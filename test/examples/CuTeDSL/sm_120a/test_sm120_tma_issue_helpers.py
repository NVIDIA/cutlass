# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest

import cutlass
import cutlass.cute as cute
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import make_fake_compact_tensor


pytestmark = [pytest.mark.arch(["120a"])]


def _make_kernel(
    rank,
    tile_mode,
    cache_hint,
    already_elected=True,
    desc_space=cute.AddressSpace.gmem,
):
    @cute.kernel
    def _kernel(out: cute.Tensor):
        dst = cute.make_ptr(cutlass.Int32, 0, cute.AddressSpace.smem, assumed_align=16)
        desc = cute.make_ptr(cutlass.Int64, 0, desc_space, assumed_align=64)
        bar = cute.make_ptr(cutlass.Int64, 0, cute.AddressSpace.smem, assumed_align=8)
        if rank == 2:
            cpasync.sm120_tma_load_2d(
                dst,
                desc,
                bar,
                0,
                0,
                cache_policy=0 if cache_hint else None,
                already_elected=already_elected,
                tile_mode=tile_mode,
            )
        elif rank == 3:
            cpasync.sm120_tma_load_3d(
                dst,
                desc,
                bar,
                0,
                0,
                0,
                cache_policy=0 if cache_hint else None,
                already_elected=already_elected,
                tile_mode=tile_mode,
            )
        else:
            cpasync.sm120_tma_load_4d(
                dst,
                desc,
                bar,
                0,
                0,
                0,
                0,
                cache_policy=0 if cache_hint else None,
                already_elected=already_elected,
                tile_mode=tile_mode,
            )
        out[0] = 0

    @cute.jit
    def _launch(out: cute.Tensor):
        _kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])

    return _launch


def _compile_ptx(host_fn) -> str:
    cute_out = make_fake_compact_tensor(cutlass.Int32, (1,), assumed_align=16)
    compiled = cute.compile(host_fn, cute_out, options="--keep-ptx")
    return compiled.__ptx__


@pytest.mark.parametrize(
    ("rank", "tile_mode", "cache_hint", "expected"),
    [
        (
            2,
            False,
            False,
            "cp.async.bulk.tensor.2d.shared::cta.global.mbarrier::complete_tx::bytes",
        ),
        (
            2,
            True,
            True,
            "cp.async.bulk.tensor.2d.shared::cta.global.tile.mbarrier::complete_tx::bytes.L2::cache_hint",
        ),
        (
            3,
            False,
            False,
            "cp.async.bulk.tensor.3d.shared::cta.global.mbarrier::complete_tx::bytes",
        ),
        (
            3,
            True,
            True,
            "cp.async.bulk.tensor.3d.shared::cta.global.tile.mbarrier::complete_tx::bytes.L2::cache_hint",
        ),
        (
            4,
            False,
            False,
            "cp.async.bulk.tensor.4d.shared::cta.global.mbarrier::complete_tx::bytes",
        ),
        (
            4,
            True,
            True,
            "cp.async.bulk.tensor.4d.shared::cta.global.tile.mbarrier::complete_tx::bytes.L2::cache_hint",
        ),
    ],
)
def test_sm120_tma_issue_helper_ptx(rank, tile_mode, cache_hint, expected):
    ptx = _compile_ptx(_make_kernel(rank, tile_mode, cache_hint))
    tma_lines = [line.strip() for line in ptx.splitlines() if "cp.async.bulk.tensor" in line]

    assert len(tma_lines) == 1
    assert expected in tma_lines[0]
    assert "shared::cluster" not in tma_lines[0]
    assert ".cta_group" not in tma_lines[0]
    assert "multicast" not in tma_lines[0]


def test_sm120_tma_issue_helper_election_control():
    elected_ptx = _compile_ptx(_make_kernel(3, False, False, already_elected=True))
    non_elected_ptx = _compile_ptx(
        _make_kernel(3, False, False, already_elected=False)
    )

    assert "elect.sync" not in elected_ptx
    assert "elect.sync" in non_elected_ptx


def test_sm120_tma_issue_helper_accepts_generic_descriptor_pointer():
    ptx = _compile_ptx(
        _make_kernel(3, False, False, desc_space=cute.AddressSpace.generic)
    )

    assert "cp.async.bulk.tensor.3d.shared::cta.global" in ptx


def _make_bad_address_space_kernel(kind):
    @cute.kernel
    def _kernel(out: cute.Tensor):
        dst_space = cute.AddressSpace.gmem if kind == "dst" else cute.AddressSpace.smem
        desc_space = (
            cute.AddressSpace.smem if kind == "desc" else cute.AddressSpace.gmem
        )
        bar_space = cute.AddressSpace.gmem if kind == "bar" else cute.AddressSpace.smem
        dst = cute.make_ptr(cutlass.Int32, 0, dst_space, assumed_align=16)
        desc = cute.make_ptr(cutlass.Int64, 0, desc_space, assumed_align=64)
        bar = cute.make_ptr(cutlass.Int64, 0, bar_space, assumed_align=8)
        cpasync.sm120_tma_load_3d(dst, desc, bar, 0, 0, 0, already_elected=True)
        out[0] = 0

    @cute.jit
    def _launch(out: cute.Tensor):
        _kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])

    return _launch


@pytest.mark.parametrize("kind", ["dst", "desc", "bar"])
def test_sm120_tma_issue_helper_rejects_wrong_address_space(kind):
    cute_out = make_fake_compact_tensor(cutlass.Int32, (1,), assumed_align=16)
    with pytest.raises(ValueError):
        cute.compile(_make_bad_address_space_kernel(kind), cute_out)


def test_sm120_tma_issue_helper_rejects_wrong_coordinate_count():
    @cute.kernel
    def _kernel(out: cute.Tensor):
        dst = cute.make_ptr(cutlass.Int32, 0, cute.AddressSpace.smem, assumed_align=16)
        desc = cute.make_ptr(cutlass.Int64, 0, cute.AddressSpace.gmem, assumed_align=64)
        bar = cute.make_ptr(cutlass.Int64, 0, cute.AddressSpace.smem, assumed_align=8)
        cpasync.sm120_tma_load_3d(dst, desc, bar, 0, 0, already_elected=True)
        out[0] = 0

    @cute.jit
    def _launch(out: cute.Tensor):
        _kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])

    cute_out = make_fake_compact_tensor(cutlass.Int32, (1,), assumed_align=16)
    with pytest.raises(TypeError):
        cute.compile(_launch, cute_out)
