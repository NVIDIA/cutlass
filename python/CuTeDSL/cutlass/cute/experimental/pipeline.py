# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# NVIDIA CORPORATION, its affiliates and licensors retain all intellectual
# property and proprietary rights in and to this material, related
# documentation and any modifications thereto. Any use, reproduction,
# disclosure or distribution of this material and related documentation
# without an express license agreement from NVIDIA CORPORATION or
# its affiliates is strictly prohibited.

"""
Convenience pipeline classes that hide elect_one synchronization complexity
"""

from dataclasses import dataclass
from typing import Optional

import cutlass

import cutlass.cute as cute
from cutlass._mlir.dialects import lir as cutlass_lir_ir
from cutlass.base_dsl.typing import Int32
from cutlass._mlir.dialects.core import OperationTypeEnum
from cutlass.cute.experimental.core import (
    create_pipeline,
    create_pipeline_with_mask,
    producer_acquire,
    get_pipeline_produce_stage,
    get_pipeline_consume_stage,
    producer_commit,
    consumer_release,
    pipeline_advance_iterator,
    consumer_wait,
    consumer_tail,
)

from cutlass.cutlass_dsl import CuteExperimentalDSL


class GenericPipelineBase:
    """Base class for pipeline convenience wrappers"""

    def __init__(
        self,
        raw_pipeline,
        num_stages,
        producer_state,
        consumer_state,
    ):
        self.raw_pipeline = raw_pipeline
        self.num_stages = num_stages
        # For convenience class, we always manage state internally
        self.producer_state = producer_state
        self.consumer_state = consumer_state

    def __extract_mlir_values__(self):
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
                num_stages_dsl.__extract_mlir_values__()[0],
            ]
            + producer_state_values
            + consumer_state_values
        )

    @classmethod
    def __new_from_mlir_values__(cls, values):
        """Reconstruct object from MLIR values."""
        # Parse the known structure: [pipeline] + [num_stages, producer_flag, consumer_flag] + [producer_state] + [consumer_state]
        # All lir_* objects are single MLIR values
        raw_pipeline = values[0]  # Always single ir.OpResult
        num_stages_val = values[1]
        producer_state = values[2]  # Always single PipelineState
        consumer_state = values[3]  # Always single PipelineState

        # Create temporary DSL objects and extract Python values
        temp_num_stages = Int32(0)

        num_stages_dsl = temp_num_stages.__new_from_mlir_values__([num_stages_val])

        return cls(
            raw_pipeline,
            (
                num_stages_dsl.value
                if hasattr(num_stages_dsl, "value")
                else int(num_stages_dsl)
            ),
            producer_state,
            consumer_state,
        )

    def producer_acquire(self):
        """Acquire producer state."""
        producer_acquire(self.raw_pipeline, self.producer_state)
        return self

    def get_producer_stage(self):
        """Get producer stage."""
        return get_pipeline_produce_stage(self.raw_pipeline, self.producer_state)

    def get_consumer_stage(self):
        """Get consumer stage."""
        return get_pipeline_consume_stage(self.raw_pipeline, self.consumer_state)

    # Instance methods that can now be used directly in kernel context
    def producer_acquire_and_get_stage(self):
        """Combined producer acquire + get_stage with automatic elect_one using internal state."""

        self.producer_acquire()
        return get_pipeline_produce_stage(self.raw_pipeline, self.producer_state)

    def producer_commit(self):
        """Commit producer state."""
        producer_commit(self.raw_pipeline, self.producer_state)
        return self

    def consumer_release(self):
        """Release consumer state."""
        consumer_release(self.raw_pipeline, self.consumer_state)
        return self

    def producer_commit_and_advance(self):
        """Combined producer commit + advance with automatic elect_one using internal state."""
        self.producer_commit()
        # Update internal state in-place for better performance
        self.producer_state = pipeline_advance_iterator(
            self.raw_pipeline, self.producer_state
        )
        return self

    def consumer_wait_and_get_stage(self):
        """Combined consumer wait + get_stage with automatic elect_one using internal state."""
        self.consumer_wait()
        return get_pipeline_consume_stage(self.raw_pipeline, self.consumer_state)

    def consumer_wait(self):
        """Wait for consumer to be ready."""
        consumer_wait(self.raw_pipeline, self.consumer_state)
        return self

    def consumer_release_and_advance(self):
        """Combined consumer release + advance with automatic elect_one using internal state."""
        self.consumer_release()
        # Update internal state in-place for better performance
        self.consumer_state = pipeline_advance_iterator(
            self.raw_pipeline, self.consumer_state
        )
        return self

    def consumer_tail(self):
        """Combined consumer tail with automatic elect_one using internal state."""
        consumer_tail(self.raw_pipeline, self.consumer_state)
        return self


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
    ):
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


def _validate_umma_operation_type(operation_type: OperationTypeEnum):
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
    ):
        """
        Create a TMA to UMMA pipeline.

        For 2SM MMA with TMA_LOAD_2SM, provide cluster_layout_vmnk for proper mask computation.
        """
        _validate_umma_operation_type(
            mma_operation_type,
        )

        # Default to SM90_TMA_LOAD if not specified
        if tma_operation_type is None:
            tma_operation_type = OperationTypeEnum.SM90_TMA_LOAD

        if tma_operation_type == OperationTypeEnum.SM100_TMA_LOAD_2SM:
            if cluster_layout_vmnk is None:
                raise ValueError(
                    "cluster_layout_vmnk is required if using 2CTA MMA with TMA"
                )

            # If using 2CTA MMA, need consumer_mask == local_cta | peer_cta
            cta_rank_in_cluster = cute.arch.make_warp_uniform(
                cute.arch.block_idx_in_cluster()
            )
            cta_in_cluster_coord_vmnk = cluster_layout_vmnk.get_flat_coord(
                cta_rank_in_cluster
            )
            arrival_mask = cute.make_layout_image_mask(
                cluster_layout_vmnk, cta_in_cluster_coord_vmnk, mode=0
            )

            raw_pipeline, producer_state, consumer_state = create_pipeline_with_mask(
                num_stages,
                tma_operation_type,
                mma_operation_type,
                producer_arv_count=1,
                consumer_arv_count=1,
                arrival_mask=arrival_mask,
            )
        else:
            raw_pipeline, producer_state, consumer_state = create_pipeline(
                num_stages,
                tma_operation_type,
                mma_operation_type,
                producer_arv_count=1,
                consumer_arv_count=1,
            )
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
    ):
        """
        Create a TMA to UMMA pipeline with multicast mask for 2CTA operations.
        """
        _validate_umma_operation_type(
            mma_operation_type,
        )

        # Calculate TMA multicasting masks
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
        v_size = cute.size(cluster_layout_vmnk.shape[0])
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

        num_mcast_ctas_a = cute.size(cluster_layout_vmnk.shape[2])
        num_mcast_ctas_b = cute.size(cluster_layout_vmnk.shape[1])
        num_mcast_participants = num_mcast_ctas_a + num_mcast_ctas_b - 1

        raw_pipeline, producer_state, consumer_state = create_pipeline_with_mask(
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

    def producer_commit(self):
        """Commit producer state."""
        with cute.arch.elect_one():
            super().producer_commit()
        return self

    def consumer_release(self):
        """Release consumer state."""
        with cute.arch.elect_one():
            super().consumer_release()
        return self


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
    ):
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

    def producer_commit(self):
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
    ):
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

    def consumer_release(self):
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
    ):
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
    ):
        """
        Create a UMMA to * pipeline with arrival mask for 2CTA operations.
        """
        tmem_sync_mask = cutlass.pipeline.PipelineUmmaAsync._compute_tmem_sync_mask(
            cta_layout_vmnk=cluster_layout_vmnk
        )
        raw_pipeline, producer_state, consumer_state = create_pipeline_with_mask(
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

    def producer_commit(self):
        """Commit producer state."""
        with cute.arch.elect_one():
            super().producer_commit()
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

    def get_num_stages(self):
        return self.stages

    def acquire_sync(self):
        """
        Acquire pipeline stage and synchronize all warps.

        TMA warp waits for previous TMA operation to the same stage to complete (allowing writes to other stages to be in flight).
        All warps then synchronize before producers write to SMEM.
        """

        @CuteExperimentalDSL.jit
        def acquire_sync_impl():
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

    def commit_sync(self):
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

    def release_advance(self):
        """
        Release current stage and advance to next stage.

        TMA warp commits the TMA store operations to a bulk group.
        All warps advance to the next pipeline stage.
        """

        @CuteExperimentalDSL.jit
        def release_advance_impl():
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

    def get_index(self):
        """Get current pipeline stage index."""
        return self.index

    def tail(self):
        """
        Wait for all remaining TMA operations to complete.

        Should be called at the end of the pipeline to ensure all TMA stores finish.
        """

        @CuteExperimentalDSL.jit
        def tail_impl():
            warp_idx = cute.arch.warp_idx()
            warp_idx = cute.arch.make_warp_uniform(warp_idx)

            # Use Python if with @Cutlass_LIR.jit preprocessor
            if warp_idx == self.tma_warp_id:
                # Wait for all TMA operations to complete
                cute.arch.cp_async_bulk_wait_group(0, read=True)

            self._barrier()
            return self

        return tail_impl()

    def _barrier(self):
        """Internal barrier synchronization."""
        cute.arch.barrier(
            barrier_id=self.barrier_id,
            number_of_threads=self.arv_count,
        )
