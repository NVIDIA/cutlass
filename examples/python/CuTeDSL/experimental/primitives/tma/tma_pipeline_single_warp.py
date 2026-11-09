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
TMA multi-stage pipeline: NUM_STAGES-buffered TMA load, single warp.

Extends ``tma_1cta_mbarrier.py`` from a single-shot load to a full
N-stage (double or triple) prefetch pipeline over multiple K-tiles.

Demonstrates:

  - ``full_bar[NUM_STAGES]`` array for tracking TMA completion per stage
  - Prologue: fill the first ``NUM_PREFETCH`` stages before the main loop
  - Main loop: issue next fill BEFORE waiting on current drain — safe
    because ``fill_stage != drain_stage`` when ``NUM_PREFETCH < NUM_STAGES``
  - Parity formula: ``(k // NUM_STAGES) & 1``
  - **No empty_bar needed** when one warp is both TMA producer and consumer:
    sequential PC guarantees the stage is drained before it can be refilled
    (fill_stage cycles ahead by NUM_PREFETCH steps)

This is the simplest TMA pipeline pattern — a useful stepping stone before
warp-specialized (producer/consumer split) kernels that add ``empty_bar``.

The kernel performs an elementwise copy of M rows × (K_TILES × TILE_K) cols
of fp16 data, loading each (TILE_M, TILE_K) tile via TMA and storing to dst.

Requires SM90+ (Hopper+) for TMA.

To run::

    python CuTeDSL/experimental/primitives/tma/tma_pipeline_single_warp.py

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
_THREADS = 128  # 4 warps; only warp 0 issues TMA


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
    dst: cute.Tensor,
    k_tiles: cutlass.Int32,  # number of K-tiles
) -> None:
    """NUM_STAGES-buffered TMA pipeline: copy all K-tiles of one block's rows.

    Pipeline invariant: ``fill_stage = (k + NUM_PREFETCH) % NUM_STAGES``.
    The fill always leads the drain by NUM_PREFETCH steps so their stages
    never alias (required: NUM_PREFETCH < NUM_STAGES).
    """
    # Allocate shared memory: data buffer + mbarrier array.
    smem = cutlass.Array(
        cutlass.Float16,
        NUM_STAGES * TILE_M * TILE_K,
        space=cutlass.AddressSpace.smem,
        alignment=128,
    )
    mbar = cutlass.Array(
        cutlass.Int64, NUM_STAGES, space=cutlass.AddressSpace.smem, alignment=8
    )
    full_bar = mbar  # one barrier per stage

    coord_m, _, _ = cute.arch.block_idx()
    coord_m *= TILE_M
    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()

    # ------------------------------------------------------------------
    # Init: one elected thread initialises all NUM_STAGES barriers.
    # ------------------------------------------------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(NUM_STAGES):
                prims.mbarrier_init(full_bar.subview(i), 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    src_ptr = tma_src_desc.get_ptr()

    # ------------------------------------------------------------------
    # Prologue: issue the first NUM_PREFETCH TMA loads.
    #
    # These fill stages 0 .. NUM_PREFETCH-1 without waiting for any prior
    # drain — there is nothing to drain yet.
    # ------------------------------------------------------------------
    if warp_idx == 0:
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
                    full_bar.subview(s),  # TMA column-major: K first, M second
                )
    prims.barrier_cta_sync(0)

    # ------------------------------------------------------------------
    # Main loop: drain stage drain_s then issue fill for fill_k.
    #
    # Issue fill BEFORE waiting for drain — safe because fill_s != drain_s
    # as long as NUM_PREFETCH < NUM_STAGES.
    # ------------------------------------------------------------------
    for k in cutlass.range(k_tiles):
        drain_s = k % NUM_STAGES
        drain_p = (k // NUM_STAGES) & 1

        fill_k = k + NUM_PREFETCH

        # Issue next fill (if within bounds) BEFORE waiting for current drain.
        if warp_idx == 0:
            if fill_k < k_tiles:
                fill_s = fill_k % NUM_STAGES
                k_coord = fill_k * TILE_K
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

        # Wait for stage drain_s to be full.
        while not prims.mbarrier_try_wait_parity(
            full_bar.subview(drain_s), drain_p, time_limit=10_000_000
        ):
            pass

        prims.barrier_cta_sync(
            0
        )  # all threads see TMA writes before reading shared memory

        # ------------------------------------------------------------------
        # Store: all threads cooperatively copy shared-memory tile → dst.
        #
        # Each thread handles one element per row within the tile.
        # Layout: smem[drain_s * TILE_M * TILE_K + row * TILE_K + col]
        # ------------------------------------------------------------------
        lane = tidx % 32
        warp = tidx // 32
        k_offset = k * TILE_K
        smem_base = drain_s * TILE_M * TILE_K
        dst_ptr = dst.iterator.raw_ptr()
        smem_ptr = smem.data_ptr()

        for col in cutlass.range_constexpr(TILE_K):
            row = warp * 32 + lane
            # TMA s128b swizzle: physical col = (col_group XOR (row & 7)) * 8 + col_rem
            col_group = col // 8
            col_rem = col % 8
            phys_col = (col_group ^ (row & 7)) * 8 + col_rem
            smem_idx = smem_base + row * TILE_K + phys_col
            dst_idx = (coord_m + row) * (k_tiles * TILE_K) + k_offset + col
            (dst_ptr + dst_idx).store((smem_ptr + smem_idx).load())


# ---------------------------------------------------------------------------
# Host
# ---------------------------------------------------------------------------


@cute.jit
def host(src: cute.Tensor, dst: cute.Tensor, k_tiles: int) -> None:
    """Build TMA descriptor and launch one thread block per M tile."""
    # src is (M, K) row-major fp16.  TMA col-major: K innermost.
    tma_src_desc = cuda.create_tensor_map_tiled(
        global_address=src.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[src.shape[1], src.shape[0]],  # [K, M]
        global_strides=[src.shape[1] * 2 // 16],  # row stride in 16-B units
        box_dims=[TILE_K, TILE_M],
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    # One thread block copies TILE_M rows; launch enough blocks to cover all rows.
    m_tiles = src.shape[0] // TILE_M
    kernel(tma_src_desc, dst, k_tiles).launch(
        grid=(m_tiles, 1, 1), block=(_THREADS, 1, 1)
    )


# ---------------------------------------------------------------------------
# Compile and run
# ---------------------------------------------------------------------------

_DEFAULT_K_TILES = 4
_DEFAULT_M = TILE_M  # one thread block's worth of rows


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
        f"PASS  TMA {NUM_STAGES}-stage pipeline  "
        f"M={m} K={k_tiles * TILE_K} ({k_tiles} tiles × {TILE_K})  "
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
