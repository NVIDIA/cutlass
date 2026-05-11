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

from typing import Type, Optional
from cutlass._mlir.dialects import cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir import ir
from cutlass.cutlass_dsl import dsl_user_op
from cutlass._mlir.dialects import (
    lir as cutlass_lir,
    cute as _cute_ir,
)
from cutlass._mlir.dialects.core import OperationTypeEnum
from cutlass import cute


def _get_tma_load_kind(
    tma_operation_type: OperationTypeEnum,
) -> _cute_ir.TiledTmaLoadEnum:
    """Convert OperationTypeEnum to TiledTmaLoadEnum."""
    if tma_operation_type == OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST:
        return _cute_ir.TiledTmaLoadEnum.sm_100_2sm_multicast
    if tma_operation_type == OperationTypeEnum.SM90_TMA_LOAD_MULTICAST:
        return _cute_ir.TiledTmaLoadEnum.sm_90_multicast
    if tma_operation_type == OperationTypeEnum.SM100_TMA_LOAD_2SM:
        return _cute_ir.TiledTmaLoadEnum.sm_100_2sm
    if tma_operation_type == OperationTypeEnum.SM90_TMA_LOAD:
        return _cute_ir.TiledTmaLoadEnum.sm_90
    raise ValueError(f"Unsupported TMA operation type: {tma_operation_type}")


@dsl_user_op
def allocate(
    type: Type[cute.Numeric],
    address_space: cute.AddressSpace,
    layout: cute.Layout | cute.ComposedLayout,
    alignment: cute.Int32,
    is2cta: bool = False,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Tensor:
    """
    Allocate a buffer of the given type and layout.

    :param type: The type of the buffer
    :type type: cute.Tensor
    :param layout: The layout of the buffer
    :type layout: cute.Layout
    :param address_space: The address space of the buffer
    :type address_space: str
    :param alignment: The alignment of the buffer
    :type alignment: cute.Int32
    :param is2cta: Whether TMEM allocation should span a CTA pair (2CTA TMEM)
    :type is2cta: bool
    """
    swizzle = None
    if isinstance(layout, cute.ComposedLayout):
        swizzle = layout.inner
        layout = layout.outer

    bit_layout = None

    _is_passthrough_type = False
    if not _is_passthrough_type:
        type = type.mlir_type

    ptr_ty = _cute_ir.PtrType.get(
        type,
        address_space,
        alignment,
        swizzle.type.attribute if swizzle else None,
        None,
        bit_layout.type.attribute if bit_layout else None,
    )
    buffer_type = _cute_ir.MemRefType.get(ptr_ty, layout.type)

    # `is2cta` is a UnitAttr flag in the IR:
    # present => true, absent => false.
    is2cta_attr = ir.UnitAttr.get() if is2cta else None
    buffer_op = cutlass_lir.AllocateBufferOp(
        buffer_type, is2cta=is2cta_attr, loc=loc, ip=ip
    )
    return buffer_op.result


@dsl_user_op
def tma_load(
    src: cute.Tensor,
    dst: cute.Tensor,
    mbar: ir.Value,
    *,
    cta_v_map: Optional[cute.Layout] = None,
    tma_operation_type: Optional[OperationTypeEnum] = None,
    internal_type: Optional[Type[cute.Numeric]] = None,
    update_expect_tx: bool = True,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Copies a tensor pointed by a !cute.memref into a Buffer using TMA.

    update_expect_tx (bool): controls whether this operation increments the mbarrier's transaction bytes with the TMA copy size.
    When used with Cute DSL pipelines, it must be set to False as the pipeline already initializes the mbarrier's transaction bytes.
    tma_operation_type (optional): specifies the TMA operation type (SM90_TMA_LOAD, SM100_TMA_LOAD_2SM, etc.)
    internal_type (optional): selects the TMA transfer's internal element encoding used by hardware.
    """
    if tma_operation_type is not None:
        kind = _get_tma_load_kind(tma_operation_type)
    else:
        kind = _cute_ir.TiledTmaLoadEnum.sm_90

    kwargs = {
        "kind": kind,
        "loc": loc,
        "ip": ip,
    }
    if cta_v_map is not None:
        kwargs["cta_v_map"] = cta_v_map.type.attribute
    # Map internal_type to tma_format per updated API
    if internal_type is not None:
        internal_mlir_ty = (
            internal_type.mlir_type
            if hasattr(internal_type, "mlir_type")
            else internal_type
        )
        kwargs["tma_format"] = _cute_nvgpu_ir.TmaDataFormat(
            _cute_nvgpu_ir.get_default_tma_format(internal_mlir_ty, False)
        )

    if update_expect_tx:
        kwargs["update_expect_tx"] = True
    cutlass_lir.TmaLoadOp(src.value, dst.value, mbar, **kwargs)


@dsl_user_op
def tma_load_multicast(
    src: cute.Tensor,
    dst: cute.Tensor,
    mbar: ir.Value,
    *,
    vmnk_layout: cute.Layout,
    cta_v_map: Optional[cute.Layout] = None,
    tma_operation_type: OperationTypeEnum,
    multicast_mode: int,
    update_expect_tx: bool = True,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Copies a tensor pointed by a !cute.memref into a Buffer using TMA with multicast.

    :param src: Source tensor in global memory
    :param dst: Destination tensor in shared memory
    :param mbar: Memory barrier for synchronization
    :param vmnk_layout: Layout describing the cluster configuration
    :param cta_v_map: CTA V-map for the tensor
    :param tma_operation_type: TMA operation type (e.g., SM90_TMA_LOAD_MULTICAST, SM100_TMA_LOAD_2SM_MULTICAST)
    :param multicast_mode: Multicast projection mode (1=column, 2=row)
    :param update_expect_tx: Whether to update expected transaction bytes
    """
    kind = _get_tma_load_kind(tma_operation_type)
    kwargs = {
        "kind": kind,
        "vmnk_layout": vmnk_layout,
        "multicast_mode": multicast_mode,
        "loc": loc,
        "ip": ip,
    }
    if cta_v_map is not None:
        kwargs["cta_v_map"] = cta_v_map.type.attribute

    if update_expect_tx:
        kwargs["update_expect_tx"] = True
    cutlass_lir.TmaLoadMulticastOp(
        src.value,
        dst.value,
        mbar,
        **kwargs,
    )


@dsl_user_op
def tma_store(
    src: cute.Tensor,
    dst: cute.Tensor,
    *,
    cta_v_map: Optional[cute.Layout] = None,
    internal_type: Optional[Type[cute.Numeric]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Copies a tensor from a Buffer to a tensor pointed to by a !cute.memref.

    internal_type (optional): selects the TMA transfer's internal element encoding used by hardware.
    """

    kwargs = {
        "loc": loc,
        "ip": ip,
    }
    if cta_v_map is not None:
        kwargs["cta_v_map"] = cta_v_map.type.attribute

    # Map internal_type to tma_format per updated API
    if internal_type is not None:
        internal_mlir_ty = (
            internal_type.mlir_type
            if hasattr(internal_type, "mlir_type")
            else internal_type
        )
        kwargs["tma_format"] = _cute_nvgpu_ir.TmaDataFormat(
            _cute_nvgpu_ir.get_default_tma_format(internal_mlir_ty, False)
        )

    cutlass_lir.TmaStoreOp(src.value, dst.value, **kwargs)


@dsl_user_op
def copy(
    src: cute.Tensor,
    dst: cute.Tensor,
    *,
    copy_atom: cute.CopyAtom,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Copy a tensor from src to dst using a given copy atom.
    """
    copy_atom = ir.Attribute.parse(f"{copy_atom.type}")
    cutlass_lir.CopyOp(src.value, dst.value, copy_atom=copy_atom, loc=loc, ip=ip)
