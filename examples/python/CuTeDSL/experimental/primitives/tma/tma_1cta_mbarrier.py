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
TMA 2-D tile load: global → shared → global, single thread block.

Demonstrates the core TMA + mbarrier building blocks:

  - :func:`~cutlass.experimental.cuda.create_tensor_map_tiled` —
    build a TMA descriptor with explicit global dims, strides, and box dims.
  - ``cutlass.GridConstant[cuda.TensorMap]`` — kernel parameter annotation that injects
    ``cuda.grid_constant`` into the compiled IR, avoiding a descriptor copy
    on every launch.
  - ``desc.get_ptr()`` — obtain a pointer to the TensorMap for use in TMA
    intrinsic calls inside ``@cute.kernel``.
  - :func:`~cutlass.primitives.mbarrier_init` / :func:`~cutlass.primitives.mbarrier_arrive_expect_tx`
    / :func:`~cutlass.primitives.mbarrier_try_wait_parity_timelimit` — explicit
    mbarrier-based producer/consumer synchronization.

Setup
-----
The example loads a single (TILE_M, TILE_K) fp16 tile from ``src`` into shared
memory, then stores it back to ``dst``.  Swizzle ``s128b`` requires:

    TILE_K * sizeof(fp16) == 128  →  TILE_K = 64

Single thread block (PTX CTA), 128 threads (4 warps).

To run::

    source /path/to/env.sh
    python CuTeDSL/experimental/primitives/tma/tma_1cta_mbarrier.py

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
TILE_M = 128  # rows to load per kernel launch
TILE_K = 64  # cols to load; s128b swizzle requires TILE_K * 2 == 128

_TILE_BYTES = TILE_M * TILE_K * 2  # fp16 = 2 bytes per element
_THREADS = 128  # 4 warps of 32 threads


# ---------------------------------------------------------------------------
# CUDA kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    tma_src_desc: cutlass.GridConstant[cuda.TensorMap],
    dst: cute.Tensor,
    coord_m: cutlass.Int32,
    coord_k: cutlass.Int32,
) -> None:
    """Load one (TILE_M, TILE_K) fp16 tile from global via TMA, store to dst.

    Producer/consumer protocol (single-stage, no double-buffering):

    1. One elected thread initialises the mbarrier (arrive-count = 1).
    2. ``fence_mbarrier_init`` + ``barrier`` make the init visible
       thread-block-wide.
    3. The elected thread calls ``arrive_expect_tx`` — this registers the
       expected byte count *and* counts as the single software arrive.
    4. The elected thread issues ``cp_async_bulk_tensor_shared_cta_global`` to
       start the TMA load.  TMA hardware sends ``complete_tx`` automatically
       when all bytes arrive, decrementing the mbarrier's transaction counter.
    5. All threads spin on ``mbarrier_try_wait_parity_timelimit`` until the
       barrier fires (parity transitions 0 → 1).
    6. ``barrier`` fences visibility before threads read shared memory.
    7. All 128 threads cooperatively store shared → dst (stride-1 in K).
    """
    smem = cutlass.Array(
        cutlass.Float16, TILE_M * TILE_K, space=cutlass.AddressSpace.smem, alignment=128
    )
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)

    warp_idx = cute.arch.warp_idx()
    tidx, _, _ = cute.arch.thread_idx()

    # ---- Initialise mbarrier (one elected thread) --------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            # arrive_count = 1: arrive_expect_tx serves as the single software arrive.
            prims.mbarrier_init(mbar, 1)
    # Make mbarrier_init visible to all threads before any arrive/wait calls.
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # ---- Producer: set expected tx bytes, then issue TMA load ---------------
    if warp_idx == 0:
        if prims.elect_sync():
            # Registers the descriptor-derived expected TMA byte count AND
            # counts as the single software arrive (arrive_count satisfied).
            prims.mbarrier_arrive_expect_tx(mbar, tma_src_desc.global_tx_bytes())
        if prims.elect_sync():
            # TMA load: coords are (innermost, outermost) = (K, M) because
            # create_tensor_map_tiled_from_view reorders dims to TMA's
            # column-major layout (innermost dimension first in descriptor).
            prims.cp_async_bulk_tensor_shared_cta_global(
                smem,
                tma_src_desc.get_ptr(),  # TensorMap pointer, not the descriptor object
                (coord_k, coord_m),
                mbar,  # TMA column-major: K first, M second
            )

    # ---- Consumer: all threads wait for TMA to complete --------------------
    # parity = 0: wait until mbar fires (the phase bit flips to 1).
    parity = cutlass.Int32(0)
    while not prims.mbarrier_try_wait_parity(mbar, parity, time_limit=10_000_000):
        pass

    # Fence: ensure TMA writes are visible before threads read shared memory.
    prims.barrier_cta_sync(0)

    # ---- Store shared → dst (128 threads × 64 K-elements per row) ----------
    # Each thread handles one element per row.  Total = 128 × 64 = 8192 elements.
    lane = tidx % cutlass.Int32(32)  # 0..31 within warp
    warp = tidx // cutlass.Int32(32)  # 0..3

    dst_ptr = dst.iterator.raw_ptr()
    smem_ptr = smem.data_ptr()
    for k in cutlass.range_constexpr(TILE_K):
        row = warp * cutlass.Int32(32) + lane  # thread maps to one row
        # TMA s128b swizzle: physical smem column = (k_group XOR (row & 7)) * 8 + k_rem
        # Must de-swizzle when reading back to get logical element (row, k).
        k_group = k // 8
        k_rem = k % 8
        phys_k = (cutlass.Int32(k_group) ^ (row & cutlass.Int32(7))) * cutlass.Int32(
            8
        ) + cutlass.Int32(k_rem)
        smem_idx = row * cutlass.Int32(TILE_K) + phys_k
        dst_idx = row * cutlass.Int32(TILE_K) + cutlass.Int32(k)
        elem = (smem_ptr + smem_idx).load()
        (dst_ptr + dst_idx).store(elem)


# ---------------------------------------------------------------------------
# Host function
# ---------------------------------------------------------------------------


@cute.jit
def host(src: cute.Tensor, dst: cute.Tensor) -> None:
    """Build TMA descriptor and launch kernel to copy tile (0, 0)."""
    # src is (M, K) row-major; TMA column-major: innermost (K) dimension first.
    # global_strides: row stride in 16-byte units = TILE_K * sizeof(fp16) / 16 = 8.
    tma_src_desc = cuda.create_tensor_map_tiled(
        global_address=src.iterator.toint(),
        dtype=cutlass.Float16,
        global_dims=[TILE_K, src.shape[0]],  # [K, M] — K innermost
        global_strides=[TILE_K * 2 // 16],  # row stride in 16-B units
        box_dims=[TILE_K, TILE_M],  # TMA col-major: K box, M box
        swizzle=cuda.TensorMapSwizzle.s128b,
    )
    kernel(
        tma_src_desc,
        dst,
        cutlass.Int32(0),  # coord_m: row offset in global memory
        cutlass.Int32(0),  # coord_k: col offset in global memory
    ).launch(grid=(1, 1, 1), block=(_THREADS, 1, 1))


def _check_src_rows(src_rows: int) -> None:
    if src_rows < TILE_M:
        raise ValueError(f"src_rows must be at least TILE_M ({TILE_M}), got {src_rows}")


def BYTES_FORMULA(src_rows: int = TILE_M, **_) -> int:
    # One TMA load tile plus one global store of the same tile. The kernel
    # always transfers TILE_M * TILE_K fp16; src_rows only changes the source
    # tensor/descriptor extent used to back that fixed tile.
    _check_src_rows(src_rows)
    return 2 * _TILE_BYTES


@lru_cache(maxsize=None)
def compile(**_) -> Callable:
    """AOT-compile host with symbolic M (K is concrete at 64)."""
    sym_m = cute.sym_int64()
    fake_src = make_fake_compact_tensor(
        cutlass.Float16, (sym_m, TILE_K), stride_order=(1, 0), assumed_align=16
    )
    fake_dst = make_fake_compact_tensor(
        cutlass.Float16, (sym_m, TILE_K), stride_order=(1, 0), assumed_align=16
    )
    return cute.compile(host, fake_src, fake_dst, options="--enable-tvm-ffi")


def prepare_tensors(src_rows: int = TILE_M, **_) -> dict[str, torch.Tensor]:
    _check_src_rows(src_rows)
    src = torch.arange(src_rows * TILE_K, dtype=torch.float16, device="cuda").view(
        src_rows, TILE_K
    )
    dst = torch.zeros(TILE_M, TILE_K, dtype=torch.float16, device="cuda")
    return {"src": src, "dst": dst}


def verify_output(tensors: dict[str, torch.Tensor], **_) -> None:
    torch.testing.assert_close(tensors["dst"], tensors["src"][:TILE_M], atol=0, rtol=0)


def run(
    compiled_fn: Callable | None = None,
    tensors: dict[str, torch.Tensor] | None = None,
    stream=None,
) -> None:
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    if compiled_fn is not None:
        if tensors is None:
            raise ValueError("tensors must be provided when compiled_fn is provided")
        del stream  # implicit via current torch stream
        compiled_fn(tensors["src"][:TILE_M], tensors["dst"])
        return

    compiled = compile()
    tensors = prepare_tensors(src_rows=TILE_M)
    compiled(tensors["src"], tensors["dst"])

    verify_output(tensors)
    print(
        "PASS  src[0, :4] = "
        f"{tensors['src'][0, :4].tolist()}  dst[0, :4] = "
        f"{tensors['dst'][0, :4].tolist()}"
    )


def verify() -> None:
    """Compile, run, and assert the single-block TMA load example."""
    run()


def main() -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.parse_args()
    verify()


if __name__ == "__main__":
    main()
