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
Warp-specialized software-fill pipeline (non-TMA): global → shared → global.

Demonstrates the producer-consumer pattern using ``cutlass.primitives.mbarrier_arrive``
for software signaling — the non-TMA alternative to ``arrive_expect_tx``.

Key patterns:

  - Two mbarrier arrays: ``full_bar`` (data ready) and ``empty_bar`` (slot free)
  - **Pre-signal trick**: all ``empty_bar[s]`` are arrived once in the prologue
    so the producer's very first ``wait(empty_bar, parity=0)`` passes
    immediately (fresh bar at parity 0 ≠ wait parity 0 after one arrive).
  - Producer warp: wait(empty_bar) → fill shared memory with direct register stores
    → arrive(full_bar)
  - Consumer warp: wait(full_bar) → read shared memory → arrive(empty_bar)
  - Parity formula: ``phase = (k // STAGES) & 1`` for both bars
  - **No** ``arrive_expect_tx`` — TMA is not involved; each thread writes
    its own elements

Contrasts with:

  - ``async_pipeline.py``: single warp is both producer and consumer (no
    warp specialization, both barriers per thread in the same loop)
  - ``tma/tma_1cta_mbarrier.py``: TMA producer, uses
    ``arrive_expect_tx`` + ``cp_async_bulk_tensor_shared_cta_global``

Requires SM90+ (Hopper) for mbarrier hardware.

Public API (mirrors ``examples/template_kernel.py``):
  - :func:`compile` — AOT factory keyed on ``TILE``, ``STAGES``.
  - :func:`run`     — allocate src/dst, call compiled fn, return ``(dst, src)``.
  - :func:`verify`  — compile + run + assert vs reference.

To run::

    python CuTeDSL/experimental/primitives/pipeline_software_fill.py
    python CuTeDSL/experimental/primitives/pipeline_software_fill.py --STAGES 4 --num_tiles 32

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

_BLOCK: int = 64  # 2 warps: warp 0 = producer, warp 1 = consumer (fixed)


# ---------------------------------------------------------------------------
# Kernel Configurations — tunable (exposed via argparser / compile)
# ---------------------------------------------------------------------------

_DEFAULT_TILE: int = 32  # float32 elements per stage     (compile-time Constexpr)
_DEFAULT_STAGES: int = 2  # pipeline depth                 (compile-time Constexpr)

# ---------------------------------------------------------------------------
# Default problem sizes
# ---------------------------------------------------------------------------

_DEFAULT_NUM_TILES: int = 16  # number of tiles per block (runtime cutlass.Int32)


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    src: cute.Tensor,
    dst: cute.Tensor,
    num_tiles: cutlass.Int32,
    TILE: cutlass.Constexpr,
    STAGES: cutlass.Constexpr,
):
    """Warp-specialized STAGES-stage software-fill pipeline: src → smem → dst."""

    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()
    warp_idx = tidx // 32
    lane = tidx % 32

    # ------------------------------------------------------------------
    # Step 1 — Allocate shared-memory data buffer and two mbarrier arrays.
    # ------------------------------------------------------------------
    smem_buf = cutlass.Array(
        cutlass.Float32, STAGES * TILE, space=cutlass.AddressSpace.smem
    )
    mbar = cutlass.Array(cutlass.Int64, 2 * STAGES, space=cutlass.AddressSpace.smem)
    full_bar = mbar
    empty_bar = mbar.subview(STAGES)

    # ------------------------------------------------------------------
    # Step 2 — Init barriers (one elected thread, constexpr loop).
    # ------------------------------------------------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(STAGES):
                prims.mbarrier_init(full_bar.subview(i), 1)
                prims.mbarrier_init(empty_bar.subview(i), 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    # ------------------------------------------------------------------
    # Step 3 — Pre-signal empty_bar (producer warp only).
    # ------------------------------------------------------------------
    if warp_idx == 0:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(STAGES):
                prims.mbarrier_arrive(empty_bar.subview(i))
    prims.barrier_cta_sync(0)

    # ------------------------------------------------------------------
    # Step 4 — Producer warp (warp 0): fill pipeline.
    # ------------------------------------------------------------------
    if warp_idx == 0:
        for k in cutlass.range(num_tiles):
            s = k % STAGES
            phase = (k // STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                empty_bar.subview(s), phase, time_limit=10_000_000
            ):
                pass

            global_idx = bidx * (num_tiles * TILE) + k * TILE + lane
            smem_buf[s * TILE + lane] = src[global_idx]

            # Sync: ensure all 32 lane writes are done before signaling consumer.
            prims.barrier_cta_sync(0, thread_count=32)

            if prims.elect_sync():
                prims.mbarrier_arrive(full_bar.subview(s))

    # ------------------------------------------------------------------
    # Step 5 — Consumer warp (warp 1): drain pipeline.
    # ------------------------------------------------------------------
    if warp_idx == 1:
        for k in cutlass.range(num_tiles):
            s = k % STAGES
            phase = (k // STAGES) & 1

            while not prims.mbarrier_try_wait_parity(
                full_bar.subview(s), phase, time_limit=10_000_000
            ):
                pass

            global_idx = bidx * (num_tiles * TILE) + k * TILE + lane
            dst[global_idx] = smem_buf[s * TILE + lane]

            if prims.elect_sync():
                prims.mbarrier_arrive(empty_bar.subview(s))


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    src: cute.Tensor,
    dst: cute.Tensor,
    num_tiles: cutlass.Int32,
    TILE: cutlass.Constexpr,
    STAGES: cutlass.Constexpr,
):
    """Launch the software-fill pipeline kernel."""
    kernel(src, dst, num_tiles, TILE, STAGES).launch(
        grid=(1, 1, 1), block=(_BLOCK, 1, 1)
    )


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(  # noqa: A001
    TILE: int = _DEFAULT_TILE,
    STAGES: int = _DEFAULT_STAGES,
) -> Callable:
    """AOT-compile :func:`host`; cache by ``(TILE, STAGES)``."""
    if TILE != 32:
        # Producer fills with 32 lanes (warp 0) — kernel hard-codes one element per lane.
        raise ValueError(f"TILE must be 32 (one element per warp lane), got {TILE}")
    sym_n = cute.sym_int64(divisibility=TILE)
    fake_src = make_fake_compact_tensor(cutlass.Float32, (sym_n,))
    fake_dst = make_fake_compact_tensor(cutlass.Float32, (sym_n,))
    fake_num_tiles = cutlass.Int32(0)
    return cute.compile(
        host,
        fake_src,
        fake_dst,
        fake_num_tiles,
        TILE,
        STAGES,
        options="--enable-tvm-ffi",
    )


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(
    compiled_fn: Callable,
    num_tiles: int = _DEFAULT_NUM_TILES,
    TILE: int = _DEFAULT_TILE,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate src/dst, call compiled_fn, return ``(dst, src)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    n = TILE * num_tiles
    src = torch.arange(n, dtype=torch.float32, device="cuda")
    dst = torch.zeros(n, dtype=torch.float32, device="cuda")
    compiled_fn(src, dst, num_tiles)
    torch.cuda.synchronize()
    return dst, src


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(
    num_tiles: int = _DEFAULT_NUM_TILES,
    TILE: int = _DEFAULT_TILE,
    STAGES: int = _DEFAULT_STAGES,
) -> None:
    """Compile, run, and assert dst == src."""
    compiled_fn = compile(TILE=TILE, STAGES=STAGES)
    print(f"Compile kernel (TILE={TILE}, STAGES={STAGES}) OK", flush=True)

    dst, src = run(compiled_fn, num_tiles=num_tiles, TILE=TILE)
    print(
        f"Run kernel (num_tiles={num_tiles}, TILE={TILE}, STAGES={STAGES}) OK",
        flush=True,
    )

    torch.testing.assert_close(dst, src)
    print(
        f"verify (num_tiles={num_tiles}, STAGES={STAGES}, TILE={TILE}): PASS  "
        f"dst[:4] = {dst[:4].tolist()}"
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="warp-spec software-fill pipeline (non-TMA)",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--num_tiles",
        type=int,
        default=None,
        help="number of tiles  [runtime cutlass.Int32]",
    )
    p.add_argument(
        "--TILE",
        type=int,
        default=_DEFAULT_TILE,
        help="elements per tile  [compile-time cutlass.Constexpr]",
    )
    p.add_argument(
        "--STAGES",
        type=int,
        default=_DEFAULT_STAGES,
        help="pipeline depth  [compile-time cutlass.Constexpr]",
    )
    args = p.parse_args()

    if args.num_tiles is not None:
        verify(num_tiles=args.num_tiles, TILE=args.TILE, STAGES=args.STAGES)
    else:
        verify(num_tiles=_DEFAULT_NUM_TILES, STAGES=args.STAGES)
        verify(num_tiles=_DEFAULT_NUM_TILES * 2, STAGES=args.STAGES)
