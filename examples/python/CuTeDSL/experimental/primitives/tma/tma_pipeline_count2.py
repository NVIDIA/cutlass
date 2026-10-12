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
Two-producer TMA pipeline (full_bar count=2, parallel operand loading).

Two dedicated producer warps load **different operands** (A and B) to the
**same** pipeline stage at every K-tile.  The consumer's ``full_bar`` fires
only after **both** producers have arrived AND TMA has delivered all bytes.

This is NOT ping-pong:

  - **Count=2** (this file): both producers iterate ALL K-tiles, each loading
    a different operand (A or B) to the same stage.  ``full_bar count=2``
    aggregates both arrivals.
  - **Ping-pong** (``tma_pipeline_pingpong.py``): two producers alternate
    K-tiles by stride (count=1, each producer owns different stages).

Use count=2 when you want to parallelise A and B loads within the same K-tile.
Use ping-pong when TMA issue throughput is the bottleneck.

Warp layout (3 warps, 96 threads per block):

  | Warp | Role       | Description                                   |
  |------|------------|-----------------------------------------------|
  |  0   | producer-A | TMA loads A operand for each K-tile            |
  |  1   | producer-B | TMA loads B operand for each K-tile            |
  |  2   | consumer   | Reads A+B from shared memory, writes to dst     |

The kernel performs an elementwise add: dst = A + B, loading each operand
via TMA and writing the sum via direct global stores.

Requires SM90+ (Hopper+) for TMA + warpspec mbarrier patterns.

The two-producer count-2 protocol shown here is the intended pattern selection.

To run::

    python CuTeDSL/experimental/primitives/tma/tma_pipeline_count2.py

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
NUM_STAGES = 2  # pipeline stages
_THREADS = 96  # 3 warps x 32 threads

_WARP_PROD_A = 0
_WARP_PROD_B = 1
_WARP_CONS = 2


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_a_desc: cutlass.GridConstant[cuda.TensorMap],
    tma_b_desc: cutlass.GridConstant[cuda.TensorMap],
    dst: cute.Tensor,
    k_tiles: cutlass.Int32,
) -> None:
    """Two-producer TMA pipeline: dst = A + B via parallel operand loading."""

    # Separate shared-memory buffers for A and B operands.
    smem_a = cutlass.Array(
        cutlass.Float16,
        NUM_STAGES * TILE_M * TILE_K,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    smem_b = cutlass.Array(
        cutlass.Float16,
        NUM_STAGES * TILE_M * TILE_K,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    mbar = cutlass.Array(
        cutlass.Int64, 2 * NUM_STAGES, space=cutlass.AddressSpace.smem, alignment=8
    )
    full_bar = mbar  # count=2: both producers must arrive
    empty_bar = mbar.subview(NUM_STAGES)  # count=1: one consumer

    bidx, _, _ = cute.arch.block_idx()
    coord_m = bidx * TILE_M

    # Use tidx // 32 (logical warp) rather than %warpid (physical hardware slot).
    # On SM100 (Blackwell), %warpid is a physical slot ID that may not be 0/1/2
    # for a 3-warp block — logical warp (tidx // 32) always gives the correct index.
    tidx, _, _ = cute.arch.thread_idx()
    warp_idx = tidx // 32

    # ------------------------------------------------------------------
    # Init: full_bar count=2 (both producers), empty_bar count=1 (consumer).
    #
    # count=2 means full_bar fires only when BOTH producers have called
    # arrive_expect_tx AND TMA has delivered all expected bytes from both.
    # ------------------------------------------------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(NUM_STAGES):
                prims.mbarrier_init(full_bar.subview(i), 2)  # count=2!
                prims.mbarrier_init(empty_bar.subview(i), 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # Pre-signal empty_bar: mark all stages as initially free.
    if warp_idx == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(NUM_STAGES):
                prims.mbarrier_arrive(empty_bar.subview(i))
    prims.barrier_cta_sync(0)

    a_ptr = tma_a_desc.get_ptr()
    b_ptr = tma_b_desc.get_ptr()

    # ------------------------------------------------------------------
    # Producer-A (warp 0): loads A operand for ALL K-tiles.
    #
    # arrive_expect_tx specifies only A's descriptor-derived byte count.
    # The barrier aggregates this with producer-B's byte count.
    # ------------------------------------------------------------------
    if warp_idx == _WARP_PROD_A:
        for k in cutlass.range(k_tiles):
            s = k % NUM_STAGES
            parity_empty = (k // NUM_STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                empty_bar.subview(s), parity_empty, time_limit=10_000_000
            ):
                pass

            k_coord = k * TILE_K
            if prims.elect_sync():
                prims.mbarrier_arrive_expect_tx(
                    full_bar.subview(s), tma_a_desc.global_tx_bytes()
                )
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_a.subview(s * TILE_M * TILE_K),
                    a_ptr,
                    (k_coord, coord_m),
                    full_bar.subview(s),
                )

    # ------------------------------------------------------------------
    # Producer-B (warp 1): loads B operand for ALL K-tiles.
    #
    # Same stage, same full_bar — but different operand and byte count.
    # ------------------------------------------------------------------
    if warp_idx == _WARP_PROD_B:
        for k in cutlass.range(k_tiles):
            s = k % NUM_STAGES
            parity_empty = (k // NUM_STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                empty_bar.subview(s), parity_empty, time_limit=10_000_000
            ):
                pass

            k_coord = k * TILE_K
            if prims.elect_sync():
                prims.mbarrier_arrive_expect_tx(
                    full_bar.subview(s), tma_b_desc.global_tx_bytes()
                )
            if prims.elect_sync():
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_b.subview(s * TILE_M * TILE_K),
                    b_ptr,
                    (k_coord, coord_m),
                    full_bar.subview(s),
                )

    # ------------------------------------------------------------------
    # Consumer (warp 2): reads A and B from shared memory, writes A+B to dst.
    #
    # full_bar fires only after BOTH producers have arrived AND TMA has
    # delivered both descriptor boxes' total bytes.
    # ------------------------------------------------------------------
    if warp_idx == _WARP_CONS:
        lane = tidx % 32
        dst_ptr = dst.iterator.raw_ptr()
        smem_a_ptr = smem_a.data_ptr()
        smem_b_ptr = smem_b.data_ptr()

        for k in cutlass.range(k_tiles):
            s = k % NUM_STAGES
            parity_full = (k // NUM_STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                full_bar.subview(s), parity_full, time_limit=10_000_000
            ):
                pass

            prims.bar_warp_sync(cute.arch.FULL_MASK)

            # Elementwise add: A + B → dst.
            # Each warp covers TILE_M rows total (TILE_M/32 row groups × 32 threads).
            k_offset = k * TILE_K
            smem_base = s * TILE_M * TILE_K

            for row_group in cutlass.range_constexpr(TILE_M // 32):
                row = row_group * 32 + lane
                for col in cutlass.range_constexpr(TILE_K):
                    # TMA s128b swizzle: physical col = (col_group XOR (row & 7)) * 8 + col_rem
                    col_group = col // 8
                    col_rem = col % 8
                    phys_col = (col_group ^ (row & 7)) * 8 + col_rem
                    idx = smem_base + row * TILE_K + phys_col
                    a_val = (smem_a_ptr + idx).load()
                    b_val = (smem_b_ptr + idx).load()
                    dst_idx = (coord_m + row) * (k_tiles * TILE_K) + k_offset + col
                    (dst_ptr + dst_idx).store(a_val + b_val)

            # Release: signal slot is free for both producers to reuse.
            if prims.elect_sync():
                prims.mbarrier_arrive(empty_bar.subview(s))


# ---------------------------------------------------------------------------
# Host
# ---------------------------------------------------------------------------


@cute.jit
def host(a: cute.Tensor, b: cute.Tensor, dst: cute.Tensor, k_tiles: int) -> None:
    """Build TMA descriptors for A and B, launch kernel."""
    # Both a and b are (M, K) row-major fp16.  TMA col-major: K innermost.
    tma_a_desc = cuda.create_tensor_map_tiled(
        global_address=a.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[a.shape[1], a.shape[0]],  # [K, M]
        global_strides=[a.shape[1] * 2 // 16],  # row stride in 16-B units
        box_dims=[TILE_K, TILE_M],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    tma_b_desc = cuda.create_tensor_map_tiled(
        global_address=b.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[b.shape[1], b.shape[0]],  # [K, M]
        global_strides=[b.shape[1] * 2 // 16],
        box_dims=[TILE_K, TILE_M],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    m_tiles = a.shape[0] // TILE_M
    kernel(tma_a_desc, tma_b_desc, dst, k_tiles).launch(
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
    fake_a = make_fake_compact_tensor(
        cutlass.Float16, (sym_m, k), stride_order=(1, 0), assumed_align=16
    )
    fake_b = make_fake_compact_tensor(
        cutlass.Float16, (sym_m, k), stride_order=(1, 0), assumed_align=16
    )
    fake_dst = make_fake_compact_tensor(
        cutlass.Float16, (sym_m, k), stride_order=(1, 0), assumed_align=16
    )
    return cute.compile(
        host, fake_a, fake_b, fake_dst, k_tiles, options="--enable-tvm-ffi"
    )


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

    a = torch.ones(m, k, dtype=torch.float16, device="cuda")
    b = torch.ones(m, k, dtype=torch.float16, device="cuda") * 2.0
    dst = torch.zeros(m, k, dtype=torch.float16, device="cuda")

    compiled_fn(a, b, dst, k_tiles)
    torch.cuda.synchronize()

    expected = a + b  # 1 + 2 = 3
    return dst, expected


def verify(m: int = _DEFAULT_M, k_tiles: int = _DEFAULT_K_TILES) -> None:
    dst, expected = run(m=m, k_tiles=k_tiles)
    torch.testing.assert_close(dst, expected, atol=0, rtol=0)
    print(
        f"PASS  TMA count=2 pipeline  "
        f"M={m} K={k_tiles * TILE_K} ({k_tiles} tiles x {TILE_K})  "
        f"STAGES={NUM_STAGES}  "
        f"dst[0,0]={dst[0, 0].item()} (expected {expected[0, 0].item()})"
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
