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

"""Emitter for the informational ``ts`` dialect (single-module design).

Two responsibilities, both serialization ONLY:

- **Declarations**: forward the primitive facts :mod:`.adapter` marshaled
  out of the live ``task_scheduling`` objects to the C++ ``DeclBuilder``,
  which places ``ts.resource`` / ``ts.work_queue`` / ``ts.pipeline_group``
  / ``ts.slot`` ops at the kernel function's entry. The assigned ordinals
  ("r0", "s1", ...) are kept in a ts_audit-owned weak map keyed by the
  TaskManager and by each Task, for the marker walker.
- **Markers**: :func:`begin_mark` / :func:`end_mark` bracket everything
  one schedule construct traces with a ``ts.mark`` pair; the begin marker
  carries the construct's payload (kind, resource ordinal, guard, ...).
  ``ts-form-regions`` -- right after the pyir prelower, before any
  optimization -- pairs the markers and wraps the ops between them into
  ``ts.body`` regions.

This module never reads a ``task_scheduling`` attribute; every framework
fact arrives as an :mod:`.adapter` record, and a record the adapter could
not build degrades to a skipped item plus one grouped warning.

Do not add schedule-correctness logic here -- checks belong in
Ts/Transforms passes.

Environment: ``CUTLASS_TS_EMIT_IR`` (default on) controls all emission;
set to ``0``/``false``/``off``/``no`` to disable.
"""

import itertools
import os
import weakref
from typing import Any, Optional

from cutlass._mlir import ir
from cutlass._mlir.dialects import ts as _ts

from . import TsAuditError, adapter

_EMIT_ENV = "CUTLASS_TS_EMIT_IR"
_FALSE_VALUES = frozenset({"0", "false", "off", "no"})


def emission_enabled() -> bool:
    """Whether ts emission (declarations and markers) is enabled."""
    return os.environ.get(_EMIT_ENV, "1").strip().lower() not in _FALSE_VALUES


# --------------------------------------------------------------------- #
# Markers.
# --------------------------------------------------------------------- #

#: Unique suffix for structural (non-Step) marker pair ids within a trace.
_mark_counter = itertools.count()


def _i64(value: int) -> ir.IntegerAttr:
    return ir.IntegerAttr.get(ir.IntegerType.get_signless(64), int(value))


def _i32(value: int) -> ir.IntegerAttr:
    return ir.IntegerAttr.get(ir.IntegerType.get_signless(32), int(value))


def _str_array(values: list) -> ir.ArrayAttr:
    return ir.ArrayAttr.get([ir.StringAttr.get(str(v)) for v in values])


def _dict_attr(mapping: dict) -> ir.DictAttr:
    entries = {}
    for key, value in mapping.items():
        if isinstance(value, bool):
            attr: ir.Attribute = ir.BoolAttr.get(value)
        elif isinstance(value, int):
            attr = _i64(value)
        else:
            attr = ir.StringAttr.get(str(value))
        entries[str(key)] = attr
    return ir.DictAttr.get(entries)


def _guard_attr(guard: "adapter.GuardSpec") -> ir.Attribute:
    """Marshaled guard spec -> #ts guard attribute."""
    if guard.kind == "first_iter":
        return _ts.FirstIterGuardAttr.get()
    if guard.kind == "last_iter":
        return _ts.LastIterGuardAttr.get()
    if guard.kind == "every":
        return _ts.EveryGuardAttr.get(guard.period, guard.start)
    if guard.kind == "skippable":
        return _ts.SkippableGuardAttr.get()
    if guard.kind == "opaque":
        return _ts.OpaqueGuardAttr.get(guard.key, guard.negated)
    raise TypeError(f"unmapped schedule guard: {guard!r}")


def emit_mark(
    kind: str,
    body_kind: str,
    step: Optional[str] = None,
    *,
    task: Optional[str] = None,
    resource: Optional[str] = None,
    role: Optional[str] = None,
    callee: Optional[str] = None,
    reads: Optional[list] = None,
    writes: Optional[list] = None,
    call_attrs: Optional[dict] = None,
    guard: Optional[ir.Attribute] = None,
    work_queue: Optional[str] = None,
    warp_idx: Optional[int] = None,
    num_warps: Optional[int] = None,
    num_registers: Optional[int] = None,
    run_only_on_cta_id: Optional[int] = None,
    src: Optional[list] = None,
    dst: Optional[list] = None,
    source_loc: "Optional[tuple]" = None,
) -> ir.Operation:
    """Emits one ``ts.mark`` at the current insertion point.

    ``kind`` is ``"begin"`` or ``"end"``; ``body_kind`` a ``BodyKind``
    spelling; ``step`` the pair-matching id shared by both markers of one
    construct. Begin markers carry the construct payload — copied
    verbatim onto the formed ``ts.body`` by ``ts-form-regions``. Only
    sound on untransformed IR: formation must consume the pair before any
    other pass runs.

    ``source_loc`` is the recorded user ``(file, line)`` of the schedule
    call that produced the construct; it becomes the op's location (same
    convention as the declarations' side-table source locs) so audit
    diagnostics point at the user's schedule line instead of the ambient
    insertion site. NEVER used for correlation — diagnostics only.
    """
    context = ir.Context.current
    attributes: dict = {
        "kind": ir.Attribute.parse(f"#ts.mark_kind<{kind}>", context),
        "body_kind": ir.Attribute.parse(f"#ts.body_kind<{body_kind}>", context),
    }
    if step is not None:
        attributes["step"] = ir.StringAttr.get(step)
    if task is not None:
        attributes["task"] = ir.StringAttr.get(task)
    if resource is not None:
        attributes["resource"] = ir.StringAttr.get(resource)
    if role is not None:
        attributes["role"] = ir.Attribute.parse(f"#ts.work_role<{role}>", context)
    if callee is not None:
        attributes["callee"] = ir.StringAttr.get(callee)
    if reads:
        attributes["reads"] = _str_array(reads)
    if writes:
        attributes["writes"] = _str_array(writes)
    if call_attrs:
        attributes["call_attrs"] = _dict_attr(call_attrs)
    if guard is not None:
        attributes["guard"] = guard
    if work_queue is not None:
        attributes["work_queue"] = ir.StringAttr.get(work_queue)
    if warp_idx is not None:
        attributes["warp_idx"] = _i64(warp_idx)
    if num_warps is not None:
        attributes["num_warps"] = _i64(num_warps)
    if num_registers is not None:
        attributes["num_registers"] = _i32(num_registers)
    if run_only_on_cta_id is not None:
        attributes["run_only_on_cta_id"] = _i32(run_only_on_cta_id)
    if src:
        attributes["src"] = _str_array(src)
    if dst:
        attributes["dst"] = _str_array(dst)
    loc = None
    if source_loc is not None:
        file, line = source_loc
        loc = ir.Location.file(str(file), int(line), 0, context=context)
    return ir.Operation.create("ts.mark", attributes=attributes, loc=loc)


def begin_mark(spec: Optional[tuple]) -> Optional[tuple]:
    """Emits the begin marker of a construct; returns the token
    :func:`end_mark` needs, or ``None`` when ``spec`` is ``None``
    (emission disabled / ordinals unavailable)."""
    if spec is None:
        return None
    body_kind, step_id, payload = spec
    op = emit_mark("begin", body_kind, step_id, **payload)
    return (body_kind, step_id, op)


def end_mark(token: Optional[tuple]) -> None:
    """Emits the end marker matching a :func:`begin_mark` token.

    An unpaired begin marker is a LOUD formation error, so if end
    emission itself fails the begin marker is erased — the construct then
    simply forms no region (fail-open), instead of failing the compile.
    """
    if token is None:
        return
    body_kind, step_id, begin_op = token
    try:
        emit_mark("end", body_kind, step_id)
    except BaseException:
        begin_op.erase()
        raise


#: Open-construct tokens for the walker. A MODULE-level stack, never a
#: walker frame local: several walker methods are ``@cute.jit``-traced,
#: and a local live across a traced loop would be threaded as a loop
#: iter-arg (a Meta value the DSL cannot carry). Constructs trace strictly
#: nested, so stack discipline matches begin/end pairing; the stack is
#: reset per trace by :func:`emit_after_setup`.
_open_marks: list = []


def push_mark(spec: Optional[tuple]) -> None:
    """:func:`begin_mark` with the token pushed on the module stack.

    ALWAYS pushes exactly one entry (``None`` on emission failure) so a
    matching :func:`pop_mark` stays aligned."""
    token = None
    try:
        token = begin_mark(spec)
    finally:
        _open_marks.append(token)


def pop_mark() -> None:
    """:func:`end_mark` for the innermost :func:`push_mark`."""
    if not _open_marks:
        return
    end_mark(_open_marks.pop())


#: Ordinals assigned at setup, owned HERE and not stashed on framework
#: objects (a ts_audit attribute on a TaskManager or a Task would be an
#: attribute the framework never declared). Keyed by the manager and by
#: every task of that manager, so the walker resolves them from whichever
#: object it holds. Weak keys: the entry dies with the trace.
_ordinals: "weakref.WeakKeyDictionary[Any, tuple[dict, dict]]" = (
    weakref.WeakKeyDictionary()
)


#: The traced function each manager emitted into, owned HERE for the same
#: reason as :data:`_ordinals`.
_func_ops: "weakref.WeakKeyDictionary[Any, Any]" = weakref.WeakKeyDictionary()

#: Framework fields already named in a degradation report; the report is
#: emitted once per distinct set of misses so a renamed attribute is loud
#: exactly once instead of once per construct.
_reported_missing: set[str] = set()


def _report_degradation() -> None:
    """Report, once, every framework attribute this process could not read.

    A miss means ``task_scheduling`` changed under ts_audit: a declaration
    or step that needed the attribute is left out of the audit, and a guard
    kind the adapter cannot classify is bracketed as an opaque conditional
    (never as unconditional, which could turn a legal schedule into an
    error). Silence here would look like a clean audit of an incomplete
    schedule.
    """
    missing = adapter.missing_fields()
    if not missing or set(missing) <= _reported_missing:
        return
    _reported_missing.update(missing)
    _warn_infra(
        "task_scheduling changed: ts_audit could not read "
        + ", ".join(missing)
        + "; items that needed a missing attribute are left out of the audit, "
        "and a guard it cannot classify is audited as an opaque conditional"
    )


def set_ordinals(owner: Any, resource_ords: dict, slot_ords: dict) -> None:
    """Remember the ordinals assigned for ``owner`` (manager or task)."""
    try:
        _ordinals[owner] = (resource_ords, slot_ords)
    except TypeError:  # pragma: no cover - unhashable / weakref-less owner
        pass


def get_ordinals(owner: Any) -> Optional[tuple[dict, dict]]:
    """The ordinals recorded for ``owner``, or ``None``."""
    try:
        return _ordinals.get(owner)
    except TypeError:  # pragma: no cover - unhashable owner
        return None


def _task_ordinals(task: Any) -> Optional[tuple[dict, dict]]:
    """(resource ordinals, slot ordinals) recorded for ``task`` at setup,
    or ``None`` when marks should not be emitted."""
    if not emission_enabled():
        return None
    return get_ordinals(task)


def step_mark_spec(task: Any, step: Any) -> Optional[tuple]:
    """Marker spec for one schedule ``Step`` (verb or work)."""
    ordinals = _task_ordinals(task)
    if ordinals is None:
        return None
    resource_ords, slot_ords = ordinals
    info = adapter.step_info(task, step)
    if info is None:
        return None
    payload: dict = {"resource": resource_ords[id(info.resource)]}
    if info.source_loc is not None:
        payload["source_loc"] = info.source_loc
    if info.verb is not None:
        return info.verb, info.step_id, payload
    payload["role"] = info.role
    if info.callee:
        payload["callee"] = info.callee
    reads = [slot_ords[id(v)] for v in info.reads]
    writes = [slot_ords[id(v)] for v in info.writes]
    if reads:
        payload["reads"] = reads
    if writes:
        payload["writes"] = writes
    if info.call_attrs:
        payload["call_attrs"] = dict(info.call_attrs)
    return "work", info.step_id, payload


def _structural_step_id(name: str, body_kind: str) -> str:
    return f"{name}.{body_kind}.{next(_mark_counter)}"


def task_mark_spec(task: Any) -> Optional[tuple]:
    """Marker spec bracketing a task's selected-branch body."""
    ordinals = _task_ordinals(task)
    if ordinals is None:
        return None
    resource_ords, _ = ordinals
    info = adapter.task_info(task)
    if info is None:
        return None
    payload: dict = {
        "task": info.name,
        "warp_idx": info.warp_idx,
        "num_warps": info.num_warps,
    }
    if info.num_registers is not None:
        payload["num_registers"] = int(info.num_registers)
    if info.run_only_on_cta_id is not None:
        payload["run_only_on_cta_id"] = int(info.run_only_on_cta_id)
    src = [resource_ords[id(r)] for r in info.src_resources]
    dst = [resource_ords[id(r)] for r in info.dst_resources]
    if src:
        payload["src"] = src
    if dst:
        payload["dst"] = dst
    return "task", _structural_step_id(info.name, "task"), payload


def _structural_task_name(task: Any) -> str:
    """The task name used in structural pair ids (never fails).

    Default: this must not fail or record a miss. A renamed ``name`` is
    already reported by :func:`adapter.task_info` on the same walk.
    """
    name = adapter.field(task, "name", None)
    return name if name else "task"


def drain_mark_spec(task: Any, resource: Any) -> Optional[tuple]:
    """Marker spec bracketing one resource's post-body drain."""
    ordinals = _task_ordinals(task)
    if ordinals is None:
        return None
    resource_ords, _ = ordinals
    info = adapter.drain_info(resource)
    payload = {"resource": resource_ords[id(info.resource)]}
    step_id = _structural_step_id(_structural_task_name(task), "drain")
    return "drain", step_id, payload


def domain_loop_mark_spec(task: Any, node: Any = None) -> Optional[tuple]:
    """Marker spec bracketing a domain loop's real ``scf.for``.

    No bounds payload: the formed ``ts.body<domain_loop>`` contains the
    real loop op, whose bound SSA values the audits fold directly.
    """
    if _task_ordinals(task) is None:
        return None
    adapter.domain_loop_info(node)
    step_id = _structural_step_id(_structural_task_name(task), "domain_loop")
    return "domain_loop", step_id, {}


def work_tile_loop_mark_spec(task: Any, node: Any) -> Optional[tuple]:
    """Marker spec bracketing the persistent loop's real ``scf.while``."""
    ordinals = _task_ordinals(task)
    if ordinals is None:
        return None
    resource_ords, _ = ordinals
    info = adapter.work_tile_loop_info(node)
    if info is None:
        return None
    payload = {"work_queue": resource_ords[id(info.work_queue)]}
    step_id = _structural_step_id(_structural_task_name(task), "work_tile_loop")
    return "work_tile_loop", step_id, payload


def cond_mark_spec(task: Any, node: Any) -> Optional[tuple]:
    """Marker spec bracketing a guarded block's real branch."""
    if _task_ordinals(task) is None:
        return None
    info = adapter.cond_info(node)
    if info is None:
        return None
    payload = {"guard": _guard_attr(adapter.guard_spec(info.guard))}
    step_id = _structural_step_id(_structural_task_name(task), "cond")
    return "cond", step_id, payload


# --------------------------------------------------------------------- #
# Declarations.
# --------------------------------------------------------------------- #


class _Declare:
    """Single-pass declaration walk feeding the C++ DeclBuilder.

    Every framework fact arrives as an :mod:`.adapter` record; an item
    the adapter could not marshal is SKIPPED (it gets no ordinal, so the
    marks referring to it are skipped too) and the miss is reported once
    by :func:`_report_degradation`.

    After :meth:`run`, :attr:`resource_ords` / :attr:`slot_ords` map
    ``id(python object)`` -> assigned ordinal for the marker walker, and
    :attr:`readable` says whether the manager could be walked at all.
    """

    def __init__(self, task_manager: Any, builder: Any) -> None:
        self.tm = task_manager
        self.builder = builder
        self.resource_ords: dict[int, str] = {}
        self.slot_ords: dict[int, str] = {}
        #: False when the schedule could not be walked. The caller must
        #: then record NO ordinals: an empty-but-present ordinal map reads
        #: as "emission is on" to the mark specs, which would then look up
        #: an ordinal that is not there and raise on every construct.
        self.readable = False

    def run(self) -> None:
        plan = adapter.collect_declarations(self.tm)
        if plan is None:
            return
        self.readable = True
        groups = []
        for resource in plan.resources:
            if adapter.is_work_queue(resource):
                queue = adapter.queue_decl(
                    resource, plan.queue_skip_ifs.get(id(resource))
                )
                if queue is None:
                    continue
                self.resource_ords[id(resource)] = self.builder.add_work_queue(
                    queue.name, queue.scheduler, queue.num_stages, queue.skip_if
                )
            elif adapter.is_pipeline_group(resource):
                groups.append(resource)  # members first; groups second pass.
            else:
                decl = adapter.resource_decl(resource)
                if decl is None:
                    continue
                self.resource_ords[id(resource)] = self.builder.add_resource(
                    decl.name,
                    None,
                    decl.pipeline_config.spec if decl.pipeline_config else None,
                    decl.type_name,
                    decl.source_file,
                    decl.source_line,
                )
        for group in groups:
            group_decl = adapter.group_decl(group)
            if group_decl is None:
                continue
            member_ords = [self.resource_ords.get(id(m)) for m in group_decl.members]
            if any(ordinal is None for ordinal in member_ords):
                continue  # a member was skipped: the group would dangle.
            self.resource_ords[id(group)] = self.builder.add_pipeline_group(
                group_decl.name, group_decl.mode, member_ords
            )
        for variable in plan.slots:
            slot = adapter.slot_decl(variable)
            if slot is None:
                continue
            self.slot_ords[id(variable)] = self.builder.add_slot(
                slot.name, list(slot.types)
            )


def _enclosing_kernel_function() -> ir.Operation:
    """The function-like op enclosing the current insertion point.

    The nearest ancestor carrying a ``sym_name`` and a region is the traced
    kernel function — the op whose entry block receives the declarations.
    """
    # Block.owner is the operation owning the block; normalize OpView vs
    # Operation via .operation. Operation.parent is the parent *operation*
    # in these bindings (only Block has .owner), so the walk stays on
    # operations the whole way up.
    op = ir.InsertionPoint.current.block.owner.operation
    while op is not None:
        if "sym_name" in op.attributes and len(op.regions) > 0:
            return op
        op = op.parent
    raise RuntimeError("no enclosing function-like op for ts emission")


def emit(task_manager: Any, *, func: Optional[ir.Operation] = None) -> ir.Operation:
    """Emits the ts declarations for ``task_manager`` at function entry.

    When ``func`` is None the traced kernel function is discovered from
    the current insertion point. Returns the function op.

    The assigned ordinals go into this module's :data:`_ordinals` weak
    map, keyed by the TaskManager and by each of its Tasks, so the marker
    walker can resolve them from whichever object it holds; the framework
    objects carry no ts_audit attributes. When the schedule could not be
    read at all, NO ordinals are recorded, which the mark specs read as
    "emission off for this manager" -- the safe state.
    """
    if func is None:
        func = _enclosing_kernel_function()
    file, line = adapter.caller_loc()
    func_operation = getattr(func, "operation", func)
    builder = _ts.DeclBuilder(func_operation, file, line)
    walk = _Declare(task_manager, builder)
    try:
        walk.run()
        builder.finalize()
    except BaseException:
        # Declarations stay detached until finalize(); abandoning them
        # keeps the traced function byte-identical on any marshaling
        # failure (fail-open must never leave half-built ops behind).
        builder.abandon()
        raise
    _func_ops[task_manager] = func_operation
    if walk.readable:
        set_ordinals(task_manager, walk.resource_ords, walk.slot_ords)
        for task in adapter.manager_tasks(task_manager) or ():
            set_ordinals(task, walk.resource_ords, walk.slot_ords)
    _report_degradation()
    return func_operation


def emit_after_setup(task_manager: Any) -> None:
    """Fail-open emission hook called from ``setup_resources_and_tasks``.

    Emits the declarations and runs the declaration-level audits
    (verifiers + ``ts-verify-schedule``). Audit rejections surface as
    :class:`TsAuditError` (a ``ValueError``, matching the TS validation
    surface) unless the TaskManager was built with ``skip_validation``;
    any other emission problem degrades to a warning and never blocks
    compilation.
    """
    if not emission_enabled():
        return
    # A previous trace that aborted mid-walk may have left open-construct
    # tokens behind; a fresh trace starts balanced.
    _open_marks.clear()
    try:
        func_op = emit(task_manager)
        from .audit import run_audit

        run_audit(func_op)
    except TsAuditError as error:
        # Default: an internal flag only ``TaskManager.__init__`` sets, so
        # a manager built another way legitimately lacks it.
        if adapter.field(task_manager, "_warn_only", False):
            _warn_advisory(f"skip_validation demoted an audit error:\n{error}")
            return
        raise
    except Exception as error:  # noqa: BLE001 - fail-open by design.
        _warn_infra(f"TS IR emission failed: {error!r}")


def audit_after_run(task_manager: Any) -> None:
    """Test/tooling entry: run the structural ts audits on a traced manager.

    NOT called by the product flow: in the compile pipeline the same
    passes (``ts-form-regions`` first, the audits after the first
    canonicalize/cse block, ``ts-strip-ts`` right after) run on the IR
    that actually lowers. This hook remains for tests and offline tools
    that want the same checks on a freshly traced module — it FORMS the
    ``ts.body`` regions in place (sound: the trace is untransformed;
    the pipeline's own formation pass is idempotent on formed IR). Same
    surface as :func:`emit_after_setup`: audit rejections keep the TS
    ``ValueError`` (``skip_validation`` demotes), infrastructure failures
    degrade to a warning.
    """
    if not emission_enabled():
        return
    func_op = _func_ops.get(task_manager)
    if func_op is None:
        return
    try:
        from .audit import run_structural_audit

        run_structural_audit(func_op)
    except TsAuditError as error:
        # Default: an internal flag only ``TaskManager.__init__`` sets, so
        # a manager built another way legitimately lacks it.
        if adapter.field(task_manager, "_warn_only", False):
            _warn_advisory(f"skip_validation demoted an audit error:\n{error}")
            return
        raise
    except Exception as error:  # noqa: BLE001 - fail-open by design.
        _warn_infra(f"TS structural audit failed: {error!r}")


def _warn_advisory(details: str) -> None:
    """One grouped DSL warning for advisory audit findings; plain-warning
    fallback keeps fail-open working even if the DSL catalog is absent."""
    try:
        from cutlass.base_dsl.diagnostics import WarnId, report_warning

        report_warning(WarnId.TS_AUDIT_ADVISORY, details=details)
    except Exception:  # noqa: BLE001 - reporting must never break a build.
        _warn_quietly(f"TS audit advisory: {details}")


def _warn_infra(details: str) -> None:
    """Infrastructure-degradation DSL warning (kernel unaffected)."""
    try:
        from cutlass.base_dsl.diagnostics import WarnId, report_warning

        report_warning(WarnId.TS_INFRA_DEGRADED, details=details)
    except Exception:  # noqa: BLE001 - reporting must never break a build.
        _warn_quietly(f"TS audit infrastructure degraded (ignored): {details}")


def _warn_quietly(message: str) -> None:
    """``warnings.warn`` that cannot itself raise.

    Under ``-W error`` a warning IS an exception. These fallbacks run on
    the non-fail-open ``after_setup`` path, where a raising warning would
    turn a degraded audit into a failed compile.
    """
    import warnings

    try:
        warnings.warn(message)
    except Exception:  # noqa: BLE001 - a warning must never break a build.
        pass
