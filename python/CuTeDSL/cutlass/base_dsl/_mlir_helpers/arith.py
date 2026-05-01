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
import builtins
from typing import Any, Callable, Optional, Union

import numpy as np

from ..common import *
from ..common import DSLRuntimeError, DSLNotImplemented
from ..._mlir import ir
from ..._mlir.extras import types as T
from ..._mlir.dialects import arith, math, builtin
from ..._mlir.dialects import nvgpu, vector, llvm
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
        arith._is_float_type(ty)
        # TODO-upstream: prediction is not correct. Patch here and fix in upstream later
        or is_narrow_precision(ty)
        or ty in (T.bf16(), T.tf32())
    )


def is_integer_like_type(ty: ir.Type) -> bool:
    return isinstance(ty, (ir.IntegerType, ir.IndexType))


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
    elif arith._is_integer_like_type(src_elem_ty) and arith._is_integer_like_type(
        res_elem_ty
    ):
        if src_elem_ty.width >= res_elem_ty.width:
            cast_op = arith.trunci
        else:
            if is_signed != False:  # noqa: E712
                cast_op = arith.extsi
            else:
                cast_op = arith.extui

        res_ty = recast_type(src_ty, res_elem_ty)
        return cast_op(res_ty, src, loc=loc, ip=ip)
    elif is_float_type(src_elem_ty) and arith._is_integer_like_type(res_elem_ty):
        return fptoi(src, is_signed, res_elem_ty, loc=loc, ip=ip)
    elif arith._is_integer_like_type(src_elem_ty) and is_float_type(res_elem_ty):
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
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Generates dynamic expression for constant values.
    """
    from ..typing import Numeric, NumericMeta
    from ..dsl import is_dynamic_expression
    from ..utils.numpy import _numpy_type_to_mlir_type

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
        ty = ty.mlir_type
    elif isinstance(ty, ir.Type):
        if ir.RankedTensorType.isinstance(ty) or ir.VectorType.isinstance(ty):
            elem_ty = ty.element_type
            if isinstance(elem_ty, ir.IntegerType):
                attr = ir.IntegerAttr.get(elem_ty, value)
            else:
                attr = ir.FloatAttr.get(elem_ty, value)
            value = ir.DenseElementsAttr.get_splat(ty, attr)
        elif arith._is_float_type(ty) and isinstance(value, (bool, int)):
            value = float(value)
        elif arith._is_integer_like_type(ty) and isinstance(value, float):
            value = int(value)
    else:
        raise DSLNotImplemented(f"type {ty} is not supported")

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
            other = const(other, self.type).with_signedness(self.signed)

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
            v = arith.constant(self.type, v, loc=loc, ip=ip)
        super().__init__(v)

        elem_ty = element_type(self.type)
        self.is_float = arith._is_float_type(elem_ty)
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
    from ..dsl import is_dynamic_expression

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
        if arith._is_integer_like_type(elem_type):
            assert hasattr(lhs, "signed"), (
                "Should have attribute `signed`, must be a bug"
            )
            if lhs.signed != False:  # noqa: E712
                return arith.minsi(lhs, rhs, loc=loc, ip=ip)
            else:
                return arith.minui(lhs, rhs, loc=loc, ip=ip)
        else:
            return arith.minimumf(lhs, rhs, loc=loc, ip=ip)
    elif arith._is_integer_like_type(lhs.type):
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
    from ..dsl import is_dynamic_expression

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
    elif arith._is_integer_like_type(lhs.type):
        assert hasattr(lhs, "signed"), "Should have attribute `signed`, must be a bug"
        if lhs.signed != False:  # noqa: E712
            return arith.maxsi(lhs, rhs, loc=loc, ip=ip)
        else:
            return arith.maxui(lhs, rhs, loc=loc, ip=ip)
    else:
        return arith.maximumf(lhs, rhs, loc=loc, ip=ip)


# =============================================================================
# Vector Type - Immutable on registers
# =============================================================================


@ir.register_value_caster(ir.VectorType.static_typeid)
class Vector(ArithValue):
    """Wrap an MLIR ``vector<NxTy>`` register value with DSL type information.

    Provides element extraction (``vec[i]`` / ``vec[a:b]``), element-wise
    arithmetic (``+``, ``-``, ``*``, ``/``), type conversion (:meth:`to`),
    and bit-reinterpretation (:meth:`bitcast`) on top of a raw MLIR vector.

    Vectors live entirely in registers — they carry no memory address and do
    not support in-place element assignment.

    Registered as the MLIR value caster for :class:`ir.VectorType`, so any
    op that returns a vector automatically produces a ``Vector`` instance.

    :param v: Underlying MLIR vector value.
    :type v: ir.Value
    :param dtype: DSL element type (e.g. ``Float32``, ``Int32``).
        Inferred from the MLIR element type when omitted.
    :type dtype: type, optional
    """

    _dtype: "type"
    _mlir_type: ir.Type
    _shape: "tuple[int, ...]"

    # Cache parameterized subclasses so ``Vector[T, N] is Vector[T, N]``.
    _parameterized_cache: "dict[tuple, type]" = {}

    @classmethod
    def __class_getitem__(cls, params: "tuple[type, int | tuple[int, ...]]") -> type:
        """Return a parameterized Vector subclass with a ``mlir_type`` descriptor.

        ``Vector[Int32, 4].mlir_type`` returns ``vector<4xi32>`` and
        ``Vector[Float32, (4, 8)].mlir_type`` returns ``vector<4x8xf32>``,
        matching the dual type-descriptor / value-constructor pattern of
        scalar types like ``Int32``.  Follows the same approach as
        ``Pointer.__class_getitem__``.
        """
        element_type, shape = params

        from ..typing import Numeric

        if not (isinstance(element_type, type) and issubclass(element_type, Numeric)):
            raise TypeError(
                f"Vector element type must be a Numeric type (Integer or Float), "
                f"got {element_type!r}"
            )
        if isinstance(shape, int):
            shape = (shape,)
        shape = tuple(shape)
        if not shape or any(d <= 0 for d in shape):
            raise ValueError(
                f"Vector shape dimensions must be positive integers, got {shape}"
            )
        key = (element_type, shape)
        if key not in cls._parameterized_cache:
            shape_str = "x".join(str(d) for d in shape)

            class _Parameterized(cls):  # type: ignore[valid-type, misc]
                """Vector subclass with an ``mlir_type`` type descriptor."""

                class mlir_type:  # noqa: N801
                    def __get__(
                        self, obj: object, objtype: Optional[type] = None
                    ) -> ir.Type:
                        return ir.VectorType.get(list(shape), element_type.mlir_type)  # type: ignore[arg-type, attr-defined]

                mlir_type = mlir_type()  # type: ignore[misc, assignment]

                @staticmethod
                def __get_mlir_types__() -> list:
                    """Return MLIR types list — compatible with FFI ``_to_mlir_types``."""
                    return [ir.VectorType.get(list(shape), element_type.mlir_type)]  # type: ignore[arg-type, attr-defined]

                @staticmethod
                def isinstance(value: object) -> bool:
                    """Check if an ``ir.Value`` matches this parameterized vector type."""
                    if not builtins.isinstance(value, ir.Value):
                        return False
                    ty = value.type
                    if not builtins.isinstance(ty, ir.VectorType):
                        return False
                    return (
                        list(ty.shape) == list(shape)  # type: ignore[arg-type]
                        and ty.element_type == element_type.mlir_type  # type: ignore[attr-defined]
                    )

            _Parameterized.__name__ = f"Vector[{element_type.__name__}, {shape_str}]"
            _Parameterized.__qualname__ = _Parameterized.__name__
            cls._parameterized_cache[key] = _Parameterized
        return cls._parameterized_cache[key]

    def __init__(
        self,
        v: "ir.Value",
        *,
        dtype: "type | None" = None,
        loc: "ir.Location | None" = None,
        ip: "ir.InsertionPoint | None" = None,
    ) -> None:
        # Derive signedness from dtype for ArithValue base
        signed = getattr(dtype, "signed", None)
        super().__init__(v, signed, loc=loc, ip=ip)

        # Infer dtype from MLIR element type if not provided
        if dtype is None:
            from ..typing import Numeric

            dtype = Numeric.from_mlir_type(self.type.element_type)
        self._dtype = dtype
        self._mlir_type = dtype.mlir_type  # type: ignore[attr-defined]

        # Shape is always derived from MLIR vector type
        self._shape = tuple(self.type.shape)

    # =========================================================================
    # DSL Infrastructure
    # =========================================================================

    def __extract_mlir_values__(self) -> list:
        return [self]

    def __extract_mlir_attributes__(self) -> list:
        return [ir.DictAttr.get({})]

    def __new_from_mlir_values__(self, values: list) -> "Vector":
        return Vector(values[0], dtype=self._dtype)

    def with_signedness(self, signed: Union[bool, None]) -> "Vector":
        """Override ArithValue.with_signedness for keyword-only __init__."""
        new_vec = Vector(self, dtype=self._dtype)
        elem_ty = self.type.element_type
        new_vec.signed = (
            signed
            and ir.IntegerType.isinstance(elem_ty)
            and ir.IntegerType(elem_ty).width > 1
        )
        return new_vec

    # =========================================================================
    # Properties
    # =========================================================================

    @property
    def dtype(self) -> "type":
        """The DSL element type (e.g., Float32, Int32)."""
        return self._dtype

    @property
    def shape(self) -> "tuple[int, ...]":
        """The logical shape of the vector array (1D, 2D, or 3D)."""
        return self._shape

    @property
    def _count(self) -> int:
        """Total number of elements (product of shape dimensions)."""
        result = 1
        for dim in self._shape:
            result *= dim
        return result

    def numel(self) -> int:
        """Total number of elements (product of all shape dimensions)."""
        return self._count

    # Vector has no memory space - it's always in registers
    # The space property is intentionally not exposed on Vector

    def ir_value(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value:
        """Return the underlying MLIR vector value."""
        return self

    # =========================================================================
    # Indexing Operations
    # =========================================================================

    def _compute_linear_index(
        self,
        indices: "tuple[Union[int, Int32], ...]",  # type: ignore[name-defined]
    ) -> "Union[int, Int32]":  # type: ignore[name-defined]
        """Compute linear index from multi-dimensional indices (row-major order)."""
        if len(indices) != len(self._shape):
            raise IndexError(
                f"Expected {len(self._shape)} indices for shape {self._shape}, "
                f"got {len(indices)}"
            )

        # Check if all indices are static (Python ints)
        all_static = all(isinstance(i, int) for i in indices)

        if all_static:
            # Static computation
            linear = 0
            stride = 1
            for i in range(len(self._shape) - 1, -1, -1):
                linear += indices[i] * stride
                stride *= self._shape[i]
            return linear
        else:
            from ..typing import Int32

            # Dynamic computation using Int32 arithmetic
            linear = Int32(0)  # type: ignore[assignment]
            stride = 1
            for i in range(len(self._shape) - 1, -1, -1):
                idx = indices[i] if isinstance(indices[i], Int32) else Int32(indices[i])
                linear = linear + idx * Int32(stride)
                stride *= self._shape[i]
            return linear

    def __getitem__(
        self,
        idx: "Union[int, Int32, tuple, slice]",  # type: ignore[name-defined]
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> object:
        """Extract an element or a contiguous sub-vector.

        Supports three indexing modes:

        * **Scalar index** — returns a single DSL scalar value::

            elem = vec[i]          # static int or Int32

        * **1-D slice** — all bounds must be static Python ``int``s::

            sub = vec[start:stop]        # stride defaults to 1
            sub = vec[start:stop:stride] # explicit stride

        * **Multi-dimensional slice** — one entry per dimension, all bounds
          must be static ``int``s.  An integer in a multi-dim slice is treated
          as a size-1 slice (the dimension is kept)::

            sub = mat[r0:r1, c0:c1]   # 2-D: rows r0:r1, cols c0:c1
            sub = mat[:, c0:c1]       # 2-D: all rows, cols c0:c1
            sub = mat[0, c0:c1]       # 2-D: row 0 (size 1), cols c0:c1

        Slices use ``vector.extract_strided_slice`` internally; dynamic
        (MLIR-value) slice bounds are **not** supported.

        :param idx: Element index (int or Int32), a slice, or a tuple of
            ints/slices for multi-dimensional access.
        :type idx: int or Int32 or tuple or slice
        :return: A scalar DSL value (for element indexing) or a new
            :class:`Vector` (for slice indexing).
        :rtype: Numeric or Vector
        :raises TypeError: If slice bounds are not static Python ints.
        :raises IndexError: If the number of dimensions in a multi-dim index
            does not match :attr:`shape`.
        """
        from ..utils.logger import log

        # Slice → extract_strided_slice (step==1) or vector.shuffle (step>1)
        if isinstance(idx, slice):
            start = idx.start if idx.start is not None else 0
            step = idx.step if idx.step is not None else 1
            stop = idx.stop if idx.stop is not None else self._count
            if not all(isinstance(v, int) for v in (start, stop, step)):
                raise TypeError(
                    "Vector slice indices must be static ints; "
                    f"got start={start}, stop={stop}, step={step}"
                )
            size = (stop - start + step - 1) // step
            result_ty = ir.VectorType.get([size], self._mlir_type)
            if step == 1:
                result = vector.extract_strided_slice(
                    result_ty, self, [start], [size], [step], loc=loc, ip=ip
                )
            else:
                # vector.extract_strided_slice requires stride==1; use shuffle instead
                mask = list(range(start, stop, step))
                result = vector.shuffle(self, self, mask, loc=loc, ip=ip)
            return Vector(result, dtype=self._dtype)

        # Multi-dimensional slice: tuple containing at least one slice object
        if isinstance(idx, tuple) and any(isinstance(i, slice) for i in idx):
            if len(idx) != len(self._shape):
                raise IndexError(
                    f"Expected {len(self._shape)} indices for shape {self._shape}, "
                    f"got {len(idx)}"
                )
            offsets: "list[int]" = []
            sizes: "list[int]" = []
            strides: "list[int]" = []
            for dim, (i, dim_size) in enumerate(zip(idx, self._shape)):
                if isinstance(i, slice):
                    start = i.start if i.start is not None else 0
                    stop = i.stop if i.stop is not None else dim_size
                    step = i.step if i.step is not None else 1
                    if not all(isinstance(v, int) for v in (start, stop, step)):
                        raise TypeError(
                            f"Vector slice indices must be static ints in dimension {dim}; "
                            f"got start={start}, stop={stop}, step={step}"
                        )
                    if step != 1:
                        raise NotImplementedError(
                            f"Multi-dimensional strided slice (step={step}) is not supported; "
                            "use step=1 for multi-dimensional slices"
                        )
                    offsets.append(start)
                    sizes.append(stop - start)
                    strides.append(1)
                elif isinstance(i, int):
                    # Integer index: treated as a size-1 slice (rank is preserved)
                    if i < 0:
                        i += dim_size
                    offsets.append(i)
                    sizes.append(1)
                    strides.append(1)
                else:
                    raise TypeError(
                        f"Vector multi-dimensional slice: dimension {dim} index must be "
                        f"a static int or slice, got {type(i).__name__}"
                    )
            result_ty = ir.VectorType.get(sizes, self._mlir_type)
            result = vector.extract_strided_slice(
                result_ty, self, offsets, sizes, strides, loc=loc, ip=ip
            )
            return Vector(result, dtype=self._dtype)

        # Normalize to tuple
        if not isinstance(idx, tuple):
            indices = (idx,)
        else:
            indices = idx

        # Compute linear index
        linear_idx = self._compute_linear_index(indices)

        log().info(
            f"Vector.__getitem__: idx={idx}, linear={linear_idx}, "
            f"dtype={self._dtype}, shape={self._shape}"
        )

        # For dynamic indices, we use llvm.extractelement instead of vector.extract
        # because vector.extract has issues with dynamic positions
        if isinstance(linear_idx, int):
            # Static index - use vector.extract with static position
            elem = vector.extract(self, [], [linear_idx])
        else:
            # Dynamic index - use llvm.extractelement
            elem = llvm.extractelement(self, linear_idx.ir_value())

        return self._dtype(elem)

    def __setitem__(
        self,
        idx: "Union[int, Int32, tuple]",  # type: ignore[name-defined]
        value: object,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        Vector element assignment is not supported.

        Vectors are immutable register values. Use one of these alternatives:

        1. Use Array for mutable memory-backed storage:
           arr = ctm.allocate_memory_local(ctm.Float32, 4)
           arr[0] = value  # This works

        2. Use full() to create vectors with initial values:
           vec = ctm.full((4,), 1.0, ctm.Float32)
        """
        raise TypeError(
            "Vector is immutable. Element assignment (vec[i] = value) is not supported. "
        )

    # =========================================================================
    # Arithmetic Operations
    # =========================================================================

    def _is_float_type(self) -> bool:
        """Check if this vector contains floating-point elements."""
        return arith._is_float_type(self._mlir_type)

    # Arithmetic operators (+, -, *, /, -x) are inherited from ArithValue.
    # Results are automatically wrapped as Vector via the value caster.

    def to(
        self,
        dtype: "type",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        """Convert the vector elements to a different numeric type.

        :param dtype: Target DSL element type (e.g. ``Float16``, ``Int32``).
        :type dtype: Type[Numeric]
        :return: A new :class:`Vector` with the same shape and elements cast
            to ``dtype``.
        :rtype: Vector
        :raises TypeError: If ``dtype`` is not a subclass of ``Numeric``.

        Example::

            vec_f32 = ctm.full([4], 1.5, dtype=ctm.Float32)
            vec_i32 = vec_f32.to(ctm.Int32)    # fp → int truncation
            vec_f16 = vec_f32.to(ctm.Float16)  # fp32 → fp16 narrowing
        """
        from inspect import isclass
        from ..typing import Numeric, Integer

        if dtype is ir.Value:
            return self

        if not isclass(dtype) or not issubclass(dtype, Numeric):
            raise TypeError(f"dtype must be a type of Numeric, but got {type(dtype)}")

        src_dtype = self._dtype
        if src_dtype == dtype:
            return self

        # maybe_downcast handles narrow precision types, with_signedness sets signedness
        src = self.maybe_downcast().with_signedness(self.signed)

        if src_dtype.is_float and dtype.is_float:  # type: ignore[attr-defined]
            res_vect = cvtf(src, dtype.mlir_type, loc=loc, ip=ip)
        elif src_dtype.is_float and issubclass(dtype, Integer):  # type: ignore[attr-defined]
            res_vect = fptoi(src, dtype.signed, dtype.mlir_type, loc=loc, ip=ip)
        elif issubclass(src_dtype, Integer) and dtype.is_float:
            res_vect = itofp(src, src_dtype.signed, dtype.mlir_type, loc=loc, ip=ip)
        else:
            res_vect = int_to_int(src, dtype, loc=loc, ip=ip)

        return Vector(res_vect, dtype=dtype)

    @dsl_user_op
    def bitcast(
        self,
        dtype: "type",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        """Reinterpret the vector bits as a different element type.

        The total bit width is preserved; the element count adjusts
        proportionally.  For example, ``vector<4xi32>`` bitcast to
        ``Float16`` yields ``vector<8xf16>`` (4 × 32 = 8 × 16 bits).

        :param dtype: Target DSL element type (e.g. ``Float32``, ``Float16``).
        :type dtype: Type[Numeric]
        :return: A new :class:`Vector` with bits reinterpreted as ``dtype``.
        :rtype: Vector
        :raises TypeError: If ``dtype`` is not a subclass of ``Numeric``.
        """
        from inspect import isclass
        from ..typing import Numeric

        if not isclass(dtype) or not issubclass(dtype, Numeric):
            raise TypeError(f"dtype must be a Numeric type, but got {dtype}")
        if dtype is self._dtype:
            return self
        new_count = self._count * self._dtype.width // dtype.width  # type: ignore[attr-defined]
        target_vec_ty = T.vector(new_count, dtype.mlir_type)
        res_vec = vector.bitcast(target_vec_ty, self, loc=loc, ip=ip)
        return Vector(res_vec, dtype=dtype, loc=loc, ip=ip)

    @dsl_user_op
    def __add__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        result = super().__add__(other, loc=loc, ip=ip)
        return Vector(result, dtype=self.dtype, loc=loc, ip=ip)

    @dsl_user_op
    def __radd__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        result = super().__radd__(other, loc=loc, ip=ip)
        return Vector(result, dtype=self.dtype, loc=loc, ip=ip)

    @dsl_user_op
    def __sub__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        result = super().__sub__(other, loc=loc, ip=ip)
        return Vector(result, dtype=self.dtype, loc=loc, ip=ip)

    @dsl_user_op
    def __rsub__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        result = super().__rsub__(other, loc=loc, ip=ip)
        return Vector(result, dtype=self.dtype, loc=loc, ip=ip)

    @dsl_user_op
    def __mul__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        result = super().__mul__(other, loc=loc, ip=ip)
        return Vector(result, dtype=self.dtype, loc=loc, ip=ip)

    @dsl_user_op
    def __rmul__(
        self,
        other: "Vector",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "Vector":
        result = super().__rmul__(other, loc=loc, ip=ip)
        return Vector(result, dtype=self.dtype, loc=loc, ip=ip)
