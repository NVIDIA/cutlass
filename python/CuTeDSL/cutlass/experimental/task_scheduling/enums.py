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

from enum import Enum, IntFlag


class PipelineType(Enum):
    """Type of the concrete pipeline implementation in ``PipelineConfig``.

    Pipeline names follow the ``<Producer><Consumer>`` convention.

    Public members:

    * ``AsyncAsync`` - Generic async (thread-based) producer + async-thread
      consumer pipeline.
    * ``TmaAsync`` - TMA-producer + async-thread consumer pipeline
      (cp.async.bulk).
    * ``TmaUmma`` - TMA-producer + UMMA-consumer async pipeline.
    * ``UmmaAsync`` - UMMA-producer + AsyncThread-consumer async pipeline.
      ``UmmaAsync`` matches the CUTLASS pipeline name.
    * ``AsyncUmma`` - AsyncThread-producer + UMMA-consumer async pipeline.
      ``AsyncUmma`` matches the CUTLASS pipeline name.
    * ``UmmaUmma`` - UMMA-producer + UMMA-consumer async pipeline. Used when
      tensor-core producer and consumer stages are both UMMA-backed.
    * ``ClcFetchAsync`` - CLC tile-fetch producer + async-thread consumer pipeline.

    """

    AsyncAsync = "AsyncAsync"
    TmaAsync = "TmaAsync"
    TmaUmma = "TmaUmma"
    UmmaAsync = "UmmaAsync"
    AsyncUmma = "AsyncUmma"
    UmmaUmma = "UmmaUmma"
    ClcFetchAsync = "ClcFetchAsync"

class TileSchedulerType(Enum):
    """Selects the persistent tile-scheduling strategy.

    Members:

    * ``StaticPersistent`` - CTAs are launched to fill one SM wave; work-tile
      indices are assigned statically per CTA.
    * ``ClcDynamicPersistent`` - A dedicated scheduler warp fetches work tiles
      dynamically at runtime.
    """

    StaticPersistent = "StaticPersistent"
    ClcDynamicPersistent = "ClcDynamicPersistent"


class PipelineGroupMode(Enum):
    """Dataflow topology of a ``PipelineGroup``.

    A group collapses the barrier on whichever side is driven by a single
    task.  Group construction derives a merged config from the member configs:
    ``num_bytes`` is combined across members as required by the group mode,
    while the collapsed side's cooperative-group size must match across
    members.

    Members:

    * ``Merge`` - N-to-1: each member has a separate producer task; all
      members share one consumer task. The consumer side is collapsed: member
      pipeline types must have compatible consumer kinds, and
      ``consumer_group.size`` must match.
    * ``Fork`` - 1-to-N: all members share one producer task; each member
      has a separate consumer task. The producer side is collapsed: member
      pipeline types must have compatible producer kinds, and
      ``producer_group.size`` must match.
    """

    Merge = "Merge"
    Fork = "Fork"


class SignalingThreads(IntFlag):
    """Controls which threads execute pipeline barrier operations.

    Members:

    * ``All`` - Every thread in the cooperative group participates.
    * ``CtaLeader`` - Only CTA 0 in the cluster signals (used when a single
      CTA drives a 2-CTA pipeline, e.g. MMA producer).
    * ``TaskWarpLeader`` - Only the first warp assigned to the task arms the
      producer-side transaction barrier. This is orthogonal to CTA ownership:
      it may be combined with ``CtaLeader``.

    ``CtaLeader`` and ``TaskWarpLeader`` are composable. ``All`` is
    exclusive: combining it with another flag is invalid because it
    contradicts a narrower signaling predicate.
    """

    All = 1
    CtaLeader = 2
    TaskWarpLeader = 4

    @classmethod
    def is_valid_combination(cls, value: "SignalingThreads") -> bool:
        """Return true for signaling modes supported by TS codegen."""
        return value in (
            cls.All,
            cls.CtaLeader,
            cls.TaskWarpLeader,
            cls.CtaLeader | cls.TaskWarpLeader,
        )

    @classmethod
    def validate(cls, value: "SignalingThreads", field_name: str) -> None:
        """Raise if ``value`` is not a supported signaling mode."""
        if not isinstance(value, cls):
            raise TypeError(
                f"{field_name} must be a SignalingThreads value, got "
                f"{type(value).__name__}."
            )
        if not cls.is_valid_combination(value):
            raise ValueError(
                f"{field_name} has unsupported SignalingThreads combination "
                f"{value}; supported values are All, CtaLeader, TaskWarpLeader, "
                f"and CtaLeader|TaskWarpLeader."
            )

    def has_cta_leader(self) -> bool:
        """Return true when CTA-leader gating is part of this mode."""
        return bool(self & SignalingThreads.CtaLeader)

    def has_task_warp_leader(self) -> bool:
        """Return true when task-warp-leader gating is part of this mode."""
        return bool(self & SignalingThreads.TaskWarpLeader)

    def __str__(self) -> str:
        return self.name if self.name is not None else f"SignalingThreads({int(self)})"


class WorkAttr(IntFlag):
    """Verification-visible attributes attached to TS work callbacks.

    Work attributes describe semantic properties that the schedule verifier
    must account for.  ``AUXILIARY`` marks callbacks that do not model memory
    access and should not participate in normal resource ordering checks.
    The type is an ``IntFlag`` so future verifier attributes can be composed
    without changing the decorator API.
    """

    NONE = 0
    AUXILIARY = 1

    @classmethod
    def is_valid_combination(cls, value: "WorkAttr") -> bool:
        """Return true for work-attribute sets supported by verification."""
        return value in {cls.NONE, cls.AUXILIARY}

    @classmethod
    def validate(cls, value: "WorkAttr", field_name: str) -> None:
        """Raise if ``value`` is not a supported work-attribute flag set."""
        if not isinstance(value, cls):
            raise TypeError(
                f"{field_name} must be a WorkAttr value, got {type(value).__name__}."
            )
        if not cls.is_valid_combination(value):
            raise ValueError(
                f"{field_name} has unsupported WorkAttr combination {value}; "
                "supported values are NONE and AUXILIARY."
            )

    def is_auxiliary(self) -> bool:
        """Return true when auxiliary-work semantics are requested."""
        return bool(self & WorkAttr.AUXILIARY)


class ScheduleStage(Enum):
    """Individual pipeline operations that a ``Task`` schedule can reference.

    Each member maps to a method on ``Task`` that delegates to the
    corresponding pipeline / resource call:

    Consumer side (src in the Task):
      - ``ConsumerAuxWork``        - execute side-effect-free helper-variable work.
      - ``ConsumerTryWait``         - non-blocking check for data availability.
      - ``ConsumerWait``            - blocking wait for data availability.
      - ``ConsumerWork``            - execute the resource's ``consumer_work()``.
      - ``ConsumerRelease``         - signal the producer that the buffer is free.

    Producer side (dst in the Task):
      - ``ProducerAuxWork``        - execute side-effect-free helper-variable work.
      - ``ProducerTryAcquire``     - non-blocking check for a free buffer.
      - ``ProducerAcquire``        - blocking wait for a free buffer.
      - ``ProducerWork``           - execute the resource's ``producer_work()``.
      - ``ProducerCommit``         - signal the consumer that data is ready.

    The ``__str__`` method returns compact labels used in schedule printouts.
    """

    def __str__(self) -> str:
        if self == ScheduleStage.ConsumerAuxWork:
            return "  ConsAux"
        elif self == ScheduleStage.ConsumerRelease:
            return "<-ConsRel"
        elif self == ScheduleStage.ConsumerTryWait:
            return "  ConsTrW"
        elif self == ScheduleStage.ConsumerWait:
            return "->ConsWai"
        elif self == ScheduleStage.ConsumerWork:
            return "  ConsWrk"
        elif self == ScheduleStage.ProducerAuxWork:
            return "  ProdAux"
        elif self == ScheduleStage.ProducerTryAcquire:
            return "  ProdTrA"
        elif self == ScheduleStage.ProducerAcquire:
            return "  ProdAcq<-"
        elif self == ScheduleStage.ProducerCommit:
            return "  ProdCmt->"
        elif self == ScheduleStage.ProducerWork:
            return "  ProdWrk"
        else:
            raise ValueError("Invalid schedule stage")

    ConsumerAuxWork = "ConsumerAuxWork"
    ConsumerRelease = "ConsumerRelease"
    ConsumerTryWait = "ConsumerTryWait"
    ConsumerWait = "ConsumerWait"
    ConsumerWork = "ConsumerWork"
    ProducerAuxWork = "ProducerAuxWork"
    ProducerTryAcquire = "ProducerTryAcquire"
    ProducerAcquire = "ProducerAcquire"
    ProducerCommit = "ProducerCommit"
    ProducerWork = "ProducerWork"


class ScheduleStageType(Enum):
    """Classifies where a schedule entry sits relative to the
    K-tile loop over the computational domain.

    Members:

    * ``Head`` - Prefetch phase, executed once before the loop.
    * ``Loop`` - Steady-state body, every iteration.
    * ``LoopFirstIter`` - Fires only on the first iteration (idx == 0).
    * ``LoopLastIter`` - Fires only on the last iteration
      (idx == domain - step).
    * ``Tail`` - Drain / epilogue phase, executed once after the loop.
    """

    Head = "Head"
    Loop = "Loop"
    LoopFirstIter = "LoopFirstIter"
    LoopLastIter = "LoopLastIter"
    Tail = "Tail"


class LoopGuard(Enum):
    """Conditional execution guard for LOOP schedule entries.

    Members
    -------
    Always    - Execute every iteration (default).
    LastIter  - Execute only on the last iteration (``is_last_iter``).
    FirstIter - Execute only on the first iteration (``is_first_iter``).
    """

    Always = "Always"
    LastIter = "LastIter"
    FirstIter = "FirstIter"
