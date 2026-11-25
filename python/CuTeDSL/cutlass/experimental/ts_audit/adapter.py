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

"""The ONLY module that reads ``task_scheduling`` attribute names.

``task_scheduling`` is a fast-moving framework owned by another team; it
knows nothing about this package. Everything the audit needs from a live
framework object is read here, once, into a small frozen record. The
emitter then works on those records and never touches a framework object.

**Required vs optional.** Every attribute the framework *declares* -- a
dataclass field, or one its ``__init__`` always assigns -- is read
WITHOUT a default, so a rename is recorded as a miss and the item is
dropped. A default is reserved for attributes that may genuinely be
absent from a well-formed object, and each such call says why. Passing a
default for a declared field would turn a rename into silent data loss,
which is the exact failure this module exists to prevent.

Reading through :func:`field` is what makes a framework change VISIBLE
instead of silent: a missing attribute is recorded as ``Type.attr`` and
the item it belonged to is dropped (its builder returns ``None``), so the
audit skips that item and reports what it could not read. Nothing here
raises on a missing attribute, and nothing here mutates a framework
object.

The one framework contract this package still depends on is the *set of
attribute names* recorded in the module tables below; the ts_audit
contract test fails the moment a tutorial-shaped schedule stops
satisfying it.
"""

from dataclasses import dataclass, field as _dc_field
from typing import Any, Optional

__all__ = [
    "CondInfo",
    "DeclarationPlan",
    "DrainInfo",
    "GroupDecl",
    "GuardSpec",
    "LoopInfo",
    "MISSING",
    "PipelineConfigInfo",
    "QueueDecl",
    "ResourceDecl",
    "SlotDecl",
    "StepInfo",
    "TaskInfo",
    "caller_loc",
    "clear_missing_fields",
    "collect_declarations",
    "cond_info",
    "domain_loop_info",
    "drain_info",
    "field",
    "group_decl",
    "guard_spec",
    "is_pipeline_group",
    "is_work_queue",
    "manager_tasks",
    "missing_fields",
    "pipeline_config_info",
    "queue_decl",
    "resource_decl",
    "slot_decl",
    "step_info",
    "task_info",
    "work_tile_loop_info",
]


class _Missing:
    """Sentinel distinguishing "no default" from a default of ``None``."""

    def __repr__(self) -> str:  # pragma: no cover - debugging aid
        return "MISSING"


MISSING = _Missing()

#: ``"Type.attr"`` for every framework attribute this process failed to
#: read. Never cleared by the emitter -- a degradation is a property of
#: the process, and the report lists all of it at once.
_missing_fields: set[str] = set()


def missing_fields() -> tuple[str, ...]:
    """Sorted ``Type.attr`` names this process could not read."""
    return tuple(sorted(_missing_fields))


def clear_missing_fields() -> None:
    """Forget the recorded misses (tests only)."""
    _missing_fields.clear()


def field(obj: Any, name: str, default: Any = MISSING) -> Any:
    """Read ``obj.name``, recording the miss when the attribute is absent.

    With a ``default`` the attribute is optional and the default is
    returned. Without one the attribute is required: the miss is recorded
    as ``Type.name`` and ``MISSING`` is returned, which every builder
    below turns into a dropped item.
    """
    try:
        return getattr(obj, name)
    except AttributeError:
        pass
    if default is not MISSING:
        return default
    _missing_fields.add(f"{type(obj).__name__}.{name}")
    return MISSING


def _all_present(*values: Any) -> bool:
    return all(value is not MISSING for value in values)


# --------------------------------------------------------------------- #
# Declarations.
# --------------------------------------------------------------------- #


@dataclass(frozen=True)
class PipelineConfigInfo:
    """A resource's pipeline configuration as C++-builder primitives.

    ``spec`` keys mirror the ``#ts.pipeline_config`` keyword syntax; the
    builder consumes it verbatim.
    """

    spec: dict


@dataclass(frozen=True)
class ResourceDecl:
    """One ``ts.resource`` declaration."""

    name: str
    type_name: str
    pipeline_config: Optional[PipelineConfigInfo]
    source_file: str
    source_line: int


@dataclass(frozen=True)
class QueueDecl:
    """One ``ts.work_queue`` declaration."""

    name: str
    scheduler: Optional[str]
    num_stages: Optional[int]
    skip_if: Optional[str]


@dataclass(frozen=True)
class GroupDecl:
    """One ``ts.pipeline_group`` declaration; ``members`` are the objects."""

    name: str
    mode: str
    members: tuple


@dataclass(frozen=True)
class SlotDecl:
    """One ``ts.slot`` declaration."""

    name: str
    types: tuple


_PIPELINE_TYPE_SPELLING = {
    "AsyncAsync": "async_async",
    "TmaAsync": "tma_async",
    "TmaUmma": "tma_umma",
    "UmmaAsync": "umma_async",
    "AsyncUmma": "async_umma",
    "UmmaUmma": "umma_umma",
    "ClcFetchAsync": "clc_fetch_async",
}

_GROUP_MODE_SPELLING = {
    "Merge": "merge",
    "Fork": "fork",
    "FusedMerge": "fused_merge",
}

_SCHEDULER_TYPE_SPELLING = {
    "StaticPersistent": "static_persistent",
    "ClcDynamicPersistent": "clc_dynamic_persistent",
}

_SIGNALING_SPELLING = {
    "All": "all",
    "CtaLeader": "cta_leader",
    "TaskWarpLeader": "task_warp_leader",
}

#: PipelineConfig attributes read unconditionally. A framework rename of
#: any of them drops the whole config (and its resource's pipeline facts).
_PIPELINE_CONFIG_REQUIRED = (
    "pipeline_type",
    "num_stages",
    "num_bytes",
    "producer_group",
    "consumer_group",
    "producer_signaling_threads",
    "consumer_signaling_threads",
    "advance_on_wait",
    "advance_on_acquire",
    "mcast_mode_mn",
    "interleave_stride",
    "defer_init",
    "consumer_wait_signaling_threads",
    "async_producer_op",
    "umma_consumer_producer_op",
    "num_bytes_per_warp_per_cta",
    "storage_offset_full",
    "storage_offset_empty",
    "cta_layout_vmnk",
)


def _signaling_spelling(value: Any) -> str:
    """``SignalingThreads`` flag combination as ``a|b`` bare keywords."""
    parts = [flag.name for flag in type(value) if flag in value and flag.name]
    if not parts:
        parts = [value.name]
    return "|".join(_SIGNALING_SPELLING[p] for p in parts)


def _cooperative_group(group: Any) -> dict:
    return {
        "agent": str(getattr(getattr(group, "agent", None), "name", "thread")).lower(),
        "size": int(getattr(group, "size", 1)),
        "alignment": int(getattr(group, "alignment", 1) or 1),
    }


def pipeline_config_info(cfg: Any) -> Optional[PipelineConfigInfo]:
    """Marshal a ``PipelineConfig``, or ``None`` when it cannot be read."""
    values = {name: field(cfg, name) for name in _PIPELINE_CONFIG_REQUIRED}
    if not _all_present(*values.values()):
        return None
    stride = values["interleave_stride"]
    strides = list(stride) if isinstance(stride, tuple) else [int(stride)] * 4
    spec = {
        "pipeline_type": _PIPELINE_TYPE_SPELLING[values["pipeline_type"].name],
        "num_stages": int(values["num_stages"]),
        "num_bytes": int(values["num_bytes"]),
        "producer_group": _cooperative_group(values["producer_group"]),
        "consumer_group": _cooperative_group(values["consumer_group"]),
        "producer_signaling_threads": _signaling_spelling(
            values["producer_signaling_threads"]
        ),
        "consumer_signaling_threads": _signaling_spelling(
            values["consumer_signaling_threads"]
        ),
        "advance_on_wait": bool(values["advance_on_wait"]),
        "advance_on_acquire": bool(values["advance_on_acquire"]),
        "mcast_mode_mn": [int(v) for v in values["mcast_mode_mn"]],
        "interleave_stride": [int(v) for v in strides],
        "defer_init": bool(values["defer_init"]),
    }
    if values["consumer_wait_signaling_threads"] is not None:
        spec["consumer_wait_signaling_threads"] = _signaling_spelling(
            values["consumer_wait_signaling_threads"]
        )
    spec["async_producer_op"] = getattr(
        values["async_producer_op"], "name", "AsyncThread"
    )
    spec["umma_consumer_producer_op"] = getattr(
        values["umma_consumer_producer_op"], "name", "AsyncThread"
    )
    if values["num_bytes_per_warp_per_cta"] is not None:
        spec["num_bytes_per_warp_per_cta"] = int(values["num_bytes_per_warp_per_cta"])
    # The attr semantics are BYTES into the coalesced mbarrier arena; the
    # Python allocator hands out slot indices (BarrierAllocator.offset_of:
    # "in mbarrier slots"), one 8-byte mbarrier per slot.
    bytes_per_mbarrier_slot = 8
    if values["storage_offset_full"] is not None:
        spec["storage_offset_full"] = (
            int(values["storage_offset_full"]) * bytes_per_mbarrier_slot
        )
    if values["storage_offset_empty"] is not None:
        spec["storage_offset_empty"] = (
            int(values["storage_offset_empty"]) * bytes_per_mbarrier_slot
        )
    if values["cta_layout_vmnk"] is not None:
        spec["cta_layout_vmnk"] = str(values["cta_layout_vmnk"])
    return PipelineConfigInfo(spec=spec)


def resource_decl(resource: Any) -> Optional[ResourceDecl]:
    """Marshal a plain memory resource, or ``None`` when it cannot be read."""
    from ..task_scheduling.enums import get_construction_site

    cfg = field(resource, "pipeline_config")
    name = field(resource, "name")
    if not _all_present(cfg, name):
        return None
    config = pipeline_config_info(cfg) if cfg else None
    if cfg and config is None:
        return None
    # Construction site (metaclass-captured) becomes the op loc so "rN"
    # ordinals trace back to the user's declaration line.
    file, line = get_construction_site(resource) or ("", 0)
    return ResourceDecl(
        name=str(name or ""),
        type_name=type(resource).__name__,
        pipeline_config=config,
        source_file=str(file),
        source_line=int(line),
    )


def queue_decl(queue: Any, skip_if: Optional[str]) -> Optional[QueueDecl]:
    """Marshal a work queue, or ``None`` when it cannot be read."""
    scheduler_cfg = field(queue, "tile_scheduler_config")
    cfg = field(queue, "pipeline_config")
    name = field(queue, "name")
    if not _all_present(scheduler_cfg, cfg, name):
        return None
    scheduler = getattr(scheduler_cfg, "tile_scheduler_type", None)
    spelling = (
        _SCHEDULER_TYPE_SPELLING.get(scheduler.name) if scheduler is not None else None
    )
    num_stages = None
    if cfg is not None:
        stages = field(cfg, "num_stages")
        if stages is MISSING:
            return None
        num_stages = int(stages)
    # response_smem_offset intentionally unemitted: the CLC response buffer
    # exists only as a traced pointer today.
    return QueueDecl(
        name=str(name or ""),
        scheduler=spelling,
        num_stages=num_stages,
        skip_if=skip_if,
    )


def group_decl(group: Any) -> Optional[GroupDecl]:
    """Marshal a pipeline group, or ``None`` when it cannot be read."""
    members = field(group, "members")
    mode = field(group, "mode")
    if not _all_present(members, mode):
        return None
    spelling = _GROUP_MODE_SPELLING.get(mode.name)
    if spelling is None:
        _missing_fields.add(f"{type(group).__name__}.mode<{mode.name}>")
        return None
    name = field(group, "name")
    if name is MISSING:
        return None
    return GroupDecl(
        name=str(name or ""),
        mode=spelling,
        members=tuple(members),
    )


def slot_decl(variable: Any) -> "Optional[SlotDecl]":
    """Marshal a task-local slot, or ``None`` when it cannot be read."""
    dtype = field(variable, "dtype")
    name = field(variable, "slot_name")
    if not _all_present(dtype, name):
        return None
    return SlotDecl(
        name=name or "",
        types=(str(dtype),) if dtype is not None else (),
    )


# --------------------------------------------------------------------- #
# Constructs.
# --------------------------------------------------------------------- #

_STAGE_TO_VERB = {
    "ProducerTryAcquire": "try_acquire",
    "ProducerAcquire": "acquire",
    "ProducerCommit": "commit",
    "ConsumerTryWait": "try_wait",
    "ConsumerWait": "wait",
    "ConsumerRelease": "release",
}

_STAGE_TO_WORK_ROLE = {
    "ProducerWork": "producer_work",
    "ConsumerWork": "consumer_work",
    "ProducerAuxWork": "producer_aux",
    "ConsumerAuxWork": "consumer_aux",
}


@dataclass(frozen=True)
class TaskInfo:
    """A task's selected-branch construct payload."""

    name: str
    warp_idx: int
    num_warps: int
    num_registers: Optional[int]
    run_only_on_cta_id: Optional[int]
    src_resources: tuple
    dst_resources: tuple
    schedule_name: str


@dataclass(frozen=True)
class StepInfo:
    """One schedule step: a pipeline verb or a work call."""

    step_id: str
    resource: Any
    verb: Optional[str]
    role: Optional[str]
    callee: Optional[str]
    reads: tuple
    writes: tuple
    call_attrs: dict = _dc_field(default_factory=dict)
    source_loc: Optional[tuple] = None


@dataclass(frozen=True)
class DrainInfo:
    """One resource's post-body drain."""

    resource: Any


@dataclass(frozen=True)
class LoopInfo:
    """A domain loop (``work_queue`` ``None``) or a work-tile loop."""

    work_queue: Any = None


@dataclass(frozen=True)
class GuardSpec:
    """A block guard reduced to a kind and its primitive parameters.

    ``kind`` is one of ``first_iter``, ``last_iter``, ``every``,
    ``skippable``, ``opaque``.
    """

    kind: str
    period: int = 0
    start: int = 0
    key: str = ""
    negated: bool = False


@dataclass(frozen=True)
class CondInfo:
    """A guarded block and the guard driving it."""

    guard: GuardSpec


def _guard_key(guard: Any) -> str:
    """Spell a guard tree as the key of the opaque guard standing in for it.

    Leaves keep their ``#ts`` spelling (``first_iter``, ``every<2,1>``,
    ``opaque<key>``); ``not``, ``and(...)`` and ``or(...)`` wrap them, so the
    key reads as the guard the user wrote, in the negation-normal form the
    framework stores it in. A field a known kind lost is spelled ``?`` and
    recorded as a miss like any required field (``every<2,?>``).
    """
    from ..task_scheduling.enums import (
        FIRST_ITER,
        LAST_ITER,
        ComplementedIterationPredicate,
        Every,
        GuardAnd,
        GuardOr,
        OpaqueCondition,
        is_skippable_guard,
    )

    def spell(value: Any) -> str:
        return "?" if value is MISSING else str(value)

    if guard == FIRST_ITER:
        return "first_iter"
    if guard == LAST_ITER:
        return "last_iter"
    if isinstance(guard, Every):
        return f"every<{spell(field(guard, 'period'))},{spell(field(guard, 'start'))}>"
    if is_skippable_guard(guard):
        return "skippable"
    if isinstance(guard, OpaqueCondition):
        spelled = f"opaque<{spell(field(guard, 'key'))}>"
        negated = field(guard, "negated")
        return f"not {spelled}" if negated is not MISSING and negated else spelled
    if isinstance(guard, ComplementedIterationPredicate):
        predicate = field(guard, "predicate")
        return f"not {'?' if predicate is MISSING else _guard_key(predicate)}"
    if isinstance(guard, (GuardAnd, GuardOr)):
        operator = "and" if isinstance(guard, GuardAnd) else "or"
        operands = field(guard, "operands")
        if operands is MISSING:
            return f"{operator}(?)"
        return f"{operator}({', '.join(_guard_key(operand) for operand in operands)})"
    return f"<unknown:{type(guard).__name__}>"


def guard_spec(guard: Any) -> GuardSpec:
    """Classify a framework block guard. Total: every guard yields a spec.

    A guard without a spec would leave its steps outside any ``cond`` body,
    and the audits would then judge them UNCONDITIONAL -- the one direction
    the never-false-error policy forbids (``with when_false(d.first):
    smem.commit()`` is a legal prefetch, not a commit without acquire). The
    dialect has no compound guard attr, so a complemented iteration
    predicate (``when_false(d.first)``, ``~d.last``) and the ``&`` / ``|``
    trees become opaque guards whose key spells the construct
    (``#ts.guard_opaque<"first_iter", negated>``,
    ``#ts.guard_opaque<"and(first_iter, opaque<ready>)">``); a guard kind
    this adapter has never seen, or a known kind that lost a field, is an
    opaque guard keyed by its type name, and the miss is recorded.

    Value equality (never ``is``): the DSL reconstructs frozen-dataclass
    guards across ``@cute.jit`` boundaries.
    """
    from ..task_scheduling.enums import (
        FIRST_ITER,
        LAST_ITER,
        ComplementedIterationPredicate,
        Every,
        GuardAnd,
        GuardOr,
        OpaqueCondition,
        is_skippable_guard,
    )

    def conservative() -> GuardSpec:
        return GuardSpec(kind="opaque", key=f"<unknown:{type(guard).__name__}>")

    if guard == FIRST_ITER:
        return GuardSpec(kind="first_iter")
    if guard == LAST_ITER:
        return GuardSpec(kind="last_iter")
    if isinstance(guard, Every):
        period = field(guard, "period")
        start = field(guard, "start")
        if not _all_present(period, start):
            return conservative()
        return GuardSpec(kind="every", period=int(period), start=int(start))
    if is_skippable_guard(guard):
        return GuardSpec(kind="skippable")
    if isinstance(guard, OpaqueCondition):
        key = field(guard, "key")
        negated = field(guard, "negated")
        if not _all_present(key, negated):
            return conservative()
        return GuardSpec(kind="opaque", key=str(key), negated=bool(negated))
    if isinstance(guard, ComplementedIterationPredicate):
        predicate = field(guard, "predicate")
        if predicate is MISSING:
            return conservative()
        return GuardSpec(kind="opaque", key=_guard_key(predicate), negated=True)
    if isinstance(guard, (GuardAnd, GuardOr)):
        if field(guard, "operands") is MISSING:
            return conservative()
        return GuardSpec(kind="opaque", key=_guard_key(guard))
    _missing_fields.add(f"{type(guard).__name__}<unmapped guard>")
    return conservative()


def caller_loc() -> tuple:
    """(file, line) of the first frame outside the TS/DSL infrastructure.

    Shares the resource construction-site frame filter so the base loc of
    the declarations is never attributed to the PyIR call boundary.
    """
    from ..task_scheduling.enums import capture_user_source_loc

    return capture_user_source_loc() or ("<task_scheduling>", 0)


def manager_tasks(manager: Any) -> Optional[tuple]:
    """The manager's tasks, or ``None`` when they cannot be read."""
    tasks = field(manager, "tasks")
    if tasks is MISSING:
        return None
    return tuple(tasks)


def task_info(task: Any) -> Optional[TaskInfo]:
    """Marshal a task, or ``None`` when its required fields are unreadable."""
    warp_idx = field(task, "warp_idx")
    num_warps = field(task, "num_warps")
    schedule = field(task, "schedule")
    if not _all_present(warp_idx, num_warps, schedule):
        return None
    name = field(task, "name")
    num_registers = field(task, "num_registers")
    run_only_on_cta_id = field(task, "run_only_on_cta_id")
    src_resources = field(task, "src_resources")
    dst_resources = field(task, "dst_resources")
    schedule_name = field(schedule, "name")
    if not _all_present(
        name,
        num_registers,
        run_only_on_cta_id,
        src_resources,
        dst_resources,
        schedule_name,
    ):
        return None
    return TaskInfo(
        name=name or f"task{id(task):x}",
        warp_idx=int(warp_idx),
        num_warps=int(num_warps),
        num_registers=num_registers,
        run_only_on_cta_id=run_only_on_cta_id,
        src_resources=tuple(src_resources),
        dst_resources=tuple(dst_resources),
        schedule_name=str(schedule_name),
    )


def step_info(task: Any, step: Any) -> Optional[StepInfo]:
    """Marshal one step relative to its task, or ``None`` when unreadable."""
    schedule = field(task, "schedule")
    resource = field(step, "memory_resource")
    unique_id = field(step, "unique_id")
    stage = field(step, "schedule_stage")
    input_bindings = field(step, "input_bindings")
    returned = field(step, "returned_variables")
    if not _all_present(schedule, resource, unique_id, stage, input_bindings, returned):
        return None
    stage_name = str(getattr(stage, "name", ""))
    verb = _STAGE_TO_VERB.get(stage_name)
    role = _STAGE_TO_WORK_ROLE.get(stage_name)
    if verb is None and role is None:
        _missing_fields.add(f"{type(step).__name__}.schedule_stage<{stage_name}>")
        return None
    label = field(step, "label")
    constexpr_kwargs = field(step, "constexpr_kwargs")
    source_loc = field(step, "source_loc")
    schedule_name = field(schedule, "name")
    if not _all_present(label, constexpr_kwargs, source_loc, schedule_name):
        return None
    return StepInfo(
        step_id=f"{schedule_name}.{unique_id}",
        resource=resource,
        verb=verb,
        role=role,
        callee=str(label) if (verb is None and label) else None,
        reads=() if verb is not None else tuple(input_bindings.values()),
        writes=() if verb is not None else tuple(returned),
        call_attrs={} if verb is not None else dict(constexpr_kwargs or {}),
        source_loc=source_loc,
    )


def drain_info(resource: Any) -> DrainInfo:
    """Marshal a drain construct (the resource is the whole payload)."""
    return DrainInfo(resource=resource)


def domain_loop_info(node: Any) -> LoopInfo:
    """Marshal a domain loop.

    No payload: the formed region contains the real loop op, whose bound
    SSA values the audits fold directly.
    """
    del node
    return LoopInfo()


def work_tile_loop_info(node: Any) -> Optional[LoopInfo]:
    """Marshal a work-tile loop, or ``None`` when its queue is unreadable."""
    work_queue = field(node, "work_queue")
    if work_queue is MISSING:
        return None
    return LoopInfo(work_queue=work_queue)


def cond_info(node: Any) -> Optional[CondInfo]:
    """Marshal a guarded block, or ``None`` when its guard is unreadable."""
    condition = field(node, "condition")
    if condition is MISSING:
        return None
    return CondInfo(guard=condition)


# --------------------------------------------------------------------- #
# The declaration walk (the only traversal of framework schedule trees).
# --------------------------------------------------------------------- #


@dataclass(frozen=True)
class DeclarationPlan:
    """What one manager declares, in deterministic declaration order.

    ``resources`` holds framework resource objects (work queues, pipeline
    groups and plain resources alike -- the emitter classifies them via
    :func:`is_work_queue` / :func:`is_pipeline_group`); ``slots`` holds
    task-local variables; ``queue_skip_ifs`` maps ``id(queue)`` to the
    qualname of the predicate driving it.
    """

    resources: tuple
    slots: tuple
    queue_skip_ifs: dict


def is_work_queue(resource: Any) -> bool:
    """True for a framework work queue."""
    from ..task_scheduling.resources import WorkQueue

    return isinstance(resource, WorkQueue)


def is_pipeline_group(resource: Any) -> bool:
    """True for a framework pipeline group."""
    from ..task_scheduling.pipeline_group import PipelineGroup

    return isinstance(resource, PipelineGroup)


def _iter_tree(nodes: Any) -> Any:
    """Pre-order iterator over a schedule (sub)tree."""
    for node in nodes:
        yield node
        # A Step has no body at all: genuinely optional, not a rename.
        body = field(node, "body", None)
        if body:
            yield from _iter_tree(body)


def collect_declarations(manager: Any) -> Optional[DeclarationPlan]:
    """Walk a manager's tasks once, or ``None`` when it cannot be read."""
    from ..task_scheduling.schedule_builder import (
        ConditionalBlock,
        DomainLoop,
        Step,
        WorkTileLoop,
    )

    tasks = manager_tasks(manager)
    if tasks is None:
        return None

    resources: list = []
    slots: list = []
    seen_r: set[int] = set()
    seen_s: set[int] = set()

    def add_resource(resource: Any) -> None:
        if id(resource) not in seen_r:
            seen_r.add(id(resource))
            resources.append(resource)

    def add_slot(variable: Any) -> None:
        if id(variable) not in seen_s:
            seen_s.add(id(variable))
            slots.append(variable)

    def visit(nodes: Any) -> bool:
        """Collect one node list; False when a required field was missing."""
        readable = True
        for node in nodes:
            if isinstance(node, Step):
                resource = field(node, "memory_resource")
                bindings = field(node, "input_bindings")
                returned = field(node, "returned_variables")
                if not _all_present(resource, bindings, returned):
                    readable = False
                    continue
                add_resource(resource)
                for variable in bindings.values():
                    add_slot(variable)
                for variable in returned:
                    add_slot(variable)
            elif isinstance(node, WorkTileLoop):
                queue = field(node, "work_queue")
                body = field(node, "body")
                if not _all_present(queue, body):
                    readable = False
                    continue
                add_resource(queue)
                readable &= visit(body)
            elif isinstance(node, (ConditionalBlock, DomainLoop)):
                body = field(node, "body")
                if body is MISSING:
                    readable = False
                    continue
                readable &= visit(body)
        return readable

    for task in tasks:
        src = field(task, "src_resources")
        dst = field(task, "dst_resources")
        schedule = field(task, "schedule")
        if not _all_present(src, dst, schedule):
            return None
        for resource in list(src) + list(dst):
            add_resource(resource)
        body = field(schedule, "body")
        if body is MISSING or not visit(body):
            return None
    # Group members may only be touched via the group; declare them too.
    for resource in list(resources):
        if is_pipeline_group(resource):
            members = field(resource, "members")
            if members is MISSING:
                return None
            for member in members:
                add_resource(member)

    # The skip predicate lives on the WorkTileLoop schedule node, not the
    # queue; scan the task trees for the loop that consumes each queue.
    queue_skip_ifs: dict = {}
    for task in tasks:
        # Re-read: every field below was proven present by the walk above.
        body = field(field(task, "schedule"), "body")
        for node in _iter_tree(body):
            if not isinstance(node, WorkTileLoop):
                continue
            skip_if = field(node, "skip_if")
            queue = field(node, "work_queue")
            if not _all_present(skip_if, queue):
                return None
            if skip_if is not None and queue is not None:
                name = getattr(skip_if, "__qualname__", None)
                queue_skip_ifs.setdefault(
                    id(queue), name if isinstance(name, str) else repr(skip_if)
                )

    return DeclarationPlan(
        resources=tuple(resources),
        slots=tuple(slots),
        queue_skip_ifs=queue_skip_ifs,
    )
