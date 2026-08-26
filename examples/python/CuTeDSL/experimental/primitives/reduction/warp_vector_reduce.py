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
Warp-level reductions from per-lane vector partials.

Each CTA owns one row of ``src`` with ``32 * ITEMS_PER_LANE`` values. Every lane
loads ``ITEMS_PER_LANE`` contiguous values, folds them locally with
``Vector.reduce``, then reduces those lane results across the warp. The example
specializes the same kernel shape for ``Float16``, ``BFloat16``, ``Float32``,
and ``Int32``. The input and output tensors have the same dtype for each
specialization.

Warp reduction path:

+-------------------+-------------------------+-------------------------+-------------------------+
| Dtype             | Add                     | Min                     | Max                     |
+===================+=========================+=========================+=========================+
| ``i32``           | ``prims.redux_sync``     | ``prims.redux_sync``     | ``prims.redux_sync``     |
|                   | with ``ADD``            | with ``MIN``            | with ``MAX``            |
+-------------------+-------------------------+-------------------------+-------------------------+
| ``f32``           | Shuffle tree in ``f32`` | sm_100a/103a/107a:      | sm_100a/103a/107a:      |
|                   |                         | ``redux.sync.f32``;     | ``redux.sync.f32``;     |
|                   |                         | else shuffle tree       | else shuffle tree       |
+-------------------+-------------------------+-------------------------+-------------------------+
| ``f16``/``bf16``  | Shuffle tree in input   | Shuffle tree in input   | Shuffle tree in input   |
|                   | dtype                   | dtype                   | dtype                   |
+-------------------+-------------------------+-------------------------+-------------------------+

To run::

    python CuTeDSL/experimental/primitives/reduction/warp_vector_reduce.py
    python CuTeDSL/experimental/primitives/reduction/warp_vector_reduce.py \
        --rows 32 --items-per-lane 4 --dtype bf16

"""

import argparse
from functools import lru_cache
from typing import Callable, Literal, TypeAlias, cast

import torch
import cuda.bindings.driver as cuda

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor, make_fake_stream
from cutlass.experimental import primitives as prims
from cutlass import base_dsl
from cutlass.cutlass_dsl import BaseDSL


# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

_DEFAULT_ROWS: int = 16
_DEFAULT_ITEMS_PER_LANE: int = 4
_DEFAULT_REDUCE_OP: Literal["add", "max", "min"] = "add"
_WARP_SIZE: int = 32
_FULL_MASK: int = 0xFFFFFFFF
REDUCE_OPS: tuple[Literal["add", "max", "min"], ...] = ("add", "max", "min")
DTypeName: TypeAlias = Literal["f16", "bf16", "f32", "i32"]
_DEFAULT_DTYPE: DTypeName = "i32"
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
    """Return a validated dtype alias for warp vector reductions."""
    if DTYPE not in DTYPES:
        raise ValueError(f"DTYPE must be one of {DTYPES}, got {DTYPE!r}")
    return cast(DTypeName, DTYPE)


def _redux_kind(REDUCE_OP: Literal["add", "max", "min"]) -> prims.ReductionKind:
    """Return the NVVM enum for one integer redux operation."""
    if REDUCE_OP == "add":
        return prims.ReductionKind.ADD
    if REDUCE_OP == "min":
        return prims.ReductionKind.MIN
    return prims.ReductionKind.MAX


# Fast path for the f32 redux.sync.{min,max}.f32 instruction, which ptxas accepts
# only for sm_100a/sm_103a/sm_107a. Other targets use the generic shuffle
# butterfly.
_F32_REDUX_ARCHS = (
    base_dsl.Arch.sm_100a,
    base_dsl.Arch.sm_103a,
    base_dsl.Arch.sm_107a,
)


def _f32_redux_available() -> bool:
    """Return True at compile time when the target supports redux.sync.f32."""
    return BaseDSL._get_dsl().get_arch_enum() in _F32_REDUX_ARCHS


def _use_f32_redux(DTYPE, REDUCE_OP) -> bool:
    # f32 min/max only: no f32 redux-add, no f16/bf16 redux at all.
    return DTYPE == "f32" and REDUCE_OP in ("min", "max") and _f32_redux_available()


def _f32_redux_kind(REDUCE_OP):
    # NOTE: default (no .NaN) ignores NaN lanes, matching cutlass.max/min for
    # NaN-free inputs. Use nan=True on prims.redux_sync if propagation is needed.
    return prims.ReductionKind.FMIN if REDUCE_OP == "min" else prims.ReductionKind.FMAX


# ---------------------------------------------------------------------------
# Device kernel
# ---------------------------------------------------------------------------


@cute.jit
def _cast_to_dtype(
    value,
    DTYPE: cutlass.Constexpr,
):
    """Cast a scalar value back to the compile-time reduction dtype."""
    if cutlass.const_expr(DTYPE == "f16"):
        return cutlass.Float16(value)
    if cutlass.const_expr(DTYPE == "bf16"):
        return cutlass.BFloat16(value)
    if cutlass.const_expr(DTYPE == "i32"):
        return cutlass.Int32(value)
    return cutlass.Float32(value)


@cute.jit
def _combine_value(
    lhs,
    rhs,
    REDUCE_OP: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
):
    """Combine two same-dtype values with the selected reduction operation."""
    if cutlass.const_expr(REDUCE_OP == "add"):
        return _cast_to_dtype(lhs + rhs, DTYPE)
    if cutlass.const_expr(REDUCE_OP == "min"):
        return cutlass.min(lhs, rhs)
    return cutlass.max(lhs, rhs)


@cute.jit
def _warp_reduce_tree(
    value,
    REDUCE_OP: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
):
    """Reduce one same-dtype value per lane with a fixed butterfly tree."""
    other = cute.arch.shuffle_sync_bfly(value, 16)
    value = _combine_value(value, other, REDUCE_OP, DTYPE)
    other = cute.arch.shuffle_sync_bfly(value, 8)
    value = _combine_value(value, other, REDUCE_OP, DTYPE)
    other = cute.arch.shuffle_sync_bfly(value, 4)
    value = _combine_value(value, other, REDUCE_OP, DTYPE)
    other = cute.arch.shuffle_sync_bfly(value, 2)
    value = _combine_value(value, other, REDUCE_OP, DTYPE)
    other = cute.arch.shuffle_sync_bfly(value, 1)
    return _combine_value(value, other, REDUCE_OP, DTYPE)


@cute.kernel
def _kernel(
    src: cute.Tensor,  # [rows, _WARP_SIZE * ITEMS_PER_LANE]
    out: cute.Tensor,  # [rows]
    REDUCE_OP: cutlass.Constexpr,
    ITEMS_PER_LANE: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
    REDUX_KIND: cutlass.Constexpr,
    ELEMENT_BYTES: cutlass.Constexpr,
) -> None:
    """Reduce one row per CTA with vector lane folds plus warp collectives."""
    row, _, _ = cute.arch.block_idx()
    tx, _, _ = cute.arch.thread_idx()

    row_width = _WARP_SIZE * ITEMS_PER_LANE
    lane_base = row * row_width + tx * ITEMS_PER_LANE
    src_ptr = src.iterator.raw_ptr() + lane_base
    out_ptr = out.iterator.raw_ptr() + row

    # Each lane first reduces its own contiguous segment. This keeps the
    # per-thread work vectorized before handing one scalar to the warp reducer.
    alignment = ITEMS_PER_LANE * ELEMENT_BYTES
    values = src_ptr.load(count=ITEMS_PER_LANE, alignment=alignment)
    lane_out = values.reduce(REDUCE_OP)
    if cutlass.const_expr(DTYPE == "i32"):
        warp_out = prims.redux_sync(lane_out, REDUX_KIND, _FULL_MASK)
    elif cutlass.const_expr(_use_f32_redux(DTYPE, REDUCE_OP)):
        warp_out = prims.redux_sync(lane_out, _f32_redux_kind(REDUCE_OP), _FULL_MASK)
    else:
        warp_out = _warp_reduce_tree(lane_out, REDUCE_OP, DTYPE)

    if tx == 0:
        out_ptr.store(warp_out)


# ---------------------------------------------------------------------------
# Host launcher
# ---------------------------------------------------------------------------


@cute.jit
def _host(
    src: cute.Tensor,
    out: cute.Tensor,
    stream,
    REDUCE_OP: cutlass.Constexpr,
    ITEMS_PER_LANE: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
    REDUX_KIND: cutlass.Constexpr,
    ELEMENT_BYTES: cutlass.Constexpr,
) -> None:
    """Launch one 32-lane CTA per row."""
    rows = src.shape[0]
    _kernel(
        src, out, REDUCE_OP, ITEMS_PER_LANE, DTYPE, REDUX_KIND, ELEMENT_BYTES
    ).launch(
        grid=(rows, 1, 1),
        block=(_WARP_SIZE, 1, 1),
        stream=stream,
    )


# ---------------------------------------------------------------------------
# Compile factory
# ---------------------------------------------------------------------------


@lru_cache(maxsize=None)
def compile(
    ITEMS_PER_LANE: int = _DEFAULT_ITEMS_PER_LANE,
    REDUCE_OP: str = _DEFAULT_REDUCE_OP,
    DTYPE: str = _DEFAULT_DTYPE,
) -> Callable:
    """AOT-compile the warp vector-reduction example."""
    REDUCE_OP = _normalize_reduce_op(REDUCE_OP)
    DTYPE = _normalize_dtype(DTYPE)
    REDUX_KIND = _redux_kind(REDUCE_OP)
    cutlass_dtype = _CUTLASS_DTYPES[DTYPE]
    source_align = max(16, ITEMS_PER_LANE * cutlass_dtype.bytes)
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
        ITEMS_PER_LANE,
        DTYPE,
        REDUX_KIND,
        cutlass_dtype.bytes,
        options="--enable-tvm-ffi",
    )


# ---------------------------------------------------------------------------
# Run
# ---------------------------------------------------------------------------


def run(
    compiled_fn: Callable,
    rows: int = _DEFAULT_ROWS,
    ITEMS_PER_LANE: int = _DEFAULT_ITEMS_PER_LANE,
    DTYPE: str = _DEFAULT_DTYPE,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, run the kernel, and return ``(out, src)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    DTYPE = _normalize_dtype(DTYPE)
    torch_dtype = _TORCH_DTYPES[DTYPE]
    row_width = _WARP_SIZE * ITEMS_PER_LANE
    src = torch.arange(rows * row_width, dtype=torch.float32, device="cuda").reshape(
        rows, row_width
    )
    src = (src % 23.0) - 11.0
    if DTYPE != "i32":
        # Fractional float inputs catch accidental use of integer redux kinds
        # on floating-point data.
        src = src * 0.5
    src = src.to(torch_dtype).contiguous()
    out = torch.empty(rows, dtype=torch_dtype, device="cuda")

    stream = cuda.CUstream(torch.cuda.current_stream().cuda_stream)
    compiled_fn(src, out, stream)
    torch.cuda.synchronize()
    return out, src


# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------


def verify(
    rows: int = _DEFAULT_ROWS,
    ITEMS_PER_LANE: int = _DEFAULT_ITEMS_PER_LANE,
    REDUCE_OP: str = _DEFAULT_REDUCE_OP,
    DTYPE: str = _DEFAULT_DTYPE,
) -> None:
    """Compile, run, and compare warp reductions with torch."""
    REDUCE_OP = _normalize_reduce_op(REDUCE_OP)
    DTYPE = _normalize_dtype(DTYPE)
    compiled_fn = compile(
        ITEMS_PER_LANE=ITEMS_PER_LANE,
        REDUCE_OP=REDUCE_OP,
        DTYPE=DTYPE,
    )
    print(
        "Compile kernel "
        f"(ITEMS_PER_LANE={ITEMS_PER_LANE}, REDUCE_OP={REDUCE_OP}, "
        f"DTYPE={DTYPE}) OK",
        flush=True,
    )

    out, src = run(
        compiled_fn,
        rows=rows,
        ITEMS_PER_LANE=ITEMS_PER_LANE,
        DTYPE=DTYPE,
    )
    print(
        "Run kernel "
        f"(rows={rows}, ITEMS_PER_LANE={ITEMS_PER_LANE}, "
        f"REDUCE_OP={REDUCE_OP}, DTYPE={DTYPE}) OK",
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
        f"(rows={rows}, ITEMS_PER_LANE={ITEMS_PER_LANE}, "
        f"REDUCE_OP={REDUCE_OP}, DTYPE={DTYPE}): PASS"
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> None:
    """Parse CLI arguments and run verification."""
    parser = argparse.ArgumentParser(
        description="Run the warp-level Vector.reduce plus redux/shuffle example.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--rows", type=int, default=_DEFAULT_ROWS, help="Number of rows"
    )
    parser.add_argument(
        "--items-per-lane",
        type=int,
        default=_DEFAULT_ITEMS_PER_LANE,
        choices=(2, 4, 8, 16),
        help="Compile-time contiguous elements reduced by each lane",
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
    verify(
        rows=args.rows,
        ITEMS_PER_LANE=args.items_per_lane,
        REDUCE_OP=args.REDUCE_OP,
        DTYPE=args.DTYPE,
    )


if __name__ == "__main__":
    main()
