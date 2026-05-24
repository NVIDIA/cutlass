# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import warp
from cutlass.cute.runtime import from_dlpack, make_fake_compact_tensor


pytestmark = [pytest.mark.arch(["120a"])]

_MXF4NVF4_UE4M3_MMA_PTX = (
    "mma.sync.aligned.m16n8k64.row.col.kind::mxf4nvf4.block_scale."
    "scale_vec::4X.f32.e2m1.e2m1.f32.ue4m3"
)


@cute.kernel
def _mma_mxf4nvf4_kernel(out: cute.Tensor, scale_a2: cutlass.Constexpr[bool]):
    tidx, _, _ = cute.arch.thread_idx()
    mma_op = warp.MmaMXF4NVF4Op(
        cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E4M3FN
    )
    tiled_mma = cute.make_tiled_mma(mma_op)
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa = warp.make_mxf4nvf4_sfa_fragment()
    sfb = warp.make_mxf4nvf4_sfb_fragment()

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    sfa.fill(2.0 if scale_a2 else 1.0)
    sfb.fill(1.0)

    warp.mma_mxf4nvf4(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.kernel
def _gemm_bundle_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    mma_op = warp.MmaMXF4NVF4Op(
        cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E4M3FN
    )
    tiled_mma = cute.make_tiled_mma(mma_op)
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa = warp.make_mxf4nvf4_sfa_fragment()
    sfb = warp.make_mxf4nvf4_sfb_fragment()

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    sfa.fill(1.0)
    sfb.fill(1.0)

    cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.jit
def _launch_mma_mxf4nvf4(out: cute.Tensor):
    _mma_mxf4nvf4_kernel(out, False).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.jit
def _launch_mma_mxf4nvf4_scale_a2(out: cute.Tensor):
    _mma_mxf4nvf4_kernel(out, True).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.jit
def _launch_gemm_bundle(out: cute.Tensor):
    _gemm_bundle_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.kernel
def _full_fragment_gemm_bundle_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    mma_op = warp.MmaMXF4NVF4Op(
        cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E4M3FN
    )
    tiled_mma = cute.make_tiled_mma(
        mma_op,
        atom_layout_mnk=cute.make_layout((4, 2, 1), stride=(1, 4, 0)),
        permutation_mnk=(
            128,
            cute.make_layout((8, 2, 2), stride=(1, 16, 8)),
            64,
        ),
    )
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((128, 128)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((128, 128)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(
        tiled_mma.partition_shape_C((128, 128)), cutlass.Float32
    )
    sfa = cute.make_rmem_tensor(
        cute.make_layout(((16, 4), 2, 2), stride=((0, 1), 4, 8)),
        cutlass.Float8E4M3FN,
    )
    sfb = cute.make_rmem_tensor(
        cute.make_layout(((16, 4), 8, 2), stride=((0, 1), 4, 32)),
        cutlass.Float8E4M3FN,
    )

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    sfa.fill(1.0)
    sfb.fill(1.0)
    cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.jit
def _launch_full_fragment_gemm_bundle(out: cute.Tensor):
    _full_fragment_gemm_bundle_kernel(out).launch(
        grid=[1, 1, 1], block=[256, 1, 1]
    )


@cute.kernel
def _wrong_scale_dtype_kernel(out: cute.Tensor):
    mma_op = warp.MmaMXF4NVF4Op(
        cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E4M3FN
    )
    tiled_mma = cute.make_tiled_mma(mma_op)
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfa = cute.make_rmem_tensor(warp.make_mxf4nvf4_sfa_layout(), cutlass.Float8E5M2)
    sfb = warp.make_mxf4nvf4_sfb_fragment()
    cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)


@cute.jit
def _launch_wrong_scale_dtype(out: cute.Tensor):
    _wrong_scale_dtype_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.kernel
def _wrong_accumulator_dtype_kernel(out: cute.Tensor):
    mma_op = warp.MmaMXF4NVF4Op(
        cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E4M3FN
    )
    tiled_mma = cute.make_tiled_mma(mma_op)
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float16)
    sfa = warp.make_mxf4nvf4_sfa_fragment()
    sfb = warp.make_mxf4nvf4_sfb_fragment()
    cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)


@cute.jit
def _launch_wrong_accumulator_dtype(out: cute.Tensor):
    _wrong_accumulator_dtype_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.kernel
def _non_rmem_scale_kernel(out: cute.Tensor, scale: cute.Tensor):
    mma_op = warp.MmaMXF4NVF4Op(
        cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E4M3FN
    )
    tiled_mma = cute.make_tiled_mma(mma_op)
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    sfb = warp.make_mxf4nvf4_sfb_fragment()
    cute.gemm(tiled_mma, acc, (a, scale), (b, sfb), acc)


@cute.jit
def _launch_non_rmem_scale(out: cute.Tensor, scale: cute.Tensor):
    _non_rmem_scale_kernel(out, scale).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.kernel
def _plain_f16bf16_gemm_kernel(out: cute.Tensor):
    mma_op = warp.MmaF16BF16Op(cutlass.Float16, cutlass.Float32, (16, 8, 16))
    tiled_mma = cute.make_tiled_mma(mma_op)
    a = cute.make_rmem_tensor(tiled_mma.partition_shape_A((16, 16)), cutlass.Float16)
    b = cute.make_rmem_tensor(tiled_mma.partition_shape_B((8, 16)), cutlass.Float16)
    acc = cute.make_rmem_tensor(tiled_mma.partition_shape_C((16, 8)), cutlass.Float32)
    a.fill(1.0)
    b.fill(1.0)
    acc.fill(0.0)
    cute.gemm(tiled_mma, acc, a, b, acc)

    tidx, _, _ = cute.arch.thread_idx()
    if tidx == 0:
        out[0] = acc[0]


@cute.jit
def _launch_plain_f16bf16_gemm(out: cute.Tensor):
    _plain_f16bf16_gemm_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])


def _cuda_out():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    return torch, out, from_dlpack(out, enable_tvm_ffi=True)


def _compile_mma_runtime(fn, *args):
    compiled = cute.compile(fn, *args, options="--keep-ptx --keep-cubin")
    assert _MXF4NVF4_UE4M3_MMA_PTX in compiled.__ptx__
    assert "_mma.block_scale" not in compiled.__ptx__
    if not isinstance(compiled.artifacts.CUBIN, bytes):
        pytest.skip("CuTe DSL CUBIN artifact unavailable for SM120 MMA backend check")
    return compiled


def _fake_float32_out():
    return make_fake_compact_tensor(
        cutlass.Float32,
        (32 * 4,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )


def test_sm120_mxf4nvf4_direct_helper_all_ones():
    torch, out, cute_out = _cuda_out()
    compiled = _compile_mma_runtime(_launch_mma_mxf4nvf4, cute_out)
    compiled(cute_out)
    torch.cuda.synchronize()
    torch.testing.assert_close(out, torch.full_like(out, 64.0), rtol=0, atol=0)


def test_sm120_mxf4nvf4_gemm_bundle_matches_direct_helper():
    torch, out_direct, cute_direct = _cuda_out()
    _, out_gemm, cute_gemm = _cuda_out()
    _compile_mma_runtime(_launch_mma_mxf4nvf4, cute_direct)(cute_direct)
    _compile_mma_runtime(_launch_gemm_bundle, cute_gemm)(cute_gemm)
    torch.cuda.synchronize()
    torch.testing.assert_close(out_gemm, out_direct, rtol=0, atol=0)


def test_sm120_mxf4nvf4_direct_helper_scale_a2():
    torch, out, cute_out = _cuda_out()
    compiled = _compile_mma_runtime(_launch_mma_mxf4nvf4_scale_a2, cute_out)
    compiled(cute_out)
    torch.cuda.synchronize()
    torch.testing.assert_close(out, torch.full_like(out, 128.0), rtol=0, atol=0)


def test_sm120_mxf4nvf4_full_fragment_gemm_bundle_compile():
    out = make_fake_compact_tensor(
        cutlass.Float32,
        (256 * 64,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )
    compiled = cute.compile(_launch_full_fragment_gemm_bundle, out, options="--keep-ptx")
    assert (
        compiled.__ptx__.count(
            "mma.sync.aligned.m16n8k64.row.col.kind::mxf4nvf4.block_scale.scale_vec::4X"
        )
        == 2
    )


def test_sm120_mxf4nvf4_wrong_scale_dtype_rejects():
    with pytest.raises(Exception, match="sfa.*Float8E4M3FN"):
        cute.compile(_launch_wrong_scale_dtype, _fake_float32_out())


def test_sm120_mxf4nvf4_wrong_accumulator_dtype_rejects():
    with pytest.raises(Exception, match="d.*Float32"):
        cute.compile(_launch_wrong_accumulator_dtype, _fake_float32_out())


def test_sm120_mxf4nvf4_non_rmem_scale_rejects():
    scale = make_fake_compact_tensor(
        cutlass.Float8E4M3FN,
        (64,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )
    with pytest.raises(Exception, match="sfa.*register-resident"):
        cute.compile(_launch_non_rmem_scale, _fake_float32_out(), scale)


def test_sm120_mxf4nvf4_plain_f16bf16_gemm_still_compiles():
    cute.compile(_launch_plain_f16bf16_gemm, _fake_float32_out())
