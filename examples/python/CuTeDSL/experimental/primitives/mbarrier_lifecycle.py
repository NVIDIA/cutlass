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
mbarrier lifecycle smoke test using the public primitives namespace.

This example keeps the protocol intentionally small: one CTA initializes a
shared-memory mbarrier, one thread arrives, then the same thread checks the
completed phase through the state-token wait forms and invalidates the barrier.

It complements ``mbarrier.py`` and ``async_pipeline.py`` by covering the direct
``cutlass.experimental.primitives`` import path for:

  - ``mbarrier_init`` / ``fence_mbarrier_init``
  - ``mbarrier_arrive``
  - ``mbarrier_try_wait_timelimit``
  - ``mbarrier_inval``

Requires SM90+.

To run::

    python CuTeDSL/experimental/primitives/mbarrier_lifecycle.py

"""

from functools import lru_cache
from typing import Callable

import torch

import cutlass
import cutlass.cute as cute
import cutlass.experimental.primitives as prims
from cutlass.cute.runtime import make_fake_compact_tensor


# ---------------------------------------------------------------------------
# Kernel Configurations
# ---------------------------------------------------------------------------

_N_RESULTS: int = 1


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(dst: cute.Tensor) -> None:
    """Exercise one SM90+ shared-memory mbarrier lifecycle.

    ``dst`` is a compact CUDA Int32 tensor with shape ``(_N_RESULTS,)``.  The
    CTA initializes a shared mbarrier, arrives once, waits on the returned state
    token with a time limit, writes ``1`` when the wait completes and ``0``
    otherwise, then invalidates the barrier before returning.
    """
    mbar = cutlass.Array(
        cutlass.Int64,
        1,
        space=cutlass.AddressSpace.smem,
        alignment=8,
    )

    prims.mbarrier_init(mbar, 1)
    prims.fence_mbarrier_init()
    prims.barrier_cta_sync(0)

    state = prims.mbarrier_arrive(mbar)
    timelimit_done = prims.mbarrier_try_wait_timelimit(mbar, state, 10_000_000)

    dst[0] = cutlass.Int32(0)
    if timelimit_done:
        dst[0] = cutlass.Int32(1)

    prims.mbarrier_inval(mbar)


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(dst: cute.Tensor) -> None:
    """Launch ``kernel`` as one CTA with one thread."""
    kernel(dst).launch(grid=(1, 1, 1), block=(1, 1, 1))


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile() -> Callable:  # noqa: A001
    """Compile and cache the host wrapper for a compact Int32 result tensor.

    The fake tensor models shape ``(_N_RESULTS,)``.  Compilation uses
    ``--enable-tvm-ffi`` and targets the SM90+ mbarrier primitive path.
    """
    fake_dst = make_fake_compact_tensor(cutlass.Int32, (_N_RESULTS,))
    return cute.compile(host, fake_dst, options="--enable-tvm-ffi")


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(compiled_fn: Callable) -> tuple[torch.Tensor]:
    """Run the compiled function on CUDA and return ``(dst,)``.

    Raises:
        RuntimeError: If CUDA is unavailable.
    """
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    dst = torch.zeros(_N_RESULTS, dtype=torch.int32, device="cuda")
    compiled_fn(dst)
    torch.cuda.synchronize()
    return (dst,)


def _require_sm90_device() -> None:
    """Raise a clear error before compilation on devices below SM90."""
    if not torch.cuda.is_available():
        raise RuntimeError("mbarrier_lifecycle requires an SM90+ CUDA GPU")

    major, minor = torch.cuda.get_device_capability()
    if major < 9:
        raise RuntimeError(
            "mbarrier_lifecycle requires an SM90+ CUDA GPU, "
            f"got compute capability {major}.{minor}"
        )


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify() -> None:
    """Compile, run, and assert that the mbarrier wait completed.

    The SM90+ guard runs before compilation to avoid opaque backend failures.
    Verification expects ``dst`` to be all ones; ``torch.testing.assert_close``
    raises on mismatch.
    """
    _require_sm90_device()

    compiled_fn = compile()
    print("Compile mbarrier_lifecycle OK", flush=True)

    (dst,) = run(compiled_fn)
    print("Run mbarrier_lifecycle OK", flush=True)

    expected = torch.ones(_N_RESULTS, dtype=torch.int32, device="cuda")
    torch.testing.assert_close(dst, expected)
    print(f"verify: PASS  dst = {dst.tolist()}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    verify()
