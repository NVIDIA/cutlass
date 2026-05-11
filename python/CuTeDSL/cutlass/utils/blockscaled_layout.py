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

from dataclasses import dataclass, field
from typing import Optional

from cutlass.cutlass_dsl import dsl_user_op

import cutlass.cute as cute
from cutlass.cute.nvgpu import OperandMajorMode

from cutlass._mlir import ir
import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir


@dataclass(frozen=True)
class BlockScaledBasicChunk:
    """
    The basic scale factor atom layout decided by tcgen05 BlockScaled MMA Ops.

    This class represents the fixed layout pattern for scale factors used in
    tcgen05 BlockScaled MMA Ops. The layout is determined by the
    instruction specification and cannot be modified.
    See `PTX documentation <https://docs.nvidia.com/cuda/parallel-thread-execution/#tcgen05-mma-scale-factor-a-layout-1x>`.
    """

    sf_vec_size: int
    major_mode: OperandMajorMode = OperandMajorMode.K
    _layout: cute.Layout = field(init=False, repr=False)

    def __post_init__(self) -> None:
        if self.major_mode == OperandMajorMode.K:
            # K-major layout: (AtomMN, AtomK)
            atom_shape = ((32, 4), (self.sf_vec_size, 4))
            atom_stride = ((16, 4), (0, 1))
        else:
            # MN-major layout: (AtomK, AtomMN)
            atom_shape = ((self.sf_vec_size, 4), (32, 4))
            atom_stride = ((0, 1), (16, 4))

        object.__setattr__(
            self, "_layout", cute.make_layout(atom_shape, stride=atom_stride)
        )

    @property
    def layout(self) -> cute.Layout:
        """
        Get the layout for this block scaled chunk.

        :return: The layout representing the scale factor atom
        :rtype: cute.Layout
        """
        return self._layout


@dsl_user_op
def tile_atom_to_shape_SF(
    Shape: cute.Shape,
    sf_vec_size: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """
    A helper function to get dynamic SFA/SFB layout by filling dynamic A/B shape to the scale factor atom layout.

    :param Shape: The shape of the A/B tensor
    :param sf_vec_size: Scale factor vector size

    :return: The layout of the SFA/SFB tensor
    :rtype: cute.Layout
    """
    # ((Atom_MN, Rest_MN),(Atom_K, Rest_K),RestL)
    sf_layout = cute.tile_to_shape(
        BlockScaledBasicChunk(sf_vec_size).layout, Shape, (2, 1, 3)
    )
    return sf_layout


@dsl_user_op
def make_smem_layout_sf(
    tile_shape: cute.Tile,
    sf_vec_size: int,
    num_stages: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """
    A helper function to get dynamic SFA/SFB layout by filling dynamic A/B shape to the scale factor atom layout.

    :param Shape: The shape of the A/B tensor
    :param sf_vec_size: Scale factor vector size
    :param num_stages: Number of stages

    :return: The layout of the SFA/SFB tensor
    :rtype: cute.Layout
    """

    smem_layout = cute.tile_to_shape(
        BlockScaledBasicChunk(sf_vec_size).layout,
        tile_shape,  # type: ignore[arg-type]
        (2, 1),
        loc=loc,
        ip=ip,
    )
    smem_layout_staged = cute.append(
        smem_layout,
        cute.make_layout(
            num_stages,
            stride=cute.cosize(cute.filter_zeros(smem_layout)),
            loc=loc,
            ip=ip,
        ),
        loc=loc,
        ip=ip,
    )
    return smem_layout_staged


@dsl_user_op
def make_smem_layout_sfa(
    tiled_mma: cute.TiledMma,
    mma_tiler_mnk: cute.Tile,
    sf_vec_size: int,
    num_stages: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """
    Make smem layout for SFA based on:

    1. BlockScaledBasicChunk
    2. MMA tiler shape
    3. Scale factor vector size
    4. Number of stages

    :param tiled_mma: The tiled MMA
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_mnk: The mma tiler shape
    :type mma_tiler_mnk: cute.Tile
    :param sf_vec_size: The scale factor vector size
    :type sf_vec_size: int
    :param num_stages: The number of stages
    :type num_stages: int

    :return: Smem layout for SFA
    :rtype: cute.Layout
    """
    # (CTA_Tile_Shape_M, MMA_Tile_Shape_K)
    sfa_tile_shape = (
        mma_tiler_mnk[0] // cute.size(tiled_mma.thr_id.shape),  # type: ignore[index]
        mma_tiler_mnk[2],  # type: ignore[index]
    )

    # ((Atom_M, Rest_M),(Atom_K, Rest_K))
    smem_layout = cute.tile_to_shape(
        BlockScaledBasicChunk(sf_vec_size).layout,
        sfa_tile_shape,  # type: ignore[arg-type]
        (2, 1),
    )

    # Number of MMA instructions to cover all k-tiles
    mma_tile_inst_m = mma_tiler_mnk[0] // cute.size(tiled_mma.shape_mnk, mode=[0])  # type: ignore[index]
    mma_tile_inst_k = mma_tiler_mnk[2] // cute.size(tiled_mma.shape_mnk, mode=[2])  # type: ignore[index]

    # (CTA_Tile_Shape_M, MMA_Inst_Shape_K)
    sfa_tile_shape = cute.shape_div(sfa_tile_shape, (mma_tile_inst_m, mma_tile_inst_k))
    # ((Atom_Inst_M, Atom_Inst_K), MMA_M, MMA_K))
    smem_layout = cute.tiled_divide(smem_layout, sfa_tile_shape)

    atom_m = 128
    tiler_inst = ((atom_m, sf_vec_size),)
    # (((Atom_Inst_M, Rest_M),(Atom_Inst_K, Rest_K)), MMA_M, MMA_K)
    smem_layout = cute.logical_divide(smem_layout, tiler_inst)

    # (((Atom_Inst_M, Rest_M),(Atom_Inst_K, Rest_K)), MMA_M, MMA_K, STAGE)
    sfa_smem_layout_staged = cute.append(
        smem_layout,
        cute.make_layout(
            num_stages, stride=cute.cosize(cute.filter_zeros(smem_layout))
        ),
    )

    return sfa_smem_layout_staged


@dsl_user_op
def make_smem_layout_sfb(
    tiled_mma: cute.TiledMma,
    mma_tiler_mnk: cute.Tile,
    sf_vec_size: int,
    num_stages: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """
    Make smem layout for SFB based on:

    1. BlockScaledBasicChunk
    2. MMA tiler shape
    3. Scale factor vector size
    4. Number of stages

    :param tiled_mma: The tiled MMA
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_mnk: The mma tiler shape
    :type mma_tiler_mnk: cute.Tile
    :param sf_vec_size: The scale factor vector size
    :type sf_vec_size: int
    :param num_stages: The number of stages
    :type num_stages: int

    :return: Smem layout for SFA
    :rtype: cute.Layout
    """
    # (Round_Up(CTA_Tile_Shape_N, 128), MMA_Tile_Shape_K)
    sfb_tile_shape = (
        cute.round_up(mma_tiler_mnk[1], 128),  # type: ignore[index, arg-type]
        mma_tiler_mnk[2],  # type: ignore[index]
    )

    # ((Atom_N, Rest_N),(Atom_K, Rest_K))
    smem_layout = cute.tile_to_shape(
        BlockScaledBasicChunk(sf_vec_size).layout,
        sfb_tile_shape,  # type: ignore[arg-type]
        (2, 1),
    )

    # Number of MMA instructions to cover all k-tiles
    mma_tile_inst_n = mma_tiler_mnk[1] // cute.size(tiled_mma.shape_mnk, mode=[1])  # type: ignore[index]
    mma_tile_inst_k = mma_tiler_mnk[2] // cute.size(tiled_mma.shape_mnk, mode=[2])  # type: ignore[index]

    # (CTA_Tile_Shape_N, MMA_Inst_Shape_K)
    sfb_tile_shape = cute.shape_div(sfb_tile_shape, (mma_tile_inst_n, mma_tile_inst_k))
    # ((Atom_Inst_N, Atom_Inst_K), MMA_N, MMA_K)
    smem_layout = cute.tiled_divide(smem_layout, sfb_tile_shape)

    atom_n = 128
    tiler_inst = ((atom_n, sf_vec_size),)
    # (((Atom_Inst_M, Rest_M),(Atom_Inst_K, Rest_K)), MMA_M, MMA_K)
    smem_layout = cute.logical_divide(smem_layout, tiler_inst)

    # (((Atom_Inst_M, Rest_M),(Atom_Inst_K, Rest_K)), MMA_M, MMA_K, STAGE)
    sfb_smem_layout_staged = cute.append(
        smem_layout,
        cute.make_layout(
            num_stages, stride=cute.cosize(cute.filter_zeros(smem_layout))
        ),
    )

    return sfb_smem_layout_staged


@dsl_user_op
def sm120_make_smem_layout_sfa(
    tiled_mma: cute.TiledMma,
    tile_shape_mnk: cute.Tile,
    sf_vec_size: int,
    num_stages: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """
    Make smem layout for SFA based on:
    1. BlockScaledBasicChunk
    2. MMA tiler shape
    3. Scale factor vector size
    4. Number of stages

    :param tiled_mma: The tiled MMA
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_mnk: The mma tiler shape
    :type mma_tiler_mnk: cute.Tile
    :param sf_vec_size: The scale factor vector size
    :type sf_vec_size: int
    :param num_stages: The number of stages
    :type num_stages: int

    :return: Smem layout for SFA
    :rtype: cute.Layout
    """

    assert sf_vec_size == 16 or sf_vec_size == 32, "sf_vec_size must be 16 or 32"

    blk_mn = 128
    blk_sf = 4
    blk_elems = blk_mn * blk_sf
    mma_nsf = tiled_mma.shape_mnk[2] // sf_vec_size

    mn_basic_block_shape = (32, 4)
    mn_basic_block_stride = (16, 4)
    k_basic_block_shape = (sf_vec_size, mma_nsf)
    k_basic_block_stride = (0, 1)

    assert tile_shape_mnk[0] % blk_mn == 0, (  # type: ignore[index, operator]
        "tile_shape_mnk[0] must be divisible by blk_mn"
    )

    sSFA_shapeM = (mn_basic_block_shape, tile_shape_mnk[0] // blk_mn)  # type: ignore[index, operator]
    sSF_strideM = (mn_basic_block_stride, blk_elems)

    assert tile_shape_mnk[2] % (blk_sf * mma_nsf) == 0, (  # type: ignore[index]
        "tile_shape_mnk[2] must be divisible by blk_sf * mma_nsf"
    )

    sSFA_shapeK = (
        k_basic_block_shape,
        blk_sf // mma_nsf,
        tile_shape_mnk[2] // sf_vec_size // blk_sf,  # type: ignore[index, operator]
    )
    sSF_strideK = (
        k_basic_block_stride,
        mma_nsf,
        tile_shape_mnk[0] // blk_mn * blk_elems,  # type: ignore[index, operator]
    )

    sSFA_shape = (sSFA_shapeM, sSFA_shapeK)
    sSFA_stride = (sSF_strideM, sSF_strideK)

    smem_layout = cute.make_layout(sSFA_shape, stride=sSFA_stride)

    # (((Atom_Inst_M, Rest_M),(Atom_Inst_K, Rest_K)), MMA_M, MMA_K, STAGE)
    sfa_smem_layout_staged = cute.append(
        smem_layout,
        cute.make_layout(
            num_stages, stride=cute.cosize(cute.filter_zeros(smem_layout))
        ),
    )

    return sfa_smem_layout_staged


@dsl_user_op
def sm120_make_smem_layout_sfb(
    tiled_mma: cute.TiledMma,
    tile_shape_mnk: cute.Tile,
    sf_vec_size: int,
    num_stages: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """
    Make smem layout for SFB based on:
    1. BlockScaledBasicChunk
    2. MMA tiler shape
    3. Scale factor vector size
    4. Number of stages

    :param tiled_mma: The tiled MMA
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_mnk: The mma tiler shape
    :type mma_tiler_mnk: cute.Tile
    :param sf_vec_size: The scale factor vector size
    :type sf_vec_size: int
    :param num_stages: The number of stages
    :type num_stages: int

    :return: Smem layout for SFA
    :rtype: cute.Layout
    """

    # A single indivisible block will hold 4 scale factors of 128 rows/columns (A/B matrix).
    # 4 is chosen to make consecutive 32bits of data to have scale factors for only a single row(col).
    blk_mn = 128
    blk_sf = 4
    blk_elems = blk_mn * blk_sf

    assert sf_vec_size == 16 or sf_vec_size == 32, "sf_vec_size must be 16 or 32"

    assert tile_shape_mnk[1] % blk_mn == 0, (  # type: ignore[index, operator]
        "tile_shape_mnk[1] must be divisible by blk_mn"
    )

    assert tile_shape_mnk[2] % sf_vec_size == 0, (  # type: ignore[index, operator]
        "tile_shape_mnk[2] must be divisible by sf_vec_size"
    )

    mma_nsf = tiled_mma.shape_mnk[2] // sf_vec_size

    mn_basic_block_shape = (32, 4)
    mn_basic_block_stride = (16, 4)
    k_basic_block_shape = (sf_vec_size, mma_nsf)
    k_basic_block_stride = (0, 1)

    assert tile_shape_mnk[1] % blk_mn == 0, (  # type: ignore[index, operator]
        "tile_shape_mnk[1] must be divisible by blk_mn"
    )

    sSFA_shapeN = (mn_basic_block_shape, tile_shape_mnk[1] // blk_mn)  # type: ignore[index, operator]
    sSF_strideN = (mn_basic_block_stride, blk_elems)

    assert tile_shape_mnk[2] % (blk_sf * mma_nsf) == 0, (  # type: ignore[index]
        "tile_shape_mnk[2] must be divisible by blk_sf * mma_nsf"
    )

    sSFA_shapeK = (
        k_basic_block_shape,
        blk_sf // mma_nsf,
        tile_shape_mnk[2] // sf_vec_size // blk_sf,  # type: ignore[index, operator]
    )
    sSF_strideK = (
        k_basic_block_stride,
        mma_nsf,
        tile_shape_mnk[1] // blk_mn * blk_elems,  # type: ignore[index, operator]
    )

    sSFA_shape = (sSFA_shapeN, sSFA_shapeK)
    sSFA_stride = (sSF_strideN, sSF_strideK)

    smem_layout = cute.make_layout(sSFA_shape, stride=sSFA_stride)

    # (((Atom_Inst_M, Rest_M),(Atom_Inst_K, Rest_K)), MMA_M, MMA_K, STAGE)
    sfb_smem_layout_staged = cute.append(
        smem_layout,
        cute.make_layout(
            num_stages, stride=cute.cosize(cute.filter_zeros(smem_layout))
        ),
    )

    return sfb_smem_layout_staged


@dsl_user_op
def make_tmem_layout_sfa(
    tiled_mma: cute.TiledMma,
    mma_tiler_mnk: cute.Tile,
    sf_vec_size: int,
    smem_layout: cute.Layout,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Make tmem layout for SFA based on:

    1. SFA smem layout per stage
    2. Cta tile shape m
    3. tiled MMA atom thr size
    4. Scale factor vector size

    :param tiled_mma: The tiled MMA
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_mnk: The mma tiler shape
    :type mma_tiler_mnk: cute.Tile
    :param sf_vec_size: The scale factor vector size
    :type sf_vec_size: int
    :param smem_layout: The smem layout of SFA per stage
    :type smem_layout: cute.Layout

    :return: TMEM layout for SFA
    :rtype: cute.Layout
    """
    atom_thr_size = cute.size(tiled_mma.thr_id.shape, loc=loc, ip=ip)
    cta_tile_shape_m = mma_tiler_mnk[0] // atom_thr_size  # type: ignore[index]

    sfa_layout_ty = _cute_nvgpu_ir.make_tmem_layout_sfa(
        smem_layout, cta_tile_shape_m, atom_thr_size, sf_vec_size
    )
    return _cute_ir.static(sfa_layout_ty, loc=loc, ip=ip)


@dsl_user_op
def make_tmem_layout_sfb(
    tiled_mma: cute.TiledMma,
    mma_tiler_mnk: cute.Tile,
    sf_vec_size: int,
    smem_layout: cute.Layout,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Make tmem layout for SFB based on:

    1. SFB smem layout per stage
    2. Cta tile shape m
    3. tiled MMA atom thr size
    4. Scale factor vector size

    :param tiled_mma: The tiled MMA
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_mnk: The mma tiler shape
    :type mma_tiler_mnk: cute.Tile
    :param sf_vec_size: The scale factor vector size
    :type sf_vec_size: int
    :param smem_layout: The smem layout of SFB per stage
    :type smem_layout: cute.Layout

    :return: TMEM layout for SFB
    :rtype: cute.Layout
    """
    atom_thr_size = cute.size(tiled_mma.thr_id.shape, loc=loc, ip=ip)
    cta_tile_shape_m = mma_tiler_mnk[0] // atom_thr_size  # type: ignore[index]

    sfb_layout_ty = _cute_nvgpu_ir.make_tmem_layout_sfb(
        smem_layout, cta_tile_shape_m, atom_thr_size, sf_vec_size
    )
    return _cute_ir.static(sfb_layout_ty, loc=loc, ip=ip)


@dataclass(frozen=True)
class Sm103BlockScaledBasicChunk:
    """
    Basic scale-factor atom layout decided by tcgen05 BlockScaled MMA Ops on SM103.

    Represents the fixed layout pattern for scale factors used by tcgen05
    BlockScaled MMA Ops on SM103. The layout is determined by the instruction
    specification and is not configurable.
    """

    sf_vec_size: int
    major_mode: OperandMajorMode = OperandMajorMode.K
    _layout: cute.Layout = field(init=False, repr=False)

    def __post_init__(self) -> None:
        atom_shape: cute.Shape
        atom_stride: cute.Stride
        if self.major_mode == OperandMajorMode.K:
            atom_shape = ((8, 4, 4), (self.sf_vec_size, 4))
            atom_stride = ((16, 128, 4), (0, 1))
        else:
            atom_shape = ((self.sf_vec_size, 4), (8, 4, 4))
            atom_stride = ((0, 1), (16, 128, 4))

        object.__setattr__(
            self, "_layout", cute.make_layout(shape=atom_shape, stride=atom_stride)
        )

    @property
    def layout(self) -> cute.Layout:
        return self._layout


@dsl_user_op
def sm103_make_smem_layout_sfa(
    tiled_mma: cute.TiledMma,
    mma_tiler: cute.Tile,
    sf_vec_size: int,
    num_stages: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """
    Make SMEM layout for SFA based on:
    1) Sm103BlockScaledBasicChunk, 2) MMA tiler, 3) sf_vec_size, 4) stages.

    :param tiled_mma: The tiled MMA
    :type tiled_mma: cute.TiledMma
    :param mma_tiler: The mma tiler shape
    :type mma_tiler: cute.Tile
    :param sf_vec_size: The scale factor vector size
    :type sf_vec_size: int
    :param num_stages: The number of stages
    :type num_stages: int

    :return: Smem layout for SFA
    :rtype: cute.Layout
    """
    mma_shape_mk = tiled_mma.partition_shape_A((mma_tiler[0], mma_tiler[2]))  # type: ignore[index]
    sf_atom = Sm103BlockScaledBasicChunk(sf_vec_size, tiled_mma.op.a_major_mode).layout  # type: ignore[attr-defined]
    k_divisor = 4 if sf_vec_size == 16 else 2
    mma_sfa_tiler = (
        mma_shape_mk[0][0] * mma_shape_mk[1],
        mma_shape_mk[0][1] * mma_shape_mk[2] // k_divisor,
    )
    sfa_smem_atom_layout = cute.tiled_product(
        sf_atom,
        cute.make_layout(
            cute.shape_div(mma_sfa_tiler, cute.product_each(sf_atom.shape))
        ),
    )
    sfa_smem_layout_staged = cute.make_layout(
        shape=cute.append(sfa_smem_atom_layout.shape, num_stages),
        stride=cute.append(
            sfa_smem_atom_layout.stride,
            cute.size(cute.filter_zeros(sfa_smem_atom_layout)),
        ),
    )
    return sfa_smem_layout_staged


@dsl_user_op
def sm103_make_smem_layout_sfb(
    tiled_mma: cute.TiledMma,
    mma_tiler: cute.Tile,
    sf_vec_size: int,
    num_stages: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """
    Make SMEM layout for SFB based on the basic chunk, MMA tiler, sf_vec_size, stages.

    :param tiled_mma: The tiled MMA
    :type tiled_mma: cute.TiledMma
    :param mma_tiler: The mma tiler shape
    :type mma_tiler: cute.Tile
    :param sf_vec_size: The scale factor vector size
    :type sf_vec_size: int
    :param num_stages: The number of stages
    :type num_stages: int

    :return: Smem layout for SFB
    :rtype: cute.Layout
    """
    sf_atom = Sm103BlockScaledBasicChunk(sf_vec_size, tiled_mma.op.b_major_mode).layout  # type: ignore[attr-defined]
    k_divisor = 4 if sf_vec_size == 16 else 2
    mma_sfb_tiler = (mma_tiler[1], mma_tiler[2] // k_divisor)  # type: ignore[index, operator]
    if mma_sfb_tiler[0] == 128:
        sfb_smem_atom_layout = cute.tiled_product(
            sf_atom,
            cute.make_layout(
                cute.shape_div(mma_sfb_tiler, cute.product_each(sf_atom.shape))
            ),
        )
    else:
        sf_k_major_atom256 = cute.make_layout(
            shape=(
                (32, 4, 2),
                (sf_vec_size, 4),
            ),
            stride=(
                (16, 4, mma_sfb_tiler[1] // sf_vec_size // 4 * 512),
                (0, 1),
            ),
        )
        sfb_smem_atom_layout = cute.tiled_product(
            sf_k_major_atom256,
            cute.make_layout(
                cute.shape_div(
                    mma_sfb_tiler, cute.product_each(sf_k_major_atom256.shape)
                )
            ),
        )

    sfb_smem_layout_staged = cute.make_layout(
        shape=cute.append(sfb_smem_atom_layout.shape, num_stages),
        stride=cute.append(
            sfb_smem_atom_layout.stride,
            cute.size(cute.filter_zeros(sfb_smem_atom_layout)),
        ),
    )
    return sfb_smem_layout_staged
