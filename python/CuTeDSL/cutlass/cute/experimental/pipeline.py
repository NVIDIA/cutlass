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

"""
Convenience pipeline classes that hide elect_one synchronization complexity
"""

# The stdlib copy() FUNCTION, underscore-aliased so it stays out of this
# module's star-exports (cute.experimental re-exports * from here and defines
# its own `copy` op in memory.py, which an un-underscored name would shadow).
from copy import copy as _shallow_copy
from dataclasses import dataclass
from typing import NoReturn, Optional, cast

from typing_extensions import Self

import cutlass

import cutlass.cute as cute
from cutlass.base_dsl.typing import Int32
from cutlass._mlir import ir
from cutlass._mlir.dialects import lir as cutlass_lir_ir
from cutlass.cutlass_dsl import extract_mlir_values
from cutlass._mlir.dialects.core import (
    OperationTypeEnum,
    is_sm10x_mma_2sm_operation,
    is_sm10x_mma_operation,
)
from cutlass.cute.typing import Boolean
from cutlass.cute.experimental.core import (
    create_pipeline,
    get_arrival_count,
    producer_acquire,
    get_pipeline_produce_phase,
    get_pipeline_consume_phase,
    get_pipeline_produce_stage,
    get_pipeline_consume_stage,
    get_mbarrier,
    producer_commit,
    consumer_release,
    pipeline_advance_iterator,
    PipelineState,
    consumer_wait,
    consumer_test_valid,
    create_pipeline_state_at,
    pipeline_tail,
    create_circular_buffer_pipeline,
    circular_buffer_pipeline_consume,
    circular_buffer_pipeline_consumer_release,
    circular_buffer_pipeline_advance_iterator,
    normalize_skip_wait_token,
    producer_try_acquire,
    consumer_try_wait,
    OperationTypeSpec,
    SkipWaitToken,
    PipelineLocale,
    MmaOperand,
    MmaOperation,
    OperationDescriptor,
    _mma_operand_of,
    _operation_descriptors,
    _operation_kind,
)


def _resolve_arrival_count(
    side: str,
    *,
    arv_count: Optional[cute.Int32],
    threads_per_cta: Optional[cute.Int32],
    producer: OperationTypeSpec,
    consumer: OperationTypeSpec,
    locale: Optional[PipelineLocale] = None,
) -> cute.Int32:
    """Resolve one side's mbarrier arrival count from the two mutually
    exclusive parameters a pipeline ``create`` exposes for that side.

    ``arv_count`` is the explicit count (the legacy parameter); it is returned
    verbatim, so callers that already know the count keep their behavior.
    ``threads_per_cta`` is the number of threads per CTA that issue the release
    on this side; the count is derived with :func:`get_arrival_count` from the
    pipeline's producer/consumer operation types. The release on the resolved
    side is the pipeline class's default -- non-elected and unmasked -- so an
    elected or multicast-masked release must use ``arv_count``.

    Exactly one of the two must be provided. The message describes the two
    parameters semantically rather than by name -- the exact parameter names
    live on each ``create`` signature, and this helper does not assume a naming
    convention for them.
    """
    if (arv_count is None) == (threads_per_cta is None):
        raise ValueError(
            f"provide exactly one of the {side} arrival count or the {side} "
            "per-CTA issuing thread count (see this pipeline's create signature)"
        )
    if arv_count is not None:
        return arv_count
    return get_arrival_count(
        producer,
        consumer,
        side=side,
        num_threads_per_cta=threads_per_cta,
        locale=locale,
    )


class GenericPipelineBase:
    """Base class for pipeline convenience wrappers.

    Ordinary Python assignment and indexing preserve object identity. For
    example, ``selected = pipelines[0]`` aliases ``pipelines[0]``, so mutating
    ``selected.consumer_state`` also updates that list entry.

    This differs from reconstruction through the DynamicExpression protocol,
    which the DSL uses when transporting values across staged control flow.
    ``__extract_mlir_values__`` exposes the component SSA values and
    ``__new_from_mlir_values__`` creates a distinct wrapper around transported
    values. Later attribute mutation affects only the reconstructed wrapper; it
    does not write back into the Python container that held the original
    wrapper. Keeping and using either state is valid. Authors who intend to
    propagate an updated state must do so explicitly through the surrounding
    staged control flow.

    To deliberately hold two positions on the same pipeline (e.g. a consumer
    whose waits run ahead of its in-order releases), call :meth:`clone`
    rather than re-invoking the constructor with another wrapper's fields,
    which reads misleadingly like pipeline creation at the call site. The
    constructor itself remains the right tool for its two jobs: wrapping a
    fresh ``create_pipeline`` result when no ``create()`` factory covers the
    configuration, and wrapper reconstruction by the DynamicExpression
    protocol.
    """

    def __init__(
        self,
        raw_pipeline: ir.Value,
        num_stages: cute.Int32,
        producer_state: ir.Value,
        consumer_state: ir.Value,
    ) -> None:
        self.raw_pipeline = raw_pipeline
        self.num_stages = num_stages
        # For convenience class, we always manage state internally
        self.producer_state = producer_state
        self.consumer_state = consumer_state

    def __extract_mlir_values__(self) -> list:
        """Extract MLIR values for DynamicExpression protocol."""
        # raw_pipeline is always ir.OpResult from create_pipeline (no __extract_mlir_values__)
        pipeline_values = [self.raw_pipeline]

        # Create DSL types and extract their underlying MLIR values
        num_stages_dsl = Int32(self.num_stages)

        # Pipeline states are already MLIR values (PipelineState objects)
        producer_state_values = [self.producer_state]
        consumer_state_values = [self.consumer_state]

        return (
            pipeline_values
            + [
                num_stages_dsl.__extract_mlir_values__()[0],  # type: ignore[attr-defined]
            ]
            + producer_state_values
            + consumer_state_values
        )

    @classmethod
    def __new_from_mlir_values__(cls, values: list) -> "GenericPipelineBase":
        """Reconstruct object from MLIR values."""
        # Parse the known structure: [pipeline] + [num_stages, producer_flag, consumer_flag] + [producer_state] + [consumer_state]
        # All lir_* objects are single MLIR values
        raw_pipeline = values[0]  # Always single ir.OpResult
        num_stages_val = values[1]
        producer_state = values[2]  # Always single PipelineState
        consumer_state = values[3]  # Always single PipelineState

        num_stages_dsl = Int32(0).__new_from_mlir_values__([num_stages_val])  # type: ignore[attr-defined]

        return cls(
            raw_pipeline,
            num_stages_dsl,
            producer_state,
            consumer_state,
        )

    def clone(self) -> Self:
        """Return a new wrapper over the same pipeline with independent cursors.

        The clone aliases this pipeline's mbarriers (``raw_pipeline``) -- no
        barriers are allocated and no IR is emitted -- and snapshots the
        current producer/consumer cursor values. From that point the two
        wrappers advance independently.

        The canonical use is a multi-hold consumer whose waits must run ahead
        of its in-order releases. The clone's cursor does not move on a wait;
        advance it explicitly with :meth:`consumer_advance`::

            load_q_next = load_q_pipe.clone()  # runs ahead: waits on
                                                   # upcoming stages
            _, idx = load_q_next.consumer_wait_and_get_stage()
            load_q_next.consumer_advance()
            ...
            load_q_pipe.consumer_release_and_advance()  # lags: FIFO releases

        The concrete type matches ``type(self)``; subclass-specific fields
        are carried over by shallow copy. Note: this recipe applies to
        stage-indexed pipelines; ``TMAToUMMACircularPipeline`` tracks its
        consumer position in ``circular_buffer_state`` and does not support
        ``consumer_wait_and_get_stage``, so a clone of it cannot run ahead via
        ``consumer_state``.
        """
        return _shallow_copy(self)

    def consumer_advance(self) -> Self:
        """Advance the consumer cursor without releasing the stage.

        This does NOT stand in for a release: a stage whose release nobody
        posts eventually deadlocks the producer at acquire. It is legal only
        when the release is guaranteed elsewhere:

        * another wrapper of the same pipeline (this clone's partner)
          releases every stage in order via
          :meth:`consumer_release_and_advance` -- the run-ahead multi-hold
          pattern that :meth:`clone` exists for; or
        * the pipeline has no producer-side acquire to unblock (a pure
          ordering semaphore whose consumer only ever waits, e.g. the FMHA
          prefill in-place S/P exchange); or
        * partner consumers split stages by parity and each advances past
          the stages the other owns (cursor-offset schemes).
        """
        self.consumer_state = pipeline_advance_iterator(
            self.raw_pipeline, self.consumer_state
        )
        return self

    def producer_advance(self) -> Self:
        """Advance the producer cursor without acquiring or committing.

        The producer-side mirror of :meth:`consumer_advance`, with the
        analogous legality rule -- the skipped acquire/commit must be
        covered elsewhere:

        * another agent posts the commit for this stage, e.g. the non-leader
          CTA of a 2-CTA TMA pair issuing its slice against the leader's
          mbarrier (``update_expect_tx=False``) while the leader's commit
          carries the arrive; or
        * partner producers split stages by parity and each advances past
          the stages the other owns (cursor-offset schemes).
        """
        self.producer_state = pipeline_advance_iterator(
            self.raw_pipeline, self.producer_state
        )
        return self

    def producer_acquire(self) -> "GenericPipelineBase":
        """Acquire producer state."""
        self.producer_state = producer_acquire(self.raw_pipeline, self.producer_state)
        return self

    def producer_try_acquire(self, *, token: Optional[SkipWaitToken] = None) -> Boolean:
        """Try to acquire the next producer stage without blocking."""
        return producer_try_acquire(self.raw_pipeline, self.producer_state, token=token)

    def get_producer_stage(self) -> ir.Value:
        """Get producer stage."""
        return get_pipeline_produce_stage(self.raw_pipeline, self.producer_state)

    def get_consumer_stage(self) -> ir.Value:
        """Get consumer stage."""
        return get_pipeline_consume_stage(self.raw_pipeline, self.consumer_state)

    def get_producer_phase(self) -> cute.Int32:
        """Get the producer component from this wrapper's producer cursor."""
        return get_pipeline_produce_phase(self.producer_state)

    def get_consumer_phase(self) -> cute.Int32:
        """Get the consumer component from this wrapper's consumer cursor."""
        return get_pipeline_consume_phase(self.consumer_state)

    # Instance methods that can now be used directly in kernel context
    def producer_acquire_and_get_stage(
        self, *, token: Optional[SkipWaitToken] = None
    ) -> tuple[ir.Value, ir.Value]:
        """Acquire a producer stage and return its stage token/index.

        When `token` is provided, reuse the preceding `producer_try_acquire()`
        result and keep the stored state at the acquired stage so a following
        `producer_commit_and_advance()` retires the same stage.
        """
        if token is None:
            self.producer_acquire()
            return get_pipeline_produce_stage(self.raw_pipeline, self.producer_state)

        skip_wait = normalize_skip_wait_token(token)
        stage_state = cutlass_lir_ir.ProducerAcquireOp(
            self.raw_pipeline,
            self.producer_state,
            skipWait=skip_wait,
        ).outState
        self.producer_state = stage_state
        stage_token, stage_idx = get_pipeline_produce_stage(
            self.raw_pipeline, stage_state
        )
        return stage_token, stage_idx

    def producer_acquire_and_get_phase(
        self, *, token: Optional[SkipWaitToken] = None
    ) -> cute.Int32:
        """Acquire a producer stage and return its producer phase.

        Keep acquisition coupled to phase selection so callers cannot choose
        phase-indexed storage without first establishing producer ownership.
        Use ``get_producer_phase`` only when synchronization is deliberately
        managed separately.
        """
        if token is None:
            self.producer_acquire()
            return get_pipeline_produce_phase(self.producer_state)

        skip_wait = normalize_skip_wait_token(token)
        stage_state = cutlass_lir_ir.ProducerAcquireOp(
            self.raw_pipeline,
            self.producer_state,
            skipWait=skip_wait,
        ).outState
        self.producer_state = stage_state
        return get_pipeline_produce_phase(stage_state)

    def producer_commit(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "GenericPipelineBase":
        """Commit producer state."""
        producer_commit(
            self.raw_pipeline,
            self.producer_state,
            elect_one_sync=elect_one_sync,
            elect_leader_cta=elect_leader_cta,
        )
        return self

    def consumer_try_wait(self, *, token: Optional[SkipWaitToken] = None) -> Boolean:
        """Try to wait for the next consumer stage without blocking."""
        return consumer_try_wait(self.raw_pipeline, self.consumer_state, token=token)

    def consumer_test_valid(
        self, state: Optional[PipelineState] = None
    ) -> tuple[Boolean, Boolean]:
        """Probe whether a consumer stage is ready and data-valid."""
        if state is not None:
            return consumer_test_valid(self.raw_pipeline, state)
        return consumer_test_valid(self.raw_pipeline, self.consumer_state)

    def consumer_release(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "GenericPipelineBase":
        """Release consumer state."""
        consumer_release(
            self.raw_pipeline,
            self.consumer_state,
            elect_one_sync=elect_one_sync,
            elect_leader_cta=elect_leader_cta,
        )
        return self

    def producer_commit_and_advance(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "GenericPipelineBase":
        """Combined producer commit + advance using stored state."""
        self.producer_commit(
            elect_one_sync=elect_one_sync,
            elect_leader_cta=elect_leader_cta,
        )
        # Update state in-place for better performance
        self.producer_state = pipeline_advance_iterator(
            self.raw_pipeline, self.producer_state
        )
        return self

    def consumer_wait_and_get_stage(
        self, *, token: Optional[SkipWaitToken] = None
    ) -> tuple[ir.Value, ir.Value]:
        """Wait for a consumer stage and return its stage token/index.

        When `token` is provided, reuse the preceding `consumer_try_wait()`
        result and keep the stored state at the consumed stage so a following
        `consumer_release_and_advance()` retires the same stage.
        """
        if token is None:
            self.consumer_wait()
            return get_pipeline_consume_stage(self.raw_pipeline, self.consumer_state)

        skip_wait = normalize_skip_wait_token(token)
        stage_state = cutlass_lir_ir.ConsumerWaitOp(
            self.raw_pipeline,
            self.consumer_state,
            skipWait=skip_wait,
        ).outState
        self.consumer_state = stage_state
        stage_token, stage_idx = get_pipeline_consume_stage(
            self.raw_pipeline, stage_state
        )
        return stage_token, stage_idx

    def consumer_wait_and_get_phase(
        self, *, token: Optional[SkipWaitToken] = None
    ) -> cute.Int32:
        """Wait for a consumer stage and return its consumer phase.

        Keep waiting coupled to phase selection so callers cannot read a
        phase-indexed view before the producer has made it available. Use
        ``get_consumer_phase`` only when synchronization is deliberately
        managed separately.
        """
        if token is None:
            self.consumer_wait()
            return get_pipeline_consume_phase(self.consumer_state)

        skip_wait = normalize_skip_wait_token(token)
        stage_state = cutlass_lir_ir.ConsumerWaitOp(
            self.raw_pipeline,
            self.consumer_state,
            skipWait=skip_wait,
        ).outState
        self.consumer_state = stage_state
        return get_pipeline_consume_phase(stage_state)

    def consumer_wait(
        self, state: Optional[PipelineState] = None
    ) -> "GenericPipelineBase":
        """Wait for consumer to be ready."""
        if state is not None:
            consumer_wait(self.raw_pipeline, state)
        else:
            self.consumer_state = consumer_wait(self.raw_pipeline, self.consumer_state)
        return self

    def consumer_release_and_advance(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "GenericPipelineBase":
        """Combined consumer release + advance using stored state."""
        self.consumer_release(
            elect_one_sync=elect_one_sync,
            elect_leader_cta=elect_leader_cta,
        )
        # Update state in-place for better performance
        self.consumer_state = pipeline_advance_iterator(
            self.raw_pipeline, self.consumer_state
        )
        return self

    def producer_tail(self) -> "GenericPipelineBase":
        """Drain outstanding pipeline work visible to the producer state.

        A TMA producer role must call this after its final commit and before
        exiting.
        """
        self.producer_state = pipeline_tail(self.raw_pipeline, self.producer_state)
        return self

    def consumer_tail(self) -> "GenericPipelineBase":
        """Drain outstanding pipeline work visible to the consumer state."""
        self.consumer_state = pipeline_tail(self.raw_pipeline, self.consumer_state)
        return self

    def increment_state(self, state: PipelineState) -> ir.Value:
        """Advance the input state w/o modifying current pipeline"""
        return pipeline_advance_iterator(self.raw_pipeline, state)

    def create_state_at(
        self, stage_index: cute.Int32, phase: cute.Int32
    ) -> PipelineState:
        """Create a pipeline state for an explicit stage and phase."""
        return create_pipeline_state_at(
            self.raw_pipeline, self.num_stages, stage_index, phase
        )


class GenericPipeline(GenericPipelineBase):
    """
    Generic pipeline for any combination of producer and consumer.
    """

    @staticmethod
    def create(
        *,
        producer: OperationTypeSpec,
        consumer: OperationTypeSpec,
        producer_arv_count: cute.Int32,
        consumer_arv_count: cute.Int32,
        num_stages: cute.Int32,
        locale: Optional[PipelineLocale] = None,
        producer_report_valid: bool = False,
    ) -> "GenericPipeline":
        """
        Create a generic pipeline with parameterized producer and consumer.

        GenericPipeline is the low-level primitive: the caller supplies both
        operation types and the exact arrival counts. It deliberately does not
        offer the ``*_threads_per_cta`` count-derivation the named helper
        classes do -- the caller already has both op types (so it can call
        ``get_arrival_count`` directly if it wants derivation) and drives the
        release election itself, which the derivation cannot see.

        Args:
            producer: Producer operation type(s); a tcgen05 MMA may be refined
                with the operand it writes, ``MmaOperation(kind, MmaOperand.D)``.
            consumer: Consumer operation type(s); a tcgen05 MMA may be refined
                with the operand it reads, ``MmaOperation(kind, MmaOperand.A)``.
            producer_arv_count: Producer arrival count
            consumer_arv_count: Consumer arrival count
            num_stages: Number of pipeline stages
            locale: Optional explicit pipeline synchronization locale.
            producer_report_valid: Enable producer validity-check mode. This
                currently requires a TMA load producer.
        """
        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            producer,
            consumer,
            producer_arv_count=producer_arv_count,
            consumer_arv_count=consumer_arv_count,
            locale=locale,
            producer_report_valid=producer_report_valid,
        )

        return GenericPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
        )


def _validate_umma_operation_type(operation_type: OperationDescriptor) -> None:
    if not isinstance(operation_type, (OperationTypeEnum, MmaOperation)):
        raise TypeError(
            "mma_operation_type must be an OperationTypeEnum or an MmaOperation, "
            f"got {type(operation_type)}"
        )
    if not is_sm10x_mma_operation(_operation_kind(operation_type)):
        raise ValueError(f"Invalid UMMA operation type: {operation_type}")


def _has_kind(spec: OperationTypeSpec, kind: OperationTypeEnum) -> bool:
    return kind in {_operation_kind(d) for d in _operation_descriptors(spec)}


def _is_2sm_umma_operation_type(operation_type: OperationDescriptor) -> bool:
    """Check if the operation type is a 2SM UMMA operation."""
    return is_sm10x_mma_2sm_operation(_operation_kind(operation_type))


def _is_multicast_tma_operation_type(operation_type: OperationTypeEnum) -> bool:
    """Check if the operation type is a multicast TMA load."""
    return operation_type in [
        OperationTypeEnum.SM90_TMA_LOAD_MULTICAST,
        OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST,
    ]


def _is_2sm_tma_operation_type(operation_type: OperationTypeEnum) -> bool:
    """Check if the operation type is a 2SM TMA load."""
    return operation_type in [
        OperationTypeEnum.SM100_TMA_LOAD_2SM,
        OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST,
        OperationTypeEnum.SM100_TMA_LOAD_2SM_IM2COL,
        OperationTypeEnum.SM100_TMA_LOAD_2SM_IM2COL_MULTICAST,
    ]


def _is_2sm_tma_pipeline_value(raw_pipeline: ir.Value) -> bool:
    """Return whether a reconstructed pipeline value has a 2SM TMA producer."""
    return "SM100_TMA_LOAD_2SM" in str(raw_pipeline.type)


class TMAToUMMAPipeline(GenericPipelineBase):
    """
    Pipeline for TMA to UMMA.

    The TMA producer must call :meth:`producer_tail` after its final commit and
    before exiting its producer role.
    """

    def __init__(
        self,
        raw_pipeline: ir.Value,
        num_stages: cute.Int32,
        producer_state: ir.Value,
        consumer_state: ir.Value,
        is_2sm: bool = False,
    ) -> None:
        super().__init__(raw_pipeline, num_stages, producer_state, consumer_state)
        self.is_2sm = is_2sm

    @classmethod
    def __new_from_mlir_values__(cls, values: list) -> "TMAToUMMAPipeline":
        obj = cast("TMAToUMMAPipeline", super().__new_from_mlir_values__(values))
        obj.is_2sm = _is_2sm_tma_pipeline_value(obj.raw_pipeline)
        return obj

    @staticmethod
    def create(
        *,
        num_stages: cute.Int32,
        mma_operation_type: OperationDescriptor,
        tma_operation_type: Optional[OperationTypeEnum] = None,
        cluster_layout_vmnk: Optional[cute.Layout] = None,
        producer_report_valid: bool = False,
    ) -> "TMAToUMMAPipeline":
        """
        Create a TMA to UMMA pipeline.

        Args:
            num_stages: Number of pipeline stages.
            mma_operation_type: UMMA operation type (e.g., SM100_MMA_1SM_SS).
                An ``MmaOperation(kind, MmaOperand.A)`` (or ``B``) names the
                operand the stages hold. A multicast pipeline signals only the CTAs sharing that
                operand instead of the union of the A and B multicast sets.
            tma_operation_type: TMA operation type. Defaults to SM90_TMA_LOAD.
            cluster_layout_vmnk: Cluster layout in (v, m, n, k) order. Required
                whenever the selected TMA load spans more than one CTA, i.e.
                for any 2SM or multicast `tma_operation_type`. This layout is
                the source of truth for CTA identity and v-pair membership. The
                m/n/k dimensions can be dynamic.
            producer_report_valid: Enable producer validity-check mode.
        """
        _validate_umma_operation_type(
            mma_operation_type,
        )
        operand = _mma_operand_of(mma_operation_type)
        if operand is not None and operand not in (MmaOperand.A, MmaOperand.B):
            raise ValueError(
                "TMAToUMMAPipeline stages are TMA-written shared memory, so "
                f"the MMA operand must be A or B, got {mma_operation_type}"
            )

        if tma_operation_type is None:
            tma_operation_type = OperationTypeEnum.SM90_TMA_LOAD

        if _is_multicast_tma_operation_type(tma_operation_type):
            if cluster_layout_vmnk is None:
                raise ValueError(
                    "cluster_layout_vmnk is required when using multicast TMA loads"
                )
            return TMAToUMMAPipeline._create_with_multicast_mask(
                num_stages=num_stages,
                tma_operation_type=tma_operation_type,
                mma_operation_type=mma_operation_type,
                cluster_layout_vmnk=cluster_layout_vmnk,
                producer_report_valid=producer_report_valid,
            )

        if tma_operation_type == OperationTypeEnum.SM100_TMA_LOAD_2SM:
            if cluster_layout_vmnk is None:
                raise ValueError(
                    "cluster_layout_vmnk is required if using 2CTA MMA with TMA"
                )

            cta_rank_in_cluster = cute.arch.make_warp_uniform(
                cute.arch.block_idx_in_cluster()
            )
            cta_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
                cta_rank_in_cluster
            )
            arrival_mask = cute.make_layout_image_mask(
                cluster_layout_vmnk, cta_in_cluster_coord_vmnk, mode=0
            )

            raw_pipeline, producer_state, consumer_state = create_pipeline(
                num_stages,
                tma_operation_type,
                mma_operation_type,
                # Mirror this class's producer_commit: one warp issues,
                # elect_one_sync elects one thread, and for 2SM only the
                # leader CTA commits.
                producer_arv_count=get_arrival_count(
                    tma_operation_type,
                    mma_operation_type,
                    side="producer",
                    num_threads_per_cta=32,
                    elect_one_sync=True,
                    elect_leader_cta=True,
                ),
                # Mirror this class's consumer_release. The consumer arrivals
                # are multicast-masked (the mask below covers the CTA pair),
                # so the fan-in is not derivable from the pipeline: one
                # issuing CTA pair converges on each barrier in the mask.
                consumer_arv_count=get_arrival_count(
                    tma_operation_type,
                    mma_operation_type,
                    side="consumer",
                    num_threads_per_cta=32,
                    elect_one_sync=True,
                    fan_in=1,
                ),
                arrival_mask=arrival_mask,
                producer_report_valid=producer_report_valid,
            )
        elif tma_operation_type == OperationTypeEnum.SM90_TMA_LOAD:
            raw_pipeline, producer_state, consumer_state = create_pipeline(
                num_stages,
                tma_operation_type,
                mma_operation_type,
                # Mirror this class's producer_commit / consumer_release:
                # one warp issues each release with elect_one_sync.
                producer_arv_count=get_arrival_count(
                    tma_operation_type,
                    mma_operation_type,
                    side="producer",
                    num_threads_per_cta=32,
                    elect_one_sync=True,
                ),
                consumer_arv_count=get_arrival_count(
                    tma_operation_type,
                    mma_operation_type,
                    side="consumer",
                    num_threads_per_cta=32,
                    elect_one_sync=True,
                ),
                producer_report_valid=producer_report_valid,
            )
        else:
            raise ValueError(f"Invalid tma_operation_type: {tma_operation_type}")
        is_2sm = _is_2sm_tma_operation_type(tma_operation_type)
        return TMAToUMMAPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
            is_2sm=is_2sm,
        )

    @staticmethod
    def _create_with_multicast_mask(
        *,
        num_stages: cute.Int32,
        tma_operation_type: OperationTypeEnum,
        mma_operation_type: OperationDescriptor,
        cluster_layout_vmnk: cute.Layout,
        producer_report_valid: bool,
    ) -> "TMAToUMMAPipeline":
        """Compute TMA multicast masks from cluster layout."""
        # Standard GEMM projection; an operand-specific pipeline below relies
        # on it matching the kernel's tma_load multicast modes.
        tma_mcast_proj_A = 2  # multicast across CTAs in same row
        tma_mcast_proj_B = 1  # multicast across CTAs in same column

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cta_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster
        )

        # For 2CTA MMA (v-size==2), the peer CTA is the other v-slice (xor 1).
        # For 1CTA MMA (v-size==1), the peer is the local CTA (no flip).
        cluster_shape_vmnk = cluster_layout_vmnk.shape
        assert isinstance(cluster_shape_vmnk, tuple)
        v_size = cute.size(cluster_shape_vmnk[0])
        peer_v = (
            (cta_in_cluster_coord_vmnk[0] ^ 1)
            if cutlass.const_expr(v_size > 1)
            else cta_in_cluster_coord_vmnk[0]
        )
        cta_in_cluster_coord_vmnk_peer = (
            peer_v,
            *cta_in_cluster_coord_vmnk[1:],
        )

        arrival_mask_a = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cluster_layout_vmnk, cta_in_cluster_coord_vmnk, tma_mcast_proj_A
        )
        arrival_mask_b = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cluster_layout_vmnk, cta_in_cluster_coord_vmnk, tma_mcast_proj_B
        )

        arrival_mask_a_peer = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cluster_layout_vmnk,
            cta_in_cluster_coord_vmnk_peer,
            mcast_mode=tma_mcast_proj_A,
        )
        arrival_mask_b_peer = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cluster_layout_vmnk,
            cta_in_cluster_coord_vmnk_peer,
            mcast_mode=tma_mcast_proj_B,
        )

        # if 1SM MMA, arrival_mask_a_peer==arrival_mask_a && arrival_mask_b==arrival_mask_b_peer
        num_mcast_ctas_a = cute.size(cluster_shape_vmnk[2])
        num_mcast_ctas_b = cute.size(cluster_shape_vmnk[1])

        # The consumer release must reach every CTA (pair) whose next TMA into
        # this stage multicasts here. A stage holding both operands is refilled
        # by its row (A) and its column (B), so the union converges on each
        # barrier; a pipeline dedicated to one operand only needs that
        # operand's multicast set, and the fan-in shrinks to match.
        operand = _mma_operand_of(mma_operation_type)
        if cutlass.const_expr(operand == MmaOperand.A):
            arrival_mask_c = arrival_mask_a | arrival_mask_a_peer
            num_mcast_participants = num_mcast_ctas_a
        elif cutlass.const_expr(operand == MmaOperand.B):
            arrival_mask_c = arrival_mask_b | arrival_mask_b_peer
            num_mcast_participants = num_mcast_ctas_b
        else:
            arrival_mask_c = (
                arrival_mask_a
                | arrival_mask_a_peer
                | arrival_mask_b
                | arrival_mask_b_peer
            )
            num_mcast_participants = num_mcast_ctas_a + num_mcast_ctas_b - 1

        is_2sm = _is_2sm_tma_operation_type(tma_operation_type)
        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            tma_operation_type,
            mma_operation_type,
            # Mirror this class's producer_commit: one warp issues,
            # elect_one_sync elects one thread, and for 2SM only the leader
            # CTA commits.
            producer_arv_count=get_arrival_count(
                tma_operation_type,
                mma_operation_type,
                side="producer",
                num_threads_per_cta=32,
                elect_one_sync=True,
                elect_leader_cta=is_2sm,
            ),
            # Mirror this class's consumer_release. The consumer arrivals are
            # multicast-masked, so the fan-in is not derivable from the
            # pipeline: the multicast participant count is the number of
            # issuing CTAs (pairs, for 2SM) converging on each barrier in
            # the mask.
            consumer_arv_count=get_arrival_count(
                tma_operation_type,
                mma_operation_type,
                side="consumer",
                num_threads_per_cta=32,
                elect_one_sync=True,
                fan_in=num_mcast_participants,
            ),
            arrival_mask=arrival_mask_c,
            producer_report_valid=producer_report_valid,
        )
        return TMAToUMMAPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
            is_2sm=is_2sm,
        )

    def producer_commit(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "TMAToUMMAPipeline":
        """
        Commit producer state.

        For 2SM MMA, only leader CTA commits during production as MMA
        is issued by leader.
        """
        super().producer_commit(
            elect_one_sync=True,
            elect_leader_cta=True if self.is_2sm else None,
        )
        return self

    def consumer_release(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "TMAToUMMAPipeline":
        """Release consumer state."""
        super().consumer_release(elect_one_sync=True)
        return self


class TMAToUMMACircularPipeline(TMAToUMMAPipeline):
    """
    Circular Buffer Pipeline for TMA to UMMA.

    This class wraps a TMAToUMMAPipeline and adds circular buffer semantics,
    allowing fine-grained control over chunk-wise consumption within pipeline stages.
    """

    def __init__(
        self,
        raw_pipeline: ir.Value,
        num_stages: cute.Int32,
        producer_state: ir.Value,
        consumer_state: ir.Value,
        circular_buffer_state: ir.Value,
        count_per_stage: int,
        count_per_iteration: int,
    ) -> None:
        super().__init__(raw_pipeline, num_stages, producer_state, consumer_state)
        self.circular_buffer_state = circular_buffer_state
        self.count_per_stage = count_per_stage
        self.count_per_iteration = count_per_iteration

    @staticmethod
    def create(  # type: ignore[override]
        *,
        num_stages: cute.Int32,
        mma_operation_type: OperationDescriptor,
        count_per_stage: int,
        count_per_iteration: int,
        tma_operation_type: Optional[OperationTypeEnum] = None,
        cluster_layout_vmnk: Optional[cute.Layout] = None,
    ) -> "TMAToUMMACircularPipeline":
        """
        Create a TMA to UMMA circular buffer pipeline.

        Args:
            num_stages: Number of pipeline stages
            mma_operation_type: MMA operation type
            count_per_stage: Number of units (chunks) per pipeline stage
            count_per_iteration: Number of units (chunks) consumed per iteration
            tma_operation_type: TMA operation type (optional, defaults to SM90_TMA_LOAD)
            cluster_layout_vmnk: Cluster layout in (v, m, n, k) order. Required
                whenever the selected TMA load spans more than one CTA (2SM or
                multicast).

        Returns:
            TMAToUMMACircularPipeline: A circular buffer pipeline instance
        """
        base_pipeline = TMAToUMMAPipeline.create(
            num_stages=num_stages,
            mma_operation_type=mma_operation_type,
            tma_operation_type=tma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

        # Create the circular buffer pipeline state on top
        circular_buffer_state = create_circular_buffer_pipeline(
            base_pipeline.raw_pipeline,
            base_pipeline.consumer_state,
            stages=num_stages,
            count_per_stage=count_per_stage,
            count_per_iteration=count_per_iteration,
        )

        return TMAToUMMACircularPipeline(
            base_pipeline.raw_pipeline,
            num_stages,
            base_pipeline.producer_state,
            base_pipeline.consumer_state,
            circular_buffer_state,
            count_per_stage,
            count_per_iteration,
        )

    def __extract_mlir_values__(self) -> list:
        """Extract MLIR values for DynamicExpression protocol."""
        # Get base values from parent: [pipeline, num_stages, producer_state, consumer_state]
        base_values = super().__extract_mlir_values__()

        # Add circular buffer specific values
        count_per_stage_dsl = Int32(self.count_per_stage)
        count_per_iteration_dsl = Int32(self.count_per_iteration)

        return (
            base_values
            + [count_per_stage_dsl.__extract_mlir_values__()[0]]  # type: ignore[attr-defined]
            + [count_per_iteration_dsl.__extract_mlir_values__()[0]]  # type: ignore[attr-defined]
            + [self.circular_buffer_state]
        )

    @classmethod
    def __new_from_mlir_values__(cls, values: list) -> "TMAToUMMACircularPipeline":
        """Reconstruct object from MLIR values."""
        # Parse: [pipeline, num_stages, producer_state, consumer_state, count_per_stage, count_per_iteration, circular_buffer_state]
        raw_pipeline = values[0]
        num_stages_val = values[1]
        producer_state = values[2]
        consumer_state = values[3]
        count_per_stage_val = values[4]
        count_per_iteration_val = values[5]
        circular_buffer_state = values[6]

        # Extract Python values from DSL objects
        temp_int = Int32(0)
        num_stages = temp_int.__new_from_mlir_values__([num_stages_val]).value  # type: ignore[attr-defined]
        count_per_stage = temp_int.__new_from_mlir_values__([count_per_stage_val]).value  # type: ignore[attr-defined]
        count_per_iteration = temp_int.__new_from_mlir_values__(  # type: ignore[attr-defined]
            [count_per_iteration_val]
        ).value

        return cls(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
            circular_buffer_state,
            count_per_stage,
            count_per_iteration,
        )

    def consumer_wait(self) -> "TMAToUMMACircularPipeline":  # type: ignore[override]
        """Wait for consumer to be ready (uses circular buffer consume)."""
        circular_buffer_pipeline_consume(self.raw_pipeline, self.circular_buffer_state)
        return self

    def consumer_release(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "TMAToUMMACircularPipeline":
        """Release consumer state (uses circular buffer consumer release)."""
        circular_buffer_pipeline_consumer_release(
            self.raw_pipeline,
            self.circular_buffer_state,
            elect_one_sync=True,
        )
        return self

    def consumer_release_and_advance(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "TMAToUMMACircularPipeline":
        """Combined consumer release + advance using circular buffer semantics."""
        self.consumer_release(
            elect_one_sync=elect_one_sync,
            elect_leader_cta=elect_leader_cta,
        )
        # Update circular buffer state
        self.circular_buffer_state = circular_buffer_pipeline_advance_iterator(
            self.raw_pipeline, self.circular_buffer_state
        )
        return self

    def get_consumer_stage(self) -> None:
        """Get consumer stage - unsupported for circular buffer pipeline."""
        raise NotImplementedError(
            "get_consumer_stage() is not supported for TMAToUMMACircularPipeline."
        )

    def consumer_wait_and_get_stage(
        self, *, token: Optional[SkipWaitToken] = None
    ) -> NoReturn:
        """Combined consumer wait + get_stage - unsupported for circular buffer pipeline."""
        raise NotImplementedError(
            "consumer_wait_and_get_stage() is not supported for TMAToUMMACircularPipeline."
        )

    def consumer_tail(self) -> NoReturn:
        """Consumer tail - unsupported for circular buffer pipeline."""
        raise NotImplementedError(
            "consumer_tail() is not supported for TMAToUMMACircularPipeline."
        )


class TMAToAsyncPipeline(GenericPipelineBase):
    """
    Pipeline for TMA to * (except UMMA).

    The TMA producer must call :meth:`producer_tail` after its final commit and
    before exiting its producer role.
    """

    @staticmethod
    def create(
        *,
        num_stages: cute.Int32,
        consumer: OperationTypeEnum,
        consumer_arv_count: Optional[cute.Int32] = None,
        consumer_release_threads_per_cta: Optional[cute.Int32] = None,
    ) -> "TMAToAsyncPipeline":
        """
        Create a TMA to * (except UMMA) pipeline.

        The consumer arrival count is given either directly, as
        ``consumer_arv_count``, or derived from the issuing thread count, as
        ``consumer_release_threads_per_cta`` (exactly one).
        """

        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            OperationTypeEnum.SM90_TMA_LOAD,
            consumer,
            # Mirror this class's producer_commit: one warp issues the TMA
            # load with elect_one_sync.
            producer_arv_count=get_arrival_count(
                OperationTypeEnum.SM90_TMA_LOAD,
                consumer,
                side="producer",
                num_threads_per_cta=32,
                elect_one_sync=True,
            ),
            consumer_arv_count=_resolve_arrival_count(
                "consumer",
                arv_count=consumer_arv_count,
                threads_per_cta=consumer_release_threads_per_cta,
                producer=OperationTypeEnum.SM90_TMA_LOAD,
                consumer=consumer,
            ),
        )
        return TMAToAsyncPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
        )

    def producer_commit(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "TMAToAsyncPipeline":
        """Commit producer state."""
        super().producer_commit(elect_one_sync=True)
        return self


class AsyncToUMMAPipeline(GenericPipelineBase):
    """
    Pipeline for * (except TMA) to UMMA.
    """

    @staticmethod
    def create(
        *,
        num_stages: cute.Int32,
        producer: OperationTypeSpec,
        producer_arv_count: Optional[cute.Int32] = None,
        producer_commit_threads_per_cta: Optional[cute.Int32] = None,
        mma_operation_type: OperationDescriptor,
    ) -> "AsyncToUMMAPipeline":
        """
        Create a * (except TMA) to UMMA pipeline.

        Args:
            num_stages: Number of pipeline stages.
            producer: Producer operation type, or a non-empty sequence of
                them when a single pipeline stage is written by multiple
                producer kinds (e.g. ``[store to smem, SM100_COPY_R2T]`` when
                transform warps stage one operand into TMEM and another
                into SMEM under a single producer-commit). Each producer
                kind contributes its own commit-side fence at lowering
                time.
            producer_arv_count: Explicit producer arrival count.
            producer_commit_threads_per_cta: Threads per CTA issuing the
                producer commit; the count is derived via get_arrival_count.
                Exactly one of it or producer_arv_count must be given.
            mma_operation_type: UMMA operation type. An ``MmaOperation(kind,
                operand)`` names the operand (``A``, ``B``, ``C`` or
                ``Metadata``) the MMA reads from the stage buffers.
        """
        _validate_umma_operation_type(
            mma_operation_type,
        )

        if _has_kind(producer, OperationTypeEnum.SM90_TMA_LOAD):
            raise ValueError("TMA to UMMA is not supported.")

        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            producer,
            mma_operation_type,
            producer_arv_count=_resolve_arrival_count(
                "producer",
                arv_count=producer_arv_count,
                threads_per_cta=producer_commit_threads_per_cta,
                producer=producer,
                consumer=mma_operation_type,
            ),
            consumer_arv_count=1,
        )
        return AsyncToUMMAPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
        )

    def consumer_release(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "AsyncToUMMAPipeline":
        """Release consumer state."""
        super().consumer_release(elect_one_sync=True)
        return self


class UMMAtoAsyncPipeline(GenericPipelineBase):
    """
    Pipeline for UMMA to * (except TMA).
    """

    @staticmethod
    def _compute_2sm_tmem_sync_mask() -> cute.Int16:
        """Return the multicast mask for the caller's hardware CTA pair."""
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        pair_leader_rank = cta_rank_in_cluster // 2 * 2
        return cutlass.Int16(0b11) << cutlass.Int16(pair_leader_rank)

    @staticmethod
    def create(
        *,
        num_stages: cute.Int32,
        consumer: OperationTypeSpec,
        consumer_arv_count: Optional[cute.Int32] = None,
        consumer_release_threads_per_cta: Optional[cute.Int32] = None,
        mma_operation_type: OperationDescriptor,
        cluster_layout_vmnk: Optional[cute.Layout] = None,
    ) -> "UMMAtoAsyncPipeline":
        """
        Create a UMMA to * (except TMA) pipeline.

        Prefer ``consumer_release_threads_per_cta``: it is the number of
        threads in each CTA that call ``consumer_release``, and the pipeline
        derives the final mbarrier arrival count, including CTA-pair fan-in.
        For example, 128 releasing threads per CTA derive an arrival count of
        256 for the usual 2SM MMA-to-T2R pipeline because both CTAs release.

        ``consumer_arv_count`` is the legacy explicit-count escape hatch. It
        must already be the final mbarrier arrival count after accounting for
        the signaling topology and is forwarded verbatim without inference.
        Provide exactly one of these two parameters.

        ``cluster_layout_vmnk`` is deprecated and ignored. It is retained for
        source compatibility; for 2SM MMA the pipeline derives the TMEM sync
        mask directly from the caller's cluster-local CTA rank.

        ``mma_operation_type`` may be an ``MmaOperation(kind, MmaOperand.D)``
        naming the operand the producer MMA writes into the guarded buffers.
        """
        _validate_umma_operation_type(
            mma_operation_type,
        )

        if _has_kind(consumer, OperationTypeEnum.SM90_TMA_LOAD):
            raise ValueError("UMMA to TMA is not supported.")

        if _is_2sm_umma_operation_type(mma_operation_type):
            return UMMAtoAsyncPipeline._create_with_mask(
                num_stages=num_stages,
                consumer_type=consumer,
                consumer_arv_count=consumer_arv_count,
                consumer_release_threads_per_cta=consumer_release_threads_per_cta,
                mma_operation_type=mma_operation_type,
            )
        else:  # 1SM MMA
            raw_pipeline, producer_state, consumer_state = create_pipeline(
                num_stages,
                mma_operation_type,
                consumer,
                # Mirror this class's producer_commit: one warp issues the
                # UMMA commit with elect_one_sync.
                producer_arv_count=get_arrival_count(
                    mma_operation_type,
                    consumer,
                    side="producer",
                    num_threads_per_cta=32,
                    elect_one_sync=True,
                ),
                consumer_arv_count=_resolve_arrival_count(
                    "consumer",
                    arv_count=consumer_arv_count,
                    threads_per_cta=consumer_release_threads_per_cta,
                    producer=mma_operation_type,
                    consumer=consumer,
                ),
            )
            return UMMAtoAsyncPipeline(
                raw_pipeline,
                num_stages,
                producer_state,
                consumer_state,
            )

    @staticmethod
    def _create_with_mask(
        *,
        num_stages: cute.Int32,
        consumer_type: OperationTypeEnum,
        consumer_arv_count: Optional[cute.Int32] = None,
        consumer_release_threads_per_cta: Optional[cute.Int32] = None,
        mma_operation_type: OperationDescriptor,
    ) -> "UMMAtoAsyncPipeline":
        """
        Create a UMMA to * pipeline with arrival mask for 2CTA operations.

        The consumer arrival count is given either directly, as
        ``consumer_arv_count``, or derived from the issuing thread count, as
        ``consumer_release_threads_per_cta`` (exactly one).
        """
        tmem_sync_mask = UMMAtoAsyncPipeline._compute_2sm_tmem_sync_mask()
        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            mma_operation_type,
            consumer_type,
            # Mirror this class's producer_commit: one warp issues the UMMA
            # commit with elect_one_sync. The producer arrivals are
            # multicast-masked (the tmem sync mask covers the CTA pair), so
            # the fan-in is not derivable from the pipeline: one issuing CTA
            # pair converges on each barrier in the mask.
            producer_arv_count=get_arrival_count(
                mma_operation_type,
                consumer_type,
                side="producer",
                num_threads_per_cta=32,
                elect_one_sync=True,
                fan_in=1,
            ),
            # The consumer edge does not carry the explicit TMEM sync mask.
            # Its inferred ConvergeCTAPairLeader topology still contributes
            # the CTA-pair fan-in (for example, 128 threads/CTA derives 256).
            consumer_arv_count=_resolve_arrival_count(
                "consumer",
                arv_count=consumer_arv_count,
                threads_per_cta=consumer_release_threads_per_cta,
                producer=mma_operation_type,
                consumer=consumer_type,
            ),
            arrival_mask=tmem_sync_mask,
        )
        return UMMAtoAsyncPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
        )

    def producer_commit(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "UMMAtoAsyncPipeline":
        """Commit producer state."""
        super().producer_commit(elect_one_sync=True)
        return self


@dataclass
class TMAStorePipeline:
    """
    TMA Store Pipeline modeling SMEM producer to TMA consumer pipeline.
    A number of epilogue warps participate in the pipeline as producers, and one of them is designated as the consumer to perform TMA store.
    Named barrier is used to synchronize all warps so that producers write SMEM after the pipeline stage is available, and the consumer waits for all producers before issuing TMA store.
    The canonical pipeline flow is:
    1. acquire_sync(): wait for pipeline stage availability + barrier
    2. Each producer performs SMEM writes
    3. commit_sync(): fence SMEM writes + barrier
    4. Consumer performs TMA store
    5. release_advance(): commit TMA store + advance stage

    Args:
        stages: Number of pipeline stages (type parameter)
        arv_count: Number of threads participating in barriers
        barrier_id: Barrier ID for synchronization
        tma_warp_id: Which warp issues TMA stores (None = no TMA operations)
        index: Initial stage index
    """

    stages: cutlass.Constexpr[int]
    arv_count: int
    barrier_id: int
    tma_warp_id: int
    index: int = 0

    def get_num_stages(self) -> int:
        return self.stages

    def acquire_sync(self) -> "TMAStorePipeline":
        """
        Acquire pipeline stage and synchronize all warps.

        TMA warp waits for previous TMA operation to the same stage to complete (allowing writes to other stages to be in flight).
        All warps then synchronize before producers write to SMEM.
        """

        @cute.jit
        def acquire_sync_impl() -> "TMAStorePipeline":
            # Only TMA warp needs to wait for bulk async operations
            warp_idx = cute.arch.warp_idx()
            warp_idx = cute.arch.make_warp_uniform(warp_idx)

            if warp_idx == self.tma_warp_id:
                # Allow N-1 TMA operations in flight for pipelining
                # Now we can use the compile-time constant from type parameter
                num_stages = self.get_num_stages()
                wait_count = num_stages - 1 if num_stages > 1 else 0
                cute.arch.cp_async_bulk_wait_group(wait_count, read=True)

            # All warps must synchronize before producers write to SMEM
            self._barrier()
            return self

        return acquire_sync_impl()

    def commit_sync(self) -> "TMAStorePipeline":
        """
        Fence SMEM writes and synchronize all warps.

        All warps fence their SMEM writes to make them visible to consumer
        All warps then synchronize before TMA store operation.
        """
        # All warps fence their SMEM writes for TMA visibility
        cute.arch.fence_proxy("async.shared", space="cta")

        # All warps synchronize before TMA store
        self._barrier()
        return self

    def release_advance(self) -> "TMAStorePipeline":
        """
        Release current stage and advance to next stage.

        TMA warp commits the TMA store operations to a bulk group.
        All warps advance to the next pipeline stage.
        """

        @cute.jit
        def release_advance_impl() -> "TMAStorePipeline":
            # Only TMA warp commits the TMA operations
            warp_idx = cute.arch.warp_idx()
            warp_idx = cute.arch.make_warp_uniform(warp_idx)

            if warp_idx == self.tma_warp_id:
                cute.arch.cp_async_bulk_commit_group()

            # All warps advance to next stage
            # The bounded index makes this equivalent to modulo without lowering
            # non-power-of-two stage counts through a reciprocal multiply.
            next_index = self.index + 1
            self.index = 0 if next_index == self.get_num_stages() else next_index
            return self

        return release_advance_impl()

    def get_index(self) -> int:
        """Get current pipeline stage index."""
        # A trace-time index is already uniform; returning it unchanged keeps
        # stage addressing fully static.
        if isinstance(self.index, int):
            return self.index
        # Every participating warp advances the pipeline state identically.
        # Preserve that semantic guarantee when the index is used in address
        # calculations.
        return cute.arch.make_warp_uniform(self.index)

    def tail(self) -> "TMAStorePipeline":
        """
        Wait for all remaining TMA operations to complete.

        Should be called at the end of the pipeline to ensure all TMA stores finish.
        """

        @cute.jit
        def tail_impl() -> "TMAStorePipeline":
            warp_idx = cute.arch.warp_idx()
            warp_idx = cute.arch.make_warp_uniform(warp_idx)

            if warp_idx == self.tma_warp_id:
                # Wait for all TMA operations to complete
                cute.arch.cp_async_bulk_wait_group(0, read=True)

            self._barrier()
            return self

        return tail_impl()

    def _barrier(self) -> None:
        """Synchronize the pipeline barrier."""
        cute.arch.barrier(
            barrier_id=self.barrier_id,
            number_of_threads=self.arv_count,
        )


class GroupedGemmSchedulerPipeline(GenericPipelineBase):
    """
    Pipeline for a dedicated scheduler warp producing tile info into SMEM,
    consumed by all other warps.
    """

    @staticmethod
    def create(
        *,
        num_stages: cute.Int32,
        producer_arv_count: Optional[cute.Int32] = None,
        consumer_arv_count: Optional[cute.Int32] = None,
        producer_commit_threads_per_cta: Optional[cute.Int32] = None,
        consumer_release_threads_per_cta: Optional[cute.Int32] = None,
    ) -> "GroupedGemmSchedulerPipeline":
        """
        Create a grouped gemm scheduler pipeline.

        Each side's arrival count is given either directly, as
        ``producer_arv_count`` / ``consumer_arv_count``, or derived from the
        issuing thread count, as ``producer_commit_threads_per_cta`` /
        ``consumer_release_threads_per_cta`` (exactly one per side).
        """
        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            OperationTypeEnum.SREG_CTAID,
            OperationTypeEnum.LD_SHARED,
            producer_arv_count=_resolve_arrival_count(
                "producer",
                arv_count=producer_arv_count,
                threads_per_cta=producer_commit_threads_per_cta,
                producer=OperationTypeEnum.SREG_CTAID,
                consumer=OperationTypeEnum.LD_SHARED,
            ),
            consumer_arv_count=_resolve_arrival_count(
                "consumer",
                arv_count=consumer_arv_count,
                threads_per_cta=consumer_release_threads_per_cta,
                producer=OperationTypeEnum.SREG_CTAID,
                consumer=OperationTypeEnum.LD_SHARED,
            ),
        )
        return GroupedGemmSchedulerPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
        )

    def consumer_wait(self) -> "GroupedGemmSchedulerPipeline":  # type: ignore[override]
        """Wait for consumer to be ready."""
        consumer_wait(self.raw_pipeline, self.consumer_state)
        return self

    def consumer_release(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "GroupedGemmSchedulerPipeline":
        """Release consumer state."""
        consumer_release(
            self.raw_pipeline,
            self.consumer_state,
            elect_one_sync=elect_one_sync,
            elect_leader_cta=elect_leader_cta,
        )
        return self

    def producer_commit_and_advance(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "GroupedGemmSchedulerPipeline":
        """Commit producer state and advance to next stage."""
        super().producer_commit_and_advance(
            elect_one_sync=elect_one_sync,
            elect_leader_cta=elect_leader_cta,
        )
        return self


class CLCPipeline(GenericPipelineBase):
    """
    Pipeline for tile scheduling (using CLC) to all warps.
    """

    def __init__(
        self,
        raw_pipeline: ir.Value,
        num_stages: cute.Int32,
        producer_state: ir.Value,
        consumer_state: ir.Value,
        response_buffer: "cute.Tensor",
    ) -> None:
        super().__init__(raw_pipeline, num_stages, producer_state, consumer_state)
        self.response_buffer = response_buffer

    def __extract_mlir_values__(self) -> list:
        base_values = super().__extract_mlir_values__()
        return base_values + extract_mlir_values(self.response_buffer)

    @classmethod
    def __new_from_mlir_values__(cls, values: list) -> "CLCPipeline":
        num_stages_dsl = Int32(0).__new_from_mlir_values__([values[1]])  # type: ignore[attr-defined]
        return cls(
            values[0],  # raw_pipeline
            num_stages_dsl,
            values[2],  # producer_state
            values[3],  # consumer_state
            values[4],  # response_buffer
        )

    @staticmethod
    def create(
        *,
        num_stages: cute.Int32,
        consumer_arv_count: Optional[cute.Int32] = None,
        consumer_release_threads_per_cta: Optional[cute.Int32] = None,
        response_buffer: "cute.Tensor",
    ) -> "CLCPipeline":
        """
        Create a CLC to consumer pipeline.

        The consumer includes mma, tma, epilogue, and scheduler. The consumer
        arrival count is given either directly, as ``consumer_arv_count``, or
        derived from the issuing thread count, as
        ``consumer_release_threads_per_cta`` (exactly one).

        :param response_buffer: Multi-stage shared-memory buffer for CLC responses.
            Each stage gets its own slot, indexed by stage index.
        """

        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            OperationTypeEnum.SM100_LAUNCH_CONTROL,
            OperationTypeEnum.LD_SHARED,
            # The CLC producer edge is warp-distributed: the issuing warp
            # lane-distributes one arrive to each CTA's barrier, so each
            # barrier sees num_threads_per_cta / warp_size arrives. This
            # class's producer release is issued by the one full scheduler
            # warp (32 threads, unelected -- an elected lane could not
            # lane-distribute).
            producer_arv_count=get_arrival_count(
                OperationTypeEnum.SM100_LAUNCH_CONTROL,
                OperationTypeEnum.LD_SHARED,
                side="producer",
                num_threads_per_cta=32,
            ),
            consumer_arv_count=_resolve_arrival_count(
                "consumer",
                arv_count=consumer_arv_count,
                threads_per_cta=consumer_release_threads_per_cta,
                producer=OperationTypeEnum.SM100_LAUNCH_CONTROL,
                consumer=OperationTypeEnum.LD_SHARED,
            ),
        )
        return CLCPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
            response_buffer,
        )

    def producer_commit(
        self,
        *,
        elect_one_sync: Optional[bool] = None,
        elect_leader_cta: Optional[bool] = None,
    ) -> "CLCPipeline":
        """Commit producer state."""
        producer_commit(
            self.raw_pipeline,
            self.producer_state,
            elect_one_sync=elect_one_sync,
            elect_leader_cta=elect_leader_cta,
        )
        return self

    def get_response_ptr(self, stage_idx: ir.Value) -> ir.Value:
        """Returns the response pointer for the given stage index."""
        response = cute.slice_(self.response_buffer, stage_idx)
        return response.iterator

    def issue_next(self) -> None:
        """
        Issues a CLC request for the next work tile.

        Emits lir.work_item.issue_next which performs mbarrier.expect_tx
        (fan-out across cluster CTAs) and clusterlaunchcontrol.try.cancel
        in a single elected thread.
        Must be called between producer_acquire and producer_commit.
        """
        token, idx = get_pipeline_produce_stage(self.raw_pipeline, self.producer_state)
        mbar_ptr = get_mbarrier(token).result
        response_ptr = self.get_response_ptr(idx)
        cutlass_lir_ir.WorkItemIssueNextOp(
            mbar_ptr.value, response_ptr.value, elect_one_sync=True
        )


