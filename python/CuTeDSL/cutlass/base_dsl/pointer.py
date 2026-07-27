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

from typing import Type

from .._mlir import ir
from .._mlir.dialects import llvm
from .._mlir_helpers.arith import ArithValue
from .._mlir_helpers.op import dsl_user_op
from .address_space import AddressSpace
from .typing import Int32, Int64, Integer, Numeric, Pointer, _normalize_address_space


@dsl_user_op
def inttoptr(
    value: int | Integer | ArithValue | ir.Value,
    mem_space: AddressSpace | int,
    dtype: Type[Numeric],
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> Pointer:
    """Convert an integer address to a typed ``Pointer``.

    :param value: Integer address value.
    :param mem_space: Target pointer address space.
    :param dtype: Pointer element type.
    :return: Typed pointer in ``mem_space``.
    """
    space = _normalize_address_space(mem_space)
    if isinstance(value, int):
        address_dtype = (
            Int64 if space in (AddressSpace.generic, AddressSpace.gmem) else Int32
        )
        value = address_dtype(value).ir_value(loc=loc, ip=ip)
    elif isinstance(value, Integer):
        value = value.ir_value(loc=loc, ip=ip)
    elif isinstance(value, ArithValue):
        value = value.ir_value(loc=loc, ip=ip)
    elif not isinstance(value, ir.Value):
        raise TypeError(f"Unsupported value type for inttoptr: {type(value)}")

    res_val = llvm.inttoptr(llvm.PointerType.get(space.value), value, loc=loc, ip=ip)
    return Pointer._from_raw_ptr(res_val, dtype)


__all__ = ["inttoptr"]
