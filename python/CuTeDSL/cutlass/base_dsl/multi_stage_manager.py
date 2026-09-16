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
Multi-stage manager — tracks staged control-flow depth and enforces
the phase rules of the two-stage language.

"""

from collections.abc import Iterator
from contextlib import contextmanager
from typing import Any

# ---------------------------------------------------------------------------
# Staged CF depth counter
# ---------------------------------------------------------------------------

_staged_cf_depth: int = 0
_jit_depth_baseline_stack: list[int] = []


def enter_staged_cf() -> None:
    """Called when entering a staged CF region (for/if/while).

    Increments the depth counter so ``is_inside_staged_cf()`` returns True.
    Ref placement is handled by ``_create_ref()`` in ``pyir_runtime.py``
    which walks up to the function entry block -- no parent op tracking needed.
    """
    global _staged_cf_depth
    _staged_cf_depth += 1


def exit_staged_cf() -> None:
    """Called when exiting a staged CF region."""
    global _staged_cf_depth
    _staged_cf_depth -= 1


def is_inside_staged_cf() -> bool:
    """Return True if currently inside staged control flow."""
    return _staged_cf_depth > 0


# ``range_constexpr`` / ``const_expr`` if / ``const_expr`` while resolve at
# trace time (the loop unrolls or the branch is selected in Python), so a
# Python-side ``.append`` / variable mutation directly inside their body is
# realized deterministically -- it is NOT a silently-lost loop-carried
# mutation.  The M->M / container-mutation guards therefore opt out when the
# INNERMOST control-flow construct governing the mutation is a constexpr
# construct.
#
# "Innermost" is the key: a constexpr scope nested inside dynamic staged CF
# still opts out (the mutation is constexpr-governed), but a *dynamic* loop /
# if nested inside a constexpr scope must NOT opt out (the mutation is
# governed by the dynamic construct and is silently lost).  We capture this
# by recording ``_staged_cf_depth`` at each constexpr-scope entry: the scope
# is the innermost CF only while no dynamic CF has been entered since, i.e.
# the current ``_staged_cf_depth`` still equals the snapshot on top of the
# stack.
_constexpr_scope_stack: list[int] = []


def enter_constexpr_loop() -> None:
    """Enter a constexpr scope (``range_constexpr`` body or a
    ``const_expr`` if / while branch).  Records the current staged-CF
    depth so ``is_inside_constexpr_loop()`` can tell whether a later
    mutation is still governed by this constexpr scope or by a dynamic
    construct opened underneath it.  Use ``constexpr_loop_scope()``
    instead of raw enter/exit pairs where a ``with`` block is possible;
    the AST preprocessor instead emits a generated ``try/finally``.
    """
    _constexpr_scope_stack.append(_staged_cf_depth)


def exit_constexpr_loop() -> None:
    """Leave the innermost constexpr scope."""
    if _constexpr_scope_stack:
        _constexpr_scope_stack.pop()


def is_inside_constexpr_loop() -> bool:
    """True if the INNERMOST enclosing control-flow construct is a
    constexpr scope -- i.e. a constexpr scope is open and no dynamic
    staged CF has been entered since it opened.
    """
    return (
        bool(_constexpr_scope_stack) and _staged_cf_depth == _constexpr_scope_stack[-1]
    )


def _reset_constexpr_scope() -> None:
    """Clear constexpr-scope state.  Backstop for the AST-injected
    ``try/finally`` bracketing: cleared at outermost trace exit so an
    unbalanced enter (e.g. from an aborted trace) cannot leak into and
    silently disable the guards for the next trace.
    """
    _constexpr_scope_stack.clear()


@contextmanager
def constexpr_loop_scope() -> Iterator[None]:
    """Bracket a Python-side constexpr unroll so the M->M and container-
    mutation guards know the body is constexpr-governed (not dynamically
    loop-carried).
    """
    enter_constexpr_loop()
    try:
        yield
    finally:
        exit_constexpr_loop()


def get_staged_cf_depth() -> int:
    """Return the current staged-CF nesting depth.

    Counts runtime CF regions (``scf.if`` / ``scf.for`` / ``scf.while``)
    entered via ``_scf_execute_pyir``.  Trace-time ``range_constexpr``
    unrolls do NOT bump this counter, so a strictly greater depth between
    a slot's first-def and a later reassignment means the reassignment is
    inside a NESTED RUNTIME loop/if that must thread the value as an
    iter_arg / scf result rather than constexpr-fold it.
    """
    return _staged_cf_depth


@contextmanager
def _jit_scope() -> Iterator[None]:
    """Track the staged-CF depth baseline for a nested ``@cute.jit`` call.

    On exit from the OUTERMOST trace, clear the D1 meta-value promotion
    state so a second invocation of the same function in the same process
    sees a fresh slate (mixing.py acceptance criterion 3).
    """
    _jit_depth_baseline_stack.append(_staged_cf_depth)
    try:
        yield
    finally:
        _jit_depth_baseline_stack.pop()
        if not _jit_depth_baseline_stack:
            # Outermost trace just exited -- clear D1 trace state and
            # any constexpr-scope state left over from an unbalanced trace.
            _reset_constexpr_scope()
            try:
                from .pyir_runtime import _exit_function_trace

                _exit_function_trace()
            except ImportError:
                pass  # PyIR runtime unavailable -- nothing to clean.


def is_inside_locally_staged_cf() -> bool:
    """Return True if the current ``@cute.jit`` body opened staged CF."""
    if not _jit_depth_baseline_stack:
        return _staged_cf_depth > 0
    return _staged_cf_depth > _jit_depth_baseline_stack[-1]


# ---------------------------------------------------------------------------
# Isolation boundary for IsolatedFromAbove regions (kernel bodies)
# ---------------------------------------------------------------------------


@contextmanager
def isolated_region() -> Iterator[None]:
    """Save and reset staged-CF depth for IsolatedFromAbove regions.

    When a kernel body compiles inside host-level staged CF, the depth
    must reset to 0 so the kernel doesn't inherit the host's CF state.
    On exit, the host's depth is restored.

    Usage::

        with isolated_region():
            # kernel body compilation — depth is 0 here
            ...
        # depth restored to pre-kernel value
    """
    global _staged_cf_depth
    saved = _staged_cf_depth
    _staged_cf_depth = 0
    try:
        yield
    finally:
        _staged_cf_depth = saved


def _is_staged_value(val: object) -> bool:
    """Return True if *val* is a staged (S) value (DSL type with ir_value).

    Bare Python scalars (int, float, bool, str, None) are Meta (M).
    DSL types (Numeric, Pointer, Array, etc.) are Staged (S).
    """
    if val is None or isinstance(val, (int, float, bool, str, bytes, type)):
        return False
    # Lazy import to avoid circular dependency: pyir_runtime imports from
    # this module.
    try:
        from .pyir_runtime import _WatchedM
    except ImportError:
        _WatchedM = None  # type: ignore[misc,assignment]
    if _WatchedM is not None and isinstance(val, _WatchedM):
        return False
    return hasattr(val, "ir_value") and callable(getattr(val, "ir_value"))


def _get_ir_type(val: Any) -> Any:
    """Return the MLIR type of a staged value, or None."""
    try:
        iv = val.ir_value() if callable(getattr(val, "ir_value", None)) else None
        return iv.type if iv is not None else None
    except Exception:
        return None


def _user_type_name(value: Any) -> str:
    """A user-facing type name for *value*.

    Reports the primitive the author actually wrote (``int``/``bool``/``float``)
    rather than any internal wrapper subclass (e.g. the meta-value-table wrapper),
    which must never appear in a user-facing message.
    """
    if isinstance(value, bool):
        return "bool"
    if isinstance(value, int):
        return "int"
    if isinstance(value, float):
        return "float"
    return type(value).__name__


# ---------------------------------------------------------------------------
# Phase-rule enforcement (Rule 2, Rule 4)
# See ``LanguageSemantic.md``, section "Phase Rules".
# ---------------------------------------------------------------------------


def assign_meta_staged_check(
    target_name: str,
    old_value: Any,
    new_value: Any,
    filename: str,
    lineno: int,
) -> Any:
    """Runtime check for assignments inside staged control flow.

    Called by AST-inserted code at every ``=`` and ``+=`` inside staged CF.

    Enforces:
    - **Rule 2** (mutate only stage): (M) values cannot be mutated
      inside staged CF.
    - **Rule 4** (type stability): (S) type must not change at a
      join point.

    Returns ``None`` normally, or a coerced (S) value when a Python
    scalar (int/float/bool) is assigned to a matching staged variable.
    """
    from .common import DSLUserCodeError  # lazy to avoid circular import
    from .diagnostics import DiagId  # lazy to avoid circular import

    if not is_inside_staged_cf():
        return None  # Outside CF — no checks needed

    old_is_staged = _is_staged_value(old_value)
    new_is_staged = _is_staged_value(new_value)

    # Rule 2: (M) mutation inside staged CF
    if old_is_staged and not new_is_staged:
        # Auto-coerce: Python bool/int/float → matching DSL type
        dsl_type = type(old_value)
        if isinstance(new_value, (bool, int, float)) and dsl_type.isinstance(new_value):
            try:
                return dsl_type(new_value)
            except (TypeError, ValueError):
                pass

        raise DSLUserCodeError(
            DiagId.PHASE_ASSIGN_PYTHON_TO_TRACKED,
            filename=filename,
            lineno=lineno,
            var=target_name,
        )

    if not old_is_staged and not new_is_staged:
        if target_name == "self.dummy":
            return None

        # D1 (META_VALUE_TABLE_DESIGN): when *old_value* is a ``_WatchedM``
        # wrapper, the slot is being tracked by the meta-value table.
        # ``pyir_assign`` (below in pyir_runtime.py) handles retroactive
        # promotion -- it creates a ``pyir.ref`` at function entry and
        # rewrites baked constants via ``replaceAllUsesWith``.  Allow the
        # mutation here; D1 enforces correctness, including any type
        # mismatch which surfaces as an MLIR verification error.
        try:
            from .pyir_runtime import _WatchedM

            if isinstance(old_value, _WatchedM) or isinstance(new_value, _WatchedM):
                return None
        except ImportError:
            pass

        # Mp→Mp: meta-primitive mutation inside staged CF.
        # When AUTO_M2S is enabled, auto-promote to staged so the
        # value becomes a loop iter_arg / CF result.
        # When disabled, fall through to error (user must use DSL types).
        if type(old_value) is type(new_value) and isinstance(
            old_value, (bool, int, float)
        ):
            from .common import is_auto_m2s_enabled

            if is_auto_m2s_enabled():
                try:
                    from .typing import as_numeric

                    return as_numeric(new_value)
                except Exception:
                    pass  # fall through to error

        same_type_compound = (
            type(old_value) is type(new_value)
            and old_value is not None
            and not isinstance(old_value, (int, float, bool, str, bytes))
        )

        # Check TOLERATE_M2M flag first — useful for debugging.
        # Default True. Set CUTE_DSL_TOLERATE_M2M=False to catch M→M
        # replacement errors even when auto-decomposition would handle them.
        from .common import get_current_env_manager

        tolerate_m2m = True
        env_manager = get_current_env_manager()
        if env_manager is not None:
            tolerate_m2m = getattr(env_manager, "tolerate_m2m", True)

        # PyIR M->M auto-decomposition: compound objects whose staged
        # leaf fields are all ref-compatible can be decomposed into
        # per-field pyir_assign calls by pyir_assign().
        # Only let them through if TOLERATE_M2M is True (default).
        if tolerate_m2m and same_type_compound:
            try:
                from .pyir_runtime import _has_decomposable_staged_fields

                if _has_decomposable_staged_fields(old_value):
                    return None
            except ImportError:
                pass  # pyir_runtime not available (non-PyIR build)

        # Same-type M->M reassignment — tolerate if flag is set.
        if tolerate_m2m and same_type_compound:
            return None
        raise DSLUserCodeError(
            DiagId.PHASE_MUTATE_PYTHON,
            filename=filename,
            lineno=lineno,
            var=target_name,
        )

    # Rule 4: Type stability at join points
    if old_is_staged and new_is_staged:
        old_type = type(old_value)
        new_type = type(new_value)
        if old_type != new_type:
            # If MLIR types match, coerce to the old DSL type.
            # This handles cases like Int32 vs ArithValue — both carry
            # i32 but differ at the Python class level (e.g. value
            # caster wraps llvm.load results as ArithValue).
            old_ir = _get_ir_type(old_value)
            new_ir = _get_ir_type(new_value)
            if old_ir is not None and new_ir is not None and old_ir == new_ir:
                try:
                    return old_type(new_value.ir_value())
                except (TypeError, ValueError, AttributeError):
                    pass  # Fall through to error

            raise DSLUserCodeError(
                DiagId.TYPE_UNSTABLE_JOIN,
                filename=filename,
                lineno=lineno,
                var=target_name,
                old_type=old_type.__name__,
                new_type=new_type.__name__,
            )

    # 4th case: M->S promotion (old is meta, new is staged)
    if not old_is_staged and new_is_staged:
        from .common import get_current_env_manager

        auto_m2s = False
        env_manager = get_current_env_manager()
        if env_manager is not None:
            auto_m2s = getattr(env_manager, "auto_m2s", False)

        if auto_m2s:
            import warnings

            warnings.warn(
                f"Implicit Meta-to-Staged promotion of `{target_name}` "
                f"(from {type(old_value).__name__} to "
                f"{type(new_value).__name__}) is deprecated. "
                f"Initialize as: {target_name} = "
                f"cute.{type(new_value).__name__}({old_value!r})\n"
                f"  at {filename}:{lineno}",
                DeprecationWarning,
                stacklevel=3,
            )
            return None  # Allow -- pyir_assign handles promotion

        raise DSLUserCodeError(
            DiagId.PHASE_PYTHON_THEN_TRACKED,
            filename=filename,
            lineno=lineno,
            var=target_name,
            old_type=_user_type_name(old_value),
            old_value=repr(old_value),
        )

    return None
