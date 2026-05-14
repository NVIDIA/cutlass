# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import importlib.util
import subprocess
from pathlib import Path

import pytest

import cutlass
import cutlass.cute as cute
from cutlass.base_dsl.common import CudaDriverDependencyError
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack
from cutlass.cute.runtime import make_fake_compact_tensor
from cutlass.utils.gemm import sm120


pytestmark = [pytest.mark.arch(["120a"])]


def _load_example():
    path = (
        Path(__file__).parents[4]
        / "examples/python/CuTeDSL/blackwell_geforce/sm120_mxf4nvf4_tma_mainloop.py"
    )
    spec = importlib.util.spec_from_file_location("sm120_mxf4nvf4_tma_mainloop", path)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def test_sm120_mxf4nvf4_tma_mainloop_ptx_inspect():
    example = _load_example()
    compiled = example.compile_mainloop(keep_ptx=True)
    ptx = compiled.__ptx__

    example.inspect_ptx(ptx)
    assert "fence.proxy.tensormap::generic.acquire.gpu" in ptx
    assert ptx.count("cp.async.bulk.tensor.3d.shared::cta.global.tile") == 2
    assert ptx.count("cp.async.bulk.tensor.4d.shared::cta.global.tile") == 2
    assert "shared::cluster" not in ptx
    assert ".multicast" not in ptx
    assert "tcgen05" not in ptx


def test_sm120_mxf4nvf4_tma_mainloop_sass_inspect(tmp_path):
    nvdisasm = Path("/usr/local/cuda/bin/nvdisasm")
    if not nvdisasm.exists():
        pytest.skip("nvdisasm unavailable")
    example = _load_example()
    compiled = example.compile_mainloop(keep_ptx=False, keep_cubin=True)
    cubin = compiled.artifacts.CUBIN
    if not isinstance(cubin, bytes):
        pytest.skip("CuTe DSL CUBIN artifact unavailable")

    cubin_path = tmp_path / "sm120_mxf4nvf4_tma_mainloop.cubin"
    cubin_path.write_bytes(cubin)
    sass = subprocess.check_output([str(nvdisasm), str(cubin_path)], text=True)

    assert "LDSM.16.M88.4" in sass
    assert "OMMA.SF.16864.F32.E2M1.E2M1.UE4M3.4X" in sass
    assert "TCGEN05" not in sass


def test_sm120_mxf4nvf4_tma_mainloop_uses_atom_copy_path():
    source = (
        Path(__file__).parents[4]
        / "examples/python/CuTeDSL/blackwell_geforce/sm120_mxf4nvf4_tma_mainloop.py"
    ).read_text()

    assert "sm120_tma_load_3d" not in source
    assert "sm120_tma_load_4d" not in source
    assert "make_mxf4nvf4_tiled_tma_atom_a" in source
    assert "cpasync.tma_partition" in source
    assert "stage_mxf4nvf4_ab_tma_physical_to_consumer_smem" in source
    assert "load_mxf4nvf4_ab_fragments_from_consumer_smem" in source
    assert "load_mxf4nvf4_ldsm_scratch_fragments" not in source
    assert "stage_mxf4nvf4_ab_tma_physical_to_ldsm_scratch" not in source
    assert "stage_mxf4nvf4_a_tma_physical_to_ldsm_scratch" not in source
    assert "stage_mxf4nvf4_b_tma_physical_to_ldsm_scratch" not in source
    assert "make_mxf4nvf4_ldsm_scratch_views" not in source
    assert "allocate_mxf4nvf4_ldsm_scratch" not in source
    assert "stage_mxf4nvf4_scale_tma_physical_to_fragment_scratch" in source
    assert "make_mxf4nvf4_scale_fragment_views_from_scratch" in source
    assert "cute.copy(" in source
    assert "tma_desc_ptr=" in source


@cute.kernel
def _consumer_smem_ldsm_copy_path_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    smem = cutlass.utils.SmemAllocator()
    sA, sB = sm120.make_mxf4nvf4_ab_consumer_smem_views(smem)
    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    a, b = sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem(
        tiled_mma, sA, sB, tidx
    )
    sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem(
        tiled_mma, sA, sB, a, b, tidx, 0
    )
    out[0] = cutlass.Float32(0.0)


@cute.jit
def _launch_consumer_smem_ldsm_copy_path(out: cute.Tensor):
    _consumer_smem_ldsm_copy_path_kernel(out).launch(
        grid=[1, 1, 1], block=[32, 1, 1], smem=65536
    )


def test_sm120_mxf4nvf4_consumer_smem_ldsm_copy_path_compile():
    out = make_fake_compact_tensor(cutlass.Float32, (1,))
    compiled = cute.compile(
        _launch_consumer_smem_ldsm_copy_path, out, options="--keep-ptx"
    )

    assert "ldmatrix.sync.aligned.m8n8.x4.shared.b16" in compiled.__ptx__
    assert "ldmatrix.sync.aligned.m8n8.x4.trans.shared.b16" not in compiled.__ptx__


@cute.kernel
def _consumer_smem_logical_fill_mma_kernel(
    out: cute.Tensor, case_id: cutlass.Constexpr[int]
):
    tidx, _, _ = cute.arch.thread_idx()
    smem = cutlass.utils.SmemAllocator()
    sA, sB = sm120.make_mxf4nvf4_ab_consumer_smem_views(smem)
    sA_u8 = cute.recast_tensor(sA, cutlass.Uint8)
    sB_u8 = cute.recast_tensor(sB, cutlass.Uint8)
    for i in cutlass.range(tidx, sm120.MXF4NVF4_AB_TMA_BYTES, 32):
        major = i // (sm120.MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
        k_byte = i % (sm120.MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
        sA_u8[(major, k_byte, 0)] = cutlass.Uint8(0)
        sB_u8[(major, k_byte, 0)] = cutlass.Uint8(0)
        if cutlass.const_expr(case_id == 0):
            sA_u8[(major, k_byte, 0)] = cutlass.Uint8(0x22)
            sB_u8[(major, k_byte, 0)] = cutlass.Uint8(0x22)
        elif cutlass.const_expr(case_id == 1):
            sA_u8[(major, k_byte, 0)] = cutlass.Uint8(0x22)
            def set_b() -> None:
                sB_u8[(major, k_byte, 0)] = cutlass.Uint8(0x22)

            cutlass.if_generate(major < 4, set_b)
        elif cutlass.const_expr(case_id == 2):
            sA_u8[(major, k_byte, 0)] = cutlass.Uint8(0x22)
            def set_b() -> None:
                sB_u8[(major, k_byte, 0)] = cutlass.Uint8(0x22)

            cutlass.if_generate(major == 3, set_b)
        elif cutlass.const_expr(case_id == 3):
            def set_a() -> None:
                sA_u8[(major, k_byte, 0)] = cutlass.Uint8(0x22)

            cutlass.if_generate(major < 8, set_a)
            sB_u8[(major, k_byte, 0)] = cutlass.Uint8(0x22)
        elif cutlass.const_expr(case_id == 4):
            sA_u8[(major, k_byte, 0)] = cutlass.Uint8(0x02)
            sB_u8[(major, k_byte, 0)] = cutlass.Uint8(0x02)
        elif cutlass.const_expr(case_id == 5):
            sA_u8[(major, k_byte, 0)] = cutlass.Uint8(0x02)
            sB_u8[(major, k_byte, 0)] = cutlass.Uint8(0x20)
    cute.arch.sync_threads()

    sSFA = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    sSFB = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    sSFA_f8 = cute.recast_tensor(sSFA, cutlass.Float8E4M3FN)
    sSFB_f8 = cute.recast_tensor(sSFB, cutlass.Float8E4M3FN)
    for i in cutlass.range(tidx, sm120.MXF4NVF4_SCALE_TMA_BYTES, 32):
        sSFA_f8[i] = cutlass.Float8E4M3FN(1.0)
        sSFB_f8[i] = cutlass.Float8E4M3FN(1.0)
    cute.arch.sync_threads()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    a, b = sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem(
        tiled_mma, sA, sB, tidx
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem(
            tiled_mma, sA, sB, a, b, tidx, k_block_idx
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
            sSFA, sSFB, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(
            tiled_mma,
            acc,
            (a[(None, 0, k_block_idx)], sfa),
            (b[(None, 0, k_block_idx)], sfb),
            acc,
        )
        cute.arch.sync_threads()

    for i in cutlass.range(cute.size(acc), unroll_full=True):
        out[tidx * cute.size(acc) + i] = acc[i]


@cute.jit
def _launch_consumer_smem_logical_fill_mma(
    out: cute.Tensor, case_id: cutlass.Constexpr[int]
):
    _consumer_smem_logical_fill_mma_kernel(out, case_id).launch(
        grid=[1, 1, 1], block=[32, 1, 1], smem=65536
    )


def _expected_raw_accumulator(torch, case_name: str):
    expected = torch.zeros((32, 4), device="cuda", dtype=torch.float32)
    if case_name == "all_ones":
        expected.fill_(128.0)
    elif case_name == "b_varies_by_logical_n":
        expected[torch.arange(32, device="cuda") % 4 < 2, :] = 128.0
    elif case_name == "sparse_b_logical_n_probe":
        expected[torch.arange(32, device="cuda") % 4 == 1, 1] = 128.0
        expected[torch.arange(32, device="cuda") % 4 == 1, 3] = 128.0
    elif case_name == "a_varies_by_logical_m":
        expected[:, 0:2] = 128.0
    elif case_name == "low_nibble_only":
        expected.fill_(64.0)
    elif case_name == "cross_nibble_zero":
        pass
    else:
        raise AssertionError(f"unknown case {case_name}")
    return expected.reshape(-1)


def _expected_multi_warp_m_atom_accumulator(torch):
    expected = torch.zeros((8, 32, 4), device="cuda", dtype=torch.float32)
    lane_mask = torch.arange(32, device="cuda") % 4 < 2
    for m_atom in range(8):
        if m_atom % 2 == 0:
            expected[m_atom, lane_mask, 0:2] = 128.0
        else:
            expected[m_atom, lane_mask, 2:4] = 128.0
    return expected.reshape(-1)


def _expected_multi_warp_m_atom_one_hot_accumulator(torch):
    expected = torch.zeros((8, 8, 32, 4), device="cuda", dtype=torch.float32)
    tile = _expected_raw_accumulator(torch, "all_ones").reshape(32, 4)
    for m_atom in range(8):
        expected[m_atom, m_atom] = tile
    return expected.reshape(-1)


def _expected_multi_warp_n_atom_one_hot_accumulator(torch, n_base: int):
    expected = torch.zeros((16, 8, 32, 4), device="cuda", dtype=torch.float32)
    tile = _expected_raw_accumulator(torch, "all_ones").reshape(32, 4)
    for n_atom in range(16):
        if n_base <= n_atom < n_base + 8:
            expected[n_atom, n_atom - n_base] = tile
    return expected.reshape(-1)


@pytest.mark.parametrize(
    ("case_name", "case_id"),
    [
        ("all_ones", 0),
        ("b_varies_by_logical_n", 1),
        ("sparse_b_logical_n_probe", 2),
        ("a_varies_by_logical_m", 3),
        ("low_nibble_only", 4),
        ("cross_nibble_zero", 5),
    ],
)
def test_sm120_mxf4nvf4_consumer_smem_logical_fill_mma_runtime(
    case_name, case_id
):
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    cute_out = from_dlpack(out, enable_tvm_ffi=True)
    compiled = cute.compile(
        _launch_consumer_smem_logical_fill_mma,
        cute_out,
        case_id,
        options="--enable-tvm-ffi --keep-ptx",
    )
    assert "ldmatrix.sync.aligned.m8n8.x4.shared.b16" in compiled.__ptx__
    assert "ldmatrix.sync.aligned.m8n8.x4.trans.shared.b16" not in compiled.__ptx__
    compiled(cute_out)
    torch.cuda.synchronize()
    expected = _expected_raw_accumulator(torch, case_name)
    assert torch.equal(out, expected), (case_name, out.reshape(32, 4).cpu())


@cute.kernel
def _stage1_lane_idx_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    lane_idx = tidx % 32
    smem = cutlass.utils.SmemAllocator()
    sA_tma, _, sB_tma, _ = sm120.make_mxf4nvf4_ab_smem_views(smem, num_stages=2)
    sA_consumer, sB_consumer = sm120.make_mxf4nvf4_ab_consumer_smem_views(
        smem, num_stages=2
    )
    sA_phys = cute.make_tensor(
        sA_tma.iterator, cute.make_layout(2 * sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sB_phys = cute.make_tensor(
        sB_tma.iterator, cute.make_layout(2 * sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sSFA = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    sSFB = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    for i in cutlass.range(lane_idx, sm120.MXF4NVF4_AB_SMEM_BYTES, 32):
        stage1_i = sm120.MXF4NVF4_AB_SMEM_BYTES + i
        sA_phys[stage1_i] = cutlass.Uint8(0)
        sB_phys[stage1_i] = cutlass.Uint8(0)
    cute.arch.sync_threads()
    for i in cutlass.range(lane_idx, sm120.MXF4NVF4_AB_TMA_BYTES, 32):
        major = i // (sm120.MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
        payload_chunk = i // 8
        payload_byte_in_chunk = i % 8
        physical_chunk = payload_chunk ^ ((payload_chunk >> 3) & 0x7)
        physical_idx = (
            sm120.MXF4NVF4_AB_SMEM_BYTES
            + physical_chunk * 16
            + payload_byte_in_chunk
        )
        sA_phys[physical_idx] = cutlass.Uint8(0x22)

        def set_b() -> None:
            sB_phys[physical_idx] = cutlass.Uint8(0x22)

        cutlass.if_generate(major < 4, set_b)
    cute.arch.sync_threads()
    sSFA_f8 = cute.recast_tensor(sSFA, cutlass.Float8E4M3FN)
    sSFB_f8 = cute.recast_tensor(sSFB, cutlass.Float8E4M3FN)
    for i in cutlass.range(lane_idx, sm120.MXF4NVF4_SCALE_TMA_BYTES, 32):
        sSFA_f8[i] = cutlass.Float8E4M3FN(1.0)
        sSFB_f8[i] = cutlass.Float8E4M3FN(1.0)
    sm120.stage_mxf4nvf4_ab_tma_physical_to_consumer_smem(
        sA_tma[(None, None, 1)],
        sB_tma[(None, None, 1)],
        sA_consumer,
        sB_consumer,
        consumer_stage_idx=1,
        lane_idx=lane_idx,
    )
    cute.arch.sync_threads()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    a, b = sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem(
        tiled_mma, sA_consumer, sB_consumer, lane_idx=lane_idx
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem(
            tiled_mma,
            sA_consumer,
            sB_consumer,
            a,
            b,
            lane_idx,
            k_block_idx,
            consumer_stage_idx=1,
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
            sSFA, sSFB, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(
            tiled_mma,
            acc,
            (a[(None, 0, k_block_idx)], sfa),
            (b[(None, 0, k_block_idx)], sfb),
            acc,
        )
    if tidx < 32:
        for i in cutlass.range(cute.size(acc), unroll_full=True):
            out[lane_idx * cute.size(acc) + i] = acc[i]


@cute.jit
def _launch_stage1_lane_idx(out: cute.Tensor):
    _stage1_lane_idx_kernel(out).launch(
        grid=[1, 1, 1], block=[32, 1, 1], smem=100352
    )


@cute.jit
def _launch_multi_warp_lane_idx_compile(out: cute.Tensor):
    _stage1_lane_idx_kernel(out).launch(
        grid=[1, 1, 1], block=[288, 1, 1], smem=100352
    )


def test_sm120_mxf4nvf4_stage1_lane_idx_runtime():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.full((32 * 4,), -1.0, device="cuda", dtype=torch.float32)
    cute_out = from_dlpack(out, enable_tvm_ffi=True)
    compiled = cute.compile(
        _launch_stage1_lane_idx,
        cute_out,
        options="--enable-tvm-ffi --keep-ptx",
    )
    assert "ldmatrix.sync.aligned.m8n8.x4.shared.b16" in compiled.__ptx__
    compiled(cute_out)
    torch.cuda.synchronize()
    expected = _expected_raw_accumulator(torch, "b_varies_by_logical_n")
    assert torch.equal(out, expected), out.reshape(32, 4).cpu()


@cute.kernel
def _multi_warp_lane_idx_runtime_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    lane_idx = tidx % 32
    smem = cutlass.utils.SmemAllocator()
    sA_tma, _, sB_tma, _ = sm120.make_mxf4nvf4_ab_smem_views(smem, num_stages=2)
    sA_consumer, sB_consumer = sm120.make_mxf4nvf4_ab_consumer_smem_views(
        smem, num_stages=2
    )
    sA_phys = cute.make_tensor(
        sA_tma.iterator, cute.make_layout(2 * sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sB_phys = cute.make_tensor(
        sB_tma.iterator, cute.make_layout(2 * sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sSFA = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    sSFB = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    if tidx < 32:
        for i in cutlass.range(lane_idx, sm120.MXF4NVF4_AB_SMEM_BYTES, 32):
            stage1_i = sm120.MXF4NVF4_AB_SMEM_BYTES + i
            sA_phys[stage1_i] = cutlass.Uint8(0)
            sB_phys[stage1_i] = cutlass.Uint8(0)
        for i in cutlass.range(lane_idx, sm120.MXF4NVF4_AB_TMA_BYTES, 32):
            major = i // (sm120.MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
            payload_chunk = i // 8
            payload_byte_in_chunk = i % 8
            physical_chunk = payload_chunk ^ ((payload_chunk >> 3) & 0x7)
            physical_idx = (
                sm120.MXF4NVF4_AB_SMEM_BYTES
                + physical_chunk * 16
                + payload_byte_in_chunk
            )
            local_m_major = major % sm120.MXF4NVF4_MMA_SHAPE_MNK[0]
            local_m_atom = major // sm120.MXF4NVF4_MMA_SHAPE_MNK[0]

            def set_a() -> None:
                sA_phys[physical_idx] = cutlass.Uint8(0x22)

            def set_a_even_atom() -> None:
                cutlass.if_generate(local_m_major < 8, set_a)

            def set_a_odd_atom() -> None:
                cutlass.if_generate(local_m_major >= 8, set_a)

            cutlass.if_generate(local_m_atom % 2 == 0, set_a_even_atom)
            cutlass.if_generate(local_m_atom % 2 != 0, set_a_odd_atom)

            local_n_major = major % sm120.MXF4NVF4_MMA_SHAPE_MNK[1]

            def set_b() -> None:
                sB_phys[physical_idx] = cutlass.Uint8(0x22)

            cutlass.if_generate(local_n_major < 4, set_b)
        sSFA_f8 = cute.recast_tensor(sSFA, cutlass.Float8E4M3FN)
        sSFB_f8 = cute.recast_tensor(sSFB, cutlass.Float8E4M3FN)
        for i in cutlass.range(lane_idx, sm120.MXF4NVF4_SCALE_TMA_BYTES, 32):
            sSFA_f8[i] = cutlass.Float8E4M3FN(1.0)
            sSFB_f8[i] = cutlass.Float8E4M3FN(1.0)
        sm120.stage_mxf4nvf4_ab_tma_physical_to_consumer_smem(
            sA_tma[(None, None, 1)],
            sB_tma[(None, None, 1)],
            sA_consumer,
            sB_consumer,
            consumer_stage_idx=1,
            lane_idx=lane_idx,
        )
    cute.arch.sync_threads()

    def run_consumer(
        lane_idx_arg: cutlass.Int32,
        sA_consumer_arg: cute.Tensor,
        sB_consumer_arg: cute.Tensor,
        sSFA_arg: cute.Tensor,
        sSFB_arg: cute.Tensor,
        out_arg: cute.Tensor,
        m_atom: cutlass.Constexpr[int],
        n_atom: cutlass.Constexpr[int],
        out_warp: cutlass.Constexpr[int],
    ) -> None:
        tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
        a, b = sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem(
            tiled_mma,
            sA_consumer_arg,
            sB_consumer_arg,
            lane_idx=lane_idx_arg,
            m_atom=m_atom,
            n_atom=n_atom,
        )
        acc = cute.make_rmem_tensor(
            tiled_mma.partition_shape_C((16, 8)), cutlass.Float32
        )
        sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
        acc.fill(0.0)
        for k_block_idx in cutlass.range_constexpr(2):
            sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem(
                tiled_mma,
                sA_consumer_arg,
                sB_consumer_arg,
                a,
                b,
                lane_idx_arg,
                k_block_idx,
                consumer_stage_idx=1,
                m_atom=m_atom,
                n_atom=n_atom,
            )
            sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
                sSFA_arg, sSFB_arg, k_block_idx
            )
            sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
            sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
            cute.gemm(
                tiled_mma,
                acc,
                (a[(None, 0, k_block_idx)], sfa),
                (b[(None, 0, k_block_idx)], sfb),
                acc,
            )
        for i in cutlass.range(cute.size(acc), unroll_full=True):
            out_arg[
                out_warp * 32 * cute.size(acc) + lane_idx_arg * cute.size(acc) + i
            ] = acc[i]

    if tidx >= 32:
        if tidx < 64:
            run_consumer(lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, 0, 0, 0)
    if tidx >= 64:
        if tidx < 96:
            run_consumer(lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, 1, 1, 1)
    if tidx >= 96:
        if tidx < 128:
            run_consumer(lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, 2, 2, 2)
    if tidx >= 128:
        if tidx < 160:
            run_consumer(lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, 3, 3, 3)
    if tidx >= 160:
        if tidx < 192:
            run_consumer(lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, 4, 4, 4)
    if tidx >= 192:
        if tidx < 224:
            run_consumer(lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, 5, 5, 5)
    if tidx >= 224:
        if tidx < 256:
            run_consumer(lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, 6, 6, 6)
    if tidx >= 256:
        run_consumer(lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, 7, 7, 7)


@cute.kernel
def _multi_warp_microtile_one_hot_kernel(
    out: cute.Tensor,
    probe_axis: cutlass.Constexpr[int],
    n_base: cutlass.Constexpr[int],
):
    bidx, _, _ = cute.arch.block_idx()
    tidx, _, _ = cute.arch.thread_idx()
    lane_idx = tidx % 32
    smem = cutlass.utils.SmemAllocator()
    sA_tma, _, sB_tma, _ = sm120.make_mxf4nvf4_ab_smem_views(smem, num_stages=2)
    sA_consumer, sB_consumer = sm120.make_mxf4nvf4_ab_consumer_smem_views(
        smem, num_stages=2
    )
    sA_phys = cute.make_tensor(
        sA_tma.iterator, cute.make_layout(2 * sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sB_phys = cute.make_tensor(
        sB_tma.iterator, cute.make_layout(2 * sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sSFA = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    sSFB = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    if tidx < 32:
        for i in cutlass.range(lane_idx, sm120.MXF4NVF4_AB_SMEM_BYTES, 32):
            stage1_i = sm120.MXF4NVF4_AB_SMEM_BYTES + i
            sA_phys[stage1_i] = cutlass.Uint8(0)
            sB_phys[stage1_i] = cutlass.Uint8(0)
        for i in cutlass.range(lane_idx, sm120.MXF4NVF4_AB_TMA_BYTES, 32):
            major = i // (sm120.MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
            payload_chunk = i // 8
            payload_byte_in_chunk = i % 8
            physical_chunk = payload_chunk ^ ((payload_chunk >> 3) & 0x7)
            physical_idx = (
                sm120.MXF4NVF4_AB_SMEM_BYTES
                + physical_chunk * 16
                + payload_byte_in_chunk
            )
            local_m_atom = major // sm120.MXF4NVF4_MMA_SHAPE_MNK[0]
            local_n_atom = major // sm120.MXF4NVF4_MMA_SHAPE_MNK[1]

            def set_a() -> None:
                sA_phys[physical_idx] = cutlass.Uint8(0x22)

            def set_b() -> None:
                sB_phys[physical_idx] = cutlass.Uint8(0x22)

            if cutlass.const_expr(probe_axis == 0):
                cutlass.if_generate(local_m_atom == bidx, set_a)
                set_b()
            else:
                set_a()
                cutlass.if_generate(local_n_atom == bidx, set_b)
        sSFA_f8 = cute.recast_tensor(sSFA, cutlass.Float8E4M3FN)
        sSFB_f8 = cute.recast_tensor(sSFB, cutlass.Float8E4M3FN)
        for i in cutlass.range(lane_idx, sm120.MXF4NVF4_SCALE_TMA_BYTES, 32):
            sSFA_f8[i] = cutlass.Float8E4M3FN(1.0)
            sSFB_f8[i] = cutlass.Float8E4M3FN(1.0)
        sm120.stage_mxf4nvf4_ab_tma_physical_to_consumer_smem(
            sA_tma[(None, None, 1)],
            sB_tma[(None, None, 1)],
            sA_consumer,
            sB_consumer,
            consumer_stage_idx=1,
            lane_idx=lane_idx,
        )
    cute.arch.sync_threads()

    def run_consumer(
        lane_idx_arg: cutlass.Int32,
        sA_consumer_arg: cute.Tensor,
        sB_consumer_arg: cute.Tensor,
        sSFA_arg: cute.Tensor,
        sSFB_arg: cute.Tensor,
        out_arg: cute.Tensor,
        block_idx_arg: cutlass.Int32,
        m_atom: cutlass.Constexpr[int],
        n_atom: cutlass.Constexpr[int],
        out_warp: cutlass.Constexpr[int],
    ) -> None:
        tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
        a, b = sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem(
            tiled_mma,
            sA_consumer_arg,
            sB_consumer_arg,
            lane_idx=lane_idx_arg,
            m_atom=m_atom,
            n_atom=n_atom,
        )
        acc = cute.make_rmem_tensor(
            tiled_mma.partition_shape_C((16, 8)), cutlass.Float32
        )
        sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
        acc.fill(0.0)
        for k_block_idx in cutlass.range_constexpr(2):
            sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem(
                tiled_mma,
                sA_consumer_arg,
                sB_consumer_arg,
                a,
                b,
                lane_idx_arg,
                k_block_idx,
                consumer_stage_idx=1,
                m_atom=m_atom,
                n_atom=n_atom,
            )
            sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
                sSFA_arg, sSFB_arg, k_block_idx
            )
            sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
            sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
            cute.gemm(
                tiled_mma,
                acc,
                (a[(None, 0, k_block_idx)], sfa),
                (b[(None, 0, k_block_idx)], sfb),
                acc,
            )
        for i in cutlass.range(cute.size(acc), unroll_full=True):
            out_arg[
                (block_idx_arg * 8 + out_warp) * 32 * cute.size(acc)
                + lane_idx_arg * cute.size(acc)
                + i
            ] = acc[i]

    if tidx >= 32:
        if tidx < 64:
            if cutlass.const_expr(probe_axis == 0):
                run_consumer(
                    lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, bidx, 0, 0, 0
                )
            else:
                run_consumer(
                    lane_idx,
                    sA_consumer,
                    sB_consumer,
                    sSFA,
                    sSFB,
                    out,
                    bidx,
                    0,
                    n_base + 0,
                    0,
                )
    if tidx >= 64:
        if tidx < 96:
            if cutlass.const_expr(probe_axis == 0):
                run_consumer(
                    lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, bidx, 1, 0, 1
                )
            else:
                run_consumer(
                    lane_idx,
                    sA_consumer,
                    sB_consumer,
                    sSFA,
                    sSFB,
                    out,
                    bidx,
                    0,
                    n_base + 1,
                    1,
                )
    if tidx >= 96:
        if tidx < 128:
            if cutlass.const_expr(probe_axis == 0):
                run_consumer(
                    lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, bidx, 2, 0, 2
                )
            else:
                run_consumer(
                    lane_idx,
                    sA_consumer,
                    sB_consumer,
                    sSFA,
                    sSFB,
                    out,
                    bidx,
                    0,
                    n_base + 2,
                    2,
                )
    if tidx >= 128:
        if tidx < 160:
            if cutlass.const_expr(probe_axis == 0):
                run_consumer(
                    lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, bidx, 3, 0, 3
                )
            else:
                run_consumer(
                    lane_idx,
                    sA_consumer,
                    sB_consumer,
                    sSFA,
                    sSFB,
                    out,
                    bidx,
                    0,
                    n_base + 3,
                    3,
                )
    if tidx >= 160:
        if tidx < 192:
            if cutlass.const_expr(probe_axis == 0):
                run_consumer(
                    lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, bidx, 4, 0, 4
                )
            else:
                run_consumer(
                    lane_idx,
                    sA_consumer,
                    sB_consumer,
                    sSFA,
                    sSFB,
                    out,
                    bidx,
                    0,
                    n_base + 4,
                    4,
                )
    if tidx >= 192:
        if tidx < 224:
            if cutlass.const_expr(probe_axis == 0):
                run_consumer(
                    lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, bidx, 5, 0, 5
                )
            else:
                run_consumer(
                    lane_idx,
                    sA_consumer,
                    sB_consumer,
                    sSFA,
                    sSFB,
                    out,
                    bidx,
                    0,
                    n_base + 5,
                    5,
                )
    if tidx >= 224:
        if tidx < 256:
            if cutlass.const_expr(probe_axis == 0):
                run_consumer(
                    lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, bidx, 6, 0, 6
                )
            else:
                run_consumer(
                    lane_idx,
                    sA_consumer,
                    sB_consumer,
                    sSFA,
                    sSFB,
                    out,
                    bidx,
                    0,
                    n_base + 6,
                    6,
                )
    if tidx >= 256:
        if cutlass.const_expr(probe_axis == 0):
            run_consumer(
                lane_idx, sA_consumer, sB_consumer, sSFA, sSFB, out, bidx, 7, 0, 7
            )
        else:
            run_consumer(
                lane_idx,
                sA_consumer,
                sB_consumer,
                sSFA,
                sSFB,
                out,
                bidx,
                0,
                n_base + 7,
                7,
            )


@cute.jit
def _launch_multi_warp_lane_idx_runtime(out: cute.Tensor):
    _multi_warp_lane_idx_runtime_kernel(out).launch(
        grid=[1, 1, 1], block=[288, 1, 1], smem=100352
    )


@cute.jit
def _launch_multi_warp_m_atom_one_hot_runtime(out: cute.Tensor):
    _multi_warp_microtile_one_hot_kernel(out, 0, 0).launch(
        grid=[8, 1, 1], block=[288, 1, 1], smem=100352
    )


@cute.jit
def _launch_multi_warp_n_atom_one_hot_runtime(
    out: cute.Tensor, n_base: cutlass.Constexpr[int]
):
    _multi_warp_microtile_one_hot_kernel(out, 1, n_base).launch(
        grid=[16, 1, 1], block=[288, 1, 1], smem=100352
    )


def test_sm120_mxf4nvf4_multi_warp_lane_idx_runtime():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.full((8 * 32 * 4,), -1.0, device="cuda", dtype=torch.float32)
    cute_out = from_dlpack(out, enable_tvm_ffi=True)
    compiled = cute.compile(
        _launch_multi_warp_lane_idx_runtime,
        cute_out,
        options="--enable-tvm-ffi --keep-ptx",
    )
    assert "ldmatrix.sync.aligned.m8n8.x4.shared.b16" in compiled.__ptx__
    compiled(cute_out)
    torch.cuda.synchronize()
    # Keep SFA/SFB fixed at 1.0 here. This canary is a cheap A/B-only stress
    # test for ignored m_atom, wrong lane index, wrong consumer stage, and local
    # M-half selection bugs. It is not injective over all m_atoms; the one-hot
    # tests below cover aliasing such as m_atom + 2.
    expected = _expected_multi_warp_m_atom_accumulator(torch)
    assert torch.equal(out, expected), out.reshape(8, 32, 4).cpu()


def test_sm120_mxf4nvf4_multi_warp_m_atom_one_hot_runtime():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.full((8 * 8 * 32 * 4,), -1.0, device="cuda", dtype=torch.float32)
    cute_out = from_dlpack(out, enable_tvm_ffi=True)
    compiled = cute.compile(
        _launch_multi_warp_m_atom_one_hot_runtime,
        cute_out,
        options="--enable-tvm-ffi --keep-ptx",
    )
    assert "ldmatrix.sync.aligned.m8n8.x4.shared.b16" in compiled.__ptx__
    compiled(cute_out)
    torch.cuda.synchronize()
    # This keeps scales fixed and makes each block select one logical M band.
    # Only the matching consumer warp may produce a nonzero MMA tile.
    expected = _expected_multi_warp_m_atom_one_hot_accumulator(torch)
    assert torch.equal(out, expected), out.reshape(8, 8, 32, 4).cpu()


@pytest.mark.parametrize("n_base", [0, 8])
def test_sm120_mxf4nvf4_multi_warp_n_atom_one_hot_runtime(n_base):
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.full((16 * 8 * 32 * 4,), -1.0, device="cuda", dtype=torch.float32)
    cute_out = from_dlpack(out, enable_tvm_ffi=True)
    compiled = cute.compile(
        _launch_multi_warp_n_atom_one_hot_runtime,
        cute_out,
        n_base,
        options="--enable-tvm-ffi --keep-ptx",
    )
    assert "ldmatrix.sync.aligned.m8n8.x4.shared.b16" in compiled.__ptx__
    compiled(cute_out)
    torch.cuda.synchronize()
    # This keeps scales fixed and makes each block select one logical N band.
    # n_base splits the 16 local N atoms across the eight consumer warps.
    expected = _expected_multi_warp_n_atom_one_hot_accumulator(torch, n_base)
    assert torch.equal(out, expected), out.reshape(16, 8, 32, 4).cpu()


def test_sm120_mxf4nvf4_stage1_lane_idx_compile():
    out = make_fake_compact_tensor(cutlass.Float32, (32 * 4,))
    compiled = cute.compile(
        _launch_stage1_lane_idx,
        out,
        options="--keep-ptx",
    )
    assert "ldmatrix.sync.aligned.m8n8.x4.shared.b16" in compiled.__ptx__


@cute.kernel
def _stage1_adapter_bytes_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    lane_idx = tidx % 32
    smem = cutlass.utils.SmemAllocator()
    sA_tma, _, sB_tma, _ = sm120.make_mxf4nvf4_ab_smem_views(smem, num_stages=2)
    sA_consumer, sB_consumer = sm120.make_mxf4nvf4_ab_consumer_smem_views(
        smem, num_stages=2
    )
    sA_phys = cute.make_tensor(
        sA_tma.iterator, cute.make_layout(2 * sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sB_phys = cute.make_tensor(
        sB_tma.iterator, cute.make_layout(2 * sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    for i in cutlass.range(lane_idx, sm120.MXF4NVF4_AB_SMEM_BYTES, 32):
        sA_phys[sm120.MXF4NVF4_AB_SMEM_BYTES + i] = cutlass.Uint8(0)
        sB_phys[sm120.MXF4NVF4_AB_SMEM_BYTES + i] = cutlass.Uint8(0)
    cute.arch.sync_threads()
    for i in cutlass.range(lane_idx, sm120.MXF4NVF4_AB_TMA_BYTES, 32):
        payload_chunk = i // 8
        payload_byte_in_chunk = i % 8
        physical_chunk = payload_chunk ^ ((payload_chunk >> 3) & 0x7)
        physical_idx = (
            sm120.MXF4NVF4_AB_SMEM_BYTES
            + physical_chunk * 16
            + payload_byte_in_chunk
        )
        sA_phys[physical_idx] = cutlass.Uint8(0x7B)
        sB_phys[physical_idx] = cutlass.Uint8(0x3C)
    cute.arch.sync_threads()
    sm120.stage_mxf4nvf4_ab_tma_physical_to_consumer_smem(
        sA_tma[(None, None, 1)],
        sB_tma[(None, None, 1)],
        sA_consumer,
        sB_consumer,
        consumer_stage_idx=1,
        lane_idx=lane_idx,
    )
    cute.arch.sync_threads()
    sA_u8 = cute.recast_tensor(sA_consumer, cutlass.Uint8)
    sB_u8 = cute.recast_tensor(sB_consumer, cutlass.Uint8)
    for i in cutlass.range(lane_idx, sm120.MXF4NVF4_AB_TMA_BYTES, 32):
        major = i // (sm120.MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
        k_byte = i % (sm120.MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
        out[i] = sA_u8[(major, k_byte, 1)]
        out[sm120.MXF4NVF4_AB_TMA_BYTES + i] = sB_u8[(major, k_byte, 1)]


@cute.jit
def _launch_stage1_adapter_bytes(out: cute.Tensor):
    _stage1_adapter_bytes_kernel(out).launch(
        grid=[1, 1, 1], block=[32, 1, 1], smem=98304
    )


def test_sm120_mxf4nvf4_stage1_adapter_bytes_runtime():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.empty((2 * sm120.MXF4NVF4_AB_TMA_BYTES,), device="cuda", dtype=torch.uint8)
    cute_out = from_dlpack(out, enable_tvm_ffi=True)
    compiled = cute.compile(
        _launch_stage1_adapter_bytes,
        cute_out,
        options="--enable-tvm-ffi",
    )
    compiled(cute_out)
    torch.cuda.synchronize()
    assert torch.all(out[: sm120.MXF4NVF4_AB_TMA_BYTES] == 0x7B)
    assert torch.all(out[sm120.MXF4NVF4_AB_TMA_BYTES :] == 0x3C)


def test_sm120_mxf4nvf4_multi_warp_lane_idx_compile():
    out = make_fake_compact_tensor(cutlass.Float32, (32 * 4,))
    compiled = cute.compile(
        _launch_multi_warp_lane_idx_compile,
        out,
        options="--keep-ptx",
    )
    assert "ldmatrix.sync.aligned.m8n8.x4.shared.b16" in compiled.__ptx__


@cute.kernel
def _no_external_desc_tma_kernel(
    tma_atom_a: cute.CopyAtom,
    tma_tensor_a: cute.Tensor,
    out: cute.Tensor,
):
    smem = cutlass.utils.SmemAllocator()
    sA_tma, _, _, _ = sm120.make_mxf4nvf4_ab_smem_views(smem)
    barriers = smem.allocate_array(cutlass.Int64, 2, byte_alignment=8)
    tAsA, tAgA = cpasync.tma_partition(
        tma_atom_a,
        0,
        cute.make_layout(1),
        cute.group_modes(sA_tma, 0, 2),
        cute.group_modes(tma_tensor_a, 0, 2),
    )
    pipe = cutlass.pipeline.PipelineTmaWarpMma.create(
        num_stages=1,
        producer_group=cutlass.pipeline.CooperativeGroup(cutlass.pipeline.Agent.Thread),
        consumer_group=cutlass.pipeline.CooperativeGroup(
            cutlass.pipeline.Agent.Thread, 1
        ),
        tx_count=sm120.mxf4nvf4_ab_tma_tx_bytes(),
        barrier_storage=barriers,
    )
    producer_state = cutlass.pipeline.make_pipeline_state(
        cutlass.pipeline.PipelineUserType.Producer, 1
    )
    pipe.producer_acquire(producer_state, pipe.producer_try_acquire(producer_state))
    cute.copy(
        tma_atom_a,
        tAgA[(None, 0)],
        tAsA[(None, 0)],
        tma_bar_ptr=pipe.producer_get_barrier(producer_state),
    )
    pipe.producer_commit(producer_state)
    out[0] = cutlass.Uint8(0)


@cute.jit
def _launch_no_external_desc_tma(gA: cute.Tensor, out: cute.Tensor):
    ab_smem_layout = sm120.make_mxf4nvf4_smem_layout_staged()
    tma_atom_a, tma_tensor_a = sm120.make_mxf4nvf4_tiled_tma_atom_a(
        gA, ab_smem_layout
    )
    _no_external_desc_tma_kernel(tma_atom_a, tma_tensor_a, out).launch(
        grid=[1, 1, 1], block=[32, 1, 1], smem=49152
    )


def test_sm120_mxf4nvf4_non_external_tma_does_not_emit_desc_fence():
    g_ab = make_fake_compact_tensor(
        cutlass.Uint8,
        (128, 128, 2),
        memspace=cute.AddressSpace.gmem,
        assumed_align=32,
    )
    out = make_fake_compact_tensor(
        cutlass.Uint8,
        (1,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )
    compiled = cute.compile(
        _launch_no_external_desc_tma,
        g_ab,
        out,
        options="--gpu-arch=sm_120a --enable-tvm-ffi --keep-ptx",
    )
    assert "cp.async.bulk.tensor.3d.shared::cta.global.tile" in compiled.__ptx__
    assert "fence.proxy.tensormap::generic.acquire.gpu" not in compiled.__ptx__


@cute.kernel
def _two_kblock_scale_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    smem = cutlass.utils.SmemAllocator()
    sSFA = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    sSFB = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    sSFA_f8 = cute.recast_tensor(sSFA, cutlass.Float8E4M3FN)
    sSFB_f8 = cute.recast_tensor(sSFB, cutlass.Float8E4M3FN)
    # The helper under test maps each K64 MMA substep to a different scale-K
    # byte range in staged SMEM. K0 uses bytes 0..3 and K1 uses bytes 4..7.
    for i in cutlass.range_constexpr(8):
        sSFA_f8[(0, i, 0, 0)] = cutlass.Float8E4M3FN(1.0 if i < 4 else 2.0)
        sSFB_f8[(0, i, 0, 0)] = cutlass.Float8E4M3FN(1.0)
    cute.arch.sync_threads()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
            sSFA, sSFB, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.jit
def _launch_two_kblock_scale(out: cute.Tensor):
    _two_kblock_scale_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])


def test_sm120_mxf4nvf4_two_kblock_scale_offsets_runtime():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    cute_out = from_dlpack(out, enable_tvm_ffi=True)

    compiled = cute.compile(_launch_two_kblock_scale, cute_out, options="--keep-ptx")
    assert (
        compiled.__ptx__.count(
            "mma.sync.aligned.m16n8k64.row.col.kind::mxf4nvf4.block_scale.scale_vec::4X"
        )
        == 2
    )
    compiled(cute_out)
    torch.cuda.synchronize()
    torch.testing.assert_close(out, torch.full_like(out, 192.0), rtol=0, atol=0)


@cute.kernel
def _scale_stage1_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    smem = cutlass.utils.SmemAllocator()
    sSFA = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(num_stages=2),
        byte_alignment=128,
    )
    sSFB = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(num_stages=2),
        byte_alignment=128,
    )
    sSFA_f8 = cute.recast_tensor(sSFA, cutlass.Float8E4M3FN)
    sSFB_f8 = cute.recast_tensor(sSFB, cutlass.Float8E4M3FN)
    for i in cutlass.range_constexpr(4):
        sSFA_f8[(0, i, 0, 1)] = cutlass.Float8E4M3FN(2.0)
        sSFB_f8[(0, i, 0, 1)] = cutlass.Float8E4M3FN(1.0)
    cute.arch.sync_threads()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
        sSFA, sSFB, 0, stage_idx=1
    )
    sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
    sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
    cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.jit
def _launch_scale_stage1(out: cute.Tensor):
    _scale_stage1_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])


def test_sm120_mxf4nvf4_scale_fragment_views_stage1_runtime():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    cute_out = from_dlpack(out, enable_tvm_ffi=True)

    cute.compile(_launch_scale_stage1, cute_out, options="--keep-ptx")(cute_out)
    torch.cuda.synchronize()
    torch.testing.assert_close(out, torch.full_like(out, 128.0), rtol=0, atol=0)


@cute.kernel
def _scale_tma_physical_bridge_kernel(
    desc_sfa: cute.Tensor,
    desc_sfb: cute.Tensor,
    out: cute.Tensor,
):
    tidx, _, _ = cute.arch.thread_idx()
    smem = cutlass.utils.SmemAllocator()
    sSFA_tma = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_scale_tma_physical_layout_staged(),
        byte_alignment=128,
    )
    sSFB_tma = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_scale_tma_physical_layout_staged(),
        byte_alignment=128,
    )
    sSFA_scratch_all, sSFB_scratch_all = sm120.allocate_mxf4nvf4_scale_fragment_scratch(
        smem
    )
    sSFA_scratch, sSFB_scratch = sm120.make_mxf4nvf4_scale_fragment_scratch_views(
        sSFA_scratch_all, sSFB_scratch_all, cutlass.Int32(0)
    )
    barriers = smem.allocate_array(cutlass.Int64, 2, byte_alignment=8)

    pipe = cutlass.pipeline.PipelineTmaWarpMma.create(
        num_stages=1,
        producer_group=cutlass.pipeline.CooperativeGroup(cutlass.pipeline.Agent.Thread),
        consumer_group=cutlass.pipeline.CooperativeGroup(
            cutlass.pipeline.Agent.Thread, 1
        ),
        tx_count=2 * sm120.mxf4nvf4_scale_tma_tx_bytes(),
        barrier_storage=barriers,
    )
    producer_state = cutlass.pipeline.make_pipeline_state(
        cutlass.pipeline.PipelineUserType.Producer, 1
    )
    pipe.producer_acquire(producer_state, pipe.producer_try_acquire(producer_state))
    desc_sfa_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_sfa)
    desc_sfb_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_sfb)
    with cute.arch.elect_one():
        cutlass.pipeline.issue_tma_load_4d(
            pipe,
            producer_state,
            sSFA_tma.iterator,
            desc_sfa_ptr,
            0,
            0,
            0,
            0,
            already_elected=True,
        )
        cutlass.pipeline.issue_tma_load_4d(
            pipe,
            producer_state,
            sSFB_tma.iterator,
            desc_sfb_ptr,
            0,
            0,
            0,
            0,
            already_elected=True,
        )
    pipe.producer_commit(producer_state)
    consumer_state = cutlass.pipeline.make_pipeline_state(
        cutlass.pipeline.PipelineUserType.Consumer, 1
    )
    pipe.consumer_wait(consumer_state, pipe.consumer_try_wait(consumer_state))
    cute.arch.sync_threads()

    sm120.stage_mxf4nvf4_scale_tma_physical_to_fragment_scratch(
        sSFA_tma,
        sSFB_tma,
        sSFA_scratch,
        sSFB_scratch,
        lane_idx=tidx,
    )
    cute.arch.sync_threads()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_fragment_views_from_scratch(
            sSFA_scratch, sSFB_scratch, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    pipe.consumer_release(consumer_state)
    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.jit
def _launch_scale_tma_physical_bridge(
    desc_sfa: cute.Tensor,
    desc_sfb: cute.Tensor,
    out: cute.Tensor,
):
    _scale_tma_physical_bridge_kernel(desc_sfa, desc_sfb, out).launch(
        grid=[1, 1, 1], block=[32, 1, 1], smem=49152
    )


def test_sm120_mxf4nvf4_scale_tma_physical_to_fragment_scratch_runtime():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    sfa_storage, sfa = _aligned_u8_tensor(torch, sm120.MXF4NVF4_SCALE_TMA_BYTES, 16)
    sfb_storage, sfb = _aligned_u8_tensor(torch, sm120.MXF4NVF4_SCALE_TMA_BYTES, 16)
    one = 0x38
    two = 0x40
    for scale_col in range(sm120.MXF4NVF4_SCALE_K):
        value = one if scale_col < 4 else two
        sfa[scale_col * 128 : (scale_col + 1) * 128].fill_(value)
        sfb[scale_col * 128 : (scale_col + 1) * 128].fill_(one)
    try:
        desc_sfa = cutlass.utils.make_sm120_mxf4nvf4_scale_tma_desc_bytes(
            sfa.data_ptr()
        )
        desc_sfb = cutlass.utils.make_sm120_mxf4nvf4_scale_tma_desc_bytes(
            sfb.data_ptr()
        )
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")

    _, desc_sfa_dev = _device_desc_from_bytes(torch, desc_sfa)
    _, desc_sfb_dev = _device_desc_from_bytes(torch, desc_sfb)
    out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    cute_desc_sfa = from_dlpack(desc_sfa_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_desc_sfb = from_dlpack(desc_sfb_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_out = from_dlpack(out, enable_tvm_ffi=True)
    compiled = cute.compile(
        _launch_scale_tma_physical_bridge,
        cute_desc_sfa,
        cute_desc_sfb,
        cute_out,
        options="--enable-tvm-ffi --keep-ptx",
    )
    assert "cp.async.bulk.tensor.4d.shared::cta.global" in compiled.__ptx__
    compiled(cute_desc_sfa, cute_desc_sfb, cute_out)
    torch.cuda.synchronize()
    torch.testing.assert_close(out, torch.full_like(out, 192.0), rtol=0, atol=0)
    assert sfa_storage is not None and sfb_storage is not None


@cute.kernel
def _smem_ldsm_ab_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    smem = cutlass.utils.SmemAllocator()
    sA_tma, _, sB_tma, _ = sm120.make_mxf4nvf4_ab_smem_views(smem)
    sA_consumer, sB_consumer = sm120.make_mxf4nvf4_ab_consumer_smem_views(smem)
    sA_phys = cute.make_tensor(
        sA_tma.iterator, cute.make_layout(sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sB_phys = cute.make_tensor(
        sB_tma.iterator, cute.make_layout(sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sSFA = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    sSFB = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    for i in cutlass.range(tidx, sm120.MXF4NVF4_AB_SMEM_BYTES, 32):
        sA_phys[i] = cutlass.Uint8(0x22)
        sB_phys[i] = cutlass.Uint8(0x22)
    sSFA_f8 = cute.recast_tensor(sSFA, cutlass.Float8E4M3FN)
    sSFB_f8 = cute.recast_tensor(sSFB, cutlass.Float8E4M3FN)
    for i in cutlass.range(tidx, sm120.MXF4NVF4_SCALE_TMA_BYTES, 32):
        sSFA_f8[i] = cutlass.Float8E4M3FN(1.0)
        sSFB_f8[i] = cutlass.Float8E4M3FN(1.0)
    cute.arch.sync_threads()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    sm120.stage_mxf4nvf4_ab_tma_physical_to_consumer_smem(
        sA_tma, sB_tma, sA_consumer, sB_consumer, lane_idx=tidx
    )
    cute.arch.sync_threads()
    a, b = sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem(
        tiled_mma, sA_consumer, sB_consumer, tidx
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem(
            tiled_mma,
            sA_consumer,
            sB_consumer,
            a,
            b,
            tidx,
            k_block_idx,
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
            sSFA, sSFB, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(
            tiled_mma,
            acc,
            (a[(None, 0, k_block_idx)], sfa),
            (b[(None, 0, k_block_idx)], sfb),
            acc,
        )
        cute.arch.sync_threads()

    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.jit
def _launch_smem_ldsm_ab(out: cute.Tensor):
    _smem_ldsm_ab_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1], smem=65536)


def test_sm120_mxf4nvf4_smem_ldsm_ab_runtime():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    cute_out = from_dlpack(out, enable_tvm_ffi=True)

    compiled = cute.compile(_launch_smem_ldsm_ab, cute_out, options="--keep-ptx")
    assert "ldmatrix.sync.aligned.m8n8.x4.shared.b16" in compiled.__ptx__
    compiled(cute_out)
    torch.cuda.synchronize()
    torch.testing.assert_close(out, torch.full_like(out, 128.0), rtol=0, atol=0)


def _aligned_u8_tensor(torch, num_bytes: int, alignment: int):
    storage = torch.empty(num_bytes + alignment - 1, device="cuda", dtype=torch.uint8)
    offset = (-storage.data_ptr()) % alignment
    view = storage[offset : offset + num_bytes]
    assert view.data_ptr() % alignment == 0
    return storage, view


def _device_desc_from_bytes(torch, desc_bytes: bytes):
    storage, desc = _aligned_u8_tensor(torch, sm120.MXF4NVF4_TMA_DESC_BYTES, 128)
    desc.copy_(torch.tensor(list(desc_bytes), device="cuda", dtype=torch.uint8))
    return storage, desc


def _patterned_u8(torch, count: int, xor_value: int):
    values = torch.arange(count, device="cuda", dtype=torch.int32)
    return torch.bitwise_xor(values, xor_value).to(torch.uint8)


def _logical_fp4_payload(torch, is_one):
    # The descriptor logical layout is (K, major, L). Each byte packs two
    # adjacent K values; nibble 0x2 is FP4 E2M1 one and 0x0 is zero.
    host = bytearray(sm120.MXF4NVF4_AB_TMA_BYTES)
    for major in range(sm120.MXF4NVF4_CTA_SHAPE_MNK[0]):
        major_base = major * (sm120.MXF4NVF4_CTA_SHAPE_MNK[2] // 2)
        for k_pair in range(sm120.MXF4NVF4_CTA_SHAPE_MNK[2] // 2):
            k0 = 2 * k_pair
            lo = 0x2 if is_one(major, k0) else 0x0
            hi = 0x2 if is_one(major, k0 + 1) else 0x0
            host[major_base + k_pair] = lo | (hi << 4)
    return torch.tensor(list(host), device="cuda", dtype=torch.uint8)


def _expected_rank3_fp4_tma_physical(torch, src):
    # The end-to-end canary compares descriptor TMA against a physical-SMEM
    # reference so that lane offsets and K64 LDSM substep addresses are tested.
    expected = torch.full(
        (sm120.MXF4NVF4_AB_SMEM_BYTES,), 0xCD, device="cuda", dtype=torch.uint8
    )
    for dst_payload_chunk in range(src.numel() // 8):
        dst_base = dst_payload_chunk * 16
        src_swizzle_chunk = dst_payload_chunk ^ ((dst_payload_chunk >> 3) & 0x7)
        src_base = src_swizzle_chunk * 8
        expected[dst_base : dst_base + 8] = src[src_base : src_base + 8]
    return expected


@cute.kernel
def _mma_from_physical_smem_kernel(
    phys_a: cute.Tensor,
    phys_b: cute.Tensor,
    out: cute.Tensor,
):
    tidx, _, _ = cute.arch.thread_idx()
    smem = cutlass.utils.SmemAllocator()
    sA_tma, _, sB_tma, _ = sm120.make_mxf4nvf4_ab_smem_views(smem)
    sA_consumer, sB_consumer = sm120.make_mxf4nvf4_ab_consumer_smem_views(smem)
    sA_phys = cute.make_tensor(
        sA_tma.iterator, cute.make_layout(sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sB_phys = cute.make_tensor(
        sB_tma.iterator, cute.make_layout(sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sSFA = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    sSFB = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    for i in cutlass.range(tidx, sm120.MXF4NVF4_AB_SMEM_BYTES, 32):
        sA_phys[i] = phys_a[i]
        sB_phys[i] = phys_b[i]
    sSFA_f8 = cute.recast_tensor(sSFA, cutlass.Float8E4M3FN)
    sSFB_f8 = cute.recast_tensor(sSFB, cutlass.Float8E4M3FN)
    for i in cutlass.range(tidx, sm120.MXF4NVF4_SCALE_TMA_BYTES, 32):
        sSFA_f8[i] = cutlass.Float8E4M3FN(1.0)
        sSFB_f8[i] = cutlass.Float8E4M3FN(1.0)
    cute.arch.sync_threads()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    sm120.stage_mxf4nvf4_ab_tma_physical_to_consumer_smem(
        sA_tma, sB_tma, sA_consumer, sB_consumer, lane_idx=tidx
    )
    cute.arch.sync_threads()
    a, b = sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem(
        tiled_mma, sA_consumer, sB_consumer, tidx
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem(
            tiled_mma,
            sA_consumer,
            sB_consumer,
            a,
            b,
            tidx,
            k_block_idx,
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
            sSFA, sSFB, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(
            tiled_mma,
            acc,
            (a[(None, 0, k_block_idx)], sfa),
            (b[(None, 0, k_block_idx)], sfb),
            acc,
        )
        cute.arch.sync_threads()

    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.jit
def _launch_mma_from_physical_smem(
    phys_a: cute.Tensor,
    phys_b: cute.Tensor,
    out: cute.Tensor,
):
    _mma_from_physical_smem_kernel(phys_a, phys_b, out).launch(
        grid=[1, 1, 1], block=[32, 1, 1], smem=65536
    )


@cute.kernel
def _external_tma_mma_kernel(
    desc_a: cute.Tensor,
    desc_b: cute.Tensor,
    out: cute.Tensor,
):
    tidx, _, _ = cute.arch.thread_idx()
    smem = cutlass.utils.SmemAllocator()
    sA_tma, _, sB_tma, _ = sm120.make_mxf4nvf4_ab_smem_views(smem)
    sA_consumer, sB_consumer = sm120.make_mxf4nvf4_ab_consumer_smem_views(smem)
    sA_phys = cute.make_tensor(
        sA_tma.iterator, cute.make_layout(sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sB_phys = cute.make_tensor(
        sB_tma.iterator, cute.make_layout(sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sSFA = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    sSFB = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    barriers = smem.allocate_array(cutlass.Int64, 2, byte_alignment=8)
    for i in cutlass.range(tidx, sm120.MXF4NVF4_AB_SMEM_BYTES, 32):
        sA_phys[i] = cutlass.Uint8(0xCD)
        sB_phys[i] = cutlass.Uint8(0xCD)
    sSFA_f8 = cute.recast_tensor(sSFA, cutlass.Float8E4M3FN)
    sSFB_f8 = cute.recast_tensor(sSFB, cutlass.Float8E4M3FN)
    for i in cutlass.range(tidx, sm120.MXF4NVF4_SCALE_TMA_BYTES, 32):
        sSFA_f8[i] = cutlass.Float8E4M3FN(1.0)
        sSFB_f8[i] = cutlass.Float8E4M3FN(1.0)
    cute.arch.sync_threads()

    pipe = cutlass.pipeline.PipelineTmaWarpMma.create(
        num_stages=1,
        producer_group=cutlass.pipeline.CooperativeGroup(cutlass.pipeline.Agent.Thread),
        consumer_group=cutlass.pipeline.CooperativeGroup(
            cutlass.pipeline.Agent.Thread, 1
        ),
        tx_count=2 * sm120.mxf4nvf4_ab_tma_tx_bytes(),
        barrier_storage=barriers,
    )
    producer_state = cutlass.pipeline.make_pipeline_state(
        cutlass.pipeline.PipelineUserType.Producer, 1
    )
    pipe.producer_acquire(producer_state, pipe.producer_try_acquire(producer_state))
    desc_a_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_a)
    desc_b_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_b)
    with cute.arch.elect_one():
        cutlass.pipeline.issue_tma_load_3d(
            pipe,
            producer_state,
            sA_tma.iterator,
            desc_a_ptr,
            0,
            0,
            0,
            already_elected=True,
        )
        cutlass.pipeline.issue_tma_load_3d(
            pipe,
            producer_state,
            sB_tma.iterator,
            desc_b_ptr,
            0,
            0,
            0,
            already_elected=True,
        )
    pipe.producer_commit(producer_state)
    consumer_state = cutlass.pipeline.make_pipeline_state(
        cutlass.pipeline.PipelineUserType.Consumer, 1
    )
    pipe.consumer_wait(consumer_state, pipe.consumer_try_wait(consumer_state))
    cute.arch.sync_threads()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    sm120.stage_mxf4nvf4_ab_tma_physical_to_consumer_smem(
        sA_tma, sB_tma, sA_consumer, sB_consumer, lane_idx=tidx
    )
    cute.arch.sync_threads()
    a, b = sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem(
        tiled_mma, sA_consumer, sB_consumer, tidx
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem(
            tiled_mma,
            sA_consumer,
            sB_consumer,
            a,
            b,
            tidx,
            k_block_idx,
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
            sSFA, sSFB, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(
            tiled_mma,
            acc,
            (a[(None, 0, k_block_idx)], sfa),
            (b[(None, 0, k_block_idx)], sfb),
            acc,
        )
        cute.arch.sync_threads()

    pipe.consumer_release(consumer_state)
    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.jit
def _launch_external_tma_mma(
    desc_a: cute.Tensor,
    desc_b: cute.Tensor,
    out: cute.Tensor,
):
    _external_tma_mma_kernel(
        desc_a,
        desc_b,
        out,
    ).launch(grid=[1, 1, 1], block=[32, 1, 1], smem=65536)


@cute.kernel
def _atom_external_tma_mma_kernel(
    tma_atom_a: cute.CopyAtom,
    tma_tensor_a: cute.Tensor,
    tma_atom_b: cute.CopyAtom,
    tma_tensor_b: cute.Tensor,
    desc_a: cute.Tensor,
    desc_b: cute.Tensor,
    out: cute.Tensor,
):
    tidx, _, _ = cute.arch.thread_idx()
    smem = cutlass.utils.SmemAllocator()
    sA_tma, _, sB_tma, _ = sm120.make_mxf4nvf4_ab_smem_views(smem)
    sA_consumer, sB_consumer = sm120.make_mxf4nvf4_ab_consumer_smem_views(smem)
    sA_phys = cute.make_tensor(
        sA_tma.iterator, cute.make_layout(sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sB_phys = cute.make_tensor(
        sB_tma.iterator, cute.make_layout(sm120.MXF4NVF4_AB_SMEM_BYTES)
    )
    sSFA = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    sSFB = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_tma_scale_layout_staged(),
        byte_alignment=128,
    )
    barriers = smem.allocate_array(cutlass.Int64, 2, byte_alignment=8)
    tAsA, tAgA = cpasync.tma_partition(
        tma_atom_a,
        0,
        cute.make_layout(1),
        cute.group_modes(sA_tma, 0, 2),
        cute.group_modes(tma_tensor_a, 0, 2),
    )
    tBsB, tBgB = cpasync.tma_partition(
        tma_atom_b,
        0,
        cute.make_layout(1),
        cute.group_modes(sB_tma, 0, 2),
        cute.group_modes(tma_tensor_b, 0, 2),
    )
    for i in cutlass.range(tidx, sm120.MXF4NVF4_AB_SMEM_BYTES, 32):
        sA_phys[i] = cutlass.Uint8(0xCD)
        sB_phys[i] = cutlass.Uint8(0xCD)
    sSFA_f8 = cute.recast_tensor(sSFA, cutlass.Float8E4M3FN)
    sSFB_f8 = cute.recast_tensor(sSFB, cutlass.Float8E4M3FN)
    for i in cutlass.range(tidx, sm120.MXF4NVF4_SCALE_TMA_BYTES, 32):
        sSFA_f8[i] = cutlass.Float8E4M3FN(1.0)
        sSFB_f8[i] = cutlass.Float8E4M3FN(1.0)
    cute.arch.sync_threads()

    pipe = cutlass.pipeline.PipelineTmaWarpMma.create(
        num_stages=1,
        producer_group=cutlass.pipeline.CooperativeGroup(cutlass.pipeline.Agent.Thread),
        consumer_group=cutlass.pipeline.CooperativeGroup(
            cutlass.pipeline.Agent.Thread, 1
        ),
        tx_count=2 * sm120.mxf4nvf4_ab_tma_tx_bytes(),
        barrier_storage=barriers,
    )
    producer_state = cutlass.pipeline.make_pipeline_state(
        cutlass.pipeline.PipelineUserType.Producer, 1
    )
    desc_a_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_a)
    desc_b_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_b)
    pipe.producer_acquire(producer_state, pipe.producer_try_acquire(producer_state))
    bar = pipe.producer_get_barrier(producer_state)
    cute.copy(
        tma_atom_a,
        tAgA[(None, 0)],
        tAsA[(None, 0)],
        tma_bar_ptr=bar,
        tma_desc_ptr=desc_a_ptr,
    )
    cute.copy(
        tma_atom_b,
        tBgB[(None, 0)],
        tBsB[(None, 0)],
        tma_bar_ptr=bar,
        tma_desc_ptr=desc_b_ptr,
    )
    pipe.producer_commit(producer_state)
    consumer_state = cutlass.pipeline.make_pipeline_state(
        cutlass.pipeline.PipelineUserType.Consumer, 1
    )
    pipe.consumer_wait(consumer_state, pipe.consumer_try_wait(consumer_state))
    cute.arch.sync_threads()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    sm120.stage_mxf4nvf4_ab_tma_physical_to_consumer_smem(
        sA_tma, sB_tma, sA_consumer, sB_consumer, lane_idx=tidx
    )
    cute.arch.sync_threads()
    a, b = sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem(
        tiled_mma, sA_consumer, sB_consumer, tidx
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem(
            tiled_mma,
            sA_consumer,
            sB_consumer,
            a,
            b,
            tidx,
            k_block_idx,
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
            sSFA, sSFB, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(
            tiled_mma,
            acc,
            (a[(None, 0, k_block_idx)], sfa),
            (b[(None, 0, k_block_idx)], sfb),
            acc,
        )
        cute.arch.sync_threads()

    pipe.consumer_release(consumer_state)
    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.jit
def _launch_atom_external_tma_mma(
    desc_a: cute.Tensor,
    desc_b: cute.Tensor,
    gA: cute.Tensor,
    gB: cute.Tensor,
    out: cute.Tensor,
):
    ab_smem_layout = sm120.make_mxf4nvf4_ab_tma_physical_layout_staged()
    tma_atom_a, tma_tensor_a = sm120.make_mxf4nvf4_tiled_tma_atom_a(
        gA, ab_smem_layout
    )
    tma_atom_b, tma_tensor_b = sm120.make_mxf4nvf4_tiled_tma_atom_b(
        gB, ab_smem_layout
    )
    _atom_external_tma_mma_kernel(
        tma_atom_a,
        tma_tensor_a,
        tma_atom_b,
        tma_tensor_b,
        desc_a,
        desc_b,
        out,
    ).launch(grid=[1, 1, 1], block=[32, 1, 1], smem=65536)


@cute.kernel
def _atom_external_tma_mma_with_scale_bridge_kernel(
    tma_atom_a: cute.CopyAtom,
    tma_tensor_a: cute.Tensor,
    tma_atom_b: cute.CopyAtom,
    tma_tensor_b: cute.Tensor,
    desc_a: cute.Tensor,
    desc_b: cute.Tensor,
    desc_sfa: cute.Tensor,
    desc_sfb: cute.Tensor,
    out: cute.Tensor,
):
    tidx, _, _ = cute.arch.thread_idx()
    smem = cutlass.utils.SmemAllocator()
    sA_tma, _, sB_tma, _ = sm120.make_mxf4nvf4_ab_smem_views(smem)
    sA_consumer, sB_consumer = sm120.make_mxf4nvf4_ab_consumer_smem_views(smem)
    sSFA_tma = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_scale_tma_physical_layout_staged(),
        byte_alignment=128,
    )
    sSFB_tma = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_scale_tma_physical_layout_staged(),
        byte_alignment=128,
    )
    sSFA_scratch_all, sSFB_scratch_all = sm120.allocate_mxf4nvf4_scale_fragment_scratch(
        smem
    )
    sSFA_scratch, sSFB_scratch = sm120.make_mxf4nvf4_scale_fragment_scratch_views(
        sSFA_scratch_all, sSFB_scratch_all, cutlass.Int32(0)
    )
    barriers = smem.allocate_array(cutlass.Int64, 2, byte_alignment=8)
    tAsA, tAgA = cpasync.tma_partition(
        tma_atom_a,
        0,
        cute.make_layout(1),
        cute.group_modes(sA_tma, 0, 2),
        cute.group_modes(tma_tensor_a, 0, 2),
    )
    tBsB, tBgB = cpasync.tma_partition(
        tma_atom_b,
        0,
        cute.make_layout(1),
        cute.group_modes(sB_tma, 0, 2),
        cute.group_modes(tma_tensor_b, 0, 2),
    )
    pipe = cutlass.pipeline.PipelineTmaWarpMma.create(
        num_stages=1,
        producer_group=cutlass.pipeline.CooperativeGroup(cutlass.pipeline.Agent.Thread),
        consumer_group=cutlass.pipeline.CooperativeGroup(
            cutlass.pipeline.Agent.Thread, 1
        ),
        tx_count=2 * sm120.mxf4nvf4_ab_tma_tx_bytes()
        + 2 * sm120.mxf4nvf4_scale_tma_tx_bytes(),
        barrier_storage=barriers,
    )
    producer_state = cutlass.pipeline.make_pipeline_state(
        cutlass.pipeline.PipelineUserType.Producer, 1
    )
    desc_a_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_a)
    desc_b_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_b)
    desc_sfa_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_sfa)
    desc_sfb_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_sfb)
    pipe.producer_acquire(producer_state, pipe.producer_try_acquire(producer_state))
    bar = pipe.producer_get_barrier(producer_state)
    cute.copy(
        tma_atom_a,
        tAgA[(None, 0)],
        tAsA[(None, 0)],
        tma_bar_ptr=bar,
        tma_desc_ptr=desc_a_ptr,
    )
    cute.copy(
        tma_atom_b,
        tBgB[(None, 0)],
        tBsB[(None, 0)],
        tma_bar_ptr=bar,
        tma_desc_ptr=desc_b_ptr,
    )
    with cute.arch.elect_one():
        cutlass.pipeline.issue_tma_load_4d(
            pipe,
            producer_state,
            sSFA_tma.iterator,
            desc_sfa_ptr,
            0,
            0,
            0,
            0,
            already_elected=True,
        )
        cutlass.pipeline.issue_tma_load_4d(
            pipe,
            producer_state,
            sSFB_tma.iterator,
            desc_sfb_ptr,
            0,
            0,
            0,
            0,
            already_elected=True,
        )
    pipe.producer_commit(producer_state)
    consumer_state = cutlass.pipeline.make_pipeline_state(
        cutlass.pipeline.PipelineUserType.Consumer, 1
    )
    pipe.consumer_wait(consumer_state, pipe.consumer_try_wait(consumer_state))
    cute.arch.sync_threads()

    sm120.stage_mxf4nvf4_ab_tma_physical_to_consumer_smem(
        sA_tma, sB_tma, sA_consumer, sB_consumer, lane_idx=tidx
    )
    sm120.stage_mxf4nvf4_scale_tma_physical_to_fragment_scratch(
        sSFA_tma,
        sSFB_tma,
        sSFA_scratch,
        sSFB_scratch,
        lane_idx=tidx,
    )
    cute.arch.sync_threads()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    a, b = sm120.make_mxf4nvf4_ab_fragments_from_consumer_smem(
        tiled_mma, sA_consumer, sB_consumer, tidx
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sm120.load_mxf4nvf4_ab_fragments_from_consumer_smem(
            tiled_mma,
            sA_consumer,
            sB_consumer,
            a,
            b,
            tidx,
            k_block_idx,
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_fragment_views_from_scratch(
            sSFA_scratch, sSFB_scratch, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(
            tiled_mma,
            acc,
            (a[(None, 0, k_block_idx)], sfa),
            (b[(None, 0, k_block_idx)], sfb),
            acc,
        )
    pipe.consumer_release(consumer_state)
    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.jit
def _launch_atom_external_tma_mma_with_scale_bridge(
    desc_a: cute.Tensor,
    desc_b: cute.Tensor,
    desc_sfa: cute.Tensor,
    desc_sfb: cute.Tensor,
    gA: cute.Tensor,
    gB: cute.Tensor,
    out: cute.Tensor,
):
    ab_smem_layout = sm120.make_mxf4nvf4_ab_tma_physical_layout_staged()
    tma_atom_a, tma_tensor_a = sm120.make_mxf4nvf4_tiled_tma_atom_a(
        gA, ab_smem_layout
    )
    tma_atom_b, tma_tensor_b = sm120.make_mxf4nvf4_tiled_tma_atom_b(
        gB, ab_smem_layout
    )
    _atom_external_tma_mma_with_scale_bridge_kernel(
        tma_atom_a,
        tma_tensor_a,
        tma_atom_b,
        tma_tensor_b,
        desc_a,
        desc_b,
        desc_sfa,
        desc_sfb,
        out,
    ).launch(grid=[1, 1, 1], block=[32, 1, 1], smem=100352)


def test_sm120_mxf4nvf4_external_tma_ldsm_mma_runtime_nonuniform_ab():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    a_storage, a_payload = _aligned_u8_tensor(torch, sm120.MXF4NVF4_AB_SMEM_BYTES, 32)
    b_storage, b_payload = _aligned_u8_tensor(torch, sm120.MXF4NVF4_AB_SMEM_BYTES, 32)
    a_payload[: sm120.MXF4NVF4_AB_TMA_BYTES].copy_(
        _patterned_u8(torch, sm120.MXF4NVF4_AB_TMA_BYTES, 0x5A)
    )
    b_payload[: sm120.MXF4NVF4_AB_TMA_BYTES].copy_(
        _patterned_u8(torch, sm120.MXF4NVF4_AB_TMA_BYTES, 0xA5)
    )
    a_payload[sm120.MXF4NVF4_AB_TMA_BYTES :].fill_(0)
    b_payload[sm120.MXF4NVF4_AB_TMA_BYTES :].fill_(0)
    phys_a = _expected_rank3_fp4_tma_physical(
        torch, a_payload[: sm120.MXF4NVF4_AB_TMA_BYTES]
    )
    phys_b = _expected_rank3_fp4_tma_physical(
        torch, b_payload[: sm120.MXF4NVF4_AB_TMA_BYTES]
    )
    try:
        desc_a = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(a_payload.data_ptr())
        desc_b = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(b_payload.data_ptr())
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")

    desc_a_storage, desc_a_dev = _device_desc_from_bytes(torch, desc_a)
    desc_b_storage, desc_b_dev = _device_desc_from_bytes(torch, desc_b)
    ref_out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    tma_out = torch.empty_like(ref_out)
    cute_phys_a = from_dlpack(phys_a, assumed_align=16, enable_tvm_ffi=True)
    cute_phys_b = from_dlpack(phys_b, assumed_align=16, enable_tvm_ffi=True)
    cute_ref_out = from_dlpack(ref_out, enable_tvm_ffi=True)
    cute.compile(
        _launch_mma_from_physical_smem,
        cute_phys_a,
        cute_phys_b,
        cute_ref_out,
        options="--enable-tvm-ffi --keep-ptx",
    )(cute_phys_a, cute_phys_b, cute_ref_out)
    cute_desc_a = from_dlpack(desc_a_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_desc_b = from_dlpack(desc_b_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_tma_out = from_dlpack(tma_out, enable_tvm_ffi=True)
    compiled = cute.compile(
        _launch_external_tma_mma,
        cute_desc_a,
        cute_desc_b,
        cute_tma_out,
        options="--enable-tvm-ffi --keep-ptx",
    )
    assert "fence.proxy.tensormap::generic.acquire.gpu" in compiled.__ptx__
    compiled(cute_desc_a, cute_desc_b, cute_tma_out)
    torch.cuda.synchronize()
    assert int(torch.unique(ref_out).numel()) > 1
    torch.testing.assert_close(tma_out, ref_out, rtol=0, atol=0)
    assert all(
        x is not None
        for x in (
            a_storage,
            b_storage,
            desc_a_storage,
            desc_b_storage,
        )
    )


def test_sm120_mxf4nvf4_atom_copy_external_tma_ldsm_mma_runtime_nonuniform_ab():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    # Keep the atom input rank-3 at compile time; the external descriptor still
    # provides the actual A/B base pointer, datatype, swizzle, and box shape.
    rank3_tensor_bytes = 2 * sm120.MXF4NVF4_AB_SMEM_BYTES
    a_storage, a_payload = _aligned_u8_tensor(torch, rank3_tensor_bytes, 32)
    b_storage, b_payload = _aligned_u8_tensor(torch, rank3_tensor_bytes, 32)
    a_payload[: sm120.MXF4NVF4_AB_TMA_BYTES].copy_(
        _patterned_u8(torch, sm120.MXF4NVF4_AB_TMA_BYTES, 0x3C)
    )
    b_payload[: sm120.MXF4NVF4_AB_TMA_BYTES].copy_(
        _patterned_u8(torch, sm120.MXF4NVF4_AB_TMA_BYTES, 0xC3)
    )
    a_payload[sm120.MXF4NVF4_AB_TMA_BYTES :].fill_(0)
    b_payload[sm120.MXF4NVF4_AB_TMA_BYTES :].fill_(0)
    phys_a = _expected_rank3_fp4_tma_physical(
        torch, a_payload[: sm120.MXF4NVF4_AB_TMA_BYTES]
    )
    phys_b = _expected_rank3_fp4_tma_physical(
        torch, b_payload[: sm120.MXF4NVF4_AB_TMA_BYTES]
    )
    try:
        desc_a = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(a_payload.data_ptr())
        desc_b = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(b_payload.data_ptr())
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")

    desc_a_storage, desc_a_dev = _device_desc_from_bytes(torch, desc_a)
    desc_b_storage, desc_b_dev = _device_desc_from_bytes(torch, desc_b)
    ref_out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    atom_out = torch.empty_like(ref_out)
    cute_phys_a = from_dlpack(phys_a, assumed_align=16, enable_tvm_ffi=True)
    cute_phys_b = from_dlpack(phys_b, assumed_align=16, enable_tvm_ffi=True)
    cute_ref_out = from_dlpack(ref_out, enable_tvm_ffi=True)
    cute.compile(
        _launch_mma_from_physical_smem,
        cute_phys_a,
        cute_phys_b,
        cute_ref_out,
        options="--enable-tvm-ffi --keep-ptx",
    )(cute_phys_a, cute_phys_b, cute_ref_out)
    cute_desc_a = from_dlpack(desc_a_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_desc_b = from_dlpack(desc_b_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_gA = from_dlpack(
        a_payload.reshape(128, 128, 2), assumed_align=32, enable_tvm_ffi=True
    )
    cute_gB = from_dlpack(
        b_payload.reshape(128, 128, 2), assumed_align=32, enable_tvm_ffi=True
    )
    cute_atom_out = from_dlpack(atom_out, enable_tvm_ffi=True)
    compiled = cute.compile(
        _launch_atom_external_tma_mma,
        cute_desc_a,
        cute_desc_b,
        cute_gA,
        cute_gB,
        cute_atom_out,
        options="--enable-tvm-ffi --keep-ptx",
    )
    assert compiled.__ptx__.count("cp.async.bulk.tensor.3d.shared::cta.global.tile") == 2
    assert "fence.proxy.tensormap::generic.acquire.gpu" in compiled.__ptx__
    compiled(cute_desc_a, cute_desc_b, cute_gA, cute_gB, cute_atom_out)
    torch.cuda.synchronize()
    assert int(torch.unique(ref_out).numel()) > 1
    torch.testing.assert_close(atom_out, ref_out, rtol=0, atol=0)
    assert all(
        x is not None
        for x in (
            a_storage,
            b_storage,
            desc_a_storage,
            desc_b_storage,
        )
    )


@pytest.mark.parametrize(
    ("case_name", "a_is_one", "b_is_one"),
    [
        (
            "all_ones",
            lambda major, k: True,
            lambda major, k: True,
        ),
        (
            "b_varies_by_logical_n",
            lambda major, k: True,
            lambda major, k: major < 4,
        ),
        (
            "sparse_b_logical_n_probe",
            lambda major, k: True,
            lambda major, k: major == 3,
        ),
        (
            "a_varies_by_logical_m",
            lambda major, k: major < 8,
            lambda major, k: True,
        ),
        (
            "low_nibble_only",
            lambda major, k: k % 2 == 0,
            lambda major, k: k % 2 == 0,
        ),
        (
            "cross_nibble_zero",
            lambda major, k: k % 2 == 0,
            lambda major, k: k % 2 == 1,
        ),
    ],
)
def test_sm120_mxf4nvf4_atom_copy_external_tma_ldsm_mma_runtime_logical_ab(
    case_name, a_is_one, b_is_one
):
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    rank3_tensor_bytes = 2 * sm120.MXF4NVF4_AB_SMEM_BYTES
    a_storage, a_payload = _aligned_u8_tensor(torch, rank3_tensor_bytes, 32)
    b_storage, b_payload = _aligned_u8_tensor(torch, rank3_tensor_bytes, 32)
    a_payload[: sm120.MXF4NVF4_AB_TMA_BYTES].copy_(
        _logical_fp4_payload(torch, a_is_one)
    )
    b_payload[: sm120.MXF4NVF4_AB_TMA_BYTES].copy_(
        _logical_fp4_payload(torch, b_is_one)
    )
    a_payload[sm120.MXF4NVF4_AB_TMA_BYTES :].fill_(0)
    b_payload[sm120.MXF4NVF4_AB_TMA_BYTES :].fill_(0)
    try:
        desc_a = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(a_payload.data_ptr())
        desc_b = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(b_payload.data_ptr())
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")

    desc_a_storage, desc_a_dev = _device_desc_from_bytes(torch, desc_a)
    desc_b_storage, desc_b_dev = _device_desc_from_bytes(torch, desc_b)
    out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    cute_desc_a = from_dlpack(desc_a_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_desc_b = from_dlpack(desc_b_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_gA = from_dlpack(
        a_payload.reshape(128, 128, 2), assumed_align=32, enable_tvm_ffi=True
    )
    cute_gB = from_dlpack(
        b_payload.reshape(128, 128, 2), assumed_align=32, enable_tvm_ffi=True
    )
    cute_out = from_dlpack(out, enable_tvm_ffi=True)
    compiled = cute.compile(
        _launch_atom_external_tma_mma,
        cute_desc_a,
        cute_desc_b,
        cute_gA,
        cute_gB,
        cute_out,
        options="--enable-tvm-ffi --keep-ptx",
    )
    assert compiled.__ptx__.count("cp.async.bulk.tensor.3d.shared::cta.global.tile") == 2
    compiled(cute_desc_a, cute_desc_b, cute_gA, cute_gB, cute_out)
    torch.cuda.synchronize()

    expected = _expected_raw_accumulator(torch, case_name)
    assert torch.equal(out, expected), (case_name, out.reshape(32, 4).cpu())
    assert all(
        x is not None
        for x in (
            a_storage,
            b_storage,
            desc_a_storage,
            desc_b_storage,
        )
    )


def test_sm120_mxf4nvf4_atom_tma_ab_scale_bridge_runtime_combined():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    rank3_tensor_bytes = 2 * sm120.MXF4NVF4_AB_SMEM_BYTES
    a_storage, a_payload = _aligned_u8_tensor(torch, rank3_tensor_bytes, 32)
    b_storage, b_payload = _aligned_u8_tensor(torch, rank3_tensor_bytes, 32)
    sfa_storage, sfa_payload = _aligned_u8_tensor(
        torch, sm120.MXF4NVF4_SCALE_TMA_BYTES, 16
    )
    sfb_storage, sfb_payload = _aligned_u8_tensor(
        torch, sm120.MXF4NVF4_SCALE_TMA_BYTES, 16
    )
    a_payload[: sm120.MXF4NVF4_AB_TMA_BYTES].copy_(
        _logical_fp4_payload(torch, lambda major, k: major < 8)
    )
    b_payload[: sm120.MXF4NVF4_AB_TMA_BYTES].copy_(
        _logical_fp4_payload(torch, lambda major, k: major < 4)
    )
    a_payload[sm120.MXF4NVF4_AB_TMA_BYTES :].fill_(0)
    b_payload[sm120.MXF4NVF4_AB_TMA_BYTES :].fill_(0)

    one = 0x38
    two = 0x40
    for scale_col in range(sm120.MXF4NVF4_SCALE_K):
        value = one if scale_col < 4 else two
        sfa_payload[scale_col * 128 : (scale_col + 1) * 128].fill_(value)
        sfb_payload[scale_col * 128 : (scale_col + 1) * 128].fill_(one)
    try:
        desc_a = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(a_payload.data_ptr())
        desc_b = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(b_payload.data_ptr())
        desc_sfa = cutlass.utils.make_sm120_mxf4nvf4_scale_tma_desc_bytes(
            sfa_payload.data_ptr()
        )
        desc_sfb = cutlass.utils.make_sm120_mxf4nvf4_scale_tma_desc_bytes(
            sfb_payload.data_ptr()
        )
    except CudaDriverDependencyError as exc:
        pytest.skip(f"CUDA Driver tensor-map encoder unavailable: {exc}")

    desc_a_storage, desc_a_dev = _device_desc_from_bytes(torch, desc_a)
    desc_b_storage, desc_b_dev = _device_desc_from_bytes(torch, desc_b)
    desc_sfa_storage, desc_sfa_dev = _device_desc_from_bytes(torch, desc_sfa)
    desc_sfb_storage, desc_sfb_dev = _device_desc_from_bytes(torch, desc_sfb)
    out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    cute_desc_a = from_dlpack(desc_a_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_desc_b = from_dlpack(desc_b_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_desc_sfa = from_dlpack(desc_sfa_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_desc_sfb = from_dlpack(desc_sfb_dev, assumed_align=128, enable_tvm_ffi=True)
    cute_gA = from_dlpack(
        a_payload.reshape(128, 128, 2), assumed_align=32, enable_tvm_ffi=True
    )
    cute_gB = from_dlpack(
        b_payload.reshape(128, 128, 2), assumed_align=32, enable_tvm_ffi=True
    )
    cute_out = from_dlpack(out, enable_tvm_ffi=True)
    compiled = cute.compile(
        _launch_atom_external_tma_mma_with_scale_bridge,
        cute_desc_a,
        cute_desc_b,
        cute_desc_sfa,
        cute_desc_sfb,
        cute_gA,
        cute_gB,
        cute_out,
        options="--enable-tvm-ffi --keep-ptx",
    )
    assert compiled.__ptx__.count("cp.async.bulk.tensor.3d.shared::cta.global.tile") == 2
    assert compiled.__ptx__.count("cp.async.bulk.tensor.4d.shared::cta.global") == 2
    compiled(
        cute_desc_a,
        cute_desc_b,
        cute_desc_sfa,
        cute_desc_sfb,
        cute_gA,
        cute_gB,
        cute_out,
    )
    torch.cuda.synchronize()

    expected = torch.zeros((32, 4), device="cuda", dtype=torch.float32)
    expected[torch.arange(32, device="cuda") % 4 < 2, 0:2] = 192.0
    assert torch.equal(out, expected.reshape(-1)), out.reshape(32, 4).cpu()
    assert all(
        x is not None
        for x in (
            a_storage,
            b_storage,
            sfa_storage,
            sfb_storage,
            desc_a_storage,
            desc_b_storage,
            desc_sfa_storage,
            desc_sfb_storage,
        )
    )
