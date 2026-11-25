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

"""ts-dialect audit infrastructure (NOT part of the TS product API).

This package is compiler infrastructure that OBSERVES ``task_scheduling``
through its generic ``ir_emitters`` hook; the framework has no knowledge
of this package, and kernel authors never import it. It contains NO
analysis logic — analysis lives at the MLIR level (the ``Ts/Transforms``
passes behind the C++ ``run_audits`` bindings). What remains in Python,
and why it must:

- :mod:`.adapter` — the ONLY reader of ``task_scheduling`` attribute
  names; marshals live framework objects into frozen records and reports
  what it could not read;
- :mod:`.emitter` — declaration facts forwarded to the typed C++
  ``DeclBuilder`` (Python heap objects are only reachable from Python),
  plus the ``ts.mark`` begin/end pairs bracketing what each schedule
  construct traces;
- :mod:`.ir_emitter` — the ``ScheduleIREmitter`` implementation binding
  the framework's construct announcements to the two above;
- :mod:`.audit` — maps structured C++ audit diagnostics onto the TS
  ``ValueError`` / ``skip_validation`` surface (the user-facing exception
  contract is Python).

Importing this package registers the emitter (gated by
``CUTLASS_TS_EMIT_IR``) and declares this package as infrastructure for
the framework's user-source-location attribution.
"""

from . import adapter as adapter  # noqa: E402 - bind before .emitter imports it


class TsAuditError(ValueError):
    """A ts-dialect audit rejected the emitted schedule.

    Raised (instead of the fail-open warning path) so schedule errors keep
    today's TS ``ValueError`` surface; ``skip_validation`` demotes it to a
    warning in ``TaskManager``.
    """


from .audit import run_audit, run_structural_audit  # noqa: E402
from .emitter import (  # noqa: E402
    audit_after_run,
    begin_mark,
    cond_mark_spec,
    domain_loop_mark_spec,
    drain_mark_spec,
    emission_enabled,
    emit,
    emit_after_setup,
    emit_mark,
    end_mark,
    pop_mark,
    push_mark,
    step_mark_spec,
    task_mark_spec,
    work_tile_loop_mark_spec,
)

from .ir_emitter import TsIREmitter, the_emitter  # noqa: E402


def _register() -> None:
    """Observe the task-scheduling framework from this process on.

    Registration is unconditional; ``CUTLASS_TS_EMIT_IR`` is honored
    inside the emitter, which keeps a disabled build on exactly the same
    code path as an enabled one (only the emitted ops differ).
    """
    from cutlass.experimental.task_scheduling import enums, ir_emitters

    # Frames of this package sit between the user and the framework, so
    # they must not be reported as a user construction site.
    enums.add_infrastructure_module_prefix(__name__)
    ir_emitters.register_ir_emitter(the_emitter)


_register()

__all__ = [
    "TsAuditError",
    "TsIREmitter",
    "audit_after_run",
    "begin_mark",
    "cond_mark_spec",
    "domain_loop_mark_spec",
    "drain_mark_spec",
    "emission_enabled",
    "emit",
    "emit_after_setup",
    "emit_mark",
    "end_mark",
    "pop_mark",
    "push_mark",
    "run_audit",
    "run_structural_audit",
    "step_mark_spec",
    "task_mark_spec",
    "the_emitter",
    "work_tile_loop_mark_spec",
]
