# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""SM120 MXF4NVF4 warp-GEMM helper API."""

from typing import Optional, Tuple, Type

import cutlass
import cutlass.cute as cute
from cutlass import const_expr
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm
from cutlass._mlir.extras import types as T
from cutlass.base_dsl.typing import Numeric
from cutlass.cute.nvgpu import cpasync, warp
from cutlass.cutlass_dsl import dsl_user_op, for_generate, yield_out
from cutlass.utils import blockscaled_layout
from cutlass.utils.smem_allocator import SmemAllocator
from cutlass.utils.tensormap_manager import (
    SM120_MXF4NVF4_TENSOR_MAP_BYTES,
    TensorMapManager,
    TensorMapUpdateMode,
    validate_sm120_mxf4nvf4_scale_tma_desc,
    validate_sm120_mxf4nvf4_tma_desc,
)


MXF4NVF4_CTA_SHAPE_MNK = (128, 128, 128)
MXF4NVF4_MMA_SHAPE_MNK = (16, 8, 64)
MXF4NVF4_SCALE_VEC_SIZE = 16
MXF4NVF4_SCALE_K = MXF4NVF4_CTA_SHAPE_MNK[2] // MXF4NVF4_SCALE_VEC_SIZE
MXF4NVF4_AB_TMA_BYTES = MXF4NVF4_CTA_SHAPE_MNK[0] * MXF4NVF4_CTA_SHAPE_MNK[2] // 2
MXF4NVF4_AB_SMEM_BYTES = MXF4NVF4_CTA_SHAPE_MNK[0] * MXF4NVF4_CTA_SHAPE_MNK[2]
MXF4NVF4_SCALE_TMA_BYTES = MXF4NVF4_CTA_SHAPE_MNK[0] * MXF4NVF4_SCALE_K
MXF4NVF4_FULL_TMA_BYTES = 2 * MXF4NVF4_AB_TMA_BYTES + 2 * MXF4NVF4_SCALE_TMA_BYTES
MXF4NVF4_TMA_DESC_BYTES = SM120_MXF4NVF4_TENSOR_MAP_BYTES


def _check_positive(name: str, value: int) -> None:
    if value <= 0:
        raise ValueError(f"`{name}` must be positive, but got {value}")


def _check_default_tile(tile_mn: int, tile_k: int, sf_vec_size: int) -> None:
    _check_positive("tile_mn", tile_mn)
    _check_positive("tile_k", tile_k)
    _check_positive("sf_vec_size", sf_vec_size)
    if tile_k != 128:
        raise ValueError("SM120 MXF4NVF4 helpers currently support tile_k=128")
    if sf_vec_size != MXF4NVF4_SCALE_VEC_SIZE:
        raise ValueError("SM120 MXF4NVF4 helpers currently support sf_vec_size=16")


def _require_zero_major_offset(name: str, value: cutlass.Int32 | int) -> None:
    raw_value = getattr(value, "value", value)
    if raw_value != 0:
        raise ValueError(
            f"`{name}` is not supported by this helper; encode the global major "
            "tile in the TMA descriptor coordinates and stage the local 128-major tile"
        )


def _require_zero_scale_major_offset(name: str, value: cutlass.Int32 | int) -> None:
    _require_zero_major_offset(name, value)


def mxf4nvf4_ab_tma_tx_bytes(tile_mn: int = 128, tile_k: int = 128) -> int:
    """Return bytes completed by one A or B full-tile TMA transaction."""
    _check_default_tile(tile_mn, tile_k, MXF4NVF4_SCALE_VEC_SIZE)
    return tile_mn * tile_k // 2


def mxf4nvf4_scale_tma_tx_bytes(
    tile_mn: int = 128,
    tile_k: int = 128,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
) -> int:
    """Return bytes completed by one SFA or SFB full-tile TMA transaction."""
    _check_default_tile(tile_mn, tile_k, sf_vec_size)
    return tile_mn * (tile_k // sf_vec_size)


def mxf4nvf4_full_tma_tx_bytes(
    tile_m: int = 128,
    tile_n: int = 128,
    tile_k: int = 128,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
) -> int:
    """Return the barrier transaction byte count for A/B/SFA/SFB TMA."""
    return (
        mxf4nvf4_ab_tma_tx_bytes(tile_m, tile_k)
        + mxf4nvf4_ab_tma_tx_bytes(tile_n, tile_k)
        + mxf4nvf4_scale_tma_tx_bytes(tile_m, tile_k, sf_vec_size)
        + mxf4nvf4_scale_tma_tx_bytes(tile_n, tile_k, sf_vec_size)
    )


def validate_mxf4nvf4_ab_tma_contract(
    *,
    base_ptr: int,
    desc_ptr: int | None = None,
    global_dim: tuple[int, int, int] = (128, 128, 1),
    global_strides_bytes: tuple[int, int] = (64, 8192),
    box_dim: tuple[int, int, int] = (128, 128, 1),
    element_strides: tuple[int, int, int] = (1, 1, 1),
    tx_count: int | None = MXF4NVF4_AB_TMA_BYTES,
    dtype: Type[Numeric] = cutlass.Float4E2M1FN,
    align16: bool = True,
) -> None:
    """Validate the public SM120 MXF4NVF4 A/B descriptor contract."""
    if dtype != cutlass.Float4E2M1FN:
        raise ValueError("SM120 MXF4NVF4 A/B descriptors require packed Float4E2M1FN")
    validate_sm120_mxf4nvf4_tma_desc(
        base_ptr=base_ptr,
        desc_ptr=desc_ptr,
        global_dim=global_dim,
        global_strides_bytes=global_strides_bytes,
        box_dim=box_dim,
        element_strides=element_strides,
        tx_count=tx_count,
        align16=align16,
    )


def validate_mxf4nvf4_scale_tma_contract(
    *,
    base_ptr: int,
    desc_ptr: int | None = None,
    global_dim: tuple[int, int, int, int] = (128, 16, 1, 1),
    global_strides_bytes: tuple[int, int, int] = (128, 2048, 2048),
    box_dim: tuple[int, int, int, int] = (128, 8, 1, 1),
    element_strides: tuple[int, int, int, int] = (1, 1, 1, 1),
    tx_count: int | None = MXF4NVF4_SCALE_TMA_BYTES,
    dtype: Type[Numeric] = cutlass.Uint8,
) -> None:
    """Validate the public SM120 MXF4NVF4 scale descriptor contract."""
    if dtype != cutlass.Uint8:
        raise ValueError("SM120 MXF4NVF4 scale descriptors require UINT8")
    validate_sm120_mxf4nvf4_scale_tma_desc(
        base_ptr=base_ptr,
        desc_ptr=desc_ptr,
        global_dim=global_dim,
        global_strides_bytes=global_strides_bytes,
        box_dim=box_dim,
        element_strides=element_strides,
        tx_count=tx_count,
    )


@dsl_user_op
def make_mxf4nvf4_tiled_mma(
    atom_layout_mnk: Tuple[int, int, int] = (1, 1, 1),
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.TiledMma:
    """Create the SM120 warp-level MXF4NVF4 tiled MMA."""
    mma_op = warp.MmaMXF4NVF4Op(
        cutlass.Float4E2M1FN,
        cutlass.Float32,
        cutlass.Float8E4M3FN,
    )
    return cute.make_tiled_mma(
        mma_op, atom_layout_mnk=atom_layout_mnk, loc=loc, ip=ip
    )


@dsl_user_op
def make_mxf4nvf4_ab_tma_physical_layout_staged(
    major_extent: int = 128,
    tile_k: int = 128,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the A/B physical SMEM byte layout populated by external TMA."""
    _check_default_tile(major_extent, tile_k, MXF4NVF4_SCALE_VEC_SIZE)
    _check_positive("num_stages", num_stages)
    return cute.make_layout(
        (major_extent, tile_k, num_stages),
        stride=(tile_k, 1, major_extent * tile_k),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_mxf4nvf4_consumer_smem_layout_atom_ab(
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.ComposedLayout:
    """Return the SM120 packed-FP4 consumer SMEM atom layout.

    This mirrors the layout atom selected by the 79a C++ collective:
    `Sw<2,4,3> o smem_ptr[4b] o (_8,_128):(_128,_1)`.
    """
    return cute.make_composed_layout(
        cute.make_swizzle(2, 4, 3, loc=loc, ip=ip),
        0,
        cute.make_layout((8, 128), stride=(128, 1), loc=loc, ip=ip),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_mxf4nvf4_a_consumer_smem_layout_staged(
    major_extent: int = 128,
    tile_k: int = 128,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.ComposedLayout:
    """Return the staged 79a-style A consumer SMEM layout."""
    _check_default_tile(major_extent, tile_k, MXF4NVF4_SCALE_VEC_SIZE)
    _check_positive("num_stages", num_stages)
    return cute.tile_to_shape(
        make_mxf4nvf4_consumer_smem_layout_atom_ab(loc=loc, ip=ip),
        (major_extent, tile_k, num_stages),
        (0, 1, 2),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_mxf4nvf4_b_consumer_smem_layout_staged(
    major_extent: int = 128,
    tile_k: int = 128,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.ComposedLayout:
    """Return the staged 79a-style B consumer SMEM layout."""
    _check_default_tile(major_extent, tile_k, MXF4NVF4_SCALE_VEC_SIZE)
    _check_positive("num_stages", num_stages)
    return cute.tile_to_shape(
        make_mxf4nvf4_consumer_smem_layout_atom_ab(loc=loc, ip=ip),
        (major_extent, tile_k, num_stages),
        (0, 1, 2),
        loc=loc,
        ip=ip,
    )


def make_mxf4nvf4_ab_consumer_smem_views(
    smem: SmemAllocator,
    *,
    num_stages: int = 1,
    tile_m: int = 128,
    tile_n: int = 128,
    tile_k: int = 128,
) -> Tuple[cute.Tensor, cute.Tensor]:
    """Allocate A/B SMEM views for the 79a-style consumer LDSM path."""
    layout_a = make_mxf4nvf4_a_consumer_smem_layout_staged(
        tile_m, tile_k, num_stages
    )
    layout_b = make_mxf4nvf4_b_consumer_smem_layout_staged(
        tile_n, tile_k, num_stages
    )
    return (
        smem.allocate_tensor(cutlass.Float4E2M1FN, layout_a, byte_alignment=128),
        smem.allocate_tensor(cutlass.Float4E2M1FN, layout_b, byte_alignment=128),
    )


@dsl_user_op
def make_mxf4nvf4_ab_consumer_microtile_views(
    sA_consumer: cute.Tensor,
    sB_consumer: cute.Tensor,
    m_atom: cutlass.Int32 | int = 0,
    n_atom: cutlass.Int32 | int = 0,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[cute.Tensor, cute.Tensor]:
    """Return local 16x8 MMA microtile views from a staged CTA consumer tile.

    Global CTA M/N selection belongs in the tensor-map descriptor coordinates.
    This helper only selects the local output atom within the already-staged
    128x128 CTA tile.
    """
    return (
        cute.domain_offset(
            (m_atom * MXF4NVF4_MMA_SHAPE_MNK[0], 0, 0),
            sA_consumer,
            loc=loc,
            ip=ip,
        ),
        cute.domain_offset(
            (n_atom * MXF4NVF4_MMA_SHAPE_MNK[1], 0, 0),
            sB_consumer,
            loc=loc,
            ip=ip,
        ),
    )


def make_mxf4nvf4_smem_layout_staged(
    major_extent: int = 128,
    tile_k: int = 128,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Compatibility alias for the A/B TMA physical SMEM layout."""
    return make_mxf4nvf4_ab_tma_physical_layout_staged(
        major_extent, tile_k, num_stages, loc=loc, ip=ip
    )


@dsl_user_op
def make_mxf4nvf4_ab_ldsm_scratch_layout(
    major_extent: int = 128,
    k_block: int = MXF4NVF4_MMA_SHAPE_MNK[2],
    num_warps: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the LDSM-compatible A/B scratch layout for one K64 substep."""
    _check_positive("major_extent", major_extent)
    if k_block != MXF4NVF4_MMA_SHAPE_MNK[2]:
        raise ValueError("SM120 MXF4NVF4 LDSM scratch currently supports k_block=64")
    _check_positive("num_warps", num_warps)
    return cute.make_layout(
        (major_extent, k_block, num_warps),
        stride=(k_block, 1, major_extent * k_block),
        loc=loc,
        ip=ip,
    )


def make_mxf4nvf4_ab_smem_views(
    smem: SmemAllocator,
    *,
    num_stages: int = 1,
    tile_m: int = 128,
    tile_n: int = 128,
    tile_k: int = 128,
) -> Tuple[cute.Tensor, cute.Tensor, cute.Tensor, cute.Tensor]:
    """Allocate A/B TMA physical storage views.

    The returned LDSM views are compatibility aliases of the physical views.
    New kernels should stage from TMA physical storage into the SM120 consumer
    layout with `stage_mxf4nvf4_ab_tma_physical_to_consumer_smem()` before
    loading fragments.
    """
    layout_a = make_mxf4nvf4_ab_tma_physical_layout_staged(tile_m, tile_k, num_stages)
    layout_b = make_mxf4nvf4_ab_tma_physical_layout_staged(tile_n, tile_k, num_stages)
    sA_tma = smem.allocate_tensor(cutlass.Uint8, layout_a, byte_alignment=128)
    sB_tma = smem.allocate_tensor(cutlass.Uint8, layout_b, byte_alignment=128)
    sA_ldsm = sA_tma
    sB_ldsm = sB_tma
    return sA_tma, sA_ldsm, sB_tma, sB_ldsm


def allocate_mxf4nvf4_ldsm_scratch(
    smem: SmemAllocator,
    num_warps: int = 1,
) -> Tuple[cute.Tensor, cute.Tensor]:
    """Allocate CUTLASS-owned A/B LDSM scratch storage."""
    layout = make_mxf4nvf4_ab_ldsm_scratch_layout(num_warps=num_warps)
    return (
        smem.allocate_tensor(cutlass.Uint8, layout, byte_alignment=128),
        smem.allocate_tensor(cutlass.Uint8, layout, byte_alignment=128),
    )


@dsl_user_op
def make_mxf4nvf4_ldsm_scratch_views(
    scratch_a_all: cute.Tensor,
    scratch_b_all: cute.Tensor,
    consumer_warp: cutlass.Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[cute.Tensor, cute.Tensor]:
    """Return one consumer warp's A/B LDSM scratch views.

    `consumer_warp` must be compile-time constant. Preserving the base pointer
    for warp 0 keeps the 128-byte SMEM allocation alignment visible to LDSM.
    """
    warp_stride = MXF4NVF4_CTA_SHAPE_MNK[0] * MXF4NVF4_MMA_SHAPE_MNK[2]
    layout = make_mxf4nvf4_ab_ldsm_scratch_layout(loc=loc, ip=ip)
    consumer_warp_value = getattr(consumer_warp, "value", consumer_warp)
    if not isinstance(consumer_warp_value, int):
        raise ValueError("consumer_warp must be compile-time constant")
    scratch_a_ptr = scratch_a_all.iterator
    scratch_b_ptr = scratch_b_all.iterator
    if consumer_warp_value != 0:
        scratch_a_ptr = scratch_a_ptr + consumer_warp * warp_stride
        scratch_b_ptr = scratch_b_ptr + consumer_warp * warp_stride
    return (
        cute.make_tensor(
            scratch_a_ptr,
            layout,
            loc=loc,
            ip=ip,
        ),
        cute.make_tensor(
            scratch_b_ptr,
            layout,
            loc=loc,
            ip=ip,
        ),
    )


@dsl_user_op
def make_mxf4nvf4_sfa_smem_layout_staged(
    tiled_mma: Optional[cute.TiledMma] = None,
    tile_shape_mnk: cute.Tile = MXF4NVF4_CTA_SHAPE_MNK,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the staged SFA SMEM layout for SM120 MXF4NVF4."""
    tiled_mma = (
        make_mxf4nvf4_tiled_mma(loc=loc, ip=ip) if tiled_mma is None else tiled_mma
    )
    return blockscaled_layout.sm120_make_smem_layout_sfa(
        tiled_mma,
        tile_shape_mnk,
        sf_vec_size,
        num_stages,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_mxf4nvf4_sfb_smem_layout_staged(
    tiled_mma: Optional[cute.TiledMma] = None,
    tile_shape_mnk: cute.Tile = MXF4NVF4_CTA_SHAPE_MNK,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the staged SFB SMEM layout for SM120 MXF4NVF4."""
    tiled_mma = (
        make_mxf4nvf4_tiled_mma(loc=loc, ip=ip) if tiled_mma is None else tiled_mma
    )
    return blockscaled_layout.sm120_make_smem_layout_sfb(
        tiled_mma,
        tile_shape_mnk,
        sf_vec_size,
        num_stages,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_mxf4nvf4_scale_tma_physical_layout_staged(
    major_extent: int = 128,
    tile_k: int = 128,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return the rank-4 scale TMA physical destination layout."""
    _check_default_tile(major_extent, tile_k, sf_vec_size)
    _check_positive("num_stages", num_stages)
    scale_k = tile_k // sf_vec_size
    return cute.make_layout(
        (major_extent, scale_k, 1, num_stages),
        stride=(scale_k, 1, major_extent * scale_k, major_extent * scale_k),
        loc=loc,
        ip=ip,
    )


def make_mxf4nvf4_tma_scale_layout_staged(
    major_extent: int = 128,
    tile_k: int = 128,
    sf_vec_size: int = MXF4NVF4_SCALE_VEC_SIZE,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Compatibility alias for the scale TMA physical SMEM layout."""
    return make_mxf4nvf4_scale_tma_physical_layout_staged(
        major_extent, tile_k, sf_vec_size, num_stages, loc=loc, ip=ip
    )


@dsl_user_op
def make_mxf4nvf4_scale_fragment_scratch_layout(
    major_extent: int = 128,
    scale_k: int = MXF4NVF4_SCALE_K,
    num_warps: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    """Return fragment-compatible scale scratch layout."""
    _check_positive("major_extent", major_extent)
    if scale_k != MXF4NVF4_SCALE_K:
        raise ValueError("SM120 MXF4NVF4 scale scratch currently supports scale_k=8")
    _check_positive("num_warps", num_warps)
    return cute.make_layout(
        (major_extent, scale_k, num_warps),
        stride=(scale_k, 1, major_extent * scale_k),
        loc=loc,
        ip=ip,
    )


def allocate_mxf4nvf4_scale_fragment_scratch(
    smem: SmemAllocator,
    num_warps: int = 1,
) -> Tuple[cute.Tensor, cute.Tensor]:
    """Allocate CUTLASS-owned SFA/SFB fragment-compatible scale scratch."""
    layout = make_mxf4nvf4_scale_fragment_scratch_layout(num_warps=num_warps)
    return (
        smem.allocate_tensor(cutlass.Uint8, layout, byte_alignment=128),
        smem.allocate_tensor(cutlass.Uint8, layout, byte_alignment=128),
    )


@dsl_user_op
def make_mxf4nvf4_scale_fragment_scratch_views(
    scratch_sfa_all: cute.Tensor,
    scratch_sfb_all: cute.Tensor,
    consumer_warp: cutlass.Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[cute.Tensor, cute.Tensor]:
    """Return one consumer warp's SFA/SFB scale fragment scratch views."""
    warp_stride = MXF4NVF4_SCALE_TMA_BYTES
    layout = make_mxf4nvf4_scale_fragment_scratch_layout(loc=loc, ip=ip)
    return (
        cute.make_tensor(
            scratch_sfa_all.iterator + consumer_warp * warp_stride,
            layout,
            loc=loc,
            ip=ip,
        ),
        cute.make_tensor(
            scratch_sfb_all.iterator + consumer_warp * warp_stride,
            layout,
            loc=loc,
            ip=ip,
        ),
    )


def _make_mxf4nvf4_tiled_tma_atom(
    gmem_tensor: cute.Tensor,
    smem_layout: cute.Layout,
    cta_tiler: cute.Tile,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    op = cpasync.CopyBulkTensorTileG2SOp()
    return cpasync.make_tiled_tma_atom(
        op,
        gmem_tensor,
        smem_layout,
        cta_tiler,
        internal_type=cutlass.Uint8,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_mxf4nvf4_tiled_tma_atom_a(
    gmem_tensor: cute.Tensor,
    smem_layout: Optional[cute.Layout] = None,
    cta_tiler: cute.Tile = (128, 128, 1),
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    """Create the layout-aware TMA atom/tensor for one A tile."""
    if const_expr(smem_layout is None):
        smem_layout = make_mxf4nvf4_smem_layout_staged(loc=loc, ip=ip)
    return _make_mxf4nvf4_tiled_tma_atom(
        gmem_tensor, smem_layout, cta_tiler, loc=loc, ip=ip
    )


@dsl_user_op
def make_mxf4nvf4_tiled_tma_atom_b(
    gmem_tensor: cute.Tensor,
    smem_layout: Optional[cute.Layout] = None,
    cta_tiler: cute.Tile = (128, 128, 1),
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    """Create the layout-aware TMA atom/tensor for one B tile."""
    if const_expr(smem_layout is None):
        smem_layout = make_mxf4nvf4_smem_layout_staged(loc=loc, ip=ip)
    return _make_mxf4nvf4_tiled_tma_atom(
        gmem_tensor, smem_layout, cta_tiler, loc=loc, ip=ip
    )


@dsl_user_op
def make_mxf4nvf4_sfa_tiled_tma_atom(
    gmem_tensor: cute.Tensor,
    smem_layout: Optional[cute.Layout] = None,
    cta_tiler: cute.Tile = (128, 8, 1, 1),
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    """Create the layout-aware TMA atom/tensor for one SFA tile."""
    if const_expr(smem_layout is None):
        smem_layout = make_mxf4nvf4_tma_scale_layout_staged(loc=loc, ip=ip)
    return _make_mxf4nvf4_tiled_tma_atom(
        gmem_tensor, smem_layout, cta_tiler, loc=loc, ip=ip
    )


@dsl_user_op
def make_mxf4nvf4_sfb_tiled_tma_atom(
    gmem_tensor: cute.Tensor,
    smem_layout: Optional[cute.Layout] = None,
    cta_tiler: cute.Tile = (128, 8, 1, 1),
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    """Create the layout-aware TMA atom/tensor for one SFB tile."""
    if const_expr(smem_layout is None):
        smem_layout = make_mxf4nvf4_tma_scale_layout_staged(loc=loc, ip=ip)
    return _make_mxf4nvf4_tiled_tma_atom(
        gmem_tensor, smem_layout, cta_tiler, loc=loc, ip=ip
    )


@dsl_user_op
def make_mxf4nvf4_ldsm_copy_atom(
    *,
    transpose: bool = False,
    dtype: Type[Numeric] = cutlass.Uint8,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.CopyAtom:
    """Create the packed 16-bit LDSM atom used by SM120 MXF4NVF4 A/B loads."""
    return cute.make_copy_atom(
        warp.LdMatrix8x8x16bOp(transpose=transpose, num_matrices=4),
        dtype,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_mxf4nvf4_ab_smem_copy_atoms(
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[cute.CopyAtom, cute.CopyAtom]:
    """Return the non-transposed A/B LDSM copy atoms used by the C++ path."""
    return (
        make_mxf4nvf4_ldsm_copy_atom(
            transpose=False, dtype=cutlass.Float4E2M1FN, loc=loc, ip=ip
        ),
        make_mxf4nvf4_ldsm_copy_atom(
            transpose=False, dtype=cutlass.Float4E2M1FN, loc=loc, ip=ip
        ),
    )


@dsl_user_op
def make_mxf4nvf4_ab_ldsm_copy_views_from_consumer_smem(
    tiled_mma: cute.TiledMma,
    sA_consumer: cute.Tensor,
    sB_consumer: cute.Tensor,
    a_frag: cute.Tensor,
    b_frag: cute.Tensor,
    lane_idx: cutlass.Int32,
    *,
    m_atom: cutlass.Int32 | int = 0,
    n_atom: cutlass.Int32 | int = 0,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    """Return 79a-style A/B tiled-copy views from consumer SMEM.

    Input tensors must use the consumer SMEM layouts produced by
    `make_mxf4nvf4_ab_consumer_smem_views()` or the corresponding layout
    helpers. Do not pass raw external-TMA physical SMEM to this helper.
    `lane_idx` is the warp-local lane index, not the CTA thread index.
    """
    sA_consumer, sB_consumer = make_mxf4nvf4_ab_consumer_microtile_views(
        sA_consumer,
        sB_consumer,
        m_atom=m_atom,
        n_atom=n_atom,
        loc=loc,
        ip=ip,
    )
    copy_atom_a, copy_atom_b = make_mxf4nvf4_ab_smem_copy_atoms(loc=loc, ip=ip)
    tiled_copy_a = cute.make_tiled_copy_A(copy_atom_a, tiled_mma, loc=loc, ip=ip)
    tiled_copy_b = cute.make_tiled_copy_B(copy_atom_b, tiled_mma, loc=loc, ip=ip)
    thr_copy_a = tiled_copy_a.get_slice(lane_idx)
    thr_copy_b = tiled_copy_b.get_slice(lane_idx)
    sA_src = cute.as_position_independent_swizzle_tensor(
        sA_consumer, loc=loc, ip=ip
    )
    sB_src = cute.as_position_independent_swizzle_tensor(
        sB_consumer, loc=loc, ip=ip
    )
    tCsA = thr_copy_a.partition_S(sA_src, loc=loc, ip=ip)
    tCsB = thr_copy_b.partition_S(sB_src, loc=loc, ip=ip)
    tCrA = thr_copy_a.retile_D(a_frag, loc=loc, ip=ip)
    tCrB = thr_copy_b.retile_D(b_frag, loc=loc, ip=ip)
    return tiled_copy_a, tCsA, tCrA, tiled_copy_b, tCsB, tCrB


@dsl_user_op
def make_mxf4nvf4_ab_fragments_from_consumer_smem(
    tiled_mma: cute.TiledMma,
    sA_consumer: cute.Tensor,
    sB_consumer: cute.Tensor,
    lane_idx: cutlass.Int32,
    *,
    m_atom: cutlass.Int32 | int = 0,
    n_atom: cutlass.Int32 | int = 0,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[cute.Tensor, cute.Tensor]:
    """Allocate A/B fragments for one local output atom.

    `lane_idx` is the warp-local lane index. Use `m_atom`/`n_atom` to select
    the local 16x8 atom inside the staged 128x128 CTA tile.
    """
    sA_consumer, sB_consumer = make_mxf4nvf4_ab_consumer_microtile_views(
        sA_consumer,
        sB_consumer,
        m_atom=m_atom,
        n_atom=n_atom,
        loc=loc,
        ip=ip,
    )
    thread_mma = tiled_mma.get_slice(lane_idx)
    tCsA_mma = thread_mma.partition_A(sA_consumer, loc=loc, ip=ip)
    tCsB_mma = thread_mma.partition_B(sB_consumer, loc=loc, ip=ip)
    return (
        tiled_mma.make_fragment_A(tCsA_mma[None, None, None, 0], loc=loc, ip=ip),
        tiled_mma.make_fragment_B(tCsB_mma[None, None, None, 0], loc=loc, ip=ip),
    )


@dsl_user_op
def shift_mxf4nvf4_post_ldsm_fp4_fragment(
    fragment: cute.Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Validate the FP4 post-LDSM transform point for MXF4NVF4 MMA.

    The C++ path applies an explicit nibble shift after its packed LDSM copy.
    Python CuTe's typed `Float4E2M1FN` LDSM copy already materializes
    MMA-ready fragments, so this hook is intentionally a no-op after dtype
    validation. Keeping the hook explicit makes the consumer path match the C++
    mainloop structure without corrupting the Python fragment encoding.
    """
    if fragment.element_type is not cutlass.Float4E2M1FN:
        raise TypeError(
            "SM120 MXF4NVF4 post-LDSM shift expects a Float4E2M1FN fragment, "
            f"got {fragment.element_type}"
        )


@dsl_user_op
def fp4_shift_mxf4nvf4_a(
    fragment: cute.Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Apply the A-fragment FP4 post-LDSM shift."""
    shift_mxf4nvf4_post_ldsm_fp4_fragment(fragment, loc=loc, ip=ip)


@dsl_user_op
def fp4_shift_mxf4nvf4_b(
    fragment: cute.Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Apply the B-fragment FP4 post-LDSM shift."""
    shift_mxf4nvf4_post_ldsm_fp4_fragment(fragment, loc=loc, ip=ip)


@dsl_user_op
def load_mxf4nvf4_ab_fragments_from_consumer_smem(
    tiled_mma: cute.TiledMma,
    sA_consumer: cute.Tensor,
    sB_consumer: cute.Tensor,
    a_frag: cute.Tensor,
    b_frag: cute.Tensor,
    lane_idx: cutlass.Int32,
    k_block_idx: int,
    consumer_stage_idx: int = 0,
    *,
    m_atom: cutlass.Int32 | int = 0,
    n_atom: cutlass.Int32 | int = 0,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Load one K64 A/B block through the 79a-style consumer copy path.

    `lane_idx` is the warp-local lane index. Use `m_atom`/`n_atom` to select
    the local 16x8 atom inside the staged 128x128 CTA tile.
    """
    tiled_copy_a, tCsA, tCrA, tiled_copy_b, tCsB, tCrB = (
        make_mxf4nvf4_ab_ldsm_copy_views_from_consumer_smem(
            tiled_mma,
            sA_consumer,
            sB_consumer,
            a_frag,
            b_frag,
            lane_idx,
            m_atom=m_atom,
            n_atom=n_atom,
            loc=loc,
            ip=ip,
        )
    )
    tCsA_stage = tCsA[(None, None, None, consumer_stage_idx)]
    tCsB_stage = tCsB[(None, None, None, consumer_stage_idx)]
    cute.copy(
        tiled_copy_a,
        tCsA_stage[(None, None, k_block_idx)],
        tCrA[(None, None, k_block_idx)],
        loc=loc,
        ip=ip,
    )
    cute.copy(
        tiled_copy_b,
        tCsB_stage[(None, None, k_block_idx)],
        tCrB[(None, None, k_block_idx)],
        loc=loc,
        ip=ip,
    )
    fp4_shift_mxf4nvf4_a(tCrA[(None, None, k_block_idx)], loc=loc, ip=ip)
    fp4_shift_mxf4nvf4_b(tCrB[(None, None, k_block_idx)], loc=loc, ip=ip)


@dsl_user_op
def make_mxf4nvf4_ab_ldsm_copy_views(
    tiled_mma: cute.TiledMma,
    sA_ldsm: cute.Tensor,
    sB_ldsm: cute.Tensor,
    a_frag: cute.Tensor,
    b_frag: cute.Tensor,
    tidx: cutlass.Int32,
    *,
    a_transpose: bool = False,
    b_transpose: bool = True,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    """Return compatibility packed-LDSM source views and register fragments.

    This is the older manual inline-LDSM path. New code should use
    `make_mxf4nvf4_ab_ldsm_copy_views_from_consumer_smem()` and
    `load_mxf4nvf4_ab_fragments_from_consumer_smem()`, which mirror the C++
    tiled-copy consumer contract. This compatibility helper remains available
    for existing internal canaries and backward compatibility.
    """
    lane_row = tidx % 16
    lane_smem_offset = lane_row * 16
    sA_lane = cute.make_tensor(
        sA_ldsm.iterator + lane_smem_offset, sA_ldsm.layout, loc=loc, ip=ip
    )
    sB_lane = cute.make_tensor(
        sB_ldsm.iterator + lane_smem_offset, sB_ldsm.layout, loc=loc, ip=ip
    )
    return (
        make_mxf4nvf4_ldsm_copy_atom(
            transpose=a_transpose, dtype=cutlass.Int32, loc=loc, ip=ip
        ),
        sA_lane,
        a_frag,
        make_mxf4nvf4_ldsm_copy_atom(
            transpose=b_transpose, dtype=cutlass.Int32, loc=loc, ip=ip
        ),
        sB_lane,
        b_frag,
    )


make_mxf4nvf4_ab_ldsm_copy_views_from_scratch = make_mxf4nvf4_ab_ldsm_copy_views


def stage_mxf4nvf4_a_tma_physical_to_ldsm_scratch(
    sA_tma_physical: cute.Tensor,
    sA_ldsm_scratch: cute.Tensor,
    *,
    k_block_idx: cutlass.Constexpr[int],
    a_major_tile: cutlass.Int32 = cutlass.Int32(0),
    lane_idx: Optional[cutlass.Int32] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Stage one K64 A block from TMA physical SMEM into LDSM scratch."""
    loop_start = lane_idx if lane_idx is not None else 0
    loop_step = 32 if lane_idx is not None else 1
    src = cute.make_tensor(
        sA_tma_physical.iterator, cute.make_layout(MXF4NVF4_AB_SMEM_BYTES)
    )
    dst = cute.make_tensor(
        sA_ldsm_scratch.iterator, cute.make_layout(MXF4NVF4_AB_SMEM_BYTES // 2)
    )
    for i in for_generate(
        loop_start, MXF4NVF4_AB_SMEM_BYTES // 2, loop_step, loc=loc, ip=ip
    ):
        major = i // MXF4NVF4_MMA_SHAPE_MNK[2]
        byte_in_major = i % MXF4NVF4_MMA_SHAPE_MNK[2]
        payload_byte = (
            (a_major_tile + major) * (MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
            + k_block_idx * (MXF4NVF4_MMA_SHAPE_MNK[2] // 2)
            + byte_in_major % (MXF4NVF4_MMA_SHAPE_MNK[2] // 2)
        )
        payload_chunk = payload_byte // 8
        payload_byte_in_chunk = payload_byte % 8
        physical_chunk = payload_chunk ^ ((payload_chunk >> 3) & 0x7)
        dst[i] = src[physical_chunk * 16 + payload_byte_in_chunk]
        yield_out()


def stage_mxf4nvf4_b_tma_physical_to_ldsm_scratch(
    sB_tma_physical: cute.Tensor,
    sB_ldsm_scratch: cute.Tensor,
    *,
    k_block_idx: cutlass.Constexpr[int],
    b_major_tile: cutlass.Int32 = cutlass.Int32(0),
    lane_idx: Optional[cutlass.Int32] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Stage one K64 B block from TMA physical SMEM into LDSM scratch."""
    loop_start = lane_idx if lane_idx is not None else 0
    loop_step = 32 if lane_idx is not None else 1
    src = cute.make_tensor(
        sB_tma_physical.iterator, cute.make_layout(MXF4NVF4_AB_SMEM_BYTES)
    )
    dst = cute.make_tensor(
        sB_ldsm_scratch.iterator, cute.make_layout(MXF4NVF4_AB_SMEM_BYTES // 2)
    )
    for i in for_generate(
        loop_start, MXF4NVF4_AB_SMEM_BYTES // 2, loop_step, loc=loc, ip=ip
    ):
        major = i // MXF4NVF4_MMA_SHAPE_MNK[2]
        byte_in_major = i % MXF4NVF4_MMA_SHAPE_MNK[2]
        payload_byte = (
            (b_major_tile + major) * (MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
            + k_block_idx * (MXF4NVF4_MMA_SHAPE_MNK[2] // 2)
            + byte_in_major % (MXF4NVF4_MMA_SHAPE_MNK[2] // 2)
        )
        payload_chunk = payload_byte // 8
        payload_byte_in_chunk = payload_byte % 8
        physical_chunk = payload_chunk ^ ((payload_chunk >> 3) & 0x7)
        dst[i] = src[physical_chunk * 16 + payload_byte_in_chunk]
        yield_out()


def stage_mxf4nvf4_a_tma_physical_to_consumer_smem(
    sA_tma_physical: cute.Tensor,
    sA_consumer: cute.Tensor,
    *,
    a_major_tile: cutlass.Int32 = cutlass.Int32(0),
    consumer_stage_idx: int = 0,
    lane_idx: Optional[cutlass.Int32] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Stage one physical TMA A tile into the SM120 consumer SMEM layout.

    `consumer_stage_idx` selects the destination consumer stage. Pass a
    physical-stage view as `sA_tma_physical` when staging from a nonzero
    physical stage.
    """
    _require_zero_major_offset("a_major_tile", a_major_tile)
    loop_start = lane_idx if lane_idx is not None else 0
    loop_step = 32 if lane_idx is not None else 1
    src = cute.make_tensor(
        sA_tma_physical.iterator, cute.make_layout(MXF4NVF4_AB_SMEM_BYTES)
    )
    dst = cute.recast_tensor(sA_consumer, cutlass.Uint8, loc=loc, ip=ip)
    for i in for_generate(loop_start, MXF4NVF4_AB_TMA_BYTES, loop_step, loc=loc, ip=ip):
        major = i // (MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
        k_byte = i % (MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
        payload_byte = major * (MXF4NVF4_CTA_SHAPE_MNK[2] // 2) + k_byte
        payload_chunk = payload_byte // 8
        payload_byte_in_chunk = payload_byte % 8
        physical_chunk = payload_chunk ^ ((payload_chunk >> 3) & 0x7)
        dst[(major, k_byte, consumer_stage_idx)] = src[
            physical_chunk * 16 + payload_byte_in_chunk
        ]
        yield_out()


def stage_mxf4nvf4_b_tma_physical_to_consumer_smem(
    sB_tma_physical: cute.Tensor,
    sB_consumer: cute.Tensor,
    *,
    b_major_tile: cutlass.Int32 = cutlass.Int32(0),
    consumer_stage_idx: int = 0,
    lane_idx: Optional[cutlass.Int32] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Stage one physical TMA B tile into the SM120 consumer SMEM layout.

    `consumer_stage_idx` selects the destination consumer stage. Pass a
    physical-stage view as `sB_tma_physical` when staging from a nonzero
    physical stage.
    """
    _require_zero_major_offset("b_major_tile", b_major_tile)
    loop_start = lane_idx if lane_idx is not None else 0
    loop_step = 32 if lane_idx is not None else 1
    src = cute.make_tensor(
        sB_tma_physical.iterator, cute.make_layout(MXF4NVF4_AB_SMEM_BYTES)
    )
    dst = cute.recast_tensor(sB_consumer, cutlass.Uint8, loc=loc, ip=ip)
    for i in for_generate(loop_start, MXF4NVF4_AB_TMA_BYTES, loop_step, loc=loc, ip=ip):
        major = i // (MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
        k_byte = i % (MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
        payload_byte = major * (MXF4NVF4_CTA_SHAPE_MNK[2] // 2) + k_byte
        payload_chunk = payload_byte // 8
        payload_byte_in_chunk = payload_byte % 8
        physical_chunk = payload_chunk ^ ((payload_chunk >> 3) & 0x7)
        dst[(major, k_byte, consumer_stage_idx)] = src[
            physical_chunk * 16 + payload_byte_in_chunk
        ]
        yield_out()


def stage_mxf4nvf4_ab_tma_physical_to_consumer_smem(
    sA_tma_physical: cute.Tensor,
    sB_tma_physical: cute.Tensor,
    sA_consumer: cute.Tensor,
    sB_consumer: cute.Tensor,
    *,
    a_major_tile: cutlass.Int32 = cutlass.Int32(0),
    b_major_tile: cutlass.Int32 = cutlass.Int32(0),
    consumer_stage_idx: int = 0,
    lane_idx: Optional[cutlass.Int32] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Stage physical TMA A/B tiles into the SM120 consumer SMEM layouts."""
    stage_mxf4nvf4_a_tma_physical_to_consumer_smem(
        sA_tma_physical,
        sA_consumer,
        a_major_tile=a_major_tile,
        consumer_stage_idx=consumer_stage_idx,
        lane_idx=lane_idx,
        loc=loc,
        ip=ip,
    )
    stage_mxf4nvf4_b_tma_physical_to_consumer_smem(
        sB_tma_physical,
        sB_consumer,
        b_major_tile=b_major_tile,
        consumer_stage_idx=consumer_stage_idx,
        lane_idx=lane_idx,
        loc=loc,
        ip=ip,
    )


def stage_mxf4nvf4_ab_tma_physical_to_ldsm_scratch(
    sA_tma_physical: cute.Tensor,
    sB_tma_physical: cute.Tensor,
    sA_ldsm_scratch: cute.Tensor,
    sB_ldsm_scratch: cute.Tensor,
    *,
    k_block_idx: cutlass.Constexpr[int],
    a_major_tile: cutlass.Int32 = cutlass.Int32(0),
    b_major_tile: cutlass.Int32 = cutlass.Int32(0),
    lane_idx: Optional[cutlass.Int32] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Stage one K64 A/B block from TMA physical SMEM into LDSM scratch."""
    stage_mxf4nvf4_a_tma_physical_to_ldsm_scratch(
        sA_tma_physical,
        sA_ldsm_scratch,
        k_block_idx=k_block_idx,
        a_major_tile=a_major_tile,
        lane_idx=lane_idx,
        loc=loc,
        ip=ip,
    )
    stage_mxf4nvf4_b_tma_physical_to_ldsm_scratch(
        sB_tma_physical,
        sB_ldsm_scratch,
        k_block_idx=k_block_idx,
        b_major_tile=b_major_tile,
        lane_idx=lane_idx,
        loc=loc,
        ip=ip,
    )

@dsl_user_op
def _ldmatrix_x4_shared_b16(
    src: cute.Tensor,
    dst: cute.Tensor,
    *,
    transpose: bool = False,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    ptx = "ldmatrix.sync.aligned.m8n8.x4"
    if const_expr(transpose):
        ptx += ".trans"
    ptx += ".shared.b16 {$0, $1, $2, $3}, [$4];"
    src_smem_addr = src.iterator.toint(loc=loc, ip=ip).ir_value(loc=loc, ip=ip)
    regs = llvm.inline_asm(
        ir.Type.parse("!llvm.struct<(i32,i32,i32,i32)>"),
        [src_smem_addr],
        ptx,
        "=r,=r,=r,=r,r",
        has_side_effects=True,
        asm_dialect=0,
        loc=loc,
        ip=ip,
    )
    dst_i32 = cute.recast_tensor(dst, cutlass.Int32, loc=loc, ip=ip)
    dst_i32_size = cute.size(dst_i32, loc=loc, ip=ip)
    for i in range(dst_i32_size):
        dst_i32[i] = cutlass.Int32(llvm.extractvalue(T.i32(), regs, [i]))


@dsl_user_op
def load_mxf4nvf4_packed_ldsm_kblock_fragments(
    copy_a: cute.CopyAtom,
    tCsA: cute.Tensor,
    tCrA: cute.Tensor,
    copy_b: cute.CopyAtom,
    tCsB: cute.Tensor,
    tCrB: cute.Tensor,
    k_block_idx: int,
    stage_idx: int = 0,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Compatibility manual inline-LDSM load for one K64 A/B block."""
    a_src = tCsA[(None, k_block_idx * 64, stage_idx)]
    b_src = tCsB[(None, k_block_idx * 64, stage_idx)]
    _ldmatrix_x4_shared_b16(a_src, tCrA, transpose=False, loc=loc, ip=ip)
    _ldmatrix_x4_shared_b16(
        b_src,
        tCrB,
        transpose=getattr(copy_b.op, "transpose", True),
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def load_mxf4nvf4_ldsm_scratch_fragments(
    tiled_mma: cute.TiledMma,
    sA_ldsm_scratch: cute.Tensor,
    sB_ldsm_scratch: cute.Tensor,
    a_frag: cute.Tensor,
    b_frag: cute.Tensor,
    lane_idx: cutlass.Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Compatibility manual inline-LDSM load from staged scratch.

    New kernels should prefer `load_mxf4nvf4_ab_fragments_from_consumer_smem()`
    once their A/B data is in the SM120 consumer SMEM layout.
    """
    copy_a, tCsA, tCrA, copy_b, tCsB, tCrB = (
        make_mxf4nvf4_ab_ldsm_copy_views_from_scratch(
            tiled_mma,
            sA_ldsm_scratch,
            sB_ldsm_scratch,
            a_frag,
            b_frag,
            lane_idx,
            loc=loc,
            ip=ip,
        )
    )
    load_mxf4nvf4_packed_ldsm_kblock_fragments(
        copy_a, tCsA, tCrA, copy_b, tCsB, tCrB, 0, loc=loc, ip=ip
    )


@dsl_user_op
def make_mxf4nvf4_scale_smem_fragment_views(
    sSFA: cute.Tensor,
    sSFB: cute.Tensor,
    k_block_idx: int,
    stage_idx: int = 0,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[cute.Tensor, cute.Tensor]:
    """Return SFA/SFB source views for one K64 block from staged scale SMEM."""
    scale_k_offset = k_block_idx * (
        MXF4NVF4_MMA_SHAPE_MNK[2] // MXF4NVF4_SCALE_VEC_SIZE
    )
    stage_offset = stage_idx * MXF4NVF4_SCALE_TMA_BYTES
    sfa_f8 = cute.recast_tensor(sSFA, cutlass.Float8E4M3FN, loc=loc, ip=ip)
    sfb_f8 = cute.recast_tensor(sSFB, cutlass.Float8E4M3FN, loc=loc, ip=ip)
    sfa_ptr = sfa_f8.iterator + scale_k_offset + stage_offset
    sfb_ptr = sfb_f8.iterator + scale_k_offset + stage_offset
    return (
        cute.make_tensor(
            sfa_ptr, warp.make_mxf4nvf4_sfa_layout(loc=loc, ip=ip), loc=loc, ip=ip
        ),
        cute.make_tensor(
            sfb_ptr, warp.make_mxf4nvf4_sfb_layout(loc=loc, ip=ip), loc=loc, ip=ip
        ),
    )


make_mxf4nvf4_scale_fragment_views_from_compact_smem = (
    make_mxf4nvf4_scale_smem_fragment_views
)


@dsl_user_op
def make_mxf4nvf4_scale_fragment_views_from_scratch(
    sSFA_frag_scratch: cute.Tensor,
    sSFB_frag_scratch: cute.Tensor,
    k_block_idx: int,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[cute.Tensor, cute.Tensor]:
    """Return SFA/SFB source views from fragment-compatible scratch."""
    return make_mxf4nvf4_scale_smem_fragment_views(
        sSFA_frag_scratch, sSFB_frag_scratch, k_block_idx, loc=loc, ip=ip
    )


@dsl_user_op
def mxf4nvf4_scale_tma_physical_offset(
    major: cutlass.Int32,
    scale_col: cutlass.Int32,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cutlass.Int32:
    """Return rank-4 scale TMA physical byte offset for one logical scale."""
    payload_idx = scale_col * 128 + major
    chunk = payload_idx // 16
    byte = payload_idx % 16
    phys_chunk = chunk ^ (chunk >> 3)
    return phys_chunk * 16 + byte


def stage_mxf4nvf4_sfa_tma_physical_to_fragment_scratch(
    sSFA_tma_physical: cute.Tensor,
    sSFA_frag_scratch: cute.Tensor,
    *,
    sfa_major_offset: cutlass.Int32 = cutlass.Int32(0),
    lane_idx: Optional[cutlass.Int32] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Stage SFA rank-4 TMA physical SMEM into fragment-compatible scratch.

    The source tensor is one local 128-major TMA tile. Global major-tile
    selection belongs to the TMA descriptor coordinates, so the physical byte
    remap below intentionally uses local major coordinates only. The
    `sfa_major_offset` argument is rejected when nonzero; callers should encode
    global major offsets in the TMA coordinates.
    """
    _require_zero_scale_major_offset("sfa_major_offset", sfa_major_offset)
    loop_start = lane_idx if lane_idx is not None else 0
    loop_step = 32 if lane_idx is not None else 1
    src = cute.make_tensor(
        sSFA_tma_physical.iterator,
        cute.make_layout(MXF4NVF4_SCALE_TMA_BYTES),
        loc=loc,
        ip=ip,
    )
    dst = cute.make_tensor(
        sSFA_frag_scratch.iterator,
        cute.make_layout(MXF4NVF4_SCALE_TMA_BYTES),
        loc=loc,
        ip=ip,
    )
    for i in for_generate(
        loop_start, MXF4NVF4_SCALE_TMA_BYTES, loop_step, loc=loc, ip=ip
    ):
        local_major = i // MXF4NVF4_SCALE_K
        scale_col = i % MXF4NVF4_SCALE_K
        phys = mxf4nvf4_scale_tma_physical_offset(
            local_major, scale_col, loc=loc, ip=ip
        )
        dst[i] = src[phys]
        yield_out()


def stage_mxf4nvf4_sfb_tma_physical_to_fragment_scratch(
    sSFB_tma_physical: cute.Tensor,
    sSFB_frag_scratch: cute.Tensor,
    *,
    sfb_major_offset: cutlass.Int32 = cutlass.Int32(0),
    lane_idx: Optional[cutlass.Int32] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Stage SFB rank-4 TMA physical SMEM into fragment-compatible scratch.

    The source tensor is one local 128-major TMA tile. Global major-tile
    selection belongs to the TMA descriptor coordinates, so the physical byte
    remap below intentionally uses local major coordinates only. The
    `sfb_major_offset` argument is rejected when nonzero; callers should encode
    global major offsets in the TMA coordinates.
    """
    _require_zero_scale_major_offset("sfb_major_offset", sfb_major_offset)
    loop_start = lane_idx if lane_idx is not None else 0
    loop_step = 32 if lane_idx is not None else 1
    src = cute.make_tensor(
        sSFB_tma_physical.iterator,
        cute.make_layout(MXF4NVF4_SCALE_TMA_BYTES),
        loc=loc,
        ip=ip,
    )
    dst = cute.make_tensor(
        sSFB_frag_scratch.iterator,
        cute.make_layout(MXF4NVF4_SCALE_TMA_BYTES),
        loc=loc,
        ip=ip,
    )
    for i in for_generate(
        loop_start, MXF4NVF4_SCALE_TMA_BYTES, loop_step, loc=loc, ip=ip
    ):
        local_major = i // MXF4NVF4_SCALE_K
        scale_col = i % MXF4NVF4_SCALE_K
        phys = mxf4nvf4_scale_tma_physical_offset(
            local_major, scale_col, loc=loc, ip=ip
        )
        dst[i] = src[phys]
        yield_out()


def stage_mxf4nvf4_scale_tma_physical_to_fragment_scratch(
    sSFA_tma_physical: cute.Tensor,
    sSFB_tma_physical: cute.Tensor,
    sSFA_frag_scratch: cute.Tensor,
    sSFB_frag_scratch: cute.Tensor,
    *,
    sfa_major_offset: cutlass.Int32 = cutlass.Int32(0),
    sfb_major_offset: cutlass.Int32 = cutlass.Int32(0),
    lane_idx: Optional[cutlass.Int32] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Stage SFA/SFB TMA physical SMEM into fragment-compatible scratch."""
    stage_mxf4nvf4_sfa_tma_physical_to_fragment_scratch(
        sSFA_tma_physical,
        sSFA_frag_scratch,
        sfa_major_offset=sfa_major_offset,
        lane_idx=lane_idx,
        loc=loc,
        ip=ip,
    )
    stage_mxf4nvf4_sfb_tma_physical_to_fragment_scratch(
        sSFB_tma_physical,
        sSFB_frag_scratch,
        sfb_major_offset=sfb_major_offset,
        lane_idx=lane_idx,
        loc=loc,
        ip=ip,
    )


def make_mxf4nvf4_scale_fragment_views_from_tma_physical(
    sSFA_tma_physical: cute.Tensor,
    sSFB_tma_physical: cute.Tensor,
    sSFA_frag_scratch: cute.Tensor,
    sSFB_frag_scratch: cute.Tensor,
    k_block_idx: int,
    *,
    sfa_major_offset: cutlass.Int32 = cutlass.Int32(0),
    sfb_major_offset: cutlass.Int32 = cutlass.Int32(0),
    lane_idx: Optional[cutlass.Int32] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[cute.Tensor, cute.Tensor]:
    """Stage scale TMA physical SMEM into scratch and return fragment views.

    When `lane_idx` is provided, this helper synchronizes the CTA after
    cooperative staging so the returned views are ready for fragment loads.
    """
    stage_mxf4nvf4_scale_tma_physical_to_fragment_scratch(
        sSFA_tma_physical,
        sSFB_tma_physical,
        sSFA_frag_scratch,
        sSFB_frag_scratch,
        sfa_major_offset=sfa_major_offset,
        sfb_major_offset=sfb_major_offset,
        lane_idx=lane_idx,
        loc=loc,
        ip=ip,
    )
    if lane_idx is not None:
        cute.arch.sync_threads()
    return make_mxf4nvf4_scale_fragment_views_from_scratch(
        sSFA_frag_scratch,
        sSFB_frag_scratch,
        k_block_idx,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def make_mxf4nvf4_scale_fragments(
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Tuple[cute.Tensor, cute.Tensor]:
    """Create SFA and SFB register fragments for bundled SM120 MXF4NVF4 MMA."""
    return (
        warp.make_mxf4nvf4_sfa_fragment(loc=loc, ip=ip),
        warp.make_mxf4nvf4_sfb_fragment(loc=loc, ip=ip),
    )


@dsl_user_op
def load_mxf4nvf4_sfa_fragment(
    src: cute.Tensor,
    dst: cute.Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Load a prepartitioned SFA scale view into its register fragment."""
    dst.store(src.load(loc=loc, ip=ip), loc=loc, ip=ip)


@dsl_user_op
def load_mxf4nvf4_sfb_fragment(
    src: cute.Tensor,
    dst: cute.Tensor,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """Load a prepartitioned SFB scale view into its register fragment."""
    dst.store(src.load(loc=loc, ip=ip), loc=loc, ip=ip)


@dsl_user_op
def make_mxf4nvf4_external_tma_desc_ptr(
    desc_tensor: cute.Tensor,
    memspace: cute.AddressSpace = cute.AddressSpace.generic,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Pointer:
    """Return an address-space-qualified pointer to a 128-byte tensor-map descriptor."""
    manager = TensorMapManager(TensorMapUpdateMode.GMEM, MXF4NVF4_TMA_DESC_BYTES)
    return manager.get_tensormap_ptr(desc_tensor.iterator, memspace, loc=loc, ip=ip)


__all__ = [
    "MXF4NVF4_AB_TMA_BYTES",
    "MXF4NVF4_AB_SMEM_BYTES",
    "MXF4NVF4_CTA_SHAPE_MNK",
    "MXF4NVF4_FULL_TMA_BYTES",
    "MXF4NVF4_MMA_SHAPE_MNK",
    "MXF4NVF4_SCALE_K",
    "MXF4NVF4_SCALE_TMA_BYTES",
    "MXF4NVF4_SCALE_VEC_SIZE",
    "MXF4NVF4_TMA_DESC_BYTES",
    "allocate_mxf4nvf4_scale_fragment_scratch",
    "fp4_shift_mxf4nvf4_a",
    "fp4_shift_mxf4nvf4_b",
    "load_mxf4nvf4_ab_fragments_from_consumer_smem",
    "load_mxf4nvf4_sfa_fragment",
    "load_mxf4nvf4_sfb_fragment",
    "make_mxf4nvf4_a_consumer_smem_layout_staged",
    "make_mxf4nvf4_ab_consumer_microtile_views",
    "make_mxf4nvf4_ab_consumer_smem_views",
    "make_mxf4nvf4_ab_fragments_from_consumer_smem",
    "make_mxf4nvf4_ab_ldsm_copy_views_from_consumer_smem",
    "make_mxf4nvf4_ab_smem_views",
    "make_mxf4nvf4_ab_smem_copy_atoms",
    "make_mxf4nvf4_ab_tma_physical_layout_staged",
    "make_mxf4nvf4_b_consumer_smem_layout_staged",
    "make_mxf4nvf4_consumer_smem_layout_atom_ab",
    "make_mxf4nvf4_external_tma_desc_ptr",
    "make_mxf4nvf4_scale_fragment_scratch_layout",
    "make_mxf4nvf4_scale_fragment_scratch_views",
    "make_mxf4nvf4_scale_fragment_views_from_compact_smem",
    "make_mxf4nvf4_scale_fragment_views_from_scratch",
    "make_mxf4nvf4_scale_fragment_views_from_tma_physical",
    "make_mxf4nvf4_scale_fragments",
    "make_mxf4nvf4_scale_smem_fragment_views",
    "make_mxf4nvf4_scale_tma_physical_layout_staged",
    "make_mxf4nvf4_sfa_smem_layout_staged",
    "make_mxf4nvf4_sfa_tiled_tma_atom",
    "make_mxf4nvf4_sfb_smem_layout_staged",
    "make_mxf4nvf4_sfb_tiled_tma_atom",
    "make_mxf4nvf4_smem_layout_staged",
    "make_mxf4nvf4_tiled_mma",
    "make_mxf4nvf4_tiled_tma_atom_a",
    "make_mxf4nvf4_tiled_tma_atom_b",
    "make_mxf4nvf4_tma_scale_layout_staged",
    "mxf4nvf4_scale_tma_physical_offset",
    "mxf4nvf4_ab_tma_tx_bytes",
    "mxf4nvf4_full_tma_tx_bytes",
    "mxf4nvf4_scale_tma_tx_bytes",
    "shift_mxf4nvf4_post_ldsm_fp4_fragment",
    "stage_mxf4nvf4_a_tma_physical_to_consumer_smem",
    "stage_mxf4nvf4_ab_tma_physical_to_consumer_smem",
    "stage_mxf4nvf4_b_tma_physical_to_consumer_smem",
    "stage_mxf4nvf4_scale_tma_physical_to_fragment_scratch",
    "stage_mxf4nvf4_sfa_tma_physical_to_fragment_scratch",
    "stage_mxf4nvf4_sfb_tma_physical_to_fragment_scratch",
    "validate_mxf4nvf4_ab_tma_contract",
    "validate_mxf4nvf4_scale_tma_contract",
]
