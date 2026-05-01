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

from typing import Any, List, Optional, Type, Union, Tuple, overload
from typing_extensions import deprecated

from cutlass.cutlass_dsl import (
    Float16,
    BFloat16,
    TFloat32,
    Float32,
    Uint8,
    Int8,
    Float8E4M3FN,
    Float8E5M2,
    Float6E3M2FN,
    Float6E2M3FN,
    Float4E2M1FN,
    Numeric,
    NumericMeta,
    dsl_user_op,
)

from cutlass._mlir import ir
import cutlass.cute as cute
from cutlass.cute.nvgpu.common import CopyUniversalOp, OperandMajorMode
from cutlass.cute.nvgpu.warp import StMatrix8x8x16bOp, StMatrix16x8x8bOp
from cutlass.cute.nvgpu.tcgen05 import (
    MmaF16BF16Op,
    MmaTF32Op,
    MmaI8Op,
    MmaF8F6F4Op,
    MmaMXF8F6F4Op,
    MmaMXF4Op,
    MmaMXF4NVF4Op,
    SM103MmaMXF4Op,
    SM103MmaMXF4NVF4Op,
    OperandSource as Tcgen05OperandSource,
    CtaGroup,
    Ld16x64bOp,
    Ld16x128bOp,
    Ld16x256bOp,
    Ld16x32bx2Op,
    Ld32x32bOp,
    Repetition,
    Pack,
    SmemLayoutAtomKind,
    make_smem_layout_atom,
    tile_to_mma_shape,
    is_tmem_load,
    get_tmem_copy_properties,
)
from cutlass.cute.nvgpu.cpasync import (
    CopyBulkTensorTileG2SMulticastOp,
    CopyBulkTensorTileG2SOp,
)
from cutlass.utils.layout import LayoutEnum
import cutlass.cute.testing as testing

# Type alias for documentation clarity
OperandSource = Tcgen05OperandSource

TMA_ALIGNMENT_BYTES = 16


def get_tma_aligned_contiguous_elements(elem_ty: Type[Numeric]) -> int:
    """Return the minimum contiguous element count for 16B TMA alignment."""
    if not isinstance(elem_ty, NumericMeta):
        raise TypeError(f"elem_ty must be Numeric, but got {elem_ty}")
    if elem_ty.width == 6:
        raise testing.CantImplementError(
            "[alignment] FP6 TMA alignment is not validated by the experimental "
            "Blackwell GEMM preflight checks yet"
        )
    return TMA_ALIGNMENT_BYTES * 8 // elem_ty.width


def check_tma_tensor_alignment(
    tensor_name: str,
    elem_ty: Type[Numeric],
    contiguous_dim_size: int,
    contiguous_dim_name: str,
) -> None:
    """Fail fast when a TMA operand's contiguous dimension is not 16B aligned."""
    required_elements = get_tma_aligned_contiguous_elements(elem_ty)
    if contiguous_dim_size % required_elements != 0:
        raise testing.CantImplementError(
            f"[alignment] {tensor_name} requires the contiguous "
            f"{contiguous_dim_name} dimension to be {TMA_ALIGNMENT_BYTES}B aligned, "
            f"but got {contiguous_dim_name}={contiguous_dim_size} with dtype {elem_ty}; "
            f"expected a multiple of {required_elements} elements"
        )


def check_gemm_tma_alignment(
    m: int,
    n: int,
    k: int,
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    d_dtype: Type[Numeric] | None,
    a_major: str,
    b_major: str,
    d_major: str | None,
    *,
    output_tensor_name: str = "D",
) -> None:
    """Validate GEMM operand alignment for TMA loads and an optional TMA store."""
    if a_major not in ["m", "k"]:
        raise testing.CantImplementError(
            f"[alignment] Invalid a_major: {a_major}, expected 'm' or 'k'"
        )
    if b_major not in ["n", "k"]:
        raise testing.CantImplementError(
            f"[alignment] Invalid b_major: {b_major}, expected 'n' or 'k'"
        )
    if d_dtype is not None and d_major not in ["m", "n"]:
        raise testing.CantImplementError(
            f"[alignment] Invalid d_major: {d_major}, expected 'm' or 'n'"
        )

    check_tma_tensor_alignment(
        "A TMA load",
        a_dtype,
        m if a_major == "m" else k,
        "M" if a_major == "m" else "K",
    )
    check_tma_tensor_alignment(
        "B TMA load",
        b_dtype,
        n if b_major == "n" else k,
        "N" if b_major == "n" else "K",
    )

    if d_dtype is not None:
        check_tma_tensor_alignment(
            f"{output_tensor_name} TMA store",
            d_dtype,
            m if d_major == "m" else n,
            "M" if d_major == "m" else "N",
        )


@dsl_user_op
@deprecated("API is deprecated, use cutlass.utils.get_num_tmem_alloc_cols instead")
def get_num_tmem_alloc_cols(
    tmem_tensors: Union[cute.Tensor, List[cute.Tensor]],
    rounding: bool = True,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> int:
    import cutlass.utils as utils

    return utils.get_num_tmem_alloc_cols(
        tmem_tensors, rounding, arch="sm_100", loc=loc, ip=ip
    )


@dsl_user_op
def compute_epilogue_tile_shape(
    cta_tile_shape: cute.Shape,
    use_2cta_instrs: bool,
    layout_d: LayoutEnum,
    elem_ty_d: Type[Numeric],
    *,
    layout_c: Optional[LayoutEnum] = None,
    elem_ty_c: Union[Type[Numeric], None] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Tile:
    """Attempts to compute a reasonable epilogue tile based on block tile shape or allows the user to provide one.

    :param cta_tile_shape: A tuple or list representing the dimensions of the CTA tile, where
        cta_tile_shape[0] corresponds to the height (M) and cta_tile_shape[1]
        corresponds to the width (N) of the tile.
    :type cta_tile_shape: cute.Shape
    :param use_2cta_instrs: A flag indicating whether the configuration is for a 2SM setup.
    :type use_2cta_instrs: bool
    :param layout_d: The layout enum of the output tensor D.
    :type layout_d: LayoutEnum
    :param elem_ty_d: The element type of output tensor D.
    :type elem_ty_d: Type[Numeric]
    :param layout_c: The layout enum of the input tensor C. Defaults to None.
    :type layout_c: LayoutEnum, optional
    :param elem_ty_c: The element type for input tensor C. Defaults to None.
    :type elem_ty_c: Union[Type[Numeric], None], optional

    :return: Returns epilog tiler, which is used in subsequent epilog partitions.
    :rtype: cute.Tile

    :raises ValueError: If the computed tile cute.size does not meet minimum requirements based on CTA dimensions.
    """

    def validate_type(ty: Type[Numeric], ty_name: str) -> None:
        if not isinstance(ty, NumericMeta):
            raise TypeError(f"{ty_name} must be Numeric, but got {ty}")

    validate_type(elem_ty_d, "elem_ty_d")
    if elem_ty_c is not None:
        validate_type(elem_ty_c, "elem_ty_c")

    cta_m, cta_n = cta_tile_shape[:2]  # type: ignore[index]
    d_is_m_major = layout_d.is_m_major_c()
    c_is_m_major = True if layout_c is None else layout_c.is_m_major_c()

    # Pure-Python helper (no MLIR context needed)
    tile_m, tile_n = compute_epilogue_tile_size(
        cta_m,  # type: ignore[arg-type]
        cta_n,  # type: ignore[arg-type]
        use_2cta_instrs,
        elem_ty_d.width,
        elem_ty_c.width if elem_ty_c is not None else None,
        d_is_m_major,
        c_is_m_major,
    )

    # Compute warp layout parameters (needed for CuTe layout creation)
    (warp_m, warp_n) = (2, 2) if (cta_m == 64 and use_2cta_instrs) else (4, 1)

    # Validate minimum tile requirements
    disable_source = elem_ty_c is None
    n_min_d = (
        8 * warp_n
        if d_is_m_major
        else (128 * warp_n if elem_ty_d.width == 6 else 128 // elem_ty_d.width * warp_n)
    )
    n_min_c = (
        8 * warp_n
        if (c_is_m_major or disable_source)
        else (128 * warp_n if elem_ty_c.width == 6 else 128 // elem_ty_c.width * warp_n)  # type: ignore[union-attr]
    )
    if cta_n < n_min_c or cta_n < n_min_d:  # type: ignore[operator]
        raise ValueError(f"CTA tile too small: {cta_tile_shape=}")

    # stride by tmem warp layout and return a by-mode tiler
    tile_m_layout = cute.make_layout(tile_m, loc=loc, ip=ip)
    tile_n_layout = cute.make_layout(
        (tile_n // warp_n, warp_n),
        stride=(1, cta_n // warp_n),  # type: ignore[operator]
        loc=loc,
        ip=ip,
    )
    return (tile_m_layout, cute.coalesce(tile_n_layout, loc=loc, ip=ip))


@dsl_user_op
def get_smem_store_op(
    layout_d: LayoutEnum,
    elem_ty_d: Type[Numeric],
    elem_ty_acc: Type[Numeric],
    tiled_tmem_load: cute.TiledCopy,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.CopyAtom:
    """Selects the largest vectorized smem store atom available subject to
    constraint of gmem layout and chosen TMEM_LOAD's thread-value ownership.

    :param layout_d: The layout enum of the output tensor D.
    :type layout_d: LayoutEnum
    :param elem_ty_d: The element type for output tensor D.
    :type elem_ty_d: Type[Numeric]
    :param elem_ty_acc: The element type for accumulator.
    :type elem_ty_acc: Type[Numeric]
    :param tiled_tmem_load: An instance of TiledCopy that represents the tmem load operation.
    :type tiled_tmem_load: cute.TiledCopy

    :return: Either SmemStoreMatrix or SimtSyncCopy, based on the input parameters.
    :rtype: cute.CopyAtom
    """

    def validate_type(ty: Type[Numeric], ty_name: str) -> None:
        if not isinstance(ty, NumericMeta):
            raise TypeError(f"{ty_name} must be a Numeric, but got {ty}")

    validate_type(elem_ty_d, "elem_ty_d")
    validate_type(elem_ty_acc, "elem_ty_acc")

    is_m_major = layout_d.is_m_major_c()
    is_n_major = layout_d.is_n_major_c()

    if not is_tmem_load(tiled_tmem_load):
        return cute.make_copy_atom(CopyUniversalOp(), elem_ty_d, loc=loc, ip=ip)

    num_dp, num_bits, num_rep, pack = get_tmem_copy_properties(tiled_tmem_load)

    use_stmatrix_m8n8_4x = (
        all(
            [
                elem_ty_acc.width == 32,
                elem_ty_d.width == 32,
                is_n_major,
                num_dp == 16,
                num_bits == 128,
                num_rep in (2, 4, 8, 16, 32, 64),
                pack == Pack.NONE,
            ]
        )
        or all(
            [
                elem_ty_acc.width == 32,
                elem_ty_d.width == 16,
                num_dp == 16,
                num_bits == 256,
                num_rep in (2, 4, 8, 16, 32),
                pack == Pack.NONE,
            ]
        )
        or all(
            [
                elem_ty_acc.width == 16,
                elem_ty_d.width == 16,
                num_dp == 16,
                num_bits == 128,
                num_rep in (2, 4, 8, 16, 32, 64),
                pack == Pack.PACK_16b_IN_32b,
            ]
        )
    )
    use_stmatrix_m16n8_4x = all(
        [
            elem_ty_acc.width == 32,
            elem_ty_d.width == 8,
            is_m_major,
            num_dp == 16,
            num_bits == 256,
            num_rep in (4, 8, 16, 32),
            pack == Pack.NONE,
        ]
    )
    use_stmatrix_m8n8_2x = (
        all(
            [
                elem_ty_acc.width == 32,
                elem_ty_d.width == 32,
                is_n_major,
                num_dp == 16,
                num_bits == 128,
                num_rep == 1,
                pack == Pack.NONE,
            ]
        )
        or all(
            [
                elem_ty_acc.width == 32,
                elem_ty_d.width == 16,
                num_dp == 16,
                num_bits == 256,
                num_rep == 1,
                pack == Pack.NONE,
            ]
        )
        or all(
            [
                elem_ty_acc.width == 16,
                elem_ty_d.width == 16,
                num_dp == 16,
                num_bits == 128,
                num_rep == 1,
                pack == Pack.PACK_16b_IN_32b,
            ]
        )
    )
    use_stmatrix_m16n8_2x = all(
        [
            elem_ty_acc.width == 32,
            elem_ty_d.width == 8,
            is_m_major,
            num_dp == 16,
            num_bits == 256,
            num_rep == 2,
            pack == Pack.NONE,
        ]
    )
    use_stmatrix_m16n8_1x = all(
        [
            elem_ty_acc.width == 32,
            elem_ty_d.width == 8,
            is_m_major,
            num_dp == 16,
            num_bits == 256,
            num_rep == 1,
            pack == Pack.NONE,
        ]
    )

    op: Any
    if use_stmatrix_m8n8_4x:
        op = StMatrix8x8x16bOp(is_m_major, 4)
        return cute.make_copy_atom(op, elem_ty_d, loc=loc, ip=ip)
    elif use_stmatrix_m8n8_2x:
        op = StMatrix8x8x16bOp(is_m_major, 2)
        return cute.make_copy_atom(op, elem_ty_d, loc=loc, ip=ip)
    elif use_stmatrix_m16n8_4x:
        op = StMatrix16x8x8bOp(transpose=True, num_matrices=4)
        return cute.make_copy_atom(op, elem_ty_d, loc=loc, ip=ip)
    elif use_stmatrix_m16n8_2x:
        op = StMatrix16x8x8bOp(transpose=True, num_matrices=2)
        return cute.make_copy_atom(op, elem_ty_d, loc=loc, ip=ip)
    elif use_stmatrix_m16n8_1x:
        op = StMatrix16x8x8bOp(transpose=True, num_matrices=1)
        return cute.make_copy_atom(op, elem_ty_d, loc=loc, ip=ip)
    else:
        op = CopyUniversalOp()
        return cute.make_copy_atom(op, elem_ty_d, loc=loc, ip=ip)


@dsl_user_op
def get_tmem_load_op(
    cta_tile_shape: cute.Shape,
    layout_d: LayoutEnum,
    elem_ty_d: Type[Numeric],
    elem_ty_acc: Type[Numeric],
    epi_tile: cute.Tile,
    use_2cta_instrs: bool,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.CopyAtom:
    """Finds a performant TMEM_LOAD copy op for the selected epilogue
    tile (epi_tile), element types, and tcgen05.mma instruction used.

    :param cta_tile_shape: A tuple or list representing the dimensions of the CTA tile.
    :type cta_tile_shape: cute.Shape
    :param layout_d: The layout enum of the output tensor D.
    :type layout_d: LayoutEnum
    :param elem_ty_d: The element type for output tensor D.
    :type elem_ty_d: Type[Numeric]
    :param elem_ty_acc: The element type for accumulation.
    :type elem_ty_acc: Type[Numeric]
    :param epi_tile: The epilogue tile configuration.
    :type epi_tile: cute.Tile
    :param use_2cta_instrs: A flag indicating whether the configuration is for 2 SMs.
    :type use_2cta_instrs: bool

    :return: An instance of Sm100TmemLoad with the computed configuration.
    :rtype: cute.CopyAtom

    :raises ValueError: If the function cannot handle the given combination of accumulation
        and dimension types, or if it cannot determine the appropriate configuration based on
        the input parameters.
    """
    is_m_major = layout_d.is_m_major_c()

    acc_bits = elem_ty_acc.width
    d_bits = elem_ty_d.width

    tmem_warp_shape_mn = (
        (2, 2) if (cta_tile_shape[0] == 64 and use_2cta_instrs) else (4, 1)  # type: ignore[index]
    )
    epilog_tile_shape_mn = cute.product_each(
        cute.shape(epi_tile, loc=loc, ip=ip), loc=loc, ip=ip
    )
    epilog_warp_tile_shape_mn = cute.shape_div(
        epilog_tile_shape_mn, tmem_warp_shape_mn, loc=loc, ip=ip
    )

    num_dp = cute.size(epilog_warp_tile_shape_mn[0], loc=loc, ip=ip)
    if num_dp not in {16, 32}:
        raise ValueError("Cta tile and 2sm config does not generate correct num dp.")

    num_col_bits = cute.size(epilog_warp_tile_shape_mn[1], loc=loc, ip=ip) * acc_bits

    tmem_dp = 0
    tmem_bit = 0
    tmem_rep = 0
    tmem_pack16b = False
    if acc_bits == 32 and d_bits == 32:
        if num_dp == 16:
            if is_m_major:
                tmem_dp = 16
                tmem_bit = 256
            else:
                tmem_dp = 16
                tmem_bit = 128
        else:
            tmem_dp = 32
            tmem_bit = 32
    elif acc_bits == 32 and d_bits == 16:
        if num_dp == 16:
            if is_m_major:
                tmem_dp = 16
                tmem_bit = 256
            else:
                tmem_dp = 16
                tmem_bit = 256
        else:
            if is_m_major:
                tmem_dp = 16
                tmem_bit = 256
            else:
                tmem_dp = 32
                tmem_bit = 32
    elif acc_bits == 32 and d_bits == 8:
        if num_dp == 16:
            if is_m_major:
                tmem_dp = 16
                tmem_bit = 256
            else:
                tmem_dp = 16
                tmem_bit = 32
        else:
            if is_m_major:
                tmem_dp = 16
                tmem_bit = 256
            else:
                tmem_dp = 32
                tmem_bit = 32
    elif acc_bits == 16 and d_bits == 16:
        tmem_pack16b = True
        if num_dp == 16:
            if is_m_major:
                tmem_dp = 16
                tmem_bit = 128
            else:
                tmem_dp = 16
                tmem_bit = 128
        else:
            if is_m_major:
                tmem_dp = 16
                tmem_bit = 128
            else:
                tmem_dp = 32
                tmem_bit = 32
    elif acc_bits == 32 and d_bits == 6:
        if not num_dp == 32:
            raise ValueError("Num dp must be 32.")
        tmem_dp = 32
        tmem_bit = 32
    elif acc_bits == 32 and d_bits == 4:
        if not num_dp == 32:
            raise ValueError("Num dp must be 32.")
        tmem_dp = 32
        tmem_bit = 32
    else:
        raise ValueError(
            f"Can not handle acc/d type combination: {elem_ty_acc=}, {elem_ty_d=}"
        )

    num_bit_div = tmem_bit
    if tmem_dp == 16 and tmem_bit == 32:
        num_bit_div = 64

    if (num_col_bits % (num_bit_div * 128) == 0) and (
        (tmem_dp == 16 and tmem_bit == 64)
        or (tmem_dp == 16 and tmem_bit == 32)
        or (tmem_dp == 32 and tmem_bit == 32)
    ):
        tmem_rep = 128
    elif (num_col_bits % (num_bit_div * 64) == 0) and (
        (tmem_dp == 16 and tmem_bit == 128)
        or (tmem_dp == 16 and tmem_bit == 64)
        or (tmem_dp == 16 and tmem_bit == 32)
        or (tmem_dp == 32 and tmem_bit == 32)
    ):
        tmem_rep = 64
    elif num_col_bits % (num_bit_div * 32) == 0:
        tmem_rep = 32
    elif num_col_bits % (num_bit_div * 16) == 0:
        tmem_rep = 16
    elif num_col_bits % (num_bit_div * 8) == 0:
        tmem_rep = 8
    elif num_col_bits % (num_bit_div * 4) == 0:
        tmem_rep = 4
    elif num_col_bits % (num_bit_div * 2) == 0:
        tmem_rep = 2
    elif num_col_bits % (num_bit_div * 1) == 0:
        tmem_rep = 1
    else:
        raise ValueError("Can not pick tmem_rep based on cta tile shape and tmem atom.")

    op: Any
    if tmem_dp == 16 and tmem_bit == 64:
        op = Ld16x64bOp(
            Repetition(tmem_rep), Pack.PACK_16b_IN_32b if tmem_pack16b else Pack.NONE
        )
        return cute.make_copy_atom(op, elem_ty_acc, loc=loc, ip=ip)
    elif tmem_dp == 16 and tmem_bit == 128:
        op = Ld16x128bOp(
            Repetition(tmem_rep), Pack.PACK_16b_IN_32b if tmem_pack16b else Pack.NONE
        )
        return cute.make_copy_atom(op, elem_ty_acc, loc=loc, ip=ip)
    elif tmem_dp == 16 and tmem_bit == 256:
        op = Ld16x256bOp(
            Repetition(tmem_rep), Pack.PACK_16b_IN_32b if tmem_pack16b else Pack.NONE
        )
        return cute.make_copy_atom(op, elem_ty_acc, loc=loc, ip=ip)
    elif tmem_dp == 16 and tmem_bit == 32:
        op = Ld16x32bx2Op(
            Repetition(tmem_rep), Pack.PACK_16b_IN_32b if tmem_pack16b else Pack.NONE
        )
        return cute.make_copy_atom(op, elem_ty_acc, loc=loc, ip=ip)

    elif tmem_dp == 32 and tmem_bit == 32:
        op = Ld32x32bOp(
            Repetition(tmem_rep), Pack.PACK_16b_IN_32b if tmem_pack16b else Pack.NONE
        )
        return cute.make_copy_atom(op, elem_ty_acc, loc=loc, ip=ip)
    else:
        raise ValueError()


def get_smem_layout_atom_ab(
    major_mode: OperandMajorMode,
    element_type: Type[Numeric],
    smem_shape_mn_k: Tuple[int, int],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> SmemLayoutAtomKind:
    """Simple heuristics to select the optimal SMEM layout atom based on the
    majorness, the data type, and the major mode size.

    :param major_mode: The major mode for the SMEM tensor is K major.
    :type major_mode: cutlass.cute.nvgpu.OperandMajorMode
    :param element_type: The element type for the SMEM tensor.
    :type element_type: Type[Numeric]
    :param smem_shape_mn_k: The shape of the SMEM tensor.
    :type smem_shape_mn_k: Tuple[int, int]
    :return: The SMEM layout atom kind
    :rtype: cutlass.cute.nvgpu.tcgen05.SmemLayoutAtomKind
    """
    is_k_major = major_mode == OperandMajorMode.K
    major_mode_size = smem_shape_mn_k[1] if is_k_major else smem_shape_mn_k[0]

    assert major_mode_size % 8 == 0
    sw128_num_contiguous_bits = 1024
    sw64_num_contiguous_bits = 512
    sw32_num_contiguous_bits = 256
    inter_num_contiguous_bits = 128
    major_mode_size_bits = major_mode_size * element_type.width

    assert major_mode_size_bits % inter_num_contiguous_bits == 0

    if not is_k_major:
        if (element_type.width == 32) and (
            major_mode_size_bits % sw128_num_contiguous_bits == 0
        ):
            return SmemLayoutAtomKind.MN_SW128_32B
        if major_mode_size_bits % sw128_num_contiguous_bits == 0:
            return SmemLayoutAtomKind.MN_SW128
        if major_mode_size_bits % sw64_num_contiguous_bits == 0:
            return SmemLayoutAtomKind.MN_SW64
        if major_mode_size_bits % sw32_num_contiguous_bits == 0:
            return SmemLayoutAtomKind.MN_SW32
        return SmemLayoutAtomKind.MN_INTER
    if major_mode_size_bits % sw128_num_contiguous_bits == 0:
        return SmemLayoutAtomKind.K_SW128
    if major_mode_size_bits % sw64_num_contiguous_bits == 0:
        return SmemLayoutAtomKind.K_SW64
    if major_mode_size_bits % sw32_num_contiguous_bits == 0:
        return SmemLayoutAtomKind.K_SW32
    return SmemLayoutAtomKind.K_INTER


@dsl_user_op
def make_smem_layout(
    leading_mode: OperandMajorMode,
    smem_tile_shape: cute.Tile,
    a_dtype: Type[Numeric],
    num_stages: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[cute.Layout, cute.ComposedLayout]:
    """Construct a staged SMEM layout for an operand given its major mode and tile shape.

    This helper:

    1. Selects a SMEM layout atom using simple heuristics based on the operand's major mode,
       element type, and the size of the major dimension in ``smem_tile_shape``.
    2. Tiles the atom to ``smem_tile_shape`` and appends a staging dimension of length ``num_stages``.
    3. Orders the ``(M, N, stage)`` axes so the major dimension is contiguous, then coalesces.

    :param leading_mode: Operand major mode (``MN`` or ``K``) of the staged operand.
    :type leading_mode: cutlass.cute.nvgpu.OperandMajorMode
    :param smem_tile_shape: 2D SMEM tile shape to stage (before the staging dimension is appended).
    :type smem_tile_shape: cute.Tile
    :param a_dtype: Element type of the staged operand.
    :type a_dtype: Type[Numeric]
    :param num_stages: Number of pipeline stages (depth of the staging dimension).
    :type num_stages: int

    :return: Staged SMEM layout for the operand.
    :rtype: Union[cute.Layout, cute.ComposedLayout]
    """

    smem_layout_atom_kind = get_smem_layout_atom_ab(
        leading_mode,
        a_dtype,
        smem_tile_shape,  # type: ignore[arg-type]
        loc=loc,
        ip=ip,
    )
    smem_layout_atom = make_smem_layout_atom(
        smem_layout_atom_kind, a_dtype, loc=loc, ip=ip
    )

    is_k_major = leading_mode == OperandMajorMode.K
    smem_layout = cute.tile_to_shape(
        smem_layout_atom,
        cute.append(smem_tile_shape, num_stages),
        order=(0, 1, 2) if is_k_major else (1, 0, 2),
    )
    return cute.coalesce(smem_layout, target_profile=(1, 1, 1), loc=loc, ip=ip)


@dsl_user_op
def make_smem_layout_a(
    tiled_mma: cute.TiledMma,
    mma_tiler_mnk: cute.Tile,
    a_dtype: Type[Numeric],
    num_stages: int,
    *,
    is_k_major: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[cute.Layout, cute.ComposedLayout]:
    """This function helps with:

    1. Get the partitioned shape of the A tensor based on the tiled_mma & MMA tiler.
    2. Select the heuristic SMEM layout atom based on the A tensor's majorness, the data type, and the major mode size.
    3. cute.Tile the SMEM layout atom to the MMA tile shape.
    4. Stage the SMEM layout based on the number of stages.

    :param tiled_mma: The tiled MMA used to partition tensor A
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_mnk: The MMA tile shape
    :type mma_tiler_mnk: cute.cute.Tile
    :param a_dtype: The element type for tensor A
    :type a_dtype: Type[Numeric]
    :param num_stages: The number of pipeline stages for tensor A
    :type num_stages: int

    :return: SMEM layout for tensor A
    :rtype: Union[cute.Layout, cute.ComposedLayout]
    """

    is_k_major = (
        (tiled_mma.op.a_major_mode == OperandMajorMode.K)  # type: ignore[attr-defined]
        if is_k_major is None
        else is_k_major
    )
    a_major_mode = OperandMajorMode.K if is_k_major else OperandMajorMode.MN
    a_smem_shape = tiled_mma.partition_shape_A(
        cute.dice(mma_tiler_mnk, (1, None, 1), loc=loc, ip=ip), loc=loc, ip=ip
    )
    a_smem_shape_mn_k = (
        cute.size(a_smem_shape[0][0], loc=loc, ip=ip) * a_smem_shape[1],
        cute.size(a_smem_shape[0][1], loc=loc, ip=ip) * a_smem_shape[2],
    )
    smem_layout_atom_kind = get_smem_layout_atom_ab(
        a_major_mode, a_dtype, a_smem_shape_mn_k, loc=loc, ip=ip
    )
    a_smem_layout_atom = make_smem_layout_atom(
        smem_layout_atom_kind, a_dtype, loc=loc, ip=ip
    )

    a_smem_shape = cute.append(a_smem_shape, num_stages, loc=loc, ip=ip)
    order = (2, 1, 3) if not is_k_major else (1, 2, 3)
    return tile_to_mma_shape(
        a_smem_layout_atom, a_smem_shape, order=order, loc=loc, ip=ip
    )


@dsl_user_op
def make_smem_layout_b(
    tiled_mma: cute.TiledMma,
    mma_tiler_mnk: cute.Tile,
    b_dtype: Type[Numeric],
    num_stages: int,
    *,
    is_k_major: Optional[bool] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[cute.Layout, cute.ComposedLayout]:
    """This function helps:

    1. Get the partitioned shape of the B tensor based on the tiled_mma & MMA tiler.
    2. Select the heuristic SMEM layout atom based on the B tensor's majorness, the data type, and the major mode size.
    3. cute.Tile the SMEM layout atom to the MMA tile shape.
    4. Stage the SMEM layout based on the number of stages.

    :param tiled_mma: The tiled MMA which is used to partition the B tensor.
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_mnk: The MMA tile shape.
    :type mma_tiler_mnk: cute.cute.Tile
    :param b_dtype: The element type for the B tensor.
    :type b_dtype: Type[Numeric]
    :param num_stages: The stage of the B tensor.
    :type num_stages: int

    :return: SMEM layout for the B tensor.
    :rtype: Union[cute.Layout, cute.ComposedLayout]
    """

    is_k_major = (
        (tiled_mma.op.b_major_mode == OperandMajorMode.K)  # type: ignore[attr-defined]
        if is_k_major is None
        else is_k_major
    )
    b_major_mode = OperandMajorMode.K if is_k_major else OperandMajorMode.MN
    b_smem_shape = tiled_mma.partition_shape_B(
        cute.dice(mma_tiler_mnk, (None, 1, 1), loc=loc, ip=ip), loc=loc, ip=ip
    )
    b_smem_shape_nk = (
        cute.size(b_smem_shape[0][0], loc=loc, ip=ip) * b_smem_shape[1],
        cute.size(b_smem_shape[0][1], loc=loc, ip=ip) * b_smem_shape[2],
    )

    smem_layout_atom_kind = get_smem_layout_atom_ab(
        b_major_mode, b_dtype, b_smem_shape_nk, loc=loc, ip=ip
    )
    b_smem_layout_atom = make_smem_layout_atom(
        smem_layout_atom_kind, b_dtype, loc=loc, ip=ip
    )

    b_smem_shape = cute.append(b_smem_shape, num_stages, loc=loc, ip=ip)
    order = (2, 1, 3) if not is_k_major else (1, 2, 3)
    return tile_to_mma_shape(
        b_smem_layout_atom, b_smem_shape, order=order, loc=loc, ip=ip
    )


@dsl_user_op
def get_smem_layout_atom_epi(
    layout: LayoutEnum,
    element_type: Type[Numeric],
    epi_tile: cute.Tile,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> SmemLayoutAtomKind:
    """Simple heuristics to select the optimal SMEM layout atom for epilog tensors.

    :param layout: The layout enum for the SMEM tensor.
    :type layout: LayoutEnum
    :param element_type: The element type for the SMEM tensor.
    :type element_type: Type[Numeric]
    :param epi_tile: The epilogue tile shape.
    :type epi_tile: cute.Tile

    :return: The SMEM layout atom kind
    :rtype: cutlass.cute.nvgpu.tcgen05.SmemLayoutAtomKind
    """
    # Get the max contiguous tile usable by TMA
    tma_shape = tuple(
        (
            # assumes get<0>(epi_tile) is coalesced and unit stride
            cute.coalesce(cute.right_inverse(x, loc=loc, ip=ip), loc=loc, ip=ip).shape
            if isinstance(x, cute.Layout)
            else x
        )
        for x in epi_tile  # type: ignore[union-attr]
    )

    if layout.is_m_major_c():
        # ColMajor C/D (M-major)
        return get_smem_layout_atom_ab(
            OperandMajorMode.MN,
            element_type,
            tma_shape,  # type: ignore[arg-type]
            loc=loc,
            ip=ip,
        )
    else:
        # RowMajor C/D (N-major)
        return get_smem_layout_atom_ab(
            OperandMajorMode.K,
            element_type,
            tma_shape,  # type: ignore[arg-type]
            loc=loc,
            ip=ip,
        )


@dsl_user_op
def make_smem_layout_epi(
    epi_dtype: Type[Numeric],
    epi_layout: LayoutEnum,
    epi_tile: cute.Tile,
    epi_stage: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
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

    :return: SMEM layout for epilog tensors (usually C & D which are processed in the epilog)
    :rtype: Union[cute.Layout, cute.ComposedLayout]
    """

    epilog_shape = cute.product_each(
        cute.shape(epi_tile, loc=loc, ip=ip), loc=loc, ip=ip
    )

    smem_atom_kind = get_smem_layout_atom_epi(
        epi_layout, epi_dtype, epi_tile, loc=loc, ip=ip
    )
    c_smem_layout_atom = make_smem_layout_atom(
        smem_atom_kind, epi_dtype, loc=loc, ip=ip
    )

    epilog_shape = cute.append(epilog_shape, epi_stage, loc=loc, ip=ip)
    epi_smem_layout_staged = cute.tile_to_shape(
        c_smem_layout_atom,
        epilog_shape,
        order=((1, 0, 2) if not epi_layout.is_n_major_c() else (0, 1, 2)),
        loc=loc,
        ip=ip,
    )

    return epi_smem_layout_staged


_F8F6F4_TYPES = {
    Float8E4M3FN,
    Float8E5M2,
    Float6E3M2FN,
    Float6E2M3FN,
    Float4E2M1FN,
}


def _bind_mma_args(
    func_name: str,
    args: Tuple[Any, ...],
    kwargs: dict,
    new_params: Tuple[str, ...],
    legacy_params: Tuple[str, ...],
) -> Tuple[bool, dict]:
    """Bind positional args and kwargs to either the new or legacy parameter list.

    The last entry of each parameter list is treated as optional; all others are
    required. Returns ``(is_new_api, bound)`` where ``bound`` maps parameter
    names to values.
    """
    if "ab_dtype" in kwargs and ("a_dtype" in kwargs or "b_dtype" in kwargs):
        raise TypeError(
            f"{func_name}() cannot mix legacy 'ab_dtype' with new "
            f"'a_dtype'/'b_dtype' keyword arguments"
        )

    if "ab_dtype" in kwargs:
        is_new_api = False
    elif "a_dtype" in kwargs or "b_dtype" in kwargs:
        is_new_api = True
    elif len(args) >= 2:
        is_new_api = isinstance(args[1], NumericMeta)
    else:
        # Single (or zero) positional with no dtype kwargs — legacy is deprecated,
        # so default to new API; missing-arg validation below produces a clear error.
        is_new_api = True

    params = new_params if is_new_api else legacy_params

    if len(args) > len(params):
        raise TypeError(
            f"{func_name}() takes at most {len(params)} positional arguments but "
            f"{len(args)} were given"
        )

    bound: dict = {}
    for i, val in enumerate(args):
        bound[params[i]] = val
    for key, val in kwargs.items():
        if key not in params:
            raise TypeError(f"{func_name}() got an unexpected keyword argument '{key}'")
        if key in bound:
            raise TypeError(f"{func_name}() got multiple values for argument '{key}'")
        bound[key] = val

    required = params[:-1]
    missing = [p for p in required if p not in bound]
    if missing:
        raise TypeError(
            f"{func_name}() missing required argument(s): {', '.join(missing)}"
        )

    return is_new_api, bound


@overload
def make_trivial_tiled_mma(
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    a_leading_mode: OperandMajorMode,
    b_leading_mode: OperandMajorMode,
    acc_dtype: Type[Numeric],
    cta_group: CtaGroup,
    mma_tiler_mn: Tuple[int, int],
    a_source: OperandSource = OperandSource.SMEM,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.TiledMma: ...


@overload
@deprecated("use make_trivial_tiled_mma with separate a_dtype and b_dtype instead")
def make_trivial_tiled_mma(
    ab_dtype: Type[Numeric],
    a_leading_mode: OperandMajorMode,
    b_leading_mode: OperandMajorMode,
    acc_dtype: Type[Numeric],
    cta_group: CtaGroup,
    mma_tiler_mn: Tuple[int, int],
    a_source: OperandSource = OperandSource.SMEM,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.TiledMma: ...


@dsl_user_op
def make_trivial_tiled_mma(
    *args: Any,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
    **kwargs: Any,
) -> cute.TiledMma:
    """Make a tiled MMA atom with given data type, leading dimension, cta group and mma tile shape.
    By default, the MMA atom is created with SMEM operand source for A.

    Supports two calling conventions:

    **New (recommended):** separate ``a_dtype`` and ``b_dtype``::

        make_trivial_tiled_mma(
            a_dtype, b_dtype, a_leading_mode, b_leading_mode,
            acc_dtype, cta_group, mma_tiler_mn, [a_source])

    **Legacy (deprecated):** single ``ab_dtype``::

        make_trivial_tiled_mma(
            ab_dtype, a_leading_mode, b_leading_mode,
            acc_dtype, cta_group, mma_tiler_mn, [a_source])
    """
    import warnings

    new_params = (
        "a_dtype",
        "b_dtype",
        "a_leading_mode",
        "b_leading_mode",
        "acc_dtype",
        "cta_group",
        "mma_tiler_mn",
        "a_source",
    )
    legacy_params = (
        "ab_dtype",
        "a_leading_mode",
        "b_leading_mode",
        "acc_dtype",
        "cta_group",
        "mma_tiler_mn",
        "a_source",
    )

    is_new_api, bound = _bind_mma_args(
        "make_trivial_tiled_mma", args, kwargs, new_params, legacy_params
    )
    bound.setdefault("a_source", OperandSource.SMEM)

    if not is_new_api:
        warnings.warn(
            "make_trivial_tiled_mma with ab_dtype is deprecated, "
            "use the overload with separate a_dtype and b_dtype instead",
            DeprecationWarning,
            stacklevel=2,
        )
        a_dtype = bound["ab_dtype"]
        b_dtype = bound["ab_dtype"]
    else:
        a_dtype = bound["a_dtype"]
        b_dtype = bound["b_dtype"]

    return _make_trivial_tiled_mma_impl(
        a_dtype,
        b_dtype,
        bound["a_leading_mode"],
        bound["b_leading_mode"],
        bound["acc_dtype"],
        bound["cta_group"],
        bound["mma_tiler_mn"],
        bound["a_source"],
        loc=loc,
        ip=ip,
    )


def _make_trivial_tiled_mma_impl(
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    a_leading_mode: OperandMajorMode,
    b_leading_mode: OperandMajorMode,
    acc_dtype: Type[Numeric],
    cta_group: CtaGroup,
    mma_tiler_mn: Tuple[int, int],
    a_source: OperandSource = OperandSource.SMEM,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.TiledMma:
    mma_op: Any
    if a_dtype in {Float16, BFloat16} and b_dtype == a_dtype:
        mma_op = MmaF16BF16Op(
            a_dtype,
            acc_dtype,
            (*mma_tiler_mn, 16),
            cta_group,
            a_source,
            a_leading_mode,
            b_leading_mode,
        )
    elif a_dtype in {TFloat32, Float32} and b_dtype == a_dtype:
        mma_op = MmaTF32Op(
            (*mma_tiler_mn, 8),
            cta_group,
            a_source,
            a_leading_mode,
            b_leading_mode,
        )
    elif a_dtype in {Uint8, Int8} and b_dtype == a_dtype:
        mma_op = MmaI8Op(
            a_dtype,
            (*mma_tiler_mn, 32),
            cta_group,
            a_source,
            a_leading_mode,
            b_leading_mode,
        )
    elif a_dtype in _F8F6F4_TYPES and b_dtype in _F8F6F4_TYPES:
        mma_op = MmaF8F6F4Op(
            a_dtype,
            b_dtype,
            acc_dtype,
            (*mma_tiler_mn, 32),
            cta_group,
            a_source,
            a_leading_mode,
            b_leading_mode,
        )
    else:
        raise TypeError(
            f"unsupported a_dtype/b_dtype, got a_dtype: {a_dtype}, b_dtype: {b_dtype}"
        )

    return cute.make_tiled_mma(
        cute.make_mma_atom(mma_op, loc=loc, ip=ip), loc=loc, ip=ip
    )


@overload
def make_blockscaled_trivial_tiled_mma(
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    a_leading_mode: OperandMajorMode,
    b_leading_mode: OperandMajorMode,
    sf_dtype: Type[Numeric],
    sf_vec_size: int,
    cta_group: CtaGroup,
    mma_tiler_mn: Tuple[int, int],
    a_source: OperandSource = OperandSource.SMEM,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.TiledMma: ...


@deprecated(
    "use make_blockscaled_trivial_tiled_mma with separate a_dtype and b_dtype instead"
)
@overload
def make_blockscaled_trivial_tiled_mma(
    ab_dtype: Type[Numeric],
    a_leading_mode: OperandMajorMode,
    b_leading_mode: OperandMajorMode,
    sf_dtype: Type[Numeric],
    sf_vec_size: int,
    cta_group: CtaGroup,
    mma_tiler_mn: Tuple[int, int],
    a_source: OperandSource = OperandSource.SMEM,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.TiledMma: ...


@dsl_user_op
def make_blockscaled_trivial_tiled_mma(
    *args: Any,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
    **kwargs: Any,
) -> cute.TiledMma:
    """Make a BlockScaled tiled MMA atom with given data type, leading dimension, cta group and mma tile shape.
    By default, the MMA atom is created with SMEM operand source for A.

    Supports two calling conventions:

    **New (recommended):** separate ``a_dtype`` and ``b_dtype``::

        make_blockscaled_trivial_tiled_mma(
            a_dtype, b_dtype, a_leading_mode, b_leading_mode,
            sf_dtype, sf_vec_size, cta_group, mma_tiler_mn, [a_source])

    **Legacy (deprecated):** single ``ab_dtype``::

        make_blockscaled_trivial_tiled_mma(
            ab_dtype, a_leading_mode, b_leading_mode,
            sf_dtype, sf_vec_size, cta_group, mma_tiler_mn, [a_source])
    """
    import warnings

    new_params = (
        "a_dtype",
        "b_dtype",
        "a_leading_mode",
        "b_leading_mode",
        "sf_dtype",
        "sf_vec_size",
        "cta_group",
        "mma_tiler_mn",
        "a_source",
    )
    legacy_params = (
        "ab_dtype",
        "a_leading_mode",
        "b_leading_mode",
        "sf_dtype",
        "sf_vec_size",
        "cta_group",
        "mma_tiler_mn",
        "a_source",
    )

    is_new_api, bound = _bind_mma_args(
        "make_blockscaled_trivial_tiled_mma",
        args,
        kwargs,
        new_params,
        legacy_params,
    )
    bound.setdefault("a_source", OperandSource.SMEM)

    if not is_new_api:
        warnings.warn(
            "make_blockscaled_trivial_tiled_mma with ab_dtype is deprecated, "
            "use the overload with separate a_dtype and b_dtype instead",
            DeprecationWarning,
            stacklevel=2,
        )
        a_dtype = bound["ab_dtype"]
        b_dtype = bound["ab_dtype"]
    else:
        a_dtype = bound["a_dtype"]
        b_dtype = bound["b_dtype"]

    return _make_blockscaled_trivial_tiled_mma_impl(
        a_dtype,
        b_dtype,
        bound["a_leading_mode"],
        bound["b_leading_mode"],
        bound["sf_dtype"],
        bound["sf_vec_size"],
        bound["cta_group"],
        bound["mma_tiler_mn"],
        bound["a_source"],
        loc=loc,
        ip=ip,
    )


def _make_blockscaled_trivial_tiled_mma_impl(
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    a_leading_mode: OperandMajorMode,
    b_leading_mode: OperandMajorMode,
    sf_dtype: Type[Numeric],
    sf_vec_size: int,
    cta_group: CtaGroup,
    mma_tiler_mn: Tuple[int, int],
    a_source: OperandSource = OperandSource.SMEM,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.TiledMma:
    mma_op: Any
    if a_dtype == Float4E2M1FN and b_dtype == Float4E2M1FN:
        if sf_vec_size == 32:
            mma_op = MmaMXF4Op(
                (*mma_tiler_mn, 64),
                cta_group,
                a_source,
            )
        elif sf_vec_size == 16:
            mma_op = MmaMXF4NVF4Op(
                sf_dtype,
                (*mma_tiler_mn, 64),
                cta_group,
                a_source,
            )
        else:
            raise ValueError(f"unsupported sf_vec_size, got {sf_vec_size}")
    elif a_dtype in _F8F6F4_TYPES and b_dtype in _F8F6F4_TYPES:
        mma_op = MmaMXF8F6F4Op(
            a_dtype,
            b_dtype,
            (*mma_tiler_mn, 32),
            cta_group,
            a_source,
            a_leading_mode,
            b_leading_mode,
        )
    else:
        raise TypeError(
            f"unsupported a_dtype/b_dtype, got a_dtype: {a_dtype}, b_dtype: {b_dtype}"
        )

    return cute.make_tiled_mma(
        cute.make_mma_atom(mma_op, loc=loc, ip=ip), loc=loc, ip=ip
    )


@dsl_user_op
def cluster_shape_to_tma_atom_A(
    cluster_shape_mnk: cute.Shape,
    atom_thr_id: cute.Layout,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[CopyBulkTensorTileG2SMulticastOp, CopyBulkTensorTileG2SOp]:
    """
    Select the appropriate TMA copy atom for A based on the number of SMs and the multicast flag.

    :param cluster_shape_mnk: The shape of the cluster
    :type cluster_shape_mnk: cute.Shape
    :param atom_thr_id: The thread ID of the atom
    :type atom_thr_id: cute.Layout

    :return: The appropriate TMA copy atom kind
    :rtype: cpasync.CopyBulkTensorTileG2SMulticastOp or cpasync.CopyBulkTensorTileG2SOp

    :raise ValueError: If the atom_sm_cnt is invalid
    :raise ValueError: If the cluster shape is not divisible by the atom SM count
    """
    atom_sm_cnt = cute.size(atom_thr_id, loc=loc, ip=ip)
    mcast = not (cute.size(cluster_shape_mnk, mode=[1], loc=loc, ip=ip) == 1)
    cluster_size = cute.size(cluster_shape_mnk, loc=loc, ip=ip)

    if not isinstance(cluster_size, int) or not isinstance(atom_sm_cnt, int):
        raise ValueError(
            f"Dynamic cluster shape or atom SM count is not supported: {cluster_shape_mnk} and {atom_thr_id}"
        )

    if cute.size(cluster_shape_mnk, mode=[0], loc=loc, ip=ip) % atom_sm_cnt != 0:
        raise ValueError(
            f"Cluster shape not divisible by MMA size: {cluster_shape_mnk} and {atom_thr_id}"
        )

    if atom_sm_cnt == 2 and mcast:
        return CopyBulkTensorTileG2SMulticastOp(CtaGroup.TWO)
    elif atom_sm_cnt == 2 and not mcast:
        return CopyBulkTensorTileG2SOp(CtaGroup.TWO)
    elif atom_sm_cnt == 1 and mcast:
        return CopyBulkTensorTileG2SMulticastOp(CtaGroup.ONE)
    elif atom_sm_cnt == 1 and not mcast:
        return CopyBulkTensorTileG2SOp(CtaGroup.ONE)

    raise ValueError(
        f"Unsupported Configuration for SM100 TMA: {cluster_shape_mnk} and {atom_thr_id}"
    )


@dsl_user_op
def cluster_shape_to_tma_atom_B(
    cluster_shape_mnk: cute.Shape,
    atom_thr_id: cute.Layout,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[CopyBulkTensorTileG2SMulticastOp, CopyBulkTensorTileG2SOp]:
    """
    Select the appropriate TMA copy atom for Bbased on the number of SMs and the multicast flag.

    :param cluster_shape_mnk: The shape of the cluster
    :type cluster_shape_mnk: cute.Shape
    :param atom_thr_id: The thread ID of the atom
    :type atom_thr_id: cute.Layout

    :return: The appropriate TMA copy atom kind
    :rtype: cpasync.CopyBulkTensorTileG2SMulticastOp or cpasync.CopyBulkTensorTileG2SOp

    :raise ValueError: If the atom_sm_cnt is invalid
    :raise ValueError: If the cluster shape is not divisible by the atom SM count
    """
    atom_sm_cnt = cute.size(atom_thr_id, loc=loc, ip=ip)
    mcast = not (cute.size(cluster_shape_mnk, mode=[0], loc=loc, ip=ip) == atom_sm_cnt)
    cluster_size = cute.size(cluster_shape_mnk, loc=loc, ip=ip)

    if not isinstance(cluster_size, int) or not isinstance(atom_sm_cnt, int):
        raise ValueError(
            f"Dynamic cluster shape or atom SM count is not supported: {cluster_shape_mnk} and {atom_thr_id}"
        )

    if cute.size(cluster_shape_mnk, mode=[0], loc=loc, ip=ip) % atom_sm_cnt != 0:
        raise ValueError(
            f"Cluster shape not divisible by MMA size: {cluster_shape_mnk} and {atom_thr_id}"
        )

    if atom_sm_cnt == 2 and mcast:
        return CopyBulkTensorTileG2SMulticastOp(CtaGroup.TWO)
    elif atom_sm_cnt == 2 and not mcast:
        return CopyBulkTensorTileG2SOp(CtaGroup.TWO)
    elif atom_sm_cnt == 1 and mcast:
        return CopyBulkTensorTileG2SMulticastOp(CtaGroup.ONE)
    elif atom_sm_cnt == 1 and not mcast:
        return CopyBulkTensorTileG2SOp(CtaGroup.ONE)

    raise ValueError(
        f"Unsupported Configuration for SM100 TMA: {cluster_shape_mnk} and {atom_thr_id}"
    )


@dsl_user_op
def cluster_shape_to_tma_atom_SFB(
    cluster_shape_mnk: cute.Shape,
    atom_thr_id: cute.Layout,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[CopyBulkTensorTileG2SMulticastOp, CopyBulkTensorTileG2SOp]:
    """
    Select the appropriate TMA copy atom for SFB based on the number of SMs and the multicast flag.

    :param cluster_shape_mnk: The shape of the cluster
    :type cluster_shape_mnk: cute.Shape
    :param atom_thr_id: The thread ID of the atom
    :type atom_thr_id: cute.Layout

    :return: The appropriate TMA copy atom kind
    :rtype: cpasync.CopyBulkTensorTileG2SMulticastOp or cpasync.CopyBulkTensorTileG2SOp

    :raise ValueError: If the atom_sm_cnt is invalid
    :raise ValueError: If the cluster shape is not divisible by the atom SM count
    """
    atom_sm_cnt = cute.size(atom_thr_id, loc=loc, ip=ip)
    mcast = not (cute.size(cluster_shape_mnk, mode=[0], loc=loc, ip=ip) == 1)
    cluster_size = cute.size(cluster_shape_mnk, loc=loc, ip=ip)

    if not isinstance(cluster_size, int) or not isinstance(atom_sm_cnt, int):
        raise ValueError(
            f"Dynamic cluster shape or atom SM count is not supported: {cluster_shape_mnk} and {atom_thr_id}"
        )

    if cute.size(cluster_shape_mnk, mode=[0], loc=loc, ip=ip) % atom_sm_cnt != 0:
        raise ValueError(
            f"Cluster shape not divisible by MMA size: {cluster_shape_mnk} and {atom_thr_id}"
        )

    if atom_sm_cnt == 2:
        return CopyBulkTensorTileG2SMulticastOp(CtaGroup.TWO)
    elif atom_sm_cnt == 1 and mcast:
        return CopyBulkTensorTileG2SMulticastOp(CtaGroup.ONE)
    elif atom_sm_cnt == 1 and not mcast:
        return CopyBulkTensorTileG2SOp(CtaGroup.ONE)

    raise ValueError(
        f"Unsupported Configuration for SM100 TMA: {cluster_shape_mnk} and {atom_thr_id}"
    )


@dsl_user_op
def sm120_get_smem_store_op(
    layout_d: LayoutEnum,
    elem_ty_d: Type[Numeric],
    elem_ty_acc: Type[Numeric],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
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

    def validate_type(ty: Type[Numeric], ty_name: str) -> None:
        if not isinstance(ty, NumericMeta):
            raise TypeError(f"{ty_name} must be a Numeric, but got {ty}")

    validate_type(elem_ty_d, "elem_ty_d")
    validate_type(elem_ty_acc, "elem_ty_acc")

    is_m_major = layout_d.is_m_major_c()

    if elem_ty_d.width == 16:
        return cute.make_copy_atom(
            StMatrix8x8x16bOp(is_m_major, 2), elem_ty_d, loc=loc, ip=ip
        )
    else:
        return cute.make_copy_atom(CopyUniversalOp(), elem_ty_d, loc=loc, ip=ip)


@dsl_user_op
def get_permutation_mnk(
    tile_shape_mnk: cute.Shape,
    sf_vec_size: int,
    use_mxf8f6f4: bool,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[int, int, int]:
    """
    Get the permutation of M, N, K for the tiled MMA.

    :param tile_shape_mnk: The shape of the tile
    :type tile_shape_mnk: cute.Shape
    :param sf_vec_size: The vector size of the Scale Factor.
    :type sf_vec_size: int
    :param use_mxf8f6f4: Whether to use MXF8F6F4 or MXF4NVF4.
    :type use_mxf8f6f4: bool

    :return: The permutation of M, N, K
    :rtype: Tuple[int, int, int]

    :raise ValueError: If the tile shape is not divisible by the sf_vec_size
    """
    perm_m = min(tile_shape_mnk[0], 128)  # type: ignore[index]
    # refer to C++ code:
    # /include/cutlass/gemm/collective/builders/sm120_common.inl?ref_type=heads#L158
    if sf_vec_size == 32 or sf_vec_size == 16:
        perm_n_shape = (8, 2, 2)
        perm_n_stride = (1, 16, 8)
    else:
        raise ValueError(f"Unsupported sf_vec_size, got {sf_vec_size}")

    perm_n_layout = cute.make_layout(perm_n_shape, stride=perm_n_stride)
    perm_k = 32 if use_mxf8f6f4 else 64
    permutation_mnk = (
        perm_m,
        perm_n_layout,
        perm_k,
    )

    return permutation_mnk  # type: ignore[return-value]


def sm103_make_blockscaled_trivial_tiled_mma(
    sf_dtype: Type[Numeric],
    sf_vec_size: int,
    cta_group: CtaGroup,
    mma_tiler_mn: Tuple[int, int],
    a_source: OperandSource = OperandSource.SMEM,
) -> cute.TiledMma:
    """Create a blockscaled trivial tiled MMA for SM103 (Ultra FP4), K fixed to 96.

    Returns a tcgen05 MMA configured for the given (M, N) tiler and CTA group.

    :param sf_dtype: Data type of the scale factor (typically 8-bit)
    :type sf_dtype: Type[Numeric]
    :param sf_vec_size: The vector size of the scale factor
    :type sf_vec_size: int
    :param cta_group: The CTA group configuration
    :type cta_group: CtaGroup
    :param mma_tiler_mn: The MMA tiler dimensions (M, N)
    :type mma_tiler_mn: Tuple[int, int]
    :param a_source: Source location for operand A (SMEM by default)
    :type a_source: OperandSource

    :return: A tiled MMA atom configured for SM103 blockscaled operations
    :rtype: cute.TiledMma

    :raises TypeError: If the data type is not supported.
    :raises ValueError: If the sf_vec_size is not supported.
    """
    mma_op: Any
    if sf_vec_size == 32:
        mma_op = SM103MmaMXF4Op(
            (*mma_tiler_mn, 96),
            cta_group,
            a_source,
        )
    elif sf_vec_size == 16:
        mma_op = SM103MmaMXF4NVF4Op(
            sf_dtype,
            (*mma_tiler_mn, 96),
            cta_group,
            a_source,
        )
    else:
        raise ValueError(f"Unsupported sf_vec_size: {sf_vec_size}. Expected 16 or 32.")
    return cute.make_tiled_mma(cute.make_mma_atom(mma_op))


@dsl_user_op  # type: ignore[no-redef]
def sm120_get_smem_store_op(
    layout_d: LayoutEnum,
    elem_ty_d: Type[Numeric],
    elem_ty_acc: Type[Numeric],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
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

    def validate_type(ty: Type[Numeric], ty_name: str) -> None:
        if not isinstance(ty, NumericMeta):
            raise TypeError(f"{ty_name} must be a Numeric, but got {ty}")

    validate_type(elem_ty_d, "elem_ty_d")
    validate_type(elem_ty_acc, "elem_ty_acc")

    is_m_major = layout_d.is_m_major_c()

    if elem_ty_d.width == 16:
        return cute.make_copy_atom(
            StMatrix8x8x16bOp(is_m_major, 2), elem_ty_d, loc=loc, ip=ip
        )
    else:
        return cute.make_copy_atom(CopyUniversalOp(), elem_ty_d, loc=loc, ip=ip)



def compute_epilogue_tile_size(
    cta_tile_m: int,
    cta_tile_n: int,
    use_2cta: bool,
    elem_width_d: int,
    elem_width_c: int | None = None,
    d_is_m_major: bool = True,
    c_is_m_major: bool = True,
) -> tuple[int, int]:
    """Compute epilogue subtile dimensions ``(tile_m, tile_n)`` (pure Python, no MLIR).

    Used by :func:`compute_epilogue_tile_shape` and at kernel-discovery time
    for SMEM capacity estimation.  Must match the C++ logic in
    ``cutlass/include/cutlass/epilogue/collective/builders/sm100_builder.inl``
    (the ``EpilogueTileAuto`` branch) and
    ``cutlass_ir/compiler/lib/Collective/SM100.cpp``
    (``sm100_compute_tile_shape_or_override``).

    Background – SM100 epilogue flow
    ---------------------------------
    After the MMA, the accumulator lives in **TMEM** (Tensor Memory, 128
    datapaths x N columns).  The epilogue:

    1. Loads a subtile from TMEM into registers (``tcgen05.tmem_load``).
    2. Optionally loads a source tile C from GMEM -> SMEM -> registers.
    3. Applies the fusion (bias, activation, ...) in registers.
    4. Stores the result D to SMEM, then to GMEM via TMA.

    The full CTA output (``cta_tile_m x cta_tile_n``) is processed in
    multiple **epilogue iterations**, each covering one subtile of shape
    ``(tile_m, tile_n)``.  Each subtile is worked on by 4 warps arranged
    in a ``(warp_m, warp_n)`` grid.

    This function picks ``(tile_m, tile_n)`` to balance three constraints:

    * **TMEM load** only supports 16 or 32 datapaths per warp, which
      caps ``tile_m``.
    * **TMA store alignment** requires a minimum contiguous transaction
      size, which sets ``n_min`` floors.
    * **SMEM budget** -- the epilogue subtile lives in SMEM alongside the
      mainloop's A/B pipeline buffers.  A larger subtile means fewer
      epilogue iterations (good) but steals SMEM from the mainloop,
      reducing pipeline depth (bad).  ``n_perf`` targets the sweet spot
      found by benchmarking.

    Algorithm
    ---------
    1. **Warp grid** ``(warp_m, warp_n)``:

       * ``(2, 2)`` when ``use_2cta and cta_tile_m == 64`` -- each of
         the 2 M-warps gets 32 datapaths.
       * ``(4, 1)`` otherwise -- 4 warps split M, each gets
         ``tile_m / 4`` datapaths (16 or 32).

    2. **tile_m** ``= min(cta_tile_m, 32 * warp_m)``

       ``32`` is ``dp_full``, the number of TMEM datapaths in one
       subpartition (hardware constant).  Capping here ensures each
       warp owns at most 32 datapaths, which is the widest mode the
       ``tcgen05.tmem_load`` instruction supports.

    3. **n_perf** -- performance target for N:

       * **Without source C** (elementwise-only epilogue): SMEM pressure
         is low because there is no C tile to stage.  Target a fixed
         element count per iteration so that each iteration does enough
         work to amortise the epilogue overhead.  The constants are::

             4096 elements  (general)  -> e.g. tile_m=128, n=32
             8192 elements  (4-bit)    -> e.g. tile_m=128, n=64

         4-bit elements are half a byte each, so doubling the count
         keeps roughly the same SMEM footprint while cutting epilogue
         iterations in half (experimentally best for 4-bit types).

       * **With source C** (residual-load epilogue): the source tile C
         also occupies SMEM, so the epilogue tile must be smaller to
         leave room for mainloop A/B pipeline stages.  Targets are
         chosen by element width and CTA shape to balance SMEM
         partitioning::

             32-bit elements: n=16 when M>64 and N<=128, else n=32
             16-bit elements: n=32 when N<=128, else n=64
             <=8-bit elements: n=64

         Wider elements consume more bytes per element, so N is
         reduced to stay within the SMEM budget.  When CTA N is
         large (>128), N is increased because the mainloop tile is
         also large and SMEM is more abundant.

       After choosing, ``n_perf`` is halved until it evenly divides
       ``cta_tile_n`` (ensures the CTA output tiles evenly into
       subtiles with no ragged remainder).

    4. **n_min_d, n_min_c** -- hard minimums from TMA store alignment:

       * **M-major** (contiguous dim is M): ``8 * warp_n``.  N is the
         strided dimension so the minimum is small (8 elements per
         warp is enough for the store to issue).
       * **N-major** (contiguous dim is N): each TMA store transaction
         is 128 bits wide, so the minimum contiguous N per warp is
         ``128 / elem_width`` elements, times ``warp_n`` warps.
       * **FP6 special case**: TMA store only supports the SW128B
         swizzle mode for 6-bit types, requiring 128 contiguous
         elements per warp, i.e. ``128 * warp_n``.

    5. **tile_n** ``= min(cta_tile_n, max(n_perf, n_min_c, n_min_d))``.

       If the chosen N doesn't evenly divide ``cta_tile_n``, fall back
       to ``cta_tile_n`` (process the full N in one iteration).

    :param cta_tile_m: Per-CTA tile size in M.
    :param cta_tile_n: Per-CTA tile size in N.
    :param use_2cta: True when 2-CTA (2-SM) MMA instructions are used.
    :param elem_width_d: Bit-width of output element type D (e.g. 16).
    :param elem_width_c: Bit-width of source element type C, or ``None``
        if the epilogue has no source (elementwise-only).
    :param d_is_m_major: ``True`` if D is column-major (M-contiguous).
    :param c_is_m_major: ``True`` if C is column-major (M-contiguous).
    :return: ``(tile_m, tile_n)`` -- epilogue subtile dimensions.
    """
    # -- Step 1: warp grid ------------------------------------------------
    # (2,2) for 2CTA+M64 so each warp gets 32 rows; else (4,1).
    (warp_m, warp_n) = (2, 2) if (cta_tile_m == 64 and use_2cta) else (4, 1)
    disable_source = elem_width_c is None
    max_bits = elem_width_d if disable_source else max(elem_width_c, elem_width_d)  # type: ignore[type-var]

    # -- Step 2: tile_m ---------------------------------------------------
    # 32 datapaths per subpartition (hardware constant); cap so each warp
    # owns <=32 datapaths, the widest tcgen05.tmem_load mode.
    dp_full = 32
    tile_m = min(cta_tile_m, dp_full * warp_m)

    # -- Step 3: n_perf (performance target for N) ------------------------
    if disable_source:
        # No source C: SMEM pressure is low.  Target a fixed element count
        # per iteration to amortise epilogue overhead.
        # 4-bit: doubled to 8192 to cut iterations while keeping same SMEM bytes.
        compute_elts = 8192 if max_bits == 4 else 4096
        n_perf = compute_elts // tile_m
    else:
        # With source C: SMEM must also hold the C tile.  Smaller N leaves
        # more SMEM for mainloop A/B pipeline stages.
        if max_bits == 32:
            n_perf = 16 if (cta_tile_m > 64 and cta_tile_n <= 128) else 32
        elif max_bits == 16:
            n_perf = 32 if cta_tile_n <= 128 else 64
        else:
            n_perf = 64

    # Ensure n_perf evenly divides cta_tile_n (no ragged last subtile).
    while cta_tile_n % n_perf != 0:
        n_perf //= 2

    # -- Step 4: n_min (TMA store alignment floors) -----------------------
    # M-major: N is strided -> small minimum (8 elems * warp_n).
    # N-major: N is contiguous -> 128-bit TMA granularity -> 128/width * warp_n.
    # FP6: TMA store only supports SW128B -> 128 * warp_n.
    n_min_d = (
        8 * warp_n
        if d_is_m_major
        else (128 * warp_n if elem_width_d == 6 else 128 // elem_width_d * warp_n)
    )
    n_min_c = (
        8 * warp_n
        if (c_is_m_major or disable_source)
        else (128 * warp_n if elem_width_c == 6 else 128 // elem_width_c * warp_n)  # type: ignore[operator]
    )

    # -- Step 5: tile_n ---------------------------------------------------
    tile_n = min(cta_tile_n, max(n_perf, n_min_c, n_min_d))
    # If the final tile_n doesn't divide cta_tile_n, fall back to full N.
    if cta_tile_n % tile_n != 0:
        tile_n = cta_tile_n

    return (tile_m, tile_n)


def compute_acc_tmem_cols_per_stage(
    cta_tile_m: int,
    cta_tile_n: int,
    use_2cta: bool,
    mma_n: int,
    transform_a_source_is_tmem: bool,
) -> int:
    """
    Compute the accumulator TMEM column footprint for one pipeline stage.

    Returns the **raw** layout footprint — the caller must enforce hardware
    allocation constraints (min 32 columns, power-of-2 total) at the final
    ``alloc_tmem`` call site.  See ``TmemAllocator.check_valid_num_columns``
    in ``cutlass/utils/tmem_allocator.py``.

    Replicates the C++ logic from without requiring an
    MLIR context, so it can be used at kernel discovery time.  When an
    MLIR context is available, prefer
    ``cutlass.cute.nvgpu.tcgen05.find_tmem_tensor_col_offset`` which
    computes the column count directly from the compiler-generated
    TMEM layout.

    **How TMEM packing works**

    TMEM has 128 datapaths (rows).  M maps to datapaths, N maps to
    columns.  When fewer than 128 DPs are needed, multiple N-values can
    share a column by occupying different DP rows::

        NonInterleaved (each N-tile owns its columns):

            columns 0..N-1       columns N..2N-1
            ┌────────────────┐  ┌────────────────┐
        DP  │ ████ tile 0    │  │ ████ tile 1    │  ← 64 DPs used
        0-  │                │  │                │
        127 │ ···· unused    │  │ ···· unused    │  ← 64 DPs wasted
            └────────────────┘  └────────────────┘
            Total: 2N columns

        Interleaved (pairs of N-tiles share columns):

            columns 0..N-1
            ┌────────────────┐
        DP  │ ████ tile 0    │  ← DPs 0-15, 32-47, 64-79, 96-111
        0-  │ ▓▓▓▓ tile 1    │  ← DPs 16-31, 48-63, 80-95, 112-127
        127 │                │
            └────────────────┘
            Total: N columns  (halved)

    For **1CTA**, the accumulator uses Interleaved when A is from SMEM
    *and* ``cta_tile_m`` == 64.  NonInterleaved is forced when
    ``cta_tile_m`` == 128 (all datapaths already occupied) or when A is
    from TMEM (each datapath can only access its own row, so A and C
    must share the same M-to-datapath mapping).

    For **2CTA**, each SM has its own 128-DP TMEM and the fragment layout
    is computed for the per-CTA shape (M = ``cta_tile_m``, which the
    caller must set to the per-CTA value).  Because ``cta_tile_m`` only
    occupies part of the 128 DPs, the remaining rows can hold additional
    N-values in the same column.  The number of N-values that share a
    column is 128 / ``cta_tile_m``, so the columns needed are
    ``cta_tile_n`` / (128 / ``cta_tile_m``):

    - ``cta_tile_m`` = 32  → 128/32 = 4 per column → ``cta_tile_n`` / 4
    - ``cta_tile_m`` = 64  → 128/64 = 2 per column → ``cta_tile_n`` / 2
    - ``cta_tile_m`` = 128 → 128/128 = 1 (no sharing) → ``cta_tile_n``

    :param cta_tile_m: Per-CTA tile size in M dimension (for 2CTA the
        caller divides the full tile M by 2).
    :param cta_tile_n: CTA tile size in N dimension.
    :param use_2cta: Whether 2CTA MMA instructions are used.
    :param mma_n: MMA atom size in N dimension.
    :param transform_a_source_is_tmem: Whether operand A is sourced from
        TMEM (forces NonInterleaved allocation).
    :return: TMEM columns per accumulator stage (before HW constraints).
    """
    if use_2cta:
        if cta_tile_m <= 32:
            return cta_tile_n // 4
        elif cta_tile_m <= 64:
            return cta_tile_n // 2
        else:
            return cta_tile_n
    else:
        # Interleaved when (A from SMEM) and (M == 64)
        # NonInterleaved otherwise
        is_interleaved = (not transform_a_source_is_tmem) and (cta_tile_m == 64)
        if is_interleaved:
            num_n_tiles = cta_tile_n // mma_n
            packed_groups = (num_n_tiles + 1) // 2
            return packed_groups * mma_n
        else:
            return cta_tile_n


def thrfrg_SFA(
    sfa_tensor: cute.Tensor,
    tiled_mma: cute.TiledMma,
) -> cute.Tensor:
    """Thread-fragment scale factor A tensor for SM120 block-scaled MMA.

    Implements the ThrFrg partitioning for scale factor A according to the
    corresponding C++ code.
    """
    assert cute.rank(sfa_tensor) >= 2

    atom_shape_mnk = tiled_mma.shape_mnk
    atom_sfa_layout = cute.make_layout(shape=((2, 2, 8), 64), stride=((8, 0, 1), 16))
    permutation_mnk = tiled_mma.permutation_mnk
    thr_layout_vmnk = tiled_mma.thr_layout_vmnk

    # Reorder the tensor for TiledAtom
    t_tile = (permutation_mnk[0], permutation_mnk[2])
    t_tensor = cute.logical_divide(sfa_tensor, t_tile)

    # Tile the tensor for the Atom
    a_tile = (
        cute.make_layout((atom_shape_mnk[0])),
        cute.make_layout((atom_shape_mnk[2])),
    )
    a_tensor = cute.zipped_divide(t_tensor, a_tile)

    # Transform the Atom mode from (M,K) to (Thr,Val)
    tv_tensor = cute.composition(a_tensor, (atom_sfa_layout, None))

    # Tile the tensor for the Thread
    thr_tile = (
        None,
        (
            cute.make_layout(cute.size(thr_layout_vmnk[1])),
            cute.make_layout(cute.size(thr_layout_vmnk[3])),
        ),
    )

    thr_tensor = cute.zipped_divide(tv_tensor, thr_tile)

    return thr_tensor


def thrfrg_SFB(
    sfb_tensor: cute.Tensor,
    tiled_mma: cute.TiledMma,
) -> cute.Tensor:
    """Thread-fragment scale factor B tensor for SM120 block-scaled MMA.

    Implements the ThrFrg partitioning for scale factor B according to the
    corresponding C++ code.
    """
    assert cute.rank(sfb_tensor) >= 2

    atom_shape_mnk = tiled_mma.shape_mnk
    atom_sfb_layout = cute.make_layout(shape=((4, 8), 64), stride=((0, 1), 8))
    permutation_mnk = tiled_mma.permutation_mnk
    thr_layout_vmnk = tiled_mma.thr_layout_vmnk

    # Reorder the tensor for TiledAtom
    t_tile = (permutation_mnk[1], permutation_mnk[2])
    t_tensor = cute.logical_divide(sfb_tensor, t_tile)

    # Tile the tensor for the Atom
    a_tile = (
        cute.make_layout((atom_shape_mnk[1])),
        cute.make_layout((atom_shape_mnk[2])),
    )
    a_tensor = cute.zipped_divide(t_tensor, a_tile)

    # Transform the Atom mode from (M,K) to (Thr,Val)
    tv_tensor = cute.composition(a_tensor, (atom_sfb_layout, None))

    # Tile the tensor for the Thread
    thr_tile = (
        None,
        (
            cute.make_layout(cute.size(thr_layout_vmnk[2])),
            cute.make_layout(cute.size(thr_layout_vmnk[3])),
        ),
    )

    thr_tensor = cute.zipped_divide(tv_tensor, thr_tile)

    return thr_tensor


def partition_fragment_SFA(
    sfa_tensor: cute.Tensor,
    thr_mma: cute.ThrMma,
    tidx: int,
) -> cute.Tensor:
    """Partition and create a register fragment for scale factor A."""
    thrfrg_sfa_layout = thrfrg_SFA(sfa_tensor.layout, thr_mma)  # type: ignore[arg-type]
    thr_tensor = cute.make_tensor(sfa_tensor.iterator, thrfrg_sfa_layout)
    thr_vmnk = thr_mma.thr_layout_vmnk.get_flat_coord(tidx)
    thr_vmk = (thr_vmnk[0], (thr_vmnk[1], thr_vmnk[3]))
    partitioned_sfa = thr_tensor[thr_vmk, (None, None)]
    partitioned_sfa = cute.group_modes(cute.flatten(partitioned_sfa), 0, 2)
    return cute.make_fragment_like(partitioned_sfa)


def partition_fragment_SFB(
    sfb_tensor: cute.Tensor,
    thr_mma: cute.ThrMma,
    tidx: int,
) -> cute.Tensor:
    """Partition and create a register fragment for scale factor B."""
    thrfrg_sfb_layout = thrfrg_SFB(sfb_tensor.layout, thr_mma)  # type: ignore[arg-type]
    thr_tensor = cute.make_tensor(sfb_tensor.iterator, thrfrg_sfb_layout)
    thr_vmnk = thr_mma.thr_layout_vmnk.get_flat_coord(tidx)
    thr_vnk = (thr_vmnk[0], (thr_vmnk[2], thr_vmnk[3]))
    partitioned_sfb = thr_tensor[thr_vnk, (None, None)]
    partitioned_sfb = cute.group_modes(cute.flatten(partitioned_sfb), 0, 2)
    partitioned_sfb = cute.group_modes(partitioned_sfb, 1, 3)
    return cute.make_fragment_like(partitioned_sfb)


def get_layoutSFA_TV(tiled_mma: cute.TiledMma) -> cute.Layout:
    """Get the Thread-Value layout for scale factor A."""
    if tiled_mma.permutation_mnk is not None:
        perm_m = tiled_mma.permutation_mnk[0]
        perm_k = tiled_mma.permutation_mnk[2]
        tile_m = cute.size(perm_m)
        tile_k = cute.size(perm_k)
    else:
        tile_shape_mnk = tiled_mma.shape_mnk * tiled_mma.thr_layout_vmnk
        tile_m = cute.size(tile_shape_mnk[0])
        tile_k = cute.size(tile_shape_mnk[2])

    ref_A = cute.make_layout((tile_m, tile_k))
    thr_layout_vmnk = tiled_mma.thr_layout_vmnk

    # (ThrV, (ThrM, ThrK)) -> (ThrV, (ThrM, ThrN, ThrK))
    atile = (
        None,
        (
            cute.make_layout(
                shape=(
                    cute.size(thr_layout_vmnk[1]),
                    cute.size(thr_layout_vmnk[2]),
                ),
                stride=(1, 0),
            ),
            None,
        ),
    )

    # thr_idx -> (ThrV,ThrM,ThrN,ThrK)
    thridx_2_thrid = cute.right_inverse(thr_layout_vmnk)
    thrfrg_sfa = thrfrg_SFA(ref_A, tiled_mma)
    layout_tv_1 = cute.composition(thrfrg_sfa, (atile, None))
    layout_tv = cute.composition(layout_tv_1, (thridx_2_thrid, None))

    return layout_tv  # type: ignore[return-value]


def get_layoutSFB_TV(tiled_mma: cute.TiledMma) -> cute.Layout:
    """Get the Thread-Value layout for scale factor B."""
    if tiled_mma.permutation_mnk is not None:
        perm_n_layout = tiled_mma.permutation_mnk[1]
        perm_k = tiled_mma.permutation_mnk[2]
        tile_n = cute.size(perm_n_layout)
        tile_k = cute.size(perm_k)
    else:
        tile_shape_mnk = tiled_mma.shape_mnk * tiled_mma.thr_layout_vmnk
        tile_n = cute.size(tile_shape_mnk[1])
        tile_k = cute.size(tile_shape_mnk[2])

    ref_B = cute.make_layout((tile_n, tile_k))
    thr_layout_vmnk = tiled_mma.thr_layout_vmnk

    # (ThrV, (ThrM, ThrK)) -> (ThrV, (ThrM, ThrN, ThrK))
    atile = (
        None,
        (
            cute.make_layout(
                shape=(
                    cute.size(thr_layout_vmnk[1]),
                    cute.size(thr_layout_vmnk[2]),
                ),
                stride=(0, 1),
            ),
            None,
        ),
    )

    # thr_idx -> (ThrV,ThrM,ThrN,ThrK)
    thridx_2_thrid = cute.right_inverse(thr_layout_vmnk)
    thrfrg_sfb = thrfrg_SFB(ref_B, tiled_mma)
    layout_tv = cute.composition(thrfrg_sfb, (atile, None))
    layout_tv = cute.composition(layout_tv, (thridx_2_thrid, None))
    return layout_tv  # type: ignore[return-value]


__all__ = [
    "compute_epilogue_tile_size",
    "compute_acc_tmem_cols_per_stage",
    "compute_epilogue_tile_shape",
    "get_smem_store_op",
    "get_tmem_load_op",
    "make_smem_layout_a",
    "make_smem_layout_b",
    "make_smem_layout_epi",
    "make_trivial_tiled_mma",
    "make_blockscaled_trivial_tiled_mma",
    "cluster_shape_to_tma_atom_A",
    "cluster_shape_to_tma_atom_B",
    "cluster_shape_to_tma_atom_SFB",
    "get_permutation_mnk",
    "get_num_tmem_alloc_cols",  # deprecated; use cutlass.utils.get_num_tmem_alloc_cols instead
    "thrfrg_SFA",
    "thrfrg_SFB",
    "partition_fragment_SFA",
    "partition_fragment_SFB",
    "get_layoutSFA_TV",
    "get_layoutSFB_TV",
]
