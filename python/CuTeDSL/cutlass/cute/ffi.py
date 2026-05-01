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

import functools
from typing import List, Optional

from cutlass.base_dsl.ffi import extern as base_extern
from cutlass.base_dsl.ffi import FFI, BitCode, mangle, ConstValue
from cutlass._mlir import ir
from cutlass._mlir.dialects import cute, llvm


def _implicit_convert(arg: List[ir.Value], typ: List[ir.Type]) -> List[ir.Value]:
    if len(arg) == 1 and len(typ) == 1:
        arg_type = arg[0].type
        typ_type = typ[0]
        # implicitly cast !cute.ptr -> !llvm.ptr
        if isinstance(typ_type, llvm.PointerType) and isinstance(
            arg_type, cute.PtrType
        ):
            ptr_value = arg[0]
            ptr_as_int = cute.ptrtoint(ir.IntegerType.get_signless(64), ptr_value)
            addr_space = cute.PtrType(ptr_value.type).address_space
            llvm_ptr_ty = llvm.PointerType.get(addr_space)
            llvm_ptr = llvm.inttoptr(llvm_ptr_ty, ptr_as_int)
            return [llvm_ptr]

    return arg


def ffi(
    *,
    name: str | None = None,
    params_types: list | None = None,
    return_type: Optional[ir.Type] = None,
    inline: bool = True,
    source: str | None = None,
) -> FFI:
    return FFI(
        name=name,
        params_types=params_types,
        return_type=return_type,
        inline=inline,
        source=source,
        implicit_convert=_implicit_convert,
    )


extern = functools.partial(base_extern, implicit_convert=_implicit_convert)

__all__ = [
    "ffi",
    "extern",
    "BitCode",
    "mangle",
    "ConstValue",
]
