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
Tensor Memory (TMEM) store and load using cutlass.primitives.tcgen05_st / cutlass.primitives.tcgen05_ld.

Demonstrates:

  - :func:`~cutlass.primitives.tcgen05_alloc` — TMEM allocation (warp-collective)
  - ``cutlass.inttoptr`` — typed TMEM pointer (address space 6 = TMEM)
  - :func:`~cutlass.primitives.tcgen05_st` — vector store to TMEM (auto-bitcasts non-Int32 to Int32)
  - :func:`~cutlass.primitives.tcgen05_ld` — vector load from TMEM (auto-bitcasts i32 to tmem_ptr.dtype)
  - :func:`~cutlass.primitives.elect_sync` — elected-thread print
  - :func:`~cutlass.primitives.tcgen05_relinquish_alloc_permit` — permit release after TMEM use

Requires a Blackwell GPU (sm_100a).

TMEM layout (SHAPE_32X32B):
  32 rows × 32 bits per row.  Each warp instruction covers all 32 rows
  simultaneously, one row per thread.  With ``num=N_REPS`` repetitions, each
  thread reads/writes ``N_REPS`` float32 values, using ``N_REPS`` TMEM columns
  in total.  The minimum column allocation is 32 (hardware requirement).

Public API (mirrors ``examples/template_kernel.py``):
  - :func:`compile` — AOT factory keyed on ``N_REPS``.
  - :func:`run`     — allocate out, call compiled fn, return ``(out,)``.
  - :func:`verify`  — compile + run + assert vs reference.

To run::

    python CuTeDSL/experimental/primitives/tcgen05/tmem_ld_st.py
    python CuTeDSL/experimental/primitives/tcgen05/tmem_ld_st.py --N_REPS 32

"""

import argparse
from functools import lru_cache
from typing import Callable

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
import cuda.bindings.driver as cuda
from cutlass.experimental import primitives as prims


# ---------------------------------------------------------------------------
# Kernel Configurations — fixed
# ---------------------------------------------------------------------------

_WARP_SIZE: int = 32  # one warp (fixed)
_N_COLS_MIN: int = 32  # TMEM column allocation must be a multiple of 32 (HW limit)


# ---------------------------------------------------------------------------
# Kernel Configurations — tunable
# ---------------------------------------------------------------------------

_DEFAULT_N_REPS: int = 32  # repetitions of SHAPE_32X32B (compile-time)


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    out: cutlass.Array,
    N_REPS: cutlass.Constexpr,
):
    """Store ``N_REPS`` float32 values to TMEM then read back and verify."""
    tidx, _, _ = cute.arch.thread_idx()

    # ------------------------------------------------------------------
    # Step 1 — Allocate TMEM.
    # ------------------------------------------------------------------
    tmem_addr_smem = cutlass.Array(cutlass.Int32, 1, space=cutlass.AddressSpace.smem)
    prims.tcgen05_alloc(tmem_addr_smem, N_REPS)
    prims.barrier_cta_sync(0)  # sync before reading the written address

    # ------------------------------------------------------------------
    # Step 2 — Build a typed TMEM pointer via inttoptr.
    # ------------------------------------------------------------------
    tmem_addr = tmem_addr_smem.load()
    tmem_ptr = cutlass.inttoptr(tmem_addr, 6, cutlass.Float32)

    # ------------------------------------------------------------------
    # Step 3 — Store N_REPS float32 values to TMEM.
    # ------------------------------------------------------------------
    data_f32 = cutlass.full([N_REPS], 1.0, dtype=cutlass.Float32)
    prims.tcgen05_st("32x32b", tmem_ptr, data_f32)
    prims.tcgen05_wait(prims.Tcgen05Wait.STORE)

    # ------------------------------------------------------------------
    # Step 4 — Load the values back from TMEM.
    # ------------------------------------------------------------------
    result = prims.tcgen05_ld("32x32b", tmem_ptr, num=N_REPS)
    prims.tcgen05_wait(prims.Tcgen05Wait.LOAD)
    # result: Vector[Float32] with N_REPS elements per thread

    # ------------------------------------------------------------------
    # Step 5 — Print from one elected thread per warp + write element 0
    # to global for host-side verification.
    # ------------------------------------------------------------------
    if prims.elect_sync():
        cutlass.print_nd_vector(result)

    out[tidx] = result[0]

    # ------------------------------------------------------------------
    # Step 6 — Deallocate TMEM, then relinquish the allocation permit.
    # ------------------------------------------------------------------
    prims.tcgen05_fence(prims.Tcgen05Fence.BEFORE_THREAD_SYNC)
    prims.barrier_cta_sync(0)
    prims.tcgen05_dealloc(tmem_ptr, N_REPS)
    prims.tcgen05_relinquish_alloc_permit()


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(out: cutlass.Array, stream, N_REPS: cutlass.Constexpr):
    # One CTA, one warp (32 threads).  tcgen05 ops are warp-collective so
    # we need at least 32 threads.
    kernel(out, N_REPS).launch(grid=(1, 1, 1), block=(_WARP_SIZE, 1, 1), stream=stream)


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(N_REPS: int = _DEFAULT_N_REPS) -> Callable:  # noqa: A001
    """AOT-compile :func:`host`; cache by ``N_REPS``.

    ``N_REPS`` is the SHAPE_32X32B repetition count — must be a multiple of
    32 (TMEM column allocation granularity).
    """
    if N_REPS % _N_COLS_MIN != 0:
        raise ValueError(f"N_REPS must be a multiple of {_N_COLS_MIN} (got {N_REPS})")
    fake_out = make_fake_compact_tensor(cutlass.Float32, (_WARP_SIZE,))
    return cute.compile(
        host, fake_out, make_fake_stream(), N_REPS, options="--enable-tvm-ffi"
    )


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(compiled_fn: Callable) -> tuple[torch.Tensor]:
    """Allocate out, call compiled_fn, return ``(out,)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    out = torch.zeros(_WARP_SIZE, dtype=torch.float32, device="cuda")
    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(out, stream)
    torch.cuda.synchronize()
    return (out,)


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(N_REPS: int = _DEFAULT_N_REPS) -> None:
    """Compile, run, and assert all 32 lanes read back 1.0."""
    compiled_fn = compile(N_REPS=N_REPS)
    print(f"Compile kernel (N_REPS={N_REPS}) OK", flush=True)

    (out,) = run(compiled_fn)
    print(f"Run kernel (N_REPS={N_REPS}) OK", flush=True)

    expected = torch.ones(_WARP_SIZE, dtype=torch.float32, device="cuda")
    torch.testing.assert_close(out, expected, atol=0, rtol=0)
    print(f"verify (N_REPS={N_REPS}): PASS  out[:4] = {out[:4].tolist()}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="tcgen05 TMEM store→load round-trip (SM100+)",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--N_REPS",
        type=int,
        default=None,
        help="SHAPE_32X32B repetitions (multiple of 32)  [compile-time cutlass.Constexpr]",
    )
    args = p.parse_args()

    if args.N_REPS is not None:
        verify(N_REPS=args.N_REPS)
    else:
        verify(N_REPS=_DEFAULT_N_REPS)
