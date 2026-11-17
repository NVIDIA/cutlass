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

import array as _array_module
import collections as _collections_module
import dis as _dis_module
import inspect as _inspect_module
import weakref

from . import pyir_class_facts as _pyir_class_facts
from .pyir_state import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_core import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_core import (  # names kept out of the wildcard chain
    _pyir_arm_path_covers,
    _pyir_current_region_arm_path,
    _pyir_holder_read,
    _pyir_innermost_enclosing_region_op_at_ip,
)
from .pyir_corewalk import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_loop_carry import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_state import _Sentinel


def _decompose_tuple(
    field_key: str,
    old_tuple: tuple,
    new_tuple: tuple,
    filename: "str | None",
    lineno: "int | None",
    _visited: set[int],
    *,
    owner: Any = None,
    slot_name: Any = None,
) -> tuple:
    """Decompose parallel tuples element-wise.

    Returns a new tuple with ``pyir_assign``-updated elements.

    *owner* / *slot_name* carry the parent's slot key down so per-element
    refs key on ``(owner, _place_seg_child(slot_name, i))`` -- matching the key
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
        elem_slot = _place_seg_child(slot_name, i) if has_slot_ctx else None

        if _is_staged_value(old_elem) and _can_carry_leaf_ref(old_elem):
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
            _has_instance_storage(old_elem)
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

        elif (
            isinstance(old_elem, (int, float, bool, _WatchedM))
            and _is_staged_value(new_elem)
            and _can_carry_leaf_ref(new_elem)
        ):
            # M->S leaf: a primitive loop-init element the body made staged. Route through
            # ``pyir_assign`` for a stable loop-carried ref instead of a poison-init ref.
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

        elif old_elem is None or isinstance(old_elem, (int, float, bool, str, bytes)):
            result.append(new_elem)

        else:
            log().warning(
                "[decompose_tuple] '%s' element %d not decomposable, copying",
                field_key,
                i,
            )
            result.append(new_elem)

    # Preserve a namedtuple's subtype: ``tuple(result)`` would strip field names,
    # breaking later ``obj.field`` reads. Use the new tuple as the template.
    return _rebuild_tuple_like(new_tuple, result)


def _pyir_regions_since_binding(slot: Any) -> "tuple[int, ...]":
    """Entry tokens of the open staged regions entered AFTER the place *slot*
    was last bound to a compound object, outermost first.  A place the choke
    never saw bound (a parameter) counts as bound when its function scope
    started; an unseen owner slot counts as bound before every open region."""
    bound_in = _PYIR_SLOT_BIND_REGIONS.get(slot)
    if bound_in is None:
        bound_in = ()
        if isinstance(slot, tuple) and slot and slot[0] == "local":
            bound_in = _PYIR_SCOPE_REGION_BASE.get(slot[1], ())
    return tuple(tok for tok in _pyir_open_region_tokens() if tok not in bound_in)


def _pyir_identity_repoint_obstacle(
    slot: Any,
    target_name: Any,
    owner: Any,
    slot_name: Any,
    old_value: Any,
    new_value: Any,
) -> "tuple[str, str] | None":
    """Why a re-point of the place *slot* from *old_value* to *new_value* (an
    object that pre-exists the innermost open staged region) is NOT a
    trace-time static identity, as ``(detail, hint)`` for the refusal, or
    ``None`` when it is static.

    Static means: the place is a bare local that no other code can read (not
    an attribute or container entry, not a parameter, not a name a nested
    scope refers to); every region entered since the place's binding is a
    staged loop body that provably runs at least once, in which the place is
    dead on entry (``_collect_dead_on_entry_paths``), that *new_value*
    already existed at, and in which *old_value* was not rebuilt by a
    body-born rebind; and *new_value* has *old_value*'s class."""
    name = str(target_name)
    if owner is not None or slot_name is not None:
        return (
            f"`{name}` is an attribute or container entry that other holders of"
            " the object can read",
            "Re-point a plain local to the object instead, and use that local.",
        )
    between = _pyir_regions_since_binding(slot)
    loops = {facts["entry"]: facts for facts in _pyir_open_loop_body_facts}
    if any(tok not in loops for tok in between):
        # Loop-free too: the region close would thread the chosen object's
        # values into the entry object, which other bindings still see.
        return (
            "inside a run-time if",
            f"Re-point `{name}` before the `if`, or choose values, not objects "
            "(`a.idx if cond else b.idx`).",
        )
    for tok in between:
        facts = loops[tok]
        if not facts["guaranteed_trip"]:
            return (
                f"the enclosing {facts['kind']} may run zero times",
                "Make the loop run at least once at trace time: a constant trip "
                "count, or `range(..., at_least_once=True)`.",
            )
    for tok in between:
        verdict = loops[tok]["dead_on_entry"].get(name, "read")
        if verdict == "captured":
            return (
                f"`{name}` is a parameter or a name a nested function, lambda or"
                " comprehension refers to",
                "Re-point a fresh local instead (`cur = other`).",
            )
        if verdict == "swap":
            return (
                "a swap",
                "Swap through fresh copies (`a, b = b.clone(), a.clone()`), or swap "
                "the fields.",
            )
        if verdict == "read":
            return (
                f"`{name}` is read earlier in the same body",
                f"Make the re-point the first use of `{name}` in the loop body, or "
                "re-point before the loop.",
            )
        if verdict != "dead":
            where = verdict.partition(":")[2]
            return (
                f"`{name}` is first stored inside {where}, which may not run on"
                " every pass",
                "Make the re-point an unconditional statement of the loop body, "
                f"or re-point `{name}` before the loop.",
            )
    if between and _pyir_region_recarried(old_value):
        return (
            f"`{name}` was rebound to a new object earlier in this body",
            "Build the new object under another name.",
        )
    if between and not _pyir_holder_preexists_region(new_value, between[0]):
        return (
            f"the object `{name}` is re-pointed to was created inside an enclosing"
            " loop body",
            "Re-point to an object created before the outermost loop.",
        )
    if type(new_value) is not type(old_value):
        return (
            f"`{name}` is re-pointed to an object of a different class "
            f"(`{type(old_value).__name__}` to `{type(new_value).__name__}`)",
            "Keep one class per name: bind the other object to a new name.",
        )
    return None


def _pyir_select_join_owns_rebind(old_value: Any, new_value: Any) -> bool:
    """Whether the whole-object branch-select join of ``_assign_m2m_compound``
    owns this rebind: a loop-free run-time ``if`` selecting between two
    value-tree objects whose compile-time fields differ.  The join rebuilds
    the binding from the entry prototype at the ``if`` close, as the pytree
    frontend does, and writes into neither object, so it is not a re-point
    of the name.  Mirrors that arm's gate."""
    return (
        _implements_dynamic_expression(old_value)
        and _innermost_enclosing_loop_op_at_ip() is None
        and bool(_loop_free_enclosing_if_ops_at_ip())
        and _value_tree_prototype_mismatch(old_value, new_value) is not None
    )


def _pyir_judge_identity_repoint(
    target_name: Any,
    owner: Any,
    slot_name: Any,
    old_value: Any,
    new_value: Any,
    filename: "str | None",
    lineno: "int | None",
    stmt_id: "int | None",
) -> bool:
    """Classify a whole-object rebind of a compound place inside staged
    control flow; True when it is an ADMITTED identity re-point.

    A replacement constructed inside the open region (the advance pattern,
    ``clone()``, a ctor) is not judged here: its fields are carried into the
    place's own object as before (False).  A replacement that pre-exists the
    region is a Python re-point of the name: admitted (the caller binds the
    replacement itself, no field copy) when the post-region identity is
    trace-time static (see :func:`_pyir_identity_repoint_obstacle`), else
    refused, as are a swap within one unpack statement and a run-time
    ``x if cond else y`` selection between pre-existing objects."""
    if (
        old_value is None
        or new_value is old_value
        or not is_inside_staged_cf()
        or not _pyir_open_region_tokens()
        or isinstance(new_value, (list, tuple, dict, set, frozenset))
        or not _pyir_is_generation_compound(old_value)
        or not _pyir_is_generation_compound(new_value)
        or not (
            _has_any_staged_content(old_value) or _has_any_staged_content(new_value)
        )
    ):
        return False
    refusal: "tuple[str, str] | None" = None
    rebind_cls: "type" = type(new_value)
    selection_cls = (
        _pyir_selection_rebind_candidates(new_value, old_value)
        if _PYIR_STAGED_SELECTION_ARMS
        else None
    )
    admitted = False
    if stmt_id is not None and _pyir_stmt_rebind_overwrote(new_value, stmt_id):
        refusal = (
            "a swap",
            "Swap through fresh copies (`a, b = b.clone(), a.clone()`), or swap "
            "the fields.",
        )
    elif selection_cls is not None:
        refusal = (
            "a run-time selection",
            "Choose values, not objects (`a.idx if cond else b.idx`), or choose "
            "at trace time with `cutlass.const_expr(cond)`.",
        )
        rebind_cls = selection_cls
    elif _pyir_select_join_owns_rebind(old_value, new_value):
        pass
    elif _pyir_holder_preexists_open_region(new_value):
        slot = _make_slot_key(target_name, owner, slot_name)
        refusal = _pyir_identity_repoint_obstacle(
            slot, target_name, owner, slot_name, old_value, new_value
        )
        admitted = refusal is None
    elif _PYIR_SLOT_REPOINTED:
        # A body-born replacement is carried by copying its fields into the
        # object the place names; after an identity re-point that object is
        # a pre-existing one other bindings see, and Python leaves it alone.
        slot = _make_slot_key(target_name, owner, slot_name)
        if slot is not None and _PYIR_SLOT_REPOINTED.get(slot) is old_value:
            refusal = (
                f"`{target_name}` names a pre-existing `{type(old_value).__name__}`"
                " it was re-pointed to, and a new object built in staged control"
                " flow can only replace a name's own object",
                "Build the new object under another name, or bind a copy "
                f"(`{target_name} = other.clone()`) instead of re-pointing.",
            )
    if refusal is not None:
        raise DSLUserCodeError(
            DiagId.SCOPE_REBIND_IDENTITY_RUNTIME_DEPENDENT,
            filename=filename,
            lineno=lineno,
            var=str(target_name),
            cls=rebind_cls.__name__,
            detail=refusal[0],
            hint=refusal[1],
        )
    if stmt_id is not None:
        _pyir_stmt_rebind_note(old_value, stmt_id)
    if admitted:
        log().info(
            "[pyir_assign] '%s' re-pointed to a pre-existing %s -> identity "
            "re-point (no field copy)",
            target_name,
            type(new_value).__name__,
        )
    return admitted


def _unalias_tuple_leaves(value: tuple) -> tuple:
    """LAW-2 at a bare-local tuple binding: give the tuple its OWN ref-supported
    leaf wrappers.

    A tuple literal hands its elements straight over from whatever produced
    them, so a leaf is routinely the live binding of ANOTHER place -- ``coord =
    (i, base, head_idx, zero)`` puts the caller's ``head_idx`` object into the
    tuple.  The leaf's read-minted row then adopts that very object as its
    template, and every later use of ``head_idx`` follows the row (V-2 serves
    the template by identity) into a cell stored only where the container was
    bound, so a use on a path the container binding does not reach reads the
    row's placeholder init.

    A fresh wrapper shares the leaf's SSA, so the tuple's own value is
    unchanged; only the object identity the row adopts differs.  Leaves whose
    type is not ``pyir.ref``-supported (tensors, tensor maps) keep their object:
    their carry story is the value-tree walk's, not a leaf cell's, and a tuple
    with nothing to unalias is returned as-is.  A tuple that DOES own new leaf
    wrappers is a new object, so an alias binding of one (``b = a``) no longer
    answers ``b is a`` -- the same wrapper-identity break the scalar rule at the
    first-def choke already takes, and the reason ``is`` on a tracked value is
    refused outright.
    """
    leaves = [
        (
            _unalias_tuple_leaves(elem)
            if isinstance(elem, tuple)
            else (
                _fresh_wrapper(elem)
                if _is_staged_value(elem) and _can_create_ref(elem)
                else elem
            )
        )
        for elem in value
    ]
    if all(new is old for new, old in zip(leaves, value)):
        return value
    return _rebuild_tuple_like(value, leaves)


def _pyir_decompose_container_entries(
    field_key: str,
    watched: Any,
    filename: "str | None",
    lineno: "int | None",
    entries: Any,
    setter: Any,
) -> None:
    """Per-entry M->M decomposition shared by the dict/list arms of
    :func:`_decompose_m2m_assign`: identity-equal entries are skipped, a
    staged leaf entry routes through the owner-keyed pre-read (publishing the
    entry cell under the subscript slot so the assign resolves the SAME cell)
    then ``pyir_assign``, and anything else is written back raw.  *entries*
    yields lazily so each entry is read only after the previous one's write."""
    for _k, _old_e, _new_e in entries:
        if _old_e is _new_e:
            continue
        if _is_staged_value(_old_e) and _can_carry_leaf_ref(_old_e):
            _old_e = pyir_read(
                f"{field_key}[{_k!r}]",
                _old_e,
                owner=watched,
                slot_name=_k,
            )
            setter(
                watched,
                _k,
                pyir_assign(
                    f"{field_key}[{_k!r}]",
                    _old_e,
                    _new_e,
                    filename,
                    lineno,
                    owner=watched,
                    slot_name=_k,
                ),
            )
        else:
            setter(watched, _k, _new_e)


def _decompose_m2m_assign(
    target_name: str,
    old_obj: object,
    new_obj: object,
    filename: "str | None",
    lineno: "int | None",
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

        if _is_staged_value(old_field) and _can_carry_leaf_ref(old_field):
            # Carry slot context so per-field ref identity keys on ``(old_obj, attr_name)``,
            # avoiding a shared ref for fields that happen to share a Python value.
            result = pyir_assign(
                field_key,
                old_field,
                new_field,
                filename,
                lineno,
                owner=old_obj,
                slot_name=attr_name,
            )
            _pyir_setattr_raw(old_obj, attr_name, result)

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
            _pyir_setattr_raw(old_obj, attr_name, new_tuple)

        elif (
            isinstance(old_field, dict)
            and isinstance(new_field, dict)
            and set(dict.keys(old_field)) == set(dict.keys(new_field))
        ):
            # Dict field with an IDENTICAL key set: decompose per entry onto the
            # dict's subscript legs; the old dict stays the binding carrier.
            _watched = _pyir_adopt_dict_value(
                old_obj, attr_name, old_field, label=field_key
            )
            _pyir_decompose_container_entries(
                field_key,
                _watched,
                filename,
                lineno,
                entries=(
                    (
                        _k,
                        dict.__getitem__(_watched, _k),
                        dict.__getitem__(new_field, _k),
                    )
                    for _k in list(dict.keys(_watched))
                ),
                setter=dict.__setitem__,
            )

        elif (
            isinstance(old_field, list)
            and isinstance(new_field, list)
            and len(old_field) == len(new_field)
        ):
            # List field with an IDENTICAL length: decompose per element onto the
            # list's integer legs; the old list stays the binding carrier.
            _watched_l = _pyir_adopt_list_value(
                old_obj, attr_name, old_field, label=field_key
            )
            _pyir_decompose_container_entries(
                field_key,
                _watched_l,
                filename,
                lineno,
                entries=(
                    (_i, list.__getitem__(_watched_l, _i), new_field[_i])
                    for _i in range(list.__len__(_watched_l))
                ),
                setter=list.__setitem__,
            )

        elif (
            _has_instance_storage(old_field)
            and not _is_staged_value(old_field)
            and not isinstance(old_field, (int, float, bool, str, bytes, type))
            and type(old_field) is type(new_field)
            and _has_decomposable_staged_fields(old_field)
        ):
            # Decomposable nested compound: recurse so its staged scalars carry through
            # ``pyir.ref`` slots. A non-decomposable field falls through to copy-as-is below.
            _decompose_m2m_assign(
                field_key,
                old_field,
                new_field,
                filename,
                lineno,
                _visited=_visited,
            )

        elif old_field is None or isinstance(old_field, (int, float, bool, str, bytes)):
            # A meta-primitive field must stay constant inside staged CF (the
            # body is traced once) -- route a change to a diagnostic instead.

            # Meta-int wrappers inherit from ``int`` but report a distinct
            # ``type()``: use ``isinstance`` both ways, not type identity.
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
                    DiagId.PHASE_META_FIELD_CHANGED_IN_CF,
                    filename=filename,
                    lineno=lineno,
                    owner_class=type(old_obj).__name__,
                    attr=attr_name,
                    old_value=old_field,
                    new_value=new_field,
                )
            _pyir_setattr_raw(old_obj, attr_name, new_field)

        else:
            log().warning(
                "[decompose_m2m] '%s' attr '%s' (type %s) not decomposable, "
                "copying directly",
                target_name,
                attr_name,
                type(old_field).__name__,
            )
            _pyir_setattr_raw(old_obj, attr_name, new_field)


def _pyir_check_no_complex_m2m_call(
    container: object,
    method_name: str,
    container_repr: str,
    filename: str,
    lineno: int,
    mutating_values: "list | None" = None,
) -> None:
    """Reject in-place mutation of a meta ``list`` / ``dict`` / ``set`` /
    ``collections.deque`` / ``bytearray`` while inside staged control flow.

    The body of a staged loop / ``scf.if`` is traced exactly once, so a
    ``a.append(x)`` (or any other mutating method) would silently bake
    only the first iteration's mutation into the IR -- the per-iteration
    side effects disappear.  Raise a ``DSLUserCodeError`` with a fix-it
    pointing at slot-backed containers or DSL collection types.  A plain
    Python ``list`` / ``dict`` / ``set`` is never carried by the slot
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
        # Only ``add`` with only META values is exempt: the membership-gated
        # once-per-key idiom (``if k not in seen: seen.add(k)``) is compile-time
        # bookkeeping whose trace-once effect matches Python for every executed
        # iteration.  Every other set mutator refuses even with meta-only
        # values: its trace-once effect is observable post-loop as a phantom
        # (a zero-trip loop still sees ``discard``/``clear``/``pop`` applied),
        # and ``clear``/``pop`` would slip through vacuously with no values.
        if (
            method_name == "add"
            and mutating_values is not None
            and not any(_is_staged_value(v) for v in mutating_values)
        ):
            return
    elif isinstance(container, _collections_module.deque):
        if method_name not in _PYIR_DEQUE_MUTATORS:
            return
        kind = "deque"
    elif isinstance(container, bytearray):
        if method_name not in _PYIR_BYTEARRAY_MUTATORS:
            return
        kind = "bytearray"
    else:
        return
    raise DSLUserCodeError(
        DiagId.UNSUP_META_CONTAINER_MUTATION,
        filename=filename,
        lineno=lineno,
        container=container_repr,
        method=method_name,
        kind=kind,
    )


def _pyir_freeze_staged_container_inserts(
    container: object,
    method_name: str,
) -> None:
    """Freeze foreign-slot-bound STAGED elements right after an insert into a meta
    container in a constexpr loop, pinning each at its insertion-time SSA."""
    if pyir is None or not is_inside_constexpr_loop():
        return
    if isinstance(container, list):
        if method_name not in _PYIR_LIST_INSERT_MUTATORS:
            return
        for idx, elem in enumerate(container):
            if _carries_foreign_slot_binding(elem):
                container[idx] = _freeze_foreign_slot_binding(
                    elem, "constexpr-loop container insert"
                )
    elif isinstance(container, dict):
        if method_name not in _PYIR_DICT_INSERT_MUTATORS:
            return
        for key, elem in list(container.items()):
            if _carries_foreign_slot_binding(elem):
                container[key] = _freeze_foreign_slot_binding(
                    elem, "constexpr-loop container insert"
                )


def pyir_promote_loop_body_arg(
    target_name: str,
    current_value: object,
    *,
    bare_first_use: bool = False,
    carried_attr_paths: "tuple[tuple[str, ...], ...]" = (),
    whole_rebound: bool = False,
    condition_bound: bool = False,
) -> object:
    """Materialise a loop-carried write_arg's ref at body entry so body reads
    load the carry, not the pre-loop SSA; ``bare_first_use`` = plain-use first
    read; ``condition_bound`` = a ``while``-condition walrus target with no
    binding before the loop (its placeholder is ``None``)."""
    if not is_inside_staged_cf():
        return current_value
    if condition_bound:
        # The condition's first-def choke minted the name's row inside the
        # before region (placeholder init at function entry, seed store at
        # the binding), so the body binds the name to a load of that row --
        # the value the condition just bound, as in Python.  No row means the
        # condition bound a value kind the first-def choke does not carry;
        # refuse with the pre-binding fix rather than serve the placeholder.
        mv = _pyir_condition_bound_row(target_name)
        if mv is None:
            src_file, src_line = _first_non_dsl_caller_location()
            raise DSLUserCodeError(
                DiagId.SCOPE_WALRUS_IN_WHILE_CONDITION,
                filename=src_file,
                lineno=src_line,
                name=target_name,
            )
        return _pyir_live_row_handle(target_name, mv, "condition-bound")
    # ``scf.while`` after-block re-load of the declared carried attr legs: the
    # before-block SSA the condition promotion rebound does not dominate here.
    if (
        carried_attr_paths
        and current_value is not None
        and not isinstance(current_value, (bool, int, float, str, bytes))
        and _has_instance_storage(current_value)
    ):
        _promote_carried_attr_legs(
            target_name, current_value, carried_attr_paths, force_promote_meta=False
        )
    if isinstance(current_value, tuple):
        # Recurse per element under the indexed slot key so each leaf carries as
        # its own iter_arg; ``bare_first_use`` gates per leaf, not wholesale.
        return _rebuild_tuple_like(
            current_value,
            [
                pyir_promote_loop_body_arg(
                    f"{target_name}[{i}]", elem, bare_first_use=bare_first_use
                )
                for i, elem in enumerate(current_value)
            ],
            region_carry=True,
        )
    if (
        whole_rebound
        and (type(current_value) is list or isinstance(current_value, _WatchedList))
        and current_staged_cf_depth() <= 1
    ):
        # Loop-carried WHOLE-rebound list: promote each meta-primitive element
        # through its owner-keyed subscript cell (outermost loop only; raw store-back).
        for _i in range(list.__len__(current_value)):  # type: ignore[arg-type]
            _elem = list.__getitem__(current_value, _i)  # type: ignore[arg-type]
            _init = _elem.python_value if isinstance(_elem, _WatchedM) else _elem
            if type(_init) not in (bool, int, float):
                continue
            _fresh = pyir_read(
                f"{target_name}[{_i}]",
                _elem,
                owner=current_value,
                slot_name=_i,
                force_promote_meta=True,
            )
            if _fresh is not _elem:
                list.__setitem__(current_value, _i, _fresh)  # type: ignore[arg-type]
        return current_value
    if ir is not None and isinstance(current_value, ir.Value):
        # Refuse a finalized-compilation raw before any admission probe
        # dereferences it (only ``.context`` is a safe probe on such a value).
        _pyir_refuse_stale_raw_carry(target_name, current_value, "loop-carried")
    if whole_rebound:
        # A bare local WHOLE-rebound in the body to an opaque handle
        # (pointer ping-pong, one-way re-point): the rebind choke stores
        # through the place cell, so body reads must load it too, or every
        # iteration consumes the pre-loop handle.  Bind the body name to a
        # region-entry load of the cell.  The emission-free raw probe gates
        # the admission predicate (whose leaf walk may emit for a compound).
        raw = _pyir_opaque_handle_raw(current_value)
        if raw is not None and _pyir_is_opaque_handle_binding(current_value):
            place = _make_slot_key(target_name, None, None)
            ref = _pyir_adopt_opaque_local_carry_cell(place, raw, current_value)
            if ref is None:
                raise DSLRuntimeError(
                    "PyIR emission self-check: the loop-carried handle "
                    f"'{target_name}' has no dominating anchor for its carry "
                    "cell; a body read would consume the pre-loop handle on "
                    "every iteration."
                )
            return _load_as_dsl(ref, place=place, stamp_place=True)
    # Vector wrappers subclass ir.Value but need the staged-value read below.
    if (
        ir is not None
        and isinstance(current_value, ir.Value)
        and not _is_vector_like(current_value)
    ):
        if isinstance(current_value.type, (ir.IntegerType, ir.FloatType)):
            # A raw scalar SSA write_arg is a loop-carried place: mint its
            # cell (the body's write choke stores raw SSA rebinds through the
            # same row) and serve body reads from it, so consumers read the
            # carried arg, not the pre-loop trace-time SSA.
            return _pyir_promote_raw_scalar_carry(target_name, current_value)
        return current_value
    if _is_staged_value(current_value):
        if not _can_create_ref(current_value):
            return current_value
        # Boolean/Vector args route through the generic read unconditionally:
        # it creates-or-reuses the place cell and returns a dominating load.
        if _is_boolean_like(current_value) or _is_vector_like(current_value):
            return pyir_read(target_name, current_value)
        if bare_first_use:
            # A plain-use first read of an SSA-backed scalar binds the body
            # NAME to a route handle on the place's live row (when one is
            # accessible), so every round reloads the carry instead of the
            # pre-loop object; other kinds (a memref handle, a literal) keep
            # their binding.
            raw = _raw_backing_ir_value(current_value)
            mv = (
                _get_slot_mv(None, target_name)
                if raw is not None
                and isinstance(raw.type, (ir.IntegerType, ir.FloatType))
                else None
            )
            if mv is not None and mv._ref is not None and mv._is_ref_accessible():
                return _pyir_live_row_handle(target_name, mv, "bare-first-use")
            # No row for the place: materialise the ref so the read loads the
            # carried value.
            if not _has_accessible_loop_carried_ref(target_name, current_value):
                return pyir_read(target_name, current_value)
        return current_value
    # Value-tree compounds are already carried per leaf; pass through.
    if not isinstance(current_value, (bool, int, float)):
        return current_value
    return _promote_loop_carried_meta(target_name, current_value)


def _pyir_live_row_handle(target_name: str, mv: "MutableValue", context: str) -> Any:
    """A route HANDLE on *mv*, the live row of loop-body name *target_name*: an
    untagged wrapper of the row's content with the row attached, so every
    read of the name reloads the row instead of retaining this entry load."""
    handle = _fresh_wrapper(mv.load())
    _attach_mutable_ref(handle, mv, f"{context} '{target_name}' body entry")
    return handle


_PYIR_PLACEHOLDER_INIT_ATTRS = (
    "pyir.placeholder_init",
    "pyir.placeholder_init_src_file",
    "pyir.placeholder_init_src_line",
)


def _pyir_condition_bound_row(target_name: str) -> "MutableValue | None":
    """The live row of a ``while``-condition-bound name with its placeholder
    marker taken off the init constant (the before region stores the cell on
    every round, so no load can observe the init); ``None`` when the place
    has no accessible row or the init is a ``ub.poison`` stand-in."""
    mv = _get_slot_mv(None, target_name)
    if mv is None or mv._ref is None or not mv._is_ref_accessible():
        return None
    ref = mv._ref
    try:
        init = ref.owner.operands[0]
        init_owner = init.owner
    except Exception:
        return None
    if isinstance(init_owner, ir.Block):
        return mv  # a block-argument init is a defined value already
    init_op = getattr(init_owner, "operation", init_owner)
    if init_op.name == "ub.poison":
        return None
    for key in _PYIR_PLACEHOLDER_INIT_ATTRS:
        if key in init_op.attributes:
            del init_op.attributes[key]
    return mv


def _pyir_record_fresh_entry_birth(owner: Any, slot_name: Any, entry: Any) -> None:
    """Record the current block as the F-BIRTHPOS fact of a region-born
    place's meta leaves -- a fresh container entry or an attribute first-def
    noted inside a staged body (tuples recurse per leaf).  Recording only, no
    ref: a never-promoted leaf stays a plain meta value."""
    if isinstance(entry, tuple):
        for i, elem in enumerate(entry):
            _pyir_record_fresh_entry_birth(owner, _place_seg_child(slot_name, i), elem)
        return
    payload = _pyir_unwrap_meta_primitive(entry)
    if payload is None or type(payload) not in (bool, int, float):
        return
    try:
        slot = _make_slot_key(None, owner, slot_name)
        block = ir.InsertionPoint.current.block
    except Exception:
        return
    if slot is None or slot in _slot_refs or slot in _slot_first_def_block:
        return
    _slot_first_def_inside_cf[slot] = True
    _slot_first_def_depth[slot] = current_staged_cf_depth()
    _slot_first_def_block[slot] = block
    _pyir_keepalive_generation_obj(owner)
    # Under a folded constant ``if`` arm the latch consumer owns the verdict:
    # a latched gate discharges this birth as a once-per-key init.
    if _PYIR_FOLD_FIRSTDEF_STACK:
        _PYIR_FOLD_FIRSTDEF_STACK[-1].append(slot)


def _pyir_fresh_container_init(
    label: str,
    container: Any,
    filename: "str | None",
    lineno: "int | None",
    fresh_paths: "frozenset[tuple]",
    _prefix: tuple = (),
) -> None:
    """Per-iteration re-init of a fresh in-region container's entry cells (the
    scalar in-region first-def rule); recursion follows declared fresh paths only."""
    items = (
        [(k, dict.__getitem__(container, k)) for k in dict.keys(container)]
        if isinstance(container, _WatchedDict)
        else list(enumerate(list.__iter__(container)))
    )
    for k, e in items:
        entry_label = f"{label}[{k!r}]"
        if isinstance(e, (_WatchedDict, _WatchedList)):
            # Nested containers were adopted eagerly at the root adoption;
            # descend only along a DECLARED nested-construction path.
            child_path = _prefix + (k,)
            if child_path in fresh_paths:
                _pyir_fresh_container_init(
                    entry_label, e, filename, lineno, fresh_paths, child_path
                )
            continue
        if not (
            _is_staged_value(e)
            and _can_carry_leaf_ref(e)
            and not _is_compound_single_leaf(e)
        ):
            # Meta entry (scalar or tuple of scalars): record the construction
            # site as the entry place's birth, so a later promotion seeds a
            # real store here (per-iteration re-init) instead of hoisting the
            # init to function entry, which would carry the value across
            # iterations.
            _pyir_record_fresh_entry_birth(container, k, e)
            continue
        log().info(
            "[pyir_assign] '%s' fresh-container binding inside staged CF → "
            "per-entry in-region init",
            entry_label,
        )
        init_e = pyir_assign(
            entry_label,
            None,
            e,
            filename,
            lineno,
            owner=container,
            slot_name=k,
        )
        if isinstance(container, _WatchedDict):
            dict.__setitem__(container, k, init_e)
        else:
            list.__setitem__(container, k, init_e)


def _pyir_route_binding_to_live_place_cells(
    owner: Any,
    slot_name: Any,
    new_value: Any,
    _visited: "set[int] | None" = None,
) -> None:
    """Complete a binding made outside staged CF: store each staged leaf into
    its place's live cell and re-alias, so reads and writes keep ONE cell."""
    if _visited is None:
        _visited = set()
    # Top-level staged scalar bound at an explicit slot.
    if owner is not None and slot_name is not None and _is_staged_value(new_value):
        _pyir_adopt_live_place_cell(owner, slot_name, new_value)
        return
    # Compound: complete each staged leaf against ITS place cell.
    if (
        new_value is None
        or _is_staged_value(new_value)
        or isinstance(new_value, (int, float, bool, str, bytes, type))
        or not _has_instance_storage(new_value)
    ):
        return
    if id(new_value) in _visited:
        return
    _visited.add(id(new_value))
    for attr_name in _get_instance_attrs(new_value):
        try:
            field = getattr(new_value, attr_name)
        except AttributeError:
            continue
        if _is_staged_value(field) and _can_carry_leaf_ref(field):
            _pyir_adopt_live_place_cell(new_value, attr_name, field)
        elif isinstance(field, tuple):
            for i, elem in enumerate(field):
                if _is_staged_value(elem) and _can_carry_leaf_ref(elem):
                    _pyir_adopt_live_place_cell(
                        new_value, _place_seg_child(attr_name, i), elem
                    )
        elif (
            _has_instance_storage(field)
            and not _is_staged_value(field)
            and not isinstance(field, (int, float, bool, str, bytes, type))
            and _has_decomposable_staged_fields(field)
        ):
            _pyir_route_binding_to_live_place_cells(
                None, None, field, _visited=_visited
            )


# Dynamic extent of the machinery's whole-object M->M decomposition: its
# per-field replays re-state a binding the choke already judged, so the
# declared-surface wall must not re-judge them as direct field writes.
_PYIR_M2M_DECOMPOSE_DEPTH: "list[int]" = [0]


def _pyir_surface_wall_governed_value(value: Any) -> bool:
    """Whether *value* has a choke-governed carry story as an attr-write
    payload: meta primitives (trace-time accounting), staged / raw-``ir.Value``
    leaves (per-field ref carry), containers and tuples (adoption /
    decomposition), and the watched-meta wrapper.  Everything else is an
    opaque compound whose predicated rebind nothing carries."""
    return (
        value is None
        or isinstance(
            value,
            (bool, int, float, str, bytes, type, tuple, list, dict, set, frozenset),
        )
        or isinstance(value, ir.Value)
        or isinstance(value, _WatchedM)
        or _is_staged_value(value)
    )


def _pyir_judge_declared_surface_write(
    owner: Any,
    slot_name: Any,
    old_value: Any,
    new_value: Any,
    filename: "str | None",
    lineno: "int | None",
) -> None:
    """Declaration wall for value-tree-protocol owners: replacing an OPAQUE
    COMPOUND held by a field the owner's OWN ``__extract_mlir_values__``
    never touches, inside dynamic staged CF, refuses loudly.  Such a field
    was declared constant context and its payload has no carry story, so
    the trace-time replacement could not follow the region's runtime
    predicate (it would bake unconditionally).

    The declared write model stays admitted: ctor-birth first-defs
    (``old_value is None``), meta-primitive accounting, staged / raw-leaf
    per-field carry, container adoption, and the machinery's own
    per-field decompose replays.

    Companion arm: a wrapper subclass that overrides ``__hash__`` beneath
    the DSL value type answers hashing without the wrapper's consumption
    witness -- the same declaration break, judged at the same choke.

    An underivable surface produces no fact and admits the write; a
    constexpr scope resolves at trace time and is exempt like every
    meta-mutation judgment."""
    # A ``_PlaceSeg`` slot names a container ELEMENT under a field; only the
    # plain-str FIELD binding is a declared-surface judgment.
    if owner is None or not isinstance(slot_name, str):
        return
    if _PYIR_M2M_DECOMPOSE_DEPTH[0]:
        return  # machinery per-field replay of a judged whole-object rebind
    if not is_inside_staged_cf() or is_inside_constexpr_loop():
        return
    if not _implements_dynamic_expression(owner):
        return
    cls = type(owner)
    definer = _pyir_class_facts.staged_wrapper_hash_override(cls)
    if definer is not None:
        from .pyir_callee_rewrite import _pyir_boundary_module_is_user

        if _pyir_boundary_module_is_user(getattr(definer, "__module__", None)):
            raise DSLUserCodeError(
                DiagId.OWNER_DECLARED_SURFACE_VIOLATION,
                filename=filename,
                lineno=lineno,
                obj=cls.__name__,
                violation=(
                    f"`{definer.__qualname__}` overrides `__hash__` beneath "
                    "the DSL value type, hiding its identity witness"
                ),
            )
    # Ctor-birth first-def, or a payload kind with a choke-governed carry
    # story: the declared write model owns it.
    if old_value is None:
        return
    if _pyir_surface_wall_governed_value(
        old_value
    ) or _pyir_surface_wall_governed_value(new_value):
        return
    surface = _pyir_class_facts.declared_extract_surface(cls)
    if surface is not None and slot_name not in surface:
        raise DSLUserCodeError(
            DiagId.OWNER_DECLARED_SURFACE_VIOLATION,
            filename=filename,
            lineno=lineno,
            obj=cls.__name__,
            violation=(
                f"`{slot_name}` is not part of that declaration and is written here"
            ),
        )


def _pyir_carry_meta_compound_region_rebind(
    old_value: Any,
    new_value: Any,
    binding_slot: Any,
    cur_cf_depth: int,
    target_name: Any,
    filename: "str | None",
    lineno: "int | None",
) -> Any:
    """Carry a REGION-CROSSING whole-object ctor rebind of an all-meta-
    primitive-field compound by promoting its numeric fields per-field.

    A compound with no staged content passes through ``pyir_assign`` as a
    harmless trace-time replacement -- but when the binding was born at a
    SHALLOWER staged depth (it carries across iterations of the enclosing
    for/while/if) and the new object's fields are all meta primitives, the
    trace-once body would bake the fields at their first-iteration values.
    Instead of refusing, promote each bool/int/float field to a staged slot
    keyed to the OLD object -- the SAME place every earlier ``obj.attr``
    read recorded its bakes under, so ``_meta_promote_slot`` rewrites those
    bakes to loads -- store the new field's SSA through it, and keep the
    OLD object as the binding carrier (m2m polarity): the compound twin of
    bare-int D1 promotion, threading each field as a carried phi the way
    the L191 staged-field whole-object rebind does.

    Returns the carrier (the OLD object) when the rebind was carried, or
    ``None`` when the passthrough stays legal: identity rebinds, constexpr
    unrolls (realized at trace time), in-region-born bindings (trace-local
    rebind), unknown birth depth (uninstrumented first-def, e.g. a callee
    parameter), objects with any non-primitive field (opaque/staged carry
    stories own those), and same-class all-fields-equal rebinds (a fixed
    point of meta state -- re-running the body cannot produce different
    fields).

    Raises ``PHASE_META_FIELD_CHANGED_IN_CF`` only for a CHANGED field with
    no sound carry story: a field the old object does not carry as a meta
    primitive (missing / None / nested object -- "unchanged" is unprovable
    there), str/bytes payloads, cross-type payload drift,
    a new value with no eager-IR derivation (a plain payload or a
    payload-domain fold would store a trace-time CONSTANT), a field already
    consumed as trace-time structure (folded if/while tests, coercions,
    comparisons -- the bake is not retargetable), a cross-class rebind, or
    a promotion the meta-value table does not admit.
    """
    if old_value is new_value or is_inside_constexpr_loop():
        return None
    first_depth = (
        _slot_first_def_depth_any.get(binding_slot)
        if binding_slot is not None
        else None
    )
    if first_depth is None or first_depth >= cur_cf_depth:
        return None
    attrs = _get_instance_attrs(new_value)
    if not attrs or not all(
        isinstance(getattr(new_value, a), (bool, int, float, str, bytes)) for a in attrs
    ):
        return None

    def _refuse(attr: str, old_field: Any, new_field: Any) -> None:
        raise DSLUserCodeError(
            DiagId.PHASE_META_FIELD_CHANGED_IN_CF,
            filename=filename,
            lineno=lineno,
            owner_class=type(old_value).__name__,
            attr=attr,
            old_value=old_field,
            new_value=new_field,
        )

    changed = []
    _absent = object()
    for attr in attrs:
        new_field = getattr(new_value, attr)
        old_field = getattr(old_value, attr, _absent)
        # Compare RAW payloads: either side may arrive as a ``_WatchedM``,
        # and a wrapper comparison would coerce through the watch dunders.
        # Primitives compare safely across types (no user dunders), so a
        # type drift with a value change (int 0 -> float 0.5) counts as a
        # change; equal-by-value pairs (True -> 1) stay a fixed point.
        old_py = getattr(old_field, "_pyir_raw_payload", old_field)
        new_py = getattr(new_field, "_pyir_raw_payload", new_field)
        if not isinstance(old_py, (bool, int, float, str, bytes)):
            # The field APPEARED, or its OLD kind is not a meta primitive
            # (None / nested object): "unchanged" is unprovable and there
            # is no numeric cell to thread through -- fail closed instead
            # of letting the rebind pass as a fixed point and bake.
            _refuse(attr, "<missing>" if old_field is _absent else old_py, new_py)
        if old_py != new_py:
            # A textual payload has no numeric cell to thread through.
            if isinstance(old_py, (str, bytes)) or isinstance(new_py, (str, bytes)):
                _refuse(attr, old_py, new_py)
            # A cross-type numeric drift (int 0 -> float 0.5) has no single
            # SSA element type for the carried cell -- fail closed.
            if type(old_py) is not type(new_py):
                _refuse(attr, old_py, new_py)
            # The carried store must RE-DERIVE from the promoted loads on
            # every iteration: only an eager-IR derivation (``_binop_ir``
            # chains) is rewrite-reachable.  A plain payload or a
            # payload-domain wrapper (comparison results, ``not_`` folds)
            # would store the trace-time CONSTANT of a folded decision --
            # fail closed.
            if (
                not isinstance(new_field, _WatchedM)
                or getattr(new_field, "_cached_ir", None) is None
            ):
                _refuse(attr, old_py, new_py)
            changed.append((attr, old_py, new_py))
    if type(old_value) is not type(new_value):
        # Cross-class all-meta rebind: the field sets need not align and the
        # bound methods differ across iterations, so no per-field carry story
        # exists.  Equal fields are a fixed point of the FIELDS, not of the
        # object (the traced body baked the old class's methods) -- refuse
        # before the passthrough, on a witness field carrying the class names
        # when no field changed.
        attr, old_py, new_py = (
            changed[0]
            if changed
            else (
                next(iter(attrs)),
                type(old_value).__name__,
                type(new_value).__name__,
            )
        )
        _refuse(attr, old_py, new_py)
    if not changed:
        return None  # same-class all-fields-equal fixed point: passthrough stays legal
    changed_names = {attr for attr, _, _ in changed}
    for attr, old_py, new_py in changed:
        # A changed field already consumed as trace-time STRUCTURE (an
        # `if obj.attr` predicate fold, a user-frame coercion or comparison,
        # `__index__`, ...) has no retargetable SSA bake: the carry would
        # keep the stale decision on every iteration -- refuse on the
        # witness the bare-local D1 arm refuses on.
        if (
            _PYIR_STRUCTURAL_META_CONSUMPTIONS.get(
                _make_slot_key(None, old_value, attr)
            )
            is not None
        ):
            _refuse(attr, old_py, new_py)

    # m2m polarity: the binding keeps the old object as carrier; the
    # generation bump lets a pre-rebind alias capture detect staleness.
    _gen_rebind_rec = _pyir_record_generation_rebind(
        binding_slot,
        old_value,
        new_value,
        target_name,
        filename,
        lineno,
        allow_empty_cells=True,
    )
    for attr in attrs:
        new_field = getattr(new_value, attr)
        old_field = getattr(old_value, attr, None)
        if not isinstance(old_field, (bool, int, float)) or isinstance(
            new_field, (str, bytes)
        ):
            # Textual field: a changed textual field refused above (and a
            # missing/non-primitive old field refused in the change scan),
            # so this is a fixed point -- copy the payload.
            _pyir_setattr_raw(old_value, attr, new_field)
            continue
        field_name = f"{target_name}.{attr}"
        # Owner-keyed pre-read FIRST: it wraps the payload as the watched
        # meta value of the SAME place the body's earlier reads baked
        # against (else pyir_assign would mint a TWIN cell).
        _old_f = pyir_read(field_name, old_field, owner=old_value, slot_name=attr)
        carried = pyir_assign(
            field_name,
            _old_f,
            new_field,
            filename,
            lineno,
            owner=old_value,
            slot_name=attr,
        )
        field_slot = _make_slot_key(field_name, old_value, attr)
        if field_slot is None or field_slot not in _slot_refs:
            # Promotion not admitted: fail closed on a changed field; an
            # unchanged field stays a legal meta fixed point.
            if attr in changed_names:
                _refuse(attr, old_field, new_field)
            _pyir_setattr_raw(old_value, attr, new_field)
            continue
        _pyir_setattr_raw(old_value, attr, carried)
        # Raw-ref born-at-rebind cell: a pre-rebind alias capture reading
        # this field resolves the ONE live row and must refuse, exactly
        # like the staged-field m2m rebind's superseded-generation reads.
        _pyir_record_rebind_ref_cell(_gen_rebind_rec, attr, _slot_refs.get(field_slot))
    _pyir_complete_generation_rebind_cells(_gen_rebind_rec, old_value)
    log().info(
        "[pyir_assign] '%s' region-crossing all-meta compound rebind -> "
        "per-field promotion (%d changed field(s)); old object carries",
        target_name,
        len(changed_names),
    )
    return old_value


def _unwrap_meta_or_self(value: Any) -> Any:
    """The raw meta payload of *value*, or *value* itself when not a
    watched/wrapped meta primitive."""
    payload = _pyir_unwrap_meta_primitive(value)
    return value if payload is None else payload


_GATE_META_SCALARS = (bool, int, float, str, bytes, type(None))


def _all_meta_content(value: Any, seen: "set[int]") -> bool:
    """True when *value* is a meta scalar or a tuple/list/dict/set/plain
    object holding only such content, recursively.  Staged leaves and
    value-protocol objects with staged content are not all-meta: a carry
    path owns them.  A value-protocol object holding only meta leaves has
    no carry path, so its fields are judged like a plain object's."""
    value = _unwrap_meta_or_self(value)
    if isinstance(value, _GATE_META_SCALARS):
        return True
    if _is_staged_value(value):
        return False
    if _implements_dynamic_expression(value) and not _pyir_meta_state_value_tree(value):
        return False
    if id(value) in seen:
        # A shared sub-object or a cycle adds no new content; the first
        # visit judges it (a changed cycle fails closed in the compare).
        return True
    seen.add(id(value))
    if isinstance(value, (tuple, set, frozenset)):
        return all(_all_meta_content(e, seen) for e in tuple(value))
    if isinstance(value, list):
        return all(_all_meta_content(e, seen) for e in list.__iter__(value))
    if isinstance(value, dict):
        return all(_all_meta_content(v, seen) for v in dict.values(value))
    names = _get_instance_attrs(value)
    if not names:
        return False
    return all(_all_meta_content(getattr(value, n), seen) for n in names)


def _meta_content_tree(value: Any, seen: "set[int]") -> Any:
    """*value* as a plain comparable tree: leaves unwrapped, containers
    as builtins, an object as its class plus field tree.  Lets the gate
    compare content by value where objects compare by identity."""
    value = _unwrap_meta_or_self(value)
    if isinstance(value, _GATE_META_SCALARS):
        return value
    if id(value) in seen:
        return "<cycle>"
    seen.add(id(value))
    if isinstance(value, tuple):
        return tuple(_meta_content_tree(e, seen) for e in value)
    if isinstance(value, list):
        return [_meta_content_tree(e, seen) for e in list.__iter__(value)]
    if isinstance(value, (set, frozenset)):
        return set(value)
    if isinstance(value, dict):
        return {k: _meta_content_tree(v, seen) for k, v in dict.items(value)}
    return (
        type(value),
        {
            n: _meta_content_tree(getattr(value, n), seen)
            for n in _get_instance_attrs(value)
        },
    )


def _refuse_meta_compound_region_rebind(
    owner: Any,
    slot_name: Any,
    old_value: Any,
    new_value: Any,
    cur_cf_depth: int,
    target_name: Any,
    filename: "str | None",
    lineno: "int | None",
) -> None:
    """Refuse a rebind of an attr-held all-meta compound (tuple, list,
    dict, set, or plain object, nested to any depth) whose content
    changed inside staged CF: no cell carries it, so the trace-once body
    would keep the first iteration's content.  Unchanged content, region-born bindings,
    constexpr unrolls, staged content, and container-element
    (``_PlaceSeg``) slots pass through.  Value-protocol owners are the
    declared-surface wall's business (including its deliberate fail-open
    cases), so this gate skips them."""
    if owner is None or not isinstance(slot_name, str) or is_inside_constexpr_loop():
        return
    if _implements_dynamic_expression(owner):
        return
    kind = None
    if isinstance(old_value, tuple) and isinstance(new_value, tuple):
        kind = "tuple"
    elif isinstance(old_value, list) and isinstance(new_value, list):
        kind = "list"
    elif isinstance(old_value, dict) and isinstance(new_value, dict):
        kind = "dict"
    elif isinstance(old_value, (set, frozenset)) and isinstance(
        new_value, (set, frozenset)
    ):
        kind = "set"
    elif type(old_value) is type(new_value) and _get_instance_attrs(old_value):
        # Fields may nest compounds (a tuple field, an object field):
        # judge the whole content tree, not just scalar fields.
        if _all_meta_content(old_value, set()) and _all_meta_content(new_value, set()):
            kind = "object"
    if kind is None:
        return
    if _has_any_staged_content(old_value) or _has_any_staged_content(new_value):
        return  # staged content has its own carry/refusal paths
    slot = _make_slot_key(target_name, owner, slot_name)
    first_depth = _slot_first_def_depth_any.get(slot) if slot is not None else None
    if first_depth is not None and first_depth >= cur_cf_depth:
        return  # region-born binding: a trace-local rebind
    try:
        if kind == "object":
            changed = _meta_content_tree(old_value, set()) != _meta_content_tree(
                new_value, set()
            )
        else:
            changed = bool(old_value != new_value)
    except Exception:
        changed = True  # incomparable payloads: fail closed
    if not changed:
        return  # content unchanged: re-tracing reproduces it
    if kind == "set":
        raise DSLUserCodeError(
            DiagId.CONTAINER_SET_REBUILT_IN_CF,
            filename=filename,
            lineno=lineno,
            var=target_name,
            old_value=old_value,
            new_value=new_value,
        )
    raise DSLUserCodeError(
        DiagId.CONTAINER_META_REBUILT_IN_CF,
        filename=filename,
        lineno=lineno,
        var=target_name,
        kind=kind,
        old_value=old_value,
        new_value=new_value,
    )


def _pyir_is_opaque_handle_binding(value: Any) -> bool:
    """Whether *value* is an OPAQUE HANDLE for carry purposes: a binding whose
    staged state is one dialect-opaque leaf the place cell carries (pointer,
    view, atom ...), not a scalar / container / meta value with a route of
    its own.  A builtin mutable ``set`` is meta-container state, not a handle
    (it has no ``__dict__``, so the staged-content probe misreads it)."""
    return (
        value is not None
        and not isinstance(value, (bool, int, float, str, bytes, type))
        and not isinstance(value, set)
        and not isinstance(value, _WatchedM)
        and (
            not _is_staged_value(value)
            # A STAGED wrapper that owns no cellable route of its own (no
            # ``_pyir_ref_supported``, leaf not scalar-carryable) is an
            # opaque HANDLE for carry purposes -- e.g. an Array/Pointer
            # whose single ``!llvm.ptr`` leaf the place cell carries.
            or (
                not _can_create_ref(value)
                and not _can_carry_leaf_ref(value)
                and _is_opaque_leaf_value_tree(value)
            )
        )
        and (
            not _has_any_staged_content(value)
            # An all-opaque-leaf value tree is carried by opaque-leaf carry;
            # ``_has_any_staged_content`` misreports its derived fields.
            or _is_opaque_leaf_value_tree(value)
        )
    )


def _pyir_judge_exception_slot_write(
    target_name: Any,
    owner: Any,
    slot_name: Any,
    filename: "str | None",
    lineno: "int | None",
) -> None:
    """An exception's C-level slot has no storage a place cell could shadow: in
    staged CF the write is trace-time host state unless the exception is born
    in the open loop body (a per-iteration object).  A composite ``_PlaceSeg``
    slot names a container element, never one of these names."""
    if (
        owner is None
        or not isinstance(owner, BaseException)
        or slot_name not in _PYIR_EXCEPTION_SLOT_NAMES
        or not is_inside_staged_cf()
    ):
        return
    from .pyir_callee_rewrite import _pyir_boundary_birth_anchor

    if _pyir_boundary_birth_anchor(owner) is not None:
        return
    # A CSE-hoisted ``_pyir_attr_N`` root is a preprocessor temp: name the
    # receiver's class instead so no temporary reaches the user.
    if not isinstance(target_name, str) or target_name.startswith("_pyir_"):
        target_name = f"{type(owner).__name__}.{slot_name}"
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.UNSUP_EXCEPTION_SLOT_WRITE_IN_STAGED_CF,
            filename=filename,
            lineno=lineno,
            target=target_name,
            attr=slot_name,
        )
    )


def pyir_assign(
    target_name: Any,
    old_value: Any,
    new_value: Any,
    filename: "str | None",
    lineno: "int | None",
    *,
    owner: Any = None,
    slot_name: Any = None,
    fresh_binding: bool = False,
    fresh_paths: tuple = (),
    rhs_ctor: Any = None,
    rmw_self: bool = False,
    rmw_path: "str | None" = None,
    stmt_id: "int | None" = None,
) -> Any:
    """Called by AST-inserted code after every ``=`` and ``+=``.

    1. Checks (M) mutation and type stability (Rule 2, Rule 4).
    2. If inside staged CF and value is (S):
       - Creates ``pyir.ref`` on first write (via MutableValue).
       - ``pyir.store`` the new value into the ref.
       - Returns ``new_value`` with ``_mutable_ref`` attached (NO load).
    3. Outside CF: returns new_value unchanged.

    Value-keyed local writes defer their loads to ``pyir_read`` /
    ``_pyir_auto_load_arg`` at the use site (the loaded SSA is created at
    the correct insertion point); the D1 owner/slot arms and the
    store-through paths DO return fresh ``pyir.load`` products so the
    binding the caller re-binds is cell-backed.

    *owner* / *slot_name* optionally identify the storage slot (e.g.
    ``(obj, "loop_desc")`` or ``(container, "key")``).  When both are
    provided, ``pyir_assign`` keys ref identity on the slot instead of
    on the value object -- preventing shared-value aliasing bugs where
    three attributes initialised from the same Python object collapse
    onto a single ``pyir.ref``.  When either is ``None`` the function
    falls back to the value-keyed path (preserving local-name
    semantics).

    *rhs_ctor* is the re-loaded callee of a DIRECT-call RHS (``x = Ctor(...)``,
    Name-rooted load chain): with standard allocation semantics it witnesses
    that the statement CONSTRUCTED the bound object, so its raw meta-primitive
    fields record their in-region first-def facts at the binding (see
    :func:`_pyir_record_fresh_object_leaf_first_defs`).  ``None`` for any
    other RHS shape.

    Simplified ``pyir_assign(owner, key, value, filename, lineno)`` entry
    point: detected by *target_name* not being a string (it's the owner
    object) and dispatched to the slot-registry-only path; the location
    args are still required so diagnostics can cite where the call came
    from.
    """
    # Simplified (owner, key, value) dispatch -- used by the slot
    # registry unit test and by external (owner, key) callers.  The
    # location args are still required (see signature) so this branch
    # never observes ``None`` for either; we just don't carry them
    # through ``_pyir_assign_simple`` (which is registry-only and emits
    # no diagnostics).
    if not isinstance(target_name, str):
        return _pyir_assign_simple(target_name, old_value, new_value)
    # Diagnostics name the attribute as the user spelled it; the place is
    # keyed on the storage slot that spelling resolves to.
    _spelled_slot_name = slot_name
    slot_name = _pyir_canonical_slot_name(owner, slot_name)

    # F-MEMORY: an element of a memref-backed owner lives in staged memory and
    # the owner's accessors emit its stores; memory, not a row, is the authority.
    if (
        owner is not None
        and slot_name is not None
        and not isinstance(slot_name, (str, _PlaceSeg))
        and _is_memref_like(owner)
    ):
        return new_value
    # A field write whose owner is a fresh load product of a ref-carried
    # opaque value (a staged copy, never the stored object) can reach neither
    # the storage it was read from nor that storage's cell: the write would
    # be lost, so it refuses.
    if (
        owner is not None
        and isinstance(slot_name, str)
        and _get_load_version(owner) is not None
        and _is_staged_value(owner)
        and _can_create_ref(owner)
    ):
        raise DSLUserCodeError(
            DiagId.WRAPPER_FIELD_WRITE_ON_STAGED_COPY,
            filename=filename,
            lineno=lineno,
            field=slot_name,
            type=type(owner).__name__,
        )
    _pyir_judge_exception_slot_write(target_name, owner, slot_name, filename, lineno)
    # Staged-selection wall: a field write through the product of a
    # runtime-predicate ternary (``x if cond else y``) cannot reach either
    # candidate and which one Python would mutate is a run-time fact -> refuse.
    # The M->M decomposition's per-field replay of a judged whole-object rebind
    # is machinery, not a user write.
    if owner is not None and not _PYIR_M2M_DECOMPOSE_DEPTH[0]:
        if _PYIR_STAGED_SELECTIONS:
            _pyir_check_staged_selection_write(
                owner, slot_name, target_name, filename, lineno
            )
        # An UNSIGHTED merge (two temporaries nobody else can observe) takes
        # the write; its candidates are marked so a later field read of
        # either refuses instead (OWNER_STAGED_SELECTION_CANDIDATE_READ).
        if _PYIR_STAGED_SELECTION_ARMS:
            _pyir_mark_selection_written_candidates(owner)
        # A write to a candidate of a staged selection: the products taken
        # before it no longer say what Python's (the candidate itself) would.
        if _PYIR_SELECTION_CANDIDATE_PRODUCTS:
            _pyir_mark_selection_products_stale(owner)
    # Call-born witness (F-BIRTHPOS for a call-RHS first-def inside staged CF):
    # a function callee cannot witness the allocation the way a direct ctor
    # does, so the trace proves it here -- BEFORE this binding's own
    # bookkeeping sights the object, while "never sighted" still means "born
    # by this statement".  Consumed by ``_assign_first_def``.
    rhs_call_born = False
    if (
        rhs_ctor is not None
        and not isinstance(rhs_ctor, type)
        and old_value is None
        and is_inside_staged_cf()
        and not is_inside_constexpr_loop()
    ):
        try:
            rhs_call_born = _pyir_call_born_object_is_fresh(
                new_value, owner, id(new_value) in _PYIR_CANDIDATE_HOLDERS
            )
        except Exception:
            rhs_call_born = False
    # Declaration wall: a value-tree-protocol owner's observed field write in
    # dynamic staged CF must stay on its declared (extraction-touched) surface.
    _pyir_judge_declared_surface_write(
        owner, slot_name, old_value, new_value, filename, lineno
    )
    # F-SPEC write amendment: a trace-observed persistent-state write re-bakes
    # its recorded rows so re-entry verifies the trace-exit value.
    if owner is not None and slot_name is not None:
        # Host-restore witness: the pre-write scalar binding this place returns
        # to at trace close if the write leaves it holding a staged wrapper.
        _pyir_record_host_restore(owner, slot_name, old_value)
        _pyir_spec_record_write(
            _pyir_read_place(target_name, owner, slot_name), new_value
        )
    # F-CEPLACE: the assign choke maintains the binding-BIRTH ownership fact
    # for bare locals; every later key derivation in this call consumes it.
    # A non-None *old_value* witnesses a rebind of an existing binding (the
    # instrumented form read the bound value first), which continues the one
    # logical binding; only a first-def can birth a new one.
    if owner is None and slot_name is None:
        _ce_note_local_assign(target_name, continues_binding=old_value is not None)
    # A staged write of a place a plain callee already READ through a closure
    # cell in staged CF cannot be retargeted; refuse loudly (declared fact).
    if _PYIR_BOUNDARY_META_CELL_READS and owner is None and is_inside_staged_cf():
        _cr_key = _make_slot_key(target_name, owner, slot_name)
        _cr = (
            _pyir_boundary_cell_read_for_local(_cr_key) if _cr_key is not None else None
        )
        if _cr is not None:
            _cr_name, _cr_file, _cr_line = _cr
            raise DSLUserCodeError(
                DiagId.BOUNDARY_CLOSURE_READ_THEN_WRITTEN,
                filename=filename,
                lineno=lineno,
                name=str(target_name),
                def_file=_cr_file,
                def_line=_cr_line,
            )
    # Candidate-holder registry: an instrumented binding sights the slot owner
    # and both bound objects -- each is a potential captured-holder walk root.
    _pyir_register_candidate_holder(owner)
    _pyir_register_candidate_holder(old_value)
    _pyir_register_candidate_holder(new_value)
    # A constructed container RHS binds its elements in Python VALUE terms
    # (the plain-local first-def freeze, per element).  The freeze must run
    # on the PLAIN container, before adoption installs the element write
    # choke: a choked in-place freeze reads the routed element at the new
    # place, claims its foreign cell as that place's row (first-wins
    # rooting) and stores the snapshot back into the source cell, so the
    # element keeps following the source binding.
    if (
        fresh_binding
        and type(new_value) in (list, dict)
        and _carries_foreign_slot_binding(new_value)
    ):
        new_value = _freeze_foreign_slot_binding(
            new_value, f"first-def local '{target_name}'", fresh_container=True
        )
    # Binding-choke adoption: a plain dict at a KNOWN holder slot adopts with the
    # holder replaced; owner-less bindings adopt only for FRESH constructions.
    if (
        type(new_value) is dict
        and not isinstance(old_value, dict)
        and _WATCHED_DICT_READ_HOOK[0] is not None
    ):
        if owner is not None and slot_name is not None:
            new_value = _pyir_adopt_dict_value(
                owner, slot_name, new_value, label=str(target_name)
            )
        elif fresh_binding:
            new_value = _pyir_adopt_dict_value(
                None, None, new_value, label=str(target_name)
            )
    # List sibling of the binding-choke adoption (known holder slot or owner-less
    # fresh construction; a list-over-list rebind belongs to the decomposition).
    if (
        type(new_value) is list
        and not isinstance(old_value, list)
        and _WATCHED_LIST_READ_HOOK[0] is not None
    ):
        if owner is not None and slot_name is not None:
            new_value = _pyir_adopt_list_value(
                owner, slot_name, new_value, label=str(target_name)
            )
        elif fresh_binding:
            new_value = _pyir_adopt_list_value(
                None, None, new_value, label=str(target_name)
            )
    # Identity re-point decision for a whole-object compound rebind inside
    # staged CF: a replacement that pre-exists the open region re-points the
    # place (admitted when the post-region identity is trace-time static,
    # refused otherwise); a body-born replacement keeps the per-field carry.
    _identity_repoint = _pyir_judge_identity_repoint(
        target_name, owner, slot_name, old_value, new_value, filename, lineno, stmt_id
    )
    # Record stable-anchor rooting for a dotted attr access; ``alias_from=old_value``
    # lets a NEW object at a rooted place adopt the old rooting (anti-twin).  A
    # re-pointed place names an object that keeps its own places: no adoption.
    if not _identity_repoint:
        _register_place_prefix(
            target_name, owner, slot_name, old_value, new_value, alias_from=old_value
        )

    # A write through a stamped superseded generation would corrupt the one
    # live cell -> diagnostic; every compound binding is recorded for rebinds.
    if _SUPERSEDED_GENERATIONS and owner is not None:
        _pyir_check_superseded_owner_write(owner, slot_name, new_value, target_name)
    _pyir_record_compound_binding(
        target_name,
        owner,
        slot_name,
        new_value,
        filename,
        lineno,
        old_value=old_value,
        identity_repoint=_identity_repoint,
    )
    # A binding that sets the object the place names in the trace (first def,
    # host-phase binding, admitted re-point; a body-born rebind in staged CF
    # copies into the place's object instead) records the regions open at it:
    # a later re-point of the place must prove static every region entered
    # after it.
    if (
        (_identity_repoint or old_value is None or not is_inside_staged_cf())
        and new_value is not None
        and _pyir_is_generation_compound(new_value)
    ):
        _bind_slot = _make_slot_key(target_name, owner, slot_name)
        if _bind_slot is not None:
            _pyir_record_slot_bind_regions(_bind_slot, _pyir_open_region_tokens())
            if _identity_repoint:
                _PYIR_SLOT_REPOINTED[_bind_slot] = new_value
            else:
                _PYIR_SLOT_REPOINTED.pop(_bind_slot, None)
    # Region-conditional attr first-def maintenance: a reassignment may widen
    # or discharge an earlier in-region first-def record (read-before-set).
    # A write on a SIBLING arm of the first-def replaces a value Python never
    # bound on this path, so it is not a same-position reset (see D1 below).
    _sibling_arm_write = False
    if old_value is not None and owner is not None and _PYIR_CF_ATTR_FIRST_DEFS:
        _sibling_arm_write = _pyir_update_cf_attr_first_def_on_write(owner, slot_name)

    # Binding-depth bookkeeping for the within-body-local gate below: ``_prior_binding_depth`` is the depth
    # where ``old_value`` was last written; refreshed to THIS write. Tracked only inside staged CF.
    _binding_slot = None
    _prior_binding_depth = None
    _cur_cf_depth = current_staged_cf_depth()
    if is_inside_staged_cf():
        _binding_slot = _make_slot_key(target_name, owner, slot_name)
        if _binding_slot is not None:
            if old_value is not None:
                _prior_binding_depth = _slot_binding_depth.get(_binding_slot)
            _slot_binding_depth[_binding_slot] = _cur_cf_depth
            try:
                _slot_binding_block[_binding_slot] = ir.InsertionPoint.current.block
            except Exception:
                _slot_binding_block.pop(_binding_slot, None)
    log().info(
        "[pyir_assign] '%s' old=%s new=%s (%s:%d)",
        target_name,
        type(old_value).__name__,
        type(new_value).__name__,
        filename,
        lineno,
    )
    # An admitted identity re-point binds the pre-existing object itself: its
    # fields stay in its own cells (mutations through the place reach them),
    # and the object the place named before is left untouched.
    if _identity_repoint:
        return new_value

    if old_value is None:
        return _assign_first_def(
            target_name,
            new_value,
            filename,
            lineno,
            owner,
            slot_name,
            fresh_binding,
            fresh_paths,
            rhs_ctor,
            rhs_call_born,
        )

    # A witnessed direct-ctor RHS births its fields here (F-BIRTHPOS) only when
    # the new object REPLACES the binding; when the M->M arm keeps the
    # binding's own object as carrier, the leaf keys are that carrier's
    # pre-existing places and must stay entry-seeded.
    if (
        is_inside_staged_cf()
        and rhs_ctor is not None
        and not (
            type(old_value) is type(new_value)
            and _has_decomposable_staged_fields(old_value)
        )
    ):
        _pyir_record_fresh_object_leaf_first_defs(rhs_ctor, new_value)

    # D1 (META_VALUE_TABLE_DESIGN): retroactive promotion of M values.
    # When the old value is a ``_WatchedM`` wrapper, or the slot is
    # already promoted, route through the meta-value table.  This
    # handles M-mutation inside staged CF without falling through to
    # the "M mutation forbidden" error.
    if is_inside_staged_cf():
        d1_slot = _make_slot_key(target_name, owner, slot_name)
        if d1_slot is not None:
            # Keep-constexpr gate: refuse to promote a still-primitive write
            # whose first-def was inside staged CF (promotion would hoist the
            # per-iteration reset out of the loop).
            # Depth guard: keep-constexpr holds only at the SAME staged-CF
            # depth as the first-def; a deeper write sits in a nested runtime
            # region and must carry, so it falls through to D1 promotion.
            # Subscript exemption: a subscript target is a trace-time counter
            # (once per trace-visit) and stays meta regardless of depth.
            _is_subscript_counter = target_name is not None and "[" in target_name
            # A write in a block strictly inside the first-def's block is a
            # conditional update; keep-constexpr would fold the untaken branch.
            # EXCEPT when every crossed region is an ``scf.if`` arm of the
            # slot's own birth region (a per-iteration reset counter, e.g.
            # fmha's q0_index): in-arm folds are exact per program point, so
            # keep-constexpr with an escape mark (out-of-arm consumptions
            # refuse at the read) is the faithful disposition.
            _fd_block = _slot_first_def_block.get(d1_slot)
            _wr_block = None
            _reassign_strictly_nested = False
            _arm_local_write = False
            if _fd_block is not None and pyir is not None:
                try:
                    _wr_block = ir.InsertionPoint.current.block
                    _reassign_strictly_nested = _block_strictly_inside(
                        _wr_block, _fd_block
                    )
                    # Only a slot ALREADY consumed as trace-time structure
                    # takes the arm-local disposition: promotion cannot
                    # retarget its bake, so keep-constexpr + escape mark is
                    # the one faithful treatment.  An unconsumed slot keeps
                    # the D1 promotion flow (a staged select carries the
                    # conditional update on every path).
                    if (
                        _reassign_strictly_nested
                        and _PYIR_STRUCTURAL_META_CONSUMPTIONS.get(d1_slot) is not None
                    ):
                        _arm_local_write = _pyir_write_in_if_arms_of(
                            _wr_block, _fd_block
                        )
                except Exception:
                    _reassign_strictly_nested = False
                    _arm_local_write = False
            # The reset disposition is a fact about the slot's OWN birth region:
            # the write must sit in the birth block or strictly inside it.  A
            # same-depth write in a later sibling region (a second loop after
            # the one that bound the slot) is a carried write, not the next
            # reset, and falls through to promotion / the off-mode audit.
            _write_in_birth_region = (
                _fd_block is None
                or _wr_block is None
                or _wr_block == _fd_block
                or _reassign_strictly_nested
            )
            if (
                _slot_first_def_inside_cf.get(d1_slot, False)
                and _write_in_birth_region
                and (
                    current_staged_cf_depth() <= _slot_first_def_depth.get(d1_slot, 0)
                    or _is_subscript_counter
                    or _arm_local_write
                )
                and not _sibling_arm_write
                and isinstance(new_value, (bool, int, float))
                and not _is_staged_value(new_value)
                and isinstance(old_value, _WatchedM)
                and d1_slot not in _slot_refs
                and (not _reassign_strictly_nested or _arm_local_write)
            ):
                if _arm_local_write:
                    _PYIR_ARM_LOCAL_META_WRITES[d1_slot] = (
                        ir.InsertionPoint.current.block,
                        filename or "<arm-local write>",
                        lineno or 0,
                    )
                else:
                    # A same-depth write (the next reset) retires the mark.
                    _PYIR_ARM_LOCAL_META_WRITES.pop(d1_slot, None)
                log().info(
                    "[pyir_assign] '%s' D1 keep-constexpr (first-def "
                    "inside CF, new is Python primitive)",
                    target_name,
                )
                return _WatchedM(new_value, d1_slot)
            # Past keep-constexpr the write needs promotion/carry, but a
            # place consumed as trace-time structure has no retargetable
            # constant: a value-changing write bakes stale structure -- refuse.
            #
            # Unless the write stays in the region that births the place: a
            # folded ``if`` adds no staged depth, so this re-binds the place
            # straight-line in the body that re-runs its binding every
            # iteration. The bake therefore stays valid and the normal
            # promotion flow is correct -- only a place born ABOVE the loop
            # carries its value into the next iteration and is a real hazard.
            _sc = _PYIR_STRUCTURAL_META_CONSUMPTIONS.get(d1_slot)
            if _sc is not None and _pyir_structural_bake_is_reseeded(d1_slot):
                _sc = None
            if _sc is not None and _pyir_structural_value_conflicts(_sc, new_value):
                raise DSLUserCodeError(
                    DiagId.PHASE_STRUCTURAL_CONSTANT_MUTATED,
                    filename=filename,
                    lineno=lineno,
                    var=target_name or str(d1_slot),
                    value=_sc[0],
                    read_file=_sc[1],
                    read_line=_sc[2],
                )
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
            old_is_meta_primitive = isinstance(old_value, (bool, int, float))
            new_is_primitive = isinstance(new_value, (bool, int, float, _WatchedM))
            new_is_staged = _is_staged_value(new_value)
            old_cached_ir = getattr(old_value, "_cached_ir", None)
            prior_meta_use_exists = any(
                u is not old_cached_ir for u in _meta_uses.get(d1_slot, [])
            )
            already_tracked = d1_slot in _slot_refs or prior_meta_use_exists
            # A same-value re-bake in the SIBLING branch of a standalone loop-free
            # scf.if is a per-branch re-trace, not a carry: keep the slot meta.
            _rebaked_in_sibling = False
            if (
                already_tracked
                and d1_slot not in _slot_refs
                and not _reassign_strictly_nested
                and new_is_primitive
                and isinstance(old_value, _WatchedM)
                and isinstance(old_value.python_value, (bool, int, float))
                and _const_values_equal(_unwrap(new_value), old_value.python_value)
                and _innermost_enclosing_loop_op_at_ip() is None
            ):
                _baked = _meta_uses.get(d1_slot, [])
                _rebaked_in_sibling = any(
                    _meta_use_in_sibling_if_region(_baked, _if)
                    for _if in _loop_free_enclosing_if_ops_at_ip()
                )
            if _rebaked_in_sibling:
                log().info(
                    "[pyir_assign] '%s' Mp->Mp re-baked constant in sibling "
                    "standalone-if branch -> keep meta (no auto-promote)",
                    target_name,
                )
                _meta_uses.pop(d1_slot, None)
                return _WatchedM(new_value, d1_slot)
            # Meta-to-staged promotion is the DEFAULT: a meta/_WatchedM slot assigned a STAGED value inside a
            # region is promoted to a function-entry ref. A plain-primitive Mp->Mp is NOT force-promoted.
            # An idempotent rewrite (same primitive value AND type, e.g. a
            # staged-loop body re-binding ``n = 128`` when ``n`` is already
            # 128) is a no-op on every path: the baked constant stays correct
            # whether or not the write executes, so it must not promote the
            # slot through ANY of the Mp->Mp rules below (prior-use D1,
            # gate-once, AUTO_M2S, strictly-nested).  Type equality is
            # required on top of ``_const_values_equal`` (which already
            # splits bool from int) because ``1 == 1.0`` yet an int->float
            # rebind changes the baked constant's IR type -- a real rebind.
            # Each skipped write anchors its program point with a constant so
            # a LATER different-value promotion can re-materialise the no-op
            # as a per-site reset store (``_meta_promote_slot``); a slot that
            # never promotes leaves only dead constants behind.  A slot that
            # already owns a cell falls through and stores through it.
            if (
                d1_slot not in _slot_refs
                and new_is_primitive
                and isinstance(old_value, _WatchedM)
                and isinstance(old_value.python_value, (bool, int, float))
                and type(_unwrap(new_value)) is type(old_value.python_value)
                and _const_values_equal(_unwrap(new_value), old_value.python_value)
            ):
                _anchor = _emit_constant_at_current_ip(_unwrap(new_value))
                _meta_idempotent_write_anchors.setdefault(d1_slot, []).append(_anchor)
                log().info(
                    "[pyir_assign] '%s' idempotent Mp->Mp rebind -> keep meta "
                    "(anchor recorded) -> %s",
                    target_name,
                    d1_slot,
                )
                return _WatchedM(new_value, d1_slot)
            if (
                not already_tracked
                and new_is_staged
                and (old_is_watched or old_is_meta_primitive)
            ):
                already_tracked = True
            # Gate-once init (see pyir_state): the first-def was proven once-per-key,
            # so a subsequent Mp->Mp write is the loop-carried advance -- promote.
            if (
                not already_tracked
                and old_is_watched
                and new_is_primitive
                and d1_slot in _PYIR_GATE_ONCE_INIT_SLOTS
            ):
                already_tracked = True
            # Mp->Mp promotion gate: explicit AUTO_M2S promotes any slot; PyIR-implied
            # promotes only a bare local or an attr leg of a container-held object.
            if not already_tracked and old_is_watched and new_is_primitive:
                from .common import (
                    is_auto_m2s_enabled as _is_auto_m2s_enabled,
                    is_pyir_enabled as _is_pyir_enabled,
                )

                _is_name_slot = (
                    isinstance(d1_slot, tuple)
                    and len(d1_slot) > 0
                    and d1_slot[0] == "local"
                ) or _pyir_owner_is_container_held(owner)
                # A constexpr-unroll write is straight-line trace-time Python (meta),
                # UNLESS the scope opened under a dynamic region and isn't idempotent.
                _value_idempotent_rewrite = (
                    isinstance(old_value, _WatchedM)
                    and isinstance(old_value.python_value, (bool, int, float))
                    and _const_values_equal(_unwrap(new_value), old_value.python_value)
                )
                _conditional_constexpr_write = (
                    constexpr_scope_under_staged_cf() and not _value_idempotent_rewrite
                )
                if _is_auto_m2s_enabled() or (
                    _is_pyir_enabled()
                    and _is_name_slot
                    and (not is_inside_constexpr_loop() or _conditional_constexpr_write)
                ):
                    already_tracked = True
            # Mp->Mp strictly NESTED inside the first-def block is a CONDITIONAL update (branch-dependent),
            # so promote unconditionally -- without this the conditional write is dropped and the read folds.
            if (
                not already_tracked
                and old_is_watched
                and new_is_primitive
                and _reassign_strictly_nested
            ):
                already_tracked = True
            # Mp->Mp on a SIBLING arm of the slot's first-def replaces a value
            # Python never bound on this path: the two arms bind different
            # values, so the slot must carry (promote; refuses loudly when
            # automatic promotion is off).  Keeping it meta would bake the
            # last-traced arm's constant on every path.
            if (
                not already_tracked
                and (old_is_watched or isinstance(old_value, (bool, int, float)))
                and new_is_primitive
                and _sibling_arm_write
            ):
                # The old value is raw when it is the sibling arm's binding the
                # arm entry unbound (a plain first-def store, never wrapped).
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
                    # The statement's own RHS read this place (syntactic
                    # witness) yet produced a PLAIN changed primitive with no
                    # wrapper arm having run on the read: the value derives
                    # from the payload through an operation the wrapper
                    # cannot see (a float/bool left operand, a C builtin),
                    # so no retargetable constant exists -- refuse loudly.
                    if (
                        rmw_self
                        and old_is_watched
                        and type(new_value) in (bool, int, float)
                        and not _is_staged_value(new_value)
                        and getattr(old_value, "_cached_ir", None) is None
                        and d1_slot not in _PYIR_STRUCTURAL_META_CONSUMPTIONS
                        and _innermost_enclosing_loop_op_at_ip() is not None
                        and not _const_values_equal(new_value, initial_py)
                    ):
                        raise DSLUserCodeError(
                            DiagId.PHASE_OPAQUE_READ_THEN_PROMOTED,
                            filename=filename,
                            lineno=lineno,
                            var=target_name or str(d1_slot),
                            reader="this statement's own right-hand side",
                        )
                    if isinstance(initial_py, (bool, int, float)):
                        _meta_promote_slot(
                            d1_slot,
                            initial_py,
                            target_name,
                            filename,
                            lineno,
                            promoted_value=new_value,
                        )
                        # An owner place is repairable at region boundaries:
                        # record it for the stale-leaf reload sweep.
                        if d1_slot in _slot_refs and owner is not None:
                            _pyir_record_promoted_place_leaf(owner, slot_name)
                ref = _slot_refs.get(d1_slot)
                if ref is not None:
                    # A STAGED value may be trapped in a closed CF region (a post-region
                    # store fails dominance); the trapped-child-region guard skips it.
                    if new_is_staged and not isinstance(new_value, _WatchedM):
                        skipped = _pyir_skip_trapped_child_region_writeback(
                            ref, new_value, place=d1_slot
                        )
                        if skipped is not None:
                            log().info(
                                "[pyir_assign] '%s' D1 staged value from "
                                "closed child region (ref already written "
                                "in-loop) -> skip redundant store -> %s",
                                target_name,
                                d1_slot,
                            )
                            return skipped
                    # Bake the new value as IR and store into the ref.
                    if isinstance(new_value, _WatchedM) or new_is_staged:
                        # A store captures ITS program point: the value's own
                        # raw backing, never an ``ir_value()`` cell re-follow.
                        # Exception (clause B): a region-crossed epoch-equal
                        # raw must observe its cell; the swap pin keeps its
                        # epoch-MISMATCHED capture.
                        from .pyir_core import _pyir_region_fresh_raw

                        _fresh_rhs = (
                            _pyir_region_fresh_raw(new_value)
                            if new_is_staged and not isinstance(new_value, _WatchedM)
                            else None
                        )
                        if _fresh_rhs is not None:
                            new_value = _fresh_rhs
                        new_ir = _raw_backing_ir_value(new_value)
                        if new_ir is None:
                            new_ir = new_value.ir_value()
                    else:
                        new_ir = _emit_constant_at_current_ip(new_value)
                    # A rebind baked at a type other than the cell pointee is a
                    # fresh redefinition: re-mint the ref, republish the slot.
                    try:
                        _retyped = new_ir.type != ref.type.pointee
                    except Exception:
                        _retyped = False
                    if _retyped:
                        # A binding born OUTSIDE the enclosing staged LOOP body
                        # whose row a body read already traced LOADS is a carry
                        # in flight: the backedge re-executes that read against
                        # the old cell while the new cell takes the stores.  A
                        # binding born in the write's own block re-executes its
                        # first def on every pass (a body-born local keeps its
                        # placeholder cell in the entry block), a row no body
                        # read loads yet, and an if/else arm (no backedge)
                        # re-mint: a fresh redefinition.
                        _region_op = _pyir_innermost_enclosing_region_op_at_ip()
                        _born_in_write_block = (
                            _fd_block is not None
                            and _wr_block is not None
                            and _wr_block == _fd_block
                        )
                        if (
                            _region_op is not None
                            and str(getattr(_region_op, "name", ""))
                            in ("scf.for", "scf.while")
                            and not _born_in_write_block
                            and not _ir_value_defined_inside_op(ref, _region_op)
                            and _pyir_ref_loaded_inside_op(ref, _region_op)
                        ):
                            _pyir_raise_type_changed_in_region(
                                target_name, ref.type.pointee, new_ir.type
                            )
                        ref = pyir.ref(new_ir)
                        _slot_refs[d1_slot] = ref
                    # W2 type step (F-TYPEID): a staged store advances the row's
                    # wrapper template; a primitive store keeps the row's class
                    # (a re-minted generation re-books its declared class).
                    if new_is_staged and not isinstance(new_value, _WatchedM):
                        _pyir_record_slot_template(d1_slot, new_value)
                    elif _retyped:
                        _pyir_record_slot_template(
                            d1_slot,
                            _pyir_declared_promotion_template(
                                new_value.python_value
                                if isinstance(new_value, _WatchedM)
                                else new_value
                            ),
                        )
                    _pyir_emit_store(new_ir, ref)
                    log().info(
                        "[pyir_assign] '%s' D1 store -> %s",
                        target_name,
                        d1_slot,
                    )
                    return _load_as_dsl(ref, place=d1_slot)

    # Off-mode RMW audit: a still-meta attribute slot whose RHS reads the path
    # it writes diverges under trace-once -- per iteration in a loop body, and
    # per taken path in an ``scf.if`` arm (the write executes at trace time
    # whatever the run-time predicate, so the post-region value is wrong on
    # the untaken path) -- so refuse with the promotion-entry diagnostic.
    # ``rmw_self``/``rmw_path`` are the preprocessor's syntactic witness and
    # its dotted spelling.  Region-born receivers are exempt (the write
    # re-executes from its binding with the region).  In an ``if`` arm a
    # value-tree-protocol owner is exempt as well: its meta fields are the
    # trace-time counter channel, never carried state.
    if (
        rmw_self
        and owner is not None
        and slot_name is not None
        and (
            bool(_pyir_open_loop_body_blocks)
            or (is_inside_staged_cf() and not _implements_dynamic_expression(owner))
        )
        and not is_inside_constexpr_loop()
        and not is_auto_m2s_enabled()
    ):
        _audit_slot = _make_slot_key(target_name, owner, slot_name)
        _audit_old = (
            old_value.python_value if isinstance(old_value, _WatchedM) else old_value
        )
        _audit_new = _unwrap(new_value)
        if (
            _audit_slot is not None
            and isinstance(_audit_slot, tuple)
            and _audit_slot[0] == "attr"
            and _audit_slot not in _slot_refs
            and isinstance(_audit_old, (bool, int, float))
            and isinstance(_audit_new, (bool, int, float))
            and _audit_old != _audit_new
            and not _pyir_place_is_region_born(_audit_slot)
        ):
            # Prefer ``rmw_path``'s user-spelled chain, unless an earlier CSE
            # hoist already rewrote the root to a ``_pyir_attr_N`` temp (then
            # it's as uninformative as ``target_name``) -- fall back to the
            # receiver's class name so no preprocessor temp leaks to the user.
            _audit_var = (
                rmw_path
                if rmw_path is not None and not rmw_path.startswith("_pyir_")
                else (
                    f"{type(owner).__name__}.{_spelled_slot_name}"
                    if isinstance(target_name, str) and target_name.startswith("_pyir_")
                    else target_name
                )
            )
            _promoted_cls = _declared_m2s_promotion_class(_audit_old)
            raise DSLUserCodeError(
                DiagId.PHASE_AUTO_PROMOTE_DISABLED,
                filename=filename,
                lineno=lineno,
                var=_audit_var,
                value=repr(_audit_old),
                type=_promoted_cls.__name__ if _promoted_cls is not None else "Int32",
            )

    if (
        is_inside_staged_cf()
        and "[" in target_name
        and isinstance(old_value, (bool, int, float))
        and isinstance(new_value, (bool, int, float))
        and type(old_value) is type(new_value)
    ):
        # A dict-SUBCLASS entry reaching this meta passthrough with a CHANGED
        # value was never promoted: subclasses are never adopted as watched
        # owners, and the augassign spelling loads the entry raw (no read
        # choke records a baked constant), so the D1 write-side promotion
        # above cannot fire -- the per-iteration change would silently
        # freeze at the first pass's value.  Exact plain dicts keep the
        # passthrough (the trace-time-counter channel); constexpr scopes
        # realize the update at trace time.
        if (
            isinstance(owner, dict)
            and type(owner) is not dict
            and not isinstance(owner, _WatchedDict)
            and old_value != new_value
            and not is_inside_constexpr_loop()
        ):
            raise DSLUserCodeError(
                DiagId.CONTAINER_DICT_META_WRITE_UNPROMOTED,
                filename=filename,
                lineno=lineno,
                var=target_name,
                old_value=repr(old_value),
                new_value=repr(new_value),
            )
        log().info(
            "[pyir_assign] '%s' trace-time primitive subscript update → passthrough",
            target_name,
        )
        return new_value

    # Different-LENGTH tuple rebind inside staged CF is always a trace-time
    # rebuild (an iter_arg cannot change shape across iterations).

    # The new tuple's staged leaves carry their own SSAs: pass it through (the
    # M->M path below cannot decompose a tuple).
    if (
        is_inside_staged_cf()
        and isinstance(old_value, tuple)
        and isinstance(new_value, tuple)
        and len(old_value) != len(new_value)
    ):
        # Fail-closed: an arity-changing rebind of a LOOP-CARRIED tuple inside
        # a dynamic staged loop cannot thread (an iter_arg set is arity-fixed),
        # and the trace-once passthrough below would bake every consumer to the
        # trace-time arity (``len()`` folds, the post-loop read serves the
        # snapshot) -- a silent miscompile legacy refuses at the join as
        # TYPE_UNSTABLE_JOIN (tuple<0> vs tuple<1>).  Mirror that judgment
        # here, where the arity mismatch is visible, with the tuple-arity
        # code.  Scope: only a genuine cross-iteration join refuses -- the
        # binding's first-def at a SHALLOWER depth (or unrecorded: a
        # param/closure capture, defined outside by construction).  A
        # same-region straight-line rebuild, a constexpr-governed unroll, and
        # a declared-untracked slot (no place key) keep the passthrough.
        if (
            not is_inside_constexpr_loop()
            and _innermost_enclosing_loop_op_at_ip() is not None
        ):
            _arity_slot = _make_slot_key(target_name, owner, slot_name)
            _arity_first_depth = (
                _slot_first_def_depth_any.get(_arity_slot)
                if _arity_slot is not None
                else None
            )
            if _arity_slot is not None and (
                _arity_first_depth is None
                or _arity_first_depth < current_staged_cf_depth()
            ):
                raise DSLUserCodeError(
                    DiagId.CONTAINER_TUPLE_LENGTH_CHANGED,
                    filename=filename,
                    lineno=lineno,
                    var=target_name,
                    old=len(old_value),
                    new=len(new_value),
                )
        log().info(
            "[pyir_assign] '%s' different-length tuple rebind (%d -> %d) → "
            "compile-time structural rebuild, passthrough",
            target_name,
            len(old_value),
            len(new_value),
        )
        # Generation coherence: the fresh elements store through their access
        # paths' still-live cells (or mark them for a loud serve), so a later
        # place-routed element read resolves this rebind, not the prior
        # generation left in a read-minted row.
        _pyir_route_restructured_tuple_leaves(
            target_name, owner, slot_name, new_value, old_value
        )
        return new_value

    # Tuple-vs-tuple rebind inside staged CF: a tuple has no ``__dict__`` so the M->M path never
    # carries its staged leaves; ``_decompose_tuple`` carries each leaf through its loop-carried ref.
    if (
        is_inside_staged_cf()
        and isinstance(old_value, tuple)
        and isinstance(new_value, tuple)
        and len(old_value) == len(new_value)
        and (
            # Old tuple carries a carryable staged leaf (S->S/S->M), or the new tuple introduces one (M->S).
            # A pure meta->meta tuple has no staged leaf and falls through to the M->M handling below.
            any(
                _is_staged_value(e) and _can_carry_leaf_ref(e)
                for e in _flatten_tuple(old_value)
            )
            or any(
                _is_staged_value(e) and _can_carry_leaf_ref(e)
                for e in _flatten_tuple(new_value)
            )
        )
    ):
        log().info(
            "[pyir_assign] '%s' tuple-vs-tuple rebind → per-leaf decomposition",
            target_name,
        )
        return _decompose_tuple(
            target_name,
            old_value,
            new_value,
            filename,
            lineno,
            set(),
            owner=owner,
            slot_name=slot_name,
        )

    # Whole-DICT rebind inside staged CF: decompose per entry onto the OLD
    # dict's subscript legs when key sets match and every entry is staged.

    # The old dict stays the binding carrier (it accumulates the entry refs).

    # A non-decomposable rebind with staged content is REFUSED; a pure meta
    # dict rebind stays a harmless trace-time replacement.  The whole-rebind
    # intent fact is PRODUCED by the staged-CF write funnel only: a host-phase
    # rebind (no staged region open) takes the outside-CF passthrough.
    if (
        is_inside_staged_cf()
        and isinstance(old_value, dict)
        and isinstance(new_value, dict)
        and old_value is not new_value
    ):
        _old_keys = set(dict.keys(old_value))
        _same_keys = _old_keys == set(dict.keys(new_value))
        if (
            _same_keys
            and _old_keys
            and all(
                _is_staged_value(_e)
                and _can_carry_leaf_ref(_e)
                and not _is_compound_single_leaf(_e)
                for _k in _old_keys
                for _e in (
                    dict.__getitem__(old_value, _k),
                    dict.__getitem__(new_value, _k),
                )
            )
        ):
            log().info(
                "[pyir_assign] '%s' dict whole-rebind → per-entry "
                "decomposition (%d staged entries)",
                target_name,
                len(_old_keys),
            )
            for _k in list(dict.keys(old_value)):
                # Owner-keyed pre-read FIRST: it publishes the entry's cell under
                # the subscript slot (else pyir_assign would mint a TWIN cell).
                _old_e = pyir_read(
                    f"{target_name}[{_k!r}]",
                    dict.__getitem__(old_value, _k),
                    owner=old_value,
                    slot_name=_k,
                )
                dict.__setitem__(
                    old_value,
                    _k,
                    pyir_assign(
                        f"{target_name}[{_k!r}]",
                        _old_e,
                        dict.__getitem__(new_value, _k),
                        filename,
                        lineno,
                        owner=old_value,
                        slot_name=_k,
                    ),
                )
            return old_value  # old dict carries the entry refs
        if any(
            _is_staged_value(_e)
            for _d in (old_value, new_value)
            for _e in list(dict.values(_d))
        ):
            raise DSLUserCodeError(
                DiagId.CONTAINER_OBJECT_REPLACED,
                filename=filename,
                lineno=lineno,
                var=target_name,
            )
        # A dict field rebuilt inside staged CF would keep its
        # first-iteration entries: refuse before passing through.
        _refuse_meta_compound_region_rebind(
            owner,
            slot_name,
            old_value,
            new_value,
            _cur_cf_depth,
            target_name,
            filename,
            lineno,
        )
        log().info(
            "[pyir_assign] '%s' pure meta dict rebind → passthrough",
            target_name,
        )
        return new_value

    # Opaque-object rebind inside staged CF: ``old_value`` is an opaque handle with no staged leaves,
    # an ordinary within-iteration rebind. A tracked-ref slot is loop-carried state and excluded.
    # A builtin mutable ``set`` is NOT an opaque handle: it has no ``__dict__``
    # so the staged-content probe misreads it, but its rebind is meta-container
    # state (``s = s | {x}``) that must reach the phase check below and refuse.
    if is_inside_staged_cf() and _pyir_is_opaque_handle_binding(old_value):
        d1_slot = _make_slot_key(target_name, owner, slot_name)
        # A place rebound to a same-type opaque value stores through its ONE
        # place cell, so one carry chain spans every region level.  An
        # attr/subscript place cells the same way a bare local does: without
        # the cell the rebind passes through and the new handle's SSA stays
        # trapped in the region, which the verifier rejects at the post-join
        # read.  A value-protocol owner is EXCLUDED: its leaves already thread
        # as region results / iter_args through the opaque-leaf region carry,
        # and a second cell would carry the same leaf twice.
        if (
            owner is None
            or slot_name is None
            or not _implements_dynamic_expression(owner)
        ):
            _choke_ref = _pyir_place_opaque_rebind_choke(
                target_name, d1_slot, old_value, new_value
            )
            if _choke_ref is not None:
                return new_value
        if d1_slot is None or d1_slot not in _slot_refs:
            # An all-meta-primitive-field compound is NOT an opaque handle:
            # a region-crossing rebind of one bakes its fields (the body is
            # traced once), so it must carry per-field, not pass through.
            _carrier = _pyir_carry_meta_compound_region_rebind(
                old_value,
                new_value,
                d1_slot,
                _cur_cf_depth,
                target_name,
                filename,
                lineno,
            )
            if _carrier is not None:
                _pyir_region_note_recarried(_carrier)
                return _carrier
            # A compound field rebuilt inside staged CF would keep its
            # first-iteration content: refuse before passing through.
            _refuse_meta_compound_region_rebind(
                owner,
                slot_name,
                old_value,
                new_value,
                _cur_cf_depth,
                target_name,
                filename,
                lineno,
            )
            log().info(
                "[pyir_assign] '%s' opaque-object (%s) -> (%s) "
                "within-iteration rebind → passthrough",
                target_name,
                type(old_value).__name__,
                type(new_value).__name__,
            )
            return new_value

    # Trace-local meta-container rebind: a meta list/tuple binding
    # FIRST-DEFINED in the CURRENT insertion block cannot be observed across
    # a staged join (no back-edge or branch merge separates birth from
    # rebind), so rebinding it -- including the list->tuple freeze whose
    # leaves are staged SSAs -- is trace-time Python, exactly what non-PyIR
    # executes.  A binding born in an OUTER or SIBLING block keeps the
    # Rule-2 refusal below.  A tuple->tuple rebind stays on the existing
    # per-leaf decomposition / carry routes.
    if (
        is_inside_staged_cf()
        and isinstance(old_value, (list, tuple))
        and isinstance(new_value, (list, tuple))
        and not _is_staged_value(old_value)
        and not _is_staged_value(new_value)
        and not (isinstance(old_value, tuple) and isinstance(new_value, tuple))
    ):
        _mc_slot = _make_slot_key(target_name, owner, slot_name)
        _mc_birth = (
            _slot_first_def_block_any.get(_mc_slot) if _mc_slot is not None else None
        )
        try:
            _mc_cur = ir.InsertionPoint.current.block
        except Exception:
            _mc_cur = None
        if _mc_birth is not None and _mc_cur is not None and _mc_birth == _mc_cur:
            log().info(
                "[pyir_assign] '%s' trace-local meta-container rebind "
                "(birth block is current) → passthrough",
                target_name,
            )
            return new_value

    # Within-body TYPE-TRANSITION rebind: a slot last written at the SAME
    # staged-CF depth rebound at an incompatible type is a fresh redefinition.

    # * S->S class change: the place re-mints at the new type -- hand back a
    #   fresh wrapper so a later read attaches its own cell.

    # * S->container RESTRUCTURING: the old whole-value cell is retired for the
    #   scope; each staged leaf's place mints its own cell on its next write.

    # A container with NO staged leaf is a genuine staged->Python demotion and
    # stays on the phase-rule error path below.
    if (
        old_value is not None
        and new_value is not None
        and _prior_binding_depth is not None
        and _prior_binding_depth == _cur_cf_depth
        and _binding_slot is not None
        and _binding_slot not in _slot_refs
        and _is_staged_value(old_value)
        and type(old_value) is not type(new_value)
    ):
        # A place TYPE transition is an MLIR-type change; a same-MLIR-type
        # wrapper-class step falls through to Rule-4 coercion → store-through.
        if _is_staged_value(new_value) and _staged_type_changed(old_value, new_value):
            log().info(
                "[pyir_assign] '%s' within-body local type change %s -> %s "
                "(prior binding depth == current depth) → fresh rebind",
                target_name,
                type(old_value).__name__,
                type(new_value).__name__,
            )
            _pyir_retire_place_row(target_name, owner, slot_name)
            return _fresh_wrapper(new_value)
        if isinstance(new_value, tuple) and any(
            _is_staged_value(e) for e in _flatten_tuple(new_value)
        ):
            log().info(
                "[pyir_assign] '%s' within-body restructuring rebind %s -> "
                "tuple with staged leaves (prior binding depth == current "
                "depth) → fresh container binding",
                target_name,
                type(old_value).__name__,
            )
            _pyir_retire_place_row(target_name, owner, slot_name)
            # Generation coherence: the fresh elements store through their
            # access paths' still-live cells (or mark them for a loud serve).
            _pyir_route_restructured_tuple_leaves(
                target_name, owner, slot_name, new_value, old_value
            )
            return new_value

    # Same-name S->S rebind widening the wrapper to a richer SUBCLASS over an
    # IDENTICAL MLIR type: a fresh redefinition (no SSA join conflict can arise).

    # (Rule 4 would coerce down to the base class and the single-typed ref
    # would reconstruct the base on every auto-load.)

    # Reached even when a tuple-unpack first-def leaves ``_prior_binding_depth``
    # None.  A loop-carried (slot-tracked) rebind keeps its carry.
    if (
        is_inside_staged_cf()
        and old_value is not None
        and new_value is not None
        and _is_staged_value(old_value)
        and _is_staged_value(new_value)
        and type(old_value) is not type(new_value)
        and isinstance(
            new_value, type(old_value)
        )  # new is a SUBCLASS of old (widening)
        and not isinstance(
            old_value, type(new_value)
        )  # strict: old is not a subclass of new
        and _mlir_types_match(
            old_value, new_value
        )  # identical MLIR type (no SSA-join conflict)
        and (
            _binding_slot is None or _binding_slot not in _slot_refs
        )  # not a carried loop carry
    ):
        # MLIR types match, so there is no SSA join conflict regardless of the Python wrapper class;
        # avoid the spurious type-stability rejection. HOW the rebind is reconciled depends on scope:
        if _ref_lives_in_strictly_enclosing_block(old_value):
            # CONDITIONAL update of an OUTER-scope binding (ref minted in a
            # strictly-enclosing block, rebind inside a nested staged region):

            # store back through the existing ref (identical MLIR type) so the
            # lowering carries it out; return the loaded value as the binding.
            _enclosing_mv = getattr(old_value, "_mutable_ref", None)
            # _ref_lives_in_strictly_enclosing_block returned True, which holds
            # only when a live _mutable_ref is present, so it is never None here.
            assert _enclosing_mv is not None
            log().info(
                "[pyir_assign] '%s' conditional subclass rebind of outer-scope "
                "binding %s -> %s (identical MLIR type) → store-back through ref",
                target_name,
                type(old_value).__name__,
                type(new_value).__name__,
            )
            _enclosing_mv.store(new_value)
            return _enclosing_mv.load()
        # FLAT same-region redefinition (ref and rebind share a block, or a tuple-unpack first-def
        # left no binding): a fresh subclass wrapper lets a later read in this region mint its own ref.
        log().info(
            "[pyir_assign] '%s' staged rebind to richer subclass %s -> %s "
            "(identical MLIR type) → fresh rebind",
            target_name,
            type(old_value).__name__,
            type(new_value).__name__,
        )
        _pyir_retire_place_row(target_name, owner, slot_name)
        return _fresh_wrapper(new_value)

    # Structural tuple<->staged rebind inside staged CF: a name oscillates
    # between a single staged value and a tuple/list WRAPPING it.

    # Both directions are legal whole-object replacements: every flattened
    # leaf of the NEW value carries an SSA dominating the bind point.

    # Gated to a NON-carried slot so a genuine loop-carried type-changing
    # carry is not silently accepted.
    def _all_staged_carryable_dominating(_v: Any) -> bool:
        _leaves = (
            list(_flatten_tuple(tuple(_v))) if isinstance(_v, (tuple, list)) else [_v]
        )
        return bool(_leaves) and all(
            _is_staged_value(_lf)
            and _can_carry_leaf_ref(_lf)
            and _value_dominates_current_ip(_lf)
            for _lf in _leaves
        )

    def _all_staged_leaves(_v: Any) -> bool:
        _leaves = (
            list(_flatten_tuple(tuple(_v))) if isinstance(_v, (tuple, list)) else [_v]
        )
        return bool(_leaves) and all(_is_staged_value(_lf) for _lf in _leaves)

    def _is_inert_meta_leaf(_lf: Any) -> bool:
        """A trace-time-only tuple leaf: ``None`` or a plain Python scalar that
        no cell ever carried.  A ``_WatchedM`` is EXCLUDED -- it is TRACKED
        meta (a promotion the machinery may still owe), as is anything with a
        live ``_mutable_ref``; both keep the strict all-staged judgment."""
        if isinstance(_lf, _WatchedM):
            return False
        if getattr(_lf, "_mutable_ref", None) is not None:
            return False
        return _lf is None or isinstance(_lf, (bool, int, float, str, bytes, type))

    def _mixed_inert_leaves(_v: Any) -> bool:
        """OLD is a tuple of at least one staged leaf plus inert trace-time
        structure -- e.g. quack's ``(sf_tensor, None)`` = one staged value and
        a "there is no norm constant" marker.

        An inert meta leaf is compile-time SHAPE no cell ever carried, so
        unwrapping such a tuple onto one of its staged leaves drops nothing a
        later read of the NAME could observe.  That makes the unwrap the same
        whole-object replacement the all-staged premise above accepts -- but
        only for a binding BORN inside this region (see the depth guard at the
        use site): a binding that pre-dates the region still has the old tuple
        live on the not-taken path, which is a genuine structural join."""
        _leaves = (
            list(_flatten_tuple(tuple(_v))) if isinstance(_v, (tuple, list)) else [_v]
        )
        if not _leaves:
            return False
        _staged_leaves = 0
        for _lf in _leaves:
            if _is_staged_value(_lf):
                _staged_leaves += 1
            elif not _is_inert_meta_leaf(_lf):
                # A container / object / tracked-meta leaf may itself hold
                # carried state: keep it out of the structural admission.
                return False
        # A container with NO staged leaf is a genuine meta binding, not a
        # tracked one -- it stays on the phase-rule paths below.
        return _staged_leaves > 0

    _old_is_tuple = isinstance(old_value, (tuple, list))
    _new_is_tuple = isinstance(new_value, (tuple, list))

    def _old_leaves_structurally_tracked() -> bool:
        """The gate's OLD premise: all-staged leaves (historic), or staged +
        inert-meta leaves for a binding born in THIS region.

        The born-in-region fact is the callee-parameter case the unpack idiom
        ``param, norm_const = param`` needs: a traced callee entered inside a
        run-time region records its parameter first-def at the region's depth,
        and the binding dies at return, so no read can ever observe the
        pre-unpack tuple.  A binding first-defined at a SHALLOWER depth
        outlives the region and keeps the refusal."""
        if _all_staged_leaves(old_value):
            return True
        if not _mixed_inert_leaves(old_value):
            return False
        _stl_first_depth = (
            _slot_first_def_depth_any.get(_binding_slot)
            if _binding_slot is not None
            else None
        )
        # Fail closed on an unrecorded first-def (by convention here: a
        # binding defined outside the traced region).
        return _stl_first_depth is not None and _stl_first_depth >= _cur_cf_depth

    if (
        is_inside_staged_cf()
        and old_value is not None
        # Exactly ONE side is a tuple -- a structural wrap/unwrap, not a same-shape carry (a tuple->tuple
        # carry is owned by the tuple-vs-tuple decompose gate above; a staged->staged carry by Rule 4).
        and (_old_is_tuple != _new_is_tuple)
        # OLD is already tracked through its leaves.
        and _old_leaves_structurally_tracked()
        # NEW's every flattened leaf is a self-dominating carryable staged SSA.
        and _all_staged_carryable_dominating(new_value)
    ):
        _stl_slot = _make_slot_key(target_name, owner, slot_name)
        if _stl_slot is None or _stl_slot not in _slot_refs:
            log().info(
                "[pyir_assign] '%s' structural tuple<->staged rebind "
                "(old leaves staged-or-inert, new leaves self-dominate) → "
                "passthrough (region/loop carry owns the carry)",
                target_name,
            )
            # Generation coherence in BOTH directions.  Re-tupling: the fresh
            # elements store through their access paths' still-live cells.
            # Un-tupling: the fresh scalar stores through the NAME's own
            # still-live row (minted while it held the earlier scalar
            # generation); left unadvanced, R1 row authority would serve that
            # stale generation to the very next read at the place.
            if _new_is_tuple:
                # ``old_value`` is a non-tuple here (exactly one side is a
                # tuple), so only the write-through pass has work to do.
                _pyir_route_restructured_tuple_leaves(
                    target_name, owner, slot_name, new_value, old_value
                )
            else:
                _pyir_route_restructured_leaf(target_name, owner, slot_name, new_value)
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
        _rebind_slot = _make_slot_key(target_name, owner, slot_name)
        _first_depth = (
            _slot_first_def_depth_any.get(_rebind_slot)
            if _rebind_slot is not None
            else None
        )
        if _first_depth is not None and _first_depth >= current_staged_cf_depth():
            log().info(
                "[pyir_assign] '%s' straight-line type-change rebind "
                "(%s -> %s, first-def depth %d == cur depth %d) → allow",
                target_name,
                type(old_value).__name__,
                type(new_value).__name__,
                _first_depth,
                current_staged_cf_depth(),
            )
            # Re-root the variable at the new type for this region so a
            # subsequent same-depth rebind is also recognised as straight-line.
            _slot_first_def_depth_any[_rebind_slot] = current_staged_cf_depth()
            _straight_line_type_rebind = True
            # Skip Rule 4; fall through to the type-changing reassignment path.

    # Rule checks (M mutation, type stability) — may auto-coerce scalars.
    # Skipped for a straight-line type-change rebind exempted above (the
    # type-changing reassignment path below materialises a fresh ref).
    coerced = (
        None
        if _straight_line_type_rebind
        else assign_meta_staged_check(
            target_name, old_value, new_value, filename, lineno, owner=owner
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
        return _assign_outside_cf(
            target_name, old_value, new_value, filename, lineno, owner, slot_name
        )

    if (
        not _is_staged_value(new_value)
        and not _is_staged_value(old_value)
        and old_value is not None
        and not isinstance(old_value, (int, float, bool, str, bytes, type))
        and (
            type(old_value) is type(new_value)
            # An adopted watched container is the same PLACE as the plain container
            # literal that rebinds it -- adoption must not change the dispatch.
            or (isinstance(old_value, _WatchedList) and type(new_value) is list)
            or (isinstance(old_value, _WatchedDict) and type(new_value) is dict)
        )
    ):
        return _assign_m2m_compound(
            target_name,
            old_value,
            new_value,
            filename,
            lineno,
            owner,
            slot_name,
            _binding_slot,
            _cur_cf_depth,
        )

    if not _is_staged_value(new_value):
        log().info(
            "[pyir_assign] '%s' new_value not staged → passthrough",
            target_name,
        )
        return new_value

    if not _is_staged_value(old_value):
        return _assign_m2s_promotion(
            target_name, old_value, new_value, filename, lineno, owner, slot_name
        )

    return _assign_store_through(
        target_name, old_value, new_value, filename, lineno, owner, slot_name
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
def _assign_first_def(
    target_name: Any,
    new_value: Any,
    filename: "str | None",
    lineno: "int | None",
    owner: Any,
    slot_name: Any,
    fresh_binding: bool,
    fresh_paths: tuple,
    rhs_ctor: Any,
    rhs_call_born: bool = False,
) -> Any:
    # Freeze a fresh plain-local binding wired to a foreign storage slot, or
    # the local re-loads the source at its consumer (breaks value semantics).

    # Fires at ANY scope: Python binds the value at assignment time whether
    # or not staged CF is open.  A constructed list/dict was frozen at the
    # assign choke before adoption (its elements no longer carry a route);
    # an aliased container passes through untouched here.
    if owner is None and slot_name is None and _carries_foreign_slot_binding(new_value):
        new_value = _freeze_foreign_slot_binding(
            new_value, f"first-def local '{target_name}'"
        )
    if owner is None and slot_name is None and isinstance(new_value, tuple):
        new_value = _unalias_tuple_leaves(new_value)
    # Fresh-container first-def inside staged CF re-executes per iteration:
    # every decomposable staged entry re-inits its cell (declared fresh paths only).
    if (
        is_inside_staged_cf()
        and fresh_binding
        and isinstance(new_value, (_WatchedDict, _WatchedList))
    ):
        _pyir_fresh_container_init(
            str(target_name),
            new_value,
            filename,
            lineno,
            frozenset(tuple(_p) for _p in fresh_paths),
        )
    # The default first-def gate excludes booleans because a free-
    # standing ``cond = i > 2`` is almost always a one-shot if-test
    # and the dead ref breaks PYIRToSCF.  But when the caller supplied
    # slot context (e.g. ``self._is_valid_tile = Boolean(valid)`` in
    # a jit ``__init__``), the slot store records the ref so
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
        and (
            # A live row at the local place admits the write regardless of
            # the value kind: every choked write of a row-backed place must
            # store through the row (INV-1; vectors included).
            (
                owner is None
                and slot_name is None
                and _get_slot_mv(None, target_name) is not None
            )
            or (
                not _is_vector_like(new_value)
                and (
                    # Boolean admitted with an explicit slot identity, or
                    # inside a staged loop body (the birth-block seed store
                    # keeps the ref live).
                    not _is_boolean_like(new_value)
                    or bool(_pyir_open_loop_body_blocks)
                    or (
                        owner is not None
                        and slot_name is not None
                        and _slot_storage_available(owner)
                    )
                )
            )
        )
    ):
        log().info(
            "[pyir_assign] '%s' first def inside staged CF → create ref",
            target_name,
        )
        new_value = _fresh_wrapper(new_value)
        # F-BIRTHPOS: the first-def choke runs at the binding position, so
        # the current block IS the place's birth block.
        try:
            _birth_block = ir.InsertionPoint.current.block
        except Exception:
            _birth_block = None
        fresh_mv = _create_ref(new_value, birth_block=_birth_block)
        if owner is None and slot_name is None:
            # F-PLACE: a bare-local first-def cell is the local place's
            # row; registration stamps the route a later read validates
            # (V-1) and converges sibling-region first-defs on one cell.
            fresh_mv = _set_slot_mv(None, target_name, fresh_mv)
        fresh_mv.store(new_value)
        _attach_mutable_ref(
            new_value, fresh_mv, f"pyir_assign '{target_name}' first-def"
        )
        # When the caller supplied slot context (e.g. ``self._m_idx``
        # first-def in a jit ``__init__``), register the
        # freshly-created ref against the slot so a later
        # ``pyir_read(... owner=..., slot_name=...)`` finds it via
        # the slot registry instead of falling through to the value-keyed
        # ``_mutable_ref`` (which a wrapper rebuild can drop) and
        # then to ``_create_ref`` Case-D poison fallback.
        if (
            owner is not None
            and slot_name is not None
            and _slot_storage_available(owner)
        ):
            _canon_mv = _set_slot_mv(owner, slot_name, fresh_mv)
            if _canon_mv is fresh_mv:
                # Fresh in-region attr first-def (no adopted prior cell):
                # record it so an uncovered read refuses at trace time.
                _pyir_record_cf_attr_first_def(owner, slot_name)
    elif _is_staged_value(new_value) and _can_create_ref(new_value):
        # Outside staged CF (or non-eager type): no ref yet, but a later
        # staged read must attach ``_mutable_ref`` to a local-owned object.

        # EXCEPT a no-op op returning self (e.g. a same-dtype cast): a
        # re-wrap would rebuild the object and break Python ``is`` identity.

        # Guarded to compounds (``_shape``) so SSA-backed scalars keep
        # their distinct-outer-wrapper behaviour.
        if (
            getattr(new_value, "_pyir_local_wrapper", False)
            and getattr(new_value, "_shape", None) is not None
        ):
            log().info(
                "[pyir_assign] '%s' first def → no-op self-return, "
                "preserve identity (skip re-wrap)",
                target_name,
            )
        else:
            log().info(
                "[pyir_assign] '%s' first def → fresh wrapper (no ref yet)",
                target_name,
            )
            new_value = _fresh_wrapper(new_value)
    else:
        log().info("[pyir_assign] '%s' first def → passthrough", target_name)
    # Fresh-object first-def inside staged CF (witnessed direct-ctor RHS, or a
    # call RHS whose result the bind choke proved call-born): record per-field
    # first-def facts so the lazy cell mint seeds at this block.
    if is_inside_staged_cf() and rhs_ctor is not None:
        _pyir_record_fresh_object_leaf_first_defs(
            rhs_ctor, new_value, call_born=rhs_call_born
        )
    # First-def depth bookkeeping for the straight-line type-change
    # rebind guard (see ``_slot_first_def_depth_any``).  Recorded for
    # EVERY local first-def -- primitive OR staged DSL value -- so a
    # later reassignment can tell whether the prior binding originated
    # in the current staged-CF region (straight-line) or crosses a
    # region boundary (a genuine Rule-4 join).
    if target_name is not None:
        _any_slot = _make_slot_key(target_name, owner, slot_name)
        if _any_slot is not None:
            _slot_first_def_depth_any[_any_slot] = current_staged_cf_depth()
            # F-BIRTHPOS: the binding's birth block, for every first-def
            # (a later same-block rebind is provably trace-local).
            try:
                _slot_first_def_block_any[_any_slot] = ir.InsertionPoint.current.block
            except Exception:
                _slot_first_def_block_any.pop(_any_slot, None)

    # Slot-identity wrap + per-iteration reset + first-def location
    # bookkeeping for literal first-defs; tuples recurse per leaf.
    if target_name is not None:
        new_value = _record_meta_primitive_first_def_and_store_if_registered(
            target_name, new_value, owner, slot_name
        )
    return new_value


def _assign_outside_cf(
    target_name: Any,
    old_value: Any,
    new_value: Any,
    filename: "str | None",
    lineno: "int | None",
    owner: Any,
    slot_name: Any,
) -> Any:
    log().info("[pyir_assign] '%s' outside staged CF → passthrough", target_name)
    # An already-PROMOTED bare-local slot's cell stays authoritative even
    # for a Python-phase rebind: store through it so later reads re-load.
    if owner is None:
        _pt_slot = _make_slot_key(target_name, owner, slot_name)
        _pt_ref = _slot_refs.get(_pt_slot) if _pt_slot is not None else None
        # OPAQUE-row generation hygiene: a Python-phase rebind of a local
        # with a dialect-opaque cell stores through or retires the row.
        if _pt_ref is not None and pyir is not None:
            try:
                _pt_pointee = _pt_ref.type.pointee
            except Exception:
                _pt_pointee = None
            if _pt_pointee is not None and _pyir_ir_type_is_opaque(_pt_pointee):
                _pt_new_raw = _raw_backing_ir_value(new_value)
                if (
                    isinstance(_pt_new_raw, ir.Value)
                    and _pt_new_raw.type == _pt_pointee
                    and _value_dominates_current_ip(_pt_ref)
                ):
                    _pyir_emit_store(
                        _pt_new_raw,
                        _pt_ref,
                        choke=f"Python-phase opaque rebind '{target_name}'",
                    )
                    _pyir_record_slot_template(_pt_slot, new_value)
                else:
                    _slot_refs.pop(_pt_slot, None)
                    _slot_templates.pop(_pt_slot, None)
                return new_value
        if _pt_ref is not None and pyir is not None:
            _pt_is_primitive = isinstance(new_value, (bool, int, float, _WatchedM))
            _pt_is_staged = _is_staged_value(new_value) and not (
                isinstance(new_value, _WatchedM)
            )
            if _pt_is_staged and not _is_compound_single_leaf(new_value):
                _pt_ir = new_value.ir_value()
                if _pyir_ref_pointee_type_changed(_pt_ref, new_value):
                    # Fresh redefinition at a new width: re-mint and
                    # republish, exactly like the in-CF D1 store path.
                    _pt_ref = pyir.ref(_pt_ir)
                    _slot_refs[_pt_slot] = _pt_ref
                # F-TYPEID: the store advances the row's wrapper template.
                _pyir_record_slot_template(_pt_slot, new_value)
                _pyir_emit_store(_pt_ir, _pt_ref)
                log().info(
                    "[pyir_assign] '%s' Python-phase rebind of promoted "
                    "slot → store-through (cell stays authoritative)",
                    target_name,
                )
                return _load_as_dsl(_pt_ref, place=_pt_slot)
            if _pt_is_primitive:
                _pt_py = (
                    new_value.python_value
                    if isinstance(new_value, _WatchedM)
                    else new_value
                )
                _pyir_emit_store(_emit_constant_for_ref(_pt_ref, _pt_py), _pt_ref)
                log().info(
                    "[pyir_assign] '%s' Python-phase primitive rebind of "
                    "promoted slot → store-through",
                    target_name,
                )
                return _load_as_dsl(_pt_ref, place=_pt_slot)
        # A VALUE-KEYED place row (a local promoted by a prior staged
        # region, never published as a D1 `_slot_refs` row) is equally
        # authoritative for later reads (R1): a Python-phase rebind must
        # store through it, or the next staged region reads the stale
        # pre-rebind cell.
        if _pt_ref is None and pyir is not None:
            _pt_mv = _get_slot_mv(None, target_name)
            if (
                _pt_mv is not None
                and _pt_mv._is_ref_accessible()
                and _is_staged_value(new_value)
                and not isinstance(new_value, _WatchedM)
                and _can_carry_leaf_ref(new_value)
                and not _is_compound_single_leaf(new_value)
                # A type-changing rebind of the promoted row (an
                # Int32-promoted slot rebound to a Boolean, say) must not
                # store through: the write is type-unfaithful and the cell
                # cannot be re-minted under a live while-carry. Fall through
                # so the join check refuses it as TYPE_UNSTABLE_JOIN.
                and _mlir_types_match(_pt_mv._value, new_value)
            ):
                # INV-1' no-op: the binding already IS the row's content.
                if (
                    getattr(new_value, "_mutable_ref", None) is _pt_mv
                    and new_value is _pt_mv._value
                ):
                    return new_value
                # The guard above proved the pointee is unchanged, so this
                # store is faithful (a same-type re-init of the row).
                _pt_mv.store(new_value)
                new_value = _pt_mv._reconstruct(new_value.ir_value())
                _attach_mutable_ref(
                    new_value,
                    _pt_mv,
                    f"pyir_assign '{target_name}' Python-phase row rebind",
                )
                _pyir_adopt_stored_representative(_pt_mv, new_value)
                log().info(
                    "[pyir_assign] '%s' Python-phase rebind of promoted "
                    "place row → store-through (row stays authoritative)",
                    target_name,
                )
                return new_value
    # Copy-on-bind alias split: a Python-phase rebind re-keys a _WatchedM to the
    # target slot / fresh-wraps a staged scalar so two names never share a ref.
    if new_value is not old_value:
        if isinstance(new_value, _WatchedM):
            _tgt_slot = _make_slot_key(target_name, owner, slot_name)
            if _tgt_slot is not None and new_value._slot_key != _tgt_slot:
                log().info(
                    "[pyir_assign] '%s' copy-on-bind split: _WatchedM "
                    "re-keyed %s -> %s",
                    target_name,
                    new_value._slot_key,
                    _tgt_slot,
                )
                new_value = _WatchedM(new_value.python_value, _tgt_slot)
        elif (
            _is_staged_value(new_value)
            and _can_carry_leaf_ref(new_value)
            and not _is_compound_single_leaf(new_value)
        ):
            _split = _fresh_wrapper(new_value)
            if _split is not new_value:
                log().info(
                    "[pyir_assign] '%s' copy-on-bind split: fresh scalar wrapper (%s)",
                    target_name,
                    type(new_value).__name__,
                )
                new_value = _split
    # Python-phase polarity: the NEW object becomes the binding; stamp the
    # OLD generation superseded with pre-adoption store versions.
    if (
        old_value is not None
        and old_value is not new_value
        and type(old_value) is type(new_value)
        and _pyir_is_generation_compound(old_value)
    ):
        try:
            _rebind_slot = _make_slot_key(target_name, owner, slot_name)
        except Exception:
            _rebind_slot = None
        _pyir_record_generation_rebind(
            _rebind_slot,
            old_value,
            new_value,
            target_name,
            filename,
            lineno,
            superseded_obj=old_value,
        )
    # A Python-phase rebind still lands on places: leaves whose place owns
    # a live cell get the store + re-alias so later reads resolve ONE cell.
    try:
        _pyir_route_binding_to_live_place_cells(owner, slot_name, new_value)
    except Exception:
        pass
    return new_value


# M→M compound auto-decomposition: both old and new are compound
# objects (not directly staged) with staged leaf fields.  Decompose
# into per-field pyir_assign calls so the compiler sees each SSA
# update through pyir.ref/store.
def _assign_m2m_compound(
    target_name: Any,
    old_value: Any,
    new_value: Any,
    filename: "str | None",
    lineno: "int | None",
    owner: Any,
    slot_name: Any,
    _binding_slot: Any,
    _cur_cf_depth: int,
) -> Any:
    # A value-tree whole-object BRANCH-SELECT must NOT take the ``__dict__``
    # walk (it would store a host-computed sub-leaf into a kernel ref).

    # The no-op arm (``old is new``) passes through: re-selecting the
    # object the name already holds changes nothing to carry.

    # A select between two structurally DISTINCT prototypes of one class is
    # joined as the pytree frontend joins it: the canonical leaves become
    # ``scf.if`` results and the binding is rebuilt from the ENTRY prototype
    # (its compile-time fields) at the ``if`` close; the arm itself keeps the
    # selected object.

    # Gated to a LOOP-FREE ``scf.if``: a per-iteration meta change must
    # still hit the meta-primitive guard via the ``__dict__`` walk.
    if (
        _implements_dynamic_expression(old_value)
        and _innermost_enclosing_loop_op_at_ip() is None
        and (_select_ifs := _loop_free_enclosing_if_ops_at_ip())
    ):
        if old_value is new_value:
            log().info(
                "[pyir_assign] '%s' value-tree whole-object no-op branch-select "
                "rebind → passthrough",
                target_name,
            )
            return new_value
        if _value_tree_prototype_mismatch(old_value, new_value) is not None:
            if not _pyir_join_whole_object_select(
                target_name, old_value, new_value, _select_ifs, filename, lineno
            ):
                # The binding was born in this arm: nothing outside the arm
                # to join with, and a post-``if`` read is refused as a
                # branch-born first-def.
                log().info(
                    "[pyir_assign] '%s' value-tree whole-object branch-select "
                    "of an arm-born binding → passthrough",
                    target_name,
                )
            return new_value
    # Whole-object rebind of a top-level LIST of ref-carryable staged
    # scalars: per-element ``pyir_assign`` on the OLD list's subscript slots.

    # The old list stays the binding carrier (it accumulates element refs).

    # Gated to ALL elements ref-carryable staged on both sides; otherwise
    # fall through to the existing decompose / rejection logic unchanged.

    # ``old_value is new_value`` takes the same path: each element
    # self-assign stores the current SSA through the element's slot ref.
    if (
        isinstance(old_value, list)
        and old_value
        and len(old_value) == len(new_value)
        and all(
            _is_staged_value(e)
            and _can_carry_leaf_ref(e)
            and not _is_compound_single_leaf(e)
            for pair in zip(old_value, new_value)
            for e in pair
        )
    ):
        log().info(
            "[pyir_assign] '%s' list whole-rebind → per-element "
            "decomposition (%d staged elements)",
            target_name,
            len(old_value),
        )
        for _i, (_old_elem, _new_elem) in enumerate(zip(old_value, new_value)):
            old_value[_i] = pyir_assign(
                f"{target_name}[{_i}]",
                _old_elem,
                _new_elem,
                filename,
                lineno,
                owner=old_value,
                slot_name=_i,
            )
        return old_value  # old list carries the element refs
    if old_value is new_value and _has_decomposable_staged_fields(old_value):
        # ``x = x`` (or ``c = a`` while ``c`` already names ``a`` at trace
        # time) is a no-op in Python.  Decomposing it would store each field's
        # trace-entry wrapper back into the field's cell, resetting a loop-
        # carried field to its entry value on every iteration.
        log().info(
            "[pyir_assign] '%s' whole-object self-assign → no-op",
            target_name,
        )
        return old_value
    if _has_decomposable_staged_fields(old_value):
        log().info(
            "[pyir_assign] '%s' M→M auto-decomposition (type=%s)",
            target_name,
            type(old_value).__name__,
        )
        # m2m polarity: the binding keeps the old object as carrier; the
        # generation bump lets a pre-rebind alias capture detect staleness.
        _gen_rebind_rec = _pyir_record_generation_rebind(
            _binding_slot,
            old_value,
            new_value,
            target_name,
            filename,
            lineno,
            allow_empty_cells=True,
        )
        _PYIR_M2M_DECOMPOSE_DEPTH[0] += 1
        try:
            with _PyirGenEventSuppress():
                _decompose_m2m_assign(
                    target_name, old_value, new_value, filename, lineno
                )
        finally:
            _PYIR_M2M_DECOMPOSE_DEPTH[0] -= 1
        # Cells the decompose walk itself minted enter the baseline as
        # born-at-rebind (a pre-rebind alias read of them always diverges).
        _pyir_complete_generation_rebind_cells(_gen_rebind_rec, old_value)
        # The old object now carries the NEW (body-born) object's state: a
        # later re-point to it is not an identity-rebind to a pre-existing one.
        _pyir_region_note_recarried(old_value)
        # ... and stands for a staged selection the new object was (its write
        # wall / candidate record follow the carrier).
        if _PYIR_STAGED_SELECTION_ARMS:
            _pyir_propagate_staged_selection(new_value, old_value)
        return old_value  # I1: return old — it accumulates refs
    if _has_any_staged_content(old_value):
        # An opaque-leaf value-tree is not scalar-decomposable but is legal:
        # its carry carries on its canonical extract-leaf at region-close.
        if _is_opaque_leaf_value_tree(old_value):
            log().info(
                "[pyir_assign] '%s' opaque-leaf value-tree rebind → "
                "passthrough (region-close carry owns the carry)",
                target_name,
            )
            return new_value
        # MIXED-leaf value-tree generalisation: a fresh same-class rebind
        # whose NEW canonical leaves all DOMINATE the bind point loses no carry.

        # Opaque leaves carry at region-close, scalar leaves via the M2S
        # slot machinery -- pass through, as non-PyIR rebinds the local.

        # Gated to a NON-carried slot and all-dominating NEW leaves so a
        # genuine region-crossing type-changing carry is not accepted.
        _co_slot = _make_slot_key(target_name, owner, slot_name)
        if _co_slot is None or _co_slot not in _slot_refs:
            _new_leaves = _pyir_extract_leaf_values(new_value)
            if _new_leaves and all(
                _value_dominates_current_ip(_lf) for _lf in _new_leaves
            ):
                log().info(
                    "[pyir_assign] '%s' mixed-leaf value-tree whole-object rebind "
                    "(all new canonical leaves self-dominate) → passthrough "
                    "(region-close / M2S carry owns the carry)",
                    target_name,
                )
                return new_value
        raise DSLUserCodeError(
            DiagId.CONTAINER_OBJECT_REPLACED,
            filename=filename,
            lineno=lineno,
            var=target_name,
        )
    # Pure meta object (no staged fields): harmless replacement, except
    # for a region-crossing all-meta-primitive rebind, which carries
    # per-field (the old object stays the binding carrier).
    _carrier = _pyir_carry_meta_compound_region_rebind(
        old_value,
        new_value,
        _binding_slot,
        _cur_cf_depth,
        target_name,
        filename,
        lineno,
    )
    if _carrier is not None:
        _pyir_region_note_recarried(_carrier)
        return _carrier
    log().info(
        "[pyir_assign] '%s' pure meta compound → passthrough",
        target_name,
    )
    return new_value


# M->S promotion: old is meta, new is staged.
# This is only reachable when auto_m2s=True (otherwise
# assign_meta_staged_check raises above).
# Promote old_value to new_value's type, create ref at function entry.
def _assign_m2s_promotion(
    target_name: Any,
    old_value: Any,
    new_value: Any,
    filename: "str | None",
    lineno: "int | None",
    owner: Any,
    slot_name: Any,
) -> Any:
    dsl_type = type(new_value)
    # Domain of the promotion choke: a meta PRIMITIVE old value -- the only
    # shape with a declared staged counterpart to seed the cell with (cf.
    # ``_declared_m2s_promotion_class``).  A CONTAINER old value has none, and
    # blindly running ``dsl_type(old_value)`` on one mis-reports the judgment:
    # a ``_Tensor`` target raises ``TypeError`` -> PHASE_CONVERSION_FAILED,
    # whose "create it as a runtime value before the loop" fix-it is
    # unactionable for a tuple, while a ``Numeric`` target raises
    # ``DSLRuntimeError`` -> error[INTERNAL], which is not a DSL bug at all.
    # Judge the SHAPE here instead: re-binding a container name to a runtime
    # value inside a run-time region is a structure change the region cannot
    # join.  (The structural tuple<->staged gate in ``pyir_assign`` admits the
    # sound cases -- an all-staged tuple, and a staged + inert-meta tuple whose
    # binding was born inside the region -- before reaching here.)
    if isinstance(old_value, (tuple, list, dict, set, frozenset)):
        raise DSLUserCodeError(
            DiagId.CONTAINER_REBOUND_TO_RUNTIME_VALUE,
            filename=filename,
            lineno=lineno,
            var=target_name,
            old_type=type(old_value).__name__,
            old_value=repr(old_value),
            new_type=dsl_type.__name__,
        )
    try:
        promoted = dsl_type(old_value)
    except (TypeError, ValueError, DSLRuntimeError):
        # ``DSLRuntimeError`` is the DSL's internal-bug envelope; a constructor
        # raising it for an unconvertible old value is a user-code shape
        # mismatch, so re-code it rather than let it surface as error[INTERNAL].
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
        owner is not None and slot_name is not None and _slot_storage_available(owner)
    )
    mv: "MutableValue | None" = None
    if have_slot_m2s:
        existing_slot_mv = _get_slot_mv(owner, slot_name)
        if existing_slot_mv is not None and existing_slot_mv._is_ref_accessible():
            mv = existing_slot_mv
    if mv is None:
        mv = _create_ref(
            promoted,
            birth_block=_pyir_recorded_birth_block(target_name, owner, slot_name),
        )
        if have_slot_m2s:
            _set_slot_mv(owner, slot_name, mv)
        elif owner is None and slot_name is None:
            # F-PLACE: a bare-local promotion cell is the local place's
            # row; registration stamps the route a later read validates.
            mv = _set_slot_mv(None, target_name, mv)
    mv.store(new_value)
    # Anti-aliasing: when slot context is present ALWAYS reconstruct so
    # the _mutable_ref attached below cannot leak onto a shared value.
    if have_slot_m2s:
        new_value = mv._reconstruct(new_value.ir_value())
    else:
        existing_mv = getattr(new_value, "_mutable_ref", None)
        if existing_mv is not mv:
            new_value = mv._reconstruct(new_value.ir_value())
    _attach_mutable_ref(new_value, mv, f"pyir_assign '{target_name}' M->S promotion")
    # The reconstructed wrapper rewraps the just-stored raw: record it as
    # the cell's canonical representative for the staged-read choke.
    _pyir_adopt_stored_representative(mv, new_value)
    return new_value


def _assign_store_through(
    target_name: Any,
    old_value: Any,
    new_value: Any,
    filename: "str | None",
    lineno: "int | None",
    owner: Any,
    slot_name: Any,
) -> Any:
    # Find or create MutableValue.
    have_slot = (
        owner is not None and slot_name is not None and _slot_storage_available(owner)
    )
    mv = None
    if have_slot:
        mv = _get_slot_mv(owner, slot_name)
    else:
        # INV-1': the resolved place row is the commit target whenever one
        # exists -- the old value's route is a fact about the VALUE, never
        # about the row's currency, so route equality can never dedup a
        # commit the row has not seen.
        if owner is None and slot_name is None:
            mv = _get_slot_mv(None, target_name)
        if mv is None:
            mv = getattr(old_value, "_mutable_ref", None)
    log().info("[pyir_assign] '%s' existing mv=%s", target_name, mv)

    # The type-change predicate is pure in (old_value, new_value) and neither
    # is rebound below, so its three sites here share one evaluation.
    _stc_memo: "bool | None" = None

    def _staged_type_changed_once() -> bool:
        nonlocal _stc_memo
        if _stc_memo is None:
            _stc_memo = _staged_type_changed(old_value, new_value)
        return _stc_memo

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
    # (same wrapper class on both sides) whose MLIR type CHANGES at a region
    # crossing must NOT silently create a fresh, non-escaping ref -- the new
    # value would be computed but never carried out (no scf result / iter_arg),
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
        and _staged_type_changed_once()
    ):
        _tc_slot = _make_slot_key(target_name, owner, slot_name)
        _tc_first_depth = (
            _slot_first_def_depth_any.get(_tc_slot) if _tc_slot is not None else None
        )
        _is_straight_line = (
            _tc_first_depth is not None and _tc_first_depth >= current_staged_cf_depth()
        )
        if not _is_straight_line:
            # Surface the old vs new value in its human-readable form -- the
            # same repr ``print(x)`` shows (e.g. a tensor wrapper prints as
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
        mv is not None and _can_create_ref(new_value) and _staged_type_changed_once()
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
        and _staged_type_changed_once()
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

    reuse_accessible_ref = mv is not None and mv._is_ref_accessible()
    if reuse_accessible_ref:
        log().info("[pyir_assign] '%s' reuse ref (accessible)", target_name)
    elif not _can_carry_leaf_ref(old_value) and not type_changed:
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
        #
        # F-BIRTHPOS: a type change births a fresh generation HERE; a same-type
        # lazy mint seeds at the place's RECORDED first-def block (if any).
        if type_changed:
            try:
                _birth_block = ir.InsertionPoint.current.block
            except Exception:
                _birth_block = None
        else:
            _birth_block = _pyir_recorded_birth_block(target_name, owner, slot_name)
        mv = _create_ref(
            new_value if type_changed else old_value, birth_block=_birth_block
        )
        if have_slot:
            _set_slot_mv(owner, slot_name, mv)
        else:
            if owner is None and slot_name is None:
                # F-PLACE: a bare-local rebind cell is the local place's row;
                # registration stamps the route a later read validates (V-1).
                mv = _set_slot_mv(None, target_name, mv)
            # Publish a fresh, function-entry-dominating ref under the slot's D1
            # name key so a post-region read loads it (conditional-def carry).
            try:
                d1_slot = _make_slot_key(target_name, owner, slot_name)
                if (
                    d1_slot is not None
                    and d1_slot not in _slot_refs
                    and _ref_dominates_whole_function(mv)
                ):
                    _slot_refs[d1_slot] = mv.ref
                    _pyir_record_slot_template(d1_slot, mv._value)
                    log().info(
                        "[pyir_assign] '%s' published entry-block ref as D1 slot",
                        target_name,
                    )
            except Exception:
                pass
        log().info("[pyir_assign] '%s' ref created via _create_ref", target_name)

    # Every non-passthrough path above bound a cell: reuse or fresh mint.
    assert mv is not None

    # INV-1' no-op re-walk: an unchanged binding's cell IS the row cell, so a
    # re-observation walk commits nothing (zero new write positions).
    if (
        reuse_accessible_ref
        and getattr(new_value, "_mutable_ref", None) is mv
        and new_value is mv._value
    ):
        return new_value

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

    # A staged store replacing a fold-witnessed old value invalidates the fold:
    # refuse loudly (covers writes whose pre-read did not promote).
    _pyir_check_staged_fold_witness(old_value, target_name)

    # Child-region escapee: the new value's SSA was produced inside an already-closed
    # CF region; the in-region store carries as an iter_arg, so skip the post-store.
    if reuse_accessible_ref:
        skipped = _pyir_skip_trapped_child_region_writeback(mv.ref, new_value, mv=mv)
        if skipped is not None:
            log().info(
                "[pyir_assign] '%s' new value from closed child region "
                "(ref already written in-loop) -> skip redundant store",
                target_name,
            )
            return skipped

    _pre_store_ref = mv.ref
    mv.store(new_value)
    log().info("[pyir_assign] '%s' stored", target_name)
    # Width-changing rebind: ``MutableValue.store`` re-minted the cell at the
    # new MLIR type, so the name denotes a NEW place generation. Republish the
    # new cell under the D1 name key when it dominates the whole function,
    # else retire the entry so reads resolve the value-carried ref.
    try:
        if _pre_store_ref is not None and mv.ref is not None:
            _same_ref = False
            try:
                _same_ref = bool(_pre_store_ref == mv.ref)
            except Exception:
                _same_ref = _pre_store_ref is mv.ref
            if not _same_ref:
                _wc_slot = _make_slot_key(target_name, owner, slot_name)
                if _wc_slot is not None and _wc_slot in _slot_refs:
                    if _ref_dominates_whole_function(mv):
                        _slot_refs[_wc_slot] = mv.ref
                        _pyir_record_slot_template(_wc_slot, mv._value)
                    else:
                        del _slot_refs[_wc_slot]
                        _slot_templates.pop(_wc_slot, None)
    except Exception:
        pass

    # Do NOT emit pyir.load here — the loaded SSA value would be
    # trapped inside the current CF region.  Instead, return new_value
    # with _mutable_ref attached.  When the value is read later,
    # pyir_read (or _pyir_auto_load_arg) emits a fresh pyir.load
    # at the correct insertion point outside the CF region.
    #
    # Anti-aliasing: when slot context is provided ALWAYS reconstruct so
    # the wrapper carrying this ref belongs exclusively to this slot.
    # Otherwise, only reconstruct when new_value does not already carry
    # this mv (the anti-aliasing rule for locals).
    if have_slot:
        new_value = mv._reconstruct(new_value.ir_value())
    else:
        existing_mv = getattr(new_value, "_mutable_ref", None)
        if existing_mv is not mv:
            new_value = mv._reconstruct(new_value.ir_value())
    _attach_mutable_ref(new_value, mv, f"pyir_assign '{target_name}'")
    # The returned wrapper rewraps the just-stored raw: make it the cell's
    # canonical representative so a later read proves staleness and reloads.
    _pyir_adopt_stored_representative(mv, new_value)

    return new_value


# Attribute name carrying the ``(base, attr)`` pairs a staged loop-body
# function's ORIGINAL code assigns directly (the declared write facts).
PYIR_REGION_ATTR_WRITES_ATTR = "__pyir_region_attr_writes__"
# Attribute name carrying the ``(base, method)`` pairs a staged loop-body
# function's ORIGINAL code calls on Name-rooted receiver paths (dotted base);
# each pair completes into write facts through class facts at region entry.
PYIR_REGION_METHOD_CALLS_ATTR = "__pyir_region_method_calls__"
# Attribute name carrying the ``(func_name, arg_base)`` pairs a staged
# loop-body function's ORIGINAL code calls as a bare-Name free function with a
# Name-rooted first argument (``step(c)``); each pair completes into write
# facts through the callee's first-parameter write facts at region entry.
PYIR_REGION_FREE_CALLS_ATTR = "__pyir_region_free_calls__"
# Attribute name carrying the ``(path, line)`` pairs of the places a staged
# loop-body function's ORIGINAL code does not read before it first stores
# them (dead on body entry); ``line`` is 0 for an unconditional top-level
# store, else the line of the nested store that is the first occurrence.
PYIR_REGION_DEAD_ON_ENTRY_ATTR = "__pyir_region_dead_on_entry__"


def pyir_tag_region_attr_writes(
    attr_writes: "tuple[tuple[str, str], ...]",
    method_calls: "tuple[tuple[str, str], ...]" = (),
    free_calls: "tuple[tuple[str, str], ...]" = (),
    dead_on_entry: "tuple[tuple[str, int], ...]" = (),
) -> "Callable[[Any], Any]":
    """Decorator factory tagging a staged loop-body function with the ``(base, attr)``
    pairs its ORIGINAL body assigns directly, the ``(base, method)`` pairs
    it calls on Name-rooted receiver paths, the ``(func_name, arg_base)``
    pairs it calls as free functions with a Name-rooted first argument, and
    the ``(path, line)`` pairs of the places dead on body entry."""

    def _tag(func: Any) -> Any:
        setattr(func, PYIR_REGION_ATTR_WRITES_ATTR, tuple(attr_writes))
        setattr(func, PYIR_REGION_METHOD_CALLS_ATTR, tuple(method_calls))
        setattr(func, PYIR_REGION_FREE_CALLS_ATTR, tuple(free_calls))
        setattr(func, PYIR_REGION_DEAD_ON_ENTRY_ATTR, tuple(dead_on_entry))
        return func

    return _tag


_PYIR_BIND_VALUE_UNSET = object()


def _meta_kind(v: Any) -> "type | None":
    """The Python scalar kind of a meta value (``bool``/``int``/``float``,
    watched wrappers included), ``type(None)`` for None, None for anything
    else (a staged value or an object)."""
    if v is None:
        return type(None)
    if _is_staged_value(v):
        return None
    for kind in (bool, int, float):
        if isinstance(v, kind):
            return kind
    return None


def _pyir_sibling_pair_conflict(prior: Any, value: Any) -> "str | None":
    """Why *prior* (the value a sibling arm bound) and *value* (the value
    this arm binds) cannot both be carried past the if by one slot, or None
    when they can (the same meta value, or a pair promotion may join).  The
    read after the if turns the kind into a diagnostic
    (``_pyir_check_cf_attr_first_def_read``)."""
    if value is prior and not _is_staged_value(value):
        return None  # the same Python object on both arms: nothing to carry
    prior_kind, value_kind = _meta_kind(prior), _meta_kind(value)
    if (prior_kind is None and not _is_staged_value(prior)) or (
        value_kind is None and not _is_staged_value(value)
    ):
        # An object bound per arm: objects live on the Python side and have
        # no staged form, so which one the attribute holds cannot follow the
        # runtime path.
        return "object"
    if (
        prior_kind is not None
        and value_kind is not None
        and type(None) not in (prior_kind, value_kind)
        and prior_kind is not value_kind
    ):
        # int on one arm, float on the other: carrying it would mean the
        # compiler picks the join type and inserts the cast; that is the
        # user's call, in the branch.
        return "type"
    if (
        not _is_staged_value(value)
        and value_kind is not None
        and value_kind is prior_kind
        and value == prior
    ):
        return None  # the same meta value on both arms: nothing to carry
    if not is_auto_m2s_enabled() or prior is None or value is None:
        # Different meta values with promotion off, or ``None`` on either arm
        # (no staged form): the promotion diagnostic at the read after the if.
        return "meta"
    return None


def _pyir_bind_sibling_first_def(
    owner: Any,
    slot_name: Any,
    target_name: "str | None" = None,
    site: "tuple | None" = None,
    value: Any = _PYIR_BIND_VALUE_UNSET,
) -> bool:
    """A first-def of an attribute that a SIBLING arm already first defined
    (the arm entry unbound the sibling's binding, so the store on this arm is
    a first-def again in Python) is, for the record, a write over the
    sibling's value: route it through ``pyir_assign`` with that value as the
    old one, so the sibling-arm rule applies (a meta rewrite promotes, or
    refuses loudly with automatic promotion off) and this arm's path joins the
    record.  Returns False when there is no such sibling value to bind over,
    leaving the plain first-def record to the caller."""
    key = (id(owner), slot_name)
    rec = _PYIR_CF_ATTR_FIRST_DEFS.get(key)
    if rec is None:
        return False
    if any(
        _pyir_arm_path_covers(p, _pyir_current_region_arm_path()) for p in rec["paths"]
    ):
        return False
    prior = _PYIR_DROPPED_SIBLING_VALUES.get(key, _PYIR_BIND_VALUE_UNSET)
    if prior is _PYIR_BIND_VALUE_UNSET:
        return False  # nothing was unbound for this arm: a plain first-def
    if _is_staged_value(prior):
        # The sibling's value is an SSA of a closed arm: it cannot serve as the
        # old value of a store here (it does not dominate).  Leave the plain
        # first-def record to the caller; the read after the if refuses.
        return False
    # The place is bound on this arm too: a promotion here or later in the
    # arm seeds the cell with the sibling's value at the enclosing entry (a
    # load before this arm's own store then reads it), not with the
    # placeholder of a binding born in the sibling arm alone.
    try:
        _place = _make_slot_key(None, owner, slot_name)
    except Exception:
        _place = None
    if _place is not None:
        _slot_first_def_inside_cf.pop(_place, None)
        _slot_first_def_block.pop(_place, None)
    if value is _PYIR_BIND_VALUE_UNSET:
        try:
            value = _pyir_holder_read(owner, slot_name)
        except (AttributeError, KeyError):
            return False  # the arm did not leave the attribute bound after all
    label = (
        target_name
        if isinstance(target_name, str)
        else f"{type(owner).__name__}.{slot_name}"
    )
    filename, lineno = site if site and site[0] is not None else (None, None)
    # What the arms disagree on decides what happens at the read after the if
    # (``_pyir_check_cf_attr_first_def_read``).  A read inside this arm sees
    # its own value, exactly as Python does, so nothing is refused here; the
    # record remembers the conflict and the if exit carries it to the
    # enclosing path.  This is the FIRST value the arm binds; the arm's end
    # compares its LAST (``_pyir_settle_sibling_arm_values``).
    conflict = _pyir_sibling_pair_conflict(prior, value)
    if conflict is not None:
        rec["conflict"] = (conflict, prior, value, filename, lineno)
        _pyir_update_cf_attr_first_def_on_write(owner, slot_name)
        return True
    value_kind = _meta_kind(value)
    if (
        value_kind is not None
        and not _is_staged_value(value)
        and value_kind is _meta_kind(prior)
        and value == prior
    ):
        # Both arms bind the same meta value: nothing to carry, the slot may
        # stay meta; this arm's path still joins the record.
        _pyir_update_cf_attr_first_def_on_write(owner, slot_name)
        return True
    if value_kind is not None and _pyir_open_loop_body_blocks:
        # Both arms bind meta values and promotion is on, but the if sits in
        # a staged loop body: the promoted slot would have to be carried
        # across iterations as well as across the arms, which is not done
        # yet.  Refuse here, at the write, naming the fix.
        raise DSLUserCodeError(
            DiagId.PHASE_META_FIELD_CHANGED_IN_CF,
            filename=filename,
            lineno=lineno,
            owner_class=type(owner).__name__,
            attr=slot_name,
            old_value=prior,
            new_value=value,
        )
    result = pyir_assign(
        label, prior, value, filename, lineno, owner=owner, slot_name=slot_name
    )
    if result is not value:
        _pyir_holder_store(owner, slot_name, result)
    return True


def _pyir_short_repr(value: Any, limit: int = 40) -> str:
    """A bounded ``repr`` for diagnostics (an object's repr may be long)."""
    try:
        text = repr(value)
    except Exception:
        text = f"<{type(value).__name__}>"
    return text if len(text) <= limit else text[: limit - 3] + "..."


def _pyir_mark_if_arm_meta_leaves(
    before: "dict[int, tuple[Any, frozenset, dict[str, Any]]]", arm_block: Any
) -> None:
    """Arm end of a runtime ``scf.if``: a meta-primitive attribute leaf that
    was bound at the arm's start, is still meta and unpromoted at its end and
    holds a different value was rewritten on one traced path only, so its
    value after the if depends on the path taken.  A meta slot cannot carry
    that, and whether the leaf is read afterwards is not visible here, so the
    leaf gets the arm-local escape mark (``_PYIR_ARM_LOCAL_META_WRITES``):
    a consumption inside the arm is exact, a consumption from outside it
    refuses with PHASE_ARM_LOCAL_CONSTANT_ESCAPES, in both modes (with
    promotion on a leaf still meta here was written by a spelling promotion
    never saw).  A raw payload left by such a spelling (``setattr``, a tuple
    target, ``__dict__``, a plain method) is wrapped so its consumption
    reaches the check like a choked store's does.  Judged at EVERY arm's end
    against that arm's start (``_pyir_attr_keysets``): an arm that moves the
    leaf and a later arm that moves it back leave the if exit equal to the
    entry.  A key born on the arm is not in *before* and stays with the
    first-def rules.  A leaf that turned into a non-primitive (None, a tuple,
    an object, a string) is refused here in both modes: no type joins the two
    paths, and a read-side mark has no wrapper to live on."""
    if not before:
        return
    site = None
    for _hid, (holder, _keys, metas) in before.items():
        if not metas:
            continue
        storage = _instance_storage_items(holder)
        if storage is None:
            continue
        for attr, entry in metas.items():
            if attr not in storage:
                continue
            cur = storage[attr]
            if _is_staged_value(cur):
                continue
            now = _pyir_meta_leaf_value(cur)
            if now is None:
                # A meta primitive turned into None, a tuple, an object, a
                # string: nothing in either mode can carry that across the
                # if (no type to join on), so refuse here; a read-side mark
                # has no wrapper to live on for such a value.
                if site is None:
                    site = _first_non_dsl_caller_location()
                raise DSLUserCodeError(
                    DiagId.PHASE_ARM_REWRITE_NOT_STAGEABLE,
                    filename=site[0],
                    lineno=site[1],
                    var=f"{type(holder).__name__}.{attr}",
                    old_type=type(entry).__name__,
                    old_value=entry,
                    new_type=type(cur).__name__,
                    new_value=_pyir_short_repr(cur),
                )
            try:
                moved = type(now) is not type(entry) or bool(now != entry)
            except Exception:
                moved = True
            if not moved:
                continue
            try:
                place = _make_slot_key(None, holder, attr)
            except Exception:
                place = None
            if place is None or place in _slot_refs:
                continue  # promoted: the staged cell carries it
            if site is None:
                site = _first_non_dsl_caller_location()
            _pyir_arm_local_mark_leaf(holder, attr, now, place, arm_block, site)


def _pyir_settle_sibling_arm_values(roots: "list") -> None:
    """Arm end: an attribute a SIBLING arm first defined and this arm bound
    again is carried past the if by the value the arm LEAVES, not the first
    one it bound (``c.k = 1`` followed by ``c.k = c.k * 2`` leaves 2).  Compare
    that final meta value with the sibling's saved value and record the
    conflict the first bind did not see; a staged final value was carried by
    the store that produced it.  Runs inside the arm's region scope, before
    the arm exit restores the sibling's value."""
    if not _PYIR_DROPPED_SIBLING_VALUES or _pyir_gen_events_suppressed():
        return
    cur = _pyir_current_region_arm_path()
    if not cur:
        return
    for (oid, slot_name), prior in list(_PYIR_DROPPED_SIBLING_VALUES.items()):
        rec = _PYIR_CF_ATTR_FIRST_DEFS.get((oid, slot_name))
        if rec is None or rec.get("conflict") is not None:
            continue
        if not any(_pyir_arm_path_covers(cur, p) for p in rec["paths"]):
            continue  # this arm did not bind it; the arm exit restores prior
        handle = _GEN_OBJ_KEEPALIVE.get(oid)
        owner = handle() if isinstance(handle, weakref.ReferenceType) else handle
        if owner is None:
            continue
        items = _instance_storage_items(owner)
        if items is None or slot_name not in items:
            continue
        final = items[slot_name]
        if _is_staged_value(final) or _is_staged_value(prior):
            continue
        conflict = _pyir_sibling_pair_conflict(prior, final)
        if conflict is None and final != prior:
            # Promotion is on but no store promoted the slot (a meta rewrite
            # after an equal first bind): the read after the if would see
            # this arm's constant on every path.
            conflict = "meta"
        if conflict is not None:
            site = rec.get("site") or (None, None)
            rec["conflict"] = (conflict, prior, final, site[0], site[1])


def pyir_note_attr_first_def(
    target_name: str,
    owner: Any,
    slot_name: Any,
    value: Any,
    rhs_ctor: Any = None,
    site: "tuple | None" = None,
) -> None:
    """Trace-only note for an attr first-def inside staged CF (the
    preprocessor's first-def branch is a plain setattr, invisible otherwise).
    The record is a binding-position fact, so every value kind records.

    *rhs_ctor* is the re-loaded callee of a call RHS (same witness as
    ``pyir_assign``): a freshly-constructed object bound to a brand-new
    attribute records its fields' birth block here, since no ``pyir_assign``
    choke runs on this branch.

    *site* is the binding's ``(filename, lineno)`` when the caller has it."""
    if owner is None or slot_name is None:
        return
    slot_name = _pyir_canonical_slot_name(owner, slot_name)
    # An attr first-def binds its RHS in Python VALUE terms (the plain-local
    # first-def freeze, one hop deeper).  The preprocessor's first-def
    # branch is a plain setattr, so the storage holds the RHS object itself:
    # a value still re-resolving a foreign cell would let this attribute's
    # first place-named read claim that cell as its row (first-wins
    # rooting), and every later read would follow the source binding
    # instead of the stash.  Fires at ANY scope, before the region gates.
    if _carries_foreign_slot_binding(value):
        frozen = _freeze_foreign_slot_binding(value, f"attr first-def '{target_name}'")
        if frozen is not value:
            try:
                bound = _pyir_holder_read(owner, slot_name)
            except Exception:
                bound = None
            # Only plain storage holding the RHS object is rebound; a
            # descriptor-mediated write already ran its setter once.
            if bound is value:
                _pyir_holder_store(owner, slot_name, frozen)
                value = frozen
    if not is_inside_staged_cf() or is_inside_constexpr_loop():
        return
    # The branch (absent at statement entry) was decided before the RHS ran,
    # and the RHS seeded the leaf through a default-taken miss: the store is
    # the seeded leaf's first UPDATE -- a write to an existing place whose
    # entry value is the default -- so it takes the assign choke, not the
    # first-def note (promotion in AUTO_M2S, the loud refusal otherwise).
    seeded = _PYIR_CF_SEEDED_ATTRS.get((id(owner), slot_name))
    if seeded is not None and "default" in seeded:
        old = pyir_read(
            target_name, seeded["default"], owner=owner, slot_name=slot_name
        )
        filename, lineno = _first_non_dsl_caller_location()
        result = pyir_assign(
            target_name, old, value, filename, lineno, owner=owner, slot_name=slot_name
        )
        if result is not value:
            _pyir_holder_store(owner, slot_name, result)
        return
    if _pyir_bind_sibling_first_def(
        owner, slot_name, target_name, site=site, value=value
    ):
        return
    _pyir_record_cf_attr_first_def(owner, slot_name, site=site)
    if rhs_ctor is not None:
        call_born = False
        if not isinstance(rhs_ctor, type):
            try:
                call_born = _pyir_call_born_object_is_fresh(
                    value, owner, id(value) in _PYIR_CANDIDATE_HOLDERS
                )
            except Exception:
                call_born = False
        _pyir_record_fresh_object_leaf_first_defs(rhs_ctor, value, call_born=call_born)
    # A meta-primitive attribute born in this region is region-born for the
    # off-mode write audit (``_pyir_place_is_region_born``): a later
    # read-modify-write of it in the same body re-executes from this binding
    # on every iteration, so it is not a carried accumulation.  The same
    # binding position is the place's F-BIRTHPOS fact: a same-depth rebind
    # keeps the per-iteration meta value (keep-constexpr) and a promotion
    # seeds the cell here, per iteration, instead of folding this reset into
    # a once-seeded entry cell that the rebind then carries across iterations.
    if isinstance(value, (bool, int, float)):
        _pyir_note_region_birth(_make_slot_key(target_name, owner, slot_name))
        _pyir_record_fresh_entry_birth(owner, slot_name, value)


def pyir_generation_probe(target_name: str) -> None:
    """Detector-only probe for function-scope Name-rooted attribute reads: emits no
    IR, evaluates no attribute, and fires only while a stamped generation exists."""
    if not (
        _SUPERSEDED_GENERATIONS
        or _ALIAS_CAPTURE_ROOT_NAMES
        or _SUPERSEDED_LEAF_WRAPPERS
        or _PYIR_CF_ATTR_FIRST_DEFS
        or _PYIR_SELECTION_STALE_PRODUCTS
    ):
        return
    if _pyir_gen_events_suppressed():
        return
    root_name, sep, attr = target_name.partition(".")
    if not sep or not attr or "[" in root_name:
        return
    base = sys._getframe(1).f_locals.get(root_name)
    if base is None:
        return
    if _PYIR_SELECTION_STALE_PRODUCTS:
        _pyir_check_stale_selection_product_read(base, attr, target_name)
    _pyir_generation_read_checks(target_name, None, base, attr)
    _pyir_check_cf_attr_first_def_read(base, attr)


def _pyir_reconcile_unobserved_write(
    mv: Any,
    current_value: Any,
    target_name: Any,
    owner: Any,
    slot_name: Any,
) -> "tuple[Any, Any]":
    """V-3 at the read choke: the live binding is another cell's product, so a
    write the chokes never saw rebound this place.  Within an unchanged
    region-epoch interval the write is replayed through the write choke here
    (commit-on-read: the interval is straight-line, so this position is the
    binding's); across a staged-region boundary the binding position is
    unrecoverable -- refuse loudly."""
    if not _pyir_row_binding_unobserved_write(current_value, mv):
        return mv, current_value
    filename, lineno = _first_non_dsl_caller_location()
    if mv._last_choke_region_epoch != _pyir_current_region_epoch():
        raise DSLUserCodeError(
            DiagId.UNOBSERVED_WRITE_POSITION_UNKNOWN,
            filename=filename,
            lineno=lineno,
            var=str(target_name),
        )
    result = pyir_assign(
        str(target_name),
        mv._value,
        current_value,
        filename or "<unobserved write>",
        lineno or 0,
        owner=owner,
        slot_name=slot_name,
    )
    if result is not None and result is not current_value:
        # Python's storage adopts the choke's binding (the boundary-replay
        # writeback discipline); composite spellings name no storage key.
        if isinstance(owner, (dict, list)) or (
            owner is not None and isinstance(slot_name, str)
        ):
            _pyir_holder_store(owner, slot_name, result)
        current_value = result
    # The replay may have re-minted or retired the row: re-resolve the place.
    if owner is not None and slot_name is not None:
        mv = _get_slot_mv(owner, slot_name)
    else:
        mv = _get_slot_mv(None, target_name)
    return mv, current_value


_PYIR_FABRICATION_MISS = _Sentinel("fabrication miss")


def _pyir_judge_fabricated_attr_read(
    owner: Any, slot_name: Any, value: Any
) -> "tuple[str, str] | None":
    """Fabricated-read guard (LangRef 3.12 section 3.3.2): a read FABRICATED by
    a user-defined ``__getattr__`` names no storage slot, so no place fact can
    carry it.  A bare meta payload consumed inside staged CF would bake here
    and silently mask whatever mutable state the hook derived it from --
    refuse loudly.  Tolerated everywhere else: meta flow is CPython truth,
    and a tracked payload (staged / watched / route-carrying / callable)
    carries its own choke-governed identity through the hook.  Returns the
    tolerated read's ``(definer qualname, attr)`` witness (``None`` when the
    read is not a tolerated fabrication)."""
    if owner is None:
        return None
    if isinstance(slot_name, _PlaceSeg):
        base = slot_name.base
        if not isinstance(base, str):
            return None
    elif isinstance(slot_name, str):
        base = slot_name
    else:
        return None
    definer = _pyir_class_facts.getattr_fabrication_definer(type(owner))
    if definer is None:
        return None
    from .pyir_callee_rewrite import _pyir_boundary_module_is_user

    if not _pyir_boundary_module_is_user(getattr(definer, "__module__", None)):
        return None  # wrapper-consumer contract: DSL/stdlib fabrication protocols
    if (
        _inspect_module.getattr_static(owner, base, _PYIR_FABRICATION_MISS)
        is not _PYIR_FABRICATION_MISS
    ):
        return None  # the name resolves to real storage: not a fabricated read
    tracked = (
        _is_staged_value(value)
        or isinstance(value, (_WatchedM, _WatchedDict, _WatchedList))
        or getattr(value, "_mutable_ref", None) is not None
        or callable(value)
    )
    if not tracked and is_inside_staged_cf():
        filename, lineno = _first_non_dsl_caller_location()
        raise DSLUserCodeError(
            DiagId.OWNER_FABRICATED_ATTR_IN_STAGED_CF,
            filename=filename,
            lineno=lineno,
            obj=owner.__name__ if isinstance(owner, type) else type(owner).__name__,
            attr=base,
            definer=definer.__qualname__,
        )
    if not tracked:
        from .pyir_core import _pyir_spec_note_fabricated_bake

        # F-SPEC: an unrooted fabricated bare-meta bake is unverifiable at
        # re-entry (no storage slot names a re-derivable path): fail closed.
        _pyir_spec_note_fabricated_bake(owner, base)
    return (definer.__qualname__, base)


_PYIR_MUTATING_FGET_SCANS: "dict[Any, bool]" = {}
_PYIR_FGET_STORE_OPS = frozenset(
    (
        "STORE_ATTR",
        "DELETE_ATTR",
        "STORE_GLOBAL",
        "DELETE_GLOBAL",
        "STORE_SUBSCR",
        "DELETE_SUBSCR",
    )
)
# A ``nonlocal`` write compiles to STORE_DEREF/DELETE_DEREF.  Only a FREEvar
# target (a cell captured from an enclosing scope) is an external side effect;
# a cellvar target is a getter-local captured by a nested function and is
# benign, so the scan gates DEREF ops on ``code.co_freevars``.
_PYIR_FGET_DEREF_OPS = frozenset(("STORE_DEREF", "DELETE_DEREF"))


def _pyir_canonical_slot_name(owner: Any, slot_name: Any) -> Any:
    """The storage slot a choke's ``(owner, slot_name)`` pair names: the
    backing attribute when *slot_name* is a storage-transparent property of
    ``type(owner)`` (``return self._n`` / ``self._n = v``), else *slot_name*
    unchanged.  Both spellings of the leaf must resolve to ONE place: a
    read-modify-write through the property and a plain callee's raw write of
    the backing field are updates of the same cell, and a place keyed on the
    property name would name no storage (F-SHAPE) and never promote."""
    # Only an attribute NAME can spell a property; an item key or a composite
    # ``_PlaceSeg`` element slot passes through unchanged.
    if not isinstance(slot_name, str) or owner is None:
        return slot_name
    if isinstance(owner, (dict, list, tuple, type)) or _is_staged_value(owner):
        return slot_name
    backing = _pyir_class_facts.transparent_property_backing(type(owner), slot_name)
    return slot_name if backing is None else backing


def _pyir_judge_mutating_property_read(owner: Any, slot_name: Any) -> None:
    """Mutating-getter guard: a user ``@property`` whose fget's own bytecode
    writes state executes once at trace time, so inside dynamic staged CF its
    side effect cannot re-run per iteration -- the read result AND the mutated
    state both freeze.  Refuse loudly; pure getters (no store opcodes) pass,
    and DSL/stdlib properties are wrapper-consumer machinery and pass."""
    if owner is None or isinstance(owner, type) or not isinstance(slot_name, str):
        # A composite ``_PlaceSeg`` slot names a tuple element, never a
        # descriptor attribute; only a plain-str name can resolve a property.
        return
    if not is_inside_staged_cf() or is_inside_constexpr_loop():
        return
    # Inspect the descriptor itself without invoking a custom __get__ again.
    descr = _inspect_module.getattr_static(type(owner), slot_name, None)
    if not isinstance(descr, property) or descr.fget is None:
        return
    fget = descr.fget
    code = getattr(fget, "__code__", None)
    if code is None:
        return
    mutates = _PYIR_MUTATING_FGET_SCANS.get(code)
    if mutates is None:
        from .pyir_callee_rewrite import _pyir_boundary_module_is_user

        mutates = _pyir_boundary_module_is_user(
            getattr(fget, "__module__", None)
        ) and any(
            ins.opname in _PYIR_FGET_STORE_OPS
            or (ins.opname in _PYIR_FGET_DEREF_OPS and ins.argval in code.co_freevars)
            for ins in _dis_module.get_instructions(code)
        )
        _PYIR_MUTATING_FGET_SCANS[code] = mutates
    if not mutates:
        return
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.PROPERTY_GETTER_MUTATES_IN_STAGED_CF,
        filename=filename,
        lineno=lineno,
        obj=type(owner).__name__,
        attr=slot_name,
        getter=getattr(fget, "__qualname__", slot_name),
    )


def pyir_read(
    target_name: Any,
    current_value: Any = _PYIR_READ_SIMPLE_SENTINEL,
    *,
    attach_ref: bool = True,
    owner: Any = None,
    slot_name: Any = None,
    force_promote_meta: bool = False,
    row_authoritative: bool = False,
    maybe_written: bool = True,
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
    ``_mutable_ref`` cache.  When either is ``None`` the value-keyed
    value-keyed path is used unchanged.
    """
    # Callers that omit ``current_value`` get the historical default of
    # ``None`` (the sentinel just distinguishes "omitted" from "explicitly
    # None" at the call site).
    if current_value is _PYIR_READ_SIMPLE_SENTINEL:
        current_value = None
    # Refuse a wrapper minted under a previous top-level compilation before any
    # dominance probe dereferences its already-finalized backing IR handle.
    from .typing import _refuse_stale_staged  # lazy: typing imports this chain

    _refuse_stale_staged(current_value)
    slot_name = _pyir_canonical_slot_name(owner, slot_name)
    # F-MEMORY: an element of a memref-backed owner lives in staged memory and
    # the owner's accessors emit its loads; memory, not a row, is the authority.
    if (
        owner is not None
        and slot_name is not None
        and not isinstance(slot_name, (str, _PlaceSeg))
        and _is_memref_like(owner)
    ):
        return current_value
    # A candidate of an unsighted staged selection that a write went through:
    # its fields no longer say what Python's would -> refuse the read.
    if _PYIR_SELECTION_WRITTEN_CANDIDATES and owner is not None:
        _pyir_check_selection_written_candidate_read(owner, slot_name, target_name)
    # A staged-selection product read after a write to one of its candidates.
    if _PYIR_SELECTION_STALE_PRODUCTS and owner is not None:
        _pyir_check_stale_selection_product_read(owner, slot_name, target_name)
    # Fabrication guard: judge a ``__getattr__``-fabricated read here (refuse a
    # bare meta bake inside staged CF; tolerate + record everywhere else).
    _pyir_judge_fabricated_attr_read(owner, slot_name, current_value)
    # Candidate-holder registry: an attribute read sights its owner, so a
    # holder the body reads before any binding choke sees it joins the open
    # meta-leaf audits with its pre-write value.
    if owner is not None:
        _pyir_register_candidate_holder(owner, adopt=False)
    # Mutating-getter guard: a user property whose fget writes state cannot
    # re-run its side effect per staged iteration -- refuse inside staged CF.
    _pyir_judge_mutating_property_read(owner, slot_name)
    # Sighting: a user-class instance read here has its class instrumented so
    # its implicit protocol code (dunders, properties) observes from now on.
    if _PYIR_SIGHT_HOOK[0] is not None:
        if owner is not None:
            _PYIR_SIGHT_HOOK[0](owner)
        if current_value is not None and type(current_value) not in (
            int,
            float,
            bool,
            str,
            bytes,
        ):
            _PYIR_SIGHT_HOOK[0](current_value)
    # Read-choke adoption: a plain dict read off a KNOWN holder slot adopts with
    # the holder replaced; owner-less reads stay raw.
    if (
        type(current_value) is dict
        and owner is not None
        and slot_name is not None
        and _WATCHED_DICT_READ_HOOK[0] is not None
    ):
        current_value = _pyir_adopt_dict_value(
            owner, slot_name, current_value, label=str(target_name)
        )
    # List sibling: a plain list read off a KNOWN holder slot adopts with the
    # holder replaced (``obj.l`` -- the attr-read hoist passes owner/slot).
    if (
        type(current_value) is list
        and owner is not None
        and slot_name is not None
        and _WATCHED_LIST_READ_HOOK[0] is not None
    ):
        current_value = _pyir_adopt_list_value(
            owner, slot_name, current_value, label=str(target_name)
        )
    # F-SPEC hop chaining: the value observed at a rooted (owner, slot) place
    # roots one composition deeper, so its own leaf reads become re-derivable.
    if owner is not None and slot_name is not None:
        _pyir_spec_chain_value(current_value, owner, slot_name)
    log().info(
        "[pyir_read] '%s' type=%s attach_ref=%s",
        target_name,
        type(current_value).__name__,
        attach_ref,
    )

    # Superseded-generation read checks: three dict truthiness tests on the
    # common path; the channel checks run only while a stamp or capture exists.
    if (
        _SUPERSEDED_GENERATIONS
        or _SUPERSEDED_LEAF_WRAPPERS
        or _ALIAS_CAPTURE_ROOT_NAMES
    ):
        _pyir_generation_read_checks(target_name, current_value, owner, slot_name)
    # Region-conditional attr first-def read check (read-before-set): a read
    # outside the first-def block's subtree is never-set on its reaching path.
    # The pre-store refresh of an assignment target takes this check too: the
    # refresh is the one tracked read of the target, and a read hidden from
    # the preprocessor (``getattr``, ``__dict__``, a helper) may follow it.
    if _PYIR_CF_ATTR_FIRST_DEFS and owner is not None:
        _pyir_check_cf_attr_first_def_read(owner, slot_name)

    # Tuple recursion: aggregate tuples are not ref-supported themselves
    # (``_can_create_ref(tuple) == False``), but their staged leaves often
    # are. ``_decompose_tuple`` creates per-element refs on the write side;
    # we mirror that on the read side so the caller gets a tuple of
    # freshly-loaded values rather than the rebound tuple object holding
    # SSA defined in a sibling scf.if region.
    if isinstance(current_value, tuple):

        def elem_slot(i: int) -> Any:
            return _place_seg_child(slot_name, i) if slot_name is not None else None

        # F-TYPEID: the reload rebuilds through the declared reconstruction
        # funnel so a NamedTuple keeps its class (a bare tuple() strips it).
        return _rebuild_tuple_like(
            current_value,
            [
                pyir_read(
                    f"{target_name}[{i}]",
                    elem,
                    attach_ref=attach_ref,
                    owner=owner,
                    slot_name=elem_slot(i),
                )
                for i, elem in enumerate(current_value)
            ],
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
    # Gated to staged CF -- outside, the code below already loads
    # from any recorded ref via the slot-first lookup.  Primitives are
    # excluded; tuples / aggregate containers handled by the branch above.
    #
    # We MUST re-attach ``_mutable_ref`` to the freshly-loaded value so a
    # subsequent ``attach_ref=False`` snapshot read (e.g. a downstream-DSL
    # print arg) can recover the ref via the value-keyed cache instead of
    # falling through to ``_create_ref`` Case-D poison.
    if (
        attach_ref
        and is_inside_staged_cf()
        and not isinstance(current_value, (int, float, bool, str, bytes))
    ):
        slots = _iter_owner_slot_mvs(current_value)
        if slots:
            # Refreshing a SUPERSEDED object's slots would setattr the current
            # generation's values onto the retained handle; check first.
            if _SUPERSEDED_GENERATIONS and not _pyir_gen_events_suppressed():
                _gen_rec = _SUPERSEDED_GENERATIONS.get(id(current_value))
                if _gen_rec is not None:
                    for _mv0, _v0 in _gen_rec["cells"].values():
                        if _mv0._store_version > _v0:
                            _pyir_raise_superseded(
                                "read", target_name, _gen_rec["site"]
                            )
            owner_cls = type(current_value)
            # Refuse silent rebind when the class overrides __setattr__:
            # the user's hook may have side-effects we cannot reason about,
            # and the alternative (calling type-specific __setattr__) would
            # re-trigger PyIR's instrumentation.  Skip refresh in that case
            # and fall through to the value-keyed path.
            if _pyir_plain_storage_setattr(owner_cls):
                refreshed = False
                for stored_slot_name, slot_mv in slots:
                    if slot_mv is None or not slot_mv._is_ref_accessible():
                        continue
                    # Skip composite slot keys (``_PlaceSeg``): those refer
                    # to tuple elements registered by ``_decompose_tuple``,
                    # not direct Python attributes.  ``setattr`` on them
                    # would create a synthetic attribute that then breaks
                    # ``_decompose_m2m_assign``'s parallel walk on the next
                    # reassignment.
                    if not isinstance(stored_slot_name, str):
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
                        _pyir_setattr_raw(current_value, stored_slot_name, fresh)
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
    #   ``_SLOT_REGISTRY``; ``__dict__`` owners use tier-1)
    # - this read will also attach _mutable_ref to the returned value
    #   (attach_ref=False reads are snapshots -- no ref tracking needed,
    #   and creating a ref here would introduce spurious iter_args).
    # A CONTAINER owner is slot-authoritative even for snapshot reads: legs often
    # share a seed value, so identity comes from the slot registry, not the value.
    have_slot = (
        (attach_ref or isinstance(owner, (dict, list)))
        and owner is not None
        and slot_name is not None
        and _slot_storage_available(owner)
    )

    if not is_inside_staged_cf():
        # Outside staged CF, but the value may have been modified inside
        # a now-exited CF region.  If the place's ledger row exists
        # (R1), load from it so subsequent uses see the accumulated
        # result; a value-carried route is only place-validated evidence,
        # and a computed (property-family) attribute has no row at all.
        computed_slot = (
            owner is not None
            and slot_name is not None
            and _pyir_owner_slot_is_computed(owner, slot_name)
        )
        read_place = (
            None if computed_slot else _pyir_read_place(target_name, owner, slot_name)
        )
        if computed_slot:
            mv = None
        elif owner is not None and slot_name is not None:
            mv = _get_slot_mv(owner, slot_name)
        else:
            mv = _get_slot_mv(None, target_name)
        if mv is not None:
            # R1c (V-3): judge the live binding against the row before the
            # row routes the read; an unobserved write replays or refuses.
            mv, current_value = _pyir_reconcile_unobserved_write(
                mv, current_value, target_name, owner, slot_name
            )
        if mv is None:
            route = getattr(current_value, "_mutable_ref", None)
            if route is not None and (
                getattr(route, "_place", None) in (read_place, None)
                if read_place is not None
                else (
                    _pyir_route_is_live_place_row(route)
                    or _pyir_route_is_current(current_value, route)
                )
            ):
                mv = route
                if read_place is not None:
                    # First-wins rooting: register the adopted cell as the
                    # place's row so later reads resolve by place.
                    if owner is not None and slot_name is not None:
                        mv = _set_slot_mv(owner, slot_name, route)
                    else:
                        mv = _set_slot_mv(None, target_name, route)
        if mv is not None and mv._is_ref_accessible():
            _pyir_refuse_superseded_row_serve(mv, target_name)
            if _pyir_cell_read_is_fresh(current_value, mv):
                # The binding IS the cell's content at this program point (a
                # region-close reload left it there): a second load would
                # read the same content, so the read shares that load.
                loaded = _pyir_share_fresh_cell_load(current_value, mv)
                log().info(
                    "[pyir_read] '%s' outside CF: binding is a fresh load → reused",
                    target_name,
                )
            else:
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
        d1_slot = _make_slot_key(target_name, owner, slot_name)
        if (
            d1_slot is not None
            and d1_slot in _slot_refs
            # Skip an opaque row whose pointee no longer matches the binding:
            # it belongs to an earlier generation, so the load would read stale.
            and not _pyir_row_load_type_mismatch(_slot_refs[d1_slot], current_value)
        ):
            return _load_as_dsl(_slot_refs[d1_slot], place=d1_slot, stamp_place=True)
        log().info("[pyir_read] '%s' outside staged CF → passthrough", target_name)
        # F-SPEC: a meta passthrough of a rooted place is a specialization fact.
        _pyir_spec_record_read(read_place, current_value)
        return current_value

    # D1 (META_VALUE_TABLE_DESIGN): when inside staged CF AND the slot is
    # tracked (or trackable) by the meta-value table, route through D1
    # instead of the value-keyed paths.
    #
    # - If the slot is already promoted, emit ``pyir.load %ref`` and
    #   return the matching DSL Numeric.  The promotion happened earlier
    #   in this trace (e.g. previous mutation).
    # - If the value is a Python primitive AND the slot is not yet
    #   promoted, wrap as ``_WatchedM`` so a later mutation can rewrite
    #   any leaf constants we bake during use.
    d1_slot = _make_slot_key(target_name, owner, slot_name)
    if d1_slot is not None:
        existing_ref = _slot_refs.get(d1_slot)
        # A2 read guard: an OPAQUE row whose pointee no longer matches the
        # binding belongs to an earlier generation -- skip the load.
        if existing_ref is not None and _pyir_row_load_type_mismatch(
            existing_ref, current_value
        ):
            existing_ref = None
        if existing_ref is not None:
            return _load_as_dsl(existing_ref, place=d1_slot, stamp_place=True)
        # A force-promoted read must not settle for the _WatchedM wrap (a condition
        # over a watched meta would fold); unwrap and fall through to Mp->S.
        if force_promote_meta and isinstance(current_value, _WatchedM):
            current_value = current_value.python_value
        elif isinstance(current_value, _WatchedM):
            _pyir_spec_record_read(current_value._slot_key, current_value)
            return current_value  # idempotent
        # Strict type check (NOT isinstance): IntEnum / IntFlag subclass int,
        # but wrapping them in _WatchedM strips their enum identity at the
        # @dsl_user_op coercion boundary -- downstream MLIR attr builders
        # then receive a bare int and fail (e.g. `#nvvm.tcgen05_ldst_shape<3>`
        # vs the expected `<shape16x32bx2>`).  Only true primitives are
        # mutated as D1 slots; enums are configuration values and should
        # pass through unchanged.  See PYIR_DEV_GUIDE.md Pitfall 15.
        if type(current_value) in (bool, int, float) and not force_promote_meta:
            # F-SPEC: the wrapped payload is what a later bake carries.
            _pyir_spec_record_read(d1_slot, current_value)
            # Only ``bool`` unwraps: no write can promote this slot, while
            # ``int``/``float`` keep the wrapper for its payload-width refusal
            # and attributes keep it for their non-lexical write set.
            if owner is None and not maybe_written and type(current_value) is bool:
                return current_value
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
        # ``force_promote_meta`` is the declared carried-leg fact (condition-read
        # AND body-written legs must stage); it overrides the meta default.
        if (
            attach_ref
            and (is_auto_m2s_enabled() or force_promote_meta)
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
                        mv = _create_ref(
                            promoted,
                            birth_block=_pyir_recorded_birth_block(
                                target_name, owner, slot_name
                            ),
                        )
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
            except Exception as exc:
                # Fail-loud wall: a swallowed promotion failure would silently
                # bake the meta payload where a staged carry was declared.
                raise DSLRuntimeError(
                    "PyIR emission self-check: Mp→S auto-promotion failed for "
                    f"'{target_name}' (payload {current_value!r}): {exc}"
                ) from exc
        log().info("[pyir_read] '%s' not staged → passthrough", target_name)
        # F-SPEC: a meta passthrough inside staged CF bakes wherever it is
        # consumed; record it under its place when rooted.
        _pyir_spec_record_read(
            _pyir_read_place(target_name, owner, slot_name), current_value
        )
        return current_value

    if not _can_create_ref(current_value):
        log().info(
            "[pyir_read] '%s' type %s not ref-compatible → passthrough",
            target_name,
            type(current_value).__name__,
        )
        return current_value

    # R0: the read's place is derived unconditionally; attach_ref keeps its
    # ref-leakage role only and never gates place validation.  A computed
    # (property-family) attribute names no storage place (F-SHAPE).
    computed_slot = (
        owner is not None
        and slot_name is not None
        and _pyir_owner_slot_is_computed(owner, slot_name)
    )
    read_place = (
        None if computed_slot else _pyir_read_place(target_name, owner, slot_name)
    )
    # R1: a live ledger row at the place is authoritative (values that share a
    # ref across slots resolve by place, never by object identity).
    if computed_slot:
        mv = None
    elif owner is not None and slot_name is not None:
        mv = _get_slot_mv(owner, slot_name)
    else:
        mv = _get_slot_mv(None, target_name)
    if mv is not None and not row_authoritative:
        # R1c (V-3): judge the live binding against the row before the row
        # routes the read; an unobserved write replays or refuses.  A
        # row-authoritative caller passes a machinery re-presentation of the
        # carried binding (region carry), which names no user write.
        mv, current_value = _pyir_reconcile_unobserved_write(
            mv, current_value, target_name, owner, slot_name
        )
    foreign_stored_local_route = False
    if mv is None:
        route = getattr(current_value, "_mutable_ref", None)
        if route is not None:
            if read_place is not None:
                # R2 (V-1): a value-carried cell routes a place-named read only
                # when it is stamped as this place's own cell.  A place-less
                # cell is claimed by its first place-named read (first-wins
                # rooting); a cell stamped with a DIFFERENT place is LAW-1
                # snapshot evidence and falls through to the mint path.
                if getattr(route, "_place", None) in (read_place, None):
                    if owner is not None and slot_name is not None:
                        mv = _set_slot_mv(owner, slot_name, route)
                    else:
                        mv = _set_slot_mv(None, target_name, route)
                else:
                    # Same-named local row stamped in a DIFFERENT function
                    # scope: candidate nonlocal-cell twin; judged at the mint
                    # (a snapshot passthrough below never re-roots the place).
                    _route_place = getattr(route, "_place", None)
                    if (
                        owner is None
                        and slot_name is None
                        and isinstance(target_name, str)
                        and target_name.isidentifier()
                        and isinstance(_route_place, tuple)
                        and len(_route_place) >= 3
                        and _route_place[0] == "local"
                        and _route_place[2] == target_name
                        and isinstance(read_place, tuple)
                        and len(read_place) >= 3
                        and read_place[0] == "local"
                        and _route_place[1] != read_place[1]
                        and getattr(route, "_store_version", 0) > 0
                    ):
                        foreign_stored_local_route = True
            elif _pyir_route_is_live_place_row(route) or _pyir_route_is_current(
                current_value, route
            ):
                # R3: a place-less read follows its route when the route IS its
                # own place's live row (place authority) or while the value is
                # provably the cell's current binding (V-2).
                mv = route
            else:
                # R3 residue: the value is a retained snapshot; its own SSA is
                # Python's dereference, and an unusable SSA refuses loudly.
                return _pyir_resolve_snapshot(current_value, target_name)
    mv_was_preexisting = mv is not None
    log().info("[pyir_read] '%s' existing mv=%s", target_name, mv)

    if mv is None:
        # A route-less computed (property-family) read IS its result: no
        # storage place exists, so there is no cell to create or consult (R3).
        if computed_slot:
            log().info(
                "[pyir_read] '%s' computed attribute -> passthrough", target_name
            )
            return current_value
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
        # An assignment pre-read promoting a fold-witnessed value to a cell is
        # the write transition: refuse before the stale fold carries a store.
        if attach_ref:
            _pyir_check_staged_fold_witness(current_value, target_name)
        # Backstop: a ``nonlocal`` name resolves to its cell's home row
        # (see ``_cell_home_binding``), so a foreign stored row here means
        # the home fact is absent -- a re-rooting mint would abandon the
        # foreign scope's stores at the join.  Refuse instead of twinning.
        if (
            foreign_stored_local_route
            and is_inside_staged_cf()
            and _PYIR_SCOPE_STACK
            and target_name
            in _PYIR_SCOPE_NONLOCAL_NAMES.get(_PYIR_SCOPE_STACK[-1].scope_id, ())
        ):
            raise DSLUserCodeError(
                DiagId.SCOPE_NONLOCAL_WRITE_IN_STAGED_CF,
                name=str(target_name),
            )
        # R6: a row-authoritative carry mint firing inside the promoted loop
        # op's own block emits its cell and copy-in at the declared pre-region
        # position (write facts are position + value; never the ambient IP).
        _pre_ip = _pyir_promoted_region_pre_ip() if row_authoritative else None
        _birth = _pyir_recorded_birth_block(target_name, owner, slot_name)
        # Fail-closed sibling-region serve guard: a place-named container/attr
        # read minting from an SSA trapped in a closed region that does not
        # dominate this IP serves a value Python never bound on this path
        # (e.g. a protocol-carried holder rebuilt at region close presents the
        # producer arm's trace-time value to the sibling arm).  A recorded
        # birth block keeps the region-born cell mint (seed placed at birth).
        if (
            owner is not None
            and slot_name is not None
            and _birth is None
            and _raw_backing_ir_value(current_value) is not None
            and not _value_dominates_current_ip(current_value)
        ):
            _sg_file, _sg_line = _first_non_dsl_caller_location()
            raise DSLUserCodeError(
                DiagId.SCOPE_READ_NEVER_SET,
                filename=_sg_file,
                lineno=_sg_line,
                detail=" (its only value was produced inside a sibling branch"
                " that cannot reach this read)",
            )
        if _pre_ip is not None:
            with _pre_ip:
                mv = _create_ref(current_value, birth_block=_birth)
        else:
            mv = _create_ref(current_value, birth_block=_birth)
        log().info("[pyir_read] '%s' ref created via _create_ref", target_name)
        if have_slot:
            mv = _set_slot_mv(owner, slot_name, mv)
            # Reconstruct BEFORE attach when slot context is present so the
            # fresh wrapper carries this ref instead of the caller's
            # (potentially shared) value.  Without this, a later write to a
            # sibling slot would observe the same ``_mutable_ref`` and
            # alias back onto this slot.  When slot context is absent we
            # must attach to the caller's object directly -- the
            # value-keyed ``_mutable_ref`` cache is the only lookup path
            # available to subsequent reads.
            current_value = mv._reconstruct(current_value.ir_value())
        elif (
            owner is not None
            and slot_name is not None
            and is_inside_staged_cf()
            and _slot_storage_available(owner)
        ):
            # PRODUCER PUBLISH.
            mv = _set_slot_mv(owner, slot_name, mv)
            # LAW-2: a published place row's representative is a fresh
            # wrapper -- the presented object can be (or become) a live
            # binding of ANOTHER place (a frame local, a kernel parameter),
            # and attaching this row to it would steal that binding's route.
            # A literal-backed value mints a fresh position-independent
            # constant per ``ir_value()``; an adoptable slot mints it at the
            # declared pre-region position so the constant lands outside the
            # staged region.  Every other value materializes position-
            # dependently (e.g. as a cell load) and keeps the ambient mint.
            # Composite spellings name no storage key.
            _adopt_slot = isinstance(slot_name, str)
            _pub_pre_ip = (
                _pyir_promoted_region_pre_ip()
                if _adopt_slot and _is_literal_backed(current_value)
                else None
            )
            if _pub_pre_ip is not None:
                with _pub_pre_ip:
                    _pub_raw = current_value.ir_value()
            else:
                _pub_raw = current_value.ir_value()
            current_value = mv._reconstruct(_pub_raw)
            # Python's storage adopts the representative (the boundary-replay
            # writeback discipline: the slot's binding stays routed to its
            # row, so later slot reads and boundary-observed writes resolve
            # it) only when every later serve of the adopted binding is
            # total: the raw itself dominates the region exterior (a direct
            # serve is valid anywhere), or the row's cell does (every choke
            # read re-loads the live cell and the boundary replay carries
            # it -- a plain-method advance inside the region then reads and
            # writes the carried cell, not a baked snapshot).  A raw AND
            # cell both interior to a staged region stay out of storage:
            # the row alone carries the binding.
            _row_cell = getattr(mv, "_ref", None)
            if _adopt_slot and (
                _pyir_raw_dominates_region_exterior(_pub_raw)
                or (
                    _row_cell is not None
                    and _pyir_raw_dominates_region_exterior(_row_cell)
                )
            ):
                # The stored wrapper IS the row's own representative: the cell
                # was minted from this very value at this choke, so a later
                # region-close sweep finding it unchanged in storage has no
                # un-instrumented advance to store back.  A real plain-method
                # advance rebinds the slot to a NEW object without this mark.
                try:
                    _pyir_setattr_raw(
                        current_value, "_pyir_publish_representative_of", mv
                    )
                except (AttributeError, TypeError):
                    pass  # unmarkable wrapper: the sweep judges it by position
                _pyir_holder_store(owner, slot_name, current_value)
        elif owner is None and read_place is not None:
            # R2 publish: the minted snapshot cell becomes the local place's
            # row, so later same-name reads resolve by place (R1), not by value.
            mv = _set_slot_mv(None, target_name, mv)
            # LAW-2: a wrapper routed to a FOREIGN cell is a shared caller-scope
            # binding; this scope's representative is minted on a fresh wrapper.
            _prior_route = getattr(current_value, "_mutable_ref", None)
            if _prior_route is not None and _prior_route is not mv:
                current_value = mv._reconstruct(current_value.ir_value())
        _attach_mutable_ref(current_value, mv, f"pyir_read '{target_name}' new-ref")

    if mv._is_ref_accessible():
        if mv_was_preexisting:
            _pyir_refuse_superseded_row_serve(mv, target_name)
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

    # A SNAPSHOT read of a region-trapped container leg must not re-create the
    # cell (the write side owns that); the trapped-raw recovery repairs reads.
    if not attach_ref and isinstance(owner, (dict, list)):
        return current_value
    # Ref exists but is inaccessible (defined in a sibling/exited CF region,
    # e.g. inside a previous meta-loop iteration's scf.if body).
    # current_value's SSA may not dominate the current insertion point.
    # Re-create the ref at the current scope so the load dominates.
    # _create_ref handles placement: literal-backed → function entry (Case A),
    # SSA-backed → after defining op or current IP (Cases B-D).
    try:
        if attach_ref:
            _pyir_check_staged_fold_witness(current_value, target_name)
        # R6: same declared pre-region position for the re-created cell of a
        # row-authoritative carry (see the mint above).
        _pre_ip = _pyir_promoted_region_pre_ip() if row_authoritative else None
        _birth = _pyir_recorded_birth_block(target_name, owner, slot_name)
        if _pre_ip is not None:
            with _pre_ip:
                mv = _create_ref(current_value, birth_block=_birth)
        else:
            mv = _create_ref(current_value, birth_block=_birth)
        if have_slot and not computed_slot:
            _set_slot_mv(owner, slot_name, mv)
        elif owner is None and read_place is not None:
            # F-PLACE: the re-created cell becomes the local place's row.
            mv = _set_slot_mv(None, target_name, mv)
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


def pyir_bind_param(target_name: str, value: Any) -> Any:
    """Scope entry: a parameter binding IS this scope's first-def (Python
    semantics), so a binding that arrives routed to ANOTHER place's live row
    is re-homed now -- the scope's own row is minted on a fresh wrapper
    seeded from the binding (LAW-2), and every later read, write, and
    boundary load in this scope resolves the scope's own place row instead
    of the caller's shared cell.  Route-less or own-row bindings keep the
    lazy row mint.  A container param binds each leaf place the same way."""
    if isinstance(value, tuple):
        return _pyir_bind_param_leaves(target_name, value)
    return _pyir_bind_param_scalar(target_name, value)


def _pyir_bind_param_scalar(target_name: str, value: Any) -> Any:
    """The scalar arm of :func:`pyir_bind_param` (one name, one place)."""
    route = getattr(value, "_mutable_ref", None)
    if route is None:
        # A route-less staged binding shares the caller's wrapper OBJECT; the
        # callee owns its binding (LAW-2), so hand it a fresh wrapper -- else a
        # later callee row mints on the shared wrapper and the rebind leaks out.
        if _is_staged_value(value) and _can_create_ref(value):
            return _fresh_wrapper(value)
        return value
    place = _pyir_read_place(target_name, None, None)
    if place is None:
        return value
    route_place = getattr(route, "_place", None)
    if route_place is None or route_place == place:
        return value
    if not _can_create_ref(value) or not hasattr(value, "ir_value"):
        return value
    # The argument's value AT THE BIND POSITION is a read of the caller's live
    # cell (the wrapper's cached SSA may predate in-region advances of that
    # cell), so seed from a route load emitted here.
    incoming = route.load()
    mv = _create_ref(incoming)
    mv = _set_slot_mv(None, target_name, mv)
    # The binding IS the scope's first-def: commit the incoming value into the
    # scope's own row AT THE BIND POSITION (inside the current region for an
    # inlined callee, so a loop re-binds per iteration).  Row-keyed reads then
    # resolve this write instead of the row's placeholder init.
    mv.store(incoming)
    fresh = mv._reconstruct(incoming.ir_value())
    _attach_mutable_ref(fresh, mv, f"pyir_bind_param '{target_name}'")
    return fresh


def _pyir_bind_param_leaves(target_name: str, value: tuple) -> tuple:
    """A tuple/NamedTuple parameter binding is a first-def of EVERY leaf place
    it creates (``name[i]``, the write-walk's leaf naming): a routed leaf is
    re-homed onto this scope's own leaf row exactly like the scalar case; a
    meta or route-less staged leaf records its bind position so the lazy cell
    mint seeds HERE and zero-trip/post-loop reads stay defined."""
    rebuilt: list = []
    changed = False
    for i, leaf in enumerate(value):
        leaf_name = f"{target_name}[{i}]"
        if isinstance(leaf, tuple):
            new_leaf = _pyir_bind_param_leaves(leaf_name, leaf)
        else:
            pyir_seed_param_bindings(leaf_name)
            _pyir_record_bind_position_first_def(leaf_name, leaf)
            new_leaf = _pyir_bind_param_scalar(leaf_name, leaf)
        changed = changed or new_leaf is not leaf
        rebuilt.append(new_leaf)
    if not changed:
        return value
    return _rebuild_tuple_like(value, rebuilt)


def _pyir_record_bind_position_first_def(leaf_name: str, leaf: Any) -> None:
    """Record the bind position as *leaf_name*'s first-def fact (F-BIRTHPOS):
    a later lazy mint / M->S promotion of the leaf place seeds at this block
    instead of a hoisted placeholder.  Recording only -- no wrap, no ref."""
    try:
        slot = _make_slot_key(leaf_name, None, None)
    except Exception:
        return
    if slot is None or slot in _slot_refs:
        return
    try:
        block = ir.InsertionPoint.current.block
    except Exception:
        return
    if _is_staged_value(leaf) and _can_carry_leaf_ref(leaf):
        _slot_first_def_block[slot] = block
        return
    if type(leaf) in (bool, int, float):
        inside_cf = is_inside_staged_cf()
        _slot_first_def_inside_cf[slot] = inside_cf
        if inside_cf:
            _slot_first_def_depth[slot] = current_staged_cf_depth()
            _slot_first_def_block[slot] = block


def _pyir_obs_read(
    target_name: str, base: Any, attr: str, mod_name: "str | None" = None
) -> Any:
    """Record-only read choke for attribute reads the staging chokes never
    route (function-scope symbol-rooted reads, test-position reads, and
    module/class-spelled reads).  Evaluates the read exactly in place, adopts
    dict/list values off the known holder slot (the object-level chokes then
    own their entry lifecycles), and records the baked payload under the
    read's place (F-SPEC).  Never alters staging semantics."""
    value = getattr(base, attr)
    try:
        if base is None or _is_staged_value(base) or isinstance(base, _WatchedM):
            return value
        if (
            type(value) is dict
            and _WATCHED_DICT_READ_HOOK[0] is not None
            and not isinstance(base, (types.ModuleType, type))
        ):
            value = _pyir_adopt_dict_value(base, attr, value, label=str(target_name))
        elif (
            type(value) is list
            and _WATCHED_LIST_READ_HOOK[0] is not None
            and not isinstance(base, (types.ModuleType, type))
        ):
            value = _pyir_adopt_list_value(base, attr, value, label=str(target_name))
        # A test-position read of a meta primitive off a PLAIN compound folds
        # the payload into a trace-time decision with no retargetable SSA:
        # witness it like a structural consumption, so a later carry/promote
        # of the place with a CHANGED value refuses instead of keeping the
        # folded branch on every iteration.
        if (
            type(value) in (bool, int, float)
            and not isinstance(base, (types.ModuleType, type))
            and is_inside_staged_cf()
            and not is_inside_constexpr_loop()
            and _innermost_enclosing_loop_op_at_ip() is not None
        ):
            _obs_sk = _make_slot_key(None, base, attr)
            if (
                _obs_sk is not None
                and _obs_sk not in _PYIR_STRUCTURAL_META_CONSUMPTIONS
            ):
                _obs_file, _obs_line = _first_non_dsl_caller_location()
                _PYIR_STRUCTURAL_META_CONSUMPTIONS[_obs_sk] = (
                    str(value),
                    _obs_file or "<test-position read>",
                    _obs_line or 0,
                )
        _pyir_spec_observe_attr_read(target_name, base, attr, value, mod_name)
        # The module/class-spelled funnel judges fabricated reads too
        # (the metaclass ``__getattr__`` leg arrives here); after observation
        # so a symbol-rooted base resolves its root before the bake note.
        _pyir_judge_fabricated_attr_read(base, attr, value)
    except DSLUserCodeError:
        raise  # curated refusals are the loud floor, never swallowed
    except Exception:
        pass  # observation must never break the read (recording fails closed)
    return value


def _pyir_obs_global_read(name: str, value: Any, mod_name: "str | None" = None) -> Any:
    """Record-only read choke for a bare global-name read (no staging choke
    exists for module-level bindings): records scalar bakes under the module
    root and roots object bindings for their downstream legs (F-SPEC)."""
    try:
        _pyir_spec_observe_global_read(name, value, mod_name)
    except Exception:
        pass  # observation must never break the read (recording fails closed)
    return value


def _pyir_post_attr_read(
    target_name: str,
    owner: Any,
    attr: str,
    mod_name: "str | None" = None,
) -> Any:
    """Evaluate one lazy attribute read at its original Python evaluation site.

    The receiver arrives already evaluated; getattr runs once. Meta reads need
    specialization observation even outside staged CF, while staged reads use
    the same owner-keyed snapshot path as ordinary attribute instrumentation.
    """
    if isinstance(owner, (types.ModuleType, type)):
        return _pyir_obs_read(target_name, owner, attr, mod_name)
    value = getattr(owner, attr)
    value = pyir_read(target_name, value, attach_ref=False, owner=owner, slot_name=attr)
    # A helper may run inside its caller's staged region while reading globals
    # from a different module. Keep that module root even in staged CF, and
    # observe the routed value so an existing row cannot seal a stale payload.
    _pyir_spec_observe_attr_read(target_name, owner, attr, value, mod_name)
    return value


# Its ``getattr`` runs the program's read: a property that consumes a
# trace-time payload (``python_value``) consumes it on the program's behalf.
_PYIR_NATIVE_INVOKE_CODES.add(_pyir_post_attr_read.__code__)


def _pyir_post_subscript_read(
    target_name: str,
    container: Any,
    key: Any,
) -> Any:
    """Read ``container[key]``, emitting ``pyir.load`` for tracked values.

    Called by AST-inserted code for every ``container[key]`` in Load
    context inside jit-decorated bodies.

    For dicts/lists: evaluates ``container[key]`` and passes through
    ``pyir_read`` with ``attach_ref=False`` to emit ``pyir.load`` when
    the value carries a ``_mutable_ref``.  Returns the loaded value
    (fresh SSA) or the original value if no ref exists.

    For a DICT container the owner/key pair is forwarded into ``pyir_read``
    so the read names the same ``("subscript", owner_token, key)`` D1 slot the
    write choke names (the write side has always passed them) -- place
    NAMING only: the read stays ``attach_ref=False`` (a standalone snapshot
    read), it just stops keying the entry by its spelling string.  Without
    the owner, a read spelled ``d['x']`` and a read spelled ``obj.d['x']``
    of the SAME entry land on two unrelated name slots and a write-side
    promotion can never find the reads' baked constants.

    For non-dicts (GPU arrays, tensors, etc.): evaluates and returns
    ``container[key]`` directly (no overhead beyond the isinstance check).
    """
    # A meta KEY indexing any container is a structural consumption of the
    # key's place: C-level int-subclass fast paths (tuple/list subscript via
    # ``PyNumber_Index``) skip ``__index__``, so the choke must witness it --
    # records the bake and refuses an arm-local escape.
    if isinstance(key, _WatchedM):
        key._record_structural_consumption()
    # Dict SUBCLASS with a MISSING key inside dynamic staged CF: subclass magic
    # would create the key in-region (key-set rule); guarded BEFORE the access.
    if (
        isinstance(container, dict)
        and type(container) is not dict
        and not isinstance(container, _WatchedDict)
        and not dict.__contains__(container, key)
        and is_inside_staged_cf()
        and not is_inside_constexpr_loop()
    ):
        raise DSLUserCodeError(
            DiagId.CONTAINER_DICT_KEY_SET_MUTATED,
            var=str(target_name),
            detail=f"key {key!r} created via {type(container).__name__}",
        )
    # A plain dict / list no adoption tracks (or a subclass inheriting the
    # builtin lookup): the watched containers' key / index wall, before the
    # lookup misses by identity (a bare KeyError) or a Staged index falls to
    # the generic ``__index__`` refusal.
    _pyir_item_key_wall(
        container, key, str(target_name).split("[", 1)[0], "__getitem__"
    )
    val = container[key]
    if isinstance(container, (_WatchedDict, _WatchedList)):
        # The watched ``__getitem__`` already routed this read (single-fire
        # contract); a second pyir_read would duplicate the load/wrap.
        return val
    if not isinstance(container, (dict, list)):
        # A tuple slot cannot re-point (no adoption): the item hop still
        # declares the value's root chain so deeper leaf reads re-derive.
        if (
            type(container) is tuple
            and isinstance(key, int)
            and not isinstance(key, bool)
        ):
            idx = key + len(container) if key < 0 else key
            _pyir_spec_chain_value(val, container, steps=(("item", idx),))
        return val
    if isinstance(container, dict):
        if type(val) is dict:
            # A nested plain dict surfacing at the read choke: adopt it as a
            # child place (the parent container IS the holder slot in hand).
            return _pyir_adopt_dict_value(container, key, val, label=target_name)
        if type(val) is list:
            # A nested plain list surfacing at the read choke: same child-place
            # adoption, integer-leg domain (dict-of-lists).
            return _pyir_adopt_list_value(container, key, val, label=target_name)
        # A plain OBJECT surfacing through a never-adopted dict's leg: its
        # attr legs are still places one composition deeper.
        _pyir_register_container_held_object(val)
        return pyir_read(
            target_name, val, attach_ref=False, owner=container, slot_name=key
        )
    if type(val) is dict:
        # list-of-dicts: the list element slot is the holder in hand.
        return _pyir_adopt_dict_value(container, key, val, label=target_name)
    if type(val) is list:
        return _pyir_adopt_list_value(container, key, val, label=target_name)
    if isinstance(key, int) and not isinstance(key, bool):
        # Owner-keyed read of an integer leg so read and write chokes name the
        # SAME subscript slot; the read itself stays a standalone snapshot.
        _pyir_register_container_held_object(val)
        idx = key + len(container) if key < 0 else key
        return pyir_read(
            target_name, val, attach_ref=False, owner=container, slot_name=idx
        )
    return pyir_read(target_name, val, attach_ref=False)


def _pyir_pre_subscript_assign(
    target_name: str,
    container: object,
    key: object,
) -> object:
    """Read the old value from a subscript target for PyIR instrumentation.

    Called by AST-inserted code before every ``container[key] = expr`` and
    ``container[key] += expr`` inside jit-decorated bodies.

    Returns ``_PYIR_SKIP`` if the container is not a tracked Python
    container (e.g. GPU array, tensor, shared memory).

    Dicts are always tracked because cross-task state uses them even
    outside the immediate local CF body.  Python primitive dict entries
    remain meta values so trace-time counters can still drive
    ``const_expr`` dispatch.

    Lists are only tracked when the current jit-decorated body opened
    staged CF. This avoids instrumenting trace-time list fills inside
    nested jit-decorated helpers while still lifting list slot writes that
    would otherwise leak SSA across ``scf.if``/``scf.for`` regions.

    If the key does not yet exist in the container (first-time
    definition), returns ``None`` so that ``pyir_assign`` treats it as a
    first def.

    A :class:`_WatchedDict` / :class:`_WatchedList` container returns
    ``_PYIR_SKIP``: the object-level choke owns the whole write lifecycle.
    The AST expansion stores through the container up to three times
    (old-value writeback, the original statement's store, the
    processed-value store); deferring to the watched ``__setitem__`` --
    which fires exactly once per plain store, on the original statement --
    keeps the access single-fired.

    A memref-backed container also returns ``_PYIR_SKIP``, before any
    element access: element places of memref-backed owners are
    memory-authoritative (the same declared fact that gates the
    ``pyir_assign``/``pyir_read`` pass-throughs), so no row exists and
    no instrumentation access may be emitted.
    """
    # F-MEMORY: an element of a memref-backed owner lives in staged memory
    # and the owner's accessors emit its loads/stores; memory, not a row,
    # is the authority -- skip before the first element access.
    if not isinstance(key, str) and _is_memref_like(container):
        return _PYIR_SKIP
    if isinstance(container, (_WatchedDict, _WatchedList)):
        return _PYIR_SKIP
    # Untracked Python-mutable sequences and dict/list SUBCLASSES never become
    # watched place owners: element writes inside dynamic staged CF are refused.
    _untracked = isinstance(
        container,
        (bytearray, memoryview, _array_module.array, _collections_module.deque),
    ) or (isinstance(container, list) and type(container) is not list)
    if _untracked:
        # Human name computed from the type (module-qualified for stdlib
        # containers), never spelled as a literal.
        _kind_ty = type(container)
        _untracked_kind = _kind_ty.__name__
        if _kind_ty.__module__ not in ("builtins", None):
            _untracked_kind = _kind_ty.__module__ + "." + _untracked_kind
        if is_inside_staged_cf() and not is_inside_constexpr_loop():
            raise DSLUserCodeError(
                DiagId.CONTAINER_SUBSCRIPT_WRITE_UNTRACKED,
                var=str(target_name),
                kind=_untracked_kind,
            )
        return _PYIR_SKIP
    # Dict SUBCLASS with a MISSING key at the write: subclass magic materialises
    # the entry (a key-set change, loud in dynamic CF); existing keys stay tracked.
    if (
        isinstance(container, dict)
        and type(container) is not dict
        and not dict.__contains__(container, key)
        and is_inside_staged_cf()
        and not is_inside_constexpr_loop()
    ):
        raise DSLUserCodeError(
            DiagId.CONTAINER_DICT_KEY_SET_MUTATED,
            var=str(target_name),
            detail=f"key {key!r} created via {type(container).__name__}",
        )
    if isinstance(container, list):
        # A plain list no adoption tracks: the watched-list index wall,
        # whatever the CF depth, before a Staged index falls to the generic
        # ``__index__`` refusal.
        _pyir_list_index_wall(key, str(target_name).split("[", 1)[0])
        if not is_inside_locally_staged_cf():
            return _PYIR_SKIP
    elif not isinstance(container, dict):
        # Owner classification (funnel totality): a staged owner or a declared
        # DynamicExpression compound emits/reconstructs its own element writes.
        if _is_staged_value(container) or _implements_dynamic_expression(container):
            return _PYIR_SKIP
        # Anything else stores through an opaque ``__setitem__`` into state no
        # place row names. Pre-existing reachable leaves are carried by the
        # region walks; a container key CREATED by the write has no
        # pre-region cell, so it can never follow the region's runtime
        # predicate -- arm a region-close key-set audit of the owner.
        if is_inside_staged_cf() and not is_inside_constexpr_loop():
            _pyir_arm_opaque_owner_audit(str(target_name), container)
        return _PYIR_SKIP
    # A plain dict no adoption tracks (one a plain helper returned, or module
    # state, or a subclass inheriting dict's store): the watched-dict write
    # wall's key rule, before the store inserts an identity-hashed entry.
    _pyir_item_key_wall(
        container, key, str(target_name).split("[", 1)[0], "__setitem__"
    )
    try:
        old = container[key]  # type: ignore[call-overload]
    except (KeyError, IndexError):
        return None
    if isinstance(container, dict) and isinstance(old, (bool, int, float)):
        return old
    if _previous_compilation_value(old):
        # A leftover of a previous compilation: its backing IR lives in another
        # MLIR context, so this store overwrites it and nothing reads it here.
        # The slot is absent for this compilation (a first-def at the store).
        return None
    # Pass owner/slot_name so the slot registry distinguishes subscript entries that happen to hold the same
    # Python value; otherwise dict keys sharing one value would collapse onto a single ``pyir.ref``.
    return pyir_read(target_name, old, owner=container, slot_name=key)


def _previous_compilation_value(value: object) -> bool:
    """A leftover of a previous compilation: an SSA-backed value whose backing
    IR lives in another MLIR context (see :func:`_pyir_is_stale_staged`)."""
    return _pyir_is_stale_staged(value)


def _attr_owner_plain_storage_setattr(owner: object) -> bool:
    """Plain-storage judgment for an ATTRIBUTE assignment *owner*.

    ``_pyir_plain_storage_setattr`` inspects ``type(owner).__setattr__``.  For
    a CLASS owner (``cls.attr = ...``) that slot is the metaclass's, and
    ``type.__setattr__`` is not ``object.__setattr__`` even though an
    unadorned class stores attributes through plain type-dict storage -- so
    normal class-attribute writes would be misclassified as non-plain and a
    same-object write would wrongly veto its generated write-back.  Treat an
    unoverridden metaclass ``__setattr__`` as plain; a metaclass that DOES
    override it keeps the skip protocol like any other custom hook.
    """
    if isinstance(owner, type):
        return type(owner).__setattr__ is type.__setattr__
    return _pyir_plain_storage_setattr(type(owner))


def _pyir_pre_attr_assign(
    target_name: str,
    current_value: object,
    *,
    owner: object = None,
    slot_name: object = None,
) -> object:
    """Pre-store refresh for an ATTRIBUTE assignment target -- the attribute
    sibling of ``_pyir_pre_subscript_assign``'s ``_PYIR_SKIP`` protocol.

    The AST expansion stores this function's result straight back through
    *owner*'s REAL ``__setattr__`` (``obj.attr = <result>``), so the result
    must be a value that store can accept.  ``pyir_read`` runs first with all
    its tracking side effects intact; the write-back is then vetoed
    (``_PYIR_SKIP``) exactly when no fresh value was produced AND the owner's
    ``__setattr__`` is not plain object storage.  For such an owner the
    round-trip ``obj.attr = obj.attr`` is not a safe no-op: ``getattr`` may
    expose a handle the custom hook cannot accept as a stored value (a
    downstream-DSL struct field reads back as its scalar-slot pointer
    handle; assigning that handle back raises in the DSL's numeric
    conversion).  When ``pyir_read`` DID
    produce a fresh value the write-back proceeds unchanged -- a fresh load
    is a genuine value the owner's hook must accept anyway.
    """
    fresh = pyir_read(target_name, current_value, owner=owner, slot_name=slot_name)
    if (
        fresh is current_value
        and owner is not None
        and not _attr_owner_plain_storage_setattr(owner)
    ):
        return _PYIR_SKIP
    return fresh


def _pyir_post_attr_assign(
    target_name: str,
    old_value: object,
    new_value: object,
    filename: "str | None",
    lineno: "int | None",
    *,
    owner: object = None,
    slot_name: object = None,
    rmw_self: bool = False,
    rmw_path: "str | None" = None,
    rhs_ctor: object = None,
) -> object:
    """Post-store bookkeeping for an ATTRIBUTE assignment target.

    ``pyir_assign`` runs first and unconditionally, mirroring
    ``_pyir_pre_attr_assign``'s ``pyir_read``; the sentinel vetoes only the
    generated write-back ``obj.attr = <result>``.

    *old_value* / *new_value* are the attribute read back around the store.
    Identical reads on a non-plain owner OVER-APPROXIMATE the case the veto
    is for -- a downstream-DSL struct field reads back as its scalar-slot
    pointer handle, which the real ``__setattr__`` rejects in its numeric
    conversion.  They also catch a verbatim ``object.__setattr__`` forwarder
    , where the vetoed write-back would only
    re-store what ``getattr`` just returned.

    ``rmw_self``/``rmw_path`` are the syntactic RMW witness: every
    PREPROCESSOR injection site for an ATTRIBUTE target calls this wrapper,
    so both kwargs must be declared here and forwarded, or the generated
    call raises ``TypeError`` on every attribute read-modify-write.  Tracer-side
    callers (M->M decomposition, the write-choke replay) call ``pyir_assign``
    with ``owner``/``slot_name`` directly and carry no syntactic witness; a
    read-modify-write through them is caught at the loop's close by the
    owner-identity meta-leaf audit (``_pyir_verify_loop_meta_leaves``).
    """
    result = pyir_assign(
        target_name,
        old_value,
        new_value,
        filename,
        lineno,
        owner=owner,
        slot_name=slot_name,
        rmw_self=rmw_self,
        rmw_path=rmw_path,
        rhs_ctor=rhs_ctor,
    )
    if (
        new_value is old_value
        and owner is not None
        and not _attr_owner_plain_storage_setattr(owner)
    ):
        log().info(
            "[pyir_assign] '%s' handle-shaped attr on %s -- write-back skipped",
            target_name,
            type(owner).__name__,
        )
        return _PYIR_SKIP
    return result


def _promote_carried_attr_legs(
    root_name: str,
    root_obj: object,
    attr_paths: "tuple[tuple[str, ...], ...]",
    *,
    force_promote_meta: bool,
) -> None:
    """Route each declared carried attr leg through ``pyir_read`` with its
    ``(owner, slot)`` identity and rebind it (default ``__setattr__`` only)."""
    for path in attr_paths:
        if not path:
            continue
        owner: Any = root_obj
        skip = False
        for hop in path[:-1]:
            try:
                owner = getattr(owner, hop)
            except AttributeError:
                skip = True
                break
            if owner is None:
                skip = True
                break
        if skip or owner is None:
            continue
        leaf = path[-1]
        if not isinstance(leaf, str):
            continue
        owner_cls = type(owner)
        if not _pyir_plain_storage_setattr(owner_cls):
            log().info(
                "[pyir while] carried attr leg %s.%s skipped: %s overrides __setattr__",
                root_name,
                ".".join(path),
                owner_cls.__name__,
            )
            continue
        try:
            value = getattr(owner, leaf)
        except AttributeError:
            continue
        dotted = f"{root_name}.{'.'.join(path)}"
        fresh = pyir_read(
            dotted,
            value,
            owner=owner,
            slot_name=leaf,
            force_promote_meta=force_promote_meta,
        )
        if fresh is not value:
            try:
                _pyir_setattr_raw(owner, leaf, fresh)
            except (AttributeError, TypeError):
                pass  # frozen / __slots__ without target -- best-effort


def pyir_promote_while_carried_arg(
    target_name: str,
    current_value: object,
    is_condition_read: bool = True,
    condition_attr_paths: "tuple[tuple[str, ...], ...]" = (),
) -> object:
    """Materialise a ``scf.while`` write_arg's ref before the condition runs (an
    unpromoted meta write_arg would fold to ``scf.condition(%true)``)."""
    if not is_inside_staged_cf():
        return current_value
    # Promote declared carried attr legs to their place cells BEFORE the
    # condition evaluates, so it reads the carried cell.
    if (
        condition_attr_paths
        and current_value is not None
        and not isinstance(current_value, (bool, int, float, str, bytes))
        and _has_instance_storage(current_value)
    ):
        _promote_carried_attr_legs(
            target_name, current_value, condition_attr_paths, force_promote_meta=True
        )
    if (
        not isinstance(current_value, (bool, int, float))
        and current_value is not None
        and _has_instance_storage(current_value)
        and _implements_dynamic_expression(current_value)
        and not _can_create_ref(current_value)
        and not _is_scalar_ssa_carryable(current_value)
    ):
        _promote_compound_leaf_refs(current_value, target_name)
        return current_value
    if isinstance(current_value, (bool, int, float)):
        if not is_condition_read:
            # A meta-primitive the condition does not read is rederived per
            # iteration, not loop-carried; promoting would demote a constexpr.
            return current_value
        return _promote_loop_carried_meta(target_name, current_value)
    if ir is not None and isinstance(current_value, ir.Value):
        _pyir_refuse_stale_raw_carry(target_name, current_value, "`while` condition")
        if is_condition_read and isinstance(
            current_value.type, (ir.IntegerType, ir.FloatType)
        ):
            # A raw scalar SSA local the condition reads is a loop-carried
            # place: mint its cell (the body's write choke stores raw SSA
            # rebinds through the same row) and serve the condition from it,
            # so ``scf.condition`` reads the carried arg, not the stale
            # trace-time SSA.
            return _pyir_promote_raw_scalar_carry(target_name, current_value)
    # The carried binding is the carry engine's re-presentation of the
    # place, not a user rebind: the row stays authoritative for this read.
    return pyir_read(target_name, current_value, row_authoritative=True)


def _pyir_while_cond_hops_holder(root_obj: object, hops: "tuple[str, ...]") -> Any:
    """The object at ``root_obj.<hops>`` read through instance storage only
    (no descriptor runs); ``None`` when a hop is missing or not an object."""
    obj: Any = root_obj
    for hop in hops:
        items = _instance_storage_items(obj)
        if items is None or hop not in items:
            return None
        obj = items[hop]
        if obj is None or isinstance(obj, (bool, int, float, str, bytes)):
            return None
    return obj


def _pyir_while_cond_plain_def(fn: Any) -> "types.FunctionType | None":
    """*fn* as the plain unbound Python def its writes are facts of (through
    a declared ``__wrapped__`` chain); ``None`` for a bound method, class,
    builtin, partial or callable object -- their first parameter is not the
    passed object, so no receiver fact attributes their writes to it."""
    hops = 0
    while hasattr(fn, "__wrapped__") and hops < 8:
        fn = fn.__wrapped__
        hops += 1
    if isinstance(fn, types.FunctionType) and getattr(fn, "__self__", None) is None:
        return fn
    return None


def _pyir_while_cond_callee_written_legs(
    root_obj: object,
    cond_paths: "tuple[tuple[str, ...], ...]",
    free_calls: "tuple[tuple[tuple[str, ...], str, Callable[[], Any]], ...]",
    method_calls: "tuple[tuple[tuple[str, ...], str], ...]",
    opaque_hops: "tuple[tuple[str, ...], ...]",
) -> "tuple[tuple[str, ...], ...]":
    """The condition-read paths under *root_obj* a body callee can rewrite.

    Exact where the callee's def is resolvable and the passed object is
    provably its receiver (first parameter of a plain def called with it
    first, or the method's ``self``): the closure ``transitive_write_facts``
    names the written fields.  That closure under-approximates, so an
    partial closure, an unresolvable callee, and every pass the
    preprocessor could not attribute widen to all paths under the passed
    object -- a leg carried without a write is still correct; a write without
    a carry is a loop-invariant condition."""
    paths = [tuple(p) for p in cond_paths if p]
    carried: "set[tuple[str, ...]]" = set()
    opaque: "set[tuple[str, ...]]" = {tuple(h) for h in opaque_hops}

    def _under(hops: "tuple[str, ...]") -> "list[tuple[str, ...]]":
        return [p for p in paths if len(p) > len(hops) and p[: len(hops)] == hops]

    def _exact(hops: "tuple[str, ...]", bound_callee: Any) -> None:
        try:
            writes, complete = _pyir_class_facts.transitive_write_facts(bound_callee)
        except Exception:
            writes, complete = frozenset(), False
        for p in _under(hops):
            if p[len(hops)] in writes:
                carried.add(p)
        if not complete:
            opaque.add(hops)

    for hops, fname, thunk in free_calls:
        hops = tuple(hops)
        holder = _pyir_while_cond_hops_holder(root_obj, hops)
        if holder is None:
            continue
        try:
            fn = thunk()
        except Exception:
            opaque.add(hops)  # unbound here: the body's own call decides
            continue
        plain = _pyir_while_cond_plain_def(fn)
        if plain is not None:
            # The def's first parameter IS the passed object: bind it so the
            # closure resolves the def's receiver-method edges on its class.
            _exact(hops, types.MethodType(plain, holder))
            continue
        if isinstance(fn, types.BuiltinFunctionType) and not isinstance(fn, type):
            # A C builtin writes Python attributes only through the dynamic
            # access surface; any other cannot rebind a field.
            names = {fname, getattr(fn, "__name__", "")}
            if names & _pyir_class_facts._SURFACE_OPAQUE_CALLS:
                opaque.add(hops)
            continue
        opaque.add(hops)

    for hops, meth in method_calls:
        hops = tuple(hops)
        holder = _pyir_while_cond_hops_holder(root_obj, hops)
        if holder is None:
            continue
        # Class MRO only -- no instance getattr, so a property getter cannot
        # run here; an instance-dict callable or a ``__getattr__`` product
        # resolves to no def.
        target = None
        for klass in type(holder).__mro__:
            cand = klass.__dict__.get(meth)
            if cand is not None:
                target = cand
                break
        if isinstance(target, (staticmethod, classmethod)):
            continue  # the receiver is not passed
        plain = _pyir_while_cond_plain_def(target) if target is not None else None
        if plain is None or isinstance(target, property):
            opaque.add(hops)
            continue
        _exact(hops, plain.__get__(holder, type(holder)))

    for hops in opaque:
        carried.update(_under(hops))
    return tuple(sorted(carried))


def _pyir_while_cond_leg_storage(
    root_obj: object, path: "tuple[str, ...]"
) -> "tuple[Any, Any] | None":
    """``(holder, value)`` of the storage slot *path* names under *root_obj*;
    ``None`` when the leaf is not an instance-storage slot (a property or
    ``__getattr__`` product has no ``(owner, slot)`` cell to carry, and
    reading it here would run its getter)."""
    holder = _pyir_while_cond_hops_holder(root_obj, tuple(path[:-1]))
    items = _instance_storage_items(holder) if holder is not None else None
    if items is None or path[-1] not in items:
        return None
    return holder, items[path[-1]]


def _pyir_while_cond_leg_is_meta(root_obj: object, path: "tuple[str, ...]") -> bool:
    """True when the leaf of *path* under *root_obj* is a plain Python
    number (or its watched wrap): the value the off mode must not promote."""
    slot = _pyir_while_cond_leg_storage(root_obj, path)
    if slot is None:
        return False
    v = slot[1]
    py_v = v.python_value if isinstance(v, _WatchedM) else v
    return type(py_v) in (bool, int, float)


def _pyir_while_cond_leg_has_cell(root_obj: object, path: "tuple[str, ...]") -> bool:
    holder = _pyir_while_cond_hops_holder(root_obj, tuple(path[:-1]))
    if holder is None:
        return False
    try:
        place = _make_slot_key(None, holder, path[-1])
    except Exception:
        return False
    return place is not None and _slot_refs.get(place) is not None


def pyir_promote_while_cond_callee_legs(
    root_name: str,
    root_obj: object,
    *,
    cond_paths: "tuple[tuple[str, ...], ...]",
    free_calls: "tuple[tuple[tuple[str, ...], str, Callable[[], Any]], ...]" = (),
    method_calls: "tuple[tuple[tuple[str, ...], str], ...]" = (),
    opaque_hops: "tuple[tuple[str, ...], ...]" = (),
    reload: bool = False,
) -> None:
    """Carry the ``scf.while`` condition's attribute reads that a BODY CALLEE
    rewrites (``while m.remaining > 0: drain(m)``).

    The body traces once, so a condition leg with no cell compares the
    pre-loop SSA on every iteration: the loop would run to its other bound
    while the body dutifully updates the field.  The body's own text shows
    no write, so the carry is decided here from the callee's def (see
    ``_pyir_while_cond_callee_written_legs``) and each written leg is routed
    through its ``(owner, slot)`` cell before the condition reads it, exactly
    as a declared ``condition_attr_paths`` leg is.  ``reload`` is the
    after-block re-load of the same legs (the before-block load does not
    dominate the body); only legs that already have a cell re-load.

    Off mode: a plain-meta leg is left alone -- promoting it would turn a
    Python value into a runtime value behind the author's back; the callee's
    write of it is what the boundary refuses loudly."""
    if not is_inside_staged_cf():
        return
    if (
        root_obj is None
        or isinstance(root_obj, (bool, int, float, str, bytes))
        or not _has_instance_storage(root_obj)
    ):
        return
    legs = tuple(
        p
        for p in _pyir_while_cond_callee_written_legs(
            root_obj, cond_paths, free_calls, method_calls, opaque_hops
        )
        if _pyir_while_cond_leg_storage(root_obj, p) is not None
    )
    promote_meta = is_auto_m2s_enabled()
    if not promote_meta:
        legs = tuple(p for p in legs if not _pyir_while_cond_leg_is_meta(root_obj, p))
    if reload:
        legs = tuple(p for p in legs if _pyir_while_cond_leg_has_cell(root_obj, p))
    if not legs:
        return
    log().info(
        "[pyir while] callee-written condition legs of '%s': %s",
        root_name,
        ", ".join(".".join(p) for p in legs),
    )
    _promote_carried_attr_legs(
        root_name, root_obj, legs, force_promote_meta=promote_meta and not reload
    )


def _pyir_refuse_stale_raw_carry(
    target_name: str, current_value: "ir.Value", role: str
) -> None:
    """Refuse a raw SSA binding from an already-finalized compilation: it
    cannot be carried (its backing IR is gone). Runs before any dereference
    (only ``.context`` is a safe probe on a possibly-dangling value)."""
    try:
        _raw_ctx = id(current_value.context)
    except Exception:
        _raw_ctx = None
    if _raw_ctx != id(ir.Context.current):
        raise DSLRuntimeError(
            f"the {role} variable '{target_name}' holds an IR "
            "value produced by a previous @jit compilation and cannot be "
            "carried here: its backing IR lives in an already-finalized "
            "compilation context. Pass it through the kernel's arguments "
            "or recompute it in this compilation."
        )


def _pyir_promote_raw_scalar_carry(target_name: str, current_value: object) -> object:
    """Serve a loop-region read of a raw scalar ``ir.Value`` write_arg
    (``scf.while`` condition or loop-body entry) from its place cell, minting
    the cell at the declared pre-region position on first sight (the raw-value
    sibling of the wrapper mint in :func:`pyir_read`)."""
    if pyir is None or _make_slot_key(target_name, None, None) is None:
        return current_value
    mv = _get_slot_mv(None, target_name)
    if mv is None or not mv._is_ref_accessible():
        # A pre-region rebind may have D1-promoted this name already: adopt
        # that row (body D1 stores keep writing it; a second cell would split
        # body reads from body writes).
        mv = _pyir_adopt_d1_carry_cell(target_name, current_value)
    if mv is None or not mv._is_ref_accessible():
        _pre_ip = _pyir_promoted_region_pre_ip()
        if _pre_ip is not None:
            with _pre_ip:
                mv = _create_ref(current_value)
        else:
            mv = _create_ref(current_value)
        mv = _set_slot_mv(None, target_name, mv)
    loaded = mv.load()
    _attach_mutable_ref(loaded, mv, f"raw while-carry '{target_name}'")
    return loaded


def _pyir_promoted_region_pre_ip() -> "ir.InsertionPoint | None":
    """The declared pre-region position when a carry promotion fires with the
    promoted loop op's own block as the ambient insertion point."""
    if ir is None:
        return None
    try:
        owner = ir.InsertionPoint.current.block.owner
        op = getattr(owner, "operation", owner)
        if getattr(op, "name", None) in ("scf.while", "scf.for"):
            return ir.InsertionPoint(op)
    except Exception:
        pass
    return None


def _pyir_raw_dominates_region_exterior(raw: Any) -> bool:
    """True when *raw* is defined directly in the function body region (its
    definition's parent is the function op itself).  Trace emission is
    program-ordered, so a function-scope definition precedes -- and therefore
    dominates -- every later trace point, including reads emitted after the
    enclosing staged region closes.  Conservative: False."""
    if ir is None:
        return False
    try:
        owner = raw.owner
        if isinstance(owner, ir.Block):
            host = owner.owner  # block argument: the op owning the block
        else:
            host = getattr(owner, "operation", owner).parent
        host_op = getattr(host, "operation", host)
        return _is_func_boundary_op(str(host_op.name))
    except Exception:
        return False


def _promote_loop_carried_meta(target_name: str, current_value: object) -> object:
    """Eagerly promote a read-before-write loop-carried meta primitive to a
    function-entry ``pyir.ref`` and return a dominating load."""
    if pyir is None:
        return current_value
    d1_slot = _make_slot_key(target_name, None, None)
    if d1_slot is None:
        return current_value
    initial_py = (
        current_value.python_value
        if isinstance(current_value, _WatchedM)
        else current_value
    )
    if not isinstance(initial_py, (bool, int, float)):
        return current_value
    existing_ref = _slot_refs.get(d1_slot)
    if existing_ref is None:
        # Read-before-write => loop-carried: force the reset flag off. EXCEPTION:
        # a strictly-shallower literal first-def is an outer-loop reset that must survive.
        first_def_depth = _slot_first_def_depth.get(d1_slot)
        outer_reset = (
            _slot_first_def_inside_cf.get(d1_slot, False)
            and first_def_depth is not None
            and first_def_depth < current_staged_cf_depth()
        )
        if not outer_reset:
            # Adopt the value-carried first-def facts (F-FIRSTDEF) only when
            # the recorded reset position dominates this read; else plain carry.
            adopted = False
            fd_key = (
                current_value._slot_key
                if isinstance(current_value, _WatchedM)
                else None
            )
            if fd_key is not None and fd_key != d1_slot:
                fd_block = _slot_first_def_block.get(fd_key)
                fd_depth = _slot_first_def_depth.get(fd_key)
                try:
                    cur_block = ir.InsertionPoint.current.block
                except Exception:
                    cur_block = None
                if (
                    _slot_first_def_inside_cf.get(fd_key, False)
                    and fd_block is not None
                    and fd_depth is not None
                    and _block_strictly_inside(cur_block, fd_block)
                ):
                    _slot_first_def_inside_cf[d1_slot] = True
                    _slot_first_def_block[d1_slot] = fd_block
                    _slot_first_def_depth[d1_slot] = fd_depth
                    adopted = True
            if not adopted:
                _slot_first_def_inside_cf[d1_slot] = False
        existing_ref = _meta_promote_slot(d1_slot, initial_py, target_name)
        if existing_ref is None:
            return current_value
    return _load_as_dsl(existing_ref, place=d1_slot)


def _pyir_check_unpack_arity(seq: Any, expected: int, has_star: bool) -> None:
    """Replicate CPython's unpack arity check for the decomposed unpack.

    The decomposition stores each element with ``tmp[i]``, which silently
    ignores a length mismatch -- Python raises.  Emitted once per sequence
    target (each target of ``(p, q) = (c, r, s) = rhs`` checks its own arity
    against the shared temp).
    """
    got = len(seq)
    if has_star:
        if got < expected:
            raise ValueError(
                f"not enough values to unpack (expected at least {expected}, got {got})"
            )
        return
    if got < expected:
        raise ValueError(
            f"not enough values to unpack (expected {expected}, got {got})"
        )
    if got > expected:
        # CPython below 3.14 words this one without the ", got N" tail; the other
        # two carried it already.
        # Emit the 3.14 spelling everywhere because it is clear and the text
        # does not depend on the interpreter the trace happens to run under.
        raise ValueError(f"too many values to unpack (expected {expected}, got {got})")


def _pyir_pin_tuple_capture(
    value: Any, _seen: "set[int] | None" = None, *, unpack_source: bool = False
) -> Any:
    """Pin the watched-meta elements of a tuple-unpack RHS at the CAPTURE
    position (called by the AST tuple-assign decomposition's temp statement).

    Python evaluates the whole RHS before any element store, so a swap must
    consume each source's value AS OF the capture.

    A ``_WatchedM`` element materialised here leaves a position-recorded
    constant; a later promotion rewrites it to a position-correct ``pyir.load``.

    Meta-ness is untouched; non-watched elements and non-container captures
    pass through.

    ``unpack_source`` marks the pin that captures a whole unpack RHS (emitted by
    ``_make_rhs_pin``); such a value is also MATERIALISED here when it is not
    already an indexable sequence.  The decomposition extracts elements by index
    (``tmp[i]``) while Python's native unpack walks ``__iter__``, so a generator
    / ``zip`` / set / dict source has to become a tuple exactly once (a
    generator is single-use, and several chained targets share this one temp).
    A non-iterable source raises ``TypeError`` from ``tuple()`` here, which is
    what Python's own unpack does.

    The flag is OFF for the element pin the decomposition wraps around a
    ``_pyir_nest_N`` extraction: that value is a single element, routinely a
    scalar, and its own follow-up statement pins it as an unpack source later.
    """
    if unpack_source and not isinstance(value, (tuple, list, str, bytes)):
        value = tuple(value)
    if pyir is None or not is_inside_staged_cf():
        return value
    if isinstance(value, (tuple, list)):
        # Recurse into NESTED tuple/list elements: their leaves defer to a
        # follow-up statement of the unpack split, which runs AFTER the
        # flat element stores -- an unpinned doubly-nested leaf would load
        # the post-store value (swap pinning breaks one level down).  The
        # id set only breaks self-referential list cycles.
        _seen = set() if _seen is None else _seen
        if id(value) in _seen:
            return value
        _seen.add(id(value))
        pinned = [
            (
                _pyir_pin_tuple_capture(_elem, _seen)
                if isinstance(_elem, (tuple, list))
                else _pyir_anchor_statement_read(_elem)
            )
            for _elem in value
        ]
        if any(p is not e for p, e in zip(pinned, value)):
            return (
                pinned
                if isinstance(value, list)
                else _rebuild_tuple_like(value, pinned)
            )
        return value
    return _pyir_anchor_statement_read(value)


def _pyir_anchor_statement_read(value: Any) -> Any:
    """Anchor one managed-place read at ITS OWN program point (statement-top
    read-anchor rule, the scalar sibling of :func:`_pyir_pin_tuple_capture`).

    Emitted by the preprocessor for a read Python evaluates BEFORE a
    same-statement store of the same place (a pre-walrus read).

    * ``_WatchedM``: materialise the constant HERE so a later promotion
      rewrites it to a ``pyir.load`` preceding the store; meta-ness untouched.

    * cell-paired staged wrapper: return a fresh SNAPSHOT ``mv.load()`` (no
      ``_mutable_ref``), so later reads never follow the cell past the store.

    Everything else passes through untouched.
    """
    if pyir is None or not is_inside_staged_cf():
        return value
    if isinstance(value, _WatchedM):
        # PROMOTED place: the read must be a load AT THIS POSITION (a deferred
        # materialisation could land after the same-statement store).
        slot = getattr(value, "_slot_key", None)
        if slot is not None:
            _ref = _slot_refs.get(slot)
            if isinstance(_ref, ir.Value) and _value_dominates_current_ip(_ref):
                try:
                    return _load_as_dsl(_ref, attach=False, place=slot)
                except Exception:
                    pass
        try:
            value.ir_value()
        except Exception:
            pass  # no context / unsupported width -- consumer decides
        return value
    mv = getattr(value, "_mutable_ref", None)
    if mv is not None:
        try:
            if mv.ref is not None and mv._is_ref_accessible():
                return mv.load()
        except Exception:
            pass
    return value


def _pyir_watched_dict_read(container: "_WatchedDict", key: Any, val: Any) -> Any:
    """Object-side READ choke for one adopted dict entry: the owner-keyed
    ``pyir_read`` lifecycle from ANY Python code; nested plain dicts adopt.
    An instance-``__dict__`` mapping routes str-keyed items to the INSTANCE's
    attr row -- one place row per storage, whatever the spelling."""
    label = _pyir_watched_dict_label(container, key)
    if type(val) is dict or isinstance(val, _WatchedDict):
        return _pyir_adopt_dict_value(container, key, val, label=label)
    if type(val) is list or isinstance(val, _WatchedList):
        return _pyir_adopt_list_value(container, key, val, label=label)
    # A plain OBJECT surfacing through a container leg: its attr legs are
    # places one composition deeper (root -> dict-leg -> attr-leg).
    _pyir_register_container_held_object(val)
    place_owner = _pyir_instance_dict_owner(container, key)
    return pyir_read(
        label,
        val,
        attach_ref=False,
        owner=place_owner if place_owner is not None else container,
        slot_name=key,
    )


def _pyir_watched_dict_write(
    container: "_WatchedDict",
    key: Any,
    value: Any,
    filename: str,
    lineno: int,
) -> Any:
    """Object-side WRITE choke for one adopted dict entry: the AST write choke's
    read+assign lifecycle; unpromoted meta changes in dynamic staged CF are refused.
    An instance-``__dict__`` mapping routes str-keyed items to the INSTANCE's
    attr row -- one place row per storage, whatever the spelling."""
    label = _pyir_watched_dict_label(container, key)
    # A key must NAME a compile-time place: a staged / IR-backed key, or a key
    # whose own ``__hash__`` launders staged identity, is refused.
    _pyir_dict_key_wall(key, getattr(container, "_pyir_label", None) or "dict")
    _inst = _pyir_instance_dict_owner(container, key)
    place_owner = _inst if _inst is not None else container
    missing = not dict.__contains__(container, key)
    seeded = _PYIR_CF_SEEDED_ATTRS.get((id(place_owner), key)) if missing else None
    if seeded is not None and "default" in seeded:
        # A default-taken miss earlier in this region seeded the entry: this
        # store is the seeded entry's first UPDATE, a write to an existing
        # place whose entry value is the default.
        old = pyir_read(label, seeded["default"], owner=place_owner, slot_name=key)
        missing = False
    elif missing:
        # New-key insertion through SUBSCRIPT syntax stays supported (first-def
        # mints the cell; stale reads refuse at the READ). Mutator methods stay loud.
        old = None
        # A key probed absent earlier in this open region (an unseeded
        # ``.get()`` miss) and created here: the probe's answer is fixed to
        # the first iteration while Python finds the key afterwards.
        if is_inside_staged_cf() and not is_inside_constexpr_loop():
            _pyir_check_absent_probe_then_bound(place_owner, key)
        # Inside dynamic staged CF the key SET changed on this one traced pass
        # only: record it (with the creating arm path) so a later whole-key-set
        # consumption (membership, lookup miss, a walk outside the creating
        # path) refuses instead of baking this pass's truth.
        if is_inside_staged_cf() and not is_inside_constexpr_loop():
            _PYIR_DICT_CF_CREATED_KEYS.setdefault(id(container), (container, {}))[
                1
            ].setdefault(key, _pyir_current_region_arm_path())
        # Gate-once evidence: a first-def traced under a folded constant ``if`` arm
        # lifts keep-meta when the arm provably latched the gate (see pyir_state).
        if _PYIR_FOLD_FIRSTDEF_STACK:
            try:
                _fd_slot = _make_slot_key(None, place_owner, key)
                if _fd_slot is not None:
                    _PYIR_FOLD_FIRSTDEF_STACK[-1].append(_fd_slot)
            except Exception:
                pass
    else:
        old = pyir_read(
            label,
            dict.__getitem__(container, key),
            owner=place_owner,
            slot_name=key,
        )
    if type(value) is dict:
        value = _pyir_adopt_dict_value(container, key, value, label=label)
    elif type(value) is list:
        value = _pyir_adopt_list_value(container, key, value, label=label)
    result = pyir_assign(
        label, old, value, filename, lineno, owner=place_owner, slot_name=key
    )
    # A first-def inside a PLAIN callee within a staged loop has unprovable
    # multiplicity: lift keep-meta so later meta changes fail-close loudly.
    if (
        missing
        and _PYIR_BOUNDARY_CALLEE_DEPTH[0] > 0
        and not _PYIR_FOLD_FIRSTDEF_STACK
        and is_inside_staged_cf()
        and not is_inside_constexpr_loop()
        and _innermost_enclosing_loop_op_at_ip() is not None
    ):
        try:
            _fd_slot = _make_slot_key(None, place_owner, key)
            if _fd_slot is not None:
                _slot_first_def_inside_cf[_fd_slot] = False
        except Exception:
            pass
    # A NEW-key insert inside a constexpr-unrolled loop pins foreign-bound staged
    # values at insertion-time SSA (the staged-container-insert freeze).
    if missing and is_inside_constexpr_loop() and _carries_foreign_slot_binding(result):
        result = _freeze_foreign_slot_binding(
            result, "constexpr-loop watched-dict insert"
        )
    # Mark the dict as carrying tracked writes: drives get()-miss loudness (a
    # miss default would bake fixed while sibling entries update).
    if _is_staged_value(result) or is_inside_staged_cf():
        try:
            container._pyir_staged_writes = True
        except Exception:
            pass
    # Loud residue: a meta->meta change on an un-promoted leg in dynamic staged CF
    # refuses; declared keep-meta forms (constexpr, reset, unchanged, first def) pass.
    if (
        old is not None
        and isinstance(old, (bool, int, float))
        and isinstance(result, (bool, int, float))
        and not _is_staged_value(result)
        and is_inside_staged_cf()
        and not is_inside_constexpr_loop()
    ):
        _d1 = _make_slot_key(None, place_owner, key)
        _old_p = old.python_value if isinstance(old, _WatchedM) else old
        _new_p = result.python_value if isinstance(result, _WatchedM) else result
        if (
            _d1 is not None
            and _d1 not in _slot_refs
            and not _slot_first_def_inside_cf.get(_d1, False)
            and _old_p != _new_p
        ):
            raise DSLUserCodeError(
                DiagId.CONTAINER_DICT_META_WRITE_UNPROMOTED,
                filename=filename,
                lineno=lineno,
                var=label,
                old_value=repr(_old_p),
                new_value=repr(_new_p),
            )
    return result


def _pyir_watched_dict_mutate(
    container: "_WatchedDict", op_name: str, detail: str
) -> None:
    """Object-side STRUCTURAL-mutation choke (key-set changes): loud inside dynamic
    staged CF only; constexpr scopes realize the mutation and route the insert freeze."""
    _pyir_spec_structural_amend(container)
    if op_name in ("setdefault", "update"):
        _pyir_freeze_staged_container_inserts(container, "update")
    if is_inside_staged_cf() and not is_inside_constexpr_loop():
        raise DSLUserCodeError(
            DiagId.CONTAINER_DICT_KEY_SET_MUTATED,
            var=getattr(container, "_pyir_label", None) or "dict",
            detail=detail,
        )


def _pyir_watched_dict_get_miss(
    container: "_WatchedDict", key: Any, default: Any = None
) -> Any:
    """Object-side ``get()``-MISS choke: a miss default on a dict with tracked
    writes inside dynamic staged CF is path-dependent -- refused.

    Inside an open staged LOOP body a primitive default is the entry value of
    an entry the body creates by its own first update (``d[k] = d.get(k, 0)
    + 1``): the miss is the read half of a carried accumulator, so the place
    is seeded with the default (a record, the storage stays untouched) and
    the read routes through the item read choke (the first write then takes
    the assign choke: promotion, or the loud refusal in the default mode).
    Returns the served read, or ``None`` when the plain default is Python's
    answer; an unseeded miss records an absence probe so a first-def of the
    key later in the same region refuses."""
    if (
        getattr(container, "_pyir_staged_writes", False)
        and is_inside_staged_cf()
        and not is_inside_constexpr_loop()
    ):
        raise DSLUserCodeError(
            DiagId.CONTAINER_DICT_GET_MISS_IN_STAGED_CF,
            var=getattr(container, "_pyir_label", None) or "dict",
            detail=repr(key),
        )
    if (
        not is_inside_staged_cf()
        or is_inside_constexpr_loop()
        or not _pyir_open_loop_body_blocks
        or _is_staged_value(key)
        or isinstance(key, ir.Value)
    ):
        return None
    _inst = _pyir_instance_dict_owner(container, key)
    place_owner = _inst if _inst is not None else container
    # A container with no recorded birth inside nested open loops cannot be
    # anchored (its entry value may be per-outer-iteration): probe only.
    from .pyir_callee_rewrite import _pyir_boundary_birth_anchor

    seedable = type(default) in (bool, int, float) and (
        len(_pyir_open_loop_body_blocks) == 1
        or _pyir_boundary_birth_anchor(place_owner) is not None
    )
    if not seedable:
        _pyir_note_absent_probe(place_owner, key, "a default-taken `.get()`")
        return None
    _pyir_check_absent_probe_then_bound(place_owner, key)
    # The storage stays untouched (Python creates the key only at the write):
    # the record alone makes a later first-def of the key in this region the
    # seeded entry's first UPDATE, and a probe or iteration of the dict refuse.
    place = _make_slot_key(None, place_owner, key)
    from .pyir_callee_rewrite import _pyir_boundary_declare_birth_place

    _pyir_boundary_declare_birth_place(place_owner, place)
    src_file, src_line = _first_non_dsl_caller_location()
    _PYIR_CF_SEEDED_ATTRS.setdefault(
        (id(place_owner), key),
        {
            "arms": _pyir_current_region_arm_path(),
            "site": (src_file, src_line),
            "default": default,
        },
    )
    return pyir_read(
        _pyir_watched_dict_label(container, key),
        default,
        attach_ref=False,
        owner=place_owner,
        slot_name=key,
    )


def _pyir_watched_dict_iterate(container: Any, method: str) -> Any:
    """ITERATION choke for tracked dicts inside dynamic staged CF.  The key
    set is trace-time STABLE (structural mutation refuses at the mutator
    choke), so enumerating it is exact -- but the raw stored VALUES are a
    trace-time snapshot that bypasses the per-entry read choke, so
    ``.values()``/``.items()`` serve every entry through the same tracked
    read path ``d[k]`` uses (the carried slot read); a write driven by the
    pair then stores through the tracked path naturally.  Key walks (bare
    ``iter()``/``.keys()``) raw-delegate: per-slot reads re-enter the item
    choke themselves.  The one UNSTABLE case refuses: a key CREATED inside
    dynamic staged CF (subscript first-def) on a region-arm path the walk
    does not lie under exists on the one traced pass only, so the enumerated
    key set cannot follow the runtime path.  A key created earlier on a path
    still open at the walk (same body, or an enclosing one) is created on
    every runtime execution that reaches the walk, so the walk is exact.
    Returns the served sequence, or None to raw-delegate (constexpr scopes
    realize the walk at trace time)."""
    if not is_inside_staged_cf() or is_inside_constexpr_loop():
        return None
    entry = _PYIR_DICT_CF_CREATED_KEYS.get(id(container))
    if entry is not None:
        cur_arms = _pyir_current_region_arm_path()
        uncovered = [
            k
            for k, arms in entry[1].items()
            if not (arms and _pyir_arm_path_covers(arms, cur_arms))
        ]
        if uncovered:
            raise DSLUserCodeError(
                DiagId.CONTAINER_DICT_ITERATED_IN_STAGED_CF,
                var=getattr(container, "_pyir_label", None) or "dict",
                method=method,
                detail=", ".join(sorted(repr(k) for k in uncovered)),
            )
    # A key seeded by its own default-taken miss is absent on the first
    # iteration only: the enumerated key set is iteration-dependent.
    seeded = [k for (oid, k) in _PYIR_CF_SEEDED_ATTRS if oid == id(container)]
    if seeded:
        raise DSLUserCodeError(
            DiagId.CONTAINER_DICT_ITERATED_IN_STAGED_CF,
            var=getattr(container, "_pyir_label", None) or "dict",
            method=method,
            detail=", ".join(sorted(repr(k) for k in seeded)),
        )
    name = method.strip(".()")
    if name not in ("values", "items"):
        return None
    served = []
    for key in list(dict.keys(container)):
        val = container[key]
        served.append(val if name == "values" else (key, val))
    return served


def _pyir_watched_list_index(
    container: "_WatchedList", key: Any, label: str
) -> "int | None":
    """Validate and normalise a list-leg index: staged indices refuse, negative
    trace-time indices normalise, anything else returns ``None`` (raw delegation)."""
    _pyir_list_index_wall(key, getattr(container, "_pyir_label", None) or "list")
    if not isinstance(key, int):
        return None
    idx = int(key)
    if idx < 0:
        idx += list.__len__(container)
    if idx < 0 or idx >= list.__len__(container):
        return None
    return idx


def _pyir_watched_list_read(container: "_WatchedList", key: Any) -> Any:
    """Object-side READ choke for one adopted list element (owner-keyed snapshot
    read; nested plain containers adopt; slices never reach here)."""
    label = _pyir_watched_list_label(container, key)
    idx = _pyir_watched_list_index(container, key, label)
    if idx is None:
        return list.__getitem__(container, key)
    val = list.__getitem__(container, idx)
    if type(val) is dict or isinstance(val, _WatchedDict):
        return _pyir_adopt_dict_value(container, idx, val, label=label)
    if type(val) is list or isinstance(val, _WatchedList):
        return _pyir_adopt_list_value(container, idx, val, label=label)
    # A plain OBJECT surfacing through a container leg: its attr legs are
    # places one composition deeper (root -> list-leg -> attr-leg).
    _pyir_register_container_held_object(val)
    return pyir_read(
        label,
        val,
        attach_ref=False,
        owner=container,
        slot_name=idx,
    )


def _pyir_watched_list_write(
    container: "_WatchedList",
    key: Any,
    value: Any,
    filename: str,
    lineno: int,
) -> Any:
    """Object-side WRITE choke for one adopted list element: the dict write choke's
    lifecycle on integer legs (no first-def arm; unpromoted meta changes refuse)."""
    label = _pyir_watched_list_label(container, key)
    idx = _pyir_watched_list_index(container, key, label)
    if idx is None:
        # Wrong-type / out-of-range index: the caller's raw store raises the
        # plain-Python error.
        return value
    old = pyir_read(
        label,
        list.__getitem__(container, idx),
        owner=container,
        slot_name=idx,
    )
    if type(value) is dict:
        value = _pyir_adopt_dict_value(container, idx, value, label=label)
    elif type(value) is list:
        value = _pyir_adopt_list_value(container, idx, value, label=label)
    result = pyir_assign(
        label, old, value, filename, lineno, owner=container, slot_name=idx
    )
    if (
        old is not None
        and isinstance(old, (bool, int, float))
        and isinstance(result, (bool, int, float))
        and not _is_staged_value(result)
        and is_inside_staged_cf()
        and not is_inside_constexpr_loop()
    ):
        _d1 = _make_slot_key(None, container, idx)
        _old_p = old.python_value if isinstance(old, _WatchedM) else old
        _new_p = result.python_value if isinstance(result, _WatchedM) else result
        if (
            _d1 is not None
            and _d1 not in _slot_refs
            and not _slot_first_def_inside_cf.get(_d1, False)
            and _old_p != _new_p
        ):
            raise DSLUserCodeError(
                DiagId.CONTAINER_LIST_META_WRITE_UNPROMOTED,
                filename=filename,
                lineno=lineno,
                var=label,
                old_value=repr(_old_p),
                new_value=repr(_new_p),
            )
    return result


def _pyir_watched_list_mutate(
    container: "_WatchedList", op_name: str, detail: str
) -> None:
    """Object-side STRUCTURAL-mutation choke (length/order changes): loud inside
    dynamic staged CF; constexpr scopes realize the mutation and route the freeze."""
    _pyir_spec_structural_amend(container)
    if op_name in _PYIR_LIST_INSERT_MUTATORS:
        _pyir_freeze_staged_container_inserts(container, op_name)
    if is_inside_staged_cf() and not is_inside_constexpr_loop():
        raise DSLUserCodeError(
            DiagId.CONTAINER_LIST_SHAPE_MUTATED,
            var=getattr(container, "_pyir_label", None) or "list",
            detail=detail,
        )


# Install the watched-container choke hooks (the classes live in the core
# layer, which cannot import this one; see _WATCHED_*_HOOK in pyir_state).
_WATCHED_DICT_READ_HOOK[0] = _pyir_watched_dict_read
_WATCHED_DICT_WRITE_HOOK[0] = _pyir_watched_dict_write
_WATCHED_DICT_MUTATOR_HOOK[0] = _pyir_watched_dict_mutate
_WATCHED_DICT_GET_MISS_HOOK[0] = _pyir_watched_dict_get_miss
_WATCHED_DICT_ITER_HOOK[0] = _pyir_watched_dict_iterate
_WATCHED_LIST_READ_HOOK[0] = _pyir_watched_list_read
_WATCHED_LIST_WRITE_HOOK[0] = _pyir_watched_list_write
_WATCHED_LIST_MUTATOR_HOOK[0] = _pyir_watched_list_mutate


# Static export surface (regenerate with scripts/gen_pyir_all.py): the
# module's OWN names -- its namespace minus what lower chain modules
# already export and minus the generator's INTERNAL_ONLY registry.
__all__ = [
    "_decompose_tuple",
    "_pyir_regions_since_binding",
    "_pyir_identity_repoint_obstacle",
    "_pyir_select_join_owns_rebind",
    "_pyir_judge_identity_repoint",
    "_unalias_tuple_leaves",
    "_pyir_check_no_complex_m2m_call",
    "_pyir_freeze_staged_container_inserts",
    "pyir_promote_loop_body_arg",
    "_pyir_live_row_handle",
    "_PYIR_PLACEHOLDER_INIT_ATTRS",
    "_pyir_condition_bound_row",
    "_pyir_record_fresh_entry_birth",
    "_pyir_is_opaque_handle_binding",
    "_pyir_judge_exception_slot_write",
    "pyir_assign",
    "PYIR_REGION_ATTR_WRITES_ATTR",
    "PYIR_REGION_METHOD_CALLS_ATTR",
    "PYIR_REGION_FREE_CALLS_ATTR",
    "PYIR_REGION_DEAD_ON_ENTRY_ATTR",
    "pyir_tag_region_attr_writes",
    "_PYIR_BIND_VALUE_UNSET",
    "_meta_kind",
    "_pyir_sibling_pair_conflict",
    "_pyir_bind_sibling_first_def",
    "_pyir_short_repr",
    "_pyir_mark_if_arm_meta_leaves",
    "_pyir_settle_sibling_arm_values",
    "pyir_note_attr_first_def",
    "pyir_generation_probe",
    "_pyir_judge_fabricated_attr_read",
    "_PYIR_FGET_DEREF_OPS",
    "_pyir_canonical_slot_name",
    "pyir_read",
    "pyir_bind_param",
    "_pyir_obs_read",
    "_pyir_obs_global_read",
    "_pyir_post_attr_read",
    "_pyir_post_subscript_read",
    "_pyir_pre_subscript_assign",
    "_previous_compilation_value",
    "_attr_owner_plain_storage_setattr",
    "_pyir_pre_attr_assign",
    "_pyir_post_attr_assign",
    "pyir_promote_while_carried_arg",
    "_pyir_while_cond_hops_holder",
    "_pyir_while_cond_plain_def",
    "_pyir_while_cond_callee_written_legs",
    "_pyir_while_cond_leg_storage",
    "_pyir_while_cond_leg_is_meta",
    "_pyir_while_cond_leg_has_cell",
    "pyir_promote_while_cond_callee_legs",
    "_pyir_check_unpack_arity",
    "_pyir_pin_tuple_capture",
    "_pyir_anchor_statement_read",
]
