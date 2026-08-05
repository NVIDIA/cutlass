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
elect.sync — elect one lane from a warp-convergent member mask.

Demonstrates :func:`~cutlass.primitives.elect_sync` in the two forms users normally need:

  1. Default ``FULL_MASK`` election — all 32 lanes execute the instruction and
     exactly one lane receives ``True`` from the wrapper.
  2. Explicit member-mask election — only the lanes named in ``membermask`` may
     execute the instruction.  This example uses the lower half-warp mask and
     branches non-participating lanes around the call.

PTX ``elect.sync`` has both a lane-id destination and a predicate destination.
The CUTLASS wrapper exposes the predicate as a Boolean.  PTX guarantees that the
same member mask deterministically elects the same leader, but it does not
specify that the elected lane is lane 0.

Use the elected predicate to gate non-idempotent single-issuer work such as
``mbarrier_arrive_expect_tx``, ``cp_async_bulk_tensor_shared_cta_global``, and
``tcgen05_commit``.  Do not use it around warp-collective ``.sync.aligned`` ops
that require all lanes to participate.

One thread block per row, one warp per thread block.

Public API (mirrors :mod:`~examples.template_kernel`):
  - :func:`compile`  — ``@lru_cache`` AOT factory
  - :func:`run`      — allocate tensors, call compiled fn, return outputs
  - :func:`verify`   — compile + run + assert vs reference

Runtime parameter (``rows``) varies freely without recompilation.
Compile-time parameter (``WARP_SIZE_C``) baked into the binary.

PTX reference: §9.7.14.15 ``elect.sync``.
Available on SM90+ (Hopper).

To run::

    python CuTeDSL/experimental/primitives/elect_sync.py                # default rows
    python CuTeDSL/experimental/primitives/elect_sync.py --rows 128

"""

import argparse
from functools import lru_cache
from typing import Callable

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims

# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------

_WARP_SIZE: int = 32  # threads per warp (fixed by HW)
_HALF_WARP: int = _WARP_SIZE // 2
_LOWER_HALF_MASK: int = (1 << _HALF_WARP) - 1

_DEFAULT_ROWS: int = 32  # default number of rows  (runtime cutlass.Int32)


# =============================================================================
# Kernel
# =============================================================================


@cute.kernel
def kernel_elect_sync(
    full_elected_per_lane: cute.Tensor,  # [rows, WARP_SIZE_C] int32 — full-mask predicate
    masked_elected_per_lane: cute.Tensor,  # [rows, WARP_SIZE_C] int32 — half-mask predicate
    full_marker: cute.Tensor,  # [rows] int32 — set by full-mask elected lane only
    masked_marker: cute.Tensor,  # [rows] int32 — set by lower-half elected lane only
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Each warp processes one row.

    First all 32 lanes participate in a default-mask election.  Then only the
    lower half warp participates in an explicit-mask election, while lanes
    outside that mask skip the instruction as PTX requires.
    """
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    full_elected = prims.elect_sync()  # default membermask = FULL_MASK
    full_elected_per_lane[bidx, tidx] = (
        cutlass.Int32(1) if full_elected else cutlass.Int32(0)
    )

    if full_elected:
        full_marker[bidx] = cutlass.Int32(bidx)

    if tidx < _HALF_WARP:
        masked_elected = prims.elect_sync(membermask=_LOWER_HALF_MASK)
        masked_elected_per_lane[bidx, tidx] = (
            cutlass.Int32(1) if masked_elected else cutlass.Int32(0)
        )
        if masked_elected:
            masked_marker[bidx] = cutlass.Int32(bidx)


@cute.jit
def host(
    full_elected_per_lane: cute.Tensor,
    masked_elected_per_lane: cute.Tensor,
    full_marker: cute.Tensor,
    masked_marker: cute.Tensor,
    stream,
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Launch one warp per row."""
    rows = full_elected_per_lane.shape[0]
    kernel_elect_sync(
        full_elected_per_lane,
        masked_elected_per_lane,
        full_marker,
        masked_marker,
        WARP_SIZE_C,
    ).launch(
        grid=(rows, 1, 1),
        block=(WARP_SIZE_C, 1, 1),
        stream=stream,
    )


# =============================================================================
# compile / run / verify
# =============================================================================


@lru_cache(maxsize=None)
def compile(WARP_SIZE_C: int = _WARP_SIZE) -> Callable:
    """AOT-compile :func:`host`; cache by ``WARP_SIZE_C``.

    ``rows`` stays runtime via ``cute.sym_int64`` — one binary for any size.

    :raises ValueError: if ``WARP_SIZE_C != 32``.  ``elect.sync`` operates on
        the hardware-defined 32-lane warp, and :func:`run` / :func:`verify`
        allocate tensors of width ``_WARP_SIZE`` (32); any other value would
        either run out of bounds or mis-verify.
    """
    if WARP_SIZE_C != _WARP_SIZE:
        raise ValueError(
            f"WARP_SIZE_C must be {_WARP_SIZE} for this example; got {WARP_SIZE_C}"
        )
    # Share rows between the two fake tensors and pin the lane dim to
    # WARP_SIZE_C so the compiled signature matches host()'s grid.
    rows_sym = cute.sym_int64()
    fake_full_elected = make_fake_compact_tensor(
        cutlass.Int32, (rows_sym, WARP_SIZE_C), stride_order=(1, 0)
    )
    fake_masked_elected = make_fake_compact_tensor(
        cutlass.Int32, (rows_sym, WARP_SIZE_C), stride_order=(1, 0)
    )
    fake_full_marker = make_fake_compact_tensor(
        cutlass.Int32, (rows_sym,), stride_order=(0,)
    )
    fake_masked_marker = make_fake_compact_tensor(
        cutlass.Int32, (rows_sym,), stride_order=(0,)
    )
    return cute.compile(
        host,
        fake_full_elected,
        fake_masked_elected,
        fake_full_marker,
        fake_masked_marker,
        make_fake_stream(),
        WARP_SIZE_C,
        options="--enable-tvm-ffi",
    )


def run(
    compiled_fn: Callable,
    rows: int = _DEFAULT_ROWS,
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor, torch.Tensor]:
    """Allocate outputs, call compiled_fn, and return the election tensors.

    :raises ValueError: if ``rows <= 0`` (used as a tensor extent and grid.x).
    :raises RuntimeError: if CUDA is unavailable.
    """
    if rows <= 0:
        raise ValueError(f"rows must be > 0; got {rows}")
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    full_elected = torch.zeros((rows, _WARP_SIZE), dtype=torch.int32, device="cuda")
    masked_elected = torch.full(
        (rows, _WARP_SIZE), -1, dtype=torch.int32, device="cuda"
    )
    full_marker = torch.full((rows,), -1, dtype=torch.int32, device="cuda")
    masked_marker = torch.full((rows,), -1, dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(full_elected, masked_elected, full_marker, masked_marker, stream)
    torch.cuda.synchronize()
    return full_elected, masked_elected, full_marker, masked_marker


def verify(
    rows: int = _DEFAULT_ROWS,
    WARP_SIZE_C: int = _WARP_SIZE,
) -> None:
    """Compile, run, assert election semantics hold:

    - Exactly one lane is elected for the full-warp member mask.
    - Exactly one lane is elected for the lower-half member mask.
    - Non-participating lanes skip the masked ``elect_sync`` call.
    - The elected lane in each case writes ``bidx`` into its marker.

    :raises ValueError: if ``rows <= 0`` or ``WARP_SIZE_C != 32``.
    :raises RuntimeError: if CUDA is unavailable.
    """
    compiled_fn = compile(WARP_SIZE_C=WARP_SIZE_C)
    print(f"Compile kernel (WARP_SIZE_C={WARP_SIZE_C}) OK", flush=True)

    full_elected, masked_elected, full_marker, masked_marker = run(
        compiled_fn, rows=rows
    )
    print(f"Run kernel (rows={rows}) OK", flush=True)

    full_elected_cpu = full_elected.cpu()
    masked_elected_cpu = masked_elected.cpu()
    full_marker_cpu = full_marker.cpu()
    masked_marker_cpu = masked_marker.cpu()

    # Exactly one elected lane per row.  PTX guarantees deterministic election,
    # but the ISA does not specify which lane ID wins.
    torch.testing.assert_close(
        full_elected_cpu.sum(dim=1),
        torch.ones(rows, dtype=torch.int64),
        rtol=0,
        atol=0,
    )
    torch.testing.assert_close(
        full_marker_cpu,
        torch.arange(rows, dtype=torch.int32),
        rtol=0,
        atol=0,
    )

    torch.testing.assert_close(
        masked_elected_cpu[:, :_HALF_WARP].sum(dim=1),
        torch.ones(rows, dtype=torch.int64),
        rtol=0,
        atol=0,
    )
    torch.testing.assert_close(
        masked_elected_cpu[:, _HALF_WARP:],
        torch.full((rows, _HALF_WARP), -1, dtype=torch.int32),
        rtol=0,
        atol=0,
    )
    torch.testing.assert_close(
        masked_marker_cpu,
        torch.arange(rows, dtype=torch.int32),
        rtol=0,
        atol=0,
    )
    print(f"verify (rows={rows}, WARP_SIZE_C={WARP_SIZE_C}): PASS")


# =============================================================================
# Entry point
# =============================================================================

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="elect.sync — one elected lane per warp",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--rows",
        type=int,
        default=None,
        help="number of rows  [runtime cutlass.Int32; None → sweep {32, 128}]",
    )
    p.add_argument(
        "--WARP_SIZE_C",
        type=int,
        default=_WARP_SIZE,
        help="warp size  [compile-time cutlass.Constexpr]",
    )
    args = p.parse_args()

    if args.rows is not None:
        verify(rows=args.rows, WARP_SIZE_C=args.WARP_SIZE_C)
    else:
        for r in (32, 128):
            verify(rows=r, WARP_SIZE_C=args.WARP_SIZE_C)
