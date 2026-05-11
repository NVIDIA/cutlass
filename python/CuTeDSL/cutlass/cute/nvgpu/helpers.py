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

from typing import Any, Optional, Tuple, Type, Union, cast

from cutlass.cutlass_dsl import dsl_user_op

from cutlass._mlir import ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir

from .. import core, atom
from ..typing import Shape, Layout, ComposedLayout, Tensor, Numeric, NumericMeta
from .cpasync.copy import (
    CopyBulkTensorTileG2SOp,
    CopyBulkTensorTileG2SNonExecTrait,
    CopyBulkTensorTileG2SMulticastOp,
    CopyBulkTensorTileG2SMulticastNonExecTrait,
    CopyBulkTensorIm2ColG2SOp,
    CopyBulkTensorIm2ColG2SNonExecTrait,
    CopyBulkTensorIm2ColG2SMulticastOp,
    CopyBulkTensorIm2ColG2SMulticastNonExecTrait,
)
from .cpasync.helpers import TmaInfo


__all__ = [
    "make_tiled_tma_atom_A",
    "make_tiled_tma_atom_B",
    "make_im2col_tma_atom_A",
]

####################################################################################################
#
# TMA creation helpers for tcgen05 MMAs
#
####################################################################################################


@dsl_user_op
def make_tiled_tma_atom_A(
    op: Union[CopyBulkTensorTileG2SOp, CopyBulkTensorTileG2SMulticastOp],
    gmem_tensor: Tensor,
    smem_layout: Union[Layout, ComposedLayout],
    mma_tiler_mnk: Shape,
    tiled_mma: atom.TiledMma,
    cluster_shape_vmnk: Union[Shape, None] = None,
    *,
    internal_type: Optional[Type[Numeric]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> TmaInfo:
    """
    Makes a TMA Copy atom mapping to ``.tile`` mode for ``cp.async.bulk.tensor`` PTX operation
    accounting for the MK projections of the TiledMMA for A tensor loads.

    Given

    - a GMEM tensor
    - a SMEM layout
    - a MMA Tiler
    - a TiledMma
    - a Cluster-level shape

    this function figures out the bulk tensor asynchronous copy instruction to use with the maximum
    "TMA vector length" to copy tiles of the GMEM tensor to an SMEM buffer with the provided
    layout and consistent with the provided Tiler & tiled_mma (considering the M-mode & K-mode).
    The Cluster-level shape is used to determine the multicast factor across the N-mode for A tensor loads.

    This function returns two results:

    1. the Copy Atom
    2. the so-called TMA tensor used to map logical coordinates of the GMEM tensor to coordinates
       that the TMA unit can consume. TMA tensors have so-called basis stride elements so that the
       associated layout can output coordinates. Otherwise, TMA tensors can be partitioned
       similarly to any other CuTe tensors using the algebra.

    :param op:                 The Copy Operation to construct an Atom for
    :type op:                  Union[CopyBulkTensorTileG2SOp, CopyBulkTensorTileG2SMulticastOp]
    :param gmem_tensor:        The GMEM tensor to be loaded by this copy atom
    :type gmem_tensor:         Tensor
    :param smem_layout:        Shared memory layout to load the tensor into (PDSL)
    :type smem_layout:         Union[Layout, ComposedLayout]
    :param mma_tiler_mnk:      The MMA Tiler shape (TILE_M, TILE_N, TILE_K) in MNK dimensions
    :type mma_tiler_mnk:       Shape
    :param tiled_mma:          The TiledMMA that will consume the load as operands
    :type tiled_mma:           atom.TiledMma
    :param cluster_shape_vmnk: The Cluster-level shape in VMNK dimensions
    :type cluster_shape_vmnk:  Shape
    :param internal_type:      An optional parameter for the internal data type to when element
                               type does not match the copy type
    :type internal_type:       Type[Numeric]
    :return:                   A TmaInfo containing the Copy Atom, TMA tensor, and SMEM layout
    :rtype:                    TmaInfo

    """
    smem_rank = core.rank(smem_layout)
    assert smem_rank == 3 or smem_rank == 4, (
        "a_smem_layout must be non-staged (atom, rest_m, rest_k) "
        "or staged (atom, rest_m, rest_k, stage), "
        f"but got rank = {smem_rank}"
    )

    # Keep the original SMEM layout object for later retrieval at Python level.
    stored_smem_layout = smem_layout

    # Slice the smem_layout if it is staged
    if smem_rank == 4:
        smem_layout = core.select(smem_layout, mode=[0, 1, 2])

    ident = core.make_identity_layout(gmem_tensor.shape, loc=loc, ip=ip)
    mma_mnk: Any = mma_tiler_mnk
    mma_tiler_mk = (mma_mnk[0], *mma_mnk[2:])
    g_tile = core.composition(ident, mma_tiler_mk, loc=loc, ip=ip)
    cta_v_map: Any = tiled_mma._thrfrg_A(g_tile)
    cta_v_map = core.get(cta_v_map, mode=[1])
    cta_v_map = core.dice(cta_v_map, (1, (1,) * core.rank(g_tile)))

    if isinstance(op, CopyBulkTensorTileG2SOp):
        num_multicast = 1
    else:
        assert isinstance(op, CopyBulkTensorTileG2SMulticastOp)
        # multicast across the N-mode since those would share the same tile of A
        if cluster_shape_vmnk is None:
            raise ValueError(
                "cluster_shape_vmnk must be provided for multicast A tensor loads"
            )
        num_multicast = core.size(cluster_shape_vmnk, mode=[2])

    smem_for_ir: Any = smem_layout
    if isinstance(smem_for_ir, core._ComposedLayout):
        smem_for_ir = smem_for_ir.value

    tma_format = None
    if internal_type is not None:
        itype: Any = internal_type
        if not isinstance(internal_type, NumericMeta):
            raise TypeError(f"internal_type must be a Numeric, but got {internal_type}")

        use_unpack = (
            itype.width == 8
            and isinstance(gmem_tensor.element_type, NumericMeta)
            and gmem_tensor.element_type.width < 8  # type: ignore[union-attr]
        )
        internal_mlir_type = (
            gmem_tensor.element_type.mlir_type if use_unpack else itype.mlir_type  # type: ignore[union-attr]
        )
        tma_format = _cute_nvgpu_ir.TmaDataFormat(
            _cute_nvgpu_ir.get_default_tma_format(internal_mlir_type, use_unpack)
        )

    # res[0] = the IR Value for the non-executable atom instance
    # res[1] = the IR Value for the associated TMA tensor
    res = _cute_nvgpu_ir.atom_make_non_exec_tiled_tma_load(
        cast(Any, gmem_tensor).value,
        smem_for_ir,
        cta_v_map,
        op._to_ir(),
        num_multicast=num_multicast,
        tma_format=tma_format,
        loc=loc,
        ip=ip,
    )
    if isinstance(op, CopyBulkTensorTileG2SOp):
        return TmaInfo(
            atom.CopyAtom(op, CopyBulkTensorTileG2SNonExecTrait(res[0])),
            res[1],
            stored_smem_layout,
        )

    assert isinstance(op, CopyBulkTensorTileG2SMulticastOp)
    return TmaInfo(
        atom.CopyAtom(op, CopyBulkTensorTileG2SMulticastNonExecTrait(res[0])),
        res[1],
        stored_smem_layout,
    )


@dsl_user_op
def make_tiled_tma_atom_B(
    op: Union[CopyBulkTensorTileG2SOp, CopyBulkTensorTileG2SMulticastOp],
    gmem_tensor: Tensor,
    smem_layout: Union[Layout, ComposedLayout],
    mma_tiler_mnk: Shape,
    tiled_mma: atom.TiledMma,
    cluster_shape_vmnk: Union[Shape, None] = None,
    *,
    internal_type: Optional[Type[Numeric]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> TmaInfo:
    """
    Makes a TMA Copy atom mapping to ``.tile`` mode for ``cp.async.bulk.tensor`` PTX operation
    accounting for the NK projections of the TiledMMA for B tensor loads.

    Given

    - a GMEM tensor
    - a SMEM layout
    - a MMA Tiler
    - a TiledMma
    - a Cluster-level shape

    this function figures out the bulk tensor asynchronous copy instruction to use with the maximum
    "TMA vector length" to copy tiles of the GMEM tensor to an SMEM buffer with the provided
    layout and consistent with the provided Tiler & tiled_mma (considering the N-mode & K-mode).
    The Cluster-level shape is used to determine the multicast factor across the M-mode for B tensor loads.

    This function returns two results:

    1. the Copy Atom
    2. the so-called TMA tensor used to map logical coordinates of the GMEM tensor to coordinates
       that the TMA unit can consume. TMA tensors have so-called basis stride elements so that the
       associated layout can output coordinates. Otherwise, TMA tensors can be partitioned
       similarly to any other CuTe tensors using the algebra.

    :param op:                 The Copy Operation to construct an Atom for
    :type op:                  Union[CopyBulkTensorTileG2SOp, CopyBulkTensorTileG2SMulticastOp]
    :param gmem_tensor:        The GMEM tensor to be loaded by this copy atom
    :type gmem_tensor:         Tensor
    :param smem_layout:        Shared memory layout to load the tensor into (PDSL)
    :type smem_layout:         Union[Layout, ComposedLayout]
    :param mma_tiler_mnk:      The MMA Tiler shape (TILE_M, TILE_N, TILE_K) in MNK dimensions
    :type mma_tiler_mnk:       Shape
    :param tiled_mma:          The TiledMMA that will consume the load as operands
    :type tiled_mma:           core.TiledMma
    :param cluster_shape_vmnk: The Cluster-level shape in VMNK dimensions
    :type cluster_shape_vmnk:  Shape
    :param internal_type:      An optional parameter for the internal data type to when element
                               type does not match the copy type
    :type internal_type:       Type[Numeric]
    :return:                   A TmaInfo containing the Copy Atom, TMA tensor, and SMEM layout
    :rtype:                    TmaInfo

    """
    smem_rank = core.rank(smem_layout)
    assert smem_rank == 3 or smem_rank == 4, (
        "b_smem_layout must be non-staged (atom, rest_n, rest_k) "
        "or staged (atom, rest_n, rest_k, stage), "
        f"but got rank = {smem_rank}"
    )

    # Keep the original SMEM layout object for later retrieval at Python level.
    stored_smem_layout = smem_layout

    # Slice the smem_layout if it is staged
    if smem_rank == 4:
        smem_layout = core.select(smem_layout, mode=[0, 1, 2])

    ident = core.make_identity_layout(gmem_tensor.shape, loc=loc, ip=ip)
    mma_mnk: Any = mma_tiler_mnk
    mma_tiler_nk = (mma_mnk[1], *mma_mnk[2:])
    g_tile = core.composition(ident, mma_tiler_nk, loc=loc, ip=ip)
    cta_v_map: Any = tiled_mma._thrfrg_B(g_tile)
    cta_v_map = core.get(cta_v_map, mode=[1])
    cta_v_map = core.dice(cta_v_map, (1, (1,) * core.rank(g_tile)))

    if isinstance(op, CopyBulkTensorTileG2SOp):
        num_multicast = 1
    else:
        assert isinstance(op, CopyBulkTensorTileG2SMulticastOp)
        # multicast across the M-mode since those would share the same tile of B
        if cluster_shape_vmnk is None:
            raise ValueError(
                "cluster_shape_vmnk must be provided for multicast B tensor loads"
            )
        num_multicast = core.size(cluster_shape_vmnk, mode=[1])

    smem_for_ir: Any = smem_layout
    if isinstance(smem_for_ir, core._ComposedLayout):
        smem_for_ir = smem_for_ir.value

    tma_format = None
    if internal_type is not None:
        itype: Any = internal_type
        if not isinstance(internal_type, NumericMeta):
            raise TypeError(f"internal_type must be a Numeric, but got {internal_type}")

        use_unpack = (
            itype.width == 8
            and isinstance(gmem_tensor.element_type, NumericMeta)
            and gmem_tensor.element_type.width < 8  # type: ignore[union-attr]
        )
        internal_mlir_type = (
            gmem_tensor.element_type.mlir_type if use_unpack else itype.mlir_type  # type: ignore[union-attr]
        )
        tma_format = _cute_nvgpu_ir.TmaDataFormat(
            _cute_nvgpu_ir.get_default_tma_format(internal_mlir_type, use_unpack)
        )

    # res[0] = the IR Value for the non-executable atom instance
    # res[1] = the IR Value for the associated TMA tensor
    res = _cute_nvgpu_ir.atom_make_non_exec_tiled_tma_load(
        cast(Any, gmem_tensor).value,
        smem_for_ir,
        cta_v_map,
        op._to_ir(),
        num_multicast=num_multicast,
        tma_format=tma_format,
        loc=loc,
        ip=ip,
    )
    if isinstance(op, CopyBulkTensorTileG2SOp):
        return TmaInfo(
            atom.CopyAtom(op, CopyBulkTensorTileG2SNonExecTrait(res[0])),
            res[1],
            stored_smem_layout,
        )

    assert isinstance(op, CopyBulkTensorTileG2SMulticastOp)
    return TmaInfo(
        atom.CopyAtom(op, CopyBulkTensorTileG2SMulticastNonExecTrait(res[0])),
        res[1],
        stored_smem_layout,
    )


@dsl_user_op
def make_im2col_tma_atom_A(
    op: Union[CopyBulkTensorIm2ColG2SOp, CopyBulkTensorIm2ColG2SMulticastOp],
    gmem_tensor: Tensor,
    smem_layout: Union[Layout, ComposedLayout],
    mma_tiler_mnk: Shape,
    tiled_mma: atom.TiledMma,
    filter_trs: Tuple[int, int, int],
    upper_padding_dhw: Tuple[int, int, int],
    lower_padding_dhw: Tuple[int, int, int],
    stride_dhw: Tuple[int, int, int],
    dilation_dhw: Tuple[int, int, int],
    cluster_shape_vmnk: Union[Shape, None] = None,
    *,
    internal_type: Optional[Type[Numeric]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> TmaInfo:
    """
    Makes a TMA Copy atom mapping to ``.im2col`` mode for ``cp.async.bulk.tensor`` PTX operation accounting for the MK projections of the TiledMMA for A tensor loads.

    Given

    - a GMEM tensor
    - a SMEM layout
    - a MMA Tiler
    - a TiledMma
    - a filter shape
    - a padding shape
    - a stride shape
    - a dilation shape
    - a Cluster-level shape

    this function figures out the bulk tensor asynchronous copy instruction to use with the maximum
    "TMA vector length" to copy tiles of the GMEM tensor to/from an SMEM buffer with the provided
    layout while maintaining consistency with the provided Tiler.

    This function returns two results:

    1. the Copy Atom
    2. the TMA tensor used to map logical coordinates of the GMEM tensor to coordinates
       that the TMA unit can consume. TMA tensors have so-called basis stride elements so that the
       associated layout can output coordinates. Otherwise, TMA tensors can be partitioned
       similarly to any other CuTe tensors using the algebra.

    :param op:                 The Copy Operation to construct an Atom for
    :type op:                  Union[CopyBulkTensorIm2ColG2SOp, CopyBulkTensorIm2ColG2SMulticastOp]
    :param gmem_tensor:        The GMEM tensor to be loaded by this copy atom
    :type gmem_tensor:         Tensor
    :param smem_layout:        Shared memory layout to load the tensor into (PDSL)
    :type smem_layout:         Union[Layout, ComposedLayout]
    :param mma_tiler_mnk:      The MMA Tiler shape (TILE_M, TILE_N, TILE_K) in MNK dimensions
    :type mma_tiler_mnk:       Shape
    :param tiled_mma:          The TiledMMA that will consume the load as operands
    :type tiled_mma:           atom.TiledMma
    :param filter_trs:         The filter shape (T, R, S) in TRS dimensions
    :type filter_trs:          Tuple[int, int, int]
    :param upper_padding_dhw:  The upper padding shape (D, H, W) in DHW dimensions
    :type upper_padding_dhw:   Tuple[int, int, int]
    :param lower_padding_dhw:  The lower padding shape (D, H, W) in DHW dimensions
    :type lower_padding_dhw:   Tuple[int, int, int]
    :param stride_dhw:         The stride shape (D, H, W) in DHW dimensions
    :type stride_dhw:          Tuple[int, int, int]
    :param dilation_dhw:       The dilation shape (D, H, W) in DHW dimensions
    :type dilation_dhw:        Tuple[int, int, int]
    :param cluster_shape_vmnk: The Cluster-level shape in VMNK dimensions
    :type cluster_shape_vmnk:  Shape
    :param internal_type:      An optional parameter for the internal data type to when element
                               type does not match the copy type
    :type internal_type:       Type[Numeric]
    :return:                   A TmaInfo containing the Copy Atom, TMA tensor, and SMEM layout
    :rtype:                    TmaInfo
    """
    smem_rank = core.rank(smem_layout)
    assert smem_rank == 3 or smem_rank == 4, (
        "a_smem_layout must be non-staged (atom, rest_m, rest_k) "
        "or staged (atom, rest_m, rest_k, stage), "
        f"but got rank = {smem_rank}"
    )

    # Keep the original SMEM layout object for later retrieval at Python level.
    stored_smem_layout = smem_layout

    # Slice the smem_layout if it is staged
    if smem_rank == 4:
        smem_layout = core.select(smem_layout, mode=[0, 1, 2])

    ident = core.make_identity_layout(
        core.product_each(gmem_tensor.shape), loc=loc, ip=ip
    )
    mma_mnk: Any = mma_tiler_mnk
    mma_tiler_mk = (mma_mnk[0], *mma_mnk[2:])
    g_tile = core.composition(ident, mma_tiler_mk, loc=loc, ip=ip)
    cta_v_map: Any = tiled_mma._thrfrg_A(g_tile)
    cta_v_map = core.get(cta_v_map, mode=[1])
    cta_v_map = core.dice(cta_v_map, (1, (1,) * core.rank(g_tile)))

    # Compute im2col descriptor parameters
    pad_upper_d, pad_upper_h, pad_upper_w = upper_padding_dhw
    pad_lower_d, pad_lower_h, pad_lower_w = lower_padding_dhw
    stride_d, stride_h, stride_w = stride_dhw
    dilation_d, dilation_h, dilation_w = dilation_dhw
    filter_t, filter_r, filter_s = filter_trs
    lower_corner_whd = (-pad_lower_w, -pad_lower_h, -pad_lower_d)
    upper_corner_whd = (
        pad_upper_w - ((filter_s - 1) * dilation_w),
        pad_upper_h - ((filter_r - 1) * dilation_h),
        pad_upper_d - ((filter_t - 1) * dilation_d),
    )
    lower_padding_whd = (pad_lower_w, pad_lower_h, pad_lower_d)
    upper_padding_whd = (pad_upper_w, pad_upper_h, pad_upper_d)
    stride_whd = (stride_w, stride_h, stride_d)
    lower_srt = (0, 0, 0)
    stride_srt = (dilation_w, dilation_h, dilation_d)

    if isinstance(op, CopyBulkTensorIm2ColG2SOp):
        num_multicast = 1
    else:
        assert isinstance(op, CopyBulkTensorIm2ColG2SMulticastOp)
        # multicast across the N-mode since those would share the same tile of A
        if cluster_shape_vmnk is None:
            raise ValueError(
                "cluster_shape_vmnk must be provided for multicast A tensor loads"
            )
        num_multicast = core.size(cluster_shape_vmnk, mode=[2])

    smem_for_ir: Any = smem_layout
    if isinstance(smem_for_ir, core._ComposedLayout):
        smem_for_ir = smem_for_ir.value

    tma_format = None
    if internal_type is not None:
        itype: Any = internal_type
        if not isinstance(internal_type, NumericMeta):
            raise TypeError(f"internal_type must be a Numeric, but got {internal_type}")

        use_unpack = (
            itype.width == 8
            and isinstance(gmem_tensor.element_type, NumericMeta)
            and gmem_tensor.element_type.width < 8  # type: ignore[union-attr]
        )
        internal_mlir_type = (
            gmem_tensor.element_type.mlir_type if use_unpack else itype.mlir_type  # type: ignore[union-attr]
        )
        tma_format = _cute_nvgpu_ir.TmaDataFormat(
            _cute_nvgpu_ir.get_default_tma_format(internal_mlir_type, use_unpack)
        )

    res = _cute_nvgpu_ir.atom_make_non_exec_im2col_tma_load(
        cast(Any, gmem_tensor).value,
        smem_for_ir,
        cta_v_map,
        op._to_ir(),
        core._pack_int_tuple(lower_corner_whd, loc=loc, ip=ip),
        core._pack_int_tuple(upper_corner_whd, loc=loc, ip=ip),
        core._pack_int_tuple(lower_padding_whd, loc=loc, ip=ip),
        core._pack_int_tuple(upper_padding_whd, loc=loc, ip=ip),
        core._pack_int_tuple(stride_whd, loc=loc, ip=ip),
        core._pack_int_tuple(lower_srt, loc=loc, ip=ip),
        core._pack_int_tuple(stride_srt, loc=loc, ip=ip),
        num_multicast=num_multicast,
        tma_format=tma_format,
        loc=loc,
        ip=ip,
    )
    if isinstance(op, CopyBulkTensorIm2ColG2SOp):
        return TmaInfo(
            atom.CopyAtom(op, CopyBulkTensorIm2ColG2SNonExecTrait(res[0])),
            res[1],
            stored_smem_layout,
        )

    assert isinstance(op, CopyBulkTensorIm2ColG2SMulticastOp)
    return TmaInfo(
        atom.CopyAtom(op, CopyBulkTensorIm2ColG2SMulticastNonExecTrait(res[0])),
        res[1],
        stored_smem_layout,
    )
