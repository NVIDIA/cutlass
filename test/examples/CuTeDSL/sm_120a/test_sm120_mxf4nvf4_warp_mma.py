# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import warp
from cutlass.cute.runtime import from_dlpack


pytestmark = [pytest.mark.arch(["120a"])]

_MXF4NVF4_UE4M3_MMA_PTX = (
    "mma.sync.aligned.m16n8k64.row.col.kind::mxf4nvf4.block_scale."
    "scale_vec::4X.f32.e2m1.e2m1.f32.ue4m3"
)


@cute.kernel
def _mma_unpack_kernel(out: cute.Tensor, scale_a2: cutlass.Constexpr[bool]):
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

    warp.mma_unpack(tiled_mma, acc, (a, sfa), (b, sfb), acc)

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


@cute.kernel
def _mma_unpack_nonuniform_kernel(out: cute.Tensor):
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
    a_i32 = cute.recast_tensor(a, cutlass.Int32)
    b_i32 = cute.recast_tensor(b, cutlass.Int32)

    for i in cutlass.range(cute.size(a_i32), unroll_full=True):
        a_i32[i] = 0x11111111 + tidx + i
    for i in cutlass.range(cute.size(b_i32), unroll_full=True):
        b_i32[i] = 0x22222222 + tidx + i
    sfa.fill(1.0)
    sfb.fill(1.0)
    acc.fill(0.0)

    warp.mma_unpack(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    acc_size = cute.size(acc)
    for i in cutlass.range(acc_size, unroll_full=True):
        out[tidx * acc_size + i] = acc[i]


@cute.kernel
def _bad_scale_dtype_kernel(out: cute.Tensor):
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
    sfa = cute.make_rmem_tensor(warp.make_mxf4nvf4_sfa_layout(), cutlass.Float32)
    sfb = warp.make_mxf4nvf4_sfb_fragment()
    warp.mma_unpack(tiled_mma, acc, (a, sfa), (b, sfb), acc)
    out[0] = 0.0


@cute.kernel
def _bad_bundle_kernel(out: cute.Tensor):
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
    cute.gemm(tiled_mma, acc, (a, sfa), b, acc)
    out[0] = 0.0


@cute.jit
def _launch_mma_unpack(out: cute.Tensor):
    _mma_unpack_kernel(out, False).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.jit
def _launch_mma_unpack_scale_a2(out: cute.Tensor):
    _mma_unpack_kernel(out, True).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.jit
def _launch_gemm_bundle(out: cute.Tensor):
    _gemm_bundle_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.jit
def _launch_mma_unpack_nonuniform(out: cute.Tensor):
    _mma_unpack_nonuniform_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.jit
def _launch_bad_scale_dtype(out: cute.Tensor):
    _bad_scale_dtype_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])


@cute.jit
def _launch_bad_bundle(out: cute.Tensor):
    _bad_bundle_kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])


def _cuda_out():
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.empty((32 * 4,), device="cuda", dtype=torch.float32)
    return torch, out, from_dlpack(out, enable_tvm_ffi=True)


def _compile_mma_runtime(fn, *args):
    # Keep executable canaries coupled to the exact SM120 MMA mnemonic and a
    # materialized CUBIN while leaving constexpr choices at compile time.
    compiled = cute.compile(fn, *args, options="--keep-ptx --keep-cubin")
    ptx = compiled.__ptx__
    assert _MXF4NVF4_UE4M3_MMA_PTX in ptx
    assert "_mma.block_scale" not in ptx

    cubin = compiled.artifacts.CUBIN
    if not isinstance(cubin, bytes):
        pytest.skip("CuTe DSL CUBIN artifact unavailable for SM120 MMA backend check")
    return compiled


def test_sm120_mxf4nvf4_mma_unpack_all_ones():
    torch, out, cute_out = _cuda_out()
    compiled = _compile_mma_runtime(_launch_mma_unpack, cute_out)
    compiled(cute_out)
    torch.cuda.synchronize()
    torch.testing.assert_close(out, torch.full_like(out, 64.0), rtol=0, atol=0)


def test_sm120_mxf4nvf4_gemm_bundle_matches_mma_unpack():
    torch, out_unpack, cute_unpack = _cuda_out()
    _, out_gemm, cute_gemm = _cuda_out()
    _compile_mma_runtime(_launch_mma_unpack, cute_unpack)(cute_unpack)
    _compile_mma_runtime(_launch_gemm_bundle, cute_gemm)(cute_gemm)
    torch.cuda.synchronize()
    torch.testing.assert_close(out_gemm, out_unpack, rtol=0, atol=0)


def test_sm120_mxf4nvf4_mma_unpack_scale_a2():
    torch, out, cute_out = _cuda_out()
    compiled = _compile_mma_runtime(_launch_mma_unpack_scale_a2, cute_out)
    compiled(cute_out)
    torch.cuda.synchronize()
    torch.testing.assert_close(out, torch.full_like(out, 128.0), rtol=0, atol=0)


def test_sm120_mxf4nvf4_mma_unpack_nonuniform_operands_compile():
    _, out, cute_out = _cuda_out()
    cute.compile(_launch_mma_unpack_nonuniform, cute_out, options="--keep-ptx")


def test_sm120_mxf4nvf4_bad_scale_dtype_raises():
    _, out, cute_out = _cuda_out()
    with pytest.raises(TypeError):
        cute.compile(_launch_bad_scale_dtype, cute_out)


def test_sm120_mxf4nvf4_one_sided_bundle_raises():
    _, out, cute_out = _cuda_out()
    with pytest.raises((TypeError, ValueError)):
        cute.compile(_launch_bad_bundle, cute_out)


def test_sm120_mxf4nvf4_mma_unpack_rejects_non_2_sequence():
    _, out, cute_out = _cuda_out()

    @cute.kernel
    def _bad(out_: cute.Tensor):
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
        acc = cute.make_rmem_tensor(
            tiled_mma.partition_shape_C((16, 8)), cutlass.Float32
        )
        sfa = warp.make_mxf4nvf4_sfa_fragment()
        sfb = warp.make_mxf4nvf4_sfb_fragment()
        warp.mma_unpack(tiled_mma, acc, (a, sfa, sfa), (b, sfb), acc)
        out_[0] = 0.0

    @cute.jit
    def _launch(out_: cute.Tensor):
        _bad(out_).launch(grid=[1, 1, 1], block=[32, 1, 1])

    with pytest.raises(TypeError):
        cute.compile(_launch, cute_out)


@pytest.mark.parametrize(
    ("kind", "expected"),
    [
        ("a", "a fragment"),
        ("b", "b fragment"),
        ("c", "c"),
        ("d", "d"),
    ],
)
def test_sm120_mxf4nvf4_mma_unpack_rejects_malformed_fragment_layout(kind, expected):
    _, out, cute_out = _cuda_out()

    @cute.kernel
    def _bad(out_: cute.Tensor):
        mma_op = warp.MmaMXF4NVF4Op(
            cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E4M3FN
        )
        tiled_mma = cute.make_tiled_mma(mma_op)
        good_a = cute.make_rmem_tensor(
            tiled_mma.partition_shape_A((16, 64)), cutlass.Float4E2M1FN
        )
        good_b = cute.make_rmem_tensor(
            tiled_mma.partition_shape_B((8, 64)), cutlass.Float4E2M1FN
        )
        good_acc = cute.make_rmem_tensor(
            tiled_mma.partition_shape_C((16, 8)), cutlass.Float32
        )
        bad_a = cute.make_rmem_tensor(cute.make_layout(16), cutlass.Float4E2M1FN)
        bad_b = cute.make_rmem_tensor(cute.make_layout(8), cutlass.Float4E2M1FN)
        bad_acc = cute.make_rmem_tensor(cute.make_layout(8), cutlass.Float32)
        sfa = warp.make_mxf4nvf4_sfa_fragment()
        sfb = warp.make_mxf4nvf4_sfb_fragment()
        a = bad_a if kind == "a" else good_a
        b = bad_b if kind == "b" else good_b
        d = bad_acc if kind == "d" else good_acc
        c = bad_acc if kind == "c" else good_acc
        warp.mma_unpack(tiled_mma, d, (a, sfa), (b, sfb), c)
        out_[0] = 0.0

    @cute.jit
    def _launch(out_: cute.Tensor):
        _bad(out_).launch(grid=[1, 1, 1], block=[32, 1, 1])

    with pytest.raises(ValueError, match=expected):
        cute.compile(_launch, cute_out)
