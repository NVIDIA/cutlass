# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest

import cutlass
from cutlass.utils.gemm import sm120


def test_sm120_blackwell_geforce_helpers_are_exported():
    assert cutlass.utils.gemm.sm120 is sm120
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
        "make_mxf4nvf4_ab_ldsm_scratch_layout",
        "make_mxf4nvf4_scale_fragment_scratch_layout",
        "allocate_mxf4nvf4_ldsm_scratch",
        "make_mxf4nvf4_ldsm_scratch_views",
        "make_mxf4nvf4_ab_ldsm_copy_views_from_scratch",
        "stage_mxf4nvf4_a_tma_physical_to_ldsm_scratch",
        "stage_mxf4nvf4_ab_tma_physical_to_ldsm_scratch",
        "stage_mxf4nvf4_b_tma_physical_to_ldsm_scratch",
        "load_mxf4nvf4_ldsm_scratch_fragments",
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
