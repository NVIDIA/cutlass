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

"""Layouts for SM120 MXF4/NVFP4 GEMM helpers."""

from typing import Any, Optional

import cutlass
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.cute.nvgpu import warp
from cutlass.cutlass_dsl import dsl_user_op
from cutlass.utils.smem_allocator import SmemAllocator

from .constants import (
    AbSmemFormat,
    MXF4NVF4_CTA_SHAPE_MNK,
    MXF4NVF4_SCALE_TMA_MIN_L,
    MXF4NVF4_SCALE_VEC_SIZE,
)
from .validation import _check_default_tile, _check_positive


@dsl_user_op
def make_mxf4nvf4_tiled_mma(
    atom_layout_mnk: Any = None,
    permutation_mnk: Any = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.TiledMma:
    """Create the tested SM120 128x128x128 MXF4/NVFP4 tiled MMA."""
    mma_op = warp.MmaMXF4NVF4Op(
        cutlass.Float4E2M1FN,
        cutlass.Float32,
        cutlass.Float8E4M3FN,
    )
    if atom_layout_mnk is None:
        atom_layout_mnk = cute.make_layout((4, 2, 1), stride=(1, 4, 0), loc=loc, ip=ip)
        if permutation_mnk is None:
            permutation_mnk = (
                128,
                cute.make_layout((8, 2, 2), stride=(1, 16, 8), loc=loc, ip=ip),
                64,
            )
    return cute.make_tiled_mma(
        mma_op,
        atom_layout_mnk=atom_layout_mnk,
        permutation_mnk=permutation_mnk,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_mxf4nvf4_a_gmem_layout(
    m: int = 128,
    k: int = 128,
    l_extent: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the logical K-major A GMEM layout."""
    _check_positive("m", m)
    _check_positive("k", k)
    _check_positive("l_extent", l_extent)
    return cute.make_layout((m, k, l_extent), stride=(k, 1, m * k), loc=loc, ip=ip)


@dsl_user_op
def make_mxf4nvf4_b_gmem_layout(
    n: int = 128,
    k: int = 128,
    l_extent: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the logical K-major B GMEM layout."""
    _check_positive("n", n)
    _check_positive("k", k)
    _check_positive("l_extent", l_extent)
    return cute.make_layout((n, k, l_extent), stride=(k, 1, n * k), loc=loc, ip=ip)


@dsl_user_op
def make_mxf4nvf4_scale_interleaved_gmem_layout(
    major_extent: int = 128,
    logical_k_extent: int = 128,
    l_extent: int = 1,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the compact interleaved FP8 GMEM scale layout consumed by TMA."""
    _check_positive("major_extent", major_extent)
    _check_positive("logical_k_extent", logical_k_extent)
    _check_positive("l_extent", l_extent)
    _check_positive("sf_vec_size", sf_vec_size)
    if sf_vec_size != MXF4NVF4_SCALE_VEC_SIZE:
        raise ValueError("SM120 MXF4NVF4 scale layout requires sf_vec_size=16")
    if major_extent % 128 != 0:
        raise ValueError("SM120 scale interleaved layout requires major_extent % 128 == 0")
    if logical_k_extent % sf_vec_size != 0:
        raise ValueError(
            "SM120 scale interleaved layout requires "
            "logical_k_extent % sf_vec_size == 0"
        )
    logical_scale_k = cute.ceil_div(logical_k_extent, sf_vec_size)
    if logical_scale_k % 4 != 0:
        raise ValueError("SM120 scale interleaved layout requires scale_k % 4 == 0")
    major_tiles = major_extent // 128
    scale_tiles = logical_scale_k // 4
    l_stride = major_tiles * scale_tiles * 512
    return cute.make_layout(
        (((32, 4), major_tiles), 4, scale_tiles, l_extent),
        stride=(((16, 4), 512), 1, major_tiles * 512, l_stride),
        loc=loc,
        ip=ip,
    )


def mxf4nvf4_padded_scale_k_extent(logical_scale_k_extent: int) -> int:
    """Return the padded physical scale-K extent for SM120 scale TMA."""
    _check_positive("logical_scale_k_extent", logical_scale_k_extent)
    granularity = MXF4NVF4_CTA_SHAPE_MNK[2] // MXF4NVF4_SCALE_VEC_SIZE * 2
    return (
        (logical_scale_k_extent + granularity - 1) // granularity
    ) * granularity


def mxf4nvf4_scale_tma_physical_k_extent(
    k: int,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
) -> int:
    """Return the physical scale-K extent needed to back a logical K extent."""
    _check_positive("k", k)
    _check_positive("sf_vec_size", sf_vec_size)
    if sf_vec_size != MXF4NVF4_SCALE_VEC_SIZE:
        raise ValueError("SM120 MXF4NVF4 scale TMA requires sf_vec_size=16")
    if k % sf_vec_size != 0:
        raise ValueError("SM120 MXF4NVF4 K extent must be divisible by sf_vec_size")
    return mxf4nvf4_padded_scale_k_extent(k // sf_vec_size)


def mxf4nvf4_scale_tma_physical_l_extent(logical_l_extent: int) -> int:
    """Return the physical scale-L extent used by native SM120 scale TMA."""
    _check_positive("logical_l_extent", logical_l_extent)
    return max(logical_l_extent, MXF4NVF4_SCALE_TMA_MIN_L)


@dsl_user_op
def make_mxf4nvf4_ab_tma_physical_layout_staged(
    major_extent: int = 128,
    tile_k: int = 128,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the A/B physical SMEM byte layout populated by TMA."""
    _check_default_tile(major_extent, tile_k, MXF4NVF4_SCALE_VEC_SIZE)
    _check_positive("num_stages", num_stages)
    return cute.make_layout(
        (major_extent, tile_k, num_stages),
        stride=(tile_k, 1, major_extent * tile_k),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def _make_mxf4nvf4_ab_consumer_layout_atom(
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.ComposedLayout:
    return cute.make_composed_layout(
        cute.make_swizzle(2, 4, 3, loc=loc, ip=ip),
        0,
        cute.make_layout((8, 128), stride=(128, 1), loc=loc, ip=ip),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def _make_mxf4nvf4_a_consumer_smem_layout_staged(
    major_extent: int = 128,
    tile_k: int = 128,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.ComposedLayout:
    _check_default_tile(major_extent, tile_k, MXF4NVF4_SCALE_VEC_SIZE)
    _check_positive("num_stages", num_stages)
    return cute.tile_to_shape(
        _make_mxf4nvf4_ab_consumer_layout_atom(loc=loc, ip=ip),
        (major_extent, tile_k, num_stages),
        (0, 1, 2),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def _make_mxf4nvf4_b_consumer_smem_layout_staged(
    major_extent: int = 128,
    tile_k: int = 128,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.ComposedLayout:
    return _make_mxf4nvf4_a_consumer_smem_layout_staged(
        major_extent, tile_k, num_stages, loc=loc, ip=ip
    )


@dsl_user_op
def make_mxf4nvf4_scale_interleaved_tma_layout_staged(
    major_extent: int = 128,
    tile_k: int = 128,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the compact interleaved FP8 scale TMA SMEM layout."""
    _check_default_tile(major_extent, tile_k, sf_vec_size)
    _check_positive("num_stages", num_stages)
    if major_extent % 128 != 0:
        raise ValueError(
            "SM120 scale interleaved SMEM layout requires major_extent % 128 == 0"
        )
    scale_k = tile_k // sf_vec_size
    if scale_k % 4 != 0:
        raise ValueError("SM120 scale interleaved SMEM layout requires scale_k % 4 == 0")
    major_tiles = major_extent // 128
    scale_tiles = scale_k // 4
    stage_stride = major_tiles * scale_tiles * 512
    return cute.make_layout(
        (((32, 4), major_tiles), 4, scale_tiles, num_stages),
        stride=(((16, 4), 512), 1, major_tiles * 512, stage_stride),
        loc=loc,
        ip=ip,
    )


def _mxf4nvf4_ab_smem_dtype(ab_smem_format: AbSmemFormat):
    if ab_smem_format == "unpack":
        return cutlass.Uint8
    if ab_smem_format == "packed":
        return cutlass.Float4E2M1FN
    raise ValueError(
        f"`ab_smem_format` must be 'packed' or 'unpack', but got {ab_smem_format!r}"
    )


def _allocate_mxf4nvf4_ab_smem_views(
    smem: SmemAllocator,
    *,
    ab_smem_format: AbSmemFormat = "packed",
    num_stages: int = 1,
    tile_m: int = 128,
    tile_n: int = 128,
    tile_k: int = 128,
) -> tuple[cute.Tensor, cute.Tensor]:
    ab_smem_dtype = _mxf4nvf4_ab_smem_dtype(ab_smem_format)
    return (
        smem.allocate_tensor(
            ab_smem_dtype,
            _make_mxf4nvf4_a_consumer_smem_layout_staged(tile_m, tile_k, num_stages),
            byte_alignment=128,
        ),
        smem.allocate_tensor(
            ab_smem_dtype,
            _make_mxf4nvf4_b_consumer_smem_layout_staged(tile_n, tile_k, num_stages),
            byte_alignment=128,
        ),
    )


def _allocate_mxf4nvf4_scale_interleaved_smem_views(
    smem: SmemAllocator,
    *,
    tile_m: int = 128,
    tile_n: int = 128,
    tile_k: int = 128,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
    num_stages: int = 1,
) -> tuple[cute.Tensor, cute.Tensor]:
    return (
        smem.allocate_tensor(
            cutlass.Float8E4M3FN,
            make_mxf4nvf4_scale_interleaved_tma_layout_staged(
                tile_m, tile_k, sf_vec_size, num_stages
            ),
            byte_alignment=128,
        ),
        smem.allocate_tensor(
            cutlass.Float8E4M3FN,
            make_mxf4nvf4_scale_interleaved_tma_layout_staged(
                tile_n, tile_k, sf_vec_size, num_stages
            ),
            byte_alignment=128,
        ),
    )


def make_mxf4nvf4_native_tma_smem_views(
    smem: SmemAllocator,
    *,
    ab_smem_format: AbSmemFormat = "packed",
    num_stages: int = 1,
    tile_m: int = 128,
    tile_n: int = 128,
    tile_k: int = 128,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
) -> tuple[cute.Tensor, cute.Tensor, cute.Tensor, cute.Tensor]:
    """Allocate A/B/SFA/SFB SMEM views for native SM120 TMA atoms.

    The scale path is intentionally interleaved-only; this is the compact fast
    path matching the SM120 native FP8 scale tensor-map usage.
    """
    sA, sB = _allocate_mxf4nvf4_ab_smem_views(
        smem,
        ab_smem_format=ab_smem_format,
        num_stages=num_stages,
        tile_m=tile_m,
        tile_n=tile_n,
        tile_k=tile_k,
    )
    sSFA, sSFB = _allocate_mxf4nvf4_scale_interleaved_smem_views(
        smem,
        tile_m=tile_m,
        tile_n=tile_n,
        tile_k=tile_k,
        sf_vec_size=sf_vec_size,
        num_stages=num_stages,
    )
    return (sA, sB, sSFA, sSFB)


__all__ = [
    "make_mxf4nvf4_a_gmem_layout",
    "make_mxf4nvf4_ab_tma_physical_layout_staged",
    "make_mxf4nvf4_b_gmem_layout",
    "make_mxf4nvf4_native_tma_smem_views",
    "make_mxf4nvf4_scale_interleaved_gmem_layout",
    "make_mxf4nvf4_scale_interleaved_tma_layout_staged",
    "make_mxf4nvf4_tiled_mma",
    "mxf4nvf4_padded_scale_k_extent",
    "mxf4nvf4_scale_tma_physical_k_extent",
    "mxf4nvf4_scale_tma_physical_l_extent",
]
