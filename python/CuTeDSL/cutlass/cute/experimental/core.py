# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from typing import Optional, Protocol, TypeAlias

from cutlass.cutlass_dsl import dsl_user_op
from cutlass._mlir.dialects import lir as cutlass_lir_ir, nvvm as _nvvm
from cutlass._mlir import ir
from cutlass.cutlass_dsl import lru_cache_ir
from cutlass._mlir.dialects.core import OperationTypeEnum
from cutlass import cute
from cutlass.cute.typing import Boolean


class _SupportsIrValue(Protocol):
    def ir_value(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> ir.Value: ...


SkipWaitToken: TypeAlias = bool | ir.Value | _SupportsIrValue


@dsl_user_op
def elect_sync(
    loc: Optional[ir.Location] = None, ip: Optional[ir.InsertionPoint] = None
) -> ir.Value:
    return _nvvm.elect_sync(loc=loc, ip=ip)


@dsl_user_op
def get_mbarrier(
    stage_token: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Returns the mbarrier pointer for a given stage token.
    """
    return cutlass_lir_ir.GetMbarrierOp(stage_token, loc=loc, ip=ip)


@ir.register_value_caster(cutlass_lir_ir.PipelineStateType.get_static_typeid())
class PipelineState(ir.Value):
    def __init__(self, value: ir.Value) -> None:
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
    def __new_from_mlir_values__(cls, values: list[ir.Value]) -> "PipelineState":
        assert len(values) == 1, f"Expected 1 value, but got {len(values)}"
        return PipelineState(values[0])


def _normalize_create_pipeline_arrival_mask(
    arrival_mask: Optional[cute.Int16],
    compat_kwargs: dict[str, object],
) -> Optional[cute.Int16]:
    # Legacy source compatibility: older callers used `multicast` as the sixth
    # argument. Keep `False` working, but force `True` callers onto the explicit
    # mask APIs because the legacy path produced incorrect IR.
    # Remove this shim once the team is comfortable breaking low-level
    # create_pipeline() callers and dropping the legacy multicast spelling.
    multicast = compat_kwargs.pop("multicast", None)
    if compat_kwargs:
        unexpected_arg = next(iter(compat_kwargs))
        raise TypeError(
            f"create_pipeline() got an unexpected keyword argument '{unexpected_arg}'"
        )

    if multicast is not None:
        if not isinstance(multicast, bool):
            raise TypeError(f"Expected `multicast` to be a bool, got {type(multicast)}")
        if arrival_mask is not None:
            raise ValueError(
                "create_pipeline() does not accept both `arrival_mask` and legacy `multicast`."
            )
        if multicast:
            raise ValueError(
                "create_pipeline(multicast=True) is no longer supported; "
                "use create_pipeline(..., arrival_mask=...) or "
                "create_pipeline_with_mask(...)."
            )
        return None

    if isinstance(arrival_mask, bool):
        if arrival_mask:
            raise ValueError(
                "create_pipeline(True) no longer supports the legacy multicast "
                "form; use create_pipeline(..., arrival_mask=...) or "
                "create_pipeline_with_mask(...)."
            )
        return None

    return arrival_mask


def _build_pipeline(
    stage: cute.Int32,
    producer: OperationTypeEnum,
    consumer: OperationTypeEnum,
    producer_arv_count: cute.Int32,
    consumer_arv_count: cute.Int32,
    arrival_mask: Optional[cute.Int16],
    loc: Optional[ir.Location],
    ip: Optional[ir.InsertionPoint],
) -> tuple[PipelineState, PipelineState, PipelineState]:
    if isinstance(producer_arv_count, int):
        producer_arv_count = cute.Int32(producer_arv_count)
    if isinstance(consumer_arv_count, int):
        consumer_arv_count = cute.Int32(consumer_arv_count)

    if arrival_mask is not None:
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
    else:
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
def create_pipeline(
    stage: cute.Int32,
    producer: OperationTypeEnum,
    consumer: OperationTypeEnum,
    producer_arv_count: cute.Int32,
    consumer_arv_count: cute.Int32,
    arrival_mask: Optional[cute.Int16] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
    **compat_kwargs: object,
) -> tuple[PipelineState, PipelineState, PipelineState]:
    """
    Creates an abstraction for a circular buffer of synchronization primitives
    indexed by stage count.

    Args:
        stage: Number of pipeline stages.
        producer: Producer operation type.
        consumer: Consumer operation type.
        producer_arv_count: Number of producer arrivals.
        consumer_arv_count: Number of consumer arrivals.
        arrival_mask: Optional arrival mask for multi-CTA synchronization
            (2SM or multicast). When provided, creates the pipeline with
            explicit mask-based barrier configuration.
    """
    arrival_mask = _normalize_create_pipeline_arrival_mask(arrival_mask, compat_kwargs)
    return _build_pipeline(
        stage,
        producer,
        consumer,
        producer_arv_count,
        consumer_arv_count,
        arrival_mask,
        loc,
        ip,
    )


@dsl_user_op
def create_pipeline_with_mask(
    stage: cute.Int32,
    producer: OperationTypeEnum,
    consumer: OperationTypeEnum,
    producer_arv_count: cute.Int32,
    consumer_arv_count: cute.Int32,
    arrival_mask: cute.Int16,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[PipelineState, PipelineState, PipelineState]:
    """Backward-compatible wrapper. Prefer create_pipeline(..., arrival_mask=...)."""
    return _build_pipeline(
        stage,
        producer,
        consumer,
        producer_arv_count,
        consumer_arv_count,
        arrival_mask,
        loc,
        ip,
    )


@dsl_user_op
def pipeline_advance_iterator(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Advances a pipeline iterator to the next stage.
    """
    op = cutlass_lir_ir.PipelineAdvanceIteratorOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def producer_acquire(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Acquires exclusive access to a pipeline.
    """
    op = cutlass_lir_ir.ProducerAcquireOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def producer_commit(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Commits results to a pipeline.
    """
    op = cutlass_lir_ir.ProducerCommitOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def consumer_wait(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Waits for a pipeline to transition to `full`.
    """
    op = cutlass_lir_ir.ConsumerWaitOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def consumer_release(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Releases a pipeline that has been consumed.
    """
    op = cutlass_lir_ir.ConsumerReleaseOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def consumer_release_elect_one_sync(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Releases a pipeline that has been consumed.
    """
    op = cutlass_lir_ir.ConsumerReleaseOp(
        pipe, state, elect_one_sync=True, loc=loc, ip=ip
    )
    return op.result


@dsl_user_op
def consumer_tail(
    pipe: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> ir.Value:
    """
    Called by the consumer to block until asynchronous tasks have completed.
    """
    op = cutlass_lir_ir.ConsumerTailOp(pipe, state, loc=loc, ip=ip)
    return op.result


@dsl_user_op
def get_pipeline_produce_stage(
    pipeline: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[ir.Value, ir.Value]:
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
def get_pipeline_consume_stage(
    pipeline: ir.Value,
    state: ir.Value,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> tuple[ir.Value, ir.Value]:
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


@ir.register_value_caster(
    cutlass_lir_ir.CircularBufferPipelineStateType.get_static_typeid()
)
class CircularBufferPipelineState(ir.Value):
    def __init__(self, value: ir.Value) -> None:
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
    def __new_from_mlir_values__(
        cls, values: list[ir.Value]
    ) -> "CircularBufferPipelineState":
        assert len(values) == 1, f"Expected 1 value, but got {len(values)}"
        return CircularBufferPipelineState(values[0])


@dsl_user_op
def create_circular_buffer_pipeline(
    pipeline: ir.Value,
    pipeline_state: PipelineState,
    stages: int,
    count_per_stage: int,
    count_per_iteration: int,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> CircularBufferPipelineState:
    """
    Creates a circular buffer abstraction layered on top of a lir.pipeline.

    Each pipeline stage is subdivided into `count_per_stage` units.
    Operations can advance the circular buffer position by `count_per_iteration` units
    at a time in a FIFO manner. The abstraction provides synchronized access to
    pipeline stages given the circular buffer position.

    Args:
        pipeline: The underlying pipeline object
        pipeline_state: Initial pipeline state
        stages: Number of pipeline stages
        count_per_stage: Number of units per pipeline stage
        count_per_iteration: Number of units per iteration (chunk size)
        loc: Source location
        ip: Insertion point

    Returns:
        CircularBufferPipelineState: The circular buffer pipeline state
    """
    result_type = ir.Type.parse(
        f"!lir.circular_buffer_pipeline_state<{stages}, {count_per_stage}, {count_per_iteration}>"
    )
    op = cutlass_lir_ir.CreateCircularBufferPipelineOp(
        result_type,
        pipeline,
        pipeline_state,
        loc=loc,
        ip=ip,
    )
    return op.result


@dsl_user_op
def circular_buffer_pipeline_consume(
    pipeline: ir.Value,
    circular_buffer_pipeline_state: CircularBufferPipelineState,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Synchronize pipeline stages needed for circular buffer consumption.

    This operation performs synchronization for the circular buffer consumer.
    Based on the current circular buffer position and `count_per_iteration`, it
    determines which pipeline stages need to be synchronized and waits for them
    to transition to full before consumption can proceed.

    Args:
        pipeline: The underlying pipeline object
        circular_buffer_pipeline_state: Current circular buffer pipeline state
        loc: Source location
        ip: Insertion point
    """
    cutlass_lir_ir.CircularBufferPipelineConsumeOp(
        pipeline,
        circular_buffer_pipeline_state,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def circular_buffer_pipeline_consumer_release(
    pipeline: ir.Value,
    circular_buffer_pipeline_state: CircularBufferPipelineState,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Release pipeline stages after circular buffer consumption.

    This operation releases pipeline stages after circular buffer consumption.
    Based on the current circular buffer position and `count_per_iteration`, it
    determines which pipeline stages have been fully consumed and transitions them
    to empty.

    Args:
        pipeline: The underlying pipeline object
        circular_buffer_pipeline_state: Current circular buffer pipeline state
        loc: Source location
        ip: Insertion point
    """
    cutlass_lir_ir.CircularBufferPipelineConsumerReleaseOp(
        pipeline,
        circular_buffer_pipeline_state,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def circular_buffer_pipeline_advance_iterator(
    pipeline: ir.Value,
    circular_buffer_pipeline_state: CircularBufferPipelineState,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> CircularBufferPipelineState:
    """
    Advance the circular buffer position.

    This operation advances the circular buffer position by `count_per_iteration`
    units.

    Args:
        pipeline: The underlying pipeline
        circular_buffer_pipeline_state: Current circular buffer pipeline state
        loc: Source location
        ip: Insertion point

    Returns:
        CircularBufferPipelineState: Updated circular buffer pipeline state with advanced offset
    """
    op = cutlass_lir_ir.CircularBufferPipelineAdvanceIteratorOp(
        pipeline,
        circular_buffer_pipeline_state,
        loc=loc,
        ip=ip,
    )
    return op.result


@dsl_user_op
def mbarrier_expect_tx(
    mbarPtr: ir.Value,
    txBytes: cute.Int32,
    ctaId: Optional[ir.Value] = None,
    elect_one_sync: bool = False,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    """
    Called by the consumer to block until asynchronous tasks have completed. Supports optional broadcast.
    """
    if isinstance(txBytes, int):
        txBytes = cute.Int32(txBytes)
    if ctaId != None:
        ctaId = ctaId.value
    _op = cutlass_lir_ir.MBarrierExpectTxOp(
        mbarPtr.value,
        txBytes.ir_value(),
        ctaId=ctaId,
        elect_one_sync=elect_one_sync,
        loc=loc,
        ip=ip,
    )
    return


def normalize_skip_wait_token(
    token: Optional[SkipWaitToken],
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Optional[ir.Value]:
    """
    Normalizes a skip wait token to an ir.Value.
    """
    if token is None:
        return None
    if isinstance(token, bool):
        return Boolean(token).ir_value(loc=loc, ip=ip)
    if isinstance(token, ir.Value):
        return token
    if hasattr(token, "ir_value"):
        return token.ir_value(loc=loc, ip=ip)
    raise TypeError(f"skipWait token must lower to ir.Value, got {type(token)}")


@dsl_user_op
def producer_try_acquire(
    pipe: ir.Value,
    state: ir.Value,
    *,
    token: Optional[SkipWaitToken] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Boolean:
    """
    Tries to acquire a producer stage, non-blocking.
    """
    skip_wait = normalize_skip_wait_token(token, loc=loc, ip=ip)
    token_value = cutlass_lir_ir.ProducerTryAcquireOp(
        pipe, state, skipWait=skip_wait, loc=loc, ip=ip
    ).token
    return Boolean(token_value, loc=loc, ip=ip)


@dsl_user_op
def consumer_try_wait(
    pipe: ir.Value,
    state: ir.Value,
    *,
    token: Optional[SkipWaitToken] = None,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> Boolean:
    """
    Tries to wait for a consumer stage, non-blocking.
    """
    skip_wait = normalize_skip_wait_token(token, loc=loc, ip=ip)
    token_value = cutlass_lir_ir.ConsumerTryWaitOp(
        pipe, state, skipWait=skip_wait, loc=loc, ip=ip
    ).token
    return Boolean(token_value, loc=loc, ip=ip)
