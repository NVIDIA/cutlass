# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""Compile-time SM120 MXF4NVF4 mainloop scaffold."""

import argparse

import cutlass
import cutlass.cute as cute
from cutlass import pipeline
from cutlass.base_dsl.common import CudaDriverDependencyError
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack, make_fake_compact_tensor
from cutlass.utils.gemm import sm120


@cute.kernel
def _mainloop_kernel(
    tma_atom_a: cute.CopyAtom,
    tma_tensor_a: cute.Tensor,
    tma_atom_b: cute.CopyAtom,
    tma_tensor_b: cute.Tensor,
    tma_atom_sfa: cute.CopyAtom,
    tma_tensor_sfa: cute.Tensor,
    tma_atom_sfb: cute.CopyAtom,
    tma_tensor_sfb: cute.Tensor,
    desc_a: cute.Tensor,
    desc_b: cute.Tensor,
    desc_sfa: cute.Tensor,
    desc_sfb: cute.Tensor,
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
    sSFA = smem.allocate_tensor(
        cutlass.Uint8,
        sm120.make_mxf4nvf4_scale_tma_physical_layout_staged(),
        byte_alignment=128,
    )
    sSFB = smem.allocate_tensor(
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
    tSFAs, tSFAg = cpasync.tma_partition(
        tma_atom_sfa,
        0,
        cute.make_layout(1),
        cute.group_modes(sSFA, 0, 2),
        cute.group_modes(tma_tensor_sfa, 0, 2),
    )
    tSFBs, tSFBg = cpasync.tma_partition(
        tma_atom_sfb,
        0,
        cute.make_layout(1),
        cute.group_modes(sSFB, 0, 2),
        cute.group_modes(tma_tensor_sfb, 0, 2),
    )

    pipe = pipeline.PipelineTmaWarpMma.create(
        num_stages=1,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        tx_count=sm120.mxf4nvf4_full_tma_tx_bytes(),
        barrier_storage=barriers,
    )
    producer_state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Producer, 1)
    pipe.producer_acquire(producer_state, pipe.producer_try_acquire(producer_state))
    bar = pipe.producer_get_barrier(producer_state)

    desc_a_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_a)
    desc_b_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_b)
    desc_sfa_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_sfa)
    desc_sfb_ptr = sm120.make_mxf4nvf4_external_tma_desc_ptr(desc_sfb)

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
    cute.copy(
        tma_atom_sfa,
        tSFAg[(None, 0, 0)],
        tSFAs[(None, 0, 0)],
        tma_bar_ptr=bar,
        tma_desc_ptr=desc_sfa_ptr,
    )
    cute.copy(
        tma_atom_sfb,
        tSFBg[(None, 0, 0)],
        tSFBs[(None, 0, 0)],
        tma_bar_ptr=bar,
        tma_desc_ptr=desc_sfb_ptr,
    )
    pipe.producer_commit(producer_state)
    consumer_state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Consumer, 1)
    pipe.consumer_wait(consumer_state, pipe.consumer_try_wait(consumer_state))
    cute.arch.sync_threads()

    sm120.stage_mxf4nvf4_scale_tma_physical_to_fragment_scratch(
        sSFA,
        sSFB,
        sSFA_scratch,
        sSFB_scratch,
        lane_idx=tidx,
    )
    cute.arch.sync_threads()

    tiled_mma = sm120.make_mxf4nvf4_tiled_mma()
    a_frag = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b_frag = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(
        tiled_mma.partition_shape_C((16, 8)), cutlass.Float32
    )
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
            tiled_mma, sA_ldsm_scratch, sB_ldsm_scratch, a_frag, b_frag, tidx
        )
        sfa_src, sfb_src = sm120.make_mxf4nvf4_scale_fragment_views_from_scratch(
            sSFA_scratch, sSFB_scratch, k_block_idx
        )
        sm120.load_mxf4nvf4_sfa_fragment(sfa_src, sfa)
        sm120.load_mxf4nvf4_sfb_fragment(sfb_src, sfb)
        cute.gemm(tiled_mma, acc, (a_frag, sfa), (b_frag, sfb), acc)
        cute.arch.sync_threads()
    pipe.consumer_release(consumer_state)
    out[0] = acc[0].to(cutlass.BFloat16)


@cute.jit
def _launch(
    desc_a: cute.Tensor,
    desc_b: cute.Tensor,
    desc_sfa: cute.Tensor,
    desc_sfb: cute.Tensor,
    gA: cute.Tensor,
    gB: cute.Tensor,
    gSFA: cute.Tensor,
    gSFB: cute.Tensor,
    out: cute.Tensor,
):
    ab_smem_layout = sm120.make_mxf4nvf4_ab_tma_physical_layout_staged()
    scale_smem_layout = sm120.make_mxf4nvf4_scale_tma_physical_layout_staged()
    tma_atom_a, tma_tensor_a = sm120.make_mxf4nvf4_tiled_tma_atom_a(
        gA, ab_smem_layout
    )
    tma_atom_b, tma_tensor_b = sm120.make_mxf4nvf4_tiled_tma_atom_b(
        gB, ab_smem_layout
    )
    tma_atom_sfa, tma_tensor_sfa = sm120.make_mxf4nvf4_sfa_tiled_tma_atom(
        gSFA, scale_smem_layout
    )
    tma_atom_sfb, tma_tensor_sfb = sm120.make_mxf4nvf4_sfb_tiled_tma_atom(
        gSFB, scale_smem_layout
    )
    _mainloop_kernel(
        tma_atom_a,
        tma_tensor_a,
        tma_atom_b,
        tma_tensor_b,
        tma_atom_sfa,
        tma_tensor_sfa,
        tma_atom_sfb,
        tma_tensor_sfb,
        desc_a,
        desc_b,
        desc_sfa,
        desc_sfb,
        out,
    ).launch(grid=[1, 1, 1], block=[32, 1, 1], smem=65536)


def fake_inputs():
    desc = make_fake_compact_tensor(
        cutlass.Uint8,
        (sm120.MXF4NVF4_TMA_DESC_BYTES,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=128,
    )
    g_ab = make_fake_compact_tensor(
        cutlass.Uint8,
        (128, 128, 2),
        memspace=cute.AddressSpace.gmem,
        assumed_align=32,
    )
    g_scale = make_fake_compact_tensor(
        cutlass.Uint8,
        (128, sm120.MXF4NVF4_SCALE_K, 2, 2),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )
    out = make_fake_compact_tensor(
        cutlass.BFloat16,
        (1,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )
    return desc, desc, desc, desc, g_ab, g_ab, g_scale, g_scale, out


def compile_mainloop(*, keep_ptx: bool = True, keep_cubin: bool = False):
    options = "--gpu-arch=sm_120a --enable-tvm-ffi"
    if keep_ptx:
        options += " --keep-ptx"
    if keep_cubin:
        options += " --keep-cubin"
    return cute.compile(_launch, *fake_inputs(), options=options)


def inspect_ptx(ptx: str) -> None:
    required = [
        "cp.async.bulk.tensor.3d.shared::cta.global.tile",
        "cp.async.bulk.tensor.4d.shared::cta.global.tile",
        "ldmatrix.sync.aligned.m8n8.x4.shared.b16",
        "mma.sync.aligned.m16n8k64.row.col.kind::mxf4nvf4.block_scale.scale_vec::4X",
    ]
    forbidden = ["b4x16_p64", "shared::cluster", ".multicast", "tcgen05"]
    for needle in required:
        if needle not in ptx:
            raise AssertionError(f"missing expected PTX: {needle}")
    for needle in forbidden:
        if needle in ptx:
            raise AssertionError(f"unexpected PTX: {needle}")


@cute.kernel
def _runtime_check_kernel(out: cute.Tensor):
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
def _launch_runtime_check(out: cute.Tensor):
    _runtime_check_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])


def runtime_check() -> None:
    torch = __import__("torch")
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA device unavailable")
    out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    cute_out = from_dlpack(out, enable_tvm_ffi=True)
    compiled = cute.compile(_launch_runtime_check, cute_out, options="--keep-ptx")
    compiled(cute_out)
    torch.cuda.synchronize()
    expected = torch.full_like(out, 192.0)
    torch.testing.assert_close(out, expected, rtol=0, atol=0)


@cute.kernel
def _runtime_tma_copy_kernel(desc: cute.Tensor, out: cute.Tensor):
    smem = cutlass.utils.SmemAllocator()
    smem_tensor = smem.allocate_tensor(
        cutlass.Uint8, cute.make_layout(17408), byte_alignment=128
    )
    barriers = smem.allocate_array(cutlass.Int64, 2, byte_alignment=8)
    tidx, _, _ = cute.arch.thread_idx()

    for i in cutlass.range(tidx, 17408, 32):
        smem_tensor[i] = cutlass.Uint8(0xCD)
    cute.arch.sync_threads()

    pipe = pipeline.PipelineTmaWarpMma.create(
        num_stages=1,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        tx_count=sm120.mxf4nvf4_ab_tma_tx_bytes(),
        barrier_storage=barriers,
    )
    producer_state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Producer, 1)
    consumer_state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Consumer, 1)
    pipeline.producer_acquire_issue_tma_load_3d(
        pipe,
        producer_state,
        None,
        smem_tensor.iterator,
        desc.iterator,
        0,
        0,
        0,
        already_elected=False,
    )
    pipe.consumer_wait(consumer_state)
    cute.arch.sync_threads()
    for i in cutlass.range(tidx, 17408, 32):
        out[i] = smem_tensor[i]
    pipe.consumer_release(consumer_state)


@cute.jit
def _launch_runtime_tma_copy(desc: cute.Tensor, out: cute.Tensor):
    _runtime_tma_copy_kernel(desc, out).launch(grid=[1, 1, 1], block=[32, 1, 1])


def _aligned_u8_tensor(torch, num_bytes: int, alignment: int):
    storage = torch.empty(num_bytes + alignment - 1, device="cuda", dtype=torch.uint8)
    offset = (-storage.data_ptr()) % alignment
    view = storage[offset : offset + num_bytes]
    if view.data_ptr() % alignment != 0:
        raise RuntimeError("failed to create aligned CUDA tensor")
    return storage, view


def _patterned_u8(torch, count: int):
    values = torch.arange(count, device="cuda", dtype=torch.int32)
    return torch.bitwise_xor(values, 0x5A).to(torch.uint8)


def _expected_rank3_fp4_tma_output(torch, src, output_bytes: int):
    expected = torch.full((output_bytes,), 0xCD, device="cuda", dtype=torch.uint8)
    for dst_payload_chunk in range(src.numel() // 8):
        dst_base = dst_payload_chunk * 16
        src_swizzle_chunk = dst_payload_chunk ^ ((dst_payload_chunk >> 3) & 0x7)
        src_base = src_swizzle_chunk * 8
        expected[dst_base : dst_base + 8] = src[src_base : src_base + 8]
    return expected


def runtime_tma_check() -> None:
    torch = __import__("torch")
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA device unavailable")
    src_storage, src = _aligned_u8_tensor(torch, sm120.MXF4NVF4_AB_TMA_BYTES, 32)
    src.copy_(_patterned_u8(torch, src.numel()))
    try:
        desc_bytes = cutlass.utils.make_sm120_mxf4nvf4_tma_desc_bytes(src.data_ptr())
    except CudaDriverDependencyError as exc:
        raise RuntimeError(f"CUDA Driver tensor-map encoder unavailable: {exc}") from exc
    desc_storage, desc = _aligned_u8_tensor(torch, sm120.MXF4NVF4_TMA_DESC_BYTES, 128)
    desc.copy_(torch.tensor(list(desc_bytes), device="cuda", dtype=torch.uint8))
    out = torch.empty((17408,), device="cuda", dtype=torch.uint8)
    cute_desc = from_dlpack(desc, assumed_align=128, enable_tvm_ffi=True)
    cute_out = from_dlpack(out, assumed_align=16, enable_tvm_ffi=True)
    cute.compile(
        _launch_runtime_tma_copy,
        cute_desc,
        cute_out,
        options="--enable-tvm-ffi",
    )(cute_desc, cute_out)
    torch.cuda.synchronize()
    expected = _expected_rank3_fp4_tma_output(torch, src, out.numel())
    if not torch.equal(out, expected):
        raise AssertionError("runtime TMA descriptor check copied unexpected bytes")
    _ = src_storage, desc_storage


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--compile-only", action="store_true")
    parser.add_argument("--ptx-inspect", action="store_true")
    parser.add_argument("--runtime-check", action="store_true")
    parser.add_argument("--runtime-tma-check", action="store_true")
    args = parser.parse_args()
    if args.runtime_check:
        runtime_check()
        return
    if args.runtime_tma_check:
        runtime_tma_check()
        return
    compiled = compile_mainloop(keep_ptx=args.ptx_inspect)
    if args.ptx_inspect:
        inspect_ptx(compiled.__ptx__)
    if not args.compile_only and not args.ptx_inspect:
        print("compiled")


if __name__ == "__main__":
    main()
