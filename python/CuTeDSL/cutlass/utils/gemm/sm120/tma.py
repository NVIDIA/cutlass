# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""TMA atom helpers for SM120 MXF4/NVFP4 GEMM."""

from typing import Optional, Type

import cutlass
import cutlass.cute as cute
from cutlass import const_expr
from cutlass._mlir import ir
from cutlass.base_dsl.typing import Numeric
from cutlass.cute.nvgpu import cpasync
from cutlass.cutlass_dsl import dsl_user_op

from .constants import (
    AbSmemFormat,
    MXF4NVF4_CTA_SHAPE_MNK,
    MXF4NVF4_SCALE_TMA_MIN_L,
    MXF4NVF4_SCALE_VEC_SIZE,
)
from .layouts import (
    _make_mxf4nvf4_a_consumer_smem_layout_staged,
    _make_mxf4nvf4_b_consumer_smem_layout_staged,
    make_mxf4nvf4_scale_interleaved_tma_layout_staged,
)


def _normalize_mxf4nvf4_ab_smem_format(smem_format: AbSmemFormat) -> AbSmemFormat:
    if smem_format in ("packed", "unpack"):
        return smem_format
    raise ValueError(
        f"`smem_format` must be 'packed' or 'unpack', but got {smem_format!r}"
    )


def _mxf4nvf4_ab_tma_internal_type(
    smem_format: AbSmemFormat,
) -> Optional[Type[Numeric]]:
    if _normalize_mxf4nvf4_ab_smem_format(smem_format) == "unpack":
        return cutlass.Uint8
    return None


def _preserve_mxf4nvf4_ab_tma_l_mode(gmem_tensor: cute.Tensor) -> cute.Tensor:
    """Keep A/B tensor maps rank-3 even for logical L=1.

    The SM120 native TMA path is closest to the C++ 79a path when A/B tensor
    maps keep the L coordinate in the instruction stream. For logical L=1, use
    a physical L extent of at least two while preserving the original strides.
    """
    if const_expr(cute.size(gmem_tensor, mode=[2]) != 1):
        return gmem_tensor
    return cute.make_tensor(
        gmem_tensor.iterator,
        cute.make_layout(
            (
                gmem_tensor.shape[0],
                gmem_tensor.shape[1],
                MXF4NVF4_SCALE_TMA_MIN_L,
            ),
            stride=gmem_tensor.layout.stride,
        ),
    )


def _make_mxf4nvf4_tiled_tma_atom(
    gmem_tensor: cute.Tensor,
    smem_layout: cute.Layout,
    cta_tiler: cute.Tile,
    *,
    internal_type: Optional[Type[Numeric]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    return cpasync.make_tiled_tma_atom(
        cpasync.CopyBulkTensorTileG2SOp(),
        gmem_tensor,
        smem_layout,
        cta_tiler,
        internal_type=internal_type,
        loc=loc,
        ip=ip,
    )


def _validate_mxf4nvf4_tma_tensor(
    name: str,
    tensor: cute.Tensor,
    dtype: Type[Numeric],
    rank: int,
) -> None:
    if tensor.element_type != dtype:
        raise TypeError(
            f"`{name}` must have element type {dtype}, but got {tensor.element_type}"
        )
    if cute.rank(tensor) != rank:
        raise ValueError(
            f"`{name}` must have rank {rank}, but got rank {cute.rank(tensor)}"
        )
    if tensor.memspace != cute.AddressSpace.gmem:
        raise ValueError(f"`{name}` must be a global-memory tensor")


@dsl_user_op
def _make_mxf4nvf4_tiled_tma_atom_a(
    gmem_tensor: cute.Tensor,
    smem_layout: Optional[cute.Layout] = None,
    cta_tiler: cute.Tile = (128, 128, 1),
    smem_format: AbSmemFormat = "packed",
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    smem_format = _normalize_mxf4nvf4_ab_smem_format(smem_format)
    if const_expr(smem_layout is None):
        smem_layout = _make_mxf4nvf4_a_consumer_smem_layout_staged(loc=loc, ip=ip)
    return _make_mxf4nvf4_tiled_tma_atom(
        gmem_tensor,
        smem_layout,
        cta_tiler,
        internal_type=_mxf4nvf4_ab_tma_internal_type(smem_format),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def _make_mxf4nvf4_tiled_tma_atom_b(
    gmem_tensor: cute.Tensor,
    smem_layout: Optional[cute.Layout] = None,
    cta_tiler: cute.Tile = (128, 128, 1),
    smem_format: AbSmemFormat = "packed",
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    smem_format = _normalize_mxf4nvf4_ab_smem_format(smem_format)
    if const_expr(smem_layout is None):
        smem_layout = _make_mxf4nvf4_b_consumer_smem_layout_staged(loc=loc, ip=ip)
    return _make_mxf4nvf4_tiled_tma_atom(
        gmem_tensor,
        smem_layout,
        cta_tiler,
        internal_type=_mxf4nvf4_ab_tma_internal_type(smem_format),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def _make_mxf4nvf4_sfa_tiled_tma_atom(
    gmem_tensor: cute.Tensor,
    smem_layout: Optional[cute.Layout] = None,
    cta_tiler: cute.Tile = (128, 4, 2, 1),
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    if const_expr(smem_layout is None):
        smem_layout = make_mxf4nvf4_scale_interleaved_tma_layout_staged(
            loc=loc, ip=ip
        )
    return _make_mxf4nvf4_tiled_tma_atom(
        gmem_tensor,
        smem_layout,
        cta_tiler,
        # Do not pass an internal type here: unlike A/B unpack-SMEM TMA,
        # the scale tensor-map format must remain the native FP8 GMEM type.
        # In CuTe DSL, internal_type controls tensor-map data format, so a
        # Uint16 internal type would change the descriptor away from FP8.
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def _make_mxf4nvf4_sfb_tiled_tma_atom(
    gmem_tensor: cute.Tensor,
    smem_layout: Optional[cute.Layout] = None,
    cta_tiler: cute.Tile = (128, 4, 2, 1),
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    if const_expr(smem_layout is None):
        smem_layout = make_mxf4nvf4_scale_interleaved_tma_layout_staged(
            loc=loc, ip=ip
        )
    return _make_mxf4nvf4_tiled_tma_atom(
        gmem_tensor,
        smem_layout,
        cta_tiler,
        # Keep the scale tensor-map format native FP8. See SFA helper above.
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_mxf4nvf4_native_tma_atoms(
    gA: cute.Tensor,
    gB: cute.Tensor,
    gSFA: cute.Tensor,
    gSFB: cute.Tensor,
    *,
    ab_smem_format: AbSmemFormat = "packed",
    ab_cta_tiler: cute.Tile = (128, 128, 1),
    ab_tile_coord: Optional[tuple[int, int, int]] = None,
    ab_tile_coord_a: Optional[tuple[int, int, int]] = None,
    ab_tile_coord_b: Optional[tuple[int, int, int]] = None,
    scale_tile_coord: Optional[tuple[int, int, int, int]] = None,
    scale_tile_coord_sfa: Optional[tuple[int, int, int, int]] = None,
    scale_tile_coord_sfb: Optional[tuple[int, int, int, int]] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    """Create A/B/SFA/SFB native TMA atoms for the SM120 NVFP4 path.

    A/B tensors remain logical FP4. Passing ``ab_smem_format="unpack"`` uses an
    8-bit internal TMA type, triggering the FP4 unpack-SMEM tensor-map format.
    Scale tensors remain native FP8 and use the compact interleaved scale TMA
    layout. Tile coordinates default to ``None`` for both A/B and scale tensors;
    callers that need local tiles can request them consistently.
    """
    _validate_mxf4nvf4_tma_tensor("gA", gA, cutlass.Float4E2M1FN, 3)
    _validate_mxf4nvf4_tma_tensor("gB", gB, cutlass.Float4E2M1FN, 3)
    _validate_mxf4nvf4_tma_tensor("gSFA", gSFA, cutlass.Float8E4M3FN, 4)
    _validate_mxf4nvf4_tma_tensor("gSFB", gSFB, cutlass.Float8E4M3FN, 4)
    scale_cta_tiler = (128, 4, 2, 1)
    gA = _preserve_mxf4nvf4_ab_tma_l_mode(gA)
    gB = _preserve_mxf4nvf4_ab_tma_l_mode(gB)
    tma_atom_a, tma_tensor_a = _make_mxf4nvf4_tiled_tma_atom_a(
        gA, cta_tiler=ab_cta_tiler, smem_format=ab_smem_format, loc=loc, ip=ip
    )
    tma_atom_b, tma_tensor_b = _make_mxf4nvf4_tiled_tma_atom_b(
        gB, cta_tiler=ab_cta_tiler, smem_format=ab_smem_format, loc=loc, ip=ip
    )

    if ab_tile_coord_a is None:
        ab_tile_coord_a = ab_tile_coord
    if ab_tile_coord_b is None:
        ab_tile_coord_b = ab_tile_coord
    if ab_tile_coord_a is not None:
        tma_tensor_a = cute.local_tile(
            tma_tensor_a, ab_cta_tiler, ab_tile_coord_a, loc=loc, ip=ip
        )
    if ab_tile_coord_b is not None:
        tma_tensor_b = cute.local_tile(
            tma_tensor_b, ab_cta_tiler, ab_tile_coord_b, loc=loc, ip=ip
        )

    scale_smem_layout_a = make_mxf4nvf4_scale_interleaved_tma_layout_staged(
        MXF4NVF4_CTA_SHAPE_MNK[0],
        MXF4NVF4_CTA_SHAPE_MNK[2],
        MXF4NVF4_SCALE_VEC_SIZE,
        1,
        loc=loc,
        ip=ip,
    )
    scale_smem_layout_b = make_mxf4nvf4_scale_interleaved_tma_layout_staged(
        MXF4NVF4_CTA_SHAPE_MNK[1],
        MXF4NVF4_CTA_SHAPE_MNK[2],
        MXF4NVF4_SCALE_VEC_SIZE,
        1,
        loc=loc,
        ip=ip,
    )
    tma_atom_sfa, tma_tensor_sfa = _make_mxf4nvf4_sfa_tiled_tma_atom(
        gSFA,
        smem_layout=scale_smem_layout_a,
        cta_tiler=scale_cta_tiler,
        loc=loc,
        ip=ip,
    )
    tma_atom_sfb, tma_tensor_sfb = _make_mxf4nvf4_sfb_tiled_tma_atom(
        gSFB,
        smem_layout=scale_smem_layout_b,
        cta_tiler=scale_cta_tiler,
        loc=loc,
        ip=ip,
    )

    if scale_tile_coord_sfa is None:
        scale_tile_coord_sfa = scale_tile_coord
    if scale_tile_coord_sfb is None:
        scale_tile_coord_sfb = scale_tile_coord
    if scale_tile_coord_sfa is not None:
        tma_tensor_sfa = cute.local_tile(
            tma_tensor_sfa,
            scale_cta_tiler,
            scale_tile_coord_sfa,
            loc=loc,
            ip=ip,
        )
    if scale_tile_coord_sfb is not None:
        tma_tensor_sfb = cute.local_tile(
            tma_tensor_sfb,
            scale_cta_tiler,
            scale_tile_coord_sfb,
            loc=loc,
            ip=ip,
        )

    return (
        tma_atom_a,
        tma_tensor_a,
        tma_atom_b,
        tma_tensor_b,
        tma_atom_sfa,
        tma_tensor_sfa,
        tma_atom_sfb,
        tma_tensor_sfb,
    )


__all__ = [
    "AbSmemFormat",
    "make_mxf4nvf4_native_tma_atoms",
]
