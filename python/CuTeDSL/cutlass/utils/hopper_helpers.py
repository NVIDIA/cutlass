# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from typing import Type, Union, Tuple, Optional

from cutlass.utils.layout import LayoutEnum
from cutlass.cutlass_dsl import (
    Float16,
    BFloat16,
    Float8E5M2,
    Float8E4M3FN,
    Int8,
    Uint8,
    Numeric,
    NumericMeta,
    dsl_user_op,
)

import cutlass.cute as cute
from cutlass.cute.nvgpu.common import CopyUniversalOp
from cutlass.cute.nvgpu.warp import StMatrix8x8x16bOp
from cutlass.cute.nvgpu.warpgroup import (
    MmaF16BF16Op,
    MmaF8Op,
    MmaI8Op,
    OperandMajorMode,
    OperandSource as WarpgroupOperandSource,
    make_smem_layout_atom,
)

# Type alias for documentation clarity
OperandSource = WarpgroupOperandSource


@dsl_user_op
def get_smem_store_op(
    layout_d: LayoutEnum,
    elem_ty_d: Type[Numeric],
    elem_ty_acc: Type[Numeric],
    *,
    loc=None,
    ip=None,
) -> cute.CopyAtom:
    """
    Selects the largest vectorized smem store atom available subject to constraint of gmem layout.

    Parameters:
    -----------
    layout_d : LayoutEnum
        The layout enum of the output tensor D.

    elem_ty_d : Type[Numeric]
        The element type for output tensor D.

    elem_ty_acc : Type[Numeric]
        The element type for accumulator.

    Returns:
    --------
    Either SmemStoreMatrix or SimtSyncCopy, based on the input parameters.
    """

    def validate_type(ty, ty_name):
        if not isinstance(ty, NumericMeta):
            raise TypeError(f"{ty_name} must be a Numeric, but got {ty}")

    validate_type(elem_ty_d, "elem_ty_d")
    validate_type(elem_ty_acc, "elem_ty_acc")

    is_m_major = layout_d.is_m_major_c()

    if elem_ty_d.width == 16:
        return cute.make_copy_atom(
            StMatrix8x8x16bOp(is_m_major, 4), elem_ty_d, loc=loc, ip=ip
        )
    else:
        return cute.make_copy_atom(CopyUniversalOp(), elem_ty_d, loc=loc, ip=ip)


# Temporarily wire to existing code to avoid breaking changes
sm90_get_smem_store_op = get_smem_store_op


def make_trivial_tiled_mma(
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    a_leading_mode: OperandMajorMode,
    b_leading_mode: OperandMajorMode,
    acc_dtype: Type[Numeric],
    atom_layout_mnk: Tuple[int, int, int],
    tiler_mn: Tuple[int, int],
    a_source: OperandSource = OperandSource.SMEM,
    *,
    loc=None,
    ip=None,
) -> cute.TiledMma:
    """Make a tiled MMA atom with given data type, leading dimension, cta group and mma tile shape.
    By default, the MMA atom is created with SMEM operand source for A.

    :param a_dtype: Data type of operand A.
    :type a_dtype: type[Numeric]
    :param b_dtype: Data type of operand B.
    :type b_dtype: type[Numeric]
    :param a_leading_mode: Leading dimension of operand A (1 for K, 0 for M/N).
    :type a_leading_mode: warpgroup.OperandMajorMode
    :param b_leading_mode: Leading dimension of operand B (1 for K, 0 for M/N).
    :type b_leading_mode: warpgroup.OperandMajorMode
    :param acc_dtype: Data type of the accumulator.
    :type acc_dtype: type[Numeric]
    :param atom_layout_mnk: A integer tuple describing the tiling of Atom across threads.
    :type atom_layout_mnk: Tuple[int, int, int]
    :param tiler_mn: The shape (M, N) of the cta tiler.
    :type tiler_mn: Tuple[int, int]

    :return: A tiled MMA atom.
    :rtype: cute.TiledMma

    :raises TypeError: If the data type is not supported.
    """

    if a_dtype in {Float16, BFloat16}:
        if a_dtype != b_dtype:
            raise TypeError(f"Type mismatch: {a_dtype} != {b_dtype}")
        if a_dtype.width != b_dtype.width:
            raise TypeError(f"Type width mismatch: {a_dtype.width} != {b_dtype.width}")

        mma_op = MmaF16BF16Op(
            a_dtype,
            acc_dtype,
            (*tiler_mn, 16),
            a_source,
            a_leading_mode,
            b_leading_mode,
        )
    elif a_dtype in {Float8E4M3FN, Float8E5M2} and b_dtype in {
        Float8E4M3FN,
        Float8E5M2,
    }:
        mma_op = MmaF8Op(
            a_dtype,
            b_dtype,
            acc_dtype,
            (*tiler_mn, 32),
            a_source,
            a_leading_mode,
            b_leading_mode,
        )
    elif a_dtype in {Int8, Uint8} and b_dtype in {Int8, Uint8}:
        mma_op = MmaI8Op(
            a_dtype,
            b_dtype,
            acc_dtype,
            (*tiler_mn, 32),
            a_source,
            a_leading_mode,
            b_leading_mode,
        )
    else:
        raise TypeError(f"unsupported a_dtype and b_dtype, got {a_dtype} and {b_dtype}")

    return cute.make_tiled_mma(cute.make_mma_atom(mma_op), atom_layout_mnk)


@dsl_user_op
def get_smem_layout_atom(
    layout: LayoutEnum,
    element_type: Type[Numeric],
    major_mode_size: int,
    *,
    loc=None,
    ip=None,
):
    """Select the optimal shared memory layout atom based on parameters.

    :param layout: Layout enum of the tensor
    :type layout: LayoutEnum
    :param element_type: Data type of the elements
    :type element_type: type[Numeric]
    :param major_mode_size: Size of the major mode dimension
    :type major_mode_size: int

    :return: Selected shared memory layout atom kind
    :rtype: cute.nvgpu.warpgroup.SmemLayoutAtomKind
    """
    assert major_mode_size % 8 == 0
    sw128_num_contiguous_bits = 1024
    sw64_num_contiguous_bits = 512
    sw32_num_contiguous_bits = 256
    major_mode_size_bits = major_mode_size * element_type.width
    if layout.sm90_mma_major_mode() == OperandMajorMode.MN:
        if major_mode_size_bits % sw128_num_contiguous_bits == 0:
            return cute.nvgpu.warpgroup.SmemLayoutAtomKind.MN_SW128
        if major_mode_size_bits % sw64_num_contiguous_bits == 0:
            return cute.nvgpu.warpgroup.SmemLayoutAtomKind.MN_SW64
        if major_mode_size_bits % sw32_num_contiguous_bits == 0:
            return cute.nvgpu.warpgroup.SmemLayoutAtomKind.MN_SW32
        return cute.nvgpu.warpgroup.SmemLayoutAtomKind.MN_INTER
    if major_mode_size_bits % sw128_num_contiguous_bits == 0:
        return cute.nvgpu.warpgroup.SmemLayoutAtomKind.K_SW128
    if major_mode_size_bits % sw64_num_contiguous_bits == 0:
        return cute.nvgpu.warpgroup.SmemLayoutAtomKind.K_SW64
    if major_mode_size_bits % sw32_num_contiguous_bits == 0:
        return cute.nvgpu.warpgroup.SmemLayoutAtomKind.K_SW32
    return cute.nvgpu.warpgroup.SmemLayoutAtomKind.K_INTER


@dsl_user_op
def make_smem_layout_a(
    a_layout: LayoutEnum,
    mma_tiler_mnk: cute.Tile,
    a_dtype: Type[Numeric],
    num_stages: int,
    *,
    loc=None,
    ip=None,
) -> Union[cute.Layout, cute.ComposedLayout]:
    """This function helps with:

    1. Get the partitioned shape of the A tensor based on the MMA tiler.
    2. Select the heuristic SMEM layout atom based on the A tensor's majorness, the data type, and the major mode size.
    3. cute.Tile the SMEM layout atom to the MMA tile shape.
    4. Stage the SMEM layout based on the number of stages.

    :param a_layout: The layout enum for tensor A
    :type a_layout: LayoutEnum
    :param mma_tiler_mnk: The MMA tile shape
    :type mma_tiler_mnk: cute.cute.Tile
    :param a_dtype: The element type for tensor A
    :type a_dtype: Type[Numeric]
    :param num_stages: The number of pipeline stages for tensor A
    :type num_stages: int

    :return: SMEM layout for tensor A
    :rtype: Union[cute.Layout, cute.ComposedLayout]
    """
    # Extract A tensor shape from the MMA tiler (M dimension)
    a_tile_shape_mnk = mma_tiler_mnk
    a_smem_shape = cute.slice_(a_tile_shape_mnk, (None, 0, None), loc=loc, ip=ip)

    # Determine if K is the major mode and get the major mode size
    is_k_major = a_layout.is_k_major_a()
    a_major_mode_size = a_tile_shape_mnk[2] if is_k_major else a_tile_shape_mnk[0]

    # Create SMEM layout atom for A tensor based on major mode and data type
    a_smem_layout_atom = make_smem_layout_atom(
        get_smem_layout_atom(a_layout, a_dtype, a_major_mode_size, loc=loc, ip=ip),
        a_dtype,
        loc=loc,
        ip=ip,
    )

    # Tile the SMEM layout atom to the A tensor shape and add staging dimension
    a_smem_layout_staged = cute.tile_to_shape(
        a_smem_layout_atom,
        cute.append(a_smem_shape, num_stages),
        order=(0, 1, 2) if is_k_major else (1, 0, 2),
        loc=loc,
        ip=ip,
    )

    return a_smem_layout_staged


@dsl_user_op
def make_smem_layout_b(
    b_layout: LayoutEnum,
    mma_tiler_mnk: cute.Tile,
    b_dtype: Type[Numeric],
    num_stages: int,
    *,
    loc=None,
    ip=None,
) -> Union[cute.Layout, cute.ComposedLayout]:
    """This function helps with:

    1. Get the partitioned shape of the B tensor based on the MMA tiler.
    2. Select the heuristic SMEM layout atom based on the B tensor's majorness, the data type, and the major mode size.
    3. cute.Tile the SMEM layout atom to the MMA tile shape.
    4. Stage the SMEM layout based on the number of stages.

    :param b_layout: The layout enum for tensor B
    :type b_layout: LayoutEnum
    :param mma_tiler_mnk: The MMA tile shape
    :type mma_tiler_mnk: cute.cute.Tile
    :param b_dtype: The element type for tensor B
    :type b_dtype: Type[Numeric]
    :param num_stages: The number of pipeline stages for tensor B
    :type num_stages: int

    :return: SMEM layout for tensor B
    :rtype: Union[cute.Layout, cute.ComposedLayout]
    """
    # Extract B tensor shape from the MMA tiler (N and K dimensions)
    b_smem_shape = cute.slice_(mma_tiler_mnk, (0, None, None), loc=loc, ip=ip)

    # Determine if K is the major mode and get the major mode size
    is_k_major = b_layout.is_k_major_b()
    b_major_mode_size = mma_tiler_mnk[2] if is_k_major else mma_tiler_mnk[1]

    # Create SMEM layout atom for B tensor based on major mode and data type
    b_smem_layout_atom = make_smem_layout_atom(
        get_smem_layout_atom(b_layout, b_dtype, b_major_mode_size, loc=loc, ip=ip),
        b_dtype,
        loc=loc,
        ip=ip,
    )

    # Tile the SMEM layout atom to the B tensor shape and add staging dimension
    b_smem_layout_staged = cute.tile_to_shape(
        b_smem_layout_atom,
        cute.append(b_smem_shape, num_stages),
        order=((1, 0, 2) if not is_k_major else (0, 1, 2)),
        loc=loc,
        ip=ip,
    )

    return b_smem_layout_staged


@dsl_user_op
def make_smem_layout_epi(
    epi_dtype: Type[Numeric],
    epi_layout: LayoutEnum,
    epi_tile: cute.Tile,
    epi_stage: int,
    smem_trg_shape: Optional[cute.Layout] = None,
    smem_order: Optional[tuple] = None,
    *,
    loc=None,
    ip=None,
) -> Union[cute.Layout, cute.ComposedLayout]:
    """This function helps:

    1. Select the heuristic SMEM layout atom based on the epilog tile shape,
       the epilog tensor's majorness, and the element type.
    2. cute.Tile the SMEM layout atom to the epilog tile shape.
    3. Stage the SMEM layout based on the number of stages.

    :param epi_dtype: The element type for the epilog tensor.
    :type epi_dtype: Type[Numeric]
    :param epi_layout: The layout enum for the epilog tensor.
    :type epi_layout: LayoutEnum
    :param epi_tile: The epilogue tile shape.
    :type epi_tile: cute.cute.Tile
    :param epi_stage: The stage of the epilog tensor.
    :type epi_stage: int
    :param smem_trg_shape: Target shape for SMEM layout (optional).
    :type smem_trg_shape: cute.Layout | None
    :param smem_order: Order for SMEM layout (optional).
    :type smem_order: tuple | None

    :return: SMEM layout for epilog tensors (usually C & D which are processed in the epilog)
    :rtype: Union[cute.Layout, cute.ComposedLayout]
    """
    # Extract output tensor shape from epilog tile
    o_smem_shape = epi_tile

    # Determine major mode size based on layout (M or N major)
    o_major_mode_size = epi_tile[1] if epi_layout.is_n_major_c() else epi_tile[0]

    # Create SMEM layout atom for output tensor based on layout and data type
    o_smem_layout_atom = make_smem_layout_atom(
        get_smem_layout_atom(epi_layout, epi_dtype, o_major_mode_size, loc=loc, ip=ip),
        epi_dtype,
        loc=loc,
        ip=ip,
    )

    # Determine target shape and order for staging (use provided or default)
    trg_shape = (
        smem_trg_shape
        if smem_trg_shape is not None
        else cute.append(o_smem_shape, epi_stage)
    )

    order = (
        smem_order
        if smem_order is not None
        else (1, 0, 2)
        if epi_layout.is_m_major_c()
        else (0, 1, 2)
    )

    # Tile the SMEM layout atom to the target shape with staging
    o_smem_layout_staged = cute.tile_to_shape(
        o_smem_layout_atom, trg_shape, order, loc=loc, ip=ip
    )

    return o_smem_layout_staged


def compute_tile_shape_or_override(
    tile_shape_mnk: tuple[int, int, int],
    element_type: type[Numeric],
    is_cooperative: bool = False,
    epi_tile_override: Optional[tuple[int, int]] = None,
) -> tuple[int, int]:
    """Compute the epilogue tile shape or use override if provided.

    :param tile_shape_mnk: CTA tile shape (M,N,K)
    :type tile_shape_mnk: Tuple[int, int, int]
    :param element_type: Data type of elements
    :type element_type: type[Numeric]
    :param is_cooperative: Whether to use cooperative approach
    :type is_cooperative: bool
    :param epi_tile_override: Optional override for epilogue tile shape
    :type epi_tile_override: Tuple[int, int] or None

    :return: Computed epilogue tile shape
    :rtype: Tuple[int, int]
    """
    if epi_tile_override is not None:
        return epi_tile_override
    if is_cooperative:
        tile_m = min(128, cute.size(tile_shape_mnk, mode=[0]))
        tile_n = min(32, cute.size(tile_shape_mnk, mode=[1]))
        return (tile_m, tile_n)
    else:
        n_perf = 64 if element_type.width == 8 else 32
        tile_m = min(64, cute.size(tile_shape_mnk, mode=[0]))
        tile_n = min(n_perf, cute.size(tile_shape_mnk, mode=[1]))
        return (tile_m, tile_n)


__all__ = [
    "get_smem_store_op",
    "make_smem_layout_a",
    "make_smem_layout_b",
    "make_smem_layout_epi",
    "compute_tile_shape_or_override",
]
