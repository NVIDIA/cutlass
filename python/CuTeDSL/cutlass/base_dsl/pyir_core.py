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


"""PyIR runtime -- core layer."""

import enum as _enum
import functools as _functools
import gc
import sys as _sys
import types
import inspect
import weakref

from typing import NoReturn

from .pyir_state import *  # noqa: F401,F403  (re-export lower layers up the chain)
from .pyir_state import _Sentinel


# Staleness tags stamped on every ``MutableValue.load`` result: the slot's load
# counter and the staged-CF depth the load was emitted at.
_PYIR_LOAD_VERSION_ATTR = "_pyir_load_version"
_PYIR_LOAD_DEPTH_ATTR = "_pyir_load_depth"
_PYIR_REGION_ENTRY_ATTR = "_pyir_region_entry"
# The ref's write-epoch at load time; ``_pyir_emit_store`` bumps it, so it also
# counts stores that bypassed the tagging ``MutableValue``.
_PYIR_REF_EPOCH_ATTR = "_pyir_ref_epoch"

# Per-ref write-epoch registry, keyed by the raw ``pyir.ref`` value; trace-scoped.
_REF_WRITE_EPOCH: "dict[Any, int]" = {}

# Closure-cell meta reads observed at a call boundary: slot key -> (name,
# callee file, callee line); promotion consults it to refuse loudly. Trace-scoped.
_PYIR_BOUNDARY_META_CELL_READS: "dict[Any, tuple[str, str, int]]" = {}

# Structural (``__index__``) consumptions of a meta place inside staged CF: slot
# key -> (label, file, line); promotion consults it to refuse loudly. Trace-scoped.
_PYIR_STRUCTURAL_META_CONSUMPTIONS: "dict[Any, tuple[str, str, int]]" = {}

# Where each structural consumption was witnessed: slot key -> (block, enclosing
# loop op). Kept beside ``_PYIR_STRUCTURAL_META_CONSUMPTIONS`` rather than widening
# its tuple, which several unpackers destructure positionally. Used to tell a
# re-seeded place (the loop body re-runs its binding before the fold is reached
# again, so the bake stays valid) from one whose value genuinely carries.
# Trace-scoped.
_PYIR_STRUCTURAL_META_CONSUMPTION_SITES: "dict[Any, tuple[Any, Any]]" = {}

# Meta writes admitted inside a staged-``if`` arm of the slot's own birth
# region (a per-iteration reset counter): slot key -> (arm block, file, line).
# In-arm consumptions fold their program point's value exactly; a consumption
# OUTSIDE the arm is path-dependent (the arm may not run) and refuses loudly.
# The next same-depth reset retires the mark. Trace-scoped.
_PYIR_ARM_LOCAL_META_WRITES: "dict[Any, tuple[Any, str, int]]" = {}

# Guard places a committed boundary loop-carry flip relied on: slot key ->
# (guard attr, flipped slot, callee file, callee line); promotion consults it.
_PYIR_BOUNDARY_FLIP_GUARD_READS: "dict[Any, tuple[str, str, str, int]]" = {}

# Host-restore ledger: (id(holder), slot) -> (holder, slot, pre-staging scalar
# binding, minting-context id).  Trace close re-points every recorded place still
# bound to THIS compilation's wrapper back to that binding; a leftover without a
# record keeps the stale-epoch refusal. Trace-scoped.
_PYIR_HOST_RESTORE: "dict[tuple[int, Any], tuple[Any, Any, Any, int]]" = {}

# Literal-backed STAGED predicate folds inside an enclosing loop: id(src wrapper)
# -> (payload repr, file, line); staged write chokes refuse on a hit. Trace-scoped.
_PYIR_STAGED_LITERAL_FOLD_WITNESSES: "dict[int, tuple[str, str, int]]" = {}
_PYIR_STAGED_LITERAL_FOLD_KEEPALIVE: "list[Any]" = []
_PYIR_TRACE_KEEPALIVES.append(_PYIR_STAGED_LITERAL_FOLD_KEEPALIVE)
# Promotion rewrite map: baked ``arith.constant`` -> the position-correct
# ``pyir.load`` that replaced its uses; new consumers follow it. Trace-scoped.
_META_CONST_REPLACEMENTS: "dict[Any, Any]" = {}


def _ref_write_epoch(ref: "Any") -> int:
    """Current write-epoch of *ref* (0 = never stored through the choke)."""
    if ref is None:
        return 0
    try:
        return _REF_WRITE_EPOCH.get(ref, 0)
    except TypeError:
        return 0  # unhashable ref stand-in -- no epoch tracking


def _get_load_version(v: "Any") -> "Optional[int]":
    """Return *v*'s load-version tag, or ``None`` if it is not a load."""
    return getattr(v, _PYIR_LOAD_VERSION_ATTR, None)


def _get_load_depth(v: "Any") -> "Optional[int]":
    """Return *v*'s staged-CF load-depth tag, or ``None`` if untagged."""
    return getattr(v, _PYIR_LOAD_DEPTH_ATTR, None)


def _get_load_epoch(v: "Any") -> "Optional[int]":
    """Return *v*'s ref-write-epoch tag, or ``None`` if untagged."""
    return getattr(v, _PYIR_REF_EPOCH_ATTR, None)


def _get_load_region_entry(v: "Any") -> "Optional[int]":
    """Return *v*'s region-entry-clock tag, or ``None`` if untagged."""
    return getattr(v, _PYIR_REGION_ENTRY_ATTR, None)


def _tag_load(v: "Any", version: int, depth: int, epoch: int = 0) -> None:
    """Tag *v* with the load *version*, staged-CF *depth*, ref write-*epoch*,
    and the region-entry clock it was loaded at.

    Best-effort: value types that reject attribute assignment simply go
    untagged (no dedup), which is safe.
    """
    object.__setattr__(v, _PYIR_LOAD_VERSION_ATTR, version)
    object.__setattr__(v, _PYIR_LOAD_DEPTH_ATTR, depth)
    object.__setattr__(v, _PYIR_REF_EPOCH_ATTR, epoch)
    object.__setattr__(v, _PYIR_REGION_ENTRY_ATTR, _pyir_region_entry_clock())
    _pyir_note_holder_write(v)  # one stamp covers the tag-attr cluster


def _pyir_adopt_stored_representative(mv: Any, wrapper: Any) -> None:
    """Record *wrapper* (a rewrap of the just-stored raw) as the cell's canonical
    representative and stamp the store tags (epoch + depth, no load-version)."""
    try:
        mv._value = wrapper
        object.__setattr__(wrapper, _PYIR_REF_EPOCH_ATTR, _ref_write_epoch(mv.ref))
        object.__setattr__(wrapper, _PYIR_LOAD_DEPTH_ATTR, current_staged_cf_depth())
        object.__setattr__(wrapper, _PYIR_REGION_ENTRY_ATTR, _pyir_region_entry_clock())
        _pyir_note_holder_write(wrapper)  # one stamp covers the tag-attr cluster
    except (AttributeError, TypeError):
        pass  # wrapper rejects attrs -- no staleness tracking.


def _is_func_boundary_op(op_name: str) -> bool:
    """Return True if *op_name* is a function-like op that owns an SSA body
    region where a ``pyir.ref`` may be hosted.

    Matches ``<dialect>.func``-named ops plus :data:`_NON_DOT_FUNC_ENTRY_OPS`
    (name-pattern, so new dialect function ops need no maintenance here).
    """
    return op_name.endswith(".func") or op_name in _NON_DOT_FUNC_ENTRY_OPS


def _is_module_boundary_op(op_name: str) -> bool:
    """Return True if *op_name* is a module-like symbol-table container.

    The entry-block walk stops here: a module owns no SSA region for a
    ``pyir.ref``, and walking past it risks recycled block wrappers.
    """
    return op_name in _MODULE_OPS or op_name.endswith(".module")


def _auto_promote_primitive(value: object) -> object | None:
    """Promote a Python ``bool``/``int``/``float`` to the matching DSL type.

    ``bool`` → ``Boolean``, ``int`` → ``Int32`` (``Int64`` for large),
    ``float`` → ``Float32`` (via ``as_numeric`` from ``typing.py``).

    Returns ``None`` on failure (import error, unsupported value).
    """
    try:
        from .typing import as_numeric

        return as_numeric(value)
    except (ImportError, TypeError, ValueError):
        return None


# Lazily bound ``multi_stage_manager._is_staged_value`` (layering: that module
# imports from the pyir chain at module top, so the binding resolves on first use).
_IS_STAGED_VALUE_FN: "Callable[[object], bool] | None" = None


def _can_create_ref(value: object) -> bool:
    """Return True if *value*'s type supports ``pyir.ref`` tracking.

    Only types with ``_pyir_ref_supported = True`` round-trip through
    ``MutableValue`` (numerics, DSL pointers); Array/Tensor/TensorMap do not.

    Pure (a plain ``getattr``): must NOT materialise ``ir_value()`` (it
    would pin a constant and corrupt the sibling cache).
    """
    return getattr(type(value), "_pyir_ref_supported", False)


def _is_scalar_ssa_carryable(value: object) -> bool:
    """True if *value* is a staged non-compound leaf whose baked backing is exactly
    one scalar int/float SSA value, so a single ``pyir.ref`` round-trips it."""
    global _IS_STAGED_VALUE_FN
    try:
        fn = _IS_STAGED_VALUE_FN
        if fn is None:
            from .multi_stage_manager import _is_staged_value

            fn = _IS_STAGED_VALUE_FN = _is_staged_value

        if (
            fn(value)
            and not isinstance(value, (bool, int, float, str, bytes, type))
            and not hasattr(value, "__extract_mlir_values__")
        ):
            raw = _raw_backing_ir_value(value)
            if raw is not None and isinstance(raw.type, (ir.IntegerType, ir.FloatType)):
                return True
    except Exception:
        return False
    return False


def _can_carry_leaf_ref(value: object) -> bool:
    """True if a decomposition leaf can carry through one ``pyir.ref``: superset of
    :func:`_can_create_ref` used only on decomposition / leaf-promotion paths."""
    return _can_create_ref(value) or _is_scalar_ssa_carryable(value)


def _is_vector_like(value: object) -> bool:
    """Return True if *value* is a multi-element MLIR vector type.

    Vectors take the uniform place-cell rules; this predicate only selects
    the generic ``pyir_read`` routing for loop-body write_args.
    """
    try:
        ir_val = value.ir_value()  # type: ignore[attr-defined]
        return isinstance(ir_val.type, ir.VectorType)
    except Exception:
        return False


def _mlir_types_match(old_value: object, new_value: object) -> bool:
    """True if both values carry the same MLIR type (read side-effect-free via
    ``_raw_backing_ir_value``). Conservative: True when indeterminate."""
    old_raw = _raw_backing_ir_value(old_value)
    new_raw = _raw_backing_ir_value(new_value)
    if old_raw is None or new_raw is None:
        return True
    try:
        return old_raw.type == new_raw.type
    except Exception:
        return True


def _types_match(old_value: object, new_value: object) -> bool:
    """Full slot type identity (V-4): the MLIR half AND the wrapper-class half.
    Conservative: True when either half is indeterminate."""
    if not _mlir_types_match(old_value, new_value):
        return False
    if type(old_value) is type(new_value):
        return True
    if _is_staged_value(old_value) and _is_staged_value(new_value):
        return False
    return True


def _is_memref_like(value: object) -> bool:
    """Return True if *value* is a memref-backed descriptor (recomputable wherever
    it dominates); declared via pyir's ``MemRefLikeTypeInterface``. Conservative: False."""
    try:
        ir_type = value.type if isinstance(value, ir.Value) else value.ir_value().type  # type: ignore[attr-defined]
    except Exception:
        return False
    if isinstance(ir_type, ir.MemRefType):
        return True
    if pyir is None:
        return False
    try:
        return bool(pyir.pyir_type_is_memref_backed(ir_type))
    except Exception:
        return False


def _pyir_raise_memref_inregion_alloc_rebind(var: Any) -> None:
    """Refuse loudly: a rebind under staged CF to a memref handle backed by an
    IN-REGION allocation aliases ONE entry-hoisted buffer per iteration."""
    name = str(var) if var is not None else "<value>"
    raise DSLUserCodeError(
        DiagId.MEMREF_INREGION_ALLOC_REBIND,
        name=name,
        region_kind=_pyir_enclosing_region_kind_at_ip(),
    )


def _pyir_type_is_register_memref(ir_type: Any) -> bool:
    """True iff *ir_type* is a REGISTER-backed memref-like handle (the
    declared ``isRegisterBacked`` fact of pyir's MemRefLikeTypeInterface).
    Conservative: False."""
    if pyir is None or not hasattr(pyir, "pyir_type_is_register_memref"):
        return False
    try:
        return bool(pyir.pyir_type_is_register_memref(ir_type))
    except Exception:
        return False


# Iteration-private scratch admissions: register-space memref-handle rebinds
# the liveness gate admitted at the store choke.  One record per admitted
# rebind store; the admitted cell threads as a carried buffer-identity phi
# (mem2reg promotes the slot into an scf iter_arg, the shape non-PyIR
# emits), and the trace-close sweep refuses any load whose consumers let a
# SUPERSEDED handle escape its window (see
# _pyir_verify_scratch_admissions).  Consumed by the trace-close sweep.
_PYIR_SCRATCH_ADMISSIONS: "list[dict]" = []

# Last memref-handle store per cell: [ref, stored raw, store op] entries the
# store choke maintains (one per cell, latest wins).  The auto-load stale-serve
# guard consults it to tell a wrapper holding the cell's CURRENT handle from a
# retained SUPERSEDED one.  Trace-scoped.
_PYIR_MEMREF_LAST_STORE: "list[list]" = []


def _pyir_note_memref_store(ref: "ir.Value", value: "ir.Value", store: Any) -> None:
    """Record *store* as the latest memref-handle store into *ref*.  Scan errors
    propagate: a silently skipped match would leave a stale first entry shadowing
    the update, making a superseded handle look CURRENT to the serve guard."""
    for entry in _PYIR_MEMREF_LAST_STORE:
        if _same_ir_value(entry[0], ref):
            entry[1] = value
            entry[2] = store
            return
    _PYIR_MEMREF_LAST_STORE.append([ref, value, store])


def _pyir_scratch_stale_serve_record(ref: Any, raw: "ir.Value | None") -> "dict | None":
    """The admission record of *ref* when *raw* is a SUPERSEDED handle of that
    admitted cell -- i.e. re-serving the wrapper through the cell would
    observe a fresh generation's buffer instead of the buffer Python
    retained.  ``None`` when *ref* is not an admitted cell, *raw* is the
    cell's current handle, or *raw* is a load taken after the last rebind.
    Both record scans walk internally-built entries only; scan errors propagate
    (an error swallowed to ``None`` here would serve the stale handle)."""
    if raw is None or ref is None or not _PYIR_SCRATCH_ADMISSIONS:
        return None
    rec_found = None
    for rec in _PYIR_SCRATCH_ADMISSIONS:
        if _same_ir_value(rec["ref"], ref):
            rec_found = rec
            break
    if rec_found is None:
        return None
    last_value = None
    last_store = None
    for entry in _PYIR_MEMREF_LAST_STORE:
        if _same_ir_value(entry[0], ref):
            last_value, last_store = entry[1], entry[2]
            break
    if last_value is None:
        return None
    if _same_ir_value(last_value, raw):
        return None  # the cell's current handle
    try:
        raw_owner = getattr(raw, "owner", None)
        if raw_owner is not None and not isinstance(raw_owner, ir.Block):
            raw_op = getattr(raw_owner, "operation", raw_owner)
            if str(getattr(raw_op, "name", "")) == "pyir.load" and _same_ir_value(
                raw_op.operands[0], ref
            ):
                # A load AFTER the last rebind is the current handle; a
                # retained pre-rebind load is superseded.
                if not _pyir_op_strictly_before(raw_op, last_store):
                    return None
    except Exception:
        pass
    return rec_found


def _pyir_refuse_stale_memref_serve(value: Any, mv: Any) -> None:
    """Refuse (loudly) serving *value* through its slot route *mv* when it is
    a SUPERSEDED handle of an ADMITTED rebound memref cell: the cell now
    carries a fresh generation, and under the one entry-hoisted buffer the
    slot-routed read would observe that generation's overwrites instead of
    the buffer Python retained.  No-op for anything else."""
    if not _PYIR_SCRATCH_ADMISSIONS or mv is None:
        return
    ref = getattr(mv, "ref", None)
    if ref is None:
        return
    raw = _raw_backing_ir_value(value)
    if raw is None or not _is_memref_like(raw):
        return
    rec = _pyir_scratch_stale_serve_record(ref, raw)
    if rec is None:
        return
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.MEMREF_STALE_SCRATCH_CONSUMED,
        filename=rec["filename"],
        lineno=rec["lineno"],
        name=rec["name"],
        consumer_loc=(
            f"{filename}:{lineno}" if filename is not None else "<unknown consumer>"
        ),
    )


def _pyir_op_transitive_consumer_loc(op: Any) -> "str | None":
    """Source location of the first projection-closed consumer of *op*'s
    results, or None when every transitive use is a dead projection chain.
    The walk runs in C++: Python-side result access would run the dialect
    value casters, which EMIT projection ops."""
    if pyir is None or not hasattr(pyir, "op_first_transitive_consumer_loc"):
        return "<consumer scan unavailable>"
    try:
        return pyir.op_first_transitive_consumer_loc(op)
    except Exception:
        return "<consumer scan failed>"


def _pyir_op_strictly_before(a: Any, b: Any) -> bool:
    """True iff *a* executes strictly before *b* (ancestors ordered in their
    deepest common block). Conservative: False."""
    if pyir is None or not hasattr(pyir, "op_strictly_before"):
        return False
    try:
        return bool(
            pyir.op_strictly_before(
                getattr(a, "operation", a), getattr(b, "operation", b)
            )
        )
    except Exception:
        return False


def _pyir_classify_transitive_consumers(
    op: Any, anchor: Any = None
) -> "tuple[int, str | None] | None":
    """Consumer classification of *op*'s results under the projection closure
    (CAPI fact): ``(mask, loc)`` with bit 1 = a consumer exists, bit 2 = a
    consumer CAPTURES the value (stored as data / region-carried / terminator
    / no effect anchored on the value; fail-closed), bit 4 = a non-capturing
    consumer not strictly before *anchor*; ``loc`` names the first offending
    consumer.  None when the fact is unavailable (callers refuse)."""
    if pyir is None or not hasattr(pyir, "op_classify_transitive_consumers"):
        return None
    try:
        mask, loc = pyir.op_classify_transitive_consumers(
            getattr(op, "operation", op),
            None if anchor is None else getattr(anchor, "operation", anchor),
        )
        return int(mask), loc
    except Exception:
        return None


def _pyir_load_in_rebind_reexecution_scope(load_op: Any, region_op: Any) -> bool:
    """True iff *load_op* sits inside *region_op* or inside a staged-CF
    ancestor of it -- the scopes whose runtime re-execution re-runs the
    rebind, so a handle captured there crosses an iteration boundary one
    generation stale.  Conservative: True on walk failure."""
    try:
        cur = getattr(region_op, "operation", region_op)
        while cur is not None:
            name = getattr(cur, "name", None)
            if name is None or _is_func_boundary_op(name):
                return False
            if name in _SCF_REGION_NAMES and _op_is_inside_op(load_op, cur):
                return True
            parent = cur.parent
            cur = getattr(parent, "operation", parent) if parent is not None else None
        return False
    except Exception:
        return True


def _pyir_admit_scratch_rebind(
    value: "ir.Value", ref: "ir.Value", region_op: Any, var: Any
) -> bool:
    """Liveness admission for an in-region register-memref rebind: the cell
    threads as a loop-carried buffer-identity phi (mem2reg promotes the slot
    into an scf iter_arg, exactly the shape non-PyIR emits), which is
    observationally exact under the one entry-hoisted buffer UNLESS a
    superseded handle stays reachable -- a CAPTURED old handle crosses an
    iteration boundary one generation stale.  Register space only (a
    hardware fact: no async engine extends a register buffer's lifetime
    beyond its handle).  The past half is decided here (an in-region load of
    the cell with a CAPTURING consumer refuses at the store); the witnessed
    halves -- captures and consumers emitted AFTER this store -- are
    enforced by the trace-close sweep over the recorded window."""
    if pyir is None or not hasattr(pyir, "op_classify_transitive_consumers"):
        return False  # no consumption facts -> the refusal stands
    try:
        if not _pyir_type_is_register_memref(value.type):
            return False
        region_norm = getattr(region_op, "operation", region_op)
        for use in ref.uses:
            user = getattr(use, "owner", None)
            user_op = getattr(user, "operation", user)
            if getattr(user_op, "name", "") != "pyir.load":
                continue
            if not _op_is_inside_op(user_op, region_norm):
                continue
            verdict = _pyir_classify_transitive_consumers(user_op)
            if verdict is None or verdict[0] & 2:
                return False  # old handle captured in-region: live alias
    except Exception:
        return False
    filename, lineno = _first_non_dsl_caller_location()
    _PYIR_SCRATCH_ADMISSIONS.append(
        {
            "ref": ref,
            "region": region_norm,
            "stored_raw": value,
            "name": str(var) if var is not None else "<value>",
            "filename": filename,
            "lineno": lineno,
        }
    )
    return True


def _pyir_scratch_value_admitted(value: Any, region_op: Any) -> bool:
    """True iff *value* is the stored handle of a scratch admission for
    *region_op*: the region-close carry walk skips it (the admitted store
    already went through the slot cell, which mem2reg promotes into the
    carried phi -- a dedicated carry ref would double-carry; the admission
    sweep owns the escape enforcement)."""
    if not _PYIR_SCRATCH_ADMISSIONS or not isinstance(value, ir.Value):
        return False
    region_norm = getattr(region_op, "operation", region_op)
    # A region-close RE-LOAD of the admitted slot names the same carried
    # handle as the recorded store (the walk re-reads the cell): match the
    # loaded-from ref alongside the raw stored handle.
    loaded_ref = None
    try:
        def_op = _get_defining_operation(value)
        if getattr(def_op, "name", None) == "pyir.load":
            loaded_ref = def_op.operands[0]
    except Exception:
        loaded_ref = None
    for rec in _PYIR_SCRATCH_ADMISSIONS:
        try:
            if rec["region"] != region_norm:
                continue
            if _same_ir_value(rec["stored_raw"], value):
                return True
            if loaded_ref is not None and _same_ir_value(rec["ref"], loaded_ref):
                return True
        except Exception:
            continue
    return False


def _pyir_verify_scratch_admissions() -> None:
    """Trace-close enforcement of the admitted rebinds: the cell itself
    threads as a carried buffer-identity phi (a load of the cell always
    names the CURRENT buffer), so the sweep polices only the escape routes
    of a SUPERSEDED handle -- (a) a CAPTURE of any load of the cell inside a
    scope whose runtime re-execution re-runs the rebind (the captured handle
    crosses that scope's iteration boundary one generation stale), and (b) a
    pre-rebind in-region load with a consumer not strictly before the next
    rebind store, or with no positional window at all (e.g. a
    while-condition read in the sibling region).  Violations refuse loudly
    at the consumer's source position.  Consumes the admission list."""
    if not _PYIR_SCRATCH_ADMISSIONS:
        return
    records = list(_PYIR_SCRATCH_ADMISSIONS)
    _PYIR_SCRATCH_ADMISSIONS.clear()
    for rec in records:
        region = rec["region"]
        ref = rec["ref"]

        def _refuse(consumer_loc: "str | None") -> NoReturn:
            raise DSLUserCodeError(
                DiagId.MEMREF_STALE_SCRATCH_CONSUMED,
                filename=rec["filename"],
                lineno=rec["lineno"],
                name=rec["name"],
                consumer_loc=consumer_loc or "<unknown consumer>",
            )

        # The use walk feeds the refusal decision; the per-use probes are
        # already conservative (defaulted getattrs, error-safe containment),
        # so a raise here is an internal failure of the walk itself -- refuse
        # rather than drop enforcement for this admitted rebind.
        try:
            loads: "list[Any]" = []
            stores_in: "list[Any]" = []
            for use in ref.uses:
                user = getattr(use, "owner", None)
                user_op = getattr(user, "operation", user)
                op_name = getattr(user_op, "name", "")
                if op_name == "pyir.load":
                    loads.append(user_op)
                elif op_name == "pyir.store" and _op_is_inside_op(user_op, region):
                    stores_in.append(user_op)
        except Exception:
            _refuse("<use walk failed>")
        for load_op in loads:
            verdict = _pyir_classify_transitive_consumers(load_op)
            if verdict is None:
                _refuse("<consumer facts unavailable>")
            if verdict[0] == 0:
                continue  # dead projection chain (machinery seed): no read
            anchor = None
            if _op_is_inside_op(load_op, region):
                after = [s for s in stores_in if _pyir_op_strictly_before(load_op, s)]
                if after:
                    # Pre-rebind load: its window closes at the NEXT rebind.
                    anchor = after[0]
                    for s in after[1:]:
                        if _pyir_op_strictly_before(s, anchor):
                            anchor = s
                elif not all(_pyir_op_strictly_before(s, load_op) for s in stores_in):
                    # A consumed load with no positional window w.r.t. some
                    # rebind store (e.g. a while-condition read in the
                    # sibling region): refuse.
                    _refuse(_pyir_op_transitive_consumer_loc(load_op))
            if anchor is not None:
                verdict = _pyir_classify_transitive_consumers(load_op, anchor)
                if verdict is None:
                    _refuse("<consumer facts unavailable>")
            mask, loc = verdict
            if mask & 4:
                _refuse(loc)  # consumer escaped the pre-rebind window
            if mask & 2 and _pyir_load_in_rebind_reexecution_scope(load_op, region):
                _refuse(loc)  # captured handle crosses an iteration boundary


def _pyir_ref_pointee_type_changed(ref: "ir.Value", value: object) -> bool:
    """True iff *value*'s baked MLIR type differs from *ref*'s pointee (a ref is
    single-typed; wrapper-class checks miss same-class rebinds). Conservative: False."""
    if ref is None:
        return False
    raw = _raw_backing_ir_value(value)
    if raw is None:
        return False
    try:
        return raw.type != ref.type.pointee
    except Exception:
        return False


def _pyir_enclosing_region_op_at_ip() -> "ir.Operation | None":
    """The innermost staged-CF region op enclosing the current insertion point,
    or None outside any staged region. Conservative: None."""
    try:
        block = ir.InsertionPoint.current.block
        for _ in range(64):
            op = block.owner
            op = getattr(op, "operation", op)
            name = getattr(op, "name", None)
            if name in _SCF_REGION_NAMES:
                return op
            if (
                name is None
                or _is_func_boundary_op(name)
                or _is_module_boundary_op(name)
            ):
                break
            parent_block = getattr(op, "block", None)
            if parent_block is None:
                break
            block = parent_block
    except Exception:
        pass
    return None


def _pyir_enclosing_region_kind_at_ip() -> str:
    """Human-readable name of the innermost staged region enclosing the current
    insertion point, for diagnostics; generic fallback when unresolvable."""
    op = _pyir_enclosing_region_op_at_ip()
    name = getattr(op, "name", None) if op is not None else None
    if name is None:
        return "a for/while/if body"
    return _SCF_REGION_NAMES.get(name, "a for/while/if body")


def _pyir_raise_type_changed_in_region(var: Any, old_type: Any, new_type: Any) -> None:
    """Refuse loudly: a type-changing rebind inside a staged region cannot be
    lifted to a single-typed iter_arg/if-result and must not be silently skipped."""
    raise DSLUserCodeError(
        DiagId.TYPE_CHANGED_INSIDE_REGION,
        var=str(var) if var is not None else "<value>",
        old_type=str(old_type),
        new_type=str(new_type),
        region=_pyir_enclosing_region_kind_at_ip(),
    )


def _pyir_raise_rebind_duplicate_leaf(obj: Any) -> None:
    """Refuse loudly: a whole-object rebind whose pre-region extract repeats
    an SSA value has no faithful positional leaf pairing -- first-match would
    silently cross-bind the duplicated positions."""
    raise DSLUserCodeError(
        DiagId.WRAPPER_REBIND_DUPLICATE_LEAF,
        cls=type(obj).__name__,
        region=_pyir_enclosing_region_kind_at_ip(),
    )


def _pyir_record_slot_template(place: Any, value: Any) -> None:
    """F-TYPEID: advance the place row's wrapper-template half at a store or
    publish choke; reads reconstruct the row from the recorded wrapper."""
    if place is None or value is None:
        return
    if isinstance(value, (_WatchedM, bool, int, float, str, bytes)):
        return
    _slot_templates[place] = value


def _declared_m2s_promotion_class(py_value: Any) -> "type | None":
    """The ONE declared Python-scalar -> staged-class fact: bool->Boolean,
    int->Int32 (widening to Int64 by value), float->Float32; ``None`` when no
    value-preserving declared width exists."""
    from .typing import Boolean, Int32, Int64, Float32

    if isinstance(py_value, bool):
        return Boolean
    if isinstance(py_value, int):
        if -(2**31) <= py_value < 2**31:
            return Int32
        if -(2**63) <= py_value < 2**63:
            return Int64
        return None
    if isinstance(py_value, float):
        return Float32
    return None


def _pyir_declared_promotion_template(
    py_value: Any, staged_type: "type | None" = None
) -> Any:
    """The declared M->S promotion identity: the staged write's own class, else
    the scalar's declared promotion class (literal-backed, no IR emitted)."""
    if staged_type is not None:
        try:
            return staged_type(py_value)
        except (TypeError, ValueError, AttributeError):
            pass
    default_cls = _declared_m2s_promotion_class(py_value)
    if default_cls is None:
        return None
    try:
        return default_cls(py_value)
    except (TypeError, ValueError, AttributeError):
        return None


def _pyir_rebook_place_cell(mv: "MutableValue") -> None:
    """After a type-transition re-mint, re-point the place's bare-ref row at the
    live ref (the other place-keyed tables map to the MutableValue and follow)."""
    place = getattr(mv, "_place", None)
    if place is None or mv._ref is None:
        return
    if place in _slot_refs:
        _slot_refs[place] = mv._ref
        _pyir_record_slot_template(place, mv._value)


def _is_boolean_like(value: object) -> bool:
    """Return True if *value* is a 1-bit integer (i1/Boolean) type.

    Booleans take the uniform place-cell rules; this predicate only selects
    the generic ``pyir_read`` routing for loop-body write_args.
    """
    try:
        ir_val = value.ir_value()  # type: ignore[attr-defined]
        return isinstance(ir_val.type, ir.IntegerType) and ir_val.type.width == 1
    except Exception:
        return False


def _is_literal_backed(dsl_value: object) -> bool:
    """Return True if *dsl_value* stores a Python scalar (not an ir.Value).

    Literal-backed values mint a fresh ``arith.constant`` per ``ir_value()``
    (safe at block_begin); SSA-backed values must dominate the ref point.
    """
    return isinstance(getattr(dsl_value, "value", None), (bool, int, float))


def _wrap_ir_like(template: Any, ir_val: "ir.Value") -> Any:
    """The ONE reconstruction funnel: rebuild a DSL value from *ir_val*
    mirroring *template* -- value-tree protocol, then shape/dtype ctor, then
    single-arg ctor; a template with no viable protocol refuses loudly."""
    # A row with no wrapper template holds an unwrapped SSA binding: the loaded
    # value IS the reconstruction (identity, not a guess). Exact-type test:
    # dialect value-caster classes SUBCLASS ir.Value yet carry a wrapper
    # identity and must take the strategies below.
    if template is None or type(template) in (
        ir.Value,
        ir.OpResult,
        ir.BlockArgument,
    ):
        return ir_val

    # Strategy 1: value-tree reconstruct protocol (TensorSSA-family wrappers).
    # Licensed ONLY by the full class-declared opt-in (BOTH protocol dunders):
    # a half-opt-in masquerade falls through to ctor replay or the loud
    # no-protocol refusal instead of an unlicensed reconstruct call.
    if _implements_dynamic_expression(template):
        new_from = getattr(template, "__new_from_mlir_values__", None)
        if callable(new_from):
            try:
                return new_from([ir_val])
            except Exception:
                pass  # fall through

    # Strategy 2: replay constructor with shape/dtype metadata.
    shape = getattr(template, "_shape", None)
    if shape is not None:
        dtype = getattr(template, "_dtype", None)
        try:
            return type(template)(ir_val, shape, dtype)
        except Exception:
            pass  # fall through

    # Strategy 3: simple single-arg constructor (scalar Numerics).
    try:
        return type(template)(ir_val)
    except Exception:
        raise DSLUserCodeError(
            DiagId.RECONSTRUCT_NO_PROTOCOL, cls=type(template).__name__
        ) from None


def _make_poison_like(dsl_value: Any, ir_val: "ir.Value") -> Any:
    """Create a ``ub.poison`` value of the same type as *dsl_value*.

    Case D-fallback ref init: the caller MUST ``store`` before any ``load``;
    a pre-store read surfaces the poison instead of a silent zero.

    Stamps the first non-DSL caller (file, line) on the op for the poison-read
    diagnostic; wraps via :func:`_wrap_ir_like`; zero-constant without ``ub``.
    """
    if ub is None:
        return _make_zero_like(dsl_value, ir_val)
    poison_ir = ub.PoisonOp(ir_val.type).result
    _record_poison_source(poison_ir)
    return _wrap_ir_like(dsl_value, poison_ir)


def _make_zero_like(dsl_value: Any, ir_val: "ir.Value") -> Any:
    """DEFINED zero/false placeholder init of *dsl_value*'s type: only dead bypass
    paths ever observe it, so it must not be a surviving ``ub.poison``."""
    zero_ssa = _make_raw_placeholder_init(ir_val.type)
    if zero_ssa is not None:
        return _wrap_ir_like(dsl_value, zero_ssa)
    # Non-scalar / unrecognised type: fall back to a type-correct ``ub.poison``;
    # the store-after-def still dominates every real read.
    if ub is not None:
        poison_ir = ub.PoisonOp(ir_val.type).result
        _record_poison_source(poison_ir)
        return _wrap_ir_like(dsl_value, poison_ir)
    # No ``ub`` and not a recognised scalar: last-resort literal wrapper.
    return type(dsl_value)(0)


def _pyir_type_is_scalar(ir_type: "ir.Type") -> bool:
    """True for scalar MLIR types (int/index/standard float): safe to materialize
    in Python; any other type may have a dialect value caster that emits ops."""
    try:
        return isinstance(
            ir_type,
            (
                ir.IntegerType,
                ir.IndexType,
                ir.F16Type,
                ir.F32Type,
                ir.F64Type,
                ir.BF16Type,
            ),
        )
    except Exception:
        return False


def _make_raw_placeholder_init(ir_type: "ir.Type") -> "ir.Value | None":
    """Emit a stamped zero/false ``arith.constant`` stand-in init for a SCALAR
    *ir_type*, as a bare ``ir.Value`` (never DSL-wrapped); ``None`` for non-scalar."""
    from .._mlir.dialects import arith as _arith

    zero_ssa: "ir.Value | None" = None
    try:
        if isinstance(ir_type, (ir.IntegerType, ir.IndexType)):
            zero_ssa = _arith.constant(ir_type, 0)
        elif isinstance(ir_type, (ir.F16Type, ir.F32Type, ir.F64Type, ir.BF16Type)):
            zero_ssa = _arith.constant(ir_type, 0.0)
    except Exception:
        zero_ssa = None
    if zero_ssa is not None and isinstance(zero_ssa, ir.Value):
        _record_placeholder_init_source(zero_ssa)
        return zero_ssa
    return None


def _mint_write_only_placeholder_cell(
    dsl_value: Any, ir_type: "ir.Type", entry_block: "ir.Block"
) -> "MutableValue | None":
    """Mint a write-only placeholder cell for a non-scalar type entirely in C++
    (the poison init never materializes in Python); ``None`` when unavailable."""
    if pyir is None or not hasattr(pyir, "mint_write_only_placeholder_cell"):
        return None
    src_file, src_line = _first_non_dsl_caller_location()
    try:
        ref = pyir.mint_write_only_placeholder_cell(
            ir_type, entry_block, src_file or "", src_line or 0
        )
    except Exception:
        return None
    if not isinstance(ref, ir.Value):
        return None
    # The C++ helper stamped a `ub.poison` placeholder init that Python never
    # touches; count it so the verify-boundary fast path stays sound.
    _count_poison_emitted()
    mv = MutableValue(dsl_value)
    mv._ref = ref
    mv._ref_context_id = id(ir.Context.current)
    return mv


def _mint_ref_with_raw_init(dsl_value: Any, init_ir: "ir.Value") -> "MutableValue":
    """Build a ``MutableValue`` whose ref is minted from the raw stand-in
    *init_ir*; the wrapper template stays the REAL value so loads reconstruct."""
    mv = MutableValue(dsl_value)
    mv._ref = pyir.ref(init_ir)
    mv._ref_context_id = id(ir.Context.current)
    return mv


# Bound on the lazy caller-location climb: a pathological stack must not turn
# a diagnostic annotation into a linear-cost walk.
_CALLER_LOCATION_MAX_CLIMB = 256


def _first_non_dsl_caller_location() -> "tuple[str | None, int | None]":
    """(filename, lineno) of the first non-DSL caller frame, for diagnostics only;
    a bounded ``sys._getframe`` climb keyed on module top-level package name."""
    dsl_top_level = __name__.split(".", 1)[0]
    try:
        # Start two frames up: skip this helper and its recording caller,
        # matching the frame selection the renderers rely on.
        frame: "types.FrameType | None" = sys._getframe(2)
    except ValueError:
        return None, None
    for _ in range(_CALLER_LOCATION_MAX_CLIMB):
        if frame is None:
            break
        mod_name = frame.f_globals.get("__name__", "")
        if not (mod_name == dsl_top_level or mod_name.startswith(dsl_top_level + ".")):
            return frame.f_code.co_filename, frame.f_lineno
        frame = frame.f_back
    return None, None


# Poison / placeholder inits stamped since the last verify boundary; the
# used-poison scan skips the module walk when zero.
_POISON_EMITTED: int = 0


def _count_poison_emitted() -> None:
    global _POISON_EMITTED
    _POISON_EMITTED += 1


def _record_poison_source(poison_value: "ir.Value") -> None:
    """Stamp the first non-DSL caller location onto the fresh ``ub.poison`` op so
    the end-of-trace catcher can render a diagnostic without MLIR loc info."""
    _count_poison_emitted()
    src_file, src_line = _first_non_dsl_caller_location()
    if src_file is None:
        return
    try:
        poison_op = poison_value.owner
        poison_op.attributes["pyir.poison_src_file"] = ir.StringAttr.get(src_file)
        poison_op.attributes["pyir.poison_src_line"] = ir.IntegerAttr.get(
            ir.IntegerType.get_signless(32), src_line
        )
    except (AttributeError, TypeError):
        pass


def _record_placeholder_init_source(placeholder_value: "ir.Value") -> None:
    """Mark a placeholder-init constant (unconditional ``pyir.placeholder_init``
    attr + best-effort source attrs) so an uncovered read of it faults loudly."""
    _count_poison_emitted()
    try:
        ph_op = placeholder_value.owner
        ph_op.attributes["pyir.placeholder_init"] = ir.UnitAttr.get()
    except (AttributeError, TypeError):
        return
    src_file, src_line = _first_non_dsl_caller_location()
    if src_file is None:
        return
    try:
        ph_op.attributes["pyir.placeholder_init_src_file"] = ir.StringAttr.get(src_file)
        ph_op.attributes["pyir.placeholder_init_src_line"] = ir.IntegerAttr.get(
            ir.IntegerType.get_signless(32), src_line
        )
    except (AttributeError, TypeError):
        pass


def _get_defining_operation(ir_val: ir.Value) -> ir.Operation:
    """Return the ``ir.Operation`` that defines an ``OpResult``."""
    owner = ir_val.owner
    return getattr(owner, "operation", owner)


def _get_function_entry_block() -> ir.Block | None:
    """Walk up from the current insertion point to find the enclosing
    function-like op's entry block.

    Returns the entry block, or ``None``. Stops at the nearest function
    boundary and never walks past a module container (recycled-wrapper hazard).
    """
    try:
        block = ir.InsertionPoint.current.block
    except Exception:
        return None

    # Bound the walk by IR nesting depth, not an id() visited-set: recycled
    # wrapper ids / a non-None recycled op.block could loop into a SIGSEGV.
    _MAX_NESTING = 256

    for _ in range(_MAX_NESTING):
        if block is None:
            break
        try:
            parent = block.owner  # Block → Python dialect op
        except Exception:
            break
        op = getattr(parent, "operation", parent)  # → ir.Operation

        try:
            op_name = str(op.name)
        except Exception:
            break

        if _is_func_boundary_op(op_name):
            return op.regions[0].blocks[0]

        # A module container is the symbol-table root (no enclosing function); stop
        # rather than walk into the binding's recycled module-block aliasing.
        if _is_module_boundary_op(op_name):
            break

        try:
            block = op.block  # ir.Operation → parent Block
        except Exception:
            break

    return None


def _pyir_recorded_birth_block(
    target_name: "str | None", owner: Any, slot_name: Any
) -> "ir.Block | None":
    """The place's recorded F-BIRTHPOS block (``None`` when unrecorded)."""
    try:
        slot = _make_slot_key(target_name, owner, slot_name)
    except Exception:
        return None
    if slot is None:
        return None
    return _slot_first_def_block.get(slot)


def _mint_region_born_cell(
    dsl_value: Any, birth_block: "ir.Block", entry_block: "ir.Block"
) -> "MutableValue | None":
    """Mint the cell for a region-born place: undefined-placeholder entry init
    (dominance device) + the seed stored at the recorded birth block
    (invariant E).

    ``None`` when no placeholder init is constructible (legacy placement
    applies); refuses when the seed has no position inside the birth block."""
    # A memref-backed descriptor is a recomputable value handle with no entry
    # cell (Case D's declared arm): seed semantics do not apply.
    if _is_memref_like(dsl_value):
        return None
    # Locate the seed at its binding position: a literal re-materialises inside
    # the birth block; an SSA seed keeps its defining position.
    seed_raw = _raw_backing_ir_value(dsl_value)
    if seed_raw is None:
        if _is_literal_backed(dsl_value):
            with ir.InsertionPoint.at_block_begin(birth_block):
                seed_raw = dsl_value.ir_value()
        else:
            seed_raw = dsl_value.ir_value()
    # Seed placement: after a same-block def; at block begin for a dominating
    # outer def; no position exists otherwise (LAW 3 fabricates none).
    seed_owner = seed_raw.owner
    if isinstance(seed_owner, ir.Block):
        seed_def_op = None
        seed_in_birth = seed_owner == birth_block
    else:
        seed_def_op = getattr(seed_owner, "operation", seed_owner)
        seed_in_birth = seed_def_op.block == birth_block
    if not seed_in_birth and not pyir.value_dominates_ip(seed_raw, birth_block, None):
        src_file, src_line = _first_non_dsl_caller_location()
        raise DSLUserCodeError(
            DiagId.BODY_BORN_SEED_UNPLACEABLE,
            filename=src_file,
            lineno=src_line,
            var=type(dsl_value).__name__,
        )
    mv: "MutableValue | None"
    with ir.InsertionPoint.at_block_begin(entry_block):
        init_ir = _make_raw_placeholder_init(seed_raw.type)
        if init_ir is not None:
            mv = _mint_ref_with_raw_init(dsl_value, init_ir)
        else:
            mv = _mint_write_only_placeholder_cell(
                dsl_value, seed_raw.type, entry_block
            )
    if mv is None:
        return None
    if seed_in_birth and seed_def_op is not None:
        seed_ip = ir.InsertionPoint.after(seed_def_op)
    else:
        seed_ip = ir.InsertionPoint.at_block_begin(birth_block)
    # Init-like raw emission (the mint is not a store event): the cell's
    # template already IS *dsl_value*, so no wrapper facts need advancing.
    with seed_ip:
        _pyir_emit_store(seed_raw, mv._ref, choke="region-born birth seed")
    return mv


def _create_ref(
    dsl_value: Any, birth_block: "ir.Block | None" = None
) -> "MutableValue":
    """Create a ``MutableValue`` + ``pyir.ref`` with correct placement.

    *birth_block* is the place's recorded first-def block (F-BIRTHPOS); a
    region-born place takes an undefined-placeholder entry init plus a real
    seed store at that block, so the binding executes where Python executes it.

    Placement strategy (4 cases, most optimal to most conservative):

    **Case A** — Literal-backed: function entry block begin (a fresh
        ``arith.constant`` per ``ir_value()``, dominance guaranteed).

    **Case B** — Entry-block argument: entry block begin (block args
        dominate their whole block).

    **Case C** — Entry-block OpResult: immediately after the defining op.

    **Case D** — Everything else: current insertion point (the value
        dominates it — Python is using it here).

    **Case D-fallback** — Non-dominating sibling-scope SSA: a ``ub.poison`` ref
        at function entry; the caller stores immediately (pre-store loads = UB).
    """
    # Some mint paths may fail to construct a stand-in cell (None) before the
    # in-branch fallback re-mints; declare the union once for every branch.
    mv: "MutableValue | None"
    entry_block = _get_function_entry_block()

    # Invariant E: a place first bound inside an open region seeds at its birth
    # block; entry placement stays a pure dominance device (placeholder init).
    if (
        birth_block is not None
        and entry_block is not None
        and pyir is not None
        and _block_strictly_inside(birth_block, entry_block)
    ):
        mv = _mint_region_born_cell(dsl_value, birth_block, entry_block)
        if mv is not None:
            return mv

    if entry_block is not None:
        # Case A: literal-backed -> fresh constant at entry block begin (the mint
        # site is not the binding position; the literal is the unconditional seed).
        if _is_literal_backed(dsl_value):
            with ir.InsertionPoint.at_block_begin(entry_block):
                mv = MutableValue(dsl_value)
                mv.take_reference()
            return mv

        ir_val = dsl_value.ir_value()

        # Case B: key on owner type (Block->BlockArgument, Operation->OpResult);
        # isinstance on ir_val is unreliable (DSL wrappers extend Value directly).
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

    if entry_block is not None and pyir is not None:
        current_block = ir.InsertionPoint.current.block

        if pyir.is_value_in_ancestor_region(ir_val, current_block):
            # A memref-backed descriptor is a recomputable value handle: its ref
            # is a current-IP anchor, re-minted when a later access cannot reach it.
            if _is_memref_like(dsl_value):
                log().info(
                    "[_create_ref] Case D: memref descriptor -> ref at current "
                    "IP (recomputable value handle, no entry cell)"
                )
                mv = MutableValue(dsl_value)
                mv.take_reference()
                return mv

            # Value dominates the IP: one entry-block cell per place (never region-
            # trapped), seeded by a store-after-def; init is a DEFINED zero placeholder.
            log().info(
                "[_create_ref] Case D: zero-init ref at entry "
                "block + store after defining op"
            )
            with ir.InsertionPoint.at_block_begin(entry_block):
                init_ir = _make_raw_placeholder_init(ir_val.type)
                if init_ir is not None:
                    mv = _mint_ref_with_raw_init(dsl_value, init_ir)
                else:
                    # Non-scalar: mint the write-only placeholder cell in C++ so
                    # the poison init never materializes as a Python value.
                    mv = _mint_write_only_placeholder_cell(
                        dsl_value, ir_val.type, entry_block
                    )
                if mv is None:
                    # No stand-in constructible: fall back to the wrapped
                    # zero/poison template (pre-existing behavior).
                    init_dsl = _make_zero_like(dsl_value, ir_val)
                    mv = MutableValue(init_dsl)
                    mv.take_reference()
            # The seed's write-fact is position + value: anchor the store at
            # the defining position of the SAME raw ``mv.store`` emits (the
            # value's own baked backing).  ``ir_val`` can be a choke-time
            # ``ir_value()`` re-serve emitted at the ambient (possibly
            # region-interior) IP; anchoring there while storing the exterior
            # backing leaves the entry placeholder live on every path outside
            # that region, so a later region-exterior serve of the cell reads
            # a value it was never given.
            seed_raw = _raw_backing_ir_value(dsl_value)
            if seed_raw is None or not pyir.is_value_in_ancestor_region(
                seed_raw, current_block
            ):
                seed_raw = ir_val
            seed_owner = seed_raw.owner
            if isinstance(seed_owner, ir.Block):
                with ir.InsertionPoint.at_block_begin(seed_owner):
                    mv.store(dsl_value)
            else:
                seed_def = getattr(seed_owner, "operation", seed_owner)
                with ir.InsertionPoint.after(seed_def):
                    mv.store(dsl_value)
            return mv

        # D-fallback (value does not dominate): poison-init ref at function entry,
        # caller stores immediately; non-scalar placeholders are minted in C++.
        log().info(
            "[_create_ref] Case D-fallback: value does not dominate "
            "current IP → poison-init ref at entry block"
        )
        with ir.InsertionPoint.at_block_begin(entry_block):
            mv = None
            if not _pyir_type_is_scalar(ir_val.type):
                mv = _mint_write_only_placeholder_cell(
                    dsl_value, ir_val.type, entry_block
                )
            if mv is None:
                poison_dsl = _make_poison_like(dsl_value, ir_val)
                mv = MutableValue(poison_dsl)
                mv.take_reference()
        return mv

    mv = MutableValue(dsl_value)
    mv.take_reference()
    return mv


def _pyir_emit_store(
    value: "ir.Value", ref: "ir.Value", *, choke: str = "", var: Any = None
) -> Any:
    """The single ``pyir.store`` emission choke: refuses unfaithful stores
    loudly and advances the cell's write-epoch."""
    _pointee = None
    try:
        _pointee = ref.type.pointee
        _mismatch = value.type != _pointee
    except Exception:
        _mismatch = False
    if _mismatch:
        raise DSLRuntimeError(
            "PyIR internal error: type-unfaithful pyir.store"
            + (f" at {choke}" if choke else "")
            + f": value type {value.type} does not equal the cell pointee "
            f"type {_pointee}. Every store path must re-mint the cell at "
            "the new type (function-scope redefinition) or refuse the "
            "in-region type transition before emitting."
        )
    # A value stored into a cell that outlives the enclosing staged region
    # must not root in an in-region allocation (entry-hoisted alias): the
    # escaped identity crosses the iteration boundary one generation stale.
    # The judgment is TYPE-UNIFORM -- the operand-cone Allocate fact, cut at
    # Read producers and block arguments, fires only for identity-carrying
    # values (handles, pointers, views), never content-derived scalars.
    # Register-backed memref handles go through the liveness gate (carried-
    # phi admission); every other alloc-rooted value refuses -- no declared
    # space/lifetime fact can prove its aliasing faithful.
    _region = _pyir_enclosing_region_op_at_ip()
    if (
        _region is not None
        and not _ir_value_defined_inside_op(ref, _region)
        and _pyir_memref_alloc_rooted_inside_region(value, _region)
    ):
        if not _is_memref_like(value) or not _pyir_admit_scratch_rebind(
            value, ref, _region, var
        ):
            _pyir_raise_memref_inregion_alloc_rebind(var)
    store = pyir.store(value, ref)
    if _is_memref_like(value):
        _pyir_note_memref_store(ref, value, getattr(store, "operation", store))
    # Bump the ref's write-epoch so cached loads are invalidated even when the
    # store bypassed their ``MutableValue``.
    try:
        _REF_WRITE_EPOCH[ref] = _REF_WRITE_EPOCH.get(ref, 0) + 1
    except TypeError:
        pass  # unhashable ref stand-in -- no epoch tracking
    return store


class _SlotId(_NamedTuple):
    kind: "_Literal['scope', 'attr', 'subscript']"
    owner: int  # id(owner_obj), or the owning scope_id for a bare-name slot
    key: Any


def _purge_owner_slots(owner_id: int) -> None:
    """Remove every ``_SLOT_REGISTRY`` entry owned by *owner_id* (weakref
    finalizer callback on owner GC)."""
    dead = [sid for sid in _SLOT_REGISTRY if sid.owner == owner_id]
    for sid in dead:
        _SLOT_REGISTRY.pop(sid, None)
    _OWNER_KEEPALIVE.pop(owner_id, None)


# Owner types already reported as non-weakref-able (the arm re-fires per
# write; the debug note is per-type).
_NON_WEAKREF_OWNER_TYPES_SEEN: "set[str]" = set()


def _ensure_owner_finalizer(owner: object) -> None:
    """Attach a weakref to *owner* so its slot entries are purged on GC.

    Some built-ins (``dict``, ``list``, ``int``) reject weakrefs; their slot
    entries then persist until ``_exit_function_trace`` clears the registry.
    """
    owner_id = id(owner)
    if owner_id in _OWNER_KEEPALIVE:
        return

    def _on_owner_collected(_ref: Any, oid: int = owner_id) -> None:
        _purge_owner_slots(oid)

    try:
        _OWNER_KEEPALIVE[owner_id] = _weakref.ref(owner, _on_owner_collected)
    except TypeError:
        # Object doesn't support weakref (the normal path for exact
        # dict/list); entries persist until trace exit clears the registry.
        if (tname := type(owner).__name__) not in _NON_WEAKREF_OWNER_TYPES_SEEN:
            _NON_WEAKREF_OWNER_TYPES_SEEN.add(tname)
            log().debug(
                "slot owner type %s is not weakref-able; its slot rows "
                "persist until trace exit",
                tname,
            )


def _current_scope_id(context: str) -> int:
    """Scope id of the innermost open scope frame; an empty stack is an internal
    error (a scope-agnostic fallback would alias same-named locals)."""
    if not _PYIR_SCOPE_STACK:
        raise DSLRuntimeError(
            "PyIR internal error: no function scope is open for a bare-name "
            f"slot operation on '{context}'; every instrumented function body "
            "opens its scope at entry, so slot operations must execute inside "
            "a traced function."
        )
    return _PYIR_SCOPE_STACK[-1].scope_id


def _make_slot_id(owner: "object | None", key: Any) -> _SlotId:
    """Structural slot id: bare names key on the current scope id, dict/list
    owners on ('subscript', id, key), other owners on ('attr', id, name)."""
    if owner is None:
        return _SlotId("scope", _current_scope_id(key), key)
    if isinstance(owner, (dict, list)):
        _ensure_owner_finalizer(owner)
        return _SlotId("subscript", id(owner), key)
    _ensure_owner_finalizer(owner)
    return _SlotId("attr", id(owner), key)


_CE_ABSENT = _Sentinel("constexpr snapshot absent")


def _cell_home_binding(scope_id: int, name: str) -> "tuple[int, str]":
    """LangRef 3.12 section 7.13: a ``nonlocal`` name IS the nearest enclosing
    scope's binding (one shared cell), so its place resolves to the cell's
    HOME row.  Resolution composes two declared facts -- the scope's syntactic
    ``nonlocal`` set and its registered cell token; absent either fact the
    scope keeps its own row (the staged-CF twin then refuses loudly)."""
    if name in _PYIR_SCOPE_NONLOCAL_NAMES.get(scope_id, ()):
        toks = _PYIR_SCOPE_CELL_TOKENS.get((scope_id, name))
        if toks:
            # The scope's ENTRY registration is first: the freevar cell itself
            # (later same-key registrations are region-frame carry cells).
            home = _PYIR_CELL_HOME_BINDING.get(toks[0])
            if home is not None:
                return home
    return (scope_id, name)


def _ce_local_key(scope_id: int, name: str) -> tuple:
    """F-CEPLACE local key: instance-qualified when the binding was BORN
    inside a constexpr instance (open or closed -- the row stays reachable
    after the instance exits, e.g. a const_expr-if-born local read after the
    if); the shared key for an outside-born or pre-observation binding.
    A ``nonlocal`` name first resolves to its cell's home binding."""
    scope_id, name = _cell_home_binding(scope_id, name)
    owner = _CE_BINDING_OWNER.get((scope_id, name))
    if owner is not None:
        return ("local", scope_id, name, owner)
    return ("local", scope_id, name)


def _ce_note_local_assign(name: str, *, continues_binding: bool = False) -> None:
    """ASSIGN choke (every ``=``/``+=`` of a bare local): maintain the
    binding-BIRTH ownership fact.  A live binding (outside-born ``None`` row
    or an owner instance still open) keeps its birth owner -- a rebind never
    changes ownership.  Python semantics: a REBIND of an existing binding
    (*continues_binding*, the choke read the bound value before assigning)
    never creates a new binding either, so it keeps the birth owner even
    after the owning constexpr instance closed.  A dead-owner pure first-def
    (the re-executed birth statement of a per-iteration local) births a NEW
    logical binding owned by the innermost open instance."""
    from .multi_stage_manager import (
        open_constexpr_instance_serial,
        open_constexpr_instance_serials,
    )

    if not _PYIR_SCOPE_STACK:
        return
    key = _cell_home_binding(_PYIR_SCOPE_STACK[-1].scope_id, name)
    rec = _CE_BINDING_OWNER.get(key, _CE_ABSENT)
    if rec is not _CE_ABSENT and (
        rec is None or rec in open_constexpr_instance_serials()
    ):
        return  # live binding: the birth fact is unchanged by a rebind
    if rec is not _CE_ABSENT and continues_binding:
        return  # dead-owner REBIND: the one logical binding continues
    _CE_BINDING_OWNER[key] = open_constexpr_instance_serial()


def pyir_seed_param_bindings(*names: str) -> None:
    """Scope entry: DECLARE each parameter binding outside-born (``ce_owner``
    ``None``) so a later rebind inside a constexpr instance keeps the one
    shared row -- the fact is seeded, never defaulted from absence.  Python
    semantics: a parameter binding IS a first-def at fn entry, so each param
    place also carries the entry first-def-depth fact (a same-depth rebind in
    this activation is straight-line, never a join; deeper rebinds refuse)."""
    if not _PYIR_SCOPE_STACK:
        return
    scope_id = _PYIR_SCOPE_STACK[-1].scope_id
    entry_depth = current_staged_cf_depth()
    for name in names:
        _CE_BINDING_OWNER[(scope_id, name)] = None
        place = _ce_local_key(scope_id, name)
        if place is not None and place not in _slot_first_def_depth_any:
            _slot_first_def_depth_any[place] = entry_depth


def _make_slot_key(
    target_name: "str | None", owner: Any = None, slot_name: Any = None
) -> Any:
    """Canonical ledger PLACE key: locals on the (instance-qualified)
    (scope_id, name) binding fact, owner slots on stable owner tokens (never
    id()); ``None`` when no key is derivable."""
    if owner is not None and slot_name is not None:
        return _corrected_place_for(owner, slot_name)
    if target_name is not None:
        return _ce_local_key(_current_scope_id(target_name), target_name)
    return None


def _pyir_owner_slot_is_computed(owner: Any, slot_name: Any) -> bool:
    """True when *slot_name* on ``type(owner)`` is a property-family descriptor
    whose value is produced by class code, not read from instance storage: no
    storage place exists for the pair, so the read is anonymous (F-SHAPE).
    A subscripted spelling (``coord[0]``) is judged by its base attribute --
    an element of a computed aggregate is itself computed.  A tuple's storage
    places are its element cells, so a named field on a tuple (a namedtuple
    accessor) is always computed."""
    if isinstance(owner, (dict, list)):
        return False
    if isinstance(slot_name, _PlaceSeg):
        base = slot_name.base
    elif isinstance(slot_name, str):
        base = slot_name
    else:
        return False
    if isinstance(owner, tuple):
        return True
    if not isinstance(base, str):
        return False  # exact item-key base: no class descriptor to consult
    try:
        for klass in type(owner).__mro__:
            desc = klass.__dict__.get(base)
            if desc is None:
                continue
            if isinstance(desc, property):
                return True
            if isinstance(desc, _functools.cached_property):
                # A materialized cache entry is instance storage.
                inst = getattr(owner, "__dict__", None)
                return not (inst is not None and base in inst)
            return False
    except Exception:
        return False
    return False


def _pyir_read_place(target_name: Any, owner: Any, slot_name: Any) -> Any:
    """R0: the read's ledger place, derived unconditionally -- owner slots on
    the token-rooted key, bare names on the (instance-qualified) local key.
    Constexpr scopes gate instrumentation only, never place production: the
    per-instance identity is a PRODUCED key fact (F-CEPLACE)."""
    try:
        return _make_slot_key(
            target_name if isinstance(target_name, str) else None, owner, slot_name
        )
    except Exception:
        return None


def _pyir_route_is_live_place_row(mv: Any) -> bool:
    """True when *mv* IS the ledger's live row for its own stamped place: the
    route carries place authority (R1) -- a re-read through it is a read of
    the place, not a value-identity guess."""
    place = getattr(mv, "_place", None)
    if place is None:
        return False
    try:
        return _PLACE_REGISTRY.get(place) is mv
    except Exception:
        return False


def _pyir_route_is_current(value: Any, mv: "MutableValue") -> bool:
    """V-2 CURRENT: *value* still equals its cell's content, so a reload
    through the route is exact.  Holds for the stored template, or for a
    choke-stamped product with no store since (write-epoch equal) consumed
    where every open staged region predates the stamp -- a region entered
    after it could re-execute a later-traced store before this read."""
    # An epoch-superseded value is a LAW-1 retained snapshot even when it is
    # still the cell's bound template: an un-instrumented store (a plain
    # Python callee's ``self.x += 1``) bumps the write-epoch without
    # rebinding ``mv._value``, and the identity fast-path would misread that
    # state as current and serve the post-store cell to a pre-store read.
    _ep = _get_load_epoch(value)
    if _ep is not None and mv._ref is not None and _ep != _ref_write_epoch(mv._ref):
        return False
    if value is mv._value:
        return True
    entry_tag = _get_load_region_entry(value)
    return (
        entry_tag is not None
        and entry_tag >= _pyir_region_entry_watermark()
        and _get_load_epoch(value) == _ref_write_epoch(mv._ref)
    )


def _pyir_resolve_snapshot(value: Any, var: Any) -> Any:
    """LAW-1 snapshot semantics for a routed value that is not its cell's
    current binding: the value's own SSA where usable (a literal re-materializes
    at its use site), else a loud refusal -- the capture is unrecoverable."""
    if _is_literal_backed(value) or _value_dominates_current_ip(value):
        return value
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.SNAPSHOT_UNMATERIALIZABLE,
        filename=filename,
        lineno=lineno,
        var=str(var),
    )


def _pyir_row_binding_unobserved_write(value: Any, mv: "MutableValue") -> bool:
    """V-3 COHERENT: True when the live binding at a rowed place is a DIFFERENT
    cell's choke product -- proof that a write the chokes never saw rebound the
    place.  The row's own products stay coherent (template identity, own
    route); a route-less binding names no producing cell, so it carries no
    fact that could attribute a divergence.  Load/store tag ints are
    cell-anonymous, so cell attribution comes from the co-produced route."""
    if mv._ref is None or not _is_staged_value(value):
        return False
    if value is mv._value:
        return False
    route = getattr(value, "_mutable_ref", None)
    if route is None or route is mv:
        return False
    # The template's own route is the row-recorded content channel: a fresh
    # product of it (an auto-load re-read) is the choked binding's content,
    # not evidence of a foreign write.
    return route is not getattr(mv._value, "_mutable_ref", None)


# --- Place-identity resolver + scope stack + reconstruction propagation ---
# Scope push/pop failures propagate loudly: a skipped push corrupts identity.


def _push_scope(kind: str, inherit: bool = False) -> "_ScopeFrame":
    """Push a scope frame onto :data:`_PYIR_SCOPE_STACK` and return it.

    A ``'fn'`` scope gets a fresh monotonic ``scope_id``; a ``'region'`` scope
    inherits the enclosing frame's (one place across regions; empty → fresh).
    """
    if inherit and _PYIR_SCOPE_STACK:
        scope_id = _PYIR_SCOPE_STACK[-1].scope_id
    else:
        scope_id = next(_SCOPE_ID_COUNTER)
    frame = _ScopeFrame(scope_id, kind)
    _PYIR_SCOPE_STACK.append(frame)
    return frame


def _pop_scope() -> None:
    """Pop the top scope frame (no-op on an empty stack)."""
    if _PYIR_SCOPE_STACK:
        _PYIR_SCOPE_STACK.pop()


class _PyirScopeGuard:
    """Context manager: push a scope frame on enter, pop in ``finally``.

    A ``'region'`` scope inherits the enclosing ``scope_id``; a ``'fn'``
    scope mints a fresh one.  Pop-in-finally means a region-builder exception
    cannot leak a frame.  Scope frames are load-bearing (slot keys and
    region-arm paths resolve from the stack), so errors propagate.
    """

    __slots__ = ("_kind", "_inherit")

    def __init__(self, kind: str = "region", inherit: bool = True) -> None:
        self._kind = kind
        self._inherit = inherit

    def __enter__(self) -> "_PyirScopeGuard":
        _push_scope(self._kind, inherit=self._inherit)
        return self

    def __exit__(self, *exc: Any) -> "_Literal[False]":
        _pop_scope()
        return False


def pyir_register_scope_cells(cells_probe: Any) -> None:
    """Instrumented-function entry: register the frame's closure CELLS on the
    open scope.  *cells_probe* is a generated zero-arg lambda referencing every
    cellvar; its ``__closure__`` exposes the frame's cell objects without
    evaluating any of them.  A cell is the one binding a nested closure and
    its defining frame share, so the (scope, name) -> cell-token rows are the
    exact aliasing facts between a boundary closure read and a local write."""
    if not _PYIR_SCOPE_STACK:
        return
    closure = getattr(cells_probe, "__closure__", None)
    if not closure:
        return
    names = getattr(getattr(cells_probe, "__code__", None), "co_freevars", ())
    scope_id = _PYIR_SCOPE_STACK[-1].scope_id
    nonlocal_names = _PYIR_SCOPE_NONLOCAL_NAMES.get(scope_id, ())
    for name, cell in zip(names, closure):
        tok = _owner_token(cell)
        if tok is not None:
            prev = _PYIR_SCOPE_CELL_TOKENS.get((scope_id, name), ())
            if tok not in prev:
                _PYIR_SCOPE_CELL_TOKENS[(scope_id, name)] = prev + (tok,)
            # The cell's OWNING scope registers first (its entry precedes any
            # nested def's execution); a nonlocal-declared name is a freevar,
            # so it never claims ownership of the shared cell.
            if name not in nonlocal_names and tok not in _PYIR_CELL_HOME_BINDING:
                _PYIR_CELL_HOME_BINDING[tok] = (scope_id, name)


def pyir_register_nonlocal_names(*names: str) -> None:
    """Instrumented-function entry: DECLARE the function's ``nonlocal`` names
    on the open scope (a rewrite-time syntactic fact).  A bare-name choke
    consults the innermost scope's set to recognize that the name binds a
    rebindable closure cell of an enclosing scope, not a scope-own local."""
    if not _PYIR_SCOPE_STACK or not names:
        return
    scope_id = _PYIR_SCOPE_STACK[-1].scope_id
    prev = _PYIR_SCOPE_NONLOCAL_NAMES.get(scope_id)
    fresh = frozenset(names)
    _PYIR_SCOPE_NONLOCAL_NAMES[scope_id] = fresh if prev is None else prev | fresh


def _pyir_boundary_cell_read_for_local(slot_key: Any) -> "tuple | None":
    """The boundary closure-read record aliasing a bare-local slot key, or
    ``None``.  Resolution is by CELL IDENTITY: a cell token registered for the
    local must equal the token recorded at the boundary read -- a same-named
    local backed by a different cell never matches.  Every registered cell of
    the binding (entry cell plus region-frame carry cells) is consulted."""
    if not (isinstance(slot_key, tuple) and slot_key and slot_key[0] == "local"):
        return None
    for tok in _PYIR_SCOPE_CELL_TOKENS.get((slot_key[1], slot_key[2]), ()):
        rec = _PYIR_BOUNDARY_META_CELL_READS.get(("cell", tok))
        if rec is not None:
            return rec
    return None


def _owner_token(obj: Any) -> "int | None":
    """Stable id()-independent token for slot-owner *obj*, minted on first
    sight.  The table is identity-keyed, so the lookup never routes through a
    payload dunder (IR-silent by construction) and never raises."""
    if obj is None:
        return None
    tok = _OWNER_TOKENS.get(obj)
    if tok is None:
        tok = next(_TOKEN_COUNTER)
        _OWNER_TOKENS[obj] = tok
        # F-CLASS: the owner's class is recorded at token mint; carried
        # uses validate the live class against it (V-7).
        _PYIR_TOKEN_BORN_CLASS[tok] = type(obj)
    return tok


def _pyir_wall_composite_str_slot(slot_name: Any) -> None:
    """Bracket wall: a composite STRING slot name in attr place-key space is
    impossible by construction (identifiers contain no ``[``; composite
    tuple-element keys are ``_PlaceSeg``, declared at their decomposition
    birth).  A partial migration or regression fails LOUD here instead of
    minting a silent place twin."""
    if isinstance(slot_name, str) and "[" in slot_name:
        raise DSLRuntimeError(
            f"[pyir internal] composite string slot name {slot_name!r} reached "
            "place-key space; composite tuple-element keys must be _PlaceSeg"
        )


def _place_for(
    target_name: "str | None", owner: Any = None, slot_name: Any = None
) -> Any:
    """Canonical place key rooted at the IMMEDIATE owner's token (locals on the
    scope id); :func:`_corrected_place_for` layers stable-anchor rooting on top."""
    if owner is not None and slot_name is not None:
        tok = _owner_token(owner)
        if tok is None:
            return None
        if isinstance(owner, (dict, list)):
            return ("subscript", tok, slot_name)
        _pyir_wall_composite_str_slot(slot_name)
        return ("attr", tok, slot_name)
    if target_name is not None:
        if not _PYIR_SCOPE_STACK:
            return ("local", None, target_name)
        return _ce_local_key(_PYIR_SCOPE_STACK[-1].scope_id, target_name)
    return None


def _corrected_place_for(owner: Any, slot_name: Any) -> Any:
    """Attr/subscript place resolver: recorded stable anchor + symbolic suffix,
    else immediate-owner rooting; rooting freezes at first use."""
    if owner is None or slot_name is None:
        return _place_for(None, owner, slot_name)
    pref = _OWNER_PLACE_PREFIX.get(owner)
    if pref is not None:
        root_tok, suffix = pref
        _pyir_wall_composite_str_slot(slot_name)
        return ("attr", root_tok, *suffix, slot_name)
    # First key for this owner: freeze its self-rooting so the key space stays
    # stable for the rest of the trace.
    tok = _owner_token(owner)
    if tok is not None and not isinstance(owner, (dict, list)):
        _OWNER_PLACE_PREFIX[owner] = (tok, ())
    return _place_for(None, owner, slot_name)


def _register_place_prefix(
    target_name: Any,
    owner: Any,
    slot_name: Any,
    *bound_values: Any,
    alias_from: Any = None,
) -> None:
    """Record the stable-anchor rooting for values bound at a dotted access
    (first-wins); the *alias_from* leg lets a replacement adopt the old rooting."""
    try:
        if (
            not isinstance(target_name, str)
            or "." not in target_name
            or owner is None
            or not isinstance(slot_name, (str, _PlaceSeg))
            or _is_staged_value(owner)
        ):
            # A dotted attr access with a compound (non-staged) owner only; a
            # staged owner must not be attribute/hash/weakref-probed.
            return
        segments = target_name.split(".")
        # The last dotted segment must name this slot, else a synthesized
        # ``field_key`` mismatch could mis-root the chain.
        if len(segments) < 2 or segments[-1] != str(slot_name):
            return
        prefix_segments = segments[:-1]
        # Exactness gate: the dotted split is exact only over identifier
        # segments (an identifier contains neither '.' nor '['); a spelling
        # whose subscript key carries a dot shreds into garbage segments that
        # would mint a guaranteed-unresolvable rooting.  Outside the exact
        # domain fall through to the immediate-owner self-rooting.
        if not all(s.isidentifier() for s in prefix_segments):
            return

        # Resolve the owner's (root_token, owner_suffix).
        existing = _OWNER_PLACE_PREFIX.get(owner)
        if existing is not None:
            root_tok, owner_suffix = existing
        elif len(prefix_segments) == 1:
            # The owner IS the outermost named binding: its token is the anchor;
            # the name->token row is scoped per activation.
            root_tok = _owner_token(owner)
            if root_tok is None:
                return
            owner_suffix = ()
            _root_scope = _PYIR_SCOPE_STACK[-1].scope_id if _PYIR_SCOPE_STACK else -1
            _ROOT_NAME_TOKENS[(_root_scope, prefix_segments[0])] = root_tok
            _OWNER_PLACE_PREFIX[owner] = (root_tok, ())
        else:
            # Deeper owner not yet recorded: root at the outermost named binding if
            # its token is known IN THIS SCOPE, else anchor at this owner's own token.
            _root_scope = _PYIR_SCOPE_STACK[-1].scope_id if _PYIR_SCOPE_STACK else -1
            root_tok = _ROOT_NAME_TOKENS.get((_root_scope, prefix_segments[0]))
            if root_tok is not None:
                owner_suffix = tuple(prefix_segments[1:])
            else:
                root_tok = _owner_token(owner)
                if root_tok is None:
                    return
                owner_suffix = ()

        # Place-continuity rooting for a replacement rebind (resolved once):
        # the old value's recorded rooting names where THIS PLACE's cells live
        # (first-wins may have rooted them under an earlier spelling), so a
        # structure-equal replacement adopts it -- a place fact, never an
        # owner-token adoption (that channel is the rebuild protocol, V-6).
        _place_rooting = None
        if alias_from is not None and not is_inside_constexpr_loop():
            try:
                if not _is_staged_value(alias_from) and _has_instance_storage(
                    alias_from
                ):
                    _place_rooting = _OWNER_PLACE_PREFIX.get(alias_from)
            except Exception:
                _place_rooting = None

        leaf_suffix = owner_suffix + (slot_name,)
        for bound in bound_values:
            # Register only compound container objects; a staged leaf is skipped
            # BEFORE any attribute/hash/weakref probe (probing it is not neutral).
            if (
                bound is None
                or _is_staged_value(bound)
                or not _has_instance_storage(bound)
            ):
                continue
            # First-wins over EVERY recorded rooting, the default self-rooting
            # freeze included: a rooting is recorded exactly when the first
            # place key is issued under it, so the record means live keys may
            # already name this object's leaves.  Re-rooting it mid-trace
            # would land two distinct live objects' registrations on one
            # place key, and the shared cell then serves one object's value
            # for the other's slot (a silent wrong value).  Only a bound
            # object with NO recorded rooting -- a fresh replacement whose
            # key space is provably unused -- may adopt the old rooting.
            if _OWNER_PLACE_PREFIX.get(bound) is not None:
                continue
            if (
                _place_rooting is not None
                and bound is not alias_from
                and _pyir_same_container_structure(alias_from, bound)
            ):
                # Replacement rebind: the fresh object's leaves continue
                # the place's existing cells (rooting recorded on the
                # value it replaces).
                _OWNER_PLACE_PREFIX[bound] = _place_rooting
            else:
                _OWNER_PLACE_PREFIX[bound] = (root_tok, leaf_suffix)
    except Exception:
        pass


def _pyir_same_container_structure(old_obj: Any, new_obj: Any) -> bool:
    """True iff both objects expose the same type + instance-storage field names
    (or tuple/list arity); gates owner-token propagation. Conservative: False."""
    try:
        if isinstance(old_obj, (tuple, list)) and isinstance(new_obj, (tuple, list)):
            return len(old_obj) == len(new_obj)
        if type(old_obj) is not type(new_obj):
            return False
        old_d = _instance_storage_items(old_obj)
        new_d = _instance_storage_items(new_obj)
        if old_d is None or new_d is None:
            return old_d is None and new_d is None
        old_keys = {k for k in old_d if k != _SLOT_STORE_ATTR}
        new_keys = {k for k in new_d if k != _SLOT_STORE_ATTR}
        return old_keys == new_keys
    except Exception:
        return False


def _pyir_propagate_owner_token(old_obj: Any, new_obj: Any) -> None:
    """Copy *old_obj*'s owner token onto *new_obj* (recursing into fields) so
    token-rooted places re-resolve after reconstruction; structure-gated, guarded.

    Runs only inside the rebuild-protocol frame (V-6): token adoption maps a
    ``__new_from_mlir_values__`` product onto its source's places; any other
    fresh object is a birth and must mint its own token."""
    if not _PYIR_REBUILD_PROTOCOL_DEPTH[0]:
        raise DSLRuntimeError(
            "owner-token adoption outside the rebuild protocol: a token may "
            "only transfer to an object produced by __new_from_mlir_values__ "
            "(a constructor call births a fresh token)."
        )
    try:
        # Iterative pair walk with a visited set: a cyclic object graph (or a
        # rebuilder aliasing old sub-objects) terminates instead of recursing
        # to a swallowed RecursionError with partial token propagation.
        work: "list[tuple[Any, Any]]" = [(old_obj, new_obj)]
        seen_pairs: "set[tuple[int, int]]" = set()
        while work:
            old_cur, new_cur = work.pop()
            if old_cur is None or new_cur is None or old_cur is new_cur:
                continue
            pair = (id(old_cur), id(new_cur))
            if pair in seen_pairs:
                continue
            seen_pairs.add(pair)
            # Register both objects as candidate holders so a rebuilt captured
            # object stays discoverable by the registry-driven gathers.
            _pyir_register_candidate_holder(old_cur)
            _pyir_register_candidate_holder(new_cur)
            _struct_ok = _pyir_same_container_structure(old_cur, new_cur)
            if not _struct_ok:
                continue
            tok = _OWNER_TOKENS.get(old_cur)
            if tok is not None:
                _OWNER_TOKENS[new_cur] = tok
            # Framework reconstruction is NOT a generation event: stamps
            # propagate unchanged and no generation counter is bumped.
            if _SUPERSEDED_GENERATIONS:
                _gen_rec = _SUPERSEDED_GENERATIONS.get(id(old_cur))
                if _gen_rec is not None:
                    _SUPERSEDED_GENERATIONS[id(new_cur)] = _gen_rec
                    _pyir_keepalive_generation_obj(new_cur)
            if isinstance(old_cur, (tuple, list)) and isinstance(
                new_cur, (tuple, list)
            ):
                work.extend(zip(old_cur, new_cur))
                continue
            old_d = _instance_storage_items(old_cur)
            new_d = _instance_storage_items(new_cur)
            if old_d is not None and new_d is not None:
                for k, ov in list(old_d.items()):
                    if k == _SLOT_STORE_ATTR:
                        continue
                    if k in new_d:
                        work.append((ov, new_d[k]))
    except Exception:
        pass


def _pyir_adopt_rebuilt_owner_token(src: Any, rebuilt: Any) -> None:
    """Adoption entry for the generic value-tree rebuilders: a
    ``__new_from_mlir_values__`` product adopts *src*'s token inside the
    rebuild-protocol frame (F-BIRTH, V-6)."""
    _PYIR_REBUILD_PROTOCOL_DEPTH[0] += 1
    try:
        _pyir_propagate_owner_token(src, rebuilt)
    finally:
        _PYIR_REBUILD_PROTOCOL_DEPTH[0] -= 1


def _pyir_lookup_owner_token(obj: Any) -> "int | None":
    """*obj*'s owner token WITHOUT minting, or ``None``."""
    return _OWNER_TOKENS.get(obj)


def _pyir_validate_owner_class(obj: Any) -> None:
    """V-7: a tokenized owner's live class must equal the class recorded at its
    token mint -- place keys and class facts resolved under a reclassed owner
    name the wrong namespace. A never-tokenized owner is untouched."""
    if obj is None or isinstance(obj, (tuple, list, dict)):
        return
    tok = _pyir_lookup_owner_token(obj)
    if tok is None:
        return
    born = _PYIR_TOKEN_BORN_CLASS.get(tok)
    if born is None or type(obj) is born:
        return
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.OWNER_CLASS_CHANGED,
        filename=filename,
        lineno=lineno,
        old_class=born.__name__,
        new_class=type(obj).__name__,
    )


def _pyir_owner_is_celled(obj: Any) -> bool:
    """True when a live cell is booked under a place rooted at *obj*'s recorded
    rooting: the owner carries staged state (not an effect-only object)."""
    pref = _OWNER_PLACE_PREFIX.get(obj)
    if pref is None:
        tok = _pyir_lookup_owner_token(obj)
        if tok is None:
            return False
        pref = (tok, ())
    root_tok, suffix = pref
    n = len(suffix)
    for key in _slot_refs:
        if (
            isinstance(key, tuple)
            and len(key) >= 2 + n
            and key[0] in ("attr", "subscript")
            and key[1] == root_tok
            and tuple(key[2 : 2 + n]) == tuple(suffix)
        ):
            return True
    return False


def _pyir_emission_self_check(
    op: str,
    owner: Any,
    slot_name: Any,
    live_mv: "MutableValue | None",
    place: Any,
    place_mv: "MutableValue | None",
) -> None:
    """Raise when a staged slot access resolves a live cell different from the
    place's registered live cell of the same MLIR type (a split place)."""
    if live_mv is None or place_mv is None or live_mv is place_mv:
        return
    try:
        live_ref = live_mv._ref
        place_ref = place_mv._ref
        if live_ref is None or place_ref is None:
            return
        if not (live_mv._is_ref_accessible() and place_mv._is_ref_accessible()):
            return
        if live_ref.type != place_ref.type:
            return
    except Exception:
        # Structural reads only: an unreadable cell cannot be classified as
        # live, so it is not a violation.
        return
    if len(_EMISSION_SELF_CHECK_LOG) < _EMISSION_SELF_CHECK_LOG_CAP:
        _EMISSION_SELF_CHECK_LOG.append(
            {
                "op": op,
                "owner_type": type(owner).__name__,
                "owner_id": id(owner),
                "slot": slot_name,
                "place": place,
            }
        )
    raise DSLRuntimeError(
        "PyIR emission self-check: one-cell-per-place violation on "
        f"{op} of slot {slot_name!r} (owner type {type(owner).__name__!r}, "
        f"place key {place!r}): the access resolves a live cell different "
        "from the place's registered cell. Two live cells of the same type "
        "exist for one logical place, so stores and reads of this slot can "
        "split across cells."
    )


def _pyir_guard_stale_epoch(value: Any) -> None:
    """Refuse an SSA-backed wrapper born in a previous, already-finalized
    compilation context, before its backing ``ir.Value`` is dereferenced."""
    birth = getattr(value, "_pyir_birth_ctx", None)
    if birth is None:
        return
    try:
        current = id(ir.Context.current)
    except Exception:
        return
    if birth != current:
        from .common import DSLRuntimeError

        raise DSLRuntimeError(
            "this value was produced by a previous @jit compilation and "
            "cannot be reused here: its backing IR lives in an "
            "already-finalized compilation context. Pass it through the "
            "kernel's arguments or recompute it in this compilation."
        )


def _pyir_witness_predicate_fold(pred: Any) -> None:
    """Witness an ``if`` predicate folded on trace-time data: recording its
    source places/values makes a later staged write of any of them refuse loudly."""
    try:
        if isinstance(pred, _WatchedM):
            pred._record_structural_consumption()
            return
        _pyir_record_staged_literal_fold(pred)
    except DSLUserCodeError:
        raise  # curated refusals are the loud floor, never swallowed
    except Exception:
        pass


def _pyir_record_staged_literal_fold(pred: Any) -> None:
    """Record a literal-backed STAGED predicate fold inside an enclosing loop:
    the decision is fixed at trace time, so a later staged write of any recorded
    source must raise instead of silently keeping it (per-iteration hazard)."""
    from .typing import Numeric

    if not isinstance(pred, Numeric) or type(getattr(pred, "value", None)) not in (
        bool,
        int,
        float,
    ):
        return
    # Loop multiplicity is the hazard; a loop-free fold matches Python exactly.
    if not is_inside_staged_cf() or _innermost_enclosing_loop_op_at_ip() is None:
        return
    filename, lineno = _first_non_dsl_caller_location()
    for src in getattr(pred, "_pyir_fold_srcs", ()) or (pred,):
        if not isinstance(src, Numeric) or type(getattr(src, "value", None)) not in (
            bool,
            int,
            float,
        ):
            continue
        if id(src) in _PYIR_STAGED_LITERAL_FOLD_WITNESSES:
            continue
        _PYIR_STAGED_LITERAL_FOLD_WITNESSES[id(src)] = (
            repr(src.value),
            filename or "<predicate fold>",
            lineno or 0,
        )
        # Pin the object so a recycled address can never alias the record.
        _PYIR_STAGED_LITERAL_FOLD_KEEPALIVE.append(src)


def _pyir_check_staged_fold_witness(value: Any, target_name: Any) -> None:
    """Refuse a staged write reaching a value whose trace-time payload already
    decided an if/while predicate inside an enclosing loop -- the folded branch
    would keep the stale decision silently on every iteration."""
    if not _PYIR_STAGED_LITERAL_FOLD_WITNESSES:
        return
    rec = _PYIR_STAGED_LITERAL_FOLD_WITNESSES.get(id(value))
    if rec is None:
        return
    payload, read_file, read_line = rec
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.PHASE_PREDICATE_FOLDED_STALE,
        filename=filename,
        lineno=lineno,
        var=str(target_name),
        value=payload,
        read_file=read_file,
        read_line=read_line,
    )


def _pyir_module_is_tracer_layer(mod: str) -> bool:
    """True when *mod* is the tracer layer's own package (this module's parent,
    e.g. ``cutlass.base_dsl``): its bookkeeping reads of trace-time payloads
    are not consumption events.  The DSL's SEMANTIC funnels (``not_``,
    ``equal``, ``and_`` in the dialect layers above) consume payloads as
    structure exactly like user code and are NOT exempt."""
    base_pkg = __name__.rsplit(".", 1)[0]
    return mod == base_pkg or mod.startswith(base_pkg + ".")


def _pyir_record_external_payload_consumption(wrapper: Any, depth: int = 2) -> None:
    """Witness a trace-time payload consumed as structure OUTSIDE the tracer
    layer (a coercion dunder, comparison fold, or the payload accessor); only
    the tracer's own bookkeeping reads are not consumption events.  *depth*
    is the consumer's frame distance: 2 for a directly-invoked dunder, 3 when
    routed through one intermediate helper (the comparison funnel)."""
    try:
        if not _PYIR_SCOPE_STACK or not is_inside_staged_cf():
            return
        # The consumer is the frame that invoked the dunder/accessor (C-level
        # callees such as ``bool()``/``min()`` are frame-transparent).
        mod = sys._getframe(depth).f_globals.get("__name__", "")
        if _pyir_module_is_tracer_layer(mod):
            return
        if isinstance(wrapper, _WatchedM):
            wrapper._record_structural_consumption()
        else:
            _pyir_record_staged_literal_fold(wrapper)
    except DSLUserCodeError:
        raise  # curated refusals are the loud floor, never swallowed
    except Exception:
        pass  # witnessing must never break the consumption itself


# Trace-scoped witness: how many times a STAGED payload was consumed through
# ``__hash__`` during the active trace.  Recording never refuses; the dict-key
# write choke snapshots/compares this count around hashing THE KEY, so only a
# keyed write whose own hash consumed staged identity refuses -- hashing
# anywhere else (logging, memo tables) stays untouched.
_PYIR_STAGED_HASH_WITNESS = [0]


def _pyir_record_staged_identity_hashed() -> None:
    """Witness a staged payload answering ``__hash__``: the resulting Python
    hash launders runtime identity into a trace-time value, so the container
    key wall must be able to see the consumption."""
    if _PYIR_SCOPE_STACK:
        _PYIR_STAGED_HASH_WITNESS[0] += 1


def _pyir_staged_hash_witness_count() -> int:
    """The staged-hash witness count for snapshot/compare correlation."""
    return _PYIR_STAGED_HASH_WITNESS[0]


def _emit_constant_at_current_ip(value: Any) -> "ir.Value":
    """Emit a FRESH ``arith.constant`` (bypassing the memoised helper): slots
    sharing one cached SSA would clobber each other on per-slot RAUW."""
    from .._mlir.dialects import arith as _arith
    from .._mlir import ir as _ir

    if isinstance(value, bool):
        mlir_ty = _ir.IntegerType.get_signless(1)
        return _arith.constant(mlir_ty, value)
    if isinstance(value, int):
        # A traced plain-int leaf materialises at the narrowest declared staged
        # width that preserves its value (i32, widening to i64); anything wider
        # than a signed i64 has no value-preserving width, so reject it loudly.
        if -(2**31) <= value < 2**31:
            return _arith.constant(_ir.IntegerType.get_signless(32), value)
        if -(2**63) <= value < 2**63:
            return _arith.constant(_ir.IntegerType.get_signless(64), value)
        raise DSLRuntimeError(
            f"PyIR: integer literal {value} read inside staged control flow "
            "does not fit any declared staged integer width (i32/i64) without "
            "changing its value; keep the constant within signed 64 bits or "
            "restructure it as an explicit DSL integer value."
        )
    if isinstance(value, float):
        mlir_ty = _ir.F32Type.get()
        return _arith.constant(mlir_ty, value)
    # Fallback (rare): defer to the cached helper.
    from .._mlir_helpers.arith import const as _arith_const

    return _arith_const(value)


def _emit_constant_for_ref(ref: "ir.Value", value: Any) -> "ir.Value":
    """Emit a constant of *value* typed to match *ref*'s pointee (a store must
    verify against it); falls back to the Python-default emit when unavailable."""
    from .._mlir.dialects import arith as _arith
    from .._mlir import ir as _ir

    try:
        pointee = ref.type.pointee
    except Exception:
        return _emit_constant_at_current_ip(value)
    try:
        if _ir.IntegerType.isinstance(pointee):
            width = _ir.IntegerType(pointee).width
            coerced = bool(value) if width == 1 else int(value)
            return _arith.constant(pointee, coerced)
        # Float pointee (f16/bf16/f32/f64/...): a float attr of the exact type.
        return _arith.constant(pointee, float(value))
    except Exception:
        return _emit_constant_at_current_ip(value)


def _const_value_of(ir_value: "ir.Value") -> Any:
    """Return the exact-typed Python value baked into an ``arith.constant``
    (implemented in C++), or ``_NO_CONST_VALUE`` when not a scalar constant."""
    try:
        if pyir is None:
            return _NO_CONST_VALUE
        result = pyir.literal_const_of_value(ir_value)
    except Exception:
        return _NO_CONST_VALUE
    return _NO_CONST_VALUE if result is None else result


def _const_values_equal(a: Any, b: Any) -> bool:
    """Numeric equality that does not conflate ``bool`` with ``int`` (a baked
    ``i1`` and a baked ``i32`` are distinct slot values)."""
    if isinstance(a, bool) != isinstance(b, bool):
        return False
    try:
        return a == b
    except Exception:
        return False


def _unwrap(value: Any) -> Any:
    """Strip a ``_WatchedM`` wrapper (one level), or return *value* as-is."""
    if isinstance(value, _WatchedM):
        return value._pyir_raw_payload
    return value


def _pyir_structural_value_conflicts(
    record: "tuple[str, str, int]", value: Any
) -> bool:
    """True when writing *value* does not provably re-establish the recorded
    structural consumption *record* (declared value-equality: the plain or
    watched payload, or a literal-backed staged wrapper's own literal)."""
    payload = _unwrap(value)
    if isinstance(payload, (bool, int, float)):
        return str(payload) != record[0]
    literal = getattr(value, "value", None)
    if isinstance(literal, (bool, int, float)):
        return str(literal) != record[0]
    # No provable payload (an SSA-backed staged value): the write may diverge.
    return True


def _pyir_structural_bake_is_reseeded(slot_key: Any) -> bool:
    """True when *slot_key*'s binding is re-run inside the loop body that
    witnessed its structural consumption, so every iteration reaches the fold
    with the value it was baked on and a later staged write cannot leave stale
    structure behind::

        while ...:
            cond = False        # binding: re-runs every iteration
            if not cond:        # fold: always reached with False -> admitted
                cond = <staged> # killed before the fold is reached again

    False for everything else, which just leaves the caller's existing refusal
    in place; it makes no claim about how those places are handled.

    Compares the BINDING against the CONSUMPTION, never against the write that
    triggers this query: however deeply the write nests, the next iteration's
    binding kills it before the fold is reached again. Testing the WRITE's
    staged-CF depth instead agrees on the sketch above but rejects the SM100
    FMHA guard chains, which write from inside a staged ``if`` while their fold
    stays at body level.
    """
    site = _PYIR_STRUCTURAL_META_CONSUMPTION_SITES.get(slot_key)
    if site is None:
        return False
    sc_block, sc_loop_op = site
    if sc_block is None or sc_loop_op is None:
        return False
    # The binding must be born inside control flow (a per-iteration re-run), not
    # hoisted above the loop where its value would carry.
    if not _slot_first_def_inside_cf.get(slot_key, False):
        return False
    def_block = _slot_first_def_block.get(slot_key)
    if def_block is None:
        return False
    # ``is`` is unreliable: the MLIR Python bindings hand out a fresh wrapper per
    # access, so two handles on the same block are distinct objects.
    if def_block == sc_block:
        return True
    try:
        if not _block_strictly_inside(sc_block, def_block):
            return False
    except Exception:
        return False
    # The binding must belong to the loop that witnessed the fold. A binding in
    # an OUTER loop body re-runs only once per outer iteration, so an inner
    # loop's fold still meets the value its own previous iteration wrote --
    # block ancestry alone would admit that.
    return _block_inside_op(def_block, sc_loop_op)


def _pyir_merge_src_pairs(*operands: Any) -> "tuple[tuple[Any, Any], ...]":
    """Union of the watched *operands*' (source place, payload) pairs, first
    occurrence of a place wins (the payload its first consumption saw)."""
    pairs: "list[tuple[Any, Any]]" = []
    for o in operands:
        if isinstance(o, _WatchedM):
            for sk, payload in o._pyir_src_pairs():
                if all(sk != have for have, _ in pairs):
                    pairs.append((sk, payload))
    return tuple(pairs)


class _WatchedM:
    """Wrap a Python primitive read inside staged CF, recording its slot so a later
    mutation rewrites baked constants to loads; subclasses int/float for transparency."""

    # Declared on the base class for type-checkers; the concrete subclass __new__
    # populates each instance.
    _slot_key: Any
    # (source place, its payload at derivation) pairs propagated through meta
    # arithmetic / comparisons (set on derived wrappers only; absent means none).
    _pred_src_pairs: "tuple[tuple[Any, Any], ...]"
    _cached_ir: Optional["ir.Value"]

    def __new__(cls, value: Any = 0, slot_key: Any = None) -> "_WatchedM":
        # Factory dispatch: _WatchedM(...) forwards to the right int/float-backed
        # subclass; subclass __new__ paths (cls is not _WatchedM) bypass this.
        if cls is _WatchedM:
            # Bool first (``isinstance(True, int)`` is True): route via ``_WatchedBool`` so
            # ``python_value`` is True/False and ``arith.const`` emits ``i1``, not ``i32``.
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

    def _pyir_record_birth_facts(self, slot_key: Any) -> None:
        """Birth fact: the slot's cell (and write epoch) as of creation -- the
        read position this wrapper snapshots (C5 one-semantics anchor)."""
        ref = _slot_refs.get(slot_key) if slot_key is not None else None
        self._pyir_birth_ref = ref
        self._pyir_birth_epoch = _ref_write_epoch(ref) if ref is not None else None

    @property
    def python_value(self) -> Any:
        """Declared payload accessor: a read from outside the DSL package is a
        recorded structural consumption; subclasses supply the raw payload."""
        _pyir_record_external_payload_consumption(self)
        return self._pyir_raw_payload

    @property
    def _pyir_raw_payload(self) -> Any:
        """The bare payload for the tracer's own bookkeeping (never recorded);
        subclasses cast to their int/float base."""
        return self

    def ir_value(
        self,
        *,
        loc: "ir.Location | None" = None,
        ip: "ir.InsertionPoint | None" = None,
    ) -> "ir.Value":
        """Emit (or reuse, if it still dominates the current IP) the leaf constant
        and record it in ``_meta_uses[slot]``; ``loc``/``ip`` accepted and ignored."""
        # An arm-locally mutated slot baked outside its arm would freeze one
        # traced path's value for both runtime paths -- refuse loudly.
        if self._slot_key is not None:
            _pyir_check_arm_local_escape(self._slot_key)
        cached = self._cached_ir
        if cached is not None:
            # Follow the promotion rewrite: new consumers must use the RAUW'd
            # position-correct load, not the dead constant.
            _replacement = _META_CONST_REPLACEMENTS.get(cached)
            if _replacement is not None:
                cached = _replacement
                self._cached_ir = cached
        if cached is not None and _cached_ir_value_dominates_current_ip(cached):
            return cached
        # An already-promoted slot materialises as a load of its cell -- but
        # only while the cell still holds this wrapper's creation-time value
        # (same ref, same write epoch): one declared SNAPSHOT semantics.
        if self._slot_key is not None:
            _ref = _slot_refs.get(self._slot_key)
            if isinstance(_ref, ir.Value) and _cached_ir_value_dominates_current_ip(
                _ref
            ):
                if _ref is getattr(self, "_pyir_birth_ref", None) and _ref_write_epoch(
                    _ref
                ) == getattr(self, "_pyir_birth_epoch", None):
                    loaded = pyir.load(_ref)
                    self._cached_ir = loaded
                    return loaded
                # The cell moved past this wrapper's snapshot.  A flat region
                # runs once, so the payload constant IS the creation-time
                # value; inside a loop the carry engine's store-back walk
                # re-presents slots through this arm, so the cell load stays
                # (the user-facing loop-snapshot residue is a recorded
                # deviation, not a refusal).
                if _innermost_enclosing_loop_op_at_ip() is None:
                    const = _emit_constant_at_current_ip(self._pyir_raw_payload)
                    self._cached_ir = const
                    # F-SPEC: a baked constant of a rooted place is a
                    # specialization fact of this trace.
                    _pyir_spec_record_read(self._slot_key, self._pyir_raw_payload)
                    return const
                loaded = pyir.load(_ref)
                self._cached_ir = loaded
                return loaded
        const = _emit_constant_at_current_ip(self._pyir_raw_payload)
        self._cached_ir = const
        if self._slot_key is not None:
            _meta_uses.setdefault(self._slot_key, []).append(const)
        # F-SPEC: a baked constant of a rooted place is a specialization fact.
        _pyir_spec_record_read(self._slot_key, self._pyir_raw_payload)
        return const

    def _record_structural_consumption(self) -> None:
        """Witness one structural (``__index__``) consumption inside staged CF: such
        a bake has no retargetable SSA constant, so a later promotion refuses loudly."""
        try:
            pairs = self._pyir_src_pairs()
            if not pairs or not is_inside_staged_cf():
                return
            # Loop multiplicity is the hazard (per-trace bake vs per-iteration
            # re-evaluation); outside any enclosing loop record nothing.
            _sc_loop_op = _innermost_enclosing_loop_op_at_ip()
            if _sc_loop_op is None:
                return
            try:
                _sc_block = ir.InsertionPoint.current.block
            except Exception:
                _sc_block = None
            filename, lineno = _first_non_dsl_caller_location()
            for sk, payload in pairs:
                # An arm-locally mutated slot consumed outside its arm is
                # path-dependent -- refuse before witnessing the bake.
                _pyir_check_arm_local_escape(sk)
                # F-SPEC: a structural bake of a rooted place is a
                # specialization fact of this trace (the PLACE's own payload).
                _pyir_spec_record_read(sk, payload)
                if sk in _PYIR_STRUCTURAL_META_CONSUMPTIONS:
                    continue
                _PYIR_STRUCTURAL_META_CONSUMPTIONS[sk] = (
                    str(payload),
                    filename or "<structural consumption>",
                    lineno or 0,
                )
                _PYIR_STRUCTURAL_META_CONSUMPTION_SITES[sk] = (_sc_block, _sc_loop_op)
        except DSLUserCodeError:
            raise  # curated refusals are the loud floor, never swallowed
        except Exception:
            pass  # witnessing must never break the consumption itself

    def _pyir_src_pairs(self) -> "tuple[tuple[Any, Any], ...]":
        """(place key, that place's payload) pairs this value's Python value
        derives from: its own slot at its own payload, plus propagated sources
        each at the payload it held when the derivation consumed it."""
        pairs: "list[tuple[Any, Any]]" = []
        if self._slot_key is not None:
            pairs.append((self._slot_key, self._pyir_raw_payload))
        for sk, payload in getattr(self, "_pred_src_pairs", ()):  # derived
            if sk is not None and all(sk != have for have, _ in pairs):
                pairs.append((sk, payload))
        return tuple(pairs)

    # Coercion record arms: the closed dunder set through which non-DSL code
    # consumes the payload as structure (each records, then coerces).
    def __bool__(self) -> bool:
        _pyir_record_external_payload_consumption(self)
        return bool(self._pyir_raw_payload)

    def __int__(self) -> int:
        _pyir_record_external_payload_consumption(self)
        return int(self._pyir_raw_payload)

    def __float__(self) -> float:
        _pyir_record_external_payload_consumption(self)
        return float(self._pyir_raw_payload)

    def __hash__(self) -> int:
        _pyir_record_external_payload_consumption(self)
        return hash(self._pyir_raw_payload)

    def __str__(self) -> str:
        _pyir_record_external_payload_consumption(self)
        return str(self._pyir_raw_payload)

    def __format__(self, format_spec: str) -> str:
        _pyir_record_external_payload_consumption(self)
        return format(self._pyir_raw_payload, format_spec)

    def __reduce__(self) -> Any:
        # Snapshot semantics (same contract as the watched containers):
        # serialization de-watches to the PLAIN payload -- a recorded
        # structural consumption, never a pickled tracer wrapper.
        _pyir_record_external_payload_consumption(self)
        payload = self._pyir_raw_payload
        return (type(payload), (payload,))

    def _pyir_cmp_watched(self, other: Any, op: str) -> Any:
        """Comparison on the Python values, returning a place-attributed
        ``_WatchedBool``; equality routes here like the orderings (structural
        refusals stay value-conflict-gated downstream)."""
        other_py = _unwrap(other)
        if type(other_py) not in (bool, int, float):
            return NotImplemented
        import operator as _op

        result = getattr(_op, op)(self._pyir_raw_payload, other_py)
        # A comparison folds the payloads (no eager-IR form): witness the
        # structural bake through the consumption funnel (depth 3 = the
        # frame that invoked the comparison dunder), so a later carry or
        # promotion of a source place with a changed value refuses instead
        # of keeping the folded truth.  Only the tracer layer's own
        # bookkeeping comparisons are exempt; the DSL's semantic funnels
        # (``equal``, ``not_``, ``and_``, ...) consume the payload as
        # structure exactly like user code does.
        _pyir_record_external_payload_consumption(self, depth=3)
        if isinstance(other, _WatchedM):
            _pyir_record_external_payload_consumption(other, depth=3)
        wrapped = _WatchedM(bool(result), None)
        wrapped._pred_src_pairs = _pyir_merge_src_pairs(self, other)
        return wrapped

    def __lt__(self, other: Any) -> Any:
        return self._pyir_cmp_watched(other, "lt")

    def __le__(self, other: Any) -> Any:
        return self._pyir_cmp_watched(other, "le")

    def __gt__(self, other: Any) -> Any:
        return self._pyir_cmp_watched(other, "gt")

    def __ge__(self, other: Any) -> Any:
        return self._pyir_cmp_watched(other, "ge")

    def __eq__(self, other: Any) -> Any:
        return self._pyir_cmp_watched(other, "eq")

    def __ne__(self, other: Any) -> Any:
        return self._pyir_cmp_watched(other, "ne")

    # ``__repr__`` and the remaining int/float dunders are inherited from the
    # int/float base class on the concrete subclass.

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
            "truediv": lambda a, b: a / b,
            "floordiv": lambda a, b: a // b,
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
            result_py = py_ops[op_name](self._pyir_raw_payload, rhs_py)
        except ZeroDivisionError:
            raise  # Python truth: the operation itself raises at trace time.
        except Exception:
            return NotImplemented

        try:
            from .._mlir_helpers.arith import const as _arith_const

            lhs_ir = self.ir_value()
            # SSA == payload (Python semantics): i1 operands widen to i32
            # before arithmetic (Python bool arithmetic is int arithmetic);
            # bitwise ops on two bools stay i1 (Python returns bool).
            _widen = (
                isinstance(lhs_ir.type, ir.IntegerType)
                and lhs_ir.type.width == 1
                and not (op_name in ("and", "or", "xor") and isinstance(rhs_py, bool))
            )
            if _widen:
                lhs_ir = _arith.extui(ir.IntegerType.get_signless(32), lhs_ir)
            if op_name == "truediv" and isinstance(lhs_ir.type, ir.IntegerType):
                # Python ``/`` always yields a float: run in the f32 domain.
                lhs_ir = _arith.sitofp(ir.F32Type.get(), lhs_ir)
            if isinstance(other, _WatchedM):
                rhs_ir = other.ir_value()
                if (
                    isinstance(rhs_ir.type, ir.IntegerType)
                    and rhs_ir.type.width == 1
                    and isinstance(lhs_ir.type, ir.IntegerType)
                    and lhs_ir.type.width != 1
                ):
                    rhs_ir = _arith.extui(lhs_ir.type, rhs_ir)
            else:
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
                ("and", False): _arith.andi,
                ("or", False): _arith.ori,
                ("xor", False): _arith.xori,
                ("lshift", False): _arith.shli,
                ("rshift", False): _arith.shrsi,
            }
            if op_name == "truediv":
                # The lhs is already float (widened above for int payloads);
                # widen an integer rhs the same way (unsigned for i1).
                if isinstance(rhs_ir.type, ir.IntegerType):
                    if rhs_ir.type.width == 1:
                        rhs_ir = _arith.extui(ir.IntegerType.get_signless(32), rhs_ir)
                    rhs_ir = _arith.sitofp(lhs_ir.type, rhs_ir)
                result_ir = _arith.divf(lhs_ir, rhs_ir)
            elif op_name == "floordiv" and is_float:
                # Python float floordiv FLOORS; arith.divf alone does not.
                from .._mlir.dialects import math as _math

                result_ir = _math.floor(_arith.divf(lhs_ir, rhs_ir))
            elif op_name == "mod" and not is_float:
                # Python % takes the DIVISOR's sign; arith.remsi the dividend's.
                # r = remsi(a,b); fix = (r != 0) && (sign(r) != sign(b)) -> r+b.
                _r = _arith.remsi(lhs_ir, rhs_ir)
                _zero = _arith_const(0, _r.type)
                _r_neg = _arith.cmpi(_arith.CmpIPredicate.slt, _r, _zero)
                _b_neg = _arith.cmpi(_arith.CmpIPredicate.slt, rhs_ir, _zero)
                _sign_diff = _arith.xori(_r_neg, _b_neg)
                _r_nonzero = _arith.cmpi(_arith.CmpIPredicate.ne, _r, _zero)
                _fix = _arith.andi(_sign_diff, _r_nonzero)
                result_ir = _arith.select(_fix, _arith.addi(_r, rhs_ir), _r)
            elif op_name == "mod" and is_float:
                # Python fmod takes the divisor's sign: r = remf; fix as above.
                _r = _arith.remf(lhs_ir, rhs_ir)
                _zero = _arith_const(0.0, _r.type)
                _r_neg = _arith.cmpf(_arith.CmpFPredicate.OLT, _r, _zero)
                _b_neg = _arith.cmpf(_arith.CmpFPredicate.OLT, rhs_ir, _zero)
                _sign_diff = _arith.xori(_r_neg, _b_neg)
                _r_nonzero = _arith.cmpf(_arith.CmpFPredicate.ONE, _r, _zero)
                _fix = _arith.andi(_sign_diff, _r_nonzero)
                result_ir = _arith.select(_fix, _arith.addf(_r, rhs_ir), _r)
            else:
                fn = arith_fn_table.get((op_name, is_float))
                if fn is None:
                    return NotImplemented
                result_ir = fn(lhs_ir, rhs_ir)
        except Exception:
            return NotImplemented

        derived = _WatchedM(result_py, slot_key=None)
        derived._cached_ir = result_ir
        # Source-place propagation: a structural consumption of the derived
        # value bakes the operands' places at their consumed payloads.
        pairs = _pyir_merge_src_pairs(self, other)
        if pairs:
            derived._pred_src_pairs = pairs
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

    def __truediv__(self, other: Any) -> Any:
        return self._binop_ir(other, "truediv")

    def __rtruediv__(self, other: Any) -> Any:
        if not isinstance(_unwrap(other), (bool, int, float)):
            return NotImplemented
        return _WatchedM(_unwrap(other)).__truediv__(self)

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

    def __divmod__(self, other: Any) -> Any:
        # LangRef 3.3.8: divmod == (floordiv, mod).  Route both halves through
        # the IR-emitting arm so the pair follows a later promotion of the place.
        q = self._binop_ir(other, "floordiv")
        r = self._binop_ir(other, "mod") if q is not NotImplemented else q
        if q is NotImplemented or r is NotImplemented:
            rhs = _unwrap(other)
            if not isinstance(rhs, (bool, int, float)):
                return NotImplemented
            # Payload-domain fallback (no IR context / zero divisor): witness
            # the structural consumption, then let Python decide.
            self._record_structural_consumption()
            if isinstance(other, _WatchedM):
                other._record_structural_consumption()
            return divmod(self._pyir_raw_payload, rhs)
        return (q, r)

    def __rdivmod__(self, other: Any) -> Any:
        lhs = _unwrap(other)
        if not isinstance(lhs, (bool, int, float)):
            return NotImplemented
        return _WatchedM(lhs).__divmod__(self)

    def __pow__(self, other: Any, mod: Any = None) -> Any:
        """Witness arm (LangRef 3.3.8): pow has no eager-IR form, so compute
        the Python truth, record the structural bake, propagate source places."""
        rhs = _unwrap(other)
        if not isinstance(rhs, (bool, int, float)):
            return NotImplemented
        if mod is not None and not isinstance(_unwrap(mod), (bool, int, float)):
            return NotImplemented
        for o in (self, other, mod):
            if isinstance(o, _WatchedM):
                o._record_structural_consumption()
        if mod is None:
            result = pow(self._pyir_raw_payload, rhs)
        else:
            result = pow(self._pyir_raw_payload, rhs, _unwrap(mod))
        if not isinstance(result, (bool, int, float)):
            return result  # complex etc.: the payload leaves the numeric domain
        wrapped = _WatchedM(result, None)
        pairs = _pyir_merge_src_pairs(self, other, mod)
        if pairs:
            wrapped._pred_src_pairs = pairs
        return wrapped

    def __rpow__(self, other: Any, mod: Any = None) -> Any:
        lhs = _unwrap(other)
        if not isinstance(lhs, (bool, int, float)):
            return NotImplemented
        return _WatchedM(lhs).__pow__(self, mod)

    def __complex__(self) -> complex:
        _pyir_record_external_payload_consumption(self)
        return complex(self._pyir_raw_payload)

    # ----- unary operators: emit IR eagerly, return derived wrappers -------

    def _unary_ir(self, op_name: str) -> Any:
        """Python-truth unary fold plus the eager arith form; a failed emission
        (no MLIR context) keeps the payload-only derived wrapper."""
        _py_unary = {
            "neg": lambda a: -a,
            "pos": lambda a: +a,
            "invert": lambda a: ~a,
            "abs": abs,
        }
        # Python truth decides validity (e.g. ``~`` on a float raises here).
        result_py = _py_unary[op_name](self._pyir_raw_payload)
        result_ir = None
        try:
            from .._mlir.dialects import arith as _arith
            from .._mlir_helpers.arith import const as _arith_const

            v = self.ir_value()
            if isinstance(v.type, ir.IntegerType) and v.type.width == 1:
                # Python unary arithmetic on bool runs in the int domain.
                v = _arith.extui(ir.IntegerType.get_signless(32), v)
            is_float = isinstance(v.type, ir.FloatType)
            if op_name == "pos":
                result_ir = v
            elif op_name == "neg":
                zero = _arith_const(0.0 if is_float else 0, v.type)
                result_ir = _arith.subf(zero, v) if is_float else _arith.subi(zero, v)
            elif op_name == "invert":
                result_ir = _arith.xori(v, _arith_const(-1, v.type))
            elif is_float:  # abs
                from .._mlir.dialects import math as _math

                result_ir = _math.absf(v)
            else:  # abs, integer domain
                zero = _arith_const(0, v.type)
                neg = _arith.subi(zero, v)
                isneg = _arith.cmpi(_arith.CmpIPredicate.slt, v, zero)
                result_ir = _arith.select(isneg, neg, v)
        except Exception:
            result_ir = None  # payload-only wrapper: value-exact, no eager IR
        derived = _WatchedM(result_py, None)
        if result_ir is not None:
            derived._cached_ir = result_ir
        pairs = _pyir_merge_src_pairs(self)
        if pairs:
            derived._pred_src_pairs = pairs
        return derived

    def __neg__(self) -> Any:
        return self._unary_ir("neg")

    def __pos__(self) -> Any:
        return self._unary_ir("pos")

    def __abs__(self) -> Any:
        return self._unary_ir("abs")

    def __invert__(self) -> Any:
        return self._unary_ir("invert")


class _WatchedInt(_WatchedM, int):
    """Concrete D1 wrapper backed by ``int`` (no ``__slots__``: CPython forbids
    them on int subclasses; the ``__dict__`` cost buys isinstance transparency)."""

    def __new__(cls, value: Any, slot_key: Any = None) -> "_WatchedInt":
        inst = int.__new__(cls, value)
        inst._slot_key = slot_key
        inst._cached_ir = None
        inst._pyir_record_birth_facts(slot_key)
        return inst

    @property
    def _pyir_raw_payload(self) -> int:
        # Base-slot extraction: int(self) would re-enter the recorded __int__.
        return int.__int__(self)

    def __index__(self) -> int:
        # Witness the structural bake so a later promotion of the place
        # refuses instead of leaving it silently stale.
        self._record_structural_consumption()
        return int.__int__(self)


class _WatchedBool(_WatchedM, int):
    """Concrete D1 wrapper for ``bool`` (final in CPython, so backed by ``int``
    with ``python_value`` returning a proper ``bool`` for ``i1`` emission)."""

    def __new__(cls, value: Any, slot_key: Any = None) -> "_WatchedBool":
        inst = int.__new__(cls, int(value))
        inst._slot_key = slot_key
        inst._cached_ir = None
        inst._pyir_record_birth_facts(slot_key)
        return inst

    @property
    def _pyir_raw_payload(self) -> bool:
        # Base-slot extraction: int(self) would re-enter the recorded __int__.
        return bool(int.__int__(self))

    def __index__(self) -> int:
        # See ``_WatchedInt.__index__`` -- same structural-bake witness.
        self._record_structural_consumption()
        return int.__int__(self)


class _WatchedFloat(_WatchedM, float):
    """Concrete D1 wrapper backed by ``float``.  Same ``__slots__`` rule
    as :class:`_WatchedInt`."""

    def __new__(cls, value: Any, slot_key: Any = None) -> "_WatchedFloat":
        inst = float.__new__(cls, value)
        inst._slot_key = slot_key
        inst._cached_ir = None
        inst._pyir_record_birth_facts(slot_key)
        return inst

    @property
    def _pyir_raw_payload(self) -> float:
        # Base-slot extraction: float(self) would re-enter the recorded __float__.
        return float.__float__(self)


# --- Watched dict: the OBJECT-level choke for dict-entry places ---


# Keys CREATED through the watched write choke inside dynamic staged CF
# (first-def subscript insertion stays supported: the cell is minted and item
# reads refuse staleness). The key SET, however, changed on the one traced
# pass only -- a later whole-key-set consumption (membership, lookup miss)
# would bake that pass's truth regardless of the runtime branch, so it
# refuses through this record. id -> (container, created keys); trace-scoped.
_PYIR_DICT_CF_CREATED_KEYS: "dict[int, tuple[Any, set]]" = {}


class _WatchedDict(dict):
    """Identity-adopted tracked ``dict``: entry accesses from ANY Python code route
    through one owner-keyed choke; inert without an open PyIR trace scope."""

    # Slot attribute types (assigned post-construction at the adoption /
    # write chokes, so declared here for the type checker).
    _pyir_label: str
    _pyir_staged_writes: bool
    # The instance whose attribute storage this mapping IS (weakref, or the
    # instance itself when non-weakrefable); set at the __dict__ adoption.
    _pyir_instance_of: Any

    __slots__ = ("_pyir_label", "_pyir_staged_writes", "_pyir_instance_of")

    def _pyir_engaged(self) -> bool:
        """Whether the object-side chokes fire for this access (see class doc)."""
        return (
            not _WATCHED_CONTAINER_BYPASS[0]
            and bool(_PYIR_SCOPE_STACK)
            and _WATCHED_DICT_READ_HOOK[0] is not None
        )

    def __getitem__(self, key: Any) -> Any:
        try:
            val = dict.__getitem__(self, key)
        except KeyError:
            # A missed lookup consumed the key SET (the absence is the fact
            # the trace acts on): record the contents snapshot, then raise.
            self._pyir_record_miss()
            raise
        if not self._pyir_engaged():
            return val
        _WATCHED_CONTAINER_BYPASS[0] += 1
        try:
            return _WATCHED_DICT_READ_HOOK[0](self, key, val)
        finally:
            _WATCHED_CONTAINER_BYPASS[0] -= 1

    def _pyir_refuse_baked_keyset_read(self) -> None:
        """Refuse a whole-key-set consumption after a key was CREATED inside
        dynamic staged CF: the consumed key set reflects the one traced pass,
        not the runtime branch that decides the insertion."""
        entry = _PYIR_DICT_CF_CREATED_KEYS.get(id(self))
        if entry is None:
            return
        raise DSLUserCodeError(
            DiagId.CONTAINER_DICT_KEY_SET_BAKED_READ,
            var=getattr(self, "_pyir_label", None) or "dict",
            detail=", ".join(sorted(repr(k) for k in entry[1])),
        )

    def _pyir_record_miss(self) -> None:
        # A key-set consumption with no item choke (F-SPEC, same funnel as
        # ``__contains__``).
        if self._pyir_engaged():
            self._pyir_refuse_baked_keyset_read()
            _WATCHED_CONTAINER_BYPASS[0] += 1
            try:
                _pyir_spec_record_membership(self)
            finally:
                _WATCHED_CONTAINER_BYPASS[0] -= 1

    def get(self, key: Any, default: Any = None) -> Any:
        if not dict.__contains__(self, key):
            self._pyir_record_miss()
            if self._pyir_engaged() and _WATCHED_DICT_GET_MISS_HOOK[0] is not None:
                _WATCHED_CONTAINER_BYPASS[0] += 1
                try:
                    _WATCHED_DICT_GET_MISS_HOOK[0](self, key)
                finally:
                    _WATCHED_CONTAINER_BYPASS[0] -= 1
            return default
        return self.__getitem__(key)

    def __contains__(self, key: Any) -> bool:
        # Membership consumes the WHOLE key set through the C-level probe
        # (no item choke fires): record a contents-snapshot row (F-SPEC).
        if self._pyir_engaged():
            self._pyir_refuse_baked_keyset_read()
            _WATCHED_CONTAINER_BYPASS[0] += 1
            try:
                _pyir_spec_record_membership(self)
            finally:
                _WATCHED_CONTAINER_BYPASS[0] -= 1
        return dict.__contains__(self, key)

    def __setitem__(self, key: Any, value: Any) -> None:
        if not self._pyir_engaged():
            dict.__setitem__(self, key, value)
            return
        # Diagnostics-only source attribution via the ONE sanctioned frame
        # helper (never influences emission or slot identity).
        filename, lineno = _first_non_dsl_caller_location()
        _WATCHED_CONTAINER_BYPASS[0] += 1
        try:
            value = _WATCHED_DICT_WRITE_HOOK[0](
                self, key, value, filename or "<watched dict>", lineno or 0
            )
        finally:
            _WATCHED_CONTAINER_BYPASS[0] -= 1
        dict.__setitem__(self, key, value)

    # Structural mutators (key-set changes) are trace-time-only: the object-side
    # hook refuses them inside dynamic staged CF and realizes them everywhere else.

    def _pyir_structural(self, op_name: str, detail: str) -> None:
        if self._pyir_engaged() and _WATCHED_DICT_MUTATOR_HOOK[0] is not None:
            _WATCHED_CONTAINER_BYPASS[0] += 1
            try:
                _WATCHED_DICT_MUTATOR_HOOK[0](self, op_name, detail)
            finally:
                _WATCHED_CONTAINER_BYPASS[0] -= 1

    def __iter__(self) -> Any:
        # Bare iteration walks the KEY set, which is trace-time stable inside
        # dynamic staged CF (structural mutation refuses at the mutator
        # choke), so the raw walk is exact -- per-slot reads re-enter the
        # item choke themselves.  The object-side hook refuses the one
        # unstable case (a key CREATED inside the region) and raw-delegates
        # everywhere else.  The ``.keys()/.values()/.items()`` views route at
        # the call boundary (user calls only), so DSL-internal walks over
        # adopted ``__dict__`` mappings stay unobserved.
        if self._pyir_engaged() and _WATCHED_DICT_ITER_HOOK[0] is not None:
            _WATCHED_CONTAINER_BYPASS[0] += 1
            try:
                _WATCHED_DICT_ITER_HOOK[0](self, "iter()")
            finally:
                _WATCHED_CONTAINER_BYPASS[0] -= 1
        return dict.__iter__(self)

    def __delitem__(self, key: Any) -> None:
        self._pyir_structural("__delitem__", f"del [{key!r}]")
        dict.__delitem__(self, key)

    def _pyir_read_out(self, key: Any, val: Any) -> Any:
        """Route a departing value (``pop``/``popitem``) through the entry's read
        lifecycle so consumers observe the place cell, not region-trapped SSA."""
        if not self._pyir_engaged():
            return val
        _WATCHED_CONTAINER_BYPASS[0] += 1
        try:
            return _WATCHED_DICT_READ_HOOK[0](self, key, val)
        finally:
            _WATCHED_CONTAINER_BYPASS[0] -= 1

    def pop(self, *args: Any) -> Any:
        self._pyir_structural("pop", "pop()")
        if args and dict.__contains__(self, args[0]):
            val = self._pyir_read_out(args[0], dict.__getitem__(self, args[0]))
            dict.__delitem__(self, args[0])
            return val
        return dict.pop(self, *args)

    def popitem(self) -> Any:
        self._pyir_structural("popitem", "popitem()")
        key, val = dict.popitem(self)
        return key, self._pyir_read_out(key, val)

    def clear(self) -> None:
        self._pyir_structural("clear", "clear()")
        dict.clear(self)

    def setdefault(self, key: Any, default: Any = None) -> Any:
        if dict.__contains__(self, key):
            return self.__getitem__(key)
        self._pyir_structural("setdefault", f"setdefault({key!r})")
        dict.__setitem__(self, key, default)
        return default

    def update(self, *args: Any, **kwargs: Any) -> None:
        other: dict = {}
        if args:
            other.update(args[0])
        other.update(kwargs)
        new_keys = [k for k in other if not dict.__contains__(self, k)]
        if new_keys:
            self._pyir_structural("update", f"update() inserting {new_keys!r}")
            for k in new_keys:
                dict.__setitem__(self, k, other.pop(k))
        # Existing keys route through the per-entry write choke, emitting the
        # same stores subscript assignment would.
        for k, v in other.items():
            self[k] = v

    # ``|`` keeps dict.__or__ (a PLAIN dict copy by design), so the augmented
    # form's in-place signature intentionally diverges from it.
    def __ior__(self, other: Any) -> "_WatchedDict":  # type: ignore[misc]
        self.update(other)
        return self

    # --- snapshot semantics: copies are PLAIN dicts --------------------------

    def __copy__(self) -> dict:
        return dict(self)

    def __deepcopy__(self, memo: Any) -> dict:
        import copy as _copy

        out: dict = {}
        memo[id(self)] = out
        for k, v in dict.items(self):
            out[_copy.deepcopy(k, memo)] = _copy.deepcopy(v, memo)
        return out

    def __reduce__(self) -> Any:
        # Serialization de-watches to a PLAIN dict; while engaged, each entry
        # is read THROUGH the choke so the whole-container bake records rows
        # (a staged entry then reaches its natively unpicklable MLIR payload).
        if self._pyir_engaged():
            return (dict, ({k: self[k] for k in dict.keys(self)},))
        return (dict, (dict(self),))

    # --- transparency protocol (F-TRANSPARENT): outside the observation
    # machinery, the wrapper IS its plain value.  Declared once here;
    # boundaries consult the protocol instead of enumerating wrapper types.
    __pyir_plain_type__ = dict

    def __pyir_plain_view__(self) -> dict:
        # Raw snapshot (same de-watch contract as ``__copy__``): every stored
        # element is choke-maintained, so raw storage IS the current value.
        return dict(self)


class _WatchedList(list):
    """Identity-adopted tracked ``list``: integer-index places with the same choke
    lifecycle as :class:`_WatchedDict`; length/order changes are trace-time-only."""

    # Slot attribute type (assigned post-construction at the adoption choke).
    _pyir_label: str

    __slots__ = ("_pyir_label",)

    def _pyir_engaged(self) -> bool:
        """Whether the object-side chokes fire for this access (see class doc)."""
        return (
            not _WATCHED_CONTAINER_BYPASS[0]
            and bool(_PYIR_SCOPE_STACK)
            and _WATCHED_LIST_READ_HOOK[0] is not None
        )

    def __getitem__(self, key: Any) -> Any:
        if not self._pyir_engaged() or isinstance(key, slice):
            # Slice reads are trace-time snapshots (plain-list copies) --
            # declared residue.
            return list.__getitem__(self, key)
        _WATCHED_CONTAINER_BYPASS[0] += 1
        try:
            return _WATCHED_LIST_READ_HOOK[0](self, key)
        except IndexError:
            # A missed lookup consumed the LENGTH (the bounds fact the trace
            # acts on): record the contents snapshot, then raise (F-SPEC,
            # same funnel as ``__contains__``).
            _pyir_spec_record_membership(self)
            raise
        finally:
            _WATCHED_CONTAINER_BYPASS[0] -= 1

    def __contains__(self, key: Any) -> bool:
        # Membership consumes the WHOLE contents through the C-level scan
        # (no item choke fires): record a contents-snapshot row (F-SPEC).
        if self._pyir_engaged():
            _WATCHED_CONTAINER_BYPASS[0] += 1
            try:
                _pyir_spec_record_membership(self)
            finally:
                _WATCHED_CONTAINER_BYPASS[0] -= 1
        return list.__contains__(self, key)

    def __setitem__(self, key: Any, value: Any) -> None:
        if not self._pyir_engaged():
            list.__setitem__(self, key, value)
            return
        if isinstance(key, slice):
            # A slice write can change the length -- structural.
            self._pyir_structural("__setitem__", f"slice write [{key!r}]")
            list.__setitem__(self, key, value)
            return
        # Diagnostics-only source attribution via the ONE sanctioned frame
        # helper (never influences emission or slot identity).
        filename, lineno = _first_non_dsl_caller_location()
        _WATCHED_CONTAINER_BYPASS[0] += 1
        try:
            value = _WATCHED_LIST_WRITE_HOOK[0](
                self, key, value, filename or "<watched list>", lineno or 0
            )
        finally:
            _WATCHED_CONTAINER_BYPASS[0] -= 1
        list.__setitem__(self, key, value)

    # Structural mutators (length/order changes) are trace-time-only: refused in
    # dynamic staged CF; constexpr-scope inserts freeze foreign-bound staged elements.

    def _pyir_structural(self, op_name: str, detail: str) -> None:
        if self._pyir_engaged() and _WATCHED_LIST_MUTATOR_HOOK[0] is not None:
            _WATCHED_CONTAINER_BYPASS[0] += 1
            try:
                _WATCHED_LIST_MUTATOR_HOOK[0](self, op_name, detail)
            finally:
                _WATCHED_CONTAINER_BYPASS[0] -= 1

    def append(self, value: Any) -> None:
        list.append(self, value)
        self._pyir_structural("append", "append()")

    def extend(self, other: Any) -> None:
        list.extend(self, other)
        self._pyir_structural("extend", "extend()")

    def insert(self, index: Any, value: Any) -> None:
        list.insert(self, index, value)
        self._pyir_structural("insert", f"insert({index!r})")

    def pop(self, *args: Any) -> Any:
        # A pop reads the element's place (at the PRE-pop index) before the
        # removal, so post-region consumers observe the place cell.
        if self._pyir_engaged():
            idx = args[0] if args else -1
            read_val = self[idx]  # __getitem__ routes the tracked read
            list.pop(self, *args)
            self._pyir_structural("pop", "pop()")
            return read_val
        val = list.pop(self, *args)
        self._pyir_structural("pop", "pop()")
        return val

    def remove(self, value: Any) -> None:
        list.remove(self, value)
        self._pyir_structural("remove", "remove()")

    def clear(self) -> None:
        list.clear(self)
        self._pyir_structural("clear", "clear()")

    def sort(self, *args: Any, **kwargs: Any) -> None:
        list.sort(self, *args, **kwargs)
        self._pyir_structural("sort", "sort()")

    def reverse(self) -> None:
        list.reverse(self)
        self._pyir_structural("reverse", "reverse()")

    def __delitem__(self, key: Any) -> None:
        list.__delitem__(self, key)
        self._pyir_structural("__delitem__", f"del [{key!r}]")

    # ``+`` keeps list.__add__ (a PLAIN list copy by design), so the augmented
    # form's in-place signature intentionally diverges from it.
    def __iadd__(self, other: Any) -> "_WatchedList":  # type: ignore[misc]
        list.extend(self, other)
        self._pyir_structural("extend", "+=")
        return self

    def __imul__(self, factor: Any) -> "_WatchedList":  # type: ignore[misc]
        list.__imul__(self, factor)
        self._pyir_structural("__imul__", "*=")
        return self

    # --- snapshot semantics: copies are PLAIN lists --------------------------

    def copy(self) -> list:
        return list(self)

    def __copy__(self) -> list:
        return list(self)

    def __deepcopy__(self, memo: Any) -> list:
        import copy as _copy

        out: list = []
        memo[id(self)] = out
        for elem in list.__iter__(self):
            out.append(_copy.deepcopy(elem, memo))
        return out

    def __reduce__(self) -> Any:
        # Same de-watch + choke-read contract as ``_WatchedDict.__reduce__``.
        if self._pyir_engaged():
            return (list, ([self[i] for i in range(list.__len__(self))],))
        return (list, (list(self),))

    # --- transparency protocol (F-TRANSPARENT): see ``_WatchedDict``.
    __pyir_plain_type__ = list

    def __pyir_plain_view__(self) -> list:
        # Raw snapshot (same de-watch contract as ``__copy__``).
        return list(self)


def _pyir_identity_opaque(value: Any) -> bool:
    """Whether *value* is a wrapper the tracer mints over a tracked Python
    place (watched primitive / ir-backed scalar wrapper): its OBJECT identity
    does not follow the program's own object identity.  Raw ``ir.Value``
    objects stay native: their stored-reference identity is a DSL-level
    invariant (the no-op-cast backing share), not an A-axis place wrapper."""
    if isinstance(value, _WatchedM):
        return True
    from .typing import Numeric

    return isinstance(value, Numeric) and isinstance(
        value.__dict__.get("value"), ir.Value
    )


def _pyir_judge_identity_leg(left: Any, right: Any) -> "str | None":
    """Refuse-or-witness one ``is``/``is not`` leg (LangRef 3.12 section
    6.10.3): over tracker-minted wrappers the fold compares WRAPPER identity.
    The fold stands where a declared fact makes it exact -- the two names
    hold one object, or the tracked side's payload domain (bool/int/float)
    is type-disjoint from the other operand, so ``is`` is False in both
    worlds.  Everything else (two distinct wrappers, or a wrapper against a
    numeric primitive CPython may or may not intern) has no trace-time
    answer: refuse loudly.  Returns the witnessed fold kind (``None`` for an
    inert leg)."""
    left_opaque = _pyir_identity_opaque(left)
    right_opaque = _pyir_identity_opaque(right)
    if not left_opaque and not right_opaque:
        return None
    if left is right:
        kind = "same-object"
    elif left_opaque and right_opaque:
        kind = None
    elif type(right if left_opaque else left) in (bool, int, float):
        kind = None
    else:
        kind = "domain-disjoint"
    if kind is None:
        filename, lineno = _first_non_dsl_caller_location()
        opaque = left if left_opaque else right
        raise DSLUserCodeError(
            DiagId.PHASE_IDENTITY_ON_TRACKED,
            filename=filename,
            lineno=lineno,
            what=type(opaque).__name__,
        )
    return kind


def _pyir_identity_compare_choke(
    left: Any, comparators: "list[Any]", ops: "list[Any]"
) -> None:
    """Judge every ``is``/``is not`` leg of one comparison chain; inert
    without an open PyIR trace scope."""
    if not _PYIR_SCOPE_STACK:
        return
    current = left
    for comparator, op in zip(comparators, ops):
        if op in ("is", "is not"):
            _pyir_judge_identity_leg(current, comparator)
        current = comparator


def _pyir_watched_dict_label(container: Any, key: Any) -> str:
    """Diagnostic label for one adopted dict entry (``<adopt-site>[key]``)."""
    base = getattr(container, "_pyir_label", None) or "dict"
    return f"{base}[{key!r}]"


def _pyir_watched_list_label(container: Any, key: Any) -> str:
    """Diagnostic label for one adopted list element (``<adopt-site>[i]``)."""
    base = getattr(container, "_pyir_label", None) or "list"
    return f"{base}[{key!r}]"


def _pyir_adopt_container_value(
    owner: Any,
    slot_name: Any,
    obj: Any,
    label: "str | None",
    raw_type: type,
    watched_cls: type,
    fill: Any,
    entries: Any,
) -> Any:
    """Shared skeleton of the dict/list adoption twins: watched passthrough,
    exact-type gate, unrepointable-holder guard, adopt-once memo (aliases
    converge) with recursive child adoption, holder re-point.  Returns the
    watched twin, or *obj* untouched on a pass-through path (the callers
    skip their container-specific tails then)."""
    if isinstance(obj, watched_cls):
        w = obj
    elif type(obj) is not raw_type:
        return obj
    elif (
        owner is not None
        and slot_name is not None
        and not _pyir_holder_slot_refers(owner, slot_name, obj)
    ):
        # The holder in hand cannot be re-pointed (e.g. a class attribute):
        # adopting would mint a stale watched twin -- keep the raw object.
        return obj
    else:
        w = _WATCHED_CONTAINER_ADOPTIONS.get(id(obj))
        if w is None:
            w = watched_cls()
            w._pyir_label = str(label) if label is not None else raw_type.__name__
            fill(w, obj)
            _WATCHED_CONTAINER_ADOPTIONS[id(obj)] = w
            _WATCHED_CONTAINER_KEEPALIVE.append(obj)
            for k, v in entries(w):
                if type(v) is dict or isinstance(v, _WatchedDict):
                    _pyir_adopt_dict_value(w, k, v, label=f"{w._pyir_label}[{k!r}]")
                elif type(v) is list or isinstance(v, _WatchedList):
                    _pyir_adopt_list_value(w, k, v, label=f"{w._pyir_label}[{k!r}]")
    if w is not obj and owner is not None and slot_name is not None:
        _pyir_replace_holder_slot(owner, slot_name, obj, w)
    return w


def _pyir_adopt_dict_value(
    owner: Any, slot_name: Any, d: Any, label: "str | None" = None
) -> Any:
    """Adopt plain dict *d* as its place-owning :class:`_WatchedDict`: adopt-once
    (aliases converge), known holder slots re-pointed; non-exact dicts pass through."""
    w = _pyir_adopt_container_value(
        owner,
        slot_name,
        d,
        label,
        dict,
        _WatchedDict,
        dict.update,
        lambda w: [(k, dict.__getitem__(w, k)) for k in list(dict.keys(w))],
    )
    if not isinstance(w, _WatchedDict):
        return w  # pass-through: nothing was adopted
    # Instance-storage fact: a mapping adopted through the ``__dict__``
    # pseudo-slot IS the owner's attribute storage (LangRef 3.3.2), so its
    # str-keyed item places unify with the owner's attr places.
    if (
        slot_name == "__dict__"
        and owner is not None
        and not isinstance(owner, type)
        and getattr(owner, "__dict__", None) is w
    ):
        try:
            w._pyir_instance_of = _weakref.ref(owner)
        except TypeError:
            w._pyir_instance_of = owner  # non-weakrefable: trace-scoped strong ref
    _pyir_spec_chain_container(w, owner, slot_name)
    return w


def _pyir_instance_dict_owner(container: Any, key: Any) -> Any:
    """The instance whose attribute storage *container* IS (recorded at the
    ``vars(obj)``/``obj.__dict__`` adoption): a str-keyed item access names the
    SAME place as the attr spelling, so the item chokes route it to the
    instance's attr row -- one place row per storage.  ``None`` when the fact
    is absent, expired (storage re-pointed), the key is not a str, or a data
    descriptor on the class intercepts the attr spelling (different storage)."""
    ref = getattr(container, "_pyir_instance_of", None)
    if ref is None or not isinstance(key, str):
        return None
    owner = ref() if isinstance(ref, _weakref.ref) else ref
    if owner is None:
        return None
    try:
        if getattr(owner, "__dict__", None) is not container:
            return None
        for klass in type(owner).__mro__:
            desc = klass.__dict__.get(key)
            if desc is None:
                continue
            if hasattr(type(desc), "__set__") or hasattr(type(desc), "__delete__"):
                return None
            break
    except Exception:
        return None
    return owner


def _pyir_spec_chain_container(twin: Any, owner: Any, slot_name: Any) -> None:
    """F-SPEC root chaining: an adopted container IS the persistent value of its
    holder slot, so its token roots at the holder's root plus that hop
    (first-wins; owner-less adoptions stay trace-internal)."""
    try:
        if not isinstance(twin, (_WatchedDict, _WatchedList)):
            return
        _pyir_spec_chain_value(twin, owner, slot_name)
    except Exception:
        pass  # chaining must never break the adoption it observes


def _pyir_spec_value_is_ir_wrapper(value: Any) -> bool:
    """True for a value of the MLIR value-tree wrapper family (staged, or its
    class implements the ``__extract_mlir_values__`` protocol): such an object
    observed at a persistent place during the trace is TRACE-EPOCH -- its
    interior is derived from this trace's IR, so a spec-row chain through it
    is trace-internal, never launch-recheckable."""
    if _is_staged_value(value):
        return True
    return getattr(type(value), "__extract_mlir_values__", None) is not None


def _pyir_spec_chain_value(
    value: Any, owner: Any, slot_name: Any = None, steps: "tuple | None" = None
) -> None:
    """F-SPEC root chaining for ANY owner-slot read hop: the value observed at a
    ``(owner, slot)`` place roots at the owner's root plus that hop, so scalar
    legs one composition deeper resolve a re-derivable root path (first-wins;
    hops off unrooted owners stay trace-internal until the owner roots).
    A hop through a TRACE-EPOCH object never chains: re-resolving it at launch
    would walk this trace's consumed IR (the value stamps trace-born instead,
    so deeper hops stay trace-internal too)."""
    try:
        if value is None or owner is None:
            return
        if _is_staged_value(value) or isinstance(value, _WatchedM):
            return
        if type(value) in (bool, int, float, str, bytes) or isinstance(
            value, _enum.Enum
        ):
            return
        if isinstance(value, (types.ModuleType, type)):
            return  # symbol bases carry canonical roots, never holder chains
        if _pyir_spec_value_is_ir_wrapper(value):
            _pyir_spec_stamp_trace_born(value)
            return
        o_tok_early = _owner_token(owner)
        if o_tok_early is not None and o_tok_early in _PYIR_SPEC_TRACE_BORN_TOKENS:
            _pyir_spec_stamp_trace_born(value)
            return
        if steps is None:
            if slot_name is None:
                return
            if isinstance(slot_name, _PlaceSeg):
                steps = slot_name.steps()
            elif isinstance(owner, (dict, list, tuple)) or not isinstance(
                slot_name, str
            ):
                steps = (("item", slot_name),)
            else:
                steps = (("attr", slot_name),)
        v_tok = _owner_token(value)
        o_tok = _owner_token(owner)
        if v_tok is None or o_tok is None or v_tok == o_tok:
            return
        _PYIR_SPEC_CONTAINER_CHAIN.setdefault(v_tok, (o_tok, tuple(steps)))
    except Exception:
        pass  # chaining must never break the read it observes


def _pyir_spec_stamp_trace_born(value: Any) -> None:
    """Stamp *value* TRACE-EPOCH (DF-3): its rows are trace-internal and never
    record.  The strong pin makes the id-token provably name this object for
    the whole trace (a dead stamped wrapper can never alias a fresh holder)."""
    tok = _owner_token(value)
    if tok is not None:
        _PYIR_SPEC_TRACE_BORN_TOKENS.add(tok)
        _PYIR_SPEC_TRACE_BORN_PINS.append(value)


def _pyir_holder_slot_refers(owner: Any, slot_name: Any, obj: Any) -> bool:
    """Whether the ``(owner, slot_name)`` slot references *obj* through re-pointable
    storage; adopting through anything else would split a stale watched twin.
    ``__dict__`` is the instance-storage pseudo-slot (the mapping IS the
    owner's assignable storage, so it is holder storage by definition)."""
    try:
        if isinstance(owner, dict):
            return dict.__getitem__(owner, slot_name) is obj
        if isinstance(owner, list):
            return list.__getitem__(owner, slot_name) is obj
        if slot_name == "__dict__" and not isinstance(owner, type):
            return getattr(owner, "__dict__", None) is obj
        storage = _instance_storage_items(owner)
        return storage is not None and storage.get(slot_name) is obj
    except Exception:
        return False


def _pyir_replace_holder_slot(owner: Any, slot_name: Any, old: Any, new: Any) -> None:
    """Re-point the ``(owner, slot_name)`` slot from *old* to *new*, bypassing user
    hooks and frozen guards; best-effort no-op when the slot moved on."""
    try:
        if isinstance(owner, dict):
            if dict.__getitem__(owner, slot_name) is old:
                dict.__setitem__(owner, slot_name, new)
        elif isinstance(owner, list):
            if list.__getitem__(owner, slot_name) is old:
                list.__setitem__(owner, slot_name, new)
        elif slot_name == "__dict__" and not isinstance(owner, type):
            if getattr(owner, "__dict__", None) is old:
                _pyir_setattr_raw(owner, "__dict__", new)
        else:
            storage = _instance_storage_items(owner)
            if storage is not None and storage.get(slot_name) is old:
                _pyir_setattr_raw(owner, slot_name, new)
    except Exception:
        pass


def _pyir_adopt_list_value(
    owner: Any, slot_name: Any, l: Any, label: "str | None" = None
) -> Any:
    """Adopt plain list *l* as its place-owning :class:`_WatchedList` (exact list
    sibling of :func:`_pyir_adopt_dict_value`); non-exact lists pass through."""
    w = _pyir_adopt_container_value(
        owner,
        slot_name,
        l,
        label,
        list,
        _WatchedList,
        list.extend,
        lambda w: [(i, list.__getitem__(w, i)) for i in range(list.__len__(w))],
    )
    if not isinstance(w, _WatchedList):
        return w  # pass-through: nothing was adopted
    _pyir_spec_chain_container(w, owner, slot_name)
    return w


def _pyir_register_container_held_object(obj: Any) -> None:
    """Record *obj* as a tracked-container leg value (the root -> container-leg ->
    attr-leg composition fact); value-tree-protocol objects are skipped."""
    if obj is None or isinstance(
        obj,
        (
            int,
            float,
            bool,
            str,
            bytes,
            type,
            types.ModuleType,
            ir.Value,
            dict,
            list,
            tuple,
            set,
            frozenset,
        ),
    ):
        return
    oid = id(obj)
    if oid in _WATCHED_CONTAINER_HELD_OBJECTS:
        return
    if _is_staged_value(obj) or _implements_dynamic_expression(obj):
        return
    if not _has_instance_storage(obj):
        return
    _WATCHED_CONTAINER_HELD_OBJECTS.add(oid)
    _WATCHED_CONTAINER_HELD_KEEPALIVE.append(obj)


def _pyir_owner_is_container_held(owner: Any) -> bool:
    """Whether *owner* was discovered as a tracked-container leg value this trace
    (qualifies its attr legs for the adopted meta lifecycle)."""
    return owner is not None and id(owner) in _WATCHED_CONTAINER_HELD_OBJECTS


def _pyir_adopt_sequence_elems(seq: Any, prefix: str) -> None:
    """Element walk shared by the two tuple/list arms of
    :func:`_pyir_adopt_containers_under`: dict/list elements adopt in place
    (a tuple slot cannot re-point, so its container legs keep the raw value),
    the item hop declares each element's root either way, and opaque
    elements recurse."""
    for i, elem in enumerate(seq):
        if type(elem) is dict and isinstance(seq, list):
            seq[i] = _pyir_adopt_dict_value(None, None, elem, label=f"{prefix}[{i}]")
            _pyir_spec_chain_value(seq[i], seq, steps=(("item", i),))
        elif type(elem) is list and isinstance(seq, list):
            seq[i] = _pyir_adopt_list_value(None, None, elem, label=f"{prefix}[{i}]")
            _pyir_spec_chain_value(seq[i], seq, steps=(("item", i),))
        else:
            _pyir_spec_chain_value(elem, seq, steps=(("item", i),))
            _pyir_adopt_containers_under(elem)


# Element types the sequence-adoption walk provably does nothing with; exact
# types only, mirroring the two callees' own early-return checks.
_SEQ_WALK_INERT_PRIMS = frozenset({int, float, bool, str, bytes, type(None)})


def _mark_container_walk_visited(obj: Any, oid: int) -> None:
    """Memoize *obj* as adoption-walked. The visited object is pinned for the
    trace: a GC'd-and-recycled id must never make a fresh object look
    already-walked (its containers would silently escape adoption).

    The pin is why only objects whose re-walk could change something are
    memoized: it also keeps the object's candidate-holder registry row alive,
    and every staged region sweeps that registry, so pinning each staged scalar
    sighted at a ``@dsl_user_op`` boundary would make the per-region sweep grow
    with trace history instead of with live captured state."""
    _WATCHED_CONTAINER_WALKED.add(oid)
    _WATCHED_CONTAINER_WALKED_KEEPALIVE.append(obj)


def _sequence_walk_is_inert(seq: Any) -> bool:
    """True when re-walking *seq* provably changes nothing, so the memo (and the
    trace-long pin it needs) buys nothing.

    Inert = every element is a shape BOTH halves of
    :func:`_pyir_adopt_sequence_elems` return on before any recorded effect: a
    bare Python scalar (``_pyir_spec_chain_value`` line 1 / the adoption walk's
    head filter) or a staged value-tree object (chaining returns on staged,
    adoption returns on the value-tree protocol).  Anything else -- a raw
    ``dict``/``list`` element, an opaque object, a bare ``ir.Value`` (which
    stamps trace-born) -- keeps the memo, since re-walking it would repeat a
    recorded effect."""
    for elem in seq:
        if type(elem) in _SEQ_WALK_INERT_PRIMS:
            continue
        if _is_staged_value(elem) and _implements_dynamic_expression(elem):
            continue
        return False
    return True


def _pyir_adopt_containers_under(obj: Any) -> None:
    """Adoption walk: replace plain dict/list fields reachable from *obj* with
    watched instances; memoized per trace, value-tree objects and bare roots skipped."""
    if obj is None or isinstance(
        obj,
        (int, float, bool, str, bytes, type, types.ModuleType, ir.Value, dict),
    ):
        return
    oid = id(obj)
    if oid in _WATCHED_CONTAINER_WALKED:
        return
    if isinstance(obj, (tuple, list)):
        if not _sequence_walk_is_inert(obj):
            _mark_container_walk_visited(obj, oid)
        _pyir_adopt_sequence_elems(obj, prefix="")
        return
    if _implements_dynamic_expression(obj):
        return  # nothing to walk, so nothing to memoize
    storage = _instance_storage_items(obj)
    if storage is None:
        return
    _mark_container_walk_visited(obj, oid)
    for attr, val in list(storage.items()):
        if isinstance(attr, str) and attr.startswith("__"):
            continue
        if type(val) is dict:
            _pyir_adopt_dict_value(obj, attr, val, label=attr)
        elif type(val) is list:
            _pyir_adopt_list_value(obj, attr, val, label=attr)
        elif isinstance(val, (_WatchedDict, _WatchedList)):
            # A twin persisting from an earlier trace: re-declare its root
            # chain (the chain registry is trace-scoped, the twin is not).
            _pyir_spec_chain_container(val, obj, attr)
            continue
        elif isinstance(val, (tuple, list)):
            _pyir_spec_chain_value(val, obj, attr)
            _pyir_adopt_sequence_elems(val, prefix=str(attr))
        elif not isinstance(val, (int, float, bool, str, bytes)):
            _pyir_adopt_containers_under(val)


def _pyir_holder_read(holder: Any, attr: Any) -> Any:
    """Raw read of a ``(holder, attr)`` slot -- the mirror of
    :func:`_pyir_holder_store` (bypasses watched chokes, user hooks, and
    descriptors: instance/class STORAGE only)."""
    if isinstance(holder, dict):
        return dict.__getitem__(holder, attr)
    if isinstance(holder, list):
        return list.__getitem__(holder, attr)
    if isinstance(holder, types.CellType):
        return holder.cell_contents
    if isinstance(holder, type):
        return holder.__dict__[attr]
    storage = _instance_storage_items(holder)
    if storage is None or attr not in storage:
        raise AttributeError(attr)
    return storage[attr]


def _pyir_record_host_restore(owner: Any, slot_name: Any, pre_value: Any) -> None:
    """Witness a host place's last scalar meta binding before a write; trace
    close restores it if the place is left holding this trace's wrapper."""
    if owner is None or slot_name is None:
        return
    if isinstance(pre_value, _WatchedM):
        pre_value = pre_value._pyir_raw_payload
    if type(pre_value) not in (bool, int, float):
        return  # non-scalar pre-binding: a leftover keeps the stale-epoch refusal
    try:
        ctx_id = id(ir.Context.current)
    except Exception:
        return
    try:
        _PYIR_HOST_RESTORE[(id(owner), slot_name)] = (
            owner,
            slot_name,
            pre_value,
            ctx_id,
        )
    except TypeError:
        pass  # unhashable slot key: a leftover keeps the stale-epoch refusal


def _pyir_restore_host_places() -> None:
    """Trace close: re-point every recorded host place still bound to a wrapper
    THIS compilation minted back to its pre-staging meta binding (the documented
    post-trace state of a promoted place), and re-bake its F-SPEC rows so a
    no-retrace reuse verifies the restored state."""
    for owner, slot_name, pre_value, ctx_id in list(_PYIR_HOST_RESTORE.values()):
        try:
            cur = _pyir_holder_read(owner, slot_name)
        except Exception:
            continue
        if getattr(cur, "_pyir_birth_ctx", None) != ctx_id:
            continue  # meta rebinds and adopted twins stay: last host binding wins
        try:
            _pyir_holder_store(owner, slot_name, pre_value)
        except Exception:
            continue
        _pyir_spec_record_write(_make_slot_key(None, owner, slot_name), pre_value)
    _PYIR_HOST_RESTORE.clear()


def _pyir_holder_store(holder: Any, attr: Any, value: Any) -> None:
    """Raw write of a ``(holder, attr)`` slot (dict entry, list element, or
    attribute), bypassing watched chokes, user hooks, and frozen guards."""
    try:
        _pyir_record_host_restore(holder, attr, _pyir_holder_read(holder, attr))
    except Exception:
        pass  # no pre-binding (first def): nothing to restore
    if isinstance(holder, dict):
        dict.__setitem__(holder, attr, value)
    elif isinstance(holder, list):
        list.__setitem__(holder, attr, value)
    elif isinstance(holder, types.CellType):
        # Closure cell holder: the single ``cell_contents`` binding (the
        # *attr* carries the closure variable name for diagnostics only).
        holder.cell_contents = value
    elif isinstance(holder, type):
        # Class-attribute holder (a context-manager counter):
        # ``object.__setattr__`` rejects classes, plain ``setattr`` works.
        setattr(holder, attr, value)
    else:
        _pyir_setattr_raw(holder, attr, value)


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


def _forget_region_local_slot_state(owner: Any, slot_name: Any) -> None:
    """Drop a region-local meta slot's baked-constant bookkeeping so a sibling
    region starts from op-entry state; slots already in ``_slot_refs`` untouched."""
    slot_key = _make_slot_key(None, owner, slot_name)
    if slot_key is None or slot_key in _slot_refs:
        return
    _meta_uses.pop(slot_key, None)
    _slot_first_def_inside_cf.pop(slot_key, None)
    _slot_first_def_block.pop(slot_key, None)
    _slot_binding_depth.pop(slot_key, None)


def _exit_function_trace() -> None:
    """Clear D1 per-trace state.  Called from ``_jit_scope.finally``."""
    # Host restore first: user-visible bindings must not keep this trace's
    # staged wrappers past compilation (documented promoted-place semantics).
    _pyir_restore_host_places()
    # Scratch-admission enforcement runs at trace close, while the emitted
    # ops are live: every consuming read of an admitted cell needs an
    # in-window reaching store.  A trace already failing keeps its own error;
    # a sweep refusal is held so the state clearing below still runs.
    _scratch_refusal: "BaseException | None" = None
    try:
        if _sys.exc_info()[0] is None:
            _pyir_verify_scratch_admissions()
    except DSLUserCodeError as _e:
        _scratch_refusal = _e
    finally:
        _PYIR_SCRATCH_ADMISSIONS.clear()
        _PYIR_MEMREF_LAST_STORE.clear()
    # F-SPEC seal: snapshot the specialization ledger of the trace that just
    # closed; the compile flow moves it onto the JitCompiledFunction.  An
    # empty-and-complete ledger seals as None (nothing to validate).
    _PYIR_SPEC_SEALED[0] = (
        (
            dict(_PYIR_SPEC_RECORD),
            _PYIR_SPEC_COMPLETE[0],
            _PYIR_SPEC_ENTRY_FUNC[0],
            _pyir_spec_sealed_receiver(),
            _PYIR_SPEC_ENTRY_SIG[0],
        )
        if (_PYIR_SPEC_RECORD or not _PYIR_SPEC_COMPLETE[0])
        else None
    )
    _reset_spec_state()
    _meta_uses.clear()
    _meta_idempotent_write_anchors.clear()
    _slot_refs.clear()
    _slot_templates.clear()
    # Ref write-epochs / promotion rewrite map key MLIR-context-bound
    # ir.Values; never cross traces.
    _REF_WRITE_EPOCH.clear()
    _META_CONST_REPLACEMENTS.clear()
    _PYIR_BOUNDARY_META_CELL_READS.clear()
    _PYIR_BOUNDARY_FLIP_GUARD_READS.clear()
    _PYIR_HOST_RESTORE.clear()
    _PYIR_STRUCTURAL_META_CONSUMPTIONS.clear()
    _PYIR_STRUCTURAL_META_CONSUMPTION_SITES.clear()
    _PYIR_ARM_LOCAL_META_WRITES.clear()
    _PYIR_STAGED_LITERAL_FOLD_WITNESSES.clear()
    _PYIR_STAGED_LITERAL_FOLD_KEEPALIVE.clear()
    _PYIR_STAGED_HASH_WITNESS[0] = 0
    _slot_first_def_inside_cf.clear()
    _slot_first_def_block.clear()
    _slot_first_def_block_any.clear()
    _slot_first_def_depth.clear()
    _slot_first_def_depth_any.clear()
    _slot_binding_depth.clear()
    _pyir_open_loop_body_blocks.clear()
    # Clear the slot registry; it holds MLIR-context-bound MutableValue
    # instances which must not survive across traces.
    _SLOT_REGISTRY.clear()
    _OWNER_KEEPALIVE.clear()
    _PYIR_SLOT_HOLDERS.clear()
    _PYIR_PROMOTED_PLACE_LEAVES.clear()
    # Candidate-holder registry is trace-scoped (its strong non-weakrefable
    # entries must not outlive the trace).  Its id-keyed stamp/segment side
    # rows go with it: clearing the registry discards the weakrefs whose
    # callbacks would otherwise pop them at object death.
    _PYIR_CANDIDATE_HOLDERS.clear()
    _PYIR_HOLDER_WRITE_STAMPS.clear()
    _PYIR_GATHER_SEGMENTS.clear()
    _PYIR_SIGHTING_SETTLED.clear()
    _PYIR_WRITE_CLOCK[0] = 0
    _PYIR_CANDIDATE_REGISTRY_ACTIVE[0] = False
    # Watched-container adoption state is trace-scoped; adopted instances stay
    # embedded in user objects, inert without an open PyIR scope.
    _WATCHED_CONTAINER_ADOPTIONS.clear()
    # Armed opaque-owner audits hold strong owner references; trace-scoped.
    _PYIR_OPAQUE_OWNER_AUDITS.clear()
    # In-CF key-creation records hold strong container references; trace-scoped.
    _PYIR_DICT_CF_CREATED_KEYS.clear()
    _WATCHED_CONTAINER_KEEPALIVE.clear()
    _PYIR_SPEC_CONTAINER_CHAIN.clear()
    _WATCHED_CONTAINER_WALKED.clear()
    _WATCHED_CONTAINER_WALKED_KEEPALIVE.clear()
    _WATCHED_CONTAINER_BYPASS[0] = 0
    _WATCHED_CONTAINER_HELD_OBJECTS.clear()
    _WATCHED_CONTAINER_HELD_KEEPALIVE.clear()
    # Superseded-generation detector state: stamp records hold MutableValues
    # (MLIR-context-bound) and id-keyed entries; none may survive the trace.
    _PYIR_CF_ATTR_FIRST_DEFS.clear()
    _SUPERSEDED_GENERATIONS.clear()
    _SUPERSEDED_LEAF_WRAPPERS.clear()
    _GEN_OBJ_KEEPALIVE.clear()
    _BINDING_GEN.clear()
    _BINDING_REBIND_CELLS.clear()
    _ALIAS_CAPTURES.clear()
    _ALIAS_CAPTURE_ROOT_NAMES.clear()
    _COMPOUND_BINDING_SLOTS.clear()
    _PYIR_GEN_EVENT_SUPPRESS[0] = 0
    # Place layer: clear the per-trace scope stack, owner tokens, and place
    # registry (holds MLIR-context-bound MutableValues).
    _reset_scope_state()
    if _scratch_refusal is not None:
        raise _scratch_refusal


def _pyir_take_sealed_spec() -> "tuple | None":
    """Move the last sealed F-SPEC snapshot to the caller (one collection per
    trace close); ``None`` when no PyIR trace sealed since the last take."""
    sealed = _PYIR_SPEC_SEALED[0]
    _PYIR_SPEC_SEALED[0] = None
    return sealed


def _pyir_assert_entry_attested(func_body: Any, dsl_obj: Any) -> None:
    """V-9 ATTESTED: a trace entry must carry the current rewrite stamp or a
    declared-native mark; anything else traces with invisible reads/writes."""
    if not is_pyir_enabled():
        return
    ver = getattr(getattr(dsl_obj, "preprocessor", None), "choke_set_version", None)
    if ver is None or not getattr(dsl_obj, "enable_preprocessor", True):
        return  # the DSL declared a whole-hog native (non-PyIR) trace mode
    fn = getattr(func_body, "__func__", func_body)
    if getattr(fn, "__pyir_rewritten__", None) == ver:
        return
    if (
        getattr(fn, "__pyir_native__", False)
        or getattr(fn, "_preprocess_enabled", True) is False
    ):
        return
    raise DSLUserCodeError(
        DiagId.INSTRUMENTATION_GAP,
        name=getattr(fn, "__qualname__", getattr(fn, "__name__", repr(fn))),
    )


def _slot_store_for_tier1(
    owner: object, *, create: bool = False
) -> "dict[Any, MutableValue] | None":
    """Return the tier-1 ``__pyir_slots__`` dict on *owner* (``None`` without a
    writable ``__dict__``); *create* installs one bypassing frozen setattr."""
    owner_dict = getattr(owner, "__dict__", None)
    if owner_dict is None:
        return None
    store = owner_dict.get(_SLOT_STORE_ATTR)
    if store is None:
        if not create:
            return None
        store = {}
        try:
            _pyir_setattr_raw(owner, _SLOT_STORE_ATTR, store)
        except (AttributeError, TypeError):
            return None
    return store


def _slot_storage_available(owner: Any) -> bool:
    """True if *owner* can host slot storage; every non-``None`` owner has some
    storage path (tier-1 ``__dict__`` or ``_SLOT_REGISTRY``)."""
    return owner is not None


def _registry_owner(owner: Any) -> bool:
    """True if *owner*'s slots route through ``_SLOT_REGISTRY`` (any owner
    without a WRITABLE instance ``__dict__``: none at all, or a read-only
    mapping like a class's mappingproxy); writable-dict owners use tier-1."""
    if owner is None:
        return False
    d = getattr(owner, "__dict__", None)
    return d is None or not isinstance(d, dict)


def _get_slot_mv(owner: Any, slot_name: Any) -> "MutableValue | None":
    """Look up the ``MutableValue`` bound to ``(owner, slot_name)`` (registry or
    tier-1); ``owner=None`` resolves the ownerless local place directly."""
    if owner is None:
        # Ownerless LOCAL place: place registry only, on the F-CEPLACE
        # instance-qualified key (constexpr scopes never gate production).
        if slot_name is None:
            return None
        try:
            place = _make_slot_key(slot_name, None, None)
        except Exception:
            return None
        return _PLACE_REGISTRY.get(place) if place is not None else None
    # Id-keyed resolution is primary: registry slots for ownerless-storage
    # owners, the tier-1 ``__pyir_slots__`` dict otherwise.
    if _registry_owner(owner):
        slot_id = _make_slot_id(owner, slot_name)
        live_mv = _SLOT_REGISTRY.get(slot_id)
    else:
        live_mv = None
        store = _slot_store_for_tier1(owner)
        if store is not None:
            live_mv = store.get(slot_name)
    # On an id-key MISS resolve by PLACE (a reconstructed holder keeps its
    # token-rooted place); an attr place is unroll-invariant, so the place
    # layer runs inside constexpr scopes too.
    place_fallback = None
    _sc_place = None
    _sc_place_mv = None
    try:
        _place = _corrected_place_for(owner, slot_name)
        _place_mv = _PLACE_REGISTRY.get(_place) if _place is not None else None
        _sc_place, _sc_place_mv = _place, _place_mv
        if live_mv is None:
            place_fallback = _place_mv
    except Exception:
        pass
    # Emission self-check (one-cell-per-place): the diagnostic raise must
    # propagate; pre-filtered on cell identity.
    if _sc_place_mv is not None and live_mv is not None and _sc_place_mv is not live_mv:
        _pyir_emission_self_check(
            "read", owner, slot_name, live_mv, _sc_place, _sc_place_mv
        )
    if live_mv is None:
        return place_fallback
    return live_mv


def _pyir_track_slot_holder(owner: Any) -> None:
    """Record *owner* in the slot-holder registry for the region-close carry sweep;
    id-keyed, never invokes user ``__hash__``/``__eq__``."""
    oid = id(owner)
    if oid not in _PYIR_SLOT_HOLDERS:
        try:
            _PYIR_SLOT_HOLDERS[oid] = _weakref.ref(
                owner, lambda _r: _PYIR_SLOT_HOLDERS.pop(oid, None)
            )
        except TypeError:
            _PYIR_SLOT_HOLDERS[oid] = owner
    # A slot owner is also a candidate root for the captured-holder gathers.
    _pyir_register_candidate_holder(owner)


def _pyir_refuse_del_finalizer_owner(obj: Any) -> None:
    """S4 floor (LangRef 3.12 section 3.3.1): refuse admitting an instance of
    a user class defining ``__del__`` into the ledger's identity domain --
    its finalizer runs at a GC-determined instant, which has no binding
    position in the traced program."""
    from . import pyir_class_facts as _pcf

    definer = _pcf.del_finalizer_definer(type(obj))
    if definer is None:
        return
    from .pyir_call_boundary import _pyir_boundary_module_is_user

    if not _pyir_boundary_module_is_user(getattr(definer, "__module__", None)):
        return  # DSL/stdlib finalizers stay under the wrapper-consumer contract
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.OWNER_DEL_FINALIZER_AT_BIRTH,
        filename=filename,
        lineno=lineno,
        cls=type(obj).__name__,
        definer=definer.__qualname__,
    )


# Per-class verdict for the sighting front gate: True when instances of the
# class provably no-op through BOTH the adoption walk (head filter) and the
# registry filters, so a sighting returns before either. Built from class-shape
# facts only (layout filters, MRO-declared protocol, dynamic attribute hooks),
# so the verdict is stable; same doctrine as ``_VT_PROTOCOL_CLASS_CACHE``.
_PYIR_SIGHTING_INERT_CLASSES: "dict[type, bool]" = {}


def _pyir_sighting_inert_class(cls: type) -> bool:
    """Whether instances of *cls* provably no-op through a candidate sighting."""
    if cls is type(None):
        return True
    if issubclass(cls, (tuple, list)):
        return False  # the adoption walk recurses into sequence elements
    if issubclass(cls, (int, float, bool, str, bytes, type, types.ModuleType, dict)):
        return True  # head-filtered by both the adoption walk and the registry
    if issubclass(cls, ir.Value):
        # A bare Value registers only when it implements the value-tree
        # protocol. The protocol is class-declared (grep-gated, see
        # ``_vt_protocol_class_bucket``), so with default attribute access and
        # no declaration in the MRO the instance check can never turn it on.
        declared = any(
            "__extract_mlir_values__" in k.__dict__ for k in cls.__mro__
        ) and any("__new_from_mlir_values__" in k.__dict__ for k in cls.__mro__)
        if declared:
            return False
        return (
            cls.__getattribute__ is object.__getattribute__
            and getattr(cls, "__getattr__", None) is None
        )
    return False


def _pyir_register_candidate_holder(obj: Any) -> None:
    """Register *obj* as a candidate captured-holder walk root; admits exactly the
    shapes the walkers can yield holders from, id-deduped in sighting order.

    Front gates: a sighting of an inert-class instance (provably filtered by
    type alone) or of a settled id (registered, adoption settled) returns
    before the adoption walk; both verdicts assert the whole body is a no-op."""
    if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
        return
    cls = type(obj)
    inert = _PYIR_SIGHTING_INERT_CLASSES.get(cls)
    if inert is None:
        inert = _PYIR_SIGHTING_INERT_CLASSES[cls] = _pyir_sighting_inert_class(cls)
    if inert:
        return
    oid = id(obj)
    if oid in _PYIR_SIGHTING_SETTLED:
        return
    # Adoption runs at every candidate sighting, memoized per object; placed
    # before the container filter so tuple/list ELEMENTS still adopt.
    adopted = _WATCHED_DICT_READ_HOOK[0] is not None
    if adopted:
        try:
            _pyir_adopt_containers_under(obj)
        except Exception:
            pass
    if obj is None or isinstance(
        obj, (int, float, bool, str, bytes, type, types.ModuleType, tuple, list, dict)
    ):
        return
    if oid in _PYIR_CANDIDATE_HOLDERS:
        _pyir_settle_sighting(obj, oid, adopted)
        return
    if isinstance(obj, ir.Value) and not _implements_dynamic_expression(obj):
        return
    if not _has_instance_storage(obj):
        return
    # S4 floor at ledger admission: a user-defined `__del__` fires at a
    # GC-determined instant with no binding position; judged BEFORE the memo
    # insert so an intake-swallowed refusal re-fires at the next sighting.
    _pyir_refuse_del_finalizer_owner(obj)
    try:
        _PYIR_CANDIDATE_HOLDERS[oid] = _weakref.ref(obj, _pyir_drop_candidate_rows(oid))
        # Write-stamp row minted with the registry entry (and dying with it),
        # so a stamp/segment row can never describe a reused id.
        _PYIR_HOLDER_WRITE_STAMPS[oid] = 0
        _PYIR_GATHER_SEGMENTS.pop(oid, None)
    except TypeError:
        # Non-weakrefable but ``__dict__``-backed: keep a strong, trace-scoped
        # reference so the sweep can still reach it (cleared at trace exit).
        _PYIR_CANDIDATE_HOLDERS[oid] = obj
    _pyir_settle_sighting(obj, oid, adopted)


def _pyir_settle_sighting(obj: Any, oid: int, adopted: bool) -> None:
    """Mark a REGISTERED *obj* settled when its re-sighting is provably a
    no-op: the registry insert dedups on the id, and the adoption walk either
    memoized it or head-filters it by the value-tree protocol. Skipped while
    the adoption hook is down, since a later arming would still need the walk."""
    if adopted and (
        oid in _WATCHED_CONTAINER_WALKED or _implements_dynamic_expression(obj)
    ):
        _PYIR_SIGHTING_SETTLED.add(oid)


def _pyir_drop_candidate_rows(oid: int) -> "Callable[[Any], None]":
    """Registry weakref callback dropping every id-keyed candidate row."""

    def _drop(_r: Any) -> None:
        _PYIR_CANDIDATE_HOLDERS.pop(oid, None)
        _PYIR_HOLDER_WRITE_STAMPS.pop(oid, None)
        _PYIR_GATHER_SEGMENTS.pop(oid, None)
        _PYIR_SIGHTING_SETTLED.discard(oid)

    return _drop


def _pyir_register_trace_args(
    args: Any, kwargs: Any = None, sig: Any = None, entry_func: Any = None
) -> None:
    """Trace-arg intake: register each argument (tuple/list unpacked one level)
    as a candidate holder root. Never raises.

    An OUTER intake (``entry_func`` given) also opens the F-SPEC ledger for
    this trace: argument objects become token roots, entry parameter names
    become pending local roots, and the entry function's own closure cells
    become closure roots."""
    try:
        if not is_pyir_enabled():
            return
        # Arm the fast registration gate for this (and any nested) trace; the
        # per-sighting sites then pay one flag test instead of an env consult.
        _PYIR_CANDIDATE_REGISTRY_ACTIVE[0] = True
        for a in args or ():
            _pyir_register_candidate_holder(a)
            if isinstance(a, (tuple, list)):
                for e in a:
                    _pyir_register_candidate_holder(e)
        if kwargs:
            for v in kwargs.values():
                _pyir_register_candidate_holder(v)
                if isinstance(v, (tuple, list)):
                    for e in v:
                        _pyir_register_candidate_holder(e)
        if entry_func is not None:
            _pyir_spec_open_trace(args, kwargs, sig, entry_func)
    except Exception:
        pass


# --- F-SPEC producers: root registration + the one recording funnel --------


def _pyir_spec_sealed_receiver() -> Any:
    """The receiver to seal with the record: the live first-binding object,
    kept ONLY when the record actually roots rows at the receiver parameter
    (nothing else needs it, and holding an unrelated first argument would pin
    its lifetime).  A receiver that died before the seal leaves rooted rows
    with no live verification root: seal the DEAD sentinel so re-entry
    refuses instead of skipping."""
    cand = _PYIR_SPEC_ENTRY_RECEIVER[0]
    if cand is None:
        return None
    ref, first_name = cand
    if not any(rp[0] == "arg" and rp[1] == first_name for rp in _PYIR_SPEC_RECORD):
        return None
    live = ref()
    return live if live is not None else _SPEC_RECEIVER_DEAD


def _pyir_spec_signature_facts(fn: Any, sig: Any) -> "tuple | None":
    """Entry-signature facts captured once at trace open and sealed with the
    record (DF-1): ``(first_param_name, {name: ("pos", i) | ("kwonly",)})``.
    Launch resolution then reads ``__defaults__[i]`` / ``__kwdefaults__[name]``
    -- pure data reads that still see a REASSIGNED default (drift preserved)
    -- and never re-derives call structure by executing signature code.  The
    index map is validated against the live ``__defaults__``/``__kwdefaults__``
    shape here; on disagreement (a decorated entry whose signature lies) the
    map seals ``None`` and default-rooted rows become unverifiable."""
    if sig is None:
        return None
    try:
        params = list(sig.parameters.values())
        first_param = params[0].name if params else None
        pos_defaulted = [
            p
            for p in params
            if p.kind
            in (
                inspect.Parameter.POSITIONAL_ONLY,
                inspect.Parameter.POSITIONAL_OR_KEYWORD,
            )
            and p.default is not inspect.Parameter.empty
        ]
        kwonly_defaulted = [
            p
            for p in params
            if p.kind is inspect.Parameter.KEYWORD_ONLY
            and p.default is not inspect.Parameter.empty
        ]
        live_defaults = getattr(fn, "__defaults__", None) or ()
        live_kwdefaults = getattr(fn, "__kwdefaults__", None) or {}
        consistent = len(live_defaults) == len(pos_defaulted) and all(
            live_defaults[i] is p.default for i, p in enumerate(pos_defaulted)
        )
        consistent = consistent and all(
            p.name in live_kwdefaults and live_kwdefaults[p.name] is p.default
            for p in kwonly_defaulted
        )
        if not consistent:
            return (first_param, None)
        default_index: "dict[str, tuple]" = {
            p.name: ("pos", i) for i, p in enumerate(pos_defaulted)
        }
        for p in kwonly_defaulted:
            default_index[p.name] = ("kwonly",)
        return (first_param, default_index)
    except Exception:
        return None


def _pyir_spec_open_trace(args: Any, kwargs: Any, sig: Any, entry_func: Any) -> None:
    """Open the F-SPEC ledger for an outer trace: seed the re-resolvable roots
    (this call's argument graph, the entry function's closure cells) and stage
    the entry parameter-name roots for adoption at the entry 'fn' scope."""
    _reset_spec_state()
    fn = getattr(entry_func, "__func__", entry_func)
    _PYIR_SPEC_ENTRY_FUNC[0] = fn
    _PYIR_SPEC_ENTRY_SIG[0] = _pyir_spec_signature_facts(fn, sig)
    # Root paths key arguments by PARAMETER NAME: re-entry calls may omit
    # trace-time-constant arguments, so positional indices do not re-resolve.
    pos_names: "list[str]" = []
    if sig is not None:
        pos_names = [
            p.name
            for p in sig.parameters.values()
            if p.kind
            in (
                inspect.Parameter.POSITIONAL_ONLY,
                inspect.Parameter.POSITIONAL_OR_KEYWORD,
            )
        ]
    for i, a in enumerate(args or ()):
        if i >= len(pos_names):
            break
        name = pos_names[i]
        _pyir_spec_register_root_obj(a, ("arg", name, ()))
        if isinstance(a, (tuple, list)):
            for j, e in enumerate(a):
                _pyir_spec_register_root_obj(e, ("arg", name, (("item", j),)))
        _PYIR_SPEC_PENDING_PARAM_ROOTS.append((name, ("arg", name, ())))
    if kwargs:
        for name, v in kwargs.items():
            _pyir_spec_register_root_obj(v, ("arg", name, ()))
            if isinstance(v, (tuple, list)):
                for j, e in enumerate(v):
                    _pyir_spec_register_root_obj(e, ("arg", name, (("item", j),)))
            _PYIR_SPEC_PENDING_PARAM_ROOTS.append((name, ("arg", name, ())))
    closure = getattr(fn, "__closure__", None)
    if closure:
        for ci, cell in enumerate(closure):
            try:
                contents = cell.cell_contents
            except ValueError:
                continue
            _pyir_spec_register_root_obj(contents, ("closure", ci, ()))
            # A scalar entry cell is a specialization input with no read
            # choke of its own: record it eagerly (the callee boundary arm
            # already applies exactly this contract per called function).
            payload = _pyir_spec_exact_payload(contents)
            if payload is not _SPEC_UNRECORDED:
                _PYIR_SPEC_RECORD.setdefault(("closure", ci, ()), payload)
    # Receiver candidate: a class-defined entry's first positional binding is
    # its receiver (the launch binder never names it, so re-entry validation
    # needs a live root).  Held weakly until the seal decides it is needed.
    recv = getattr(entry_func, "__self__", None)
    qual_parts = getattr(fn, "__qualname__", "").split(".")
    if (
        recv is None
        and args
        and pos_names
        and len(qual_parts) >= 2
        and qual_parts[-2] != "<locals>"
    ):
        recv = args[0]
    if recv is not None and pos_names:
        try:
            _PYIR_SPEC_ENTRY_RECEIVER[0] = (weakref.ref(recv), pos_names[0])
        except TypeError:
            _PYIR_SPEC_ENTRY_RECEIVER[0] = None


def _pyir_spec_register_root_obj(obj: Any, root: tuple) -> None:
    """Register *obj*'s owner token as an F-SPEC root (first-wins); staged
    values and primitives carry no token and are rooted by place instead."""
    if obj is None or _is_staged_value(obj):
        return
    if type(obj) in (bool, int, float, str, bytes):
        return
    tok = _owner_token(obj)
    if tok is not None:
        _PYIR_SPEC_TOKEN_ROOTS.setdefault(tok, root)


def _pyir_spec_seg_steps(segments: "tuple[Any, ...]") -> "tuple[tuple, ...]":
    """Mechanical unfold of place-key segments into re-resolution steps: a
    ``_PlaceSeg`` unfolds the hops recorded at its birth, a plain str is by
    definition a simple attr name (the bracket wall keeps composite strings
    out of key space), anything else is an exact item key."""
    steps: "list[tuple]" = []
    for seg in segments:
        if isinstance(seg, _PlaceSeg):
            steps.extend(seg.steps())
        elif isinstance(seg, str):
            steps.append(("attr", seg))
        else:
            steps.append(("item", seg))
    return tuple(steps)


def _pyir_spec_root_path_for_place(place: Any) -> "tuple | None":
    """Resolve a ledger place to a re-resolvable root path, or ``None`` for a
    trace-internal place (a chain rooting at a trace-born object)."""
    if not isinstance(place, tuple) or len(place) < 3:
        return None
    kind = place[0]
    if kind == "local":
        return _PYIR_SPEC_LOCAL_ROOTS.get(place)
    if kind not in ("attr", "subscript"):
        return None
    tok = place[1]
    if tok in _PYIR_SPEC_TRACE_BORN_TOKENS:
        return None  # trace-epoch owner: the place is trace-internal
    root = _PYIR_SPEC_TOKEN_ROOTS.get(tok)
    if root is None:
        root = _pyir_spec_resolve_container_root(tok)
    if root is None:
        root = _pyir_spec_resolve_global_root(tok)
    if root is None:
        return None
    if kind == "subscript":
        seg = place[2]
        steps = seg.steps() if isinstance(seg, _PlaceSeg) else (("item", seg),)
    else:
        steps = _pyir_spec_seg_steps(place[2:])
    return (root[0], root[1], root[2] + steps)


def _pyir_spec_resolve_container_root(tok: int) -> "tuple | None":
    """Resolve a chained value token through its declared holder chain to a
    re-resolvable root path (memoized on success); ``None`` for a chain that
    bottoms out at a trace-internal holder."""
    steps: "list[tuple]" = []
    seen = {tok}
    cur = tok
    if tok in _PYIR_SPEC_TRACE_BORN_TOKENS:
        return None  # trace-epoch value: the chain is trace-internal
    while True:
        hop = _PYIR_SPEC_CONTAINER_CHAIN.get(cur)
        if hop is None:
            return None
        cur, hop_steps = hop
        if cur in _PYIR_SPEC_TRACE_BORN_TOKENS:
            return None  # the chain passes through a trace-epoch holder
        steps = list(hop_steps) + steps
        root = _PYIR_SPEC_TOKEN_ROOTS.get(cur)
        if root is None and cur not in _PYIR_SPEC_CONTAINER_CHAIN:
            root = _pyir_spec_resolve_global_root(cur)
        if root is not None:
            full = (root[0], root[1], root[2] + tuple(steps))
            _PYIR_SPEC_TOKEN_ROOTS[tok] = full
            return full
        if cur in seen:
            return None
        seen.add(cur)


def _pyir_spec_resolve_global_root(tok: int) -> "tuple | None":
    """Lazily root an unregistered token at the entry function's module
    globals by object identity; a scan miss is cached for the trace."""
    if tok in _PYIR_SPEC_UNROOTED_TOKENS:
        return None
    fn = _PYIR_SPEC_ENTRY_FUNC[0]
    fn_globals = getattr(fn, "__globals__", None)
    if fn_globals:
        for name, val in list(fn_globals.items()):
            if _pyir_lookup_owner_token(val) == tok:
                root = ("global", name, ())
                _PYIR_SPEC_TOKEN_ROOTS[tok] = root
                return root
    _PYIR_SPEC_UNROOTED_TOKENS.add(tok)
    return None


def _pyir_spec_canonical_symbol_root(base: Any) -> "tuple | None":
    """The canonical re-resolvable root of a module or class object: modules
    re-deref through ``sys.modules`` by their own name, classes through their
    defining module and qualname (a ``<locals>`` class has no canonical path).
    Identity-verified against the live registry; ``None`` when unverifiable."""
    try:
        if isinstance(base, types.ModuleType):
            name = getattr(base, "__name__", None)
            if name and _sys.modules.get(name) is base:
                return ("module", name, ())
            return None
        if isinstance(base, type):
            mod_name = getattr(base, "__module__", None)
            qual = getattr(base, "__qualname__", "") or ""
            if not mod_name or not qual or "<locals>" in qual:
                return None
            mod = _sys.modules.get(mod_name)
            if mod is None:
                return None
            cur: Any = mod
            steps = tuple(("attr", part) for part in qual.split("."))
            for _, part in steps:
                cur = getattr(cur, part, None)
            if cur is base:
                return ("module", mod_name, steps)
        return None
    except Exception:
        return None


def _pyir_spec_root_symbol_base(base: Any, mod_name: "str | None") -> None:
    """Root a symbol-read base object (first-wins): canonical module/class
    paths, then the entry function's globals by identity, then the reading
    module's own globals by identity (the choke declares the module)."""
    tok = _owner_token(base)
    if tok is None or tok in _PYIR_SPEC_TOKEN_ROOTS:
        return
    if tok in _PYIR_SPEC_CONTAINER_CHAIN:
        return  # already rooted through a holder chain
    canonical = _pyir_spec_canonical_symbol_root(base)
    if canonical is not None:
        _PYIR_SPEC_TOKEN_ROOTS[tok] = canonical
        return
    if _pyir_spec_resolve_global_root(tok) is not None:
        return
    if not mod_name:
        return
    mod = _sys.modules.get(mod_name)
    mod_dict = getattr(mod, "__dict__", None)
    if not mod_dict:
        return
    for name, val in list(mod_dict.items()):
        if val is base:
            _PYIR_SPEC_TOKEN_ROOTS[tok] = ("module", mod_name, (("attr", name),))
            _PYIR_SPEC_UNROOTED_TOKENS.discard(tok)
            return


def _pyir_spec_observe_attr_read(
    path: Any, base: Any, attr: Any, value: Any, mod_name: "str | None"
) -> None:
    """F-SPEC observation arm for an attribute read the staging chokes never
    route (function-scope, test-position, and module/class-spelled reads):
    roots the base symbol, chains the value hop, and records the read under
    its place.  Observation-only -- the read's value is never altered."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        if base is None or _is_staged_value(base) or isinstance(base, _WatchedM):
            return
        _pyir_spec_root_symbol_base(base, mod_name)
        _pyir_spec_chain_value(value, base, attr)
        _pyir_spec_record_read(_pyir_read_place(path, base, attr), value)
    except Exception:
        # An unobserved bake is a staleness channel the validator cannot
        # re-check: the record turns incomplete (fail closed at re-entry).
        _PYIR_SPEC_COMPLETE[0] = False


def _pyir_spec_observe_global_read(
    name: Any, value: Any, mod_name: "str | None"
) -> None:
    """F-SPEC observation arm for a bare global-name read (no staging choke
    exists for the binding): scalar payloads record under the module root,
    object payloads root the object for its downstream attr/container legs."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        if _is_staged_value(value) or isinstance(value, _WatchedM):
            return
        mod = _sys.modules.get(mod_name) if mod_name else None
        mod_dict = getattr(mod, "__dict__", None)
        if mod_dict is None or name not in mod_dict:
            return  # shadowed / non-module binding: no re-resolvable fact
        current = mod_dict[name]
        root = ("module", mod_name, (("attr", name),))
        payload = _pyir_spec_exact_payload(value)
        if payload is not _SPEC_UNRECORDED:
            if current is value or (type(current) is type(value) and current == value):
                _PYIR_SPEC_RECORD.setdefault(root, payload)
            return
        if current is not value:
            return
        _pyir_spec_register_root_obj(value, root)
    except Exception:
        _PYIR_SPEC_COMPLETE[0] = False


def _pyir_spec_container_snapshot(
    container: Any, kind: "str | None" = None
) -> "_SpecContainerSnapshot | None":
    """Exact contents snapshot of a dict/list (scalar legs by value, object
    legs by identity); ``None`` for a non-container or a kind mismatch."""

    def leg(v: Any) -> Any:
        p = _pyir_spec_exact_payload(v)
        return p if p is not _SPEC_UNRECORDED else _SpecTraceExitObject(v)

    if isinstance(container, dict):
        if kind not in (None, "dict-keys"):
            return None
        return _SpecContainerSnapshot(
            "dict-keys", tuple(leg(k) for k in dict.keys(container))
        )
    if isinstance(container, list):
        if kind not in (None, "list"):
            return None
        return _SpecContainerSnapshot(
            "list", tuple(leg(v) for v in list.__iter__(container))
        )
    return None


def _pyir_spec_record_membership(container: Any) -> None:
    """F-SPEC arm for a whole-container consumption (``in`` routes through the
    C-level ``__contains__``, bypassing every item choke): the bake depends on
    the full contents, so the container's root records a contents snapshot."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        tok = _OWNER_TOKENS.get(container)
        if tok is None:
            return
        root = _PYIR_SPEC_TOKEN_ROOTS.get(tok)
        if root is None:
            root = _pyir_spec_resolve_container_root(tok)
        if root is None:
            root = _pyir_spec_resolve_global_root(tok)
        if root is None:
            return  # trace-internal container: its bake needs no re-check
        snap = _pyir_spec_container_snapshot(container)
        if snap is not None:
            _PYIR_SPEC_RECORD.setdefault(root, snap)
    except Exception:
        _PYIR_SPEC_COMPLETE[0] = False


def _pyir_spec_exact_payload(value: Any) -> Any:
    """The exact structural payload a meta read bakes, or ``_SPEC_UNRECORDED``
    for a value that is not itself a baked scalar (object-shaped reads bake
    through their leaf reads, which record themselves)."""
    if isinstance(value, _WatchedM):
        value = value.python_value
    if value is None or type(value) in (bool, int, float, str, bytes):
        return value
    if isinstance(value, _enum.Enum):
        return value
    if type(value) is tuple:
        elems = tuple(_pyir_spec_exact_payload(e) for e in value)
        if any(e is _SPEC_UNRECORDED for e in elems):
            return _SPEC_UNRECORDED
        return elems
    return _SPEC_UNRECORDED


class _SpecUnrecorded:
    """Sentinel: the read's value is not a recordable exact payload."""


_SPEC_UNRECORDED = _SpecUnrecorded()


def _pyir_spec_numeric_payload(value: Any) -> Any:
    """Payload for a VALUE-SEMANTIC numeric wrapper written to a persistent
    place.  A wrapper carrying a constexpr scalar records that scalar BY VALUE
    (its meaning is the number, not the wrapper instance -- a fresh same-value
    wrapper is not stale).  Returns ``None`` otherwise, so the caller keeps its
    own object/identity handling (a non-derivable staged scalar and an opaque
    object both stay identity rows)."""
    prim = _pyir_meta_primitive_value(value)
    if prim is not _NO_CONST_VALUE:
        payload = _pyir_spec_exact_payload(prim)
        if payload is not _SPEC_UNRECORDED:
            return payload
    return None


def _pyir_spec_record_read(place: Any, value: Any) -> None:
    """F-SPEC recording funnel: a meta read at a root-pathable place records
    (root path -> exact payload), first-wins.  Observation-only on the trace
    path; a trace-internal or non-scalar read records nothing.  A value row
    SUBSUMES a presence-probe row at the same path (the read bakes strictly
    more than the probe's boolean)."""
    try:
        if place is None or not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        payload = _pyir_spec_exact_payload(value)
        if payload is _SPEC_UNRECORDED:
            return
        root_path = _pyir_spec_root_path_for_place(place)
        if root_path is None:
            return
        if _PYIR_SPEC_RECORD.get(root_path) is _SPEC_ATTR_PRESENT:
            _PYIR_SPEC_RECORD[root_path] = payload
            return
        _PYIR_SPEC_RECORD.setdefault(root_path, payload)
    except Exception:
        # Recording must never break the read it observes, but an unrecorded
        # bake is a staleness channel the validator cannot re-check: the
        # record turns incomplete (fail closed at re-entry).
        _PYIR_SPEC_COMPLETE[0] = False


def _pyir_spec_record_attr_probe(owner: Any, attr: str, present: bool) -> None:
    """F-SPEC arm for an attribute PROBE (``hasattr`` / 3-arg ``getattr``
    default-miss): the bake is the presence boolean, never the value, so a
    root-pathable owner records a presence/absence row that re-entry re-probes
    (the answer flipping post-compile refuses instead of re-entering stale)."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        place = _make_slot_key(None, owner, attr)
        if place is None:
            return
        root_path = _pyir_spec_root_path_for_place(place)
        if root_path is None:
            return  # trace-internal owner: its bake needs no re-check
        payload = _SPEC_ATTR_PRESENT if present else _SPEC_ATTR_ABSENT
        _PYIR_SPEC_RECORD.setdefault(root_path, payload)
    except Exception:
        _PYIR_SPEC_COMPLETE[0] = False


def _pyir_spec_note_fabricated_bake(owner: Any, attr: str) -> None:
    """F-SPEC arm for a tolerated ``__getattr__``-fabricated bare-meta read:
    a ROOTED place re-derives through the hook at re-entry (the recording
    funnel keeps it exact); an unrooted one is an unpathable bake the
    validator cannot re-check -- the record turns incomplete (fail closed)."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        place = _make_slot_key(None, owner, attr)
        if place is not None and _pyir_spec_root_path_for_place(place) is not None:
            return
        _PYIR_SPEC_COMPLETE[0] = False
    except Exception:
        _PYIR_SPEC_COMPLETE[0] = False


def _pyir_spec_written_payload(value: Any) -> Any:
    """The trace-exit payload a write amendment re-bakes: the exact structural
    payload when the written value is scalar-shaped, the written object's
    IDENTITY otherwise.  Tuple interiors complete element-wise, so a mixed
    tuple keeps exact verification where exactness exists.  A raw dict/list is
    the one shape whose observed binding is NOT the stored binding (container
    adoption may re-point the holder slot to a watched twin after this
    observation), so it stays unrecordable -- the row keeps its old payload
    and refuses at re-entry, loud."""
    if isinstance(value, _WatchedM):
        value = value.python_value
    payload = _pyir_spec_exact_payload(value)
    if payload is not _SPEC_UNRECORDED:
        return payload
    if type(value) is tuple:
        elems = tuple(_pyir_spec_written_payload(e) for e in value)
        if any(e is _SPEC_UNRECORDED for e in elems):
            return _SPEC_UNRECORDED
        return elems
    if type(value) in (dict, list):
        return _SPEC_UNRECORDED
    # A constexpr-carrying numeric wrapper records BY VALUE; a non-derivable
    # staged scalar and a genuine opaque object both keep an identity row.
    num = _pyir_spec_numeric_payload(value)
    if num is not None:
        return num
    return _SpecTraceExitObject(value)


def _pyir_spec_record_write(place: Any, value: Any) -> None:
    """F-SPEC write amendment: a trace-observed write to a persistent place
    (attr/subscript) re-bakes every recorded row under the written path to the
    written trace-exit payload -- exact for scalars, object identity
    otherwise.  Re-entry then verifies the trace-EXIT state: the trace's own
    pre-launch receiver mutations never read as drift, while any post-compile
    change still refuses.  A write never creates rows, and a row whose leaf
    the written value cannot re-derive keeps its old payload (refuses at
    re-entry, loud)."""
    try:
        if place is None or not _PYIR_SPEC_RECORD:
            return
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        # A local rebind mutates the BINDING, not the persistent state a
        # re-entry re-reads; only owner-place writes amend rows.
        if not isinstance(place, tuple) or place[0] not in ("attr", "subscript"):
            return
        # A TRACE-EPOCH object written to a persistent place is trace-born:
        # rows chaining through it are trace-internal (nothing at a later
        # launch can change it independently of the constexpr inputs that
        # built it, and re-resolving its interior would walk consumed IR).
        if _pyir_spec_value_is_ir_wrapper(value):
            _pyir_spec_stamp_trace_born(value)
        root_path = _pyir_spec_root_path_for_place(place)
        if root_path is None:
            return
        _pyir_spec_amend_rows_under(root_path, value)
    except Exception:
        pass  # an unamended row refuses at re-entry -- loud, never silent


def _pyir_spec_record_unbind(owner: Any, attr: str) -> None:
    """F-SPEC unbind amendment: a trace-observed attribute deletion re-bakes the
    place's row to trace-exit ABSENCE (re-entry re-probes the final hop and
    refuses when the name is back -- the same discipline as a write amendment).
    Rows recorded UNDER the deleted path keep their old payloads: their storage
    no longer resolves, so they refuse at re-entry, loud."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        place = _make_slot_key(None, owner, attr)
        if place is None:
            return
        root_path = _pyir_spec_root_path_for_place(place)
        if root_path is None:
            return  # trace-internal owner: the deletion has no re-entry footprint
        _PYIR_SPEC_RECORD[root_path] = _SPEC_ATTR_ABSENT
    except Exception:
        _PYIR_SPEC_COMPLETE[0] = False


def _pyir_module_cached(name: str) -> bool:
    """True when *name* is a fully initialized entry of the module cache
    (LangRef 3.12 section 5.3.1): importing it again executes no module code."""
    mod = _sys.modules.get(name)
    if mod is None:
        return False
    spec = getattr(mod, "__spec__", None)
    return not getattr(spec, "_initializing", False)


def _pyir_import_is_cached(
    module: "str | None", level: int, names: tuple, package: "str | None"
) -> bool:
    """True when executing the import statement is a pure module-cache hit
    (no module code runs -- the bindings are ordinary meta reads).  A plain
    import needs each dotted module cached; a ``from`` import needs the
    resolved source cached and each name to resolve as an attribute or a
    cached submodule.  Unverifiable resolution answers False (the staged-CF
    wall then refuses, loud)."""
    try:
        if module is None and level == 0:
            return all(_pyir_module_cached(n) for n in names)
        resolved = _pyir_spec_resolve_import(module, level, package)
        if resolved is None or not _pyir_module_cached(resolved):
            return False
        mod = _sys.modules[resolved]
        return all(
            hasattr(mod, n) or _pyir_module_cached(f"{resolved}.{n}") for n in names
        )
    except Exception:
        return False


def _pyir_spec_record_module_identity(name: str) -> None:
    """Root an in-body-imported module as a spec row: the compiled program owns
    the trace-time import, so re-entry verifies ``sys.modules[name]`` is still
    that exact module (a removed/replaced entry would re-import in Python)."""
    mod = _sys.modules.get(name)
    if mod is None:
        _PYIR_SPEC_COMPLETE[0] = False  # bound module not re-derivable: fail closed
        return
    _PYIR_SPEC_RECORD.setdefault(("module", name, ()), _SpecTraceExitObject(mod))


def _pyir_spec_resolve_import(
    module: "str | None", level: int, package: "str | None"
) -> "str | None":
    """Absolute module name of an executed ``from``-import: *package* is the
    defining module's declared package (a rewrite-time constant), anchoring
    the relative walk exactly as the import system does (LangRef 3.12
    section 5.4.2)."""
    if level == 0:
        return module
    if not package:
        return None
    import importlib.util as _importlib_util

    return _importlib_util.resolve_name("." * level + (module or ""), package)


def _pyir_spec_record_import(
    module: "str | None", level: int, pairs: tuple, package: "str | None"
) -> None:
    """F-SPEC record arm for an in-body import statement (meta flow): the
    binding is a trace-time bake off the module, so each bound name records a
    re-derivable spec root.  A plain ``import`` (``module is None, level 0``)
    binds only modules -- identity rows through ``sys.modules``.  A ``from``
    import re-derives each binding off the resolved source module: scalar
    payloads record value rows, object payloads root for their leaf reads;
    a binding the module cannot re-derive fails closed (loud at re-entry)."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        if module is None and level == 0:
            for dotted, value in pairs:
                _pyir_spec_record_module_identity(dotted)
                _pyir_spec_root_symbol_base(value, None)
            return
        resolved = _pyir_spec_resolve_import(module, level, package)
        mod = _sys.modules.get(resolved) if resolved else None
        if resolved is None or mod is None:
            _PYIR_SPEC_COMPLETE[0] = False  # unresolvable source: fail closed
            return
        _pyir_spec_record_module_identity(resolved)
        for attr, value in pairs:
            if isinstance(value, types.ModuleType):
                _pyir_spec_record_module_identity(getattr(value, "__name__", resolved))
                _pyir_spec_root_symbol_base(value, None)
                continue
            root = ("module", resolved, (("attr", attr),))
            current = getattr(mod, attr, _SPEC_UNRECORDED)
            payload = _pyir_spec_exact_payload(value)
            if payload is not _SPEC_UNRECORDED:
                if current is value or (
                    type(current) is type(value) and current == value
                ):
                    _PYIR_SPEC_RECORD.setdefault(root, payload)
                else:
                    _PYIR_SPEC_COMPLETE[0] = False  # binding drifted mid-trace
            elif current is value:
                _pyir_spec_register_root_obj(value, root)
            else:
                _PYIR_SPEC_COMPLETE[0] = False  # binding not re-derivable
    except Exception:
        _PYIR_SPEC_COMPLETE[0] = False


def _pyir_spec_amend_rows_under(root_path: tuple, value: Any) -> None:
    """Re-bake every recorded row under *root_path* from *value* (the
    trace-exit state of that path); a row whose leaf *value* cannot re-derive
    keeps its old payload (refuses at re-entry, loud)."""
    kind, key, steps = root_path
    n = len(steps)
    for rp in list(_PYIR_SPEC_RECORD):
        if rp[0] != kind or rp[1] != key or rp[2][:n] != steps:
            continue
        cur = value
        ok = True
        for step_kind, step_key in rp[2][n:]:
            try:
                if step_kind == "item":
                    cur = cur[step_key]
                elif step_kind == "attr":
                    # An attr step is an owner-SLOT hop: container
                    # adoption models dict items as owner slots, so a
                    # mapping at this hop resolves its slot by key.
                    cur = (
                        cur[step_key]
                        if isinstance(cur, dict)
                        else getattr(cur, step_key)
                    )
                else:
                    ok = False
                    break
            except Exception:
                ok = False
                break
        if not ok:
            continue
        old = _PYIR_SPEC_RECORD.get(rp)
        if isinstance(old, _SpecContainerSnapshot):
            # A whole-container row re-bakes to the trace-exit contents (a
            # shape change keeps the old snapshot: refuses at re-entry, loud).
            snap = _pyir_spec_container_snapshot(cur, old.kind)
            if snap is not None:
                _PYIR_SPEC_RECORD[rp] = snap
            continue
        payload = _pyir_spec_written_payload(cur)
        if payload is _SPEC_UNRECORDED:
            continue
        _PYIR_SPEC_RECORD[rp] = payload


def _pyir_spec_structural_amend(container: Any) -> None:
    """F-SPEC amendment for a STRUCTURAL container mutation: legs under the
    container may have moved, so re-bake its recorded rows from the container's
    post-mutation contents (an orphaned row keeps its old payload and refuses
    at re-entry, loud)."""
    try:
        if not _PYIR_SPEC_RECORD or not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        tok = _OWNER_TOKENS.get(container)
        if tok is None:
            return
        root_path = _PYIR_SPEC_TOKEN_ROOTS.get(tok)
        if root_path is None:
            root_path = _pyir_spec_resolve_container_root(tok)
        if root_path is None:
            return
        _pyir_spec_amend_rows_under(root_path, container)
    except Exception:
        pass  # an unamended row refuses at re-entry -- loud, never silent


def _pyir_stamp_rewritten(fn: Any) -> Any:
    """Innermost decorator emitted under a nested user ``def``: attests exactly
    the raw function object compiled from this trace's instrumented AST.  The
    fact is identity-valued (the attested object itself), so a decorator
    wrapper — even one that copies ``__dict__`` via ``functools.wraps`` — is
    never attested, and an undecoratable decoration result (``@property``)
    never receives a post-decoration attribute store.  A generator/coroutine
    def refuses instead of attesting: its body never runs at the call site, so
    the stamp would certify a body the trace can never observe."""
    if isinstance(fn, types.FunctionType):
        _code = getattr(fn, "__code__", None)
        if inspect.isasyncgenfunction(fn) or inspect.iscoroutinefunction(fn):
            raise DSLUserCodeError(
                DiagId.UNSUP_ASYNC,
                filename=getattr(_code, "co_filename", None),
                lineno=getattr(_code, "co_firstlineno", None),
            )
        if inspect.isgeneratorfunction(fn):
            raise DSLUserCodeError(
                DiagId.UNSUP_YIELD,
                filename=getattr(_code, "co_filename", None),
                lineno=getattr(_code, "co_firstlineno", None),
            )
        setattr(fn, "_dsl_callee_rewritten", fn)
    return fn


def _pyir_callee_is_rewritten(callee: Any) -> bool:
    """True only for a function object a rewrite genuinely attested: the
    identity-valued preprocessor stamp (bound methods unwrap to their
    underlying function) or the module rewriter's ``True`` stamp on the
    exec-compiled result."""
    fn = getattr(callee, "__func__", callee)
    mark = getattr(fn, "_dsl_callee_rewritten", None)
    return mark is fn or mark is True


def _pyir_spec_boundary_closure_read(func: Any, ci: int, contents: Any) -> None:
    """F-SPEC boundary arm: root a callee's closure-cell meta read.  A cell of
    a trace-rewritten nested def is trace-internal; the entry function's own
    cells root at ("closure", i); a module-global callee's cells re-deref
    through the entry function's globals.  Any other scalar cell is a bake
    with no re-resolvable root, so the record turns incomplete (R6b)."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        payload = _pyir_spec_exact_payload(contents)
        if payload is _SPEC_UNRECORDED:
            return  # staged / object-shaped cells are not scalar bakes
        if _pyir_callee_is_rewritten(func):
            return  # nested def born inside this trace: cells are internal
        entry = _PYIR_SPEC_ENTRY_FUNC[0]
        if entry is None:
            return
        if func is entry:
            _PYIR_SPEC_RECORD.setdefault(("closure", ci, ()), payload)
            return
        gname = getattr(func, "__name__", None)
        entry_globals = getattr(entry, "__globals__", None) or {}
        if gname is not None and entry_globals.get(gname) is func:
            _PYIR_SPEC_RECORD.setdefault(("global", gname, (("cell", ci),)), payload)
            return
        _PYIR_SPEC_COMPLETE[0] = False
    except Exception:
        pass  # recording must never break the read it observes


def _pyir_boundary_taken_defaults(
    callee: Any, args: Any, kwargs: Any
) -> "list[tuple[tuple, Any]]":
    """The parameter defaults this call BINDS (CPython 3.12 LangRef §8.7 /
    §6.3.4: defaults evaluate once at def time; a call binds the STORED object
    for every defaulted parameter the arguments leave unbound).  Selectors
    address ``__defaults__`` by index and ``__kwdefaults__`` by name."""
    func = getattr(callee, "__func__", callee)
    code = getattr(func, "__code__", None)
    if code is None:
        return []
    dflts = getattr(func, "__defaults__", None) or ()
    kwdflts = getattr(func, "__kwdefaults__", None) or {}
    if not dflts and not kwdflts:
        return []
    n_pos = len(args) + (1 if getattr(callee, "__self__", None) is not None else 0)
    names = code.co_varnames[: code.co_argcount]
    first = code.co_argcount - len(dflts)
    taken: "list[tuple[tuple, Any]]" = []
    for j, d in enumerate(dflts):
        i = first + j
        if i < n_pos or not (0 <= i < len(names)):
            continue  # bound positionally (extras spill to *args)
        if i >= code.co_posonlyargcount and names[i] in kwargs:
            continue  # bound by keyword (a pos-only name in kwargs feeds **kw)
        taken.append((("default", j), d))
    for name, d in kwdflts.items():
        if name not in kwargs:
            taken.append((("kwdefault", name), d))
    return taken


def _pyir_spec_unwrap_steps(cand: Any, func: Any) -> "tuple | None":
    """Attr steps re-deref'ing *cand*'s ``__wrapped__`` chain (the standard
    functools.wraps identity) down to *func*; a direct identity match is the
    empty tuple; ``None`` when the chain never reaches it."""
    steps: "tuple[tuple, ...]" = ()
    seen: "set[int]" = set()
    cur = cand
    try:
        while cur is not None and id(cur) not in seen:
            if cur is func:
                return steps
            seen.add(id(cur))
            cur = getattr(cur, "__wrapped__", None)
            steps += (("attr", "__wrapped__"),)
    except Exception:
        return None
    return None


def _pyir_spec_callee_defaults_root(func: Any) -> "tuple | None":
    """Re-resolvable root path of a boundary callee FUNCTION object: its name
    (or an identity-scanned alias) in the entry function's globals, else its
    defining module + qualname walk; a decorator wrapper at the canonical
    binding re-derefs through the standard ``__wrapped__`` chain -- always
    identity-verified against the live object; ``None`` when no canonical
    path re-derefs to this function."""
    entry = _PYIR_SPEC_ENTRY_FUNC[0]
    if entry is None:
        return None
    entry_globals = getattr(entry, "__globals__", None) or {}
    gname = getattr(func, "__name__", None)
    if gname is not None and gname in entry_globals:
        steps = _pyir_spec_unwrap_steps(entry_globals[gname], func)
        if steps is not None:
            return ("global", gname, steps)
    for name, val in list(entry_globals.items()):
        if val is func:
            return ("global", name, ())
        if callable(val):
            steps = _pyir_spec_unwrap_steps(val, func)
            if steps is not None:
                return ("global", name, steps)
    mod_name = getattr(func, "__module__", None)
    qual = getattr(func, "__qualname__", "") or ""
    if mod_name and qual and "<locals>" not in qual:
        cur: Any = _sys.modules.get(mod_name)
        for part in qual.split("."):
            cur = getattr(cur, part, None)
        steps = _pyir_spec_unwrap_steps(cur, func)
        if steps is not None:
            return (
                "module",
                mod_name,
                tuple(("attr", p) for p in qual.split(".")) + steps,
            )
    return None


def _pyir_register_taken_default_holders(callee: Any, args: Any, kwargs: Any) -> None:
    """Executor-side intake for an INLINE rewritten callee: its taken defaults
    enter the body as parameter bindings with no dispatcher walk in the way,
    so they join the candidate-holder domain exactly like call arguments
    (their leaf reads then record at the body's own chokes).  Never raises."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        for _sel, d in _pyir_boundary_taken_defaults(callee, args, kwargs):
            if _is_staged_value(d):
                continue
            _pyir_register_candidate_holder(d)
            if isinstance(d, (tuple, list)):
                for e in d:
                    _pyir_register_candidate_holder(e)
    except Exception:
        pass


def _pyir_spec_boundary_default_reads(callee: Any, args: Any, kwargs: Any) -> None:
    """F-SPEC boundary arm: a TAKEN default is external def-time state consumed
    with no read choke (LangRef §8.7), so each taken payload seals at the
    callee's ``__defaults__``/``__kwdefaults__`` path -- scalars by exact
    payload, plain containers by contents snapshot plus per-leg rows, object
    defaults by root registration for their leaf rows.  A taken payload with
    no re-resolvable callee path turns the record incomplete (fail closed)."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return
        taken = _pyir_boundary_taken_defaults(callee, args, kwargs)
        if not taken:
            return
        func = getattr(callee, "__func__", callee)
        if _pyir_callee_is_rewritten(func):
            return  # trace-born nested def: its defaults are trace-internal
        root = _pyir_spec_callee_defaults_root(func)
        for sel, d in taken:
            if _is_staged_value(d):
                continue  # staged flow is not a meta bake
            if root is None:
                _PYIR_SPEC_COMPLETE[0] = False
                continue
            path = (root[0], root[1], root[2] + (sel,))
            if isinstance(d, (_WatchedDict, _WatchedList)):
                # Adopted container: consumptions record at its chokes; the
                # defaults path makes those rows re-resolvable.
                _pyir_spec_register_root_obj(d, path)
                continue
            if isinstance(d, _WatchedM):
                continue  # place-attributed wrapper: reads record at its place
            payload = _pyir_spec_exact_payload(d)
            if payload is not _SPEC_UNRECORDED:
                _PYIR_SPEC_RECORD.setdefault(path, payload)
                continue
            _pyir_spec_register_root_obj(d, path)
            if isinstance(d, (dict, list)):
                snap = _pyir_spec_container_snapshot(d)
                if snap is not None:
                    _PYIR_SPEC_RECORD.setdefault(path, snap)
            if isinstance(d, dict):
                items: Any = [(k, dict.__getitem__(d, k)) for k in dict.keys(d)]
            elif isinstance(d, tuple):
                items = list(enumerate(d))
            else:
                continue  # instance default: leaf rows record at their chokes
            for k, v in items:
                leg = _pyir_spec_exact_payload(v)
                _PYIR_SPEC_RECORD.setdefault(
                    (path[0], path[1], path[2] + (("item", k),)),
                    leg if leg is not _SPEC_UNRECORDED else _SpecTraceExitObject(v),
                )
    except Exception:
        _PYIR_SPEC_COMPLETE[0] = False


def _pyir_registry_candidate_objects() -> "list[Any]":
    """Return the live candidate holders in sighting order (weakrefs resolved,
    strong-held entries passed through)."""
    out: "list[Any]" = []
    for entry in list(_PYIR_CANDIDATE_HOLDERS.values()):
        obj = entry() if isinstance(entry, _weakref.ref) else entry
        if obj is not None:
            out.append(obj)
    return out


def _set_slot_mv(owner: Any, slot_name: Any, mv: "MutableValue") -> "MutableValue":
    """Register *mv* for the slot and return the CANONICAL cell: a live same-typed
    cell already at the place is adopted (stored into), never replaced."""
    if owner is None:
        if slot_name is None:
            return mv
        try:
            place = _make_slot_key(slot_name, None, None)
        except Exception:
            return mv
        if place is None:
            return mv
        _local_prev = _PLACE_REGISTRY.get(place)
        if (
            _local_prev is not None
            and _local_prev is not mv
            and _local_prev._ref is not None
            and _local_prev._is_ref_accessible()
            and mv._ref is not None
            and _local_prev._ref.type == mv._ref.type
        ):
            # Live place cell of the same type: adopt it (INV-1).
            if mv._value is not None and _is_staged_value(mv._value):
                _local_prev.store(mv._value)
            _local_prev._place = place
            return _local_prev
        _PLACE_REGISTRY[place] = mv
        # A fresh cell registered at the place IS the new generation: any
        # superseded-unadvanced mark on the place is discharged.
        _PYIR_SUPERSEDED_PLACE_ROWS.pop(place, None)
        mv._place = place
        return mv
    # Also register the SAME MutableValue by PLACE (adopting a live same-typed
    # cell); an attr place is unroll-invariant, so this runs inside constexpr
    # scopes too (mirroring the read side).
    _sc_place = None
    try:
        _place = _corrected_place_for(owner, slot_name)
        if _place is not None:
            _sc_place = _place
            _prev = _PLACE_REGISTRY.get(_place)
            if (
                _prev is not None
                and _prev is not mv
                and _prev._ref is not None
                and _prev._is_ref_accessible()
                and mv._ref is not None
                and _prev._ref.type == mv._ref.type
            ):
                # Live place cell of the same type: adopt it (INV-1).
                if mv._value is not None and _is_staged_value(mv._value):
                    _prev.store(mv._value)
                mv = _prev
            else:
                _PLACE_REGISTRY[_place] = mv
                _PYIR_SUPERSEDED_PLACE_ROWS.pop(_place, None)
            # Stamp the cell with its place so a type-transition re-mint
            # can re-book the place's bare-ref row.
            mv._place = _place
    except Exception:
        pass
    # Emission self-check post-condition: the place must now map to the ONE
    # canonical cell; OUTSIDE the guard so the diagnostic raise propagates.
    if _sc_place is not None:
        _sc_prev = _PLACE_REGISTRY.get(_sc_place)
        if _sc_prev is not None and _sc_prev is not mv:
            _pyir_emission_self_check(
                "write", owner, slot_name, mv, _sc_place, _sc_prev
            )
    if _registry_owner(owner):
        slot_id = _make_slot_id(owner, slot_name)
        _SLOT_REGISTRY[slot_id] = mv
        _pyir_track_slot_holder(owner)
        return mv
    store = _slot_store_for_tier1(owner, create=True)
    if store is None:
        # A dropped registration severs the slot's carry -- surface an unknown
        # owner kind instead of silently skipping it.
        raise DSLRuntimeError(
            "PyIR internal error: tier-1 slot storage is unavailable for "
            f"owner of type {type(owner).__name__!r} (slot {slot_name!r})."
        )
    store[slot_name] = mv
    _pyir_track_slot_holder(owner)
    return mv


def _slot_registry_attr_mvs_for_owner(
    owner: Any,
) -> "list[tuple[Any, MutableValue]]":
    """Enumerate *owner*'s ATTRIBUTE slots in ``_SLOT_REGISTRY`` (registration
    order); subscript slots are excluded."""
    oid = id(owner)
    return [
        (slot_id.key, mv)
        for slot_id, mv in list(_SLOT_REGISTRY.items())
        if slot_id.kind == "attr" and slot_id.owner == oid
    ]


def _iter_owner_slot_mvs(
    owner: Any,
) -> "list[tuple[Any, MutableValue]]":
    """Yield ``(slot_name, MutableValue)`` pairs registered for *owner* (tier-1
    store or ``_SLOT_REGISTRY``); ``pyir_read`` refreshes them so property
    getters see cross-region writes."""
    if owner is None:
        return []
    store = _slot_store_for_tier1(owner)
    if store is not None:
        return list(store.items())
    if _registry_owner(owner) and not isinstance(owner, (dict, list)):
        return _slot_registry_attr_mvs_for_owner(owner)
    return []


# Superseded-generation detection: rebind events, stamps, and read/write fire
# checks; keyed on registry facts only, never value shapes. Tables: pyir_state.


class _PyirGenEventSuppress:
    """Reentrancy guard: while entered, generation rebind events are not
    recorded and superseded-generation checks do not fire."""

    def __enter__(self) -> None:
        _PYIR_GEN_EVENT_SUPPRESS[0] += 1

    def __exit__(self, *_exc: Any) -> "_Literal[False]":
        _PYIR_GEN_EVENT_SUPPRESS[0] -= 1
        return False


def _pyir_gen_events_suppressed() -> bool:
    return _PYIR_GEN_EVENT_SUPPRESS[0] > 0


def _pyir_is_generation_compound(value: Any) -> bool:
    """True for a compound user object that can carry staged leaf places --
    the object kind whose whole-object rebind is a generation event."""
    if not _has_instance_storage(value):
        return False
    if isinstance(value, (int, float, bool, str, bytes, type, types.ModuleType)):
        return False
    if _is_staged_value(value):
        return False
    return True


def _pyir_keepalive_generation_obj(obj: Any) -> None:
    """Pin *obj*'s id() for the trace so the id-keyed generation tables never
    alias a recycled address; weakref with drop callback when possible."""
    oid = id(obj)
    if oid in _GEN_OBJ_KEEPALIVE:
        return

    def _drop(_ref: Any, _oid: int = oid) -> None:
        # Purge EVERY (oid, *)-keyed row this pin guards: a surviving row
        # would re-anchor onto whatever object recycles the address.
        _SUPERSEDED_GENERATIONS.pop(_oid, None)
        _COMPOUND_BINDING_SLOTS.pop(_oid, None)
        for _key in [k for k in _PYIR_CF_ATTR_FIRST_DEFS if k[0] == _oid]:
            _PYIR_CF_ATTR_FIRST_DEFS.pop(_key, None)
        _GEN_OBJ_KEEPALIVE.pop(_oid, None)

    try:
        _GEN_OBJ_KEEPALIVE[oid] = _weakref.ref(obj, _drop)
    except TypeError:
        _GEN_OBJ_KEEPALIVE[oid] = obj


def _pyir_snapshot_generation_cells(obj: Any) -> "dict[Any, tuple]":
    """Snapshot *obj*'s registered leaf cells as {slot: (MutableValue,
    store_version)} -- the baseline the fire rule compares against."""
    cells: "dict[Any, tuple]" = {}
    for slot_name, mv in _iter_owner_slot_mvs(obj):
        if mv is None or mv._ref is None:
            continue
        cells[slot_name] = (mv, mv._store_version)
    return cells


def _pyir_record_compound_binding(
    target_name: Any,
    owner: Any,
    slot_name: Any,
    new_value: Any,
    filename: "str | None",
    lineno: "int | None",
) -> None:
    """Track compound binding places at the assign choke: a first binding records
    the root place; rebinding an already-rooted compound records an alias capture."""
    if new_value is None or not _pyir_is_generation_compound(new_value):
        return
    if _pyir_gen_events_suppressed() or is_inside_constexpr_loop():
        return
    try:
        binding_slot = _make_slot_key(target_name, owner, slot_name)
    except Exception:
        return
    if binding_slot is None:
        return
    oid = id(new_value)
    root = _COMPOUND_BINDING_SLOTS.get(oid)
    if root is None:
        _COMPOUND_BINDING_SLOTS[oid] = binding_slot
        _pyir_keepalive_generation_obj(new_value)
        # This place now roots a fresh object: a stale capture at the same
        # place no longer describes the current binding.
        _ALIAS_CAPTURES.pop(binding_slot, None)
        return
    if root == binding_slot:
        _ALIAS_CAPTURES.pop(binding_slot, None)
        return
    # Alias capture is only consultable for a bare-local root name (the read
    # choke discriminates on the dotted target's root NAME).
    if binding_slot[0] != "local":
        return
    _ALIAS_CAPTURES[binding_slot] = {
        "root": root,
        "gen": _BINDING_GEN.get(root, 0),
    }
    _ALIAS_CAPTURE_ROOT_NAMES.add(binding_slot[2])


def _pyir_stamp_superseded_generation(
    obj: Any,
    live_obj: Any,
    target_name: Any,
    filename: "str | None",
    lineno: "int | None",
    cells: "dict[Any, tuple]",
) -> None:
    """Stamp *obj* as a superseded generation: record the pre-rebind cell
    versions and its own staged leaf wrappers (excluding shared ones)."""
    rec: "dict[str, Any]" = {
        "target": target_name,
        "site": (filename, lineno),
        "cells": cells,
        "wrapper_refs": [],
    }
    live_d = _instance_storage_items(live_obj) or {}
    for slot_name, value in list((_instance_storage_items(obj) or {}).items()):
        if slot_name not in cells:
            continue
        if not _is_staged_value(value):
            continue
        if live_d.get(slot_name) is value:
            continue  # wrapper shared with the live generation
        _SUPERSEDED_LEAF_WRAPPERS[id(value)] = (rec, slot_name)
        rec["wrapper_refs"].append(value)
    _SUPERSEDED_GENERATIONS[id(obj)] = rec
    _pyir_keepalive_generation_obj(obj)


# Store-version sentinel for a cell born at the rebind itself: any read
# resolving it diverges, so its baseline is always "advanced".
_PYIR_GEN_CELL_BORN_AT_REBIND = -1


def _pyir_record_rebind_ref_cell(
    rebind_rec: "dict | None", attr: Any, ref: Any
) -> None:
    """Register a D1-promoted meta-field ``pyir.ref`` as a born-at-rebind cell
    of a whole-object rebind record (the raw-ref cell form the alias-capture
    channel resolves against the live meta-value-table row)."""
    if rebind_rec is None or ref is None:
        return
    rebind_rec["cells"][attr] = (ref, _PYIR_GEN_CELL_BORN_AT_REBIND)


def _pyir_record_generation_rebind(
    binding_slot: Any,
    old_value: Any,
    new_value: Any,
    target_name: Any,
    filename: "str | None",
    lineno: "int | None",
    superseded_obj: Any = None,
    allow_empty_cells: bool = False,
) -> "dict | None":
    """Record a whole-object rebind of a compound binding place: bump the place's
    generation counter(s) and stamp a retained non-current generation."""
    if _pyir_gen_events_suppressed() or is_inside_constexpr_loop():
        return None
    cells = _pyir_snapshot_generation_cells(old_value)
    if not cells and not allow_empty_cells:
        return None
    keys = []
    if binding_slot is not None:
        keys.append(binding_slot)
    root = _COMPOUND_BINDING_SLOTS.get(id(old_value))
    if root is not None and root != binding_slot:
        keys.append(root)
    if not keys:
        return None
    rebind_rec = {"cells": cells, "site": (filename, lineno)}
    for k in keys:
        _BINDING_GEN[k] = _BINDING_GEN.get(k, 0) + 1
        _BINDING_REBIND_CELLS[k] = rebind_rec
    if superseded_obj is not None and cells:
        _pyir_stamp_superseded_generation(
            superseded_obj, new_value, target_name, filename, lineno, cells
        )
    return rebind_rec


def _pyir_complete_generation_rebind_cells(
    rebind_rec: "dict | None", old_value: Any
) -> None:
    """Complete an m2m rebind record with cells the decompose walk minted;
    their baseline is the always-advanced born-at-rebind sentinel."""
    if rebind_rec is None or _pyir_gen_events_suppressed():
        return
    cells = rebind_rec["cells"]
    for slot_name, mv in _iter_owner_slot_mvs(old_value):
        if slot_name in cells or mv is None or mv._ref is None:
            continue
        cells[slot_name] = (mv, _PYIR_GEN_CELL_BORN_AT_REBIND)


def _pyir_raise_superseded(access: str, var: Any, rebind_site: "tuple | None") -> None:
    """Raise the superseded-generation diagnostic."""
    detail = ""
    if rebind_site and rebind_site[0]:
        detail = f" (replaced at {rebind_site[0]}:{rebind_site[1]})"
    raise DSLUserCodeError(
        DiagId.SCOPE_READ_OF_SUPERSEDED_GENERATION,
        var=str(var),
        access=access,
        detail=detail,
    )


def _pyir_check_superseded_owner_write(
    owner: Any, slot_name: Any, new_value: Any, target_name: Any
) -> None:
    """Write choke: a write through a superseded generation lands in the one
    live cell and would corrupt the current generation -> diagnostic."""
    rec = _SUPERSEDED_GENERATIONS.get(id(owner))
    if rec is None or _pyir_gen_events_suppressed():
        return
    if slot_name not in rec["cells"] and not _is_staged_value(new_value):
        return
    _pyir_raise_superseded("written", target_name or rec["target"], rec["site"])


def _pyir_check_superseded_wrapper_load(value: Any) -> None:
    """Auto-load choke: a superseded generation's own leaf wrapper whose shared
    cell advanced past the stamp would observe the replacing value -> raise."""
    if not _SUPERSEDED_LEAF_WRAPPERS or value is None:
        return
    ent = _SUPERSEDED_LEAF_WRAPPERS.get(id(value))
    if ent is None or _pyir_gen_events_suppressed():
        return
    rec, w_slot = ent
    cell = rec["cells"].get(w_slot)
    if cell is None:
        return
    mv0, v0 = cell
    if mv0._store_version <= v0:
        return
    _pyir_raise_superseded("read", rec["target"], rec["site"])


def _pyir_check_alias_generation_read(
    root_name: str, target_name: Any, owner: Any, slot_name: Any
) -> None:
    """Alias-capture channel: fires only when the dotted read resolves the same
    cell the root place held at the rebind AND its store version advanced."""
    try:
        key = _make_slot_key(root_name, None, None)
    except Exception:
        return
    cap = _ALIAS_CAPTURES.get(key)
    if cap is None:
        return
    root_slot = cap["root"]
    if _BINDING_GEN.get(root_slot, 0) <= cap["gen"]:
        return
    rebind = _BINDING_REBIND_CELLS.get(root_slot)
    if rebind is None:
        return
    cell = rebind["cells"].get(slot_name)
    if cell is None:
        return
    mv0, v0 = cell
    if isinstance(mv0, ir.Value):
        # Raw-ref cell: a D1-promoted meta field of a carried all-meta
        # compound rebind.  Identity is the live meta-value-table row; the
        # born-at-rebind baseline means any capture-crossing read diverges.
        try:
            live = _slot_refs.get(_make_slot_key(None, owner, slot_name))
        except Exception:
            live = None
        if not isinstance(live, ir.Value) or not _same_ir_value(live, mv0):
            return
        _pyir_raise_superseded("read", target_name, rebind["site"])
    mv = _get_slot_mv(owner, slot_name)
    if mv is not mv0:
        return
    if mv0._store_version <= v0:
        return
    _pyir_raise_superseded("read", target_name, rebind["site"])


def _pyir_generation_read_checks(
    target_name: Any, current_value: Any, owner: Any, slot_name: Any
) -> None:
    """Read choke: owner-identity, leaf-wrapper, and alias-capture channels,
    each guarded by the store-version-advanced conjunct."""
    if _pyir_gen_events_suppressed():
        return
    if owner is not None and _SUPERSEDED_GENERATIONS:
        rec = _SUPERSEDED_GENERATIONS.get(id(owner))
        if rec is not None:
            cell = rec["cells"].get(slot_name)
            if cell is not None:
                mv0, v0 = cell
                if mv0._store_version > v0:
                    _pyir_raise_superseded(
                        "read", target_name or rec["target"], rec["site"]
                    )
    _pyir_check_superseded_wrapper_load(current_value)
    if _ALIAS_CAPTURE_ROOT_NAMES and owner is not None and isinstance(target_name, str):
        root_name, sep, _rest = target_name.partition(".")
        if sep and root_name in _ALIAS_CAPTURE_ROOT_NAMES:
            _pyir_check_alias_generation_read(root_name, target_name, owner, slot_name)


# Region-conditional attribute first-defs: the attr persists on the shared
# owner beyond its arm, so an uncovered read re-materializes an unbound value.


def _pyir_current_region_arm_path() -> tuple:
    """The trace-time region-arm path: the 'region' frames of the scope stack;
    distinct frame objects distinguish sibling arms of one ``scf.if``."""
    return tuple(f for f in _PYIR_SCOPE_STACK if f.kind == "region")


def _pyir_arm_path_covers(recorded: tuple, current: tuple) -> bool:
    """True iff every arm on the recorded path is still open on the current
    path (identity-compared prefix)."""
    if len(recorded) > len(current):
        return False
    for a, b in zip(recorded, current):
        if a is not b:
            return False
    return True


def _pyir_record_cf_attr_first_def(owner: Any, slot_name: Any) -> None:
    """Record a staged attr-leaf first-def minted inside a staged region; keys
    on binding-position facts only (owner identity + region-arm path)."""
    if owner is None or slot_name is None:
        return
    if _pyir_gen_events_suppressed() or is_inside_constexpr_loop():
        return
    arms = _pyir_current_region_arm_path()
    if not arms:
        return  # not inside a region body: unconditional first-def
    src_file, src_line = _first_non_dsl_caller_location()
    _PYIR_CF_ATTR_FIRST_DEFS[(id(owner), slot_name)] = {
        "arms": arms,
        "site": (src_file, src_line),
    }
    _pyir_keepalive_generation_obj(owner)
    # Under a folded constant if branch, hand the record to the latch consumer:
    # a latched gate proves a once-per-key init and discharges it.
    if _PYIR_FOLD_FIRSTDEF_STACK:
        _PYIR_FOLD_FIRSTDEF_STACK[-1].append(
            (CF_ATTR_FIRST_DEF, (id(owner), slot_name))
        )


def _pyir_update_cf_attr_first_def_on_write(owner: Any, slot_name: Any) -> None:
    """A later write outside staged CF drops the record; a write outside the
    recorded subtree re-anchors it at the wider arm path."""
    if owner is None or slot_name is None or not _PYIR_CF_ATTR_FIRST_DEFS:
        return
    key = (id(owner), slot_name)
    rec = _PYIR_CF_ATTR_FIRST_DEFS.get(key)
    if rec is None or _pyir_gen_events_suppressed():
        return
    if not is_inside_staged_cf():
        _PYIR_CF_ATTR_FIRST_DEFS.pop(key, None)
        return
    cur_arms = _pyir_current_region_arm_path()
    if not cur_arms:
        _PYIR_CF_ATTR_FIRST_DEFS.pop(key, None)
        return
    if not _pyir_arm_path_covers(rec["arms"], cur_arms):
        rec["arms"] = cur_arms


def _pyir_check_cf_attr_first_def_read(owner: Any, slot_name: Any) -> None:
    """Read choke: raise when the read site is outside the first-def's arm-path
    subtree (sibling arm or post-region), where Python never bound the attr."""
    if owner is None or slot_name is None or not _PYIR_CF_ATTR_FIRST_DEFS:
        return
    rec = _PYIR_CF_ATTR_FIRST_DEFS.get((id(owner), slot_name))
    if rec is None or _pyir_gen_events_suppressed():
        return
    if is_inside_constexpr_loop():
        return
    if _pyir_arm_path_covers(rec["arms"], _pyir_current_region_arm_path()):
        return
    detail = ""
    def_file, def_line = rec["site"]
    if def_file:
        detail = f" (only set at {def_file}:{def_line}, inside a branch that does not cover this read)"
    raise DSLUserCodeError(DiagId.SCOPE_READ_NEVER_SET, detail=detail)


def _attach_mutable_ref(obj: object, mv: "MutableValue", context: str) -> None:
    """Attach *mv* as ``_mutable_ref`` on *obj*; logs (never raises) when the
    object does not accept arbitrary attributes."""
    try:
        _pyir_setattr_raw(obj, "_mutable_ref", mv)
    except (AttributeError, TypeError):
        log().info(
            "could not attach _mutable_ref to %s (%s)",
            type(obj).__name__,
            context,
        )


def _pyir_adopt_live_place_cell(owner: Any, slot_name: Any, value: Any) -> Any:
    """Bind *value* at a live place cell: store into it, re-alias ``_mutable_ref``
    and the id tier to it. Never mints cells; steps aside on a type change."""
    if owner is None or slot_name is None or value is None:
        return value
    try:
        if not (_is_staged_value(value) and _can_carry_leaf_ref(value)):
            return value
        place = _corrected_place_for(owner, slot_name)
        if place is None:
            return value
        place_mv = _PLACE_REGISTRY.get(place)
        if place_mv is None or place_mv._ref is None:
            return value
        if not place_mv._is_ref_accessible():
            return value
        if getattr(value, "_mutable_ref", None) is place_mv:
            return value
        if _pyir_ref_pointee_type_changed(place_mv._ref, value):
            return value
        # A backing trapped in an already-closed region cannot be stored at the
        # current IP (conservative skip).
        if _raw_backing_ir_value(value) is not None and not _value_dominates_current_ip(
            value
        ):
            return value
        place_mv.store(value)
        # Clear any foreign-cell load tag so the next auto-load reads the place
        # cell, not the foreign cell's SSA.
        try:
            _pyir_setattr_raw(value, _PYIR_LOAD_VERSION_ATTR, None)
        except (AttributeError, TypeError):
            pass
        _attach_mutable_ref(value, place_mv, f"place-cell binding '{slot_name}'")
        _set_slot_mv(owner, slot_name, place_mv)
    except Exception:
        return value
    return value


def _pyir_place_is_index_sibling(route_place: Any, place: Any) -> bool:
    """True when the two ledger places name elements of the SAME parent path
    and differ only in the final integer index -- the positional-shift
    signature of a shrinking/growing restructure.  A whole-value place vs an
    element place ('t' vs 't[0]') is NOT a sibling pair (LAW-2: re-aliasing
    across it would steal another live binding's route)."""
    if (
        not isinstance(route_place, tuple)
        or not isinstance(place, tuple)
        or len(route_place) != len(place)
        or route_place == place
    ):
        return False
    diff = [i for i in range(len(place)) if route_place[i] != place[i]]
    if len(diff) != 1:
        return False
    a, b = route_place[diff[0]], place[diff[0]]
    if isinstance(a, _PlaceSeg) and isinstance(b, _PlaceSeg):
        return (
            a.base == b.base
            and len(a.keys) == len(b.keys)
            and bool(a.keys)
            and a.keys[:-1] == b.keys[:-1]
            and isinstance(a.keys[-1], int)
            and isinstance(b.keys[-1], int)
        )
    if isinstance(a, str) and isinstance(b, str):
        base_a, sep_a, idx_a = a.rpartition("[")
        base_b, sep_b, idx_b = b.rpartition("[")
        return (
            bool(sep_a)
            and bool(sep_b)
            and base_a == base_b
            and idx_a.endswith("]")
            and idx_b.endswith("]")
            and idx_a[:-1].isdigit()
            and idx_b[:-1].isdigit()
        )
    return False


def _pyir_route_restructured_tuple_leaves(
    target_name: Any, owner: Any, slot_name: Any, new_value: Any
) -> None:
    """Generation coherence for a restructuring rebind: each element of the
    fresh tuple stores through its access path's still-live cell, so a
    post-join read of ``name[i]`` resolves the fresh generation.  A live cell
    the write cannot advance is marked superseded-unadvanced; serving it to a
    later place-routed read refuses instead of reading the old generation."""
    for i, elem in enumerate(new_value):
        elem_name = f"{target_name}[{i}]"
        elem_slot = _place_seg_child(slot_name, i) if slot_name is not None else None
        if isinstance(elem, (tuple, list)):
            _pyir_route_restructured_tuple_leaves(
                elem_name, owner, elem_slot if owner is not None else None, elem
            )
            continue
        try:
            if owner is not None and elem_slot is not None:
                mv = _get_slot_mv(owner, elem_slot)
                place = _make_slot_key(None, owner, elem_slot)
            else:
                mv = _get_slot_mv(None, elem_name)
                place = _make_slot_key(elem_name, None, None)
        except Exception:
            continue
        if mv is None or mv._ref is None or not mv._is_ref_accessible():
            log().info(
                "[pyir_assign] '%s' restructure write-through: no live row",
                elem_name,
            )
            continue
        can_store = (
            _is_staged_value(elem)
            and _can_carry_leaf_ref(elem)
            # LAW-1 position rule: a literal-backed value re-materializes at
            # the store position, so only SSA-backed values need dominance.
            and (_is_literal_backed(elem) or _value_dominates_current_ip(elem))
        )
        if can_store:
            if _is_literal_backed(elem):
                # Type-probe on a rebuilt twin: ``ir_value()`` on the element
                # itself would demote it from literal- to SSA-backed.
                try:
                    probe_raw = type(elem)(elem.value).ir_value()
                    can_store = probe_raw.type == mv._ref.type.pointee
                except Exception:
                    can_store = False
            else:
                can_store = not _pyir_ref_pointee_type_changed(mv._ref, elem)
        if can_store:
            mv.store(elem)
            if place is not None:
                _PYIR_SUPERSEDED_PLACE_ROWS.pop(place, None)
            # An index-shifted survivor still routes to its OLD sibling row,
            # which this same pass may overwrite with a higher index's leaf;
            # re-alias it to the row it now lives at (mirroring
            # _pyir_adopt_live_place_cell's binding step).  Only the
            # index-sibling shift re-aliases: a route to any other place is
            # another live binding's (LAW-2) and keeps it.
            route = getattr(elem, "_mutable_ref", None)
            if (
                route is not None
                and route is not mv
                and _pyir_place_is_index_sibling(getattr(route, "_place", None), place)
            ):
                try:
                    _pyir_setattr_raw(elem, _PYIR_LOAD_VERSION_ATTR, None)
                except (AttributeError, TypeError):
                    pass
                _attach_mutable_ref(elem, mv, f"restructure shift '{elem_name}'")
            log().info(
                "[pyir_assign] '%s' restructure write-through: stored", elem_name
            )
        elif place is not None:
            _PYIR_SUPERSEDED_PLACE_ROWS[place] = mv._store_version
            log().info(
                "[pyir_assign] '%s' restructure write-through: cell not "
                "advanceable → superseded mark",
                elem_name,
            )


def _pyir_refuse_superseded_row_serve(mv: Any, target_name: Any) -> None:
    """The reroute guard: a place-routed read about to be served by a row whose
    cell a restructuring rebind could NOT advance would read the superseded
    generation -- refuse loudly.  Any tracked store since the mark (a differing
    store version) is the new generation's write and discharges the mark."""
    if not _PYIR_SUPERSEDED_PLACE_ROWS:
        return
    place = getattr(mv, "_place", None)
    if place is None:
        return
    marked_version = _PYIR_SUPERSEDED_PLACE_ROWS.get(place)
    if marked_version is None:
        return
    if mv._store_version != marked_version:
        _PYIR_SUPERSEDED_PLACE_ROWS.pop(place, None)
        return
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.UNOBSERVED_WRITE_POSITION_UNKNOWN,
        filename=filename,
        lineno=lineno,
        var=str(target_name),
    )


def _fresh_wrapper(dsl_value: Any) -> Any:
    """Return a fresh DSL wrapper sharing *dsl_value*'s backing (distinct object for
    the wrapper-keyed ref cache, same ``.value``); unchanged on any failure."""
    # Literal-backed Numeric: rebuild from the raw Python scalar so the wrapper stays literal-backed;
    # ``ir_value()`` would emit an eager ``arith.constant``, demoting it to SSA-backed.
    if _is_literal_backed(dsl_value):
        try:
            return type(dsl_value)(dsl_value.value)
        except Exception:
            return dsl_value

    try:
        ir_val = dsl_value.ir_value()
    except Exception:
        return dsl_value

    # Rebuild through the ONE reconstruction funnel (the copy is a best-effort
    # convenience, not a read: an unrebuildable value passes through unchanged).
    try:
        fresh = _wrap_ir_like(dsl_value, ir_val)
    except DSLUserCodeError:
        return dsl_value

    # Re-point the rebuilt wrapper's ``.value`` at the original ``ir.Value`` so a
    # no-op cast keeps ``b.value is a.value``; SSA-backed scalars only.
    src_value = getattr(dsl_value, "value", None)
    if (
        fresh is not dsl_value
        and isinstance(src_value, ir.Value)
        and isinstance(getattr(fresh, "value", None), ir.Value)
    ):
        try:
            _pyir_setattr_raw(fresh, "value", src_value)
        except (AttributeError, TypeError):
            pass
    # Mark a local-owned wrapper so ``pyir_assign`` can preserve Python ``is``
    # identity instead of re-wrapping a compound handed back by a no-op op.
    if fresh is not dsl_value:
        try:
            _pyir_setattr_raw(fresh, "_pyir_local_wrapper", True)
        except (AttributeError, TypeError):
            pass
    return fresh


def _same_ir_value(a: "ir.Value | None", b: "ir.Value | None") -> bool:
    """Whether *a* and *b* are the same SSA value, via the base ``ir.Value.__eq__``
    (a subclass ``==`` may emit IR). Conservative: any error -> ``False``."""
    if a is None or b is None:
        return False
    try:
        return bool(ir.Value.__eq__(a, b))
    except Exception:
        return a is b


def _raw_backing_ir_value(arg: Any) -> "ir.Value | None":
    """Return *arg*'s already-baked backing ``ir.Value`` structurally, never via
    ``ir_value()`` (which re-enters the auto-load path); ``None`` when unavailable."""
    if isinstance(arg, ir.Value):
        return arg
    inner = getattr(arg, "value", None)
    if isinstance(inner, ir.Value):
        return inner
    return None


def _as_arith_capable_scalar_leaf(value: Any) -> Any:
    """Wrap a bare SCALAR int/float ``ir.Value`` in ``ArithValue`` so downstream
    staged arithmetic works; opaque leaves and non-``ir.Value``s pass through."""
    # Local import: ``base_dsl.typing`` imports ``_WatchedM`` from this module, so a
    # module-level import of ``ArithValue`` would be circular.
    from .._mlir_helpers.arith import ArithValue

    if not isinstance(value, ir.Value) or isinstance(value, ArithValue):
        return value
    try:
        ty = value.type
        if isinstance(ty, (ir.IntegerType, ir.FloatType)):
            return ArithValue(value)
    except Exception:
        pass
    return value


def _value_dominates_current_ip(value: Any) -> bool:
    """True if *value*'s backing ``ir.Value`` dominates the current insertion point
    (C++ binding). Conservative: ``False`` on any error, so callers re-load."""
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


def _ref_literal_init_const(ref: "ir.Value") -> Any:
    """Return the literal a ``pyir.ref`` was GENUINELY seeded from, or
    ``_NO_CONST_VALUE`` (a placeholder/poison init is not a seed). C++-backed."""
    try:
        if pyir is None:
            return _NO_CONST_VALUE
        result = pyir.ref_literal_init(ref)
    except Exception:
        return _NO_CONST_VALUE
    return _NO_CONST_VALUE if result is None else result


def _op_is_inside_op(op: "ir.Operation", outer_op: "ir.Operation") -> bool:
    """True if *op* is nested (at any depth) inside *outer_op*, via the
    ``Operation.parent`` chain only. Conservative: any error -> ``False``."""
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


def _block_strictly_inside(inner: "ir.Block", outer: "ir.Block") -> bool:
    """True if *inner* block is nested strictly inside *outer* block (owning-op
    containment, blocks differ). Conservative: False."""
    try:
        if inner is None or outer is None or inner == outer:
            return False
        inner_op = inner.owner
        outer_op = outer.owner
        if inner_op is None or outer_op is None:
            return False
        return _op_is_inside_op(
            getattr(inner_op, "operation", inner_op),
            getattr(outer_op, "operation", outer_op),
        )
    except Exception:
        return False


def _block_inside_op(block: "ir.Block", op: Any) -> bool:
    """True if *block* is one of *op*'s own blocks or nested inside them.
    Conservative: False."""
    try:
        if block is None or op is None:
            return False
        owner = block.owner
        if owner is None:
            return False
        owner_op = getattr(owner, "operation", owner)
        target_op = getattr(op, "operation", op)
        if owner_op == target_op:
            return True
        return _op_is_inside_op(owner_op, target_op)
    except Exception:
        return False


def _pyir_write_in_if_arms_of(inner: "ir.Block", outer: "ir.Block") -> bool:
    """True when walking up from *inner* to *outer* crosses ONLY ``scf.if``
    regions: the write sits in conditional arms of the slot's own birth
    region, with no loop in between to multiply it. Conservative: False."""
    try:
        if inner is None or outer is None or inner == outer:
            return False
        target = outer.owner
        target = getattr(target, "operation", target)
        cur = inner.owner
        cur = getattr(cur, "operation", cur)
        for _ in range(64):
            if cur is None or target is None:
                return False
            if cur == target:
                return True
            if cur.name != "scf.if":
                return False
            parent = cur.parent
            if parent is None:
                return False
            cur = getattr(parent, "operation", parent)
        return False
    except Exception:
        return False


def _pyir_check_arm_local_escape(slot_key: Any) -> None:
    """Refuse a consumption of an arm-locally mutated meta slot from OUTSIDE
    its arm: the write ran on one traced path only, so the folded value is
    path-dependent at run time."""
    entry = _PYIR_ARM_LOCAL_META_WRITES.get(slot_key)
    if entry is None:
        return
    arm_block, w_file, w_line = entry
    try:
        cur = ir.InsertionPoint.current.block
    except Exception:
        return
    if cur == arm_block or _block_strictly_inside(cur, arm_block):
        return
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.PHASE_ARM_LOCAL_CONSTANT_ESCAPES,
        filename=filename,
        lineno=lineno,
        var=str(slot_key[-1]) if isinstance(slot_key, tuple) else str(slot_key),
        write_file=w_file,
        write_line=w_line,
    )


def _ir_value_defined_inside_op(value: "ir.Value", outer_op: "ir.Operation") -> bool:
    """True if *value* is defined (at any depth) inside *outer_op*.
    Conservative: False (treats the value as outside)."""
    try:
        owner = value.owner
        if isinstance(owner, ir.Block):
            parent = owner.owner  # op owning the block
            if parent is None:
                return False
            return _op_is_inside_op(getattr(parent, "operation", parent), outer_op)
        def_op = getattr(owner, "operation", owner)
        return _op_is_inside_op(def_op, outer_op)
    except Exception:
        return False


def _op_has_enclosing_loop(op: "ir.Operation") -> bool:
    """True if *op* has an enclosing ``scf.for``/``scf.while`` ancestor (gates how
    the ``scf.if`` forward-carry treats mutated leaves). Conservative: False."""
    try:
        cur = getattr(op, "operation", op)
        # Skip the op itself; only ancestors count as "enclosing".
        parent = cur.parent
        while parent is not None:
            pop = getattr(parent, "operation", parent)
            if getattr(pop, "name", None) in ("scf.for", "scf.while"):
                return True
            parent = pop.parent
        return False
    except Exception:
        return False


def _innermost_enclosing_loop_op_at_ip() -> "ir.Operation | None":
    """Innermost ``scf.for``/``scf.while`` op enclosing the current insertion
    point, or ``None``; bounded upward walk stopping at function/module boundaries."""
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
    """Chain of loop-free ``scf.if`` ancestors of the current insertion point,
    innermost outward, stopping at the first loop or function/module boundary."""
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


def _region_block_of_if_containing_op(
    start_op: "ir.Operation", if_op: "ir.Operation"
) -> "ir.Block | None":
    """The *if_op* region block (then/else) that transitively contains *start_op*,
    via the ``Operation.parent`` walk. Conservative: ``None``."""
    try:
        target = getattr(if_op, "operation", if_op)
        cur = getattr(start_op, "operation", start_op)
        while cur is not None:
            parent = cur.parent
            if parent is None:
                return None
            parent = getattr(parent, "operation", parent)
            if parent == target:
                return cur.block
            cur = parent
        return None
    except Exception:
        return None


def _meta_use_in_sibling_if_region(
    baked_uses: "list[ir.Value]", if_op: "ir.Operation"
) -> bool:
    """True if a use in *baked_uses* lives in a DIFFERENT branch of *if_op* than the
    current IP (sibling-branch re-trace, not a carry); any error -> ``False``."""
    if pyir is None:
        return False
    try:
        cur_block = ir.InsertionPoint.current.block
    except Exception:
        return False
    if cur_block is None:
        return False
    if_op = getattr(if_op, "operation", if_op)
    # Reduce the current IP to its own branch block under ``if_op``: an op directly in ``cur_block``
    # reduces to ``cur_block`` itself; otherwise climb to the region block whose parent op is ``if_op``.
    cur_branch = None
    try:
        cb_owner = getattr(cur_block.owner, "operation", cur_block.owner)
        if cb_owner == if_op:
            cur_branch = cur_block
        else:
            cur_branch = _region_block_of_if_containing_op(cb_owner, if_op)
    except Exception:
        cur_branch = None
    if cur_branch is None:
        return False
    for use in baked_uses:
        try:
            if isinstance(getattr(use, "owner", None), ir.Block):
                continue  # block argument: no defining op
            def_op = getattr(use.owner, "operation", use.owner)
            use_branch = _region_block_of_if_containing_op(def_op, if_op)
            if use_branch is None:
                continue  # baked outside this if -> not a sibling rebake
            if use_branch != cur_branch:
                return True
        except Exception:
            continue
    return False


def _safe_instance_dict(obj: Any) -> "dict | None":
    """*obj*'s instance ``__dict__`` or ``None``, read via
    ``object.__getattribute__`` so an overloaded attribute access cannot abort the caller."""
    try:
        d = object.__getattribute__(obj, "__dict__")
    except Exception:
        return None
    return d if isinstance(d, dict) else None


# Per-class cache of declared ``__slots__`` member descriptors.  Classes are
# module-lifetime objects, so a plain dict keyed by the class is safe.
_SLOTS_MEMBERS_CACHE: "dict[type, tuple[tuple[str, Any], ...]]" = {}


def _slots_member_descriptors(cls: type) -> "tuple[tuple[str, Any], ...]":
    """(name, descriptor) for every ``__slots__`` entry across *cls*'s MRO (cached);
    pseudo-slots, dunders and shadowed names are skipped."""
    cached = _SLOTS_MEMBERS_CACHE.get(cls)
    if cached is not None:
        return cached
    members: "list[tuple[str, Any]]" = []
    seen: "set[str]" = set()
    for klass in getattr(cls, "__mro__", ()):
        raw = klass.__dict__.get("__slots__")
        if raw is None:
            continue
        if isinstance(raw, str):
            raw = (raw,)
        try:
            names = list(raw)
        except TypeError:
            continue
        for name in names:
            if not isinstance(name, str) or name.startswith("__") or name in seen:
                continue
            desc = klass.__dict__.get(name)
            if desc is None or not hasattr(desc, "__get__"):
                continue
            seen.add(name)
            members.append((name, desc))
    result = tuple(members)
    _SLOTS_MEMBERS_CACHE[cls] = result
    return result


def _has_instance_storage(obj: Any) -> bool:
    """True when *obj* has per-instance attribute storage: a readable instance
    ``__dict__`` OR declared ``__slots__`` members."""
    if _safe_instance_dict(obj) is not None:
        return True
    return bool(_slots_member_descriptors(type(obj)))


def _instance_storage_items(obj: Any) -> "dict[str, Any] | None":
    """``{name: value}`` of *obj*'s instance storage (``__dict__`` entries plus
    SET ``__slots__`` fields, unset slots omitted), or ``None`` when it has none."""
    d = _safe_instance_dict(obj)
    members = _slots_member_descriptors(type(obj))
    if not members:
        return d
    items: "dict[str, Any]" = dict(d) if d else {}
    for name, desc in members:
        if name in items:
            continue
        try:
            items[name] = desc.__get__(obj, type(obj))
        except Exception:
            continue  # unset slot (AttributeError) / exotic descriptor
    return items


# MutableValue -- internal bookkeeping for pyir.ref / pyir.load / pyir.store


class MutableValue:
    """Wraps a single leaf DSL value and holds the ``pyir.ref`` handle; never
    exposed to user code and never participates in operator dispatch."""

    __slots__ = (
        "_value",
        "_type",
        "_ref",
        "_ref_context_id",
        "_load_version",
        "_store_version",
        "_place",
        "_last_choke_region_epoch",
    )

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
        # Bumped on every load()/store(); used to dedup redundant auto-loads. A value
        # whose ``_pyir_load_version`` equals the current one is the freshest load.
        self._load_version: int = 0
        # Bumped ONLY on store(); the superseded-generation detector fires only
        # when the shared cell demonstrably advanced past a recorded stamp.
        self._store_version: int = 0
        # The ledger place this cell is registered under (``None`` if
        # unregistered); a type-transition re-mint re-books the place through it.
        self._place: Any = None
        # Region-epoch at this cell's last store()/load() choke; equality with
        # the current epoch proves a straight-line interval since that event.
        self._last_choke_region_epoch: "int | None" = None

    def take_reference(self, *, remint: bool = False) -> None:
        """Create the ``pyir.ref`` for the current value -- exactly once per trace;
        re-minting an accessible cell is an internal error unless *remint*."""
        if self._ref is not None and not remint and self._is_ref_accessible():
            raise DSLRuntimeError(
                "PyIR internal error: re-minting a pyir.ref while the existing "
                "cell is still accessible (one-cell-per-place invariant)."
            )
        # Mint from the value's OWN raw backing: minting captures this program
        # point, never a reload of some attached cell via ``ir_value()``.
        ir_val = _raw_backing_ir_value(self._value)
        if ir_val is None:
            ir_val = self._value.ir_value()
        self._ref = pyir.ref(ir_val)
        self._ref_context_id = id(ir.Context.current)

    def _is_ref_accessible(self) -> bool:
        """True if the existing ref is accessible from the current insertion
        point (same or non-isolated ancestor region)."""
        if self._ref is None:
            return False
        if self._ref_context_id != id(ir.Context.current):
            return False
        current_block = ir.InsertionPoint.current.block
        return bool(pyir.value_dominates_ip(self._ref, current_block, None))

    def _reconstruct(self, loaded_ir: Any) -> Any:
        """Reconstruct a DSL value from a loaded MLIR value, preserving compound
        wrapper metadata (dtype/shape) via the ``_wrap_ir_like`` template."""
        # ``_wrap_ir_like`` uses ``self._value`` as a template, so compound wrappers
        # (e.g. TensorSSA) are rebuilt with full state.
        return _wrap_ir_like(self._value, loaded_ir)

    def load(self) -> Any:
        """Emit ``pyir.load`` and return a fresh, load-version-tagged DSL value.
        ``_mutable_ref`` is deliberately not attached here (callers decide)."""
        assert self._ref is not None, (
            "MutableValue.load: no ref -- call take_reference() first"
        )
        loaded_ir = pyir.load(self._ref)
        self._load_version += 1
        # Record the region-epoch of this choke event (F-GEN): equality with a
        # later epoch proves no staged-region boundary was crossed in between.
        self._last_choke_region_epoch = _pyir_current_region_epoch()
        loaded = self._reconstruct(loaded_ir)
        try:
            _tag_load(
                loaded,
                self._load_version,
                current_staged_cf_depth(),
                _ref_write_epoch(self._ref),
            )
        except (AttributeError, TypeError):
            pass  # value type doesn't accept attrs — no dedup, fine.
        return loaded

    def store(self, new_value: Any) -> None:
        """Emit ``pyir.store`` of *new_value* into the ref; a pointee-type change
        re-mints the cell at the new type and re-books its place row."""
        assert self._ref is not None, (
            "MutableValue.store: no ref -- call take_reference() first"
        )
        # ``self._value`` must be set BEFORE ``take_reference`` (which mints from
        # it), else the re-mint would use the stale type.
        if _pyir_ref_pointee_type_changed(self._ref, new_value):
            self._value = new_value
            self.take_reference(remint=True)
            _pyir_rebook_place_cell(self)
        # Store the value's OWN raw backing: a store captures ITS program point,
        # never an ``ir_value()`` reload of an attached or foreign cell.
        raw = _raw_backing_ir_value(new_value)
        if raw is None:
            raw = new_value.ir_value()
        _place = getattr(self, "_place", None)
        _pyir_emit_store(
            raw,
            self._ref,
            var=_place[-1] if isinstance(_place, tuple) and _place else None,
        )
        self._value = new_value
        # A place dual-booked as a bare-ref row advances its template half too,
        # so a row-keyed read reconstructs the class current at this store.
        if self._place is not None and self._place in _slot_refs:
            _pyir_record_slot_template(self._place, new_value)
        # Invalidate previously-loaded values: subsequent uses must reload.
        self._load_version += 1
        self._store_version += 1
        # Record the region-epoch of this choke event (F-GEN): equality with a
        # later epoch proves no staged-region boundary was crossed in between.
        self._last_choke_region_epoch = _pyir_current_region_epoch()
        # Stamp write-epoch + staged-CF depth + region-entry clock so a later
        # read can judge currency; the load-version tag is NOT stamped
        # (presence means "from a pyir.load").
        try:
            object.__setattr__(
                new_value, _PYIR_REF_EPOCH_ATTR, _ref_write_epoch(self._ref)
            )
            object.__setattr__(
                new_value, _PYIR_LOAD_DEPTH_ATTR, current_staged_cf_depth()
            )
            object.__setattr__(
                new_value, _PYIR_REGION_ENTRY_ATTR, _pyir_region_entry_clock()
            )
            _pyir_note_holder_write(new_value)  # one stamp covers the cluster
        except (AttributeError, TypeError):
            pass  # value type doesn't accept attrs -- no staleness tracking.

    @property
    def ref(self) -> ir.Value | None:
        """The raw ``pyir.ref`` SSA value (or ``None``)."""
        return self._ref

    def __repr__(self) -> str:
        return f"MutableValue({self._value!r})"


def _ref_dominates_whole_function(mv: "MutableValue") -> bool:
    """True if *mv*'s ref is defined in the function entry block (only such a ref
    may be published for post-region loads). Conservative: False."""
    if pyir is None:
        return False
    ref = getattr(mv, "_ref", None)
    if ref is None:
        return False
    try:
        entry_block = _get_function_entry_block()
        if entry_block is None:
            return False
        defining_op = ref.owner  # OpResult -> defining op (pyir.ref is an op)
        op = getattr(defining_op, "operation", defining_op)
        return op.block == entry_block
    except Exception:
        return False


def _get_instance_attrs(obj: object) -> list[str]:
    """Instance attribute names from instance storage (``__dict__`` plus set
    ``__slots__``); skips dunders, never class-level properties/methods."""
    items = _instance_storage_items(obj)
    if items is None:
        return []
    return [name for name in items if not name.startswith("__")]


# Per-class cache of the value-tree protocol judgment. The protocol is
# class-declared (both methods live on the type; instance storage never carries
# them — grep-gated), so a class verdict is stable. Classes with dynamic
# attribute hooks keep the exact per-instance check (bucket "instance").
_VT_PROTOCOL_CLASS_CACHE: "dict[type, object]" = {}


def _vt_protocol_class_bucket(cls: type, obj: object) -> "bool | str":
    """Classify *cls* for the protocol check: ``True`` (declares it),
    ``False`` (cannot provide it), or ``"instance"`` (hooks; per-instance)."""
    declared = any(
        "__extract_mlir_values__" in k.__dict__ for k in cls.__mro__
    ) and any("__new_from_mlir_values__" in k.__dict__ for k in cls.__mro__)
    if declared:
        # Confirm through the instance view once (descriptor shape).
        if callable(getattr(obj, "__extract_mlir_values__", None)) and callable(
            getattr(obj, "__new_from_mlir_values__", None)
        ):
            return True
        return "instance"
    # Undeclared: a dynamic hook could still fabricate the methods.
    if (
        type(cls) is type
        and cls.__getattribute__ is object.__getattribute__
        and getattr(cls, "__getattr__", None) is None
    ):
        return False
    return "instance"


def _implements_dynamic_expression(obj: object) -> bool:
    """True if *obj* exposes the DSL ``DynamicExpression`` protocol; its
    non-extracted fields are constant context that must not be carried.

    Declaring BOTH dunders is the documented public opt-in (typing.py): only
    such classes are ever reconstructed via ``__new_from_mlir_values__``."""
    cls = type(obj)
    bucket = _VT_PROTOCOL_CLASS_CACHE.get(cls)
    if bucket is None:
        bucket = _VT_PROTOCOL_CLASS_CACHE[cls] = _vt_protocol_class_bucket(cls, obj)
    if bucket is True:
        return True
    if bucket is False:
        return False
    return callable(getattr(obj, "__extract_mlir_values__", None)) and callable(
        getattr(obj, "__new_from_mlir_values__", None)
    )


def _rebuild_tuple_like(template: tuple, elements: Any) -> tuple:
    """Rebuild a tuple-shaped value PRESERVING the template's subtype; an
    unrebuildable subclass refuses loudly rather than degrade to plain tuple."""
    elems = tuple(elements)
    make = getattr(type(template), "_make", None)
    if make is not None and hasattr(template, "_fields"):
        try:
            return make(elems)
        except Exception as exc:
            raise DSLUserCodeError(
                DiagId.CONTAINER_TUPLE_SUBCLASS_NOT_REBUILDABLE,
                type=type(template).__name__,
                detail=f" (rebuilding {len(elems)} item(s) raised {exc!r})",
            ) from exc
    if type(template) is tuple:
        return elems
    # Extra per-instance state (an instance __dict__ with entries) cannot be
    # reproduced from the elements alone -- refuse rather than drop it.
    _extra_state = getattr(template, "__dict__", None)
    if _extra_state:
        raise DSLUserCodeError(
            DiagId.CONTAINER_TUPLE_SUBCLASS_NOT_REBUILDABLE,
            type=type(template).__name__,
            detail=" (it carries extra per-instance attributes)",
        )
    try:
        return type(template)(elems)
    except Exception as exc:
        raise DSLUserCodeError(
            DiagId.CONTAINER_TUPLE_SUBCLASS_NOT_REBUILDABLE,
            type=type(template).__name__,
            detail=f" (its constructor rejected the item iterable: {exc!r})",
        ) from exc


def _is_compound_single_leaf(value: object) -> bool:
    """True if *value* is ref-supported yet compound (holds a staged semantic
    sub-field): unsupported as a field of a whole-replaced container."""
    if not (_is_staged_value(value) and _can_create_ref(value)):
        return False
    if not _has_instance_storage(value):
        return False
    for attr_name in _get_instance_attrs(value):
        # Skip the scalar's own MLIR leaf (``value``) and PyIR plumbing attrs;
        # only a SEMANTIC staged sub-field makes the value compound.
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
    """True if *value* needs no further decomposition: a meta primitive or a
    ref-trackable staged scalar (compound single-leaf values excluded)."""
    if value is None or isinstance(value, (int, float, bool, str, bytes)):
        return True
    if (
        _is_staged_value(value)
        and _can_carry_leaf_ref(value)
        and not _is_compound_single_leaf(value)
    ):
        return True
    return False


def _check_tuple_decomposable(
    t: tuple,
    _visited: set[int],
) -> tuple[bool, bool]:
    """Check if all elements of a tuple are decomposable; returns ``(ok, has_staged)``."""
    has_staged = False
    for elem in t:
        if _is_leaf_decomposable(elem):
            if _is_staged_value(elem) and _can_carry_leaf_ref(elem):
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
        if _has_instance_storage(elem) and _check_all_fields_decomposable(
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
    """True if every instance attribute is a meta primitive, a ref-compatible
    staged leaf, or a tuple/nested compound of same; at least one staged."""
    obj_id = id(obj)
    if obj_id in _visited:
        return False
    _visited.add(obj_id)

    if not _has_instance_storage(obj):
        return False

    attrs = _get_instance_attrs(obj)
    if not attrs:
        return False

    has_any_staged = False
    for attr_name in attrs:
        value = getattr(obj, attr_name)

        if _is_leaf_decomposable(value):
            if _is_staged_value(value) and _can_carry_leaf_ref(value):
                has_any_staged = True
            continue

        if isinstance(value, tuple):
            ok, found_staged = _check_tuple_decomposable(value, _visited)
            if not ok:
                return False
            has_any_staged = has_any_staged or found_staged
            continue

        if isinstance(value, dict):
            # A dict field decomposes per entry when every value is a decomposable
            # leaf (the tuple rule's dict analogue); nested containers refuse.
            _dict_staged = False
            for _dv in list(dict.values(value)):
                if _is_leaf_decomposable(_dv) and not isinstance(
                    _dv, (tuple, list, dict)
                ):
                    if _is_staged_value(_dv) and _can_carry_leaf_ref(_dv):
                        _dict_staged = True
                    continue
                return False
            has_any_staged = has_any_staged or _dict_staged
            continue

        # A ref-supported COMPOUND single-leaf field is not decomposable (its
        # per-field ref does not survive loop iter_args): refuse loudly instead.
        if _is_staged_value(value):
            return False

        if _has_instance_storage(value) and _check_all_fields_decomposable(
            value, _visited=_visited
        ):
            has_any_staged = True
            continue

        if _implements_dynamic_expression(obj):
            # *obj* declares its carried state via the value-tree protocol; a field outside it
            # (e.g. a pipeline/barrier ref) is constant context and does not block decomposition.
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


# pyir_assign / pyir_read — AST-inserted hooks


def _pyir_assign_simple(owner: Any, key: Any, value: Any) -> Any:
    """Register a slot in ``_SLOT_REGISTRY`` and return *value* unchanged;
    emits no IR, so it is usable without an active MLIR context."""
    _pyir_register_candidate_holder(owner)
    _pyir_register_candidate_holder(value)
    slot_id = _make_slot_id(owner, key)
    mv = _SLOT_REGISTRY.get(slot_id)
    if mv is None:
        # Placeholder MutableValue (no ``pyir.ref`` yet -- callers may have no MLIR context); it gives the
        # registry the right identity and is upgraded when staged CF actually needs a ref.
        mv = MutableValue.__new__(MutableValue)
        _pyir_setattr_raw(mv, "_value", value)
        _pyir_setattr_raw(mv, "_type", type(value))
        _pyir_setattr_raw(mv, "_ref", None)
        _pyir_setattr_raw(mv, "_ref_context_id", None)
        _pyir_setattr_raw(mv, "_load_version", 0)
        _pyir_setattr_raw(mv, "_store_version", 0)
        _pyir_setattr_raw(mv, "_last_choke_region_epoch", None)
        _SLOT_REGISTRY[slot_id] = mv
    return value


def _pyir_record_fresh_object_leaf_first_defs(ctor: Any, obj: Any) -> None:
    """Record in-region first-def facts for the fields of a directly-constructed
    *obj*: the binding position becomes each field's birth block (F-BIRTHPOS)."""
    if pyir is None or is_inside_constexpr_loop():
        return
    if not (isinstance(ctor, type) and type(ctor) is type):
        return
    # Freshness: a plain-__new__ class, or exactly the stdlib SimpleNamespace
    # (its distinct C-slot __new__ allocates fresh state all the same).
    if (
        ctor.__new__ is not object.__new__ and ctor is not types.SimpleNamespace
    ) or type(obj) is not ctor:
        return
    if _is_staged_value(obj):
        return
    try:
        block = ir.InsertionPoint.current.block
    except Exception:
        return
    depth = current_staged_cf_depth()
    _record_fresh_leaf_first_defs_walk(obj, block, depth, {id(obj)})


def _subobject_is_ctor_private(parent: Any, value: Any) -> bool:
    """Whether a ctor-born *parent*'s field holds a PRIVATE fresh sub-object:
    a plain-``__new__`` instance whose only referrer is the parent's own
    ``__dict__``.  Such a sub-object is reborn with the parent on every
    execution of the binding, so its leaves inherit the parent's birth facts
    (F-BIRTHPOS).  Any other referrer may be an outer alias smuggled into the
    ctor (``self.sub = OUTER``) whose state genuinely carries -- do not
    descend; the pre-existing conservative carry stays.

    Design tradeoff: this is an after-the-fact ``gc.get_referrers`` heap scan
    (trace-time only, behind cheap short-circuit gates) because the binds
    that decide privacy happen in plain ``__init__`` bodies and module code,
    which never reach the assign choke -- there is no bind-time record to
    consult.  If ctor-internal binds ever become choke-visible, replace this
    with bind-time ownership bookkeeping."""
    if _is_staged_value(value):
        return False
    cls = type(value)
    if not (isinstance(cls, type) and cls.__new__ is object.__new__):
        return False
    if _implements_dynamic_expression(value):
        return False
    # A ``__slots__`` parent has no ``__dict__``: its hold then shows up as
    # the parent INSTANCE itself among the referrers, which the loop below
    # accepts, so a missing dict is not disqualifying.
    parent_dict = getattr(parent, "__dict__", None)
    # No instance state (dict or set slots) means no leaves at any depth:
    # skip the heap scan.  Uses the storage view the walker enumerates.
    if not _instance_storage_items(value):
        return False
    # The trace's own keepalive registries hold traced values against GC;
    # they are bookkeeping, not user aliases, so they don't disqualify
    # (every STRONG-holding keepalive self-registers in
    # ``_PYIR_TRACE_KEEPALIVES``; weakref-valued tables such as
    # ``_OWNER_KEEPALIVE`` never appear among referrers at all).
    # The parent's hold shows up as its ``__dict__`` or as the parent
    # INSTANCE itself (managed dicts, ``__slots__``); accept both -- and
    # measured on 3.10 and 3.12, the calling frame's locals never appear
    # as referrers, so the verdict does not depend on frame lifetime.
    saw_parent = False
    for ref in gc.get_referrers(value):
        if ref is parent_dict or ref is parent:
            saw_parent = True
            continue
        if any(ref is reg for reg in _PYIR_TRACE_KEEPALIVES):
            continue
        return False
    return saw_parent


def _record_fresh_leaf_first_defs_walk(
    obj: Any, block: "ir.Block", depth: int, seen: "set[int]"
) -> None:
    """Record the leaf first-def facts of one ctor-born object and descend
    into its ctor-private sub-objects (``t.sub.n``-style depth-2+ leaves)."""
    # Meta-primitive fields of value-tree-protocol objects belong to the leaf
    # machinery, not to the attr-place ledger.
    record_meta_fields = not _implements_dynamic_expression(obj)
    for attr_name in _get_instance_attrs(obj):
        value = getattr(obj, attr_name, None)
        # F-BIRTHPOS depth totality: every published instance-attr place of a
        # ctor-born object carries the birth-depth fact (first-wins).
        _any_slot = _make_slot_key(None, obj, attr_name)
        if _any_slot is not None and _any_slot not in _slot_first_def_depth_any:
            _slot_first_def_depth_any[_any_slot] = depth
        # Staged scalar leaf: record ONLY the birth block; a later cell mint for
        # this place seeds at that block instead of a fabricated entry init.
        if _is_staged_value(value) and _can_carry_leaf_ref(value):
            leaf_slot = _make_slot_key(None, obj, attr_name)
            if leaf_slot is not None and leaf_slot not in _slot_refs:
                _slot_first_def_block[leaf_slot] = block
                _pyir_keepalive_generation_obj(obj)
            continue
        if not record_meta_fields:
            continue
        if type(value) not in (bool, int, float):
            if id(value) not in seen and _subobject_is_ctor_private(obj, value):
                seen.add(id(value))
                _record_fresh_leaf_first_defs_walk(value, block, depth, seen)
            continue
        leaf_slot = _make_slot_key(None, obj, attr_name)
        if leaf_slot is None or leaf_slot in _slot_refs:
            continue
        _slot_first_def_inside_cf[leaf_slot] = True
        _slot_first_def_depth[leaf_slot] = depth
        _slot_first_def_block[leaf_slot] = block


def _record_meta_primitive_first_def(
    target_name: str,
    value: Any,
    owner: Any,
    slot_name: Any,
    maybe_written: bool = True,
) -> Any:
    """Record D1 first-def bookkeeping for a Python-primitive *value* (tuples
    recurse per leaf); *maybe_written=False* (bound once) skips the wrap."""
    if isinstance(value, tuple):
        # Recurse per leaf with the ``f"{name}[{i}]"`` convention shared with ``_decompose_tuple``:
        # bare-name tuples use a name-based key; slot-backed tuples carry their parent slot via ``elem_slot``.
        has_slot_ctx = owner is not None and slot_name is not None
        wrapped = []
        for i, elem in enumerate(value):
            elem_name = f"{target_name}[{i}]"
            elem_slot = _place_seg_child(slot_name, i) if has_slot_ctx else None
            wrapped.append(
                _record_meta_primitive_first_def(
                    elem_name,
                    elem,
                    owner if has_slot_ctx else None,
                    elem_slot,
                    maybe_written=maybe_written,
                )
            )
        # Identity-preserving when no leaf changed (an alias bind keeps
        # `t2 is t1` Python-true); else preserve a namedtuple's subtype on
        # first-def: ``tuple(wrapped)`` would strip its field names.
        if all(w is e for w, e in zip(wrapped, value)):
            return value
        return _rebuild_tuple_like(value, wrapped)

    # F-CEPLACE: a synthesized tuple-leaf name is its own binding birth (the
    # assign choke only saw the whole-tuple target).
    if owner is None and slot_name is None and isinstance(target_name, str):
        _ce_note_local_assign(target_name)

    # Constexpr-loop per-iteration reset: a raw-primitive first-def into an
    # already-promoted slot stores into the existing ref (no staged-CF depth here).
    if (
        is_inside_constexpr_loop()
        and not is_inside_staged_cf()
        and type(value) in (bool, int, float)
        and pyir is not None
    ):
        _ce_slot = _make_slot_key(target_name, owner, slot_name)
        if _ce_slot is not None:
            _ce_ref = _slot_refs.get(_ce_slot)
            if _ce_ref is not None:
                log().info(
                    "[pyir_assign] '%s' constexpr-loop per-iteration reset into "
                    "already-promoted slot -> store + load",
                    target_name,
                )
                _pyir_emit_store(_emit_constant_for_ref(_ce_ref, value), _ce_ref)
                return _load_as_dsl(_ce_ref, place=_ce_slot)

    # Staged scalar leaf first-def (F-BIRTHPOS): record the binding block so a
    # later lazy cell mint for this place seeds at the birth position.
    if (
        is_inside_staged_cf()
        and _is_staged_value(value)
        and _can_carry_leaf_ref(value)
        and pyir is not None
    ):
        birth_slot = _make_slot_key(target_name, owner, slot_name)
        if birth_slot is not None and birth_slot not in _slot_refs:
            try:
                _slot_first_def_block[birth_slot] = ir.InsertionPoint.current.block
            except Exception:
                _slot_first_def_block.pop(birth_slot, None)

    # Wrap a RAW Python literal (exactly bool/int/float, not an already-``_WatchedM`` value) first-read
    # inside staged CF, or re-materialise its reset. The strict ``type`` test excludes slot-tracked wrappers.
    if is_inside_staged_cf() and type(value) in (bool, int, float):
        d1_slot = _make_slot_key(target_name, owner, slot_name)
        if d1_slot is not None:
            # Per-iteration reset: an earlier unrolled iteration already promoted this slot, so this
            # first-def is the body-top reset -- store + ``_load_as_dsl`` so the local carries the reset SSA.
            existing_ref = _slot_refs.get(d1_slot)
            if existing_ref is not None and pyir is not None:
                log().info(
                    "[pyir_assign] '%s' Python-primitive first-def into "
                    "already-promoted slot -> store + load (per-iteration reset)",
                    target_name,
                )
                new_ir = _emit_constant_for_ref(existing_ref, value)
                _pyir_emit_store(new_ir, existing_ref)
                return _load_as_dsl(existing_ref, place=d1_slot)
            # Read-only first-def gate (symmetric to ``_pyir_read_impl``): a primitive proved bound once
            # (``maybe_written=False``) skips the ``_WatchedM`` wrap, keeping the read a constexpr.
            if not maybe_written and not _meta_uses.get(d1_slot):
                log().info(
                    "[pyir_assign] '%s' read-only primitive first-def "
                    "(maybe_written=False) -> meta passthrough",
                    target_name,
                )
            else:
                value = _WatchedM(value, d1_slot)

    # Record whether this slot was first-defined inside staged CF (a later reassignment consults it for the
    # per-iteration reset). Gated on ``isinstance`` so ``_WatchedM`` records.
    if isinstance(value, (bool, int, float)):
        d1_slot = _make_slot_key(target_name, owner, slot_name)
        if d1_slot is not None:
            inside_cf = is_inside_staged_cf()
            _slot_first_def_inside_cf[d1_slot] = inside_cf
            if inside_cf:
                _slot_first_def_depth[d1_slot] = current_staged_cf_depth()
                if pyir is not None:
                    try:
                        _slot_first_def_block[d1_slot] = ir.InsertionPoint.current.block
                    except Exception:
                        _slot_first_def_block.pop(d1_slot, None)
    return value


# Base-form machinery: the watched-meta wrappers, dominance/constant helpers and
# slot lookups the entrypoints/carry spine drives.


def _cached_ir_value_dominates_current_ip(value: "ir.Value") -> bool:
    """Whether *value* is reachable from ``InsertionPoint.current`` (reusing a
    sibling-region constant would be a region escape). True when undecidable."""
    if pyir is None:
        return True
    try:
        current_block = ir.InsertionPoint.current.block
    except (RuntimeError, ValueError):
        return True
    return bool(pyir.value_dominates_ip(value, current_block, None))


def _mlir_type_or_none(value: object) -> "ir.Type | None":
    """Return *value*'s MLIR type, or ``None`` if it has no SSA backing.

    Reads the baked backing structurally first, never through ``ir_value()``
    (a full staged-read choke that can emit a refresh ``pyir.load`` or bake a
    constant -- pure waste when only the type is consumed). A value with no
    baked backing keeps the ``ir_value()`` judgment (a meta payload bakes and
    reports its type)."""
    raw = _raw_backing_ir_value(value)
    if raw is not None:
        try:
            return raw.type
        except Exception:
            return None
    try:
        return value.ir_value().type  # type: ignore[attr-defined]
    except Exception:
        return None


def _staged_type_changed(old_value: object, new_value: object) -> bool:
    """Return True when a same-name reassignment changes the MLIR type.

    A ref's element type is fixed at creation: a same-name rebind to a different
    MLIR type would round-trip the OLD type, so the path mints a fresh ref.

    Without both MLIR types the comparison reports "no change" so the
    ref-reuse path is preserved.
    """
    old_ty = _mlir_type_or_none(old_value)
    new_ty = _mlir_type_or_none(new_value)
    if old_ty is None or new_ty is None:
        return False
    return old_ty != new_ty


def _pyir_lookup_slot_from_value(value: "Any") -> "MutableValue | None":
    """Find the ``MutableValue`` that most recently produced *value* via ``.load()``.

    Cheap path: ``value._mutable_ref`` only; ``None`` when not slot-backed
    (callers then route through the plain-Python path with no auto-load).

    Narrow contract (no registry-scan fallback): O(1) lookups and no ambiguity
    when two slots share the same ``_load_version``.
    """
    if _get_load_version(value) is None:
        return None
    return getattr(value, "_mutable_ref", None)


def _pyir_value_tracked_by_accessible_ref(value: "Any") -> bool:
    """Whether *value* is backed by a slot whose ``pyir.ref`` is reachable
    from the current insertion point.

    Used by the op-build dominance check to skip values that the lowering
    carries through ``scf`` iter_args (the pass maintains SSA dominance).
    """
    mv = _pyir_lookup_slot_from_value(value)
    if mv is None:
        return False
    if getattr(mv, "ref", None) is None:
        return False
    return mv._is_ref_accessible()


def _pyir_row_load_type_mismatch(ref: "ir.Value", current_value: Any) -> bool:
    """True when *ref*'s pointee differs from *current_value*'s baked MLIR
    type: a place row is single-typed, so a differently-typed binding belongs
    to another generation of the place and the row must not serve it (the
    load would read a stale sibling value).  A binding with NO baked backing
    (a meta primitive reading its promoted row) only refuses an opaque row."""
    try:
        pointee = ref.type.pointee
    except Exception:
        return False
    raw = _raw_backing_ir_value(current_value)
    if raw is None:
        return _pyir_ir_type_is_opaque(pointee)
    try:
        return raw.type != pointee
    except Exception:
        return False


def _load_as_dsl(
    ref: "ir.Value",
    *,
    attach: bool = True,
    place: Any = None,
    stamp_place: bool = False,
) -> Any:
    """Emit ``pyir.load(ref)`` and reconstruct the row's wrapper from its
    store-time template (F-TYPEID) through the one ``_wrap_ir_like`` funnel.

    *place* keys the template of the row being loaded; *stamp_place* also
    stamps the synthetic cell handle with it (F-PLACE) so a later read can
    validate the route by place equality.  Only the place-NAMED read chokes
    stamp: a wrapper returned from a write choke flows into machinery carry
    temps whose reads must still claim the cell by first-wins rooting.

    Attaches a synthetic ``_mutable_ref`` so ``_pyir_auto_load_arg`` re-emits
    ``pyir.load`` at op boundaries (post-CF uses would carry stale SSA).

    *attach=False* returns a snapshot pinned at this program point: no later
    choke re-follows the cell (statement-top read-anchor semantics).
    """
    if pyir is None:
        return None
    loaded_ir = pyir.load(ref)
    template = _slot_templates.get(place) if place is not None else None
    dsl_val = _wrap_ir_like(template, loaded_ir)
    if dsl_val is loaded_ir:
        # Identity reconstruction (no wrapper template): nothing to attach to.
        return dsl_val

    if not attach:
        return dsl_val
    # Synthetic MutableValue so _pyir_auto_load_arg can re-load.
    try:
        mv = MutableValue(dsl_val)
        mv._ref = ref
        mv._ref_context_id = id(ir.Context.current)
        # F-PLACE: the synthetic cell handle names the place it loads from,
        # so a later read can validate this route by place equality.
        if stamp_place and place is not None:
            mv._place = place
        # The load just emitted IS this row's choke event (F-GEN).
        mv._last_choke_region_epoch = _pyir_current_region_epoch()
        _attach_mutable_ref(dsl_val, mv, "D1 _load_as_dsl")
        # Freshness tags: this value IS a load of the cell at this program point,
        # provably current (same version/depth/epoch + dominance) -- no reload needed.
        _tag_load(
            dsl_val,
            mv._load_version,
            current_staged_cf_depth(),
            _ref_write_epoch(ref),
        )
    except Exception:
        pass  # attach failure is non-fatal; value still works inside CF
    return dsl_val


def _clear_slot_mv(owner: Any, slot_name: Any) -> None:
    """Remove the recorded ``MutableValue`` for ``(owner, slot_name)``;
    silently does nothing when the slot has no entry."""
    if owner is None:
        return
    store = _slot_store_for_tier1(owner)
    if store is not None:
        store.pop(slot_name, None)
    # Registry-slot owners (no ``__dict__``) live only here; tier-1 owners may
    # also have a same-object echo that must not resurface on the next lookup.
    _SLOT_REGISTRY.pop(_make_slot_id(owner, slot_name), None)


def _pyir_retire_place_row(target_name: Any, owner: Any, slot_name: Any) -> None:
    """A fresh-generation rebind abandons the place's previous ledger row; the
    binding's next read or write mints the new generation's cell (W2).

    The retire is total across scopes: inside a constexpr instance the
    (instance-qualified) key names the same stale row, and leaving it live
    would let R1 place authority serve the abandoned generation."""
    if owner is not None and slot_name is not None:
        _clear_slot_mv(owner, slot_name)
        return
    if not isinstance(target_name, str):
        return
    try:
        place = _make_slot_key(target_name, None, None)
    except Exception:
        return
    if place is not None:
        _PLACE_REGISTRY.pop(place, None)


def _pyir_region_fresh_raw(value: "Any") -> "Any | None":
    """Clause-B freshness for a routed raw consumed ACROSS a region boundary:
    a fresh load of the cell when the cell is unchanged since the value's own
    load (epoch-equal) but a staged region opened after it -- the runtime
    re-entry re-executes later-traced stores the pre-region snapshot cannot
    see.  ``None`` keeps the captured raw: an epoch-MISMATCHED raw is a LAW-1
    retained snapshot (the tuple-swap pin relies on it), and no route or no
    region-entry proof keeps the conservative raw."""
    mv = getattr(value, "_mutable_ref", None)
    if mv is None or pyir is None or not is_pyir_enabled():
        return None
    try:
        if mv.ref is None or not mv._is_ref_accessible():
            return None
        entry_tag = _get_load_region_entry(value)
        if (
            entry_tag is not None
            and entry_tag < _pyir_region_entry_watermark()
            and _get_load_epoch(value) == _ref_write_epoch(mv.ref)
        ):
            return mv.load()
    except Exception:
        return None
    return None


def _pyir_refresh_cell_read(value: "Any") -> "Any | None":
    """The staged-read choke (clause B read half): return a FRESH wrapper
    loaded from *value*'s place cell when its cached raw is no longer the
    cell's current content, or ``None`` to keep the cached raw.

    ``Numeric.to(ir.Value)`` is the single funnel every staged scalar read
    materialises through; a read of the place must observe the cell.

    Staleness discrimination matches ``_pyir_auto_load_arg`` (version +
    staged-CF depth + ref write-epoch + dominance).

    Machine stores consume the value's OWN raw and never route through this
    choke.  Conservative: any failure returns ``None`` (cached-raw behaviour).
    """
    mv = getattr(value, "_mutable_ref", None)
    if mv is None:
        if pyir is None or not is_pyir_enabled():
            return None
        return _pyir_recover_place_cell_read(value)
    if pyir is None or not is_pyir_enabled():
        return None
    try:
        # A cell minted in a DIFFERENT MLIR context belongs to a previous
        # compilation; any dereference is a use-after-free.  Refuse loudly.
        if mv._ref is not None and mv._ref_context_id != id(ir.Context.current):
            raise DSLUserCodeError(
                "This value was produced by a PREVIOUS @jit compilation "
                "(its backing IR lives in a different, already-finalized "
                "compilation context) and cannot be reused here.",
                suggestion=(
                    "Pass the value through the kernel's arguments (a "
                    "runtime value) or recompute it in this compilation; "
                    "values stashed across separate top-level @jit calls "
                    "do not carry over."
                ),
            )
        if mv.ref is None or not mv._is_ref_accessible():
            return None
        # Pairing-identity split: full freshness discrimination only when *value*
        # is the cell's CANONICAL representative (last stored/loaded value).

        # A site-less read of an aliased wrapper keeps its dominating raw (it
        # cannot tell which place it names); a trapped raw loads the attached cell.
        if mv._value is not value:
            if _value_dominates_current_ip(value):
                # A literal re-bake would re-materialize a possibly-unstored
                # placeholder seed: a placeholder-seeded cell serves the read
                # through a live load the used-poison scan can judge.
                if _is_literal_backed(value) and not _pyir_ref_init_is_real_value(
                    mv.ref
                ):
                    return mv.load()
                fresh = _pyir_region_fresh_raw(value)
                if fresh is not None:
                    return fresh
                return None
            return mv.load()
        cached_version = _get_load_version(value)
        if (
            cached_version is not None
            and cached_version == mv._load_version
            and _get_load_depth(value) == current_staged_cf_depth()
            and _get_load_epoch(value) == _ref_write_epoch(mv.ref)
            and _value_dominates_current_ip(value)
        ):
            return None
        if cached_version is None:
            # Version-untagged wrapper (a store stamps epoch+depth, not version):
            # its raw is current only at the same epoch AND depth, and dominating.

            # A paired wrapper with NO tags carries no freshness proof: the read
            # loads the cell (a redundant load-after-store folds downstream).
            epoch_tag = _get_load_epoch(value)
            depth_tag = _get_load_depth(value)
            if (
                epoch_tag is not None
                and epoch_tag == _ref_write_epoch(mv.ref)
                and depth_tag is not None
                and depth_tag == current_staged_cf_depth()
                and _value_dominates_current_ip(value)
            ):
                return None
        return mv.load()
    except Exception:
        return None


def _pyir_holder_pairs_binding(value: "Any", candidates: "Any") -> "list[tuple]":
    """The ``(holder, attr)`` pairs among *candidates* whose instance storage
    binds *value* by identity."""
    pairs: "list[tuple]" = []
    for cand in candidates:
        if not _has_instance_storage(cand):
            continue
        for attr in _get_instance_attrs(cand):
            try:
                if getattr(cand, attr, None) is value:
                    pairs.append((cand, attr))
            except Exception:
                continue
    return pairs


def _pyir_recovery_holder_pairs(value: "Any") -> "Any":
    """The holder pairs an unpaired read may resolve (a list, or a lazy
    registry-order iterator).  Inside an extraction walk the DECLARED owner
    context is authoritative: the innermost declared holder binding the value
    serves the read, a two-attr binding within it refuses loudly (the walk
    names the holder, never the attr), and no context hit means no emission
    (the existing loud refusal stands).  Outside a walk, the registry scan in
    sighting order is the recorded C4 residual (multi-holder states reach
    here through channels the walks do not declare yet)."""
    if _EXTRACTION_WALK_OWNERS:
        for cand in reversed(_EXTRACTION_WALK_OWNERS):
            pairs = _pyir_holder_pairs_binding(value, (cand,))
            if len(pairs) == 1:
                return pairs
            if len(pairs) > 1:
                filename, lineno = _first_non_dsl_caller_location()
                raise DSLUserCodeError(
                    DiagId.SNAPSHOT_UNMATERIALIZABLE,
                    filename=filename,
                    lineno=lineno,
                    var=type(value).__name__,
                )
        return []
    return _pyir_registry_pairs_iter(value)


def _pyir_registry_pairs_iter(value: "Any") -> "Any":
    """Registry-order pair enumeration with the full scan's membership and
    order.  Non-funneled candidates are probed EAGERLY up front (their
    ``getattr`` can run user descriptor getters, which the full scan always
    executed); funneled wrappers are probed lazily -- those probes are plain
    storage reads (frame-filtered recorder aside), so probes past the
    consumer's first accepted pair are droppable with no observable
    difference."""
    cands = _pyir_registry_candidate_objects()
    eager: "dict[int, list]" = {}
    for i, cand in enumerate(cands):
        if not _pyir_wrapper_write_funneled(type(cand)):
            eager[i] = _pyir_holder_pairs_binding(value, (cand,))

    def _pairs() -> "Any":
        for i, cand in enumerate(cands):
            pre = eager.get(i)
            if pre is not None:
                yield from pre
                continue
            if not _has_instance_storage(cand):
                continue
            for attr in _get_instance_attrs(cand):
                try:
                    if getattr(cand, attr, None) is value:
                        yield (cand, attr)
                except Exception:
                    continue

    return _pairs()


def _pyir_recover_place_cell_read(value: "Any") -> "Any | None":
    """Owner-context recovery for an unpaired staged read: promote / reload
    from the resolved holder's live cell; refuse a type-differing in-region
    rebind loudly."""
    if _is_literal_backed(value) and is_inside_staged_cf():
        if getattr(value, "_pyir_place_probe_neg", False):
            return None
        if not (_is_staged_value(value) and _can_create_ref(value)):
            return None
        for cand, attr in _pyir_recovery_holder_pairs(value):
            slot_mv = _get_slot_mv(cand, attr)
            if slot_mv is not None and slot_mv._is_ref_accessible():
                if _pyir_ref_pointee_type_changed(slot_mv._ref, value):
                    return None
                loaded = slot_mv.load()
            else:
                # One cell per place: a bare-ref row already booked for this
                # place (a promoted meta slot) is the cell -- adopt it.
                place = _make_slot_key(None, cand, attr)
                d1_ref = _slot_refs.get(place) if place is not None else None
                if d1_ref is not None:
                    if _pyir_ref_pointee_type_changed(d1_ref, value):
                        return None
                    loaded = _load_as_dsl(d1_ref, place=place)
                    try:
                        setattr(cand, attr, loaded)
                    except Exception:
                        pass
                    return loaded
                slot_mv = _create_ref(value)
                slot_mv = _set_slot_mv(cand, attr, slot_mv)
                loaded = slot_mv.load()
            try:
                setattr(cand, attr, loaded)
            except Exception:
                pass
            return loaded
        try:
            _pyir_setattr_raw(value, "_pyir_place_probe_neg", True)
        except (AttributeError, TypeError):
            pass
        return None
    try:
        raw = _raw_backing_ir_value(value)
        if raw is None or _value_dominates_current_ip(value):
            return None
    except Exception:
        return None
    assert raw is not None  # narrowed above; the except path returned
    for cand, attr in _pyir_recovery_holder_pairs(value):
        slot_mv = _get_slot_mv(cand, attr)
        if slot_mv is None or not slot_mv._is_ref_accessible():
            continue
        slot_ref = slot_mv._ref
        if slot_ref is not None and _pyir_ref_pointee_type_changed(slot_ref, value):
            _pyir_raise_type_changed_in_region(attr, slot_ref.type.pointee, raw.type)
        loaded = slot_mv.load()
        try:
            setattr(cand, attr, loaded)
        except Exception:
            pass
        return loaded
    return None


def _pyir_meta_primitive_value(v: "Any") -> "Any":
    """Return the Python value of a meta-valued binding (primitive, ``_WatchedM``,
    or cell-less literal-backed staged scalar), else ``_NO_CONST_VALUE``."""
    if isinstance(v, _WatchedM):
        return v.python_value
    if isinstance(v, (bool, int, float)):
        return v
    try:
        if (
            _is_staged_value(v)
            and _is_literal_backed(v)
            and getattr(v, "_mutable_ref", None) is None
        ):
            return v.value
    except Exception:
        pass
    return _NO_CONST_VALUE


def _pyir_snapshot_registry_meta_slots() -> "list[tuple[Any, str, Any]]":
    """Snapshot ``(holder, attr, literal)`` for registered holder attributes bound
    to cell-less literal-backed staged scalars at a staged-loop entry."""
    out: "list[tuple[Any, str, Any]]" = []
    if not is_pyir_enabled():
        return out
    for cand in _pyir_registry_candidate_objects():
        if isinstance(cand, MutableValue) or _is_staged_value(cand):
            continue
        if not _has_instance_storage(cand):
            continue
        for attr in _get_instance_attrs(cand):
            if isinstance(attr, str) and attr.startswith("_pyir"):
                continue
            try:
                v = getattr(cand, attr, None)
            except Exception:
                continue
            try:
                if (
                    v is not None
                    and _is_staged_value(v)
                    and _is_literal_backed(v)
                    and getattr(v, "_mutable_ref", None) is None
                ):
                    out.append((cand, attr, v.value))
            except Exception:
                continue
    return out


def _pyir_verify_registry_meta_slots(
    snapshot: "list[tuple[Any, str, Any]]",
) -> None:
    """Refuse a meta-valued holder attribute advanced inside a staged loop body
    outside the ledger (traced once -- only the first iteration's value bakes)."""
    for holder, attr, pre in snapshot:
        try:
            cur = getattr(holder, attr, None)
        except Exception:
            continue
        curp = _pyir_meta_primitive_value(cur)
        if curp is _NO_CONST_VALUE or isinstance(cur, _WatchedM):
            # The cell's literal init is the witness: minted in-region from a
            # value differing from the loop-entry literal = an unledgered advance.

            # A non-literal init (an SSA seed) is a genuine carried store -- exempt.
            mv = getattr(cur, "_mutable_ref", None)
            if mv is None or mv.ref is None:
                continue
            try:
                init_const = _ref_literal_init_const(mv.ref)
            except Exception:
                continue
            if init_const is _NO_CONST_VALUE:
                continue
            try:
                if bool(init_const == pre):
                    continue
            except Exception:
                continue
        else:
            try:
                unchanged = bool(curp == pre)
            except Exception:
                unchanged = True
            if unchanged:
                continue
            d1_slot = _make_slot_key(None, holder, attr)
            if d1_slot is not None and d1_slot in _slot_refs:
                continue
        raise DSLUserCodeError(
            DiagId.BOUNDARY_META_LOOP_CARRY,
            name=str(attr),
        )


# Opaque-owner subscript-write audit: a subscript store through a type outside
# the place-owner families (dict/list, watched, memref-like, staged /
# DynamicExpression) runs a ``__setitem__`` the chokes cannot see into.
# Pre-existing reachable leaves are carried by the region walks; a container
# key CREATED by such a store has no pre-region cell, so no lowering can make
# it follow the region's runtime predicate. The write choke arms this audit
# with a key-set snapshot of the owner's reachable containers; the region
# close verifies and retires it.
_PYIR_OPAQUE_OWNER_AUDITS: "dict[int, tuple[str, Any, list[tuple[Any, frozenset]]]]" = {}


def _pyir_opaque_owner_key_sets(owner: "Any") -> "list[tuple[Any, frozenset]]":
    """Key sets of every dict/list reachable from *owner* through instance
    storage and container values (attribute-walk only: no protocol method of
    the owner runs, so the snapshot itself has no side effects)."""
    out: "list[tuple[Any, frozenset]]" = []
    seen: "set[int]" = set()

    def _walk(obj: "Any") -> None:
        if obj is None or id(obj) in seen:
            return
        seen.add(id(obj))
        if isinstance(obj, dict):
            out.append((obj, frozenset(dict.keys(obj))))
            for v in list(dict.values(obj)):
                _walk(v)
            return
        if isinstance(obj, list):
            out.append((obj, frozenset(range(list.__len__(obj)))))
            for v in list.__iter__(obj):
                _walk(v)
            return
        if isinstance(obj, tuple):
            for v in obj:
                _walk(v)
            return
        if _is_staged_value(obj):
            return
        items = _instance_storage_items(obj)
        if items is None:
            return
        for v in list(items.values()):
            _walk(v)

    _walk(owner)
    return out


def _pyir_arm_opaque_owner_audit(name: str, owner: "Any") -> None:
    """Arm the region-close key-set audit for an opaque-``__setitem__`` owner.
    The first write's pre-state wins: the audit diffs the state before the
    owner's first in-region store against the region close."""
    if id(owner) in _PYIR_OPAQUE_OWNER_AUDITS:
        return
    _PYIR_OPAQUE_OWNER_AUDITS[id(owner)] = (
        name,
        owner,
        _pyir_opaque_owner_key_sets(owner),
    )


def _pyir_verify_opaque_owner_audits() -> None:
    """Refuse (loudly) any container key created through an opaque
    ``__setitem__`` owner inside dynamic staged CF; retires the armed audits
    whether or not they pass (each dynamic region judges its own writes)."""
    if not _PYIR_OPAQUE_OWNER_AUDITS:
        return
    try:
        for name, owner, snap in list(_PYIR_OPAQUE_OWNER_AUDITS.values()):
            pre_by_id = {id(h): ks for h, ks in snap}
            for holder, cur_keys in _pyir_opaque_owner_key_sets(owner):
                pre_keys = pre_by_id.get(id(holder), frozenset())
                added = [k for k in cur_keys if k not in pre_keys]
                if added:
                    raise DSLUserCodeError(
                        DiagId.CONTAINER_OPAQUE_SUBSCRIPT_KEY_CREATED,
                        var=name,
                        kind=type(owner).__name__,
                        detail=", ".join(sorted(repr(k) for k in added)),
                    )
    finally:
        _PYIR_OPAQUE_OWNER_AUDITS.clear()


def _pyir_leaf_is_carried(value: "Any") -> bool:
    """Return True if a Numeric leaf is carried through PyIR slot state.

    An instrumented-method mutation leaves a slot marker (slot ref /
    ``_mutable_ref`` / ``_pyir_load_version``); an uninstrumented
    (``@dsl_user_op``) mutation rebinds the parent to an untracked Numeric.

    A carried leaf keeps its markers even while its SSA is region-trapped.
    Conservative: any error returns True (an indeterminate leaf is never clobbered).
    """
    try:
        if _pyir_value_tracked_by_accessible_ref(value):
            return True
        if getattr(value, "_mutable_ref", None) is not None:
            return True
        if _get_load_version(value) is not None:
            return True
        return False
    except Exception:
        return True


def _ref_lives_in_strictly_enclosing_block(value: "Any") -> bool:
    """True if *value*'s backing ``pyir.ref`` was minted in a block that
    STRICTLY ENCLOSES the current insertion point.

    A conditional update of an outer-scope binding stores back through the
    shallower ref; a flat same-region redefinition takes a fresh shadow.

    Block nesting is the reliable signal (the depth dict and a live
    ``_mutable_ref`` cannot discriminate).  Any error returns ``False``.
    """
    if pyir is None:
        return False
    mv = getattr(value, "_mutable_ref", None)
    if mv is None:
        return False
    ref_ssa = getattr(mv, "ref", None)
    if ref_ssa is None:
        return False
    try:
        owner = ref_ssa.owner
        ref_block = (
            owner
            if isinstance(owner, ir.Block)
            else getattr(owner, "operation", owner).block
        )
        cur_block = ir.InsertionPoint.current.block
        if ref_block == cur_block:
            return False
        return pyir.is_value_in_ancestor_region(ref_ssa, cur_block)
    except Exception:
        return False


def _carries_foreign_slot_binding(value: Any) -> bool:
    """Return True if *value* (or any of its tuple leaves) re-resolves a
    storage slot on every use rather than holding a fixed SSA value.

    Re-resolution = an accessible ``_mutable_ref`` (auto-load re-emits
    ``pyir.load`` per consumer) or a ``_slot_refs``-promoted ``_WatchedM`` key.

    A live binding is correct for the slot's own accessor but WRONG for an
    independent Python local; see ``_freeze_foreign_slot_binding``.

    Containers recurse per element: a literal / comprehension / concat
    container SNAPSHOTS its elements in Python value terms.
    """
    if isinstance(value, tuple):
        return any(_carries_foreign_slot_binding(e) for e in value)
    if isinstance(value, list):
        return any(_carries_foreign_slot_binding(e) for e in value)
    if isinstance(value, dict):
        return any(_carries_foreign_slot_binding(e) for e in value.values())
    if isinstance(value, _WatchedM):
        slot = value._slot_key
        return slot is not None and slot in _slot_refs
    mv = getattr(value, "_mutable_ref", None)
    return mv is not None and mv._is_ref_accessible()


def _freeze_foreign_slot_binding(
    value: Any, context: str, *, fresh_container: bool = False
) -> Any:
    """Return a copy of *value* frozen to its current SSA, detached from
    any storage slot it was loaded from.

    Used by ``pyir_assign`` for a fresh plain-local binding that still
    re-resolves a foreign slot: freezing binds it to its assignment-time value.

    Value-preserving: reuses the already-loaded SSA and only removes the slot
    linkage.  Tuples are frozen leaf-by-leaf; unfreezable values pass through.

    A ``list`` / ``dict`` is frozen element-in-place ONLY under the declared
    ``fresh_binding`` AST fact (constructed by the binding statement itself).

    An aliased container is returned untouched -- detaching a shared list's
    elements would rewrite the source binding.  Top-level snapshot only.
    """
    if isinstance(value, tuple):
        # Shape-faithful freeze (clause A3): rebuild through the tuple's own
        # subtype so a namedtuple binding keeps its named fields.
        return _rebuild_tuple_like(
            value, (_freeze_foreign_slot_binding(e, context) for e in value)
        )
    if isinstance(value, list):
        if fresh_container:
            for i, e in enumerate(value):
                if isinstance(e, (list, dict)):
                    continue  # possibly-aliased nested container
                if _carries_foreign_slot_binding(e):
                    value[i] = _freeze_foreign_slot_binding(e, context)
        return value
    if isinstance(value, dict):
        if fresh_container:
            for k, e in list(value.items()):
                if isinstance(e, (list, dict)):
                    continue  # possibly-aliased nested container
                if _carries_foreign_slot_binding(e):
                    value[k] = _freeze_foreign_slot_binding(e, context)
        return value
    if isinstance(value, _WatchedM):
        slot = value._slot_key
        if slot is None or slot not in _slot_refs:
            return value
        # Bake/reuse the current SSA, then return a slot-less wrapper so
        # ``_pyir_auto_load_arg`` treats it as a fixed value.
        frozen = _WatchedM(value.python_value, slot_key=None)
        try:
            frozen._cached_ir = value.ir_value()
        except Exception:
            return value
        log().info("[pyir_assign] froze _WatchedM binding (%s)", context)
        return frozen
    mv = getattr(value, "_mutable_ref", None)
    if mv is None or not mv._is_ref_accessible():
        return value
    # A SUPERSEDED handle of an admitted rebound memref cell must not freeze
    # to the slot's current value (that is a fresh generation's buffer).
    _pyir_refuse_stale_memref_serve(value, mv)
    # Capture the slot's CURRENT carried value at assignment time, then detach. A leaf still on its
    # construction-time SSA would bake a STALE pre-loop value, so load the ref (iter_arg) and freeze THAT.
    try:
        frozen = mv.load()
    except Exception:
        frozen = _fresh_wrapper(value)
    if frozen is value:
        return value
    # Defensive: neither ``load`` nor the ``_fresh_wrapper`` fallback copies
    # ``_mutable_ref``; ensure it is detached.
    if getattr(frozen, "_mutable_ref", None) is not None:
        try:
            _pyir_delattr_raw(frozen, "_mutable_ref")
        except (AttributeError, TypeError):
            pass
    log().info("[pyir_assign] froze ref-backed binding (%s)", context)
    return frozen


def _pyir_same_ref_reload(value: Any, ref: "ir.Value | None") -> bool:
    """Shared same-ref reload exemption: *value* is backed by *ref*'s own cell.

    A value whose ``_mutable_ref`` IS the slot's ref is a reload of (or an
    instrumented store through) the SAME place cell, not an unledgered advance.
    """
    if ref is None:
        return False
    try:
        return getattr(getattr(value, "_mutable_ref", None), "ref", None) is ref
    except Exception:
        return False


def _is_opaque_leaf_type(value: "ir.Value") -> bool:
    """Return ``True`` for an OPAQUE value-tree leaf -- one the scalar
    ``pyir.ref`` / M2S slot machinery does NOT auto-carry.

    Opaque = a dialect-specific value (an MMA / copy atom handle etc.) the
    slot machinery cannot carry; the region carry carries it instead.

    Gates the ``scf.if`` forward-carry to opaque leaves only; a slot-carried
    scalar leaf is never double-carried.  Any error -> ``False``.
    """
    try:
        return _pyir_ir_type_is_opaque(value.type)
    except Exception:
        return False


def _pyir_ir_type_is_opaque(ty: Any) -> bool:
    """``True`` for a dialect-opaque MLIR type (not a builtin integer / index /
    float / shaped type).  Conservative: any error -> ``False``."""
    try:
        if ir.IntegerType.isinstance(ty):
            return False
        if ir.IndexType.isinstance(ty):
            return False
        if hasattr(ir, "FloatType") and ir.FloatType.isinstance(ty):
            return False
        if ir.ShapedType.isinstance(ty):
            # vector<...> / tensor<...> of scalars -- carried by the slot
            # machinery as a staged aggregate.
            return False
        return True
    except Exception:
        return False


def _pyir_extract_leaf_values(obj: Any) -> "list[ir.Value] | None":
    """Return *obj*'s canonical value-tree leaves as bare ``ir.Value``s.

    Uses ``__extract_mlir_values__`` (the non-PyIR pytree flattening), so the
    result is the independent leaf set that reconstructs *obj*.

    Narrower than :func:`_pyir_walk_ir_value_holders`: a whole-object rebind
    carries only canonical leaves; the reconstruct re-derives derived fields.

    Returns ``None`` for a non-value-tree object or any extraction failure.

    A SCALAR leaf is normalised to an ``ArithValue`` via
    :func:`_as_arith_capable_scalar_leaf`; an OPAQUE leaf is left raw.
    """
    if not _implements_dynamic_expression(obj):
        return None
    try:
        vals = obj.__extract_mlir_values__()
    except Exception:
        return None
    if not isinstance(vals, (list, tuple)):
        return None
    leaves: "list[ir.Value]" = []
    for v in vals:
        if isinstance(v, ir.Value):
            leaves.append(_as_arith_capable_scalar_leaf(v))
        else:
            raw = _raw_backing_ir_value(v)
            if raw is None:
                return None
            leaves.append(_as_arith_capable_scalar_leaf(raw))
    return leaves


def _pyir_is_carryable_tuple(obj: Any) -> bool:
    """A TOP-LEVEL ``tuple`` / ``list`` whose every element is a value-tree: the
    region-close carry treats it as a value-tree (concat of leaves)."""
    return (
        isinstance(obj, (tuple, list))
        and len(obj) > 0
        and all(_implements_dynamic_expression(e) for e in obj)
    )


def _pyir_extract_any_leaf_values(obj: Any) -> "list[ir.Value] | None":
    """:func:`_pyir_extract_leaf_values` extended to a top-level tuple / list:
    the canonical leaves are the concatenation of each element's, in order.

    Falls back to the plain value-tree extract for a non-container; ``None``
    on any non-extractable element."""
    if _pyir_is_carryable_tuple(obj):
        out: "list[ir.Value]" = []
        for elem in obj:
            ev = _pyir_extract_leaf_values(elem)
            if ev is None:
                return None
            out.extend(ev)
        return out
    return _pyir_extract_leaf_values(obj)


def _pyir_new_from_mlir_values_any(obj: Any, new_vals: "list[ir.Value]") -> Any:
    """``__new_from_mlir_values__`` extended to a top-level tuple / list: split
    *new_vals* by extract arity and rebuild a NEW container of the same kind.

    Falls back to the plain protocol for a non-container; ``None`` on any
    failure (the caller leaves the binding unchanged).

    Opens the rebuild-protocol frame (F-BIRTH): token adoption is legal only
    for objects this machinery produces (V-6), and the carried source must
    still be its born class (V-7)."""
    _PYIR_REBUILD_PROTOCOL_DEPTH[0] += 1
    try:
        if _pyir_is_carryable_tuple(obj):
            rebuilt: "list[Any]" = []
            idx = 0
            for elem in obj:
                _pyir_validate_owner_class(elem)
                try:
                    arity = len(elem.__extract_mlir_values__())
                except Exception:
                    return None
                new_elem = elem.__new_from_mlir_values__(new_vals[idx : idx + arity])
                # Re-root the rebuilt element's place at the source's owner token.
                _pyir_propagate_owner_token(elem, new_elem)
                rebuilt.append(new_elem)
                idx += arity
            # Shape-faithful container rebuild (clause A3): a namedtuple / tuple
            # subclass must come back as its own subtype (fields as separate args).
            if isinstance(obj, list):
                new_container: Any = list(rebuilt)
            else:
                new_container = _rebuild_tuple_like(obj, rebuilt)
            _pyir_propagate_owner_token(obj, new_container)
            return new_container
        _pyir_validate_owner_class(obj)
        new_obj = obj.__new_from_mlir_values__(new_vals)
        # Re-root the rebuilt object's place at the source's owner token.
        _pyir_propagate_owner_token(obj, new_obj)
        return new_obj
    finally:
        _PYIR_REBUILD_PROTOCOL_DEPTH[0] -= 1


def _is_opaque_leaf_value_tree(obj: Any) -> bool:
    """Return ``True`` for a value-tree object whose canonical extract-leaves
    are ALL opaque (a tensor's opaque memref handle, an MMA / copy atom handle).

    Its loop-carried state is carried by the opaque-leaf region carry,
    not the scalar slot machinery (which cannot carry an opaque leaf).

    A whole-object rebind of such an object PASSES THROUGH in ``pyir_assign``
    and leaves the carry to the region-close carry.

    Keys on the CANONICAL leaves (what ``__new_from_mlir_values__``
    reconstructs from), unlike a raw ``__dict__`` walk over derived fields.

    Conservative: non-value-tree, no leaves, or any scalar leaf -> ``False``
    (a scalar value-tree stays on the M->M decompose path).
    """
    leaves = _pyir_extract_leaf_values(obj)
    if not leaves:
        return False
    return all(_is_opaque_leaf_type(leaf) for leaf in leaves)


def _value_trees_different_prototype(old: object, new: object) -> bool:
    """Return True if *old* and *new* are value-tree-protocol objects of the same
    class whose canonical leaves ALIGN (same count) but a NON-LEAF *prototype*
    field (a meta-primitive or a primitive tuple) DIFFERS.

    That is the signature of a whole-object BRANCH-SELECT between two
    structurally distinct prototypes of one class.

    Such a rebind carries only the DIFFERING canonical leaves through the
    region-close ``scf.if``; the reconstruct restores the prototype fields.

    A ``__dict__`` walk would instead branch-select every field, tripping the
    meta-primitive guard and leaving a ref unstored on the no-op branch.

    A SAME-prototype carry returns False (stays on the ``__dict__``-walk
    decomposition).  Conservative: any failure / non-protocol -> False.
    """
    if old is new:
        return False
    if not _implements_dynamic_expression(old) or not _implements_dynamic_expression(
        new
    ):
        return False
    if type(old) is not type(new):
        return False
    if not _has_instance_storage(old) or not _has_instance_storage(new):
        return False
    try:
        old_leaves = _pyir_extract_leaf_values(old) or []
        new_leaves = _pyir_extract_leaf_values(new) or []
    except Exception:
        return False
    # Leaves must align for region-close carry + reconstruct; a divergent
    # extract is left to the conservative ``__dict__`` walk.
    if len(old_leaves) == 0 or len(old_leaves) != len(new_leaves):
        return False
    try:
        attrs = _get_instance_attrs(old)
    except Exception:
        return False
    for attr_name in attrs:
        try:
            ov = getattr(old, attr_name)
            nv = getattr(new, attr_name)
        except AttributeError:
            continue
        # A non-leaf prototype field is a meta-primitive or tuple of primitives;
        # an SSA-backed (staged) field is a leaf handled by carry.
        if ov is None or isinstance(ov, (bool, int, float)):
            if (nv is None or isinstance(nv, (bool, int, float))) and ov != nv:
                return True
        elif (
            isinstance(ov, tuple)
            and isinstance(nv, tuple)
            and all(isinstance(x, (bool, int, float)) for x in ov)
            and all(isinstance(x, (bool, int, float)) for x in nv)
            and ov != nv
        ):
            return True
    return False


def _has_accessible_loop_carried_ref(target_name: str, value: object) -> bool:
    """Return True iff *value* already has a ``pyir.ref`` slot reachable from
    inside the current loop body -- so its top-of-body read would load the
    loop-carried value rather than bind to the pre-loop SSA.

    Used by :func:`pyir_promote_loop_body_arg` to decide whether a body-entry
    ``pyir_read`` is needed; checks ``_mutable_ref`` and the D1 ``_slot_refs``.

    A ref counts only when accessible from the current IP.  Conservative on
    error: report "no ref" so the body-entry load is emitted.
    """
    try:
        mv = getattr(value, "_mutable_ref", None)
        if mv is not None and mv._is_ref_accessible():
            return True
        d1_slot = _make_slot_key(target_name, None, None)
        if d1_slot is not None and d1_slot in _slot_refs:
            return True
    except Exception:
        return False
    return False


def _pyir_skip_trapped_child_region_writeback(
    ref: "ir.Value",
    new_value: Any,
    place: Any = None,
    mv: "MutableValue | None" = None,
) -> Any:
    """Shared guard for the two ``pyir_assign`` writeback fast-paths."""
    if pyir is None or ref is None:
        return None
    if _raw_backing_ir_value(new_value) is None:
        return None
    if _value_dominates_current_ip(new_value):
        return None
    if mv is not None:
        loaded = mv.load()
        _attach_mutable_ref(loaded, mv, "child-region writeback skip")
        return loaded
    return _load_as_dsl(ref, place=place)


def _walk_value_tree_holders(
    obj: Any,
    leaf_pred: "Callable[[Any], bool]",
    _visited: "set[int] | None" = None,
    _out: "list[tuple[Any, str, Any]] | None" = None,
) -> "list[tuple[Any, str, Any]]":
    """Return the ``(holder, attr, value)`` of every *leaf_pred* leaf in *obj*.

    Appends into *_out* when given (one shared accumulator across a multi-root
    sweep; identical DFS order to the concatenating form) and returns it.
    """
    if _visited is None:
        _visited = set()
    if _out is None:
        _out = []
    oid = id(obj)
    if oid in _visited:
        return _out
    if not _implements_dynamic_expression(obj):
        return _out
    storage = _instance_storage_items(obj)
    if storage is None:
        return _out
    _visited.add(oid)

    for attr_name, attr_val in list(storage.items()):
        if isinstance(attr_val, (tuple, list)):
            for elem in attr_val:
                _walk_value_tree_holders(elem, leaf_pred, _visited, _out)
        elif isinstance(attr_val, dict):
            # Dict fields recurse per value (raw ``dict.values`` so an adopted
            # watched dict is walked without firing its read chokes).
            for elem in list(dict.values(attr_val)):
                _walk_value_tree_holders(elem, leaf_pred, _visited, _out)
        elif leaf_pred(attr_val):
            _out.append((obj, attr_name, attr_val))
        else:
            _walk_value_tree_holders(attr_val, leaf_pred, _visited, _out)
    return _out


# Exact builtin scalar types that can never hold or be a staged-SSA leaf;
# subclasses deliberately excluded (exact-type check) so they take the full path.
_WALK_PRIM_SKIP = frozenset({int, float, bool, str, bytes, complex, type(None)})


def _pyir_walk_ir_value_holders(obj: Any) -> "list[tuple[Any, str, Any]]":
    """Return the in-place holders of every staged-SSA leaf in *obj*.

    Specialized form of ``_walk_value_tree_holders`` with the staged-SSA leaf
    predicate inlined (identical DFS output; this sweep runs once per staged
    region over the whole candidate registry, so it is hot)."""
    out: "list[tuple[Any, str, Any]]" = []
    _walk_ir_value_holders_into(obj, set(), out)
    return out


# Branch class of one attr value in the holder walk, memoized per type
# (class shape is definition-time-stable). Mirrors the walk's branch
# precedence exactly: containers, then bare ``ir.Value``, then exact builtin
# scalars, then the generic leaf-or-recurse path.
_WALK_KIND_SEQ, _WALK_KIND_DICT, _WALK_KIND_IRV, _WALK_KIND_PRIM, _WALK_KIND_OTHER = (
    1,
    2,
    3,
    4,
    5,
)
_WALK_CLASS_KIND: "dict[type, int]" = {}


def _walk_class_kind(cls: type) -> int:
    if issubclass(cls, (tuple, list)):
        return _WALK_KIND_SEQ
    if issubclass(cls, dict):
        return _WALK_KIND_DICT
    if issubclass(cls, ir.Value):
        return _WALK_KIND_IRV
    if cls in _WALK_PRIM_SKIP:
        return _WALK_KIND_PRIM
    return _WALK_KIND_OTHER


def _walk_storage_prim_irv_only(storage: "dict[str, Any]") -> bool:
    """True when every storage value is an exact builtin scalar or a bare
    ``ir.Value`` -- on such nodes the walk's loop body is append/continue only
    (no user code reachable), so it may iterate the live dict directly."""
    kinds = _WALK_CLASS_KIND
    for v in storage.values():
        cls = type(v)
        kind = kinds.get(cls)
        if kind is None:
            kind = kinds[cls] = _walk_class_kind(cls)
        if kind != _WALK_KIND_PRIM and kind != _WALK_KIND_IRV:
            return False
    return True


def _walk_ir_value_holders_into(
    obj: Any,
    visited: "set[int]",
    out: "list[tuple[Any, str, Any]]",
) -> None:
    """Recursive body of :func:`_pyir_walk_ir_value_holders`."""
    oid = id(obj)
    if oid in visited:
        return
    if not _implements_dynamic_expression(obj):
        return
    storage = _instance_storage_items(obj)
    if storage is None:
        return
    visited.add(oid)
    kinds = _WALK_CLASS_KIND
    if _walk_storage_prim_irv_only(storage):
        # PRIM/IRV-only node: the loop body runs no user code, so no snapshot
        # copy of the storage dict is needed (same records, same order).
        for attr_name, attr_val in storage.items():
            if kinds[type(attr_val)] == _WALK_KIND_IRV:
                out.append((obj, attr_name, attr_val))
        return
    for attr_name, attr_val in list(storage.items()):
        cls = type(attr_val)
        kind = kinds.get(cls)
        if kind is None:
            kind = kinds[cls] = _walk_class_kind(cls)
        if kind == _WALK_KIND_OTHER:  # scalar-Numeric leaf or recurse
            if _is_numeric_leaf_holder(attr_val):
                out.append((obj, attr_name, attr_val))
            else:
                _walk_ir_value_holders_into(attr_val, visited, out)
        elif kind == _WALK_KIND_IRV:  # bare ir.Value leaf
            out.append((obj, attr_name, attr_val))
        elif kind == _WALK_KIND_PRIM:  # exact builtin scalar: nothing below
            continue
        elif kind == _WALK_KIND_SEQ:
            for elem in attr_val:
                _walk_ir_value_holders_into(elem, visited, out)
        else:
            # Raw ``dict.values`` so an adopted watched dict is walked without
            # firing its read chokes.
            for elem in list(dict.values(attr_val)):
                _walk_ir_value_holders_into(elem, visited, out)


def _pyir_build_gather_segment(cand: Any) -> "tuple | None":
    """The walk records of a cacheable sweep root as ``(records, guards)``, or
    ``None`` when the root must take the live walk. ``records`` holds the
    ``(attr, value)`` pairs; ``guards`` holds ``(wrapper, stamp)`` pairs for
    every Numeric-leaf record, revalidated at splice time. The root itself is
    left out of the cached row (the splice re-attaches it): a cached record
    holding its own root would pin the root -- and with it the root's registry
    row -- for the whole trace, defeating the registry's weakref pruning.

    Cacheable = write-funneled class (declared value-tree protocol, no
    ``__slots__``/override) whose every storage value is an exact builtin
    scalar, a bare ``ir.Value``, an SSA-backed scalar-Numeric leaf, or a
    walk-inert value (protocol bucket ``False``: the walk's recursion into it
    returns before visiting). Rebinding any such field goes through the
    declared write funnel and stamps the root, so the records are a pure
    function of root storage. The one non-root input is the SSA-backed leaf
    classification, which can only change through a write on the WRAPPER's own
    funnel; the per-record guard pins the wrapper's write stamp so a stale
    classification invalidates the row instead of splicing.
    This builder mirrors the live walk on such roots, record for record."""
    cls = type(cand)
    if _VT_PROTOCOL_CLASS_CACHE.get(cls) is not True:
        return None  # unseen/instance/False buckets: the live walk judges it
    if not _pyir_wrapper_write_funneled(cls):
        return None
    storage = _instance_storage_items(cand)
    if storage is None:
        return None
    kinds = _WALK_CLASS_KIND
    stamps = _PYIR_HOLDER_WRITE_STAMPS
    seg: "list[tuple[str, Any]]" = []
    guards: "list[tuple[Any, int]]" = []
    for attr_name, attr_val in storage.items():
        vcls = type(attr_val)
        kind = kinds.get(vcls)
        if kind is None:
            kind = kinds[vcls] = _walk_class_kind(vcls)
        if kind == _WALK_KIND_IRV:  # bare ir.Value leaf record
            seg.append((attr_name, attr_val))
        elif kind == _WALK_KIND_PRIM:  # exact builtin scalar: nothing below
            continue
        elif kind == _WALK_KIND_OTHER and _is_numeric_leaf_holder(attr_val):
            # SSA-backed scalar-Numeric leaf: the live walk records the
            # wrapper by reference without recursing. An unregistered
            # wrapper has no stamp row to guard on -- live walk.
            wstamp = stamps.get(id(attr_val))
            if wstamp is None:
                return None
            seg.append((attr_name, attr_val))
            guards.append((attr_val, wstamp))
        elif kind == _WALK_KIND_OTHER and _VT_PROTOCOL_CLASS_CACHE.get(vcls) is False:
            # Class-stable walk-inert value (e.g. the slot cell handle): the
            # walk's recursion returns before visiting, so no record.
            continue
        else:  # containers, walkable objects, meta-payload wrappers: live walk
            return None
    return (tuple(seg), tuple(guards))


class _PyirSelfLeafHolder:
    """Sentinel ``holder`` of a SELF-LEAF snapshot record -- the record's TYPE
    discriminator (recognised by :func:`_is_self_leaf_record`)."""


_PYIR_SELF_LEAF_HOLDER = _PyirSelfLeafHolder()


def _is_self_leaf_record(holder: Any, attr_name: str) -> bool:
    """Return ``True`` for a SELF-LEAF snapshot record (structural: the holder is the
    dedicated :class:`_PyirSelfLeafHolder` sentinel)."""
    return isinstance(holder, _PyirSelfLeafHolder)


def _self_leaf_snapshot(arg: Any) -> "list[tuple[Any, str, ir.Value]] | None":
    """Snapshot a WHOLE-OBJECT bare ``ir.Value`` *arg* as ONE self-leaf record."""
    if not isinstance(arg, ir.Value):
        return None
    raw = _raw_backing_ir_value(arg)
    if raw is None:
        return None
    if _implements_dynamic_expression(arg):
        # A protocol-bearing ir.Value whose holder walk found nothing is
        # still its own single leaf when extraction agrees (e.g. an
        # ir.Value-subclass pointer wrapper with no instance storage);
        # bail only when extraction names a different leaf set.
        try:
            leaves = _pyir_extract_any_leaf_values(arg) or []
        except Exception:
            return None
        if len(leaves) != 1 or not _same_ir_value(leaves[0], raw):
            return None
    return [(_PYIR_SELF_LEAF_HOLDER, _PYIR_SELF_LEAF_ATTR, raw)]


def _numeric_leaf_kind(value: object) -> "_Literal['none', 'ssa', 'meta']":
    """Classify *value* as a value-tree scalar-Numeric leaf and its backing."""
    global _IS_STAGED_VALUE_FN
    try:
        fn = _IS_STAGED_VALUE_FN
        if fn is None:
            from .multi_stage_manager import _is_staged_value

            fn = _IS_STAGED_VALUE_FN = _is_staged_value

        if isinstance(value, ir.Value):
            return _NUMERIC_LEAF_NONE
        if not (fn(value) and _can_carry_leaf_ref(value)):
            return _NUMERIC_LEAF_NONE
        if _raw_backing_ir_value(value) is not None:
            return _NUMERIC_LEAF_SSA
        return _NUMERIC_LEAF_META
    except Exception:
        return _NUMERIC_LEAF_NONE


def _is_numeric_leaf_holder(value: object) -> bool:
    """Return True if *value* is a staged scalar Numeric wrapper backed by a
    real SSA (the parent-attribute leaf shape the holder walk snapshots)."""
    return _numeric_leaf_kind(value) == _NUMERIC_LEAF_SSA


def _pyir_record_promoted_place_leaf(owner: Any, key: Any) -> None:
    """Record an owner place promoted at the D1 write choke so the stale-leaf
    region reload can repair its raw storage; trace-scoped, weakref preferred."""
    if owner is None or not isinstance(key, (str, int)):
        return
    oid = id(owner)
    row = _PYIR_PROMOTED_PLACE_LEAVES.get(oid)
    if row is None:

        def _drop_leaf_row(_r: Any, _oid: int = oid) -> None:
            _PYIR_PROMOTED_PLACE_LEAVES.pop(_oid, None)

        try:
            handle: Any = _weakref.ref(owner, _drop_leaf_row)
        except TypeError:
            handle = owner  # non-weakrefable (dict/list): strong, cleared at exit
        row = (handle, set())
        _PYIR_PROMOTED_PLACE_LEAVES[oid] = row
    row[1].add(key)


def _pyir_reload_one_stale_leaf(owner: Any, key: Any, context: str) -> None:
    """Re-bind ONE owner place to a fresh dominating load when its current
    staged scalar escaped a closed region while its slot ref dominates."""
    try:
        leaf_place = _make_slot_key(None, owner, key)
        ref = _slot_refs.get(leaf_place)
    except Exception:
        return
    if not isinstance(ref, ir.Value) or not _value_dominates_current_ip(ref):
        return
    is_container = isinstance(owner, (dict, list))
    try:
        if is_container:
            value = (
                dict.__getitem__(owner, key)
                if isinstance(owner, dict)
                else list.__getitem__(owner, key)
            )
        else:
            value = getattr(owner, key)
    except Exception:
        return
    cur_raw = _raw_backing_ir_value(value)
    # Only an ESCAPING leaf: a real backing SSA that does NOT dominate the IP.
    if cur_raw is None or _value_dominates_current_ip(cur_raw):
        return
    try:
        fresh = _load_as_dsl(ref, place=leaf_place)
        if isinstance(owner, dict):
            dict.__setitem__(owner, key, fresh)
        elif isinstance(owner, list):
            list.__setitem__(owner, key, fresh)
        else:
            _pyir_setattr_raw(owner, key, fresh)
        log().info(
            "[pyir region] re-loaded stale staged leaf '%s' from its slot ref (%s)",
            key,
            context,
        )
    except Exception:
        return


def _pyir_reload_stale_staged_attr_leaves(context: str) -> None:
    """Re-load any TRACKED object-attribute slot whose current staged scalar
    escaped a sibling region (its backing SSA no longer dominates the IP)."""
    if pyir is None:
        return
    for sid in list(_SLOT_REGISTRY.keys()):
        if sid.kind != "attr" or not isinstance(sid.key, str):
            continue
        wref = _OWNER_KEEPALIVE.get(sid.owner)
        owner = wref() if wref is not None else None
        if owner is None:
            continue
        # The D1 table keys by PLACE, so the owner object (not the id-keyed
        # ``_SlotId``) is needed to resolve the entry.
        _pyir_reload_one_stale_leaf(owner, sid.key, context)
    # Places promoted at the D1 write choke (no registry row): same repair.
    for oid, (handle, keys) in list(_PYIR_PROMOTED_PLACE_LEAVES.items()):
        owner = handle() if isinstance(handle, _weakref.ReferenceType) else handle
        if owner is None:
            continue
        for key in list(keys):
            _pyir_reload_one_stale_leaf(owner, key, context)


def _pyir_revert_escaped_leaf(
    holder: Any,
    attr_name: str,
    snap_value: Any,
    allow_numeric_revert: bool = True,
) -> bool:
    """Revert one snapshotted leaf if it escaped a closed staged region."""
    try:
        cur_value = getattr(holder, attr_name)
    except AttributeError:
        return False
    if cur_value is snap_value:
        return False
    cur_raw = _raw_backing_ir_value(cur_value)
    snap_raw = _raw_backing_ir_value(snap_value)
    if cur_raw is None or snap_raw is None:
        return False
    # A carried Numeric leaf (instrumented mutator -> slot markers) is a genuine carried accumulator;
    # reverting it would drop the carry. Only the untracked ``@dsl_user_op`` escape is repaired here.
    if _is_numeric_leaf_holder(snap_value) and (
        not allow_numeric_revert or _pyir_leaf_is_carried(cur_value)
    ):
        return False
    # Keep the replacement if it still dominates the outer IP (a legitimate forward update); revert only
    # when the replacement is trapped in the closed region AND the snapshot SSA dominates.
    if _value_dominates_current_ip(cur_raw):
        return False
    if not _value_dominates_current_ip(snap_raw):
        return False
    try:
        _pyir_setattr_raw(holder, attr_name, snap_value)
    except (AttributeError, TypeError):
        return False
    return True


def _pyir_repair_captured_escaped_leaves(
    snapshot: "list[tuple[Any, str, Any]] | None",
    context: str,
    allow_numeric_revert: bool = True,
) -> None:
    """Revert captured value-tree leaves that escaped a closed staged region. Companion
    to :func:`_pyir_gather_captured_leaf_holders`.

    Records of write-funneled holders unwritten since the snapshot's gather
    clock are skipped: unchanged stamp on a funneled class whose ``getattr``
    is a storage read implies exactly the unchanged-identity ``continue``."""
    if snapshot is None:
        return
    snap_clock = getattr(snapshot, "pyir_gather_clock", None)
    stamps = _PYIR_HOLDER_WRITE_STAMPS
    for holder, attr_name, snap_value in snapshot:
        if snap_clock is not None:
            stamp = stamps.get(id(holder))
            if (
                stamp is not None
                and stamp <= snap_clock
                and _pyir_getattr_reads_storage(type(holder), attr_name)
            ):
                continue
        # Unchanged-identity fast path: mirrors the first check inside
        # :func:`_pyir_revert_escaped_leaf`, hoisted out of the call.
        try:
            if getattr(holder, attr_name) is snap_value:
                continue
        except AttributeError:
            continue
        if _pyir_revert_escaped_leaf(
            holder, attr_name, snap_value, allow_numeric_revert
        ):
            log().info(
                "[pyir region] reverted escaped captured value-tree leaf '%s' (%s)",
                attr_name,
                context,
            )


def _pyir_repair_region_escaped_leaves(
    arg: Any,
    snapshot: "list[tuple[Any, str, Any]] | None",
    context: str,
    allow_numeric_revert: bool = True,
) -> Any:
    """Revert value-tree leaves that escaped a closed staged region, in place."""
    if snapshot is None:
        return arg
    for holder, attr_name, snap_value in snapshot:
        # Unchanged-identity fast path: mirrors the first check inside
        # :func:`_pyir_revert_escaped_leaf`, hoisted out of the call.
        try:
            if getattr(holder, attr_name) is snap_value:
                continue
        except AttributeError:
            continue
        if _pyir_revert_escaped_leaf(
            holder, attr_name, snap_value, allow_numeric_revert
        ):
            log().info(
                "[pyir region] reverted escaped value-tree leaf '%s' (%s)",
                attr_name,
                context,
            )
    return arg


def _pyir_ref_init_is_real_value(ref: "ir.Value") -> bool:
    """Return ``True`` if a ``pyir.ref``'s INIT operand is a genuine value, not a
    deferred-UB stand-in."""
    try:
        if pyir is None or not hasattr(pyir, "ref_init_is_real_value"):
            return False
        return bool(pyir.ref_init_is_real_value(ref))
    except Exception:
        return False


def _pyir_repair_region_escaped_tuple_leaves(
    arg: Any,
    if_op: "ir.Operation",
    context: str,
) -> None:
    """Re-bind a TUPLE/LIST-contained scalar value-tree leaf trapped in a closed
    STANDALONE ``scf.if`` to a dominating ``pyir.load`` of its slot ref."""
    if pyir is None or arg is None:
        return
    if not _implements_dynamic_expression(arg):
        return
    for attr_name in _get_instance_attrs(arg):
        attr_val = getattr(arg, attr_name, None)
        if not isinstance(attr_val, (tuple, list)):
            continue
        new_elems: "list[Any]" = []
        rebuilt = False
        for elem in attr_val:
            repaired = _pyir_reload_trapped_tuple_leaf(elem, if_op, context)
            if repaired is not None:
                new_elems.append(repaired)
                rebuilt = True
            else:
                new_elems.append(elem)
        if rebuilt:
            # ``type(attr_val)(new_elems)`` breaks a namedtuple (positional
            # ``__new__``), so rebuild through the tuple-like helper.
            rebuilt_val = (
                new_elems
                if isinstance(attr_val, list)
                else _rebuild_tuple_like(attr_val, new_elems)
            )
            try:
                _pyir_setattr_raw(arg, attr_name, rebuilt_val)
            except (AttributeError, TypeError):
                pass


def _pyir_reload_trapped_tuple_leaf(
    elem: Any,
    if_op: "ir.Operation",
    context: str,
) -> Any:
    """Repair ONE tuple element trapped in a closed ``scf.if``; see
    :func:`_pyir_repair_region_escaped_tuple_leaves`."""
    if not _is_numeric_leaf_holder(elem):
        return None
    raw = _raw_backing_ir_value(elem)
    if raw is None:
        return None
    # Already dominates the post-``if`` IP -> correctly carried, leave it.
    if _value_dominates_current_ip(elem):
        return None
    # Only repair a leaf genuinely TRAPPED inside the closed ``scf.if``.
    if not _ir_value_defined_inside_op(raw, if_op):
        return None
    mv = getattr(elem, "_mutable_ref", None)
    if mv is None:
        return None
    ref = getattr(mv, "ref", None)
    if not isinstance(ref, ir.Value):
        return None
    if not mv._is_ref_accessible() or not _value_dominates_current_ip(ref):
        return None
    # Never re-bind to a load of a deferred-UB (poison / placeholder) ref: that would reintroduce a
    # SCOPE_READ_NEVER_SET read. A real ``arith`` init passes; a conditional-store placeholder is blocked.
    if not _pyir_ref_init_is_real_value(ref):
        return None
    try:
        # Row-authoritative reload: the leaf's own cell reconstructs from its
        # store-time template and re-attaches for downstream re-loads.
        loaded = mv.load()
        _attach_mutable_ref(loaded, mv, "trapped tuple-leaf reload")
    except Exception as exc:
        log().info("[pyir if] tuple-leaf reload emit failed: %s", exc)
        return None
    loaded_raw = _raw_backing_ir_value(loaded)
    if loaded_raw is not None:
        # Mutate the SHARED wrapper in place so a sibling region holding this exact wrapper observes the
        # dominating load, then return the freshly re-bound leaf for the rebuilt tuple.
        try:
            _pyir_setattr_raw(elem, "value", loaded_raw)
        except (AttributeError, TypeError):
            pass
    log().info(
        "[pyir if] reloaded trapped tuple-contained scalar leaf to a dominating "
        "post-if load (%s)",
        context,
    )
    return loaded


def _pyir_mark_loop_carried_ref(ref: "ir.Value") -> None:
    """Stamp the carry-ref marker attribute on *ref*'s defining ``pyir.ref``. See
    :data:`_PYIR_LOOP_ITER_ARGS_ATTR`."""
    try:
        ref_op = _get_defining_operation(ref)
        op = getattr(ref_op, "operation", ref_op)
        op.attributes[_PYIR_LOOP_ITER_ARGS_ATTR] = ir.UnitAttr.get()
    except Exception:
        pass


def _pyir_ref_carries_value(ref: "ir.Value", raw: "ir.Value") -> bool:
    """True iff *raw* is a value the cell *ref* demonstrably carries: its init
    operand, a stored operand of one of its ``pyir.store``s, or a load of it."""
    if pyir is None or ref is None or raw is None:
        return False
    try:
        ref_op = _get_defining_operation(ref)
        if _same_ir_value(ref_op.operands[0], raw):
            return True
        # A load OF this ref: the loaded value is the cell's reaching value
        # at the load point by definition.
        raw_owner = getattr(raw, "owner", None)
        if raw_owner is not None and not isinstance(raw_owner, ir.Block):
            raw_op = getattr(raw_owner, "operation", raw_owner)
            if str(getattr(raw_op, "name", "")) == "pyir.load" and _same_ir_value(
                raw_op.operands[0], ref
            ):
                return True
        # A value some ``pyir.store`` wrote into the cell.
        for use in ref.uses:
            user = getattr(use, "owner", None)
            if user is None:
                continue
            user_op = getattr(user, "operation", user)
            try:
                if str(user_op.name) != "pyir.store":
                    continue
                if _same_ir_value(user_op.operands[0], raw):
                    return True
            except Exception:
                continue
    except Exception:
        return False
    return False


def _pyir_ref_dominates_op(ref: "ir.Value", op: "ir.Operation") -> bool:
    """True iff *ref* dominates the position immediately before *op* -- the
    anchor a region-carry ref needs so the C++ pass can lift it."""
    if pyir is None or ref is None or op is None:
        return False
    try:
        op_norm = getattr(op, "operation", op)
        return bool(pyir.value_dominates_ip(ref, op_norm.block, op_norm))
    except Exception:
        return False


def _pyir_local_place_for_name(name: "str | None") -> Any:
    """LOCAL place key ``('local', scope_id, name)`` for an executor-known bare
    name; ``None`` when no scope is open or inside a constexpr unroll."""
    if not isinstance(name, str) or not name:
        return None
    try:
        if is_inside_constexpr_loop():
            return None
        if not _PYIR_SCOPE_STACK:
            return None
        return _make_slot_key(name, None, None)
    except Exception:
        return None


def _pyir_region_carry_place_for(
    holder: Any, attr_name: Any, arg_name: "str | None"
) -> Any:
    """Ledger place for a region-forwarder leaf record (clause A totality)."""
    if _is_self_leaf_record(holder, attr_name):
        return _pyir_local_place_for_name(arg_name)
    return None


def _pyir_adopt_region_carry_ref(
    place: Any, snap_value: "ir.Value", region_op: "ir.Operation"
) -> "tuple[ir.Value | None, bool]":
    """Get-or-mint THE ``pyir.ref`` cell for a region-carried leaf place."""
    if place is not None and isinstance(place, tuple) and place and place[0] == "local":
        cand = _slot_refs.get(place)
        if cand is not None:
            try:
                type_ok = cand.type.pointee == snap_value.type
            except Exception:
                type_ok = False
            if (
                type_ok
                and _pyir_ref_dominates_op(cand, region_op)
                and _pyir_ref_carries_value(cand, snap_value)
            ):
                return cand, False
    else:
        place = None
    try:
        # Anchor placement (clause A totality for COMPOUND leaves): hoist the
        # mint OUT of the loop body so its init anchors before the region.
        anchor = getattr(region_op, "operation", region_op)
        cur = anchor
        while True:
            parent = getattr(cur, "parent", None)
            if parent is None:
                break
            parent = getattr(parent, "operation", parent)
            name = str(getattr(parent, "name", ""))
            if name == "builtin.module" or getattr(parent, "parent", None) is None:
                break
            try:
                if not pyir.value_dominates_ip(snap_value, parent.block, parent):
                    break
            except Exception:
                break
            if name in ("scf.while", "scf.for"):
                anchor = parent
            cur = parent
        with ir.InsertionPoint(anchor):
            ref = pyir.ref(snap_value)
    except Exception:
        return None, False
    _pyir_mark_loop_carried_ref(ref)
    if place is not None:
        try:
            entry_block = _get_function_entry_block()
            region_op_norm = getattr(region_op, "operation", region_op)
            if entry_block is not None and region_op_norm.block == entry_block:
                _slot_refs[place] = ref
                # F-TYPEID: one type identity per place -- adopt the live
                # registry row's wrapper template when it describes this
                # pointee; a raw-SSA leaf row reconstructs as identity.
                template: Any = snap_value
                row = _PLACE_REGISTRY.get(place)
                if row is not None and row._value is not None:
                    row_raw = _raw_backing_ir_value(row._value)
                    if row_raw is not None and row_raw.type == snap_value.type:
                        template = row._value
                _pyir_record_slot_template(place, template)
        except Exception:
            pass
    return ref, True


def _pyir_adopt_d1_carry_cell(
    target_name: str, raw: "ir.Value"
) -> "MutableValue | None":
    """Adopt the name's live D1 row as its loop-carry cell (one-cell-per-place):
    body reads and the body's D1 write-throughs must share ONE ref.  Adoption
    requires the row to demonstrably carry *raw*; ``None`` lets the caller mint."""
    try:
        place = _make_slot_key(target_name, None, None)
        ref = _slot_refs.get(place) if place is not None else None
        type_ok = ref is not None and ref.type.pointee == raw.type
    except Exception:
        # No provable row (key resolution failed, or the row is not a typed
        # pointer cell): minting is the correct conservative outcome.
        return None
    if not type_ok:
        return None
    if not _pyir_ref_carries_value(ref, raw):
        return None
    # Guards passed: exceptions past here are internal errors and must
    # surface; a silent mint would recreate the split-cell miscompile.
    mv = MutableValue(raw)
    mv._ref = ref
    mv._ref_context_id = id(ir.Context.current)
    if not mv._is_ref_accessible():
        return None
    return _set_slot_mv(None, target_name, mv)


def _pyir_innermost_enclosing_region_op_at_ip() -> "ir.Operation | None":
    """The innermost region-carrying op enclosing the current insertion point,
    or ``None`` at function scope or on any resolution failure."""
    try:
        block = ir.InsertionPoint.current.block
        entry_block = _get_function_entry_block()
        if entry_block is not None and block == entry_block:
            return None
        op = block.owner
        if op is None:
            return None
        return getattr(op, "operation", op)
    except Exception:
        return None


def _pyir_mint_ref_at_value_def(raw: "ir.Value") -> "ir.Value | None":
    """Mint ``pyir.ref %raw`` immediately at *raw*'s definition point (after its
    defining op; at block begin for a block argument) -- the furthest-out anchor."""
    if pyir is None:
        return None
    try:
        entry_block = _get_function_entry_block()
        if entry_block is None:
            return None
        owner = raw.owner
        if isinstance(owner, ir.Block):
            if owner != entry_block:
                return None
            with ir.InsertionPoint.at_block_begin(owner):
                return pyir.ref(raw)
        def_op = getattr(owner, "operation", owner)
        if def_op.block != entry_block:
            return None
        with ir.InsertionPoint.after(def_op):
            return pyir.ref(raw)
    except Exception:
        return None


def _pyir_single_opaque_extract_leaf(value: Any) -> "ir.Value | None":
    """The single canonical extract leaf of *value*, for a wrapper whose raw
    backing is not directly discoverable (the leaf nests in an interior impl
    object, e.g. Array -> _ArrayImpl -> _base).  None unless extraction
    yields exactly one ``ir.Value``."""
    try:
        leaves = _pyir_extract_any_leaf_values(value) or []
    except Exception:
        return None
    if len(leaves) == 1 and isinstance(leaves[0], ir.Value):
        return leaves[0]
    return None


def _pyir_pair_place_cell_handle(place: Any, ref: "ir.Value", value: Any) -> None:
    """Pair *value* with the place cell it was just stored into, so a use of the
    wrapper AFTER the region reloads instead of consuming the trapped raw.

    A bare local needs no pairing: its post-region reads route through the
    instrumented name and reach the cell there.  An attr/subscript read hands
    the wrapper straight to a ``@dsl_user_op``, so only the attached cell lets
    ``_pyir_auto_load_arg`` re-emit the load.  A wrapper that already names a
    live cell keeps it (one cell per place)."""
    if isinstance(place, tuple) and place and place[0] == "local":
        return
    try:
        if getattr(value, "_mutable_ref", None) is not None:
            return
        mv = MutableValue(value)
        mv._ref = ref
        mv._ref_context_id = id(ir.Context.current)
        mv._place = place
        _attach_mutable_ref(value, mv, "opaque place-cell rebind")
    except Exception:
        return


def _pyir_place_opaque_rebind_choke(
    target_name: str, place: Any, old_value: Any, new_value: Any
) -> "ir.Value | None":
    """Clause-A write choke: a PLACE rebound to a same-type OPAQUE value inside a
    staged region writes through that place's ONE cell.  Attr/subscript places
    cell exactly like locals: the place key already roots on the owner token, so
    every alias of the owner names the same cell."""
    if pyir is None or place is None:
        return None
    kind = place[0] if isinstance(place, tuple) and place else None
    if kind != "local" and kind not in ("attr", "subscript"):
        return None
    try:
        if is_inside_constexpr_loop():
            return None
    except Exception:
        return None
    old_raw = _raw_backing_ir_value(old_value)
    if not isinstance(old_raw, ir.Value):
        old_raw = _pyir_single_opaque_extract_leaf(old_value)
    new_raw = _raw_backing_ir_value(new_value)
    if not isinstance(new_raw, ir.Value):
        new_raw = _pyir_single_opaque_extract_leaf(new_value)
    if not isinstance(old_raw, ir.Value) or not isinstance(new_raw, ir.Value):
        return None
    if _same_ir_value(old_raw, new_raw):
        return None
    try:
        if old_raw.type != new_raw.type:
            return None
        if not _is_opaque_leaf_type(old_raw):
            return None
    except Exception:
        return None
    # An owner-rooted place has no per-iteration carry cell of its own, so a
    # NEW value that already dominates the region is some other binding's
    # entry value (`a.ptr = b.ptr`): celling it would pin that trace-time
    # handle for every iteration while the source advances.  A bare local is
    # safe -- its loop carry re-serves the source each iteration -- so only
    # the owner-rooted kinds decline, leaving the pre-existing loud refusal
    # in place.  Loud beats silent drift.
    if kind != "local":
        region = _pyir_innermost_enclosing_region_op_at_ip()
        if region is None or not _ir_value_defined_inside_op(new_raw, region):
            return None
    # CONTINUE-STORE leg.
    cand = _slot_refs.get(place)
    if cand is not None:
        try:
            type_ok = cand.type.pointee == new_raw.type
        except Exception:
            type_ok = False
        if (
            type_ok
            and _value_dominates_current_ip(cand)
            and _pyir_ref_carries_value(cand, old_raw)
        ):
            _pyir_emit_store(
                new_raw, cand, choke=f"opaque place rebind '{target_name}'"
            )
            _pyir_record_slot_template(place, new_value)
            _pyir_pair_place_cell_handle(place, cand, new_value)
            return cand
        # A live row that does not carry the old value belongs to an earlier
        # generation of the name; the mint gate re-books the row.
    region_op = _pyir_innermost_enclosing_region_op_at_ip()
    if region_op is None:
        return None
    if not _value_dominates_current_ip(old_raw):
        return None
    if _ir_value_defined_inside_op(old_raw, region_op):
        return None
    # The new value may be trapped INSIDE the region (the classic carry) or
    # defined OUTSIDE it (a swap/select between pre-region handles): both
    # are loop-carried binding state and cell identically -- without a cell
    # an outside->outside swap silently pins the trace-time binding.
    # Handles cell-carry uniformly (all spaces, all types); refuse only a
    # rebind backed by an IN-REGION allocation (entry-hoisted: aliases one
    # buffer).  Register-space memref handles defer to the store choke
    # below, whose liveness gate admits the iteration-private scratch idiom
    # or refuses there; every other alloc-rooted value (pointer, view,
    # non-register memref) refuses here -- no declared space fact can prove
    # its aliasing faithful.
    if _pyir_memref_alloc_rooted_inside_region(new_raw, region_op):
        if not _pyir_type_is_register_memref(new_raw.type):
            _pyir_raise_memref_inregion_alloc_rebind(target_name)
    ref = _pyir_mint_ref_at_value_def(old_raw)
    if ref is None:
        return None
    _pyir_mark_loop_carried_ref(ref)
    _slot_refs[place] = ref
    _pyir_record_slot_template(place, new_value)
    _pyir_emit_store(new_raw, ref, choke=f"opaque place rebind '{target_name}'")
    _pyir_pair_place_cell_handle(place, ref, new_value)
    log().info(
        "[pyir_assign] '%s' opaque rebind → place cell store",
        target_name,
    )
    return ref


def _pyir_value_rooted_outside_loop(value: "ir.Value", loop_op: "ir.Operation") -> bool:
    """Return ``True`` if *value* is (transitively) computed ONLY from values defined
    OUTSIDE *loop_op* -- i.e."""
    if pyir is None or not isinstance(value, ir.Value):
        return False
    try:
        return bool(
            pyir.value_rooted_outside_loop(
                value, getattr(loop_op, "operation", loop_op)
            )
        )
    except Exception:
        return False


def _pyir_memref_alloc_rooted_inside_region(
    value: "ir.Value", region_op: "ir.Operation"
) -> bool:
    """True iff *value*'s operand cone, cut at the region boundary, reaches an
    op DECLARING the Allocate memory effect INSIDE *region_op* -- the value
    depends on memory allocated inside the staged region. Conservative: False."""
    if pyir is None or not isinstance(value, ir.Value):
        return False
    if not hasattr(pyir, "value_alloc_rooted_inside_region"):
        return False
    try:
        return bool(
            pyir.value_alloc_rooted_inside_region(
                value, getattr(region_op, "operation", region_op)
            )
        )
    except Exception:
        return False


def _pyir_value_is_inner_loop_carried(
    value: "ir.Value", loop_op: "ir.Operation"
) -> bool:
    """Return ``True`` if *value* is a ``pyir.load`` of a leaf-carry ref that a
    NESTED loop / if (closed inside *loop_op*) already created."""
    try:
        if not isinstance(value, ir.Value):
            return False
        def_op = _get_defining_operation(value)
        if getattr(def_op, "name", None) != "pyir.load":
            return False
        ref_val = def_op.operands[0]
        ref_op = _get_defining_operation(ref_val)
        op = getattr(ref_op, "operation", ref_op)
        # Stamped-marker consult: the marker is the exact record the carry
        # machinery established when it minted the ref.
        if _PYIR_LOOP_ITER_ARGS_ATTR not in op.attributes:
            return False
        # The ref must live INSIDE the current loop body (a nested loop closed within it). A ref at the
        # same scope as the current loop (its own outer ref from a prior pass) must not suppress carry.
        if not _ir_value_defined_inside_op(ref_val, loop_op):
            return False
        # The nested loop carries the leaf across loop_op iterations only when
        # its ref re-inits from a value loop_op itself carries.
        try:
            ref_init = op.operands[0]
        except Exception:
            return True
        if isinstance(ref_init, ir.Value) and _pyir_value_rooted_outside_loop(
            ref_init, loop_op
        ):
            return False
        return True
    except Exception:
        return False


def _pyir_holder_walks_align(
    arg: Any, snapshot: "list[tuple[Any, str, ir.Value]]"
) -> bool:
    """True iff *arg*'s ir.Value-holder walk corresponds record-for-record
    ((holder class, attr name) pairs, in walk order) with *snapshot* -- the
    rebound binding is a same-shaped value tree whose leaf holders nest
    BELOW the binding (e.g. a wrapper delegating to an interior impl
    object), so positional leaf pairing is faithful even though the
    snapshot's immediate holder class differs from the binding's own."""
    if not snapshot:
        return False
    try:
        cur_records = _pyir_walk_ir_value_holders(arg)
    except Exception:
        return False
    if len(cur_records) != len(snapshot):
        return False
    for snap_rec, cur_rec in zip(snapshot, cur_records):
        if type(snap_rec[0]) is not type(cur_rec[0]) or snap_rec[1] != cur_rec[1]:
            return False
    return True


def _pyir_resolve_loop_leaf_updates(
    arg: Any,
    snapshot: "list[tuple[Any, str, ir.Value]]",
) -> "list[tuple[Any, str, ir.Value, ir.Value, Any, int]]":
    """Pair each pre-loop snapshot leaf with the loop body's CURRENT leaf value."""
    updates: "list[tuple[Any, str, ir.Value, ir.Value, Any, int]]" = []
    # Whole-object-rebind support: snapshot owner's and current binding's canonical leaves, aligned
    # positionally. Computed lazily (the common in-place path never pays this nor risks a mis-pair).
    snap_owner = snapshot[0][0] if snapshot else None
    snap_extract: "list[ir.Value] | None" = None
    cur_extract: "list[ir.Value] | None" = None
    rebind_aligned = False  # snapshot/current extract lined up by length

    for snap_idx, (snap_holder, attr_name, snap_value) in enumerate(snapshot):
        cur_value: Any = None
        rebind_holder: Any = snap_holder
        reconstruct_obj: Any = None
        leaf_index = -1
        # 0. SELF-LEAF: the snapshot is a whole-object bare ``ir.Value`` (the local IS
        # its own leaf).
        if _is_self_leaf_record(snap_holder, attr_name):
            # OPAQUE self-leaves only: a scalar bare ``ir.Value`` is already
            # carried by the slot machinery; carrying it here would double-carry.
            if not _is_opaque_leaf_type(snap_value):
                continue
            cur_self = _raw_backing_ir_value(arg)
            if isinstance(cur_self, ir.Value) and cur_self is not snap_value:
                cur_value = cur_self
            if cur_value is None:
                continue
            updates.append(
                (
                    rebind_holder,
                    attr_name,
                    snap_value,
                    cur_value,
                    reconstruct_obj,
                    leaf_index,
                )
            )
            continue
        # 1. In-place attribute mutation on the original holder.
        try:
            in_place = getattr(snap_holder, attr_name)
        except AttributeError:
            in_place = None
        if isinstance(in_place, ir.Value) and in_place is not snap_value:
            cur_value = in_place
            rebind_holder = snap_holder
        elif arg is not None and arg is not snap_owner:
            # 2. Whole-object rebind (local binds a NEW object): align this snapshot leaf to a canonical
            #    extract leaf of the owner, then to the same position in the current binding's extract.
            if snap_extract is None:
                # The owner is the rebound object itself (same class as the
                # current binding), or the snapshot's holders nest BELOW the
                # binding as a same-shaped value tree (a wrapper delegating
                # to an interior impl -- e.g. Array -> _ArrayImpl): both give
                # a faithful positional leaf pairing.
                snap_extract = _pyir_extract_any_leaf_values(snap_owner) or []
                cur_extract = _pyir_extract_any_leaf_values(arg) or []
                rebind_aligned = (
                    len(snap_extract) > 0
                    and len(snap_extract) == len(cur_extract)
                    and (
                        type(snap_owner) is type(arg)
                        or _pyir_holder_walks_align(arg, snapshot)
                    )
                )
            if rebind_aligned and snap_extract is not None and cur_extract is not None:
                # Participates only if this leaf's SSA is one of the owner's canonical extract
                # leaves; a derived holder is skipped. ``_same_ir_value`` (same underlying MLIR
                # value), not Python ``is`` -- extraction may re-wrap the same SSA in a fresh
                # ``ir.Value`` object -- and not ``==`` (structural).
                matched = [
                    _k
                    for _k, _ev in enumerate(snap_extract)
                    if _same_ir_value(_ev, snap_value)
                ]
                ci = matched[0] if matched else -1
                if ci >= 0 and _is_opaque_leaf_type(snap_value):
                    # DUPLICATE SSA among the owner's extract leaves: every record
                    # collapses onto the FIRST match, so a duplicated position's own
                    # update would silently cross-bind. Refuse unless every
                    # duplicated position is unchanged (then no pairing is needed).
                    if len(matched) > 1 and any(
                        not _same_ir_value(cur_extract[_k], snap_value)
                        for _k in matched
                    ):
                        _pyir_raise_rebind_duplicate_leaf(arg)
                    # OPAQUE leaves only: a scalar rebind is already carried by the M2S function-entry ref,
                    # so carrying it again would double-carry.
                    new_leaf = cur_extract[ci]
                    if isinstance(new_leaf, ir.Value) and not _same_ir_value(
                        new_leaf, snap_value
                    ):
                        cur_value = new_leaf
                        rebind_holder = snap_holder
                        reconstruct_obj = arg
                        leaf_index = ci
        if cur_value is None:
            continue
        updates.append(
            (
                rebind_holder,
                attr_name,
                snap_value,
                cur_value,
                reconstruct_obj,
                leaf_index,
            )
        )
    return updates


def _pyir_load_dominates_use(loaded: "ir.Value", user_op: "ir.Operation") -> bool:
    """Return ``True`` if *loaded* (a body-entry ``pyir.load`` at a region block's begin)
    DOMINATES *user_op*."""
    if pyir is None:
        return False
    try:
        user_block = user_op.block
        if user_block is None:
            return False
        if not pyir.is_value_in_ancestor_region(loaded, user_block):
            return False
        load_op = _get_defining_operation(loaded)
        if load_op.block != user_block:
            # User is in a region strictly nested below the load's block -> dominated.
            return True
        # Same block: the load sits at block begin, so it dominates any op after it;
        # ``is_before_in_block`` orders the two within the block.
        return load_op.is_before_in_block(getattr(user_op, "operation", user_op))
    except Exception:
        return False


def _pyir_typed_update_is_advance(
    cur_value: "ir.Value",
    sources: "list[ir.Value]",
    region_op: "ir.Operation",
    max_ops: int = 512,
) -> bool:
    """Whether *cur_value*'s def chain inside *region_op* transitively consumes any of
    *sources* -- the old leaf value (or its in-body loads)."""
    if not sources:
        return False
    try:
        seen: "set[int]" = set()
        # Pin every visited wrapper for the walk's duration: a GC'd wrapper's
        # recycled id would alias a NEW op into ``seen`` and break the chain.
        pins: "list[Any]" = []
        work: "list[ir.Value]" = [cur_value]
        budget = max_ops
        while work:
            if budget <= 0:
                # Exhaustion is UNKNOWN, never a silent skip: report an
                # advance so the caller refuses loudly (bounds gate by loud
                # refusal, not truncation).
                return True
            v = work.pop()
            for src in sources:
                if _same_ir_value(v, src):
                    return True
            owner = v.owner
            if isinstance(owner, ir.Block):
                continue  # block argument: no defining op to walk through
            def_op = getattr(owner, "operation", owner)
            oid = id(def_op)
            if oid in seen:
                continue
            seen.add(oid)
            pins.append(def_op)
            if not _op_is_inside_op(def_op, region_op):
                continue  # chain exits the region: loop-invariant root
            budget -= 1
            for operand in def_op.operands:
                work.append(operand)
    except Exception:
        return False
    return False


def _pyir_ref_use_inside_op(
    ref: "ir.Value", loop_op: "ir.Operation", op_name: str
) -> bool:
    """Return True if a use of *ref* by an *op_name* op exists inside *loop_op*."""
    if pyir is None:
        return False
    try:
        for use in ref.uses:
            user = getattr(use, "owner", None)
            if user is None:
                continue
            user_op = getattr(user, "operation", user)
            try:
                if str(user_op.name) != op_name:
                    continue
            except Exception:
                continue
            if _op_is_inside_op(user_op, loop_op):
                return True
    except Exception:
        return False
    return False


def _pyir_slot_stored_in_body(ref: "ir.Value", loop_op: "ir.Operation") -> bool:
    """Return True if a ``pyir.store`` into *ref* exists inside *loop_op*."""
    return _pyir_ref_use_inside_op(ref, loop_op, "pyir.store")


def _pyir_ref_loaded_inside_op(ref: "ir.Value", loop_op: "ir.Operation") -> bool:
    """Return True if a ``pyir.load`` of *ref* exists inside *loop_op*."""
    return _pyir_ref_use_inside_op(ref, loop_op, "pyir.load")


def _pyir_unwrap_meta_primitive(value: Any) -> "Any | None":
    """Return the Python primitive a meta scalar wraps, else ``None``."""
    # Wrapper unwrap precedes the bare-primitive test: a wrapper subclasses
    # int/float, so isinstance would return it (a wrapped bool then mints i32).
    pv = getattr(value, "python_value", None)
    if type(pv) in (bool, int, float):
        return pv
    if type(value) in (bool, int, float):
        return value
    inner = getattr(value, "value", None)
    if isinstance(inner, (bool, int, float)):
        return inner
    return None


def _is_region_meta_scalar(value: Any) -> bool:
    """Return ``True`` for a value-tree field that is a plain *meta* scalar."""
    if isinstance(value, ir.Value):
        return False
    if value is None or isinstance(value, (bool, int, float, str, bytes)):
        return True
    return isinstance(value, _WatchedM)


def _pyir_walk_meta_holders(obj: Any) -> "list[tuple[Any, str, Any]]":
    """Return the in-place holders of every meta-scalar leaf in *obj*."""
    return _walk_value_tree_holders(obj, _is_region_meta_scalar)


def _pyir_restore_region_meta(
    arg: Any,
    snapshot: "list[tuple[Any, str, Any]] | None",
    context: str,
) -> Any:
    """Restore value-tree meta-scalar leaves mutated inside a staged region."""
    if snapshot is None:
        return arg
    for holder, attr_name, snap_value in snapshot:
        try:
            cur_value = getattr(holder, attr_name)
        except AttributeError:
            continue
        # Identity short-circuit covers the no-mutation and interned-small-int cases. Only rebind when the
        # body left another meta scalar there (else the value is not ours to restore).
        if cur_value is snap_value or not _is_region_meta_scalar(cur_value):
            continue
        try:
            _pyir_setattr_raw(holder, attr_name, snap_value)
        except (AttributeError, TypeError):
            continue
        # Forget the closed region's baked-constant bookkeeping so a sibling region
        # re-reading the leaf starts from op-entry state, not spuriously promoted.
        _forget_region_local_slot_state(holder, attr_name)
        log().info(
            "[pyir region] restored region-mutated meta leaf '%s' (%s)",
            attr_name,
            context,
        )
    return arg


def _walk_meta_numeric_leaf_holders(obj: Any) -> "list[tuple[Any, str, Any]]":
    """Return parent-attribute holders of every META-backed Numeric leaf in *obj*."""
    return _walk_value_tree_holders(obj, _is_meta_numeric_leaf)


def _is_meta_numeric_leaf(value: object) -> bool:
    """Return True if *value* is a staged scalar Numeric WRAPPER whose backing is still a
    Python primitive (a meta literal, not a baked SSA)."""
    return _numeric_leaf_kind(value) == _NUMERIC_LEAF_META


def _pyir_restore_meta_numeric_leaves(
    snapshot: "list[tuple[Any, str, Any]] | None",
    context: str,
) -> None:
    """Restore a write-only literal-origin Numeric leaf the closed region baked.
    Companion to :func:`_walk_meta_numeric_leaf_holders`."""
    if snapshot is None:
        return
    for holder, attr_name, snap_value in snapshot:
        try:
            cur_value = getattr(holder, attr_name)
        except AttributeError:
            continue
        if cur_value is snap_value:
            continue
        cur_raw = _raw_backing_ir_value(cur_value)
        if cur_raw is None:
            # Still a meta literal -- nothing baked / trapped.
            continue
        if _value_dominates_current_ip(cur_raw):
            continue
        if _pyir_leaf_is_carried(cur_value):
            # A real loop-carried accumulator carried through a slot is authoritative;
            # only an untracked dead write-only counter is restored.
            continue
        try:
            _pyir_setattr_raw(holder, attr_name, snap_value)
        except (AttributeError, TypeError):
            continue
        log().info(
            "[pyir region] restored region-baked write-only meta numeric leaf "
            "'%s' (%s)",
            attr_name,
            context,
        )


def _is_untracked_post_region_binding(value: Any) -> bool:
    """Return True if *value* is a post-region local binding that the
    ``_pyir_auto_load_arg`` merge could NOT carry through a ref."""
    try:
        if isinstance(value, _WatchedM):
            return False
        if _get_load_version(value) is not None:
            return False
        mv = getattr(value, "_mutable_ref", None)
        if mv is not None and mv._is_ref_accessible():
            return False
        return True
    except Exception:
        return False


# Static export surface (regenerate with scripts/gen_pyir_all.py): the
# module's OWN names -- its namespace minus what lower chain modules
# already export and minus the generator's INTERNAL_ONLY registry.
__all__ = [
    "_functools",
    "gc",
    "_sys",
    "weakref",
    "NoReturn",
    "_PYIR_LOAD_VERSION_ATTR",
    "_PYIR_BOUNDARY_META_CELL_READS",
    "_PYIR_STRUCTURAL_META_CONSUMPTIONS",
    "_PYIR_STRUCTURAL_META_CONSUMPTION_SITES",
    "_PYIR_ARM_LOCAL_META_WRITES",
    "_PYIR_BOUNDARY_FLIP_GUARD_READS",
    "_META_CONST_REPLACEMENTS",
    "_ref_write_epoch",
    "_get_load_version",
    "_get_load_depth",
    "_get_load_epoch",
    "_pyir_adopt_stored_representative",
    "_is_func_boundary_op",
    "_is_module_boundary_op",
    "_auto_promote_primitive",
    "_can_create_ref",
    "_is_scalar_ssa_carryable",
    "_can_carry_leaf_ref",
    "_is_vector_like",
    "_mlir_types_match",
    "_types_match",
    "_is_memref_like",
    "_pyir_raise_memref_inregion_alloc_rebind",
    "_pyir_type_is_register_memref",
    "_PYIR_MEMREF_LAST_STORE",
    "_pyir_note_memref_store",
    "_pyir_scratch_stale_serve_record",
    "_pyir_refuse_stale_memref_serve",
    "_pyir_classify_transitive_consumers",
    "_pyir_load_in_rebind_reexecution_scope",
    "_pyir_scratch_value_admitted",
    "_pyir_ref_pointee_type_changed",
    "_pyir_raise_type_changed_in_region",
    "_pyir_raise_rebind_duplicate_leaf",
    "_pyir_record_slot_template",
    "_declared_m2s_promotion_class",
    "_pyir_declared_promotion_template",
    "_is_boolean_like",
    "_is_literal_backed",
    "_wrap_ir_like",
    "_make_poison_like",
    "_make_zero_like",
    "_pyir_type_is_scalar",
    "_make_raw_placeholder_init",
    "_first_non_dsl_caller_location",
    "_POISON_EMITTED",
    "_get_defining_operation",
    "_get_function_entry_block",
    "_pyir_recorded_birth_block",
    "_mint_region_born_cell",
    "_create_ref",
    "_pyir_emit_store",
    "_SlotId",
    "_NON_WEAKREF_OWNER_TYPES_SEEN",
    "_make_slot_id",
    "_cell_home_binding",
    "_ce_local_key",
    "_ce_note_local_assign",
    "pyir_seed_param_bindings",
    "_make_slot_key",
    "_pyir_owner_slot_is_computed",
    "_pyir_read_place",
    "_pyir_route_is_live_place_row",
    "_pyir_route_is_current",
    "_pyir_resolve_snapshot",
    "_pyir_row_binding_unobserved_write",
    "_push_scope",
    "_pop_scope",
    "_PyirScopeGuard",
    "pyir_register_scope_cells",
    "pyir_register_nonlocal_names",
    "_pyir_boundary_cell_read_for_local",
    "_owner_token",
    "_pyir_wall_composite_str_slot",
    "_place_for",
    "_corrected_place_for",
    "_register_place_prefix",
    "_pyir_same_container_structure",
    "_pyir_propagate_owner_token",
    "_pyir_adopt_rebuilt_owner_token",
    "_pyir_lookup_owner_token",
    "_pyir_validate_owner_class",
    "_pyir_owner_is_celled",
    "_pyir_emission_self_check",
    "_pyir_guard_stale_epoch",
    "_pyir_witness_predicate_fold",
    "_pyir_check_staged_fold_witness",
    "_pyir_module_is_tracer_layer",
    "_pyir_record_external_payload_consumption",
    "_pyir_record_staged_identity_hashed",
    "_pyir_staged_hash_witness_count",
    "_emit_constant_at_current_ip",
    "_emit_constant_for_ref",
    "_const_value_of",
    "_const_values_equal",
    "_unwrap",
    "_pyir_structural_value_conflicts",
    "_pyir_structural_bake_is_reseeded",
    "_pyir_merge_src_pairs",
    "_WatchedM",
    "_WatchedInt",
    "_WatchedBool",
    "_WatchedFloat",
    "_PYIR_DICT_CF_CREATED_KEYS",
    "_WatchedDict",
    "_WatchedList",
    "_pyir_identity_compare_choke",
    "_pyir_watched_dict_label",
    "_pyir_watched_list_label",
    "_pyir_adopt_dict_value",
    "_pyir_instance_dict_owner",
    "_pyir_spec_value_is_ir_wrapper",
    "_pyir_spec_chain_value",
    "_pyir_spec_stamp_trace_born",
    "_pyir_adopt_list_value",
    "_pyir_register_container_held_object",
    "_pyir_owner_is_container_held",
    "_SEQ_WALK_INERT_PRIMS",
    "_mark_container_walk_visited",
    "_sequence_walk_is_inert",
    "_pyir_adopt_containers_under",
    "_pyir_record_host_restore",
    "_pyir_holder_store",
    "_replace_value_uses",
    "_exit_function_trace",
    "_pyir_take_sealed_spec",
    "_pyir_assert_entry_attested",
    "_slot_storage_available",
    "_get_slot_mv",
    "_pyir_track_slot_holder",
    "_pyir_refuse_del_finalizer_owner",
    "_pyir_sighting_inert_class",
    "_pyir_register_candidate_holder",
    "_pyir_settle_sighting",
    "_pyir_register_trace_args",
    "_pyir_spec_signature_facts",
    "_pyir_spec_seg_steps",
    "_pyir_spec_observe_attr_read",
    "_pyir_spec_observe_global_read",
    "_pyir_spec_record_read",
    "_pyir_spec_record_attr_probe",
    "_pyir_spec_note_fabricated_bake",
    "_pyir_spec_record_write",
    "_pyir_spec_record_unbind",
    "_pyir_import_is_cached",
    "_pyir_spec_record_import",
    "_pyir_spec_structural_amend",
    "_pyir_stamp_rewritten",
    "_pyir_callee_is_rewritten",
    "_pyir_spec_boundary_closure_read",
    "_pyir_boundary_taken_defaults",
    "_pyir_register_taken_default_holders",
    "_pyir_spec_boundary_default_reads",
    "_pyir_registry_candidate_objects",
    "_set_slot_mv",
    "_iter_owner_slot_mvs",
    "_PyirGenEventSuppress",
    "_pyir_gen_events_suppressed",
    "_pyir_is_generation_compound",
    "_pyir_keepalive_generation_obj",
    "_pyir_record_compound_binding",
    "_pyir_record_rebind_ref_cell",
    "_pyir_record_generation_rebind",
    "_pyir_complete_generation_rebind_cells",
    "_pyir_raise_superseded",
    "_pyir_check_superseded_owner_write",
    "_pyir_check_superseded_wrapper_load",
    "_pyir_generation_read_checks",
    "_pyir_record_cf_attr_first_def",
    "_pyir_update_cf_attr_first_def_on_write",
    "_pyir_check_cf_attr_first_def_read",
    "_attach_mutable_ref",
    "_pyir_adopt_live_place_cell",
    "_pyir_place_is_index_sibling",
    "_pyir_route_restructured_tuple_leaves",
    "_pyir_refuse_superseded_row_serve",
    "_fresh_wrapper",
    "_same_ir_value",
    "_raw_backing_ir_value",
    "_as_arith_capable_scalar_leaf",
    "_value_dominates_current_ip",
    "_op_is_inside_op",
    "_block_strictly_inside",
    "_block_inside_op",
    "_pyir_write_in_if_arms_of",
    "_pyir_check_arm_local_escape",
    "_ir_value_defined_inside_op",
    "_op_has_enclosing_loop",
    "_innermost_enclosing_loop_op_at_ip",
    "_loop_free_enclosing_if_ops_at_ip",
    "_meta_use_in_sibling_if_region",
    "_safe_instance_dict",
    "_slots_member_descriptors",
    "_has_instance_storage",
    "_instance_storage_items",
    "MutableValue",
    "_ref_dominates_whole_function",
    "_get_instance_attrs",
    "_implements_dynamic_expression",
    "_rebuild_tuple_like",
    "_is_compound_single_leaf",
    "_check_all_fields_decomposable",
    "_flatten_tuple",
    "_pyir_assign_simple",
    "_pyir_record_fresh_object_leaf_first_defs",
    "_subobject_is_ctor_private",
    "_record_fresh_leaf_first_defs_walk",
    "_record_meta_primitive_first_def",
    "_mlir_type_or_none",
    "_staged_type_changed",
    "_pyir_lookup_slot_from_value",
    "_pyir_value_tracked_by_accessible_ref",
    "_pyir_row_load_type_mismatch",
    "_load_as_dsl",
    "_clear_slot_mv",
    "_pyir_retire_place_row",
    "_pyir_region_fresh_raw",
    "_pyir_refresh_cell_read",
    "_pyir_recovery_holder_pairs",
    "_pyir_meta_primitive_value",
    "_pyir_snapshot_registry_meta_slots",
    "_pyir_verify_registry_meta_slots",
    "_PYIR_OPAQUE_OWNER_AUDITS",
    "_pyir_opaque_owner_key_sets",
    "_pyir_arm_opaque_owner_audit",
    "_pyir_verify_opaque_owner_audits",
    "_ref_lives_in_strictly_enclosing_block",
    "_carries_foreign_slot_binding",
    "_freeze_foreign_slot_binding",
    "_pyir_same_ref_reload",
    "_is_opaque_leaf_type",
    "_pyir_ir_type_is_opaque",
    "_pyir_extract_leaf_values",
    "_pyir_is_carryable_tuple",
    "_pyir_extract_any_leaf_values",
    "_pyir_new_from_mlir_values_any",
    "_is_opaque_leaf_value_tree",
    "_value_trees_different_prototype",
    "_has_accessible_loop_carried_ref",
    "_pyir_skip_trapped_child_region_writeback",
    "_pyir_walk_ir_value_holders",
    "_walk_ir_value_holders_into",
    "_pyir_build_gather_segment",
    "_is_self_leaf_record",
    "_self_leaf_snapshot",
    "_is_numeric_leaf_holder",
    "_pyir_record_promoted_place_leaf",
    "_pyir_reload_stale_staged_attr_leaves",
    "_pyir_repair_captured_escaped_leaves",
    "_pyir_repair_region_escaped_leaves",
    "_pyir_repair_region_escaped_tuple_leaves",
    "_pyir_reload_trapped_tuple_leaf",
    "_pyir_local_place_for_name",
    "_pyir_region_carry_place_for",
    "_pyir_adopt_region_carry_ref",
    "_pyir_adopt_d1_carry_cell",
    "_pyir_single_opaque_extract_leaf",
    "_pyir_pair_place_cell_handle",
    "_pyir_place_opaque_rebind_choke",
    "_pyir_memref_alloc_rooted_inside_region",
    "_pyir_value_is_inner_loop_carried",
    "_pyir_holder_walks_align",
    "_pyir_resolve_loop_leaf_updates",
    "_pyir_load_dominates_use",
    "_pyir_typed_update_is_advance",
    "_pyir_slot_stored_in_body",
    "_pyir_ref_loaded_inside_op",
    "_pyir_unwrap_meta_primitive",
    "_pyir_walk_meta_holders",
    "_pyir_restore_region_meta",
    "_walk_meta_numeric_leaf_holders",
    "_pyir_restore_meta_numeric_leaves",
    "_is_untracked_post_region_binding",
]
