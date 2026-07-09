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

from cutlass.address_space import AddressSpace
from typing import Optional, Type

from cutlass.cutlass_dsl import T, dsl_user_op

import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir import ir
from cutlass._mlir.dialects import nvvm, llvm

from ..typing import Int, Int32, Pointer, Numeric, NumericMeta


@dsl_user_op
def alloc_smem(
    element_type: Type[Numeric],
    size_in_elems: int,
    alignment: Optional[int] = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Pointer:
    """
    Statically allocates SMEM.

    :param element_type:  The pointee type of the pointer.
    :type element_type:   Type[Numeric]
    :param size_in_elems: The size of the allocation in terms of number of elements of the
                          pointee type
    :type size_in_elems:  int
    :param alignment:     An optional pointer alignment for the allocation
    :type alignment:      int
    :return:              A pointer to the start of the allocation
    :rtype:               Pointer
    """
    if not isinstance(element_type, NumericMeta):
        raise TypeError(
            f"element_type must be a type of Numeric, but got {element_type}"
        )

    if alignment is None:
        # Default alignment based on the element type's width
        alignment = element_type.width // 8
    ptr_ty = _cute_ir.PtrType.get(element_type.mlir_type, AddressSpace.smem, alignment)
    return _cute_nvgpu_ir.arch_alloc_smem(
        ptr=ptr_ty,
        input=ir.IntegerAttr.get(T.i32(), size_in_elems),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def get_dyn_smem(
    element_type: Type[Numeric],
    alignment: Optional[int] = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Pointer:
    """
    Retrieves a pointer to a dynamic SMEM allocation.

    :param element_type:  The pointee type of the pointer.
    :type element_type:   Type[Numeric]
    :param alignment:     An optional pointer alignment, the result pointer is offset appropriately
    :type alignment:      int
    :return:              A pointer to the start of the dynamic SMEM allocation with a correct
                          alignement
    :rtype:               Pointer
    """
    if not isinstance(element_type, NumericMeta):
        raise TypeError(
            f"element_type must be a type of Numeric, but got {element_type}"
        )

    if alignment is None:
        # Default alignment based on the element type's width
        alignment = element_type.width // 8
    ptr_ty = _cute_ir.PtrType.get(
        element_type.mlir_type,
        AddressSpace.smem,
        alignment,
    )
    return _cute_nvgpu_ir.arch_get_dyn_smem(ptr=ptr_ty, loc=loc, ip=ip)


@dsl_user_op
def get_dyn_smem_size(
    *, loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> int:
    """
    Gets the size in bytes of the dynamic shared memory that was specified at kernel launch time.
    This can be used for bounds checking during shared memory allocation.

    :return: The size of dynamic shared memory in bytes
    :rtype:  int
    """
    return _cute_nvgpu_ir.arch_get_dyn_smem_size(loc=loc, ip=ip)


@dsl_user_op
def map_dsmem_ptr(
    smem_ptr: Pointer,
    cta_rank_in_cluster: Int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Pointer:
    """
    Maps a shared memory pointer to a remote CTA's distributed shared memory.

    :param smem_ptr:            A pointer in SMEM.
    :type smem_ptr:             Pointer
    :param cta_rank_in_cluster: The CTA in cluster to map to
    :type cta_rank_in_cluster:  Int

    :return: A DSMEM CuTe pointer to the remote CTA's shared memory.
    :rtype: Pointer

    :raises TypeError: If smem_ptr is not a CuTe pointer.
    :raises ValueError: If smem_ptr is not in the SMEM address space.

    """
    if not isinstance(smem_ptr, Pointer):
        raise TypeError(f"smem_ptr must be a Pointer, but got {type(smem_ptr)}")
    # Public API validation: map_dsmem_ptr accepts only local SMEM pointers.
    if smem_ptr.memspace != AddressSpace.smem:
        raise ValueError(
            "map_dsmem_ptr expects smem_ptr to be an SMEM pointer, "
            f"but got {smem_ptr.memspace}"
        )

    mlir_type = smem_ptr.dtype.mlir_type
    memspace = AddressSpace.dsmem
    alignment = smem_ptr.alignment
    is_swizzled = smem_ptr.type.is_swizzled
    swizzle = smem_ptr.type.swizzle_type.attribute if is_swizzled else None
    ptr_type = _cute_ir.PtrType.get(mlir_type, memspace, alignment, swizzle)

    dsmem_llvm_ptr = nvvm.mapa(
        llvm.PointerType.get(memspace),
        smem_ptr.to_llvm_ptr(loc=loc, ip=ip),
        Int32(cta_rank_in_cluster).ir_value(loc=loc, ip=ip),
        loc=loc,
        ip=ip,
    )

    intptr = llvm.ptrtoint(T.i32(), dsmem_llvm_ptr, loc=loc, ip=ip)
    aligned_ty = _cute_ir.ConstrainedIntType.get(alignment, 32)
    aligned_intptr = _cute_ir.assume(aligned_ty, intptr, loc=loc, ip=ip)

    return _cute_ir.inttoptr(ptr_type, aligned_intptr, loc=loc, ip=ip)


@dsl_user_op
def store_async_dsmem(
    smem_ptr: Pointer,
    value: Int,
    mbar_ptr: Pointer,
    peer_cta_rank: Int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Asynchronous store to a remote CTA's shared memory via ``st.async.shared::cluster``.

    The store completion is tracked by the mbarrier's transaction count
    (``mbarrier::complete_tx::bytes``), allowing the caller to use a relaxed
    mbarrier arrive.

    :param smem_ptr:       Destination pointer in this CTA's shared memory.
    :param value:          The i32 value to store.
    :param mbar_ptr:       Mbarrier pointer in this CTA's shared memory.
                           Mapped to the peer CTA via ``nvvm.mapa``.
    :param peer_cta_rank:  Target CTA rank in the cluster.
    :raises TypeError:     If `smem_ptr` or `mbar_ptr` is not a CuTe pointer.
    :raises ValueError:    If `value` is not a scalar or 2/4-tuple, or if
                           `smem_ptr`/`mbar_ptr` is not in the SMEM address
                           space, or if `smem_ptr` is not aligned to
                           `4 * len(value)` bytes.
    """
    if not isinstance(smem_ptr, Pointer):
        raise TypeError(f"smem_ptr must be a Pointer, but got {type(smem_ptr)}")
    if not isinstance(mbar_ptr, Pointer):
        raise TypeError(f"mbar_ptr must be a Pointer, but got {type(mbar_ptr)}")
    if smem_ptr.memspace != AddressSpace.smem:
        raise ValueError(
            "store_async_dsmem expects smem_ptr to be an SMEM pointer, "
            f"but got {smem_ptr.memspace}"
        )
    if mbar_ptr.memspace != AddressSpace.smem:
        raise ValueError(
            "store_async_dsmem expects mbar_ptr to be an SMEM pointer, "
            f"but got {mbar_ptr.memspace}"
        )

    values = value if isinstance(value, tuple) else (value,)
    n = len(values)
    if n not in [1, 2, 4]:
        raise ValueError(
            f"store_async_dsmem: value must be a scalar or a tuple of 2 or 4 i32s, got {n}"
        )
    required_align = n * 4
    if smem_ptr.alignment % required_align != 0:
        raise ValueError(
            f"store_async_dsmem: v{n}.b32 requires {required_align}-byte aligned pointer, "
            f"but smem_ptr has alignment {smem_ptr.alignment}"
        )

    dsmem_ptr_ty = llvm.PointerType.get(AddressSpace.dsmem)
    cta_rank_ir = Int32(peer_cta_rank).ir_value(loc=loc, ip=ip)

    dsmem_addr = nvvm.mapa(
        dsmem_ptr_ty,
        smem_ptr.to_llvm_ptr(loc=loc, ip=ip),
        cta_rank_ir,
        loc=loc,
        ip=ip,
    )

    dsmem_mbar = nvvm.mapa(
        dsmem_ptr_ty,
        mbar_ptr.to_llvm_ptr(loc=loc, ip=ip),
        cta_rank_ir,
        loc=loc,
        ip=ip,
    )

    addr_i32 = llvm.ptrtoint(T.i32(), dsmem_addr, loc=loc, ip=ip)
    mbar_i32 = llvm.ptrtoint(T.i32(), dsmem_mbar, loc=loc, ip=ip)
    value_ir = Int32(value).ir_value(loc=loc, ip=ip)

    llvm.inline_asm(
        None,
        [addr_i32, value_ir, mbar_i32],
        "st.async.shared::cluster.mbarrier::complete_tx::bytes.b32 [$0], $1, [$2];",
        "r,r,r",
        has_side_effects=True,
        is_align_stack=False,
        asm_dialect=llvm.AsmDialect.AD_ATT,
        loc=loc,
        ip=ip,
    )
