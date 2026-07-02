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

import warnings
from dataclasses import dataclass
from typing import TYPE_CHECKING, Literal, Optional, cast

from cutlass._mlir import ir

import cutlass
import cutlass.cute as cute
from cutlass.cute.arch.constants import WARP_SIZE
from cutlass.cute.core import is_static
from cutlass.cutlass_dsl import BaseDSL, Boolean, Int32, if_generate, dsl_user_op

from cutlass.pipeline import (
    Agent,
    CooperativeGroup,
    MbarrierLayout,
    PipelineOp,
    SyncObject,
    MbarrierArray,
    TmaStoreFence,
    PipelineState,
    PipelineAsync,
    alloc_reserved_mbarrier,
    agent_sync,
)
from cutlass.pipeline.helpers import _get_thread_arrive_count
from cutlass.pipeline.profiling import register_barrier

if TYPE_CHECKING:
    from cutlass.pipeline.sm90 import PipelineConsumer, PipelineProducer

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
        mbarrier_layout: MbarrierLayout = MbarrierLayout.V0,
        name: str = "",
        phase: Literal["", "full", "empty"] = "",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> SyncObject:
        """
        Returns a SyncObject corresponding to an agent's PipelineOp.
        """
        full_name = f"{name}.{phase}" if name and phase else name
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
                mbarrier_layout=mbarrier_layout,
                name=full_name,
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
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Int32:
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
    def _compute_is_leader_cta(
        cta_layout_vmnk: cute.Layout,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Boolean:
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
        barrier_storage: Optional[cute.Pointer] = None,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        mcast_mode_mn: tuple[int, int] = (1, 1),
        enable_multicast_signaling: bool = False,
        defer_sync: bool = False,
        name: str = "",
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "PipelineTmaUmma":
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
        :param enable_multicast_signaling: See docstring in PipelineTmaAsync.create() for details
        :type enable_multicast_signaling: bool, optional
        :param defer_sync: Bool specifying whether or not to skip the built-in mbarrier fence and sync for performance, defaults to False
        :type defer_sync: bool, optional
        :raises ValueError: If barrier_storage is not a cute.Pointer instance
        :return: A new PipelineTmaUmma instance configured with the provided parameters
        :rtype: PipelineTmaUmma
        """
        # Create barrier storage at reserved low address of smem
        if barrier_storage is None:
            barrier_storage = alloc_reserved_mbarrier(num_stages)
        if not isinstance(barrier_storage, cute.Pointer):
            raise TypeError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        if not is_static(cta_layout_vmnk):
            raise ValueError("The cluster shape (cta_layout_vmnk) needs to be static.")

        if cta_layout_vmnk is None:
            cta_layout_vmnk = cute.make_layout((1, 1, 1, 1))

        producer_type = PipelineOp.TmaLoad
        consumer_type = PipelineOp.TCGen05Mma

        producer = (producer_type, producer_group)

        if enable_multicast_signaling:
            consumer_thread_arrive_cnt = _get_thread_arrive_count(consumer_group)

            if (
                isinstance(consumer_thread_arrive_cnt, int)
                and consumer_thread_arrive_cnt % WARP_SIZE != 0
            ):
                raise ValueError(
                    "Error: Consumer arrival count must be aligned with warp size"
                )

            shape_vmnk = cast(tuple[int, ...], cta_layout_vmnk.shape)
            mcast_m_size = shape_vmnk[2] if mcast_mode_mn[0] else 0
            mcast_n_size = shape_vmnk[1] if mcast_mode_mn[1] else 0
            overlap = 1 if (mcast_mode_mn[0] and mcast_mode_mn[1]) else 0
            mcast_size = mcast_m_size + mcast_n_size - overlap
            assert mcast_size > 0, "Mcast size must be greater than 0."

            num_warps = consumer_thread_arrive_cnt // WARP_SIZE
            num_signaling_threads = mcast_size * num_warps

            thread_consumer_group = CooperativeGroup(
                Agent.Thread, num_signaling_threads
            )
        else:
            thread_consumer_group = consumer_group

        consumer = (consumer_type, thread_consumer_group)

        sync_object_full = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8),
            num_stages,
            producer,
            tx_count,
            name=name,
            phase="full",
            loc=loc,
            ip=ip,
        )
        sync_object_empty = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages,
            num_stages,
            consumer,
            name=name,
            phase="empty",
            loc=loc,
            ip=ip,
        )

        if name:
            register_barrier(name, num_stages, "PipelineTmaUmma")

        if cute.size(cta_layout_vmnk, loc=loc, ip=ip) == 1:
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
            if cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )

        consumer_mask = producer_mask

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if cute.size(cta_layout_vmnk, loc=loc, ip=ip) == 1:
                agent_sync(Agent.ThreadBlock)
            else:
                agent_sync(Agent.ThreadBlockCluster, is_relaxed=True)

        return PipelineTmaUmma(
            sync_object_full,
            sync_object_empty,
            num_stages,
            producer_mask,  # unused
            consumer_mask,
            is_leader_cta,
            cta_group,
        )

    @dsl_user_op
    def consumer_release(
        self,
        state: PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
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
        expected_tx: Optional[Int32] = None,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        TMA producer conditionally waits on buffer empty and sets the transaction barrier for leader threadblocks.

        :param expected_tx: Override the expected transaction byte count for this
            acquire. When ``None`` (default), uses the ``tx_count`` from barrier init.
            Pass a dynamic value for workloads where the byte count varies per
            iteration (e.g. sparse GEMM with conditional metadata loading).
        """
        if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_empty.wait(
                state.index, state.phase, loc=loc, ip=ip
            ),
            loc=loc,
            ip=ip,
        )
        tx = self.sync_object_full.tx_count if expected_tx is None else expected_tx  # type: ignore[attr-defined]

        def arrive_body() -> None:
            self.sync_object_full.arrive_and_expect_tx(state.index, tx, loc=loc, ip=ip)  # type: ignore[attr-defined]

        if_generate(
            self.is_leader_cta,
            arrive_body,
            loc=loc,
            ip=ip,
        )

    def producer_commit(self, state: PipelineState) -> None:
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
    def _compute_leading_cta_rank(
        cta_v_size: int,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Int32:
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
    def _compute_is_leader_cta(
        cta_layout_vmnk: cute.Layout,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Boolean:
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
    def _compute_peer_cta_mask(
        cta_layout_vmnk: cute.Layout,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Int32:
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
        barrier_storage: Optional[cute.Pointer] = None,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        defer_sync: bool = False,
        name: str = "",
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "PipelineAsyncUmma":
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
        # Create barrier storage at reserved low address of smem
        if barrier_storage is None:
            barrier_storage = alloc_reserved_mbarrier(num_stages)
        if not isinstance(barrier_storage, cute.Pointer):
            raise TypeError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        if not is_static(cta_layout_vmnk):
            raise ValueError("The cluster shape (cta_layout_vmnk) needs to be static.")

        if cta_layout_vmnk is None:
            cta_layout_vmnk = cute.make_layout((1, 1, 1, 1))

        producer_type = PipelineOp.AsyncThread
        consumer_type = PipelineOp.TCGen05Mma

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_full = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8),
            num_stages,
            producer,
            name=name,
            phase="full",
            loc=loc,
            ip=ip,
        )
        sync_object_empty = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages,
            num_stages,
            consumer,
            name=name,
            phase="empty",
            loc=loc,
            ip=ip,
        )

        if name:
            register_barrier(name, num_stages, "PipelineAsyncUmma")

        cta_v_size = cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip)
        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )
        if cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip) == 1:
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
            if cute.size(cta_layout_vmnk, loc=loc, ip=ip) == 1:
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
    def consumer_release(
        self,
        state: PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        UMMA consumer release buffer empty, cta_group needs to be provided.
        """
        self.sync_object_empty.arrive(
            state.index, self.consumer_mask, self.cta_group, loc=loc, ip=ip
        )


@dataclass(frozen=True)
class PipelineUmmaAsync(PipelineAsync):
    """
    PipelineUmmaAsync is used for UMMA producers and AsyncThread consumers (e.g. Blackwell accumulator pipelines).
    """

    cta_group: cute.nvgpu.tcgen05.CtaGroup

    @dsl_user_op
    @staticmethod
    def _compute_tmem_sync_mask(
        cta_layout_vmnk: cute.Layout,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Int32:
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
    def _compute_peer_cta_rank(
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Int32:
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
        barrier_storage: Optional[cute.Pointer] = None,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        defer_sync: bool = False,
        name: str = "",
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "PipelineUmmaAsync":
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
        # Create barrier storage at reserved low address of smem
        if barrier_storage is None:
            barrier_storage = alloc_reserved_mbarrier(num_stages)
        if not isinstance(barrier_storage, cute.Pointer):
            raise TypeError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        if not is_static(cta_layout_vmnk):
            raise ValueError("The cluster shape (cta_layout_vmnk) needs to be static.")

        if cta_layout_vmnk is None:
            cta_layout_vmnk = cute.make_layout((1, 1, 1, 1))

        producer_type = PipelineOp.TCGen05Mma
        consumer_type = PipelineOp.AsyncThread

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_full = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8),
            num_stages,
            producer,
            name=name,
            phase="full",
            loc=loc,
            ip=ip,
        )
        sync_object_empty = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages,
            num_stages,
            consumer,
            name=name,
            phase="empty",
            loc=loc,
            ip=ip,
        )

        if name:
            register_barrier(name, num_stages, "PipelineUmmaAsync")

        if cute.size(cta_layout_vmnk, loc=loc, ip=ip) == 1:
            # Set mask to None if not using clusters (i.e. 1CTA kernels)
            producer_mask = None
        else:
            producer_mask = PipelineUmmaAsync._compute_tmem_sync_mask(
                cta_layout_vmnk, loc=loc, ip=ip
            )

        if cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip) == 1:
            # Set mask to None if not using 2CTA instructions
            consumer_mask = None
        else:
            consumer_mask = PipelineUmmaAsync._compute_peer_cta_rank(loc=loc, ip=ip)

        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cute.size(cta_layout_vmnk, mode=[0], loc=loc, ip=ip) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if cute.size(cta_layout_vmnk, loc=loc, ip=ip) == 1:
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
    def producer_commit(
        self,
        state: PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        UMMA producer commit buffer full, cta_group needs to be provided.
        """
        self.sync_object_full.arrive(
            state.index, self.producer_mask, self.cta_group, loc=loc, ip=ip
        )

    @dsl_user_op
    @cute.jit
    def producer_tail(
        self,
        state: PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
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
class PipelineClcFetchAsync(PipelineAsync):
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
    is_signaling_thread: Boolean

    @staticmethod
    @cute.jit
    def _init_full_barrier_arrive_signal(
        cta_layout_vmnk: cute.Layout, tidx: Int32
    ) -> tuple[Int32, Boolean]:
        """
        Computes producer barrier signaling parameters, returns destination CTA rank
        (0 to cluster_size-1) based on thread ID, and a boolean flag indicating if
        this thread participates in signaling.

        :param cta_layout_vmnk: Cluster layout defining CTA count
        :param tidx: Thread ID within the CTA
        """
        dst_rank = tidx % WARP_SIZE
        is_signaling_thread = dst_rank < cute.size(cta_layout_vmnk)
        return dst_rank, is_signaling_thread

    @staticmethod
    def create(  # type: ignore[override]
        *,
        num_stages: int,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        tx_count: int,
        barrier_storage: Optional[cute.Pointer] = None,
        producer_mask: Optional[Int32] = None,
        consumer_mask: Optional[Int32] = None,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        defer_sync: bool = False,
        name: str = "",
    ) -> "PipelineClcFetchAsync":
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
        # Create barrier storage at reserved low address of smem
        if barrier_storage is None:
            barrier_storage = alloc_reserved_mbarrier(num_stages)
        if not isinstance(barrier_storage, cute.Pointer):
            raise TypeError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        if not is_static(cta_layout_vmnk):
            raise ValueError("The cluster shape (cta_layout_vmnk) needs to be static.")

        if cta_layout_vmnk is None:
            cta_layout_vmnk = cute.make_layout((1, 1, 1, 1))

        producer_type = PipelineOp.ClcLoad
        consumer_type = PipelineOp.AsyncThread

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)
        sync_object_full = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8),
            num_stages,
            producer,
            tx_count,
            name=name,
            phase="full",
        )
        sync_object_empty = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages,
            num_stages,
            consumer,
            name=name,
            phase="empty",
        )

        if name:
            register_barrier(name, num_stages, "PipelineClcFetchAsync")

        tidx, _, _ = cute.arch.thread_idx()
        # All signaling happens from CTA 0's threads, each thread
        # in CTA 0 signals a different remote CTA's mbarrier.
        (producer_mask, is_signaling_thread) = (
            PipelineClcFetchAsync._init_full_barrier_arrive_signal(
                cta_layout_vmnk, tidx
            )
        )

        # The producer (sched warp) runs ONLY in CTA 0, all consumers
        # across the cluster must arrive at CTA 0's empty barrier
        consumer_mask = 0  # type: ignore[assignment]

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if cute.size(cta_layout_vmnk) == 1:
                agent_sync(Agent.ThreadBlock)
            else:
                agent_sync(Agent.ThreadBlockCluster, is_relaxed=True)

        return PipelineClcFetchAsync(
            sync_object_full,
            sync_object_empty,
            num_stages,
            producer_mask,
            consumer_mask,
            is_signaling_thread,
        )

    @dsl_user_op
    def producer_acquire(
        self,
        state: PipelineState,
        try_acquire_token: Optional[Boolean] = None,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
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
            self.is_signaling_thread,
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
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
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
    def consumer_release(
        self,
        state: PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        self.sync_object_empty.arrive(state.index, self.consumer_mask, loc=loc, ip=ip)

    @dsl_user_op
    def producer_get_barrier(
        self,
        state: PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Pointer:
        return self.sync_object_full.get_barrier(state.index, loc=loc, ip=ip)  # type: ignore[call-arg, return-value]

    @dsl_user_op
    def consumer_get_barrier(
        self,
        state: PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> cute.Pointer:
        return self.sync_object_empty.get_barrier(state.index, loc=loc, ip=ip)  # type: ignore[call-arg, return-value]


@dataclass(frozen=True)
class PipelineTmaMultiConsumersAsync(PipelineAsync):
    """
    PipelineTmaMultiConsumersAsync is used for TMA producers and UMMA+Async consumers.
    """

    is_leader_cta: bool
    sync_object_empty_umma: SyncObject
    sync_object_empty_async: SyncObject
    cta_group: cute.nvgpu.tcgen05.CtaGroup
    consumer_dst_rank_async: Optional[Int32] = None
    is_signaling_thread: Boolean = True  # type: ignore[assignment]

    @staticmethod
    def create(  # type: ignore[override]
        *,
        num_stages: int,
        producer_group: CooperativeGroup,
        consumer_group_umma: CooperativeGroup,
        consumer_group_async: CooperativeGroup,
        tx_count: int,
        barrier_storage: Optional[cute.Pointer] = None,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        mcast_mode_mn: tuple[int, int] = (1, 1),
        tidx: Optional[Int32] = None,
        enable_multicast_signaling: bool = False,
        defer_sync: bool = False,
        force_deprecated_per_lane_signaling: Optional[bool] = None,
        name: str = "",
    ) -> "PipelineTmaMultiConsumersAsync":
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
        :param mcast_mode_mn: Tuple specifying multicast modes for m and n dimensions (each 0 or 1)
        :type mcast_mode_mn: tuple[int, int]
        :param tidx: Thread index for computing AsyncThread consumer signaling, defaults to thread_idx()[0]
        :type tidx: Int32 | None
        :param enable_multicast_signaling: See docstring in PipelineTmaAsync.create() for details
        :type enable_multicast_signaling: bool, optional
        :param force_deprecated_per_lane_signaling: **Deprecated.** Set ``False`` if your arrive count is a multiple of ``WARP_SIZE`` and you do not want the legacy fallback. Leave unset otherwise.
        :type force_deprecated_per_lane_signaling: bool | None
        """
        # Create barrier storage at reserved low address of smem
        if barrier_storage is None:
            barrier_storage = alloc_reserved_mbarrier(num_stages)
        if not isinstance(barrier_storage, cute.Pointer):
            raise TypeError(
                f"Expected barrier_storage to be a cute.Pointer, but got {type(barrier_storage)}"
            )

        if not is_static(cta_layout_vmnk):
            raise ValueError("The cluster shape (cta_layout_vmnk) needs to be static.")

        if cta_layout_vmnk is None:
            cta_layout_vmnk = cute.make_layout((1, 1, 1, 1))

        producer_type = PipelineOp.TmaLoad
        consumer_type = PipelineOp.Composite
        consumer_type_umma = PipelineOp.TCGen05Mma
        consumer_type_async = PipelineOp.AsyncThread

        if consumer_group_umma.agent != consumer_group_async.agent:
            raise ValueError(
                "UMMA and AsyncThread consumer groups must be the same agent"
            )

        if enable_multicast_signaling and force_deprecated_per_lane_signaling:
            raise ValueError(
                "enable_multicast_signaling unsupported with force_deprecated_per_lane_signaling"
            )

        if enable_multicast_signaling:
            consumer_thread_arrive_cnt_umma = _get_thread_arrive_count(
                consumer_group_umma
            )
            consumer_thread_arrive_cnt_async = _get_thread_arrive_count(
                consumer_group_async
            )

            if (
                isinstance(consumer_thread_arrive_cnt_umma, int)
                and consumer_thread_arrive_cnt_umma % WARP_SIZE != 0
            ):
                raise ValueError(
                    "Error: UMMA consumer arrival count must be aligned with warp size"
                )
            if (
                isinstance(consumer_thread_arrive_cnt_async, int)
                and consumer_thread_arrive_cnt_async % WARP_SIZE != 0
            ):
                raise ValueError(
                    "Error: AsyncThread consumer arrival count must be aligned with warp size"
                )

            shape_vmnk = cast(tuple[int, ...], cta_layout_vmnk.shape)
            mcast_m_size = shape_vmnk[2] if mcast_mode_mn[0] else 0
            mcast_n_size = shape_vmnk[1] if mcast_mode_mn[1] else 0
            overlap = 1 if (mcast_mode_mn[0] and mcast_mode_mn[1]) else 0
            mcast_size = mcast_m_size + mcast_n_size - overlap
            assert mcast_size > 0, "Mcast size must be greater than 0."

            num_warps_umma = consumer_thread_arrive_cnt_umma // WARP_SIZE
            num_signaling_threads_umma = mcast_size * num_warps_umma

            num_warps_async = consumer_thread_arrive_cnt_async // WARP_SIZE
            num_signaling_threads_async = mcast_size * num_warps_async

            thread_consumer_group_umma = CooperativeGroup(
                Agent.Thread, num_signaling_threads_umma
            )
            thread_consumer_group_async = CooperativeGroup(
                Agent.Thread, num_signaling_threads_async
            )
        else:
            thread_consumer_group_umma = consumer_group_umma
            thread_consumer_group_async = consumer_group_async

        def _looks_legacy(cg: CooperativeGroup) -> bool:
            return (
                cg.agent is Agent.Thread
                and cg.size >= WARP_SIZE
                and cg.size % WARP_SIZE == 0
            )

        if force_deprecated_per_lane_signaling is None:
            force_deprecated_per_lane_signaling = not enable_multicast_signaling and (
                _looks_legacy(thread_consumer_group_umma)
                or _looks_legacy(thread_consumer_group_async)
            )
            if force_deprecated_per_lane_signaling:
                warnings.warn(
                    "PipelineTmaMultiConsumersAsync now expects only one lane "
                    "per warp to arrive on the empty barrier, but consumer_group "
                    "arrive count is a multiple of WARP_SIZE - this suggests you are expecting the"
                    "legacy behavior where every lane arrives. Falling back to "
                    "the legacy path. Divide the arrive count by WARP_SIZE to "
                    "migrate, or pass force_deprecated_per_lane_signaling=False to opt out of "
                    "this auto-detection.",
                    DeprecationWarning,
                    stacklevel=2,
                )
        elif force_deprecated_per_lane_signaling:
            warnings.warn(
                "force_deprecated_per_lane_signaling=True is deprecated.",
                DeprecationWarning,
                stacklevel=2,
            )

        if force_deprecated_per_lane_signaling:
            cluster_size = (
                cute.size(cta_layout_vmnk) if cta_layout_vmnk is not None else 1
            )
            if cluster_size > 1:
                raise ValueError(
                    "force_deprecated_per_lane_signaling does not support multicast "
                    "(cluster_size > 1)."
                )

        consumer_group = CooperativeGroup(
            thread_consumer_group_umma.agent,
            thread_consumer_group_umma.size + thread_consumer_group_async.size,
        )

        producer = (producer_type, producer_group)
        consumer = (consumer_type, consumer_group)

        sync_object_full = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8),
            num_stages,
            producer,
            tx_count,
            name=name,
            phase="full",
        )
        sync_object_empty = PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages,
            num_stages,
            consumer,
            name=name,
            phase="empty",
        )

        if name:
            register_barrier(name, num_stages, "PipelineTmaMultiConsumersAsync")
        sync_object_empty_umma = sync_object_empty.recast_to_new_op_type(
            consumer_type_umma
        )
        sync_object_empty_async = sync_object_empty.recast_to_new_op_type(
            consumer_type_async
        )

        # Compute AsyncThread consumer signaling (dst_rank + is_signaling_thread)
        if force_deprecated_per_lane_signaling:
            dst_rank_async = None
            is_signaling_thread = Boolean(True)
        else:
            if tidx is None:
                tidx, _, _ = cute.arch.thread_idx()
            (
                dst_rank_async,
                is_signaling_thread,
            ) = PipelineTmaMultiConsumersAsync._init_empty_barrier_arrive_signal_2sm(
                cta_layout_vmnk, tidx, mcast_mode_mn
            )

        if cute.size(cta_layout_vmnk) == 1:
            # No mcast mask if not using clusters
            producer_mask = None
            consumer_mask = None
            consumer_dst_rank_async = None
            is_leader_cta = True
        else:
            producer_mask = None
            consumer_mask = PipelineTmaUmma._compute_mcast_arrival_mask(
                cta_layout_vmnk, mcast_mode_mn
            )
            consumer_dst_rank_async = dst_rank_async
            is_leader_cta = PipelineTmaUmma._compute_is_leader_cta(cta_layout_vmnk)

        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cute.size(cta_layout_vmnk, mode=[0]) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if cute.size(cta_layout_vmnk) == 1:
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
            consumer_dst_rank_async,
            is_signaling_thread,
        )

    @staticmethod
    @cute.jit
    def _init_empty_barrier_arrive_signal_2sm(
        cta_layout_vmnk: cute.Layout,
        tidx: Int32,
        mcast_mode_mn: tuple[int, int] = (1, 1),
    ) -> tuple[Int32, Boolean]:
        """
        Identical to sm90.py PipelineTmaAsync.init_empty_barrier_arrive_signal except
        that CTAs in the multicast will also signal CTAs with a different V-coordinate (i.e. leader/follower CTA pairs).
        """
        # Logic to optimally schedule Empty Arrives
        cluster_shape_vmnk = cta_layout_vmnk.shape

        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )

        tidx = tidx % WARP_SIZE
        is_signaling_thread = tidx < cute.size(cluster_shape_vmnk)
        dst_rank = tidx % cute.size(cluster_shape_vmnk)

        dst_cta_coord = cta_layout_vmnk.get_hier_coord(dst_rank)
        cur_cta_coord = cta_layout_vmnk.get_hier_coord(cta_rank_in_cluster)
        assert isinstance(dst_cta_coord, tuple)
        assert isinstance(cur_cta_coord, tuple)

        is_mcast_mode_m = (
            dst_cta_coord[1] == cur_cta_coord[1]
            and dst_cta_coord[3] == cur_cta_coord[3]
        )
        is_mcast_mode_n = (
            dst_cta_coord[2] == cur_cta_coord[2]
            and dst_cta_coord[3] == cur_cta_coord[3]
        )

        assert not (mcast_mode_mn[0] == 0 and mcast_mode_mn[1] == 0)
        if mcast_mode_mn[0] == 1 and mcast_mode_mn[1] == 0:
            is_signaling_thread = is_signaling_thread and is_mcast_mode_m
        elif mcast_mode_mn[0] == 0 and mcast_mode_mn[1] == 1:
            is_signaling_thread = is_signaling_thread and is_mcast_mode_n
        elif mcast_mode_mn[0] == 1 and mcast_mode_mn[1] == 1:
            is_mcast_mode_m_or_n = is_mcast_mode_m or is_mcast_mode_n
            is_signaling_thread = is_signaling_thread and is_mcast_mode_m_or_n

        return dst_rank, is_signaling_thread

    @dsl_user_op
    def producer_acquire(
        self,
        state: PipelineState,
        try_acquire_token: Optional[Boolean] = None,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
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
    def producer_commit(
        self,
        state: PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """
        TMA producer commit is a noop since TMA instruction itself updates the transaction count.
        """
        pass

    @dsl_user_op
    def consumer_wait(
        self,
        state: PipelineState,
        try_wait_token: Optional[Boolean] = None,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Consumer waits for full barrier to be signaled."""
        if_generate(
            try_wait_token is None or try_wait_token == 0,
            lambda: self.sync_object_full.wait(
                state.index, state.phase, loc=loc, ip=ip
            ),
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def consumer_try_wait(
        self,
        state: PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> Boolean:
        """Non-blocking check if data is ready."""
        return self.sync_object_full.try_wait(state.index, state.phase, loc=loc, ip=ip)  # type: ignore[attr-defined]

    @dsl_user_op
    def consumer_release(
        self,
        state: PipelineState,
        op_type: PipelineOp = PipelineOp.TCGen05Mma,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        if op_type == PipelineOp.TCGen05Mma:
            self.sync_object_empty_umma.arrive(
                state.index, self.consumer_mask, self.cta_group, loc=loc, ip=ip
            )
        elif op_type == PipelineOp.AsyncThread:
            if_generate(
                self.is_signaling_thread,
                lambda: self.sync_object_empty_async.arrive(
                    state.index, self.consumer_dst_rank_async, loc=loc, ip=ip
                ),
                loc=loc,
                ip=ip,
            )
        else:
            raise ValueError(f"Invalid PipelineOp specified. op_type:{op_type}")

    @dsl_user_op
    def make_participants(
        self,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> "tuple[PipelineProducer, PipelineConsumer, None]":
        """Returns (producer, umma_consumer, None)."""
        return (
            self.make_producer(loc=loc, ip=ip),
            self.make_consumer(loc=loc, ip=ip),
            None,
        )
