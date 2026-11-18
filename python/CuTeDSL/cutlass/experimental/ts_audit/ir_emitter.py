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

"""The ts-dialect implementation of the framework's IR-emitter hook.

``task_scheduling.ir_emitters`` announces each schedule construct as it
is traced; this module turns those announcements into the ``ts.mark``
pairs the ``ts-form-regions`` pass folds into ``ts.body`` regions, and
turns the post-setup announcement into the declaration emission plus the
declaration-level audits.

Nothing here may leave the marker stack unbalanced: every :meth:`begin`
pushes exactly one entry whatever goes wrong, because the framework's
``finally`` will pop exactly one.

Unknown construct kinds are expected: the framework may grow a construct
before this package learns what it means. Such a construct still gets a
region -- an opaque ``cond`` body naming the kind -- so the ops it traces
stay attributed to *something* the audits treat conservatively (a guarded
region demotes balance errors to remarks) rather than silently merging
into the enclosing construct. Each unknown kind is reported once.
"""

from typing import Any, Callable, Optional

from ..task_scheduling import ir_emitters
from . import emitter

__all__ = ["TsIREmitter", "the_emitter"]

#: kind -> the spec builder for that construct. Every builder takes
#: ``(task, node)`` and returns a marker spec or ``None``.
_SPEC_BUILDERS: dict[str, Callable[[Any, Any], Optional[tuple]]] = {
    "task": lambda task, node: emitter.task_mark_spec(task),
    "step": emitter.step_mark_spec,
    "drain": emitter.drain_mark_spec,
    "domain_loop": emitter.domain_loop_mark_spec,
    "work_tile_loop": emitter.work_tile_loop_mark_spec,
    "cond": emitter.cond_mark_spec,
}

#: Construct kinds already reported as unknown; one report per kind per
#: process (a walk emits the same unknown kind many times).
_reported_unknown_kinds: set[str] = set()


def _unknown_kind_spec(kind: str, task: Any) -> Optional[tuple]:
    """An opaque region for a construct kind this package does not know.

    Modeled as a guarded (``cond``) body: the audits treat a guarded
    region conservatively, so an unrecognized construct can never turn
    into a false schedule error.
    """
    if kind not in _reported_unknown_kinds:
        _reported_unknown_kinds.add(kind)
        emitter._warn_infra(
            f"task_scheduling announced the unknown schedule construct "
            f"{kind!r}; ts_audit brackets it as an opaque region and audits "
            f"it conservatively"
        )
    if emitter._task_ordinals(task) is None:
        return None
    from cutlass._mlir.dialects import ts as _ts

    payload = {"guard": _ts.OpaqueGuardAttr.get(f"<unknown:{kind}>", False)}
    step_id = emitter._structural_step_id(emitter._structural_task_name(task), kind)
    return "cond", step_id, payload


class TsIREmitter:
    """Emits the ts audit mirror of the schedule the walker is tracing.

    Implements ``task_scheduling.ir_emitters.ScheduleIREmitter``. The
    begin/end token stack lives on the :mod:`.emitter` module, never in a
    walker frame local: several walker methods are ``@cute.jit``-traced,
    and a local live across a traced loop is threaded as a loop iter-arg.
    """

    def begin(self, kind: str, task: Any, node: Any) -> None:
        """Open a ``ts.mark`` pair for one construct.

        ALWAYS pushes exactly one stack entry (``None`` when nothing is
        emitted), so the matching :meth:`end` stays aligned. Building the
        spec is therefore inside the try: a builder that raises must not
        skip the push, or the enclosing construct's :meth:`end` would pop
        the PARENT's token and close its region early.
        """
        spec = None
        if node is not ir_emitters.NO_NODE:
            try:
                builder = _SPEC_BUILDERS.get(kind)
                spec = (
                    builder(task, node) if builder else _unknown_kind_spec(kind, task)
                )
            except Exception:  # noqa: BLE001 - fail-open by design.
                spec = None
        emitter.push_mark(spec)
        emitter._report_degradation()

    def end(self, kind: str, task: Any, node: Any) -> None:
        """Close the innermost pair opened by :meth:`begin`."""
        del kind, task, node
        emitter.pop_mark()

    def after_setup(self, manager: Any) -> None:
        """Emit the declarations and run the declaration-level audits."""
        emitter.emit_after_setup(manager)


#: The single registered instance (registration happens in ``__init__``).
the_emitter = TsIREmitter()
