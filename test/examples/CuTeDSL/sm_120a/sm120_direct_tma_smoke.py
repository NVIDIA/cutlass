# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import os

import torch

import cutlass
import cutlass.cute as cute
import cutlass.pipeline
import cutlass.utils
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.runtime import from_dlpack
from cutlass.pipeline.sm90 import PipelineTmaAsync, make_pipeline_state


_CACHE_HINT_EVICT_NORMAL = 0x1000000000000000


def _require_sm120():
    if not torch.cuda.is_available():
        raise RuntimeError("CUDA is required")
    if torch.cuda.get_device_capability()[0] < 12:
        raise RuntimeError("SM120 TMA smoke requires compute capability 12.x")
    os.environ.setdefault("CUTE_DSL_ARCH", "sm_120")


@cute.kernel
def _direct_basis_tma_kernel(
    tma_atom: cute.CopyAtom,
    dst: cute.Tensor,
    coord0: cutlass.Int32,
    coord1: cutlass.Int32,
    dtype: cutlass.Constexpr,
    d_tile: cutlass.Constexpr,
    seq_tile: cutlass.Constexpr,
    use_cache_hint: cutlass.Constexpr,
    tile_mode: cutlass.Constexpr,
    use_swizzle: cutlass.Constexpr,
):
    smem = cutlass.utils.SmemAllocator()
    smem_layout = cute.make_layout((d_tile, seq_tile), stride=(1, d_tile))
    if cutlass.const_expr(use_swizzle):
        s_tile = smem.allocate_tensor(
            dtype,
            smem_layout,
            byte_alignment=128,
            swizzle=cute.make_swizzle(3, 4, 3),
        )
    else:
        s_tile = smem.allocate_tensor(
            dtype,
            smem_layout,
            byte_alignment=128,
        )
    s_mbar = smem.allocate_tensor(
        cutlass.Int64, cute.make_layout(2), byte_alignment=8
    )

    tidx, _, _ = cute.arch.thread_idx()
    warp = tidx // 32
    lane = tidx % 32
    desc_ptr = cpasync.get_tma_desc_addr(tma_atom)
    pipe = PipelineTmaAsync.create(
        barrier_storage=s_mbar.iterator,
        num_stages=1,
        producer_group=cutlass.pipeline.CooperativeGroup(
            cutlass.pipeline.Agent.Thread, 1
        ),
        consumer_group=cutlass.pipeline.CooperativeGroup(
            cutlass.pipeline.Agent.Thread, 1
        ),
        tx_count=d_tile * seq_tile * dtype.width // 8,
        defer_sync=False,
    )

    if warp == 0:
        with cute.arch.elect_one():
            cpasync.fence_tma_desc_acquire(desc_ptr)

        producer_state = make_pipeline_state(
            cutlass.pipeline.PipelineUserType.Producer, 1
        )
        pipe.producer_acquire(producer_state)
        if use_cache_hint:
            cpasync.sm120_tma_load_2d(
                s_tile.iterator,
                desc_ptr,
                pipe.producer_get_barrier(producer_state),
                coord0,
                coord1,
                cache_policy=cutlass.Int64(_CACHE_HINT_EVICT_NORMAL),
                tile_mode=tile_mode,
            )
        else:
            cpasync.sm120_tma_load_2d(
                s_tile.iterator,
                desc_ptr,
                pipe.producer_get_barrier(producer_state),
                coord0,
                coord1,
                tile_mode=tile_mode,
            )
        producer_state.advance()
        pipe.producer_tail(producer_state)

    if warp == 1:
        consumer_state = make_pipeline_state(
            cutlass.pipeline.PipelineUserType.Consumer, 1
        )
        pipe.consumer_wait(consumer_state)
        cute.arch.fence_view_async_shared()
        pipe.consumer_release(consumer_state)

        # Row in direct TMA basis: d varies at fixed seq.
        dst[lane] = s_tile[lane, 0].to(cutlass.Float32)
        # Column in direct TMA basis: seq varies at fixed d.
        dst[32 + lane] = s_tile[0, lane].to(cutlass.Float32)


@cute.jit
def _launch_direct_basis_tma(
    src: cute.Tensor,
    dst: cute.Tensor,
    coord0: cutlass.Int32,
    coord1: cutlass.Int32,
    dtype: cutlass.Constexpr,
    d_total: cutlass.Constexpr,
    seq_total: cutlass.Constexpr,
    d_tile: cutlass.Constexpr,
    seq_tile: cutlass.Constexpr,
    use_cache_hint: cutlass.Constexpr,
    tile_mode: cutlass.Constexpr,
    use_swizzle: cutlass.Constexpr,
):
    gmem_tma = cute.make_tensor(
        src.iterator,
        cute.make_layout((d_total, seq_total), stride=(1, d_total)),
    )
    smem_layout = cute.make_layout((d_tile, seq_tile), stride=(1, d_tile))
    if cutlass.const_expr(use_swizzle):
        smem_layout = cute.make_composed_layout(
            cute.make_swizzle(3, 4, 3),
            0,
            smem_layout,
        )
    tma_atom, _, _ = cpasync.make_sm120_tma_load_2d_atom(
        gmem_tma,
        smem_layout,
        (d_tile, seq_tile),
    )
    smem_bytes = d_tile * seq_tile * dtype.width // 8 + 16
    _direct_basis_tma_kernel(
        tma_atom,
        dst,
        coord0,
        coord1,
        dtype,
        d_tile,
        seq_tile,
        use_cache_hint,
        tile_mode,
        use_swizzle,
    ).launch(grid=[1, 1, 1], block=[64, 1, 1], smem=smem_bytes)


def _make_source(seq_total: int, d_total: int, torch_dtype: torch.dtype):
    values = torch.empty((seq_total, d_total), device="cuda", dtype=torch.float32)
    seq = torch.arange(seq_total, device="cuda", dtype=torch.float32)[:, None]
    d = torch.arange(d_total, device="cuda", dtype=torch.float32)[None, :]
    values.copy_(seq * 100.0 + d)
    return values.to(torch_dtype)


def _run_direct_basis_case(
    dtype,
    torch_dtype,
    *,
    d_total=128,
    seq_total=128,
    d_tile=64,
    seq_tile=64,
    coord0=16,
    coord1=32,
    use_cache_hint=False,
    tile_mode=False,
    use_swizzle=False,
):
    src = _make_source(seq_total, d_total, torch_dtype)
    dst = torch.zeros(64, device="cuda", dtype=torch.float32)
    runtime_args = (
        from_dlpack(src),
        from_dlpack(dst),
        cutlass.Int32(coord0),
        cutlass.Int32(coord1),
    )
    args = (
        *runtime_args,
        dtype,
        d_total,
        seq_total,
        d_tile,
        seq_tile,
        use_cache_hint,
        tile_mode,
        use_swizzle,
    )
    cute.compile(_launch_direct_basis_tma, *args)(*runtime_args)
    torch.cuda.synchronize()

    src_f32 = src.to(torch.float32)
    expected_row = src_f32[coord1, coord0 : coord0 + 32]
    expected_col = src_f32[coord1 : coord1 + 32, coord0]
    assert torch.equal(dst[:32], expected_row)
    assert torch.equal(dst[32:], expected_col)


def _run_fa_like_kv_direct_basis_smoke(torch_dtype, dtype, d_tile, seq_tile):
    _require_sm120()
    # This is the K/V contract FlashAttention needs: GMEM is logically
    # (seq, d), but TMA sees direct basis (d, seq). Consumers can create a
    # logical shared-memory view after the load without changing TMA basis.
    _run_direct_basis_case(
        dtype,
        torch_dtype,
        d_total=128,
        seq_total=192,
        d_tile=d_tile,
        seq_tile=seq_tile,
        coord0=0,
        coord1=32,
    )


def _run_fa_like_kv_swizzled_smoke(torch_dtype, dtype, d_tile, seq_tile):
    _require_sm120()
    _run_direct_basis_case(
        dtype,
        torch_dtype,
        d_total=128,
        seq_total=192,
        d_tile=d_tile,
        seq_tile=seq_tile,
        coord0=16,
        coord1=32,
        use_swizzle=True,
    )


if __name__ == "__main__":
    _require_sm120()
    for dtype, torch_dtype in [
        (cutlass.Float32, torch.float32),
        (cutlass.BFloat16, torch.bfloat16),
    ]:
        for coord0, coord1 in [(0, 0), (16, 0), (0, 32), (16, 32)]:
            _run_direct_basis_case(
                dtype,
                torch_dtype,
                coord0=coord0,
                coord1=coord1,
            )

    _run_direct_basis_case(
        cutlass.Float32,
        torch.float32,
        use_cache_hint=True,
        tile_mode=True,
    )
    for torch_dtype, dtype in [
        (torch.float16, cutlass.Float16),
        (torch.bfloat16, cutlass.BFloat16),
    ]:
        for d_tile in [64, 96, 128]:
            for seq_tile in [64, 128]:
                _run_fa_like_kv_direct_basis_smoke(
                    torch_dtype, dtype, d_tile, seq_tile
                )
    for torch_dtype, dtype in [
        (torch.float16, cutlass.Float16),
        (torch.bfloat16, cutlass.BFloat16),
    ]:
        _run_fa_like_kv_swizzled_smoke(torch_dtype, dtype, 64, 64)
    print("SM120 direct TMA smoke passed")
