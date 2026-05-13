# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest

import cutlass
import cutlass.cute as cute
from cutlass import pipeline
from cutlass.base_dsl.common import CudaDriverDependencyError
from cutlass.cute.runtime import from_dlpack


pytestmark = [pytest.mark.arch(["120a"])]


def _aligned_u8_tensor(num_bytes: int, alignment: int):
    torch = pytest.importorskip("torch")
    storage = torch.empty(num_bytes + alignment - 1, device="cuda", dtype=torch.uint8)
    offset = (-storage.data_ptr()) % alignment
    view = storage[offset : offset + num_bytes]
    assert view.data_ptr() % alignment == 0
    return storage, view


def _device_desc_from_bytes(desc_bytes: bytes):
    torch = pytest.importorskip("torch")
    storage, view = _aligned_u8_tensor(128, 128)
    view.copy_(torch.tensor(list(desc_bytes), device="cuda", dtype=torch.uint8))
    return storage, view


@cute.kernel
def _sm120_tma_canary_kernel(
    desc: cute.Tensor,
    out: cute.Tensor,
    num_bytes: cutlass.Constexpr[int],
    rank: cutlass.Constexpr[int],
    tx_count: cutlass.Constexpr[int],
    coord0: cutlass.Constexpr[int],
    coord1: cutlass.Constexpr[int],
    coord2: cutlass.Constexpr[int],
    coord3: cutlass.Constexpr[int],
):
    smem = cutlass.utils.SmemAllocator()
    smem_tensor = smem.allocate_tensor(
        cutlass.Uint8, cute.make_layout(num_bytes), byte_alignment=128
    )
    barriers = smem.allocate_array(cutlass.Int64, 2, byte_alignment=8)
    tidx, _, _ = cute.arch.thread_idx()

    for i in cutlass.range(tidx, num_bytes, 32):
        smem_tensor[i] = cutlass.Uint8(0xCD)
    cute.arch.sync_threads()

    pipe = pipeline.PipelineTmaWarpMma.create(
        num_stages=1,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        tx_count=tx_count,
        barrier_storage=barriers,
    )
    producer_state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Producer, 1)
    consumer_state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Consumer, 1)

    if rank == 3:
        pipeline.producer_acquire_issue_tma_load_3d(
            pipe,
            producer_state,
            None,
            smem_tensor.iterator,
            desc.iterator,
            coord0,
            coord1,
            coord2,
            already_elected=False,
        )
    else:
        pipeline.producer_acquire_issue_tma_load_4d(
            pipe,
            producer_state,
            None,
            smem_tensor.iterator,
            desc.iterator,
            coord0,
            coord1,
            coord2,
            coord3,
            already_elected=False,
        )

    pipe.consumer_wait(consumer_state)
    cute.arch.sync_threads()
    for i in cutlass.range(tidx, num_bytes, 32):
        out[i] = smem_tensor[i]
    pipe.consumer_release(consumer_state)


@cute.jit
def _launch_sm120_tma_canary(
    desc: cute.Tensor,
    out: cute.Tensor,
    num_bytes: cutlass.Constexpr[int],
    rank: cutlass.Constexpr[int],
    tx_count: cutlass.Constexpr[int],
    coord0: cutlass.Constexpr[int],
    coord1: cutlass.Constexpr[int],
    coord2: cutlass.Constexpr[int],
    coord3: cutlass.Constexpr[int],
):
    _sm120_tma_canary_kernel(
        desc, out, num_bytes, rank, tx_count, coord0, coord1, coord2, coord3
    ).launch(grid=[1, 1, 1], block=[32, 1, 1])


def _run_canary(desc_bytes, expected, output_bytes, rank, tx_count, coords, touched_bytes):
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    desc_storage, desc = _device_desc_from_bytes(desc_bytes)
    out = torch.empty(output_bytes, device="cuda", dtype=torch.uint8)
    out.fill_(0xCD)
    assert int((out != 0).sum().item()) == output_bytes
    cute_desc = from_dlpack(desc, assumed_align=128, enable_tvm_ffi=True)
    cute_out = from_dlpack(out, assumed_align=16, enable_tvm_ffi=True)
    cute.compile(
        _launch_sm120_tma_canary,
        cute_desc,
        cute_out,
        output_bytes,
        rank,
        tx_count,
        coords[0],
        coords[1],
        coords[2],
        coords[3],
        options="--enable-tvm-ffi",
    )(cute_desc, cute_out)
    torch.cuda.synchronize()
    assert desc_storage is not None
    assert torch.equal(out, expected)
    assert torch.all(out[touched_bytes:] == 0xCD)


def _patterned_u8(torch, count: int):
    values = torch.arange(count, device="cuda", dtype=torch.int32)
    return torch.bitwise_xor(values, 0x5A).to(torch.uint8)


def _expected_rank3_fp4_tma_output(torch, src, output_bytes: int):
    expected = torch.full((output_bytes,), 0xCD, device="cuda", dtype=torch.uint8)
    payload_bytes = src.numel()
    for dst_payload_chunk in range(payload_bytes // 8):
        # 16U4_ALIGN16B copies each 8-byte packed-FP4 payload chunk into the
        # first half of a 16-byte shared-memory slot. The 128B swizzle permutes
        # the source payload chunk by xor'ing the chunk index with the 128B row
        # bits; the high half of each destination slot remains the guard value.
        dst_base = dst_payload_chunk * 16
        src_swizzle_chunk = dst_payload_chunk ^ ((dst_payload_chunk >> 3) & 0x7)
        src_base = src_swizzle_chunk * 8
        expected[dst_base : dst_base + 8] = src[src_base : src_base + 8]
    return expected


def _expected_rank3_fp4_tma_output_from_logical_tile(
    torch,
    src,
    output_bytes: int,
    *,
    k_extent: int,
    major_extent: int,
    coord_k: int,
    coord_major: int,
    coord_l: int = 0,
):
    major_stride = k_extent // 2
    l_stride = major_stride * major_extent
    payload = torch.empty((8192,), device="cuda", dtype=torch.uint8)
    for major in range(128):
        src_base = (
            coord_l * l_stride
            + (coord_major + major) * major_stride
            + coord_k // 2
        )
        dst_base = major * 64
        payload[dst_base : dst_base + 64] = src[src_base : src_base + 64]
    return _expected_rank3_fp4_tma_output(torch, payload, output_bytes)


def _expected_rank4_scale_tma_output(torch, src, output_bytes: int):
    expected = torch.full((output_bytes,), 0xCD, device="cuda", dtype=torch.uint8)
    payload_bytes = src.numel()
    for dst_chunk in range(payload_bytes // 16):
        # The UINT8 scale descriptor writes dense 16-byte chunks. Its 128B
        # swizzle uses the same xor-by-row mapping, but without FP4 ALIGN16
        # padding between destination payload chunks.
        src_chunk = dst_chunk ^ (dst_chunk >> 3)
        expected[dst_chunk * 16 : (dst_chunk + 1) * 16] = src[
            src_chunk * 16 : (src_chunk + 1) * 16
        ]
    return expected


def test_sm120_mxf4nvf4_rank3_external_descriptor_tma_canary():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    src_storage, src = _aligned_u8_tensor(8192, 32)
    src.copy_(_patterned_u8(torch, src.numel()))
    try:
        desc = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(src.data_ptr())
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")
    assert src_storage is not None
    output_bytes = 17408
    expected = _expected_rank3_fp4_tma_output(torch, src, output_bytes)
    _run_canary(desc, expected, output_bytes, 3, 8192, (0, 0, 0, 0), 16384)


def test_sm120_mxf4nvf4_rank3_external_descriptor_nonzero_coordinate_canary():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    src_storage, src = _aligned_u8_tensor(16384, 32)
    src[:8192].copy_(_patterned_u8(torch, 8192))
    src[8192:16384].copy_(torch.bitwise_xor(_patterned_u8(torch, 8192), 0xA5))
    try:
        desc = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(
            src.data_ptr(), l_extent=2
        )
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")
    assert src_storage is not None
    output_bytes = 17408
    expected = _expected_rank3_fp4_tma_output(torch, src[8192:16384], output_bytes)
    _run_canary(desc, expected, output_bytes, 3, 8192, (0, 0, 1, 0), 16384)


def test_sm120_mxf4nvf4_rank3_external_descriptor_nonzero_k_tile_canary():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    src_storage, src = _aligned_u8_tensor(16384, 32)
    src.copy_(_patterned_u8(torch, src.numel()))
    try:
        desc = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(
            src.data_ptr(), k_extent=256
        )
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")
    assert src_storage is not None
    output_bytes = 17408
    expected = _expected_rank3_fp4_tma_output_from_logical_tile(
        torch,
        src,
        output_bytes,
        k_extent=256,
        major_extent=128,
        coord_k=128,
        coord_major=0,
    )
    _run_canary(desc, expected, output_bytes, 3, 8192, (128, 0, 0, 0), 16384)


def test_sm120_mxf4nvf4_rank3_external_descriptor_nonzero_major_tile_canary():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    src_storage, src = _aligned_u8_tensor(16384, 32)
    src.copy_(_patterned_u8(torch, src.numel()))
    try:
        desc = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(
            src.data_ptr(), major_extent=256, box_major_extent=128
        )
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")
    assert src_storage is not None
    output_bytes = 17408
    expected = _expected_rank3_fp4_tma_output_from_logical_tile(
        torch,
        src,
        output_bytes,
        k_extent=128,
        major_extent=256,
        coord_k=0,
        coord_major=128,
    )
    _run_canary(desc, expected, output_bytes, 3, 8192, (0, 128, 0, 0), 16384)


def test_sm120_mxf4nvf4_scale_rank4_external_descriptor_tma_canary():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    src_storage, src = _aligned_u8_tensor(1024, 16)
    src.copy_(_patterned_u8(torch, src.numel()))
    try:
        desc = cutlass.utils.make_sm120_mxf4nvf4_scale_tma_desc_bytes(src.data_ptr())
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")
    assert src_storage is not None
    expected = _expected_rank4_scale_tma_output(torch, src, 2048)
    _run_canary(desc, expected, 2048, 4, 1024, (0, 0, 0, 0), 1024)


def test_sm120_mxf4nvf4_scale_rank4_external_descriptor_nonzero_coordinate_canary():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    src_storage, src = _aligned_u8_tensor(2048, 16)
    src.copy_(_patterned_u8(torch, src.numel()))
    expected_src = src[128:1152].clone()
    try:
        desc = cutlass.utils.make_sm120_mxf4nvf4_scale_tma_desc_bytes(
            src.data_ptr(), tile_extent=2
        )
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")
    assert src_storage is not None
    expected = _expected_rank4_scale_tma_output(torch, expected_src, 2048)
    _run_canary(desc, expected, 2048, 4, 1024, (0, 1, 0, 0), 1024)


def test_sm120_mxf4nvf4_scale_rank4_external_descriptor_scale_k_substep_is_view_offset():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    src_storage, src = _aligned_u8_tensor(2048, 16)
    src.copy_(_patterned_u8(torch, src.numel()))
    # The external scale descriptor transfers the full logical scale-K box.
    # K64 substep selection is handled by the SMEM scale-fragment view, not by
    # issuing a second descriptor coordinate inside the scale-K box.
    expected_src = src[:1024].clone()
    try:
        desc = cutlass.utils.make_sm120_mxf4nvf4_scale_tma_desc_bytes(
            src.data_ptr(), scale_k_extent=16, logical_scale_k_extent=8
        )
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")
    assert src_storage is not None
    expected = _expected_rank4_scale_tma_output(torch, expected_src, 2048)
    _run_canary(desc, expected, 2048, 4, 1024, (0, 8, 0, 0), 1024)


def test_sm120_mxf4nvf4_driver_descriptor_path_repro():
    cutlass.utils.validate_sm120_mxf4nvf4_tma_desc(
        base_ptr=0x1000,
        global_dim=(128, 128, 1),
        global_strides_bytes=(64, 8192),
        box_dim=(128, 128, 1),
        tx_count=8192,
    )
