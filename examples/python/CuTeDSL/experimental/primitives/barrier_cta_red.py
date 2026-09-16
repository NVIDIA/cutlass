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
barrier.cta.red — thread-block predicate reduction at a named barrier.

Demonstrates:

  - :func:`~cutlass.primitives.barrier_cta_red` with ``kind="or"``.
  - :func:`~cutlass.primitives.barrier_cta_red` with ``kind="and"``.
  - Reusing different named barrier slots for independent thread-block reductions.

To run::

    python CuTeDSL/experimental/primitives/barrier_cta_red.py
    python CuTeDSL/experimental/primitives/barrier_cta_red.py --threads 64

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
# Kernel Configurations
# ---------------------------------------------------------------------------

_DEFAULT_THREADS: int = 64
_OUT_ELEMS: int = 3


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    out_arr: cutlass.Array,  # [_OUT_ELEMS] Int32: [any_lane0, all_in_range, all_nonzero]
    THREADS: cutlass.Constexpr,
):
    """Run three thread-block predicate reductions and store the broadcast results."""
    tidx, _, _ = cute.arch.thread_idx()

    any_lane0 = prims.barrier_cta_red(
        tidx == 0,
        barrier_id=0,
        kind="or",
        thread_count=THREADS,
    )
    all_in_range = prims.barrier_cta_red(
        tidx < THREADS,
        barrier_id=1,
        kind="and",
        thread_count=THREADS,
    )
    all_nonzero = prims.barrier_cta_red(
        tidx != 0,
        barrier_id=2,
        kind="and",
        thread_count=THREADS,
    )

    if tidx == 0:
        out_arr[0] = any_lane0
        out_arr[1] = all_in_range
        out_arr[2] = all_nonzero


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    out: cutlass.Array,
    stream,
    THREADS: cutlass.Constexpr,
):
    """Launch one thread block with ``THREADS`` participating threads."""
    kernel(out, THREADS).launch(
        grid=(1, 1, 1),
        block=(THREADS, 1, 1),
        stream=stream,
    )


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(THREADS: int = _DEFAULT_THREADS) -> Callable:
    """AOT-compile the thread-block predicate-reduction example."""
    fake_out = make_fake_compact_tensor(cutlass.Int32, (_OUT_ELEMS,), assumed_align=4)
    return cute.compile(
        host,
        fake_out,
        make_fake_stream(),
        THREADS,
        options="--enable-tvm-ffi",
    )


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(
    compiled_fn: Callable,
) -> torch.Tensor:
    """Allocate output, run the compiled kernel, and return the result."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    out = torch.zeros(_OUT_ELEMS, dtype=torch.int32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(out, stream)
    torch.cuda.synchronize()
    return out


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(
    compiled_fn: Callable | None = None,
    THREADS: int = _DEFAULT_THREADS,
) -> None:
    """Run a compiled kernel and compare thread-block reductions with the expected result."""
    if compiled_fn is None:
        compiled_fn = compile(THREADS=THREADS)
        print(f"Compile kernel (THREADS={THREADS}) OK", flush=True)

    out = run(compiled_fn)
    print(f"Run kernel (THREADS={THREADS}) OK", flush=True)

    expected = torch.tensor([1, 1, 0], dtype=torch.int32, device="cuda")
    torch.testing.assert_close(out, expected, rtol=0, atol=0)
    print(f"verify (THREADS={THREADS}): PASS")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--threads",
        type=int,
        default=_DEFAULT_THREADS,
        choices=(32, 64, 128),
        help="Thread count baked into the named barrier reductions",
    )
    args = parser.parse_args()
    verify(THREADS=args.threads)


if __name__ == "__main__":
    main()
