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
Thread block-level tile reduction through shared memory.

Each thread block owns a small 2-D tile with ``ROWS_PER_CTA`` rows and
``THREADS * ITEMS_PER_LANE`` columns. Every thread loads a contiguous vector
from the column dimension for each row, folds that vector locally with
``Vector.reduce``. Each warp then reduces its per-lane values with
``prims.redux_sync`` for ``i32`` reductions and sm_100a/sm_103a/sm_107a ``f32``
min/max, falling back to a shuffle tree for the other floating-point paths.
The cross-warp pass uses the narrowest shared-memory
primitive available for the specialization: scalar ``prims.red`` for
supported integer and add reductions, ATOMS-style integer-bitcast atomics for
``f32`` min/max, and an explicit SMEM warp-result combine for
``f16``/``bf16`` min/max because the ISA only supports those REDS forms as
vector operations. The REDS paths call ``prims.red`` on shared-memory
pointers so the pointer address space selects ``shared::cta`` lowering. After
a thread block barrier, one thread per row stores the compile-time
``REDUCE_OP`` result in the same dtype as the input.

Cross-warp reduction path:

+-------------------+--------------------------------+--------------------------------+--------------------------------+
| Dtype             | Add                            | Min                            | Max                            |
+===================+================================+================================+================================+
| ``i32``           | ``prims.redux_sync`` then       | ``prims.redux_sync`` then       | ``prims.redux_sync`` then       |
|                   | ``prims.red`` shared::cta add   | ``prims.red`` shared::cta min   | ``prims.red`` shared::cta max   |
+-------------------+--------------------------------+--------------------------------+--------------------------------+
| ``f32``           | Shuffle tree then              | sm_100a/103a/107a:             | sm_100a/103a/107a:             |
|                   | ``prims.red`` shared::cta add   | ``redux.sync.f32`` then        | ``redux.sync.f32`` then        |
|                   |                                | ``cute.arch.atomic_fmin``      | ``cute.arch.atomic_fmax``      |
|                   |                                | else shuffle tree then         | else shuffle tree then         |
|                   |                                | ``cute.arch.atomic_fmin``      | ``cute.arch.atomic_fmax``      |
+-------------------+--------------------------------+--------------------------------+--------------------------------+
| ``f16``/``bf16``  | Shuffle tree then              | Shuffle tree then              | Shuffle tree then              |
|                   | ``prims.red`` shared::cta add   | SMEM warp-result combine       | SMEM warp-result combine       |
+-------------------+--------------------------------+--------------------------------+--------------------------------+

To run::

    python CuTeDSL/experimental/primitives/reduction/block_smem_reduce.py
    python CuTeDSL/experimental/primitives/reduction/block_smem_reduce.py \
        --row-tiles 8 --items-per-lane 4 --dtype bf16

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

_DEFAULT_ROW_TILES: int = 4
_ROWS_PER_CTA: int = 4
_DEFAULT_ITEMS_PER_LANE: int = 4
_DEFAULT_REDUCE_OP: Literal["add", "max", "min"] = "add"
_WARP_SIZE: int = 32
_NUM_WARPS: int = 4
_THREADS: int = _WARP_SIZE * _NUM_WARPS
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
    """Return a validated dtype alias for block shared-memory reductions."""
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


@cute.jit
def _identity_value(
    REDUCE_OP: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
):
    """Return the Python literal identity for the selected op and dtype."""
    if cutlass.const_expr(REDUCE_OP == "add"):
        return 0
    if cutlass.const_expr(DTYPE == "i32"):
        if cutlass.const_expr(REDUCE_OP == "min"):
            return 2147483647
        return -2147483648
    if cutlass.const_expr(DTYPE == "f16"):
        if cutlass.const_expr(REDUCE_OP == "min"):
            return 65504.0
        return -65504.0
    if cutlass.const_expr(DTYPE == "bf16"):
        if cutlass.const_expr(REDUCE_OP == "min"):
            return 3.0e38
        return -3.0e38
    if cutlass.const_expr(REDUCE_OP == "min"):
        return 3.4028234663852886e38
    return -3.4028234663852886e38


@cute.jit
def _smem_red(
    ptr,
    value,
    REDUCE_OP: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
) -> None:
    """Contribute one warp result through NVVM REDS or ATOMS."""
    if cutlass.const_expr(DTYPE == "f32" and REDUCE_OP == "max"):
        cute.arch.atomic_fmax(ptr, value, sem="relaxed", scope="cta")
        return
    if cutlass.const_expr(DTYPE == "f32" and REDUCE_OP == "min"):
        cute.arch.atomic_fmin(ptr, value, sem="relaxed", scope="cta")
        return

    if cutlass.const_expr(REDUCE_OP == "add"):
        op = prims.ReductionOp.ADD
    elif cutlass.const_expr(REDUCE_OP == "min"):
        op = prims.ReductionOp.MIN
    else:
        op = prims.ReductionOp.MAX

    if cutlass.const_expr(DTYPE == "i32"):
        red_type = prims.ReductionType.S32
    elif cutlass.const_expr(DTYPE == "f16"):
        red_type = prims.ReductionType.F16
    elif cutlass.const_expr(DTYPE == "bf16"):
        red_type = prims.ReductionType.BF16
    else:
        red_type = prims.ReductionType.F32

    prims.red(
        op,
        red_type,
        ptr,
        value,
        mem_order=prims.MemOrder.RELAXED,
        mem_scope=prims.MemScope.CTA,
    )


@cute.kernel
def _kernel(
    src: cute.Tensor,  # [rows, _THREADS * ITEMS_PER_LANE]
    out: cute.Tensor,  # [rows]
    REDUCE_OP: cutlass.Constexpr,
    ITEMS_PER_LANE: cutlass.Constexpr,
    DTYPE: cutlass.Constexpr,
    REDUX_KIND: cutlass.Constexpr,
    ELEMENT_BYTES: cutlass.Constexpr,
) -> None:
    """Reduce one thread block-owned tile along K into row-vector outputs."""
    row_tile, _, _ = cute.arch.block_idx()
    tx, _, _ = cute.arch.thread_idx()
    warp_idx = tx // _WARP_SIZE
    lane_idx = tx % _WARP_SIZE

    need_smem_reduction = cutlass.const_expr(
        (DTYPE == "f16" or DTYPE == "bf16") and REDUCE_OP != "add"
    )
    # Scalar red.min/max.f16 and red.min/max.bf16 are rejected by ptxas; the
    # larger SMEM buffer shape stores one lane-0 warp result for that path.
    smem_buf_elems = cutlass.const_expr(
        _ROWS_PER_CTA * _NUM_WARPS if need_smem_reduction else _ROWS_PER_CTA
    )
    smem_buf = cutlass.Array(
        src.element_type,
        smem_buf_elems,
        space=cutlass.AddressSpace.smem,
        alignment=16,
    )

    row_width = _THREADS * ITEMS_PER_LANE
    row_base = row_tile * _ROWS_PER_CTA
    src_ptr = src.iterator.raw_ptr()

    if cutlass.const_expr(not need_smem_reduction):
        if tx < _ROWS_PER_CTA:
            smem_buf[tx] = _cast_to_dtype(_identity_value(REDUCE_OP, DTYPE), DTYPE)
        prims.barrier_cta_sync(0)

    alignment = ITEMS_PER_LANE * ELEMENT_BYTES
    for tile_row in cutlass.range_constexpr(_ROWS_PER_CTA):
        row = row_base + tile_row
        thread_base = row * row_width + tx * ITEMS_PER_LANE
        # Each thread owns a contiguous vector from the K dimension of this row.
        # The first reduction is local to that vector.
        values = (src_ptr + thread_base).load(count=ITEMS_PER_LANE, alignment=alignment)
        lane_out = values.reduce(REDUCE_OP)
        if cutlass.const_expr(DTYPE == "i32"):
            warp_out = prims.redux_sync(lane_out, REDUX_KIND, _FULL_MASK)
        elif cutlass.const_expr(_use_f32_redux(DTYPE, REDUCE_OP)):
            warp_out = prims.redux_sync(
                lane_out, _f32_redux_kind(REDUCE_OP), _FULL_MASK
            )
        else:
            warp_out = _warp_reduce_tree(lane_out, REDUCE_OP, DTYPE)

        if cutlass.const_expr(need_smem_reduction):
            if lane_idx == 0:
                smem_buf[tile_row * _NUM_WARPS + warp_idx] = warp_out
        else:
            if lane_idx == 0:
                _smem_red(smem_buf.data_ptr(tile_row), warp_out, REDUCE_OP, DTYPE)

    # Ensure every warp leader's shared-memory contribution or SMEM store is
    # visible before publishing the row result.
    prims.barrier_cta_sync(0)

    if tx < _ROWS_PER_CTA:
        row = row_base + tx
        if cutlass.const_expr(need_smem_reduction):
            row_smem_base = tx * _NUM_WARPS
            result = smem_buf[row_smem_base]
            for warp in cutlass.range_constexpr(1, _NUM_WARPS):
                result = _combine_value(
                    result,
                    smem_buf[row_smem_base + warp],
                    REDUCE_OP,
                    DTYPE,
                )
            (out.iterator.raw_ptr() + row).store(result)
        else:
            (out.iterator.raw_ptr() + row).store(smem_buf[tx])


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
    """Launch one 128-thread block per row tile."""
    rows = src.shape[0]
    row_tiles = rows // _ROWS_PER_CTA
    _kernel(
        src, out, REDUCE_OP, ITEMS_PER_LANE, DTYPE, REDUX_KIND, ELEMENT_BYTES
    ).launch(
        grid=(row_tiles, 1, 1),
        block=(_THREADS, 1, 1),
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
    """AOT-compile the thread block shared-memory reduction example."""
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
    row_tiles: int = _DEFAULT_ROW_TILES,
    ITEMS_PER_LANE: int = _DEFAULT_ITEMS_PER_LANE,
    DTYPE: str = _DEFAULT_DTYPE,
) -> tuple[torch.Tensor, torch.Tensor]:
    """Allocate tensors, run the kernel, and return ``(out, src)``."""
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA GPU required")

    DTYPE = _normalize_dtype(DTYPE)
    torch_dtype = _TORCH_DTYPES[DTYPE]
    rows = row_tiles * _ROWS_PER_CTA
    row_width = _THREADS * ITEMS_PER_LANE
    src = torch.arange(rows * row_width, dtype=torch.float32, device="cuda").reshape(
        rows, row_width
    )
    src = (src % 37.0) - 18.0
    if DTYPE != "i32":
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
    row_tiles: int = _DEFAULT_ROW_TILES,
    ITEMS_PER_LANE: int = _DEFAULT_ITEMS_PER_LANE,
    REDUCE_OP: str = _DEFAULT_REDUCE_OP,
    DTYPE: str = _DEFAULT_DTYPE,
) -> None:
    """Compile, run, and compare block reductions with torch."""
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
        row_tiles=row_tiles,
        ITEMS_PER_LANE=ITEMS_PER_LANE,
        DTYPE=DTYPE,
    )
    print(
        "Run kernel "
        f"(row_tiles={row_tiles}, "
        f"ITEMS_PER_LANE={ITEMS_PER_LANE}, "
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
        f"(row_tiles={row_tiles}, "
        f"ITEMS_PER_LANE={ITEMS_PER_LANE}, "
        f"REDUCE_OP={REDUCE_OP}, DTYPE={DTYPE}): PASS"
    )


# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------


def main() -> None:
    """Parse CLI arguments and run verification."""
    parser = argparse.ArgumentParser(
        description="Run the thread block shared-memory reduction example.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--row-tiles",
        type=int,
        default=_DEFAULT_ROW_TILES,
        help="Number of row tiles, each containing four rows",
    )
    parser.add_argument(
        "--items-per-lane",
        type=int,
        default=_DEFAULT_ITEMS_PER_LANE,
        choices=(2, 4, 8),
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
        row_tiles=args.row_tiles,
        ITEMS_PER_LANE=args.items_per_lane,
        REDUCE_OP=args.REDUCE_OP,
        DTYPE=args.DTYPE,
    )


if __name__ == "__main__":
    main()
