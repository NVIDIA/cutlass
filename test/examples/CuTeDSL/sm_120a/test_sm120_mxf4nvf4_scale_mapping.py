# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import warp
from cutlass.cute.runtime import from_dlpack


pytestmark = [pytest.mark.arch(["120a"])]

_MXF4NVF4_MMA_PTX = (
    "mma.sync.aligned.m16n8k64.row.col.kind::mxf4nvf4.block_scale."
    "scale_vec::4X"
)


@cute.jit
def _make_full_k_tiled_mma():
    mma_op = warp.MmaMXF4NVF4Op(
        cutlass.Float4E2M1FN, cutlass.Float32, cutlass.Float8E4M3FN
    )
    return cute.make_tiled_mma(
        mma_op,
        atom_layout_mnk=cute.make_layout((4, 2, 1), stride=(1, 4, 0)),
        permutation_mnk=(
            128,
            cute.make_layout((8, 2, 2), stride=(1, 16, 8)),
            64,
        ),
    )


@cute.jit
def _make_sfa_fragment():
    return cute.make_rmem_tensor(
        cute.make_layout(((16, 4), 2, 2), stride=((0, 1), 4, 8)),
        cutlass.Float8E4M3FN,
    )


@cute.jit
def _make_sfb_fragment():
    return cute.make_rmem_tensor(
        cute.make_layout(((16, 4), 8, 2), stride=((0, 1), 4, 32)),
        cutlass.Float8E4M3FN,
    )


@cute.jit
def _store_accumulator(thr_mma: cute.ThrMma, acc: cute.Tensor, out: cute.Tensor):
    tDgD = thr_mma.partition_C(out)
    rD = cute.make_rmem_tensor(acc.layout, out.element_type)
    rD.store(acc.load().to(out.element_type))
    copy_atom = cute.make_copy_atom(cute.nvgpu.CopyUniversalOp(), out.element_type)
    cute.copy(copy_atom, rD, tDgD)


@cute.jit
def _fill_sfa_k64_split(sfa: cute.Tensor):
    sfa.fill(1.0)
    for major in cutlass.range_constexpr(2):
        for scale_col in cutlass.range_constexpr(4):
            for row in cutlass.range_constexpr(16):
                sfa[((row, scale_col), major, 1)] = cutlass.Float8E4M3FN(2.0)


@cute.jit
def _fill_row_col_k64_scales(sfa: cute.Tensor, sfb: cute.Tensor):
    for major in cutlass.range_constexpr(2):
        for k_tile in cutlass.range_constexpr(2):
            sfa_value = 1 << (major + k_tile)
            for scale_col in cutlass.range_constexpr(4):
                for row in cutlass.range_constexpr(16):
                    sfa[((row, scale_col), major, k_tile)] = cutlass.Float8E4M3FN(
                        sfa_value
                    )

    for major in cutlass.range_constexpr(8):
        for k_tile in cutlass.range_constexpr(2):
            sfb_value = 1 << k_tile
            if major >= 4:
                sfb_value = 4 << k_tile
            for scale_col in cutlass.range_constexpr(4):
                for row in cutlass.range_constexpr(16):
                    sfb[((row, scale_col), major, k_tile)] = cutlass.Float8E4M3FN(
                        sfb_value
                    )


@cute.jit
def _fill_one_logical_scale_column(
    sfa: cute.Tensor,
    sfb: cute.Tensor,
    selected_scale_col: cutlass.Constexpr[int],
):
    sfa.fill(0.0)
    sfb.fill(0.0)
    selected_k_tile = selected_scale_col // 4
    selected_col = selected_scale_col % 4
    sfa_base = 1 << selected_scale_col
    sfb_base = 1 << ((selected_scale_col + 1) % 4)

    for major in cutlass.range_constexpr(2):
        sfa_value = sfa_base
        if major != 0:
            sfa_value = 2 * sfa_base
        for row in cutlass.range_constexpr(16):
            sfa[((row, selected_col), major, selected_k_tile)] = (
                cutlass.Float8E4M3FN(sfa_value)
            )

    for major in cutlass.range_constexpr(8):
        sfb_value = sfb_base
        if major >= 4:
            sfb_value = 4 * sfb_base
        for row in cutlass.range_constexpr(16):
            sfb[((row, selected_col), major, selected_k_tile)] = (
                cutlass.Float8E4M3FN(sfb_value)
            )


@cute.kernel
def _full_k_distinct_c_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    tiled_mma = _make_full_k_tiled_mma()
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((128, 128)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((128, 128)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(
        tiled_mma.partition_shape_C((128, 128)), cutlass.Float32
    )
    c = cute.make_rmem_tensor(tiled_mma.partition_shape_C((128, 128)), cutlass.Float32)
    sfa = _make_sfa_fragment()
    sfb = _make_sfb_fragment()

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    c.fill(7.0)
    sfa.fill(1.0)
    sfb.fill(1.0)
    cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), c)

    thr_mma = tiled_mma.get_slice(tidx)
    _store_accumulator(thr_mma, acc, out)


@cute.kernel
def _two_k64_scale_columns_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    tiled_mma = _make_full_k_tiled_mma()
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((128, 128)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((128, 128)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(
        tiled_mma.partition_shape_C((128, 128)), cutlass.Float32
    )
    sfa = _make_sfa_fragment()
    sfb = _make_sfb_fragment()

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    _fill_sfa_k64_split(sfa)
    sfb.fill(1.0)
    cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    thr_mma = tiled_mma.get_slice(tidx)
    _store_accumulator(thr_mma, acc, out)


@cute.kernel
def _row_col_k64_scale_mapping_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    tiled_mma = _make_full_k_tiled_mma()
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((128, 128)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((128, 128)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(
        tiled_mma.partition_shape_C((128, 128)), cutlass.Float32
    )
    sfa = _make_sfa_fragment()
    sfb = _make_sfb_fragment()

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    _fill_row_col_k64_scales(sfa, sfb)
    cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    thr_mma = tiled_mma.get_slice(tidx)
    _store_accumulator(thr_mma, acc, out)


@cute.kernel
def _per_scale_column_mapping_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    tiled_mma = _make_full_k_tiled_mma()
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((128, 128)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((128, 128)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(
        tiled_mma.partition_shape_C((128, 128)), cutlass.Float32
    )
    sfa = _make_sfa_fragment()
    sfb = _make_sfb_fragment()

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    thr_mma = tiled_mma.get_slice(tidx)

    for selected_scale_col in cutlass.range_constexpr(8):
        acc.fill(0.0)
        _fill_one_logical_scale_column(sfa, sfb, selected_scale_col)
        cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)
        _store_accumulator(thr_mma, acc, out[(selected_scale_col, None, None)])
        cute.arch.sync_threads()


@cute.kernel
def _row_varying_sfa_mapping_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    tiled_mma = _make_full_k_tiled_mma()
    a = cute.make_rmem_tensor(
        tiled_mma.partition_shape_A((128, 128)), cutlass.Float4E2M1FN
    )
    b = cute.make_rmem_tensor(
        tiled_mma.partition_shape_B((128, 128)), cutlass.Float4E2M1FN
    )
    acc = cute.make_rmem_tensor(
        tiled_mma.partition_shape_C((128, 128)), cutlass.Float32
    )
    sfa = _make_sfa_fragment()
    sfb = _make_sfb_fragment()

    cute.recast_tensor(a, cutlass.Int32).fill(0x22222222)
    cute.recast_tensor(b, cutlass.Int32).fill(0x22222222)
    acc.fill(0.0)
    sfa.fill(1.0)
    row_mod = (tidx // 4) % 4
    if row_mod == 1:
        sfa.fill(2.0)
    if row_mod == 2:
        sfa.fill(3.0)
    if row_mod == 3:
        sfa.fill(4.0)
    sfb.fill(1.0)
    cute.gemm(tiled_mma, acc, (a, sfa), (b, sfb), acc)

    thr_mma = tiled_mma.get_slice(tidx)
    _store_accumulator(thr_mma, acc, out)


@cute.jit
def _launch_full_k_distinct_c(out: cute.Tensor):
    _full_k_distinct_c_kernel(out).launch(grid=[1, 1, 1], block=[256, 1, 1])


@cute.jit
def _launch_two_k64_scale_columns(out: cute.Tensor):
    _two_k64_scale_columns_kernel(out).launch(grid=[1, 1, 1], block=[256, 1, 1])


@cute.jit
def _launch_row_col_k64_scale_mapping(out: cute.Tensor):
    _row_col_k64_scale_mapping_kernel(out).launch(
        grid=[1, 1, 1], block=[256, 1, 1]
    )


@cute.jit
def _launch_per_scale_column_mapping(out: cute.Tensor):
    _per_scale_column_mapping_kernel(out).launch(grid=[1, 1, 1], block=[256, 1, 1])


@cute.jit
def _launch_row_varying_sfa_mapping(out: cute.Tensor):
    _row_varying_sfa_mapping_kernel(out).launch(grid=[1, 1, 1], block=[256, 1, 1])


def _cuda_out(*shape):
    torch = pytest.importorskip("torch")
    if not torch.cuda.is_available():
        pytest.skip("CUDA device unavailable")
    out = torch.empty(shape, device="cuda", dtype=torch.float32)
    return torch, out, from_dlpack(out, enable_tvm_ffi=True)


def _compile(fn, *args):
    compiled = cute.compile(fn, *args, options="--keep-ptx")
    assert compiled.__ptx__.count(_MXF4NVF4_MMA_PTX) >= 2
    return compiled


def test_sm120_mxf4nvf4_scale_mapping_uses_both_k64_halves():
    torch, out, cute_out = _cuda_out(128, 128)
    _compile(_launch_two_k64_scale_columns, cute_out)(cute_out)
    torch.cuda.synchronize()
    torch.testing.assert_close(out, torch.full_like(out, 192.0), rtol=0, atol=0)


def test_sm120_mxf4nvf4_full_k_distinct_d_and_c_accumulates_across_k():
    torch, out, cute_out = _cuda_out(128, 128)
    _compile(_launch_full_k_distinct_c, cute_out)(cute_out)
    torch.cuda.synchronize()
    torch.testing.assert_close(out, torch.full_like(out, 135.0), rtol=0, atol=0)


def test_sm120_mxf4nvf4_scale_mapping_covers_row_col_and_k64():
    torch, out, cute_out = _cuda_out(128, 128)
    _compile(_launch_row_col_k64_scale_mapping, cute_out)(cute_out)
    torch.cuda.synchronize()

    expected = torch.empty_like(out)
    expected[:64, :64] = 320.0
    expected[:64, 64:] = 1280.0
    expected[64:, :64] = 640.0
    expected[64:, 64:] = 2560.0
    torch.testing.assert_close(out, expected, rtol=0, atol=0)


def test_sm120_mxf4nvf4_scale_mapping_covers_each_logical_scale_column():
    torch, out, cute_out = _cuda_out(8, 128, 128)
    _compile(_launch_per_scale_column_mapping, cute_out)(cute_out)
    torch.cuda.synchronize()

    expected = torch.empty_like(out)
    for scale_col in range(8):
        sfa_value = 1 << scale_col
        sfb_value = 1 << ((scale_col + 1) % 4)
        expected[scale_col, :64, :64] = 16.0 * sfa_value * sfb_value
        expected[scale_col, :64, 64:] = 64.0 * sfa_value * sfb_value
        expected[scale_col, 64:, :64] = 32.0 * sfa_value * sfb_value
        expected[scale_col, 64:, 64:] = 128.0 * sfa_value * sfb_value
    torch.testing.assert_close(out, expected, rtol=0, atol=0)


def test_sm120_mxf4nvf4_scale_mapping_covers_row_varying_sfa():
    torch, out, cute_out = _cuda_out(128, 128)
    _compile(_launch_row_varying_sfa_mapping, cute_out)(cute_out)
    torch.cuda.synchronize()

    row_values = (torch.arange(128, device="cuda") % 4 + 1).to(torch.float32) * 128.0
    expected = row_values[:, None].expand_as(out)
    torch.testing.assert_close(out, expected, rtol=0, atol=0)
