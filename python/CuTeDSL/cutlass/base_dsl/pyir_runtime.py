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
PyIR runtime — ``MutableValue``, ``pyir_assign``, and ``pyir_read``.

``pyir_assign`` and ``pyir_read`` are inserted by the AST preprocessor
at every assignment and read of (S) variables inside ``@cute.jit`` bodies.
They use ``MutableValue`` to manage ``pyir.ref / pyir.load / pyir.store``
per-object, with ``_is_ref_accessible()`` handling CF scoping.

No pre-scan / auto-flatten needed.  The ref travels with the object.
"""

# =============================================================================
# Standard library imports
# =============================================================================
import inspect

from typing import Any
from weakref import WeakKeyDictionary

# =============================================================================
# Local imports
# =============================================================================
from .multi_stage_manager import (
    is_inside_staged_cf,
    is_inside_locally_staged_cf,
    is_inside_constexpr_loop,
    get_staged_cf_depth,
    _is_staged_value,
    assign_meta_staged_check,
)

# =============================================================================
# MLIR imports
# =============================================================================
from .common import DSLRuntimeError, DSLUserCodeError, is_auto_m2s_enabled
from .diagnostics import DiagId
from .._mlir import ir
from .utils.logger import log

try:
    from .._mlir.dialects import pyir
except ImportError:
    pyir = None
try:
    from .._mlir.dialects import ub
except ImportError:
    ub = None


# ---------------------------------------------------------------------------
# Dominance-check helpers (used by _mlir_helpers/op.py)
# ---------------------------------------------------------------------------

_SCF_REGION_NAMES = {
    "scf.for": "a for-loop body",
    "scf.if": "an if/else body",
    "scf.while": "a while-loop body",
}


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


# ---------------------------------------------------------------------------
# The meta-value table (slot state, the _WatchedM family, the slot-key builder
# + owner pin, and promotion) lives in pyir_meta_table.py.  Re-exported here so
# pyir_assign / pyir_read and external callers keep using pyir_runtime.<name>.
# ---------------------------------------------------------------------------
from .pyir_meta_table import (  # noqa: F401
    _meta_uses,
    _slot_refs,
    _slot_first_def_inside_cf,
    _slot_first_def_depth,
    _slot_first_def_depth_any,
    _slot_first_def_block,
    _pinned_owners,
    _make_slot_key,
    _cached_ir_value_dominates_current_ip,
    _emit_constant_at_current_ip,
    _unwrap,
    _WatchedM,
    _WatchedInt,
    _WatchedBool,
    _WatchedFloat,
    _replace_value_uses,
    _meta_promote_slot,
    _exit_function_trace,
    _slot_mvs,
    pyir_function_scope,
    _current_fn_id,
    _watched_to_dsl,
)


# ----------------------------------------------------------------------
# Slot MutableValue storage.
#
# MutableValues for dict / list / non-__dict__ / non-weakref-able owners are
# keyed by ``_make_slot_key(None, owner, slot_name)`` into the shared
# ``_slot_mvs`` table (see pyir_meta_table.py) -- the same keying used by
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


# ==========================================================================
# Runtime-classified subscript instrumentation
# ==========================================================================

_PYIR_SKIP = object()  # Sentinel: container is not a dict, skip instrumentation


# ---------------------------------------------------------------------------
# Slot-keyed ref identity (slot-keyed MutableValue registry)
# ---------------------------------------------------------------------------
#
# PyIR historically attached ``_mutable_ref`` to the value object. When the
# same Python value is bound into multiple storage slots (three attributes
# share a seed, a dict has three entries with the same value), they collapse
# onto a single ``pyir.ref``. Pure Python rebinds by slot, not by value
# identity, so the tracking must do the same.
#
# Tier 1: owner.__dict__["__pyir_slots__"] -- a dict per owner that maps
# slot_name -> MutableValue. ``object.__setattr__`` bypasses
# ``@dataclass(frozen=True)``.
#
# Tier 2: ``_PYIR_SLOT_FALLBACK`` -- module-level ``WeakKeyDictionary`` that
# maps owner instances (declaring ``__slots__`` with no ``__dict__``) to
# their per-owner ``{slot_name: MutableValue}`` map.
#
# Tier 3: return ``None``. ``pyir_assign``/``pyir_read`` fall back to the
# legacy value-keyed ``_mutable_ref`` attribute on the value.
#
# Built-in ``dict`` / ``list`` owners can carry neither ``__pyir_slots__``
# (no writable ``__dict__``) nor a weakref. ``_set_slot_mv`` silently skips
# recording for those owners, so subscript lookups fall through to tier 3
# exactly as before.

_SLOT_STORE_ATTR = "__pyir_slots__"
_PYIR_SLOT_FALLBACK: "WeakKeyDictionary[Any, dict[Any, MutableValue]]" = (
    WeakKeyDictionary()
)


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


def _verify_no_used_poison(module: "ir.Module") -> None:
    """End-of-trace check: any ``ub.poison`` value with a real use is a bug.

    A poison-init ref is fine when no read ever consumes it — it's just a
    placeholder waiting for a store.  But if the IR contains a
    ``pyir.load`` against a poison-init ref whose result feeds any
    downstream op (printf, store, control-flow condition, etc.), the
    load will return undefined data at runtime.  We flag that case at
    trace completion, before the C++ pass pipeline runs.

    Raises ``DSLUserCodeError`` with a Python-source location lifted from
    the offending load's MLIR ``loc()`` attribute (set by the AST
    preprocessor at the original Python access site).
    """
    if ub is None:
        return  # ub dialect not built in -- no poison ops can exist

    def _has_any_use(value: Any) -> bool:
        try:
            for _ in value.uses:
                return True
        except (AttributeError, TypeError):
            return False
        return False

    def _dominates(store_op: Any, load_op: Any) -> bool:
        """True if ``store_op`` dominates ``load_op`` in the structured-region
        sense: either same block with ``store_op`` earlier, or some ancestor
        of ``load_op`` lives in ``store_op``'s block after ``store_op``.

        Walks up from ``load_op`` through ``op.block.region.owner`` (the
        proper MLIR Python chain — ``Block.owner`` is not a region).  When
        an ancestor lands in ``store_op``'s block, checks whether
        ``store_op`` precedes that ancestor (which is what dominance
        requires for structured CF)."""
        # ``OpView`` wrappers (StoreOp, LoadOp, ...) don't expose ``.block``
        # or ``.is_before_in_block`` directly — those live on the underlying
        # ``Operation``.  Normalise both inputs first.
        store_raw = getattr(store_op, "operation", store_op)
        load_raw = getattr(load_op, "operation", load_op)

        def _safe_block(op: Any) -> Any:
            """Return ``op.block`` or None — guards the C++ assertion
            ``Attached operation has null parent`` for module roots /
            detached ops."""
            try:
                if getattr(op, "parent", None) is None:
                    return None
                return op.block
            except Exception:
                return None

        store_block = _safe_block(store_raw)
        if store_block is None:
            return False
        cur = load_raw
        depth = 0
        while cur is not None and depth < 64:
            cur_block = _safe_block(cur)
            if cur_block is None:
                return False
            try:
                same_block = cur_block == store_block
            except Exception:
                same_block = False
            if same_block:
                if cur is store_raw:
                    return False
                try:
                    return store_raw.is_before_in_block(cur)
                except (AttributeError, TypeError):
                    return False
            region = getattr(cur_block, "region", None)
            if region is None:
                return False
            parent_op = getattr(region, "owner", None)
            if parent_op is None or parent_op is cur:
                return False
            parent_op = getattr(parent_op, "operation", parent_op)
            cur = parent_op
            depth += 1
        return False

    def _load_has_dominating_store(ref_op: Any, load_op: Any) -> bool:
        for use in ref_op.result.uses:
            store = use.owner
            if store is None or store.name != "pyir.store":
                continue
            if _dominates(store, load_op):
                return True
        return False

    offender = None  # the offending pyir.load or other op consuming poison
    offender_poison = None  # the originating ub.poison ir.Value, if known

    def _walk(op: Any) -> None:
        # Same walk, but also record the offending poison value when found.
        nonlocal offender, offender_poison
        if offender is not None:
            return
        if op.name == "ub.poison":
            for use in op.result.uses:
                user = use.owner
                if user is None:
                    continue
                if user.name == "pyir.ref":
                    for ref_use in user.result.uses:
                        ref_user = ref_use.owner
                        if (
                            ref_user is not None
                            and ref_user.name == "pyir.load"
                            and _has_any_use(ref_user.result)
                            and not _load_has_dominating_store(user, ref_user)
                        ):
                            offender = ref_user
                            offender_poison = op.result
                            return
                elif user.name == "pyir.load":
                    if _has_any_use(user.result):
                        offender = user
                        offender_poison = op.result
                        return
                else:
                    for r in user.results:
                        if _has_any_use(r):
                            offender = user
                            offender_poison = op.result
                            return
        for region in op.regions:
            for block in region.blocks:
                for sub in block.operations:
                    _walk(sub)
                    if offender is not None:
                        return

    _walk(module.operation)
    if offender is None:
        return

    # First try to recover Python file/line from the recorded poison
    # source (set by _make_poison_like at creation).  Fall back to parsing
    # the offending load's MLIR loc() if that map was wiped.
    filename, lineno = None, None
    # Prefer the attributes stamped onto the originating ub.poison op by
    # ``_record_poison_source``; fall back to the offender's MLIR loc().
    if offender_poison is not None:
        try:
            poison_op = offender_poison.owner
            attrs = poison_op.attributes
            file_attr = attrs["pyir.poison_src_file"]
            line_attr = attrs["pyir.poison_src_line"]
            filename = str(file_attr).strip('"')
            lineno = int(str(line_attr).split()[0])
        except (KeyError, AttributeError, ValueError, TypeError):
            pass
    if filename is None:
        import re

        loc_str = str(offender.location) if hasattr(offender, "location") else ""
        m = re.search(r'"([^"]+\.py)"\s*:\s*(\d+)', loc_str)
        if m:
            filename, lineno = m.group(1), int(m.group(2))

    raise DSLUserCodeError(
        DiagId.SCOPE_READ_NEVER_SET, filename=filename, lineno=lineno
    )


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


def _flatten_tuple(t: tuple) -> Any:  # Generator[Any, None, None]
    """Yield all non-tuple leaf elements from a (possibly nested) tuple."""
    for elem in t:
        if isinstance(elem, tuple):
            yield from _flatten_tuple(elem)
        else:
            yield elem


def _decompose_tuple(
    field_key: str,
    old_tuple: tuple,
    new_tuple: tuple,
    filename: str,
    lineno: int,
    _visited: set[int],
    *,
    owner: Any = None,
    slot_name: Any = None,
) -> tuple:
    """Decompose parallel tuples element-wise.

    Returns a new tuple with ``pyir_assign``-updated elements.

    *owner* / *slot_name* thread the parent's slot key down so per-element
    refs key on ``(owner, f"{slot_name}[{i}]")`` -- matching the key
    convention ``pyir_read``'s tuple recursion uses on the read side.
    """
    if len(old_tuple) != len(new_tuple):
        raise DSLUserCodeError(
            DiagId.CONTAINER_TUPLE_LENGTH_CHANGED,
            filename=filename,
            lineno=lineno,
            var=field_key,
            old=len(old_tuple),
            new=len(new_tuple),
        )

    has_slot_ctx = owner is not None and slot_name is not None
    result: list = []
    for i, (old_elem, new_elem) in enumerate(zip(old_tuple, new_tuple)):
        elem_key = f"{field_key}[{i}]"
        elem_slot = f"{slot_name}[{i}]" if has_slot_ctx else None

        if _is_staged_value(old_elem) and _can_create_ref(old_elem):
            result.append(
                pyir_assign(
                    elem_key,
                    old_elem,
                    new_elem,
                    filename,
                    lineno,
                    owner=owner if has_slot_ctx else None,
                    slot_name=elem_slot,
                )
            )

        elif isinstance(old_elem, tuple) and isinstance(new_elem, tuple):
            result.append(
                _decompose_tuple(
                    elem_key,
                    old_elem,
                    new_elem,
                    filename,
                    lineno,
                    _visited,
                    owner=owner,
                    slot_name=elem_slot,
                )
            )

        elif (
            hasattr(old_elem, "__dict__")
            and not _is_staged_value(old_elem)
            and type(old_elem) is type(new_elem)
        ):
            _decompose_m2m_assign(
                elem_key,
                old_elem,
                new_elem,
                filename,
                lineno,
                _visited=_visited,
            )
            result.append(old_elem)

        elif old_elem is None or isinstance(old_elem, (int, float, bool, str, bytes)):
            result.append(new_elem)

        else:
            log().warning(
                "[decompose_tuple] '%s' element %d not decomposable, copying",
                field_key,
                i,
            )
            result.append(new_elem)

    return tuple(result)


def _decompose_m2m_assign(
    target_name: str,
    old_obj: object,
    new_obj: object,
    filename: str,
    lineno: int,
    *,
    _visited: set[int] | None = None,
) -> None:
    """Decompose M→M object replacement into per-field ``pyir_assign``.

    Walks ``old_obj`` and ``new_obj`` in parallel via ``__dict__``.  For
    each attribute:

    - Staged leaf (``_pyir_ref_supported``): ``pyir_assign`` creates/reuses
      ref and emits ``pyir.store``.
    - Tuple: element-wise decomposition, rebuild, ``setattr`` back.
    - Nested compound: recurse.
    - Meta primitive: ``setattr`` directly (copy new value).

    After return, ``old_obj``'s staged fields carry ``_mutable_ref``
    handles with ``pyir.store`` emitted for ``new_obj``'s values.

    Cycle detection uses ``_visited`` (set of ``id(old_obj)``).
    """
    if _visited is None:
        _visited = set()

    obj_id = id(old_obj)
    if obj_id in _visited:
        log().warning(
            "[decompose_m2m] '%s' cycle detected (id=%d), skipping",
            target_name,
            obj_id,
        )
        return
    _visited.add(obj_id)

    log().info(
        "[decompose_m2m] '%s' type=%s",
        target_name,
        type(old_obj).__name__,
    )

    for attr_name in _get_instance_attrs(old_obj):
        old_field = getattr(old_obj, attr_name)
        try:
            new_field = getattr(new_obj, attr_name)
        except AttributeError:
            raise DSLUserCodeError(
                DiagId.CONTAINER_OBJECT_FIELD_MISMATCH,
                filename=filename,
                lineno=lineno,
                var=target_name,
                detail=f"missing `{attr_name}`",
            )

        field_key = f"{target_name}.{attr_name}"

        if _is_staged_value(old_field) and _can_create_ref(old_field):
            # Thread slot context so the per-field ref identity is keyed
            # on ``(old_obj, attr_name)`` -- closes the last loophole
            # where compound replacement re-uses the same pyir.ref for
            # multiple fields that shared a Python value object.
            result = pyir_assign(
                field_key,
                old_field,
                new_field,
                filename,
                lineno,
                owner=old_obj,
                slot_name=attr_name,
            )
            object.__setattr__(old_obj, attr_name, result)

        elif isinstance(old_field, tuple) and isinstance(new_field, tuple):
            new_tuple = _decompose_tuple(
                field_key,
                old_field,
                new_field,
                filename,
                lineno,
                _visited,
                owner=old_obj,
                slot_name=attr_name,
            )
            object.__setattr__(old_obj, attr_name, new_tuple)

        elif (
            hasattr(old_field, "__dict__")
            and not _is_staged_value(old_field)
            and not isinstance(old_field, (int, float, bool, str, bytes, type))
            and type(old_field) is type(new_field)
        ):
            _decompose_m2m_assign(
                field_key,
                old_field,
                new_field,
                filename,
                lineno,
                _visited=_visited,
            )

        elif old_field is None or isinstance(old_field, (int, float, bool, str, bytes)):
            # Meta-primitive field.  When this M->M decomposition is
            # happening inside staged control flow, the field's value
            # MUST stay constant across iterations -- the compiler only
            # traces the loop body once, so a "1 -> 2" change is silently
            # erased.  Catch it here and route to DSLUserCodeError so
            # users get a comprehensible diagnostic instead of subtly
            # wrong code.
            #
            # Meta-int wrappers (e.g. ``_WatchedInt``) inherit from ``int``
            # but identify as a distinct ``type()``, so strict type identity
            # is unreliable here.  ``isinstance(new_field, type(old_field))``
            # or vice versa keeps the check honest across subclass relations.
            same_numeric_kind = isinstance(new_field, type(old_field)) or isinstance(
                old_field, type(new_field)
            )
            if (
                is_inside_staged_cf()
                and not is_inside_constexpr_loop()
                and old_field is not None
                and isinstance(old_field, (int, float, bool))
                and isinstance(new_field, (int, float, bool))
                and same_numeric_kind
                and old_field != new_field
            ):
                raise DSLUserCodeError(
                    f"Meta-primitive field `{type(old_obj).__name__}.{attr_name}` "
                    f"cannot change across iterations of staged control flow "
                    f"({old_field!r} -> {new_field!r}). The compiler traces "
                    f"the body only once and would silently discard later "
                    f"changes.",
                    filename=filename,
                    lineno=lineno,
                    suggestion=(
                        f"Use a DSL Numeric type (e.g. cute.Int32) for "
                        f"`{attr_name}` so it is tracked by `pyir.ref`, or "
                        f"hoist the assignment outside staged control flow."
                    ),
                )
            object.__setattr__(old_obj, attr_name, new_field)

        else:
            log().warning(
                "[decompose_m2m] '%s' attr '%s' (type %s) not decomposable, "
                "copying directly",
                target_name,
                attr_name,
                type(old_field).__name__,
            )
            object.__setattr__(old_obj, attr_name, new_field)


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


# Mutator methods on built-in containers that we forbid inside staged CF
# when the container is a plain Python ``list``/``dict``/``set`` -- the
# compiler traces the body once and would silently discard the per-
# iteration mutations.
_PYIR_LIST_MUTATORS = frozenset(
    {
        "append",
        "extend",
        "insert",
        "pop",
        "remove",
        "clear",
        "sort",
        "reverse",
    }
)
_PYIR_DICT_MUTATORS = frozenset(
    {
        "update",
        "pop",
        "popitem",
        "setdefault",
        "clear",
    }
)
_PYIR_SET_MUTATORS = frozenset(
    {
        "add",
        "discard",
        "remove",
        "clear",
        "update",
        "intersection_update",
        "difference_update",
        "symmetric_difference_update",
    }
)


def _pyir_check_no_complex_m2m_call(
    container: object,
    method_name: str,
    container_repr: str,
    filename: str,
    lineno: int,
) -> None:
    """Reject in-place mutation of a meta ``list`` / ``dict`` / ``set``
    while inside staged control flow.

    The body of a staged loop / ``scf.if`` is traced exactly once, so a
    ``a.append(x)`` (or any other mutating method) would silently bake
    only the first iteration's mutation into the IR -- the per-iteration
    side effects disappear.  Raise a ``DSLUserCodeError`` with a fix-it
    pointing at slot-backed containers or DSL collection types.  A plain
    Python ``list`` / ``dict`` / ``set`` is never threaded by the slot
    registry regardless of element type, so the guard fires even when the
    container already holds staged values (the mutating method itself is
    not routed through ``pyir_assign``).

    No-op when the innermost control-flow construct is a constexpr scope
    (``range_constexpr`` / ``const_expr`` if/while): the body runs at
    trace time, so the mutation is realized deterministically rather than
    silently lost.
    """
    if not is_inside_staged_cf():
        return
    if is_inside_constexpr_loop():
        return
    if isinstance(container, list):
        if method_name not in _PYIR_LIST_MUTATORS:
            return
        kind = "list"
    elif isinstance(container, dict):
        if method_name not in _PYIR_DICT_MUTATORS:
            return
        kind = "dict"
    elif isinstance(container, (set, frozenset)):
        if method_name not in _PYIR_SET_MUTATORS:
            return
        kind = "set"
    else:
        return
    raise DSLUserCodeError(
        f"In-place mutation `{container_repr}.{method_name}(...)` of a "
        f"meta Python {kind} is not allowed inside staged control flow. "
        f"The compiler traces the body once and would silently discard "
        f"the per-iteration mutation.",
        filename=filename,
        lineno=lineno,
        suggestion=(
            f"Build the {kind} before the staged region, or use a DSL "
            f"collection type that the compiler can track (e.g. "
            f"``cute.struct``-backed buffer for accumulation)."
        ),
    )


def pyir_promote_loop_body_arg(target_name: str, current_value: object) -> object:
    """Auto-promote a Python-primitive write_arg at loop-body entry.

    If a loop-body reads a Python primitive (bool/int/float) that is later
    re-stored in the same iteration, the read site bakes the trace-time
    constant instead of loading from the loop-carried ref.  Calling
    ``pyir_read`` at body entry forces the slot to materialise so
    subsequent reads inside the body load from it.

    No-op for already-staged values: deferring to the existing read paths
    keeps Case A ref-placement order stable.
    """
    if not is_inside_staged_cf():
        return current_value
    if not is_auto_m2s_enabled():
        return current_value
    if _is_staged_value(current_value):
        return current_value
    if not isinstance(current_value, (bool, int, float)):
        return current_value
    return pyir_read(target_name, current_value)


def pyir_assign(
    target_name: Any,
    old_value: Any,
    new_value: Any,
    filename: str,
    lineno: int,
    *,
    owner: Any = None,
    slot_name: Any = None,
) -> Any:
    """Called by AST-inserted code after every ``=`` and ``+=``.

    1. Checks (M) mutation and type stability (Rule 2, Rule 4).
    2. If inside staged CF and value is (S):
       - Creates ``pyir.ref`` on first write (via MutableValue).
       - ``pyir.store`` the new value into the ref.
       - Returns ``new_value`` with ``_mutable_ref`` attached (NO load).
    3. Outside CF: returns new_value unchanged.

    The deferred-load invariant: ``pyir_assign`` never emits
    ``pyir.load``.  Loads are deferred to ``pyir_read`` or
    ``_pyir_auto_load_arg`` at the use site, ensuring the loaded SSA
    value is created at the correct insertion point (outside CF).

    *owner* / *slot_name* optionally identify the storage slot (e.g.
    ``(obj, "loop_desc")`` or ``(container, "key")``).  When both are
    provided, ``pyir_assign`` keys ref identity on the slot instead of
    on the value object -- preventing shared-value aliasing bugs where
    three attributes initialised from the same Python object collapse
    onto a single ``pyir.ref``.  When either is ``None`` the function
    falls back to the legacy value-keyed path (preserving local-name
    semantics).

    Simplified ``pyir_assign(owner, key, value, filename, lineno)`` entry
    point: detected by *target_name* not being a string (it's the owner
    object) and dispatched to the slot-registry-only path; the location
    args are still required so diagnostics can cite where the call came
    from.
    """
    # Simplified (owner, key, value) dispatch -- used by the slot
    # registry unit test and by external (owner, key) callers.  The
    # location args are still required (see signature) so this branch
    # never observes ``None`` for either; we just don't thread them
    # through ``_pyir_assign_simple`` (which is registry-only and emits
    # no diagnostics).
    if not isinstance(target_name, str):
        return _pyir_assign_simple(target_name, old_value, new_value)

    # Register a placeholder for the slot in _slot_mvs keyed by
    # structural identity.  ``_get_slot_mv`` consults the registry for
    # registry-backed owners (dict/list, which have no ``__dict__``);
    # ``__dict__``-backed owners use the tier-1/tier-2 stores below.
    # Authoritative storage stays in _set_slot_mv / _get_slot_mv below.
    if owner is not None and slot_name is not None:
        slot_key = _make_slot_key(None, owner, slot_name)
        if slot_key not in _slot_mvs:
            placeholder = MutableValue.__new__(MutableValue)
            object.__setattr__(placeholder, "_value", new_value)
            object.__setattr__(placeholder, "_type", type(new_value))
            object.__setattr__(placeholder, "_ref", None)
            object.__setattr__(placeholder, "_ref_context_id", None)
            object.__setattr__(placeholder, "_load_version", 0)
            _slot_mvs[slot_key] = placeholder
    log().info(
        "[pyir_assign] '%s' old=%s new=%s (%s:%d)",
        target_name,
        type(old_value).__name__,
        type(new_value).__name__,
        filename,
        lineno,
    )

    # First-time definition — create ref eagerly if inside staged CF.
    # Only create refs for scalar-like types (Numeric, not Boolean).
    # Multi-element types (Vector), boolean types (i1), and types with
    # complex ir_value() are left to the reassignment path to handle.
    #
    # Anti-aliasing: ``a = b = c = seed`` binds three Python locals to
    # the same value object.  ``ast.Name`` targets carry no storage
    # owner, so ``pyir_assign``/``pyir_read`` fall back to the
    # value-keyed ``_mutable_ref`` cache.  Without a fresh wrapper per
    # first-def, the three locals would alias onto ``seed._mutable_ref``
    # and collapse onto a single ``pyir.ref``.  Returning a fresh
    # wrapper per first-def gives each local its own attachment slot.
    if old_value is None:
        # The default first-def gate excludes booleans because a free-
        # standing ``cond = i > 2`` is almost always a one-shot if-test
        # and the dead ref breaks PYIRToSCF.  But when the caller supplied
        # slot context (e.g. ``self._is_valid_tile = Boolean(valid)`` in
        # ``@cute.jit __init__``), the slot store records the ref so
        # downstream ``pyir_read('container', container)`` can refresh it
        # across staged CF boundaries.  Slot-keyed booleans are therefore
        # allowed to take refs.
        #
        # CRITICAL: keep the gate as a single ``and`` chain so the early
        # checks short-circuit BEFORE we call ``_is_boolean_like`` /
        # ``_is_vector_like``.  Those helpers call ``value.ir_value()``
        # which materialises (and caches) the leaf ``arith.constant`` for
        # ``_WatchedInt`` -- if we evaluate them on a meta primitive we
        # pin the constant at the wrong insertion point and break the
        # sibling-region constant cache.
        if (
            is_inside_staged_cf()
            and _is_staged_value(new_value)
            and _can_create_ref(new_value)
            and not _is_vector_like(new_value)
            and (
                # Boolean blocked unless slot context supplies an
                # explicit storage identity.
                not _is_boolean_like(new_value)
                or (
                    owner is not None
                    and slot_name is not None
                    and _slot_storage_available(owner)
                )
            )
        ):
            log().info(
                "[pyir_assign] '%s' first def inside staged CF → create ref",
                target_name,
            )
            new_value = _fresh_wrapper(new_value)
            fresh_mv = _create_ref(new_value)
            fresh_mv.store(new_value)
            _attach_mutable_ref(
                new_value, fresh_mv, f"pyir_assign '{target_name}' first-def"
            )
            # When the caller supplied slot context (e.g. ``self._m_idx``
            # first-def in a ``@cute.jit __init__``), register the
            # freshly-created ref against the slot so a later
            # ``pyir_read(... owner=..., slot_name=...)`` finds it via
            # the slot registry instead of falling through to legacy
            # ``_mutable_ref`` (which a wrapper rebuild can drop) and
            # then to ``_create_ref`` Case-D poison fallback.
            if (
                owner is not None
                and slot_name is not None
                and _slot_storage_available(owner)
            ):
                _set_slot_mv(owner, slot_name, fresh_mv)
        elif _is_staged_value(new_value) and _can_create_ref(new_value):
            # Outside staged CF (or non-eager type): no ref yet, but the
            # local will be read inside a later staged region.  Return a
            # fresh wrapper so that read attaches ``_mutable_ref`` to a
            # local-owned object rather than the shared source value.
            log().info(
                "[pyir_assign] '%s' first def → fresh wrapper (no ref yet)",
                target_name,
            )
            new_value = _fresh_wrapper(new_value)
        else:
            log().info("[pyir_assign] '%s' first def → passthrough", target_name)
        # Slot-identity wrap for literal-bool / int / float first-defs inside
        # staged CF.  Without this, a Python ``skip = False`` (or ``count =
        # 0``) first-def returns the bare primitive to the caller; the
        # caller's Python local then carries no slot identity.  If a later
        # write inside this region promotes the slot via D1 (because the
        # new value is a STAGED DSL type the keep-constexpr gate does not
        # catch), the promotion lands in ``_slot_refs`` but the caller's
        # local still holds the bare primitive.  Downstream reads (e.g.
        # ``if skip:`` after the region) then constexpr-fold with the
        # stale primitive instead of going through ``pyir.load %ref`` --
        # silent miscompile.
        #
        # Wrapping as ``_WatchedM(value, slot_key)`` makes the slot
        # identity travel with the value.  After the region exits, the
        # post-region merge calls ``_pyir_auto_load_arg`` on the slot's
        # ``mix_iter_args`` entry; ``_WatchedM`` carrying a promoted slot
        # key resolves to ``_load_as_dsl`` (which emits ``pyir.load`` and
        # attaches a fresh ``_mutable_ref``) so the caller's local picks
        # up the promoted SSA.  Outside staged CF, ``_WatchedM`` is
        # transparent (``int`` / ``float`` subclass) so consumers that
        # treat it as a primitive (e.g. shape params, ``isinstance(x,
        # int)``) continue to work.
        #
        # Skip wrapping for already-wrapped values (``_WatchedM`` re-wrap
        # would lose the existing slot key) and for non-primitives (DSL
        # types handled by the eager-ref branch above).
        if (
            is_inside_staged_cf()
            and target_name is not None
            and type(new_value) in (bool, int, float)
        ):
            d1_slot = _make_slot_key(target_name, owner, slot_name, _current_fn_id())
            if d1_slot is not None:
                # Per-iteration reset: when an earlier trace-time unrolled
                # iteration of an enclosing ``range_constexpr`` already
                # promoted this slot via D1, the Python-primitive first-def
                # here is the user's reset at the top of the current
                # unrolled body (``acc = 0.0`` / ``cur_max = -inf``).  Emit
                # ``pyir.store(primitive, %ref)`` at the current IP so
                # downstream reads observe the reset instead of loading the
                # value the previous iteration last stored, and return
                # ``_load_as_dsl`` so the caller's Python local carries the
                # reset SSA (a ``_WatchedM`` return would be ignored by
                # ``pyir_read``'s slot-already-promoted shortcut and the
                # store would race the stale load).
                existing_ref = _slot_refs.get(d1_slot)
                if existing_ref is not None and pyir is not None:
                    log().info(
                        "[pyir_assign] '%s' Python-primitive first-def into "
                        "already-promoted slot -> store + load (per-iteration reset)",
                        target_name,
                    )
                    new_ir = _emit_constant_at_current_ip(new_value)
                    pyir.store(new_ir, existing_ref)
                    return _load_as_dsl(existing_ref, new_value)
                new_value = _WatchedM(new_value, d1_slot)
        # First-def depth bookkeeping for the straight-line type-change
        # rebind guard (see ``_slot_first_def_depth_any``).  Recorded for
        # EVERY local first-def -- primitive OR staged DSL value -- so a
        # later reassignment can tell whether the prior binding originated
        # in the current staged-CF region (straight-line) or crosses a
        # region boundary (a genuine Rule-4 join).
        if target_name is not None:
            _any_slot = _make_slot_key(target_name, owner, slot_name, _current_fn_id())
            if _any_slot is not None:
                _slot_first_def_depth_any[_any_slot] = get_staged_cf_depth()

        # First-def location bookkeeping: record whether this slot was
        # first-defined inside staged CF when the init is a Python
        # primitive (bool / int / float).  A later D1 reassignment
        # consults this flag to refuse promotion -- placing the ref's
        # init at the function-entry block would hoist the user's
        # per-iteration reset out of the enclosing scf.while / scf.for.
        if isinstance(new_value, (bool, int, float)) and target_name is not None:
            d1_slot = _make_slot_key(target_name, owner, slot_name, _current_fn_id())
            if d1_slot is not None:
                _slot_first_def_inside_cf[d1_slot] = is_inside_staged_cf()
                _slot_first_def_depth[d1_slot] = get_staged_cf_depth()
                try:
                    _slot_first_def_block[d1_slot] = ir.InsertionPoint.current.block
                except Exception:
                    _slot_first_def_block.pop(d1_slot, None)
        return new_value

    # D1 (META_VALUE_TABLE_DESIGN): retroactive promotion of M values.
    # When the old value is a ``_WatchedM`` wrapper, or the slot is
    # already promoted, route through the meta-value table.  This
    # handles M-mutation inside staged CF without falling through to
    # the legacy "M mutation forbidden" error.
    if is_inside_staged_cf() and target_name != "self.dummy":
        d1_slot = _make_slot_key(target_name, owner, slot_name, _current_fn_id())
        if d1_slot is not None:
            # Keep-constexpr gate: refuse to promote when the slot's
            # first-def was inside staged CF and the new value is still
            # a Python primitive.  Promotion would lift the slot's init
            # to the function-entry block, hoisting the user's per-
            # iteration reset out of the enclosing scf.while / scf.for.
            # When the user wants persistent semantics they initialise
            # the slot OUTSIDE the staged region (flag=False), which
            # still promotes normally.  The ``d1_slot not in _slot_refs``
            # clause keeps the rule local: once a slot is promoted (e.g.
            # a sibling staged region wrote a dynamic value), continued
            # Python-primitive writes go through the existing D1 path
            # and store into the ref.
            #
            # Depth guard (L103): keep-constexpr is only sound when the
            # reassignment is at the SAME staged-CF depth as the first-def
            # -- i.e. the toggle constant-folds across a ``range_constexpr``
            # unroll at the same runtime-CF level (L97/L97b).  When the
            # current depth is GREATER, the toggle sits inside a NESTED
            # RUNTIME loop/if entered after the first-def (FMHA-decode QK
            # GEMM: ``scale_d`` born in an outer ``cutlass.range`` then
            # toggled in a nested ``range`` MMA-K loop).  That loop must
            # thread the value as an iter_arg, so we must NOT keep it
            # constexpr -- fall through to D1 promotion instead.
            #
            # Subscript exemption (L107): a SUBSCRIPT target (``"["`` in
            # the name, e.g. ``_tmem_o_pw_counters[obj_id] = pw + 1``) is a
            # TRACE-TIME counter incremented once per trace-visit -- never a
            # loop-carried runtime value.  It must stay meta regardless of
            # depth (matching the dedicated subscript passthrough below).
            # The depth guard alone would let a deeper-than-first-def visit
            # fall through to D1 promotion (via the ``prior_meta_use`` baked
            # by an earlier same-depth visit), turning the counter into a
            # ``pyir.load`` -- then ``const_expr(counter % 2 == 0)`` sees a
            # dynamic value.  A genuine loop-carried value in a subscript
            # would be a STAGED DSL type, which fails the
            # ``isinstance(new_value, (bool, int, float))`` test below.
            _is_subscript_counter = target_name is not None and "[" in target_name
            if (
                _slot_first_def_inside_cf.get(d1_slot, False)
                and (
                    get_staged_cf_depth() <= _slot_first_def_depth.get(d1_slot, 0)
                    or _is_subscript_counter
                )
                and isinstance(new_value, (bool, int, float))
                and not _is_staged_value(new_value)
                and isinstance(old_value, _WatchedM)
                and d1_slot not in _slot_refs
            ):
                log().info(
                    "[pyir_assign] '%s' D1 keep-constexpr (first-def "
                    "inside CF, new is Python primitive)",
                    target_name,
                )
                return _WatchedM(new_value, d1_slot)
            # Gate: D1 must only fire when a PRIOR read (in an earlier
            # statement) baked a constant into ``_meta_uses[slot]`` --
            # this is the snapshot-rewrite case D1 was designed for.
            # The CURRENT statement's RHS evaluation also calls
            # ``_pyir_auto_load_arg(_WatchedM)`` which records
            # ``old_value._cached_ir`` in ``_meta_uses``; that entry
            # must be excluded so that pure M->S patterns
            # (``x = 0; for: x = x + i``) do NOT silently get promoted
            # by D1 -- preserving the pre-D1 safety guardrail that
            # errored unless ``CUTE_DSL_AUTO_M2S=True``.
            #
            # When the assignment is M->S (``new_is_staged``) AND the user
            # explicitly opted into ``CUTE_DSL_AUTO_M2S``, D1 also fires
            # so the baked constants from this statement's RHS get
            # rewritten to ``pyir.load %ref`` for correct lowering.
            old_is_watched = isinstance(old_value, _WatchedM)
            new_is_primitive = isinstance(new_value, (bool, int, float, _WatchedM))
            new_is_staged = _is_staged_value(new_value)
            old_cached_ir = getattr(old_value, "_cached_ir", None)
            prior_meta_use_exists = any(
                u is not old_cached_ir for u in _meta_uses.get(d1_slot, [])
            )
            already_tracked = d1_slot in _slot_refs or prior_meta_use_exists
            # AUTO_M2S=True opt-in: when the slot has a ``_WatchedM`` old
            # value (i.e. the RHS just baked a constant from this Python
            # primitive) and the user explicitly enabled M->S promotion,
            # also fire D1 so the baked constants get rewritten to
            # ``pyir.load %ref``.  Without this fall-back, the legacy M->S
            # path would create a fresh ref but leave dangling constants.
            # Plain dict-int subscripts (no ``_WatchedM`` wrapper) are
            # never auto-promoted by this branch -- they fall through to
            # the legacy passthrough so trace-time counters stay meta.
            if not already_tracked and old_is_watched:
                from .common import is_auto_m2s_enabled as _is_auto_m2s_enabled

                if _is_auto_m2s_enabled():
                    already_tracked = True
            # D1 accepts:
            #   * primitives / _WatchedM -> bake as IR constant
            #   * staged DSL values (Int32(a+b), Boolean, ...) -> store the
            #     existing SSA into the ref. This handles the M->S
            #     promotion inside CF (e.g. `x = 0; for: x = a + b`).
            if already_tracked and (new_is_primitive or new_is_staged):
                # Promote if not yet promoted.
                if d1_slot not in _slot_refs:
                    initial_py = old_value.python_value if old_is_watched else old_value
                    if isinstance(initial_py, (bool, int, float)):
                        _meta_promote_slot(
                            d1_slot, initial_py, target_name, filename, lineno
                        )
                ref = _slot_refs.get(d1_slot)
                if ref is not None:
                    # Bake the new value as IR and store into the ref.
                    if isinstance(new_value, _WatchedM):
                        new_ir = new_value.ir_value()
                    elif new_is_staged:
                        new_ir = new_value.ir_value()
                    else:
                        new_ir = _emit_constant_at_current_ip(new_value)
                    pyir.store(new_ir, ref)
                    log().info(
                        "[pyir_assign] '%s' D1 store -> %s",
                        target_name,
                        d1_slot,
                    )
                    sample = (
                        old_value.python_value
                        if old_is_watched
                        else (
                            new_value.python_value
                            if isinstance(new_value, _WatchedM)
                            else new_value
                        )
                    )
                    return _load_as_dsl(ref, sample)

    if (
        is_inside_staged_cf()
        and "[" in target_name
        and isinstance(old_value, (bool, int, float))
        and isinstance(new_value, (bool, int, float))
        and type(old_value) is type(new_value)
    ):
        log().info(
            "[pyir_assign] '%s' trace-time primitive subscript update → passthrough",
            target_name,
        )
        return new_value

    # Straight-line type-change rebind exemption (Rule 4 false positive).
    #
    # A same-name local reassigned to a value of a DIFFERENT MLIR type is a
    # Rule-4 "unstable join" violation ONLY at a real join -- a branch merge
    # or a loop back-edge -- where the prior binding crosses a staged-CF
    # boundary.  But ``assign_meta_staged_check`` runs per assignment at trace
    # time and cannot see CF structure, so its Rule 4 fires on EVERY
    # staged->staged type-changing reassignment while ``is_inside_staged_cf()``
    # -- including legitimate straight-line rebinds where the next statement
    # simply derives a new-typed value from the previous one
    # (``p = base + off``  ->  ``p = inttoptr(p)``).
    # Non-PyIR accepts those (the Python name is just rebound).
    #
    # Discriminate by first-def depth: when the prior binding was first-defined
    # at the SAME staged-CF depth as this reassignment, both assignments live
    # in the same region (straight-line) -- not a join -- so the type change is
    # safe and is materialised by the type-changing-reassignment path below (a
    # fresh ref typed to the new value).  When the first-def is at a SHALLOWER
    # depth the prior binding pre-dates the current region and the type really
    # would differ at the back-edge / merge: keep raising via Rule 4.  Genuine
    # region-crossing joins are additionally validated by
    # ``ScfGenerator._check_region_result`` at the region boundary.
    _straight_line_type_rebind = False
    if (
        is_inside_staged_cf()
        and isinstance(target_name, str)
        and _is_staged_value(old_value)
        and _is_staged_value(new_value)
        and type(old_value) is not type(new_value)
        and _staged_type_changed(old_value, new_value)
    ):
        _rebind_slot = _make_slot_key(target_name, owner, slot_name, _current_fn_id())
        _first_depth = (
            _slot_first_def_depth_any.get(_rebind_slot)
            if _rebind_slot is not None
            else None
        )
        if _first_depth is not None and _first_depth >= get_staged_cf_depth():
            log().info(
                "[pyir_assign] '%s' straight-line type-change rebind "
                "(%s -> %s, first-def depth %d == cur depth %d) → allow",
                target_name,
                type(old_value).__name__,
                type(new_value).__name__,
                _first_depth,
                get_staged_cf_depth(),
            )
            # Re-root the variable at the new type for this region so a
            # subsequent same-depth rebind is also recognised as straight-line.
            _slot_first_def_depth_any[_rebind_slot] = get_staged_cf_depth()
            _straight_line_type_rebind = True
            # Skip Rule 4; fall through to the type-changing reassignment path.

    # Rule checks (M mutation, type stability) — may auto-coerce scalars.
    # Skipped for a straight-line type-change rebind exempted above (the
    # type-changing reassignment path below materialises a fresh ref).
    coerced = (
        None
        if _straight_line_type_rebind
        else assign_meta_staged_check(
            target_name, old_value, new_value, filename, lineno
        )
    )
    if coerced is not None:
        log().info(
            "[pyir_assign] '%s' auto-coerced %s → %s",
            target_name,
            type(new_value).__name__,
            type(coerced).__name__,
        )
        new_value = coerced

    if not is_inside_staged_cf():
        log().info("[pyir_assign] '%s' outside staged CF → passthrough", target_name)
        return new_value

    # M→M compound auto-decomposition: both old and new are compound
    # objects (not directly staged) with staged leaf fields.  Decompose
    # into per-field pyir_assign calls so the compiler sees each SSA
    # update through pyir.ref/store.
    if (
        not _is_staged_value(new_value)
        and not _is_staged_value(old_value)
        and old_value is not None
        and not isinstance(old_value, (int, float, bool, str, bytes, type))
        and type(old_value) is type(new_value)
    ):
        if _has_decomposable_staged_fields(old_value):
            log().info(
                "[pyir_assign] '%s' M→M auto-decomposition (type=%s)",
                target_name,
                type(old_value).__name__,
            )
            _decompose_m2m_assign(target_name, old_value, new_value, filename, lineno)
            return old_value  # I1: return old — it accumulates refs
        if _has_any_staged_content(old_value):
            raise DSLUserCodeError(
                DiagId.CONTAINER_OBJECT_REPLACED,
                filename=filename,
                lineno=lineno,
                var=target_name,
            )
        # Pure meta object (no staged fields): harmless replacement.
        log().info(
            "[pyir_assign] '%s' pure meta compound → passthrough",
            target_name,
        )
        return new_value

    if not _is_staged_value(new_value):
        log().info(
            "[pyir_assign] '%s' new_value not staged → passthrough",
            target_name,
        )
        return new_value

    # M->S promotion: old is meta, new is staged.
    # This is only reachable when auto_m2s=True (otherwise
    # assign_meta_staged_check raises above).
    # Promote old_value to new_value's type, create ref at function entry.
    if not _is_staged_value(old_value):
        dsl_type = type(new_value)
        try:
            promoted = dsl_type(old_value)
        except (TypeError, ValueError):
            raise DSLUserCodeError(
                DiagId.PHASE_CONVERSION_FAILED,
                filename=filename,
                lineno=lineno,
                var=target_name,
                new_type=dsl_type.__name__,
                old_value=repr(old_value),
            )
        if not _can_create_ref(promoted):
            # Non-ref-compatible type (Pointer, Array, etc.) — passthrough.
            # The non-PyIR iter_args path handles these via pytree.
            log().info(
                "[pyir_assign] '%s' M->S but %s not ref-compatible → passthrough",
                target_name,
                type(promoted).__name__,
            )
            return new_value
        log().info(
            "[pyir_assign] '%s' M->S auto-promotion: %s(%r) -> ref",
            target_name,
            dsl_type.__name__,
            old_value,
        )
        have_slot_m2s = (
            owner is not None
            and slot_name is not None
            and _slot_storage_available(owner)
        )
        mv: "MutableValue | None" = None
        if have_slot_m2s:
            existing_slot_mv = _get_slot_mv(owner, slot_name)
            if existing_slot_mv is not None and existing_slot_mv._is_ref_accessible():
                mv = existing_slot_mv
        if mv is None:
            mv = _create_ref(promoted)
            if have_slot_m2s:
                _set_slot_mv(owner, slot_name, mv)
        mv.store(new_value)
        # Anti-aliasing: when slot context is present ALWAYS reconstruct so
        # the _mutable_ref attached below cannot leak onto a shared value.
        if have_slot_m2s:
            new_value = mv._reconstruct(new_value.ir_value())
        else:
            existing_mv = getattr(new_value, "_mutable_ref", None)
            if existing_mv is not mv:
                new_value = mv._reconstruct(new_value.ir_value())
        _attach_mutable_ref(
            new_value, mv, f"pyir_assign '{target_name}' M->S promotion"
        )
        return new_value

    # Find or create MutableValue.
    # Slot-first lookup: when owner/slot_name are supplied, the storage
    # slot is authoritative (``_slot_storage_available`` is True for any
    # non-None owner -- dict/list owners route through ``_slot_mvs``
    # rather than ``__dict__`` but the lookup path is the same).  This
    # prevents shared-value aliasing bugs where three attributes
    # initialised from the same Python object collapse onto a single
    # pyir.ref.
    #
    # When slot lookup returns nothing we also consult the value's
    # ``_mutable_ref`` so a ref created earlier via the legacy path
    # (e.g. an ``attach_ref=False`` read) is adopted by the slot instead
    # of being duplicated.
    have_slot = (
        owner is not None and slot_name is not None and _slot_storage_available(owner)
    )
    mv = None
    if have_slot:
        mv = _get_slot_mv(owner, slot_name)
        if mv is None:
            legacy_mv = getattr(old_value, "_mutable_ref", None)
            if legacy_mv is not None:
                mv = legacy_mv
                _set_slot_mv(owner, slot_name, mv)
    else:
        mv = getattr(old_value, "_mutable_ref", None)
    log().info("[pyir_assign] '%s' existing mv=%s", target_name, mv)

    # Type-changing reassignment: a same-name local rebound to a value of
    # a DIFFERENT MLIR type (e.g. ``v = v.to(other_dtype)`` or a vector
    # recast ``vector<8xf4E2M1FN> -> vector<4xi8>``) cannot reuse the old
    # ref -- the ref's element type is fixed at creation, so storing the
    # new value and loading it back round-trips the OLD type and a later
    # use reads a stale-typed value (silent miscompile / verifier error).
    # Drop the incompatible ref and create a FRESH ref typed to the new
    # value so the ref/store/load all carry the new type.  ``_can_create_
    # ref(new_value)`` gates this so non-ref types still passthrough.
    # Layer-4 guard (P89): a SAME-Python-type, ref-supported staged value
    # (e.g. cute._Tensor -> cute._Tensor) whose MLIR type CHANGES at a region
    # crossing must NOT silently create a fresh, non-escaping ref -- the new
    # value would be computed but never threaded out (no scf result / iter_arg),
    # and the post-CF use would read the STALE pre-CF value (a silent
    # miscompile).  Rule 4 (assign_meta_staged_check) misses this because it only
    # compares the Python class, and both sides are the same class here.  Honor
    # the L110 straight-line exemption: a same-depth rebind (the prior binding
    # was first-defined in THIS region) is straight-line, not a join, so the
    # fresh-ref path below handles it.  Only a genuine join -- the prior binding
    # first-defined at a SHALLOWER depth -- is rejected, matching non-PyIR.
    if (
        mv is not None
        and isinstance(target_name, str)
        and type(old_value) is type(new_value)
        and _can_create_ref(old_value)
        and _can_create_ref(new_value)
        and _staged_type_changed(old_value, new_value)
    ):
        _tc_slot = _make_slot_key(target_name, owner, slot_name, _current_fn_id())
        _tc_first_depth = (
            _slot_first_def_depth_any.get(_tc_slot) if _tc_slot is not None else None
        )
        _is_straight_line = (
            _tc_first_depth is not None and _tc_first_depth >= get_staged_cf_depth()
        )
        if not _is_straight_line:
            # Surface the old vs new value in its human-readable form -- the
            # same repr ``print(x)`` shows (e.g. a cute._Tensor prints as
            # ``tensor<ptr<f16, smem, align<128>> o (128,128):(1,128)>``), so the
            # user can see exactly what changed.
            def _type_desc(v: Any) -> str:
                try:
                    text = str(v)
                except Exception:
                    return type(v).__name__
                text = " ".join(text.split())  # collapse newlines/indentation
                return text if len(text) <= 160 else text[:157] + "..."

            raise DSLUserCodeError(
                DiagId.CONTAINER_STRUCTURE_CHANGED,
                filename=filename,
                lineno=lineno,
                var=target_name,
                op_type="for/while/if",
                detail=f" (was {_type_desc(old_value)}, now {_type_desc(new_value)})",
            )

    type_changed = (
        mv is not None
        and _can_create_ref(new_value)
        and _staged_type_changed(old_value, new_value)
    )
    if type_changed:
        log().info(
            "[pyir_assign] '%s' type-changing reassignment (%s -> %s) → fresh ref",
            target_name,
            _mlir_type_or_none(old_value),
            _mlir_type_or_none(new_value),
        )
        mv = None

    # Type-changing rebind to a NON-ref-compatible value (e.g. Int64 ->
    # Pointer).
    # ``_can_create_ref(new_value)`` is False so the fresh-ref path above does
    # not fire, yet the old ``mv`` is typed to the OLD value -- storing the new
    # value into it would fail ``pyir.store`` verification (pointee type
    # mismatch).  Drop the stale ref and passthrough the new value, matching
    # the non-PyIR pytree handling for non-ref types.
    elif (
        mv is not None
        and not _can_create_ref(new_value)
        and _staged_type_changed(old_value, new_value)
    ):
        log().info(
            "[pyir_assign] '%s' type-changing rebind to non-ref type "
            "(%s -> %s) → drop stale ref, passthrough",
            target_name,
            _mlir_type_or_none(old_value),
            type(new_value).__name__,
        )
        if have_slot:
            _clear_slot_mv(owner, slot_name)
        return new_value

    if mv is not None and mv._is_ref_accessible():
        log().info("[pyir_assign] '%s' reuse ref (accessible)", target_name)
    elif not _can_create_ref(old_value) and not type_changed:
        # Non-ref-compatible type (Pointer, Array, etc.) — passthrough.
        # The non-PyIR iter_args path handles these via pytree.
        log().info(
            "[pyir_assign] '%s' type %s not ref-compatible → passthrough",
            target_name,
            type(old_value).__name__,
        )
        return new_value
    else:
        # On a type-changing rebind the ref must be typed to ``new_value``
        # (``old_value``'s type no longer fits).  For same-type rebinds keep
        # the historical behaviour and build from ``old_value``.
        mv = _create_ref(new_value if type_changed else old_value)
        if have_slot:
            _set_slot_mv(owner, slot_name, mv)
        log().info("[pyir_assign] '%s' ref created via _create_ref", target_name)

    # P-058-D: Auto-load new_value when it carries a ref from a different
    # context (cross-dict propagation in copy_consumer_vars_to).
    # For Name/Attribute targets the pyir_read that precedes this call
    # already loaded the value, so this is redundant.  For subscript
    # targets, _pyir_pre_subscript_assign reads the DEST ref while
    # new_value carries a different SOURCE ref — we must load the source
    # to get a fresh SSA before storing into the dest ref.
    new_mv = getattr(new_value, "_mutable_ref", None)
    if new_mv is not None and new_mv is not mv and new_mv._is_ref_accessible():
        new_value = new_mv.load()
        log().info(
            "[pyir_assign] '%s' auto-loaded new_value from different ref",
            target_name,
        )

    mv.store(new_value)
    log().info("[pyir_assign] '%s' stored", target_name)

    # Do NOT emit pyir.load here — the loaded SSA value would be
    # trapped inside the current CF region.  Instead, return new_value
    # with _mutable_ref attached.  When the value is read later,
    # pyir_read (or _pyir_auto_load_arg) emits a fresh pyir.load
    # at the correct insertion point outside the CF region.
    #
    # Anti-aliasing: when slot context is provided ALWAYS reconstruct so
    # the wrapper carrying this ref belongs exclusively to this slot.
    # Otherwise, only reconstruct when new_value does not already carry
    # this mv (the legacy anti-aliasing rule for locals).
    if have_slot:
        new_value = mv._reconstruct(new_value.ir_value())
    else:
        existing_mv = getattr(new_value, "_mutable_ref", None)
        if existing_mv is not mv:
            new_value = mv._reconstruct(new_value.ir_value())
    _attach_mutable_ref(new_value, mv, f"pyir_assign '{target_name}'")

    return new_value


_PYIR_READ_SIMPLE_SENTINEL = object()


def pyir_read(
    target_name: Any,
    current_value: Any = _PYIR_READ_SIMPLE_SENTINEL,
    *,
    attach_ref: bool = True,
    owner: Any = None,
    slot_name: Any = None,
    meta_only: bool = False,
    **_extra_kwargs: Any,
) -> Any:
    """Called by AST-inserted code before every read of a tracked variable.

    If the object has a ``_mutable_ref`` with an accessible ref, emit
    ``pyir.load`` and return a fresh DSL value.

    If inside staged CF and no ref exists yet, lazily create one at the
    parent scope so subsequent reads/writes use it.

    # TODO: cache pyir_read — augmented assignments (x += 1) emit a
    # redundant pyir.load here whose result is unused, because __iadd__
    # also loads the ref. The dead load is eliminated by later passes but
    # caching the load result would avoid emitting it in the first place.

    When *attach_ref* is ``False``, the loaded value does NOT carry
    ``_mutable_ref``.  Used for standalone ``self.X`` reads (no
    following ``pyir_assign``) to prevent the ref from leaking through
    object boundaries.

    *owner* / *slot_name* optionally identify the storage slot so
    ``pyir_read`` can consult the slot registry before the value-keyed
    ``_mutable_ref`` cache.  When either is ``None`` the legacy
    value-keyed path is used unchanged.
    """
    # Callers that omit ``current_value`` get the historical default of
    # ``None`` (the sentinel just distinguishes "omitted" from "explicitly
    # None" at the call site).
    if current_value is _PYIR_READ_SIMPLE_SENTINEL:
        current_value = None
    log().info(
        "[pyir_read] '%s' type=%s attach_ref=%s",
        target_name,
        type(current_value).__name__,
        attach_ref,
    )

    # Tuple recursion: aggregate tuples are not ref-supported themselves
    # (``_can_create_ref(tuple) == False``), but their staged leaves often
    # are. ``_decompose_tuple`` creates per-element refs on the write side;
    # we mirror that on the read side so the caller gets a tuple of
    # freshly-loaded values rather than the rebound tuple object holding
    # SSA defined in a sibling scf.if region.
    if isinstance(current_value, tuple):

        def elem_slot(i: int) -> Any:
            return f"{slot_name}[{i}]" if slot_name is not None else None

        return tuple(
            pyir_read(
                f"{target_name}[{i}]",
                elem,
                attach_ref=attach_ref,
                owner=owner,
                slot_name=elem_slot(i),
            )
            for i, elem in enumerate(current_value)
        )

    # Slot-tracked container recursion: refresh each registered slot
    # so the returned container's attributes carry fresh-load values.
    # Symmetric to the tuple recursion above.  Required for callers
    # like ``pyir_read('work_tile', work_tile)`` inserted by
    # ``_prepare_while_condition_vars`` in scf.while before-blocks so the
    # @property getter reads a freshly-loaded Boolean (or other field)
    # instead of the construction-time cached SSA carried over from the
    # entry of the loop.
    #
    # Gated to staged CF -- outside, the legacy code below already loads
    # from any recorded ref via the slot-first lookup.  Primitives are
    # excluded; tuples / aggregate containers handled by the branch above.
    #
    # We MUST re-attach ``_mutable_ref`` to the freshly-loaded value so a
    # subsequent ``attach_ref=False`` snapshot read (e.g. ``cute.printf``
    # arg) can recover the ref via the value-keyed cache instead of
    # falling through to ``_create_ref`` Case-D poison.
    if (
        attach_ref
        and is_inside_staged_cf()
        and not isinstance(current_value, (int, float, bool, str, bytes))
    ):
        slots = _iter_slot_mvs_for_pyir_read(current_value)
        if slots:
            owner_cls = type(current_value)
            # Refuse silent rebind when the class overrides __setattr__:
            # the user's hook may have side-effects we cannot reason about,
            # and the alternative (calling type-specific __setattr__) would
            # re-trigger PyIR's instrumentation.  Skip refresh in that case
            # and fall through to the legacy path.
            if owner_cls.__setattr__ is object.__setattr__:
                refreshed = False
                for stored_slot_name, slot_mv in slots:
                    if slot_mv is None or not slot_mv._is_ref_accessible():
                        continue
                    # Skip subscript-style slot names (``'_coord[0]'``):
                    # those refer to tuple elements registered by
                    # ``_decompose_tuple`` under composite slot keys, not
                    # direct Python attributes.  ``setattr`` on them
                    # would create a synthetic ``box._coord[0]`` attribute
                    # that then breaks ``_decompose_m2m_assign``'s
                    # parallel walk on the next reassignment.
                    if not isinstance(stored_slot_name, str) or "[" in stored_slot_name:
                        continue
                    fresh = slot_mv.load()
                    # Re-attach the slot ref to the fresh value so
                    # later attach_ref=False snapshot reads can recover
                    # the ref via the value-keyed _mutable_ref cache.
                    _attach_mutable_ref(
                        fresh,
                        slot_mv,
                        f"pyir_read '{target_name}' slot-refresh",
                    )
                    try:
                        object.__setattr__(current_value, stored_slot_name, fresh)
                        refreshed = True
                    except (AttributeError, TypeError):
                        pass  # frozen / __slots__ without target -- best-effort
                if refreshed:
                    log().info(
                        "[pyir_read] '%s' slot-tracked container -> refreshed %d slot(s)",
                        target_name,
                        sum(
                            1
                            for _, mv in slots
                            if mv is not None and mv._is_ref_accessible()
                        ),
                    )
                    return current_value
            else:
                log().info(
                    "[pyir_read] '%s' slot refresh skipped: %s overrides __setattr__",
                    target_name,
                    owner_cls.__name__,
                )

    # Slot context is only authoritative when:
    # - caller supplied both owner and slot_name
    # - the owner is non-None (dict/list owners route through
    #   ``_slot_mvs``; ``__dict__`` owners use tier-1 / tier-2)
    # - this read will also attach _mutable_ref to the returned value
    #   (attach_ref=False reads are snapshots -- no ref tracking needed,
    #   and creating a ref here would introduce spurious iter_args).
    have_slot = (
        attach_ref
        and owner is not None
        and slot_name is not None
        and _slot_storage_available(owner)
    )

    if not is_inside_staged_cf():
        # Outside staged CF, but the value may have been modified inside
        # a now-exited CF region.  If a ref exists (slot-first, else on
        # the value), load from it so subsequent uses see the accumulated
        # result.
        if have_slot:
            mv = _get_slot_mv(owner, slot_name)
        else:
            mv = getattr(current_value, "_mutable_ref", None)
        if mv is not None and mv._is_ref_accessible():
            loaded = mv.load()
            log().info(
                "[pyir_read] '%s' outside CF but has ref → loaded",
                target_name,
            )
            if attach_ref:
                _attach_mutable_ref(loaded, mv, f"pyir_read '{target_name}' outside-CF")
            return loaded
        # D1: even outside CF, the slot may have been promoted earlier
        # (e.g. by a sibling for that fired _meta_promote_slot).  Load
        # from the D1 ref so post-CF reads see the accumulated result.
        d1_slot = _make_slot_key(target_name, owner, slot_name, _current_fn_id())
        if d1_slot is not None and d1_slot in _slot_refs:
            return _load_as_dsl(_slot_refs[d1_slot], current_value)
        log().info("[pyir_read] '%s' outside staged CF → passthrough", target_name)
        return current_value

    # D1 (META_VALUE_TABLE_DESIGN): when inside staged CF AND the slot is
    # tracked (or trackable) by the meta-value table, route through D1
    # instead of the legacy paths.
    #
    # - If the slot is already promoted, emit ``pyir.load %ref`` and
    #   return the matching DSL Numeric.  The promotion happened earlier
    #   in this trace (e.g. previous mutation).
    # - If the value is a Python primitive AND the slot is not yet
    #   promoted, wrap as ``_WatchedM`` so a later mutation can rewrite
    #   any leaf constants we bake during use.
    d1_slot = (
        None
        if target_name == "self.dummy"
        else _make_slot_key(target_name, owner, slot_name, _current_fn_id())
    )
    if d1_slot is not None:
        existing_ref = _slot_refs.get(d1_slot)
        if existing_ref is not None:
            sample = (
                current_value.python_value
                if isinstance(current_value, _WatchedM)
                else current_value
            )
            return _load_as_dsl(existing_ref, sample)
        if isinstance(current_value, _WatchedM):
            return current_value  # idempotent
        # Strict type check (NOT isinstance): IntEnum / IntFlag subclass int,
        # but wrapping them in _WatchedM strips their enum identity at the
        # @dsl_user_op coercion boundary -- downstream MLIR attr builders
        # then receive a bare int and fail (e.g. `#nvvm.tcgen05_ldst_shape<3>`
        # vs the expected `<shape16x32bx2>`).  Only true primitives are
        # mutated as D1 slots; enums are configuration values and should
        # pass through unchanged.  See PYIR_DEV_GUIDE.md Pitfall 15.
        if type(current_value) in (bool, int, float):
            return _WatchedM(current_value, d1_slot)

    if not _is_staged_value(current_value):
        # Mp→S auto-promotion (gated by CUTE_DSL_AUTO_M2S):
        # Promote meta-primitives (int/float/bool) to staged DSL types
        # inside staged CF.  Creates a pyir.ref so that arithmetic like
        # (c + 1) produces arith.addi(load(ref), 1) — a value that
        # depends on the ref — instead of a Python constant.
        # Only when attach_ref=True (assignment reads).  Standalone
        # reads (attach_ref=False, e.g. self.x in a format string)
        # must stay as Python scalars for meta-level operations.
        if (
            attach_ref
            and is_auto_m2s_enabled()
            and type(current_value) in (bool, int, float)
        ):
            try:
                promoted = _auto_promote_primitive(current_value)
                if promoted is not None and _can_create_ref(promoted):
                    # Mp->S: check slot first so the same meta-int bound
                    # to three attributes doesn't collapse onto one ref.
                    mv = None
                    if have_slot:
                        mv = _get_slot_mv(owner, slot_name)
                        if mv is not None and not mv._is_ref_accessible():
                            mv = None
                    if mv is None:
                        mv = _create_ref(promoted)
                        if have_slot:
                            _set_slot_mv(owner, slot_name, mv)
                    loaded = mv.load()
                    log().info(
                        "[pyir_read] '%s' Mp→S auto-promoted %r → %s + ref",
                        target_name,
                        current_value,
                        type(promoted).__name__,
                    )
                    from .diagnostics import WarnId, report_warning

                    # Warn about the promotion AND the stale-local risk: the
                    # slot is now tracked, but the caller's Python binding for
                    # ``target_name`` still holds the original value, so a read
                    # OUTSIDE this region could see the stale value.
                    report_warning(
                        WarnId.PHASE_AUTO_PROMOTED_TO_STAGED,
                        stacklevel=2,
                        var=target_name,
                        value=repr(current_value),
                        type=type(promoted).__name__,
                    )
                    if attach_ref:
                        _attach_mutable_ref(
                            loaded,
                            mv,
                            f"pyir_read '{target_name}' Mp→S auto-promotion",
                        )
                    return loaded
            except Exception:
                pass  # No MLIR context — fall through to passthrough
        log().info("[pyir_read] '%s' not staged → passthrough", target_name)
        return current_value

    if not _can_create_ref(current_value):
        log().info(
            "[pyir_read] '%s' type %s not ref-compatible → passthrough",
            target_name,
            type(current_value).__name__,
        )
        return current_value

    # Slot-first lookup: when owner/slot_name are supplied the slot
    # registry is authoritative.  Values that share a ref across slots
    # (e.g. ``self.a = self.b = self.c = seed``) previously collapsed
    # because ``_mutable_ref`` was attached to the shared value.
    # When the slot has no entry fall back to the value-keyed
    # ``_mutable_ref`` cache -- this keeps us interoperable with refs
    # created by legacy code paths (``attach_ref=False`` snapshot reads,
    # M->S promotions) so we do not duplicate ref storage.
    if have_slot:
        mv = _get_slot_mv(owner, slot_name)
        if mv is None:
            legacy_mv = getattr(current_value, "_mutable_ref", None)
            if legacy_mv is not None:
                mv = legacy_mv
                _set_slot_mv(owner, slot_name, mv)
    else:
        mv = getattr(current_value, "_mutable_ref", None)
    mv_was_preexisting = mv is not None
    log().info("[pyir_read] '%s' existing mv=%s", target_name, mv)

    if mv is None:
        # D1 bare Name-Load snapshot reads (``attach_ref=False`` AND no
        # owner/slot context) skip lazy ref creation -- the wrap is
        # only for ``_meta_uses`` recording on Python primitives.
        # ``self.X`` / ``obj.X`` snapshot reads pass ``owner`` and
        # ``slot_name`` so they continue to create the lazy ref.
        if not attach_ref and owner is None and slot_name is None:
            log().info(
                "[pyir_read] '%s' D1 bare snapshot -> passthrough",
                target_name,
            )
            return current_value
        mv = _create_ref(current_value)
        log().info("[pyir_read] '%s' ref created via _create_ref", target_name)
        if have_slot:
            _set_slot_mv(owner, slot_name, mv)
            # Reconstruct BEFORE attach when slot context is present so the
            # fresh wrapper carries this ref instead of the caller's
            # (potentially shared) value.  Without this, a later write to a
            # sibling slot would observe the same ``_mutable_ref`` and
            # alias back onto this slot.  When slot context is absent we
            # must attach to the caller's object directly -- the
            # value-keyed ``_mutable_ref`` cache is the only lookup path
            # available to subsequent reads.
            current_value = mv._reconstruct(current_value.ir_value())
        _attach_mutable_ref(current_value, mv, f"pyir_read '{target_name}' new-ref")

    if mv._is_ref_accessible():
        loaded = mv.load()
        log().info(
            "[pyir_read] '%s' loaded → %s",
            target_name,
            type(loaded).__name__,
        )
        # Always attach when the mv pre-existed (caller's ref, not
        # lazily created here): downstream auto-load via
        # ``_pyir_auto_load_arg`` needs ``_mutable_ref`` to recover a
        # dominating SSA when the loaded value crosses a region
        # boundary (e.g. cross-task data flow through a
        # non-instrumented dict round-trip).  The ``attach_ref=False``
        # option exists to prevent lazy ref leakage from snapshot reads,
        # not to strip refs that already exist.
        if attach_ref or mv_was_preexisting:
            _attach_mutable_ref(loaded, mv, f"pyir_read '{target_name}' loaded")
        return loaded

    # Ref exists but is inaccessible (defined in a sibling/exited CF region,
    # e.g. inside a previous meta-loop iteration's scf.if body).
    # current_value's SSA may not dominate the current insertion point.
    # Re-create the ref at the current scope so the load dominates.
    # _create_ref handles placement: literal-backed → function entry (Case A),
    # SSA-backed → after defining op or current IP (Cases B-D).
    try:
        mv = _create_ref(current_value)
        if have_slot:
            _set_slot_mv(owner, slot_name, mv)
        loaded = mv.load()
        log().info(
            "[pyir_read] '%s' ref inaccessible → re-created + loaded",
            target_name,
        )
        if attach_ref:
            _attach_mutable_ref(loaded, mv, f"pyir_read '{target_name}' re-created")
        return loaded
    except DSLUserCodeError:
        # Don't swallow user-facing diagnostics (e.g. poison-read catcher).
        raise
    except Exception:
        # If re-creation fails (e.g. non-ref-compatible type), passthrough.
        log().info("[pyir_read] '%s' ref not accessible → passthrough", target_name)
        return current_value


def _pyir_post_subscript_read(
    target_name: str,
    container: Any,
    key: Any,
) -> Any:
    """Read ``container[key]``, emitting ``pyir.load`` for tracked values.

    Called by AST-inserted code for every ``container[key]`` in Load
    context inside ``@cute.jit`` bodies.

    For dicts/lists: evaluates ``container[key]`` and passes through
    ``pyir_read`` with ``attach_ref=False`` to emit ``pyir.load`` when
    the value carries a ``_mutable_ref``.  Returns the loaded value
    (fresh SSA) or the original value if no ref exists.

    For non-dicts (GPU arrays, tensors, etc.): evaluates and returns
    ``container[key]`` directly (no overhead beyond the isinstance check).
    """
    val = container[key]
    if not isinstance(container, (dict, list)):
        return val
    return pyir_read(target_name, val, attach_ref=False)


def _pyir_pre_subscript_assign(
    target_name: str,
    container: object,
    key: object,
) -> object:
    """Read the old value from a subscript target for PyIR instrumentation.

    Called by AST-inserted code before every ``container[key] = expr`` and
    ``container[key] += expr`` inside ``@cute.jit`` bodies.

    Returns ``_PYIR_SKIP`` if the container is not a tracked Python
    container (e.g. GPU array, tensor, shared memory).

    Dicts are always tracked because cross-task state uses them even
    outside the immediate local CF body.  Python primitive dict entries
    remain meta values so trace-time counters can still drive
    ``const_expr`` dispatch.

    Lists are only tracked when the current ``@cute.jit`` body opened
    staged CF. This avoids instrumenting trace-time list fills inside
    nested ``@cute.jit`` helpers while still lifting list slot writes that
    would otherwise leak SSA across ``scf.if``/``scf.for`` regions.

    If the key does not yet exist in the container (first-time
    definition), returns ``None`` so that ``pyir_assign`` treats it as a
    first def.
    """
    if isinstance(container, list):
        if not is_inside_locally_staged_cf():
            return _PYIR_SKIP
    elif not isinstance(container, dict):
        return _PYIR_SKIP
    try:
        old = container[key]  # type: ignore[call-overload]
    except (KeyError, IndexError):
        return None
    if isinstance(container, dict) and isinstance(old, (bool, int, float)):
        return old
    # Pass owner/slot_name so the slot registry distinguishes subscript
    # entries that happen to hold the same Python value.  Without this,
    # three dict keys holding the same Int32 seed would collapse to a
    # single ``pyir.ref`` keyed off the shared value.
    return pyir_read(target_name, old, owner=container, slot_name=key)
