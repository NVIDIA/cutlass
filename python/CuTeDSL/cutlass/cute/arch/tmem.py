# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from typing import Type

from cutlass.cutlass_dsl import dsl_user_op

import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir

from ..typing import Pointer, Int, Int32, Numeric, NumericMeta, Tensor

SM100_TMEM_CAPACITY_COLUMNS = (
    512  # deprecated; use get_max_tmem_alloc_cols(arch="sm_100") instead
)
SM100_TMEM_MIN_ALLOC_COLUMNS = (
    32  # deprecated; use get_min_tmem_alloc_cols(arch="sm_100") instead
)

TMEM_MAX_ALLOC_COLUMNS_MAP = {
    "sm_120": 512,
    "sm_103": 512,
    "sm_100": 512,
}

TMEM_MIN_ALLOC_COLUMNS_MAP = {
    "sm_120": 32,
    "sm_103": 32,
    "sm_100": 32,
}


def get_max_tmem_alloc_cols(compute_capability: str) -> int:
    """Get the tensor memory capacity in columns for a given compute capability.

    Returns the maximum TMEM capacity in columns available for the specified
    GPU compute capability.

    :param compute_capability: The compute capability string (e.g. "sm_100", "sm_103")
    :type compute_capability: str
    :return: The TMEM capacity in columns
    :rtype: int
    :raises ValueError: If the compute capability is not supported
    """
    if compute_capability not in TMEM_MAX_ALLOC_COLUMNS_MAP:
        raise ValueError(f"Unsupported compute capability: {compute_capability}")
    return TMEM_MAX_ALLOC_COLUMNS_MAP[compute_capability]



def get_min_tmem_alloc_cols(compute_capability: str) -> int:
    """Get the minimum TMEM allocation columns for a given compute capability.

    Returns the minimum TMEM allocation columns available for the specified
    GPU compute capability.

    :param compute_capability: The compute capability string (e.g. "sm_100", "sm_103")
    :type compute_capability: str
    :return: The minimum TMEM allocation columns
    :rtype: int
    :raises ValueError: If the compute capability is not supported
    """
    if compute_capability not in TMEM_MIN_ALLOC_COLUMNS_MAP:
        raise ValueError(f"Unsupported compute capability: {compute_capability}")
    return TMEM_MIN_ALLOC_COLUMNS_MAP[compute_capability]


@dsl_user_op
def retrieve_tmem_ptr(
    element_type: Type[Numeric],
    alignment: int,
    ptr_to_buffer_holding_addr: Pointer,
    *,
    loc=None,
    ip=None,
) -> Pointer:
    """
    Retrieves a pointer to TMEM with the provided element type and alignment.

    :param element_type:               The pointee type of the pointer.
    :type element_type:                Type[Numeric]
    :param alignment:                  The alignment of the result pointer
    :type alignment:                   int
    :param ptr_to_buffer_holding_addr: A pointer to a SMEM buffer holding the TMEM address of the
                                       start of the allocation allocation
    :type ptr_to_buffer_holding_addr:  Pointer
    :return:                           A pointer to TMEM
    :rtype:                            Pointer
    """
    if not isinstance(element_type, NumericMeta):
        raise TypeError(
            f"element_type must be a type of Numeric, but got {element_type}"
        )

    res_ty = _cute_ir.PtrType.get(
        element_type.mlir_type, _cute_ir.AddressSpace.tmem, alignment
    )
    return _cute_nvgpu_ir.arch_sm100_retrieve_tmem_ptr(
        res_ty, ptr_to_buffer_holding_addr.value, loc=loc, ip=ip
    )


@dsl_user_op
def alloc_tmem(
    num_columns: Int,
    smem_ptr_to_write_address: Pointer,
    is_two_cta=None,
    *,
    arch: str = "sm_100",
    loc=None,
    ip=None,
) -> None:
    """
    Allocates TMEM.

    :param num_columns: The number of TMEM columns to allocate
    :type num_columns:  Int
    :param smem_ptr_to_write_address: A pointer to a SMEM buffer where the TMEM address is written
                                      to
    :type smem_ptr_to_write_address:  Pointer
    :param is_two_cta:                Optional boolean parameter for 2-CTA MMAs
    :param arch:                      The architecture of the GPU.
    :type arch:                       str
    """
    tmem_max_alloc_cols = get_max_tmem_alloc_cols(arch)
    tmem_min_alloc_cols = get_min_tmem_alloc_cols(arch)
    if isinstance(num_columns, int):
        if (
            num_columns < tmem_min_alloc_cols
            or num_columns > tmem_max_alloc_cols
            or not (num_columns & (num_columns - 1) == 0)
        ):
            raise ValueError(
                f"num_columns must be between {tmem_min_alloc_cols} and {tmem_max_alloc_cols}, and must be pow of 2, but got {num_columns}"
            )
    _cute_nvgpu_ir.arch_sm100_alloc_tmem(
        Int32(num_columns).ir_value(loc=loc, ip=ip),
        smem_ptr_to_write_address.value,
        is_two_cta=is_two_cta,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def relinquish_tmem_alloc_permit(is_two_cta=None, *, loc=None, ip=None) -> None:
    """
    Relinquishes the right to allocate TMEM so that other CTAs potentially in a different grid can
    allocate.
    """
    _cute_nvgpu_ir.arch_sm100_relinquish_tmem_alloc_permit(
        is_two_cta=is_two_cta, loc=loc, ip=ip
    )


@dsl_user_op
def dealloc_tmem(
    tmem_ptr: Pointer,
    num_columns: Int,
    is_two_cta=None,
    *,
    arch: str = "sm_100",
    loc=None,
    ip=None,
) -> None:
    """
    Deallocates TMEM using the provided pointer and number of columns.

    :param tmem_ptr:    A pointer to the TMEM allocation to de-allocate
    :type tmem_ptr:     Pointer
    :param num_columns: The number of columns in the TMEM allocation
    :type num_columns:  Int
    :param is_two_cta:  Optional boolean parameter for 2-CTA MMAs
    :param arch:        The architecture of the GPU.
    :type arch:         str
    """
    tmem_max_alloc_cols = get_max_tmem_alloc_cols(arch)
    tmem_min_alloc_cols = get_min_tmem_alloc_cols(arch)
    if isinstance(num_columns, int):
        if (
            num_columns < tmem_min_alloc_cols
            or num_columns > tmem_max_alloc_cols
            or not (num_columns & (num_columns - 1) == 0)
        ):
            raise ValueError(
                f"num_columns must be between {tmem_min_alloc_cols} and {tmem_max_alloc_cols}, and must be pow of 2, but got {num_columns}"
            )
    _cute_nvgpu_ir.arch_sm100_dealloc_tmem(
        tmem_ptr.value,
        Int32(num_columns).ir_value(loc=loc, ip=ip),
        is_two_cta=is_two_cta,
        loc=loc,
        ip=ip,
    )
