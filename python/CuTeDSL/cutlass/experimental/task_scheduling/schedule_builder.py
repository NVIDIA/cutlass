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
schedule.  The grammar is structured around a persistent work-tile loop,
one or more optional domain loops, and auxiliary work in between:

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
- A schedule may use ``with domain_loop(start, end, step):`` directly, with
  HEAD entries before the loop and TAIL entries after it.
- ``while_true_loop(init=..., advance=...)`` records a dynamic loop whose
  body repeats until a ``loop.break_loop()`` path fires.  A schedule may
  contain a ``domain_loop`` or a ``while_true_loop``, not both.

Variable tokens and lifecycle
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
``TaskLocalVariable`` fields materialize as task-local register state in
generated code. Consumer work declares the variable it returns with
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

A method that declares one ``returns=`` value yields one token; multiple
declared values yield a tuple of tokens.

Non-routable tokens
-------------------
Work calls that declare no ``returns=`` — pipeline ops (``acquire``,
``commit``, ...) and untyped work — return a token whose ``variable`` is
``None``. Only tokens carrying a variable may be passed as downstream inputs;
other tokens raise :class:`ScheduleError`.

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
    is an ordered list of nodes — ``Step`` / ``LoopBreak`` leaves plus
    ``ConditionalBlock`` / ``DomainLoop`` / ``WorkTileLoop`` /
    ``WhileTrueLoop`` containers — and per-variable data flow
    is recorded as named ``Step.input_bindings`` on consuming steps.

Step
    A leaf node: one pipeline op or work call on a resource. Carries its named
    input bindings and the variables (``returns=``) it produces.

ConditionalBlock
    A region whose body runs only when its :class:`~.enums.BlockGuard` holds.

DomainLoop
    A ``range``-style loop over the work tile's iteration domain; any
    bound may be a callable ``Task`` method to make that bound dynamic.

WorkTileLoop
    The persistent (while) loop over work tiles, driven by a ``WorkQueue``;
    an optional ``skip_if`` predicate enables skipped-tile execution.

WhileTrueLoop
    A dynamic loop whose cursor comes from init/advance consumer-work hooks
    and whose exit formula is the dominating guards of ``break_loop()``.

LoopBreak
    Marker leaf recorded by ``loop.break_loop()``.

DataFlowToken
    Opaque handle returned by a work call — one per ``TaskLocalVariable``
    declared in ``@consumer_work(returns=...)``.  Passing it to a downstream
    work call records a per-variable routing edge.

ResourceProxy
    Tracing wrapper around a ``MemoryResource``.  Method calls record
    schedule steps for pipeline operations.

DomainLoopProxy / WorkTileLoopProxy / WhileTrueLoopProxy
    Handles yielded by ``domain_loop()`` / ``work_tile_loop()`` /
    ``while_true_loop()``.
    ``DomainLoopProxy`` opens per-iteration ``first_iter()`` / ``last_iter()``
    / ``every()`` blocks; ``WorkTileLoopProxy`` opens ``skippable()`` blocks;
    ``WhileTrueLoopProxy`` records ``break_loop()``.

ScheduleBuilder
    Internal state machine that accumulates the schedule tree during
    tracing. The ``@schedule`` decorator manages its lifetime.

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
    tree. Bounds mirror ``range`` (``domain_loop(end)`` / ``(start, end)`` /
    ``(start, end, step)``); any bound may be a ``Task`` method
    accessed on the class (``MyTask.get_domain``) to make that dimension
    dynamic.

work_tile_loop(wq, *, skip_if=None)
    Wrapper that delimits the per-tile body of a persistent task.  With a
    ``skip_if=(work_queue, work_tile) -> Boolean`` predicate set, ``skippable()``
    regions are omitted for skipped tiles while the surrounding WorkQueue
    bookkeeping still runs.

while_true_loop(*, init, advance, verify_num_iters=None)
    Opens a dynamic loop.  ``init`` / ``advance`` are consumer work methods
    that return the loop cursor.  ``loop.break_loop()`` records the exit
    formula from the opaque guards that dominate the call.

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
from dataclasses import dataclass, field, replace
from types import TracebackType
from typing import Callable, Hashable, NoReturn, TypeGuard, cast

import cutlass
from typing_extensions import assert_never

from .enums import (
    BlockGuard,
    ComplementedIterationPredicate,
    Every,
    FIRST_ITER,
    GuardAnd,
    GuardOr,
    IterationPredicate,
    LAST_ITER,
    OpaqueCondition,
    SKIPPABLE,
    ScheduleStage,
    capture_user_source_loc,
    StateRole,
)
from .resources import (
    MemoryResource,
    TaskLocalVariable,
    WorkQueue,
    get_task_local_variables,
    _CONSUMER_WORK_FNS_ATTR,
    _PRODUCER_WORK_FNS_ATTR,
    _collect_named_work_fns,
)
from .pipeline_group import PipelineGroup

# ---------------------------------------------------------------------------
# Data model
# ---------------------------------------------------------------------------

# Shared with resource construction-site capture; one implementation.
_capture_source_loc = capture_user_source_loc


@dataclass(kw_only=True, eq=False)
class Step:
    """A leaf node: one pipeline op or work call on a resource.

    ``eq=False`` keeps identity equality/hash: steps are referenced by identity
    (by tokens, the scope map, and ``unique_id`` keying), and two
    structurally identical steps must stay distinct.

    Attributes
    ----------
    memory_resource : MemoryResource
        The resource this step operates on.
    schedule_stage : ScheduleStage
        Which pipeline stage / work kind this step is (e.g. ``ConsumerWait``).
    input_bindings : dict[str, TaskLocalVariable]
        This step's routed inputs as ``argument -> variable`` bindings: which
        task-local variable each routed parameter reads.  A binding observes the
        latest write to that variable in execution order, including values
        carried across loop iterations. Each variable occupies one
        identity-keyed task-local slot.
    constexpr_kwargs : dict
        Compile-time literals bound to ``cutlass.Constexpr`` work parameters
        (e.g. ``is_head=True``, ``subtile=0``) and forwarded to the work method.
    returned_variables : list[TaskLocalVariable]
        Variables this step produces, as declared by
        ``@consumer_work(returns=...)``.
    label : str | None
        The named work-fn label (e.g. ``"get_item"``), or ``None`` for a
        standard pipeline op.
    unique_id : int
        Stable per-schedule id, used for identity references and printing.
    source_loc : tuple[str, int] | None
        The ``(file, line)`` of the user call that recorded this step, for
        source-located diagnostics; ``None`` when unattributable.
    """

    memory_resource: MemoryResource
    schedule_stage: ScheduleStage
    input_bindings: "dict[str, TaskLocalVariable]" = field(default_factory=dict)
    constexpr_kwargs: dict = field(default_factory=dict)
    returned_variables: list[TaskLocalVariable] = field(default_factory=list)
    label: str | None = None
    state_binding: "PipelineStateRef | None" = None
    unique_id: int
    source_loc: "tuple[str, int] | None" = None


@dataclass(frozen=True)
class PipelineStateRef:
    """Trace-time reference to one explicit software-pipeline cursor."""

    resource: MemoryResource
    role: StateRole
    slot: int
    offset: int
    unique_id: int
    builder_id: int = field(repr=False, compare=False)
    stage_index: int | None = None

    def __str__(self) -> str:
        base = f"{self.resource.name}.{self.role.value}[{self.slot}]"
        if self.stage_index is not None:
            return f"{base}@{self.stage_index}"
        if self.offset:
            return f"{base}{self.offset:+d}"
        return base

    def advance(self, n: int = 1) -> None:
        builder = _require_active_builder("PipelineStateRef.advance()")
        builder.record_state_advance(self, n)

    def previous(self) -> "PipelineStateRef":
        return replace(self, offset=self.offset - 1)

    def at(self, stage_idx: int) -> "PipelineStateRef":
        """Select a physical ring buffer.  Valid on work, not on barrier ops.

        The view carries only a stage index.  Acquire, wait, commit, and
        release consume a ``(index, phase)`` cursor; ``at()`` does not know
        the phase, so those ops reject it.
        """
        if type(stage_idx) is not int:
            raise ScheduleError(
                f"{self}.at() stage index must be an int, got "
                f"{type(stage_idx).__name__}."
            )
        cfg = self.resource.pipeline_config
        assert cfg is not None
        if not 0 <= stage_idx < cfg.num_stages:
            raise ScheduleError(
                f"{self}.at({stage_idx}) is outside [0, {cfg.num_stages})."
            )
        return replace(self, stage_index=stage_idx)


@dataclass(kw_only=True, eq=False)
class StateAdvance:
    """A logical advance of an explicit software-pipeline cursor."""

    state: PipelineStateRef
    count: int = 1
    unique_id: int
    source_loc: "tuple[str, int] | None" = None


@dataclass(kw_only=True, eq=False)
class ConditionalBlock:
    """A region executed only when its guard holds.

    ``verify_num_fires`` is a verifier-only assertion available on
    ``when_true`` / ``when_false`` blocks inside ``while_true_loop``.  It is
    the exact number of modeled rounds on which the effective guard, including
    enclosing guards, must hold.  It constrains opaque exit histories without
    changing generated code.
    """

    body: "list[Node]"
    condition: BlockGuard
    verify_num_fires: int | None = None
    source_loc: "tuple[str, int] | None" = None


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
    source_loc: "tuple[str, int] | None" = None


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
    source_loc: "tuple[str, int] | None" = None


@dataclass(frozen=True)
class LoopHook:
    """Work method used as a ``while_true_loop`` init or advance hook."""

    resource: MemoryResource
    schedule_stage: ScheduleStage
    label: str
    result_name: str
    step: Step


@dataclass(kw_only=True, eq=False)
class LoopBreak:
    """Marker leaf for ``loop.break_loop()`` inside a captured while loop.

    ``conditions`` is the conjunction of guards that dominate the
    call (nested ``when_true`` / ``when_false``).  An empty tuple is an
    unconditional break.  When reached, the marker suppresses all later nodes
    in the current iteration.
    """

    conditions: tuple[BlockGuard, ...]
    source_loc: "tuple[str, int] | None" = None


@dataclass(kw_only=True, eq=False)
class WhileTrueLoop:
    """Dynamic loop whose body repeats until a recorded ``LoopBreak`` fires.

    ``verify_num_iters`` is the normalized tuple of modeled iteration counts
    the verifier explores.  Each count ``N`` is checked as
    ``retry^(N-1) + break``.
    """

    init: LoopHook
    advance: LoopHook
    verify_num_iters: tuple[int, ...]
    body: "list[Node]"
    breaks: list[LoopBreak] = field(default_factory=list)
    source_loc: "tuple[str, int] | None" = None

    @property
    def break_conditions(self) -> tuple[tuple[BlockGuard, ...], ...]:
        """Exit formula: the loop exits iff any captured break clause holds."""
        return tuple(brk.conditions for brk in self.breaks)


Node = (
    Step
    | StateAdvance
    | ConditionalBlock
    | DomainLoop
    | WorkTileLoop
    | WhileTrueLoop
    | LoopBreak
)


def _has_public_state_cursor(resource: MemoryResource) -> bool:
    """Return whether user-authored ``state=`` is valid for ``resource``."""
    return (
        resource.pipeline_config is not None
        and not isinstance(resource, WorkQueue)
        and not resource.is_barrier
    )


def _has_internal_state_cursor(resource: MemoryResource) -> bool:
    """Return whether the automatic rewrite may synthesize a cursor."""
    return resource.pipeline_config is not None or isinstance(resource, PipelineGroup)


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
    manual_state: bool = False

    def __str__(self) -> str:
        return _format_schedule(self)


def _child_nodes(node: Node) -> list[Node]:
    """Direct children of ``node`` (empty for a leaf :class:`Step` or :class:`LoopBreak`)."""
    match node:
        case Step() | StateAdvance() | LoopBreak():
            return []
        case (
            ConditionalBlock(body=body)
            | DomainLoop(body=body)
            | WorkTileLoop(body=body)
            | WhileTrueLoop(body=body)
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


def is_queue_advance_step(step: Step) -> bool:
    """True for a WorkQueue ``get_and_advance_work_tile`` step.

    The walker treats ``WorkQueue`` + ``ConsumerWork`` as the sole per-tile
    queue advance. Auxiliary WorkQueue work uses ``ConsumerAuxWork`` and is
    not an advance.
    """
    return (
        isinstance(step.memory_resource, WorkQueue)
        and step.schedule_stage is ScheduleStage.ConsumerWork
    )


def validate_queue_advance_placement(
    nodes: list[Node], *, parent_is_work_tile_loop: bool = False
) -> None:
    """Require every queue-advance step to be a direct ``WorkTileLoop`` child.

    The work-tile loop carries the advance return value as its ``scf.while``
    iter-arg, so a nested advance under ``domain_loop()`` or a conditional
    block cannot propagate. Raises :class:`ScheduleError` when placement is
    wrong.
    """
    for node in nodes:
        if isinstance(node, Step):
            if is_queue_advance_step(node) and not parent_is_work_tile_loop:
                raise ScheduleError(
                    "get_and_advance_work_tile() must be a direct child of "
                    "work_tile_loop()."
                )
        elif isinstance(node, WorkTileLoop):
            validate_queue_advance_placement(node.body, parent_is_work_tile_loop=True)
        elif isinstance(node, (DomainLoop, ConditionalBlock, WhileTrueLoop)):
            validate_queue_advance_placement(node.body, parent_is_work_tile_loop=False)
        elif isinstance(node, LoopBreak):
            continue


def _format_schedule(schedule: Schedule, *, show_routes: bool = True) -> str:
    res_list = ", ".join(f"{r.name}: {type(r).__name__}" for r in schedule.resources)

    steps = list(_iter_steps(schedule))

    # Execution order (pre-order) and nearest-enclosing-loop per step, for the
    # ``(carried)`` tag: a read is loop-carried when its variable is (re)written
    # later in the same loop, so the read observes a previous iteration's value.
    exec_index: dict[int, int] = {}
    enclosing_loop: dict[int, int] = {}

    def _index_nodes(nodes: "list[Node]", loop_id: int) -> None:
        for node in nodes:
            if isinstance(node, Step):
                exec_index[id(node)] = len(exec_index)
                enclosing_loop[id(node)] = loop_id
            child_loop = (
                id(node)
                if isinstance(node, (DomainLoop, WorkTileLoop, WhileTrueLoop))
                else loop_id
            )
            _index_nodes(_child_nodes(node), child_loop)

    _index_nodes(schedule.body, -1)

    # Include the variable-owning resource to make data provenance visible.
    def _feeder_resource(var: object) -> str | None:
        return getattr(getattr(var, "owner", None), "name", None)

    reads_view: dict[int, list[tuple[str, str, str | None]]] = {}
    for step in steps:
        if step.input_bindings:
            reads: list[tuple[str, str, str | None]] = []
            for arg, var in step.input_bindings.items():
                assert var.slot_name is not None
                reads.append((arg, var.slot_name, _feeder_resource(var)))
            reads_view[id(step)] = reads

    writers: dict[str, list[Step]] = {}
    for step in steps:
        for var in step.returned_variables:
            assert var.slot_name is not None
            writers.setdefault(var.slot_name, []).append(step)
    routed_slots = {slot for reads in reads_view.values() for _, slot, _ in reads}
    variables = ", ".join(sorted(routed_slots))
    var_suffix = f", variables=[{variables}]" if variables else ""
    lines = [f"Schedule({schedule.name!r}, resources=[{res_list}]{var_suffix})"]

    def _is_carried(reader: Step, slot: str) -> bool:
        # Carried iff the variable is (re)written later in the reader's loop.
        reader_loop = enclosing_loop.get(id(reader), -1)
        if reader_loop == -1:
            return False
        reader_idx = exec_index.get(id(reader), -1)
        return any(
            enclosing_loop.get(id(writer), -1) == reader_loop
            and exec_index.get(id(writer), -1) > reader_idx
            for writer in writers.get(slot, ())
        )

    def fmt_bound(value: object) -> str:
        if callable(value):
            return f"{getattr(value, '__name__', repr(value))}()"
        if isinstance(value, (bool, int, float)):
            return str(value)
        # Dynamic DSL values expose their printable payload through ``value``.
        inner = getattr(value, "value", None)
        if isinstance(inner, (bool, int, float)):
            return str(inner)
        if inner is not None:
            return f"<dynamic {type(value).__name__}>"
        return str(value)

    def fmt_header(node: Node) -> str:
        match node:
            case Step(memory_resource=resource, schedule_stage=stage, label=label):
                lbl = f", label={label!r}" if label else ""
                state = (
                    f", state={node.state_binding}"
                    if node.state_binding is not None
                    else ""
                )
                return (
                    f"[#{node.unique_id}] Step({resource.name}, {stage.name}"
                    f"{lbl}{state})"
                )
            case StateAdvance(state=state, count=count):
                return f"[#{node.unique_id}] StateAdvance({state}, +{count})"
            case ConditionalBlock(condition=condition):
                fires = (
                    f", verify_num_fires={node.verify_num_fires}"
                    if node.verify_num_fires is not None
                    else ""
                )
                return (
                    f"ConditionalBlock(condition={_format_block_guard(condition)}"
                    f"{fires})"
                )
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
            case WhileTrueLoop(init=init, advance=advance, verify_num_iters=iters):
                exit_formula = _format_exit_formula(node.breaks)
                return (
                    "WhileTrueLoop("
                    f"init={init.resource.name}.{init.label}, "
                    f"advance={advance.resource.name}.{advance.label}, "
                    f"verify_num_iters={iters}, "
                    f"exit={exit_formula})"
                )
            case LoopBreak(conditions=conditions):
                if not conditions:
                    return "LoopBreak()"
                conds = ", ".join(_format_block_guard(cond) for cond in conditions)
                return f"LoopBreak({conds})"
            case _:
                assert_never(node)

    def fmt_node(node: Node, indent: int) -> list[str]:
        pad = " " * indent
        out = [f"{pad}{fmt_header(node)}"]
        if show_routes and isinstance(node, Step):
            # Arrows show produced variables, consuming parameters, provenance,
            # and loop-carried reads.
            for var in node.returned_variables:
                out.append(f"{pad}      -> {var.slot_name}")
            for argument, slot, feeder in reads_view.get(id(node), []):
                tag = "  (loop-carried)" if _is_carried(node, slot) else ""
                source = f"{feeder}.{slot}" if feeder else slot
                out.append(f"{pad}      {argument} <- {source}{tag}")
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
class DataFlowToken(BlockGuard):
    """Handle returned by a work call; passing it downstream routes its variable.

    A consumer work call that declares ``returns=`` yields one token per
    produced :class:`TaskLocalVariable`; passing such a token into a downstream
    work call records the variable under the consuming step's named input. A
    token carries exactly one variable and binds to the single destination
    argument resolved from its slot position or keyword.

    Calls that declare no outputs (pipeline ops and untyped work) return a token
    with ``variable is None``. Routable tokens carry a variable.

    The builder tracks the latest token minted per variable. Re-producing a
    variable makes the new token its authoritative handle; freshness uses token
    identity.
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

    def __invert__(self) -> BlockGuard:
        return _NegatedDataFlowToken(self)


@dataclass(frozen=True)
class _NegatedDataFlowToken(BlockGuard):
    """Capture-time negation of a token, resolved to an opaque NNF leaf."""

    token: DataFlowToken

    def __invert__(self) -> BlockGuard:
        return self.token


_opaque_capture_counter = itertools.count()


def _format_iteration_predicate(condition: IterationPredicate) -> str:
    if isinstance(condition, ComplementedIterationPredicate):
        return f"~{_format_iteration_predicate(condition.predicate)}"
    if isinstance(condition, Every):
        return f"every(period={condition.period}, start={condition.start})"
    if condition is FIRST_ITER:
        return "first_iter"
    if condition is LAST_ITER:
        return "last_iter"
    return repr(condition)


def _format_guard_expression(condition: BlockGuard) -> str:
    if isinstance(condition, OpaqueCondition):
        value = f"key={condition.key!r}"
        return f"~({value})" if condition.negated else value
    if isinstance(condition, IterationPredicate):
        return _format_iteration_predicate(condition)
    if isinstance(condition, (GuardAnd, GuardOr)):
        operator = " and " if isinstance(condition, GuardAnd) else " or "
        return (
            "("
            + operator.join(
                _format_guard_expression(operand) for operand in condition.operands
            )
            + ")"
        )
    raise TypeError(f"unsupported guard expression type: {type(condition).__name__}")


def _format_block_guard(condition: BlockGuard) -> str:
    if condition is SKIPPABLE:
        return "Skippable"
    if isinstance(condition, OpaqueCondition):
        polarity = "when_false" if condition.negated else "when_true"
        return f"{polarity}(key={condition.key!r})"
    if isinstance(condition, (IterationPredicate, GuardAnd, GuardOr)):
        if isinstance(condition, (GuardAnd, GuardOr)):
            return f"when_true({_format_guard_expression(condition)})"
        return _format_iteration_predicate(condition)
    raise TypeError(f"unsupported block guard type: {type(condition).__name__}")


def _format_exit_formula(breaks: list[LoopBreak]) -> str:
    """Render the while-loop exit formula from captured break clauses."""
    if not breaks:
        return "never"
    clauses: list[str] = []
    for brk in breaks:
        if not brk.conditions:
            clauses.append("true")
            continue
        parts = [_format_block_guard(cond) for cond in brk.conditions]
        joined = " and ".join(parts)
        clauses.append(joined)
    if len(clauses) == 1:
        return clauses[0]
    return " or ".join(
        f"({clause})" if " and " in clause else clause for clause in clauses
    )


def _resolve_when_guard(
    builder: "ScheduleBuilder",
    cond: object,
    *,
    key: Hashable | None,
    negated: bool,
    api: str,
    key_from_composite: bool = False,
) -> BlockGuard:
    # Must precede the opaque capture below: an iteration-block context is not a
    # recognized guard, so the fallback would turn it into a resource-less
    # OpaqueCondition, which codegen treats as unconditionally true.
    if isinstance(cond, _IterationBlockContext):
        cond._operand_error()
    if isinstance(cond, (GuardAnd, GuardOr)):
        if (
            key is not None
            and not key_from_composite
            and not any(
                not isinstance(leaf, IterationPredicate)
                for leaf in _unresolved_guard_leaves(cond)
            )
        ):
            raise ScheduleError(
                f"{api}(): key= on a composite condition requires at least one "
                "opaque leaf to correlate."
            )
        resolved = tuple(
            _resolve_when_guard(
                builder,
                operand,
                key=key,
                negated=False,
                api=api,
                key_from_composite=key is not None,
            )
            for operand in cond.operands
        )
        guard: BlockGuard = type(cond)(resolved)
        if negated:
            guard = ~guard
        return guard
    if isinstance(cond, IterationPredicate):
        if key is not None and not key_from_composite:
            warnings.warn(
                f"{api}(): key= is ignored for iteration predicates.",
                stacklevel=3,
            )
        if negated:
            cond = ~cond
        if not builder._is_inside_domain_loop():
            raise ScheduleError(
                f"{api}() with an iteration predicate is only valid inside "
                "domain_loop()."
            )
        return cond
    token_negated = False
    if isinstance(cond, _NegatedDataFlowToken):
        token_negated = True
        cond = cond.token
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
            negated=negated != token_negated,
            resource=cond.producer_step.memory_resource,
            method_label=label,
            result_name=result_name,
        )
    if isinstance(cond, OpaqueCondition):
        if key is not None:
            cond = OpaqueCondition(
                key=key,
                negated=cond.negated,
                resource=cond.resource,
                method_label=cond.method_label,
                result_name=cond.result_name,
            )
        return ~cond if negated else cond
    resolved_key = (
        key if key is not None else ("__opaque__", next(_opaque_capture_counter))
    )
    return OpaqueCondition(key=resolved_key, negated=negated)


def _unresolved_guard_leaves(guard: BlockGuard) -> Iterator[BlockGuard]:
    """Yield leaves before work-call tokens have been resolved to opaque guards."""
    if isinstance(guard, (GuardAnd, GuardOr)):
        for operand in guard.operands:
            yield from _unresolved_guard_leaves(operand)
    else:
        yield guard


@contextmanager
def when_true(
    cond: object,
    *,
    key: Hashable | None = None,
    verify_num_fires: int | None = None,
) -> Iterator[None]:
    """Open a block that runs when ``cond`` is true.

    Iteration predicates are only valid inside ``domain_loop()``.  Opaque
    runtime conditions are work-call outputs backed by ``TaskLocalVariable``
    slots. Conditions may be combined with ``&`` / ``|`` / ``~`` and nested
    condition blocks compose as runtime conjunctions. Keying a composite
    correlates all of its opaque leaves; iteration-predicate leaves are unchanged.
    Extra guards that wrap ``break_loop()`` are part of the while-loop exit
    formula.

    ``verify_num_fires=N`` asserts that this block runs on exactly ``N`` of
    the enclosing ``while_true_loop``'s modeled rounds.  The exhaustive
    checker uses the assertion to discard impossible opaque exit histories;
    it has no runtime effect.
    """
    builder = _require_active_builder("when_true()")
    guard = _resolve_when_guard(builder, cond, key=key, negated=False, api="when_true")
    with _conditional_block(builder, guard, verify_num_fires=verify_num_fires):
        yield


@contextmanager
def when_false(
    cond: object,
    *,
    key: Hashable | None = None,
    verify_num_fires: int | None = None,
) -> Iterator[None]:
    """Open a block that runs when ``cond`` is false.

    This is equivalent to ``when_true(~cond)`` for any schedule guard tree.
    Composite guards are converted to negation-normal form.
    ``verify_num_fires`` behaves as in :func:`when_true`.
    """
    builder = _require_active_builder("when_false()")
    guard = _resolve_when_guard(builder, cond, key=key, negated=True, api="when_false")
    with _conditional_block(builder, guard, verify_num_fires=verify_num_fires):
        yield


@dataclass(frozen=True)
class _WorkInfo:
    """Per-proxy-method metadata needed to record a step and its routes.

    Resolved once per proxy from the resource's ``@consumer_work`` /
    ``@producer_work`` decorator metadata.
    """

    stage: ScheduleStage
    label: str | None
    # Positional-or-keyword data-flow inputs, in positional binding order.
    routed_positional_names: tuple[str, ...]
    # Keyword-only data-flow inputs, bound as ``argument=token``.
    routed_keyword_names: tuple[str, ...]
    # Task-local variables declared through ``returns=``.
    returned_variables: tuple[TaskLocalVariable, ...]
    # Keyword-only ``cutlass.Constexpr[...]`` parameters forwarded as literals.
    constexpr_names: tuple[str, ...] = ()
    # ``constexpr_names`` entries that require an explicit value.
    required_constexpr_names: tuple[str, ...] = ()

    @property
    def routed_names(self) -> tuple[str, ...]:
        """All routed data-flow input names, in declaration order."""
        return self.routed_positional_names + self.routed_keyword_names


_Scope = Schedule | ConditionalBlock | DomainLoop | WorkTileLoop | WhileTrueLoop


def _is_allowed_outside_work_tile_loop(node: Node) -> bool:
    """True for a step allowed outside the work-tile loop."""
    return isinstance(node, Step) and (
        node.schedule_stage in _AUX_STAGES or node.memory_resource.is_barrier
    )


class ScheduleBuilder:
    """Accumulates a :class:`Schedule` tree while a ``@schedule`` function runs.

    Recording uses a scope stack.  Every container (the root ``Schedule`` plus
    any open ``ConditionalBlock`` / ``DomainLoop`` / ``WorkTileLoop`` /
    ``WhileTrueLoop``) exposes ``body``; context managers push on enter and pop
    on exit.
    """

    def __init__(
        self,
        name: str,
        resources: list[MemoryResource],
        *,
        manual_state: bool = False,
    ) -> None:
        self._schedule = Schedule(
            name=name, body=[], resources=resources, manual_state=manual_state
        )
        self.manual_state = manual_state
        self._stack: list[_Scope] = [self._schedule]
        self._has_work_tile_loop = False
        self._has_while_true_loop = False
        self._after_work_tile_loop = False
        # Freshness is tracked independently for each task-local variable.
        self._latest_token: dict[TaskLocalVariable, DataFlowToken] = {}
        # Produced values used as opaque conditions are consumed by control flow,
        # with their use tracked separately from routed data flow.
        self._condition_uses: set[tuple[int, int]] = set()
        # Step identifiers are stable and monotonic within a schedule.
        self._next_unique_id = 0
        self._next_state_id = 0
        self._state_slots: dict[tuple[int, StateRole], int] = {}

    def mint_state(
        self, resource: MemoryResource, role: StateRole, *, internal: bool = False
    ) -> PipelineStateRef:
        """Mint the next cursor slot for ``resource`` and ``role``."""
        if not self.manual_state and not internal:
            raise ScheduleError(
                f"{resource.name}.{role.value}_state() is only valid in an "
                "@schedule(manual_state=True) function."
            )
        if not _has_public_state_cursor(resource) and not (
            internal and _has_internal_state_cursor(resource)
        ):
            raise ScheduleError(
                f"{resource.name} has no stage cursor; state references require "
                "a non-barrier resource with pipeline_config."
            )
        key = (id(resource), role)
        slot = self._state_slots.get(key, 0)
        if slot >= 2:
            raise ScheduleError(
                f"{resource.name}.{role.value}_state() supports at most two "
                "independent cursor slots."
            )
        self._state_slots[key] = slot + 1
        ref = PipelineStateRef(
            resource=resource,
            role=role,
            slot=slot,
            offset=0,
            unique_id=self._next_state_id,
            builder_id=id(self),
        )
        self._next_state_id += 1
        return ref

    def record_state_advance(self, state: PipelineStateRef, count: int = 1) -> None:
        """Append a cursor advance after validating its local shape."""
        if state.builder_id != id(self):
            raise ScheduleError(
                f"cursor {state} was not minted in schedule {self._schedule.name!r}."
            )
        if state.offset != 0 or state.stage_index is not None:
            raise ScheduleError(f"cursor view {state} is read-only and cannot advance.")
        if type(count) is not int or count <= 0:
            raise ScheduleError(
                f"{state}.advance() count must be a positive int, got {count!r}."
            )
        node = StateAdvance(state=state, count=count, unique_id=self._next_unique_id)
        self._next_unique_id += 1
        self._stack[-1].body.append(node)

    # -- token lifecycle --

    def record_latest(self, token: DataFlowToken) -> None:
        """Mark ``token`` as the latest handle for the variable it carries."""
        if token.variable is not None:
            self._latest_token[token.variable] = token

    def is_stale(self, token: DataFlowToken) -> bool:
        """Return whether ``token`` differs from its variable's latest handle."""
        if token.variable is None:
            return True
        return self._latest_token.get(token.variable) is not token

    def record_condition_use(self, token: DataFlowToken) -> None:
        """Mark ``token`` as consumed by a ``when_true`` / ``when_false`` guard."""
        assert token.variable is not None
        self._condition_uses.add((id(token.producer_step), id(token.variable)))

    def _warn_unconsumed(self) -> None:
        """Warn about consumer outputs that are produced but never routed.

        A produced variable is consumed when it appears in a step's
        ``input_bindings`` or guards an opaque conditional block. Persistent-loop
        machinery consumes WorkQueue tile state through ``stage_info``.
        """
        read_variables = {
            variable
            for reader in _iter_steps(self._schedule)
            for variable in reader.input_bindings.values()
        }
        for step in _iter_steps(self._schedule):
            if isinstance(step.memory_resource, WorkQueue):
                continue
            label = step.label or step.schedule_stage.name
            for variable in step.returned_variables:
                if variable in read_variables:
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
        self, container: ConditionalBlock | DomainLoop | WorkTileLoop | WhileTrueLoop
    ) -> None:
        """Validate ``container``, link it into the current scope, make it current."""
        if self._after_work_tile_loop and not isinstance(container, WorkTileLoop):
            raise ScheduleError("no blocks may follow work_tile_loop()")
        self._validate_open(container)
        if isinstance(container, WorkTileLoop):
            self._has_work_tile_loop = True
        if isinstance(container, WhileTrueLoop):
            self._has_while_true_loop = True
        if container.source_loc is None:
            container.source_loc = _capture_source_loc()
        self._stack[-1].body.append(container)
        self._stack.append(container)

    def close_scope(
        self, container: ConditionalBlock | DomainLoop | WorkTileLoop | WhileTrueLoop
    ) -> None:
        """Pop ``container``; it must be the current (innermost) scope."""
        if self._stack[-1] is not container:
            raise ScheduleError("schedule blocks closed out of order.")
        if isinstance(container, WhileTrueLoop):
            if not container.breaks:
                raise ScheduleError(
                    "while_true_loop() requires at least one loop.break_loop()."
                )
            if any(count > 1 for count in container.verify_num_iters) and any(
                not brk.conditions for brk in container.breaks
            ):
                raise ScheduleError(
                    "while_true_loop() with verify_num_iters > 1 requires a "
                    "retry assignment, but a break_loop() is unconditional."
                )
        self._stack.pop()
        if isinstance(container, WorkTileLoop):
            self._after_work_tile_loop = True

    def record_step(
        self,
        resource: MemoryResource,
        info: "_WorkInfo",
        state_binding: PipelineStateRef | None = None,
    ) -> Step:
        """Append a :class:`Step` (described by ``info``) to the current scope."""
        if isinstance(resource, WorkQueue) and self._in_skippable():
            raise ScheduleError(
                "WorkQueue operations cannot appear inside a skippable() block; "
                "skipped work tiles must still run WorkQueue "
                "wait/advance/release bookkeeping."
            )
        # Queue advance must be a direct WorkTileLoop child: the walker returns
        # the next tile only from a direct Step sibling of the loop body.
        if (
            isinstance(resource, WorkQueue)
            and info.stage is ScheduleStage.ConsumerWork
            and not isinstance(self._stack[-1], WorkTileLoop)
        ):
            raise ScheduleError(
                "get_and_advance_work_tile() must be a direct child of "
                "work_tile_loop()."
            )
        step = Step(
            memory_resource=resource,
            schedule_stage=info.stage,
            label=info.label,
            state_binding=state_binding,
            unique_id=self._next_unique_id,
            source_loc=_capture_source_loc(),
        )
        self._validate_state_binding(step)
        if self._after_work_tile_loop and not _is_allowed_outside_work_tile_loop(step):
            raise ScheduleError(
                "detected a schedule entry that is not allowed outside "
                "work_tile_loop()."
            )
        self._next_unique_id += 1
        self._stack[-1].body.append(step)
        return step

    def allocate_step(self, resource: MemoryResource, info: "_WorkInfo") -> Step:
        """Create a ``Step`` with a unique id without appending it to the tree.

        Used for ``while_true_loop`` init/advance hooks, which run outside the
        recorded body.
        """
        step = Step(
            memory_resource=resource,
            schedule_stage=info.stage,
            label=info.label,
            unique_id=self._next_unique_id,
        )
        self._next_unique_id += 1
        step.returned_variables = list(info.returned_variables)
        return step

    def record_loop_break(self, loop: WhileTrueLoop) -> LoopBreak:
        """Append a ``LoopBreak`` marker dominated by the active opaque guards."""
        if not self.is_scope_open(loop):
            raise ScheduleError(
                "break_loop() was called on a while_true_loop() handle whose block "
                "has already exited."
            )
        conditions: list[BlockGuard] = []
        for frame in self._stack:
            if isinstance(frame, ConditionalBlock) and frame.condition is not SKIPPABLE:
                conditions.append(frame.condition)
        node = LoopBreak(conditions=tuple(conditions), source_loc=_capture_source_loc())
        loop.breaks.append(node)
        self._stack[-1].body.append(node)
        return node

    def finalize(self) -> Schedule:
        """Return the completed schedule once every scope has been closed."""
        if len(self._stack) != 1:
            raise ScheduleError("schedule ended with an unclosed block.")
        if not self.manual_state:
            self._rewrite_implicit_state()
            self._renumber_nodes()
        self._validate_single_work_queue()
        self._validate_queue_advance_placement()
        self._validate_domain_and_while_exclusivity()
        self._warn_unconsumed()
        return self._schedule

    def _validate_domain_and_while_exclusivity(self) -> None:
        """Reject a schedule that mixes ``domain_loop`` and ``while_true_loop``."""
        has_domain = any(
            isinstance(node, DomainLoop) for node in _iter_nodes(self._schedule.body)
        )
        has_while = any(
            isinstance(node, WhileTrueLoop) for node in _iter_nodes(self._schedule.body)
        )
        if has_domain and has_while:
            raise ScheduleError(
                "domain_loop() and while_true_loop() cannot both appear in one "
                "schedule."
            )

    def _renumber_nodes(self) -> None:
        """Assign execution-order ids after automatic nodes are inserted."""
        next_id = 0

        def renumber(nodes: list[Node]) -> None:
            nonlocal next_id
            for node in nodes:
                if isinstance(node, (Step, StateAdvance)):
                    node.unique_id = next_id
                    next_id += 1
                    continue
                if isinstance(node, WhileTrueLoop):
                    node.init.step.unique_id = next_id
                    next_id += 1
                    renumber(node.body)
                    node.advance.step.unique_id = next_id
                    next_id += 1
                    continue
                renumber(_child_nodes(node))

        renumber(self._schedule.body)
        self._next_unique_id = next_id

    @staticmethod
    def _state_role_for_stage(stage: ScheduleStage) -> StateRole:
        if stage in {
            ScheduleStage.ProducerTryAcquire,
            ScheduleStage.ProducerAcquire,
            ScheduleStage.ProducerWork,
            ScheduleStage.ProducerCommit,
            ScheduleStage.ProducerAuxWork,
        }:
            return StateRole.Producer
        return StateRole.Consumer

    def _validate_state_binding(self, step: Step) -> None:
        """Enforce the manual-state call-site rules (R1/R2)."""
        resource = step.memory_resource
        state = step.state_binding
        has_cursor = _has_public_state_cursor(resource)
        site = f"{resource.name}.{step.label or step.schedule_stage.name}()"
        if state is not None and not has_cursor:
            raise ScheduleError(
                f"{site} forbids state=: {resource.name} has no cursor."
            )
        if self.manual_state and has_cursor and state is None:
            raise ScheduleError(
                f"{site} in a manual_state schedule requires state=; pass "
                f"{resource.name}.{self._state_role_for_stage(step.schedule_stage).value}"
                "_state() minted in this schedule."
            )
        if state is None:
            return
        expected = self._state_role_for_stage(step.schedule_stage)
        if state.builder_id != id(self):
            raise ScheduleError(
                f"{site} uses stale cursor {state} from another schedule."
            )
        if state.resource is not resource:
            raise ScheduleError(
                f"{site} uses cursor owned by {state.resource.name}; expected "
                f"{resource.name}."
            )
        if state.role is not expected:
            raise ScheduleError(
                f"{site} requires a {expected.value} cursor, got {state.role.value} "
                f"cursor {state}."
            )
        if (
            state.stage_index is not None
            and step.schedule_stage in self._PHASE_SENSITIVE_STAGES
        ):
            raise ScheduleError(
                f"{site} cannot take {state}: at() selects a physical buffer "
                "and does not carry a wait/acquire phase. Use the live cursor "
                "or previous()."
            )

    #: Barrier ops that wait or arrive with a ``(index, phase)`` cursor.
    #: ``at()`` supplies only a physical index, so these stages reject it.
    _PHASE_SENSITIVE_STAGES = frozenset(
        {
            ScheduleStage.ProducerTryAcquire,
            ScheduleStage.ProducerAcquire,
            ScheduleStage.ProducerCommit,
            ScheduleStage.ConsumerTryWait,
            ScheduleStage.ConsumerWait,
            ScheduleStage.ConsumerRelease,
        }
    )

    #: Per role, the stages that drive the split-cursor rewrite: the leading
    #: barrier op that claims a stage, the data movement on that stage, and the
    #: trailing barrier op that frees it.  ``advance_on_acquire`` splits the
    #: producer triple exactly the way ``advance_on_wait`` splits the consumer
    #: one, so both roles share one rewrite rule.
    _SPLIT_CURSOR_STAGES = {
        StateRole.Producer: (
            ScheduleStage.ProducerAcquire,
            ScheduleStage.ProducerWork,
            ScheduleStage.ProducerCommit,
        ),
        StateRole.Consumer: (
            ScheduleStage.ConsumerWait,
            ScheduleStage.ConsumerWork,
            ScheduleStage.ConsumerRelease,
        ),
    }

    def _rewrite_implicit_state(self) -> None:
        """Rewrite implicit cursor motion into explicit state managment.

        A resource that advances on its leading barrier op
        (``advance_on_acquire`` / ``advance_on_wait``) keeps two live cursors:
        slot 0 leads and is advanced by the leading op, slot 1 lags and is
        advanced by the trailing op.  Work in between reads the stage the
        leading op just claimed, which is slot 0's ``previous()`` view; work
        with no leading op ahead of it reads the lagging cursor directly.
        Every other resource keeps the single slot-0 cursor advanced by its
        trailing op.
        """
        refs: dict[tuple[int, StateRole, int], PipelineStateRef] = {}
        # Resources whose leading barrier op has been recorded so far, in
        # source order, so work can tell which cursor holds its stage.
        led: set[int] = set()

        def ref(
            resource: MemoryResource, role: StateRole, slot: int
        ) -> PipelineStateRef:
            key = (id(resource), role, slot)
            if key not in refs:
                while (id(resource), role, slot) not in refs:
                    minted = self.mint_state(resource, role, internal=True)
                    refs[(id(resource), role, minted.slot)] = minted
            return refs[key]

        def rewrite(nodes: list[Node]) -> list[Node]:
            out: list[Node] = []
            for node in nodes:
                if isinstance(
                    node, (ConditionalBlock, DomainLoop, WorkTileLoop, WhileTrueLoop)
                ):
                    node.body = rewrite(node.body)
                    out.append(node)
                    continue
                if not isinstance(node, Step):
                    out.append(node)
                    continue
                resource = node.memory_resource
                cfg = resource.pipeline_config
                if not _has_internal_state_cursor(resource):
                    out.append(node)
                    continue
                assert cfg is not None
                stage = node.schedule_stage
                role = self._state_role_for_stage(stage)
                lead, work, trail = self._SPLIT_CURSOR_STAGES[role]
                split = (
                    cfg.advance_on_acquire
                    if role is StateRole.Producer
                    else cfg.advance_on_wait
                )
                slot = 0
                view_offset = 0
                # Without a split, one cursor serves the whole triple and the
                # trailing op moves it.  With a split, the leading op moves
                # slot 0 and the trailing op moves slot 1, so both advance.
                advance_after = stage is (lead if split else trail)
                if split:
                    if stage is trail:
                        slot = 1
                        advance_after = True
                    elif stage is work:
                        if id(resource) in led:
                            view_offset = -1
                        else:
                            slot = 1
                if stage is lead:
                    led.add(id(resource))
                binding = ref(resource, role, slot)
                if view_offset:
                    binding = replace(binding, offset=view_offset)
                node.state_binding = binding
                out.append(node)
                if advance_after:
                    live = ref(resource, role, slot)
                    out.append(
                        StateAdvance(
                            state=live,
                            count=1,
                            unique_id=self._next_unique_id,
                        )
                    )
                    self._next_unique_id += 1
            return out

        self._schedule.body = rewrite(self._schedule.body)

    def _validate_queue_advance_placement(self) -> None:
        """Require every queue-advance step to be a direct ``WorkTileLoop`` child.

        The work-tile loop carries the advance return value as its ``scf.while``
        iter-arg, so a nested advance under ``domain_loop()`` or a conditional
        block cannot propagate. Raises :class:`ScheduleError` when placement is
        wrong.
        """
        validate_queue_advance_placement(self._schedule.body)

    def _validate_single_work_queue(self) -> None:
        """Reject a schedule that references more than one WorkQueue resource.

        A schedule is driven by a single tile scheduler, so at most one distinct
        WorkQueue may be referenced across its ``work_tile_loop()`` and steps.
        """
        work_queues: dict[int, WorkQueue] = {}
        for node in _iter_nodes(self._schedule.body):
            if isinstance(node, WorkTileLoop):
                work_queues[id(node.work_queue)] = node.work_queue
            elif isinstance(node, Step) and isinstance(node.memory_resource, WorkQueue):
                work_queues[id(node.memory_resource)] = node.memory_resource
        if len(work_queues) > 1:
            names = ", ".join(sorted(wq.name for wq in work_queues.values()))
            raise ScheduleError(
                "a schedule may reference at most one WorkQueue (a single tile "
                f"scheduler); found {len(work_queues)}: {names}."
            )

    # -- ancestry queries --

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

    def _is_inside_while_true_loop(self) -> bool:
        return any(isinstance(f, WhileTrueLoop) for f in self._stack)

    def _in_iteration_predicate_condition(self) -> bool:
        return any(
            isinstance(frame, ConditionalBlock)
            and isinstance(frame.condition, IterationPredicate)
            for frame in self._stack
        )

    def _in_non_skippable_condition(self) -> bool:
        return any(
            isinstance(frame, ConditionalBlock) and frame.condition is not SKIPPABLE
            for frame in self._stack
        )

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

    def _validate_verify_num_fires(self, block: ConditionalBlock) -> None:
        """Reject a fire-count assertion the verifier could not apply."""
        count = block.verify_num_fires
        assert count is not None
        if type(count) is not int or count < 0:
            raise ScheduleError(
                f"verify_num_fires must be a non-negative int, got {count!r}."
            )
        if not self._is_inside_while_true_loop():
            raise ScheduleError(
                "verify_num_fires= is only valid inside while_true_loop(); it "
                "counts that loop's modeled rounds. A domain_loop() already "
                "has a static trip count."
            )

    def _validate_open(
        self, container: ConditionalBlock | DomainLoop | WorkTileLoop | WhileTrueLoop
    ) -> None:
        if (
            isinstance(container, ConditionalBlock)
            and container.verify_num_fires is not None
        ):
            self._validate_verify_num_fires(container)
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
                if self._is_inside_while_true_loop():
                    raise ScheduleError(
                        "domain_loop() cannot be nested inside while_true_loop()."
                    )
                # Domain-loop work must be omitted for skipped tiles.
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
            case WhileTrueLoop():
                if self._has_while_true_loop or self._is_inside_while_true_loop():
                    raise ScheduleError(
                        "at most one while_true_loop() is allowed per schedule; "
                        "while_true_loop() cannot be nested inside another "
                        "while_true_loop()."
                    )
                if self._is_inside_domain_loop():
                    raise ScheduleError(
                        "while_true_loop() cannot be nested inside domain_loop()."
                    )
                if self._in_non_skippable_condition():
                    raise ScheduleError(
                        "while_true_loop() cannot be nested inside a condition block."
                    )
                wtl = self._enclosing_work_tile_loop()
                if (
                    wtl is not None
                    and wtl.skip_if is not None
                    and not self._in_skippable()
                ):
                    raise ScheduleError(
                        "with work_tile_loop(skip_if=...), while_true_loop() must be "
                        "inside wtl.skippable()."
                    )


def ensure_explicit_state_ir(schedule: Schedule, *, force: bool = False) -> None:
    """Normalize directly constructed automatic schedules to the common IR."""

    def has_implicit_cursor_step(node: Node) -> TypeGuard[Step]:
        return isinstance(node, Step) and _has_internal_state_cursor(
            node.memory_resource
        )

    def strip(nodes: list[Node]) -> list[Node]:
        stripped: list[Node] = []
        for node in nodes:
            if isinstance(node, Step):
                if has_implicit_cursor_step(node):
                    node.state_binding = None
                stripped.append(node)
            elif isinstance(node, StateAdvance):
                continue
            elif isinstance(
                node, (ConditionalBlock, DomainLoop, WorkTileLoop, WhileTrueLoop)
            ):
                node.body = strip(node.body)
                stripped.append(node)
            elif isinstance(node, LoopBreak):
                stripped.append(node)
            else:
                assert_never(node)
        return stripped

    missing = [
        node
        for node in _iter_nodes(schedule.body)
        if has_implicit_cursor_step(node) and node.state_binding is None
    ]
    if schedule.manual_state:
        if force:
            return
        if not missing:
            return
        first = missing[0]
        raise ScheduleError(
            f"{first.memory_resource.name}.{first.schedule_stage.name}() in a "
            "manual_state Schedule requires state_binding."
        )
    if not force and not missing:
        return
    if force:
        schedule.body = strip(schedule.body)
    resources: list[MemoryResource] = []
    seen: set[int] = set()
    for node in _iter_nodes(schedule.body):
        if isinstance(node, Step) and id(node.memory_resource) not in seen:
            seen.add(id(node.memory_resource))
            resources.append(node.memory_resource)
    builder = ScheduleBuilder(schedule.name, resources)
    builder._schedule = schedule
    builder._stack = [schedule]
    builder._next_unique_id = (
        max(
            (
                node.unique_id
                for node in _iter_nodes(schedule.body)
                if isinstance(node, (Step, StateAdvance))
            ),
            default=-1,
        )
        + 1
    )
    builder._rewrite_implicit_state()
    builder._renumber_nodes()


class ResourceProxy:
    """Tracing proxy for a ``MemoryResource``.

    Method calls on the proxy record pipeline operations as schedule entries in
    the ``ScheduleBuilder``.

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

    Named work methods registered via ``@consumer_work`` /
    ``@producer_work`` on the resource class are also bound here::

        proxy.k_desc()             # ConsumerWork with label="k_desc"
        proxy.k_load(token)        # ProducerWork with label="k_load"

    WorkQueue operations use named methods such as
    ``get_and_advance_work_tile()`` and ``fetch_work_tile()`` so each schedule
    entry identifies its scheduler operation.
    """

    def __init__(self, resource: MemoryResource, builder: ScheduleBuilder) -> None:
        self._resource = resource
        self._builder = builder
        self._work_info: dict[str, _WorkInfo] = {}
        # Slot names resolve declared outputs to concrete task-local variables.
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
            # The metaclass resolves return slots to a tuple at class creation.
            names = getattr(method, "_consumer_return_var_names", None) or ()
            self._register_work_info(
                proxy_name,
                _WorkInfo(
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
                raise ScheduleError(
                    f"@producer_work {proxy_name!r} on {res_cls.__name__} collides "
                    "with a @consumer_work of the same name; a work-method label "
                    "must be unique. Rename one of them."
                )
            method = getattr(res_cls, method_name, None)
            self._register_work_info(
                proxy_name,
                _WorkInfo(
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
                ),
            )

    def _register_work_info(self, proxy_name: str, info: _WorkInfo) -> None:
        """Publish ``info`` after rejecting a work argument named ``state``."""
        if "state" in info.routed_names or "state" in info.constexpr_names:
            raise ScheduleError(
                f"{self._resource.name}.{proxy_name}() cannot declare a work "
                "argument named 'state'; state= is reserved for a "
                "PipelineStateRef cursor."
            )
        self._work_info[proxy_name] = info

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
        if name == "producer_state":
            return lambda: self._builder.mint_state(self._resource, StateRole.Producer)
        if name == "consumer_state":
            return lambda: self._builder.mint_state(self._resource, StateRole.Consumer)
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
            state = kwargs.get("state")
            if state is not None and not isinstance(state, PipelineStateRef):
                raise ScheduleError(
                    f"{self._site(info)} state= must be a PipelineStateRef, got "
                    f"{type(state).__name__}."
                )
            step = self._builder.record_step(
                self._resource,
                info,
                state_binding=state if isinstance(state, PipelineStateRef) else None,
            )
            self._bind_routes(step, info, args, kwargs)
            return self._mint_outputs(step, info)

        record._ts_loop_hook_resource = self._resource  # type: ignore[attr-defined]
        record._ts_loop_hook_info = info  # type: ignore[attr-defined]
        return record

    def _site(self, info: _WorkInfo) -> str:
        """Return a ``res.method()`` label for diagnostics."""
        return f"{self._resource.name}.{info.label or info.stage.name}()"

    def _bind_routes(
        self,
        step: Step,
        info: _WorkInfo,
        args: tuple[object, ...],
        kwargs: dict[str, object],
    ) -> None:
        """Bind routed inputs and constexpr arguments to ``step``.

        ``info`` partitions arguments into two kinds:

        - **Routed (data-flow) inputs** (``info.routed_names``) bind by token
          identity.  A token may be passed positionally for a parameter declared
          *positional-or-keyword* (bound by slot order against
          ``info.routed_positional_names``) or by keyword as ``argument=token``;
          a keyword-only input must use the keyword form. Each one records the
          source variable in this step's ``input_bindings`` map.
        - **Constexpr params** (``info.constexpr_names``) are compile-time
          literals captured on ``step.constexpr_kwargs`` and forwarded to the
          work body. Parameters listed in ``info.required_constexpr_names``
          require explicit values.

        ``state=`` is reserved for a :class:`PipelineStateRef` cursor and is
        stripped before this partition; it is not a work argument.

        Raises :class:`ScheduleError` for invalid binding cardinality, duplicate
        bindings, missing routed or required constexpr arguments, unknown
        arguments, non-routable or stale tokens, and non-literal constexpr
        values.
        """
        site = self._site(info)

        # ``state=`` is the scheduler cursor, not a routed/constexpr work arg.
        work_kwargs = dict(kwargs)
        cursor = work_kwargs.get("state")
        if isinstance(cursor, PipelineStateRef) or (
            "state" in work_kwargs and cursor is None
        ):
            del work_kwargs["state"]

        # Merge positional and keyword bindings; handled entries are consumed.
        positional = info.routed_positional_names
        if len(args) > len(positional):
            allowed = ", ".join(positional) or "none"
            raise ScheduleError(
                f"{site} accepts at most {len(positional)} positional data-flow "
                f"input(s) ({allowed}); got {len(args)}. Pass keyword-only "
                "inputs as argument=token."
            )
        bound: dict[str, object] = dict(zip(positional, args))
        for argument, value in work_kwargs.items():
            if argument in bound:
                raise ScheduleError(
                    f"{site} got multiple values for input {argument!r} (passed "
                    "both positionally and by keyword)."
                )
            bound[argument] = value

        # Bind routed inputs in declaration order.
        for argument in info.routed_names:
            if argument not in bound:
                raise ScheduleError(
                    f"{site} is missing routed input {argument!r}; pass it as a "
                    "positional token or argument=token."
                )
            token = self._validate_routed_token(info, argument, bound.pop(argument))
            # Routed-token validation guarantees a task-local variable.
            assert token.variable is not None
            # Record the destination binding to the logical source variable.
            step.input_bindings[argument] = token.variable

        # Capture constexpr arguments.
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

        # Remaining bindings name no declared parameter.
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
        """Return authoritative tokens for the variables ``step`` produces.

        ``step.returned_variables`` records the produced variables for routing
        and unconsumed-output diagnostics.
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
    """Require a callable bound to be an unbound ``(self, coord)`` Task method."""
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
    *,
    verify_num_fires: int | None = None,
) -> Iterator[None]:
    """Open a :class:`ConditionalBlock` with ``condition`` on enter, close it on exit."""
    node = ConditionalBlock(
        body=[], condition=condition, verify_num_fires=verify_num_fires
    )
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


class WhileTrueLoopProxy:
    """Yielded by while_true_loop(); records dynamic-loop break points."""

    def __init__(self, builder: ScheduleBuilder, loop: WhileTrueLoop) -> None:
        self._builder = builder
        self._loop = loop

    def break_loop(self) -> None:
        self._check_active("break_loop")
        self._builder.record_loop_break(self._loop)

    def _check_active(self, api: str) -> None:
        if not self._builder.is_scope_open(self._loop):
            raise ScheduleError(
                f"{api}() was called on a while_true_loop() handle whose block has "
                "already exited; it is only valid inside the with-block of the "
                "loop that produced the handle."
            )


class DomainLoopProxy:
    """Yielded by domain_loop(); opens per-iteration condition blocks.

    Each proxy is valid while its associated :class:`DomainLoop` is open.
    ``first_iter()`` / ``last_iter()`` / ``every()`` reject an expired proxy.
    """

    def __init__(self, builder: ScheduleBuilder, loop: DomainLoop) -> None:
        self._builder = builder
        self._loop = loop

    def first_iter(self) -> AbstractContextManager[None]:
        self._check_active("first_iter")
        return _IterationBlockContext(FIRST_ITER, "first_iter")

    def last_iter(self) -> AbstractContextManager[None]:
        self._check_active("last_iter")
        return _IterationBlockContext(LAST_ITER, "last_iter")

    def every(self, period: int, *, start: int = 0) -> AbstractContextManager[None]:
        self._check_active("every")
        return _IterationBlockContext(Every(period=period, start=start), "every")

    @property
    def first(self) -> IterationPredicate:
        self._check_active("first")
        return FIRST_ITER

    @property
    def last(self) -> IterationPredicate:
        self._check_active("last")
        return LAST_ITER

    def every_pred(self, period: int, *, start: int = 0) -> IterationPredicate:
        self._check_active("every_pred")
        return Every(period=period, start=start)

    def _check_active(self, api: str) -> None:
        if not self._builder.is_scope_open(self._loop):
            raise ScheduleError(
                f"{api}() was called on a domain_loop() handle whose block has "
                "already exited; per-iteration conditions are only valid inside the "
                "with-block of the loop that produced the handle."
            )


class _IterationBlockContext(AbstractContextManager[None]):
    """Context-manager spelling of a predicate, never a boolean operand."""

    def __init__(self, predicate: IterationPredicate, api: str) -> None:
        self._context = when_true(predicate)
        self._api = api

    def __enter__(self) -> None:
        return self._context.__enter__()

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: TracebackType | None,
    ) -> bool | None:
        return self._context.__exit__(exc_type, exc_value, traceback)

    def _operand_error(self) -> NoReturn:
        raise ScheduleError(
            f"d.{self._api}() is a context manager, not a condition operand; "
            "use d.first / d.last / d.every_pred(...), or FIRST_ITER / LAST_ITER."
        )

    def __and__(self, _other: object) -> NoReturn:
        self._operand_error()

    def __rand__(self, _other: object) -> NoReturn:
        self._operand_error()

    def __or__(self, _other: object) -> NoReturn:
        self._operand_error()

    def __ror__(self, _other: object) -> NoReturn:
        self._operand_error()

    def __invert__(self) -> NoReturn:
        self._operand_error()

    def __bool__(self) -> NoReturn:
        self._operand_error()


def _check_skip_predicate(skip_if: object, work_queue: WorkQueue) -> None:
    """Validate a ``work_tile_loop(skip_if=...)`` predicate.

    ``skip_if`` may be a plain ``(work_queue, work_tile)`` function/lambda or a
    method of ``work_queue``'s class. Methods must belong to the loop's
    WorkQueue type. Raises :class:`ScheduleError` for a non-callable predicate
    or a method associated with another WorkQueue.
    """
    if not callable(skip_if):
        raise ScheduleError("work_tile_loop(skip_if=...) must be callable.")

    # Bound methods carry the WorkQueue instance in ``__self__``.
    bound_self = getattr(skip_if, "__self__", None)
    if isinstance(bound_self, WorkQueue) and bound_self is not work_queue:
        raise ScheduleError(
            "work_tile_loop(skip_if=...) is bound to a different WorkQueue "
            f"({type(bound_self).__name__}) than the loop's "
            f"{type(work_queue).__name__}."
        )

    # An unbound WorkQueue method is identified by its class-qualified name.
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


def _normalize_verify_num_iters(
    verify_num_iters: int | tuple[int, ...] | None,
) -> tuple[int, ...]:
    """Normalize ``verify_num_iters`` to a non-empty tuple of positive ints.

    ``None`` defaults to ``(1, 2)``: an immediate-break iteration and one
    retry followed by break.
    """
    if verify_num_iters is None:
        return (1, 2)
    if type(verify_num_iters) is int:
        if verify_num_iters <= 0:
            raise ScheduleError("while_true_loop() verify_num_iters must be positive.")
        return (verify_num_iters,)
    if isinstance(verify_num_iters, tuple):
        if not verify_num_iters:
            raise ScheduleError(
                "while_true_loop() verify_num_iters tuple must be non-empty."
            )
        counts: list[int] = []
        for count in verify_num_iters:
            if type(count) is not int or count <= 0:
                raise ScheduleError(
                    "while_true_loop() verify_num_iters must contain only "
                    "positive compile-time ints."
                )
            counts.append(count)
        return tuple(counts)
    raise ScheduleError(
        "while_true_loop() verify_num_iters must be a compile-time int, "
        "a tuple of ints, or None."
    )


def _resolve_while_true_loop_hook(
    builder: ScheduleBuilder, api: str, hook: object
) -> LoopHook:
    resource = getattr(hook, "_ts_loop_hook_resource", None)
    info = getattr(hook, "_ts_loop_hook_info", None)
    if not isinstance(resource, MemoryResource) or not isinstance(info, _WorkInfo):
        raise ScheduleError(
            f"while_true_loop() {api}= must be a traced resource work method such as "
            f"`smem.{api}_loop`; got {type(hook).__name__}."
        )
    if info.stage not in (ScheduleStage.ConsumerAuxWork, ScheduleStage.ConsumerWork):
        raise ScheduleError(
            f"while_true_loop() {api}= must name a consumer work method that returns "
            "the loop offset/state."
        )
    if info.label is None:
        raise ScheduleError(
            f"while_true_loop() {api}= must name a registered work method."
        )
    if len(info.returned_variables) != 1:
        raise ScheduleError(
            f"while_true_loop() {api}= must return exactly one TaskLocalVariable."
        )
    result_name = info.returned_variables[0].slot_name
    if result_name is None:
        raise ScheduleError(
            f"while_true_loop() {api}= returned variable must be named."
        )
    return LoopHook(
        resource=resource,
        schedule_stage=info.stage,
        label=info.label,
        result_name=result_name,
        step=builder.allocate_step(resource, info),
    )


@contextmanager
def while_true_loop(
    *,
    init: Callable[..., object],
    advance: Callable[..., object],
    verify_num_iters: int | tuple[int, ...] | None = None,
) -> Iterator[WhileTrueLoopProxy]:
    """Open a dynamic while loop with explicit init/advance hooks.

    The loop exits as soon as any recorded ``break_loop()`` clause holds.  Each
    clause is the conjunction of opaque guards that dominate that call; later
    entries in the breaking iteration do not execute.
    ``verify_num_iters`` selects the modeled iteration counts: an ``int``
    ``N`` checks ``retry^(N-1) + break``; a tuple checks each count; ``None``
    defaults to ``(1, 2)``.
    """
    builder = _require_active_builder("while_true_loop()")
    node = WhileTrueLoop(
        init=_resolve_while_true_loop_hook(builder, "init", init),
        advance=_resolve_while_true_loop_hook(builder, "advance", advance),
        verify_num_iters=_normalize_verify_num_iters(verify_num_iters),
        body=[],
    )
    builder.open_scope(node)
    try:
        yield WhileTrueLoopProxy(builder, node)
    finally:
        builder.close_scope(node)


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
    **Any** bound may be dynamic. Pass a ``Task`` subclass method accessed on
    the class, such as ``MyTask.get_domain``; it must retain the explicit
    ``(self, work_tile_coord)`` parameters used to resolve the current tile's
    bound.

    Parameters
    ----------
    *bounds : int, DSL value, or callable
        One to three range-style bounds.
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


def schedule(
    fn: Callable[..., None] | None = None, *, manual_state: bool = False
) -> Callable[..., Schedule] | Callable[[Callable[..., None]], Callable[..., Schedule]]:
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
    ``MemoryResource``. Proxy method calls record schedule entries and routing
    edges. Schedule functions are trace-time metaprograms: Python runs once to
    record work that executes later. ``domain_loop`` and ``work_tile_loop``
    record runtime loops, but each ``with`` body is traced once.

    Ordinary Python variables have no runtime storage in the recorded schedule,
    so assignment cannot carry state between runtime iterations::

        x = 0
        with domain_loop(0, 4, 1):
            x = x + 1

    The assignment runs once while tracing. It records no runtime update.

    The only supported way to preserve a value between runtime loop iterations
    is to use one ``TaskLocalVariable``. The method that creates the initial
    value and every method that updates it must name the same slot in
    ``@consumer_work(returns=...)``. This belongs on the decorator, not the
    method call. For example, assume ``compute_coords()`` and
    ``advance_coords()`` both use
    ``@consumer_work(returns=coord_slot)``::

        coord = gmem.compute_coords()
        with domain_loop(0, num_tiles, 1):
            smem.tma_load(coord=coord)
            coord = gmem.advance_coords(coord)

    The slot identifies runtime storage: ``compute_coords()`` initializes it,
    and ``advance_coords()`` writes the value for the next iteration. The
    Python name ``coord`` is only a trace-time reference to that slot.
    """

    if fn is None:

        def decorator(decorated: Callable[..., None]) -> Callable[..., Schedule]:
            return cast(
                Callable[..., Schedule],
                schedule(decorated, manual_state=manual_state),
            )

        return decorator
    if type(manual_state) is not bool:
        raise TypeError(
            f"schedule(manual_state=...) must be bool, got "
            f"{type(manual_state).__name__}."
        )

    @functools.wraps(fn)
    def traced(*resources: object) -> Schedule:
        from .pipeline_group import _GroupMemberRef

        members: list[MemoryResource] = []
        for resource in resources:
            if isinstance(resource, _GroupMemberRef):
                # The member retains its PipelineGroup identity after unwrapping.
                members.append(resource.member)
            elif isinstance(resource, MemoryResource):
                # Grouped resources require an explicit ``group.member`` identity.
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
        builder = ScheduleBuilder(
            name=fn.__name__, resources=members, manual_state=manual_state
        )
        proxies = [ResourceProxy(member, builder) for member in members]
        token = _active_builder.set(builder)
        try:
            fn(*proxies)
        finally:
            _active_builder.reset(token)
        return builder.finalize()

    return traced
