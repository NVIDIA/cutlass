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
mapa — thread-block cluster access through distributed shared memory.

Demonstrates:

  - :func:`~cutlass.primitives.mapa` ``(addr, cta_rank)`` — translate a local
    shared-memory address to the corresponding distributed shared-memory
    address in a target thread block (PTX CTA)
  - ``cute.arch.block_idx_in_cluster()`` — get the thread-block rank within the
    cluster, exposed in PTX as the CTA rank
  - :func:`~cutlass.primitives.barrier_cluster_arrive_relaxed` / :func:`~cutlass.primitives.barrier_cluster_wait`
    — cluster-wide synchronization
  - :func:`~cutlass.primitives.mbarrier_arrive` on a remote thread block's mbarrier via
    mapa

Pattern: a ring of thread blocks in a cluster each writes its rank to local
shared memory, then uses mapa to read the next block's value.  An mbarrier
ensures the target block has written before the read.

Requires SM90+ (Hopper) for cluster and mapa hardware.

Public API (mirrors ``examples/template_kernel.py``):
  - :func:`compile` — AOT factory keyed on ``CLUSTER_SIZE_C``.
  - :func:`run`     — allocate dst, call compiled fn, return ``(dst,)``.
  - :func:`verify`  — compile + run + assert vs reference.

To run::

    python CuTeDSL/experimental/primitives/mapa.py

"""

import argparse
from functools import lru_cache
from typing import Callable

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


# ---------------------------------------------------------------------------
# Kernel Configurations — tunable
# ---------------------------------------------------------------------------

_DEFAULT_CLUSTER_SIZE: int = 2


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(dst_arr: cutlass.Array, CLUSTER_SIZE_C: cutlass.Constexpr):
    """Each thread block reads the next block's value via cutlass.primitives.mapa."""

    tidx, _, _ = cute.arch.thread_idx()

    # ------------------------------------------------------------------
    # Step 1 — Allocate shared memory: data buffer + mbarrier.
    #
    # Each thread block has its own copy of smem_data and mbar in shared memory.
    # ------------------------------------------------------------------
    smem_data = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem, alignment=8)

    # ------------------------------------------------------------------
    # Step 2 — Get PTX CTA rank within the cluster.
    # ------------------------------------------------------------------
    my_rank = cute.arch.block_idx_in_cluster()
    peer_rank = (my_rank + 1) % cutlass.Int32(CLUSTER_SIZE_C)

    # ------------------------------------------------------------------
    # Step 3 — Initialize the mbarrier.
    #
    # count=1: one arrive from the predecessor block will complete the barrier.
    # Use cluster_arrive/cluster_wait instead of cutlass.primitives.barrier_cta_sync(0) so that
    # the mbarrier init is visible across the thread blocks in the cluster.
    # ------------------------------------------------------------------
    if prims.elect_sync():
        prims.mbarrier_init(mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cluster_arrive_relaxed()
    prims.barrier_cluster_wait()

    # ------------------------------------------------------------------
    # Step 4 — Each thread block writes its own rank to local shared memory.
    # ------------------------------------------------------------------
    if tidx == 0:
        smem_data[0] = my_rank

    prims.barrier_cta_sync(0)  # ensure local write is visible within the block

    # ------------------------------------------------------------------
    # Step 5 — Signal the next block in the ring that our data is ready.
    # ------------------------------------------------------------------
    if tidx == 0:
        peer_mbar = prims.mapa(mbar, peer_rank)
        prims.mbarrier_arrive(peer_mbar)

    # ------------------------------------------------------------------
    # Step 6 — Wait for the previous block in the ring to signal us.
    # ------------------------------------------------------------------
    while not prims.mbarrier_try_wait_parity(mbar, 0, time_limit=10_000_000):
        pass

    # ------------------------------------------------------------------
    # Step 7 — Read the next block's data via mapa.
    # ------------------------------------------------------------------
    if tidx == 0:
        peer_ptr = prims.mapa(smem_data.data_ptr(), peer_rank)
        peer_value = peer_ptr[0]
        dst_arr[my_rank] = peer_value


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(dst: cutlass.Array, CLUSTER_SIZE_C: cutlass.Constexpr):
    """Launch with cluster=(CLUSTER_SIZE_C,1,1)."""
    kernel(dst, CLUSTER_SIZE_C).launch(
        grid=(CLUSTER_SIZE_C, 1, 1),
        block=(32, 1, 1),
        cluster=(CLUSTER_SIZE_C, 1, 1),
    )


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(CLUSTER_SIZE_C: int = _DEFAULT_CLUSTER_SIZE) -> Callable:  # noqa: A001
    """AOT-compile :func:`host`; cache by ``CLUSTER_SIZE_C``."""
    if CLUSTER_SIZE_C < 2:
        raise ValueError(f"CLUSTER_SIZE_C must be >= 2 (got {CLUSTER_SIZE_C})")
    fake_dst = make_fake_compact_tensor(cutlass.Int32, (CLUSTER_SIZE_C,))
    return cute.compile(host, fake_dst, CLUSTER_SIZE_C, options="--enable-tvm-ffi")


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(compiled_fn: Callable, cluster_size: int) -> tuple[torch.Tensor]:
    """Allocate dst, call compiled_fn, return ``(dst,)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    dst = torch.full((cluster_size,), -1, dtype=torch.int32, device="cuda")
    compiled_fn(dst)
    torch.cuda.synchronize()
    return (dst,)


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(cluster_size: int = _DEFAULT_CLUSTER_SIZE) -> None:
    """Compile, run, and assert each block reads the next block's rank."""
    compiled_fn = compile(CLUSTER_SIZE_C=cluster_size)
    print(f"Compile kernel (cluster_size={cluster_size}) OK", flush=True)

    (dst,) = run(compiled_fn, cluster_size)
    print(f"Run kernel (cluster_size={cluster_size}) OK", flush=True)

    expected = torch.tensor(
        [(i + 1) % cluster_size for i in range(cluster_size)],
        dtype=torch.int32,
        device="cuda",
    )
    torch.testing.assert_close(dst, expected)
    print(
        f"verify (cluster_size={cluster_size}): PASS  dst = {dst.tolist()}  "
        f"(block i reads rank (i+1)%cluster_size)"
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="mapa — distributed shared-memory cluster ring demo",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--cluster_size",
        type=int,
        default=_DEFAULT_CLUSTER_SIZE,
        help="Compile-time cluster size",
    )
    args = p.parse_args()
    verify(cluster_size=args.cluster_size)
