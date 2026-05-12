# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

"""SM120 CTA-local TMA pipeline helpers."""

from dataclasses import dataclass
from typing import Optional, Tuple

from cutlass.cutlass_dsl import Boolean, Int32, Int64, dsl_user_op
from cutlass.cute.nvgpu import cpasync
from cutlass.cute.typing import Pointer
from cutlass.pipeline import CooperativeGroup, PipelineState
from cutlass.pipeline.sm90 import PipelineTmaAsync


@dataclass(frozen=True)
class PipelineTmaWarpMma(PipelineTmaAsync):
    """SM120 CTA-local TMA pipeline for warp-level MMA consumers."""

    @staticmethod
    def create(
        *,
        num_stages: int,
        producer_group: CooperativeGroup,
        consumer_group: CooperativeGroup,
        tx_count: int,
        barrier_storage: Optional[Pointer] = None,
        cta_layout_vmnk=None,
        tidx: Optional[Int32] = None,
        mcast_mode_mn: Tuple[int, int] = (1, 1),
        defer_sync: bool = False,
    ) -> "PipelineTmaWarpMma":
        base = PipelineTmaAsync.create(
            num_stages=num_stages,
            producer_group=producer_group,
            consumer_group=consumer_group,
            tx_count=tx_count,
            barrier_storage=barrier_storage,
            cta_layout_vmnk=cta_layout_vmnk,
            tidx=tidx,
            mcast_mode_mn=mcast_mode_mn,
            defer_sync=defer_sync,
        )
        return PipelineTmaWarpMma(
            base.sync_object_full,
            base.sync_object_empty,
            base.num_stages,
            base.producer_mask,
            base.consumer_mask,
            base.is_signalling_thread,
        )


@dsl_user_op
def issue_tma_load_3d(
    pipe: PipelineTmaWarpMma,
    producer_state: PipelineState,
    dst_smem_ptr: Pointer,
    tma_desc_ptr: Pointer,
    coord0: Int32,
    coord1: Int32,
    coord2: Int32,
    *,
    cache_policy: Optional[Int64] = None,
    already_elected: bool = False,
    tile_mode: bool = False,
    loc=None,
    ip=None,
) -> None:
    """Issue one SM120 rank-3 TMA load on a pipeline barrier.

    Coordinates are passed directly to the tensor-map instruction and must match the external descriptor's rank and basis.
    Descriptor-memory visibility is handled by the SM120 raw TMA helper, which emits a tensor-map acquire fence before issue.
    """
    cpasync.sm120_tma_load_3d(
        dst_smem_ptr,
        tma_desc_ptr,
        pipe.producer_get_barrier(producer_state),
        coord0,
        coord1,
        coord2,
        cache_policy=cache_policy,
        already_elected=already_elected,
        tile_mode=tile_mode,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def issue_tma_load_4d(
    pipe: PipelineTmaWarpMma,
    producer_state: PipelineState,
    dst_smem_ptr: Pointer,
    tma_desc_ptr: Pointer,
    coord0: Int32,
    coord1: Int32,
    coord2: Int32,
    coord3: Int32,
    *,
    cache_policy: Optional[Int64] = None,
    already_elected: bool = False,
    tile_mode: bool = False,
    loc=None,
    ip=None,
) -> None:
    """Issue one SM120 rank-4 TMA load on a pipeline barrier.

    Coordinates are passed directly to the tensor-map instruction and must match the external descriptor's rank and basis.
    Descriptor-memory visibility is handled by the SM120 raw TMA helper, which emits a tensor-map acquire fence before issue.
    """
    cpasync.sm120_tma_load_4d(
        dst_smem_ptr,
        tma_desc_ptr,
        pipe.producer_get_barrier(producer_state),
        coord0,
        coord1,
        coord2,
        coord3,
        cache_policy=cache_policy,
        already_elected=already_elected,
        tile_mode=tile_mode,
        loc=loc,
        ip=ip,
    )


@dsl_user_op
def producer_acquire_issue_tma_load_3d(
    pipe: PipelineTmaWarpMma,
    producer_state: PipelineState,
    try_acquire_token: Optional[Boolean],
    dst_smem_ptr: Pointer,
    tma_desc_ptr: Pointer,
    coord0: Int32,
    coord1: Int32,
    coord2: Int32,
    *,
    cache_policy: Optional[Int64] = None,
    already_elected: bool = False,
    tile_mode: bool = False,
    loc=None,
    ip=None,
) -> None:
    """Acquire a producer stage and issue one SM120 rank-3 TMA load.

    Coordinates are passed directly to the tensor-map instruction and must match the external descriptor's rank and basis.
    Descriptor-memory visibility is handled by the SM120 raw TMA helper, which emits a tensor-map acquire fence before issue.
    """
    pipe.producer_acquire(producer_state, try_acquire_token, loc=loc, ip=ip)
    issue_tma_load_3d(
        pipe,
        producer_state,
        dst_smem_ptr,
        tma_desc_ptr,
        coord0,
        coord1,
        coord2,
        cache_policy=cache_policy,
        already_elected=already_elected,
        tile_mode=tile_mode,
        loc=loc,
        ip=ip,
    )
    pipe.producer_commit(producer_state, loc=loc, ip=ip)


@dsl_user_op
def producer_acquire_issue_tma_load_4d(
    pipe: PipelineTmaWarpMma,
    producer_state: PipelineState,
    try_acquire_token: Optional[Boolean],
    dst_smem_ptr: Pointer,
    tma_desc_ptr: Pointer,
    coord0: Int32,
    coord1: Int32,
    coord2: Int32,
    coord3: Int32,
    *,
    cache_policy: Optional[Int64] = None,
    already_elected: bool = False,
    tile_mode: bool = False,
    loc=None,
    ip=None,
) -> None:
    """Acquire a producer stage and issue one SM120 rank-4 TMA load.

    Coordinates are passed directly to the tensor-map instruction and must match the external descriptor's rank and basis.
    Descriptor-memory visibility is handled by the SM120 raw TMA helper, which emits a tensor-map acquire fence before issue.
    """
    pipe.producer_acquire(producer_state, try_acquire_token, loc=loc, ip=ip)
    issue_tma_load_4d(
        pipe,
        producer_state,
        dst_smem_ptr,
        tma_desc_ptr,
        coord0,
        coord1,
        coord2,
        coord3,
        cache_policy=cache_policy,
        already_elected=already_elected,
        tile_mode=tile_mode,
        loc=loc,
        ip=ip,
    )
    pipe.producer_commit(producer_state, loc=loc, ip=ip)


__all__ = [
    "PipelineTmaWarpMma",
    "issue_tma_load_3d",
    "issue_tma_load_4d",
    "producer_acquire_issue_tma_load_3d",
    "producer_acquire_issue_tma_load_4d",
]
