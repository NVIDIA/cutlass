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

import os
import sys
import weakref
from dataclasses import dataclass
from enum import Enum, IntFlag
from typing import Hashable, Iterator, cast
from types import FrameType

_INT32_MAX = (1 << 31) - 1


class BlockGuard:
    """Marker base for conditional block guards in captured schedules.

    ``&`` and ``|`` build flattened boolean guard trees. ``~`` converts a guard
    to negation-normal form, including first-class complements of iteration
    predicates.
    """

    def __and__(self, other: object) -> "BlockGuard":
        if not isinstance(other, BlockGuard):
            return NotImplemented
        return _combine_guard(GuardAnd, self, other)

    def __rand__(self, other: object) -> "BlockGuard":
        if not isinstance(other, BlockGuard):
            return NotImplemented
        return _combine_guard(GuardAnd, other, self)

    def __or__(self, other: object) -> "BlockGuard":
        if not isinstance(other, BlockGuard):
            return NotImplemented
        return _combine_guard(GuardOr, self, other)

    def __ror__(self, other: object) -> "BlockGuard":
        if not isinstance(other, BlockGuard):
            return NotImplemented
        return _combine_guard(GuardOr, other, self)

    def __invert__(self) -> "BlockGuard":
        return _negate_guard(self)

    def __bool__(self) -> bool:
        from .schedule_builder import ScheduleError

        raise ScheduleError(
            "schedule conditions cannot be converted to bool; use '&', '|', "
            "and '~'. Python 'and', 'or', and 'not' cannot be overloaded."
        )


class IterationPredicate(BlockGuard):
    """Loop guard decidable at trace time from the zero-based iteration count."""

    def fires(self, iter_idx: int, num_iters: int) -> bool:
        """Return whether the guarded block runs on iteration ``iter_idx``."""
        raise NotImplementedError


@dataclass(frozen=True)
class ComplementedIterationPredicate(IterationPredicate):
    """Boolean complement of an iteration predicate."""

    predicate: IterationPredicate

    def fires(self, iter_idx: int, num_iters: int) -> bool:
        return not self.predicate.fires(iter_idx, num_iters)


@dataclass(frozen=True)
class _FirstIterPredicate(IterationPredicate):
    """Singleton first-iteration guard."""

    def fires(self, iter_idx: int, num_iters: int) -> bool:
        return iter_idx == 0


@dataclass(frozen=True)
class _LastIterPredicate(IterationPredicate):
    """Singleton last-iteration guard."""

    def fires(self, iter_idx: int, num_iters: int) -> bool:
        if num_iters <= 0:
            return False
        return iter_idx == num_iters - 1


FIRST_ITER = _FirstIterPredicate()
LAST_ITER = _LastIterPredicate()


@dataclass(frozen=True)
class Every(IterationPredicate):
    """Periodic guard using zero-based iteration counts.

    Fires on counts ``start, start + period, start + 2 * period, ...``.
    """

    period: int
    start: int = 0

    def __post_init__(self) -> None:
        if type(self.period) is not int:
            raise TypeError(
                f"Every period must be an int, got {type(self.period).__name__}."
            )
        if self.period <= 0:
            raise ValueError(f"Every period must be positive, got {self.period}.")
        if self.period > _INT32_MAX:
            raise ValueError(
                f"Every period must fit in a signed 32-bit integer, got {self.period}."
            )
        if type(self.start) is not int:
            raise TypeError(
                f"Every start must be an int, got {type(self.start).__name__}."
            )
        if self.start < 0:
            raise ValueError(f"Every start must be nonnegative, got {self.start}.")
        if self.start > _INT32_MAX:
            raise ValueError(
                f"Every start must fit in a signed 32-bit integer, got {self.start}."
            )

    def fires(self, iter_idx: int, num_iters: int) -> bool:
        del num_iters
        return iter_idx >= self.start and (iter_idx - self.start) % self.period == 0


@dataclass(frozen=True)
class OpaqueCondition(BlockGuard):
    """Loop guard backed by a runtime value enumerated under ``key``.

    ``negated`` is ``True`` for :func:`when_false` blocks.  Optional
    ``resource`` / ``method_label`` identify the work-call output that produced
    the stored guard value; when omitted the verifier still honors ``key``
    correlation.  ``result_name`` selects that stored output.  Runtime execution
    reads the stored value instead of re-invoking the producing method;
    integer-like values are false only when zero.
    """

    key: Hashable
    negated: bool = False
    resource: object | None = None
    method_label: str | None = None
    result_name: str | None = None


@dataclass(frozen=True)
class GuardAnd(BlockGuard):
    """Conjunction of two or more guards, flattened at construction."""

    operands: tuple[BlockGuard, ...]

    def __post_init__(self) -> None:
        if len(self.operands) < 2:
            raise ValueError("GuardAnd requires at least two operands.")


@dataclass(frozen=True)
class GuardOr(BlockGuard):
    """Disjunction of two or more guards, flattened at construction."""

    operands: tuple[BlockGuard, ...]

    def __post_init__(self) -> None:
        if len(self.operands) < 2:
            raise ValueError("GuardOr requires at least two operands.")


def _combine_guard(
    operator: type[GuardAnd] | type[GuardOr],
    left: BlockGuard,
    right: BlockGuard,
) -> BlockGuard:
    """Build one flattened AND/OR node."""
    operands: list[BlockGuard] = []
    for operand in (left, right):
        if isinstance(operand, operator):
            operands.extend(cast(GuardAnd | GuardOr, operand).operands)
        else:
            operands.append(operand)
    return operator(tuple(operands))


def _negate_guard(guard: BlockGuard) -> BlockGuard:
    """Return ``guard`` in negation-normal form."""
    if isinstance(guard, OpaqueCondition):
        return OpaqueCondition(
            key=guard.key,
            negated=not guard.negated,
            resource=guard.resource,
            method_label=guard.method_label,
            result_name=guard.result_name,
        )
    if isinstance(guard, GuardAnd):
        operands = tuple(_negate_guard(operand) for operand in guard.operands)
        result = operands[0] | operands[1]
        for operand in operands[2:]:
            result = result | operand
        return result
    if isinstance(guard, GuardOr):
        operands = tuple(_negate_guard(operand) for operand in guard.operands)
        result = operands[0] & operands[1]
        for operand in operands[2:]:
            result = result & operand
        return result
    if isinstance(guard, ComplementedIterationPredicate):
        return guard.predicate
    if isinstance(guard, IterationPredicate):
        return ComplementedIterationPredicate(guard)
    if type(guard).__invert__ is not BlockGuard.__invert__:
        return guard.__invert__()
    return NotImplemented


def iter_leaves(guard: BlockGuard) -> Iterator[OpaqueCondition | IterationPredicate]:
    """Yield opaque and iteration leaves from a guard tree."""
    if isinstance(guard, (OpaqueCondition, IterationPredicate)):
        yield guard
        return
    if isinstance(guard, (GuardAnd, GuardOr)):
        for operand in guard.operands:
            yield from iter_leaves(operand)


@dataclass(frozen=True)
class _SkippableGuard(BlockGuard):
    """Singleton guard for work omitted on skipped work tiles."""


SKIPPABLE = _SkippableGuard()


def is_skippable_guard(guard: object) -> bool:
    """Return whether ``guard`` is the work-tile ``SKIPPABLE`` marker."""
    return guard is SKIPPABLE


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
    * ``FusedMerge`` - N-to-1, like ``Merge`` but with a single shared
      full barrier instead of one per producer.
    """

    Merge = "Merge"
    Fork = "Fork"
    FusedMerge = "FusedMerge"


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


class StateRole(Enum):
    """Role of an explicit software-pipeline cursor."""

    Producer = "producer"
    Consumer = "consumer"


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


def is_iteration_predicate(guard: object) -> bool:
    """Return whether ``guard`` is an iteration predicate or legacy enum."""
    if isinstance(guard, IterationPredicate):
        return True
    if isinstance(guard, LoopGuard):
        return guard in (LoopGuard.Always, LoopGuard.FirstIter, LoopGuard.LastIter)
    return False


def is_loop_guard(guard: object) -> bool:
    """Return whether ``guard`` is a supported loop-schedule guard."""
    return isinstance(
        guard, (LoopGuard, IterationPredicate, OpaqueCondition, GuardAnd, GuardOr)
    )


def guard_fires(
    guard: object,
    iter_idx: int,
    num_iters: int,
    *,
    opaque_assignment: dict[Hashable, bool] | None = None,
) -> bool:
    """Evaluate whether a loop guard is active on iteration ``iter_idx``."""
    if guard == LoopGuard.Always:
        return True
    if guard == LoopGuard.FirstIter or guard is FIRST_ITER:
        return iter_idx == 0
    if guard == LoopGuard.LastIter or guard is LAST_ITER:
        if num_iters <= 0:
            return False
        return iter_idx == num_iters - 1
    if isinstance(guard, IterationPredicate):
        return guard.fires(iter_idx, num_iters)
    if isinstance(guard, OpaqueCondition):
        assignment = opaque_assignment or {}
        active = assignment.get(guard.key, False)
        return active != guard.negated
    if isinstance(guard, GuardAnd):
        return all(
            guard_fires(
                operand,
                iter_idx,
                num_iters,
                opaque_assignment=opaque_assignment,
            )
            for operand in guard.operands
        )
    if isinstance(guard, GuardOr):
        return any(
            guard_fires(
                operand,
                iter_idx,
                num_iters,
                opaque_assignment=opaque_assignment,
            )
            for operand in guard.operands
        )
    raise TypeError(f"unsupported loop guard type: {type(guard).__name__}")


# Directory-boundary prefix for user-frame attribution (plain prefix would
# also match siblings like .../task_scheduling_x). Fallback for frames whose
# module name is unavailable (exec'd code without ``__name__``).
_TS_PACKAGE_DIR = os.path.dirname(os.path.abspath(__file__)) + os.sep

# Module-name prefixes of frames that are never the user's call site. Under
# the FrontendNext/PyIR frontend every user call (e.g. ``SmemResource(...)``)
# is routed through ``cutlass.base_dsl.pyir_call_boundary``, so skipping only
# this package would attribute the construction to the DSL runtime. Matched
# on ``__name__`` rather than file paths: the installed layout (symlink farm,
# wheel) and realpath/abspath differences make path prefixes unreliable.
#
# Only frameworks this package itself routes calls through are listed here.
# An out-of-tree observer that sits between the user and the framework adds
# its own prefix via :func:`add_infrastructure_module_prefix`; enumerating
# observers here would be a dependency on them (an explicit registration is
# also exact, unlike a blanket "everything under cutlass.experimental" rule,
# which would misclassify a user kernel written inside that namespace).
_INFRASTRUCTURE_MODULE_PREFIXES: list[str] = [
    "cutlass.experimental.task_scheduling",
    "cutlass.base_dsl",
    "cutlass.cutlass_dsl",
    "cutlass._mlir",
    "contextlib",
]


def add_infrastructure_module_prefix(prefix: str) -> None:
    """Treat frames under module ``prefix`` as framework, not user, code.

    For callers that wrap the framework and would otherwise be reported as
    the user's construction site. Idempotent, so a module may register on
    import and survive a reload.
    """
    if prefix not in _INFRASTRUCTURE_MODULE_PREFIXES:
        _INFRASTRUCTURE_MODULE_PREFIXES.append(prefix)


def _has_module_prefix(module_name: str, prefix: str) -> bool:
    return module_name == prefix or module_name.startswith(prefix + ".")


def is_infrastructure_frame(frame: FrameType) -> bool:
    """True when ``frame`` belongs to the DSL/TS runtime rather than user code.

    A frame is infrastructure when its module (``f_globals['__name__']``)
    lives under one of the DSL packages or contextlib, or, when the module
    name is unavailable, when its code object was loaded from this package.
    """
    module_name = frame.f_globals.get("__name__")
    if isinstance(module_name, str):
        return any(
            _has_module_prefix(module_name, prefix)
            for prefix in _INFRASTRUCTURE_MODULE_PREFIXES
        )
    filename = os.path.abspath(frame.f_code.co_filename)
    return filename.startswith(_TS_PACKAGE_DIR)


def capture_user_source_loc() -> "tuple[str, int] | None":
    """The user's (file, line) call site for the current framework entry.

    Walks up past task_scheduling, DSL-runtime (``cutlass.base_dsl``,
    ``cutlass.cutlass_dsl``, ``cutlass._mlir``) and contextlib frames to
    the first user frame (see :func:`is_infrastructure_frame`). Runs once
    per captured object (schedule node, resource), never at kernel runtime.
    Returns ``None`` when no user frame is attributable.
    """
    frame: FrameType | None
    try:
        frame = sys._getframe(1)
    except ValueError:  # pragma: no cover - no frame support
        return None
    for _ in range(64):
        if frame is None:
            break
        if not is_infrastructure_frame(frame):
            return (frame.f_code.co_filename, frame.f_lineno)
        frame = frame.f_back
    return None


# Construction-site locations live OUTSIDE the instances: resources are user
# dataclasses, and the DSL pytree flattener (extract_dataclass_members)
# rejects any instance __dict__ key that is not a declared field, so an
# attribute like `_construction_site` breaks every kernel that carries a
# resource through a staged `if`. Keyed by id() with a liveness weakref
# because ordinary (eq=True) dataclass instances are unhashable, ruling out
# WeakKeyDictionary.
_construction_sites: "dict[int, tuple[weakref.ref, tuple[str, int]]]" = {}


def record_construction_site(obj: object) -> None:
    """Capture and remember the user construction site for ``obj``.

    Never raises: objects that do not support weak references are skipped
    (their emitted declarations fall back to an unknown location).
    """
    loc = capture_user_source_loc()
    if loc is None:
        return
    key = id(obj)
    try:
        ref = weakref.ref(obj, lambda _: _construction_sites.pop(key, None))
    except TypeError:  # pragma: no cover - weakref-less instance
        return
    _construction_sites[key] = (ref, loc)


def get_construction_site(obj: object) -> "tuple[str, int] | None":
    """The recorded user construction site of ``obj``, or ``None``."""
    entry = _construction_sites.get(id(obj))
    if entry is None:
        return None
    ref, loc = entry
    # id() values recycle after collection; the weakref proves this entry
    # belongs to this object and not a dead predecessor at the same address.
    return loc if ref() is obj else None
