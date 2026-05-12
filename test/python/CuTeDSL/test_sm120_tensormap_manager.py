# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import ctypes

import pytest

from cutlass import utils
from cutlass.base_dsl.common import CudaDriverDependencyError
from cutlass.utils import tensormap_manager as tm


def _cuda_driver():
    return pytest.importorskip("cuda.bindings.driver")


def test_sm120_driver_descriptor_storage_is_64b_aligned():
    backing, tensor_map, address = tm._make_aligned_cu_tensor_map()

    assert address % 64 == 0
    assert ctypes.addressof(tensor_map) == address
    assert len(tm._cu_tensor_map_to_bytes(address)) == utils.SM120_MXF4NVF4_TENSOR_MAP_BYTES
    assert backing is not None


def test_sm120_tensormap_driver_enum_names_resolve():
    cuda_driver = _cuda_driver()

    assert (
        tm._cuda_enum_value(
            cuda_driver.CUtensorMapDataType.CU_TENSOR_MAP_DATA_TYPE_16U4_ALIGN16B
        )
        >= 0
    )
    assert (
        tm._cuda_enum_value(cuda_driver.CUtensorMapSwizzle.CU_TENSOR_MAP_SWIZZLE_128B)
        >= 0
    )


def test_sm120_fp4_descriptor_validation_default_and_rejections():
    valid = dict(
        base_ptr=0x1000,
        desc_ptr=0x2000,
        global_dim=(128, 128, 1),
        global_strides_bytes=(64, 8192),
        box_dim=(128, 128, 1),
        element_strides=(1, 1, 1),
        tx_count=8192,
    )
    utils.validate_sm120_mxf4nvf4_tma_desc(**valid)

    rejects = [
        dict(base_ptr=0x1008),
        dict(desc_ptr=0x2020),
        dict(global_dim=(128, 128)),
        dict(global_dim=(64, 128, 1)),
        dict(box_dim=(64, 128, 1)),
        dict(global_strides_bytes=(66, 8192)),
        dict(global_strides_bytes=(32, 8192)),
        dict(global_strides_bytes=(64, 4096)),
        dict(box_dim=(128, 129, 1)),
        dict(box_dim=(128, 128, 2)),
        dict(tx_count=4096),
    ]
    for update in rejects:
        with pytest.raises(ValueError):
            utils.validate_sm120_mxf4nvf4_tma_desc(**dict(valid, **update))


def test_sm120_scale_descriptor_validation_default_and_rejections():
    valid = dict(
        base_ptr=0x1000,
        desc_ptr=0x2000,
        global_dim=(128, 16, 1, 1),
        global_strides_bytes=(128, 2048, 2048),
        box_dim=(128, 8, 1, 1),
        element_strides=(1, 1, 1, 1),
        tx_count=1024,
    )
    utils.validate_sm120_mxf4nvf4_scale_tma_desc(**valid)
    assert utils.sm120_mxf4nvf4_padded_scale_k_extent(8) == 16
    assert utils.sm120_mxf4nvf4_padded_scale_k_extent(17) == 32

    rejects = [
        dict(base_ptr=0x1001),
        dict(global_dim=(128, 16, 1)),
        dict(global_dim=(128, 8, 1, 1)),
        dict(global_strides_bytes=(130, 2048, 2048)),
        dict(global_strides_bytes=(64, 2048, 2048)),
        dict(global_strides_bytes=(128, 1024, 2048)),
        dict(global_dim=(128, 16, 2, 1), global_strides_bytes=(128, 2048, 2048)),
        dict(box_dim=(129, 8, 1, 1)),
        dict(box_dim=(128, 17, 1, 1)),
        dict(box_dim=(128, 8, 2, 1)),
        dict(tx_count=2048),
    ]
    for update in rejects:
        with pytest.raises(ValueError):
            utils.validate_sm120_mxf4nvf4_scale_tma_desc(**dict(valid, **update))


def _install_fake_encoder(monkeypatch):
    calls = []

    def encode(
        tensor_map_ptr,
        data_type,
        rank,
        global_address,
        global_dim,
        global_strides,
        box_dim,
        element_strides,
        interleave,
        swizzle,
        l2_promotion,
        oob_fill,
    ):
        tensor_map = ctypes.cast(tensor_map_ptr, ctypes.POINTER(tm._CUtensorMap)).contents
        tensor_map.opaque[0] = data_type
        tensor_map.opaque[1] = rank
        calls.append(
            {
                "data_type": data_type,
                "rank": rank,
                "base": global_address.value,
                "global_dim": tuple(global_dim[i] for i in range(rank)),
                "global_strides": tuple(global_strides[i] for i in range(rank - 1)),
                "box_dim": tuple(box_dim[i] for i in range(rank)),
                "element_strides": tuple(element_strides[i] for i in range(rank)),
                "interleave": interleave,
                "swizzle": swizzle,
                "l2_promotion": l2_promotion,
                "oob_fill": oob_fill,
            }
        )
        return 0

    monkeypatch.setattr(tm, "_get_cuda_tensormap_encoder", lambda: encode)
    return calls


def test_sm120_fp4_driver_descriptor_builder_fields(monkeypatch):
    cuda_driver = _cuda_driver()
    calls = _install_fake_encoder(monkeypatch)

    desc = utils.make_sm120_mxf4nvf4_tma_desc_bytes(0x1000)

    assert len(desc) == utils.SM120_MXF4NVF4_TENSOR_MAP_BYTES
    assert calls == [
        {
            "data_type": tm._cuda_enum_value(
                cuda_driver.CUtensorMapDataType.CU_TENSOR_MAP_DATA_TYPE_16U4_ALIGN16B
            ),
            "rank": 3,
            "base": 0x1000,
            "global_dim": (128, 128, 1),
            "global_strides": (64, 8192),
            "box_dim": (128, 128, 1),
            "element_strides": (1, 1, 1),
            "interleave": tm._cuda_enum_value(
                cuda_driver.CUtensorMapInterleave.CU_TENSOR_MAP_INTERLEAVE_NONE
            ),
            "swizzle": tm._cuda_enum_value(
                cuda_driver.CUtensorMapSwizzle.CU_TENSOR_MAP_SWIZZLE_128B
            ),
            "l2_promotion": tm._cuda_enum_value(
                cuda_driver.CUtensorMapL2promotion.CU_TENSOR_MAP_L2_PROMOTION_L2_128B
            ),
            "oob_fill": tm._cuda_enum_value(
                cuda_driver.CUtensorMapFloatOOBfill.CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE
            ),
        }
    ]

    with pytest.raises(ValueError):
        utils.make_sm120_mxf4nvf4_tma_desc_bytes(0x1000, major_extent=0)
    with pytest.raises(ValueError):
        utils.make_sm120_mxf4nvf4_tma_desc_bytes(
            0x1000, major_extent=128, box_major_extent=129
        )


def test_sm120_scale_driver_descriptor_builder_fields(monkeypatch):
    cuda_driver = _cuda_driver()
    calls = _install_fake_encoder(monkeypatch)

    desc = utils.make_sm120_mxf4nvf4_scale_tma_desc_bytes(0x1000)

    assert len(desc) == utils.SM120_MXF4NVF4_TENSOR_MAP_BYTES
    assert calls == [
        {
            "data_type": tm._cuda_enum_value(
                cuda_driver.CUtensorMapDataType.CU_TENSOR_MAP_DATA_TYPE_UINT8
            ),
            "rank": 4,
            "base": 0x1000,
            "global_dim": (128, 16, 1, 1),
            "global_strides": (128, 2048, 2048),
            "box_dim": (128, 8, 1, 1),
            "element_strides": (1, 1, 1, 1),
            "interleave": tm._cuda_enum_value(
                cuda_driver.CUtensorMapInterleave.CU_TENSOR_MAP_INTERLEAVE_NONE
            ),
            "swizzle": tm._cuda_enum_value(
                cuda_driver.CUtensorMapSwizzle.CU_TENSOR_MAP_SWIZZLE_128B
            ),
            "l2_promotion": tm._cuda_enum_value(
                cuda_driver.CUtensorMapL2promotion.CU_TENSOR_MAP_L2_PROMOTION_L2_128B
            ),
            "oob_fill": tm._cuda_enum_value(
                cuda_driver.CUtensorMapFloatOOBfill.CU_TENSOR_MAP_FLOAT_OOB_FILL_NONE
            ),
        }
    ]

    with pytest.raises(ValueError):
        utils.make_sm120_mxf4nvf4_scale_tma_desc_bytes(0x1000, tile_extent=0)
    with pytest.raises(ValueError):
        utils.make_sm120_mxf4nvf4_scale_tma_desc_bytes(
            0x1000, major_extent=128, box_major_extent=129
        )


def test_sm120_driver_descriptor_builders_real_driver_smoke():
    _cuda_driver()
    try:
        tm._get_cuda_tensormap_encoder()
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")

    fp4_storage = torch.empty((8192,), device="cuda", dtype=torch.uint8)
    scale_storage = torch.empty((2048,), device="cuda", dtype=torch.uint8)

    assert len(utils.make_sm120_mxf4nvf4_tma_desc_bytes(fp4_storage.data_ptr())) == 128
    assert len(
        utils.make_sm120_mxf4nvf4_scale_tma_desc_bytes(scale_storage.data_ptr())
    ) == 128
