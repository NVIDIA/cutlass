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
cp.async copy into a manually swizzled shared-memory layout.

This is the non-TMA path for:

    global memory -> shared memory -> load_swizzled -> registers -> global memory

Every participating thread computes the shared-memory address it owns, applies
the same XOR swizzle that the later reader expects, and passes
``swizzled_smem_ptr`` to ``cutlass.primitives.cp_async_shared_global``.  The matching
``load_swizzled`` read recovers the vector into registers before the final
global-memory store.

Use this pattern when a kernel needs per-thread ``cp.async`` copies instead
of descriptor-based TMA, but the shared-memory tile must still be laid out with
``s128b`` for a swizzled consumer such as ``tcgen05.mma`` or vector
shared-memory reads.
With the constants in this example, ``BLOCK`` must be a multiple of 8 so each
thread-block tile contains whole 128-byte shared-memory rows.

To run::

    python CuTeDSL/experimental/primitives/cp_async_shared_global_swizzled.py
    python CuTeDSL/experimental/primitives/cp_async_shared_global_swizzled.py --BLOCK 64 --n 4096

"""

from __future__ import annotations

import argparse
from functools import lru_cache
from typing import Callable

import torch

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.experimental import primitives as prims


# ---------------------------------------------------------------------------
# Kernel Configurations
# ---------------------------------------------------------------------------

_VEC_BYTES: int = 16
_ELEMS_PER_THREAD: int = _VEC_BYTES // 4
_SMEM_ROW_BYTES: int = 128
_SMEM_ROW_ELEMS: int = _SMEM_ROW_BYTES // 4
_DEFAULT_BLOCK: int = 128
_DEFAULT_N: int = 2048
_SWIZZLE: str = "s128b"


def _validate_problem_shape(n: int, BLOCK: int) -> None:
    if BLOCK <= 0:
        raise ValueError(f"BLOCK must be positive, got {BLOCK}")
    tile = BLOCK * _ELEMS_PER_THREAD
    if tile % _SMEM_ROW_ELEMS != 0:
        raise ValueError(
            f"BLOCK * {_ELEMS_PER_THREAD} ({tile}) must be a multiple of "
            f"{_SMEM_ROW_ELEMS} float32 elements for {_SMEM_ROW_BYTES}-byte "
            f"{_SWIZZLE} rows; with this example BLOCK must be divisible by 8"
        )
    if n % tile != 0:
        raise ValueError(
            f"n ({n}) must be divisible by BLOCK * {_ELEMS_PER_THREAD} ({tile})"
        )


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    src: cute.Tensor,
    dst: cute.Tensor,
    BLOCK: cutlass.Constexpr,
    ELEMS_PER_THREAD: cutlass.Constexpr,
    SMEM_ROW_ELEMS: cutlass.Constexpr,
    SWIZZLE: cutlass.Constexpr,
):
    """Copy src -> swizzled shared memory, then load_swizzled -> dst."""

    tile = BLOCK * ELEMS_PER_THREAD
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()

    smem = cutlass.Array(
        cutlass.Float32, tile, space=cutlass.AddressSpace.smem, alignment=128
    )
    swizzle = cutlass.Swizzle.from_name(SWIZZLE)

    base = bidx * tile
    thread_offset = tidx * ELEMS_PER_THREAD
    smem_row = thread_offset // SMEM_ROW_ELEMS
    smem_col = thread_offset - smem_row * SMEM_ROW_ELEMS
    smem_ptr = smem.data_ptr() + smem_row * SMEM_ROW_ELEMS + smem_col
    # cp.async needs the physically swizzled destination address, not a
    # load/store helper.
    swizzled_smem_ptr = smem_ptr.apply_swizzle(swizzle)
    gmem_src_ptr = src.iterator.raw_ptr() + base + thread_offset

    prims.cp_async_shared_global(
        swizzled_smem_ptr,
        gmem_src_ptr,
        ELEMS_PER_THREAD * 4,
        "cg",
    )

    prims.cp_async_commit_group()
    prims.cp_async_wait_group(0)
    prims.barrier_cta_sync(0)

    vec = smem_ptr.load_swizzled(
        swizzle,
        alignment=ELEMS_PER_THREAD * 4,
        count=ELEMS_PER_THREAD,
    )
    gmem_dst_ptr = dst.iterator.raw_ptr() + base + thread_offset
    gmem_dst_ptr.store(vec, alignment=ELEMS_PER_THREAD * 4)


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    src: cute.Tensor,
    dst: cute.Tensor,
    BLOCK: cutlass.Constexpr,
    ELEMS_PER_THREAD: cutlass.Constexpr,
    SMEM_ROW_ELEMS: cutlass.Constexpr,
    SWIZZLE: cutlass.Constexpr,
):
    """Launch the swizzled cp.async kernel."""
    n = src.shape[0]
    tile = BLOCK * ELEMS_PER_THREAD
    grid = (n // tile, 1, 1)
    kernel(
        src,
        dst,
        BLOCK,
        ELEMS_PER_THREAD,
        SMEM_ROW_ELEMS,
        SWIZZLE,
    ).launch(grid=grid, block=(BLOCK, 1, 1))


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(BLOCK: int = _DEFAULT_BLOCK) -> Callable:  # noqa: A001
    """AOT-compile :func:`host`; cache by ``BLOCK``."""
    _validate_problem_shape(BLOCK * _ELEMS_PER_THREAD, BLOCK)
    sym_n = cute.sym_int64(divisibility=BLOCK * _ELEMS_PER_THREAD)
    fake_src = make_fake_compact_tensor(cutlass.Float32, (sym_n,))
    fake_dst = make_fake_compact_tensor(cutlass.Float32, (sym_n,))
    return cute.compile(
        host,
        fake_src,
        fake_dst,
        BLOCK,
        _ELEMS_PER_THREAD,
        _SMEM_ROW_ELEMS,
        _SWIZZLE,
        options="--enable-tvm-ffi",
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
    print(f"Run kernel (n={n}, BLOCK={BLOCK}, swizzle={_SWIZZLE}) OK", flush=True)

    torch.testing.assert_close(dst, src)
    print(f"verify (n={n}, BLOCK={BLOCK}): PASS  dst[:4] = {dst[:4].tolist()}")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="cp.async copy into swizzled shared memory",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--n",
        type=int,
        default=None,
        help="total elements [must be divisible by BLOCK*4]",
    )
    parser.add_argument(
        "--BLOCK",
        type=int,
        default=_DEFAULT_BLOCK,
        help="threads per block [compile-time cutlass.Constexpr; must be divisible by 8]",
    )
    args = parser.parse_args()

    if args.n is not None:
        verify(n=args.n, BLOCK=args.BLOCK)
    else:
        verify(n=_DEFAULT_N, BLOCK=args.BLOCK)
        verify(n=_DEFAULT_N * 4, BLOCK=args.BLOCK)
