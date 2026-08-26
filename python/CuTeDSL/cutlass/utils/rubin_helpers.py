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


"""
SM107 (Rubin) specific helper functions for blockscaled GEMM kernels.

This module provides Rubin-specific implementations that derive from or extend
the Blackwell (SM100) helpers. Key differences for Rubin:
- Extended SMEM capacity: 334848 bytes (328 KB) vs 232448 bytes (228 KB)
- Extended TMEM capacity: 576 columns vs 512 columns (256 KB)
- K blocksize: 64 (2 scale factors per row/col) vs 32 (1 scale factor per row/col)
"""

from typing import Any, Optional, Type, Union, Tuple, NamedTuple, cast

from cutlass._mlir import ir

from cutlass.cutlass_dsl import (
    Float16,
    BFloat16,
    Float4E2M1FN,
    Float6E3M2FN,
    Float6E2M3FN,
    TFloat32,
    Float32,
    Uint8,
    Int8,
    Float8E4M3FN,
    Float8E5M2,
    Numeric,
    dsl_user_op,
)

import cutlass.cute as cute
from cutlass.cute.nvgpu import OperandMajorMode
from cutlass.cute.nvgpu.tcgen05 import (
    MmaF16BF16Op,
    MmaTF32Op,
    SM107MmaFP8Op,
    SM107MmaMXF4NVF4Op,
    SM107BlockScaledMmaMXF8F6F4Op,
    Tcgen05MmaOp,
    CollectorOp,
    Field,
    CtaGroup,
    OperandSource as Tcgen05OperandSource,
    tile_to_mma_shape,
)
from cutlass.cute.nvgpu.warp.mma import SparseMetadataFormat
from cutlass.tensor_utils import LayoutEnum
from cutlass.utils import blackwell_helpers as sm100_utils

OperandSource = Tcgen05OperandSource


_RUBIN_RESOURCE_ARCH_BY_BASE_ARCH = {
    "sm_107": "sm_107",
}


def canonicalize_rubin_resource_arch(arch: str) -> str:
    """Return the base Rubin architecture key used by SMEM/TMEM resource maps."""
    from cutlass import base_dsl

    try:
        arch_enum = base_dsl.Arch.from_string(arch)
        return _RUBIN_RESOURCE_ARCH_BY_BASE_ARCH[
            f"sm_{arch_enum.major}{arch_enum.minor}"
        ]
    except KeyError as exc:
        raise ValueError(f"Unsupported Rubin resource architecture: {arch}") from exc


@dsl_user_op
def compute_epilogue_tile_shape(
    mma_op: Tcgen05MmaOp,
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

    :param mma_op: tcgen05 MMA operation
    :type Tcgen05MmaOp
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

    :return: Returns epilogue tiler, which is used in subsequent epilogue partitions.
    :rtype: cute.Tile
    """

    # The following special cases can be found in sm107_blockscaled_compute_tile_shape_or_override
    # TODO: Add other variants of blockscaled operations once they are defined
    if isinstance(mma_op, SM107MmaMXF4NVF4Op):

        class Sm107TileEntry(NamedTuple):
            a_bits: int
            b_bits: int
            vec_size: int
            cta_m: int
            cta_n: int
            is_2cta: bool

        SM107_TILES = {
            Sm107TileEntry(4, 4, 32, 128, 256, True): (128, 64),
            Sm107TileEntry(4, 4, 32, 256, 256, True): (128, 64),
            Sm107TileEntry(4, 4, 16, 128, 256, True): (128, 32),
            Sm107TileEntry(4, 4, 16, 256, 256, True): (128, 64),
        }

        key = Sm107TileEntry(
            mma_op.a_dtype.width,
            mma_op.b_dtype.width,
            mma_op.sf_vec_size,
            cta_tile_shape[0],  # type: ignore[index, arg-type]
            cta_tile_shape[1],  # type: ignore[index, arg-type]
            use_2cta_instrs,
        )

        if key in SM107_TILES:
            return SM107_TILES[key]

    return sm100_utils.compute_epilogue_tile_shape(
        cta_tile_shape,
        use_2cta_instrs,
        layout_d,
        elem_ty_d,
        layout_c=layout_c,
        elem_ty_c=elem_ty_c,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_trivial_tiled_mma(
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    a_leading_mode: OperandMajorMode,
    b_leading_mode: OperandMajorMode,
    acc_dtype: Type[Numeric],
    cta_group: CtaGroup,
    mma_tiler: Tuple[int, int, int],
    atom_layout_mnk: Tuple[int, int, int] = (1, 1, 1),
    permutation_mnk: Optional[Tuple[int, int, int]] = None,
    a_source: OperandSource = OperandSource.SMEM,
    a_collector_op: Union[CollectorOp, str] = CollectorOp.DISCARD,
    b_collector_op: Union[CollectorOp, str] = CollectorOp.DISCARD,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.TiledMma:
    """Make a tiled MMA atom with given data type, leading dimension, cta group and mma tile shape.
    By default, the MMA atom is created with SMEM operand source for A.

    This SM107 (Rubin) version supports collector operations for advanced TMEM management.

    :param a_dtype: Data type of operand A.
    :type a_dtype: type[Numeric]
    :param b_dtype: Data type of operand B.
    :type b_dtype: type[Numeric]
    :param a_leading_mode: Leading dimension of operand A (1 for K, 0 for M/N).
    :type a_leading_mode: cutlass.cute.nvgpu.OperandMajorMode
    :param b_leading_mode: Leading dimension of operand B (1 for K, 0 for M/N).
    :type b_leading_mode: cutlass.cute.nvgpu.OperandMajorMode
    :param acc_dtype: Data type of the accumulator.
    :type acc_dtype: type[Numeric]
    :param cta_group: The CTA group to use.
    :type cta_group: tcgen05.CtaGroup
    :param mma_tiler: The shape (M, N, K) of the MMA tiler. K can be 32 or 64.
    :type mma_tiler: Tuple[int, int, int]
    :param a_source: The source of operand A (SMEM by default or TMEM).
    :type a_source: cutlass.cute.nvgpu.tcgen05.OperandSource
    :param a_collector_op: Collector operation for operand A (DISCARD by default).
    :type a_collector_op: cutlass.cute.nvgpu.tcgen05.CollectorOp | str
    :param b_collector_op: Collector operation for operand B (DISCARD by default).
    :type b_collector_op: cutlass.cute.nvgpu.tcgen05.CollectorOp | str

    :return: A tiled MMA atom.
    :rtype: cute.TiledMma

    :raises TypeError: If the data type is not supported.
    """

    mma_op: Any
    if a_dtype in {Float16, BFloat16} and b_dtype == a_dtype:
        if isinstance(a_collector_op, str):
            a_collector_op = CollectorOp(a_collector_op)
        if isinstance(b_collector_op, str):
            b_collector_op = CollectorOp(b_collector_op)
        if (
            a_collector_op != CollectorOp.DISCARD
            or b_collector_op != CollectorOp.DISCARD
        ):
            raise TypeError("F16/BF16 Rubin MMA does not support collector ops")
        mma_op = MmaF16BF16Op(
            a_dtype,
            acc_dtype,
            mma_tiler,
            cta_group,
            a_source,
            a_leading_mode,
            b_leading_mode,
        )
    elif a_dtype in {TFloat32, Float32} and b_dtype == a_dtype:
        if isinstance(a_collector_op, str):
            a_collector_op = CollectorOp(a_collector_op)
        if isinstance(b_collector_op, str):
            b_collector_op = CollectorOp(b_collector_op)
        if (
            a_collector_op != CollectorOp.DISCARD
            or b_collector_op != CollectorOp.DISCARD
        ):
            raise TypeError("TF32 Rubin MMA does not support collector ops")
        mma_op = MmaTF32Op(
            mma_tiler,
            cta_group,
            a_source,
            a_leading_mode,
            b_leading_mode,
        )
    elif a_dtype in {Float8E4M3FN, Float8E5M2} and b_dtype in {
        Float8E4M3FN,
        Float8E5M2,
    }:
        from cutlass.cutlass_dsl import BaseDSL
        from cutlass import base_dsl

        arch = BaseDSL._get_dsl().get_arch_enum()
        MmaFP8OpCls = SM107MmaFP8Op
        if isinstance(a_collector_op, str):
            a_collector_op = CollectorOp(a_collector_op)
        if isinstance(b_collector_op, str):
            b_collector_op = CollectorOp(b_collector_op)
        mma_op = MmaFP8OpCls(
            a_dtype,
            b_dtype,
            acc_dtype,
            mma_tiler,
            cta_group,
            a_source,
            a_leading_mode,
            b_leading_mode,
            a_collector_op,
            b_collector_op,
        )
    else:
        raise TypeError(f"unsupported a_dtype and b_dtype, got {a_dtype} and {b_dtype}")

    return cute.make_tiled_mma(
        cute.make_mma_atom(mma_op),
        atom_layout_mnk=atom_layout_mnk,
        permutation_mnk=permutation_mnk,
        loc=loc,
        ip=ip,
    )


def _copy_mma_op_with_b_collector(
    op: Tcgen05MmaOp, b_collector_op: CollectorOp
) -> Tcgen05MmaOp:
    """Return a shallow copy of a tcgen05 MMA op with b_collector_op overridden.

    Uses __new__ + object.__setattr__ per-field instead of dataclasses.replace()
    because subclass __init__ signatures do not accept all parent dataclass fields
    (e.g. acc_dtype is hardcoded in SM107BlockScaledMmaMXF8F6F4Op.__init__),
    which makes dataclasses.replace() raise an unexpected keyword argument error.
    """
    import dataclasses

    new_op = op.__class__.__new__(op.__class__)
    for field in dataclasses.fields(op):  # type: ignore[arg-type]
        object.__setattr__(new_op, field.name, getattr(op, field.name))
    object.__setattr__(new_op, "b_collector_op", b_collector_op)
    return new_op


class TiledMmaWrapper(cute.TiledMma):
    """TiledMma for Rubin ops; adds with_bkeep()/with_breuse() factories."""

    def _make_variant(self, collector_op: CollectorOp) -> "TiledMmaWrapper":
        """Return a new TiledMmaWrapper with collector_op changed, copying all gettable fields."""
        new_op = _copy_mma_op_with_b_collector(
            cast(Tcgen05MmaOp, self.op), collector_op
        )
        result = cute.make_tiled_mma(
            cute.make_mma_atom(new_op),
            atom_layout_mnk=cute.slice_(self.thr_layout_vmnk, (0, None, None, None)),
            permutation_mnk=self.permutation_mnk,
        )
        for field in self._trait.admissible_fields:  # type: ignore[attr-defined]
            try:
                result.set(field, self.get(field))
            except ValueError:
                pass  # SFA/SFB are pointer-only fields not exposed by get()
        return result

    def with_bkeep(self, accumulate: bool | None = None) -> "TiledMmaWrapper":
        """Return a copy with b_collector_op=FILL (keep B in collector buffer).

        :param accumulate: If given, sets Field.ACCUMULATE on the returned object.
        :type accumulate: bool | None
        """
        result = self._make_variant(CollectorOp.FILL)
        if accumulate is not None:
            result.set(Field.ACCUMULATE, accumulate)
        return result

    def with_breuse(self, accumulate: bool | None = None) -> "TiledMmaWrapper":
        """Return a copy with b_collector_op=LASTUSE (consume the kept B data).

        :param accumulate: If given, sets Field.ACCUMULATE on the returned object.
        :type accumulate: bool | None
        """
        result = self._make_variant(CollectorOp.LASTUSE)
        if accumulate is not None:
            result.set(Field.ACCUMULATE, accumulate)
        return result


@dsl_user_op
def make_blockscaled_trivial_tiled_mma(
    a_dtype: Type[Numeric],
    b_dtype: Type[Numeric],
    a_leading_mode: OperandMajorMode,
    b_leading_mode: OperandMajorMode,
    sf_dtype: Type[Numeric],
    sf_vec_size: int,
    cta_group: CtaGroup,
    mma_inst_shape: Tuple[int, int, int],
    a_source: OperandSource = OperandSource.SMEM,
    a_collector_op: Union[CollectorOp, str] = CollectorOp.DISCARD,
    b_collector_op: Union[CollectorOp, str] = CollectorOp.DISCARD,
    atom_layout_mnk: Tuple[int, int, int] = (1, 1, 1),
    permutation_mnk: Optional[Tuple[int, int, int]] = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.TiledMma:
    """Make a BlockScaled tiled MMA atom with given data type, leading dimension, cta group and mma tile shape.
    By default, the MMA atom is created with SMEM operand source for A.

    :param a_dtype: Data type of operand A.
    :type a_dtype: type[Numeric]
    :param b_dtype: Data type of operand B.
    :type b_dtype: type[Numeric]
    :param a_leading_mode: Leading dimension of operand A (1 for K, 0 for M/N).
    :type a_leading_mode: cutlass.cute.nvgpu.OperandMajorMode
    :param b_leading_mode: Leading dimension of operand B (1 for K, 0 for M/N).
    :type b_leading_mode: cutlass.cute.nvgpu.OperandMajorMode
    :param sf_dtype: Data type of the Scale Factor.
    :type sf_dtype: type[Numeric]
    :param sf_vec_size: The vector size of the Scale Factor.
    :type sf_vec_size: int
    :param cta_group: The CTA group to use.
    :type cta_group: tcgen05.CtaGroup
    :param mma_inst_shape: The shape (M, N, K) of the MMA instruction.
    :type mma_inst_shape: Tuple[int, int, int]
    :param a_source: The source of operand A (SMEM by default or TMEM).
    :type a_source: cutlass.cute.nvgpu.tcgen05.OperandSource
    :param a_collector_op: Collector operation for operand A (DISCARD by default).
    :type a_collector_op: cutlass.cute.nvgpu.tcgen05.CollectorOp | str
    :param b_collector_op: Collector operation for operand B (DISCARD by default).
    :type b_collector_op: cutlass.cute.nvgpu.tcgen05.CollectorOp | str
    :param atom_layout_mnk: A Layout describing the tiling of Atom across threads
    :type atom_layout_mnk:  Layout
    :param permutation_mnk: A permutation Tiler describing the tiling of Atom across values including any permutation of such tiling
    :type permutation_mnk:  Tiler

    :return: A tiled MMA atom with with_bkeep()/with_breuse() factory methods.
    :rtype: TiledMmaWrapper

    :raises TypeError: If the data type is not supported.
    """
    mma_op: Any
    if a_dtype == Float4E2M1FN and b_dtype == Float4E2M1FN:
        mma_op = SM107MmaMXF4NVF4Op(
            sf_dtype,
            sf_vec_size,
            mma_inst_shape,
            cta_group,
            a_source,
            a_collector_op,
            b_collector_op,
        )
    elif a_dtype in {
        Float4E2M1FN,
        Float6E3M2FN,
        Float6E2M3FN,
        Float8E4M3FN,
        Float8E5M2,
    } and b_dtype in {
        Float4E2M1FN,
        Float6E3M2FN,
        Float6E2M3FN,
        Float8E4M3FN,
        Float8E5M2,
    }:
        mma_op = SM107BlockScaledMmaMXF8F6F4Op(
            a_dtype,
            b_dtype,
            sf_dtype,
            sf_vec_size,
            mma_inst_shape,
            cta_group,
            a_source,
            a_leading_mode,
            b_leading_mode,
            a_collector_op,
            b_collector_op,
        )
    else:
        raise TypeError(
            f"unsupported a_dtype/b_dtype, got a_dtype: {a_dtype}"
            f" and b_dtype: {b_dtype}"
        )

    raw = cute.make_tiled_mma(
        cute.make_mma_atom(mma_op, loc=loc, ip=ip),
        atom_layout_mnk=atom_layout_mnk,
        permutation_mnk=permutation_mnk,
        loc=loc,
        ip=ip,
    )
    return TiledMmaWrapper(raw._op, raw._trait)



@dsl_user_op
def make_tensor_e_atom_layout(
    a_raw_dtype: Type[Numeric],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Get TensorEAtom layout for given A data type.

    :param a_raw_dtype: Element type for A tensor
    :type a_raw_dtype: Type[Numeric]

    :return: TensorEAtom layout
    :rtype: cute.Layout

    :raises ValueError: If a_raw_dtype is not supported for sparse operations
    """
    if a_raw_dtype in {Int8, Uint8, Float8E4M3FN, Float8E5M2, Float4E2M1FN}:
        return cute.make_layout((128, 128), stride=(128, 1), loc=loc, ip=ip)
    elif a_raw_dtype in {TFloat32, Float32}:
        return cute.make_layout(
            ((8, 2, 8), (8, 2, 4)), stride=((64, 8, 1024), (1, 512, 16)), loc=loc, ip=ip
        )
    elif a_raw_dtype in {Float16, BFloat16}:
        return cute.make_layout(
            ((8, 2, 8), (16, 2, 4)),
            stride=((128, 16, 2048), (1, 1024, 32)),
            loc=loc,
            ip=ip,
        )
    else:
        raise ValueError(f"Unsupported a_raw_dtype for sparse E tensor: {a_raw_dtype}")


@dsl_user_op
def make_sparse_gmem_layout_e(
    problem_shape_mnkl: cute.Shape,
    a_raw_dtype: Type[Numeric],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Create GMEM layout for sparse metadata E tensor.

    :param problem_shape_mnkl: Problem shape (M, N, K, L)
    :type problem_shape_mnkl: cute.Shape
    :param a_raw_dtype: Element type for A tensor
    :type a_raw_dtype: Type[Numeric]

    :return: GMEM layout for metadata E tensor
    :rtype: cute.Layout
    """
    assert isinstance(problem_shape_mnkl, tuple)
    m, _, k, l = problem_shape_mnkl[:4]

    # Get TensorEAtom properties
    tensor_e_atom_layout = make_tensor_e_atom_layout(a_raw_dtype, loc=loc, ip=ip)
    tensor_e_atom_shape = tensor_e_atom_layout.shape
    tensor_e_atom_stride = tensor_e_atom_layout.stride
    tensor_e_atom_m = cute.size(tensor_e_atom_layout, mode=[0], loc=loc, ip=ip)
    tensor_e_atom_k = cute.size(tensor_e_atom_layout, mode=[1], loc=loc, ip=ip)
    tensor_e_atom_cosize = cute.cosize(tensor_e_atom_layout, loc=loc, ip=ip)

    m_aligned_e = cute.round_up(m, tensor_e_atom_m)
    k_aligned_e = cute.round_up(k, tensor_e_atom_k)

    shape = (
        (tensor_e_atom_shape[0], m_aligned_e // tensor_e_atom_m),
        (tensor_e_atom_shape[1], k_aligned_e // tensor_e_atom_k),
        l,
    )

    batch_stride = m_aligned_e * k_aligned_e  # type: ignore[operator]
    stride = (
        (tensor_e_atom_stride[0], tensor_e_atom_cosize),
        (tensor_e_atom_stride[1], m_aligned_e * tensor_e_atom_k),
        batch_stride,
    )

    return cute.make_layout(shape, stride=stride, loc=loc, ip=ip)


@dsl_user_op
def make_sparse_smem_layout_e(
    tiled_mma: cute.TiledMma,
    mma_tiler_e_mnk: cute.Tile,
    a_raw_dtype: Type[Numeric],
    num_stages: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Union[cute.Layout, cute.ComposedLayout]:
    """This function helps with:

    1. Get the partitioned shape of the E tensor based on the tiled_mma & MMA tiler.
    2. Create SMEM layout atom with swizzle and sparse metadata flags.
    3. Tile the SMEM layout atom to the MMA tile shape.
    4. Stage the SMEM layout based on the number of stages.

    :param tiled_mma: The sparse tiled MMA used to partition tensor E
    :type tiled_mma: cute.TiledMma
    :param mma_tiler_e_mnk: The E tile shape (M, N, K) in logical elements
    :type mma_tiler_e_mnk: cute.Tile
    :param a_raw_dtype: Element type for A tensor
    :type a_raw_dtype: Type[Numeric]
    :param num_stages: Number of pipeline stages for tensor E
    :type num_stages: int

    :return: SMEM layout for tensor E
    :rtype: Union[cute.Layout, cute.ComposedLayout]
    """

    # K dimension for E metadata: 384 = 3 * 128 (3 K-tiles of sparse metadata)
    E_SMEM_K_DIM = 384
    assert isinstance(mma_tiler_e_mnk, tuple)
    e_smem_shape = (mma_tiler_e_mnk[0], E_SMEM_K_DIM)
    tensor_e_atom_layout = make_tensor_e_atom_layout(a_raw_dtype, loc=loc, ip=ip)

    # Create composed layout with swizzle for sparse metadata
    e_smem_layout_atom = cute.make_composed_layout(
        cute.make_swizzle(0, 4, 3),
        0,
        tensor_e_atom_layout,
        loc=loc,
        ip=ip,
    )

    e_smem_shape = cute.append(e_smem_shape, num_stages, loc=loc, ip=ip)  # type: ignore[assignment]
    return tile_to_mma_shape(
        e_smem_layout_atom,
        e_smem_shape,  # type: ignore[arg-type]
        order=(0),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_sparse_tmem_layout_e(
    tmem_shape: cute.Shape,
    a_raw_dtype: Type[Numeric],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Create TMEM layout for sparse metadata E tensor.

    This function implements the logic from tmem_e_frg::make() in mma_traits_sm100.hpp.
    It creates a TMEM layout based on the A matrix data type and the metadata shape.

    :param tmem_shape: Shape from E SMEM layout, expected format ((M_MMA, N_MMA), ...)
    :type tmem_shape: cute.Shape
    :param a_raw_dtype: Data type of A matrix (determines atom layout)
    :type a_raw_dtype: Type[Numeric]

    :return: TMEM layout for metadata tensor
    :rtype: cute.Layout

    :raises ValueError: If shape structure is invalid or M_MMA is not 128
    :raises ValueError: If N_MMA doesn't match expected value for the data type
    :raises ValueError: If a_raw_dtype bits is not supported
    """
    # Validate shape structure
    if cute.rank(tmem_shape, mode=[0]) != 2:
        raise ValueError("Expected post-partitioned shape ((M_MMA, N_MMA), ...)")

    assert isinstance(tmem_shape, tuple)
    R = cute.rank(tmem_shape)
    M_MMA = cute.size(tmem_shape, mode=[0, 0])
    N_MMA = cute.size(tmem_shape, mode=[0, 1])
    # TMEM DP stride constant for byte-based addressing (1 << 21 = 2097152)
    TMEM_DP_BYTES_STRIDE = 1 << 21

    if M_MMA != 128:
        raise ValueError(f"Only M_MMA=128 is implemented, got {M_MMA}")

    # TMEM restride layout for virtual tensor memory addressing
    # DP_b is the DP stride constant from TMEM allocator
    # For metadata, we use byte-based addressing
    tmem_restride = cute.make_layout(
        (128, 16384),
        stride=(TMEM_DP_BYTES_STRIDE, 1),
        loc=loc,
        ip=ip,
    )

    a_dtype_bits = a_raw_dtype.width

    if a_dtype_bits == 32:  # TF32: 128x16 atom
        if N_MMA != 16:
            raise ValueError(f"For TF32, expected N_MMA=16, got {N_MMA}")

        # TF32 metadata atom layout
        tmem_atom = cute.make_layout(
            ((8, 2, 8), (8, 2)), stride=((1, 1024, 16), (128, 8)), loc=loc, ip=ip
        )

        # Tile to MMA tiling
        tmem_logical_layout = cute.tiled_product(
            tmem_atom,
            cute.make_layout(tmem_shape[1:R], loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )

        # Address transformations with upcast<2> for 2-bit base types
        tmem_layout = cute.composition(
            cute.upcast(tmem_restride, 2, loc=loc, ip=ip),  # type: ignore[attr-defined]
            tmem_logical_layout,
            loc=loc,
            ip=ip,
        )

    elif a_dtype_bits == 16:  # FP16/BF16: 128x32 atom
        if N_MMA != 32:
            raise ValueError(f"For FP16/BF16, expected N_MMA=32, got {N_MMA}")

        # FP16/BF16 metadata atom layout
        tmem_atom = cute.make_layout(
            ((8, 2, 8), (16, 2)), stride=((1, 2048, 16), (128, 8)), loc=loc, ip=ip
        )

        # Tile to MMA tiling
        tmem_logical_layout = cute.tiled_product(
            tmem_atom,
            cute.make_layout(tmem_shape[1:R], loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )

        # Address transformations
        tmem_layout = cute.composition(
            tmem_restride, tmem_logical_layout, loc=loc, ip=ip
        )

    elif a_dtype_bits == 8:  # S8|Mix.F4/F6/F8: 128x64 atom
        if N_MMA != 64:
            raise ValueError(f"For 8-bit types, expected N_MMA=64, got {N_MMA}")

        # 8-bit metadata atom layout
        tmem_atom = cute.make_layout((128, 64), stride=(1, 128), loc=loc, ip=ip)

        # Tile to MMA tiling
        tmem_logical_layout = cute.tiled_product(
            tmem_atom,
            cute.make_layout(tmem_shape[1:R], loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )

        # Address transformations
        tmem_layout = cute.composition(
            tmem_restride, tmem_logical_layout, loc=loc, ip=ip
        )

    elif a_dtype_bits == 4:  # F4: 128x128 atom
        # F4 metadata atom layout
        tmem_atom = cute.make_layout((128, 128), stride=(1, 128), loc=loc, ip=ip)

        # Tile to MMA tiling
        tmem_logical_layout = cute.tiled_product(
            tmem_atom,
            cute.make_layout(tmem_shape[1:R], loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )
        # Address transformations
        tmem_layout = cute.composition(
            tmem_restride, tmem_logical_layout, loc=loc, ip=ip
        )

    else:
        raise ValueError(f"Unsupported a_raw_dtype bits: {a_dtype_bits}")

    return tmem_layout


__all__ = [
    "canonicalize_rubin_resource_arch",
    "make_trivial_tiled_mma",
    "make_sparse_trivial_tiled_mma",
    "make_blockscaled_trivial_tiled_mma",
    "make_sparse_a_dtype",
    "make_sparse_e_dtype",
    "make_tensor_e_atom_layout",
    "make_sparse_gmem_layout_e",
    "make_sparse_smem_layout_e",
    "make_sparse_tmem_layout_e",
]
