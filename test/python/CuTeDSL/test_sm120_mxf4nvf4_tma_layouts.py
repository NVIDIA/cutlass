# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.utils.gemm import sm120
from cutlass.utils.gemm.sm120.constants import (
    MXF4NVF4_AB_TMA_BYTES,
    MXF4NVF4_FULL_TMA_BYTES,
    mxf4nvf4_ab_tma_bytes,
    mxf4nvf4_full_tma_bytes,
)
from cutlass.utils.gemm.sm120.layouts import (
    mxf4nvf4_padded_scale_k_extent,
    mxf4nvf4_scale_tma_physical_k_extent,
    mxf4nvf4_scale_tma_physical_l_extent,
)
from cutlass.utils.smem_allocator import SmemAllocator


def test_sm120_mxf4nvf4_public_api_is_narrow():
    assert set(sm120.__all__) == {
        "MXF4NVF4_CTA_SHAPE_MNK",
        "MXF4NVF4_MMA_SHAPE_MNK",
        "MXF4NVF4_SCALE_TMA_BYTES",
        "MXF4NVF4_SCALE_VEC_SIZE",
        "make_mxf4nvf4_a_gmem_layout",
        "make_mxf4nvf4_ab_tma_physical_layout_staged",
        "make_mxf4nvf4_b_gmem_layout",
        "make_mxf4nvf4_native_tma_atoms",
        "make_mxf4nvf4_native_tma_smem_views",
        "make_mxf4nvf4_scale_interleaved_gmem_layout",
        "make_mxf4nvf4_scale_interleaved_tma_layout_staged",
        "make_mxf4nvf4_tiled_mma",
        "mxf4nvf4_ab_tma_bytes",
        "mxf4nvf4_can_implement",
        "mxf4nvf4_full_tma_bytes",
        "validate_mxf4nvf4_gemm_config",
    }


def test_sm120_mxf4nvf4_config_and_extent_validation():
    assert sm120.MXF4NVF4_CTA_SHAPE_MNK == (128, 128, 128)
    assert sm120.MXF4NVF4_MMA_SHAPE_MNK == (16, 8, 64)
    assert sm120.MXF4NVF4_SCALE_VEC_SIZE == 16
    assert sm120.mxf4nvf4_can_implement()
    assert not sm120.mxf4nvf4_can_implement(k=64)

    sm120.validate_mxf4nvf4_gemm_config()
    with pytest.raises(ValueError, match="tile_shape_mnk"):
        sm120.validate_mxf4nvf4_gemm_config(tile_shape_mnk=(64, 128, 128))

    assert mxf4nvf4_padded_scale_k_extent(8) == 16
    assert mxf4nvf4_padded_scale_k_extent(17) == 32
    assert mxf4nvf4_scale_tma_physical_k_extent(384) == 32
    assert mxf4nvf4_scale_tma_physical_l_extent(1) == 2
    with pytest.raises(ValueError, match="major_extent % 128"):
        sm120.make_mxf4nvf4_scale_interleaved_tma_layout_staged(64, 128, 16, 1)
    with pytest.raises(ValueError, match="logical_k_extent % sf_vec_size"):
        sm120.make_mxf4nvf4_scale_interleaved_gmem_layout(128, 127, 1)
    assert mxf4nvf4_ab_tma_bytes("packed") == MXF4NVF4_AB_TMA_BYTES
    assert mxf4nvf4_ab_tma_bytes("unpack") == 2 * MXF4NVF4_AB_TMA_BYTES
    assert mxf4nvf4_full_tma_bytes("packed") == MXF4NVF4_FULL_TMA_BYTES
    assert mxf4nvf4_full_tma_bytes("unpack") > MXF4NVF4_FULL_TMA_BYTES


@cute.jit
def _check_scale_interleaved_layouts_exact():
    ab_tma_layout = sm120.make_mxf4nvf4_ab_tma_physical_layout_staged(128, 128, 1)
    gmem_layout = sm120.make_mxf4nvf4_scale_interleaved_gmem_layout(128, 128, 1)
    smem_layout = sm120.make_mxf4nvf4_scale_interleaved_tma_layout_staged(
        128, 128, 16, 1
    )
    assert ab_tma_layout.shape == (128, 128, 1)
    assert ab_tma_layout.stride == (128, 1, 16384)
    expected_shape = (((32, 4), 1), 4, 2, 1)
    expected_stride = (((16, 4), 512), 1, 512, 1024)
    assert gmem_layout.shape == expected_shape
    assert gmem_layout.stride == expected_stride
    assert smem_layout.shape == expected_shape
    assert smem_layout.stride == expected_stride


@cute.jit
def _build_native_tma_atoms(
    gA: cute.Tensor,
    gB: cute.Tensor,
    gSFA_storage: cute.Tensor,
    gSFB_storage: cute.Tensor,
):
    gSFA = cute.make_tensor(
        gSFA_storage.iterator,
        sm120.make_mxf4nvf4_scale_interleaved_gmem_layout(128, 128, 1),
    )
    gSFB = cute.make_tensor(
        gSFB_storage.iterator,
        sm120.make_mxf4nvf4_scale_interleaved_gmem_layout(128, 128, 1),
    )
    (
        tma_atom_a,
        tma_tensor_a,
        tma_atom_b,
        tma_tensor_b,
        tma_atom_sfa,
        tma_tensor_sfa,
        tma_atom_sfb,
        tma_tensor_sfb,
    ) = sm120.make_mxf4nvf4_native_tma_atoms(gA, gB, gSFA, gSFB)
    assert tma_atom_a is not None
    assert tma_atom_b is not None
    assert tma_atom_sfa is not None
    assert tma_atom_sfb is not None
    assert cute.rank(tma_tensor_a) == 3
    assert cute.rank(tma_tensor_b) == 3
    assert cute.size(tma_tensor_a, mode=[2]) == 2
    assert cute.size(tma_tensor_b, mode=[2]) == 2
    assert cute.rank(tma_tensor_sfa) == 4
    assert cute.rank(tma_tensor_sfb) == 4


@cute.jit
def _build_native_tma_atoms_unpack(
    gA: cute.Tensor,
    gB: cute.Tensor,
    gSFA_storage: cute.Tensor,
    gSFB_storage: cute.Tensor,
):
    gSFA = cute.make_tensor(
        gSFA_storage.iterator,
        sm120.make_mxf4nvf4_scale_interleaved_gmem_layout(128, 128, 1),
    )
    gSFB = cute.make_tensor(
        gSFB_storage.iterator,
        sm120.make_mxf4nvf4_scale_interleaved_gmem_layout(128, 128, 1),
    )
    sm120.make_mxf4nvf4_native_tma_atoms(
        gA,
        gB,
        gSFA,
        gSFB,
        ab_smem_format="unpack",
    )


@cute.jit
def _check_default_tiled_mma():
    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    assert tiled_mma.size == 256
    assert tiled_mma.get_tile_size(0) == 128
    assert tiled_mma.get_tile_size(2) == 64


@cute.kernel
def _check_native_tma_smem_view_dtypes_kernel(ab_smem_format: cutlass.Constexpr[str]):
    smem = SmemAllocator()
    sA, sB, sSFA, sSFB = sm120.make_mxf4nvf4_native_tma_smem_views(
        smem,
        ab_smem_format=ab_smem_format,
    )
    assert sA.element_type == cutlass.Float4E2M1FN
    assert sB.element_type == cutlass.Float4E2M1FN
    assert sSFA.element_type == cutlass.Float8E4M3FN
    assert sSFB.element_type == cutlass.Float8E4M3FN


@cute.kernel
def _check_native_tma_unpack_smem_view_dtypes_kernel():
    smem = SmemAllocator()
    sA, sB, sSFA, sSFB = sm120.make_mxf4nvf4_native_tma_smem_views(
        smem,
        ab_smem_format="unpack",
    )
    assert sA.element_type == cutlass.Uint8
    assert sB.element_type == cutlass.Uint8
    assert sSFA.element_type == cutlass.Float8E4M3FN
    assert sSFB.element_type == cutlass.Float8E4M3FN


@cute.jit
def _launch_check_native_tma_smem_view_dtypes():
    _check_native_tma_smem_view_dtypes_kernel("packed").launch(
        grid=[1, 1, 1], block=[1, 1, 1]
    )


@cute.jit
def _launch_check_native_tma_unpack_smem_view_dtypes():
    _check_native_tma_unpack_smem_view_dtypes_kernel().launch(
        grid=[1, 1, 1], block=[1, 1, 1]
    )


def _fake_fp4_tensor(memspace: cute.AddressSpace = cute.AddressSpace.gmem):
    return make_fake_compact_tensor(
        cutlass.Float4E2M1FN,
        (128, 128, 1),
        stride_order=(1, 0, 2),
        memspace=memspace,
        assumed_align=16,
    )


def _fake_fp8_scale_storage():
    return make_fake_compact_tensor(
        cutlass.Float8E4M3FN,
        (1024,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )


def _fake_uint8_scale_storage():
    return make_fake_compact_tensor(
        cutlass.Uint8,
        (1024,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )


def _fake_f16_tensor():
    return make_fake_compact_tensor(
        cutlass.Float16,
        (128, 128, 1),
        stride_order=(1, 0, 2),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )


def test_sm120_mxf4nvf4_scale_interleaved_layouts_are_exact():
    _check_scale_interleaved_layouts_exact()


def test_sm120_mxf4nvf4_default_tiled_mma_matches_full_tile_config():
    _check_default_tiled_mma()


def test_sm120_mxf4nvf4_native_tma_smem_view_dtypes_compile():
    cute.compile(_launch_check_native_tma_smem_view_dtypes)
    cute.compile(_launch_check_native_tma_unpack_smem_view_dtypes)


def test_sm120_mxf4nvf4_native_tma_atoms_compile():
    cute.compile(
        _build_native_tma_atoms,
        _fake_fp4_tensor(),
        _fake_fp4_tensor(),
        _fake_fp8_scale_storage(),
        _fake_fp8_scale_storage(),
    )


def test_sm120_mxf4nvf4_native_tma_atoms_unpack_compile():
    cute.compile(
        _build_native_tma_atoms_unpack,
        _fake_fp4_tensor(),
        _fake_fp4_tensor(),
        _fake_fp8_scale_storage(),
        _fake_fp8_scale_storage(),
    )


def test_sm120_mxf4nvf4_native_tma_atoms_reject_wrong_dtypes():
    with pytest.raises(Exception, match="gA.*Float4E2M1FN"):
        cute.compile(
            _build_native_tma_atoms,
            _fake_f16_tensor(),
            _fake_fp4_tensor(),
            _fake_fp8_scale_storage(),
            _fake_fp8_scale_storage(),
        )
    with pytest.raises(Exception, match="gSFA.*Float8E4M3FN"):
        cute.compile(
            _build_native_tma_atoms,
            _fake_fp4_tensor(),
            _fake_fp4_tensor(),
            _fake_uint8_scale_storage(),
            _fake_fp8_scale_storage(),
        )
    with pytest.raises(Exception, match="gA.*global-memory"):
        cute.compile(
            _build_native_tma_atoms,
            _fake_fp4_tensor(cute.AddressSpace.smem),
            _fake_fp4_tensor(),
            _fake_fp8_scale_storage(),
            _fake_fp8_scale_storage(),
        )
