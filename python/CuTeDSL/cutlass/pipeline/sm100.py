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

import cutlass
import cutlass.cute as cute
from cutlass.cutlass_dsl import Boolean, Int32, if_generate, dsl_user_op

from cutlass.pipeline import (
    Agent,
    CooperativeGroup,
    PipelineOp,
    SyncObject,
    MbarrierArray,
    TmaStoreFence,
    PipelineState,
    PipelineAsync,
    agent_sync,
)

##############################################################################
# Pipeline classes
##############################################################################


@dataclass(frozen=True)
class PipelineTmaUmma(PipelineAsync):
    """
    PipelineTmaUmma is used for TMA producers and UMMA consumers (e.g. Blackwell mainloops).
    """

    is_leader_cta: bool
    cta_group: cute.nvgpu.tcgen05.CtaGroup

    @dsl_user_op
    @staticmethod
    def _make_sync_object(
        barrier_storage: cute.Pointer,
        num_stages: int,
        agent: tuple[PipelineOp, CooperativeGroup],
        tx_count: int = 0,
        *,
        loc=None,
        ip=None,
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
            PipelineOp.ClcLoad,
        ]:
            return MbarrierArray(
                barrier_storage=barrier_storage,
                num_stages=num_stages,
                agent=agent,
                tx_count=tx_count,
                loc=loc,
                ip=ip,
            )
        elif agent[0] is PipelineOp.TmaStore:
            # Path taken for AsyncTmaStore
            return TmaStoreFence(num_stages=num_stages)
        else:
            assert False, "Error: Invalid PipelineOp specified."

    @dsl_user_op
    @staticmethod
    def _compute_mcast_arrival_mask(
        cta_layout_vmnk: cute.Layout,
        mcast_mode_mn: tuple[int, int],
        *,
        loc=None,
        ip=None,
    ):
        """
        Computes a mask for signaling arrivals to multicasting threadblocks.
        """
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster(loc=loc, ip=ip), loc=loc, ip=ip
        )
        cta_in_cluster_coord_vmnk = cta_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster, loc=loc, ip=ip
        )

        tma_mcast_mask_a = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cta_layout_vmnk, cta_in_cluster_coord_vmnk, mcast_mode=2, loc=loc, ip=ip
        )
        tma_mcast_mask_b = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cta_layout_vmnk, cta_in_cluster_coord_vmnk, mcast_mode=1, loc=loc, ip=ip
        )

        block_in_cluster_coord_vmnk_peer = (
            cta_in_cluster_coord_vmnk[0] ^ 1,
            *cta_in_cluster_coord_vmnk[1:],
        )
        tma_mcast_mask_a_peer = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cta_layout_vmnk,
            block_in_cluster_coord_vmnk_peer,
            mcast_mode=2,
            loc=loc,
            ip=ip,
        )
        tma_mcast_mask_b_peer = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cta_layout_vmnk,
            block_in_cluster_coord_vmnk_peer,
            mcast_mode=1,
            loc=loc,
            ip=ip,
        )

        assert not (mcast_mode_mn[0] == 0 and mcast_mode_mn[1] == 0)
        if mcast_mode_mn[0] == 1 and mcast_mode_mn[1] == 1:
            return (
                tma_mcast_mask_a
                | tma_mcast_mask_b
                | tma_mcast_mask_a_peer
                | tma_mcast_mask_b_peer
            )
        elif mcast_mode_mn[1] == 1:
            return tma_mcast_mask_b | tma_mcast_mask_b_peer
        assert mcast_mode_mn[0] == 1
        return tma_mcast_mask_a | tma_mcast_mask_a_peer

    @dsl_user_op
    @staticmethod
    def _compute_is_leader_cta(cta_layout_vmnk: cute.Layout, *, loc=None, ip=None):
        """
        Computes leader threadblocks for 2CTA kernels. For 1CTA, all threadblocks are leaders.
        """
        bidx, bidy, _ = cute.arch.block_idx(loc=loc, ip=ip)

        mma_coord_vmnk = (
            bidx % cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip),
            bidx // cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip),
            bidy,
            None,
        )
        return mma_coord_vmnk[0] == 0

    @dsl_user_op
    @staticmethod
    def create(
        *,
        num_stages: int,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        tx_count: int,
        barrier_storage: cute.Pointer = None,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        mcast_mode_mn: tuple[int, int] = (1, 1),
        defer_sync: bool = False,
        loc=None,
        ip=None,
    ):
        """Creates and initializes a new PipelineTmaUmma instance.

        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: int
        :param producer_group: CooperativeGroup for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group: CooperativeGroup for the consumer agent
        :type consumer_group: CooperativeGroup
        :param tx_count: Number of bytes expected to be written to the transaction barrier for one stage
        :type tx_count: int
        :param barrier_storage: Pointer to the shared memory address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer, optional
        :param cta_layout_vmnk: Layout of the cluster shape
        :type cta_layout_vmnk: cute.Layout, optional
        :param mcast_mode_mn: Tuple specifying multicast modes for m and n dimensions (each 0 or 1)
        :type mcast_mode_mn: tuple[int, int], optional
        :raises ValueError: If barrier_storage is not a cute.Pointer instance
        :return: A new PipelineTmaUmma instance configured with the provided parameters
        :rtype: PipelineTmaUmma
        """
        if not isinstance(barrier_storage, cute.Pointer):
            raise TypeError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        producer_type = PipelineOp.TmaLoad
        consumer_type = PipelineOp.TCGen05Mma

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_full = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8),
            num_stages,
            producer,
            tx_count,
            loc=loc,
            ip=ip,
        )
        sync_object_empty = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages,
            num_stages,
            consumer,
            loc=loc,
            ip=ip,
        )

        if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, loc=loc, ip=ip) == 1:
            # No mcast mask if not using clusters
            producer_mask = None
            # All threadblocks are leaders if not using clusters
            is_leader_cta = True
        else:
            producer_mask = PipelineTmaUmma._compute_mcast_arrival_mask(
                cta_layout_vmnk, mcast_mode_mn, loc=loc, ip=ip
            )
            is_leader_cta = PipelineTmaUmma._compute_is_leader_cta(
                cta_layout_vmnk, loc=loc, ip=ip
            )

        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cta_layout_vmnk is None
            or cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )

        consumer_mask = producer_mask

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if (
                cta_layout_vmnk is None
                or cute.size(cta_layout_vmnk, loc=loc, ip=ip) == 1
            ):
                agent_sync(Agent.ThreadBlock)
            else:
                agent_sync(Agent.ThreadBlockCluster, is_relaxed=True)

        return PipelineTmaUmma(
            sync_object_full,
            sync_object_empty,
            num_stages,
            producer_mask,
            consumer_mask,
            is_leader_cta,
            cta_group,
        )

    @dsl_user_op
    def consumer_release(self, state: PipelineState, *, loc=None, ip=None):
        """
        UMMA consumer release buffer empty, cta_group needs to be provided.
        """
        self.sync_object_empty.arrive(
            state.index, self.consumer_mask, self.cta_group, loc=loc, ip=ip
        )

    def producer_acquire(
        self,
        state: PipelineState,
        try_acquire_token: Optional[Boolean] = None,
        *,
        loc=None,
        ip=None,
    ):
        """
        TMA producer commit conditionally waits on buffer empty and sets the transaction barrier for leader threadblocks.
        """
        if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_empty.wait(
                state.index, state.phase, loc=loc, ip=ip
            ),
            loc=loc,
            ip=ip,
        )
        if_generate(
            self.is_leader_cta,
            lambda: self.sync_object_full.arrive(
                state.index, self.producer_mask, loc=loc, ip=ip
            ),
            loc=loc,
            ip=ip,
        )

    def producer_commit(self, state: PipelineState):
        """
        TMA producer commit is a noop since TMA instruction itself updates the transaction count.
        """
        pass


@dataclass(frozen=True)
class PipelineAsyncUmma(PipelineAsync):
    """
    PipelineAsyncUmma is used for AsyncThread producers and UMMA consumers (e.g. Blackwell input fusion pipelines).
    """

    cta_group: cute.nvgpu.tcgen05.CtaGroup

    @dsl_user_op
    @staticmethod
    def _compute_leading_cta_rank(cta_v_size, *, loc=None, ip=None):
        """
        Computes the leading CTA rank.
        """
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster(loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )
        return cta_rank_in_cluster // cta_v_size * cta_v_size

    @dsl_user_op
    @staticmethod
    def _compute_is_leader_cta(cta_layout_vmnk: cute.Layout, *, loc=None, ip=None):
        """
        Computes leader threadblocks for 2CTA kernels. For 1CTA, all threadblocks are leaders.
        """
        bidx, bidy, _ = cute.arch.block_idx(loc=loc, ip=ip)
        mma_coord_vmnk = (
            bidx % cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip),
            bidx // cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip),
            bidy,
            None,
        )
        return mma_coord_vmnk[0] == 0

    @dsl_user_op
    @staticmethod
    def _compute_peer_cta_mask(cta_layout_vmnk: cute.Layout, *, loc=None, ip=None):
        """
        Computes a mask for signaling arrivals to multicasting threadblocks.
        """
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster(loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )
        cta_in_cluster_coord_vmnk = cta_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster, loc=loc, ip=ip
        )
        mask_self = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cta_layout_vmnk, cta_in_cluster_coord_vmnk, mcast_mode=0, loc=loc, ip=ip
        )
        block_in_cluster_coord_vmnk_peer = (
            cta_in_cluster_coord_vmnk[0] ^ 1,
            *cta_in_cluster_coord_vmnk[1:],
        )
        mask_peer = cute.nvgpu.cpasync.create_tma_multicast_mask(
            cta_layout_vmnk,
            block_in_cluster_coord_vmnk_peer,
            mcast_mode=0,
            loc=loc,
            ip=ip,
        )
        return mask_self | mask_peer

    @dsl_user_op
    @staticmethod
    def create(
        *,
        num_stages: int,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        barrier_storage: cute.Pointer = None,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        defer_sync: bool = False,
        loc=None,
        ip=None,
    ):
        """Creates and initializes a new PipelineAsyncUmma instance.

        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: int
        :param producer_group: CooperativeGroup for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group: CooperativeGroup for the consumer agent
        :type consumer_group: CooperativeGroup
        :param barrier_storage: Pointer to the shared memory address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer, optional
        :param cta_layout_vmnk: Layout of the cluster shape
        :type cta_layout_vmnk: cute.Layout, optional
        :raises ValueError: If barrier_storage is not a cute.Pointer instance
        :return: A new PipelineAsyncUmma instance configured with the provided parameters
        :rtype: PipelineAsyncUmma
        """
        if not isinstance(barrier_storage, cute.Pointer):
            raise TypeError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        producer_type = PipelineOp.AsyncThread
        consumer_type = PipelineOp.TCGen05Mma

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_full = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8),
            num_stages,
            producer,
            loc=loc,
            ip=ip,
        )
        sync_object_empty = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages,
            num_stages,
            consumer,
            loc=loc,
            ip=ip,
        )

        cta_v_size = (
            cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip)
            if cta_layout_vmnk is not None
            else 1
        )
        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cta_layout_vmnk is None
            or cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )
        if (
            cta_layout_vmnk is None
            or cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip) == 1
        ):
            # No mcast mask if we're not using 2CTA tcgen05 MMA
            producer_mask = None
            consumer_mask = None
        else:
            # If we're using 2CTA UMMAs, producer will arrive the mbar on leading CTA
            # We need to get the target cta_rank
            producer_mask = PipelineAsyncUmma._compute_leading_cta_rank(
                cta_v_size, loc=loc, ip=ip
            )
            # consumer needs to get the mask to signal
            consumer_mask = PipelineAsyncUmma._compute_peer_cta_mask(
                cta_layout_vmnk, loc=loc, ip=ip
            )

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if (
                cta_layout_vmnk is None
                or cute.size(cta_layout_vmnk, loc=loc, ip=ip) == 1
            ):
                agent_sync(Agent.ThreadBlock)
            else:
                agent_sync(Agent.ThreadBlockCluster, is_relaxed=True)

        return PipelineAsyncUmma(
            sync_object_full,
            sync_object_empty,
            num_stages,
            producer_mask,
            consumer_mask,
            cta_group,
        )

    @dsl_user_op
    def consumer_release(self, state: PipelineState, *, loc=None, ip=None):
        """
        UMMA consumer release buffer empty, cta_group needs to be provided.
        """
        self.sync_object_empty.arrive(state.index, self.consumer_mask, self.cta_group)


@dataclass(frozen=True)
class PipelineUmmaAsync(PipelineAsync):
    """
    PipelineUmmaAsync is used for UMMA producers and AsyncThread consumers (e.g. Blackwell accumulator pipelines).
    """

    cta_group: cute.nvgpu.tcgen05.CtaGroup

    @dsl_user_op
    @staticmethod
    def _compute_tmem_sync_mask(cta_layout_vmnk: cute.Layout, *, loc=None, ip=None):
        """
        Computes a mask to signal completion of tmem buffers for 2CTA kernels.
        """
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster(loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )
        cta_in_cluster_coord_vmnk = cta_layout_vmnk.get_flat_coord(
            cta_rank_in_cluster, loc=loc, ip=ip
        )
        return cute.make_layout_image_mask(
            cta_layout_vmnk, cta_in_cluster_coord_vmnk, mode=0, loc=loc, ip=ip
        )

    @dsl_user_op
    @staticmethod
    def _compute_peer_cta_rank(*, loc=None, ip=None):
        """
        Computes a mask to signal release of tmem buffers for 2CTA kernels.
        """
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster(loc=loc, ip=ip),
            loc=loc,
            ip=ip,
        )
        return cta_rank_in_cluster // 2 * 2

    @dsl_user_op
    @staticmethod
    def create(
        *,
        num_stages: int,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        barrier_storage: cute.Pointer = None,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        defer_sync: bool = False,
        loc=None,
        ip=None,
    ):
        """Creates an instance of PipelineUmmaAsync with computed attributes.

        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: int
        :param producer_group: ``CooperativeGroup`` for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group: ``CooperativeGroup`` for the consumer agent
        :type consumer_group: CooperativeGroup
        :param barrier_storage: Pointer to the shared memory address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer, optional
        :param cta_layout_vmnk: Layout of the cluster shape
        :type cta_layout_vmnk: cute.Layout, optional
        :raises ValueError: If barrier_storage is not a cute.Pointer instance
        :return: New instance of ``PipelineUmmaAsync``
        :rtype: PipelineUmmaAsync
        """
        if not isinstance(barrier_storage, cute.Pointer):
            raise TypeError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        producer_type = PipelineOp.TCGen05Mma
        consumer_type = PipelineOp.AsyncThread

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_full = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8), num_stages, producer, loc=loc, ip=ip
        )
        sync_object_empty = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages,
            num_stages,
            consumer,
            loc=loc,
            ip=ip,
        )

        if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, loc=loc, ip=ip) == 1:
            # Set mask to None if not using clusters (i.e. 1CTA kernels)
            producer_mask = None
        else:
            producer_mask = PipelineUmmaAsync._compute_tmem_sync_mask(
                cta_layout_vmnk, loc=loc, ip=ip
            )

        if (
            cta_layout_vmnk is None
            or cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip) == 1
        ):
            # Set mask to None if not using 2CTA instructions
            consumer_mask = None
        else:
            consumer_mask = PipelineUmmaAsync._compute_peer_cta_rank(loc=loc, ip=ip)

        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cta_layout_vmnk is None
            or cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if (
                cta_layout_vmnk is None
                or cute.size(cta_layout_vmnk, loc=loc, ip=ip) == 1
            ):
                agent_sync(Agent.ThreadBlock)
            else:
                agent_sync(Agent.ThreadBlockCluster, is_relaxed=True)

        return PipelineUmmaAsync(
            sync_object_full,
            sync_object_empty,
            num_stages,
            producer_mask,
            consumer_mask,
            cta_group,
        )

    @dsl_user_op
    def producer_commit(self, state: PipelineState, *, loc=None, ip=None):
        """
        UMMA producer commit buffer full, cta_group needs to be provided.
        """
        self.sync_object_full.arrive(
            state.index, self.producer_mask, self.cta_group, loc=loc, ip=ip
        )

    @dsl_user_op
    @cute.jit
    def producer_tail(self, state: PipelineState, *, loc=None, ip=None):
        """
        Make sure the last used buffer empty signal is visible to producer.
        Producer tail is usually executed by producer before exit, to avoid dangling
        mbarrier arrive signals after kernel exit.

        :param state: The pipeline state that points to next useful buffer
        :type state: PipelineState
        """
        bidx_in_cluster = cute.arch.block_idx_in_cluster(loc=loc, ip=ip)
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            bidx_in_cluster, loc=loc, ip=ip
        )
        is_leader_cta = cta_rank_in_cluster % 2 == 0

        if is_leader_cta:
            # Assume state contains that next useful buffer
            # So we only need to advance to num_stages - 1 times to last used buffer
            for i in cutlass.range_constexpr(self.num_stages - 1):
                state.advance(loc=loc, ip=ip)
            self.producer_acquire(state, loc=loc, ip=ip)


@dataclass(frozen=True)
class PipelineClcFetchAsync:
    """
    PipelineClcFetchAsync implements a producer-consumer pipeline for Cluster Launch
    Control based dynamic scheduling. Both producer and consumer operate asynchronously
    using barrier synchronization to coordinate across pipeline stages and cluster CTAs.

    - Producer: waits for empty buffer, signals full barrier with transection bytes
      across all CTAs in cluster, hardware autosignals each CTA's mbarrier when
      transaction bytes are written, then the satte advance to next buffer slot.
    - Consumer: waits for full barrier, then load respinse from local SMEM, then
      sigals CTA 0's empty barrier to allow buffer reuse.
    """

    sync_object_full: SyncObject
    sync_object_empty: SyncObject
    num_stages: int
    producer_mask: Optional[Int32]
    consumer_mask: Optional[Int32]
    is_signalling_thread: Boolean

    @staticmethod
    @cute.jit
    def _init_full_barrier_arrive_signal(cta_layout_vmnk: cute.Layout, tidx: Int32):
        """
        Computes producer barrier signaling parameters, returns destination CTA rank
        (0 to cluster_size-1) based on thread ID, and a boolean flag indicating if
        this thread participates in signaling.

        :param cta_layout_vmnk: Cluster layout defining CTA count
        :param tidx: Thread ID within the CTA
        """
        dst_rank = tidx % 32
        is_signalling_thread = dst_rank < cute.size(cta_layout_vmnk)
        return dst_rank, is_signalling_thread

    @staticmethod
    def create(
        *,
        num_stages: int,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        tx_count: int,
        barrier_storage: cute.Pointer = None,
        producer_mask: Int32 = None,
        consumer_mask: Int32 = None,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        defer_sync: bool = False,
    ):
        """
        This helper function computes any necessary attributes and returns an instance of PipelineClcFetchAsync.
        :param barrier_storage: Pointer to the shared memory address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer
        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: int
        :param producer_group: `CooperativeGroup` for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group: `CooperativeGroup` for the consumer agent
        :type consumer_group: CooperativeGroup
        :param tx_count: Number of bytes expected to be written to the transaction barrier for one stage
        :type tx_count: int
        :param producer_mask: Mask for signaling arrives for the producer agent, defaults to ``None``
        :type producer_mask: Int32, optional
        :param consumer_mask: Mask for signaling arrives for the consumer agent, defaults to ``None``
        :type consumer_mask: Int32, optional
        """
        if not isinstance(barrier_storage, cute.Pointer):
            raise TypeError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        producer_type = PipelineOp.ClcLoad
        consumer_type = PipelineOp.AsyncThread

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)
        sync_object_full = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8), num_stages, producer, tx_count
        )
        sync_object_empty = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages, num_stages, consumer
        )

        if cta_layout_vmnk is None:
            cta_layout_vmnk = cute.make_layout((1, 1, 1, 1))

        tidx, _, _ = cute.arch.thread_idx()
        # All signalling happens from CTA 0's threads, each thread
        # in CTA 0 signals a different remote CTA's mbarrier.
        (producer_mask, is_signalling_thread) = (
            PipelineClcFetchAsync._init_full_barrier_arrive_signal(
                cta_layout_vmnk, tidx
            )
        )

        # The producer (sched warp) runs ONLY in CTA 0, all consumers
        # across the cluster must arrive at CTA 0's empty barrier
        consumer_mask = 0

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
                agent_sync(Agent.ThreadBlock)
            else:
                agent_sync(Agent.ThreadBlockCluster, is_relaxed=True)

        return PipelineClcFetchAsync(
            sync_object_full,
            sync_object_empty,
            num_stages,
            producer_mask,
            consumer_mask,
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
        Producer acquire waits for empty buffer and sets transaction expectation on full barrier.

        :param state: Pipeline state pointing to the current buffer stage
        :param try_acquire_token: Optional token to skip the empty barrier wait
        """
        if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_empty.wait(
                state.index, state.phase, loc=loc, ip=ip
            ),
            loc=loc,
            ip=ip,
        )
        if_generate(
            self.is_signalling_thread,
            lambda: self.sync_object_full.arrive(
                state.index, self.producer_mask, loc=loc, ip=ip
            ),
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def consumer_wait(
        self,
        state: PipelineState,
        try_wait_token: Optional[Boolean] = None,
        *,
        loc=None,
        ip=None,
    ):
        """
        Consumer waits for full barrier to be signaled by hardware multicast.

        :param state: Pipeline state pointing to the current buffer stage
        :param try_wait_token: Optional token to skip the full barrier wait
        """
        if_generate(
            try_wait_token is None or try_wait_token == 0,
            lambda: self.sync_object_full.wait(
                state.index, state.phase, loc=loc, ip=ip
            ),
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def consumer_release(self, state: PipelineState, *, loc=None, ip=None):
        self.sync_object_empty.arrive(state.index, self.consumer_mask, loc=loc, ip=ip)

    @dsl_user_op
    def producer_get_barrier(
        self, state: PipelineState, *, loc=None, ip=None
    ) -> cute.Pointer:
        return self.sync_object_full.get_barrier(state.index, loc=loc, ip=ip)

    @dsl_user_op
    def producer_tail(
        self,
        state: PipelineState,
        try_acquire_token: Optional[Boolean] = None,
        *,
        loc=None,
        ip=None,
    ):
        """
        Ensures all in-flight buffers are released before producer exits.

        :param state: Pipeline state with current position in the buffer
        :param try_acquire_token: Optional token to skip the empty barrier waits

        """
        for i in range(self.num_stages):
            if_generate(
                try_acquire_token is None or try_acquire_token == 0,
                lambda: self.sync_object_empty.wait(
                    state.index, state.phase, loc=loc, ip=ip
                ),
                loc=loc,
                ip=ip,
            )
            state.advance(loc=loc, ip=ip)


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
        """
        This helper function computes any necessary attributes and returns an instance of PipelineTmaMultiConsumersAsync.
        :param barrier_storage: Pointer to the smem address for this pipeline's mbarriers
        :type barrier_storage: cute.Pointer
        :param num_stages: Number of buffer stages for this pipeline
        :type num_stages: Int32
        :param producer_group: `CooperativeGroup` for the producer agent
        :type producer_group: CooperativeGroup
        :param consumer_group_umma: `CooperativeGroup` for the UMMA consumer agent
        :type consumer_group_umma: CooperativeGroup
        :param consumer_group_async: `CooperativeGroup` for the AsyncThread consumer agent
        :type consumer_group_async: CooperativeGroup
        :param tx_count: Number of bytes expected to be written to the transaction barrier for one stage
        :type tx_count: int
        :param cta_layout_vmnk: Layout of the cluster shape
        :type cta_layout_vmnk: cute.Layout | None
        """
        if not isinstance(barrier_storage, cute.Pointer):
            raise TypeError(
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

        sync_object_full = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8), num_stages, producer, tx_count
        )
        sync_object_empty = PipelineTmaUmma._make_sync_object(
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
        # All threadblocks are leaders if not using clusters
        is_leader_cta = True
        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, mode=[0]) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
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
        TMA producer acquire waits on buffer empty and sets the transaction barrier for leader threadblocks.
        """
        if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_empty.wait(
                state.index, state.phase, loc=loc, ip=ip
            ),
            loc=loc,
            ip=ip,
        )
        if_generate(
            self.is_leader_cta,
            lambda: self.sync_object_full.arrive(state.index, self.producer_mask),
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def producer_commit(self, state: PipelineState, *, loc=None, ip=None):
        """
        TMA producer commit is a noop since TMA instruction itself updates the transaction count.
        """
        pass

    @dsl_user_op
    def consumer_release(
        self, state: PipelineState, op_type: PipelineOp, *, loc=None, ip=None
    ):
        if op_type == PipelineOp.TCGen05Mma:
            self.sync_object_empty_umma.arrive(
                state.index, self.consumer_mask, self.cta_group, loc=loc, ip=ip
            )
        elif op_type == PipelineOp.AsyncThread:
            self.sync_object_empty_async.arrive(
                state.index, self.consumer_mask, loc=loc, ip=ip
            )
        else:
            raise ValueError(f"Invalid PipelineOp specified. op_type:{op_type}")
