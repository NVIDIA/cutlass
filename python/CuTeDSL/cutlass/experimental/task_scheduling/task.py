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
"""Task for the Task Scheduling (TS) framework.

**Compile-time abstraction**: ``Task.run()`` is traced by the DSL into a
monolithic loop.  The
captured schedule list, loop guards, and domain computation are all resolved
at trace time.  A task whose resolved domain has zero loop iterations emits no
loop-body work.  The generated PTX is identical to a hand-coded bare-metal
kernel with the same schedule.

This module provides the Task class and schedule normalisation utilities
that sit on top of the resource abstractions defined in ``resources.py``.

*Tasks* are assigned to a contiguous range of warps and bind resource roles to
a captured ``ScheduleResult``.  A task reads from its ``src_resources``
(consumer side) and writes to its ``dst_resources`` (producer side).  The
captured schedule records ordered pipeline operations such as acquire, wait,
work, commit, and release.  ``TaskManager`` executes every task: each warp
enters ``task.run()``, but only the warps in
``[warp_idx, warp_idx + num_warps)`` execute that task's schedule body.

"""

from dataclasses import dataclass
import inspect
import cutlass
import cutlass.pipeline as pipeline
import cutlass.cute as cute
from cutlass.experimental import primitives as prims

from cutlass.base_dsl.leaf_utils import TraversableLeafMixin
from collections.abc import Iterator, Sequence, Set as AbstractSet
from itertools import chain
from typing import Any, Callable, FrozenSet, Optional, List, TYPE_CHECKING
from typing import Tuple, cast
from cutlass.utils.static_persistent_tile_scheduler import (
    WorkTileInfo,
)

if TYPE_CHECKING:
    from .schedule_builder import ScheduleResult
from .enums import (
    LoopGuard,
    PipelineType,
    SignalingThreads,
    ScheduleStage,
    ScheduleStageType,
)
from .enums import PipelineGroupMode
from .memory import ResourceContext
from .resources import (
    StageInfo,
    MemoryResource,
    PipelineConfig,
    PipelineGroup,
    WorkQueue,
    SlotRouting,
    get_task_local_variables,
    _CONSUMER_WORK_FNS_ATTR,
    _PRODUCER_WORK_FNS_ATTR,
    _TS_MANAGES_CAPTURE_CONTEXT_ATTR,
    _collect_named_work_fns,
    _format_did_you_mean,
)
from .pipeline_group import _GroupMemberRef

# The scheduler annotates generated code with inline PTX comments. Targets that
# reject inline PTX asm can set ``emit_ptx_comments = False`` to suppress them
# (e.g. ``task_scheduling.task.emit_ptx_comments = False``).
emit_ptx_comments = True


def _ptx_comment(text: str) -> None:
    """Emit a PTX comment via inline PTX, unless suppressed (see above)."""
    if emit_ptx_comments:
        prims.inline_ptx("// " + text)


def _is_schedule_stage_type(value: object) -> bool:
    """Check if a value is a ScheduleStageType (phase specifier)."""
    return isinstance(value, ScheduleStageType)


def _is_loop_guard(value: object) -> bool:
    """Check if a value is a LoopGuard."""
    return isinstance(value, LoopGuard)


def _is_label(value: object) -> bool:
    """Check if a value is a user-defined work label."""
    return not _is_schedule_stage_type(value) and not _is_loop_guard(value)


def _validate_get_domain_signature(
    get_domain: Callable[..., object],
    *,
    api_name: str,
) -> None:
    """Validate the ``Task.get_domain`` method shape used by captured schedules."""
    if inspect.ismethod(get_domain) and get_domain.__self__ is not None:
        raise ValueError(
            f"{api_name} must be an unbound Task method such as "
            "`MyTask.get_domain`, not an instance-bound method."
        )
    if not callable(get_domain):
        raise ValueError(f"{api_name} must be callable.")
    try:
        signature = inspect.signature(get_domain)
    except (TypeError, ValueError) as exc:
        raise ValueError(f"{api_name} must expose a Python signature.") from exc
    params = tuple(signature.parameters.values())
    valid_kinds = (
        inspect.Parameter.POSITIONAL_ONLY,
        inspect.Parameter.POSITIONAL_OR_KEYWORD,
    )
    if (
        len(params) != 2
        or any(param.kind not in valid_kinds for param in params)
        or any(param.default is not inspect.Parameter.empty for param in params)
    ):
        raise ValueError(
            f"{api_name} must accept two required positional parameters: "
            "`self` and a work-tile coordinate."
        )


# Destination stages in the resolved slot routing that target the
# consumer side of ``dst_resource`` (i.e. write into ``consumer_vars``
# rather than ``producer_vars``).  Used by the three ``_consumer_work*``
# methods to dispatch between ``copy_consumer_vars_to`` (producer side)
# and ``copy_consumer_vars_to_consumer_of`` (consumer side).
_CONSUMER_DST_STAGES = frozenset(
    {
        ScheduleStage.ConsumerAuxWork,
        ScheduleStage.ConsumerWork,
    }
)

HeadTailEntry = tuple[MemoryResource, ScheduleStage, int, object]
HeadTailExecGroup = tuple[bool, list[HeadTailEntry]]
LoopExecGroup = tuple[LoopGuard, list[HeadTailEntry]]


def _task_local_slot_names(resource: object) -> tuple[str | None, ...]:
    """Return declared task-local slot names without tracing a comprehension."""
    return tuple(variable.slot_name for variable in get_task_local_variables(resource))


def _callable_accepts_n_args(fn: object, n_args: int) -> bool:
    """Best-effort check that ``fn`` can be called with ``n_args`` args."""
    try:
        signature = inspect.signature(fn)  # type: ignore[arg-type]
    except (TypeError, ValueError):
        # Some DSL/runtime callables do not expose an inspectable Python
        # signature. Treat them as valid and let the eventual call surface any
        # backend-specific error.
        return True
    try:
        signature.bind(*([object()] * n_args))
    except TypeError:
        return False
    return True


def _looks_like_unbound_method(fn: object) -> bool:
    """Return true when ``fn`` appears to be a class method descriptor."""
    qualname = getattr(fn, "__qualname__", "")
    owner_path = qualname.rsplit(".", 1)[0] if "." in qualname else ""
    owner_leaf = owner_path.rsplit(".", 1)[-1] if owner_path else ""
    return bool(owner_leaf and owner_leaf != "<locals>")


def _method_owner_in_work_queue_mro(
    fn: object,
    work_queue: WorkQueue,
) -> type | None:
    """Find the WorkQueue MRO owner for an unbound method, if any."""
    name = getattr(fn, "__name__", None)
    if name is None:
        return None
    for cls in type(work_queue).__mro__:
        if cls.__dict__.get(name) is fn:
            return cls
    return None


def _skip_predicate_passes_work_queue(
    skip_if: object | None,
    work_queue: WorkQueue | None,
    task_name: str,
) -> bool:
    """Validate ``skip_if`` against this task's WorkQueue call shape.

    The schedule DSL commonly passes an unbound method such as
    ``MyWorkQueue.skip_work_tile_if``.  That method must belong to the
    concrete WorkQueue instance's MRO.  Plain free functions are also
    accepted with either ``(work_queue, work_tile)`` or ``(work_tile)``.
    The returned boolean tells runtime dispatch whether to call
    ``skip_if(work_queue, work_tile)`` or ``skip_if(work_tile)``.
    """
    if skip_if is None:
        return False
    if not callable(skip_if):
        raise TypeError(f"Task {task_name!r}: 'skip_if' must be callable.")
    if work_queue is None:
        raise ValueError(
            f"Task {task_name!r}: 'skip_if' requires exactly one WorkQueue "
            "in src_resources."
        )

    bound_self = getattr(skip_if, "__self__", None)
    if bound_self is not None and not inspect.isclass(bound_self):
        if bound_self is not work_queue:
            raise TypeError(
                f"Task {task_name!r}: bound 'skip_if' must be bound to the "
                "WorkQueue instance used by the task."
            )
        if _callable_accepts_n_args(skip_if, 1):
            return False
        raise TypeError(
            f"Task {task_name!r}: 'skip_if' must accept exactly one "
            "work_tile argument when it is already bound to the WorkQueue."
        )

    owner = _method_owner_in_work_queue_mro(skip_if, work_queue)
    if owner is not None:
        if not _callable_accepts_n_args(skip_if, 2):
            raise TypeError(
                f"Task {task_name!r}: WorkQueue method 'skip_if' must accept "
                "(work_queue, work_tile)."
            )
        descriptor_get = getattr(skip_if, "__get__", None)
        if descriptor_get is not None:
            bound = descriptor_get(work_queue, type(work_queue))
            if not callable(bound) or not _callable_accepts_n_args(bound, 1):
                raise TypeError(
                    f"Task {task_name!r}: 'skip_if' is not callable for "
                    f"WorkQueue instance {type(work_queue).__name__!r}."
                )
        return True

    if _looks_like_unbound_method(skip_if):
        raise TypeError(
            f"Task {task_name!r}: unbound method 'skip_if' is not a method "
            f"of WorkQueue instance {type(work_queue).__name__!r}."
        )

    # Free functions or callable objects can request the WorkQueue instance
    # explicitly by accepting two arguments.
    if _callable_accepts_n_args(skip_if, 2):
        return True

    if _callable_accepts_n_args(skip_if, 1):
        return False

    raise TypeError(
        f"Task {task_name!r}: 'skip_if' must accept either "
        "(work_queue, work_tile) or (work_tile)."
    )


def _is_consumer_dst_stage(stage: ScheduleStage) -> bool:
    """Return True when ``stage`` targets the consumer side of dst_resource."""
    return stage in _CONSUMER_DST_STAGES


def normalize_and_validate_schedule_list(
    schedule_list: Sequence[Tuple[object, ...]],
) -> Tuple[
    List[Tuple[MemoryResource, ScheduleStage, int, object]],
    List[Tuple[MemoryResource, ScheduleStage, int, LoopGuard, object]],
    List[Tuple[MemoryResource, ScheduleStage, int, object]],
]:
    """
    Normalize and validate schedule_list.

    - Normalizes 2-element tuples to 3-element with ScheduleStageType.Loop default
    - Accepts optional 4th element (LoopGuard) for Loop entries
    - Supports optional work labels (any non-ScheduleStageType, non-LoopGuard
      value) as the last tuple element.
    - Validates ordering: all Head elements first, then Loop, then Tail
    - Pre-computes call_id for each (resource, schedule_stage) pair within each list

    Supported tuple formats (label is always the last element when present)::

        (resource, stage)                          # Loop, Always, label=None
        (resource, stage, label)                   # Loop, Always, label
        (resource, stage, phase)                   # explicit phase, label=None
        (resource, stage, phase, label)            # explicit phase + label
        (resource, stage, phase, guard)            # explicit guard, label=None
        (resource, stage, phase, guard, label)     # all explicit

    Args:
        schedule_list: List of tuples with 2-5 elements.

    Returns:
        Tuple of three lists: (head_list, loop_list, tail_list)
        head/tail contain (MemoryResource, ScheduleStage, call_id, label)
        loop contains (MemoryResource, ScheduleStage, call_id, LoopGuard, label)

    Raises:
        ValueError: If validation fails
    """
    # Each normalized entry is (resource, stage, phase, guard, label).
    normalized_schedule_list = []
    for item in schedule_list:
        n = len(item)
        resource = cast("MemoryResource | PipelineGroup | _GroupMemberRef", item[0])
        stage = cast(ScheduleStage, item[1])
        phase: object = ScheduleStageType.Loop
        guard: object = LoopGuard.Always
        label: object = None

        # ── Unwrap _GroupMemberRef and enforce group-access rules ──
        # ``ab_sync.smem_a`` evaluates to a ``_GroupMemberRef`` naming
        # both the group and the member.  For scheduling we need the
        # underlying member (the schedule still operates on the
        # member's data state), but the wrapper is what the user is
        # *required* to write when the member belongs to a group.
        #
        # Rules enforced here:
        #
        #   * Merge ``ConsumerRelease`` → must be ``(group, ...)`` at
        #     the group level (the shared empty barrier fires once
        #     per stage, releasing all members at once).
        #   * Fork ``ProducerCommit`` → must be ``(group, ...)`` at
        #     the group level (the shared full barrier fires once
        #     per stage, committing for all members at once).
        #   * All other barrier ops on a group member → must be
        #     ``(group.member, ...)``; bare ``member`` is rejected.
        if isinstance(resource, _GroupMemberRef):
            ref: _GroupMemberRef = resource
            if (
                ref.group.mode == PipelineGroupMode.Merge
                and stage == ScheduleStage.ConsumerRelease
            ):
                raise ValueError(
                    f"Merge group '{ref.group.name}': ConsumerRelease must "
                    f"be emitted on the group itself (`{ref.group.name}`), "
                    f"not on member `{ref.member.name}`.  The shared empty "
                    f"barrier fires once per stage, releasing all members "
                    f"at once."
                )
            if (
                ref.group.mode == PipelineGroupMode.Fork
                and stage == ScheduleStage.ProducerCommit
            ):
                raise ValueError(
                    f"Fork group '{ref.group.name}': ProducerCommit must "
                    f"be emitted on the group itself (`{ref.group.name}`), "
                    f"not on member `{ref.member.name}`.  The shared full "
                    f"barrier fires once per stage, committing for all "
                    f"members at once."
                )
            resource = ref.member
        elif isinstance(resource, PipelineGroup):
            if resource.mode == PipelineGroupMode.Merge:
                if stage != ScheduleStage.ConsumerRelease:
                    raise ValueError(
                        f"Merge group '{resource.name}' only accepts "
                        f"ConsumerRelease at the group level, got "
                        f"{stage.name}.  Use `{resource.name}.<member>` for "
                        f"member-level barrier ops."
                    )
            else:
                if stage != ScheduleStage.ProducerCommit:
                    raise ValueError(
                        f"Fork group '{resource.name}' only accepts "
                        f"ProducerCommit at the group level, got "
                        f"{stage.name}.  Use `{resource.name}.<member>` for "
                        f"member-level barrier ops."
                    )
        else:
            # Bare member of *some* group is forbidden — must use the
            # group-qualified form so the barrier identity is explicit.
            pg = getattr(resource, "pipeline_group", None)
            if pg is not None:
                raise ValueError(
                    f"Resource '{resource.name}' is a member of "
                    f"PipelineGroup '{pg.name}' and must be accessed via "
                    f"`{pg.name}.{resource.name}` in schedule entries "
                    f"(bare member resources are not allowed in "
                    f"schedule_list once joined to a group)."
                )

        if n == 2:
            pass  # defaults are fine
        elif n == 3:
            third = item[2]
            if _is_schedule_stage_type(third):
                phase = third
            else:
                label = third
        elif n == 4:
            third, fourth = item[2], item[3]
            if _is_schedule_stage_type(third):
                phase = third
                if _is_loop_guard(fourth):
                    guard = fourth
                else:
                    label = fourth
            else:
                raise ValueError(
                    f"schedule_list 3rd element must be a ScheduleStageType "
                    f"when 4 elements are provided, got {type(third)}"
                )
        elif n == 5:
            phase, guard, label = item[2], item[3], item[4]
            if not _is_schedule_stage_type(phase):
                raise ValueError(
                    f"schedule_list 3rd element must be a ScheduleStageType, "
                    f"got {type(phase)}"
                )
            if not _is_loop_guard(guard):
                raise ValueError(
                    f"schedule_list 4th element must be a LoopGuard, got {type(guard)}"
                )
        else:
            raise ValueError(
                f"schedule_list items must be tuples of 2-5 elements, got {n} elements"
            )

        # Map LoopFirstIter/LoopLastIter shorthands to Loop + guard
        if phase == ScheduleStageType.LoopFirstIter:
            phase = ScheduleStageType.Loop
            guard = LoopGuard.FirstIter
        elif phase == ScheduleStageType.LoopLastIter:
            phase = ScheduleStageType.Loop
            guard = LoopGuard.LastIter

        if guard != LoopGuard.Always and phase != ScheduleStageType.Loop:
            raise ValueError(
                f"LoopGuard can only be used with ScheduleStageType.Loop "
                f"entries, got {phase}"
            )

        if not isinstance(phase, ScheduleStageType):
            raise ValueError(
                f"schedule_list phase must be a ScheduleStageType enum, "
                f"got {type(phase)}"
            )

        normalized_schedule_list.append((resource, stage, phase, guard, label))

    # Validate ordering: all Head elements first, then Loop, then Tail
    stage_types = [item[2] for item in normalized_schedule_list]
    if stage_types:
        valid_order = [
            ScheduleStageType.Head,
            ScheduleStageType.Loop,
            ScheduleStageType.Tail,
        ]
        order_map = {stage_type: idx for idx, stage_type in enumerate(valid_order)}

        current_type = None
        for idx, stage_type in enumerate(stage_types):
            if current_type is None:
                current_type = stage_type
            elif stage_type != current_type:
                current_order = order_map.get(current_type)
                next_order = order_map.get(stage_type)

                if current_order is None or next_order is None:
                    raise ValueError(
                        f"schedule_list contains invalid stage type. "
                        f"Expected ScheduleStageType enum, got '{stage_type}'"
                    )

                if next_order <= current_order:
                    raise ValueError(
                        f"schedule_list must have continuous sections: all Head "
                        f"elements first, then Loop, then Tail. Found invalid "
                        f"transition from '{current_type}' to '{stage_type}' "
                        f"at index {idx}."
                    )

                current_type = stage_type

    # Split into head, loop, and tail lists
    head_list_raw = [
        item for item in normalized_schedule_list if item[2] == ScheduleStageType.Head
    ]
    loop_list_raw = [
        item for item in normalized_schedule_list if item[2] == ScheduleStageType.Loop
    ]
    tail_list_raw = [
        item for item in normalized_schedule_list if item[2] == ScheduleStageType.Tail
    ]

    # Pre-compute call_id for each (resource, schedule_stage) pair within each list
    def compute_call_ids(
        items: list,
        keep_guard: bool = False,
    ) -> list:
        call_counts: dict = {}
        result: list = []
        for item in items:
            resource, schedule_stage = item[0], item[1]
            label = item[4]
            key = (id(resource), schedule_stage)
            call_idx = call_counts.get(key, 0)
            call_counts[key] = call_idx + 1
            if keep_guard:
                guard = item[3]
                result.append((resource, schedule_stage, call_idx, guard, label))
            else:
                result.append((resource, schedule_stage, call_idx, label))
        return result

    head_list = compute_call_ids(head_list_raw)
    loop_list = compute_call_ids(loop_list_raw, keep_guard=True)
    tail_list = compute_call_ids(tail_list_raw)

    return head_list, loop_list, tail_list


@dataclass
class Task(TraversableLeafMixin):
    """A unit of warp-specialised work in the TS framework.

    A Task maps a contiguous range of warps to a pair of resource lists
    (``src_resources`` consumed by the task and ``dst_resources`` produced
    by the task).  Its schedule is supplied only as a ``ScheduleResult``
    captured by the ``@schedule`` decorator.  The captured schedule defines
    the pipeline operations (e.g. wait, acquire, work, commit, release)
    executed each iteration of the main loop over the computational domain.

    The captured schedule list is normalized into three phases
    (head / loop / tail) at construction time.

    Attributes
    ----------
    name : str
        Human-readable label used in debug prints and PTX comments.
    src_resources : List[MemoryResource]
        Resources from which this task reads (consumer side).
    dst_resources : List[MemoryResource]
        Resources to which this task writes (producer side).
    warp_idx : cutlass.Int32
        Index of the first warp assigned to this task.
    num_warps : int
        Number of consecutive warps assigned to this task.
    num_registers : int | None
        Per-task register budget (must be 8-256, divisible by 8).
        ``setmaxregister_increase/decrease`` is emitted accordingly.
    schedule : ScheduleResult
        Captured output of the ``@schedule`` decorator.  It supplies the
        schedule list, loop bounds, loop step, unroll hint, routing table,
        and any persistent-work-tile metadata.
    domain_getter : callable | None
        Explicit ``Task`` subclass method captured from the callable ``end``
        bound, e.g. ``domain_loop(MyTask.get_domain)``.  When present, ``Task``
        validates that this instance inherits that exact ``get_domain`` override.
    is_persistent : bool
        ``True`` when ``src_resources`` contains a ``WorkQueue``.
    run_only_on_cta_id : int | None
        Hoist CTA selection for the whole task body to one explicit CTA rank.
        When set, the CTA-rank check is hoisted into ``is_selected()`` so the
        entire task body, including all pipeline operations, runs only on that
        CTA.  Requires that every pipelined resource touched by this task sets
        the matching signaling side to ``SignalingThreads.CtaLeader``; a
        ``ValueError`` is raised at trace time otherwise.
    debug_print : bool
        Emit per-step debug prints to stdout (default: False).

    head_schedule_list, loop_schedule_list, tail_schedule_list
        Normalised schedule phases, each a list of
        ``(MemoryResource, ScheduleStage, call_id)`` tuples.
    """

    # Thread ``self`` through dynamic control flow on the legacy frontend.
    # Task methods mutate pipeline state (mbarrier phases, producer/consumer
    # cursors) reachable through ``self`` from inside dynamic for/while/if
    # regions, so ``self`` must be carried as region state -- otherwise
    # sibling warp-specialized regions read region-internal SSA values
    # ("operand does not dominate this use"). See ``is_read_only_object`` in
    # cutlass_dsl/cutlass.py.
    _dsl_thread_self_in_staged_cf = True

    def __init__(
        self,
        src_resources: List[MemoryResource],
        dst_resources: List[MemoryResource],
        warp_idx: int,
        num_warps: int,
        *,
        schedule: "ScheduleResult",
        num_registers: Optional[int] = None,
        name: str = "",
        debug_print: bool = False,
        # Hoist the CTA-leader gate into is_selected() so the entire
        # task body runs only on CTA 0.  See class docstring for details.
        run_only_on_cta_id: Optional[int] = None,
    ) -> None:
        """Create a task from a captured schedule.

        ``schedule`` is the sole source of schedule metadata.  It
        supplies the schedule list, slot routing, loop bounds, loop step,
        unroll hint, skip predicate, and persistent-work-tile placement
        metadata captured by the ``@schedule`` decorator.

        Parameters
        ----------
        src_resources : List[MemoryResource]
            Resources read by this task on the consumer side.
        dst_resources : List[MemoryResource]
            Resources written by this task on the producer side.
        warp_idx : int
            Index of the first warp assigned to this task.
        num_warps : int
            Number of consecutive warps assigned to this task.
        schedule : object
            Captured result returned by a ``@schedule`` function.  Must be
            provided; legacy constructor schedule metadata is not accepted by
            this API.
        num_registers : int, optional
            Per-task register budget.  When set, it must be in ``[8, 256]`` and
            divisible by 8.
        name : str, optional
            Human-readable task name used in diagnostics and PTX comments.
        debug_print : bool, optional
            Emit per-step debug prints from generated code.

        run_only_on_cta_id : int, optional
            Hoist task selection so all task work runs only on the given CTA
            rank.  Requires matching CTA-leader signaling on every pipelined
            resource touched by the task.
        """
        if schedule is None:
            raise ValueError(
                f"Task {name!r}: 'schedule' is required. "
                "Build it with the @schedule decorator and pass "
                "`schedule=<captured result>`."
            )
        # The @schedule front-end returns a Schedule tree, but this legacy
        # runtime consumes the flat ScheduleResult bundle.  Auto-lower a tree via
        # the adapter so callers can pass the @schedule result directly.  Imports
        # are lazy to keep the tree builder / adapter off task.py's load path.
        from .schedule_builder import Schedule

        if isinstance(schedule, Schedule):
            from .schedule_legacy_adapter import lower_to_legacy

            schedule = lower_to_legacy(schedule)
        schedule_list = schedule.schedule_list
        slot_routing = schedule.slot_routing
        constexpr_work_kwargs = getattr(schedule, "constexpr_work_kwargs", None)
        domain_getter = getattr(schedule, "domain_getter", None)
        if schedule.loop_end is None and domain_getter is None:
            raise ValueError(
                f"Task {name!r}: schedule has no static domain. "
                "Pass a callable `end` bound -- `domain_loop(MyTask.get_domain)` "
                "-- for per-work-tile domains."
            )
        domain = schedule.loop_end
        domain_start = schedule.loop_start if schedule.loop_start is not None else 0
        step = schedule.loop_step if schedule.loop_step is not None else 1
        unroll = schedule.unroll
        skip_if = schedule.skip_if
        pre_work_loop_head_slots = schedule.pre_work_loop_head_slots
        post_work_loop_tail_slots = schedule.post_work_loop_tail_slots
        skippable_head_slots = schedule.skippable_head_slots
        skippable_tail_slots = schedule.skippable_tail_slots

        self.name = name
        self.src_resources = src_resources
        self.dst_resources = dst_resources
        self.warp_idx = warp_idx
        self.num_warps = num_warps
        self.num_registers = num_registers
        self.default_num_registers = 128
        self.warp_start = self.warp_idx
        self.warp_end = self.warp_idx + self.num_warps
        if domain is None and domain_getter is None:
            raise ValueError(
                f"Task {name!r}: `domain=None` requires "
                "`domain_getter=MyTask.get_domain`."
            )
        self.domain: Any = domain if domain is not None else 0
        self.domain_getter = domain_getter
        if self.domain_getter is not None:
            self._validate_domain_getter_reference(self.domain_getter)
        self.domain_start: Any = domain_start
        if isinstance(step, int) and step == 0:
            raise ValueError(f"Task {name!r}: 'step' must be non-zero.")
        self.step: Any = step
        self.is_persistent = any(
            isinstance(res, WorkQueue) for res in self.src_resources
        )
        self.debug_print = debug_print
        if run_only_on_cta_id is not None:
            if type(run_only_on_cta_id) is not int or run_only_on_cta_id < 0:
                raise ValueError(
                    f"Task {name!r}: 'run_only_on_cta_id' must be a "
                    f"non-negative int, got {run_only_on_cta_id!r}"
                )
        self.run_only_on_cta_id = run_only_on_cta_id
        self.captured_schedule = True
        self.pre_work_loop_head_slots = frozenset(pre_work_loop_head_slots or ())
        self.post_work_loop_tail_slots = frozenset(post_work_loop_tail_slots or ())
        self.skippable_head_slots = frozenset(skippable_head_slots or ())
        self.skippable_tail_slots = frozenset(skippable_tail_slots or ())
        # Keep type narrow since user might pass a bool by mistake.
        if unroll is not None and type(unroll) is not int:
            raise ValueError(
                f"Task {name!r}: 'unroll' must be a compile-time int or None."
            )
        self.unroll = unroll
        self.work_queue = None
        self.work_queue_idx = None
        if self.is_persistent:
            work_queues = [
                (i, res)
                for i, res in enumerate(self.src_resources)
                if isinstance(res, WorkQueue)
            ]
            if len(work_queues) != 1:
                raise ValueError(
                    "Exactly one WorkQueue must be present in src_resources when "
                    "is_persistent is True, "
                    f"found {len(work_queues)}"
                )
            self.work_queue_idx = work_queues[0][0]
            self.work_queue = work_queues[0][1]
        self.skip_if = skip_if
        self._skip_if_passes_work_queue = _skip_predicate_passes_work_queue(
            skip_if, self.work_queue, name
        )
        self._has_skip_if = skip_if is not None
        # User-supplied slot-to-slot variable-flow routing.  This is the
        # single source of truth consumed by the runtime dispatch in
        # ``_consumer_work*``: for each writer slot it lists which
        # variables flow to which reader slots (producer-side or
        # consumer-side).  ``None`` means "no explicit routing" — the
        # task falls back to the legacy broadcast of every matching
        # consumer var to every ``dst_resource``.
        #
        # The ``TaskManager`` validates this dict at build time
        # (see ``_verify_slot_routing``) against stage legality,
        # call-idx ranges, schedule ordering (linear or body
        # loop-carry), and the most-recent-writer rule.
        self.slot_routing: SlotRouting | None = slot_routing
        # Per-step compile-time ``cutlass.Constexpr`` work-kwargs, keyed on the
        # work-call slot (the same ``routing_slot`` identity ``_create_stage_info``
        # computes). Auto-forwarded to the work method via ``StageInfo.work_kwargs``.
        self.constexpr_work_kwargs: dict | None = constexpr_work_kwargs

        # Validate and normalize schedule_list
        (
            self.head_schedule_list,
            self.loop_schedule_list,
            self.tail_schedule_list,
        ) = normalize_and_validate_schedule_list(schedule_list)
        # Pre-compute HEAD/TAIL execution groups. Consecutive entries with the
        # same skip_if behavior are emitted under one dynamic guard, which keeps
        # IR state threading consistent for pipeline-state updates.
        self._head_exec_groups = self._make_head_tail_exec_groups(
            self.head_schedule_list,
            self.skippable_head_slots,
            self.pre_work_loop_head_slots,
        )
        self._tail_exec_groups = self._make_head_tail_exec_groups(
            self.tail_schedule_list,
            self.skippable_tail_slots,
            self.post_work_loop_tail_slots,
        )
        self._producer_work_follow_acquire_slots = (
            self._make_producer_work_follow_acquire_slots()
        )
        self._advance_on_acquire_state_resources = (
            self._make_advance_on_acquire_state_resources()
        )
        # Pre-compute execution groups for the K-loop: consecutive entries
        # with the same LoopGuard are merged into a single group so they
        # execute inside one scf.if block (e.g. two LastIter releases
        # share a single scf.if(is_last_iter)).
        self._loop_exec_groups: list[LoopExecGroup] = []
        for resource, schedule_stage, call_id, guard, label in self.loop_schedule_list:
            if self._loop_exec_groups and self._loop_exec_groups[-1][0] == guard:
                self._loop_exec_groups[-1][1].append(
                    (resource, schedule_stage, call_id, label)
                )
            else:
                self._loop_exec_groups.append(
                    (guard, [(resource, schedule_stage, call_id, label)])
                )
        self._has_last_iter = any(
            guard == LoopGuard.LastIter for guard, _ in self._loop_exec_groups
        )
        # Fallback lists for domain-0 (no loop iterations): splice guarded
        # entries into the head+tail path so their side effects still fire.
        self.loop_first_iter_fallback_list = [
            (r, s, c, lbl)
            for r, s, c, g, lbl in self.loop_schedule_list
            if g == LoopGuard.FirstIter
        ]
        self.loop_last_iter_fallback_list = [
            (r, s, c, lbl)
            for r, s, c, g, lbl in self.loop_schedule_list
            if g == LoopGuard.LastIter
        ]
        if self.num_registers is not None:
            assert (
                self.num_registers > 0
                and self.num_registers <= 256
                and self.num_registers % 8 == 0
            ), (
                "num_registers must be between 8 and 256 and divisible by 8, "
                f"got {self.num_registers}"
            )

    @property
    def resources(self) -> chain:
        """Iterate over all resources (src then dst) without duplicates."""
        return chain(self.src_resources, self.dst_resources)

    @staticmethod
    def _make_head_tail_exec_groups(
        section_schedule_list: Sequence[HeadTailEntry],
        skippable_slots: AbstractSet[tuple[int, ScheduleStage, int]],
        outside_work_loop_slots: AbstractSet[tuple[int, ScheduleStage, int]],
    ) -> list[HeadTailExecGroup]:
        """Group consecutive HEAD/TAIL entries by skipped-tile behavior."""
        exec_groups: list[HeadTailExecGroup] = []
        for resource, schedule_stage, call_id, label in section_schedule_list:
            if (id(resource), schedule_stage, call_id) in outside_work_loop_slots:
                continue
            is_skippable = (id(resource), schedule_stage, call_id) in skippable_slots
            entry = (resource, schedule_stage, call_id, label)
            if exec_groups and exec_groups[-1][0] == is_skippable:
                exec_groups[-1][1].append(entry)
            else:
                exec_groups.append((is_skippable, [entry]))
        return exec_groups

    def _make_producer_work_follow_acquire_slots(
        self,
    ) -> frozenset[object]:
        """Return producer-work slots that follow acquire in this task.

        ``advance_on_acquire`` advances the acquire cursor before producer work
        runs.  Head, loop, and tail entries form one contiguous task schedule:
        once the task has acquired a resource, later ProducerWork slots for
        that resource use the just-acquired state.  Split producer-work tasks
        without acquire follow commit state.

        Slots are identified by their routing slot (:meth:`_routing_slot`) so
        the membership test in :meth:`_producer_work_uses_acquire_state_for_stage_info`
        keys on the same per-step identity used by the executor.
        """
        acquired_resource_ids: set[int] = set()
        follow_acquire_slots: set[object] = set()

        def loop_entries_without_guard() -> Iterator[HeadTailEntry]:
            for (
                resource,
                schedule_stage,
                call_idx,
                _guard,
                label,
            ) in self.loop_schedule_list:
                yield resource, schedule_stage, call_idx, label

        for stage_type, entries in (
            (ScheduleStageType.Head, self.head_schedule_list),
            (ScheduleStageType.Loop, loop_entries_without_guard()),
            (ScheduleStageType.Tail, self.tail_schedule_list),
        ):
            for resource, schedule_stage, call_idx, _label in entries:
                resource_id = id(resource)
                if schedule_stage == ScheduleStage.ProducerAcquire:
                    acquired_resource_ids.add(resource_id)
                elif (
                    schedule_stage == ScheduleStage.ProducerWork
                    and resource_id in acquired_resource_ids
                ):
                    follow_acquire_slots.add(
                        self._routing_slot(
                            resource, schedule_stage, stage_type, call_idx
                        )
                    )

        return frozenset(follow_acquire_slots)

    def _make_advance_on_acquire_state_resources(self) -> tuple[MemoryResource, ...]:
        """Return producer resources that need explicit split-cursor threading.

        These are the resources for which generated control-flow regions must
        carry acquire cursor, commit cursor, and producer status as a tuple.
        This mirrors the normal resource state, but makes the IR dataflow
        explicit at loop/body boundaries.
        """
        resources: list[MemoryResource] = []
        seen_resource_ids: set[int] = set()

        for entries in (
            self.head_schedule_list,
            [(r, s, c, lbl) for r, s, c, _g, lbl in self.loop_schedule_list],
            self.tail_schedule_list,
        ):
            for resource, schedule_stage, _call_idx, _label in entries:
                if (
                    id(resource) in seen_resource_ids
                    or isinstance(resource, PipelineGroup)
                    or schedule_stage == ScheduleStage.ProducerAuxWork
                    or not self._is_producer_stage(schedule_stage)
                ):
                    continue
                seen_resource_ids.add(id(resource))
                resources.append(resource)

        return tuple(resources)

    def _validate_domain_getter_reference(
        self,
        domain_getter: Callable[..., object],
    ) -> None:
        """Validate that an explicit domain provider belongs to this task class."""
        _validate_get_domain_signature(
            domain_getter,
            api_name=f"Task {self.name!r} domain_getter",
        )
        owner_cls = None
        for cls in type(self).__mro__:
            if cls.__dict__.get("get_domain") is domain_getter:
                owner_cls = cls
                break
        if owner_cls is None:
            raise ValueError(
                f"Task {self.name!r}: the `domain_loop(...)` end callable must "
                f"reference a `get_domain` method inherited by "
                f"{type(self).__name__}."
            )
        if owner_cls is Task:
            raise ValueError(
                f"Task {self.name!r}: the `domain_loop(...)` end callable must "
                "reference a `get_domain` override on a Task subclass."
            )

    def _set_max_register(self) -> None:
        """Emit a ``setmaxregister`` instruction for this task's register budget.

        Uses ``setmaxregister_increase`` when the budget exceeds the kernel's
        computed default register budget and ``setmaxregister_decrease``
        otherwise.  No-op when ``num_registers`` is ``None``.
        """
        if self.num_registers is None:
            return
        if self.num_registers > self.default_num_registers:
            prims.setmaxregister(
                self.num_registers, prims.SetMaxRegisterAction.INCREASE
            )
        else:
            prims.setmaxregister(
                self.num_registers, prims.SetMaxRegisterAction.DECREASE
            )

    def get_domain(self, tile_coord: object) -> Any:
        """Return the iteration domain for the given tile coordinate.

        Override in subclasses for tile-dependent domain logic.
        The default implementation returns ``self.domain``.

        Parameters
        ----------
        tile_coord : object
            ``work_tile.tile_idx`` – a 3-tuple ``(bx, by, bz)`` of the
            current tile's block coordinates.

        Returns
        -------
        int or cutlass.Int32
            The number of loop iterations for this tile.
        """
        return self.domain

    @cute.jit
    def _print_stage_info(
        self, resource: MemoryResource, stage_info: StageInfo, stage_name: str
    ) -> None:
        """Emit a runtime debug print (block 0, elected thread only)."""

        # Should be const_expr for zero-cost if-else
        if cutlass.const_expr(self.debug_print):
            bx, by, bz = cute.arch.block_idx()
            tx, ty, tz = cute.arch.thread_idx()
            assert stage_info.work_tile is not None
            wx, wy, wz = stage_info.work_tile.tile_idx
            if prims.elect_sync() and bx < 2 and by == 0 and bz == 0:
                prims.print_runtime(
                    "["
                    + self.name
                    + " : "
                    + resource.name
                    + " | "
                    + stage_name
                    + "], LoopIdx = {},"
                    + " T(x,y,z) = ({},{},{}),"
                    + " CTA(x,y,z) = ({},{},{}),"
                    + " WorkTile(x,y,z) = ({},{},{})\n",
                    stage_info.loop_offset,
                    tx,
                    ty,
                    tz,
                    bx,
                    by,
                    bz,
                    wx,
                    wy,
                    wz,
                )

    def _run_group_entries(
        self,
        entries: list[HeadTailEntry],
        idx: Any,
        work_tile: WorkTileInfo,
        resolved_domain: Any,
        context: Optional[ResourceContext],
    ) -> None:
        """Execute a group of (resource, schedule_stage, call_id, label) entries.

        Plain Python method (not @cute.jit) so the AST preprocessor does
        not try to yield local variables (e.g. ``stage_info``) as scf.if
        write_args when called inside a dynamic guard like
        ``if is_last_iter:``.
        """
        for r, s, c, lbl in entries:
            # ``PipelineGroup``s never appear in ``src_resources`` /
            # ``dst_resources`` (only their members do), but they are
            # valid schedule targets for group-level stages such as
            # Merge ``ConsumerRelease``.  ``normalize_and_validate_schedule_list``
            # already checks that such a group is only used when at
            # least one of its members is referenced by the task.
            assert r in self.resources or isinstance(r, PipelineGroup)
            is_producer = self._is_producer_stage(s)
            work_method = self._resolve_work_method(
                r,
                s,
                lbl,
                require_label_for_named=self.captured_schedule,
            )
            routing_slot = self._routing_slot(r, s, ScheduleStageType.Loop, c)
            if cutlass.const_expr(
                is_producer
                and s != ScheduleStage.ProducerAuxWork
                and not isinstance(r, PipelineGroup)
                and r.pipeline_config is not None
                and r.pipeline_config.advance_on_acquire
            ):
                self._run_advance_on_acquire_schedule_entry(
                    r,
                    s,
                    work_method,
                    idx,
                    work_tile,
                    is_producer,
                    resolved_domain,
                    routing_slot,
                    context,
                    label=lbl,
                )
            else:
                si = self._create_stage_info(
                    r,
                    idx,
                    work_tile,
                    is_producer,
                    resolved_domain,
                    label=lbl,
                    schedule_stage=s,
                    routing_slot=routing_slot,
                    context=context,
                )
                self._run_step(r, si, s, work_method, routing_slot)
    def _run_head_entry(
        self,
        resource: MemoryResource,
        schedule_stage: ScheduleStage,
        call_id_head: int,
        label_head: object,
        work_tile: WorkTileInfo,
        resolved_domain: Any,
        context: Optional[ResourceContext],
    ) -> None:
        """Execute one HEAD schedule entry."""
        assert resource in self.resources or isinstance(resource, PipelineGroup), (
            "Resource from head schedule list is not found in resources"
        )
        is_producer_head = self._is_producer_stage(schedule_stage)

        work_method_head = self._resolve_work_method(
            resource,
            schedule_stage,
            label_head,
            require_label_for_named=self.captured_schedule,
        )

        routing_slot = self._routing_slot(
            resource, schedule_stage, ScheduleStageType.Head, call_id_head
        )
        if cutlass.const_expr(
            is_producer_head
            and schedule_stage != ScheduleStage.ProducerAuxWork
            and not isinstance(resource, PipelineGroup)
            and resource.pipeline_config is not None
            and resource.pipeline_config.advance_on_acquire
        ):
            self._run_advance_on_acquire_schedule_entry(
                resource,
                schedule_stage,
                work_method_head,
                0,
                work_tile,
                is_producer_head,
                resolved_domain,
                routing_slot,
                context,
                label=label_head,
            )
        else:
            stage_info_head = self._create_stage_info(
                resource,
                0,
                work_tile,
                is_producer_head,
                resolved_domain,
                label=label_head,
                schedule_stage=schedule_stage,
                routing_slot=routing_slot,
                context=context,
            )
            self._run_step(
                resource,
                stage_info_head,
                schedule_stage,
                work_method_head,
                routing_slot,
            )

    def _run_head_entry_group(
        self,
        entries: list[HeadTailEntry],
        work_tile: WorkTileInfo,
        resolved_domain: object,
        context: Optional[ResourceContext],
    ) -> None:
        """Execute a grouped set of HEAD schedule entries."""
        for resource, schedule_stage, call_id_head, label_head in entries:
            self._run_head_entry(
                resource,
                schedule_stage,
                call_id_head,
                label_head,
                work_tile,
                resolved_domain,
                context,
            )

    def _run_tail_entry(
        self,
        resource: MemoryResource,
        schedule_stage: ScheduleStage,
        call_id_tail: int,
        label_tail: object,
        work_tile: WorkTileInfo,
        resolved_domain: Any,
        context: Optional[ResourceContext],
    ) -> None:
        """Execute one TAIL schedule entry."""
        assert resource in self.resources or isinstance(resource, PipelineGroup), (
            "Resource from tail schedule list is not found in resources"
        )
        is_producer_tail = self._is_producer_stage(schedule_stage)

        work_method_tail = self._resolve_work_method(
            resource,
            schedule_stage,
            label_tail,
            require_label_for_named=self.captured_schedule,
        )

        routing_slot = self._routing_slot(
            resource, schedule_stage, ScheduleStageType.Tail, call_id_tail
        )
        # Tail's loop offset is the final iteration's index, not resolved_domain - 1.
        _, tail_loop_offset = self._peeled_loop_bounds(
            self.domain_start, resolved_domain, self.step
        )
        if cutlass.const_expr(
            is_producer_tail
            and schedule_stage != ScheduleStage.ProducerAuxWork
            and not isinstance(resource, PipelineGroup)
            and resource.pipeline_config is not None
            and resource.pipeline_config.advance_on_acquire
        ):
            self._run_advance_on_acquire_schedule_entry(
                resource,
                schedule_stage,
                work_method_tail,
                tail_loop_offset,
                work_tile,
                is_producer_tail,
                resolved_domain,
                routing_slot,
                context,
                label=label_tail,
            )
        else:
            stage_info_tail = self._create_stage_info(
                resource,
                tail_loop_offset,
                work_tile,
                is_producer_tail,
                resolved_domain,
                label=label_tail,
                schedule_stage=schedule_stage,
                routing_slot=routing_slot,
                context=context,
            )
            self._run_step(
                resource,
                stage_info_tail,
                schedule_stage,
                work_method_tail,
                routing_slot,
            )

    def _run_tail_entry_group(
        self,
        entries: list[HeadTailEntry],
        work_tile: WorkTileInfo,
        resolved_domain: object,
        context: Optional[ResourceContext],
    ) -> None:
        """Execute a grouped set of TAIL schedule entries."""
        for resource, schedule_stage, call_id_tail, label_tail in entries:
            self._run_tail_entry(
                resource,
                schedule_stage,
                call_id_tail,
                label_tail,
                work_tile,
                resolved_domain,
                context,
            )

    @staticmethod
    def _peeled_loop_bounds(start: Any, end: Any, step: Any) -> tuple[Any, Any]:
        """Trip count and final visited index of ``range(start, end, step)``.

        Callers must guarantee at least one iteration (``end > start``).
        """
        num_iters = (end - start + step - 1) // step
        last_idx = start + (num_iters - 1) * step
        return num_iters, last_idx

    @cute.jit
    def _run_loop_simple(
        self,
        resolved_domain: Any,
        work_tile: WorkTileInfo,
        context: Optional[ResourceContext],
    ) -> None:
        """K-loop without loop peeling (no LastIter entries)."""
        # Keep the steady-state task body as a staged runtime loop.  The
        # unroll hint comes from ``self.unroll`` (default ``1`` =
        # disabled; ``None`` -> ``-1`` lets cutlass/ptxas decide).
        _unroll = -1 if self.unroll is None else self.unroll
        for idx in cutlass.range(
            self.domain_start,
            resolved_domain,
            self.step,
            unroll=_unroll,
        ):
            is_first_iter = idx == self.domain_start
            for group_guard, group_entries in self._loop_exec_groups:
                if cutlass.const_expr(group_guard == LoopGuard.Always):
                    self._run_group_entries(
                        group_entries,
                        idx,
                        work_tile,
                        resolved_domain,
                        context,
                    )
                elif cutlass.const_expr(group_guard == LoopGuard.FirstIter):
                    if is_first_iter:
                        self._run_group_entries(
                            group_entries,
                            idx,
                            work_tile,
                            resolved_domain,
                            context,
                        )

    @cute.jit
    def _run_loop_peeled(
        self,
        resolved_domain: Any,
        work_tile: WorkTileInfo,
        context: Optional[ResourceContext],
    ) -> None:
        """K-loop with last-iteration peeling for LastIter entries.

        Runs iterations 0..N-2 inside an scf.for (Always + FirstIter only),
        then executes the last iteration as straight-line code outside the
        loop (Always + LastIter + FirstIter-if-only-iter).  This avoids a
        conditional ``scf.if(is_last_iter)`` inside the scf.for which
        triggers a ptxas codegen bug in persistent mode.
        """
        # Zero-iteration domain: do not execute peeled-last body.
        # The peeled path is only valid when at least one loop iteration exists.
        if resolved_domain > self.domain_start:
            num_iters, last_idx = self._peeled_loop_bounds(
                self.domain_start, resolved_domain, self.step
            )
            # Main loop: iterations domain_start to N-2
            # Same rationale as _run_loop_simple: preserve one compact staged loop
            # for the peeled steady-state region
            _unroll = -1 if self.unroll is None else self.unroll
            for idx in cutlass.range(
                self.domain_start,
                last_idx,
                self.step,
                unroll=_unroll,
            ):
                is_first_iter = idx == self.domain_start
                for group_guard, group_entries in self._loop_exec_groups:
                    if cutlass.const_expr(group_guard == LoopGuard.Always):
                        self._run_group_entries(
                            group_entries,
                            idx,
                            work_tile,
                            resolved_domain,
                            context,
                        )
                    elif cutlass.const_expr(group_guard == LoopGuard.FirstIter):
                        if is_first_iter:
                            self._run_group_entries(
                                group_entries,
                                idx,
                                work_tile,
                                resolved_domain,
                                context,
                            )
                    # LastIter entries skipped in main loop

            # Peeled last iteration: Always + LastIter groups, plus FirstIter
            # only when this is the sole iteration.
            is_only_iter = num_iters == 1
            for group_guard, group_entries in self._loop_exec_groups:
                if cutlass.const_expr(group_guard == LoopGuard.Always):
                    self._run_group_entries(
                        group_entries,
                        last_idx,
                        work_tile,
                        resolved_domain,
                        context,
                    )
                elif cutlass.const_expr(group_guard == LoopGuard.FirstIter):
                    # Only runs if N=1 (last is also first)
                    if is_only_iter:
                        self._run_group_entries(
                            group_entries,
                            last_idx,
                            work_tile,
                            resolved_domain,
                            context,
                        )
                elif cutlass.const_expr(group_guard == LoopGuard.LastIter):
                    # Runs unconditionally — no scf.if needed
                    self._run_group_entries(
                        group_entries,
                        last_idx,
                        work_tile,
                        resolved_domain,
                        context,
                    )

    @cute.jit
    def _run_step(
        self,
        resource: MemoryResource,
        stage_info: StageInfo,
        schedule_stage: ScheduleStage,
        work_method: Optional[Callable[..., object]] = None,
        routing_slot: object = None,
    ) -> None:
        """Dispatch a single ``ScheduleStage`` to the corresponding handler.

        ``work_method`` is the pre-resolved callable for
        ``ConsumerWork`` / ``ProducerWork`` entries (from
        ``_resolve_work_method``).  Ignored for all other stages.

        ``routing_slot`` is the executor-supplied step identity (from
        :meth:`_routing_slot`); it drives both the consumer-side ``slot_routing``
        lookup and this step's captured constexpr ``work_kwargs``.

        Wraps the actual operation with optional before/after debug prints.
        """
        # Look up the step's captured constexpr work-kwargs once, keyed by the
        # routing slot, and forward them to the work handlers below.
        work_kwargs = None
        if cutlass.const_expr(self.constexpr_work_kwargs is not None):
            assert self.constexpr_work_kwargs is not None
            work_kwargs = self.constexpr_work_kwargs.get(routing_slot)

        if cutlass.const_expr(self.debug_print):
            prefix = "Before" + schedule_stage.value
            self._print_stage_info(resource, stage_info, prefix)

        if cutlass.const_expr(schedule_stage == ScheduleStage.ConsumerRelease):
            self._consumer_release(resource, stage_info)
        elif cutlass.const_expr(schedule_stage == ScheduleStage.ConsumerTryWait):
            self._consumer_try_wait(resource, stage_info)
        elif cutlass.const_expr(schedule_stage == ScheduleStage.ConsumerWait):
            self._consumer_wait(resource, stage_info)
        elif cutlass.const_expr(schedule_stage == ScheduleStage.ConsumerAuxWork):
            self._consumer_aux_work(
                resource, stage_info, work_method, routing_slot, work_kwargs
            )
        elif cutlass.const_expr(schedule_stage == ScheduleStage.ConsumerWork):
            self._consumer_work(
                resource, stage_info, work_method, routing_slot, work_kwargs
            )
        elif cutlass.const_expr(schedule_stage == ScheduleStage.ProducerAuxWork):
            self._producer_aux_work(resource, stage_info, work_method, work_kwargs)
        elif cutlass.const_expr(schedule_stage == ScheduleStage.ProducerTryAcquire):
            self._producer_try_acquire(resource, stage_info)
        elif cutlass.const_expr(schedule_stage == ScheduleStage.ProducerAcquire):
            self._producer_acquire(resource, stage_info)
        elif cutlass.const_expr(schedule_stage == ScheduleStage.ProducerCommit):
            self._producer_commit(resource, stage_info)
        elif cutlass.const_expr(schedule_stage == ScheduleStage.ProducerWork):
            self._producer_work(resource, stage_info, work_method, work_kwargs)
        else:
            raise ValueError(f"Invalid schedule stage: {schedule_stage}")

        if cutlass.const_expr(self.debug_print):
            suffix = "After" + schedule_stage.value
            self._print_stage_info(resource, stage_info, suffix)

    @staticmethod
    def _resolve_work_method(
        resource: MemoryResource,
        schedule_stage: ScheduleStage,
        label: object,
        *,
        require_label_for_named: bool = True,
    ) -> Optional[Callable[..., object]]:
        """Resolve the work callable at compile time (pure Python, no JIT).

        For ``ConsumerWork`` / ``ProducerWork`` entries, resolves the
        target method using the following priority:

        1. **Label provided, matches registry** → named bound method.
        2. **Label provided, no match** → ``ValueError`` with a
           did-you-mean suggestion listing registered labels.
        3. **No label, ≥1 registered methods, labels required** →
           ``ValueError`` requiring a label (lists available labels).
        4. **No label, 0 registered methods** → default monolithic
           ``consumer_work`` / ``producer_work``.
        5. **No label, ≥1 registered methods, labels not required** →
           default monolithic ``consumer_work`` / ``producer_work``.

        Captured schedules require labels so the schedule text selects
        the intended TS work hook explicitly.  Legacy non-captured tasks
        can disable that requirement to preserve the historical default
        monolithic work method behavior.

        Returns ``None`` for non-work stages.
        """
        if schedule_stage in {
            ScheduleStage.ConsumerAuxWork,
            ScheduleStage.ConsumerWork,
        }:
            return Task._resolve_named_or_default(
                resource,
                label,
                schedule_stage,
                attr=_CONSUMER_WORK_FNS_ATTR,
                stage_attr="_consumer_work_stage",
                default_stage=ScheduleStage.ConsumerWork,
                default_method=(
                    resource.consumer_aux_work
                    if schedule_stage == ScheduleStage.ConsumerAuxWork
                    else resource.consumer_work
                ),
                side="consumer",
                decorator="@consumer_work",
                require_label_for_named=require_label_for_named,
            )
        if schedule_stage in {
            ScheduleStage.ProducerAuxWork,
            ScheduleStage.ProducerWork,
        }:
            return Task._resolve_named_or_default(
                resource,
                label,
                schedule_stage,
                attr=_PRODUCER_WORK_FNS_ATTR,
                stage_attr="_producer_work_stage",
                default_stage=ScheduleStage.ProducerWork,
                default_method=(
                    resource.producer_aux_work
                    if schedule_stage == ScheduleStage.ProducerAuxWork
                    else resource.producer_work
                ),
                side="producer",
                decorator="@producer_work",
                require_label_for_named=require_label_for_named,
            )
        return None

    @staticmethod
    def _resolve_named_or_default(
        resource: MemoryResource,
        label: object,
        schedule_stage: ScheduleStage,
        *,
        attr: str,
        stage_attr: str,
        default_stage: ScheduleStage,
        default_method: Callable[..., object],
        side: str,
        decorator: str,
        require_label_for_named: bool,
    ) -> Callable[..., object]:
        """Resolve a named work method or fall back to the default.

        Falls back to ``default_method`` when the resource has zero
        stage-matching ``@consumer_work`` / ``@producer_work``
        methods, or when label requirements are disabled for a legacy
        non-captured task.

        Raises ``ValueError`` with actionable diagnostics for:

        - label typos (did-you-mean suggestion)
        - missing label when labels are required and any named methods
          are registered
        """
        named_fns = {}
        for candidate_label, method_name in _collect_named_work_fns(
            type(resource), attr
        ).items():
            method = getattr(type(resource), method_name, None)
            method_stage = getattr(method, stage_attr, default_stage)
            if method_stage == schedule_stage:
                named_fns[candidate_label] = method_name

        if label is not None:
            if label in named_fns:
                return getattr(resource, named_fns[label])
            available = list(named_fns.keys())
            hint = _format_did_you_mean(str(label), available)
            raise ValueError(
                f"{side.capitalize()} work label {label!r} not found on "
                f"{type(resource).__name__} (resource '{resource.name}').\n"
                f"  Registered {decorator} labels: {available}\n"
                f"{hint}"
            )

        if isinstance(resource, WorkQueue) and named_fns:
            available = list(named_fns.keys())
            raise ValueError(
                f"{type(resource).__name__} (resource '{resource.name}') has "
                f"{len(named_fns)} {decorator} "
                f"{'method' if len(named_fns) == 1 else 'methods'} "
                f"{available} but the schedule entry has no label.\n"
                "  WorkQueue entries must use the named scheduler operation; "
                f"add a label such as {available[0]!r}."
            )

        if named_fns and require_label_for_named:
            raise ValueError(
                f"{type(resource).__name__} (resource '{resource.name}') has "
                f"{len(named_fns)} {decorator} "
                f"{'method' if len(named_fns) == 1 else 'methods'} "
                f"{list(named_fns.keys())} but the schedule entry has no "
                f"label.\n"
                f"  Add a label to the schedule tuple, e.g.:\n"
                f"    (resource, ScheduleStage.{side.capitalize()}Work, "
                f"{list(named_fns.keys())[0]!r})"
            )

        return default_method

    @staticmethod
    def _get_cta_v_size(pipeline_config: PipelineConfig) -> int:
        """Extract the V-group size from ``cta_layout_vmnk``.

        Returns 1 when the layout is absent or cannot be inspected.
        For multi-pair clusters (e.g. (2,2,2,1)), V=2 means CTAs
        0,2,4,6 are V-group leaders.
        """
        layout = pipeline_config.cta_layout_vmnk
        if layout is None:
            return 1
        if isinstance(layout, (tuple, list)) and len(layout) > 0:
            return int(layout[0])
        return 1

    def _check_leader_cta_signaling(
        self,
        resource: MemoryResource,
        signaling_threads: SignalingThreads,
        side: str,
    ) -> None:
        """Raise if ``run_only_on_cta_id`` is set but signaling is not ``CtaLeader``.

        Called at trace time before each CTA-leader gate in the pipeline
        operations.  When a task runs only on CTA 0, the gate is skipped,
        so the pipeline config must already specify ``CtaLeader``.
        """
        if self._runs_on_single_cta() and not signaling_threads.has_cta_leader():
            if cutlass.const_expr(
                resource.pipeline_config is not None
                and resource.pipeline_config.pipeline_type == PipelineType.ClcFetchAsync
                and side == "consumer"
            ):
                # CLC WorkQueue consumers may intentionally mix all-CTA tasks
                # with leader-only tasks behind one shared pipeline config.
                return
            raise ValueError(
                f"Task '{self.name}' has run_only_on_cta_id={self.run_only_on_cta_id} but "
                f"resource '{resource.name}' has "
                f"{side}_signaling_threads={signaling_threads}, "
                f"expected CtaLeader"
            )

    def _runs_on_single_cta(self) -> bool:
        """Return true when the whole task body is CTA-rank restricted."""
        return self.run_only_on_cta_id is not None

    @staticmethod
    def _is_fork_secondary(resource: MemoryResource) -> bool:
        """True if *resource* is a non-primary Fork group member.

        In Fork mode, only the first member (``members[0]``) has
        ProducerAcquire/Commit in the schedule.  Secondary members
        must not call ``producer_tail`` — doing so would re-arm the
        shared full barrier and cause a hang or error.
        """
        _pg = getattr(resource, "pipeline_group", None)
        if _pg is None or isinstance(resource, PipelineGroup):
            return False
        return _pg.mode == PipelineGroupMode.Fork and resource is not _pg.members[0]

    @staticmethod
    def _producer_state_owned_by_signaling_ctas_only(resource: MemoryResource) -> bool:
        """True when non-signaling CTAs must not advance producer state.

        Most leader-routed producer resources still run producer work on every
        CTA and only gate the mbarrier signal itself.  Barrier-only resources
        such as BatchedGemm's work throttle are different: only the signaling
        CTA owns the software pipeline state.
        """
        return bool(
            getattr(resource, "producer_state_owned_by_signaling_ctas_only", False)
        )

    @cute.jit
    def _thread_advance_on_acquire_state(self, resource: MemoryResource) -> None:
        """Materialize split producer cursors before dynamic control flow.

        ``advance_on_acquire`` uses two semantic cursors: ``producer_state`` is
        the acquire cursor, and ``producer_commit_state`` is the commit cursor.
        The work stage has no independent cursor.  This method does not change
        either cursor; it rewrites the current values back into their staged
        fields so the IR pass treats them as live SSA values when the following loop or
        tail section threads mutable resource state.
        """
        resource.producer_state._index = resource.producer_state.index
        resource.producer_state._count = resource.producer_state.count
        resource.producer_state._phase = resource.producer_state.phase
        resource.producer_commit_state._index = resource.producer_commit_state.index
        resource.producer_commit_state._count = resource.producer_commit_state.count
        resource.producer_commit_state._phase = resource.producer_commit_state.phase
        resource.store_producer_status(resource.load_producer_status())

    @cute.jit
    def _load_advance_on_acquire_state(self, resource: MemoryResource) -> tuple:
        """Return the explicit SSA tuple for split producer state.

        Resource state is stored as mutable object fields, but generated IR
        regions need explicit input/output values for every field that must
        survive across the region.  The tuple order is acquire
        index/count/phase, commit index/count/phase, and producer status.
        """
        return (
            resource.producer_state.index,
            resource.producer_state.count,
            resource.producer_state.phase,
            resource.producer_commit_state.index,
            resource.producer_commit_state.count,
            resource.producer_commit_state.phase,
            resource.load_producer_status(),
        )

    @cute.jit
    def _store_advance_on_acquire_state(
        self,
        resource: MemoryResource,
        producer_index: Any,
        producer_count: Any,
        producer_phase: Any,
        commit_index: Any,
        commit_count: Any,
        commit_phase: Any,
        producer_status: Any,
    ) -> None:
        """Write the explicit split-state tuple back to resource fields.

        The normal TS stage helpers read and update ``resource.producer_state``,
        ``resource.producer_commit_state``, and ``resource.producer_status``.
        Loading/storing around generated regions lets those helpers stay in the
        usual resource-field style while the IR pass sees explicit SSA values.
        """
        resource.producer_state._index = producer_index
        resource.producer_state._count = producer_count
        resource.producer_state._phase = producer_phase
        resource.producer_commit_state._index = commit_index
        resource.producer_commit_state._count = commit_count
        resource.producer_commit_state._phase = commit_phase
        resource.store_producer_status(producer_status)

    def _run_advance_on_acquire_schedule_entry(
        self,
        resource: MemoryResource,
        schedule_stage: ScheduleStage,
        work_method: Optional[Callable[..., object]],
        idx: int,
        work_tile: WorkTileInfo,
        is_producer: bool,
        resolved_domain: object,
        routing_slot: object,
        context: Optional[ResourceContext],
        label: object = None,
    ) -> None:
        """Run a producer entry while forwarding untouched split cursors.

        ``advance_on_acquire`` has an acquire cursor and a commit cursor.  The
        entry body mutates at most one of them, but the IR pass still needs the
        unchanged cursor fields re-written at the schedule-entry boundary so
        the generated loop carries both cursors consistently.

        The unconditional ``if_generate`` below is not a TS scheduling guard.
        Its condition is always true; it is used to make the generated region
        accept and return the acquire cursor, commit cursor, and producer
        status as explicit SSA values.  Without that boundary, unchanged fields
        can become scoped locals instead of loop-carried state in generated IR.
        """
        input_state = list(self._load_advance_on_acquire_state(resource))

        def active_body(
            producer_index: Any,
            producer_count: Any,
            producer_phase: Any,
            commit_index: Any,
            commit_count: Any,
            commit_phase: Any,
            producer_status: Any,
        ) -> tuple:
            self._store_advance_on_acquire_state(
                resource,
                producer_index,
                producer_count,
                producer_phase,
                commit_index,
                commit_count,
                commit_phase,
                producer_status,
            )

            stage_info = self._create_stage_info(
                resource,
                idx,
                work_tile,
                is_producer,
                resolved_domain,
                label=label,
                schedule_stage=schedule_stage,
                routing_slot=routing_slot,
                context=context,
            )
            self._run_step(
                resource, stage_info, schedule_stage, work_method, routing_slot
            )

            if cutlass.const_expr(schedule_stage == ScheduleStage.ProducerTryAcquire):
                return (
                    producer_index,
                    producer_count,
                    producer_phase,
                    commit_index,
                    commit_count,
                    commit_phase,
                    resource.load_producer_status(),
                )
            if cutlass.const_expr(schedule_stage == ScheduleStage.ProducerAcquire):
                return (
                    resource.producer_state.index,
                    resource.producer_state.count,
                    resource.producer_state.phase,
                    commit_index,
                    commit_count,
                    commit_phase,
                    resource.load_producer_status(),
                )
            if cutlass.const_expr(schedule_stage == ScheduleStage.ProducerCommit):
                return (
                    producer_index,
                    producer_count,
                    producer_phase,
                    resource.producer_commit_state.index,
                    resource.producer_commit_state.count,
                    resource.producer_commit_state.phase,
                    producer_status,
                )
            if cutlass.const_expr(schedule_stage == ScheduleStage.ProducerWork):
                return (
                    producer_index,
                    producer_count,
                    producer_phase,
                    commit_index,
                    commit_count,
                    commit_phase,
                    producer_status,
                )
            return (
                resource.producer_state.index,
                resource.producer_state.count,
                resource.producer_state.phase,
                resource.producer_commit_state.index,
                resource.producer_commit_state.count,
                resource.producer_commit_state.phase,
                resource.load_producer_status(),
            )

        # The condition is intentionally always true: this generated region is
        # used to yield updated split-cursor SSA values, not to guard execution.
        updated_state = cutlass.if_generate(
            cutlass.Boolean(True),
            active_body,
            input_args=input_state,
            return_types=[cutlass.Int32] * 7,
        )
        self._store_advance_on_acquire_state(resource, *updated_state)

    @cute.jit
    def _consumer_release(
        self, resource: MemoryResource, stage_info: StageInfo
    ) -> None:
        """Signal the producer that the consumer is done with the current stage.

        Calls ``pipeline.consumer_release`` and advances the consumer
        state.

        When ``advance_on_wait`` is enabled, releases using the separate
        ``consumer_release_state`` (which tracks the oldest un-released
        stage) instead of ``consumer_state`` (which has already advanced
        past the waited stage).
        """
        if cutlass.const_expr(resource.pipeline_config is not None):
            assert resource.pipeline_config is not None
            do_release = cutlass.Boolean(True)
            if cutlass.const_expr(
                resource.pipeline_config.consumer_signaling_threads.has_cta_leader()
                and not self._runs_on_single_cta()
            ):
                cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
                cta_v_size = self._get_cta_v_size(resource.pipeline_config)
                do_release = cta_rank_in_cluster % cta_v_size == 0
            _cfg = resource.state_src.pipeline_config
            assert _cfg is not None
            # Interleaved pipeline states are initialized to the warp-local
            # lane and advanced by interleave_stride, so the normal pipeline
            # release API targets the correct per-lane barrier stage.
            if do_release:
                _ptx_comment(resource.name + "_consumer_release")
                # For PipelineGroups, self.pipeline is None to avoid
                # aliasing issues with inject_leaves; use group_pipeline.
                pipe = (
                    resource.group_pipeline
                    if cutlass.const_expr(isinstance(resource, PipelineGroup))
                    else resource.pipeline
                )
                if cutlass.const_expr(_cfg.advance_on_wait):
                    pipe.consumer_release(resource.state_src.consumer_release_state)
                else:
                    pipe.consumer_release(resource.state_src.consumer_state)
            if cutlass.const_expr(_cfg.advance_on_wait):
                release_state = resource.state_src.consumer_release_state
            else:
                release_state = resource.state_src.consumer_state
            _release_stride = _cfg.consumer_release_interleave_stride
            if cutlass.const_expr(_release_stride > 1):
                # Advance OUTSIDE do_release so SSA update is visible at
                # the scf.for yield level for interleaved pipelines.
                self._advance_pipeline_state(release_state, _cfg, _release_stride)
            else:
                self._advance_pipeline_state_if(
                    release_state, _cfg, _release_stride, do_release
                )

    @cute.jit
    def _consumer_try_wait(
        self, resource: MemoryResource, stage_info: StageInfo
    ) -> None:
        """Non-blocking probe for data availability on the consumer side.

        Stores the status in ``resource.consumer_status`` for a later
        ``_consumer_wait`` call.  Skipped for ``ClcFetchAsync`` pipelines
        (no explicit consumer try wait).
        """
        if cutlass.const_expr(resource.pipeline_config is not None):
            assert resource.pipeline_config is not None
            do_wait = cutlass.Boolean(True)
            # Allow per-resource override for wait signaling (split-consumer
            # pattern: one task waits on All CTAs, another releases on leader).
            consumer_wait_signaling = (
                resource.pipeline_config.consumer_wait_signaling_threads
                if resource.pipeline_config.consumer_wait_signaling_threads is not None
                else resource.pipeline_config.consumer_signaling_threads
            )
            self._check_leader_cta_signaling(
                resource,
                consumer_wait_signaling,
                "consumer",
            )
            if cutlass.const_expr(
                consumer_wait_signaling.has_cta_leader()
                and not self._runs_on_single_cta()
            ):
                cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
                cta_v_size = self._get_cta_v_size(resource.pipeline_config)
                do_wait = cta_rank_in_cluster % cta_v_size == 0

            if cutlass.const_expr(
                resource.pipeline_config.pipeline_type == PipelineType.ClcFetchAsync
            ):
                do_wait = cutlass.Boolean(False)

            if do_wait:
                if cutlass.const_expr(
                    resource.pipeline_config.pipeline_type != PipelineType.ClcFetchAsync
                ):
                    _ptx_comment(resource.name + "_consumer_try_wait")
                    resource.store_consumer_status(
                        resource.pipeline.consumer_try_wait(
                            resource.state_src.consumer_state
                        )
                    )

    @cute.jit
    def _consumer_wait(self, resource: MemoryResource, stage_info: StageInfo) -> None:
        """Blocking wait for data availability on the consumer side.

        Completes the wait started by ``_consumer_try_wait`` using
        ``resource.consumer_status``.

        When ``advance_on_wait`` is enabled on the resource's pipeline,
        saves the current stage index to ``consumer_work_stage`` and
        advances ``consumer_state`` immediately after the wait.  This
        decouples the wait-advance from the release-advance, allowing
        out-of-order buffer releases.  See ``advance_on_wait.md`` for
        a worked example.
        """
        if cutlass.const_expr(resource.pipeline_config is not None):
            assert resource.pipeline_config is not None
            do_wait = cutlass.Boolean(True)
            # Allow per-resource override for wait signaling (split-consumer
            # pattern: one task waits on All CTAs, another releases on leader).
            consumer_wait_signaling = (
                resource.pipeline_config.consumer_wait_signaling_threads
                if resource.pipeline_config.consumer_wait_signaling_threads is not None
                else resource.pipeline_config.consumer_signaling_threads
            )
            self._check_leader_cta_signaling(
                resource,
                consumer_wait_signaling,
                "consumer",
            )
            if cutlass.const_expr(
                consumer_wait_signaling.has_cta_leader()
                and not self._runs_on_single_cta()
            ):
                cta_rank_in_cluster = cute.arch.block_idx_in_cluster()
                cta_v_size = self._get_cta_v_size(resource.pipeline_config)
                do_wait = cta_rank_in_cluster % cta_v_size == 0
            if do_wait:
                _ptx_comment(resource.name + "_consumer_wait")
                if cutlass.const_expr(resource.pipeline_config is not None):
                    resource.pipeline.consumer_wait(
                        resource.state_src.consumer_state,
                        resource.load_consumer_status(),
                    )
            assert resource.state_src.pipeline_config is not None
            if cutlass.const_expr(resource.state_src.pipeline_config.advance_on_wait):
                self._capture_consumer_work_stage_and_advance_if(resource, do_wait)

    @cute.jit
    def _call_work_method(
        self,
        resource: MemoryResource,
        stage_info: StageInfo,
        work_method: Optional[Callable[..., object]],
        work_kwargs: Optional[dict] = None,
    ) -> None:
        """Invoke user work while enforcing captured-schedule access rules."""
        assert work_method is not None
        forwarded = work_kwargs if work_kwargs is not None else {}
        with resource._ts_captured_schedule_execution(self.captured_schedule):
            manages_context = getattr(
                work_method,
                _TS_MANAGES_CAPTURE_CONTEXT_ATTR,
                getattr(
                    getattr(work_method, "__func__", None),
                    _TS_MANAGES_CAPTURE_CONTEXT_ATTR,
                    False,
                ),
            )
            if cutlass.const_expr(manages_context):
                work_method(stage_info, **forwarded)
            else:
                hook_name = getattr(
                    work_method,
                    "__name__",
                    type(work_method).__name__,
                )
                with resource._ts_captured_schedule_user_hook(hook_name):
                    work_method(stage_info, **forwarded)

    @cute.jit
    def _consumer_aux_work(
        self,
        resource: MemoryResource,
        stage_info: StageInfo,
        work_method: Optional[Callable[..., object]],
        routing_slot: object = None,
        work_kwargs: Optional[dict] = None,
    ) -> None:
        """Execute helper-variable consumer work and propagate outputs."""
        self._call_work_method(resource, stage_info, work_method, work_kwargs)
        if cutlass.const_expr(self.slot_routing is not None):
            assert self.slot_routing is not None
            key = cast(Any, routing_slot)
            if cutlass.const_expr(key in self.slot_routing):
                for var_names, destinations in self.slot_routing[key]:
                    for dst_entry in destinations:
                        parts = cast("tuple[Any, ...]", dst_entry)
                        if cutlass.const_expr(len(parts) == 3):
                            dst_resource, dst_stage, dst_call_idx = parts
                        else:
                            dst_resource, dst_stage, _dst_stage_type, dst_call_idx = (
                                parts
                            )
                        _ptx_comment(
                            resource.name
                            + "_consumer_aux_work->"
                            + dst_resource.name
                            + "."
                            + dst_stage.name
                            + "["
                            + str(dst_call_idx)
                            + "]"
                        )
                        if cutlass.const_expr(_is_consumer_dst_stage(dst_stage)):
                            resource.copy_consumer_vars_to_consumer_of(
                                dst_resource, var_names
                            )
                        else:
                            resource.copy_consumer_vars_to(dst_resource, var_names)
        else:
            for dst_resource in self.dst_resources:
                _ptx_comment(resource.name + "_consumer_aux_work")
                resource.copy_consumer_vars_to(dst_resource)

    @cute.jit
    def _consumer_work(
        self,
        resource: MemoryResource,
        stage_info: StageInfo,
        work_method: Optional[Callable[..., object]],
        routing_slot: object = None,
        work_kwargs: Optional[dict] = None,
    ) -> None:
        """Execute the resource's ``consumer_work`` and propagate outputs.

        ``work_method`` is the pre-resolved callable (either
        ``resource.consumer_work`` or a ``@consumer_work`` method)
        determined at compile time by ``_resolve_work_method``.

        Label validation is performed by ``_resolve_work_method`` before
        this method is called.  See ``_resolve_named_or_default`` for
        the full dispatch and error-reporting logic.

        When ``self.slot_routing`` is set, matching consumer variables
        are copied only to the destinations listed for this
        ``(resource, ConsumerWork, call_idx)`` slot.  Producer-side
        destinations receive the copy via ``copy_consumer_vars_to``
        (into ``producer_vars``); consumer-side destinations receive
        it via ``copy_consumer_vars_to_consumer_of`` (into
        ``consumer_vars``).  When ``self.slot_routing is None`` the
        legacy broadcast to every ``dst_resource`` is used.
        """
        self._call_work_method(resource, stage_info, work_method, work_kwargs)
        if cutlass.const_expr(self.slot_routing is not None):
            assert self.slot_routing is not None
            key = cast(Any, routing_slot)
            if cutlass.const_expr(key in self.slot_routing):
                for var_names, destinations in self.slot_routing[key]:
                    for dst_entry in destinations:
                        parts = cast("tuple[Any, ...]", dst_entry)
                        if cutlass.const_expr(len(parts) == 3):
                            dst_resource, dst_stage, dst_call_idx = parts
                        else:
                            dst_resource, dst_stage, _dst_stage_type, dst_call_idx = (
                                parts
                            )
                        _ptx_comment(
                            resource.name
                            + "_consumer_work->"
                            + dst_resource.name
                            + "."
                            + dst_stage.name
                            + "["
                            + str(dst_call_idx)
                            + "]"
                        )
                        if cutlass.const_expr(_is_consumer_dst_stage(dst_stage)):
                            resource.copy_consumer_vars_to_consumer_of(
                                dst_resource, var_names
                            )
                        else:
                            resource.copy_consumer_vars_to(dst_resource, var_names)
        else:
            for dst_resource in self.dst_resources:
                _ptx_comment(resource.name + "_consumer_work")
                resource.copy_consumer_vars_to(dst_resource)

    @cute.jit
    def _producer_try_acquire(
        self, resource: MemoryResource, stage_info: StageInfo
    ) -> None:
        """Non-blocking probe for a free buffer on the producer side.

        Stores the status in ``resource.producer_status`` for a later
        ``_producer_acquire`` call. Skipped for ``ClcFetchAsync``
        pipelines.
        """
        del stage_info
        if cutlass.const_expr(resource.pipeline_config is not None):
            assert resource.pipeline_config is not None
            if cutlass.const_expr(
                resource.pipeline_config.pipeline_type == PipelineType.ClcFetchAsync
            ):
                return
            if cutlass.const_expr(
                resource.pipeline_config.pipeline_type == PipelineType.TmaUmma
                or self._uses_task_warp_leader_tma_acquire(resource.pipeline_config)
            ):
                # Do not gate TMA acquire at task level when the pipeline must
                # wait all producer participants on the empty barrier.  TmaUmma
                # gates the full-barrier arrive internally on CTA leadership;
                # TaskWarpLeader further narrows the transaction arrive to the
                # first warp assigned to the task.
                self._producer_try_acquire_now(resource)
            else:
                if cutlass.const_expr(
                    self._has_task_level_producer_cta_gate(resource.pipeline_config)
                ):
                    self._producer_try_acquire_if(
                        resource,
                        self._is_producer_signaling_cta(resource.pipeline_config),
                    )
                else:
                    self._producer_try_acquire_for_selected_cta(resource)

    def _has_task_level_producer_cta_gate(
        self, pipeline_config: PipelineConfig
    ) -> bool:
        """Return true when this task must gate producer ops to leader CTAs."""
        return (
            pipeline_config.producer_signaling_threads.has_cta_leader()
            and not self._runs_on_single_cta()
        )

    @staticmethod
    def _uses_task_warp_leader_tma_acquire(
        pipeline_config: PipelineConfig,
    ) -> bool:
        """Return true when the TS TMA acquire overload needs all warps."""
        return (
            pipeline_config.pipeline_type
            in (PipelineType.TmaAsync, PipelineType.TmaUmma)
            and pipeline_config.producer_signaling_threads.has_task_warp_leader()
        )

    def _is_producer_signaling_cta(self, pipeline_config: PipelineConfig) -> bool:
        """Return true for the CTA that is allowed to signal producer barriers."""
        cta_rank_in_cluster = cute.arch.make_warp_uniform(
            cute.arch.block_idx_in_cluster()
        )
        if cutlass.const_expr(
            pipeline_config.pipeline_type == PipelineType.ClcFetchAsync
        ):
            return cta_rank_in_cluster == 0
        cta_v_size = self._get_cta_v_size(pipeline_config)
        return cta_rank_in_cluster % cta_v_size == 0

    @cute.jit
    def _producer_try_acquire_for_selected_cta(self, resource: MemoryResource) -> None:
        self._producer_try_acquire_now(resource)

    @cute.jit
    def _producer_try_acquire_if(
        self, resource: MemoryResource, do_acquire: Any
    ) -> None:
        """Probe a producer barrier only on selected CTAs.

        The producer status is loop-carried by the DSL.  Assigning it only
        inside a dynamic CTA-leader branch can leave the following scf.for
        with a non-dominating iter_arg, so build an explicit if-result and
        store it once after the branch.
        """
        previous_status = resource.load_producer_status()

        def acquire_body(_previous_status: cutlass.Int32) -> cutlass.Int32:
            _ptx_comment(resource.name + "_producer_try_acquire")
            return cutlass.Int32(
                resource.pipeline.producer_try_acquire(
                    resource.get_producer_acquire_state()
                )
            )

        def keep_body(_previous_status: cutlass.Int32) -> cutlass.Int32:
            return _previous_status

        producer_status = cutlass.if_generate(
            do_acquire,
            acquire_body,
            keep_body,
            [previous_status],
            [cutlass.Int32],
        )
        resource.store_producer_status(producer_status)

    @cute.jit
    def _producer_try_acquire_now(self, resource: MemoryResource) -> None:
        _ptx_comment(resource.name + "_producer_try_acquire")
        resource.store_producer_status(
            resource.pipeline.producer_try_acquire(
                resource.get_producer_acquire_state()
            )
        )

    @cute.jit
    def _producer_acquire(
        self, resource: MemoryResource, stage_info: StageInfo
    ) -> None:
        """Blocking wait for a free buffer on the producer side.

        Completes the acquisition started by ``_producer_try_acquire``
        using ``resource.producer_status``.
        """
        if cutlass.const_expr(resource.pipeline_config is not None):
            assert resource.pipeline_config is not None
            if cutlass.const_expr(
                resource.pipeline_config.pipeline_type == PipelineType.TmaUmma
                or self._uses_task_warp_leader_tma_acquire(resource.pipeline_config)
            ):
                # See _producer_try_acquire: all producer participants must
                # finish the empty-barrier wait.  The transaction-barrier
                # arrive is guarded inside the concrete pipeline.
                self._producer_acquire_now(resource)
            else:
                if cutlass.const_expr(
                    self._has_task_level_producer_cta_gate(resource.pipeline_config)
                ):
                    if self._is_producer_signaling_cta(resource.pipeline_config):
                        self._producer_acquire_for_selected_cta(resource)
                else:
                    self._producer_acquire_for_selected_cta(resource)

    @cute.jit
    def _producer_acquire_for_selected_cta(self, resource: MemoryResource) -> None:
        self._producer_acquire_now(resource)

    @cute.jit
    def _producer_acquire_now(self, resource: MemoryResource) -> None:
        assert resource.pipeline_config is not None
        if cutlass.const_expr(self._is_fork_secondary(resource)):
            # Fork secondary: only wait on per-member empty barrier.  The
            # shared full was already armed by the primary member's
            # ProducerAcquire.  Uses its own producer_state, kept in sync by
            # _producer_commit advancing all Fork members.
            _ptx_comment(resource.name + "_fork_empty_wait")
            token = resource.load_producer_status()
            if token == 0:
                resource.pipeline.sync_object_empty.wait(
                    resource.producer_state.index,
                    resource.producer_state.phase,
                )
            if cutlass.const_expr(resource.pipeline_config.advance_on_acquire):
                self._advance_producer_acquire_state(resource)
        elif cutlass.const_expr(resource.pipeline_config is not None):
            _ptx_comment(resource.name + "_producer_acquire")
            resource.pipeline.producer_acquire(
                resource.get_producer_acquire_state(),
                resource.load_producer_status(),
            )
            if cutlass.const_expr(resource.pipeline_config.advance_on_acquire):
                self._advance_producer_acquire_state(resource)

    @cute.jit
    def _producer_commit(self, resource: MemoryResource, stage_info: StageInfo) -> None:
        """Commit the current producer stage and advance the producer state.

        For ``ClcFetchAsync`` pipelines the commit is implicit (the CLC
        hardware was already triggered), so only the state advance is
        performed.

        **Fork group-level commit**: when ``resource`` is a
        ``PipelineGroup`` in Fork mode, the commit fires once on the
        shared full barrier (via the primary member's pipeline) and
        *all* members' producer states advance.  All other gating —
        ``CtaLeader`` signaling, ``ClcFetchAsync`` implicit commit —
        is shared with the per-resource path and driven by the
        group's merged ``pipeline_config``.
        """
        is_fork_group = cutlass.const_expr(
            isinstance(resource, PipelineGroup)
            and resource.mode == PipelineGroupMode.Fork
        )
        if cutlass.const_expr(is_fork_group):
            self._producer_commit_fork_group(resource)
            return
        if cutlass.const_expr(resource.pipeline_config is not None):
            self._producer_commit_memory_resource(resource)

    @cute.jit
    def _producer_commit_memory_resource(self, resource: MemoryResource) -> None:
        assert resource.pipeline_config is not None
        if cutlass.const_expr(
            self._has_task_level_producer_cta_gate(resource.pipeline_config)
        ):
            is_producer_cta = self._is_producer_signaling_cta(resource.pipeline_config)
            if is_producer_cta:
                self._producer_commit_signal_for_selected_cta(resource)
            if cutlass.const_expr(
                resource.pipeline_config.pipeline_type == PipelineType.ClcFetchAsync
                or self._producer_state_owned_by_signaling_ctas_only(resource)
            ):
                # CLC fetch and explicit leader-owned software barriers have a
                # real CTA0-only producer: follower CTAs may participate in the
                # surrounding task, but do not own producer state.
                if cutlass.const_expr(resource.pipeline_config.advance_on_acquire):
                    self._advance_producer_commit_state_if(resource, is_producer_cta)
                else:
                    self._advance_producer_state_if(resource, is_producer_cta)
            else:
                if cutlass.const_expr(resource.pipeline_config.advance_on_acquire):
                    self._advance_producer_commit_state(resource)
                else:
                    self._advance_producer_state(resource)
        else:
            do_commit = cutlass.Boolean(True)
            if do_commit:
                _ptx_comment(resource.name + "_producer_commit")
                if cutlass.const_expr(
                    resource.pipeline_config.pipeline_type != PipelineType.ClcFetchAsync
                ):
                    resource.pipeline.producer_commit(
                        resource.get_producer_commit_state()
                    )
                if cutlass.const_expr(resource.pipeline_config.advance_on_acquire):
                    self._advance_producer_commit_state(resource)
                else:
                    self._advance_producer_state(resource)

    @cute.jit
    def _producer_commit_fork_group(self, resource: PipelineGroup) -> None:
        # Fork group-level commit routes through the primary member's
        # pipeline and advances all members' producer states.
        cfg = resource.pipeline_config
        assert cfg is not None
        if cutlass.const_expr(self._has_task_level_producer_cta_gate(cfg)):
            is_producer_cta = self._is_producer_signaling_cta(cfg)
            if is_producer_cta:
                self._producer_commit_fork_group_signal_for_selected_cta(resource)
            if cutlass.const_expr(cfg.pipeline_type == PipelineType.ClcFetchAsync):
                # CLC fetch has a real CTA0-only producer: follower CTAs
                # consume the work queue response but do not own producer
                # state for the fetch pipeline.
                self._advance_producer_fork_group_state_if(resource, is_producer_cta)
            else:
                self._advance_producer_fork_group_state(resource)
        else:
            self._producer_commit_fork_group_signal_for_selected_cta(resource)
            self._advance_producer_fork_group_state(resource)

    @cute.jit
    def _producer_commit_signal_for_selected_cta(
        self, resource: MemoryResource
    ) -> None:
        self._producer_commit_signal_now(resource)

    @cute.jit
    def _producer_commit_fork_group_signal_for_selected_cta(
        self, resource: PipelineGroup
    ) -> None:
        self._producer_commit_fork_group_signal_now(resource)

    @cute.jit
    def _advance_producer_state(self, resource: MemoryResource) -> None:
        assert resource.pipeline_config is not None
        _producer_stride = resource.pipeline_config.producer_acquire_interleave_stride
        if cutlass.const_expr(_producer_stride > 1):
            self._strided_advance(
                resource.producer_state,
                resource.state_src.pipeline_config,
                _producer_stride,
            )
        else:
            resource.producer_state.advance()

    @cute.jit
    def _advance_pipeline_state(
        self, state: Any, pipeline_config: PipelineConfig, stride: Any
    ) -> None:
        _stride = stride
        new_index = state.index + _stride
        new_count = state.count + _stride

        def wrap_body(index: cutlass.Int32, phase: cutlass.Int32) -> tuple:
            return cutlass.Int32(index - pipeline_config.num_stages), phase ^ 1

        def keep_body(index: cutlass.Int32, phase: cutlass.Int32) -> tuple:
            return index, phase

        state._index, state._phase = cast(
            list,
            cutlass.if_generate(
                new_index >= pipeline_config.num_stages,
                wrap_body,
                keep_body,
                [new_index, state.phase],
                [cutlass.Int32, cutlass.Int32],
            ),
        )
        state._count = new_count

    @cute.jit
    def _advance_pipeline_state_if(
        self,
        state: Any,
        pipeline_config: PipelineConfig,
        stride: Any,
        do_advance: Any,
    ) -> None:
        _stride = stride

        def advance_body(index: Any, count: Any, phase: Any) -> tuple:
            new_index = index + _stride
            new_count = count + _stride

            def wrap_body(index: cutlass.Int32, phase: cutlass.Int32) -> tuple:
                return cutlass.Int32(index - pipeline_config.num_stages), phase ^ 1

            def keep_body(index: cutlass.Int32, phase: cutlass.Int32) -> tuple:
                return index, phase

            new_index, new_phase = cast(
                list,
                cutlass.if_generate(
                    new_index >= pipeline_config.num_stages,
                    wrap_body,
                    keep_body,
                    [new_index, phase],
                    [cutlass.Int32, cutlass.Int32],
                ),
            )
            return new_index, new_count, new_phase

        def keep_body(
            index: cutlass.Int32, count: cutlass.Int32, phase: cutlass.Int32
        ) -> tuple:
            return index, count, phase

        state._index, state._count, state._phase = cast(
            list,
            cutlass.if_generate(
                do_advance,
                advance_body,
                keep_body,
                [state.index, state.count, state.phase],
                [cutlass.Int32, cutlass.Int32, cutlass.Int32],
            ),
        )

    @cute.jit
    def _previous_producer_acquire_state_values(
        self, resource: MemoryResource
    ) -> tuple:
        """Return the just-acquired state values from the acquire cursor."""
        cfg = resource.pipeline_config
        assert cfg is not None
        state = cast(pipeline.PipelineState, resource.get_producer_acquire_state())
        stride = cfg.interleave_stride
        previous_index = state.index - stride
        previous_count = state.count - stride

        def wrap_body(index: Any, phase: Any) -> tuple:
            return cutlass.Int32(index + cfg.num_stages), phase ^ 1

        def keep_body(index: Any, phase: Any) -> tuple:
            return index, phase

        previous_index, previous_phase = cast(
            list,
            cutlass.if_generate(
                previous_index < 0,
                wrap_body,
                keep_body,
                [previous_index, state.phase],
                [cutlass.Int32, cutlass.Int32],
            ),
        )
        return previous_index, previous_count, previous_phase

    @cute.jit
    def _previous_producer_acquire_state(
        self, resource: MemoryResource
    ) -> pipeline.PipelineState:
        """Return the just-acquired state from the advanced acquire cursor."""
        cfg = resource.pipeline_config
        assert cfg is not None
        previous_index, previous_count, previous_phase = (
            self._previous_producer_acquire_state_values(resource)
        )
        return pipeline.PipelineState(
            cfg.num_stages,
            previous_count,
            previous_index,
            previous_phase,
        )

    @cute.jit
    def _capture_consumer_work_stage_and_advance_if(
        self, resource: MemoryResource, do_advance: Any
    ) -> None:
        state = resource.state_src.consumer_state
        cfg = resource.state_src.pipeline_config
        assert cfg is not None

        def capture_body(
            old_work_stage: cutlass.Int32, state_index: cutlass.Int32
        ) -> cutlass.Int32:
            del old_work_stage
            return state_index

        def keep_body(
            old_work_stage: cutlass.Int32, state_index: cutlass.Int32
        ) -> cutlass.Int32:
            del state_index
            return old_work_stage

        resource.state_src.consumer_work_stage = cutlass.if_generate(
            do_advance,
            capture_body,
            keep_body,
            [resource.state_src.consumer_work_stage, state.index],
            [cutlass.Int32],
        )
        self._advance_pipeline_state_if(
            state, cfg, cfg.consumer_wait_interleave_stride, do_advance
        )

    @cute.jit
    def _advance_producer_acquire_state(self, resource: MemoryResource) -> None:
        """Advance acquire state after a successful acquire."""
        self._advance_producer_state(resource)

    @cute.jit
    def _advance_producer_state_if(
        self, resource: MemoryResource, do_advance: Any
    ) -> None:
        assert resource.pipeline_config is not None
        _producer_stride = resource.pipeline_config.producer_acquire_interleave_stride
        cfg = (
            resource.state_src.pipeline_config
            if cutlass.const_expr(_producer_stride > 1)
            else resource.pipeline_config
        )
        self._advance_pipeline_state_if(
            resource.producer_state, cfg, _producer_stride, do_advance
        )

    @cute.jit
    def _advance_producer_commit_state(self, resource: MemoryResource) -> None:
        assert resource.pipeline_config is not None
        _producer_stride = resource.pipeline_config.producer_commit_interleave_stride
        if cutlass.const_expr(_producer_stride > 1):
            self._strided_advance(
                resource.producer_commit_state,
                resource.state_src.pipeline_config,
                _producer_stride,
            )
        else:
            resource.producer_commit_state.advance()

    @cute.jit
    def _advance_producer_commit_state_if(
        self, resource: MemoryResource, do_advance: Any
    ) -> None:
        assert resource.pipeline_config is not None
        _producer_stride = resource.pipeline_config.producer_commit_interleave_stride
        cfg = (
            resource.state_src.pipeline_config
            if cutlass.const_expr(_producer_stride > 1)
            else resource.pipeline_config
        )
        self._advance_pipeline_state_if(
            resource.producer_commit_state, cfg, _producer_stride, do_advance
        )

    @cute.jit
    def _advance_producer_fork_group_state(self, resource: PipelineGroup) -> None:
        assert resource.pipeline_config is not None
        _producer_stride = resource.pipeline_config.producer_acquire_interleave_stride
        for _st in [m.producer_state for m in resource.members]:
            self._strided_advance(_st, resource.pipeline_config, _producer_stride)

    @cute.jit
    def _advance_producer_fork_group_state_if(
        self, resource: PipelineGroup, do_advance: Any
    ) -> None:
        assert resource.pipeline_config is not None
        _producer_stride = resource.pipeline_config.producer_acquire_interleave_stride
        for _st in [m.producer_state for m in resource.members]:
            self._advance_pipeline_state_if(
                _st, resource.pipeline_config, _producer_stride, do_advance
            )

    @cute.jit
    def _producer_commit_signal_now(self, resource: MemoryResource) -> None:
        assert resource.pipeline_config is not None
        _ptx_comment(resource.name + "_producer_commit")
        if cutlass.const_expr(
            resource.pipeline_config.pipeline_type != PipelineType.ClcFetchAsync
        ):
            resource.pipeline.producer_commit(resource.get_producer_commit_state())

    @cute.jit
    def _producer_commit_fork_group_signal_now(self, resource: PipelineGroup) -> None:
        _ptx_comment(resource.name + "_producer_commit")
        primary = resource.members[0]
        cfg = resource.pipeline_config
        assert cfg is not None
        if cutlass.const_expr(cfg.pipeline_type != PipelineType.ClcFetchAsync):
            primary.pipeline.producer_commit(primary.producer_state)

    @cute.jit
    def _producer_tail(self, resource: MemoryResource) -> None:
        tail_state = resource.get_producer_commit_state()
        if cutlass.const_expr(
            resource.pipeline_config is not None
            and self._has_task_level_producer_cta_gate(resource.pipeline_config)
            and self._producer_state_owned_by_signaling_ctas_only(resource)
        ):
            assert resource.pipeline_config is not None
            if self._is_producer_signaling_cta(resource.pipeline_config):
                resource.pipeline.producer_tail(tail_state)
        else:
            resource.pipeline.producer_tail(tail_state)

    @cute.jit
    def _producer_aux_work(
        self,
        resource: MemoryResource,
        stage_info: StageInfo,
        work_method: Optional[Callable[..., object]],
        work_kwargs: Optional[dict] = None,
    ) -> None:
        """Execute helper-variable producer work."""
        _ptx_comment(resource.name + "_producer_aux_work")
        self._call_work_method(resource, stage_info, work_method, work_kwargs)

    @cute.jit
    def _producer_work(
        self,
        resource: MemoryResource,
        stage_info: StageInfo,
        work_method: Optional[Callable[..., object]],
        work_kwargs: Optional[dict] = None,
    ) -> None:
        """Execute the resource's ``producer_work`` or a named variant.

        ``work_method`` is the pre-resolved callable (either
        ``resource.producer_work`` or a ``@producer_work`` method)
        determined at compile time by ``_resolve_work_method``.

        Label validation is performed by ``_resolve_work_method`` before
        this method is called.  See ``_resolve_named_or_default`` for
        the full dispatch and error-reporting logic.

        ``work_kwargs`` are the step's captured constexpr work arguments,
        forwarded to the work method.
        """
        _ptx_comment(resource.name + "_producer_work")
        self._call_work_method(resource, stage_info, work_method, work_kwargs)

    @staticmethod
    def _is_producer_stage(schedule_stage: ScheduleStage) -> bool:
        """Determine if a schedule stage is a producer-side operation."""
        return schedule_stage in {
            ScheduleStage.ProducerAuxWork,
            ScheduleStage.ProducerTryAcquire,
            ScheduleStage.ProducerAcquire,
            ScheduleStage.ProducerWork,
            ScheduleStage.ProducerCommit,
        }

    def _has_consumer_wait_for_resource(self, resource: MemoryResource) -> bool:
        """Return true when this task directly waits on ``resource``."""
        for schedule_entries in (
            self.head_schedule_list,
            self.loop_schedule_list,
            self.tail_schedule_list,
        ):
            for entry in schedule_entries:
                res, stage = entry[0], entry[1]
                if res is resource and stage == ScheduleStage.ConsumerWait:
                    return True
        return False

    def _uses_consumer_release_state_for_stage_info(
        self,
        resource: MemoryResource,
        schedule_stage: ScheduleStage | None,
    ) -> bool:
        """Return true when ``StageInfo`` should follow release-side state.

        ``advance_on_wait`` normally records the just-waited stage in
        ``consumer_work_stage`` before advancing ``consumer_state``.  That is
        correct for tasks that directly wait and then work.  In the
        split-consumer proxy pattern, a different task waits while this task
        only performs ``ConsumerWork`` and ``ConsumerRelease``; such work must
        follow ``consumer_release_state``, the state this task owns locally.
        """
        return (
            schedule_stage == ScheduleStage.ConsumerWork
            and resource.pipeline_config is not None
            and resource.pipeline_config.advance_on_wait
            and not self._has_consumer_wait_for_resource(resource)
        )

    @staticmethod
    def _routing_slot(
        resource: MemoryResource,
        schedule_stage: ScheduleStage,
        stage_type: ScheduleStageType,
        call_idx: int,
    ) -> object:
        """Opaque per-step routing identity (the writer-slot key)."""
        return (id(resource), schedule_stage, stage_type, call_idx)

    def _producer_work_uses_acquire_state_for_stage_info(
        self,
        resource: MemoryResource,
        schedule_stage: ScheduleStage | None,
        routing_slot: object,
    ) -> bool:
        """Return true when this producer-work slot follows acquire state.

        ``advance_on_acquire`` keeps only acquire and commit cursors.  A work
        slot follows acquire when an earlier ProducerAcquire for the same
        resource exists in the contiguous head -> loop -> tail task schedule.
        Split producer-work tasks without acquire follow the commit cursor.

        The slot identity is the routing slot from :meth:`_routing_slot`, which
        already encodes ``(resource, schedule_stage, stage_type, call_idx)``.
        """
        if (
            schedule_stage != ScheduleStage.ProducerWork
            or resource.pipeline_config is None
            or not resource.pipeline_config.advance_on_acquire
        ):
            return False

        return routing_slot in self._producer_work_follow_acquire_slots

    @cute.jit
    def _create_stage_info(
        self,
        resource: MemoryResource,
        idx: int,
        work_tile: Optional[WorkTileInfo] = None,
        is_producer: Optional[bool] = None,
        resolved_domain: Any = None,
        label: object = None,
        schedule_stage: Optional[ScheduleStage] = None,
        routing_slot: object = None,
        context: Optional[ResourceContext] = None,
    ) -> StageInfo:
        """Build a ``StageInfo`` snapshot for the current schedule step.

        Resolves the pipeline stage index and, for producer stages,
        retrieves the mbarrier pointer from the pipeline.

        Parameters
        ----------
        resource : MemoryResource
            The resource this step operates on.
        idx : int
            Current loop offset.
        work_tile : WorkTileInfo | None
            Active work tile (``None`` for non-persistent tasks).
        is_producer : bool | None
            If ``None``, inferred from ``dst_resources`` membership.
        resolved_domain : int | cutlass.Int32 | None
            The resolved loop domain for this tile.  When ``None``,
            falls back to ``self.domain``.
        label : object or None
            User-defined work label from the schedule entry.
        schedule_stage : ScheduleStage or None
            The concrete stage being executed.  Used to choose the correct
            consumer state when ``advance_on_wait`` splits wait/work/release
            across tasks.
        routing_slot : object or None
            Per-step routing identity from :meth:`_routing_slot`.  Used to
            decide whether an ``advance_on_acquire`` ProducerWork slot follows
            an earlier acquire in this contiguous task schedule.
        context : ResourceContext or None
            Framework-level SMEM/TMEM pointers forwarded by ``TaskManager``.
        """
        stage_idx = None
        prim_barrier_array: "cutlass.Array | None" = None

        if cutlass.const_expr(resource.pipeline_config is not None):
            assert resource.pipeline_config is not None
            assert resource.state_src.pipeline_config is not None
            # Determine producer vs consumer based on schedule stage if provided,
            # otherwise fall back to checking dst_resources membership.
            if cutlass.const_expr(is_producer is None):
                is_producer = resource in self.dst_resources

            # Consumer state uses ``state_src`` (Merge members share the
            # group's consumer state).  Producer state uses the resource's
            # own state directly (each producer task tracks independently).
            pipeline_state = (
                resource.producer_state
                if is_producer
                else resource.state_src.consumer_state
            )
            producer_work_follows_acquire = False
            if cutlass.const_expr(
                is_producer and resource.pipeline_config.advance_on_acquire
            ):
                if cutlass.const_expr(schedule_stage == ScheduleStage.ProducerWork):
                    producer_work_follows_acquire = (
                        self._producer_work_uses_acquire_state_for_stage_info(
                            resource, schedule_stage, routing_slot
                        )
                    )
                    if cutlass.const_expr(producer_work_follows_acquire):
                        # ProducerAcquire advances the acquire cursor before
                        # ProducerWork runs.  Work that follows an acquire in
                        # this contiguous task schedule therefore uses the
                        # previous acquire cursor value, i.e. the stage that
                        # was just acquired.  Split work-only tasks use the
                        # lagging commit cursor below.
                        stage_idx = self._previous_producer_acquire_state_values(
                            resource
                        )[0]
                    else:
                        pipeline_state = resource.get_producer_work_state(
                            follows_acquire=False
                        )
                elif cutlass.const_expr(schedule_stage == ScheduleStage.ProducerCommit):
                    pipeline_state = resource.get_producer_commit_state()
            if cutlass.const_expr(
                not is_producer
                and self._uses_consumer_release_state_for_stage_info(
                    resource, schedule_stage
                )
            ):
                pipeline_state = resource.state_src.consumer_release_state
            if cutlass.const_expr(stage_idx is None):
                stage_idx = pipeline_state.index
            _pipe = (
                resource.group_pipeline
                if cutlass.const_expr(isinstance(resource, PipelineGroup))
                else resource.pipeline
            )
            pipeline_type = type(_pipe)
            # advance_on_wait: consumer_state has already advanced past the
            # waited stage, so use consumer_work_stage (captured by
            # _consumer_wait before advancing) for consumer-side stage_idx.
            if cutlass.const_expr(
                not is_producer
                and resource.state_src.pipeline_config.advance_on_wait
                and not self._uses_consumer_release_state_for_stage_info(
                    resource, schedule_stage
                )
            ):
                stage_idx = resource.state_src.consumer_work_stage

            _cfg = resource.pipeline_config
            if cutlass.const_expr(is_producer):
                if cutlass.const_expr(schedule_stage == ScheduleStage.ProducerCommit):
                    _stage_info_stride = _cfg.producer_commit_interleave_stride
                else:
                    _stage_info_stride = _cfg.producer_acquire_interleave_stride
            elif cutlass.const_expr(schedule_stage == ScheduleStage.ConsumerRelease):
                _stage_info_stride = _cfg.consumer_release_interleave_stride
            else:
                _stage_info_stride = _cfg.consumer_wait_interleave_stride
            if cutlass.const_expr(_stage_info_stride > 1):
                cute_barrier_pointer = _pipe.sync_object_full.get_barrier(stage_idx)
            elif cutlass.const_expr(producer_work_follows_acquire):
                cute_barrier_pointer = _pipe.sync_object_full.get_barrier(stage_idx)
            elif cutlass.const_expr(is_producer):
                if cutlass.const_expr(
                    isinstance(
                        _pipe,
                        (pipeline.PipelineAsync, pipeline.PipelineClcFetchAsync),
                    )
                ):
                    cute_barrier_pointer = _pipe.producer_get_barrier(pipeline_state)
                else:
                    cute_barrier_pointer = super(  # type: ignore[misc]
                        pipeline_type, _pipe
                    ).producer_get_barrier(pipeline_state)
            else:
                if cutlass.const_expr(
                    isinstance(
                        _pipe,
                        (pipeline.PipelineAsync, pipeline.PipelineClcFetchAsync),
                    )
                ):
                    cute_barrier_pointer = _pipe.consumer_get_barrier(pipeline_state)
                else:
                    cute_barrier_pointer = super(  # type: ignore[misc]
                        pipeline_type, _pipe
                    ).consumer_get_barrier(pipeline_state)
            prim_barrier_array = cutlass.Array(cute_barrier_pointer, shape=(1,))
        loop_end = (
            resolved_domain
            if cutlass.const_expr(resolved_domain is not None)
            else self.domain
        )
        return StageInfo(
            loop_offset=idx,
            loop_start=self.domain_start,
            loop_end=loop_end,
            loop_step=self.step,
            stage_idx=stage_idx,
            label=label,
            barrier=prim_barrier_array,
            work_tile=work_tile,
            context=context,
            task_cache=self.make_task_cache(),
        )

    @cute.jit
    def _run_task_body_persistent(
        self, context: Optional[ResourceContext] = None
    ) -> None:
        """Persistent work loop: iterate while the tile scheduler provides valid tiles.

        Each iteration calls ``_run_task_body_impl`` for one work tile.
        The ``consumer_work`` callback publishes the next tile through
        ``consumer_vars["work_tile"]``.  After the loop exits,
        ``producer_tail`` is invoked on the work queue pipeline to drain
        any in-flight stages.
        """
        assert self.work_queue is not None
        work_tile = self.work_queue.initial_work_tile_info()
        self.work_queue._set_consumer_var_from_ts("work_tile", work_tile)

        self._run_pre_work_loop_entries(work_tile, context)
        work_tile = self.work_queue._get_consumer_var_from_ts("work_tile")
        for resource in self.dst_resources:
            if cutlass.const_expr(
                resource.pipeline_config is not None
                and resource.pipeline_config.advance_on_acquire
                and not self._is_fork_secondary(resource)
            ):
                self._thread_advance_on_acquire_state(resource)
        while work_tile.is_valid_tile:
            if cutlass.const_expr(self._has_skip_if):
                skip_work_tile = self._should_skip_work_tile(work_tile)
                self._run_task_body_impl(work_tile, skip_work_tile, context)
            else:
                self._run_task_body_impl(work_tile, context=context)
            work_tile = self.work_queue._get_consumer_var_from_ts("work_tile")

        self._run_post_work_loop_entries(work_tile, context)
        # Drain in-flight pipeline stages for every dst resource.
        # PTX requires all outstanding mbarrier arrivals to be completed
        # before the producing warp exits; without this the kernel hits
        # cudaErrorLaunchFailure (error 719).
        for resource in self.dst_resources:
            if cutlass.const_expr(
                resource.pipeline_config is not None
                and resource is not self.work_queue
                and not self._is_fork_secondary(resource)
            ):
                pipeline_config = resource.pipeline_config
                assert pipeline_config is not None
                if cutlass.const_expr(pipeline_config.advance_on_acquire):
                    self._thread_advance_on_acquire_state(resource)
                self._producer_tail(resource)
        # Call producer_tail on the work queue pipeline after the persistent loop
        # to ensure all in-flight stages are properly drained.
        if cutlass.const_expr(
            self.work_queue is not None
            and self.work_queue in self.dst_resources
            and self.work_queue.pipeline_config is not None
        ):
            self.work_queue.producer_tail()

    @cute.jit
    def _run_task_body_non_persistent(
        self, context: Optional[ResourceContext] = None
    ) -> None:
        """Single-shot execution for non-persistent tasks (no loop over work tiles).

        Constructs a ``WorkTileInfo`` from ``cute.arch.block_idx()`` so that
        ``stage_info.work_tile`` is always available (consistent with
        persistent schedules).
        """
        work_tile = WorkTileInfo(cute.arch.block_idx(), cutlass.Boolean(True))
        self._run_task_body_impl(work_tile, context=context)
        for resource in self.dst_resources:
            if cutlass.const_expr(
                resource.pipeline_config is not None
                and resource is not self.work_queue
                and not self._is_fork_secondary(resource)
            ):
                assert resource.pipeline_config is not None
                if cutlass.const_expr(resource.pipeline_config.advance_on_acquire):
                    self._thread_advance_on_acquire_state(resource)
                _producer_stride = (
                    resource.pipeline_config.producer_acquire_interleave_stride
                )
                if cutlass.const_expr(_producer_stride > 1):
                    # Interleaved: drain (per_warp_stages - 1) stages.
                    # The last stage was already consumed/released in the
                    # final loop iteration. Draining it again would
                    # deadlock because the phase wrapped back.
                    _cfg = resource.pipeline_config
                    _state = resource.producer_state
                    _drain_count = _cfg.num_stages // _producer_stride - 1
                    for _di in cutlass.range_constexpr(_drain_count):
                        resource.pipeline.sync_object_empty.wait(
                            _state.index,
                            _state.phase,
                        )
                        self._strided_advance(_state, _cfg, _producer_stride)
                else:
                    self._producer_tail(resource)

    @cute.jit
    def _should_skip_work_tile(self, work_tile: WorkTileInfo) -> bool:
        """Return true when a persistent work tile should only run bookkeeping.

        Captured schedules pass an explicit ``skip_if`` predicate from
        ``work_tile_loop(skip_if=...)``.  The TS still owns the
        control flow: a skipped tile runs only non-skippable HEAD/TAIL slots,
        normally PDL/WorkQueue bookkeeping, and omits the skippable loop body.
        """
        if cutlass.const_expr(self.skip_if is not None):
            assert self.skip_if is not None
            assert self.work_queue is not None
            if cutlass.const_expr(self._skip_if_passes_work_queue):
                skip_work_tile = self.skip_if(self.work_queue, work_tile)
            else:
                skip_work_tile = self.skip_if(work_tile)
            self.work_queue._set_consumer_var_from_ts("skip_work_tile", skip_work_tile)
            return cast(bool, skip_work_tile)
        skip_work_tile = cutlass.Boolean(False)
        if cutlass.const_expr(
            self.work_queue is not None
            and "skip_work_tile"
            in object.__getattribute__(self.work_queue, "consumer_vars")
        ):
            assert self.work_queue is not None
            self.work_queue._set_consumer_var_from_ts("skip_work_tile", skip_work_tile)
        return cast(bool, skip_work_tile)

    @cute.jit
    def _run_persistent_skip_iteration(
        self,
        work_tile: WorkTileInfo,
        context: Optional[ResourceContext] = None,
    ) -> None:
        """Run non-skippable head/tail entries for one inactive tile."""
        tile_coord = work_tile.tile_idx
        resolved_domain = self.get_domain(tile_coord)

        for (
            resource_head,
            schedule_stage_head,
            call_id_head,
            label_head,
        ) in self.head_schedule_list:
            if cutlass.const_expr(
                (id(resource_head), schedule_stage_head, call_id_head)
                not in self.skippable_head_slots
            ):
                work_method_head = self._resolve_work_method(
                    resource_head,
                    schedule_stage_head,
                    label_head,
                    require_label_for_named=self.captured_schedule,
                )
                routing_slot = self._routing_slot(
                    resource_head,
                    schedule_stage_head,
                    ScheduleStageType.Head,
                    call_id_head,
                )
                stage_info_head = self._create_stage_info(
                    resource_head,
                    0,
                    work_tile,
                    is_producer=self._is_producer_stage(schedule_stage_head),
                    resolved_domain=resolved_domain,
                    label=label_head,
                    schedule_stage=schedule_stage_head,
                    routing_slot=routing_slot,
                    context=context,
                )
                self._run_step(
                    resource_head,
                    stage_info_head,
                    schedule_stage_head,
                    work_method_head,
                    routing_slot,
                )

        for (
            resource_tail,
            schedule_stage_tail,
            call_id_tail,
            label_tail,
        ) in self.tail_schedule_list:
            if cutlass.const_expr(
                (id(resource_tail), schedule_stage_tail, call_id_tail)
                not in self.skippable_tail_slots
            ):
                is_producer_tail = self._is_producer_stage(schedule_stage_tail)
                work_method_tail = self._resolve_work_method(
                    resource_tail,
                    schedule_stage_tail,
                    label_tail,
                    require_label_for_named=self.captured_schedule,
                )
                routing_slot = self._routing_slot(
                    resource_tail,
                    schedule_stage_tail,
                    ScheduleStageType.Tail,
                    call_id_tail,
                )
                _, tail_loop_offset = self._peeled_loop_bounds(
                    self.domain_start, resolved_domain, self.step
                )
                stage_info_tail = self._create_stage_info(
                    resource_tail,
                    tail_loop_offset,
                    work_tile,
                    is_producer_tail,
                    resolved_domain,
                    label=label_tail,
                    schedule_stage=schedule_stage_tail,
                    routing_slot=routing_slot,
                    context=context,
                )
                self._run_step(
                    resource_tail,
                    stage_info_tail,
                    schedule_stage_tail,
                    work_method_tail,
                    routing_slot,
                )

    @cute.jit
    def _run_pre_work_loop_entries(
        self,
        work_tile: WorkTileInfo,
        context: Optional[ResourceContext] = None,
    ) -> None:
        """Run head entries captured before ``work_tile_loop()`` starts."""
        for (
            resource_head,
            schedule_stage_head,
            call_id_head,
            label_head,
        ) in self.head_schedule_list:
            if cutlass.const_expr(
                (id(resource_head), schedule_stage_head, call_id_head)
                in self.pre_work_loop_head_slots
            ):
                work_method_head = self._resolve_work_method(
                    resource_head,
                    schedule_stage_head,
                    label_head,
                    require_label_for_named=self.captured_schedule,
                )
                routing_slot = self._routing_slot(
                    resource_head,
                    schedule_stage_head,
                    ScheduleStageType.Head,
                    call_id_head,
                )
                stage_info_head = self._create_stage_info(
                    resource_head,
                    0,
                    work_tile,
                    is_producer=self._is_producer_stage(schedule_stage_head),
                    resolved_domain=0,
                    label=label_head,
                    schedule_stage=schedule_stage_head,
                    routing_slot=routing_slot,
                    context=context,
                )
                self._run_step(
                    resource_head,
                    stage_info_head,
                    schedule_stage_head,
                    work_method_head,
                    routing_slot,
                )

    @cute.jit
    def _run_post_work_loop_entries(
        self,
        work_tile: WorkTileInfo,
        context: Optional[ResourceContext] = None,
    ) -> None:
        """Run tail entries captured after ``work_tile_loop()`` exits."""
        for (
            resource_tail,
            schedule_stage_tail,
            call_id_tail,
            label_tail,
        ) in self.tail_schedule_list:
            if cutlass.const_expr(
                (id(resource_tail), schedule_stage_tail, call_id_tail)
                in self.post_work_loop_tail_slots
            ):
                work_method_tail = self._resolve_work_method(
                    resource_tail,
                    schedule_stage_tail,
                    label_tail,
                    require_label_for_named=self.captured_schedule,
                )
                routing_slot = self._routing_slot(
                    resource_tail,
                    schedule_stage_tail,
                    ScheduleStageType.Tail,
                    call_id_tail,
                )
                stage_info_tail = self._create_stage_info(
                    resource_tail,
                    0,
                    work_tile,
                    is_producer=self._is_producer_stage(schedule_stage_tail),
                    resolved_domain=0,
                    label=label_tail,
                    schedule_stage=schedule_stage_tail,
                    routing_slot=routing_slot,
                    context=context,
                )
                self._run_step(
                    resource_tail,
                    stage_info_tail,
                    schedule_stage_tail,
                    work_method_tail,
                    routing_slot,
                )

    def _run_task_body_with_advance_on_acquire_state(
        self,
        resource_index: int,
        work_tile: WorkTileInfo,
        skip_work_tile: Any,
        context: Optional[ResourceContext],
    ) -> None:
        """Thread split producer cursors across one work-tile schedule body."""
        if resource_index >= len(self._advance_on_acquire_state_resources):
            self._run_task_body_impl_schedule(work_tile, skip_work_tile, context)
            return

        resource = self._advance_on_acquire_state_resources[resource_index]
        if cutlass.const_expr(
            resource.pipeline_config is None
            or not resource.pipeline_config.advance_on_acquire
        ):
            self._run_task_body_with_advance_on_acquire_state(
                resource_index + 1,
                work_tile,
                skip_work_tile,
                context,
            )
            return

        input_state = list(self._load_advance_on_acquire_state(resource))

        def active_body(
            producer_index: Any,
            producer_count: Any,
            producer_phase: Any,
            commit_index: Any,
            commit_count: Any,
            commit_phase: Any,
            producer_status: Any,
        ) -> tuple:
            self._store_advance_on_acquire_state(
                resource,
                producer_index,
                producer_count,
                producer_phase,
                commit_index,
                commit_count,
                commit_phase,
                producer_status,
            )

            self._run_task_body_with_advance_on_acquire_state(
                resource_index + 1,
                work_tile,
                skip_work_tile,
                context,
            )
            return self._load_advance_on_acquire_state(resource)

        updated_state = cutlass.if_generate(
            cutlass.Boolean(True),
            active_body,
            input_args=input_state,
            return_types=[cutlass.Int32] * 7,
        )
        self._store_advance_on_acquire_state(resource, *updated_state)

    @cute.jit
    def _run_task_body_impl(
        self,
        work_tile: WorkTileInfo,
        skip_work_tile: Any = None,
        context: Optional[ResourceContext] = None,
    ) -> None:
        """Execute one work tile while threading split producer cursors."""
        self._run_task_body_with_advance_on_acquire_state(
            0,
            work_tile,
            skip_work_tile,
            context,
        )

    @cute.jit
    def _run_task_body_impl_schedule(
        self,
        work_tile: WorkTileInfo,
        skip_work_tile: Any = None,
        context: Optional[ResourceContext] = None,
    ) -> None:
        """Execute one work tile through the full head -> loop -> tail schedule.

        1. Resolve the domain via ``get_domain(tile_coord)`` (may be dynamic).
        2. Head schedule stages once before the loop over the computational domain.
        3. Loop schedule stages ``range(0, resolved_domain, step)``.
        4. Tail schedule stages once after the loop over the computational domain.
        """
        # IMPORTANT DSL RULE: Cannot use the same Python variable name outside,
        # then inside, then outside of a dynamic loop. Each section must use
        # unique variable names (e.g., stage_info_head, stage_info, stage_info_tail)

        tile_coord = work_tile.tile_idx
        resolved_domain = self.get_domain(tile_coord)

        # Execute head schedule (prefetch phase)
        if cutlass.const_expr(skip_work_tile is None):
            for (
                resource_head,
                schedule_stage_head,
                call_id_head,
                label_head,
            ) in self.head_schedule_list:
                if cutlass.const_expr(
                    self.is_persistent
                    and (id(resource_head), schedule_stage_head, call_id_head)
                    in self.pre_work_loop_head_slots
                ):
                    continue
                self._run_head_entry(
                    resource_head,
                    schedule_stage_head,
                    call_id_head,
                    label_head,
                    work_tile,
                    resolved_domain,
                    context,
                )
        else:
            for is_skippable_head, head_entries in self._head_exec_groups:
                if cutlass.const_expr(is_skippable_head):
                    if skip_work_tile == cutlass.Boolean(False):
                        self._run_head_entry_group(
                            head_entries,
                            work_tile,
                            resolved_domain,
                            context,
                        )
                else:
                    self._run_head_entry_group(
                        head_entries, work_tile, resolved_domain, context
                    )

        # Execute loop schedule (steady state)
        # Uses pre-computed _loop_exec_groups: consecutive entries with the
        # same LoopGuard are batched into a single group so they execute
        # inside one scf.if block (avoids state-threading bugs between
        # multiple scf.if blocks sharing the same dynamic condition).
        #
        # Loop peeling for LastIter: when LastIter entries exist, the
        # last iteration is peeled out of the scf.for and executed as
        # straight-line code after the loop.  This avoids a conditional
        # scf.if(is_last_iter) inside scf.for inside scf.while which
        # triggers a ptxas codegen bug in persistent mode (mbarrier
        # arrive/commit inside the conditional produces wrong results
        # for the second pipeline stage only — O1 100% wrong).
        if cutlass.const_expr(skip_work_tile is not None):

            def skip_body(_resolved_domain: Any) -> Any:
                del _resolved_domain
                return cutlass.Int32(self.domain_start)

            def keep_body(_resolved_domain: Any) -> Any:
                return _resolved_domain

            loop_domain = cutlass.if_generate(
                skip_work_tile,
                skip_body,
                keep_body,
                cast(list, [cutlass.Int32(resolved_domain)]),
                [cutlass.Int32],
            )
            if cutlass.const_expr(self._has_last_iter):
                self._run_loop_peeled(loop_domain, work_tile, context)
            else:
                self._run_loop_simple(loop_domain, work_tile, context)
        else:
            if cutlass.const_expr(self._has_last_iter):
                self._run_loop_peeled(resolved_domain, work_tile, context)
            else:
                self._run_loop_simple(resolved_domain, work_tile, context)

        # Execute tail schedule (drain phase)
        if cutlass.const_expr(skip_work_tile is None):
            for (
                resource_tail,
                schedule_stage_tail,
                call_id_tail,
                label_tail,
            ) in self.tail_schedule_list:
                if cutlass.const_expr(
                    self.is_persistent
                    and (id(resource_tail), schedule_stage_tail, call_id_tail)
                    in self.post_work_loop_tail_slots
                ):
                    continue
                self._run_tail_entry(
                    resource_tail,
                    schedule_stage_tail,
                    call_id_tail,
                    label_tail,
                    work_tile,
                    resolved_domain,
                    context,
                )
        else:
            for is_skippable_tail, tail_entries in self._tail_exec_groups:
                if cutlass.const_expr(is_skippable_tail):
                    if skip_work_tile == cutlass.Boolean(False):
                        self._run_tail_entry_group(
                            tail_entries,
                            work_tile,
                            resolved_domain,
                            context,
                        )
                else:
                    self._run_tail_entry_group(
                        tail_entries, work_tile, resolved_domain, context
                    )
    @cute.jit
    def is_selected(self) -> bool:
        """Return ``True`` if the current warp falls within this task's range."""
        # Use make_warp_uniform so ptxas knows this branch is warp-uniform
        # (all threads in the warp take the same path). Without this, ptxas
        # conservatively treats code after the branch as divergent, preventing
        # uniform register promotion for address computations.
        warp_id = cute.arch.warp_idx()
        selected = warp_id >= self.warp_start and warp_id < self.warp_end
        if cutlass.const_expr(self.run_only_on_cta_id is not None):
            cta_rank_in_cluster = cute.arch.make_warp_uniform(
                cute.arch.block_idx_in_cluster()
            )
            selected = selected and cta_rank_in_cluster == self.run_only_on_cta_id
        return selected

    @cute.jit
    def init_variables(self, context: Optional[ResourceContext] = None) -> None:
        """Create resource variables outside dynamic control flow.

        Must be called before any ``scf.if`` dispatch to keep the DSL
        IR structure stable.  ``TaskManager.run()`` calls this for
        every task before entering the dispatch chain.

        Parameters
        ----------
        context : ResourceContext or None
            Carries ``smem_base`` and/or ``tmem_ptr_i32`` when
            allocators are in use.
        """
        for resource in self.resources:
            resource.initialize_runtime_state_internal(
                context,
                captured_schedule=self.captured_schedule,
            )

        # Legacy-mode hooks (no-ops + override checks in captured mode).
        for resource in self.src_resources:
            resource.create_consumer_variables_internal(
                captured_schedule=self.captured_schedule
            )
        for resource in self.dst_resources:
            resource.create_producer_variables_internal(
                captured_schedule=self.captured_schedule
            )

        # Captured-mode auto-allocation: walk the schedule's slot_routing
        # and allocate every destination slot (producer_vars or
        # consumer_vars) from the writer's consumer_vars.  This handles
        # both same-name routing (gmem.compute_coords -> smem.tma_load),
        # explicit aliases (smem_q.q0_desc -> tmem_sp.qk_mma's
        # desc_q_base=desc_q0_base), and consumer-to-consumer routes
        # (tmem_vec.read_vec -> tmem_o.correct).  Replaces the legacy
        # create_producer_variables / create_consumer_variables overrides
        # for slot allocation.
        if cutlass.const_expr(self.captured_schedule):
            self._allocate_slots_from_routing()

    @cute.jit
    def _allocate_slots_from_routing(self) -> None:
        """Auto-allocate dst-side slots from ``self.slot_routing`` edges.

        For every routing edge (writer slot -> destination), looks up
        the writer's ``consumer_vars[src_name]`` (seeded from
        ``TaskLocalVariable`` defaults in captured mode) and copies that
        initial value into the destination dict
        (``producer_vars`` for Producer*Work destinations,
        ``consumer_vars`` for Consumer*Work destinations) under the
        possibly-aliased ``dst_name``. Slots already populated by the
        destination resource's own ``TaskLocalVariable`` default are left
        untouched.

        Broadcast routes (``var_names is None``) fall back to copying
        every name from the writer's ``consumer_vars`` that is not
        already present in the destination.

        Errors
        ------
        - Aliased route names a source that is not in the writer's
          ``consumer_vars``: ``ValueError`` (likely typo or missing
          upstream emitter).
        """
        if cutlass.const_expr(self.slot_routing is not None):
            assert self.slot_routing is not None
            res_by_id: dict[int, MemoryResource] = {id(r): r for r in self.resources}
            for writer_key, route_dest_pairs in self.slot_routing.items():
                writer = res_by_id.get(writer_key[0])
                if cutlass.const_expr(writer is not None):
                    assert writer is not None
                    writer_consumer = object.__getattribute__(writer, "consumer_vars")
                    declared_writer_slots = _task_local_slot_names(writer)
                    for var_routes, destinations in route_dest_pairs:
                        for dst_entry in destinations:
                            parts = cast("tuple[Any, ...]", dst_entry)
                            if cutlass.const_expr(len(parts) == 3):
                                dst_resource, dst_stage, _ = parts
                            else:
                                dst_resource, dst_stage, _, _ = parts
                            dst_dict_name = (
                                "consumer_vars"
                                if _is_consumer_dst_stage(dst_stage)
                                else "producer_vars"
                            )
                            dst_dict = object.__getattribute__(
                                dst_resource, dst_dict_name
                            )
                            if cutlass.const_expr(var_routes is None):
                                # Broadcast: copy every name from writer not already present.
                                for src_name, value in writer_consumer.items():
                                    if cutlass.const_expr(src_name not in dst_dict):
                                        dst_dict[src_name] = value
                            else:
                                assert var_routes is not None
                                for route in var_routes:
                                    if cutlass.const_expr(isinstance(route, tuple)):
                                        src_name, dst_name = cast(
                                            "tuple[str, str]", route
                                        )
                                    else:
                                        src_name = dst_name = cast(str, route)
                                    if cutlass.const_expr(
                                        src_name not in writer_consumer
                                    ):
                                        if cutlass.const_expr(
                                            src_name in declared_writer_slots
                                        ):
                                            continue
                                        raise ValueError(
                                            f"slot_routing edge from "
                                            f"{writer.name!r}: source var "
                                            f"'{src_name}' is not in "
                                            f"{writer.name!r}.consumer_vars "
                                            f"(seeded by TaskLocalVariable "
                                            f"defaults). Declare '{src_name}' as "
                                            f"a TaskLocalVariable on that resource."
                                        )
                                    if cutlass.const_expr(dst_name not in dst_dict):
                                        dst_dict[dst_name] = writer_consumer[src_name]

    def _has_interleaved_pipeline(self) -> bool:
        """Python-time check: this task's resources use strided state."""
        return any(
            r.pipeline_config is not None and r.pipeline_config.has_interleaved_stride
            for r in self.resources
        )

    def _uses_domain_interleave_lane(self, stride: int) -> bool:
        """Use domain_start as the lane when loop iterations are split by stride."""
        return (
            stride > 1
            and self.num_warps != stride
            and isinstance(self.step, int)
            and self.step == stride
            and isinstance(self.domain_start, int)
        )

    @cute.jit
    def _interleave_lane(self, stride: int) -> cutlass.Int32:
        """Return the resource-level interleave lane for this task."""
        if cutlass.const_expr(self._uses_domain_interleave_lane(stride)):
            return cutlass.Int32(self.domain_start % stride)
        return cutlass.Int32(cute.arch.warp_idx() - self.warp_start)

    @cute.jit
    def _strided_advance(
        self, state: Any, pipeline_config: PipelineConfig, stride: Any
    ) -> None:
        """Advance pipeline state by ``stride`` instead of 1.

        Manually implements strided advancement since the upstream
        ``PipelineState.advance()`` doesn't accept a stride parameter.
        Increments ``_index`` by ``stride`` and wraps with phase flip
        when the index reaches ``num_stages``.
        """
        self._advance_pipeline_state(state, pipeline_config, stride)

    @cute.jit
    def _init_interleaved_state(self) -> None:
        """Set initial pipeline state index to the selected resource lane."""
        if cutlass.const_expr(
            any(
                (
                    r.state_src.pipeline_config is not None
                    and (
                        self._uses_domain_interleave_lane(
                            r.state_src.pipeline_config.consumer_wait_interleave_stride
                        )
                        or self._uses_domain_interleave_lane(
                            r.state_src.pipeline_config.consumer_release_interleave_stride
                        )
                    )
                )
                for r in self.src_resources
            )
            or any(
                (
                    r.pipeline_config is not None
                    and (
                        self._uses_domain_interleave_lane(
                            r.pipeline_config.producer_acquire_interleave_stride
                        )
                        or self._uses_domain_interleave_lane(
                            r.pipeline_config.producer_commit_interleave_stride
                        )
                    )
                )
                for r in self.dst_resources
            )
        ):
            # Domain-lane tasks seed a task-constant lane into state shared by
            # sibling tasks.  Gate the write so each task initializes only its
            # selected warps; otherwise a later task can overwrite every warp's
            # lane and leave pipeline stages permanently unowned.
            if self.is_selected():
                self._init_interleaved_state_impl()
            return
        self._init_interleaved_state_impl()

    @cute.jit
    def _init_interleaved_state_impl(self) -> None:
        """Set initial interleaved pipeline states for this task."""
        for resource in self.src_resources:
            # Consumer states live on ``state_src`` (Merge members share the
            # group's state), so the governing config is the owner's config.
            _cfg = resource.state_src.pipeline_config
            if cutlass.const_expr(_cfg is None):
                continue
            assert _cfg is not None
            _consumer_state = resource.state_src.consumer_state
            _consumer_state_ok = cutlass.const_expr(
                _consumer_state is not None
                and not isinstance(_consumer_state, cutlass.Int32)
            )
            if cutlass.const_expr(
                _cfg.consumer_wait_interleave_stride > 1 and _consumer_state_ok
            ):
                _consumer_state._index = self._interleave_lane(
                    _cfg.consumer_wait_interleave_stride
                )
            if cutlass.const_expr(_cfg.consumer_release_interleave_stride > 1):
                release_lane = self._interleave_lane(
                    _cfg.consumer_release_interleave_stride
                )
                # When ``advance_on_wait`` is set, release tracks a separate
                # state; otherwise release shares ``consumer_state`` (already
                # initialized above when the wait role is interleaved).  The
                # release state is an ``Int32`` placeholder unless the owner
                # uses ``advance_on_wait``, so guard the write.
                if cutlass.const_expr(_cfg.advance_on_wait):
                    _release_state = resource.state_src.consumer_release_state
                    if cutlass.const_expr(
                        _release_state is not None
                        and not isinstance(_release_state, cutlass.Int32)
                    ):
                        _release_state._index = release_lane
                elif cutlass.const_expr(_consumer_state_ok):
                    _consumer_state._index = release_lane
        for resource in self.dst_resources:
            _cfg = resource.pipeline_config
            if cutlass.const_expr(
                _cfg is None
                or resource.producer_state is None
                or isinstance(resource.producer_state, cutlass.Int32)
            ):
                continue
            assert _cfg is not None
            if cutlass.const_expr(_cfg.producer_acquire_interleave_stride > 1):
                acquire_lane = self._interleave_lane(
                    _cfg.producer_acquire_interleave_stride
                )
                resource.producer_state._index = acquire_lane
                if cutlass.const_expr(_cfg.advance_on_acquire):
                    resource.producer_work_state._index = acquire_lane
            if cutlass.const_expr(_cfg.producer_commit_interleave_stride > 1):
                commit_lane = self._interleave_lane(
                    _cfg.producer_commit_interleave_stride
                )
                # When ``advance_on_acquire`` is set, commit tracks a separate
                # state; otherwise commit shares ``producer_state`` (already
                # initialized above when the acquire role is interleaved).
                if cutlass.const_expr(_cfg.advance_on_acquire):
                    resource.producer_commit_state._index = commit_lane
                else:
                    resource.producer_state._index = commit_lane

    @cute.jit
    def make_task_cache(self) -> object:
        """Return an optional task-defined payload captured into ``StageInfo``.

        Override in task subclasses when hot resource paths need a few cached
        task-local values without widening ``StageInfo`` field-by-field.
        """
        return None

    @cute.jit
    def run_body(self, context: Optional[ResourceContext] = None) -> None:
        """Gate on warp selection and execute the task body.

        Call only after ``init_variables()`` has already been invoked
        for *all* tasks.  ``context`` is forwarded explicitly into
        ``StageInfo`` so traced task structure does not change at runtime.
        """
        if self.is_selected():
            _ptx_comment(
                self.name + " warp: [%d, %d)" % (self.warp_start, self.warp_end)
            )
            self._set_max_register()
            if cutlass.const_expr(self.is_persistent):
                self._run_task_body_persistent(context)
            else:
                self._run_task_body_non_persistent(context)

    @cute.jit
    def run(self) -> None:
        """Top-level entry point executed by ``TaskManager.run()``.

        1. Initialises function-level and role-level variables on
           *every* resource (outside dynamic control flow to keep the
           DSL IR structure stable).
        2. Gates on ``is_selected()`` so only the assigned warps proceed.
        3. Sets the register budget via ``_set_max_register``.
        4. Dispatches to persistent or non-persistent body.
        """
        self.init_variables()
        self.run_body()
