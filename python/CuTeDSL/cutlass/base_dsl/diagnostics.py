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

so no separate metadata table is needed.
"""

import enum
import linecache
import re
import sys
import textwrap
import types
from dataclasses import dataclass
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
    "NvvmDiagPartialWarpElectSync": _nvvm_info(
        "C13",
        "elect.sync",
        "#parallel-synchronization-and-communication-instructions-elect-sync",
    ),
    _DEVICE_BINARY_SERIALIZATION_DIAGNOSTIC: _CompilerDiagnosticInfo(""),
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
    ) -> None:
        self.context = context
        self.remark_filter = remark_filter
        # Checker domains whose warnings the DSL shows (from --warnings{<cat>}).
        # Errors always show; warnings are gated to these domains; remarks are
        # gated at collection by the remark filter.
        self.warnings_filter = warnings_filter
        self.remark_output = remark_output
        self.collect_diagnostics = bool(collect_diagnostics and not remark_output)
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
            return ""
        return format_compiler_diagnostics(self._collected_diagnostics())

    def format_failure(self, raw_error: str) -> str:
        if not self.collect_diagnostics:
            return ""
        return format_compiler_failure_diagnostics(
            self._collected_diagnostics(), raw_error
        )

    def format_backend_failure(
        self,
        *,
        raw_error: str,
        nvvm_error: str = "",
        ir_context: str = "",
        arch: str = "",
        location: str = "",
    ) -> str:
        return format_compiler_backend_failure(
            raw_error=raw_error,
            nvvm_error=nvvm_error,
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


def _warning_domain(name: str) -> str:
    """Map a warning's name to its checker domain, for --warnings{} gating."""
    if name.startswith("NvvmDiag"):
        return "nvvm"
    return ""


def _filter_warning_visibility(
    diagnostics: Sequence[CompilerDiagnostic], warnings_filter: str
) -> list[CompilerDiagnostic]:
    """Drop warnings whose checker domain is not enabled via --warnings{<cat>}.

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
        # (generic) warnings show whenever any --warnings{} was passed.
        if domain in domains or (not domain and domains):
            out.append(diag)
    return out


def _filter_remark_visibility(
    diagnostics: Sequence[CompilerDiagnostic], remark_filter: str
) -> list[CompilerDiagnostic]:
    """Drop opt-in remarks unless --remarks{} requested them.

    Errors and warnings always pass (warnings are already gated by
    _filter_warning_visibility). Opt-in remarks are shown only when --remarks{}
    set a concrete category: the engine then narrowed them to those categories
    at collection. When no --remarks{} was passed the filter defaults to the
    match-all sentinel (``.*``) — which the engine cannot use to suppress at
    collection time — so we treat that default as "not requested" and drop the
    remarks here. Errors/warnings (always-on) are unaffected."""
    requested = remark_filter.strip()
    if requested and requested not in (".*", "all"):
        return list(diagnostics)
    return [diag for diag in diagnostics if diag.severity != "remark"]


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

    filter_str = remark_filter or ".*"
    if collect_diagnostics:
        # Collecting path (a checker is enabled via warnings{}/remarks{}):
        # errors/warnings are always-on and collected regardless of any filter
        # (warnings are gated later at display by --warnings{}). A non-empty
        # remark filter narrows opt-in remarks to the requested categories, but
        # an empty filter is read as match-all by the engine. So opt-in remarks
        # are gated at display instead (see _filter_remark_visibility): they are
        # shown only when --remarks{} was passed.
        opt_filter = remark_filter or ""
        if opt_filter == "ptxas":
            opt_filter = "ptxas.*"
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
    return _dedupe_compiler_diagnostics(diagnostics)


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
    frame = _format_user_source_frame(filename, line, col, end_col)
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
    parts = [
        f"\n{_Colors.RED}{_Colors.BOLD}[Internal Error] The compiler hit a "
        f"problem it could not trace back to your code.{_Colors.RESET}",
        "This is a bug in the DSL, not a mistake in your kernel.\n",
    ]
    if frame:
        parts.append(f"{_Colors.BLUE}Closest point in your code:{_Colors.RESET}")
        parts.append(frame)
        parts.append("")
    if err.message:
        parts.append(f"{_Colors.BLUE}Detail:{_Colors.RESET} {err.message}")
        parts.append("")
    if cause_text:
        parts.append(f"{_Colors.BLUE}Cause:{_Colors.RESET} {cause_text}")
        parts.append("")
    parts.append(f"{_Colors.GREEN}What to do:{_Colors.RESET}")
    parts.append(
        f"  {_Colors.GREEN}Please report this with the snippet above and your "
        f"kernel.{_Colors.RESET}"
    )
    parts.append(
        f"  {_Colors.GREEN}Re-run with CUTE_DSL_SHOW_STACKTRACE=1 to include the "
        f"full technical detail.{_Colors.RESET}"
    )
    parts.append("")
    parts.append("=" * 100)
    return "\n".join(parts)


def _nearest_function_name(lines: list[str], line_no: int) -> str | None:
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
    filename: str, line: int, col: int | None, end_col: int | None
) -> list[str]:
    source_lines = _read_source_lines(filename)
    loc = _format_source_location(
        filename, line, col, absolute_path=False, col_zero_based=True
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
        lines.extend(_format_labeled_text(reason_label, diag.reason))
    if diag.suggestion:
        lines.extend(_format_labeled_text("suggestion", diag.suggestion))
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


def format_compiler_backend_failure(
    *,
    raw_error: str,
    nvvm_error: str = "",
    ir_context: str = "",
    arch: str = "",
    location: str = "",
) -> str:
    """Render an unstructured backend failure with compiler diagnostic styling."""

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

    if severity == "remark":
        # Remarks are keyed by their category (e.g. "ptxas"), not the
        # error/warning code table.
        code = str(item.get("category", "")) or name
        namespace = ""
        ptx_ref = ""
        ptx_url = ""
    else:
        info = _COMPILER_DIAGNOSTICS.get(name)
        code = info.code if info else str(item.get("remark_id", ""))
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


def format_compiler_failure_diagnostics(
    diagnostics: Sequence[CompilerDiagnostic], raw_error: str
) -> str:
    diagnostics = _dedupe_compiler_diagnostics(diagnostics)
    formatted = format_compiler_diagnostics(diagnostics)
    if not formatted:
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
    SCOPE_READ_NEVER_SET = (
        "A variable is read on a path where it was never given a value. It must be "
        "set before it is read, on every path that can reach this point.",
        (
            "Set the variable before the for/while/if, or set it on every branch "
            "that can reach this read.",
        ),
    )
    CONTAINER_TUPLE_LENGTH_CHANGED = (
        "`{var}` is a tuple with {old} item(s) on one pass and {new} on another. A "
        "tuple must keep the same number of items every pass so its parts can be "
        "followed.",
        ("Keep `{var}` the same length on every branch and every loop pass.",),
    )
    CONTAINER_STRUCTURE_CHANGED = (
        "`{var}` has a different structure at the end of this `{op_type}` than at "
        "the start. A value carried through a `{op_type}` must keep the same shape "
        "(same fields and the same number of parts) on every pass.",
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
    CONTAINER_OBJECT_REPLACED = (
        "`{var}` is replaced as a whole object inside a for/while/if, but it holds "
        "runtime values that cannot be followed through a whole-object replacement.",
        (
            "Update the individual fields of `{var}` instead, e.g. "
            "`{var}.field = new_value`.",
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
    UNSUP_MIXED_ASSIGN_TARGETS = (
        "An assignment that mixes plain names, subscripts, and tuple targets on a "
        "single line is not supported here.",
        ("Split it into separate assignment statements, one kind of target per line.",),
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
    ARG_BIND_FAILED = (
        "The arguments do not match the function signature.",
        ("Check that you are passing the correct number and types of arguments.",),
    )
    ARG_COUNT_MISMATCH = (
        "Passed {got} argument(s) to FFI function, but it expects {expected}",
        ("Check the function signature and provide the correct number of arguments",),
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
        ("Pass a non-negative address, or use nullptr() for null pointers",),
    )
    ARG_SPLIT_MODE_INVALID = (
        "The split_mode must be one of the valid CudaDlcSplitMode enum values.",
        (
            "Use cuda_helpers.CudaDlcSplitMode enum: NONE, ANY, SINGLE_DLCC, or DUAL_DLCC.",
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
    CALL_EXPERIMENTAL_MISMATCH = (
        "The is_experimental flag does not match the function's DSL routing. Either remove the flag or use @cute.jit(is_experimental=True).",
        (
            "If using experimental DSL, decorate the function with @cute.jit(is_experimental=True).",
            "Otherwise, remove the is_experimental=True flag from cute.compile().",
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
        "The `@kernel` decorator with `attributes=` is not supported by this DSL. Only experimental CuTe supports this feature.",
        (
            "Remove the `attributes=` parameter from the @kernel decorator.",
            "Or use `@cute.experimental.kernel(attributes=...)` if you need kernel-level attributes.",
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
        "{vars} requires the 'nvdisasm' tool to write SASS output, but it is not found in PATH.",
        (
            "Install the CUDA Toolkit from https://developer.nvidia.com/cuda-downloads; if CUDA is installed, add its bin directory to PATH: export PATH=/usr/local/cuda/bin:$PATH",
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
    CONFIG_VERSION_MISSING = (
        "When checking a version range, at least min_version or max_version must be provided.",
        (
            'Set min_version="X.Y" to check minimum,',
            'set max_version="X.Y" to check maximum,',
            "or set both for a range between them.",
        ),
    )
    CONFIG_VERSION_RANGE_INVALID = (
        "The minimum version cannot be greater than or equal to the maximum version. Swap them or fix the range.",
        (
            'Ensure min_version < max_version, e.g., min_version="12.0", max_version="13.0"',
        ),
    )
    CONFIG_VERSION_REQUIRED = (
        "At least one version parameter is required.",
        (
            'Provide exact_version="X.Y" for a specific version,',
            'or min_version="X.Y" and/or max_version="X.Y" for a version range.',
        ),
    )
    CONFIG_VERSION_TYPE = (
        '{param_name} must be a version string (e.g., "12.3") or DSLCudaVersion, not {got_type}',
        (
            'Pass a version string like "12.3" or use DSLCudaVersion("{version_string}")',
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
    LAUNCH_MISSING_ARG = (
        "Required argument `{name}` is missing when launching kernel `{kernel_name}`.",
        ("Pass a value for `{name}` to the kernel launch.",),
    )
    # --- PHASE ---
    PHASE_CONDITIONAL_NOT_DYNAMIC = (
        "The condition must be a {staged} value, not a {meta}.",
        ("Ensure the condition is a runtime value (Boolean, Int32, etc.).",),
    )
    PHASE_DYNAMIC_INDEX = (
        "Cannot use a {staged} value as a list index or for loop range in plain Python code",
        (
            "Mark the loop as dynamic with @dynamic_expr or @range_dynamic",
            "Decorate the parent function with @jit so the indexing happens in staged code where {staged} values are allowed",
        ),
    )
    PHASE_DYNAMIC_TO_STATIC_BOOL = (
        "Cannot use a {staged} value where a {meta} boolean is required (e.g. in plain Python control flow)",
        (
            "Decorate the function with @jit and ensure preprocess is enabled so control flow is staged",
            "Or move the boolean check inside a staged for/while/if block where {staged} values are allowed",
        ),
    )
    PHASE_REQUIRES_CONSTANT = (
        "{what} requires a value known at code-read time, but you gave it a {staged}.",
        (
            "Make the value a Python constant (a literal or a value computed only from Python values).",
            "If the value is only known at run time, use the runtime form instead (for example a runtime `if`/loop or a runtime assert).",
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
    # --- TYPE ---
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
    TYPE_UNSUPPORTED_TENSOR = (
        "`{func}` does not support this tensor type.",
        ("Pass a tensor of a supported type, or convert it first.",),
    )
    TYPE_WHILE_INPUTS_INVALID = (
        "The while loop inputs must be convertible to runtime values.",
        ("Ensure all inputs are DSL types or implement DynamicExpression.",),
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
