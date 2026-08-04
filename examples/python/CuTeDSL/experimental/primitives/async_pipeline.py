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
CUTLASS primitives implementation of a staged producer/consumer async pipeline.

Demonstrates:

  - Two warp roles: producer warp 0 and consumer warp 1.
  - Two mbarrier arrays: ``empty_bar[stage]`` grants a reusable shared-memory stage
    to the producer, and ``full_bar[stage]`` grants a filled stage to the
    consumer.
  - Pipeline state: stage index, phase, and circular advancement.
  - Producer acquire:
    ``wait(empty_bar[stage], phase)`` before writing a stage.
  - Producer commit:
    fill the stage in SMEM, then elected ``mbarrier_arrive(full_bar[stage])``.
  - Consumer wait:
    ``wait(full_bar[stage], phase)`` before reading a stage.
  - Consumer release:
    read/drain the stage, then elected ``mbarrier_arrive(empty_bar[stage])``.

The example spells out the pipeline state machine using CUTLASS primitives mbarrier
primitives.  For TMA-based pipelines, the producer's commit side uses
``mbarrier_arrive_expect_tx`` plus a TMA copy instead of plain
``mbarrier_arrive``.

Pattern: elementwise copy through an S-stage shared-memory pipeline::

    producer warp: global src → [stage 0..S-1 shared memory]
    consumer warp: [stage 0..S-1 shared memory] → global dst

Conceptual flow for each stage:

.. code-block:: text

    Producer warp       empty_bar[s]    shared-memory stage    full_bar[s]    Consumer warp
         |                   |                 |                 |                 |
         | wait empty phase  |                 |                 |                 |
         |------------------>|                 |                 |                 |
         | fill from global  |                 |                 |                 |
         |------------------------------------>|                 |                 |
         | commit full       |                 |                 |                 |
         |----------------------------------------------------->|                 |
         |                   |                 |                 | wait full phase |
         |                   |                 |                 |<----------------|
         |                   |                 |                 | read to global  |
         |                   |                 |<--------------------------------|
         |                   | release empty   |                 |                 |
         |                   |<---------------------------------------------------|

Requires SM90+ (Hopper) for mbarrier hardware.

Public API (mirrors ``examples/template_kernel.py``):
  - :func:`compile` — AOT factory keyed on ``BLOCK``, ``TILE``, ``STAGES``.
  - :func:`run`     — allocate src/dst, call compiled fn, return ``(dst, src)``.
  - :func:`verify`  — compile + run + assert vs reference.

To run::

    python CuTeDSL/experimental/primitives/async_pipeline.py
    python CuTeDSL/experimental/primitives/async_pipeline.py --STAGES 4 --num_tiles 16

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
# Kernel Configurations — tunable (exposed via argparser / compile)
# ---------------------------------------------------------------------------

_WARP_SIZE: int = 32
_PRODUCER_WARP: int = 0
_CONSUMER_WARP: int = 1
_THREADS: int = 2 * _WARP_SIZE
_INIT_SYNC_BARRIER: int = 0
_PRODUCER_SYNC_BARRIER: int = 1
_CONSUMER_SYNC_BARRIER: int = 2

_DEFAULT_BLOCK: int = _THREADS  # two warps: producer + consumer
_DEFAULT_TILE: int = 128  # float32 elements per tile     (compile-time Constexpr)
_DEFAULT_STAGES: int = 2  # pipeline depth                (compile-time Constexpr)

# ---------------------------------------------------------------------------
# Default problem sizes
# ---------------------------------------------------------------------------

_DEFAULT_NUM_TILES: int = 8  # number of tiles per block (runtime cutlass.Int32)


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    src: cute.Tensor,
    dst: cute.Tensor,
    num_tiles: cutlass.Int32,
    BLOCK: cutlass.Constexpr,
    TILE: cutlass.Constexpr,
    STAGES: cutlass.Constexpr,
):
    """S-stage producer/consumer pipeline lowered to CUTLASS primitives mbarriers."""

    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()
    warp_idx = tidx // _WARP_SIZE
    lane = tidx % _WARP_SIZE
    producer = warp_idx == _PRODUCER_WARP
    consumer = warp_idx == _CONSUMER_WARP

    # ------------------------------------------------------------------
    # Step 1 — Allocate pipeline storage:
    #   - data stages
    #   - 2 * STAGES barriers: full_bar[S] and empty_bar[S]
    # ------------------------------------------------------------------
    smem_buf = cutlass.Array(
        cutlass.Float32, STAGES * TILE, space=cutlass.AddressSpace.smem
    )
    mbar = cutlass.Array(
        cutlass.Int64, 2 * STAGES, space=cutlass.AddressSpace.smem, alignment=8
    )
    full_bar = mbar
    empty_bar = mbar.subview(STAGES)

    # ------------------------------------------------------------------
    # Step 2 — Initialize barriers (elected thread, constexpr loop).
    # ------------------------------------------------------------------
    if producer:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(STAGES):
                prims.mbarrier_init(full_bar.subview(i), 1)
                prims.mbarrier_init(empty_bar.subview(i), 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(_INIT_SYNC_BARRIER)

    # ------------------------------------------------------------------
    # Step 3 — Pre-signal empty stages so producer acquire(stage 0, phase 0)
    # can pass immediately. Fresh barrier parity is 0; the arrive flips each
    # empty_bar to 1, so wait(parity=0) succeeds.
    # ------------------------------------------------------------------
    if producer:
        if prims.elect_sync():
            for i in cutlass.range_constexpr(STAGES):
                prims.mbarrier_arrive(empty_bar.subview(i))
    prims.barrier_cta_sync(_INIT_SYNC_BARRIER)

    # ------------------------------------------------------------------
    # Step 4 — Producer participant:
    #
    #   acquire empty stage
    #   fill stage
    #   commit full stage
    # ------------------------------------------------------------------
    if producer:
        for k in cutlass.range(num_tiles):
            stage = k % STAGES
            phase = (k // STAGES) & 1
            stage_base = stage * TILE
            global_base = bidx * (num_tiles * TILE) + k * TILE

            # Acquire: wait for an empty stage.
            while not prims.mbarrier_try_wait_parity(
                empty_bar.subview(stage), phase, time_limit=10_000_000
            ):
                pass

            for elem in cutlass.range(lane, TILE, cutlass.Int32(_WARP_SIZE), unroll=1):
                smem_buf[stage_base + elem] = src[global_base + elem]

            # Ensure all producer lanes have filled the stage before commit().
            prims.barrier_cta_sync(_PRODUCER_SYNC_BARRIER, thread_count=_WARP_SIZE)

            # Commit: signal that the stage is full.
            if prims.elect_sync():
                prims.mbarrier_arrive(full_bar.subview(stage))

    # ------------------------------------------------------------------
    # Step 5 — Consumer participant:
    #
    #   wait for full stage
    #   read stage
    #   release empty stage
    # ------------------------------------------------------------------
    if consumer:
        for k in cutlass.range(num_tiles):
            stage = k % STAGES
            phase = (k // STAGES) & 1
            stage_base = stage * TILE
            global_base = bidx * (num_tiles * TILE) + k * TILE

            # Wait: block until the producer commits this stage.
            while not prims.mbarrier_try_wait_parity(
                full_bar.subview(stage), phase, time_limit=10_000_000
            ):
                pass

            for elem in cutlass.range(lane, TILE, cutlass.Int32(_WARP_SIZE), unroll=1):
                dst[global_base + elem] = smem_buf[stage_base + elem]

            # Ensure all consumer lanes are done before release().
            prims.barrier_cta_sync(_CONSUMER_SYNC_BARRIER, thread_count=_WARP_SIZE)

            # Release: signal that the stage can be reused.
            if prims.elect_sync():
                prims.mbarrier_arrive(empty_bar.subview(stage))


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    src: cute.Tensor,
    dst: cute.Tensor,
    num_tiles: cutlass.Int32,
    BLOCK: cutlass.Constexpr,
    TILE: cutlass.Constexpr,
    STAGES: cutlass.Constexpr,
):
    """Launch the S-stage pipeline kernel."""
    kernel(src, dst, num_tiles, BLOCK, TILE, STAGES).launch(
        grid=(1, 1, 1), block=(BLOCK, 1, 1)
    )


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(  # noqa: A001
    BLOCK: int = _DEFAULT_BLOCK,
    TILE: int = _DEFAULT_TILE,
    STAGES: int = _DEFAULT_STAGES,
) -> Callable:
    """AOT-compile :func:`host`; cache by ``(BLOCK, TILE, STAGES)``.

    ``num_tiles`` (and therefore ``n``) stays runtime: pass any value
    when calling the compiled fn.
    """
    if BLOCK != _THREADS:
        raise ValueError(
            f"async_pipeline models one producer warp and one consumer warp; "
            f"BLOCK must be {_THREADS}, got {BLOCK}"
        )
    sym_n = cute.sym_int64(divisibility=TILE)
    fake_src = make_fake_compact_tensor(cutlass.Float32, (sym_n,))
    fake_dst = make_fake_compact_tensor(cutlass.Float32, (sym_n,))
    fake_num_tiles = cutlass.Int32(0)
    return cute.compile(
        host,
        fake_src,
        fake_dst,
        fake_num_tiles,
        BLOCK,
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
    BLOCK: int = _DEFAULT_BLOCK,
    TILE: int = _DEFAULT_TILE,
    STAGES: int = _DEFAULT_STAGES,
) -> None:
    """Compile, run, and assert dst == src."""
    compiled_fn = compile(BLOCK=BLOCK, TILE=TILE, STAGES=STAGES)
    print(
        f"Compile kernel (BLOCK={BLOCK}, TILE={TILE}, STAGES={STAGES}) OK",
        flush=True,
    )

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
        description="async_pipeline — full_bar/empty_bar S-stage pipeline",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--num_tiles",
        type=int,
        default=None,
        help="number of tiles  [runtime cutlass.Int32]",
    )
    p.add_argument(
        "--BLOCK",
        type=int,
        default=_DEFAULT_BLOCK,
        help="threads per block  [compile-time cutlass.Constexpr]",
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
        verify(
            num_tiles=args.num_tiles,
            BLOCK=args.BLOCK,
            TILE=args.TILE,
            STAGES=args.STAGES,
        )
    else:
        verify(num_tiles=_DEFAULT_NUM_TILES, STAGES=args.STAGES)
        verify(num_tiles=_DEFAULT_NUM_TILES * 2, STAGES=args.STAGES)
