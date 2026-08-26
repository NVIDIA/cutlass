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


"""PyIR runtime -- corewalk layer; see facade for the public surface."""

from .pyir_core import *  # noqa: F401,F403  (re-export lower layers up the chain)

# -- BEGIN explicit imports for the type checker (do not edit the list by hand;
# it mirrors names the chain re-exports at runtime via the wildcard + dynamic
# ``__all__`` above, which a static type checker cannot evaluate -- so every
# name is also imported explicitly from the layer that DEFINES it). Purely
# additive: the wildcard import stays the runtime source of truth.
from .pyir_state import (  # noqa: F401
    Any,
    _is_staged_value,
    _slot_refs,
    ir,
    pyir,
)
from .pyir_core import (  # noqa: F401
    _WatchedM,
    _can_create_ref,
    _check_all_fields_decomposable,
    _create_ref,
    _flatten_tuple,
    _get_instance_attrs,
    _load_as_dsl,
)
# -- END explicit imports for the type checker


def _pyir_auto_load_arg(arg: Any) -> Any:
    """If *arg* carries a ``_mutable_ref`` with an accessible ref, emit
    ``pyir.load`` and return a fresh value that dominates the current
    insertion point.  Otherwise return *arg* unchanged.

    Called by ``@dsl_user_op`` on every positional argument so that
    post-loop uses of pyir-tracked variables automatically get a load
    from the ref instead of using a stale SSA value from inside the
    loop body.

    Optimization: skip the auto-load when *arg* was itself produced by
    the most recent ``MutableValue.load()`` (same ``_load_version``)
    AND its underlying ``ir.Value`` still dominates the current
    insertion point.  This eliminates the redundant load that would
    otherwise follow an AST-inserted ``pyir_read``.  A ``store()``
    bumps ``_load_version`` and invalidates the cache.

    D1: when *arg* is a ``_WatchedM`` wrapper:
      * If the slot has been promoted to ``pyir.ref`` (an entry in
        ``_slot_refs``), emit ``pyir.load`` and wrap in the matching
        DSL Numeric.
      * Otherwise return the wrapper unchanged.  ``_WatchedInt`` /
        ``_WatchedBool`` / ``_WatchedFloat`` subclass ``int`` / ``float``
        so consumers that use the arg as a Python primitive (e.g.
        ``ir.VectorType.get([vec_size], ...)`` reading ``vec_size`` as
        the shape, ``isinstance(x, int)`` branches, ``const_expr``)
        work transparently.  Consumers that need an SSA value
        (Numeric ``__init__``, ``arith.const``, ``cute.printf`` arg
        coercion) already invoke ``.ir_value()`` on the wrapper, which
        performs the bake AND records into ``_meta_uses`` so D1's
        retroactive rewrite still fires when the slot later mutates.
    """
    if isinstance(arg, _WatchedM):
        slot = arg._slot_key
        if slot is not None and slot in _slot_refs:
            return _load_as_dsl(_slot_refs[slot], arg.python_value)
        # Unpromoted: return the bare wrapper so the consumer decides
        # whether to bake (via ``.ir_value()``) or use as a Python
        # primitive (via the int/float subclass nature of ``_WatchedM``).
        return arg

    # Tuple recursion: tuples have no ``_mutable_ref`` themselves but
    # their staged leaves often do.  Mirrors ``pyir_read``'s existing
    # tuple recursion so ``@dsl_user_op`` boundaries like
    # ``Vector.from_elements((rm, rm, ...))`` auto-load each element.
    if isinstance(arg, tuple):
        return tuple(_pyir_auto_load_arg(e) for e in arg)

    mv = getattr(arg, "_mutable_ref", None)

    if mv is not None and mv.ref is not None:
        if mv._is_ref_accessible():
            # Dedup: arg is the latest load AND still dominates current IP.
            cached_version = getattr(arg, "_pyir_load_version", None)
            if (
                cached_version is not None
                and cached_version == mv._load_version
                and _arg_value_dominates_current_ip(arg)
            ):
                return arg
            return mv.load()
        # Ref exists but is inaccessible (stale, from sibling/exited CF).
        # Re-create at current scope to restore dominance -- but only
        # when ``arg``'s SSA value still dominates the current IP.  If
        # it doesn't, ``_create_ref`` would D-fallback to a
        # ``ub.poison``-initialised ref at function entry with no
        # accompanying store, and the subsequent ``mv.load()`` would
        # silently read poison.  In that case fall through to
        # returning ``arg`` unchanged -- the verifier (or the
        # end-of-trace poison-read catcher, if a sibling code path
        # did create the same poison-init pattern) will surface the
        # real issue at trace time instead of producing wrong results.
        if _can_create_ref(arg) and _arg_value_dominates_current_ip(arg):
            try:
                new_mv = _create_ref(arg)
                return new_mv.load()
            except Exception:
                pass  # fall through to return arg
    return arg


def _raw_ir_value(arg: Any) -> "ir.Value":
    """Return *arg*'s backing ``ir.Value`` WITHOUT re-entering the
    ``@dsl_user_op`` instrumentation in :func:`_pyir_auto_load_arg`.

    ``_arg_value_dominates_current_ip`` needs only the raw MLIR value to
    inspect its owner/defining-op; it must not trigger op emission or a
    nested auto-load.  Calling ``arg.ir_value()`` directly is unsafe:
    for DSL value types whose ``ir_value`` is itself ``@dsl_user_op``
    -wrapped (e.g. ``cute.TensorSSA``), the wrapper auto-loads its own
    ``self`` argument, which calls back into ``_pyir_auto_load_arg`` ->
    ``_arg_value_dominates_current_ip`` -> ``ir_value()`` -> ... ad
    infinitum (RecursionError).

    DSL value wrappers (``ArithValue`` / ``Vector`` / ``TensorSSA``)
    subclass ``ir.Value`` directly, so when *arg* is already an
    ``ir.Value`` it IS its own raw MLIR value and no call is needed.
    Otherwise fall back to the un-instrumented underlying ``ir_value``
    (``__wrapped__`` strips the ``@dsl_user_op`` wrapper) so the
    dominance probe stays side-effect-free.
    """
    if isinstance(arg, ir.Value):
        return arg
    iv = getattr(type(arg), "ir_value", None)
    unwrapped = getattr(iv, "__wrapped__", None)
    if unwrapped is not None:
        return unwrapped(arg)
    return arg.ir_value()


def _arg_value_dominates_current_ip(arg: Any) -> bool:
    """Return ``True`` if *arg*'s backing ``ir.Value`` dominates the
    current MLIR insertion point.

    Used by ``_pyir_auto_load_arg`` to decide whether a previously
    loaded value can be reused without emitting a fresh
    ``pyir.load``.  Conservative: returns ``False`` on any error so
    the caller falls back to re-loading.

    The region check via ``is_value_in_ancestor_region`` is necessary
    but not sufficient: same-region values may still be defined after
    the current insertion point.  For same-block defs we additionally
    require the defining op to precede the IP using
    ``is_before_in_block`` against the IP's reference operation (or
    accept any same-block op when the IP is at the block end).
    """
    if pyir is None:
        return False
    try:
        raw = _raw_ir_value(arg)
        ip = ir.InsertionPoint.current
        current_block = ip.block
        if not pyir.is_value_in_ancestor_region(raw, current_block):
            return False
        owner = raw.owner
        if isinstance(owner, ir.Block):
            return True  # block argument — dominates everything in its region
        def_op = getattr(owner, "operation", owner)
        if def_op.block != current_block:
            return True  # proper-ancestor region — structural dominance
        ref_op = ip.ref_operation
        if ref_op is None:
            return True  # IP at block end; def was emitted earlier in trace
        ref_op = getattr(ref_op, "operation", ref_op)
        if def_op == ref_op:
            return False
        return def_op.is_before_in_block(ref_op)
    except Exception:
        return False


def _has_decomposable_staged_fields(obj: object) -> bool:
    """Return True if *obj* can be auto-decomposed into per-field
    ``pyir_assign`` calls.

    All instance attributes must be meta primitives, staged+ref-compatible
    scalars, tuples of the above, or nested compounds of the above.
    At least one field must be staged (otherwise there is nothing to
    decompose).
    """
    return _check_all_fields_decomposable(obj, _visited=set())


def _has_any_staged_content(obj: object) -> bool:
    """Return True if any field (deeply) is a staged value.

    Used for the error vs passthrough decision: if the object has staged
    content that cannot be decomposed, we raise an error.  If it has NO
    staged content, it is a pure meta replacement (harmless).
    """
    for attr_name in _get_instance_attrs(obj):
        value = getattr(obj, attr_name)
        if _is_staged_value(value):
            return True
        if isinstance(value, tuple) and any(
            _is_staged_value(e) for e in _flatten_tuple(value)
        ):
            return True
        if (
            hasattr(value, "__dict__")
            and not isinstance(value, (int, float, bool, str, bytes, type))
            and _has_any_staged_content(value)
        ):
            return True
    return False


__all__ = [name for name in list(globals()) if not name.startswith("__")]
