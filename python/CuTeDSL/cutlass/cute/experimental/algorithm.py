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

from cutlass import AddressSpace
from typing import Callable, Optional

from cutlass import cute
from cutlass.cutlass_dsl import dsl_user_op
from cutlass._mlir import ir
from cutlass._mlir.dialects import lir as cutlass_lir
from cutlass._mlir.dialects.core import OperationTypeEnum
from cutlass._mlir.dialects.core import ReductionKind as CoreReductionKind

from .memory import copy


@dsl_user_op
def simt_auto_vec_copy(
    src: cute.Tensor,
    dst: cute.Tensor,
    async_op: bool = False,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Copies a tensor between two cute.memref buffers with single thread
    """
    if async_op:
        cutlass_lir.SimtAutoVecCopyOp(
            src.value, dst.value, async_=True, cache="always", loc=loc, ip=ip
        )
    else:
        cutlass_lir.SimtAutoVecCopyOp(src.value, dst.value, loc=loc, ip=ip)


@dsl_user_op
def partition(
    buffer: cute.Tensor,
    agent_id: cute.Int32,
    *,
    layout_tv: cute.Layout,
    tiler: Optional[cute.Tiler] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Tensor:
    """
    Partition a buffer with a thread-value layout and an optional tiler.

    ``tiler`` accepts the same public tiling forms as other CuTe operations,
    including tuples such as ``(128, 64)``. When omitted, ``layout_tv`` fully
    describes the partition.

    :raises AssertionError: If ``agent_id`` is not a ``cute.Int32`` value.
    :raises ValueError: If a non-``None`` public ``tiler`` form contains leaves
        other than integers, layouts, or ``None``.
    """
    assert isinstance(agent_id, cute.Int32), (
        f"Expected agent_id to be cute.Int32, got {type(agent_id)}"
    )
    tiler_attr = None
    if tiler is not None:
        if isinstance(tiler, ir.Value):
            # Preserve compatibility with callers that pre-packed the tiler.
            tiler_attr = tiler.type.attribute
        else:
            tiler_attr = cute.core._pack_tile(tiler, loc=loc, ip=ip).type.attribute

    partition_op = cutlass_lir.PartitionOp(
        buffer.value,
        agent_id.ir_value(),
        layout_tv=layout_tv.type.attribute,
        tiler=tiler_attr,
        loc=loc,
        ip=ip,
    )
    return partition_op.result


@dsl_user_op
def partition_and_copy(
    tiled_copy: cute.ThrCopy,
    src: cute.Tensor,
    dst: cute.Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Partitions ``src`` / ``dst`` with ``tiled_copy`` and issues the copy.

    Non-register operands are partitioned with the tiled copy's TV layouts and
    tiler; register operands are left as-is. For a broadcasting SMEM to TMEM
    copy, SMEM is first rewritten by ``tcgen05.append_s2t_broadcast_mode`` so
    its MMA mode matches the TMEM-derived tiler. The SMEM descriptor such a copy
    needs is materialized when the copy is lowered.
    """
    src_partitioned = src
    dst_partitioned = dst
    tid_x = tiled_copy.thr_idx
    if src.memspace != AddressSpace.rmem:
        src_to_partition = src
        if src.memspace == AddressSpace.smem and dst.memspace == AddressSpace.tmem:
            src_to_partition = cute.nvgpu.tcgen05.append_s2t_broadcast_mode(
                tiled_copy.op, src, loc=loc, ip=ip
            )
        src_partitioned = partition(
            src_to_partition,
            tid_x,
            layout_tv=tiled_copy.layout_src_tv_tiled,
            tiler=cute.core._pack_tile(tiled_copy.tiler_mn),
        )
    if dst.memspace != AddressSpace.rmem:
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
        (AddressSpace.rmem, AddressSpace.smem),
        (AddressSpace.smem, AddressSpace.rmem),
        (AddressSpace.rmem, AddressSpace.gmem),
        (AddressSpace.gmem, AddressSpace.rmem),
    ]:
        simt_auto_vec_copy(src_partitioned, dst_partitioned, loc=loc, ip=ip)
    elif src.memspace == AddressSpace.gmem and dst.memspace == AddressSpace.smem:
        simt_auto_vec_copy(
            src_partitioned, dst_partitioned, async_op=True, loc=loc, ip=ip
        )

    # Handle copy where copy atom is used for partition and copy
    else:
        copy(
            src_partitioned,
            dst_partitioned,
            copy_atom=cute.make_copy_atom(tiled_copy.op, src.element_type),
            loc=loc,
            ip=ip,
        )


@dsl_user_op
def predicated_tensor_origin(
    tensor: cute.Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Tensor:
    """
    Marks `tensor` as the origin (root) for predication/TMA bounds.

    This is a semantic marker that lets the compiler unambiguously choose which
    `!cute.memref` shape is used as the `predBounds` origin when automatically
    constructing predicate tensors for OOB masking.
    """
    return cutlass_lir.PredicatedTensorOriginOp(tensor.value, loc=loc, ip=ip).result


@dsl_user_op
def warp_reduce(
    input: cute.Tensor,
    output: cute.Tensor,
    reduction_t_map: cute.Layout,
    intra_warp_reduce_type: OperationTypeEnum,
    body: Callable,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Performs warp-level reduction with custom binary operation specified by the body.

    :param input: The input tensor
    :type input: cute.Tensor

    :param output: The output tensor reduction result is stored at
    :type output: cute.Tensor

    :param reduction_t_map: Maps the physical lane index in warp to the logical lane index within each reduction. Domain size must be 32.
    For instance, 32:1 means all threads participate in the same reduction, (8,4):(1,0) represents 4 independent reductions between threads 0-7, 8-15, 16-23, and 24-31.
    :type reduction_t_map: cute.Layout

    :param intra_warp_reduce_type: Specifies the warp-level reduction type. The following values are supported:
    - `REDUCE_DOWN_SHUFFLE`: shuffle down based reduction. It reduces the data from numThr x fragSize
      to frgSize, all threads hold a replica of the result.
    - `REDUCE_SWAP_SHUFFLE`: swap shuffle based reduction. It reduces the data from numThr x (numThr x fragSize)
      to numThr x fragSize, where each thread holds fragSize data.
    :type intra_warp_reduce_type: OperationTypeEnum

    :param body: The binary operation to perform on the input and output tensors
    :type body: Callable
    """
    intra_warp_reduce_type_attr = ir.Attribute.parse(
        f"#core.operation_type<value={intra_warp_reduce_type}>"
    )
    warp_reduce_op = cutlass_lir.WarpReduceOp(
        input.value,
        output.value,
        reduction_t_map=reduction_t_map.type.attribute,
        intra_warp_reduce_type=intra_warp_reduce_type_attr,
        loc=loc,
        ip=ip,
    )

    # Create the block in the warp_reduce_op
    block_arg_types = [input.type.value_type, output.type.value_type]  # type: ignore[attr-defined]
    entry = ir.Block.create_at_start(warp_reduce_op.regions[0], block_arg_types)
    with ir.InsertionPoint(entry):
        args = entry.arguments
        output = body(args[0], args[1])
        yield_op = cutlass_lir.YieldOp([output], loc=loc, ip=ip)


@dsl_user_op
def elementwise(
    inputs: list[cute.Tensor],
    outputs: list[cute.Tensor],
    body: Callable,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Performs element-wise operation between tensors.
    """
    elementwise_op = cutlass_lir.ElementwiseOp(
        inputs=[input.value for input in inputs],
        outputs=[output.value for output in outputs],
        loc=loc,
        ip=ip,
    )

    # Create the block in the elementwise_op
    block_arg_types = [input.type.value_type for input in inputs] + [  # type: ignore[attr-defined]
        output.type.value_type  # type: ignore[attr-defined]
        for output in outputs
    ]
    entry = ir.Block.create_at_start(elementwise_op.regions[0], block_arg_types)
    with ir.InsertionPoint(entry):
        args = entry.arguments
        output = body(args)
        yield_op = cutlass_lir.YieldOp([output], loc=loc, ip=ip)


@dsl_user_op
def accumulate(
    src: cute.Tensor,
    dst: cute.Tensor,
    *,
    reduction_kind: Optional[CoreReductionKind] = None,
    body: Optional[Callable] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Reduces `src` element-wise into `dst`, both `!cute.memref` buffers.

    `src` and `dst` must have the same element type and the same total size.
    Their shapes need not be congruent: the op walks a single linear coordinate
    over each view's domain, so only the sizes have to agree.

    The reduction combiner is specified in exactly one of two mutually
    exclusive ways -- passing both or neither raises.

    :param src: The tensor to reduce from
    :type src: cute.Tensor

    :param dst: The tensor to reduce into
    :type dst: cute.Tensor

    :param reduction_kind: Built-in shorthand for a common element-wise
    reduction (`ADD`, `MIN`, `MAX`, `INC`, `DEC`, `AND`, `OR`, `XOR`). Use
    `ReductionKind.<X>` from `cutlass._mlir.dialects.core` -- note this is the
    Core dialect enum, not the TMA-specific `cute.ReductionKind`. Mutually
    exclusive with `body`.
    :type reduction_kind: Optional[CoreReductionKind]

    :param body: The binary combiner to apply, called as
    `body(in_elem, out_elem)` where `in_elem` is the current `src` element and
    `out_elem` the current `dst` element, returning the updated value.
    Mutually exclusive with `reduction_kind`.
    :type body: Optional[Callable]

    :raises ValueError: If both or neither of `reduction_kind` and `body` are
    provided

    Note that the predication operands (`coordTensor`/`predBounds`) are not
    exposed here: they are injected by the `lir-predication-rewrite` pass when
    the destination tile is partially out of bounds.
    """
    if (reduction_kind is None) == (body is None):
        raise ValueError(
            "accumulate expects exactly one of `reduction_kind` or `body`, but got "
            f"reduction_kind={reduction_kind!r} and body={body!r}"
        )

    if reduction_kind is not None:
        cutlass_lir.AccumulateOp(
            src.value, dst.value, reduction_kind=reduction_kind, loc=loc, ip=ip
        )
        return

    assert body is not None
    accumulate_op = cutlass_lir.AccumulateOp(src.value, dst.value, loc=loc, ip=ip)

    # Both combiner arguments must carry the src element type, so derive the
    # dst-side argument from `src` too rather than from `dst`.
    elem_type = src.type.value_type  # type: ignore[attr-defined]
    entry = ir.Block.create_at_start(accumulate_op.regions[0], [elem_type, elem_type])
    with ir.InsertionPoint(entry):
        args = entry.arguments
        cutlass_lir.YieldOp([body(args[0], args[1])], loc=loc)
