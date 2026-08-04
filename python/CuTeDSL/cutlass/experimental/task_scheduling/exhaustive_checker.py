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

Algorithm
---------
State includes per-task cursor positions into the expanded
(head + loop + tail) schedule plus dynamic protocol state (producer
credits, consumer credits, and held-resource access windows).  The
visited-set key includes all of these so path-sensitive states that
share cursors are still explored independently.

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

Three-state physical-access model
----------------------------------
Race detection tracks three per-resource access states:

- **held** — buffer is reserved by the pipeline protocol (``PAcq``,
  ``CWait``) but no physical memory access is happening.  A ``held``
  entry never participates in a race.
- **prod_work** — producer is physically writing (set at ``PWork``).
- **cons_work** — consumer is physically reading (set at ``CWork``).

A **race** is flagged when two aliased resources both have work-level
entries and at least one is ``prod_work``::

    prod_work vs prod_work → RACE   (two concurrent writers)
    prod_work vs cons_work → RACE   (writer vs reader)
    cons_work vs cons_work → safe   (two concurrent readers)
    held      vs *         → safe   (no physical access)

Clearing rules — sync vs DMA/async:

For **sync** pipelines (``AsyncAsync`` producer, non-UMMA consumer):

- ``prod_work`` transitions back to ``held`` after the last consecutive
  ``ProducerWork`` on the same resource (the synchronous write completes
  within the Work call).
- ``cons_work`` transitions back to ``held`` after the last consecutive
  ``ConsumerWork`` on the same resource.

For **DMA/async producer** pipelines (``TmaAsync``, ``TmaUmma``,
``UmmaAsync``, ``ClcFetchAsync``):

- ``prod_work`` persists until ``ConsumerWait`` on the same resource
  (the barrier proves the async write is complete).

For **UMMA consumer** pipelines (``TmaUmma``, ``AsyncUmma``):

- ``cons_work`` persists past ``ConsumerRelease`` (UMMA is still reading).
- ``cons_work`` is cleared at whichever comes first:

  1. ``ConsumerWait(TmemC)`` on a **paired UmmaAsync** resource
     (UMMA pairing — the hardware reads SmemAb while writing TmemC, so
     ``CWait(TmemC)`` guarantees SmemAb reads are complete).
  2. ``ProducerAcquire(R)`` implicitly closes the old hold (buffer
     reclaimed by producer).

``ConsumerWait`` is a full barrier: it clears both ``prod_work`` and
``cons_work`` on the resource (for DMA producer/consumer pipelines;
sync pipelines will already have cleared via the last-Work rule).

Non-atomic work modelling
~~~~~~~~~~~~~~~~~~~~~~~~~
A single ``ProducerWork`` or ``ConsumerWork`` call may consist of many
hardware instructions.  Another warp can interleave mid-call.  To
model this, each **sync-side** work entry is **doubled** in the
schedule before BFS exploration (see ``_explode_sync_work``).  The
two consecutive work steps keep the ``prod_work`` / ``cons_work``
state visible across multiple BFS states, giving other tasks a chance
to interleave and expose races.

``PWork`` is doubled when the producer is sync (``AsyncAsync``,
``AsyncUmma``).  ``CWork`` is doubled when the consumer is
sync (``AsyncAsync``, ``TmaAsync``, ``UmmaAsync``,
``ClcFetchAsync``).  Async/DMA producers and UMMA consumers are not
doubled because their work states already persist across steps.

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
  ``prod_work`` race checks.
- **cons_alias_map** — consumer-ranges × all-ranges.  Used for
  ``cons_work`` race checks.

A race between resources A and B is only flagged when **both** sides
confirm the overlap through their respective role alias maps.
"""

from collections import deque
from dataclasses import dataclass, field
from typing import Dict, List, Optional, Set, Tuple

from .enums import PipelineGroupMode, PipelineType, ScheduleStage
from .resources import (
    MemoryResource,
    PdlLaunchBarrier,
    PdlWaitBarrier,
    PipelineGroup,
    WorkQueue,
)
from .task import Task
from .task_manager import _count_independent_interleave_lane, expand_loop

# Pipeline types whose consumer is UMMA (TCGen05Mma).  For these
# pipelines SMEM remains in use past ConsumerRelease — the actual
# release happens implicitly at the next ProducerAcquire.
_UMMA_CONSUMER_TYPES = frozenset(
    {
        PipelineType.TmaUmma,
        PipelineType.AsyncUmma,
        PipelineType.UmmaUmma,
    }
)

# Pipeline types whose producer writes asynchronously (TMA DMA or
# UMMA MMA).  prod_work holds persist past PWork until the CWait
# barrier proves the write is complete.
_ASYNC_PRODUCER_TYPES = frozenset(
    {
        PipelineType.TmaAsync,
        PipelineType.TmaUmma,
        PipelineType.UmmaAsync,
        PipelineType.UmmaUmma,
        PipelineType.ClcFetchAsync,
    }
)


def _explode_sync_work(
    schedules: List[list],
) -> List[list]:
    """Double sync-side work steps to model non-atomic physical access.

    A single ``ProducerWork`` or ``ConsumerWork`` may consist of many
    instructions.  Another warp can interleave during this window.  By
    inserting a duplicate work entry, the BFS explores states where the
    work state (``prod_work`` / ``cons_work``) is visible across
    multiple steps, allowing race detection during the work window.

    Only the **sync side** of each pipeline is doubled:

    - ``PWork`` when the producer is sync (pipeline_type not in
      ``_ASYNC_PRODUCER_TYPES``): ``AsyncAsync``, ``AsyncUmma``.
    - ``CWork`` when the consumer is sync (pipeline_type not in
      ``_UMMA_CONSUMER_TYPES``): ``AsyncAsync``, ``TmaAsync``,
      ``UmmaAsync``, ``ClcFetchAsync``.

    Async/DMA producers and UMMA consumers are not doubled because
    their work states already persist across BFS steps.

    ``ConsumerWork`` on resources **without a pipeline config** is
    conservatively split into write/read phases to model hidden
    read-modify-write patterns inside one work call:

    - ``cons_write_phase`` — conservative write-capable phase.
    - ``cons_read_phase`` — read phase.

    Pipelined ``ConsumerWork`` is only doubled (no phase tags) because
    the pipeline protocol already guarantees mutual exclusion between
    producer and consumer on each buffer slot.
    """
    result = []
    for sched in schedules:
        new_sched: list = []
        for entry in sched:
            res, stage = entry[0], entry[1]
            new_sched.append(entry)
            if res.is_barrier:
                continue
            if stage == ScheduleStage.ConsumerWork and res.pipeline_config is None:
                new_sched[-1] = (*entry, "cons_write_phase")
                new_sched.append((*entry, "cons_read_phase"))
                continue

            if res.pipeline_config is None:
                continue

            ptype = res.pipeline_config.pipeline_type
            if (
                stage == ScheduleStage.ProducerWork
                and ptype not in _ASYNC_PRODUCER_TYPES
            ):
                new_sched.append(entry)
            elif (
                stage == ScheduleStage.ConsumerWork
                and ptype not in _UMMA_CONSUMER_TYPES
            ):
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


def _expand_task_for_check(task: Task, skipped_tile: bool) -> List:
    """Return the schedule variant to explore for one logical tile."""
    if skipped_tile and getattr(task, "skip_if", None) is not None:
        return _expand_skipped_tile(task)
    return expand_loop(task)


# ── Result data classes ──────────────────────────────────────────────────


@dataclass
class DeadlockInfo:
    """A deadlock state found during exhaustive exploration."""

    cursors: tuple
    blocked_tasks: List[Tuple[str, str, str]]


@dataclass
class RaceInfo:
    """A data race found during exhaustive exploration."""

    cursors: tuple
    writer_task: str
    writer_resource: str
    victim_task: str
    victim_resource: str
    victim_access: str
    overlap_desc: str


@dataclass
class PdlOrderInfo:
    """A PDL launch that can execute before any PDL wait in an interleaving."""

    cursors: tuple
    launch_task: str
    launch_resource: str


@dataclass
class CheckResult:
    """Aggregated results from ``check_all_interleavings``."""

    deadlock_states: List[DeadlockInfo]
    race_states: List[RaceInfo]
    states_explored: int
    complete_count: int
    is_safe: bool
    pdl_order_states: List[PdlOrderInfo] = field(default_factory=list)
    hit_state_limit: bool = False


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
) -> Dict[int, int]:
    """Each pipelined resource starts with ``num_stages`` empty-slot credits.

    Group members get their own independent credits (``PipelineGroup``
    objects themselves are skipped since they are not in schedules).
    """
    credits: Dict[int, int] = {}
    for res in resources:
        if (
            res.pipeline_config is not None
            and not isinstance(res, WorkQueue)
            and not isinstance(res, PipelineGroup)
        ):
            rid = id(res)
            if rid not in credits:
                credits[rid] = res.pipeline_config.num_stages
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
      Used for ``prod_work`` race checks.  Reflects allocations from
      ``get_producer_requirements()`` (defaults to all when ``None``).
    - *cons_alias_map* — asymmetric, consumer-ranges × all-ranges.
      Used for ``cons_work`` race checks.  Reflects allocations from
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


def _find_races_at_state(
    held: Dict[int, List[Tuple[str, int]]],
    next_point_ops: List[Tuple[int, str, int]],
    alias_map: Dict[int, Set[int]],
    prod_alias_map: Dict[int, Set[int]],
    cons_alias_map: Dict[int, Set[int]],
    overlap_descs: Dict[Tuple[int, int], str],
    id_to_res: Dict[int, MemoryResource],
    task_names: List[str],
    cursors: tuple,
) -> List[RaceInfo]:
    """Find aliasing races at one state.

    Merges pipeline-held entries and next point-access ops into a single
    list and checks all pairs on aliased resources.  A race is flagged
    only when both entries are *work*-level (``prod_work`` or
    ``cons_work``) and at least one is ``prod_work``.  The passive
    ``held`` state never triggers a race.

    For each access, the role-specific alias map is used
    (``prod_alias_map`` for ``prod_work``, ``cons_alias_map`` for
    ``cons_work``) so that only the physical ranges the role actually
    accesses (declared via ``get_producer/consumer_requirements``) are
    considered.  Both sides of a candidate pair must confirm the overlap
    through their respective maps.
    """

    def _aliases_for(rid: int, access: str) -> Set[int]:
        if access == "prod_work":
            return prod_alias_map.get(rid, set())
        if access == "cons_work":
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

    all_accesses: List[Tuple[int, str, int]] = []
    for rid, entries in held.items():
        for access_type, task_idx in entries:
            all_accesses.append((rid, access_type, task_idx))
    all_accesses.extend(next_point_ops)

    races: List[RaceInfo] = []
    seen: Set[Tuple[int, int, int, int]] = set()
    for i, (rid_a, access_a, ti_a) in enumerate(all_accesses):
        if rid_a not in alias_map:
            continue
        for rid_b, access_b, ti_b in all_accesses[i + 1 :]:
            if ti_a == ti_b:
                continue
            if access_a == "held" or access_b == "held":
                continue
            if access_a != "prod_work" and access_b != "prod_work":
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
            if access_a == "prod_work":
                races.append(_make_race(ti_a, rid_a, ti_b, rid_b, access_b))
            else:
                races.append(_make_race(ti_b, rid_b, ti_a, rid_a, access_a))

    return races


def _freeze_credits(credits: Dict[int, int]) -> tuple:
    """Canonicalize credit maps for visited-state keys."""
    return tuple(sorted((rid, val) for rid, val in credits.items() if val != 0))


def _freeze_held(held: Dict[int, List[Tuple[str, int]]]) -> tuple:
    """Canonicalize held map for visited-state keys.

    Resource ids are sorted for stable hashing.  Per-resource entry order is
    preserved because barrier/release logic pops from the list directionally.
    """
    return tuple(
        (rid, tuple(entries)) for rid, entries in sorted(held.items()) if entries
    )


def _make_state_key(
    cursors: tuple,
    prod_credits: Dict[int, int],
    cons_credits: Dict[int, int],
    held: Dict[int, List[Tuple[str, int]]],
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


# ── Main entry point ─────────────────────────────────────────────────────


def check_all_interleavings(
    tasks: List[Task],
    alias_map: Optional[Dict[int, Set[int]]] = None,
    prod_alias_map: Optional[Dict[int, Set[int]]] = None,
    cons_alias_map: Optional[Dict[int, Set[int]]] = None,
    overlap_descs: Optional[Dict[Tuple[int, int], str]] = None,
    max_states: int = 100_000,
    num_tiles: int = 1,
    skipped_tile: bool = False,
    assume_pdl_wait_completed: bool = False,
    verbose: bool = False,
) -> CheckResult:
    """Explore all valid schedule interleavings via BFS.

    Parameters
    ----------
    tasks
        TS tasks with normalized schedule lists.
    alias_map
        Pre-computed aliasing map (all-ranges × all-ranges, symmetric).
        Built automatically when ``None``.
    prod_alias_map
        Pre-computed producer aliasing map (producer-ranges × all-ranges).
        Built automatically when ``None``.
    cons_alias_map
        Pre-computed consumer aliasing map (consumer-ranges × all-ranges).
        Built automatically when ``None``.
    overlap_descs
        Pre-computed overlap descriptions keyed by ``(min_id, max_id)``.
    max_states
        Upper bound on explored states (safety valve for large schedules).
    num_tiles
        Tile repetitions for persistent-kernel simulation (typically 2).
    skipped_tile
        When ``True``, tasks with ``skip_if`` are explored using
        their non-skippable head/tail slots. Other tasks use the normal
        expanded schedule.
    assume_pdl_wait_completed
        Treat PDL wait as already executed before any TS schedule entry.
        Use this for kernels that emit ``griddepcontrol.wait`` outside TS
        before the first PDL-dependent memory access.
    verbose
        Print every explored state with cursor positions, per-task
        status, held windows, and any detected races or deadlocks.

    Returns
    -------
    CheckResult
        Deadlocks, races, exploration count, and overall safety flag.
    """
    if not tasks:
        return CheckResult([], [], 0, 0, True)

    resources = _collect_resources(tasks)
    schedules = [_expand_task_for_check(t, skipped_tile) for t in tasks]
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

    # Resources with UMMA-consumer pipelines: reading hold extends past
    # ConsumerRelease; actual release is at the next ProducerAcquire
    # or at ConsumerWait on a paired UmmaAsync resource.
    umma_rids: Set[int] = {
        id(r)
        for r in resources
        if r.pipeline_config is not None
        and r.pipeline_config.pipeline_type in _UMMA_CONSUMER_TYPES
    }

    schedules = _explode_sync_work(schedules)

    # UMMA pairing: map id(UmmaProducer resource) → {id(UMMA-consumer resource), ...}.
    # ConsumerWait on the UmmaProducer resource also frees the paired
    # UMMA-consumer reading holds (the UMMA reads SmemAb while writing TmemC,
    # so CWait(TmemC) guarantees SmemAb reads are complete).
    umma_paired_reads: Dict[int, Set[int]] = {}
    for task in tasks:
        consumed_umma = [
            r
            for r in task.src_resources
            if r.pipeline_config is not None
            and r.pipeline_config.pipeline_type in _UMMA_CONSUMER_TYPES
        ]
        produced_umma = [
            r
            for r in task.dst_resources
            if r.pipeline_config is not None
            and r.pipeline_config.pipeline_type
            in {PipelineType.UmmaAsync, PipelineType.UmmaUmma}
        ]
        for prod_res in produced_umma:
            for cons_res in consumed_umma:
                umma_paired_reads.setdefault(id(prod_res), set()).add(id(cons_res))

    task_names = [t.name for t in tasks]
    n_tasks = len(tasks)

    def _has_executed_pdl_wait(cursors: tuple) -> bool:
        """Return True if any already-executed schedule prefix emitted PDL wait."""
        if assume_pdl_wait_completed:
            return True
        for task_idx, cursor in enumerate(cursors):
            for entry in schedules[task_idx][:cursor]:
                if _is_pdl_wait_entry(entry):
                    return True
        return False

    if verbose:
        print("=" * 72)
        print("Exhaustive interleaving checker — BFS exploration")
        print("=" * 72)
        for i, t in enumerate(tasks):
            sched_desc = ", ".join(f"{e[1].name}({e[0].name})" for e in schedules[i])
            print(f"  Task {i} ({task_names[i]}): [{sched_desc}]")
        if alias_map:
            print("  Alias pairs:")
            seen_pairs: set = set()
            for rid_a, aliases in alias_map.items():
                for rid_b in aliases:
                    pair = (min(rid_a, rid_b), max(rid_a, rid_b))
                    if pair not in seen_pairs:
                        seen_pairs.add(pair)
                        na = id_to_res[rid_a].name if rid_a in id_to_res else "?"
                        nb = id_to_res[rid_b].name if rid_b in id_to_res else "?"
                        print(f"    {na} <-> {nb}")
        print("-" * 72)

    initial_cons = _build_initial_cons_credits(resources)
    initial_cursors = tuple(0 for _ in range(n_tasks))

    # ── Credit model for merge/fork pipelines ───────────────────────
    # Count how many distinct tasks act as producer / consumer for each
    # pipelined resource.  Full-round completion is detected via
    # ``total_events % N == 0``.  For 1:1 pipelines N == 1 and every
    # event immediately produces/consumes a credit.
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

    # BFS queue entries:
    #   (cursors, prod_credits, cons_credits, held, total_counts, path)
    # ``held`` maps resource id() → list of (access_type, task_idx) entries
    # tracking pipeline occupancy from ProdAcquire to ConsRelease.
    # ``total_counts`` tracks cumulative event counts per resource; a
    # full credit round completes when ``total % N == 0``.  These are
    # NOT part of the visited-state key (they are determined by cursors).
    # ``path`` is a list of (task_name, op_description) tuples representing
    # the complete time-ordered execution history leading to this state.
    empty_path: List[Tuple[str, str]] = []
    empty_held: Dict[int, List[Tuple[str, int]]] = {}
    empty_totals: Dict[str, Dict[int, int]] = {
        "commits": {},
        "waits": {},
        "releases": {},
        "acquires": {},
    }
    visited: Set[tuple] = {
        _make_state_key(
            initial_cursors,
            {},
            dict(initial_cons),
            empty_held,
        )
    }
    queue: deque = deque()
    queue.append(
        (
            initial_cursors,
            {},
            dict(initial_cons),
            empty_held,
            empty_totals,
            empty_path,
        )
    )

    deadlocks: List[DeadlockInfo] = []
    races: List[RaceInfo] = []
    pdl_order_states: List[PdlOrderInfo] = []
    states_explored = 0
    complete_count = 0

    def _fmt_held(h: Dict[int, List[Tuple[str, int]]]) -> str:
        """Format the held-resource map for display."""
        if not h:
            return "{}"
        parts = []
        for rid, entries in h.items():
            rname = id_to_res[rid].name if rid in id_to_res else f"?{rid}"
            for access, tid in sorted(entries):
                parts.append(f"{rname}:{access}@{task_names[tid]}")
        return "{" + ", ".join(parts) + "}"

    def _print_timeline(
        path: List[Tuple[str, str]],
        suffix_label: str = "",
    ) -> None:
        """Print time-ordered execution history as a columnar table.

        Each task occupies its own column.  At every time step only the
        active task's column shows the operation; the other columns are
        left blank (``·``).  Reading a single column top-to-bottom gives
        that task's operation sequence with the interleaving gaps visible.
        """
        if not path:
            print("  timeline: (initial state)")
            if suffix_label:
                print(f"  {suffix_label}")
            return

        col_width = (
            max(
                max((len(op) for _, op in path), default=0),
                max((len(n) for n in task_names), default=0),
                5,
            )
            + 2
        )

        header = "    t  "
        sep = "    ─  "
        for name in task_names:
            header += name.ljust(col_width)
            sep += ("─" * len(name)).ljust(col_width)
        print(f"  timeline ({len(path)} steps):")
        print(header)
        print(sep)

        name_to_idx = {n: i for i, n in enumerate(task_names)}
        for t, (tname, op_desc) in enumerate(path):
            row = f"    {t:<3d}"
            active_col = name_to_idx.get(tname, -1)
            for col in range(n_tasks):
                if col == active_col:
                    row += op_desc.ljust(col_width)
                else:
                    row += "·".ljust(col_width)
            print(row)

        if suffix_label:
            print(f"  {suffix_label}")

    while queue and states_explored < max_states:
        cursors, prod_credits, cons_credits, held, total_counts, path = queue.popleft()
        states_explored += 1

        # ── Classify each task: done / blocked / enabled ──
        enabled: List[int] = []
        all_done = True
        blocked_info: List[Tuple[str, str, str]] = []

        for i in range(n_tasks):
            c = cursors[i]
            if c >= len(schedules[i]):
                continue
            all_done = False
            res, stage = schedules[i][c][0], schedules[i][c][1]
            if stage in _BLOCKING and _is_tracked(res):
                rid = id(res)
                if stage == ScheduleStage.ConsumerWait:
                    if prod_credits.get(rid, 0) > 0:
                        enabled.append(i)
                    else:
                        blocked_info.append((task_names[i], res.name, stage.name))
                else:
                    if cons_credits.get(rid, 0) > 0:
                        enabled.append(i)
                    else:
                        blocked_info.append((task_names[i], res.name, stage.name))
            else:
                enabled.append(i)

        if all_done:
            complete_count += 1
            if verbose:
                print(f"State #{states_explored}  cursors={cursors}  ✓ COMPLETE")
                _print_timeline(path)
                print()
            continue

        if not enabled:
            deadlocks.append(DeadlockInfo(cursors=cursors, blocked_tasks=blocked_info))
            if verbose:
                bl = ", ".join(f"{n} on {r}.{s}" for n, r, s in blocked_info)
                print(
                    f"State #{states_explored}  cursors={cursors}  "
                    f"held={_fmt_held(held)}"
                )
                _print_timeline(path, suffix_label=f"*** DEADLOCK: {bl}")
                print()
            continue

        # ── Race check at this state ──
        state_races: List[RaceInfo] = []
        if alias_map:
            next_point_ops: List[Tuple[int, str, int]] = []
            for task_idx in enabled:
                c = cursors[task_idx]
                entry = schedules[task_idx][c]
                res, stage = entry[0], entry[1]
                rid = id(res)
                if rid in alias_map:
                    if stage in _POINT_WRITE:
                        next_point_ops.append((rid, "prod_work", task_idx))
                    elif stage in _POINT_READ:
                        phase = _entry_consumer_work_phase(entry)
                        access = (
                            "prod_work" if phase == "cons_write_phase" else "cons_work"
                        )
                        next_point_ops.append((rid, access, task_idx))

            state_races = _find_races_at_state(
                held,
                next_point_ops,
                alias_map,
                prod_alias_map,
                cons_alias_map,
                overlap_descs,
                id_to_res,
                task_names,
                cursors,
            )
            if verbose and state_races:
                race_descs = "; ".join(
                    f"{rc.writer_task} writes {rc.writer_resource}"
                    f" vs {rc.victim_task} {rc.victim_access} "
                    f"{rc.victim_resource} ({rc.overlap_desc})"
                    for rc in state_races
                )
                print(
                    f"State #{states_explored}  cursors={cursors}  "
                    f"held={_fmt_held(held)}"
                )
                _print_timeline(
                    path,
                    suffix_label=f"*** RACE: {race_descs}",
                )
                print()
            races.extend(state_races)

        # ── Branch: advance each enabled task ──
        has_executed_pdl_wait = _has_executed_pdl_wait(cursors)
        for task_idx in enabled:
            c = cursors[task_idx]
            entry = schedules[task_idx][c]
            res, stage = entry[0], entry[1]
            rid = id(res)
            track = _is_tracked(res)

            if _is_pdl_launch_entry(entry) and not has_executed_pdl_wait:
                pdl_order_states.append(
                    PdlOrderInfo(
                        cursors=cursors,
                        launch_task=task_names[task_idx],
                        launch_resource=res.name,
                    )
                )
                if verbose:
                    print(
                        f"State #{states_explored}  cursors={cursors}  "
                        f"held={_fmt_held(held)}"
                    )
                    _print_timeline(
                        path,
                        suffix_label=(
                            "*** PDL ORDER: launch_griddep can execute "
                            "before any wait_griddep"
                        ),
                    )
                    print()
                continue

            new_prod = dict(prod_credits)
            new_cons = dict(cons_credits)
            new_totals = {k: dict(v) for k, v in total_counts.items()}
            if track:
                if stage == ScheduleStage.ProducerCommit:
                    # Merge: per-member ``ProducerCommit``.
                    # Fork: ``(group, ProducerCommit)`` — shared full
                    # barrier fires once and delivers credits to all
                    # members.  Track credits only on members; the
                    # group itself has no ``ConsumerWait`` so a
                    # group-level credit would be unmatched.
                    if (
                        isinstance(res, PipelineGroup)
                        and res.mode == PipelineGroupMode.Fork
                    ):
                        for _m in res.members:
                            _mid = id(_m)
                            n_prod = _num_producers.get(_mid, 1)
                            new_totals["commits"][_mid] = (
                                new_totals["commits"].get(_mid, 0) + 1
                            )
                            if new_totals["commits"][_mid] % n_prod == 0:
                                new_prod[_mid] = new_prod.get(_mid, 0) + 1
                    else:
                        n_prod = _num_producers.get(rid, 1)
                        new_totals["commits"][rid] = (
                            new_totals["commits"].get(rid, 0) + 1
                        )
                        if new_totals["commits"][rid] % n_prod == 0:
                            new_prod[rid] = new_prod.get(rid, 0) + 1
                elif stage == ScheduleStage.ConsumerRelease:
                    # Merge: ``(group, ConsumerRelease)`` — shared
                    # empty barrier fires once and releases all
                    # members.  Track credits only on members; the
                    # group itself has no ProducerAcquire so a
                    # group-level credit would be unmatched at the
                    # end-of-schedule reconciliation.
                    # Fork: per-member empties; ``ConsumerRelease``
                    # lives on each member directly, no propagation.
                    if (
                        isinstance(res, PipelineGroup)
                        and res.mode == PipelineGroupMode.Merge
                    ):
                        for _m in res.members:
                            _mid = id(_m)
                            n_cons = _num_consumers.get(_mid, 1)
                            new_totals["releases"][_mid] = (
                                new_totals["releases"].get(_mid, 0) + 1
                            )
                            if new_totals["releases"][_mid] % n_cons == 0:
                                new_cons[_mid] = new_cons.get(_mid, 0) + 1
                    else:
                        n_cons = _num_consumers.get(rid, 1)
                        new_totals["releases"][rid] = (
                            new_totals["releases"].get(rid, 0) + 1
                        )
                        if new_totals["releases"][rid] % n_cons == 0:
                            new_cons[rid] = new_cons.get(rid, 0) + 1
                elif stage == ScheduleStage.ConsumerWait:
                    n_cons = _num_consumers.get(rid, 1)
                    new_totals["waits"][rid] = new_totals["waits"].get(rid, 0) + 1
                    if new_totals["waits"][rid] % n_cons == 0:
                        new_prod[rid] = new_prod.get(rid, 0) - 1
                elif stage == ScheduleStage.ProducerAcquire:
                    n_prod = _num_producers.get(rid, 1)
                    new_totals["acquires"][rid] = new_totals["acquires"].get(rid, 0) + 1
                    if new_totals["acquires"][rid] % n_prod == 0:
                        new_cons[rid] = new_cons.get(rid, 0) - 1

            new_held: Dict[int, List[Tuple[str, int]]] = {
                k: list(v) for k, v in held.items()
            }

            # ── Held-state propagation ─────────────────────────────
            # ``(group, ConsumerRelease)`` on a Merge group clears
            # held entries on every member (shared empty barrier).
            # The group itself has no SMEM range so ``rid`` is not
            # in ``alias_map`` — handle it separately before the
            # per-resource block below.
            if (
                stage == ScheduleStage.ConsumerRelease
                and isinstance(res, PipelineGroup)
                and res.mode == PipelineGroupMode.Merge
            ):
                for m in res.members:
                    mid = id(m)
                    if mid in umma_rids:
                        continue
                    m_entries = new_held.get(mid, [])
                    for j in range(len(m_entries)):
                        if m_entries[j][1] == task_idx:
                            m_entries.pop(j)
                            break
                    if not m_entries:
                        new_held.pop(mid, None)

            if rid in alias_map:
                if stage == ScheduleStage.ProducerAcquire:
                    entries = new_held.setdefault(rid, [])
                    if rid in umma_rids:
                        for j in range(len(entries)):
                            if entries[j][0] in ("cons_work", "held"):
                                entries.pop(j)
                                break
                    entries.append(("held", task_idx))

                elif stage == ScheduleStage.ProducerWork:
                    if rid in alias_map:
                        entries = new_held.setdefault(rid, [])
                        for j in range(len(entries)):
                            if entries[j] == ("held", task_idx):
                                entries[j] = ("prod_work", task_idx)
                                break
                        is_async_prod = (
                            res.pipeline_config is not None
                            and res.pipeline_config.pipeline_type
                            in _ASYNC_PRODUCER_TYPES
                        )
                        if not is_async_prod:
                            next_c = c + 1
                            consecutive = (
                                next_c < len(schedules[task_idx])
                                and id(schedules[task_idx][next_c][0]) == rid
                                and schedules[task_idx][next_c][1]
                                == ScheduleStage.ProducerWork
                            )
                            if not consecutive:
                                for j in range(len(entries)):
                                    if entries[j] == ("prod_work", task_idx):
                                        entries[j] = ("held", task_idx)
                                        break

                elif stage == ScheduleStage.ConsumerWait:
                    if rid in alias_map:
                        entries = new_held.setdefault(rid, [])
                        for j in range(len(entries) - 1, -1, -1):
                            if entries[j][0] in ("prod_work", "held"):
                                entries.pop(j)
                                break
                        for j in range(len(entries) - 1, -1, -1):
                            if entries[j][0] == "cons_work":
                                entries.pop(j)
                                break
                        entries.append(("held", task_idx))

                elif stage == ScheduleStage.ConsumerWork:
                    if rid in alias_map:
                        entries = new_held.setdefault(rid, [])
                        phase = _entry_consumer_work_phase(schedules[task_idx][c])
                        next_access = (
                            "prod_work" if phase == "cons_write_phase" else "cons_work"
                        )
                        for j in range(len(entries)):
                            if entries[j][1] == task_idx and entries[j][0] in (
                                "held",
                                "prod_work",
                                "cons_work",
                            ):
                                entries[j] = (next_access, task_idx)
                                break
                        if rid not in umma_rids:
                            next_c = c + 1
                            consecutive = (
                                next_c < len(schedules[task_idx])
                                and id(schedules[task_idx][next_c][0]) == rid
                                and schedules[task_idx][next_c][1]
                                == ScheduleStage.ConsumerWork
                            )
                            if not consecutive:
                                for j in range(len(entries)):
                                    if entries[j][1] == task_idx and entries[j][0] in (
                                        "cons_work",
                                        "prod_work",
                                    ):
                                        entries[j] = ("held", task_idx)
                                        break

                elif stage == ScheduleStage.ConsumerRelease:
                    # Member-level ConsumerRelease.  Merge-mode groups
                    # release at the group level (handled above) so
                    # this path only fires for Fork members and
                    # standalone resources.
                    if rid not in umma_rids:
                        entries = new_held.get(rid, [])
                        for j in range(len(entries)):
                            if entries[j][1] == task_idx:
                                entries.pop(j)
                                break
                        if not entries:
                            new_held.pop(rid, None)

            # UMMA pairing runs unconditionally: CWait on a paired
            # UmmaAsync resource (e.g. TmemC) frees the
            # UMMA-consumer's reading hold (e.g. SmemAb), even when
            # TmemC itself is not in the alias map.
            if stage == ScheduleStage.ConsumerWait:
                for paired_rid in umma_paired_reads.get(rid, ()):
                    p_entries = new_held.get(paired_rid, [])
                    for j in range(len(p_entries)):
                        if p_entries[j][0] in ("cons_work", "held"):
                            p_entries.pop(j)
                            break
                    if not p_entries:
                        new_held.pop(paired_rid, None)

            new_cursors = list(cursors)
            new_cursors[task_idx] = c + 1
            new_cursors_t = tuple(new_cursors)

            new_state_key = _make_state_key(
                new_cursors_t,
                new_prod,
                new_cons,
                new_held,
            )
            if new_state_key not in visited:
                visited.add(new_state_key)
                op_desc = f"{stage.name}({res.name})"
                new_path = path + [(task_names[task_idx], op_desc)]
                queue.append(
                    (new_cursors_t, new_prod, new_cons, new_held, new_totals, new_path)
                )

    hit_state_limit = bool(queue and states_explored >= max_states)
    is_safe = not deadlocks and not races and not pdl_order_states

    if verbose:
        print("=" * 72)
        print(
            f"BFS complete: {states_explored} states explored, "
            f"{complete_count} complete, "
            f"{len(deadlocks)} deadlock(s), {len(races)} race(s), "
            f"{len(pdl_order_states)} PDL order violation(s)"
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

    return CheckResult(
        deadlock_states=deadlocks,
        race_states=races,
        states_explored=states_explored,
        complete_count=complete_count,
        is_safe=is_safe,
        pdl_order_states=pdl_order_states,
        hit_state_limit=hit_state_limit,
    )
