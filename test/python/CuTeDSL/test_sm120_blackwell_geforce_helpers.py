# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest

import cutlass
from cutlass.utils.gemm import sm120


def test_sm120_blackwell_geforce_helpers_are_exported():
    assert cutlass.utils.gemm.sm120 is sm120
    assert cutlass.cute.as_position_independent_swizzle_tensor is not None
    assert "as_position_independent_swizzle_tensor" in cutlass.cute.__all__
    assert cutlass.utils.sm120.make_mxf4nvf4_tiled_mma is sm120.make_mxf4nvf4_tiled_mma
    assert (
        cutlass.utils.sm120.make_mxf4nvf4_scale_smem_fragment_views
        is sm120.make_mxf4nvf4_scale_smem_fragment_views
    )
    assert cutlass.utils.blackwell_geforce_helpers.MXF4NVF4_FULL_TMA_BYTES == 18432


@pytest.mark.parametrize(
    "name",
    [
        "make_mxf4nvf4_ab_tma_physical_layout_staged",
        "make_mxf4nvf4_scale_tma_physical_layout_staged",
        "make_mxf4nvf4_consumer_smem_layout_atom_ab",
        "make_mxf4nvf4_a_consumer_smem_layout_staged",
        "make_mxf4nvf4_b_consumer_smem_layout_staged",
        "make_mxf4nvf4_ab_consumer_smem_views",
        "make_mxf4nvf4_ab_consumer_microtile_views",
        "make_mxf4nvf4_ab_fragments_from_consumer_smem",
        "make_mxf4nvf4_scale_fragment_scratch_layout",
        "make_mxf4nvf4_ab_smem_copy_atoms",
        "make_mxf4nvf4_ab_ldsm_copy_views_from_consumer_smem",
        "load_mxf4nvf4_ab_fragments_from_consumer_smem",
        "shift_mxf4nvf4_post_ldsm_fp4_fragment",
        "fp4_shift_mxf4nvf4_a",
        "fp4_shift_mxf4nvf4_b",
        "stage_mxf4nvf4_a_tma_physical_to_consumer_smem",
        "stage_mxf4nvf4_ab_tma_physical_to_consumer_smem",
        "stage_mxf4nvf4_b_tma_physical_to_consumer_smem",
        "allocate_mxf4nvf4_scale_fragment_scratch",
        "make_mxf4nvf4_scale_fragment_scratch_views",
        "stage_mxf4nvf4_sfa_tma_physical_to_fragment_scratch",
        "stage_mxf4nvf4_scale_tma_physical_to_fragment_scratch",
        "stage_mxf4nvf4_sfb_tma_physical_to_fragment_scratch",
        "make_mxf4nvf4_scale_fragment_views_from_compact_smem",
        "make_mxf4nvf4_scale_fragment_views_from_scratch",
        "make_mxf4nvf4_scale_fragment_views_from_tma_physical",
        "mxf4nvf4_scale_tma_physical_offset",
    ],
)
def test_sm120_mxf4nvf4_layout_adapter_helpers_are_exported(name):
    assert hasattr(sm120, name)
    assert name in sm120.__all__


def test_sm120_mxf4nvf4_manual_ldsm_compat_helpers_are_not_public_exports():
    assert hasattr(sm120, "make_mxf4nvf4_ab_ldsm_scratch_layout")
    assert hasattr(sm120, "allocate_mxf4nvf4_ldsm_scratch")
    assert hasattr(sm120, "make_mxf4nvf4_ldsm_scratch_views")
    assert hasattr(sm120, "make_mxf4nvf4_ab_ldsm_copy_views")
    assert hasattr(sm120, "make_mxf4nvf4_ab_ldsm_copy_views_from_scratch")
    assert hasattr(sm120, "stage_mxf4nvf4_a_tma_physical_to_ldsm_scratch")
    assert hasattr(sm120, "stage_mxf4nvf4_ab_tma_physical_to_ldsm_scratch")
    assert hasattr(sm120, "stage_mxf4nvf4_b_tma_physical_to_ldsm_scratch")
    assert hasattr(sm120, "load_mxf4nvf4_ldsm_scratch_fragments")
    assert hasattr(sm120, "load_mxf4nvf4_packed_ldsm_kblock_fragments")
    assert "make_mxf4nvf4_ab_ldsm_scratch_layout" not in sm120.__all__
    assert "allocate_mxf4nvf4_ldsm_scratch" not in sm120.__all__
    assert "make_mxf4nvf4_ldsm_scratch_views" not in sm120.__all__
    assert "make_mxf4nvf4_ab_ldsm_copy_views" not in sm120.__all__
    assert "make_mxf4nvf4_ab_ldsm_copy_views_from_scratch" not in sm120.__all__
    assert "stage_mxf4nvf4_a_tma_physical_to_ldsm_scratch" not in sm120.__all__
    assert "stage_mxf4nvf4_ab_tma_physical_to_ldsm_scratch" not in sm120.__all__
    assert "stage_mxf4nvf4_b_tma_physical_to_ldsm_scratch" not in sm120.__all__
    assert "load_mxf4nvf4_ldsm_scratch_fragments" not in sm120.__all__
    assert "load_mxf4nvf4_packed_ldsm_kblock_fragments" not in sm120.__all__


def test_sm120_mxf4nvf4_consumer_loader_uses_cute_tiled_copy_path():
    source = sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem.__wrapped__.__code__
    helper_names = set(source.co_names)

    assert "make_mxf4nvf4_ab_ldsm_copy_views_from_consumer_smem" in helper_names
    assert "copy" in helper_names
    assert "fp4_shift_mxf4nvf4_a" in helper_names
    assert "fp4_shift_mxf4nvf4_b" in helper_names
    assert "_ldmatrix_x4_shared_b16" not in helper_names

    view_source = sm120.make_mxf4nvf4_ab_ldsm_copy_views_from_consumer_smem.__wrapped__.__code__
    view_names = set(view_source.co_names)
    assert "make_tiled_copy_A" in view_names
    assert "make_tiled_copy_B" in view_names
    assert "as_position_independent_swizzle_tensor" in view_names
    assert "retile_D" in view_names


@pytest.mark.parametrize(
    "helper",
    [
        sm120.make_mxf4nvf4_ab_ldsm_copy_views_from_consumer_smem,
        sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem,
        sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem,
    ],
)
def test_sm120_mxf4nvf4_consumer_helpers_name_lane_idx_contract(helper):
    varnames = helper.__wrapped__.__code__.co_varnames
    assert "lane_idx" in varnames
    assert "tidx" not in varnames


def test_sm120_mxf4nvf4_physical_to_consumer_bridge_uses_consumer_layout():
    for helper_name, offset_name in [
        ("stage_mxf4nvf4_a_tma_physical_to_consumer_smem", "a_major_tile"),
        ("stage_mxf4nvf4_b_tma_physical_to_consumer_smem", "b_major_tile"),
    ]:
        source = getattr(sm120, helper_name).__code__
        names = set(source.co_names)
        assert "recast_tensor" in names
        assert "recast_ptr" not in names
        assert "make_tensor" in names
        assert "MXF4NVF4_AB_SMEM_BYTES" in names
        assert "consumer_stage_idx" in source.co_varnames
        assert "stage_idx" not in source.co_varnames
        assert offset_name in source.co_varnames
    combined = sm120.stage_mxf4nvf4_ab_tma_physical_to_consumer_smem.__code__
    assert "consumer_stage_idx" in combined.co_varnames
    assert "stage_idx" not in combined.co_varnames


def test_sm120_mxf4nvf4_transaction_bytes():
    assert sm120.MXF4NVF4_AB_SMEM_BYTES == 16384
    assert sm120.mxf4nvf4_ab_tma_tx_bytes() == 8192
    assert sm120.mxf4nvf4_scale_tma_tx_bytes() == 1024
    assert sm120.mxf4nvf4_full_tma_tx_bytes() == 18432


@pytest.mark.parametrize(
    ("fn", "args"),
    [
        (sm120.mxf4nvf4_ab_tma_tx_bytes, (128, 64)),
        (sm120.mxf4nvf4_scale_tma_tx_bytes, (128, 128, 32)),
        (sm120.mxf4nvf4_full_tma_tx_bytes, (128, 128, 64, 16)),
    ],
)
def test_sm120_mxf4nvf4_transaction_bytes_reject_unsupported_shapes(fn, args):
    with pytest.raises(ValueError):
        fn(*args)


@pytest.mark.parametrize("name", ["sfa_major_offset", "sfb_major_offset"])
def test_sm120_mxf4nvf4_scale_major_offsets_are_not_silently_ignored(name):
    # The public staging wrappers are DSL ops that require tensor operands, so
    # the Python-level regression covers the shared validation guard directly.
    with pytest.raises(ValueError, match="encode the global major tile"):
        sm120._require_zero_scale_major_offset(name, 128)


@pytest.mark.parametrize("name", ["a_major_tile", "b_major_tile"])
def test_sm120_mxf4nvf4_ab_major_offsets_are_not_silently_ignored(name):
    with pytest.raises(ValueError, match="encode the global major tile"):
        sm120._require_zero_major_offset(name, 1)


def test_sm120_mxf4nvf4_descriptor_contracts_accept_defaults():
    sm120.validate_mxf4nvf4_ab_tma_contract(base_ptr=0x1000, desc_ptr=0x2000)
    sm120.validate_mxf4nvf4_scale_tma_contract(base_ptr=0x1000, desc_ptr=0x2000)


@pytest.mark.parametrize(
    "kwargs",
    [
        {"global_dim": (128, 128)},
        {"global_dim": (64, 128, 1)},
        {"box_dim": (64, 128, 1)},
        {"box_dim": (128, 129, 1)},
        {"desc_ptr": 0x2001},
        {"global_strides_bytes": (16, 8192)},
        {"element_strides": (2, 1, 1)},
        {"tx_count": 8191},
        {"dtype": cutlass.Uint8},
        {"align16": False},
    ],
)
def test_sm120_mxf4nvf4_ab_descriptor_contract_rejects_invalid(kwargs):
    params = {"base_ptr": 0x1000, "desc_ptr": 0x2000}
    params.update(kwargs)
    with pytest.raises(ValueError):
        sm120.validate_mxf4nvf4_ab_tma_contract(**params)


@pytest.mark.parametrize(
    "kwargs",
    [
        {"global_dim": (128, 16, 1)},
        {"global_dim": (128, 8, 1, 1)},
        {"box_dim": (128, 17, 1, 1)},
        {"box_dim": (129, 8, 1, 1)},
        {"desc_ptr": 0x2001},
        {"global_strides_bytes": (64, 2048, 2048)},
        {"element_strides": (2, 1, 1, 1)},
        {"tx_count": 1023},
        {"dtype": cutlass.Float8E4M3FN},
    ],
)
def test_sm120_mxf4nvf4_scale_descriptor_contract_rejects_invalid(kwargs):
    params = {"base_ptr": 0x1000, "desc_ptr": 0x2000}
    params.update(kwargs)
    with pytest.raises(ValueError):
        sm120.validate_mxf4nvf4_scale_tma_contract(**params)
