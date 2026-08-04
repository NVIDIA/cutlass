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
Thread-local reductions from fixed-width vector loads.

Each CTA owns one row of ``src``. A single thread loads ``WIDTH`` contiguous
values as a CUTLASS vector, then applies the compile-time ``REDUCE_OP`` variant
with ``Vector.reduce`` and stores one scalar result per row. The example
specializes the same kernel shape for ``Float16``, ``BFloat16``, ``Float32``,
and ``Int32``. The input and output tensors have the same dtype for each
specialization.

All variants intentionally use the public ``Vector.reduce`` path. This example
only reduces values inside one thread's fixed-width register vector.

Thread-local reduction path:

+-------------------+-------------------+-------------------+-------------------+
| Dtype             | Add               | Min               | Max               |
+===================+===================+===================+===================+
| ``f16``/``bf16``  | ``Vector.reduce`` | ``Vector.reduce`` | ``Vector.reduce`` |
+-------------------+-------------------+-------------------+-------------------+
| ``f32``           | ``Vector.reduce`` | ``Vector.reduce`` | ``Vector.reduce`` |
+-------------------+-------------------+-------------------+-------------------+
| ``i32``           | ``Vector.reduce`` | ``Vector.reduce`` | ``Vector.reduce`` |
+-------------------+-------------------+-------------------+-------------------+

To run::

    python CuTeDSL/experimental/primitives/reduction/thread_vector_reduce.py
    python CuTeDSL/experimental/primitives/reduction/thread_vector_reduce.py \
        --rows 32 --width 8 --dtype bf16

"""

import argparse
from functools import lru_cache
from typing import Callable, Literal, TypeAlias, cast

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream

_DEFAULT_ROWS: int = 16
_DEFAULT_WIDTH: int = 8
_DEFAULT_REDUCE_OP: Literal["add", "max", "min"] = "add"
REDUCE_OPS: tuple[Literal["add", "max", "min"], ...] = ("add", "max", "min")
DTypeName: TypeAlias = Literal["f16", "bf16", "f32", "i32"]
_DEFAULT_DTYPE: DTypeName = "f32"
DTYPES: tuple[DTypeName, ...] = ("f16", "bf16", "f32", "i32")
_CUTLASS_DTYPES: dict[DTypeName, type[cutlass.Numeric]] = {
    "f16": cutlass.Float16,
    "bf16": cutlass.BFloat16,
    "f32": cutlass.Float32,
    "i32": cutlass.Int32,
}
_TORCH_DTYPES: dict[DTypeName, torch.dtype] = {
    "f16": torch.float16,
    "bf16": torch.bfloat16,
    "f32": torch.float32,
    "i32": torch.int32,
}


def _normalize_reduce_op(REDUCE_OP: str) -> Literal["add", "max", "min"]:
    if REDUCE_OP not in REDUCE_OPS:
        raise ValueError(f"REDUCE_OP must be 'add', 'max', or 'min', got {REDUCE_OP!r}")
    return cast(Literal["add", "max", "min"], REDUCE_OP)


def _normalize_dtype(DTYPE: str) -> DTypeName:
    """Return a validated dtype alias for Vector reductions."""
    if DTYPE not in DTYPES:
        raise ValueError(f"DTYPE must be one of {DTYPES}, got {DTYPE!r}")
    return cast(DTypeName, DTYPE)


@cute.kernel
def _kernel(
    src: cute.Tensor,  # [rows, WIDTH]
    out: cute.Tensor,  # [rows]
    REDUCE_OP: cutlass.Constexpr,
    WIDTH: cutlass.Constexpr,
    ELEMENT_BYTES: cutlass.Constexpr,
) -> None:
    """Reduce one contiguous row vector per CTA."""
    row, _, _ = cute.arch.block_idx()
    tx, _, _ = cute.arch.thread_idx()

    if tx == 0:
        # This example isolates the thread-local Vector API: one elected thread
        # owns the whole row vector, so no inter-thread synchronization is needed.
        src_ptr = src.iterator.raw_ptr() + row * WIDTH
        out_ptr = out.iterator.raw_ptr() + row

        # WIDTH is compile-time, so the load returns a fixed-width Vector that
        # can be folded with Vector.reduce.
        alignment = WIDTH * ELEMENT_BYTES
        values = src_ptr.load(count=WIDTH, alignment=alignment)

        out_ptr.store(values.reduce(REDUCE_OP))


@cute.jit
def _host(
    src: cute.Tensor,
    out: cute.Tensor,
    stream,
    REDUCE_OP: cutlass.Constexpr,
    WIDTH: cutlass.Constexpr,
    ELEMENT_BYTES: cutlass.Constexpr,
) -> None:
    """Launch one CTA per row."""
    rows = src.shape[0]
    _kernel(src, out, REDUCE_OP, WIDTH, ELEMENT_BYTES).launch(
        grid=(rows, 1, 1),
        block=(1, 1, 1),
        stream=stream,
    )


@lru_cache(maxsize=None)
def compile(
    WIDTH: int = _DEFAULT_WIDTH,
    REDUCE_OP: str = _DEFAULT_REDUCE_OP,
    DTYPE: str = _DEFAULT_DTYPE,
) -> Callable:
    """AOT-compile the thread-local vector reduction example."""
    REDUCE_OP = _normalize_reduce_op(REDUCE_OP)
    DTYPE = _normalize_dtype(DTYPE)
    cutlass_dtype = _CUTLASS_DTYPES[DTYPE]
    source_align = max(16, WIDTH * cutlass_dtype.bytes)
    fake_src = make_fake_compact_tensor(
        cutlass_dtype,
        (cute.sym_int64(), cute.sym_int64()),
        stride_order=(1, 0),
        assumed_align=source_align,
    )
    fake_out = make_fake_compact_tensor(
        cutlass_dtype,
        (cute.sym_int64(),),
        assumed_align=16,
    )
    return cute.compile(
        _host,
        fake_src,
        fake_out,
        make_fake_stream(),
        REDUCE_OP,
        WIDTH,
        cutlass_dtype.bytes,
        options="--enable-tvm-ffi",
    )


def run(
    compiled_fn: Callable,
    rows: int = _DEFAULT_ROWS,
    WIDTH: int = _DEFAULT_WIDTH,
    DTYPE: str = _DEFAULT_DTYPE,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, run the kernel, and return ``(out, src)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    DTYPE = _normalize_dtype(DTYPE)
    torch_dtype = _TORCH_DTYPES[DTYPE]
    src = torch.arange(rows * WIDTH, dtype=torch.float32, device="cuda").reshape(
        rows, WIDTH
    )
    src = ((src % 17.0) - 8.0).to(torch_dtype).contiguous()
    out = torch.empty(rows, dtype=torch_dtype, device="cuda")

    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(src, out, stream)
    torch.cuda.synchronize()
    return out, src


def verify(
    rows: int = _DEFAULT_ROWS,
    WIDTH: int = _DEFAULT_WIDTH,
    REDUCE_OP: str = _DEFAULT_REDUCE_OP,
    DTYPE: str = _DEFAULT_DTYPE,
) -> None:
    """Compile, run, and compare vector reductions with torch."""
    REDUCE_OP = _normalize_reduce_op(REDUCE_OP)
    DTYPE = _normalize_dtype(DTYPE)
    compiled_fn = compile(WIDTH=WIDTH, REDUCE_OP=REDUCE_OP, DTYPE=DTYPE)
    print(
        f"Compile kernel (WIDTH={WIDTH}, REDUCE_OP={REDUCE_OP}, DTYPE={DTYPE}) OK",
        flush=True,
    )

    out, src = run(compiled_fn, rows=rows, WIDTH=WIDTH, DTYPE=DTYPE)
    print(
        "Run kernel "
        f"(rows={rows}, WIDTH={WIDTH}, REDUCE_OP={REDUCE_OP}, "
        f"DTYPE={DTYPE}) OK",
        flush=True,
    )

    if REDUCE_OP == "add":
        expected = src.sum(dim=1)
    elif REDUCE_OP == "min":
        expected = src.min(dim=1).values
    else:
        expected = src.max(dim=1).values
    torch.testing.assert_close(out, expected.to(out.dtype), rtol=0, atol=0)
    print(
        "verify "
        f"(rows={rows}, WIDTH={WIDTH}, REDUCE_OP={REDUCE_OP}, "
        f"DTYPE={DTYPE}): PASS"
    )


def main() -> None:
    """Parse CLI arguments and run verification."""
    parser = argparse.ArgumentParser(
        description="Run the thread-local Vector.reduce example.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--rows",
        type=int,
        default=_DEFAULT_ROWS,
        help="Number of rows",
    )
    parser.add_argument(
        "--width",
        type=int,
        default=_DEFAULT_WIDTH,
        choices=(4, 8, 16),
        help="Compile-time vector width per CTA",
    )
    parser.add_argument(
        "--reduce-op",
        dest="REDUCE_OP",
        default=_DEFAULT_REDUCE_OP,
        choices=REDUCE_OPS,
        help="Compile-time reduction operator",
    )
    parser.add_argument(
        "--dtype",
        dest="DTYPE",
        default=_DEFAULT_DTYPE,
        choices=DTYPES,
        help="Compile-time element dtype",
    )
    args = parser.parse_args()
    verify(rows=args.rows, WIDTH=args.width, REDUCE_OP=args.REDUCE_OP, DTYPE=args.DTYPE)


if __name__ == "__main__":
    main()
