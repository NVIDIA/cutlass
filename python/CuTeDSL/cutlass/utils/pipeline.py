# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

import enum
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Optional

from cutlass.cutlass_dsl import Boolean, Int32, Int64, T, if_generate, and_, or_

import cutlass._mlir.dialects.cute as _cute_ir

import cutlass.cute as cute


##############################################################################
# Agent class
##############################################################################


class Agent(enum.Enum):
    """
    Agent indicates what is participating in the pipeline synchronization.
    """

    # Arbitrary grouping of N threads
    Thread = enum.auto()
    # Same as AsyncThread, but includes all threads in the block
    ThreadBlock = enum.auto()
    # Same as AsyncThread, but includes all threads in the cluster
    ThreadBlockCluster = enum.auto()


class CooperativeGroup:
    """
    CooperativeGroup contains size and alignment restrictions for an Agent.
    """

    def __init__(self, agent: Agent, size: int = 1, alignment: int = 1):
        if agent is Agent.Thread:
            assert size > 0
            if size == 32:
                assert (
                    size == alignment
                ), "Error: Alignment does not match number of threads in a warp."
            elif size == 128:
                assert (
                    size == alignment
                ), "Error: Alignment does not match number of threads in a warpgroup."
        elif agent is Agent.ThreadBlock:
            assert False, "Error: Not yet supported."
        elif agent is Agent.ThreadBlockCluster:
            assert False, "Error: Not yet supported."
        else:
            # Should never reach this state
            size = 0

        if size <= 0:
            raise ValueError(
                "Error: The number of threads in a CooperativeGroup must be more than 0."
            )

        # Size indicates how many threads are participating in this CooperativeGroup
        self.size = size
        # Agent indicates the type of thread group
        self.agent = agent


class _PipelineOp(enum.Enum):
    """
    PipelineOp assigns an operation to an agent corresponding to a specific hardware feature.
    """

    # async-threads
    AsyncThread = enum.auto()
    # Blackwell (SM100a) MMA instruction
    TCGen05Mma = enum.auto()
    # Tensor Memory Accelerator load
    TmaLoad = enum.auto()
    # TMA Store consuming smem produced by AsyncThread
    TmaStore = enum.auto()


def _get_pipeline_op(type_str):
    return _PipelineOp(type_str)


##############################################################################
# SyncObjectArray class
##############################################################################


class SyncObjectArray(ABC):
    """
    SyncObjectArray is an abstract base class for different types of hardware synchronizations (e.g. smem barriers, named barriers, fences)
    """

    @abstractmethod
    def wait(self):
        pass

    @abstractmethod
    def arrive(self):
        pass

    @abstractmethod
    def get_barrier(self):
        pass


class MbarrierArray(SyncObjectArray):
    """
    MbarrierArray implements an abstraction for an array of smem barriers.
    """

    def __init__(
        self,
        barrier_storage: cute.Pointer,
        num_stages: int,
        agent: tuple[_PipelineOp, CooperativeGroup],
        tx_count: int = 0,
    ):
        self.barrier_storage = barrier_storage
        self.tx_count = tx_count
        self.num_stages = num_stages
        self.op_type, self.cg = agent
        self.arrive_count = self.cg.size

        if self.num_stages <= 0:
            raise ValueError("Error: Mbarrier stage count must be greater than 0.")
        if self.arrive_count <= 0:
            raise ValueError("Error: Mbarrier arrive count must be greater than 0.")
        if self.op_type is _PipelineOp.TmaLoad and self.tx_count <= 0:
            raise ValueError(
                "Error: Mbarrier tx count must be greater than 0 for TMA ops."
            )

        # Store mbarrier base pointer
        self.mbarrier_base = self.barrier_storage

        # Mbarrier initialization in constructor
        self.mbarrier_init()

    # Mbarrier initialization
    def mbarrier_init(self):
        """
        Initializes an array of mbarriers using warp 0.
        """

        def then_body():
            for index in range(self.num_stages):
                cute.arch.mbarrier_init_arrive_cnt(
                    self.get_barrier(index), self.arrive_count
                )

        warp_idx = cute.arch.warp_idx()
        warp_idx = cute.arch.make_warp_uniform(warp_idx)

        if_generate(warp_idx == 0, then_body)

    def arrive(
        self,
        index: int,
        dst: int,
        cta_group: Optional[cute.nvgpu.tcgen05.CtaGroup] = None,
    ):
        """
        Select the arrive corresponding to this MbarrierArray's PipelineOp
        :param index: Index of the mbarrier in the array to arrive on
        :type index: int
        :param dst: Destination parameter for selective arrival, which can be either a mask or destination cta rank. When None, both TCGen05Mma and AsyncThread will arrive on their local mbarrier.
        - For TCGen05Mma, dst serves as a multicast mask (e.g., 0b1011 allows arrive signal to be multicast to CTAs in the cluster with rank = 0, 1, and 3).
        - For AsyncThread, dst serves as a destination cta rank (e.g., 3 means threads will arrive on the mbarrier with rank = 3 in the cluster).
        :type dst: int | None
        :param cta_group: CTA group for TCGen05Mma, defaults to None for other op types
        :type cta_group: cute.nvgpu.tcgen05.CtaGroup, optional
        """
        if self.op_type is _PipelineOp.AsyncThread:
            self.arrive_mbarrier(index, dst)
        elif self.op_type is _PipelineOp.TCGen05Mma:
            assert (
                cta_group is not None
            ), "Error: CTA group must be provided for TCGen05Mma."
            self.arrive_tcgen05mma(index, dst, cta_group)
        elif self.op_type in [_PipelineOp.TmaLoad]:
            self.arrive_and_expect_tx(index, self.tx_count)
        else:
            assert False, f"Error: MbarrierArray is not supported for PipelineOp: {_get_pipeline_op(self.op_type)}."

    def arrive_mbarrier(self, index: int, dst_rank: int):
        if dst_rank is None:
            cute.arch.mbarrier_arrive(self.get_barrier(index))
        else:
            cute.arch.mbarrier_arrive(self.get_barrier(index), dst_rank)

    def arrive_tcgen05mma(
        self, index: int, mask: int, cta_group: cute.nvgpu.tcgen05.CtaGroup
    ):
        if mask is None:
            with cute.arch.elect_one():
                cute.nvgpu.tcgen05.commit(self.get_barrier(index))
        else:
            with cute.arch.elect_one():
                cute.nvgpu.tcgen05.commit(
                    self.get_barrier(index),
                    mask,
                    cta_group,
                )

    def arrive_and_expect_tx(self, index: int, tx_count: int):
        with cute.arch.elect_one():
            cute.arch.mbarrier_init_tx_bytes(self.get_barrier(index), tx_count)

    def try_wait(self, index: int, phase: int):
        return cute.arch.mbarrier_try_wait(self.get_barrier(index), phase)

    def wait(self, index: int, phase: int):
        cute.arch.mbarrier_wait(self.get_barrier(index), phase)

    def get_barrier(self, index: int) -> cute.Pointer:
        return self.mbarrier_base + index


class TmaStoreFence(SyncObjectArray):
    """
    TmaStoreFence is used for a multi-stage epilogue buffer.
    """

    def __init__(
        self,
        num_stages: int = 0,
    ):
        if num_stages <= 0:
            raise ValueError("Mbarrier stage count must be greater than 0.")

        self.num_stages = num_stages

    def arrive(self):
        cute.arch.cp_async_bulk_commit_group()

    def wait(self):
        cute.arch.cp_async_bulk_wait_group(self.num_stages - 1, read=True)

    # TmaStoreFence doesn't have mbarriers
    def get_barrier(self):
        assert (
            False
        ), "Error: TmaStoreFence doesn't use mbarriers and cannot return a barrier."

    def tail(self):
        cute.arch.cp_async_bulk_wait_group(0, read=True)


##############################################################################
# PipelineState class
##############################################################################


class PipelineUserType(enum.Enum):
    Producer = enum.auto()
    Consumer = enum.auto()


class PipelineState:
    """
    Pipeline state contains an index and phase bit corresponding to the current position in the circular buffer.
    """

    def __init__(self, stages: int, count, index, phase):
        self._stages = stages
        self._count = count
        self._index = index
        self._phase = phase

    def clone(self) -> "PipelineState":
        return PipelineState(self.stages, self._count, self.index, self.phase)

    @property
    def index(self) -> Int32:
        return self._index

    @property
    def count(self) -> Int32:
        return self._count

    @property
    def stages(self) -> int:
        return self._stages

    @property
    def phase(self) -> Int32:
        return self._phase

    def reset_count(self):
        self._count = Int32(0)

    def advance(self):
        self._index += 1
        self._count += 1

        def then_body(index, phase):
            new_index = Int32(0)
            new_phase = phase ^ 1
            return new_index, new_phase

        def else_body(index, phase):
            return index, phase

        self._index, self._phase = if_generate(
            self._index == self.stages,
            then_body,
            else_body,
            [self.index, self.phase],
            [Int32, Int32],
        )

    def reverse(self):
        self._index -= 1
        self._count -= 1

        def then_body(index, phase):
            new_index = Int32(self.stages - 1)
            new_phase = phase ^ 1
            return new_index, new_phase

        def else_body(index, phase):
            return index, phase

        self._index, self._phase = if_generate(
            self._index == -1,
            then_body,
            else_body,
            [self.index, self.phase],
            [Int32, Int32],
        )

    def __get_mlir_types__(self):
        return [self._count.type, self._index.type, self._phase.type]

    def __extract_mlir_values__(self):
        count = self._count
        index = self._index
        phase = self._phase
        return [count.ir_value(), index.ir_value(), phase.ir_value()]

    # This can be overridden by derived classes
    def __new_from_mlir_values__(self, values):
        return PipelineState(
            self.stages, Int32(values[0]), Int32(values[1]), Int32(values[2])
        )


def make_pipeline_state(type: PipelineUserType, stages: int):
    """
    Creates a pipeline state. Producers are assumed to start with an empty buffer and have a flipped phase bit of 1.
    """
    if type is PipelineUserType.Producer:
        return PipelineState(
            stages,
            Int32(0),
            Int32(0),
            Int32(1),
        )
    elif type is PipelineUserType.Consumer:
        return PipelineState(
            stages,
            Int32(0),
            Int32(0),
            Int32(0),
        )
    else:
        assert (
            False
        ), "Error: invalid PipelineUserType specified for make_pipeline_state."


##############################################################################
# Pipeline classes
##############################################################################


@dataclass(frozen=True)
class PipelineAsync:
    """
    PipelineAsync is a generic pipeline class where both the producer and consumer are
    AsyncThreads. It also serves as a base class for specialized pipeline classes.
    """

    sync_object_array_full: SyncObjectArray
    sync_object_array_empty: SyncObjectArray
    num_stages: Int32
    producer_mask: Int32
    consumer_mask: Int32

    @staticmethod
    def _make_sync_object_array(
        barrier_storage: cute.Pointer,
        num_stages: Int32,
        agent: tuple[_PipelineOp, CooperativeGroup],
        tx_count: int = 0,
    ) -> SyncObjectArray:
        """
        Returns a SyncObjectArray corresponding to an agent's PipelineOp.
        """
        if agent[0] in [
            _PipelineOp.AsyncThread,
            _PipelineOp.TmaLoad,
            _PipelineOp.TCGen05Mma,
        ]:
            return MbarrierArray(
                barrier_storage=barrier_storage,
                num_stages=num_stages,
                agent=agent,
                tx_count=tx_count,
            )
        elif agent[0] is _PipelineOp.TmaStore:
            # Path taken for AsyncTmaStore
            return TmaStoreFence(num_stages=num_stages)
        else:
            assert False, "Error: Invalid PipelineOp specified."

    @staticmethod
    def create(
        barrier_storage: cute.Pointer,
        num_stages: Int32,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        producer_mask: Int32 = None,
        consumer_mask: Int32 = None,
    ):
        """
        This helper function computes any necessary attributes and returns an instance of PipelineAsync.
        :param barrier_storage: Pointer to the smem address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer
        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: Int32
        :param producer_group: CooperativeGroup for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group: CooperativeGroup for the consumer agent
        :type consumer_group: CooperativeGroup
        :param producer_mask: Mask for signaling arrives for the producer agent
        :type producer_mask: Int32 | None
        :param consumer_mask: Mask for signaling arrives for the consumer agent
        :type consumer_mask: Int32 | None
        """
        producer_type = _PipelineOp.AsyncThread
        consumer_type = _PipelineOp.AsyncThread

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_array_full = PipelineAsync._make_sync_object_array(
            barrier_storage.align(min_align=8), num_stages, producer
        )
        sync_object_array_empty = PipelineAsync._make_sync_object_array(
            barrier_storage.align(min_align=8) + num_stages, num_stages, consumer
        )

        pipeline_init_wait()

        return PipelineAsync(
            sync_object_array_full,
            sync_object_array_empty,
            num_stages,
            producer_mask,
            consumer_mask,
        )

    def producer_acquire(
        self, state: PipelineState, try_acquire_token: Optional[Boolean] = None
    ):
        if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_array_empty.wait(state.index, state.phase),
        )

    def producer_try_acquire(self, state: PipelineState):
        return self.sync_object_array_empty.try_wait(state.index, state.phase)

    def producer_commit(self, state: PipelineState):
        self.sync_object_array_full.arrive(state.index, self.producer_mask)

    def consumer_wait(
        self, state: PipelineState, try_wait_token: Optional[Boolean] = None
    ):
        if_generate(
            try_wait_token is None or try_wait_token == 0,
            lambda: self.sync_object_array_full.wait(state.index, state.phase),
        )

    def consumer_try_wait(self, state: PipelineState):
        return self.sync_object_array_full.try_wait(state.index, state.phase)

    def consumer_release(self, state: PipelineState):
        self.sync_object_array_empty.arrive(state.index, self.consumer_mask)

    def producer_get_barrier(self, state: PipelineState) -> cute.Pointer:
        return self.sync_object_array_full.get_barrier(state.index)

    def producer_tail(self, state: PipelineState):
        """
        Make sure the last used buffer empty signal is visible to producer.
        Producer tail is usually executed by producer before exit, to avoid dangling
        mbarrier arrive signals after kernel exit.

        :param state: The pipeline state that points to next useful buffer
        :type state: PipelineState
        """
        # Assume state contains that next useful buffer
        # So we only need to advance to num_stages - 1 times to last used buffer
        for i in range(self.num_stages - 1):
            state.advance()
        self.producer_acquire(state)


@dataclass(frozen=True)
class PipelineTmaAsync(PipelineAsync):
    """
    PipelineTmaAsync is used for TMA producers and AsyncThread consumers (e.g. Hopper mainloops).
    """

    is_signalling_thread: bool

    @staticmethod
    def init_empty_barrier_arrive_signal(cta_layout_vmnk: cute.Layout):
        """
        Initialize the empty barrier arrive signal
        This function returns the destination cta rank and a boolean indicating if the signalling thread is the same as the current thread
        """
        # Logic to optimally schedule Empty Arrives
        cluster_shape_mnk = cta_layout_vmnk.shape
        tidx, _, _ = cute.arch.thread_idx()
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )

        is_signalling_thread = tidx < cute.size(cluster_shape_mnk)
        dst_rank = tidx % cute.size(cluster_shape_mnk)
        m = cluster_shape_mnk[0]

        # Check if same row
        is_same_row_l = dst_rank % m
        is_same_row_r = cta_rank_in_cluster % m
        is_same_row = is_same_row_l == is_same_row_r

        # Check if same column
        is_same_col_l = dst_rank // m
        is_same_col_r = cta_rank_in_cluster // m

        is_same_col = is_same_col_l == is_same_col_r

        is_same_row_or_col = or_(is_same_row, is_same_col)
        is_signalling_thread_final = and_(is_signalling_thread, is_same_row_or_col)

        return dst_rank, is_signalling_thread_final

    @staticmethod
    def create(
        barrier_storage: cute.Pointer,
        num_stages: Int32,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        tx_count: int,
        cta_layout_vmnk: Optional[cute.Layout] = None,
    ):
        """
        This helper function computes any necessary attributes and returns an instance of PipelineTmaAsync.
        :param barrier_storage: Pointer to the smem address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer
        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: Int32
        :param producer_group: CooperativeGroup for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group: CooperativeGroup for the consumer agent
        :type consumer_group: CooperativeGroup
        :param tx_count: Number of bytes expected to be written to the transaction barrier for one stage
        :type tx_count: int
        :param cta_layout_vmnk: Layout of the cluster shape
        :type cta_layout_vmnk: cute.Layout | None
        """
        producer_type = _PipelineOp.TmaLoad
        consumer_type = _PipelineOp.AsyncThread

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_array_full = PipelineAsync._make_sync_object_array(
            barrier_storage.align(min_align=8), num_stages, producer, tx_count
        )
        sync_object_array_empty = PipelineAsync._make_sync_object_array(
            barrier_storage.align(min_align=8) + num_stages, num_stages, consumer
        )

        dst_rank, is_signalling_thread = (
            PipelineTmaAsync.init_empty_barrier_arrive_signal(cta_layout_vmnk)
        )
        if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
            dst_rank = None
        else:
            dst_rank = dst_rank

        is_signalling_thread = is_signalling_thread
        producer_mask = None

        pipeline_init_wait(cta_layout_vmnk)

        return PipelineTmaAsync(
            sync_object_array_full,
            sync_object_array_empty,
            num_stages,
            producer_mask,
            dst_rank,
            is_signalling_thread,
        )

    def producer_acquire(
        self, state: PipelineState, try_acquire_token: Optional[Boolean] = None
    ):
        """
        TMA producer commit conditionally waits on buffer empty and sets the transaction barrier for leader threadblocks.
        """
        if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_array_empty.wait(state.index, state.phase),
        )
        self.sync_object_array_full.arrive(state.index, self.producer_mask)

    def producer_commit(self, state: PipelineState):
        """
        TMA producer commit is a NOP. The transaction barrier signals the commit upon completion of the TMA.
        """
        pass

    def consumer_release(self, state: PipelineState):
        """
        TMA consumer release conditionally signals the empty buffer to the producer.
        """
        if_generate(
            self.is_signalling_thread,
            lambda: self.sync_object_array_empty.arrive(
                state.index, self.consumer_mask
            ),
        )


@dataclass(frozen=True)
class PipelineTmaUmma(PipelineAsync):
    """
    PipelineTmaUmma is used for TMA producers and UMMA consumers (e.g. Blackwell mainloops).
    """

    is_leader_cta: bool
    cta_group: cute.nvgpu.tcgen05.CtaGroup

    @staticmethod
    def _compute_mcast_arrival_mask(cta_layout_vmnk: cute.Layout):
        """
        Computes a mask for signaling arrivals to multicasting threadblocks.
        """
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cta_in_cluster_coord_vmnk = cta_layout_vmnk.get_flat_coord(cta_rank_in_cluster)

        tma_mcast_mask_a = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cta_layout_vmnk, cta_in_cluster_coord_vmnk, mcast_mode=2
        )
        tma_mcast_mask_b = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cta_layout_vmnk, cta_in_cluster_coord_vmnk, mcast_mode=1
        )

        block_in_cluster_coord_vmnk_peer = (
            cta_in_cluster_coord_vmnk[0] ^ 1,
            *cta_in_cluster_coord_vmnk[1:],
        )
        tma_mcast_mask_a_peer = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cta_layout_vmnk, block_in_cluster_coord_vmnk_peer, mcast_mode=2
        )
        tma_mcast_mask_b_peer = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cta_layout_vmnk, block_in_cluster_coord_vmnk_peer, mcast_mode=1
        )
        return (
            tma_mcast_mask_a
            | tma_mcast_mask_b
            | tma_mcast_mask_a_peer
            | tma_mcast_mask_b_peer
        )

    @staticmethod
    def _compute_is_leader_cta(cta_layout_vmnk: cute.Layout):
        """
        Computes leader threadblocks for 2CTA kernels. For 1CTA, all threadblocks are leaders.
        """
        bidx, bidy, _ = cute.arch.block_idx()

        mma_coord_vmnk = (
            bidx % cute.size(cta_layout_vmnk, mode=[0]),
            bidx // cute.size(cta_layout_vmnk, mode=[0]),
            bidy,
            None,
        )
        return mma_coord_vmnk[0] == 0

    @staticmethod
    def create(
        barrier_storage: cute.Pointer,
        num_stages: Int32,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        tx_count: int,
        cta_layout_vmnk: Optional[cute.Layout] = None,
    ):
        """
        This helper function computes any necessary attributes and returns an instance of PipelineTmaUmma.
        :param barrier_storage: Pointer to the smem address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer
        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: Int32
        :param producer_group: CooperativeGroup for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group: CooperativeGroup for the consumer agent
        :type consumer_group: CooperativeGroup
        :param tx_count: Number of bytes expected to be written to the transaction barrier for one stage
        :type tx_count: int
        :param cta_layout_vmnk: Layout of the cluster shape
        :type cta_layout_vmnk: cute.Layout | None
        """
        producer_type = _PipelineOp.TmaLoad
        consumer_type = _PipelineOp.TCGen05Mma

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_array_full = PipelineAsync._make_sync_object_array(
            barrier_storage.align(min_align=8), num_stages, producer, tx_count
        )
        sync_object_array_empty = PipelineAsync._make_sync_object_array(
            barrier_storage.align(min_align=8) + num_stages, num_stages, consumer
        )

        if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
            # No mcast mask if not using clusters
            producer_mask = None
            # All threadblocks are leaders if not using clusters
            is_leader_cta = True
        else:
            producer_mask = PipelineTmaUmma._compute_mcast_arrival_mask(cta_layout_vmnk)
            is_leader_cta = PipelineTmaUmma._compute_is_leader_cta(cta_layout_vmnk)

        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, mode=[0]) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )

        consumer_mask = producer_mask

        pipeline_init_wait(cta_layout_vmnk)

        return PipelineTmaUmma(
            sync_object_array_full,
            sync_object_array_empty,
            num_stages,
            producer_mask,
            consumer_mask,
            is_leader_cta,
            cta_group,
        )

    def consumer_release(self, state: PipelineState):
        """
        UMMA consumer release buffer empty, cta_group needs to be provided.
        """
        self.sync_object_array_empty.arrive(
            state.index, self.consumer_mask, self.cta_group
        )

    def producer_acquire(
        self, state: PipelineState, try_acquire_token: Optional[Boolean] = None
    ):
        """
        TMA producer commit conditionally waits on buffer empty and sets the transaction barrier for leader threadblocks.
        """
        if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_array_empty.wait(state.index, state.phase),
        )
        if_generate(
            self.is_leader_cta,
            lambda: self.sync_object_array_full.arrive(state.index, self.producer_mask),
        )

    def producer_commit(self, state: PipelineState):
        """
        TMA producer commit is a NOP. The transaction barrier signals the commit upon completion of the TMA.
        """
        pass


@dataclass(frozen=True)
class PipelineUmmaAsync(PipelineAsync):
    """
    PipelineTmaUmma is used for UMMA producers and AsyncThread consumers (e.g. Blackwell accumulator pipelines).
    """

    cta_group: cute.nvgpu.tcgen05.CtaGroup

    @staticmethod
    def _compute_tmem_sync_mask(cta_layout_vmnk: cute.Layout):
        """
        Computes a mask to signal completion of tmem buffers for 2CTA kernels.
        """
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        cta_in_cluster_coord_vmnk = cta_layout_vmnk.get_flat_coord(cta_rank_in_cluster)
        return cute.make_layout_image_mask(
            cta_layout_vmnk, cta_in_cluster_coord_vmnk, mode=0
        )

    @staticmethod
    def _compute_peer_cta_rank():
        """
        Computes a mask to signal release of tmem buffers for 2CTA kernels.
        """
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        return cta_rank_in_cluster // 2 * 2

    @staticmethod
    def create(
        barrier_storage: cute.Pointer,
        num_stages: Int32,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        cta_layout_vmnk: Optional[cute.Layout] = None,
    ):
        """
        This helper function computes any necessary attributes and returns an instance of PipelineUmmaAsync.
        :param barrier_storage: Pointer to the smem address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer
        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: Int32
        :param producer_group: CooperativeGroup for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group: CooperativeGroup for the consumer agent
        :type consumer_group: CooperativeGroup
        :param cta_layout_vmnk: Layout of the cluster shape
        :type cta_layout_vmnk: cute.Layout | None
        """
        producer_type = _PipelineOp.TCGen05Mma
        consumer_type = _PipelineOp.AsyncThread

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_array_full = PipelineAsync._make_sync_object_array(
            barrier_storage.align(min_align=8), num_stages, producer
        )
        sync_object_array_empty = PipelineAsync._make_sync_object_array(
            barrier_storage.align(min_align=8) + num_stages, num_stages, consumer
        )

        if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
            # Set mask to None if not using clusters (i.e. 1CTA kernels)
            producer_mask = None
        else:
            producer_mask = PipelineUmmaAsync._compute_tmem_sync_mask(cta_layout_vmnk)

        if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, mode=[0]) == 1:
            # Set mask to None if not using 2CTA intructions
            consumer_mask = None
        else:
            consumer_mask = PipelineUmmaAsync._compute_peer_cta_rank()

        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, mode=[0]) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )

        pipeline_init_wait(cta_layout_vmnk)

        return PipelineUmmaAsync(
            sync_object_array_full,
            sync_object_array_empty,
            num_stages,
            producer_mask,
            consumer_mask,
            cta_group,
        )

    def producer_commit(self, state: PipelineState):
        """
        UMMA producer commit buffer full, cta_group needs to be provided.
        """
        self.sync_object_array_full.arrive(
            state.index, self.producer_mask, self.cta_group
        )

    def producer_tail(self, state: PipelineState):
        """
        Make sure the last used buffer empty signal is visible to producer.
        Producer tail is usually executed by producer before exit, to avoid dangling
        mbarrier arrive signals after kernel exit.

        :param state: The pipeline state that points to next useful buffer
        :type state: PipelineState
        """
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        is_leader_cta = cta_rank_in_cluster % 2 == 0

        def then_body():
            # Assume state contains that next useful buffer
            # So we only need to advance to num_stages - 1 times to last used buffer
            for i in range(self.num_stages - 1):
                state.advance()
            self.producer_acquire(state)

        if_generate(is_leader_cta, then_body)


@dataclass(frozen=True)
class PipelineTmaStore(PipelineAsync):
    """
    PipelineTmaStore is used for synchronizing TMA stores in the epilogue. It does not use mbarriers.
    """

    @staticmethod
    def create(
        num_stages: Int32,
        producer_group: CooperativeGroup,
    ):
        """
        This helper function computes any necessary attributes and returns an instance of PipelineTmaStore.
        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: Int32
        :param producer_group: CooperativeGroup for the producer agent
        :type producer_group: CooperativeGroup
        """
        producer_type = _PipelineOp.TmaStore

        producer = (producer_type, producer_group)

        sync_object_array_full = PipelineAsync._make_sync_object_array(
            None, num_stages, producer
        )

        return PipelineTmaStore(sync_object_array_full, None, num_stages, None, None)

    def producer_acquire(self):
        self.sync_object_array_full.wait()

    def producer_commit(self):
        self.sync_object_array_full.arrive()

    def consumer_wait(self):
        assert False, "Error: PipelineTmaStore does not have a consumer agent."

    def consumer_release(self):
        assert False, "Error: PipelineTmaStore does not have a consumer agent."

    def producer_tail(self):
        self.sync_object_array_full.tail()


##############################################################################
# Helper functions
##############################################################################


def pipeline_init_wait(cta_layout_vmnk: Optional[cute.Layout] = None):
    """
    Fences the mbarrier init and syncs the threadblock or cluster
    """
    cute.arch.mbarrier_init_fence()

    if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
        # If not using clusters, sync the threadblock
        _sync(Agent.ThreadBlock)
    else:
        # If using clusters, sync the cluster
        _sync(Agent.ThreadBlockCluster)


def _sync(group: Agent):
    """
    Syncs all threads within an agent.
    """
    if group is Agent.Thread:
        assert False, "Error: Not supported."
    elif group is Agent.ThreadBlock:
        cute.arch.sync_threads()
    elif group is Agent.ThreadBlockCluster:
        cute.arch.cluster_arrive()
        cute.arch.cluster_wait()
    else:
        assert (
            False
        ), "Error: No explicit sync instruction exists. Please use barriers (named / mbarrier) instead."


def _mbarrier_i64_to_ptr(val: Int64) -> cute.Pointer:
    """
    Converts a smem pointer of type Int64 to cute.Pointer with 8B alignment
    """
    return cute.make_ptr(
        Int64,
        val.ir_value(),
        mem_space=_cute_ir.AddressSpace.smem,
        assumed_align=8,
    )
