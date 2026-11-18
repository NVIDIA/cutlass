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
"""Tree-walking Task runtime for the Task Scheduling (TS) framework.

The runtime walks the nested :class:`~.schedule_builder.Schedule` tree
directly and lowers each node to traceable instructions.

``run`` walks the whole tree via :meth:`run_node`: a ``DomainLoop`` /
``WorkTileLoop`` / ``WhileTrueLoop`` lowers to an ``scf.for`` / ``scf.while``;
``FirstIter`` / ``LastIter`` / ``Skippable`` / opaque guards to runtime
branches; ``LoopBreak`` suppresses the remainder of its while-loop iteration;
standard pipeline stages to the pipeline ops (acquire / commit / wait /
release); and a work step calls the resource method with its routed inputs
(from ``route_slots``) and constexpr kwargs, routing the return to the
consuming steps.  In-flight producer stages are drained after the body.
"""

from __future__ import annotations

import inspect

from collections.abc import Callable, Iterator
from dataclasses import dataclass, replace
from typing import Any, cast

import cutlass
import cutlass.cute as cute
import cutlass.pipeline as pipeline
from cutlass.experimental import primitives as prims

import cutlass.cute.experimental.iket as iket
from cutlass.base_dsl.leaf_utils import TraversableLeafMixin
from cutlass.base_dsl.multi_stage_manager import constexpr_loop_scope

from .enums import (
    BlockGuard,
    ComplementedIterationPredicate,
    FIRST_ITER,
    GuardAnd,
    GuardOr,
    LAST_ITER,
    SKIPPABLE,
    Every,
    IterationPredicate,
    OpaqueCondition,
    PipelineGroupMode,
    ScheduleStage,
    StateRole,
    iter_leaves,
)
from . import ir_emitters
from .ir_emitters import emits_ir
from .memory import ResourceContext
from .pipeline_group import PipelineGroup
from .resources import (
    LOOP_STATE_UNAVAILABLE,
    MemoryResource,
    PipelineConfig,
    StageInfo,
    WorkQueue,
    WorkTileInfo,
    _CONSUMER_WORK_FNS_ATTR,
    _PRODUCER_WORK_FNS_ATTR,
    _collect_named_work_fns,
    _format_did_you_mean,
    _validate_consumer_produced_value_dtype,
)
from .schedule_builder import (
    ConditionalBlock,
    DomainLoop,
    LoopBreak,
    LoopHook,
    Node,
    Schedule,
    ScheduleError,
    StateAdvance,
    Step,
    WhileTrueLoop,
    WorkTileLoop,
    _child_nodes,
    _iter_nodes,
    ensure_explicit_state_ir,
    is_queue_advance_step,
    validate_queue_advance_placement,
)

# The scheduler annotates generated code with inline PTX comments. Targets that
# reject inline PTX asm can set ``emit_ptx_comments = False`` to suppress them
# (e.g. ``task_scheduling.task.emit_ptx_comments = False``).
emit_ptx_comments = True


@dataclass(frozen=True)
class WarpSlot:
    """One warp's task ownership on one CTA rank or on every CTA."""

    warp_idx: int
    cta_rank: int | None


@dataclass(frozen=True)
class _LoopContext:
    """Resolved induction state of the enclosing domain or while-true loop.

    ``index`` is the current loop cursor: the ``scf.for`` induction value for a
    domain loop, or the init/advance hook result for a ``while_true_loop``.
    ``start`` / ``end`` / ``step`` are the domain loop's resolved bounds, or
    ``LOOP_STATE_UNAVAILABLE`` inside a while-true loop.  Threaded so a nested
    first/last iter conditional can test the boundary and a work step can fill
    its ``StageInfo`` loop offset/bounds.
    """

    index: Any
    start: Any
    end: Any
    step: Any


@dataclass(frozen=True)
class _WalkContext:
    """Read-only context threaded down the schedule walk.

    Every field is the state the enclosing loops/regions impose on the nodes
    below them; a node forwards it unchanged or replaces the parts it owns.

    Attributes
    ----------
    loop : _LoopContext or None
        The innermost enclosing domain or while-true loop's induction state, or
        ``None`` outside any such loop.
    skip : Boolean or None
        The enclosing work-tile loop's per-tile skip predicate, or ``None`` when
        there is no ``skip_if`` (a ``skippable()`` region then always runs).
    work_tile : WorkTileInfo or None
        The current tile: the block coordinate (non-persistent) or the queue's
        tile (inside a ``WorkTileLoop``).
    """

    loop: _LoopContext | None = None
    skip: object = None
    work_tile: Any = None


# -- module-private helpers (independent of any Task instance) --------------


def _is_fork_secondary(resource: MemoryResource) -> bool:
    """True if ``resource`` is a non-primary Fork group member.

    Secondary Fork members share the primary's full barrier and must not call
    ``producer_tail`` (it would re-arm the shared barrier and hang).
    """
    pg = resource.pipeline_group
    if pg is None or isinstance(resource, PipelineGroup):
        return False
    return pg.mode == PipelineGroupMode.Fork and resource is not pg.members[0]


def _require_pipeline_config(resource: MemoryResource) -> PipelineConfig:
    """Return the pipeline config of a resource taking part in a pipeline stage.

    Only resources that carry a pipeline reach the stage lowerings, so the
    config is present wherever this is called.
    """
    cfg = resource.pipeline_config
    assert cfg is not None
    return cfg


def _route_source_default(source: Any) -> Any:
    """Return the routed source variable's default (dtype-correct DSL value)."""
    if source.default_factory is not None:
        return source.default_factory()
    return source.default


def _is_producer_stage(stage: ScheduleStage) -> bool:
    """True for a producer-side schedule stage."""
    return stage in {
        ScheduleStage.ProducerAuxWork,
        ScheduleStage.ProducerTryAcquire,
        ScheduleStage.ProducerAcquire,
        ScheduleStage.ProducerWork,
        ScheduleStage.ProducerCommit,
    }


def _producer_state_owned_by_signaling(resource: MemoryResource) -> bool:
    """True when only signalling CTAs advance this resource's producer cursor.

    Most leader-routed producers still run producer work (and advance the
    software-pipeline cursor) on every CTA and only gate the mbarrier signal.
    Barrier-only throttle resources are the exception: the cursor is owned by
    the signalling CTA alone, so non-leaders must not advance it.
    """
    return bool(getattr(resource, "producer_state_owned_by_signaling_ctas_only", False))


def _previous_producer_acquire_index(resource: MemoryResource) -> Any:
    """Return the stage index the acquire cursor just moved past."""
    cfg = resource.pipeline_config
    assert cfg is not None
    stride = cfg.producer_acquire_interleave_stride
    index = resource.producer_state.index
    return (index - stride + cfg.num_stages) % cfg.num_stages


def _previous_consumer_wait_index(resource: MemoryResource) -> Any:
    """Return the stage index the wait cursor just moved past."""
    cfg = resource.pipeline_config
    assert cfg is not None
    stride = cfg.consumer_wait_interleave_stride
    index = resource.consumer_state.index
    return (index - stride + cfg.num_stages) % cfg.num_stages


def _cta_v_size(cfg: Any) -> int:
    """V-group size from ``cta_layout_vmnk[0]`` (1 when no cluster layout)."""
    layout = cfg.cta_layout_vmnk
    if layout is None:
        return 1
    if isinstance(layout, (tuple, list)) and len(layout) > 0:
        return int(layout[0])
    return 1


def _consumer_wait_signaling(cfg: Any) -> Any:
    """SignalingThreads governing the consumer wait (falls back to release)."""
    if cfg.consumer_wait_signaling_threads is not None:
        return cfg.consumer_wait_signaling_threads
    return cfg.consumer_signaling_threads


def _work_tile_loop_label(node: WorkTileLoop) -> str:
    """Render the work-tile loop's PTX-comment label (queue and skip_if)."""
    label = f"WorkTileLoop(queue={node.work_queue.name}"
    if node.skip_if is not None:
        label += f", skip_if={getattr(node.skip_if, '__name__', 'skip')}"
    return label + ")"


def _last_iteration_index(start: Any, end: Any, step: Any) -> Any:
    """Return the induction value of the loop's final iteration.

    ``last = start + (n - 1) * step`` where ``n = ceildiv(end - start, step)``
    is the trip count.  Evaluates in Python for static (int) bounds and in
    staged arithmetic otherwise; assumes a positive ``step``.
    """
    num_iters = (end - start + step - 1) // step
    return start + (num_iters - 1) * step


def _condition_value_to_bool(value: object) -> Any:
    """Normalize a stored ``OpaqueCondition`` result to a DSL Boolean.

    A ``Boolean`` passes through; any other (integer-like) value is false only
    when zero.
    """
    if cutlass.const_expr(isinstance(value, cutlass.Boolean)):
        return value
    return cutlass.Boolean(value != 0)


def _describe_guard(guard: object) -> str:
    """Short label for a ``BlockGuard`` used in PTX comments.

    Compares the fieldless singleton guards by value (``==``). The DSL
    reconstructs a frozen-dataclass guard when it crosses a ``@cute.jit``
    boundary.
    """
    if guard == SKIPPABLE:
        return "Skippable"
    if guard == FIRST_ITER:
        return "FirstIter"
    if guard == LAST_ITER:
        return "LastIter"
    if isinstance(guard, ComplementedIterationPredicate):
        return f"Not({_describe_guard(guard.predicate)})"
    if isinstance(guard, Every):
        return f"Every(period={guard.period}, start={guard.start})"
    if isinstance(guard, OpaqueCondition):
        return f"{'when_false' if guard.negated else 'when_true'}(key={guard.key!r})"
    if isinstance(guard, (GuardAnd, GuardOr)):
        operator = " and " if isinstance(guard, GuardAnd) else " or "
        return (
            "(" + operator.join(_describe_guard(item) for item in guard.operands) + ")"
        )
    return type(guard).__name__


def _describe_bound(bound: object) -> str:
    """Render a DomainLoop bound: a static value or a per-tile Task method."""
    if callable(bound):
        return f"{getattr(bound, '__name__', 'method')}()"
    return str(bound)


def _strided_domain_lane_ids(nodes: list[Node], stride: int) -> set[int]:
    """Lane ids ``start % stride`` from every matching static DomainLoop.

    Collects every ``DomainLoop`` with ``step == stride`` and a static
    ``start``.  An empty set means no matching loop; more than one distinct
    id means the schedule assigns conflicting domain lanes on one task.
    """
    lanes: set[int] = set()

    def walk(body: list[Node]) -> None:
        for node in body:
            if isinstance(node, DomainLoop):
                if (
                    isinstance(node.step, int)
                    and node.step == stride
                    and isinstance(node.start, int)
                ):
                    lanes.add(node.start % stride)
                walk(node.body)
            elif not isinstance(node, Step):
                walk(_child_nodes(node))

    walk(nodes)
    return lanes


def _reject_unsupported_pipeline(resource: MemoryResource) -> None:
    """Guard the interleaved producer drain against a resource with no pipeline.

    The barrier-op lowerings (``_producer_acquire`` / ``_consumer_wait`` / ...)
    no-op on a resource without a ``pipeline_config`` -- a static-persistent
    WorkQueue's acquire/commit/wait/release are tile-scheduler bookkeeping.
    This guard applies where a missing pipeline is a genuine schedule error:
    the interleaved producer drain reads the resource's
    ``producer_acquire_interleave_stride`` and cannot run without a configured pipeline.
    """
    cfg = resource.pipeline_config
    if cutlass.const_expr(cfg is None):
        raise ValueError(
            f"{resource.name}: pipeline op on a resource with no pipeline_config."
        )


def _runtime_pipeline_state(step: Step) -> Any:
    """Resolve a step's explicit state slot to its runtime resource attribute."""
    binding = step.state_binding
    assert binding is not None
    resource = binding.resource
    if binding.role is StateRole.Producer:
        state_owner = (
            resource.members[0]
            if isinstance(resource, PipelineGroup)
            and resource.mode is PipelineGroupMode.Fork
            else resource
        )
        state = (
            state_owner.producer_state
            if binding.slot == 0
            else state_owner.producer_commit_state
        )
    else:
        src = resource.state_src
        state = src.consumer_state if binding.slot == 0 else src.consumer_release_state
    if binding.offset == 0 and binding.stage_index is None:
        return state
    cfg = _require_pipeline_config(resource)
    stride = (
        cfg.producer_commit_interleave_stride
        if binding.role is StateRole.Producer
        else cfg.consumer_release_interleave_stride
    )
    raw_index = (
        binding.stage_index
        if binding.stage_index is not None
        else state.index + binding.offset * stride
    )
    # A state view needs Python's Euclidean modulo, but the lowering of `%` on
    # a runtime index is a signed remainder, and `.previous()` can make
    # `raw_index` negative before the cursor has wrapped.  Adding `num_stages`
    # before the second fold normalizes those negative remainders.
    stage_index = (raw_index % cfg.num_stages + cfg.num_stages) % cfg.num_stages
    # The numerator is an exact multiple of `num_stages`, so the truncating
    # lowering of `//` yields the true (possibly negative) wrap count, whose
    # parity `& 1` reads correctly in two's complement.
    wraps = (raw_index - stage_index) // cfg.num_stages
    return pipeline.PipelineState(
        cfg.num_stages,
        state.count + binding.offset,
        cutlass.Int32(stage_index),
        state.phase ^ (wraps & 1),
    )


def _stage_cursor_and_barrier(
    step: Step,
    use_release_state: bool = False,
    follows_acquire: bool = False,
    use_explicit_binding: bool = False,
) -> tuple:
    """Return ``(stage_idx, barrier)`` for a work step on a pipelined resource."""
    resource = step.memory_resource
    if cutlass.const_expr(resource.pipeline_config is None):
        return None, None
    if cutlass.const_expr(use_explicit_binding):
        binding = step.state_binding
        assert binding is not None
        pipe = resource.pipeline
        state = _runtime_pipeline_state(step)
        stage_idx = state.index
        resource_cfg = _require_pipeline_config(resource)
        # A work-stage barrier is role-specific: producers arm the full
        # barrier, while consumers report completion to the empty barrier.
        # Resolving every explicit binding through ``sync_object_full`` makes
        # the consumer wait and its completion signal target different rings,
        # leaving the producer blocked on the empty barrier. Interleaved roles
        # are the exception: their state already selects a physical full-barrier
        # lane, matching the implicit-state lowering below.
        if cutlass.const_expr(binding.role is StateRole.Producer):
            barrier_ptr = (
                pipe.sync_object_full.get_barrier(stage_idx)
                if cutlass.const_expr(
                    resource_cfg.producer_acquire_interleave_stride > 1
                )
                else pipe.producer_get_barrier(state)
            )
        else:
            src_cfg = _require_pipeline_config(resource.state_src)
            barrier_ptr = (
                pipe.sync_object_full.get_barrier(stage_idx)
                if cutlass.const_expr(src_cfg.consumer_wait_interleave_stride > 1)
                else pipe.consumer_get_barrier(state)
            )
        barrier: Any = cutlass.Array(barrier_ptr, shape=(1,))
        return stage_idx, barrier
    cfg = resource.pipeline_config
    assert cfg is not None
    pipe = resource.pipeline
    if cutlass.const_expr(_is_producer_stage(step.schedule_stage)):
        follows = cfg.advance_on_acquire and follows_acquire
        if cutlass.const_expr(follows):
            stage_idx = _previous_producer_acquire_index(resource)
            pipeline_state = resource.producer_state
        elif cutlass.const_expr(cfg.advance_on_acquire):
            pipeline_state = resource.producer_commit_state
            stage_idx = pipeline_state.index
        else:
            pipeline_state = resource.producer_state
            stage_idx = pipeline_state.index
        if cutlass.const_expr(cfg.producer_acquire_interleave_stride > 1 or follows):
            barrier = cutlass.Array(
                pipe.sync_object_full.get_barrier(stage_idx), shape=(1,)
            )
        else:
            barrier = cutlass.Array(
                pipe.producer_get_barrier(pipeline_state), shape=(1,)
            )
        return stage_idx, barrier

    src = resource.state_src
    scfg = src.pipeline_config
    assert scfg is not None
    if cutlass.const_expr(use_release_state):
        state = src.consumer_release_state
        stage_idx = state.index
    elif cutlass.const_expr(scfg.advance_on_wait):
        state = src.consumer_state
        stage_idx = _previous_consumer_wait_index(src)
    else:
        state = src.consumer_state
        stage_idx = state.index
    if cutlass.const_expr(scfg.consumer_wait_interleave_stride > 1):
        barrier = cutlass.Array(
            pipe.sync_object_full.get_barrier(stage_idx), shape=(1,)
        )
    else:
        barrier = cutlass.Array(pipe.consumer_get_barrier(state), shape=(1,))
    return stage_idx, barrier


def _callable_accepts_n_args(fn: Any, n_args: int) -> bool:
    """True when ``fn`` can be bound with ``n_args`` positional arguments.

    A callable that exposes no inspectable Python signature is treated as
    accepting the arity, deferring any real mismatch to the eventual call.
    """
    try:
        signature = inspect.signature(fn)
    except (TypeError, ValueError):
        return True
    try:
        signature.bind(*([object()] * n_args))
    except TypeError:
        return False
    return True


def _resolve_work_method(
    resource: MemoryResource,
    schedule_stage: ScheduleStage,
    label: object,
) -> Callable[..., object] | None:
    """Resolve a work callable from its stage and label."""
    if schedule_stage in {
        ScheduleStage.ConsumerAuxWork,
        ScheduleStage.ConsumerWork,
    }:
        return _resolve_named_or_default(
            resource,
            label,
            schedule_stage,
            attr=_CONSUMER_WORK_FNS_ATTR,
            stage_attr="_consumer_work_stage",
            default_stage=ScheduleStage.ConsumerWork,
            side="consumer",
            decorator="@consumer_work",
        )
    if schedule_stage in {
        ScheduleStage.ProducerAuxWork,
        ScheduleStage.ProducerWork,
    }:
        return _resolve_named_or_default(
            resource,
            label,
            schedule_stage,
            attr=_PRODUCER_WORK_FNS_ATTR,
            stage_attr="_producer_work_stage",
            default_stage=ScheduleStage.ProducerWork,
            side="producer",
            decorator="@producer_work",
        )
    return None


def _resolve_named_or_default(
    resource: MemoryResource,
    label: object,
    schedule_stage: ScheduleStage,
    *,
    attr: str,
    stage_attr: str,
    default_stage: ScheduleStage,
    side: str,
    decorator: str,
) -> Callable[..., object]:
    """Resolve a named work method from its schedule stage and label."""
    named_fns = {}
    for candidate_label, method_name in _collect_named_work_fns(
        type(resource), attr
    ).items():
        method = getattr(type(resource), method_name, None)
        if getattr(method, stage_attr, default_stage) == schedule_stage:
            named_fns[candidate_label] = method_name

    if label is not None:
        if label in named_fns:
            return getattr(resource, named_fns[label])
        available = list(named_fns)
        hint = _format_did_you_mean(str(label), available)
        raise ValueError(
            f"{side.capitalize()} work label {label!r} not found on "
            f"{type(resource).__name__} (resource '{resource.name}').\n"
            f"  Registered {decorator} labels: {available}\n"
            f"{hint}"
        )

    if isinstance(resource, WorkQueue) and named_fns:
        available = list(named_fns)
        raise ValueError(
            f"{type(resource).__name__} (resource '{resource.name}') has "
            f"{len(named_fns)} {decorator} "
            f"{'method' if len(named_fns) == 1 else 'methods'} "
            f"{available} but the schedule entry has no label.\n"
            "  WorkQueue entries must use the named scheduler operation; "
            f"add a label such as {available[0]!r}."
        )

    if named_fns:
        available = list(named_fns)
        raise ValueError(
            f"{type(resource).__name__} (resource '{resource.name}') has "
            f"{len(named_fns)} {decorator} "
            f"{'method' if len(named_fns) == 1 else 'methods'} "
            f"{available} but the schedule step has no label.\n"
            f"  Add a label to the step, e.g. the {decorator} method name "
            f"{available[0]!r}."
        )

    raise ValueError(
        f"{type(resource).__name__} (resource '{resource.name}') has no "
        f"{decorator} method; the tree-walking runtime dispatches work by the "
        f"step's label, so define a named {decorator} method."
    )


class Task(TraversableLeafMixin):
    """A unit of warp-specialised work that executes by walking its schedule tree.

    A Task binds a contiguous warp range ``[warp_idx, warp_idx + num_warps)`` to
    a pair of resource lists (``src_resources`` consumed by the task,
    ``dst_resources`` produced by it) and a captured
    :class:`~.schedule_builder.Schedule` tree. Every warp enters :meth:`run`,
    but only the warps in the task's range execute its body (see
    :meth:`is_selected`).

    Body execution walks ``schedule`` node by node through :meth:`run_node`.
    Persistence is encoded as a ``WorkTileLoop`` node in the tree, allowing a
    single unified walk.

    Attributes
    ----------
    name : str
        Human-readable label used in PTX comments and diagnostics.
    src_resources : list[MemoryResource]
        Resources this task reads (consumer side).
    dst_resources : list[MemoryResource]
        Resources this task writes (producer side).
    schedule : Schedule
        The captured schedule tree, walked directly by the runtime.
    warp_idx, num_warps : int
        Warp range assigned to this task.
    num_registers : int | None
        Per-task register budget; ``None`` leaves the kernel default.
    run_only_on_cta_id : int | range | tuple[int, ...] | None
        When set, the whole task body runs only on those ranks in the cluster.
    debug_print : bool
        Emit per-step debug prints to stdout (default: False).
    iket_enable_profiling : bool
        When ``True``, wrap each schedule step in an IKET profiling range (see
        :meth:`_run_step`); off by default so the common path emits no markers.
    iket_profiling_stages, iket_profiling_resources : frozenset or None
        Optional filters narrowing profiling to specific stages / resource names
        (``None`` profiles all when enabled), to stay within the hardware
        marker-slot budget.
    """

    #: Kernel default register budget; a ``num_registers`` above this emits an
    #: ``INCREASE``, at or below it a ``DECREASE`` (see :meth:`_set_max_register`).
    default_num_registers: int = 128

    #: Common budget ``TaskManager`` releases to before dispatch. When set,
    #: tasks emit only a request above this floor; ``None`` preserves the
    #: legacy per-task request (see :meth:`_set_max_register`).
    register_release_floor: int | None = None

    def __init__(
        self,
        src_resources: list[MemoryResource],
        dst_resources: list[MemoryResource],
        warp_idx: int,
        num_warps: int,
        *,
        schedule: Schedule,
        num_registers: int | None = None,
        name: str = "",
        debug_print: bool = False,
        iket_enable_profiling: bool = False,
        iket_profiling_stages: frozenset | None = None,
        iket_profiling_resources: frozenset | None = None,
        run_only_on_cta_id: int | range | tuple[int, ...] | None = None,
    ) -> None:
        """Create a task from a captured :class:`~.schedule_builder.Schedule`.

        Requires a ``Schedule`` tree (the ``@schedule`` result), which the
        walker reads directly.

        ``debug_print`` controls runtime schedule diagnostics. The ``iket_*``
        parameters enable and scope per-step IKET profiling ranges.
        """
        if not isinstance(schedule, Schedule):
            raise ValueError(f"Task {name!r}: 'schedule' must be a Schedule.")
        ensure_explicit_state_ir(schedule)
        self.name = name
        self.iket_enable_profiling = iket_enable_profiling
        self.iket_profiling_stages = iket_profiling_stages
        self.iket_profiling_resources = iket_profiling_resources
        self.src_resources = src_resources
        self.dst_resources = dst_resources
        self.schedule = schedule
        self.num_registers = num_registers
        self.warp_idx = warp_idx
        self.num_warps = num_warps
        self.debug_print = debug_print
        self.run_only_on_cta_id = run_only_on_cta_id

        self.resources = list(set(src_resources + dst_resources))

        # Reject the generic monolithic work hooks up front. The walker dispatches
        # only named @…work methods.
        self._reject_generic_work()

        # Reject construction-time invalid configuration before the walk: an
        # illegal register budget, an invalid CTA pin, or a malformed domain
        # loop (unroll type, zero static step, unresolvable callable bound).
        self._validate_num_registers()
        self._validate_run_only_on_cta_id()
        self._validate_domain_loops()
        self._validate_work_tile_loop_resource()
        validate_queue_advance_placement(schedule.body)
        self._configure_explicit_state_slots()

        self._resource_context: ResourceContext | None = None

        # Per-task value scratch: one mailbox per read TaskLocalVariable, keyed
        # by ``id(variable)`` -> value. Seeded from step and condition reads at
        # the start of run_body (outside dynamic control flow), written when any
        # producer of the variable runs, and read by work steps and guards.
        self.route_slots: dict = {}

        # Reject a PipelineGroup barrier op emitted at the wrong level at construction.
        self._validate_group_stage_placement()

        # Producer work after an advance-on-acquire acquire reads the
        # just-acquired stage; split producer work uses the lagging commit cursor.
        self._producer_follow_acquire_steps = self._make_producer_follow_acquire_steps()

        # WORKAROUND: pre-initialise so that a later
        # `self.dummy = cutlass.Boolean(True)` inside dynamic for/while/if is a
        # value update, avoiding a first-time attribute add (a structural change
        # that trips "self is structured differently after this for").
        self.dummy = cutlass.Boolean(True)

    def _configure_explicit_state_slots(self) -> None:
        """Validate advance_on_* incompatibility and publish per-resource
        runtime slot requirements."""
        for resource in self.resources:
            cfg = resource.pipeline_config
            if (
                self.schedule.manual_state
                and cfg is not None
                and (cfg.advance_on_acquire or cfg.advance_on_wait)
            ):
                raise ScheduleError(
                    f"Task {self.name!r}: manual_state is incompatible with "
                    f"{resource.name}'s advance_on_acquire/advance_on_wait; spell "
                    "the split cursors with state refs and StateAdvance nodes."
                )
        for node in _iter_nodes(self.schedule.body):
            refs = []
            if isinstance(node, Step) and node.state_binding is not None:
                refs.append(node.state_binding)
            elif isinstance(node, StateAdvance):
                refs.append(node.state)
            for state in refs:
                attr = (
                    "_ts_producer_state_slots"
                    if state.role is StateRole.Producer
                    else "_ts_consumer_state_slots"
                )
                setattr(
                    state.resource,
                    attr,
                    max(getattr(state.resource, attr), state.slot + 1),
                )

    @property
    def warp_start(self) -> int:
        """Return the inclusive first warp index owned by this task."""
        return self.warp_idx

    @property
    def warp_end(self) -> int:
        """Return the exclusive end warp index owned by this task."""
        return self.warp_idx + self.num_warps

    def _ptx_comment(self, text: str) -> None:
        """Emit an inline-PTX ``// <schedule>: text`` comment when enabled.

        Prefixes the schedule name so each comment stays attributable to its
        task when several tasks' PTX is interleaved in one dump.  Used to
        annotate the generated PTX with the Python calls the walk makes
        (``resource.method`` form), a useful debugging aid.
        """
        if emit_ptx_comments:
            prims.inline_ptx(f"// {self.schedule.name}: {text}")

    def _step_comment(self, step: Step, text: str) -> None:
        """Emit a step-scoped PTX comment tagged with the step's unique id.

        Adds the ``#<unique_id>`` prefix (stable per schedule) so a comment
        pins to the exact tree node it lowered, on top of the schedule-name
        prefix :meth:`_ptx_comment` adds.
        """
        self._ptx_comment(f"#{step.unique_id} {text}")

    @cute.jit
    def run(self) -> None:
        """Initialise resource variables, then gate on warp selection and walk.

        Top-level entry point.  ``TaskManager`` may instead drive the two-phase
        ``init_variables()`` / :meth:`run_body` split across all tasks.
        """
        self.init_variables()
        self.run_body()

    @cute.jit
    def init_variables(self, context: ResourceContext | None = None) -> None:
        """Create every touched resource's runtime state, outside any control flow.

        Runs for all warps -- before the :meth:`run_body` selection gate -- so
        the DSL IR structure is identical across warps regardless of which one
        executes the body.  For each resource it resets task-local storage and
        creates pipeline state/status; the captured-mode role hooks then run per
        side.  ``context`` carries ``smem_base`` / ``tmem_ptr_i32`` when
        allocators are in use and is retained for later stage-info construction.

        Parameters
        ----------
        context : ResourceContext or None
            Allocator-provided SMEM/TMEM handles, or ``None`` when unused.
        """
        self._resource_context = context
        for resource in self.resources:
            resource.initialize_runtime_state_internal(context)

    def _uses_domain_interleave_lane(self, stride: int) -> bool:
        """True when the interleave lane comes from the domain slice.

        A ``stride > 1`` whose task warp count differs from the stride and that owns
        a strided domain slice (loop ``step == stride``, static ``start``) keys the
        lane on ``start % stride`` -- shared by all the task's warps for that loop.
        Otherwise each warp is its own lane.
        """
        return (
            stride > 1
            and self.num_warps != stride
            and bool(_strided_domain_lane_ids(self.schedule.body, stride))
        )

    def _uses_any_domain_interleave_lane(self) -> bool:
        """True when any interleaved role on this task uses the domain-slice lane."""
        for resource in self.src_resources:
            cfg = resource.state_src.pipeline_config
            if cfg is not None and (
                self._uses_domain_interleave_lane(cfg.consumer_wait_interleave_stride)
                or self._uses_domain_interleave_lane(
                    cfg.consumer_release_interleave_stride
                )
            ):
                return True
        for resource in self.dst_resources:
            cfg = resource.pipeline_config
            if cfg is not None and (
                self._uses_domain_interleave_lane(
                    cfg.producer_acquire_interleave_stride
                )
                or self._uses_domain_interleave_lane(
                    cfg.producer_commit_interleave_stride
                )
            ):
                return True
        return False

    def _warp_interleave_lane(self) -> object:
        """Warp-local interleave lane: ``warp_idx - warp_start``."""
        return cutlass.Int32(cute.arch.warp_idx() - self.warp_start)

    @cute.jit
    def _init_interleaved_state(self) -> None:
        """Seed warp-lane interleaved cursors to their lane index.

        Domain-lane cursors are seeded on each matching ``DomainLoop`` entry
        (:meth:`_seed_domain_interleave_lanes`) from that loop's
        ``start % stride``.  Warp-lane roles seed here once before the walk.

        Interleave lanes share one pipeline of ``num_stages`` barriers; a lane
        starts at its stage index and every advance steps by the role stride
        (:meth:`_advance_cursor`), so lanes never collide.  The driver calls
        this after :meth:`init_variables` and before :meth:`run_body` for tasks
        that use a stride > 1 (standalone harnesses mirror that ordering);
        cursors whose role stride is 1 keep index 0.
        """
        self._init_interleaved_state_impl()

    @cute.jit
    def _init_interleaved_state_impl(self) -> None:
        """Write each warp-lane interleaved cursor's lane index.

        Domain-lane roles are skipped here; they are seeded when the walker
        enters a matching domain loop.  Acquire/commit strides are equal and
        wait/release strides are equal (per ``PipelineConfig`` validation), so
        seeding the acquire cursor also covers a non-``advance_on_acquire``
        commit (shared ``producer_state``); the separate commit/release
        cursors are seeded only when the split (``advance_on_acquire`` /
        ``advance_on_wait``) owns them.
        """
        for resource in self.src_resources:
            src = resource.state_src
            cfg = src.pipeline_config
            if cutlass.const_expr(cfg is None):
                continue
            assert cfg is not None
            wait_stride = cfg.consumer_wait_interleave_stride
            if cutlass.const_expr(
                wait_stride > 1 and not self._uses_domain_interleave_lane(wait_stride)
            ):
                src.consumer_state._index = self._warp_interleave_lane()
            release_stride = cfg.consumer_release_interleave_stride
            if cutlass.const_expr(
                release_stride > 1
                and src._ts_consumer_state_slots > 1
                and not self._uses_domain_interleave_lane(release_stride)
            ):
                src.consumer_release_state._index = self._warp_interleave_lane()
        for resource in self.dst_resources:
            cfg = resource.pipeline_config
            if cutlass.const_expr(cfg is None):
                continue
            assert cfg is not None
            acquire_stride = cfg.producer_acquire_interleave_stride
            if cutlass.const_expr(
                acquire_stride > 1
                and not self._uses_domain_interleave_lane(acquire_stride)
            ):
                resource.producer_state._index = self._warp_interleave_lane()
            commit_stride = cfg.producer_commit_interleave_stride
            if cutlass.const_expr(
                commit_stride > 1
                and resource._ts_producer_state_slots > 1
                and not self._uses_domain_interleave_lane(commit_stride)
            ):
                resource.producer_commit_state._index = self._warp_interleave_lane()

    @cute.jit
    def _seed_domain_interleave_lanes(self, start: Any, step: Any) -> None:
        """Seed domain-lane cursors whose role stride equals this loop's step.

        Called on ``DomainLoop`` entry after bounds are resolved.  Only the
        selected warps write: domain-lane tasks share pipeline state with
        sibling lane tasks, so a non-selected pass must not overwrite the
        lane.  Roles whose stride does not match ``step`` are left unchanged.
        """
        if cutlass.const_expr(not self._uses_any_domain_interleave_lane()):
            return
        if self.is_selected():
            for resource in self.src_resources:
                src = resource.state_src
                cfg = src.pipeline_config
                if cutlass.const_expr(cfg is None):
                    continue
                assert cfg is not None
                wait_stride = cfg.consumer_wait_interleave_stride
                if cutlass.const_expr(self._uses_domain_interleave_lane(wait_stride)):
                    if step == wait_stride:
                        src.consumer_state._index = cutlass.Int32(start % wait_stride)
                release_stride = cfg.consumer_release_interleave_stride
                if cutlass.const_expr(
                    self._uses_domain_interleave_lane(release_stride)
                    and src._ts_consumer_state_slots > 1
                ):
                    if step == release_stride:
                        src.consumer_release_state._index = cutlass.Int32(
                            start % release_stride
                        )
            for resource in self.dst_resources:
                cfg = resource.pipeline_config
                if cutlass.const_expr(cfg is None):
                    continue
                assert cfg is not None
                acquire_stride = cfg.producer_acquire_interleave_stride
                if cutlass.const_expr(
                    self._uses_domain_interleave_lane(acquire_stride)
                ):
                    if step == acquire_stride:
                        resource.producer_state._index = cutlass.Int32(
                            start % acquire_stride
                        )
                commit_stride = cfg.producer_commit_interleave_stride
                if cutlass.const_expr(
                    self._uses_domain_interleave_lane(commit_stride)
                    and resource._ts_producer_state_slots > 1
                ):
                    if step == commit_stride:
                        resource.producer_commit_state._index = cutlass.Int32(
                            start % commit_stride
                        )

    @cute.jit
    def run_body(self) -> None:
        """Gate on warp selection, set the register budget, and walk the tree.

        Only the warps in ``[warp_start, warp_end)`` execute the body; the walk
        visits ``schedule.body`` once (persistence is a ``WorkTileLoop`` node
        inside it, not a separate body path).
        """
        # Pre-seed the routing slots outside dynamic control flow, so a later
        # write inside an scf.if/for is a value update on a dtype-correct slot.
        self._seed_route_slots()
        if self.is_selected():
            # The construct region lives INSIDE the selected branch, so an
            # observer brackets exactly what this task executes.
            self._run_selected_body()
            # WORKAROUND: force `self` state threading across dynamic control
            # flow (see the `self.dummy` pre-init in __init__).
            self.dummy = cutlass.Boolean(True)

    @emits_ir("task")
    def _run_selected_body(self) -> None:
        """Everything a selected task traces: the body walk and the drain."""
        self._ptx_comment(f"{self.name}.run_body[{self.warp_start}, {self.warp_end})")
        self._set_max_register()
        self.run_nodes(
            self.schedule.body,
            _WalkContext(work_tile=self._initial_body_work_tile()),
        )
        self._drain()

    def _initial_body_work_tile(self) -> Any:
        """The tile the top-level body walk starts on.

        A persistent task starts at the tile scheduler's first tile: the steps
        before the ``WorkTileLoop`` see the same initial tile the loop's first
        iteration will. A non-persistent task has no scheduler, so it addresses
        off the block coordinate.
        """
        work_tile_loop = self._find_work_tile_loop()
        if cutlass.const_expr(work_tile_loop is not None):
            assert work_tile_loop is not None
            return work_tile_loop.work_queue.initial_work_tile_info()
        return WorkTileInfo(cute.arch.block_idx(), cutlass.Boolean(True))

    @cute.jit
    def _drain(self) -> None:
        """Drain in-flight pipeline stages after the body, before the task exits.

        Shared skeleton: for every ``dst`` with a pipeline, excluding the work
        queue and fork-secondaries, ``producer_tail`` waits out its
        outstanding commits (PTX requires all mbarrier arrivals complete before
        the producing warp exits, else error-719).  Persistent shape adds the
        work queue's own ``producer_tail`` (keyed on the ``WorkTileLoop`` node).

        An interleaved (stride > 1) producer drains through
        :meth:`_interleave_producer_drain` (``producer_tail`` cannot express the
        strided tail); every non-interleaved pipeline uses ``producer_tail``.
        """
        work_tile_loop = self._find_work_tile_loop()
        work_queue = work_tile_loop.work_queue if work_tile_loop is not None else None
        for resource in self.dst_resources:
            cfg = resource.pipeline_config
            if cutlass.const_expr(
                cfg is not None
                and resource is not work_queue
                and not _is_fork_secondary(resource)
            ):
                _reject_unsupported_pipeline(resource)
                assert cfg is not None
                self._drain_resource(resource)
        # Persistent shape only: drain the work queue's own pipeline.
        if cutlass.const_expr(
            work_queue is not None
            and any(r is work_queue for r in self.dst_resources)
            and work_queue.pipeline_config is not None
        ):
            assert work_queue is not None
            self._drain_work_queue(work_queue)

    @emits_ir("drain", node=lambda self, resource: resource)
    def _drain_resource(self, resource: MemoryResource) -> None:
        """Drain one destination resource's in-flight producer commits."""
        cfg = _require_pipeline_config(resource)
        stride = cfg.producer_acquire_interleave_stride
        if cutlass.const_expr(stride > 1):
            self._interleave_producer_drain(resource, stride)
        else:
            self._producer_tail(resource)

    @emits_ir("drain", node=lambda self, work_queue: work_queue)
    def _drain_work_queue(self, work_queue: WorkQueue) -> None:
        """Drain the persistent work queue's own pipeline."""
        self._ptx_comment(f"{work_queue.name}.drain producer_tail")
        work_queue.producer_tail()

    def _find_work_tile_loop(self) -> WorkTileLoop | None:
        """Return the top-level ``WorkTileLoop`` node, or ``None`` (non-persistent)."""
        for node in self.schedule.body:
            if isinstance(node, WorkTileLoop):
                return node
        return None

    def _find_while_true_loop(self) -> WhileTrueLoop | None:
        """Return the unique ``WhileTrueLoop`` in this task, or ``None``."""
        found = [node for node in self._all_nodes() if isinstance(node, WhileTrueLoop)]
        if len(found) > 1:
            raise ScheduleError(
                f"Task {self.name!r}: at most one while_true_loop() is allowed "
                "per schedule."
            )
        return found[0] if found else None

    def _validate_work_tile_loop_resource(self) -> None:
        """Require an explicit ``WorkTileLoop``'s ``WorkQueue`` in ``src_resources``.

        The runtime reads the persistent loop's ``WorkQueue`` off the
        ``WorkTileLoop`` node, while the manager's persistence detection and
        tile-replication analysis read ``src_resources``. Listing the queue in
        ``src_resources`` keeps those two views in agreement. Raises
        ``ScheduleError`` when the node's queue is absent.
        """
        work_tile_loop = self._find_work_tile_loop()
        if work_tile_loop is None:
            return
        if not any(r is work_tile_loop.work_queue for r in self.src_resources):
            raise ScheduleError(
                f"Task {self.name!r}: work_tile_loop() WorkQueue "
                f"{work_tile_loop.work_queue.name!r} must be listed in "
                "src_resources."
            )

    @cute.jit
    def _producer_tail(self, resource: MemoryResource) -> None:
        """Wait out a resource's outstanding producer commits (simple case).

        The tail arrive is gated to the signalling CTA under CtaLeader signaling
        only when the resource's producer state is owned by signalling CTAs
        alone; otherwise every CTA drains its own cursor.
        """
        self._ptx_comment(f"{resource.name}.drain producer_tail")
        cfg = resource.pipeline_config
        assert cfg is not None
        tail_state = (
            resource.producer_commit_state
            if self._producer_commit_state_slot(resource) == 1
            else resource.producer_state
        )
        if cutlass.const_expr(_producer_state_owned_by_signaling(resource)):
            if self._leader_cta_gate(cfg, cfg.producer_signaling_threads):
                resource.pipeline.producer_tail(tail_state)
            elif cutlass.const_expr(emit_ptx_comments):
                self._ptx_comment(f"{resource.name}.drain skipped")
        else:
            resource.pipeline.producer_tail(tail_state)

    def _producer_commit_state_slot(self, resource: MemoryResource) -> int:
        """Return the explicit cursor slot used by this resource's commits."""
        slot = 0
        for step in self._all_steps():
            if (
                step.memory_resource is resource
                and step.schedule_stage is ScheduleStage.ProducerCommit
                and step.state_binding is not None
            ):
                slot = step.state_binding.slot
        return slot

    @cute.jit
    def _interleave_producer_drain(self, resource: MemoryResource, stride: int) -> None:
        """Drain an interleaved (stride > 1) producer's in-flight stages.

        ``producer_tail`` waits a single tail stage, which is wrong for an
        interleaved lane: each lane keeps ``num_stages // stride`` stages in
        flight and the last one was already consumed in the body, so wait out the
        remaining ``num_stages // stride - 1`` empties, stepping the cursor by
        ``stride`` each time (draining the already-consumed final stage again
        would block on a phase that wrapped back).

        Leader-gated when the producer cursor is owned by signalling CTAs alone
        (mirrors :meth:`_producer_tail`): a non-leader neither owns the cursor
        nor is signalled the empty barrier the leader-routed release arms, so it
        must not wait/advance here.  The gate folds to compile-time ``True`` for
        the common per-CTA producer, keeping the drain unconditional.
        """
        cfg = resource.pipeline_config
        assert cfg is not None
        drain_count = cfg.num_stages // stride - 1
        self._ptx_comment(f"{resource.name}.drain interleaved")
        gate = (
            self._leader_cta_gate(cfg, cfg.producer_signaling_threads)
            if cutlass.const_expr(_producer_state_owned_by_signaling(resource))
            else True
        )
        if gate:
            for _ in cutlass.range_constexpr(drain_count):
                resource.pipeline.sync_object_empty.wait(
                    resource.producer_state.index, resource.producer_state.phase
                )
                for _ in cutlass.range_constexpr(stride):
                    resource.producer_state.advance()
        elif cutlass.const_expr(emit_ptx_comments):
            self._ptx_comment(f"{resource.name}.drain skipped")

    def _seed_route_slots(self) -> None:
        """Seed one mailbox slot per read variable and index all consumers.

        A routed value is a mailbox keyed by its **source variable**. A variable
        reassigned by several producers (e.g. a descriptor recomputed once in the
        head and again each loop iteration) is a single slot that every consumer
        reads and every producer overwrites. A consumer that reads the variable
        before its own iteration rewrites it sees the previous iteration's value
        (the paired-MMA "previous V" loop-carry). This keying makes the runtime
        data-flow match each declared ``Step.input_bindings`` entry: each
        destination argument reads its logical variable, whichever producer last
        wrote it.

        Each slot is seeded through :meth:`_store_route_slot` (instrumented)
        *before* any dynamic control flow, so the slot's ``pyir.ref`` is created
        at the function entry block from the source's (literal-backed) default and
        therefore dominates every later store/load -- the property that lets a
        producer inside a ``first_iter`` conditional feed a consumer outside it.

        :attr:`_step_inputs` maps each destination step to the
        ``(argument, source-variable key)`` pairs it reads.
        :attr:`_condition_var_keys` maps each opaque guard's resource/name key
        to the same source-variable mailbox. :attr:`_routed_var_keys` is the set
        of all seeded mailbox keys, so producers write values consumed by work
        steps or guards through one mechanism.
        """
        self.route_slots = {}
        self._step_inputs: dict = {}
        self._condition_var_keys: dict = {}
        self._routed_var_keys: set = set()
        for step in self._all_steps():
            for argument, variable in step.input_bindings.items():
                var_key = id(variable)
                if var_key not in self._routed_var_keys:
                    self._store_route_slot(var_key, _route_source_default(variable))
                    self._routed_var_keys.add(var_key)
                self._step_inputs.setdefault(id(step), []).append((argument, var_key))
        produced_vars: dict = {}
        for step in self._all_steps():
            for var in step.returned_variables:
                produced_vars[(id(step.memory_resource), var.slot_name)] = var
        for guard in self._all_opaque_conditions():
            if guard.resource is None or guard.result_name is None:
                continue
            assert isinstance(guard.resource, MemoryResource)
            key = (id(guard.resource), guard.result_name)
            condition_var = produced_vars.get(key)
            if condition_var is None:
                raise ScheduleError(
                    f"OpaqueCondition names {guard.result_name!r} on "
                    f"{guard.resource.name!r}, but no work step produces it."
                )
            var_key = id(condition_var)
            if var_key not in self._routed_var_keys:
                self._store_route_slot(var_key, _route_source_default(condition_var))
                self._routed_var_keys.add(var_key)
            self._condition_var_keys[key] = var_key
        for node in self._all_nodes():
            if not isinstance(node, WhileTrueLoop):
                continue
            for hook in (node.init, node.advance):
                for var in hook.step.returned_variables:
                    var_key = id(var)
                    if var_key not in self._routed_var_keys:
                        self._store_route_slot(var_key, _route_source_default(var))
                        self._routed_var_keys.add(var_key)

    def _all_steps(self) -> Iterator[Step]:
        """Yield every ``Step`` in the schedule tree, in pre-order.

        ``while_true_loop`` init/advance hook steps are included even though
        they are not children of the loop body.
        """

        def walk(nodes: list[Node]) -> Iterator[Step]:
            for node in nodes:
                if isinstance(node, Step):
                    yield node
                elif isinstance(node, WhileTrueLoop):
                    yield node.init.step
                    yield from walk(node.body)
                    yield node.advance.step
                else:
                    yield from walk(_child_nodes(node))

        yield from walk(self.schedule.body)

    def _all_nodes(self) -> Iterator[Node]:
        """Yield every node (leaves and containers) in the tree, in pre-order."""

        def walk(nodes: list[Node]) -> Iterator[Node]:
            for node in nodes:
                yield node
                yield from walk(_child_nodes(node))

        yield from walk(self.schedule.body)

    #: Work stages dispatched by :meth:`_run_work` via ``getattr(resource, label)``.
    _WORK_STAGES = frozenset(
        {
            ScheduleStage.ConsumerWork,
            ScheduleStage.ProducerWork,
            ScheduleStage.ConsumerAuxWork,
            ScheduleStage.ProducerAuxWork,
        }
    )

    def _reject_generic_work(self) -> None:
        """Reject the generic monolithic work hooks at construction time.

        The walker dispatches work only by the step's ``label``
        (``getattr(resource, step.label)``), which a named ``@consumer_work`` /
        ``@producer_work`` method always carries.  A generic hook call
        (``proxy.consumer_work()`` / ``producer_work()`` and the ``*_aux_work``
        shorthands, i.e. an undecorated base hook) records a work step with
        ``label is None`` and is unsupported. This check raises immediately to
        prevent an opaque ``getattr(resource, None)`` failure later in
        :meth:`_run_work`. Pipeline-op steps also carry ``label is None`` but
        are dispatched by stage, so only work stages are checked.
        """
        for step in self._all_steps():
            if step.label is None and step.schedule_stage in self._WORK_STAGES:
                raise ScheduleError(
                    f"{step.memory_resource.name}: generic "
                    f"{step.schedule_stage.value} is not supported by the "
                    f"tree-walking runtime. Define the work as a named "
                    f"@consumer_work / @producer_work method (auxiliary work via "
                    f"work_attrs=WorkAttr.AUXILIARY) so it dispatches by name."
                )

    #: Legal per-task register budget bounds for ``setmaxnreg`` (inclusive).
    _MIN_NUM_REGISTERS: int = 8
    _MAX_NUM_REGISTERS: int = 256
    #: ``setmaxnreg`` only accepts a register count that is a multiple of this.
    _NUM_REGISTERS_STEP: int = 8

    def _validate_num_registers(self) -> None:
        """Reject a ``num_registers`` outside the ``setmaxnreg`` legal range.

        A per-task register budget must be a multiple of 8 in ``[8, 256]``;
        ``None`` leaves the kernel default.  Raises ScheduleError otherwise.
        """
        n = self.num_registers
        if n is None:
            return
        if not (
            isinstance(n, int)
            and self._MIN_NUM_REGISTERS <= n <= self._MAX_NUM_REGISTERS
            and n % self._NUM_REGISTERS_STEP == 0
        ):
            raise ScheduleError(
                f"Task {self.name!r}: num_registers must be between "
                f"{self._MIN_NUM_REGISTERS} and {self._MAX_NUM_REGISTERS} and "
                f"divisible by {self._NUM_REGISTERS_STEP}, got {n!r}."
            )

    def _validate_run_only_on_cta_id(self) -> None:
        """Validate and normalize the CTA ranks selected by this task.

        ``None`` runs on every CTA.  An integer selects one rank; a ``range``
        or tuple selects multiple ranks.  Ranks must be non-negative integers,
        and ranges must be contiguous and increasing.
        """
        selector = self.run_only_on_cta_id
        if selector is None:
            self._cta_ranks = None
            self._cta_ranks_are_contiguous = False
            return

        ranks: tuple[int, ...]
        if type(selector) is int:
            ranks = (selector,)
        elif isinstance(selector, range):
            if selector.step != 1:
                raise ScheduleError(
                    f"Task {self.name!r}: run_only_on_cta_id range must have "
                    f"step=1, got {selector!r}."
                )
            ranks = tuple(selector)
        elif type(selector) is tuple:
            ranks = selector
        else:
            raise TypeError(
                f"Task {self.name!r}: run_only_on_cta_id must be an int, "
                f"range, tuple of ints, or None, got {type(selector).__name__}."
            )

        if not ranks:
            raise ScheduleError(
                f"Task {self.name!r}: run_only_on_cta_id must select at least "
                "one CTA rank."
            )
        for rank in ranks:
            if type(rank) is not int:
                raise TypeError(
                    f"Task {self.name!r}: run_only_on_cta_id ranks must be "
                    f"ints, got {type(rank).__name__}."
                )
            if rank < 0:
                raise ScheduleError(
                    f"Task {self.name!r}: run_only_on_cta_id ranks must be "
                    f"non-negative, got {rank!r}."
                )

        self._cta_ranks = tuple(sorted(set(ranks)))
        self._cta_ranks_are_contiguous = all(
            right == left + 1
            for left, right in zip(self._cta_ranks, self._cta_ranks[1:])
        )

    def _validate_domain_loops(self) -> None:
        """Validate every ``DomainLoop`` node's unroll, step, and callable bounds."""
        for node in self._all_nodes():
            if isinstance(node, DomainLoop):
                self._validate_domain_loop(node)

    def _validate_domain_loop(self, node: DomainLoop) -> None:
        """Enforce a single ``DomainLoop`` node's construction-time invariants.

        ``unroll`` must be an int or ``None`` (TypeError otherwise); a static
        (Python int) ``step`` must be positive (ScheduleError otherwise); and a
        callable bound must be resolvable as a ``(self, work_tile_coord)`` Task
        method (ScheduleError otherwise).  A callable ``step`` is checked for a
        constant non-positive value once resolved per tile in
        :meth:`_reject_nonpositive_domain_step`, not here.
        """
        if node.unroll is not None and type(node.unroll) is not int:
            raise TypeError(
                f"Task {self.name!r}: domain_loop() unroll must be a "
                f"compile-time int or None, got {type(node.unroll).__name__}."
            )
        if isinstance(node.step, int) and node.step <= 0:
            raise ScheduleError(
                f"Task {self.name!r}: domain_loop() step must be a positive "
                f"int, got {node.step}."
            )
        for name, bound in (
            ("start", node.start),
            ("end", node.end),
            ("step", node.step),
        ):
            if callable(bound):
                self._validate_domain_getter(name, bound)

    def _validate_domain_getter(self, name: str, fn: Any) -> None:
        """Reject a callable ``DomainLoop`` bound the walker cannot resolve per tile.

        The walker resolves a callable bound as ``fn(self, work_tile_coord)``,
        so ``fn`` must be an unbound ``(self, work_tile_coord)`` Task method
        accessed on the class: callable, exposing a Python signature, and taking
        exactly two required positional parameters.  Raises ScheduleError
        otherwise.
        """
        if inspect.ismethod(fn) and fn.__self__ is not None:
            raise ScheduleError(
                f"Task {self.name!r}: domain_loop() {name} callable must be a "
                "Task method accessed on the class (e.g. MyTask.kv_loop_end), "
                "not an instance-bound method."
            )
        try:
            signature = inspect.signature(fn)
        except (TypeError, ValueError) as exc:
            raise ScheduleError(
                f"Task {self.name!r}: domain_loop() {name} callable must expose "
                "a Python signature."
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
                f"Task {self.name!r}: domain_loop() {name} callable must accept "
                "exactly two required positional parameters: "
                "(self, work_tile_coord)."
            )

    def _all_opaque_conditions(self) -> Iterator[OpaqueCondition]:
        """Yield every ``OpaqueCondition`` guard on a ``ConditionalBlock`` in the tree."""

        def walk(nodes: list[Node]) -> Iterator[OpaqueCondition]:
            for node in nodes:
                if isinstance(node, ConditionalBlock):
                    yield from (
                        leaf
                        for leaf in iter_leaves(node.condition)
                        if isinstance(leaf, OpaqueCondition)
                    )
                    yield from walk(node.body)
                elif not isinstance(node, Step):
                    yield from walk(_child_nodes(node))

        yield from walk(self.schedule.body)

    @cute.jit
    def is_selected(self) -> bool:
        """Return ``True`` if the current warp falls within this task's range.

        When ``run_only_on_cta_id`` is set, also gates on the CTA rank in the
        cluster so the whole body runs only on the selected CTA ranks.
        """
        warp_id = cute.arch.warp_idx()
        selected = warp_id >= self.warp_start and warp_id < self.warp_end
        if cutlass.const_expr(self._cta_ranks is not None):
            assert self._cta_ranks is not None
            cta_rank_in_cluster = cute.arch.make_warp_uniform(
                cute.arch.block_idx_in_cluster()
            )
            if cutlass.const_expr(len(self._cta_ranks) == 1):
                cta_selected = cta_rank_in_cluster == self._cta_ranks[0]
            elif cutlass.const_expr(self._cta_ranks_are_contiguous):
                cta_selected = (
                    cta_rank_in_cluster >= self._cta_ranks[0]
                    and cta_rank_in_cluster <= self._cta_ranks[-1]
                )
            else:
                cta_selected = cta_rank_in_cluster == self._cta_ranks[0]
                for cta_rank in self._cta_ranks[1:]:
                    cta_selected = cta_selected or cta_rank_in_cluster == cta_rank
            selected = selected and cta_selected
        return selected

    def _set_max_register(self) -> None:
        """Emit a ``setmaxregister`` for this task's register budget.

        If using hoisted decrease:
          ``INCREASE`` when ``num_registers`` exceeds ``register_release_floor``
        Else:
          ``INCREASE`` when ``num_registers`` exceeds ``default_num_registers``,
          ``DECREASE`` otherwise.
        No-op when ``num_registers`` is ``None``.
        """
        for num_registers, action in self._register_requests():
            prims.setmaxregister(num_registers, action)

    def _register_requests(self) -> list[tuple[int, prims.SetMaxRegisterAction]]:
        """Resolve the ``setmaxregister`` requests this task emits, in order."""
        if self.num_registers is None:
            return []
        floor = self.register_release_floor
        if floor is not None:
            if self.num_registers > floor:
                return [(self.num_registers, prims.SetMaxRegisterAction.INCREASE)]
            return []
        if self.num_registers > self.default_num_registers:
            return [(self.num_registers, prims.SetMaxRegisterAction.INCREASE)]
        return [(self.num_registers, prims.SetMaxRegisterAction.DECREASE)]

    @cute.jit
    def _debug_print_stage_info(
        self, step: Step, ctx: _WalkContext, stage_name: str
    ) -> None:
        """Emit a runtime debug print for elected threads in the first two CTAs."""
        if cutlass.const_expr(self.debug_print):
            bx, by, bz = cute.arch.block_idx()
            tx, ty, tz = cute.arch.thread_idx()
            assert ctx.work_tile is not None
            wx, wy, wz = ctx.work_tile.tile_idx
            loop = ctx.loop
            loop_offset: Any = -1
            if cutlass.const_expr(loop is not None):
                assert loop is not None
                loop_offset = loop.index
            if prims.elect_sync() and bx < 2 and by == 0 and bz == 0:
                prims.print_runtime(
                    "["
                    + self.name
                    + " : "
                    + step.memory_resource.name
                    + " | "
                    + stage_name
                    + "], LoopIdx = {},"
                    + " T(x,y,z) = ({},{},{}),"
                    + " CTA(x,y,z) = ({},{},{}),"
                    + " WorkTile(x,y,z) = ({},{},{})\n",
                    loop_offset,
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

    def run_nodes(self, nodes: list[Node], ctx: _WalkContext) -> object:
        """Walk an ordered list of sibling nodes in execution order.

        ``ctx`` is the threaded :class:`_WalkContext` forwarded so nested
        first/last-iter conditionals, skippable regions, and work steps can
        build their predicates and stage info.

        Returns the ``WorkTileInfo`` produced by a queue-advance child step
        (``get_and_advance_work_tile``), which :meth:`_run_work_tile_loop` reads
        as the next ``scf.while`` iter-arg, or ``None`` when no child advances
        the queue.  At most one child at this level advances (the queue's
        per-tile bookkeeping is a single loop-level step).

        A ``WorkTileLoop`` child instead yields the loop's final (invalid) tile;
        it is not returned but folded into ``ctx`` so any following siblings (the
        post-work-loop entries) run with the final tile. Only the loop advance -- never the
        loop's own final tile -- carries the queue advance the parent reads.
        """
        advanced_tile = None
        for node in nodes:
            tile = self.run_node(node, ctx)
            if tile is not None:
                if cutlass.const_expr(isinstance(node, WorkTileLoop)):
                    ctx = replace(ctx, work_tile=tile)
                else:
                    advanced_tile = tile
        return advanced_tile

    def run_node(self, node: Node, ctx: _WalkContext) -> object:
        """Lower one schedule-tree node to traceable instructions.

        ``DomainLoop`` becomes an ``scf.for``; ``FirstIter`` / ``LastIter``
        become runtime branches on the enclosing loop's induction value;
        ``Skippable`` a runtime branch on the work-tile loop's skip predicate;
        a ``Step`` emits a PTX comment (and, for a standard pipeline stage, its
        real op).  The threaded ``ctx`` carries the loop induction context and
        skip flag those branches need.

        Returns the queue-advance tile from a ``Step`` (see :meth:`run_nodes`),
        or the ``WorkTileLoop``'s final (invalid) tile so post-loop siblings can
        adopt it; ``None`` for the other container nodes (they carry no tile).

        Raises
        ------
        TypeError
            If ``node`` is not one of the known :data:`~.schedule_builder.Node`
            kinds -- a guard against an unhandled tree shape.
        """
        match node:
            case Step():
                return self._run_step(node, ctx)
            case StateAdvance():
                self._run_state_advance(node)
            case WorkTileLoop():
                return self._run_work_tile_loop(node, ctx)
            case DomainLoop():
                self._run_domain_loop(node, ctx)
            case WhileTrueLoop():
                self._run_while_true_loop(node, ctx)
            case LoopBreak():
                pass
            case ConditionalBlock():
                self._run_conditional_block(node, ctx)
            case _:
                raise TypeError(f"Unhandled schedule node: {type(node).__name__}")
        return None

    @cute.jit
    def _run_state_advance(self, node: StateAdvance) -> None:
        """Lower the sole cursor-mutation IR node through resource attributes."""
        state = node.state
        resource = state.resource
        cfg = _require_pipeline_config(resource)
        stride = (
            cfg.producer_commit_interleave_stride
            if state.role is StateRole.Producer
            else cfg.consumer_release_interleave_stride
        )
        self._ptx_comment(f"#{node.unique_id} {state}.advance({node.count})")
        if cutlass.const_expr(
            isinstance(resource, PipelineGroup)
            and state.role is StateRole.Producer
            and resource.mode == PipelineGroupMode.Fork
        ):
            assert isinstance(resource, PipelineGroup)
            for member in resource.members:
                for _ in cutlass.range_constexpr(stride * node.count):
                    if cutlass.const_expr(state.slot == 0):
                        member.producer_state.advance()
                    else:
                        member.producer_commit_state.advance()
            return
        gate = (
            self._advance_gate(resource, self._producer_leader_gate(cfg))
            if state.role is StateRole.Producer
            else self._leader_cta_gate(cfg, cfg.consumer_signaling_threads)
        )
        if gate:
            for _ in cutlass.range_constexpr(stride * node.count):
                if cutlass.const_expr(state.role is StateRole.Producer):
                    if cutlass.const_expr(state.slot == 0):
                        resource.producer_state.advance()
                    else:
                        resource.producer_commit_state.advance()
                else:
                    src = resource.state_src
                    if cutlass.const_expr(state.slot == 0):
                        src.consumer_state.advance()
                    else:
                        src.consumer_release_state.advance()

    # -- per-node lowerings --------------------------------------------------

    @emits_ir("step", node=lambda self, step, ctx: step)
    def _run_step(self, step: Step, ctx: _WalkContext) -> object:
        """Lower one step (see :meth:`_run_step_impl`).

        Everything this step traces is one construct region, so an
        observer can attribute the emitted ops to this step by containment.
        """
        return self._run_step_impl(step, ctx)

    def _run_step_impl(self, step: Step, ctx: _WalkContext) -> object:
        """Lower one step: a pipeline op or a work call.

        Dispatches: a standard pipeline stage (try-acquire / acquire / commit /
        try-wait / wait / release) to its real lowering (which emits its own
        step-scoped ``#<id> resource.method`` PTX comment); a work stage --
        ConsumerWork / ProducerWork, or the auxiliary ConsumerAuxWork /
        ProducerAuxWork (setup / helper work with no surrounding barrier op) --
        to the work method.

        The work-tile loop's queue advance (the queue's ``ConsumerWork``) is
        carved out to :meth:`_run_queue_advance`: it produces the loop's next
        ``scf.while`` iter-arg rather than structural work.
        """
        self._debug_print_stage_info(
            step,
            ctx,
            "Before" + step.schedule_stage.value,
        )
        if cutlass.const_expr(self._is_queue_advance_step(step)):
            advanced_tile = self._run_queue_advance(step, ctx)
            self._debug_print_stage_info(
                step,
                ctx,
                "After" + step.schedule_stage.value,
            )
            return advanced_tile
        stage = step.schedule_stage
        # Wrap the step's lowering in an IKET range when profiling is enabled
        # (default off -> both calls fold away, leaving the dispatch unchanged).
        token = self._start_profile_entry(step.memory_resource, stage)
        try:
            if cutlass.const_expr(stage is ScheduleStage.ProducerTryAcquire):
                self._producer_try_acquire(step)
            elif cutlass.const_expr(stage is ScheduleStage.ProducerAcquire):
                self._producer_acquire(step)
            elif cutlass.const_expr(stage is ScheduleStage.ProducerCommit):
                self._producer_commit(step)
            elif cutlass.const_expr(stage is ScheduleStage.ConsumerTryWait):
                self._consumer_try_wait(step)
            elif cutlass.const_expr(stage is ScheduleStage.ConsumerWait):
                self._consumer_wait(step)
            elif cutlass.const_expr(stage is ScheduleStage.ConsumerRelease):
                self._consumer_release(step)
            elif cutlass.const_expr(
                stage is ScheduleStage.ConsumerWork
                or stage is ScheduleStage.ProducerWork
                or stage is ScheduleStage.ConsumerAuxWork
                or stage is ScheduleStage.ProducerAuxWork
            ):
                # Auxiliary work (helper-variable / setup work with no pipeline
                # barrier op) runs identically to regular work -- it just carries
                # no acquire/commit/wait/release around it.
                #
                # This arm is chosen at trace time, so `constexpr_loop_scope`
                # tells the DSL that what the work body writes is not carried
                # across runtime control flow.
                with constexpr_loop_scope():
                    self._run_work(step, ctx)
            else:
                # No fallthrough: an unhandled stage must fail loudly (a silent
                # no-op would drop a real pipeline op).
                raise ScheduleError(f"unhandled schedule stage: {stage}")
        finally:
            self._end_profile_entry(step.memory_resource, stage, token)
        self._debug_print_stage_info(
            step,
            ctx,
            "After" + stage.value,
        )
        return None

    def _should_profile_entry(
        self, resource: MemoryResource, stage: ScheduleStage
    ) -> bool:
        """True when this step should emit an IKET range.

        Requires profiling enabled and (when the stage / resource filters are
        set) the step's stage and resource name to be in them; ``None`` filters
        match everything.
        """
        return (
            self.iket_enable_profiling
            and (
                self.iket_profiling_stages is None
                or stage in self.iket_profiling_stages
            )
            and (
                self.iket_profiling_resources is None
                or resource.name in self.iket_profiling_resources
            )
        )

    def _start_profile_entry(
        self, resource: MemoryResource, stage: ScheduleStage
    ) -> Any:
        """Open a ``<resource>_<stage>`` IKET range for a profiled step, else None."""
        if cutlass.const_expr(self._should_profile_entry(resource, stage)):
            return iket.range_start(resource.name + "_" + stage.value)
        return None

    def _end_profile_entry(
        self, resource: MemoryResource, stage: ScheduleStage, token: Any
    ) -> None:
        """Close the IKET range opened by :meth:`_start_profile_entry`, if any."""
        if cutlass.const_expr(self._should_profile_entry(resource, stage)):
            assert token is not None
            iket.range_end(token)

    @staticmethod
    def _is_queue_advance_step(step: Step) -> bool:
        """True for the work-tile loop's queue-advance step.

        A ``WorkQueue``'s ``ConsumerWork`` is its ``get_and_advance_work_tile``
        callback -- the sole per-tile advance, whose returned ``WorkTileInfo``
        becomes the enclosing loop's next ``scf.while`` iter-arg
        (:meth:`_run_work_tile_loop`).  It is loop bookkeeping and is the only
        advance.
        """
        return is_queue_advance_step(step)

    def _run_queue_advance(self, step: Step, ctx: _WalkContext) -> object:
        """Advance the work queue and return the next tile for the loop.

        Runs the queue's advance callback and returns its ``WorkTileInfo``,
        which propagates up through :meth:`run_node` / :meth:`run_nodes` to
        :meth:`_run_work_tile_loop`, where it becomes the next ``scf.while``
        iter-arg.  The tile feeds the loop carry (a local value-tree) so the
        step's return contract / routing is skipped.

        The raw ``_get_and_advance_work_tile_impl`` is called directly rather
        than the ``@consumer_work``-wrapped ``get_and_advance_work_tile``: the
        walker carries the next tile as the ``scf.while`` iter-arg, so it takes
        the plain return value and skips the wrapper's routed-return handling.
        """
        resource = step.memory_resource
        assert isinstance(resource, WorkQueue)
        self._step_comment(step, f"{resource.name}.{step.label}")
        stage_info = self._create_stage_info(step, ctx)
        return resource._get_and_advance_work_tile_impl(stage_info)

    @cute.jit
    def _store_route_slot(
        self, key: cutlass.Constexpr[object], value: cutlass.Constexpr[object]
    ) -> None:
        """Store a routed value through the AST-instrumented dict-subscript path.

        The ``@cute.jit`` body makes ``route_slots[key] = value`` an instrumented
        ``pyir_assign``: the slot's ``pyir.ref`` (created dominating at the entry
        block when seeded from the default) receives a ``pyir.store``. An
        instrumented write ensures a value produced inside a conditional/loop
        region receives a dominating SSA def, avoiding a never-stored poison ref
        at a downstream direct use.
        """
        route_slots = object.__getattribute__(self, "route_slots")
        route_slots[key] = value

    @cute.jit
    def _load_route_slot(self, key: cutlass.Constexpr[object]) -> object:
        """Load a routed value through the AST-instrumented dict-subscript path.

        The ``@cute.jit`` body makes ``route_slots[key]`` an instrumented
        ``pyir.load`` from the slot's entry ``pyir.ref`` at the consumer's
        insertion point, so the loaded SSA dominates the use even when the
        producing store ran inside a conditional (e.g. a ``first_iter`` block).
        """
        route_slots = object.__getattribute__(self, "route_slots")
        return route_slots[key]

    def _run_work(self, step: Step, ctx: _WalkContext) -> None:
        """Call a producer/consumer work method and route its outputs.

        Reads this step's routed inputs from their source variables' mailboxes
        (``_step_inputs`` gives the ``(argument, source-variable key)`` pairs)
        via :meth:`_load_route_slot` -- an instrumented dict-subscript load, so
        each value dominates this consumer even when the producer wrote it inside
        a conditional region -- then calls
        ``resource.<label>(stage_info, **routed, **constexpr)`` and writes the
        return values back to their mailboxes.  The ``resources`` thin
        wrapper forwards args straight to the user fn, so the call is direct.
        """
        resource = step.memory_resource
        assert step.label is not None
        method = getattr(resource, step.label)
        self._step_comment(step, f"{resource.name}.{step.label}")
        step_inputs = object.__getattribute__(self, "_step_inputs")
        routed: dict = {}
        for argument, var_key in step_inputs.get(id(step), ()):
            routed[argument] = self._load_route_slot(var_key)
        stage_info = self._create_stage_info(step, ctx)
        ret = method(stage_info, **routed, **step.constexpr_kwargs)
        self._route_outputs(step, ret)

    def _route_outputs(self, step: Step, ret: Any) -> None:
        """Enforce the return contract and write this step's routed outputs.

        The return is normalized (``None`` -> ``()``, a non-tuple -> a 1-tuple,
        a tuple as-is; a ``dict`` is rejected) and its length must match
        ``step.returned_variables`` (order-preserving) before the zip -- this
        catches a ``returns=``-less method that returned a value.  Each produced
        value is then checked against its declared ``TaskLocalVariable.dtype``
        (``_validate_consumer_produced_value_dtype``), so a wrong-typed return fails at the
        producing step rather than as an opaque error inside a later consumer.
        Each produced value is then written into its source variable's mailbox
        (keyed by ``id(variable)``), so a variable reassigned across producers
        stays coherent for all its readers; a produced output with no consumer
        (not in :attr:`_routed_var_keys`) is dropped.
        """
        if cutlass.const_expr(isinstance(ret, dict)):
            raise ScheduleError(
                f"work step '{step.label}' returned a dict; a work method must "
                "return its outputs positionally (bare value, tuple, or None)."
            )
        if cutlass.const_expr(ret is None):
            values: tuple = ()
        elif cutlass.const_expr(isinstance(ret, tuple)):
            values = ret
        else:
            values = (ret,)
        if cutlass.const_expr(len(values) != len(step.returned_variables)):
            raise ScheduleError(
                f"work step '{step.label}' returned {len(values)} value(s) but "
                f"declares {len(step.returned_variables)} routed output(s)."
            )
        produced = dict(zip(step.returned_variables, values))
        assert step.label is not None
        for var, value in produced.items():
            _validate_consumer_produced_value_dtype(step.label, var, value)
        # Write each produced value into its source variable's mailbox (keyed by
        # id(variable)).  A variable reassigned by multiple producers (head +
        # loop) is one slot every consumer reads, so a later producer refreshes
        # what a consumer reads before rewriting it itself -- the descriptor
        # loop-carry the paired-MMA "previous V" PV depends on.
        routed_var_keys = object.__getattribute__(self, "_routed_var_keys")
        for var, value in produced.items():
            if cutlass.const_expr(id(var) in routed_var_keys):
                self._store_route_slot(id(var), value)

    def _create_stage_info(self, step: Step, ctx: _WalkContext) -> StageInfo:
        """Build the ``StageInfo`` handed to a work method as its first arg.

        The loop offset/bounds come from the enclosing domain loop's resolved
        induction state (``ctx.loop``), or from a ``while_true_loop`` cursor
        (``loop.index`` is the init/advance hook result; bounds are
        ``LOOP_STATE_UNAVAILABLE``). Outside any such loop they are
        ``None`` (``LOOP_STATE_UNAVAILABLE``): peeled head/tail work has no
        loop induction state. ``work_tile`` is the current tile threaded through
        the walk.

        For a step on a pipelined resource, ``stage_idx`` is the current
        pipeline cursor (``producer_state`` for a producer stage, else
        ``consumer_state``) and ``barrier`` is that stage's mbarrier (the one a
        producer signals into / a consumer waits on).  For a resource with no
        pipeline both stay ``None``.
        """
        loop = ctx.loop
        if loop is None:
            loop_offset: Any = LOOP_STATE_UNAVAILABLE
            loop_start: Any = LOOP_STATE_UNAVAILABLE
            loop_end: Any = LOOP_STATE_UNAVAILABLE
            loop_step: Any = LOOP_STATE_UNAVAILABLE
        else:
            loop_offset = loop.index
            loop_start = loop.start
            loop_end = loop.end
            loop_step = loop.step
        work_tile = ctx.work_tile
        stage_idx, barrier = _stage_cursor_and_barrier(
            step,
            use_release_state=self._uses_consumer_release_state(step),
            follows_acquire=id(step) in self._producer_follow_acquire_steps,
            use_explicit_binding=step.state_binding is not None,
        )
        return StageInfo(
            loop_offset=loop_offset,
            loop_start=loop_start,
            loop_end=loop_end,
            loop_step=loop_step,
            stage_idx=stage_idx,
            label=step.label,
            barrier=barrier,
            work_tile=work_tile,
            num_active_stages=0,
            context=self._resource_context,
        )

    def _uses_consumer_release_state(self, step: Step) -> bool:
        """True when ``StageInfo`` follows a split consumer release cursor."""
        resource = step.memory_resource
        cfg = resource.pipeline_config
        return (
            step.schedule_stage is ScheduleStage.ConsumerWork
            and cfg is not None
            and cfg.advance_on_wait
            and not self._has_consumer_wait(resource)
        )

    def _has_consumer_wait(self, resource: MemoryResource) -> bool:
        """True when this schedule contains ``ConsumerWait`` on ``resource``."""
        return any(
            step.memory_resource is resource
            and step.schedule_stage is ScheduleStage.ConsumerWait
            for step in self._all_steps()
        )

    #: Stages each PipelineGroup mode collapses onto its shared barrier and must
    #: therefore be emitted on the group.
    _GROUP_LEVEL_STAGES = {
        PipelineGroupMode.Merge: (ScheduleStage.ConsumerRelease,),
        PipelineGroupMode.Fork: (ScheduleStage.ProducerCommit,),
        PipelineGroupMode.FusedMerge: (
            ScheduleStage.ConsumerTryWait,
            ScheduleStage.ConsumerWait,
            ScheduleStage.ConsumerRelease,
        ),
    }

    def _validate_group_stage_placement(self) -> None:
        """Reject a PipelineGroup barrier op emitted at the wrong level.

        Certain stages collapse onto a group's shared barrier and fire once, so
        they must target the group, while every other op targets a member:

          * ``Merge``      -> ``ConsumerRelease`` (shared empty)
          * ``Fork``       -> ``ProducerCommit``  (shared full)
          * ``FusedMerge`` -> ``ConsumerTryWait`` / ``ConsumerWait`` /
            ``ConsumerRelease`` (shared full + shared empty)

        A group-level step whose stage is excluded from its mode's set, or a member-level
        step whose stage belongs at the group level, is a construction error.
        Rejecting this prevents the walker from firing a shared barrier from an uncoordinated
        call site (shared-cursor corruption / deadlock) or dereferencing the group's
        intentionally-``None`` ``pipeline`` (an opaque ``AttributeError`` deep in
        the trace).
        """
        for step in self._all_steps():
            resource = step.memory_resource
            stage = step.schedule_stage
            if isinstance(resource, PipelineGroup):
                allowed = Task._GROUP_LEVEL_STAGES[resource.mode]
                if stage not in allowed:
                    accepted = ", ".join(s.name for s in allowed)
                    raise ScheduleError(
                        f"{resource.mode.value} group {resource.name!r} only "
                        f"accepts {accepted} at the group level, got "
                        f"{stage.name}; emit member-level ops on the member."
                    )
            else:
                group = resource.pipeline_group
                if group is not None and stage in Task._GROUP_LEVEL_STAGES[group.mode]:
                    raise ScheduleError(
                        f"{group.mode.value} group {group.name!r}: {stage.name} "
                        f"must be emitted on the group, not member "
                        f"{resource.name!r}."
                    )

    def _make_producer_follow_acquire_steps(self) -> frozenset:
        """Return ids of producer work steps that use the acquire cursor."""
        acquired: set[int] = set()
        follow: set[int] = set()
        for step in self._all_steps():
            cfg = step.memory_resource.pipeline_config
            if cfg is None or not cfg.advance_on_acquire:
                continue
            if step.schedule_stage is ScheduleStage.ProducerAcquire:
                acquired.add(id(step.memory_resource))
            elif (
                step.schedule_stage is ScheduleStage.ProducerWork
                and id(step.memory_resource) in acquired
            ):
                follow.add(id(step))
        return frozenset(follow)

    def _has_interleaved_pipeline(self) -> bool:
        """Python-time check: any of this task's resources use strided state.

        Read by ``TaskManager._run_impl`` to decide interleaved-lane init.
        Returns ``True`` when any resource's pipeline uses a strided
        (interleaved) state.
        """
        return any(
            r.pipeline_config is not None and r.pipeline_config.has_interleaved_stride
            for r in self.resources
        )

    # -- CTA-leader signaling gates ----------------------------------------
    #
    # A cluster pipeline may restrict a barrier op to the leader CTA of each
    # V-group (``cta_layout_vmnk[0]`` CTAs).  Each gate returns a compile-time
    # ``True`` when the whole task/CTA participates (single-CTA task, or no
    # CtaLeader policy), else a runtime Boolean that is true only on the leader
    # CTA.  The state cursor always advances; only the barrier op is gated.

    def _runs_on_single_cta(self) -> bool:
        """True when the task body is pinned to one CTA rank (no cluster gate)."""
        return self._cta_ranks is not None and len(self._cta_ranks) == 1

    def _leader_cta_gate(self, cfg: PipelineConfig, signaling: Any) -> Any:
        """Predicate for 'this CTA performs the barrier op' under ``signaling``.

        ``True`` (compile-time) unless ``signaling`` restricts to the CTA leader
        and the task spans a cluster; then it is the runtime test
        ``cta_rank_in_cluster % v_size == 0`` selecting each V-group's leader.  A
        A task restricted to one rank by ``run_only_on_cta_id`` is the only CTA
        it runs on, so it always returns ``True``.  The single-rank/signaling
        consistency is validated only on the consumer-wait side by
        :meth:`_check_leader_cta_signaling`; producer or release ops bypass gate
        validation.
        """
        if cutlass.const_expr(
            not signaling.has_cta_leader() or self._runs_on_single_cta()
        ):
            return True
        rank = cute.arch.make_warp_uniform(cute.arch.block_idx_in_cluster())
        return rank % _cta_v_size(cfg) == 0

    def _check_leader_cta_signaling(
        self, resource: MemoryResource, signaling: Any
    ) -> None:
        """Reject a single-rank task whose consumer wait is not CtaLeader.

        A single-rank task skips the cluster gate
        (:meth:`_leader_cta_gate` returns ``True``), so its consumer wait must
        already restrict to the leader or it would wait on the wrong CTA's
        barrier. Applied only to the consumer-wait side. A pipeline whose
        consumers may mix
        CTA scopes (``cfg.consumer_pin_signaling_exempt``) is exempt.
        """
        if cutlass.const_expr(
            self._runs_on_single_cta() and not signaling.has_cta_leader()
        ):
            cfg = resource.pipeline_config
            if cutlass.const_expr(
                cfg is not None and cfg.consumer_pin_signaling_exempt
            ):
                return
            raise ValueError(
                f"Task {self.name!r}: run_only_on_cta_id={self.run_only_on_cta_id} "
                f"but {resource.name!r} consumer-wait signaling={signaling}; "
                f"expected CtaLeader."
            )

    def _advance_gate(self, resource: MemoryResource, gate: Any) -> Any:
        """Predicate for 'this CTA advances the producer cursor'.

        ``True`` (compile-time) for the common case when every CTA runs
        producer work and owns its cursor.  When the producer cursor is owned by
        the leader alone -- either a signalling-CTA-owned barrier resource or a
        single cluster-wide issuer (``producer_signals_on_cluster_leader_only``,
        e.g. CLC fetch) -- non-leaders bypass the advance, so the advance reuses
        the leader ``gate`` computed for the barrier op.
        """
        cfg = resource.pipeline_config
        if cutlass.const_expr(
            _producer_state_owned_by_signaling(resource)
            or (cfg is not None and cfg.producer_signals_on_cluster_leader_only)
        ):
            return gate
        return True

    def _producer_leader_gate(self, cfg: PipelineConfig) -> Any:
        """Predicate for 'this CTA performs the producer barrier op'.

        A single cluster-wide issuer (``cfg.producer_signals_on_cluster_leader_only``,
        e.g. CLC fetch) gates to the absolute cluster leader
        (``block_idx_in_cluster() == 0``); every other pipeline uses the V-group
        leader gate. A CTA-pinned task runs on one CTA, so it is always its own
        leader and the gate is a compile-time ``True``.
        """
        if cutlass.const_expr(
            cfg.producer_signals_on_cluster_leader_only
            and not self._runs_on_single_cta()
        ):
            rank = cute.arch.make_warp_uniform(cute.arch.block_idx_in_cluster())
            return rank == 0
        return self._leader_cta_gate(cfg, cfg.producer_signaling_threads)

    def _producer_acquire_gate(self, cfg: PipelineConfig) -> Any:
        """Gate for a producer acquire / try-acquire empty-barrier wait.

        Ungated (every producer CTA runs the empty wait) when the pipeline arms
        the full-barrier arrive internally -- ``cfg.acquire_waits_all_ctas``, a
        capability the pipeline kind implies (TmaUmma / TaskWarpLeader TMA);
        otherwise the producer leader gate applies.
        """
        if cutlass.const_expr(cfg.acquire_waits_all_ctas):
            return True
        return self._producer_leader_gate(cfg)

    # NOTE: a pipeline-state cursor is only threaded correctly when it is
    # mutated via its attribute path on the resource (``resource.producer_state
    # .advance()``).  Mutating it through a local/parameter alias (e.g. a helper
    # that advances a passed-in ``state`` arg) bypasses the ``self``-leaf state
    # threading, dropping the advance and hanging the pipeline.  A strided
    # (interleave) advance is therefore inlined at each site as ``N`` unit
    # advances over ``cutlass.range_constexpr`` (compile-time unrolled;
    # ``stride == 1`` is the single advance the common path always emitted) --
    # ``N`` unit advances reach the same index / phase / count as one stride-``N``
    # step while keeping the attribute-path mutation.

    @cute.jit
    def _producer_try_acquire(self, step: Step) -> None:
        """Non-blocking probe for a free buffer; store the token for acquire.

        Records ``producer_try_acquire``'s token in the resource so the
        following ``ProducerAcquire`` skips the empty wait when the buffer was
        already free.  The token is one-shot: that acquire clears it after use.
        Gated to the leader CTA under CtaLeader signaling; leaves the producer
        cursor unadvanced.
        """
        resource = step.memory_resource
        if cutlass.const_expr(resource.pipeline_config is None):
            self._step_comment(
                step, f"{resource.name}.producer_try_acquire no pipeline"
            )
            return
        cfg = _require_pipeline_config(resource)
        if cutlass.const_expr(not cfg.supports_try_probe_ops):
            self._step_comment(
                step, f"{resource.name}.producer_try_acquire no try-probe"
            )
            return
        gate = self._producer_acquire_gate(cfg)
        if gate:
            self._step_comment(step, f"{resource.name}.producer_try_acquire probe")
            resource.store_producer_status(
                resource.pipeline.producer_try_acquire(_runtime_pipeline_state(step))
            )
        elif cutlass.const_expr(emit_ptx_comments):
            self._step_comment(step, f"{resource.name}.producer_try_acquire skipped")

    @cute.jit
    def _producer_acquire(self, step: Step) -> None:
        """Block until a free buffer stage is available (producer empty wait).

        Passes the resource's stored producer status: a preceding
        ``ProducerTryAcquire`` short-circuits the wait when it already found the
        buffer free.  This operation then clears the one-shot status, so a later
        acquire without its own probe performs a full wait.  The empty wait is
        gated to the leader CTA under CtaLeader signaling.  Under
        ``advance_on_acquire`` the acquire cursor (``producer_state``) advances
        here, leading the lagging commit cursor.

        A Fork ``PipelineGroup`` secondary member (any member past the first)
        only waits its own per-member empty barrier: the shared full barrier was
        already armed by the primary member's acquire, and the group-level commit
        advances every member's cursor in lockstep.
        """
        resource = step.memory_resource
        if cutlass.const_expr(resource.pipeline_config is None):
            self._step_comment(step, f"{resource.name}.producer_acquire no pipeline")
            return
        cfg = _require_pipeline_config(resource)
        if cutlass.const_expr(_is_fork_secondary(resource)):
            if resource.load_producer_status() == 0:
                self._step_comment(
                    step, f"{resource.name}.producer_acquire wait member"
                )
                resource.pipeline.sync_object_empty.wait(
                    _runtime_pipeline_state(step).index,
                    _runtime_pipeline_state(step).phase,
                )
            elif cutlass.const_expr(emit_ptx_comments):
                self._step_comment(
                    step, f"{resource.name}.producer_acquire member ready"
                )
        else:
            gate = self._producer_acquire_gate(cfg)
            if gate:
                self._step_comment(step, f"{resource.name}.producer_acquire wait")
                resource.pipeline.producer_acquire(
                    _runtime_pipeline_state(step),
                    resource.load_producer_status(),
                )
            elif cutlass.const_expr(emit_ptx_comments):
                self._step_comment(step, f"{resource.name}.producer_acquire skipped")
        if cutlass.const_expr(cfg.supports_try_probe_ops):
            # Clear at the step's top level rather than inside a signaling gate:
            # the token describes only the stage/phase consumed above.
            resource.clear_producer_status()

    @cute.jit
    def _producer_commit(self, step: Step) -> None:
        """Signal the stage full and advance the producer commit cursor.

        The commit arrive is gated to the leader CTA under CtaLeader signaling.
        Under ``advance_on_acquire`` the lagging commit cursor
        (``producer_commit_state``) advances here while the acquire cursor ran
        ahead at :meth:`_producer_acquire`; otherwise the single
        ``producer_state`` cursor advances.  The ``producer_commit`` call is
        uniform across pipeline types -- for ``ClcFetchAsync`` the pipeline
        overrides it as a no-op (the fetch's ``issue_clc_query`` already armed the
        full barrier), so no pipeline-type branch is needed here; the cursor
        still advances.

        A Fork ``PipelineGroup`` commit (the resource *is* the group) fires once
        on the primary member's pipeline (the shared full barrier) and advances
        every member's producer cursor in lockstep.
        """
        resource = step.memory_resource
        if cutlass.const_expr(resource.pipeline_config is None):
            self._step_comment(step, f"{resource.name}.producer_commit no pipeline")
            return
        cfg = _require_pipeline_config(resource)
        gate = self._producer_leader_gate(cfg)
        if cutlass.const_expr(
            isinstance(resource, PipelineGroup)
            and resource.mode == PipelineGroupMode.Fork
        ):
            assert isinstance(resource, PipelineGroup)
            primary = resource.members[0]
            if gate:
                self._step_comment(step, f"{resource.name}.producer_commit shared")
                primary.pipeline.producer_commit(_runtime_pipeline_state(step))
            elif cutlass.const_expr(emit_ptx_comments):
                self._step_comment(step, f"{resource.name}.producer_commit skipped")
        else:
            if gate:
                self._step_comment(step, f"{resource.name}.producer_commit signal")
                resource.pipeline.producer_commit(_runtime_pipeline_state(step))
            elif cutlass.const_expr(emit_ptx_comments):
                self._step_comment(step, f"{resource.name}.producer_commit skipped")

    @cute.jit
    def _consumer_try_wait(self, step: Step) -> None:
        """Non-blocking probe for data readiness; store the token for wait.

        Records ``consumer_try_wait``'s token in the resource so the following
        ``ConsumerWait`` skips the full wait when data was already ready.  The
        token is one-shot: that wait clears it after use.  Gated to the leader
        CTA under CtaLeader wait signaling.
        """
        resource = step.memory_resource
        if cutlass.const_expr(resource.pipeline_config is None):
            self._step_comment(step, f"{resource.name}.consumer_try_wait no pipeline")
            return
        cfg = _require_pipeline_config(resource)
        if cutlass.const_expr(not cfg.supports_try_probe_ops):
            self._step_comment(step, f"{resource.name}.consumer_try_wait no try-probe")
            return
        self._check_leader_cta_signaling(resource, _consumer_wait_signaling(cfg))
        pipe = (
            cast(PipelineGroup, resource).group_pipeline
            if cutlass.const_expr(isinstance(resource, PipelineGroup))
            else resource.pipeline
        )
        action = (
            "shared probe"
            if cutlass.const_expr(isinstance(resource, PipelineGroup))
            else "probe"
        )
        gate = self._leader_cta_gate(cfg, _consumer_wait_signaling(cfg))
        if gate:
            self._step_comment(step, f"{resource.name}.consumer_try_wait {action}")
            resource.store_consumer_status(
                pipe.consumer_try_wait(_runtime_pipeline_state(step))
            )
        elif cutlass.const_expr(emit_ptx_comments):
            self._step_comment(step, f"{resource.name}.consumer_try_wait skipped")

    @cute.jit
    def _consumer_wait(self, step: Step) -> None:
        """Block until the current stage is full (consumer full wait).

        Passes the resource's stored consumer status (a preceding per-member
        ``ConsumerTryWait`` short-circuits the wait), then clears the one-shot
        status so a later wait without its own probe performs a full wait.  The
        wait is gated to the leader CTA under CtaLeader wait signaling.  Cursor
        motion lives on the following ``StateAdvance`` node; work that follows
        the wait reads the claimed stage as the wait cursor's previous index.

        The consumer cursor is read from ``state_src``: a Merge PipelineGroup
        member waits its own full barrier at the group's shared consumer index.
        A group-level wait (the resource *is* the group -- FusedMerge) waits the
        shared full barrier once via ``group_pipeline`` (the group's own
        ``pipeline`` is ``None`` to avoid inject-leaves aliasing) and always does
        the full blocking wait: a group has no group-level ``ConsumerTryWait`` in
        this lowering, so a fresh ``0`` status is passed. The group's own
        ``consumer_status`` is seeded only by the driver's group-init and lacks
        a stable leaf across the selection gate.
        """
        resource = step.memory_resource
        if cutlass.const_expr(resource.pipeline_config is None):
            self._step_comment(step, f"{resource.name}.consumer_wait no pipeline")
            return
        cfg = _require_pipeline_config(resource)
        self._check_leader_cta_signaling(resource, _consumer_wait_signaling(cfg))
        do_wait = self._leader_cta_gate(cfg, _consumer_wait_signaling(cfg))
        pipe = (
            cast(PipelineGroup, resource).group_pipeline
            if cutlass.const_expr(isinstance(resource, PipelineGroup))
            else resource.pipeline
        )
        status = (
            cutlass.Int32(0)
            if cutlass.const_expr(isinstance(resource, PipelineGroup))
            else resource.load_consumer_status()
        )
        action = (
            "shared wait"
            if cutlass.const_expr(isinstance(resource, PipelineGroup))
            else "wait"
        )
        if do_wait:
            self._step_comment(step, f"{resource.name}.consumer_wait {action}")
            pipe.consumer_wait(_runtime_pipeline_state(step), status)
        elif cutlass.const_expr(emit_ptx_comments):
            self._step_comment(step, f"{resource.name}.consumer_wait skipped")
        if cutlass.const_expr(
            cfg.supports_try_probe_ops and not isinstance(resource, PipelineGroup)
        ):
            # Group-level waits always pass a fresh zero. Member waits consume
            # their resource token and clear it outside the signaling gate.
            resource.clear_consumer_status()

    @cute.jit
    def _consumer_release(self, step: Step) -> None:
        """Signal the stage empty and advance the consumer release cursor.

        The release arrive is gated to the leader CTA under CtaLeader signaling.
        Under ``advance_on_wait`` the release targets the separate
        ``consumer_release_state`` (the oldest un-released stage, which lags the
        already-advanced ``consumer_state``); otherwise it targets
        ``consumer_state``.  Each branch advances the cursor via its attribute
        path (avoiding local aliases -- see the aliasing note above the pipeline
        ops), so the advance threads through the walk.

        A Merge ``PipelineGroup`` release (the resource *is* the group) fires
        once on the shared empty barrier via ``group_pipeline`` (the group's own
        ``pipeline`` is ``None`` to avoid inject-leaves aliasing) and advances
        the group's shared consumer cursor.  The cursor is read from
        ``state_src`` so a group release uses the group's own cursor.
        """
        resource = step.memory_resource
        if cutlass.const_expr(resource.pipeline_config is None):
            self._step_comment(step, f"{resource.name}.consumer_release no pipeline")
            return
        cfg = _require_pipeline_config(resource)
        do_release = self._leader_cta_gate(cfg, cfg.consumer_signaling_threads)
        pipe = (
            cast(PipelineGroup, resource).group_pipeline
            if cutlass.const_expr(isinstance(resource, PipelineGroup))
            else resource.pipeline
        )
        state = _runtime_pipeline_state(step)
        action = (
            "shared signal"
            if cutlass.const_expr(isinstance(resource, PipelineGroup))
            else "signal"
        )
        if do_release:
            self._step_comment(step, f"{resource.name}.consumer_release {action}")
            pipe.consumer_release(state)
        elif cutlass.const_expr(emit_ptx_comments):
            self._step_comment(step, f"{resource.name}.consumer_release skipped")

    def _skip_if_takes_work_queue(self, skip_if: Any) -> bool:
        """Whether the work-tile skip predicate takes the WorkQueue as first arg.

        A predicate declaring two positional parameters is a
        ``(work_queue, work_tile)`` predicate; one declaring a single parameter
        is a ``(work_tile,)`` predicate.  Raises ScheduleError when it accepts
        neither arity.
        """
        if _callable_accepts_n_args(skip_if, 2):
            return True
        if _callable_accepts_n_args(skip_if, 1):
            return False
        raise ScheduleError(
            f"Task {self.name!r}: skip_if must accept either "
            "(work_queue, work_tile) or (work_tile)."
        )

    def _call_skip_if(self, skip_if: Any, work_queue: Any, work_tile: Any) -> Any:
        """Invoke the work-tile skip predicate with the arity its signature declares.

        A two-parameter predicate receives ``(work_queue, work_tile)``; a
        one-parameter predicate receives ``(work_tile,)``.
        """
        if self._skip_if_takes_work_queue(skip_if):
            return skip_if(work_queue, work_tile)
        return skip_if(work_tile)

    @emits_ir("work_tile_loop", node=lambda self, node, ctx: node)
    @cute.jit
    def _run_work_tile_loop(self, node: WorkTileLoop, ctx: _WalkContext) -> object:
        """Lower the persistent work-tile loop to an ``scf.while`` over the queue.

        The current work tile is a native ``scf.while`` iter-arg: seeded from
        ``ctx.work_tile`` -- the scheduler's initial tile, which ``run_body``
        placed there (via :meth:`_initial_body_work_tile`) so the pre-loop steps
        and the loop's first iteration share one tile -- and it is tested
        for the loop condition via ``work_tile.is_valid_tile``.  Returns the
        loop's final (invalid) tile so post-loop siblings adopt it (see
        :meth:`run_nodes`).  The loop carries the tile the body's queue-advance step
        (``get_and_advance_work_tile``) produced as the next iter-arg, returned up through
        :meth:`run_nodes` from :meth:`_run_queue_advance`.  Carrying it as the
        loop-local iter-arg keeps the scalarized
        ``WorkTileInfo`` reconciled across the ``scf.while``.  This single owner
        of the advance unifies the CLC consumer path -- where the advance is a
        pipeline read -- with the linear bump.
        The loop exits when the scheduler runs out of tiles.

        When ``skip_if`` is set, the per-tile skip Boolean is computed each
        iteration by :meth:`_call_skip_if` (which passes ``work_queue`` only to
        a two-parameter predicate) and threaded into the body so ``skippable()``
        regions run only on non-skipped tiles (bookkeeping steps outside them
        still run).
        """
        work_queue = node.work_queue
        # Hoist everything the loop body reads into locals: touching `node.` or
        # `ctx.` inside the scf.while makes the DSL treat that object (the tree
        # with its stub resources, or the context) as a loop-carried value and
        # fail to stage it.  The comment label is (re)built at enter and exit
        # rather than kept in a local: a str live across the loop would be
        # threaded as a loop iter-arg (a Meta value the DSL cannot carry).
        skip_if = node.skip_if
        parent_loop = ctx.loop
        work_tile = ctx.work_tile
        # The construct region brackets the REAL scf.while, so the loop
        # condition stays real SSA. An observer keeps its own
        # per-construct state — a local here would be threaded as a loop
        # iter-arg (see the label note).
        self._ptx_comment(f"enter {_work_tile_loop_label(node)}")
        while work_tile.is_valid_tile:
            if cutlass.const_expr(skip_if is not None):
                skip = self._call_skip_if(skip_if, work_queue, work_tile)
                if cutlass.const_expr(emit_ptx_comments):
                    if skip:
                        self._ptx_comment(f"{work_queue.name}.tile skipped")
                    else:
                        self._ptx_comment(f"{work_queue.name}.tile active")
            else:
                skip = None
            # The current tile is the loop iter-arg; thread it for stage_info.
            # The body's get_and_advance_work_tile step advances the queue and
            # its returned tile propagates up as the walk's result; take it as
            # the next iter-arg (the loop never advances on its own).
            work_tile = self.run_nodes(
                node.body,
                _WalkContext(
                    loop=parent_loop,
                    skip=skip,
                    work_tile=work_tile,
                ),
            )
            # WORKAROUND: force `self` state threading across the scf.while.
            self.dummy = cutlass.Boolean(True)
        self._ptx_comment(f"exit {_work_tile_loop_label(node)}")
        # The final iter-arg is the invalid tile that ended the loop; hand it to
        # post-loop siblings.
        return work_tile

    @cute.jit
    def _run_domain_loop(self, node: DomainLoop, ctx: _WalkContext) -> None:
        """Lower a domain loop to an ``scf.for`` over its resolved bounds.

        ``start`` / ``end`` / ``step`` are each either a static value or a
        per-tile Task method (``(self, work_tile_coord) -> value``); every bound
        is resolved here, then the body is walked once inside the loop region
        and traced for all iterations.  ``unroll`` maps to the ``cutlass.range``
        unroll hint (``None`` -> ``-1``, letting the compiler decide).

        The body context replaces ``loop`` with this loop's induction state; the
        enclosing skip flag and work tile are preserved.
        """
        # Hoist ctx reads into locals: touching `ctx.` inside the scf.for makes
        # the DSL treat the context as a loop-carried value and fail to stage it.
        skip = ctx.skip
        work_tile = ctx.work_tile
        start = self._resolve_bound(node.start, work_tile)
        end = self._resolve_bound(node.end, work_tile)
        step = self._resolve_bound(node.step, work_tile)
        if cutlass.const_expr(callable(node.step)):
            self._reject_nonpositive_domain_step(step)
        self._seed_domain_interleave_lanes(start, step)
        # The ONE construct that cannot use @emits_ir. The region must
        # start after the lane seeding (an observer's region is the REAL
        # scf.for and nothing else, so a consumer folds the loop's actual
        # bound SSA values), but the seeding needs the bounds this method
        # resolves. Extracting the tail into a decorated helper therefore
        # adds a second @cute.jit boundary, whose promoted arguments
        # change the emitted IR -- measured, not assumed.
        ir_emitters.begin("domain_loop", self, node)
        self._ptx_comment(
            f"enter DomainLoop(start={_describe_bound(node.start)}, "
            f"end={_describe_bound(node.end)}, "
            f"step={_describe_bound(node.step)}, "
            f"unroll={node.unroll})"
        )
        unroll = -1 if node.unroll is None else node.unroll
        for idx in cutlass.range(start, end, step, unroll=unroll):
            self.run_nodes(
                node.body,
                _WalkContext(
                    loop=_LoopContext(index=idx, start=start, end=end, step=step),
                    skip=skip,
                    work_tile=work_tile,
                ),
            )
            # WORKAROUND: force `self` state threading across the scf.for.
            self.dummy = cutlass.Boolean(True)
        self._ptx_comment("exit DomainLoop")
        ir_emitters.end("domain_loop", self, node)

    def _run_while_hook(self, hook: LoopHook, ctx: _WalkContext) -> Any:
        """Run a while-loop init/advance hook and return its stored cursor."""
        with constexpr_loop_scope():
            self._run_work(hook.step, ctx)
        return self._load_route_slot(id(hook.step.returned_variables[0]))

    @cute.jit
    def _break_guards_all_active(
        self, guards: tuple[BlockGuard, ...], ctx: _WalkContext
    ) -> object:
        """Return the conjunction of break guards for the current iteration.

        Avoid self-updating accumulators such as ``active = active & cond``.
        Inside a generated dynamic while loop, those variables become
        loop-carried and a false value from one iteration can stick forever.
        """
        if cutlass.const_expr(len(guards) == 0):
            return cutlass.Boolean(True)
        first = self._guard_active(guards[0], ctx)
        if cutlass.const_expr(len(guards) == 1):
            return first
        rest = self._break_guards_all_active(guards[1:], ctx)
        return first & rest

    @cute.jit
    def _break_clauses_any_active(
        self, clauses: tuple[tuple[BlockGuard, ...], ...], ctx: _WalkContext
    ) -> object:
        """Return the disjunction of break clauses for the current iteration."""
        if cutlass.const_expr(len(clauses) == 0):
            return cutlass.Boolean(False)
        first = self._break_guards_all_active(clauses[0], ctx)
        if cutlass.const_expr(len(clauses) == 1):
            return first
        rest = self._break_clauses_any_active(clauses[1:], ctx)
        return first | rest

    @cute.jit
    def _while_break_requested(
        self, clauses: tuple[tuple[BlockGuard, ...], ...], ctx: _WalkContext
    ) -> Any:
        """Return whether any captured while-loop break clause is active."""
        return self._break_clauses_any_active(clauses, ctx)

    @staticmethod
    def _loop_break_clauses_in_node(
        node: Node,
    ) -> tuple[tuple[BlockGuard, ...], ...]:
        """Return break clauses nested in ``node`` in source order."""
        return tuple(
            tuple(n.conditions) for n in _iter_nodes([node]) if isinstance(n, LoopBreak)
        )

    @cute.jit
    def _run_while_node_if_no_break(
        self,
        node: Node,
        ctx: _WalkContext,
        preceding_clauses: tuple[tuple[BlockGuard, ...], ...],
    ) -> None:
        """Run one node only if no earlier break site fired this iteration."""
        break_requested = self._while_break_requested(preceding_clauses, ctx)
        if not break_requested:
            self.run_node(node, ctx)
            # WORKAROUND: force `self` state threading across the scf.if.
            self.dummy = cutlass.Boolean(True)

    def _run_while_nodes(
        self,
        nodes: list[Node],
        ctx: _WalkContext,
        preceding_clauses: tuple[tuple[BlockGuard, ...], ...] = (),
    ) -> None:
        """Run a while body, suppressing nodes after the first active break.

        ``LoopBreak`` remains a capture-time marker rather than a runtime op.
        For every later node, the guards of all preceding break sites form a
        continuation predicate.  A conditional needs a specialized recursive
        lowering so a break also suppresses later nodes in that same block.
        """
        clauses = preceding_clauses
        for node in nodes:
            if isinstance(node, LoopBreak):
                clauses += (tuple(node.conditions),)
                continue
            if isinstance(node, ConditionalBlock):
                self._run_while_conditional_block(node, ctx, clauses)
            elif cutlass.const_expr(len(clauses) == 0):
                self.run_node(node, ctx)
            else:
                self._run_while_node_if_no_break(node, ctx, clauses)
            clauses += self._loop_break_clauses_in_node(node)

    @cute.jit
    def _run_while_true_loop(self, node: WhileTrueLoop, ctx: _WalkContext) -> None:
        """Lower a dynamic while loop to an ``scf.while`` over init/advance hooks.

        The init hook seeds the loop cursor.  Each iteration walks the body
        with ``_LoopContext(index=cursor, end=LOOP_STATE_UNAVAILABLE)``.  After
        the body, reaching a captured break suppresses the rest of that
        iteration and ends the loop; otherwise the advance hook produces the
        next cursor.
        """
        # Hoist node/ctx reads: touching them inside the scf.while makes the
        # DSL treat those objects as loop-carried values and fail to stage them.
        skip = ctx.skip
        work_tile = ctx.work_tile
        init_hook = node.init
        advance_hook = node.advance
        body = node.body
        break_conditions = tuple(tuple(brk.conditions) for brk in node.breaks)
        self._ptx_comment(
            f"enter WhileTrueLoop(init={init_hook.resource.name}.{init_hook.label}, "
            f"advance={advance_hook.resource.name}.{advance_hook.label})"
        )
        loop_state = self._run_while_hook(
            init_hook,
            _WalkContext(loop=None, skip=skip, work_tile=work_tile),
        )
        loop_active = cutlass.Boolean(True)
        while loop_active:
            body_ctx = _WalkContext(
                loop=_LoopContext(
                    index=loop_state,
                    start=LOOP_STATE_UNAVAILABLE,
                    end=LOOP_STATE_UNAVAILABLE,
                    step=LOOP_STATE_UNAVAILABLE,
                ),
                skip=skip,
                work_tile=work_tile,
            )
            self._run_while_nodes(body, body_ctx)
            break_requested = self._while_break_requested(break_conditions, body_ctx)
            if break_requested:
                loop_active = cutlass.Boolean(False)
            else:
                loop_state = self._run_while_hook(advance_hook, body_ctx)
                loop_active = cutlass.Boolean(True)
            # WORKAROUND: force `self` state threading across the scf.while.
            self.dummy = cutlass.Boolean(True)
        self._ptx_comment("exit WhileTrueLoop")

    def _reject_nonpositive_domain_step(self, step: object) -> None:
        """Reject a ``domain_loop`` step callable that resolved to a non-positive int.

        A non-positive stride makes the ``scf.for`` ill-defined. When the
        callable resolves to a compile-time integer, a value ``<= 0`` raises
        ``ScheduleError`` while tracing. A value only known at runtime is not
        checked here.
        """
        if cutlass.const_expr(isinstance(step, int) and step <= 0):
            raise ScheduleError(
                f"Task {self.name!r}: domain_loop() step callable returned "
                f"{step}; the step must be a positive int."
            )

    def _resolve_bound(self, bound: Any, work_tile: Any) -> Any:
        """Resolve a DomainLoop bound to a concrete value.

        A callable bound is a per-tile Task method invoked as
        ``bound(self, tile_coord)`` with the *current work tile's* coordinate
        (``work_tile.tile_idx``), so a persistent task resolves a fresh per-tile
        domain rather than the CTA's block coordinate; a non-callable bound is returned
        unchanged.
        """
        if callable(bound):
            return bound(self, work_tile.tile_idx)
        return bound

    @emits_ir("cond", node=lambda self, node, ctx: node)
    @cute.jit
    def _run_conditional_block(self, node: ConditionalBlock, ctx: _WalkContext) -> None:
        """Lower a conditional region, keyed on its ``BlockGuard``.

        - ``SKIPPABLE`` -> ``if not skip_work_tile`` on the work-tile loop's
          per-tile skip Boolean (always runs when there is no ``skip_if``).
        - An ``IterationPredicate`` (``FIRST_ITER`` / ``LAST_ITER`` / ``Every``)
          -> a runtime test on the enclosing domain loop's induction value
          (:meth:`_iteration_predicate_active`).
        - An ``OpaqueCondition`` -> a runtime test on the stored work-call output
          the guard names (:meth:`_opaque_condition_active`).
        """
        guard = node.condition
        # The construct region brackets the REAL guarded branch: the
        # scf.if and its predicate computation.
        self._ptx_comment(f"enter ConditionalBlock({_describe_guard(guard)})")
        # Compare fieldless singleton guards by value: the DSL
        # reconstructs a frozen-dataclass guard across @cute.jit boundaries, making
        # ``is`` unreliable (value equality remains stable).
        if cutlass.const_expr(guard == SKIPPABLE):
            skip = ctx.skip
            if cutlass.const_expr(skip is None):
                self.run_nodes(node.body, ctx)
            elif not skip:
                self.run_nodes(node.body, ctx)
                # WORKAROUND: force `self` state threading across the scf.if.
                self.dummy = cutlass.Boolean(True)
        elif cutlass.const_expr(isinstance(guard, BlockGuard)):
            if self._guard_active(guard, ctx):
                self.run_nodes(node.body, ctx)
                # WORKAROUND: force `self` state threading across the scf.if.
                self.dummy = cutlass.Boolean(True)
        else:
            raise TypeError(f"Unhandled block guard: {type(guard).__name__}")
        self._ptx_comment(f"exit ConditionalBlock({_describe_guard(guard)})")

    @emits_ir("cond", node=lambda self, node, ctx, preceding_clauses: node)
    @cute.jit
    def _run_while_conditional_block(
        self,
        node: ConditionalBlock,
        ctx: _WalkContext,
        preceding_clauses: tuple[tuple[BlockGuard, ...], ...],
    ) -> None:
        """Lower a while-body condition and stop it after an earlier break."""
        guard = node.condition
        self._ptx_comment(f"enter ConditionalBlock({_describe_guard(guard)})")
        if cutlass.const_expr(len(preceding_clauses) == 0):
            continuation_active: Any = cutlass.Boolean(True)
        else:
            break_requested = self._while_break_requested(preceding_clauses, ctx)
            continuation_active = ~break_requested

        # Keep this as one runtime branch so the observer region still brackets
        # the conditional's actual scf.if rather than a separate continuation
        # gate followed by the user-authored guard.
        if cutlass.const_expr(guard == SKIPPABLE):
            skip = ctx.skip
            if cutlass.const_expr(skip is None):
                guard_active: Any = cutlass.Boolean(True)
            else:
                guard_active = ~_condition_value_to_bool(skip)
        elif cutlass.const_expr(isinstance(guard, BlockGuard)):
            guard_active = self._guard_active(guard, ctx)
        else:
            raise TypeError(f"Unhandled block guard: {type(guard).__name__}")

        if continuation_active & guard_active:
            self._run_while_nodes(node.body, ctx, preceding_clauses)
            # WORKAROUND: force `self` state threading across the scf.if.
            self.dummy = cutlass.Boolean(True)
        self._ptx_comment(f"exit ConditionalBlock({_describe_guard(guard)})")

    @cute.jit
    def _guard_active(self, guard: BlockGuard, ctx: _WalkContext) -> object:
        """Recursively lower one boolean schedule guard."""
        if cutlass.const_expr(isinstance(guard, IterationPredicate)):
            if cutlass.const_expr(ctx.loop is None):
                raise ValueError(
                    f"{_describe_guard(guard)} block requires an enclosing domain loop."
                )
            return self._iteration_predicate_active(guard, ctx.loop)
        if cutlass.const_expr(isinstance(guard, OpaqueCondition)):
            return self._opaque_condition_active(guard)
        if cutlass.const_expr(isinstance(guard, GuardAnd)):
            guard_and = cast(GuardAnd, guard)
            active = self._guard_active(guard_and.operands[0], ctx)
            for operand in guard_and.operands[1:]:
                active = active & self._guard_active(operand, ctx)
            return active
        if cutlass.const_expr(isinstance(guard, GuardOr)):
            guard_or = cast(GuardOr, guard)
            active = self._guard_active(guard_or.operands[0], ctx)
            for operand in guard_or.operands[1:]:
                active = active | self._guard_active(operand, ctx)
            return active
        raise TypeError(f"Unhandled block guard: {type(guard).__name__}")

    @cute.jit
    def _iteration_predicate_active(
        self, guard: IterationPredicate, loop: "_LoopContext"
    ) -> object:
        """Runtime predicate for an iteration-guarded block on this domain loop.

        ``FIRST_ITER`` / ``LAST_ITER`` compare the induction value against the
        loop's first / last iteration; ``Every(period, start)`` fires on the
        zero-based iteration counts ``start, start + period, ...``.
        """
        idx, start, end, step = loop.index, loop.start, loop.end, loop.step
        if cutlass.const_expr(isinstance(guard, ComplementedIterationPredicate)):
            complemented = cast(ComplementedIterationPredicate, guard)
            return ~self._iteration_predicate_active(complemented.predicate, loop)
        if cutlass.const_expr(guard == FIRST_ITER):
            return idx == start
        if cutlass.const_expr(guard == LAST_ITER):
            return idx == _last_iteration_index(start, end, step)
        if cutlass.const_expr(isinstance(guard, Every)):
            assert isinstance(guard, Every)
            iteration = (idx - start) // step
            g_start = cutlass.Int32(guard.start)
            period = cutlass.Int32(guard.period)
            return (iteration >= g_start) & (
                (iteration - g_start) % period == cutlass.Int32(0)
            )
        raise TypeError(f"Unhandled iteration predicate: {type(guard).__name__}")

    @cute.jit
    def _opaque_condition_active(self, guard: OpaqueCondition) -> object:
        """Runtime predicate for an ``OpaqueCondition`` block.

        Reads the guard's TaskLocalVariable from the shared mailbox populated
        when the producing work ran. Integer-like values are false only when
        zero. ``negated`` inverts the value for ``when_false`` blocks. A guard
        with no ``resource`` is unconditionally true.
        """
        if cutlass.const_expr(guard.resource is None):
            active: Any = cutlass.Boolean(True)
        else:
            if cutlass.const_expr(guard.result_name is None):
                raise ValueError(
                    "OpaqueCondition with a resource must name a stored condition "
                    "result."
                )
            condition_var_keys = object.__getattribute__(self, "_condition_var_keys")
            var_key = condition_var_keys[(id(guard.resource), guard.result_name)]
            value = self._load_route_slot(var_key)
            active = _condition_value_to_bool(value)
        if cutlass.const_expr(guard.negated):
            active = ~active
        return active


class RegisterPaddingTask(Task):
    """Set a warp-group register budget on an explicit warp/CTA rectangle.

    Register padding intentionally has no resources or schedule body. In
    particular, persistent kernels must not count its non-uniform per-CTA warp
    participation in a ``WorkQueue`` barrier's cooperative group.
    """

    def __init__(
        self,
        *,
        warp_idx: int,
        num_warps: int,
        num_registers: int,
        cta_ranks: int | range | tuple[int, ...] | None = None,
        name: str,
    ) -> None:
        super().__init__(
            src_resources=[],
            dst_resources=[],
            warp_idx=warp_idx,
            num_warps=num_warps,
            schedule=Schedule(name=name, body=[], resources=[]),
            num_registers=num_registers,
            name=name,
            run_only_on_cta_id=cta_ranks,
        )
