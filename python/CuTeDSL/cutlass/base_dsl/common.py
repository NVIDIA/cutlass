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
import warnings
from typing import (
    TYPE_CHECKING,
    Any,
    ClassVar,
    Dict,
    Generator,
    Optional,
    Tuple,
    TypeVar,
    Union,
)
import functools
from functools import total_ordering
from dataclasses import dataclass
from packaging.version import InvalidVersion, Version

if TYPE_CHECKING:
    from .compiler import CompileOptions

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

_active_compile_options: contextvars.ContextVar["CompileOptions | None"] = (
    contextvars.ContextVar("active_compile_options", default=None)
)


def get_current_compile_options() -> "CompileOptions":
    """Return the CompileOptions being traced.

    Outside a compilation, return default options.
    """
    options = _active_compile_options.get()
    if options is None:
        from .compiler import CompileOptions

        options = CompileOptions()
    return options


@contextlib.contextmanager
def active_compile_options(options: "CompileOptions") -> Generator[None, None, None]:
    """Expose ``options`` to trace-time code for this compilation."""
    token = _active_compile_options.set(options)
    try:
        yield
    finally:
        _active_compile_options.reset(token)


_CUDA_ERROR_NAME_ALIASES = {
    "cudaErrorNoKernelImageForDevice": "CUDA_ERROR_NO_BINARY_FOR_GPU",
    "cudaErrorMemoryAllocation": "CUDA_ERROR_OUT_OF_MEMORY",
    "cudaErrorInitializationError": "CUDA_ERROR_NOT_INITIALIZED",
}


def _cuda_error_lookup_key(error_name: str) -> str:
    """Fold the driver and runtime spellings of one CUDA error onto one key.

    The same failure reaches this module as ``CUDA_ERROR_INVALID_VALUE`` or as
    ``cudaErrorInvalidValue`` depending on which CUDA API reported it, so tables
    keyed by error name must not depend on the spelling. Pairs that differ by
    more than case and punctuation are folded through
    ``_CUDA_ERROR_NAME_ALIASES`` first.
    """
    canonical = _CUDA_ERROR_NAME_ALIASES.get(error_name, error_name).lower()
    for prefix in ("cuda_error_", "cudaerror"):
        if canonical.startswith(prefix):
            canonical = canonical[len(prefix) :]
            break
    return canonical.replace("_", "")


def _lookup_by_cuda_error(
    table: Dict[str, Any], lookup_key: str, default: Any = ""
) -> Any:
    """Look up a table keyed by CUDA error name, ignoring the spelling."""
    for name, value in table.items():
        if _cuda_error_lookup_key(name) == lookup_key:
            return value
    return default


_CUDA_INVALID_LAUNCH_VALUE_KEY = _cuda_error_lookup_key("CUDA_ERROR_INVALID_VALUE")


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


def is_pyir_enabled() -> bool:
    """Return True when the user has set ``ENABLE_PYIR=True``."""
    env_manager = get_current_env_manager()
    if env_manager is not None:
        return getattr(env_manager, "enable_pyir", False)
    return False


def is_auto_m2s_enabled() -> bool:
    """Return True when ``CUTE_DSL_AUTO_M2S=True``.

    Controls auto-promotion of meta-primitives (``int``/``float``/``bool``)
    to staged DSL types inside staged control flow.
    """
    env_manager = get_current_env_manager()
    if env_manager is not None:
        return getattr(env_manager, "auto_m2s", False)
    return False


def is_pyir_verify_scans_enabled() -> bool:
    """Return True when ``CUTE_DSL_PYIR_VERIFY_SCANS=True``: every incremental
    PyIR registry scan also runs its full scan and the two must agree."""
    env_manager = get_current_env_manager()
    if env_manager is not None:
        return getattr(env_manager, "pyir_verify_scans", False)
    return False


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

    # Check the MRO by name to avoid circular imports while allowing specialized
    # DSL exception subclasses to inherit the clean rendering behavior.
    clean_error_bases = {
        "DSLOperationError",
        "DSLOperationBuildError",
        "DSLUserCodeError",
        "CompilerDiagnosticError",
        "DSLRuntimeError",
        "DSLCudaRuntimeError",
    }
    if any(base.__name__ in clean_error_bases for base in exc_type.__mro__):
        if show_stacktrace:
            # Show full traceback in verbose mode
            _original_excepthook(exc_type, exc_value, exc_traceback)
        else:
            # Just print the formatted message (which is in __str__)
            print(str(exc_value), file=sys.stderr)
        # Don't kill an interactive session (REPL, `python -i`, PYTHONINSPECT)
        if not (hasattr(sys, "ps1") or sys.flags.interactive or sys.flags.inspect):
            sys.exit(1)
    else:
        # Use the original exception hook for other exceptions
        _original_excepthook(exc_type, exc_value, exc_traceback)


# Install the custom exception hook
sys.excepthook = _dsl_excepthook


# =============================================================================
# DSL Exceptions
# =============================================================================


def _format_cause(cause: Any) -> str:
    """Render an error's underlying cause, or empty string when there is none."""
    return f"Caused exception: {cause}" if cause else ""


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
        return _format_cause(self.cause)

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
    _cuda_error_lookup_key(name)
    for name in (
        "CUDA_ERROR_INVALID_SOURCE",
        "CUDA_ERROR_NO_BINARY_FOR_GPU",
        "CUDA_ERROR_INVALID_PTX",
        "CUDA_ERROR_UNSUPPORTED_PTX_VERSION",
        "CUDA_ERROR_NO_DEVICE",
        "CUDA_ERROR_INVALID_DEVICE",
    )
)


def _normalize_cuda_error_name(error_name: Union[str, bytes]) -> str:
    if isinstance(error_name, bytes):
        return error_name.decode("utf-8")
    if (
        isinstance(error_name, str)
        and error_name.startswith("b'")
        and error_name.endswith("'")
    ):
        return error_name[2:-1]
    return str(error_name)


def _target_arch_from_env_manager(env_manager: Any) -> str:
    """Architecture already known to the env manager, or ``unknown``.

    Must not read ``env_manager.arch``. That property probes the CUDA driver
    and a failed probe raises ``DSLCudaRuntimeError``, whose constructor
    calls this module again.
    """
    if env_manager is None:
        return "unknown"
    configured = getattr(env_manager, "configured_arch", None)
    if callable(configured):
        return configured() or "unknown"
    return "unknown"


def _get_friendly_cuda_error_message(
    error_code: int, error_name: Union[str, bytes]
) -> tuple[str, str, Union[str, tuple[str, ...]]]:
    """Get a user-friendly error message for common CUDA errors."""
    # Avoid circular dependency
    from .runtime.cuda import get_device_info

    error_name = _normalize_cuda_error_name(error_name)
    lookup_key = _cuda_error_lookup_key(error_name)

    env_manager = get_current_env_manager()
    target_arch = _target_arch_from_env_manager(env_manager)
    arch_is_relevant = lookup_key in _ARCH_RELATED_CUDA_ERRORS
    invalid_launch_value_suggestion = (
        "Check `.launch(...)`: grid, block, dynamic shared memory, stream, "
        "and attributes. Keep block.x * block.y * block.z <= "
        "maxThreadsPerBlock. If only threadIdx.x is used, launch with "
        "block=(threads, 1, 1)."
    )
    if lookup_key == _CUDA_INVALID_LAUNCH_VALUE_KEY:
        message = f"CUDA launch failed: {error_name} ({error_code})"
        return message, "", invalid_launch_value_suggestion

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
        "CUDA_ERROR_ILLEGAL_INSTRUCTION": (
            f"{Colors.RED}❌ A running kernel executed an illegal instruction.{Colors.RESET}\n\n"
            f"{Colors.YELLOW}This is a fault inside the kernel, not an architecture mismatch.{Colors.RESET}\n\n"
        ),
        "CUDA_ERROR_INVALID_CLUSTER_SIZE": (
            f"{Colors.RED}❌ Invalid cluster size.{Colors.RESET}\n\n"
        ),
    }

    error_suggestions: Dict[str, Union[str, tuple[str, ...]]] = {
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
        "cudaErrorInsufficientDriver": (
            "1. Run nvidia-smi to confirm CUDA driver version",
            "2. Ensure the CUDA driver version meets the requirement of the installed cuda-bindings package",
        ),
    }

    message = (
        f"{error_name} (error code: {error_code}) \n"
        f"{_lookup_by_cuda_error(additional_info, lookup_key)} \n\n{Colors.RESET}"
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

    return message, debug_info, _lookup_by_cuda_error(error_suggestions, lookup_key)


class DSLCudaRuntimeError(DSLBaseError):
    """
    Raised when an error occurs during CUDA runtime code generation in the DSL.
    """

    # Inherits all logic from DSLRuntimeError; override methods if you need
    # specialized behavior or formatting for runtime errors.
    def __init__(
        self,
        error_code: int,
        error_name: Union[str, bytes],
        runtime_detail: Optional[str] = None,
        suggestion: Union[str, list[str], tuple[str, ...], None] = None,
    ) -> None:
        self._error_code = error_code
        self._error_name = error_name
        normalized_error_name = _normalize_cuda_error_name(error_name)
        concise_launch_error = (
            _cuda_error_lookup_key(normalized_error_name)
            == _CUDA_INVALID_LAUNCH_VALUE_KEY
        )
        if concise_launch_error:
            self.code = "CUDA_LAUNCH_INVALID_CONFIG"
        message, debug_info, default_suggestion = _get_friendly_cuda_error_message(
            error_code, error_name
        )
        selected_suggestion = default_suggestion if suggestion is None else suggestion
        if runtime_detail:
            if concise_launch_error:
                message = f"{message.rstrip()}\n\n{runtime_detail.strip()}"
                if selected_suggestion:
                    message += "\n"
            else:
                debug_info = (
                    f"\n- {Colors.BOLD}CUDA runtime detail:{Colors.RESET} "
                    f"{runtime_detail.strip()}\n{debug_info.lstrip()}"
                )
        elif concise_launch_error:
            message = (
                f"{message.rstrip()}\n\n"
                "CUDA rejected the launch configuration before running the kernel."
            )

        super().__init__(
            message,
            error_code=None if concise_launch_error else error_code,
            context=debug_info,
            suggestion=selected_suggestion,
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
        return _format_cause(self.cause)


class DSLFutureWarning(FutureWarning):
    """A DSL warning about behavior that will change in a future release."""


class DSLDeprecationWarning(DeprecationWarning):
    """A deprecated DSL API was used.

    Python's default filters show ``DeprecationWarning`` only when the call
    site is in ``__main__``, so a deprecation reached from kernels that live in
    a package would be silent for its whole removal window. Importing this
    module therefore installs a ``default`` filter for this category, giving
    one warning per call site, unless the interpreter was started with ``-W``
    or ``PYTHONWARNINGS``. Filters installed later take precedence, including
    the ones ``[DSL]_WARNINGS_IGNORE`` and ``[DSL]_WARNINGS_AS_ERRORS`` add,
    and any filter on ``DeprecationWarning`` also matches this subclass.

    DSL code switches to the replacement as soon as an API is deprecated, so
    a warning attributed to a DSL module is a DSL bug; the DSL's own tests turn
    those into errors.
    """


if not sys.warnoptions:
    warnings.filterwarnings("default", category=DSLDeprecationWarning)


_DSL_PACKAGE = __name__.partition(".")[0]
_DSL_PLUMBING_PACKAGES = (f"{_DSL_PACKAGE}.base_dsl", f"{_DSL_PACKAGE}._mlir_helpers")


def _in_package(module: str, package: str) -> bool:
    return module == package or module.startswith(package + ".")


def _runs_on_deprecated_object(frame: types.FrameType) -> bool:
    """Whether ``frame`` runs a method whose ``self`` is a deprecated class's instance.

    The class dictionaries are read directly because a metaclass
    ``__getattr__`` can fabricate any attribute, ``__deprecated__`` included.
    """
    code = frame.f_code
    if not code.co_argcount or code.co_varnames[0] != "self":
        return False
    receiver_class = type(frame.f_locals.get("self"))
    return any("__deprecated__" in vars(klass) for klass in receiver_class.__mro__)


def _warn_deprecated(
    message: str,
    *,
    every_call: bool = False,
    user_input: bool = False,
    api_module: Optional[str] = None,
) -> None:
    """Emit a :class:`DSLDeprecationWarning` at the code that used the API.

    A deprecated path is reached through a varying number of frames that only
    deliver the call: the deprecated API's own module (``__post_init__``
    chains, module ``__getattr__``), DSL infrastructure (``base_dsl``, such as
    the PyIR call proxies, and ``_mlir_helpers``, such as ``dsl_user_op``), the
    ``@deprecated`` wrapper and the standard library. No fixed ``stacklevel``
    names the caller for every path, so the warning is attributed to the
    nearest frame outside those: the author's line, or the line of DSL code
    that still uses the API. ``api_module`` names the deprecated API's module
    and defaults to the caller's; a use from inside that module is attributed
    past it. A DSL method running on a deprecated object, such as a mixin or
    base-class method in another module, is part of that deprecated API too.
    A warning raised while such an object rebuilds itself from MLIR values
    (``__new_from_mlir_values__``, when the DSL launches a kernel or carries
    the object through a loop) is dropped: the author was warned when they
    built the object, and the rebuild is not a new use.

    ``user_input=True`` is for a deprecated value, option or setting that the
    author supplied and DSL code may pass along, such as an enum member handed
    to a helper that builds the op: the warning then also passes every DSL
    frame and names the author.

    By default the warning is recorded in that frame's module registry, so the
    ``default`` filter shows it once per call site. ``every_call=True`` skips
    the registry, for deprecations in their final stage: the warning then
    shows on every call, while ``ignore``, ``error`` and ``once`` filters,
    including ``[DSL]_WARNINGS_IGNORE``, still apply.
    """
    stdlib = sys.stdlib_module_names
    frame = sys._getframe(1)
    if api_module is None:
        api_module = frame.f_globals.get("__name__")
    try:
        while frame.f_back is not None:
            module = frame.f_globals.get("__name__") or ""
            in_dsl = _in_package(module, _DSL_PACKAGE)
            on_deprecated_object = in_dsl and _runs_on_deprecated_object(frame)
            if (
                on_deprecated_object
                and frame.f_code.co_name == "__new_from_mlir_values__"
            ):
                return
            if not (
                module == api_module
                or on_deprecated_object
                or module == "typing_extensions"
                or module.split(".", 1)[0] in stdlib
                or any(_in_package(module, pkg) for pkg in _DSL_PLUMBING_PACKAGES)
                or (user_input and in_dsl)
            ):
                break
            frame = frame.f_back
        warnings.warn_explicit(
            message,
            DSLDeprecationWarning,
            frame.f_code.co_filename,
            frame.f_lineno,
            module=frame.f_globals.get("__name__"),
            registry=(
                None
                if every_call
                else frame.f_globals.setdefault("__warningregistry__", {})
            ),
        )
    finally:
        del frame


if TYPE_CHECKING:
    from typing_extensions import deprecated as _deprecated
else:

    class _deprecated:
        """Mark a DSL function, method or class as deprecated.

        Type checkers see ``typing_extensions.deprecated``, so they report
        uses statically. At runtime the call, instantiation or subclassing
        emits a :class:`DSLDeprecationWarning` through
        :func:`_warn_deprecated`, which attributes it to the code that used
        the API whatever wrappers sit in between (``dsl_user_op``, the PyIR
        call proxies), instead of to a fixed ``stacklevel``. The wrapping
        otherwise matches ``typing_extensions.deprecated``, except that only
        the wrapper is marked ``__deprecated__``: wrapping a replacement API
        under its old name does not mark the replacement.
        """

        def __init__(self, message: str, /) -> None:
            if not isinstance(message, str):
                raise TypeError(
                    f"Expected an object of type str for 'message', not {message!r}"
                )
            self.message = message

        def __call__(self, arg: object, /) -> object:
            message = self.message
            api_module = arg.__module__
            if isinstance(arg, type):
                original_new = arg.__new__

                @functools.wraps(original_new)
                def __new__(cls: type, /, *args: object, **kwargs: object) -> object:
                    if cls is arg:
                        _warn_deprecated(message, api_module=api_module)
                    if original_new is not object.__new__:
                        return original_new(cls, *args, **kwargs)
                    elif cls.__init__ is object.__init__ and (args or kwargs):
                        raise TypeError(f"{cls.__name__}() takes no arguments")
                    else:
                        return original_new(cls)

                arg.__new__ = staticmethod(__new__)

                if "__init_subclass__" in arg.__dict__:
                    original_init_subclass = arg.__init_subclass__
                    if isinstance(original_init_subclass, types.MethodType):
                        original_init_subclass = original_init_subclass.__func__

                    @functools.wraps(original_init_subclass)
                    def __init_subclass__(*args: object, **kwargs: object) -> object:
                        _warn_deprecated(message, api_module=api_module)
                        return original_init_subclass(*args, **kwargs)

                else:

                    def __init_subclass__(
                        cls: type, *args: object, **kwargs: object
                    ) -> object:
                        _warn_deprecated(message, api_module=api_module)
                        return super(arg, cls).__init_subclass__(*args, **kwargs)

                arg.__init_subclass__ = classmethod(__init_subclass__)
                arg.__deprecated__ = __new__.__deprecated__ = message
                __init_subclass__.__deprecated__ = message
                return arg
            if callable(arg):

                @functools.wraps(arg)
                def wrapper(*args: object, **kwargs: object) -> object:
                    _warn_deprecated(message, api_module=api_module)
                    return arg(*args, **kwargs)

                wrapper.__deprecated__ = message
                return wrapper
            raise TypeError(
                f"@deprecated must be applied to a class or callable, not {arg!r}"
            )


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


class DSLUserCodeRuntimeError(DSLUserCodeError, RuntimeError):
    """``DSLUserCodeError`` that is also catchable as ``RuntimeError``.

    Raise this (instead of plain ``DSLUserCodeError``) when replacing a raw
    ``RuntimeError`` that user code may already catch — e.g. the MLIR
    bindings' "requires a Context" error, which trace-time helpers probe
    with ``except RuntimeError:`` to detect that no context is active.
    """


class DSLUserCodeTypeError(DSLUserCodeError, TypeError):
    """``DSLUserCodeError`` that is also catchable as ``TypeError``.

    Raise this when replacing a raw ``TypeError`` that user code may already
    catch — e.g. nanobind overload-resolution failures caused by a missing
    default MLIR context — and for an argument of the wrong kind.
    """


class DSLUserCodeValueError(DSLUserCodeError, ValueError):
    """``DSLUserCodeError`` that is also catchable as ``ValueError``.

    Raise this for an argument of the right kind but an unacceptable value or
    range, and when replacing a raw ``ValueError`` that user code may already
    catch, so ``except ValueError`` and ``except DSLUserCodeError`` both work.
    """


class DSLUserCodeIndexError(DSLUserCodeError, IndexError):
    """``DSLUserCodeError`` that is also catchable as ``IndexError``.

    Raise this for an out-of-range mode or index argument, and when replacing
    a raw ``IndexError`` that user code may already catch.
    """


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
        # If frameInfo not provided, capture the caller's frame information
        if frameInfo is None:
            current_frame = inspect.currentframe()
            frame = current_frame.f_back if current_frame else None
            frameInfo = inspect.getframeinfo(frame) if frame else None
            del current_frame

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


def _get_dsl_version() -> str:
    # Client of this module should implement this function
    """
    Placeholder for DSL package version query.

    This function should be implemented by the client of this module.
    When implemented, it must return the DSL package version as a string,
    e.g. "4.6.0" or "4.6.0.dev0".

    Raises:
        NotImplementedError: Always, unless overridden by the package initializer or client.
    """
    raise NotImplementedError("_get_dsl_version is not implemented")


def _is_pep440_compliant(version_str: str) -> bool:
    """Return True if ``version_str`` is a PEP 440 version."""
    try:
        Version(version_str)
        return True
    except InvalidVersion:
        return False


# packaging.version.Version names the third release field ``micro``.
_PEP440_COMPONENT_ATTRS: Tuple[str, ...] = ("major", "minor", "micro")


@total_ordering
class _VersionBase:
    """
    Shared parsing and comparison logic for the version classes below.

    Validates the input with :class:`packaging.version.Version` (PEP 440), then
    copies the release fields named by ``_component_names``. Missing components
    default to 0 (e.g. ``"4"`` parses as 4.0 / 4.0.0). Prerelease and local
    suffixes are ignored for comparison, so ``"4.9.0a0.dev0"`` parses as 4.9.0.
    Comparisons are component-wise and only defined between instances of the
    same class; cross-type comparison is intentionally unsupported.
    """

    _component_names: ClassVar[Tuple[str, ...]] = ()

    def __init__(self, version: str) -> None:
        if not _is_pep440_compliant(version):
            from .diagnostics import DiagId  # lazy: avoid an import cycle

            raise DSLUserCodeError(
                DiagId.CONFIG_VERSION_MALFORMED,
                version_string=version,
                class_name=type(self).__name__,
            )
        parsed = Version(version)
        for i, name in enumerate(self._component_names):
            object.__setattr__(self, name, getattr(parsed, _PEP440_COMPONENT_ATTRS[i]))

    def _components(self) -> Tuple[int, ...]:
        return tuple(getattr(self, name) for name in self._component_names)

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, _VersionBase) or type(other) is not type(self):
            return NotImplemented
        return self._components() == other._components()

    def __lt__(self, other: "_VersionBase") -> bool:
        if type(other) is not type(self):
            return NotImplemented
        return self._components() < other._components()

    def __hash__(self) -> int:
        return hash(self._components())


@dataclass(frozen=True, init=False, eq=False)
class DSLCudaVersion(_VersionBase):
    """
    Class to represent the CUDA version used to build the DSL.

    Comparisons use (major, minor); "12" parses as 12.0.
    """

    major: int
    minor: int

    _component_names: ClassVar[Tuple[str, ...]] = ("major", "minor")


@dataclass(frozen=True, init=False, eq=False)
class DSLVersion(_VersionBase):
    """
    Class to represent the version of the DSL Python package itself
    (e.g. ``cutlass.__version__``).

    Parses PEP 440 version strings; comparisons use (major, minor, patch).
    Missing components default to 0 and any prerelease or local suffix is
    ignored, so "4.6" parses as 4.6.0, "4.6.1.dev0" as 4.6.1, and
    "4.9.0a0.dev0" as 4.9.0.
    """

    major: int
    minor: int
    patch: int

    _component_names: ClassVar[Tuple[str, ...]] = ("major", "minor", "patch")


# Bound rather than constrained to the concrete classes: the version class is
# selected from _VERSION_KINDS at runtime, so a static checker cannot know
# which one a given call uses. "One call, one class" is enforced at runtime by
# _coerce_to_version (CONFIG_VERSION_TYPE); the classes intentionally do not
# support cross-type comparison.
_VersionT = TypeVar("_VersionT", bound=_VersionBase)


# Maps each target_version(kind=...) value to the version class its parameters
# coerce to and the name of the current-version global in version_info.
# Adding a new version kind only requires a new entry here (plus the global).
_VERSION_KINDS: Dict[str, Tuple[type[_VersionBase], str]] = {
    "ctk": (DSLCudaVersion, "CUDA_VERSION"),
    "dsl": (DSLVersion, "DSL_VERSION"),
}


def _coerce_to_version(
    value: Optional[Union[_VersionT, str]],
    param_name: str,
    version_cls: type[_VersionT],
) -> Optional[_VersionT]:
    """
    Coerce a value to the given version class.

    :param value: The value to coerce (an instance of version_cls, str, or None).
    :param param_name: The parameter name for error messages.
    :param version_cls: The version class to coerce to (DSLCudaVersion or DSLVersion).
    :returns: An instance of version_cls, or None if value is None.
    :raises DSLUserCodeError: If value is not a supported type.
    """
    if value is None:
        return None
    if isinstance(value, version_cls):
        return value
    if isinstance(value, str):
        return version_cls(value)
    from .diagnostics import DiagId  # lazy: avoid an import cycle

    raise DSLUserCodeError(
        DiagId.CONFIG_VERSION_TYPE,
        param_name=param_name,
        expected_type=version_cls.__name__,
        got_type=type(value).__name__,
    )


def _check_version_requirement(
    current: _VersionT,
    exact_v: Optional[_VersionT],
    min_v: Optional[_VersionT],
    max_v: Optional[_VersionT],
) -> bool:
    """
    Evaluate an exact-or-range version requirement against ``current``.

    Callers must ensure at least one requirement parameter is not None.
    """
    from .diagnostics import DiagId

    is_range_check = min_v is not None or max_v is not None
    is_exact_version_check = exact_v is not None
    if is_range_check and is_exact_version_check:
        raise DSLUserCodeError(DiagId.CONFIG_VERSION_CONFLICT)

    if is_range_check:
        if min_v is not None and max_v is not None:
            if min_v > max_v:
                raise DSLUserCodeError(DiagId.CONFIG_VERSION_RANGE_INVALID)

        result = True
        if min_v is not None:
            result = result and current >= min_v
        if max_v is not None:
            result = result and current <= max_v
        return result
    return current == exact_v


def target_version(
    exact_version: Optional[Union[DSLCudaVersion, DSLVersion, str]] = None,
    *,
    min_version: Optional[Union[DSLCudaVersion, DSLVersion, str]] = None,
    max_version: Optional[Union[DSLCudaVersion, DSLVersion, str]] = None,
    kind: str = "ctk",
) -> bool:
    """
    Check at compile-time that a target version matches an exact version or
    falls within specified bounds.

    ``kind`` selects which version is checked: ``"ctk"`` (the default) checks
    the CUDA toolkit version used to build the DSL, ``"dsl"`` checks the DSL
    package version (``cutlass.__version__``). One call checks one kind;
    combine two calls with ``and`` when both are needed. Only one of the exact
    version *or* the min/max range may be specified, and at least one version
    parameter must be provided.

    CUDA toolkit version comparisons use (major, minor). DSL version
    comparisons use (major, minor, patch); missing components default to 0 and
    dev suffixes are ignored, so ``exact_version="4.6"`` means exactly 4.6.0 —
    use a ``min_version``/``max_version`` range to match a whole release
    series.

    :param exact_version: The required version (e.g., "12.3").
    :type exact_version: Optional[Union[DSLCudaVersion, DSLVersion, str]]
    :param min_version: The minimum version required (inclusive, e.g., "12.0").
    :type min_version: Optional[Union[DSLCudaVersion, DSLVersion, str]]
    :param max_version: The maximum version allowed (inclusive, e.g., "13.2").
    :type max_version: Optional[Union[DSLCudaVersion, DSLVersion, str]]
    :param kind: Which version to check: "ctk" (CUDA toolkit, default) or "dsl"
        (DSL package).
    :type kind: str

    :returns: ``True`` if the selected version matches the requirement(s) specified.
    :rtype: bool

    :raises DSLUserCodeError:
        - If ``kind`` is not a supported version kind.
        - If no version parameter is given.
        - If both an exact version and a range are provided.
        - If the minimum version > the maximum version.
        - If any version parameter is not a str or the version class matching
          ``kind`` (DSLCudaVersion for "ctk", DSLVersion for "dsl").
        - If a version string has non-numeric components (e.g. "4.x").

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

        target_version(kind="dsl", min_version="4.6")
        # True if DSL_VERSION >= 4.6

        target_version(min_version="13.1") and target_version(kind="dsl", min_version="4.6")
        # Combine a CUDA toolkit check and a DSL check with two calls
    """
    # Avoid circular dependency
    from . import version_info
    from .diagnostics import DiagId

    if kind not in _VERSION_KINDS:
        raise DSLUserCodeError(
            DiagId.CONFIG_VERSION_KIND_INVALID,
            kind=kind,
            valid_kinds=", ".join(f'"{k}"' for k in _VERSION_KINDS),
        )
    version_cls, current_version_name = _VERSION_KINDS[kind]
    current_version = getattr(version_info, current_version_name)

    # Coerce all version parameters to the kind's version class at the start
    exact_v = _coerce_to_version(exact_version, "exact_version", version_cls)
    min_v = _coerce_to_version(min_version, "min_version", version_cls)
    max_v = _coerce_to_version(max_version, "max_version", version_cls)

    if exact_v is None and min_v is None and max_v is None:
        raise DSLUserCodeError(DiagId.CONFIG_VERSION_REQUIRED)

    return _check_version_requirement(current_version, exact_v, min_v, max_v)
