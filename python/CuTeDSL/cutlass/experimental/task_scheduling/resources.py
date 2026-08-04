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
      - per-role variable dicts (``consumer_vars``, ``producer_vars``),
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
      states, status flags, and task-local storage defaults. Executed once per
      kernel invocation, outside any dynamic control flow.
    * ``resource.create_consumer_variables_internal()`` /
      ``resource.create_producer_variables_internal()`` populates
      ``consumer_vars`` / ``producer_vars`` dicts with the user-defined
      variables that flow between resources.
    * ``consumer_work(stage_info)`` / ``producer_work(stage_info)`` runs
      user-defined per-stage logic invoked by the ``Task`` schedule.
    * ``copy_consumer_vars_to(dst_resource)`` propagates matching consumer
      variables into a downstream resource's producer variables. This is
      automatic and called by ``Task``.
"""

from collections.abc import Callable, Mapping
from dataclasses import MISSING, Field, dataclass, field, fields, is_dataclass
import ast
import difflib
import functools
import inspect
import textwrap
import cutlass.pipeline as pipeline
import cutlass.cute as cute
import cutlass
from cutlass.experimental import primitives as prims
from typing import (
    ClassVar,
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
import cutlass.utils.static_persistent_tile_scheduler as _static_persistent_tile_scheduler
from cutlass.utils.static_persistent_tile_scheduler import (
    WorkTileInfo,
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
    ScheduleStageType,
    TileSchedulerType,
    SignalingThreads,
    WorkAttr,
)
from . import pipeline as ts_pipeline

if TYPE_CHECKING:
    from .pipeline_group import PipelineGroup


# TS loop-carries ``WorkTileInfo`` through staged persistent control flow and
# advances it in tail schedule entries.  The upstream implementation stores
# ``tile_idx`` as one tuple field, which makes in-place updates fail IR
# dominance checks in nested dynamic regions. Keep the public CUTLASS type but
# scalarize its runtime representation while this module is loaded.
@cute.jit
def _work_tile_info_init_scalar(
    self: WorkTileInfo, tile_idx: cute.Coord, is_valid_tile: cutlass.Boolean
) -> None:
    m_idx, n_idx, l_idx = tile_idx  # type: ignore[misc]
    self._m_idx = cutlass.Int32(m_idx)  # type: ignore[attr-defined]
    self._n_idx = cutlass.Int32(n_idx)  # type: ignore[attr-defined]
    self._l_idx = cutlass.Int32(l_idx)  # type: ignore[attr-defined]
    self._is_valid_tile = cutlass.Boolean(is_valid_tile)


def _work_tile_info_extract_scalar(self: WorkTileInfo) -> list:
    return [
        self._m_idx.ir_value(),  # type: ignore[attr-defined]
        self._n_idx.ir_value(),  # type: ignore[attr-defined]
        self._l_idx.ir_value(),  # type: ignore[attr-defined]
        self._is_valid_tile.ir_value(),
    ]


def _work_tile_info_new_from_mlir_values_scalar(
    self: WorkTileInfo, values: list
) -> WorkTileInfo:
    assert len(values) == 4
    return WorkTileInfo(
        (
            cutlass.Int32(values[0]),
            cutlass.Int32(values[1]),
            cutlass.Int32(values[2]),
        ),
        cutlass.Boolean(values[3]),
    )


@cute.jit
def _work_tile_info_tile_idx_scalar(self: WorkTileInfo) -> cute.Coord:
    return (self._m_idx, self._n_idx, self._l_idx)  # type: ignore[attr-defined]


@cute.jit
def _work_tile_info_is_valid_tile_scalar(self: WorkTileInfo) -> cutlass.Boolean:
    return self._is_valid_tile


@cute.jit
def _work_tile_info_update_from_scalar(self: WorkTileInfo, other: WorkTileInfo) -> None:
    m_idx, n_idx, l_idx = other.tile_idx
    self._m_idx = cutlass.Int32(m_idx)  # type: ignore[attr-defined]
    self._n_idx = cutlass.Int32(n_idx)  # type: ignore[attr-defined]
    self._l_idx = cutlass.Int32(l_idx)  # type: ignore[attr-defined]
    self._is_valid_tile = cutlass.Boolean(other.is_valid_tile)


WorkTileInfo.__init__ = _work_tile_info_init_scalar  # type: ignore[method-assign]
WorkTileInfo.__extract_mlir_values__ = _work_tile_info_extract_scalar  # type: ignore[method-assign]
WorkTileInfo.__new_from_mlir_values__ = _work_tile_info_new_from_mlir_values_scalar  # type: ignore[method-assign]
WorkTileInfo.tile_idx = property(_work_tile_info_tile_idx_scalar)  # type: ignore[method-assign]
WorkTileInfo.is_valid_tile = property(_work_tile_info_is_valid_tile_scalar)  # type: ignore[method-assign]
WorkTileInfo.update_from = _work_tile_info_update_from_scalar  # type: ignore[attr-defined]

# The scalarized methods are installed on CUTLASS' WorkTileInfo class.  Some
# IR reconstruction paths resolve patched class methods in the owner module's
# globals rather than this module's globals; make the CuTe name used by the
# patches available there too.
_static_persistent_tile_scheduler.cute = cute

# Variable-flow model
# -------------------
# Consumer and producer variables are *not* freshly created by consumer/producer
# work functions.  ``create_consumer_variables`` / ``create_producer_variables``
# allocate the storage once; consumer work functions *mutate* the existing
# variables in place, and producer work reads the mutated values via
# ``get_producer_var``.  The ``SlotRouting`` table below controls which
# mutated consumer vars are copied to which downstream producer/consumer vars
# between schedule steps.
#
# Slot-to-slot variable-flow routing table — the single source of truth
# for how local task variables propagate between schedule entries.
#
# A "slot" is one schedule item, uniquely identified by
# ``(resource_id, stage, stage_type, call_idx)`` where ``call_idx`` is
# the 0-based ordinal of schedule items with that
# ``(resource, stage, stage_type)`` tuple inside one schedule section.
#
# Each key of ``SlotRouting`` is a *writer* slot (ConsumerAuxWork or ConsumerWork on the
# consumer side of one of the task's ``src_resources``).  Its value is a list of
# ``(var_routes, destinations)`` pairs: the writer forwards each named
# variable (read from its resource's
# ``consumer_vars``) to every destination in ``destinations``.  A route
# may be either ``"name"`` for same-name copy or
# ``("src_name", "dst_name")`` for explicit source-to-destination
# copy.  Each destination is a
# ``(dst_resource, dst_stage, dst_stage_type, dst_call_idx)`` tuple.
#
# Allowed stage placements:
#   - Writer stage ∈ { ConsumerAuxWork, ConsumerWork }
#     on a resource in the task's ``src_resources``.
#   - Producer-side destination: ``dst_stage`` ∈
#     { ProducerAuxWork, ProducerWork }
#     on a resource in ``dst_resources`` (written into
#     ``dst_resource.producer_vars``).
#   - Consumer-side destination: ``dst_stage`` ∈
#     { ConsumerAuxWork, ConsumerWork }
#     on a resource in ``src_resources`` (written into
#     ``dst_resource.consumer_vars``).
#
# At runtime, when a writer slot executes, it invokes the appropriate
# ``copy_consumer_vars_to`` / ``copy_consumer_vars_to_consumer_of``
# helper for each destination listed here.  Variables not mentioned in
# any routing entry are not propagated at all (no copy) — the routing
# table *is* the copy plan.
#
# Build-time validation (``TaskManager._verify_slot_routing``):
#   1. Stage legality, call-idx range, and non-empty route/destination
#      lists for every writer and every destination.  A route must be
#      either a non-empty string or a ``(src_name, dst_name)`` pair of
#      non-empty strings; one reader destination var cannot receive
#      multiple source vars.
#   2. Schedule ordering: the writer must run *linearly* before the
#      reader in the combined schedule (head + loop body + tail) —
#      writer's schedule position < reader's schedule position.
#      Loop-carry across iteration boundaries is **not** modelled: a
#      body reader whose only writer is later in the body is rejected.
#      To feed iteration 0, add a head writer of the same variable.
#   3. Most-recent-writer consistency: for every (reader, source
#      variable, destination variable) route, the routing must match
#      what a linear matcher would produce from the back-derived
#      per-slot write/read sets — so a later writer of the same source
#      variable cannot silently overwrite an earlier routing edge.
#      Edges that violate this rule are
#      rejected so the runtime copy plan is always conflict-free.
#
# Example for a GEMM load task (gmem tile coords feed the TMA load):
#   slot_routing = {
#       (id(gmem_ab), ScheduleStage.ConsumerWork, ScheduleStageType.Loop, 0): [
#           (
#               ["coord_k", ("coord_m_src", "coord_m"), "coord_n"],
#               [(smem_ab, ScheduleStage.ProducerWork, ScheduleStageType.Loop, 0)],
#           ),
#       ],
#   }
VarRoute = str | tuple[str, str]
SlotRouting = dict[
    tuple[int, ScheduleStage, ScheduleStageType, int],
    list[
        tuple[
            Optional[list[VarRoute]],
            list[tuple["MemoryResource", ScheduleStage, ScheduleStageType, int]],
        ]
    ],
]
InterleaveStride: TypeAlias = int | tuple[int, int, int, int]


_TS_MANAGES_CAPTURE_CONTEXT_ATTR = "_ts_manages_schedule_capture_context"


@dataclass(frozen=True)
class _CapturedScheduleAccessContext:
    """User hook currently protected by captured-schedule var access rules."""

    hook_name: str


class _CapturedScheduleExecutionGuard:
    """Temporarily mark a resource call as driven by a captured schedule."""

    def __init__(self, resource: "MemoryResource", enabled: bool) -> None:
        self.resource = resource
        self.enabled = enabled
        self.previous_depth = 0

    def __enter__(self) -> None:
        if not self.enabled:
            return
        self.previous_depth = object.__getattribute__(
            self.resource, "_ts_captured_schedule_depth"
        )
        object.__setattr__(
            self.resource,
            "_ts_captured_schedule_depth",
            self.previous_depth + 1,
        )

    def __exit__(self, exc_type: object, exc: object, tb: object) -> None:
        if not self.enabled:
            return
        object.__setattr__(
            self.resource, "_ts_captured_schedule_depth", self.previous_depth
        )


class _CapturedScheduleUserHookGuard:
    """Disallow raw producer/consumer-var state access inside user hook code."""

    def __init__(
        self, resource: "MemoryResource", hook_name: str, enabled: bool
    ) -> None:
        self.resource = resource
        self.context = _CapturedScheduleAccessContext(hook_name=hook_name)
        self.enabled = enabled
        self.previous_context: _CapturedScheduleAccessContext | None = None

    def __enter__(self) -> None:
        if not self.enabled:
            return
        self.previous_context = object.__getattribute__(
            self.resource, "_ts_captured_schedule_access_context"
        )
        object.__setattr__(
            self.resource,
            "_ts_captured_schedule_access_context",
            self.context,
        )

    def __exit__(self, exc_type: object, exc: object, tb: object) -> None:
        if not self.enabled:
            return
        object.__setattr__(
            self.resource,
            "_ts_captured_schedule_access_context",
            self.previous_context,
        )


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

    @staticmethod
    def create_async_async_pipeline_cfg(
        num_stages: int,
        producer_group: pipeline.CooperativeGroup,
        consumer_group: pipeline.CooperativeGroup,
        cta_layout_vmnk: cute.Layout,
        producer_signaling_threads: SignalingThreads = SignalingThreads.All,
        consumer_signaling_threads: SignalingThreads = SignalingThreads.All,
        barrier_ptr: Optional[cute.Pointer] = None,
        producer_op: pipeline.PipelineOp = pipeline.PipelineOp.AsyncThread,
        advance_on_acquire: bool = False,
        interleave_stride: InterleaveStride = 1,
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
            advance_on_acquire=advance_on_acquire,
            interleave_stride=interleave_stride,
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
        interleave_stride: InterleaveStride = 1,
        num_bytes_per_warp_per_cta: Optional[int] = None,
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
        interleave_stride : int or tuple[int, int, int, int], optional
            Role-specific pipeline-state stride.  Mismatched opening and
            closing roles require the corresponding advance flag.
        num_bytes_per_warp_per_cta : int, optional
            Per-producer-warp, per-CTA transaction byte count for leader-routed
            clustered TMA completion validation.

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
            interleave_stride=interleave_stride,
            num_bytes_per_warp_per_cta=num_bytes_per_warp_per_cta,
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


@dataclass(frozen=True)
class StageInfo:
    """Read-only context passed to ``producer_work`` / ``consumer_work``.

    Attributes
    ----------
    loop_offset : int
        Current iteration index within the K-tile loop over the  computational domain.
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

        ``None`` when no label is specified (backward-compatible default).
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
    task_cache : object or None
        Optional task-defined payload returned by ``Task.make_task_cache()``.
        This is intended for kernel-specific cached values that hot resource
        paths want to read without widening ``StageInfo`` field-by-field.
        The payload shape is task-defined and should remain fixed per task
        class.
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
    task_cache: object = None


_TASK_LOCAL_VARIABLE_VALUE_MISSING = object()
_TS_TASK_LOCAL_VARIABLES_ATTR = "_ts_task_local_variables"


_TS_FIELD_METADATA_NAMESPACE = "ts"


@dataclass(eq=False)
class TaskLocalVariable:
    """Metadata for one resource-owned variable in captured TS schedules.

    A ``TaskLocalVariable`` is the public identity of a logical variable owned by
    a ``MemoryResource``. In generated code it materializes as task-local
    register state, with consumer work calls producing new
    versions of that register value. The current implementation still lowers
    through string-named ``consumer_vars`` / ``producer_vars`` slots, but
    schedule code should carry ``TaskLocalVariable`` identities rather than
    naming those internal dictionaries directly.

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
        """Stable resource field name used for legacy slot lowering."""
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


def _initialize_task_local_variable_from_ts(
    variable: TaskLocalVariable,
    value: object = _TASK_LOCAL_VARIABLE_VALUE_MISSING,
) -> None:
    """Populate one task-local runtime slot from TS internals."""
    if value is _TASK_LOCAL_VARIABLE_VALUE_MISSING:
        value = (
            variable.default_factory()
            if variable.default_factory is not None
            else variable.default
        )
    if variable.owner is None or variable.field_name is None:
        raise ValueError("Cannot initialize an unbound TaskLocalVariable.")
    slot_name = variable.slot_name
    if slot_name is None:
        raise ValueError("Cannot initialize a TaskLocalVariable without a slot name.")
    setter = getattr(variable.owner, "_set_consumer_var_from_ts", None)
    if setter is None:
        raise TypeError("TaskLocalVariable requires an owning MemoryResource.")
    setter(slot_name, value)


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
    """Expose task-local dataclass fields as class-level field references."""

    def __getattr__(cls, name: str) -> Field:
        dataclass_field = _task_local_variable_field_on_class(cls, name)
        if dataclass_field is not None:
            return dataclass_field
        raise AttributeError(name)


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


def _is_internal_tree_flatten_access() -> bool:
    """Return true when DSL dataclass flattening is reading resource metadata."""
    frame = inspect.currentframe()
    for _ in range(12):
        if frame is None:
            return False
        frame = frame.f_back
        if frame is None:
            return False
        code = frame.f_code
        if code.co_filename.endswith("tree_utils.py") and code.co_name in {
            "extract_dataclass_members",
            "default_dataclass_to_iterable",
            "_tree_flatten",
            "tree_flatten",
        }:
            return True
    return False


# ---------------------------------------------------------------------------
# Named work function decorators
# ---------------------------------------------------------------------------

_CONSUMER_WORK_FNS_ATTR = "_named_consumer_work_fns"
_PRODUCER_WORK_FNS_ATTR = "_named_producer_work_fns"


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


def _reject_consumer_return_dict_static(
    fn: Callable[..., Any], method_name: str
) -> None:
    """Reject literal dict returns from consumer work at decoration time.

    Source retrieval is best-effort, so dynamic dict construction still falls
    through to the runtime wrapper check.
    """
    try:
        # ``@consumer_work`` typically decorates a ``@cute.jit``-wrapped
        # method; ``inspect.unwrap`` follows ``__wrapped__`` to recover the
        # original function whose source we want to scan.
        original = inspect.unwrap(fn)
        source_lines, _ = inspect.getsourcelines(original)
        tree = ast.parse(textwrap.dedent("".join(source_lines)))
    except (OSError, TypeError, SyntaxError):
        return
    for node in ast.walk(tree):
        if not (isinstance(node, ast.Return) and isinstance(node.value, ast.Dict)):
            continue
        raise ValueError(
            f"@consumer_work on `{method_name}`: consumer work must not "
            "return a dict. Return a single value or a tuple of values "
            "matching the captured schedule TaskLocalVariable assignment."
        )


def _normalize_consumer_work_result_values(
    result: object,
    method_name: str,
) -> tuple[object, ...]:
    """Convert a consumer-work return value into positional output values."""
    if isinstance(result, dict):
        raise TypeError(
            f"@consumer_work '{method_name}' returned dict; consumer work "
            "must return a single value or a tuple of values matching the "
            "captured schedule TaskLocalVariable assignment."
        )
    if result is None:
        return ()
    if isinstance(result, tuple):
        return result
    return (result,)


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


def _task_local_variable_names_for_error(resource: object) -> str:
    """Return a deterministic list of available TaskLocalVariable slot names."""
    names: list[str] = []
    for variable in get_task_local_variables(resource):
        name = variable.slot_name
        if name is not None and name not in names:
            names.append(name)
    if not names:
        return "<none>"
    return ", ".join(repr(name) for name in names)


def _format_annotation_name(annotation: object) -> str:
    """Return a compact user-facing name for a resource field annotation."""
    if isinstance(annotation, str):
        return annotation
    return getattr(annotation, "__name__", repr(annotation))


def _task_local_variable_member_mismatch_for_error(
    resource: object,
    name: str,
) -> str | None:
    """Describe a same-named resource member that is not a TaskLocalVariable."""
    if is_dataclass(resource):
        for dataclass_field in fields(resource):
            if dataclass_field.name != name:
                continue
            annotation = _format_annotation_name(dataclass_field.type)
            try:
                value = object.__getattribute__(resource, name)
            except AttributeError:
                return (
                    f"{type(resource).__name__}.{name} is declared as "
                    f"{annotation}, not TaskLocalVariable, and was not "
                    "initialized as a TaskLocalVariable"
                )
            if not isinstance(value, TaskLocalVariable):
                return (
                    f"{type(resource).__name__}.{name} is declared as "
                    f"{annotation} and contains {type(value).__name__}, "
                    "not TaskLocalVariable"
                )
            return None

    for cls in type(resource).__mro__:
        raw_annotation = getattr(cls, "__annotations__", {}).get(name)
        if raw_annotation is None:
            continue
        try:
            value = object.__getattribute__(resource, name)
        except AttributeError:
            return (
                f"{type(resource).__name__}.{name} is declared as "
                f"{_format_annotation_name(raw_annotation)}, not TaskLocalVariable, "
                "and was not initialized as a TaskLocalVariable"
            )
        if not isinstance(value, TaskLocalVariable):
            return (
                f"{type(resource).__name__}.{name} is declared as "
                f"{_format_annotation_name(raw_annotation)} and contains "
                f"{type(value).__name__}, not TaskLocalVariable"
            )
        return None

    try:
        value = object.__getattribute__(resource, name)
    except AttributeError:
        return None
    if isinstance(value, TaskLocalVariable):
        return None
    return (
        f"{type(resource).__name__}.{name} exists with type "
        f"{type(value).__name__}, not TaskLocalVariable"
    )


def _task_local_variables_for_output_names(
    resource: object,
    method_name: str,
    output_names: tuple[str, ...],
) -> tuple[TaskLocalVariable, ...]:
    """Resolve declared output names to resource-owned TaskLocalVariables."""
    variables_by_name: dict[str, TaskLocalVariable] = {}
    for variable in get_task_local_variables(resource):
        name = variable.slot_name
        if name is None:
            continue
        if name in variables_by_name and variables_by_name[name] is not variable:
            raise ValueError(
                f"@consumer_work '{method_name}' cannot resolve "
                f"TaskLocalVariable output '{name}' because resource "
                f"{type(resource).__name__} declares that slot more than once."
            )
        variables_by_name[name] = variable

    variables: list[TaskLocalVariable] = []
    for name in output_names:
        resolved = variables_by_name.get(name)
        if resolved is None:
            mismatch = _task_local_variable_member_mismatch_for_error(resource, name)
            if mismatch is not None:
                raise ValueError(
                    f"@consumer_work '{method_name}' declares "
                    f"returns={name!r}, but {mismatch}. "
                    "Decorator return names must identify TaskLocalVariable "
                    "fields."
                )
            raise ValueError(
                f"@consumer_work '{method_name}' declares returns={name!r}, "
                f"but {type(resource).__name__} has no TaskLocalVariable named "
                f"{name!r}. Valid TaskLocalVariable names: "
                f"{_task_local_variable_names_for_error(resource)}."
            )
        variables.append(resolved)
    return tuple(variables)


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


def consumer_work(
    method: Callable[..., Any] | None = None,
    *,
    work_attrs: WorkAttr = WorkAttr.NONE,
    returns: str | Field | tuple[str | Field, ...] | list[str | Field] | None = None,
) -> Callable[..., Any]:
    """Register a method as a named consumer work function on a ``MemoryResource``.

    Consumer work reads data out of the owning ``MemoryResource`` from the
    resource's point of view.  The decorator registers the method under its
    Python name, which is also the raw ``schedule_list`` label.

    Parameters
    ----------
    method : Callable, optional
        Method being decorated.  Omitted when using decorator-factory form.
    work_attrs : cutlass.experimental.task_scheduling.enums.WorkAttr, optional
        Verification-visible attributes for the work callback.  Use
        ``WorkAttr.AUXILIARY`` for helper work that carries no data payload.
    returns : str or dataclasses.Field or sequence, optional
        ``TaskLocalVariable`` output slot or slots updated by this consumer.
        Field references must point at fields declared with
        ``TaskLocalVariable.uninitialized()``.

    Returns
    -------
    Callable
        Decorated method or decorator factory.

    Notes
    -----
    Captured schedules pass returned values as data-flow tokens.  A typical
    method declaration is::

        item: TaskLocalVariable = TaskLocalVariable.uninitialized()

        @consumer_work(returns=item)
        @cute.jit
        def load(self, stage_info):
            return self.tensor[stage_info.loop_offset]

    When a raw schedule list is used and a resource has multiple named
    consumer methods, the label is the final tuple element, for example
    ``(smem, ScheduleStage.ConsumerWork, "build_desc_a")``.
    """
    # Factory form (called with parens, ``method`` arrives as ``None``)
    # is stamped so ``_discover_consumer_var_names`` can distinguish it
    # from the bare decorator when needed.
    is_factory_form = method is None

    normalized_work_attrs = _normalize_work_attrs(
        work_attrs,
        decorator_name="@consumer_work",
    )
    normalized_returns = _normalize_consumer_returns(returns)
    consumer_stage = _consumer_stage_from_work_attrs(normalized_work_attrs)

    def decorator(fn: Callable[..., Any]) -> Callable[..., Any]:
        method_name = fn.__name__

        # Register the method name in the per-method registry.
        if not hasattr(fn, _CONSUMER_WORK_FNS_ATTR):
            setattr(fn, _CONSUMER_WORK_FNS_ATTR, {})
        getattr(fn, _CONSUMER_WORK_FNS_ATTR)[method_name] = method_name

        (
            kwarg_names,
            positional_arg_names,
            constexpr_arg_names,
            required_constexpr_arg_names,
        ) = _infer_work_arg_names(
            fn,
            "@consumer_work",
            "consumer inputs",
        )

        _reject_consumer_return_dict_static(fn, method_name)

        # Lazy resolver for the declared ``returns=`` entries.  Resolution
        # cannot happen at decoration time because ``Field.name`` is only
        # populated after ``@dataclass`` finishes processing the owning
        # class.  Defer to first read at schedule-build / dispatch time,
        # then cache via ``lru_cache``.
        if normalized_returns is None:
            _consumer_return_var_names = None
        else:

            @functools.lru_cache(maxsize=None)
            def _consumer_return_var_names() -> tuple[str, ...]:
                resolved: list[str] = []
                for entry in normalized_returns:
                    name = entry if isinstance(entry, str) else entry.name
                    if name is MISSING or not name:
                        raise RuntimeError(
                            f"@consumer_work '{method_name}': returns= "
                            "Field has no .name; ensure the owning class "
                            "is decorated with @dataclass."
                        )
                    if name in resolved:
                        raise ValueError(
                            f"@consumer_work '{method_name}': returns= "
                            "contains duplicate TaskLocalVariable name "
                            f"'{name}'."
                        )
                    resolved.append(name)
                return tuple(resolved)

        # Wrap to auto-inject consumer vars and publish returned values.
        @functools.wraps(fn)
        def wrapper(
            self: "MemoryResource", stage_info: StageInfo, **work_kwargs: Any
        ) -> Any:
            resolved_return_names: tuple[str, ...] | None = (
                None
                if _consumer_return_var_names is None
                else _consumer_return_var_names()
            )
            # Constexpr work-kwargs are supplied by the executor (captured at
            # schedule-build time) and forwarded verbatim to the work method;
            # ``**work_kwargs`` is empty for legacy / non-captured tasks.
            if kwarg_names:
                kwargs = {
                    name: self._get_consumer_var_from_ts(name) for name in kwarg_names
                }
                with self._ts_captured_schedule_user_hook(method_name):
                    result = fn(self, stage_info, **kwargs, **work_kwargs)
            else:
                with self._ts_captured_schedule_user_hook(method_name):
                    result = fn(self, stage_info, **work_kwargs)
            values = _normalize_consumer_work_result_values(result, method_name)
            output_names: tuple = ()
            if resolved_return_names is not None:
                output_names = resolved_return_names
            if not output_names and values:
                shared_names: list[str] = []
                for variable in get_task_local_variables(self):
                    name = variable.slot_name
                    if name is not None and name not in shared_names:
                        shared_names.append(name)
                if len(shared_names) == 1:
                    output_names = tuple(shared_names)
                elif shared_names:
                    raise TypeError(
                        f"@consumer_work '{method_name}' returned "
                        f"{len(values)} value(s), but there is no "
                        "captured schedule assignment metadata to select "
                        "which TaskLocalVariable output slot(s) to update."
                    )
            if output_names:
                if len(values) != len(output_names):
                    raise TypeError(
                        f"@consumer_work '{method_name}' returned "
                        f"{len(values)} value(s), but the captured schedule "
                        f"expects {len(output_names)} TaskLocalVariable output(s) "
                        f"{tuple(output_names)}."
                    )
                produced_variables = None
                if resolved_return_names is not None:
                    produced_variables = _task_local_variables_for_output_names(
                        self,
                        method_name,
                        output_names,
                    )
                for i, (name, value) in enumerate(zip(output_names, values)):
                    if produced_variables is not None:
                        variable = produced_variables[i]
                        _validate_consumer_produced_value_dtype(
                            method_name,
                            variable,
                            value,
                        )
                    self._set_consumer_var_from_ts(name, value)
            return result

        # Ensure the registration metadata survives wrapping.
        if not hasattr(wrapper, _CONSUMER_WORK_FNS_ATTR):
            setattr(wrapper, _CONSUMER_WORK_FNS_ATTR, {})
        getattr(wrapper, _CONSUMER_WORK_FNS_ATTR).update(
            getattr(fn, _CONSUMER_WORK_FNS_ATTR, {})
        )

        # Expose the routed (data-flow) input names so the schedule builder can
        # validate the number and identity of DataFlowTokens passed in
        # consumer-to-consumer routing.  Alongside the full list
        # (``_consumer_routed_names``), expose the positional and keyword-only
        # names split out so the builder can bind each group without re-deriving
        # it.  Constexpr params (``_consumer_constexpr_names``) are tracked
        # separately below: forwarded verbatim, never routed.
        if kwarg_names:
            setattr(wrapper, "_consumer_routed_names", kwarg_names)
            setattr(wrapper, "_consumer_routed_positional_names", positional_arg_names)
            setattr(
                wrapper,
                "_consumer_routed_keyword_names",
                tuple(n for n in kwarg_names if n not in positional_arg_names),
            )
        if constexpr_arg_names:
            setattr(wrapper, "_consumer_constexpr_names", constexpr_arg_names)
        if required_constexpr_arg_names:
            setattr(
                wrapper,
                "_consumer_required_constexpr_names",
                required_constexpr_arg_names,
            )
        if _consumer_return_var_names is not None:
            setattr(wrapper, "_consumer_return_var_names", _consumer_return_var_names)

        # Stamp factory-form wrappers so ``_discover_consumer_var_names``
        # can tell factory form apart from bare ``@consumer_work``.
        if is_factory_form:
            setattr(wrapper, "_is_consumer_work_factory", True)

        # Stage metadata consumed by schedule-builder/task dispatch.
        setattr(wrapper, "_consumer_work_attrs", normalized_work_attrs)
        setattr(wrapper, "_consumer_work_stage", consumer_stage)
        setattr(wrapper, _TS_MANAGES_CAPTURE_CONTEXT_ATTR, True)

        return wrapper

    if method is not None:
        # Bare decorator: @consumer_work (legacy path).
        if not callable(method):
            raise TypeError(
                f"@consumer_work must decorate a method directly. Got {type(method)}."
            )
        return decorator(method)
    # Decorator factory: @consumer_work(...).
    return decorator


def producer_work(
    method: Callable[..., Any] | None = None,
    *,
    work_attrs: WorkAttr = WorkAttr.NONE,
) -> Callable[..., Any]:
    """Register a method as a named producer work function on a ``MemoryResource``.

    Producer work writes data into the owning ``MemoryResource`` from the
    resource's point of view.  Captured schedules pass consumer tokens into
    producer keyword parameters by name.

    Parameters
    ----------
    method : Callable, optional
        Method being decorated.  Omitted when using decorator-factory form.
    work_attrs : cutlass.experimental.task_scheduling.enums.WorkAttr, optional
        Verification-visible attributes for the work callback.  Use
        ``WorkAttr.AUXILIARY`` for helper work that carries no data payload.

    Returns
    -------
    Callable
        Decorated method or decorator factory.

    Notes
    -----
    A typical captured producer receives token values as keyword parameters::

        @producer_work
        @cute.jit
        def store(self, stage_info, *, item):
            self.tensor[stage_info.loop_offset] = item

    When a raw schedule list is used and a resource has multiple named producer
    methods, the label is the final tuple element, for example
    ``(smem, ScheduleStage.ProducerWork, "tma_load_a")``.
    """

    normalized_work_attrs = _normalize_work_attrs(
        work_attrs,
        decorator_name="@producer_work",
    )
    producer_stage = _producer_stage_from_work_attrs(normalized_work_attrs)

    def decorator(fn: Callable[..., Any]) -> Callable[..., Any]:
        method_name = fn.__name__

        # Register the method name in the per-method registry.
        if not hasattr(fn, _PRODUCER_WORK_FNS_ATTR):
            setattr(fn, _PRODUCER_WORK_FNS_ATTR, {})
        getattr(fn, _PRODUCER_WORK_FNS_ATTR)[method_name] = method_name

        (
            kwarg_names,
            positional_arg_names,
            constexpr_arg_names,
            required_constexpr_arg_names,
        ) = _infer_work_arg_names(
            fn,
            "@producer_work",
            "producer inputs",
        )

        # Wrap to auto-inject producer vars as kwargs.
        @functools.wraps(fn)
        def wrapper(
            self: "MemoryResource", stage_info: StageInfo, **work_kwargs: Any
        ) -> Any:
            # Constexpr work-kwargs are supplied by the executor and forwarded
            # verbatim to the work method; empty for legacy / non-captured tasks.
            if kwarg_names:
                kwargs = {
                    name: self._get_producer_var_from_ts(name) for name in kwarg_names
                }
                with self._ts_captured_schedule_user_hook(method_name):
                    return fn(self, stage_info, **kwargs, **work_kwargs)
            with self._ts_captured_schedule_user_hook(method_name):
                return fn(self, stage_info, **work_kwargs)

        # Ensure the registration metadata survives wrapping.
        if not hasattr(wrapper, _PRODUCER_WORK_FNS_ATTR):
            setattr(wrapper, _PRODUCER_WORK_FNS_ATTR, {})
        getattr(wrapper, _PRODUCER_WORK_FNS_ATTR).update(
            getattr(fn, _PRODUCER_WORK_FNS_ATTR, {})
        )

        # Expose the routed (data-flow) input names so the schedule builder can
        # validate the number and identity of DataFlowTokens passed at the
        # schedule call site.  Alongside the full list (``_producer_routed_names``),
        # expose the positional and keyword-only names split out so the builder
        # can bind each group without re-deriving it.  Constexpr params
        # (``_producer_constexpr_names``) are tracked separately below:
        # forwarded verbatim, never routed.
        if kwarg_names:
            setattr(wrapper, "_producer_routed_names", kwarg_names)
            setattr(wrapper, "_producer_routed_positional_names", positional_arg_names)
            setattr(
                wrapper,
                "_producer_routed_keyword_names",
                tuple(n for n in kwarg_names if n not in positional_arg_names),
            )
        if constexpr_arg_names:
            setattr(wrapper, "_producer_constexpr_names", constexpr_arg_names)
        if required_constexpr_arg_names:
            setattr(
                wrapper,
                "_producer_required_constexpr_names",
                required_constexpr_arg_names,
            )

        # Stage metadata consumed by schedule-builder/task dispatch.
        setattr(wrapper, "_producer_work_attrs", normalized_work_attrs)
        setattr(wrapper, "_producer_work_stage", producer_stage)
        setattr(wrapper, _TS_MANAGES_CAPTURE_CONTEXT_ATTR, True)

        return wrapper

    if method is not None:
        # Bare decorator: @producer_work (legacy path).
        if not callable(method):
            raise TypeError(
                f"@producer_work must decorate a method directly. Got {type(method)}."
            )
        return decorator(method)
    # Decorator factory: @producer_work()
    return decorator


@functools.lru_cache(maxsize=None)
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
    Instead of (or in addition to) overriding the monolithic
    ``consumer_work`` / ``producer_work``, subclasses can use the
    ``@consumer_work`` / ``@producer_work`` decorators to
    register multiple named work methods.  The schedule-list label
    selects which method to call at trace time::

        @consumer_work
        @cute.jit
        def k_desc(self, stage_info):
            ...

        @consumer_work
        @cute.jit
        def v_desc(self, stage_info):
            ...

    In the schedule list, each ``ConsumerWork`` entry must carry a
    label when two or more named methods are registered::

        (smem_kv, ScheduleStage.ConsumerWork, "k_desc")

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
    * ``create_consumer_variables() -> dict`` returns a ``{name: default}``
      dict of consumer variables that the consumer side produces and forwards
      to downstream resources via ``copy_consumer_vars_to``.
    * ``create_producer_variables() -> dict`` returns a ``{name: default}``
      dict of variables consumed by the producer side and populated from an
      upstream resource's consumer vars.
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
    consumer_vars, producer_vars : dict
        Variable dicts populated by ``create_consumer/producer_variables``.
    pipeline : object or None
        Materialised pipeline object, set by ``create()``.
    consumer_state, producer_state
        Pipeline state objects (stage index + phase bit).  With
        ``advance_on_acquire``, ``producer_state`` is the acquire cursor and
        ``producer_commit_state`` is the lagging commit cursor.  Producer work
        derives the just-acquired state from ``producer_state`` or follows the
        commit cursor, depending on the work slot.
    consumer_status, producer_status
        Boolean flags used by try_wait / try_acquire.
    is_barrier : bool
        ``True`` for pure signaling resources that carry no data (e.g.
        sequence barriers, done notifications).  Barrier resources get
        relaxed dependency-backing rules in ``_verify_resource_deps``.
    dummy : bool
        Keep DSL state live across dynamic control-flow boundaries.
    """

    # Class-level escape hatch used by the schedule-builder DSL to discover
    # the names of consumer variables produced by ``create_consumer_variables``
    # without having to dry-run the (often DSL-only) hook.  Subclasses whose
    # ``create_consumer_variables`` allocates DSL values that cannot be built
    # outside a kernel context should set this to a tuple of strings matching
    # the keys returned by ``create_consumer_variables``.  Default ``None``
    # means "fall back to dry-run discovery in
    # ``ts.schedule_builder._discover_consumer_var_names``".
    consumer_var_names: ClassVar[Optional[Tuple[str, ...]]] = None

    name: cutlass.Constexpr[str] = ""
    is_barrier: cutlass.Constexpr[bool] = False
    pipeline_config: cutlass.Constexpr[Optional[PipelineConfig]] = None
    consumer_vars: cutlass.Constexpr[dict] = field(default_factory=dict, repr=False)
    producer_vars: cutlass.Constexpr[dict] = field(default_factory=dict, repr=False)
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
    _ts_captured_schedule_depth: cutlass.Constexpr[int] = field(
        init=False, default=0, repr=False
    )
    _ts_captured_schedule_access_context: cutlass.Constexpr[
        Optional[_CapturedScheduleAccessContext]
    ] = field(init=False, default=None, repr=False)
    _ts_task_local_variables: cutlass.Constexpr[object] = field(
        init=False, default=None, repr=False
    )

    def __hash__(self) -> int:
        """Identity-based hash so resources can be used as dict keys."""
        return id(self)

    def __getattribute__(self, name: str) -> Any:
        """Guard direct variable-state reads in captured schedule user code."""
        if name in {"consumer_vars", "producer_vars"}:
            state = object.__getattribute__(self, "__dict__")
            if (
                state.get("_ts_captured_schedule_access_context") is not None
                and not _is_internal_tree_flatten_access()
            ):
                object.__getattribute__(self, "_raise_captured_schedule_var_access")(
                    name
                )
        value = object.__getattribute__(self, name)
        if isinstance(value, TaskLocalVariable):
            state = object.__getattribute__(self, "__dict__")
            context = state.get("_ts_captured_schedule_access_context")
            if context is not None and not _is_internal_tree_flatten_access():
                object.__getattribute__(self, "_raise_captured_schedule_var_access")(
                    name
                )
        return value

    def __setattr__(self, name: str, value: object) -> None:
        """Guard raw variable-dict replacement in captured schedule user code."""
        if name in {"consumer_vars", "producer_vars"}:
            state = object.__getattribute__(self, "__dict__")
            if state.get("_ts_captured_schedule_access_context") is not None:
                object.__getattribute__(self, "_raise_captured_schedule_var_access")(
                    name
                )
        if isinstance(value, TaskLocalVariable):
            value._bind_owner(self, name)
        object.__setattr__(self, name, value)

    def _ts_captured_schedule_execution(
        self,
        enabled: bool,
    ) -> _CapturedScheduleExecutionGuard:
        """Return a context marking the current call as captured-schedule replay."""
        return _CapturedScheduleExecutionGuard(self, enabled)

    def _ts_captured_schedule_user_hook(
        self,
        hook_name: str,
        enabled: bool | None = None,
    ) -> _CapturedScheduleUserHookGuard:
        """Return a context that blocks raw var-dict access in user hook code."""
        if enabled is None:
            enabled = self._ts_is_captured_schedule_execution()
        return _CapturedScheduleUserHookGuard(self, hook_name, enabled)

    def _ts_is_captured_schedule_execution(self) -> bool:
        """True when the current resource call is replaying a captured schedule."""
        return object.__getattribute__(self, "_ts_captured_schedule_depth") > 0

    def _raise_captured_schedule_var_access(self, operation: str) -> None:
        """Raise a user-facing error for hidden var state access."""
        context = object.__getattribute__(self, "_ts_captured_schedule_access_context")
        hook_name = context.hook_name if context is not None else "<unknown hook>"
        raise RuntimeError(
            f"{type(self).__name__}.{hook_name}() accessed `{operation}` "
            f"during captured schedule execution. Captured TS schedules do "
            f"not allow direct TaskLocalVariable or consumer/producer variable "
            f"access or mutation from producer/consumer work hooks. Work hooks "
            f"must use method parameters for inputs and return a scalar or tuple "
            f"matching @consumer_work(returns=...) for outputs."
        )

    @cute.jit
    def _get_consumer_var_from_ts(self, name: cutlass.Constexpr[str]) -> object:
        """Read a consumer variable for TS internals, bypassing user guards."""
        consumer_vars = object.__getattribute__(self, "consumer_vars")
        if cutlass.const_expr(name not in consumer_vars):
            raise KeyError(f"Consumer var '{name}' is not set.")
        return consumer_vars[name]

    @cute.jit
    def _get_producer_var_from_ts(self, name: cutlass.Constexpr[str]) -> object:
        """Read a producer variable for TS internals, bypassing user guards."""
        producer_vars = object.__getattribute__(self, "producer_vars")
        if cutlass.const_expr(name not in producer_vars):
            raise KeyError(f"Producer var '{name}' is not set.")
        return producer_vars[name]

    @cute.jit
    def _set_consumer_var_from_ts(
        self, name: cutlass.Constexpr[str], value: cutlass.Constexpr[object]
    ) -> None:
        """Write a consumer variable for TS internals, bypassing user guards."""
        consumer_vars = object.__getattribute__(self, "consumer_vars")
        consumer_vars[name] = value

    @cute.jit
    def _set_producer_var_from_ts(
        self, name: cutlass.Constexpr[str], value: cutlass.Constexpr[object]
    ) -> None:
        """Write a producer variable for TS internals, bypassing user guards."""
        producer_vars = object.__getattribute__(self, "producer_vars")
        producer_vars[name] = value

    @property
    def state_src(self) -> "MemoryResource":
        """The object that owns this resource's *consumer* pipeline state.

        Returns ``self`` by default.  For a member of a *Merge*
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
        ``PipelineGroup.__post_init__`` for Merge members only.
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

        if pipeline_config.pipeline_type == PipelineType.AsyncAsync:
            if pipeline_config.async_producer_op == pipeline.PipelineOp.AsyncLoad:
                sync_object_full = pipeline.PipelineAsync._make_sync_object(
                    barrier_ptr.align(min_align=8),
                    pipeline_config.num_stages,
                    (
                        pipeline.PipelineOp.AsyncLoad,
                        pipeline_config.producer_group,
                    ),
                )
                sync_object_empty = pipeline.PipelineAsync._make_sync_object(
                    barrier_ptr.align(min_align=8) + pipeline_config.num_stages,
                    pipeline_config.num_stages,
                    (
                        pipeline.PipelineOp.AsyncThread,
                        pipeline_config.consumer_group,
                    ),
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
                    barrier_ptr.align(min_align=8),
                    pipeline_config.num_stages,
                    (pipeline.PipelineOp.TmaLoad, pipeline_config.producer_group),
                    pipeline_config.num_bytes,
                )
                sync_object_empty = pipeline.PipelineAsync._make_sync_object(
                    barrier_ptr.align(min_align=8) + pipeline_config.num_stages,
                    pipeline_config.num_stages,
                    (pipeline.PipelineOp.AsyncThread, pipeline_config.consumer_group),
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

    def create_consumer_variables_internal(
        self, captured_schedule: bool = False
    ) -> None:
        """Populate ``consumer_vars`` by calling the user hook (legacy only)."""
        if captured_schedule:
            cls = type(self)
            if "create_consumer_variables" in cls.__dict__:
                raise TypeError(
                    f"{cls.__name__}: overriding create_consumer_variables() "
                    f"is forbidden in captured-schedule mode. Declare emitted "
                    f"vars as TaskLocalVariable fields and produce them from "
                    f"@consumer_work(returns=...)."
                )
            return

        cls = type(self)
        # Transitional resources can seed consumer_vars from pre-existing
        # role-variable state while still supporting legacy schedules.
        if cutlass.const_expr(
            cls.create_consumer_variables is MemoryResource.create_consumer_variables
            and object.__getattribute__(self, "consumer_vars")
        ):
            return

        with self._ts_captured_schedule_execution(captured_schedule):
            with self._ts_captured_schedule_user_hook(
                "create_consumer_variables",
                enabled=captured_schedule,
            ):
                result = self.create_consumer_variables()
        if not isinstance(result, dict):
            raise TypeError(
                f"{type(self).__name__}.create_consumer_variables() must "
                f"return dict, got {type(result).__name__}."
            )
        object.__setattr__(self, "consumer_vars", result)

    def create_producer_variables_internal(
        self, captured_schedule: bool = False
    ) -> None:
        """Populate ``producer_vars`` by calling the user hook (legacy only).

        In captured-schedule mode, ``producer_vars`` is auto-allocated
        by ``Task._allocate_slots_from_routing`` from upstream
        ``consumer_vars`` based on captured schedule data-flow tokens,
        and overriding ``create_producer_variables`` is forbidden. This
        method becomes a no-op (and raises on illegal overrides) — the
        actual slot allocation runs from ``Task.init_variables``.
        """
        if captured_schedule:
            cls = type(self)
            if "create_producer_variables" in cls.__dict__:
                raise TypeError(
                    f"{cls.__name__}: overriding create_producer_variables() "
                    f"is forbidden in captured-schedule mode. Producer-side "
                    f"slots are auto-allocated from upstream consumer_vars "
                    f"via captured schedule data-flow tokens."
                )
            return

        with self._ts_captured_schedule_execution(captured_schedule):
            with self._ts_captured_schedule_user_hook(
                "create_producer_variables",
                enabled=captured_schedule,
            ):
                result = self.create_producer_variables()
        if not isinstance(result, dict):
            raise TypeError(
                f"{type(self).__name__}.create_producer_variables() must "
                f"return dict, got {type(result).__name__}."
            )
        object.__setattr__(self, "producer_vars", result)

    def create_consumer_variables(self) -> dict:
        """Return initial consumer variable dict.  Override in subclasses."""
        return {}

    def create_producer_variables(self) -> dict:
        """Return initial producer variable dict.  Override in subclasses."""
        return {}

    def _reset_task_local_variables_to_defaults(
        self, variables: tuple[TaskLocalVariable, ...]
    ) -> None:
        """Populate internal slots from ``TaskLocalVariable`` declarations."""
        for variable in variables:
            _initialize_task_local_variable_from_ts(variable)

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
        captured_schedule: bool = False,
    ) -> None:
        """Initialise pipeline state/status and task-local storage defaults.

        Always creates ``consumer_status`` / ``producer_status`` (Int32)
        and ``consumer_state`` / ``producer_state`` (pipeline state or
        dummy Int32) so that the DSL tree shape is consistent regardless
        of whether a pipeline is attached.

        For CLC pipelines the producer
        state uses ``ProducerConsumer`` mode to support both roles.
        """
        del context, captured_schedule
        self._reset_task_local_variables_to_defaults(get_task_local_variables(self))

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

        # Members of a Merge PipelineGroup share the group's pipeline
        # state (one consumer drives progression).  Fork members need
        # their own states because consumers advance independently.
        from .enums import PipelineGroupMode
        from .pipeline_group import PipelineGroup

        has_own_pipeline = self.pipeline_config is not None and (
            self.pipeline_group is None
            or self.pipeline_group.mode == PipelineGroupMode.Fork
        )
        is_merge_member = (
            self.pipeline_config is not None
            and self.pipeline_group is not None
            and isinstance(self.pipeline_group, PipelineGroup)
            and self.pipeline_group.mode == PipelineGroupMode.Merge
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
                if cutlass.const_expr(self.pipeline_config.advance_on_acquire):
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
                if cutlass.const_expr(self.pipeline_config.advance_on_acquire):
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
            if cutlass.const_expr(self.pipeline_config.advance_on_wait):
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
            if cutlass.const_expr(self.pipeline_config.advance_on_acquire):
                self.producer_commit_state = pipeline.make_pipeline_state(
                    pipeline.PipelineUserType.Producer,
                    self.pipeline_config.num_stages,
                )
            else:
                self.producer_commit_state = cutlass.Int32(0)
            if cutlass.const_expr(self.pipeline_config.advance_on_wait):
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
    def set_consumer_var(self, name: cutlass.Constexpr[str], value: object) -> None:
        """Save a named consumer variable (called from ``consumer_work``)."""
        if cutlass.const_expr(self._ts_is_captured_schedule_execution()):
            self._raise_captured_schedule_var_access("set_consumer_var")
        self.consumer_vars[name] = value

    def get_consumer_var(self, name: str) -> object:
        """Read a named consumer variable (called from consumer work)."""
        if self._ts_is_captured_schedule_execution():
            self._raise_captured_schedule_var_access("get_consumer_var")
        if name in self.consumer_vars:
            return self.consumer_vars[name]
        raise KeyError(f"Consumer var '{name}' is not set.")

    @cute.jit
    def get_producer_var(self, name: cutlass.Constexpr[str]) -> object:
        """Read a named producer variable (called from ``producer_work``)."""
        if cutlass.const_expr(self._ts_is_captured_schedule_execution()):
            self._raise_captured_schedule_var_access("get_producer_var")
        if cutlass.const_expr(name not in self.producer_vars):
            raise KeyError(f"Producer var '{name}' is not set.")
        return self.producer_vars[name]

    @cute.jit
    def copy_consumer_vars_to(
        self,
        dst_resource: "MemoryResource",
        var_names: Optional[list[VarRoute]] = None,
    ) -> None:
        """Forward matching consumer vars into *dst_resource*'s producer vars.

        When *var_names* is ``None`` (broadcast mode), every key present in
        both ``self.consumer_vars`` and ``dst_resource.producer_vars`` is
        copied.  When *var_names* is given, only those specific routes are
        copied.  A route may be ``"name"`` for same-name copy or
        ``("src_name", "dst_name")`` for explicit remapping.

        Called automatically by ``Task._consumer_work`` after
        ``consumer_work(stage_info)`` returns, for destinations whose
        ``dst_stage`` in the resolved slot routing is a ``Producer*Work``
        stage.
        """
        if cutlass.const_expr(var_names is None):
            for name in self.consumer_vars:
                if cutlass.const_expr(name in dst_resource.producer_vars):
                    dst_resource._set_producer_var_from_ts(
                        name, self.consumer_vars[name]
                    )
        else:
            assert var_names is not None
            for route in var_names:
                if cutlass.const_expr(isinstance(route, tuple)):
                    src_name = route[0]
                    dst_name = route[1]
                else:
                    src_name = cast(str, route)
                    dst_name = cast(str, route)
                if cutlass.const_expr(
                    src_name in self.consumer_vars
                    and dst_name in dst_resource.producer_vars
                ):
                    dst_resource._set_producer_var_from_ts(
                        dst_name, self.consumer_vars[src_name]
                    )

    @cute.jit
    def copy_consumer_vars_to_consumer_of(
        self,
        dst_resource: "MemoryResource",
        var_names: Optional[list[VarRoute]] = None,
    ) -> None:
        """Forward matching consumer vars into *dst_resource*'s consumer vars.

        Counterpart to :meth:`copy_consumer_vars_to` for
        consumer-to-consumer variable flow: the source resource's
        ``consumer_vars`` are copied into the destination resource's
        ``consumer_vars`` so that a later ``consumer_work*`` call on
        ``dst_resource`` can read them with ``get_consumer_var``.

        When *var_names* is ``None`` (broadcast mode), every key present in
        both ``self.consumer_vars`` and ``dst_resource.consumer_vars`` is
        copied.  When *var_names* is given, only those specific routes are
        copied.  A route may be ``"name"`` for same-name copy or
        ``("src_name", "dst_name")`` for explicit remapping.

        Called automatically by ``Task._consumer_work*`` when the
        resolved slot routing for this slot targets a ``ConsumerWork*``
        stage on ``dst_resource`` (which must therefore be in
        ``src_resources``, since consumer vars belong to the consumer
        side of a resource).
        """
        if cutlass.const_expr(var_names is None):
            for name in self.consumer_vars:
                if cutlass.const_expr(name in dst_resource.consumer_vars):
                    dst_resource._set_consumer_var_from_ts(
                        name, self.consumer_vars[name]
                    )
        else:
            assert var_names is not None
            for route in var_names:
                if cutlass.const_expr(isinstance(route, tuple)):
                    src_name = route[0]
                    dst_name = route[1]
                else:
                    src_name = cast(str, route)
                    dst_name = cast(str, route)
                if cutlass.const_expr(
                    src_name in self.consumer_vars
                    and dst_name in dst_resource.consumer_vars
                ):
                    dst_resource._set_consumer_var_from_ts(
                        dst_name, self.consumer_vars[src_name]
                    )

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

    def create_tile_scheduler(
        self,
    ) -> "StaticPersistentTileScheduler | ClcDynamicPersistentTileScheduler":
        """Instantiate the concrete tile scheduler from ``tile_scheduler_config``."""
        if (
            self.tile_scheduler_config.tile_scheduler_type
            == TileSchedulerType.StaticPersistent
        ):
            return StaticPersistentTileScheduler.create(
                cast(
                    PersistentTileSchedulerParams,
                    self.tile_scheduler_config.tile_scheduler_params,
                ),
                cute.arch.block_idx(),
                cute.arch.grid_dim(),
            )
        elif (
            self.tile_scheduler_config.tile_scheduler_type
            == TileSchedulerType.ClcDynamicPersistent
        ):
            return ClcDynamicPersistentTileScheduler.create(
                cast(
                    ClcDynamicPersistentTileSchedulerParams,
                    self.tile_scheduler_config.tile_scheduler_params,
                ),
                cute.arch.block_idx(),
                cute.arch.grid_dim(),
                self.tile_scheduler_config.response_ptr,
            )
        else:
            raise ValueError(
                f"Invalid tile scheduler type: {self.tile_sched_config.tile_scheduler_type}"
            )

    def create(self) -> None:
        """Create the pipeline (from base class) and the tile scheduler."""
        super().create()
        self.tile_scheduler = self.create_tile_scheduler()

    @cute.jit
    def _make_initial_work_tile(self) -> WorkTileInfo:
        assert self.tile_scheduler is not None
        return self.tile_scheduler.initial_work_tile_info()

    @cute.jit
    def initial_work_tile_info(self) -> WorkTileInfo:
        """Return the initial work tile from the underlying scheduler."""
        return self._make_initial_work_tile()

    @cute.jit
    def skip_work_tile_if(self, work_tile: WorkTileInfo) -> cutlass.Boolean:
        """Default skipped-tile predicate used by captured TS schedules."""
        del work_tile
        return self._get_consumer_var_from_ts("skip_work_tile")

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
            work_tile = self.tile_scheduler.get_current_work()
        else:
            # CLC dynamic: read from the per-stage response buffer
            stage_response_ptr = self._get_stage_response_ptr(stage_info.stage_idx)
            assert isinstance(self.tile_scheduler, ClcDynamicPersistentTileScheduler)
            work_tile = self.tile_scheduler.work_tile_info_from_clc_response(
                stage_response_ptr
            )
        return work_tile

    @consumer_work(returns=("work_tile",))
    @cute.jit
    def get_and_advance_work_tile(
        self,
        stage_info: StageInfo,
    ) -> WorkTileInfo:
        """Typed-schedule work-tile advance callback."""
        return self._get_and_advance_work_tile_impl(stage_info)

    @cute.jit
    def _get_stage_response_ptr(self, stage_idx: int) -> cute.Pointer:
        """Compute the CLC response pointer for a given pipeline stage.

        With multi-stage work queues, each stage has its own 16-byte
        response buffer.  The base ``_clc_response_ptr`` points to stage 0;
        subsequent stages are offset by one Int128 response record each.
        """
        assert self.pipeline_config is not None
        assert isinstance(self.tile_scheduler, ClcDynamicPersistentTileScheduler)
        if cutlass.const_expr(self.pipeline_config.num_stages == 1):
            return self.tile_scheduler._clc_response_ptr
        return self.tile_scheduler._clc_response_ptr + stage_idx

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

        assert isinstance(self.tile_scheduler, ClcDynamicPersistentTileScheduler)
        m_idx, n_idx, l_idx = self.tile_scheduler._swizzle_and_rasterize(
            m_idx,
            n_idx,
            l_idx,
        )
        cta_idx_in_cluster, cta_idy_in_cluster, _ = (
            self.tile_scheduler.cta_id_in_cluster  # type: ignore[misc]
        )
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
            assert isinstance(self.tile_scheduler, ClcDynamicPersistentTileScheduler)
            self.tile_scheduler._num_tiles_executed += cutlass.Int32(1)

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
                self.pipeline.producer_tail(self.producer_state)
            else:
                self.pipeline.producer_tail(self.producer_state)


# PipelineGroup lives in its own module but is re-exported here lazily for
# backward compatibility.  Importing it eagerly creates a cycle when callers
# import ``ts.pipeline_group`` before ``ts.resources`` has finished loading.
def __getattr__(name: str) -> Any:
    if name in {"PipelineGroup", "_GroupMemberRef"}:
        from .pipeline_group import PipelineGroup, _GroupMemberRef

        return {
            "PipelineGroup": PipelineGroup,
            "_GroupMemberRef": _GroupMemberRef,
        }[name]
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
