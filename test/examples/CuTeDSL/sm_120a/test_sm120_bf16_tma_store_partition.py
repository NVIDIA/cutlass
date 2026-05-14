# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.utils import LayoutEnum
import cutlass.utils.blackwell_helpers as blackwell_helpers


_TILE_SHAPE_MN = (128, 128)
_EPI_TILE = (32, 32)
_COMPILE_OPTIONS = "--gpu-arch=sm_120a --enable-tvm-ffi"


def _make_n_major_bf16_d():
    return make_fake_compact_tensor(
        cutlass.BFloat16,
        (128, 128, 1),
        stride_order=(1, 0, 2),
        assumed_align=16,
    )


@cute.jit
def _compile_returned_tensor_partition(d: cute.Tensor):
    _returned_tensor_partition_kernel(d).launch(
        grid=(1, 1, 1),
        block=(128, 1, 1),
        smem=16384,
    )


@cute.kernel
def _returned_tensor_partition_kernel(d: cute.Tensor):
    smem = cutlass.utils.SmemAllocator()

    d_layout = LayoutEnum.from_tensor(d)
    smem_layout = blackwell_helpers.make_smem_layout_epi(
        d.element_type,
        d_layout,
        _EPI_TILE,
        1,
    )
    sD = smem.allocate_tensor(d.element_type, smem_layout, byte_alignment=1024)

    epi_smem_layout = cute.slice_(smem_layout, (None, None, 0))
    d_cta_v_layout = cute.composition(cute.make_identity_layout(d.shape), _EPI_TILE)
    tma_atom_d, tma_tensor_d = cpasync.make_tiled_tma_atom(
        cpasync.CopyBulkTensorTileS2GOp(),
        d,
        epi_smem_layout,
        d_cta_v_layout,
    )

    tD_mn = tma_tensor_d[None, None, 0]
    tD_tile = cute.local_tile(tD_mn, _TILE_SHAPE_MN, (0, 0))
    tD_epi = cute.flat_divide(tD_tile, _EPI_TILE)

    cpasync.tma_partition(
        tma_atom_d,
        0,
        cute.make_layout(1),
        cute.group_modes(sD, 0, 2),
        cute.group_modes(tD_epi, 0, 2),
    )


@cute.jit
def _compile_helper_partition(d: cute.Tensor):
    _helper_partition_kernel(d).launch(
        grid=(1, 1, 1),
        block=(128, 1, 1),
        smem=16384,
    )


@cute.kernel
def _helper_partition_kernel(d: cute.Tensor):
    smem = cutlass.utils.SmemAllocator()

    d_layout = LayoutEnum.from_tensor(d)
    smem_layout = blackwell_helpers.make_smem_layout_epi(
        d.element_type,
        d_layout,
        _EPI_TILE,
        1,
    )
    sD = smem.allocate_tensor(d.element_type, smem_layout, byte_alignment=1024)

    epi_smem_layout = cute.slice_(smem_layout, (None, None, 0))
    d_cta_v_layout = cute.composition(cute.make_identity_layout(d.shape), _EPI_TILE)
    tma_atom_d, tma_tensor_d = cpasync.make_tiled_tma_atom(
        cpasync.CopyBulkTensorTileS2GOp(),
        d,
        epi_smem_layout,
        d_cta_v_layout,
    )

    cpasync.tma_partition_s2g_tile(
        tma_atom_d,
        tma_tensor_d,
        sD,
        _TILE_SHAPE_MN,
        _EPI_TILE,
        (0, 0, 0, 0),
    )


@cute.jit
def _compile_reduce_helper_partition(d: cute.Tensor):
    _reduce_helper_partition_kernel(d).launch(
        grid=(1, 1, 1),
        block=(128, 1, 1),
        smem=16384,
    )


@cute.kernel
def _reduce_helper_partition_kernel(d: cute.Tensor):
    smem = cutlass.utils.SmemAllocator()

    d_layout = LayoutEnum.from_tensor(d)
    smem_layout = blackwell_helpers.make_smem_layout_epi(
        d.element_type,
        d_layout,
        _EPI_TILE,
        1,
    )
    sD = smem.allocate_tensor(d.element_type, smem_layout, byte_alignment=1024)

    epi_smem_layout = cute.slice_(smem_layout, (None, None, 0))
    d_cta_v_layout = cute.composition(cute.make_identity_layout(d.shape), _EPI_TILE)
    tma_atom_d, tma_tensor_d = cpasync.make_tiled_tma_atom(
        cpasync.CopyReduceBulkTensorTileS2GOp(),
        d,
        epi_smem_layout,
        d_cta_v_layout,
    )

    cpasync.tma_partition_s2g_tile(
        tma_atom_d,
        tma_tensor_d,
        sD,
        _TILE_SHAPE_MN,
        _EPI_TILE,
        (0, 0, 0, 0),
    )


@cute.jit
def _compile_ordinary_gmem_partition(d: cute.Tensor):
    _ordinary_gmem_partition_kernel(d).launch(
        grid=(1, 1, 1),
        block=(128, 1, 1),
        smem=16384,
    )


@cute.kernel
def _ordinary_gmem_partition_kernel(d: cute.Tensor):
    smem = cutlass.utils.SmemAllocator()

    d_layout = LayoutEnum.from_tensor(d)
    smem_layout = blackwell_helpers.make_smem_layout_epi(
        d.element_type,
        d_layout,
        _EPI_TILE,
        1,
    )
    sD = smem.allocate_tensor(d.element_type, smem_layout, byte_alignment=1024)

    epi_smem_layout = cute.slice_(smem_layout, (None, None, 0))
    d_cta_v_layout = cute.composition(cute.make_identity_layout(d.shape), _EPI_TILE)
    tma_atom_d, _ = cpasync.make_tiled_tma_atom(
        cpasync.CopyBulkTensorTileS2GOp(),
        d,
        epi_smem_layout,
        d_cta_v_layout,
    )

    gD_mn = d[None, None, 0]
    gD_tile = cute.local_tile(gD_mn, _TILE_SHAPE_MN, (0, 0))
    gD_epi = cute.flat_divide(gD_tile, _EPI_TILE)

    cpasync.tma_partition(
        tma_atom_d,
        0,
        cute.make_layout(1),
        cute.group_modes(sD, 0, 2),
        cute.group_modes(gD_epi, 0, 2),
    )


@pytest.mark.parametrize(
    "compile_fn",
    [
        _compile_returned_tensor_partition,
        _compile_helper_partition,
        _compile_reduce_helper_partition,
    ],
)
def test_sm120_bf16_s2g_tma_store_partition_uses_returned_tma_tensor(compile_fn):
    compiled = cute.compile(
        compile_fn,
        _make_n_major_bf16_d(),
        options=_COMPILE_OPTIONS,
    )
    assert compiled


def test_sm120_bf16_s2g_tma_store_partition_rejects_ordinary_gmem_tile():
    with pytest.raises(ValueError, match="returned by cpasync.make_tiled_tma_atom"):
        cute.compile(
            _compile_ordinary_gmem_partition,
            _make_n_major_bf16_d(),
            options=_COMPILE_OPTIONS,
        )


def test_sm120_bf16_s2g_tma_store_partition_helper_rejects_short_coord():
    class FakeS2GAtom:
        op = cpasync.CopyBulkTensorTileS2GOp()

    with pytest.raises(
        ValueError, match="tile_coord_mnkl must have at least four modes"
    ):
        cpasync.tma_partition_s2g_tile(
            FakeS2GAtom(),
            _make_n_major_bf16_d(),
            _make_n_major_bf16_d(),
            _TILE_SHAPE_MN,
            _EPI_TILE,
            (0, 0, 0),
        )
