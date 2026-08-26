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
State includes per-task cursor positions into the expanded
(head + loop + tail) schedule plus dynamic protocol state (producer
credits, consumer credits, and held-resource access windows).  The
default visited-set key is a packed cursor vector; the dynamic protocol
state is deterministic from the cursor positions.  A defensive full-state
key remains available for debugging via ``cursor_only_visited=False``.

At each state the checker:

1. Computes which tasks are **enabled** (next op is non-blocking, or
   blocking with credits available).
2. If no task is enabled and work remains → **deadlock**.
3. Checks enabled PDL launch ops against the already-executed prefix; a
   launch is unsafe if no task has executed a PDL wait yet.
4. Checks held-resource windows and next point-access ops for aliasing
   **races** (conflicting concurrent accesses to shared physical storage).
5. For each enabled task, advances its cursor by one step, updates
   credits and held sets, and enqueues the successor state.

Synchronization rules mirror the ``TaskManager`` credit model:

- ``ConsumerWait(R)`` blocks until ``prod_credits[R] > 0``
  (a ``ProducerCommit`` has been recorded).
- ``ProducerAcquire(R)`` blocks until ``cons_credits[R] > 0``
  (a ``ConsumerRelease`` or initial pipeline stage is available).
- ``WorkQueue`` resources are not credit-tracked.

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

from collections import deque
from dataclasses import dataclass, field
from typing import Dict, Iterable, List, Optional, Set, Tuple

from .enums import PipelineGroupMode, PipelineType, ScheduleStage
from .resources import (
    MemoryResource,
    PdlLaunchBarrier,
    PdlWaitBarrier,
    PipelineGroup,
    WorkQueue,
)
from .task import Task
from .task_manager import (
    CreditKey,
    _count_independent_interleave_lane,
    _credit_key,
    _domain_interleaved_resource_ids,
    _precompute_stage_credit_keys,
    expand_loop,
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

HeldEntry = Tuple[str, int, int, int]
HeldMap = Dict[int, List[HeldEntry]]
PointAccess = Tuple[int, int, str, int]
CreditTuple = Tuple[int, ...]
TotalCounts = Dict[str, Dict[int, int]]


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


def _consumer_work_phase_entries(entry: tuple) -> List[tuple]:
    """Split slotless ConsumerWork into conservative write/read phases."""
    res, stage = entry[0], entry[1]
    if (
        not res.is_barrier
        and stage == ScheduleStage.ConsumerWork
        and res.pipeline_config is None
    ):
        return [(*entry, "cons_write_phase"), (*entry, "cons_read_phase")]
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
            res, stage = entry[0], entry[1]
            phase_entries = _consumer_work_phase_entries(entry)
            new_sched.extend(phase_entries)
            if len(phase_entries) > 1:
                continue

            if _should_double_nonpipeline_producer_work(res, stage):
                new_sched.append(entry)
        result.append(new_sched)
    return result


def _entry_consumer_work_phase(entry: tuple) -> str | None:
    """Return internal ConsumerWork phase tag, if present."""
    if not entry:
        return None
    tag = entry[-1]
    if isinstance(tag, str) and tag in {"cons_write_phase", "cons_read_phase"}:
        return tag
    return None


def _expand_skipped_tile(task: Task) -> List:
    """Expand the schedule executed by one skipped work-tile iteration.

    Runtime skipped-tile execution replays every non-skippable head/tail
    slot and omits the loop body.  Slots inside ``wtl.skippable()`` are
    omitted from the skipped-tile path.
    """
    skippable_head_slots: frozenset[tuple[int, ScheduleStage, int]] = getattr(
        task, "skippable_head_slots", frozenset()
    )
    skippable_tail_slots: frozenset[tuple[int, ScheduleStage, int]] = getattr(
        task, "skippable_tail_slots", frozenset()
    )
    head = [
        (res, stage, cid, "SH")
        for res, stage, cid, _lbl in task.head_schedule_list
        if (id(res), stage, cid) not in skippable_head_slots
    ]
    tail = [
        (res, stage, cid, "ST")
        for res, stage, cid, _lbl in task.tail_schedule_list
        if (id(res), stage, cid) not in skippable_tail_slots
    ]
    return head + tail


def _expand_task_for_check(
    task: Task,
    skipped_tile: bool,
    opaque_assignment: dict | None = None,
) -> List:
    """Return the schedule variant to explore for one logical tile."""
    if skipped_tile and getattr(task, "skip_if", None) is not None:
        return _expand_skipped_tile(task)
    return expand_loop(task, opaque_assignment=opaque_assignment)


# ── Result data classes ──────────────────────────────────────────────────


@dataclass(slots=True)
class BlockedTaskInfo:
    """Detailed reason one task is blocked in a deadlock state."""

    task_name: str
    resource_name: str
    stage_name: str
    credit_kind: str
    physical_stage: int
    available_stage_counts: Tuple[Tuple[int, int], ...]
    domain_interleaved: bool

    def format(self) -> str:
        """Return a human-readable one-line deadlock explanation."""
        base = (
            f"{self.task_name} blocked on {self.resource_name}.{self.stage_name} "
            f"waiting for {self.credit_kind}"
        )
        if self.domain_interleaved:
            base += f" at physical stage {self.physical_stage}"
        if not self.available_stage_counts:
            return f"{base}; no matching credit is available for this resource"

        stage_text = ", ".join(
            f"physical stage {stage} ({count} credit{'s' if count != 1 else ''})"
            for stage, count in self.available_stage_counts
        )
        if self.domain_interleaved:
            return f"{base}; available credits are on {stage_text}"
        return f"{base}; available credits: {stage_text}"


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


def _available_stage_counts(
    credits: Dict[CreditKey, int],
    resource_id: int,
) -> Tuple[Tuple[int, int], ...]:
    """Positive credit counts for one resource, grouped by physical stage."""
    return tuple(
        (stage, count)
        for (rid, stage), count in sorted(credits.items())
        if rid == resource_id and count > 0
    )


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
class CheckResult:
    """Aggregated results from ``check_all_interleavings``."""

    deadlock_states: List[DeadlockInfo]
    race_states: List[RaceInfo]
    states_explored: int
    complete_count: int
    is_safe: bool
    pdl_order_states: List[PdlOrderInfo] = field(default_factory=list)
    hit_state_limit: bool = False


@dataclass(slots=True)
class _BfsState:
    """One queued BFS state."""

    cursors: tuple
    cursor_key: int
    prod_credits: CreditTuple
    cons_credits: CreditTuple
    held: HeldMap
    total_counts: TotalCounts
    path: Optional[List[Tuple[str, str]]]
    has_executed_pdl_wait: bool


# ── Stage classifications ────────────────────────────────────────────────

_BLOCKING = frozenset({ScheduleStage.ConsumerWait, ScheduleStage.ProducerAcquire})
_POINT_WRITE = frozenset({ScheduleStage.ProducerWork})
_POINT_READ = frozenset({ScheduleStage.ConsumerWork})


# ── Helper functions ─────────────────────────────────────────────────────


def _is_pdl_wait_entry(entry: tuple) -> bool:
    """Return True when a schedule entry emits PDL wait."""
    return (
        isinstance(entry[0], PdlWaitBarrier) and entry[1] == ScheduleStage.ConsumerWork
    )


def _is_pdl_launch_entry(entry: tuple) -> bool:
    """Return True when a schedule entry emits PDL launch-dependents."""
    return (
        isinstance(entry[0], PdlLaunchBarrier)
        and entry[1] == ScheduleStage.ProducerWork
    )


def _is_tracked(res: MemoryResource) -> bool:
    """WorkQueue resources are exempt from credit tracking.

    PipelineGroups are credit-tracked (they carry a merged pipeline_config).
    Member resources whose barrier ops go through a group are NOT
    independently credit-tracked for barrier stages; their Work ops use
    the member's held-state but not credit tracking.
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


def _build_initial_cons_credits(
    resources: List[MemoryResource],
    domain_rids: Set[int],
) -> Dict[CreditKey, int]:
    """Each pipelined resource starts with ``num_stages`` empty-slot credits.

    Group members get their own independent credits (``PipelineGroup``
    objects themselves are skipped since they are not in schedules).

    Credits are keyed ``(id(res), stage)`` to match
    ``_precompute_stage_credit_keys``.  A domain-interleaved resource is
    split into one credit *per physical stage* (each ring slot starts with
    a single empty credit); every other resource keeps a single pool at
    stage ``0`` with ``num_stages`` credits.  The total empty count is
    unchanged either way.
    """
    credits: Dict[CreditKey, int] = {}
    for res in resources:
        if (
            res.pipeline_config is not None
            and not isinstance(res, WorkQueue)
            and not isinstance(res, PipelineGroup)
        ):
            rid = id(res)
            num_stages = res.pipeline_config.num_stages
            if rid in domain_rids:
                for stage in range(num_stages):
                    credits.setdefault((rid, stage), 1)
            else:
                credits.setdefault((rid, 0), num_stages)
    return credits


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


def _freeze_credits(credits: Dict[CreditKey, int]) -> tuple:
    """Canonicalize credit maps for visited-state keys.

    Keys are ``(id(resource), physical_stage)`` tuples, so a plain sort
    yields a stable canonical order.
    """
    return tuple(sorted((key, val) for key, val in credits.items() if val != 0))


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
    prod_credits: Dict[CreditKey, int],
    cons_credits: Dict[CreditKey, int],
    held: HeldMap,
) -> tuple:
    """Build visited-state key for BFS deduplication.

    Credits, held state, and event totals are all deterministic
    functions of the cursor positions, so ``cursors`` alone would
    suffice.  We keep credits and held in the key as a defensive
    measure — if a bug makes them diverge from the cursors the BFS
    will still explore both branches instead of silently dropping one.
    """
    return (
        cursors,
        _freeze_credits(prod_credits),
        _freeze_credits(cons_credits),
        _freeze_held(held),
    )


# ── Optimized BFS metadata ──────────────────────────────────────────────


@dataclass(frozen=True, slots=True)
class _StepInfo:
    """Precomputed metadata for one schedule position."""

    res: MemoryResource
    stage: ScheduleStage
    rid: int
    track: bool
    in_alias: bool
    is_pdl_wait: bool
    is_pdl_launch: bool
    cons_work_phase: Optional[str]
    consecutive_same_work: bool
    is_blocking: bool
    is_point_write: bool
    is_point_read: bool
    is_producer_commit: bool
    is_consumer_release: bool
    is_consumer_wait: bool
    is_producer_acquire: bool
    is_producer_work: bool
    is_consumer_work: bool
    has_credit_transition: bool
    needs_held_update: bool
    is_fork_group: bool
    is_merge_group: bool
    is_fused_merge_group: bool
    group_member_rids: Tuple[int, ...]
    credit_idx: int
    producer_count: int
    consumer_count: int
    group_member_prod_counts: Tuple[Tuple[int, int], ...]
    group_member_cons_counts: Tuple[Tuple[int, int], ...]
    producer_slot: int
    consumer_slot: int
    group_member_release_slots: Tuple[Tuple[int, int], ...]
    group_member_wait_slots: Tuple[Tuple[int, int], ...]
    completion_wait_rids: Tuple[int, ...]
    commit_wait_gen: int


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
    credit_key_order: List[CreditKey]
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


def _initial_interleave_lane(task: Task, stride: int) -> int:
    """Return the static pipeline lane represented by this task in the checker."""
    if stride <= 1:
        return 0
    if task._uses_domain_interleave_lane(stride) and isinstance(task.domain_start, int):
        return task.domain_start % stride
    # The checker models one logical task, not each participating warp.
    # Warp-local interleave lanes therefore use lane 0 as the representative
    # slot for held-state race tracking.
    return 0


def _precompute_schedule_steps(
    tasks: List[Task],
    schedules: List[list],
    alias_map: Dict[int, Set[int]],
    num_producers: Dict[int, int],
    num_consumers: Dict[int, int],
    completion_wait_rids: Dict[int, Set[int]],
    credit_keys: List[List[CreditKey]],
    credit_idx_by_key: Dict[CreditKey, int],
) -> List[List[Optional[_StepInfo]]]:
    """Build per-(task, cursor) metadata to avoid hot-loop unpacking."""
    out: List[List[Optional[_StepInfo]]] = []
    for task_idx, sched in enumerate(schedules):
        task = tasks[task_idx]
        producer_acquire_next: Dict[int, int] = {}
        producer_commit_next: Dict[int, int] = {}
        producer_current: Dict[int, int] = {}
        consumer_wait_next: Dict[int, int] = {}
        consumer_release_next: Dict[int, int] = {}
        consumer_current: Dict[int, int] = {}
        commit_gen: Dict[int, int] = {}
        wait_gen: Dict[int, int] = {}

        def _index_for(
            next_by_rid: Dict[int, int],
            resource: MemoryResource,
            stride: int,
        ) -> int:
            rid = id(resource)
            if rid not in next_by_rid:
                next_by_rid[rid] = _initial_interleave_lane(task, stride)
            return next_by_rid[rid]

        def _producer_acquire_slot(resource: MemoryResource) -> int:
            cfg = resource.pipeline_config
            if cfg is None:
                return _SLOTLESS
            idx = _index_for(
                producer_acquire_next,
                resource,
                cfg.producer_acquire_interleave_stride,
            )
            return idx % cfg.num_stages

        def _producer_commit_slot(resource: MemoryResource) -> int:
            cfg = resource.pipeline_config
            if cfg is None:
                return _SLOTLESS
            idx = _index_for(
                producer_commit_next,
                resource,
                cfg.producer_commit_interleave_stride,
            )
            return idx % cfg.num_stages

        def _consumer_wait_slot(resource: MemoryResource) -> int:
            cfg = resource.pipeline_config
            if cfg is None:
                return _SLOTLESS
            idx = _index_for(
                consumer_wait_next,
                resource,
                cfg.consumer_wait_interleave_stride,
            )
            return idx % cfg.num_stages

        def _consumer_release_slot(resource: MemoryResource) -> int:
            cfg = resource.pipeline_config
            if cfg is None:
                return _SLOTLESS
            idx = _index_for(
                consumer_release_next,
                resource,
                cfg.consumer_release_interleave_stride,
            )
            return idx % cfg.num_stages

        def _advance_producer_after_acquire(resource: MemoryResource) -> None:
            cfg = resource.pipeline_config
            if cfg is None or not cfg.advance_on_acquire:
                return
            rid = id(resource)
            producer_acquire_next[rid] = (
                _index_for(
                    producer_acquire_next,
                    resource,
                    cfg.producer_acquire_interleave_stride,
                )
                + cfg.producer_acquire_interleave_stride
            )

        def _advance_producer_after_commit(resource: MemoryResource) -> None:
            cfg = resource.pipeline_config
            if cfg is None:
                return
            if cfg.advance_on_acquire:
                rid = id(resource)
                producer_commit_next[rid] = (
                    _index_for(
                        producer_commit_next,
                        resource,
                        cfg.producer_commit_interleave_stride,
                    )
                    + cfg.producer_commit_interleave_stride
                )
            else:
                rid = id(resource)
                producer_acquire_next[rid] = (
                    _index_for(
                        producer_acquire_next,
                        resource,
                        cfg.producer_acquire_interleave_stride,
                    )
                    + cfg.producer_acquire_interleave_stride
                )

        def _advance_consumer_after_wait(resource: MemoryResource) -> None:
            cfg = resource.pipeline_config
            if cfg is None or not cfg.advance_on_wait:
                return
            rid = id(resource)
            consumer_wait_next[rid] = (
                _index_for(
                    consumer_wait_next,
                    resource,
                    cfg.consumer_wait_interleave_stride,
                )
                + cfg.consumer_wait_interleave_stride
            )

        def _advance_consumer_after_release(resource: MemoryResource) -> None:
            cfg = resource.pipeline_config
            if cfg is None:
                return
            if cfg.advance_on_wait:
                rid = id(resource)
                consumer_release_next[rid] = (
                    _index_for(
                        consumer_release_next,
                        resource,
                        cfg.consumer_release_interleave_stride,
                    )
                    + cfg.consumer_release_interleave_stride
                )
            else:
                rid = id(resource)
                consumer_wait_next[rid] = (
                    _index_for(
                        consumer_wait_next,
                        resource,
                        cfg.consumer_wait_interleave_stride,
                    )
                    + cfg.consumer_wait_interleave_stride
                )

        steps: List[Optional[_StepInfo]] = []
        for c, entry in enumerate(sched):
            res, stage = entry[0], entry[1]
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
                    and id(sched[next_c][0]) == rid
                    and sched[next_c][1] == stage
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
            is_fused_merge_producer = (
                pg is not None and pg.mode == PipelineGroupMode.FusedMerge
            )
            is_blocking = stage in _BLOCKING
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
                        is_blocking
                        or is_point_write
                        or is_point_read
                        or is_consumer_release
                    )
                )
                or is_completion_wait
                or is_completion_commit
            )
            group_member_prod_counts = tuple(
                (credit_idx_by_key[(mid, 0)], num_producers.get(mid, 1))
                for mid in group_member_rids
            )
            group_member_cons_counts = tuple(
                (credit_idx_by_key[(mid, 0)], num_consumers.get(mid, 1))
                for mid in group_member_rids
            )

            producer_slot = _SLOTLESS
            consumer_slot = _SLOTLESS
            group_member_release_slots: Tuple[Tuple[int, int], ...] = ()
            group_member_wait_slots: Tuple[Tuple[int, int], ...] = ()
            if res.pipeline_config is not None:
                if is_producer_acquire:
                    producer_slot = _producer_acquire_slot(res)
                    producer_current[rid] = producer_slot
                elif is_producer_work:
                    producer_slot = producer_current.get(
                        rid,
                        (
                            _producer_commit_slot(res)
                            if res.pipeline_config.advance_on_acquire
                            else _producer_acquire_slot(res)
                        ),
                    )
                elif is_producer_commit:
                    producer_slot = (
                        _producer_commit_slot(res)
                        if res.pipeline_config.advance_on_acquire
                        else producer_current.get(rid, _producer_acquire_slot(res))
                    )

                if is_consumer_wait:
                    consumer_slot = _consumer_wait_slot(res)
                    consumer_current[rid] = consumer_slot
                elif is_consumer_work:
                    consumer_slot = consumer_current.get(rid, _consumer_wait_slot(res))
                elif is_consumer_release:
                    consumer_slot = (
                        _consumer_release_slot(res)
                        if res.pipeline_config.advance_on_wait
                        else consumer_current.get(rid, _consumer_wait_slot(res))
                    )

            if is_merge_group and is_consumer_release:
                group_member_release_slots = tuple(
                    (
                        id(member),
                        (
                            _consumer_release_slot(member)
                            if member.pipeline_config is not None
                            and member.pipeline_config.advance_on_wait
                            else consumer_current.get(
                                id(member),
                                _consumer_wait_slot(member),
                            )
                        ),
                    )
                    for member in res.members
                )

            if is_fused_merge_group and is_consumer_wait:
                group_member_wait_slots = tuple(
                    (
                        id(member),
                        (
                            _consumer_release_slot(member)
                            if member.pipeline_config.advance_on_wait
                            else _consumer_wait_slot(member)
                        ),
                    )
                    for member in res.members
                    if id(member) in alias_map
                )

            producer_count = num_producers.get(rid, 1)
            # FusedMerge: acquire counts the res, commit counts the group.
            if is_fused_merge_producer and is_producer_commit:
                assert pg is not None
                producer_count = len(pg.members)

            steps.append(
                _StepInfo(
                    res=res,
                    stage=stage,
                    rid=rid,
                    track=track,
                    in_alias=in_alias,
                    is_pdl_wait=_is_pdl_wait_entry(entry),
                    is_pdl_launch=_is_pdl_launch_entry(entry),
                    cons_work_phase=_entry_consumer_work_phase(entry),
                    consecutive_same_work=consecutive,
                    is_blocking=is_blocking,
                    is_point_write=is_point_write,
                    is_point_read=is_point_read,
                    is_producer_commit=is_producer_commit,
                    is_consumer_release=is_consumer_release,
                    is_consumer_wait=is_consumer_wait,
                    is_producer_acquire=is_producer_acquire,
                    is_producer_work=is_producer_work,
                    is_consumer_work=is_consumer_work,
                    has_credit_transition=track
                    and (
                        is_producer_commit
                        or is_consumer_release
                        or is_consumer_wait
                        or is_producer_acquire
                    ),
                    needs_held_update=needs_held_update,
                    is_fork_group=is_fork_group,
                    is_merge_group=is_merge_group,
                    is_fused_merge_group=is_fused_merge_group,
                    group_member_rids=group_member_rids,
                    credit_idx=credit_idx_by_key.get(credit_keys[task_idx][c], -1),
                    producer_count=producer_count,
                    consumer_count=num_consumers.get(rid, 1),
                    group_member_prod_counts=group_member_prod_counts,
                    group_member_cons_counts=group_member_cons_counts,
                    producer_slot=producer_slot,
                    consumer_slot=consumer_slot,
                    group_member_release_slots=group_member_release_slots,
                    group_member_wait_slots=group_member_wait_slots,
                    completion_wait_rids=tuple(completion_wait_rids.get(rid, ())),
                    commit_wait_gen=commit_wait_gen,
                )
            )
            if is_producer_acquire:
                _advance_producer_after_acquire(res)
            elif is_producer_commit:
                if is_fork_group:
                    for member in res.members:
                        _advance_producer_after_commit(member)
                else:
                    _advance_producer_after_commit(res)

            if is_consumer_wait:
                _advance_consumer_after_wait(res)
            elif is_consumer_release:
                if is_merge_group:
                    for member in res.members:
                        _advance_consumer_after_release(member)
                else:
                    _advance_consumer_after_release(res)
        out.append(steps)
    return out


def _cow_total_bucket(
    totals: Dict[str, Dict[int, int]],
    bucket_name: str,
) -> Tuple[Dict[str, Dict[int, int]], Dict[int, int]]:
    """Copy only one total-count bucket for multi-lane credit accounting."""
    new_totals = dict(totals)
    bucket = dict(totals[bucket_name])
    new_totals[bucket_name] = bucket
    return new_totals, bucket


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


def _apply_credit_transition(
    step: _StepInfo,
    prod_credits: CreditTuple,
    cons_credits: CreditTuple,
    total_counts: TotalCounts,
) -> Tuple[CreditTuple, CreditTuple, TotalCounts]:
    """Apply producer/consumer credit effects for one schedule step."""
    if not step.track:
        return prod_credits, cons_credits, total_counts

    new_prod = prod_credits
    new_cons = cons_credits
    new_totals = total_counts
    if step.is_producer_commit:
        new_prod_list = list(prod_credits)
        if step.is_fork_group:
            commit_counts: Optional[Dict[int, int]] = None
            for midx, n_prod in step.group_member_prod_counts:
                if n_prod == 1:
                    new_prod_list[midx] += 1
                else:
                    if commit_counts is None:
                        new_totals, commit_counts = _cow_total_bucket(
                            total_counts, "commits"
                        )
                    commit_counts[midx] = commit_counts.get(midx, 0) + 1
                    if commit_counts[midx] % n_prod == 0:
                        new_prod_list[midx] += 1
        else:
            n_prod = step.producer_count
            cidx = step.credit_idx
            if n_prod == 1:
                new_prod_list[cidx] += 1
            else:
                new_totals, commit_counts = _cow_total_bucket(total_counts, "commits")
                commit_counts[cidx] = commit_counts.get(cidx, 0) + 1
                if commit_counts[cidx] % n_prod == 0:
                    new_prod_list[cidx] += 1
        new_prod = tuple(new_prod_list)
    elif step.is_consumer_release:
        new_cons_list = list(cons_credits)
        if step.is_merge_group:
            release_counts: Optional[Dict[int, int]] = None
            for midx, n_cons in step.group_member_cons_counts:
                if n_cons == 1:
                    new_cons_list[midx] += 1
                else:
                    if release_counts is None:
                        new_totals, release_counts = _cow_total_bucket(
                            total_counts, "releases"
                        )
                    release_counts[midx] = release_counts.get(midx, 0) + 1
                    if release_counts[midx] % n_cons == 0:
                        new_cons_list[midx] += 1
        else:
            n_cons = step.consumer_count
            cidx = step.credit_idx
            if n_cons == 1:
                new_cons_list[cidx] += 1
            else:
                new_totals, release_counts = _cow_total_bucket(total_counts, "releases")
                release_counts[cidx] = release_counts.get(cidx, 0) + 1
                if release_counts[cidx] % n_cons == 0:
                    new_cons_list[cidx] += 1
        new_cons = tuple(new_cons_list)
    elif step.is_consumer_wait:
        new_prod_list = list(prod_credits)
        n_cons = step.consumer_count
        cidx = step.credit_idx
        if n_cons == 1:
            new_prod_list[cidx] -= 1
        else:
            new_totals, wait_counts = _cow_total_bucket(total_counts, "waits")
            wait_counts[cidx] = wait_counts.get(cidx, 0) + 1
            if wait_counts[cidx] % n_cons == 0:
                new_prod_list[cidx] -= 1
        new_prod = tuple(new_prod_list)
    elif step.is_producer_acquire:
        new_cons_list = list(cons_credits)
        n_prod = step.producer_count
        cidx = step.credit_idx
        if n_prod == 1:
            new_cons_list[cidx] -= 1
        else:
            new_totals, acquire_counts = _cow_total_bucket(total_counts, "acquires")
            acquire_counts[cidx] = acquire_counts.get(cidx, 0) + 1
            if acquire_counts[cidx] % n_prod == 0:
                new_cons_list[cidx] -= 1
        new_cons = tuple(new_cons_list)

    return new_prod, new_cons, new_totals


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
    def _needs_update(step: _StepInfo) -> bool:
        """Return whether one step can mutate held-resource state."""
        return (
            (step.is_consumer_release and step.is_merge_group)
            or (step.is_consumer_release and step.is_fused_merge_group)
            or (
                step.in_alias
                and (
                    step.is_blocking
                    or step.is_point_write
                    or step.is_point_read
                    or step.is_consumer_release
                )
            )
            or (
                (step.is_consumer_wait or step.is_producer_commit)
                and bool(step.completion_wait_rids)
            )
        )

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
        """Tag paired reads preceding this commit with its generation.
        """
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
        """Clear paired reads tagged with the generation this wait observes.
        """
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


def _credit_tuple_to_dict(
    credits: CreditTuple,
    context: _CheckerContext,
) -> Dict[CreditKey, int]:
    """Convert dense credit tuples back to sparse credit-key maps."""
    return {
        key: credits[idx]
        for idx, key in enumerate(context.credit_key_order)
        if credits[idx] != 0
    }


def _available_stage_counts_from_tuple(
    credits: CreditTuple,
    context: _CheckerContext,
    resource_id: int,
) -> Tuple[Tuple[int, int], ...]:
    """Positive dense credit counts for one resource, grouped by stage."""
    return tuple(
        (key[1], credits[idx])
        for idx, key in enumerate(context.credit_key_order)
        if key[0] == resource_id and credits[idx] > 0
    )


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
        if step.is_blocking and step.track:
            if step.is_consumer_wait:
                if step.credit_idx >= 0 and state.prod_credits[step.credit_idx] > 0:
                    enabled_mask |= 1 << task_idx
            elif step.credit_idx >= 0 and state.cons_credits[step.credit_idx] > 0:
                enabled_mask |= 1 << task_idx
        else:
            enabled_mask |= 1 << task_idx
    return _EnabledTasks(enabled_mask, all_done)


def _blocked_tasks_for_deadlock(
    state: _BfsState,
    context: _CheckerContext,
) -> Tuple[List[Tuple[str, str, str]], List[BlockedTaskInfo]]:
    """Describe tasks blocked on unavailable protocol credits."""
    blocked_info: List[Tuple[str, str, str]] = []
    blocked_details: List[BlockedTaskInfo] = []
    for task_idx in range(context.n_tasks):
        cursor = state.cursors[task_idx]
        if cursor >= context.schedule_lens[task_idx]:
            continue
        step = context.schedule_steps[task_idx][cursor]
        assert step is not None
        if not (step.is_blocking and step.track):
            continue
        credit_rid = _credit_key(step.res, step.stage)
        if step.is_consumer_wait:
            if step.credit_idx < 0 or state.prod_credits[step.credit_idx] <= 0:
                blocked_info.append(
                    (
                        context.task_names[task_idx],
                        step.res.name,
                        step.stage.name,
                    )
                )
                physical_stage = (
                    context.credit_key_order[step.credit_idx][1]
                    if step.credit_idx >= 0
                    else 0
                )
                blocked_details.append(
                    BlockedTaskInfo(
                        task_name=context.task_names[task_idx],
                        resource_name=step.res.name,
                        stage_name=step.stage.name,
                        credit_kind="producer commit credit",
                        physical_stage=physical_stage,
                        available_stage_counts=_available_stage_counts_from_tuple(
                            state.prod_credits, context, credit_rid
                        ),
                        domain_interleaved=credit_rid in context.domain_rids,
                    )
                )
        elif step.credit_idx < 0 or state.cons_credits[step.credit_idx] <= 0:
            blocked_info.append(
                (context.task_names[task_idx], step.res.name, step.stage.name)
            )
            physical_stage = (
                context.credit_key_order[step.credit_idx][1]
                if step.credit_idx >= 0
                else 0
            )
            blocked_details.append(
                BlockedTaskInfo(
                    task_name=context.task_names[task_idx],
                    resource_name=step.res.name,
                    stage_name=step.stage.name,
                    credit_kind="empty-slot credit",
                    physical_stage=physical_stage,
                    available_stage_counts=_available_stage_counts_from_tuple(
                        state.cons_credits, context, credit_rid
                    ),
                    domain_interleaved=credit_rid in context.domain_rids,
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
) -> _BfsState:
    """Build the successor reached by executing one enabled task step."""
    cursor = state.cursors[task_idx]
    step = context.schedule_steps[task_idx][cursor]
    assert step is not None

    if step.has_credit_transition:
        new_prod, new_cons, new_totals = _apply_credit_transition(
            step,
            state.prod_credits,
            state.cons_credits,
            state.total_counts,
        )
    else:
        new_prod = state.prod_credits
        new_cons = state.cons_credits
        new_totals = state.total_counts

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
        op_desc = f"{step.stage.name}({step.res.name})"
        new_path = (state.path or []) + [(context.task_names[task_idx], op_desc)]
    else:
        new_path = None

    return _BfsState(
        cursors=new_cursors_t,
        cursor_key=state.cursor_key + context.cursor_strides[task_idx],
        prod_credits=new_prod,
        cons_credits=new_cons,
        held=new_held,
        total_counts=new_totals,
        path=new_path,
        has_executed_pdl_wait=new_pdl,
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
            rname = (
                self.id_to_res[rid].name
                if rid in self.id_to_res
                else f"?{rid}"
            )
            for access, tid, slot, gen in sorted(entries):
                slot_suffix = "" if slot == _SLOTLESS else f"[s{slot}]"
                gen_suffix = "" if gen == _UNTAGGED else f"(g{gen})"
                parts.append(
                    f"{rname}{slot_suffix}:{access}{gen_suffix}"
                    f"@{self.task_names[tid]}"
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
                f"{e[1].name}({e[0].name})" for e in schedules[task_idx]
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

    def print_summary(
        self,
        states_explored: int,
        complete_count: int,
        deadlock_count: int,
        race_count: int,
        pdl_order_count: int,
        hit_state_limit: bool,
        max_states: int,
        is_safe: bool,
    ) -> None:
        print("=" * 72)
        print(
            f"BFS complete: {states_explored} states explored, "
            f"{complete_count} complete, "
            f"{deadlock_count} deadlock(s), {race_count} race(s), "
            f"{pdl_order_count} PDL order violation(s)"
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
    opaque_assignment: dict | None = None,
    early_exit: bool = True,
    cursor_only_visited: bool = True,
) -> CheckResult:
    """Explore all valid schedule interleavings via optimized BFS.

    ``cursor_only_visited`` keeps the default visited key compact.  Set it
    to ``False`` only when debugging checker state divergence, as this
    falls back to the slower full-state key.
    """
    if not tasks:
        return CheckResult([], [], 0, 0, True)

    resources = _collect_resources(tasks)
    schedules = [
        _expand_task_for_check(t, skipped_tile, opaque_assignment) for t in tasks
    ]
    if num_tiles > 1:
        schedules = [s * num_tiles for s in schedules]

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

    # Domain-interleaved resources track credits per *physical stage* so a
    # lane-0 commit cannot release a lane-1 wait (on hardware they are
    # different mbarriers).  Non-domain resources use the fixed stage 0
    # key and keep their existing fungible credit pool.
    domain_rids = _domain_interleaved_resource_ids(tasks)
    credit_keys = _precompute_stage_credit_keys(tasks, schedules, domain_rids)

    task_names = [t.name for t in tasks]
    n_tasks = len(tasks)
    schedule_lens = [len(s) for s in schedules]
    cursor_strides: List[int] = []
    cursor_stride = 1
    for schedule_len in schedule_lens:
        cursor_strides.append(cursor_stride)
        cursor_stride *= schedule_len + 1

    initial_cons = _build_initial_cons_credits(resources, domain_rids)
    initial_cursors = tuple(0 for _ in range(n_tasks))

    _num_producers: Dict[int, int] = {}
    _num_consumers: Dict[int, int] = {}
    for task in tasks:
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
        for res in task.src_resources:
            if _is_tracked(res) and res.pipeline_config is not None:
                rid = id(res)
                if not _count_independent_interleave_lane(
                    _num_consumers,
                    rid,
                    task,
                    res,
                    ScheduleStage.ConsumerWait,
                ):
                    _num_consumers[rid] = _num_consumers.get(rid, 0) + 1

    credit_key_set: Set[CreditKey] = set(initial_cons)
    for task_keys in credit_keys:
        credit_key_set.update(task_keys)
    credit_key_set.update((rid, 0) for rid in _num_producers)
    credit_key_set.update((rid, 0) for rid in _num_consumers)
    for sched in schedules:
        for entry in sched:
            res = entry[0]
            if isinstance(res, PipelineGroup):
                credit_key_set.update((id(member), 0) for member in res.members)

    credit_key_order: List[CreditKey] = []
    seen_credit_keys: Set[CreditKey] = set()
    for res in resources:
        rid = id(res)
        for key in sorted(key for key in credit_key_set if key[0] == rid):
            seen_credit_keys.add(key)
            credit_key_order.append(key)
    for key in sorted(credit_key_set):
        if key not in seen_credit_keys:
            seen_credit_keys.add(key)
            credit_key_order.append(key)

    credit_idx_by_key = {key: idx for idx, key in enumerate(credit_key_order)}
    zero_credits = tuple(0 for _ in credit_key_order)
    initial_cons_dense_list = [0 for _ in credit_key_order]
    for key, value in initial_cons.items():
        idx = credit_idx_by_key.get(key)
        if idx is not None:
            initial_cons_dense_list[idx] = value
    initial_cons_dense = tuple(initial_cons_dense_list)

    schedule_steps = _precompute_schedule_steps(
        tasks,
        schedules,
        alias_map,
        _num_producers,
        _num_consumers,
        completion.completion_wait_rids,
        credit_keys,
        credit_idx_by_key,
    )
    context = _CheckerContext(
        task_names=task_names,
        n_tasks=n_tasks,
        schedule_lens=schedule_lens,
        cursor_strides=cursor_strides,
        credit_key_order=credit_key_order,
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

    empty_totals: Dict[str, Dict[int, int]] = {
        "commits": {},
        "waits": {},
        "releases": {},
        "acquires": {},
    }
    empty_held: HeldMap = {}

    initial_pdl = assume_pdl_wait_completed
    initial_cursor_key = 0
    if cursor_only_visited:
        visited: Set[int | tuple] = {initial_cursor_key}
    else:
        visited = {_make_state_key(initial_cursors, {}, dict(initial_cons), empty_held)}

    queue: deque[_BfsState] = deque()
    queue.append(
        _BfsState(
            cursors=initial_cursors,
            cursor_key=initial_cursor_key,
            prod_credits=zero_credits,
            cons_credits=initial_cons_dense,
            held=empty_held,
            total_counts=empty_totals,
            path=[] if verbose else None,
            has_executed_pdl_wait=initial_pdl,
        )
    )

    deadlocks: List[DeadlockInfo] = []
    races: List[RaceInfo] = []
    pdl_order_states: List[PdlOrderInfo] = []
    states_explored = 0
    complete_count = 0
    cursor_only = context.cursor_only_visited
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

            successor = _advance_one_task(
                state,
                task_idx,
                context,
                held_tracker,
                verbose,
            )
            state_key: int | tuple
            if cursor_only:
                state_key = successor.cursor_key
            else:
                state_key = _make_state_key(
                    successor.cursors,
                    _credit_tuple_to_dict(successor.prod_credits, context),
                    _credit_tuple_to_dict(successor.cons_credits, context),
                    successor.held,
                )
            if state_key in visited:
                continue
            visited_add(state_key)
            queue.append(successor)

        if stop_branching or (early_exit and (pdl_order_states or deadlocks or races)):
            break

    hit_state_limit = bool(queue and states_explored >= max_states)
    is_safe = not deadlocks and not races and not pdl_order_states

    if reporter is not None:
        reporter.print_summary(
            states_explored,
            complete_count,
            len(deadlocks),
            len(races),
            len(pdl_order_states),
            hit_state_limit,
            max_states,
            is_safe,
        )

    return CheckResult(
        deadlock_states=deadlocks,
        race_states=races,
        states_explored=states_explored,
        complete_count=complete_count,
        is_safe=is_safe,
        pdl_order_states=pdl_order_states,
        hit_state_limit=hit_state_limit,
    )
