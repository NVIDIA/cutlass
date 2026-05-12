# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

from cutlass import pipeline
from cutlass.cute.nvgpu import cpasync
import cutlass.pipeline.sm120 as sm120_pipeline
from cutlass.pipeline.sm90 import PipelineTmaAsync


def test_sm120_tma_helpers_are_exported():
    assert cpasync.sm120_tma_load_2d is not None
    assert cpasync.sm120_tma_load_3d is not None
    assert cpasync.sm120_tma_load_4d is not None
    assert pipeline.PipelineTmaWarpMma is not None
    assert pipeline.issue_tma_load_3d is sm120_pipeline.issue_tma_load_3d
    assert pipeline.issue_tma_load_4d is sm120_pipeline.issue_tma_load_4d
    assert (
        pipeline.producer_acquire_issue_tma_load_3d
        is sm120_pipeline.producer_acquire_issue_tma_load_3d
    )
    assert (
        pipeline.producer_acquire_issue_tma_load_4d
        is sm120_pipeline.producer_acquire_issue_tma_load_4d
    )


def test_pipeline_tma_warp_mma_create_returns_wrapper(monkeypatch):
    base = object.__new__(PipelineTmaAsync)
    for name, value in (
        ("sync_object_full", object()),
        ("sync_object_empty", object()),
        ("num_stages", 2),
        ("producer_mask", None),
        ("consumer_mask", None),
        ("is_signalling_thread", True),
    ):
        object.__setattr__(base, name, value)

    monkeypatch.setattr(
        sm120_pipeline.PipelineTmaAsync,
        "create",
        staticmethod(lambda **kwargs: base),
    )

    pipe = sm120_pipeline.PipelineTmaWarpMma.create(
        num_stages=2,
        producer_group=object(),
        consumer_group=object(),
        tx_count=128,
        barrier_storage=object(),
    )

    assert isinstance(pipe, sm120_pipeline.PipelineTmaWarpMma)
    assert pipe.sync_object_full is base.sync_object_full
    assert pipe.sync_object_empty is base.sync_object_empty
    assert pipe.num_stages == 2
