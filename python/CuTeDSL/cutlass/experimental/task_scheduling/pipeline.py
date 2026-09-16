# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""TS pipeline overloads.

CuTeDSL TMA pipelines arm transaction barriers from every warp that calls
``producer_acquire`` because ``MbarrierArray.arrive_and_expect_tx`` is guarded
only by per-warp ``elect_one``.  TS sometimes intentionally maps several TMA
producer warps in one task to the same full barrier and wants one software
arrival carrying the aggregate transaction byte count.  ``TaskWarpLeader``
therefore keeps every producer warp in the empty-barrier acquire path, but
guards the full-barrier transaction arrive to the first warp assigned to the
task.
"""

from dataclasses import dataclass
from typing import Optional

from cutlass._mlir import ir
from cutlass.cutlass_dsl import Boolean, dsl_user_op, if_generate
import cutlass
import cutlass.cute as cute
import cutlass.pipeline as cutlass_pipeline


@dataclass(frozen=True)
class TSPipelineTmaAsync(cutlass_pipeline.PipelineTmaAsync):
    """TMA async pipeline with TS task-warp-leader barrier arming.

    Attributes
    ----------
    is_task_warp_leader : Boolean
        Predicate selecting the first warp assigned to the task.  Only this
        warp arms the transaction barrier when TS uses task-warp-leader
        signaling.
    """

    is_task_warp_leader: Boolean

    @staticmethod
    def create(  # type: ignore[override]
        *,
        num_stages: int,
        producer_group: cutlass_pipeline.CooperativeGroup,
        consumer_group: cutlass_pipeline.CooperativeGroup,
        tx_count: int,
        barrier_storage: cute.Pointer,
        is_task_warp_leader: Boolean,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        mcast_mode_mn: tuple[int, int] = (1, 1),
        defer_sync: bool = False,
    ) -> "TSPipelineTmaAsync":
        """Create an TS TMA async pipeline.

        Parameters
        ----------
        num_stages : int
            Number of pipeline stages.
        producer_group, consumer_group : cutlass.pipeline.CooperativeGroup
            Cooperative groups for producer and consumer sides.
        tx_count : int
            Transaction byte count expected by the full barrier.
        barrier_storage : cute.Pointer
            SMEM mbarrier storage.
        is_task_warp_leader : Boolean
            Predicate controlling task-warp-leader transaction arming.
        cta_layout_vmnk : cute.Layout, optional
            Cluster layout.
        mcast_mode_mn : tuple[int, int], optional
            TMA multicast mode.
        defer_sync : bool, optional
            Defer pipeline initialization synchronization.

        Returns
        -------
        TSPipelineTmaAsync
            Pipeline instance with TS producer acquire semantics.
        """
        base = cutlass_pipeline.PipelineTmaAsync.create(
            num_stages=num_stages,
            producer_group=producer_group,
            consumer_group=consumer_group,
            tx_count=tx_count,
            barrier_storage=barrier_storage,
            cta_layout_vmnk=cta_layout_vmnk,
            mcast_mode_mn=mcast_mode_mn,
            defer_sync=defer_sync,
        )
        return TSPipelineTmaAsync(
            base.sync_object_full,
            base.sync_object_empty,
            base.num_stages,
            base.producer_mask,
            base.consumer_mask,
            base.is_signaling_thread,
            is_task_warp_leader,
        )

    @dsl_user_op
    def producer_acquire(
        self,
        state: cutlass_pipeline.PipelineState,
        try_acquire_token: Optional[Boolean] = None,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Wait for empty on all producer warps; arm full only on task leader."""
        if_generate(
            try_acquire_token is None or try_acquire_token == 0,
            lambda: self.sync_object_empty.wait(  # type: ignore[call-arg]
                state.index, state.phase, loc=loc, ip=ip
            ),
            loc=loc,
            ip=ip,
        )

        def arrive_body() -> None:
            self.sync_object_full.arrive_and_expect_tx(  # type: ignore[attr-defined]
                state.index,
                self.sync_object_full.tx_count,  # type: ignore[attr-defined]
                loc=loc,
                ip=ip,
            )

        if_generate(self.is_task_warp_leader, arrive_body, loc=loc, ip=ip)


@dataclass(frozen=True)
class TSPipelineUmmaUmma(cutlass_pipeline.PipelineAsync):
    """Pipeline for a UMMA producer feeding a UMMA consumer.

    Attributes
    ----------
    cta_group : cute.nvgpu.tcgen05.CtaGroup
        TCGen05 CTA group used by producer commit and consumer release.
    """

    cta_group: cute.nvgpu.tcgen05.CtaGroup

    @staticmethod
    def create(  # type: ignore[override]
        *,
        num_stages: int,
        producer_group: cutlass_pipeline.CooperativeGroup,
        consumer_group: cutlass_pipeline.CooperativeGroup,
        barrier_storage: cute.Pointer,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        defer_sync: bool = False,
    ) -> "TSPipelineUmmaUmma":
        """Create an async pipeline with TCGen05 arrivals on both sides.

        Parameters
        ----------
        num_stages : int
            Number of pipeline stages.
        producer_group, consumer_group : cutlass.pipeline.CooperativeGroup
            Cooperative groups for producer and consumer sides.
        barrier_storage : cute.Pointer
            SMEM mbarrier storage.
        cta_layout_vmnk : cute.Layout, optional
            Cluster layout used to select CTA group and peer masks.
        defer_sync : bool, optional
            Defer pipeline initialization synchronization.

        Returns
        -------
        TSPipelineUmmaUmma
            Pipeline with UMMA-style full and empty barrier arrivals.
        """
        sync_object_full = cutlass_pipeline.PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8),
            num_stages,
            (cutlass_pipeline.PipelineOp.TCGen05Mma, producer_group),
        )
        sync_object_empty = cutlass_pipeline.PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages,
            num_stages,
            (cutlass_pipeline.PipelineOp.TCGen05Mma, consumer_group),
        )

        if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, mode=[0]) == 1:
            producer_mask = None
            consumer_mask = None
        else:
            peer_cta_mask = cutlass_pipeline.PipelineAsyncUmma._compute_peer_cta_mask(
                cta_layout_vmnk
            )
            producer_mask = peer_cta_mask
            consumer_mask = peer_cta_mask

        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, mode=[0]) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )

        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
                cutlass_pipeline.agent_sync(cutlass_pipeline.Agent.ThreadBlock)
            else:
                cutlass_pipeline.agent_sync(
                    cutlass_pipeline.Agent.ThreadBlockCluster,
                    is_relaxed=True,
                )

        return TSPipelineUmmaUmma(
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
        state: cutlass_pipeline.PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """UMMA producer commit of the full barrier."""
        self.sync_object_full.arrive(
            state.index,
            self.producer_mask,
            self.cta_group,
            loc=loc,
            ip=ip,
        )

    @dsl_user_op
    def consumer_release(
        self,
        state: cutlass_pipeline.PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """UMMA consumer release of the empty barrier."""
        self.sync_object_empty.arrive(
            state.index,
            self.consumer_mask,
            self.cta_group,
            loc=loc,
            ip=ip,
        )


@dataclass(frozen=True)
class TSPipelineAsyncUmma(cutlass_pipeline.PipelineAsyncUmma):
    """TS async-producer pipeline feeding a UMMA consumer.

    CUTLASS ``PipelineUmmaConsumerAsync`` does not use the
    generic async-thread destination-rank arrive for 2SM producer commits.
    It clears SM100's peer bit on the full-barrier address and emits one
    cluster-shared mbarrier arrive per producer thread, targeting SM0 of the
    collaborating pair.
    """

    producer_op: cutlass_pipeline.PipelineOp = cutlass_pipeline.PipelineOp.AsyncThread

    @staticmethod
    def create(  # type: ignore[override]
        *,
        num_stages: int,
        producer_group: cutlass_pipeline.CooperativeGroup,
        consumer_group: cutlass_pipeline.CooperativeGroup,
        barrier_storage: cute.Pointer,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        producer_op: cutlass_pipeline.PipelineOp = cutlass_pipeline.PipelineOp.AsyncThread,
        defer_sync: bool = False,
    ) -> "TSPipelineAsyncUmma":
        """Create an TS async-producer to UMMA-consumer pipeline.

        Parameters
        ----------
        num_stages : int
            Number of pipeline stages.
        producer_group, consumer_group : cutlass.pipeline.CooperativeGroup
            Cooperative groups for producer and consumer sides.
        barrier_storage : cute.Pointer
            SMEM mbarrier storage.
        cta_layout_vmnk : cute.Layout, optional
            Cluster layout.
        producer_op : cutlass.pipeline.PipelineOp, optional
            Producer-side operation, either ``AsyncThread`` or ``AsyncLoad``.
        defer_sync : bool, optional
            Defer pipeline initialization synchronization.

        Returns
        -------
        TSPipelineAsyncUmma
            Pipeline instance with TS producer commit semantics.
        """
        if producer_op == cutlass_pipeline.PipelineOp.AsyncThread:
            base = cutlass_pipeline.PipelineAsyncUmma.create(
                num_stages=num_stages,
                producer_group=producer_group,
                consumer_group=consumer_group,
                barrier_storage=barrier_storage,
                cta_layout_vmnk=cta_layout_vmnk,
                defer_sync=defer_sync,
            )
            return TSPipelineAsyncUmma(
                base.sync_object_full,
                base.sync_object_empty,
                base.num_stages,
                base.producer_mask,
                base.consumer_mask,
                base.cta_group,
                producer_op,
            )

        if producer_op != cutlass_pipeline.PipelineOp.AsyncLoad:
            raise ValueError(
                "TSPipelineAsyncUmma producer_op must be AsyncThread or "
                f"AsyncLoad, got {producer_op}."
            )

        sync_object_full = cutlass_pipeline.PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8),
            num_stages,
            (cutlass_pipeline.PipelineOp.AsyncLoad, producer_group),
        )
        sync_object_empty = cutlass_pipeline.PipelineTmaUmma._make_sync_object(
            barrier_storage.align(min_align=8) + num_stages,
            num_stages,
            (cutlass_pipeline.PipelineOp.TCGen05Mma, consumer_group),
        )
        cta_group = (
            cute.nvgpu.tcgen05.CtaGroup.ONE
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, mode=[0]) == 1
            else cute.nvgpu.tcgen05.CtaGroup.TWO
        )
        consumer_mask = (
            None
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk, mode=[0]) == 1
            else cutlass_pipeline.PipelineAsyncUmma._compute_peer_cta_mask(
                cta_layout_vmnk,
            )
        )
        if not defer_sync:
            cute.arch.mbarrier_init_fence()
            if cta_layout_vmnk is None or cute.size(cta_layout_vmnk) == 1:
                cutlass_pipeline.agent_sync(cutlass_pipeline.Agent.ThreadBlock)
            else:
                cutlass_pipeline.agent_sync(
                    cutlass_pipeline.Agent.ThreadBlockCluster,
                    is_relaxed=True,
                )
        return TSPipelineAsyncUmma(
            sync_object_full,
            sync_object_empty,
            num_stages,
            None,
            consumer_mask,
            cta_group,
            producer_op,
        )

    @dsl_user_op
    def producer_commit(
        self,
        state: cutlass_pipeline.PipelineState,
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Publish full barrier using CUTLASS 2SM UMMA-consumer semantics."""
        if (
            self.producer_op == cutlass_pipeline.PipelineOp.AsyncThread
            and self.cta_group is cute.nvgpu.tcgen05.CtaGroup.TWO
        ):
            assert isinstance(self.sync_object_full, cutlass_pipeline.MbarrierArray)
            mbar_addr = self.sync_object_full.get_barrier(
                state.index, loc=loc, ip=ip
            ).toint(loc=loc, ip=ip) & cutlass.Int32(0xFEFFFFFF)
            cute.arch.inline_ptx(
                "mbarrier.arrive.shared::cluster.b64 _, [{$r0}];",
                read_only_args=[mbar_addr],
                loc=loc,
                ip=ip,
            )
        else:
            self.sync_object_full.arrive(
                state.index, self.producer_mask, loc=loc, ip=ip
            )
