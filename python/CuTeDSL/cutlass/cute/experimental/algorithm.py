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

from cutlass import cute
from cutlass.cutlass_dsl import dsl_user_op
from cutlass._mlir.dialects import lir as cutlass_lir

from .memory import copy


@dsl_user_op
def simt_auto_vec_copy(
    src: cute.Tensor, dst: cute.Tensor, async_op=False, loc=None, ip=None
):
    """
    Copies a tensor between two cute.memref buffers with single thread.

    :param src: Source tensor
    :type src: cute.Tensor
    :param dst: Destination tensor
    :type dst: cute.Tensor
    :param async_op: Whether to use asynchronous operation, defaults to False
    :type async_op: bool, optional
    """
    if async_op:
        cutlass_lir.SimtAutoVecCopyOp(
            src.value, dst.value, async_=True, cache="always", loc=loc, ip=ip
        )
    else:
        cutlass_lir.SimtAutoVecCopyOp(src.value, dst.value, loc=loc, ip=ip)


@dsl_user_op
def partition(
    buffer: cute.Tensor, agent_id: cute.Int32, *, layout_tv, tiler, loc=None, ip=None
) -> cute.Tensor:
    """
    Partition a buffer into a given layout and tiler.

    :param buffer: Buffer to partition
    :type buffer: cute.Tensor
    :param agent_id: Agent ID
    :type agent_id: cute.Int32
    :param layout_tv: Layout tensor
    :type layout_tv: cute.Tensor
    :param tiler: Tiler
    :type tiler: cute.Tensor
    """
    assert isinstance(agent_id, cute.Int32), (
        f"Expected agent_id to be cute.Int32, got {type(agent_id)}"
    )
    partition_op = cutlass_lir.PartitionOp(
        buffer.value,
        agent_id.ir_value(),
        layout_tv=layout_tv.type.attribute,
        tiler=tiler.type.attribute,
        loc=loc,
        ip=ip,
    )
    return partition_op.result


@dsl_user_op
def partition_and_copy(
    tiled_copy: cute.core.ThrCopy,
    src: cute.Tensor,
    dst: cute.Tensor,
    *,
    loc=None,
    ip=None,
):
    """
    Copies a tensor between two cute.memref buffer

    :param tiled_copy: Tiled copy
    :type tiled_copy: cute.core.ThrCopy
    :param src: Source tensor
    :type src: cute.Tensor
    :param dst: Destination tensor
    :type dst: cute.Tensor
    """
    src_partitioned = src
    dst_partitioned = dst
    tid_x = tiled_copy.thr_idx
    if src.memspace != cute.AddressSpace.rmem:
        src_partitioned = partition(
            src,
            tid_x,
            layout_tv=tiled_copy.layout_src_tv_tiled,
            tiler=cute.core._pack_tile(tiled_copy.tiler_mn),
        )
    if dst.memspace != cute.AddressSpace.rmem:
        dst_partitioned = partition(
            dst,
            tid_x,
            layout_tv=tiled_copy.layout_dst_tv_tiled,
            tiler=cute.core._pack_tile(tiled_copy.tiler_mn),
        )

    # Handle copy where copy atom is used for both partition and copy during smem to rmem and rmem to smem copies
    if type(tiled_copy.op) in [
        cute.nvgpu.warp.LdMatrix8x8x16bOp,
        cute.nvgpu.warp.LdMatrix16x16x8bOp,
        cute.nvgpu.warp.StMatrix8x8x16bOp,
        cute.nvgpu.warp.StMatrix16x8x8bOp,
    ]:
        copy(
            src_partitioned,
            dst_partitioned,
            copy_atom=tiled_copy,
            loc=loc,
            ip=ip,
        )

    # The rest handles copy where copy atom is used for partition
    elif (
        src.memspace,
        dst.memspace,
    ) in [
        (cute.AddressSpace.rmem, cute.AddressSpace.smem),
        (cute.AddressSpace.smem, cute.AddressSpace.rmem),
        (cute.AddressSpace.rmem, cute.AddressSpace.gmem),
        (cute.AddressSpace.gmem, cute.AddressSpace.rmem),
    ]:
        simt_auto_vec_copy(src_partitioned, dst_partitioned, loc=loc, ip=ip)
    elif (
        src.memspace == cute.AddressSpace.gmem
        and dst.memspace == cute.AddressSpace.smem
    ):
        simt_auto_vec_copy(
            src_partitioned, dst_partitioned, async_op=True, loc=loc, ip=ip
        )

    # Handle copy where copy atom is used for partition and copy
    else:
        copy(
            src_partitioned,
            dst_partitioned,
            copy_atom=tiled_copy,
            loc=loc,
            ip=ip,
        )
