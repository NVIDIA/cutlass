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
red — Global-memory reduction operations with ``cutlass.primitives.red``.

Every valid thread contributes one ``Int32`` or ``Float32`` value to global
output cells. The ``Int32`` variant reduces both sum and max cells. The
``Float32`` variant demonstrates ``red.add.f32`` for the sum cell; PTX does not
support ``red.max.f32``. The output tensors are initialized on the host before
launch because ``red`` is a non-returning memory reduction that combines with
the current destination value.

To run::

    python CuTeDSL/experimental/primitives/red.py
    python CuTeDSL/experimental/primitives/red.py --n 8192 --threads 256
    python CuTeDSL/experimental/primitives/red.py --dtype f32 --n 8192 --threads 256

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

_DEFAULT_N: int = 4096  # Input element count; must be > 0 for max reductions.
_DEFAULT_THREADS: int = 128  # block thread count; CLI restricts to supported variants.
_S32_OUT_ELEMS: int = 2  # S32 output cells: [sum, max].
_F32_OUT_ELEMS: int = 1  # F32 output cells: [sum].
_MAX_VERIFY_N: int = 10_000_000
_DTYPE_BY_NAME: dict[str, type] = {
    "s32": cutlass.Int32,
    "f32": cutlass.Float32,
}


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.kernel
def kernel(
    src: cute.Tensor,  # [n] Int32 or Float32
    out: cute.Tensor,  # S32: [sum, max]; F32: [sum]
    n: cutlass.Int64,
    THREADS: cutlass.Constexpr,
) -> None:
    """Have each valid thread contribute one value through ``cutlass.primitives.red``."""
    tidx, _, _ = cute.arch.thread_idx()
    bidx, _, _ = cute.arch.block_idx()
    idx = bidx * THREADS + tidx

    if idx < n:
        src_ptr = src.iterator.raw_ptr() + idx
        out_ptr = out.iterator.raw_ptr()
        value = src_ptr.load()

        if cutlass.const_expr(src.element_type is cutlass.Float32):
            prims.red(
                prims.ReductionOp.ADD,
                prims.ReductionType.F32,
                out_ptr,
                value,
                mem_order=prims.MemOrder.RELAXED,
                mem_scope=prims.MemScope.GPU,
            )
        else:
            prims.red(
                prims.ReductionOp.ADD,
                prims.ReductionType.S32,
                out_ptr,
                value,
                mem_order=prims.MemOrder.RELAXED,
                mem_scope=prims.MemScope.GPU,
            )
            prims.red(
                prims.ReductionOp.MAX,
                prims.ReductionType.S32,
                out_ptr + 1,
                value,
                mem_order=prims.MemOrder.RELAXED,
                mem_scope=prims.MemScope.GPU,
            )


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def host(
    src: cute.Tensor,
    out: cute.Tensor,
    stream,
    THREADS: cutlass.Constexpr,
) -> None:
    """Launch enough thread blocks for every source element to contribute."""
    n = cute.size(src)
    blocks = (n + THREADS - 1) // THREADS
    kernel(src, out, n, THREADS).launch(
        grid=(blocks, 1, 1),
        block=(THREADS, 1, 1),
        stream=stream,
    )


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(THREADS: int = _DEFAULT_THREADS, DTYPE: type = cutlass.Int32) -> Callable:
    """AOT-compile the ``cutlass.primitives.red`` example."""
    _check_dtype(DTYPE)
    fake_src = make_fake_compact_tensor(
        DTYPE,
        (cute.sym_int64(),),
        assumed_align=16,
    )
    fake_out = make_fake_compact_tensor(
        DTYPE,
        (_out_elems(DTYPE),),
        assumed_align=8,
    )
    return cute.compile(
        host,
        fake_src,
        fake_out,
        make_fake_stream(),
        THREADS,
        options="--enable-tvm-ffi",
    )


def dtype_from_name(name: str) -> type:
    """Return the CUTLASS dtype selected by a CLI/test dtype name."""
    try:
        return _DTYPE_BY_NAME[name]
    except KeyError as exc:
        choices = ", ".join(sorted(_DTYPE_BY_NAME))
        raise ValueError(
            f"unsupported dtype {name!r}; expected one of: {choices}"
        ) from exc


def _check_dtype(DTYPE: type) -> None:
    if DTYPE not in _DTYPE_BY_NAME.values():
        choices = ", ".join(sorted(_DTYPE_BY_NAME))
        raise ValueError(f"unsupported DTYPE {DTYPE!r}; expected one of: {choices}")


def _torch_dtype(DTYPE: type) -> torch.dtype:
    _check_dtype(DTYPE)
    if DTYPE is cutlass.Float32:
        return torch.float32
    return torch.int32


def _out_elems(DTYPE: type) -> int:
    _check_dtype(DTYPE)
    if DTYPE is cutlass.Float32:
        return _F32_OUT_ELEMS
    return _S32_OUT_ELEMS


def _dtype_name(DTYPE: type) -> str:
    _check_dtype(DTYPE)
    for name, dtype in _DTYPE_BY_NAME.items():
        if DTYPE is dtype:
            return name
    raise AssertionError("unreachable")


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(
    compiled_fn: Callable,
    n: int = _DEFAULT_N,
    DTYPE: type = cutlass.Int32,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, run the kernel, and return ``(out, src)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    torch_dtype = _torch_dtype(DTYPE)
    src = torch.arange(n, dtype=torch.int32, device="cuda")
    src = ((src % 23) - 11).to(torch_dtype).contiguous()
    out = torch.empty(_out_elems(DTYPE), dtype=torch_dtype, device="cuda")
    out[0] = 0
    if DTYPE is cutlass.Int32:
        out[1] = torch.iinfo(torch.int32).min

    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(src, out, stream)
    torch.cuda.synchronize()
    return out, src


def expected(src: torch.Tensor) -> torch.Tensor:
    """Build the reference result and reject sizes that could hide S32 overflow."""
    n = src.numel()
    if src.dtype == torch.int32:
        if n > _MAX_VERIFY_N:
            raise ValueError(
                f"red.py verification supports n <= {_MAX_VERIFY_N:,}; got {n:,}. "
                "The kernel accumulates into Int32 output cells, so larger reference "
                "reductions are refused to avoid silent int32 wraparound."
            )

        sum64 = src.sum(dtype=torch.int64)
        sum64_value = int(sum64.item())
        int32 = torch.iinfo(torch.int32)
        if sum64_value < int32.min or sum64_value > int32.max:
            raise OverflowError(
                "red.py reference sum does not fit in int32; refusing to cast "
                f"{sum64_value} before torch.testing.assert_close."
            )

        sum32 = torch.tensor(sum64_value, dtype=torch.int32, device=src.device)
        return torch.stack((sum32, src.max()))

    if src.dtype == torch.float32:
        return torch.stack((src.sum(dtype=torch.float32),))

    raise ValueError(f"unsupported source dtype for red.py verification: {src.dtype}")


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(
    compiled_fn: Callable | None = None,
    n: int = _DEFAULT_N,
    THREADS: int = _DEFAULT_THREADS,
    DTYPE: type = cutlass.Int32,
) -> None:
    """Run a compiled kernel and compare memory reductions with torch."""
    dtype_name = _dtype_name(DTYPE)
    if compiled_fn is None:
        compiled_fn = compile(THREADS=THREADS, DTYPE=DTYPE)
        print(f"Compile kernel (THREADS={THREADS}, DTYPE={dtype_name}) OK", flush=True)

    out, src = run(compiled_fn, n=n, DTYPE=DTYPE)
    print(f"Run kernel (n={n}, DTYPE={dtype_name}) OK", flush=True)

    expected_out = expected(src)
    if tuple(out.shape) != tuple(expected_out.shape):
        raise AssertionError(
            f"expected output shape {expected_out.shape}, got {out.shape}"
        )
    torch.testing.assert_close(out, expected_out, rtol=0, atol=0)
    print(f"verify (n={n}, THREADS={THREADS}, DTYPE={dtype_name}): PASS")


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> None:
    """CLI entry point."""
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--n",
        type=int,
        default=_DEFAULT_N,
        help=(
            "Number of inputs to reduce. Verification refuses values "
            f"above {_MAX_VERIFY_N:,} for --dtype s32 to avoid silent int32 "
            "reference overflow."
        ),
    )
    parser.add_argument(
        "--dtype",
        choices=tuple(_DTYPE_BY_NAME),
        default="s32",
        help="Compile-time source/output dtype variant.",
    )
    parser.add_argument(
        "--threads",
        type=int,
        default=_DEFAULT_THREADS,
        choices=(64, 128, 256),
    )
    args = parser.parse_args()
    verify(n=args.n, THREADS=args.threads, DTYPE=dtype_from_name(args.dtype))


if __name__ == "__main__":
    main()
