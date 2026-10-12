# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from __future__ import annotations

from collections.abc import Callable
from typing import Optional, Type

from cutlass._mlir import ir
from cutlass._mlir.dialects import arith
from cutlass._mlir.dialects import core as _core_ir
from cutlass._mlir.dialects import cute as _cute_ir
from cutlass._mlir._mlir_libs._cutlass_ir._core import TensorType as _CoreTensorType
from cutlass.base_dsl.typing import Integer, Numeric
from cutlass.cute.core import _pack_coord, _unpack_x_tuple
from cutlass.cute.typing import Coord, Shape
from cutlass.cutlass_dsl import dsl_user_op


class Tensor:
    """
    Thin SSA wrapper for ``!core.tensor`` values.
    """

    def __init__(self, value: ir.Value):
        self.value = value

    @property
    def type(self) -> ir.Type:
        return self.value.type

    @property
    @dsl_user_op
    def shape(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Shape:
        return _unpack_x_tuple(self.value.type.shape, loc=loc, ip=ip)

    def __extract_mlir_values__(self) -> list[ir.Value]:
        return [self.value]

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> Tensor:
        return Tensor(values[0])

    @dsl_user_op
    def __getitem__(
        self,
        coord: Coord,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor:
        if isinstance(coord, tuple):
            coord = _pack_coord(coord, loc=loc, ip=ip)
        return Tensor(_cute_ir.slice(self.value, coord, loc=loc, ip=ip))

    @dsl_user_op
    def to(
        self,
        dtype: Type[Numeric],
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor:
        """Convert the tensor's element type.

        Returns self unchanged if source and destination types match.

        :param dtype: Target element type (e.g. Float16, Float32)
        """
        src_ty = _CoreTensorType(self.value.type)
        src_dtype = Numeric.from_mlir_type(src_ty.element_type)
        if src_dtype is dtype:
            return self

        ir_dst_type = src_ty.clone(dtype.mlir_type)

        if src_dtype.is_float and dtype.is_float:
            op = _core_ir.truncf if dtype.width < src_dtype.width else _core_ir.extf
        elif src_dtype.is_float:
            assert issubclass(dtype, Integer)
            op = _core_ir.fptosi if dtype.signed else _core_ir.fptoui
        elif dtype.is_float:
            assert issubclass(src_dtype, Integer)
            op = _core_ir.sitofp if src_dtype.signed else _core_ir.uitofp
        elif dtype.width < src_dtype.width:
            op = _core_ir.trunci
        else:
            assert issubclass(src_dtype, Integer)
            if src_dtype.signed:
                op = _core_ir.extsi
            else:
                op = _core_ir.extui

        return Tensor(op(ir_dst_type, self.value, loc=loc, ip=ip))

    # Splat a scalar operand to this tensor's type; a Tensor passes through.
    def _coerce(
        self,
        other: Tensor | int | float,
        loc: Optional[ir.Location],
        ip: Optional[ir.InsertionPoint],
    ) -> ir.Value:
        if isinstance(other, Tensor):
            return other.value
        elem_ty = _CoreTensorType(self.value.type).element_type
        is_float = Numeric.from_mlir_type(elem_ty).is_float
        scalar = arith.constant(
            elem_ty, float(other) if is_float else int(other), loc=loc, ip=ip
        )
        return _core_ir.fill(self.value.type, scalar, loc=loc, ip=ip)

    # Apply a binary op, choosing the float / signed-int / unsigned-int variant by dtype.
    def _binary(
        self,
        other: Tensor | int | float,
        float_op: Callable[..., ir.Value],
        int_op_signed: Callable[..., ir.Value],
        int_op_unsigned: Callable[..., ir.Value],
        *,
        swap: bool = False,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor:
        rhs = self._coerce(other, loc, ip)
        lhs, rhs = (rhs, self.value) if swap else (self.value, rhs)
        numeric = Numeric.from_mlir_type(_CoreTensorType(self.value.type).element_type)
        if numeric.is_float:
            op = float_op
        else:
            assert issubclass(numeric, Integer)
            op = int_op_signed if numeric.signed else int_op_unsigned
        return Tensor(op(self.value.type, lhs, rhs, loc=loc, ip=ip))

    @dsl_user_op
    def __add__(
        self,
        other: Tensor | int | float,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor:
        return self._binary(
            other, _core_ir.addf, _core_ir.addi, _core_ir.addi, loc=loc, ip=ip
        )

    __radd__ = __add__

    @dsl_user_op
    def __sub__(
        self,
        other: Tensor | int | float,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor:
        return self._binary(
            other, _core_ir.subf, _core_ir.subi, _core_ir.subi, loc=loc, ip=ip
        )

    @dsl_user_op
    def __rsub__(
        self,
        other: Tensor | int | float,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor:
        return self._binary(
            other,
            _core_ir.subf,
            _core_ir.subi,
            _core_ir.subi,
            swap=True,
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def __mul__(
        self,
        other: Tensor | int | float,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor:
        return self._binary(
            other, _core_ir.mulf, _core_ir.muli, _core_ir.muli, loc=loc, ip=ip
        )

    __rmul__ = __mul__

    @dsl_user_op
    def __truediv__(
        self,
        other: Tensor | int | float,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor:
        return self._binary(
            other, _core_ir.divf, _core_ir.divsi, _core_ir.divui, loc=loc, ip=ip
        )

    @dsl_user_op
    def __rtruediv__(
        self,
        other: Tensor | int | float,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor:
        return self._binary(
            other,
            _core_ir.divf,
            _core_ir.divsi,
            _core_ir.divui,
            swap=True,
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def __neg__(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor:
        return self._binary(
            0, _core_ir.subf, _core_ir.subi, _core_ir.subi, swap=True, loc=loc, ip=ip
        )

    @dsl_user_op
    def maximum(
        self,
        other: Tensor | int | float,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Tensor:
        return self._binary(
            other, _core_ir.maximumf, _core_ir.maxsi, _core_ir.maxui, loc=loc, ip=ip
        )
