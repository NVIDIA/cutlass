# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from __future__ import annotations

from enum import Enum, auto
from math import log2
from typing import Optional, Union

import cutlass
import cutlass.cute as cute
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.nvgpu import cpasync, tcgen05
from cutlass.cute.runtime import from_dlpack

"""
This file contain common utilities for mixed-input GEMM.
"""


class TransformMode(Enum):
    """
    An enumeration for the possible transform modes of a mixed-input GEMM.
    """

    ConvertOnly = auto()
    ConvertScale = auto()


def scale_tma_partition(
    tCsS: cute.Tensor,
    tCgS: cute.Tensor,
    tma_atom_s: cute.CopyAtom,
    block_in_cluster_coord_vmnk: cute.Coord,
    scale_cta_layout: cute.Layout,
) -> tuple[cute.Tensor, cute.Tensor]:
    """
    Perform TMA partition for scale tensor.
    This method partitions the gobal memory and shared memory buffer for scale tensor for TMA load.
    :param tCsS: Input scale shared memory tensor
    :type tCsS: cute.Tensor
    :param tCgS: Input scale global memory tensor
    :type tCgS: cute.Tensor
    :param tma_atom_s: TMA copy atom for scale tensor
    :type tma_atom_s: cute.CopyAtom
    :param block_in_cluster_coord_vmnk: CTA coord in the cluster
    :type block_in_cluster_coord_vmnk: cute.Coord
    :param scale_cta_layout: Layout of CTA from the view of the scale tensor
    :type scale_cta_layout: cute.Layout
    :return: A tuple containing (tSsS, tSgS) where:

        * tSsS: Partitioned scale tensor in shared memory
        * tSgS: Partitioned scale tensor in global memory

    :rtype: tuple[cute.Tensor, cute.Tensor]
    """
    tSsS, tSgS = cpasync.tma_partition(
        tma_atom_s,
        block_in_cluster_coord_vmnk[2],
        scale_cta_layout,
        cute.group_modes(tCsS, 0, 3),
        cute.group_modes(tCgS, 0, 3),
    )
    # Add rest_v mode
    # ((atom_v, rest_v), STAGE)
    # ((atom_v, rest_v), loopM, loopK, loopL)
    tSsS = cute.make_tensor(
        tSsS.iterator,
        cute.make_layout(
            ((tSsS.layout.shape[0], 1), *tSsS.layout.shape[1:]),
            stride=(
                (tSsS.layout.stride[0], 0),
                *tSsS.layout.stride[1:],
            ),
        ),
    )
    tSgS = cute.make_tensor(
        tSgS.iterator,
        cute.make_layout(
            ((tSgS.layout.shape[0], 1), *tSgS.layout.shape[1:]),
            stride=(
                (tSgS.layout.stride[0], 0),
                *tSgS.layout.stride[1:],
            ),
        ),
    )
    return tSsS, tSgS


def transform_partition(
    transform_a_source: tcgen05.OperandSource,
    scale_mode: TransformMode,
    copy_atom_a_input: cute.CopyAtom,
    copy_atom_a_transform: cute.CopyAtom,
    sA_input: cute.Tensor,
    A_transform: cute.Tensor,
    transform_local_tidx: cutlass.Int32,
) -> tuple[cute.TiledCopy, cute.TiledCopy, cute.Tensor, cute.Tensor]:
    """
    Partition tensors for transform input and output.
    This method sets up the copy atoms and partitions the shared/tensor memory
    for the transformation of tensor A.
    :param transform_a_source: Where the transformed tensor A is stored (TMEM or SMEM)
    :type transform_a_source: tcgen05.OperandSource
    :param scale_mode: The transform mode (ConvertOnly or ConvertScale)
    :type scale_mode: TransformMode
    :param copy_atom_a_input: Copy atom for loading A from shared memory
    :type copy_atom_a_input: cute.CopyAtom
    :param copy_atom_a_transform: Copy atom for storing transformed A
    :type copy_atom_a_transform: cute.CopyAtom
    :param sA_input: Input tensor A in shared memory
    :type sA_input: cute.Tensor
    :param A_transform: Transformed tensor A in tensor or shared memory
    :type A_transform: cute.Tensor
    :param transform_local_tidx: Local thread index for transformation warps
    :type transform_local_tidx: cutlass.Int32
    :return: A tuple containing (src_copy_a, dst_copy_a, tAsA_input, tA_transform) where:

        * src_copy_a: Tiled copy for source tensor
        * dst_copy_a: Tiled copy for destination tensor
        * tAsA_input: Partitioned input tensor A
        * tA_transform: Partitioned transformed tensor A

    :rtype: tuple[cute.TiledCopy, cute.TiledCopy, cute.Tensor, cute.Tensor]
    """
    if cutlass.const_expr(transform_a_source == tcgen05.OperandSource.TMEM):
        if cutlass.const_expr(
            cute.size(A_transform, mode=[0, 0]) == 128
            and cute.size(sA_input, mode=[0, 0]) == 64
        ):
            tensor_input = cute.make_tensor(
                sA_input.iterator,
                cute.logical_product(
                    sA_input.layout,
                    ((cute.make_layout(2, stride=0), None), None, None, None),
                ),
            )
        else:
            tensor_input = sA_input
        reg2tmem_tiled_copy = tcgen05.make_tmem_copy(
            copy_atom_a_transform, A_transform[(None, None, None, 0)]
        )
        thr_reg2tmem_tiled_copy = reg2tmem_tiled_copy.get_slice(transform_local_tidx)
        partitioned_tensor_input = thr_reg2tmem_tiled_copy.partition_S(tensor_input)
        partitioned_tensor_transform = thr_reg2tmem_tiled_copy.partition_D(A_transform)
        src_copy_a = (
            cute.make_tiled_copy_S(copy_atom_a_input, reg2tmem_tiled_copy)
            if scale_mode is TransformMode.ConvertScale
            else None
        )
        dst_copy_a = reg2tmem_tiled_copy
        tAsA_input = partitioned_tensor_input
        tA_transform = partitioned_tensor_transform
    elif cutlass.const_expr(transform_a_source == tcgen05.OperandSource.SMEM):
        # Construct tiled_copy satisfying 8 contiguous elts per copy atom
        reg2smem_tiled_copy = cute.make_cotiled_copy(
            copy_atom_a_transform,
            cute.make_layout((128, 8), stride=(8, 1)),
            A_transform[(None, None, None, 0)].layout,
        )
        thr_reg2smem_tiled_copy = reg2smem_tiled_copy.get_slice(transform_local_tidx)
        partitioned_tensor_input = thr_reg2smem_tiled_copy.partition_S(sA_input)
        partitioned_tensor_transform = thr_reg2smem_tiled_copy.partition_D(A_transform)
        src_copy_a = (
            cute.make_tiled_copy_S(copy_atom_a_input, reg2smem_tiled_copy)
            if scale_mode is TransformMode.ConvertScale
            else None
        )
        # auto-vec copy is enough for copy from register to shared memory here
        dst_copy_a = None
        tAsA_input = partitioned_tensor_input
        tA_transform = partitioned_tensor_transform
    return src_copy_a, dst_copy_a, tAsA_input, tA_transform


def scale_partition(
    src_copy_a: cute.TiledCopy,
    tCsS: cute.Tensor,
    transform_local_tidx: cutlass.Int32,
    mma_dtype: type[cutlass.Numeric],
) -> tuple[cute.TiledCopy, cute.Tensor, cute.Tensor, cute.Tensor]:
    """
    Partition the scale tensor for transformation.
    This method prepares the copy atom and partitions the shared memory for the scale tensor.
    :param src_copy_a: Tiled copy for the source tensor
    :type src_copy_a: cute.TiledCopy
    :param tCsS: Scale tensor in shared memory
    :type tCsS: cute.Tensor
    :param transform_local_tidx: Local thread index for transformation warps
    :type transform_local_tidx: cutlass.Int32
    :param mma_dtype: Data type for the MMA operation
    :type mma_dtype: type[cutlass.Numeric]
    :return: A tuple containing (smem_thr_copy_S, tSsS_trans, tSrS_copy, tSrS) where:

        * smem_thr_copy_S: Tiled copy for the scale tensor
        * tSsS_trans: Partitioned scale tensor for transformation
        * tSrS_copy: Register fragment for the scale tensor
        * tSrS: View of scale tensor used for transformation computation

    :rtype: tuple[cute.TiledCopy, cute.Tensor, cute.Tensor, cute.Tensor]
    """
    smem_thr_copy_S = None
    tSsS_trans = None
    tSrS = None
    # Partition scale tensor
    smem_thr_copy_S = src_copy_a.get_slice(transform_local_tidx)
    tSsS_trans = smem_thr_copy_S.partition_S(tCsS)
    # Construct register fragment for scale tensor
    tSsS_layout_per_stage = tSsS_trans[(None, None, None, None, 0)].layout
    # tSrS for copy
    tSrS_copy = cute.make_rmem_tensor(
        cute.filter_zeros(tSsS_layout_per_stage).shape, mma_dtype
    )
    # tSrS view for transformation computation
    tSrS = cute.make_tensor(
        tSrS_copy.iterator,
        cute.make_layout(tSsS_layout_per_stage.shape, stride=tSrS_copy.layout.stride),
    )
    return smem_thr_copy_S, tSsS_trans, tSrS_copy, tSrS


def get_gmem_layout_scale(
    scale_shape_mkl: tuple[int, int, int],
    scale_granularity_m: int,
    scale_granularity_k: int,
    scale_major_mode: tcgen05.OperandMajorMode,
) -> cute.Layout:
    """
    Get the layout of the scale tensor in global memory.
    :param scale_shape_mkl: The shape of the scale tensor (M, K, L).
    :type scale_shape_mkl: tuple[int, int, int]
    :return: The layout of the scale tensor in global memory.
    :rtype: cute.Layout
    """
    m, k, l = scale_shape_mkl
    shape_scale = (
        (scale_granularity_m, cute.ceil_div(m, scale_granularity_m)),
        (scale_granularity_k, cute.ceil_div(k, scale_granularity_k)),
    )
    if cutlass.const_expr(scale_major_mode == tcgen05.OperandMajorMode.MN):
        layout_mk = cute.make_layout(
            shape_scale,
            stride=(
                (0, 1),
                (0, cute.size(shape_scale[0][1])),
            ),
        )
    else:
        layout_mk = cute.make_layout(
            shape_scale,
            stride=(
                (0, cute.size(shape_scale[1][1])),
                (0, 1),
            ),
        )
    return cute.make_layout(
        (*layout_mk.shape, l),
        stride=(*layout_mk.stride, cute.cosize(layout_mk)),
    )


def get_smem_layout_scale(
    mma_tiler: tuple[int, int, int],
    use_2cta_instrs: bool,
    scale_granularity_m: int,
    scale_granularity_k: int,
    scale_major_mode: tcgen05.OperandMajorMode,
    a_scale_dtype: type[cutlass.Numeric],
    num_scale_load2trans_stage: int,
) -> tuple[tuple[int, int], cute.ComposedLayout, cute.ComposedLayout]:
    """
    Get the layout of the scale tensor in shared memory.
    :return: A tuple containing (scale_tile_shape, smem_layout_scale_per_stage, smem_layout_scale) where:

        * scale_tile_shape: The tile shape
        * smem_layout_scale_per_stage: Shared memory layout for scale tensor per stage
        * smem_layout_scale: Shared memory layout for scale tensor

    :rtype: tuple[tuple[int, int], cute.ComposedLayout, cute.ComposedLayout]
    """
    scale_tile_shape = (
        (cute.size(mma_tiler[0]) // 2 if use_2cta_instrs else cute.size(mma_tiler[0])),
        cute.size(mma_tiler[2]),
    )
    size_mn = scale_tile_shape[0]
    size_k = scale_tile_shape[1]
    smem_size_mn = scale_granularity_m if scale_granularity_m < size_mn else size_mn
    smem_size_k = scale_granularity_k if scale_granularity_k < size_k else size_k
    div_mn = cute.ceil_div(size_mn, smem_size_mn)
    div_k = cute.ceil_div(size_k, smem_size_k)
    smem_atom_shape = (
        (smem_size_mn, div_mn),
        (smem_size_k, div_k),
    )
    if cutlass.const_expr(scale_major_mode == tcgen05.OperandMajorMode.MN):
        outer_layout = cute.make_layout(
            smem_atom_shape,
            stride=(
                (0, 1),
                (0, div_mn),
            ),
        )
    else:
        outer_layout = cute.make_layout(
            smem_atom_shape,
            stride=(
                (0, div_k),
                (0, 1),
            ),
        )
    # Apply a trivial swizzle to make it a composed layout, which could be used to construct TMA atom
    smem_layout_scale_per_stage = cute.make_composed_layout(
        cute.make_swizzle(0, 4, 3), 0, outer_layout
    )
    assert cute.rank(smem_layout_scale_per_stage) == 2, "Scale layout must be rank 2"
    assert (
        cute.size(mma_tiler[0]) % cute.size(smem_layout_scale_per_stage.outer[0]) == 0
    ), "smem_layout_scale_per_stage must equal the tile shape."
    assert (
        cute.size(mma_tiler[2]) % cute.size(smem_layout_scale_per_stage.outer[1]) == 0
    ), "smem_layout_scale_per_stage must evenly divide tile k shape."
    # Shared memory buffer for scale must be at least 128B to satisfy TMA requirement

    assert cute.size_in_bytes(a_scale_dtype, smem_layout_scale_per_stage) >= 128, (
        "smem size for scale must be at least 128B"
    )
    # Scale layout in smem with multiple stages
    smem_layout_scale = cute.append(
        smem_layout_scale_per_stage,
        cute.make_layout(
            (num_scale_load2trans_stage),
            stride=(cute.cosize(smem_layout_scale_per_stage.outer)),
        ),
    )
    return scale_tile_shape, smem_layout_scale_per_stage, smem_layout_scale


def compute_smem_layout(
    tiled_mma: cute.TiledMma,
    mma_tiler_mnk: tuple[int, int, int],
    a_dtype: type[cutlass.Numeric],
    b_dtype: type[cutlass.Numeric],
    load2trans_stage_count: int,
    trans2mma_stage_count: int,
) -> tuple[
    cute.ComposedLayout,
    cute.ComposedLayout,
    cute.ComposedLayout,
]:
    """
    Compute shared memory layouts for tensor A, transformed A and tensor B.
    :param tiled_mma: The tiled MMA object defining the core computation.
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_mnk: The shape (M, N, K) of the MMA tiler.
    :type mma_tiler_mnk: tuple[int, int, int]
    :param a_dtype: Data type of operand A.
    :type a_dtype: type[cutlass.Numeric]
    :param b_dtype: Data type of operand B.
    :type b_dtype: type[cutlass.Numeric]
    :param load2trans_stage_count: Number of stages for load-to-transform pipeline.
    :type load2trans_stage_count: int
    :param trans2mma_stage_count: Number of stages for transform-to-MMA pipeline.
    :type trans2mma_stage_count: int
    :return: A tuple containing (smem_layout_a, smem_layout_a_transform, smem_layout_b) where:

        * smem_layout_a: Shared memory layout for tensor A
        * smem_layout_a_transform: Shared memory layout for transformed tensor A
        * smem_layout_b: Shared memory layout for tensor B

    :rtype: tuple[cute.ComposedLayout, cute.ComposedLayout, cute.ComposedLayout]
    """
    smem_layout_a = sm100_utils.make_smem_layout_a(
        tiled_mma,
        mma_tiler_mnk,
        a_dtype,
        load2trans_stage_count,
    )
    smem_layout_a_transform = sm100_utils.make_smem_layout_a(
        tiled_mma,
        mma_tiler_mnk,
        tiled_mma.op.a_dtype,
        trans2mma_stage_count,
    )
    smem_layout_b = sm100_utils.make_smem_layout_b(
        tiled_mma,
        mma_tiler_mnk,
        b_dtype,
        load2trans_stage_count,
    )
    return (smem_layout_a, smem_layout_a_transform, smem_layout_b)


def get_transform_a_source(
    a_major_mode: tcgen05.OperandMajorMode,
) -> tcgen05.OperandSource:
    """
    Determine the operand source for transformed A tensor based on the operand major mode.
    """
    if cutlass.const_expr(a_major_mode == tcgen05.OperandMajorMode.K):
        return tcgen05.OperandSource.TMEM
    else:
        return tcgen05.OperandSource.SMEM


def get_tma_atom_kind(
    mcast: cutlass.Boolean,
    use_2cta_instrs: bool,
    is_b: bool,
) -> Union[cpasync.CopyBulkTensorTileG2SMulticastOp, cpasync.CopyBulkTensorTileG2SOp]:
    """
    Get the TMA atom kind based on 1) whether it's a multicast operation,
    2) whether 2CTA tcgen05.mma instruction is enabled, and
    3) whether it's a B tensor
    """
    # Not using .2CTA instructions for tensor A as the consumer is threads on different CTAs
    cta_group = (
        tcgen05.CtaGroup.TWO if (use_2cta_instrs and is_b) else tcgen05.CtaGroup.ONE
    )
    if cutlass.const_expr(mcast):
        return cpasync.CopyBulkTensorTileG2SMulticastOp(cta_group)
    return cpasync.CopyBulkTensorTileG2SOp(cta_group)


def get_copy_atom_a_transform(
    mma_dtype: type[cutlass.Numeric],
    use_2cta_instrs: bool,
    transform_a_source: tcgen05.OperandSource,
    a_smem_shape: cute.Shape,
    a_dtype: type[cutlass.Numeric],
) -> cute.CopyAtom:
    """
    Determine the copy atom for transformed A tensor based on the operand source and tile size.
    """
    if cutlass.const_expr(transform_a_source == tcgen05.OperandSource.TMEM):
        if cutlass.const_expr(
            cute.size(a_smem_shape[0][0]) == 64 and (not use_2cta_instrs)
        ):
            copy_op_r2t = tcgen05.St16x256bOp(
                tcgen05.Repetition(1), tcgen05.Unpack.NONE
            )
        else:
            copy_op_r2t = tcgen05.St32x32bOp(tcgen05.Repetition(8), tcgen05.Unpack.NONE)
        return cute.make_copy_atom(copy_op_r2t, mma_dtype)
    else:
        return cute.make_copy_atom(
            cute.nvgpu.CopyUniversalOp(), a_dtype, num_bits_per_copy=32
        )


def is_valid_scale_granularity(
    scale_granularity_m: int,
    scale_granularity_k: int,
    a_dtype: type[cutlass.Numeric],
    k: int,
    mma_tiler_k: int,
) -> bool:
    """
    Check if the scale granularity settings are valid for the given data type and problem size.
    """
    if a_dtype.width == 8:
        # No scale tensor for 8bit data type A
        if not (scale_granularity_m == 0 and scale_granularity_k == 0):
            return False
    elif a_dtype.width == 4:
        if scale_granularity_m != 1 or (
            scale_granularity_k == 0
            or k % scale_granularity_k != 0
            or scale_granularity_k % mma_tiler_k != 0
        ):
            return False
    return True


def get_divisibility(contiguous_dim_size: int, upper_bound: int = 128) -> int:
    """
    Calculate the largest power of 2 divisibility factor for memory alignment.
    """
    # Check the largest power of 2 factor of contiguous_dim_size
    for i in range(int(log2(contiguous_dim_size)), 0, -1):
        if contiguous_dim_size % (2**i) == 0:
            return min(2**i, upper_bound)
    return 1
