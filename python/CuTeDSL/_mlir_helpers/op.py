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

import inspect
import importlib.util
import os
import types
import warnings
from functools import wraps, lru_cache
from typing import Any, Callable, TYPE_CHECKING

from .._mlir import ir
from ..base_dsl.common import DSLRuntimeError, DSLOperationBuildError
from ..base_dsl.utils.logger import log
from ..base_dsl.utils.stacktrace import walk_to_top_module

# The DSL package root is empty by default.
_DSL_PACKAGE_ROOT: str | None = ""
_DSL_PACKAGE_ROOTS: tuple[str, ...] | None = None

# Whether location tracking is enabled.
_ENABLE_FRAME_FILTERING: bool = False

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


def _verify_new_block_ops(snap_block: Any, snap_n_ops: int) -> None:
    """Verify ops appended to ``snap_block`` after ``snap_n_ops``."""
    ops = snap_block.operations
    new_count = len(ops) - snap_n_ops
    if new_count <= 0:
        return

    # OperationList materialization is O(block size).  Most DSL wrappers append
    # one op, so walk the new tail by negative index instead of list-slicing the
    # whole block on every wrapper call.
    for offset in range(new_count, 0, -1):
        ops[-offset].verify()


def _set_enable_frame_filtering(enable: bool) -> None:
    """Set whether location tracking is enabled."""
    global _ENABLE_FRAME_FILTERING
    _ENABLE_FRAME_FILTERING = enable


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
    framework_prefixes = _FRAMEWORK_MODULE_PREFIXES

    return any(
        module_name == prefix or module_name.startswith(prefix + ".")
        for prefix in framework_prefixes
    )


def _is_framework_stack_frame(frame: types.FrameType) -> bool:
    module_name = frame.f_globals.get("__name__", "")
    return _is_framework_module(module_name) or _is_framework_frame(
        frame.f_code.co_filename
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


def dsl_user_op(opFunc: Callable[..., Any]) -> Callable[..., Any]:
    """Decorator for user-facing DSL op wrappers.

    Responsibilities:

    1. Attach a source-location to every MLIR op built by ``opFunc`` so that
       diagnostics and IR dumps point back at the user's Python call site.
    2. Run trace-time MLIR verification on each newly-built op so verifier
       errors surface at the call site rather than at module-verify time.

    Verification snapshots ``InsertionPoint.current.block`` and its op
    count before invoking ``opFunc``, then calls ``OpView.verify()`` on
    every op appended during the call. ``verify()`` recurses through
    regions, so a wrapper that opens an ``scf.if`` covers the body via
    the outer op.

    Disabled by default; enable with the ``CUTE_DSL_VERIFY_TRACE`` env
    var (``1`` / ``true`` / ``on`` / ``yes``) or ``set_verify_trace(True)``.

    :param opFunc: The user-facing API function.
    :type opFunc: Callable
    :return: The wrapped user-facing API function.
    :rtype: Callable
    """

    @wraps(opFunc)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        # Pop loc= from kwargs so callers that still pass it don't break.
        # We no longer forward it — LOC_TRACEBACKS captures full stacks automatically.
        loc: Any = kwargs.pop("loc", None)
        frameInfo = None
        verifier_error = False

        if loc is None and ir.Context.current is not None:
            cur_frame = inspect.currentframe()
            assert cur_frame is not None
            frame = _find_user_frame(cur_frame.f_back)
            del cur_frame  # break self-ref
            assert frame is not None
            frameInfo = inspect.getframeinfo(frame)
            try:
                # In Python < 3.11, getframeinfo returns a NamedTuple without positions
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
                loc = ir.Location.name(
                    (
                        "".join([c.strip() for c in frameInfo.code_context])
                        if frameInfo.code_context
                        else frameInfo.function
                    ),
                    childLoc=file_loc,
                )
            except RuntimeError:
                # No MLIR context available (e.g. validation-only call
                # outside a kernel).  Proceed with loc=None so that the
                # wrapped function's own validation can still fire.
                pass

        is_init = False
        # Snapshot the current insertion block so we can verify newly-built
        # ops after opFunc returns. The dialect Python bindings strip
        # `.result` for value-producing ops before our wrapper sees the
        # return value, so we cannot rely on the return value alone —
        # block-diff sees every op regardless.
        snap_block: Any = None
        snap_n_ops: int = 0
        if _verify_trace_enabled() and not is_init:
            try:
                snap_block = ir.InsertionPoint.current.block
                snap_n_ops = len(snap_block.operations)
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
            is_cm = hasattr(res_or_list, "__enter__") and hasattr(
                res_or_list, "__exit__"
            )
            # Fast path: if opFunc didn't append anything to the block,
            # skip materializing the operation list — it's O(N) in the
            # block size and adds up across thousands of wrapper calls.
            if (
                snap_block is not None
                and not is_cm
                and len(snap_block.operations) > snap_n_ops
            ):
                _verify_new_block_ops(snap_block, snap_n_ops)
            # Defensive fallback: cover the rare wrapper that returns an
            # OpView directly. Block-diff already verified it if it was
            # appended to snap_block, so this is a no-op in the common
            # case; the branch only matters for cross-block builders or
            # calls with no active insertion point.
            if hasattr(res_or_list, "verify"):
                res_or_list.verify()

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

            raise e

        return res_or_list

    return wrapper


def _get_call_arg_names(frameInfo: Any) -> dict[str | int, str]:
    """Extract argument names from the source line (best-effort)."""
    if frameInfo is None or not frameInfo.code_context:
        return {}
    import ast as _ast

    line = "".join(frameInfo.code_context).strip()
    call_node: _ast.expr | None = None
    try:
        expr_tree = _ast.parse(line, mode="eval")
        call_node = expr_tree.body
    except SyntaxError:
        try:
            mod_tree = _ast.parse(line, mode="exec")
            if not mod_tree.body:
                return {}
            stmt = mod_tree.body[0]
            if isinstance(stmt, _ast.Expr):
                call_node = stmt.value
            elif isinstance(stmt, _ast.Assign):
                call_node = stmt.value
            elif isinstance(stmt, _ast.Return):
                call_node = stmt.value
            elif isinstance(stmt, _ast.AugAssign):
                call_node = stmt.value
            else:
                return {}
        except SyntaxError:
            return {}

    # Unwrap chained calls: ``type(self)(self, signed)`` parses as a Call
    # whose func is another Call.  We want the outermost (rightmost) call.
    if not isinstance(call_node, _ast.Call):
        return {}
    names: dict[str | int, str] = {}
    for i, arg in enumerate(call_node.args):
        names[i] = _ast.unparse(arg)
    for kw in call_node.keywords:
        if kw.arg:
            names[kw.arg] = _ast.unparse(kw.value)
    return names


