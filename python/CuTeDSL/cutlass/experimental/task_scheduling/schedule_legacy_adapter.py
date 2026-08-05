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

"""Lower a new-style :class:`~.schedule_builder.Schedule` tree to the legacy form.

TEMPORARY BRIDGE: the new ``@schedule`` front-end builds a nested
:class:`~.schedule_builder.Schedule` tree, but the runtime + deadlock verifier
still consume the legacy *flat* form (``schedule_list`` + ``slot_routing`` +
loop bounds + skippable slot-sets) that the legacy :class:`~.task.Task`
constructor accepts.  :func:`lower_to_legacy` walks the tree and emits exactly
that legacy bundle, so the new DSL runs on the proven legacy runtime today.

This module is a deletable bridge: when the tree-walking runtime lands it
consumes the tree directly and this file (and ``lower_to_legacy``) goes away.

Scope: a flat ``head/loop/tail`` schedule cannot represent more than one domain
loop, so :func:`lower_to_legacy` raises on a schedule with more than one
``domain_loop()``.  Everything else (single domain loop, ``first_iter()`` /
``last_iter()`` guards, ``work_tile_loop()`` persistence, ``skippable()``
regions, and identity-based data-flow routing) lowers to the legacy encoding.

Legacy encoding reproduced here (must match
``task.normalize_and_validate_schedule_list`` and the old ScheduleBuilder):

- ``schedule_list`` entries are the shortest tuple form:
  ``(resource, stage)`` / ``(..., label)`` / ``(..., stage_type)`` /
  ``(..., stage_type, label)`` / ``(..., stage_type, guard)`` /
  ``(..., stage_type, guard, label)``, where ``stage_type`` is Head/Loop/Tail
  (by tree position) and ``guard`` is Always/FirstIter/LastIter.
- ``call_idx`` is a per-``(id(resource), stage, stage_type)`` counter assigned
  in execution order (the ``guard`` does not affect the key).
- ``slot_routing`` maps a producer slot
  ``(id(resource), stage, stage_type, call_idx)`` to a list of
  ``(var_names | None, [dst_triple, ...])`` where
  ``dst_triple = (resource, stage, stage_type, call_idx)``.
- the four slot-sets are keyed ``(id(resource), stage, call_idx)``.
"""

from collections.abc import Iterator
from dataclasses import dataclass, field
from typing import Optional

from .enums import LoopGuard, ScheduleStage, ScheduleStageType
from .resources import MemoryResource
from .schedule_builder import (
    BlockCondition,
    ConditionalBlock,
    DomainLoop,
    Node,
    Schedule,
    ScheduleError,
    ScheduleResult,
    Step,
    WorkTileLoop,
)

# A writer/per-step slot key: keys on the resource *id*.
_Slot = tuple[int, ScheduleStage, ScheduleStageType, int]
# A routing *destination*: like ``_Slot`` but carrying the resource *object*
# rather than its id.  The legacy runtime dereferences destinations directly
# (``dst_resource.name``, ``copy_consumer_vars_to(dst_resource, ...)``) while it
# looks writer slots up by id -- an intentional asymmetry of the legacy form
# (see the module docstring's ``slot_routing`` description).
_DstSlot = tuple[MemoryResource, ScheduleStage, ScheduleStageType, int]
# A routed variable: a source name, or a ``(source, destination)`` rename.
_VarRoute = str | tuple[str, str]

_AUX_STAGES: frozenset[ScheduleStage] = frozenset(
    {ScheduleStage.ConsumerAuxWork, ScheduleStage.ProducerAuxWork}
)


def _build_entry(
    resource: object,
    stage: ScheduleStage,
    stage_type: ScheduleStageType,
    guard: LoopGuard,
    label: object,
) -> tuple:
    """Shortest schedule tuple the legacy normaliser accepts (mirrors old builder).

    ``resource`` is the entry's recorded identity -- a bare ``MemoryResource`` or,
    for a PipelineGroup member access, a ``_GroupMemberRef`` the legacy normaliser
    unwraps.
    """
    is_loop = stage_type == ScheduleStageType.Loop
    is_always = guard == LoopGuard.Always
    has_label = label is not None
    if is_loop and is_always and not has_label:
        return (resource, stage)
    if is_loop and is_always and has_label:
        return (resource, stage, label)
    if is_always and not has_label:
        return (resource, stage, stage_type)
    if is_always and has_label:
        return (resource, stage, stage_type, label)
    if not has_label:
        return (resource, stage, stage_type, guard)
    return (resource, stage, stage_type, guard, label)


@dataclass
class _Lowerer:
    """Single-pass tree walker producing the legacy bundle."""

    schedule_list: list[tuple] = field(default_factory=list)
    call_counts: dict[tuple[int, ScheduleStage, ScheduleStageType], int] = field(
        default_factory=dict
    )
    # Step identity -> its producer slot, used to resolve routes after the walk.
    step_slot: dict[int, _Slot] = field(default_factory=dict)
    routing_edges: list[tuple[_Slot, Optional[_VarRoute], _DstSlot]] = field(
        default_factory=list
    )
    pre_head: set = field(default_factory=set)
    post_tail: set = field(default_factory=set)
    skip_head: set = field(default_factory=set)
    skip_tail: set = field(default_factory=set)
    seen_domain_loop: bool = False
    # Whether the schedule contains a ``work_tile_loop()``.  Hoisting head/tail
    # aux work to run once outside the persistent loop is only valid relative to
    # an explicit ``work_tile_loop()``; with only a ``domain_loop()`` the
    # persistent runtime re-runs the whole body (head+loop+tail) per work tile,
    # so head init (e.g. ``init_softmax_state``) must NOT be hoisted.
    has_wtl: bool = False

    def _call_idx(
        self, resource: MemoryResource, stage: ScheduleStage, st: ScheduleStageType
    ) -> int:
        key = (id(resource), stage, st)
        idx = self.call_counts.get(key, 0)
        self.call_counts[key] = idx + 1
        return idx

    def _record_step(
        self,
        step: Step,
        *,
        stage_type: ScheduleStageType,
        guard: LoopGuard,
        in_skippable: bool,
        outside_wtl: bool,
    ) -> None:
        resource = step.memory_resource
        stage = step.schedule_stage
        call_idx = self._call_idx(resource, stage, stage_type)
        self.step_slot[id(step)] = (id(resource), stage, stage_type, call_idx)
        # The schedule-list entry carries the group-qualified ref (when the step
        # targets a PipelineGroup member) so the legacy normaliser enforces the
        # group barrier rules; slot keys above stay on the bare member identity.
        # The ref is re-derived here from the member's back-reference -- it never
        # propagates through the tree.
        group = resource.pipeline_group
        if group is not None:
            # Imported lazily: pipeline_group is a heavier module (it pulls in
            # the pipeline runtime), so it is not imported at module load.
            from .pipeline_group import _GroupMemberRef

            entry_resource: object = _GroupMemberRef(group, resource)
        else:
            entry_resource = resource
        self.schedule_list.append(
            _build_entry(entry_resource, stage, stage_type, guard, step.label)
        )
        slot_key = (id(resource), stage, call_idx)
        if in_skippable and stage_type == ScheduleStageType.Head:
            self.skip_head.add(slot_key)
        elif in_skippable and stage_type == ScheduleStageType.Tail:
            self.skip_tail.add(slot_key)
        # Only hoist aux/barrier head/tail work to run once outside the
        # persistent work loop when an explicit ``work_tile_loop()`` exists.
        # Without one (e.g. a ``domain_loop()``-only persistent kernel like FMHA
        # decode), the persistent runtime re-runs the entire body per work tile;
        # hoisting head init there would run it once and skip it on every later
        # tile, leaving stale per-tile state (softmax accumulators, TMEM
        # descriptors) -> numerical corruption on persistent multi-tile runs.
        if (
            self.has_wtl
            and outside_wtl
            and (stage in _AUX_STAGES or resource.is_barrier)
        ):
            if stage_type == ScheduleStageType.Tail:
                self.post_tail.add(slot_key)
            else:
                self.pre_head.add(slot_key)

    def walk(
        self,
        nodes: list[Node],
        *,
        stage_type: ScheduleStageType,
        guard: LoopGuard,
        in_skippable: bool,
        in_wtl: bool,
        outside_wtl: bool,
    ) -> None:
        """Recursively lower ``nodes`` in execution order.

        ``stage_type`` marks whether ``nodes`` are inside the domain loop
        (``Loop``).  Outside it, a step is ``Head`` before the single domain loop
        and ``Tail`` after it; the ``seen_domain_loop`` latch makes that hold even
        across ``skippable()`` / conditional nesting (so a sibling WorkQueue op
        after a nested ``skippable(domain_loop())`` is still ``Tail``).  ``guard``
        carries first/last-iter; ``in_skippable`` / ``in_wtl`` / ``outside_wtl``
        drive the slot-set bookkeeping.
        """
        for node in nodes:
            match node:
                case Step():
                    if stage_type is ScheduleStageType.Loop:
                        section = ScheduleStageType.Loop
                    elif self.seen_domain_loop:
                        section = ScheduleStageType.Tail
                    else:
                        section = ScheduleStageType.Head
                    self._record_step(
                        node,
                        stage_type=section,
                        guard=guard,
                        in_skippable=in_skippable,
                        outside_wtl=outside_wtl,
                    )
                case DomainLoop(body=body):
                    self.seen_domain_loop = True
                    self.walk(
                        body,
                        stage_type=ScheduleStageType.Loop,
                        guard=guard,
                        in_skippable=in_skippable,
                        in_wtl=in_wtl,
                        outside_wtl=False,
                    )
                case WorkTileLoop(body=body):
                    self.walk(
                        body,
                        stage_type=ScheduleStageType.Head,
                        guard=guard,
                        in_skippable=in_skippable,
                        in_wtl=True,
                        outside_wtl=False,
                    )
                case ConditionalBlock(condition=condition, body=body):
                    nf = guard
                    nskip = in_skippable
                    if condition is BlockCondition.FirstIter:
                        nf = LoopGuard.FirstIter
                    elif condition is BlockCondition.LastIter:
                        nf = LoopGuard.LastIter
                    elif condition is BlockCondition.Skippable:
                        nskip = True
                    self.walk(
                        body,
                        stage_type=stage_type,
                        guard=nf,
                        in_skippable=nskip,
                        in_wtl=in_wtl,
                        outside_wtl=outside_wtl,
                    )

    def build_slot_routing(self) -> Optional[dict]:
        """Group routing edges into the legacy ``SlotRouting`` dict shape."""
        if not self.routing_edges:
            return None
        # writer_slot -> dst_slot -> (dst_slot, [var_routes])
        per_writer: dict[
            _Slot, dict[_DstSlot, tuple[_DstSlot, list[Optional[_VarRoute]]]]
        ] = {}
        for writer, var_route, dst in self.routing_edges:
            per_dst = per_writer.setdefault(writer, {})
            if dst in per_dst:
                per_dst[dst][1].append(var_route)
            else:
                per_dst[dst] = (dst, [var_route])
        result: dict = {}
        for writer, per_dst in per_writer.items():
            groups: dict[Optional[tuple[_VarRoute, ...]], list[_DstSlot]] = {}
            for dst, var_routes in per_dst.values():
                if any(v is None for v in var_routes):
                    sig: Optional[tuple[_VarRoute, ...]] = None
                else:
                    seen: list[_VarRoute] = []
                    for v in var_routes:
                        # The None branch above handles any-None; here every
                        # element is a concrete _VarRoute.
                        assert v is not None
                        if v not in seen:
                            seen.append(v)
                    sig = tuple(seen)
                groups.setdefault(sig, []).append(dst)
            result[writer] = [
                (None if sig is None else list(sig), dsts)
                for sig, dsts in groups.items()
            ]
        return result


def _iter_nodes(nodes: list[Node]) -> Iterator[Node]:
    for node in nodes:
        yield node
        match node:
            case Step():
                pass
            case (
                ConditionalBlock(body=body)
                | DomainLoop(body=body)
                | WorkTileLoop(body=body)
            ):
                yield from _iter_nodes(body)


def lower_to_legacy(schedule: Schedule) -> ScheduleResult:
    """Lower a new-style ``Schedule`` tree to a legacy :class:`~.schedule_builder.ScheduleResult`.

    Raises :class:`~.schedule_builder.ScheduleError` if the schedule has more
    than one ``domain_loop()`` (the flat legacy form cannot represent it) or a
    ``domain_loop()`` with a non-static ``start``/``step`` (the legacy form only
    supports a dynamic *end* via ``domain_getter``).
    """
    domain_loops = [n for n in _iter_nodes(schedule.body) if isinstance(n, DomainLoop)]
    if len(domain_loops) > 1:
        raise ScheduleError(
            "legacy lowering supports at most one domain_loop() per schedule; "
            f"found {len(domain_loops)}. Multiple/sequential domain loops require "
            "the tree-walking runtime."
        )

    # Validate + extract the single domain loop's bounds up front (before the
    # walk) so an unrepresentable loop fails fast and all domain-loop handling
    # lives in one place.
    loop_start = loop_end = loop_step = None
    domain_getter = None
    unroll: int | None = 1
    if domain_loops:
        dl = domain_loops[0]
        if callable(dl.start) or callable(dl.step):
            raise ScheduleError(
                "legacy lowering only supports a dynamic domain_loop() end "
                "(via domain_getter); start and step must be static."
            )
        loop_start = dl.start
        loop_step = dl.step
        if callable(dl.end):
            domain_getter = dl.end
        else:
            loop_end = dl.end
        unroll = dl.unroll

    work_tile_loops = [
        n for n in _iter_nodes(schedule.body) if isinstance(n, WorkTileLoop)
    ]
    skip_if = work_tile_loops[0].skip_if if work_tile_loops else None

    lowerer = _Lowerer(has_wtl=bool(work_tile_loops))
    lowerer.walk(
        schedule.body,
        stage_type=ScheduleStageType.Head,
        guard=LoopGuard.Always,
        in_skippable=False,
        in_wtl=False,
        outside_wtl=True,
    )

    # Resolve routes now that every step has a slot: each Route lives on its
    # producing step and points at the consuming step + destination argument.
    # The recorded ``step_slot`` keys on ``id(resource)``; that is correct for
    # the writer key, but a *destination* must carry the resource object (see
    # ``_DstSlot``), so swap the id back to the object via the consuming step.
    for step in (n for n in _iter_nodes(schedule.body) if isinstance(n, Step)):
        writer = lowerer.step_slot[id(step)]
        for route in step.routes:
            _dst_res_id, dst_stage, dst_stage_type, dst_call_idx = lowerer.step_slot[
                id(route.destination)
            ]
            dst: _DstSlot = (
                route.destination.memory_resource,
                dst_stage,
                dst_stage_type,
                dst_call_idx,
            )
            src_name = route.source.slot_name
            # A routed source is always a declared, named variable.
            assert src_name is not None
            dst_name = route.destination_argument
            var_route: _VarRoute = (
                src_name if src_name == dst_name else (src_name, dst_name)
            )
            lowerer.routing_edges.append((writer, var_route, dst))

    # Collect each step's constexpr work-kwargs (auto-forwarded to the work
    # method), keyed on the same writer-slot identity as ``slot_routing`` so the
    # runtime can look them up by ``StageInfo.routing_slot``.
    constexpr_work_kwargs: dict = {}
    for step in (n for n in _iter_nodes(schedule.body) if isinstance(n, Step)):
        if step.constexpr_kwargs:
            constexpr_work_kwargs[lowerer.step_slot[id(step)]] = dict(
                step.constexpr_kwargs
            )

    return ScheduleResult(
        schedule_list=lowerer.schedule_list,
        slot_routing=lowerer.build_slot_routing(),
        constexpr_work_kwargs=constexpr_work_kwargs or None,
        resources=schedule.resources,
        loop_start=loop_start,
        loop_end=loop_end,
        loop_step=loop_step,
        domain_getter=domain_getter,
        unroll=unroll,
        skip_if=skip_if,
        has_work_tile_loop=bool(work_tile_loops),
        pre_work_loop_head_slots=lowerer.pre_head,
        post_work_loop_tail_slots=lowerer.post_tail,
        skippable_head_slots=lowerer.skip_head,
        skippable_tail_slots=lowerer.skip_tail,
    )
