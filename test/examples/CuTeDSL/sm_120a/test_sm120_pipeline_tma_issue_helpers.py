# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

import pytest

import cutlass
import cutlass.cute as cute
from cutlass import pipeline
from cutlass.cute.runtime import make_fake_compact_tensor


pytestmark = [pytest.mark.arch(["120a"])]


def _make_pipeline_kernel(rank, acquire_and_commit):
    @cute.kernel
    def _kernel(out: cute.Tensor):
        smem = cutlass.utils.SmemAllocator()
        smem_tensor = smem.allocate_tensor(
            cutlass.Uint8, cute.make_layout(2048), byte_alignment=128
        )
        barriers = smem.allocate_array(cutlass.Int64, 2, byte_alignment=8)
        desc = cute.make_ptr(cutlass.Int64, 0, cute.AddressSpace.gmem, assumed_align=64)
        pipe = pipeline.PipelineTmaWarpMma.create(
            num_stages=1,
            producer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread),
            consumer_group=pipeline.CooperativeGroup(pipeline.Agent.Thread, 1),
            tx_count=1024,
            barrier_storage=barriers,
        )
        producer_state = pipeline.make_pipeline_state(
            pipeline.PipelineUserType.Producer, 1
        )

        if rank == 3 and acquire_and_commit:
            pipeline.producer_acquire_issue_tma_load_3d(
                pipe,
                producer_state,
                None,
                smem_tensor.iterator,
                desc,
                0,
                0,
                0,
                already_elected=True,
            )
        elif rank == 3:
            pipeline.issue_tma_load_3d(
                pipe,
                producer_state,
                smem_tensor.iterator,
                desc,
                0,
                0,
                0,
                already_elected=True,
            )
        elif acquire_and_commit:
            pipeline.producer_acquire_issue_tma_load_4d(
                pipe,
                producer_state,
                None,
                smem_tensor.iterator,
                desc,
                0,
                0,
                0,
                0,
                already_elected=True,
            )
        else:
            pipeline.issue_tma_load_4d(
                pipe,
                producer_state,
                smem_tensor.iterator,
                desc,
                0,
                0,
                0,
                0,
                already_elected=True,
            )
        out[0] = 0

    @cute.jit
    def _launch(out: cute.Tensor):
        _kernel(out).launch(grid=[1, 1, 1], block=[32, 1, 1])

    return _launch


@pytest.mark.parametrize("rank", [3, 4])
@pytest.mark.parametrize("acquire_and_commit", [False, True])
def test_sm120_pipeline_tma_wrappers_compile(rank, acquire_and_commit):
    cute_out = make_fake_compact_tensor(cutlass.Int32, (1,), assumed_align=16)
    ptx = cute.compile(
        _make_pipeline_kernel(rank, acquire_and_commit),
        cute_out,
        options="--keep-ptx",
    ).__ptx__

    assert f"cp.async.bulk.tensor.{rank}d.shared::cta.global" in ptx
    assert "fence.proxy.tensormap::generic.acquire.gpu" in ptx
