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

"""Exhaustive interleaving checker for TS schedules.

Explores **all** valid interleavings of schedule operations across
concurrent tasks using BFS, detecting deadlocks, race conditions, and
PDL launch-before-wait order violations.

GPU hardware can execute warp-specialized tasks in any order.  If *any*
valid interleaving deadlocks or races, the schedule is unsafe.

Enabled by default in ``TaskManager``.  Disable via
``TaskManager(exhaustive_deadlock_race_check=False)`` for large schedules.
For skip-enabled work-tile schedules, ``TaskManager`` runs this checker
once on normal tile execution and once on skipped-tile execution.

Algorithm
---------
Synchronization is modelled as **mbarrier phases**.  Every
pipelined resource owns, per physical ring stage, a *full* barrier and an
*empty* barrier.  Each barrier holds a phase bit plus a pending arrival
count, and flips its phase once the arrival count reaches the number of
participants the schedule declares for that side.

A waiter compares the barrier phase against the phase its own software
cursor names::

    wait succeeds  <=>  barrier.phase != cursor.phase

Empty barriers start at phase ``1`` and full barriers at phase ``0``, while
every software cursor starts at phase ``0``.  The first ``num_stages``
producer acquires therefore pass immediately and the first consumer wait
blocks until the producer side completes the stage — the same slack the
hardware ring provides.

Software cursors are minted per schedule builder, so they are task-local:
every mutation of a cursor sits in that task's own schedule in a fixed
order, which makes each step's ``(index, phase, count)`` a pure function of
that task's position.  :func:`~.task_manager._simulate_cursors` resolves
them once per expansion and stamps ``FlatScheduleOp.cursor_state``, so
``advance(n)``, ``previous()`` and ``state.at(k)`` all reach the phase
compare with the stage and phase the schedule actually names.  Because a
``StateAdvance`` node mutates nothing that another task can observe, it
is dropped from the explored timeline rather than interleaved.

Barrier state, by contrast, is shared, so it lives in the BFS state and in
the default visited key.  The same task cursors can be reached with different
pending arrivals when independent tasks release or commit in different orders,
so pruning only by cursor positions can drop the path that completes the
handshake — see :func:`check_all_interleavings`.

At each state the checker:

1. Computes which tasks are **enabled**.  ``ConsumerWait`` compares the full
   barrier phase and ``ProducerAcquire`` compares the empty barrier phase.
   Everything else is always enabled.
2. If no task is enabled and work remains → **deadlock**.
3. Checks enabled PDL launch ops against the already-executed prefix; a
   launch is unsafe if no task has executed a PDL wait yet.
4. Checks held-resource windows and next point-access ops for aliasing
   **races** (conflicting concurrent accesses to shared physical storage).
5. For each enabled task, advances its cursor by one step, applies the
   barrier and held-state transitions, and enqueues the successor.

Which op arrives on the full barrier depends on the pipeline type.  For
``PipelineAsync``-style pipelines ``producer_commit`` issues the arrive, so
the checker counts the arrival there.  For producer types whose
``producer_commit`` is a no-op because the transfer's own transaction count
completes the barrier, the arrival is counted at the transfer instead, on the
last ``ProducerWork`` of that round.  A round whose commit is not
preceded by producer work on the same resource keeps the arrival on the
commit; that is the group-level commit shape, where the transfers are
issued on the members.  A ``ProducerAcquire`` also closes any transfer group
left open on that stage, and every group's last transfer arrives.

``PipelineGroup`` fork/merge is "one op arrives on several barriers":
a fork ``ProducerCommit`` arrives on every member's full barrier and a
merge ``ConsumerRelease`` on every member's empty barrier.  A
``FusedMerge`` group owns one shared full barrier that every member's
transfer arrives on.

Round counts have to agree across tasks for arrival counts to balance.  Each
loop kind is modelled on its own terms: a ``domain_loop`` over its folded
trip count, a ``while_true_loop`` over ``verify_num_iters``.  The checker
does not reconcile the two.  A ``verify_num_iters`` that does not match the
rounds its partner tasks drive therefore reports a deadlock, and the fix is
to pick a ``verify_num_iters`` that models the loop faithfully — a count the
schedule author knows and the checker cannot infer.

A while loop's *exit* is opaque in the same way, and worse: it is enumerated
per round, so the loop is modelled as exiting after any number of rounds.
When the exit tests a counter the loop body feeds — the Rubin retry loop
exits once ``valid_tile_count`` reaches the row count — almost every one of
those exits is unreachable, and each unreachable one strands the partner
tasks and reports a deadlock.  ``when_true(..., verify_num_fires=N)`` is how
the author closes that gap: it declares that the hinted block runs on
exactly ``N`` of the modelled rounds, and round sequences that disagree are
dropped before the BFS ever sees them (:func:`collect_fire_count_hints`).  A
hint that cannot be met over ``verify_num_iters`` rounds is an error, not a
silently empty search.  Failures reported for a loop whose exit is still
unconstrained carry :func:`while_loop_exit_caveat`, because they may be
artifacts of an exit the kernel cannot reach.

Counting rounds is not enough for a guard that decides *which* stage a round
works on.  The retry loop skips a stage whose logical row is past the end
(``current_stage_pending()`` is ``loop_offset < retry_tile_count``), and
enumerating that freely lets a sequence call the early stages inactive and
the late ones active — which slides every productive round onto a stage the
producer never filled, and reports the resulting unreleased stage as a
deadlock.  Such an output is a function of the cursor, so it comes with a
pure-Python replica declared as ``@consumer_work(verify_model=...)``; the
checker evaluates that against the cursor it already simulates and keeps
only the rounds where the enumerated value agrees
(:func:`collect_cursor_models`).  Unlike a fire-count hint this is a
recomputation rather than a count, so it also pins the round *positions*.

A round is enumerated over the guards it reads and no others
(:func:`_replay_round`).  A retry loop that sweeps several pipelines in
alternating phases reads one phase's probes per round, and enumerating the
idle phases as well would multiply the round classes by their outcomes --
each product being a separate BFS over the whole kernel.

Ownership/access model
----------------------
Race detection tracks four stored per-resource states:

- **prod_held** — producer owns the slot, but has not touched memory yet.
- **prod** — producer has written data or is in a producer-side work window.
- **cons_held** — consumer owns the slot after ``CWait``.
- **cons** — consumer is reading, or a DMA consumer read is still live.

``nothing`` is represented by the absence of an entry.  ``prod_held`` is
a reservation marker, not a physical memory access.  A **race** is flagged
when two aliased resources both have stored/access states, neither side is
``prod_held``, and at least one side is producer work (``prod``)::

              nothing  prod_held  prod  cons_held  cons
    nothing      no       no       no      no       no
    prod_held    no       no       no      no       no
    prod         no       no       yes     yes      yes
    cons_held    no       no       yes     no       no
    cons         no       no       yes     no       no

For pipelined resources these entries are also tagged with the pipeline
slot/stage.  Work-level entries on different real slots are independent and
do not race; slotless resources are treated as overlapping every slot.

Pipeline ownership transitions:

- ``ProducerAcquire`` creates ``prod_held``.
- ``ProducerWork`` changes ``prod_held`` to ``prod``.
- ``ConsumerWait`` changes producer-side state to ``cons_held``.
- ``ConsumerWork`` changes ``cons_held`` to ``cons``.
- ``ConsumerRelease`` clears normal consumer state.

For **DMA consumer** pipelines (``TmaUmma``, ``AsyncUmma``,
``UmmaUmma``), ``cons`` persists past ``ConsumerRelease`` and is cleared
at whichever comes first:

  1. ``ConsumerWait(R)`` on a **paired UmmaAsync** resource
     (UMMA pairing — the hardware reads S while writing R, so
     ``CWait(R)`` guarantees S reads are complete).
  2. ``ProducerAcquire(R)`` implicitly closes the old hold (buffer
     reclaimed by producer).

Clearing at (1) is per **commit/wait generation**: a producer may commit
several times, each work encompassing a distinct set of reads.
``ProducerCommit(R)`` tags the reads preceding that commit; ``ConsumerWait(R)``
clears only the reads of the generation it observes, so it does not free reads
feeding a later commit it has not yet observed.

Non-atomic work modelling
~~~~~~~~~~~~~~~~~~~~~~~~~
A single ``ProducerWork`` or ``ConsumerWork`` call may consist of many
hardware instructions.  Another warp can interleave mid-call.  To
model this for **non-pipelined** resources, standalone work entries are
split or doubled before BFS exploration (see ``_explode_sync_work``).
Pipelined resources use their protocol ownership interval instead.

Role-specific aliasing
~~~~~~~~~~~~~~~~~~~~~~
Resources may have allocations in multiple address spaces (SMEM + TMEM).
The producer and consumer may access different subsets.  A resource can
declare which allocations each role accesses by overriding
``get_producer_requirements()`` and/or ``get_consumer_requirements()``
on ``MemoryResource``.  Each returns a mixed list of
``SmemAllocation`` / ``TmemAllocation`` objects, or ``None`` (default)
to mean "all allocations".
``build_alias_info`` builds three alias maps:

- **alias_map** — all-ranges × all-ranges (symmetric).  Used by the
  held-state tracker.
- **prod_alias_map** — producer-ranges × all-ranges.  Used for
  producer-side race checks.
- **cons_alias_map** — consumer-ranges × all-ranges.  Used for
  consumer-side race checks.

A race between resources A and B is only flagged when **both** sides
confirm the overlap through their respective role alias maps.
"""

import itertools
import warnings
from collections import deque
from dataclasses import dataclass, field, replace
from typing import (
    Callable,
    Dict,
    Hashable,
    Iterable,
    Iterator,
    List,
    Optional,
    Set,
    Tuple,
    cast,
)

from typing_extensions import assert_never

from .enums import (
    BlockGuard,
    Every,
    FIRST_ITER,
    GuardAnd,
    GuardOr,
    LAST_ITER,
    OpaqueCondition,
    PipelineGroupMode,
    PipelineType,
    SKIPPABLE,
    ScheduleStage,
    guard_fires,
    iter_leaves,
)
from .resources import (
    MemoryResource,
    PdlLaunchBarrier,
    PdlWaitBarrier,
    PipelineConfig,
    WorkQueue,
    verify_model_for,
)
from .pipeline_group import PipelineGroup
from .task import Task
from .schedule_builder import (
    ConditionalBlock,
    DomainLoop,
    LoopBreak,
    PipelineStateRef,
    ScheduleError,
    StateAdvance,
    Step,
    WhileTrueLoop,
    WorkTileLoop,
    _format_block_guard,
    _iter_nodes,
)
from .task_manager import (
    _count_independent_interleave_lane,
    _domain_interleaved_resource_ids,
    _opaque_assignments,
    _simulate_cursors,
)

# Pipeline types whose consumer completes asynchronously.  For these
# pipelines memory remains in use past ConsumerRelease — the actual
# release happens implicitly at the next ProducerAcquire, or at a paired
# completion wait.
_DMA_CONSUMER_TYPES = frozenset(
    {
        PipelineType.TmaUmma,
        PipelineType.AsyncUmma,
        PipelineType.UmmaUmma,
    }
)

_SLOTLESS = -1
_UNTAGGED = -1

# Pipeline types whose ``producer_commit`` is a no-op because the producer's
# own transfer completes the full barrier's transaction count.  For these the
# checker counts the full-barrier arrival on the transfer (``ProducerWork``)
# instead of on the commit.  Every other type arrives in ``producer_commit``
# (``sync_object_full.arrive``).
_TRANSFER_COMPLETES_FULL = frozenset(
    {
        PipelineType.TmaAsync,
        PipelineType.TmaUmma,
        PipelineType.ClcFetchAsync,
    }
)

# The ops that arm a stage's full barrier, and therefore begin a new group of
# transfers into it.  Used to close the previous group when no
# ``ProducerCommit`` does, which is the V1 reissue shape.
_ARMS_FULL_BARRIER = frozenset(
    {
        ScheduleStage.ProducerAcquire,
    }
)

HeldEntry = Tuple[str, int, int, int]
HeldMap = Dict[int, List[HeldEntry]]
PointAccess = Tuple[int, int, str, int]

# ── Barrier state vector ────────────────────────────────────────────────
#
# One record per ``(barrier owner, physical stage)``, flattened into a single
# tuple of ints so a successor state is one tuple copy.  ``barrier owner`` is
# the resource itself, except for the shared full barrier of a ``FusedMerge``
# group, which is owned by the group (see :func:`_full_barrier_owner`).  The
# full fields are read at the owner's slot; the empty and window fields are
# always read at the resource's own slot, because arming and empty-barrier
# signalling stay per-resource even when the full barrier is shared.
_B_FULL_PHASE = 0
_B_FULL_ARRIVALS = 1
_B_EMPTY_PHASE = 2
_B_EMPTY_ARRIVALS = 3
_BARRIER_FIELDS = 4

# What has to become true before a step can execute.  Every gate is a phase
# compare between a barrier field and the phase the step's software cursor
# names; they differ only in which field is read.
_GATE_NONE = 0
_GATE_FULL = 1  # ConsumerWait
_GATE_EMPTY = 2  # ProducerAcquire
_GATE_FIELD = {
    _GATE_FULL: _B_FULL_PHASE,
    _GATE_EMPTY: _B_EMPTY_PHASE,
}

BarrierTuple = Tuple[int, ...]


@dataclass(frozen=True)
class FlatScheduleOp:
    """One barrier/work op in a flattened schedule timeline.

    Produced by :func:`expand_task` for the credit simulator, schedule
    printer, and exhaustive BFS.  ``domain_start`` / ``domain_end`` /
    ``domain_step`` are the enclosing :class:`DomainLoop` bounds (``None``
    outside any domain loop).  ``domain_entry`` numbers that loop's entry
    within this expansion, so ops from two entries of the same or equally
    bounded loops -- successive loops, or one loop re-entered per work tile
    -- stay distinguishable (``None`` outside any domain loop).
    ``sync_phase`` is set by :func:`_explode_sync_work` when non-pipelined
    ``ConsumerWork`` is split into synthetic write/read phases.

    """

    resource: MemoryResource
    schedule_stage: ScheduleStage | None
    unique_id: int
    phase: str
    state_binding: PipelineStateRef | None = None
    state_advance: StateAdvance | None = None
    cursor_state: Tuple[int, int, int] | None = None
    domain_start: object | None = None
    domain_end: object | None = None
    domain_step: object | None = None
    domain_entry: int | None = None
    domain_iteration: int | None = None
    sync_phase: str | None = None


OpaqueAssignment = dict[object, bool]
OpaqueAssignmentSequence = list[OpaqueAssignment]


@dataclass(frozen=True)
class OpaqueAssignmentScenario:
    """Per-task opaque assignments for a joint interleaving check.

    Tasks that contain a ``while_true_loop`` receive an assignment
    *sequence* (one dict per modeled iteration).  Partner tasks without a
    while loop receive ``default_assignment``, which is the last (break)
    assignment of the first while-loop task so they observe exit-iteration
    effects.
    """

    default_assignment: OpaqueAssignment
    task_assignments: dict[int, OpaqueAssignment | OpaqueAssignmentSequence]
    task_names: dict[int, str] = field(default_factory=dict)

    def for_task(self, task: Task) -> OpaqueAssignment | OpaqueAssignmentSequence:
        """Return the assignment or sequence recorded for ``task``."""
        return self.task_assignments.get(id(task), self.default_assignment)


OpaqueAssignmentLike = (
    OpaqueAssignment | OpaqueAssignmentSequence | OpaqueAssignmentScenario | None
)

# Pipeline stages that count as retry-iteration progress.  Auxiliary work
# (including ``should_exit`` probes) is excluded: a spinning retry that only
# polls a predicate does not make progress.
_WHILE_RETRY_PROGRESS_STAGES = frozenset(
    {
        ScheduleStage.ProducerTryAcquire,
        ScheduleStage.ProducerAcquire,
        ScheduleStage.ProducerCommit,
        ScheduleStage.ProducerWork,
        ScheduleStage.ConsumerTryWait,
        ScheduleStage.ConsumerWait,
        ScheduleStage.ConsumerRelease,
        ScheduleStage.ConsumerWork,
    }
)


def _keep_bfs_entry(entry: FlatScheduleOp) -> bool:
    """Keep the ops the BFS has to interleave.

    A schedule node earns a place in the timeline by being able to block or by
    having an effect or a check the checker applies to shared state.  Barrier
    and work ops always qualify.

    ``advance()`` and ``next()`` do not.  They move a software cursor, which is
    minted per schedule builder and therefore task-local: no other task can
    observe the write, and nothing gates on it.  Their effect is not lost —
    :func:`~.task_manager._simulate_cursors` has already resolved it into the
    ``(stage, phase)`` every later step on that resource carries, so a
    misplaced ``advance()`` still shows up as a later op naming the wrong
    stage or comparing the wrong phase.  Interleaving the node itself would
    only add states whose shared component is identical to the state before
    it, so dropping it is exact rather than approximate.  The cost is that a
    verbose timeline does not list the cursor moves.
    """
    return entry.schedule_stage is not None


def _full_barrier_owner(res: MemoryResource) -> int:
    """Id of the object owning the full barrier ``res``'s producer signals.

    This is the resource itself except for a member of a ``FusedMerge`` group,
    whose members share one full barrier held by the group.  A member's
    transfer and the group's ``ConsumerWait`` then resolve to the same owner
    and therefore to the same barrier record, which is what makes the fused
    wait see both members' arrivals.

    The empty barrier is never shared this way — each member is acquired and
    released on its own — so it always sits at ``id(res)``.
    """
    pg = getattr(res, "pipeline_group", None)
    if pg is not None and pg.mode == PipelineGroupMode.FusedMerge:
        return id(pg)
    return id(res)


def _commits_at_group_level(res: MemoryResource) -> bool:
    """Return whether ``res``'s full-barrier signal is emitted on its group.

    A ``Fork`` group owns the signal: the schedule emits one
    ``ProducerCommit`` on the group and it arrives on every member's full
    barrier, so a member's own transfer must not arrive a second time.
    """
    pg = getattr(res, "pipeline_group", None)
    return pg is not None and pg.mode == PipelineGroupMode.Fork


def _fallback_domain_cursor(
    entry: "FlatScheduleOp",
    cfg: PipelineConfig,
) -> Tuple[int, int, int]:
    """Infer a ring cursor for legacy entries without usable explicit state."""
    num_stages = cfg.num_stages
    iteration = entry.domain_iteration or 0
    return (
        iteration % num_stages,
        (iteration // num_stages) % 2,
        iteration,
    )


def _step_cursor_state(entry: "FlatScheduleOp") -> Tuple[int, int, int] | None:
    """Return the cursor state the barrier checker should use for ``entry``."""
    res = entry.resource
    cfg = res.pipeline_config
    if cfg is None:
        return None
    pg = getattr(res, "pipeline_group", None)
    if (
        pg is not None
        and pg.mode == PipelineGroupMode.Fork
        and entry.schedule_stage
        in {
            ScheduleStage.ProducerAcquire,
            ScheduleStage.ProducerWork,
            ScheduleStage.ProducerCommit,
        }
    ):
        return _fallback_domain_cursor(entry, cfg)
    if entry.cursor_state is not None:
        return entry.cursor_state
    return _fallback_domain_cursor(entry, cfg)


def _barrier_layout(
    resources: List[MemoryResource],
    schedules: List[List[FlatScheduleOp]],
) -> Tuple[Dict[int, int], BarrierTuple]:
    """Assign a dense record to every ``(barrier owner, physical stage)``.

    Returns the per-owner base offset and the initial barrier vector.  Empty
    barriers start at phase ``1`` and full barriers at phase ``0`` so that,
    against software cursors that all start at phase ``0``, the first
    ``num_stages`` producer acquires pass and the first consumer wait blocks.

    Owners are the pipelined resources plus every ``PipelineGroup`` a schedule
    names, since a group carries its own merged ``pipeline_config`` and, in
    ``FusedMerge`` mode, its own full barrier.
    """
    owners: List[MemoryResource] = []
    seen: Set[int] = set()

    def add(candidate: MemoryResource) -> None:
        if candidate.pipeline_config is None or isinstance(candidate, WorkQueue):
            return
        if id(candidate) in seen:
            return
        seen.add(id(candidate))
        owners.append(candidate)

    for res in resources:
        add(res)
    for sched in schedules:
        for entry in sched:
            add(entry.resource)
            if isinstance(entry.resource, PipelineGroup):
                for member in entry.resource.members:
                    add(member)

    offsets: Dict[int, int] = {}
    initial: List[int] = []
    for owner in owners:
        cfg = owner.pipeline_config
        assert cfg is not None
        offsets[id(owner)] = len(initial) // _BARRIER_FIELDS
        for _ in range(cfg.num_stages):
            record = [0] * _BARRIER_FIELDS
            record[_B_EMPTY_PHASE] = 1
            initial.extend(record)
    return offsets, tuple(initial)


# Pipeline stages that count as retry-iteration progress.  Auxiliary work
# (including ``should_exit`` probes) is excluded: a spinning retry that only
# polls a predicate does not make progress.
_WHILE_RETRY_PROGRESS_STAGES = frozenset(
    {
        ScheduleStage.ProducerTryAcquire,
        ScheduleStage.ProducerAcquire,
        ScheduleStage.ProducerCommit,
        ScheduleStage.ProducerWork,
        ScheduleStage.ConsumerTryWait,
        ScheduleStage.ConsumerWait,
        ScheduleStage.ConsumerRelease,
        ScheduleStage.ConsumerWork,
    }
)


def _is_dma_consumer_resource(res: MemoryResource) -> bool:
    """Return True for resources whose consumer completion is asynchronous."""
    return (
        res.pipeline_config is not None
        and res.pipeline_config.pipeline_type in _DMA_CONSUMER_TYPES
    )


def _is_completion_producer_resource(res: MemoryResource) -> bool:
    """Return True when waiting on this resource proves paired reads complete."""
    return res.pipeline_config is not None and res.pipeline_config.pipeline_type in {
        PipelineType.UmmaAsync,
        PipelineType.UmmaUmma,
    }


def _consumer_work_phase_entries(entry: FlatScheduleOp) -> List[FlatScheduleOp]:
    """Split slotless ConsumerWork into conservative write/read phases."""
    res, stage = entry.resource, entry.schedule_stage
    if (
        not res.is_barrier
        and stage == ScheduleStage.ConsumerWork
        and res.pipeline_config is None
    ):
        return [
            replace(entry, sync_phase="cons_write_phase"),
            replace(entry, sync_phase="cons_read_phase"),
        ]
    return [entry]


def _should_double_nonpipeline_producer_work(
    res: MemoryResource,
    stage: ScheduleStage,
) -> bool:
    """Return True when standalone producer work needs an active window."""
    return (
        not res.is_barrier
        and res.pipeline_config is None
        and stage == ScheduleStage.ProducerWork
    )


def _explode_sync_work(schedules: List[list]) -> List[list]:
    """Expand non-pipelined work steps to model non-atomic physical access.

    A single ``ProducerWork`` or ``ConsumerWork`` may consist of many
    instructions.  Pipelined resources use the acquire/wait/release
    protocol to keep ownership visible across BFS states.  Non-pipelined
    work has no such protocol interval, so the checker creates a small
    synthetic active window.

    ``ConsumerWork`` on resources **without a pipeline config** is
    conservatively split into write/read phases to model hidden
    read-modify-write patterns inside one work call:

    - ``cons_write_phase`` — conservative write-capable phase.
    - ``cons_read_phase`` — read phase.

    ``ProducerWork`` on resources without a pipeline config is doubled
    so producer-side access remains visible across one interleaving point.
    """
    result = []
    for sched in schedules:
        new_sched: list = []
        for entry in sched:
            res, stage = entry.resource, entry.schedule_stage
            phase_entries = _consumer_work_phase_entries(entry)
            new_sched.extend(phase_entries)
            if len(phase_entries) > 1:
                continue

            if _should_double_nonpipeline_producer_work(res, stage):
                new_sched.append(entry)
        result.append(new_sched)
    return result


def _entry_consumer_work_phase(entry: FlatScheduleOp) -> str | None:
    """Return internal ConsumerWork phase tag, if present."""
    tag = entry.sync_phase
    if tag in {"cons_write_phase", "cons_read_phase"}:
        return tag
    return None


def _fold_domain_bound(
    bound: object, task: Task, name: str, *, warn: bool = True
) -> int | None:
    """Fold a ``DomainLoop`` bound to a compile-time int.

    Literal ints are returned as-is. Callables are invoked as
    ``bound(task, (0, 0, 0))`` on a representative work tile. Returns the
    value only when it is a plain ``int``; otherwise ``None`` so the caller
    uses the representative fallback.

    ``warn=False`` suppresses the diagnostic, reporting a bound that does not
    fold through the ``None`` return alone.
    """
    if isinstance(bound, int) and not isinstance(bound, bool):
        return bound
    if not callable(bound):
        if warn:
            warnings.warn(
                f"Task {getattr(task, 'name', '?')!r}: domain_loop {name} is not "
                "a compile-time int or callable; using the representative "
                "iteration-count fallback for schedule validation.",
                stacklevel=2,
            )
        return None
    validation_tile = (0, 0, 0)
    try:
        value = bound(task, validation_tile)
    except Exception:
        value = None
    if isinstance(value, int) and not isinstance(value, bool):
        return value
    if warn:
        warnings.warn(
            f"Task {getattr(task, 'name', '?')!r}: domain_loop {name} callable "
            "did not fold to a compile-time int; using the representative "
            "iteration-count fallback for schedule validation.",
            stacklevel=2,
        )
    return None


def _domain_loop_iters(
    node: DomainLoop,
    task: Task,
    dynamic_domain_fallback: int,
) -> int:
    """Representative unroll count for one ``DomainLoop``.

    Bounds fold to compile-time ints from literals, or from callables probed on
    a representative all-zero work tile.  When every bound folds, the count is
    ``len(range(start, end, step))``.

    ``dynamic_domain_fallback`` is a representative *end* bound: one past the
    largest static ``domain_loop`` start in the kernel.  Substituting it for an
    unfoldable end preserves the relative trip counts of loops that begin at
    different offsets, so a loop peeled to start at 1 runs one iteration fewer
    than the loader it consumes from.  That relationship is what keeps producer
    commits balanced against consumer waits.  Loops with an unfoldable end
    always run at least once.

    A folded ``step`` must be positive.
    """
    start = _fold_domain_bound(node.start, task, "start")
    end = _fold_domain_bound(node.end, task, "end")
    step = _fold_domain_bound(node.step, task, "step")
    if step is not None and step <= 0:
        raise ScheduleError(
            f"Task {getattr(task, 'name', '?')!r}: domain_loop() step must be "
            f"a positive int, got {step}."
        )
    if start is None or step is None:
        count = max(1, dynamic_domain_fallback)
    else:
        if end is None:
            end = max(dynamic_domain_fallback, start + step)
        count = len(range(start, end, step))
    return count


def _emit_nodes(
    nodes: list,
    task: Task,
    opaque_assignment: dict | None,
    dynamic_domain_fallback: int,
    *,
    iter_index: int | None,
    iter_count: int | None,
    phase: str,
    skip: bool = False,
    num_tiles: int = 1,
    domain_start: object | None = None,
    domain_end: object | None = None,
    domain_step: object | None = None,
    domain_entry: int | None = None,
    entry_counter: Iterator[int],
    result: List,
    while_sequence: OpaqueAssignmentSequence | None = None,
    break_hits: list | None = None,
) -> None:
    """Append the ops for ``nodes`` in execution order.

    Each entry is a :class:`FlatScheduleOp`. ``phase`` is ``"O"`` outside any
    domain loop, ``""`` inside a plain ``DomainLoop`` body, or ``"F"`` / ``"L"``
    / ``"P"`` / ``"I"`` for a first-iter / last-iter / ``Every`` /
    opaque-guarded block (see :func:`_guard_phase`).

    ``iter_index`` / ``iter_count`` are set inside a ``DomainLoop`` or
    ``WhileTrueLoop`` body and ``None`` outside.  ``domain_start`` /
    ``domain_end`` / ``domain_step`` are the enclosing domain loop's bounds
    (``None`` outside any domain loop), and ``domain_entry`` is that loop
    entry's index, drawn from ``entry_counter`` once per ``DomainLoop`` visit --
    so a loop replayed per work tile draws a fresh index each time, matching
    the walker's per-entry lane reseed.

    ``num_tiles`` replays the ``WorkTileLoop`` body that many times, once per
    simulated work tile.  Steps outside the work-tile loop are emitted once, so
    per-tile bookkeeping repeats while a kernel-once prologue/epilogue does not.

    When ``skip`` is set the traversal models a skipped work tile (the walker's
    ``ctx.skip`` gate): ``DomainLoop`` / ``WhileTrueLoop`` bodies and
    ``skippable()`` regions are omitted.

    ``while_sequence`` is the modeled assignment list for an enclosing
    ``while_true_loop`` (one dict per iteration).  Init/advance hooks are not
    emitted.  ``LoopBreak`` is a marker, not a :class:`FlatScheduleOp`.
    """

    def recurse(
        body: list,
        *,
        assignment: dict | None = opaque_assignment,
        iter_index: int | None = iter_index,
        iter_count: int | None = iter_count,
        phase: str = phase,
        skip: bool = skip,
        num_tiles: int = num_tiles,
        domain_start: object | None = domain_start,
        domain_end: object | None = domain_end,
        domain_step: object | None = domain_step,
        domain_entry: int | None = domain_entry,
        while_sequence: OpaqueAssignmentSequence | None = while_sequence,
        break_hits: list | None = break_hits,
    ) -> None:
        _emit_nodes(
            body,
            task,
            assignment,
            dynamic_domain_fallback,
            iter_index=iter_index,
            iter_count=iter_count,
            phase=phase,
            skip=skip,
            num_tiles=num_tiles,
            domain_start=domain_start,
            domain_end=domain_end,
            domain_step=domain_step,
            domain_entry=domain_entry,
            entry_counter=entry_counter,
            result=result,
            while_sequence=while_sequence,
            break_hits=break_hits,
        )

    for node in nodes:
        if break_hits:
            break
        match node:
            case Step():
                result.append(
                    FlatScheduleOp(
                        resource=node.memory_resource,
                        schedule_stage=node.schedule_stage,
                        unique_id=node.unique_id,
                        phase=phase,
                        state_binding=node.state_binding,
                        domain_start=domain_start,
                        domain_end=domain_end,
                        domain_step=domain_step,
                        domain_entry=domain_entry,
                        domain_iteration=iter_index,
                    )
                )
            case StateAdvance():
                result.append(
                    FlatScheduleOp(
                        resource=node.state.resource,
                        schedule_stage=None,
                        unique_id=node.unique_id,
                        phase=phase,
                        state_advance=node,
                        domain_start=domain_start,
                        domain_end=domain_end,
                        domain_step=domain_step,
                        domain_entry=domain_entry,
                        domain_iteration=iter_index,
                    )
                )
            case LoopBreak():
                if break_hits is not None:
                    break_hits.append(True)
            case WorkTileLoop():
                # The persistent work-tile loop: replay its body once per
                # simulated work tile.  ``num_tiles`` resets to 1 inside the
                # body so the count applies to this loop alone.
                for _ in range(num_tiles):
                    recurse(node.body, num_tiles=1)
            case DomainLoop():
                if skip:
                    continue  # loop body omitted on a skipped tile
                iters = _domain_loop_iters(node, task, dynamic_domain_fallback)
                entry = next(entry_counter)
                for i in range(iters):
                    recurse(
                        node.body,
                        iter_index=i,
                        iter_count=iters,
                        phase="",
                        domain_start=node.start,
                        domain_end=node.end,
                        domain_step=node.step,
                        domain_entry=entry,
                    )
            case WhileTrueLoop():
                if skip:
                    continue
                sequence = while_sequence
                check_structure = sequence is not None
                if sequence is None:
                    sequence = [opaque_assignment or {}]
                if not sequence:
                    raise ValueError(
                        f"Task {getattr(task, 'name', '?')!r}: while_true_loop() "
                        "expansion received an empty assignment sequence."
                    )
                modeled = len(sequence)
                for i, assignment in enumerate(sequence):
                    hits: list = []
                    start = len(result)
                    recurse(
                        node.body,
                        assignment=assignment,
                        iter_index=i,
                        iter_count=modeled,
                        phase="",
                        while_sequence=None,
                        break_hits=hits,
                    )
                    if not check_structure:
                        continue
                    emitted = result[start:]
                    is_last = i == modeled - 1
                    if is_last:
                        if not hits:
                            raise ValueError(
                                f"Task {getattr(task, 'name', '?')!r}: "
                                f"while_true_loop last iteration {i} of "
                                f"{modeled} does not reach a break_loop()."
                            )
                    else:
                        if hits:
                            raise ValueError(
                                f"Task {getattr(task, 'name', '?')!r}: "
                                f"while_true_loop retry iteration {i} of "
                                f"{modeled} reaches break_loop()."
                            )
                        if not any(
                            op.schedule_stage in _WHILE_RETRY_PROGRESS_STAGES
                            for op in emitted
                        ):
                            raise ValueError(
                                f"Task {getattr(task, 'name', '?')!r}: "
                                f"while_true_loop retry iteration {i} of "
                                f"{modeled} has no blocking or state-changing "
                                "pipeline op "
                                f"(init={node.init.resource.name}."
                                f"{node.init.label})."
                            )
            case ConditionalBlock(condition=guard) if guard is SKIPPABLE:
                if skip:
                    continue
                recurse(node.body)
            case ConditionalBlock(condition=guard):
                # A non-skippable guard: an iteration predicate (always inside a
                # domain loop, so iter_index/iter_count are set) or an opaque
                # condition (which may sit outside any loop, where they are None;
                # guard_fires ignores iter_index/iter_count for opaque guards).
                if guard_fires(
                    guard,
                    iter_index if iter_index is not None else 0,
                    iter_count if iter_count is not None else 0,
                    opaque_assignment=opaque_assignment,
                ):
                    recurse(node.body, phase=_guard_phase(guard))
            case _:
                assert_never(node)


def _assignment_for_task(
    opaque_assignment: OpaqueAssignmentLike, task: Task
) -> OpaqueAssignment | OpaqueAssignmentSequence | None:
    """Unwrap a scenario (or pass through a dict / sequence) for one task."""
    if isinstance(opaque_assignment, OpaqueAssignmentScenario):
        return opaque_assignment.for_task(task)
    return opaque_assignment


def expand_task(
    task: Task,
    *,
    skipped_tile: bool = False,
    opaque_assignment: OpaqueAssignmentLike = None,
    num_tiles: int = 1,
    dynamic_domain_fallback: int = 1,
) -> List[FlatScheduleOp]:
    """Expand a task's schedule tree into execution-order :class:`FlatScheduleOp`s.

    ``phase`` is ``"O"`` outside any domain loop, ``""`` inside a plain
    domain-loop body, or ``"F"`` / ``"L"`` / ``"P"`` / ``"I"`` for a
    first-iter / last-iter / ``Every`` / opaque-guarded step (see
    :func:`_guard_phase`).  Domain-loop bounds travel on each op for
    per-loop lane identity, together with the entry index that separates one
    loop entry from the next; both are ``None`` outside a loop.

    The ``WorkTileLoop`` body is replayed ``num_tiles`` times; work outside it
    (prologue/epilogue) is emitted once.  On a skipped tile (``skipped_tile``
    with a ``skip_if`` loop), domain-loop bodies, ``while_true_loop`` bodies,
    and ``skippable()`` regions are omitted.

    ``opaque_assignment`` may be a single assignment dict, a while-loop
    assignment sequence, or an :class:`OpaqueAssignmentScenario`.  A sequence
    unrolls the ``while_true_loop`` once per modeled iteration; init/advance
    hooks are not emitted.  Partner-task opaque guards outside the while loop
    see the last (break) assignment of that sequence.
    """
    result: List[FlatScheduleOp] = []
    work_tile_loop = task._find_work_tile_loop()
    skip = bool(
        skipped_tile
        and work_tile_loop is not None
        and work_tile_loop.skip_if is not None
    )
    raw = _assignment_for_task(opaque_assignment, task)
    if isinstance(raw, list):
        outer: dict | None = raw[-1] if raw else {}
        sequence: OpaqueAssignmentSequence | None = raw
    else:
        outer = raw
        sequence = None
    _emit_nodes(
        task.schedule.body,
        task,
        outer,
        dynamic_domain_fallback,
        iter_index=None,
        iter_count=None,
        phase="O",
        skip=skip,
        num_tiles=num_tiles,
        entry_counter=itertools.count(),
        result=result,
        while_sequence=sequence,
    )
    return result


def _guard_phase(guard: object) -> str:
    if guard is FIRST_ITER:
        return "F"
    if guard is LAST_ITER:
        return "L"
    if isinstance(guard, Every):
        return "P"
    if isinstance(guard, OpaqueCondition):
        return "I"
    if isinstance(guard, (GuardAnd, GuardOr)):
        leaves = tuple(iter_leaves(guard))
        if any(isinstance(leaf, OpaqueCondition) for leaf in leaves):
            return "I"
        if any(leaf is FIRST_ITER for leaf in leaves):
            return "F"
        if any(leaf is LAST_ITER for leaf in leaves):
            return "L"
        if any(isinstance(leaf, Every) for leaf in leaves):
            return "P"
    return ""


def collect_opaque_keys(tasks: List[Task]) -> list:
    """Return distinct opaque correlation keys across all task schedule trees.

    Walks every conditional expression and collects opaque leaf keys once, in
    first-seen order. Tokens used only as routed data are not verifier keys.
    """
    keys: list = []
    seen: set = set()
    for task in tasks:
        for node in _iter_nodes(task.schedule.body):
            if isinstance(node, ConditionalBlock):
                for leaf in iter_leaves(node.condition):
                    if isinstance(leaf, OpaqueCondition) and leaf.key not in seen:
                        seen.add(leaf.key)
                        keys.append(leaf.key)
    return keys


def collect_guard_observations(
    tasks: List[Task],
) -> list[tuple[BlockGuard, int, int]]:
    """Collect each guard at every enclosing domain iteration it can observe."""
    observations: list[tuple[BlockGuard, int, int]] = []
    dynamic_fallback = dynamic_domain_fallback_for(tasks)

    for task in tasks:

        def walk(nodes: list, contexts: tuple[tuple[int, int], ...]) -> None:
            for node in nodes:
                if isinstance(node, (Step, StateAdvance, LoopBreak)):
                    continue
                if isinstance(node, DomainLoop):
                    count = _domain_loop_iters(node, task, dynamic_fallback)
                    walk(node.body, tuple((index, count) for index in range(count)))
                    continue
                if isinstance(node, ConditionalBlock):
                    if node.condition is not SKIPPABLE:
                        observations.extend(
                            (node.condition, index, count) for index, count in contexts
                        )
                    walk(node.body, contexts)
                    continue
                if isinstance(node, (WorkTileLoop, WhileTrueLoop)):
                    walk(node.body, contexts)
                    continue
                assert_never(node)

        walk(task.schedule.body, ((0, 0),))
    return observations


def find_while_true_loop(task: Task) -> WhileTrueLoop | None:
    """Return the unique ``WhileTrueLoop`` in ``task``, or ``None``."""
    return task._find_while_true_loop()


def collect_fire_count_hints(loop: WhileTrueLoop) -> list[tuple[BlockGuard, int]]:
    """Collect ``verify_num_fires`` hints declared inside ``loop``.

    Each hint pairs the *effective* firing condition of a hinted block with
    the number of modeled rounds on which the author says it fires.  That
    number is exact, not a floor: the arm this is meant for releases one stage
    per row, so a sequence that runs it more often over-releases and a
    sequence that runs it less leaves rows stranded.  Both are bugs to
    surface, not models to admit.

    The effective condition conjoins the enclosing conditional guards, because
    a nested block only runs when its ancestors do; counting its own guard
    alone would also count rounds on which an enclosing guard is false.

    Hints are the only handle the verifier has on a counter-backed exit.  A
    ``while_true_loop`` whose break tests ``valid_tile_count >= num_rows``
    reads, to the verifier, as a free boolean, so without a hint it enumerates
    exits after zero rounds, one round, and everything between -- almost all
    of which the kernel cannot reach.
    """
    hints: list[tuple[BlockGuard, int]] = []

    def walk(nodes: list, chain: tuple[BlockGuard, ...]) -> None:
        for node in nodes:
            if isinstance(node, ConditionalBlock):
                inner = chain
                if node.condition is not SKIPPABLE:
                    inner = chain + (node.condition,)
                if node.verify_num_fires is not None:
                    # A hinted block always contributes its own condition, and
                    # that condition is never SKIPPABLE (skippable() takes no
                    # hint), so ``inner`` holds at least one guard.
                    guard = inner[0] if len(inner) == 1 else GuardAnd(inner)
                    hints.append((guard, node.verify_num_fires))
                walk(node.body, inner)
            elif isinstance(node, (DomainLoop, WorkTileLoop, WhileTrueLoop)):
                walk(node.body, chain)

    walk(loop.body, ())
    return hints


@dataclass(frozen=True)
class CursorSnapshot:
    """Ordinary pipeline-cursor state observed by a verifier model."""

    index: int
    count: int
    num_stages: int

    @property
    def loop_offset(self) -> int:
        """Logical position of the stage the cursor currently names."""
        return self.index + self.count * self.num_stages


@dataclass(frozen=True)
class _CursorModel:
    """One opaque work result derived from an ordinary pipeline cursor."""

    key: Hashable
    resource: MemoryResource
    method_label: str
    model: Callable[[MemoryResource, CursorSnapshot], object]

    def evaluate(self, position: int) -> bool:
        cfg = self.resource.pipeline_config
        assert cfg is not None
        snapshot = CursorSnapshot(
            index=position % cfg.num_stages,
            count=position // cfg.num_stages,
            num_stages=cfg.num_stages,
        )
        return bool(self.model(self.resource, snapshot))

    def produced_by(self, step: Step) -> bool:
        """Return whether ``step`` is the work call this model stands in for."""
        label = step.label or step.schedule_stage.value
        return step.memory_resource is self.resource and label == self.method_label


_LoopCursors = Dict[int, int]


def collect_cursor_models(task: Task, loop: WhileTrueLoop) -> list[_CursorModel]:
    """Collect ``verify_model`` declarations read inside ``loop``."""
    models: dict[Hashable, _CursorModel] = {}
    for node in _iter_nodes(loop.body):
        if not isinstance(node, ConditionalBlock):
            continue
        for leaf in iter_leaves(node.condition):
            if not isinstance(leaf, OpaqueCondition):
                continue
            if leaf.resource is None or leaf.method_label is None:
                continue
            if leaf.key in models:
                continue
            if not isinstance(leaf.resource, MemoryResource):
                continue
            model = verify_model_for(leaf.resource, leaf.method_label)
            if model is None:
                continue
            if leaf.resource.pipeline_config is None:
                raise ValueError(
                    f"{leaf.resource.name}.{leaf.method_label}() declares "
                    "verify_model=, but the resource has no pipeline_config "
                    "and therefore no cursor to model."
                )
            models[leaf.key] = _CursorModel(
                key=leaf.key,
                resource=leaf.resource,
                method_label=leaf.method_label,
                model=model,
            )
    return list(models.values())


def _apply_state_advance(cursors: _LoopCursors, advance: StateAdvance) -> _LoopCursors:
    """Apply one ordinary pipeline-cursor advance."""
    updated = dict(cursors)
    rid = id(advance.state.resource)
    updated[rid] = updated.get(rid, 0) + advance.count
    return updated


def _guard_keys(guard: BlockGuard) -> Iterator[Hashable]:
    """Yield the opaque correlation keys ``guard`` reads."""
    for leaf in iter_leaves(guard):
        if isinstance(leaf, OpaqueCondition):
            yield leaf.key


def _replay_round(
    loop: WhileTrueLoop,
    models: list[_CursorModel],
    assignment: OpaqueAssignment,
    cursors: _LoopCursors,
    pinned_keys: Set[Hashable],
) -> Tuple[bool, OpaqueAssignment, _LoopCursors]:
    """Replay one round: check its models and reduce it to what it observes.

    Walks the loop body in schedule order under ``assignment`` and returns
    ``(agrees, canonical_assignment, cursors_after)``.

    ``agrees`` is false when a model disagrees with the value ``assignment``
    stamped for its key, which means the round cannot happen and neither can
    any sequence containing it.  A model constrains a round only when the
    round both runs the work call and reads its output: a value nothing
    branches on has no effect on the round, so pinning it would drop rounds
    the kernel can reach.

    ``canonical_assignment`` forces every key the round did not read to
    ``False``.  Rounds that differ only in unread keys expand identically,
    so canonicalizing lets the caller explore one of them instead of all,
    which is what keeps a loop over several pipelines finite: a round of the
    Q phase reads the Q probe and leaves the K and V probes untouched, and
    without this the K/V outcomes would multiply into every Q round.  It also
    makes ``verify_num_fires`` exact, because a hinted block cannot be
    counted as firing on the strength of a guard the round never evaluated.
    ``pinned_keys`` are exempt, and the caller supplies them for the break
    round only: that round is the assignment :func:`expand_task` hands the
    rest of this task and every partner task, so it also speaks for guards
    outside the loop.

    Raises ``ValueError`` when a modelled work call whose output the round
    reads runs after the round has already moved that resource's cursor.
    ``StageInfo.loop_offset`` inside a while loop is the value the loop's
    ``advance=`` hook returned at the top of the round, so a work call
    reading it after a ``next()`` in the same round sees the pre-``next()``
    offset while this walk would hand the model the post-``next()`` cursor.
    The retry idiom puts every cursor mutation after the guards, so this is a
    shape the verifier rejects rather than mismodels.
    """
    read: Set[Hashable] = set()
    pending: list[Tuple[_CursorModel, int]] = []

    def fires(guard: BlockGuard) -> bool:
        read.update(_guard_keys(guard))
        return guard_fires(guard, 0, 0, opaque_assignment=assignment)

    def walk(nodes: list) -> bool:
        """Apply one nesting level of the round.

        Returns whether a ``break_loop()`` ended it.  :func:`expand_task`
        stops emitting the rest of the round once one is reached, and this
        stops too, including through the conditional that contained it.  The
        read set is then exactly the guards the expansion evaluates, which is
        what makes the reduction below safe.
        """
        nonlocal cursors
        for node in nodes:
            if isinstance(node, LoopBreak):
                for condition in node.conditions:
                    read.update(_guard_keys(condition))
                return True
            if isinstance(node, Step):
                for model in models:
                    if model.produced_by(node):
                        pending.append((model, cursors.get(id(model.resource), 0)))
                continue
            if isinstance(node, StateAdvance):
                cursors = _apply_state_advance(cursors, node)
                continue
            if isinstance(node, ConditionalBlock):
                if node.condition is not SKIPPABLE and not fires(node.condition):
                    continue
                if walk(node.body):
                    return True
                continue
            # A domain_loop cannot nest inside a while_true_loop and neither
            # can a second while loop, so the only containers left run their
            # body once.
            if walk(node.body):
                return True
        return False

    walk(loop.body)
    canonical = {
        key: value if key in read or key in pinned_keys else False
        for key, value in assignment.items()
    }
    for model, position in pending:
        if model.key not in read:
            continue
        if model.evaluate(position) != bool(assignment.get(model.key, False)):
            return False, canonical, cursors
    return True, canonical, cursors


def _cursors_entering_loop(
    task: Task, loop: WhileTrueLoop, models: list[_CursorModel]
) -> _LoopCursors:
    """Cursor state the modelled resources hold when the loop starts.

    Everything the task does before the loop is unguarded in practice (cursor
    setup precedes the retry loop), so this applies the state ops it finds and
    refuses the cases it cannot resolve statically rather than guessing.

    Raises ``ValueError`` when a modelled resource's cursor is mutated inside
    a conditional or a loop before the while loop: the entering state would
    then depend on values this walk does not have, and a wrong entering state
    silently mismodels every round.
    """
    cursors: _LoopCursors = {}
    modelled = {id(model.resource) for model in models}
    if not modelled:
        return cursors

    def walk(nodes: list, guarded: bool) -> bool:
        """Apply pre-loop state ops; return whether the loop was reached."""
        nonlocal cursors
        for node in nodes:
            if node is loop:
                return True
            if isinstance(node, StateAdvance):
                if id(node.state.resource) not in modelled:
                    continue
                if guarded:
                    raise ValueError(
                        f"Task {task.name!r}: "
                        f"{node.state.resource.name} carries a verify_model= "
                        "guard, but its cursor is mutated inside a "
                        "conditional or loop before while_true_loop(); the "
                        "verifier cannot resolve the state the loop starts in."
                    )
                cursors = _apply_state_advance(cursors, node)
                continue
            if isinstance(node, (Step, LoopBreak)):
                continue
            # This walk sees the work-tile body once.  A second tile would
            # enter where the first tile finished, which this map does not
            # name.  :func:`check_all_interleavings` therefore checks one tile
            # when a while loop has a ``verify_model``.  A conditional or a
            # domain loop still makes the entering state depend on a guard
            # this walk does not have.
            nested_guarded = guarded or isinstance(node, (ConditionalBlock, DomainLoop))
            if walk(node.body, nested_guarded):
                return True
        return False

    walk(task.schedule.body, False)
    return cursors


def while_loop_exit_caveat(tasks: List[Task]) -> str | None:
    """Note that a while-loop failure may be an unreachable-exit artifact.

    A ``while_true_loop`` exit is an opaque formula, so the verifier models the
    loop exiting after any number of rounds.  Most of those rounds counts are
    unreachable when the exit tests a counter the loop body feeds, and a
    failure found on one of them is a false positive: the partners stall
    because the loop stopped releasing stages in a round sequence the kernel
    never executes.  Returns ``None`` when no task has a while loop, so the
    note only appears where it applies.
    """
    notes: list[str] = []
    for task in tasks:
        loop = find_while_true_loop(task)
        if loop is None:
            continue
        hints = collect_fire_count_hints(loop)
        counts = ", ".join(str(count) for count in loop.verify_num_iters)
        pinned = (
            ", ".join(
                f"{_format_block_guard(guard)} fires {declared}x"
                for guard, declared in hints
            )
            if hints
            else "none"
        )
        models = collect_cursor_models(task, loop)
        modelled = (
            ", ".join(
                f"{model.resource.name}.{model.method_label}()" for model in models
            )
            if models
            else "none"
        )
        notes.append(
            f"  {task.name}: opaque exit, "
            f"modeled rounds {counts}, fire-count hints: {pinned}, "
            f"cursor models: {modelled}"
        )
    if not notes:
        return None
    return "\n".join(
        [
            "NOTE: this kernel has a while_true_loop() whose exit is opaque, so "
            "the report above may be a false positive: the verifier explores "
            "round sequences that exit earlier or later than the kernel can. "
            "Constrain them with when_true(..., verify_num_fires=N) on the "
            "block whose count drives the exit.",
            *notes,
        ]
    )


def _fire_count(guard: BlockGuard, sequence: OpaqueAssignmentSequence) -> int:
    """Count the rounds of ``sequence`` on which ``guard`` holds.

    Iteration predicates cannot occur inside a ``while_true_loop`` (the
    builder rejects a nested ``domain_loop``), so the iteration arguments are
    unused and passed as zero.
    """
    return sum(
        1
        for assignment in sequence
        if guard_fires(guard, 0, 0, opaque_assignment=assignment)
    )


def _reachable_fire_counts(
    guard: BlockGuard,
    retry_assignments: list[OpaqueAssignment],
    break_assignments: list[OpaqueAssignment],
    count: int,
) -> Tuple[int, int]:
    """Smallest and largest fire count ``guard`` can reach over ``count`` rounds.

    A round is either one of the ``count - 1`` retry rounds or the final break
    round.  A position contributes to the ceiling when some assignment fires
    ``guard`` there and to the floor when every assignment does.

    Because ``verify_num_fires`` is an exact count, a hint can be out of range
    in either direction, and the two failures need different fixes: too high
    wants a larger ``verify_num_iters``, while too low means the guard is one
    the loop cannot avoid running that often.  Reporting only a ceiling would
    describe the second case as if it were the first.

    This treats every round as free, so it is only used when the loop carries
    no ``verify_model``; with models the range is measured on the sequences
    the models admit instead.
    """
    retry_rounds = count - 1
    retry_can = any(
        guard_fires(guard, 0, 0, opaque_assignment=a) for a in retry_assignments
    )
    retry_must = bool(retry_assignments) and all(
        guard_fires(guard, 0, 0, opaque_assignment=a) for a in retry_assignments
    )
    break_can = any(
        guard_fires(guard, 0, 0, opaque_assignment=a) for a in break_assignments
    )
    break_must = bool(break_assignments) and all(
        guard_fires(guard, 0, 0, opaque_assignment=a) for a in break_assignments
    )
    low = (retry_rounds if retry_must else 0) + (1 if break_must else 0)
    high = (retry_rounds if retry_can else 0) + (1 if break_can else 0)
    return low, high


def _opaque_clause_holds(
    clause: tuple[BlockGuard, ...], assignment: OpaqueAssignment
) -> bool:
    """Return whether every conjunct in ``clause`` holds under ``assignment``.

    An empty clause is an unconditional break (always true).
    """
    return all(guard_fires(cond, 0, 0, opaque_assignment=assignment) for cond in clause)


def _is_break_assignment(loop: WhileTrueLoop, assignment: OpaqueAssignment) -> bool:
    """Return whether ``assignment`` satisfies any captured break clause."""
    return any(
        _opaque_clause_holds(clause, assignment) for clause in loop.break_conditions
    )


def _round_signature(
    assignment: OpaqueAssignment, keys: list[object]
) -> Tuple[bool, ...]:
    """Order-independent identity of one round's canonical assignment."""
    return tuple(bool(assignment.get(key, False)) for key in keys)


def _model_consistent_sequences(
    loop: WhileTrueLoop,
    models: list[_CursorModel],
    retry_assignments: list[OpaqueAssignment],
    break_assignments: list[OpaqueAssignment],
    count: int,
    entering: _LoopCursors,
    keys: list[object],
    pinned_keys: Set[Hashable],
) -> list[OpaqueAssignmentSequence]:
    """Enumerate the ``count``-round sequences this loop can run.

    Rounds are extended one at a time rather than filtered out of a finished
    product, for two reasons.  A round that contradicts a cursor model prunes
    the whole subtree, and the contradiction is only visible in order because
    the cursor state depends on the rounds before it.  And each round is
    reduced to the guards it actually reads
    (:func:`_replay_round`), so rounds that expand identically are explored
    once: without that, a loop that probes three pipelines in alternating
    phases multiplies the two idle pipelines' outcomes into every round.
    """
    sequences: list[OpaqueAssignmentSequence] = []

    def rounds(
        candidates: list[OpaqueAssignment],
        cursors: _LoopCursors,
        pinned: Set[Hashable],
    ) -> list[Tuple[OpaqueAssignment, _LoopCursors]]:
        """Distinct rounds runnable from ``cursors``, in candidate order."""
        distinct: dict[Tuple[bool, ...], Tuple[OpaqueAssignment, _LoopCursors]] = {}
        for candidate in candidates:
            agrees, canonical, after = _replay_round(
                loop, models, candidate, cursors, pinned
            )
            if not agrees:
                continue
            distinct.setdefault(_round_signature(canonical, keys), (canonical, after))
        return list(distinct.values())

    def extend(
        prefix: List[OpaqueAssignment], cursors: _LoopCursors, remaining: int
    ) -> None:
        if remaining == 1:
            # Only the break round has to carry keys this loop does not read:
            # it is the assignment :func:`expand_task` gives the rest of this
            # task and every partner task.  A retry round speaks for nothing
            # outside its own iteration of the loop body.
            for brk, _after in rounds(break_assignments, cursors, pinned_keys):
                sequences.append(prefix + [brk])
            return
        for retry, after in rounds(retry_assignments, cursors, set()):
            extend(prefix + [retry], after, remaining - 1)

    extend([], entering, count)
    return sequences


def keys_read_outside(tasks: List[Task], loop: WhileTrueLoop) -> Set[Hashable]:
    """Collect the opaque keys read anywhere other than inside ``loop``.

    A round of ``loop`` is reduced to the guards it reads
    (:func:`_replay_round`), which is only sound for keys whose *only* reader
    is that loop.  A key a partner task branches on, or one this task reads
    before the loop, has to survive: the break round doubles as the
    ``default_assignment`` every non-while task expands with.
    """
    outside: Set[Hashable] = set()

    def walk(nodes: list, inside: bool) -> None:
        for node in nodes:
            if isinstance(node, Step):
                continue
            if isinstance(node, LoopBreak):
                if not inside:
                    for condition in node.conditions:
                        outside.update(_guard_keys(condition))
                continue
            if isinstance(node, StateAdvance):
                continue
            if isinstance(node, ConditionalBlock):
                if not inside and node.condition is not SKIPPABLE:
                    outside.update(_guard_keys(node.condition))
                walk(node.body, inside)
                continue
            walk(node.body, inside or node is loop)

    for task in tasks:
        walk(task.schedule.body, False)
    return outside


def _while_true_loop_task_sequences(
    task: Task,
    loop: WhileTrueLoop,
    keys: list[object],
    guard_observations: list[tuple[BlockGuard, int, int]] | None = None,
    pinned_keys: Set[Hashable] | None = None,
) -> list[OpaqueAssignmentSequence]:
    """Build ``retry^(N-1) + break`` sequences for one while-loop task.

    Two author-supplied constraints prune the result, and a sequence has to
    pass both:

    * ``verify_model`` replicas (:func:`collect_cursor_models`) are checked
      round by round while the sequence is built, so a round whose enumerated
      value contradicts the cursor is never extended.  This is the exact
      constraint of the two -- the verifier recomputes the value rather than
      counting occurrences.
    * ``verify_num_fires`` hints (:func:`collect_fire_count_hints`) are
      checked on the finished sequence: it survives only when every hinted
      block fires on exactly as many rounds as declared.  A modeled count too
      small to meet the hints contributes nothing instead of failing, so an
      author can offer several counts to explore how many unproductive rounds
      to model.

    Each round is also reduced to the guards it reads, so the result grows
    with the branching of one phase of the loop rather than with all of them
    at once (:func:`_replay_round`).

    Raises ``ValueError`` when no assignment satisfies a break clause, when
    ``N > 1`` but every assignment is a break assignment (no retry class), or
    when no count in ``verify_num_iters`` can meet the constraints.
    """
    all_assignments = _opaque_assignments(keys, guard_observations)
    break_assignments = [
        assignment
        for assignment in all_assignments
        if _is_break_assignment(loop, assignment)
    ]
    retry_assignments = [
        assignment
        for assignment in all_assignments
        if not _is_break_assignment(loop, assignment)
    ]
    task_name = getattr(task, "name", "?")
    if not break_assignments:
        raise ValueError(
            f"Task {task_name!r}: while_true_loop() has no assignment that "
            "satisfies a break_loop() clause; the loop cannot be verified."
        )
    fire_hints = collect_fire_count_hints(loop)
    models = collect_cursor_models(task, loop)
    entering = _cursors_entering_loop(task, loop, models)
    sequences: list[OpaqueAssignmentSequence] = []
    # Whether the models alone admitted anything, which is what tells the two
    # "nothing survived" diagnoses apart: an unreachable round count and an
    # unreachable fire count need different fixes.
    model_admitted = False
    widest = max(loop.verify_num_iters)
    # The widest count's model-consistent sequences, kept for the fire-count
    # diagnostic: with models in play the reachable range has to be measured
    # on the rounds the models admit, not on the raw assignment classes.
    admitted_widest: list[OpaqueAssignmentSequence] = []
    for count in loop.verify_num_iters:
        if count > 1 and not retry_assignments:
            raise ValueError(
                f"Task {task_name!r}: while_true_loop() "
                f"verify_num_iters={count} requires a retry assignment, "
                "but every opaque assignment satisfies a break_loop() "
                "clause."
            )
        for_count = _model_consistent_sequences(
            loop,
            models,
            retry_assignments,
            break_assignments,
            count,
            entering,
            keys,
            pinned_keys or set(),
        )
        model_admitted = model_admitted or bool(for_count)
        if count == widest:
            admitted_widest = list(for_count)
        for guard, declared in fire_hints:
            for_count = [
                seq for seq in for_count if _fire_count(guard, seq) == declared
            ]
        # A modeled count that cannot meet the hints is dropped rather than
        # rejected: offering several counts alongside a hint is how an author
        # asks for "these many productive rounds plus zero, one or two
        # unproductive ones", and the counts below that floor are simply not
        # models of this kernel.  Only an empty result is an error.
        sequences.extend(for_count)
    if models and not model_admitted:
        modelled = ", ".join(
            f"{model.resource.name}.{model.method_label}()" for model in models
        )
        raise ValueError(
            f"Task {task_name!r}: no while_true_loop() round sequence agrees "
            f"with the verify_model= of {modelled} over verify_num_iters="
            f"{tuple(loop.verify_num_iters)}.  The loop cannot run for any of "
            "the modeled round counts: pick a count the cursor can reach, or "
            "correct the model."
        )
    if fire_hints and not sequences:
        details: list[str] = []
        for guard, declared in fire_hints:
            if models:
                counts = [_fire_count(guard, seq) for seq in admitted_widest]
                low, high = (min(counts), max(counts)) if counts else (0, 0)
            else:
                low, high = _reachable_fire_counts(
                    guard, retry_assignments, break_assignments, widest
                )
            reach = f"exactly {low}" if low == high else f"between {low} and {high}"
            details.append(
                f"{_format_block_guard(guard)} declares "
                f"verify_num_fires={declared} but fires on {reach} of the "
                f"{widest} modeled rounds"
            )
        raise ValueError(
            f"Task {task_name!r}: no while_true_loop() round sequence satisfies "
            f"verify_num_fires over verify_num_iters="
            f"{tuple(loop.verify_num_iters)}: {'; '.join(details)}.  Raise "
            "verify_num_iters to model more rounds, or correct the hint."
        )
    return sequences


def opaque_assignment_sequences(
    tasks: List[Task], keys: list[object]
) -> list[OpaqueAssignment | OpaqueAssignmentScenario]:
    """Enumerate opaque assignments, using while-loop sequences when present.

    With no ``while_true_loop``, this is the cartesian product of boolean
    assignments over ``keys`` (same as ``_opaque_assignments``).

    When one or more tasks contain a while loop, each scenario carries a
    per-task sequence for those tasks and uses the last (break) assignment of
    the first while-loop task as ``default_assignment`` for partners.

    """
    while_tasks: list[tuple[Task, WhileTrueLoop]] = []
    for task in tasks:
        loop = find_while_true_loop(task)
        if loop is not None:
            while_tasks.append((task, loop))
    guard_observations = collect_guard_observations(tasks)
    if not while_tasks:
        return cast(
            list[OpaqueAssignment | OpaqueAssignmentScenario],
            _opaque_assignments(keys, guard_observations),
        )

    per_task_sequences = [
        _while_true_loop_task_sequences(
            task,
            loop,
            keys,
            guard_observations,
            pinned_keys=keys_read_outside(tasks, loop),
        )
        for task, loop in while_tasks
    ]
    scenarios: list[OpaqueAssignment | OpaqueAssignmentScenario] = []
    for combo in itertools.product(*per_task_sequences):
        task_assignments: dict[int, OpaqueAssignment | OpaqueAssignmentSequence] = {
            id(task): sequence for (task, _loop), sequence in zip(while_tasks, combo)
        }
        task_names = {id(task): task.name for task, _loop in while_tasks}
        first_sequence = combo[0]
        default = first_sequence[-1] if first_sequence else {}
        scenarios.append(
            OpaqueAssignmentScenario(
                default_assignment=default,
                task_assignments=task_assignments,
                task_names=task_names,
            )
        )
    return scenarios


def dynamic_domain_fallback_for(tasks: List[Task]) -> int:
    """Representative end bound for unfoldable domain-loop bounds in a kernel.

    One past the largest ``domain_loop`` start across ``tasks``, where a start
    folds from a literal or from a callable probed on a representative work
    tile.  The value is kernel-wide so trip counts stay comparable between
    tasks: a loop peeled to start at N models one iteration fewer than the loop
    it consumes from, keeping producer commits balanced against consumer waits.
    A start that does not fold contributes nothing; expansion warns about it.
    """
    starts: list[int] = []
    for task in tasks:
        for node in _iter_nodes(task.schedule.body):
            if isinstance(node, DomainLoop):
                start = _fold_domain_bound(node.start, task, "start", warn=False)
                if start is not None:
                    starts.append(start)
    return (max(starts) if starts else 0) + 1


# ── Result data classes ──────────────────────────────────────────────────


@dataclass(slots=True)
class BlockedTaskInfo:
    """Detailed reason one task is blocked in a deadlock state.

    ``barrier_kind`` names which barrier field the step compares against:
    ``"conditional phase"`` for a ``ConsumerWait``, ``"empty"`` for a
    ``ProducerAcquire``, or ``"primary phase"`` for a ``test_wait_valid``
    whose enumerated outcome claims a completion that has not happened.
    ``expected_phase`` is the phase the step's own software cursor names and
    ``observed_phase`` the phase the barrier is in; the compare succeeds when
    they differ, so equal values are the block.  ``window_state``, when set,
    says how far the stage's V1 arm/land window got, which is what
    distinguishes "nobody armed this stage" from "armed but never landed".
    """

    task_name: str
    resource_name: str
    stage_name: str
    barrier_kind: str
    physical_stage: int
    expected_phase: int
    observed_phase: int
    window_state: str
    pending_arrivals: int
    expected_arrivals: int
    domain_interleaved: bool
    available_stage_counts: Tuple[Tuple[int, int], ...]

    def format(self) -> str:
        """Return a human-readable one-line deadlock explanation."""
        base = f"{self.task_name} blocked on {self.resource_name}.{self.stage_name}"
        detail = (
            f"{base}: {self.barrier_kind}[{self.resource_name}, physical stage "
            f"{self.physical_stage}] expecting phase {self.expected_phase}, "
            f"barrier is in phase {self.observed_phase} with "
            f"{self.pending_arrivals} of {self.expected_arrivals} arrival"
            f"{'' if self.expected_arrivals == 1 else 's'}"
        )
        if self.window_state:
            detail += f", {self.window_state}"
        if self.domain_interleaved:
            detail += "; this resource is tracked per domain-interleave lane"
        if self.available_stage_counts:
            available = ", ".join(
                f"physical stage {stage} ({count} available)"
                for stage, count in self.available_stage_counts
            )
            detail += f"; matching phase is available on {available}"
        return detail


@dataclass(slots=True)
class DeadlockInfo:
    """A deadlock state found during exhaustive exploration."""

    cursors: tuple
    blocked_tasks: List[Tuple[str, str, str]]
    blocked_details: List[BlockedTaskInfo] = field(default_factory=list)

    def format_lines(self) -> List[str]:
        """Format this deadlock state for diagnostics."""
        lines = [f"cursors={self.cursors}"]
        if self.blocked_details:
            lines.extend(f"  {detail.format()}" for detail in self.blocked_details)
        else:
            lines.extend(
                f"  {task} blocked on {resource}.{stage}"
                for task, resource, stage in self.blocked_tasks
            )
        return lines


@dataclass(slots=True)
class RaceInfo:
    """A data race found during exhaustive exploration."""

    cursors: tuple
    writer_task: str
    writer_resource: str
    victim_task: str
    victim_resource: str
    victim_access: str
    overlap_desc: str


@dataclass(slots=True)
class PdlOrderInfo:
    """A PDL launch that can execute before any PDL wait in an interleaving."""

    cursors: tuple
    launch_task: str
    launch_resource: str


@dataclass(slots=True)
class ProtocolErrorInfo:
    """A barrier protocol violation found during exhaustive exploration."""

    cursors: tuple
    task_name: str
    resource_name: str
    message: str


@dataclass(slots=True)
class CheckResult:
    """Aggregated results from ``check_all_interleavings``."""

    deadlock_states: List[DeadlockInfo]
    race_states: List[RaceInfo]
    states_explored: int
    complete_count: int
    is_safe: bool
    pdl_order_states: List[PdlOrderInfo] = field(default_factory=list)
    protocol_states: List[ProtocolErrorInfo] = field(default_factory=list)
    hit_state_limit: bool = False


@dataclass(slots=True)
class _BfsState:
    """One queued BFS state.

    ``barriers`` is the flat barrier vector described by :data:`_BARRIER_FIELDS`
    — the only synchronization state the checker carries, since software cursor
    values are a pure function of a task's own position and are resolved
    statically by :func:`~.task_manager._simulate_cursors`.
    """

    cursors: tuple
    cursor_key: int
    barriers: BarrierTuple
    held: HeldMap
    path: Optional[List[Tuple[str, str]]]
    has_executed_pdl_wait: bool


# ── Stage classifications ────────────────────────────────────────────────

# Barrier-protocol stages whose ownership transition the held-state tracker
# has to see.  Which steps can *block* is decided per step from the barrier it
# compares against (``_StepInfo.gate_kind``), not from this set.
_BLOCKING = frozenset({ScheduleStage.ConsumerWait, ScheduleStage.ProducerAcquire})
_POINT_WRITE = frozenset({ScheduleStage.ProducerWork})
_POINT_READ = frozenset({ScheduleStage.ConsumerWork})


# ── Helper functions ─────────────────────────────────────────────────────


def _is_pdl_wait_entry(entry: FlatScheduleOp) -> bool:
    """Return True when a schedule entry emits PDL wait."""
    return (
        isinstance(entry.resource, PdlWaitBarrier)
        and entry.schedule_stage == ScheduleStage.ConsumerWork
    )


def _is_pdl_launch_entry(entry: FlatScheduleOp) -> bool:
    """Return True when a schedule entry emits PDL launch-dependents."""
    return (
        isinstance(entry.resource, PdlLaunchBarrier)
        and entry.schedule_stage == ScheduleStage.ProducerWork
    )


def _is_tracked(res: MemoryResource) -> bool:
    """WorkQueue resources are exempt from barrier tracking.

    A ``WorkQueue`` manages its own CLC pipeline internally, so its steps
    never gate on a barrier the checker models.  ``PipelineGroup`` objects are
    tracked (they carry a merged ``pipeline_config``); a member whose barrier
    ops go through a group still uses its own held-state for race detection
    but does not own the barrier those ops signal.
    """
    return not isinstance(res, WorkQueue)


def _collect_resources(tasks: List[Task]) -> List[MemoryResource]:
    """De-duplicate resources from all tasks, preserving first-seen order."""
    seen: Set[int] = set()
    resources: List[MemoryResource] = []
    for task in tasks:
        for res in task.src_resources:
            if id(res) not in seen:
                seen.add(id(res))
                resources.append(res)
        for res in task.dst_resources:
            if id(res) not in seen:
                seen.add(id(res))
                resources.append(res)
    return resources


def _allocs_to_ranges(allocs: list) -> list:
    """Convert ``SmemAllocation`` / ``TmemAllocation`` objects to ranges.

        Returns a list of ``(space, start, end)`` tuples.
    """
    ranges: list = []
    for a in allocs:
        if hasattr(a, "size_bytes") and a.size_bytes > 0:
            ranges.append(("smem", a.offset, a.offset + a.size_bytes))
        elif hasattr(a, "num_columns") and a.num_columns > 0:
            ranges.append(("tmem", a.offset, a.offset + a.num_columns))
    return ranges


def _resource_all_ranges(resource: MemoryResource) -> list:
    """Collect all physical ranges (SMEM + TMEM) for a resource."""
    ranges: list = []
    if hasattr(resource, "get_smem_requirements"):
        for a in resource.get_smem_requirements():
            if a.size_bytes > 0:
                ranges.append(("smem", a.offset, a.offset + a.size_bytes))
    if hasattr(resource, "get_tmem_requirements"):
        for t in resource.get_tmem_requirements():
            if t.num_columns > 0:
                ranges.append(("tmem", t.offset, t.offset + t.num_columns))
    return ranges


def _resource_role_ranges(
    resource: MemoryResource,
    role_allocs: Optional[list],
) -> list:
    """Collect physical ranges for a specific role (producer or consumer).

    If *role_allocs* is ``None`` (the default when the resource does not
    override ``get_producer/consumer_requirements``), falls back to
    ``_resource_all_ranges``.
    """
    if role_allocs is None:
        return _resource_all_ranges(resource)
    return _allocs_to_ranges(role_allocs)


def _ranges_overlap(ranges_a: list, ranges_b: list) -> list:
    """Return overlapping intervals between two range lists."""
    overlaps = []
    for sa, a0, a1 in ranges_a:
        for sb, b0, b1 in ranges_b:
            if sa == sb and a0 < b1 and b0 < a1:
                overlaps.append((sa, max(a0, b0), min(a1, b1)))
    return overlaps


def _build_role_alias_map(
    role_range_map: Dict[int, tuple],
    all_range_map: Dict[int, tuple],
) -> Dict[int, Set[int]]:
    """Build an asymmetric alias map: role_ranges(A) × all_ranges(B).

    For each resource A in *role_range_map*, find which resources B in
    *all_range_map* have ranges that overlap with A's role-specific
    ranges.
    """
    role_alias_map: Dict[int, Set[int]] = {}
    for rid_a, (_, role_ranges_a) in role_range_map.items():
        for rid_b, (_, all_ranges_b) in all_range_map.items():
            if rid_a == rid_b:
                continue
            if _ranges_overlap(role_ranges_a, all_ranges_b):
                role_alias_map.setdefault(rid_a, set()).add(rid_b)
    return role_alias_map


def build_alias_info(
    resources: List[MemoryResource],
) -> Tuple[
    Dict[int, Set[int]],
    Dict[int, Set[int]],
    Dict[int, Set[int]],
    Dict[Tuple[int, int], str],
]:
    """Build alias maps and overlap descriptions from physical ranges.

    Returns ``(alias_map, prod_alias_map, cons_alias_map, overlap_descs)``:

    - *alias_map* — symmetric, all-ranges × all-ranges.  Used by the
      held-state tracker to decide whether a resource needs tracking.
    - *prod_alias_map* — asymmetric, producer-ranges × all-ranges.
      Used for producer-side race checks.  Reflects allocations from
      ``get_producer_requirements()`` (defaults to all when ``None``).
    - *cons_alias_map* — asymmetric, consumer-ranges × all-ranges.
      Used for consumer-side race checks.  Reflects allocations from
      ``get_consumer_requirements()`` (defaults to all when ``None``).
    - *overlap_descs* — human-readable overlap description per pair.
    """
    all_range_map: Dict[int, tuple] = {}
    prod_range_map: Dict[int, tuple] = {}
    cons_range_map: Dict[int, tuple] = {}
    for resource in resources:
        all_ranges = _resource_all_ranges(resource)
        if all_ranges:
            all_range_map[id(resource)] = (resource, all_ranges)
        prod_allocs = (
            resource.get_producer_requirements()
            if hasattr(resource, "get_producer_requirements")
            else None
        )
        prod_ranges = _resource_role_ranges(resource, prod_allocs)
        if prod_ranges:
            prod_range_map[id(resource)] = (resource, prod_ranges)
        cons_allocs = (
            resource.get_consumer_requirements()
            if hasattr(resource, "get_consumer_requirements")
            else None
        )
        cons_ranges = _resource_role_ranges(resource, cons_allocs)
        if cons_ranges:
            cons_range_map[id(resource)] = (resource, cons_ranges)

    if not all_range_map:
        return {}, {}, {}, {}

    # alias_map: all_ranges × all_ranges (symmetric)
    items = list(all_range_map.values())
    alias_map: Dict[int, Set[int]] = {}
    overlap_descs: Dict[Tuple[int, int], str] = {}
    for i, (ra, ranges_a) in enumerate(items):
        for rb, ranges_b in items[i + 1 :]:
            overlaps = _ranges_overlap(ranges_a, ranges_b)
            if overlaps:
                alias_map.setdefault(id(ra), set()).add(id(rb))
                alias_map.setdefault(id(rb), set()).add(id(ra))
                key = (min(id(ra), id(rb)), max(id(ra), id(rb)))
                overlap_descs[key] = ", ".join(f"{s}[{a}:{b}]" for s, a, b in overlaps)

    prod_alias_map = _build_role_alias_map(prod_range_map, all_range_map)
    cons_alias_map = _build_role_alias_map(cons_range_map, all_range_map)

    return alias_map, prod_alias_map, cons_alias_map, overlap_descs


def _slots_overlap(slot_a: int, slot_b: int) -> bool:
    """Return True when two accesses may target the same physical slot."""
    return slot_a == _SLOTLESS or slot_b == _SLOTLESS or slot_a == slot_b


def _entry_matches(
    entry: HeldEntry,
    access_types: tuple[str, ...] | None = None,
    task_idx: int | None = None,
    slot: int | None = None,
    gen: int | None = None,
) -> bool:
    """Return True when a held entry matches the requested filters."""
    access, tid, entry_slot, entry_gen = entry
    if access_types is not None and access not in access_types:
        return False
    if task_idx is not None and tid != task_idx:
        return False
    if slot is not None and entry_slot != slot:
        return False
    if gen is not None and entry_gen != gen:
        return False
    return True


def _pop_first_entry(
    entries: List[HeldEntry],
    access_types: tuple[str, ...] | None = None,
    task_idx: int | None = None,
    slot: int | None = None,
) -> bool:
    """Remove the first held entry matching the filters."""
    for idx, entry in enumerate(entries):
        if _entry_matches(entry, access_types, task_idx, slot):
            entries.pop(idx)
            return True
    return False


def _pop_last_entry(
    entries: List[HeldEntry],
    access_types: tuple[str, ...] | None = None,
    task_idx: int | None = None,
    slot: int | None = None,
) -> bool:
    """Remove the last held entry matching the filters."""
    for idx in range(len(entries) - 1, -1, -1):
        if _entry_matches(entries[idx], access_types, task_idx, slot):
            entries.pop(idx)
            return True
    return False


def _find_races_at_state(
    held: HeldMap,
    next_point_ops: List[PointAccess],
    alias_map: Dict[int, Set[int]],
    prod_alias_map: Dict[int, Set[int]],
    cons_alias_map: Dict[int, Set[int]],
    overlap_descs: Dict[Tuple[int, int], str],
    id_to_res: Dict[int, MemoryResource],
    task_names: List[str],
    cursors: tuple,
    domain_rids: Set[int],
) -> List[RaceInfo]:
    """Find aliasing races at one state.

    Merges pipeline ownership entries and next point-access ops into a
    single list and checks all pairs on aliased resources.  A race is
    flagged when both entries are stored/access states, neither entry is
    ``prod_held``, and at least one entry is producer work (``prod``).

    For each access, the role-specific alias map is used
    (``prod_alias_map`` for producer-side states, ``cons_alias_map`` for
    consumer-side states) so that only the physical ranges the role
    actually accesses (declared via ``get_producer/consumer_requirements``)
    are considered.  Both sides of a candidate pair must confirm the
    overlap through their respective maps.
    """

    def _is_racing_write(access: str) -> bool:
        return access == "prod"

    def _is_reservation_only(access: str) -> bool:
        return access == "prod_held"

    def _aliases_for(rid: int, access: str) -> Set[int]:
        if access in {"prod_held", "prod"}:
            return prod_alias_map.get(rid, set())
        if access in {"cons_held", "cons"}:
            return cons_alias_map.get(rid, set())
        return alias_map.get(rid, set())

    def _make_race(
        writer_tid: int,
        writer_rid: int,
        victim_tid: int,
        victim_rid: int,
        victim_access: str,
    ) -> RaceInfo:
        key = (min(writer_rid, victim_rid), max(writer_rid, victim_rid))
        return RaceInfo(
            cursors=cursors,
            writer_task=task_names[writer_tid],
            writer_resource=id_to_res[writer_rid].name,
            victim_task=task_names[victim_tid],
            victim_resource=id_to_res[victim_rid].name,
            victim_access=victim_access,
            overlap_desc=overlap_descs.get(key, "?"),
        )

    all_accesses: List[PointAccess] = []
    for rid, entries in held.items():
        for access_type, task_idx, slot, _gen in entries:
            all_accesses.append((rid, slot, access_type, task_idx))
    all_accesses.extend(next_point_ops)

    races: List[RaceInfo] = []
    seen: Set[Tuple[int, int, int, int]] = set()
    for i, (rid_a, slot_a, access_a, ti_a) in enumerate(all_accesses):
        if rid_a not in alias_map:
            continue
        for rid_b, slot_b, access_b, ti_b in all_accesses[i + 1 :]:
            if ti_a == ti_b:
                continue
            if not _slots_overlap(slot_a, slot_b):
                continue
            # Two different tasks accessing the same domain-interleaved
            # resource are distinct domain lanes, which own *disjoint*
            # physical ring stages (lane ``L`` owns ``L, L+stride, …``).
            # Their work never aliases, so this is not a race.
            if rid_a == rid_b and rid_a in domain_rids:
                continue
            if _is_reservation_only(access_a) or _is_reservation_only(access_b):
                continue
            if not (_is_racing_write(access_a) or _is_racing_write(access_b)):
                continue

            # Both sides must confirm the overlap through their
            # role-specific alias maps.
            if rid_b not in _aliases_for(rid_a, access_a):
                continue
            if rid_a not in _aliases_for(rid_b, access_b):
                continue

            race_key = (
                min(ti_a, ti_b),
                max(ti_a, ti_b),
                min(rid_a, rid_b),
                max(rid_a, rid_b),
            )
            if race_key in seen:
                continue
            seen.add(race_key)
            if _is_racing_write(access_a):
                races.append(_make_race(ti_a, rid_a, ti_b, rid_b, access_b))
            else:
                races.append(_make_race(ti_b, rid_b, ti_a, rid_a, access_a))

    return races


def _freeze_held(held: HeldMap) -> tuple:
    """Canonicalize held map for visited-state keys.

    Resource ids and entries are sorted for stable hashing.  Held entries carry
    an explicit pipeline slot, so list order is not part of the logical state.
    """
    return tuple(
        (rid, tuple(sorted(entries)))
        for rid, entries in sorted(held.items())
        if entries
    )


def _make_state_key(
    cursors: tuple,
    barriers: BarrierTuple,
    held: HeldMap,
) -> tuple:
    """Build the ``cursor_only_visited=False`` visited-state key.

    Barrier state and held state are both deterministic functions of the
    cursor positions — every arrival sits at a fixed offset in some task's
    schedule — so the default key uses the cursors alone.  Spelling them out
    here can only split states, never merge them, so a run whose
    ``states_explored`` grows under this key has found a divergence.
    """
    return (cursors, barriers, _freeze_held(held))


# ── Optimized BFS metadata ──────────────────────────────────────────────


@dataclass(frozen=True, slots=True)
class _StepInfo:
    """Precomputed metadata for one schedule position.

    Barrier-related fields resolve, statically, which barrier record a step
    touches and how:

    - ``physical_stage`` is the ring slot the step's software cursor names,
      and is what diagnostics report.
    - ``full_slot`` / ``empty_slot`` index into the barrier vector.  They are
      equal except on a ``FusedMerge`` member, whose transfer arrives on the
      group's shared full barrier while its empty barrier stays its own.
    - ``gate_kind`` is which phase compare (if any) can block the step;
      ``gate_slot`` is the barrier record it reads and ``gate_phase`` the
      phase the step's own software cursor names.
    - ``arrives_on_full`` / ``arrives_on_empty`` mark the step that increments
      an arrival count, and ``full_expected`` / ``empty_expected`` how many
      arrivals flip that barrier.
    """

    res: MemoryResource
    stage: Optional[ScheduleStage]
    rid: int
    in_alias: bool
    is_pdl_wait: bool
    is_pdl_launch: bool
    cons_work_phase: Optional[str]
    consecutive_same_work: bool
    is_point_write: bool
    is_point_read: bool
    is_producer_commit: bool
    is_consumer_release: bool
    is_consumer_wait: bool
    is_producer_acquire: bool
    is_producer_work: bool
    is_consumer_work: bool
    has_barrier_transition: bool
    needs_held_update: bool
    is_merge_group: bool
    is_fused_merge_group: bool
    producer_slot: int
    consumer_slot: int
    group_member_release_slots: Tuple[Tuple[int, int], ...]
    group_member_wait_slots: Tuple[Tuple[int, int], ...]
    completion_wait_rids: Tuple[int, ...]
    commit_wait_gen: int
    physical_stage: int
    full_slot: int
    empty_slot: int
    gate_kind: int
    gate_slot: int
    gate_phase: int
    arrives_on_full: bool
    arrives_on_empty: bool
    full_expected: int
    empty_expected: int
    group_full_arrivals: Tuple[Tuple[int, int], ...]
    group_empty_arrivals: Tuple[Tuple[int, int], ...]


@dataclass(slots=True)
class _ConsumerCompletionMetadata:
    """Async consumer completion information used by held-state transitions."""

    dma_consumer_rids: Set[int]
    completion_wait_rids: Dict[int, Set[int]]


@dataclass(slots=True)
class _CheckerContext:
    """Read-only setup data shared by BFS helper functions."""

    task_names: List[str]
    n_tasks: int
    schedule_lens: List[int]
    cursor_strides: List[int]
    schedule_steps: List[List[Optional[_StepInfo]]]
    id_to_res: Dict[int, MemoryResource]
    alias_map: Dict[int, Set[int]]
    prod_alias_map: Dict[int, Set[int]]
    cons_alias_map: Dict[int, Set[int]]
    overlap_descs: Dict[Tuple[int, int], str]
    domain_rids: Set[int]
    cursor_only_visited: bool
    assume_pdl_wait_completed: bool


@dataclass(frozen=True, slots=True)
class _EnabledTasks:
    """Enabled-task classification for one BFS state."""

    mask: int
    all_done: bool

    def contains(self, task_idx: int) -> bool:
        return bool(self.mask & (1 << task_idx))


def _build_consumer_completion_metadata(
    tasks: List[Task],
    resources: List[MemoryResource],
) -> _ConsumerCompletionMetadata:
    """Build DMA-consumer and paired completion-wait metadata.

    A task-local completion pair means one task consumes a DMA-consumer
    resource and produces a resource whose later ``ConsumerWait`` proves
    that the earlier consumer-side reads are complete.
    """
    dma_consumer_rids: Set[int] = {
        id(r) for r in resources if _is_dma_consumer_resource(r)
    }
    completion_wait_rids: Dict[int, Set[int]] = {}
    for task in tasks:
        dma_consumed = [r for r in task.src_resources if _is_dma_consumer_resource(r)]
        completion_producers = [
            r for r in task.dst_resources if _is_completion_producer_resource(r)
        ]
        for prod_res in completion_producers:
            for cons_res in dma_consumed:
                completion_wait_rids.setdefault(id(prod_res), set()).add(id(cons_res))
    return _ConsumerCompletionMetadata(dma_consumer_rids, completion_wait_rids)


def _precompute_schedule_steps(
    schedules: List[list],
    alias_map: Dict[int, Set[int]],
    num_producers: Dict[int, int],
    num_consumers: Dict[int, int],
    completion_wait_rids: Dict[int, Set[int]],
    barrier_offsets: Dict[int, int],
) -> List[List[Optional[_StepInfo]]]:
    """Build per-(task, cursor) metadata to avoid hot-loop unpacking.

    All slot and phase values come from ``entry.cursor_state``, which
    :func:`~.task_manager._simulate_cursors` resolved by walking the task's own
    explicit cursor IR.  ``ensure_explicit_state_ir`` guarantees every
    pipelined step carries a binding, so a pipelined step always has a
    simulated ``(index, phase, count)``.
    """
    out: List[List[Optional[_StepInfo]]] = []
    for sched in schedules:
        commit_gen: Dict[int, int] = {}
        wait_gen: Dict[int, int] = {}
        # Per (rid, stage) the index of the last ProducerWork of the transfer
        # group currently open on that stage.  A transfer-completing pipeline
        # attributes the arrival to the last transfer of the group, because on
        # hardware the barrier's transaction count spans every transfer issued
        # into the stage and only completes when the last one lands.  A group
        # is closed by the ProducerCommit that ends the round or by the next op
        # that arms the stage, whichever comes first.
        pending_work: Dict[Tuple[int, int], int] = {}
        arrives_at: Set[int] = set()
        commit_without_work: Set[int] = set()

        steps: List[Optional[_StepInfo]] = []
        for c, entry in enumerate(sched):
            res, stage = entry.resource, entry.schedule_stage
            rid = id(res)
            cfg = res.pipeline_config
            simulated = _step_cursor_state(entry)
            slot = simulated[0] if simulated is not None else _SLOTLESS
            if cfg is not None and not _is_tracked(res):
                slot = _SLOTLESS
            if (
                cfg is not None
                and slot != _SLOTLESS
                and cfg.pipeline_type in _TRANSFER_COMPLETES_FULL
                and not _commits_at_group_level(res)
            ):
                key = (rid, slot)
                if stage is ScheduleStage.ProducerWork:
                    pending_work[key] = c
                elif stage is ScheduleStage.ProducerCommit:
                    work_c = pending_work.pop(key, None)
                    if work_c is None:
                        # A group-level commit can cover transfers issued on
                        # the members. Keeping the arrival on the commit leaves
                        # that round verifiable instead of reporting a false
                        # deadlock.
                        commit_without_work.add(c)
                    else:
                        arrives_at.add(work_c)
                elif stage in _ARMS_FULL_BARRIER:
                    # Arming the stage again closes the previous transfer
                    # group: whatever it issued has landed by the time the
                    # stage can be re-armed.
                    work_c = pending_work.pop(key, None)
                    if work_c is not None:
                        arrives_at.add(work_c)
        # A transfer with no commit behind it still completes the barrier.
        arrives_at.update(pending_work.values())

        for c, entry in enumerate(sched):
            res, stage = entry.resource, entry.schedule_stage
            rid = id(res)
            is_producer_work = stage == ScheduleStage.ProducerWork
            is_consumer_work = stage == ScheduleStage.ConsumerWork
            is_producer_commit = stage == ScheduleStage.ProducerCommit
            is_consumer_release = stage == ScheduleStage.ConsumerRelease
            is_consumer_wait = stage == ScheduleStage.ConsumerWait
            is_producer_acquire = stage == ScheduleStage.ProducerAcquire
            track = _is_tracked(res)
            consecutive = False
            if is_producer_work or is_consumer_work:
                next_c = c + 1
                consecutive = (
                    next_c < len(sched)
                    and id(sched[next_c].resource) == rid
                    and sched[next_c].schedule_stage == stage
                )
            group_member_rids: Tuple[int, ...] = ()
            is_fork_group = False
            is_merge_group = False
            is_fused_merge_group = False
            if isinstance(res, PipelineGroup):
                group_member_rids = tuple(id(member) for member in res.members)
                is_fork_group = res.mode == PipelineGroupMode.Fork
                is_fused_merge_group = res.mode == PipelineGroupMode.FusedMerge
                is_merge_group = res.mode in (
                    PipelineGroupMode.Merge,
                    PipelineGroupMode.FusedMerge,
                )
            pg = getattr(res, "pipeline_group", None)
            protocol_blocking = stage in _BLOCKING
            is_point_write = stage in _POINT_WRITE
            is_point_read = stage in _POINT_READ
            in_alias = rid in alias_map
            is_completion_commit = is_producer_commit and bool(
                completion_wait_rids.get(rid)
            )
            is_completion_wait = is_consumer_wait and bool(
                completion_wait_rids.get(rid)
            )
            commit_wait_gen = -1
            if is_completion_commit:
                commit_wait_gen = commit_gen.get(rid, 0)
                commit_gen[rid] = commit_wait_gen + 1
            if is_completion_wait:
                commit_wait_gen = wait_gen.get(rid, 0)
                wait_gen[rid] = commit_wait_gen + 1
            needs_held_update = (
                (is_consumer_release and is_merge_group)
                or (is_consumer_wait and is_fused_merge_group)
                or (
                    in_alias
                    and (
                        protocol_blocking
                        or is_point_write
                        or is_point_read
                        or is_consumer_release
                    )
                )
                or is_completion_wait
                or is_completion_commit
            )
            producer_slot = _SLOTLESS
            consumer_slot = _SLOTLESS
            group_member_release_slots: Tuple[Tuple[int, int], ...] = ()
            group_member_wait_slots: Tuple[Tuple[int, int], ...] = ()
            cfg = res.pipeline_config
            simulated = _step_cursor_state(entry)
            if cfg is not None and simulated is not None:
                if is_producer_acquire or is_producer_work or is_producer_commit:
                    producer_slot = simulated[0]
                if is_consumer_wait or is_consumer_work or is_consumer_release:
                    consumer_slot = simulated[0]

            if is_merge_group and is_consumer_release:
                group_member_release_slots = tuple(
                    (
                        id(member),
                        (simulated[0] if simulated is not None else _SLOTLESS),
                    )
                    for member in res.members
                )

            if is_fused_merge_group and is_consumer_wait:
                group_member_wait_slots = tuple(
                    (
                        id(member),
                        (simulated[0] if simulated is not None else _SLOTLESS),
                    )
                    for member in res.members
                    if id(member) in alias_map
                )

            # ── Barrier resolution ──────────────────────────────────────
            physical_stage = _SLOTLESS
            full_slot = _SLOTLESS
            empty_slot = _SLOTLESS
            gate_kind = _GATE_NONE
            gate_slot = _SLOTLESS
            gate_phase = 0
            arrives_on_full = False
            arrives_on_empty = False
            full_expected = 1
            empty_expected = 1
            group_full_arrivals: Tuple[Tuple[int, int], ...] = ()
            group_empty_arrivals: Tuple[Tuple[int, int], ...] = ()
            transfer_completes = (
                cfg is not None and cfg.pipeline_type in _TRANSFER_COMPLETES_FULL
            )

            if track and cfg is not None and simulated is not None:
                physical_stage = simulated[0]
                base = barrier_offsets.get(rid)
                if base is not None:
                    empty_slot = base + simulated[0]
                    empty_expected = num_consumers.get(rid, 1)
                owner = _full_barrier_owner(res)
                owner_base = barrier_offsets.get(owner)
                if owner_base is not None:
                    full_slot = owner_base + simulated[0]
                if owner != rid:
                    # FusedMerge: one shared full barrier that every member's
                    # transfer arrives on.
                    assert pg is not None
                    full_expected = len(pg.members)
                else:
                    full_expected = num_producers.get(rid, 1)
                # Every gate is the same compare against a different field, and
                # ``simulated[1]`` is the phase this step's own cursor names.
                if is_consumer_wait:
                    gate_kind, gate_slot = _GATE_FULL, full_slot
                elif is_producer_acquire:
                    gate_kind, gate_slot = _GATE_EMPTY, empty_slot
                if gate_kind != _GATE_NONE:
                    gate_phase = simulated[1]

                arrives_on_empty = is_consumer_release
                if transfer_completes:
                    arrives_on_full = (is_producer_work and c in arrives_at) or (
                        is_producer_commit and c in commit_without_work
                    )
                else:
                    arrives_on_full = is_producer_commit

            if group_member_rids and simulated is not None:
                # Fork commits fan out onto the members' full barriers and
                # merge releases onto the members' empty barriers, both at the
                # group cursor's stage: the group owns the cursor, so its
                # position is what names the members' ring slot.
                if is_fork_group and is_producer_commit:
                    group_full_arrivals = tuple(
                        (
                            barrier_offsets[mid] + simulated[0],
                            num_producers.get(mid, 1),
                        )
                        for mid in group_member_rids
                        if mid in barrier_offsets
                    )
                    arrives_on_full = False
                if is_merge_group and is_consumer_release:
                    group_empty_arrivals = tuple(
                        (
                            barrier_offsets[mid] + simulated[0],
                            num_consumers.get(mid, 1),
                        )
                        for mid in group_member_rids
                        if mid in barrier_offsets
                    )
                    arrives_on_empty = False

            steps.append(
                _StepInfo(
                    res=res,
                    stage=stage,
                    rid=rid,
                    in_alias=in_alias,
                    is_pdl_wait=_is_pdl_wait_entry(entry),
                    is_pdl_launch=_is_pdl_launch_entry(entry),
                    cons_work_phase=_entry_consumer_work_phase(entry),
                    consecutive_same_work=consecutive,
                    is_point_write=is_point_write,
                    is_point_read=is_point_read,
                    is_producer_commit=is_producer_commit,
                    is_consumer_release=is_consumer_release,
                    is_consumer_wait=is_consumer_wait,
                    is_producer_acquire=is_producer_acquire,
                    is_producer_work=is_producer_work,
                    is_consumer_work=is_consumer_work,
                    has_barrier_transition=(
                        arrives_on_full
                        or arrives_on_empty
                        or bool(group_full_arrivals)
                        or bool(group_empty_arrivals)
                    ),
                    needs_held_update=needs_held_update,
                    is_merge_group=is_merge_group,
                    is_fused_merge_group=is_fused_merge_group,
                    producer_slot=producer_slot,
                    consumer_slot=consumer_slot,
                    group_member_release_slots=group_member_release_slots,
                    group_member_wait_slots=group_member_wait_slots,
                    completion_wait_rids=tuple(completion_wait_rids.get(rid, ())),
                    commit_wait_gen=commit_wait_gen,
                    physical_stage=physical_stage,
                    full_slot=full_slot,
                    empty_slot=empty_slot,
                    gate_kind=gate_kind,
                    gate_slot=gate_slot,
                    gate_phase=gate_phase,
                    arrives_on_full=arrives_on_full,
                    arrives_on_empty=arrives_on_empty,
                    full_expected=full_expected,
                    empty_expected=empty_expected,
                    group_full_arrivals=group_full_arrivals,
                    group_empty_arrivals=group_empty_arrivals,
                )
            )
        out.append(steps)
    return out


def _cow_held(
    held: HeldMap,
    rid: Optional[int] = None,
) -> HeldMap:
    """Shallow-copy held dict; optionally deep-copy one resource list."""
    if not held:
        return {}
    new_held = dict(held)
    if rid is not None and rid in new_held:
        new_held[rid] = list(held[rid])
    return new_held


def _arrive(
    record: List[int],
    phase_field: int,
    count_field: int,
    expected: int,
) -> bool:
    """Count one arrival on a barrier; flip and report when it completes."""
    record[count_field] += 1
    if record[count_field] < expected:
        return False
    record[count_field] = 0
    record[phase_field] ^= 1
    return True


def _apply_barrier_transition(
    step: _StepInfo,
    barriers: BarrierTuple,
) -> Tuple[BarrierTuple, Optional[str]]:
    """Apply one step's barrier effects.

    Returns the successor barrier vector. The optional error result is reserved
    for protocol extensions that impose rules beyond ordinary ring barriers.

    Barrier effects, by side:

    - **Empty barrier** — ``ConsumerRelease`` arrives (fanning out to every
      member for a merge group).  It flips once ``num_consumers`` releases
      land, which is the point the ring slot is genuinely free again.
    - **Full barrier** — the arrival sits on ``ProducerCommit`` for pipeline
      types whose commit really arrives, and on the transfer for producer
      types whose commit is a no-op.  A fork group's commit fans out onto the
      members' full barriers.
    """
    full = step.full_slot
    empty = step.empty_slot

    if (
        full == _SLOTLESS
        and empty == _SLOTLESS
        and not step.group_full_arrivals
        and not step.group_empty_arrivals
    ):
        return barriers, None

    values = list(barriers)

    if step.arrives_on_full and full != _SLOTLESS:
        record = values[full * _BARRIER_FIELDS : (full + 1) * _BARRIER_FIELDS]
        _arrive(record, _B_FULL_PHASE, _B_FULL_ARRIVALS, step.full_expected)
        values[full * _BARRIER_FIELDS : (full + 1) * _BARRIER_FIELDS] = record

    for slot, expected in step.group_full_arrivals:
        record = values[slot * _BARRIER_FIELDS : (slot + 1) * _BARRIER_FIELDS]
        _arrive(record, _B_FULL_PHASE, _B_FULL_ARRIVALS, expected)
        values[slot * _BARRIER_FIELDS : (slot + 1) * _BARRIER_FIELDS] = record

    if step.arrives_on_empty and empty != _SLOTLESS:
        record = values[empty * _BARRIER_FIELDS : (empty + 1) * _BARRIER_FIELDS]
        _arrive(record, _B_EMPTY_PHASE, _B_EMPTY_ARRIVALS, step.empty_expected)
        values[empty * _BARRIER_FIELDS : (empty + 1) * _BARRIER_FIELDS] = record

    for slot, expected in step.group_empty_arrivals:
        record = values[slot * _BARRIER_FIELDS : (slot + 1) * _BARRIER_FIELDS]
        _arrive(record, _B_EMPTY_PHASE, _B_EMPTY_ARRIVALS, expected)
        values[slot * _BARRIER_FIELDS : (slot + 1) * _BARRIER_FIELDS] = record

    return tuple(values), None


class _HeldStateTracker:
    """Apply producer/consumer ownership-state transitions.

    The checker stores one entry per tracked resource slot and task.  The
    absence of an entry is the ``nothing`` state.  Stored states are:

    - ``prod_held``: producer owns an empty slot after ``ProducerAcquire``.
    - ``prod``: producer-side data/access is live after ``ProducerWork``.
    - ``cons_held``: consumer owns the produced slot after ``ConsumerWait``.
    - ``cons``: consumer-side read is live after ``ConsumerWork``.

    Race matrix used by ``_find_races_at_state``::

                  nothing  prod_held  prod  cons_held  cons
        nothing      no       no       no      no       no
        prod_held    no       no       no      no       no
        prod         no       no       yes     yes      yes
        cons_held    no       no       yes     no       no
        cons         no       no       yes     no       no

    Equivalently, ``prod_held`` does not race because it is only a
    reservation.  Two overlapping stored/access states race once at
    least one side is producer work (``prod``).  Consumer-side states do
    not race with each other because they model read ownership/access.

    Normal pipeline transition matrix::

        nothing --ProducerAcquire--> prod_held
        prod_held --ProducerWork--> prod
        prod/prod_held --ConsumerWait--> cons_held
        cons_held --ConsumerWork--> cons
        cons/cons_held --ConsumerRelease--> nothing

    DMA-consumer resources differ at release time: ``ConsumerRelease``
    does not free ``cons``/``cons_held``.  The state is cleared by a
    later paired completion wait or by the next ``ProducerAcquire`` for
    the same slot.

    Non-pipelined work has no acquire/wait/release ownership interval.
    ``_explode_sync_work`` creates a synthetic two-step active window for
    those work calls, and this tracker removes the synthetic state at the
    last consecutive expanded step.
    """

    def __init__(self, completion: _ConsumerCompletionMetadata):
        self.completion = completion

    @staticmethod
    def _copy_entries_if_shared(
        new_held: HeldMap,
        original_held: HeldMap,
        rid: int,
    ) -> HeldMap:
        if rid in new_held and new_held[rid] is original_held.get(rid):
            return _cow_held(new_held, rid)
        return new_held

    def apply(
        self,
        held: HeldMap,
        step: _StepInfo,
        task_idx: int,
    ) -> HeldMap:
        """Return ownership state after executing one schedule step."""
        if not step.needs_held_update:
            return held

        new_held = _cow_held(held)
        if step.is_consumer_release and step.is_merge_group:
            new_held = self._on_merge_group_release(new_held, held, step, task_idx)
        if step.is_consumer_wait and step.is_fused_merge_group:
            new_held = self._on_fused_merge_wait(new_held, held, step, task_idx)
        if step.in_alias:
            if step.is_producer_acquire:
                new_held = self._on_producer_acquire(new_held, held, step, task_idx)
            elif step.is_producer_work:
                new_held = self._on_producer_work(new_held, held, step, task_idx)
            elif step.is_consumer_wait:
                new_held = self._on_consumer_wait(new_held, held, step, task_idx)
            elif step.is_consumer_work:
                new_held = self._on_consumer_work(new_held, held, step, task_idx)
            elif step.is_consumer_release:
                new_held = self._on_consumer_release(new_held, held, step, task_idx)

        if step.is_producer_commit and step.completion_wait_rids:
            new_held = self._on_completion_commit(new_held, step)
        if step.is_consumer_wait and step.completion_wait_rids:
            new_held = self._on_completion_wait(new_held, step)

        return new_held

    def _on_merge_group_release(
        self,
        new_held: HeldMap,
        held: HeldMap,
        step: _StepInfo,
        task_idx: int,
    ) -> HeldMap:
        for mid, member_slot in step.group_member_release_slots:
            if mid in self.completion.dma_consumer_rids:
                continue
            new_held = self._copy_entries_if_shared(new_held, held, mid)
            entries = new_held.get(mid, [])
            _pop_first_entry(
                entries,
                access_types=("cons", "cons_held"),
                task_idx=task_idx,
                slot=member_slot,
            )
            if not entries:
                new_held.pop(mid, None)
        return new_held

    def _on_fused_merge_wait(
        self,
        new_held: HeldMap,
        held: HeldMap,
        step: _StepInfo,
        task_idx: int,
    ) -> HeldMap:
        for mid, member_slot in step.group_member_wait_slots:
            if mid in self.completion.dma_consumer_rids:
                continue
            new_held = self._copy_entries_if_shared(new_held, held, mid)
            entries = new_held.setdefault(mid, [])
            _pop_last_entry(
                entries,
                access_types=("prod", "prod_held", "cons", "cons_held"),
                slot=member_slot,
            )
            entries.append(("cons_held", task_idx, member_slot, _UNTAGGED))
        return new_held

    def _on_producer_acquire(
        self,
        new_held: HeldMap,
        held: HeldMap,
        step: _StepInfo,
        task_idx: int,
    ) -> HeldMap:
        rid = step.rid
        slot = step.producer_slot
        new_held = self._copy_entries_if_shared(new_held, held, rid)
        entries = new_held.setdefault(rid, [])
        if rid in self.completion.dma_consumer_rids:
            _pop_first_entry(
                entries,
                access_types=("cons", "cons_held"),
                slot=slot,
            )
        entries.append(("prod_held", task_idx, slot, _UNTAGGED))
        return new_held

    def _on_producer_work(
        self,
        new_held: HeldMap,
        held: HeldMap,
        step: _StepInfo,
        task_idx: int,
    ) -> HeldMap:
        rid = step.rid
        slot = step.producer_slot
        new_held = self._copy_entries_if_shared(new_held, held, rid)
        entries = new_held.setdefault(rid, [])
        replaced = False
        for j in range(len(entries)):
            if _entry_matches(
                entries[j],
                access_types=("prod_held",),
                task_idx=task_idx,
                slot=slot,
            ):
                entries[j] = ("prod", task_idx, slot, entries[j][3])
                replaced = True
                break
        if not replaced:
            entries.append(("prod", task_idx, slot, _UNTAGGED))
        if step.res.pipeline_config is None and not step.consecutive_same_work:
            _pop_first_entry(
                entries,
                access_types=("prod",),
                task_idx=task_idx,
                slot=slot,
            )
            if not entries:
                new_held.pop(rid, None)
        return new_held

    def _on_consumer_wait(
        self,
        new_held: HeldMap,
        held: HeldMap,
        step: _StepInfo,
        task_idx: int,
    ) -> HeldMap:
        rid = step.rid
        slot = step.consumer_slot
        new_held = self._copy_entries_if_shared(new_held, held, rid)
        entries = new_held.setdefault(rid, [])
        _pop_last_entry(
            entries,
            access_types=("prod", "prod_held", "cons", "cons_held"),
            slot=slot,
        )
        entries.append(("cons_held", task_idx, slot, _UNTAGGED))
        return new_held

    def _on_consumer_work(
        self,
        new_held: HeldMap,
        held: HeldMap,
        step: _StepInfo,
        task_idx: int,
    ) -> HeldMap:
        rid = step.rid
        slot = step.consumer_slot
        new_held = self._copy_entries_if_shared(new_held, held, rid)
        entries = new_held.setdefault(rid, [])
        next_access = "prod" if step.cons_work_phase == "cons_write_phase" else "cons"
        replaced = False
        for j in range(len(entries)):
            if _entry_matches(
                entries[j],
                access_types=("prod", "prod_held", "cons", "cons_held"),
                task_idx=task_idx,
                slot=slot,
            ):
                entries[j] = (next_access, task_idx, slot, entries[j][3])
                replaced = True
                break
        if not replaced:
            entries.append((next_access, task_idx, slot, _UNTAGGED))
        if step.res.pipeline_config is None and not step.consecutive_same_work:
            for j in range(len(entries)):
                if _entry_matches(
                    entries[j],
                    access_types=("cons", "prod"),
                    task_idx=task_idx,
                    slot=slot,
                ):
                    entries.pop(j)
                    break
            if not entries:
                new_held.pop(rid, None)
        return new_held

    def _on_consumer_release(
        self,
        new_held: HeldMap,
        held: HeldMap,
        step: _StepInfo,
        task_idx: int,
    ) -> HeldMap:
        rid = step.rid
        if rid in self.completion.dma_consumer_rids:
            return new_held
        slot = step.consumer_slot
        new_held = self._copy_entries_if_shared(new_held, held, rid)
        entries = new_held.get(rid, [])
        _pop_first_entry(
            entries,
            access_types=("cons", "cons_held"),
            task_idx=task_idx,
            slot=slot,
        )
        if not entries:
            new_held.pop(rid, None)
        return new_held

    def _on_completion_commit(
        self,
        new_held: HeldMap,
        step: _StepInfo,
    ) -> HeldMap:
        """Tag paired reads preceding this commit with its generation."""
        gen = step.commit_wait_gen
        for dma_rid in step.completion_wait_rids:
            entries = new_held.get(dma_rid)
            if not entries:
                continue
            new_held[dma_rid] = [
                (
                    (entry[0], entry[1], entry[2], gen)
                    if entry[0] in ("cons", "cons_held") and entry[3] == _UNTAGGED
                    else entry
                )
                for entry in entries
            ]
        return new_held

    def _on_completion_wait(
        self,
        new_held: HeldMap,
        step: _StepInfo,
    ) -> HeldMap:
        """Clear paired reads tagged with the generation this wait observes."""
        gen = step.commit_wait_gen
        for completed_rid in step.completion_wait_rids:
            entries = new_held.get(completed_rid)
            if not entries:
                continue
            kept = [
                entry
                for entry in entries
                if not (entry[0] in ("cons", "cons_held") and entry[3] == gen)
            ]
            if kept:
                new_held[completed_rid] = kept
            else:
                new_held.pop(completed_rid, None)
        return new_held


def _visited_key(state: _BfsState, context: _CheckerContext) -> int | tuple:
    """Visited-set key for one BFS state.

    The cursor tuple, packed into one int, is the whole logical state: barrier
    and held state are deterministic functions of it.  ``cursor_only_visited``
    switches to a key that spells them out, which turns that claim into
    something a test can check (see :func:`check_all_interleavings`).
    """
    if context.cursor_only_visited:
        return state.cursor_key
    return _make_state_key(state.cursors, state.barriers, state.held)


def _step_op_desc(step: _StepInfo) -> str:
    """Return a ``Op(resource)`` label for traces and diagnostics."""
    assert step.stage is not None
    return f"{step.stage.name}({step.res.name})"


def _flat_op_label(entry: FlatScheduleOp) -> str:
    """Return the schedule-stage or state-op name for a flattened entry."""
    if entry.schedule_stage is not None:
        return entry.schedule_stage.name
    advance = entry.state_advance
    if advance is not None:
        return "StateAdvance"
    return "?"


def _step_is_enabled(state: _BfsState, step: _StepInfo) -> bool:
    """Return whether ``step`` can execute in ``state``.

    Two shapes can block, and both compare a barrier phase against the phase
    the step's own software cursor names:

    - ``ConsumerWait`` reads the full barrier phase.
    - ``ProducerAcquire`` reads the empty barrier's phase.
    """
    if step.gate_kind == _GATE_NONE or step.gate_slot == _SLOTLESS:
        return True
    base = step.gate_slot * _BARRIER_FIELDS
    return state.barriers[base + _GATE_FIELD[step.gate_kind]] != step.gate_phase


def _compute_enabled_tasks(
    state: _BfsState,
    context: _CheckerContext,
) -> _EnabledTasks:
    """Return the enabled tasks and whether all schedules are complete."""
    enabled_mask = 0
    all_done = True
    for task_idx in range(context.n_tasks):
        cursor = state.cursors[task_idx]
        if cursor >= context.schedule_lens[task_idx]:
            continue
        all_done = False
        step = context.schedule_steps[task_idx][cursor]
        assert step is not None
        if _step_is_enabled(state, step):
            enabled_mask |= 1 << task_idx
    return _EnabledTasks(enabled_mask, all_done)


def _blocked_tasks_for_deadlock(
    state: _BfsState,
    context: _CheckerContext,
) -> Tuple[List[Tuple[str, str, str]], List[BlockedTaskInfo]]:
    """Describe every task whose next step fails its phase or window compare."""
    blocked_info: List[Tuple[str, str, str]] = []
    blocked_details: List[BlockedTaskInfo] = []
    for task_idx in range(context.n_tasks):
        cursor = state.cursors[task_idx]
        if cursor >= context.schedule_lens[task_idx]:
            continue
        step = context.schedule_steps[task_idx][cursor]
        assert step is not None
        if _step_is_enabled(state, step):
            continue
        assert step.stage is not None
        base = step.gate_slot * _BARRIER_FIELDS
        expected = step.gate_phase
        observed = state.barriers[base + _GATE_FIELD[step.gate_kind]]
        if step.gate_kind == _GATE_EMPTY:
            kind = "empty"
            pending = state.barriers[base + _B_EMPTY_ARRIVALS]
            expected_arrivals = step.empty_expected
        else:
            kind = "full"
            pending = state.barriers[base + _B_FULL_ARRIVALS]
            expected_arrivals = step.full_expected
        blocked_info.append(
            (context.task_names[task_idx], step.res.name, step.stage.name)
        )
        blocked_details.append(
            BlockedTaskInfo(
                task_name=context.task_names[task_idx],
                resource_name=step.res.name,
                stage_name=step.stage.name,
                barrier_kind=kind,
                physical_stage=step.physical_stage,
                expected_phase=expected,
                observed_phase=observed,
                window_state="",
                pending_arrivals=pending,
                expected_arrivals=expected_arrivals,
                domain_interleaved=step.rid in context.domain_rids,
                available_stage_counts=tuple(
                    (stage, 1)
                    for stage in range(step.res.pipeline_config.num_stages)
                    if state.barriers[
                        (
                            context.schedule_steps[task_idx][cursor].gate_slot
                            - step.physical_stage
                            + stage
                        )
                        * _BARRIER_FIELDS
                        + _GATE_FIELD[step.gate_kind]
                    ]
                    != expected
                )
                if step.res.pipeline_config is not None
                else (),
            )
        )
    return blocked_info, blocked_details


def _next_point_accesses(
    state: _BfsState,
    enabled: _EnabledTasks,
    context: _CheckerContext,
) -> List[PointAccess]:
    """Collect point accesses from enabled tasks for race checking."""
    next_point_ops: List[PointAccess] = []
    for task_idx in range(context.n_tasks):
        if not enabled.contains(task_idx):
            continue
        cursor = state.cursors[task_idx]
        step = context.schedule_steps[task_idx][cursor]
        assert step is not None
        if not step.in_alias:
            continue
        if step.is_point_write:
            next_point_ops.append((step.rid, step.producer_slot, "prod", task_idx))
        elif step.is_point_read:
            access = "prod" if step.cons_work_phase == "cons_write_phase" else "cons"
            next_point_ops.append((step.rid, step.consumer_slot, access, task_idx))
    return next_point_ops


def _advance_one_task(
    state: _BfsState,
    task_idx: int,
    context: _CheckerContext,
    held_tracker: _HeldStateTracker,
    verbose: bool,
) -> Tuple[_BfsState, Optional[str]]:
    """Build the successor reached by executing one enabled task step.

    Returns the successor and any barrier-protocol error the step raised.
    """
    cursor = state.cursors[task_idx]
    step = context.schedule_steps[task_idx][cursor]
    assert step is not None

    error: Optional[str] = None
    if step.has_barrier_transition:
        new_barriers, error = _apply_barrier_transition(step, state.barriers)
    else:
        new_barriers = state.barriers

    if step.needs_held_update:
        new_held = held_tracker.apply(state.held, step, task_idx)
    else:
        new_held = state.held
    new_pdl = (
        state.has_executed_pdl_wait
        or step.is_pdl_wait
        or context.assume_pdl_wait_completed
    )

    new_cursors = list(state.cursors)
    new_cursors[task_idx] = cursor + 1
    new_cursors_t = tuple(new_cursors)

    if verbose:
        op_desc = _step_op_desc(step)
        new_path = (state.path or []) + [(context.task_names[task_idx], op_desc)]
    else:
        new_path = None

    return (
        _BfsState(
            cursors=new_cursors_t,
            cursor_key=state.cursor_key + context.cursor_strides[task_idx],
            barriers=new_barriers,
            held=new_held,
            path=new_path,
            has_executed_pdl_wait=new_pdl,
        ),
        error,
    )


class _VerboseReporter:
    """Verbose diagnostic formatting for the exhaustive checker."""

    def __init__(
        self,
        task_names: List[str],
        id_to_res: Dict[int, MemoryResource],
    ):
        self.task_names = task_names
        self.id_to_res = id_to_res

    def format_held(self, held: HeldMap) -> str:
        """Format the held-resource map for verbose diagnostics."""
        if not held:
            return "{}"
        parts = []
        for rid, entries in held.items():
            rname = self.id_to_res[rid].name if rid in self.id_to_res else f"?{rid}"
            for access, tid, slot, gen in sorted(entries):
                slot_suffix = "" if slot == _SLOTLESS else f"[s{slot}]"
                gen_suffix = "" if gen == _UNTAGGED else f"(g{gen})"
                parts.append(
                    f"{rname}{slot_suffix}:{access}{gen_suffix}@{self.task_names[tid]}"
                )
        return "{" + ", ".join(parts) + "}"

    def print_timeline(
        self,
        path: List[Tuple[str, str]],
        suffix_label: str = "",
    ) -> None:
        """Print time-ordered execution history as a columnar table."""
        if not path:
            print("  timeline: (initial state)")
            if suffix_label:
                print(f"  {suffix_label}")
            return

        col_width = (
            max(
                max((len(op) for _, op in path), default=0),
                max((len(n) for n in self.task_names), default=0),
                5,
            )
            + 2
        )

        header = "    t  "
        sep = "    -  "
        for name in self.task_names:
            header += name.ljust(col_width)
            sep += ("-" * len(name)).ljust(col_width)
        print(f"  timeline ({len(path)} steps):")
        print(header)
        print(sep)

        name_to_idx = {n: i for i, n in enumerate(self.task_names)}
        for t, (tname, op_desc) in enumerate(path):
            row = f"    {t:<3d}"
            active_col = name_to_idx.get(tname, -1)
            for col in range(len(self.task_names)):
                if col == active_col:
                    row += op_desc.ljust(col_width)
                else:
                    row += ".".ljust(col_width)
            print(row)

        if suffix_label:
            print(f"  {suffix_label}")

    def print_header(
        self,
        schedules: List[list],
        skipped_tile: bool,
        alias_map: Dict[int, Set[int]],
    ) -> None:
        print("=" * 72)
        print("Exhaustive interleaving checker - BFS exploration")
        if skipped_tile:
            print("Variant: skipped-tile execution")
        print("=" * 72)
        for task_idx, task_name in enumerate(self.task_names):
            sched_desc = ", ".join(
                f"{_flat_op_label(e)}({e.resource.name})" for e in schedules[task_idx]
            )
            print(f"  Task {task_idx} ({task_name}): [{sched_desc}]")
        if alias_map:
            print("  Alias pairs:")
            seen_pairs: set = set()
            for rid_a, aliases in alias_map.items():
                for rid_b in aliases:
                    pair = (min(rid_a, rid_b), max(rid_a, rid_b))
                    if pair in seen_pairs:
                        continue
                    seen_pairs.add(pair)
                    na = self.id_to_res[rid_a].name if rid_a in self.id_to_res else "?"
                    nb = self.id_to_res[rid_b].name if rid_b in self.id_to_res else "?"
                    print(f"    {na} <-> {nb}")
        print("-" * 72)

    def print_complete(
        self,
        state_no: int,
        cursors: tuple,
        path: Optional[List[Tuple[str, str]]],
    ) -> None:
        print(f"State #{state_no}  cursors={cursors}  COMPLETE")
        self.print_timeline(path or [])
        print()

    def print_deadlock(
        self,
        state_no: int,
        cursors: tuple,
        held: HeldMap,
        path: Optional[List[Tuple[str, str]]],
        blocked_info: List[Tuple[str, str, str]],
        blocked_details: Optional[List[BlockedTaskInfo]] = None,
    ) -> None:
        if blocked_details:
            blocked_desc = "; ".join(detail.format() for detail in blocked_details)
        else:
            blocked_desc = ", ".join(
                f"{name} on {resource}.{stage}"
                for name, resource, stage in blocked_info
            )
        print(f"State #{state_no}  cursors={cursors}  held={self.format_held(held)}")
        self.print_timeline(path or [], suffix_label=f"*** DEADLOCK: {blocked_desc}")
        print()

    def print_races(
        self,
        state_no: int,
        cursors: tuple,
        held: HeldMap,
        path: Optional[List[Tuple[str, str]]],
        state_races: List[RaceInfo],
    ) -> None:
        race_descs = "; ".join(
            f"{rc.writer_task} writes {rc.writer_resource}"
            f" vs {rc.victim_task} {rc.victim_access} "
            f"{rc.victim_resource} ({rc.overlap_desc})"
            for rc in state_races
        )
        print(f"State #{state_no}  cursors={cursors}  held={self.format_held(held)}")
        self.print_timeline(path or [], suffix_label=f"*** RACE: {race_descs}")
        print()

    def print_pdl_order(
        self,
        state_no: int,
        cursors: tuple,
        held: HeldMap,
        path: Optional[List[Tuple[str, str]]],
    ) -> None:
        print(f"State #{state_no}  cursors={cursors}  held={self.format_held(held)}")
        self.print_timeline(
            path or [],
            suffix_label=(
                "*** PDL ORDER: launch_griddep can execute before any wait_griddep"
            ),
        )
        print()

    def print_protocol(
        self,
        state_no: int,
        cursors: tuple,
        held: HeldMap,
        path: Optional[List[Tuple[str, str]]],
        message: str,
    ) -> None:
        print(f"State #{state_no}  cursors={cursors}  held={self.format_held(held)}")
        self.print_timeline(path or [], suffix_label=f"*** PROTOCOL: {message}")
        print()

    def print_summary(
        self,
        states_explored: int,
        complete_count: int,
        deadlock_count: int,
        race_count: int,
        pdl_order_count: int,
        protocol_count: int,
        hit_state_limit: bool,
        max_states: int,
        is_safe: bool,
        exit_caveat: str | None = None,
    ) -> None:
        print("=" * 72)
        print(
            f"BFS complete: {states_explored} states explored, "
            f"{complete_count} complete, "
            f"{deadlock_count} deadlock(s), {race_count} race(s), "
            f"{pdl_order_count} PDL order violation(s), "
            f"{protocol_count} V1 protocol error(s)"
        )
        if hit_state_limit:
            print(
                f"WARNING: exhaustive checker hit max_states={max_states} "
                "before completing the search; no concrete issue was found. "
                "Increase max_states or reduce the validated schedule "
                "size/main-loop length for a complete proof."
            )
        if is_safe:
            print("Result: SAFE")
        else:
            print("Result: UNSAFE")
            if exit_caveat is not None:
                print(exit_caveat)
        print("=" * 72)


def check_all_interleavings(
    tasks: List[Task],
    alias_map: Optional[Dict[int, Set[int]]] = None,
    prod_alias_map: Optional[Dict[int, Set[int]]] = None,
    cons_alias_map: Optional[Dict[int, Set[int]]] = None,
    overlap_descs: Optional[Dict[Tuple[int, int], str]] = None,
    max_states: int = 1_000_000,
    num_tiles: int = 1,
    skipped_tile: bool = False,
    assume_pdl_wait_completed: bool = False,
    verbose: bool = False,
    opaque_assignment: OpaqueAssignmentLike = None,
    early_exit: bool = True,
    cursor_only_visited: bool = False,
) -> CheckResult:
    """Explore all valid schedule interleavings via optimized BFS.

    ``opaque_assignment`` may be a single dict, a while-loop assignment
    sequence, or an :class:`OpaqueAssignmentScenario`.  Partner tasks
    without a while loop observe that scenario's ``default_assignment``.

    ``cursor_only_visited`` selects the visited-set key, and exists to make one
    modelling claim testable.  The claim is that the tuple of per-task cursor
    positions *is* the state: barrier phases, arrival counts and held-resource
    ownership are all determined by it, because every arrival and every
    ownership transfer sits at a fixed offset in some task's schedule.  The
    default packs those positions into one int, which is the cheapest possible
    key.  Passing ``False`` builds a key that also contains the barrier vector
    and the held map, which can only *split* states the compact key merged.  So
    the two keys agreeing on ``states_explored`` is evidence the claim holds,
    and a schedule where ``False`` explores more states has found a place where
    the checker's shared state drifted out of step with the cursors — a bug in
    the checker, not in the schedule.  ``test_merge_overlapping_members_race``
    asserts that agreement; keep it that way and this parameter stays honest.
    """
    if not tasks:
        return CheckResult([], [], 0, 0, True)

    # A verify_model is evaluated from the cursor the first tile enters with.
    # Replaying the work-tile body again would reuse that answer, so the
    # persistent two-tile check drops to one tile instead of refusing to run.
    if num_tiles > 1 and any(
        (loop := find_while_true_loop(task)) is not None
        and collect_cursor_models(task, loop)
        for task in tasks
    ):
        num_tiles = 1

    resources = _collect_resources(tasks)
    dynamic_domain_fallback = dynamic_domain_fallback_for(tasks)
    schedules = [
        expand_task(
            t,
            skipped_tile=skipped_tile,
            opaque_assignment=opaque_assignment,
            num_tiles=num_tiles,
            dynamic_domain_fallback=dynamic_domain_fallback,
        )
        for t in tasks
    ]

    if alias_map is None:
        alias_map, prod_alias_map, cons_alias_map, overlap_descs = build_alias_info(
            resources
        )
    if prod_alias_map is None:
        prod_alias_map = {}
    if cons_alias_map is None:
        cons_alias_map = {}
    if overlap_descs is None:
        overlap_descs = {}

    id_to_res: Dict[int, MemoryResource] = {id(r): r for r in resources}

    # Add pipeline groups to the id_to_res map.
    for res in resources:
        pg = getattr(res, "pipeline_group", None)
        if pg is not None:
            id_to_res[id(pg)] = pg

    completion = _build_consumer_completion_metadata(tasks, resources)

    schedules = _explode_sync_work(schedules)

    # Domain-interleaved resources are those whose ring slot is a function of
    # the lane a task drives, so two lanes touching the same resource are on
    # different physical stages and must not be treated as racing.
    domain_rids = _domain_interleaved_resource_ids(tasks)
    filtered_schedules: List[List[FlatScheduleOp]] = []
    for task, schedule_entries in zip(tasks, schedules):
        simulated, _ = _simulate_cursors(task, schedule_entries)
        schedule_entries = [
            replace(entry, cursor_state=state)
            for entry, state in zip(schedule_entries, simulated)
        ]
        filtered_schedules.append(
            [entry for entry in schedule_entries if _keep_bfs_entry(entry)]
        )
    schedules = filtered_schedules

    task_names = [t.name for t in tasks]
    n_tasks = len(tasks)
    schedule_lens = [len(s) for s in schedules]
    cursor_strides: List[int] = []
    cursor_stride = 1
    for schedule_len in schedule_lens:
        cursor_strides.append(cursor_stride)
        cursor_stride *= schedule_len + 1

    initial_cursors = tuple(0 for _ in range(n_tasks))

    # Expected arrival counts per barrier: how many tasks have to arrive before
    # a phase flips.  Domain-lane tasks are the exception and are pinned to one
    # rather than summed, because each lane owns a strided subset of the ring
    # and so meets its partners on its own barrier records.
    _num_producers: Dict[int, int] = {}
    _num_consumers: Dict[int, int] = {}
    for task, sched in zip(tasks, schedules):
        for res in task.dst_resources:
            if _is_tracked(res) and res.pipeline_config is not None:
                rid = id(res)
                if not _count_independent_interleave_lane(
                    _num_producers,
                    rid,
                    task,
                    res,
                    ScheduleStage.ProducerCommit,
                ):
                    _num_producers[rid] = _num_producers.get(rid, 0) + 1

        releasing_resources: list[MemoryResource] = []
        for entry in sched:
            if entry.schedule_stage is not ScheduleStage.ConsumerRelease:
                continue
            if isinstance(entry.resource, PipelineGroup):
                releasing_resources.extend(entry.resource.members)
            else:
                releasing_resources.append(entry.resource)
        seen_releasers: Set[int] = set()
        for res in releasing_resources:
            if _is_tracked(res) and res.pipeline_config is not None:
                rid = id(res)
                if rid in seen_releasers:
                    continue
                seen_releasers.add(rid)
                if not _count_independent_interleave_lane(
                    _num_consumers,
                    rid,
                    task,
                    res,
                    ScheduleStage.ConsumerRelease,
                ):
                    _num_consumers[rid] = _num_consumers.get(rid, 0) + 1

    barrier_offsets, initial_barriers = _barrier_layout(resources, schedules)
    schedule_steps = _precompute_schedule_steps(
        schedules,
        alias_map,
        _num_producers,
        _num_consumers,
        completion.completion_wait_rids,
        barrier_offsets,
    )
    context = _CheckerContext(
        task_names=task_names,
        n_tasks=n_tasks,
        schedule_lens=schedule_lens,
        cursor_strides=cursor_strides,
        schedule_steps=schedule_steps,
        id_to_res=id_to_res,
        alias_map=alias_map,
        prod_alias_map=prod_alias_map,
        cons_alias_map=cons_alias_map,
        overlap_descs=overlap_descs,
        domain_rids=domain_rids,
        cursor_only_visited=cursor_only_visited,
        assume_pdl_wait_completed=assume_pdl_wait_completed,
    )
    held_tracker = _HeldStateTracker(completion)
    reporter = _VerboseReporter(task_names, id_to_res) if verbose else None

    if reporter is not None:
        reporter.print_header(schedules, skipped_tile, alias_map)

    empty_held: HeldMap = {}

    initial_pdl = assume_pdl_wait_completed
    initial_cursor_key = 0
    initial_state = _BfsState(
        cursors=initial_cursors,
        cursor_key=initial_cursor_key,
        barriers=initial_barriers,
        held=empty_held,
        path=[] if verbose else None,
        has_executed_pdl_wait=initial_pdl,
    )
    visited: Set[int | tuple] = {_visited_key(initial_state, context)}

    queue: deque[_BfsState] = deque()
    queue.append(initial_state)

    deadlocks: List[DeadlockInfo] = []
    races: List[RaceInfo] = []
    pdl_order_states: List[PdlOrderInfo] = []
    protocol_states: List[ProtocolErrorInfo] = []
    states_explored = 0
    complete_count = 0
    visited_add = visited.add
    enabled_indices_by_mask: Optional[List[Tuple[int, ...]]] = None
    if n_tasks <= 16:
        enabled_indices_by_mask = [
            tuple(idx for idx in range(n_tasks) if mask & (1 << idx))
            for mask in range(1 << n_tasks)
        ]

    while queue and states_explored < max_states:
        state = queue.popleft()
        cursors = state.cursors
        held = state.held
        path = state.path
        has_executed_pdl_wait = state.has_executed_pdl_wait
        states_explored += 1

        enabled = _compute_enabled_tasks(state, context)
        if alias_map:
            state_races = _find_races_at_state(
                held,
                _next_point_accesses(state, enabled, context),
                alias_map,
                prod_alias_map,
                cons_alias_map,
                overlap_descs,
                id_to_res,
                task_names,
                cursors,
                domain_rids,
            )
            if state_races:
                races.extend(state_races)
                if reporter is not None:
                    reporter.print_races(
                        states_explored,
                        cursors,
                        held,
                        path,
                        state_races,
                    )
                if early_exit:
                    break

        if enabled.all_done:
            complete_count += 1
            if reporter is not None:
                reporter.print_complete(states_explored, cursors, path)
            continue

        if not enabled.mask:
            blocked_info, blocked_details = _blocked_tasks_for_deadlock(state, context)
            deadlocks.append(
                DeadlockInfo(
                    cursors=cursors,
                    blocked_tasks=blocked_info,
                    blocked_details=blocked_details,
                )
            )
            if reporter is not None:
                reporter.print_deadlock(
                    states_explored,
                    cursors,
                    held,
                    path,
                    blocked_info,
                    blocked_details,
                )
            if early_exit:
                break
            continue

        stop_branching = False
        enabled_task_indices: Iterable[int]
        if enabled_indices_by_mask is not None:
            enabled_task_indices = enabled_indices_by_mask[enabled.mask]
        else:
            enabled_task_indices = range(n_tasks)
        for task_idx in enabled_task_indices:
            if enabled_indices_by_mask is None and not (enabled.mask & (1 << task_idx)):
                continue
            step = schedule_steps[task_idx][cursors[task_idx]]
            assert step is not None

            if step.is_pdl_launch and not has_executed_pdl_wait:
                pdl_order_states.append(
                    PdlOrderInfo(
                        cursors=cursors,
                        launch_task=task_names[task_idx],
                        launch_resource=step.res.name,
                    )
                )
                if reporter is not None:
                    reporter.print_pdl_order(states_explored, cursors, held, path)
                if early_exit:
                    stop_branching = True
                    break
                continue

            successor, protocol_error = _advance_one_task(
                state,
                task_idx,
                context,
                held_tracker,
                verbose,
            )
            if protocol_error is not None:
                protocol_states.append(
                    ProtocolErrorInfo(
                        cursors=cursors,
                        task_name=task_names[task_idx],
                        resource_name=step.res.name,
                        message=protocol_error,
                    )
                )
                if reporter is not None:
                    reporter.print_protocol(
                        states_explored, cursors, held, path, protocol_error
                    )
                if early_exit:
                    stop_branching = True
                    break
                continue

            state_key = _visited_key(successor, context)
            if state_key in visited:
                continue
            visited_add(state_key)
            queue.append(successor)

        if stop_branching or (
            early_exit and (pdl_order_states or deadlocks or races or protocol_states)
        ):
            break

    hit_state_limit = bool(queue and states_explored >= max_states)
    is_safe = (
        not deadlocks and not races and not pdl_order_states and not protocol_states
    )

    if reporter is not None:
        reporter.print_summary(
            states_explored,
            complete_count,
            len(deadlocks),
            len(races),
            len(pdl_order_states),
            len(protocol_states),
            hit_state_limit,
            max_states,
            is_safe,
            exit_caveat=None if is_safe else while_loop_exit_caveat(tasks),
        )

    return CheckResult(
        deadlock_states=deadlocks,
        race_states=races,
        states_explored=states_explored,
        complete_count=complete_count,
        is_safe=is_safe,
        pdl_order_states=pdl_order_states,
        protocol_states=protocol_states,
        hit_state_limit=hit_state_limit,
    )
