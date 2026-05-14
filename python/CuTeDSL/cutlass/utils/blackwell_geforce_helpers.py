# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""Blackwell GeForce / SM120 CuTe DSL helper utilities.

This module is the SM120-facing peer to ``blackwell_helpers``. It exposes the
narrow SM120 NVFP4 warp-MMA/TMA helper surface without adding SM100
tcgen05/TMEM concepts that are not part of the SM120 path.
"""

from typing import Optional, Tuple, Type

import cutlass
import cutlass.cute as cute
from cutlass._mlir import ir
from cutlass.base_dsl.typing import Numeric
from cutlass.cute.nvgpu import cpasync
from cutlass.cutlass_dsl import dsl_user_op
from cutlass.utils.gemm import sm120 as _sm120
from cutlass.utils.smem_allocator import SmemAllocator


def _require_cluster_1x1x1(cluster_shape_mnk: cute.Shape) -> None:
    if tuple(cluster_shape_mnk) != (1, 1, 1):
        raise ValueError(
            "SM120 Blackwell GeForce NVFP4 supports only "
            "cluster_shape_mnk=(1, 1, 1)"
        )


@dsl_user_op
def make_blockscaled_trivial_tiled_mma(
    a_dtype: Type[Numeric] = cutlass.Float4E2M1FN,
    b_dtype: Type[Numeric] = cutlass.Float4E2M1FN,
    acc_dtype: Type[Numeric] = cutlass.Float32,
    sf_dtype: Type[Numeric] = cutlass.Float8E4M3FN,
    sf_vec_size: int = _sm120.MXF4NVF4_SCALE_VEC_SIZE,
    atom_layout_mnk: Tuple[int, int, int] = (1, 1, 1),
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.TiledMma:
    """Create the supported SM120 NVFP4 blockscaled tiled MMA."""
    if a_dtype != cutlass.Float4E2M1FN:
        raise ValueError("SM120 NVFP4 A operands require Float4E2M1FN")
    if b_dtype != cutlass.Float4E2M1FN:
        raise ValueError("SM120 NVFP4 B operands require Float4E2M1FN")
    if acc_dtype != cutlass.Float32:
        raise ValueError("SM120 NVFP4 accumulation requires Float32")
    if sf_dtype != cutlass.Float8E4M3FN:
        raise ValueError("SM120 NVFP4 scale operands require Float8E4M3FN")
    if sf_vec_size != _sm120.MXF4NVF4_SCALE_VEC_SIZE:
        raise ValueError(
            "SM120 NVFP4 scale operands require sf_vec_size="
            f"{_sm120.MXF4NVF4_SCALE_VEC_SIZE}"
        )
    return _sm120.make_mxf4nvf4_tiled_mma(
        atom_layout_mnk=atom_layout_mnk, loc=loc, ip=ip
    )


@dsl_user_op
def make_smem_layout_a_tma_physical(
    major_extent: int = 128,
    tile_k: int = 128,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    return _sm120.make_mxf4nvf4_ab_tma_physical_layout_staged(
        major_extent, tile_k, num_stages, loc=loc, ip=ip
    )


@dsl_user_op
def make_smem_layout_b_tma_physical(
    major_extent: int = 128,
    tile_k: int = 128,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    return _sm120.make_mxf4nvf4_ab_tma_physical_layout_staged(
        major_extent, tile_k, num_stages, loc=loc, ip=ip
    )


@dsl_user_op
def make_smem_layout_a_consumer(
    major_extent: int = 128,
    tile_k: int = 128,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.ComposedLayout:
    return _sm120.make_mxf4nvf4_a_consumer_smem_layout_staged(
        major_extent, tile_k, num_stages, loc=loc, ip=ip
    )


@dsl_user_op
def make_smem_layout_b_consumer(
    major_extent: int = 128,
    tile_k: int = 128,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.ComposedLayout:
    return _sm120.make_mxf4nvf4_b_consumer_smem_layout_staged(
        major_extent, tile_k, num_stages, loc=loc, ip=ip
    )


@dsl_user_op
def make_smem_layout_scale_tma_physical(
    major_extent: int = 128,
    tile_k: int = 128,
    sf_vec_size: int = _sm120.MXF4NVF4_SCALE_VEC_SIZE,
    num_stages: int = 1,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cute.Layout:
    return _sm120.make_mxf4nvf4_scale_tma_physical_layout_staged(
        major_extent,
        tile_k,
        sf_vec_size,
        num_stages,
        loc=loc,
        ip=ip,
    )


def make_smem_layouts_ab(
    *,
    num_stages: int = 1,
    tile_m: int = 128,
    tile_n: int = 128,
    tile_k: int = 128,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
):
    """Return physical and consumer A/B layouts for SM120 NVFP4."""
    return (
        make_smem_layout_a_tma_physical(tile_m, tile_k, num_stages, loc=loc, ip=ip),
        make_smem_layout_b_tma_physical(tile_n, tile_k, num_stages, loc=loc, ip=ip),
        make_smem_layout_a_consumer(tile_m, tile_k, num_stages, loc=loc, ip=ip),
        make_smem_layout_b_consumer(tile_n, tile_k, num_stages, loc=loc, ip=ip),
    )


def make_ab_smem_views(
    smem: SmemAllocator,
    *,
    num_stages: int = 1,
    tile_m: int = 128,
    tile_n: int = 128,
    tile_k: int = 128,
):
    return _sm120.make_mxf4nvf4_ab_smem_views(
        smem, num_stages=num_stages, tile_m=tile_m, tile_n=tile_n, tile_k=tile_k
    )


def make_ab_consumer_smem_views(
    smem: SmemAllocator,
    *,
    num_stages: int = 1,
    tile_m: int = 128,
    tile_n: int = 128,
    tile_k: int = 128,
):
    return _sm120.make_mxf4nvf4_ab_consumer_smem_views(
        smem, num_stages=num_stages, tile_m=tile_m, tile_n=tile_n, tile_k=tile_k
    )


@dsl_user_op
def cluster_shape_to_tma_atom_A(
    cluster_shape_mnk: cute.Shape,
    atom_thr_id=None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cpasync.CopyBulkTensorTileG2SOp:
    _require_cluster_1x1x1(cluster_shape_mnk)
    return cpasync.CopyBulkTensorTileG2SOp()


@dsl_user_op
def cluster_shape_to_tma_atom_B(
    cluster_shape_mnk: cute.Shape,
    atom_thr_id=None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cpasync.CopyBulkTensorTileG2SOp:
    _require_cluster_1x1x1(cluster_shape_mnk)
    return cpasync.CopyBulkTensorTileG2SOp()


@dsl_user_op
def cluster_shape_to_tma_atom_SFA(
    cluster_shape_mnk: cute.Shape,
    atom_thr_id=None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cpasync.CopyBulkTensorTileG2SOp:
    _require_cluster_1x1x1(cluster_shape_mnk)
    return cpasync.CopyBulkTensorTileG2SOp()


@dsl_user_op
def cluster_shape_to_tma_atom_SFB(
    cluster_shape_mnk: cute.Shape,
    atom_thr_id=None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> cpasync.CopyBulkTensorTileG2SOp:
    _require_cluster_1x1x1(cluster_shape_mnk)
    return cpasync.CopyBulkTensorTileG2SOp()


def make_tiled_tma_atom_A(gA: cute.Tensor, smem_layout=None, *args, **kwargs):
    return _sm120.make_mxf4nvf4_tiled_tma_atom_a(gA, smem_layout, *args, **kwargs)


def make_tiled_tma_atom_B(gB: cute.Tensor, smem_layout=None, *args, **kwargs):
    return _sm120.make_mxf4nvf4_tiled_tma_atom_b(gB, smem_layout, *args, **kwargs)


def make_tiled_tma_atom_SFA(gSFA: cute.Tensor, smem_layout=None, *args, **kwargs):
    return _sm120.make_mxf4nvf4_sfa_tiled_tma_atom(gSFA, smem_layout, *args, **kwargs)


def make_tiled_tma_atom_SFB(gSFB: cute.Tensor, smem_layout=None, *args, **kwargs):
    return _sm120.make_mxf4nvf4_sfb_tiled_tma_atom(gSFB, smem_layout, *args, **kwargs)


def get_ab_tma_tx_bytes() -> int:
    return _sm120.mxf4nvf4_ab_tma_tx_bytes()


def get_scale_tma_tx_bytes() -> int:
    return _sm120.mxf4nvf4_scale_tma_tx_bytes()


def get_full_tma_tx_bytes() -> int:
    return _sm120.mxf4nvf4_full_tma_tx_bytes()


def get_tma_desc_bytes() -> int:
    return _sm120.MXF4NVF4_TMA_DESC_BYTES


def stage_ab_tma_physical_to_consumer_smem(*args, **kwargs):
    return _sm120.stage_mxf4nvf4_ab_tma_physical_to_consumer_smem(*args, **kwargs)


def make_ab_consumer_microtile_views(*args, **kwargs):
    return _sm120.make_mxf4nvf4_ab_consumer_microtile_views(*args, **kwargs)


def make_ab_fragments_from_consumer_smem(*args, **kwargs):
    return _sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem(*args, **kwargs)


def load_ab_fragments_from_consumer_smem(*args, **kwargs):
    return _sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem(*args, **kwargs)


def allocate_scale_fragment_scratch(*args, **kwargs):
    return _sm120.allocate_mxf4nvf4_scale_fragment_scratch(*args, **kwargs)


def make_scale_fragment_scratch_views(*args, **kwargs):
    return _sm120.make_mxf4nvf4_scale_fragment_scratch_views(*args, **kwargs)


def stage_scale_tma_physical_to_fragment_scratch(*args, **kwargs):
    return _sm120.stage_mxf4nvf4_scale_tma_physical_to_fragment_scratch(*args, **kwargs)


def make_scale_fragment_views_from_scratch(*args, **kwargs):
    return _sm120.make_mxf4nvf4_scale_fragment_views_from_scratch(*args, **kwargs)


def make_scale_fragments(*args, **kwargs):
    return _sm120.make_mxf4nvf4_scale_fragments(*args, **kwargs)


def load_sfa_fragment(*args, **kwargs):
    return _sm120.load_mxf4nvf4_sfa_fragment(*args, **kwargs)


def load_sfb_fragment(*args, **kwargs):
    return _sm120.load_mxf4nvf4_sfb_fragment(*args, **kwargs)


def make_external_tma_desc_ptr(*args, **kwargs):
    return _sm120.make_mxf4nvf4_external_tma_desc_ptr(*args, **kwargs)


def validate_ab_tma_contract(*args, **kwargs):
    return _sm120.validate_mxf4nvf4_ab_tma_contract(*args, **kwargs)


def validate_scale_tma_contract(*args, **kwargs):
    return _sm120.validate_mxf4nvf4_scale_tma_contract(*args, **kwargs)


_facade_all = [
    "allocate_scale_fragment_scratch",
    "cluster_shape_to_tma_atom_A",
    "cluster_shape_to_tma_atom_B",
    "cluster_shape_to_tma_atom_SFA",
    "cluster_shape_to_tma_atom_SFB",
    "get_ab_tma_tx_bytes",
    "get_full_tma_tx_bytes",
    "get_scale_tma_tx_bytes",
    "get_tma_desc_bytes",
    "load_ab_fragments_from_consumer_smem",
    "load_sfa_fragment",
    "load_sfb_fragment",
    "make_external_tma_desc_ptr",
    "make_ab_consumer_microtile_views",
    "make_ab_consumer_smem_views",
    "make_ab_fragments_from_consumer_smem",
    "make_ab_smem_views",
    "make_blockscaled_trivial_tiled_mma",
    "make_scale_fragment_scratch_views",
    "make_scale_fragment_views_from_scratch",
    "make_scale_fragments",
    "make_smem_layout_a_consumer",
    "make_smem_layout_a_tma_physical",
    "make_smem_layout_b_consumer",
    "make_smem_layout_b_tma_physical",
    "make_smem_layout_scale_tma_physical",
    "make_smem_layouts_ab",
    "make_tiled_tma_atom_A",
    "make_tiled_tma_atom_B",
    "make_tiled_tma_atom_SFA",
    "make_tiled_tma_atom_SFB",
    "stage_ab_tma_physical_to_consumer_smem",
    "stage_scale_tma_physical_to_fragment_scratch",
    "validate_ab_tma_contract",
    "validate_scale_tma_contract",
]

__all__ = sorted(_facade_all)
