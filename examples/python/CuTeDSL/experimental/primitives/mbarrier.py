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
mbarrier — Basic init / arrive / wait demonstration.

Demonstrates:

  - :func:`~cutlass.primitives.mbarrier_init` — set expected arrival count
  - :func:`~cutlass.primitives.fence_mbarrier_init` — make init visible to all threads
  - :func:`~cutlass.primitives.mbarrier_arrive` — software arrive (signal data is ready)
  - :func:`~cutlass.primitives.mbarrier_try_wait_parity_timelimit` — while-loop wait
  - Phase / parity semantics: a fresh barrier starts at parity 0

Pattern: one elected producer thread writes data to shared memory and
signals the barrier.  All consumer threads spin on the barrier, then
read the data.

Requires SM90+ (Hopper) for mbarrier hardware.

Public API (mirrors ``examples/template_kernel.py``):
  - :func:`compile` — AOT factory keyed on ``N_LANES``.
  - :func:`run`     — allocate dst tensor, call compiled fn, return ``(dst,)``.
  - :func:`verify`  — compile + run + assert vs reference.

To run::

    python CuTeDSL/experimental/primitives/mbarrier.py
    python CuTeDSL/experimental/primitives/mbarrier.py --N_LANES 16

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

_DEFAULT_N_LANES: int = (
    32  # default lanes participating (compile-time cutlass.Constexpr)
)


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    dst: cute.Tensor,  # [N_LANES] Float32 — output
    N_LANES: cutlass.Constexpr,  # threads per block / output length (compile-time)
):
    """Write data via one thread, barrier-sync, then all threads read."""

    tidx, _, _ = cute.arch.thread_idx()

    # ------------------------------------------------------------------
    # Step 1 — Allocate shared memory: data buffer + mbarrier.
    #
    # mbarrier is a 64-bit shared-memory object (cutlass.Int64).
    # We allocate a small shared buffer that the producer will fill.
    # ------------------------------------------------------------------
    smem_data = cutlass.Array(cutlass.Float32, N_LANES, space=cutlass.AddressSpace.smem)
    mbar = cutlass.Array(cutlass.Int64, 1, space=cutlass.AddressSpace.smem)

    # ------------------------------------------------------------------
    # Step 2 — Initialize the mbarrier (one elected thread per warp).
    #
    # mbarrier_init(bar, count) sets the expected arrival count.
    # count=1 means: one software arrive completes the barrier.
    # fence_mbarrier_init makes the init visible to all threads.
    # ------------------------------------------------------------------
    if prims.elect_sync():
        prims.fence_mbarrier_init()
        prims.mbarrier_init(mbar, 1)
    prims.barrier_cta_sync(0)  # __syncthreads — all threads see the initialized barrier

    # ------------------------------------------------------------------
    # Step 3 — Producer: thread 0 writes data, then arrives on barrier.
    #
    # Only one thread produces data.  The arrive signals that the shared
    # memory write is complete and visible (release semantics).
    # ------------------------------------------------------------------
    if tidx == 0:
        # Fill shared memory with lane indices (0..N_LANES-1) as floats
        for i in cutlass.range_constexpr(N_LANES):
            smem_data[i] = cutlass.Float32(i)

        # Software arrive — decrements the arrival count by 1
        prims.mbarrier_arrive(mbar)

    # ------------------------------------------------------------------
    # Step 4 — All threads wait on the barrier.
    #
    # mbarrier_try_wait_parity(bar, parity, time_limit=ns):
    #   Returns True when the barrier completes (the phase bit flips
    #   away from `parity`).  A fresh barrier starts at parity 0, so
    #   waiting with parity=0 blocks until the first arrive completes.
    #
    # Always wrap in a while loop — the instruction may time out.
    # ------------------------------------------------------------------
    while not prims.mbarrier_try_wait_parity(mbar, 0, time_limit=10_000_000):
        pass

    # ------------------------------------------------------------------
    # Step 5 — All threads read the shared data and write to global.
    #
    # After the wait returns, the shared memory writes from Step 3 are
    # guaranteed visible (acquire semantics from the barrier).
    # ------------------------------------------------------------------
    if tidx < N_LANES:
        dst[tidx] = smem_data[tidx]


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    dst: cute.Tensor,
    N_LANES: cutlass.Constexpr,
):
    """Launch the mbarrier kernel with one thread block of N_LANES threads."""
    kernel(dst, N_LANES).launch(grid=(1, 1, 1), block=(N_LANES, 1, 1))


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(N_LANES: int = _DEFAULT_N_LANES) -> Callable:  # noqa: A001
    """AOT-compile :func:`host`; cache by ``N_LANES``."""
    fake_dst = make_fake_compact_tensor(cutlass.Float32, (N_LANES,))
    return cute.compile(host, fake_dst, N_LANES, options="--enable-tvm-ffi")


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(
    compiled_fn: Callable,
    N_LANES: int = _DEFAULT_N_LANES,
) -> tuple[torch.Tensor]:
    """Allocate dst, call compiled_fn, return ``(dst,)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    dst = torch.zeros(N_LANES, dtype=torch.float32, device="cuda")
    compiled_fn(dst)
    torch.cuda.synchronize()
    return (dst,)


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(N_LANES: int = _DEFAULT_N_LANES) -> None:
    """Compile, run, and assert dst[i] == i for i in [0, N_LANES)."""
    compiled_fn = compile(N_LANES=N_LANES)
    print(f"Compile kernel (N_LANES={N_LANES}) OK", flush=True)

    (dst,) = run(compiled_fn, N_LANES=N_LANES)
    print(f"Run kernel (N_LANES={N_LANES}) OK", flush=True)

    expected = torch.arange(N_LANES, dtype=torch.float32, device="cuda")
    torch.testing.assert_close(dst, expected)
    print(
        f"verify (N_LANES={N_LANES}): PASS  dst[:8] = {dst[: min(8, N_LANES)].tolist()}"
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="mbarrier basic init/arrive/wait demo",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--N_LANES",
        type=int,
        default=None,
        help="lanes participating  [compile-time cutlass.Constexpr; None → sweep {16, 32}]",
    )
    args = p.parse_args()

    if args.N_LANES is not None:
        verify(N_LANES=args.N_LANES)
    else:
        for n in (16, 32):
            verify(N_LANES=n)
