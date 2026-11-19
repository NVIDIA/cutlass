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

"""ts-dialect audit runner: exception bridge ONLY.

The audits themselves (verifier + the ``ts-verify-schedule`` pass, and
every future audit pass) run in C++ behind ``run_audits``; this module
only maps their structured diagnostics onto the TS ``ValueError``
surface. Do not add schedule-correctness logic here — checks belong in
MLIR passes (Ts/Transforms).
"""

from typing import Any

from cutlass._mlir.dialects import ts as _ts

from . import TsAuditError


def _dispatch_findings(findings: Any, what: str) -> None:
    """Maps structured (severity, message, file, line) findings onto the
    TS surface: error-severity findings as one :class:`TsAuditError`;
    everything else grouped into ONE DSL warning (yellow ``[Warning]``
    block via ``report_warning``, anchored at the first finding's python
    line) — never per-finding spam."""
    errors = []
    advisories = []
    first_loc: "tuple[str, int] | None" = None
    for severity, message, file, line in findings:
        where = f"{file}:{line}: " if file else ""
        text = f"{where}{message}"
        if severity == "error":
            errors.append(text)
        else:
            advisories.append(f"[{severity}] {text}")
            if first_loc is None and file:
                first_loc = (file, int(line))
    if advisories:
        from cutlass.base_dsl.diagnostics import WarnId, report_warning

        report_warning(
            WarnId.TS_AUDIT_ADVISORY,
            filename=first_loc[0] if first_loc else None,
            lineno=first_loc[1] if first_loc else None,
            details="  " + "\n  ".join(advisories),
        )
    if errors:
        raise TsAuditError(f"TS schedule failed {what}:\n  " + "\n  ".join(errors))


def run_audit(func_op: Any) -> None:
    """Runs the declaration-level ts audits (op verifiers +
    ``ts-verify-schedule``) over the module enclosing the kernel function
    ``func_op``; raises :class:`TsAuditError` on error findings. Valid on
    unformed IR (markers not yet consumed)."""
    _dispatch_findings(_ts.run_audits(func_op), "ts-dialect audits")


def run_structural_audit(func_op: Any) -> None:
    """Runs ``ts-form-regions`` + ``ts-check-schedule`` +
    ``ts-audit-arrivals`` over the module enclosing the kernel function
    ``func_op``; raises :class:`TsAuditError` on error findings. FORMS
    the ``ts.body`` regions in place, so it must run on untransformed
    traced IR, after the task bodies traced (post ``run()``) — before
    that there are no marked ops to attribute."""
    _dispatch_findings(_ts.run_structural_audits(func_op), "the ts structural audit")
