# SPDX-FileCopyrightText: Copyright (c) 2025-2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""
This module provides MLIR Arith Dialect helper functions
"""

import array
from typing import Any, Callable, Optional, Union

import numpy as np

from ..base_dsl.common import *
from ..base_dsl.common import DSLRuntimeError, DSLNotImplemented
from .._mlir import ir
from .._mlir.extras import types as T
from .._mlir.dialects import arith, math, builtin
from .op import dsl_user_op

from .lru_cache_ir import lru_cache_ir

# =============================================================================
# Arith Dialect Helper functions
# =============================================================================


def recast_type(src_type: ir.Type, res_elem_type: ir.Type) -> ir.Type:
    if isinstance(src_type, T.VectorType):
        if src_type.scalable:
            res_type = T.vector(
                *src_type.shape,
                res_elem_type,
                scalable=src_type.scalable,
                scalable_dims=src_type.scalable_dims,
            )
        else:
            res_type = T.vector(*src_type.shape, res_elem_type)
    elif isinstance(src_type, T.RankedTensorType):
        res_type = T.RankedTensorType.get(
            element_type=res_elem_type, shape=src_type.shape, strides=src_type.strides
        )
    elif isinstance(src_type, T.UnrankedTensorType):
        res_type = T.UnrankedTensorType.get(element_type=res_elem_type)
    elif isinstance(src_type, T.MemRefType):
        res_type = T.MemRefType.get(
            element_type=res_elem_type, shape=src_type.shape, strides=src_type.strides
        )
    else:
        res_type = res_elem_type
    return res_type


def is_scalar(ty: ir.Type) -> bool:
    return not isinstance(
        ty, (T.VectorType, T.RankedTensorType, T.UnrankedTensorType, T.MemRefType)
    )


def element_type(ty: ir.Type) -> ir.Type:
    if not is_scalar(ty):
        return ty.element_type
    else:
        return ty


def is_narrow_precision(ty: ir.Type) -> bool:
    narrow_types = {
        T.f8E8M0FNU(),
        T.f8E4M3FN(),
        T.f8E4M3(),
        T.f8E5M2(),
        T.f8E4M3B11FNUZ(),
        T.f4E2M1FN(),
        T.f6E3M2FN(),
        T.f6E2M3FN(),
    }
    return ty in narrow_types


def is_float_type(ty: ir.Type) -> bool:
    return (
        isinstance(ty, ir.FloatType)
        # TODO-upstream: prediction is not correct. Patch here and fix in upstream later
        or is_narrow_precision(ty)
        or ty in (T.bf16(), T.tf32())
    )


def is_integer_like_type(ty: ir.Type) -> bool:
    return isinstance(ty, (ir.IntegerType, ir.IndexType))


def _python_int_for_integer_attr(value: int, width: int, signed: bool) -> int:
    """Coerce a Python int to a value MLIR's IntegerAttr.get accepts.

    MLIR's Python bindings only accept integers in the signed range of the
    target width. Unsigned DSL constants may be supplied either as canonical
    unsigned literals, e.g. 0xffffffffffffffff, or as the equivalent signed
    storage representation, e.g. -1.
    """
    if width <= 0:
        raise ValueError(f"Invalid integer width: {width}")

    signed_lo = -(1 << (width - 1))
    signed_hi = (1 << (width - 1)) - 1

    if signed:
        if not (signed_lo <= value <= signed_hi):
            raise ValueError(f"Signed integer literal {value} does not fit in i{width}")
        return value

    max_unsigned = (1 << width) - 1

    if signed_lo <= value < 0:
        return value

    if not (0 <= value <= max_unsigned):
        raise ValueError(
            f"Unsigned integer literal {value} does not fit in unsigned i{width}"
        )

    if value > signed_hi:
        return value - (1 << width)

    return value


def bitcast(
    src: ir.Value,
    res_elem_type: ir.Type,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    res_type = recast_type(src.type, res_elem_type)
    return arith.bitcast(res_type, src, loc=loc, ip=ip)


def cvtf(
    src: ir.Value,
    res_elem_type: ir.Type,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    src_elem_type = element_type(src.type)

    if res_elem_type == src_elem_type:
        return src

    res_type = recast_type(src.type, res_elem_type)

    # Treat TF32 as F32 and use i32 as intermediate data
    # TODO-upstream: update arith to support tf32 <-> f32 conversion
    if src_elem_type == T.tf32():
        # tf32 -> i32
        tmp_type = recast_type(src.type, T.i32())
        src = builtin.unrealized_conversion_cast([tmp_type], [src], loc=loc, ip=ip)
        # i32 -> f32
        src = bitcast(src, T.f32(), loc=loc, ip=ip)
        # f32 -> X with `cvtf` recursively
        return cvtf(src, res_elem_type, loc=loc, ip=ip)

    if res_elem_type == T.tf32():
        # X -> f32 with `cvtf`` recursively
        tmp = cvtf(src, T.f32(), loc=loc, ip=ip)
        # f32 -> i32
        tmp = bitcast(tmp, T.i32(), loc=loc, ip=ip)
        # i32 -> tf32
        return builtin.unrealized_conversion_cast([res_type], [tmp], loc=loc, ip=ip)

    if res_elem_type.width > src_elem_type.width:
        return arith.extf(res_type, src, loc=loc, ip=ip)
    else:
        # bf16 <-> f16: both are 16-bit, arith.truncf requires strict narrowing.
        # Route through f32 intermediate.
        if (src_elem_type == T.f16() and res_elem_type == T.bf16()) or (
            src_elem_type == T.bf16() and res_elem_type == T.f16()
        ):
            tmp_type = recast_type(src.type, T.f32())
            tmp = arith.extf(tmp_type, src, loc=loc, ip=ip)
            return arith.truncf(res_type, tmp, loc=loc, ip=ip)

        # E8M0 requires upward rounding; all others default to to_nearest_even
        roundingmode = (
            arith.RoundingMode.upward if res_elem_type == T.f8E8M0FNU() else None
        )
        return arith.truncf(res_type, src, roundingmode=roundingmode, loc=loc, ip=ip)


def fptoi(
    src: ir.Value,
    signed: Union[bool, None],
    res_elem_type: ir.Type,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    res_type = recast_type(src.type, res_elem_type)
    # TODO-upstream: update arith to support this kind of conversion
    if element_type(src.type) in (T.tf32(), T.bf16()):
        src = cvtf(src, T.f32(), loc=loc, ip=ip)

    if signed != False:  # noqa: E712
        return arith.fptosi(res_type, src, loc=loc, ip=ip)
    else:
        return arith.fptoui(res_type, src, loc=loc, ip=ip)


def itofp(
    src: ir.Value,
    signed: Union[bool, None],
    res_elem_type: ir.Type,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    res_type = recast_type(src.type, res_elem_type)

    orig_res_type = res_type
    # TODO-upstream: update arith to support this kind of conversion
    if res_elem_type in (T.tf32(), T.bf16()):
        res_type = recast_type(src.type, T.f32())

    if signed != False and element_type(src.type).width > 1:  # noqa: E712
        res = arith.sitofp(res_type, src, loc=loc, ip=ip)
    else:
        res = arith.uitofp(res_type, src, loc=loc, ip=ip)

    if orig_res_type == res_type:
        return res

    return cvtf(res, element_type(orig_res_type), loc=loc, ip=ip)


def int_to_int(
    a: ir.Value,
    dst_elem_type: Any,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    src_signed = a.signed
    dst_signed = dst_elem_type.signed
    src_width = element_type(a.type).width
    dst_width = dst_elem_type.width

    dst_mlir_type = recast_type(a.type, dst_elem_type.mlir_type)

    if dst_width == src_width:
        return a
    elif src_signed != False and not dst_signed:  # noqa: E712
        # Signed -> Unsigned
        if dst_width > src_width:
            return arith.extui(dst_mlir_type, a, loc=loc, ip=ip)
        else:
            return arith.trunci(dst_mlir_type, a, loc=loc, ip=ip)
    elif src_signed == dst_signed:
        # Same signedness
        if dst_width > src_width:
            if src_signed != False and src_width > 1:  # noqa: E712
                return arith.extsi(dst_mlir_type, a, loc=loc, ip=ip)
            else:
                return arith.extui(dst_mlir_type, a, loc=loc, ip=ip)
        else:
            return arith.trunci(dst_mlir_type, a, loc=loc, ip=ip)
    else:
        # Unsigned -> Signed
        if dst_width > src_width:
            return arith.extui(dst_mlir_type, a, loc=loc, ip=ip)
        else:
            # For truncation from unsigned to signed, we need to handle overflow
            # First truncate to the target width
            trunc = arith.trunci(dst_mlir_type, a, loc=loc, ip=ip)
            # Then reinterpret as signed
            if dst_signed:
                return arith.bitcast(dst_mlir_type, trunc, loc=loc, ip=ip)
            return trunc


# =============================================================================
# Arith Ops Emitter Helpers
#   - assuming type of lhs and rhs match each other
#   - op name matches python module operator
# =============================================================================


def _cast(
    res_elem_ty: ir.Type,
    src: ir.Value,
    is_signed: Optional[bool] = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    This function provides simplified interface to upstream op builder
        arith.truncf(T.vector(shape, new_type), src)

    is simplified as because it's element-wise op which can't change shape
        arith.truncf(new_type, src)
    """
    if isinstance(src, ir.Value):
        src_ty = src.type
    else:
        src_ty = type(src).mlir_type
        src = src.ir_value()

    src_elem_ty = element_type(src_ty)

    if src_elem_ty == res_elem_ty:
        return src
    elif is_float_type(src_elem_ty) and is_float_type(res_elem_ty):
        # float-to-float
        return cvtf(src, res_elem_ty, loc=loc, ip=ip)
    elif is_integer_like_type(src_elem_ty) and is_integer_like_type(res_elem_ty):
        if src_elem_ty.width >= res_elem_ty.width:
            cast_op = arith.trunci
        else:
            if is_signed != False:  # noqa: E712
                cast_op = arith.extsi
            else:
                cast_op = arith.extui

        res_ty = recast_type(src_ty, res_elem_ty)
        return cast_op(res_ty, src, loc=loc, ip=ip)
    elif is_float_type(src_elem_ty) and is_integer_like_type(res_elem_ty):
        return fptoi(src, is_signed, res_elem_ty, loc=loc, ip=ip)
    elif is_integer_like_type(src_elem_ty) and is_float_type(res_elem_ty):
        return itofp(src, is_signed, res_elem_ty, loc=loc, ip=ip)
    else:
        raise DSLRuntimeError(
            f"cast from {src_elem_ty} to {res_elem_ty} is not supported"
        )


@lru_cache_ir()
def const(
    value: Union[int, float, bool, np.ndarray],
    ty: Optional[Union[ir.Type, "NumericMeta"]] = None,  # type: ignore[name-defined]
    *,
    signed: Union[bool, None] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Generates dynamic expression for constant values.
    """
    from ..base_dsl.typing import Numeric, NumericMeta
    from ..base_dsl.dsl import is_dynamic_expression
    from ..base_dsl.utils.numpy import _numpy_type_to_mlir_type

    if isinstance(value, Numeric):
        value = value.value

    # Early return
    if is_dynamic_expression(value) and (
        isinstance(value.type, type(value.type))  # type: ignore[union-attr]
        or isinstance(value.type, type(T.bool()))  # type: ignore[union-attr]
    ):
        return value

    # Assume type
    if ty is None:
        if isinstance(value, float):
            ty = T.f32()
        elif isinstance(value, bool):
            ty = T.bool()
        elif isinstance(value, int):
            ty = T.i32()
        elif isinstance(value, np.ndarray):
            ty = T.vector(*value.shape, _numpy_type_to_mlir_type(value.dtype))
            value = array.array(value.dtype.kind, value.flatten().tolist())  # type: ignore[assignment]
        else:
            raise DSLNotImplemented(f"{type(value)} is not supported")
    elif isinstance(ty, NumericMeta):
        if signed is None:
            signed = getattr(ty, "signed", None)
        if isinstance(value, int) and signed is False:
            value = _python_int_for_integer_attr(value, ty.width, signed=False)
        ty = ty.mlir_type
    elif isinstance(ty, ir.Type):
        if isinstance(ty, ir.RankedTensorType) or isinstance(ty, ir.VectorType):
            elem_ty = ty.element_type
            if isinstance(elem_ty, ir.IntegerType):
                if isinstance(value, int) and signed is False:
                    value = _python_int_for_integer_attr(
                        value, elem_ty.width, signed=False
                    )
                attr = ir.IntegerAttr.get(elem_ty, value)
            else:
                attr = ir.FloatAttr.get(elem_ty, value)
            value = ir.DenseElementsAttr.get_splat(ty, attr)
        elif isinstance(ty, ir.FloatType) and isinstance(value, (bool, int)):
            value = float(value)
        elif is_integer_like_type(ty) and isinstance(value, float):
            value = int(value)
    else:
        raise DSLNotImplemented(f"type {ty} is not supported")

    if isinstance(value, int) and isinstance(ty, ir.IntegerType) and signed is False:
        value = _python_int_for_integer_attr(value, ty.width, signed=False)

    return arith.constant(ty, value, loc=loc, ip=ip)


def _dispatch_to_rhs_r_op(op: Callable[..., "ArithValue"]) -> Callable[..., Any]:
    """Decorator that dispatches to the right-hand-side's reverse operation.

    If the other operand is not an ArithValue or is a subclass (more specific)
    of ArithValue, this allows proper method resolution for binary operations.
    """

    def wrapper(
        self: "ArithValue", other: Union[int, float, bool, "ArithValue"], **kwargs: Any
    ) -> Any:
        if not isinstance(other, ArithValue):
            if not isinstance(other, (int, float, bool)):
                return NotImplemented

        return op(self, other, **kwargs)

    return wrapper


def _binary_op(op: Callable[..., "ArithValue"]) -> Callable[..., "ArithValue"]:
    """
    Decorator to check if the 'other' argument is an ArithValue.
    If not, returns NotImplemented.
    """

    def wrapper(
        self: "ArithValue", other: Union[int, float, bool, "ArithValue"], **kwargs: Any
    ) -> "ArithValue":
        if isinstance(other, (int, float, bool)):
            other = const(other, self.type, signed=self.signed).with_signedness(
                self.signed
            )

        return op(self, other, **kwargs)

    return wrapper


# Operator overloading
@ir.register_value_caster(ir.Float4E2M1FNType.static_typeid)
@ir.register_value_caster(ir.Float6E2M3FNType.static_typeid)
@ir.register_value_caster(ir.Float6E3M2FNType.static_typeid)
@ir.register_value_caster(ir.Float8E4M3FNType.static_typeid)
@ir.register_value_caster(ir.Float8E4M3B11FNUZType.static_typeid)
@ir.register_value_caster(ir.Float8E5M2Type.static_typeid)
@ir.register_value_caster(ir.Float8E4M3Type.static_typeid)
@ir.register_value_caster(ir.Float8E8M0FNUType.static_typeid)
@ir.register_value_caster(ir.BF16Type.static_typeid)
@ir.register_value_caster(ir.F16Type.static_typeid)
@ir.register_value_caster(ir.FloatTF32Type.static_typeid)
@ir.register_value_caster(ir.F32Type.static_typeid)
@ir.register_value_caster(ir.F64Type.static_typeid)
@ir.register_value_caster(ir.IntegerType.static_typeid)
@ir.register_value_caster(ir.RankedTensorType.static_typeid)
class ArithValue(ir.Value):
    """Overloads operators for MLIR's Arith dialects binary operations."""

    @dsl_user_op
    def __init__(
        self,
        v: Union[int, ir.Value],
        signed: Union[bool, None] = None,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        if isinstance(v, int):
            v = const(v, self.type, signed=signed, loc=loc, ip=ip)
        super().__init__(v)

        elem_ty = element_type(self.type)
        self.is_float = isinstance(elem_ty, ir.FloatType)
        # arith dialect consider `1` in `i1` as `-1`, treat it as unsigned for DSL
        self.signed = signed and elem_ty.width > 1

    @dsl_user_op
    def ir_value(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value:
        return self

    def with_signedness(self, signed: Union[bool, None]) -> "ArithValue":
        return type(self)(self, signed)

    @dsl_user_op
    def __neg__(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.type == T.bool():
            raise TypeError(
                "Negation, the operator `-` is not supported for boolean type"
            )

        if self.is_float:
            return arith.negf(self, loc=loc, ip=ip)
        else:
            c0 = arith.constant(self.type, 0, loc=loc, ip=ip)
            return arith.subi(c0, self, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __pow__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float and other.is_float:
            return math.powf(self, other, loc=loc, ip=ip)
        elif self.is_float and not other.is_float:
            return math.fpowi(self, other, loc=loc, ip=ip)
        elif not self.is_float and other.is_float:
            lhs = itofp(self, self.signed, T.f32(), loc=loc, ip=ip)
            rhs = cvtf(other, T.f32(), loc=loc, ip=ip)
            return math.powf(lhs, rhs, loc=loc, ip=ip)
        elif not self.is_float and not other.is_float:
            return math.ipowi(self, other, loc=loc, ip=ip)
        else:
            raise DSLNotImplemented(f"Unsupported '{self} ** {other}'")

    @dsl_user_op
    @_binary_op
    def __rpow__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return other.__pow__(self, loc=loc, ip=ip)

    # arith operators
    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __add__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            return arith.addf(self, other, loc=loc, ip=ip)
        else:
            return arith.addi(self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __sub__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            return arith.subf(self, other, loc=loc, ip=ip)
        else:
            return arith.subi(self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __mul__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            return arith.mulf(self, other, loc=loc, ip=ip)
        else:
            return arith.muli(self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __truediv__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            return arith.divf(self, other, loc=loc, ip=ip)
        else:
            lhs = itofp(self, self.signed, T.f32(), loc=loc, ip=ip)
            rhs = itofp(other, other.signed, T.f32(), loc=loc, ip=ip)
            return arith.divf(lhs, rhs, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __floordiv__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            q = arith.divf(self, other, loc=loc, ip=ip)
            return math.floor(q, loc=loc, ip=ip)
        elif self.signed != False:  # noqa: E712
            return arith.floordivsi(self, other, loc=loc, ip=ip)
        else:
            return arith.divui(self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __mod__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            return arith.remf(self, other, loc=loc, ip=ip)
        elif self.signed != False:  # noqa: E712
            return arith.remsi(self, other, loc=loc, ip=ip)
        else:
            return arith.remui(self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __radd__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return other.__add__(self, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __rsub__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return other.__sub__(self, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __rmul__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return other.__mul__(self, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __rtruediv__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return other.__truediv__(self, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __rfloordiv__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return other.__floordiv__(self, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __rmod__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return other.__mod__(self, loc=loc, ip=ip)

    # Comparison operators (comparison doesn't have right-hand-side variants)
    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __lt__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            return arith.cmpf(arith.CmpFPredicate.OLT, self, other, loc=loc, ip=ip)
        elif self.signed != False:  # noqa: E712
            return arith.cmpi(arith.CmpIPredicate.slt, self, other, loc=loc, ip=ip)
        else:
            return arith.cmpi(arith.CmpIPredicate.ult, self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __le__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            return arith.cmpf(arith.CmpFPredicate.OLE, self, other, loc=loc, ip=ip)
        elif self.signed != False:  # noqa: E712
            return arith.cmpi(arith.CmpIPredicate.sle, self, other, loc=loc, ip=ip)
        else:
            return arith.cmpi(arith.CmpIPredicate.ule, self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __eq__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            return arith.cmpf(arith.CmpFPredicate.OEQ, self, other, loc=loc, ip=ip)
        else:
            return arith.cmpi(arith.CmpIPredicate.eq, self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __ne__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            # In Python, bool(float("nan")) is True, so use unordered comparison here
            return arith.cmpf(arith.CmpFPredicate.UNE, self, other, loc=loc, ip=ip)
        else:
            return arith.cmpi(arith.CmpIPredicate.ne, self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __gt__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            return arith.cmpf(arith.CmpFPredicate.OGT, self, other, loc=loc, ip=ip)
        elif self.signed != False:  # noqa: E712
            return arith.cmpi(arith.CmpIPredicate.sgt, self, other, loc=loc, ip=ip)
        else:
            return arith.cmpi(arith.CmpIPredicate.ugt, self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __ge__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            return arith.cmpf(arith.CmpFPredicate.OGE, self, other, loc=loc, ip=ip)
        elif self.signed != False:  # noqa: E712
            return arith.cmpi(arith.CmpIPredicate.sge, self, other, loc=loc, ip=ip)
        else:
            return arith.cmpi(arith.CmpIPredicate.uge, self, other, loc=loc, ip=ip)

    # Unary operators
    @dsl_user_op
    def __abs__(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.is_float:
            return math.absf(self, loc=loc, ip=ip)
        else:
            return math.absi(self, loc=loc, ip=ip)

    @dsl_user_op
    def __invert__(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        # For i1 (boolean) types, the all-ones value is 1, not -1.
        # Using -1 with i1 vectors causes arith.constant to produce a
        # type mismatch (e.g. vector<32xi0> instead of vector<32xi1>).
        all_ones = 1 if element_type(self.type).width == 1 else -1
        return arith.xori(self, const(all_ones, self.type))

    # Bitwise operations
    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __and__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return arith.andi(self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __or__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return arith.ori(self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __xor__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return arith.xori(self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __rshift__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        if self.signed != False:  # noqa: E712
            return arith.shrsi(self, other, loc=loc, ip=ip)
        else:
            return arith.shrui(self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_dispatch_to_rhs_r_op
    @_binary_op
    def __lshift__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return arith.shli(self, other, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __rand__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return arith.andi(other, self, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __ror__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return arith.ori(other, self, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __rxor__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return arith.xori(other, self, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __rrshift__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return other.__rshift__(self, loc=loc, ip=ip)

    @dsl_user_op
    @_binary_op
    def __rlshift__(
        self,
        other: "ArithValue",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "ArithValue":
        return other.__lshift__(self, loc=loc, ip=ip)

    def __hash__(self) -> int:
        return super().__hash__()

    def __str__(self) -> str:
        return "?"

    def __repr__(self) -> str:
        return self.__str__()


def _min(
    lhs: ir.Value,
    rhs: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    This function provides a unified interface for building arith min

    Assuming the operands have the same type
    """
    from ..base_dsl.dsl import is_dynamic_expression

    if not is_dynamic_expression(lhs):
        if not is_dynamic_expression(rhs):
            return min(lhs, rhs)
        else:
            lhs = arith.constant(rhs.type, lhs, loc=loc, ip=ip)
    else:
        if not is_dynamic_expression(rhs):
            rhs = arith.constant(lhs.type, rhs, loc=loc, ip=ip)

    # Handle vector types
    if isinstance(lhs.type, T.VectorType):
        elem_type = lhs.type.element_type
        if is_integer_like_type(elem_type):
            assert hasattr(lhs, "signed"), (
                "Should have attribute `signed`, must be a bug"
            )
            if lhs.signed != False:  # noqa: E712
                return arith.minsi(lhs, rhs, loc=loc, ip=ip)
            else:
                return arith.minui(lhs, rhs, loc=loc, ip=ip)
        else:
            return arith.minimumf(lhs, rhs, loc=loc, ip=ip)
    elif is_integer_like_type(lhs.type):
        assert hasattr(lhs, "signed"), "Should have attribute `signed`, must be a bug"
        if lhs.signed != False:  # noqa: E712
            return arith.minsi(lhs, rhs, loc=loc, ip=ip)
        else:
            return arith.minui(lhs, rhs, loc=loc, ip=ip)
    else:
        return arith.minimumf(lhs, rhs, loc=loc, ip=ip)


def _max(
    lhs: ir.Value,
    rhs: ir.Value,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    This function provides a unified interface for building arith max

    Assuming the operands have the same type
    """
    from ..base_dsl.dsl import is_dynamic_expression

    if not is_dynamic_expression(lhs):
        if not is_dynamic_expression(rhs):
            return max(lhs, rhs)
        else:
            lhs = arith.constant(rhs.type, lhs, loc=loc, ip=ip)
    else:
        if not is_dynamic_expression(rhs):
            rhs = arith.constant(lhs.type, rhs, loc=loc, ip=ip)
    # Handle vector types
    if isinstance(lhs.type, T.VectorType):
        elem_type = lhs.type.element_type
        if isinstance(elem_type, ir.IntegerType):
            assert hasattr(lhs, "signed"), (
                "Should have attribute `signed`, must be a bug"
            )
            if lhs.signed != False:  # noqa: E712
                return arith.maxsi(lhs, rhs, loc=loc, ip=ip)
            else:
                return arith.maxui(lhs, rhs, loc=loc, ip=ip)
        else:
            return arith.maximumf(lhs, rhs, loc=loc, ip=ip)
    elif is_integer_like_type(lhs.type):
        assert hasattr(lhs, "signed"), "Should have attribute `signed`, must be a bug"
        if lhs.signed != False:  # noqa: E712
            return arith.maxsi(lhs, rhs, loc=loc, ip=ip)
        else:
            return arith.maxui(lhs, rhs, loc=loc, ip=ip)
    else:
        return arith.maximumf(lhs, rhs, loc=loc, ip=ip)


def __getattr__(name: str) -> object:
    if name == "Vector":
        from .vector import Vector

        return Vector
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
