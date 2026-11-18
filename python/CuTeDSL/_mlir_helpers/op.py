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
This module provides MLIR's OP helper functions
"""

import dis
import inspect
import importlib.util
import itertools
import linecache
import os
import sys
import types
import warnings
from contextvars import ContextVar
from contextlib import contextmanager
from functools import wraps, lru_cache
from typing import Any, Callable, Iterator, TYPE_CHECKING

from .._mlir import ir
from ..base_dsl.common import (
    DSLBaseError,
    DSLOperationBuildError,
    DSLRuntimeError,
    DSLUserCodeError,
    DSLUserCodeRuntimeError,
    DSLUserCodeTypeError,
    DSLUserCodeValueError,
)
from ..base_dsl.diagnostics import DiagId
from ..base_dsl.utils.logger import log
from ..base_dsl.utils.stacktrace import walk_to_top_module

if TYPE_CHECKING:
    from ..base_dsl.pyir_runtime import MutableValue


try:
    from ..base_dsl.pyir_runtime import (
        _pyir_auto_load_arg,
        _pyir_lookup_slot_from_value,
        _pyir_value_tracked_by_accessible_ref,
    )
except ImportError:

    def _pyir_auto_load_arg(arg: Any, *, row_authoritative: bool = False) -> Any:  # noqa: ARG001
        return arg

    def _pyir_lookup_slot_from_value(value: Any) -> "MutableValue | None":  # noqa: ARG001
        return None

    def _pyir_value_tracked_by_accessible_ref(value: Any) -> bool:  # noqa: ARG001
        return False


# The DSL package root is empty by default.
_DSL_PACKAGE_ROOT: str | None = ""
_DSL_PACKAGE_ROOTS: tuple[str, ...] | None = None

# Whether location tracking is enabled.
_ENABLE_FRAME_FILTERING: bool = False

# Generic stack of loc transforms used by dialect-specific compilation
# contexts. Keep this file unaware of any particular dialect or debug-info
# schema; callers decide what a transformed loc means.
_LOC_TRANSFORMS: ContextVar[tuple[Callable[[Any], Any], ...]] = ContextVar(
    "_LOC_TRANSFORMS", default=()
)

# When True, dsl_user_op attributes ops to the closest frame (including DSL
# library code) instead of skipping up to the user's call site. Enabled when
# debugging mode is ON so library developers can see where inside the DSL an op
# was built.
_INCLUDE_LIB_FRAME: bool = False

_SOURCE_FRAMEWORK_DIRS = (
    "_mlir_helpers",
    "base_dsl",
    "cutlass_dsl",
)
_FRAMEWORK_MODULE_PREFIXES = (
    "cutlass",
)

# Trace-time MLIR op verification — see `dsl_user_op` docstring.
# Default resolved lazily from CUTE_DSL_VERIFY_TRACE on first read to
# avoid a circular import with base_dsl.env_manager (which transitively
# imports base_dsl.runtime, _mlir_helpers, and back into this module).
_VERIFY_TRACE_ENABLED: bool | None = None


def _verify_trace_enabled() -> bool:
    global _VERIFY_TRACE_ENABLED
    if _VERIFY_TRACE_ENABLED is None:
        from ..base_dsl.env_manager import get_bool_env_var

        _VERIFY_TRACE_ENABLED = get_bool_env_var("CUTE_DSL_VERIFY_TRACE", False)
    return _VERIFY_TRACE_ENABLED


def set_verify_trace(enabled: bool) -> None:
    """Toggle trace-time MLIR op verification at runtime.

    Useful for hot benchmarking loops where the per-op `verify()`
    cost matters.
    """
    global _VERIFY_TRACE_ENABLED
    _VERIFY_TRACE_ENABLED = bool(enabled)


def get_verify_trace() -> bool:
    """Return whether trace-time verification is currently enabled."""
    return _verify_trace_enabled()


def _verify_new_block_ops(snap_block: Any, snap_n_ops: int, snap_tail: Any) -> Any:
    """Verify the ops ``opFunc`` appended to ``snap_block``.

    ``snap_tail`` is the block's last operation before the call, ``None`` for an
    empty block; the ops after it are the ones the wrapper appended. Anything it
    inserted further up the block -- a deferred op emitted back at a recorded
    construction point -- is left to module-verify time, along with the ops that
    were already there.

    Finding the anchor means walking tail to head, but the verification itself
    then runs head to tail, so a wrapper that builds several malformed ops still
    reports the first one. Wrappers that erase ``snap_tail`` are outside the
    contract: the anchor is then not expected to match anything and every op in
    the window is verified, which is what the count-based diff did before.

    Only ops in ``snap_block`` are reachable this way: a wrapper that emits into
    a different block entirely gets no trace verification, by the diff or by the
    caller's fallback, and is covered at module-verify time.

    Returns the tail operation when it was verified here, so the caller can skip
    verifying that one a second time.
    """
    ops = snap_block.operations
    new_count = len(ops) - snap_n_ops
    if new_count <= 0:
        return None

    # OperationList materialization is O(block size).  Most DSL wrappers append
    # one op, so walk the new tail by negative index instead of list-slicing the
    # whole block on every wrapper call.
    window = 0
    verified_tail = None
    for offset in range(1, new_count + 1):
        op = ops[-offset]
        operation = getattr(op, "operation", op)
        if snap_tail is not None and operation == snap_tail:
            break
        window = offset
        if offset == 1:
            verified_tail = operation
    for offset in range(window, 0, -1):
        ops[-offset].verify()
    return verified_tail


def _set_enable_frame_filtering(enable: bool) -> None:
    """Set whether location tracking is enabled."""
    global _ENABLE_FRAME_FILTERING
    _ENABLE_FRAME_FILTERING = enable


@contextmanager
def loc_transform(transform: Callable[[Any], Any]) -> Iterator[None]:
    """Temporarily rewrite locs produced by ``@dsl_user_op``.

    The decorator still owns the generic work: find the Python user frame and
    build the usual MLIR source loc. This hook lets a frontend or dialect wrap
    that loc while it is building a scoped construct.

    Example:
        def add_scope(loc):
            if loc is None:
                return None
            return ir.Location.name("frontend.scope", childLoc=loc)

        with loc_transform(add_scope):
            dsl_add(a, b)  # receives loc=frontend.scope("file.py":line:col)

    Transforms are scoped and stackable. The innermost transform runs first, so
    nested frontend scopes behave like nested Python context managers.

    ``transform`` receives each generated or caller-provided location, which may
    be ``None``, and returns its replacement. Exceptions raised by ``transform``
    propagate to the caller. The active transform stack is restored when this
    context exits, including exceptional exits.

    :param transform: Callable used to rewrite locations within this scope.
    :type transform: Callable[[Any], Any]
    :raises TypeError: If ``transform`` is not callable.
    """
    if not callable(transform):
        raise TypeError("loc_transform(transform): transform must be callable")

    token = _LOC_TRANSFORMS.set(_LOC_TRANSFORMS.get() + (transform,))
    try:
        yield
    finally:
        _LOC_TRANSFORMS.reset(token)


def _apply_loc_transforms(loc: Any) -> Any:
    """Apply the active scoped loc transforms to ``loc``."""
    for transform in reversed(_LOC_TRANSFORMS.get()):
        loc = transform(loc)
    return loc


def _set_include_lib_frame(enable: bool) -> None:
    """Set whether ops are attributed to the closest (library) frame.

    When enabled, `_find_user_frame` returns the immediate caller of the op
    wrapper instead of walking up past DSL library frames. Used when debugging
    mode is ON for internal DSL development.
    """
    global _INCLUDE_LIB_FRAME
    _INCLUDE_LIB_FRAME = enable


@lru_cache(maxsize=256)
def _is_framework_frame(filename: str) -> bool:
    """Check if a frame's filename belongs to DSL library code."""
    global _DSL_PACKAGE_ROOT, _DSL_PACKAGE_ROOTS
    if _DSL_PACKAGE_ROOTS is None:
        roots: list[str] = []

        module_root = walk_to_top_module(os.path.dirname(os.path.abspath(__file__)))

        _DSL_PACKAGE_ROOT = module_root
        if _DSL_PACKAGE_ROOT is not None:
            roots.append(os.path.abspath(_DSL_PACKAGE_ROOT))

        for package_name in _FRAMEWORK_MODULE_PREFIXES:
            spec = importlib.util.find_spec(package_name)
            if spec is None:
                continue
            if spec.submodule_search_locations:
                roots.extend(
                    os.path.abspath(path) for path in spec.submodule_search_locations
                )
            elif spec.origin:
                roots.append(os.path.dirname(os.path.abspath(spec.origin)))

        _DSL_PACKAGE_ROOTS = tuple(dict.fromkeys(roots))

    if not _DSL_PACKAGE_ROOTS:
        return False

    filename = os.path.abspath(filename)
    return any(
        filename == root or filename.startswith(root + os.sep)
        for root in _DSL_PACKAGE_ROOTS
    )


def _is_framework_module(module_name: str) -> bool:
    if not module_name:
        return False
    framework_prefixes: tuple[str, ...] = _FRAMEWORK_MODULE_PREFIXES

    return any(
        module_name == prefix or module_name.startswith(prefix + ".")
        for prefix in framework_prefixes
    )


# Python 3.14 implements warnings.deprecated in the private _py_warnings module.
_DEPRECATION_WRAPPER_MODULES = frozenset(
    {"typing_extensions", "warnings", "_py_warnings"}
)


def _is_framework_stack_frame(frame: types.FrameType) -> bool:
    """Return True for a frame that is not the author's call site.

    Besides DSL code, this covers the wrapper that ``@deprecated`` (from
    ``typing_extensions`` or ``warnings``) puts around a deprecated API. That
    frame sits between the author and the DSL op whenever a deprecated API
    reaches one without forwarding ``loc``, and its file lies outside the DSL
    package, so stopping there would name ``typing_extensions.py`` as the
    source location.
    """
    module_name = frame.f_globals.get("__name__", "")
    return (
        _is_framework_module(module_name)
        or module_name in _DEPRECATION_WRAPPER_MODULES
        or _is_framework_frame(frame.f_code.co_filename)
    )


def _find_user_frame(start_frame: types.FrameType | None) -> types.FrameType | None:
    """Walk up the call stack from start_frame to find the first user (non-library) frame.

    Returns the first frame whose file is not under the DSL package root.
    Falls back to start_frame if no user frame is found.

    Uses linear search with early termination - returns immediately upon finding the
    first user frame. This is O(m) where m is the position of the first user frame
    (typically 3-10). This is optimal - no algorithm can do better for finding the
    first occurrence in an unsorted sequence.

    The main optimization is @lru_cache on _is_framework_frame(), which caches filename
    checks across all DSL operations.
    """
    if _INCLUDE_LIB_FRAME:
        return start_frame
    if not _ENABLE_FRAME_FILTERING:
        return start_frame

    frame = start_frame
    while frame is not None:
        if not _is_framework_stack_frame(frame):
            return frame
        frame = frame.f_back
    # Fallback: if everything is framework code, use the original caller
    return start_frame


def _get_user_warning_stacklevel(stacklevel: int) -> int:
    """Use a fixed depth unless source-location tracking is enabled.

    Call this directly in ``warnings.warn(..., stacklevel=...)``. When line
    info or compiler diagnostics are enabled, skip DSL library frames to
    identify the user's call site.
    """
    if not _ENABLE_FRAME_FILTERING:
        return stacklevel

    frame: types.FrameType | None = sys._getframe(1)
    try:
        stacklevel = 1
        while frame is not None:
            if not _is_framework_stack_frame(frame):
                return stacklevel
            frame = frame.f_back
            stacklevel += 1
        return 1
    finally:
        del frame


def _is_missing_context_error(e: BaseException) -> bool:
    """Return True for the raw errors the MLIR bindings raise when an
    IR-building call runs with no active ``ir.Context``.

    Three shapes exist across MLIR binding generations:

    1. Older MLIR Python bindings: ``_ods_get_default_loc_context`` raises
       ``RuntimeError("An MLIR function requires a Context but none was
       provided ...")``; op builders that resolve their default location
       raise the sibling ``RuntimeError("An MLIR function requires a
       Location but none was provided ...")``.

    2. Newer MLIR Python bindings:
       ``get_default_loc_context`` returns ``None`` instead of raising, so
       the error surfaces one level deeper — ``Location.current`` and
       ``InsertionPoint.current`` raise ``ValueError("Value not set:
       InsertionPoint")`` / ``ValueError("Value not set: Location")`` when
       no MLIR context is active.

    3. nanobind overloads whose trailing ``context`` parameter cannot be
       filled from the (absent) default context fail overload resolution with
       ``TypeError("...(): incompatible function arguments...")``.
    """
    if isinstance(e, DSLBaseError):
        return False
    if isinstance(e, RuntimeError):
        message = str(e)
        return "requires a Context" in message or "requires a Location" in message
    if isinstance(e, ValueError):
        # New MLIR Python bindings raise ValueError from the DefaultingPy*
        # accessors (Location.current / InsertionPoint.current) when no
        # context is active: "Value not set: InsertionPoint" / "Value not
        # set: Location".
        return "Value not set" in str(e) or "requires a Context" in str(e)
    if isinstance(e, TypeError):
        return "incompatible function arguments" in str(e)
    return False


class _DSLUserCodeMLIRError(DSLUserCodeValueError, ir.MLIRError):
    """``DSLUserCodeValueError`` that is also catchable as ``ir.MLIRError``.

    ``dsl_user_op`` raises this for an ``MLIRError`` that an op builder raised
    while creating an op, so ``except MLIRError`` handlers keep catching it. The
    binding declares ``message`` and ``error_diagnostics`` as read-only
    properties: ``message`` is shadowed by a plain class attribute so the DSL
    error can store its rendered message, and ``error_diagnostics`` returns the
    diagnostics of the original ``MLIRError``.
    """

    message = ""

    @property
    def error_diagnostics(self) -> list[Any]:
        return getattr(self.cause, "error_diagnostics", [])


def _translate_binding_error(e: BaseException, api: str) -> DSLUserCodeError | None:
    """Return the user-facing error for a raw MLIR binding error, or ``None``.

    The generated op builders reject bad arguments with errors that name
    binding internals rather than the API the user called:

    - ``ir.MLIRError`` when the op fails verification while it is created
      (``Operation creation failed: ...``, ``Unable to parse attribute: ...``);
    - ``ValueError('Operand N of operation "..." must be a Value ...')`` when an
      operand is not an MLIR value;
    - ``RuntimeError('std::bad_cast')`` when an attribute argument has a Python
      type the binding cannot convert.

    Each maps to a ``DSLUserCodeError`` subclass that also inherits the class
    it replaces, so ``except ValueError`` / ``except RuntimeError`` /
    ``except MLIRError`` handlers keep catching it: ``MLIRError`` maps to
    ``_DSLUserCodeMLIRError`` (a ``DSLUserCodeValueError``), the operand error to
    ``DSLUserCodeValueError`` and ``std::bad_cast`` to ``DSLUserCodeRuntimeError``.
    The error does not depend on whether trace-time
    verification is enabled, because all three are raised while the op is
    built. Anything else, including errors that are already DSL errors, maps to
    ``None`` and propagates unchanged.

    :param e: The exception that escaped the wrapped op function.
    :param api: Name of the DSL API whose wrapper caught ``e``.
    :return: The error to raise from ``e``, or ``None`` to re-raise ``e``.
    """
    if isinstance(e, DSLBaseError):
        return None
    detail = " ".join(str(e).split())
    err_cls: type[DSLUserCodeError]
    if isinstance(e, ir.MLIRError):
        err_cls = _DSLUserCodeMLIRError
    elif (
        isinstance(e, ValueError)
        and detail.startswith("Operand ")
        and " of operation " in detail
    ):
        err_cls = DSLUserCodeValueError
    elif type(e) is RuntimeError and detail == "std::bad_cast":
        err_cls = DSLUserCodeRuntimeError
    else:
        return None
    return err_cls(DiagId.ARG_REJECTED_BY_OP, api=api, cause=e, detail=detail)


# Cache of ``inspect.getsourcefile(frame) or inspect.getfile(frame)`` keyed on
# ``co_filename``.  The resolution only depends on the code object's filename
# (suffix checks + an ``os.path.exists`` probe), so one lookup per distinct
# source file is enough for the per-op hot path below.
_SOURCE_FILE_CACHE: dict[str, str] = {}

# Python >= 3.11: code objects carry a position table and
# ``inspect.Traceback`` accepts ``positions=``.  On older interpreters
# ``_fast_frameinfo`` falls back to plain ``inspect.getframeinfo``.
_HAS_CO_POSITIONS: bool = hasattr(types.CodeType, "co_positions")

# The 3.11+ APIs used below (``CodeType.co_positions``, ``dis.Positions``,
# ``inspect.Traceback``'s ``positions=`` field) are absent from the stubs at
# the project's mypy floor (``python_version = "3.10"``), so resolve them
# dynamically.  All uses are behind the ``_HAS_CO_POSITIONS`` run-time gate.
_CO_POSITIONS: Any = getattr(types.CodeType, "co_positions", None)
_DIS_POSITIONS: Any = getattr(dis, "Positions", None)
_TRACEBACK_WITH_POSITIONS: Any = inspect.Traceback


def _fast_frameinfo(frame: types.FrameType) -> inspect.Traceback:
    """Build the same ``inspect.Traceback`` as ``inspect.getframeinfo(frame)``
    without its per-call cost.

    ``getframeinfo`` re-resolves the source file (2x ``os.stat``) and runs
    ``inspect.findsource`` — module lookup plus a regex walk over the source —
    on EVERY call; profiling shows it as the single largest trace-time cost of
    a kernel compile (it runs once per built MLIR op).  The same fields come
    straight from the frame: positions from the code object's position table,
    the context line from ``linecache``, and the filename from a per-file
    cache.  (Sole divergence: for a ``lineno`` beyond the real file length —
    stale source on disk — ``getframeinfo`` returns an arbitrary clamped line
    while this returns no context and callers fall back to the function name.)
    """
    if not _HAS_CO_POSITIONS:
        return inspect.getframeinfo(frame)
    code = frame.f_code
    lasti = frame.f_lasti
    if lasti >= 0:
        positions = next(itertools.islice(_CO_POSITIONS(code), lasti // 2, None))
    else:
        positions = (None, None, None, None)
    if positions[0] is None:
        positions = (frame.f_lineno,) + tuple(positions[1:])
    lineno = positions[0]

    co_filename = code.co_filename
    filename = _SOURCE_FILE_CACHE.get(co_filename)
    if filename is None:
        filename = inspect.getsourcefile(frame) or inspect.getfile(frame)
        _SOURCE_FILE_CACHE[co_filename] = filename

    line = linecache.getline(filename, lineno, frame.f_globals)
    code_context = [line] if line else None
    return _TRACEBACK_WITH_POSITIONS(
        filename,
        lineno,
        code.co_name,
        code_context,
        0 if code_context else None,
        positions=_DIS_POSITIONS(*positions),
    )


def _get_caller_frame_info() -> inspect.Traceback | None:
    """Return lightweight frame info for the DSL user callsite.

    This helper is only called when source-location tracking is enabled. It
    skips the wrapper frame, applies framework-frame filtering, and avoids
    `inspect.getframeinfo()`'s source-context lookup on the hot path.
    """
    cur_frame = inspect.currentframe()
    if cur_frame is None:
        return None
    wrapper_frame = cur_frame.f_back
    start_frame = wrapper_frame.f_back if wrapper_frame is not None else None
    frame = _find_user_frame(start_frame)
    del cur_frame
    if frame is None:
        return None
    return _fast_frameinfo(frame)


def _get_location_from_frame_info(frameInfo: inspect.Traceback) -> ir.Location:
    """Build an MLIR location from captured Python frame information.

    The file/line/column portion becomes the child `FileLineColLoc`, while the
    name location carries either the source snippet, when available, or the
    Python function name.
    """
    # In Python < 3.11, getframeinfo returns a NamedTuple without positions.
    if not hasattr(frameInfo, "positions"):
        file_loc = ir.Location.file(
            frameInfo.filename,
            frameInfo.lineno,
            0,
        )
    else:
        file_loc = ir.Location.file(
            frameInfo.filename,
            frameInfo.positions.lineno,  # type: ignore[attr-defined]
            frameInfo.positions.col_offset or 0,  # type: ignore[attr-defined]
        )
    return ir.Location.name(
        (
            "".join([c.strip() for c in frameInfo.code_context])
            if frameInfo.code_context
            else frameInfo.function
        ),
        childLoc=file_loc,
    )


def _declares_none_return(func: Callable[..., Any]) -> bool:
    """Return whether ``func`` is annotated ``-> None``.

    Accepts both the evaluated ``None`` and the ``"None"`` string that
    ``from __future__ import annotations`` leaves in place. ``dsl_user_op``
    calls it when a wrapper returns an ``OpView`` instead of caching the
    answer in the wrapper's closure: PyIR cannot re-check a scalar closure
    cell of a wrapper called from traced code, and one such cell makes the
    compiled function refuse its first call (``SPEC_UNVERIFIABLE_REENTRY``).
    """
    return_annotation = inspect.get_annotations(func).get(
        "return", inspect.Parameter.empty
    )
    return return_annotation is None or return_annotation == "None"


def dsl_user_op(opFunc: Callable[..., Any]) -> Callable[..., Any]:
    """Decorator for user-facing DSL op wrappers.

    Responsibilities:

    1. Attach source locations when line info / diagnostics are enabled so
       diagnostics and IR dumps point back at the user's Python call site.
    2. Run trace-time MLIR verification on each newly-built op so verifier
       errors surface at the call site rather than at module-verify time.
    3. Re-raise the raw errors the MLIR op builders use to reject bad
       arguments as ``DSLUserCodeError`` subclasses that name the API and keep
       the builtin base of the original (see ``_translate_binding_error``).
    4. Keep statement APIs free of IR handles: when a wrapper annotated
       ``-> None`` returns the ``OpView`` it built, the caller receives
       ``None``, so the op stays an implementation detail of the API.

    Verification snapshots ``InsertionPoint.current.block`` and its last
    operation before invoking ``opFunc``, then calls ``OpView.verify()``
    on the ops that ``opFunc`` left after that anchor. ``verify()``
    recurses through regions, so a wrapper that opens an ``scf.if``
    covers the body via the outer op.

    The anchor, rather than the op count alone, is what bounds the walk:
    a wrapper may also insert *before* the anchor -- an op emitted back
    at a recorded construction point -- and the ops already in the block
    can include one still under construction, such as the enclosing
    ``scf.if`` whose body the caller has not filled in yet. Those are
    left to module-verify time. A value-producing wrapper whose op
    landed before the anchor is still reached through the owner of the
    value it returned.

    Disabled by default; enable with the ``CUTE_DSL_VERIFY_TRACE`` env
    var (``1`` / ``true`` / ``on`` / ``yes``) or ``set_verify_trace(True)``.
    One long-standing exception is not under that toggle: a wrapper that
    returns an ``OpView`` directly is always verified. Statement wrappers
    rely on it -- they return the op they built so its verifier errors
    surface at the call site in default mode, and responsibility 4 then
    hands ``None`` back to the caller.

    :param opFunc: The user-facing API function.
    :type opFunc: Callable
    :return: The wrapped user-facing API function.
    :rtype: Callable
    """

    @wraps(opFunc)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        # PyIR: auto-load from pyir.ref for any arg carrying an accessible
        # ``_mutable_ref`` (see pyir_runtime._pyir_auto_load_arg).
        args = tuple(map(_pyir_auto_load_arg, args))
        # Value-carrying kwargs escape loops like positional args; auto-load them
        # so a post-loop kwarg use reads from the ref, not a stale in-loop SSA.
        kwargs = {k: _pyir_auto_load_arg(v) for k, v in kwargs.items()}
        # Pop loc= from kwargs so callers that still pass it don't break.
        # The wrapper replaces it only when source-location tracking is enabled.
        loc: Any = kwargs.pop("loc", None)
        frameInfo = None
        verifier_error = False

        if loc is None and ir.Context.current is not None and _ENABLE_FRAME_FILTERING:
            frameInfo = _get_caller_frame_info()
            try:
                if frameInfo is not None:
                    loc = _get_location_from_frame_info(frameInfo)
            except RuntimeError:
                # No MLIR context available (e.g. validation-only call
                # outside a kernel).  Proceed with loc=None so that the
                # wrapped function's own validation can still fire.
                pass
        # Keep ContextVar out of the wrapper's dependencies for semantic hashing.
        loc = _apply_loc_transforms(loc)

        # Snapshot the current insertion block so we can verify newly-built
        # ops after opFunc returns. The dialect Python bindings strip
        # `.result` for value-producing ops before our wrapper sees the
        # return value, so we cannot rely on the return value alone —
        # block-diff sees every op regardless.
        snap_block: Any = None
        if _VERIFY_TRACE_ENABLED is None:
            _verify_trace_enabled()
        # __init__ wrappers either wrap an existing ir.Value (no new
        # ops, e.g. with_signedness) or build a trivial arith constant
        # that always verifies. They're also called *very* frequently
        # from hot paths like signedness coercion, so we skip the
        # block-diff verify for them —
        # materializing `block.operations` on every call would be O(N)
        # per call and turn kernel build into O(N^2).
        if _VERIFY_TRACE_ENABLED and getattr(opFunc, "__name__", "") != "__init__":
            snap_tail: Any = None
            try:
                snap_block = ir.InsertionPoint.current.block
                snap_ops = snap_block.operations
                snap_n_ops = len(snap_ops)
                # Anchor the diff on the tail op rather than on the count: the
                # ops opFunc appends land after it, whatever it inserts higher
                # up the block does not (see `_verify_new_block_ops`). Resolve
                # the operation here, while the handle is still known good.
                if snap_n_ops:
                    tail = snap_ops[-1]
                    snap_tail = getattr(tail, "operation", tail)
            except ValueError:
                # No active InsertionPoint (e.g. validation-only call
                # outside a kernel) — skip trace-time verification.
                snap_block = None

        try:
            res_or_list = opFunc(*args, **kwargs, loc=loc)
            verifier_error = True
            # Trace-time verification: walk every op appended to the
            # snapshotted block during opFunc. OpView.verify() is
            # recursive — for ops with regions (scf.if, scf.for, ...) it
            # verifies the body too, so we don't need to descend.
            #
            # Skip when opFunc returns a context manager (e.g. elect_one,
            # if_generate): the op's body is filled by the surrounding
            # `with` block after opFunc returns, so verifying here would
            # see an empty region and fail. The body still gets covered
            # at module-verify time.
            # Fast path: if opFunc didn't append anything to the block,
            # skip materializing the operation list — it's O(N) in the
            # block size and adds up across thousands of wrapper calls.
            tail_diff_ran = False
            if snap_block is not None:
                is_cm = hasattr(res_or_list, "__enter__") and hasattr(
                    res_or_list, "__exit__"
                )
                tail_diff_ran = not is_cm and len(snap_block.operations) > snap_n_ops
                verified_tail = None
                if tail_diff_ran:
                    verified_tail = _verify_new_block_ops(
                        snap_block, snap_n_ops, snap_tail
                    )
            # Defensive fallback: cover the rare wrapper that returns an
            # OpView directly. Block-diff already verified it if it was
            # appended to snap_block, so this is a no-op in the common
            # case; the branch only matters for cross-block builders or
            # calls with no active insertion point.
            has_verifier = hasattr(res_or_list, "verify")
            if has_verifier:
                res_or_list.verify()
            elif tail_diff_ran and verified_tail is None:
                # A value-producing wrapper whose op landed before snap_tail
                # -- a deferred op emitted back at a recorded construction
                # point -- sits outside the block diff, so reach it through
                # the value it returned. The two guards are what keep this to
                # the wrapper's own op: the block grew, yet nothing landed
                # after the anchor, so whatever was built went in higher up.
                # Without them a wrapper that returns one of its inputs
                # unchanged (cute.assume, slice_, dice, align, broadcast_to)
                # would verify a foreign op while a nested call was what grew
                # the block. Never verify the anchor itself either -- an op
                # that was already the block's tail at snapshot may be under
                # construction, which is the failure this diff exists to
                # avoid.
                owner = getattr(res_or_list, "owner", None)
                if owner is not None and hasattr(owner, "verify"):
                    operation = getattr(owner, "operation", owner)
                    if operation != snap_tail:
                        owner.verify()

        except DSLOperationBuildError as e:
            # Nested DSLOperationError
            raise DSLOperationBuildError(
                message=e.message, cause=e, frameInfo=frameInfo
            )
        except Exception as e:
            # Check if it's a decorator config error first
            func_name = getattr(opFunc, "__name__", str(opFunc))
            if "unexpected keyword argument 'loc'" in str(e):
                raise DSLRuntimeError(
                    f"Function '{func_name}' decorated with @dsl_user_op does not accept the required 'loc' parameter.",
                    suggestion=[
                        f"1. Add 'loc=None' as a keyword-only parameter to {func_name}:",
                        f"  def {func_name}(..., *, loc=None):",
                        "",
                        "2. Remove the @dsl_user_op decorator if location tracking is not needed",
                    ],
                    cause=e,
                ) from e
            if verifier_error:
                raise DSLOperationBuildError(
                    message="Operation verification failed",
                    cause=e,
                    frameInfo=frameInfo,
                    auto_translate=False,
                )

            # A missing-context failure means the op was invoked outside any
            # @cute.jit/@cute.kernel compilation (e.g. at Python module
            # level) — an author mistake, not a DSL bug. Calls that succeed
            # without a context (static Numeric arithmetic) never reach here.
            # The raised diagnostic stays catchable as the raw type it
            # replaces: trace-time helpers probe for a missing context with
            # ``except RuntimeError:`` around ops like make_tmem_ptr.
            if ir.Context.current is None and _is_missing_context_error(e):
                err_cls = (
                    DSLUserCodeTypeError
                    if isinstance(e, TypeError)
                    else DSLUserCodeRuntimeError
                )
                raise err_cls(DiagId.CALL_OUTSIDE_JIT, api=func_name, cause=e) from e

            translated = _translate_binding_error(e, func_name)
            if translated is not None:
                raise translated from e
            raise e

        # OpView always exposes verify(). Reuse that check so ordinary scalar
        # and tensor results avoid another native type test. Keep annotation
        # lookup lazy to preserve the wrapper's PyIR-compatible closure.
        if (
            has_verifier
            and isinstance(res_or_list, ir.OpView)
            and _declares_none_return(opFunc)
        ):
            return None
        return res_or_list

    # F-COVER: a DSL op wrapper runs natively inside a trace by design; the
    # decorator declares that so entry attestation never mistakes it for an
    # un-instrumented user function.
    wrapper.__pyir_native__ = True  # type: ignore[attr-defined]
    return wrapper
