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

from __future__ import annotations

from enum import Enum, auto
from math import log2
from typing import Optional, Union

import cutlass
import cutlass.cute as cute
from cutlass.cutlass_dsl import (
    extract_mlir_values,
    new_from_mlir_values,
)
from cutlass.utils.layout import LayoutEnum
import cutlass.utils.blackwell_helpers as sm100_utils
from cutlass.cute.nvgpu import cpasync, tcgen05

"""
This file contains common utilities for mixed-input GEMM.
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
    This method partitions the global memory and shared memory buffer for the scale tensor for TMA load.
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
) -> tuple[
    Optional[cute.TiledCopy], Optional[cute.TiledCopy], cute.Tensor, cute.Tensor
]:
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

    :rtype: tuple[Optional[cute.TiledCopy], Optional[cute.TiledCopy], cute.Tensor, cute.Tensor]
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


def epilog_gmem_copy_and_partition(
    c_dtype: type[cutlass.Numeric],
    tidx: cutlass.Int32,
    tma_atom_c: Optional[cute.CopyAtom],
    tiled_copy_t2r: Optional[cute.TiledCopy],
    gC_mnl_tma: Optional[cute.Tensor],
    gC_mnl_simt: Optional[cute.Tensor],
    epi_tile: cute.Tile,
    sC: cute.Tensor,
) -> tuple[
    Optional[cute.CopyAtom],
    Optional[cute.Tensor],
    Optional[cute.Tensor],
    Optional[cute.CopyAtom],
    Optional[cute.Tensor],
]:
    """
    Partitions source and destination tensors for a global memory store.
    This method generates a tiled copy for storing results to global memory
    and partitions the source (register or shared memory) and destination
    (global memory) tensors accordingly. If tma_atom_c is not None, then
    partition for TMA store will be performed. If tiled_copy_t2r is not None, then
    partition for SIMT store will be performed.
    :param c_dtype: The data type of the tensor C.
    :type c_dtype: type[cutlass.Numeric]
    :param tidx: The thread index in epilogue warp groups.
    :type tidx: cutlass.Int32
    :param tma_atom_c: The TMA copy atom.
    :type tma_atom_c: Optional[cute.CopyAtom]
    :param tiled_copy_t2r: The tiled copy operation for tmem to register copy.
    :type tiled_copy_t2r: Optional[cute.TiledCopy]
    :param gC_mnl_tma: The global tensor C for TMA.
    :type gC_mnl_tma: Optional[cute.Tensor]
    :param gC_mnl_simt: The global tensor C for SIMT Copy.
    :type gC_mnl_simt: Optional[cute.Tensor]
    :param epi_tile: The epilogue tiler.
    :type epi_tile: cute.Tile
    :param sC: The shared memory tensor C.
    :return: A tuple containing the appropriate copy atom and partitioned
             source and destination tensors for the store operation.
    :rtype: tuple[Optional[cute.CopyAtom], Optional[cute.Tensor], Optional[cute.Tensor], Optional[cute.CopyAtom], Optional[cute.Tensor]]
    """
    bSG_sC = None
    bSG_gC = None
    simt_atom = None
    tTR_gC = None
    if tma_atom_c is not None:
        gC_epi_tma = cute.flat_divide(
            gC_mnl_tma[((None, None), 0, 0, None, None, None)], epi_tile
        )
        # TMA store
        sC_for_tma_partition = cute.group_modes(sC, 0, 2)
        gC_for_tma_partition = cute.group_modes(gC_epi_tma, 0, 2)
        # ((ATOM_V, REST_V), EPI_M, EPI_N)
        # ((ATOM_V, REST_V), EPI_M, EPI_N, RestM, RestN, RestL)
        bSG_sC, bSG_gC = cpasync.tma_partition(
            tma_atom_c,
            0,
            cute.make_layout(1),
            sC_for_tma_partition,
            gC_for_tma_partition,
        )
    if tiled_copy_t2r is not None:
        # SIMT Store
        gC_epi_simt = cute.flat_divide(
            gC_mnl_simt[((None, None), 0, 0, None, None, None)], epi_tile
        )
        # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, RestM, RestN, RestL)
        thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
        tTR_gC = thr_copy_t2r.partition_D(gC_epi_simt)
        simt_atom = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), c_dtype)
    return tma_atom_c, bSG_sC, bSG_gC, simt_atom, tTR_gC


def epilog_smem_copy_and_partition(
    c_layout: LayoutEnum,
    c_dtype: type[cutlass.Numeric],
    acc_dtype: type[cutlass.Numeric],
    tiled_copy_t2r: cute.TiledCopy,
    tTR_rC: cute.Tensor,
    tidx: cutlass.Int32,
    sC: cute.Tensor,
) -> tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
    """
    Partitions source and destination tensors for a shared memory store.
    This method generates a tiled copy for storing results to shared memory
    and partitions the source (register) and destination (shared memory)
    tensors accordingly.
    :param c_layout: The layout of the tensor C.
    :type c_layout: LayoutEnum
    :param c_dtype: The data type of the tensor C.
    :type c_dtype: type[cutlass.Numeric]
    :param acc_dtype: The data type of the accumulator tensor.
    :type acc_dtype: type[cutlass.Numeric]
    :param tiled_copy_t2r: The tiled copy operation for tmem to register copy.
    :param tTR_rC: The partitioned accumulator tensor.
    :param tidx: The thread index in epilogue warp groups.
    :param sC: The shared memory tensor to be copied and partitioned.
    :return: A tuple containing the tiled copy for the store operation and
             the partitioned source and destination tensors.
    """
    copy_atom_r2s = sm100_utils.get_smem_store_op(
        c_layout, c_dtype, acc_dtype, tiled_copy_t2r
    )
    tiled_copy_r2s = cute.make_tiled_copy_D(copy_atom_r2s, tiled_copy_t2r)
    # (R2S, R2S_M, R2S_N, PIPE_D)
    thr_copy_r2s = tiled_copy_r2s.get_slice(tidx)
    tRS_sC = thr_copy_r2s.partition_D(sC)
    # (R2S, R2S_M, R2S_N)
    tRS_rC = tiled_copy_r2s.retile(tTR_rC)
    return tiled_copy_r2s, tRS_rC, tRS_sC


def epilog_tmem_copy_and_partition(
    cta_tile_shape_mnk: tuple[int, int, int],
    c_layout: LayoutEnum,
    c_dtype: type[cutlass.Numeric],
    acc_dtype: type[cutlass.Numeric],
    tidx: cutlass.Int32,
    tAcc: cute.Tensor,
    gC_mnl: cute.Tensor,
    epi_tile: cute.Tile,
    use_2cta_instrs: Union[cutlass.Boolean, bool],
) -> tuple[cute.TiledCopy, cute.Tensor, cute.Tensor]:
    """
    Partitions source and destination tensors for a tensor memory load.
    This method generates a tiled copy for loading accumulators from tensor
    memory and partitions the source (tensor memory) and destination
    (register) tensors accordingly.
    :param cta_tile_shape_mnk: The shape of the CTA tile (M, N, K).
    :type cta_tile_shape_mnk: tuple[int, int, int]
    :param c_layout: The layout of the tensor C.
    :type c_layout: LayoutEnum
    :param c_dtype: The data type of the tensor C.
    :type c_dtype: type[cutlass.Numeric]
    :param acc_dtype: The data type of the accumulator tensor.
    :type acc_dtype: type[cutlass.Numeric]
    :param tidx: The thread index in epilogue warp groups.
    :param tAcc: The accumulator tensor to be copied and partitioned.
    :param gC_mnl: The global tensor C.
    :param epi_tile: The epilogue tiler.
    :param use_2cta_instrs: Whether use_2cta_instrs is enabled.
    :return: A tuple containing the tiled copy for the load operation and
             the partitioned source and destination tensors.
    """
    # Make tiledCopy for tensor memory load
    copy_atom_t2r = sm100_utils.get_tmem_load_op(
        cta_tile_shape_mnk,
        c_layout,
        c_dtype,
        acc_dtype,
        epi_tile,
        use_2cta_instrs,
    )
    # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, STAGE)
    tAcc_epi = cute.flat_divide(
        tAcc[((None, None), 0, 0, None)],
        epi_tile,
    )
    # (EPI_TILE_M, EPI_TILE_N)
    tiled_copy_t2r = tcgen05.make_tmem_copy(
        copy_atom_t2r, tAcc_epi[(None, None, 0, 0, 0)]
    )
    thr_copy_t2r = tiled_copy_t2r.get_slice(tidx)
    # (T2R, T2R_M, T2R_N, EPI_M, EPI_M, STAGE)
    tTR_tAcc = thr_copy_t2r.partition_S(tAcc_epi)
    # (EPI_TILE_M, EPI_TILE_N, EPI_M, EPI_N, loopM, loopN, loopL)
    gC_mnl_epi = cute.flat_divide(
        gC_mnl[((None, None), 0, 0, None, None, None)], epi_tile
    )
    # (T2R, T2R_M, T2R_N, EPI_M, EPI_N, loopM, loopN, loopL)
    tTR_gC = thr_copy_t2r.partition_D(gC_mnl_epi)
    # (T2R, T2R_M, T2R_N)
    tTR_rAcc = cute.make_rmem_tensor(
        tTR_gC[(None, None, None, 0, 0, 0, 0, 0)].shape, acc_dtype
    )
    return tiled_copy_t2r, tTR_tAcc, tTR_rAcc


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
    assert (
        cute.size_in_bytes(a_scale_dtype, smem_layout_scale_per_stage) >= 128
    ), "smem size for scale must be at least 128B"
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


def is_shuffle_a(
    a_major: str,
    k: int,
    a_dtype: type[cutlass.Numeric],
    mma_dtype: type[cutlass.Numeric],
    scale_granularity_k: int,
) -> bool:
    # Enable shuffle on the k mode of A tensor when
    # 1) tensor a is k-major and,
    # 2) k is exactly divisible by 8 and,
    # 3) a_dtype is Int4 and mma_dtype is BFloat16 and,
    # 4) scale granularity k is greater than 8
    shuffle_a = (
        a_major == "k"
        and a_dtype == cutlass.Int4
        and k % 8 == 0
        and mma_dtype == cutlass.BFloat16
        and scale_granularity_k >= 8
    )
    return shuffle_a


def is_valid_tensor_alignment(
    m: int,
    n: int,
    k: int,
    a_dtype: type[cutlass.Numeric],
    b_dtype: type[cutlass.Numeric],
    c_dtype: type[cutlass.Numeric],
    scale_dtype: type[cutlass.Numeric],
    a_major: str,
    b_major: str,
    c_major: str,
    mma_tiler_mnk: tuple[int, int, int],
    use_2cta_instrs: bool,
    cluster_shape_mn: tuple[int, int],
    scale_granularity_m: int,
    scale_granularity_k: int,
) -> bool:
    """
    Check if the tensor alignments are valid for the given problem size and data types.
    """

    def check_contiguous_16B_alignment(dtype, is_mode0_major, tensor_shape):
        major_mode_idx = 0 if is_mode0_major else 1
        num_major_elements = tensor_shape[major_mode_idx]
        num_contiguous_elements = 16 * 8 // dtype.width
        return num_major_elements % num_contiguous_elements == 0

    if not (
        check_contiguous_16B_alignment(a_dtype, a_major == "m", (m, k))
        and check_contiguous_16B_alignment(b_dtype, b_major == "n", (n, k))
        and check_contiguous_16B_alignment(c_dtype, c_major == "m", (m, n))
        and (
            scale_granularity_k == 0
            or check_contiguous_16B_alignment(
                b_dtype, True, (m, k // scale_granularity_k)
            )
        )
    ):
        return False
    # Check if scale tensor matches the TMA load 128B alignment requirement
    cta_tile_shape_mnk = (
        mma_tiler_mnk[0] // (2 if use_2cta_instrs else 1),
        mma_tiler_mnk[1],
        mma_tiler_mnk[2],
    )
    if (
        scale_granularity_m > 0
        and (cta_tile_shape_mnk[0] // cluster_shape_mn[1] // scale_granularity_m)
        * (scale_dtype.width // 8)
        < 128
    ):
        return False
    return True


def is_valid_mma_tiler_and_cluster_shape(
    mma_tiler: tuple[int, int, int],
    cluster_shape_mn: tuple[int, int],
    use_2cta_instrs: bool,
) -> bool:
    """
    Check if the MMA tiler and cluster shape are valid for the given problem size.
    """
    if cluster_shape_mn[0] % (2 if use_2cta_instrs else 1) != 0:
        return False
    if (mma_tiler[0] // (2 if use_2cta_instrs else 1)) not in [64, 128]:
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


class ContiguousGGSearchState:
    """
    The state of group search for grouped GEMM with contiguous offsets.

    The state records the progress of the group search algorithm on one mode. It will be
    initialized once and updated in every round of group index search.

    :param last_tile_count: Number of cluster tiles before the current group
    :type last_tile_count: cutlass.Int32
    :param cur_boundary: The boundary of the current group, which is the size along the seach
                         mode before the next group
    :type cur_boundary: cutlass.Int32
    :param cur_tile_count: Number of cluster tiles searched so far
    :type cur_tile_count: cutlass.Int32
    :param cur_group_idx: The index of the current group
    :type cur_group_idx: cutlass.Int32
    :param cur_offset: The starting offset of the current group along the search mode
    :type cur_offset: cutlass.Int32
    :param cur_start: The starting offset of the current cluster tile size along the search mode
                      when group search is done
    :type cur_start: cutlass.Int32
    """

    def __init__(
        self,
        last_tile_count: cutlass.Int32,
        cur_boundary: cutlass.Int32,
        cur_tile_count: cutlass.Int32,
        cur_group_idx: cutlass.Int32,
        cur_offset: cutlass.Int32,
        cur_start: cutlass.Int32,
    ):
        self.last_tile_count = last_tile_count
        self.cur_boundary = cur_boundary
        self.cur_tile_count = cur_tile_count
        self.cur_group_idx = cur_group_idx
        self.cur_offset = cur_offset
        self.cur_start = cur_start

    def __extract_mlir_values__(self):
        values = extract_mlir_values(self.last_tile_count)
        values.extend(extract_mlir_values(self.cur_boundary))
        values.extend(extract_mlir_values(self.cur_tile_count))
        values.extend(extract_mlir_values(self.cur_group_idx))
        values.extend(extract_mlir_values(self.cur_offset))
        values.extend(extract_mlir_values(self.cur_start))
        return values

    def __new_from_mlir_values__(self, values) -> "ContiguousGGSearchState":
        last_tile_count = new_from_mlir_values(self.last_tile_count, [values[0]])
        cur_boundary = new_from_mlir_values(self.cur_boundary, [values[1]])
        cur_tile_count = new_from_mlir_values(self.cur_tile_count, [values[2]])
        cur_group_idx = new_from_mlir_values(self.cur_group_idx, [values[3]])
        cur_offset = new_from_mlir_values(self.cur_offset, [values[4]])
        cur_start = new_from_mlir_values(self.cur_start, [values[5]])
        return ContiguousGGSearchState(
            last_tile_count,
            cur_boundary,
            cur_tile_count,
            cur_group_idx,
            cur_offset,
            cur_start,
        )


def create_initial_contiguous_group_search_state() -> ContiguousGGSearchState:
    """
    Create an initial search state for grouped gemm with contiguous offsets.
    """
    return ContiguousGGSearchState(
        last_tile_count=cutlass.Int32(0),
        cur_boundary=cutlass.Int32(0),
        cur_tile_count=cutlass.Int32(0),
        cur_group_idx=cutlass.Int32(0),
        cur_offset=cutlass.Int32(0),
        cur_start=cutlass.Int32(0),
    )


class ContiguousGroupWorkTileInfo:
    """
    Tile info for grouped GEMM with contiguous offsets.
    It's constructed from the search state and contains information needed for different warps.

    :param group_count: The total number of groups
    :type group_count: int
    :param cta_coord_m: The coordinate of the current CTA tile along the M mode
    :type cta_coord_m: cutlass.Int32
    :param coord_n: The starting offset on N mode for the current CTA tile
    :type coord_n: cutlass.Int32
    :param group_idx: The index of the current group
    :type group_idx: cutlass.Int32
    :param distance_to_boundary: The distance to the boundary of the current group
    :type distance_to_boundary: cutlass.Int32
    """

    def __init__(
        self,
        group_count: int,
        cta_coord_m: cutlass.Int32,
        coord_n: cutlass.Int32,
        group_idx: cutlass.Int32,
        distance_to_boundary: cutlass.Int32,
    ):
        self.cta_coord_m = cta_coord_m
        self.coord_n = coord_n
        self.group_idx = group_idx
        self.distance_to_boundary = distance_to_boundary
        self.group_count = group_count

    def __extract_mlir_values__(self):
        values = extract_mlir_values(self.cta_coord_m)
        values.extend(extract_mlir_values(self.coord_n))
        values.extend(extract_mlir_values(self.group_idx))
        values.extend(extract_mlir_values(self.distance_to_boundary))
        return values

    def __new_from_mlir_values__(self, values):
        assert len(values) == 4
        new_cta_coord_m = new_from_mlir_values(self.cta_coord_m, [values[0]])
        new_coord_n = new_from_mlir_values(self.coord_n, [values[1]])
        new_group_idx = new_from_mlir_values(self.group_idx, [values[2]])
        new_distance_to_boundary = new_from_mlir_values(
            self.distance_to_boundary, [values[3]]
        )
        return ContiguousGroupWorkTileInfo(
            self.group_count,
            new_cta_coord_m,
            new_coord_n,
            new_group_idx,
            new_distance_to_boundary,
        )

    @property
    def is_valid_tile(self):
        return self.group_idx < self.group_count


@cute.jit
def contiguous_group_search(
    cluster_tile_shape_mnk: tuple[int, int, int],
    group_count: cutlass.Int32,
    linear_idx: cutlass.Int32,
    search_state: ContiguousGGSearchState,
    cumsum: cute.Tensor,
    search_mode: int,
) -> ContiguousGGSearchState:
    """
    Group search for contiguous grouped gemm.
    """
    not_found = linear_idx >= search_state.cur_tile_count
    next_boundary = cutlass.Int32(0)
    cur_group_idx = search_state.cur_group_idx
    cur_offset = search_state.cur_offset
    last_tile_count = search_state.last_tile_count
    cur_boundary = search_state.cur_boundary
    cur_tile_count = search_state.cur_tile_count
    if not_found:
        cur_group_idx = cur_group_idx + 1
    while not_found and cur_group_idx <= group_count:
        next_boundary = cumsum[cur_group_idx]
        num_m_blocks = cute.ceil_div(
            (next_boundary - cur_boundary),
            cluster_tile_shape_mnk[search_mode],
        )
        next_tile_count = num_m_blocks + cur_tile_count
        not_found = linear_idx >= next_tile_count

        last_tile_count = cur_tile_count
        cur_offset = cur_boundary
        cur_boundary = next_boundary
        cur_tile_count = next_tile_count
        if not_found:
            cur_group_idx = cur_group_idx + 1
    cur_start = cur_offset + cluster_tile_shape_mnk[search_mode] * (
        linear_idx - last_tile_count
    )
    return ContiguousGGSearchState(
        last_tile_count,
        cur_boundary,
        cur_tile_count,
        cur_group_idx,
        cur_offset,
        cur_start,
    )


def make_contiguous_group_work_tile_info(group_count: int, sTile_info: cute.Tensor):
    """
    Generate ContiguousGroupWorkTileInfo from tile_info tensor generated by contiguous_group_search
    """
    tile_info = cute.make_rmem_tensor(sTile_info.shape, sTile_info.element_type)
    cute.autovec_copy(sTile_info, tile_info)
    return ContiguousGroupWorkTileInfo(
        group_count, tile_info[0], tile_info[1], tile_info[2], tile_info[3]
    )


def cvt_tensor_a(
    src: cute.Tensor, dtype: type[cutlass.Numeric], shuffle: bool
) -> cute.TensorSSA:
    """
    Convert tensor src to the given data type. If shuffle is True, use shuffle intrinsic
    for int4-to-bf16 conversion.
    """
    from cutlass import CUDA_VERSION

    # shuffle is supported since CUDA 13.1
    shuffle_supported = True
    if CUDA_VERSION.major < 13 or (CUDA_VERSION == 13 and CUDA_VERSION.minor < 1):
        shuffle_supported = False
    shuffle = shuffle and shuffle_supported
    rst = src.load()
    if cutlass.const_expr(shuffle):
        # conversion with shuffle
        rst = cute.TensorSSA(
            cute.arch.cvt_i4_bf16_intrinsic(
                rst,
                cute.size(rst.shape),
                with_shuffle=True,
            ),
            rst.shape,
            dtype,
        )
    else:
        rst = rst.to(dtype)
    return rst


def store_transformed_a(
    src_a: cute.Tensor, dst_a: cute.Tensor, copy_atom_a: Optional[cute.CopyAtom]
) -> None:
    """
    Store transformed A tensor to the given destination tensor. If copy_atom_a is not None, use autovec_copy.
    """
    if cutlass.const_expr(copy_atom_a is not None):
        cute.copy(copy_atom_a, src_a, dst_a)
    else:
        cute.autovec_copy(src_a, dst_a)
