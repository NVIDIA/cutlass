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
    assert "stage_mxf4nvf4_ab_tma_physical_to_ldsm_scratch" in source
    assert "load_mxf4nvf4_ldsm_scratch_fragments" in source
    assert "stage_mxf4nvf4_scale_tma_physical_to_fragment_scratch" in source
    assert "make_mxf4nvf4_scale_fragment_views_from_scratch" in source
    assert "cute.copy(" in source
    assert "tma_desc_ptr=" in source


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
    sA_ldsm_scratch_all, sB_ldsm_scratch_all = sm120.allocate_mxf4nvf4_ldsm_scratch(
        smem
    )
    sA_ldsm_scratch, sB_ldsm_scratch = sm120.make_mxf4nvf4_ldsm_scratch_views(
        sA_ldsm_scratch_all, sB_ldsm_scratch_all, cutlass.Int32(0)
    )
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
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sm120.stage_mxf4nvf4_ab_tma_physical_to_ldsm_scratch(
            sA_tma,
            sB_tma,
            sA_ldsm_scratch,
            sB_ldsm_scratch,
            k_block_idx=k_block_idx,
            lane_idx=tidx,
        )
        cute.arch.sync_threads()
        sm120.load_mxf4nvf4_ldsm_scratch_fragments(
            tiled_mma, sA_ldsm_scratch, sB_ldsm_scratch, a, b, tidx
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
            sSFA, sSFB, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)
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
    sA_ldsm_scratch_all, sB_ldsm_scratch_all = sm120.allocate_mxf4nvf4_ldsm_scratch(
        smem
    )
    sA_ldsm_scratch, sB_ldsm_scratch = sm120.make_mxf4nvf4_ldsm_scratch_views(
        sA_ldsm_scratch_all, sB_ldsm_scratch_all, cutlass.Int32(0)
    )
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
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sm120.stage_mxf4nvf4_ab_tma_physical_to_ldsm_scratch(
            sA_tma,
            sB_tma,
            sA_ldsm_scratch,
            sB_ldsm_scratch,
            k_block_idx=k_block_idx,
            lane_idx=tidx,
        )
        cute.arch.sync_threads()
        sm120.load_mxf4nvf4_ldsm_scratch_fragments(
            tiled_mma, sA_ldsm_scratch, sB_ldsm_scratch, a, b, tidx
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
            sSFA, sSFB, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)
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
    sA_ldsm_scratch_all, sB_ldsm_scratch_all = sm120.allocate_mxf4nvf4_ldsm_scratch(
        smem
    )
    sA_ldsm_scratch, sB_ldsm_scratch = sm120.make_mxf4nvf4_ldsm_scratch_views(
        sA_ldsm_scratch_all, sB_ldsm_scratch_all, cutlass.Int32(0)
    )
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
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sm120.stage_mxf4nvf4_ab_tma_physical_to_ldsm_scratch(
            sA_tma,
            sB_tma,
            sA_ldsm_scratch,
            sB_ldsm_scratch,
            k_block_idx=k_block_idx,
            lane_idx=tidx,
        )
        cute.arch.sync_threads()
        sm120.load_mxf4nvf4_ldsm_scratch_fragments(
            tiled_mma, sA_ldsm_scratch, sB_ldsm_scratch, a, b, tidx
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
            sSFA, sSFB, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)
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
    sA_ldsm_scratch_all, sB_ldsm_scratch_all = sm120.allocate_mxf4nvf4_ldsm_scratch(
        smem
    )
    sA_ldsm_scratch, sB_ldsm_scratch = sm120.make_mxf4nvf4_ldsm_scratch_views(
        sA_ldsm_scratch_all, sB_ldsm_scratch_all, cutlass.Int32(0)
    )
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
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa, sfb = sm120.make_mxf4nvf4_scale_fragments()
    acc.fill(0.0)
    for k_block_idx in cutlass.range_constexpr(2):
        sm120.stage_mxf4nvf4_ab_tma_physical_to_ldsm_scratch(
            sA_tma,
            sB_tma,
            sA_ldsm_scratch,
            sB_ldsm_scratch,
            k_block_idx=k_block_idx,
            lane_idx=tidx,
        )
        cute.arch.sync_threads()
        sm120.load_mxf4nvf4_ldsm_scratch_fragments(
            tiled_mma, sA_ldsm_scratch, sB_ldsm_scratch, a, b, tidx
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_smem_fragment_views(
            sSFA, sSFB, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)
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


@pytest.mark.xfail(
    reason=(
        "legacy physical-byte reference no longer models the logical A/B "
        "scratch bridge after payload/gap compaction"
    )
)
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


@pytest.mark.xfail(
    reason=(
        "legacy physical-byte reference no longer models the logical A/B "
        "scratch bridge after payload/gap compaction"
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
    ("case_name", "a_is_one", "b_is_one", "expected_128_count"),
    [
        (
            "all_ones",
            lambda major, k: True,
            lambda major, k: True,
            128,
        ),
        pytest.param(
            "b_varies_by_logical_n",
            lambda major, k: True,
            lambda major, k: major < 4,
            64,
            marks=pytest.mark.xfail(
                reason="logical B major-to-output-N probe still needs the full SM120 LDSM map",
                strict=True,
            ),
        ),
        pytest.param(
            "sparse_b_logical_n_probe",
            lambda major, k: True,
            lambda major, k: major == 3,
            16,
            marks=pytest.mark.xfail(
                reason="logical B major-to-output-N probe still needs the full SM120 LDSM map",
                strict=True,
            ),
        ),
        pytest.param(
            "a_varies_by_logical_m",
            lambda major, k: major < 8,
            lambda major, k: True,
            64,
            marks=pytest.mark.xfail(
                reason="logical A major-to-output-M probe still needs the full SM120 LDSM map",
                strict=True,
            ),
        ),
    ],
)
def test_sm120_mxf4nvf4_atom_copy_external_tma_ldsm_mma_runtime_logical_ab(
    case_name, a_is_one, b_is_one, expected_128_count
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

    expected_zero_count = out.numel() - expected_128_count
    actual_128_count = int(torch.count_nonzero(out == 128.0).item())
    actual_zero_count = int(torch.count_nonzero(out == 0.0).item())
    unique_values, unique_counts = torch.unique(out, return_counts=True)
    unique_summary = list(zip(unique_values.cpu().tolist(), unique_counts.cpu().tolist()))
    assert actual_128_count == expected_128_count, (case_name, unique_summary)
    assert actual_zero_count == expected_zero_count, (case_name, unique_summary)
    assert all(
        x is not None
        for x in (
            a_storage,
            b_storage,
            desc_a_storage,
            desc_b_storage,
        )
    )
