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

"""Resource abstractions for the Task Scheduling (TS) framework.

**Compile-time abstraction**: Pipeline operations (acquire, release, commit,
wait) defined here are traced by the DSL at compile time and produce the
same mbarrier PTX instructions as hand-coded bare-metal kernels.  There is
no additional runtime overhead from using these abstractions — the framework
is a code generator, not a runtime scheduler.

This module defines the data-flow building blocks that a warp-specialised
kernel assembles into a pipeline:

Classes
-------
PipelineConfig
    Immutable descriptor that selects a pipeline type (TMA, UMMA, CLC, etc.)
    and captures its parameters (stage count, byte count, cooperative groups,
    signalling policy).  Static factory methods hide the per-type details.

TileSchedulerConfig
    Pairs a ``TileSchedulerType`` with the scheduler-specific parameters
    (static persistent or CLC dynamic persistent) and, for CLC, the
    SMEM response pointer.

StageInfo
    Read-only snapshot passed into every ``producer_work`` / ``consumer_work``
    call.  Carries the current loop offset, pipeline stage index, mbarrier
    pointer, per-call index, and the active ``WorkTileInfo``.

MemoryResource
    Base class for every resource in the dataflow graph.  A resource owns:
      - an optional ``PipelineConfig`` -> materialised pipeline + barriers,
      - pipeline state objects (``consumer_state``, ``producer_state``).

    Subclasses declare public data-flow state as ``TaskLocalVariable`` fields and
    implement consumer / producer work methods to define the resource's
    behaviour at each schedule stage.

WorkQueue (MemoryResource)
    Specialised resource that wraps a tile scheduler
    (``StaticPersistentTileScheduler`` or
    ``ClcDynamicPersistentTileScheduler``).  It drives the persistent
    work loop by producing/consuming ``WorkTileInfo`` tiles.

Typical lifecycle (driven by ``TaskManager``)
---------------------------------------------
    * ``resource.create()`` allocates SMEM barriers and materialises the
      pipeline object. Called once per resource from
      ``TaskManager.setup_resources_and_tasks()``.
    * ``resource.initialize_runtime_state_internal()`` initialises pipeline
      states and status flags. Executed once per kernel invocation, outside
      any dynamic control flow.
    * ``consumer_work(stage_info)`` / ``producer_work(stage_info)`` runs
      user-defined per-stage logic invoked by the ``Task`` schedule.  Routed
      inputs arrive as method parameters and outputs are returned; those values
      flow through the owning ``Task``'s ``route_slots`` mailbox.
"""

from collections.abc import Callable, Mapping
from dataclasses import Field, dataclass, field, fields, is_dataclass
import sys
import difflib
import functools
import inspect
import cutlass.pipeline as pipeline
import cutlass.cute as cute
import cutlass
from cutlass.experimental import primitives as prims
from typing import (
    List,
    Optional,
    Any,
    Tuple,
    TypeAlias,
    TYPE_CHECKING,
    Union,
    cast,
    get_origin,
)
from cutlass.impl_utils import resolve_optional
from cutlass.utils.static_persistent_tile_scheduler import (
    WorkTileInfo as _BaseWorkTileInfo,
)
from cutlass.utils import (
    StaticPersistentTileScheduler,
    PersistentTileSchedulerParams,
    ClcDynamicPersistentTileScheduler,
    ClcDynamicPersistentTileSchedulerParams,
)
from .memory import SmemAllocation, TmemAllocation, ResourceContext
from .enums import (
    PipelineType,
    ScheduleStage,
    TileSchedulerType,
    SignalingThreads,
    WorkAttr,
    record_construction_site,
)
from . import pipeline as ts_pipeline

if TYPE_CHECKING:
    from .pipeline_group import PipelineGroup


class WorkTileInfo(_BaseWorkTileInfo):
    """TS-local 3D work tile with scalarized loop-carried fields.

    TS loop-carries work tiles through staged persistent control flow and
    advances them in tail schedule entries. The released CUTLASS work-tile class
    stores ``tile_idx`` as one tuple field, which makes in-place updates fail IR
    dominance checks in nested dynamic regions. Keep that released class
    untouched and scalarize only the TS-local subclass.
    """

    @cute.jit
    def __init__(self, tile_idx: cute.Coord, is_valid_tile: cutlass.Boolean) -> None:
        m_idx, n_idx, l_idx = tile_idx  # type: ignore[misc]
        self._m_idx = cutlass.Int32(m_idx)
        self._n_idx = cutlass.Int32(n_idx)
        self._l_idx = cutlass.Int32(l_idx)
        self._is_valid_tile = cutlass.Boolean(is_valid_tile)

    def __extract_mlir_values__(self) -> list:
        return [
            self._m_idx.ir_value(),
            self._n_idx.ir_value(),
            self._l_idx.ir_value(),
            self._is_valid_tile.ir_value(),
        ]

    def __new_from_mlir_values__(self, values: list) -> "WorkTileInfo":
        assert len(values) == 4
        return WorkTileInfo(
            (
                cutlass.Int32(values[0]),
                cutlass.Int32(values[1]),
                cutlass.Int32(values[2]),
            ),
            cutlass.Boolean(values[3]),
        )

    @property
    @cute.jit
    def tile_idx(self) -> cute.Coord:
        return (self._m_idx, self._n_idx, self._l_idx)

    @property
    @cute.jit
    def is_valid_tile(self) -> cutlass.Boolean:
        return self._is_valid_tile

    @cute.jit
    def update_from(self, other: _BaseWorkTileInfo) -> None:
        m_idx, n_idx, l_idx = other.tile_idx
        self._m_idx = cutlass.Int32(m_idx)
        self._n_idx = cutlass.Int32(n_idx)
        self._l_idx = cutlass.Int32(l_idx)
        self._is_valid_tile = cutlass.Boolean(other.is_valid_tile)


InterleaveStride: TypeAlias = int | tuple[int, int, int, int]


_TS_MANAGES_CAPTURE_CONTEXT_ATTR = "_ts_manages_schedule_capture_context"


@dataclass(frozen=True)
class PipelineConfig:
    """Immutable descriptor for a single pipeline instance.

    Captures everything ``MemoryResource.create_pipeline()`` needs to
    materialise a concrete pipeline object (barrier storage, stage count,
    transaction bytes, cooperative groups, CTA layout, and signalling
    policy).

    Users should not construct ``PipelineConfig`` directly.  Instead, use
    one of the static factory methods which fill in the correct
    ``PipelineType`` and sensible defaults:

    - ``create_async_async_pipeline_cfg``    - generic async-producer + async-consumer pipeline.
    - ``create_tma_async_pipeline_cfg``      - TMA-producer + async-consumer pipeline.
    - ``create_tma_umma_pipeline_cfg``       - TMA-producer + UMMA-consumer pipeline.
    - ``create_umma_async_pipeline_cfg``     - UMMA-producer + async-consumer pipeline.
    - ``create_async_umma_pipeline_cfg``     - async-producer + UMMA-consumer pipeline.
    - ``create_umma_umma_pipeline_cfg``      - UMMA-producer + UMMA-consumer pipeline.
    - ``create_clc_fetch_async_pipeline_cfg``- CLC tile-fetch + async-consumer pipeline.

    Attributes
    ----------
    num_stages : int
        Number of buffering stages (pipeline depth).
    num_bytes : int
        Expected transaction byte count per stage (0 when not applicable).
    producer_group, consumer_group : pipeline.CooperativeGroup
        Cooperative groups that define the producer / consumer agents.
    pipeline_type : PipelineType
        Selects the concrete pipeline implementation.
    barrier_ptr : cute.Pointer, optional
        Pre-allocated SMEM barrier storage (Int64, 2 * num_stages).
        When *None*, ``MemoryResource.create_pipeline()`` allocates it.
    cta_layout_vmnk : cute.Layout, optional
        Cluster decomposition layout; required for UMMA / CLC pipelines.
    producer_signaling_threads : SignalingThreads
        Which threads execute producer-side barrier operations
        (acquire, commit).  ``CtaLeader`` restricts signalling to CTA 0.
    consumer_signaling_threads : SignalingThreads
        Which threads execute consumer-side barrier operations
        (wait, release).  Used for ConsumerRelease (and ConsumerWait
        when ``consumer_wait_signaling_threads`` is *None*).
    consumer_wait_signaling_threads : SignalingThreads or None
        Override for ConsumerTryWait / ConsumerWait signaling threads.
        When *None* (default), falls back to ``consumer_signaling_threads``.
        Set this when ConsumerWait and ConsumerRelease need different
        CTA signaling (e.g. split-consumer pattern where one task waits
        on all CTAs and another releases on leader CTA only).
    async_producer_op : pipeline.PipelineOp
        Producer-side barrier operation for ``AsyncAsync``.  Defaults to
        ``AsyncThread``.  ``AsyncLoad`` selects cp.async-style producer
        commits that use ``cp.async.mbarrier.arrive`` on local per-CTA
        full barriers.
    umma_consumer_producer_op : pipeline.PipelineOp
        Producer-side barrier operation for ``AsyncUmma``.
        Defaults to ``AsyncThread``.  ``AsyncLoad`` selects
        cp.async-style producer commits and local per-CTA arrivals.
    num_bytes_per_warp_per_cta : int, optional
        Declares that each producer CTA routes its TMA completion to the
        leader-visible full barrier.  The value is the per-producer-warp, per-CTA
        transaction byte count; validation checks that ``num_bytes`` covers
        every producer warp across the full cluster.
    mcast_mode_mn : tuple[int, int]
        Multicast mode passed to CUTLASS TMA pipeline creation for cluster
        arrival masks.
    advance_on_wait : bool
        Controls when the pipeline stage index is advanced.  When *False*
        (default), the stage is advanced on ``release``; when *True*, the
        stage is advanced on the ``wait`` call and a separate pipeline state
        is used to release the consumer.
        Disabled by default pending performance measurements.
    advance_on_acquire : bool
        Producer-side analogue of ``advance_on_wait``.  When *True*,
        ``ProducerAcquire`` advances ``producer_state`` immediately.
        ``ProducerWork`` either derives the just-acquired state from
        ``producer_state`` or follows the lagging ``producer_commit_state``.
        ``ProducerCommit`` always uses ``producer_commit_state``.
    interleave_stride : int or tuple[int, int, int, int]
        Stride for interleaved pipeline advancement.  When the stride is > 1,
        N lanes share one pipeline with ``num_stages`` total barriers; each
        lane starts at its lane index and advances by the stride, which must
        evenly divide ``num_stages``.  A lane may be selected by a task-local
        warp or by a task's domain start.  A single
        integer applies the same stride to every role.  A 4-tuple assigns
        role-specific strides interpreted as ``(producer_acquire,
        producer_commit, consumer_wait, consumer_release)``.  Splitting
        ``producer_acquire`` from ``producer_commit`` requires
        ``advance_on_acquire``; splitting ``consumer_wait`` from
        ``consumer_release`` requires ``advance_on_wait``.
    defer_init : bool
        When *True*, ``create_pipeline`` skips the per-pipeline
        ``mbarrier_init``. Requires a pre-supplied ``barrier_ptr``.
    storage_offset_full : int, optional
        Offset of the first full barrier within ``barrier_ptr``.
        Defaults to 0.
    storage_offset_empty : int, optional
        Offset of the first empty barrier within ``barrier_ptr``.
        Defaults to ``num_stages`` (contiguous after full barriers).
    full_mbarrier_layout : pipeline.MbarrierLayout
        Hardware mbarrier layout for this pipeline's full barrier.
    empty_mbarrier_layout : pipeline.MbarrierLayout
        Hardware mbarrier layout for this pipeline's empty barrier.
    """

    num_stages: int
    num_bytes: int
    producer_group: pipeline.CooperativeGroup
    consumer_group: pipeline.CooperativeGroup
    pipeline_type: PipelineType
    barrier_ptr: Optional[cute.Pointer] = None
    cta_layout_vmnk: Optional[Union[cute.Layout, tuple]] = None
    producer_signaling_threads: SignalingThreads = SignalingThreads.All
    consumer_signaling_threads: SignalingThreads = SignalingThreads.All
    consumer_wait_signaling_threads: Optional[SignalingThreads] = None
    umma_consumer_producer_op: pipeline.PipelineOp = pipeline.PipelineOp.AsyncThread
    advance_on_wait: bool = False
    advance_on_acquire: bool = False
    num_bytes_per_warp_per_cta: Optional[int] = None
    mcast_mode_mn: tuple[int, int] = (1, 1)
    # Stride for interleaved pipeline advancement.
    # When > 1, N warp- or domain-owned lanes share one pipeline with
    # num_stages total barriers. Each lane starts at its index and advances
    # by stride.
    # Must evenly divide num_stages.  Accepts a single int (uniform across
    # all roles) or a 4-tuple ``(producer_acquire, producer_commit,
    # consumer_wait, consumer_release)`` for per-role strides.
    interleave_stride: InterleaveStride = 1
    async_producer_op: pipeline.PipelineOp = pipeline.PipelineOp.AsyncThread
    defer_init: bool = False
    storage_offset_full: Optional[int] = None
    storage_offset_empty: Optional[int] = None
    full_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0
    empty_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0

    def __post_init__(self) -> None:
        SignalingThreads.validate(
            self.producer_signaling_threads,
            "producer_signaling_threads",
        )
        SignalingThreads.validate(
            self.consumer_signaling_threads,
            "consumer_signaling_threads",
        )
        if self.consumer_wait_signaling_threads is not None:
            SignalingThreads.validate(
                self.consumer_wait_signaling_threads,
                "consumer_wait_signaling_threads",
            )
        supported_thread_producer_ops = (
            pipeline.PipelineOp.AsyncThread,
            pipeline.PipelineOp.AsyncLoad,
        )
        if self.async_producer_op not in supported_thread_producer_ops:
            raise ValueError(
                "async_producer_op must be AsyncThread or AsyncLoad, "
                f"got {self.async_producer_op}."
            )
        if (
            self.pipeline_type != PipelineType.AsyncAsync
            and self.async_producer_op != pipeline.PipelineOp.AsyncThread
        ):
            raise ValueError(
                "async_producer_op can only be changed for PipelineType.AsyncAsync."
            )
        if self.umma_consumer_producer_op not in supported_thread_producer_ops:
            raise ValueError(
                "umma_consumer_producer_op must be AsyncThread or AsyncLoad, "
                f"got {self.umma_consumer_producer_op}."
            )
        if (
            self.pipeline_type != PipelineType.AsyncUmma
            and self.umma_consumer_producer_op != pipeline.PipelineOp.AsyncThread
        ):
            raise ValueError(
                "umma_consumer_producer_op can only be changed for "
                "PipelineType.AsyncUmma."
            )
        (
            producer_acquire_stride,
            producer_commit_stride,
            consumer_wait_stride,
            consumer_release_stride,
        ) = self.interleave_strides
        for role, stride in zip(
            (
                "producer_acquire",
                "producer_commit",
                "consumer_wait",
                "consumer_release",
            ),
            (
                producer_acquire_stride,
                producer_commit_stride,
                consumer_wait_stride,
                consumer_release_stride,
            ),
        ):
            if self.num_stages % stride != 0:
                raise ValueError(
                    f"{role} interleave_stride={stride} must evenly "
                    f"divide num_stages={self.num_stages}"
                )
        if producer_acquire_stride != producer_commit_stride and (
            not self.advance_on_acquire
        ):
            raise ValueError(
                "producer_acquire and producer_commit interleave strides differ "
                f"({producer_acquire_stride} vs {producer_commit_stride}); "
                "advance_on_acquire=True is required so the acquire and commit "
                "roles use separate producer pipeline states."
            )
        if consumer_wait_stride != consumer_release_stride and not self.advance_on_wait:
            raise ValueError(
                "consumer_wait and consumer_release interleave strides differ "
                f"({consumer_wait_stride} vs {consumer_release_stride}); "
                "advance_on_wait=True is required so the wait and release "
                "roles use separate consumer pipeline states."
            )
        # A half-set pair of offsets is almost certainly a mistake, so reject it.
        if (self.storage_offset_full is None) != (self.storage_offset_empty is None):
            raise ValueError("storage_offset_{full,empty} must both be set or neither")
        # Deferred init may only be used with a pre-supplied barrier_ptr.
        if self.defer_init and self.barrier_ptr is None:
            raise ValueError("defer_init=True requires a pre-supplied barrier_ptr.")

    @staticmethod
    def _validate_interleave_stride_value(stride: int, role: str) -> int:
        """Validate a single interleave-stride entry is a positive int."""
        if not isinstance(stride, int) or isinstance(stride, bool):
            raise TypeError(f"{role} interleave_stride must be an int, got {stride!r}")
        if stride < 1:
            raise ValueError(f"{role} interleave_stride must be >= 1, got {stride}")
        return stride

    @classmethod
    def _normalize_interleave_stride(
        cls,
        interleave_stride: InterleaveStride,
    ) -> tuple[int, int, int, int]:
        """Expand ``interleave_stride`` into a per-role 4-tuple.

        A single int is broadcast to every role.  A 4-tuple is taken as
        ``(producer_acquire, producer_commit, consumer_wait,
        consumer_release)``.
        """
        if isinstance(interleave_stride, tuple):
            if len(interleave_stride) != 4:
                raise ValueError(
                    "interleave_stride tuple must be "
                    "(producer_acquire, producer_commit, consumer_wait, "
                    "consumer_release)"
                )
            validated = [
                cls._validate_interleave_stride_value(stride, role)
                for stride, role in zip(
                    interleave_stride,
                    (
                        "producer_acquire",
                        "producer_commit",
                        "consumer_wait",
                        "consumer_release",
                    ),
                )
            ]
            return (validated[0], validated[1], validated[2], validated[3])
        stride = cls._validate_interleave_stride_value(
            interleave_stride,
            "uniform",
        )
        return (stride, stride, stride, stride)

    @property
    def interleave_strides(self) -> tuple[int, int, int, int]:
        """Return ``(producer_acquire, producer_commit, consumer_wait,
        consumer_release)`` strides."""
        return self._normalize_interleave_stride(self.interleave_stride)

    @property
    def producer_acquire_interleave_stride(self) -> int:
        """Stride used when advancing the producer acquire cursor."""
        return self.interleave_strides[0]

    @property
    def producer_commit_interleave_stride(self) -> int:
        """Stride used when advancing the producer commit cursor."""
        return self.interleave_strides[1]

    @property
    def consumer_wait_interleave_stride(self) -> int:
        """Stride used when ``advance_on_wait`` advances consumer wait state."""
        return self.interleave_strides[2]

    @property
    def consumer_release_interleave_stride(self) -> int:
        """Stride used when advancing consumer release state."""
        return self.interleave_strides[3]

    @property
    def max_interleave_stride(self) -> int:
        """Largest role-specific interleave stride."""
        return max(self.interleave_strides)

    @property
    def has_interleaved_stride(self) -> bool:
        """Whether any role advances through the pipeline with stride > 1."""
        return self.max_interleave_stride > 1

    @property
    def consumer_pin_signaling_exempt(self) -> bool:
        """Whether a CTA-pinned consumer is exempt from the CtaLeader-signaling rule.

        A ``ClcFetchAsync`` work queue intentionally mixes all-CTA and
        leader-only consumers behind one shared config, so a CTA-pinned consumer
        need not use ``CtaLeader`` signaling.  A capability the pipeline kind
        implies, so callers consult this instead of branching on ``pipeline_type``.
        """
        return self.pipeline_type == PipelineType.ClcFetchAsync

    @property
    def supports_try_probe_ops(self) -> bool:
        """Whether the pipeline implements non-blocking try_acquire / try_wait.

        A ``ClcFetchAsync`` work queue has no explicit try-probe: the CLC fetch
        arms the full barrier directly, so producers and consumers perform only
        the blocking acquire / wait and the try-probe steps are inert. A
        capability the pipeline kind implies, so callers consult this instead of
        branching on ``pipeline_type``.
        """
        return self.pipeline_type != PipelineType.ClcFetchAsync

    @property
    def producer_signals_on_cluster_leader_only(self) -> bool:
        """Whether the producer is a single cluster-wide issuer gated to rank 0.

        A ``ClcFetchAsync`` work queue holds one cluster-wide query that exactly
        one CTA -- the absolute cluster leader (``block_idx_in_cluster() == 0``)
        -- may issue and commit; extra issuers break the cluster CLC handshake.
        This differs from the V-group leader (``rank % v_size == 0``) used by
        ordinary CtaLeader signaling, which selects one CTA per V-group and
        coincides with rank 0 only when ``v_size == cluster_size``. A capability
        the pipeline kind implies, so callers consult this instead of branching
        on ``pipeline_type``.
        """
        return self.pipeline_type == PipelineType.ClcFetchAsync

    @property
    def acquire_waits_all_ctas(self) -> bool:
        """Whether the producer acquire's empty wait runs on every producer CTA.

        A ``TmaUmma`` pipeline gates its full-barrier arrive internally on CTA
        leadership, and a ``TaskWarpLeader``-narrowed ``TmaAsync`` / ``TmaUmma``
        acquire narrows the transaction arrive to the task's first warp inside
        the pipeline.  In both cases the empty-barrier wait must still run on
        *every* producer CTA -- gating it to the leader would let a non-leader
        reuse a buffer without waiting on its empty barrier (race/hang) -- so the
        acquire is not leader-gated at task level.  A capability the pipeline
        kind implies, so callers consult this instead of branching on
        ``pipeline_type``.
        """
        return self.pipeline_type == PipelineType.TmaUmma or (
            self.pipeline_type in (PipelineType.TmaAsync, PipelineType.TmaUmma)
            and self.producer_signaling_threads.has_task_warp_leader()
        )

    @property
    def resolved_storage_offset_full(self) -> int:
        """The offset of the full barrier from barrier_ptr."""
        return resolve_optional(self.storage_offset_full, 0)

    @property
    def resolved_storage_offset_empty(self) -> int:
        """The offset of the empty barrier from barrier_ptr."""
        return resolve_optional(self.storage_offset_empty, self.num_stages)

    @staticmethod
    def create_async_async_pipeline_cfg(
        num_stages: int,
        producer_group: pipeline.CooperativeGroup,
        consumer_group: pipeline.CooperativeGroup,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        producer_signaling_threads: SignalingThreads = SignalingThreads.All,
        consumer_signaling_threads: SignalingThreads = SignalingThreads.All,
        barrier_ptr: Optional[cute.Pointer] = None,
        producer_op: pipeline.PipelineOp = pipeline.PipelineOp.AsyncThread,
        advance_on_acquire: bool = False,
        interleave_stride: InterleaveStride = 1,
        defer_init: bool = False,
        storage_offset_full: Optional[int] = None,
        storage_offset_empty: Optional[int] = None,
        full_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
        empty_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
        *,
        advance_on_wait: bool = False,
    ) -> "PipelineConfig":
        """Create a config for a generic async pipeline.

        ``producer_op=AsyncLoad`` matches async global-to-shared producers that
        signal full barriers with ``cp.async.mbarrier.arrive`` while their
        consumers still release through ordinary async-thread mbarriers.

        Parameters
        ----------
        num_stages : int
            Number of buffering stages.
        producer_group, consumer_group : pipeline.CooperativeGroup
            Cooperative groups on the producer and consumer sides.
        cta_layout_vmnk : cute.Layout
            CTA cluster layout.
        producer_signaling_threads, consumer_signaling_threads : SignalingThreads, optional
            Threads that execute producer- and consumer-side barrier operations.
        barrier_ptr : cute.Pointer, optional
            Pre-allocated barrier storage.  ``None`` lets the allocator place it.
        producer_op : pipeline.PipelineOp, optional
            Async producer operation, normally ``AsyncThread`` or ``AsyncLoad``.
        advance_on_acquire : bool, optional
            Advance producer state at acquire time instead of commit time.
        interleave_stride : int or tuple[int, int, int, int], optional
            Role-specific pipeline-state stride.  Mismatched opening and
            closing roles require the corresponding advance flag.
        advance_on_wait : bool, optional
            Advance consumer state at wait time instead of release time.
            Keyword-only so existing positional callers keep mapping the
            ninth argument to ``advance_on_acquire``.
        full_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the full barrier.
        empty_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the empty barrier.

        Returns
        -------
        PipelineConfig
            Configuration for an ``AsyncAsync`` pipeline.
        """
        return PipelineConfig(
            num_stages=num_stages,
            num_bytes=0,
            producer_group=producer_group,
            consumer_group=consumer_group,
            pipeline_type=PipelineType.AsyncAsync,
            cta_layout_vmnk=cta_layout_vmnk,
            producer_signaling_threads=producer_signaling_threads,
            consumer_signaling_threads=consumer_signaling_threads,
            barrier_ptr=barrier_ptr,
            async_producer_op=producer_op,
            advance_on_wait=advance_on_wait,
            advance_on_acquire=advance_on_acquire,
            interleave_stride=interleave_stride,
            defer_init=defer_init,
            storage_offset_full=storage_offset_full,
            storage_offset_empty=storage_offset_empty,
            full_mbarrier_layout=full_mbarrier_layout,
            empty_mbarrier_layout=empty_mbarrier_layout,
        )

    @staticmethod
    def create_tma_async_pipeline_cfg(
        num_stages: int,
        num_bytes: int,
        producer_group: pipeline.CooperativeGroup,
        consumer_group: pipeline.CooperativeGroup,
        cta_layout_vmnk: Optional[cute.Layout] = None,
        producer_signaling_threads: SignalingThreads = SignalingThreads.All,
        consumer_signaling_threads: SignalingThreads = SignalingThreads.All,
        barrier_ptr: Optional[cute.Pointer] = None,
        advance_on_wait: bool = False,
        interleave_stride: InterleaveStride = 1,
        num_bytes_per_warp_per_cta: Optional[int] = None,
        defer_init: bool = False,
        storage_offset_full: Optional[int] = None,
        storage_offset_empty: Optional[int] = None,
        full_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
        empty_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
    ) -> "PipelineConfig":
        """Create a config for a TMA-producer async pipeline.

        Parameters
        ----------
        num_stages : int
            Number of buffering stages.
        num_bytes : int
            TMA transaction byte count for each stage.
        producer_group, consumer_group : pipeline.CooperativeGroup
            Cooperative groups on the producer and consumer sides.
        cta_layout_vmnk : cute.Layout, optional
            CTA cluster layout.
        producer_signaling_threads, consumer_signaling_threads : SignalingThreads, optional
            Threads that execute producer- and consumer-side barrier operations.
        barrier_ptr : cute.Pointer, optional
            Pre-allocated barrier storage.  ``None`` lets the allocator place it.
        advance_on_wait : bool, optional
            Setting advance_on_wait=True on a PipelineConfig decouples the consumer's wait
            cursor from its release cursor by introducing two independent pipeline state objects:

            .. list-table::
               :header-rows: 1

               * - State
                 - Advances when
                 - Points to
               * - ``consumer_state``
                 - ``ConsumerWait``
                 - the *next* buffer to wait on
               * - ``consumer_release_state``
                 - ``ConsumerRelease``
                 - the *oldest* un-released buffer

            With this split, the consumer can wait on buffer N+1 (advancing consumer_state) while
            still holding buffer N (not yet released via consumer_release_state).
        interleave_stride : int or tuple[int, int, int, int], optional
            Role-specific pipeline-state stride.  Mismatched opening and
            closing roles require the corresponding advance flag.
        num_bytes_per_warp_per_cta : int, optional
            Per-producer-warp, per-CTA transaction byte count for leader-routed
            clustered TMA completion validation.
        full_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the full barrier.
        empty_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the empty barrier.

        Returns
        -------
        PipelineConfig
            Configuration for a ``TmaAsync`` pipeline.
        """
        return PipelineConfig(
            num_stages=num_stages,
            num_bytes=num_bytes,
            producer_group=producer_group,
            consumer_group=consumer_group,
            pipeline_type=PipelineType.TmaAsync,
            cta_layout_vmnk=cta_layout_vmnk,
            producer_signaling_threads=producer_signaling_threads,
            consumer_signaling_threads=consumer_signaling_threads,
            barrier_ptr=barrier_ptr,
            advance_on_wait=advance_on_wait,
            interleave_stride=interleave_stride,
            num_bytes_per_warp_per_cta=num_bytes_per_warp_per_cta,
            defer_init=defer_init,
            storage_offset_full=storage_offset_full,
            storage_offset_empty=storage_offset_empty,
            full_mbarrier_layout=full_mbarrier_layout,
            empty_mbarrier_layout=empty_mbarrier_layout,
        )

    @staticmethod
    def create_tma_umma_pipeline_cfg(
        num_stages: int,
        num_bytes: int,
        producer_group: pipeline.CooperativeGroup,
        consumer_group: pipeline.CooperativeGroup,
        cta_layout_vmnk: cute.Layout,
        producer_signaling_threads: SignalingThreads = SignalingThreads.All,
        consumer_signaling_threads: SignalingThreads = SignalingThreads.All,
        barrier_ptr: Optional[cute.Pointer] = None,
        advance_on_wait: bool = False,
        interleave_stride: InterleaveStride = 1,
        mcast_mode_mn: tuple[int, int] = (1, 1),
        num_bytes_per_warp_per_cta: Optional[int] = None,
        defer_init: bool = False,
        storage_offset_full: Optional[int] = None,
        storage_offset_empty: Optional[int] = None,
        full_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
        empty_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
    ) -> "PipelineConfig":
        """Create a config for TMA producer + UMMA consumer async pipeline.

        Parameters
        ----------
        num_stages : int
            Number of buffering stages.
        num_bytes : int
            TMA transaction byte count for each stage.
        producer_group, consumer_group : pipeline.CooperativeGroup
            Cooperative groups on the producer and consumer sides.
        cta_layout_vmnk : cute.Layout
            CTA cluster layout.
        producer_signaling_threads, consumer_signaling_threads : SignalingThreads, optional
            Threads that execute producer- and consumer-side barrier operations.
        barrier_ptr : cute.Pointer, optional
            Pre-allocated barrier storage.  ``None`` lets the allocator place it.
        advance_on_wait : bool, optional
            Advance consumer state at wait time instead of release time.
        interleave_stride : int or tuple[int, int, int, int], optional
            Role-specific pipeline-state stride.  Mismatched opening and
            closing roles require the corresponding advance flag.
        mcast_mode_mn : tuple[int, int], optional
            TMA multicast mode in M and N.
        num_bytes_per_warp_per_cta : int, optional
            Per-producer-warp, per-CTA transaction byte count for validation.
        full_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the full barrier.
        empty_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the empty barrier.

        Returns
        -------
        PipelineConfig
            Configuration for a ``TmaUmma`` pipeline.
        """
        return PipelineConfig(
            num_stages=num_stages,
            num_bytes=num_bytes,
            producer_group=producer_group,
            consumer_group=consumer_group,
            cta_layout_vmnk=cta_layout_vmnk,
            pipeline_type=PipelineType.TmaUmma,
            producer_signaling_threads=producer_signaling_threads,
            consumer_signaling_threads=consumer_signaling_threads,
            barrier_ptr=barrier_ptr,
            advance_on_wait=advance_on_wait,
            interleave_stride=interleave_stride,
            num_bytes_per_warp_per_cta=num_bytes_per_warp_per_cta,
            mcast_mode_mn=mcast_mode_mn,
            defer_init=defer_init,
            storage_offset_full=storage_offset_full,
            storage_offset_empty=storage_offset_empty,
            full_mbarrier_layout=full_mbarrier_layout,
            empty_mbarrier_layout=empty_mbarrier_layout,
        )

    @staticmethod
    def create_umma_async_pipeline_cfg(
        num_stages: int,
        producer_group: pipeline.CooperativeGroup,
        consumer_group: pipeline.CooperativeGroup,
        cta_layout_vmnk: cute.Layout,
        producer_signaling_threads: SignalingThreads = SignalingThreads.All,
        consumer_signaling_threads: SignalingThreads = SignalingThreads.All,
        barrier_ptr: Optional[cute.Pointer] = None,
        interleave_stride: InterleaveStride = 1,
        defer_init: bool = False,
        storage_offset_full: Optional[int] = None,
        storage_offset_empty: Optional[int] = None,
        full_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
        empty_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
    ) -> "PipelineConfig":
        """Create a config for a UMMA-producer async pipeline.

        Parameters
        ----------
        num_stages : int
            Number of buffering stages.
        producer_group, consumer_group : pipeline.CooperativeGroup
            Cooperative groups on the producer and consumer sides.
        cta_layout_vmnk : cute.Layout
            CTA cluster layout.
        producer_signaling_threads, consumer_signaling_threads : SignalingThreads, optional
            Threads that execute producer- and consumer-side barrier operations.
        barrier_ptr : cute.Pointer, optional
            Pre-allocated barrier storage.  ``None`` lets the allocator place it.
        interleave_stride : int or tuple[int, int, int, int], optional
            Role-specific pipeline-state stride.  Mismatched opening and
            closing roles require the corresponding advance flag.
        full_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the full barrier.
        empty_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the empty barrier.

        Returns
        -------
        PipelineConfig
            Configuration for an ``UmmaAsync`` pipeline.
        """
        return PipelineConfig(
            num_stages=num_stages,
            num_bytes=0,
            producer_group=producer_group,
            consumer_group=consumer_group,
            cta_layout_vmnk=cta_layout_vmnk,
            pipeline_type=PipelineType.UmmaAsync,
            producer_signaling_threads=producer_signaling_threads,
            consumer_signaling_threads=consumer_signaling_threads,
            barrier_ptr=barrier_ptr,
            interleave_stride=interleave_stride,
            defer_init=defer_init,
            storage_offset_full=storage_offset_full,
            storage_offset_empty=storage_offset_empty,
            full_mbarrier_layout=full_mbarrier_layout,
            empty_mbarrier_layout=empty_mbarrier_layout,
        )

    @staticmethod
    def create_async_umma_pipeline_cfg(
        num_stages: int,
        producer_group: pipeline.CooperativeGroup,
        consumer_group: pipeline.CooperativeGroup,
        cta_layout_vmnk: cute.Layout,
        producer_signaling_threads: SignalingThreads = SignalingThreads.All,
        consumer_signaling_threads: SignalingThreads = SignalingThreads.All,
        consumer_wait_signaling_threads: Optional[SignalingThreads] = None,
        producer_op: pipeline.PipelineOp = pipeline.PipelineOp.AsyncThread,
        barrier_ptr: Optional[cute.Pointer] = None,
        advance_on_wait: bool = False,
        advance_on_acquire: bool = False,
        interleave_stride: InterleaveStride = 1,
        defer_init: bool = False,
        storage_offset_full: Optional[int] = None,
        storage_offset_empty: Optional[int] = None,
        full_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
        empty_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
    ) -> "PipelineConfig":
        """Create a config for an async-producer + UMMA-consumer pipeline.

        Used when async producer threads create data and the UMMA warp
        consumes it.  ``producer_op=AsyncLoad`` matches async global-to-shared
        producer commits that use ``cp.async.mbarrier.arrive`` on local
        per-CTA full barriers.

        Parameters
        ----------
        num_stages : int
            Number of buffering stages.
        producer_group, consumer_group : pipeline.CooperativeGroup
            Cooperative groups on the producer and consumer sides.
        cta_layout_vmnk : cute.Layout
            CTA cluster layout.
        producer_signaling_threads, consumer_signaling_threads : SignalingThreads, optional
            Threads that execute producer- and consumer-side barrier operations.
        consumer_wait_signaling_threads : SignalingThreads, optional
            Override for wait-side signaling when wait and release use different
            participants.
        producer_op : pipeline.PipelineOp, optional
            Async producer operation, normally ``AsyncThread`` or ``AsyncLoad``.
        barrier_ptr : cute.Pointer, optional
            Pre-allocated barrier storage.  ``None`` lets the allocator place it.
        advance_on_wait : bool, optional
            Advance consumer state at wait time instead of release time.
        advance_on_acquire : bool, optional
            Advance producer state at acquire time instead of commit time.
        interleave_stride : int or tuple[int, int, int, int], optional
            Role-specific pipeline-state stride.  Mismatched opening and
            closing roles require the corresponding advance flag.
        full_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the full barrier.
        empty_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the empty barrier.

        Returns
        -------
        PipelineConfig
            Configuration for an ``AsyncUmma`` pipeline.
        """
        return PipelineConfig(
            num_stages=num_stages,
            num_bytes=0,
            producer_group=producer_group,
            consumer_group=consumer_group,
            cta_layout_vmnk=cta_layout_vmnk,
            pipeline_type=PipelineType.AsyncUmma,
            producer_signaling_threads=producer_signaling_threads,
            consumer_signaling_threads=consumer_signaling_threads,
            consumer_wait_signaling_threads=consumer_wait_signaling_threads,
            umma_consumer_producer_op=producer_op,
            barrier_ptr=barrier_ptr,
            advance_on_wait=advance_on_wait,
            advance_on_acquire=advance_on_acquire,
            interleave_stride=interleave_stride,
            defer_init=defer_init,
            storage_offset_full=storage_offset_full,
            storage_offset_empty=storage_offset_empty,
            full_mbarrier_layout=full_mbarrier_layout,
            empty_mbarrier_layout=empty_mbarrier_layout,
        )

    @staticmethod
    def create_umma_umma_pipeline_cfg(
        num_stages: int,
        producer_group: pipeline.CooperativeGroup,
        consumer_group: pipeline.CooperativeGroup,
        cta_layout_vmnk: cute.Layout,
        producer_signaling_threads: SignalingThreads = SignalingThreads.All,
        consumer_signaling_threads: SignalingThreads = SignalingThreads.All,
        barrier_ptr: Optional[cute.Pointer] = None,
        defer_init: bool = False,
        storage_offset_full: Optional[int] = None,
        storage_offset_empty: Optional[int] = None,
        full_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
        empty_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
    ) -> "PipelineConfig":
        """Create a config for a UMMA producer + UMMA consumer pipeline.

        Parameters
        ----------
        num_stages : int
            Number of buffering stages.
        producer_group, consumer_group : pipeline.CooperativeGroup
            Cooperative groups on the producer and consumer sides.
        cta_layout_vmnk : cute.Layout
            CTA cluster layout.
        producer_signaling_threads, consumer_signaling_threads : SignalingThreads, optional
            Threads that execute producer- and consumer-side barrier operations.
        barrier_ptr : cute.Pointer, optional
            Pre-allocated barrier storage.  ``None`` lets the allocator place it.
        full_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the full barrier.
        empty_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the empty barrier.

        Returns
        -------
        PipelineConfig
            Configuration for an ``UmmaUmma`` pipeline.
        """
        return PipelineConfig(
            num_stages=num_stages,
            num_bytes=0,
            producer_group=producer_group,
            consumer_group=consumer_group,
            cta_layout_vmnk=cta_layout_vmnk,
            pipeline_type=PipelineType.UmmaUmma,
            producer_signaling_threads=producer_signaling_threads,
            consumer_signaling_threads=consumer_signaling_threads,
            barrier_ptr=barrier_ptr,
            defer_init=defer_init,
            storage_offset_full=storage_offset_full,
            storage_offset_empty=storage_offset_empty,
            full_mbarrier_layout=full_mbarrier_layout,
            empty_mbarrier_layout=empty_mbarrier_layout,
        )

    @staticmethod
    def create_clc_fetch_async_pipeline_cfg(
        num_stages: int,
        num_bytes: int,
        producer_group: pipeline.CooperativeGroup,
        consumer_group: pipeline.CooperativeGroup,
        cta_layout_vmnk: cute.Layout,
        producer_signaling_threads: SignalingThreads = SignalingThreads.CtaLeader,
        consumer_signaling_threads: SignalingThreads = SignalingThreads.All,
        barrier_ptr: Optional[cute.Pointer] = None,
        defer_init: bool = False,
        storage_offset_full: Optional[int] = None,
        storage_offset_empty: Optional[int] = None,
        full_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
        empty_mbarrier_layout: pipeline.MbarrierLayout = pipeline.MbarrierLayout.V0,
    ) -> "PipelineConfig":
        """Create a config for a CLC tile-fetch async pipeline.

        Parameters
        ----------
        num_stages : int
            Number of buffering stages.
        num_bytes : int
            Work-tile fetch transaction byte count for each stage.
        producer_group, consumer_group : pipeline.CooperativeGroup
            Cooperative groups on the producer and consumer sides.
        cta_layout_vmnk : cute.Layout
            CTA cluster layout.
        producer_signaling_threads, consumer_signaling_threads : SignalingThreads, optional
            Threads that execute producer- and consumer-side barrier operations.
        barrier_ptr : cute.Pointer, optional
            Pre-allocated barrier storage.  ``None`` lets the allocator place it.
        full_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the full barrier.
        empty_mbarrier_layout : pipeline.MbarrierLayout, optional
            Hardware mbarrier layout for the empty barrier.

        Returns
        -------
        PipelineConfig
            Configuration for a ``ClcFetchAsync`` pipeline.
        """
        return PipelineConfig(
            num_stages=num_stages,
            num_bytes=num_bytes,
            producer_group=producer_group,
            consumer_group=consumer_group,
            cta_layout_vmnk=cta_layout_vmnk,
            pipeline_type=PipelineType.ClcFetchAsync,
            producer_signaling_threads=producer_signaling_threads,
            consumer_signaling_threads=consumer_signaling_threads,
            barrier_ptr=barrier_ptr,
            defer_init=defer_init,
            storage_offset_full=storage_offset_full,
            storage_offset_empty=storage_offset_empty,
            full_mbarrier_layout=full_mbarrier_layout,
            empty_mbarrier_layout=empty_mbarrier_layout,
        )



@dataclass(frozen=True)
class TileSchedulerConfig:
    """Immutable descriptor that pairs a tile-scheduler type with its params.

    Attributes
    ----------
    tile_scheduler_type : TileSchedulerType
        ``StaticPersistent`` or ``ClcDynamicPersistent``.
    tile_scheduler_params : PersistentTileSchedulerParams
        Scheduler-specific parameters (grid dims, cluster shape, etc.).
    response_ptr : cute.Pointer, optional
        SMEM response buffer pointer; required only for CLC dynamic mode.
    """

    tile_scheduler_type: TileSchedulerType
    tile_scheduler_params: Union[
        PersistentTileSchedulerParams, ClcDynamicPersistentTileSchedulerParams
    ]
    response_ptr: Optional[cute.Pointer] = None

    @staticmethod
    def create_static_persistent_tile_scheduler_params(
        tile_scheduler_params: PersistentTileSchedulerParams,
    ) -> "TileSchedulerConfig":
        """Create a config for the static persistent tile scheduler.

        Parameters
        ----------
        tile_scheduler_params : PersistentTileSchedulerParams
            CUTLASS static persistent scheduler parameters.

        Returns
        -------
        TileSchedulerConfig
            Configuration selecting ``TileSchedulerType.StaticPersistent``.
        """
        return TileSchedulerConfig(
            tile_scheduler_type=TileSchedulerType.StaticPersistent,
            tile_scheduler_params=tile_scheduler_params,
        )

    @staticmethod
    def create_clc_dynamic_persistent_tile_scheduler_params(
        tile_scheduler_params: ClcDynamicPersistentTileSchedulerParams,
        response_ptr: cute.Pointer,
    ) -> "TileSchedulerConfig":
        """Create a config for the CLC dynamic persistent tile scheduler.

        Parameters
        ----------
        tile_scheduler_params : ClcDynamicPersistentTileSchedulerParams
            CUTLASS CLC dynamic scheduler parameters.
        response_ptr : cute.Pointer
            SMEM response buffer pointer used by the CLC fetch pipeline.

        Returns
        -------
        TileSchedulerConfig
            Configuration selecting ``TileSchedulerType.ClcDynamicPersistent``.
        """
        return TileSchedulerConfig(
            tile_scheduler_type=TileSchedulerType.ClcDynamicPersistent,
            tile_scheduler_params=tile_scheduler_params,
            response_ptr=response_ptr,
        )


# Peeled head/tail work has no domain-loop induction state.
LOOP_STATE_UNAVAILABLE = None


@dataclass(frozen=True)
class StageInfo:
    """Read-only context passed to ``producer_work`` / ``consumer_work``.

    Attributes
    ----------
    loop_offset : int
        Current iteration cursor: the domain-loop induction value, or the
        ``while_true_loop`` state returned by the init/advance hooks. Peeled
        head/tail work has no loop state (``LOOP_STATE_UNAVAILABLE``).
    loop_start, loop_end, loop_step : int
        Bounds and stride of the K-tile loop
        (``range(loop_start, loop_end, loop_step)``).
    stage_idx : int or None
        Pipeline stage index for the current operation (``None`` when the
        resource has no pipeline).
    label : object or None
        User-defined compile-time work label from the schedule entry.
        Selects a named work hook::

            if cutlass.const_expr(stage_info.label == WorkLabel.K_DESC):
                ...  # K descriptor logic
            elif cutlass.const_expr(stage_info.label == WorkLabel.V_DESC):
                ...  # V descriptor logic

        ``None`` when no label is specified.
    barrier : cutlass.Array or None
        Mbarrier pointer for the current pipeline stage (``None`` when the
        resource has no pipeline).
    work_tile : WorkTileInfo or None
        Tile coordinates and validity flag from the tile scheduler.
    num_active_stages : int
        Number of producer stages currently in flight for delayed-commit
        producer schedules.  This is 0 for the default immediate-commit
        schedule.
    context : ResourceContext or None
        Unified context carrying ``smem_base``, ``tmem_ptr_i32``, and
        any future framework-level state.  ``None`` when no allocator
        is in use.
    """

    loop_offset: int
    loop_start: int
    loop_end: int
    loop_step: int
    stage_idx: Optional[int]
    label: object
    barrier: Optional[cutlass.Array]
    work_tile: Optional[WorkTileInfo]
    num_active_stages: cutlass.Constexpr[int] = 0
    context: Optional[ResourceContext] = None


_TASK_LOCAL_VARIABLE_VALUE_MISSING = object()
_TS_TASK_LOCAL_VARIABLES_ATTR = "_ts_task_local_variables"


_TS_FIELD_METADATA_NAMESPACE = "ts"


@dataclass(eq=False)
class TaskLocalVariable:
    """Metadata for one resource-owned variable in captured TS schedules.

    A ``TaskLocalVariable`` is the public identity of a logical variable owned by
    a ``MemoryResource``. In generated code it materializes as task-local
    register state, with consumer work calls producing new versions of that
    register value. Routed values flow through the owning ``Task``'s
    ``route_slots`` mailbox keyed by ``TaskLocalVariable`` identity; schedule
    code carries these identities via ``Step.input_bindings`` /
    ``returned_variables``.

    Attributes
    ----------
    dtype : object
        DSL type of the value stored in the task-local register slot.
    default : object
        Sink-safe initial value used before any producer writes and at SSA joins.
    default_factory : Callable[[], object], optional
        Factory for the initial value.  Mutually exclusive with ``default``.
    docs : str, optional
        Short user-facing description rendered by API documentation.
    runtime_slot_name : str, optional
        Override for the internal slot name.  Most resources use the dataclass
        field name.
    """

    dtype: object = _TASK_LOCAL_VARIABLE_VALUE_MISSING
    default: object = _TASK_LOCAL_VARIABLE_VALUE_MISSING
    default_factory: Callable[[], object] | None = None
    docs: str | None = None
    runtime_slot_name: str | None = None
    _owner: object | None = field(init=False, default=None, repr=False)
    _field_name: str | None = field(init=False, default=None, repr=False)

    def __post_init__(self) -> None:
        if self.dtype is _TASK_LOCAL_VARIABLE_VALUE_MISSING:
            raise ValueError("TaskLocalVariable requires a dtype.")
        if (
            self.default_factory is not None
            and self.default is not _TASK_LOCAL_VARIABLE_VALUE_MISSING
        ):
            raise ValueError(
                "TaskLocalVariable accepts either default or default_factory, not both."
            )
        if self.default is _TASK_LOCAL_VARIABLE_VALUE_MISSING:
            if self.default_factory is None:
                raise ValueError(
                    "TaskLocalVariable requires a default or default_factory."
                )

    @staticmethod
    def declare(
        *,
        dtype: object,
        default: object = _TASK_LOCAL_VARIABLE_VALUE_MISSING,
        default_factory: Callable[[], object] | None = None,
        docs: str | None = None,
        runtime_slot_name: str | None = None,
    ) -> Field:
        """Declare and initialize a task-local dataclass field in one step.

        Each owning resource instance receives a distinct
        :class:`TaskLocalVariable`, so its owner binding cannot leak across
        resource instances::

            item: TaskLocalVariable = TaskLocalVariable.declare(
                dtype=cutlass.Int16,
                default=cutlass.Int16(0),
            )

        Use :meth:`uninitialized` instead when the dtype or initial value
        depends on constructor arguments and must be assigned in ``__init__``
        or ``__post_init__``.

        Parameters
        ----------
        dtype : object
            DSL type of the value stored in the task-local register slot.
        default : object, optional
            Sink-safe initial value. Mutually exclusive with
            ``default_factory``.
        default_factory : Callable[[], object], optional
            Factory for the sink-safe initial value.
        docs : str, optional
            Short user-facing description rendered by API documentation.
        runtime_slot_name : str, optional
            Override for the internal slot name.

        Returns
        -------
        dataclasses.Field
            Non-init field whose factory creates fresh task-local metadata for
            each owning resource instance.
        """

        def make_task_local_variable() -> TaskLocalVariable:
            return TaskLocalVariable(
                dtype=dtype,
                default=default,
                default_factory=default_factory,
                docs=docs,
                runtime_slot_name=runtime_slot_name,
            )

        # dataclasses.field is typed as its eventual attribute value, but this
        # declaration helper returns the Field object itself.
        return cast(
            Field,
            field(
                init=False,
                default_factory=make_task_local_variable,
                metadata={_TS_FIELD_METADATA_NAMESPACE: {}},
            ),
        )

    @staticmethod
    def uninitialized() -> Field:
        """Declare a dataclass field that backs a ``TaskLocalVariable`` slot.

        The slot must be assigned a ``TaskLocalVariable`` instance during
        ``__init__`` or ``__post_init__`` of the owning class::

            item: TaskLocalVariable = TaskLocalVariable.uninitialized()

            def __post_init__(self) -> None:
                self.item = TaskLocalVariable(dtype=..., default=...)

        Forgetting the assignment surfaces as a clear ``ValueError`` the
        first time TS walks the resource's task-local variables (see
        ``bind_task_local_variables``).

        The returned ``Field`` carries framework metadata under the
        ``"ts"`` namespace so that ``@consumer_work(returns=...)``
        can verify that a field reference points at an actual task-local
        slot rather than an arbitrary ``dataclasses.Field``.

        Returns
        -------
        dataclasses.Field
            Field placeholder to assign a concrete ``TaskLocalVariable`` in the
            owning resource constructor or ``__post_init__``.
        """
        return field(
            init=False,
            metadata={_TS_FIELD_METADATA_NAMESPACE: {}},
        )

    @property
    def owner(self) -> object | None:
        """Resource instance that owns this variable, once bound."""
        return self._owner

    @property
    def field_name(self) -> str | None:
        """Stable resource field name backing ``slot_name``."""
        return self._field_name

    @property
    def slot_name(self) -> str | None:
        """Current internal slot name for this variable."""
        return self.runtime_slot_name or self._field_name

    def _bind_owner(self, owner: object, field_name: str) -> None:
        """Bind this metadata object to exactly one resource field."""
        if self._owner is None:
            self._owner = owner
            self._field_name = field_name
            return
        if self._owner is owner and self._field_name == field_name:
            return
        owner_name = getattr(self._owner, "name", type(self._owner).__name__)
        raise ValueError(
            "TaskLocalVariable instances cannot be reused across resource fields: "
            f"already bound to {owner_name}.{self._field_name}, attempted "
            f"{getattr(owner, 'name', type(owner).__name__)}.{field_name}."
        )


def _is_uninitialized_field(f: Field) -> bool:
    """True iff ``f`` was declared via ``TaskLocalVariable.uninitialized()``."""
    return isinstance(f.metadata.get(_TS_FIELD_METADATA_NAMESPACE), Mapping)


def _is_task_local_variable_annotation(annotation: object) -> bool:
    """Return true for annotations that declare a TaskLocalVariable field."""
    if annotation is TaskLocalVariable:
        return True
    if isinstance(annotation, str):
        return annotation.endswith("TaskLocalVariable")
    origin = getattr(annotation, "__origin__", None)
    args = getattr(annotation, "__args__", ())
    return origin is not None and any(
        _is_task_local_variable_annotation(arg) for arg in args
    )


def _is_task_local_variable_field(dataclass_field: Field) -> bool:
    """True iff a dataclass field declares TS task-local variable state."""
    return _is_uninitialized_field(dataclass_field) or (
        _is_task_local_variable_annotation(dataclass_field.type)
    )


def _task_local_variable_field_on_class(cls: type, name: str) -> Field | None:
    """Return a task-local dataclass field exposed by ``cls`` or its bases."""
    for klass in cls.__mro__:
        dataclass_fields = vars(klass).get("__dataclass_fields__")
        if dataclass_fields is None:
            continue
        dataclass_field = dataclass_fields.get(name)
        if dataclass_field is None:
            continue
        if _is_task_local_variable_field(dataclass_field):
            return dataclass_field
        return None
    return None


class _MemoryResourceMeta(type):
    """Resolve ``returns=`` slot names and expose task-local fields on the class.

    The tree-walker schedule builder reads ``_consumer_return_var_names`` as a
    tuple of slot names. Raw ``@_ts_consumer_returns_raw`` entries may still be
    ``Field`` objects whose ``.name`` is only known after the class body is
    collected, so resolution runs in :meth:`__new__` before ``@dataclass``
    finishes.

    :meth:`__getattr__` exposes each ``TaskLocalVariable`` field as a
    class-level ``Field`` reference so ``@consumer_work(returns=Resource.slot)``
    resolves even though ``@dataclass`` keeps no class attribute for a
    defaultless ``TaskLocalVariable.uninitialized()`` field.
    """

    def __call__(cls, *args: Any, **kwargs: Any) -> Any:
        """Record the user's construction site on every new resource.

        Tooling that reports on a resource (an IR emitter, a diagnostic)
        uses the site so the report traces back to the user's declaration;
        the metaclass hook makes the capture immune to subclass
        ``__init__``/``__post_init__`` overrides that skip ``super()``.
        """
        instance = super().__call__(*args, **kwargs)
        # Recorded in a side table, NOT as an instance attribute: the DSL
        # pytree flattener rejects undeclared __dict__ keys on dataclasses.
        record_construction_site(instance)
        return instance

    def __getattr__(cls, name: str) -> Field:
        """Resolve a task-local field name to its declared ``Field``.

        Class-level access (``Resource.slot``) used by
        ``@consumer_work(returns=...)`` resolves here to the declared ``Field``
        for any task-local field on ``cls`` or its bases; every other name
        raises ``AttributeError``.
        """
        dataclass_field = _task_local_variable_field_on_class(cls, name)
        if dataclass_field is not None:
            return dataclass_field
        raise AttributeError(name)

    def __new__(
        mcls,  # noqa: N804
        name: str,
        bases: tuple[type, ...],
        namespace: dict[str, Any],
        **kwargs: Any,
    ) -> Any:
        cls = super().__new__(mcls, name, bases, namespace, **kwargs)
        field_names = {
            id(value): key
            for key, value in namespace.items()
            if isinstance(value, Field)
        }
        for member_name, value in namespace.items():
            raw = getattr(value, "_ts_consumer_returns_raw", None)
            if raw is None:
                continue
            resolved: list[str] = []
            for entry in raw:
                slot: str | None
                if isinstance(entry, str):
                    slot = entry
                else:
                    slot = entry.name
                    if not isinstance(slot, str) or not slot:
                        slot = field_names.get(id(entry))
                    if not isinstance(slot, str) or not slot:
                        raise RuntimeError(
                            f"@consumer_work on {name}.{member_name}: cannot "
                            "resolve a returns= Field to a slot name; declare it "
                            "with TaskLocalVariable.uninitialized() on the owning "
                            "class."
                        )
                if slot in resolved:
                    raise ValueError(
                        f"@consumer_work on {name}.{member_name}: returns= "
                        f"contains duplicate TaskLocalVariable name '{slot}'."
                    )
                resolved.append(slot)
            setattr(value, "_consumer_return_var_names", tuple(resolved))
        return cls


def _declared_task_local_variable_field_names(resource: object) -> list[str]:
    """Return dataclass field names explicitly annotated as TaskLocalVariable."""
    if not is_dataclass(resource):
        return []
    names: list[str] = []
    for dataclass_field in fields(resource):
        if _is_task_local_variable_field(dataclass_field):
            names.append(dataclass_field.name)
    return names


def bind_task_local_variables(resource: object) -> tuple[TaskLocalVariable, ...]:
    """Bind and validate all TaskLocalVariable fields on *resource*.

    Dataclass annotations define the stable order. Additional instance
    attributes assigned to ``TaskLocalVariable`` values are accepted after the
    declared fields. The returned tuple is keyed by object identity; callers
    should not treat field names as public handles.
    """
    names = _declared_task_local_variable_field_names(resource)
    seen_names = set(names)
    for name, value in vars(resource).items():
        if isinstance(value, TaskLocalVariable) and name not in seen_names:
            names.append(name)
            seen_names.add(name)

    task_local_variables: list[TaskLocalVariable] = []
    seen_ids: set[int] = set()
    for name in names:
        try:
            value = object.__getattribute__(resource, name)
        except AttributeError as exc:
            raise ValueError(
                f"{type(resource).__name__}.{name} is declared as a "
                "TaskLocalVariable field but was not initialized."
            ) from exc
        if not isinstance(value, TaskLocalVariable):
            raise TypeError(
                f"{type(resource).__name__}.{name} is declared as a "
                f"TaskLocalVariable field but contains {type(value).__name__}."
            )
        value._bind_owner(resource, name)
        if id(value) in seen_ids:
            continue
        task_local_variables.append(value)
        seen_ids.add(id(value))

    object.__setattr__(
        resource, _TS_TASK_LOCAL_VARIABLES_ATTR, tuple(task_local_variables)
    )
    return tuple(task_local_variables)


def get_task_local_variables(resource: object) -> tuple[TaskLocalVariable, ...]:
    """Return the resource's bound TaskLocalVariable metadata objects."""
    cached = getattr(resource, _TS_TASK_LOCAL_VARIABLES_ATTR, None)
    if cached is not None:
        return cached
    return bind_task_local_variables(resource)


# ---------------------------------------------------------------------------
# Named work function decorators
# ---------------------------------------------------------------------------

_CONSUMER_WORK_FNS_ATTR = "_named_consumer_work_fns"
_PRODUCER_WORK_FNS_ATTR = "_named_producer_work_fns"
_VERIFY_MODEL_ATTR = "_ts_verify_model"


def _is_constexpr_annotation(annotation: object) -> bool:
    """True when ``annotation`` denotes ``cutlass.Constexpr`` / ``Constexpr[...]``.

    Recognizes the bare alias, the subscripted form, ``Annotated[Constexpr[...],
    ...]``, and string / postponed (PEP 563) ``"cutlass.Constexpr[...]"``.
    """
    if hasattr(annotation, "__metadata__"):
        annotation = annotation.__origin__  # type: ignore[attr-defined]
    if isinstance(annotation, str):
        return (
            "Constexpr[" in annotation or annotation.rsplit(".", 1)[-1] == "Constexpr"
        )
    return (
        annotation is cutlass.Constexpr or get_origin(annotation) is cutlass.Constexpr
    )


def _infer_work_arg_names(
    fn: Callable[..., Any],
    decorator_name: str,
    input_description: str,
) -> tuple[tuple[str, ...], tuple[str, ...], tuple[str, ...], tuple[str, ...]]:
    """Infer work-method inputs, which bind positionally, and constexpr params.

    Returns ``(var_names, positional_names, constexpr_names, required_constexpr_names)``:

    - ``var_names``: data-flow input parameters (read from consumer/producer
      task-local variables); positional-or-keyword and keyword-only.
    - ``positional_names`` ⊆ ``var_names``: the positional-or-keyword subset.
    - ``constexpr_names``: keyword-only parameters annotated
      ``cutlass.Constexpr[...]``, forwarded verbatim from the schedule call site
      (see auto-forwarding in the ``@consumer_work`` / ``@producer_work``
      wrappers).  A ``Constexpr`` param that is not keyword-only raises
      ``TypeError`` at decoration time.
    - ``required_constexpr_names`` ⊆ ``constexpr_names``: those without a default;
      the schedule builder rejects a call that omits them.
    """
    try:
        signature = inspect.signature(inspect.unwrap(fn))
    except (TypeError, ValueError):
        return (), (), (), ()

    names: list[str] = []
    positional_names: list[str] = []
    constexpr_names: list[str] = []
    required_constexpr_names: list[str] = []
    for param in signature.parameters.values():
        if param.name in {"self", "stage_info"}:
            continue
        if param.kind == inspect.Parameter.POSITIONAL_ONLY:
            raise TypeError(
                f"{decorator_name} cannot infer {input_description} for "
                f"{fn.__name__}() because parameter '{param.name}' is "
                "positional-only. Use a named positional-or-keyword or "
                "keyword-only parameter."
            )
        if param.kind == inspect.Parameter.VAR_POSITIONAL:
            raise TypeError(
                f"{decorator_name} cannot infer {input_description} for "
                f"{fn.__name__}() from *{param.name}. Use named parameters "
                "instead."
            )
        if param.kind == inspect.Parameter.VAR_KEYWORD:
            raise TypeError(
                f"{decorator_name} cannot infer {input_description} for "
                f"{fn.__name__}() from **{param.name}. Use named parameters."
            )
        if param.kind in (
            inspect.Parameter.POSITIONAL_OR_KEYWORD,
            inspect.Parameter.KEYWORD_ONLY,
        ):
            if _is_constexpr_annotation(param.annotation):
                if param.kind == inspect.Parameter.POSITIONAL_OR_KEYWORD:
                    raise TypeError(
                        f"{decorator_name} requires Constexpr parameter "
                        f"'{param.name}' of {fn.__name__}() to be keyword-only; "
                        f"declare it after '*', e.g. "
                        f"'def {fn.__name__}(self, stage_info, *, {param.name}: "
                        "cutlass.Constexpr[...])'."
                    )
                constexpr_names.append(param.name)
                if param.default is inspect.Parameter.empty:
                    required_constexpr_names.append(param.name)
                continue
            names.append(param.name)
            if param.kind == inspect.Parameter.POSITIONAL_OR_KEYWORD:
                positional_names.append(param.name)
    return (
        tuple(names),
        tuple(positional_names),
        tuple(constexpr_names),
        tuple(required_constexpr_names),
    )


def _normalize_consumer_returns(
    returns: object | None,
) -> tuple[str | Field, ...] | None:
    """Normalize ``@consumer_work(returns=...)`` slot declarations.

    Validates structural types only. Each entry is either a ``str`` slot
    name or a ``dataclasses.Field`` reference; name resolution and
    duplicate detection are deferred to the per-decorator inline resolver
    (see ``consumer_work``) because ``Field.name`` is only populated
    once ``@dataclass`` has processed the owning class, which happens
    after this normalizer runs.
    """
    if returns is None:
        return None
    if isinstance(returns, (str, Field)):
        returns = (returns,)
    elif not isinstance(returns, (tuple, list)):
        raise TypeError(
            "@consumer_work(returns=...) expects a str, dataclasses.Field, "
            "or a tuple/list of those; got "
            f"{type(returns).__name__}."
        )
    if not returns:
        raise ValueError("@consumer_work(returns=...) cannot be empty.")
    for idx, entry in enumerate(returns):
        if isinstance(entry, Field):
            if not _is_task_local_variable_field(entry):
                raise TypeError(
                    f"@consumer_work(returns=...) entry {idx} is a "
                    "dataclasses.Field that is not a task-local slot. "
                    "Declare the field with TaskLocalVariable.uninitialized() "
                    "or annotate it as TaskLocalVariable."
                )
            continue
        if not isinstance(entry, str):
            raise TypeError(
                "@consumer_work(returns=...) entries must be str or "
                f"dataclasses.Field; entry {idx} is {type(entry).__name__}."
            )
        if not entry:
            raise ValueError(
                f"@consumer_work(returns=...) entry {idx} is an empty string."
            )
    return tuple(returns)


def _format_dtype_name(dtype: object) -> str:
    """Return a compact user-facing name for a TaskLocalVariable dtype."""
    return getattr(dtype, "__name__", repr(dtype))


def _format_value_type_name(value: object) -> str:
    """Return a compact user-facing name for a produced value."""
    value_dtype = getattr(value, "dtype", None)
    if value_dtype is not None:
        return f"{type(value).__name__}(dtype={_format_dtype_name(value_dtype)})"
    return type(value).__name__


def _is_value_compatible_with_task_local_dtype(
    value: object,
    dtype: object,
) -> bool:
    """Best-effort runtime validation for ``returns=`` values."""
    dtype_isinstance = getattr(dtype, "isinstance", None)
    if callable(dtype_isinstance):
        try:
            if dtype_isinstance(value):
                return True
        except TypeError:
            pass
    if type(value) is dtype:
        return True
    if isinstance(dtype, type):
        try:
            if isinstance(value, dtype):
                return True
        except TypeError:
            pass
    value_dtype = getattr(value, "dtype", None)
    return value_dtype is dtype or value_dtype == dtype


def _validate_consumer_produced_value_dtype(
    method_name: str,
    variable: TaskLocalVariable,
    value: object,
) -> None:
    """Validate a value returned for an explicitly declared output variable."""
    if _is_value_compatible_with_task_local_dtype(value, variable.dtype):
        return
    variable_name = variable.slot_name
    raise TypeError(
        f"@consumer_work '{method_name}' returned value for "
        f"TaskLocalVariable '{variable_name}' with type "
        f"{_format_value_type_name(value)}, expected "
        f"{_format_dtype_name(variable.dtype)}."
    )


def _normalize_work_attrs(
    work_attrs: WorkAttr,
    *,
    decorator_name: str,
) -> WorkAttr:
    """Validate and return work attributes for a work decorator."""
    WorkAttr.validate(work_attrs, f"{decorator_name} work_attrs")
    return work_attrs


def _consumer_stage_from_work_attrs(work_attrs: WorkAttr) -> ScheduleStage:
    """Map consumer work attributes to the existing schedule-stage encoding."""
    if work_attrs.is_auxiliary():
        return ScheduleStage.ConsumerAuxWork
    return ScheduleStage.ConsumerWork


def _producer_stage_from_work_attrs(work_attrs: WorkAttr) -> ScheduleStage:
    """Map producer work attributes to the existing schedule-stage encoding."""
    if work_attrs.is_auxiliary():
        return ScheduleStage.ProducerAuxWork
    return ScheduleStage.ProducerWork


def _register_named_work_fn(
    wrapper: Callable[..., Any], fn: Callable[..., Any], attr: str, method_name: str
) -> None:
    """Copy the per-method work-fn registry from ``fn`` onto ``wrapper``."""
    if not hasattr(fn, attr):
        setattr(fn, attr, {})
    getattr(fn, attr)[method_name] = method_name
    if not hasattr(wrapper, attr):
        setattr(wrapper, attr, {})
    getattr(wrapper, attr).update(getattr(fn, attr, {}))


def _expose_routed_schema(
    wrapper: Callable[..., Any],
    prefix: str,
    kwarg_names: tuple[str, ...],
    positional_arg_names: tuple[str, ...],
    constexpr_arg_names: tuple[str, ...],
    required_constexpr_arg_names: tuple[str, ...],
) -> None:
    """Attach routed and constexpr parameter-name metadata to ``wrapper``."""
    if kwarg_names:
        setattr(wrapper, f"_{prefix}_routed_names", kwarg_names)
        setattr(wrapper, f"_{prefix}_routed_positional_names", positional_arg_names)
        setattr(
            wrapper,
            f"_{prefix}_routed_keyword_names",
            tuple(n for n in kwarg_names if n not in positional_arg_names),
        )
    if constexpr_arg_names:
        setattr(wrapper, f"_{prefix}_constexpr_names", constexpr_arg_names)
    if required_constexpr_arg_names:
        setattr(
            wrapper,
            f"_{prefix}_required_constexpr_names",
            required_constexpr_arg_names,
        )


def consumer_work(
    method: Callable[..., Any] | None = None,
    *,
    work_attrs: WorkAttr = WorkAttr.NONE,
    returns: str | Field | tuple[str | Field, ...] | list[str | Field] | None = None,
    verify_model: Callable[[Any, Any], object] | None = None,
) -> Callable[..., Any]:
    """Register a forwarding consumer work method.

    The wrapper passes routed and constexpr keyword arguments to the decorated
    method and returns its result directly. Metadata records its inputs, work
    attributes, and declared outputs. Return slots are stored as
    ``_ts_consumer_returns_raw`` and resolved to a
    ``_consumer_return_var_names`` tuple by :class:`MemoryResource`'s metaclass.

    ``verify_model`` can make one returned guard value a pure function of the
    resource's pipeline cursor. The exhaustive checker calls the model with
    ``(resource, cursor_snapshot)`` while enumerating a ``while_true_loop`` and
    rejects opaque round assignments that disagree with it. The callable must
    model the decorated method's single declared output; it is verifier-only
    and is not cross-checked against the runtime method body.
    """
    normalized_work_attrs = _normalize_work_attrs(
        work_attrs, decorator_name="@consumer_work"
    )
    consumer_stage = _consumer_stage_from_work_attrs(normalized_work_attrs)
    normalized_returns = _normalize_consumer_returns(returns)
    if verify_model is not None:
        if not callable(verify_model):
            raise TypeError(
                "@consumer_work(verify_model=...) must be callable, got "
                f"{type(verify_model).__name__}."
            )
        if normalized_returns is None or len(normalized_returns) != 1:
            raise TypeError(
                "@consumer_work(verify_model=...) requires exactly one "
                "returns= output for the model to stand in for."
            )

    def decorator(fn: Callable[..., Any]) -> Callable[..., Any]:
        method_name = fn.__name__
        (
            kwarg_names,
            positional_arg_names,
            constexpr_arg_names,
            required_constexpr_arg_names,
        ) = _infer_work_arg_names(fn, "@consumer_work", "consumer inputs")

        @functools.wraps(fn)
        def wrapper(
            self: MemoryResource, stage_info: StageInfo, **work_kwargs: Any
        ) -> Any:
            return fn(self, stage_info, **work_kwargs)

        _register_named_work_fn(wrapper, fn, _CONSUMER_WORK_FNS_ATTR, method_name)
        _expose_routed_schema(
            wrapper,
            "consumer",
            kwarg_names,
            positional_arg_names,
            constexpr_arg_names,
            required_constexpr_arg_names,
        )
        if normalized_returns is not None:
            setattr(wrapper, "_ts_consumer_returns_raw", normalized_returns)
        if verify_model is not None:
            setattr(wrapper, _VERIFY_MODEL_ATTR, verify_model)
        setattr(wrapper, "_consumer_work_attrs", normalized_work_attrs)
        setattr(wrapper, "_consumer_work_stage", consumer_stage)
        return wrapper

    if method is not None:
        if not callable(method):
            raise TypeError(
                f"@consumer_work must decorate a method directly. Got {type(method)}."
            )
        return decorator(method)
    return decorator


def verify_model_for(
    resource: "MemoryResource", method_label: str
) -> Callable[[Any, Any], object] | None:
    """Return a named consumer-work method's verifier model, if declared."""
    method_name = _collect_named_work_fns(type(resource), _CONSUMER_WORK_FNS_ATTR).get(
        method_label
    )
    if method_name is None:
        return None
    return getattr(getattr(type(resource), method_name, None), _VERIFY_MODEL_ATTR, None)


def producer_work(
    method: Callable[..., Any] | None = None,
    *,
    work_attrs: WorkAttr = WorkAttr.NONE,
) -> Callable[..., Any]:
    """Register a forwarding producer work method.

    The wrapper passes routed and constexpr keyword arguments to the decorated
    method and returns its result directly. Metadata records its inputs and work
    attributes.
    """
    normalized_work_attrs = _normalize_work_attrs(
        work_attrs, decorator_name="@producer_work"
    )
    producer_stage = _producer_stage_from_work_attrs(normalized_work_attrs)

    def decorator(fn: Callable[..., Any]) -> Callable[..., Any]:
        method_name = fn.__name__
        (
            kwarg_names,
            positional_arg_names,
            constexpr_arg_names,
            required_constexpr_arg_names,
        ) = _infer_work_arg_names(fn, "@producer_work", "producer inputs")

        @functools.wraps(fn)
        def wrapper(
            self: MemoryResource, stage_info: StageInfo, **work_kwargs: Any
        ) -> Any:
            return fn(self, stage_info, **work_kwargs)

        _register_named_work_fn(wrapper, fn, _PRODUCER_WORK_FNS_ATTR, method_name)
        _expose_routed_schema(
            wrapper,
            "producer",
            kwarg_names,
            positional_arg_names,
            constexpr_arg_names,
            required_constexpr_arg_names,
        )
        setattr(wrapper, "_producer_work_attrs", normalized_work_attrs)
        setattr(wrapper, "_producer_work_stage", producer_stage)
        return wrapper

    if method is not None:
        if not callable(method):
            raise TypeError(
                f"@producer_work must decorate a method directly. Got {type(method)}."
            )
        return decorator(method)
    return decorator


def _collect_named_work_fns(cls: type, attr: str) -> dict:
    """Walk the MRO and merge all ``attr`` registries into one dict.

    Returns a mapping ``{label: method_name}`` aggregated from
    every class in the MRO that has methods decorated with
    ``@consumer_work`` / ``@producer_work``.

    Cached per ``(cls, attr)`` pair — the MRO and decorator
    registrations are fixed after class definition.
    """
    merged = {}
    for klass in reversed(cls.__mro__):
        for method in vars(klass).values():
            registry = getattr(method, attr, None)
            if registry is not None:
                merged.update(registry)
    return merged


def _format_did_you_mean(label: str, available: list) -> str:
    """Return a human-readable suggestion for a mismatched label.

    Uses ``difflib.get_close_matches`` (edit-distance based) to find
    the closest registered labels.  Returns an empty string when no
    close match exists.
    """
    matches = difflib.get_close_matches(
        str(label), [str(a) for a in available], n=3, cutoff=0.4
    )
    if matches:
        suggestions = ", ".join(repr(m) for m in matches)
        return f"  Did you mean: {suggestions}?"
    return ""


@dataclass(kw_only=True)
class MemoryResource(metaclass=_MemoryResourceMeta):
    """Base class for every resource in the TS dataflow graph.

    A ``MemoryResource`` represents a named piece of memory (GMEM, SMEM,
    TMEM, etc.) together with the pipeline that guards access to it.
    Subclasses override the hook methods below to define resource-specific
    behaviour; the ``Task`` scheduler calls them at the appropriate points.

    Named work functions
    --------------------
    Subclasses register named work methods with the ``@consumer_work`` /
    ``@producer_work`` decorators.  The step's ``label`` selects which
    method to call at trace time::

        @consumer_work
        @cute.jit
        def k_desc(self, stage_info):
            ...

        @consumer_work
        @cute.jit
        def v_desc(self, stage_info):
            ...

    Each ``ConsumerWork`` step must carry a label when two or more named
    methods are registered; the label is the method name, e.g. ``"k_desc"``.

    Label validation:

    * Typos raise ``ValueError`` with a did-you-mean suggestion.
    * Missing labels with ≥2 named methods raise ``ValueError``.
    * A single named method auto-dispatches without a label.
    * No named methods → monolithic ``consumer_work()`` is called.

    Hook methods (override in subclasses)
    --------------------------------------
    * ``get_smem_requirements() -> list[SmemAllocation]`` returns
      ``SmemAllocation`` objects for data SMEM this resource needs. Default
      returns ``[]``.
    * ``get_tmem_requirements() -> list[TmemAllocation]`` returns
      ``TmemAllocation`` objects for TMEM columns this resource needs. Default
      returns ``[]``.
    * ``consumer_aux_work(stage_info)`` is helper-variable logic executed
      during ``ScheduleStage.ConsumerAuxWork``.
    * ``consumer_work(stage_info)`` is user logic executed during
      ``ScheduleStage.ConsumerWork``. Overridden by ``@consumer_work`` methods
      when labels are used.
    * ``producer_aux_work(stage_info)`` is helper-variable logic executed
      during ``ScheduleStage.ProducerAuxWork``.
    * ``producer_work(stage_info)`` is user logic executed during
      ``ScheduleStage.ProducerWork``. Overridden by ``@producer_work`` methods
      when labels are used.

    Attributes
    ----------
    name : str
        Human-readable label (used in debug prints and PTX comments).
    pipeline_config : PipelineConfig or None
        Pipeline descriptor; ``None`` for resources that need no pipeline
        (e.g. GMEM source/sink).
    pipeline : object or None
        Materialised pipeline object, set by ``create()``.
    consumer_state, producer_state
        Pipeline state objects (stage index + phase bit).  With
        ``advance_on_acquire``, ``producer_state`` is the acquire cursor and
        ``producer_commit_state`` is the lagging commit cursor.  Producer work
        derives the just-acquired state from ``producer_state`` or follows the
        commit cursor, depending on the work slot.
    consumer_status, producer_status
        Boolean flags used by try_wait / try_acquire. The matching blocking
        operation consumes and clears its flag.
    is_barrier : bool
        ``True`` for pure signaling resources that carry no data (e.g.
        sequence barriers, done notifications).  Barrier resources get
        relaxed dependency-backing rules in ``_verify_resource_deps``.
    dummy : bool
        Keep DSL state live across dynamic control-flow boundaries.
    """

    name: cutlass.Constexpr[str] = ""
    is_barrier: cutlass.Constexpr[bool] = False
    pipeline_config: cutlass.Constexpr[Optional[PipelineConfig]] = None
    pipeline: cutlass.Constexpr = None
    consumer_state: Any = field(init=False, default=None)
    producer_state: Any = field(init=False, default=None)
    producer_commit_state: Any = field(init=False, default=None)
    consumer_status: Any = field(init=False, default=None)
    producer_status: Any = field(init=False, default=None)
    # advance_on_wait: separate release state (lags behind consumer_state)
    # and work stage (captures the stage index right before wait-advance).
    consumer_release_state: Any = field(init=False, default=None)
    consumer_work_stage: Any = field(init=False, default=None)
    _ts_producer_state_slots: cutlass.Constexpr[int] = field(init=False, default=1)
    _ts_consumer_state_slots: cutlass.Constexpr[int] = field(init=False, default=1)
    # Optional override: use a different CTA signaling mode for ConsumerWait
    # than for ConsumerRelease.  When set, _consumer_try_wait and
    # _consumer_wait in Task use this instead of
    # pipeline_config.consumer_signaling_threads.  ConsumerRelease is
    # unchanged (still uses pipeline_config.consumer_signaling_threads).
    # This enables split-consumer patterns where one task waits (on all
    # CTAs) and another task releases (on leader CTA only).
    consumer_wait_signaling_threads: cutlass.Constexpr[Optional[SignalingThreads]] = (
        None
    )
    # Back-reference to the PipelineGroup this resource belongs to, if any.
    # Set automatically by PipelineGroup.__post_init__().
    pipeline_group: cutlass.Constexpr[Optional["PipelineGroup"]] = field(
        init=False,
        default=None,
    )
    # Derived by TaskManager runtime-metadata preparation for TmaAsync resources
    # whose consumer_group.size matches all participating consumer threads rather
    # than CUTLASS's default per-warp release predicate.
    _tma_async_consumer_release_uses_all_threads: cutlass.Constexpr[bool] = field(
        init=False,
        default=False,
    )
    # Derived by TaskManager for TMA resources that use TaskWarpLeader.
    # Pipeline creation uses these task start warps to build the runtime
    # predicate that narrows transaction-barrier arming.
    _producer_warp_leader_idxs: cutlass.Constexpr[Tuple[int, ...]] = field(
        init=False,
        default=(),
    )
    # State-source override for Merge PipelineGroup members.
    _state_src_owner: cutlass.Constexpr = field(init=False, default=None)
    # Dummy field used to force self updated across dynamic control flow.
    # Declared here so every subclass has a consistent structure in DSL for-loops.
    dummy: cutlass.Constexpr[bool] = field(init=False, default=False)
    _ts_task_local_variables: cutlass.Constexpr[object] = field(
        init=False, default=None, repr=False
    )

    def __hash__(self) -> int:
        """Identity-based hash so resources can be used as dict keys."""
        return id(self)

    def __setattr__(self, name: str, value: object) -> None:
        """Bind a TaskLocalVariable to its owning field on assignment."""
        if isinstance(value, TaskLocalVariable):
            value._bind_owner(self, name)
        object.__setattr__(self, name, value)

    @property
    def state_src(self) -> "MemoryResource":
        """The object that owns this resource's *consumer* pipeline state.

        Returns ``self`` by default.  For a member of a Merge or FusedMerge
        ``PipelineGroup`` this returns the group itself, so all
        members share the group's canonical consumer state (one
        consumer drives pipeline progression).  Fork members and
        non-group resources use their own state (returns ``self``).

        **Producer state is NOT redirected.**  Each producer task
        independently tracks its own stage via ``resource.producer_state``.
        Code on the producer side must use ``resource.producer_state``
        directly, not ``resource.state_src.producer_state``.

        Pre-resolving the state source as a plain Python attribute
        access (instead of a ``_resolve_dispatch`` function call
        inside ``@cute.jit`` regions) avoids DSL-tracer side
        effects that would otherwise emit IR dominance errors.
        The ``_state_src_owner`` field is set by
        ``PipelineGroup.__post_init__`` for Merge and FusedMerge members.
        """
        return self._state_src_owner if self._state_src_owner is not None else self

    def __init_subclass__(cls, **kwargs: object) -> None:
        """Ensure every subclass dataclass remains hashable.

        Python's ``@dataclass`` sets ``__hash__ = None`` on any class that
        defines (or inherits) ``__eq__`` without ``unsafe_hash=True``.
        By unconditionally placing ``__hash__`` in ``cls.__dict__`` here
        (before the ``@dataclass`` decorator runs), the decorator sees an
        explicit definition and leaves it alone.
        """
        super().__init_subclass__(**kwargs)
        cls.__hash__ = MemoryResource.__hash__  # type: ignore[method-assign]

    def create_pipeline(self, pipeline_config: PipelineConfig) -> object:
        """Materialise a pipeline object from the given config.

        Allocates SMEM barrier storage (if not pre-supplied in
        ``pipeline_config.barrier_ptr``), then dispatches to the correct
        pipeline constructor based on ``pipeline_config.pipeline_type``.

        All pipelines are created with ``defer_sync=True`` so that
        barrier initialisation fencing is left to the caller
        (``TaskManager`` / kernel).
        """
        barrier_ptr = pipeline_config.barrier_ptr
        if barrier_ptr is None:
            barrier_storage: cutlass.Array = cutlass.Array(
                cutlass.Int64,
                pipeline_config.num_stages * 2,
                space=cutlass.AddressSpace.smem,
                alignment=8,
            )
            barrier_ptr = cute.make_ptr(
                cutlass.Int64,
                barrier_storage.data_ptr(),
                mem_space=cutlass.AddressSpace.smem,
            )

        # Default offsets use a contiguous layout (full at 0, empty at num_stages).
        off_full = pipeline_config.resolved_storage_offset_full
        off_empty = pipeline_config.resolved_storage_offset_empty
        defer_init = pipeline_config.defer_init

        if pipeline_config.pipeline_type == PipelineType.AsyncAsync:
            if pipeline_config.async_producer_op == pipeline.PipelineOp.AsyncLoad:
                sync_object_full = pipeline.PipelineAsync._make_sync_object(
                    barrier_ptr.align(min_align=8) + off_full,
                    pipeline_config.num_stages,
                    (
                        pipeline.PipelineOp.AsyncLoad,
                        pipeline_config.producer_group,
                    ),
                    defer_init=defer_init,
                )
                sync_object_empty = pipeline.PipelineAsync._make_sync_object(
                    barrier_ptr.align(min_align=8) + off_empty,
                    pipeline_config.num_stages,
                    (
                        pipeline.PipelineOp.AsyncThread,
                        pipeline_config.consumer_group,
                    ),
                    defer_init=defer_init,
                )
                return pipeline.PipelineAsync(
                    sync_object_full,
                    sync_object_empty,
                    pipeline_config.num_stages,
                    None,
                    None,
                )
            return pipeline.PipelineAsync.create(
                num_stages=pipeline_config.num_stages,
                producer_group=pipeline_config.producer_group,
                consumer_group=pipeline_config.consumer_group,
                barrier_storage=barrier_ptr,
                defer_sync=True,
                defer_init=defer_init,
                storage_offset_full=pipeline_config.storage_offset_full,
                storage_offset_empty=pipeline_config.storage_offset_empty,
            )
        elif pipeline_config.pipeline_type == PipelineType.TmaAsync:
            cta_layout = pipeline_config.cta_layout_vmnk
            if cta_layout is not None and not isinstance(cta_layout, cute.Layout):
                cta_layout = cute.make_layout(cta_layout)
            if self._tma_async_consumer_release_uses_all_threads:
                if (
                    pipeline_config.producer_group.agent is not pipeline.Agent.Thread
                    or pipeline_config.consumer_group.agent is not pipeline.Agent.Thread
                ):
                    raise ValueError(
                        "TmaAsync all-thread consumer release requires Thread "
                        "producer/consumer groups so mbarrier arrive counts are "
                        "already expressed in threads."
                    )
                sync_object_full = pipeline.PipelineAsync._make_sync_object(
                    barrier_ptr.align(min_align=8) + off_full,
                    pipeline_config.num_stages,
                    (pipeline.PipelineOp.TmaLoad, pipeline_config.producer_group),
                    pipeline_config.num_bytes,
                    defer_init=defer_init,
                )
                sync_object_empty = pipeline.PipelineAsync._make_sync_object(
                    barrier_ptr.align(min_align=8) + off_empty,
                    pipeline_config.num_stages,
                    (pipeline.PipelineOp.AsyncThread, pipeline_config.consumer_group),
                    defer_init=defer_init,
                )
                if pipeline_config.producer_signaling_threads.has_task_warp_leader():
                    return ts_pipeline.TSPipelineTmaAsync(
                        sync_object_full,
                        sync_object_empty,
                        pipeline_config.num_stages,
                        None,
                        None,
                        cast(cutlass.Boolean, True),
                        self._producer_task_warp_leader_predicate(
                            include_cta_leader=True,
                        ),
                    )
                return pipeline.PipelineTmaAsync(
                    sync_object_full,
                    sync_object_empty,
                    pipeline_config.num_stages,
                    None,
                    None,
                    cast(cutlass.Boolean, True),
                )
            if pipeline_config.producer_signaling_threads.has_task_warp_leader():
                return ts_pipeline.TSPipelineTmaAsync.create(
                    num_stages=pipeline_config.num_stages,
                    producer_group=pipeline_config.producer_group,
                    consumer_group=pipeline_config.consumer_group,
                    tx_count=pipeline_config.num_bytes,
                    barrier_storage=barrier_ptr,
                    is_task_warp_leader=self._producer_task_warp_leader_predicate(
                        include_cta_leader=True,
                    ),
                    cta_layout_vmnk=cta_layout,
                    mcast_mode_mn=pipeline_config.mcast_mode_mn,
                    defer_sync=True,
                    defer_init=defer_init,
                    storage_offset_full=pipeline_config.storage_offset_full,
                    storage_offset_empty=pipeline_config.storage_offset_empty,
                )
            return pipeline.PipelineTmaAsync.create(
                num_stages=pipeline_config.num_stages,
                producer_group=pipeline_config.producer_group,
                consumer_group=pipeline_config.consumer_group,
                tx_count=pipeline_config.num_bytes,
                barrier_storage=barrier_ptr,
                cta_layout_vmnk=cta_layout,
                mcast_mode_mn=pipeline_config.mcast_mode_mn,
                defer_sync=True,
                defer_init=defer_init,
                storage_offset_full=pipeline_config.storage_offset_full,
                storage_offset_empty=pipeline_config.storage_offset_empty,
            )
        elif pipeline_config.pipeline_type == PipelineType.TmaUmma:
            cta_layout = pipeline_config.cta_layout_vmnk
            if not isinstance(cta_layout, cute.Layout):
                cta_layout = cute.make_layout(cta_layout)
            tma_umma_pipeline = pipeline.PipelineTmaUmma.create(
                num_stages=pipeline_config.num_stages,
                producer_group=pipeline_config.producer_group,
                consumer_group=pipeline_config.consumer_group,
                tx_count=pipeline_config.num_bytes,
                barrier_storage=barrier_ptr,
                cta_layout_vmnk=cta_layout,
                mcast_mode_mn=pipeline_config.mcast_mode_mn,
                defer_sync=True,
                defer_init=defer_init,
                storage_offset_full=pipeline_config.storage_offset_full,
                storage_offset_empty=pipeline_config.storage_offset_empty,
            )
            return self._apply_task_warp_leader_to_tma_umma(tma_umma_pipeline)
        elif pipeline_config.pipeline_type == PipelineType.UmmaAsync:
            cta_layout = pipeline_config.cta_layout_vmnk
            if not isinstance(cta_layout, cute.Layout):
                cta_layout = cute.make_layout(cta_layout)
            return pipeline.PipelineUmmaAsync.create(
                num_stages=pipeline_config.num_stages,
                producer_group=pipeline_config.producer_group,
                consumer_group=pipeline_config.consumer_group,
                barrier_storage=barrier_ptr,
                cta_layout_vmnk=cta_layout,
                defer_sync=True,
                defer_init=defer_init,
                storage_offset_full=pipeline_config.storage_offset_full,
                storage_offset_empty=pipeline_config.storage_offset_empty,
            )
        elif pipeline_config.pipeline_type == PipelineType.UmmaUmma:
            cta_layout = pipeline_config.cta_layout_vmnk
            if not isinstance(cta_layout, cute.Layout):
                cta_layout = cute.make_layout(cta_layout)
            return ts_pipeline.TSPipelineUmmaUmma.create(
                num_stages=pipeline_config.num_stages,
                producer_group=pipeline_config.producer_group,
                consumer_group=pipeline_config.consumer_group,
                barrier_storage=barrier_ptr,
                cta_layout_vmnk=cta_layout,
                defer_sync=True,
                defer_init=defer_init,
                storage_offset_full=pipeline_config.storage_offset_full,
                storage_offset_empty=pipeline_config.storage_offset_empty,
            )
        elif pipeline_config.pipeline_type == PipelineType.AsyncUmma:
            cta_layout = pipeline_config.cta_layout_vmnk
            if not isinstance(cta_layout, cute.Layout):
                cta_layout = cute.make_layout(cta_layout)
            return ts_pipeline.TSPipelineAsyncUmma.create(
                num_stages=pipeline_config.num_stages,
                producer_group=pipeline_config.producer_group,
                consumer_group=pipeline_config.consumer_group,
                barrier_storage=barrier_ptr,
                cta_layout_vmnk=cta_layout,
                producer_op=pipeline_config.umma_consumer_producer_op,
                defer_sync=True,
                defer_init=defer_init,
                storage_offset_full=pipeline_config.storage_offset_full,
                storage_offset_empty=pipeline_config.storage_offset_empty,
            )
        elif pipeline_config.pipeline_type == PipelineType.ClcFetchAsync:
            cta_layout = pipeline_config.cta_layout_vmnk
            if not isinstance(cta_layout, cute.Layout):
                cta_layout = cute.make_layout(cta_layout)
            return pipeline.PipelineClcFetchAsync.create(
                num_stages=pipeline_config.num_stages,
                producer_group=pipeline_config.producer_group,
                consumer_group=pipeline_config.consumer_group,
                tx_count=pipeline_config.num_bytes,
                barrier_storage=barrier_ptr,
                cta_layout_vmnk=cta_layout,
                defer_sync=True,
                defer_init=defer_init,
                storage_offset_full=pipeline_config.storage_offset_full,
                storage_offset_empty=pipeline_config.storage_offset_empty,
            )
        else:
            raise ValueError(f"Invalid pipeline type: {pipeline_config.pipeline_type}")

    def get_producer_acquire_state(self) -> object:
        """Return the state used for producer-side empty-barrier waits."""
        return self.producer_state

    def get_producer_commit_state(self) -> object:
        """Return the state used for producer-side full-barrier commits."""
        if self.pipeline_config is not None and self.pipeline_config.advance_on_acquire:
            return self.producer_commit_state
        return self.producer_state

    def get_producer_work_state(self, follows_acquire: bool = True) -> object:
        """Return the state used for producer-side data movement.

        With ``advance_on_acquire``, work does not have an independent
        pipeline cursor.  Work that follows acquire derives its stage from the
        acquire cursor in ``Task._create_stage_info``; work that does not
        follow acquire uses the lagging commit cursor.
        """
        if self.pipeline_config is not None and self.pipeline_config.advance_on_acquire:
            if not follows_acquire:
                return self.producer_commit_state
            return self.producer_state
        return self.producer_state

    @staticmethod
    def _get_cta_v_size(pipeline_config: PipelineConfig) -> int:
        """Extract the V-group size from ``cta_layout_vmnk``."""
        layout = pipeline_config.cta_layout_vmnk
        if layout is None:
            return 1
        if isinstance(layout, (tuple, list)) and len(layout) > 0:
            return int(layout[0])
        return 1

    def _producer_task_warp_leader_predicate(
        self,
        *,
        include_cta_leader: bool = False,
    ) -> cutlass.Boolean:
        """Return true for the first warp of each producer task."""
        assert self.pipeline_config is not None
        warp_leader_idxs = self._producer_warp_leader_idxs
        if not warp_leader_idxs:
            raise ValueError(
                f"Resource '{self.name}' requested TaskWarpLeader signaling, "
                "but TaskManager did not derive any producer warp leader index."
            )
        warp_idx = cute.arch.warp_idx()
        is_task_warp_leader = warp_idx == cutlass.Int32(warp_leader_idxs[0])
        for leader_idx in warp_leader_idxs[1:]:
            is_task_warp_leader = is_task_warp_leader | (
                warp_idx == cutlass.Int32(leader_idx)
            )
        if (
            include_cta_leader
            and self.pipeline_config.producer_signaling_threads.has_cta_leader()
        ):
            cta_rank = cute.arch.make_warp_uniform(cute.arch.block_idx_in_cluster())
            cta_v_size = self._get_cta_v_size(self.pipeline_config)
            is_task_warp_leader = is_task_warp_leader & (cta_rank % cta_v_size == 0)
        return is_task_warp_leader

    def _apply_task_warp_leader_to_tma_umma(self, tma_umma_pipeline: Any) -> object:
        """Narrow CuTeDSL TmaUmma ``is_leader_cta`` for TaskWarpLeader mode."""
        assert self.pipeline_config is not None
        if not self.pipeline_config.producer_signaling_threads.has_task_warp_leader():
            return tma_umma_pipeline
        is_task_warp_leader = self._producer_task_warp_leader_predicate()
        is_leader_cta = tma_umma_pipeline.is_leader_cta
        if isinstance(is_leader_cta, bool):
            narrowed = is_task_warp_leader if is_leader_cta else False
        else:
            narrowed = is_leader_cta & is_task_warp_leader
        object.__setattr__(tma_umma_pipeline, "is_leader_cta", narrowed)
        return tma_umma_pipeline

    def create(self) -> None:
        """Materialise the pipeline (if configured).

        Called once per resource from
        ``TaskManager.setup_resources_and_tasks()``.  Subclasses that
        need additional one-time setup (e.g. ``WorkQueue`` creating its
        tile scheduler) should call ``super().create()`` first.

        Members of a ``PipelineGroup`` skip pipeline creation — their
        barrier ops are routed through the group's shared pipeline.
        """
        if self.pipeline_config is not None and self.pipeline_group is None:
            self.pipeline = self.create_pipeline(self.pipeline_config)

    def get_smem_requirements(self) -> List[SmemAllocation]:
        """Return SMEM allocations required by this resource.

        Override in subclasses that use data SMEM (not barrier SMEM,
        which is managed by ``create_pipeline``).  The returned
        ``SmemAllocation`` objects should be stored as instance
        attributes so the resource can read their ``.offset`` later.

        Default returns an empty list (no data SMEM needed).
        """
        return []

    def get_tmem_requirements(self) -> List[TmemAllocation]:
        """Return TMEM column allocations required by this resource.

        Override in subclasses that use TMEM.  The returned
        ``TmemAllocation`` objects should be stored as instance
        attributes so the resource can read their ``.offset`` later.

        Default returns an empty list (no TMEM needed).
        """
        return []

    def get_producer_requirements(self) -> Optional[list]:
        """Return allocations accessed during ``ProducerWork``.

        Override in subclasses where the producer only accesses a subset
        of the resource's allocations.  Return a list containing any mix
        of ``SmemAllocation`` and ``TmemAllocation`` objects.

        The exhaustive checker uses this to build a producer-specific
        alias map so that ``prod_work`` only conflicts with aliases that
        overlap these ranges.

        Default returns ``None`` (all allocations from
        ``get_smem_requirements`` + ``get_tmem_requirements`` are
        considered producer-accessible).
        """
        return None

    def get_consumer_requirements(self) -> Optional[list]:
        """Return allocations accessed during ``ConsumerWork``.

        Symmetric counterpart of ``get_producer_requirements``.  Override
        in subclasses where the consumer only accesses a subset of the
        resource's allocations.

        Default returns ``None`` (all allocations are consumer-accessible).
        """
        return None

    @cute.jit
    def initialize_runtime_state_internal(
        self,
        context: Optional[ResourceContext] = None,
    ) -> None:
        """Initialize pipeline state and status fields.

        Always creates ``consumer_status`` / ``producer_status`` (Int32)
        and ``consumer_state`` / ``producer_state`` (pipeline state or
        dummy Int32) so that the DSL tree shape is consistent regardless
        of whether a pipeline is attached.

        For CLC pipelines the producer
        state uses ``ProducerConsumer`` mode to support both roles.
        """
        del context

        # IMPORTANT: Always initialize status fields to maintain consistent structure
        # across all resources, even if pipeline_config is None. This prevents DSL
        # structure change errors when different resources are used in head vs loop
        # schedules.
        #
        # Use Int32 instead of Boolean to avoid IR boolean-ref edge cases:
        # Boolean (i1) first-defs are skipped by the boolean assignment pass.
        # guard, and the anti-aliasing _reconstruct path can produce stale SSA
        # values that violate MLIR dominance when the status crosses scf.if
        # region boundaries (consumer_try_wait → consumer_wait).  Int32 refs
        # are well-tested and bypass all boolean-specific code paths.
        self.consumer_status = cutlass.Int32(0)
        self.producer_status = cutlass.Int32(0)

        # Members of a Merge / FusedMerge PipelineGroup share the group's
        # pipeline state (one consumer drives progression).  Fork members need
        # their own states because consumers advance independently.
        from .enums import PipelineGroupMode
        from .pipeline_group import PipelineGroup

        # Merge consumers are read from ``resource.state_src`` (the group).
        # Slot counts are published on the member that minted the cursor;
        # copy them onto the group before this path allocates, because
        # TaskManager initialises groups before any member.  The type check is
        # compile-time because PipelineGroup is Python-only metadata.
        if cutlass.const_expr(
            isinstance(self, PipelineGroup)
            and self.mode in (PipelineGroupMode.Merge, PipelineGroupMode.FusedMerge)
        ):
            for member in cast(PipelineGroup, self).members:
                self._ts_consumer_state_slots = max(
                    self._ts_consumer_state_slots,
                    member._ts_consumer_state_slots,
                )

        has_own_pipeline = self.pipeline_config is not None and (
            self.pipeline_group is None
            or self.pipeline_group.mode == PipelineGroupMode.Fork
        )
        is_merge_member = (
            self.pipeline_config is not None
            and self.pipeline_group is not None
            and isinstance(self.pipeline_group, PipelineGroup)
            and self.pipeline_group.mode
            in (PipelineGroupMode.Merge, PipelineGroupMode.FusedMerge)
        )
        if cutlass.const_expr(has_own_pipeline):
            assert self.pipeline_config is not None
            self.consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer,
                self.pipeline_config.num_stages,
            )
            # CLC pipelines use ProducerConsumer state to support both roles
            if cutlass.const_expr(
                self.pipeline_config.pipeline_type == PipelineType.ClcFetchAsync
            ):
                self.producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.ProducerConsumer,
                    self.pipeline_config.num_stages,
                )
                if cutlass.const_expr(
                    self.pipeline_config.advance_on_acquire
                    or self._ts_producer_state_slots > 1
                ):
                    self.producer_commit_state = pipeline.make_pipeline_state(
                        pipeline.PipelineUserType.ProducerConsumer,
                        self.pipeline_config.num_stages,
                    )
                else:
                    self.producer_commit_state = cutlass.Int32(0)
            else:
                self.producer_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer,
                    self.pipeline_config.num_stages,
                )
                if cutlass.const_expr(
                    self.pipeline_config.advance_on_acquire
                    or self._ts_producer_state_slots > 1
                ):
                    self.producer_commit_state = pipeline.make_pipeline_state(
                        pipeline.PipelineUserType.Producer,
                        self.pipeline_config.num_stages,
                    )
                else:
                    self.producer_commit_state = cutlass.Int32(0)
            # advance_on_wait: separate release state tracks which stage to
            # release next (lags behind consumer_state when releases are
            # deferred). consumer_work_stage captures the stage index that
            # _consumer_wait just waited on (before advancing consumer_state).
            if cutlass.const_expr(
                self.pipeline_config.advance_on_wait
                or self._ts_consumer_state_slots > 1
            ):
                self.consumer_release_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer,
                    self.pipeline_config.num_stages,
                )
                self.consumer_work_stage = cutlass.Int32(0)
            else:
                self.consumer_release_state = cutlass.Int32(0)
                self.consumer_work_stage = cutlass.Int32(0)
        elif cutlass.const_expr(is_merge_member):
            assert self.pipeline_config is not None
            # Merge PipelineGroup member: create independent pipeline
            # states that mirror the group's state types.  Each task
            # independently tracks stage progression; warp-to-warp
            # synchronisation is via mbarriers, not shared register state.
            self.consumer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Consumer,
                self.pipeline_config.num_stages,
            )
            self.producer_state = pipeline.make_pipeline_state(
                pipeline.PipelineUserType.Producer,
                self.pipeline_config.num_stages,
            )
            if cutlass.const_expr(
                self.pipeline_config.advance_on_acquire
                or self._ts_producer_state_slots > 1
            ):
                self.producer_commit_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer,
                    self.pipeline_config.num_stages,
                )
            else:
                self.producer_commit_state = cutlass.Int32(0)
            if cutlass.const_expr(
                self.pipeline_config.advance_on_wait
                or self._ts_consumer_state_slots > 1
            ):
                self.consumer_release_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Consumer,
                    self.pipeline_config.num_stages,
                )
                self.consumer_work_stage = cutlass.Int32(0)
            else:
                self.consumer_release_state = cutlass.Int32(0)
                self.consumer_work_stage = cutlass.Int32(0)
        else:
            # Create dummy state for resources without pipelines
            self.consumer_state = cutlass.Int32(0)
            self.producer_state = cutlass.Int32(0)
            self.producer_commit_state = cutlass.Int32(0)
            self.consumer_release_state = cutlass.Int32(0)
            self.consumer_work_stage = cutlass.Int32(0)

    @cute.jit
    def store_consumer_status(self, value: cutlass.Boolean) -> None:
        """Store consumer_status via self so the IR pass instruments the write.

        Converts the Boolean (i1) from consumer_try_wait to Int32 to
        avoid IR boolean-ref edge cases (see initialize_runtime_state_internal).
        """
        self.consumer_status = cutlass.Int32(value)

    @cute.jit
    def load_consumer_status(self) -> cutlass.Int32:
        """Load consumer_status via self so the IR pass instruments the read.

        Returns Int32; the pipeline's consumer_wait already compares
        with 0 via arith.cmpi so no conversion back to Boolean is needed.
        """
        return self.consumer_status

    @cute.jit
    def clear_consumer_status(self) -> None:
        """Clear the one-shot consumer probe token after its wait consumes it.

        Assigns through ``self`` so the IR pass instruments the write.  Callers
        must emit this at the top level of the blocking step lowering rather
        than under its runtime signaling gate.
        """
        self.consumer_status = cutlass.Int32(0)

    @cute.jit
    def store_producer_status(self, value: cutlass.Boolean) -> None:
        """Store producer_status via self so the IR pass instruments the write.

        Converts the Boolean (i1) from producer_try_acquire to Int32 to
        avoid IR boolean-ref edge cases (see initialize_runtime_state_internal).
        """
        self.producer_status = cutlass.Int32(value)

    @cute.jit
    def load_producer_status(self) -> cutlass.Int32:
        """Load producer_status via self so the IR pass instruments the read.

        Returns Int32; the pipeline's producer_acquire already compares
        with 0 via arith.cmpi so no conversion back to Boolean is needed.
        """
        return self.producer_status

    @cute.jit
    def clear_producer_status(self) -> None:
        """Clear the one-shot producer probe token after acquire consumes it.

        Assigns through ``self`` so the IR pass instruments the write.  Callers
        must emit this at the top level of the blocking step lowering rather
        than under its runtime signaling gate.
        """
        self.producer_status = cutlass.Int32(0)

    def consumer_work(self, stage_info: StageInfo) -> None:
        """Consumer-side user logic.

        Parameters
        ----------
        stage_info : StageInfo
            Current loop, stage, barrier, work-tile, and resource context.

        Override in subclasses that use the monolithic work hook instead of
        named ``@consumer_work`` methods.
        """
        pass

    def consumer_aux_work(self, stage_info: StageInfo) -> None:
        """Helper-variable consumer work that does not model memory access.

        Parameters
        ----------
        stage_info : StageInfo
            Current loop, stage, barrier, work-tile, and resource context.
        """
        pass

    def producer_aux_work(self, stage_info: StageInfo) -> None:
        """Helper-variable producer work that does not model memory access.

        Parameters
        ----------
        stage_info : StageInfo
            Current loop, stage, barrier, work-tile, and resource context.
        """
        pass

    def producer_work(self, stage_info: StageInfo) -> None:
        """Producer-side user logic.

        Parameters
        ----------
        stage_info : StageInfo
            Current loop, stage, barrier, work-tile, and resource context.

        Override in subclasses that use the monolithic work hook instead of
        named ``@producer_work`` methods.
        """
        pass

    def physical_ranges(self) -> list[tuple[str, int, int]]:
        """Declare physical memory regions this resource occupies.

        Returns a list of ``(memory_space, start_col, end_col)`` tuples
        describing the physical address ranges.  Used by the cross-tile
        aliasing verifier to detect potential data races between resources
        that share the same physical memory (e.g. TMEM column overlaps).

        Override in subclasses whose physical storage overlaps with other
        resources.  Default: empty (no declared ranges, no aliasing checks).
        """
        return []


@dataclass(kw_only=True)
class PdlWaitBarrier(MemoryResource):
    """Wait side of CUDA Programmatic Dependent Launch (PDL).

    A barrier-only resource (``is_barrier=True``, no ``PipelineConfig``)
    whose single user-facing method, :meth:`wait_griddep`, emits a
    ``griddepcontrol.wait`` PTX instruction.  The instruction blocks the
    issuing thread until the direct predecessor grid dependency has completed
    and made its global-memory results visible.

    Wiring contract
    ---------------
    Any TS resource whose data is sourced from the predecessor grid
    (e.g. SMEM-A loaded via TMA, GMEM-A read directly, DSMEM-A copied from
    a peer CTA) declares the dependency by listing ``pdl_wait`` as one of
    that resource's upstreams in ``TaskManager.resource_dependency_graph``,
    e.g. ``resource_dependency_graph[smem_a] = [pdl_wait, ...]``.  Because
    ``PdlWaitBarrier`` has ``is_barrier=True``, the verifier interprets the
    edge as *ordering-only*: no consumer/producer variable copy plan is set
    up, but it does require the schedule entry that emits the wait to precede
    the producer entries of any task that produces the dependent resource.

    The ``wait_griddep`` entry may sit in any phase (Head, Loop with
    ``LoopFirstIter`` / ``LoopLastIter`` guards, Tail, post-WTL).

    Encouraged pattern
    ------------------
    The encouraged pattern is **inline wait**: every task that produces a
    PDL-dependent resource issues its own ``pdl_wait.wait_griddep()`` call.

    See also
    --------
    :class:`PdlLaunchBarrier` for the corresponding ``launch_dependents``
    side.
    """

    is_barrier: cutlass.Constexpr[bool] = True

    @consumer_work
    @cute.jit
    def wait_griddep(self, stage_info: StageInfo) -> None:
        prims.griddepcontrol(kind=prims.GridDepAction.WAIT)


@dataclass(kw_only=True)
class PdlLaunchBarrier(MemoryResource):
    """Launch-dependents side of CUDA Programmatic Dependent Launch (PDL).

    A barrier-only resource (``is_barrier=True``, no ``PipelineConfig``)
    whose single user-facing method, :meth:`launch_griddep`, emits a
    ``griddepcontrol.launch_dependents`` PTX instruction.  The instruction
    notifies the successor grid that it may begin launching CTAs.

    Wiring contract
    ---------------
    A ``PdlLaunchBarrier`` carries no data dependency: it does **not**
    appear on the consumer side of any data flow.  Therefore it is not
    expected as a destination in ``resource_dependency_graph``.  The
    verifier treats ``launch_griddep`` entries as schedule-only emissions
    that may sit in any task and any phase. The exhaustive interleaving
    checker still requires every executable launch interleaving to have
    already executed at least one ``PdlWaitBarrier.wait_griddep``.

    No global "at least one launch" rule is enforced — a kernel may
    legitimately omit launch (e.g. when it is the last grid in a pipeline
    chain or launch is gated by a non-PDL host policy).

    See also
    --------
    :class:`PdlWaitBarrier` for the corresponding ``wait`` side.
    """

    is_barrier: cutlass.Constexpr[bool] = True

    @producer_work
    @cute.jit
    def launch_griddep(self, stage_info: StageInfo) -> None:
        prims.griddepcontrol(kind=prims.GridDepAction.LAUNCH_DEPENDENTS)


PDL_BARRIER_TYPES: tuple = (
    PdlWaitBarrier,
    PdlLaunchBarrier,
)
"""Tuple of all PDL barrier classes for ``isinstance`` checks.

Use this in framework code that needs to recognise any PDL-style barrier
regardless of whether it is the wait side (``PdlWaitBarrier``) or the
launch side (``PdlLaunchBarrier``).
"""


@dataclass(kw_only=True)
class WorkQueue(MemoryResource):
    """Resource that wraps a persistent tile scheduler.

    It participates in the schedule of every task:

    - **Static persistent mode** - Number of launched CTAs is exactly to fill 1
      wave of SMs. Work-tile indices are assigned statically to each CTA. It
      needs no dedicated scheduler warp.
      ``get_and_advance_work_tile`` calls ``advance_to_next_work`` directly.
    - **CLC dynamic persistent mode** - a dedicated scheduler warp acts
      as the producer, issuing work-tile fetch requests in ``fetch_work_tile``.
      Consumer tasks simply wait on the pipeline.

    In both modes, the consumer-side variable ``work_tile``
    (``WorkTileInfo``) carries the tile coordinates and validity flag
    that other resources read.

    Attributes
    ----------
    tile_scheduler : StaticPersistentTileScheduler or ClcDynamicPersistentTileScheduler
        Materialised scheduler, set by ``create()``.
    tile_scheduler_config : TileSchedulerConfig
        Descriptor selecting the scheduler type and parameters.
    """

    tile_scheduler: Optional[
        Union[StaticPersistentTileScheduler, ClcDynamicPersistentTileScheduler]
    ] = None
    tile_scheduler_config: cutlass.Constexpr[TileSchedulerConfig] = None  # type: ignore[assignment]
    work_tile: cutlass.Constexpr[TaskLocalVariable] = field(init=False)
    skip_work_tile: cutlass.Constexpr[TaskLocalVariable] = field(init=False)

    def __init__(
        self,
        tile_scheduler_config: TileSchedulerConfig,
        **kwargs: Any,
    ) -> None:
        super().__init__(**kwargs)
        self.tile_scheduler_config = tile_scheduler_config
        self.work_tile = TaskLocalVariable(
            dtype=WorkTileInfo,
            default=WorkTileInfo(
                (cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0)),
                cutlass.Boolean(False),
            ),
            docs="Current persistent-scheduler work tile.",
        )
        self.skip_work_tile = TaskLocalVariable(
            dtype=cutlass.Boolean,
            default=cutlass.Boolean(False),
            docs="Whether the current work tile should skip skippable work.",
        )

    def _tile_scheduler_class(self, name: str) -> Any:
        """Resolve the scheduler class that goes with ``tile_scheduler_params``.

        The params object and its scheduler are defined side by side (in
        ``cutlass.utils`` or in a user-provided copy such as the examples'
        ``helpers``), so take the class from the params' own module. Params
        from a module without the class fall back to ``cutlass.utils``'s
        ``StaticPersistentTileScheduler``; the deprecated ``cutlass.utils``
        Clc scheduler is never a fallback, since DSL code does not use
        deprecated APIs.
        """
        params = self.tile_scheduler_config.tile_scheduler_params
        params_module = sys.modules.get(type(params).__module__)
        scheduler_class = getattr(params_module, name, None)
        if scheduler_class is None and name == "StaticPersistentTileScheduler":
            scheduler_class = StaticPersistentTileScheduler
        if scheduler_class is None:
            raise TypeError(
                f"{type(params).__name__} comes from a module that does not "
                f"define {name}; pass tile scheduler params from the module "
                f"that defines {name}, such as the examples' helpers."
            )
        return scheduler_class

    def create_tile_scheduler(
        self,
    ) -> "StaticPersistentTileScheduler | ClcDynamicPersistentTileScheduler":
        """Instantiate the concrete tile scheduler from ``tile_scheduler_config``."""
        if (
            self.tile_scheduler_config.tile_scheduler_type
            == TileSchedulerType.StaticPersistent
        ):
            return self._tile_scheduler_class("StaticPersistentTileScheduler").create(
                self.tile_scheduler_config.tile_scheduler_params,
                cute.arch.block_idx(),
                cute.arch.grid_dim(),
            )
        elif (
            self.tile_scheduler_config.tile_scheduler_type
            == TileSchedulerType.ClcDynamicPersistent
        ):
            return self._tile_scheduler_class(
                "ClcDynamicPersistentTileScheduler"
            ).create(
                self.tile_scheduler_config.tile_scheduler_params,
                cute.arch.block_idx(),
                cute.arch.grid_dim(),
                self.tile_scheduler_config.response_ptr,
            )
        else:
            raise ValueError(
                f"Invalid tile scheduler type: "
                f"{self.tile_scheduler_config.tile_scheduler_type}"
            )

    def create(self) -> None:
        """Create the pipeline (from base class) and the tile scheduler."""
        super().create()
        self.tile_scheduler = self.create_tile_scheduler()

    @staticmethod
    @cute.jit
    def _as_ts_work_tile(work_tile: Any) -> WorkTileInfo:
        """Re-wrap a scheduler-produced tile as TS's scalarized ``WorkTileInfo``.

        The scheduler may come from outside ``cutlass.utils`` (see
        ``_tile_scheduler_class``) and then hands back its own work-tile type.
        TS loop-carries the tile through staged control flow and relies on the
        scalarized TS-local ``WorkTileInfo``, so only ever carry that.
        """
        return WorkTileInfo(work_tile.tile_idx, work_tile.is_valid_tile)

    @cute.jit
    def _make_initial_work_tile(self) -> WorkTileInfo:
        assert self.tile_scheduler is not None
        return self._as_ts_work_tile(self.tile_scheduler.initial_work_tile_info())

    @cute.jit
    def initial_work_tile_info(self) -> WorkTileInfo:
        """Return the initial work tile from the underlying scheduler."""
        return self._make_initial_work_tile()

    @consumer_work(
        work_attrs=WorkAttr.AUXILIARY, returns=("work_tile", "skip_work_tile")
    )
    @cute.jit
    def init_work_tile(
        self,
        stage_info: StageInfo,
    ) -> tuple[WorkTileInfo, "cutlass.Boolean"]:
        """Seed the persistent loop state before the first work tile."""
        del stage_info
        tile_scheduler = object.__getattribute__(self, "tile_scheduler")
        if cutlass.const_expr(tile_scheduler is not None):
            initial_work_tile = self.initial_work_tile_info()
        else:
            initial_work_tile = WorkTileInfo(
                (cutlass.Int32(0), cutlass.Int32(0), cutlass.Int32(0)),
                cutlass.Boolean(False),
            )
        return initial_work_tile, cutlass.Boolean(False)

    @cute.jit
    def _get_and_advance_work_tile_impl(
        self,
        stage_info: StageInfo,
    ) -> WorkTileInfo:
        """Advance to the next work tile and update ``work_tile``.

        For the **static persistent** scheduler there is no dedicated
        scheduler warp, so ``advance_to_next_work`` is called here on the
        consumer side.  This is slightly counter-intuitive but allows
        every task to use the same three-stage tail pattern:

            (work_queue, ScheduleStage.ConsumerTryWait,    ScheduleStageType.Tail),
            (work_queue, ScheduleStage.ConsumerWait,    ScheduleStageType.Tail),
            (work_queue, ScheduleStage.ConsumerWork,    ScheduleStageType.Tail,
             "get_and_advance_work_tile"),
            (work_queue, ScheduleStage.ConsumerRelease, ScheduleStageType.Tail),

        regardless of whether the scheduler is static or dynamic.

        For the **CLC dynamic** scheduler, advancing is handled by the
        producer warp (``fetch_work_tile``), so nothing extra is done here.
        The consumer reads from the per-stage response buffer to support
        multi-stage work queues.
        """
        if cutlass.const_expr(
            self.tile_scheduler_config.tile_scheduler_type
            == TileSchedulerType.StaticPersistent
        ):
            assert self.tile_scheduler is not None
            self.tile_scheduler.advance_to_next_work()
            work_tile = self._as_ts_work_tile(self.tile_scheduler.get_current_work())
        else:
            # CLC dynamic: read from the per-stage response buffer.
            stage_response_ptr = self._get_stage_response_ptr(stage_info.stage_idx)
            work_tile = self._work_tile_info_from_clc_response(stage_response_ptr)
        return work_tile

    @consumer_work(returns=("work_tile",))
    @cute.jit
    def get_and_advance_work_tile(
        self,
        stage_info: StageInfo,
    ) -> WorkTileInfo:
        """Typed-schedule work-tile advance callback."""
        return self._get_and_advance_work_tile_impl(stage_info)

    def _clc_scheduler(self) -> Any:
        """The CLC scheduler in use; only valid in ``ClcDynamicPersistent`` mode.

        Typed ``Any`` on purpose: the concrete class is whatever
        ``_tile_scheduler_class`` resolved, not necessarily the ``cutlass.utils``
        one, so only the CLC duck-type (``_clc_response_ptr``,
        ``_swizzle_and_rasterize``, ``_num_tiles_executed``) is relied on.
        """
        assert (
            self.tile_scheduler_config.tile_scheduler_type
            == TileSchedulerType.ClcDynamicPersistent
        )
        assert self.tile_scheduler is not None
        return self.tile_scheduler

    @cute.jit
    def _get_stage_response_ptr(self, stage_idx: int) -> cute.Pointer:
        """Compute the CLC response pointer for a given pipeline stage.

        With multi-stage work queues, each stage has its own 16-byte
        response buffer.  The base ``_clc_response_ptr`` points to stage 0;
        subsequent stages are offset by one Int128 response record each.
        """
        assert self.pipeline_config is not None
        tile_scheduler = self._clc_scheduler()
        if cutlass.const_expr(self.pipeline_config.num_stages == 1):
            return tile_scheduler._clc_response_ptr
        return tile_scheduler._clc_response_ptr + stage_idx

    @cute.jit
    def _decode_clc_response(
        self, response_ptr: cute.Pointer
    ) -> tuple[Any, Any, Any, Any]:
        """Decode a CLC response with the hardware query instructions.

        The 16-byte response produced by clusterlaunchcontrol is opaque.  Its
        CTA coordinates and validity bit must be read through the query_cancel
        instructions, matching CUTLASS/TRT-LLM's scheduler helper.
        """
        m_idx, n_idx, l_idx, is_valid_i32 = cute.arch.clc_response(response_ptr)
        if cutlass.const_expr(getattr(self.tile_scheduler, "insert_fence", True)):
            cute.arch.fence_view_async_shared()
        return m_idx, n_idx, l_idx, is_valid_i32 != cutlass.Int32(0)

    @cute.jit
    def _work_tile_info_from_clc_response(
        self, response_ptr: cute.Pointer
    ) -> WorkTileInfo:
        """Read and rasterize one CLC response without querying invalid ids."""
        m_idx, n_idx, l_idx, is_valid = self._decode_clc_response(response_ptr)

        tile_scheduler = self._clc_scheduler()
        m_idx, n_idx, l_idx = tile_scheduler._swizzle_and_rasterize(
            m_idx,
            n_idx,
            l_idx,
        )
        cta_idx_in_cluster, cta_idy_in_cluster, _ = tile_scheduler.cta_id_in_cluster
        return WorkTileInfo(
            (
                m_idx + cta_idx_in_cluster,
                n_idx + cta_idy_in_cluster,
                l_idx,
            ),
            is_valid,
        )

    @cute.jit
    def _fetch_work_tile_impl(self, stage_info: StageInfo) -> None:
        """Issue a CLC tile-fetch request (CLC dynamic mode only).

        Only CTA 0 in the cluster triggers the CLC fetch; the hardware
        writes the response into the per-stage SMEM buffer and signals
        the pipeline mbarrier.
        """
        if cutlass.const_expr(
            self.tile_scheduler_config.tile_scheduler_type
            == TileSchedulerType.ClcDynamicPersistent
        ):
            cta_rank_in_cluster = cute.arch.make_warp_uniform(
                cute.arch.block_idx_in_cluster()
            )
            if cta_rank_in_cluster == 0:
                mbarrier_addr = self.pipeline.producer_get_barrier(self.producer_state)
                stage_response_ptr = self._get_stage_response_ptr(stage_info.stage_idx)
                # Inline the CLC query from advance_to_next_work.
                # The counter increment is hoisted below, outside this
                # conditional, to avoid an SSA dominance violation:
                # a void scf.if traps the updated value inside the
                # then-block, making it invisible to the outer yield.
                with cute.arch.elect_one():
                    cute.arch.issue_clc_query(mbarrier_addr, stage_response_ptr)
            # Counter must live outside the dynamic conditional so the
            # new SSA value dominates the enclosing scf.yield.
            self._clc_scheduler()._num_tiles_executed += cutlass.Int32(1)

    @producer_work
    @cute.jit
    def fetch_work_tile(
        self,
        stage_info: StageInfo,
    ) -> None:
        """Typed-schedule work-tile fetch callback.

        Takes no routed input: the current work tile is supplied by the
        persistent-loop machinery through ``stage_info``, so schedules call
        ``wq.fetch_work_tile()`` directly.
        """
        self._fetch_work_tile_impl(stage_info)

    @cute.jit
    def producer_tail(self) -> None:
        """Drain in-flight pipeline stages after the persistent loop exits."""
        if cutlass.const_expr(self.pipeline_config is not None):
            assert self.pipeline_config is not None
            if cutlass.const_expr(
                self.pipeline_config.pipeline_type == PipelineType.ClcFetchAsync
            ):
                return
            self.pipeline.producer_tail(self.producer_state)


# PipelineGroup and _GroupMemberRef live in ``pipeline_group`` but are
# re-exported here lazily for backward compatibility. Importing them eagerly
# creates a cycle: ``pipeline_group`` imports ``MemoryResource`` /
# ``PipelineConfig`` from this module before it finishes loading.
def __getattr__(name: str) -> Any:
    if name in {"PipelineGroup", "_GroupMemberRef"}:
        from .pipeline_group import PipelineGroup, _GroupMemberRef

        return {
            "PipelineGroup": PipelineGroup,
            "_GroupMemberRef": _GroupMemberRef,
        }[name]
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
