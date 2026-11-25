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

"""Emit checked CUDA queries in DSL host IR.

The calls execute in the generated host function, not during Python tracing.
Query errors propagate through ``cuda.return_if_error`` before loading results.
"""

from .._mlir import ir
from .._mlir.dialects import cuda, llvm


def _i32(
    value: int, *, loc: ir.Location | None = None, ip: ir.InsertionPoint | None = None
) -> ir.Value:
    ty = ir.IntegerType.get_signless(32)
    return llvm.ConstantOp(ty, ir.IntegerAttr.get(ty, int(value)), loc=loc, ip=ip).res


def _query_i32(
    callee: str,
    operands: list[ir.Value],
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> ir.Value:
    module = (ip or ir.InsertionPoint.current).block.owner.operation
    while module.parent is not None:
        module = module.parent

    i32 = ir.IntegerType.get_signless(32)
    ptr = ir.Type.parse("!llvm.ptr")
    symbols = ir.SymbolTable(module)
    if callee not in symbols:
        params = ", ".join(str(t) for t in [ptr, *(v.type for v in operands)])
        with ir.InsertionPoint(module.regions[0].blocks[0]):
            llvm.func(
                callee,
                ir.TypeAttr.get(ir.Type.parse(f"!llvm.func<i32 ({params})>")),
                loc=loc,
            )
    slot = llvm.alloca(
        res=ptr,
        elem_type=i32,
        array_size=_i32(1, loc=loc, ip=ip),
        alignment=4,
        loc=loc,
        ip=ip,
    )
    status = llvm.call(
        i32,
        callee=callee,
        callee_operands=[slot, *operands],
        op_bundle_sizes=[],
        op_bundle_operands=[],
        loc=loc,
        ip=ip,
    )
    cuda.return_if_error([status], loc=loc, ip=ip)
    return llvm.load(i32, slot, loc=loc, ip=ip)


def get_device(
    *, loc: ir.Location | None = None, ip: ir.InsertionPoint | None = None
) -> ir.Value:
    """Emit a checked query for the current CUDA device ID."""
    return _query_i32("_cudaGetDevice", [], loc=loc, ip=ip)


def device_get_attribute(
    attribute: int,
    device: ir.Value,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> ir.Value:
    """Emit a checked device attribute query returning an i32 value."""
    attr = _i32(attribute, loc=loc, ip=ip)
    return _query_i32("_cudaDeviceGetAttribute", [attr, device], loc=loc, ip=ip)


def kernel_get_attribute(
    kernel: ir.SymbolRefAttr,
    attribute: int,
    device: ir.Value,
    *,
    loc: ir.Location | None = None,
    ip: ir.InsertionPoint | None = None,
) -> ir.Value:
    """Emit a checked attribute query for a loaded kernel symbol."""
    ptr = ir.Type.parse("!llvm.ptr")
    slot = cuda.addressof(
        ir.Type.parse("!ptr.ptr<#ptr.generic_space>"), kernel, loc=loc, ip=ip
    )
    slot = cuda.cast(ptr, slot, loc=loc, ip=ip)
    handle = llvm.load(ptr, slot, loc=loc, ip=ip)
    attr = _i32(attribute, loc=loc, ip=ip)
    return _query_i32("_cuKernelGetAttribute", [attr, handle, device], loc=loc, ip=ip)
