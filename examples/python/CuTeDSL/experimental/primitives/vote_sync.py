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
vote.sync — Collective warp vote using all four VoteSyncKind variants.

Demonstrates:

  - :func:`~cutlass.primitives.vote_sync` with ``prims.VoteSync.ALL``    — True iff every
    masked lane voted True
  - :func:`~cutlass.primitives.vote_sync` with ``prims.VoteSync.ANY``    — True iff at
    least one masked lane voted True
  - :func:`~cutlass.primitives.vote_sync` with ``prims.VoteSync.UNI``    — True iff all
    masked lanes cast the same vote (all-True OR all-False)
  - :func:`~cutlass.primitives.vote_sync` with ``prims.VoteSync.BALLOT`` — Int32 bitmask
    of lanes that voted True

Two kernels (each with its own canonical ``compile_*``/``run_*``/``verify_*``):

  Kernel ``pred`` (``any`` / ``all`` / ``uni``): for each row of an input
  tensor, each lane checks whether its element is positive and votes
  collectively.  Three results per row: ``any_pos``, ``all_pos``, ``uni_vote``.

  Kernel ``ballot``: for each row, each lane votes on its element being
  positive and stores the resulting bitmask for that row.

Public API (mirrors ``examples/template_kernel.py``):
  - :func:`compile_pred` / :func:`compile_ballot`     — ``@lru_cache`` AOT factory
  - :func:`run_pred`     / :func:`run_ballot`         — call compiled fn, return outputs
  - :func:`verify_pred`  / :func:`verify_ballot`      — orchestrate compile + run + assert

Runtime parameter (``rows``) varies freely without recompilation.
Compile-time parameter (``WARP_SIZE_C``) baked into the binary.

PTX reference: §9.7.13.9 ``vote.sync``.
Available on SM30+; ballot requires SM35+.

To run::

    python CuTeDSL/experimental/primitives/vote_sync.py                       # both kernels, default rows
    python CuTeDSL/experimental/primitives/vote_sync.py --rows 128
    python CuTeDSL/experimental/primitives/vote_sync.py --kernel pred
    python CuTeDSL/experimental/primitives/vote_sync.py --kernel ballot

"""

import cutlass
import argparse
from functools import lru_cache
from typing import Callable

import torch
import cuda.bindings.driver as cuda

import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims

# ---------------------------------------------------------------------------
# Shared constants
# ---------------------------------------------------------------------------

_WARP_SIZE: int = 32  # threads per warp (fixed by HW)

# ---------------------------------------------------------------------------
# Default sizes / problem
# ---------------------------------------------------------------------------

_DEFAULT_ROWS: int = 32  # default number of rows  (runtime cutlass.Int32)


# =============================================================================
# Kernel "pred" — any / all / uni votes
# =============================================================================


@cute.kernel
def kernel_pred(
    inp: cute.Tensor,  # [rows, WARP_SIZE_C] int32
    any_out: cute.Tensor,  # [rows, 1] int32  (Boolean stored as 0/1)
    all_out: cute.Tensor,
    uni_out: cute.Tensor,
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Each warp processes one row; votes on element > 0."""
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    val = inp[bidx, tidx]
    is_positive = val > 0

    any_pos = prims.vote_sync(0xFFFFFFFF, is_positive, prims.VoteSync.ANY)
    all_pos = prims.vote_sync(0xFFFFFFFF, is_positive, prims.VoteSync.ALL)
    uni_vote = prims.vote_sync(0xFFFFFFFF, is_positive, prims.VoteSync.UNI)

    if tidx == 0:
        any_out[bidx, 0] = any_pos
        all_out[bidx, 0] = all_pos
        uni_out[bidx, 0] = uni_vote


@cute.jit
def host_pred(
    inp: cute.Tensor,
    any_out: cute.Tensor,
    all_out: cute.Tensor,
    uni_out: cute.Tensor,
    stream,
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Launch one warp per row."""
    rows = inp.shape[0]
    kernel_pred(inp, any_out, all_out, uni_out, WARP_SIZE_C).launch(
        grid=(rows, 1, 1),
        block=(WARP_SIZE_C, 1, 1),
        stream=stream,
    )


@lru_cache(maxsize=None)
def compile_pred(WARP_SIZE_C: int = _WARP_SIZE) -> Callable:
    """AOT-compile :func:`host_pred`; cache by ``WARP_SIZE_C``.

    ``rows`` stays runtime via ``cute.sym_int64`` — same binary for any size.
    """
    fake_inp = make_fake_compact_tensor(
        cutlass.Int32, (cute.sym_int64(), cute.sym_int64()), stride_order=(1, 0)
    )
    fake_out = make_fake_compact_tensor(
        cutlass.Int32, (cute.sym_int64(), cute.sym_int64()), stride_order=(1, 0)
    )
    return cute.compile(
        host_pred,
        fake_inp,
        fake_out,
        fake_out,
        fake_out,
        make_fake_stream(),
        WARP_SIZE_C,
        options="--enable-tvm-ffi",
    )


def run_pred(
    compiled_fn: Callable,
    rows: int = _DEFAULT_ROWS,
) -> tuple[torch.Tensor, torch.Tensor, torch.Tensor, torch.Tensor]:
    """Allocate inputs/outputs, call compiled_fn, return ``(any, all, uni, inp)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    torch.manual_seed(42)
    inp = torch.randint(-10, 10, (rows, _WARP_SIZE), dtype=torch.int32, device="cuda")
    any_out = torch.zeros((rows, 1), dtype=torch.int32, device="cuda")
    all_out = torch.zeros((rows, 1), dtype=torch.int32, device="cuda")
    uni_out = torch.zeros((rows, 1), dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(inp, any_out, all_out, uni_out, stream)
    torch.cuda.synchronize()
    return any_out, all_out, uni_out, inp


def verify_pred(
    rows: int = _DEFAULT_ROWS,
    WARP_SIZE_C: int = _WARP_SIZE,
) -> None:
    """Compile, run, assert all three vote results match torch reference."""
    compiled_fn = compile_pred(WARP_SIZE_C=WARP_SIZE_C)
    print(f"Compile kernel (pred, WARP_SIZE_C={WARP_SIZE_C}) OK", flush=True)

    any_out, all_out, uni_out, inp = run_pred(compiled_fn, rows=rows)
    print(f"Run kernel (pred, rows={rows}) OK", flush=True)

    inp_cpu = inp.cpu()
    any_ref = (inp_cpu > 0).any(dim=1).int()
    all_ref = (inp_cpu > 0).all(dim=1).int()
    uni_ref = (any_ref == all_ref).int()
    torch.testing.assert_close(any_out.cpu().squeeze(1), any_ref, rtol=0, atol=0)
    torch.testing.assert_close(all_out.cpu().squeeze(1), all_ref, rtol=0, atol=0)
    torch.testing.assert_close(uni_out.cpu().squeeze(1), uni_ref, rtol=0, atol=0)
    print(f"verify (pred, rows={rows}, WARP_SIZE_C={WARP_SIZE_C}): PASS")


# =============================================================================
# Kernel "ballot"
# =============================================================================


@cute.kernel
def kernel_ballot(
    inp: cute.Tensor,
    ballot_out: cute.Tensor,
    WARP_SIZE_C: cutlass.Constexpr,
):
    """Each warp produces a ballot bitmask for its row."""
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    val = inp[bidx, tidx]
    is_positive = val > 0

    mask = prims.vote_sync(0xFFFFFFFF, is_positive, prims.VoteSync.BALLOT)

    if tidx == 0:
        ballot_out[bidx, 0] = mask


@cute.jit
def host_ballot(
    inp: cute.Tensor,
    ballot_out: cute.Tensor,
    stream,
    WARP_SIZE_C: cutlass.Constexpr,
):
    rows = inp.shape[0]
    kernel_ballot(inp, ballot_out, WARP_SIZE_C).launch(
        grid=(rows, 1, 1),
        block=(WARP_SIZE_C, 1, 1),
        stream=stream,
    )


@lru_cache(maxsize=None)
def compile_ballot(WARP_SIZE_C: int = _WARP_SIZE) -> Callable:
    """AOT-compile :func:`host_ballot`; cache by ``WARP_SIZE_C``."""
    fake_inp = make_fake_compact_tensor(
        cutlass.Int32, (cute.sym_int64(), cute.sym_int64()), stride_order=(1, 0)
    )
    fake_out = make_fake_compact_tensor(
        cutlass.Int32, (cute.sym_int64(), cute.sym_int64()), stride_order=(1, 0)
    )
    return cute.compile(
        host_ballot,
        fake_inp,
        fake_out,
        make_fake_stream(),
        WARP_SIZE_C,
        options="--enable-tvm-ffi",
    )


def run_ballot(
    compiled_fn: Callable,
    rows: int = _DEFAULT_ROWS,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate inputs/outputs, call compiled_fn, return ``(ballot, inp)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    torch.manual_seed(43)
    inp = torch.randint(-10, 10, (rows, _WARP_SIZE), dtype=torch.int32, device="cuda")
    ballot_out = torch.zeros((rows, 1), dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(inp, ballot_out, stream)
    torch.cuda.synchronize()
    return ballot_out, inp


def verify_ballot(
    rows: int = _DEFAULT_ROWS,
    WARP_SIZE_C: int = _WARP_SIZE,
) -> None:
    """Compile, run, assert ballot bitmask matches torch reference."""
    compiled_fn = compile_ballot(WARP_SIZE_C=WARP_SIZE_C)
    print(f"Compile kernel (ballot, WARP_SIZE_C={WARP_SIZE_C}) OK", flush=True)

    ballot_out, inp = run_ballot(compiled_fn, rows=rows)
    print(f"Run kernel (ballot, rows={rows}) OK", flush=True)

    inp_cpu = inp.cpu()
    positive = inp_cpu > 0
    expected = torch.zeros(positive.shape[0], dtype=torch.int32)
    for i in range(_WARP_SIZE):
        expected |= positive[:, i].int() << i
    torch.testing.assert_close(ballot_out.cpu().squeeze(1), expected, rtol=0, atol=0)
    print(f"verify (ballot, rows={rows}, WARP_SIZE_C={WARP_SIZE_C}): PASS")


# =============================================================================
# Top-level verify
# =============================================================================


def verify(
    kernel: str = "all",
    rows: int = _DEFAULT_ROWS,
    WARP_SIZE_C: int = _WARP_SIZE,
) -> None:
    """Run pred / ballot / both with the given runtime + compile-time params."""
    if kernel not in ("pred", "ballot", "all"):
        raise ValueError(f"kernel must be one of pred/ballot/all, got {kernel!r}")
    if kernel in ("pred", "all"):
        verify_pred(rows=rows, WARP_SIZE_C=WARP_SIZE_C)
    if kernel in ("ballot", "all"):
        verify_ballot(rows=rows, WARP_SIZE_C=WARP_SIZE_C)


# =============================================================================
# Entry point
# =============================================================================

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="vote.sync — predicate / ballot warp vote",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--rows",
        type=int,
        default=None,
        help="number of rows  [runtime cutlass.Int32; None → sweep {32, 128}]",
    )
    p.add_argument(
        "--kernel",
        type=str,
        default="all",
        choices=["pred", "ballot", "all"],
        help="kernel to run",
    )
    p.add_argument(
        "--WARP_SIZE_C",
        type=int,
        default=_WARP_SIZE,
        help="warp size  [compile-time cutlass.Constexpr]",
    )
    args = p.parse_args()

    if args.rows is not None:
        verify(kernel=args.kernel, rows=args.rows, WARP_SIZE_C=args.WARP_SIZE_C)
    else:
        for r in (32, 128):
            verify(kernel=args.kernel, rows=r, WARP_SIZE_C=args.WARP_SIZE_C)
