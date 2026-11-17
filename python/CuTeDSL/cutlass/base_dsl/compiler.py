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

"""
This module provides a class that compiles generated IR using MLIR's PassManager
and executes it using MLIR's ExecutionEngine.

"""

from typing import Any
import collections.abc
import copy
import contextlib
import copy
import functools
import importlib.util
import os
import re
import shlex
import sys
import inspect
import types
from .common import DSLBaseError, DSLUserCodeError
from .dsl_lock import with_dsl_lock
from . import diagnostics as _diagnostics
from .utils.logger import log
from .env_manager import EnvironmentVarManager

def _escape_windows_backslashes(text: str) -> str:
    """Double every backslash that POSIX shlex would treat as an escape.

    Single-quoted spans are copied unchanged: shlex already keeps their
    backslashes literal, so doubling there would leave two in the value.
    """
    out = []
    in_single = in_double = False
    for ch in text:
        if ch == "'" and not in_double:
            in_single = not in_single
        elif ch == '"' and not in_single:
            in_double = not in_double
        elif ch == "\\" and not in_single:
            ch = "\\\\"
        out.append(ch)
    return "".join(out)


def _split_options(text: str) -> list[str]:
    """shlex.split an option string, keeping Windows path separators intact.

    POSIX lexing treats "\\" as an escape, which silently turns an option like
    ``--dump-dir=C:\\Temp\\x`` into ``--dump-dir=C:Tempx``. Doubling the
    backslashes first makes them literal without disturbing any other quoting
    rule.
    """
    if os.name == "nt":
        text = _escape_windows_backslashes(text)
    return shlex.split(text)


def _join_compact_option_fragments(
    split_tokens: list[str],
    compact_names: frozenset[str],
    legacy_value_flags: set[str],
) -> list[str]:
    """Reassemble whitespace-separated fragments of compact brace options.

    Only a registered compact-option spelling can start a fragment. Literal
    braces in legacy option values retain normal shell-token semantics.
    """
    tokens: list[str] = []
    brace_fragments: list[str] = []
    brace_depth = 0
    previous_is_legacy_value_flag = False
    for token in split_tokens:
        if brace_fragments:
            brace_fragments.append(token)
            brace_depth += token.count("{") - token.count("}")
            if brace_depth <= 0:
                tokens.append(" ".join(brace_fragments))
                brace_fragments.clear()
            continue

        brace_depth = token.count("{") - token.count("}")
        spelling = token[2:] if token.startswith("--") else token
        option_name = spelling.split("{", 1)[0].rsplit(",", 1)[-1]
        if (
            not previous_is_legacy_value_flag
            and brace_depth > 0
            and option_name in compact_names
        ):
            brace_fragments.append(token)
        else:
            tokens.append(token)
        previous_is_legacy_value_flag = token in legacy_value_flags

    if brace_fragments:
        tokens.append(" ".join(brace_fragments))
    return tokens


# msvcrt's FILE is 48 bytes on x64 and stdout is __iob[1]; _IONBF is 4.
_MSVCRT_FILE_SIZE = 48
_IONBF = 4
_jit_c_stdout_unbuffered = False


def _unbuffer_jit_c_stdout() -> None:
    """Unbuffer the C stdout that the JIT's ``printf`` writes to (Windows).

    LLVM binds the JIT's ``printf`` by scanning the process's loaded modules
    for an export of that name. The UCRT does not export one -- ``printf`` is
    inline in its <stdio.h> -- so the search lands on the legacy
    ``msvcrt.dll``, whose C stdout is a stream of its own, unrelated to the one
    Python writes through. On a pipe it is fully buffered and flushed only when
    msvcrt runs its exit handler, so every ``cute.printf`` line surfaces after
    all Python output rather than interleaving in program order.

    Any Windows caller mixing ``cute.printf`` with Python output sees this, not
    just the test harness. ``PYTHONUNBUFFERED`` does not address it: that
    controls Python's own stdout, not msvcrt's, so setting it unbuffers one side
    and leaves the other buffered -- which is the skew itself.

    Done once when the execution engine is built, so nothing lands on the
    execution path, and it touches only msvcrt's stdout, which no other part of
    the process writes to. No-op off Windows, where ``printf`` resolves to the
    same libc Python is already sharing.
    """
    global _jit_c_stdout_unbuffered
    if _jit_c_stdout_unbuffered or os.name != "nt":
        return
    # Only ever attempt this once, successful or not.
    _jit_c_stdout_unbuffered = True
    import ctypes

    try:
        msvcrt = ctypes.CDLL("msvcrt.dll")
        iob_func = getattr(msvcrt, "__iob_func")
        iob_func.restype = ctypes.c_void_p
        msvcrt._fileno.restype = ctypes.c_int
        msvcrt._fileno.argtypes = [ctypes.c_void_p]
        msvcrt.setvbuf.argtypes = [
            ctypes.c_void_p,
            ctypes.c_void_p,
            ctypes.c_int,
            ctypes.c_size_t,
        ]
        stdout = iob_func() + _MSVCRT_FILE_SIZE
        # Confirm the FILE stride against the descriptor rather than trusting
        # the struct layout blindly; leave the stream alone if it disagrees.
        if msvcrt._fileno(stdout) != 1:
            log().warning("msvcrt stdout not found at __iob[1]; leaving buffered")
            return
        msvcrt.setvbuf(stdout, None, _IONBF, 0)
    except (OSError, AttributeError) as e:
        log().warning(f"could not unbuffer the JIT's C stdout: {e}")


from .._mlir import ir


# =============================================================================
# Compiler Class
# =============================================================================

# Each entry is (marker, separator preceding the log, backend). Match ptxas
# before libNVVM so a PTX-to-SASS failure is attributed to the correct stage.
_BACKEND_FAILURE_MARKERS: tuple[tuple[str, str, str], ...] = (
    # Normalized CudaToBinaryPass diagnostic.
    ("PTXAS_ERROR", "ptxas log:", "ptxas"),
    # The public chip-specific helper names its target in the diagnostic.
    ("NVPTX compiler invocation failed for chip", ", error log:", "ptxas"),
    ("NVVM_ERROR", "libNVVM extra log:", "nvvm"),
)


class CompilerDiagnosticError(DSLBaseError):
    """Compilation failed with Python-rendered compiler diagnostics."""

    def __init__(
        self,
        formatted: str,
        raw_error: str = "",
        *,
        backend: str = "",
        nvvm_error: str = "",
        ptxas_error: str = "",
        ir_context: str = "",
        arch: str = "",
    ) -> None:
        self.formatted = formatted
        self.raw_error = raw_error
        self.backend = backend
        self.nvvm_error = nvvm_error
        self.ptxas_error = ptxas_error
        self.ir_context = ir_context
        self.arch = arch
        super().__init__(formatted)

    def _format_message(self) -> str:
        return self.message

    def __str__(self) -> str:
        return self.formatted


def _strip_mlir_continuation_indent(text: str) -> str:
    """Remove MLIR's continuation indent from a multi-line diagnostic."""
    continuation_indent = "  "
    first, separator, rest = text.partition("\n")
    if not separator:
        return text
    lines = rest.split("\n")
    if not all(
        line.startswith(continuation_indent) or not line.strip() for line in lines
    ):
        return text
    return "\n".join([first, *(line[len(continuation_indent) :] for line in lines)])


_JitEngineFactory = collections.abc.Callable[
    [ir.Module, collections.abc.Sequence[str]], Any
]


class Compiler:
    """Compiler class for compiling and building MLIR modules."""

    def __init__(self, passmanager: Any, execution_engine: Any) -> None:
        self.passmanager = passmanager
        self.execution_engine = execution_engine
        self._post_compile_hook: collections.abc.Callable[[Any], None] | None = None
        self._jit_engine_factory: _JitEngineFactory | None = None

    def _process_error(self, error_msg: str) -> tuple[str, str, str, str]:
        """Split a backend failure into (compiler log, IR context, location, backend).

        The backend is "" when `error_msg` is not a backend failure at all.
        """
        location = _diagnostics.extract_compiler_location(error_msg)

        for marker, separator, backend in _BACKEND_FAILURE_MARKERS:
            if marker not in error_msg:
                continue

            # maxsplit=1: the compiler log can contain the separator itself (a
            # libNVVM failure whose text already quotes its own log, say), and
            # splitting on every occurrence would keep only the part before the
            # second one and drop the log we are trying to surface.
            if separator in error_msg:
                backend_error = error_msg.split(separator, 1)[1].strip()
            else:
                # Marker-only C++ patterns carry no dedicated log separator.
                # Keep the payload after the marker without the surrounding
                # MLIR diagnostic prefix (for example, "error: unknown:").
                backend_error = error_msg.split(marker, 1)[1].lstrip(" ,:").strip()
                if not backend_error:
                    backend_error = marker
            backend_error = _strip_mlir_continuation_indent(backend_error)

            # Extract IR context
            ir_msg = ""
            if "see current operation:" in error_msg:
                # Get the IR section
                ir_section = error_msg.split("see current operation:")[1].strip()
                # Remove duplicate IR section
                ir_section = ir_section.split("error: unknown: Failed translating")[
                    0
                ].strip()

                # Get first few lines and last few lines of the IR
                ir_lines = ir_section.split("\n")
                if len(ir_lines) > 10:
                    ir_msg = "\n".join(ir_lines[:5] + ["  ..."] + ir_lines[-5:])
                else:
                    ir_msg = ir_section

            return backend_error, ir_msg, location, backend

        return "", "", location, ""

    def compile(
        self,
        module: ir.Module,
        pipeline: str,
        arch: str = "",
        enable_debug_info: bool = False,
        enable_verifier: bool = False,
        *,
        remark_filter: str = "",
        warnings_filter: str = "",
        remark_output: str = "",
        collect_compiler_diagnostics: bool = False,
        warnings_as_errors: bool = False,
    ) -> ir.Module:
        """Compiles the module by invoking the pipeline and returns it.

        Subclasses overriding this method should return the compiled module so
        compile_and_jit callers can optionally retain the finalized IR.
        """
        diagnostic_session = _diagnostics.CompilerDiagnosticSession(
            ir.Context.current,
            remark_filter=remark_filter,
            warnings_filter=warnings_filter,
            remark_output=remark_output,
            collect_diagnostics=collect_compiler_diagnostics,
            warnings_as_errors=warnings_as_errors,
        )
        try:
            pm = self.passmanager.PassManager.parse(pipeline)
            pm.enable_verifier(enable_verifier)

            # Enable diagnostic collection or remark streaming when configured.
            diagnostic_session.enable()

            with diagnostic_session.collecting():
                pm.run(module.operation)
            formatted = diagnostic_session.format_success()
            if warnings_as_errors and diagnostic_session.warnings_promoted_to_errors:
                raise CompilerDiagnosticError(formatted)
            if formatted:
                print(formatted, file=sys.stderr)
        except CompilerDiagnosticError:
            # A promoted ptxas spill is already a structured compiler
            # diagnostic. Do not reclassify it as a backend failure.
            raise
        except Exception as e:
            if diagnostic_session.collect_diagnostics:
                formatted = diagnostic_session.format_failure(str(e))
                if formatted:
                    raise CompilerDiagnosticError(formatted, raw_error=str(e)) from e
            error_msg = str(e)
            backend_error = ir_msg = location = backend = ""
            # When warnings/remarks are enabled, the scoped MLIR diagnostic
            # collector consumes regular error diagnostics. MLIRError then only
            # contains the generic pass-failure text, so also inspect the
            # collected messages for a backend marker and its original log.
            error_candidates = (
                error_msg,
                *diagnostic_session._collected_error_texts(),
            )
            for candidate in error_candidates:
                processed = self._process_error(candidate)
                if processed[3]:
                    backend_error, ir_msg, location, backend = processed
                    error_msg = candidate
                    break

            if backend_error:
                ir_context = ir_msg or ""
                is_ptxas = backend == "ptxas"
                nvvm_error = "" if is_ptxas else backend_error
                ptxas_error = backend_error if is_ptxas else ""
                formatted = diagnostic_session.format_backend_failure(
                    raw_error=error_msg,
                    nvvm_error=nvvm_error,
                    ptxas_error=ptxas_error,
                    ir_context=ir_context,
                    arch=arch,
                    location=location,
                )
                raise CompilerDiagnosticError(
                    formatted,
                    raw_error=error_msg,
                    backend=backend,
                    nvvm_error=nvvm_error,
                    ptxas_error=ptxas_error,
                    ir_context=ir_context,
                    arch=arch,
                ) from e
            formatted = _diagnostics.format_compiler_failure_diagnostics((), error_msg)
            if formatted:
                raise CompilerDiagnosticError(formatted, raw_error=error_msg) from e
            raise e
        finally:
            # Finalize remark output after passes complete
            diagnostic_session.finalize()

        if self._post_compile_hook:
            self._post_compile_hook(module)
        return module

    def jit(
        self,
        module: ir.Module,
        opt_level: int = 2,
        shared_libs: collections.abc.Sequence[str] = (),
    ) -> Any:
        """Wraps the module in a JIT execution engine."""
        _unbuffer_jit_c_stdout()
        if self._jit_engine_factory is not None:
            return self._jit_engine_factory(module, shared_libs)
        return self.execution_engine.ExecutionEngine(
            module, opt_level=opt_level, shared_libs=shared_libs
        )

    def compile_and_jit(
        self,
        module: ir.Module,
        pipeline: str,
        shared_libs: collections.abc.Sequence[str] = (),
        opt_level: int = 2,
        arch: str = "",
        enable_debug_info: bool = False,
        enable_verifier: bool = False,
        return_module: bool = False,
        *,
        remark_filter: str = "",
        warnings_filter: str = "",
        remark_output: str = "",
        collect_compiler_diagnostics: bool = False,
        warnings_as_errors: bool = False,
    ) -> Any:
        """Compiles and jits the module."""
        compiled_module = self.compile(
            module,
            pipeline,
            arch,
            remark_filter=remark_filter,
            warnings_filter=warnings_filter,
            remark_output=remark_output,
            collect_compiler_diagnostics=collect_compiler_diagnostics,
            warnings_as_errors=warnings_as_errors,
            enable_debug_info=enable_debug_info,
            enable_verifier=enable_verifier,
        )

        engine = self.jit(compiled_module, opt_level, shared_libs)
        if return_module:
            return engine, compiled_module
        return engine


class PostCompileHookContext:
    """Scope module finalization and an optional matching execution-engine factory.

    A custom factory receives the finalized module and its shared libraries, and
    controls the host optimization level. Both hooks are restored on exit.
    """

    def __init__(
        self,
        compiler: Compiler,
        hook: collections.abc.Callable[[Any], None],
        *,
        jit_engine_factory: _JitEngineFactory | None = None,
    ) -> None:
        self.compiler = compiler
        self.hook = hook
        self.jit_engine_factory = jit_engine_factory
        self.prev_jit_engine_factory: _JitEngineFactory | None = None
        self.prev_post_compile_hook: collections.abc.Callable[[Any], None] | None = None

    def __enter__(self) -> "PostCompileHookContext":
        self.prev_post_compile_hook = self.compiler._post_compile_hook
        self.compiler._post_compile_hook = self.hook
        self.prev_jit_engine_factory = self.compiler._jit_engine_factory
        self.compiler._jit_engine_factory = self.jit_engine_factory
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: types.TracebackType | None,
    ) -> None:
        self.compiler._post_compile_hook = self.prev_post_compile_hook
        self.compiler._jit_engine_factory = self.prev_jit_engine_factory


_OPTION_REGISTRY: "list[type[CompileOption]]" = []


def register_option(cls: "type[CompileOption]") -> "type[CompileOption]":
    """Register a concrete compile-option class in declaration order.

    The registry is the single source from which the defaults dict and the
    string-API argparse / dest tables are derived. Abstract base classes are
    left undecorated so they never register.
    """
    _OPTION_REGISTRY.append(cls)
    return cls


class CompileOption:
    """Base class for compile options.

    * ``_option_name`` -- pipeline-string token, also the compact ``name=value``
      key; ``None`` marks a non-pipeline option (``serialize()`` returns ``""``).
    * ``_cli_flag`` -- string-API flag name without the ``--`` prefix; defaults
      to ``_option_name``, so spell it out only when the two differ. ``None``
      means no argparse flag.
    * ``_value_kind`` -- argparse value kind: ``"bool"`` / ``"int"`` / ``"str"``.
    * ``_default`` -- default value for the defaults dict.
    * ``_reconstruct_on_assign`` -- rebuild via the constructor on the string
      merge path instead of assigning ``.value``.
    """

    _option_name: "str | None" = None
    _cli_flag: "str | None" = None
    _value_kind: str = "str"
    _default: Any = ""
    _reconstruct_on_assign: bool = False

    def __init_subclass__(cls, **kwargs: Any) -> None:
        super().__init_subclass__(**kwargs)
        if "_cli_flag" not in cls.__dict__:
            cls._cli_flag = cls._option_name

    def __init__(self, val: Any) -> None:
        self._value: Any = val

    def serialize(self) -> str:
        if self.__class__._option_name is None:
            return ""
        return f"{self.__class__._option_name}={self._value}"

    @property
    def value(self) -> Any:
        return self._value

    @value.setter
    def value(self, value: Any) -> None:
        self._value = value


class BooleanCompileOption(CompileOption):
    _value_kind = "bool"
    _default = False

    def __init__(self, val: bool = True) -> None:
        super().__init__(val)

    def serialize(self) -> str:
        if self.__class__._option_name is None:
            return ""
        return f"{self.__class__._option_name}={'true' if self._value else 'false'}"


class StringCompileOption(CompileOption):
    _value_kind = "str"
    _default = ""

    def __init__(self, val: str = "") -> None:
        super().__init__(val)

    def serialize(self) -> str:
        if self._value and self.__class__._option_name:
            value = self._value.strip("'")
            return f"{self.__class__._option_name}='{value}'"
        return ""


@register_option
class DivmodSemantics(StringCompileOption):
    """Select the semantics of DSL ``//`` and ``%`` operators.

    ``python`` uses :func:`cute.math.floordiv` and :func:`cute.math.mod`.
    ``legacy`` preserves the existing operator behavior without warnings.
    When unspecified (the default), operators keep the legacy behavior and
    emit migration warnings for affected operators. Explicit math APIs keep
    their own semantics.

    :param val: Operator semantics, ``python``, ``legacy``, or empty for
        unspecified, defaults to empty.
    :type val: str

    Example:

    .. code-block:: python

        compiled = cute.compile(fn, *args, options="--divmod-semantics=python")
    """

    _cli_flag = "divmod-semantics"
    _default = ""
    _reconstruct_on_assign = True

    def __init__(self, val: str = "") -> None:
        if val not in ("", "python", "legacy"):
            raise ValueError(
                f"divmod-semantics must be 'python' or 'legacy', got {val!r}"
            )
        super().__init__(val)


class BooleanBasedFileDumpOption(BooleanCompileOption):
    def __init__(self, val: bool = True) -> None:
        super().__init__(val)
        self._dump_path: str = ""

    @property
    def dump_path(self) -> str:
        return self._dump_path

    @dump_path.setter
    def dump_path(self, path: str) -> None:
        self._dump_path = path

    def serialize(self) -> str:
        if self._value and self.__class__._option_name:
            assert self._dump_path, (
                f"Dump path is not set for {self.__class__.__name__}"
            )
            return f"{self.__class__._option_name}='{self._dump_path}'"
        return ""


@register_option
class OptLevel(CompileOption):
    _option_name = "opt-level"
    _value_kind = "int"
    _default = 3

    def __init__(self, val: int) -> None:
        if val < 0 or val > 3:
            raise DSLUserCodeError(
                _diagnostics.DiagId.CONFIG_INVALID_OPT_LEVEL, val=val
            )
        super().__init__(val)



@register_option
class EnablePYIR(BooleanCompileOption):
    _option_name = "enable-pyir"


@register_option
class FrontendNext(BooleanCompileOption):
    """Write your kernel as ordinary Python; the compiler does the plumbing.

    Select this frontend when compiling::

        compiled = cute.compile[FrontendNext](fn, *args)

    It lets ``fn`` carry your own Python objects through ``if`` / ``while`` /
    ``for`` and mutate their fields in place. The compiler tracks each read and
    write and threads the updated object across iterations and branches for you.

    A small state object, updated each iteration, just works::

        class Stats:
            def __init__(self):
                self.total = Int32(0)
                self.count = Int32(0)

            @cute.jit
            def update(self, x):
                self.total += x          # field mutation, carried across iterations
                self.count += Int32(1)

        @cute.jit
        def fn(n: Int32):
            stats = Stats()
            for i in range(n):
                stats.update(Int32(2))
            return stats.total

    Without this frontend the same loop is rejected -- a plain ``Stats`` cannot
    be carried through a runtime ``for`` -- unless the class hand-implements the
    value flatten / rebuild protocol (``__extract_mlir_values__`` /
    ``__new_from_mlir_values__``). Here you just write and mutate the class.

    Options compose, e.g. to also emit line info::

        cute.compile[FrontendNext, GenerateLineInfo(True)](fn, *args)
    """


@register_option
class EnableCuteExtCompile(BooleanCompileOption):
    """Enable CuTe extension compilation for this compile invocation.

    This option selects the CuTe extension compiler even when it is not enabled
    globally::

        compiled = cute.compile[cute.EnableCuteExtCompile](fn, *args)

    ``DisableCuteExtCompile`` remains the safety override if both routing
    options are selected.
    """


@register_option
class DisableCuteExtCompile(BooleanCompileOption):
    """Disable CuTe extension compilation for this compile invocation.

    This option skips the CuTe extension compiler even when extension
    compilation is enabled globally. Use it only when the program does not
    require CuTe extension compiler support::

        compiled = cute.compile[cute.DisableCuteExtCompile](fn, *args)

    Operations that require CuTe extension compiler support are unsupported
    when this option is selected and may fail during tracing or lowering.
    """



@register_option
class ExtraCompilerOpts(CompileOption):
    """Raw MLIR pass options from CUTE_DSL_COMPILER_OPT, serialized verbatim.

    Also owns ``COMPACT_FLAGS``, which maps a compact-token shorthand to the
    MLIR flag it enables plus the flag prefix for its brace-listed
    sub-features: ``name`` and ``name{}`` emit ``<flag>=true``; ``name{a}``
    additionally emits ``<prefix>a=true``, and ``name{a=false}`` emits
    ``<prefix>a=false``. Sub-feature names are forwarded as-is; the pipeline
    rejects unknown ones.
    """

    COMPACT_FLAGS: "dict[str, tuple[str, str | None]]" = {
        "iket": ("enable-iket", None),
        "fast-divmod": ("use-auto-fdd-pass", None),
        "grid-invariant-code-motion": ("use-grid-invariant-code-motion-pass", None),
    }

    def __init__(self, val: str = "") -> None:
        super().__init__(val)

    def serialize(self) -> str:
        return self._value

    @staticmethod
    def takes_sub_options(name: str) -> bool:
        flag_and_prefix = ExtraCompilerOpts.COMPACT_FLAGS.get(name)
        return flag_and_prefix is not None and flag_and_prefix[1] is not None

    @staticmethod
    def expand(name: str, sub_str: "str | None") -> "list[str]":
        """Expand compact token ``name`` / ``name{sub,...}`` into raw flags.

        A sub-option may be written either way:

        * ``name{sub}``        -> ``<prefix>sub=true``   (enable)
        * ``name{sub=value}``  -> ``<prefix>sub=value``  (explicit)

        Listing a sub-feature enables it, matching the bare token itself, which
        emits ``<flag>=true``. Turning something off is therefore always
        written out: ``name{sub=false}``.

        NOTE: the bare form previously expanded to ``=false``. Spellings that
        relied on that -- ``strength-reduction{circular-counter}`` was the only
        one -- must now say ``{circular-counter=false}`` to keep their meaning.
        """
        flag, sub_prefix = ExtraCompilerOpts.COMPACT_FLAGS[name]
        if sub_str is not None and sub_prefix is None:
            raise ValueError(f"option '{name}' does not take {{...}} sub-options")
        # Do not filter empty entries: dropping them would silently accept
        # malformed spellings such as a trailing or doubled comma.
        subs = [] if sub_str is None else [s.strip() for s in sub_str.split(",")]
        flags = [f"{flag}=true"]
        for sub in subs:
            if not sub:
                raise ValueError(
                    f"option '{name}': empty sub-option; remove the extra comma"
                )
            key, sep, value = sub.partition("=")
            key = key.strip()
            value = value.strip()
            if not key:
                raise ValueError(f"option '{name}': empty sub-option name in '{sub}'")
            if sep and not value:
                raise ValueError(
                    f"option '{name}': sub-option '{key}=' has no value; "
                    f"write '{key}=<value>' or bare '{key}' to enable it"
                )
            flags.append(f"{sub_prefix}{key}={value if sep else 'true'}")
        return flags


def _ensure_ptxas_verbose(options: str) -> str:
    stripped = (options or "").strip()
    if len(stripped) >= 2 and stripped[0] == stripped[-1] and stripped[0] in "'\"":
        stripped = stripped[1:-1]
    try:
        tokens = _split_options(stripped) if stripped else []
    except ValueError:
        tokens = stripped.split()
    if any(token in ("-v", "--verbose") for token in tokens):
        return stripped
    return f"{stripped} -v".strip()


def _ensure_compiler_diagnostic_selector(options: str, selector: str) -> str:
    match = re.search(r"(^|\s)diagnostic=([^\s]+)", options)
    if not match:
        return f"{options} diagnostic={selector}".strip()

    selectors = {item for item in match.group(2).split(",") if item}
    if selector in selectors:
        return options

    selectors.add(selector)
    replacement = f"{match.group(1)}diagnostic={','.join(sorted(selectors))}"
    return options[: match.start()] + replacement + options[match.end() :]


@register_option
class PtxasOptions(StringCompileOption):
    _option_name = "ptx-options"
    _cli_flag = "ptxas-options"


@register_option
class RDC(BooleanCompileOption):
    """Compile as relocatable device code (``ptxas -c``).

    Enabled automatically by ``DeviceTarget``.  In the future, can be
    used directly with kernel compilation to produce linkable objects.
    """

    _option_name = "rdc"


@register_option
class EnableAssertions(BooleanCompileOption):
    _option_name = "enable-assertions"


@register_option
class GenerateLineInfo(BooleanCompileOption):
    _option_name = "preserve-line-info"
    _cli_flag = "generate-line-info"


@register_option
class KeepCUBIN(BooleanBasedFileDumpOption):
    _option_name = "dump-cubin-path"
    _cli_flag = "keep-cubin"

    def __init__(self, val: bool = True) -> None:
        super().__init__(val)
        self.full_cubin_path: str = ""


@register_option
class KeepPTX(BooleanBasedFileDumpOption):
    _option_name = "dump-ptx-path"
    _cli_flag = "keep-ptx"

    def __init__(self, val: bool = True) -> None:
        super().__init__(val)
        self.full_ptx_path: str = ""


@register_option
class KeepSASS(BooleanBasedFileDumpOption):
    _cli_flag = "keep-sass"

@register_option
class NvdisasmOptions(StringCompileOption):
    _cli_flag = "nvdisasm-options"
    _default = "-g -c"
    _reconstruct_on_assign = True
    def __init__(self, val: str = "-g -c") -> None:
        super().__init__(val)



@register_option
class GPUArch(StringCompileOption):
    _option_name = "cubin-chip"
    _cli_flag = "gpu-arch"

    def __init__(self, val: str) -> None:
        if val == "":
            super().__init__(val)
        else:
            # Avoid circular dependency
            from . import Arch

            super().__init__(Arch.from_string(val).to_string())

    @property
    def value(self) -> str:
        return self._value

    @value.setter
    def value(self, value: str) -> None:
        if value == "":
            self._value = value
        else:
            # Avoid circular dependency
            from . import Arch

            self._value = Arch.from_string(value).to_string()


@register_option
class FlattenLocsOutputJsonPath(StringCompileOption):
    """Path to the FlattenLocs JSON sidecar (vloc id -> original source chain).

    When set, the `flatten-locs` pass runs and writes the sidecar. Empty (the
    default) makes the pass a no-op — the original loc chain passes through
    to the LLVM backend unchanged.
    """

    _option_name = "flatten-locs-output-json-path"


@register_option
class LinkLibraries(StringCompileOption):
    _option_name = "link-libraries"


@register_option
class EnableTVMFFI(BooleanCompileOption):
    _cli_flag = "enable-tvm-ffi"


@register_option
class DeviceTarget(BooleanCompileOption):
    """Compile a ``@cute.jit`` function as a ``device`` function.

    By default ``cute.compile`` compiles host and gpu kernel.
    Usage::

        cute.compile[DeviceTarget](my_func, Float32, Float32)
    """



@register_option
class DumpDir(StringCompileOption):
    _cli_flag = "dump-dir"


@register_option
class HostTarget(StringCompileOption):
    """Target spec for AOT host cross-compile.

    Empty value (default) targets the build host via the native
    auto-detect path. A non-empty value cross-compiles the AOT host
    object for the requested target; cross-compile is currently
    exercised for AArch64 only, and other ISAs hit a "target not
    registered" error at codegen time.

    Accepts either a registered preset tag or a TVM-style long form
    (consumed by the AOT export path; not part of the MLIR pipeline
    string).

    Presets::

        linux-aarch64   → aarch64-unknown-linux-gnu
        qnx8-aarch64    → aarch64-unknown-nto-qnx8.0.0

    LLVM has no QNX target, so the QNX triple resolves to an unknown OS
    and generic AArch64 ELF codegen: the emitted object is byte-identical
    to the ``linux-aarch64`` one, and QNX uses the same AAPCS64 ABI. The
    distinct triple exists so the AOT runtime library lookup
    (``aot_config --target``) can tell the two targets apart.

    Long form (explicit tuning / escape hatch)::

        llvm -mtriple=<triple> [-mcpu=<cpu>] [-mattr=<features>]

    Examples::

        cute.compile(fn, *args,
                     options="--gpu-arch sm_100a --host-target linux-aarch64")
        cute.compile(fn, *args,
                     options=(
                         "--gpu-arch sm_100a "
                         "--host-target 'llvm -mtriple=aarch64-unknown-linux-gnu "
                         "-mcpu=neoverse-n1 -mattr=+lse'"
                     ))
    """

    _cli_flag = "host-target"

    _PRESETS: "dict[str, tuple[str, str, str]]" = {
        "linux-aarch64": ("aarch64-unknown-linux-gnu", "", ""),
        "qnx8-aarch64": ("aarch64-unknown-nto-qnx8.0.0", "", ""),
    }

    def __init__(self, val: str = "") -> None:
        # Parse + validate eagerly so bad input fails at cute.compile()
        # parse time rather than later at AOT export time. The parsed
        # triple/cpu/features are cached and exposed as attributes; the
        # raw spec is the option's ``value``.
        self._parse_and_cache(val)
        super().__init__(val)

    @staticmethod
    def _parse_target(spec: str) -> "tuple[str, str, str]":
        """Parse a ``--host-target`` value into ``(triple, cpu, features)``.

        Accepts:
          * Empty string → all empty (native build-host behavior).
          * Preset tag in ``HostTarget._PRESETS``.
          * TVM-style long form ``llvm -mtriple=<t> [-mcpu=<c>] [-mattr=<f>]``.
        """
        spec = (spec or "").strip()
        if not spec:
            return "", "", ""
        if spec.startswith("llvm"):
            tokens = _split_options(spec)
            if not tokens or tokens[0] != "llvm":
                raise ValueError(f"invalid host-target long form: {spec!r}")
            triple, cpu, features = "", "", ""
            for tok in tokens[1:]:
                if tok.startswith("-mtriple="):
                    triple = tok[len("-mtriple=") :]
                elif tok.startswith("-mcpu="):
                    cpu = tok[len("-mcpu=") :]
                elif tok.startswith("-mattr="):
                    features = tok[len("-mattr=") :]
                else:
                    raise ValueError(
                        f"unknown host-target flag {tok!r}; "
                        "supported: -mtriple=, -mcpu=, -mattr="
                    )
            if not triple:
                raise ValueError(
                    f"host-target long form requires -mtriple=<triple>; got: {spec!r}"
                )
            return triple, cpu, features
        if spec in HostTarget._PRESETS:
            return HostTarget._PRESETS[spec]
        raise ValueError(
            f"--host-target {spec!r}: not a known preset and does not start "
            f"with 'llvm '. Known presets: {sorted(HostTarget._PRESETS)}. "
            f"Long form: 'llvm -mtriple=<triple> [-mcpu=<cpu>] [-mattr=<features>]'."
        )

    def _parse_and_cache(self, val: str) -> None:
        try:
            self._triple, self._cpu, self._features = HostTarget._parse_target(val)
        except ValueError as exc:
            raise DSLUserCodeError(
                _diagnostics.DiagId.CONFIG_INVALID_HOST_TARGET, error=str(exc)
            ) from exc

    @property
    def value(self) -> str:
        return self._value

    @value.setter
    def value(self, new_value: str) -> None:
        self._parse_and_cache(new_value)
        self._value = new_value

    @property
    def triple(self) -> str:
        """LLVM target triple. Empty = native build host."""
        return self._triple

    @property
    def cpu(self) -> str:
        """LLVM CPU name. Empty = generic baseline for the triple."""
        return self._cpu

    @property
    def features(self) -> str:
        """Comma-separated LLVM feature list."""
        return self._features


@register_option
class RemarkFilter(StringCompileOption):
    """Regex filter for remark categories e.g. 'Memory|Algorithm' or '.*' for all.
    This option is not serialized into the pipeline string; it configures
    the MLIR context remark engine directly."""

    _cli_flag = "remark-filter"


@register_option
class WarningsFilter(StringCompileOption):
    """Checker domains whose warnings the DSL displays, for example ``nvvm``.

    Set by the user-facing ``warnings{<cat>}`` compile option. Errors are
    always shown; warnings are shown only for domains listed here. Not
    serialized into the pipeline string; consumed by the Python diagnostic
    renderer to gate warning visibility."""


@register_option
class RemarkOutput(StringCompileOption):
    """Output file path for YAML remark format.
    This option is not serialized into the pipeline string; it configures
    the MLIR context remark engine directly."""

    _cli_flag = "remark-output"


@register_option
class CollectCompilerDiagnostics(BooleanCompileOption):
    """Track whether the C++ diagnostic-collection passes are enabled; set by
    the compact diagnostic handlers, never itself serialized."""


# remarks{<selector>} to remark-category mapping. The values must equal the
# emit-time category names — the stringifyCategoryID() descriptions from the
# compiler's Remarks.td — verbatim: the MLIR remark engine anchors the filter
# regex to the whole string (`^(...)$`), so anything else never matches and
# every remark is dropped at emission. test_compile_options.py cross-checks
# these values against Remarks.td.
_DOMAIN_TO_REMARK_CATEGORY: dict[str, str] = {
    "nvvm": "Kernel synchronization protocol",
    "ptx": "ptxas info",
    "loop": "Loop optimization",
    "ts": "Task scheduling audit",
}



class CompileOptions:
    """
    This class encapsulates compilation options to configure the JIT compilation.
    It provides a convenient way to manage and pass compilation options.
    By centralizing these options, it ensures consistent and flexible configuration of
    compilation parameters such as optimization level, debugging control, etc.
    """

    def __init__(
        self,
        options: "CompileOption | tuple[CompileOption, ...] | None" = None,
    ) -> None:
        self.options: dict[type[CompileOption], CompileOption] = {
            cls: cls(cls._default) for cls in _OPTION_REGISTRY
        }
        self._ptxas_diagnostics_enabled = False
        self._debug_selectors: set[str] = set()
        # Raw pass-option bodies keyed by logical compiler stage. The DSL
        # recognizes only the outer ``stage{...}`` envelope; the compiler is
        # the source of truth for every name, type, value, and default inside.
        self._pipeline_options: dict[str, str] = {}
        # ``apply_envar_settings`` may run twice for one compilation after
        # device instantiation enables artifact dumps. Avoid appending the
        # same opaque environment-provided stage bodies a second time.
        self._applied_envar_compiler_opt: str | None = None
        # Set from CUTE_DSL_WARNINGS_AS_ERRORS via apply_envar_settings.
        self._warnings_as_errors = False

        if options is not None:
            self._update(options)

    def _update(
        self,
        options: "CompileOption | tuple[CompileOption, ...]",
    ) -> None:
        def _validate_and_update_option(option: CompileOption) -> None:
            if type(option) not in self.options:
                raise DSLUserCodeError(
                    _diagnostics.DiagId.CONFIG_UNKNOWN_COMPILE_OPTION, option=option
                )
            self.options[type(option)] = option

        if isinstance(options, tuple):
            for option in options:
                _validate_and_update_option(option)
        else:
            _validate_and_update_option(options)

    def _add_pipeline_options(self, pipeline: str, options: str) -> None:
        """Append one opaque pass-option body to a logical compiler stage."""
        if not options.strip():
            raise ValueError(
                f"Empty braces for pipeline '{pipeline}'; provide pass options"
            )
        existing = self._pipeline_options.get(pipeline, "")
        separator = (
            ""
            if not existing or existing[-1].isspace() or options[0].isspace()
            else " "
        )
        self._pipeline_options[pipeline] = existing + separator + options

    @property
    def has_pipeline_options(self) -> bool:
        """Return whether any explicitly scoped options were requested."""
        return any(self._pipeline_options.values())

    @property
    def configured_pipelines(self) -> frozenset[str]:
        """Return the logical pipelines with explicit user options."""
        return frozenset(
            pipeline for pipeline, options in self._pipeline_options.items() if options
        )

    def merge_pipeline_options(self, pipeline: str, base_options: str) -> str:
        """Overlay scoped options on a pipeline's existing option string.

        MLIR pass options use last-value-wins semantics, so explicitly scoped
        values are appended after the legacy options for their stage. Avoid
        reparsing the legacy text here: string-valued ``CompileOption`` objects
        use MLIR's historical quoting syntax, whose contents cannot be safely
        reconstructed by a separate tokenizer. With no scoped values the
        original string is returned verbatim, preserving legacy pipeline text.
        """
        scoped = self._pipeline_options.get(pipeline, "")
        if not scoped:
            return base_options
        separator = "" if not base_options or base_options[-1].isspace() else " "
        return base_options + separator + scoped

    def pipeline_options_cache_key(self) -> str:
        """Return a stable representation of explicitly scoped options."""
        sections = []
        for pipeline in sorted(self._pipeline_options):
            options = self._pipeline_options[pipeline]
            if options:
                sections.append(f"{pipeline}{{{options}}}")
        return ",".join(sections)

    def _parse_debug_token(
        self, name: str, sub_str: "str | None", val_str: "str | None"
    ) -> None:
        """Handle the ``debug{...}`` compact token."""
        if val_str is not None or sub_str is None:
                raise ValueError(
                    "debug expects selector braces, e.g. debug{launch-check}"
                )
        valid_selectors = {"launch-check"}
        selectors = {item.strip() for item in sub_str.split(",") if item.strip()}
        unknown = selectors - valid_selectors
        if unknown:
            valid_list = ", ".join(sorted(valid_selectors))
            unknown_list = ", ".join(sorted(unknown))
            raise ValueError(
                f"debug supports selectors {{{valid_list}}}; "
                f"unknown selector(s): {unknown_list}"
            )
        self._debug_selectors.update(selectors)
    def _parse_diagnostic_token(
        self,
        name: str,
        sub_str: "str | None",
        val_str: "str | None",
        raw_opts: "list[str]",
    ) -> None:
        """Handle the ``warnings{...}`` / ``remarks{...}`` compact tokens."""
        if val_str is not None:
            raise ValueError(f"{name} expects selector braces, e.g. {name}{{nvvm}}")
        valid_selectors = {
            "nvvm",
            "ptx",
            # Task Scheduling audit findings. Like `loop` it has no checker
            # pass to enable (the ts audit passes always run when the kernel
            # carries ts declarations), so it is never forwarded below; it
            # only selects which severities the DSL displays.
            "ts",
        }
        if name == "remarks":
            # `loop` has no checker pass — it only selects remark categories —
            # so it is a remarks{}-only selector.
            valid_selectors.add("loop")
        selectors = (
            set(valid_selectors)
            if sub_str is None
            else {item.strip() for item in sub_str.split(",") if item.strip()}
        )
        unknown = selectors - valid_selectors
        if unknown:
            valid_list = ", ".join(sorted(valid_selectors))
            unknown_list = ", ".join(sorted(unknown))
            raise ValueError(
                f"{name} supports selectors {{{valid_list}}}; "
                f"unknown selector(s): {unknown_list}"
            )
        # warnings{} / remarks{} enable the C++ collection passes via
        # the pipeline's `diagnostic=` selector. Errors are always-on
        # regardless; these flags only control which severity the DSL
        # displays (warnings vs remarks). `loop` is not forwarded: it has
        # no checker pass to enable.
        checker_selectors = selectors & {"nvvm", "ptx"}
        if checker_selectors:
            self._append_diagnostic_selectors(raw_opts, checker_selectors)
        self.options[CollectCompilerDiagnostics].value = True
        self._ptxas_diagnostics_enabled = (
            self._ptxas_diagnostics_enabled or "ptx" in selectors
        )
        if name == "warnings":
            wf = self.options[WarningsFilter]
            have = {d for d in wf.value.split(",") if d}
            wf.value = ",".join(sorted(have | selectors))
        else:  # remarks
            new_cats = {_DOMAIN_TO_REMARK_CATEGORY[s] for s in selectors}
            rf = self.options[RemarkFilter]
            have = {c for c in rf.value.split("|") if c}
            rf.value = "|".join(sorted(have | new_cats))

    @staticmethod
    def _append_diagnostic_selectors(
        raw_opts: "list[str]", selectors: "set[str]"
    ) -> None:
        """Merge diagnostic selectors into the current compact-option batch."""
        for index, raw_option in enumerate(raw_opts):
            if not raw_option.startswith("diagnostic="):
                continue
            existing = {
                selector
                for selector in raw_option.removeprefix("diagnostic=").split(",")
                if selector
            }
            raw_opts[index] = f"diagnostic={','.join(sorted(existing | selectors))}"
            return
        raw_opts.append(f"diagnostic={','.join(sorted(selectors))}")

    def _parse_nvvm_diag_token(
        self,
        name: str,
        sub_str: "str | None",
        val_str: "str | None",
        raw_opts: "list[str]",
    ) -> None:
        """Handle ``nvvm-diag`` and its CFG-dump sub-options."""
        if val_str is not None:
            raise ValueError(
                "nvvm-diag does not take '=value'; use nvvm-diag or "
                "nvvm-diag{dump-cfg=kernel.json}"
            )

        if sub_str is None:
            self._append_diagnostic_selectors(raw_opts, {"nvvm"})
            self.options[CollectCompilerDiagnostics].value = True
            return

        valid_keys = {"dump-cfg", "dump-cfg-function"}
        values: dict[str, str] = {}
        for item in sub_str.split(","):
            key, separator, value = item.partition("=")
            key = key.strip()
            value = value.strip()
            if not key:
                raise ValueError("nvvm-diag contains an empty option")
            if key not in valid_keys:
                valid_list = ", ".join(sorted(valid_keys))
                raise ValueError(
                    f"nvvm-diag supports options {{{valid_list}}}; "
                    f"unknown option: {key}"
                )
            if key in values:
                raise ValueError(
                    f"nvvm-diag option '{key}' is specified more than once"
                )
            if not separator or not value:
                raise ValueError(
                    f"nvvm-diag option '{key}' requires a value, e.g. {key}=<value>"
                )
            values[key] = value

        if "dump-cfg" not in values:
            raise ValueError("nvvm-diag requires dump-cfg=<path>")

        for key, value in values.items():
            if any(character.isspace() for character in value):
                raise ValueError(
                    f"nvvm-diag option '{key}' does not support whitespace in its value"
                )

        dump_path = values["dump-cfg"]
        if dump_path != "-" and not dump_path.lower().endswith(".json"):
            raise ValueError(
                "nvvm-diag option 'dump-cfg' must end in .json; DOT is an "
                "offline rendering format"
            )

        existing_raw = self.options[ExtraCompilerOpts].value
        values_to_append: dict[str, str] = {}
        for key, value in values.items():
            pipeline_key = f"nvvm-diag-{key}="
            prior_values = [
                option.removeprefix(pipeline_key)
                for option in raw_opts
                if option.startswith(pipeline_key)
            ]
            prior_values.extend(
                re.findall(rf"(?:^|\s){re.escape(pipeline_key)}([^\s]+)", existing_raw)
            )
            if any(prior_value != value for prior_value in prior_values):
                raise ValueError(
                    f"nvvm-diag option '{key}' is specified more than once "
                    "with conflicting values"
                )
            if not prior_values:
                values_to_append[key] = value

        if "dump-cfg" in values_to_append:
            raw_opts.append(f"nvvm-diag-dump-cfg={values_to_append['dump-cfg']}")
        if function_name := values_to_append.get("dump-cfg-function"):
            raw_opts.append(f"nvvm-diag-dump-cfg-function={function_name}")

        # Install the diagnostic handler because nvvm-diag still reports fatal
        # correctness errors while producing the graph. Warning and remark
        # visibility remains controlled independently by warnings{}/remarks{}.
        self.options[CollectCompilerDiagnostics].value = True

    def _parse_named_option_token(
        self,
        name: str,
        val_str: "str | None",
        opt_name_map: dict,
        raw_opts: "list[str]",
    ) -> None:
        """Handle the ``name`` / ``name=val`` form: enable/configure a named option."""
        key = name
        val = val_str or ""
        if key in opt_name_map:
            opt = self.options[opt_name_map[key]]
            if isinstance(opt, BooleanCompileOption):
                opt.value = (
                    True if not val else val.lower() in ("1", "true", "yes", "on")
                )
            else:
                if not val:
                    raise DSLUserCodeError(
                        _diagnostics.DiagId.CONFIG_OPTION_REQUIRES_VALUE,
                        key=key,
                    )
                opt.value = val
        else:
            raw_opts.append(f"{key}={'true' if not val else val}")

    def _apply_opt_string(self, opt_str: str) -> None:
        """Apply a compact compiler option string in-place.

        Parses the same format as ``CUTE_DSL_COMPILER_OPT`` and updates this
        object's options accordingly.  Valid forms (comma- or space-separated,
        ``--`` prefix optional)::

            # Errors are always shown and fail compilation -- no flag needed.
            # warnings / remarks are opt-in and non-fatal; a {<cat>}
            # selector shows only that category, bare shows all categories.
            warnings                         # show all warnings
            warnings{nvvm}                   # show only nvvm-category warnings
            remarks                          # show all remarks
            remarks{nvvm}                    # show only nvvm (sync) remarks
            remarks{ptx}                     # show only ptxas remarks (local mem)
            warnings{ptx}                    # show ptxas warnings (register spills)
            warnings{ts}                     # show Task Scheduling audit warnings
            remarks{ts}                      # show Task Scheduling audit remarks
            debug{launch-check}              # check CUDA launch arguments
            nvvm-diag                        # run NVVM correctness diagnostics
            nvvm-diag{dump-cfg=kernel.json}  # diagnose and dump the CFG
            fast-divmod                      # enable fast-divmod pass
            grid-invariant-code-motion       # enable grid-invariant code motion
            iket                             # enable IKET (In-Kernel Event Tracing) instrumentation

        :param opt_str: Compact option string to parse.
        :raises ValueError: On malformed syntax:

            - **Unclosed brace** — a ``{`` immediately after a token that was
              not captured by the regex (e.g. ``name{``).
            - **Empty braces** — ``name{}`` is rejected unless the token takes
              sub-options (then it just enables the token's flag).
            - **Stray braces** — ``name{...}`` on a token that takes no
              sub-options.
            - **Empty value** — ``name=`` (equals with no value) is rejected;
              use the bare name to enable boolean options.
        """
        import re

        pipeline_options, opt_str = _extract_pipeline_option_groups(opt_str)
        for pipeline, options in pipeline_options:
            self._add_pipeline_options(pipeline, options)

        opt_name_map = {
            cls._option_name or cls._cli_flag: cls
            for cls in self.options
            if cls._option_name or cls._cli_flag
        }
        raw_opts: list[str] = []

        # Tokenize: each token is  name  or  name{sub-opts}  or  name=val
        for m in re.finditer(r"([\w][\w-]*)(?:\{([^}]*)\}|=([\S]+))?", opt_str):
            name = m.group(1)
            sub_str = m.group(2)  # braces content, or None
            val_str = m.group(3)  # =val content, or None

            # --- Malformed-syntax checks ---
            # (1) Unclosed brace: the regex skips a lone '{' that has no '}'.
            if m.end() < len(opt_str) and opt_str[m.end()] == "{":
                raise ValueError(
                    f"Unclosed '{{' after option '{name}'; "
                    f"braces must be closed (e.g. {name}{{...}})"
                )
            # (2) Empty braces: name{} is ambiguous — reject unless the token
            #     takes sub-options (an empty list then just enables it).
            if sub_str == "" and not ExtraCompilerOpts.takes_sub_options(name):
                raise ValueError(
                    f"Empty braces for option '{name}'; "
                    f"provide sub-options (e.g. {name}{{key=val}}) "
                    f"or remove the braces"
                )
            # (3) Empty value: name= (equals with no RHS). The regex requires
            #     at least one \S after '=', so 'name=' leaves '=' uncaptured.
            if (
                val_str is None
                and sub_str is None
                and m.end() < len(opt_str)
                and opt_str[m.end()] == "="
            ):
                raise ValueError(
                    f"Empty value for option '{name}='; "
                    f"provide a value (e.g. {name}=<value>) "
                    f"or use the bare name to enable a boolean option"
                )

            if name == "debug":
                self._parse_debug_token(name, sub_str, val_str)
            elif name in ("warnings", "remarks"):
                self._parse_diagnostic_token(name, sub_str, val_str, raw_opts)
            elif name == "nvvm-diag":
                self._parse_nvvm_diag_token(name, sub_str, val_str, raw_opts)
            elif name in ExtraCompilerOpts.COMPACT_FLAGS:
                raw_opts.extend(ExtraCompilerOpts.expand(name, sub_str))
            elif sub_str is not None:
                raise ValueError(f"option '{name}' does not take {{...}} sub-options")
            else:
                self._parse_named_option_token(name, val_str, opt_name_map, raw_opts)

        if raw_opts:
            existing = self.options[ExtraCompilerOpts].value
            non_diagnostic_options: list[str] = []
            for raw_option in raw_opts:
                if not raw_option.startswith("diagnostic="):
                    non_diagnostic_options.append(raw_option)
                    continue
                for selector in raw_option.removeprefix("diagnostic=").split(","):
                    if selector:
                        existing = _ensure_compiler_diagnostic_selector(
                            existing, selector
                        )
            combined = (existing + " " + " ".join(non_diagnostic_options)).strip()
            self.options[ExtraCompilerOpts].value = combined

    @staticmethod
    def _set_artifact_dump_paths(
        option: Any,
        dump_dir: str,
        function_name: str,
        arch: Any,
        ext: str,
        full_attr: str,
    ) -> None:
        """Set an artifact option's ``dump_path`` and its ``full_<ext>_path``.

        ``dump_path`` is ``<dump_dir>/<function_name>`` and the full path is
        ``<dump_dir>/<function_name>.<arch>.<ext>``. Shared by the PTX/CUBIN dump
        blocks (identical shape, differing only in extension / attribute name).
        """
        option.dump_path = os.path.join(dump_dir, f"{function_name}")
        setattr(
            option,
            full_attr,
            os.path.join(dump_dir, f"{function_name}.{arch}.{ext}"),
        )

    def apply_envar_settings(
        self, envar: EnvironmentVarManager, function_name: str
    ) -> None:
        # Honor the settings from environment variables as well
        if envar.keep_ptx:
            self.options[KeepPTX].value = True
        if envar.keep_cubin:
            self.options[KeepCUBIN].value = True
        if envar.keep_sass:
            self.options[KeepSASS].value = True
        if envar.enable_pyir:
            self.options[EnablePYIR].value = True
        if (
            envar.compiler_opt
            and envar.compiler_opt != self._applied_envar_compiler_opt
        ):
            self._apply_opt_string(envar.compiler_opt)
            self._applied_envar_compiler_opt = envar.compiler_opt
        if envar.debug and "diagnostic=" not in self.options[ExtraCompilerOpts].value:
            self._apply_opt_string("warnings{nvvm}")
        if envar.enable_assertions:
            self.options[EnableAssertions].value = True
        if envar.lineinfo:
            self.options[GenerateLineInfo].value = True
        if envar.enable_tvm_ffi:
            self.options[EnableTVMFFI].value = True

        # Update the dump path if the option is set
        arch = (
            envar.arch
            if self.options[GPUArch].value == ""
            else self.options[GPUArch].value
        )
        dump_dir = (
            envar.dump_dir
            if self.options[DumpDir].value == ""
            else self.options[DumpDir].value
        )
        keep_ptx = self.options[KeepPTX]
        keep_cubin = self.options[KeepCUBIN]
        assert isinstance(keep_ptx, KeepPTX)
        assert isinstance(keep_cubin, KeepCUBIN)
        if keep_ptx.value:
            assert dump_dir is not None
            self._set_artifact_dump_paths(
                keep_ptx, dump_dir, function_name, arch, "ptx", "full_ptx_path"
            )
        if keep_cubin.value:
            assert dump_dir is not None
            self._set_artifact_dump_paths(
                keep_cubin, dump_dir, function_name, arch, "cubin", "full_cubin_path"
            )
        keep_sass = self.options[KeepSASS]
        assert isinstance(keep_sass, KeepSASS)
        if keep_sass.value:
            assert dump_dir is not None
            keep_sass.dump_path = os.path.join(
                dump_dir,
                f"{function_name}.sass",
            )
            _need_cubin_on_disk = True
            if _need_cubin_on_disk and not keep_cubin.value:
                keep_cubin.value = True
                self._set_artifact_dump_paths(
                    keep_cubin,
                    dump_dir,
                    function_name,
                    arch,
                    "cubin",
                    "full_cubin_path",
                )
        raw_filter = self.options[RemarkFilter].value
        matches_ptxas = False
        if raw_filter:
            try:
                compiled_filter = re.compile(raw_filter)
            except re.error as exc:
                raise DSLUserCodeError(
                    _diagnostics.DiagId.CONFIG_MALFORMED_COMPILE_OPTIONS,
                    options=f"remark-filter={raw_filter}",
                ) from exc
            # Probe both spellings: the legacy literal "ptxas" and the
            # emit-time category name "ptxas info" both mean the user wants
            # ptxas diagnostics captured.
            matches_ptxas = (
                compiled_filter.search("ptxas") is not None
                or compiled_filter.search("ptxas info") is not None
            )
        if matches_ptxas:
            self.options[CollectCompilerDiagnostics].value = True
            self._ptxas_diagnostics_enabled = True
        # Fail closed on ptxas register spills. Auto-enable warnings{ptx} so a
        # generator cannot skip the check by omitting warnings{ptx}/remarks{ptx}.
        self._warnings_as_errors = bool(envar.warnings_as_errors)
        if self._warnings_as_errors:
            self._apply_opt_string("warnings{ptx}")

    @property
    def generate_line_info(self) -> bool:
        return self.options[GenerateLineInfo].value

    @property
    def divmod_semantics(self) -> str:
        return self.options[DivmodSemantics].value

    @property
    def gpu_arch(self) -> str:
        return self.options[GPUArch].value

    @property
    def host_target(self) -> "HostTarget":
        """Host-target option object.

        ``.value`` is the raw user-facing spec (preset tag or ``llvm …``
        long form, empty = native build host). ``.triple`` / ``.cpu`` /
        ``.features`` are the parsed components.
        """
        return self.options[HostTarget]  # type: ignore[return-value]

    @property
    def dump_ptx_path(self) -> str | None:
        keep_ptx = self.options[KeepPTX]
        assert isinstance(keep_ptx, KeepPTX)
        return keep_ptx.dump_path if keep_ptx.value else None

    @property
    def full_ptx_path(self) -> str | None:
        keep_ptx = self.options[KeepPTX]
        assert isinstance(keep_ptx, KeepPTX)
        return keep_ptx.full_ptx_path if keep_ptx.value else None

    @property
    def dump_cubin_path(self) -> str | None:
        keep_cubin = self.options[KeepCUBIN]
        assert isinstance(keep_cubin, KeepCUBIN)
        return keep_cubin.dump_path if keep_cubin.value else None

    @property
    def full_cubin_path(self) -> str | None:
        keep_cubin = self.options[KeepCUBIN]
        assert isinstance(keep_cubin, KeepCUBIN)
        return keep_cubin.full_cubin_path if keep_cubin.value else None

    @property
    def dump_sass_path(self) -> str | None:
        keep_sass = self.options[KeepSASS]
        assert isinstance(keep_sass, KeepSASS)
        return keep_sass.dump_path if keep_sass.value else None

    @property
    def remark_filter(self) -> str:
        print_remark_all = ".*"
        return self.options[RemarkFilter].value or print_remark_all

    @property
    def warnings_filter(self) -> str:
        """Comma-separated checker domains whose warnings the DSL shows
        (set by warnings{<cat>}). Empty means no warnings are displayed."""
        return self.options[WarningsFilter].value or ""

    @property
    def remark_output(self) -> str:
        return self.options[RemarkOutput].value or ""

    @property
    def remarks_enabled(self) -> bool:
        return self.remark_output != ""

    @property
    def collect_compiler_diagnostics(self) -> bool:
        # Collection (and the nvvm checker) is enabled by warnings{} /
        # remarks{}. When set, the checker runs and renders its diagnostics;
        # errors among them are always fatal + shown (no separate error flag).
        return bool(self.options[CollectCompilerDiagnostics].value)

    @property
    def warnings_as_errors(self) -> bool:
        """True when CUTE_DSL_WARNINGS_AS_ERRORS should fail on ptxas spills."""
        return self._warnings_as_errors

    @property
    def debug_launch_check(self) -> bool:
        return "launch-check" in self._debug_selectors

    @property
    def enable_tvm_ffi(self) -> bool:
        ret = self.options[EnableTVMFFI].value
        if ret and importlib.util.find_spec("tvm_ffi") is None:
            raise DSLUserCodeError(_diagnostics.DiagId.CONFIG_MISSING_TVM_FFI)
        return ret

    def to_str(self) -> str:
        """
        Generate a string representation of all compilation options
        which will be used in pipeline options.
        """
        self._finalize_derived_options()
        flattened_options = ""
        for option in self.options.values():
            flattened_options += option.serialize() + " "

        log().info("`cute.compile` CompileOptions: options=" + flattened_options)
        return flattened_options

    def _finalize_derived_options(self) -> None:
        if self._ptxas_diagnostics_enabled:
            self.options[CollectCompilerDiagnostics].value = True
            extra_options = self.options[ExtraCompilerOpts]
            assert isinstance(extra_options, ExtraCompilerOpts)
            extra_options.value = _ensure_compiler_diagnostic_selector(
                extra_options.value, "ptx"
            )
            ptxas_options = self.options[PtxasOptions]
            assert isinstance(ptxas_options, PtxasOptions)
            ptxas_options.value = _ensure_ptxas_verbose(ptxas_options.value)


@functools.lru_cache(maxsize=None)
def _build_string_api_tables() -> (
    "tuple[Any, dict[str, type[CompileOption]], set[str]]"
):
    """Derive the legacy string-API tables from the option registry.

    Cached: built once on first use, after every option has registered.
    """
    import argparse

    parser = argparse.ArgumentParser()
    dest_to_cls: "dict[str, type[CompileOption]]" = {}
    exact_value_flags: "set[str]" = set()
    long_flags = {"--help"}
    for cls in _OPTION_REGISTRY:
        if cls._cli_flag is None:
            continue
        flag = "--" + cls._cli_flag
        long_flags.add(flag)
        dest_to_cls[cls._cli_flag.replace("-", "_")] = cls
        if cls._value_kind == "bool":
            parser.add_argument(flag, action="store_true", default=argparse.SUPPRESS)
        else:
            kwargs: "dict[str, Any]" = {
                "type": str,
                "default": argparse.SUPPRESS,
            }
            if cls._value_kind == "int":
                kwargs = {
                    "nargs": "?",
                    "type": int,
                    "default": argparse.SUPPRESS,
                }
            parser.add_argument(flag, **kwargs)
            exact_value_flags.add(flag)

    # argparse accepts any unambiguous long-option prefix. The outer stage
    # scanner must recognize the same spellings so an abbreviated legacy flag
    # still consumes a brace-bearing value rather than reclassifying it as a
    # ``stage{...}`` group.
    value_flags = set(exact_value_flags)
    for flag in exact_value_flags:
        for prefix_length in range(3, len(flag)):
            prefix = flag[:prefix_length]
            if prefix in long_flags:
                continue
            if sum(candidate.startswith(prefix) for candidate in long_flags) == 1:
                value_flags.add(prefix)
    return parser, dest_to_cls, value_flags


_COMPACT_OPTION_NAMES: frozenset[str] = frozenset(
    {"warnings", "remarks", "nvvm-diag"}
    | set(ExtraCompilerOpts.COMPACT_FLAGS)
)


def _find_pipeline_group_end(options: str, open_brace: int) -> int:
    """Return the matching brace while treating the group body as opaque.

    Nested MLIR value groups and braces inside quoted strings are both
    supported. MLIR's pass-option parser does not give backslashes escape
    semantics inside quoted values, so neither does this envelope scanner.
    Every input byte is retained in the returned body.
    """
    depth = 1
    quote: str | None = None
    for index in range(open_brace + 1, len(options)):
        char = options[index]
        if quote is not None:
            if char == quote:
                quote = None
            continue
        # Quotes in MLIR pass options delimit a value only when they start at
        # a value boundary. An apostrophe embedded in an opaque bare value
        # (for example ``a=it's``) must not hide the stage's closing brace.
        quote_starts_value = index == open_brace + 1 or (
            options[index - 1].isspace() or options[index - 1] in "=,{"
        )
        if char in "'\"" and quote_starts_value:
            quote = char
        elif char == "{":
            depth += 1
        elif char == "}":
            depth -= 1
            if depth == 0:
                return index
    raise ValueError("Unclosed pipeline option group; braces must be balanced")


def _extract_pipeline_option_groups(options: str) -> tuple[list[tuple[str, str]], str]:
    """Extract opaque ``stage{pass-options}`` groups from an option string.

    Known compact options such as ``warnings{...}`` stay on the legacy parser
    path. Every other grouped token is retained as a generic logical stage and
    validated later by the active DSL. This keeps ``base_dsl`` independent of
    CuTe's ``cute`` and ``cute_ext`` stage names.
    """
    _, _, legacy_value_flags = _build_string_api_tables()
    groups: list[tuple[str, str]] = []
    remaining: list[str] = []
    index = 0
    quote: str | None = None
    escaped_double_quote = False
    brace_depth = 0
    at_token_boundary = True
    while index < len(options):
        char = options[index]
        if quote is not None:
            remaining.append(char)
            if quote == "'":
                if char == quote:
                    quote = None
            elif escaped_double_quote:
                escaped_double_quote = False
            elif char == "\\":
                escaped_double_quote = True
            elif char == quote:
                quote = None
            index += 1
            continue
        if char == "\\" and os.name != "nt":
            # Match POSIX shlex outside quotes: the next character belongs to
            # the current shell token, even when it is whitespace. Windows
            # paths use the platform-specific preservation in ``_split_options``.
            remaining.append(char)
            index += 1
            if index < len(options):
                remaining.append(options[index])
                index += 1
            at_token_boundary = False
            continue
        if char in "'\"":
            quote = char
            remaining.append(char)
            at_token_boundary = False
            index += 1
            continue

        at_token_start = brace_depth == 0 and at_token_boundary
        if at_token_start:
            match = re.match(
                r"(?:--)?(?P<name>[A-Za-z][A-Za-z0-9_-]*)\{", options[index:]
            )
            if match is not None and match.group("name") not in _COMPACT_OPTION_NAMES:
                prefix = options[:index].rstrip()
                previous = prefix.rsplit(None, 1)[-1] if prefix else ""
                # A brace-bearing token can still be the value of a legacy
                # argparse option, for example ``--ptxas-options foo{bar}``.
                if previous not in legacy_value_flags:
                    open_brace = index + match.end() - 1
                    close_brace = _find_pipeline_group_end(options, open_brace)
                    if close_brace + 1 < len(options) and not (
                        options[close_brace + 1].isspace()
                        or options[close_brace + 1] == ","
                    ):
                        raise ValueError(
                            "A pipeline option group must be followed by "
                            "whitespace, a comma, or the end of the string"
                        )
                    pipeline = match.group("name")
                    body = options[open_brace + 1 : close_brace]
                    if not body.strip():
                        raise ValueError(
                            f"Empty braces for pipeline '{pipeline}'; "
                            "provide pass options"
                        )
                    groups.append((pipeline, body))
                    index = close_brace + 1
                    # Commas are valid top-level compact-option separators.
                    # Consume one adjacent comma when removing a stage group,
                    # then leave whitespace so the remaining legacy parser
                    # cannot accidentally concatenate its neighboring tokens.
                    if remaining and remaining[-1] == ",":
                        remaining[-1] = " "
                    if index < len(options) and options[index] == ",":
                        index += 1
                    remaining.append(" ")
                    at_token_boundary = True
                    continue

        remaining.append(char)
        if char == "{":
            brace_depth += 1
        elif char == "}" and brace_depth:
            brace_depth -= 1
        at_token_boundary = brace_depth == 0 and (char.isspace() or char == ",")
        index += 1
    return groups, "".join(remaining)


def _extract_compact_options(
    options: str,
) -> "tuple[CompileOptions | None, str]":
    """Split *options* into compact tokens and legacy tokens.

    Compact tokens such as ``nvvm-diag``, ``warnings``, and ``iket`` are applied
    immediately via ``CompileOptions._apply_opt_string``; the remaining legacy
    tokens are returned as a plain string for argparse.
    Compact optimization tokens (``fast-divmod``,
    ``grid-invariant-code-motion``) are handled the same way.
    Returns:
        (base_compile_options or None, remaining legacy options string).
        When the input is *pure* compact, the fully-configured CompileOptions
        is returned and the legacy string is empty.
    """

    def _is_compact(token: str) -> bool:
        bare = (
            (token[2:] if token.startswith("--") else token).split(",")[0].split("{")[0]
        )
        bare = bare.split("=")[0]
        return bare in _COMPACT_OPTION_NAMES

    stripped = options.strip() if options else ""
    if not stripped:
        return None, options

    pipeline_options, stripped = _extract_pipeline_option_groups(stripped)
    base_compile_options = CompileOptions() if pipeline_options else None
    if base_compile_options is not None:
        for pipeline, body in pipeline_options:
            base_compile_options._add_pipeline_options(pipeline, body)
    if not stripped.strip():
        return base_compile_options, ""

    _, _, value_flags = _build_string_api_tables()
    try:
        all_tokens = _join_compact_option_fragments(
            _split_options(stripped), _COMPACT_OPTION_NAMES, value_flags
        )
    except ValueError as exc:
        raise ValueError(
            f"Failed to parse compiler options string: {exc}\n"
            f"  options string: {stripped!r}\n"
            "  Hint: unmatched quotes or backslashes are common causes."
        ) from exc

    compact_tokens: list[str] = []
    legacy_tokens: list[str] = []
    _prev_is_legacy_key = False
    for t in all_tokens:
        if _prev_is_legacy_key:
            legacy_tokens.append(t)
            _prev_is_legacy_key = False
        elif _is_compact(t):
            compact_tokens.append(t)
        else:
            legacy_tokens.append(t)
            _prev_is_legacy_key = t in value_flags

    if not compact_tokens:
        return base_compile_options, stripped

    compact_str = " ".join(t[2:] if t.startswith("--") else t for t in compact_tokens)
    if not legacy_tokens:
        compile_options = base_compile_options or CompileOptions()
        compile_options._apply_opt_string(compact_str)
        return compile_options, ""

    base = base_compile_options or CompileOptions()
    base._apply_opt_string(compact_str)
    return base, " ".join(shlex.quote(token) for token in legacy_tokens)


# This is a temp function to preserve backward compatibility.
# To be removed in the future.
def _parse_compile_options_from_str(options: str) -> CompileOptions:
    """Parse the compile options from a string."""
    _base_compile_options: "CompileOptions | None" = None
    _base_compile_options, options = _extract_compact_options(options)
    if isinstance(_base_compile_options, CompileOptions) and not options:
        return _base_compile_options

    parser, dest_to_cls, _ = _build_string_api_tables()
    compile_options = (
        _base_compile_options if _base_compile_options is not None else CompileOptions()
    )
    try:
        # Use shlex to properly handle options with spaces
        parsed_options = _split_options(options) if options else []
        # Avoid parsing the ptxas-options value as a hyphen key
        for i in range(1, len(parsed_options)):
            if parsed_options[i - 1] in ["--ptxas-options"]:
                parsed_options[i] = f"'{parsed_options[i]}'"
        option_dict = vars(parser.parse_args(parsed_options))
        for dest, value in option_dict.items():
            option_cls = dest_to_cls[dest]
            if option_cls._reconstruct_on_assign:
                compile_options.options[option_cls] = option_cls(value)
            else:
                compile_options.options[option_cls].value = value
    except SystemExit as e:
        # catch argparse error and raise as DSLRuntimeError
        raise DSLUserCodeError(
            _diagnostics.DiagId.CONFIG_MALFORMED_COMPILE_OPTIONS, options=options
        ) from e

    return compile_options


class CompileCallable:
    """Compile a ``@cute.jit`` callable into an executable host wrapper.

    The public ``cute.compile(...)`` entrypoint is an instance of this
    class. Call it with a ``@cute.jit`` function plus representative
    arguments describing the runtime signature:

    - fake tensors from
      :func:`cutlass.cute.runtime.make_fake_tensor` or
      :func:`cutlass.cute.runtime.make_fake_compact_tensor` for tensor
      arguments
    - plain scalars or :class:`cutlass.cute.typing.SymInt`-typed values
      for scalar parameters
    - :func:`cutlass.cute.runtime.make_fake_stream` when the host wrapper
      takes a stream

    The returned object is callable with real runtime arguments matching
    the fake signature used at compile time.

    Compile-time constants should be baked into the ``@cute.jit``
    function or exposed as default-valued parameters on the user's own
    ``compile()`` wrapper; runtime-varying symbolic quantities should be
    modeled with :class:`cutlass.cute.typing.SymInt` in fake tensor
    shapes / strides or host-function scalar arguments.

    ``cute.compile(..., options="...")`` accepts the same token string as
    ``CUTE_DSL_COMPILER_OPT``. Keep this docstring focused on the compile
    contract; use ``write-kernel/references/compiler-options.md`` as the
    authoritative catalog of option tokens and examples.

    Low-level MLIR pass options can be forwarded to a logical compiler stage
    with a grouped token such as ``cute_ext{example-option=true}`` or
    ``cute{opt-level=1}``. The group body is opaque to the Python DSL.
    Existing ``CompileOption`` objects and ungrouped option strings retain
    their legacy behavior.

    ``cute.compile(..., trace_finalize_hooks=hook_or_hooks)`` temporarily
    registers callbacks for that compile only. Hooks run after tracing and
    before module hashing, and are removed even if compilation fails.

    ``cute.compile(..., extra_link_libs=(path, ...))`` makes additional shared
    libraries available to generated host code without changing the DSL's
    configured library list. LLVM loads these libraries into the process and
    adds them to this execution engine's symbol search order.
    Libraries must be existing filesystem paths, absolute or relative to the
    current working directory. Paths are canonicalized; library names are not
    searched through ``LD_LIBRARY_PATH``.
    """

    def __init__(self, options: Any = None) -> None:
        def preprocess_options(option: Any) -> Any:
            if type(option) is type and issubclass(option, BooleanCompileOption):
                # Automatically creates a True instance of the option
                return option(True)
            elif isinstance(option, tuple):
                return tuple(preprocess_options(opt) for opt in option)
            return option

        self._compile_options = CompileOptions(preprocess_options(options))

    def __getitem__(self, options: Any) -> "CompileCallable":
        """
        Get a new CompileCallable object with the specified options.
        """
        new_callable_with_options = CompileCallable(options)
        return new_callable_with_options

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        """Compile ``func`` for the signature described by ``args``.

        :param args: ``func`` followed by representative compile-time
            arguments. Tensor arguments are typically fake tensors;
            scalar arguments may be Python literals or SymInt-backed
            symbolic values.
        :param kwargs: Optional compile controls such as ``options=...``. See
            ``references/compiler-options.md`` for the legacy option-token
            catalog.
        :return: A compiled callable that accepts real runtime arguments
            matching the supplied signature.
        """
        return self._compile(*args, **kwargs)

    def to_precompiled_mlir(self, func: Any, *args: Any, **kwargs: Any) -> Any:
        """Return a PreCompiledMlirArtifact containing the pre-pass MLIR module."""
        kwargs["compile_to_precompiled_mlir"] = True
        return self._compile(func, *args, **kwargs)

    @with_dsl_lock
    def compile_to(self, target: Any, func: Any, *args: Any, **kwargs: Any) -> Any:
        """Compile a @cute.jit function to the given artifact stage.

        Args:
            target: A concrete stage after tracing: ``PreCompiledMlir``,
                ``CompiledMlir``, ``LlvmIr``, Device ``Ptx``/``LtoIr``, or
                ``Object``.
            target_kind: Optional ``cutlass.compiler.TargetKind`` keyword.
                ``Ptx`` and ``LtoIr`` imply ``Device``. Other stages default
                to ``Device`` when a device target is configured, else
                ``Heterogeneous``. Use ``Device`` to compile a standalone CUDA
                device function through this unified API.
        """
        from .._mlir._mlir_libs import _cutlass_ir as _bindings

        valid_targets = (
            _bindings.ArtifactType.PreCompiledMlir,
            _bindings.ArtifactType.CompiledMlir,
            _bindings.ArtifactType.LlvmIr,
            _bindings.ArtifactType.Ptx,
            _bindings.ArtifactType.LtoIr,
            _bindings.ArtifactType.Object,
        )
        if target not in valid_targets:
            raise ValueError(f"compile_to({target}) is not a concrete artifact stage")

        device_only_targets = (
            _bindings.ArtifactType.Ptx,
            _bindings.ArtifactType.LtoIr,
        )
        target_kind = kwargs.pop("target_kind", None)
        if target_kind is None:
            target_kind = (
                _bindings.TargetKind.Device
                if target in device_only_targets
                or self._compile_options.options[DeviceTarget].value
                else _bindings.TargetKind.Heterogeneous
            )
        if target_kind not in (
            _bindings.TargetKind.Host,
            _bindings.TargetKind.Device,
            _bindings.TargetKind.Heterogeneous,
        ):
            raise ValueError("target_kind must be Host, Device, or Heterogeneous")
        if target in device_only_targets and target_kind != _bindings.TargetKind.Device:
            raise ValueError(
                f"{target.name} compilation requires target_kind=TargetKind.Device"
            )

        kwargs["compile_to_precompiled_mlir"] = True
        artifact, compile_options, compile_gpu_arch = self._compile(
            func,
            *args,
            _return_compile_context=True,
            _compile_device=target_kind == _bindings.TargetKind.Device,
            **kwargs,
        )
        if target == _bindings.ArtifactType.PreCompiledMlir:
            return artifact

        # Tracing resolves environment settings and per-call options before it
        # produces the PreCompiledMlir artifact. Carry the resulting target and
        # backend settings into the staged compiler so compile_to(Object) is
        # equivalent to explicitly walking the same configured pipeline.
        from cutlass.cutlass_dsl.compile_options_adapter import configure_cute_compiler

        compiler = _bindings.CuteCompiler()
        configure_cute_compiler(
            compiler,
            compile_options=compile_options,
            compile_gpu_arch=compile_gpu_arch,
            allow_device_target=artifact.target_kind == _bindings.TargetKind.Device,
        )
        return compiler.compile_to(artifact, target)

    # This dispatch boundary intentionally accepts arbitrary @cute.jit callable
    # signatures and returns the wrapper or artifact selected by its options.
    @with_dsl_lock
    def _compile(
        self,
        func: Any,  # noqa: ANN401
        *args: Any,  # noqa: ANN401
        _return_compile_context: bool = False,
        _compile_device: bool | None = None,
        **kwargs: Any,  # noqa: ANN401
    ) -> Any:  # noqa: ANN401
        """
        Compile a ``@cute.jit`` function and return its executable wrapper.

        ``func`` may be a regular function, bound method, or callable
        instance, but it must ultimately resolve to a ``@cute.jit``
        definition. ``args`` describe the runtime signature seen by the
        compiled wrapper; for tensor arguments, prefer fake tensors over
        ad-hoc real tensors so shape / stride / SymInt constraints remain
        explicit and reproducible.

        :param func: The ``@cute.jit`` callable to compile.
        :param args: Representative compile-time arguments describing the
            callable's runtime signature.
        :param kwargs: Optional compile controls. ``options=...`` accepts
            the same token string as ``CUTE_DSL_COMPILER_OPT``. For the
            legacy option-token catalog, see
            ``write-kernel/references/compiler-options.md``.
        :return: A compiled callable.
        :raises DSLRuntimeError: If ``func`` is not callable or not
            decorated with ``@cute.jit``.
        """
        if func is None:
            raise DSLUserCodeError(_diagnostics.DiagId.CALL_FUNCTION_NOT_PROVIDED)

        if not callable(func):
            raise DSLUserCodeError(_diagnostics.DiagId.CALL_NOT_CALLABLE)

        finalize_hook = kwargs.pop("trace_finalize_hooks", None)

        kwargs["compile_only"] = True
        kwargs["no_cache"] = True

        if inspect.isfunction(func):
            # regular function
            pass
        elif inspect.ismethod(func):
            # if it's a method, add the instance to the first argument
            args = [func.__self__] + list(args)  # type: ignore[assignment]
            func = func.__func__
        elif (
            inspect.isclass(type(func))
            and hasattr(func, "__call__")
            and hasattr(func.__call__, "__func__")
        ):
            # If it's a class instance, get the class's __call__ method
            args = [func] + list(args)  # type: ignore[assignment]
            # Get the actual function from the class definition
            func = func.__call__.__func__
        else:
            raise DSLUserCodeError(_diagnostics.DiagId.CALL_UNSUPPORTED_CALLABLE_TYPE)

        # If it's a wrapped function created by decorators, get the original function
        while hasattr(func, "__wrapped__"):
            func = func.__wrapped__

        from .dsl import BaseDSL

        BaseDSL._lazy_initialize_dsl(func)

        if not hasattr(func, "_dsl_object"):
            raise DSLUserCodeError(_diagnostics.DiagId.CALL_MISSING_JIT_DECORATOR)

        # Reject a @cute.kernel target.
        if getattr(func, "_decorator_kind", "jit") == "kernel":
            raise DSLUserCodeError(
                _diagnostics.DiagId.CALL_KERNEL_TARGET,
                function_name=getattr(func, "__name__", "<kernel>"),
            )

        # process compile options, extract the options and remove them from the kwargs
        options = kwargs.pop("options", None)
        if isinstance(options, str) and len(options) == 0:
            options = None

        if options is not None and isinstance(options, str):
            compile_options = _parse_compile_options_from_str(options)
            # A string ``options=...`` builds a fresh CompileOptions, which would
            # otherwise drop non-pipeline selectors chosen through
            # ``cute.compile[...]``. Re-apply them so they compose with the
            # option string. Other bracket options intentionally keep the
            # existing string-options behavior.
            for selector in (
                FrontendNext,
                EnableCuteExtCompile,
                DisableCuteExtCompile,
            ):
                if self._compile_options.options[selector].value:
                    compile_options.options[selector].value = True
        else:
            # CompileOptions are mutable while tracing. In particular,
            # cute.instantiate[DeviceTarget] forces RDC and artifact options.
            # Keep the CompileCallable's reusable option template isolated
            # from per-invocation mutations.
            compile_options = copy.deepcopy(self._compile_options)

        # compile_to() passes an explicit target choice; ordinary
        # cute.compile() retains the DeviceTarget option behavior.
        compile_device = (
            compile_options.options[DeviceTarget].value
            if _compile_device is None
            else _compile_device
        )

        func._dsl_object.compile_options = compile_options
        # The backend resets the DSL object's compile options during
        # post-compilation cleanup. Resolve the target now so staged lowering
        # does not silently fall back to the environment/default architecture.
        compile_gpu_arch = func._dsl_object.get_arch_enum().to_string()

        if finalize_hook is None:
            hook_context = contextlib.nullcontext()
        else:
            hook_context = func._dsl_object.trace_finalize_hooks(finalize_hook)

        # Frontend selector: default keeps the standard preprocessor.
        staged_frontend_context: Any = contextlib.nullcontext()
        # cute.compile[FrontendNext](...) traces this compile with the PyIR
        # preprocessor (auto-M2S on) so native Python control flow and object
        # mutation lower to scf -- the same toggle the legacy
        # BaseDSL.enable_pyir() context manager applied, scoped to this compile.
        if compile_options.options[FrontendNext].value:
            staged_frontend_context = BaseDSL.enable_pyir()

        with staged_frontend_context, hook_context:
            # Preprocess the function if not already preprocessed
            func._dsl_object._preprocess_and_replace_code(func)

            if compile_device:
                # Standalone Device functions use relocatable-device-code
                # lowering even when staged compilation stops at PTX or LTO IR.
                compile_options.options[RDC].value = True
                if not kwargs.get("compile_to_precompiled_mlir"):
                    # The legacy device flow hands back files, so force the
                    # .o and .ptx dumps. The staged compile_to() path returns
                    # the artifact itself and its backend steps do not apply
                    # dump options.
                    compile_options.options[KeepPTX].value = True
                    compile_options.options[KeepCUBIN].value = True
                result = func._dsl_object._device_func(func, *args, **kwargs)
            else:
                # Default: host wrapper + kernel
                result = func._dsl_object._func(func, *args, **kwargs)

            if _return_compile_context:
                return result, compile_options, compile_gpu_arch
            return result
