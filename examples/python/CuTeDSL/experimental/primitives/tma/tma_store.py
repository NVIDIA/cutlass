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
TMA store: thread writes shared memory → fence_proxy → TMA store → global memory.

Demonstrates the TMA store path — the reverse of TMA load.  The key API
sequence that is easy to get wrong:

  1. All threads write computed results into shared memory
  2. ``cutlass.primitives.barrier_cta_sync(0)`` — ensure all thread writes are complete
  3. ``cutlass.primitives.fence_proxy(ProxyKind.async_shared, space=SharedSpace.shared_cta)``
     — make generic-proxy (thread) shared-memory writes visible to the
     async-proxy (TMA engine).  **Without this fence, TMA reads stale data.**
  4. ``cutlass.primitives.cp_async_bulk_tensor_global_shared_cta(...)`` — elected thread
     issues TMA store (shared memory → global)
  5. ``cutlass.primitives.cp_async_bulk_commit_group()`` — group the pending TMA store(s)
  6. ``cutlass.primitives.cp_async_bulk_wait_group(0)`` — **all 32 threads** wait for
     completion.  NOT inside ``elect_sync``!

The kernel loads a tile via TMA, adds a constant in registers, writes back
to shared memory, and stores the result to a separate output via TMA store.

Requires SM90+ (Hopper+) for TMA.

The sequence above is the canonical TMA store pattern and its required ordering.

To run::

    python CuTeDSL/experimental/primitives/tma/tma_store.py

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
# Configuration
# ---------------------------------------------------------------------------

TILE_M = 128  # rows per thread block
TILE_K = 64  # cols per tile; s128b requires TILE_K * 2 == 128
_TILE_BYTES = TILE_M * TILE_K * 2  # fp16 = 2 bytes/elem
_THREADS = 128  # 4 warps
_ADD_VALUE = 1.0  # constant to add (for verification)


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_dst_desc: cutlass.GridConstant[cuda.TensorMap],
    coord_m: cutlass.Int32,
    coord_k: cutlass.Int32,
) -> None:
    """TMA load → add constant → TMA store."""

    # Input and output shared-memory buffers (separate to avoid aliasing).
    smem_in = cutlass.Array(
        cutlass.Float16, TILE_M * TILE_K, space=cutlass.AddressSpace.smem, alignment=128
    )
    smem_out = cutlass.Array(
        cutlass.Float16, TILE_M * TILE_K, space=cutlass.AddressSpace.smem, alignment=128
    )
    full_bar = cutlass.Array(
        cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8
    )

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()

    # ------------------------------------------------------------------
    # Init barrier.
    # ------------------------------------------------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_init(full_bar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # ------------------------------------------------------------------
    # Step 1: TMA load src tile into smem_in.
    # ------------------------------------------------------------------
    src_ptr = tma_src_desc.get_ptr()
    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_arrive_expect_tx(full_bar, tma_src_desc.global_tx_bytes())
        if prims.elect_sync():
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem_in,
                src_ptr,
                (coord_k, coord_m),
                full_bar,
            )
    # Wait for TMA load to complete.
    while not prims.mbarrier_try_wait_parity(full_bar, 0):
        pass
    prims.barrier_cta_sync(0)

    # ------------------------------------------------------------------
    # Step 2: All threads cooperatively add a constant.
    #
    # Each thread handles a subset of elements.  Write results into
    # smem_out (separate buffer — do not reuse smem_in).
    # ------------------------------------------------------------------
    lane = tidx % 32
    warp = tidx // 32
    smem_in_ptr = smem_in.data_ptr()
    smem_out_ptr = smem_out.data_ptr()
    add_val = cutlass.Float16(_ADD_VALUE)

    for col in cutlass.range_constexpr(TILE_K):
        row = warp * 32 + lane
        idx = row * TILE_K + col
        val = (smem_in_ptr + idx).load()
        (smem_out_ptr + idx).store(val + add_val)

    # ------------------------------------------------------------------
    # Step 3: fence_proxy → TMA store → commit → wait.
    #
    # This is the critical TMA store sequence:
    #
    #   barrier()              — all thread writes to smem_out are done
    #   fence_proxy(async_shared) — make thread shared-memory writes visible to TMA
    #   TMA store              — elected thread issues shared-memory → global copy
    #   commit_group()         — group the TMA store
    #   wait_group(0)          — ALL 32 threads wait (warp-uniform!)
    # ------------------------------------------------------------------
    prims.barrier_cta_sync(0)

    dst_ptr = tma_dst_desc.get_ptr()

    # fence_proxy: bridge generic proxy (thread stores) → async proxy (TMA reads)
    prims.fence_proxy(prims.Proxy.ASYNC_SHARED, space=prims.SharedSpace.shared_cta)

    # TMA store: smem_out -> global dst
    if prims.elect_sync():
        prims.cp_async_bulk_tensor_global_shared_cta(
            dst_ptr,
            smem_out,
            (coord_k, coord_m),
        )

    # Commit + wait: all threads must participate (NOT inside elect_sync!)
    prims.cp_async_bulk_commit_group()
    prims.cp_async_bulk_wait_group(0)


# ---------------------------------------------------------------------------
# Host
# ---------------------------------------------------------------------------


@cute.jit
def host(src: cute.Tensor, dst: cute.Tensor) -> None:
    """Build TMA descriptors for load and store, launch kernel."""
    # Both src and dst are (M, K) row-major fp16.  TMA col-major: K innermost.
    tma_src_desc = cuda.create_tensor_map_tiled(
        global_address=src.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[src.shape[1], src.shape[0]],  # [K, M]
        global_strides=[src.shape[1] * 2 // 16],  # row stride in 16-B units
        box_dims=[TILE_K, TILE_M],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    tma_dst_desc = cuda.create_tensor_map_tiled(
        global_address=dst.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[dst.shape[1], dst.shape[0]],  # [K, M]
        global_strides=[dst.shape[1] * 2 // 16],
        box_dims=[TILE_K, TILE_M],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    kernel(tma_src_desc, tma_dst_desc, 0, 0).launch(
        grid=(1, 1, 1), block=(_THREADS, 1, 1)
    )


# ---------------------------------------------------------------------------
# Compile and run
# ---------------------------------------------------------------------------

_DEFAULT_M = TILE_M
_DEFAULT_K = TILE_K


@lru_cache(maxsize=None)
def compile() -> Callable:  # noqa: A001
    sym_m = cute.sym_int64()
    sym_k = cute.sym_int64()
    fake_src = make_fake_compact_tensor(
        cutlass.Float16, (sym_m, sym_k), stride_order=(1, 0), assumed_align=16
    )
    fake_dst = make_fake_compact_tensor(
        cutlass.Float16, (sym_m, sym_k), stride_order=(1, 0), assumed_align=16
    )
    return cute.compile(host, fake_src, fake_dst, options="--enable-tvm-ffi")


def run() -> None:
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    compiled = compile()

    src = torch.arange(
        _DEFAULT_M * _DEFAULT_K, dtype=torch.float16, device="cuda"
    ).view(_DEFAULT_M, _DEFAULT_K)
    dst = torch.zeros_like(src)

    compiled(src, dst)

    expected = src + _ADD_VALUE
    torch.testing.assert_close(dst, expected, atol=0, rtol=0)
    print(
        f"PASS  TMA store  "
        f"M={_DEFAULT_M} K={_DEFAULT_K}  "
        f"src[0,0]={src[0, 0].item()} + {_ADD_VALUE} = dst[0,0]={dst[0, 0].item()}"
    )


def verify() -> None:
    """Compile, run, and assert the TMA store example."""
    run()


def main() -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.parse_args()
    verify()


if __name__ == "__main__":
    main()
