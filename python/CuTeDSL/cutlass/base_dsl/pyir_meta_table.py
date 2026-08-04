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


"""PyIR meta-value table.

Tracks Python scalars (bool / int / float) that are read or written inside
staged control flow, so a later write can retroactively turn earlier reads
into ref loads instead of baked constants.  Holds the per-trace slot state,
the ``_WatchedM`` wrapper family, the slot-key builder (and the owner pin that
keeps slot-key identity stable), and the promotion routine.

Split out of ``pyir_runtime`` to keep that module focused on ``MutableValue`` /
``pyir_assign`` / ``pyir_read``.  ``pyir_runtime`` re-exports every name here,
so ``pyir_runtime.<name>`` keeps working for existing callers.
"""

from typing import Any, Optional
from contextlib import contextmanager
from collections.abc import Iterator

from .._mlir import ir
from .utils.logger import log

# Optional dialect -- not every consumer builds against pyir (see pyir_runtime).
try:
    from .._mlir.dialects import pyir
except ImportError:
    pyir = None

# ---------------------------------------------------------------------------
# D1 (META_VALUE_TABLE_DESIGN) state and types — retroactive promotion of M values
# ---------------------------------------------------------------------------
#
# When a Python (M) value is read inside staged control flow it is baked
# into the IR as ``arith.constant`` via the DSL value-coercion path.  If
# the same slot is later written, we must retroactively replace each
# baked constant with ``pyir.load %ref`` so the IR observes the
# mutation.  The two tables below are the bookkeeping for this:
#
#   _meta_uses[slot_key]  ->  list of arith.constant ops baked from
#                             leaf reads of that slot.  Only LEAF
#                             constants are tracked; derived arith ops
#                             live downstream via SSA edges and get
#                             rewritten automatically when the leaf is
#                             replaced.
#   _slot_refs[slot_key]  ->  pyir.ref handle once the slot has been
#                             promoted.  Subsequent reads return a
#                             fresh pyir.load wrapped in the matching
#                             DSL Numeric.
#
# Both dicts are per-function-trace and cleared at trace exit via
# ``_exit_function_trace()`` (driven from ``multi_stage_manager._jit_scope``).

_meta_uses: "dict[Any, list[ir.Value]]" = {}
_slot_refs: "dict[Any, ir.Value]" = {}
# Per-slot flag set at first-def time -- True when the slot's first
# assignment ran with ``is_inside_staged_cf() == True``.  Consulted by
# ``pyir_assign``'s D1 reassignment branch to refuse promotion when the
# user's logical semantics is "reset every iteration" (the slot was born
# inside a runtime-iterated region with a Python-literal init).
_slot_first_def_inside_cf: "dict[Any, bool]" = {}

# Staged-CF nesting depth recorded at each slot's first-def (parallel to
# ``_slot_first_def_inside_cf``).  The keep-constexpr gate keeps a
# Python-primitive toggle constexpr ONLY when the reassignment happens at
# the SAME depth as the first-def.  A strictly greater depth means the
# toggle is inside a NESTED RUNTIME loop/if entered after the first-def
# (e.g. ``scale_d`` first-def'd in an outer ``cutlass.range`` then toggled
# inside a nested ``range`` MMA-K loop) -- there the value MUST be promoted
# to a ``pyir.ref`` so the runtime loop threads it as an iter_arg.  Keeping
# it constexpr drops the iter_arg and the op reads the stale init forever
# (L103: FMHA-decode QK GEMM accumulate flag stuck at ``false``).
_slot_first_def_depth: "dict[Any, int]" = {}

# MLIR block in which each slot was first-defined (parallel to the dicts
# above).  When a deferred promotion later inserts a per-iteration reset
# store (see ``_meta_promote_slot``), the reset must land in the block
# where the user wrote the first-def -- NOT before the earliest baked use,
# which may sit inside a NESTED runtime loop entered after the first-def.
# Resetting there would re-reset the slot on every inner iteration (L103).
_slot_first_def_block: "dict[Any, Any]" = {}

# Staged-CF nesting depth recorded at EVERY local's first-def, regardless of
# value kind (primitive OR staged DSL value).  Distinct from
# ``_slot_first_def_depth`` above, which is recorded only for Python-primitive
# inits and feeds the D1 keep-constexpr gate -- overloading it would entangle
# that gate with this discriminator.
#
# Consulted by ``pyir_assign``'s straight-line type-change rebind guard: a
# same-name local reassigned to a value of a DIFFERENT MLIR type is a Rule-4
# "unstable join" violation ONLY when the prior binding crosses a staged-CF
# boundary (the prior binding pre-dates the current region, so the type would
# differ at a branch merge / loop back-edge).  When the prior binding was
# first-defined at the SAME depth as the reassignment, the two assignments are
# straight-line code (e.g. ``p = base + off`` then ``p = inttoptr(p)``); the
# type change is sequential dataflow, not a join, and is handled by the
# existing type-changing-reassignment path (a fresh ref typed to the new
# value).  Non-PyIR accepts this; PyIR must too.
_slot_first_def_depth_any: "dict[Any, int]" = {}

# A slot key embeds id(owner), and CPython reuses an object's address once it
# is freed.  If an owner is dropped mid-trace, a later object can land on the
# same address, build the identical slot key, and alias the dead owner's stale
# entries -- a wrong-result hazard.  Hold a strong reference to every owner we
# key on so it cannot be freed (and its address cannot be reused) while the
# trace is live.  Keyed by id(owner) so re-keying the same live owner overwrites
# a single entry.  Released in _exit_function_trace() when the trace ends.
_pinned_owners: "dict[int, Any]" = {}

# Slot-keyed MutableValue registry for owners that cannot host per-object slot
# storage (dict / list / non-__dict__ / non-weakref-able owners).  Keyed by the
# same ``_make_slot_key`` tuple used for ``_slot_refs`` / ``_meta_uses`` -- the
# owner is pinned via ``_pinned_owners`` so id(owner) stays stable, so this needs
# no separate finalizer.  __dict__-backed objects use per-object tier-1/tier-2
# storage instead and never land here.  Value type is ``MutableValue`` (Any here
# to avoid a circular import with pyir_runtime).  Cleared at trace exit.
_slot_mvs: "dict[Any, Any]" = {}


# Stack of USER ``@cute.jit`` function ids.  ``pyir_function_scope`` pushes one at each
# user function's entry and pops it on exit.  Preprocessor-generated
# loop-body functions do NOT push, so they inherit their enclosing user
# function's id.  This makes a frame-local slot key unique per USER function (so
# same-named locals in different functions -- e.g. ``stage_idx`` in copy_sfa and
# copy_sfb -- get DISTINCT slots) while keeping a loop-carried local (which the
# preprocessor threads through generated loop-body functions) on ONE key.
_pyir_fn_id_stack: "list[Any]" = []


@contextmanager
def pyir_function_scope(fn_id: Any) -> Iterator[None]:
    """Context manager for the current user-function scope."""
    _pyir_fn_id_stack.append(fn_id)
    try:
        yield
    finally:
        _pyir_fn_id_stack.pop()


def _current_fn_id() -> Any:
    """Id of the user function currently being traced (top of the stack), or None
    outside any tracked function."""
    return _pyir_fn_id_stack[-1] if _pyir_fn_id_stack else None


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


def _cached_ir_value_dominates_current_ip(value: "ir.Value") -> bool:
    """Whether *value* is reachable from ``InsertionPoint.current``.

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
        current_block = ir.InsertionPoint.current.block
    except (RuntimeError, ValueError):
        return True
    return pyir.is_value_in_ancestor_region(value, current_block)


def _emit_constant_at_current_ip(value: Any) -> "ir.Value":
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
        return _arith.constant(mlir_ty, value)
    if isinstance(value, int):
        mlir_ty = _ir.IntegerType.get_signless(32)
        return _arith.constant(mlir_ty, value)
    if isinstance(value, float):
        mlir_ty = _ir.F32Type.get()
        return _arith.constant(mlir_ty, value)
    # Fallback (rare): defer to the cached helper.
    from .._mlir_helpers.arith import const as _arith_const

    return _arith_const(value)


def _unwrap(value: Any) -> Any:
    """Strip a ``_WatchedM`` wrapper (one level), or return *value* as-is."""
    if isinstance(value, _WatchedM):
        return value.python_value
    return value


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

    def ir_value(self) -> "ir.Value":
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
        if cached is not None and _cached_ir_value_dominates_current_ip(cached):
            return cached
        const = _emit_constant_at_current_ip(self.python_value)
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
        """Emit an arith op and return a derived ``_WatchedM`` wrapper."""
        try:
            from .._mlir.dialects import arith as _arith
        except ImportError:
            return NotImplemented

        rhs_py = _unwrap(other)
        if not isinstance(rhs_py, (bool, int, float)):
            return NotImplemented

        py_ops = {
            "add": lambda a, b: a + b,
            "sub": lambda a, b: a - b,
            "mul": lambda a, b: a * b,
            "floordiv": lambda a, b: a // b,
            "truediv": lambda a, b: a / b,
            "mod": lambda a, b: a % b,
            "and": lambda a, b: a & b,
            "or": lambda a, b: a | b,
            "xor": lambda a, b: a ^ b,
            "lshift": lambda a, b: a << b,
            "rshift": lambda a, b: a >> b,
        }
        if op_name not in py_ops:
            return NotImplemented
        try:
            result_py = py_ops[op_name](self.python_value, rhs_py)
        except Exception:
            return NotImplemented

        try:
            lhs_ir = self.ir_value()
            if isinstance(other, _WatchedM):
                rhs_ir = other.ir_value()
            else:
                from .._mlir_helpers.arith import const as _arith_const

                rhs_ir = _arith_const(rhs_py, lhs_ir.type)
            is_float = isinstance(lhs_ir.type, ir.FloatType)
            arith_fn_table = {
                ("add", False): _arith.addi,
                ("add", True): _arith.addf,
                ("sub", False): _arith.subi,
                ("sub", True): _arith.subf,
                ("mul", False): _arith.muli,
                ("mul", True): _arith.mulf,
                ("floordiv", False): _arith.floordivsi,
                ("floordiv", True): _arith.divf,
                ("truediv", True): _arith.divf,
                ("mod", False): _arith.remsi,
                ("mod", True): _arith.remf,
                ("and", False): _arith.andi,
                ("or", False): _arith.ori,
                ("xor", False): _arith.xori,
                ("lshift", False): _arith.shli,
                ("rshift", False): _arith.shrsi,
            }
            fn = arith_fn_table.get((op_name, is_float))
            if fn is None:
                return NotImplemented
            result_ir = fn(lhs_ir, rhs_ir)
        except Exception:
            return NotImplemented

        derived = _WatchedM(result_py, slot_key=None)
        derived._cached_ir = result_ir
        return derived

    def __add__(self, other: Any) -> Any:
        return self._binop_ir(other, "add")

    def __radd__(self, other: Any) -> Any:
        if not isinstance(_unwrap(other), (bool, int, float)):
            return NotImplemented
        return _WatchedM(_unwrap(other)).__add__(self)

    def __sub__(self, other: Any) -> Any:
        return self._binop_ir(other, "sub")

    def __rsub__(self, other: Any) -> Any:
        if not isinstance(_unwrap(other), (bool, int, float)):
            return NotImplemented
        return _WatchedM(_unwrap(other)).__sub__(self)

    def __mul__(self, other: Any) -> Any:
        return self._binop_ir(other, "mul")

    def __rmul__(self, other: Any) -> Any:
        return self.__mul__(other)

    def __floordiv__(self, other: Any) -> Any:
        return self._binop_ir(other, "floordiv")

    def __mod__(self, other: Any) -> Any:
        return self._binop_ir(other, "mod")

    def __and__(self, other: Any) -> Any:
        return self._binop_ir(other, "and")

    def __or__(self, other: Any) -> Any:
        return self._binop_ir(other, "or")

    def __xor__(self, other: Any) -> Any:
        return self._binop_ir(other, "xor")

    def __lshift__(self, other: Any) -> Any:
        return self._binop_ir(other, "lshift")

    def __rshift__(self, other: Any) -> Any:
        return self._binop_ir(other, "rshift")


class _WatchedInt(_WatchedM, int):
    """Concrete D1 wrapper backed by ``int``.

    No ``__slots__`` -- CPython forbids non-empty ``__slots__`` on int
    subclasses.  We accept the small ``__dict__`` cost in exchange for
    transparent ``isinstance(x, int)`` behavior throughout the DSL.
    """

    def __new__(cls, value: Any, slot_key: Any = None) -> "_WatchedInt":
        inst = int.__new__(cls, value)
        inst._slot_key = slot_key
        inst._cached_ir = None
        return inst

    @property
    def python_value(self) -> int:
        return int(self)


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

    def __new__(cls, value: Any, slot_key: Any = None) -> "_WatchedBool":
        inst = int.__new__(cls, int(value))
        inst._slot_key = slot_key
        inst._cached_ir = None
        return inst

    @property
    def python_value(self) -> bool:
        return bool(int(self))


class _WatchedFloat(_WatchedM, float):
    """Concrete D1 wrapper backed by ``float``.  Same ``__slots__`` rule
    as :class:`_WatchedInt`."""

    def __new__(cls, value: Any, slot_key: Any = None) -> "_WatchedFloat":
        inst = float.__new__(cls, value)
        inst._slot_key = slot_key
        inst._cached_ir = None
        return inst

    @property
    def python_value(self) -> float:
        return float(self)


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


def _meta_promote_slot(
    slot_key: Any,
    initial_py_value: Any,
    target_name: str | None = None,
    filename: str | None = None,
    lineno: int | None = None,
) -> "ir.Value | None":
    """Promote a slot to D1 tracking.

    Creates a ``pyir.ref`` at the enclosing function's entry block
    initialized with *initial_py_value*, then walks every previously
    baked ``arith.constant`` recorded under *slot_key* and replaces its
    uses with a freshly-emitted ``pyir.load %ref``.  The replaced
    constants become dead and DCE cleans them up; downstream arith ops
    pick up the load via SSA edges automatically -- no per-derivation
    rewriting needed.

    Emits a ``DSLWarning`` (WarnId.PHASE_AUTO_PROMOTED_TO_STAGED) via
    ``report_warning`` so users can see which variable was promoted, its
    original value, and the file:line of the offending mutation.  Shares the
    catalog entry with the Mp→S warning in ``pyir_read`` so both promotion
    paths surface identically.

    Returns the new ``pyir.ref`` SSA value, or ``None`` if there is no
    enclosing function (e.g. tracing happens outside an MLIR context).
    """
    if pyir is None:
        return None
    from .pyir_runtime import _get_function_entry_block, _ancestor_op_in_block

    entry_block = _get_function_entry_block()
    if entry_block is None:
        return None

    with ir.InsertionPoint.at_block_begin(entry_block):
        initial_ir = _emit_constant_at_current_ip(initial_py_value)
        ref = pyir.ref(initial_ir)
    _slot_refs[slot_key] = ref

    # User-visible warning: a Python (M) value just became staged-tracked
    # (ref + load/store).  Show target, original value, file:line so
    # users can locate and (optionally) hoist the init out of CF.
    if target_name is not None:
        from .diagnostics import WarnId, report_warning

        if isinstance(initial_py_value, bool):
            promoted_type = "Boolean"
        elif isinstance(initial_py_value, int):
            promoted_type = "Int32"
        elif isinstance(initial_py_value, float):
            promoted_type = "Float32"
        else:
            promoted_type = type(initial_py_value).__name__
        # Warn about the promotion AND the stale-local risk: the slot is now
        # tracked, but the caller's Python binding for ``target_name`` still
        # holds the original value, so a read OUTSIDE this region could see the
        # stale value -- the catalog message explains this to the author.
        report_warning(
            WarnId.PHASE_AUTO_PROMOTED_TO_STAGED,
            filename=filename,
            lineno=lineno,
            stacklevel=4,
            var=target_name,
            value=repr(initial_py_value),
            type=promoted_type,
        )

    # Per-iteration reset for the FIRST unrolled iteration's first-def.
    # Only fires when the user's first-def was INSIDE staged CF (e.g.
    # ``acc = 0.0`` at the top of an unrolled constexpr loop body whose
    # outer parent is a staged ``scf.for``/``scf.while``).  In that
    # case the function-entry ref init carries the primitive across
    # iter 0 of the enclosing runtime loop for free, but on iter 1+ the
    # ref becomes an ``iter_arg`` carrying the yielded value from iter 0
    # and the user's reset at the top of the body is lost (the wrap-as-
    # _WatchedM first-def emits no IR).  Insert ``pyir.store(initial_const,
    # %ref)`` BEFORE the earliest baked use so every runtime iteration
    # observes the reset.  The follow-on ``replaceAllUsesWith`` loop
    # converts that bake into ``pyir.load %ref`` -- our store dominates
    # the load via IR order.
    #
    # NOT fired when the first-def is OUTSIDE staged CF (e.g.
    # ``self.val = True`` in a plain ``__init__``), because the user
    # then intends the slot to persist across iterations of any runtime
    # loop and a per-iteration reset would clobber subsequent mutations
    # back to the initial literal.
    if _slot_first_def_inside_cf.get(slot_key, False):
        uses = _meta_uses.get(slot_key, [])
        if uses:
            first_use = uses[0]
            try:
                owner = first_use.owner
                if not isinstance(owner, ir.Block):
                    defining_op = (
                        owner
                        if isinstance(owner, ir.Operation)
                        else getattr(owner, "operation", owner)
                    )
                    # L103: the earliest baked use may live inside a NESTED
                    # runtime loop entered after the first-def.  Hoist the
                    # reset to the first-def's block so it runs once per
                    # first-def-level iteration (before the nested loop),
                    # not on every inner iteration.
                    anchor_op = _ancestor_op_in_block(
                        defining_op, _slot_first_def_block.get(slot_key)
                    )
                    with ir.InsertionPoint(anchor_op):
                        reset_ir = _emit_constant_at_current_ip(initial_py_value)
                        pyir.store(reset_ir, ref)
            except Exception as exc:
                log().info(
                    "[_meta_promote_slot] %s: reset-store insert failed: %s",
                    slot_key,
                    exc,
                )

    for const_val in _meta_uses.pop(slot_key, []):
        try:
            owner = const_val.owner
            if isinstance(owner, ir.Block):
                continue  # block argument has no "before" insertion point
            defining_op = (
                owner
                if isinstance(owner, ir.Operation)
                else getattr(owner, "operation", owner)
            )
            with ir.InsertionPoint(defining_op):
                loaded = pyir.load(ref)
            if not _replace_value_uses(const_val, loaded):
                log().info(
                    "[_meta_promote_slot] %s: replace_all_uses_with missing on ir.Value",
                    slot_key,
                )
        except Exception as exc:
            log().info("[_meta_promote_slot] %s: replace failed: %s", slot_key, exc)

    return ref


def _exit_function_trace() -> None:
    """Clear D1 per-trace state.  Called from ``_jit_scope.finally``."""
    _meta_uses.clear()
    _slot_refs.clear()
    _slot_first_def_inside_cf.clear()
    _slot_first_def_depth.clear()
    _slot_first_def_depth_any.clear()
    _slot_first_def_block.clear()
    _slot_mvs.clear()
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
