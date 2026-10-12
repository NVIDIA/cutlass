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

"""Schedule function DSL for the Task Scheduling (TS) framework.

The ``@schedule`` decorator traces a Python function to build the
schedule.  The grammar is structured around optional HEAD work, one
optional persistent work-tile loop, one optional domain loop, and
optional TAIL work:

- Optionally enter ``with work_tile_loop(wq) as wtl:`` for persistent
  per-tile execution.  The WorkQueue drives the loop; the yielded ``wtl``
  is a :class:`WorkTileLoopProxy` whose only method is ``wtl.skippable()``.
- ``work_tile_loop(wq, skip_if=...)`` enables skipped work-tile
  iterations.  In that mode, entries outside ``with wtl.skippable():``
  run for both normal and skipped tiles; entries inside
  ``with wtl.skippable():`` run only for normal tiles.  The domain loop
  must be inside the skippable context so skipped tiles only execute
  non-skippable HEAD/TAIL bookkeeping such as Programmatic Dependent
  Launch (PDL) and WorkQueue stages.
- When wtl is omitted, ``with domain_loop(start, end, step):`` is
  used directly (HEAD entries before, TAIL entries after).

Variable tokens and lifecycle
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
``TaskLocalVariable`` fields materialize as task-local register state in
generated code, but schedule functions do not read those fields directly.
Consumer work declares the variable it returns with
``@consumer_work(returns=...)``.  Helper variable setup uses
``@consumer_work(work_attrs=WorkAttr.AUXILIARY, returns=...)`` or
``proxy.consumer_aux_work(...)``.

1. **Produced** — returned by a consumer work call (``consumer_work()``, named
   consumer methods like ``compute_coords()``).
2. **Consumed** — passed as an argument to a downstream work call.

The builder validates that every consumed token was produced by the
schedule DSL and is still the latest token for that variable at the call
site. An outdated (stale) token is rejected.

Reference shape::

    @schedule
    def my_schedule(gmem_qkv: GmemQkvResource, tmem_c: TmemCResource, wq: WorkQueue):
        with work_tile_loop(wq) as wtl:
            # HEAD entries (per-tile prefetch).
            smem_q.try_acquire()
            smem_q.acquire()

            with domain_loop(0, k_iters, 1) as d:
                with d.first_iter():
                    coord_q, coord_k = gmem_qkv.compute_coords()
                    smem_q.q_load(coord_q)
                    smem_q.commit()
                smem_kv.try_acquire()
                smem_kv.acquire()
                smem_kv.k_load(coord_k)
                smem_kv.commit()

            # TAIL entries (per-tile drain).
            tmem_c.commit()
            wq.try_wait()
            wq.wait()
            wq.get_and_advance_work_tile()
            wq.release()

Data flow between resources is expressed by passing a work call's
returned token into a downstream work call, which records a targeted
routing edge.  A token binds to a destination input either positionally
(by slot, for a parameter declared positional-or-keyword) or by keyword as
``argument=token``; a keyword-only parameter (declared after ``*``) must use
the keyword form.  Tokens can flow:

- **Consumer -> Producer**::  desc = smem.k_desc(); tmem.qk_mma(desc)
- **Consumer -> Consumer**::  vec = tmem_vec.read_vec(); tmem_o.correct(vec)

Per-variable tokens
-------------------
A consumer method declares which ``TaskLocalVariable`` outputs it produces,
in order, via ``@consumer_work(returns=(a, b, ...))``.  Calling that method
during tracing returns one token per declared variable in that same order, so
downstream calls can route each one independently::

    coord_q, coord_k = gmem_qkv.compute_coords()   # returns=(coord_q, coord_k)
    smem_q.q_load(coord_q)                         # routes coord_q
    smem_kv.k_load(coord_k)                        # routes coord_k

A method that declares a single ``returns=`` yields that one token directly
(not a 1-tuple).

Non-routable tokens
-------------------
Work calls that declare no ``returns=`` — pipeline ops (``acquire``,
``commit``, ...) and untyped work — still return a single token, but one whose
``variable`` is ``None``.  Such a token is not routable: passing it as a
downstream input raises :class:`ScheduleError`.

Direct-to-Task routing
----------------------
A ``@schedule`` function returns a :class:`Schedule`; pass it straight to
``Task`` as ``schedule=``::

    schedule = mma_schedule(smem_ab, tmem_c, work_queue)
    task = Task(
        schedule=schedule,
        ...,  # src_resources, dst_resources, warp_idx, num_warps
    )

Classes
-------
Schedule
    Output of ``@schedule``: the root of the traced schedule *tree*.  ``body``
    is an ordered list of nodes — ``Step`` leaves plus ``ConditionalBlock`` /
    ``DomainLoop`` / ``WorkTileLoop`` containers — and per-variable data flow
    is recorded as ``Route`` edges on the producing steps.

Step
    A leaf node: one pipeline op or work call on a resource.  Carries its
    outgoing ``Route`` edges and the variables (``returns=``) it produces.

Route
    A data-flow edge stored on the producing ``Step``: one produced variable
    feeds one named input on the consuming ``Step``.

ConditionalBlock
    A region whose body runs only when its :class:`~.enums.BlockGuard` holds.

DomainLoop
    A ``range``-style loop over the work tile's iteration domain; any
    bound may be a callable ``Task`` method to make that bound dynamic.

WorkTileLoop
    The persistent (while) loop over work tiles, driven by a ``WorkQueue``;
    an optional ``skip_if`` predicate enables skipped-tile execution.

DataFlowToken
    Opaque handle returned by a work call — one per ``TaskLocalVariable``
    declared in ``@consumer_work(returns=...)``.  Passing it to a downstream
    work call records a per-variable routing edge.

ResourceProxy
    Tracing wrapper around a ``MemoryResource``.  Method calls record
    schedule steps instead of executing real pipeline operations.

DomainLoopProxy / WorkTileLoopProxy
    Handles yielded by ``domain_loop()`` / ``work_tile_loop()``.
    ``DomainLoopProxy`` opens per-iteration ``first_iter()`` / ``last_iter()``
    / ``every()`` blocks; ``WorkTileLoopProxy`` opens ``skippable()`` blocks.

ScheduleBuilder
    Internal state machine that accumulates the schedule tree during
    tracing.  Not used directly — the ``@schedule`` decorator
    manages it.

ScheduleError
    ``ValueError`` raised when a schedule violates the grammar or cannot run.

Functions
---------
schedule(fn)
    Decorator that traces ``fn`` into a :class:`Schedule`.  The wrapped
    function receives one :class:`ResourceProxy` per resource argument and
    returns the built tree when called.

domain_loop(*bounds, unroll=None)
    Opens the domain (for-) loop and records its bounds on the schedule
    tree, so the caller need not repeat them on the ``Task`` constructor.
    Bounds mirror ``range`` (``domain_loop(end)`` / ``(start, end)`` /
    ``(start, end, step)``); any bound may instead be a ``Task`` method
    accessed on the class (``MyTask.get_domain``) to make that dimension
    dynamic.

work_tile_loop(wq, *, skip_if=None)
    Wrapper that delimits the per-tile body of a persistent task.  With a
    ``skip_if=(work_queue, work_tile) -> Boolean`` predicate set, ``skippable()``
    regions are omitted for skipped tiles while the surrounding WorkQueue
    bookkeeping still runs.

consumer_work / producer_work
    Method decorators (from ``resources``) that register a named work function
    on a ``MemoryResource`` subclass under the method's own Python name.  Usable
    bare (``@consumer_work``) or as a factory: ``@consumer_work(returns=...,
    work_attrs=...)`` and ``@producer_work(work_attrs=...)``.
"""

import functools
import inspect
import itertools
import warnings
from collections.abc import Iterator
from contextlib import AbstractContextManager, contextmanager
from contextvars import ContextVar
from dataclasses import dataclass, field
from typing import Callable, Hashable, NoReturn

import cutlass
from typing_extensions import assert_never

from .enums import (
    BlockGuard,
    Every,
    FIRST_ITER,
    IterationPredicate,
    LAST_ITER,
    OpaqueCondition,
    SKIPPABLE,
    ScheduleStage,
)
from .resources import (
    MemoryResource,
    SlotRouting,
    TaskLocalVariable,
    WorkQueue,
    get_task_local_variables,
    _CONSUMER_WORK_FNS_ATTR,
    _PRODUCER_WORK_FNS_ATTR,
    _collect_named_work_fns,
)

# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------


@dataclass(kw_only=True)
class Route:
    """A data-flow edge: one variable produced on a step feeds one input.

    Created when a downstream work call is passed the :class:`DataFlowToken` for
    ``source``.  The edge is stored on the *producing* step and references its
    endpoints by object identity (``destination`` is the consuming :class:`Step`),
    so no positional/slot key is needed.

    Attributes
    ----------
    source : TaskLocalVariable
        The produced variable whose value flows along this edge.
    destination : Step
        The step that consumes the value.
    destination_argument : str
        The named data-flow input on ``destination`` that receives the value.
    """

    source: TaskLocalVariable
    destination: "Step"
    destination_argument: str


@dataclass(kw_only=True, eq=False)
class Step:
    """A leaf node: one pipeline op or work call on a resource.

    ``eq=False`` keeps identity equality/hash: steps are referenced by identity
    (by routes, tokens, the scope map, and ``unique_id`` keying), and two
    structurally identical steps must stay distinct.

    Attributes
    ----------
    memory_resource : MemoryResource
        The resource this step operates on.
    schedule_stage : ScheduleStage
        Which pipeline stage / work kind this step is (e.g. ``ConsumerWait``).
    routes : list[Route]
        Outgoing data-flow edges for variables this step produces.
    constexpr_kwargs : dict
        Compile-time literals passed at the call site for ``cutlass.Constexpr``
        work parameters (e.g. ``is_head=True``, ``subtile=0``); auto-forwarded to
        the work method at runtime.
    returned_variables : list[TaskLocalVariable]
        Variables this step produces (from ``@consumer_work(returns=...)``),
        used to flag produced-but-unrouted outputs.
    label : str | None
        The named work-fn label (e.g. ``"get_item"``), or ``None`` for a
        standard pipeline op.
    unique_id : int
        Stable per-schedule id, used for identity references and printing.
    """

    memory_resource: MemoryResource
    schedule_stage: ScheduleStage
    routes: list[Route] = field(default_factory=list)
    constexpr_kwargs: dict = field(default_factory=dict)
    returned_variables: list[TaskLocalVariable] = field(default_factory=list)
    label: str | None = None
    unique_id: int


@dataclass(kw_only=True, eq=False)
class ConditionalBlock:
    """A region executed only when its guard holds."""

    body: "list[Node]"
    condition: BlockGuard


@dataclass(kw_only=True, eq=False)
class DomainLoop:
    """A ``range``-style loop over the work tile's iteration domain.

    ``start`` / ``end`` / ``step`` mirror Python's ``range``; any bound may be a
    callable ``(self, work_tile_coord)`` Task method to make that bound dynamic.
    ``unroll`` is the loop unroll factor (``None`` = use compiler default).
    """

    start: object | Callable[..., object]
    end: object | Callable[..., object]
    step: object | Callable[..., object]
    unroll: int | None
    body: "list[Node]"


@dataclass(kw_only=True, eq=False)
class WorkTileLoop:
    """The persistent (while) loop over work tiles, driven by ``work_queue``.

    ``skip_if`` is an optional predicate ``(work_queue, work_tile) -> Boolean``;
    when set, ``skippable()`` regions inside ``body`` are omitted for skipped
    tiles while the surrounding WorkQueue bookkeeping still runs.
    """

    body: "list[Node]"
    work_queue: WorkQueue
    skip_if: Callable[..., cutlass.Boolean] | None = None


Node = Step | ConditionalBlock | DomainLoop | WorkTileLoop


@dataclass(kw_only=True)
class Schedule:
    """The root of a traced schedule: a named tree plus its resources.

    ``body`` is the ordered list of top-level :data:`Node`s; ``resources`` lists
    every resource the schedule touches.  ``str(schedule)`` pretty-prints the
    tree, including data-flow routes.
    """

    name: str
    body: list[Node]
    resources: list[MemoryResource]

    def __str__(self) -> str:
        return _format_schedule(self)


@dataclass
class ScheduleResult:
    """Legacy flat schedule bundle consumed by the legacy :class:`~.task.Task`.

    Attributes
    ----------
    schedule_list : list[tuple]
        Flat list of schedule tuples in the legacy schedule-list format.
    slot_routing : SlotRouting or None
        Slot-to-slot variable-flow routing table.  ``None`` when no data-flow
        tokens were used.
    constexpr_work_kwargs : dict or None
        Maps a work-call slot ``(id(resource), stage, stage_type, call_idx)`` to
        the compile-time ``cutlass.Constexpr`` kwargs captured at its schedule
        call site (e.g. ``{"is_head": True}``), auto-forwarded to the work method
        at runtime.  ``None`` when no constexpr work arguments were used.
    resources : list[MemoryResource]
        Ordered list of resources the schedule function received, preserving
        parameter order.
    loop_start, loop_end, loop_step : int or DSL value or None
        Bounds captured by ``domain_loop(start, end, step)``.  ``None`` when no
        ``domain_loop`` was used.
    domain_getter : callable or None
        A ``Task`` subclass method, accessed on the class, supplied as the
        ``end`` bound, e.g. ``domain_loop(MyTask.get_domain)``.
    dynamic_domain : bool
        Derived property.  ``True`` when ``domain_getter`` is present.
    has_work_tile_loop : bool
        ``True`` when the schedule used ``with work_tile_loop(wq):``.
    skip_if : callable or None
        Optional skip predicate captured from ``work_tile_loop(skip_if=...)``.
    post_work_loop_tail_slots, pre_work_loop_head_slots : set[tuple[int, ScheduleStage, int]]
        Tail/head schedule slots recorded after/before the ``work_tile_loop(wq)``
        block, run once after/before the persistent loop.
    skippable_head_slots, skippable_tail_slots : set[tuple[int, ScheduleStage, int]]
        Head/tail slots inside ``with wtl.skippable():`` that are dropped for a
        skipped work-tile iteration.
    """

    schedule_list: list[tuple]
    slot_routing: SlotRouting | None = None
    constexpr_work_kwargs: dict | None = None
    resources: list[MemoryResource] = field(default_factory=list)
    loop_start: object | None = None
    loop_end: object | None = None
    loop_step: object | None = None
    domain_getter: Callable[..., object] | None = None
    unroll: int | None = 1
    skip_if: Callable[..., object] | None = None
    has_work_tile_loop: bool = False
    post_work_loop_tail_slots: set[tuple[int, ScheduleStage, int]] = field(
        default_factory=set
    )
    pre_work_loop_head_slots: set[tuple[int, ScheduleStage, int]] = field(
        default_factory=set
    )
    skippable_head_slots: set[tuple[int, ScheduleStage, int]] = field(
        default_factory=set
    )
    skippable_tail_slots: set[tuple[int, ScheduleStage, int]] = field(
        default_factory=set
    )

    @property
    def dynamic_domain(self) -> bool:
        """Whether this schedule resolves its domain via ``domain_getter``."""
        return self.domain_getter is not None

    def task_kwargs(self) -> dict:
        """Return kwargs suitable for ``Task(**result.task_kwargs())``.

        The legacy ``Task`` reads the captured-schedule fields off this object,
        so the caller only adds ``src_resources`` / ``dst_resources`` /
        ``warp_idx`` / ``num_warps``::

            schedule = my_schedule(smem, tmem)         # a Schedule tree
            result = lower_to_legacy(schedule)         # the legacy bundle
            Task(src_resources=[smem], dst_resources=[tmem],
                 warp_idx=0, num_warps=1, **result.task_kwargs())
        """
        return {"schedule": self}

    def __repr__(self) -> str:
        return (
            f"ScheduleResult(entries={len(self.schedule_list)}, "
            f"data_flow={self.slot_routing is not None}, "
            f"work_tile_loop={self.has_work_tile_loop}, "
            f"dynamic_domain={self.dynamic_domain}, unroll={self.unroll})"
        )


def _child_nodes(node: Node) -> list[Node]:
    """Direct children of ``node`` (empty for a leaf :class:`Step`)."""
    match node:
        case Step():
            return []
        case (
            ConditionalBlock(body=body)
            | DomainLoop(body=body)
            | WorkTileLoop(body=body)
        ):
            return body
        case _:
            assert_never(node)


def _iter_nodes(nodes: list[Node]) -> Iterator[Node]:
    """Pre-order walk over ``nodes`` and every nested body."""
    for node in nodes:
        yield node
        yield from _iter_nodes(_child_nodes(node))


def _iter_steps(schedule: Schedule) -> Iterator[Step]:
    """Yield every :class:`Step` in ``schedule`` in execution order."""
    return (node for node in _iter_nodes(schedule.body) if isinstance(node, Step))


def _format_schedule(schedule: Schedule, *, show_routes: bool = True) -> str:
    res_list = ", ".join(f"{r.name}: {type(r).__name__}" for r in schedule.resources)
    lines = [f"Schedule({schedule.name!r}, resources=[{res_list}])"]

    # destination step uid -> list of (destination arg, source variable, producer step uid)
    incoming: dict[int, list[tuple[str, str | None, int]]] = {}
    if show_routes:
        for step in _iter_steps(schedule):
            for route in step.routes:
                incoming.setdefault(route.destination.unique_id, []).append(
                    (route.destination_argument, route.source.slot_name, step.unique_id)
                )

    def fmt_bound(value: object) -> str:
        # A callable bound is a runtime domain getter; show it as ``f()``.
        if callable(value):
            return f"{getattr(value, '__name__', repr(value))}()"
        # Plain Python bounds print as their literal.
        if isinstance(value, (bool, int, float)):
            return str(value)
        # Rendering a dynamic bound.
        inner = getattr(value, "value", None)
        if isinstance(inner, (bool, int, float)):
            return str(inner)
        if inner is not None:
            return f"<dynamic {type(value).__name__}>"
        return str(value)

    def fmt_out(route: Route) -> str:
        target = route.destination.unique_id
        return f"{route.source.slot_name} -> [#{target}].{route.destination_argument}"

    def fmt_in(argument: str, source_var: str | None, producer_index: int) -> str:
        return f"{argument} <- [#{producer_index}].{source_var}"

    def fmt_header(node: Node) -> str:
        match node:
            case Step(memory_resource=resource, schedule_stage=stage, label=label):
                lbl = f", label={label!r}" if label else ""
                return f"[#{node.unique_id}] Step({resource.name}, {stage.name}{lbl})"
            case ConditionalBlock(condition=condition):
                return f"ConditionalBlock(condition={_format_block_guard(condition)})"
            case DomainLoop(start=start, end=end, step=step, unroll=unroll):
                bounds = (
                    f"start={fmt_bound(start)}, end={fmt_bound(end)}, "
                    f"step={fmt_bound(step)}"
                )
                return f"DomainLoop({bounds}, unroll={unroll})"
            case WorkTileLoop(work_queue=work_queue, skip_if=skip_if):
                parts = [work_queue.name]
                if skip_if is not None:
                    parts.append(
                        f"skip_if={getattr(skip_if, '__name__', repr(skip_if))}"
                    )
                return f"WorkTileLoop({', '.join(parts)})"
            case _:
                assert_never(node)

    def fmt_node(node: Node, indent: int) -> list[str]:
        pad = " " * indent
        out = [f"{pad}{fmt_header(node)}"]
        if show_routes and isinstance(node, Step):
            out.extend(
                f"{pad}      {fmt_in(argument, source_var, producer_index)}"
                for argument, source_var, producer_index in incoming.get(
                    node.unique_id, []
                )
            )
            out.extend(f"{pad}      {fmt_out(route)}" for route in node.routes)
        for child in _child_nodes(node):
            out.extend(fmt_node(child, indent + 2))
        return out

    for node in schedule.body:
        lines.extend(fmt_node(node, indent=2))

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Schedule builder (tracing front-end -> Schedule IR)
# ---------------------------------------------------------------------------


class ScheduleError(ValueError):
    """Raised when a schedule violates the schedule grammar or cannot be run."""


_active_builder: "ContextVar[ScheduleBuilder | None]" = ContextVar(
    "_active_builder", default=None
)

# Snake-case proxy methods that map directly to a fixed pipeline stage.
_STANDARD_STAGE_METHODS: dict[str, ScheduleStage] = {
    "try_acquire": ScheduleStage.ProducerTryAcquire,
    "acquire": ScheduleStage.ProducerAcquire,
    "commit": ScheduleStage.ProducerCommit,
    "producer_work": ScheduleStage.ProducerWork,
    "producer_aux_work": ScheduleStage.ProducerAuxWork,
    "try_wait": ScheduleStage.ConsumerTryWait,
    "wait": ScheduleStage.ConsumerWait,
    "release": ScheduleStage.ConsumerRelease,
    "consumer_work": ScheduleStage.ConsumerWork,
    "consumer_aux_work": ScheduleStage.ConsumerAuxWork,
}
_CONSUMER_WORK_HOOK_METHOD: str = "consumer_work"
_PRODUCER_WORK_HOOK_METHOD: str = "producer_work"
_AUX_STAGES: frozenset[ScheduleStage] = frozenset[ScheduleStage](
    {ScheduleStage.ConsumerAuxWork, ScheduleStage.ProducerAuxWork}
)


@dataclass
class DataFlowToken:
    """Handle returned by a work call; passing it downstream routes its variable.

    A consumer work call that declares ``returns=`` yields one token per
    produced :class:`TaskLocalVariable`; passing such a token into a downstream
    work call materializes a :class:`Route` on the producing
    step.  A token carries exactly one variable and is routed to the single
    destination argument resolved from its slot position or keyword.

    Calls that declare no outputs (pipeline ops, untyped work) return a token
    with ``variable is None``; such a token is not routable and passing it as
    an input is rejected.

    The builder tracks the latest token minted per variable; re-producing the
    variable supersedes earlier handles, so an older token becomes stale and
    cannot be routed (caught by the builder's freshness check, by identity).
    """

    producer_step: Step
    variable: TaskLocalVariable | None = None

    def __iter__(self) -> NoReturn:
        raise ScheduleError(
            "a single work-call output cannot be unpacked; it carries one "
            "variable. Only multi-output @consumer_work(returns=(a, b)) calls "
            "yield an unpackable tuple."
        )

    def __getitem__(self, index: object) -> NoReturn:
        raise ScheduleError(
            "a single work-call output cannot be indexed; it carries one variable."
        )


_opaque_capture_counter = itertools.count()


def _format_iteration_predicate(condition: IterationPredicate) -> str:
    if isinstance(condition, Every):
        return f"Every(period={condition.period}, start={condition.start})"
    if condition is FIRST_ITER:
        return "FirstIter"
    if condition is LAST_ITER:
        return "LastIter"
    return repr(condition)


def _format_block_guard(condition: BlockGuard) -> str:
    if condition is SKIPPABLE:
        return "Skippable"
    if isinstance(condition, OpaqueCondition):
        polarity = "when_false" if condition.negated else "when_true"
        return f"{polarity}(key={condition.key!r})"
    if isinstance(condition, IterationPredicate):
        return _format_iteration_predicate(condition)
    raise TypeError(f"unsupported block guard type: {type(condition).__name__}")


def _resolve_when_guard(
    builder: "ScheduleBuilder",
    cond: object,
    *,
    key: Hashable | None,
    negated: bool,
    api: str,
) -> IterationPredicate | OpaqueCondition:
    if isinstance(cond, IterationPredicate):
        if key is not None:
            warnings.warn(
                f"{api}(): key= is ignored for iteration predicates.",
                stacklevel=3,
            )
        if negated:
            raise ScheduleError(
                f"{api}() cannot negate an iteration predicate; use a different "
                "predicate or an opaque runtime condition."
            )
        if not builder._is_inside_domain_loop():
            raise ScheduleError(
                f"{api}() with an iteration predicate is only valid inside "
                "domain_loop()."
            )
        if builder._in_per_iteration_condition():
            raise ScheduleError(
                "per-iteration condition blocks cannot be nested; express "
                "independent cadences as sibling blocks."
            )
        return cond
    if isinstance(cond, DataFlowToken):
        if cond.variable is None:
            raise ScheduleError(
                f"{api}() condition must be a work-call output declared with "
                "returns=TaskLocalVariable."
            )
        if builder.is_stale(cond):
            raise ScheduleError(
                "condition token is stale; use the latest handle returned by "
                "the work call."
            )
        label = cond.producer_step.label or cond.producer_step.schedule_stage.value
        result_name = cond.variable.slot_name
        assert result_name is not None
        resolved_key = (
            key
            if key is not None
            else (
                id(cond.producer_step.memory_resource),
                label,
                result_name,
            )
        )
        builder.record_condition_use(cond)
        return OpaqueCondition(
            key=resolved_key,
            negated=negated,
            resource=cond.producer_step.memory_resource,
            method_label=label,
            result_name=result_name,
        )
    resolved_key = (
        key if key is not None else ("__opaque__", next(_opaque_capture_counter))
    )
    return OpaqueCondition(key=resolved_key, negated=negated)


def _validate_opaque_guard_placement(
    builder: "ScheduleBuilder", _guard: OpaqueCondition, api: str
) -> None:
    if builder._in_per_iteration_condition():
        raise ScheduleError(
            f"{api}() with an opaque condition cannot be nested inside a "
            "per-iteration predicate block or another opaque condition block."
        )


@contextmanager
def when_true(cond: object, *, key: Hashable | None = None) -> Iterator[None]:
    """Open a block that runs when ``cond`` is true.

    Iteration predicates are only valid inside ``domain_loop()``.  Opaque
    runtime conditions are work-call outputs backed by ``TaskLocalVariable``
    slots; they may be used as sibling blocks or inside ``skippable()``, but
    condition blocks are intentionally not nestable.
    """
    builder = _require_active_builder("when_true()")
    guard = _resolve_when_guard(builder, cond, key=key, negated=False, api="when_true")
    if isinstance(guard, OpaqueCondition):
        _validate_opaque_guard_placement(builder, guard, "when_true")
    with _conditional_block(builder, guard):
        yield


@contextmanager
def when_false(cond: object, *, key: Hashable | None = None) -> Iterator[None]:
    """Open a block that runs when ``cond`` is false.

    ``when_false`` accepts opaque runtime conditions only; iteration predicates
    cannot be negated because their complement may not be contiguous in the
    lowered loop schedule.
    """
    builder = _require_active_builder("when_false()")
    guard = _resolve_when_guard(builder, cond, key=key, negated=True, api="when_false")
    if isinstance(guard, OpaqueCondition):
        _validate_opaque_guard_placement(builder, guard, "when_false")
    with _conditional_block(builder, guard):
        yield


@dataclass(frozen=True)
class _WorkInfo:
    """Per-proxy-method metadata needed to record a step and its routes.

    Resolved once per proxy from the resource's ``@consumer_work`` /
    ``@producer_work`` decorator metadata.
    """

    stage: ScheduleStage
    label: str | None
    # Names of data-flow inputs declared positional-or-keyword (before any
    # ``*``); bound to DataFlowTokens by slot position at the call site or by
    # keyword.
    routed_positional_names: tuple[str, ...]
    # Names of data-flow inputs declared keyword-only (after ``*``); bound to
    # DataFlowTokens as ``argument=token``.
    routed_keyword_names: tuple[str, ...]
    # TaskLocalVariables this method produces (``returns=``).
    returned_variables: tuple[TaskLocalVariable, ...]
    # Names of keyword-only params annotated ``cutlass.Constexpr[...]``: literals
    # forwarded verbatim to the work method, never routed.
    constexpr_names: tuple[str, ...] = ()
    # Subset of ``constexpr_names`` declared without a default; the call site
    # must supply each (omitting one is a schedule-build error, not a late
    # trace-time ``TypeError``).
    required_constexpr_names: tuple[str, ...] = ()

    @property
    def routed_names(self) -> tuple[str, ...]:
        """All routed data-flow input names, in declaration order."""
        return self.routed_positional_names + self.routed_keyword_names


# A frame on the builder's scope stack: anything that exposes ``body``.
_Scope = Schedule | ConditionalBlock | DomainLoop | WorkTileLoop


def _is_allowed_outside_work_tile_loop(node: Node) -> bool:
    """True for a step allowed outside the work-tile loop."""
    return isinstance(node, Step) and (
        node.schedule_stage in _AUX_STAGES or node.memory_resource.is_barrier
    )


class ScheduleBuilder:
    """Accumulates a :class:`Schedule` tree while a ``@schedule`` function runs.

    Recording uses a scope stack.  Every container (the root ``Schedule`` plus
    any open ``ConditionalBlock`` / ``DomainLoop`` / ``WorkTileLoop``) exposes
    ``body``; context managers push on enter and pop on exit.
    """

    def __init__(self, name: str, resources: list[MemoryResource]) -> None:
        self._schedule = Schedule(name=name, body=[], resources=resources)
        self._stack: list[_Scope] = [self._schedule]
        self._has_work_tile_loop = False
        self._after_work_tile_loop = False
        # The latest token minted per variable (by variable identity).
        self._latest_token: dict[TaskLocalVariable, DataFlowToken] = {}
        # Produced values used as opaque conditions are consumed by control flow,
        # not by a data-flow route.
        self._condition_uses: set[tuple[int, int]] = set()
        # Monotonic per-schedule counter stamping each step's stable unique_id.
        self._next_unique_id = 0

    # -- token lifecycle --

    def record_latest(self, token: DataFlowToken) -> None:
        """Mark ``token`` as the latest handle for the variable it carries."""
        if token.variable is not None:
            self._latest_token[token.variable] = token

    def is_stale(self, token: DataFlowToken) -> bool:
        """True when ``token`` is no longer the latest handle for its variable."""
        if token.variable is None:
            return True
        return self._latest_token.get(token.variable) is not token

    def record_condition_use(self, token: DataFlowToken) -> None:
        """Mark ``token`` as consumed by a ``when_true`` / ``when_false`` guard."""
        assert token.variable is not None
        self._condition_uses.add((id(token.producer_step), id(token.variable)))

    def _warn_unconsumed(self) -> None:
        """Warn about consumer outputs that are produced but never routed.

        Derived from the tree: a produced variable is consumed iff it appears as
        a :class:`Route` source on its producing step or as a guard for an opaque
        conditional block.  WorkQueue tile state (e.g. ``work_tile``) is
        intentionally exempt -- it is consumed by the persistent-loop machinery
        via ``stage_info`` rather than by a route.
        """
        for step in _iter_steps(self._schedule):
            if isinstance(step.memory_resource, WorkQueue):
                continue
            routed = {route.source for route in step.routes}
            label = step.label or step.schedule_stage.name
            for variable in step.returned_variables:
                if variable in routed:
                    continue
                if (id(step), id(variable)) in self._condition_uses:
                    continue
                warnings.warn(
                    f"{step.memory_resource.name}.{label}() produces "
                    f"'{variable.slot_name}' but it is never routed to a "
                    "downstream work call.",
                    stacklevel=3,
                )

    # -- scope management --

    def open_scope(
        self, container: ConditionalBlock | DomainLoop | WorkTileLoop
    ) -> None:
        """Validate ``container``, link it into the current scope, make it current."""
        if self._after_work_tile_loop and not isinstance(container, WorkTileLoop):
            raise ScheduleError("no blocks may follow work_tile_loop()")
        self._validate_open(container)
        if isinstance(container, WorkTileLoop):
            self._has_work_tile_loop = True
        self._stack[-1].body.append(container)
        self._stack.append(container)

    def close_scope(
        self, container: ConditionalBlock | DomainLoop | WorkTileLoop
    ) -> None:
        """Pop ``container``; it must be the current (innermost) scope."""
        if self._stack[-1] is not container:
            raise ScheduleError("schedule blocks closed out of order.")
        self._stack.pop()
        if isinstance(container, WorkTileLoop):
            self._after_work_tile_loop = True

    def record_step(self, resource: MemoryResource, info: "_WorkInfo") -> Step:
        """Append a :class:`Step` (described by ``info``) to the current scope."""
        if isinstance(resource, WorkQueue) and self._in_skippable():
            raise ScheduleError(
                "WorkQueue operations cannot appear inside a skippable() block; "
                "skipped work tiles must still run WorkQueue "
                "wait/advance/release bookkeeping."
            )
        step = Step(
            memory_resource=resource,
            schedule_stage=info.stage,
            label=info.label,
            unique_id=self._next_unique_id,
        )
        if self._after_work_tile_loop and not _is_allowed_outside_work_tile_loop(step):
            raise ScheduleError(
                "detected a schedule entry that is not allowed outside "
                "work_tile_loop()."
            )
        self._next_unique_id += 1
        self._stack[-1].body.append(step)
        return step

    def finalize(self) -> Schedule:
        """Return the completed schedule once every scope has been closed."""
        if len(self._stack) != 1:
            raise ScheduleError("schedule ended with an unclosed block.")
        self._warn_unconsumed()
        return self._schedule

    # -- ancestry queries used by the grammar checks --

    def _in_skippable(self) -> bool:
        return any(
            isinstance(f, ConditionalBlock) and f.condition is SKIPPABLE
            for f in self._stack
        )

    def _enclosing_work_tile_loop(self) -> WorkTileLoop | None:
        for frame in reversed(self._stack):
            if isinstance(frame, WorkTileLoop):
                return frame
        return None

    def _is_inside_domain_loop(self) -> bool:
        return any(isinstance(f, DomainLoop) for f in self._stack)

    def _in_per_iteration_condition(self) -> bool:
        """Return whether an iteration or opaque condition guard is open."""
        return any(
            isinstance(frame, ConditionalBlock)
            and isinstance(frame.condition, (IterationPredicate, OpaqueCondition))
            for frame in self._stack
        )

    def is_scope_open(self, node: _Scope) -> bool:
        """True while ``node`` is still an open scope on the stack (by identity)."""
        return any(scope is node for scope in self._stack)

    def _validate_open(
        self, container: ConditionalBlock | DomainLoop | WorkTileLoop
    ) -> None:
        match container:
            case WorkTileLoop():
                if self._stack[-1] is not self._schedule:
                    raise ScheduleError(
                        "work_tile_loop() must be a top-level block of the "
                        "schedule; it cannot be nested inside a domain_loop(), a "
                        "conditional block, or another work_tile_loop()."
                    )
                if self._has_work_tile_loop:
                    raise ScheduleError(
                        "at most one work_tile_loop() is allowed per schedule."
                    )
                if not all(
                    _is_allowed_outside_work_tile_loop(n) for n in self._stack[-1].body
                ):
                    raise ScheduleError(
                        "detected a schedule entry that is not allowed outside "
                        "work_tile_loop()."
                    )
            case DomainLoop():
                if self._is_inside_domain_loop():
                    raise ScheduleError(
                        "domain_loop() cannot be nested inside another domain_loop()."
                    )
                # With a skipping work-tile loop, the copy work must be skippable.
                wtl = self._enclosing_work_tile_loop()
                if (
                    wtl is not None
                    and wtl.skip_if is not None
                    and not self._in_skippable()
                ):
                    raise ScheduleError(
                        "with work_tile_loop(skip_if=...), domain_loop() must be "
                        "inside wtl.skippable()."
                    )
            case ConditionalBlock(condition=guard) if guard is SKIPPABLE:
                if self._in_skippable():
                    raise ScheduleError("skippable() blocks cannot be nested.")
                wtl = self._enclosing_work_tile_loop()
                if wtl is None or wtl.skip_if is None:
                    raise ScheduleError(
                        "skippable() requires an enclosing work_tile_loop(skip_if=...)."
                    )
            case ConditionalBlock(condition=IterationPredicate() as condition):
                if not self._is_inside_domain_loop():
                    condition_name = _format_block_guard(condition)
                    raise ScheduleError(
                        f"{condition_name} condition is only valid inside a "
                        "domain_loop()."
                    )
                if self._in_per_iteration_condition():
                    raise ScheduleError(
                        "per-iteration condition blocks cannot be nested; "
                        "express independent cadences as sibling blocks."
                    )
            case ConditionalBlock(condition=OpaqueCondition() as opaque):
                if self._in_per_iteration_condition():
                    raise ScheduleError(
                        "opaque when_true/when_false blocks cannot be nested "
                        "inside a per-iteration predicate block or another "
                        "opaque condition block."
                    )
                del opaque


class ResourceProxy:
    """Tracing proxy for a ``MemoryResource``.

    Method calls on the proxy do not execute real pipeline operations;
    instead they record schedule entries in the ``ScheduleBuilder``.

    Standard pipeline-stage methods are exposed as snake_case::

        proxy.try_acquire()       # ProducerTryAcquire
        proxy.acquire()           # ProducerAcquire
        proxy.consumer_work()     # ConsumerWork (returns DataFlowToken / tuple[DataFlowToken])
        proxy.producer_work()     # ProducerWork (no data flow token)
        proxy.producer_work(tok)  # ProducerWork (binds data flow)
        proxy.commit()            # ProducerCommit
        proxy.try_wait()          # ConsumerTryWait
        proxy.wait()              # ConsumerWait
        proxy.release()           # ConsumerRelease
        proxy.consumer_aux_work() # ConsumerAuxWork
        proxy.producer_aux_work() # ProducerAuxWork

    Named work methods registered via ``@consumer_work_fn`` /
    ``@producer_work_fn`` on the resource class are also bound here::

        proxy.k_desc()             # ConsumerWork with label="k_desc"
        proxy.k_load(token)        # ProducerWork with label="k_load"

    WorkQueue does not expose the unnamed work shorthands. Use its named
    methods ``get_and_advance_work_tile()`` and ``fetch_work_tile()``
    so the schedule records the explicit scheduler operation.
    """

    def __init__(self, resource: MemoryResource, builder: ScheduleBuilder) -> None:
        self._resource = resource
        self._builder = builder
        self._work_info: dict[str, _WorkInfo] = {}
        # TaskLocalVariable metadata keyed by slot name, used to resolve the
        # variables a consumer call produces into concrete route sources.
        self._vars_by_name: dict[str, TaskLocalVariable] = {
            variable.slot_name: variable
            for variable in get_task_local_variables(resource)
            if variable.slot_name is not None
        }
        self._discover_named_work()

    def _discover_named_work(self) -> None:
        res_cls = type(self._resource)
        for proxy_name, method_name in _collect_named_work_fns(
            res_cls, _CONSUMER_WORK_FNS_ATTR
        ).items():
            if (
                proxy_name in _STANDARD_STAGE_METHODS
                and proxy_name != _CONSUMER_WORK_HOOK_METHOD
            ):
                raise ScheduleError(
                    f"@consumer_work {proxy_name!r} on {res_cls.__name__} collides "
                    f"with the standard pipeline method {proxy_name!r}; standard "
                    "pipeline-op names are reserved and cannot be used as a named "
                    "work method. Rename the method."
                )
            method = getattr(res_cls, method_name, None)
            returns = getattr(method, "_consumer_return_var_names", None)
            names = returns() if returns is not None else ()
            self._work_info[proxy_name] = _WorkInfo(
                stage=getattr(
                    method, "_consumer_work_stage", ScheduleStage.ConsumerWork
                ),
                label=proxy_name,
                routed_positional_names=getattr(
                    method, "_consumer_routed_positional_names", ()
                ),
                routed_keyword_names=getattr(
                    method, "_consumer_routed_keyword_names", ()
                ),
                returned_variables=tuple(
                    self._resolve_return_var(proxy_name, name) for name in names
                ),
                constexpr_names=getattr(method, "_consumer_constexpr_names", ()),
                required_constexpr_names=getattr(
                    method, "_consumer_required_constexpr_names", ()
                ),
            )
        for proxy_name, method_name in _collect_named_work_fns(
            res_cls, _PRODUCER_WORK_FNS_ATTR
        ).items():
            if (
                proxy_name in _STANDARD_STAGE_METHODS
                and proxy_name != _PRODUCER_WORK_HOOK_METHOD
            ):
                raise ScheduleError(
                    f"@producer_work {proxy_name!r} on {res_cls.__name__} collides "
                    f"with the standard pipeline method {proxy_name!r}; standard "
                    "pipeline-op names are reserved and cannot be used as a named "
                    "work method. Rename the method."
                )
            if proxy_name in self._work_info:
                # Same label already registered as @consumer_work.
                raise ScheduleError(
                    f"@producer_work {proxy_name!r} on {res_cls.__name__} collides "
                    "with a @consumer_work of the same name; a work-method label "
                    "must be unique. Rename one of them."
                )
            method = getattr(res_cls, method_name, None)
            self._work_info[proxy_name] = _WorkInfo(
                stage=getattr(
                    method, "_producer_work_stage", ScheduleStage.ProducerWork
                ),
                label=proxy_name,
                routed_positional_names=getattr(
                    method, "_producer_routed_positional_names", ()
                ),
                routed_keyword_names=getattr(
                    method, "_producer_routed_keyword_names", ()
                ),
                returned_variables=(),
                constexpr_names=getattr(method, "_producer_constexpr_names", ()),
                required_constexpr_names=getattr(
                    method, "_producer_required_constexpr_names", ()
                ),
            )

    def _resolve_return_var(self, label: str, name: str) -> TaskLocalVariable:
        """Resolve a declared ``returns=`` slot name to its TaskLocalVariable."""
        variable = self._vars_by_name.get(name)
        if variable is None:
            available = ", ".join(sorted(self._vars_by_name)) or "(none)"
            raise ScheduleError(
                f"{self._resource.name}.{label}() declares returns={name!r}, but "
                f"no such task-local variable exists; available: {available}."
            )
        return variable

    def __getattr__(self, name: str) -> Callable[..., object]:
        if name.startswith("_"):
            raise AttributeError(name)
        info = self._work_info.get(name)
        if info is None and name in _STANDARD_STAGE_METHODS:
            if isinstance(self._resource, WorkQueue) and name in (
                "consumer_work",
                "producer_work",
            ):
                raise ScheduleError(
                    f"WorkQueue does not support {name}(); use its named methods "
                    "such as get_and_advance_work_tile() or fetch_work_tile()."
                )
            info = _WorkInfo(
                stage=_STANDARD_STAGE_METHODS[name],
                label=None,
                routed_positional_names=(),
                routed_keyword_names=(),
                returned_variables=(),
            )
        if info is not None:
            return self._recorder(info)
        if name in self._vars_by_name:
            raise ScheduleError(
                f"{type(self._resource).__name__}.{name!r} is a task-local "
                "variable, not a work method; produce it from a "
                "@consumer_work(returns=...) call and route the returned token."
            )
        available = ", ".join(sorted({*self._work_info, *_STANDARD_STAGE_METHODS}))
        raise AttributeError(
            f"{type(self._resource).__name__} schedule proxy has no work method "
            f"{name!r}. Available work methods: {available}."
        )

    def _recorder(self, info: _WorkInfo) -> Callable[..., object]:
        def record(*args: object, **kwargs: object) -> object:
            step = self._builder.record_step(self._resource, info)
            self._bind_routes(step, info, args, kwargs)
            return self._mint_outputs(step, info)

        return record

    def _site(self, info: _WorkInfo) -> str:
        """Human-readable call-site label for error messages (``res.method()``)."""
        return f"{self._resource.name}.{info.label or info.stage.name}()"

    def _bind_routes(
        self,
        step: Step,
        info: _WorkInfo,
        args: tuple[object, ...],
        kwargs: dict[str, object],
    ) -> None:
        """Validate the call's arguments, recording a :class:`Route` per routed
        input and capturing each constexpr literal on ``step``.

        The call's arguments split into two disjoint kinds, matching how ``info``
        classifies the work method's parameters:

        - **Routed (data-flow) inputs** (``info.routed_names``) bind by token
          identity.  A token may be passed positionally for a parameter declared
          *positional-or-keyword* (bound by slot order against
          ``info.routed_positional_names``) or by keyword as ``argument=token``;
          a keyword-only input must use the keyword form.  Each one records a
          :class:`Route` from its producing step to this one.
        - **Constexpr params** (``info.constexpr_names``) are compile-time
          literals forwarded verbatim to the work body, never routed.  Each value
          passed at the call site is captured on ``step.constexpr_kwargs``;
          omitting one is fine when it has a default and an error when it is
          required (``info.required_constexpr_names``).

        Raises :class:`ScheduleError` if too many positional tokens are given, an
        argument is bound both positionally and by keyword, a routed input is
        left unrouted, a routed value is ``None`` / not a routable output token /
        stale, a constexpr param is given a token instead of a literal, a
        required constexpr param is omitted, or an argument names no declared
        parameter.
        """
        site = self._site(info)

        # 1. Merge positional + keyword args into one map; reject double-binds.
        #    Each name is popped as handled, so leftovers are unknown args.
        positional = info.routed_positional_names
        if len(args) > len(positional):
            allowed = ", ".join(positional) or "none"
            raise ScheduleError(
                f"{site} accepts at most {len(positional)} positional data-flow "
                f"input(s) ({allowed}); got {len(args)}. Pass keyword-only "
                "inputs as argument=token."
            )
        bound: dict[str, object] = dict(zip(positional, args))
        for argument, value in kwargs.items():
            if argument in bound:
                raise ScheduleError(
                    f"{site} got multiple values for input {argument!r} (passed "
                    "both positionally and by keyword)."
                )
            bound[argument] = value

        # 2. Route each data-flow input (declaration order); missing is an error.
        for argument in info.routed_names:
            if argument not in bound:
                raise ScheduleError(
                    f"{site} is missing routed input {argument!r}; pass it as a "
                    "positional token or argument=token."
                )
            token = self._validate_routed_token(info, argument, bound.pop(argument))
            # _validate_routed_token guarantees a non-None variable.
            assert token.variable is not None
            token.producer_step.routes.append(
                Route(
                    source=token.variable,
                    destination=step,
                    destination_argument=argument,
                )
            )

        # 3. Capture each constexpr literal; a missing required one is an error.
        for argument in info.constexpr_names:
            if argument in bound:
                value = bound.pop(argument)
                if isinstance(value, DataFlowToken):
                    raise ScheduleError(
                        f"{site} constexpr argument {argument!r} must be a "
                        "compile-time literal, not a work-call output token."
                    )
                step.constexpr_kwargs[argument] = value
            elif argument in info.required_constexpr_names:
                raise ScheduleError(
                    f"{site} is missing required constexpr argument {argument!r}."
                )

        # 4. Anything still bound names no declared parameter.
        if bound:
            declared = (
                ", ".join((*info.routed_names, *info.constexpr_names)) or "(none)"
            )
            raise ScheduleError(
                f"{site} got unknown argument(s) {', '.join(sorted(bound))}; "
                f"declared parameters: {declared}."
            )

    def _validate_routed_token(
        self, info: _WorkInfo, argument: str, value: object
    ) -> DataFlowToken:
        """Return ``value`` as a fresh, routable output token, or raise.

        Applies to both positionally and keyword-bound inputs: the value must be
        a non-``None`` :class:`DataFlowToken` that carries a variable and is still
        the latest handle for it.
        """
        site = self._site(info)
        if value is None:
            raise ScheduleError(
                f"{site} input {argument!r} cannot be None; pass the token "
                "returned by the producing work call."
            )
        if not isinstance(value, DataFlowToken):
            raise ScheduleError(
                f"{site} input {argument!r} must be a work-call output token, "
                f"got {type(value).__name__}."
            )
        if value.variable is None:
            raise ScheduleError(
                f"{site} input {argument!r} was given a token that carries no "
                "variable; only outputs declared via "
                "@consumer_work(returns=...) can be routed."
            )
        if self._builder.is_stale(value):
            producer = value.producer_step.memory_resource
            raise ScheduleError(
                f"{site} input {argument!r} uses a stale handle for "
                f"'{value.variable.slot_name}' from {producer.name}; it was "
                "re-produced after this handle was captured."
            )
        return value

    def _mint_outputs(self, step: Step, info: _WorkInfo) -> object:
        """Return the token(s) representing the variables ``step`` produces.

        Each routable output records itself as the latest handle for its
        variable (so stale handles can be rejected) and is recorded on the step
        (``returned_variables``) so unrouted outputs can be flagged from the tree.
        """
        step.returned_variables = list(info.returned_variables)
        if not info.returned_variables:
            return DataFlowToken(producer_step=step)
        tokens: list[DataFlowToken] = []
        for variable in info.returned_variables:
            token = DataFlowToken(producer_step=step, variable=variable)
            self._builder.record_latest(token)
            tokens.append(token)
        return tokens[0] if len(tokens) == 1 else tuple(tokens)


# -- DSL surface ------------------------------------------------------------


def _require_active_builder(api: str) -> ScheduleBuilder:
    builder = _active_builder.get()
    if builder is None:
        raise ScheduleError(f"{api} must be called inside an @schedule function.")
    return builder


def _validate_domain_loop_bound_fn(name: str, fn: Callable[..., object]) -> None:
    """Require a callable domain bound to be a ``(self, coord)`` method accessed on the class."""
    if inspect.ismethod(fn) and fn.__self__ is not None:
        raise ScheduleError(
            f"domain_loop() {name} callable must be a Task method accessed on "
            "the class (e.g. MyTask.get_domain), not an instance-bound method."
        )
    try:
        signature = inspect.signature(fn)
    except (TypeError, ValueError) as exc:
        raise ScheduleError(
            f"domain_loop() {name} callable must expose a Python signature."
        ) from exc
    params = tuple(signature.parameters.values())
    valid_kinds = (
        inspect.Parameter.POSITIONAL_ONLY,
        inspect.Parameter.POSITIONAL_OR_KEYWORD,
    )
    if (
        len(params) != 2
        or any(p.kind not in valid_kinds for p in params)
        or any(p.default is not inspect.Parameter.empty for p in params)
    ):
        raise ScheduleError(
            f"domain_loop() {name} callable must accept exactly two required "
            "positional parameters: (self, work_tile_coord)."
        )


@contextmanager
def _conditional_block(
    builder: ScheduleBuilder,
    condition: BlockGuard,
) -> Iterator[None]:
    """Open a :class:`ConditionalBlock` with ``condition`` on enter, close it on exit."""
    node = ConditionalBlock(body=[], condition=condition)
    builder.open_scope(node)
    try:
        yield
    finally:
        builder.close_scope(node)


class WorkTileLoopProxy:
    """Yielded by work_tile_loop(); skippable() opens a skippable block."""

    def __init__(self, builder: ScheduleBuilder, loop: WorkTileLoop) -> None:
        self._builder = builder
        self._loop = loop

    def skippable(self) -> AbstractContextManager[None]:
        self._check_active("skippable")
        return _conditional_block(self._builder, SKIPPABLE)

    def _check_active(self, api: str) -> None:
        if not self._builder.is_scope_open(self._loop):
            raise ScheduleError(
                f"{api}() was called on a work_tile_loop() handle whose block "
                "has already exited; it is only valid inside the with-block of "
                "the loop that produced the handle."
            )


class DomainLoopProxy:
    """Yielded by domain_loop(); opens per-iteration condition blocks.

    Bound to the specific :class:`DomainLoop` it was produced for, so
    ``first_iter()`` / ``last_iter()`` / ``every()`` are rejected once that
    loop's ``with`` block has exited -- including when called from inside a
    later sibling ``domain_loop()``.
    """

    def __init__(self, builder: ScheduleBuilder, loop: DomainLoop) -> None:
        self._builder = builder
        self._loop = loop

    def first_iter(self) -> AbstractContextManager[None]:
        self._check_active("first_iter")
        return when_true(FIRST_ITER)

    def last_iter(self) -> AbstractContextManager[None]:
        self._check_active("last_iter")
        return when_true(LAST_ITER)

    def every(self, period: int, *, start: int = 0) -> AbstractContextManager[None]:
        self._check_active("every")
        return when_true(Every(period=period, start=start))

    def _check_active(self, api: str) -> None:
        if not self._builder.is_scope_open(self._loop):
            raise ScheduleError(
                f"{api}() was called on a domain_loop() handle whose block has "
                "already exited; per-iteration conditions are only valid inside the "
                "with-block of the loop that produced the handle."
            )


def _check_skip_predicate(skip_if: object, work_queue: WorkQueue) -> None:
    """Reject a ``work_tile_loop(skip_if=...)`` the WorkQueue cannot run.

    ``skip_if`` may be a plain ``(work_queue, work_tile)`` function/lambda or a
    method of ``work_queue``'s class.  Raises :class:`ScheduleError` when it is
    not callable, or when it is a method that belongs to a *different*
    WorkQueue.  Argument-count checks are left to Task construction.
    """
    if not callable(skip_if):
        raise ScheduleError("work_tile_loop(skip_if=...) must be callable.")

    # A bound method (``some_wq.skip_work_tile_if``) carries its instance in
    # ``__self__``; it must be bound to this loop's WorkQueue.
    bound_self = getattr(skip_if, "__self__", None)
    if isinstance(bound_self, WorkQueue) and bound_self is not work_queue:
        raise ScheduleError(
            "work_tile_loop(skip_if=...) is bound to a different WorkQueue "
            f"({type(bound_self).__name__}) than the loop's "
            f"{type(work_queue).__name__}."
        )

    # An unbound method (``MyWorkQueue.skip_work_tile_if``) is a function whose
    # __qualname__ is ``Class.method``; it must be defined on this WorkQueue's
    # class.  Plain functions/lambdas (no owning class) are accepted as-is.
    qualname = getattr(skip_if, "__qualname__", "")
    is_unbound_method = (
        "." in qualname
        and "<locals>" not in qualname
        and not qualname.endswith("<lambda>")
    )
    if is_unbound_method:
        name = getattr(skip_if, "__name__", "")
        on_this_work_queue = any(
            getattr(cls, name, None) is skip_if for cls in type(work_queue).__mro__
        )
        if not on_this_work_queue:
            raise ScheduleError(
                f"work_tile_loop(skip_if=...) method {qualname!r} is not a "
                f"method of WorkQueue {type(work_queue).__name__!r}."
            )


@contextmanager
def work_tile_loop(
    wq: object, *, skip_if: Callable[..., cutlass.Boolean] | None = None
) -> Iterator[WorkTileLoopProxy]:
    """Open the persistent work-tile (while) loop over ``wq``.

    ``skip_if`` is an optional predicate ``(work_queue, work_tile) -> Boolean``;
    when set, ``skippable()`` regions in the body are omitted for skipped tiles
    while the surrounding WorkQueue bookkeeping still runs.  It may be a plain
    ``(work_queue, work_tile)`` callable or a method of ``wq``.
    """
    builder = _require_active_builder("work_tile_loop()")
    if not isinstance(wq, ResourceProxy) or not isinstance(wq._resource, WorkQueue):
        raise ScheduleError(
            "work_tile_loop(wq) requires a traced WorkQueue resource argument."
        )
    if skip_if is not None:
        _check_skip_predicate(skip_if, wq._resource)
    node = WorkTileLoop(body=[], work_queue=wq._resource, skip_if=skip_if)
    builder.open_scope(node)
    try:
        yield WorkTileLoopProxy(builder, node)
    finally:
        builder.close_scope(node)


@contextmanager
def domain_loop(
    *bounds: object | Callable[..., object],
    unroll: int | None = None,
) -> Iterator[DomainLoopProxy]:
    """Open a domain (for-) loop over the work tile's iteration space.

    Bounds mirror Python's ``range``: ``domain_loop(end)``,
    ``domain_loop(start, end)``, or ``domain_loop(start, end, step)`` — an
    omitted ``start`` defaults to ``0`` and an omitted ``step`` to ``1``.
    **Any** bound may be a callable, which makes that dimension dynamic: pass a
    ``Task`` subclass method accessed on the class (``MyTask.get_domain``, not
    on an instance) so its ``self`` stays an explicit parameter; the Task
    runtime calls it as ``(self, work_tile_coord)`` to get that bound for the
    current work tile.

    Parameters
    ----------
    *bounds : int, DSL value, or callable
        1 to 3 range-style bounds (see above).
    unroll : int or None
        Loop unroll hint. ``None`` lets the compiler decide.
    """
    builder = _require_active_builder("domain_loop()")
    start: object | Callable[..., object]
    end: object | Callable[..., object]
    step: object | Callable[..., object]
    if len(bounds) == 1:
        start, end, step = 0, bounds[0], 1
    elif len(bounds) == 2:
        start, end, step = bounds[0], bounds[1], 1
    elif len(bounds) == 3:
        start, end, step = bounds
    else:
        raise ScheduleError(
            "domain_loop() takes 1 to 3 positional bounds like range(): "
            "domain_loop(end), (start, end), or (start, end, step)."
        )
    if isinstance(step, int) and step == 0:
        raise ScheduleError("domain_loop() step must be non-zero.")
    for name, value in (("start", start), ("end", end), ("step", step)):
        if callable(value):
            _validate_domain_loop_bound_fn(name, value)
        elif value is None:
            raise ScheduleError(
                f"domain_loop() {name} must be a value or a callable that "
                "returns it; got None."
            )
    node = DomainLoop(start=start, end=end, step=step, unroll=unroll, body=[])
    builder.open_scope(node)
    try:
        yield DomainLoopProxy(builder, node)
    finally:
        builder.close_scope(node)


def schedule(fn: Callable[..., None]) -> Callable[..., Schedule]:
    """Decorator that traces a schedule function into a ``Schedule``.

    Parameters
    ----------
    fn : Callable
        Function whose arguments are ``MemoryResource`` instances and whose body
        records resource calls through schedule-builder context managers.

    Returns
    -------
    Callable[..., Schedule]
        Wrapper that accepts concrete resources and returns the captured
        ``Schedule``.

    Notes
    -----
    The decorated function receives ``ResourceProxy`` wrappers for each
    ``MemoryResource``.  Method calls on the proxies record schedule
    entries and routing edges. ``with work_tile_loop(wq):`` and
    ``with domain_loop(start, end, step):`` mark the structural
    boundaries.  Plain Python control flow inside the function executes at
    trace time.
    """

    @functools.wraps(fn)
    def traced(*resources: object) -> Schedule:
        from .pipeline_group import _GroupMemberRef

        members: list[MemoryResource] = []
        for resource in resources:
            if isinstance(resource, _GroupMemberRef):
                # `group.member` -- unwrap to the bare member; group membership is
                # recovered downstream from ``member.pipeline_group``.
                members.append(resource.member)
            elif isinstance(resource, MemoryResource):
                # A grouped member must be spelled `group.member` so its barrier
                # identity is explicit; reject the bare form up front.
                if resource.pipeline_group is not None:
                    raise ScheduleError(
                        f"resource {resource.name!r} belongs to PipelineGroup "
                        f"{resource.pipeline_group.name!r} and must be passed as "
                        "`group.member`, not the bare member."
                    )
                members.append(resource)
            else:
                raise ScheduleError(
                    "@schedule arguments must be MemoryResource instances (or "
                    "PipelineGroup member refs such as `group.member`); got "
                    f"{type(resource).__name__}."
                )
        builder = ScheduleBuilder(name=fn.__name__, resources=members)
        proxies = [ResourceProxy(member, builder) for member in members]
        token = _active_builder.set(builder)
        try:
            fn(*proxies)
        finally:
            _active_builder.reset(token)
        return builder.finalize()

    return traced
