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
TMA ping-pong dual-producer pipeline (full_bar count=1, stride-2 K-tiles).

Two dedicated producer warps alternate K-tiles by stride: warp 0 handles
k = 0, 2, 4, … and warp 1 handles k = 1, 3, 5, …  A consumer warp reads
all tiles sequentially.  Each stage is owned by exactly **one** producer at
a time — ``full_bar count=1``.

Key differences from the two-producer (count=2) pattern:

  - **Ping-pong** partitions *K-tiles* across two producers (each producer
    owns alternating tiles, different K-coordinates).
  - **Count=2** parallelises A and B operand *within* the same K-tile
    (both producers load to the same stage simultaneously).

Use ping-pong when TMA issue throughput is the bottleneck (T_TMA > T_MMA)
and you want to hide TMA latency with two warps issuing in parallel across
different K-tiles.

Warp layout (3 warps total, 96 threads per block):

  | Warp | Role          | Description                                   |
  |------|---------------|-----------------------------------------------|
  |  0   | producer-even | TMA loads for k = 0, 2, 4, … → stages 0, 2, … |
  |  1   | producer-odd  | TMA loads for k = 1, 3, 5, … → stages 1, 3, … |
  |  2   | consumer      | Reads all tiles sequentially, writes to dst   |

The kernel performs an elementwise copy using TMA loads and direct
shared-memory stores — no MMA.  The pipeline structure is the same as a GEMM
ping-pong kernel; replace the copy-out body with tcgen05_mma for a real GEMM.

Requires SM90+ (Hopper+) for TMA + warpspec mbarrier patterns.

To run::

    python CuTeDSL/experimental/primitives/tma/tma_pipeline_pingpong.py

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
NUM_STAGES = 4  # pipeline stages: each producer owns half → 2 stages each
_TILE_BYTES = TILE_M * TILE_K * 2  # fp16
_THREADS = 96  # 3 warps × 32 threads

_WARP_PROD_EVEN = 0
_WARP_PROD_ODD = 1
_WARP_CONS = 2


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
    dst: cute.Tensor,
    k_tiles: cutlass.Int32,
) -> None:
    """Ping-pong TMA pipeline: copy all K-tiles via two alternating producers."""

    smem = cutlass.Array(
        cutlass.Float16,
        NUM_STAGES * TILE_M * TILE_K,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    mbar = cutlass.Array(
        cutlass.Int64, 2 * NUM_STAGES, space=cutlass.AddressSpace.smem, alignment=8
    )
    full_bar = mbar  # count=1: one producer per stage
    empty_bar = mbar.subview(NUM_STAGES)  # count=1: one consumer

    bidx, _, _ = cute.arch.block_idx()
    coord_m = bidx * TILE_M

    # Use tidx // 32 (logical warp) rather than %warpid (physical hardware slot).
    # On SM100 (Blackwell), %warpid is a physical slot ID that may not be 0/1/2
    # for a 3-warp block — logical warp (tidx // 32) always gives the correct index.
    tidx, _, _ = cute.arch.thread_idx()
    warp_idx = tidx // 32

    # ------------------------------------------------------------------
    # Init: one elected thread initialises all barriers.
    #
    # count=1 for both: each stage is exclusively owned by one producer
    # (ping-pong), so only one warp arrives per barrier transition.
    # ------------------------------------------------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(NUM_STAGES):
                prims.mbarrier_init(full_bar.subview(i), 1)
                prims.mbarrier_init(empty_bar.subview(i), 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # ------------------------------------------------------------------
    # Pre-signal empty_bar for all stages.
    #
    # Without pre-signaling the producers' first wait(empty_bar, parity=0)
    # would block — a fresh barrier starts at parity 0 and wait(parity=0)
    # means "block until parity ≠ 0".  One arrive flips it to parity 1
    # so wait(parity=0) passes immediately on the first iteration.
    # ------------------------------------------------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(NUM_STAGES):
                prims.mbarrier_arrive(empty_bar.subview(i))
    prims.barrier_cta_sync(0)

    src_ptr = tma_src_desc.get_ptr()

    # ------------------------------------------------------------------
    # Producer-even (warp 0): issues TMA for k = 0, 2, 4, …
    #
    # With NUM_STAGES=4, even visits stages 0, 2, 0, 2, … cycling with
    # stride=2 over the stage array.  Parity formula (same as consumer):
    #   stage = k % NUM_STAGES    (0, 2, 0, 2, … for k=0,2,4,6,…)
    #   parity = (k // NUM_STAGES) & 1
    # ------------------------------------------------------------------
    if warp_idx == _WARP_PROD_EVEN:
        k = 0
        while k < k_tiles:
            s = k % NUM_STAGES
            # Each producer revisits each stage every NUM_STAGES k-steps
            # (stage 0 for even: k=0,4,8,…; stage 1 for odd: k=1,5,9,…).
            # This matches the consumer's cycling rate, so both use the
            # same parity formula: (k // NUM_STAGES) & 1.
            parity_empty = (k // NUM_STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                empty_bar.subview(s), parity_empty, time_limit=10_000_000
            ):
                pass

            k_coord = k * TILE_K
            if prims.elect_sync():
                prims.mbarrier_arrive_expect_tx(
                    full_bar.subview(s), tma_src_desc.global_tx_bytes()
                )
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem.subview(s * TILE_M * TILE_K),
                    src_ptr,
                    (k_coord, coord_m),
                    full_bar.subview(s),  # TMA column-major: K first, M second
                )

            k = k + 2  # stride=2: even k-tiles only

    # ------------------------------------------------------------------
    # Producer-odd (warp 1): issues TMA for k = 1, 3, 5, …
    #
    # Same formula; starts at k=1 and visits stages 1, 3, 1, 3, …
    # ------------------------------------------------------------------
    if warp_idx == _WARP_PROD_ODD:
        k = 1
        while k < k_tiles:
            s = k % NUM_STAGES
            parity_empty = (k // NUM_STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                empty_bar.subview(s), parity_empty, time_limit=10_000_000
            ):
                pass

            k_coord = k * TILE_K
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

            k = k + 2  # stride=2: odd k-tiles only

    # ------------------------------------------------------------------
    # Consumer (warp 2): reads ALL k-tiles in order 0, 1, 2, …
    #
    # Even tiles come from the even producer, odd from the odd producer,
    # but the consumer does not care — it just waits on full_bar[s].
    # ------------------------------------------------------------------
    if warp_idx == _WARP_CONS:
        lane = tidx % 32
        dst_ptr = dst.iterator.raw_ptr()
        smem_ptr = smem.data_ptr()

        for k in cutlass.range(k_tiles):
            s = k % NUM_STAGES
            # Consumer uses the global sequential parity formula.
            parity_full = (k // NUM_STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                full_bar.subview(s), parity_full, time_limit=10_000_000
            ):
                pass

            prims.bar_warp_sync(cute.arch.FULL_MASK)

            # Copy-out: each lane covers TILE_M/32 row groups × TILE_K cols.
            k_offset = k * TILE_K
            smem_base = s * TILE_M * TILE_K

            for row_group in cutlass.range_constexpr(TILE_M // 32):
                row = row_group * 32 + lane
                # Dynamic col loop: avoids 64-iteration constexpr unroll inside
                # the dynamic k-loop, which would produce O(body²) LLVM IR.
                for col in range(TILE_K):
                    # TMA s128b swizzle: physical col = (col_group XOR (row & 7)) * 8 + col_rem
                    col_group = col // 8
                    col_rem = col % 8
                    phys_col = (col_group ^ (row & 7)) * 8 + col_rem
                    smem_idx = smem_base + row * TILE_K + phys_col
                    dst_idx = (coord_m + row) * (k_tiles * TILE_K) + k_offset + col
                    (dst_ptr + dst_idx).store((smem_ptr + smem_idx).load())

            # Release: signal slot s is free for a producer to reuse.
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

_DEFAULT_K_TILES = 4  # even value exercises both producers
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
        f"PASS  TMA ping-pong pipeline  "
        f"M={m} K={k_tiles * TILE_K} ({k_tiles} tiles × {TILE_K})  "
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
        help="K-tiles (even recommended)",
    )
    args = p.parse_args()
    verify(m=args.m, k_tiles=args.k_tiles)
