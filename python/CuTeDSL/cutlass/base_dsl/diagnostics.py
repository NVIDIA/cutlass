# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""User-facing DSL error catalog.

One entry per author-facing mistake.  The enum **member name** is the stable
error code (e.g. ``TYPE_UNSTABLE_JOIN``) -- there are no hand-written numbers to
keep in sync.  The member **value** is ``(message_template, (fix_line, ...))``,
written in the author's words, never in compiler/IR terms::

    raise DSLUserCodeError(DiagId.TYPE_UNSTABLE_JOIN, filename=fn, lineno=ln,
                           var="count", old_type="Int32", new_type="Float32")

The exception consumes the ``DiagId`` directly (see ``DiagId.format``) and
renders through ``DSLUserCodeError`` (snippet + suggestion box), so an error
raised while tracing looks the same as one raised while reading code.

Auto-doc readiness (the generator is intentionally *not* built yet): every entry
exposes ``.code`` (the name), ``.category`` (the name's prefix), ``.message`` and
``.fix``.  A future doc generator just does::

    for d in DiagId:                      # group by d.category, emit d.code/
        ...                               # d.message/d.fix

so no separate metadata table is needed.  New entries are added here as their
detection is wired up; the full taxonomy lives in
``pyirdocs/DSL_DIAGNOSTICS_ARCHITECTURE.md``.
"""

import ast
import enum
import linecache
import re
import sys
import textwrap
import types
from dataclasses import dataclass, replace
from pathlib import Path
from typing import Any, Mapping, Sequence

__all__ = [
    "Colors",
    "CompilerDiagnostic",
    "CompilerDiagnosticSession",
    "DiagId",
    "WarnId",
    "report_warning",
    "META_VALUE",
    "STAGED_VALUE",
]

# Canonical author-facing names for the two value phases.  Defined once here and
# auto-injected into every message as {meta}/{staged} (see DiagId.format), so the
# wording is consistent and can be changed in a single place.
META_VALUE = "Python value (Meta value)"
STAGED_VALUE = "Runtime value (Staged value)"


class Colors:
    """Shared ANSI color codes for DSL and compiler diagnostics."""

    RED = "\033[91m"
    YELLOW = "\033[93m"
    BLUE = "\033[94m"
    GREEN = "\033[92m"
    CYAN = "\033[96m"
    BOLD = "\033[1m"
    RESET = "\033[0m"


_Colors = Colors


@dataclass(frozen=True)
class CompilerDiagnostic:
    severity: str
    message: str
    code: str = ""
    namespace: str = ""
    name: str = ""
    location: str = ""
    reason: str = ""
    suggestion: str = ""
    ptx_ref: str = ""
    ptx_url: str = ""
    notes: tuple[str, ...] = ()


@dataclass(frozen=True)
class _CompilerDiagnosticInfo:
    code: str
    namespace: str = ""
    ptx_ref: str = ""
    ptx_url: str = ""


_PY_LOC_RE = re.compile(r'"(?P<file>[^"]+?\.py)":(?P<line>\d+):(?P<col>\d+)')

_PTX_DOC_BASE = "https://docs.nvidia.com/cuda/parallel-thread-execution/index.html"
_COMPILER_DIAG_TEXT_WIDTH = 100
_COMPILER_CONTEXT_LINES = 2
_DEVICE_BINARY_SERIALIZATION_DIAGNOSTIC = "DeviceBinarySerializationFailed"
_SYNC_SUMMARY_REMARKS = {
    "RemarkSyncViolation",
    "RemarkSyncWarning",
    "RemarkSyncClean",
}
_PTXAS_LOG_REMARK = "RemarkPTXAS"
_PTXAS_LOG_PREFIX = "ptxas output:"
_PTXAS_REGISTER_SPILL_WARNING = "PtxasPerfRegisterSpill"
_WARNINGS_PROMOTED_TO_ERRORS = {
    _PTXAS_REGISTER_SPILL_WARNING,
    "DivmodMigration",
}
_PTXAS_PERF_FINDINGS = {
    _PTXAS_REGISTER_SPILL_WARNING,
    "RemarkPerfLocalMemoryUsage",
}
_PTXAS_KERNEL_RE = re.compile(r"kernel `([^`]+)`")
# Match ptxas fatal diagnostics while tolerating formatting differences.
_PTXAS_FATAL_RE = re.compile(r"^\s*ptxas\s+fatal\s*:\s*(?P<text>.+?)\s*$", re.MULTILINE)
_PTXAS_GENERIC_FATAL = "Ptx assembly aborted due to errors"
_PTXAS_REGISTER_ALLOCATION_RE = re.compile(r"Register allocation failed")


def _nvvm_info(code: str, ptx_ref: str, ptx_anchor: str) -> _CompilerDiagnosticInfo:
    return _CompilerDiagnosticInfo(
        code=code,
        namespace="nvvm-diag",
        ptx_ref=ptx_ref,
        ptx_url=_PTX_DOC_BASE + ptx_anchor,
    )


_COMPILER_DIAGNOSTICS: dict[str, _CompilerDiagnosticInfo] = {
    "NvvmDiagMbarrierArriveNeedsElect": _nvvm_info(
        "C3/C4",
        "mbarrier arrive and elect.sync",
        "#parallel-synchronization-and-communication-instructions-mbarrier-arrive",
    ),
    "NvvmDiagMbarrierCountMismatch": _nvvm_info(
        "C3",
        "mbarrier.init",
        "#parallel-synchronization-and-communication-instructions-mbarrier-init",
    ),
    "NvvmDiagMbarrierCountMismatchWarning": _nvvm_info(
        "C3",
        "mbarrier.init",
        "#parallel-synchronization-and-communication-instructions-mbarrier-init",
    ),
    "NvvmDiagExpectTxNeedsCompletion": _nvvm_info(
        "C5",
        "mbarrier.arrive.expect_tx",
        "#parallel-synchronization-and-communication-instructions-"
        "mbarrier-expect-tx-operation",
    ),
    "NvvmDiagCta2TmaMulticastMayHang": _nvvm_info(
        "C5",
        "cp.async.bulk.tensor cta_group::2 completion",
        "#data-movement-and-conversion-instructions-cp-async-bulk-tensor",
    ),
    "NvvmDiagTcgen05LdNeedsCommit": _nvvm_info(
        "C7",
        "tcgen05 memory consistency",
        "#tcgen05-memory-consistency-model-canonical-sync-patterns",
    ),
    "NvvmDiagTcgen05LdMissingAfterFence": _nvvm_info(
        "C7",
        "tcgen05 memory consistency",
        "#tcgen05-memory-consistency-model-canonical-sync-patterns",
    ),
    "NvvmDiagTcgen05CollectiveNeedsFullWarp": _nvvm_info(
        "C10",
        "tcgen05 relinquish_alloc_permit",
        "#tcgen05-instructions-tcgen05-alloc-dealloc-relinquish-alloc-permit",
    ),
    "NvvmDiagTcgen05CommitNeedsElect": _nvvm_info(
        "C11",
        "tcgen05 commit",
        "#tcgen-async-sync-operations-commit",
    ),
    "NvvmDiagPreSignalParityConflict": _nvvm_info(
        "C12",
        "mbarrier phase-parity protocol",
        "#parallel-synchronization-and-communication-instructions-"
        "mbarrier-test-wait-try-wait",
    ),
    "NvvmDiagPerSlotPhaseParityMismatch": _nvvm_info(
        "C8",
        "mbarrier phase-parity protocol",
        "#parallel-synchronization-and-communication-instructions-"
        "mbarrier-test-wait-try-wait",
    ),
    "NvvmDiagPartialWarpElectSync": _nvvm_info(
        "C13",
        "elect.sync",
        "#parallel-synchronization-and-communication-instructions-elect-sync",
    ),
    "NvvmDiagInlineAsmMissingMemoryClobber": _CompilerDiagnosticInfo(
        code="C18",
        namespace="nvvm-diag",
    ),
    _DEVICE_BINARY_SERIALIZATION_DIAGNOSTIC: _CompilerDiagnosticInfo(""),
    _PTXAS_REGISTER_SPILL_WARNING: _CompilerDiagnosticInfo(
        code="spill",
        namespace="ptxas",
    ),
}

_GENERIC_MLIR_DIAGNOSTIC = "MLIRDiagnostic"


class CompilerDiagnosticCollector:
    """Scoped collector for regular MLIR diagnostics emitted during pass runs."""

    def __init__(self, context: Any, enabled: bool) -> None:
        self.context = context
        self.enabled = enabled
        self.diagnostics: list[CompilerDiagnostic] = []
        self._handler: Any | None = None
        self._previous_emit_error_diagnostics: bool | None = None

    def __enter__(self) -> "CompilerDiagnosticCollector":
        if not self.enabled or not hasattr(self.context, "attach_diagnostic_handler"):
            return self
        if hasattr(self.context, "emit_error_diagnostics"):
            self._previous_emit_error_diagnostics = bool(
                self.context.emit_error_diagnostics
            )
            self.context.emit_error_diagnostics = True
        self._handler = self.context.attach_diagnostic_handler(self._handle)
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: types.TracebackType | None,
    ) -> None:
        if self._handler is not None:
            self._handler.detach()
            self._handler = None
        if self._previous_emit_error_diagnostics is not None:
            self.context.emit_error_diagnostics = self._previous_emit_error_diagnostics
            self._previous_emit_error_diagnostics = None

    def _handle(self, diagnostic: Any) -> bool:
        try:
            self.diagnostics.append(_mlir_diagnostic_from_callback(diagnostic))
        except Exception:  # noqa: BLE001 -- diagnostics must not break compile
            return False
        return True


class CompilerDiagnosticSession:
    """Own compiler diagnostic collection and rendering for one pass-manager run."""

    def __init__(
        self,
        context: Any,
        *,
        remark_filter: str = "",
        warnings_filter: str = "",
        remark_output: str = "",
        collect_diagnostics: bool = False,
        warnings_as_errors: bool = False,
    ) -> None:
        self.context = context
        self.remark_filter = remark_filter
        # Checker domains whose warnings the DSL shows (from warnings{<cat>}).
        # Errors always show; warnings are gated to these domains; remarks are
        # gated at collection by the remark filter.
        self.warnings_filter = warnings_filter
        self.remark_output = remark_output
        self.collect_diagnostics = bool(collect_diagnostics and not remark_output)
        # Promote supported compiler warnings to errors when requested.
        self.warnings_as_errors = warnings_as_errors
        self._success_is_error = False
        self.enabled = bool(remark_output) or self.collect_diagnostics
        self._collector = CompilerDiagnosticCollector(
            self.context, self.collect_diagnostics
        )

    def enable(self) -> None:
        if not self.enabled:
            return
        enable_compiler_diagnostics(
            self.context,
            remark_filter=self.remark_filter,
            remark_output=self.remark_output,
            collect_diagnostics=self.collect_diagnostics,
        )

    def collecting(self) -> CompilerDiagnosticCollector:
        return self._collector

    def format_success(self) -> str:
        if not self.collect_diagnostics:
            self._success_is_error = False
            return ""
        diagnostics = self._collected_diagnostics()
        if self.warnings_as_errors:
            diagnostics, self._success_is_error = _promote_warnings_to_errors(
                diagnostics
            )
        else:
            self._success_is_error = False
        return format_compiler_diagnostics(diagnostics)

    @property
    def warnings_promoted_to_errors(self) -> bool:
        """True when format_success promoted a compiler warning under Werror."""
        return self._success_is_error

    def format_failure(self, raw_error: str) -> str:
        if not self.collect_diagnostics:
            return ""
        diagnostics = self._collected_diagnostics()
        # A generic MLIR error may be a backend failure whose detailed
        # diagnostic was consumed by the scoped collector. Only a typed error
        # belongs to the structured-diagnostic path; otherwise let Compiler
        # inspect the collected text and classify the backend failure.
        if not any(
            diag.severity == "error" and diag.name != _GENERIC_MLIR_DIAGNOSTIC
            for diag in diagnostics
        ):
            return ""
        return format_compiler_failure_diagnostics(diagnostics, raw_error)

    def _collected_error_texts(self) -> tuple[str, ...]:
        """Return MLIR errors consumed by the scoped diagnostic collector."""
        texts: list[str] = []
        for diag in self._collector.diagnostics:
            if diag.severity != "error":
                continue
            location = f"{diag.location}: " if diag.location else ""
            texts.append(f"{location}{diag.message}")
        return tuple(texts)

    def format_backend_failure(
        self,
        *,
        raw_error: str,
        nvvm_error: str = "",
        ptxas_error: str = "",
        ir_context: str = "",
        arch: str = "",
        location: str = "",
    ) -> str:
        return format_compiler_backend_failure(
            raw_error=raw_error,
            nvvm_error=nvvm_error,
            ptxas_error=ptxas_error,
            ir_context=ir_context,
            arch=arch,
            location=location,
        )

    def finalize(self) -> None:
        if self.enabled:
            finalize_compiler_diagnostics(self.context)

    def _collected_diagnostics(self) -> list[CompilerDiagnostic]:
        diagnostics = collect_compiler_diagnostics(
            self.context, extra_diagnostics=self._collector.diagnostics
        )
        diagnostics = _filter_warning_visibility(diagnostics, self.warnings_filter)
        return _filter_remark_visibility(diagnostics, self.remark_filter)


def _diagnostic_selectors() -> "tuple[str, ...]":
    """The warnings{}/remarks{} selector names, longest first.

    Single source of truth is compiler.py's ``_DOMAIN_TO_REMARK_CATEGORY``;
    imported lazily because compiler.py imports this module. Longest-first so
    a selector that is a prefix of another cannot shadow it."""
    from .compiler import _DOMAIN_TO_REMARK_CATEGORY

    return tuple(sorted(_DOMAIN_TO_REMARK_CATEGORY, key=len, reverse=True))


def _warning_domain(name: str) -> str:
    """Map a warning's name to its checker domain, for warnings{} gating.

    A diagnostic belongs to the domain whose selector its catalog name starts
    with, case-insensitively: ``NvvmDiagProxyFenceMissing`` -> ``nvvm``,
    ``PtxasRegisterCap`` -> ``ptx``. This reproduces exactly the hard-coded
    ``NvvmDiag`` / ``Ptxas`` prefixes it replaces, and extends to every
    selector without naming any diagnostic family here.

    Not derived from the diagnostic's category: ``CutlassIRError`` and
    ``CutlassIRWarning`` in RemarkUtils.td bake CategoryError / CategoryWarning
    into the packed id, so EVERY warning reports the category "Warning"
    regardless of which checker raised it. Only remarks carry a domain
    category, and those are already filtered by the engine at collection.

    Returns "" when no selector matches, which keeps an untagged warning
    visible whenever any ``warnings{}`` was passed."""
    lowered = name.lower()
    for selector in _diagnostic_selectors():
        if lowered.startswith(selector):
            return selector
    return ""


def _filter_warning_visibility(
    diagnostics: Sequence[CompilerDiagnostic], warnings_filter: str
) -> list[CompilerDiagnostic]:
    """Drop warnings whose checker domain is not enabled via warnings{<cat>}.

    Errors and remarks always pass: errors are unconditional, and remarks are
    already gated at collection by the remark filter. A warning is shown only
    when its domain is listed in ``warnings_filter`` (or it is '.*' / 'all')."""
    domains = {d.strip() for d in warnings_filter.split(",") if d.strip()}
    show_all = bool(domains & {".*", "all"})
    out: list[CompilerDiagnostic] = []
    for diag in diagnostics:
        if diag.severity != "warning" or show_all:
            out.append(diag)
            continue
        domain = _warning_domain(diag.name)
        # Domain-tagged warnings show when their domain is requested; untagged
        # (generic) warnings show whenever any warnings{} was passed.
        if domain in domains or (not domain and domains):
            out.append(diag)
    return out


def _promote_warnings_to_errors(
    diagnostics: Sequence[CompilerDiagnostic],
) -> tuple[list[CompilerDiagnostic], bool]:
    """Promote visible ptxas spill and divmod migration warnings to errors.

    Other warnings and remarks are left unchanged. Returns the rewritten list
    and whether any warning was promoted.
    """
    out: list[CompilerDiagnostic] = []
    promoted = False
    for diag in diagnostics:
        if diag.name in _WARNINGS_PROMOTED_TO_ERRORS and diag.severity == "warning":
            out.append(replace(diag, severity="error"))
            promoted = True
        else:
            out.append(diag)
    return out, promoted


def _filter_remark_visibility(
    diagnostics: Sequence[CompilerDiagnostic], remark_filter: str
) -> list[CompilerDiagnostic]:
    """Drop opt-in remarks unless remarks{} requested them.

    Errors and warnings always pass (warnings are already gated by
    _filter_warning_visibility). Opt-in remarks are shown only when remarks{}
    set a concrete category: the engine then narrowed them to those categories
    at collection. When no remarks{} was passed the filter defaults to the
    match-all sentinel (``.*``) — which the engine cannot use to suppress at
    collection time — so we treat that default as "not requested" and drop the
    remarks here. Errors/warnings (always-on) are unaffected."""
    requested = remark_filter.strip()
    if requested and requested not in (".*", "all"):
        return list(diagnostics)
    return [diag for diag in diagnostics if diag.severity != "remark"]


def _widen_legacy_ptxas_filter(remark_filter: str) -> str:
    """Widen the legacy literal ``ptxas`` so it matches the category name.

    NOT dead code after the category unification: users passing the literal
    ``ptxas`` (documented usage — ``--remark-filter=ptxas`` /
    ``CUTE_DSL_REMARKS=ptxas``) predate the ``ptxas info`` category name, and
    the MLIR remark engine anchors the filter regex to the whole string, so
    the bare literal would match nothing without this widening."""
    if remark_filter == "ptxas":
        return "ptxas.*"
    return remark_filter


def _load_diagnostic_bindings() -> Any | None:
    try:
        from .._mlir._mlir_libs._cutlass_ir import _diagnostic
    except ImportError:
        return None
    return _diagnostic


def _mlir_diagnostic_from_callback(diagnostic: Any) -> CompilerDiagnostic:
    notes = tuple(
        str(getattr(note, "message", "")) for note in getattr(diagnostic, "notes", ())
    )
    severity = str(getattr(diagnostic, "severity", ""))
    return CompilerDiagnostic(
        severity="warning" if severity.endswith(".WARNING") else "error",
        message=str(diagnostic.message),
        name=_GENERIC_MLIR_DIAGNOSTIC,
        location=str(diagnostic.location),
        notes=tuple(note for note in notes if note),
    )


def enable_compiler_diagnostics(
    context: Any,
    *,
    remark_filter: str = "",
    remark_output: str = "",
    collect_diagnostics: bool = False,
) -> None:
    """Enable YAML remark output or structured diagnostic collection."""

    bindings = _load_diagnostic_bindings()
    if bindings is None:
        from .utils.logger import log

        log().warning(
            "CutlassIR diagnostic bindings not found; compiler diagnostics "
            "and remarks are unavailable"
        )
        return

    filter_str = _widen_legacy_ptxas_filter(remark_filter or ".*")
    if collect_diagnostics:
        # Collecting path (a checker is enabled via warnings{}/remarks{}):
        # errors/warnings are always-on and collected regardless of any filter
        # (warnings are gated later at display by warnings{}). A non-empty
        # remark filter narrows opt-in remarks to the requested categories, but
        # an empty filter is read as match-all by the engine. So opt-in remarks
        # are gated at display instead (see _filter_remark_visibility): they are
        # shown only when remarks{} was passed.
        opt_filter = _widen_legacy_ptxas_filter(remark_filter or "")
        bindings.enable_remark_collection(
            context,
            policy="all",
            passed_filter=opt_filter,
            missed_filter=opt_filter,
            failed_filter=opt_filter,
            analysis_filter=opt_filter,
        )
    elif remark_output:
        bindings.enable_remarks(
            context,
            policy="final",
            output_file=remark_output,
            passed_filter=filter_str,
            missed_filter=filter_str,
            failed_filter=filter_str,
            analysis_filter=filter_str,
        )


def _dedupe_compiler_diagnostics(
    diagnostics: Sequence[CompilerDiagnostic],
) -> list[CompilerDiagnostic]:
    richer_keys = {
        (diag.severity, diag.location)
        for diag in diagnostics
        if diag.name != _GENERIC_MLIR_DIAGNOSTIC
    }
    seen: set[tuple[str, str, str, str]] = set()
    deduped: list[CompilerDiagnostic] = []
    for diag in diagnostics:
        if (
            diag.name == _GENERIC_MLIR_DIAGNOSTIC
            and (diag.severity, diag.location) in richer_keys
        ):
            continue
        key = (diag.severity, diag.name, diag.message, diag.location)
        if key in seen:
            continue
        seen.add(key)
        deduped.append(diag)
    return deduped


def _ptxas_log_from_diagnostic(diag: CompilerDiagnostic) -> str:
    if diag.name != _PTXAS_LOG_REMARK:
        return ""
    message = diag.message.strip()
    if message.startswith(_PTXAS_LOG_PREFIX):
        return message[len(_PTXAS_LOG_PREFIX) :].strip()
    return message


def _ptxas_kernel_name(diag: CompilerDiagnostic) -> str:
    match = _PTXAS_KERNEL_RE.search(diag.reason)
    return match.group(1) if match else ""


def _select_ptxas_log(diag: CompilerDiagnostic, logs: Sequence[str]) -> str:
    if not logs:
        return ""
    kernel_name = _ptxas_kernel_name(diag)
    if kernel_name:
        for log in logs:
            if kernel_name in log:
                return log
    return "\n\n".join(logs)


def _append_ptxas_output(reason: str, log: str) -> str:
    log = log.strip()
    if not log:
        return reason
    return f"{reason}\n\nptxas output:\n{log}"


def _normalize_ptxas_perf_remark(
    diag: CompilerDiagnostic, ptxas_logs: Sequence[str]
) -> CompilerDiagnostic:
    log = _select_ptxas_log(diag, ptxas_logs)
    if diag.name == _PTXAS_REGISTER_SPILL_WARNING:
        return replace(
            diag,
            reason=_append_ptxas_output(
                "Spilled values are placed in local memory and can add memory "
                "traffic and latency. ptxas reports spill usage at kernel "
                "granularity; the source frame marks a likely pressure region, "
                "not an exact spill instruction.",
                log,
            ),
            suggestion=(
                "reduce live ranges in the reported kernel / likely pressure "
                "region, split large expressions or fragments, or inspect the "
                "generated PTX/SASS to identify values kept live across long "
                "regions"
            ),
        )
    if diag.name == "RemarkPerfLocalMemoryUsage":
        return replace(
            diag,
            reason=_append_ptxas_output(
                "Runtime-indexed per-thread arrays often require addressable "
                "PTX local memory instead of scalar registers; this can add "
                "memory traffic and latency.",
                log,
            ),
        )
    return diag


def _normalize_ptxas_diagnostics(
    diagnostics: Sequence[CompilerDiagnostic],
) -> list[CompilerDiagnostic]:
    ptxas_logs = [
        log for diag in diagnostics if (log := _ptxas_log_from_diagnostic(diag))
    ]
    normalized: list[CompilerDiagnostic] = []
    for diag in diagnostics:
        # RemarkPTXAS transports the raw verbose log needed to explain a
        # structured ptxas finding. It is supporting data, not a standalone
        # optimization remark, so a clean compilation must not print it.
        if diag.name == _PTXAS_LOG_REMARK:
            continue
        if diag.name in _PTXAS_PERF_FINDINGS:
            normalized.append(_normalize_ptxas_perf_remark(diag, ptxas_logs))
        else:
            normalized.append(diag)
    return normalized


def collect_compiler_diagnostics(
    context: Any, extra_diagnostics: Sequence[CompilerDiagnostic] = ()
) -> list[CompilerDiagnostic]:
    """Collect structured compiler diagnostics from the current MLIR context."""

    bindings = _load_diagnostic_bindings()
    diagnostics: list[CompilerDiagnostic] = []
    if bindings is not None:
        for item in bindings.get_collected_remarks(context):
            diagnostic = compiler_diagnostic_from_remark(item)
            if diagnostic is not None:
                diagnostics.append(diagnostic)
    diagnostics.extend(extra_diagnostics)
    # The pass-level synchronization summaries are useful in raw/YAML analysis
    # output, but are not standalone findings. In particular, rendering the
    # warning summary as a remark would bypass warnings{} visibility. Keep the
    # exact errors, warnings, and uncertainty remarks in the user-facing stream.
    diagnostics = [
        diag for diag in diagnostics if diag.name not in _SYNC_SUMMARY_REMARKS
    ]
    return _normalize_ptxas_diagnostics(_dedupe_compiler_diagnostics(diagnostics))


def finalize_compiler_diagnostics(context: Any) -> None:
    """Finalize the MLIR remark engine, if diagnostic bindings are available."""

    bindings = _load_diagnostic_bindings()
    if bindings is None:
        return
    bindings.finalize_remarks(context)


def find_user_source_location() -> tuple[
    str | None, int | None, int | None, int | None
]:
    """Best-effort author location: ``(filename, line, col, end_col)``.

    Walks out to the nearest call-stack frame *outside* the DSL package (frames
    classified by module name -- robust across source / build-tree / installed
    layouts), so a diagnostic raised deep inside the DSL still points at the
    author's own line.  On Python 3.11+ the column span of the instruction the
    author frame is suspended at is recovered via ``co_positions`` so the caret
    can underline it.  Returns ``(None, None, None, None)`` when no author frame
    is on the stack.
    """
    try:
        frame: types.FrameType | None = sys._getframe(1)
    except Exception:  # noqa: BLE001
        return None, None, None, None
    stdlib: frozenset[str] = getattr(sys, "stdlib_module_names", frozenset())
    try:
        while frame is not None:
            mod = frame.f_globals.get("__name__", "") or ""
            top = mod.split(".", 1)[0]
            fn = frame.f_code.co_filename
            is_internal = (
                mod == "cutlass"
                or mod.startswith("cutlass.")
                or top in stdlib
                or fn.startswith("<")
            )
            if not is_internal:
                line, col, end_col = frame.f_lineno, None, None
                try:  # exact column span of the suspended instruction (3.11+)
                    positions = list(frame.f_code.co_positions())  # type: ignore[attr-defined]
                    idx = frame.f_lasti // 2
                    if 0 <= idx < len(positions):
                        sl, el, sc, ec = positions[idx]
                        if sl is not None:
                            line = sl
                            if sc is not None and el == sl:
                                col, end_col = sc, ec
                except Exception:  # noqa: BLE001 -- best-effort column
                    pass
                return fn, line, col, end_col
            frame = frame.f_back
    finally:
        del frame
    return None, None, None, None


def render_code_frame(
    filename: str | None,
    line: int | None,
    col: int | None = None,
    end_col: int | None = None,
    *,
    display_filename: str | None = None,
) -> str | None:
    """Code frame: ``--> file:line:col`` + gutter + source lines + caret.

    Shows the error line preceded by up to two lines of context. The ``^``
    underlines ``[col, end_col)`` on the error line when a column span is known,
    otherwise it points at the first non-blank character of that line.
    Best-effort -- returns just the ``-->`` location line if the source cannot
    be read.
    """
    if not filename or not line:
        return None
    frame = _format_user_source_frame(
        filename, line, col, end_col, display_filename=display_filename
    )
    return "\n".join(frame) if frame else None


def render_user_diagnostic(err: Any) -> str:
    """Render a DSL user diagnostic or warning.

    Used by ``DSLBaseError`` and ``DSLWarning`` so AST pre-processing, tracing,
    runtime errors, and warnings share one source-frame and suggestion format.
    """
    parts = []
    cause_text = err._generate_cause()
    code = getattr(err, "code", None)
    frame = render_code_frame(
        err.filename, err.line, getattr(err, "col", None), getattr(err, "end_col", None)
    )

    if getattr(err, "_is_internal", False):
        return _format_internal_error_diagnostic(err, frame, cause_text)

    severity = "warning" if getattr(err, "_severity", "error") == "warning" else "error"
    parts.append(
        _format_diagnostic_headline(
            severity,
            err.message,
            code=code or "",
            bold=True,
            leading_newline=True,
        )
    )

    if frame:
        parts.append(frame)

    if getattr(err, "error_code", None) is not None:
        parts.extend(_format_user_labeled_text("note", f"error code {err.error_code}"))
    if cause_text:
        parts.extend(_format_user_labeled_text("note", cause_text))
    if err.context:
        if isinstance(err.context, dict):
            for key, value in err.context.items():
                parts.extend(_format_user_labeled_text("note", f"{key}: {value}"))
        else:
            parts.extend(_format_user_labeled_text("note", str(err.context)))
    if err.suggestion:
        fixes = (
            err.suggestion
            if isinstance(err.suggestion, (list, tuple))
            else [err.suggestion]
        )
        for s in fixes:
            parts.extend(_format_labeled_text("suggestion", str(s)))

    parts.append("")
    return "\n".join(parts)


def _format_internal_error_diagnostic(
    err: Any, frame: str | None, cause_text: str
) -> str:
    """Format internal compiler errors with a user-facing bug-report envelope."""
    # Internal errors (compiler bugs) get a "please report" envelope instead of
    # a "here's your mistake + fix" block -- they are not the author's fault.
    # Keep the same headline/source-frame/reason/suggestion grammar as compiler
    # diagnostics so backend failures and internal DSL failures are scannable in
    # the same way.
    is_verifier_error = _is_internal_verifier_error(err.message, cause_text)
    is_dominance_escape = is_verifier_error and _is_dominance_escape_cause(cause_text)
    headline = (
        "The compiler could not build valid IR for this code."
        if is_verifier_error
        else "The compiler hit an internal DSL problem while compiling your code."
    )
    parts = [
        _format_diagnostic_headline(
            "error",
            headline,
            code="INTERNAL",
            bold=True,
            leading_newline=True,
        )
    ]
    frame = frame or _internal_error_source_frame_from_cause(cause_text)
    if frame:
        parts.append(frame)

    if is_verifier_error:
        summary = _brief_internal_error(err.message)
        verifier_detail = _brief_verifier_cause(cause_text)
        if verifier_detail:
            summary = f"{summary}: {verifier_detail}"
        parts.extend(_format_labeled_text("error", summary))
        if is_dominance_escape:
            def_frame = _dominance_escape_def_frame(cause_text)
            if def_frame:
                parts.extend(
                    _format_labeled_text("note", "the escaping value is created here:")
                )
                parts.append(def_frame)
            parts.extend(
                _format_labeled_text(
                    "note",
                    "a staged value created inside a for/while/if body is used "
                    "outside that body. The tracer threads plain local variables "
                    "across staged control flow, but it cannot see rebinds made "
                    "through other channels: object attributes assigned inside "
                    "helper methods, values stashed in module-level or aliased "
                    "containers, and closure captures.",
                )
            )
    else:
        parts.extend(
            _format_labeled_text(
                "note", "This is a bug in the DSL, not a mistake in your kernel."
            )
        )
        if err.message:
            parts.extend(
                _format_labeled_text("error", _brief_internal_error(err.message))
            )
        if cause_text:
            parts.extend(_format_internal_cause(cause_text))

    if is_verifier_error:
        # A mixed *_ENABLE_PYIR configuration is the one declared config fact
        # producing this failure shape (a cross-DSL kernel compile leaves
        # region-crossing SSA behind): name it before the generic advice.
        try:
            from .pyir_state import _pyir_mixed_mode_hint

            _mode_hint = _pyir_mixed_mode_hint()
        except Exception:
            _mode_hint = None
        if _mode_hint:
            parts.extend(_format_labeled_text("suggestion", _mode_hint))
        if is_dominance_escape:
            parts.extend(
                _format_labeled_text(
                    "suggestion",
                    "Carry the value as a plain local variable rebound directly "
                    "in the loop or branch body, or re-derive it at the point of "
                    "use instead of reusing a value captured inside the region.",
                )
            )
            if not _PY_LOC_RE.search(cause_text):
                parts.extend(
                    _format_labeled_text(
                        "suggestion",
                        "Re-run with CUTE_DSL_LINEINFO=1 to see where the "
                        "escaping value is created.",
                    )
                )
        parts.extend(
            _format_labeled_text(
                "suggestion",
                "Check the source location above for invalid primitive arguments, "
                "types, or address spaces. If the code looks valid, report this "
                "with the snippet above and your kernel.",
            )
        )
    else:
        parts.extend(
            _format_labeled_text(
                "suggestion",
                "Please report this with the snippet above and your kernel.",
            )
        )
    parts.extend(
        _format_labeled_text(
            "suggestion",
            "Re-run with CUTE_DSL_SHOW_STACKTRACE=1 to include the full technical detail.",
        )
    )
    parts.append("")
    return "\n".join(parts)


def _is_internal_verifier_error(message: str, cause_text: str) -> bool:
    return (
        "ICE IR Verification Failed" in message or "Verification failed:" in cause_text
    )


def _is_dominance_escape_cause(cause_text: str) -> bool:
    """A dominance failure at trace-module verify almost always means a staged
    value leaked across region boundaries through a Python-side channel the
    tracer does not thread (attribute writes in helper methods, module-level
    or aliased containers, closure captures)."""
    return "does not dominate this use" in cause_text


def _dominance_escape_def_frame(cause_text: str) -> str | None:
    """Source frame for the verifier's 'operand defined here' note, available
    when the IR carries Python locations (PyIR trace or lineinfo builds)."""
    for line in cause_text.splitlines():
        if "operand defined here" not in line:
            continue
        loc_match = _PY_LOC_RE.search(line)
        if not loc_match:
            return None
        frame = _format_compiler_source_frame(
            loc_match.group("file"),
            int(loc_match.group("line")),
            int(loc_match.group("col")),
        )
        return "\n".join(frame) if frame else None
    return None


def _brief_internal_error(message: str) -> str:
    if "ICE IR Verification Failed" in message:
        return "IR verification failed"
    return message.strip()


def _internal_error_source_frame_from_cause(cause_text: str) -> str | None:
    loc_match = _PY_LOC_RE.search(cause_text)
    if not loc_match:
        return None
    frame = _format_compiler_source_frame(
        loc_match.group("file"),
        int(loc_match.group("line")),
        int(loc_match.group("col")),
    )
    return "\n".join(frame) if frame else None


def _clean_internal_cause_line(line: str) -> str:
    line = line.strip()
    if not line or line in {"error:", "note:"}:
        return ""
    if line.startswith("Caused exception: "):
        line = line.removeprefix("Caused exception: ").strip()
    if line == "Verification failed:":
        return ""

    loc_match = _PY_LOC_RE.search(line)
    if loc_match:
        line = line[loc_match.end() :].lstrip("): ")
    return line.strip()


def _brief_verifier_cause(cause_text: str) -> str:
    details: list[str] = []
    for line in cause_text.splitlines():
        cleaned = _clean_internal_cause_line(line)
        if not cleaned:
            continue
        if cleaned.startswith("see current operation"):
            continue
        if cleaned.startswith(": ("):
            continue
        if cleaned not in details:
            details.append(cleaned)

    return details[0] if details else ""


def _format_internal_cause(cause_text: str) -> list[str]:
    return _format_labeled_multiline_text("error", cause_text)


def _nearest_function_name(lines: list[str], line_no: int) -> str | None:
    # Function locations commonly point at the first decorator rather than the
    # ``def`` line. Resolve the containing AST node first so a decorated kernel
    # is not mislabeled as the preceding function in the file.
    try:
        tree = ast.parse("\n".join(lines))
    except (SyntaxError, ValueError):
        tree = None
    if tree is not None:
        candidates: list[tuple[int, str]] = []
        for node in ast.walk(tree):
            if not isinstance(node, (ast.FunctionDef, ast.AsyncFunctionDef)):
                continue
            start_line = min(
                (decorator.lineno for decorator in node.decorator_list),
                default=node.lineno,
            )
            end_line = node.end_lineno or node.lineno
            if start_line <= line_no <= end_line:
                candidates.append((end_line - start_line, node.name))
        if candidates:
            return min(candidates)[1]

    # Retain the old best-effort behavior for incomplete or generated sources
    # that cannot be parsed as a complete Python module.
    for idx in range(min(line_no - 1, len(lines) - 1), -1, -1):
        match = re.match(
            r"\s*(?:async\s+)?def\s+([A-Za-z_][A-Za-z0-9_]*)\(",
            lines[idx],
        )
        if match:
            return match.group(1)
    return None


def _read_source_lines(file_path: str | Path) -> list[str]:
    filename = str(file_path)
    try:
        lines = linecache.getlines(filename)
    except Exception:  # noqa: BLE001
        lines = []
    if lines:
        return [line.rstrip("\n") for line in lines]
    try:
        return Path(filename).read_text(encoding="utf-8").splitlines()
    except (OSError, UnicodeDecodeError):
        return []


def _display_column(col: int | None, *, col_zero_based: bool) -> int | None:
    if col is None:
        return None
    return col + 1 if col_zero_based else col


def _caret_column(source_line: str, col: int | None, *, col_zero_based: bool) -> int:
    if col is None:
        return len(source_line) - len(source_line.lstrip())
    return max(col if col_zero_based else col - 1, 0)


def _caret_span(
    source_line: str,
    col: int | None,
    end_col: int | None,
    *,
    col_zero_based: bool,
) -> int:
    if col is None or end_col is None:
        return 1
    start = _caret_column(source_line, col, col_zero_based=col_zero_based)
    end = end_col if col_zero_based else end_col - 1
    end = min(end, len(source_line))
    return max(1, end - start) if end > start else 1


def _format_source_location(
    filename: str,
    line: int,
    col: int | None,
    *,
    absolute_path: bool,
    col_zero_based: bool,
) -> str:
    display_path = str(Path(filename).resolve()) if absolute_path else filename
    display_col = _display_column(col, col_zero_based=col_zero_based)
    loc = f"{display_path}:{line}"
    if display_col is not None:
        loc += f":{display_col}"
    return loc


def _format_user_source_frame(
    filename: str,
    line: int,
    col: int | None,
    end_col: int | None,
    *,
    display_filename: str | None = None,
) -> list[str]:
    source_lines = _read_source_lines(filename)
    loc = _format_source_location(
        display_filename or filename,
        line,
        col,
        absolute_path=False,
        col_zero_based=True,
    )
    width = len(str(line))
    pad = " " * width
    lines = [f"{pad}{_Colors.BLUE}-->{_Colors.RESET} {loc}"]
    if not (1 <= line <= len(source_lines)):
        return lines
    source_line = source_lines[line - 1]
    if not source_line.strip():
        return lines
    caret_col = _caret_column(source_line, col, col_zero_based=True)
    span = _caret_span(source_line, col, end_col, col_zero_based=True)
    caret = f"{_Colors.RED}{'^' * span}{_Colors.RESET}"
    lines.append(f"{pad} |")
    for current in range(max(1, line - 2), line):
        context_line = source_lines[current - 1]
        lines.append(f"{current:>{width}} | {context_line}")
    lines.append(f"{line} | {source_line}")
    lines.append(f"{pad} | {' ' * caret_col}{caret}")
    return lines


def _format_compiler_source_frame(filename: str, line: int, col: int) -> list[str]:
    source_lines = _read_source_lines(filename)
    loc = _format_source_location(
        filename, line, col, absolute_path=True, col_zero_based=False
    )
    lines = ["", f"  --> {loc}"]
    fn_name = _nearest_function_name(source_lines, line)
    if fn_name:
        lines.append(
            f"      in function `{_Colors.GREEN}{fn_name}{_Colors.RESET}(...)`:"
        )
    if not source_lines:
        return lines

    start = max(1, line - _COMPILER_CONTEXT_LINES)
    end = min(len(source_lines), line + _COMPILER_CONTEXT_LINES)
    width = len(str(end))
    lines.append("   |")
    for current in range(start, end + 1):
        source_line = source_lines[current - 1]
        prefix = ">" if current == line else " "
        lines.append(f"{prefix} {current:{width}d} | {source_line}")
        if current == line:
            caret_col = _caret_column(source_line, col, col_zero_based=False)
            lines.append(f"  {' ' * width} | {' ' * caret_col}^")
    return lines


_DIAGNOSTIC_LABEL_COLORS = {
    "error": _Colors.RED,
    "warning": _Colors.YELLOW,
    "remark": _Colors.CYAN,
    "suggestion": _Colors.GREEN,
    "note": _Colors.BLUE,
}


def _diagnostic_label_prefixes(
    label: str, *, marker: str = "", prefix: str = "  "
) -> tuple[str, str]:
    plain_prefix = f"{prefix}{marker}{label}: "
    color = _DIAGNOSTIC_LABEL_COLORS.get(label, "")
    colored_label = f"{marker}{label}:"
    colored_prefix = (
        f"{prefix}{color}{colored_label}{_Colors.RESET} " if color else plain_prefix
    )
    return plain_prefix, colored_prefix


def _diagnostic_label_indent(label: str, *, marker: str = "") -> str:
    plain_prefix, _ = _diagnostic_label_prefixes(label, marker=marker)
    return " " * len(plain_prefix)


def _format_labeled_text(
    label: str, text: str, *, marker: str = "", wrap: bool = True
) -> list[str]:
    plain_prefix, colored_prefix = _diagnostic_label_prefixes(label, marker=marker)
    if not wrap:
        if not text:
            return [colored_prefix.rstrip()]
        return [colored_prefix + text]

    wrapped = textwrap.wrap(
        text,
        width=max(20, _COMPILER_DIAG_TEXT_WIDTH - len(plain_prefix)),
        break_long_words=False,
        break_on_hyphens=False,
    )
    if not wrapped:
        return [colored_prefix.rstrip()]

    lines = [colored_prefix + wrapped[0]]
    lines.extend(
        _diagnostic_label_indent(label, marker=marker) + line for line in wrapped[1:]
    )
    return lines


def _format_user_labeled_text(label: str, text: str) -> list[str]:
    return _format_labeled_text(label, text, marker="= ", wrap=False)


def _format_labeled_block(label: str, heading: str, body: str) -> list[str]:
    lines = _format_labeled_text(label, heading)
    indent = _diagnostic_label_indent(label)
    width = max(20, _COMPILER_DIAG_TEXT_WIDTH - len(indent))
    for raw_line in body.splitlines():
        if not raw_line:
            lines.append(indent.rstrip())
            continue
        wrapped = textwrap.wrap(
            raw_line,
            width=width,
            break_long_words=False,
            break_on_hyphens=False,
        )
        lines.extend(indent + line for line in wrapped)
    return lines


def _format_labeled_multiline_text(label: str, text: str) -> list[str]:
    text = text.strip()
    if "\n" not in text:
        return _format_labeled_text(label, text)
    heading, body = text.split("\n", 1)
    return _format_labeled_block(label, heading, body)


def _diagnostic_marker(severity: str, code: str = "", namespace: str = "") -> str:
    marker = severity
    if code:
        marker = (
            f"{severity}[{namespace}:{code}]" if namespace else f"{severity}[{code}]"
        )
    return marker


def _format_diagnostic_headline(
    severity: str,
    message: str,
    *,
    code: str = "",
    namespace: str = "",
    bold: bool = False,
    leading_newline: bool = False,
) -> str:
    marker = _diagnostic_marker(severity, code, namespace)
    color = _DIAGNOSTIC_LABEL_COLORS.get(severity, "")
    style = f"{color}{_Colors.BOLD if bold else ''}"
    prefix = "\n" if leading_newline else ""
    if style:
        return f"{prefix}{style}{marker}:{_Colors.RESET} {message}"
    return f"{prefix}{marker}: {message}"


def _format_compiler_diagnostic_headline(
    severity: str, message: str, code: str = "", namespace: str = ""
) -> str:
    namespace = namespace or ("nvvm-diag" if code.startswith("C") else "")
    return _format_diagnostic_headline(
        severity, message, code=code, namespace=namespace
    )


def _format_compiler_location(location: str) -> list[str]:
    if not location:
        return []

    loc_match = _PY_LOC_RE.search(location)
    if not loc_match:
        return ["", f"  --> {location}"]

    return _format_compiler_source_frame(
        loc_match.group("file"),
        int(loc_match.group("line")),
        int(loc_match.group("col")),
    )


def _format_compiler_ptx_reference(ptx_ref: str, ptx_url: str) -> list[str]:
    if not ptx_ref and not ptx_url:
        return []

    if ptx_ref and ptx_url:
        return [
            *_format_labeled_text("note", f"PTX ISA {ptx_ref}"),
            _diagnostic_label_indent("note") + f"docs: {ptx_url}",
        ]
    if ptx_ref:
        return _format_labeled_text("note", f"PTX ISA {ptx_ref}")
    return _format_labeled_text("note", f"docs: {ptx_url}")


def _format_compiler_diagnostic_body(diag: CompilerDiagnostic) -> list[str]:
    lines: list[str] = []
    if diag.reason:
        reason_label = (
            diag.severity
            if diag.severity in ("error", "warning", "remark")
            else "error"
        )
        lines.extend(_format_labeled_multiline_text(reason_label, diag.reason))
    if diag.suggestion:
        lines.extend(_format_labeled_multiline_text("suggestion", diag.suggestion))
    for note in diag.notes:
        lines.extend(_format_labeled_text("note", note))
    lines.extend(_format_compiler_ptx_reference(diag.ptx_ref, diag.ptx_url))
    return lines


def _is_concise_nvvm_backend_error(nvvm_error: str) -> bool:
    stripped = nvvm_error.strip()
    return "\n" not in stripped and stripped.startswith("Cannot select: intrinsic ")


def extract_compiler_location(text: str) -> str:
    """Return the first Python source location embedded in compiler text."""

    loc_match = _PY_LOC_RE.search(text)
    return loc_match.group(0) if loc_match else ""


def _ptxas_headline(ptxas_error: str) -> str:
    """Promote the first actionable `ptxas fatal` line into the headline.

    ptxas always follows a real diagnostic with the generic "Ptx assembly
    aborted due to errors" trailer, which carries no information; skip it so the
    headline names the actual problem.
    """

    for match in _PTXAS_FATAL_RE.finditer(ptxas_error):
        text = match.group("text").strip()
        if text and _PTXAS_GENERIC_FATAL not in text:
            return f"PTX assembly failed: {text}"
    return "PTX assembly failed"


def _ptxas_suggestion(ptxas_error: str, arch: str) -> str:
    if _PTXAS_REGISTER_ALLOCATION_RE.search(ptxas_error):
        return (
            "the kernel needs more registers than its launch configuration allows; "
            "reduce register pressure or shorten live ranges, reduce the CTA thread "
            "count, or, if the kernel uses dynamic warpgroup register redistribution, "
            "relax or remove `warpgroup_reg_dealloc` or use an appropriate "
            "`warpgroup_reg_alloc` scheme"
        )
    arch_flag = f" -arch={arch}" if arch else ""
    return (
        "read the ptxas log above; re-run with CUTE_DSL_KEEP=ptx and assemble the "
        f"dumped PTX with `ptxas{arch_flag} <dumped>.ptx` to iterate on the failure"
    )


def _format_ptxas_backend_failure(*, ptxas_error: str, arch: str, location: str) -> str:
    """Render a PTX -> SASS failure using the assembler's own log.

    ptxas is the last device compilation stage, so its log is the only account of
    what went wrong; reproduce it verbatim rather than summarizing it.
    """

    ptxas_error = ptxas_error.strip()
    lines = [
        _format_compiler_diagnostic_headline("error", _ptxas_headline(ptxas_error))
    ]
    lines.extend(_format_compiler_location(location))
    lines.extend(
        _format_labeled_text(
            "error",
            "ptxas rejected the PTX generated for this kernel while compiling it "
            "to SASS.",
        )
    )
    if arch:
        lines.extend(_format_labeled_text("note", f"target architecture: {arch}"))
    lines.extend(_format_labeled_block("note", "ptxas log:", ptxas_error))
    lines.extend(
        _format_labeled_text("suggestion", _ptxas_suggestion(ptxas_error, arch))
    )
    return "\n".join(lines)


def format_compiler_backend_failure(
    *,
    raw_error: str,
    nvvm_error: str = "",
    ptxas_error: str = "",
    ir_context: str = "",
    arch: str = "",
    location: str = "",
) -> str:
    """Render an unstructured backend failure with compiler diagnostic styling."""

    if ptxas_error:
        return _format_ptxas_backend_failure(
            ptxas_error=ptxas_error, arch=arch, location=location
        )

    is_nvvm_failure = bool(nvvm_error)
    concise_nvvm_error = is_nvvm_failure and _is_concise_nvvm_backend_error(nvvm_error)
    headline = (
        f"NVVM backend compilation failed: {nvvm_error.strip()}"
        if concise_nvvm_error
        else "NVVM backend compilation failed"
        if is_nvvm_failure
        else "compiler backend failed"
    )
    lines = [_format_compiler_diagnostic_headline("error", headline)]
    lines.extend(_format_compiler_location(location))
    reason = (
        ""
        if concise_nvvm_error
        else "libNVVM failed while compiling generated device IR."
        if is_nvvm_failure
        else "the compiler backend failed while compiling generated device code."
    )
    if reason:
        lines.extend(_format_labeled_text("error", reason))

    labeled_blocks: list[tuple[str, str]] = []
    if nvvm_error and not concise_nvvm_error:
        labeled_blocks.append(("backend log:", nvvm_error.strip()))
    elif raw_error and not concise_nvvm_error:
        labeled_blocks.append(("raw compiler error:", raw_error.strip()))
    if ir_context and not concise_nvvm_error:
        labeled_blocks.append(("IR context (truncated):", ir_context.strip()))

    if arch:
        lines.extend(_format_labeled_text("note", f"target architecture: {arch}"))
    for heading, body in labeled_blocks:
        if body:
            lines.extend(_format_labeled_block("note", heading, body))

    suggestion = "check that CUDA_TOOLKIT_PATH is set correctly"
    if arch:
        suggestion += f" and that the CUDA toolkit supports target architecture {arch}"
    suggestion += "; rerun with IR dump flags if backend context is needed"
    lines.extend(_format_labeled_text("suggestion", suggestion))
    return "\n".join(lines)


# Argument-key prefix the compiler reserves for located notes. Kept in sync
# with kNotePrefix in the compiler's Remark.h.
_REMARK_NOTE_PREFIX = "note "


def _remark_notes(item: Mapping[str, Any]) -> tuple[str, ...]:
    """Recover attached notes from a collected remark's argument channel.

    The engine has no dedicated note field, so ``reportError`` and friends
    emit each note as a generic key/value argument under the reserved
    ``note NNN`` key namespace; the keys are zero-padded so sorting them
    restores emission order."""
    metrics = item.get("metrics") or {}
    if not isinstance(metrics, Mapping):
        return ()
    return tuple(
        str(value)
        for key, value in sorted(metrics.items())
        if str(key).startswith(_REMARK_NOTE_PREFIX) and value
    )


def compiler_diagnostic_from_remark(
    item: Mapping[str, Any],
) -> CompilerDiagnostic | None:
    diag_class = str(item.get("diag_class", ""))
    name = str(item.get("name", ""))
    if diag_class == "Error":
        severity = "error"
    elif diag_class == "Warning":
        severity = "warning"
    elif diag_class == "OptRemark":
        # Opt-in remarks (perf / optimization / analysis). Rendered through the
        # same path as errors/warnings, labeled remark[<category>]. Which
        # remarks reach here is gated by the remark filter at collection time
        # (see enable_compiler_diagnostics), so this does not flood by default.
        severity = "remark"
    else:
        return None

    ptx_ref = ""
    ptx_url = ""
    namespace = ""
    if severity == "remark":
        # Remarks are keyed by their category (e.g. "ptxas"), not the
        # error/warning code table.
        code = str(item.get("category", "")) or name
    else:
        # The table supplies a curated code (and its PTX cross-reference) for
        # the diagnostics that have one. Otherwise the catalog NAME is the
        # code: it is what the user quotes in a bug report, and unlike the
        # packed id it does not depend on a table maintained here — which is
        # what lets a catalog owned by another tree grow without a DSL edit.
        # The packed id remains the last resort, for an unnamed diagnostic.
        info = _COMPILER_DIAGNOSTICS.get(name)
        code = info.code if info else (name or str(item.get("remark_id", "")))
        namespace = info.namespace if info else ""
        ptx_ref = info.ptx_ref if info else ""
        ptx_url = info.ptx_url if info else ""
    return CompilerDiagnostic(
        severity=severity,
        message=str(item.get("message", "")),
        code=code,
        namespace=namespace,
        name=name,
        location=str(item.get("location", "")),
        reason=str(item.get("reason", "")),
        suggestion=str(item.get("suggestion", "")),
        ptx_ref=ptx_ref,
        ptx_url=ptx_url,
        notes=_remark_notes(item),
    )


def format_compiler_diagnostics(diagnostics: Sequence[CompilerDiagnostic]) -> str:
    blocks: list[str] = []
    for diag in diagnostics:
        lines = [
            _format_compiler_diagnostic_headline(
                diag.severity, diag.message, diag.code, diag.namespace
            )
        ]
        lines.extend(_format_compiler_location(diag.location))
        lines.extend(_format_compiler_diagnostic_body(diag))
        blocks.append("\n".join(lines))
    return "\n\n".join(blocks)


def _clean_raw_compiler_message(text: str) -> str:
    text = text.strip()
    loc_match = _PY_LOC_RE.search(text)
    if loc_match:
        text = text[loc_match.end() :].lstrip("): ")
    return text.strip()


def _raw_pass_failure_diagnostic(raw_error: str) -> CompilerDiagnostic | None:
    if "Failure while executing pass pipeline" not in raw_error:
        return None

    location = extract_compiler_location(raw_error)
    reason = ""
    notes: list[str] = []
    for raw_line in raw_error.splitlines():
        line = raw_line.strip()
        if line.startswith("error:"):
            candidate = _clean_raw_compiler_message(line.removeprefix("error:"))
            if candidate and not reason:
                reason = candidate
        elif line.startswith("note:"):
            candidate = _clean_raw_compiler_message(line.removeprefix("note:"))
            if candidate and not candidate.startswith("see current operation"):
                notes.append(candidate)

    if not reason:
        reason = raw_error.strip()
    return CompilerDiagnostic(
        severity="error",
        message="compiler pass failed",
        name=_GENERIC_MLIR_DIAGNOSTIC,
        location=location,
        reason=reason,
        notes=tuple(notes),
    )


def format_compiler_failure_diagnostics(
    diagnostics: Sequence[CompilerDiagnostic], raw_error: str
) -> str:
    diagnostics = _dedupe_compiler_diagnostics(diagnostics)
    formatted = format_compiler_diagnostics(diagnostics)
    if not formatted:
        raw_diagnostic = _raw_pass_failure_diagnostic(raw_error)
        if raw_diagnostic is not None:
            return format_compiler_diagnostics([raw_diagnostic])
        return ""
    if raw_error and any(
        diag.name == _DEVICE_BINARY_SERIALIZATION_DIAGNOSTIC for diag in diagnostics
    ):
        raw_block = "\n".join(
            _format_labeled_block("note", "raw compiler error:", raw_error.strip())
        )
        return f"{formatted}\n{raw_block}"
    if any(diag.severity == "error" for diag in diagnostics) or not raw_error:
        return formatted
    failure_headline = _format_compiler_diagnostic_headline(
        "error", "compiler pass failed before a structured error was collected"
    )
    return f"{formatted}\n\n{failure_headline}\n{raw_error}"


class _MissingField:
    """Renders a not-supplied ``{field}`` back as the literal placeholder.

    A diagnostic must never crash the compile it is trying to explain, so a
    template referencing a field the call site forgot degrades to showing the
    raw ``{field}`` (caught by tests) instead of raising ``KeyError``.
    """

    __slots__ = ("key",)

    def __init__(self, key: str) -> None:
        self.key = key

    def __format__(self, spec: str) -> str:
        return "{" + self.key + (":" + spec if spec else "") + "}"

    def __str__(self) -> str:
        return "{" + self.key + "}"


class _SafeFields(dict):
    def __missing__(self, key: str) -> "_MissingField":
        return _MissingField(key)


class _DiagMixin:
    """Shared behaviour for the diagnostic catalogs (:class:`DiagId` errors and
    :class:`WarnId` warnings).

    Both are ``enum.Enum``s whose member **name** is the stable code and whose
    value is ``(message_template, (fix_line, ...))``.  This mix-in supplies the
    code/category/message/fix accessors and ``_fill`` (template substitution);
    each enum adds its own ``format``/``format_warning`` for the code label.
    """

    # ``name`` and ``value`` are supplied by ``enum.Enum`` at runtime (this
    # mix-in is combined with ``enum.Enum`` in DiagId/WarnId); declared here so
    # the accessor bodies below type-check.
    name: str
    value: Any  # the (message_template, (fix_line, ...)) tuple, per enum member

    @property
    def code(self) -> str:
        """The stable, human-readable code shown to the user (the name)."""
        return self.name

    @property
    def category(self) -> str:
        """High-level group, derived from the name prefix (PHASE / TYPE / ...)."""
        return self.name.split("_", 1)[0]

    @property
    def message(self) -> str:
        return self.value[0]

    @property
    def fix(self) -> tuple[str, ...]:
        return self.value[1]

    def fill(self, **fields: Any) -> tuple[str, tuple[str, ...]]:
        """Fill the templates and return ``(message, fixes)``.

        No code suffix -- the stable code (``.code``) is shown separately in the
        ``error[CODE]:`` / ``warning[CODE]:`` header.  The two
        value-phase names :data:`META_VALUE` / :data:`STAGED_VALUE` are always
        available as ``{meta}`` / ``{staged}``; a field a call site forgot
        degrades to the literal ``{field}`` instead of crashing (see
        :class:`_SafeFields`)."""
        fields.setdefault("meta", META_VALUE)
        fields.setdefault("staged", STAGED_VALUE)
        # Optional enrichment field: templates may reference ``{detail}`` to show
        # what concretely changed (e.g. old vs new structure/type); default empty
        # so call sites that omit it render cleanly.
        fields.setdefault("detail", "")
        safe = _SafeFields(fields)
        message = self.message.format_map(safe)
        fixes = tuple(f.format_map(safe) for f in self.fix)
        return message, fixes


class DiagId(_DiagMixin, enum.Enum):
    """User-facing diagnostics: member name == stable code, value == (message, fix).

    Naming convention ``<CATEGORY>_<rest>`` -- CATEGORY is one of
    PHASE / TYPE / SCOPE / CONTAINER / UNSUP / ARG / CALL / CONFIG / LAUNCH /
    TENSOR / AOT and is what ``.category`` returns.  Keep the prefix when adding
    entries.  Internal/compiler errors do not live here -- raise
    ``DSLRuntimeError`` for those.
    """

    PHASE_ASSIGN_PYTHON_TO_TRACKED = (
        "`{var}` is a {staged}, but a {meta} is being assigned to it inside a "
        "for/while/if. Only a {staged} can be used there.",
        (
            "Wrap the value in a runtime type, e.g. Int32(...), Float32(...), or "
            "Boolean(...).",
        ),
    )
    PHASE_MUTATE_PYTHON = (
        "`{var}` is a {meta}, but it is being changed inside a for/while/if whose "
        "path is decided at run time. A {meta} is fixed once your code is read and "
        "cannot change there.",
        (
            "If `{var}` must change there, create it as a {staged} first, e.g. "
            "`{var} = Int32(0)`, then update it.",
            "If it is a fixed setting, set it once before the for/while/if.",
        ),
    )
    PHASE_AUTO_PROMOTE_DISABLED = (
        "`{var}` (a {meta}, value {value}) is updated inside a for/while/if "
        "whose path is decided at run time. Keeping it correct there requires "
        "promoting it to a {staged}, and automatic Meta-to-Staged promotion "
        "is disabled (`CUTE_DSL_AUTO_M2S` is off, the default). Without the "
        "promotion the compiler traces the body once and later iterations "
        "would silently observe a wrong value, so it refuses instead.",
        (
            "Make `{var}` a {staged} before the for/while/if, e.g. "
            "`{var} = {type}(...)`, so the update is tracked explicitly.",
            "Or opt in to automatic promotion with `CUTE_DSL_AUTO_M2S=True`.",
            "If the for/while/if only depends on Python values, make it "
            "trace-time with `while cutlass.const_expr(...)` / "
            "`for ... in cutlass.range_constexpr(...)` so `{var}` stays a {meta}.",
        ),
    )
    PHASE_PYTHON_THEN_TRACKED = (
        "`{var}` was defined as a {meta} (type {old_type}, value {old_value}) but "
        "is being assigned a {staged} inside a for/while/if. Give it a runtime type "
        "from the start so it has one consistent type.",
        (
            "Initialize `{var}` as a {staged} before the for/while/if, e.g. "
            "`{var} = Int32(0)`.",
        ),
    )
    TYPE_UNSTABLE_JOIN = (
        "`{var}` has type `{old_type}` on one path and `{new_type}` on another. "
        "Where the paths come back together, both versions must be the same type.",
        (
            "Make every assignment to `{var}` produce the same type.",
            "If you need a conversion, convert it explicitly inside the branch so the "
            "result is consistently one type.",
        ),
    )
    SCOPE_DEL_LOOP_CARRIED = (
        "`{var}` is removed with `del` inside a for/while/if, but it carries a "
        "value in from before the block. Deleting it drops that carry, so the "
        "next read of `{var}` (this pass or the next) has no value to use.",
        (
            "Don't `del` a variable carried through the block; assign it a new "
            "value instead, or move the `del` outside the for/while/if.",
        ),
    )
    SCOPE_READ_NEVER_SET = (
        "A variable is read on a path where it was never given a value{detail}. "
        "It must be set before it is read, on every path that can reach this "
        "point.",
        (
            "Set the variable before the for/while/if, or set it on every branch "
            "that can reach this read.",
        ),
    )
    SCOPE_UNBOUND_NAME_IN_TRACE = (
        "`{var}` is read here but was never given a value on the traced path.",
        (
            "Set `{var}` before this read on every path that can reach it (a "
            "branch selected off at trace time does not bind it).",
        ),
    )
    SCOPE_WALRUS_IN_WHILE_CONDITION = (
        "`{name}` is bound by `:=` inside this `while` condition and has no "
        "value before the loop, so the compiled loop cannot carry it into the "
        "body or past the loop.",
        (
            "Give `{name}` an initial value of the same type before the `while`; "
            "the `({name} := ...)` condition then rebinds it every round.",
        ),
    )
    SCOPE_LOCALS_SYNTH_MISS = (
        "`locals()` inside a rewritten if/ifexp/while arm sees only the names "
        "the arm rebinds, and `{name}` is not one of them -- the source "
        "program's `locals()` would see the whole function scope, so this "
        "lookup cannot be answered faithfully.",
        (
            "Read `{name}` directly instead of through `locals()`, or call "
            "`locals()` outside the for/while/if arm.",
        ),
    )
    MEMREF_INREGION_ALLOC_REBIND = (
        "`{name}` is re-pointed inside staged control flow ({region_kind}) "
        "to a handle rooted at memory ALLOCATED inside the region, and the "
        "escape cannot be proven faithful: the previous handle is still "
        "held by another live binding, the handle is a raw pointer or view "
        "(no declared memory-space fact), or the space is not per-thread "
        "registers. In-region allocations are hoisted to ONE function-entry "
        "buffer when lowering, so an escaped old handle would alias the "
        "fresh buffer and observe its overwrites instead of the buffer "
        "Python named.",
        (
            "Drop the extra binding of the old buffer (finish reading it "
            "before re-pointing `{name}`), carry the tensor itself instead "
            "of a raw pointer or view into it, allocate the backing memory "
            "once outside the dynamic region and write `{name}` in place, "
            "or make the selection a Python-time (constexpr) branch.",
        ),
    )
    MEMREF_STALE_SCRATCH_CONSUMED = (
        "`{name}` holds iteration-private scratch memory (re-pointed inside "
        "staged control flow) and a superseded handle to it escapes that "
        "iteration's window at {consumer_loc}. All in-region allocations "
        "alias ONE function-entry buffer when lowering, so the escaped "
        "handle would observe later overwrites instead of the buffer Python "
        "read.",
        (
            "Consume the scratch inside the iteration that filled it "
            "(before the next re-point), or allocate the backing memory "
            "once outside the dynamic region and write `{name}` in place.",
        ),
    )
    BOUNDARY_HOST_STATE_IN_STAGED_CF = (
        "`{name}` is {kind} that advanced inside this for/while/if body "
        "(through `{callee}`). The body is traced once, so the compiled "
        "program would replay the first trace-time transition on every "
        "runtime execution instead of advancing it.",
        (
            "Compute the value outside the for/while/if, or carry it as a "
            "Runtime value (e.g. an `Int32` counter or index into staged data).",
            "If it is trace-time configuration that never feeds computed "
            "values, move its use out of runtime control flow.",
        ),
    )
    BOUNDARY_META_LOOP_CARRY = (
        "`{name}` is a Python value changed inside this for/while body by "
        "code the compiler cannot see (a plain, non-jit method or function). "
        "Its per-iteration update ran on plain Python values, so the carried "
        "update cannot be reconstructed -- iterations after the first would "
        "silently observe a wrong value.",
        (
            "Decorate the function that updates `{name}` with the DSL's jit "
            "decorator so the update is tracked, or make `{name}` a Runtime "
            "value (Staged value) before the loop, e.g. `Int32(...)`.",
        ),
    )
    BOUNDARY_REPLACED_OBJECT_ALIASED = (
        "`{name}` was rebound inside this for/while/if body (through "
        "`{callee}`) to {what}. The compiler keeps one storage cell per field "
        "path, so the two objects would share cells and observe each other's "
        "writes.",
        (
            "Update the existing object's fields in place instead of rebinding "
            "the field to another object.",
            "Drop every other reference to the previous object before "
            "rebinding, or rebuild the object outside runtime control flow.",
        ),
    )
    BOUNDARY_FLIP_GUARD_STAGED = (
        "`{name}` is now being changed to a Runtime value, but it gates an "
        "update of `{flipped}` performed by a plain, non-jit function "
        "(defined at {def_file}:{def_line}) inside a for/while body. That "
        "update was compiled as an unconditional per-iteration store on the "
        "proof that `{name}` never changes during the loop; changing it "
        "breaks that proof, so iterations could silently observe a wrong "
        "`{flipped}`.",
        (
            "Decorate the function that updates `{flipped}` with the DSL's "
            "jit decorator so the update is tracked, or make both `{name}` "
            "and `{flipped}` Runtime values (Staged values) before the loop.",
        ),
    )
    BOUNDARY_CLOSURE_READ_THEN_PROMOTED = (
        "`{name}` is read through a closure by a plain, non-jit function "
        "(defined at {def_file}:{def_line}) inside staged control flow, and "
        "is now being changed so it must become a Runtime value. That "
        "closure read ran on the plain Python value and was baked into the "
        "kernel at its trace-time value; no rewrite can retarget it to the "
        "staged update, so every use would keep observing the old value -- "
        "matching Python for some runtime inputs and silently diverging for "
        "others.",
        (
            "Decorate the function that reads `{name}` with the DSL's jit "
            "decorator, pass `{name}` to it as an argument, or make it a "
            "Runtime value (e.g. `{name} = Int32({name})`) before the first "
            "call.",
        ),
    )
    BOUNDARY_CLOSURE_READ_THEN_WRITTEN = (
        "`{name}` is changed here inside staged control flow, but it was "
        "already read through a closure by a plain, non-jit function "
        "(defined at {def_file}:{def_line}). That closure read ran on the "
        "plain Python value and was baked into the kernel at its trace-time "
        "value; no rewrite can retarget it to the staged update, so every "
        "use would keep observing the old value -- matching Python for some "
        "runtime inputs and silently diverging for others.",
        (
            "Decorate the function that reads `{name}` with the DSL's jit "
            "decorator so the read is tracked, or make `{name}` a Runtime "
            "value (Staged value) before the plain function reads it.",
        ),
    )
    PHASE_OPAQUE_READ_THEN_PROMOTED = (
        "`{var}` is changed inside a for/while whose trip count is decided at "
        "run time, so it must become a Runtime value (Staged value) that is "
        "carried from one iteration to the next -- but its previous value was "
        "read as a plain Python number by {reader}, through an operation the "
        "compiler cannot see (for example a float or bool on the LEFT of the "
        "operator, `abs()`, `-x`, or a C-level builtin). That read is fixed "
        "at its trace-time value, so every iteration would compute from the "
        "first iteration's value and the update would never accumulate.",
        (
            "Make `{var}` a Runtime value (Staged value) before the for/while, "
            "e.g. `{var} = Int32({var})`, so every read of it is a runtime load.",
            "Or put the Python value on the RIGHT of the operator (`x + 2.5` "
            "instead of `2.5 + x`) and avoid `int()`/`abs()` on it inside the "
            "loop, so the read stays visible to the compiler.",
        ),
    )
    SCOPE_ABSENT_PROBE_THEN_BOUND = (
        "`{var}` is probed as absent ({probe} at {probe_file}:{probe_line}) "
        "and then bound for the first time inside the same for/while whose "
        "trip count is decided at run time. The body ran once at compile "
        "time, so the probe's answer is fixed to the first iteration's "
        "(absent) while Python would find `{var}` present on every later "
        "iteration -- the kernel would repeat the first iteration's "
        "branch or default value.",
        (
            "Bind `{var}` before the for/while (e.g. `{var} = 0`) so every "
            "iteration reads a tracked value instead of probing for presence.",
            "If the for/while is compile-time, use `range_constexpr(...)` so "
            "each iteration is traced separately.",
        ),
    )
    BOUNDARY_SHORT_CIRCUIT_EFFECT = (
        "`{name}` is changed by a call inside a short-circuited `and`/`or` "
        "operand. The trace evaluates that operand exactly once, so the "
        "change cannot be conditioned on the runtime value of the guarding "
        "expression -- it would apply unconditionally, silently.",
        (
            "Move the call out of the `and`/`or` expression to its own "
            "statement, or guard it with an explicit `if`.",
        ),
    )
    BOUNDARY_CALLEE_SOURCE_UNAVAILABLE = (
        "`{name}` is called inside staged (runtime) control flow, but its "
        "Python source is not available to the compiler (generated code, a "
        "REPL/exec definition, or several definitions sharing one line), so "
        "the state it updates cannot be observed at this position.",
        (
            "Define `{name}` in a .py file on its own line, or hoist the call "
            "out of the staged for/while/if.",
        ),
    )
    STATE_FROM_PREVIOUS_COMPILATION = (
        "`{name}` holds a value computed by a previous compilation of a kernel: "
        "its backing IR belongs to that finished compilation, so this "
        "compilation can neither read it nor carry it.",
        (
            "Reset the object's fields before compiling again, or pass the value "
            "in as a kernel argument.",
        ),
    )
    BOUNDARY_MEMOIZED_IN_STAGED_CF = (
        "`{name}` is a functools.lru_cache-wrapped function called inside "
        "staged (runtime) control flow. A cache hit at trace time skips the "
        "wrapped body, so its work cannot be replayed for each runtime "
        "execution of this region -- executions after the first would "
        "silently observe stale effects.",
        (
            "Hoist the `{name}` call out of the staged for/while/if, or call "
            "the undecorated function (`{name}.__wrapped__`) inside the "
            "kernel.",
        ),
    )
    BOUNDARY_BUILTIN_SUBCLASS_ATTR_CHANGED = (
        "`{name}` is an attribute stored on a `{type}` instance (a `{base}` "
        "subclass) and it {what} inside this for/while/if body (through "
        "`{callee}`). Per-instance attributes of a builtin-container subclass "
        "are not storage cells the compiler carries: the body is traced once, "
        "so the write would run at trace time only and every runtime pass "
        "would observe that one value.",
        (
            "Keep per-pass state in the container's items or on a plain class "
            "instance instead of as an attribute of the `{base}` subclass "
            "instance.",
            "If `{name}` is trace-time configuration, set it before the "
            "for/while/if and do not change it inside.",
        ),
    )
    BOUNDARY_EXACT_CONTAINER_TYPE_PROBED = (
        "`{callee}` is a plain (non-jit) function that tests the exact type of "
        "a value against `dict`/`list` (`type(...) is dict`), and it can reach "
        "`{name}`, a tracked {kind}. The compiler tracks a dict/list through a "
        "subclass of the builtin type, so at trace time the exact-type test "
        "takes the branch plain Python would not take and the compiled program "
        "diverges from it.",
        (
            "Test with `isinstance(value, dict)` / `isinstance(value, list)`: a "
            "tracked container is still an instance of its builtin type.",
            "Or move the exact-type test out of the jit-compiled function.",
        ),
    )
    BOUNDARY_NATIVE_REJECTED_STAGED = (
        "native code raised `{exc}` while the compiler ran `{callee}` with "
        "{vars} as a {staged}. A C-level API that needs a plain Python value "
        "(an iterator `__setstate__`, a member or slot setter, a struct pack) "
        "rejects a runtime value; Python runs the same call on plain values, "
        "so the result the untraced code would compute cannot be reproduced.",
        (
            "Keep the value the native call receives a {meta}: update it "
            "outside the runtime for/while/if, or move the native call out of "
            "the compiled body.",
            "If the value must change per iteration, replace the native call "
            "with DSL arithmetic on `Int32`/`Boolean` values, or decorate "
            "`{callee}` with the DSL's jit decorator so each operation inside "
            "it is diagnosed individually.",
        ),
    )
    PHASE_META_FIELD_CHANGED_IN_CF = (
        "Meta-primitive field `{owner_class}.{attr}` cannot change across "
        "iterations of staged control flow ({old_value!r} -> {new_value!r}). "
        "The compiler traces the body only once and would silently discard "
        "later changes.",
        (
            "Use a DSL Numeric type for `{attr}` so it is tracked by "
            "`pyir.ref`, or hoist the assignment outside staged control "
            "flow.",
        ),
    )
    CONTAINER_META_REBUILT_IN_CF = (
        "The {kind} field `{var}` holds plain Python values (Meta values) "
        "and is rebuilt inside staged control flow ({old_value!r} -> "
        "{new_value!r}). The compiler traces the body only once, so the "
        "rebuilt {kind} would silently keep its first-iteration values.",
        (
            "Initialize the {kind} with DSL Numeric values (e.g. "
            "`Int32(0)`) so each element is tracked. In a staged `for` "
            "body, `CUTE_DSL_AUTO_M2S=True` promotes the elements "
            "automatically.",
            "If the {kind} is trace-time structure, rebuild it in a "
            "`range_constexpr(...)` loop instead.",
        ),
    )
    CONTAINER_SET_REBUILT_IN_CF = (
        "The set field `{var}` is rebuilt inside staged control flow "
        "({old_value!r} -> {new_value!r}). Set members are compile-time "
        "structure (hashing and membership are decided while tracing), so "
        "the rebuilt set would silently keep its first-iteration members.",
        (
            "Store per-iteration runtime values in a tuple, list, or dict "
            "field instead; a set cannot hold runtime values.",
            "If the set is trace-time structure, rebuild it in a "
            "`range_constexpr(...)` loop instead.",
        ),
    )
    UNSUP_META_CONTAINER_MUTATION = (
        "In-place mutation `{container}.{method}(...)` of a meta Python "
        "{kind} is not allowed inside staged control flow. The compiler "
        "traces the body once and would silently discard the per-iteration "
        "mutation.",
        (
            "Build the {kind} before the staged region, or use a DSL "
            "collection/struct type that the compiler can track for "
            "accumulation.",
        ),
    )
    SCOPE_READ_OF_SUPERSEDED_GENERATION = (
        "`{var}` is {access} through an object that was replaced by a whole-object "
        "assignment{detail}. The compiler keeps ONE live storage cell per field "
        "across such a replacement, so keeping BOTH the old and the new object "
        "alive does not work: this access would silently observe the replacing "
        "object's current value instead of the value the old object held when it "
        "was captured.",
        (
            "Copy the fields you need into plain locals BEFORE the whole-object "
            "assignment, e.g. `saved = obj.field`.",
            "Or access the field through the live binding instead of the retained "
            "handle.",
        ),
    )
    SCOPE_REBIND_IDENTITY_RUNTIME_DEPENDENT = (
        "`{var}` is rebound inside staged control flow to a `{cls}` object in a "
        "way the compiler cannot follow as a trace-time object identity: "
        "{detail}. Assigning an object that already existed when the region "
        "started makes `{var}` name that very object, exactly as in Python, only "
        "when the choice is the same on every run-time path; following a "
        "run-time identity would need a selector at every later use, so it is "
        "refused.",
        (
            "{hint}",
            "Or copy the fields explicitly (`{var}.field = other.field`), or bind a "
            "copy (`{var} = other.clone()`), which is carried per field.",
        ),
    )
    CONTAINER_TUPLE_LENGTH_CHANGED = (
        "`{var}` is a tuple with {old} item(s) on one pass and {new} on another. A "
        "tuple must keep the same number of items every pass so its parts can be "
        "followed.",
        ("Keep `{var}` the same length on every branch and every loop pass.",),
    )
    CONTAINER_TUPLE_SUBCLASS_NOT_REBUILDABLE = (
        "A `{type}` value carried through a for/while/if must be rebuilt from "
        "its parts, but `{type}` cannot be reconstructed that way{detail}. "
        "Rebuilding it as a plain tuple would silently drop its named fields / "
        "methods, so this is refused.",
        (
            "Use a `typing.NamedTuple` (or a plain tuple) for values carried "
            "through a for/while/if.",
            "Or give `{type}` a constructor that accepts the item iterable "
            "(like `tuple` itself) and no extra per-instance state.",
        ),
    )
    CONTAINER_STRUCTURE_CHANGED = (
        "`{var}` has a different structure at the end of this `{op_type}` than at "
        "the start{detail}. A value carried through a `{op_type}` must keep the same "
        "shape (same fields and the same number of parts) on every pass.",
        (
            "Give `{var}` the same structure on every branch and every pass of the "
            "`{op_type}`.",
        ),
    )
    CONTAINER_OBJECT_FIELD_MISMATCH = (
        "`{var}` is replaced inside a for/while/if with an object that has a "
        "different set of fields ({detail}). Replacement only works when the new "
        "object has exactly the same fields.",
        (
            "Update the individual fields of `{var}` instead of replacing the whole "
            "object, or make the new object carry exactly the same fields.",
        ),
    )
    CONTAINER_OBJECT_PROTOTYPE_MISMATCH = (
        "`{var}` is replaced inside an `if` decided at run time by a `{type}` "
        "whose compile-time fields differ from the one it held ({detail}), and "
        "whose runtime fields cannot be joined through the `if` ({leaf_detail}). "
        "The `if` carries the runtime fields of the two objects one-to-one and "
        "keeps the compile-time fields of the object `{var}` held before the "
        "`if`; a runtime field must have the same type on both paths.",
        (
            "Build both objects so their runtime fields line up with the same "
            "types, or update those fields in place in each branch "
            "(`{var}.field = other.field`).",
            "Or choose the object with a compile-time condition (`const_expr`) "
            "before the `if`.",
        ),
    )
    CONTAINER_OBJECT_REPLACED = (
        "`{var}` is replaced as a whole object inside a for/while/if, but it holds "
        "runtime values that cannot be followed through a whole-object replacement.",
        (
            "Update the individual fields of `{var}` instead, e.g. "
            "`{var}.field = new_value`.",
        ),
    )
    CONTAINER_REBOUND_TO_RUNTIME_VALUE = (
        "`{var}` holds a Python {old_type} ({old_value}) and is re-bound to a "
        "runtime {new_type} inside a for/while/if whose path is decided at run "
        "time. A container has no runtime counterpart, so the two shapes "
        "cannot be joined at the end of the region.",
        (
            "Bind the runtime value to a NEW name instead of re-using `{var}`, "
            "e.g. `first, second = {var}`.",
            "Or give `{var}` the same shape on every path: build it before the "
            "for/while/if and update its parts inside.",
        ),
    )
    CONTAINER_DICT_META_WRITE_UNPROMOTED = (
        "`{var}` is a dict entry holding a {meta} (value {old_value}) that is "
        "changed (to {new_value}) inside a for/while/if whose path is decided at "
        "run time, but no earlier use let the compiler promote it to a {staged}. "
        "The body runs once at compile time, so the per-iteration change would be "
        "silently discarded.",
        (
            "Store a {staged} in the entry from the start, e.g. "
            "`{var} = Int32(0)`, so updates inside the for/while/if are tracked.",
            "If the entry is a fixed compile-time setting, set it once before the "
            "for/while/if.",
        ),
    )
    CONTAINER_DICT_KEY_SET_MUTATED = (
        "the key set of dict `{var}` is changed ({detail}) inside a for/while/if "
        "whose path is decided at run time. The body runs once at compile time, so "
        "a per-iteration key insertion/removal would be silently discarded.",
        (
            "Create every key before the for/while/if and update the VALUES inside it.",
            "If the loop is a compile-time unroll, use `range_constexpr` so the "
            "mutation is realized at trace time.",
        ),
    )
    CONTAINER_DICT_VIEW_ALIAS_IN_STAGED_CF = (
        "`{var}` is a {kind} taken over tracked dict `{target}` and is reachable "
        "inside a for/while/if whose path is decided at run time. The view reads "
        "the dict's raw compile-time storage, so an entry written or a key "
        "created inside the body would not be observed through it -- the kernel "
        "would read the contents the view held when it was taken.",
        (
            "Read the dict itself (`{target}[key]`, `len({target})`) instead of "
            "the view, or take the view after the for/while/if.",
        ),
    )
    CONTAINER_DICT_KEY_STAGED = (
        "a {staged} is used as a dict KEY on tracked dict `{var}`. Keys name "
        "compile-time storage places, so they must be fixed Python values "
        "(str/int/tuple); a runtime value cannot name a place.",
        (
            "Use a compile-time key (a Python str/int), or restructure so the "
            "runtime value is the ENTRY, not the key.",
        ),
    )
    CONTAINER_DICT_KEY_STAGED_HASH = (
        "the `__hash__` of a KEY on tracked dict `{var}` consumed a {staged}. "
        "Keys name compile-time storage places, so a key whose hash is derived "
        "from a runtime value cannot name a place.",
        (
            "Hash only fixed Python values in the key's `__hash__`, or use a "
            "compile-time key (a Python str/int) and keep the runtime value as "
            "the ENTRY, not the key.",
        ),
    )
    CONTAINER_LIST_META_WRITE_UNPROMOTED = (
        "`{var}` is a list element holding a {meta} (value {old_value}) that is "
        "changed (to {new_value}) inside a for/while/if whose path is decided at "
        "run time, but no earlier use let the compiler promote it to a {staged}. "
        "The body runs once at compile time, so the per-iteration change would be "
        "silently discarded.",
        (
            "Store a {staged} in the element from the start, e.g. "
            "`{var} = Int32(0)`, so updates inside the for/while/if are tracked.",
            "If the element is a fixed compile-time setting, set it once before "
            "the for/while/if.",
        ),
    )
    CONTAINER_LIST_SHAPE_MUTATED = (
        "the length or element order of list `{var}` is changed ({detail}) inside "
        "a for/while/if whose path is decided at run time. The body runs once at "
        "compile time, so a per-iteration append/remove/reorder would be silently "
        "discarded.",
        (
            "Build the list before the for/while/if and update its ELEMENTS "
            "inside it (`{var}[i] = ...`).",
            "If the loop is a compile-time unroll, use `range_constexpr` so the "
            "mutation is realized at trace time.",
        ),
    )
    CONTAINER_LIST_INDEX_STAGED = (
        "a {staged} is used as the INDEX into tracked list `{var}`. Indices name "
        "compile-time storage places, so they must be fixed Python integers; a "
        "runtime value cannot name a place.",
        (
            "Use a compile-time index (a Python int), or restructure so the "
            "runtime value is the ELEMENT, not the index.",
            "If the loop is a compile-time unroll over the list, iterate it "
            "directly (`for x in {var}`) or use "
            "`cutlass.range_constexpr(len({var}))` so the index stays a Python int.",
        ),
    )
    CONTAINER_SUBSCRIPT_WRITE_UNTRACKED = (
        "`{var}` (a {kind}) has an element written inside a for/while/if whose "
        "path is decided at run time. A {kind} holds compile-time Python storage "
        "the compiler cannot track per iteration, so the body -- which runs once "
        "at compile time -- would silently discard the per-iteration write.",
        (
            "Use a plain Python `list` (tracked per element) or a {staged} "
            "value instead of the {kind}.",
            "If the loop is a compile-time unroll, use `range_constexpr` so the "
            "write is realized at trace time.",
        ),
    )
    CONTAINER_DICT_KEY_SET_BAKED_READ = (
        "membership/lookup over dict `{var}` is consumed at compile time, but "
        "its key set was changed (created key(s) {detail}) inside a "
        "for/while/if whose path is decided at run time. The body ran once at "
        "compile time, so the consumed key set reflects that one pass -- the "
        "kernel would silently behave as if the branch was taken, whatever "
        "the runtime values.",
        (
            "Create every key before the for/while/if and update the VALUES inside it.",
            "If the for/while/if is compile-time, use `range_constexpr(...)` "
            "/ `const_expr(...)` so the insertion is realized at trace time.",
        ),
    )
    CONTAINER_OPAQUE_SUBSCRIPT_KEY_CREATED = (
        "an element write through `{var}` (a {kind}, whose `__setitem__` the "
        "compiler cannot see into) created container entry/entries {detail} "
        "inside a for/while/if whose path is decided at run time. The body "
        "runs once at compile time and a created entry has no storage cell "
        "from before the for/while/if, so it cannot follow the runtime path "
        "-- later reads would silently observe it regardless of the branch "
        "taken.",
        (
            "Create the entry before the for/while/if and update its VALUE inside it.",
            "Use a plain Python `dict`/`list` (tracked per element) instead "
            "of the {kind}.",
            "If the for/while/if is compile-time, use `range_constexpr(...)` "
            "/ `const_expr(...)` so the write is realized at trace time.",
        ),
    )
    CONTAINER_DICT_GET_MISS_IN_STAGED_CF = (
        "`.get()` on tracked dict `{var}` missed key {detail} inside a "
        "for/while/if whose path is decided at run time, while other entries of "
        "the dict are updated there. The miss default would bake as a fixed "
        "compile-time value on this path.",
        (
            "Create the key before the for/while/if so every path reads a tracked "
            "entry.",
        ),
    )
    CONTAINER_DICT_ITERATED_IN_STAGED_CF = (
        "tracked dict `{var}` is iterated ({method}) inside a for/while/if "
        "whose path is decided at run time, after its key set was changed "
        "there (created key(s) {detail}). The body ran once at compile time, "
        "so the enumerated key set reflects that one pass -- the kernel "
        "would silently iterate entries as if the path creating them was "
        "taken, whatever the runtime values.",
        (
            "Create every key before the for/while/if and update the VALUES "
            "inside it -- iteration over a stable key set is supported.",
            "If the for/while/if is compile-time, use `range_constexpr(...)` "
            "/ `const_expr(...)` so the insertion is realized at trace time.",
        ),
    )
    PHASE_CONVERSION_FAILED = (
        "`{var}` could not be turned into a runtime {new_type} value (its current "
        "value {old_value} is not compatible). Give it a compatible runtime type "
        "before the loop.",
        (
            "Create `{var}` as a {staged} of a compatible type before the "
            "for/while/if, e.g. `{var} = {new_type}(...)`.",
        ),
    )
    UNSUP_LOOP_ELSE = (
        "A `for`/`while` loop with an `else:` clause is not supported in compiled "
        "code.",
        ("Remove the `else:` and put its code after the loop.",),
    )
    UNSUP_CUTE_EXT_OP_IN_DEVICE_FUNC = (
        "The device function `{function_name}` uses a cute_ext "
        "(`cute.experimental`) operation. Lowering cute_ext operations inside "
        "standalone device functions is not supported yet.",
        (
            "Remove the `cute.experimental` (cute_ext) API call from the device "
            "function body, or compile the code as a kernel instead of a device "
            "function.",
        ),
    )
    # --- AST-preprocessing (compile-time) user errors ---
    UNSUP_EARLY_EXIT = (
        "Early exit ({kind}) is not allowed in {where}. A staged for/while/if runs "
        "as a whole, so it cannot return/break/continue out early.",
        (
            "If the condition is decided at compile time, write `if const_expr(...)` "
            "or `for ... in range_constexpr(...)` -- then the early exit runs in "
            "Python and is allowed.",
        ),
    )
    UNSUP_EARLY_EXIT_RUNTIME_CONDITION = (
        "`{kind}` here is guarded by a {staged}. This loop is unrolled in Python "
        "at compile time, so an exit from it must be decided at compile time.",
        (
            "Make the condition compile-time: `if const_expr(...)`.",
            "For a runtime stop condition write a staged `while cond:` loop.",
            "Or carry a runtime `done` flag and guard the body with a staged "
            "`if not done:`.",
        ),
    )
    UNSUP_RANGE_ARGS = (
        "A staged `range(...)` takes 1 to 3 arguments.",
        (
            "Call it as `range(stop)`, `range(start, stop)`, or "
            "`range(start, stop, step)`.",
        ),
    )
    UNSUP_FSTRING = (
        "This kind of expression can't be used inside an f-string in compiled code.",
        (
            "Compute the value into a variable first, then reference that variable in "
            "the f-string.",
        ),
    )
    UNSUP_READ_UNDERSCORE = (
        "`_` is a throwaway name and cannot be read.",
        ("Give the value a real name if you need to read it.",),
    )
    UNSUP_DECORATOR_ORDER = (
        "The `{decorator}` decorator must be the innermost decorator (closest to "
        "`def`).",
        ("Move `{decorator}` directly above the function definition.",),
    )
    UNSUP_GLOBAL = (
        "`global` is not supported in a compiled function.",
        ("Pass the value in as a function argument instead.",),
    )
    UNSUP_NONLOCAL = (
        "`{stmt}` refers to `{name}`, which is not available inside the compiled "
        "function.",
        ("Pass `{name}` in as a function argument instead.",),
    )
    UNSUP_YIELD = (
        "`yield` makes a function a generator, which cannot be compiled: calling "
        "it only creates a generator object and never executes the body.",
        (
            "Define the generator at module scope (plain Python, outside compiled "
            "code) and consume it there, or build a list instead.",
        ),
    )
    UNSUP_ASYNC = (
        "`async`/`await` constructs cannot be compiled: a coroutine body does not "
        "execute when called and there is no event loop to drive it here.",
        ("Compute the value with a plain (non-async) call instead.",),
    )
    UNSUP_EXCEPT_STAR = (
        "`except*` (ExceptionGroup handling) is not supported in a compiled function.",
        ("Use a plain `except` clause instead.",),
    )
    UNSUP_DEL_IN_STAGED_CF = (
        "`{obj}.{attr}` is deleted inside a for/while/if that runs on the GPU, but "
        "the deletion happens once while building the program -- it cannot be made "
        "conditional on the region's runtime condition.",
        (
            "Move the `del` (or `delattr`) outside the for/while/if.",
            "If the attribute must differ per path, assign it a new value instead "
            "of deleting it.",
        ),
    )
    UNSUP_EXCEPTION_SLOT_WRITE_IN_STAGED_CF = (
        "`{target}` is an exception object's built-in slot (`{attr}`), and it is "
        "written inside a for/while/if whose path is decided at run time. The "
        "slot lives in the interpreter, not in storage the compiler tracks, so "
        "the body's single trace would bake this write and every later read of "
        "it, ignoring the path taken and earlier iterations.",
        (
            "Build the exception, its `args` and its cause/context before the "
            "for/while/if, or create the exception inside the loop body so it "
            "is fresh on every iteration.",
            "Carry the changing quantity as a Runtime value (e.g. an `Int32` "
            "field of your own object) instead of inside the exception.",
        ),
    )
    PROPERTY_GETTER_MUTATES_IN_STAGED_CF = (
        "Reading `{obj}.{attr}` runs the property getter `{getter}`, which "
        "writes state, and the read is inside a for/while/if that runs on the "
        "GPU: the getter executes once while building the program, so its side "
        "effect cannot re-run per iteration and both the result and the "
        "mutated state would freeze at their first values.",
        (
            "Make the getter pure and perform the update in an explicit "
            "method call whose effect assigns to tracked state.",
            "If the side effect is trace-time-only bookkeeping, read the "
            "backing field directly instead of going through the property.",
        ),
    )
    UNSUP_GLOBAL_WRITE_IN_STAGED_CF = (
        "`{callee}` writes the module global `{name}`, and it is called inside a "
        "for/while/if that runs on the GPU: the write executes once while "
        "building the program, not once per iteration, so every later read of "
        "`{name}` would see a value frozen at its first update.",
        (
            "Pass the state in as an argument and return the updated value "
            "instead of mutating a module global.",
            "If the call is trace-time configuration whose result never feeds "
            "computed values, move it outside the for/while/if.",
        ),
    )
    UNSUP_IMPORT_IN_STAGED_CF = (
        "`{stmt}` is inside a for/while/if that runs on the GPU, and the module is "
        "not imported yet: its code would execute once while building the program, "
        "not under the region's runtime condition.",
        (
            "Import the module at module scope (or before the for/while/if); an "
            "already-imported module is a cache lookup and is allowed here.",
            "If a per-path module choice is needed, import every candidate outside "
            "the for/while/if and select between them.",
        ),
    )
    UNSUP_MIXED_ASSIGN_TARGETS = (
        "An assignment that mixes plain names, subscripts, and tuple targets on a "
        "single line is not supported here.",
        ("Split it into separate assignment statements, one kind of target per line.",),
    )

    UNSUP_WALRUS_CONDITIONAL = (
        "A walrus assignment (`{name} := ...`) inside a conditionally-evaluated "
        "expression (an `and`/`or` right-hand side, a ternary branch, or a "
        "comprehension) is not supported in compiled code: whether the write "
        "happens cannot be decided at compile time.",
        (
            "Move the walrus assignment out to its own statement before the "
            "expression, or compute the value into a variable first.",
        ),
    )
    UNSUP_WALRUS_EVAL_ORDER = (
        "A call (`{call}`) that Python evaluates around the walrus assignment "
        "(`{name} := ...`) in this statement cannot be kept in its original "
        "evaluation order by the compiler (it sits in a conditionally-evaluated "
        "position, or between two walrus assignments).",
        (
            "Move the walrus assignment out to its own statement before the "
            "expression, or compute the call's result into a variable first.",
        ),
    )
    UNSUP_NO_SOURCE = (
        "The source of `{func}` is not available (e.g. defined in the REPL or "
        "via exec()), so it cannot be compiled.",
        ("Save the function to a .py file and import it from there.",),
    )

    # =====================================================================
    # Migrated from raw DSLRuntimeError raises across the DSL (author
    # mistakes: config, types, arguments, calls, launch, tensors, ...).
    # =====================================================================
    # --- AOT ---
    AOT_MISSING_RETURN_TYPE = (
        "The exported function must declare its return type.",
        (
            "Add a return type annotation to the function definition, e.g. `-> Int32:` or `-> Float32:`.",
        ),
    )
    AOT_UNSUPPORTED_RETURN_TYPE = (
        "The return type {return_type} is not supported for AOT export. Use Int32, Int64, Float32, or Float64.",
        (
            "Change the function's return type annotation to a supported type: Int32, Int64, Float32, or Float64.",
        ),
    )
    # --- ARG ---
    ARG_ANNOTATION_MISMATCH = (
        "expects argument #{num} ({arg_name}) to be {expected}, but got {got}",
        (
            "Pass a value whose type matches `{arg_name}`'s annotation, or change "
            "the parameter's annotation to match the value you pass.",
            "If `{arg_name}` should be a tensor/array, make sure the host "
            "(`@cute.jit`) and kernel (`@cute.kernel`) parameters use the same "
            "type -- mixing `cute.Tensor` and `cutlass.Array` across the host->kernel "
            "boundary triggers this.",
        ),
    )
    ARG_BIND_FAILED = (
        "The arguments do not match the function signature.",
        ("Check that you are passing the correct number and types of arguments.",),
    )
    ARG_COUNT_MISMATCH = (
        "Passed {got} argument(s) to FFI function, but it expects {expected}",
        ("Check the function signature and provide the correct number of arguments",),
    )
    ARG_CONSTEXPR_MISMATCH = (
        "Argument `{arg_name}` was `None` when this function was compiled, and it was "
        "baked into the compiled function as constexpr. Expected exactly the same "
        "argument `None`, but got `{arg_type}`.",
        (
            "Pass `None` for `{arg_name}`, as at compile time.",
            "Or compile the function again with the value you want to pass.",
        ),
    )
    ARG_FOR_LOOP_STEP_NOT_INT = (
        "Loop bounds and step must be integers, not {kind}",
        (
            "Pass integer values for start, stop, and step to for_yield().",
            "If you need a fractional step, multiply by an integer scale and adjust your loop logic.",
        ),
    )
    ARG_INVALID_ALIGNMENT = (
        "Alignment value must be a positive power of 2",
        ("Pass a positive power of 2 (e.g., 1, 2, 4, 8, 16) as the alignment value",),
    )
    ARG_NON_CONSTANT = (
        "`range_constexpr()` requires all arguments to be Python integers known at code-read time.",
        (
            "Use `range(start, stop, step)` instead if your bounds are {staged}.",
            "Ensure all arguments are Python int literals or const Python variables.",
        ),
    )
    ARG_NOT_A_TENSOR = (
        "Argument `{arg_name}` must be a tensor (array or object supporting __dlpack__), but you passed something that is not.",
        (
            "Pass a tensor or array-like object (numpy array, GPU tensor, etc.) for `{arg_name}`.",
        ),
    )
    ARG_NOT_MARSHALABLE = (
        "Argument `{arg_name}` of type `{arg_type}` cannot be passed to the kernel: it exposes neither a C-pointer interface nor a registered JIT argument adapter, so it would reach the kernel as zero arguments.",
        (
            "Pass a tensor, a numeric value, or a pointer the DSL recognizes for `{arg_name}`.",
            "Or register a JIT argument adapter for type `{arg_type}`.",
        ),
    )
    ARG_NOT_NUMERIC = (
        "Argument `{arg_name}` expects a numeric value, but you passed a `{arg_type}`.",
        (
            "Pass a numeric value (an int, a float, or a DSL numeric type) for `{arg_name}`.",
        ),
    )
    ARG_POINTER_NEGATIVE = (
        "Pointer address must be non-negative (got {address})",
        (
            "Pass a non-negative address, or use cute.runtime.nullptr() for null pointers",
        ),
    )
    ARG_POINTER_REQUIRED = (
        "`cute.arch.{op}` expects a pointer (a cute.Pointer or an `!llvm.ptr` value) for `{param}`, but got {got}.",
        (
            "Pass the tensor's iterator, e.g. `cute.arch.{op}(tensor.iterator, ...)`: a cute.Pointer to its first element.",
            "Or pass an explicit LLVM pointer value: `tensor.iterator.llvm_ptr`.",
        ),
    )
    ARG_REJECTED_BY_OP = (
        "`{api}` rejected one of its arguments: {detail}",
        (
            "Check the kind and value of each argument passed to `{api}` against its documentation.",
            "The error raised by the MLIR op builder is attached as the cause of this error.",
        ),
    )
    ARG_TENSOR_NOT_ON_DEVICE = (
        "The tensor `{arg_name}` must be in GPU memory, but it is currently on the host. Move it to the GPU before passing it to the kernel.",
        (
            "Transfer the tensor to GPU memory using your framework's GPU allocation (e.g., `.cuda()` for PyTorch, `cp.array()` for CuPy).",
        ),
    )
    ARG_TENSOR_REQUIRED = (
        "`{arg_name}` is declared as a `{type_kind}`, but you passed something that is not a tensor. Pass a tensor (array/DLPack-compatible object).",
        (
            "Pass a tensor or array-like object (numpy array, GPU tensor, etc.) for `{arg_name}`.",
        ),
    )
    ARG_TYPE_MISMATCH = (
        "Pointer alignment must be created using align(...), not a plain integer",
        ("Wrap the alignment value with align(), e.g. align(4) instead of just 4",),
    )
    ARG_UNIVERSAL_COPY_ATTRS_REJECTED = (
        "`CopyUniversalOp` does not accept {attrs}: the universal copy atom carries "
        "no memory attributes.",
        (
            "Use a specialized copy operation instead: `CopyG2ROp` (gmem->rmem), "
            "`CopyR2GOp` (rmem->gmem), `CopyS2ROp` (smem->rmem), or `CopyR2SOp` "
            "(rmem->smem).",
        ),
    )
    ARG_UNORDERED_CONTAINER = (
        "Arguments cannot be sets because sets are unordered and the compiler needs to preserve argument order.",
        (
            "Convert the set to a list or tuple, e.g. `list(my_set)` or `tuple(my_set)`.",
        ),
    )
    ARG_UNSUPPORTED_C_EXPORT = (
        "Argument {arg_name} has type {arg_type}, which cannot be exported to C. Only numeric types (Int32, Float32, etc.) and CUstream are supported.",
        (
            "Use a supported scalar type (Int8/16/32/64, Uint8/16/32/64, Float32/64, BFloat16, Float16, Boolean) or CUstream.",
            "Check that your function arguments have correct type annotations.",
        ),
    )
    ARG_UNSUPPORTED_TYPE = (
        "Argument {arg_name} (position {num}) cannot be converted to a {phase_label} for function '{function_name}'. Its type `{arg_type}` is not supported.",
        (
            "If the value is known at compile time, annotate it: `{arg_name}: Constexpr`.",
            "Otherwise, implement the `JitArgument` or `DynamicExpression` protocol for type `{arg_type}`, or register a custom argument adapter.",
        ),
    )
    ARG_WORKSPACE_COUNT_MISMATCH = (
        "The kernel call has {got} extra workspace arguments, but {expected} are required.",
        ("Provide the correct number of workspace pointers when calling the kernel.",),
    )
    ARG_WRONG_TYPE = (
        "Loop `{name}` must be an integer type, not `{dtype}`. Loop bounds (start, stop, step) must all be integers.",
        (
            "Use integer values for `range()` or loop bounds.",
            "Convert the value to an integer type, e.g., `int({name})`.",
        ),
    )
    # --- ASSERT ---
    ASSERT_DYNAMIC_CONDITION = (
        "`assert` is checked while the compiler reads your code and needs a "
        "{meta} condition, but this condition is a {staged}.",
        (
            "For a run-time check use `cutlass.assert_(cond, msg)` (active only "
            "with CUTE_DSL_COMPILER_OPT=debug / CUTE_DSL_ENABLE_ASSERTIONS=1).",
            "To assert on a compile-time value wrap it in "
            "`cutlass.const_expr(...)` or make it a `cutlass.Constexpr` parameter.",
        ),
    )
    # --- ATTR ---
    ATTR_BUILDER_REQUIRES_CONSTANT = (
        "`{var}` is passed to `{callee}`, which needs one plain compile-time "
        "value, but `{var}` changes inside a for/while/if -- no single value "
        "exists to pass.",
        (
            "Pass a {staged} value through a DSL API that accepts runtime "
            "values, or keep `{var}` a fixed compile-time constant.",
        ),
    )
    # --- BODY ---
    BODY_BORN_SEED_UNPLACEABLE = (
        "`{var}` is first given a value inside a for/while/if, but that value "
        "was computed on a different path, so no store can be placed where the "
        "assignment actually runs.",
        (
            "Assign `{var}` a value computed on the same path (or before the "
            "for/while/if) so the assignment can be compiled where it runs.",
        ),
    )
    # --- CALL ---
    CALL_BUILTIN_KWARGS_UNSUPPORTED = (
        "The built-in function '{fcn}' does not support keyword arguments.",
        ("Remove keyword arguments or use positional arguments only.",),
    )
    CALL_DUPLICATE_ARGUMENT = (
        "Got multiple values for argument {argument_name}",
        (
            "Pass the value either as a positional argument or as a keyword argument, not both",
        ),
    )
    CALL_FFI_NO_KWARGS = (
        "FFI functions do not accept keyword arguments",
        ("Use only positional arguments when calling FFI functions",),
    )
    CALL_FFI_NO_MATCH = (
        "No compatible overload found for the arguments passed to this FFI function",
        (
            "Check that your argument types match one of the function's overloads",
            "Use the function's type annotations to see what types are accepted",
        ),
    )
    CALL_FUNCTION_NOT_PROVIDED = (
        "No function was provided to compile. Pass a callable decorated with @cute.jit.",
        ("Ensure you pass a valid @cute.jit-decorated function to cute.compile().",),
    )
    CALL_KERNEL_TARGET = (
        "`{function_name}` is decorated with @cute.kernel. cute.compile() "
        "expects a @cute.jit-decorated function to compile its target as the host entry point.",
        ("Compile the @cute.jit function that launches `{function_name}`.",),
    )
    CALL_MISSING_ARG = (
        "Required argument `{name}` is missing in the call to `{function_name}`.",
        ("Pass a value for `{name}`.",),
    )
    CALL_MISSING_ARGS = (
        "Missing required arguments: {missing}",
        ("Provide all required arguments without defaults",),
    )
    CALL_MISSING_JIT_DECORATOR = (
        "Function must be decorated with @cute.jit before passing it to cute.compile().",
        ("Add @cute.jit decorator to the function definition.",),
    )
    CALL_NOT_CALLABLE = (
        "The provided object is not callable. Pass a function or method decorated with @cute.jit.",
        (
            "Ensure the first argument to cute.compile() is a callable (function, method, or callable object).",
        ),
    )
    CALL_OUTSIDE_JIT = (
        "`{api}` builds GPU kernel IR and can only be called while a @cute.jit or @cute.kernel function is being compiled, but it was called from plain Python.",
        (
            "Move this call into a function decorated with @cute.jit or @cute.kernel and call that function.",
        ),
    )
    CALL_SIGNATURE_MISMATCH = (
        "Arguments do not match the function signature (got {provided} args, {provided_kw} kwargs)",
        ("Verify that all arguments match the expected signature",),
    )
    CALL_TOO_MANY_ARGS = (
        "Too many positional arguments (expected {expected}, got {provided})",
        ("Remove extra positional arguments or pass them as keyword arguments",),
    )
    CALL_UNEXPECTED_KWARG = (
        "Unexpected keyword argument: {argument_name}",
        (
            "Remove the argument or check the function signature for the correct parameter name",
        ),
    )
    CALL_UNSUPPORTED_CALLABLE_TYPE = (
        "The provided object is of an unsupported callable type. Only functions, methods, and callable instances are supported.",
        (
            "Pass a regular function, bound method, or callable instance (with __call__ method).",
        ),
    )
    CALL_WRONG_IMPORT = (
        "`{name}` was imported from a different module; you must use the one from the DSL package.",
        (
            "Remove any local definition or import of `{name}`.",
            "Use the version from the DSL (cutlass.range, cutlass.if_, etc.).",
        ),
    )
    # --- CONFIG ---
    CONFIG_ATTRIBUTES_INVALID_TYPE = (
        "`attributes=` must be a dict, or a callable that returns a dict.",
        (
            "Pass a dict of string keys to string (or attribute) values, or a callable returning one.",
        ),
    )
    CONFIG_ATTRIBUTES_UNSUPPORTED = (
        "Non-empty `@kernel` attributes require CuTe extension compilation.",
        (
            "Make `attributes=` resolve to `None` or an empty dict for this kernel.",
            "Remove the `attributes=` parameter from the @kernel decorator.",
            "Or enable CuTe extension compilation for this program.",
        ),
    )
    CONFIG_ATTR_KEY_UNSUPPORTED = (
        "The attribute key '{key}' is not supported by this DSL.",
        ("Use one of the allowed attribute keys for your DSL.",),
    )
    CONFIG_ATTR_VALUE_TYPE_INVALID = (
        "The value for attribute '{key}' must be a string (or attribute) value.",
        ("Use a string value for attribute '{key}'.",),
    )
    CONFIG_BINARY_LOAD_PREFIX_REQUIRED = (
        "Binary loading requires a function prefix, but none was provided.",
        (
            "Provide a prefix when using load_from_binary=True.",
            "If loading from a compiled binary, the prefix must match the function name used when the binary was created.",
        ),
    )
    CONFIG_CLUSTER_DYNAMIC = (
        "The cluster dimension must use static/Constexpr values, not runtime values.",
        (
            "Use `Constexpr` annotation or a Python constant for cluster/fallback_cluster.",
        ),
    )
    CONFIG_EXPORT_NO_RUNTIME_ARGS = (
        "Cannot export a function with no runtime arguments. All of the function's parameters are compile-time constants, but a C interface needs at least one runtime parameter to call.",
        (
            "Remove the constexpr annotation from at least one parameter so it becomes a runtime argument.",
            "If all parameters must be compile-time constants, you cannot export this function as a standalone C library.",
        ),
    )
    CONFIG_FALLBACK_CLUSTER_REQUIRES_CLUSTER = (
        "You cannot set `fallback_cluster` without also setting `cluster`.",
        ("If using fallback_cluster, also set cluster in the LaunchConfig.",),
    )
    CONFIG_INCOMPATIBLE_FLAGS = (
        "TVM-FFI export (--enable-tvm-ffi) and host-target export (--host-target) cannot be used together.",
        (
            "Choose one export mode: use --enable-tvm-ffi for GPU executables, or --host-target for CPU-only.",
            "For CPU-only export, remove the --enable-tvm-ffi flag.",
        ),
    )
    CONFIG_INVALID_HOST_TARGET = (
        "Invalid --host-target specification: {error}",
        (
            "Use a known preset (e.g. 'linux-aarch64') or the long form: 'llvm -mtriple=<triple> [-mcpu=<cpu>] [-mattr=<features>]'.",
        ),
    )
    CONFIG_INVALID_OPT_LEVEL = (
        "Optimization level must be between 0 and 3, but got {val}.",
        (
            "Use a valid optimization level: 0 (no optimization), 1, 2, or 3 (maximum optimization).",
        ),
    )
    CONFIG_INVALID_VALUE = (
        "Loop attribute `prefetch_stages` must be 0 or greater; got `{value}`.",
        ("Use a non-negative integer for `prefetch_stages`.",),
    )
    CONFIG_MALFORMED_COMPILE_OPTIONS = (
        "Compiler options string is malformed: '{options}'. Check the format and values.",
        (
            "Verify the compile options string syntax and ensure values are properly formatted.",
        ),
    )
    CONFIG_MAX_THREADS_DYNAMIC = (
        "The `max_number_threads` launch config parameter must use static/Constexpr values, not runtime values.",
        ("Use `Constexpr` annotation or a Python constant for max_number_threads.",),
    )
    CONFIG_MISSING_NVDISASM = (
        "{vars} requires the 'nvdisasm' tool to write SASS output, but no compatible binary was found.",
        (
            "Install it with `pip install nvidia-cutlass-dsl[sass]`, or install a CUDA Toolkit and expose it via CUDA_HOME/CUDA_PATH.",
        ),
    )
    CONFIG_MISSING_TVM_FFI = (
        "TVM FFI is not installed, but TVM FFI support was requested.",
        ("Install TVM FFI with `pip install apache-tvm-ffi`, or disable TVM FFI.",),
    )
    CONFIG_OPTION_REQUIRES_VALUE = (
        "Option '{key}' requires a value. Provide it in the form {key}=<value>.",
        ("Specify a value for the option, e.g. {key}=<value>.",),
    )
    CONFIG_RESOLVER_INVALID_RETURN = (
        "The resolver function must return either a dict or None.",
        ("Return a dict of string keys to string (or attribute) values, or None.",),
    )
    CONFIG_UNKNOWN_COMPILE_OPTION = (
        "Unrecognized compile option: {option}. Please check that the option is spelled correctly.",
        ("Verify the compile option name and use only supported options.",),
    )
    CONFIG_UNSUPPORTED_ARCH = (
        "Unsupported GPU architecture '{arch}'. This kernel is only compatible with: {expected_archs}.",
        (
            "Set `CUTE_DSL_ARCH` environment variable or pass a compatible `gpu_arch` to compile options.",
        ),
    )
    CONFIG_VERSION_CONFLICT = (
        "Cannot use both exact_version and min/max version range at the same time. Choose one approach.",
        (
            'Either use exact_version="X.Y" for a single version,',
            "or use min_version and/or max_version for a range, but not both.",
        ),
    )
    CONFIG_VERSION_KIND_INVALID = (
        '"{kind}" is not a valid version kind for target_version().',
        ("Use one of: {valid_kinds}.",),
    )
    CONFIG_VERSION_MALFORMED = (
        '"{version_string}" is not a valid version string for {class_name}.',
        (
            'Use dot-separated numeric components like "4.6" or "4.6.1"; missing components default to 0.',
        ),
    )
    CONFIG_VERSION_MISSING = (
        "When checking a version range, at least min_version or max_version must be provided.",
        (
            'Set min_version="X.Y" to check minimum,',
            'set max_version="X.Y" to check maximum,',
            "or set both for a range between them.",
        ),
    )
    CONFIG_VERSION_RANGE_INVALID = (
        "The minimum version cannot be greater than the maximum version. Swap them or fix the range.",
        (
            'Ensure min_version <= max_version, e.g., min_version="12.0", max_version="13.0"',
        ),
    )
    CONFIG_VERSION_REQUIRED = (
        "At least one version parameter is required.",
        (
            'Provide exact_version="X.Y" for a specific version,',
            'or min_version="X.Y" and/or max_version="X.Y" for a version range.',
            'Add kind="dsl" to check the DSL package version instead of the CUDA toolkit version.',
        ),
    )
    CONFIG_VERSION_TYPE = (
        '{param_name} must be a version string (e.g., "12.3") or {expected_type}, not {got_type}',
        ('Pass a version string like "12.3" or use {expected_type}("12.3")',),
    )
    # --- INSTRUMENTATION ---
    INSTRUMENTATION_GAP = (
        "Function `{name}` is being traced as a compilation entry point, but "
        "it was never rewritten by the DSL preprocessor and is not declared "
        "native -- its variable reads/writes would be invisible to the "
        "compiler, producing silently wrong code.",
        (
            "Decorate `{name}` with @jit / @kernel so the preprocessor "
            "instruments it before tracing.",
            "Or opt it out explicitly with `preprocess=False` if it must run "
            "as plain Python.",
        ),
    )
    # --- LAUNCH ---
    LAUNCH_INVALID_CLUSTER = (
        "Launch cluster must have exactly 3 dimensions.",
        ("Provide cluster as a 3D vector, e.g. `cluster=[1, 1, 1]`.",),
    )
    LAUNCH_INVALID_DIMENSION = (
        "Launch {name} dimension at position {idx} must be an integer, but got {arg_type}.",
        ("Ensure all elements of {name} are integers, e.g. `{name}=[1, 256, 1]`.",),
    )
    LAUNCH_INVALID_FALLBACK = (
        "Launch fallback_cluster must have exactly 3 dimensions.",
        (
            "Provide fallback_cluster as a 3D vector, e.g. `fallback_cluster=[1, 1, 1]`.",
        ),
    )
    LAUNCH_INVALID_GRID = (
        "Launch {name} must have at most 3 dimensions, but got {count}.",
        ("Reduce the {name} to at most 3 elements, e.g. `{name}=[x, y, z]`.",),
    )
    LAUNCH_INVALID_STREAM = (
        "Launch `stream=` must be a CUDA stream (a `cuda.CUstream` host parameter or a 64-bit integer stream handle), but got {got}.",
        (
            "Declare the host parameter as `stream: cuda.CUstream` (`import cuda.bindings.driver as cuda`) and pass `cuda.CUstream(torch.cuda.current_stream().cuda_stream)`.",
            "A raw integer handle must be 64-bit: annotate the parameter as `cutlass.Int64` (an un-annotated Python int is marshalled as `Int32`, which cannot hold a CUstream handle).",
        ),
    )
    LAUNCH_MISSING_ARG = (
        "Required argument `{name}` is missing when launching kernel `{kernel_name}`.",
        ("Pass a value for `{name}` to the kernel launch.",),
    )
    LAUNCH_OUTSIDE_JIT = (
        "Kernel `{kernel_name}` is being launched from plain Python, but kernels can only be launched while a @cute.jit function is being compiled.",
        (
            "Wrap the launch in a host function decorated with @cute.jit and call that host function.",
        ),
    )
    LAUNCH_NEVER_ISSUED = (
        "Kernel `{kernel_name}` was called but never launched. Calling a @cute.kernel function only builds a launcher; the kernel does not run until you launch that launcher.",
        (
            "Launch the kernel, e.g. `{kernel_name}(...).launch(grid=[...], block=[...])`.",
            "If you meant to discard the call, remove it.",
        ),
    )
    # --- OWNER ---
    OWNER_CLASS_CHANGED = (
        "An object whose state is tracked across a for/while/if changed its "
        "class from `{old_class}` to `{new_class}` -- the tracked state was "
        "recorded under `{old_class}` and cannot be re-derived for "
        "`{new_class}`.",
        (
            "Create a new `{new_class}` object instead of reassigning "
            "`__class__` on one the compiler is tracking.",
        ),
    )
    OWNER_DEL_FINALIZER_AT_BIRTH = (
        "`{cls}` defines `__del__` (via `{definer}`): the finalizer runs at "
        "a garbage-collection-determined instant, which has no position in "
        "the traced program, so an object of this class created here cannot "
        "be tracked.",
        (
            "Release resources with an explicit close()/context manager "
            "instead of `__del__` on `{definer}`.",
            "Or create the object outside the traced function and pass it in.",
        ),
    )
    OWNER_DECLARED_SURFACE_VIOLATION = (
        "`{obj}` opted into the DSL value protocol "
        "(`__extract_mlir_values__`), declaring which of its values follow "
        "run-time control flow, but {violation}. State outside the "
        "declaration is fixed once code is read and cannot change inside a "
        "for/while/if whose path is decided at run time.",
        (
            "Declare the state: make `__extract_mlir_values__` / "
            "`__new_from_mlir_values__` carry it (and keep the DSL value "
            "type's own `__hash__`).",
            "Or perform the change outside the run-time for/while/if.",
        ),
    )
    OWNER_STAGED_SELECTION_WRITE = (
        "`{obj}.{attr}` is written{write_loc} through an object that a run-time "
        "condition selected (`x if cond else y` where `cond` is a {staged}). "
        "Which object receives the write is only known at run time, and the "
        "conditional expression yields a merged copy of the two candidates' "
        "values, so the write would land on that copy and neither candidate "
        "would change.",
        (
            "Mutate inside an if statement instead, one candidate per arm: "
            "`if cond: x.advance()` / `else: y.advance()`.",
            "Or select values, not objects: `v = x.field if cond else y.field`.",
            "Or make the choice compile-time with `cutlass.const_expr(cond)`, "
            "so one candidate is picked while the code is read.",
        ),
    )
    OWNER_STAGED_SELECTION_READ_AFTER_CANDIDATE_WRITE = (
        "`{obj}.{attr}` is read{read_loc} through the result of a run-time "
        "selection (`x if cond else y` with a run-time `cond`, or a re-point "
        "inside a run-time `if`) after one of its candidates was written"
        "{write_loc}. In Python the result IS the selected candidate and sees "
        "that write; the compiler's result is a merged copy taken at the "
        "selection, so it would still show the old value.",
        (
            "Select after the write: move `x if cond else y` below the "
            "candidate's update.",
            "Or read the candidate itself, or choose values, not objects "
            "(`x.field if cond else y.field`) after the write.",
            "Or make the choice compile-time with `cutlass.const_expr(cond)`.",
        ),
    )
    OWNER_STAGED_SELECTION_CANDIDATE_READ = (
        "`{obj}.{attr}` is read{read_loc} after a field write went through a "
        "run-time selection between this object and another (`x if cond else "
        "y` where `cond` is a {staged}). Python would have mutated whichever "
        "candidate the condition picked; the compiler carries an object as "
        "one storage cell per field, so the write landed on the merged copy "
        "the selection produced and this object's fields no longer say what "
        "Python's would.",
        (
            "Read the selected object through the binding the selection "
            "produced (`sel = x if cond else y`; `sel.field`), not through a "
            "candidate.",
            "Or mutate inside an if statement, one candidate per arm: "
            "`if cond: x.advance()` / `else: y.advance()`.",
            "Or make the choice compile-time with `cutlass.const_expr(cond)`, "
            "so one candidate is picked while the code is read.",
        ),
    )
    OWNER_FABRICATED_ATTR_IN_STAGED_CF = (
        "`{obj}.{attr}` is fabricated by `{definer}.__getattr__` inside "
        "staged (runtime) control flow: the name resolves to no storage "
        "slot, so the trace-time value would bake here and silently mask "
        "state that can change across runtime executions of this region.",
        (
            "Read `{obj}.{attr}` into a local before the staged "
            "for/while/if and use the local, or give `{attr}` real storage "
            "(assign it in `__init__`).",
        ),
    )
    # --- PHASE ---
    PHASE_IDENTITY_ON_TRACKED = (
        "`is` asks for Python object identity, but `{what}` is a "
        "compiler-tracked value here: the compiler re-wraps tracked values "
        "while staging code, so wrapper identity does not follow the "
        "program's own object identity.",
        (
            "Compare values with `==` instead of `is`.",
            "Identity tests against `None` (or another non-numeric sentinel) "
            "stay exact and are supported.",
        ),
    )
    PHASE_SERIALIZE_STAGED = (
        "`{what}` holds a staged (runtime) value: serializing it would bake "
        "compiler trace state into bytes that cannot round-trip to the value "
        "computed at run time.",
        (
            "Serialize plain Python values computed outside staged code.",
            "If the value is needed at run time, keep it in scalars/tensors "
            "instead of serialized bytes.",
        ),
    )
    PHASE_STAGED_VALUE_OUTLIVED_COMPILATION = (
        "This `{what}` value was computed inside a compiled function that has "
        "finished compiling: it has no Python value on the host, and the IR "
        "behind it died with that compilation, so it can neither be read here "
        "nor used in a later compilation.",
        (
            "Return the result through a tensor/array argument the kernel "
            "writes, or recompute it in plain Python.",
            "A value a later compilation needs must be passed in as an "
            "argument, not kept in a module global, container or object field.",
        ),
    )
    PHASE_NUMERIC_PROTOCOL_ON_STAGED = (
        "`{proto}` is not supported on `{what}`, a {staged}: this numeric "
        "protocol has no runtime (staged) form.",
        (
            "For 3-argument pow compute `(a ** b) % m` when wraparound "
            "semantics are acceptable.",
            "For `@` and complex(), keep the operands plain Python values -- "
            "Python defines no scalar `@` either.",
        ),
    )
    PHASE_CONDITIONAL_NOT_DYNAMIC = (
        "The condition must be a {staged} value, not a {meta}.",
        ("Ensure the condition is a runtime value (Boolean, Int32, etc.).",),
    )
    PHASE_DYNAMIC_INDEX = (
        "a {staged} is used where Python needs a fixed integer (`__index__`): a "
        "tuple/list/str index or slice bound, or a builtin `range()` bound. "
        "Python resolves these while your code is read, in a "
        "`@cute.jit`/`@cute.kernel` body as much as in a plain helper, so the "
        "value must be known at trace time.",
        (
            "Use an index known at trace time: iterate with "
            "`cutlass.range_constexpr(...)`, or restructure so the runtime value "
            "is the ELEMENT, not the index.",
            "For a runtime-bound loop write `for i in cutlass.range(n)` inside a "
            "`@cute.jit`/`@cute.kernel` body -- a plain helper's loops run at "
            "trace time.",
        ),
    )
    PHASE_DYNAMIC_RANGE_ITERATED_BY_PYTHON = (
        "`cutlass.range(...)` was iterated by plain Python: a `for` in a helper "
        "without `@cute.jit`/`@cute.kernel`, or a comprehension, generator "
        "expression, `list()`/`tuple()` call or `iter()`/`next()` anywhere. A "
        "dynamic range has no trace-time iteration; it only drives a `for` "
        "statement written in a `@cute.jit`/`@cute.kernel` body, where the "
        "compiler turns it into a runtime loop.",
        (
            "Move the runtime-bound `for` loop into a `@cute.jit`/`@cute.kernel` "
            "function -- a plain helper's body is not staged.",
            "For a trace-time loop over a Python int use "
            "`cutlass.range_constexpr(...)` (or builtin `range()`); both work in "
            "helpers and comprehensions.",
        ),
    )
    PHASE_DYNAMIC_TO_STATIC_BOOL = (
        "Cannot use a {staged} value where a {meta} boolean is required (e.g. in plain Python control flow)",
        (
            "Decorate the function with @jit and ensure preprocess is enabled so control flow is staged",
            "Or move the boolean check inside a staged for/while/if block where {staged} values are allowed",
        ),
    )
    PHASE_NATIVE_CALLEE_STAGED_TRUTH = (
        "{callee} decides its result from a {staged}: a Python built-in or "
        "container method runs at compile time and cannot branch on a runtime "
        "value.",
        (
            "Write the loop explicitly: `for x in seq:` with a staged `if cond:` "
            "that accumulates the result.",
            "For reductions use `cutlass.min`/`cutlass.max`/`cutlass.any_`/"
            "`cutlass.all_` (or the built-in on a list/tuple).",
        ),
    )
    PHASE_REQUIRES_CONSTANT = (
        "{what} requires a value known at code-read time, but you gave it a {staged}.",
        (
            "Make the value a Python constant (a literal or a value computed only from Python values).",
            "If the value is only known at run time, use the runtime form instead (for example a runtime `if`/loop or a runtime assert).",
        ),
    )
    PHASE_STRUCTURAL_CONSTANT_MUTATED = (
        "`{var}` is changed here so it must become a {staged}, but it was "
        "already consumed as a compile-time constant (value {value}, at "
        "{read_file}:{read_line}) inside a for/while/if -- as a loop trip "
        "count, a Python-sequence index, a folded if/while predicate, or a "
        "similar structural use. That structure is fixed at compile time, "
        "so every iteration would keep the old value silently.",
        (
            "Make `{var}` a {staged} from the start (e.g. `Int32(...)`) and "
            "use a runtime loop/index, or keep it a fixed compile-time "
            "constant and do not change it inside the for/while/if.",
        ),
    )
    PHASE_ARM_LOCAL_CONSTANT_ESCAPES = (
        "`{var}` is read here, but it was changed as a compile-time constant "
        "inside an if branch that only runs on some GPU paths (at "
        "{write_file}:{write_line}). The compiler runs the body once, so "
        "this read would keep that branch's value even when the branch is "
        "skipped at run time.",
        (
            "Make `{var}` a {staged} before the if (e.g. `{var} = "
            "Int32(...)`) so the update is carried on every path.",
            "Or keep every read of `{var}` inside the same if branch that changes it.",
        ),
    )
    PHASE_ARM_REWRITE_NOT_STAGEABLE = (
        "`{var}` is a {meta} (type {old_type}, value {old_value}) before this "
        "if, and a branch that only runs on some GPU paths changes it to a "
        "{new_type} ({new_value}). Where the paths come back together no GPU "
        "value can hold both possibilities, so the value after the if cannot "
        "be represented in any mode.",
        (
            "If the condition is known at compile time, write `if "
            "const_expr(...)` so only one branch is traced.",
            "Otherwise keep `{var}` a number: express the state with a numeric "
            "or bool flag decided before the if, and choose numbers, not "
            "objects, inside the branches.",
        ),
    )
    PHASE_BODY_BORN_CONSTANT_ESCAPES = (
        "`{var}` is read here, but it belongs to a binding created inside a "
        "for/while/if body (at {birth_file}:{birth_line}) and is tracked as a "
        "compile-time constant there. The compiler runs the body once, so this "
        "read outside the body would keep that pass's value even when the body "
        "runs zero times or leaves a different object bound.",
        (
            "Read `{var}` inside the for/while/if body that creates it.",
            "Or make the field a {staged} at construction (e.g. `Int32(...)`) "
            "so the value is carried on every path.",
        ),
    )
    PHASE_PREDICATE_FOLDED_STALE = (
        "`{var}` is changed here inside a for/while body, but an if/while "
        "condition already folded on its compile-time value ({value}, at "
        "{read_file}:{read_line}); the folded branch was fixed at trace "
        "time, so every iteration would keep the stale decision silently.",
        (
            "Make the value a {staged} at construction (e.g. `Int32(...)`) so "
            "the condition stays a runtime comparison.",
            "Or hoist the mutation out of the loop and keep the value a fixed "
            "compile-time constant.",
        ),
    )
    # --- PRINTF ---
    PRINTF_ARG_COUNT_MISMATCH = (
        "This cute.printf format string has {expected} placeholder(s) but "
        "{got} value(s) were passed.",
        (
            "Pass exactly one value per `{{}}` / `{{:spec}}` / `%` placeholder, "
            "in placeholder order.",
            "Write a literal percent sign as `%%`; every `{{}}` is a placeholder.",
        ),
    )
    PRINTF_BRACE_ESCAPE_UNSUPPORTED = (
        "cute.printf can't print literal braces: {detail}.",
        (
            "The generated printf reads every `{{}}` as a placeholder, so `{{{{` / "
            "`}}}}` escapes and stray braces can't be honored.",
            "Drop the braces, or print the surrounding text with a separate "
            "cute.printf call.",
        ),
    )
    PRINTF_POSITIONAL_FIELD = (
        "cute.printf fields must be empty (`{{}}` or `{{:spec}}`); the field "
        "`{field}` selects a value by position or name.",
        (
            "Pass the values in placeholder order and use `{{}}` or `{{:spec}}`.",
            'Use an f-string to refer to values by name: cute.printf(f"{{name}}").',
        ),
    )
    PRINTF_UNSUPPORTED_SPEC = (
        "cute.printf can't use the format spec `{spec}` here: {reason}.",
        (
            "Supported specs are the printf-compatible ones: an optional sign "
            "(`+`, space), `#`, zero padding, width, precision and a type letter, "
            "e.g. `{{:04d}}`, `{{:+.2f}}`, `{{:#x}}`, `{{:8.3e}}`.",
            "Format the value in Python first when it is a compile-time constant.",
        ),
    )
    # --- READ ---
    READ_DEPTH_OVERFLOW = (
        "The attribute/subscript chain `{var}` is {depth} accesses deep, "
        "which exceeds the {budget} accesses the compiler tracks per "
        "statement -- deeper reads cannot be attributed to their storage "
        "and would bake silently.",
        (
            "Split the chain across statements with intermediate variables "
            "so each statement stays within {budget} accesses.",
        ),
    )
    # --- RECONSTRUCT ---
    RECONSTRUCT_NO_PROTOCOL = (
        "A value of type `{cls}` must be rebuilt here from its compiled "
        "value, but `{cls}` provides no way to do so: it implements neither "
        "`__new_from_mlir_values__` nor a constructor accepting the compiled "
        "value.",
        (
            "Implement `__extract_mlir_values__` / `__new_from_mlir_values__` "
            "on `{cls}` so the compiler can rebuild it.",
            "Or carry a DSL value type (Int32, Float32, TensorSSA, ...) "
            "across the for/while/if instead.",
        ),
    )
    # --- SCOPE ---
    SCOPE_CLOSURE_CAPTURE = (
        "Function `{func_name}` captures variable `{var_name}`, which is not supported in staged for/while/if.",
        (
            "Pass `{var_name}` as an explicit function argument instead of relying on closure capture.",
            "Define the function inside the loop/if, or refactor to avoid the closure.",
        ),
    )
    SCOPE_NONLOCAL_WRITE_IN_STAGED_CF = (
        "`{name}` was already updated through a `nonlocal` write in another "
        "function scope inside this dynamic for/while/if, and is accessed "
        "here from a different scope of the same region. The two accesses "
        "cannot be routed to one storage cell across the region, so one "
        "side's update would be silently lost at the join.",
        (
            "Return the new value from the nested function and rebind it at "
            "the call site (`{name} = fn(...)`), or move the `nonlocal` "
            "write outside the dynamic for/while/if.",
        ),
    )
    # --- SNAPSHOT ---
    SNAPSHOT_UNMATERIALIZABLE = (
        "`{var}` holds a value captured earlier in the trace, but the tracked "
        "variable it was captured from has moved on since, and the captured "
        "value itself was computed inside a for/while/if region that has "
        "already closed -- so neither the captured value nor a faithful "
        "re-read of it is available here.",
        (
            "Read the source variable directly at this point instead of "
            "keeping a captured copy across the for/while/if.",
            "Or capture the value before the for/while/if so the copy stays "
            "available on every path.",
        ),
    )
    # --- SPEC ---
    SPEC_DESCRIPTOR_HOP = (
        "Re-validating this compiled function would execute the `{attr}` "
        "descriptor of `{owner_type}` while re-resolving `{path}`; a "
        "specialization row must re-resolve through plain storage only. "
        "This row should have been classified trace-internal at record time "
        "-- a bug in the DSL, not a mistake in your code.",
        (
            "Recompile via cute.compile (or re-invoke the @jit function) so "
            "the value is re-read on a fresh trace.",
            "And report this diagnostic to the DSL team.",
        ),
    )
    SPEC_UNVERIFIABLE_REENTRY = (
        "This compiled function baked a trace-time value that cannot be "
        "re-checked against live state, so re-invoking the compiled handle "
        "cannot be validated for reuse.",
        (
            "Re-invoke the @jit-decorated function instead of the compiled "
            "handle so the value is re-read on a fresh trace.",
            "Or recompile with cute.compile after changing host state.",
        ),
    )
    # --- STALE ---
    STALE_SPECIALIZATION = (
        "This compiled function was specialized on `{path}` = `{baked}`, but "
        "the value at this call is `{live}` -- the compiled code still uses "
        "the old value.",
        (
            "Recompile via cute.compile (or re-invoke the @jit function) "
            "after changing `{path}`.",
        ),
    )
    # --- TENSOR ---
    TENSOR_ALREADY_ALLOCATED = (
        "This tensor is already allocated. Call deallocate() before allocating again.",
        (
            "Call deallocate() before allocating the same tensor again.",
            "Or create a new tensor instead of reusing the same one.",
        ),
    )
    TENSOR_FRAMEWORK_MANAGED = (
        "This tensor is managed by the framework and cannot be manually {action}.",
        ("Let the framework manage this tensor; remove the manual {action} call.",),
    )
    TENSOR_NOT_ALLOCATED = (
        "This tensor has no device memory yet -- it must be allocated before this operation.",
        (
            "Call `allocate()` (and `copy_to_gpu()` if you need its contents) before using it here.",
        ),
    )
    TENSOR_MAP_INVALID_DESCRIPTOR = (
        "Cannot create the TensorMap descriptor: {detail}",
        (
            "Correct the arguments passed to `create_tensor_map_*` so they satisfy "
            "the reported CUDA TensorMap constraint.",
        ),
    )
    # --- TYPE ---
    TYPE_BOOLOP_OPERAND_NOT_NUMERIC = (
        "`{op}` with a left operand that is only known at run time selects its "
        "result at run time, so the right operand must be a Python number or a "
        "DSL numeric value (Int32, Float32, Boolean, ...); it is a `{got}`.",
        (
            "Select between numeric values (e.g. `y if x != 0 else x`), or test "
            "the property you need explicitly instead of the object itself.",
            "Or make the left operand a compile-time constant so Python's own "
            "`{op}` applies.",
        ),
    )
    TYPE_CHANGED_INSIDE_REGION = (
        "`{var}` changes its compiled type from `{old_type}` to `{new_type}` "
        "inside {region}. A value carried across a for/while/if boundary must "
        "keep one compiled type, so this change cannot be carried out of the "
        "region.",
        (
            "Hoist the type change out of the for/while/if so `{var}` has the "
            "new type on every path.",
            "Or make the types agree: convert explicitly so every assignment "
            "to `{var}` produces the same compiled type.",
        ),
    )
    TYPE_CLUSTER_NOT_INT = (
        "The {config_name} dimensions must be integers.",
        ("Provide integer values for {config_name}.",),
    )
    TYPE_CONDITIONAL_BRANCH_MISMATCH = (
        "The two branches of this conditional expression produce different types. Both branches must produce the same type.",
        ("Make both branches produce the same type, converting explicitly if needed.",),
    )
    TYPE_CONDITIONAL_VALUE_COUNT = (
        "The conditional expression branches must all return exactly one value.",
        ("Ensure all branches (if/else) return exactly one value.",),
    )
    TYPE_DEVICE_FUNC_RETURN_COUNT = (
        "The device function returned {count} value(s), but its return type expects exactly one.",
        ("Return exactly one value matching the declared return type.",),
    )
    TYPE_DEVICE_FUNC_RETURN_INVALID = (
        "The return type annotation must be a DSL type (like Float32, Int32) or a @native_struct.",
        (
            "Use a DSL type (Float32, Int32, etc.) or @native_struct for the return annotation.",
        ),
    )
    TYPE_DEVICE_FUNC_RETURN_NONE = (
        "The device function has a return type annotation but returned None.",
        (
            "Either add a return statement with a value, or remove the return type annotation.",
        ),
    )
    TYPE_DYNAMIC_EXPR_UNSUPPORTED = (
        "A value carried through this `{body_name}` is a plain {meta} (a `{py_type}`) "
        "that cannot be turned into a {staged}, so the `{body_name}` cannot run at "
        "run time.",
        (
            "Make it a {staged} before the `{body_name}`, e.g. Int32(...), "
            "Float32(...), or Boolean(...).",
            "Or keep the `{body_name}` fully compile-time with `range_constexpr(...)` "
            "/ `const_expr(...)` so the value can stay a {meta}.",
        ),
    )
    TYPE_ITER_ARGS_INVALID = (
        "The iter_args elements must be convertible to runtime values.",
        (
            "Ensure all iter_args elements are DSL types or implement DynamicExpression.",
        ),
    )
    TYPE_LOOP_PARAM_NOT_INT = (
        "The loop parameter must be an integer, not a float.",
        ("Use integer values for start, stop, and step in for_generate().",),
    )
    TYPE_MISSING_ANNOTATION = (
        "`{arg_name}` must have a type annotation. Annotate it with `IRConst`, `IRValue`, `Pointer`, `TensorView`, or `Constexpr`.",
        (
            "Add a type annotation to the parameter, e.g. `def foo({arg_name}: IRValue[Float32]):`.",
        ),
    )
    TYPE_PARAM_NOT_INT = (
        "The parameter must be an integer.",
        ("Use an integer value for this parameter.",),
    )
    TYPE_RETURN_TYPE_NOT_DSL = (
        "The return_types must all be DSL types (Int32, Float32, Boolean, etc.).",
        ("Use DSL types for return_types.",),
    )
    TYPE_TRUTH_OF_DSL_OBJECT = (
        "A `{type}` has no truth value, so it cannot be tested by `if`/`while`, "
        "`not`/`and`/`or` or `bool()`.",
        (
            "Test a property of it explicitly, e.g. a size or shape "
            "(`cute.size(x) > 0`) or an element it holds (`x[0] != 0`).",
        ),
    )
    TYPE_UNSUPPORTED_C_ARG = (
        "Argument type {arg_type} is not supported for C header export. Only numeric types (Int32, Float32, etc.) are supported.",
        (
            "Use a supported numeric type (Int8/16/32/64, Uint8/16/32/64, Float32/64, BFloat16, Float16, Boolean).",
            "Check that your function signature has correct type annotations.",
        ),
    )
    TYPE_UNSUPPORTED_C_EXPORT = (
        "Type {type_name} cannot be exported to a C header. Only numeric types (Int32, Float32, etc.) and @native_struct classes are supported.",
        (
            "Use a supported scalar type (Int8/16/32/64, Uint8/16/32/64, Float32/64, BFloat16, Float16, Boolean) or a @native_struct.",
            "If you need to pass a custom type, define it as a @native_struct with supported fields.",
        ),
    )
    TYPE_UNSUPPORTED_NUMERIC_INPUT = (
        "`{target}` cannot be constructed from {value!r} of type `{value_type}`.",
        (
            "Pass a Python bool, int or float, a DSL Numeric, or an MLIR value of a matching type.",
        ),
    )
    TYPE_UNSUPPORTED_TENSOR = (
        "`{func}` does not support this tensor type.",
        ("Pass a tensor of a supported type, or convert it first.",),
    )
    TYPE_WHILE_INPUTS_INVALID = (
        "The while loop inputs must be convertible to runtime values.",
        ("Ensure all inputs are DSL types or implement DynamicExpression.",),
    )
    # --- UNOBSERVED ---
    UNOBSERVED_WRITE_POSITION_UNKNOWN = (
        "`{var}` was rebound by code the compiler cannot observe (no tracked "
        "assignment recorded the new value), and a for/while/if boundary has "
        "passed since the variable's last tracked access -- the write cannot "
        "be placed at its true position in the compiled program.",
        (
            "Perform the rebind with a plain assignment in jit-decorated code "
            "so the write is tracked at its position.",
            "Or move the rebind so no for/while/if boundary separates it from "
            "the next use of `{var}`.",
        ),
    )
    # --- UNSUP ---
    UNSUP_ARCH = (
        "The `vectorize` attribute requires compute capability 10.0 or higher; your target is `{arch}`.",
        ("Remove the `vectorize` attribute, or build for sm_100 or higher.",),
    )
    UNSUP_BUILTIN = (
        "The built-in function `{name}` is not allowed in compiled code.",
        (
            "Avoid using `{name}` in your kernel code.",
            "If you need dynamic code, refactor to avoid it or pre-compute at setup time.",
        ),
    )
    UNSUP_BUILTIN_FUNCTION = (
        "The built-in function '{fcn}' is not supported by the DSL.",
        ("Use a supported built-in or equivalent DSL function.",),
    )
    UNSUP_COMPARISON_OPERATOR = (
        "The comparison operator '{op}' is not supported.",
        ("Use a supported comparison operator (==, !=, <, >, <=, >=).",),
    )
    UNSUP_FSTRING_ALIGN = (
        "F-string alignment specifiers (<, >, ^) are not supported for {staged} values.",
        (
            "Remove the alignment specifier or format the value before the f-string.",
            'Use a simple format like f"{value:d}" without alignment.',
        ),
    )
    UNSUP_FSTRING_FORMAT = (
        "F-string format specifiers for {staged} values can include at most one specifier.",
        (
            'Use a single format specifier, e.g., f"{value:.2f}".',
            "Compute the formatted value into a variable first if you need multiple transformations.",
        ),
    )
    UNSUP_IN_OPERATOR = (
        "The `in` operator is not supported between these values.",
        ("Use a supported comparison, or restructure the check to avoid `in`.",),
    )
    # --- WRAPPER ---
    WRAPPER_CLASS_MERGE = (
        "`{var}` leaves this for/while/if holding a `{new_cls}`, but entered "
        "it holding a `{old_cls}` over the same compiled type. The two Python "
        "classes have no common replacement, so reads after the region cannot "
        "reconstruct one consistent value.",
        (
            "Use one wrapper class for `{var}` on every path through the for/while/if.",
            "Or convert explicitly before the for/while/if closes so both "
            "paths produce the same class.",
        ),
    )
    WRAPPER_FIELD_WRITE_ON_STAGED_COPY = (
        "`{field}` is written on a `{type}` that was read back through the "
        "compiler as a fresh copy of the tracked value, so the write lands on "
        "that copy: the attribute it was read from never sees the new `{field}`.",
        (
            "Replace the whole value instead of one of its fields, e.g. "
            "`obj.attr = new_value` for the `obj.attr` you read the `{type}` from.",
            "If you need a different `{field}`, build a new `{type}` with it and "
            "assign that whole value.",
        ),
    )
    WRAPPER_REBIND_DUPLICATE_LEAF = (
        "A `{cls}` is replaced inside {region}, but the value it held on "
        "entry stores the SAME compiled value at more than one leaf "
        "position. Carrying the replacement pairs old and new leaves by "
        "value identity, so the repeated positions cannot be told apart and "
        "an update could be silently wired to the wrong one.",
        (
            "Enter the for/while/if with a distinct value at every leaf "
            "position (compute each initial value separately), or update "
            "the positions in place instead of replacing the whole object.",
        ),
    )
    TYPE_STRUCT_ORDER_STAGED = (
        "`{op}` between `{cls}` values runs the dataclass-generated ordering, "
        "which compares the fields lexicographically, and field `{field}` holds "
        "a {staged}; only `==` and `!=` are staged field-wise for dataclasses.",
        (
            "Compare the fields explicitly, e.g. `lhs.{field} {op} rhs.{field}`.",
            "Or compare only fields holding a {meta} so Python's own ordering applies.",
        ),
    )


class WarnId(_DiagMixin, enum.Enum):
    """Author-facing **warnings** (non-fatal) -- a separate catalog from the
    :class:`DiagId` errors so the two namespaces never collide.

    Same shape as ``DiagId`` (member name == stable code, value ==
    ``(message, fix)``) and rendered through the same block, but with a yellow
    ``[Warning]`` header and a ``(warning: CODE)`` label.  Raised via
    :func:`report_warning` / ``DSLWarning(WarnId.X, ...)``.
    """

    PHASE_AUTO_PROMOTED_TO_STAGED = (
        "`{var}` (a {meta}, value {value}) was automatically turned into a {staged} "
        "so it can be updated inside this for/while/if. If you read `{var}` AFTER "
        "the for/while/if, you may still see its original fixed value, not the "
        "updated one.",
        (
            "To be safe, make `{var}` a {staged} before the for/while/if, e.g. "
            "`{var} = {type}({var})`.",
        ),
    )

    TYPE_INT_LITERAL_OUT_OF_RANGE = (
        "The Python integer {value} does not fit in {type} (range "
        "[{min}, {max}]); it was silently truncated to {wrapped}. This drops "
        "the high bits of the original value.",
        (
            "Use a wider integer type that can hold {value}, e.g. "
            "`Int64({value})` or `Uint64({value})`.",
            "If the wrap-around is intentional (e.g. materializing a specific "
            "bit pattern), mask the value to the type width first, e.g. "
            "`{type}({value} & 0x{mask:X})`, to make the intent explicit.",
        ),
    )

    TYPE_FLOAT_TO_INT_OUT_OF_RANGE = (
        "The Python float {value} does not fit in {type} (range "
        "[{min}, {max}]); it was silently narrowed to {result}. "
        "The magnitude of the original value is lost.",
        (
            "Clamp the value to the target range before converting, e.g. "
            "`{type}(max({min}, min({max}, {value})))`.",
            "Or use a wider integer type that can hold {value}.",
            "Do not depend on the exact value {result}: narrowing a float the "
            "target cannot represent has no portable definition.",
        ),
    )

    TYPE_FLOAT_LITERAL_OVERFLOW = (
        "The Python float {value} is larger than the maximum finite {type} "
        "value ({max:g}); it silently became {wrapped}. The magnitude of the "
        "original value is lost.",
        ("Use a wider float type that can hold {value}, e.g. `Float64({value})`.",),
    )

    TYPE_FLOAT_LITERAL_UNDERFLOW = (
        "The Python float {value} is smaller than the smallest nonzero {type} "
        "value ({tiny:g}); it silently became {wrapped}. The original nonzero "
        "value is lost.",
        (
            "Use a wider float type that can represent {value}, e.g. "
            "`Float64({value})`.",
        ),
    )

    HOST_JIT_RETURNS_STAGED = (
        "`{func}` returns a {staged} (`{what}`) to plain Python.",
        (
            "Write the result into a tensor/array argument, or return only "
            "Python values.",
        ),
    )
    TS_AUDIT_ADVISORY = (
        "The task-scheduling audit could not fully verify this schedule "
        "(non-fatal):\n{details}",
        (
            "These findings are advisory: parts of the schedule could not be "
            "proven correct (dynamic values, conditional steps). Review the "
            "listed locations; the compiled kernel is unchanged.",
        ),
    )

    TS_INFRA_DEGRADED = (
        "Task-scheduling audit infrastructure degraded (ignored): {details}",
        (
            "The kernel compiles unaffected, but this schedule was not "
            "audited. Report this warning to the compiler team.",
        ),
    )
    ARG_UNIVERSAL_COPY_ATTRS_IGNORED = (
        "`CopyUniversalOp` ignores {attrs}: the universal copy atom carries no "
        "memory attributes, so they take no effect.",
        (
            "Use `CopyG2ROp` for `invariant`, and use `CopyG2ROp` or `CopyR2GOp` "
            "for `l1c_evict_priority`.",
        ),
    )


def report_warning(
    warn_id: "WarnId",
    *,
    filename: str | None = None,
    lineno: int | None = None,
    stacklevel: int = 2,
    **fields: Any,
) -> None:
    """Emit *warn_id* as a non-fatal :class:`DSLWarning` (does not raise).

    The warning analogue of ``raise DSLUserCodeError(DiagId.X, ...)``: it
    renders through the one shared diagnostic block (yellow ``[Warning]``
    header) and flows through the standard ``warnings`` module so it is
    filterable and deduplicated.
    """
    import warnings

    from .common import DSLWarning  # lazy: avoid an import cycle

    warnings.warn(
        DSLWarning(warn_id, filename=filename, lineno=lineno, **fields),
        stacklevel=stacklevel,
    )
