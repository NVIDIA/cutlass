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

import inspect
import contextlib
import contextvars
import os
import subprocess
import sys
import types
from typing import Any, Dict, Generator, Optional, Union
from functools import total_ordering
from dataclasses import dataclass

from .diagnostics import (
    Colors,
    find_user_source_location as _find_user_source_location,
    render_user_diagnostic as _render_user_diagnostic,
)

"""
This module provides a Exception classes DSL class for any Dialect.
"""


# Store the original exception hook
_original_excepthook = sys.excepthook

_active_env_manager: contextvars.ContextVar[Any] = contextvars.ContextVar(
    "active_env_manager", default=None
)


def get_current_env_manager() -> Any:
    """Return the env manager for the active DSL context, if any.

    Some shared runtime helpers do not have direct access to a ``BaseDSL``
    instance. Use the active context so those helpers observe the DSL that is
    currently preprocessing/tracing.
    """
    return _active_env_manager.get()


@contextlib.contextmanager
def active_env_manager(env_manager: Any) -> Generator[None, None, None]:
    """Temporarily make ``env_manager`` the current DSL env manager."""
    token = _active_env_manager.set(env_manager)
    try:
        yield
    except Exception as e:
        try:
            if not hasattr(e, "_dsl_env_manager"):
                setattr(e, "_dsl_env_manager", env_manager)
        except (AttributeError, TypeError):
            pass
        raise
    finally:
        _active_env_manager.reset(token)



def _dsl_excepthook(
    exc_type: type,
    exc_value: BaseException,
    exc_traceback: Optional[types.TracebackType],
) -> None:
    """
    Custom exception hook that shows clean error messages for DSL exceptions.
    For DSLOperationError, shows only the formatted message without traceback.
    For other exceptions, uses the default Python traceback.
    """
    # Check if show_stacktrace is enabled via registered env manager
    show_stacktrace = False
    env_manager = getattr(exc_value, "_dsl_env_manager", None)
    if env_manager is None:
        env_manager = get_current_env_manager()
    if env_manager is not None:
        show_stacktrace = getattr(env_manager, "show_stacktrace", False)

    # Check if it's a DSL operation error (by name to avoid circular import issues)
    if exc_type.__name__ in (
        "DSLOperationError",
        "DSLOperationBuildError",
        "DSLUserCodeError",
        "CompilerDiagnosticError",
        "DSLRuntimeError",
    ):
        if show_stacktrace:
            # Show full traceback in verbose mode
            _original_excepthook(exc_type, exc_value, exc_traceback)
        else:
            # Just print the formatted message (which is in __str__)
            print(str(exc_value), file=sys.stderr)
        sys.exit(1)
    else:
        # Use the original exception hook for other exceptions
        _original_excepthook(exc_type, exc_value, exc_traceback)


# Install the custom exception hook
sys.excepthook = _dsl_excepthook


# =============================================================================
# DSL Exceptions
# =============================================================================


class DSLBaseError(Exception):
    """
    Base exception for DSL-related errors.
    Provides optional contextual metadata to aid in debugging.
    """

    def __init__(
        self,
        message: str,
        line: Optional[int] = None,
        snippet: Optional[str] = None,
        filename: Optional[str] = None,
        error_code: Optional[Union[str, int]] = None,
        context: Optional[Union[Dict[str, Any], str]] = None,
        suggestion: Union[str, list[str], tuple[str, ...], None] = None,
        cause: Optional[BaseException] = None,
    ) -> None:
        self.message = message
        self.line = line
        self.filename = filename
        self.snippet = snippet
        self.error_code = error_code
        self.context = context
        self.suggestion = suggestion
        self.cause = cause

        super().__init__(self._format_message())

    def _generate_cause(self) -> str:
        """
        Generates a string representation of the cause of the error, if available.
        """
        if self.cause:
            return f"Caused exception: {self.cause}"
        return ""

    # Subclasses may set this to True to render the "compiler bug, please
    # report" envelope instead of the "here is your mistake" block.  See
    # ``_render_user_diagnostic``.
    _is_internal: bool = False

    def _format_message(self) -> str:
        """Format via the single shared user-diagnostic renderer.

        Every DSL error renders through ``_render_user_diagnostic`` so the
        output looks identical no matter which layer (AST pre-processing,
        tracing, or runtime) raised it -- there is exactly one rendering
        mechanism to change.  Subclasses with genuinely different needs (e.g.
        ``DSLOperationBuildError``, which walks an exception chain) may still
        override this, but the default and recommended path is the shared one.
        """
        return _render_user_diagnostic(self)


class DSLSubprocessCallError(DSLBaseError):
    """
    Raised when an error occurs during a subprocess call in the DSL.
    """

    def _generate_cause(self) -> str:
        assert isinstance(self.cause, subprocess.CalledProcessError), (
            "cause must be a subprocess.CalledProcessError"
        )
        cause = []
        cause.append(f"  Caused exception: {self.cause}")
        cause.append(
            f"    Command: \033[93m{' '.join(str(item) for item in self.cause.cmd)}\033[0m"
        )
        cause.append(f"    Return code: {self.cause.returncode}")
        cause.append(f"    stdout: {self.cause.stdout}")
        cause.append(f"    stderr: {Colors.BOLD}{self.cause.stderr}{Colors.RESET}")
        return "\n".join(cause)


class DSLRuntimeError(DSLBaseError):
    """An internal / compiler error -- NOT the author's fault.

    Rendered as the "compiler bug, please report" envelope (see
    ``_render_user_diagnostic``): a ``DSLRuntimeError`` means the DSL hit a
    "should never happen" / failed-to-build-IR / wrapped-backend situation that
    the kernel author cannot fix.  For mistakes in the author's kernel raise
    ``DSLUserCodeError`` with a ``DiagId`` instead, so the author gets a
    "here is your mistake + how to fix it" message.
    """

    _is_internal = True


_ARCH_RELATED_CUDA_ERRORS = frozenset(
    {
        "CUDA_ERROR_INVALID_SOURCE",
        "CUDA_ERROR_NO_BINARY_FOR_GPU",
        "CUDA_ERROR_INVALID_PTX",
        "CUDA_ERROR_UNSUPPORTED_PTX_VERSION",
        "CUDA_ERROR_NO_DEVICE",
        "CUDA_ERROR_INVALID_DEVICE",
    }
)


def _get_friendly_cuda_error_message(
    error_code: int, error_name: Union[str, bytes]
) -> tuple[str, str, Union[str, tuple[str, ...]]]:
    # Avoid circular dependency
    from .runtime.cuda import get_device_info

    """Get a user-friendly error message for common CUDA errors."""
    # Strip the byte string markers if present
    if isinstance(error_name, bytes):
        error_name = error_name.decode("utf-8")
    elif (
        isinstance(error_name, str)
        and error_name.startswith("b'")
        and error_name.endswith("'")
    ):
        error_name = error_name[2:-1]

    env_manager = get_current_env_manager()
    target_arch = env_manager.arch if env_manager is not None else "unknown"
    arch_is_relevant = error_name in _ARCH_RELATED_CUDA_ERRORS

    additional_info = {
        "CUDA_ERROR_INVALID_SOURCE": (
            f"{Colors.RED}❌ Failed to load CUDA kernel - likely architecture mismatch.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_NO_BINARY_FOR_GPU": (
            f"{Colors.RED}❌ CUDA kernel not compatible with your GPU.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_OUT_OF_MEMORY": (
            f"{Colors.RED}💾 CUDA out of memory error.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_INVALID_DEVICE": (
            f"{Colors.RED}❌ Invalid CUDA device.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_NOT_INITIALIZED": (
            f"{Colors.RED}❌ CUDA context not initialized.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_INVALID_CONTEXT": (
            f"{Colors.RED}❌ CUDA context not initialized.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_INVALID_VALUE": (
            f"{Colors.RED}⚠️ Invalid parameter passed to CUDA operation.{Colors.RESET}\n\n"
            f"{Colors.YELLOW}This is likely a bug - please report it with:{Colors.RESET}"
        ),
        "CUDA_ERROR_ILLEGAL_INSTRUCTION": (
            f"{Colors.RED}❌ A running kernel executed an illegal instruction.{Colors.RESET}\n\n"
            f"{Colors.YELLOW}This is a fault inside the kernel, not an architecture mismatch.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_INVALID_CLUSTER_SIZE": (
            f"{Colors.RED}❌ Invalid cluster size.{Colors.RESET}\n\n"
        ),
    }

    error_suggestions = {
        "CUDA_ERROR_INVALID_CONTEXT": (
            "1. Check if CUDA context is properly initialized under your environment",
            "2. Initialize CUDA context with `cuda.cuInit(0)` or `cutlass.cuda.initialize_cuda_context()`",
        ),
        "CUDA_ERROR_INVALID_SOURCE": (
            "1. Ensure env CUTE_DSL_ARCH matches your GPU architecture",
            "2. Clear the compilation cache and regenerate the kernel",
            "3. Check CUDA toolkit installation",
        ),
        "CUDA_ERROR_NO_BINARY_FOR_GPU": (
            "Set env CUTE_DSL_ARCH to match your GPU architecture",
        ),
        "CUDA_ERROR_ILLEGAL_INSTRUCTION": (
            "1. Inspect the kernel for an in-device fault (out-of-bounds access, "
            "failed device-side assert, or an unsupported instruction at the launch config)",
            "2. Re-run under compute-sanitizer to localize the faulting instruction",
        ),
        "CUDA_ERROR_OUT_OF_MEMORY": (
            "1. Reduce batch size",
            "2. Reduce model size",
            "3. Free unused GPU memory",
        ),
        "CUDA_ERROR_INVALID_DEVICE": (
            "1. Check if CUDA device is properly initialized",
            "2. Verify GPU is detected: nvidia-smi",
            "3. Check CUDA_VISIBLE_DEVICES environment variable",
        ),
        "CUDA_ERROR_NOT_INITIALIZED": (
            "1. Check CUDA driver installation",
            "2. call `cuda.cuInit(0)` before any other CUDA operation",
            "3. Run nvidia-smi to confirm GPU status",
        ),
        "CUDA_ERROR_INVALID_VALUE": (
            "1. Your GPU model",
            "2. SM ARCH setting",
            "3. Steps to reproduce",
        ),
        "cudaErrorInsufficientDriver": (
            "1. Run nvidia-smi to confirm CUDA driver version",
            "2. Ensure the CUDA driver version meets the requirement of the installed cuda-python package",
        ),
    }

    message = (
        f"{error_name} (error code: {error_code}) \n"
        f"{additional_info.get(error_name, '')} \n\n{Colors.RESET}"
    )

    # Add debug information
    debug_info = f"\n- {Colors.BOLD}Error name: {error_name}\n"
    debug_info += f"- Error code: {error_code}\n"
    debug_info += f"- CUDA_TOOLKIT_PATH: {os.getenv('CUDA_TOOLKIT_PATH', 'not set')}\n"
    arch_source = "from env manager" if env_manager is not None else "unspecified"
    debug_info += f"- Target SM ARCH: {target_arch} ({arch_source}){Colors.RESET}\n"

    try:
        # Get GPU information using CUDA Python API
        debug_info += f"\n{Colors.BLUE}📊 GPU Information:{Colors.RESET}\n"
        gpu_info = get_device_info()
        debug_info += gpu_info.pretty_str()

        incompatible = bool(
            target_arch
            and gpu_info.compatible_archs
            and target_arch not in gpu_info.compatible_archs
        )

        if (
            (arch_is_relevant or incompatible)
            and target_arch
            and target_arch != "unknown"
            and gpu_info.compatible_archs
        ):
            debug_info += f"\n{Colors.BOLD}Compatibility Check:{Colors.RESET}\n"

            if incompatible:
                debug_info += (
                    f"{Colors.RED}❌ Error: Target SM ARCH {target_arch} is not compatible\n"
                    f"💡 Please use one of SM ARCHs: "
                    f"{Colors.GREEN}{', '.join(gpu_info.compatible_archs or [])}{Colors.RESET}\n"
                )
            elif target_arch != gpu_info.sm_arch:
                debug_info += (
                    f"{Colors.YELLOW}⚠️  Warning: Using compatible but non-optimal architecture\n"
                    f"• Current: {target_arch}\n"
                    f"• Recommended: {Colors.GREEN}{gpu_info.sm_arch}{Colors.RESET} (native)\n"
                )
            else:
                debug_info += f"{Colors.GREEN}✓ Using optimal architecture: {gpu_info.sm_arch}{Colors.RESET}\n"

    except Exception as e:
        debug_info += (
            f"\n{Colors.YELLOW}ℹ️  Could not retrieve GPU info: {str(e)}{Colors.RESET}"
        )

    return message, debug_info, error_suggestions.get(error_name, "")


class DSLCudaRuntimeError(DSLBaseError):
    """
    Raised when an error occurs during CUDA runtime code generation in the DSL.
    """

    # Inherits all logic from DSLRuntimeError; override methods if you need
    # specialized behavior or formatting for runtime errors.
    def __init__(self, error_code: int, error_name: Union[str, bytes]) -> None:
        self._error_code = error_code
        self._error_name = error_name
        message, debug_info, suggestion = _get_friendly_cuda_error_message(
            error_code, error_name
        )

        super().__init__(
            message, error_code=error_code, context=debug_info, suggestion=suggestion
        )


class DSLWarning(UserWarning):
    """A non-fatal author-facing warning, rendered like a ``DSLUserCodeError``.

    The author's code is not wrong, only at risk (e.g. an implicit promotion
    that can silently bite later), so this renders the shared diagnostic block
    with a yellow ``[Warning]`` header instead of ``[Error]``.  It subclasses
    ``UserWarning`` so it flows through the standard ``warnings`` module
    (filterable, deduplicated); prefer raising it via
    ``diagnostics.report_warning(WarnId.X, ...)``.

    The first positional argument is normally a :class:`WarnId` (the warnings
    catalog -- separate from the :class:`DiagId` error catalog); a free-form
    string is also accepted.
    """

    _severity = "warning"
    _is_internal = False
    error_code = None

    def __init__(
        self,
        warn_or_message: Any,
        filename: Optional[str] = None,
        lineno: Optional[int] = None,
        snippet: Optional[str] = None,
        suggestion: Optional[Union[str, list]] = None,
        context: Optional[Union[Dict[str, Any], str]] = None,
        cause: Optional[BaseException] = None,
        **fields: Any,
    ) -> None:
        from .diagnostics import WarnId  # lazy: avoid an import cycle

        self.warn_id: Optional["WarnId"] = None
        self.code: Optional[str] = None
        if isinstance(warn_or_message, WarnId):
            self.warn_id = warn_or_message
            self.code = warn_or_message.code
            message, catalog_fixes = warn_or_message.fill(**fields)
            if suggestion is None:
                suggestion = list(catalog_fixes)
        else:
            if fields:
                raise TypeError(
                    "DSLWarning received template fields "
                    f"{sorted(fields)} but the first argument is a plain "
                    "string, not a WarnId."
                )
            message = warn_or_message

        self.col: Optional[int] = None
        self.end_col: Optional[int] = None
        if filename is None and lineno is None:
            filename, lineno, self.col, self.end_col = _find_user_source_location()
        self.message = message
        self.filename = filename
        self.line = lineno
        self.suggestion = suggestion
        self.context = context
        self.cause = cause
        self.snippet = snippet
        super().__init__(_render_user_diagnostic(self))

    def _generate_cause(self) -> str:
        return f"Caused exception: {self.cause}" if self.cause else ""


class DSLNotImplemented(DSLBaseError):
    """
    Raised when a feature of the DSL is not implemented yet.
    """

    # Useful for stubs in your DSL that you plan to implement in the future.
    pass


def translate_mlir_nanobind_error(exc: BaseException) -> str:
    """
    Translate nanobind/MLIR exceptions into user-friendly messages.

    Nanobind exceptions from MLIR C++ bindings:
    - nb::value_error -> ValueError
    - nb::type_error -> TypeError
    - nb::cast_error -> RuntimeError (usually)
    - nb::python_error -> Various Python exceptions

    Returns:
        tuple of (translated_message, None, original_message)
        Note: suggestions are None - only show if explicitly provided
    """
    exc_type = type(exc).__name__
    error_msg = str(exc).lower()
    original = str(exc)

    # Type casting errors (nb::cast_error, std::bad_cast)
    if "std::bad_cast" in error_msg or "cast" in exc_type.lower():
        if "must be a type" in error_msg:
            return "Type mismatch: The operation expected a different type than what was provided"

        return "Type casting failed: Cannot convert between incompatible types"

    # Value errors (nb::value_error)
    if exc_type == "ValueError":
        if "verification" in error_msg or "failed to verify" in error_msg:
            return "MLIR operation verification failed: The operation constraints are not satisfied"

        if "result" in error_msg and "operation" in error_msg:
            return "Invalid operation result type: The operation produced an unexpected type"

        if "attribute" in error_msg:
            return "Invalid attribute: Attribute value or type is incorrect"

    # Type errors (nb::type_error)
    if exc_type == "TypeError":
        if "argument" in error_msg or "parameter" in error_msg:
            return "Wrong argument type: Function received an incompatible type"

    # Runtime errors (often from nb::cast_error)
    if exc_type == "RuntimeError":
        if "operand" in error_msg:
            return (
                "Invalid operand: Operation received wrong number or type of operands"
            )

        if "not registered" in error_msg or "unknown" in error_msg:
            return "Operation or dialect not found"

    # Generic fallback
    return f"{exc_type}: {original}"


class DSLUserCodeError(DSLBaseError):
    """Raised when an error is detected in the author's kernel code.

    Covers mutation/phase violations, scope errors, type mismatches,
    unsupported constructs, configuration mistakes, and similar author-facing
    diagnostics.  ``filename``/``lineno`` may be passed explicitly; when they
    are not, the nearest author frame on the call stack is used so the error
    still points at the user's code (see ``_find_user_source_location``).

    The first positional argument is normally a :class:`DiagId` from the error
    catalog; the catalog message and fixes are filled from the keyword
    ``**fields`` and the stable code is appended automatically::

        raise DSLUserCodeError(
            DiagId.TYPE_UNSTABLE_JOIN,
            filename="/path/to/user.py",
            lineno=42,
            var="accum", old_type="Int32", new_type="Float32",
        )

    A free-form string message is still accepted for one-off diagnostics that
    do not yet have a catalog entry::

        raise DSLUserCodeError(
            "Scope Error: variable `a` escapes its scope",
            filename="/path/to/user.py",
            lineno=42,
            suggestion="Define the variable before the loop.",
        )
    """

    def __init__(
        self,
        diag_or_message: Any,
        filename: Optional[str] = None,
        lineno: Optional[int] = None,
        col_offset: Optional[int] = None,
        end_col_offset: Optional[int] = None,
        cause: Optional[BaseException] = None,
        suggestion: Optional[Union[str, list]] = None,
        context: Optional[Union[Dict[str, Any], str]] = None,
        snippet: Optional[str] = None,
        **fields: Any,
    ) -> None:
        from .diagnostics import DiagId  # lazy: avoid an import cycle

        self.diag_id: Optional["DiagId"] = None
        self.code: Optional[str] = None
        if isinstance(diag_or_message, DiagId):
            self.diag_id = diag_or_message
            self.code = diag_or_message.code
            message, catalog_fixes = diag_or_message.fill(**fields)
            if suggestion is None:
                suggestion = list(catalog_fixes)
        else:
            if fields:
                raise TypeError(
                    "DSLUserCodeError received template fields "
                    f"{sorted(fields)} but the first argument is a plain "
                    "string, not a DiagId."
                )
            message = diag_or_message

        self.col = col_offset
        self.end_col = end_col_offset
        if filename is None and lineno is None:
            filename, lineno, self.col, self.end_col = _find_user_source_location()

        super().__init__(
            message,
            line=lineno,
            filename=filename,
            snippet=snippet,
            cause=cause,
            suggestion=suggestion,
            context=context,
        )


class DSLOperationBuildError(DSLBaseError):
    """
    Raised when an error occurs during a DSL operation with formatted source location.
    This exception provides a nicely formatted error message showing the exact line
    of user code that caused the error.
    """

    def __init__(
        self,
        message: str,
        cause: Optional[BaseException] = None,
        frameInfo: Optional[inspect.Traceback] = None,
        auto_translate: bool = True,
    ) -> None:
        """
        Args:
            message: The error message to display
            cause: The underlying exception that caused this error
            frameInfo: Optional frame info from inspect.getframeinfo() - if not provided,
                      automatically captures the caller's frame
            auto_translate: If True, attempt to translate MLIR/nanobind errors
        """
        import inspect

        # If frameInfo not provided, capture the caller's frame information
        if frameInfo is None:
            current_frame = inspect.currentframe()
            frame = current_frame.f_back if current_frame else None
            frameInfo = inspect.getframeinfo(frame) if frame else None

        # Try to translate MLIR/nanobind errors if no custom message provided
        self.original_error = str(message)
        if auto_translate and cause:
            translated_msg = translate_mlir_nanobind_error(cause)
            if translated_msg != str(cause):
                message = translated_msg

        self.frameInfo = frameInfo

        # Extract line and filename from frameInfo
        line = frameInfo.lineno if frameInfo else None
        filename = frameInfo.filename if frameInfo else None
        snippet = None
        if frameInfo and frameInfo.code_context:
            lineno = frameInfo.lineno
            code_line = frameInfo.code_context[0].rstrip()
            snippet = f"   {lineno:4d} | {code_line}"

            # Add column pointer if available (Python 3.11+)
            if (
                hasattr(frameInfo, "positions")
                and frameInfo.positions.col_offset is not None  # type: ignore[attr-defined]
            ):
                col = frameInfo.positions.col_offset  # type: ignore[attr-defined]
                snippet += f"\n        | {' ' * col}^"

        super().__init__(
            message,
            line=line,
            filename=filename,
            snippet=snippet,
            cause=cause,
        )

    def _collect_dsl_errors(
        self,
    ) -> tuple[
        list[tuple["DSLOperationBuildError", str, str]], Optional[BaseException]
    ]:
        """
        Recursively collect all DSLOperationErrors in the exception chain.
        Returns a tuple of (list of unique errors with snippets, final non-DSLOperationError cause).
        Deduplicates by (filename, lineno) to avoid redundant output.
        """
        errors_with_snippets = []
        seen_locations = set()
        current = self

        while current:
            # Add error if it has a snippet to show and location is unique
            if current.snippet and current.filename and current.line:
                location_key = (current.filename, current.line)
                if location_key not in seen_locations:
                    seen_locations.add(location_key)
                    errors_with_snippets.append(
                        (current, current.snippet, current.filename)
                    )
            # Check if cause is also a DSLOperationError
            if current.cause and isinstance(current.cause, DSLOperationBuildError):
                current = current.cause
            else:
                # Found the final cause (not a DSLOperationError)
                break

        return errors_with_snippets, current.cause if current else None

    def _format_message(self) -> str:
        """Formats the error message with nice visual presentation."""
        parts = []

        # Collect all DSLOperationErrors in the chain recursively
        dsl_errors, final_cause = self._collect_dsl_errors()

        # Show error header with the root cause message
        error_msg = self.message
        if final_cause:
            error_msg = f"{type(final_cause).__name__}: {final_cause}"
        parts.append(f"\n{Colors.RED}{Colors.BOLD}[Error] {error_msg}{Colors.RESET}\n")

        # Show the actual traceback first (where the error originated)
        if final_cause:
            import traceback

            tb = final_cause.__traceback__
            if tb:
                parts.append(f"{Colors.BLUE}📍 Exception Origin:{Colors.RESET}")
                # Format the traceback from the original exception
                tb_lines = traceback.format_tb(tb)
                for line in tb_lines:
                    parts.append(line.rstrip())
                parts.append("")

        # Show unique code snippets from DSL call chain (user code locations)
        if dsl_errors:
            parts.append(f"{Colors.BLUE}📋 DSL Call Stack:{Colors.RESET}")
            for error, snippet, filename in dsl_errors:
                parts.append(f"--> {Colors.BLUE}{filename}{Colors.RESET}")
                parts.append(snippet)
                parts.append("")

        parts.append("=" * 100)
        return "\n".join(parts)


def _get_cuda_version() -> str:
    # Client of this module should implement this function
    """
    Placeholder for CUDA version query.

    This function should be implemented by the client of this module.
    When implemented, it must return the CUDA version as a string, e.g. "12.2".

    Raises:
        NotImplementedError: Always, unless overridden by the package initializer or client.
    """
    raise NotImplementedError("_get_cuda_version is not implemented")


@total_ordering
@dataclass(frozen=True)
class DSLCudaVersion:
    """
    Class to represent the CUDA version used to build the DSL.
    """

    major: int
    minor: int

    def __init__(self, version: str):
        parts = version.split(".")
        object.__setattr__(self, "major", int(parts[0]))
        object.__setattr__(self, "minor", int(parts[1]))

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, DSLCudaVersion):
            return NotImplemented
        return self.major == other.major and self.minor == other.minor

    def __lt__(self, other: "DSLCudaVersion") -> bool:
        return [self.major, self.minor] < [other.major, other.minor]


def _coerce_to_cuda_version(
    value: Optional[Union[DSLCudaVersion, str]], param_name: str
) -> Optional[DSLCudaVersion]:
    """
    Coerce a value to DSLCudaVersion.

    :param value: The value to coerce (DSLCudaVersion, str, or None).
    :param param_name: The parameter name for error messages.
    :returns: DSLCudaVersion or None if value is None.
    :raises DSLRuntimeError: If value is not a supported type.
    """
    if value is None:
        return None
    if isinstance(value, DSLCudaVersion):
        return value
    if isinstance(value, str):
        return DSLCudaVersion(value)
    from .diagnostics import DiagId  # lazy: avoid an import cycle

    raise DSLUserCodeError(
        DiagId.CONFIG_VERSION_TYPE,
        param_name=param_name,
        got_type=type(value).__name__,
    )


def target_version(
    exact_version: Optional[Union[DSLCudaVersion, str]] = None,
    *,
    min_version: Optional[Union[DSLCudaVersion, str]] = None,
    max_version: Optional[Union[DSLCudaVersion, str]] = None,
) -> bool:
    """
    Check if the current CUDA version used to build the DSL matches an exact version
    or falls within specified bounds at compile-time.

    Only one of ``exact_version`` *or* ``min_version``/``max_version`` may be specified.
    At least one must be provided.

    :param exact_version: The required CUDA version (e.g., "12.3").
    :type exact_version: Optional[Union[DSLCudaVersion, str]]
    :param min_version: The minimum CUDA version required (inclusive, e.g., "12.0").
    :type min_version: Optional[Union[DSLCudaVersion, str]]
    :param max_version: The maximum CUDA version allowed (inclusive, e.g., "13.2").
    :type max_version: Optional[Union[DSLCudaVersion, str]]

    :returns: ``True`` if the CUDA version matches the requirement(s) specified.
    :rtype: bool

    :raises DSLRuntimeError:
        - If neither an ``exact_version`` nor version range is given.
        - If both an exact version and a range are provided.
        - If ``min_version`` > ``max_version``.
        - If any version parameter is not a DSLCudaVersion or str.

    **Examples**

    .. code-block:: python

        target_version(exact_version="12.3")
        # True if CUDA_VERSION == 12.3

        target_version(min_version="12.0")
        # True if CUDA_VERSION >= 12.0

        target_version(max_version="13.2")
        # True if CUDA_VERSION <= 13.2

        target_version(min_version="12.0", max_version="13.2")
        # True if 12.0 <= CUDA_VERSION <= 13.2
    """
    # Avoid circular dependency
    from .version_info import CUDA_VERSION
    from .diagnostics import DiagId

    # Coerce all version parameters to DSLCudaVersion at the start
    exact_v = _coerce_to_cuda_version(exact_version, "exact_version")
    min_v = _coerce_to_cuda_version(min_version, "min_version")
    max_v = _coerce_to_cuda_version(max_version, "max_version")

    # Sanity check
    is_range_check = min_v is not None or max_v is not None
    is_exact_version_check = exact_v is not None
    if is_range_check and is_exact_version_check:
        raise DSLUserCodeError(DiagId.CONFIG_VERSION_CONFLICT)

    if is_range_check:
        if min_v is None and max_v is None:
            raise DSLUserCodeError(DiagId.CONFIG_VERSION_MISSING)
        if min_v is not None and max_v is not None:
            if min_v > max_v:
                raise DSLUserCodeError(DiagId.CONFIG_VERSION_RANGE_INVALID)

        result = True
        if min_v is not None:
            result = result and CUDA_VERSION >= min_v
        if max_v is not None:
            result = result and CUDA_VERSION <= max_v
        return result
    elif is_exact_version_check:
        return CUDA_VERSION == exact_v
    else:
        raise DSLUserCodeError(DiagId.CONFIG_VERSION_REQUIRED)
