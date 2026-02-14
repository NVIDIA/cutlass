# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

from cutlass.cutlass_dsl import dsl_user_op
from cutlass._mlir.dialects import lir as cutlass_lir_ir, nvvm as _nvvm
from cutlass._mlir import ir
from cutlass.cutlass_dsl import lru_cache_ir
from cutlass._mlir.dialects.core import OperationTypeEnum
from cutlass import cute


@dsl_user_op
def elect_sync(loc=None, ip=None):
    """
    Elects one predicated thread within a warp.
    """
    return _nvvm.elect_sync(loc=loc, ip=ip)


@dsl_user_op
def get_mbarrier(stage_token, loc=None, ip=None):
    """
    Returns the mbarrier pointer for a given stage token.
    """
    return cutlass_lir_ir.GetMbarrierOp(stage_token, loc=loc, ip=ip)


@ir.register_value_caster(cutlass_lir_ir.PipelineStateType.get_static_typeid())
class PipelineState(ir.Value):
    def __init__(self, value):
        if isinstance(value, ir.Value):
            self.value = value
        else:
            raise TypeError(f"Expected ir.Value, got {type(value)}")
        super().__init__(value)

    @property
    @lru_cache_ir()
    def type(self) -> ir.Type:
        return self.value.type

    @classmethod
    def __new_from_mlir_values__(cls, values):
        assert len(values) == 1, f"Expected 1 value, but got {len(values)}"
        return PipelineState(values[0])


@dsl_user_op
def create_pipeline(
    stage: cute.Int32,
    producer: OperationTypeEnum,
    consumer: OperationTypeEnum,
    producer_arv_count: cute.Int32,
    consumer_arv_count: cute.Int32,
    loc=None,
    ip=None,
) -> tuple[PipelineState, PipelineState, PipelineState]:
    """
    Creates an abstraction for a circular buffer of synchronizatoin primitives
    indexed by stage count.

    :param stage: Stage count
    :type stage: cute.Int32
    :param producer: Producer operation type
    :type producer: OperationTypeEnum
    :param consumer: Consumer operation type
    :type consumer: OperationTypeEnum
    :param producer_arv_count: Producer arrival count
    :type producer_arv_count: cute.Int32
    :param consumer_arv_count: Consumer arrival count
    :type consumer_arv_count: cute.Int32
    """
    if isinstance(producer_arv_count, int):
        producer_arv_count = cute.Int32(producer_arv_count)
    if isinstance(consumer_arv_count, int):
        consumer_arv_count = cute.Int32(consumer_arv_count)
    result = ir.Type.parse(f"!lir.pipeline<{stage}, {producer} -> {consumer}>")
    op = cutlass_lir_ir.CreatePipelineOp(
        result,
        producer_arv_count.ir_value(),
        consumer_arv_count.ir_value(),
        loc=loc,
        ip=ip,
    )
    pipeline = op.result

    result = ir.Type.parse(f"!lir.pipeline_state<{stage}>")
    op = cutlass_lir_ir.CreatePipelineStateOp(result, pipeline, loc=loc, ip=ip)
    producer_state = op.result

    result = ir.Type.parse(f"!lir.pipeline_state<{stage}>")
    op = cutlass_lir_ir.CreatePipelineStateOp(result, pipeline, loc=loc, ip=ip)
    consumer_state = op.result

    return pipeline, producer_state, consumer_state


@dsl_user_op
def create_pipeline_with_mask(
    stage: cute.Int32,
    producer: OperationTypeEnum,
    consumer: OperationTypeEnum,
    producer_arv_count: cute.Int32,
    consumer_arv_count: cute.Int32,
    arrival_mask: cute.Int16,
    loc=None,
    ip=None,
) -> tuple[PipelineState, PipelineState, PipelineState]:
    """
    Creates a pipeline with an arrival mask for cluster-scoped synchronization.

    :param stage: Pipeline stage count.
    :param producer: Producer operation type (e.g. SM90_TMA_LOAD_MULTICAST).
    :param consumer: Consumer operation type (e.g. SM100_MMA_2SM_SS).
    :param producer_arv_count: Producer arrival count for the pipeline barriers.
    :param consumer_arv_count: Consumer arrival count for the pipeline barriers.
    :param arrival_mask: Bitmask that selects participating peers (e.g. CTAs in a
        cluster). This is attached to the pipeline value and is consulted by some
        pipeline lowerings to generate cluster-scoped synchronization
    """
    if isinstance(producer_arv_count, int):
        producer_arv_count = cute.Int32(producer_arv_count)
    if isinstance(consumer_arv_count, int):
        consumer_arv_count = cute.Int32(consumer_arv_count)
    if isinstance(arrival_mask, int):
        arrival_mask = cute.Int16(arrival_mask)

    result = ir.Type.parse(f"!lir.pipeline<{stage}, {producer} -> {consumer}>")
    op = cutlass_lir_ir.CreatePipelineWithMaskOp(
        result,
        producer_arv_count.ir_value(),
        consumer_arv_count.ir_value(),
        arrival_mask.ir_value(),
        loc=loc,
        ip=ip,
    )
    pipeline = op.result

    result = ir.Type.parse(f"!lir.pipeline_state<{stage}>")
    op = cutlass_lir_ir.CreatePipelineStateOp(result, pipeline, loc=loc, ip=ip)
    producer_state = op.result

    result = ir.Type.parse(f"!lir.pipeline_state<{stage}>")
    op = cutlass_lir_ir.CreatePipelineStateOp(result, pipeline, loc=loc, ip=ip)
    consumer_state = op.result

    return pipeline, producer_state, consumer_state



@dsl_user_op
def pipeline_advance_iterator(pipe, state, loc=None, ip=None):
    """
    Advances a pipeline iterator to the next stage.
    """
    op = cutlass_lir_ir.PipelineAdvanceIteratorOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def producer_acquire(pipe, state, loc=None, ip=None):
    """
    Acquires exclusive access to a pipeline.
    """
    op = cutlass_lir_ir.ProducerAcquireOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def producer_commit(pipe, state, loc=None, ip=None):
    """
    Commits results to a pipeline.
    """
    op = cutlass_lir_ir.ProducerCommitOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def consumer_wait(pipe, state, loc=None, ip=None):
    """
    Waits for a pipeline to transition to `full`.
    """
    op = cutlass_lir_ir.ConsumerWaitOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def consumer_release(pipe, state, loc=None, ip=None):
    """
    Releases a pipeline that has been consumed.
    """
    op = cutlass_lir_ir.ConsumerReleaseOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def consumer_tail(pipe, state, loc=None, ip=None):
    """
    Called by the consumer to block until asynchronous tasks have completed.
    """
    op = cutlass_lir_ir.ConsumerTailOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def get_pipeline_produce_stage(pipeline, state, loc=None, ip=None):
    """
    Gets a pipeline produce stage.
    """
    stage_token_type = ir.Type.parse(f"!lir.stage_token<{pipeline.type}>")
    stage_idx = ir.IntegerType.get_signless(32)
    op = cutlass_lir_ir.GetPipelineProduceStageOp(
        stage_token=stage_token_type,
        stage_index=stage_idx,
        pipeline=pipeline,
        pipelineState=state,
        loc=loc,
        ip=ip,
    )
    return op.stage_token, op.stage_index


@dsl_user_op
def get_pipeline_consume_stage(pipeline, state, loc=None, ip=None):
    """
    Creates a pipeline consume stage.
    """
    stage_token_type = ir.Type.parse(f"!lir.stage_token<{pipeline.type}>")
    stage_idx = ir.IntegerType.get_signless(32)
    op = cutlass_lir_ir.GetPipelineConsumeStageOp(
        stage_token=stage_token_type,
        stage_index=stage_idx,
        pipeline=pipeline,
        pipelineState=state,
        loc=loc,
        ip=ip,
    )
    return op.stage_token, op.stage_index
