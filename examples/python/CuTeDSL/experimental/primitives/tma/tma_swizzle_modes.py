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
TMA swizzle modes: none / s32b / s64b / s128b.

Demonstrates how to parametrize a kernel over all four TMA swizzle modes and
over the per-call vector width ``CHUNK``:

  - ``SWIZZLE_TABLE`` maps a mode string to a
    ``(TensorMapSwizzle, cutlass.Swizzle, box_k)`` tuple resolved at DSL trace
    time (``SWIZZLE`` is ``cutlass.Constexpr``).
  - ``CHUNK`` is a compile-time parameter controlling how many fp16 elements
    each ``load_swizzled`` call returns. Defaults to 16 fp16 elements, the
    smallest TMA swizzle period used here. Set ``--chunk 8`` to fall back to a
    per-atom loop, ``--chunk 16/32/64`` for wider loads where the selected
    swizzle mode allows them.
  - Each (swizzle mode, CHUNK) pair compiles to its own binary via
    ``@lru_cache`` + ``compile()``.
  - ``load_swizzled`` reads shared memory back into logical order regardless
    of the physical swizzle layout; CuTe tensor layout handles the XOR re-map for
    any ``count`` that divides the per-thread row span.
  - ``verify()`` loops over all four swizzle modes at the default CHUNK
    and asserts ``dst == src``.

Setup
-----
Single thread block (PTX CTA), 128 threads (4 warps), one (TILE_M, TILE_K)
fp16 tile.
TMA loads the tile into shared memory with the requested hardware swizzle.
The kernel reads shared memory back using ``load_swizzled`` with the matching
``cutlass.Swizzle`` and stores linearly to ``dst``. For ``"none"``
``cutlass.Swizzle(0, 0, 0)`` is the identity — ``load_swizzled`` degenerates to
a regular vector load.

TMA requires the contiguous box dimension to match the selected swizzle width:
16 fp16 elements for s32b, 32 for s64b, and 64 for s128b. This example keeps
the logical row at TILE_K = 64 fp16 by issuing multiple TMA boxes for the
smaller swizzles and reading each packed box back into the correct row segment.

To run::

    python CuTeDSL/experimental/primitives/tma/tma_swizzle_modes.py

To run a specific mode::

    python CuTeDSL/experimental/primitives/tma/tma_swizzle_modes.py --swizzle s64b

To experiment with the vector width (must divide the selected swizzle's TMA
box width)::

    python CuTeDSL/experimental/primitives/tma/tma_swizzle_modes.py --chunk 8
    python CuTeDSL/experimental/primitives/tma/tma_swizzle_modes.py --chunk 32
    python CuTeDSL/experimental/primitives/tma/tma_swizzle_modes.py --chunk 64

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
TILE_K = 64  # logical cols per tile; 64 x 2 B = 128 B per row

_TILE_BYTES = TILE_M * TILE_K * 2  # fp16 = 2 bytes
_THREADS = 128  # 4 warps of 32 threads

# CHUNK — fp16 elements per ``load_swizzled`` / ``store`` call. Compile-time
# parameter; threaded through the kernel via ``cutlass.Constexpr``. Any positive
# integer that divides the selected swizzle mode's TMA box width is valid; the
# CuTe tensor layout handles the swizzle XOR re-map for any such count.
DEFAULT_CHUNK = 16  # common fp16 period for none / s32b / s64b / s128b
# Full set of CHUNK values that divide TILE_K=64. Each swizzle mode filters this
# list to values that also divide its TMA box width.
ALL_CHUNKS = tuple(c for c in (1, 2, 4, 8, 16, 32, 64) if TILE_K % c == 0)

# ---------------------------------------------------------------------------
# Swizzle table — resolved at DSL trace time when SWIZZLE is cutlass.Constexpr.
# cutlass.Swizzle(0, 0, 0) is the identity: XOR with 0 is a no-op, so
# load_swizzled degenerates to a plain vector load for "none" mode.
# ---------------------------------------------------------------------------
_SWIZZLE_TABLE = {
    "none": (cuda.TensorMapSwizzle.none, cutlass.Swizzle(0, 0, 0), TILE_K),
    "s32b": (cuda.TensorMapSwizzle.s32b, cutlass.Swizzle.from_name("s32b"), 16),
    "s64b": (cuda.TensorMapSwizzle.s64b, cutlass.Swizzle.from_name("s64b"), 32),
    "s128b": (cuda.TensorMapSwizzle.s128b, cutlass.Swizzle.from_name("s128b"), 64),
}


# ---------------------------------------------------------------------------
# CUDA kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
    dst: cute.Tensor,
    SWIZZLE: cutlass.Constexpr,
    CHUNK: cutlass.Constexpr,
) -> None:
    """Load one (TILE_M, TILE_K) fp16 tile via TMA, de-swizzle from shared memory to dst.

    Protocol:
    1. Elected thread initialises mbarrier (arrive_count = 1).
    2. ``fence_mbarrier_init`` + ``barrier`` make the init visible
       thread-block-wide.
    3. Elected thread: ``arrive_expect_tx`` + ``cp_async_bulk_tensor``.
    4. All threads spin on ``mbarrier_try_wait_parity``.
    5. ``barrier`` fences shared-memory visibility.
    6. All threads: ``load_swizzled`` row chunks from each packed TMA box,
       store linearly to dst.
    """
    _, smem_sw, tma_box_k = _SWIZZLE_TABLE[SWIZZLE]
    num_boxes = TILE_K // tma_box_k

    smem = cutlass.Array(
        cutlass.Float16, TILE_M * TILE_K, space=cutlass.AddressSpace.smem, alignment=128
    )
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()

    # ---- Initialise mbarrier (one elected thread) --------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_init(mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # ---- Producer: arrive_expect_tx + TMA load -----------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            prims.mbarrier_arrive_expect_tx(
                mbar, tma_src_desc.global_tx_bytes() * num_boxes
            )
        if prims.elect_sync():
            smem_ptr = smem.data_ptr()
            box_elems = TILE_M * tma_box_k
            for box_idx in cutlass.range_constexpr(num_boxes):
                prims.cp_async_bulk_tensor_shared_cta_global(
                    smem_ptr + box_idx * box_elems,
                    tma_src_desc.get_ptr(),
                    (box_idx * tma_box_k, 0),
                    mbar,  # (coord_k, coord_m) — TMA col-major
                )

    # ---- Consumer: wait for TMA to complete --------------------------------
    parity = 0
    while not prims.mbarrier_try_wait_parity(mbar, parity):
        pass
    prims.barrier_cta_sync(0)

    # ---- Read shared memory with load_swizzled, store linearly to dst ------
    # One row per thread: lane selects column within warp, warp selects row group.
    lane = tidx % 32
    warp = tidx // 32
    row = warp * 32 + lane

    smem_ptr = smem.data_ptr()
    dst_ptr = dst.iterator.raw_ptr()
    box_elems = TILE_M * tma_box_k

    # Per-thread row loop — CHUNK fp16 per load_swizzled call.
    # CHUNK=8 -> one 128-bit vector load per iteration. CHUNK=tma_box_k -> one
    # vector load per row segment. Any divisor of tma_box_k is legal; the CuTe
    # tensor layout applies the swizzle XOR re-map per element for any count.
    for box_idx in cutlass.range_constexpr(num_boxes):
        smem_row = smem_ptr + box_idx * box_elems + row * tma_box_k
        dst_row = dst_ptr + row * TILE_K + box_idx * tma_box_k
        for i in cutlass.range_constexpr(tma_box_k // CHUNK):
            vec = (smem_row + i * CHUNK).load_swizzled(smem_sw, count=CHUNK)
            (dst_row + i * CHUNK).store(vec)


# ---------------------------------------------------------------------------
# Host function
# ---------------------------------------------------------------------------


@cute.jit
def host(
    src: cute.Tensor,
    dst: cute.Tensor,
    SWIZZLE: cutlass.Constexpr,
    CHUNK: cutlass.Constexpr,
) -> None:
    """Build TMA descriptor with matching swizzle and launch kernel."""
    tma_sw, _, tma_box_k = _SWIZZLE_TABLE[SWIZZLE]
    tma_src_desc = cuda.create_tensor_map_tiled(
        global_address=src.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[TILE_K, TILE_M],  # TMA col-major: K innermost
        global_strides=[TILE_K * 2 // 16],  # row stride in 16-B units
        box_dims=[tma_box_k, TILE_M],
        swizzle=tma_sw,
    )
    kernel(tma_src_desc, dst, SWIZZLE, CHUNK).launch(
        grid=(1, 1, 1), block=(_THREADS, 1, 1)
    )


# ---------------------------------------------------------------------------
# Compile factory — one binary per swizzle mode, cached by lru_cache
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(SWIZZLE: str = "s128b", CHUNK: int = DEFAULT_CHUNK) -> Callable:
    """AOT-compile host for the given (swizzle mode, CHUNK) pair."""
    tma_box_k = _SWIZZLE_TABLE[SWIZZLE][2]
    if tma_box_k % CHUNK != 0:
        raise ValueError(
            f"CHUNK={CHUNK} must divide the {SWIZZLE} TMA box width "
            f"({tma_box_k} fp16 elements); valid chunks: "
            f"{valid_chunks(SWIZZLE)}"
        )
    fake_src = make_fake_compact_tensor(
        cutlass.Float16, (TILE_M, TILE_K), stride_order=(1, 0), assumed_align=16
    )
    fake_dst = make_fake_compact_tensor(
        cutlass.Float16, (TILE_M, TILE_K), stride_order=(1, 0), assumed_align=16
    )
    return cute.compile(
        host, fake_src, fake_dst, SWIZZLE, CHUNK, options="--enable-tvm-ffi"
    )


# ---------------------------------------------------------------------------
# Run and verify
# ---------------------------------------------------------------------------


def run(swizzle: str = "s128b", chunk: int = DEFAULT_CHUNK) -> None:
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    compiled = compile(SWIZZLE=swizzle, CHUNK=chunk)

    src = torch.arange(TILE_M * TILE_K, dtype=torch.float16, device="cuda").view(
        TILE_M, TILE_K
    )
    dst = torch.zeros_like(src)

    compiled(src, dst)

    torch.testing.assert_close(dst, src, atol=0, rtol=0)
    print(
        f"PASS  swizzle={swizzle!r:6s}  chunk={chunk:<3d}  "
        f"dst[0, :4] = {dst[0, :4].tolist()}"
    )


def verify(chunk: int = DEFAULT_CHUNK) -> None:
    """Run every swizzle mode at the given CHUNK width."""
    for mode in ["none", "s32b", "s64b", "s128b"]:
        run(swizzle=mode, chunk=chunk)


def verify_chunks(swizzle: str = "s128b") -> None:
    """Run the given swizzle mode across its valid CHUNK sweep."""
    for c in valid_chunks(swizzle):
        run(swizzle=swizzle, chunk=c)


def valid_chunks(swizzle: str) -> tuple[int, ...]:
    """Return CHUNK values that divide the selected swizzle's TMA box width."""
    tma_box_k = _SWIZZLE_TABLE[swizzle][2]
    return tuple(c for c in ALL_CHUNKS if tma_box_k % c == 0)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="TMA swizzle mode parametrization: none / s32b / s64b / s128b"
    )
    parser.add_argument(
        "--swizzle",
        choices=["none", "s32b", "s64b", "s128b", "all"],
        default="all",
        help="Swizzle mode to run (default: all)",
    )
    parser.add_argument(
        "--chunk",
        type=int,
        default=DEFAULT_CHUNK,
        help=(
            "fp16 elements per load_swizzled call (must divide the selected "
            "swizzle's TMA box width; "
            f"default: {DEFAULT_CHUNK}; valid values are swizzle-specific "
            f"subsets of {list(ALL_CHUNKS)})."
            " Pass 'sweep' via --chunk_sweep to iterate over all valid chunks."
        ),
    )
    parser.add_argument(
        "--chunk_sweep",
        action="store_true",
        help="For the chosen swizzle mode, sweep every valid CHUNK in ALL_CHUNKS "
        "(overrides --chunk).",
    )
    args = parser.parse_args()
    if args.chunk_sweep:
        modes = (
            ["none", "s32b", "s64b", "s128b"]
            if args.swizzle == "all"
            else [args.swizzle]
        )
        for mode in modes:
            verify_chunks(swizzle=mode)
    elif args.swizzle == "all":
        verify(chunk=args.chunk)
    else:
        run(swizzle=args.swizzle, chunk=args.chunk)
