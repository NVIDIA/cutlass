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

from dataclasses import dataclass
from typing import NoReturn, Optional

import cutlass

import cutlass.cute as cute
from cutlass.base_dsl.typing import Int32
from cutlass._mlir import ir
from cutlass._mlir.dialects import lir as cutlass_lir_ir
from cutlass._mlir.dialects.core import OperationTypeEnum
from cutlass.cute.typing import Boolean
from cutlass.cute.experimental.core import (
    create_pipeline,
    producer_acquire,
    get_pipeline_produce_stage,
    get_pipeline_consume_stage,
    producer_commit,
    consumer_release,
    pipeline_advance_iterator,
    PipelineState,
    consumer_wait,
    consumer_tail,
    create_circular_buffer_pipeline,
    circular_buffer_pipeline_consume,
    circular_buffer_pipeline_consumer_release,
    circular_buffer_pipeline_advance_iterator,
    mbarrier_expect_tx,
    normalize_skip_wait_token,
    producer_try_acquire,
    consumer_try_wait,
    SkipWaitToken,
)

from cutlass.cutlass_dsl import CuteExperimentalDSL

from ..typing import Pointer


class GenericPipelineBase:
    """Base class for pipeline convenience wrappers"""

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

    def producer_acquire(self) -> "GenericPipelineBase":
        """Acquire producer state."""
        producer_acquire(self.raw_pipeline, self.producer_state)
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

    # Instance methods that can now be used directly in kernel context
    def producer_acquire_and_get_stage(
        self, *, token: Optional[SkipWaitToken] = None
    ) -> tuple[ir.Value, ir.Value]:
        """Acquire a producer stage and return its stage token/index.

        When `token` is provided, reuse the preceding `producer_try_acquire()`
        result and keep the internal state at the acquired stage so a following
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

    def producer_commit(self) -> "GenericPipelineBase":
        """Commit producer state."""
        producer_commit(self.raw_pipeline, self.producer_state)
        return self

    def consumer_try_wait(self, *, token: Optional[SkipWaitToken] = None) -> Boolean:
        """Try to wait for the next consumer stage without blocking."""
        return consumer_try_wait(self.raw_pipeline, self.consumer_state, token=token)

    def consumer_release(self) -> "GenericPipelineBase":
        """Release consumer state."""
        consumer_release(self.raw_pipeline, self.consumer_state)
        return self

    def producer_commit_and_advance(self) -> "GenericPipelineBase":
        """Combined producer commit + advance with automatic elect_one using internal state."""
        self.producer_commit()
        # Update internal state in-place for better performance
        self.producer_state = pipeline_advance_iterator(
            self.raw_pipeline, self.producer_state
        )
        return self

    def consumer_wait_and_get_stage(
        self, *, token: Optional[SkipWaitToken] = None
    ) -> tuple[ir.Value, ir.Value]:
        """Wait for a consumer stage and return its stage token/index.

        When `token` is provided, reuse the preceding `consumer_try_wait()`
        result and keep the internal state at the consumed stage so a following
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

    def consumer_wait(
        self, state: Optional[PipelineState] = None
    ) -> "GenericPipelineBase":
        """Wait for consumer to be ready."""
        if state:
            consumer_wait(self.raw_pipeline, state)
        else:
            consumer_wait(self.raw_pipeline, self.consumer_state)
        return self

    def consumer_release_and_advance(self) -> "GenericPipelineBase":
        """Combined consumer release + advance with automatic elect_one using internal state."""
        self.consumer_release()
        # Update internal state in-place for better performance
        self.consumer_state = pipeline_advance_iterator(
            self.raw_pipeline, self.consumer_state
        )
        return self

    def consumer_tail(self) -> "GenericPipelineBase":
        """Combined consumer tail with automatic elect_one using internal state."""
        consumer_tail(self.raw_pipeline, self.consumer_state)
        return self

    def increment_state(self, state: PipelineState) -> ir.Value:
        """Advance the input state w/o modifying current pipeline"""
        return pipeline_advance_iterator(self.raw_pipeline, state)


class GenericPipeline(GenericPipelineBase):
    """
    Generic pipeline for any combination of producer and consumer.
    """

    @staticmethod
    def create(
        *,
        producer: OperationTypeEnum,
        consumer: OperationTypeEnum,
        producer_arv_count: cute.Int32,
        consumer_arv_count: cute.Int32,
        num_stages: cute.Int32,
    ) -> "GenericPipeline":
        """
        Create a generic pipeline with parameterized producer and consumer.

        Args:
            producer: Producer operation type
            consumer: Consumer operation type
            producer_arv_count: Producer arrival count
            consumer_arv_count: Consumer arrival count
            num_stages: Number of pipeline stages
        """
        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            producer,
            consumer,
            producer_arv_count=producer_arv_count,
            consumer_arv_count=consumer_arv_count,
        )

        return GenericPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
        )


def _validate_umma_operation_type(operation_type: OperationTypeEnum) -> None:
    if operation_type not in [
        OperationTypeEnum.SM100_MMA_1SM_SS,
        OperationTypeEnum.SM100_MMA_1SM_TS,
        OperationTypeEnum.SM100_MMA_2SM_SS,
        OperationTypeEnum.SM100_MMA_2SM_TS,
        OperationTypeEnum.SM100_MMA_SCALED_1SM_SS,
        OperationTypeEnum.SM100_MMA_SCALED_1SM_TS,
        OperationTypeEnum.SM100_MMA_SCALED_2SM_SS,
        OperationTypeEnum.SM100_MMA_SCALED_2SM_TS,
    ]:
        raise ValueError(f"Invalid UMMA operation type: {operation_type}")


def _is_2sm_umma_operation_type(operation_type: OperationTypeEnum) -> bool:
    """Check if the operation type is a 2SM UMMA operation."""
    return operation_type in [
        OperationTypeEnum.SM100_MMA_2SM_SS,
        OperationTypeEnum.SM100_MMA_2SM_TS,
        OperationTypeEnum.SM100_MMA_SCALED_2SM_SS,
        OperationTypeEnum.SM100_MMA_SCALED_2SM_TS,
    ]


def _is_multicast_tma_operation_type(operation_type: OperationTypeEnum) -> bool:
    """Check if the operation type is a multicast TMA load."""
    return operation_type in [
        OperationTypeEnum.SM90_TMA_LOAD_MULTICAST,
        OperationTypeEnum.SM100_TMA_LOAD_2SM_MULTICAST,
    ]


class TMAToUMMAPipeline(GenericPipelineBase):
    """
    Pipeline for TMA to UMMA.
    """

    @staticmethod
    def create(
        *,
        num_stages: cute.Int32,
        mma_operation_type: OperationTypeEnum,
        tma_operation_type: Optional[OperationTypeEnum] = None,
        cluster_layout_vmnk: Optional[cute.Layout] = None,
    ) -> "TMAToUMMAPipeline":
        """
        Create a TMA to UMMA pipeline.

        Args:
            num_stages: Number of pipeline stages.
            mma_operation_type: UMMA operation type (e.g., SM100_MMA_1SM_SS).
            tma_operation_type: TMA operation type. Defaults to SM90_TMA_LOAD.
            cluster_layout_vmnk: Cluster layout in (v, m, n, k) order. Required
                whenever the selected TMA load spans more than one CTA, i.e.
                for any 2SM or multicast `tma_operation_type`. This layout is
                the source of truth for CTA identity and v-pair membership. The
                m/n/k dimensions can be dynamic.
        """
        _validate_umma_operation_type(
            mma_operation_type,
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
                producer_arv_count=1,
                consumer_arv_count=1,
                arrival_mask=arrival_mask,
            )
        elif tma_operation_type == OperationTypeEnum.SM90_TMA_LOAD:
            raw_pipeline, producer_state, consumer_state = create_pipeline(
                num_stages,
                tma_operation_type,
                mma_operation_type,
                producer_arv_count=1,
                consumer_arv_count=1,
            )
        else:
            raise ValueError(f"Invalid tma_operation_type: {tma_operation_type}")
        return TMAToUMMAPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
        )

    @staticmethod
    def create_with_mask(
        *,
        num_stages: cute.Int32,
        tma_operation_type: OperationTypeEnum,
        mma_operation_type: OperationTypeEnum,
        cluster_layout_vmnk: cute.Layout,
    ) -> "TMAToUMMAPipeline":
        """Backward-compatible alias. Prefer create(tma_operation_type=...MULTICAST)."""
        return TMAToUMMAPipeline._create_with_multicast_mask(
            num_stages=num_stages,
            tma_operation_type=tma_operation_type,
            mma_operation_type=mma_operation_type,
            cluster_layout_vmnk=cluster_layout_vmnk,
        )

    @staticmethod
    def _create_with_multicast_mask(
        *,
        num_stages: cute.Int32,
        tma_operation_type: OperationTypeEnum,
        mma_operation_type: OperationTypeEnum,
        cluster_layout_vmnk: cute.Layout,
    ) -> "TMAToUMMAPipeline":
        """Internal: compute TMA multicast masks from cluster layout."""
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
        v_size = cute.size(cluster_layout_vmnk.shape[0])  # type: ignore[index]
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
        arrival_mask_c = (
            arrival_mask_a | arrival_mask_a_peer | arrival_mask_b | arrival_mask_b_peer
        )

        num_mcast_ctas_a = cute.size(cluster_layout_vmnk.shape[2])  # type: ignore[index]
        num_mcast_ctas_b = cute.size(cluster_layout_vmnk.shape[1])  # type: ignore[index]
        num_mcast_participants = num_mcast_ctas_a + num_mcast_ctas_b - 1

        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            tma_operation_type,
            mma_operation_type,
            producer_arv_count=1,
            consumer_arv_count=num_mcast_participants,
            arrival_mask=arrival_mask_c,
        )
        return TMAToUMMAPipeline(
            raw_pipeline, num_stages, producer_state, consumer_state
        )

    def producer_commit(self) -> "TMAToUMMAPipeline":
        """
        Commit producer state.

        For 2SM MMA, only leader CTA commits during production as MMA
        is issued by leader. Compiler generates the if-leader-cta-branch
        internally to preserve a symmetric acquire-commit pattern.
        """
        with cute.arch.elect_one():
            super().producer_commit()
        return self

    def consumer_release(self) -> "TMAToUMMAPipeline":
        """Release consumer state."""
        with cute.arch.elect_one():
            super().consumer_release()
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
        mma_operation_type: OperationTypeEnum,
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

    def consumer_release(self) -> "TMAToUMMACircularPipeline":
        """Release consumer state (uses circular buffer consumer release)."""
        with cute.arch.elect_one():
            circular_buffer_pipeline_consumer_release(
                self.raw_pipeline, self.circular_buffer_state
            )
        return self

    def consumer_release_and_advance(self) -> "TMAToUMMACircularPipeline":
        """Combined consumer release + advance using circular buffer semantics."""
        self.consumer_release()
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
    """

    @staticmethod
    def create(
        *,
        num_stages: cute.Int32,
        consumer: OperationTypeEnum,
        consumer_arv_count: cute.Int32,
    ) -> "TMAToAsyncPipeline":
        """
        Create a TMA to * (except UMMA) pipeline.
        """

        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            OperationTypeEnum.SM90_TMA_LOAD,
            consumer,
            producer_arv_count=1,
            consumer_arv_count=consumer_arv_count,
        )
        return TMAToAsyncPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
        )

    def producer_commit(self) -> "TMAToAsyncPipeline":
        """Commit producer state."""
        with cute.arch.elect_one():
            super().producer_commit()
        return self


class AsyncToUMMAPipeline(GenericPipelineBase):
    """
    Pipeline for * (except TMA) to UMMA.
    """

    @staticmethod
    def create(
        *,
        num_stages: cute.Int32,
        producer: OperationTypeEnum,
        producer_arv_count: cute.Int32,
        mma_operation_type: OperationTypeEnum,
    ) -> "AsyncToUMMAPipeline":
        """
        Create a * (except TMA) to UMMA pipeline.
        """
        _validate_umma_operation_type(
            mma_operation_type,
        )

        if producer == OperationTypeEnum.SM90_TMA_LOAD:
            raise ValueError("TMA to UMMA is not supported.")

        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            producer,
            mma_operation_type,
            producer_arv_count=producer_arv_count,
            consumer_arv_count=1,
        )
        return AsyncToUMMAPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
        )

    def consumer_release(self) -> "AsyncToUMMAPipeline":
        """Release consumer state."""
        with cute.arch.elect_one():
            super().consumer_release()
        return self


class UMMAtoAsyncPipeline(GenericPipelineBase):
    """
    Pipeline for UMMA to * (except TMA).
    """

    @staticmethod
    def create(
        *,
        num_stages: cute.Int32,
        consumer: OperationTypeEnum,
        consumer_arv_count: cute.Int32,
        mma_operation_type: OperationTypeEnum,
        cluster_layout_vmnk: Optional[cute.Layout] = None,
    ) -> "UMMAtoAsyncPipeline":
        """
        Create a UMMA to * (except TMA) pipeline.

        For 2SM MMA, provide cluster_layout_vmnk for proper mask computation.
        """
        _validate_umma_operation_type(
            mma_operation_type,
        )

        if consumer == OperationTypeEnum.SM90_TMA_LOAD:
            raise ValueError("UMMA to TMA is not supported.")

        if _is_2sm_umma_operation_type(mma_operation_type):
            if cluster_layout_vmnk is None:
                raise ValueError("cluster_layout_vmnk cannot be None if using 2SM MMA")
            return UMMAtoAsyncPipeline.create_with_mask(
                num_stages=num_stages,
                consumer_type=consumer,
                consumer_arv_count=consumer_arv_count,
                mma_operation_type=mma_operation_type,
                cluster_layout_vmnk=cluster_layout_vmnk,
            )
        else:  # 1SM MMA
            raw_pipeline, producer_state, consumer_state = create_pipeline(
                num_stages,
                mma_operation_type,
                consumer,
                producer_arv_count=1,
                consumer_arv_count=consumer_arv_count,
            )
            return UMMAtoAsyncPipeline(
                raw_pipeline,
                num_stages,
                producer_state,
                consumer_state,
            )

    @staticmethod
    def create_with_mask(
        *,
        num_stages: cute.Int32,
        consumer_type: OperationTypeEnum,
        consumer_arv_count: cute.Int32,
        mma_operation_type: OperationTypeEnum,
        cluster_layout_vmnk: cute.Layout,
    ) -> "UMMAtoAsyncPipeline":
        """
        Create a UMMA to * pipeline with arrival mask for 2CTA operations.
        """
        tmem_sync_mask = cutlass.pipeline.PipelineUmmaAsync._compute_tmem_sync_mask(
            cta_layout_vmnk=cluster_layout_vmnk
        )
        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            mma_operation_type,
            consumer_type,
            producer_arv_count=1,
            consumer_arv_count=consumer_arv_count,
            arrival_mask=tmem_sync_mask,
        )
        return UMMAtoAsyncPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
        )

    def producer_commit(self) -> "UMMAtoAsyncPipeline":
        """Commit producer state."""
        with cute.arch.elect_one():
            super().producer_commit()
        return self


@dataclass
class TMAStorePipeline:
    """
    TMA Store Pipeline modeling SMEM producer (store to smem operations) to TMA consumer (TMA store to global) pipeline.
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
        return self.stages  # type: ignore[return-value]

    def acquire_sync(self) -> "TMAStorePipeline":
        """
        Acquire pipeline stage and synchronize all warps.

        TMA warp waits for previous TMA operation to the same stage to complete (allowing writes to other stages to be in flight).
        All warps then synchronize before producers write to SMEM.
        """

        @CuteExperimentalDSL.jit
        def acquire_sync_impl() -> "TMAStorePipeline":
            # Only TMA warp needs to wait for bulk async operations
            warp_idx = cute.arch.warp_idx()
            warp_idx = cute.arch.make_warp_uniform(warp_idx)

            # Use Python if with @Cutlass_LIR.jit preprocessor
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

        @CuteExperimentalDSL.jit
        def release_advance_impl() -> "TMAStorePipeline":
            # Only TMA warp commits the TMA operations
            warp_idx = cute.arch.warp_idx()
            warp_idx = cute.arch.make_warp_uniform(warp_idx)

            # Use Python if with @Cutlass_LIR.jit preprocessor
            if warp_idx == self.tma_warp_id:
                cute.arch.cp_async_bulk_commit_group()

            # All warps advance to next stage
            self.index = (self.index + 1) % self.get_num_stages()
            return self

        return release_advance_impl()

    def get_index(self) -> int:
        """Get current pipeline stage index."""
        return self.index

    def tail(self) -> "TMAStorePipeline":
        """
        Wait for all remaining TMA operations to complete.

        Should be called at the end of the pipeline to ensure all TMA stores finish.
        """

        @CuteExperimentalDSL.jit
        def tail_impl() -> "TMAStorePipeline":
            warp_idx = cute.arch.warp_idx()
            warp_idx = cute.arch.make_warp_uniform(warp_idx)

            # Use Python if with @Cutlass_LIR.jit preprocessor
            if warp_idx == self.tma_warp_id:
                # Wait for all TMA operations to complete
                cute.arch.cp_async_bulk_wait_group(0, read=True)

            self._barrier()
            return self

        return tail_impl()

    def _barrier(self) -> None:
        """Internal barrier synchronization."""
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
        producer_arv_count: cute.Int32,
        consumer_arv_count: cute.Int32,
    ) -> "GroupedGemmSchedulerPipeline":
        """
        Create a grouped gemm scheduler pipeline.
        """
        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            OperationTypeEnum.SW_STATIC_PERSISTENT_TILE_SCHEDULER,
            OperationTypeEnum.LDS,
            producer_arv_count=producer_arv_count,
            consumer_arv_count=consumer_arv_count,
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

    def consumer_release(self) -> "GroupedGemmSchedulerPipeline":
        """Release consumer state."""
        consumer_release(self.raw_pipeline, self.consumer_state)
        return self

    def producer_commit_and_advance(self) -> "GroupedGemmSchedulerPipeline":
        """Commit producer state and advance to next stage."""
        super().producer_commit_and_advance()
        return self


class CLCPipeline(GenericPipelineBase):
    """
    Pipeline for tile scheduling (using CLC) to all warps.
    """

    @staticmethod
    def create(
        *,
        num_stages: cute.Int32,
        consumer_arv_count: cute.Int32,
    ) -> "CLCPipeline":
        """
        Create a CLC to consumer pipeline.

        The consumer includes mma, tma, epilogue, and scheduler.
        """

        raw_pipeline, producer_state, consumer_state = create_pipeline(
            num_stages,
            OperationTypeEnum.SM100_LAUNCH_CONTROL,
            OperationTypeEnum.LDS,
            producer_arv_count=1,
            consumer_arv_count=consumer_arv_count,
        )
        return CLCPipeline(
            raw_pipeline,
            num_stages,
            producer_state,
            consumer_state,
        )

    def producer_commit(self) -> "CLCPipeline":
        """Commit producer state."""
        producer_commit(self.raw_pipeline, self.producer_state)
        return self

    @staticmethod
    def get_response_size() -> int:
        """
        Returns the size in bytes of a CLC response.
        """
        return 16

    def expect_response(self, mbar_ptr: Pointer) -> None:
        """
        Increments the expected transaction count of a CLC response.
        """
        mbarrier_expect_tx(mbar_ptr, self.get_response_size(), cute.arch.lane_idx())
