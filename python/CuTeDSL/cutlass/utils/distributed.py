# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from functools import partial
from typing import Tuple, Union

import cutlass
import cutlass.cute as cute
from cutlass.cute.typing import Pointer, Int32, Literal
from cutlass.cutlass_dsl import T, dsl_user_op
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm
from typing_extensions import deprecated

__all__ = [
    # Deprecated
    "atomicAdd",
    "ld_bypass",
    # Message Passing Lock & Unlock
    "multimem_red_add1",
    "red_add1",
    "spin_lock_atom_cas_relaxed_wait",
    "spin_lock_atom_cas_acquire_wait",
    "spin_lock_ld_lt_relaxed_wait",
    # Dispatch functions
    "multimem_ld_reduce",
    "multimem_st",
    # Load & Store - 128-bit (16 bytes)
    "multimem_ld_reduce_8xf16",
    "multimem_ld_reduce_4xf32",
    "multimem_ld_reduce_8xbf16",
    "multimem_ld_reduce_16xe4m3",
    "multimem_ld_reduce_16xe5m2",
    # Load & Store - 64-bit (8 bytes)
    "multimem_ld_reduce_4xf16",
    "multimem_ld_reduce_2xf32",
    "multimem_ld_reduce_4xbf16",
    "multimem_ld_reduce_8xe4m3",
    "multimem_ld_reduce_8xe5m2",
    # Load & Store - 32-bit (4 bytes)
    "multimem_ld_reduce_2xf16",
    "multimem_ld_reduce_1xf32",
    "multimem_ld_reduce_2xbf16",
    "multimem_ld_reduce_4xe4m3",
    "multimem_ld_reduce_4xe5m2",
    # Store
    "multimem_st_4xb32",
    "multimem_st_2xb32",
    "multimem_st_1xb32",
]

########################################################
# Deprecated
########################################################


@deprecated("atomicAdd is deprecated, use cute.arch.atomic_add instead")
@dsl_user_op
def atomicAdd(dst_ptr: Pointer, val: Int32, *, loc=None, ip=None) -> Int32:
    return cute.arch.atomic_add(
        ptr=dst_ptr.llvm_ptr,
        val=val,
        sem="relaxed",
        scope="sys",
        loc=loc,
        ip=ip,
    )


@deprecated(
    "ld_bypass is deprecated, use cute.arch.load with cop='cv' directly instead"
)
@cute.jit
def ld_bypass(input_tensor: cute.Tensor):
    fragment = cute.make_rmem_tensor(input_tensor.layout, input_tensor.element_type)
    copy_atom = cute.make_copy_atom(
        cute.nvgpu.CopyUniversalOp(),
        input_tensor.element_type,
        memory_order=cute.nvgpu.common.MemoryOrder.VOLATILE,
        memory_scope=cute.nvgpu.common.MemoryScope.SYS,
    )
    cute.copy_atom_call(copy_atom, input_tensor, fragment)
    vals = fragment.load()
    return vals


########################################################
# Message Passing Lock & Unlock
########################################################


@dsl_user_op
def multimem_red_release_gpu_add1(
    lock_ptr: Pointer,
    *,
    loc=None,
    ip=None,
) -> None:
    llvm.inline_asm(
        None,
        [lock_ptr.toint().ir_value(loc=loc, ip=ip)],
        "multimem.red.release.gpu.global.add.s32 [$0], 1;",
        "l",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def multimem_red_release_sys_add1(
    lock_ptr: Pointer,
    *,
    loc=None,
    ip=None,
) -> None:
    llvm.inline_asm(
        None,
        [lock_ptr.toint().ir_value(loc=loc, ip=ip)],
        "multimem.red.release.sys.global.add.s32 [$0], 1;",
        "l",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def multimem_red_relaxed_gpu_add1(
    lock_ptr: Pointer,
    loc=None,
    ip=None,
) -> None:
    llvm.inline_asm(
        None,
        [lock_ptr.toint().ir_value(loc=loc, ip=ip)],
        "multimem.red.relaxed.gpu.global.add.s32 [$0], 1;",
        "l",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def multimem_red_relaxed_sys_add1(
    lock_ptr: Pointer,
    loc=None,
    ip=None,
) -> None:
    llvm.inline_asm(
        None,
        [lock_ptr.toint().ir_value(loc=loc, ip=ip)],
        "multimem.red.relaxed.sys.global.add.s32 [$0], 1;",
        "l",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def multimem_red_add1(
    lock_ptr: Pointer,
    *,
    order: str,
    scope: str,
    loc=None,
    ip=None,
) -> None:
    """
    add 1 to multicast ptr
    """
    if scope == "gpu":
        if order == "release":
            multimem_red_release_gpu_add1(lock_ptr=lock_ptr, loc=loc, ip=ip)
        elif order == "relaxed":
            multimem_red_relaxed_gpu_add1(lock_ptr=lock_ptr, loc=loc, ip=ip)
    elif scope == "sys":
        if order == "release":
            multimem_red_release_sys_add1(lock_ptr=lock_ptr, loc=loc, ip=ip)
        elif order == "relaxed":
            multimem_red_relaxed_sys_add1(lock_ptr=lock_ptr, loc=loc, ip=ip)


@dsl_user_op
def red_add1(
    lock_ptr: Pointer,
    *,
    order: str,
    scope: str,
    loc=None,
    ip=None,
) -> None:
    """
    add 1 to unicast ptr
    """
    cute.arch.red(
        lock_ptr.llvm_ptr,
        Int32(1),
        op="add",
        dtype="s32",
        sem=order,
        scope=scope,
        loc=loc,
        ip=ip,
    )


@cute.jit
def spin_lock_atom_cas_relaxed_wait(
    lock_ptr: Pointer,
    *,
    expected_val: Int32,
    reset_val: Int32,
    scope: Literal["gpu", "sys"],
    loc=None,
    ip=None,
) -> None:
    """
    wait on a spin lock until the expected count is reached. Reset flag to reset_val if the expected count is reached.
    """
    result = 0
    while result != expected_val:
        result = cute.arch.atomic_cas(
            ptr=lock_ptr.llvm_ptr,
            cmp=Int32(expected_val),
            val=Int32(reset_val),
            sem="relaxed",
            scope=scope,
            loc=loc,
            ip=ip,
        )


@cute.jit
def spin_lock_atom_cas_acquire_wait(
    lock_ptr: Pointer,
    *,
    expected_val: Int32,
    reset_val: Int32,
    scope: Literal["gpu", "sys"],
    loc=None,
    ip=None,
) -> None:
    """
    wait on a spin lock until the expected count is reached. Reset flag to reset_val if the expected count is reached.
    """
    result = 0
    while result != expected_val:
        result = cute.arch.atomic_cas(
            ptr=lock_ptr.llvm_ptr,
            cmp=Int32(expected_val),
            val=Int32(reset_val),
            sem="acquire",
            scope=scope,
            loc=loc,
            ip=ip,
        )


@cute.jit
def spin_lock_ld_lt_relaxed_wait(
    lock_ptr: Pointer,
    *,
    expected_val: Int32,
    scope: Literal["gpu", "sys"],
    loc=None,
    ip=None,
) -> None:
    """
    wait on a spin lock until the expected count is reached.
    """
    result = 0
    while result < expected_val:
        result = cute.arch.load(
            lock_ptr.llvm_ptr,  # addr: Pointer to memory location
            Int32,  # dtype: Data type to load (Int32)
            sem="relaxed",
            scope=scope,
            loc=loc,  # loc: Source location for debugging
            ip=ip,  # ip: Insertion point in IR
        )


########################################################
# Multimem Load & Store
########################################################


# 128-bit (16 bytes) load-reduce base
@dsl_user_op
def multimem_ld_reduce_128bit_base(
    mc_ptr: Pointer,
    *,
    ptx_string: str = "",
    loc=None,
    ip=None,
) -> Tuple[Int32, Int32, Int32, Int32]:
    mc_ptr_int = mc_ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    return_struct = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(i32,i32,i32,i32)>"),
        [mc_ptr_int],
        ptx_string,
        "=r,=r,=r,=r,l",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )
    return_regs = [llvm.extractvalue(T.i32(), return_struct, [i]) for i in range(4)]
    return return_regs[0], return_regs[1], return_regs[2], return_regs[3]


# 64-bit (8 bytes) load-reduce base
@dsl_user_op
def multimem_ld_reduce_64bit_base(
    mc_ptr: Pointer,
    *,
    ptx_string: str = "",
    loc=None,
    ip=None,
) -> Tuple[Int32, Int32]:
    mc_ptr_int = mc_ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    return_struct = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(i32,i32)>"),
        [mc_ptr_int],
        ptx_string,
        "=r,=r,l",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )
    return_regs = [llvm.extractvalue(T.i32(), return_struct, [i]) for i in range(2)]
    return return_regs[0], return_regs[1]


# 32-bit (4 bytes) load-reduce base
@dsl_user_op
def multimem_ld_reduce_32bit_base(
    mc_ptr: Pointer,
    *,
    ptx_string: str = "",
    loc=None,
    ip=None,
) -> Tuple[Int32]:
    mc_ptr_int = mc_ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    return_struct = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(i32)>"),
        [mc_ptr_int],
        ptx_string,
        "=r,l",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )
    return_regs = [llvm.extractvalue(T.i32(), return_struct, [i]) for i in range(1)]
    return (return_regs[0],)


# 128-bit variants
multimem_ld_reduce_8xf16 = partial(
    multimem_ld_reduce_128bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f32.v4.f16x2 {$0, $1, $2, $3}, [$4];",
)
multimem_ld_reduce_4xf32 = partial(
    multimem_ld_reduce_128bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.v4.f32 {$0, $1, $2, $3}, [$4];",
)
multimem_ld_reduce_8xbf16 = partial(
    multimem_ld_reduce_128bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f32.v4.bf16x2 {$0, $1, $2, $3}, [$4];",
)
multimem_ld_reduce_16xe4m3 = partial(
    multimem_ld_reduce_128bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f16.v4.e4m3x4 {$0, $1, $2, $3}, [$4];",
)
multimem_ld_reduce_16xe5m2 = partial(
    multimem_ld_reduce_128bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f16.v4.e5m2x4 {$0, $1, $2, $3}, [$4];",
)

# 64-bit variants
multimem_ld_reduce_4xf16 = partial(
    multimem_ld_reduce_64bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f32.v2.f16x2 {$0, $1}, [$2];",
)
multimem_ld_reduce_2xf32 = partial(
    multimem_ld_reduce_64bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.v2.f32 {$0, $1}, [$2];",
)
multimem_ld_reduce_4xbf16 = partial(
    multimem_ld_reduce_64bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f32.v2.bf16x2 {$0, $1}, [$2];",
)
multimem_ld_reduce_8xe4m3 = partial(
    multimem_ld_reduce_64bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f16.v2.e4m3x4 {$0, $1}, [$2];",
)
multimem_ld_reduce_8xe5m2 = partial(
    multimem_ld_reduce_64bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f16.v2.e5m2x4 {$0, $1}, [$2];",
)

# 32-bit variants
multimem_ld_reduce_2xf16 = partial(
    multimem_ld_reduce_32bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f32.f16x2 {$0}, [$1];",
)
multimem_ld_reduce_1xf32 = partial(
    multimem_ld_reduce_32bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.f32 {$0}, [$1];",
)
multimem_ld_reduce_2xbf16 = partial(
    multimem_ld_reduce_32bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f32.bf16x2 {$0}, [$1];",
)
multimem_ld_reduce_4xe4m3 = partial(
    multimem_ld_reduce_32bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f16.e4m3x4 {$0}, [$1];",
)
multimem_ld_reduce_4xe5m2 = partial(
    multimem_ld_reduce_32bit_base,
    ptx_string="multimem.ld_reduce.weak.global.add.acc::f16.e5m2x4 {$0}, [$1];",
)


# 128-bit store
@dsl_user_op
def multimem_st_4xb32(
    mc_ptr: Pointer,
    x: Int32,
    y: Int32,
    z: Int32,
    w: Int32,
    *,
    loc=None,
    ip=None,
) -> None:
    mc_ptr_int = mc_ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    llvm.inline_asm(
        None,
        [mc_ptr_int, x, y, z, w],
        "multimem.st.weak.global.v4.f32 [$0], {$1, $2, $3, $4};",
        "l,r,r,r,r",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


# 64-bit store
@dsl_user_op
def multimem_st_2xb32(
    mc_ptr: Pointer,
    x: Int32,
    y: Int32,
    *,
    loc=None,
    ip=None,
) -> None:
    mc_ptr_int = mc_ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    llvm.inline_asm(
        None,
        [mc_ptr_int, x, y],
        "multimem.st.weak.global.v2.f32 [$0], {$1, $2};",
        "l,r,r",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


# 32-bit store
@dsl_user_op
def multimem_st_1xb32(
    mc_ptr: Pointer,
    x: Int32,
    *,
    loc=None,
    ip=None,
) -> None:
    mc_ptr_int = mc_ptr.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    llvm.inline_asm(
        None,
        [mc_ptr_int, x],
        "multimem.st.weak.global.f32 [$0], {$1};",
        "l,r",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )


########################################################
# Dispatch Functions
########################################################


@dsl_user_op
def multimem_ld_reduce(
    mc_ptr: Pointer,
    *,
    dtype,
    num_elements: int,
    loc=None,
    ip=None,
) -> Union[Tuple[Int32, Int32, Int32, Int32], Tuple[Int32, Int32], Tuple[Int32]]:
    """
    Dispatch to appropriate multimem_ld_reduce variant based on dtype and num_elements.

    Args:
        mc_ptr: Multicast pointer to load from
        dtype: Data type (e.g., cutlass.Float16, cutlass.Float32)
        num_elements: Number of dtype elements to load (determines vector width)

    Returns:
        Tuple of registers (4 for 128-bit, 2 for 64-bit, 1 for 32-bit)
    """
    if dtype == cutlass.Float16:
        if num_elements == 8:
            return multimem_ld_reduce_8xf16(mc_ptr, loc=loc, ip=ip)
        elif num_elements == 4:
            return multimem_ld_reduce_4xf16(mc_ptr, loc=loc, ip=ip)
        elif num_elements == 2:
            return multimem_ld_reduce_2xf16(mc_ptr, loc=loc, ip=ip)
    elif dtype == cutlass.Float32:
        if num_elements == 4:
            return multimem_ld_reduce_4xf32(mc_ptr, loc=loc, ip=ip)
        elif num_elements == 2:
            return multimem_ld_reduce_2xf32(mc_ptr, loc=loc, ip=ip)
        elif num_elements == 1:
            return multimem_ld_reduce_1xf32(mc_ptr, loc=loc, ip=ip)
    elif dtype == cutlass.BFloat16:
        if num_elements == 8:
            return multimem_ld_reduce_8xbf16(mc_ptr, loc=loc, ip=ip)
        elif num_elements == 4:
            return multimem_ld_reduce_4xbf16(mc_ptr, loc=loc, ip=ip)
        elif num_elements == 2:
            return multimem_ld_reduce_2xbf16(mc_ptr, loc=loc, ip=ip)
    elif dtype == cutlass.Float8E4M3FN:
        if num_elements == 16:
            return multimem_ld_reduce_16xe4m3(mc_ptr, loc=loc, ip=ip)
        elif num_elements == 8:
            return multimem_ld_reduce_8xe4m3(mc_ptr, loc=loc, ip=ip)
        elif num_elements == 4:
            return multimem_ld_reduce_4xe4m3(mc_ptr, loc=loc, ip=ip)
    elif dtype == cutlass.Float8E5M2:
        if num_elements == 16:
            return multimem_ld_reduce_16xe5m2(mc_ptr, loc=loc, ip=ip)
        elif num_elements == 8:
            return multimem_ld_reduce_8xe5m2(mc_ptr, loc=loc, ip=ip)
        elif num_elements == 4:
            return multimem_ld_reduce_4xe5m2(mc_ptr, loc=loc, ip=ip)
    raise ValueError(f"Unsupported dtype={dtype}, num_elements={num_elements}")


@dsl_user_op
def multimem_st(
    mc_ptr: Pointer,
    *regs: Int32,
    loc=None,
    ip=None,
) -> None:
    """
    Dispatch to appropriate multimem_st variant based on number of registers.

    Args:
        mc_ptr: Multicast pointer to store to
        *regs: 1, 2, or 4 Int32 registers to store
    """
    num_regs = len(regs)
    if num_regs == 4:
        multimem_st_4xb32(mc_ptr, regs[0], regs[1], regs[2], regs[3], loc=loc, ip=ip)
    elif num_regs == 2:
        multimem_st_2xb32(mc_ptr, regs[0], regs[1], loc=loc, ip=ip)
    elif num_regs == 1:
        multimem_st_1xb32(mc_ptr, regs[0], loc=loc, ip=ip)
    else:
        raise ValueError(f"Unsupported number of registers: {num_regs}")
