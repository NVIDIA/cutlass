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
cp.async per-thread copy: global → shared memory.

Demonstrates:

  - :func:`~cutlass.primitives.cp_async_shared_global` — per-thread async copy
    (this example uses the 16-byte ``cg`` form)
  - :func:`~cutlass.primitives.cp_async_commit_group` — commit pending copies into a numbered group
  - :func:`~cutlass.primitives.cp_async_wait_group` — wait until ≤ N groups still pending
  - ``LoadCacheModifierKind.CA`` (cache at all levels) and ``.CG`` (bypass L1)

This is the SM80+ non-bulk, non-TMA async copy path.  Each thread issues
its own 16-byte copy (4 × float32).  No tensor descriptor needed.
The PTX ``cp.async.cg`` form is restricted to 16-byte copies; use ``ca`` for
4-byte or 8-byte copies.

Contrasts with:

  - TMA ``cp.async.bulk``: descriptor-based, one thread per block, SM90+
  - Synchronous loads: ``ptr.load()`` or ``arr[i]``

Requires SM80+.

Public API (mirrors ``examples/template_kernel.py``):
  - :func:`compile` — AOT factory keyed on ``BLOCK``.
  - :func:`run`     — allocate src/dst, call compiled fn, return ``(dst, src)``.
  - :func:`verify`  — compile + run + assert vs reference.

To run::

    python CuTeDSL/experimental/primitives/cp_async_shared_global.py
    python CuTeDSL/experimental/primitives/cp_async_shared_global.py --BLOCK 64 --n 4096

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

_VEC_BYTES: int = 16  # 16 bytes = 4 × float32 per cp.async (fixed)
_ELEMS_PER_THREAD: int = _VEC_BYTES // 4  # 4 float32s per 16-byte copy

# ---------------------------------------------------------------------------
# Kernel Configurations — tunable (exposed via argparser / compile)
# ---------------------------------------------------------------------------

_DEFAULT_BLOCK: int = 128  # default threads per block (compile-time cutlass.Constexpr)

# ---------------------------------------------------------------------------
# Default problem sizes
# ---------------------------------------------------------------------------

_DEFAULT_N: int = 2048  # total float32s; must be divisible by BLOCK*_ELEMS_PER_THREAD


def _validate_problem_shape(n: int, BLOCK: int) -> None:
    if BLOCK <= 0:
        raise ValueError(f"BLOCK must be positive, got {BLOCK}")
    tile = BLOCK * _ELEMS_PER_THREAD
    if n % tile != 0:
        raise ValueError(
            f"n ({n}) must be divisible by BLOCK * {_ELEMS_PER_THREAD} ({tile})"
        )


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    src: cute.Tensor,  # [n] Float32 — input
    dst: cute.Tensor,  # [n] Float32 — output
    BLOCK: cutlass.Constexpr,  # threads per block (compile-time)
    ELEMS_PER_THREAD: cutlass.Constexpr,  # elements each thread copies (compile-time)
):
    """Copy n float32s from global src → smem → global dst using cp.async."""

    tile = BLOCK * ELEMS_PER_THREAD  # elements per thread-block tile
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    # ------------------------------------------------------------------
    # Step 1 — Allocate shared memory staging buffer.
    #
    # Each thread copies ELEMS_PER_THREAD floats, so the tile is BLOCK*ELEMS_PER_THREAD.
    # ------------------------------------------------------------------
    smem = cutlass.Array(
        cutlass.Float32, tile, space=cutlass.AddressSpace.smem, alignment=128
    )

    # ------------------------------------------------------------------
    # Step 2 — Compute source and destination pointers.
    # ------------------------------------------------------------------
    base = bidx * tile
    thread_offset = tidx * ELEMS_PER_THREAD
    gmem_src_ptr = src.iterator.raw_ptr() + base + thread_offset
    smem_dst_ptr = smem.data_ptr() + thread_offset

    # ------------------------------------------------------------------
    # Step 3 — Issue async copy: global → shared.
    #
    # cp_async_shared_global(dst_smem, src_gmem, size, modifier)
    # - this example uses 16 bytes per thread
    # - CG modifier is valid only for 16-byte copies and bypasses L1
    # ------------------------------------------------------------------
    prims.cp_async_shared_global(
        smem_dst_ptr,
        gmem_src_ptr,
        ELEMS_PER_THREAD * 4,  # bytes (Float32 = 4 B)
        "cg",
    )

    # ------------------------------------------------------------------
    # Step 4 — Commit and wait.
    #
    # cp_async_commit_group batches all pending cp.async ops into a group.
    # cp_async_wait_group(0) waits until 0 groups are still pending.
    # __syncthreads ensures all threads see the shared-memory writes.
    # ------------------------------------------------------------------
    prims.cp_async_commit_group()
    prims.cp_async_wait_group(0)
    prims.barrier_cta_sync(0)  # __syncthreads — shared memory visible to all threads

    # ------------------------------------------------------------------
    # Step 5 — Copy from shared → global output.
    # ------------------------------------------------------------------
    smem_src_ptr = smem.data_ptr() + thread_offset
    gmem_dst_ptr = dst.iterator.raw_ptr() + base + thread_offset

    v = smem_src_ptr.load(count=ELEMS_PER_THREAD)
    gmem_dst_ptr.store(v)


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    src: cute.Tensor,
    dst: cute.Tensor,
    BLOCK: cutlass.Constexpr,
    ELEMS_PER_THREAD: cutlass.Constexpr,
):
    """Launch the cp.async kernel."""
    n = src.shape[0]
    tile = BLOCK * ELEMS_PER_THREAD
    grid = (n // tile, 1, 1)
    kernel(src, dst, BLOCK, ELEMS_PER_THREAD).launch(grid=grid, block=(BLOCK, 1, 1))


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(BLOCK: int = _DEFAULT_BLOCK) -> Callable:  # noqa: A001
    """AOT-compile :func:`host`; cache by ``BLOCK``.

    Tile width = ``BLOCK * _ELEMS_PER_THREAD``.  ``n`` is kept symbolic
    so any ``n`` divisible by the tile width re-uses the same binary.
    """
    if BLOCK <= 0:
        raise ValueError(f"BLOCK must be positive, got {BLOCK}")
    sym_n = cute.sym_int64(divisibility=BLOCK * _ELEMS_PER_THREAD)
    fake_src = make_fake_compact_tensor(cutlass.Float32, (sym_n,))
    fake_dst = make_fake_compact_tensor(cutlass.Float32, (sym_n,))
    return cute.compile(
        host, fake_src, fake_dst, BLOCK, _ELEMS_PER_THREAD, options="--enable-tvm-ffi"
    )


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(
    compiled_fn: Callable,
    n: int = _DEFAULT_N,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate src/dst, call compiled_fn, return ``(dst, src)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")
    src = torch.arange(n, dtype=torch.float32, device="cuda")
    dst = torch.zeros(n, dtype=torch.float32, device="cuda")
    compiled_fn(src, dst)
    torch.cuda.synchronize()
    return dst, src


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(n: int = _DEFAULT_N, BLOCK: int = _DEFAULT_BLOCK) -> None:
    """Compile, run, and assert dst == src."""
    _validate_problem_shape(n, BLOCK)
    compiled_fn = compile(BLOCK=BLOCK)
    print(f"Compile kernel (BLOCK={BLOCK}) OK", flush=True)

    dst, src = run(compiled_fn, n=n)
    print(f"Run kernel (n={n}, BLOCK={BLOCK}) OK", flush=True)

    torch.testing.assert_close(dst, src)
    print(f"verify (n={n}, BLOCK={BLOCK}): PASS  dst[:4] = {dst[:4].tolist()}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    p = argparse.ArgumentParser(
        description="cp.async per-thread copy",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    p.add_argument(
        "--n",
        type=int,
        default=None,
        help="total elements  [must be divisible by BLOCK*4]",
    )
    p.add_argument(
        "--BLOCK",
        type=int,
        default=_DEFAULT_BLOCK,
        help="threads per block  [compile-time cutlass.Constexpr]",
    )
    args = p.parse_args()

    if args.n is not None:
        verify(n=args.n, BLOCK=args.BLOCK)
    else:
        verify(n=_DEFAULT_N, BLOCK=args.BLOCK)
        verify(n=_DEFAULT_N * 4, BLOCK=args.BLOCK)
