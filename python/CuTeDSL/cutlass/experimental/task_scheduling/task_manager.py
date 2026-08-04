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

"""TaskManager for the Task Scheduling (TS) framework.

**Compile-time abstraction**: The entire TS framework (TaskManager, Task,
MemoryResource, pipeline acquire/release/commit) is traced away during DSL
compilation.  The resulting PTX is a single monolithic loop — identical to
what a hand-coded bare-metal kernel would produce.  There is NO runtime
task dispatch and NO framework overhead in the generated GPU code.

..
   If an TS kernel is slower than the equivalent bare-metal kernel, the cause
   is in the generated code (different instruction sequences, register usage,
   loop structure), not in the framework abstractions. Compare PTX/SASS
   directly to diagnose.

``TaskManager`` owns the full list of tasks and the resource dependency graph.
Construction prints the schedule table and runs validation checks.  It then
provides two entry points called from the kernel:

- ``setup_resources_and_tasks()`` - materialises and initializes pipelines
  and barriers for every resource (calls ``resource.create()``).
- ``run()`` - executes all tasks (calls ``task.run()`` for each).
"""

import cutlass
import warnings

import cutlass.cute as cute
import cutlass.pipeline as pipeline
from typing import FrozenSet, Optional, List, Dict, Any, Set, Callable
from typing import Tuple
from .enums import (
    LoopGuard,
    PipelineGroupMode,
    PipelineType,
    ScheduleStage,
    ScheduleStageType,
    SignalingThreads,
    TileSchedulerType,
)
from .memory import ResourceContext, SmemAllocator, TmemAllocator
from dataclasses import replace as _dataclass_replace

from .resources import (
    MemoryResource,
    PdlWaitBarrier,
    PipelineConfig,
    PipelineGroup,
    WorkQueue,
)
from .task import Task


WARP_SIZE = 32


def _combined_schedule(task: Task) -> List:
    """Concatenate head + loop + tail as uniform 4-element tuples.

    Output tuples are ``(resource, stage, call_id, label)``.
    """
    loop_4 = [
        (res, stage, cid, lbl)
        for res, stage, cid, _guard, lbl in task.loop_schedule_list
    ]
    return task.head_schedule_list + loop_4 + task.tail_schedule_list


def _task_has_stage_for_resource(
    task: Task, resource: MemoryResource, stage: ScheduleStage
) -> bool:
    """Check whether *task*'s schedule contains *stage* for *resource*."""
    for entry in (
        task.head_schedule_list + task.loop_schedule_list + task.tail_schedule_list
    ):
        if id(entry[0]) == id(resource) and entry[1] == stage:
            return True
    return False


def _domain_lane_stride(
    task: Task, resource: MemoryResource, stage: ScheduleStage
) -> int:
    """Return the stride when a task owns one domain-split pipeline lane."""
    cfg = resource.pipeline_config
    if cfg is None:
        return 1
    # TaskManager._verify_interleaved_pipelines requires matching opening and
    # closing strides before a task can use a domain-derived lane. Keep the
    # role lookup explicit because ordinary interleaving may use asymmetric
    # strides with separate pipeline states and tasks.
    if stage == ScheduleStage.ProducerAcquire:
        stride = cfg.producer_acquire_interleave_stride
    elif stage == ScheduleStage.ProducerCommit:
        stride = cfg.producer_commit_interleave_stride
    elif stage == ScheduleStage.ConsumerWait:
        stride = cfg.consumer_wait_interleave_stride
    elif stage == ScheduleStage.ConsumerRelease:
        stride = cfg.consumer_release_interleave_stride
    else:
        stride = 1
    return stride if task._uses_domain_interleave_lane(stride) else 1


def _count_independent_interleave_lane(
    counts: Dict[int, int],
    resource_id: int,
    task: Task,
    resource: MemoryResource,
    stage: ScheduleStage,
) -> bool:
    """Pin independent domain-lane participants to one credit per event."""
    if _domain_lane_stride(task, resource, stage) <= 1:
        return False
    counts[resource_id] = 1
    return True


def _try_probe_domain(task: Task) -> int | None:
    """Probe a dynamic-domain getter for a compile-time loop end.

    Calls ``get_domain`` on a representative all-zero work tile and returns the
    result when it folds to a plain ``int`` (so the schedule can be unrolled
    exactly).  Otherwise it warns and returns ``None`` so the caller uses the
    representative fallback.
    """
    validation_tile = (0, 0, 0)
    try:
        end = task.get_domain(validation_tile)
    except Exception:
        end = None
    # Reject bool (an int subclass) and dynamic values.
    if isinstance(end, int) and not isinstance(end, bool):
        return end
    warnings.warn(
        f"Task {task.name!r}: get_domain({validation_tile}) did not yield a "
        "compile-time int loop end; falling back to a representative iteration "
        "count for schedule validation.",
        stacklevel=2,
    )
    return None


def expand_loop(task: Task, dynamic_domain_fallback: int = 1) -> List:
    """Expand a task's schedule into a flat list respecting guards.

    FirstIter (LoopFirstIter) entries appear only on iteration 0;
    LastIter (LoopLastIter) entries appear only on the last iteration;
    Always (Loop) entries appear every iteration.

    When there are zero loop iterations, runtime executes no loop entries.
    An exact count is unrolled only when all bounds are compile-time ints (a
    dynamic domain's getter probe may supply the end); any remaining dynamic
    bound falls back to ``dynamic_domain_fallback`` (a representative total
    domain) so the credit simulator stays bounded.

    Each entry is a 4-tuple ``(resource, stage, call_id, phase_tag)``
    where ``phase_tag`` is one of:

    - ``"H"`` — Head (prefetch, once before the loop)
    - ``""``  — Loop body (every iteration)
    - ``"F"`` — FirstIter (loop, first iteration only)
    - ``"L"`` — LastIter (loop, last iteration only)
    - ``"T"`` — Tail (drain, once after the loop)
    """

    _GUARD_TAG = {
        LoopGuard.Always: "",
        LoopGuard.FirstIter: "F",
        LoopGuard.LastIter: "L",
    }

    # The runtime loop is ``range(domain_start, domain, step)``.  We unroll an
    # exact iteration count only when *every* bound is a compile-time int: a
    # static literal domain, or a dynamic domain whose getter probe folds to an
    # int end -- and, in both cases, a static start/step.
    #
    # All-or-nothing rather than per-field fallbacks: defaulting only the
    # dynamic field (e.g. substituting step=1 while a folded end stays at 1024)
    # would synthesise a 1024-entry loop and explode the credit simulator for
    # what may run a handful of iterations.  Any remaining dynamic bound falls
    # back to a small representative domain via ``dynamic_domain_fallback``.
    domain_attr = task.domain
    domain_start_attr = task.domain_start
    step_attr = task.step
    dynamic_domain = task.domain_getter is not None
    static_start_step = isinstance(domain_start_attr, int) and isinstance(
        step_attr, int
    )
    bounds_static = (
        not dynamic_domain and isinstance(domain_attr, int) and static_start_step
    )
    probe_end = (
        _try_probe_domain(task) if dynamic_domain and static_start_step else None
    )
    if bounds_static:
        # step != 0 is guaranteed by Task.__init__
        loop_iters = len(range(domain_start_attr, domain_attr, step_attr))
    elif probe_end is not None:
        loop_iters = len(range(domain_start_attr, probe_end, step_attr))
    else:
        step_sign = step_attr if isinstance(step_attr, int) else 1
        if step_sign > 0:
            stop = max(1, dynamic_domain_fallback)
            step = step_attr if isinstance(step_attr, int) else 1
        else:
            stop = min(-1, dynamic_domain_fallback)
            step = step_attr if isinstance(step_attr, int) else -1
        loop_iters = max(
            0,
            len(
                range(
                    domain_start_attr if isinstance(domain_start_attr, int) else 0,
                    stop,
                    step,
                )
            ),
        )
    head = [(res, stage, cid, "H") for res, stage, cid, _lbl in task.head_schedule_list]
    tail = [(res, stage, cid, "T") for res, stage, cid, _lbl in task.tail_schedule_list]

    expanded_loop: List = []
    for iter_idx in range(loop_iters):
        is_first = iter_idx == 0
        is_last = iter_idx == loop_iters - 1
        for res, stage, cid, guard, _lbl in task.loop_schedule_list:
            if guard == LoopGuard.FirstIter and not is_first:
                continue
            if guard == LoopGuard.LastIter and not is_last:
                continue
            expanded_loop.append((res, stage, cid, _GUARD_TAG.get(guard, "")))
    if loop_iters == 0:
        return head + tail
    return head + expanded_loop + tail


def print_schedule_list(
    tasks: List[Task],
    func_name: str,
    input_prod_commit_list: Dict[int, Tuple[int, Any]],
    input_cons_release: Dict[int, Tuple[int, Any]],
    initial_cons_release: Dict[int, Tuple[int, Any]],
    check_lists: bool = True,
    schedule_lists: Optional[List[List]] = None,
    verbose: bool = True,
) -> Tuple[Dict[int, Tuple[int, Any]], Dict[int, Tuple[int, Any]]]:
    """Pretty-print one schedule phase and verify producer/consumer pairing.

    Simulates concurrent execution of the schedule entries across all
    tasks in round-robin fashion.  ``ConsumerWait`` and
    ``ProducerAcquire`` stages are treated as blocking: they only
    advance when matching credits are available.  ``ConsumerWait``
    blocks until a ``ProducerCommit`` has been recorded;
    ``ProducerAcquire`` blocks until a ``ConsumerRelease`` has freed
    a pipeline slot (or initial credits remain).  This detects simple
    deadlocks at kernel-build time.

    Parameters
    ----------
    tasks : List[Task]
        All tasks whose schedules are printed side-by-side.
    func_name : str
        Attribute name of the schedule list to inspect
        (``"head_schedule_list"``, ``"loop_schedule_list"``, or
        ``"tail_schedule_list"``).  Ignored when ``schedule_lists``
        is provided.
    input_prod_commit_list : Dict
        Running tally of outstanding commits from a previous phase.
    input_cons_release : Dict
        Running tally of available empty-slot credits (decremented by
        ``ProducerAcquire``, incremented by ``ConsumerRelease``).
    initial_cons_release : Dict
        Snapshot of ``input_cons_release`` at phase start, used for
        balance checking at end-of-phase.
    check_lists : bool
        If ``True``, raise ``ValueError`` when unconsumed commits or
        unbalanced acquires/releases remain after the phase completes.
    schedule_lists : Optional[List[List]]
        If provided, use these per-task schedule lists directly instead
        of looking up ``func_name`` on each task.

    Returns
    -------
    Tuple[Dict, Dict]
        Updated ``(prod_commit_list, cons_release)`` for chaining
        into the next phase.

    Raises
    ------
    ValueError
        If a blocking stage cannot make progress (deadlock) or if
        ``check_lists`` is ``True`` and there are unpaired commits /
        acquires.
    """
    task_idx = [0] * len(tasks)
    prod_commit_list = input_prod_commit_list
    cons_release = input_cons_release
    blocking_stages = {ScheduleStage.ConsumerWait, ScheduleStage.ProducerAcquire}
    if schedule_lists is None:
        schedule_lists = [getattr(t, func_name) for t in tasks]

    # Normalize to 4-tuples (res, stage, cid, phase_tag) so the
    # printer can show Head/Tail/FirstIter/LastIter markers.
    schedule_lists = [
        [
            (e[0], e[1], e[2], e[3]) if len(e) > 3 else (e[0], e[1], e[2], "")
            for e in sched
        ]
        for sched in schedule_lists
    ]

    def _sname(resource: MemoryResource) -> str:
        return resource.name[:10] if len(resource.name) > 10 else resource.name

    # WorkQueue schedule spans multiple work tiles and is not tracked here yet.
    def _track_resource(res: MemoryResource) -> bool:
        return not isinstance(res, WorkQueue)

    def _credit_key(res: MemoryResource) -> int:
        """Canonical id for credit tracking."""
        return id(res)

    # ── Credit model for merge/fork pipelines ───────────────────────
    # In a merge/fork PipelineGroup, a single pipeline stage involves
    # multiple tasks on the same side (e.g. two producers filling
    # smem_a and smem_b).  A credit must only be produced/consumed
    # when ALL participating tasks complete their part of the round:
    #
    #   Merge (N producers → 1 consumer):
    #     ProducerCommit fires N times per stage; credit += 1 only
    #     after the Nth commit.  ConsumerWait consumes that credit.
    #
    #   Fork (1 producer → N consumers):
    #     ConsumerRelease fires N times per stage; credit += 1 only
    #     after the Nth release.  ProducerAcquire consumes that credit.
    #
    # Full-round completion is detected via total event counts and
    # modulo: ``_total_commits[rid] % n_comm == 0`` means all N
    # committers have committed for this round.
    # Per-operation counts: how many distinct tasks perform each
    # barrier operation on each resource.  In standard 1:1 pipelines
    # all counts are 1.  In merge/fork groups N tasks share a pipeline
    # and the modulo logic ensures a credit is produced/consumed only
    # after all N participants have completed their part.
    #
    # Counted from actual schedule operations rather than src/dst
    # resource lists to correctly handle split-consumer patterns where
    # a task may list a resource in src_resources (for ConsumerWork +
    # ConsumerRelease) without performing ConsumerWait on it.
    _num_committers: Dict[int, int] = {}  # tasks that ProducerCommit
    _num_waiters: Dict[int, int] = {}  # tasks that ConsumerWait
    _num_releasers: Dict[int, int] = {}  # tasks that ConsumerRelease
    _num_acquirers: Dict[int, int] = {}  # tasks that ProducerAcquire
    for task, task_sched in zip(tasks, schedule_lists):
        seen_commit: Set[int] = set()
        seen_wait: Set[int] = set()
        seen_release: Set[int] = set()
        seen_acquire: Set[int] = set()
        for entry in task_sched:
            res = entry[0]
            stage = entry[1]
            if not _track_resource(res):
                continue
            rid = _credit_key(res)
            # For Fork groups, ProducerCommit is on the group object
            # but delivers credits to each member.  Count per-member.
            if stage == ScheduleStage.ProducerCommit:
                if (
                    isinstance(res, PipelineGroup)
                    and res.mode == PipelineGroupMode.Fork
                ):
                    for _m in res.members:
                        _mid = id(_m)
                        if _mid not in seen_commit:
                            _num_committers[_mid] = _num_committers.get(_mid, 0) + 1
                            seen_commit.add(_mid)
                elif _count_independent_interleave_lane(
                    _num_committers, rid, task, res, stage
                ):
                    pass
                elif rid not in seen_commit:
                    _num_committers[rid] = _num_committers.get(rid, 0) + 1
                    seen_commit.add(rid)
            elif stage == ScheduleStage.ConsumerWait:
                if _count_independent_interleave_lane(
                    _num_waiters, rid, task, res, stage
                ):
                    pass
                elif rid not in seen_wait:
                    _num_waiters[rid] = _num_waiters.get(rid, 0) + 1
                    seen_wait.add(rid)
            # For Merge groups, ConsumerRelease is on the group object
            # but delivers credits to each member.  Count per-member.
            elif stage == ScheduleStage.ConsumerRelease:
                if (
                    isinstance(res, PipelineGroup)
                    and res.mode == PipelineGroupMode.Merge
                ):
                    for _m in res.members:
                        _mid = id(_m)
                        if _mid not in seen_release:
                            _num_releasers[_mid] = _num_releasers.get(_mid, 0) + 1
                            seen_release.add(_mid)
                elif _count_independent_interleave_lane(
                    _num_releasers, rid, task, res, stage
                ):
                    pass
                elif rid not in seen_release:
                    _num_releasers[rid] = _num_releasers.get(rid, 0) + 1
                    seen_release.add(rid)
            elif stage == ScheduleStage.ProducerAcquire:
                if _count_independent_interleave_lane(
                    _num_acquirers, rid, task, res, stage
                ):
                    pass
                elif rid not in seen_acquire:
                    _num_acquirers[rid] = _num_acquirers.get(rid, 0) + 1
                    seen_acquire.add(rid)

    _total_commits: Dict[int, int] = {}
    _total_waits: Dict[int, int] = {}
    _total_releases: Dict[int, int] = {}
    _total_acquires: Dict[int, int] = {}

    max_steps = max((len(s) for s in schedule_lists), default=0) + 100
    for idx in range(max_steps):
        line = "|"
        status_array = []
        for i, task in enumerate(tasks):
            sched = schedule_lists[i]
            if task_idx[i] >= len(sched):
                status_array.append(0)
            else:
                _res, _stage, _, _tag = sched[task_idx[i]]
                if _stage in blocking_stages and _track_resource(_res):
                    rid = _credit_key(_res)
                    if _stage == ScheduleStage.ConsumerWait:
                        if rid in prod_commit_list and prod_commit_list[rid][0] > 0:
                            status_array.append(2)  # resolvable --> runnable
                        else:
                            status_array.append(1)  # genuinely blocked
                    elif _stage == ScheduleStage.ProducerAcquire:
                        if rid in cons_release and cons_release[rid][0] > 0:
                            status_array.append(2)  # resolvable --> runnable
                        else:
                            status_array.append(1)  # genuinely blocked
                else:
                    status_array.append(2)
        if all(x == 0 for x in status_array):
            break
        if all(x == 0 or x == 1 for x in status_array):
            for i, task in enumerate(tasks):
                sched = schedule_lists[i]
                if task_idx[i] < len(sched):
                    resource, schedule_stage, call_id_loop, _tag = sched[task_idx[i]]
                    raise ValueError(
                        f"{_sname(resource):10} {schedule_stage.name:14} "
                        f"{call_id_loop:2} is blocked!  "
                        f"NOTE: if the domain is not a compile-time Python "
                        f"int, this may be a FALSE POSITIVE (domain defaults "
                        f"to 1).  Re-run with a realistic int domain via "
                        f"validate-only mode for accurate results."
                    )
            break
        for i, task in enumerate(tasks):
            sched = schedule_lists[i]
            if task_idx[i] >= len(sched):
                line += " " * 30 + "|"
                continue
            resource, schedule_stage, call_id_loop, phase_tag = sched[task_idx[i]]
            sname = _sname(resource)
            rid = _credit_key(resource)
            track = _track_resource(resource)

            if track and schedule_stage == ScheduleStage.ProducerCommit:
                # Merge: ``ProducerCommit`` is per-member; the shared
                # empty barrier is unrelated to commits.
                # Fork: ``(group, ProducerCommit)`` is the only legal
                # form — the shared full barrier fires once per stage
                # and delivers credits to every member (whose
                # ``ConsumerWait`` is keyed on member id).  Recording
                # a credit under the group's id would show up at the
                # end-of-schedule reconciliation as an unmatched
                # commit.
                if (
                    isinstance(resource, PipelineGroup)
                    and resource.mode == PipelineGroupMode.Fork
                ):
                    for _m in resource.members:
                        _mid = id(_m)
                        n_comm = _num_committers.get(_mid, 1)
                        _total_commits[_mid] = _total_commits.get(_mid, 0) + 1
                        if _total_commits[_mid] % n_comm == 0:
                            mc, mr = prod_commit_list.get(_mid, (0, _m))
                            prod_commit_list[_mid] = (mc + 1, mr)
                else:
                    n_comm = _num_committers.get(rid, 1)
                    _total_commits[rid] = _total_commits.get(rid, 0) + 1
                    if _total_commits[rid] % n_comm == 0:
                        count, res = prod_commit_list.get(rid, (0, resource))
                        prod_commit_list[rid] = (count + 1, res)
            if track and schedule_stage == ScheduleStage.ConsumerRelease:
                # Merge: ``(group, ConsumerRelease)`` is the only
                # legal form — the shared empty barrier fires once
                # and releases all members.  Track credits on each
                # member (their ``ProducerAcquire`` is keyed on
                # member id); the group itself has no
                # ``ProducerAcquire`` counterpart, so recording a
                # credit under the group's id would show up at the
                # end-of-schedule reconciliation as an unmatched
                # release.
                # Fork: per-member empties; ``ConsumerRelease`` lives
                # on each member directly, no propagation needed.
                if (
                    isinstance(resource, PipelineGroup)
                    and resource.mode == PipelineGroupMode.Merge
                ):
                    for _m in resource.members:
                        _mid = id(_m)
                        n_rel = _num_releasers.get(_mid, 1)
                        _total_releases[_mid] = _total_releases.get(_mid, 0) + 1
                        if _total_releases[_mid] % n_rel == 0:
                            mc, mr = cons_release.get(_mid, (0, _m))
                            cons_release[_mid] = (mc + 1, mr)
                else:
                    n_rel = _num_releasers.get(rid, 1)
                    _total_releases[rid] = _total_releases.get(rid, 0) + 1
                    if _total_releases[rid] % n_rel == 0:
                        count, res = cons_release.get(rid, (0, resource))
                        cons_release[rid] = (count + 1, res)

            if track and schedule_stage in blocking_stages:
                resolvable = False
                if schedule_stage == ScheduleStage.ConsumerWait:
                    resolvable = (
                        rid in prod_commit_list and prod_commit_list[rid][0] > 0
                    )
                elif schedule_stage == ScheduleStage.ProducerAcquire:
                    resolvable = rid in cons_release and cons_release[rid][0] > 0
                if resolvable:
                    line += f" {sname:10} {str(schedule_stage):12}{phase_tag:>2} {call_id_loop:2} |"
                    task_idx[i] += 1
                    if schedule_stage == ScheduleStage.ConsumerWait:
                        n_wait = _num_waiters.get(rid, 1)
                        _total_waits[rid] = _total_waits.get(rid, 0) + 1
                        if _total_waits[rid] % n_wait == 0:
                            count, res = prod_commit_list[rid]
                            prod_commit_list[rid] = (count - 1, res)
                    elif schedule_stage == ScheduleStage.ProducerAcquire:
                        n_acq = _num_acquirers.get(rid, 1)
                        _total_acquires[rid] = _total_acquires.get(rid, 0) + 1
                        if _total_acquires[rid] % n_acq == 0:
                            count, res = cons_release[rid]
                            cons_release[rid] = (count - 1, res)
                else:
                    line += " " * 30 + "|"
            else:
                line += f" {sname:10} {str(schedule_stage):12}{phase_tag:>2} {call_id_loop:2} |"
                task_idx[i] += 1
        if verbose:
            print(line)
    if check_lists:
        for key, value in prod_commit_list.items():
            if value[0] > 0:
                # Ignore WorkQueue resources as they span across multiple work tiles
                if not isinstance(value[1], WorkQueue):
                    raise ValueError(
                        f"{value[0]}x ProducerCommit from {value[1].name} not consumed!"
                    )
        for key, value in cons_release.items():
            if isinstance(value[1], WorkQueue):
                continue
            initial = initial_cons_release.get(key, (0, value[1]))
            diff = initial[0] - value[0]
            if diff > 0:
                raise ValueError(
                    f"{diff}x ProducerAcquire from {value[1].name} "
                    f"not matched by ConsumerRelease!"
                )
            elif diff < 0:
                raise ValueError(
                    f"{-diff}x ConsumerRelease from {value[1].name} "
                    f"not matched by ProducerAcquire!"
                )
    return prod_commit_list, cons_release


class TaskManager:
    """Orchestrates the execution of all tasks and their shared resources.

    Attributes
    ----------
    tasks : List[Task]
        All tasks in execution order.
    resources : List[MemoryResource]
        De-duplicated union of every task's ``src_resources`` and
        ``dst_resources``, preserving first-seen order.

    Notes
    -----
    Kernel entry points:

    * ``setup_resources_and_tasks()`` - materialises and initializes pipelines
      and barriers by calling ``resource.create()`` on each resource. Must be
      called once before ``run()``.
    * ``run()`` - executes every task by calling ``task.run()``. Validation has
      already run during construction via ``print_and_verify()``.
    """

    def __init__(
        self,
        tasks: List[Task],
        resource_dependency_graph: Dict[MemoryResource, List[MemoryResource]],
        dma_consumer_release_labels: Optional[
            Dict[Tuple[MemoryResource, MemoryResource], Set[str]]
        ] = None,
        skip_validation: bool = False,
        smem_allocator: Optional[SmemAllocator] = None,
        tmem_allocator: Optional[TmemAllocator] = None,
        tmem_ptr_i32: Optional[Any] = None,
        verbose: bool = True,
        smem_capacity_bytes: Optional[int] = None,
        tmem_capacity_columns: Optional[int] = None,
        exhaustive_deadlock_race_check: bool = True,
        assume_pdl_wait_completed: bool = False,
    ) -> None:
        """
        Parameters
        ----------
        tasks : List[Task]
            All tasks in execution order.
        resource_dependency_graph : Dict[MemoryResource, List[MemoryResource]]
            Explicit dataflow dependency graph.  Each key is a *downstream*
            resource whose producer work depends on the consumer work of the
            upstream resources listed in the value.

            For example, in a pipeline
            ``GmemAb --> SmemAb --> TmemC --> GmemD``::

                resource_dependency_graph = {
                    smem_ab: [gmem_ab],
                    tmem_c:  [smem_ab],
                    gmem_d:  [tmem_c],
                }

            The manager verifies that every declared edge
            ``(upstream --> downstream)`` is backed by a task whose
            ``src_resources`` contain the upstream resource and whose
            ``dst_resources`` contain the downstream resource.
        dma_consumer_release_labels : Dict[Tuple[MemoryResource, MemoryResource], Set[str]], optional
            Edge-specific named consumer-release labels for DMA ordering
            validation.  Use this when one upstream resource feeds multiple
            downstream DMA producers through different named consumer work
            functions.  Keys are ``(upstream, downstream)`` resource pairs.
        skip_validation : bool, optional
            When ``True``, verification checks still run but failures are
            emitted as warnings instead of raising exceptions.  Use this
            when domains are runtime values (not Python ``int``), since
            the deadlock simulation falls back to ``domain=1`` and may
            report false-positive deadlocks.  For accurate verification,
            prefer validate-only mode with realistic ``int`` domains.
            Default False.
        smem_allocator : cutlass.experimental.task_scheduling.memory.SmemAllocator or None, optional
            Unified SMEM allocator with pre-computed layout.  When set,
            ``setup_resources_and_tasks()`` calls ``smem_allocator.allocate()``
            and the resulting ``smem_base`` is threaded through
            ``ResourceContext`` / ``StageInfo`` to all resources.
        tmem_allocator : cutlass.experimental.task_scheduling.memory.TmemAllocator or None, optional
            TMEM column allocator with pre-computed layout.  When set,
            a usage report is printed during ``print_and_verify()``.
        tmem_ptr_i32 : array or None, optional
            Shared-memory ``Int32`` scalar written by
            ``nvvm.tcgen05_alloc``.  When set, it is included in the
            ``ResourceContext`` so resources can derive TMEM addresses.
        verbose : bool, optional
            When ``False``, suppresses informational output (schedule
            tables, register budgets, aliasing notes).  Errors and
            warnings are always emitted.  Default ``True``.

        smem_capacity_bytes : int or None, optional
            Maximum SMEM bytes per CTA (data + barriers).  When
            ``None``, defaults to ``(228 − 1) × 1024 = 232448 B``
            (SM100/SM90).  Override for other architectures.
        tmem_capacity_columns : int or None, optional
            Maximum TMEM columns per SM.  When ``None``, defaults to
            ``512`` (SM100).  Override for other architectures.
        exhaustive_deadlock_race_check : bool, optional
            When ``True``, run the exhaustive BFS interleaving checker
            (``check_all_interleavings``) that explores all valid
            schedule interleavings to detect deadlocks, aliasing race
            conditions, and PDL launch-before-wait ordering violations.
            Significantly more expensive than the structural checks.
            Pass ``False`` to opt out for
            performance-sensitive paths (e.g. FMHA).  Default ``True``.
        assume_pdl_wait_completed : bool, optional
            Treat PDL wait as already executed before the TS schedule.
            This is for kernels that emit ``griddepcontrol.wait`` before a
            PDL-dependent access that happens outside TS.
        """
        self.tasks = tasks
        if not resource_dependency_graph:
            raise ValueError(
                "resource_dependency_graph must be provided and non-empty."
            )
        self.resource_dependency_graph = resource_dependency_graph
        self._dma_consumer_release_labels: dict[tuple[int, int], set[str]] = {
            (id(upstream), id(downstream)): set(labels)
            for (upstream, downstream), labels in (
                dma_consumer_release_labels or {}
            ).items()
        }
        # Create a unique list of resources from all tasks and their src and dst
        # resources.  PipelineGroups are auto-discovered from members'
        # ``pipeline_group`` attributes and prepended so that
        # ``group.create()`` runs before member setup.
        all_resources = []
        seen = set()
        discovered_groups = []
        for task in self.tasks:
            for resource in task.src_resources + task.dst_resources:
                if id(resource) not in seen:
                    all_resources.append(resource)
                    seen.add(id(resource))
                    pg = getattr(resource, "pipeline_group", None)
                    if pg is not None and id(pg) not in seen:
                        discovered_groups.append(pg)
                        seen.add(id(pg))
        self.resources = discovered_groups + all_resources
        self._is_setup = False
        self._warn_only = skip_validation
        self._smem_allocator = smem_allocator
        self._tmem_allocator = tmem_allocator
        self._smem_base = None
        self._tmem_ptr_i32 = tmem_ptr_i32
        self._verbose = verbose
        self._smem_capacity_bytes = (
            smem_capacity_bytes
            if smem_capacity_bytes is not None
            else self._DEFAULT_SMEM_CAPACITY_BYTES
        )
        self._tmem_capacity_columns = (
            tmem_capacity_columns
            if tmem_capacity_columns is not None
            else self._DEFAULT_TMEM_CAPACITY_COLUMNS
        )
        self._exhaustive_deadlock_race_check = exhaustive_deadlock_race_check
        self._assume_pdl_wait_completed = assume_pdl_wait_completed

        self._assign_default_task_registers()
        self._prepare_resource_runtime_metadata()
        self.print_and_verify()

        # TODO: create padding tasks to have multiple of 4 warps

    @property
    def smem_allocator(self) -> Optional[SmemAllocator]:
        """The SMEM allocator (if configured)."""
        return self._smem_allocator

    def _default_task_registers(self) -> int:
        """Return the initial per-thread register count for each warp."""
        regs_per_sm = 65536
        threads_per_warp = 32
        warp_group_size = 4
        setmaxnreg_granularity = 8

        total_num_warps = sum(task.num_warps for task in self.tasks)
        num_warp_groups = (total_num_warps + warp_group_size - 1) // warp_group_size
        rounded_num_warps = num_warp_groups * warp_group_size
        return (
            regs_per_sm
            // (rounded_num_warps * threads_per_warp * setmaxnreg_granularity)
            * setmaxnreg_granularity
        )

    def _assign_default_task_registers(self) -> None:
        """Expose the computed default register count to task codegen."""
        default_num_regs = self._default_task_registers()
        for task in self.tasks:
            task.default_num_registers = default_num_regs

    def _build_initial_cons_release(self) -> Dict[int, Tuple[int, Any]]:
        """Build initial release credits for all pipelined resources.

        Each pipelined resource starts with ``num_stages`` credits,
        representing all buffer slots being empty (available for
        producer acquire).  Group members get their own independent
        credits (group objects are skipped since they are not in
        schedules).
        """
        credits: Dict[int, Tuple[int, Any]] = {}
        for resource in self.resources:
            has_pipeline = resource.pipeline_config is not None
            if (
                has_pipeline
                and not isinstance(resource, WorkQueue)
                and not isinstance(resource, PipelineGroup)
            ):
                rid = id(resource)
                if rid not in credits:
                    credits[rid] = (resource.pipeline_config.num_stages, resource)
        return credits

    def _print_task_schedules(self) -> None:
        """Print the head, loop, and tail schedules as a formatted table."""
        task_line = "|"
        for task in self.tasks:
            sname = f"{task.name}[{task.warp_start}:{task.warp_end})"
            task_line = task_line + f" {sname:^28} |"
        table_width = len(task_line)
        full_border = "=" * table_width

        def section_title(label: str) -> str:
            """Build a centered section title with '=' paddings."""
            title = f"> {label} <"
            pad_total = max(table_width - len(title), 0)
            left_pad = "=" * (pad_total // 2)
            right_pad = "=" * (pad_total - (pad_total // 2))
            return f"{left_pad}{title}{right_pad}"

        if self._verbose:
            print(f"\n{full_border}\n")
            print(task_line)

        initial_cons_release = self._build_initial_cons_release()

        def run_section(
            label: str,
            schedule_attr: str = "",
            prod_commit_list: Optional[Dict] = None,
            cons_release: Optional[Dict] = None,
            check_lists: bool = True,
            schedule_lists_override: Optional[List] = None,
        ) -> Tuple[Dict, Dict]:
            if self._verbose:
                print(f"\n{section_title(f'  {label}  ')}\n")
            if cons_release is None:
                rc = dict(initial_cons_release)
            else:
                rc = cons_release
            out_commit, out_release = print_schedule_list(
                self.tasks,
                schedule_attr,
                {} if prod_commit_list is None else prod_commit_list,
                rc,
                initial_cons_release,
                check_lists,
                schedule_lists=schedule_lists_override,
                verbose=self._verbose,
            )
            if self._verbose:
                print(f"\n{section_title(f'End {label}')}\n")
            return out_commit, out_release

        # Combined simulation: HEAD + LOOP*domain + TAIL concatenated per task.
        # No global barrier between phases — each task independently
        # transitions HEAD -> LOOP -> TAIL, matching real hardware execution
        # where there is no cross-task synchronization between schedule phases.
        # The LOOP body is repeated a number of times representing real-world
        # conditions so that the simulation accurately
        # reflects the actual iteration counts — critical for schedules
        # with different per-task domains or ping-pong patterns that need
        # multiple iterations to balance.
        # Guard-aware expansion: LoopFirstIter fires only on iter 0,
        # LoopLastIter fires only on the last iter.
        #
        # Non-int domains that do not fold via the getter probe use a small
        # representative total domain: one past the largest static
        # ``domain_start`` so delayed-producer schedules with head prefetch still
        # get a balanced loop iteration (avoids false-positive deadlocks).
        dynamic_domain_fallback = (
            max(
                (t.domain_start for t in self.tasks if isinstance(t.domain_start, int)),
                default=0,
            )
            + 1
        )
        combined_schedules = [
            expand_loop(t, dynamic_domain_fallback=dynamic_domain_fallback)
            for t in self.tasks
        ]
        run_section(
            label="Full (Head + Loop + Tail)",
            schedule_lists_override=combined_schedules,
            check_lists=True,
        )
        if self._verbose:
            print(
                "Phase tags:  H — Head (prefetch, before the loop)"
                "  |  F — FirstIter (first iteration only)"
                "  |  L — LastIter (last iteration only)"
                "  |  T — Tail (drain, after the loop)"
            )

    def _verify_warp_group_registers(self) -> None:
        """Verify that tasks sharing a warp group of 4 use the same register count.

        Hardware requires that every group of 4 consecutive warps (a *warp
        group*) execute with the same ``setmaxnreg`` budget.  A task that
        spans warps ``[W, W+N)`` overlaps warp groups ``W // 4`` through
        ``(W + N - 1) // 4`` inclusive.

        Tasks whose ``num_registers`` is ``None`` are ignored (they do
        not emit a ``setmaxregister`` instruction).  If at least two tasks
        in the same warp group specify *different* non-``None`` values the
        check fails.

        Additionally, when any task in a warp group specifies a non-``None``
        ``num_registers``, **all** 4 warps in that group must be covered by
        tasks that also specify ``num_registers``.

        Raises
        ------
        ValueError
            If two tasks in the same warp group specify different
            ``num_registers`` values, or if ``num_registers`` is set but
            not all 4 warps in the group are covered.
        """
        WARP_GROUP_SIZE = 4
        # Map: warp_group_id -> list of (task_name, num_registers)
        warp_group_regs: Dict[int, List[Tuple[str, Optional[int]]]] = {}
        # Map: warp_group_id -> set of warp indices covered by tasks
        # with num_registers set
        warp_group_covered: Dict[int, set] = {}

        for task in self.tasks:
            warp_start = task.warp_idx
            if not isinstance(warp_start, int):
                # Cannot verify at Python time if warp_idx is not a static int
                raise ValueError(f"warp_idx is not a static int: {warp_start}")
            warp_end = warp_start + task.num_warps

            # Determine which warp groups this task overlaps
            first_group = warp_start // WARP_GROUP_SIZE
            last_group = (warp_end - 1) // WARP_GROUP_SIZE

            for group_id in range(first_group, last_group + 1):
                if group_id not in warp_group_regs:
                    warp_group_regs[group_id] = []
                    warp_group_covered[group_id] = set()
                warp_group_regs[group_id].append((task.name, task.num_registers))

                # Track which warps within this group are covered by this task
                if task.num_registers is not None:
                    group_warp_start = group_id * WARP_GROUP_SIZE
                    group_warp_end = group_warp_start + WARP_GROUP_SIZE
                    # Intersect [warp_start, warp_end) with
                    # [group_warp_start, group_warp_end)
                    lo = max(warp_start, group_warp_start)
                    hi = min(warp_end, group_warp_end)
                    for w in range(lo, hi):
                        warp_group_covered[group_id].add(w)

        # Check each warp group for conflicting register budgets
        for group_id, entries in sorted(warp_group_regs.items()):
            # Collect distinct non-None register values
            reg_values = {regs for _, regs in entries if regs is not None}
            if len(reg_values) > 1:
                details = ", ".join(
                    f"'{name}' (num_registers={regs})" for name, regs in entries
                )
                raise ValueError(
                    f"Warp group {group_id} (warps [{group_id * WARP_GROUP_SIZE}, "
                    f"{(group_id + 1) * WARP_GROUP_SIZE})) has tasks with "
                    f"different num_registers values: {details}. "
                    f"All tasks within the same warp group of {WARP_GROUP_SIZE} "
                    f"warps must use the same num_registers setting."
                )

            # When num_registers is specified, all 4 warps in the group must
            # be covered by tasks that set num_registers.
            if reg_values:
                group_warp_start = group_id * WARP_GROUP_SIZE
                expected_warps = set(
                    range(group_warp_start, group_warp_start + WARP_GROUP_SIZE)
                )
                covered = warp_group_covered[group_id]
                missing = expected_warps - covered
                if missing:
                    details = ", ".join(
                        f"'{name}' (num_registers={regs})" for name, regs in entries
                    )
                    raise ValueError(
                        f"Warp group {group_id} (warps [{group_warp_start}, "
                        f"{group_warp_start + WARP_GROUP_SIZE})) has "
                        f"num_registers set but warps {sorted(missing)} are not "
                        f"covered by any task with num_registers specified. "
                        f"When num_registers is set, all {WARP_GROUP_SIZE} warps "
                        f"in the group must be covered. "
                        f"One might need to create a padding task "
                        f"to cover the missing warps. "
                        f"Tasks in this group: {details}."
                    )

    def _verify_register_budget(self) -> None:
        """Verify total register usage fits within the SM register file.

        For each task the register consumption is
        ``num_warps * THREADS_PER_WARP * num_registers``.  The sum over all
        tasks must not exceed the SM register-file capacity
        (``REGS_PER_SM = 65536`` 32-bit registers on current architectures).

        Tasks whose ``num_registers`` is ``None`` are counted using the
        hardware maximum (``DEFAULT_NUM_REGS = 128``).

        Raises
        ------
        ValueError
            If the total register usage exceeds the SM register file capacity.
        """
        THREADS_PER_WARP = 32
        REGS_PER_SM = 65536

        num_regs = 0
        reg_budget = 0
        default_num_regs = self._default_task_registers()

        for ii, task in enumerate(self.tasks):
            num_warps = task.num_warps
            # Use default if num_registers is not specified (conservative estimate)
            num_regs_per_thread = (
                task.num_registers
                if task.num_registers is not None
                else default_num_regs
            )

            # Accumulate total register usage
            num_regs += num_warps * THREADS_PER_WARP * num_regs_per_thread

            # Contribution to the register budget from this task
            reg_budget_contribution = num_warps * (
                default_num_regs - num_regs_per_thread
            )
            reg_budget += reg_budget_contribution

            if self._verbose:
                print(
                    f"Task {ii:>2} '{task.name:<20}', "
                    f"numWarps x (defaultMaxNumRegs - numRegsPerThread) = "
                    f"{num_warps} x ({default_num_regs:>3} - {num_regs_per_thread:>3}) = "
                    f"{reg_budget_contribution}"
                )

        # The number of registers per SM.
        num_regs_per_sm = REGS_PER_SM
        # Number of registers per block when allocating more registers
        # per warp-group.
        WARPS_PER_WARP_GROUP = 4
        num_regs_per_block = WARPS_PER_WARP_GROUP * THREADS_PER_WARP * 8
        # The number of free blocks of 8 registers per warp.
        free_reg_blocks = max(0, (num_regs_per_sm - num_regs) // num_regs_per_block)

        if self._verbose:
            print(f"Num. regs: {num_regs} (free reg blocks: {free_reg_blocks})")
            print(f"Reg budget: {reg_budget}")

        # Make sure the number of registers does not exceed the limit.
        if num_regs > num_regs_per_sm:
            raise ValueError(
                f"Too many registers needed: {num_regs} "
                f"(SM register file capacity: {num_regs_per_sm})"
            )
        if reg_budget < 0:
            raise ValueError(f"Negative register budget: {reg_budget}")

    # SM100/SM90 default limits (max opt-in SMEM per CTA and TMEM columns).
    # Override via smem_capacity_bytes / tmem_capacity_columns in __init__
    # for other architectures.
    _DEFAULT_SMEM_CAPACITY_BYTES = (228 - 1) * 1024  # 232448 B
    _DEFAULT_TMEM_CAPACITY_COLUMNS = 512  # SM100

    def _verify_smem_capacity(self) -> None:
        """Verify that SMEM usage does not exceed the hardware capacity.

        Checks the ``SmemAllocator``'s data bytes plus barrier bytes
        against ``smem_capacity_bytes`` (default 228 KB − 1 KB for
        SM100).

        Skipped when no ``SmemAllocator`` is configured.

        Raises
        ------
        ValueError
            If total SMEM exceeds the capacity.
        """
        if self._smem_allocator is None:
            return
        data_bytes = self._smem_allocator.total_smem_bytes
        barrier_bytes = self._smem_allocator.barrier_smem_bytes
        total_bytes = data_bytes + barrier_bytes
        capacity = self._smem_capacity_bytes

        if self._verbose:
            print(
                f"SMEM usage: {total_bytes} B "
                f"(data {data_bytes} B + barriers {barrier_bytes} B) "
                f"/ {capacity} B capacity"
            )

        if total_bytes > capacity:
            raise ValueError(
                f"SMEM usage ({total_bytes} B = "
                f"{data_bytes} B data + {barrier_bytes} B barriers) "
                f"exceeds hardware capacity ({capacity} B). "
                f"Reduce buffer sizes, pipeline stages, or use alias groups "
                f"to share physical memory."
            )

    def _verify_tmem_capacity(self) -> None:
        """Verify that TMEM column usage does not exceed the hardware capacity.

        Checks the ``TmemAllocator``'s total columns against
        ``tmem_capacity_columns`` (default 512 for SM100).

        Skipped when no ``TmemAllocator`` is configured.

        Raises
        ------
        ValueError
            If total TMEM columns exceed the capacity.
        """
        if self._tmem_allocator is None:
            return
        total_cols = self._tmem_allocator.total_tmem_columns
        capacity = self._tmem_capacity_columns

        if self._verbose:
            print(f"TMEM usage: {total_cols} columns / {capacity} columns capacity")

        if total_cols > capacity:
            raise ValueError(
                f"TMEM usage ({total_cols} columns) exceeds hardware "
                f"capacity ({capacity} columns). "
                f"Reduce accumulator stages or tile sizes, or use "
                f"alias groups to share TMEM regions."
            )

    # -- Stage classification constants (used by _verify_slot_routing) --
    _CONSUMER_WORK_STAGES: FrozenSet[ScheduleStage] = frozenset(
        {
            ScheduleStage.ConsumerAuxWork,
            ScheduleStage.ConsumerWork,
        }
    )
    _PRODUCER_WORK_STAGES: FrozenSet[ScheduleStage] = frozenset(
        {
            ScheduleStage.ProducerAuxWork,
            ScheduleStage.ProducerWork,
        }
    )

    def _verify_slot_routing(self) -> None:
        """Validate every task's ``slot_routing`` against the dataflow rules.

        ``task.slot_routing`` is the single user-facing input that drives
        slot-based variable flow.  Its shape is the exact runtime-form
        dict consumed by ``Task._consumer_work*`` — see
        :data:`ts.resources.SlotRouting` for the full schema.

        This pass enforces the following rules, rejecting the task with
        a ``ValueError`` on any violation.  It is **validation only**:
        no routing is synthesised; the runtime uses ``task.slot_routing``
        verbatim after this check passes.

        1. **Stage legality.**
           Every writer slot key uses ``ConsumerAuxWork`` or
           ``ConsumerWork`` on a resource in ``task.src_resources``.
           Every destination uses either a ``ProducerAuxWork`` or
           ``ProducerWork`` stage on a resource in ``task.dst_resources``
           (producer-side destination, writes to ``producer_vars``) or a
           ``ConsumerAuxWork`` or ``ConsumerWork`` stage on a resource in
           ``task.src_resources`` (consumer-side destination, writes to
           ``consumer_vars``).

        2. **call_idx in range.**
           Every ``call_idx`` (on the writer key and on each
           destination) addresses an existing schedule entry with that
           ``(resource, stage, stage_type)`` tuple.  Route lists and
           destination lists must be non-empty.  A route is either
           ``"name"`` for same-name copy or ``("src_name", "dst_name")``
           for explicit source-to-destination remapping.

           A single destination slot and destination variable name may
           not receive multiple different source variables.

        3. **Schedule ordering + most-recent-writer rule.**
           For every routing edge ``(writer, src_var, dst_var, reader)``,
           the writer must be the *correct* producer of ``src_var`` for
           that reader under the runtime's copy semantics.  Concretely,
           this pass derives per-slot write and read sets from the
           routing and re-resolves the edges with a linear matcher over
           the combined schedule (head + loop body + tail): each reader
           is fed by the writer of ``src_var`` whose schedule position is
           the largest that is strictly less than the reader's position.
           The resulting edge set, including destination aliases, must
           equal the user-supplied edge set.

           If the user edge set and the matcher edge set differ, this
           pass raises ``ValueError`` listing every mismatched edge and
           aborts kernel build.  Two categories of mismatch trigger
           the error:

             - *extra* edges — edges the user supplied that the matcher
               would not produce.  At runtime a later writer of the
               same variable would overwrite the earlier writer's
               ``copy_consumer_vars_to`` before the reader ran, so the
               reader would observe a different version than the one
               the user's edge implies.
             - *missing* edges — edges the matcher would produce that
               the user did not supply.  Without them the runtime copy
               plan never delivers the value to the reader, which
               would then observe an uninitialised or stale variable.

        Raises
        ------
        ValueError
            On any structural or ordering violation, with a message
            identifying the offending edge(s) and, for rule-3
            violations, the expected routing fixup.
        """
        consumer_stages = self._CONSUMER_WORK_STAGES
        producer_stages = self._PRODUCER_WORK_STAGES
        writer_stages = consumer_stages

        for task in self.tasks:
            if task.slot_routing is None:
                continue

            src_by_id = {id(r): r for r in task.src_resources}
            dst_by_id = {id(r): r for r in task.dst_resources}
            all_by_id = {**src_by_id, **dst_by_id}

            # Build schedule-position metadata: slot_key -> linear position.
            # Slot keys include the schedule section so Loop and Tail slots
            # with the same per-section call_idx do not alias.
            combined = (
                [
                    (ScheduleStageType.Head, res, stage, cid, lbl)
                    for res, stage, cid, lbl in task.head_schedule_list
                ]
                + [
                    (ScheduleStageType.Loop, res, stage, cid, lbl)
                    for res, stage, cid, _guard, lbl in task.loop_schedule_list
                ]
                + [
                    (ScheduleStageType.Tail, res, stage, cid, lbl)
                    for res, stage, cid, lbl in task.tail_schedule_list
                ]
            )
            stage_counts: dict[tuple[int, ScheduleStage, ScheduleStageType], int] = {}
            slot_pos_of: dict[
                tuple[int, ScheduleStage, ScheduleStageType, int], int
            ] = {}
            for pos, (stage_type, res, stage, call_idx, _lbl) in enumerate(combined):
                stage_key = (id(res), stage, stage_type)
                stage_counts[stage_key] = max(
                    stage_counts.get(stage_key, 0),
                    call_idx + 1,
                )
                slot_key = (id(res), stage, stage_type, call_idx)
                slot_pos_of[slot_key] = pos

            def _res_name(res_id: int) -> str:
                res = all_by_id.get(res_id)
                return res.name if res is not None else f"id={res_id}"

            # --- Rule 1 + 2: structural validation of every edge ---------
            # Collect the edge set in canonical form for Rule 3.
            # Each edge: (writer_slot_key, var_name, reader_slot_key).
            user_edges: set[
                tuple[
                    tuple[int, ScheduleStage, ScheduleStageType, int],
                    str,
                    str,
                    tuple[int, ScheduleStage, ScheduleStageType, int],
                ]
            ] = set()
            reader_dst_sources: dict[
                tuple[tuple[int, ScheduleStage, ScheduleStageType, int], str],
                str,
            ] = {}

            for writer_key, entries in task.slot_routing.items():
                if len(writer_key) == 3:
                    w_res_id, w_stage, w_call_idx = writer_key
                    w_stage_type = ScheduleStageType.Loop
                else:
                    w_res_id, w_stage, w_stage_type, w_call_idx = writer_key
                writer_slot_key = (w_res_id, w_stage, w_stage_type, w_call_idx)
                if w_stage not in writer_stages:
                    raise ValueError(
                        f"Task '{task.name}': slot_routing writer key on "
                        f"'{_res_name(w_res_id)}' uses stage {w_stage.name}; "
                        f"only ConsumerAuxWork and ConsumerWork slots can be "
                        f"writers (they are the only slots whose consumer_vars "
                        f"are readable by copy_consumer_vars_to)."
                    )
                if w_res_id not in src_by_id:
                    raise ValueError(
                        f"Task '{task.name}': slot_routing writer key references "
                        f"'{_res_name(w_res_id)}' at consumer stage "
                        f"{w_stage.name}, but the resource is not in "
                        f"src_resources."
                    )
                w_total = stage_counts.get((w_res_id, w_stage, w_stage_type), 0)
                if w_call_idx < 0 or w_call_idx >= w_total:
                    raise ValueError(
                        f"Task '{task.name}': slot_routing writer key "
                        f"'{_res_name(w_res_id)}' {w_stage.name}[{w_call_idx}] "
                        f"has no matching schedule entry "
                        f"({w_total} {w_stage.name} entries exist for that "
                        f"resource)."
                    )

                for var_names, destinations in entries:
                    if not var_names:
                        raise ValueError(
                            f"Task '{task.name}': slot_routing entry for "
                            f"'{_res_name(w_res_id)}' {w_stage.name}"
                            f"[{w_call_idx}] has an empty var_names list."
                        )
                    if not destinations:
                        raise ValueError(
                            f"Task '{task.name}': slot_routing entry for "
                            f"'{_res_name(w_res_id)}' {w_stage.name}"
                            f"[{w_call_idx}] forwards {list(var_names)} to "
                            f"no destinations; drop the entry or add a "
                            f"reader."
                        )
                    for dst_entry in destinations:
                        if not isinstance(dst_entry, tuple) or len(dst_entry) not in (
                            3,
                            4,
                        ):
                            raise ValueError(
                                f"Task '{task.name}': slot_routing destination "
                                f"must be a (dst_resource, dst_stage, dst_call_idx) "
                                f"triple or (dst_resource, dst_stage, "
                                f"dst_stage_type, dst_call_idx) tuple, got "
                                f"{dst_entry!r}."
                            )
                        if len(dst_entry) == 3:
                            dst_resource, dst_stage, dst_call_idx = dst_entry
                            dst_stage_type = ScheduleStageType.Loop
                        else:
                            (
                                dst_resource,
                                dst_stage,
                                dst_stage_type,
                                dst_call_idx,
                            ) = dst_entry
                        dst_res_id = id(dst_resource)
                        if dst_stage in producer_stages:
                            if dst_res_id not in dst_by_id:
                                raise ValueError(
                                    f"Task '{task.name}': slot_routing routes "
                                    f"'{_res_name(w_res_id)}' {w_stage.name}"
                                    f"[{w_call_idx}] vars {list(var_names)} to "
                                    f"'{dst_resource.name}' {dst_stage.name}"
                                    f"[{dst_call_idx}], but the destination "
                                    f"is at a producer stage and the resource "
                                    f"is not in dst_resources."
                                )
                        elif dst_stage in consumer_stages:
                            if dst_res_id not in src_by_id:
                                raise ValueError(
                                    f"Task '{task.name}': slot_routing routes "
                                    f"'{_res_name(w_res_id)}' {w_stage.name}"
                                    f"[{w_call_idx}] vars {list(var_names)} to "
                                    f"'{dst_resource.name}' {dst_stage.name}"
                                    f"[{dst_call_idx}], but the destination "
                                    f"is at a consumer stage and the resource "
                                    f"is not in src_resources."
                                )
                        else:
                            raise ValueError(
                                f"Task '{task.name}': slot_routing destination "
                                f"'{dst_resource.name}' uses stage "
                                f"{dst_stage.name}; destinations must be on a "
                                f"*Work* stage (ProducerAuxWork, ProducerWork, "
                                f"ConsumerAuxWork, or ConsumerWork)."
                            )
                        dst_total = stage_counts.get(
                            (dst_res_id, dst_stage, dst_stage_type),
                            0,
                        )
                        if dst_call_idx < 0 or dst_call_idx >= dst_total:
                            raise ValueError(
                                f"Task '{task.name}': slot_routing routes "
                                f"'{_res_name(w_res_id)}' {w_stage.name}"
                                f"[{w_call_idx}] to '{dst_resource.name}' "
                                f"{dst_stage.name}[{dst_call_idx}] but only "
                                f"{dst_total} {dst_stage.name} entries exist "
                                f"for that resource in the schedule."
                            )
                        dst_key = (
                            dst_res_id,
                            dst_stage,
                            dst_stage_type,
                            dst_call_idx,
                        )
                        for route in var_names:
                            if isinstance(route, str):
                                src_var = route
                                dst_var = route
                            elif (
                                isinstance(route, tuple)
                                and len(route) == 2
                                and all(isinstance(v, str) and v for v in route)
                            ):
                                src_var, dst_var = route
                            else:
                                raise ValueError(
                                    f"Task '{task.name}': slot_routing var route "
                                    f"must be a non-empty string or "
                                    f"(src_name, dst_name) pair of non-empty "
                                    f"strings, got {route!r}."
                                )
                            reader_dst = (dst_key, dst_var)
                            previous_src = reader_dst_sources.get(reader_dst)
                            if previous_src is not None and previous_src != src_var:
                                raise ValueError(
                                    f"Task '{task.name}': slot_routing routes "
                                    f"multiple source vars to reader "
                                    f"'{dst_resource.name}' {dst_stage.name}"
                                    f"[{dst_call_idx}] destination var "
                                    f"'{dst_var}': {previous_src!r} and "
                                    f"{src_var!r}."
                                )
                            reader_dst_sources[reader_dst] = src_var
                            user_edges.add((writer_slot_key, src_var, dst_var, dst_key))

            # --- Rule 3: most-recent-writer consistency -----------------
            # Derive per-slot write / read sets from the user's routing.
            # slot_writes[writer_key] = {src_var, ...}
            # reader_routes_by_src[(writer_res_id, src_var)] =
            #     [(reader_pos, reader_key, dst_var), ...]
            slot_writes: dict[
                tuple[int, ScheduleStage, ScheduleStageType, int], set[str]
            ] = {}
            reader_routes_by_src: dict[
                tuple[int, str],
                list[
                    tuple[int, tuple[int, ScheduleStage, ScheduleStageType, int], str]
                ],
            ] = {}
            for writer_key, src_var, dst_var, reader_key in user_edges:
                slot_writes.setdefault(writer_key, set()).add(src_var)
                reader_routes_by_src.setdefault((writer_key[0], src_var), []).append(
                    (slot_pos_of[reader_key], reader_key, dst_var)
                )

            # Group writers and readers per variable by schedule position.
            writers_by_var: dict[
                tuple[int, str],
                list[tuple[int, tuple[int, ScheduleStage, ScheduleStageType, int]]],
            ] = {}
            for wk, vars_ in slot_writes.items():
                pos = slot_pos_of[wk]
                for v in vars_:
                    writers_by_var.setdefault((wk[0], v), []).append((pos, wk))

            # Apply the linear most-recent-writer matcher on the
            # combined schedule.  No loop-carry special-casing: if no
            # writer of ``var`` precedes the reader linearly, the
            # reader has no producer and the routing is rejected.
            expected_edges: set[
                tuple[
                    tuple[int, ScheduleStage, ScheduleStageType, int],
                    str,
                    str,
                    tuple[int, ScheduleStage, ScheduleStageType, int],
                ]
            ] = set()
            for (_writer_res_id, src_var), readers in reader_routes_by_src.items():
                writers_sorted = sorted(
                    writers_by_var.get((_writer_res_id, src_var), []),
                    key=lambda w: w[0],
                )
                for r_pos, r_key, dst_var in readers:
                    matched = None
                    for w_pos, w_key in reversed(writers_sorted):
                        if w_pos < r_pos:
                            matched = w_key
                            break
                    if matched is None:
                        rr_id, r_stage, _r_stage_type, r_cidx = r_key
                        raise ValueError(
                            f"Task '{task.name}': slot_routing lists no "
                            f"writer of variable '{src_var}' that precedes "
                            f"reader '{_res_name(rr_id)}' {r_stage.name}"
                            f"[{r_cidx}] in the combined schedule.  "
                            f"Loop-carry across iteration boundaries is "
                            f"not modelled; seed iteration 0 by adding a "
                            f"head writer of '{src_var}' if a body reader "
                            f"needs to observe a body writer."
                        )
                    expected_edges.add((matched, src_var, dst_var, r_key))

            # --- Compare user edges against the expected edges ---------
            extra = user_edges - expected_edges
            missing = expected_edges - user_edges
            if extra or missing:

                def _fmt_edge(edge: tuple) -> str:
                    w_key, src_var, dst_var, r_key = edge
                    w_id, w_stage, w_stage_type, w_cidx = w_key
                    r_id, r_stage, r_stage_type, r_cidx = r_key
                    route = src_var if src_var == dst_var else f"{src_var}->{dst_var}"
                    return (
                        f"('{_res_name(w_id)}' {w_stage_type.name} "
                        f"{w_stage.name}[{w_cidx}] "
                        f"--{route}--> '{_res_name(r_id)}' "
                        f"{r_stage_type.name} {r_stage.name}[{r_cidx}])"
                    )

                parts = [
                    f"Task '{task.name}': slot_routing violates the "
                    f"most-recent-writer rule."
                ]
                if extra:
                    parts.append(
                        "Edges that the user supplied but a later writer "
                        "of the same variable would overwrite before the "
                        "reader runs (the runtime copy plan would deliver "
                        "a different version than intended):"
                    )
                    for e in sorted(extra, key=lambda x: (x[0], x[1], x[2])):
                        parts.append(f"  - {_fmt_edge(e)}")
                if missing:
                    parts.append(
                        "Edges that the most-recent-writer rule requires "
                        "but the user did not supply (without them the "
                        "reader would observe no copy at runtime, or the "
                        "wrong version):"
                    )
                    for e in sorted(missing, key=lambda x: (x[0], x[1], x[2])):
                        parts.append(f"  - {_fmt_edge(e)}")
                raise ValueError("\n".join(parts))

    def _verify_work_queue_schedule(self) -> None:
        """Verify WorkQueue placement rules across all tasks.

        Checks that either all or no tasks are persistent, and that the
        ``WorkQueue`` resource appears exclusively in the tail section of
        each task's schedule.
        """
        # Verify that either all or none of the tasks are persistent
        is_any_persistent = any(task.is_persistent for task in self.tasks)
        is_all_persistent = all(task.is_persistent for task in self.tasks)
        assert is_any_persistent == is_all_persistent, (
            "All or none of the tasks must be persistent"
        )

        # No need to check further if no persistent scheduler is used
        if not is_any_persistent:
            return

        def has_work_queue(schedule_list: List) -> bool:
            return any(
                isinstance(e[0], WorkQueue)
                and e[1]
                not in {
                    ScheduleStage.ConsumerAuxWork,
                    ScheduleStage.ProducerAuxWork,
                }
                for e in schedule_list
            )

        # Check that work queue is always done in the tail of schedule
        for task in self.tasks:
            head_has_work_queue = has_work_queue(task.head_schedule_list)
            loop_has_work_queue = has_work_queue(task.loop_schedule_list)
            tail_has_work_queue = has_work_queue(task.tail_schedule_list)
            # Only tail of the schedule can contain work queue
            assert head_has_work_queue is False, (
                "WorkQueue in head schedule is not allowed"
            )
            assert loop_has_work_queue is False, (
                "WorkQueue in loop schedule is not allowed"
            )
            assert tail_has_work_queue is True, "WorkQueue in tail schedule is required"

        work_queue_resources = []
        seen_work_queue_ids = set()
        for task in self.tasks:
            for resource in task.src_resources + task.dst_resources:
                if (
                    isinstance(resource, WorkQueue)
                    and id(resource) not in seen_work_queue_ids
                ):
                    seen_work_queue_ids.add(id(resource))
                    work_queue_resources.append(resource)

        assert len(work_queue_resources) == 1, (
            "Exactly one WorkQueue resource must be shared across all tasks; "
            f"found {len(work_queue_resources)}"
        )

        tile_sched_cfg = work_queue_resources[0].tile_scheduler_config
        if tile_sched_cfg is None:
            return
        scheduler_type = tile_sched_cfg.tile_scheduler_type
        is_dynamic_persistent = scheduler_type == TileSchedulerType.ClcDynamicPersistent
        tasks_with_only_work_queue_sources = [
            task
            for task in self.tasks
            if task.dst_resources
            and all(isinstance(res, WorkQueue) for res in task.dst_resources)
        ]
        only_wq_source_task_names = [t.name for t in tasks_with_only_work_queue_sources]
        expected_only_wq_source_tasks = 1 if is_dynamic_persistent else 0
        assert (
            len(tasks_with_only_work_queue_sources) == expected_only_wq_source_tasks
        ), (
            "Tasks with only WorkQueue in dst_resources must match scheduler mode: "
            f"expected {expected_only_wq_source_tasks} "
            f"(dynamic_persistent={is_dynamic_persistent}), "
            f"found {len(tasks_with_only_work_queue_sources)} "
            f"in {only_wq_source_task_names}"
        )

        # Verify WorkQueue tail stage ordering.
        #
        # ConsumerTryWait / ProducerTryAcquire are optional non-blocking
        # probes — schedules may omit them and go straight to the
        # blocking Wait/Acquire.
        expected_work_queue_tail_stages_with_try = [
            ScheduleStage.ConsumerTryWait,
            ScheduleStage.ConsumerWait,
            ScheduleStage.ConsumerWork,
            ScheduleStage.ConsumerRelease,
        ]
        expected_work_queue_tail_stages_without_try = [
            ScheduleStage.ConsumerWait,
            ScheduleStage.ConsumerWork,
            ScheduleStage.ConsumerRelease,
        ]
        expected_dynamic_tail_with_try = [
            ScheduleStage.ProducerTryAcquire,
            ScheduleStage.ProducerAcquire,
            ScheduleStage.ProducerWork,
            ScheduleStage.ProducerCommit,
            ScheduleStage.ConsumerTryWait,
            ScheduleStage.ConsumerWait,
            ScheduleStage.ConsumerWork,
            ScheduleStage.ConsumerRelease,
        ]
        expected_dynamic_tail_without_try = [
            ScheduleStage.ProducerAcquire,
            ScheduleStage.ProducerWork,
            ScheduleStage.ProducerCommit,
            ScheduleStage.ConsumerWait,
            ScheduleStage.ConsumerWork,
            ScheduleStage.ConsumerRelease,
        ]
        valid_static_tails = [
            expected_work_queue_tail_stages_with_try,
            expected_work_queue_tail_stages_without_try,
        ]
        valid_dynamic_tails = [
            expected_dynamic_tail_with_try,
            expected_dynamic_tail_without_try,
        ]
        dynamic_persistent_task = (
            tasks_with_only_work_queue_sources[0] if is_dynamic_persistent else None
        )
        tasks_with_dynamic_work_queue_tail_stages = []
        for task in self.tasks:
            work_queue_tail_entries = [
                (tail_idx, res, stage, call_id)
                for tail_idx, (res, stage, call_id, _lbl) in enumerate(
                    task.tail_schedule_list
                )
                if isinstance(res, WorkQueue)
            ]
            if not work_queue_tail_entries:
                continue
            stages = [stage for _, _, stage, _ in work_queue_tail_entries]
            if stages in valid_dynamic_tails:
                tasks_with_dynamic_work_queue_tail_stages.append(task)
            if dynamic_persistent_task is not None and task is dynamic_persistent_task:
                assert stages in valid_dynamic_tails, (
                    f"Task '{task.name}': dynamic persistent WorkQueue tail schedule "
                    f"must be [ProducerTryAcquire,] ProducerAcquire, ProducerWork, "
                    f"ProducerCommit, [ConsumerTryWait,] ConsumerWait, ConsumerWork, "
                    f"ConsumerRelease; "
                    f"got {[s.name for s in stages]}"
                )
            else:
                assert stages in valid_static_tails, (
                    f"Task '{task.name}': WorkQueue tail schedule must be "
                    f"[ConsumerTryWait,] ConsumerWait, ConsumerWork, "
                    f"ConsumerRelease; got {[s.name for s in stages]}"
                )
        # WorkQueue may be produced by exactly one task in dynamic mode,
        # and by zero tasks otherwise.
        tasks_with_work_queue_as_dst = [
            task
            for task in self.tasks
            if any(isinstance(res, WorkQueue) for res in task.dst_resources)
        ]
        task_names = [t.name for t in tasks_with_work_queue_as_dst]
        expected_work_queue_dst_tasks = 1 if is_dynamic_persistent else 0
        assert len(tasks_with_work_queue_as_dst) == expected_work_queue_dst_tasks, (
            "WorkQueue dst_resource count must match scheduler mode: "
            f"expected {expected_work_queue_dst_tasks} task(s) with WorkQueue in "
            f"dst_resources (dynamic_persistent={is_dynamic_persistent}), "
            f"found {len(tasks_with_work_queue_as_dst)} in: {task_names}"
        )
        # The one task with WorkQueue in dst_resources must be scheduler task.
        if is_dynamic_persistent:
            assert dynamic_persistent_task is not None
            dst_owner_task = tasks_with_work_queue_as_dst[0]
            assert tasks_with_work_queue_as_dst[0] is dynamic_persistent_task, (
                "The task with WorkQueue in dst_resources must be the "
                f"persistent scheduler task; found '{dst_owner_task.name}', "
                f"expected '{dynamic_persistent_task.name}'"
            )

    @staticmethod
    def _collect_events_per_resource(
        items: list,
    ) -> Dict[int, List[Tuple[MemoryResource, ScheduleStage, int]]]:
        per_resource_events: Dict[
            int, List[Tuple[MemoryResource, ScheduleStage, int]]
        ] = {}
        for idx, item in enumerate(items):
            resource, stage = item[0], item[1]
            per_resource_events.setdefault(id(resource), []).append(
                (resource, stage, idx)
            )
        return per_resource_events

    @staticmethod
    def _transitive_downstream(
        rid: int,
        upstream_to_downstream: Dict[int, Set[int]],
    ) -> Set[int]:
        """Return all resource ids transitively reachable downstream from *rid*.

        Follows edges in *upstream_to_downstream* (reverse dep graph) via
        BFS.  Self-loops and cycles are handled by the visited set.
        """
        visited: Set[int] = set()
        queue = list(upstream_to_downstream.get(rid, set()))
        while queue:
            did = queue.pop()
            if did in visited or did == rid:
                continue
            visited.add(did)
            queue.extend(upstream_to_downstream.get(did, set()))
        return visited

    @staticmethod
    def _build_proxy_open_map(
        per_resource_events: Dict[int, List[Tuple[MemoryResource, ScheduleStage, int]]],
        upstream_to_downstream: Dict[int, Set[int]],
        work_stage: ScheduleStage,
        open_stage: ScheduleStage,
    ) -> Dict[int, Set[int]]:
        """Build a proxy open-bracket map for split-producer/consumer detection.

        For each resource ``R`` that has *work_stage* but no *open_stage*
        in the schedule, find all transitively reachable downstream
        resources ``P`` (via the dep graph) and collect indices where
        ``P`` has *open_stage*.  Those indices serve as proxy open
        brackets for ``R`` in ``_validate_work_group_bracketing``.

        Returns a mapping ``{id(R): {proxy_open_index, ...}}``.
        """
        proxy_open_map: Dict[int, Set[int]] = {}
        for rid, events in per_resource_events.items():
            has_work = any(s == work_stage for _, s, _ in events)
            has_open = any(s == open_stage for _, s, _ in events)
            if has_work and not has_open:
                downstream_ids = TaskManager._transitive_downstream(
                    rid, upstream_to_downstream
                )
                proxy_indices: Set[int] = set()
                for did in downstream_ids:
                    if did in per_resource_events:
                        for _, stage, idx in per_resource_events[did]:
                            if stage == open_stage:
                                proxy_indices.add(idx)
                if proxy_indices:
                    proxy_open_map[rid] = proxy_indices
        return proxy_open_map

    @staticmethod
    def _validate_work_group_bracketing(
        items: list,
        schedule_name: str,
        work_stage: ScheduleStage,
        open_stage: ScheduleStage,
        close_stage: ScheduleStage,
        proxy_open_map: Optional[Dict[int, Set[int]]] = None,
    ) -> None:
        """Ensure work groups are bracketed by open/close stages.

        For a given resource and schedule:
        - a ``work_stage`` group must have a prior ``open_stage``, and
        - the group must be closed by a later ``close_stage``.
        Multiple consecutive ``work_stage`` operations are treated as one
        group.

        This validates both consumer (Wait/Work/Release) and producer
        (Acquire/Work/Commit) bracketing.

        Parameters
        ----------
        proxy_open_map : dict or None
            Mapping from resource ``id()`` to a set of schedule indices
            where a proxy resource's ``open_stage`` occurs.  When a
            resource has ``work_stage`` without a direct ``open_stage``,
            a proxy open bracket at an earlier index is accepted instead.
            This supports the split-consumer pattern where one task waits
            on a proxy resource (whose production transitively guarantees
            the original resource's readiness) and another task does the
            actual work and release.
        """
        per_resource_events = TaskManager._collect_events_per_resource(items)

        for events in per_resource_events.values():
            has_work = any(stage == work_stage for _, stage, _ in events)
            if not has_work:
                continue

            has_open = any(stage == open_stage for _, stage, _ in events)
            has_close = any(stage == close_stage for _, stage, _ in events)

            resource = events[0][0]
            rid = id(resource)
            proxy_indices = (proxy_open_map or {}).get(rid, set())

            # Resources without open/close are allowed only without pipeline
            # config or when a proxy provides the open bracket.
            if not has_open and not has_close:
                if resource.pipeline_config is None:
                    continue
                if not proxy_indices:
                    raise ValueError(
                        f"{schedule_name} schedule has no "
                        f"{open_stage.name}/{close_stage.name} for "
                        f"resource '{resource.name}' but the resource has "
                        "pipeline configuration."
                    )

            has_open_bracket = False
            has_work_after_open = False
            prev_stage: Optional[ScheduleStage] = None

            if (
                work_stage == ScheduleStage.ProducerWork
                and open_stage == ScheduleStage.ProducerAcquire
                and close_stage == ScheduleStage.ProducerCommit
                and has_open
                and has_close
                and getattr(resource, "pipeline_group", None) is None
                and resource.pipeline_config is not None
                and resource.pipeline_config.advance_on_acquire
            ):
                # Only take the direct-resource split-cursor path when both
                # direct brackets are present and the resource is not a
                # PipelineGroup member.  Group members may share one
                # group-level close across multiple member opens, so they fall
                # through to the generic/proxy bracketing logic.
                acquired_groups = 0
                committed_groups = 0
                has_work_after_acquire = False
                for _, stage, idx in events:
                    if stage == open_stage:
                        acquired_groups += 1
                    elif stage == work_stage:
                        if acquired_groups <= committed_groups:
                            raise ValueError(
                                f"{schedule_name} schedule has {work_stage.name} "
                                f"group before an available {open_stage.name} for "
                                f"resource '{resource.name}' at index {idx}."
                            )
                        has_work_after_acquire = True
                    elif stage == close_stage:
                        if has_work_after_acquire:
                            committed_groups += 1
                            has_work_after_acquire = False
                if has_work_after_acquire:
                    raise ValueError(
                        f"{schedule_name} schedule is missing {close_stage.name} "
                        f"after {work_stage.name} group for resource "
                        f"'{resource.name}'."
                    )
                continue

            if (
                work_stage == ScheduleStage.ConsumerWork
                and open_stage == ScheduleStage.ConsumerWait
                and close_stage == ScheduleStage.ConsumerRelease
                and has_open
                and has_close
                and getattr(resource, "pipeline_group", None) is None
                and resource.pipeline_config is not None
                and resource.pipeline_config.advance_on_wait
            ):
                # advance_on_wait splits the consumer into two cursors:
                # ConsumerWait opens the newest stage, while ConsumerRelease
                # closes the oldest outstanding stage.  A release between two
                # work groups therefore does not necessarily close the latest
                # wait/work group.  PipelineGroup members stay on the generic
                # path because a single group-level release may close multiple
                # member waits.
                waited_groups = 0
                released_groups = 0
                has_work_after_wait = False
                for _, stage, idx in events:
                    if stage == open_stage:
                        waited_groups += 1
                    elif stage == work_stage:
                        if waited_groups <= released_groups:
                            raise ValueError(
                                f"{schedule_name} schedule has {work_stage.name} "
                                f"group before {open_stage.name} for resource "
                                f"'{resource.name}' at index {idx}."
                            )
                        has_work_after_wait = True
                    elif stage == close_stage and released_groups < waited_groups:
                        released_groups += 1
                if has_work_after_wait and released_groups < waited_groups:
                    raise ValueError(
                        f"{schedule_name} schedule is missing {close_stage.name} "
                        f"after {work_stage.name} group for resource "
                        f"'{resource.name}'."
                    )
                continue

            for _, stage, idx in events:
                if stage == open_stage:
                    has_open_bracket = True
                    has_work_after_open = False
                elif stage == work_stage:
                    is_start_of_work_group = prev_stage != work_stage
                    if is_start_of_work_group and not has_open_bracket:
                        if proxy_indices and any(pi < idx for pi in proxy_indices):
                            has_open_bracket = True
                        if not has_open_bracket:
                            raise ValueError(
                                f"{schedule_name} schedule has {work_stage.name} group "
                                f"before {open_stage.name} for resource "
                                f"'{resource.name}' at index {idx}."
                            )
                    has_work_after_open = True
                elif stage == close_stage:
                    if has_work_after_open:
                        has_open_bracket = False
                        has_work_after_open = False
                prev_stage = stage

            if has_work_after_open:
                raise ValueError(
                    f"{schedule_name} schedule is missing {close_stage.name} after "
                    f"{work_stage.name} group for resource '{resource.name}'."
                )

    @staticmethod
    def _validate_try_before_blocking(
        items: list,
        schedule_name: str,
        try_stage: ScheduleStage,
        blocking_stage: ScheduleStage,
    ) -> None:
        """Ensure that every ``try_stage`` is eventually followed by ``blocking_stage``.

        Rules per resource:

        - Multiple consecutive ``try_stage`` entries are allowed
          (e.g. try -> try -> ... -> try -> blocking is valid).
        - ``blocking_stage`` without a preceding ``try_stage`` is allowed.
        - ``try_stage`` that is never followed by a ``blocking_stage``
          is an error.
        - Resources without ``pipeline_config`` are skipped entirely.

        This validates both ProducerTryAcquire -> ProducerAcquire and
        ConsumerTryWait -> ConsumerWait ordering.
        """
        per_resource_events = TaskManager._collect_events_per_resource(items)

        for events in per_resource_events.values():
            resource = events[0][0]
            # Skip resources without pipeline configuration.
            if resource.pipeline_config is None:
                continue

            has_try = any(stage == try_stage for _, stage, _ in events)
            if not has_try:
                continue

            # Walk events: any number of consecutive try_stage entries are
            # fine as long as they are eventually resolved by a blocking_stage.
            has_pending_try = False
            last_try_idx: Optional[int] = None
            for _, stage, idx in events:
                if stage == try_stage:
                    has_pending_try = True
                    last_try_idx = idx
                elif stage == blocking_stage:
                    has_pending_try = False

            if has_pending_try:
                raise ValueError(
                    f"{schedule_name} schedule has {try_stage.name} at index "
                    f"{last_try_idx} without a subsequent {blocking_stage.name} "
                    f"for resource '{resource.name}'."
                )

    def _verify_pdl_wait_ordering(self) -> None:
        """Verify PDL wait upstream edges in the dependency graph."""
        if self._assume_pdl_wait_completed:
            return

        dependent_work_stages = {
            ScheduleStage.ConsumerAuxWork,
            ScheduleStage.ConsumerWork,
            ScheduleStage.ProducerAuxWork,
            ScheduleStage.ProducerWork,
        }

        pdl_wait_dependencies = []
        seen_pairs = set()
        for downstream, upstreams in self.resource_dependency_graph.items():
            for upstream in upstreams:
                if isinstance(upstream, PdlWaitBarrier):
                    pair = (id(upstream), id(downstream))
                    if pair not in seen_pairs:
                        seen_pairs.add(pair)
                        pdl_wait_dependencies.append((upstream, downstream))

        for pdl_wait, dependent in pdl_wait_dependencies:
            for task in self.tasks:
                has_dependent_dst = any(
                    id(r) == id(dependent) for r in task.dst_resources
                )
                has_dependent_src = any(
                    id(r) == id(dependent) for r in task.src_resources
                )
                # Producer-side work is the common TMA-A case.  Consumer-side
                # work is guarded only for non-pipelined resources such as a
                # GMEM source that performs a direct global memory load in
                # ConsumerWork; a downstream pipelined consumer (e.g. MMA
                # reading SmemA after SmemA's producer committed) is already
                # ordered by TS.
                should_check_task = has_dependent_dst or (
                    has_dependent_src and dependent.pipeline_config is None
                )
                if not should_check_task:
                    continue

                combined = _combined_schedule(task)
                wait_positions = [
                    pos
                    for pos, (resource, stage, _call_id, _label) in enumerate(combined)
                    if id(resource) == id(pdl_wait)
                    and stage == ScheduleStage.ConsumerWork
                ]
                dependent_work_positions = [
                    pos
                    for pos, (resource, stage, _call_id, _label) in enumerate(combined)
                    if id(resource) == id(dependent) and stage in dependent_work_stages
                ]
                if not dependent_work_positions:
                    continue
                if not wait_positions:
                    raise ValueError(
                        f"Task '{task.name}' uses PDL-dependent resource "
                        f"'{dependent.name}' but has no "
                        f"'{pdl_wait.name}.wait_griddep()' entry in the same "
                        "task schedule."
                    )
                if min(wait_positions) > min(dependent_work_positions):
                    raise ValueError(
                        f"Task '{task.name}' uses PDL-dependent resource "
                        f"'{dependent.name}' before waiting on PDL barrier "
                        f"'{pdl_wait.name}'. Place "
                        f"'{pdl_wait.name}.wait_griddep()' before work "
                        f"entries for '{dependent.name}'."
                    )

    def _verify_resource_stage_roles(self) -> None:
        """Verify that src resources use consumer stages and dst use producer.

        A resource that appears **only** in ``task.src_resources`` may only be
        paired with consumer schedule stages (ConsumerWork, ConsumerWait, …).
        A resource that appears **only** in ``task.dst_resources`` may only be
        paired with producer schedule stages (ProducerAcquire, ProducerWork, …).

        A resource that appears in **both** ``src_resources`` and
        ``dst_resources`` of the same task (e.g. ``WorkQueue``) is allowed to
        use both consumer and producer stages.

        Raises
        ------
        ValueError
            If a src-only resource is paired with a producer stage, a dst-only
            resource is paired with a consumer stage, or a scheduled resource
            is not declared in either list.
        """
        _CONSUMER_STAGES = {
            ScheduleStage.ConsumerAuxWork,
            ScheduleStage.ConsumerTryWait,
            ScheduleStage.ConsumerWait,
            ScheduleStage.ConsumerWork,
            ScheduleStage.ConsumerRelease,
        }
        _PRODUCER_STAGES = {
            ScheduleStage.ProducerAuxWork,
            ScheduleStage.ProducerTryAcquire,
            ScheduleStage.ProducerAcquire,
            ScheduleStage.ProducerWork,
            ScheduleStage.ProducerCommit,
        }

        for task in self.tasks:
            src_ids = {id(r) for r in task.src_resources}
            dst_ids = {id(r) for r in task.dst_resources}
            both_ids = src_ids & dst_ids

            combined_list = _combined_schedule(task)
            for resource, stage, call_id, _lbl in combined_list:
                rid = id(resource)

                # ``PipelineGroup`` entries (e.g. Merge
                # ``(group, ConsumerRelease)``) are barrier-identity
                # only — the group does not appear in src/dst
                # resources but *does* correspond to data-carrying
                # members that are.  Verify at least one member is
                # referenced by the task so the group access makes
                # sense for this task's role, then skip the
                # src/dst/stage checks below.
                if isinstance(resource, PipelineGroup):
                    member_ids = {id(m) for m in resource.members}
                    if not (member_ids & (src_ids | dst_ids)):
                        raise ValueError(
                            f"Task '{task.name}': references PipelineGroup "
                            f"'{resource.name}' in its schedule but none "
                            f"of the group's members ({[m.name for m in resource.members]}) "
                            f"are listed in src_resources or dst_resources."
                        )
                    continue

                # Resources in both src and dst (e.g. WorkQueue) may use
                # any consumer or producer stage.
                if rid in both_ids:
                    if stage not in _CONSUMER_STAGES and stage not in _PRODUCER_STAGES:
                        raise ValueError(
                            f"Task '{task.name}': resource '{resource.name}' "
                            f"(src+dst) is used with unrecognised stage "
                            f"{stage.name} (call_id={call_id})."
                        )
                    continue

                if rid in src_ids and stage not in _CONSUMER_STAGES:
                    raise ValueError(
                        f"Task '{task.name}': src resource '{resource.name}' is "
                        f"used with producer stage {stage.name} (call_id={call_id}). "
                        f"Only consumer stages are allowed for src resources."
                    )
                if rid in dst_ids and stage not in _PRODUCER_STAGES:
                    raise ValueError(
                        f"Task '{task.name}': dst resource '{resource.name}' is "
                        f"used with consumer stage {stage.name} (call_id={call_id}). "
                        f"Only producer stages are allowed for dst resources."
                    )
                if rid not in src_ids and rid not in dst_ids:
                    raise ValueError(
                        f"Task '{task.name}': resource '{resource.name}' appears "
                        f"in the schedule but is not listed in src_resources or "
                        f"dst_resources."
                    )

    def _detect_ping_pong_resources(self) -> set:
        """Detect ping-pong resources: non-WorkQueue self-edges in the dep graph.

        A self-edge ``A: [A]`` where A is not a WorkQueue indicates a
        ping-pong pattern: one task produces data into A, another task
        consumes and writes back different data, then the first task
        re-acquires.

        Returns
        -------
        set
            Set of ``id()`` values for resources with ping-pong self-edges.
        """
        ping_pong_ids = set()
        for downstream, upstreams in self.resource_dependency_graph.items():
            if isinstance(downstream, WorkQueue):
                continue
            for upstream in upstreams:
                if id(upstream) == id(downstream):
                    ping_pong_ids.add(id(downstream))
        return ping_pong_ids

    def _verify_ping_pong_resources(self, ping_pong_ids: set) -> None:
        """Validate detected ping-pong resources.

        Checks for each ping-pong resource:

        1. Must have a ``pipeline_config`` (pipelined resource).
        2. At least one task must have the resource in ``dst_resources``
           (producer).
        3. At least one task must have the resource in ``src_resources``
           (consumer).
        4. Warns if no task has the resource in both ``src_resources``
           and ``dst_resources`` (the compute/write-back task).

        Parameters
        ----------
        ping_pong_ids : set
            Set of ``id()`` values identifying the ping-pong resources.

        Raises
        ------
        ValueError
            If a ping-pong resource fails checks 1-3.
        """
        for resource in self.resources:
            if id(resource) not in ping_pong_ids:
                continue

            # 1. Must be pipelined.
            if resource.pipeline_config is None:
                raise ValueError(
                    f"Ping-pong resource '{resource.name}' has a self-edge "
                    f"in resource_dependency_graph but no pipeline_config. "
                    f"Ping-pong resources must be pipelined."
                )

            # 1b. Consumer side must be synchronous (AsyncThread).
            #
            # PipelineType        | Producer (Full)    | Consumer (Empty)   | OK?
            # --------------------+--------------------+--------------------+----
            # AsyncAsync          | AsyncThread (sync) | AsyncThread (sync) | Yes
            # TmaAsync            | TmaLoad (DMA)      | AsyncThread (sync) | Yes
            # TmaUmma             | TmaLoad (DMA)      | TCGen05Mma (MMA)   | No
            # UmmaAsync           | TCGen05Mma (MMA)   | AsyncThread (sync) | Yes
            # AsyncUmma           | AsyncThread (sync) | TCGen05Mma (MMA)   | No
            # ClcFetchAsync       | ClcLoad (DMA)      | AsyncThread (sync) | Yes
            #
            # TmaUmma and AsyncUmma use TCGen05Mma on the
            # consumer side, which breaks the alternating protocol.
            from .enums import PipelineType

            _DISALLOWED_PING_PONG = {
                PipelineType.TmaUmma,
                PipelineType.AsyncUmma,
                PipelineType.UmmaUmma,
            }
            ptype = resource.pipeline_config.pipeline_type
            if ptype in _DISALLOWED_PING_PONG:
                raise ValueError(
                    f"Ping-pong resource '{resource.name}' uses pipeline "
                    f"type '{ptype.value}' whose consumer side is "
                    f"TCGen05Mma (hardware async). Ping-pong requires a "
                    f"synchronous (AsyncThread) consumer side."
                )

            # 2. Must have a producer task.
            has_producer = any(
                any(id(r) == id(resource) for r in t.dst_resources) for t in self.tasks
            )
            if not has_producer:
                raise ValueError(
                    f"Ping-pong resource '{resource.name}' has a self-edge "
                    f"but no task has it in dst_resources (no producer)."
                )

            # 3. Must have a consumer task.
            has_consumer = any(
                any(id(r) == id(resource) for r in t.src_resources) for t in self.tasks
            )
            if not has_consumer:
                raise ValueError(
                    f"Ping-pong resource '{resource.name}' has a self-edge "
                    f"but no task has it in src_resources (no consumer)."
                )

    def _verify_resource_deps(self) -> None:
        """Verify the explicit resource dependency graph.

        Checks:

        1. Every resource mentioned in ``resource_dependency_graph`` (keys and values)
           is known to the TaskManager (appears in at least one task).
        2. For each declared data-flow edge ``upstream --> downstream``, there
           exists at least one task whose ``src_resources`` contain *upstream*
           and whose ``dst_resources`` contain *downstream*.  Edges whose
           downstream resource has ``is_barrier=True`` are ordering-only: they
           do not imply variable flow and may be backed by a task that simply
           mentions both resources in its resource set.

        Raises
        ------
        ValueError
            If a resource is unknown or if no task backs a declared edge.
        """
        known_ids = {id(r) for r in self.resources}

        # 1. All resources in the dependency graph must be known.
        for downstream, upstreams in self.resource_dependency_graph.items():
            if id(downstream) not in known_ids:
                raise ValueError(
                    f"resource_dependency_graph: downstream "
                    f"resource '{downstream.name}' "
                    f"is not used by any task."
                )
            for upstream in upstreams:
                if id(upstream) not in known_ids:
                    raise ValueError(
                        f"resource_dependency_graph: upstream "
                        f"resource '{upstream.name}' "
                        f"(dependency of '{downstream.name}') is not used "
                        f"by any task."
                    )

        # Collect ping-pong resource ids (resources with self-edges,
        # excluding WorkQueues which use self-edges differently).
        ping_pong_ids: set = {
            id(downstream)
            for downstream, upstreams in self.resource_dependency_graph.items()
            if not isinstance(downstream, WorkQueue)
            and any(id(u) == id(downstream) for u in upstreams)
        }

        # 2. Each edge must be backed by a task whose src contains
        #    upstream and dst contains downstream.
        for downstream, upstreams in self.resource_dependency_graph.items():
            for upstream in upstreams:
                # Ping-pong self-edge: accept if ANY task has the resource
                # in src AND ANY task (possibly different) has it in dst.
                if id(upstream) == id(downstream) and not isinstance(
                    downstream, WorkQueue
                ):
                    has_src = any(
                        any(id(r) == id(upstream) for r in t.src_resources)
                        for t in self.tasks
                    )
                    has_dst = any(
                        any(id(r) == id(downstream) for r in t.dst_resources)
                        for t in self.tasks
                    )
                    if not (has_src and has_dst):
                        raise ValueError(
                            f"resource_dependency_graph: ping-pong self-edge "
                            f"on '{downstream.name}' requires at least one "
                            f"task with the resource in src_resources and at "
                            f"least one task with it in dst_resources."
                        )
                    continue

                # Standard rule: a task consumes upstream (src) and
                # produces downstream (dst).
                has_standard_backing = any(
                    any(id(r) == id(upstream) for r in task.src_resources)
                    and any(id(r) == id(downstream) for r in task.dst_resources)
                    for task in self.tasks
                )
                if has_standard_backing:
                    continue

                # Relaxed rule: accept any task that has both resources
                # in its resource set (src ∪ dst), regardless of role.
                # Applies when the strict producer/consumer distinction
                # doesn't hold:
                #   - Barrier resources (is_barrier=True) carry no data,
                #     they only enforce ordering.
                #   - Ping-pong resources have producer and consumer in
                #     different tasks, so a task that produces both the
                #     ping-pong resource and its downstream has both in
                #     dst_resources.
                is_relaxed = (
                    upstream.is_barrier
                    or downstream.is_barrier
                    or id(upstream) in ping_pong_ids
                    or id(downstream) in ping_pong_ids
                )
                if is_relaxed:
                    has_relaxed_backing = any(
                        any(
                            id(r) == id(upstream)
                            for r in task.src_resources + task.dst_resources
                        )
                        and any(
                            id(r) == id(downstream)
                            for r in task.src_resources + task.dst_resources
                        )
                        for task in self.tasks
                    )
                    if has_relaxed_backing:
                        continue

                raise ValueError(
                    f"resource_dependency_graph: edge "
                    f"'{upstream.name}' -> '{downstream.name}' "
                    f"is not backed by any task. "
                    f"Standard rule: no task has '{upstream.name}' in "
                    f"src_resources and '{downstream.name}' in "
                    f"dst_resources."
                )

    def _verify_resource_coverage(self) -> None:
        """Verify that every task resource appears in the dependency graph.

        When ``resource_dependency_graph`` is provided, every resource in any
        task's ``src_resources`` or ``dst_resources`` must appear somewhere in
        the graph (as a key or as a value).  This catches resources that are
        wired into tasks but accidentally omitted from the dependency graph.

        Raises
        ------
        ValueError
            If a task resource is not present in the dependency graph.
        """
        dep_graph_ids: set = set()
        for downstream, upstreams in self.resource_dependency_graph.items():
            dep_graph_ids.add(id(downstream))
            for upstream in upstreams:
                dep_graph_ids.add(id(upstream))

        for task in self.tasks:
            for resource in task.src_resources + task.dst_resources:
                if id(resource) not in dep_graph_ids:
                    raise ValueError(
                        f"Task '{task.name}': resource '{resource.name}' is in "
                        f"src_resources or dst_resources but does not appear "
                        f"anywhere in resource_dependency_graph."
                    )

    def _verify_schedule_uses_all_resources(self) -> None:
        """Verify that every declared src/dst resource appears in the schedule.

        A resource listed in ``src_resources`` or ``dst_resources`` but never
        referenced by any schedule entry is likely a bug (dead resource).

        Raises
        ------
        ValueError
            If a declared resource has no schedule entries.
        """
        for task in self.tasks:
            combined_list = _combined_schedule(task)
            scheduled_ids = {id(resource) for resource, _, _, _lbl in combined_list}
            for resource in task.src_resources + task.dst_resources:
                if id(resource) not in scheduled_ids:
                    raise ValueError(
                        f"Task '{task.name}': resource '{resource.name}' is "
                        f"declared in src_resources or dst_resources but has "
                        f"no entries in the schedule list."
                    )

    @staticmethod
    def _is_dma_prod_resource(resource: MemoryResource) -> bool:
        """Return True if the resource's producer uses async DMA hardware."""
        if resource.pipeline_config is None:
            return False
        from .enums import PipelineType

        return resource.pipeline_config.pipeline_type in {
            PipelineType.TmaAsync,
            PipelineType.TmaUmma,
            PipelineType.UmmaAsync,
            PipelineType.UmmaUmma,
            PipelineType.ClcFetchAsync,
        }

    def _verify_dma_ordering(self) -> None:
        """Verify DMA ordering for edges whose downstream is a DMA producer.

        When B (downstream) is a DMA-producer resource, ``B.ProducerWork``
        launches async hardware (e.g. tcgen05_mma) that reads directly from
        A's (upstream) physical buffer.  Therefore, for every dependency edge
        A → B where **B is a DMA-producer**, every task that consumes A and
        produces B must satisfy::

            A.ConsumerRelease must come after every B.ProducerWork

        This ensures A's buffer stays alive while B's async hardware reads it.

        When B is *not* a DMA-producer (e.g. a plain global-memory store),
        the data is already in registers after ``A.ConsumerWork``, so
        ``A.ConsumerRelease`` may come before ``B.ProducerWork``.

        Other ordering constraints (ConsumerWait before ConsumerWork,
        Work bracketed by Wait/Release, etc.) are enforced by
        ``_verify_work_group_bracketing``.

        ``dma_consumer_release_labels`` can narrow validation for a specific
        edge. With no entry for an edge, every upstream ``ConsumerRelease`` is
        considered. With an explicit label set, only matching releases are used;
        captured schedules may place the label on the immediately preceding
        ``ConsumerWork`` when the release itself is unlabeled. If a task has
        upstream releases but none match the configured labels, validation fails
        instead of silently disabling DMA-order checking for that edge.

        Raises
        ------
        ValueError
            If a task's schedule violates DMA ordering for any edge.
        """
        for downstream, upstreams in self.resource_dependency_graph.items():
            if not self._is_dma_prod_resource(downstream):
                continue

            # WorkQueue uses cross-iteration pipelining (consumer ops in
            # Tail fetch the *next* tile while Loop runs the *current*).
            # It has dedicated validation in _verify_work_queue_schedule.
            if isinstance(downstream, WorkQueue):
                continue

            for upstream in upstreams:
                if isinstance(upstream, WorkQueue):
                    continue

                # Ping-pong self-edges: synchronization enforced by
                # acquire/release credits, not by DMA ordering.
                if id(upstream) == id(downstream):
                    continue

                for task in self.tasks:
                    src_ids = {id(r) for r in task.src_resources}
                    dst_ids = {id(r) for r in task.dst_resources}

                    if id(upstream) not in src_ids or id(downstream) not in dst_ids:
                        continue

                    combined_list = _combined_schedule(task)

                    b_prod_work_indices = []
                    a_release_indices = []
                    upstream_release_indices = []
                    upstream_consumer_work_label = None
                    release_labels = self._dma_consumer_release_labels.get(
                        (id(upstream), id(downstream))
                    )

                    for idx, item in enumerate(combined_list):
                        resource, stage, _call_id, label = item
                        rid = id(resource)
                        if rid == id(upstream):
                            if stage == ScheduleStage.ConsumerWork:
                                upstream_consumer_work_label = label
                            if stage == ScheduleStage.ConsumerRelease:
                                upstream_release_indices.append(idx)
                                release_label = (
                                    label
                                    if label is not None
                                    else upstream_consumer_work_label
                                )
                                if (
                                    release_labels is None
                                    or release_label in release_labels
                                ):
                                    a_release_indices.append(idx)
                        elif rid == id(downstream):
                            if stage == ScheduleStage.ProducerWork:
                                b_prod_work_indices.append(idx)

                    if (
                        release_labels is not None
                        and upstream_release_indices
                        and not a_release_indices
                    ):
                        raise ValueError(
                            f"Task '{task.name}': DMA edge "
                            f"'{upstream.name}' -> '{downstream.name}' "
                            f"configured dma_consumer_release_labels="
                            f"{sorted(release_labels)!r}, but none of the "
                            "upstream ConsumerRelease entries matched."
                        )

                    if not b_prod_work_indices:
                        import warnings

                        warnings.warn(
                            f"Task '{task.name}': edge "
                            f"'{upstream.name}' -> "
                            f"'{downstream.name}' — "
                            f"'{downstream.name}' is a "
                            f"DMA-producer but has no "
                            f"ProducerWork in the schedule.",
                            stacklevel=2,
                        )
                        continue

                    edge_label = f"'{upstream.name}' -> '{downstream.name}'"
                    task_label = f"Task '{task.name}'"

                    # Every A.ConsumerRelease must come after at least
                    # one B.ProducerWork.  This prevents releasing A's
                    # buffer while B's async hardware is still reading.
                    for rel_idx in a_release_indices:
                        has_prod_before = any(p < rel_idx for p in b_prod_work_indices)
                        if not has_prod_before:
                            raise ValueError(
                                f"{task_label}: DMA edge "
                                f"{edge_label} — "
                                f"'{upstream.name}'."
                                f"ConsumerRelease at index "
                                f"{rel_idx} has no preceding "
                                f"'{downstream.name}'."
                                f"ProducerWork."
                            )

    def _verify_work_group_bracketing(self) -> None:
        """Verify consumer and producer work-group bracketing for all tasks.

        For members of a ``PipelineGroup``, barrier ops (Acquire/Commit,
        Wait/Release) on the group are treated as bracketing the member's
        Work ops.  The combined schedule is augmented so that the
        per-resource bracketing check sees the group's barrier events
        mapped to each member that the task uses.

        Also verifies that TryAcquire always precedes Acquire and
        TryWait always precedes Wait (when the try variants are used).

        Split-consumer / split-producer proxy detection
        ------------------------------------------------
        When a resource ``R`` has a work stage but no corresponding open
        stage (``ConsumerWait`` or ``ProducerAcquire``) in a task's
        schedule, the check consults the dependency graph.  If a
        transitively downstream resource ``P`` has the open stage in the
        same task, that open bracket is accepted as a proxy for ``R``.

        This is sound because ``P``'s production required consuming (or
        acquiring) ``R`` first — verified by ``_verify_resource_deps`` —
        so an open-stage on ``P`` transitively guarantees ``R``'s
        readiness / availability.
        """
        # Reverse dep graph: upstream id -> set of downstream ids.
        upstream_to_downstream: Dict[int, Set[int]] = {}
        for downstream, upstreams in self.resource_dependency_graph.items():
            for upstream in upstreams:
                upstream_to_downstream.setdefault(id(upstream), set()).add(
                    id(downstream)
                )

        for task in self.tasks:
            combined_list = _combined_schedule(task)

            # Augment: when a barrier op (ConsumerRelease, ProducerAcquire,
            # etc.) appears for a group member, replicate it for all OTHER
            # members of the same group that the task references.  This
            # ensures that, e.g., ConsumerWork(smem_b) is seen as
            # bracketed by ConsumerRelease(smem_a) when both belong to
            # the same PipelineGroup.
            _BARRIER_STAGES = {
                ScheduleStage.ProducerAcquire,
                ScheduleStage.ProducerTryAcquire,
                ScheduleStage.ProducerCommit,
                ScheduleStage.ConsumerWait,
                ScheduleStage.ConsumerTryWait,
                ScheduleStage.ConsumerRelease,
            }
            augmented_list = []
            task_resource_ids = {id(r) for r in task.src_resources + task.dst_resources}
            for res, stage, cid, lbl in combined_list:
                if isinstance(res, PipelineGroup):
                    # Group-level barrier op (e.g. Merge ConsumerRelease)
                    # — replicate to every member the task references so
                    # per-member Work ops see a matching open/close.  The
                    # group itself is not in src/dst resources.
                    if stage in _BARRIER_STAGES:
                        for m in res.members:
                            if id(m) in task_resource_ids:
                                augmented_list.append((m, stage, cid, lbl))
                    else:
                        augmented_list.append((res, stage, cid, lbl))
                    continue
                augmented_list.append((res, stage, cid, lbl))
                pg = getattr(res, "pipeline_group", None)
                if pg is not None and stage in _BARRIER_STAGES:
                    for m in pg.members:
                        if id(m) != id(res) and id(m) in task_resource_ids:
                            augmented_list.append((m, stage, cid, lbl))

            schedule_name = f"Task '{task.name}' Combined (Head/Loop/Tail)"

            per_resource_events = TaskManager._collect_events_per_resource(
                combined_list
            )

            consumer_proxy_map = TaskManager._build_proxy_open_map(
                per_resource_events,
                upstream_to_downstream,
                ScheduleStage.ConsumerWork,
                ScheduleStage.ConsumerWait,
            )
            self._validate_work_group_bracketing(
                augmented_list,
                schedule_name,
                work_stage=ScheduleStage.ConsumerWork,
                open_stage=ScheduleStage.ConsumerWait,
                close_stage=ScheduleStage.ConsumerRelease,
                proxy_open_map=consumer_proxy_map,
            )

            producer_proxy_map = TaskManager._build_proxy_open_map(
                per_resource_events,
                upstream_to_downstream,
                ScheduleStage.ProducerWork,
                ScheduleStage.ProducerAcquire,
            )
            self._validate_work_group_bracketing(
                augmented_list,
                schedule_name,
                work_stage=ScheduleStage.ProducerWork,
                open_stage=ScheduleStage.ProducerAcquire,
                close_stage=ScheduleStage.ProducerCommit,
                proxy_open_map=producer_proxy_map,
            )

            self._validate_try_before_blocking(
                combined_list,
                schedule_name,
                try_stage=ScheduleStage.ConsumerTryWait,
                blocking_stage=ScheduleStage.ConsumerWait,
            )
            self._validate_try_before_blocking(
                combined_list,
                schedule_name,
                try_stage=ScheduleStage.ProducerTryAcquire,
                blocking_stage=ScheduleStage.ProducerAcquire,
            )

    # ─────────────────────────────────────────────────────────────────────
    # Pipeline arrival-count verification
    # ─────────────────────────────────────────────────────────────────────
    #
    # Background
    # ----------
    # Each pipeline wraps a pair of mbarrier arrays:
    #
    #   * **full barrier** (producer → consumer): producers *arrive* when
    #     data is ready; consumers *wait* until the expected count is met.
    #   * **empty barrier** (consumer → producer): consumers *arrive*
    #     (release) when they are done; producers *wait* (acquire) for a
    #     free slot.
    #
    # The expected arrive count on each barrier is set from
    # ``CooperativeGroup.size`` at barrier-init time
    # (``MbarrierArray.__init__``:  ``self.arrive_count = self.cg.size``).
    #
    # **Important**: even byte-counted sides (TmaLoad, ClcLoad) still
    # use ``group.size`` to initialise the mbarrier's arrive count.
    # ``mbarrier.arrive_and_expect_tx`` atomically *decrements* the
    # arrive count **and** adds ``tx_count`` bytes.  The mbarrier
    # flips phase only when **both** the arrive count and the byte
    # count reach zero.  Therefore ``group.size`` must match the
    # number of ``arrive_and_expect_tx`` calls, not the byte count.
    #
    # Four classes of arrival mechanism exist:
    #
    #   * **Thread-based** (``AsyncThread`` / ``AsyncLoad``): every
    #     participating thread calls a barrier arrive.  The expected count
    #     must equal the number of threads that will arrive.
    #
    #   * **TCGen05Mma** (UMMA hardware commit): a single warp issues
    #     ``tcgen05.commit`` (gated by ``elect_one``) which instructs the
    #     UMMA engine to arrive on the mbarrier when outstanding MMA
    #     operations complete.  The hardware produces **exactly 1 arrival**
    #     per ``tcgen05.commit``, so ``group.size`` must be **1**.
    #
    #   * **TmaLoad** (TMA byte-counted): ``arrive_and_expect_tx`` is
    #     wrapped in ``elect_one`` inside ``MbarrierArray``, normally producing
    #     **exactly 1 arrival per warp**.  Therefore
    #     ``producer_group.size`` must equal the number of warps that
    #     call ``producer_acquire`` on this resource's pipeline unless
    #     ``TaskWarpLeader`` is enabled.
    #     For multicast (cluster) pipelines, the leader CTA calls
    #     ``arrive_and_expect_tx`` locally via ``is_leader_cta``, while
    #     the TMA hardware issues its own ``arrive_and_expect_tx`` on
    #     each remote CTA's mbarrier, so every CTA in the cluster needs
    #     ``producer_group.size = Σ producer_task.num_warps``.
    #
    #   * **ClcLoad** (CLC byte-counted): CTA 0's scheduler warp runs
    #     ``arrive_and_expect_tx_with_dst`` (NO ``elect_one``).  Each
    #     signalling thread (``tidx % 32 < cluster_total_size``) targets
    #     a **different** CTA's mbarrier.  Each CTA therefore receives
    #     **exactly 1** arrival.  ``producer_group.size`` must be **1**.
    #
    # Per-pipeline-type breakdown
    # ---------------------------
    #
    # +─────────────────────+────────────────────────────+────────────────────────────+
    # | PipelineType        | Full barrier (producer     | Empty barrier (consumer    |
    # |                     | side: commit/arrive)       | side: release/arrive)      |
    # +─────────────────────+────────────────────────────+────────────────────────────+
    # | AsyncAsync          | AsyncThread/ | AsyncThread  ✓ threads    |
    # |                     | AsyncLoad    ✓ threads    |                            |
    # +─────────────────────+────────────────────────────+────────────────────────────+
    # | TmaAsync            | TmaLoad      ✓ warps (*)  | AsyncThread  ✓ warps (**) |
    # +─────────────────────+────────────────────────────+────────────────────────────+
    # | TmaUmma             | TmaLoad      ✓ warps (*)  | TCGen05Mma   ✓ must be 1  |
    # +─────────────────────+────────────────────────────+────────────────────────────+
    # | UmmaAsync           | TCGen05Mma   ✓ must be 1  | AsyncThread  ✓ threads    |
    # +─────────────────────+────────────────────────────+────────────────────────────+
    # | UmmaUmma            | TCGen05Mma   ✓ must be 1  | TCGen05Mma   ✓ must be 1  |
    # +─────────────────────+────────────────────────────+────────────────────────────+
    # | AsyncUmma           | AsyncThread/ | TCGen05Mma   ✓ must be 1  |
    # |                     | AsyncLoad    ✓ threads    |                            |
    # +─────────────────────+────────────────────────────+────────────────────────────+
    # | ClcFetchAsync       | ClcLoad      ✓ must be 1  | AsyncThread  ✓ threads    |
    # +─────────────────────+────────────────────────────+────────────────────────────+
    #
    # (*) TmaLoad producer — elect_one and TaskWarpLeader rules
    # --------------------------------------------------------
    # ``MbarrierArray.arrive_and_expect_tx`` is wrapped in
    # ``elect_one``, so each warp that calls ``producer_acquire``
    # contributes exactly **1** arrival to the mbarrier by default.
    # Therefore:
    #
    #     producer_group.size = Σ producer_task.num_warps
    #
    # For a multi-warp TMA producer task, TS requires either:
    #
    #     * ``interleave_stride > 1``: each warp advances a distinct
    #       barrier stage, so ``producer_group.size = 1``.
    #     * ``TaskWarpLeader``: the TS pipeline overload waits all
    #       producer warps on the empty barrier but only the first warp
    #       assigned to each task performs ``arrive_and_expect_tx`` with
    #       aggregate bytes, so ``producer_group.size = len(tasks)``.
    #
    # No cluster scaling is needed because the pipeline implementation
    # gates the arrive on ``is_leader_cta`` (TmaUmma) or performs a
    # purely local arrive (TmaAsync).  Non-leader CTAs receive their
    # arrivals from the TMA multicast hardware.
    #
    # (**) TmaAsync consumer side
    # ---------------------------
    # Although the empty barrier uses ``PipelineOp.AsyncThread``, the
    # ``PipelineTmaAsync`` implementation applies an internal filter
    # (``is_signalling_thread = tidx % 32 < cluster_total_size``) and
    # further refines it via ``mcast_mode_mn``.  This means only a
    # subset of threads in each warp actually call ``mbarrier_arrive``.
    #
    # For **single-CTA** clusters (``cluster_total == 1``):
    # ``is_signaling_thread = tidx < 1`` → 1 thread per warp, so
    # ``consumer_group.size = Σ consumer_task.num_warps``.
    #
    # For **multi-CTA** clusters the count is further refined by
    # ``mcast_mode_mn`` and the exact CUTLASS TMA async release predicate,
    # so validation is skipped unless the config opts into all-thread release.
    #
    # AsyncThread cluster-scaling rules
    # ----------------------------------
    # The scaling factor when ``SignalingThreads.All`` depends on the
    # pipeline type because each implementation routes arrives differently:
    #
    # * **AsyncAsync**: ``mask = None`` → local arrives only → no cluster
    #   scaling.  Each CTA's mbarrier receives only that CTA's threads.
    #   Formula: ``Σ task.num_warps × 32``.
    #
    # * **UmmaAsync** (consumer side) / **AsyncUmma**
    #   (producer side): all ``V`` CTAs in the 2-CTA MMA group route
    #   their ``arrive`` to the *leading CTA* of the V-group
    #   (``cta_rank // V * V``).  The leading CTA's mbarrier therefore
    #   sees ``V`` times the per-CTA threads.
    #   Formula: ``Σ task.num_warps × 32 × cluster_v``.
    #
    # * **AsyncUmma** with ``AsyncLoad`` producer side: each CTA
    #   uses ``cp.async.mbarrier.arrive`` on its local full barrier, so no
    #   cluster scaling is applied.
    #   Formula: ``Σ task.num_warps × 32``.
    #
    # * **ClcFetchAsync** (consumer side): all CTAs in the cluster send
    #   ``arrive`` to CTA 0 (``consumer_mask = 0``).  CTA 0's empty
    #   barrier sees the full cluster-wide thread count.
    #   Formula: ``Σ task.num_warps × 32 × cluster_total_size``.
    #
    # When ``SignalingThreads.CtaLeader`` is used, the TS gates on
    # ``block_idx_in_cluster() == 0``, so only CTA 0's threads arrive
    # and no cluster scaling is applied regardless of pipeline type.
    #
    # Limitations
    # -----------
    # 1. ``cta_layout_vmnk`` must be a Python tuple (e.g. ``(2,1,1,1)``)
    #    at TaskManager construction time so that ``cluster_v`` and
    #    ``cluster_total`` can be extracted.  If it is an opaque
    #    ``cute.Layout``, a warning is emitted and the check is skipped.
    #
    # 2. Resources with ``pipeline_config = None`` are skipped (no
    #    mbarrier to validate).
    #
    # ─────────────────────────────────────────────────────────────────────

    @staticmethod
    def _get_cluster_v_size(cta_layout_vmnk: object) -> Optional[int]:
        """Extract the V dimension (CTA-group size) from ``cta_layout_vmnk``.

        Returns ``None`` when the value cannot be determined statically.
        """
        if cta_layout_vmnk is None:
            return 1
        if isinstance(cta_layout_vmnk, (tuple, list)):
            return int(cta_layout_vmnk[0]) if len(cta_layout_vmnk) > 0 else 1
        return None

    @staticmethod
    def _get_cluster_total_size(cta_layout_vmnk: object) -> Optional[int]:
        """Return the total number of CTAs in the cluster.

        Returns ``None`` when the value cannot be determined statically.
        """
        if cta_layout_vmnk is None:
            return 1
        if isinstance(cta_layout_vmnk, (tuple, list)):
            result = 1
            for d in cta_layout_vmnk:
                result *= int(d)
            return result
        return None

    def _find_split_consumer_resources(self) -> Set[MemoryResource]:
        """Find resources with a split-consumer pattern across tasks.

        A resource has a split-consumer pattern when one task performs
        ``ConsumerWait`` on it but *not* ``ConsumerRelease``, meaning
        wait and release live in different tasks (different warps).

        Returns the set of such resources.
        """
        result: Set[MemoryResource] = set()
        for task in self.tasks:
            all_entries = (
                [(r, s) for r, s, _, _ in task.head_schedule_list]
                + [(r, s) for r, s, _, _, _ in task.loop_schedule_list]
                + [(r, s) for r, s, _, _ in task.tail_schedule_list]
            )
            wait_resources = {
                r for r, s in all_entries if s == ScheduleStage.ConsumerWait
            }
            release_resources = {
                r for r, s in all_entries if s == ScheduleStage.ConsumerRelease
            }
            result |= wait_resources - release_resources
        return result

    def _auto_enable_advance_on_wait(self) -> None:
        """Auto-enable ``advance_on_wait`` for split-consumer resources.

        When a resource has ``ConsumerWait`` in one task and
        ``ConsumerRelease`` in another (split-consumer pattern),
        ``advance_on_wait`` must be enabled so that:

        - the wait-only task advances ``consumer_state`` on wait, and
        - the release-only task uses a separate ``consumer_release_state``.

        This is the same mechanism as explicit ``advance_on_wait=True``
        and avoids the need for a separate codepath.
        """
        split_resources = self._find_split_consumer_resources()
        for resource in split_resources:
            if (
                resource.pipeline_config is not None
                and not resource.pipeline_config.advance_on_wait
            ):
                resource.pipeline_config = _dataclass_replace(
                    resource.pipeline_config, advance_on_wait=True
                )

    def _verify_consumer_wait_signaling(self) -> None:
        """Verify that consumer_wait_signaling_threads overrides are used.

        When a resource's PipelineConfig has
        ``consumer_wait_signaling_threads`` set, there must be at least
        one task that performs ``ConsumerWait`` **without**
        ``ConsumerRelease`` on that resource (split-consumer pattern).
        Otherwise the override is redundant and likely a mistake.
        """
        overridden = {
            r
            for r in self.resources
            if r.pipeline_config is not None
            and r.pipeline_config.consumer_wait_signaling_threads is not None
        }
        if not overridden:
            return

        split_consumer_resources = self._find_split_consumer_resources()
        uncovered = {r for r in overridden if r not in split_consumer_resources}
        if uncovered:
            names = ", ".join(f"'{r.name}'" for r in uncovered)
            raise ValueError(
                f"consumer_wait_signaling_threads is set on {names} "
                f"but no task has a split-consumer pattern "
                f"(ConsumerWait without ConsumerRelease) for these "
                f"resources. Remove the override or fix the schedule."
            )

    def _collect_pipeline_arrival_tasks(
        self,
    ) -> tuple[Dict[int, List[Task]], Dict[int, List[Task]]]:
        """Return resource-to-task maps for producer/consumer mbarrier arrivals."""
        resource_producer_tasks: Dict[int, List[Task]] = {}
        resource_consumer_tasks: Dict[int, List[Task]] = {}
        for task in self.tasks:
            for res in task.dst_resources:
                if _task_has_stage_for_resource(
                    task, res, ScheduleStage.ProducerCommit
                ):
                    resource_producer_tasks.setdefault(id(res), []).append(task)
            for res in task.src_resources:
                if _task_has_stage_for_resource(
                    task, res, ScheduleStage.ConsumerRelease
                ):
                    resource_consumer_tasks.setdefault(id(res), []).append(task)
        return resource_producer_tasks, resource_consumer_tasks

    @staticmethod
    def _num_signaling_warps(signaling: SignalingThreads, tasks: List[Task]) -> int:
        """Return the per-CTA warp count selected by ``signaling``."""
        if signaling.has_task_warp_leader():
            return len(tasks)
        return sum(t.num_warps for t in tasks)

    @staticmethod
    def _async_thread_expected_count(
        signaling: SignalingThreads,
        tasks: List[Task],
        cluster_scale: int,
        interleave_stride: int = 1,
    ) -> tuple[int, str]:
        """Expected AsyncThread arrivals and a concise formula string.

        When ``interleave_stride > 1`` each barrier stage is touched by a
        single elected warp thread, so the effective warp count collapses
        to one regardless of how many warps the tasks declare.
        """
        selected_warps = (
            1
            if interleave_stride > 1
            else TaskManager._num_signaling_warps(signaling, tasks)
        )
        scale = 1 if signaling.has_cta_leader() else cluster_scale
        expected = selected_warps * 32 * scale
        if interleave_stride > 1:
            formula = "interleaved effective warp × 32"
        elif signaling.has_task_warp_leader():
            formula = "selected task warps × 32"
        else:
            formula = "Σ task.num_warps × 32"
        if scale > 1:
            formula += f" × cluster_scale({scale})"
        return expected, formula

    @staticmethod
    def _tma_async_default_signals_per_warp(
        cfg: PipelineConfig,
        *,
        strict: bool = True,
    ) -> Optional[int]:
        """Return CUTLASS TmaAsync empty-arrive lanes selected per warp."""
        cta_layout = cfg.cta_layout_vmnk
        if cta_layout is None:
            return 1
        if not isinstance(cta_layout, (tuple, list)):
            return None
        if len(cta_layout) < 4:
            return 1
        _, m_dim, n_dim, _ = (int(d) for d in cta_layout[:4])
        mcast_m, mcast_n = cfg.mcast_mode_mn
        if mcast_m == 1 and mcast_n == 0:
            return n_dim
        if mcast_m == 0 and mcast_n == 1:
            return m_dim
        if mcast_m == 1 and mcast_n == 1:
            return m_dim + n_dim - 1
        if not strict:
            return None
        raise ValueError(
            f"Resource uses invalid mcast_mode_mn={cfg.mcast_mode_mn}; "
            f"expected one of (1, 0), (0, 1), or (1, 1)."
        )

    def _prepare_resource_runtime_metadata(self) -> None:
        """Derive metadata consumed by pipeline creation.

        This is deliberately separate from validation.  It must run even when
        validation is warning-only so generated pipeline predicates do not depend
        on whether a checker raised, warned, or was bypassed.
        """
        self._auto_enable_advance_on_wait()
        resource_producer_tasks, resource_consumer_tasks = (
            self._collect_pipeline_arrival_tasks()
        )
        for resource in self.resources:
            cfg = resource.pipeline_config
            if cfg is None or isinstance(resource, PipelineGroup):
                continue

            resource._producer_warp_leader_idxs = ()
            resource._tma_async_consumer_release_uses_all_threads = False
            if (
                cfg.pipeline_type in (PipelineType.TmaAsync, PipelineType.TmaUmma)
                and cfg.producer_signaling_threads.has_task_warp_leader()
            ):
                prod_tasks = resource_producer_tasks.get(id(resource), [])
                resource._producer_warp_leader_idxs = tuple(
                    int(t.warp_start) for t in prod_tasks
                )
            if cfg.pipeline_type != PipelineType.TmaAsync:
                continue

            cons_tasks = (
                list(self.tasks)
                if isinstance(resource, WorkQueue)
                else resource_consumer_tasks.get(id(resource), [])
            )
            if not cons_tasks or cfg.consumer_release_interleave_stride > 1:
                continue

            default_signals_per_warp = self._tma_async_default_signals_per_warp(
                cfg,
                strict=False,
            )
            selected_warps = self._num_signaling_warps(
                cfg.consumer_signaling_threads,
                cons_tasks,
            )
            default_expected = (
                None
                if default_signals_per_warp is None
                else selected_warps * default_signals_per_warp
            )
            all_thread_expected, _ = self._async_thread_expected_count(
                cfg.consumer_signaling_threads,
                cons_tasks,
                1,
            )
            if (
                cfg.consumer_group.size == all_thread_expected
                and cfg.consumer_group.size != default_expected
            ):
                resource._tma_async_consumer_release_uses_all_threads = True

    def _verify_leader_routed_producer_completions(self) -> None:
        """Validate TMA transaction bytes for aggregate producer arrivals."""
        for resource in self.resources:
            cfg = resource.pipeline_config
            if cfg is None:
                continue
            if cfg.pipeline_type not in (
                PipelineType.TmaAsync,
                PipelineType.TmaUmma,
            ):
                continue

            producer_tasks = [
                task
                for task in self.tasks
                if any(id(r) == id(resource) for r in task.dst_resources)
                and _task_has_stage_for_resource(
                    task, resource, ScheduleStage.ProducerCommit
                )
            ]
            if not producer_tasks:
                continue

            bytes_per_warp_per_cta = cfg.num_bytes_per_warp_per_cta
            num_producer_warps = sum(task.num_warps for task in producer_tasks)
            has_task_warp_leader = cfg.producer_signaling_threads.has_task_warp_leader()
            task_warp_leader_aggregates = (
                has_task_warp_leader and num_producer_warps > len(producer_tasks)
            )
            cluster_total = self._get_cluster_total_size(cfg.cta_layout_vmnk)
            cluster_v = self._get_cluster_v_size(cfg.cta_layout_vmnk)
            if cluster_total is None:
                if bytes_per_warp_per_cta is not None or task_warp_leader_aggregates:
                    raise ValueError(
                        f"Resource '{resource.name}' requires TMA "
                        f"num_bytes validation, but has opaque "
                        f"cta_layout_vmnk. Use an inspectable cluster layout "
                        f"so num_bytes can be validated."
                    )
                continue

            consumer_wait_tasks = [
                task
                for task in self.tasks
                if any(id(r) == id(resource) for r in task.src_resources)
                and _task_has_stage_for_resource(
                    task, resource, ScheduleStage.ConsumerWait
                )
            ]
            consumer_wait_signaling = (
                cfg.consumer_wait_signaling_threads
                if cfg.consumer_wait_signaling_threads is not None
                else cfg.consumer_signaling_threads
            )
            has_leader_consumer = (
                cfg.consumer_signaling_threads.has_cta_leader()
                or consumer_wait_signaling.has_cta_leader()
                or any(
                    task.run_only_on_cta_id is not None for task in consumer_wait_tasks
                )
            )
            has_multi_cta_producer = (
                any(task.run_only_on_cta_id is None for task in producer_tasks)
                and cluster_total > 1
            )
            has_leader_routed_completion = (
                has_multi_cta_producer and has_leader_consumer
            )
            requires_declared_bytes = (
                has_leader_routed_completion or task_warp_leader_aggregates
            )
            if not requires_declared_bytes and bytes_per_warp_per_cta is None:
                continue

            if bytes_per_warp_per_cta is None:
                reason = (
                    "TaskWarpLeader aggregates multiple producer warps into one "
                    "transaction-barrier arrive"
                    if task_warp_leader_aggregates
                    else "multi-CTA TMA producer completions feed a leader-only consumer"
                )
                raise ValueError(
                    f"Resource '{resource.name}' must declare "
                    f"num_bytes_per_warp_per_cta because {reason}. Declare "
                    f"the per-producer-warp, per-CTA transaction byte count "
                    f"so num_bytes can be validated."
                )

            cluster_multiplier = 1
            if has_leader_routed_completion:
                # TmaUmma full barriers are per V-group leader. Several
                # independent V-groups may live in one cluster, but each full
                # barrier observes only the CTAs in its own tcgen05 group.
                cluster_multiplier = (
                    cluster_v
                    if cfg.pipeline_type == PipelineType.TmaUmma
                    and cluster_v is not None
                    else cluster_total
                )
            expected_num_bytes = bytes_per_warp_per_cta * cluster_multiplier
            expected_num_bytes *= num_producer_warps
            if cfg.num_bytes != expected_num_bytes:
                route = (
                    "leader-routed TMA producer completions"
                    if has_leader_routed_completion
                    else "TaskWarpLeader TMA producer completions"
                )
                raise ValueError(
                    f"Resource '{resource.name}' has {route} but "
                    f"num_bytes={cfg.num_bytes}. Expected "
                    f"num_bytes={expected_num_bytes} "
                    f"(num_bytes_per_warp_per_cta="
                    f"{bytes_per_warp_per_cta} * cluster_size={cluster_multiplier} "
                    f"* num_producer_warps={num_producer_warps})."
                )

    def _verify_pipeline_thread_counts(self) -> None:
        """Verify pipeline cooperative-group sizes against task thread counts.

        Five categories of checks:

        1. **TCGen05Mma** sides — ``group.size`` must be exactly 1
           (one hardware arrival per ``tcgen05.commit``).

        2. **AsyncThread** sides — ``group.size`` must equal the number
           of threads that will actually call ``mbarrier_arrive`` at
           runtime, derived from the producing/consuming task(s), their
           warp counts, ``SignalingThreads`` policy, and the cluster
           scaling factor appropriate for the pipeline type.

        3. **TmaLoad** producer sides — ``group.size`` must
           equal the number of producer warps.  ``arrive_and_expect_tx``
           is wrapped in ``elect_one`` (one arrival per warp, not per
           thread).

        4. **ClcLoad** producer side — ``group.size`` must be exactly 1.
           Each CTA's mbarrier receives one ``arrive_and_expect_tx_with_dst``
           from the CTA-0 scheduler thread that targets it.

        """
        # ── Build resource → tasks mappings ───────────────────────────
        # Only count tasks that perform the barrier-arriving operation
        # for a given resource.  In split-consumer/producer patterns a
        # task may list the resource in src/dst but only perform the
        # wait/acquire half (no mbarrier arrival).
        #   consumer side: ConsumerRelease  → mbarrier_arrive (empty)
        #   producer side: ProducerCommit   → mbarrier_arrive (full)
        resource_producer_tasks, resource_consumer_tasks = (
            self._collect_pipeline_arrival_tasks()
        )

        def _check_hw_unit_arrival(
            resource: MemoryResource,
            side_label: str,
            group_size: int,
            expected: int,
            hw_name: str,
            reason: str,
        ) -> None:
            """Verify group.size equals a fixed expected count for a HW side."""
            assert resource.pipeline_config is not None
            if group_size != expected:
                raise ValueError(
                    f"Resource '{resource.name}' "
                    f"(pipeline={resource.pipeline_config.pipeline_type.value}): "
                    f"{side_label}_group.size={group_size} but {hw_name} "
                    f"{reason}. "
                    f"Expected {side_label}_group.size={expected}."
                )

        def _check_async_thread_side(
            resource: MemoryResource,
            side_label: str,
            group_size: int,
            signaling: SignalingThreads,
            tasks: List[Task],
            cluster_scale: int,
            interleave_stride: int = 1,
        ) -> None:
            """AsyncThread side: group.size == Σ task.num_warps × 32 [× scale]."""
            assert resource.pipeline_config is not None
            if not tasks:
                return

            domain_lane_tasks = [
                task
                for task in tasks
                if task._uses_domain_interleave_lane(interleave_stride)
            ]
            if domain_lane_tasks:
                if len(domain_lane_tasks) != len(tasks):
                    task_info = ", ".join(
                        f"'{t.name}' (domain_start={t.domain_start}, "
                        f"step={t.step}, warps={t.num_warps})"
                        for t in tasks
                    )
                    raise ValueError(
                        f"Resource '{resource.name}' "
                        f"(pipeline={resource.pipeline_config.pipeline_type.value}) "
                        f"mixes domain-lane interleaved and per-warp "
                        f"{side_label} arrivals. Task(s): [{task_info}]."
                    )

                lane_tasks: Dict[int, List[Task]] = {}
                for task in tasks:
                    lane = int(task.domain_start) % interleave_stride
                    lane_tasks.setdefault(lane, []).append(task)

                for lane, grouped_tasks in lane_tasks.items():
                    expected, formula = self._async_thread_expected_count(
                        signaling,
                        grouped_tasks,
                        cluster_scale,
                    )
                    if group_size != expected:
                        task_info = ", ".join(
                            f"'{t.name}' ({t.num_warps} warps)" for t in grouped_tasks
                        )
                        raise ValueError(
                            f"Resource '{resource.name}' "
                            f"(pipeline={resource.pipeline_config.pipeline_type.value}): "
                            f"{side_label}_group.size={group_size} does not match "
                            f"interleaved lane {lane}/{interleave_stride} expected {expected} "
                            f"(= {formula}). "
                            f"Task(s): [{task_info}], "
                            f"signaling={signaling}."
                        )
                return

            expected, formula = self._async_thread_expected_count(
                signaling,
                tasks,
                cluster_scale,
                interleave_stride,
            )

            if group_size != expected:
                task_info = ", ".join(
                    f"'{t.name}' ({t.num_warps} warps)" for t in tasks
                )
                raise ValueError(
                    f"Resource '{resource.name}' "
                    f"(pipeline={resource.pipeline_config.pipeline_type.value}): "
                    f"{side_label}_group.size={group_size} does not match "
                    f"expected {expected} "
                    f"(= {formula}). "
                    f"Task(s): [{task_info}], "
                    f"signaling={signaling}."
                )

        def _check_clc_consumer_side(
            resource: MemoryResource,
            group_size: int,
            signaling: SignalingThreads,
            tasks: List[Task],
            cluster_scale: int,
        ) -> None:
            """CLC consumers may mix all-CTA and leader-only task ownership."""
            assert resource.pipeline_config is not None
            if not tasks:
                return
            expected = 0
            for task in tasks:
                task_scale = (
                    1
                    if (
                        signaling == SignalingThreads.CtaLeader
                        or task.run_only_on_cta_id is not None
                    )
                    else cluster_scale
                )
                expected += task.num_warps * WARP_SIZE * task_scale

            if group_size != expected:
                task_info = ", ".join(
                    f"'{t.name}' ({t.num_warps} warps, "
                    f"{'single' if t.run_only_on_cta_id is not None else 'all'} CTA)"
                    for t in tasks
                )
                raise ValueError(
                    f"Resource '{resource.name}' "
                    f"(pipeline={resource.pipeline_config.pipeline_type.value}): "
                    f"consumer_group.size={group_size} does not match "
                    f"expected {expected} for mixed CLC ownership. "
                    f"Task(s): [{task_info}], signaling={signaling.value}."
                )

        def _check_tma_elect_one_side(
            resource: MemoryResource,
            side_label: str,
            group_size: int,
            signaling: SignalingThreads,
            tasks: List[Task],
            interleave_stride: int = 1,
        ) -> None:
            """TmaLoad side: elect_one -> one arrival per signaling warp."""
            assert resource.pipeline_config is not None
            if not tasks:
                return
            total_warps = sum(t.num_warps for t in tasks)
            has_multi_warp_task = any(t.num_warps > 1 for t in tasks)
            if (
                has_multi_warp_task
                and interleave_stride <= 1
                and not signaling.has_task_warp_leader()
            ):
                raise ValueError(
                    f"Resource '{resource.name}' "
                    f"(pipeline={resource.pipeline_config.pipeline_type.value}) "
                    f"has TMA producer task(s) with more than one warp, but "
                    f"interleave_stride={interleave_stride} "
                    f"and producer_signaling_threads={signaling}. Multi-warp "
                    f"TMA producer tasks must either use interleave_stride > 1 "
                    f"for independent per-warp barrier stages or "
                    f"producer_signaling_threads=TaskWarpLeader for one "
                    f"aggregate transaction-barrier arrive."
                )
            if (
                has_multi_warp_task
                and interleave_stride > 1
                and signaling.has_task_warp_leader()
            ):
                raise ValueError(
                    f"Resource '{resource.name}' "
                    f"(pipeline={resource.pipeline_config.pipeline_type.value}) "
                    f"combines interleave_stride="
                    f"{interleave_stride} with "
                    f"producer_signaling_threads={signaling}. Multi-warp TMA "
                    f"producer tasks must choose either interleaved independent "
                    f"per-warp arrivals or TaskWarpLeader aggregate arrivals."
                )
            # Interleaved: each stage touched by 1 warp -> size stays 1.
            if interleave_stride > 1:
                if group_size != 1:
                    raise ValueError(
                        f"Resource '{resource.name}' "
                        f"(pipeline={resource.pipeline_config.pipeline_type.value}): "
                        f"{side_label}_group.size={group_size} but "
                        f"interleave_stride="
                        f"{interleave_stride} means "
                        f"each barrier stage is signaled by one elected "
                        f"warp thread. Expected {side_label}_group.size=1."
                    )
                return
            if signaling.has_task_warp_leader():
                expected = len(tasks)
                expected_reason = (
                    "one selected producer warp per task, because "
                    "TaskWarpLeader guards arrive_and_expect_tx"
                )
            else:
                expected = total_warps
                expected_reason = (
                    "Σ producer_task.num_warps, because "
                    "arrive_and_expect_tx uses elect_one: 1 arrival per warp"
                )
            if group_size != expected:
                task_info = ", ".join(
                    f"'{t.name}' ({t.num_warps} warps)" for t in tasks
                )
                raise ValueError(
                    f"Resource '{resource.name}' "
                    f"(pipeline={resource.pipeline_config.pipeline_type.value}): "
                    f"{side_label}_group.size={group_size} does not match "
                    f"expected {expected} "
                    f"(= {expected_reason}). "
                    f"Task(s): [{task_info}]."
                )

        # ── Per-resource checks ───────────────────────────────────────

        for resource in self.resources:
            if resource.pipeline_config is None:
                continue
            # PipelineGroup objects themselves are internal barrier
            # managers -- validation is done on their members.
            if isinstance(resource, PipelineGroup):
                continue

            cfg = resource.pipeline_config
            ptype = cfg.pipeline_type
            cluster_v = self._get_cluster_v_size(cfg.cta_layout_vmnk)
            cluster_total = self._get_cluster_total_size(cfg.cta_layout_vmnk)

            if cluster_v is None or cluster_total is None:
                print(
                    f"[pipeline-thread-check] WARNING: resource "
                    f"'{resource.name}' has opaque cta_layout_vmnk; "
                    f"skipping thread-count validation."
                )
                continue

            is_work_queue = isinstance(resource, WorkQueue)
            prod_tasks = resource_producer_tasks.get(id(resource), [])
            # WorkQueue is src to all tasks (verified by _verify_work_queue_schedule).
            cons_tasks = (
                list(self.tasks)
                if is_work_queue
                else resource_consumer_tasks.get(id(resource), [])
            )

            if cfg.producer_signaling_threads.has_task_warp_leader() and ptype not in (
                PipelineType.TmaAsync,
                PipelineType.TmaUmma,
            ):
                raise ValueError(
                    f"Resource '{resource.name}' "
                    f"(pipeline={ptype.value}) uses "
                    f"producer_signaling_threads={cfg.producer_signaling_threads}, "
                    f"but TaskWarpLeader is only supported for TMA producer "
                    f"pipelines."
                )
            if cfg.consumer_signaling_threads.has_task_warp_leader():
                raise ValueError(
                    f"Resource '{resource.name}' "
                    f"(pipeline={ptype.value}) uses "
                    f"consumer_signaling_threads={cfg.consumer_signaling_threads}, "
                    f"but TaskWarpLeader is producer-side only."
                )
            if (
                cfg.consumer_wait_signaling_threads is not None
                and cfg.consumer_wait_signaling_threads.has_task_warp_leader()
            ):
                raise ValueError(
                    f"Resource '{resource.name}' "
                    f"(pipeline={ptype.value}) uses "
                    f"consumer_wait_signaling_threads="
                    f"{cfg.consumer_wait_signaling_threads}, but TaskWarpLeader "
                    f"is producer-side only."
                )

            # ── Producer side (full barrier) ──────────────────────────
            if ptype in (PipelineType.AsyncAsync, PipelineType.AsyncUmma):
                # AsyncThread/AsyncLoad. Cluster scale depends on routing:
                #   AsyncAsync AsyncThread/AsyncLoad → local arrive → ×1
                #   AsyncUmma AsyncThread            → leading CTA → ×V
                #   AsyncUmma AsyncLoad              → local arrive → ×1
                if (
                    ptype == PipelineType.AsyncUmma
                    and cfg.umma_consumer_producer_op == pipeline.PipelineOp.AsyncThread
                ):
                    scale = cluster_v
                else:
                    scale = 1
                _check_async_thread_side(
                    resource,
                    "producer",
                    cfg.producer_group.size,
                    cfg.producer_signaling_threads,
                    prod_tasks,
                    scale,
                    cfg.producer_commit_interleave_stride,
                )
            elif ptype in (PipelineType.UmmaAsync, PipelineType.UmmaUmma):
                # TCGen05Mma: hardware sends exactly 1 arrival.
                _check_hw_unit_arrival(
                    resource,
                    "producer",
                    cfg.producer_group.size,
                    expected=1,
                    hw_name="TCGen05Mma",
                    reason="produces exactly 1 arrival per tcgen05.commit",
                )
            elif ptype in (PipelineType.TmaAsync, PipelineType.TmaUmma):
                # TmaLoad: arrive_and_expect_tx wrapped in elect_one →
                # 1 arrival per warp.  No cluster scaling because the
                # pipeline gates on is_leader_cta (TmaUmma) or is local
                # (TmaAsync); non-leader CTAs get arrivals from TMA
                # multicast hardware.
                _check_tma_elect_one_side(
                    resource,
                    "producer",
                    cfg.producer_group.size,
                    cfg.producer_signaling_threads,
                    prod_tasks,
                    cfg.producer_commit_interleave_stride,
                )
            elif ptype == PipelineType.ClcFetchAsync:
                # ClcLoad: CTA-0 threads use arrive_and_expect_tx_with_dst,
                # one thread per target CTA.  Each per-CTA full barrier
                # receives exactly one arrival.
                _check_hw_unit_arrival(
                    resource,
                    "producer",
                    cfg.producer_group.size,
                    expected=1,
                    hw_name="ClcLoad",
                    reason="targets one scheduler thread at each CTA's mbarrier",
                )
            else:
                raise ValueError(
                    f"Resource '{resource.name}' has unsupported pipeline type "
                    f"{ptype} for producer-side validation."
                )
            # ── Consumer side (empty barrier) ─────────────────────────
            if ptype == PipelineType.TmaUmma:
                if cfg.consumer_release_interleave_stride > 1:
                    if cons_tasks and cfg.consumer_group.size != 1:
                        raise ValueError(
                            f"Resource '{resource.name}' "
                            f"(pipeline={ptype.value}): consumer_group.size="
                            f"{cfg.consumer_group.size} but "
                            f"interleave_stride="
                            f"{cfg.consumer_release_interleave_stride} means "
                            f"each empty barrier stage is released by one elected "
                            f"warp thread. Expected consumer_group.size=1."
                        )
                    continue
                # TCGen05Mma with cluster-wide multicast (consumer_mask
                # covers the whole cluster).  Each committing CTA's
                # tcgen05.commit arrives once at every pair's barrier
                # (CTA_2 deduplication within a pair).  The number of
                # committing CTAs depends on SignalingThreads:
                #   CtaLeader → cluster_total / V  (one leader per pair)
                #   All       → cluster_total
                if cfg.consumer_signaling_threads.has_cta_leader():
                    expected = cluster_total // cluster_v
                else:
                    expected = cluster_total
                _check_hw_unit_arrival(
                    resource,
                    "consumer",
                    cfg.consumer_group.size,
                    expected=expected,
                    hw_name="TCGen05Mma",
                    reason=(
                        f"produces {expected} arrivals per barrier "
                        f"(cluster-wide multicast, "
                        f"signaling={cfg.consumer_signaling_threads})"
                    ),
                )
            elif ptype in (PipelineType.AsyncUmma, PipelineType.UmmaUmma):
                # TCGen05Mma with pair-local multicast: exactly 1 arrival.
                _check_hw_unit_arrival(
                    resource,
                    "consumer",
                    cfg.consumer_group.size,
                    expected=1,
                    hw_name="TCGen05Mma",
                    reason="produces exactly 1 arrival per tcgen05.commit (pair-local multicast)",
                )
            elif ptype == PipelineType.AsyncAsync:
                # AsyncThread, local arrives (mask=None), no cluster scaling.
                _check_async_thread_side(
                    resource,
                    "consumer",
                    cfg.consumer_group.size,
                    cfg.consumer_signaling_threads,
                    cons_tasks,
                    1,
                    cfg.consumer_release_interleave_stride,
                )
            elif ptype == PipelineType.UmmaAsync:
                # AsyncThread: all V CTAs route arrives to leading CTA.
                _check_async_thread_side(
                    resource,
                    "consumer",
                    cfg.consumer_group.size,
                    cfg.consumer_signaling_threads,
                    cons_tasks,
                    cluster_v,
                    cfg.consumer_release_interleave_stride,
                )
            elif ptype == PipelineType.ClcFetchAsync:
                # AsyncThread: all cluster CTAs route arrives to CTA 0
                # (consumer_mask = 0).
                _check_clc_consumer_side(
                    resource,
                    cfg.consumer_group.size,
                    cfg.consumer_signaling_threads,
                    cons_tasks,
                    cluster_total,
                )
            elif ptype == PipelineType.TmaAsync:
                # PipelineTmaAsync.consumer_release normally gates on
                # ``init_empty_barrier_arrive_signal``: a small number of
                # lanes per warp release the empty barrier based on
                # ``cta_layout_vmnk`` and ``mcast_mode_mn``.  Generated
                # kernels that size ``consumer_group`` to all participating
                # threads instead are inferred from the validated group size;
                # no separate PipelineConfig flag is needed.
                if cfg.consumer_release_interleave_stride > 1:
                    if cons_tasks and cfg.consumer_group.size != 1:
                        raise ValueError(
                            f"Resource '{resource.name}' "
                            f"(pipeline={ptype.value}): consumer_group.size="
                            f"{cfg.consumer_group.size} but "
                            f"interleave_stride="
                            f"{cfg.consumer_release_interleave_stride} means "
                            f"each barrier stage is released by one elected "
                            f"warp thread. Expected consumer_group.size=1."
                        )
                elif cons_tasks:
                    default_signals_per_warp = self._tma_async_default_signals_per_warp(
                        cfg
                    )
                    selected_warps = self._num_signaling_warps(
                        cfg.consumer_signaling_threads,
                        cons_tasks,
                    )
                    all_thread_expected, all_thread_formula = (
                        self._async_thread_expected_count(
                            cfg.consumer_signaling_threads,
                            cons_tasks,
                            1,
                        )
                    )
                    default_expected = (
                        None
                        if default_signals_per_warp is None
                        else selected_warps * default_signals_per_warp
                    )
                    group_size = cfg.consumer_group.size
                    task_info = ", ".join(
                        f"'{t.name}' ({t.num_warps} warps)" for t in cons_tasks
                    )
                    if (
                        group_size == all_thread_expected
                        and group_size != default_expected
                    ):
                        continue
                    if default_expected is not None and group_size != default_expected:
                        default_formula = "Σ consumer_task.num_warps"
                        if default_signals_per_warp != 1:
                            default_formula += (
                                f" × CUTLASS TmaAsync lanes-per-warp"
                                f"({default_signals_per_warp})"
                            )
                        raise ValueError(
                            f"Resource '{resource.name}' "
                            f"(pipeline={ptype.value}): consumer_group.size="
                            f"{group_size} does not match expected "
                            f"{default_expected} for CUTLASS TmaAsync "
                            f"consumer release (= {default_formula}) "
                            f"or {all_thread_expected} for all-thread "
                            f"consumer release (= {all_thread_formula}). "
                            f"Task(s): [{task_info}], "
                            f"signaling={cfg.consumer_signaling_threads}."
                        )

    def _exhaustive_aliasing_races(self) -> None:
        """Run the exhaustive BFS interleaving checker.

        Explores all valid schedule interleavings to detect deadlocks,
        aliasing race conditions, and PDL launch-before-wait ordering
        violations. Persistent kernels are simulated over 2 tile iterations.
        """
        from .exhaustive_checker import check_all_interleavings, CheckResult

        is_persistent = any(isinstance(r, WorkQueue) for r in self.resources)
        num_tiles = 2 if is_persistent else 1

        def _raise_if_unsafe(result: CheckResult, context: str = "") -> None:
            context_msg = f" during {context}" if context else ""
            if result.hit_state_limit:
                warnings.warn(
                    f"Exhaustive checker hit max_states after exploring "
                    f"{result.states_explored} states{context_msg} without "
                    f"completing the search; no concrete issue was found. "
                    f"Increase max_states or reduce the validated schedule "
                    f"size/main-loop length for a complete proof.",
                    stacklevel=2,
                )

            if result.deadlock_states:
                msg = (
                    f"Exhaustive checker found {len(result.deadlock_states)} "
                    f"deadlock(s){context_msg} after exploring "
                    f"{result.states_explored} states."
                )
                raise ValueError(msg)

            if result.race_states:
                lines = [
                    f"Exhaustive checker found {len(result.race_states)} "
                    f"aliasing race(s){context_msg} after exploring "
                    f"{result.states_explored} states:"
                ]
                for race in result.race_states:
                    lines.append(
                        f"  {race.writer_task} writes {race.writer_resource} vs "
                        f"{race.victim_task} {race.victim_access} "
                        f"{race.victim_resource} ({race.overlap_desc})"
                    )
                raise ValueError("\n".join(lines))

            if result.pdl_order_states:
                lines = [
                    f"Exhaustive checker found {len(result.pdl_order_states)} "
                    f"PDL launch ordering violation(s){context_msg} after "
                    f"exploring {result.states_explored} states:"
                ]
                for violation in result.pdl_order_states:
                    lines.append(
                        f"  {violation.launch_task} issues "
                        f"{violation.launch_resource}.launch_griddep before any "
                        f"PdlWaitBarrier.wait_griddep has executed "
                        f"(cursors={violation.cursors})"
                    )
                raise ValueError("\n".join(lines))

        normal_result = check_all_interleavings(
            self.tasks,
            num_tiles=num_tiles,
            assume_pdl_wait_completed=self._assume_pdl_wait_completed,
            verbose=self._verbose,
        )
        _raise_if_unsafe(normal_result)

        if any(getattr(task, "skip_if", None) is not None for task in self.tasks):
            skipped_result = check_all_interleavings(
                self.tasks,
                num_tiles=num_tiles,
                skipped_tile=True,
                assume_pdl_wait_completed=self._assume_pdl_wait_completed,
                verbose=self._verbose,
            )
            _raise_if_unsafe(skipped_result, "skipped-tile execution")

    def _verify_pipeline_group_consistency(self) -> None:
        """Validate PipelineGroup members against the merged config.

        Checks:

        1. All member ``pipeline_config``s have the same ``num_stages``
           and, for homogeneous groups, ``pipeline_type``.
        2. For Merge groups: ``sum(member.num_bytes) ==
           group.pipeline_config.num_bytes``.  Fork is skipped — its
           merged ``num_bytes`` reflects the single shared DMA transfer
           (secondaries report ``num_bytes=0``), not a sum.

        Task-to-group wiring is validated separately by
        ``normalize_and_validate_schedule_list`` (in ``task.py``),
        which enforces that a ``PipelineGroup`` never appears in
        ``src_resources`` / ``dst_resources`` — only its members do.
        Group-level stages (Merge ``ConsumerRelease`` / Fork
        ``ProducerCommit``) fire the shared barrier once per stage
        and distribute credits to every member.

        Raises ValueError on any inconsistency.
        """
        for resource in self.resources:
            if not isinstance(resource, PipelineGroup):
                continue
            group = resource
            cfg = group.pipeline_config
            assert cfg is not None
            total_bytes = 0
            for m in group.members:
                if m.pipeline_config is None:
                    raise ValueError(
                        f"PipelineGroup '{group.name}': member "
                        f"'{m.name}' has no pipeline_config."
                    )
                mc = m.pipeline_config
                if mc.num_stages != cfg.num_stages:
                    raise ValueError(
                        f"PipelineGroup '{group.name}': member "
                        f"'{m.name}' num_stages={mc.num_stages} "
                        f"differs from group ({cfg.num_stages})."
                    )
                if not group.is_heterogeneous:
                    if mc.pipeline_type != cfg.pipeline_type:
                        raise ValueError(
                            f"PipelineGroup '{group.name}': member "
                            f"'{m.name}' pipeline_type={mc.pipeline_type} "
                            f"differs from group ({cfg.pipeline_type})."
                        )
                total_bytes += mc.num_bytes
            # Merge: merged bytes = sum (each producer loads different data).
            # Fork: merged bytes = one member's bytes (producer loads once,
            # all consumers read the same data).  Skip sum check for Fork.
            if group.mode != PipelineGroupMode.Fork:
                if total_bytes != cfg.num_bytes:
                    raise ValueError(
                        f"PipelineGroup '{group.name}': "
                        f"sum(member.num_bytes)={total_bytes} != "
                        f"group.num_bytes={cfg.num_bytes}."
                    )

    # Stages that put a task in each interleave role for a resource.
    _PRODUCER_ACQUIRE_ROLE_STAGES: FrozenSet[ScheduleStage] = frozenset(
        {
            ScheduleStage.ProducerAuxWork,
            ScheduleStage.ProducerTryAcquire,
            ScheduleStage.ProducerAcquire,
            ScheduleStage.ProducerWork,
        }
    )
    _PRODUCER_COMMIT_ROLE_STAGES: FrozenSet[ScheduleStage] = frozenset(
        {ScheduleStage.ProducerCommit}
    )
    _CONSUMER_WAIT_ROLE_STAGES: FrozenSet[ScheduleStage] = frozenset(
        {
            ScheduleStage.ConsumerAuxWork,
            ScheduleStage.ConsumerTryWait,
            ScheduleStage.ConsumerWait,
            ScheduleStage.ConsumerWork,
        }
    )
    _CONSUMER_RELEASE_ROLE_STAGES: FrozenSet[ScheduleStage] = frozenset(
        {ScheduleStage.ConsumerRelease}
    )

    def _verify_interleaved_pipelines(self) -> None:
        """Validate structural invariants required by interleaved pipelines.

        Producer and consumer roles are validated independently so one side
        may be interleaved while the other remains dense. Domain-derived lanes
        additionally require one matching stride for both roles on that side.
        """
        from .enums import PipelineType

        def _task_uses_any_stage(
            task: Task, resource: MemoryResource, stages: FrozenSet[ScheduleStage]
        ) -> bool:
            return any(
                _task_has_stage_for_resource(task, resource, stage) for stage in stages
            )

        def _check_role_users(
            resource: MemoryResource,
            cfg: PipelineConfig,
            role: str,
            role_stride: int,
            stages: FrozenSet[ScheduleStage],
        ) -> None:
            if role_stride <= 1:
                return
            for task in self.tasks:
                if not _task_uses_any_stage(task, resource, stages):
                    continue
                if task.num_warps == role_stride:
                    continue
                if task._uses_domain_interleave_lane(role_stride):
                    continue
                raise ValueError(
                    f"Interleaved resource '{resource.name}' uses "
                    f"{role} interleave_stride={role_stride}, but task "
                    f"'{task.name}' has num_warps={task.num_warps}, "
                    f"domain_start={task.domain_start}, and step={task.step}. "
                    f"Each interleaved task must either cover exactly one "
                    f"warp per lane or split its loop with step equal to "
                    f"the interleave stride."
                )

        def _check_domain_lane_pair(
            resource: MemoryResource,
            side: str,
            opening_role: str,
            opening_stride: int,
            opening_stages: FrozenSet[ScheduleStage],
            closing_role: str,
            closing_stride: int,
            closing_stages: FrozenSet[ScheduleStage],
        ) -> None:
            """Require one stride for both states owned by a domain lane."""
            if opening_stride == closing_stride:
                return
            for task in self.tasks:
                uses_opening_lane = _task_uses_any_stage(
                    task, resource, opening_stages
                ) and task._uses_domain_interleave_lane(opening_stride)
                uses_closing_lane = _task_uses_any_stage(
                    task, resource, closing_stages
                ) and task._uses_domain_interleave_lane(closing_stride)
                if uses_opening_lane or uses_closing_lane:
                    raise ValueError(
                        f"Interleaved resource '{resource.name}' uses a "
                        f"domain-split {side} lane in task '{task.name}', but "
                        f"{opening_role} interleave_stride={opening_stride} "
                        f"differs from {closing_role} "
                        f"interleave_stride={closing_stride}. Domain-split "
                        f"lanes require matching opening and closing strides."
                    )

        for resource in self.resources:
            cfg = resource.pipeline_config
            if cfg is None or not cfg.has_interleaved_stride:
                continue

            stride = cfg.max_interleave_stride
            allowed_pipeline_types = {
                PipelineType.AsyncAsync,
                PipelineType.AsyncUmma,
                PipelineType.TmaAsync,
                PipelineType.TmaUmma,
                PipelineType.UmmaAsync,
            }
            if cfg.pipeline_type not in allowed_pipeline_types:
                allowed = ", ".join(
                    t.value
                    for t in sorted(
                        allowed_pipeline_types,
                        key=lambda t: t.value,
                    )
                )
                raise ValueError(
                    f"Resource '{resource.name}' uses interleave_stride={stride} "
                    f"with pipeline={cfg.pipeline_type.value}. Interleaved "
                    f"pipelines are only supported for: {allowed}."
                )

            if cfg.pipeline_type == PipelineType.TmaAsync:
                cluster_total = self._get_cluster_total_size(cfg.cta_layout_vmnk)
                if cluster_total != 1:
                    raise ValueError(
                        f"Resource '{resource.name}' uses interleave_stride={stride} "
                        f"with pipeline={cfg.pipeline_type.value} and "
                        f"cluster_total={cluster_total}. Interleaved TmaAsync "
                        f"uses the stock pipeline release path, which is only "
                        f"valid for single-CTA pipelines."
                    )
            if cfg.pipeline_type == PipelineType.UmmaAsync and (
                cfg.producer_acquire_interleave_stride > 1
                or cfg.producer_commit_interleave_stride > 1
            ):
                raise ValueError(
                    f"Resource '{resource.name}' uses interleaved producer "
                    f"strides with pipeline={cfg.pipeline_type.value}; UMMA "
                    f"producer-side interleave is not supported."
                )
            if cfg.pipeline_type == PipelineType.AsyncUmma and (
                cfg.consumer_wait_interleave_stride > 1
                or cfg.consumer_release_interleave_stride > 1
            ):
                raise ValueError(
                    f"Resource '{resource.name}' uses interleaved consumer "
                    f"strides with pipeline={cfg.pipeline_type.value}; UMMA "
                    f"consumer-side interleave is not supported."
                )

            for role, role_stride in (
                ("producer_acquire", cfg.producer_acquire_interleave_stride),
                ("producer_commit", cfg.producer_commit_interleave_stride),
                ("consumer_wait", cfg.consumer_wait_interleave_stride),
                ("consumer_release", cfg.consumer_release_interleave_stride),
            ):
                if cfg.num_stages % role_stride != 0:
                    raise ValueError(
                        f"Resource '{resource.name}' has num_stages="
                        f"{cfg.num_stages} not divisible by {role} "
                        f"interleave_stride={role_stride}."
                    )

            _check_role_users(
                resource,
                cfg,
                "producer_acquire",
                cfg.producer_acquire_interleave_stride,
                self._PRODUCER_ACQUIRE_ROLE_STAGES,
            )
            _check_role_users(
                resource,
                cfg,
                "producer_commit",
                cfg.producer_commit_interleave_stride,
                self._PRODUCER_COMMIT_ROLE_STAGES,
            )
            _check_role_users(
                resource,
                cfg,
                "consumer_wait",
                cfg.consumer_wait_interleave_stride,
                self._CONSUMER_WAIT_ROLE_STAGES,
            )
            _check_role_users(
                resource,
                cfg,
                "consumer_release",
                cfg.consumer_release_interleave_stride,
                self._CONSUMER_RELEASE_ROLE_STAGES,
            )

            _check_domain_lane_pair(
                resource,
                "producer",
                "producer_acquire",
                cfg.producer_acquire_interleave_stride,
                self._PRODUCER_ACQUIRE_ROLE_STAGES,
                "producer_commit",
                cfg.producer_commit_interleave_stride,
                self._PRODUCER_COMMIT_ROLE_STAGES,
            )
            _check_domain_lane_pair(
                resource,
                "consumer",
                "consumer_wait",
                cfg.consumer_wait_interleave_stride,
                self._CONSUMER_WAIT_ROLE_STAGES,
                "consumer_release",
                cfg.consumer_release_interleave_stride,
                self._CONSUMER_RELEASE_ROLE_STAGES,
            )

            # Asymmetric producer roles use separate states, so a task may
            # drive only one side of the acquire/commit pair.
            if (
                cfg.producer_acquire_interleave_stride
                != cfg.producer_commit_interleave_stride
            ):
                for task in self.tasks:
                    if _task_uses_any_stage(
                        task, resource, self._PRODUCER_ACQUIRE_ROLE_STAGES
                    ) and _task_uses_any_stage(
                        task, resource, self._PRODUCER_COMMIT_ROLE_STAGES
                    ):
                        raise ValueError(
                            f"Interleaved resource '{resource.name}' uses "
                            f"different producer_acquire "
                            f"({cfg.producer_acquire_interleave_stride}) and "
                            f"producer_commit "
                            f"({cfg.producer_commit_interleave_stride}) "
                            f"interleave strides, but task '{task.name}' "
                            f"schedules both acquire and commit stages for it. "
                            f"Split the acquire and commit roles into separate "
                            f"tasks so each advances its own producer state."
                        )

            # Asymmetric consumer roles likewise require separate tasks for
            # the wait and release states.
            if (
                cfg.consumer_wait_interleave_stride
                != cfg.consumer_release_interleave_stride
            ):
                for task in self.tasks:
                    if _task_uses_any_stage(
                        task, resource, self._CONSUMER_WAIT_ROLE_STAGES
                    ) and _task_uses_any_stage(
                        task, resource, self._CONSUMER_RELEASE_ROLE_STAGES
                    ):
                        raise ValueError(
                            f"Interleaved resource '{resource.name}' uses "
                            f"different consumer_wait "
                            f"({cfg.consumer_wait_interleave_stride}) and "
                            f"consumer_release "
                            f"({cfg.consumer_release_interleave_stride}) "
                            f"interleave strides, but task '{task.name}' "
                            f"schedules both wait and release stages for it. "
                            f"Split the wait and release roles into separate "
                            f"tasks so each advances its own consumer state."
                        )

    def _verify_head_loop_producer_overlap(self) -> None:
        """Warn when a pipelined producer resource appears in both HEAD and LOOP.

        HEAD entries always receive ``loop_offset=0``.  LOOP entries start at
        ``loop_offset=0`` and increment.  If a resource's ``producer_work``
        uses ``loop_offset`` for addressing (e.g. computing a tile coordinate),
        the HEAD call and LOOP iter 0 will receive the **same** loop_offset,
        making it impossible to address different tiles.

        This is a common source of "wrong data loaded" bugs when trying to
        move the first iteration's loads into HEAD (LazyHead for producers).

        The safe patterns are:
        - Producer in HEAD only, different domain for LOOP (e.g. SmemQ)
        - Producer in LOOP only, everything from iter 0 (e.g. SmemKV)

        The unsafe pattern (flagged here):
        - Producer in both HEAD and LOOP — loop_offset=0 is ambiguous
        """
        for task in self.tasks:
            dst_ids = {id(r) for r in task.dst_resources}

            # Collect resources that have ProducerWork in HEAD.
            head_producer_resources = set()
            for res, stage, _cid, _lbl in task.head_schedule_list:
                if id(res) in dst_ids and stage == ScheduleStage.ProducerWork:
                    head_producer_resources.add(id(res))

            # Check if any of those also have ProducerWork in LOOP.
            for res, stage, _cid, _guard, _lbl in task.loop_schedule_list:
                if (
                    id(res) in head_producer_resources
                    and stage == ScheduleStage.ProducerWork
                ):
                    # Warning only: some patterns (e.g. deferred SP commit)
                    # intentionally produce in both HEAD and LOOP. The
                    # concern about loop_offset ambiguity only applies when
                    # producer_work uses loop_offset for addressing.
                    print(
                        f"[head-loop-overlap] WARNING: '{res.name}' has "
                        f"ProducerWork in both HEAD and LOOP of "
                        f"'{task.name}'. If the resource uses loop_offset "
                        f"for addressing, HEAD and LOOP iter 0 will "
                        f"compute the same address."
                    )

    def _verify_work_labels(self) -> None:
        """Verify that all work-entry labels resolve to valid methods.

        Iterates every task's head, loop, and tail schedule lists and calls
        ``Task._resolve_work_method`` for each ``ConsumerWork`` /
        ``ProducerWork`` entry.  This surfaces label errors (typos, missing
        labels in captured schedules when named methods exist, etc.) eagerly
        during ``TaskManager`` construction rather than deferring to kernel
        compilation time.
        """
        _WORK_STAGES = self._CONSUMER_WORK_STAGES | self._PRODUCER_WORK_STAGES
        for task in self.tasks:
            for res, stage, _cid, lbl in task.head_schedule_list:
                if stage in _WORK_STAGES:
                    Task._resolve_work_method(
                        res,
                        stage,
                        lbl,
                        require_label_for_named=task.captured_schedule,
                    )
            for res, stage, _cid, _guard, lbl in task.loop_schedule_list:
                if stage in _WORK_STAGES:
                    Task._resolve_work_method(
                        res,
                        stage,
                        lbl,
                        require_label_for_named=task.captured_schedule,
                    )
            for res, stage, _cid, lbl in task.tail_schedule_list:
                if stage in _WORK_STAGES:
                    Task._resolve_work_method(
                        res,
                        stage,
                        lbl,
                        require_label_for_named=task.captured_schedule,
                    )

    # ─────────────────────────────────────────────────────────────────────
    # CTA layout (cluster shape) consistency verification
    # ─────────────────────────────────────────────────────────────────────
    #
    # All pipeline resources that participate in the same kernel should
    # use the same ``cta_layout_vmnk`` (cluster decomposition).  A
    # mismatch would mean that different pipelines assume different
    # numbers of CTAs in the 2-CTA MMA group, which is almost
    # certainly a bug.
    #
    # We only compare resources whose ``cta_layout_vmnk`` is a Python
    # tuple (statically known).  Resources with ``None`` (no cluster)
    # are compatible with anything but we warn if mixed with non-None.
    # Opaque ``cute.Layout`` objects are skipped.
    # ─────────────────────────────────────────────────────────────────────
    def _verify_cta_layout_consistency(self) -> None:
        """Verify that all pipeline resources use the same ``cta_layout_vmnk``.

        Raises
        ------
        ValueError
            If two resources with non-``None`` tuple ``cta_layout_vmnk``
            disagree on the cluster decomposition.
        """
        known_layouts: Dict[tuple, str] = {}  # layout_tuple → first resource name
        has_none: Optional[str] = None

        for resource in self.resources:
            if resource.pipeline_config is None:
                continue

            cta = resource.pipeline_config.cta_layout_vmnk
            if cta is None:
                has_none = resource.name
                continue
            if not isinstance(cta, (tuple, list)):
                # Opaque Layout — skip.
                continue

            cta_tuple = tuple(cta)
            if known_layouts and cta_tuple not in known_layouts:
                existing_name = next(iter(known_layouts.values()))
                existing_layout = next(iter(known_layouts.keys()))
                raise ValueError(
                    f"Inconsistent cta_layout_vmnk across pipeline "
                    f"resources: '{resource.name}' uses {cta_tuple} but "
                    f"'{existing_name}' uses {existing_layout}. "
                    f"All pipeline resources in the same kernel should "
                    f"share the same cluster decomposition."
                )
            known_layouts[cta_tuple] = resource.name

        # Warn (but don't error) if some resources have None and others
        # have an explicit layout — it's often intentional (e.g. GMEM
        # resources without pipelines) but can hint at mistakes.
        if has_none and known_layouts:
            first_resource_with_layout = next(iter(known_layouts.values()))
            first_layout = next(iter(known_layouts.keys()))
            if self._verbose:
                print(
                    f"[cta-layout-check] NOTE: resource '{has_none}' has "
                    f"cta_layout_vmnk=None, while '{first_resource_with_layout}' "
                    f"uses {first_layout}. This is typically fine for GMEM "
                    f"source/sink resources without pipelines."
                )

    def print_and_verify(self) -> None:
        """Print the full schedule table and run all verification checks.

        When ``skip_validation=True`` was passed to the constructor,
        each check still runs but failures are emitted as warnings
        instead of raising.

        **False-positive caveat:** when task ``domain`` or
        ``domain_start`` is a runtime value (not a Python ``int``), the
        deadlock simulation falls back to ``domain=1`` and
        ``domain_start=0``.  This can produce false-positive deadlock
        reports for schedules that require more iterations to balance
        (e.g. ``domain_start > 0``).  For accurate verification, use
        validate-only mode with realistic Python ``int`` domains and
        ``domain_start``.
        """
        self._run_check(self._print_task_schedules)

        checks = [
            # Verify that all tasks in the same warp group of 4 use the same num_registers
            self._verify_warp_group_registers,
            # Verify that the register budget is enough
            self._verify_register_budget,
            # Verify PipelineGroup member configs are consistent with
            # the merged group config and task wiring.
            self._verify_pipeline_group_consistency,
            # Verify that src resources use only consumer stages
            # and dst resources use only producer stages.
            self._verify_resource_stage_roles,
            # Verify explicit resource dependency graph (if provided).
            self._verify_resource_deps,
            # Verify ordering-only PDL wait edges encoded as dep-graph edges
            # whose upstream is PdlWaitBarrier.
            self._verify_pdl_wait_ordering,
            # Verify that every task resource appears in the dependency graph.
            self._verify_resource_coverage,
            # Verify that every declared src/dst resource appears in the schedule.
            self._verify_schedule_uses_all_resources,
            # Verify consumer/producer work-group bracketing for all
            # tasks: ConsumerWork bracketed by ConsumerWait/Release,
            # ProducerWork by ProducerAcquire/Commit, TryAcquire/TryWait
            # before Acquire/Wait.
            self._verify_work_group_bracketing,
            # Verify that WorkQueue is src resource to either all or none tasks
            # Verify the schedule placement correctness of the WorkQueue
            self._verify_work_queue_schedule,
            # DMA ordering: A.ConsumerRelease after B.ProducerWork when B is
            # a DMA-producer.  Runs after bracketing checks so we can assume
            # basic wait/release structure is already valid.
            self._verify_dma_ordering,
            # Verify that consumer_wait_signaling_threads overrides are
            # only set on resources with a split-consumer pattern.
            self._verify_consumer_wait_signaling,
            # Verify that thread-based pipeline cooperative group sizes match
            # the actual number of threads that will arrive on the corresponding
            # mbarrier at runtime (derived from task warp counts, signaling
            # policy, and cluster V dimension).
            self._verify_pipeline_thread_counts,
            # Verify opt-in clustered or task-warp-leader TMA producer
            # completions carry the transaction bytes expected by the
            # full barrier.  Runs after arrival-count validation so invalid
            # multi-warp producer modes do not get masked by byte errors.
            self._verify_leader_routed_producer_completions,
            # Verify interleaved pipelines have one task warp per lane and
            # a stage count divisible by the interleave stride.
            self._verify_interleaved_pipelines,
            # Verify that all pipeline resources agree on cta_layout_vmnk
            # (cluster decomposition).  Different V dimensions would break
            # 2-CTA MMA assumptions.
            self._verify_cta_layout_consistency,
            self._verify_head_loop_producer_overlap,
            # Verify that all work-entry labels resolve to valid
            # @consumer_work / @producer_work methods.
            self._verify_work_labels,
            self._verify_smem_capacity,
            self._verify_tmem_capacity,
            # Validates the user-supplied ``slot_routing`` against stage
            # legality, call-idx ranges, schedule ordering, and the
            # most-recent-writer rule.  The runtime consumes
            # ``task.slot_routing`` verbatim after this pass succeeds.
            self._verify_slot_routing,
        ]
        for check in checks:
            self._run_check(check)

        # Ping-pong detection + validation
        ping_pong_ids = self._detect_ping_pong_resources()
        if ping_pong_ids:
            self._run_check(lambda: self._verify_ping_pong_resources(ping_pong_ids))

        if self._exhaustive_deadlock_race_check:
            self._run_check(self._exhaustive_aliasing_races)

        # Memory usage reports
        if self._verbose:
            if self._smem_allocator is not None:
                self._smem_allocator.print_usage_report()
            if self._tmem_allocator is not None:
                self._tmem_allocator.print_usage_report()

    def _run_check(self, check_fn: Callable[[], Any]) -> None:
        """Run a verification check, converting errors to warnings
        when ``_warn_only`` is set."""
        if not self._warn_only:
            check_fn()
        else:
            try:
                check_fn()
            except (ValueError, RuntimeError) as e:
                warnings.warn(
                    f"TS validation ({check_fn.__name__}): {e}",
                    stacklevel=3,
                )

    def setup_resources_and_tasks(self) -> None:
        """Materialise and initialize pipelines and barriers for every resource.

        When an ``SmemAllocator`` is configured, emits a single
        ``cutlass.Array(..., space=cutlass.AddressSpace.smem)`` for all declared data SMEM and
        stores the base pointer for later use by ``run()``.

        Then calls ``resource.create()`` on each unique resource (allocates
        SMEM mbarriers, instantiates the pipeline object, initializes barriers).
        Must be called exactly once before ``run()``.

        This is a plain Python method (not ``@cute.jit``) so that
        ``_is_setup`` is assigned at Python level and never
        auto-promoted to a staged Boolean by the DSL tracer.
        """
        assert not self._is_setup, (
            "setup_resources_and_tasks must be called exactly once"
        )
        self._prepare_resource_runtime_metadata()
        self._setup_resources_and_tasks_impl()
        self._is_setup = True

    @cute.jit
    def _setup_resources_and_tasks_impl(self) -> None:
        smem_allocator = self._smem_allocator
        if cutlass.const_expr(smem_allocator is not None):
            assert smem_allocator is not None
            self._smem_base = smem_allocator.allocate()
            smem_allocator.assign_barrier_ptrs()
            tmem_ptr_alloc = smem_allocator.tmem_ptr_alloc
            if cutlass.const_expr(tmem_ptr_alloc is not None):
                assert tmem_ptr_alloc is not None
                self._tmem_ptr_i32 = smem_allocator.get(tmem_ptr_alloc)
        for resource in self.resources:
            resource.create()

    def run(self) -> None:
        """Execute all tasks.

        Each ``task.run()`` call gates on the current warp index, so
        every warp enters this method but only the warps assigned to a
        given task execute its schedule body.

        When an ``SmemAllocator`` or ``tmem_ptr_i32`` is configured,
        builds a ``ResourceContext`` and passes it to every task's
        ``init_variables`` and ``run_body``.

        This is a plain Python method (not ``@cute.jit``) so that the
        ``_is_setup`` assertion runs at Python level against a plain
        bool, avoiding staged-Boolean and early-exit issues.

        Raises
        ------
        AssertionError
            If ``setup_resources_and_tasks()`` has not been called.
        """
        assert self._is_setup, "setup_resources_and_tasks must be called before run"
        self._run_impl()

    @cute.jit
    def _run_impl(self) -> None:
        context = ResourceContext(
            smem_base=self._smem_base,
            tmem_ptr_i32=self._tmem_ptr_i32,
        )

        # PipelineGroups are not in any task's src/dst resources, so
        # their pipeline states won't be created by task.init_variables.
        # Initialise them here so group-level producer_state /
        # consumer_state are ready before any task body runs.
        for resource in self.resources:
            if cutlass.const_expr(isinstance(resource, PipelineGroup)):
                resource.initialize_runtime_state_internal(context)

        # NOTE: Two-phase dispatch — keep these as separate loops.
        # Merging init_variables() and run_body() into one loop causes a
        # perf regression.
        # We suspect it's related to how MLIR SSA values created inside
        # warp-gated scf.if blocks inflate the scf.while iter_arg set,
        # but the exact mechanism is still being investigated.
        for task in self.tasks:
            task.init_variables(context)
        # Interleaved: initialize each task's pipeline state to its
        # warp-local lane.  The normal pipeline APIs can then index the
        # correct physical barrier while _strided_advance keeps each lane
        # on its own stage sequence.
        if cutlass.const_expr(any(t._has_interleaved_pipeline() for t in self.tasks)):
            for task in self.tasks:
                if cutlass.const_expr(task._has_interleaved_pipeline()):
                    task._init_interleaved_state()

        for task in self.tasks:
            task.run_body(context)
