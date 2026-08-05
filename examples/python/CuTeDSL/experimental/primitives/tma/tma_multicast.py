# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
TMA multicast: broadcast one global tile to all thread blocks in a cluster.

TMA multicast delivers the same global-memory tile into the shared memory of
*every thread block* in a cluster with a single hardware operation, avoiding
redundant global reads when all cluster members need identical data (e.g., the
A matrix in an N-parallel GEMM split).

Demonstrates:

  - :func:`~cutlass.primitives.cp_async_bulk_tensor_shared_cluster_global` with
    ``multicast_mask`` — hardware broadcasts one tile to ``N`` blocks at once.
  - Leader/non-leader block roles: only the leader issues the TMA instruction
    and calls ``arrive_expect_tx``; non-leaders only wait.
  - ``txcount = desc.global_tx_bytes() × 2`` — the leader's mbarrier accounts
    for the two ``complete_tx`` signals routed from the CTA pair.
  - ``group=CTAGroupKind.CTA_2`` — the primitive wrapper clears bit 24 of the mbar
    pointer so the peer CTA's ``complete_tx`` routes to CTA 0's mbarrier.
  - :func:`~cutlass.primitives.barrier_cluster_arrive_relaxed` /
    :func:`~cutlass.primitives.barrier_cluster_wait` — cluster-scope barrier used both to fence
    mbarrier init (before the main loop) and to coordinate after TMA completes
    (so every block sees the loaded data before it writes to global output).
  - Static configuration (``cluster_size``) passed as a plain Python ``int``
    kernel argument — the JIT compiler specialises on its concrete value so
    compile-time constants like ``multicast_mask`` and ``leader_txcount`` are
    folded in without requiring a factory/closure pattern.

Setup
-----
Cluster of 2 thread blocks.  Each block independently allocates a
(TILE_M, TILE_K) fp16 shared-memory buffer.  The leader block (PTX CTA rank 0)
multicasts a tile from ``src`` into both blocks' shared memory.  Every block
writes its shared-memory tile to a distinct row of ``dst`` for verification.

To run with 2-block cluster::

    python CuTeDSL/experimental/primitives/tma/tma_multicast.py --cluster_size 2

"""

import argparse
from functools import lru_cache
from typing import Callable

import torch


import cutlass
import cutlass.experimental.cuda as cuda
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims

# ---------------------------------------------------------------------------
# Tile configuration
# ---------------------------------------------------------------------------
TILE_M = 128  # rows per tile
TILE_K = 64  # cols per tile; s128b swizzle: TILE_K * 2 == 128
_TILE_BYTES = TILE_M * TILE_K * 2  # fp16 = 2 bytes
_THREADS = 128  # 4 warps per block
_SUPPORTED_CLUSTER_SIZE = 2


def _check_cluster_size(cluster_size: int) -> None:
    if cluster_size != _SUPPORTED_CLUSTER_SIZE:
        raise ValueError(
            "tma_multicast uses CTA_2 leader-mbar routing and only supports "
            "cluster_size=2. Larger multicast clusters require per-CTA local "
            "mbarriers with group omitted."
        )


# ---------------------------------------------------------------------------
# Kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
    dst: cute.Tensor,
    coord_m: cutlass.Int32,
    coord_k: cutlass.Int32,
) -> None:
    """Multicast one tile to all thread blocks in the cluster.

    ``cluster_size`` is read at runtime from ``cute.arch.cluster_size()`` so the
    kernel does not need a separate parameter.

    Multicast protocol (single-stage):

    1.  The leader block (PTX CTA rank 0) initialises its mbarrier with
        ``arrive_count = 1``.
    2.  All blocks call ``fence_mbarrier_init``, then
        ``barrier_cluster_arrive_relaxed`` + ``cluster_wait`` so the leader's init
        is visible across the cluster before any block calls ``arrive`` on
        the leader's mbar.
    3.  Leader block:
        a. ``arrive_expect_tx(mbar, tile_bytes × 2)`` — counts as the single
           software arrive *and* registers the total byte count across the
           CTA pair.
        b. ``cp_async_bulk_tensor_shared_cluster_global`` with
           ``multicast_mask = 0b11`` and ``group = CTA_2``.  The
           ``group=CTA_2`` argument causes the primitive wrapper to clear bit 24
           of the mbar pointer, routing the peer CTA's TMA ``complete_tx``
           signal to the leader's shared-memory mbarrier.
    4.  Only the leader waits for its mbar to fire; this confirms all
        ``complete_tx`` signals arrived (i.e., all blocks' shared memory is
        populated).
    5.  ``barrier_cluster_arrive_relaxed`` + ``cluster_wait`` propagates the
        "data ready" signal to all non-leader blocks.
    6.  All threads store their block-local shared memory to the block's
        output row.

    Larger clusters are intentionally rejected by the host entry point.  PTX
    ISA ``.cta_group::2`` routes mbarrier signals within each CTA pair; it
    does not route every destination CTA in a 4+ CTA cluster to CTA 0's mbar.
    """
    smem = cutlass.Array(
        cutlass.Float16, TILE_M * TILE_K, space=cutlass.AddressSpace.smem, alignment=128
    )
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()

    cta_rank = cute.arch.block_idx_in_cluster()
    is_leader = cta_rank == cutlass.Int32(0)

    # Derived runtime values from the hardware cluster size register.
    n_ctas = cute.arch.cluster_size()  # Int32: number of blocks in cluster
    multicast_mask = (cutlass.Int32(1) << n_ctas) - cutlass.Int32(1)
    leader_txcount = tma_src_desc.global_tx_bytes() * n_ctas

    # ---- Initialise mbarrier (leader only) ----------------------------
    # Only the leader block's mbar is used; non-leaders' are never initialised.
    if is_leader:
        if warp_idx == 0:
            if prims.elect_sync():
                prims.mbarrier_init(mbar, 1)

    # Fence mbar init, then cluster-sync so all blocks see the init before
    # any block attempts an arrive/wait on the leader's mbar.
    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    # ---- Producer: leader issues TMA multicast -----------------------
    if is_leader:
        if warp_idx == 0:
            if prims.elect_sync():
                # txcount = descriptor bytes × cluster_size: each receiving
                # block contributes one complete_tx worth of bytes.
                prims.mbarrier_arrive_expect_tx(mbar, leader_txcount)
            if prims.elect_sync():
                # Multicast: delivers same tile into each block's shared memory.
                # group=CTA_2 routes all complete_tx signals to the leader's
                # mbar (wrapper clears bit 24 of mbar pointer automatically).
                prims.cp_async_bulk_tensor_shared_cluster_global(
                    smem,
                    tma_src_desc.get_ptr(),
                    (coord_k, coord_m),  # TMA column-major: innermost (K) first
                    mbar,
                    [],  # im2col_offsets (empty for tiled copy)
                    multicast_mask=multicast_mask,  # plain int; wrapper converts to Int16
                    group=prims.CTAGroup.CTA_2,
                )

    # ---- Consumer: leader waits, then cluster-sync -------------------
    # Leader waits for all cluster_size complete_tx signals to arrive.
    if is_leader:
        if warp_idx == 0:
            parity = cutlass.Int32(0)
            while not prims.mbarrier_try_wait_parity(
                mbar, parity, time_limit=10_000_000
            ):
                pass

    # All blocks sync: non-leaders now know their shared memory is populated.
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    # ---- Store: each block writes its shared-memory copy to its output row -----
    # dst shape: (cluster_size, TILE_M * TILE_K) — each block owns one row.
    lane = tidx % cutlass.Int32(32)
    warp = tidx // cutlass.Int32(32)
    smem_ptr = smem.data_ptr()
    dst_ptr = dst.iterator.raw_ptr()
    # Row offset into dst for this block.
    cta_offset = cta_rank * cutlass.Int32(TILE_M * TILE_K)
    for k in cutlass.range_constexpr(TILE_K):
        row = warp * cutlass.Int32(32) + lane
        # TMA s128b swizzle: physical col = (k_group XOR (row & 7)) * 8 + k_rem
        k_group = k // 8
        k_rem = k % 8
        phys_k = (cutlass.Int32(k_group) ^ (row & cutlass.Int32(7))) * cutlass.Int32(
            8
        ) + cutlass.Int32(k_rem)
        smem_idx = row * cutlass.Int32(TILE_K) + phys_k
        linear_dst_idx = row * cutlass.Int32(TILE_K) + cutlass.Int32(k)
        elem = (smem_ptr + smem_idx).load()
        (dst_ptr + cta_offset + linear_dst_idx).store(elem)


# ---------------------------------------------------------------------------
# Host function
# ---------------------------------------------------------------------------


@cute.jit
def host(src: cute.Tensor, dst: cute.Tensor, cluster_size: int) -> None:
    """Build TMA descriptor and launch multicast kernel."""
    # src is (TILE_M, TILE_K) row-major fp16.  TMA col-major: K innermost.
    tma_src_desc = cuda.create_tensor_map_tiled(
        global_address=src.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[TILE_K, TILE_M],  # [K, M] — both constants
        global_strides=[TILE_K * 2 // 16],  # row stride in 16-B units = 8
        box_dims=[TILE_K, TILE_M],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    kernel(
        tma_src_desc,
        dst,
        cutlass.Int32(0),  # coord_m: tile row offset
        cutlass.Int32(0),  # coord_k: tile col offset
    ).launch(
        grid=(cluster_size, 1, 1),  # one cluster, cluster_size blocks
        block=(_THREADS, 1, 1),
        cluster=(cluster_size, 1, 1),
    )


# ---------------------------------------------------------------------------
# Compile and run
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(cluster_size: int) -> Callable:
    _check_cluster_size(cluster_size)

    fake_src = make_fake_compact_tensor(
        cutlass.Float16, (TILE_M, TILE_K), stride_order=(1, 0), assumed_align=16
    )
    # dst shape: (cluster_size, TILE_M * TILE_K) — flattened per block
    fake_dst = make_fake_compact_tensor(
        cutlass.Float16,
        (cluster_size, TILE_M * TILE_K),
        stride_order=(1, 0),
        assumed_align=16,
    )
    return cute.compile(
        host,
        fake_src,
        fake_dst,
        cluster_size,
        options="--enable-tvm-ffi",
    )


def run(cluster_size: int = 2) -> None:
    _check_cluster_size(cluster_size)

    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    compiled = compile(cluster_size)

    src = torch.arange(TILE_M * TILE_K, dtype=torch.float16, device="cuda").view(
        TILE_M, TILE_K
    )
    # Each block's output slice should equal the flattened src tile.
    dst = torch.zeros(cluster_size, TILE_M * TILE_K, dtype=torch.float16, device="cuda")

    compiled(src, dst, cluster_size)

    expected = src.reshape(-1).unsqueeze(0).expand(cluster_size, -1)
    torch.testing.assert_close(dst, expected, atol=0, rtol=0)
    print(
        f"PASS  cluster_size={cluster_size}  "
        f"all {cluster_size} blocks received identical tile — "
        f"dst[0, :4] = {dst[0, :4].tolist()}"
    )


def verify(cluster_size: int = 2) -> None:
    """Pytest-friendly alias for the TMA multicast example."""
    run(cluster_size=cluster_size)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description=(
            "TMA multicast: broadcast one global tile to all thread blocks in a cluster"
        )
    )
    parser.add_argument(
        "--cluster_size",
        type=int,
        choices=[_SUPPORTED_CLUSTER_SIZE],
        default=2,
        help="Number of thread blocks in the CTA_2 cluster. Only 2 is supported.",
    )
    args = parser.parse_args()
    verify(cluster_size=args.cluster_size)
