# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
from cutlass.cute.runtime import make_fake_compact_tensor


@cute.kernel
def _already_elected_tma_acquire_with_token_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    barrier_storage = cute.arch.alloc_smem(cutlass.Int64, 2, alignment=8)
    pipe = pipeline.PipelineTmaAsync.create(
        num_stages=1,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        tx_count=16,
        barrier_storage=barrier_storage,
        tidx=tidx,
        defer_sync=True,
    )
    state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Producer, 1)

    token = pipe.producer_try_acquire(state)
    with cute.arch.elect_one():
        pipe.producer_acquire_already_elected(state, token)

    if tidx == 0:
        out[0] = cutlass.Int32(0)


@cute.jit
def _launch_already_elected_tma_acquire_with_token(out: cute.Tensor):
    _already_elected_tma_acquire_with_token_kernel(out).launch(
        grid=[1, 1, 1], block=[32, 1, 1]
    )


@cute.kernel
def _already_elected_tma_acquire_kernel(out: cute.Tensor):
    tidx, _, _ = cute.arch.thread_idx()
    barrier_storage = cute.arch.alloc_smem(cutlass.Int64, 2, alignment=8)
    pipe = pipeline.PipelineTmaAsync.create(
        num_stages=1,
        producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
        tx_count=16,
        barrier_storage=barrier_storage,
        tidx=tidx,
        defer_sync=True,
    )
    state = pipeline.make_pipeline_state(pipeline.PipelineUserType.Producer, 1)

    with cute.arch.elect_one():
        pipe.producer_acquire_already_elected(state)

    if tidx == 0:
        out[0] = cutlass.Int32(0)


@cute.jit
def _launch_already_elected_tma_acquire(out: cute.Tensor):
    _already_elected_tma_acquire_kernel(out).launch(
        grid=[1, 1, 1], block=[32, 1, 1]
    )


def test_pipeline_tma_producer_acquire_already_elected_compiles():
    out = make_fake_compact_tensor(
        cutlass.Int32,
        (1,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )

    compiled = cute.compile(_launch_already_elected_tma_acquire, out, options="--keep-ptx")

    assert "mbarrier.try_wait" in compiled.__ptx__
    assert "mbarrier.arrive.expect_tx" in compiled.__ptx__


def test_pipeline_tma_producer_acquire_already_elected_with_token_compiles():
    out = make_fake_compact_tensor(
        cutlass.Int32,
        (1,),
        memspace=cute.AddressSpace.gmem,
        assumed_align=16,
    )

    compiled = cute.compile(
        _launch_already_elected_tma_acquire_with_token, out, options="--keep-ptx"
    )

    assert "mbarrier.try_wait" in compiled.__ptx__
    assert "mbarrier.arrive.expect_tx" in compiled.__ptx__
