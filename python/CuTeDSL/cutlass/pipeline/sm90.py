# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

from dataclasses import dataclass
from typing import Optional

import cutlass.cute as cute
from cutlass.cutlass_dsl import Boolean, Int32, if_generate, dsl_user_op

from cutlass.pipeline import (
    Agent,
    CooperativeGroup,
    MbarrierArray,
    PipelineOp,
    PipelineState,
    PipelineUserType,
    SyncObject,
    TmaStoreFence,
    make_pipeline_state,
    agent_sync,
)

##############################################################################
# Pipeline classes
##############################################################################


@dataclass(frozen=True)
class PipelineAsync:
    """PipelineAsync is a generic pipeline class where both the producer and consumer are
    AsyncThreads. It also serves as a base class for specialized pipeline classes.

    This class implements a producer-consumer pipeline pattern where both sides operate
    asynchronously. The pipeline maintains synchronization state using barrier objects
    to coordinate between producer and consumer threads.

    The pipeline state transitions of one pipeline entry(mbarrier) can be represented as:

    .. table:: Pipeline State Transitions
       :widths: auto

       +-----------+-----------+-----------+-----------+-----------+-----------+
       | Barrier   | State     | p.acquire | p.commit  | c.wait    | c.release |
       +===========+===========+===========+===========+===========+===========+
       | empty_bar | empty     | <Return>  | n/a       | n/a       | -         |
       +-----------+-----------+-----------+-----------+-----------+-----------+
       | empty_bar | wait      | <Block>   | n/a       | n/a       | -> empty  |
       +-----------+-----------+-----------+-----------+-----------+-----------+
       | full_bar  | wait      | n/a       | -> full   | <Block >  | n/a       |
       +-----------+-----------+-----------+-----------+-----------+-----------+
       | full_bar  | full      | n/a       | -         | <Return>  | n/a       |
       +-----------+-----------+-----------+-----------+-----------+-----------+

    Where:

    - p: producer
    - c: consumer
    - <Block>: This action is blocked until transition to a state allow it to proceed by other side
      - e.g. ``p.acquire()`` is blocked until ``empty_bar`` transition to ``empty`` state by ``c.release()``

    .. code-block:: text

        Array of mbarriers as circular buffer:

             Advance Direction
           <-------------------

            Producer   Consumer
                |         ^
                V         |
           +-----------------+
         --|X|X|W|D|D|D|D|R|X|<-.
        /  +-----------------+   \\
        |                        |
        `------------------------'

    Where:

    - X: Empty buffer (initial state)
    - W: Producer writing (producer is waiting for buffer to be empty)
    - D: Data ready (producer has written data to buffer)
    - R: Consumer reading (consumer is consuming data from buffer)

    **Example:**

    .. code-block:: python

        # Create pipeline with 5 stages
        pipeline = PipelineAsync.create(
            num_stages=5,                   # number of pipeline stages
            producer_group=producer_warp,
            consumer_group=consumer_warp
            barrier_storage=smem_ptr,       # smem pointer for array of mbarriers in shared memory
        )

        producer, consumer = pipeline.make_participants()
        # Producer side
        for i in range(num_iterations):
            handle = producer.acquire_and_advance()  # Wait for buffer to be empty & Move index to next stage
            # Write data to pipeline buffer
            handle.commit()   # Signal buffer is full

        # Consumer side
        for i in range(num_iterations):
            handle = consumer.wait_and_advance()     # Wait for buffer to be full & Move index to next stage
            # Read data from pipeline buffer
            handle.release()  # Signal buffer is empty
    """

    sync_object_full: SyncObject
    sync_object_empty: SyncObject
    num_stages: int
    producer_mask: Optional[Int32]
    consumer_mask: Optional[Int32]

    @staticmethod
    def _make_sync_object(
        barrier_storage: cute.Pointer,
        num_stages: int,
        agent: tuple[PipelineOp, CooperativeGroup],
        tx_count: int = 0,
    ) -> SyncObject:
        """
        Returns a SyncObject corresponding to an agent's PipelineOp.
        """
        if agent[0] in [
            PipelineOp.AsyncThread,
            PipelineOp.TmaLoad,
            PipelineOp.TCGen05Mma,
            PipelineOp.Composite,
            PipelineOp.AsyncLoad,
        ]:
            return MbarrierArray(
                barrier_storage=barrier_storage,
                num_stages=num_stages,
                agent=agent,
                tx_count=tx_count,
            )
        elif agent[0] is PipelineOp.TmaStore:
            # Path taken for AsyncTmaStore
            return TmaStoreFence(num_stages=num_stages)
        else:
            assert False, "Error: Invalid PipelineOp specified."

    @staticmethod
    def create(
        *,
        num_stages: int,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        barrier_storage: cute.Pointer = None,
        producer_mask: Int32 = None,
        consumer_mask: Int32 = None,
        defer_sync: bool = False,
    ):
        """Creates and initializes a new PipelineAsync instance.

        This helper function computes necessary attributes and returns an instance of PipelineAsync
        with the specified configuration for producer and consumer synchronization.

        :param barrier_storage: Pointer to the shared memory address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer
        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: int
        :param producer_group: ``CooperativeGroup`` for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group: ``CooperativeGroup`` for the consumer agent
        :type consumer_group: CooperativeGroup
        :param producer_mask: Mask for signaling arrives for the producer agent
        :type producer_mask: Int32, optional
        :param consumer_mask: Mask for signaling arrives for the consumer agent
        :type consumer_mask: Int32, optional
        :raises ValueError: If barrier_storage is not a cute.Pointer instance
        :return: A new ``PipelineAsync`` instance
        :rtype: PipelineAsync
        """
        if not isinstance(barrier_storage, cute.Pointer):
            raise ValueError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        producer_type = PipelineOp.AsyncThread
        consumer_type = PipelineOp.AsyncThread

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_full = PipelineAsync._make_sync_object(
            barrier_storage.align(min_align=8), num_stages, producer
        )
        sync_object_empty = PipelineAsync._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages, num_stages, consumer
        )

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            agent_sync(Agent.ThreadBlock)

        return PipelineAsync(
            sync_object_full,
            sync_object_empty,
            num_stages,
            producer_mask,
            consumer_mask,
        )

    def producer_acquire(
        self, state: PipelineState, try_acquire_token: Optional[Boolean] = None
    ):
        if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_empty.wait(state.index, state.phase),
        )

    def producer_try_acquire(self, state: PipelineState):
        return self.sync_object_empty.try_wait(state.index, state.phase)

    def producer_commit(self, state: PipelineState):
        self.sync_object_full.arrive(state.index, self.producer_mask)

    def consumer_wait(
        self, state: PipelineState, try_wait_token: Optional[Boolean] = None
    ):
        if_generate(
            try_wait_token is None or try_wait_token == 0,
            lambda: self.sync_object_full.wait(state.index, state.phase),
        )

    def consumer_try_wait(self, state: PipelineState):
        return self.sync_object_full.try_wait(state.index, state.phase)

    def consumer_release(self, state: PipelineState):
        self.sync_object_empty.arrive(state.index, self.consumer_mask)

    def producer_get_barrier(self, state: PipelineState) -> cute.Pointer:
        return self.sync_object_full.get_barrier(state.index)

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

    # Util methods to manage produer and consumer
    def make_producer(self):
        state = make_pipeline_state(PipelineUserType.Producer, self.num_stages)
        return PipelineProducer(self, state, self.sync_object_full.cg)

    def make_consumer(self):
        state = make_pipeline_state(PipelineUserType.Consumer, self.num_stages)
        return PipelineConsumer(self, state, self.sync_object_empty.cg)

    def make_participants(self):
        return self.make_producer(), self.make_consumer()


@dataclass(frozen=True)
class PipelineCpAsync(PipelineAsync):
    """
    PipelineCpAsync is used for CpAsync producers and AsyncThread consumers (e.g. Hopper non-TMA mainloops).
    """

    @staticmethod
    def create(
        barrier_storage: cute.Pointer,
        num_stages: Int32,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        producer_mask: Int32 = None,
        consumer_mask: Int32 = None,
        defer_sync: bool = False,
    ):
        """Helper function that computes necessary attributes and returns a ``PipelineCpAsync`` instance.

        :param barrier_storage: Pointer to the shared memory address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer
        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: Int32
        :param producer_group: ``CooperativeGroup`` for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group: ``CooperativeGroup`` for the consumer agent
        :type consumer_group: CooperativeGroup
        :param producer_mask: Mask for signaling arrives for the producer agent, defaults to None
        :type producer_mask: Int32, optional
        :param consumer_mask: Mask for signaling arrives for the consumer agent, defaults to None
        :type consumer_mask: Int32, optional
        :return: A new ``PipelineCpAsync`` instance configured with the provided parameters
        :rtype: PipelineCpAsync
        """
        producer_type = PipelineOp.AsyncLoad
        consumer_type = PipelineOp.AsyncThread

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_array_full = PipelineCpAsync._make_sync_object(
            barrier_storage.align(min_align=8), num_stages, producer
        )
        sync_object_array_empty = PipelineCpAsync._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages, num_stages, consumer
        )

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            agent_sync(Agent.ThreadBlock)

        return PipelineCpAsync(
            sync_object_array_full,
            sync_object_array_empty,
            num_stages,
            producer_mask,
            consumer_mask,
        )


@dataclass(frozen=True)
class PipelineTmaAsync(PipelineAsync):
    """
    PipelineTmaAsync is used for TMA producers and AsyncThread consumers (e.g. Hopper mainloops).
    """

    is_signalling_thread: Boolean

    @staticmethod
    @cute.jit
    def init_empty_barrier_arrive_signal(
        cta_layout_vmnk: cute.Layout, tidx: Int32, mcast_mode_mn: tuple[int, int] = (1, 1)
    ):
        """Initialize the empty barrier arrive signal.

        This function determines which threads should signal empty barrier arrives based on the cluster layout
        and multicast modes. It returns the destination CTA rank and whether the current thread should signal.

        :param cta_layout_vmnk: Layout describing the cluster shape and CTA arrangement
        :type cta_layout_vmnk: cute.Layout
        :param tidx: Thread index within the warp
        :type tidx: Int32
        :param mcast_mode_mn: Tuple specifying multicast modes for m and n dimensions (each 0 or 1), defaults to (1,1)
        :type mcast_mode_mn: tuple[int, int]
        :raises ``AssertionError``: If both multicast modes are disabled (0,0)
        :return: Tuple containing destination CTA rank and boolean indicating if current thread signals
        :rtype: tuple[Int32, Boolean]
        """
        # Logic to optimally schedule Empty Arrives
        cluster_shape_vmnk = cta_layout_vmnk.shape

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )

        tidx = tidx % 32
        is_signalling_thread = tidx < cute.size(cluster_shape_vmnk)
        dst_rank = tidx % cute.size(cluster_shape_vmnk)

        dst_cta_coord = cta_layout_vmnk.get_hier_coord(dst_rank)
        cur_cta_coord = cta_layout_vmnk.get_hier_coord(cta_rank_in_cluster)

        is_mcast_mode_m = (
            dst_cta_coord[0] == cur_cta_coord[0]
            and dst_cta_coord[1] == cur_cta_coord[1]
            and dst_cta_coord[3] == cur_cta_coord[3]
        )
        is_mcast_mode_n = (
            dst_cta_coord[0] == cur_cta_coord[0]
            and dst_cta_coord[2] == cur_cta_coord[2]
            and dst_cta_coord[3] == cur_cta_coord[3]
        )

        assert not (mcast_mode_mn[0] == 0 and mcast_mode_mn[1] == 0)
        if mcast_mode_mn[0] == 1 and mcast_mode_mn[1] == 0:
            is_signalling_thread = is_signalling_thread and is_mcast_mode_m
        elif mcast_mode_mn[0] == 0 and mcast_mode_mn[1] == 1:
            is_signalling_thread = is_signalling_thread and is_mcast_mode_n
        elif mcast_mode_mn[0] == 1 and mcast_mode_mn[1] == 1:
            is_mcast_mode_m_or_n = is_mcast_mode_m or is_mcast_mode_n
            is_signalling_thread = is_signalling_thread and is_mcast_mode_m_or_n

        return dst_rank, is_signalling_thread

    @staticmethod
    def create(
        *,
        num_stages: int,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        tx_count: int,
        barrier_storage: cute.Pointer = None,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        tidx: Optional[Int32] = None,
        mcast_mode_mn: tuple[int, int] = (1, 1),
        defer_sync: bool = False,
    ):
        """Create a new ``PipelineTmaAsync`` instance.

        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: int
        :param producer_group: ``CooperativeGroup`` for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group: ``CooperativeGroup`` for the consumer agent
        :type consumer_group: CooperativeGroup
        :param tx_count: Number of bytes expected to be written to the transaction barrier for one stage
        :type tx_count: int
        :param barrier_storage: Pointer to the shared memory address for this pipeline's mbarriers, defaults to None
        :type barrier_storage: cute.Pointer, optional
        :param cta_layout_vmnk: Layout of the cluster shape, defaults to None
        :type cta_layout_vmnk: cute.Layout, optional
        :param tidx: Thread index to consumer async threads, defaults to None
        :type tidx: Int32, optional
        :param mcast_mode_mn: Tuple specifying multicast modes for m and n dimensions (each 0 or 1), defaults to (1,1)
        :type mcast_mode_mn: tuple[int, int], optional
        :raises ValueError: If barrier_storage is not a cute.Pointer instance
        :return: New ``PipelineTmaAsync`` instance
        :rtype: PipelineTmaAsync
        """
        if not isinstance(barrier_storage, cute.Pointer):
            raise ValueError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        producer_type = PipelineOp.TmaLoad
        consumer_type = PipelineOp.AsyncThread

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_full = PipelineAsync._make_sync_object(
            barrier_storage.align(min_align=8), num_stages, producer, tx_count
        )
        sync_object_empty = PipelineAsync._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages, num_stages, consumer
        )
        if tidx is None:
            tidx, _, _ = cute.arch.thread_idx()
        if cta_layout_vmnk is None:
            cta_layout_vmnk = cute.make_layout((1, 1, 1, 1))
        (
            dst_rank,
            is_signalling_thread,
        ) = PipelineTmaAsync.init_empty_barrier_arrive_signal(
            cta_layout_vmnk, tidx, mcast_mode_mn
        )
        if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
            dst_rank = None
        else:
            dst_rank = dst_rank

        producer_mask = None

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
                agent_sync(Agent.ThreadBlock)
            else:
                agent_sync(Agent.ThreadBlockCluster, is_relaxed=True)

        return PipelineTmaAsync(
            sync_object_full,
            sync_object_empty,
            num_stages,
            producer_mask,
            dst_rank,
            is_signalling_thread,
        )

    @dsl_user_op
    def producer_acquire(
        self,
        state: PipelineState,
        try_acquire_token: Optional[Boolean] = None,
        *,
        loc=None,
        ip=None,
    ):
        """
        TMA producer commit conditionally waits on buffer empty and sets the transaction barrier.
        """
        if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_empty.wait(
                state.index, state.phase, loc=loc, ip=ip
            ),
        )
        self.sync_object_full.arrive(state.index, self.producer_mask, loc=loc, ip=ip)

    def producer_commit(self, state: PipelineState):
        """
        TMA producer commit is a noop since TMA instruction itself updates the transaction count.
        """
        pass

    @dsl_user_op
    def consumer_release(self, state: PipelineState, *, loc=None, ip=None):
        """
        TMA consumer release conditionally signals the empty buffer to the producer.
        """
        if_generate(
            self.is_signalling_thread,
            lambda: self.sync_object_empty.arrive(
                state.index, self.consumer_mask, loc=loc, ip=ip
            ),
        )


@dataclass(frozen=True)
class PipelineTmaMultiConsumersAsync(PipelineAsync):
    """
    PipelineTmaMultiConsumersAsync is used for TMA producers and UMMA+Async consumers.
    """

    is_leader_cta: bool
    sync_object_empty_umma: SyncObject
    sync_object_empty_async: SyncObject
    cta_group: cute.nvgpu.tcgen05.CtaGroup

    @staticmethod
    def create(
        *,
        num_stages: int,
        producer_group: CooperativeGroup,
        consumer_group_umma: CooperativeGroup,
        consumer_group_async: CooperativeGroup,
        tx_count: int,
        barrier_storage: cute.Pointer = None,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        defer_sync: bool = False,
    ):
        """Creates an instance of PipelineTmaMultiConsumersAsync with computed attributes.

        :param barrier_storage: Pointer to the shared memory address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer
        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: int
        :param producer_group: ``CooperativeGroup`` for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group_umma: ``CooperativeGroup`` for the UMMA consumer agent
        :type consumer_group_umma: CooperativeGroup
        :param consumer_group_async: ``CooperativeGroup`` for the AsyncThread consumer agent
        :type consumer_group_async: CooperativeGroup
        :param tx_count: Number of bytes expected to be written to the transaction barrier for one stage
        :type tx_count: int
        :param cta_layout_vmnk: Layout of the cluster shape, defaults to None
        :type cta_layout_vmnk: Optional[cute.Layout]
        :raises ValueError: If ``barrier_storage`` is not a ``cute.Pointer`` instance
        :raises ValueError: If ``UMMA`` and ``AsyncThread`` consumer groups are not the same agent
        :raises ValueError: If ``cta_layout_vmnk`` size is not 1
        :return: New instance of ``PipelineTmaMultiConsumersAsync``
        :rtype: PipelineTmaMultiConsumersAsync
        """
        if not isinstance(barrier_storage, cute.Pointer):
            raise ValueError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        producer_type = PipelineOp.TmaLoad
        consumer_type = PipelineOp.Composite
        consumer_type_umma = PipelineOp.TCGen05Mma
        consumer_type_async = PipelineOp.AsyncThread

        if consumer_group_umma.agent != consumer_group_async.agent:
            raise ValueError(
                "UMMA and AsyncThread consumer groups must be the same agent"
            )

        if cta_layout_vmnk is not None and cute.size(cta_layout_vmnk) != 1:
            raise ValueError(
                f"PipelineTmaMultiConsumersAsync is not verified for cta_layout_vmnk != 1, cta_layout_vmnk:{cta_layout_vmnk}"
            )

        consumer_group = CooperativeGroup(
            consumer_group_umma.agent,
            consumer_group_umma.size + consumer_group_async.size,
        )

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_full = PipelineAsync._make_sync_object(
            barrier_storage.align(min_align=8), num_stages, producer, tx_count
        )
        sync_object_empty = PipelineAsync._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages, num_stages, consumer
        )
        sync_object_empty_umma = sync_object_empty.recast_to_new_op_type(
            consumer_type_umma
        )
        sync_object_empty_async = sync_object_empty.recast_to_new_op_type(
            consumer_type_async
        )

        # No mcast mask if not using clusters
        producer_mask = None
        consumer_mask = None
        # All thread-blocks are leaders if not using clusters
        is_leader_cta = True
        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, mode=[0]) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )

        if not defer_sync:
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
                agent_sync(Agent.ThreadBlock)
            else:
                agent_sync(Agent.ThreadBlockCluster, is_relaxed=True)

        return PipelineTmaMultiConsumersAsync(
            sync_object_full,
            sync_object_empty,
            num_stages,
            producer_mask,
            consumer_mask,
            is_leader_cta,
            sync_object_empty_umma,
            sync_object_empty_async,
            cta_group,
        )

    def producer_acquire(
        self, state: PipelineState, try_acquire_token: Optional[Boolean] = None
    ):
        """
        TMA producer acquire waits on buffer empty and sets the transaction barrier for leader threadblocks.
        """
        if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_empty.wait(state.index, state.phase),
        )
        if_generate(
            self.is_leader_cta,
            lambda: self.sync_object_full.arrive(state.index, self.producer_mask),
        )

    def producer_commit(self, state: PipelineState):
        """
        TMA producer commit is a noop since TMA instruction itself updates the transaction count.
        """
        pass

    def consumer_release(self, state: PipelineState, op_type: PipelineOp):
        if op_type == PipelineOp.TCGen05Mma:
            self.sync_object_empty_umma.arrive(
                state.index, self.consumer_mask, self.cta_group
            )
        elif op_type == PipelineOp.AsyncThread:
            self.sync_object_empty_async.arrive(state.index, self.consumer_mask)
        else:
            raise ValueError(f"Invalid PipelineOp specified. op_type:{op_type}")


@dataclass(frozen=True)
class PipelineTmaStore(PipelineAsync):
    """
    PipelineTmaStore is used for synchronizing TMA stores in the epilogue. It does not use mbarriers.
    """

    @staticmethod
    def create(
        *,
        num_stages: int,
        producer_group: CooperativeGroup,
    ):
        """This helper function computes any necessary attributes and returns an instance of ``PipelineTmaStore``.

        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: int
        :param producer_group: ``CooperativeGroup`` for the producer agent
        :type producer_group: CooperativeGroup
        :return: A new ``PipelineTmaStore`` instance
        :rtype: PipelineTmaStore
        """
        producer_type = PipelineOp.TmaStore

        producer = (producer_type, producer_group)

        sync_object_full = PipelineAsync._make_sync_object(None, num_stages, producer)

        return PipelineTmaStore(sync_object_full, None, num_stages, None, None)

    @dsl_user_op
    def producer_acquire(self, *, loc=None, ip=None):
        self.sync_object_full.wait(loc=loc, ip=ip)

    @dsl_user_op
    def producer_commit(self, *, loc=None, ip=None):
        self.sync_object_full.arrive(loc=loc, ip=ip)

    @dsl_user_op
    def consumer_wait(self, *, loc=None, ip=None):
        assert False, "Error: PipelineTmaStore does not have a consumer agent."

    @dsl_user_op
    def consumer_release(self, *, loc=None, ip=None):
        assert False, "Error: PipelineTmaStore does not have a consumer agent."

    @dsl_user_op
    def producer_tail(self, *, loc=None, ip=None):
        self.sync_object_full.tail(loc=loc, ip=ip)


@dataclass(frozen=True)
class PipelineOrder:
    """
    PipelineOrder is used for managing ordered pipeline execution with multiple groups.

    This class implements a pipeline ordering mechanism where work is divided into groups
    and stages, allowing for controlled progression through pipeline stages with proper
    synchronization between different groups.

    The pipeline ordering works as follows:
    - The pipeline is divided into 'length' number of groups
    - Each group has 'depth' number of stages
    - Groups execute in a specific order with synchronization barriers
    - Each group waits for the previous group to complete before proceeding

    **Example:**

    .. code-block:: python

        # Create pipeline order with 3 groups, each with 2 stages
        pipeline_order = PipelineOrder.create(
            barrier_storage=smem_ptr,      # shared memory pointer for barriers
            depth=2,                       # 2 stages per group
            length=3,                      # 3 groups total
            group_id=0,                    # current group ID (0, 1, or 2)
            producer_group=producer_warp   # cooperative group for producers
        )

        # In the pipeline loop
        for stage in range(num_stages):
            pipeline_order.wait()          # Wait for previous group to complete
            # Process current stage
            pipeline_order.arrive()        # Signal completion to next group
    """

    sync_object_full: SyncObject
    depth: int
    length: int
    group_id: int
    state: PipelineState

    @staticmethod
    def create(
        barrier_storage: cute.Pointer,
        depth: int,
        length: int,
        group_id: int,
        producer_group: CooperativeGroup,
        defer_sync: bool = False,
    ):
        if not isinstance(barrier_storage, cute.Pointer):
            raise ValueError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        producer_type = PipelineOp.AsyncThread

        producer = (producer_type, producer_group)

        num_stages = depth * length

        sync_object_full = PipelineAsync._make_sync_object(
            barrier_storage.align(min_align=8), num_stages, producer
        )

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            agent_sync(Agent.ThreadBlock)

        return PipelineOrder(
            sync_object_full,
            depth,
            length,
            group_id,
            PipelineState(
                depth,
                Int32(0),
                Int32(0),
                Int32(group_id == 0),  # phase
            ),
        )

    def get_barrier_for_current_stage_idx(self, group_id):
        return self.state.index * self.length + group_id

    @dsl_user_op
    def arrive(self, *, loc=None, ip=None):
        signalling_id = (self.group_id + 1) % self.length
        idx = self.get_barrier_for_current_stage_idx(signalling_id)
        cute.arch.mbarrier_arrive(
            self.sync_object_full.get_barrier(idx), loc=loc, ip=ip
        )
        self.state.advance(loc=loc, ip=ip)

    @dsl_user_op
    def wait(self, *, loc=None, ip=None):
        idx = self.get_barrier_for_current_stage_idx(self.group_id)
        cute.arch.mbarrier_wait(
            self.sync_object_full.get_barrier(idx), self.state.phase, loc=loc, ip=ip
        )


#################################################################
# Utilities to help user of pipeline to simplify the workflow
#################################################################


@dataclass(frozen=True)
class ImmutableResourceHandle:
    __origin: PipelineAsync
    __immutable_state: PipelineState

    def __init__(self, origin: PipelineAsync, immutable_state: PipelineState):
        self.__origin = origin
        self.__immutable_state = immutable_state

    @property
    def index(self):
        """Get the index of the current pipeline stage."""
        return self.__immutable_state.index

    @property
    def count(self):
        """Get the count of how many handles this producer has committed.
        This is useful for tracking the number of blocks that have been loaded from gmem.
        """
        return self.__immutable_state.count

    def get_origin(self):
        """Get the original pipeline this resource handle belongs to."""
        return self.__origin

    def __extract_mlir_values__(self):
        """Extract MLIR values from the current state.

        :return: List of MLIR values representing the current state
        :rtype: list
        """
        # TODO: need to handle pipeline as well
        return self.__immutable_state.__extract_mlir_values__()

    def __new_from_mlir_values__(self, values):
        """Create a new Producer instance from MLIR values.

        :param values: MLIR values to initialize the state
        :type values: Any
        :return: New Producer instance with state initialized from values
        :rtype: Producer
        """
        return self.__class__(
            self.__origin, self.__immutable_state.__new_from_mlir_values__(values)
        )


class PipelineProducer:
    """A class representing a producer in an asynchronous pipeline.

    This class manages the producer side of an asynchronous pipeline, handling
    synchronization and state management for producing data. It provides methods for
    acquiring, committing, and advancing through pipeline stages.

    :ivar __pipeline: The asynchronous pipeline this producer belongs to
    :type __pipeline: PipelineAsync
    :ivar __state: The current state of the producer in the pipeline
    :type __state: PipelineState
    :ivar __group: The cooperative group this producer operates in
    :type __group: CooperativeGroup

    **Examples:**

    .. code-block:: python

        pipeline = PipelineAsync.create(...)
        producer, consumer = pipeline.make_participants()
        for i in range(iterations):
            # Try to acquire the current buffer without blocking
            try_acquire_token = producer.try_acquire()

            # Do something else independently
            ...

            # Wait for current buffer to be empty & Move index to next stage
            # If try_acquire_token is True, return immediately
            # If try_acquire_token is False, block until buffer is empty
            handle = producer.acquire_and_advance(try_acquire_token)

            # Produce data
            handle.commit()
    """

    __pipeline: PipelineAsync
    __state: PipelineState
    __group: CooperativeGroup

    @dataclass(frozen=True)
    class ImmutableResourceHandle(ImmutableResourceHandle):
        @property
        def barrier(self):
            """Get the barrier pointer for the current pipeline stage.

            :return: Pointer to the barrier for the current stage
            :rtype: cute.Pointer
            """
            return self.get_origin().producer_get_barrier(
                self._ImmutableResourceHandle__immutable_state
            )

        def commit(self):
            """Signal that data production is complete for the current stage.

            This allows consumers to start processing the data.
            """
            self.get_origin().producer_commit(
                self._ImmutableResourceHandle__immutable_state
            )

    def __init__(self, pipeline, state, group: CooperativeGroup):
        """Initialize a new Producer instance.

        :param pipeline: The pipeline this producer belongs to
        :type pipeline: PipelineAsync
        :param state: Initial pipeline state
        :type state: PipelineState
        :param group: The cooperative group for synchronization
        :type group: CooperativeGroup
        """
        self.__pipeline = pipeline
        self.__state = state
        self.__group = group

    def clone(self):
        """Create a new Producer instance with the same state."""
        return PipelineProducer(self.__pipeline, self.__state.clone(), self.__group)

    def reset(self):
        """Reset the count of how many handles this producer has committed."""
        self.__state.reset_count()

    def acquire(
        self,
        try_acquire_token: Optional[Boolean] = None,
    ) -> ImmutableResourceHandle:
        """Wait for the current buffer to be empty before producing data.
        This is a blocking operation.

        :param try_acquire_token: Optional token to try to acquire the buffer
        :type try_acquire_token: Optional[Boolean]
        :return: A handle to the producer for committing the data
        :rtype: ImmutableResourceHandle
        """
        self.__pipeline.producer_acquire(self.__state, try_acquire_token)
        handle = PipelineProducer.ImmutableResourceHandle(
            self.__pipeline, self.__state.clone()
        )
        return handle

    def advance(self):
        """Move to the next pipeline stage."""
        self.__state.advance()

    def acquire_and_advance(
        self, try_acquire_token: Optional[Boolean] = None
    ) -> ImmutableResourceHandle:
        """Acquire the current buffer and advance to the next pipeline stage.

        This method combines the acquire() and advance() operations into a single call.
        It first waits for the current buffer to be empty before producing data,
        then advances the pipeline to the next stage.

        :param try_acquire_token: Token indicating whether to try non-blocking acquire.
            If True, returns immediately without waiting. If False or None, blocks
            until buffer is empty.
        :type try_acquire_token: Optional[Boolean]
        :return: A handle to the producer that can be used to commit data to the
            acquired buffer stage
        :rtype: ImmutableResourceHandle
        """
        handle = self.acquire(try_acquire_token)
        self.advance()
        return handle

    def try_acquire(self) -> Boolean:
        """Attempt to acquire the current buffer without blocking.

        This method tries to acquire the current buffer stage for producing data
        without waiting. It can be used to check buffer availability before
        committing to a blocking acquire operation.

        :return: A boolean token indicating whether the buffer was successfully acquired
        :rtype: Boolean
        """
        return self.__pipeline.producer_try_acquire(self.__state)

    def commit(self, handle: Optional[ImmutableResourceHandle] = None):
        """Signal that data production is complete for the current stage.

        This allows consumers to start processing the data.

        :param handle: Optional handle to commit, defaults to None
        :type handle: Optional[ImmutableResourceHandle]
        :raises AssertionError: If provided handle does not belong to this producer
        """
        if handle is not None:
            assert handle.get_origin() is self, (
                "ResourceHandle does not belong to this PipelineProducer instance"
            )
            handle.commit()
        else:
            self.__pipeline.producer_commit(self.__state)

    def tail(self):
        """Ensure all used buffers are properly synchronized before producer exit.

        This should be called before the producer finishes to avoid dangling signals.
        """
        self.__pipeline.producer_tail(self.__state)

    def __extract_mlir_values__(self):
        """Extract MLIR values from the current state.

        :return: List of MLIR values representing the current state
        :rtype: list
        """
        # TODO: need to handle pipeline as well
        return self.__state.__extract_mlir_values__()

    def __new_from_mlir_values__(self, values):
        """Create a new Producer instance from MLIR values.

        :param values: MLIR values to initialize the state
        :type values: Any
        :return: New Producer instance with state initialized from values
        :rtype: Producer
        """
        return PipelineProducer(
            self.__pipeline, self.__state.__new_from_mlir_values__(values), self.__group
        )


class PipelineConsumer:
    """A class representing a consumer in an asynchronous pipeline.

    The Consumer class manages the consumer side of an asynchronous pipeline, handling
    synchronization and state management for consuming data. It provides methods for
    waiting, releasing, and advancing through pipeline stages.

    :ivar __pipeline: The asynchronous pipeline this consumer belongs to
    :type __pipeline: PipelineAsync
    :ivar __state: The current state of the consumer in the pipeline
    :type __state: PipelineState
    :ivar __group: The cooperative group this consumer operates in
    :type __group: CooperativeGroup

    **Examples:**

    .. code-block:: python

        pipeline = PipelineAsync.create(...)
        producer, consumer = pipeline.make_participants()
        for i in range(iterations):
            # Try to wait for buffer to be full
            try_wait_token = consumer.try_wait()

            # Do something else independently
            ...

            # Wait for buffer to be full & Move index to next stage
            # If try_wait_token is True, return immediately
            # If try_wait_token is False, block until buffer is full
            handle = consumer.wait_and_advance(try_wait_token)

            # Consume data
            handle.release(  )  # Signal buffer is empty

            # Alternative way to do this is:
            # handle.release()  # Signal buffer is empty
    """

    __pipeline: PipelineAsync
    __state: PipelineState
    __group: CooperativeGroup

    @dataclass(frozen=True)
    class ImmutableResourceHandle(ImmutableResourceHandle):
        def release(self):
            """Signal that data production is complete for the current stage.
            This allows consumers to start processing the data.
            """
            self.get_origin().consumer_release(
                self._ImmutableResourceHandle__immutable_state
            )

    def __init__(self, pipeline, state: PipelineState, group: CooperativeGroup):
        """Initialize a new Consumer instance.

        :param pipeline: The pipeline this consumer belongs to
        :type pipeline: PipelineAsync
        :param state: Initial pipeline state
        :type state: PipelineState
        :param group: The cooperative group for synchronization
        :type group: CooperativeGroup
        """
        self.__pipeline = pipeline
        self.__group = group
        self.__state = state

    def clone(self):
        """Create a new Consumer instance with the same state."""
        return PipelineConsumer(self.__pipeline, self.__state.clone(), self.__group)

    def reset(self):
        """Reset the count of how many handles this consumer has consumed."""
        self.__state.reset_count()

    def wait(self, try_wait_token: Optional[Boolean] = None) -> ImmutableResourceHandle:
        """Wait for data to be ready in the current buffer. This is a blocking operation
        that will not return until data is available.

        :param try_wait_token: Token used to attempt a non-blocking wait for the buffer.
            If provided and True, returns immediately if buffer is not ready.
        :type try_wait_token: Optional[Boolean]
        :return: An immutable handle to the consumer that can be used to release the buffer
            once data consumption is complete
        :rtype: ImmutableResourceHandle
        """
        self.__pipeline.consumer_wait(self.__state, try_wait_token)
        handle = PipelineConsumer.ImmutableResourceHandle(
            self.__pipeline, self.__state.clone()
        )
        return handle

    def advance(self):
        """Advance the consumer to the next pipeline stage.

        This updates the internal state to point to the next buffer in the pipeline.
        Should be called after consuming data from the current buffer.
        """
        self.__state.advance()

    def wait_and_advance(
        self, try_wait_token: Optional[Boolean] = None
    ) -> ImmutableResourceHandle:
        """Atomically wait for data and advance to next pipeline stage.

        This is a convenience method that combines wait() and advance() into a single
        atomic operation. It will block until data is available in the current buffer,
        then automatically advance to the next stage.

        :param try_wait_token: Token used to attempt a non-blocking wait for the buffer.
            If provided and True, returns immediately if buffer is not ready.
        :type try_wait_token: Optional[Boolean]
        :return: An immutable handle to the consumer that can be used to release the buffer
            once data consumption is complete
        :rtype: ImmutableResourceHandle
        """
        handle = self.wait(try_wait_token)
        self.advance()
        return handle

    def try_wait(self) -> Boolean:
        """Non-blocking check if data is ready in the current buffer.

        This method provides a way to test if data is available without blocking.
        Unlike wait(), this will return immediately regardless of buffer state.

        :return: True if data is ready to be consumed, False if the buffer is not yet ready
        :rtype: Boolean
        """
        return self.__pipeline.consumer_try_wait(self.__state)

    def release(self, handle: Optional[ImmutableResourceHandle] = None):
        """Signal that data consumption is complete for the current stage.
        This allows producers to start producing new data.
        """
        if handle is not None:
            assert handle.get_origin() is self, (
                "ResourceHandle does not belong to this PipelineConsumer instance"
            )
            handle.release()
        else:
            self.__pipeline.consumer_release(self.__state)

    def __extract_mlir_values__(self):
        """Extract MLIR values from the current state.

        :return: List of MLIR values representing the current state
        :rtype: list
        """
        return self.__state.__extract_mlir_values__()

    def __new_from_mlir_values__(self, values):
        """Create a new Consumer instance from MLIR values.

        :param values: MLIR values to initialize the state
        :type values: Any
        :return: New Consumer instance with state initialized from values
        :rtype: Consumer
        """
        # TODO: need to call pipeline.__new_from_mlir_values__ recursively
        return PipelineConsumer(
            self.__pipeline, self.__state.__new_from_mlir_values__(values), self.__group
        )
