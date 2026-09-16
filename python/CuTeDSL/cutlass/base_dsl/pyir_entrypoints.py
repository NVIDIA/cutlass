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


"""PyIR runtime -- entrypoints layer; see facade for the public surface."""

from .pyir_threading import *  # noqa: F401,F403  (re-export lower layers up the chain)

# -- BEGIN explicit imports for the type checker (do not edit the list by hand;
# it mirrors names the chain re-exports at runtime via the wildcard + dynamic
# ``__all__`` above, which a static type checker cannot evaluate -- so every
# name is also imported explicitly from the layer that DEFINES it). Purely
# additive: the wildcard import stays the runtime source of truth.
from .pyir_state import (  # noqa: F401
    Any,
    DSLUserCodeError,
    DiagId,
    _PYIR_DICT_MUTATORS,
    _PYIR_LIST_MUTATORS,
    _PYIR_READ_SIMPLE_SENTINEL,
    _PYIR_SET_MUTATORS,
    _PYIR_SKIP,
    _current_fn_id,
    _is_staged_value,
    _meta_uses,
    _slot_first_def_block,
    _slot_first_def_depth,
    _slot_first_def_depth_any,
    _slot_first_def_inside_cf,
    _slot_mvs,
    _slot_pending_store,
    _slot_refs,
    assign_meta_staged_check,
    get_staged_cf_depth,
    ir,
    is_auto_m2s_enabled,
    is_inside_constexpr_loop,
    is_inside_locally_staged_cf,
    is_inside_staged_cf,
    log,
    pyir,
)
from .pyir_core import (  # noqa: F401
    MutableValue,
    _WatchedM,
    _attach_mutable_ref,
    _auto_promote_primitive,
    _can_create_ref,
    _clear_slot_mv,
    _create_ref,
    _emit_constant_at_ip,
    _fresh_wrapper,
    _get_instance_attrs,
    _get_slot_mv,
    _is_boolean_like,
    _is_memref_like,
    _is_vector_like,
    _iter_slot_mvs_for_pyir_read,
    _load_as_dsl,
    _make_slot_key,
    _mlir_type_or_none,
    _pyir_assign_simple,
    _set_slot_mv,
    _slot_storage_available,
    _staged_type_changed,
)
from .pyir_corewalk import (  # noqa: F401
    _has_any_staged_content,
    _has_decomposable_staged_fields,
)
from .pyir_threading import (  # noqa: F401
    _meta_promote_slot,
)
# -- END explicit imports for the type checker

import sys

from typing import TypeVar

_CM = TypeVar("_CM")


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
    if kind == "list":
        # A list mutator (append/extend/insert/pop/...) crossing a region
        # boundary changes the list SHAPE; the single trace bakes only pass 0.
        raise DSLUserCodeError(
            DiagId.CONTAINER_LIST_SHAPE_MUTATED,
            var=container_repr,
            filename=filename,
            lineno=lineno,
        )
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


def pyir_tag_pending_writes(*specs: "tuple[str, Any, Any]") -> None:
    """Tag slots in a staged region's SYNTACTIC write-set as pending-store.

    Emitted at the top of ``while_before_block`` for every attr/subscript
    the while BODY writes whose owner is readable in the condition scope
    (plus the plain-name write_args).  The condition evaluates BEFORE the
    body's first store lands, so consumers that must decide fold-vs-stage
    at that point (``_pyir_while_cond``) need the write-set up front --
    otherwise ``while c.v < 17: c.v += 1`` bakes ``scf.condition(true)``
    from the trace-time fold: an unkillable runtime hang.  Each spec is
    ``(dotted_name, owner_or_None, slot_or_None)``.
    """
    if not is_inside_staged_cf() or not is_auto_m2s_enabled():
        return
    fn_id = _current_fn_id()
    for dotted, owner, slot_name in specs:
        slot = _make_slot_key(dotted, owner, slot_name, fn_id)
        if slot is not None:
            _slot_pending_store.add(slot)


def pyir_promote_loop_body_arg(target_name: str, current_value: object) -> object:
    """Auto-promote a Python-primitive write_arg at loop-body entry.

    If a loop-body reads a Python primitive (bool/int/float) that is later
    re-stored in the same iteration, the read site bakes the trace-time
    constant instead of loading from the loop-carried ref.  Calling
    ``pyir_read`` at body entry forces the slot to materialise so
    subsequent reads inside the body load from it.

    A genuinely staged SCALAR write_arg (created outside the loop and read
    before its first in-body write) is reloaded from its ref here so the body
    observes the loop-carried value -- gated on the value being staged (WS4-B
    below), NOT on AUTO_M2S.  Memref-backed and vector values are left as-is.
    """
    if not is_inside_staged_cf():
        return current_value
    if not is_auto_m2s_enabled() and (
        not _is_staged_value(current_value) or _is_memref_like(current_value)
    ):
        return current_value
    if _is_staged_value(current_value):
        # Already-staged scalar: reload from its ref at body entry so in-body reads
        # emitted BEFORE the first write observe the loop-carried value instead of
        # the cached trace-entry SSA.  Restricted to ref-capable, non-vector,
        # non-memref scalars -- the ref lands at the value's dominating def, so no
        # new placement order is introduced.
        if (
            _can_create_ref(current_value)
            and not _is_vector_like(current_value)
            and not _is_memref_like(current_value)
        ):
            return pyir_read(target_name, current_value)
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
                    new_ir = _emit_constant_at_ip(new_value)
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
                        new_ir = _emit_constant_at_ip(new_value)
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


def _subscript_container_is_dsl_managed(container: object) -> bool:
    """Whether *container*'s type builds its subscript writes as IR directly.

    DSL-managed containers (cutlass.Array, tensors, shared memory) lower
    ``container[k] = v`` to real IR store ops, so they stay on the untracked
    native path.  Plain Python mutable containers (bytearray / array.array /
    collections.deque / an author class with __setitem__) fold the write at
    trace time -- inside staged CF a silent freeze -- so they are rejected.
    is_dsl_internal_code alone misclassifies stdlib types (bytearray in
    builtins, array in array, deque in collections are all in
    sys.stdlib_module_names), so exclude stdlib explicitly.
    """
    tp = type(container)
    module_name = getattr(tp, "__module__", "") or ""
    top = module_name.split(".", 1)[0]
    if top and top in getattr(sys, "stdlib_module_names", frozenset()):
        return False
    # DSL-managed containers live in the ``cutlass`` DSL package; author code
    # (module ``__main__`` / a user file) and stdlib are not managed. Self
    # contained approximation of ``is_dsl_internal_code`` (which master lacks).
    return top == "cutlass"


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
        # A plain Python mutable container (bytearray / array.array / deque, or
        # an author class with __setitem__) folds the subscript write at trace
        # time; inside auto-M2S staged CF that silently freezes it.  A
        # DSL-managed container lowers to real IR and stays on the native path.
        # Constexpr scopes realize the write deterministically -> exempt.
        if (
            is_auto_m2s_enabled()
            and is_inside_staged_cf()
            and not is_inside_constexpr_loop()
            and not _subscript_container_is_dsl_managed(container)
        ):
            raise DSLUserCodeError(
                DiagId.CONTAINER_SUBSCRIPT_WRITE_UNTRACKED,
                py_type=type(container).__name__,
            )
        return _PYIR_SKIP
    if (
        type(container) is not dict
        and hasattr(type(container), "__missing__")
        and is_inside_staged_cf()
        and not is_inside_constexpr_loop()
    ):
        # A dict SUBCLASS with __missing__ (Counter, defaultdict) materialises
        # keys implicitly on access; that key-set change cannot be reproduced
        # in staged IR. Plain dict / OrderedDict (no __missing__) stay tracked.
        raise DSLUserCodeError(DiagId.CONTAINER_DICT_KEY_SET_MUTATED, var=target_name)
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


def with_ctxmgr_check(cm: _CM) -> _CM:
    """Trace-time guard for ``with`` context managers inside staged CF.

    A ``with`` whose ``__enter__``/``__exit__`` are plain Python user functions
    runs those dunders ONCE while the kernel is traced.  Inside a staged
    for/while/if the block would (in Python) run them on every pass / only on
    the taken path, so their effects on hidden state are frozen at the first
    trace -- a silent miscompile.  Reject that; pass through decorated dunders
    (jit-traced per pass) and DSL-internal / stdlib context managers
    (e.g. ``contextlib.suppress``).

    A context-manager class carrying the ``__dsl_trace_time_ctxmgr__ = True``
    opt-in marker asserts its dunders are trace-time-only bookkeeping and is
    waved through: for such a manager, running the dunders once at trace time
    is the correct semantics.

    Returns *cm* unchanged so ``with with_ctxmgr_check(EXPR) as x`` behaves
    exactly like ``with EXPR as x`` in every accepted case.
    """
    try:
        from .multi_stage_manager import is_inside_staged_cf
    except Exception:  # noqa: BLE001 -- staging machinery absent: nothing to guard
        return cm
    # A top-level ``with`` runs its dunders exactly once at trace time, which
    # matches Python; only staged re-execution / conditional execution freezes
    # them.
    if not is_inside_staged_cf():
        return cm
    from .common import is_dsl_internal_code  # inline: break the import cycle
    from .ast_helpers import _is_dsl_traced_callable

    tp = type(cm)

    # Explicit opt-in: a manager whose dunders do only trace-time bookkeeping
    # is correct to run once at trace time.
    if getattr(tp, "__dsl_trace_time_ctxmgr__", False):
        return cm

    # A generator-based ``@contextmanager`` hides its trace-time-frozen work in
    # the USER generator body, while its ``__enter__``/``__exit__`` live in
    # ``contextlib`` (stdlib) -- so the type-dunder check below would wrongly
    # wave it through.  Classify by the generator's own origin (``cm.gen``): a
    # user-code generator run inside staged CF freezes its ``yield``-straddling
    # side effects at the first trace and must be rejected; an internal / stdlib
    # generator manager is allowed.
    gen = getattr(cm, "gen", None)
    gen_code = getattr(gen, "gi_code", None)
    if gen_code is not None:
        gen_frame = getattr(gen, "gi_frame", None)
        gen_module = ""
        if gen_frame is not None:
            gen_module = gen_frame.f_globals.get("__name__", "") or ""
        if not is_dsl_internal_code(getattr(gen_code, "co_filename", None), gen_module):
            raise DSLUserCodeError(
                DiagId.SCOPE_CTXMGR_TRACE_ONLY,
                ctx_type=tp.__name__,
            )
        return cm
    for dunder in ("__enter__", "__exit__"):
        fn = getattr(tp, dunder, None)
        if fn is None:
            continue
        code = getattr(fn, "__code__", None)
        dunder_is_internal = is_dsl_internal_code(
            getattr(code, "co_filename", None), getattr(fn, "__module__", "") or ""
        )
        if _is_dsl_traced_callable(fn) or dunder_is_internal:
            continue
        raise DSLUserCodeError(
            DiagId.SCOPE_CTXMGR_TRACE_ONLY,
            ctx_type=tp.__name__,
        )
    return cm


def _pyir_while_cond(cond: object) -> object:
    """Lift a ``_WatchedM`` while condition to its staged DSL Numeric.

    The while executor truth-tests the before-block's condition; a watched
    fold bakes ``scf.condition(true)`` -- an unkillable runtime hang once
    the body mutates the slot.  Lift when a connected slot is genuinely
    promoted (in ``_slot_refs``) or in the region's syntactic write-set
    (tagged up front by ``pyir_tag_pending_writes`` in the before-block
    prologue); otherwise keep the fold with a forced witness so a later
    store still raises the two-location stale diagnostic instead of hanging.

    NOTE (master bridge): the donor keyed "already promoted" on
    ``_slot_stored`` (D1v2, absent here); master tracks promotion as
    membership in ``_slot_refs`` (set in ``_meta_promote_slot``), so the
    gate uses ``_slot_refs.keys()`` in its place.
    """
    from .pyir_core import (
        _WatchedM,
        _record_fold_witness,
        _watched_to_dsl,
        _wrapper_slots,
    )
    from .pyir_state import (
        _slot_pending_store,
        _slot_refs,
    )

    if not is_inside_staged_cf() or not isinstance(cond, _WatchedM):
        return cond
    if not (_wrapper_slots(cond) & (_slot_refs.keys() | _slot_pending_store)):
        _record_fold_witness(
            cond,
            None,
            cond.python_value,
            "a Python `if`/`while`/`not` test",
            force_consumer=True,
        )
        return cond
    try:
        return _watched_to_dsl(cond)
    except Exception:  # noqa: BLE001 — keep the fold on lift failure
        return cond


__all__ = [name for name in list(globals()) if not name.startswith("__")]
