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


"""PyIR runtime -- core layer; see facade for the public surface."""

from .pyir_state import *  # noqa: F401,F403  (re-export lower layers up the chain)

# -- BEGIN explicit imports for the type checker (do not edit the list by hand;
# it mirrors names the chain re-exports at runtime via the wildcard + dynamic
# ``__all__`` above, which a static type checker cannot evaluate -- so every
# name is also imported explicitly from the layer that DEFINES it). Purely
# additive: the wildcard import stays the runtime source of truth.
from .pyir_state import (  # noqa: F401
    Any,
    DSLRuntimeError,
    Optional,
    _MAX_FOLD_WITNESSES_PER_SLOT,
    _MODULE_OPS,
    _NON_DOT_FUNC_ENTRY_OPS,
    _PYIR_SLOT_FALLBACK,
    _SCF_REGION_NAMES,
    _SLOT_STORE_ATTR,
    _fold_witnesses,
    _is_staged_value,
    _meta_uses,
    _pinned_owners,
    _pyir_fn_id_stack,
    _slot_first_def_block,
    _slot_first_def_depth,
    _slot_first_def_depth_any,
    _slot_first_def_inside_cf,
    _slot_mvs,
    _slot_pending_store,
    _slot_refs,
    inspect,
    ir,
    log,
    pyir,
    ub,
)
# -- END explicit imports for the type checker

import operator
import sys
from typing import Callable  # noqa: F401  (used in _BINOP_OPS annotation)
from types import FrameType  # noqa: F401  (used in _fold_consumer_is_user_code)


def _make_slot_key(
    target_name: "str | None",
    owner: Any = None,
    slot_name: Any = None,
    fn_key: Any = None,
) -> Any:
    """Build the key under which a D1 slot is tracked.

    Locals:      ``("name", target_name)``
    Attributes:  ``("attr", id(owner), slot_name)``

    Returns ``None`` when neither a target name nor an owner/slot tuple
    is available -- retroactive promotion is disabled for that call.
    """
    if owner is not None and slot_name is not None:
        # Keep the owner alive so its address can't be reused while we key on it.
        # This is total: the key is id(owner) (an int), so the owner is never
        # hashed and only stored by reference -- it can't fail for any owner,
        # including unhashable ones like dict/list.
        _pinned_owners[id(owner)] = owner
        return ("attr", id(owner), slot_name)
    if target_name is not None:
        # Frame-local key: qualify by the owning user function (fn_key) so two
        # functions with a same-named local get DISTINCT slots instead of
        # colliding on one shared ``pyir.ref``.  fn_key is None outside a tracked
        # function -> fall back to the name-only key.
        if fn_key is not None:
            return ("name", target_name, fn_key)
        return ("name", target_name)
    return None


def _cached_ir_value_dominates_ip(
    value: "ir.Value",
    ip: "Optional[ir.InsertionPoint]" = None,
) -> bool:
    """Whether *value* is reachable from the target insertion point.

    The target is *ip* when given, otherwise ``InsertionPoint.current``.
    Used to invalidate per-instance ``_WatchedM._cached_ir`` when the
    cached ``arith.constant`` was materialised in a sibling staged-CF
    region (and therefore would be a region escape if reused).  When
    the ``pyir`` python binding is unavailable (PyIR-disabled builds)
    or there is no active insertion point, returns True so the legacy
    behaviour is preserved.
    """
    if pyir is None:
        return True
    try:
        current_block = (
            ip if ip is not None else ir.InsertionPoint.current
        ).block
    except (RuntimeError, ValueError):
        return True
    return pyir.is_value_in_ancestor_region(value, current_block)


def _emit_constant_at_ip(
    value: Any,
    *,
    loc: "Optional[ir.Location]" = None,
    ip: "Optional[ir.InsertionPoint]" = None,
) -> "ir.Value":
    """Emit a FRESH ``arith.constant`` for a Python primitive at the current IP.

    Bypasses the ``@lru_cache_ir`` memoisation on
    :func:`cutlass._mlir_helpers.arith.const` so each call returns a
    distinct ``ir.Value``. D1 retroactive promotion relies on
    per-slot ``replaceAllUsesWith``: if multiple slots share the same
    cached SSA, promoting any one of them would clobber the others'
    uses too (the printf-with-three-True-args mixing.py bug).
    """
    from .._mlir.dialects import arith as _arith
    from .._mlir import ir as _ir

    if isinstance(value, bool):
        mlir_ty = _ir.IntegerType.get_signless(1)
        return _arith.constant(mlir_ty, value, loc=loc, ip=ip)
    if isinstance(value, int):
        mlir_ty = _ir.IntegerType.get_signless(32)
        return _arith.constant(mlir_ty, value, loc=loc, ip=ip)
    if isinstance(value, float):
        mlir_ty = _ir.F32Type.get()
        return _arith.constant(mlir_ty, value, loc=loc, ip=ip)
    # Fallback (rare): defer to the cached helper.
    from .._mlir_helpers.arith import const as _arith_const

    return _arith_const(value, loc=loc, ip=ip)


def _unwrap(value: Any) -> Any:
    """Strip a ``_WatchedM`` wrapper (one level), or return *value* as-is."""
    if isinstance(value, _WatchedM):
        return value.python_value
    return value


def _fold_consumer_is_user_code() -> bool:
    """Whether the frame that triggered this fold is author code, not DSL glue.

    Gate for fold-witness recording.  The predicate positions the preprocessor
    can see -- ternaries, ``while`` conditions -- record their witness directly
    through ``force_consumer`` and never reach here.  What remains is IMPLICIT
    consumption (``__bool__``/``__eq__``/``__index__``/``__int__``/``__format__``)
    that CPython invokes from an arbitrary call depth with no source site to
    instrument: e.g. the comparisons inside ``max``/``min``/``sum`` run in their
    C implementation, where the only Python frame present is a DSL executor.
    Whether such a fold is the author's own control flow or the DSL legitimately
    truth-testing a wrapped value in glue code (config checks that never build
    user-visible control flow) is a property of the live call stack, so it is
    read off the consuming frame.  Recording only author-frame folds keeps the
    diagnostic free of false positives from DSL-internal probing.
    """
    try:
        frame: "FrameType | None" = sys._getframe(1)
    except Exception:  # noqa: BLE001
        return False
    from .common import is_dsl_internal_code  # inline: break the import cycle

    try:
        while frame is not None:
            if frame.f_globals.get("__name__") != __name__:
                frame_is_internal = is_dsl_internal_code(
                    frame.f_code.co_filename,
                    frame.f_globals.get("__name__", "") or "",
                )
                if not frame_is_internal:
                    return True
                # The preprocessor RELOCATES user predicate expressions into
                # DSL executor frames: `x in seq` -> in_ / compare chains,
                # `a if c else b` -> ifExp_executor, `a and b` / `a or b` ->
                # and_op / or_op.  A fold consumed THERE is the user's
                # control flow, not DSL-internal probing -- without this the
                # witness for `if meta in (3,5,7):` / ternary / short-circuit
                # predicates is dropped and a later promotion miscompiles
                # silently.
                return frame.f_code.co_name in _PRED_EXECUTOR_FRAMES
            frame = frame.f_back
    finally:
        del frame
    return False


# DSL executor frames that evaluate USER predicate expressions on the
# preprocessor's behalf (see _fold_consumer_is_user_code).
# ``builtin_wrapper`` routes user calls to ``max``/``min``/``sum`` etc.;
# folds consumed inside it come from the USER's arguments (without
# a ``max(...)`` over watched values folded silently and a later
# promotion shipped the stale result).
_PRED_EXECUTOR_FRAMES: frozenset = frozenset(
    {"ifExp_executor", "in_", "not_in", "and_op", "or_op", "not_op", "builtin_wrapper"}
)


def _wrapper_slots(value: Any) -> frozenset:
    """All D1 slot keys a wrapper is connected to (own slot + provenance)."""
    if not isinstance(value, _WatchedM):
        return frozenset()
    slots = value._origin_slots
    if value._slot_key is not None:
        slots = slots | {value._slot_key}
    return slots


def _record_fold_witness(
    lhs: Any, rhs: Any, folded_value: Any, kind: str, force_consumer: bool = False
) -> None:
    """Record that a slot-connected fold was consumed by plain CPython.

    No-op unless (a) inside staged CF, (b) at least one operand is connected
    to a D1 slot, and (c) the consuming frame is author code (see
    ``_fold_consumer_is_user_code``).  Never raises -- the diagnostic is
    deferred to ``_meta_promote_slot`` so slots that stay constexpr for the
    whole trace (the supported meta-programming model) are never penalised.

    ``force_consumer`` skips gate (c): structural-integer consumption
    (``__index__``) is dangerous no matter which frame performs it — the
    canonical offender is ``range_constexpr``'s bound check, which calls
    ``__index__`` from ``ast_helpers`` (a DSL frame) to fix a trace-time
    unroll count that no later promotion can change.
    """
    slots = _wrapper_slots(lhs) | _wrapper_slots(rhs)
    if not slots:
        return
    from .multi_stage_manager import is_inside_staged_cf

    if not is_inside_staged_cf():
        return
    if not force_consumer and not _fold_consumer_is_user_code():
        return
    from .diagnostics import find_user_source_location

    filename, lineno, _col, _end_col = find_user_source_location()
    record = {
        "filename": filename,
        "lineno": lineno,
        "value": folded_value,
        "kind": kind,
    }
    for slot in slots:
        entries = _fold_witnesses.setdefault(slot, [])
        if len(entries) < _MAX_FOLD_WITNESSES_PER_SLOT:
            entries.append(record)
    # A fold on a slot that is ALREADY runtime-varying can never be repaired
    # by a later promotion (it already happened) -- deferring the diagnostic
    # would leave this consumption silently stale (e.g. an alias captured
    # before the region, structurally consumed after).  Raise now.  master
    # tracks "already promoted" as membership in ``_slot_refs`` (set in
    # ``_meta_promote_slot``), the bridge for the donor's ``_slot_stored``.
    stale = [s for s in slots if s in _slot_refs]
    if stale:
        slot = stale[0]
        name = slot[1] if isinstance(slot, tuple) and len(slot) > 1 else None
        _raise_on_fold_witness(slot, folded_value, name, filename, lineno)
    log().info(
        "[fold-witness] %s consumed by CPython (%s) at %s:%s -> slots %s",
        folded_value,
        kind,
        filename,
        lineno,
        list(slots),
    )


# Op name -> Python operator; folds the shadow value and drives arith IR
# emission (delegation, !24500; consumed by ``_binop_ir``).
_BINOP_OPS: "dict[str, Callable[[Any, Any], Any]]" = {
    "add": operator.add,
    "sub": operator.sub,
    "mul": operator.mul,
    "truediv": operator.truediv,
    "floordiv": operator.floordiv,
    "mod": operator.mod,
    "and": operator.and_,
    "or": operator.or_,
    "xor": operator.xor,
    "lshift": operator.lshift,
    "rshift": operator.rshift,
}

# Op name -> Python operator; used to DELEGATE comparison (and arith) IR emission
# to the canonical ``ArithValue`` operator layer (which owns cmpi/cmpf predicate
# selection) -- consumed by ``_cmp_ir`` via ``_emit_arith_via_dsl`` /
# ``_emit_widened_via_numeric``.  Superset of ``_BINOP_OPS`` (adds comparisons).
_DELEGATED_OP_FUNCS: "dict[str, Callable[[Any, Any], Any]]" = {
    "add": operator.add,
    "sub": operator.sub,
    "mul": operator.mul,
    "floordiv": operator.floordiv,
    "truediv": operator.truediv,
    "mod": operator.mod,
    "and": operator.and_,
    "or": operator.or_,
    "xor": operator.xor,
    "lshift": operator.lshift,
    "rshift": operator.rshift,
    "lt": operator.lt,
    "le": operator.le,
    "gt": operator.gt,
    "ge": operator.ge,
    "eq": operator.eq,
    "ne": operator.ne,
}


def _needs_float_promotion(lhs_ir: "ir.Value", rhs: Any, op_name: str) -> bool:
    """True when the op must use the promoting Numeric layer.

    Promote for: truediv on an integer lhs; a watched rhs (``ir.Value``)
    whose type differs from the lhs; a plain float rhs on an integer lhs
    (coercing it to the lhs type would truncate).  A plain int rhs on a float
    lhs coerces up exactly and stays on the ArithValue path.  Pre-existing i1
    hole kept as-is: ``wb + 2`` still bakes the rhs to i1.

    (Rebase merge: the fold-witness ``_cmp_ir`` reuses this as its
    float-widening discriminator -- the former ``_needs_float_widening`` had
    byte-identical logic and was dropped.)
    """
    lhs_is_float = isinstance(lhs_ir.type, ir.FloatType)
    if op_name == "truediv" and not lhs_is_float:
        return True
    if isinstance(rhs, ir.Value):
        return lhs_ir.type != rhs.type
    return (not lhs_is_float) and isinstance(rhs, float)


def _emit_arith_via_dsl(lhs_ir: "ir.Value", rhs_ir: "ir.Value", op_name: str) -> Any:
    """Emit the arith/cmp op for *op_name* by DELEGATING to the DSL's canonical
    ``ArithValue`` operator layer, rather than hand-picking arith ops here.

    ``ArithValue`` (``_mlir_helpers.arith``) already owns the mapping from a
    Python operator to a concrete arith op -- ``cmpi``/``cmpf``, the
    signed-vs-unsigned predicate choice, and so on.  We wrap the
    already-materialised operand SSA values in ``ArithValue`` and invoke the
    operator.  The operands are used verbatim -- the caller hands two
    same-typed SSA values, so this never triggers type widening.

    Returns the result ``ir.Value``, or ``NotImplemented`` for an op name not
    in the table.  Emission failures propagate so callers can apply their
    existing NotImplemented / plain-fold fallback.
    """
    op_fn = _DELEGATED_OP_FUNCS.get(op_name)
    if op_fn is None:
        return NotImplemented

    from .._mlir_helpers.arith import ArithValue

    lhs_av = lhs_ir if isinstance(lhs_ir, ArithValue) else ArithValue(lhs_ir)
    rhs_av = rhs_ir if isinstance(rhs_ir, ArithValue) else ArithValue(rhs_ir)
    return op_fn(lhs_av, rhs_av)


# Reflected dunders: "wrap" boxes the plain lhs and runs the forward op;
# "swap" reuses the forward path (commutative mul).  These fire only when the
# lhs type defers to the subclass -- ``2.0 / watched_int`` never dispatches
# here and stays unwatched.  The other ops are absent on purpose: enabling
# one changes behavior and needs its own tests.
_REFLECTED_SPECS: "dict[str, str]" = {
    "add": "wrap",
    "sub": "wrap",
    "mul": "swap",
    "truediv": "wrap",
}


def _generate_binop_dunders(cls: type) -> type:
    """Generate the binary dunders from ``_BINOP_OPS`` / ``_REFLECTED_SPECS``.

    Grep anchors: __add__ __sub__ __mul__ __truediv__ __floordiv__ __mod__
    __and__ __or__ __xor__ __lshift__ __rshift__
    __radd__ __rsub__ __rmul__ __rtruediv__
    """

    def _make_dunder(name: str, op: str, reflected_wrap: bool) -> Any:
        if reflected_wrap:

            def dunder(self: Any, other: Any) -> Any:
                # Box the plain lhs so self's slot provenance threads through.
                other_py = _unwrap(other)
                if not isinstance(other_py, (bool, int, float)):
                    return NotImplemented
                return _WatchedM(other_py)._binop_ir(self, op)

        else:

            def dunder(self: Any, other: Any) -> Any:
                return self._binop_ir(other, op)

        dunder.__name__ = name
        dunder.__qualname__ = f"{cls.__qualname__}.{name}"
        dunder.__doc__ = f"Staged ``{op}``; see ``_binop_ir``."
        return dunder

    for op in _BINOP_OPS:
        setattr(cls, f"__{op}__", _make_dunder(f"__{op}__", op, False))
    for op, style in _REFLECTED_SPECS.items():
        setattr(cls, f"__r{op}__", _make_dunder(f"__r{op}__", op, style == "wrap"))
    return cls


def _emit_widened_via_numeric(
    lhs_ir: "ir.Value", rhs_ir: "ir.Value", op_name: str
) -> Any:
    """Emit *op_name* via the DSL Numeric layer, which applies int<->float type
    widening (the ArithValue layer does not).  Used only for the mixed /
    truediv cases flagged by :func:`_needs_float_promotion`.

    ``rhs_ir`` must carry its NATURAL type (int->i32, float->f32) so widening
    sees the real operand kinds.  Returns the result ``ir.Value`` (float for
    arithmetic, i1 for comparisons) or ``NotImplemented``.
    """
    op_fn = _DELEGATED_OP_FUNCS.get(op_name)
    if op_fn is None:
        return NotImplemented

    from .typing import Numeric
    from .._mlir_helpers.arith import ArithValue

    lhs_av = lhs_ir if isinstance(lhs_ir, ArithValue) else ArithValue(lhs_ir)
    rhs_av = rhs_ir if isinstance(rhs_ir, ArithValue) else ArithValue(rhs_ir)
    lhs_num = Numeric.from_mlir_type(lhs_av.type)(lhs_av)
    rhs_num = Numeric.from_mlir_type(rhs_av.type)(rhs_av)
    result_num = op_fn(lhs_num, rhs_num)
    if result_num is NotImplemented:
        return NotImplemented
    return result_num.ir_value()


@_generate_binop_dunders
class _WatchedM:
    """Wrap a Python primitive read inside staged CF for D1 tracking.

    The wrapper records the slot it came from so a later mutation can
    rewrite baked ``arith.constant`` leaves to ``pyir.load %ref`` via
    ``replaceAllUsesWith``.  Arithmetic emits IR EAGERLY (returns a
    derived wrapper carrying the result SSA); only LEAF constants are
    tracked, downstream rewrite is handled by SSA edges when leaves are
    replaced.

    **Crucial design point:** concrete instances subclass ``int`` or
    ``float`` so that downstream code using ``isinstance(x, int)`` /
    ``isinstance(x, float)`` sees them as primitives.  Without this,
    every consumer of an Mp-typed arg (``cutlass.Array(shape=...)``,
    ``cute.printf``, MLIR builder shape params, etc.) would need a
    band-aid unwrap -- D1's wrapping must be transparent to user code.

    Construction goes through ``_WatchedM(value, slot_key)`` which
    dispatches to ``_WatchedInt`` (covers ``bool`` + ``int``) or
    ``_WatchedFloat``.  ``isinstance(x, _WatchedM)`` still works for
    D1-internal checks because both concrete classes inherit from
    ``_WatchedM``.  See ``PYIR_DEV_GUIDE.md`` Pitfall 15.
    """

    # Declared on the base class so type-checkers see them from
    # ``ir_value``/``_pyir_auto_load_arg`` callers.  Concrete subclass
    # ``__new__`` populates each instance with the per-instance value.
    _slot_key: Any
    _cached_ir: Optional["ir.Value"]

    # Slot provenance for DERIVED wrappers (``_slot_key is None``): the D1
    # slot keys of every tracked leaf this value was computed from, threaded
    # through ``_binop_ir`` / ``_cmp_ir``.  Lets a fold-witness on a derived
    # value (e.g. ``if m > 15:`` truth-testing the derived ``_WatchedBool``)
    # be attributed back to the leaf slot(s) whose promotion would make the
    # fold stale.  Class-level default keeps leaf construction unchanged.
    _origin_slots: frozenset = frozenset()

    def __new__(cls, value: Any = 0, slot_key: Any = None) -> "_WatchedM":
        # Factory dispatch: _WatchedM(...) lands here and forwards to
        # the right int/float-backed subclass.  Subclass __new__ paths
        # bypass this branch (cls is the subclass, not _WatchedM).
        if cls is _WatchedM:
            # Bool first because ``isinstance(True, int)`` is True.  Keep
            # bool routed through ``_WatchedBool`` so ``python_value``
            # returns ``True``/``False`` and downstream ``arith.const``
            # emits ``i1`` (not ``i32``).
            if isinstance(value, bool):
                return _WatchedBool.__new__(_WatchedBool, value, slot_key)
            if isinstance(value, int):
                return _WatchedInt.__new__(_WatchedInt, value, slot_key)
            if isinstance(value, float):
                return _WatchedFloat.__new__(_WatchedFloat, value, slot_key)
            raise TypeError(
                f"_WatchedM cannot wrap value of type {type(value).__name__}; "
                "only bool/int/float are supported."
            )
        # Subclass __new__ already constructed the instance; nothing to do.
        return super().__new__(cls)

    @property
    def python_value(self) -> Any:
        """The bare Python value (for ``const_expr`` and similar).

        Returns ``self`` cast to its int/float base via the subclass
        override.  Falls back to ``self`` for the base class (never
        reached in practice).
        """
        return self

    def ir_value(
        self,
        *,
        loc: "Optional[ir.Location]" = None,
        ip: "Optional[ir.InsertionPoint]" = None,
    ) -> "ir.Value":
        """Emit (or reuse) the leaf ``arith.constant`` and record it.

        Cached across calls -- BUT the cache is only honoured when the
        cached SSA still dominates the current insertion point.  Without
        that check, the same ``_WatchedInt`` instance read from N sibling
        staged-CF regions (e.g. the eight ``scf.if`` bodies an unrolled
        ``range_constexpr`` emits) would pin its only ``arith.constant``
        inside the FIRST region and leave N-1 dangling cross-region uses
        -- the printer emits invalid IR ("use of undeclared SSA value
        name") and the verifier reports the underlying region escape.

        Every materialisation is appended to ``_meta_uses[slot]`` so D1
        retroactive promotion can ``replaceAllUsesWith`` every baked
        leaf, not just the first one.
        """
        cached = self._cached_ir
        if cached is not None and _cached_ir_value_dominates_ip(cached, ip):
            return cached
        const = _emit_constant_at_ip(self.python_value, loc=loc, ip=ip)
        self._cached_ir = const
        if self._slot_key is not None:
            _meta_uses.setdefault(self._slot_key, []).append(const)
        return const

    # int / float / bool dunders are inherited from the int / float
    # base class on the concrete subclass.  ``__repr__`` is inherited
    # too -- the printed form is the bare numeric, which is what we
    # want (matches ``repr(int_value)``).

    # ----- arithmetic: emit IR eagerly, return derived wrappers -----------

    def _binop_ir(self, other: Any, op_name: str) -> Any:
        """Fold the Python shadow and emit IR via the DSL operator layer.

        Same-typed operands go through ``ArithValue``; mixed / truediv combos
        through the promoting ``Numeric`` layer (see
        ``_needs_float_promotion``).  Every failure except division-by-zero
        returns ``NotImplemented`` so Python falls back to the ``int``/
        ``float`` base-class semantics.
        """
        op_fn = _BINOP_OPS.get(op_name)
        if op_fn is None:
            return NotImplemented
        try:
            from .._mlir.dialects import arith as _arith
        except ImportError:
            return NotImplemented

        rhs_py = _unwrap(other)
        if not isinstance(rhs_py, (bool, int, float)):
            return NotImplemented

        try:
            result_py = op_fn(self.python_value, rhs_py)
        except ZeroDivisionError:
            # NotImplemented can't succeed here and would surface as a
            # misleading TypeError for a float lhs.
            raise
        except Exception:
            return NotImplemented

        try:
            from .._mlir_helpers.arith import ArithValue
            from .._mlir_helpers.arith import const as _arith_const

            def _av(v: Any) -> Any:
                return v if isinstance(v, ArithValue) else ArithValue(v)

            lhs_ir = self.ir_value()
            if isinstance(other, _WatchedM):
                rhs_ir = other.ir_value()
                promote = _needs_float_promotion(lhs_ir, rhs_ir, op_name)
            else:
                # Natural type when promoting; else coerce to the lhs type.
                promote = _needs_float_promotion(lhs_ir, rhs_py, op_name)
                rhs_ir = (
                    _arith_const(rhs_py)
                    if promote
                    else _arith_const(rhs_py, lhs_ir.type)
                )

            if promote:
                # Known waiver: promoted % emits remf while the shadow folds
                # Python floor-mod (matches the non-PyIR runtime canon).
                from .typing import Numeric

                result = op_fn(
                    Numeric.from_mlir_type(lhs_ir.type)(_av(lhs_ir)),
                    Numeric.from_mlir_type(rhs_ir.type)(_av(rhs_ir)),
                )
                result_ir = (
                    NotImplemented if result is NotImplemented else result.ir_value()
                )
            elif op_name == "floordiv" and isinstance(lhs_ir.type, ir.FloatType):
                # Legacy byte-compat: bare divf, no math.floor (ArithValue
                # would add one; the shadow IS floored).
                result_ir = _arith.divf(lhs_ir, rhs_ir)
            else:
                # ArithValue picks the arith op; i1 stays i1 (Numeric widens).
                result_ir = op_fn(_av(lhs_ir), _av(rhs_ir))
            if result_ir is NotImplemented:
                return NotImplemented
        except Exception:
            return NotImplemented

        derived = _WatchedM(result_py, slot_key=None)
        derived._cached_ir = result_ir
        # Thread slot provenance so a fold-witness on this derived value is
        # attributed back to the leaf slot(s) whose promotion would make it
        # stale (see ``_wrapper_slots`` / ``_record_fold_witness``).
        derived._origin_slots = _wrapper_slots(self) | _wrapper_slots(other)
        return derived

    # Binary dunders are generated by ``_generate_binop_dunders``.

    # ----- fold-witness channels: consumption that CPython forces to a bare
    # Python value (no SSA edge), recorded so a later promotion raises
    # PHASE_PREDICATE_FOLDED_STALE instead of silently shipping the stale fold.

    def __bool__(self) -> bool:
        """Truth-test: fold to the real Python truth value, but witness it.

        CPython requires a real ``bool`` here (``if w:``, ``while w:``,
        ``not w``, ``and``/``or``), so the fold itself cannot be avoided.
        Inside staged CF that fold decides a TRACE-TIME branch the IR never
        sees -- sound only while the slot stays constexpr.  Record a
        fold-witness so a later promotion of the slot turns the silent
        miscompile into ``DiagId.PHASE_PREDICATE_FOLDED_STALE`` (raised by
        ``_meta_promote_slot``, which cites this fold's location).
        """
        result = bool(self.python_value)
        _record_fold_witness(self, None, result, "a Python `if`/`while`/`not` test")
        return result

    def __index__(self) -> int:
        """Structural-integer consumption: loop bounds (``range_constexpr``),
        list/tuple indices, shape parameters.  The result fixes trace-time
        CODE STRUCTURE (e.g. an unroll count) that no later promotion can
        rewrite, so witness it even from DSL-internal frames
        (``force_consumer``).  CPython requires a real ``int``.
        """
        pv = self.python_value
        if not isinstance(pv, int):
            raise TypeError(
                f"'{type(self).__name__}' with non-int payload cannot be "
                "interpreted as an integer"
            )
        _record_fold_witness(
            self,
            None,
            int(pv),
            "a trace-time structural integer (constexpr loop bound / index / shape)",
            force_consumer=True,
        )
        return int(pv)

    def __int__(self) -> int:
        result = int(self.python_value)
        _record_fold_witness(self, None, result, "an `int()` cast")
        return result

    def __float__(self) -> float:
        result = float(self.python_value)
        _record_fold_witness(self, None, result, "a `float()` cast")
        return result

    def __format__(self, format_spec: str) -> str:
        result = format(self.python_value, format_spec)
        _record_fold_witness(self, None, result, "a string-formatting read")
        return result

    # ----- comparisons: emit live cmpi/cmpf and return a derived wrapper so
    # the predicate is a real SSA edge (lift-able to a dynamic while/ternary
    # condition); fall back to a witnessed plain fold when IR cannot be made.

    def _cmp_ir(self, other: Any, op_name: str) -> Any:
        # Staged DSL Numeric rhs (e.g. ``meta < i`` with a loop var): there
        # is no Python fold — emit the cmp on the TRACKED leaf and return a
        # staged Boolean so the predicate is live and promotion RAUW can
        # rewrite the lhs.  Without this the reflected Numeric compare
        # bakes python_value as an UNTRACKED constant and a while on it
        # never observes the body's writes (infinite scf.while).
        from .typing import Boolean as _Boolean, Numeric as _Numeric
        if isinstance(other, _Numeric):
            try:
                result_ir = _emit_arith_via_dsl(
                    self.ir_value(),
                    other.ir_value(),
                    op_name,
                )
                if result_ir is NotImplemented:
                    return NotImplemented
                return _Boolean(result_ir)
            except Exception:
                return NotImplemented

        # Non-primitive, non-Numeric rhs: defer to the rhs's reflected
        # dunder via NotImplemented.  For primitive-comparable operands we
        # must NEVER return NotImplemented below this point: when both
        # directions bail, CPython falls back to identity for ==/!= (two
        # equal-valued wrappers compare unequal) and raises TypeError for
        # orderings between two wrapper instances.
        rhs_py = _unwrap(other)
        if not isinstance(rhs_py, (bool, int, float)):
            return NotImplemented

        py_ops = {
            "lt": lambda a, b: a < b,
            "le": lambda a, b: a <= b,
            "gt": lambda a, b: a > b,
            "ge": lambda a, b: a >= b,
            "eq": lambda a, b: a == b,
            "ne": lambda a, b: a != b,
        }
        result_py = py_ops[op_name](self.python_value, rhs_py)

        try:
            from .._mlir.dialects import arith as _arith  # noqa: F401
        except ImportError:
            # Plain-fold fallback on a slot-connected wrapper: the folded
            # bool may feed control flow the meta table cannot see -- record
            # a witness (no-ops when neither operand carries a slot).
            _record_fold_witness(
                self, other, result_py, "a comparison folded at trace time"
            )
            return result_py

        # Disconnected wrapper (no slot, no derived SSA): nothing for
        # promotion to rewrite — keep the plain Python fold.  The RHS may
        # still be slot-connected (e.g. ``_WatchedM(5) == watched_x``), so
        # witness the fold for ITS slots (no-op when rhs carries none).
        if self._slot_key is None and self._cached_ir is None:
            _record_fold_witness(
                None, other, result_py, "a comparison folded at trace time"
            )
            return result_py

        try:
            from .._mlir_helpers.arith import const as _arith_const

            lhs_ir = self.ir_value()
            widen = _needs_float_promotion(lhs_ir, rhs_py, op_name)
            if isinstance(other, _WatchedM):
                rhs_ir = other.ir_value()
            elif widen:
                rhs_ir = _arith_const(rhs_py)  # NATURAL type so widening sees it
            else:
                rhs_ir = _arith_const(rhs_py, lhs_ir.type)
            if widen:
                # int lhs vs a float rhs: widen to float so the compare
                # matches Python.  The same-type path would truncate the float
                # rhs to the lhs integer type and flip results (e.g. ``w < 5.5``
                # with w==5 -> slt(5,5)==False instead of True).
                result_ir = _emit_widened_via_numeric(lhs_ir, rhs_ir, op_name)
            else:
                result_ir = _emit_arith_via_dsl(lhs_ir, rhs_ir, op_name)
            if result_ir is NotImplemented:
                # Unreachable for the fixed set of comparison op names; route
                # an unknown op through the plain-fold + witness path below
                # rather than ever handing back a NotImplemented from a compare.
                raise TypeError(f"unsupported comparison op {op_name!r}")
        except Exception:
            # IR emission failed (dead context, type mismatch such as an
            # i1 leaf vs int rhs, mixed int/float) — keep exact Python
            # comparison semantics rather than NotImplemented (see above).
            # This is a PLAIN-FOLD consumption: the caller gets a bare
            # ``bool`` with no live IR edge, so any control flow it feeds is
            # invisible to promotion -- witness it.  (The successful path
            # below returns a derived wrapper with live ``cmpi``/``cmpf`` IR
            # and is NOT witnessed; its truth-test, if any, is witnessed by
            # ``__bool__`` instead.)
            _record_fold_witness(
                self, other, result_py, "a comparison folded at trace time"
            )
            return result_py

        derived = _WatchedM(bool(result_py), slot_key=None)
        derived._cached_ir = result_ir
        derived._origin_slots = _wrapper_slots(self) | _wrapper_slots(other)
        return derived

    def __lt__(self, other: Any) -> Any:
        return self._cmp_ir(other, "lt")

    def __le__(self, other: Any) -> Any:
        return self._cmp_ir(other, "le")

    def __gt__(self, other: Any) -> Any:
        return self._cmp_ir(other, "gt")

    def __ge__(self, other: Any) -> Any:
        return self._cmp_ir(other, "ge")

    def __eq__(self, other: Any) -> Any:
        return self._cmp_ir(other, "eq")

    def __ne__(self, other: Any) -> Any:
        return self._cmp_ir(other, "ne")


class _WatchedInt(_WatchedM, int):
    """Concrete D1 wrapper backed by ``int``.

    No ``__slots__`` -- CPython forbids non-empty ``__slots__`` on int
    subclasses.  We accept the small ``__dict__`` cost in exchange for
    transparent ``isinstance(x, int)`` behavior throughout the DSL.
    """

    # Defining ``__eq__`` on ``_WatchedM`` implicitly sets ``__hash__ =
    # None`` there; restore the base-class hash so watched values stay
    # usable as dict keys / set members.
    __hash__ = int.__hash__

    def __new__(cls, value: Any, slot_key: Any = None) -> "_WatchedInt":
        inst = int.__new__(cls, value)
        inst._slot_key = slot_key
        inst._cached_ir = None
        return inst

    @property
    def python_value(self) -> int:
        # int.__int__ directly: ``int(self)`` would dispatch to the
        # witness-recording ``_WatchedM.__int__`` override and recurse
        # (it reads ``python_value`` right back).
        return int.__int__(self)


class _WatchedBool(_WatchedM, int):
    """Concrete D1 wrapper for ``bool`` values.

    ``bool`` is final in CPython so we cannot subclass it; subclass
    ``int`` (which ``bool`` itself subclasses) and override
    ``python_value`` to return a proper ``bool``.  This keeps
    ``arith.const`` on ``python_value`` emitting ``i1``, while
    ``isinstance(x, int)`` still passes downstream.  Note:
    ``isinstance(x, bool)`` returns ``False`` -- consumers that need
    bool-specific behavior must coerce via ``python_value`` or call
    ``arith.const`` which routes ``_WatchedM`` through ``ir_value()``.
    """

    __hash__ = int.__hash__

    def __new__(cls, value: Any, slot_key: Any = None) -> "_WatchedBool":
        inst = int.__new__(cls, int(value))
        inst._slot_key = slot_key
        inst._cached_ir = None
        return inst

    @property
    def python_value(self) -> bool:
        return bool(int.__int__(self))  # bypass _WatchedM.__int__ (recursion)


class _WatchedFloat(_WatchedM, float):
    """Concrete D1 wrapper backed by ``float``.  Same ``__slots__`` rule
    as :class:`_WatchedInt`."""

    __hash__ = float.__hash__

    def __new__(cls, value: Any, slot_key: Any = None) -> "_WatchedFloat":
        inst = float.__new__(cls, value)
        inst._slot_key = slot_key
        inst._cached_ir = None
        return inst

    @property
    def python_value(self) -> float:
        # float.__float__ directly: ``float(self)`` would dispatch to the
        # witness-recording ``_WatchedM.__float__`` override and recurse.
        return float.__float__(self)


def _replace_value_uses(old_val: "ir.Value", new_val: "ir.Value") -> bool:
    """Best-effort ``replaceAllUsesWith`` across MLIR Python binding versions."""
    for method_name in ("replace_all_uses_with", "replaceAllUsesWith"):
        fn = getattr(old_val, method_name, None)
        if fn is not None:
            try:
                fn(new_val)
                return True
            except Exception:
                continue
    return False


def _promoted_type_name(py_value: Any) -> str:
    """DSL type name a Python primitive promotes to (for diagnostics).

    Thin wrapper over the canonical mapping ``Numeric.from_python`` (single
    mechanism for Python-primitive -> DSL-type deduction); falls back to the
    raw Python type name for non-primitives so diagnostics never raise.
    """
    from .typing import Numeric

    try:
        return Numeric.from_python(py_value).__name__
    except Exception:  # noqa: BLE001 -- diagnostics must not raise
        return type(py_value).__name__


def _raise_on_fold_witness(
    slot_key: Any,
    initial_py_value: Any,
    target_name: "str | None",
    filename: "str | None",
    lineno: "int | None",
) -> None:
    """Refuse to promote a slot whose fold already decided CPython control flow.

    A recorded fold-witness means a trace-time branch was taken from this
    slot's constexpr value; promoting the slot now would make its reads
    runtime loads while that branch stays hard-wired -- a guaranteed silent
    miscompile.  Raise ``DiagId.PHASE_PREDICATE_FOLDED_STALE`` citing BOTH
    the fold site (from the witness) and the mutation site (this promotion's
    ``filename``/``lineno``, which also anchor the rendered code frame).
    """
    witnesses = _fold_witnesses.get(slot_key)
    if not witnesses:
        return
    from .common import DSLUserCodeError
    from .diagnostics import DiagId, find_user_source_location

    if filename is None and lineno is None:
        filename, lineno, _col, _end_col = find_user_source_location()

    first = witnesses[0]
    fold_location = (
        f"{first['filename']}:{first['lineno']}"
        if first["filename"] is not None
        else "a location inside a plain-Python helper"
    )
    if len(witnesses) > 1:
        fold_location += f" (and {len(witnesses) - 1} more place(s))"
    mut_location = (
        f"{filename}:{lineno}" if filename is not None else "the highlighted line"
    )
    var = target_name if target_name is not None else "this value"
    raise DSLUserCodeError(
        DiagId.PHASE_PREDICATE_FOLDED_STALE,
        filename=filename,
        lineno=lineno,
        var=var,
        value=repr(initial_py_value),
        type=_promoted_type_name(initial_py_value),
        fold_location=fold_location,
        fold_kind=first["kind"],
        mut_location=mut_location,
    )


def _exit_function_trace() -> None:
    """Clear D1 per-trace state.  Called from ``_jit_scope.finally``."""
    _meta_uses.clear()
    _slot_refs.clear()
    _slot_first_def_inside_cf.clear()
    _slot_first_def_depth.clear()
    _slot_first_def_depth_any.clear()
    _slot_first_def_block.clear()
    _slot_mvs.clear()
    _fold_witnesses.clear()  # P6: per-trace fold-witness table
    _slot_pending_store.clear()  # pfound: per-region syntactic write-set
    _pyir_fn_id_stack.clear()
    _pinned_owners.clear()  # release owners we kept alive for slot-key identity


def _watched_to_dsl(watched: "_WatchedM") -> Any:
    """Convert a ``_WatchedM`` wrapper into the matching DSL Numeric.

    Bakes the leaf ``arith.constant`` and records it in ``_meta_uses``
    (if leaf), or returns the cached IR (if derived from arithmetic).
    Wraps the resulting ``ir.Value`` in Boolean / Int32 / Float32 based
    on the Python type of the wrapped value, so downstream DSL APIs
    (``cute.printf`` etc.) see a familiar Numeric.
    """
    ir_val = watched.ir_value()
    py = watched.python_value
    from .typing import Boolean, Int32, Float32

    if isinstance(py, bool):
        return Boolean(ir_val)
    if isinstance(py, int):
        return Int32(ir_val)
    if isinstance(py, float):
        return Float32(ir_val)
    return ir_val


def _describe_value_origin(raw: Any) -> str:
    """Describe where an MLIR value was defined (best-effort).

    Returns a string like ``"inside a for-loop body"`` or ``""``.
    """
    try:
        owner = raw.owner
    except Exception:
        return ""

    # Find the parent Operation that owns the region containing this value.
    # BlockArgument: owner is Block -> Block.region -> Region.owner
    # OpResult:      owner is Operation -> Operation.block -> Block.region -> Region.owner
    try:
        if isinstance(owner, ir.Block):
            parent_name = owner.region.owner.name
        elif isinstance(owner, ir.Operation):
            parent_name = owner.block.region.owner.name
        else:
            return ""
    except Exception:
        return ""

    desc = _SCF_REGION_NAMES.get(parent_name, f"a `{parent_name}` region")
    return f"inside {desc}"


# ---------------------------------------------------------------------------
# Ref placement helpers
# ---------------------------------------------------------------------------

_FUNC_OPS = frozenset(("func.func", "gpu.func", "cuda.kernel", "llvm.func"))


def _auto_promote_primitive(value: object) -> object | None:
    """Promote a Python ``bool``/``int``/``float`` to the matching DSL type.

    Uses ``as_numeric`` from ``typing.py``:
    ``bool`` → ``Boolean``, ``int`` → ``Int32`` (``Int64`` for large),
    ``float`` → ``Float32``.

    Returns ``None`` on failure (import error, unsupported value).
    """
    try:
        from .typing import as_numeric

        return as_numeric(value)
    except (ImportError, TypeError, ValueError):
        return None


def _can_create_ref(value: object) -> bool:
    """Return True if *value*'s type supports ``pyir.ref`` tracking.

    Only types with ``_pyir_ref_supported = True`` can round-trip through
    ``MutableValue``: ``Type(ir_value)`` must be a valid single-arg
    constructor.  Numeric types (Int32, Float32, Boolean, CuTe Pointer)
    set this.  Non-scalar types (Array, Tensor, TensorMap) do not.
    """
    return getattr(type(value), "_pyir_ref_supported", False)


def _is_vector_like(value: object) -> bool:
    """Return True if *value* is a multi-element MLIR vector type.

    Vectors are ``_pyir_ref_supported`` (they round-trip via
    ``Vector(ir_value)``), but creating first-def refs for them can
    cause issues when they are subsequently stored into dicts or passed
    across MLIR region boundaries.  The reassignment path handles them
    correctly when the old value already exists.
    """
    try:
        ir_val = value.ir_value()  # type: ignore[attr-defined]
        return isinstance(ir_val.type, ir.VectorType)
    except Exception:
        return False


def _is_memref_like(value: object) -> bool:
    """Return True if *value* is backed by a memref/tensor-descriptor SSA value
    (e.g. a ``cute._Tensor``).

    Such a value is a *descriptor* (pointer + layout), recomputable wherever it
    dominates.  Inside a nested region the normal Case-D path would put a
    ``ub.poison``-init ref at the function entry block; for a memref that poison
    leaks across sibling regions (the P89 regression).  These values dominate the
    current IP, so the ref can simply be placed there instead.

    Detection is declarative: the value's type opts in via the class attribute
    ``_pyir_memref_backed`` (``cute._Tensor`` sets it).  ``base_dsl`` stays
    decoupled from the cute dialect -- no import of, or string-matching against,
    cute's MLIR type names.  Builtin ``memref`` values are also accepted via a
    structural ``isinstance`` check.
    """
    if getattr(type(value), "_pyir_memref_backed", False):
        return True
    try:
        return isinstance(value.ir_value().type, ir.MemRefType)  # type: ignore[attr-defined]
    except Exception:
        return False


def _mlir_type_or_none(value: object) -> "ir.Type | None":
    """Return *value*'s MLIR type, or ``None`` if it has no SSA backing."""
    try:
        return value.ir_value().type  # type: ignore[attr-defined]
    except Exception:
        return None


def _staged_type_changed(old_value: object, new_value: object) -> bool:
    """Return True when a same-name reassignment changes the MLIR type.

    A ``pyir.ref`` has an element type that is fixed at creation.  When a
    same-name local is reassigned to a value of a DIFFERENT MLIR type
    inside staged CF (e.g. ``v = v.to(other_dtype)`` or a vector recast
    ``vector<8xf4> -> vector<4xi8>``), the ref created for the old value
    can no longer hold the new one: ``pyir.store``/``pyir.load`` would
    round-trip the OLD type and downstream uses read a stale-typed value.
    Detecting the change lets the reassignment path drop the old ref and
    create a fresh one typed to the new value.

    Both operands must have an MLIR type for the comparison to be
    meaningful; if either is unavailable we conservatively report "no
    change" so the legacy ref-reuse path is preserved.
    """
    old_ty = _mlir_type_or_none(old_value)
    new_ty = _mlir_type_or_none(new_value)
    if old_ty is None or new_ty is None:
        return False
    return old_ty != new_ty


def _is_boolean_like(value: object) -> bool:
    """Return True if *value* is a 1-bit integer (i1/Boolean) type.

    Boolean first-defs (e.g. ``cond = i > 2``) are almost always used
    once as an ``scf.if`` condition and never modified.  Creating an
    eager first-def ``pyir.ref`` for them produces a dead ref that the
    C++ ``PYIRToSCF`` pass turns into a spurious iter_arg with a
    duplicate ``scf.yield``, breaking MLIR verification.

    The reassignment path still handles booleans correctly when an
    existing ``_mutable_ref`` is already attached (from being modified
    inside control flow).
    """
    try:
        ir_val = value.ir_value()  # type: ignore[attr-defined]
        return isinstance(ir_val.type, ir.IntegerType) and ir_val.type.width == 1
    except Exception:
        return False


def _is_literal_backed(dsl_value: object) -> bool:
    """Return True if *dsl_value* stores a Python scalar (not an ir.Value).

    Literal-backed values produce a fresh ``arith.constant`` on every
    ``ir_value()`` call, so ``pyir.ref`` can be placed at block_begin
    without dominance issues.  SSA-backed values return an existing
    ``ir.Value`` which must dominate the ref insertion point.
    """
    return isinstance(getattr(dsl_value, "value", None), (bool, int, float))


# Count of ``ub.poison`` ops built by ``_make_poison_like`` — the ONLY
# Python-layer producer of ``ub.poison`` — since the last verify boundary.
# ``_verify_no_used_poison`` walks the whole module looking for used poison;
# while this counter is zero no module can contain one, so the walk (which
# runs on EVERY compile, pyir or classic) is skipped.  The verifier consumes
# the counter at its boundary so later poison-free compiles in the same
# process keep the fast path (traces are sequential in-process).
_POISON_EMITTED: int = 0


def _make_poison_like(dsl_value: Any, ir_val: "ir.Value") -> Any:
    """Create a ``ub.poison`` value of the same type as *dsl_value*.

    Used by ``_create_ref`` Case D-fallback when the original SSA value
    does not dominate the current insertion point.  The poison signals
    deferred undefined behaviour: the caller MUST ``store`` a real value
    before any ``load``.  If that contract is ever failed, the poison
    makes the bug visible instead of silently returning zero.

    *ir_val* is the already-computed ``dsl_value.ir_value()`` — used
    only for its type.

    Records the (filename, lineno) of the first non-DSL caller as MLIR
    attributes on the poison op so the end-of-trace poison-read catcher
    can render an actionable diagnostic even when the MLIR ``loc()`` was
    stripped.

    When the ``ub`` dialect is unavailable, falls back to a zero constant
    of the matching type.
    """
    if ub is None:
        ir_type = ir_val.type
        if ir_type == ir.IntegerType.get_signless(1):
            return type(dsl_value)(False)
        if isinstance(ir_type, ir.IntegerType):
            return type(dsl_value)(0)
        return type(dsl_value)(0.0)
    global _POISON_EMITTED
    _POISON_EMITTED += 1
    poison_ir = ub.PoisonOp(ir_val.type).result
    _record_poison_source(poison_ir)
    return type(dsl_value)(poison_ir)


def _record_poison_source(poison_value: "ir.Value") -> None:
    """Stash the first pure Python caller location as MLIR attributes
    on the freshly-created ``ub.poison`` op, so the end-of-trace catcher
    can render an actionable diagnostic regardless of MLIR loc info.

    "DSL-internal" is determined by the top-level component of each
    frame's module ``__name__``: any frame whose module shares this
    file's top-level package is skipped.  The import system sets
    ``__name__`` from how the module was imported, not from a filesystem
    path — so this works identically under pip install, build symlinks,
    in-source dev, and any CI runner without any hardcoded paths.
    Tests run as ``__main__`` and user kernels as their own module names;
    neither shares the DSL's top-level, so both are correctly reported.
    """
    dsl_top_level = __name__.split(".", 1)[0]
    for frame_info in inspect.stack()[1:]:
        mod_name = frame_info.frame.f_globals.get("__name__", "")
        if mod_name == dsl_top_level or mod_name.startswith(dsl_top_level + "."):
            continue
        try:
            poison_op = poison_value.owner
            poison_op.attributes["pyir.poison_src_file"] = ir.StringAttr.get(
                frame_info.filename
            )
            poison_op.attributes["pyir.poison_src_line"] = ir.IntegerAttr.get(
                ir.IntegerType.get_signless(32), frame_info.lineno
            )
        except (AttributeError, TypeError):
            pass
        return


def _get_defining_operation(ir_val: ir.Value) -> ir.Operation:
    """Return the ``ir.Operation`` that defines an ``OpResult``."""
    owner = ir_val.owner
    return getattr(owner, "operation", owner)


def _get_function_entry_block() -> ir.Block | None:
    """Walk up from the current insertion point to find the enclosing
    function-like op's entry block.

    Returns the entry block, or ``None`` if no function is found.
    Naturally respects ``IsolatedFromAbove`` — stops at the nearest
    function boundary (``func.func``, ``gpu.func``, ``cuda.kernel``).
    """
    try:
        block = ir.InsertionPoint.current.block
    except Exception:
        return None

    while block is not None:
        try:
            parent = block.owner  # Block → Python dialect op
        except Exception:
            break
        op = getattr(parent, "operation", parent)  # → ir.Operation

        if str(op.name) in _FUNC_OPS:
            return op.regions[0].blocks[0]

        try:
            block = op.block  # ir.Operation → parent Block
        except Exception:
            break

    return None


def _create_ref(dsl_value: Any) -> "MutableValue":
    """Create a ``MutableValue`` + ``pyir.ref`` with correct placement.

    Placement strategy (4 cases, most optimal to most conservative):

    **Case A** — Literal-backed (``self.value`` is ``int/float/bool``):
        Place at function entry block begin.  ``ir_value()`` creates a
        fresh ``arith.constant``, so dominance is guaranteed.

    **Case B** — Block argument of the entry block (e.g., function param):
        Place at function entry block begin.  Block arguments dominate
        everything in their block by MLIR semantics.

    **Case C** — OpResult defined in the entry block (e.g., ``a + b``):
        Place immediately after the defining op via
        ``InsertionPoint.after(defining_op)``.  The operand is defined
        right before the ref.

    **Case D** — Everything else (loop induction var, value from nested CF):
        Place at current insertion point.  The value normally dominates
        the current point because we are using it in Python.

    **Case D-fallback** — Value from a sibling scope (e.g., stale SSA
        from a previous task's ``scf.while`` that was set via Python
        attribute mutation):
        The SSA value no longer dominates the current insertion point.
        Create a ``ub.poison``-initialised ref at the function entry
        block so it is accessible from every scope.  The caller will
        immediately ``store`` the correct value; the poison makes any
        accidental pre-store load visible as UB rather than a silent
        wrong result.
    """
    entry_block = _get_function_entry_block()

    if entry_block is not None:
        # Case A: literal-backed → fresh constant at entry block begin
        if _is_literal_backed(dsl_value):
            with ir.InsertionPoint.at_block_begin(entry_block):
                mv = MutableValue(dsl_value)
                mv.take_reference()
            return mv

        ir_val = dsl_value.ir_value()

        # Case B: block argument of entry block
        # Use owner type to distinguish: Block→BlockArgument, Operation→OpResult.
        # Python isinstance on ir_val is unreliable because DSL wrapper types
        # (e.g. ArithValue) extend Value directly, not BlockArgument/OpResult.
        owner = ir_val.owner
        if isinstance(owner, ir.Block):
            if owner == entry_block:
                with ir.InsertionPoint.at_block_begin(entry_block):
                    mv = MutableValue(dsl_value)
                    mv.take_reference()
                return mv
            # Block arg of a nested block (e.g., loop IV) → Case D

        else:
            # Case C: OpResult defined in entry block → after defining op
            defining_op = getattr(owner, "operation", owner)
            if defining_op.block == entry_block:
                with ir.InsertionPoint.after(defining_op):
                    mv = MutableValue(dsl_value)
                    mv.take_reference()
                return mv

    # Determine the block where the value is defined.
    # BlockArgument → owner is Block.  OpResult → owner is Operation.
    # NOTE: ir.Block does not support `is` identity comparison; each
    # attribute access creates a new Python wrapper.  Use `==` instead.
    owner = ir_val.owner
    if isinstance(owner, ir.Block):
        defining_block = owner
    else:
        defining_op = getattr(owner, "operation", owner)
        defining_block = defining_op.block

    if entry_block is not None and pyir is not None:
        current_block = ir.InsertionPoint.current.block

        if pyir.is_value_in_ancestor_region(ir_val, current_block):
            # Value dominates current IP.  Check if we are in a NESTED
            # region (e.g., inside scf.if) relative to the defining block.
            # If so, placing the ref at the current IP traps it in that
            # region — the topk bug.  Use poison-init ref at function
            # entry + store after the defining op instead.
            #
            if defining_block != current_block and _is_memref_like(dsl_value):
                log().info(
                    "[_create_ref] Case D: memref descriptor → ref at current "
                    "IP (no entry-block poison)"
                )
                mv = MutableValue(dsl_value)
                mv.take_reference()
                return mv

            if defining_block != current_block:
                log().info(
                    "[_create_ref] Case D: poison-init ref at entry "
                    "block + store after defining op (nested region)"
                )
                with ir.InsertionPoint.at_block_begin(entry_block):
                    poison_dsl = _make_poison_like(dsl_value, ir_val)
                    mv = MutableValue(poison_dsl)
                    mv.take_reference()
                # Store the real value after its defining op, NOT at the
                # current IP (which is inside a nested scf.if).
                if isinstance(owner, ir.Block):
                    with ir.InsertionPoint.at_block_begin(defining_block):
                        mv.store(dsl_value)
                else:
                    with ir.InsertionPoint.after(defining_op):
                        mv.store(dsl_value)
                # TODO: After tracing both branches of an scf.if, verify
                # that every poison-initialized ref was stored to in both
                # branches.  If not, raise DSLUserCodeError.  This requires
                # tracking which refs were created with poison init and
                # which branches stored to them — complex enough to defer.
                return mv

            log().info("[_create_ref] Case D: ref at current IP (same block)")
            mv = MutableValue(dsl_value)
            mv.take_reference()
            return mv

        # D-fallback: value does NOT dominate the current insertion point.
        # This happens when a Python attribute carries a stale SSA from a
        # sibling scope (e.g., task 1's scf.while value used in task 2's
        # scf.while).  Create a poison-initialised ref at function entry
        # so it is accessible from every scope.  The caller will
        # immediately store the correct value.
        log().info(
            "[_create_ref] Case D-fallback: value does not dominate "
            "current IP → poison-init ref at entry block"
        )
        with ir.InsertionPoint.at_block_begin(entry_block):
            poison_dsl = _make_poison_like(dsl_value, ir_val)
            mv = MutableValue(poison_dsl)
            mv.take_reference()
        return mv

    mv = MutableValue(dsl_value)
    mv.take_reference()
    return mv


# ----------------------------------------------------------------------
# Slot MutableValue storage.
#
# MutableValues for dict / list / non-__dict__ / non-weakref-able owners are
# keyed by ``_make_slot_key(None, owner, slot_name)`` into the shared
# ``_slot_mvs`` table (see pyir_state.py) -- the same keying used by
# ``_slot_refs`` / ``_meta_uses``.  ``_make_slot_key`` pins the owner via
# ``_pinned_owners`` so id(owner) stays stable for the trace, so no separate
# finalizer is needed.  ``__dict__``-backed objects use per-object tier-1 /
# tier-2 storage instead (see ``_get_slot_mv``).
# ----------------------------------------------------------------------


def _pyir_lookup_slot_from_value(value: "Any") -> "MutableValue | None":
    """Find the ``MutableValue`` that most recently produced *value* via ``.load()``.

    Cheap path: consult ``value._mutable_ref`` directly (still the
    authoritative tag for staged DSL values).  Returns ``None`` when
    *value* is not slot-backed, so callers can route through the
    plain-Python path with no auto-load.

    Used by the cutlass_dsl post-loop bridge and by
    ``_pyir_value_tracked_by_accessible_ref`` (the op-build dominance
    check).  The deliberately narrow contract (no registry-scan
    fallback) keeps lookups O(1) and rules out ambiguous matches when
    two slots share the same ``_load_version``.
    """
    if getattr(value, "_pyir_load_version", None) is None:
        return None
    return getattr(value, "_mutable_ref", None)


def _pyir_value_tracked_by_accessible_ref(value: "Any") -> bool:
    """Whether *value* is backed by a slot whose ``pyir.ref`` is reachable
    from the current insertion point.

    Used by the op-build dominance check (``_mlir_helpers/op.py``)
    to skip values whose data flow ``convert-pyir-to-scf`` will thread
    through ``scf`` iter_args -- those don't need a per-call dominance
    audit because the lowering pass already maintains SSA dominance.
    """
    mv = _pyir_lookup_slot_from_value(value)
    if mv is None:
        return False
    if getattr(mv, "ref", None) is None:
        return False
    return mv._is_ref_accessible()


# ---------------------------------------------------------------------------
# D1 helpers — retroactive promotion of M values
# ---------------------------------------------------------------------------


def _load_as_dsl(ref: "ir.Value", sample: Any) -> Any:
    """Emit ``pyir.load(ref)`` and wrap in a DSL Numeric matching *sample*.

    Used by D1's promotion path to return a freshly-loaded staged value
    once a slot has been promoted to ``pyir.ref``.  *sample* drives the
    output type:

    - Python primitive (bool/int/float) -> Boolean / Int32 / Float32.
    - ``_WatchedM`` wrapper -> dispatch by its ``python_value`` type.
    - DSL Numeric -> rewrap via ``type(sample)(loaded_ir)``.
    - Fallback: raw ``ir.Value``.

    Attaches a ``_mutable_ref`` (synthetic ``MutableValue``) carrying the
    D1 ref so ``_pyir_auto_load_arg`` at downstream ``@dsl_user_op``
    boundaries re-emits ``pyir.load`` at the current insertion point.
    Without this, a value loaded inside a for-body would carry stale SSA
    after the body exits and post-CF uses would fail dominance.
    """
    if pyir is None:
        return None
    loaded_ir = pyir.load(ref)
    from .typing import Boolean, Int32, Float32, Numeric

    py_sample = sample
    if isinstance(py_sample, _WatchedM):
        py_sample = py_sample.python_value

    dsl_val: Any
    if isinstance(py_sample, bool):
        dsl_val = Boolean(loaded_ir)
    elif isinstance(py_sample, int) and not isinstance(py_sample, bool):
        dsl_val = Int32(loaded_ir)
    elif isinstance(py_sample, float):
        dsl_val = Float32(loaded_ir)
    elif isinstance(py_sample, Numeric):
        try:
            dsl_val = type(py_sample)(loaded_ir)
        except Exception:
            return loaded_ir
    else:
        return loaded_ir

    # Synthetic MutableValue so _pyir_auto_load_arg can re-load.
    try:
        mv = MutableValue(dsl_val)
        mv._ref = ref
        mv._ref_context_id = id(ir.Context.current)
        _attach_mutable_ref(dsl_val, mv, "D1 _load_as_dsl")
    except Exception:
        pass  # attach failure is non-fatal; value still works inside CF
    return dsl_val


def _ancestor_op_in_block(
    op: "ir.Operation", target_block: "ir.Block | None"
) -> "ir.Operation":
    """Return *op* or its nearest ancestor whose containing block is
    *target_block*.

    Used to hoist a per-iteration reset store out of a NESTED runtime loop
    (where the earliest baked use lives) up to the block where the slot was
    first-defined.  Walks the op→block→owner-op chain (the same idiom as
    ``_get_function_entry_block``).  Falls back to *op* unchanged when
    *target_block* is ``None`` or is not an ancestor (so behaviour matches
    the pre-fix "insert before first use" placement).

    The walk terminates naturally: climbing op→block→owner-op always heads
    toward the top of the IR, where the module op has no containing block
    and ``cur.block`` raises.
    """
    if target_block is None:
        return op
    cur = op
    while cur is not None:
        try:
            blk = cur.block  # ir.Operation -> containing Block
        except Exception:
            break  # top of the IR tree: no containing block
        if blk == target_block:
            return cur
        try:
            parent = blk.owner  # Block -> owning op
            cur = getattr(parent, "operation", parent)
        except Exception:
            break
    return op


def _slot_store_for_tier1(
    owner: object, *, create: bool = False
) -> "dict[Any, MutableValue] | None":
    """Return the tier-1 ``__pyir_slots__`` dict on *owner*, or ``None``.

    Tier-1 storage lives on ``owner.__dict__``. If *owner* does not have a
    writable ``__dict__`` (built-in types, ``__slots__``-only classes,
    ``dict`` / ``list``), return ``None``.  When *create* is ``True`` a
    fresh dict is installed via ``object.__setattr__`` so it bypasses
    ``@dataclass(frozen=True)``.
    """
    owner_dict = getattr(owner, "__dict__", None)
    if owner_dict is None:
        return None
    store = owner_dict.get(_SLOT_STORE_ATTR)
    if store is None:
        if not create:
            return None
        store = {}
        try:
            object.__setattr__(owner, _SLOT_STORE_ATTR, store)
        except (AttributeError, TypeError):
            return None
    return store


def _slot_store_for_tier2(
    owner: object, *, create: bool = False
) -> "dict[Any, MutableValue] | None":
    """Return the tier-2 fallback entry for *owner*, or ``None``.

    Uses a module-level ``WeakKeyDictionary``.  If *owner* cannot be
    weakref'd (``dict``, ``list``, many built-ins), returns ``None``.
    """
    try:
        store = _PYIR_SLOT_FALLBACK.get(owner)
    except TypeError:
        # Unhashable owners -- can't key into a WeakKeyDictionary.
        return None
    if store is None:
        if not create:
            return None
        store = {}
        try:
            _PYIR_SLOT_FALLBACK[owner] = store
        except TypeError:
            # Not weakref-able (e.g. dict, list).  Skip tier 2 silently.
            return None
    return store


def _slot_storage_available(owner: Any) -> bool:
    """Return True if *owner* can host slot storage.

    ``__dict__``-backed objects use tier-1 / tier-2 storage; ``dict`` /
    ``list`` / non-weakref-able owners fall through to ``_slot_mvs``.
    Every non-``None`` owner has SOME storage path available.
    """
    return owner is not None


def _registry_owner(owner: Any) -> bool:
    """Return True if *owner*'s slots are routed through ``_slot_mvs``
    (dict / list / non-weakrefable / non-``__dict__`` types).  Regular
    ``__dict__`` objects use tier-1 / tier-2 storage.
    """
    if owner is None:
        return False
    if getattr(owner, "__dict__", None) is not None:
        return False
    try:
        import weakref as _wr

        _wr.ref(owner)
    except TypeError:
        return True
    return False


def _get_slot_mv(owner: Any, slot_name: Any) -> "MutableValue | None":
    """Look up the ``MutableValue`` bound to ``(owner, slot_name)``.

    ``_slot_mvs`` for dict / list owners (id-keyed); tier-1 /
    tier-2 storage for ``__dict__``-backed objects.  Returns ``None``
    when the slot has no recorded ``MutableValue``.
    """
    if owner is None:
        return None
    if _registry_owner(owner):
        return _slot_mvs.get(_make_slot_key(None, owner, slot_name))
    store = _slot_store_for_tier1(owner)
    if store is not None:
        mv = store.get(slot_name)
        if mv is not None:
            return mv
    store = _slot_store_for_tier2(owner)
    if store is not None:
        return store.get(slot_name)
    return None


def _set_slot_mv(owner: Any, slot_name: Any, mv: "MutableValue") -> None:
    """Record *mv* as the ``MutableValue`` for ``(owner, slot_name)``.

    Routes dict / list owners through ``_slot_mvs``; other owners
    use tier-1 / tier-2 storage as before.  See :func:`_get_slot_mv` for
    the rationale.
    """
    if owner is None:
        return
    if _registry_owner(owner):
        _slot_mvs[_make_slot_key(None, owner, slot_name)] = mv
        return
    store = _slot_store_for_tier1(owner, create=True)
    if store is not None:
        store[slot_name] = mv
        return
    store = _slot_store_for_tier2(owner, create=True)
    if store is not None:
        store[slot_name] = mv


def _clear_slot_mv(owner: Any, slot_name: Any) -> None:
    """Remove the recorded ``MutableValue`` for ``(owner, slot_name)``.

    Reserved for future teardown; not required by the v1 fix.  Silently
    does nothing when the slot has no entry.
    """
    if owner is None:
        return
    if _registry_owner(owner):
        _slot_mvs.pop(_make_slot_key(None, owner, slot_name), None)
        return
    store = _slot_store_for_tier1(owner)
    if store is not None:
        store.pop(slot_name, None)
    store = _slot_store_for_tier2(owner)
    if store is not None:
        store.pop(slot_name, None)


def _iter_slot_mvs_for_pyir_read(
    owner: Any,
) -> "list[tuple[Any, MutableValue]]":
    """Yield ``(slot_name, MutableValue)`` pairs registered for *owner*.

    Combines tier-1 (``owner.__dict__``) and tier-2 (``WeakKeyDictionary``).
    Tier-1 entries take precedence: if the same slot name appears in both
    tiers, only the tier-1 entry is returned (matches ``_get_slot_mv``'s
    lookup order).  Returns an empty list when no slots are registered or
    when *owner* cannot hold slot storage.

    Used by ``pyir_read`` to refresh each registered slot on a
    slot-tracked Python object before the caller (e.g. a while
    before-block ``pyir_read("work_tile", work_tile)``) re-reads an
    attribute via a ``@property`` getter.  Without this, the property
    would return the construction-time cached SSA, missing any cross-
    region writes.
    """
    if owner is None:
        return []
    result: list[tuple[Any, "MutableValue"]] = []
    seen: set[Any] = set()
    store = _slot_store_for_tier1(owner)
    if store is not None:
        for k, mv in store.items():
            result.append((k, mv))
            seen.add(k)
    store = _slot_store_for_tier2(owner)
    if store is not None:
        for k, mv in store.items():
            if k not in seen:
                result.append((k, mv))
    return result


def _attach_mutable_ref(obj: object, mv: "MutableValue", context: str) -> None:
    """Attach *mv* as ``_mutable_ref`` on *obj*.

    Silently logs (but does not raise) when the object does not accept
    arbitrary attributes (e.g. built-in types, ``__slots__`` without
    the attribute).
    """
    try:
        object.__setattr__(obj, "_mutable_ref", mv)
    except (AttributeError, TypeError):
        log().info(
            "could not attach _mutable_ref to %s (%s)",
            type(obj).__name__,
            context,
        )


def _fresh_wrapper(dsl_value: Any) -> Any:
    """Return a fresh DSL wrapper around the same backing value as *dsl_value*.

    Used by ``pyir_assign`` at first-def to give each Python local a
    distinct wrapper object. Without this, ``a = b = c = seed`` would
    bind three locals to the same Python object, and the value-keyed
    ``_mutable_ref`` cache used for ``ast.Name`` targets (which have no
    storage owner for slot-keyed identity) would collapse onto a single
    ``pyir.ref`` -- the last writer of ``seed._mutable_ref`` wins.

    Preserves the literal-vs-SSA backing so that ``_create_ref`` placement
    rules (Case A for literals, Case C for SSA) behave identically to the
    original wrapper.

    Returns *dsl_value* unchanged on any failure (non-staged value,
    type with no single-arg constructor, etc.). Callers must continue
    to treat the return value as semantically equivalent to *dsl_value*.
    """
    # Literal-backed Numeric values (Int32(0), Float32(1.5), ...): build a
    # fresh wrapper from the raw Python scalar so the new wrapper is also
    # literal-backed. Materializing via ``ir_value()`` would emit an
    # ``arith.constant`` eagerly and demote the wrapper to SSA-backed,
    # which changes _create_ref placement (Case A → Case C) and shifts
    # ref ordering in the IR.
    if _is_literal_backed(dsl_value):
        try:
            return type(dsl_value)(dsl_value.value)
        except Exception:
            return dsl_value

    try:
        ir_val = dsl_value.ir_value()
    except Exception:
        return dsl_value

    # Mirror MutableValue._reconstruct's strategy ladder so this works
    # for compound types (Array, TensorSSA) as well as scalars.
    if hasattr(dsl_value, "__new_from_mlir_values__"):
        try:
            return dsl_value.__new_from_mlir_values__([ir_val])
        except Exception:
            pass

    shape = getattr(dsl_value, "_shape", None)
    if shape is not None:
        dtype = getattr(dsl_value, "_dtype", None)
        try:
            return type(dsl_value)(ir_val, shape, dtype)
        except Exception:
            pass

    try:
        return type(dsl_value)(ir_val)
    except Exception:
        return dsl_value


# ==========================================================================
# MutableValue — internal bookkeeping for pyir.ref / pyir.load / pyir.store
# ==========================================================================


class MutableValue:
    """Wraps a single leaf DSL value and holds the ``pyir.ref`` handle.

    The owning DSL type (Numeric) calls ``take_reference()``,
    ``load()``, and ``store()`` explicitly — MutableValue is never
    exposed to user code and never participates in operator dispatch.
    """

    __slots__ = ("_value", "_type", "_ref", "_ref_context_id", "_load_version")

    def __init__(self, value: Any) -> None:
        if isinstance(value, (bool, int, float)):
            raise DSLRuntimeError(
                f"Cannot create a mutable reference for Python scalar "
                f"`{value}` (type: {type(value).__name__}).",
                suggestion=(
                    "Convert to a DSL type first, e.g. "
                    "cutlass.Int32(...) or cutlass.Float32(...)."
                ),
            )

        self._value = value
        self._type = type(value)
        self._ref = None  # populated by take_reference()
        self._ref_context_id: int | None = None
        # Bumped on every load()/store(); used to dedup redundant
        # auto-loads in ``_pyir_auto_load_arg``.  A DSL value carrying
        # ``_pyir_load_version`` equal to the current ``_load_version``
        # is the freshest load and need not be reloaded.
        self._load_version: int = 0

    def take_reference(self) -> None:
        """Create a ``pyir.ref`` for the current value.

        Always creates a new ref.  Caller should check
        ``_is_ref_accessible()`` before calling if reuse is desired.
        """
        ir_val = self._value.ir_value()
        self._ref = pyir.ref(ir_val)
        self._ref_context_id = id(ir.Context.current)

    def _is_ref_accessible(self) -> bool:
        """Return ``True`` if the existing ref is accessible from the
        current insertion point (same or ancestor region)."""
        if self._ref is None:
            return False
        if self._ref_context_id != id(ir.Context.current):
            return False
        current_block = ir.InsertionPoint.current.block
        return pyir.is_value_in_ancestor_region(self._ref, current_block)

    def _reconstruct(self, loaded_ir: Any) -> Any:
        """Reconstruct a DSL value from a loaded MLIR value.

        For simple types (Int32, Float32, Boolean), ``Type(ir_value)``
        works.  Complex types like ``Array`` or ``TensorSSA`` need
        extra metadata (dtype, shape) that a bare ir.Value doesn't
        carry.  We try three strategies in order:

        1. ``__new_from_mlir_values__`` — the extractable protocol used
           by Array and similar compound types.  Preserves all
           internal state (dtype, shape, strides, alignment, etc.).
        2. Constructor with ``_shape``/``_dtype`` kwargs — for types
           like TensorSSA that store metadata as instance attributes
           and accept them as constructor kwargs.
        3. Simple ``Type(ir_value)`` — works for Numeric types (Int32,
           Float32, Boolean, etc.).
        """
        orig = self._value

        # Strategy 1: extractable protocol (Array, etc.)
        if hasattr(orig, "__new_from_mlir_values__"):
            try:
                return orig.__new_from_mlir_values__([loaded_ir])
            except Exception:
                pass  # fall through

        # Strategy 2: replay constructor with shape/dtype metadata
        # (TensorSSA, Vector, etc.)
        shape = getattr(orig, "_shape", None)
        if shape is not None:
            dtype = getattr(orig, "_dtype", None)
            try:
                return self._type(loaded_ir, shape, dtype)
            except Exception:
                pass  # fall through

        # Strategy 3: simple single-arg constructor
        return self._type(loaded_ir)

    def load(self) -> Any:
        """Emit ``pyir.load`` and return a fresh DSL value.

        Tags the returned value with ``_pyir_load_version`` -- the dedup
        tag ``_pyir_auto_load_arg`` checks to skip a redundant auto-load,
        and the presence tag ``_pyir_lookup_slot_from_value`` requires
        before returning the value's ``_mutable_ref``.

        NOTE: ``_mutable_ref`` is intentionally NOT attached here.  Callers
        that need ref-attachment (``pyir_assign``, ``pyir_read`` with
        ``attach_ref=True``) do so explicitly via ``_attach_mutable_ref``
        after their own slot-aliasing decisions.  Auto-attaching here
        would break ``clone()``-style snapshots that deliberately use
        ``attach_ref=False`` to prevent ref leakage across object
        boundaries.
        """
        assert self._ref is not None, (
            "MutableValue.load: no ref -- call take_reference() first"
        )
        loaded_ir = pyir.load(self._ref)
        self._load_version += 1
        loaded = self._reconstruct(loaded_ir)
        try:
            object.__setattr__(loaded, "_pyir_load_version", self._load_version)
        except (AttributeError, TypeError):
            pass  # value type doesn't accept attrs — no dedup, fine.
        return loaded

    def store(self, new_value: Any) -> None:
        """Emit ``pyir.store`` to write *new_value* into the ref."""
        assert self._ref is not None, (
            "MutableValue.store: no ref -- call take_reference() first"
        )
        pyir.store(new_value.ir_value(), self._ref)
        self._value = new_value
        # Invalidate any previously-loaded values: subsequent uses must
        # reload to observe the new value.
        self._load_version += 1

    @property
    def ref(self) -> ir.Value | None:
        """The raw ``pyir.ref`` SSA value (or ``None``)."""
        return self._ref

    def __repr__(self) -> str:
        return f"MutableValue({self._value!r})"


# ==========================================================================
# M→M compound auto-decomposition helpers
# ==========================================================================


def _get_instance_attrs(obj: object) -> list[str]:
    """Return instance attribute names from ``__dict__``.

    Skips dunders.  Uses ``__dict__`` (NOT ``getmembers``) to avoid
    class-level properties and methods — only instance storage attributes.
    """
    if not hasattr(obj, "__dict__"):
        return []
    return [name for name in obj.__dict__ if not name.startswith("__")]


def _is_compound_single_leaf(value: object) -> bool:
    """Return True if *value* is a ref-supported value that is itself a COMPOUND
    holding a staged ref-supported SEMANTIC sub-field (e.g. ``cute._Tensor``,
    whose ``_iterator`` is a staged ``Pointer``).

    Such a value has a single MLIR leaf (its memref) yet is NOT a plain scalar:
    threading it as a FIELD of a whole-replaced container is unsupported -- the
    per-field ref it creates does not survive loop iter_args, silently dropping
    the field's loop-carried value.  A container holding such a field must fall
    back to the clean ``CONTAINER_OBJECT_REPLACED`` rejection.  (P89's top-level
    whole-replace of a ``_Tensor`` itself takes the S->S path and is unaffected
    by this check.)

    Scalar ref leaves (``Int32``/``Float32``/``Boolean``/``Pointer``/``Vector``)
    return False: their only instance attribute is the raw MLIR ``value`` (not a
    staged DSL value).  The check deliberately ignores the ``_mutable_ref``
    plumbing attribute -- a scalar that has been through decomposition once
    carries a ``MutableValue`` there, which must NOT make it look compound.
    """
    if not (_is_staged_value(value) and _can_create_ref(value)):
        return False
    if not hasattr(value, "__dict__"):
        return False
    for attr_name in _get_instance_attrs(value):
        # Skip the scalar's own MLIR leaf (``value`` -- a bare ``ir.Value`` /
        # ``ArithValue``) and the PyIR plumbing attributes.  A scalar leaf
        # (Int32/Float32/Boolean/Pointer/Vector) has NOTHING else; a compound
        # single-leaf (``cute._Tensor``) additionally holds a SEMANTIC staged
        # sub-field (``_iterator``, a ``_Pointer``) -- that is what we detect.
        if (
            attr_name == "value"
            or attr_name.startswith("_pyir_")
            or (attr_name == "_mutable_ref")
        ):
            continue
        sub = getattr(value, attr_name, None)
        if _is_staged_value(sub):
            return True
    return False


def _is_leaf_decomposable(value: object) -> bool:
    """Return True if *value* is a leaf that needs no further decomposition.

    A leaf is either a meta primitive (copied as-is) or a staged scalar
    that ``pyir_assign`` can track via ``pyir.ref``.  A ref-supported COMPOUND
    single-leaf (``cute._Tensor``) is NOT a decomposable field leaf -- see
    ``_is_compound_single_leaf``.
    """
    if value is None or isinstance(value, (int, float, bool, str, bytes)):
        return True
    if (
        _is_staged_value(value)
        and _can_create_ref(value)
        and not _is_compound_single_leaf(value)
    ):
        return True
    return False


def _check_tuple_decomposable(
    t: tuple,
    _visited: set[int],
) -> tuple[bool, bool]:
    """Check if all elements of a tuple are decomposable.

    Returns ``(ok, has_staged)``.
    """
    has_staged = False
    for elem in t:
        if _is_leaf_decomposable(elem):
            if _is_staged_value(elem) and _can_create_ref(elem):
                has_staged = True
            continue
        if isinstance(elem, tuple):
            ok, found = _check_tuple_decomposable(elem, _visited)
            if not ok:
                return False, False
            has_staged = has_staged or found
            continue
        # Compound single-leaf staged value (e.g. _Tensor): not decomposable as
        # a tuple element -- see _check_all_fields_decomposable for rationale.
        if _is_staged_value(elem):
            return False, False
        if hasattr(elem, "__dict__") and _check_all_fields_decomposable(
            elem, _visited=_visited
        ):
            has_staged = True
            continue
        return False, False
    return True, has_staged


def _check_all_fields_decomposable(
    obj: object,
    *,
    _visited: set[int],
) -> bool:
    """Return True if every instance attribute is a meta primitive,
    a staged+ref-compatible leaf, a tuple of same, or a nested compound
    of same.  At least one field must be staged.
    """
    obj_id = id(obj)
    if obj_id in _visited:
        return False
    _visited.add(obj_id)

    if not hasattr(obj, "__dict__"):
        return False

    attrs = _get_instance_attrs(obj)
    if not attrs:
        return False

    has_any_staged = False
    for attr_name in attrs:
        value = getattr(obj, attr_name)

        if _is_leaf_decomposable(value):
            if _is_staged_value(value) and _can_create_ref(value):
                has_any_staged = True
            continue

        if isinstance(value, tuple):
            ok, found_staged = _check_tuple_decomposable(value, _visited)
            if not ok:
                return False
            has_any_staged = has_any_staged or found_staged
            continue

        # A ref-supported COMPOUND single-leaf (e.g. ``cute._Tensor``, whose
        # ``_iterator`` is itself a staged Pointer) is NOT decomposable as a
        # container field: the per-field ref it creates does not survive loop
        # iter_args, silently dropping the field's loop-carried value.  Bail out
        # so the container hits the clean ``CONTAINER_OBJECT_REPLACED`` rejection
        # (P89: only a TOP-LEVEL whole-replace of a ``_Tensor`` threads, via the
        # S->S path).
        if _is_staged_value(value):
            return False

        if hasattr(value, "__dict__") and _check_all_fields_decomposable(
            value, _visited=_visited
        ):
            has_any_staged = True
            continue

        return False

    return has_any_staged


def _flatten_tuple(t: tuple) -> Any:  # Generator[Any, None, None]
    """Yield all non-tuple leaf elements from a (possibly nested) tuple."""
    for elem in t:
        if isinstance(elem, tuple):
            yield from _flatten_tuple(elem)
        else:
            yield elem


# ==========================================================================
# pyir_assign / pyir_read — AST-inserted hooks
# ==========================================================================


def _pyir_assign_simple(owner: Any, key: Any, value: Any) -> Any:
    """Simplified (owner, key, value) entry point for the unified slot
    registry.

    Registers a slot in ``_slot_mvs`` keyed on
    ``_make_slot_key(None, owner, key)`` and returns *value* unchanged.

    This entry point is intentionally side-effect-free with respect to
    MLIR IR (no ``pyir.ref`` is emitted), so it can be used outside
    ``@cute.jit`` traces -- e.g. by the unit test that runs without an
    active MLIR context.  When an MLIR context is active, production
    callers drive ``pyir_assign`` through the full 5-argument signature.
    """
    slot_key = _make_slot_key(None, owner, key)
    mv = _slot_mvs.get(slot_key)
    if mv is None:
        # Register a placeholder MutableValue.  We don't (and can't, in
        # general) emit a ``pyir.ref`` here because callers may invoke
        # this without an active MLIR context.  The placeholder gives
        # the registry the right identity; production code paths upgrade
        # it to a fully-initialised ``MutableValue`` when staged CF
        # actually needs a ref.
        mv = MutableValue.__new__(MutableValue)
        object.__setattr__(mv, "_value", value)
        object.__setattr__(mv, "_type", type(value))
        object.__setattr__(mv, "_ref", None)
        object.__setattr__(mv, "_ref_context_id", None)
        object.__setattr__(mv, "_load_version", 0)
        _slot_mvs[slot_key] = mv
    return value


# ---------------------------------------------------------------------------
# Shared side-effect-free IR-navigation substrate (no callers in this layer).
# Dominance folds into one C++ CAPI crossing (pyir.value_dominates_ip).
# ---------------------------------------------------------------------------


def _is_func_boundary_op(op_name: str) -> bool:
    """Return True if *op_name* is a function-like op that owns an SSA body
    region where a ``pyir.ref`` may be hosted.

    Matches every FunctionOpInterface op by the ``<dialect>.func`` naming
    convention plus the explicit entry ops in
    :data:`_NON_DOT_FUNC_ENTRY_OPS`. Name-pattern (not enumeration) so new
    dialect function ops need no maintenance here.
    """
    return op_name.endswith(".func") or op_name in _NON_DOT_FUNC_ENTRY_OPS


def _is_module_boundary_op(op_name: str) -> bool:
    """Return True if *op_name* is a module-like symbol-table container.

    The entry-block walk stops here: a module owns no SSA region for a
    ``pyir.ref``, and walking past it risks dereferencing recycled
    top-of-module block wrappers.
    """
    return op_name in _MODULE_OPS or op_name.endswith(".module")


def _raw_backing_ir_value(arg: Any) -> "ir.Value | None":
    """Return *arg*'s backing ``ir.Value`` WITHOUT any side effects.

    This must never invoke the value's ``ir_value()`` accessor: on
    several DSL value types (``ArithValue``, ``Vector``) ``ir_value`` is
    a ``@dsl_user_op`` whose wrapper re-runs ``_pyir_auto_load_arg`` on
    the receiver, and on ``Numeric`` it routes through ``.to(ir.Value)``
    which constructs a fresh ``@dsl_user_op`` ``ArithValue``.  Calling it
    from ``_value_dominates_current_ip`` -- itself reached *from*
    that auto-load wrapper -- creates unbounded mutual recursion that
    overflows the C stack (SIGABRT).  Instead read the already-baked SSA
    value structurally:

    - ``ArithValue`` / ``Vector`` subclass ``ir.Value`` directly.
    - ``Numeric`` stores its SSA value in ``.value`` (``ir.Value`` once
      baked; a Python primitive when still a meta constant).

    Returns ``None`` when no baked ``ir.Value`` is available; the caller
    then conservatively treats the value as not dominating and re-loads,
    which is always sound (an extra ``pyir.load``, never wrong data).
    """
    if isinstance(arg, ir.Value):
        return arg
    inner = getattr(arg, "value", None)
    if isinstance(inner, ir.Value):
        return inner
    return None


def _value_dominates_current_ip(value: Any) -> bool:
    """Return ``True`` if *value*'s backing ``ir.Value`` dominates the
    current MLIR insertion point.

    Accepts a DSL-wrapped value, a bare ``ir.Value``, or ``None``; the backing
    SSA is read via :func:`_raw_backing_ir_value` (not ``value.ir_value()``,
    which would re-enter the auto-load path that calls this and recurse).

    Used by ``_pyir_auto_load_arg`` (reuse a load vs emit a fresh one) and the
    region-escape repair (is a leaf trapped in a closed region). Conservative:
    returns ``False`` on any error, no ``pyir``, or no baked SSA, so the caller
    re-loads / repairs rather than keep a non-dominating value.

    Implemented in C++ (``pyir.value_dominates_ip``): ONE binding crossing
    folds the accessibility leg (ancestor region, ``IsolatedFromAbove``
    barriers) and the same-block ordering leg (the ancestor-region check alone
    is necessary but not sufficient -- a same-region value may be defined
    after the IP, so a same-block def must precede the IP's reference
    operation, and any same-block def counts when the IP is at the block
    end).  This probe runs per staged arg of every emitted op, so the
    step-by-step Python walk it replaces was the highest-frequency
    binding-crossing overhead of the trace.
    """
    if pyir is None:
        return False
    try:
        raw = _raw_backing_ir_value(value)
        if raw is None:
            return False
        ip = ir.InsertionPoint.current
        ref_op = ip.ref_operation
        if ref_op is not None:
            ref_op = getattr(ref_op, "operation", ref_op)
        return bool(pyir.value_dominates_ip(raw, ip.block, ref_op))
    except Exception:
        return False


def _same_ir_value(a: "ir.Value | None", b: "ir.Value | None") -> bool:
    """Whether *a* and *b* are the SAME SSA value, WITHOUT emitting IR.

    Two distinct Python wrappers can refer to one underlying MLIR value (the
    bindings re-mint a wrapper per access), so ``id()`` is unreliable; but a DSL
    ``ArithValue`` overrides ``==`` to emit an ``arith.cmpi`` (an op leaking into
    the IR at the current insertion point -- a dominance hazard).  Compare via the
    BASE ``ir.Value.__eq__`` (a nanobind pointer comparison on the C++ value),
    bypassing any subclass override.  Conservative: any error -> ``False``.
    """
    if a is None or b is None:
        return False
    try:
        return bool(ir.Value.__eq__(a, b))
    except Exception:
        return a is b


def _op_is_inside_op(op: "ir.Operation", outer_op: "ir.Operation") -> bool:
    """Return ``True`` if *op* is nested (at any depth) inside *outer_op*.

    Walks *op*'s ``parent`` chain (op -> enclosing op) comparing each ancestor
    to *outer_op*.  Uses only ``Operation.parent`` (never ``Block.region`` /
    ``Block.owner``, whose Python bindings can fault on certain blocks).
    Conservative: any error returns ``False``.
    """
    try:
        target = getattr(outer_op, "operation", outer_op)
        cur = getattr(op, "operation", op)
        while cur is not None:
            if cur == target:
                return True
            parent = cur.parent
            if parent is None:
                return False
            cur = getattr(parent, "operation", parent)
        return False
    except Exception:
        return False


def _innermost_enclosing_loop_op_at_ip() -> "ir.Operation | None":
    """Return the innermost ``scf.for`` / ``scf.while`` op enclosing the
    current insertion point, or ``None`` if there is no enclosing loop.

    Mirrors :func:`_get_function_entry_block`'s upward walk: it ascends from
    ``InsertionPoint.current`` using only the ``Block.owner`` (block -> op) and
    ``Operation.block`` (op -> parent block) navigation that is proven not to
    fault on the binding's recycled CF blocks, stops at the nearest function /
    module boundary (never walking into a recycled module-block wrapper), and
    bounds the walk by IR depth rather than an ``id()`` visited-set. Unlike
    :func:`_op_has_enclosing_loop` (which answers a yes/no question about a
    given op), this returns the loop *op* so callers can pass it to the
    ``Operation.parent``-based containment tests (:func:`_ir_value_defined_inside_op`).
    Conservative: any error -> ``None`` (caller treats the carrying loop as
    indeterminate).
    """
    try:
        block = ir.InsertionPoint.current.block
    except Exception:
        return None

    _MAX_NESTING = 256
    for _ in range(_MAX_NESTING):
        if block is None:
            return None
        try:
            parent = block.owner  # Block -> Python dialect op
        except Exception:
            return None
        op = getattr(parent, "operation", parent)  # -> ir.Operation
        try:
            op_name = str(op.name)
        except Exception:
            return None
        if op_name in ("scf.for", "scf.while"):
            return op
        # A function / module boundary owns no enclosing loop; stop rather than
        # walk into recycled top-of-region block aliasing (a SIGSEGV hazard).
        if _is_func_boundary_op(op_name) or _is_module_boundary_op(op_name):
            return None
        try:
            block = op.block  # ir.Operation -> parent Block
        except Exception:
            return None
    return None


def _loop_free_enclosing_if_ops_at_ip() -> "list[ir.Operation]":
    """Return every ``scf.if`` op enclosing the current insertion point, from
    innermost outward, stopping at the FIRST ``scf.for`` / ``scf.while`` (or a
    function / module boundary).

    Mirrors :func:`_innermost_enclosing_loop_op_at_ip`'s upward walk, using
    only the ``Block.owner`` / ``Operation.block`` navigation proven not to
    fault on recycled CF blocks. The returned list is the chain of standalone
    (loop-free) ``scf.if`` ancestors -- a caller checks each for a sibling-branch
    re-bake, since the relevant ``if`` (the mega-kernel ``if pref: ... else:
    ...``) may be an OUTER ancestor while an inner ``scf.if`` sits between it
    and the IP. An empty list means no loop-free enclosing ``scf.if``.
    Conservative: any error -> the chain collected so far.
    """
    ifs: "list[ir.Operation]" = []
    try:
        block = ir.InsertionPoint.current.block
    except Exception:
        return ifs

    _MAX_NESTING = 256
    for _ in range(_MAX_NESTING):
        if block is None:
            return ifs
        try:
            parent = block.owner
        except Exception:
            return ifs
        op = getattr(parent, "operation", parent)
        try:
            op_name = str(op.name)
        except Exception:
            return ifs
        if op_name in ("scf.for", "scf.while"):
            return ifs
        if op_name == "scf.if":
            ifs.append(op)
        if _is_func_boundary_op(op_name) or _is_module_boundary_op(op_name):
            return ifs
        try:
            block = op.block
        except Exception:
            return ifs
    return ifs


__all__ = [name for name in list(globals()) if not name.startswith("__")]
