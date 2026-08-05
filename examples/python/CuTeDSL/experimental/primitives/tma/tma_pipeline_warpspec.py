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
Warp-specialized TMA pipeline with full_bar + empty_bar (producer/consumer split).

This is the most common real-world pipeline pattern: one warp issues TMA loads
(producer), a second warp reads shared-memory data (consumer).  ``empty_bar``
prevents the producer from overwriting shared memory that the consumer has not
yet read.

Demonstrates:

  - ``full_bar[NUM_STAGES]`` (producer → consumer: data ready)
  - ``empty_bar[NUM_STAGES]`` (consumer → producer: slot free)
  - **Pre-signal trick**: arrive once on each ``empty_bar[s]`` in the prologue
    so the producer's first ``wait(empty_bar, parity=0)`` passes immediately
  - Arithmetic parity formula: ``(k // NUM_STAGES) & 1``  (no loop-carried state)
  - Producer prologue: prefetch ``NUM_PREFETCH`` stages without waiting
  - Consumer: wait(full_bar) → read shared memory → arrive(empty_bar)

Key differences from other patterns:

  - ``tma_pipeline_single_warp.py``: single warp, no empty_bar needed
  - ``tma_pipeline_pingpong.py``: two producers alternate K-tiles (count=1, stride-2)
  - ``tma_pipeline_count2.py``: two producers load different operands to same stage (count=2)

Warp layout (2 warps, 64 threads per block):

  | Warp | Role     | Description                                    |
  |------|----------|------------------------------------------------|
  |  0   | producer | TMA loads for all K-tiles, signals full_bar    |
  |  1   | consumer | Reads shared-memory tiles, signals empty_bar     |

The kernel performs an elementwise copy (no MMA): TMA loads src tiles into
shared memory, consumer reads shared memory and stores to dst.  Replace the
copy-out body with MMA for a real GEMM.

Requires SM90+ (Hopper+) for TMA + warpspec mbarrier patterns.

The producer/consumer protocol shown here is the canonical warp-specialized
TMA pipeline pattern.

To run::

    python CuTeDSL/experimental/primitives/tma/tma_pipeline_warpspec.py

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
TILE_K = 64  # cols per TMA tile; s128b swizzle requires TILE_K * 2 == 128
NUM_STAGES = 2  # pipeline depth (double buffer)
NUM_PREFETCH = 1  # stages to pre-fill before main loop; must be < NUM_STAGES
_TILE_BYTES = TILE_M * TILE_K * 2  # fp16 = 2 bytes/elem
_THREADS = 64  # 2 warps: warp 0 = producer, warp 1 = consumer

_WARP_PROD = 0
_WARP_CONS = 1


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
    dst: cute.Tensor,
    k_tiles: cutlass.Int32,
) -> None:
    """Warp-specialized TMA pipeline: producer fills, consumer drains."""

    smem = cutlass.Array(
        cutlass.Float16,
        NUM_STAGES * TILE_M * TILE_K,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    mbar = cutlass.Array(
        cutlass.Int64, 2 * NUM_STAGES, space=cutlass.AddressSpace.smem, alignment=8
    )
    full_bar = mbar  # producer → consumer: data ready
    empty_bar = mbar.subview(NUM_STAGES)  # consumer → producer: slot free

    bidx, _, _ = cute.arch.block_idx()
    coord_m = bidx * TILE_M

    # Use tidx // 32 (logical warp) rather than %warpid (physical hardware slot).
    # On SM100 (Blackwell), %warpid is a physical slot ID that may not be 0/1 for
    # a 2-warp block — it can be any pair of values from [0, 31].  Logical warp
    # (tidx // 32) always gives 0 for threads 0–31 and 1 for threads 32–63.
    tidx, _, _ = cute.arch.thread_idx()
    warp_idx = tidx // 32

    # ------------------------------------------------------------------
    # Init: one elected thread initialises all barriers.
    #
    # count=1 for both: one producer arrive per full_bar transition,
    # one consumer arrive per empty_bar transition.
    # ------------------------------------------------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(NUM_STAGES):
                prims.mbarrier_init(full_bar.subview(i), 1)
                prims.mbarrier_init(empty_bar.subview(i), 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # ------------------------------------------------------------------
    # Pre-signal empty_bar: mark all stages as initially free.
    #
    # A fresh mbarrier starts at parity 0.  The producer's first wait is:
    #   wait(empty_bar[s], parity=0)
    # On a fresh bar, parity=0 blocks until parity flips.  One arrive
    # flips empty_bar[s] from parity 0 → 1, so wait(parity=0) passes
    # immediately on the first iteration.
    # ------------------------------------------------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(NUM_STAGES):
                prims.mbarrier_arrive(empty_bar.subview(i))
    prims.barrier_cta_sync(0)

    src_ptr = tma_src_desc.get_ptr()

    # ------------------------------------------------------------------
    # Producer warp (warp 0): TMA load pipeline.
    #
    # Prologue: prefetch NUM_PREFETCH stages without waiting on empty_bar
    # (they were just pre-signaled as free).
    # Main loop: wait(empty_bar) → arrive_expect_tx(full_bar) → TMA load
    # ------------------------------------------------------------------
    if warp_idx == _WARP_PROD:
        # Prologue fills: no wait needed (empty_bar was pre-signaled).
        for i in cutlass.range_constexpr(NUM_PREFETCH):
            s = i % NUM_STAGES
            k_coord = i * TILE_K
            if prims.elect_sync():
                prims.mbarrier_arrive_expect_tx(
                    full_bar.subview(s), tma_src_desc.global_tx_bytes()
                )
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem.subview(s * TILE_M * TILE_K),
                    src_ptr,
                    (k_coord, coord_m),
                    full_bar.subview(s),
                )

        # Main loop: wait for slot to be free, then issue TMA.
        for k in cutlass.range(k_tiles - NUM_PREFETCH):
            actual_k = k + NUM_PREFETCH
            fill_s = actual_k % NUM_STAGES
            # Arithmetic parity: immune to compiler state bugs.
            parity_empty = (actual_k // NUM_STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                empty_bar.subview(fill_s), parity_empty, time_limit=10_000_000
            ):
                pass

            k_coord = actual_k * TILE_K
            if prims.elect_sync():
                prims.mbarrier_arrive_expect_tx(
                    full_bar.subview(fill_s), tma_src_desc.global_tx_bytes()
                )
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem.subview(fill_s * TILE_M * TILE_K),
                    src_ptr,
                    (k_coord, coord_m),
                    full_bar.subview(fill_s),
                )

    # ------------------------------------------------------------------
    # Consumer warp (warp 1): read all K-tiles from shared memory → dst.
    #
    # wait(full_bar) → read shared memory → arrive(empty_bar)
    # ------------------------------------------------------------------
    if warp_idx == _WARP_CONS:
        lane = tidx % 32
        dst_ptr = dst.iterator.raw_ptr()
        smem_ptr = smem.data_ptr()

        for k in cutlass.range(k_tiles):
            s = k % NUM_STAGES
            parity_full = (k // NUM_STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                full_bar.subview(s), parity_full, time_limit=10_000_000
            ):
                pass

            # Warp-level sync: ensure all lanes see TMA data.
            prims.bar_warp_sync(cute.arch.FULL_MASK)

            # Copy-out: each lane covers TILE_M/32 row groups × TILE_K cols.
            k_offset = k * TILE_K
            smem_base = s * TILE_M * TILE_K

            for row_group in cutlass.range_constexpr(TILE_M // 32):
                row = row_group * 32 + lane
                for col in cutlass.range_constexpr(TILE_K):
                    # TMA s128b swizzle: physical col = (col_group XOR (row & 7)) * 8 + col_rem
                    col_group = col // 8
                    col_rem = col % 8
                    phys_col = (col_group ^ (row & 7)) * 8 + col_rem
                    smem_idx = smem_base + row * TILE_K + phys_col
                    dst_idx = (coord_m + row) * (k_tiles * TILE_K) + k_offset + col
                    (dst_ptr + dst_idx).store((smem_ptr + smem_idx).load())

            # Release: signal slot s is free for the producer to reuse.
            if prims.elect_sync():
                prims.mbarrier_arrive(empty_bar.subview(s))


# ---------------------------------------------------------------------------
# Host
# ---------------------------------------------------------------------------


@cute.jit
def host(src: cute.Tensor, dst: cute.Tensor, k_tiles: int) -> None:
    """Build TMA descriptor and launch kernel."""
    # src is (M, K) row-major fp16.  TMA col-major: K innermost.
    tma_src_desc = cuda.create_tensor_map_tiled(
        global_address=src.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[src.shape[1], src.shape[0]],  # [K, M]
        global_strides=[src.shape[1] * 2 // 16],  # row stride in 16-B units
        box_dims=[TILE_K, TILE_M],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    m_tiles = src.shape[0] // TILE_M
    kernel(tma_src_desc, dst, k_tiles).launch(
        grid=(m_tiles, 1, 1), block=(_THREADS, 1, 1)
    )


# ---------------------------------------------------------------------------
# Compile and run
# ---------------------------------------------------------------------------

_DEFAULT_K_TILES = 4
_DEFAULT_M = TILE_M


@lru_cache(maxsize=None)
def compile(k_tiles: int = _DEFAULT_K_TILES) -> Callable:  # noqa: A001
    sym_m = cute.sym_int64()
    k = k_tiles * TILE_K
    fake_src = make_fake_compact_tensor(
        cutlass.Float16, (sym_m, k), stride_order=(1, 0), assumed_align=16
    )
    fake_dst = make_fake_compact_tensor(
        cutlass.Float16, (sym_m, k), stride_order=(1, 0), assumed_align=16
    )
    return cute.compile(host, fake_src, fake_dst, k_tiles, options="--enable-tvm-ffi")


def run(
    m: int = _DEFAULT_M,
    k_tiles: int = _DEFAULT_K_TILES,
    compiled_fn: Callable | None = None,
) -> tuple[torch.Tensor, torch.Tensor]:
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    if m % TILE_M != 0:
        raise ValueError(f"m must be divisible by TILE_M={TILE_M}")
    if k_tiles <= 0:
        raise ValueError("k_tiles must be positive")

    compiled_fn = compiled_fn or compile(k_tiles)
    k = k_tiles * TILE_K

    src = torch.arange(m * k, dtype=torch.float16, device="cuda").view(m, k)
    dst = torch.zeros_like(src)

    compiled_fn(src, dst, k_tiles)
    torch.cuda.synchronize()

    return dst, src


def verify(m: int = _DEFAULT_M, k_tiles: int = _DEFAULT_K_TILES) -> None:
    dst, src = run(m=m, k_tiles=k_tiles)
    torch.testing.assert_close(dst, src, atol=0, rtol=0)
    print(
        f"PASS  TMA warpspec pipeline  "
        f"M={m} K={k_tiles * TILE_K} ({k_tiles} tiles x {TILE_K})  "
        f"STAGES={NUM_STAGES}  "
        f"dst[0,:4] = {dst[0, :4].tolist()}"
    )


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument(
        "--m",
        type=int,
        default=_DEFAULT_M,
        help=f"rows (must be divisible by TILE_M={TILE_M})",
    )
    p.add_argument(
        "--k_tiles",
        type=int,
        default=_DEFAULT_K_TILES,
        help="number of K-tiles",
    )
    args = p.parse_args()
    verify(m=args.m, k_tiles=args.k_tiles)
