# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

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
Named-barrier warp specialization: producer → consumer → epilogue.

Demonstrates how PTX named barriers (``bar.sync a, b`` / ``bar.arrive a, b``)
scope synchronization to a strict subset of warps, so that unrelated warps
continue running while the scoped sync completes.

Kernel layout — 96 threads (3 warps):

  ===  =========  ==========================================================
  Warp  Role       Responsibility
  ===  =========  ==========================================================
   0   producer   Fills shared memory from global memory using an mbarrier pipeline.
   1   consumer   Waits on mbarrier, accumulates tiles into result shared memory,
                  then **arrives** at named barrier 1 (non-blocking).
   2   epilogue   **Waits** at named barrier 1, writes result shared memory to global memory.
  ===  =========  ==========================================================

Why named barriers instead of ``cutlass.primitives.barrier_cta_sync(0)``?

  ``cutlass.primitives.barrier_cta_sync(0)`` is ``__syncthreads__``— it forces all 96 threads to
  rendezvous. Slot 1 (``number_of_threads=64``, warps 1+2 only) excludes
  warp 0 entirely. The consumer arrives without blocking; the epilogue waits.

Public API (mirrors ``examples/template_kernel.py``):
  - :func:`compile` — AOT factory keyed on ``STAGES``.
  - :func:`run`     — allocate src/dst, call compiled fn, return ``(dst, src)``.
  - :func:`verify`  — compile + run + assert vs reference.

To run::

    python CuTeDSL/experimental/primitives/warp_named_barrier.py
    python CuTeDSL/experimental/primitives/warp_named_barrier.py --STAGES 4 --num_tiles 16

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
# Kernel Configurations — fixed
# ---------------------------------------------------------------------------

_BLOCK: int = 96  # 3 warps: producer, consumer, epilogue (fixed)
_TILE: int = 32  # one element per lane (fixed; producer fills 32 lanes)

# Named barrier slot IDs and thread counts
_BAR_PROD_FLUSH = 0  # slot 0: producer-local warp flush, 32 threads (warp 0)
_T_PROD = 32

_BAR_CONS_EPI = 1  # slot 1: consumer → epilogue handoff, 64 threads (warps 1+2)
_T_CONS_EPI = 64


# ---------------------------------------------------------------------------
# Kernel Configurations — tunable
# ---------------------------------------------------------------------------

_DEFAULT_STAGES: int = 2  # pipeline depth (compile-time)

# ---------------------------------------------------------------------------
# Default problem sizes
# ---------------------------------------------------------------------------

_DEFAULT_NUM_TILES: int = 8


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    src: cute.Tensor,
    dst: cute.Tensor,
    num_tiles: cutlass.Int32,
    STAGES: cutlass.Constexpr,
):
    """3-warp kernel: producer fills shared memory, consumer accumulates, epilogue stores."""
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()
    lane = tidx % 32

    warp = cute.arch.warp_idx()

    smem_buf = cutlass.Array(
        cutlass.Float32, STAGES * _TILE, space=cutlass.AddressSpace.smem
    )
    smem_result = cutlass.Array(cutlass.Float32, _TILE, space=cutlass.AddressSpace.smem)
    mbar = cutlass.Array(cutlass.Int64, 2 * STAGES, space=cutlass.AddressSpace.smem)
    full_bar = mbar
    empty_bar = mbar.subview(STAGES)

    if warp == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(STAGES):
                prims.mbarrier_init(full_bar.subview(i), 1)
                prims.mbarrier_init(empty_bar.subview(i), 1)
        smem_result[lane] = 0.0
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # Pre-signal empty_bar (one arrive flips each slot 0 → 1).
    if warp == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(STAGES):
                prims.mbarrier_arrive(empty_bar.subview(i))
    prims.barrier_cta_sync(0)

    # ------------------------------------------------------------------
    # Producer (warp 0)
    # ------------------------------------------------------------------
    if warp == 0:
        for k in cutlass.range(num_tiles):
            s = k % STAGES
            phase = (k // STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                empty_bar.subview(s), phase, time_limit=10_000_000
            ):
                pass

            global_idx = bidx * (num_tiles * _TILE) + k * _TILE + lane
            smem_buf[s * _TILE + lane] = src[global_idx]

            prims.barrier_cta_sync(_BAR_PROD_FLUSH, thread_count=_T_PROD)

            if prims.elect_sync():
                prims.mbarrier_arrive(full_bar.subview(s))

    # ------------------------------------------------------------------
    # Consumer (warp 1)
    # ------------------------------------------------------------------
    if warp == 1:
        for k in cutlass.range(num_tiles):
            s = k % STAGES
            phase = (k // STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                full_bar.subview(s), phase, time_limit=10_000_000
            ):
                pass

            smem_result[lane] = smem_result[lane] + smem_buf[s * _TILE + lane]

            if prims.elect_sync():
                prims.mbarrier_arrive(empty_bar.subview(s))

        prims.barrier_cta_arrive(_BAR_CONS_EPI, _T_CONS_EPI)

    # ------------------------------------------------------------------
    # Epilogue (warp 2)
    # ------------------------------------------------------------------
    if warp == 2:
        prims.barrier_cta_sync(_BAR_CONS_EPI, thread_count=_T_CONS_EPI)
        global_idx = bidx * _TILE + lane
        dst[global_idx] = smem_result[lane]


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    src: cute.Tensor,
    dst: cute.Tensor,
    num_tiles: cutlass.Int32,
    STAGES: cutlass.Constexpr,
):
    """Launch the named-barrier pipeline kernel."""
    kernel(src, dst, num_tiles, STAGES).launch(grid=(1, 1, 1), block=(_BLOCK, 1, 1))


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(STAGES: int = _DEFAULT_STAGES) -> Callable:  # noqa: A001
    """AOT-compile :func:`host`; cache by ``STAGES``."""
    sym_n_src = cute.sym_int64(divisibility=_TILE)
    fake_src = make_fake_compact_tensor(cutlass.Float32, (sym_n_src,))
    fake_dst = make_fake_compact_tensor(cutlass.Float32, (_TILE,))
    fake_num_tiles = cutlass.Int32(0)
    return cute.compile(
        host, fake_src, fake_dst, fake_num_tiles, STAGES, options="--enable-tvm-ffi"
    )


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(
    compiled_fn: Callable,
    num_tiles: int = _DEFAULT_NUM_TILES,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate src/dst, call compiled_fn, return ``(dst, src)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    n_src = _TILE * num_tiles
    src = torch.arange(n_src, dtype=torch.float32, device="cuda")
    dst = torch.zeros(_TILE, dtype=torch.float32, device="cuda")
    compiled_fn(src, dst, num_tiles)
    torch.cuda.synchronize()
    return dst, src


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(
    num_tiles: int = _DEFAULT_NUM_TILES,
    STAGES: int = _DEFAULT_STAGES,
) -> None:
    """Compile, run, and assert dst == sum_k src[k*TILE:(k+1)*TILE]."""
    compiled_fn = compile(STAGES=STAGES)
    print(f"Compile kernel (STAGES={STAGES}) OK", flush=True)

    dst, src = run(compiled_fn, num_tiles=num_tiles)
    print(f"Run kernel (num_tiles={num_tiles}, STAGES={STAGES}) OK", flush=True)

    expected = torch.stack(
        [src[k * _TILE : (k + 1) * _TILE] for k in range(num_tiles)]
    ).sum(dim=0)
    torch.testing.assert_close(dst, expected)
    print(
        f"verify (num_tiles={num_tiles}, STAGES={STAGES}): PASS  "
        f"dst[:4] = {dst[:4].tolist()}"
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="warp_named_barrier — 3-warp producer/consumer/epilogue",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--num_tiles",
        type=int,
        default=None,
        help="number of tiles  [runtime cutlass.Int32]",
    )
    p.add_argument(
        "--STAGES",
        type=int,
        default=_DEFAULT_STAGES,
        help="pipeline depth  [compile-time cutlass.Constexpr]",
    )
    args = p.parse_args()

    if args.num_tiles is not None:
        verify(num_tiles=args.num_tiles, STAGES=args.STAGES)
    else:
        verify(num_tiles=_DEFAULT_NUM_TILES, STAGES=args.STAGES)
        verify(num_tiles=_DEFAULT_NUM_TILES * 2, STAGES=args.STAGES)
