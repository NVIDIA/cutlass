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


"""PyIR runtime -- loop-carry layer; see facade for the public surface.

Loop carries exist because a value written in a loop body must feed the next
iteration before the region closes. Staged writes inside scf.if regions need
no carry here: they store into the variable's function-entry pyir.ref slot and
the mem2reg lowering in convert-pyir-to-scf materializes them as scf.if
results; only the opaque-leaf companion _pyir_carry_if_region_mutated_leaves
lives in this module.
"""

from .pyir_state import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_core import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_corewalk import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)


def _pyir_push_loop_body_scope(body_block: "ir.Block") -> None:
    """Declare *body_block* as the innermost open staged-loop body (F-BIRTHPOS);
    a body-region entry is a region-epoch boundary (F-GEN)."""
    _pyir_bump_region_epoch()
    _pyir_region_entry_push()
    _pyir_open_loop_body_blocks.append(body_block)


def _pyir_pop_loop_body_scope() -> None:
    """Close the innermost open loop-body declaration (a region-epoch boundary)."""
    _pyir_bump_region_epoch()
    _pyir_region_entry_pop()
    if _pyir_open_loop_body_blocks:
        _pyir_open_loop_body_blocks.pop()


def _meta_promote_slot(
    slot_key: Any,
    initial_py_value: Any,
    target_name: str | None = None,
    filename: str | None = None,
    lineno: int | None = None,
    promoted_value: Any = None,
    display_name: str | None = None,
) -> "ir.Value | None":
    """Promote a slot to D1 tracking (AUTO_M2S only; refuses when the flag
    is off -- ``PHASE_AUTO_PROMOTE_DISABLED``).

    Creates a ``pyir.ref`` at the enclosing function's entry block
    initialized with *initial_py_value*, then walks every previously
    baked ``arith.constant`` recorded under *slot_key* and replaces its
    uses with a freshly-emitted ``pyir.load %ref``.  The replaced
    constants become dead and DCE cleans them up; downstream arith ops
    pick up the load via SSA edges automatically -- no per-derivation
    rewriting needed.

    Warns which variable was promoted (value + file:line of the mutation),
    with the same wording as the Mp→S warning in ``pyir_read``.

    Returns the new ``pyir.ref`` SSA value, or ``None`` if there is no
    enclosing function (e.g. tracing happens outside an MLIR context).
    """
    if pyir is None:
        return None
    entry_block = _get_function_entry_block()
    if entry_block is None:
        return None

    # Implicit Meta-to-Staged promotion is an AUTO_M2S feature; with the flag
    # off the mode's contract is "never silently wrong", so every promotion
    # request refuses loudly instead of rewriting the slot.
    if not is_auto_m2s_enabled():
        _promoted_cls = _declared_m2s_promotion_class(initial_py_value)
        raise DSLUserCodeError(
            DiagId.PHASE_AUTO_PROMOTE_DISABLED,
            filename=filename,
            lineno=lineno,
            var=target_name or display_name or str(slot_key),
            value=repr(initial_py_value),
            type=_promoted_cls.__name__ if _promoted_cls is not None else "Int32",
        )

    # This place gated a plain callee's literal store that boundary commit turned
    # into a per-iteration constant; staging it breaks that proof -- refuse loudly.
    _guard_read = _PYIR_BOUNDARY_FLIP_GUARD_READS.get(slot_key)
    if _guard_read is not None:
        _gr_name, _gr_flipped, _gr_file, _gr_line = _guard_read
        raise DSLUserCodeError(
            DiagId.BOUNDARY_FLIP_GUARD_STAGED,
            filename=filename,
            lineno=lineno,
            name=_gr_name,
            flipped=_gr_flipped,
            def_file=_gr_file,
            def_line=_gr_line,
        )

    # This place was read through a closure cell by a plain callee inside staged
    # CF; no rewrite can retarget that baked read -- refuse loudly.
    _cell_read = _pyir_boundary_cell_read_for_local(slot_key)
    if _cell_read is not None:
        _cr_name, _cr_file, _cr_line = _cell_read
        raise DSLUserCodeError(
            DiagId.BOUNDARY_CLOSURE_READ_THEN_PROMOTED,
            filename=filename,
            lineno=lineno,
            name=_cr_name,
            def_file=_cr_file,
            def_line=_cr_line,
        )

    # A place already consumed as trace-time structure has no retargetable SSA
    # constant, so promotion refuses -- unless the promotion seed AND the
    # triggering write (when there is one) provably re-establish the consumed
    # value, in which case the baked structure stays valid on every iteration.
    # A write that stays in the region birthing the place re-runs that binding
    # every iteration, so the bake stays valid and promotion is safe even when
    # the triggering write is staged. Only a place born above the loop carries.
    _sc = _PYIR_STRUCTURAL_META_CONSUMPTIONS.get(slot_key)
    if _sc is not None and _pyir_structural_bake_is_reseeded(slot_key):
        _sc = None
    if _sc is not None and (
        _pyir_structural_value_conflicts(_sc, initial_py_value)
        or (
            promoted_value is not None
            and _pyir_structural_value_conflicts(_sc, promoted_value)
        )
    ):
        _sc_value, _sc_file, _sc_line = _sc
        raise DSLUserCodeError(
            DiagId.PHASE_STRUCTURAL_CONSTANT_MUTATED,
            filename=filename,
            lineno=lineno,
            var=target_name or str(slot_key),
            value=_sc_value,
            read_file=_sc_file,
            read_line=_sc_line,
        )

    # F-SPEC: the promotion bakes the meta payload as the cell's seed -- a
    # specialization fact of this trace when the place is root-pathable.
    _pyir_spec_record_read(slot_key, initial_py_value)

    # A promotion triggered by a staged write must type the ref pointee (and every
    # reset constant) by the staged value's type, else a later store fails verification.
    _staged_target_type = None
    if promoted_value is not None:
        from .multi_stage_manager import _is_staged_value

        if _is_staged_value(promoted_value):
            _staged_target_type = type(promoted_value)

    def _emit_init() -> "ir.Value":
        if _staged_target_type is not None:
            try:
                return _staged_target_type(initial_py_value).ir_value()
            except (TypeError, ValueError, AttributeError):
                pass
        return _emit_constant_at_current_ip(initial_py_value)

    # F-BIRTHPOS: a region-born place seeds itself with a real store at its
    # recorded birth block (per-iteration in a loop body, per-branch in an if
    # arm) and takes an undefined-placeholder entry init, so a path where the
    # binding never ran is caught by the used-placeholder scan.
    _birth_block = (
        _slot_first_def_block.get(slot_key)
        if _slot_first_def_inside_cf.get(slot_key, False)
        else None
    )
    if _birth_block is not None:
        with ir.InsertionPoint.at_block_begin(_birth_block):
            seed_ir = _emit_init()
        with ir.InsertionPoint.at_block_begin(entry_block):
            init_ir = _make_raw_placeholder_init(seed_ir.type)
            if init_ir is None:
                init_ir = _emit_init()
            ref = pyir.ref(init_ir)
        with ir.InsertionPoint.after(_get_defining_operation(seed_ir)):
            _pyir_emit_store(seed_ir, ref)
    else:
        with ir.InsertionPoint.at_block_begin(entry_block):
            initial_ir = _emit_init()
            ref = pyir.ref(initial_ir)
    _slot_refs[slot_key] = ref
    # F-TYPEID: the promotion declares the row's wrapper class; reads
    # reconstruct through it (a later staged store advances it).
    _pyir_record_slot_template(
        slot_key,
        _pyir_declared_promotion_template(initial_py_value, _staged_target_type),
    )

    # User-visible warning: a Python value just became staged-tracked; show target, value,
    # file:line so users can hoist the init out of CF.
    if target_name is not None:
        promoted_cls = _declared_m2s_promotion_class(initial_py_value)
        promoted_type = (
            promoted_cls.__name__
            if promoted_cls is not None
            else type(initial_py_value).__name__
        )
        # Stale-local risk: the slot is now a ``pyir.ref`` but the caller's Python binding still
        # holds the constexpr, so reads OUTSIDE this region fold the stale value.
        from .diagnostics import WarnId, report_warning

        report_warning(
            WarnId.PHASE_AUTO_PROMOTED_TO_STAGED,
            filename=filename,
            lineno=lineno,
            stacklevel=4,
            var=target_name,
            value=repr(initial_py_value),
            type=promoted_type,
        )

    # In-region first-def with no recorded birth block: seed before the earliest
    # baked use, which the follow-on rewrite turns into a dominated ``pyir.load``.
    if _slot_first_def_inside_cf.get(slot_key, False) and _birth_block is None:
        try:
            uses = _meta_uses.get(slot_key, [])
            if uses and not isinstance(uses[0].owner, ir.Block):
                owner_op = uses[0].owner
                defining_op = (
                    owner_op
                    if isinstance(owner_op, ir.Operation)
                    else getattr(owner_op, "operation", owner_op)
                )
                with ir.InsertionPoint(defining_op):
                    reset_ir = _emit_init()
                    _pyir_emit_store(reset_ir, ref)
        except Exception as exc:
            log().info(
                "[_meta_promote_slot] %s: reset-store insert failed: %s",
                slot_key,
                exc,
            )

    # Re-materialise idempotent writes the promotion gates skipped: each skip
    # left an anchor constant at its write site, and Python DID execute the
    # assignment there -- once the slot is a cell, every such site must reset
    # the cell (e.g. a body-top ``x = 128`` re-arms 128 each iteration even
    # after a later conditional write stored a different value).  Idempotence
    # guarantees every anchor's payload equals ``initial_py_value``, but the
    # anchor's own IR type may not match the ref pointee when the promotion
    # was triggered by a staged write (``_staged_target_type``), so the anchor
    # serves as the insertion position only and the stored value is re-emitted
    # through ``_emit_init`` at the ref's type; the anchor itself goes dead.
    for _anchor in _meta_idempotent_write_anchors.pop(slot_key, []):
        with ir.InsertionPoint.after(_get_defining_operation(_anchor)):
            _pyir_emit_store(_emit_init(), ref)

    # Rewrite baked uses to ``pyir.load %ref``, but ONLY those whose baked value
    # matches the ref init: an earlier-value use keeps its literal (else corrupted).
    _rewrite_recorded_meta_uses(slot_key, ref, initial_py_value)

    return ref


def _rewrite_recorded_meta_uses(
    slot_key: Any, ref: "ir.Value", initial_py_value: Any
) -> None:
    """Replace each baked constant under *slot_key* whose value matches
    *initial_py_value* with a position-correct ``pyir.load`` of *ref*."""
    for const_val in _meta_uses.pop(slot_key, []):
        try:
            owner = const_val.owner
            if isinstance(owner, ir.Block):
                continue  # block argument has no "before" insertion point
            baked_value = _const_value_of(const_val)
            if baked_value is not _NO_CONST_VALUE and not _const_values_equal(
                baked_value, initial_py_value
            ):
                log().info(
                    "[_rewrite_recorded_meta_uses] %s: keep literal %r (init=%r) -- "
                    "earlier-value baked use, not carried through ref",
                    slot_key,
                    baked_value,
                    initial_py_value,
                )
                continue
            defining_op = (
                owner
                if isinstance(owner, ir.Operation)
                else getattr(owner, "operation", owner)
            )
            with ir.InsertionPoint(defining_op):
                loaded = pyir.load(ref)
            if not _replace_value_uses(const_val, loaded):
                # A missing RAUW binding method is an environment defect that
                # silently degrades promotion (stale-literal reads); warn, not info.
                log().warning(
                    "[_rewrite_recorded_meta_uses] %s: replace_all_uses_with "
                    "missing on ir.Value",
                    slot_key,
                )
            else:
                # Record the rewrite so a cached materialisation of this constant
                # hands new consumers the load instead of the dead constant.
                try:
                    _META_CONST_REPLACEMENTS[const_val] = loaded
                except TypeError:
                    pass
        except Exception as exc:
            log().info(
                "[_rewrite_recorded_meta_uses] %s: replace failed: %s", slot_key, exc
            )


def _stage_compound_value(value: Any, seen: "set[int]") -> "tuple[Any, bool] | None":
    """Recursive worker for :func:`_stage_meta_compound_leaves`.

    Returns ``(staged_value, changed)``, or ``None`` when some leaf
    cannot be staged.  Compounds are rebuilt, never mutated in place:
    a pre-loop alias must keep the untouched original, as it would in
    plain Python."""
    from .multi_stage_manager import _is_staged_value
    from .pyir_call_boundary import _pyir_boundary_module_is_user

    if value is None or type(value) in (str, bytes):
        return (value, False)
    py = _pyir_unwrap_meta_primitive(value)
    if py is not None and type(py) in (bool, int, float):
        promoted = _auto_promote_primitive(py)
        return None if promoted is None else (promoted, True)
    if _is_staged_value(value):
        return (value, False)  # already staged: the carry engine handles it
    if _implements_dynamic_expression(value):
        # A value-protocol object carries through its own extract/reconstruct
        # pair: leave it alone, as the all-meta gate does.
        return (value, False)
    if id(value) in seen:
        return None  # cycle: no sound rebuild order
    if type(value) in (tuple, list, _WatchedList):
        if not value:
            return (value, False)  # empty: fixed structure, keep as-is
        seen.add(id(value))
        elems: "list[Any]" = []
        changed = False
        for elem in list.__iter__(value) if isinstance(value, list) else value:
            sub = _stage_compound_value(elem, seen)
            if sub is None:
                return None
            elems.append(sub[0])
            changed = changed or sub[1]
        if not changed:
            return (value, False)
        if isinstance(value, list):
            return (elems, True)  # staged replica is a plain list
        return (_rebuild_tuple_like(value, elems), True)
    if type(value) in (dict, _WatchedDict):
        if not value:
            return (value, False)
        seen.add(id(value))
        entries: "dict[Any, Any]" = {}
        changed = False
        for key, elem in dict.items(value):
            if _is_staged_value(key):
                return None  # keys are compile-time structure
            sub = _stage_compound_value(elem, seen)
            if sub is None:
                return None
            entries[key] = sub[0]
            changed = changed or sub[1]
        if not changed:
            return (value, False)
        return (entries, True)
    attrs = getattr(value, "__dict__", None)
    if (
        isinstance(attrs, dict)
        and attrs
        and _pyir_boundary_module_is_user(type(value).__module__)
    ):
        seen.add(id(value))
        staged_attrs: "dict[str, Any]" = {}
        changed = False
        for name, elem in attrs.items():
            sub = _stage_compound_value(elem, seen)
            if sub is None:
                return None
            staged_attrs[name] = sub[0]
            changed = changed or sub[1]
        if not changed:
            return (value, False)
        try:
            clone = object.__new__(type(value))
        except Exception:
            return None  # __new__ rejected: cannot clone this class
        for name, elem in staged_attrs.items():
            _pyir_setattr_raw(clone, name, elem)
        return (clone, True)
    return None


def _stage_meta_compound_leaves(value: Any) -> "Any | None":
    """Rebuild a meta compound (tuple, list, dict, or user-class object)
    with every bool/int/float leaf staged, so the per-leaf carry engine
    can thread the loop body's rebuilds.  Returns ``None`` when a leaf
    cannot be staged or nothing needed staging.  Tuple subclasses
    (namedtuple) are excluded: element reads spelled ``t.field`` bypass
    the element cells and would silently keep stale values."""
    result = _stage_compound_value(value, set())
    if result is None or not result[1]:
        return None
    return result[0]


def _pyir_snapshot_region_arg(arg: Any) -> "list[tuple[Any, str, ir.Value]] | None":
    """Snapshot *arg*'s in-place ``ir.Value`` leaf holders before a region body."""
    holders = _pyir_walk_ir_value_holders(arg)
    if holders:
        return holders
    # A TOP-LEVEL tuple/list of value-trees yields nothing from the value-tree
    # walk; snapshot the CONCATENATED element leaves with the tuple as holder.
    if _pyir_is_carryable_tuple(arg):
        leaves = _pyir_extract_any_leaf_values(arg)
        if leaves:
            return [(arg, _PYIR_TUPLE_LEAF_ATTR, lv) for lv in leaves]
    return _self_leaf_snapshot(arg)


# Region-kind wording for the shared carry core: (type-mismatch phrase,
# fail-loud wall label, carried-as phrase).
_CARRY_PHRASES = {
    "loop": ("re-derived per iteration", "loop leaf carry", "iter_arg"),
    "if": ("re-derived per branch", "scf.if leaf carry", "scf.if result"),
}


def _pyir_carry_region_mutated_leaves(
    arg: Any,
    snapshot: "list[tuple[Any, str, ir.Value]] | None",
    region_op: "ir.Operation",
    region_block: "ir.Block",
    context: str,
    *,
    kind: str,
    opaque_only: bool,
    skip_inner_loop_carried: bool,
    except_users_outside_region: bool,
    self_leaf_arg_index_only: bool,
    ref_cache: "dict[int, ir.Value] | None" = None,
    exclude_aliased_leaves: "list[ir.Value] | None" = None,
    arg_index: int = -1,
    arg_name: "str | None" = None,
) -> "list[tuple[Any, str, ir.Value, Any, int, int]]":
    """Shared core of the loop/if region-carry twins: pair each pre-region
    snapshot leaf with its current value, and carry every genuinely trapped
    update through a ``pyir.ref`` (region-entry load, region-scoped RAUW,
    region-exit store) so the C++ pass lifts it to an iter_arg / region
    result.  The wrappers fix the policy flags; every flag encodes a
    load-bearing semantic difference between the two regions -- see each
    wrapper's docstring."""
    phrase_mismatch, phrase_wall, phrase_carried = _CARRY_PHRASES[kind]
    records: "list[tuple[Any, Any, ir.Value, Any, int, int]]" = []
    if pyir is None or snapshot is None:
        return records
    # Pair each snapshot leaf with the region's current value (in-place: ``rebind_holder`` set; whole-object
    # rebind: ``reconstruct_obj`` + ``leaf_index`` let the caller reconstruct post-region from leaf loads).
    for (
        rebind_holder,
        attr_name,
        snap_value,
        cur_value,
        reconstruct_obj,
        leaf_index,
    ) in _pyir_resolve_loop_leaf_updates(arg, snapshot):
        # Trigger only on a genuine escaped update: snapshot defined OUTSIDE the region (dominates -> ref
        # anchor), new value trapped INSIDE -- it must carry forward here, not be reverted at outer scope.
        if not isinstance(cur_value, ir.Value) or cur_value is snap_value:
            continue
        if not isinstance(snap_value, ir.Value):
            continue
        if opaque_only and not _is_opaque_leaf_type(snap_value):
            # A scalar leaf is already carried by the M2S function-entry ref;
            # only an opaque leaf needs region-level carry. Avoid double-carry.
            continue
        if skip_inner_loop_carried and _pyir_value_is_inner_loop_carried(
            cur_value, region_op
        ):
            # ``scf.while``: this leaf is the post-close load of a ref a NESTED loop already carried; that
            # loop owns the carry. Avoid double-carry.
            continue
        # ALIASED-leaf exclusion (standalone ``scf.if``): skip a leaf whose pre-``if`` SSA is also held by a
        # captured free variable -- yielding it as an ``scf.if`` result would point aliases at a trapped load.
        if exclude_aliased_leaves is not None and any(
            _same_ir_value(snap_value, _al) for _al in exclude_aliased_leaves
        ):
            continue
        if _ir_value_defined_inside_op(snap_value, region_op):
            # Snapshot defined inside the region cannot anchor a pre-region ref (defensive: the snapshot
            # is taken at the outer scope).
            continue
        if not _ir_value_defined_inside_op(cur_value, region_op):
            # The mutation is a legitimate forward update defined outside the region -- nothing trapped.
            continue
        if cur_value.type != snap_value.type:
            # An scf iter_arg / region result is type-invariant by construction, so a leaf
            # rebound to a DIFFERENTLY-TYPED value cannot be carried.
            if _pyir_typed_update_is_advance(cur_value, [snap_value], region_op):
                _pyir_raise_type_changed_in_region(
                    attr_name, snap_value.type, cur_value.type
                )
            log().info(
                "[pyir %s] leaf '%s' rebound to a differently-typed value "
                "(%s -> %s); %s, not carried (%s)",
                kind,
                attr_name,
                snap_value.type,
                cur_value.type,
                phrase_mismatch,
                context,
            )
            continue
        # Leaves carry uniformly (all types); refuse only an update rooted at
        # an IN-REGION allocation (entry-hoisted: aliases one buffer) -- the
        # type-uniform escape judgment, same as the store choke.  An admitted
        # scratch handle (raw or re-loaded from the admitted slot) is neither
        # refused nor re-carried: the slot cell already promotes into the
        # carried phi, and the admission sweep owns its enforcement.
        if _pyir_scratch_value_admitted(cur_value, region_op):
            continue
        if _pyir_memref_alloc_rooted_inside_region(cur_value, region_op):
            _pyir_raise_memref_inregion_alloc_rebind(arg_name or attr_name)
        try:
            # 1. Ref acquisition (the ``scf.if`` caller shares one ref across
            #    both arms via *ref_cache*).
            ref = ref_cache.get(id(snap_value)) if ref_cache is not None else None
            if ref is None:
                place = _pyir_region_carry_place_for(rebind_holder, attr_name, arg_name)
                ref, _minted = _pyir_adopt_region_carry_ref(
                    place, snap_value, region_op
                )
                if ref is None:
                    continue
                if ref_cache is not None:
                    ref_cache[id(snap_value)] = ref
            # 2. Region-entry load. A ``pyir.load`` of an opaque type comes back WRAPPED in its value-tree
            #    class; normalise to the backing SSA for the RAUW (a bare leaf is a no-op).
            with ir.InsertionPoint.at_block_begin(region_block):
                loaded = _raw_backing_ir_value(pyir.load(ref))
            if loaded is None:
                continue
            # 3. Region-scoped rewrite of in-region uses of the pre-region leaf to the loaded value,
            #    except the ``pyir.ref`` op (keep its init) and the region op itself (its OWN operands --
            #    bounds/step/inits -- evaluate in the outer scope: rewriting a shared LB/UB SSA onto the
            #    load fails dominance).
            ref_op = _get_defining_operation(ref)
            load_op = _get_defining_operation(loaded)
            region_op_norm = getattr(region_op, "operation", region_op)
            exceptions = [ref_op]
            for use in snap_value.uses:
                user = getattr(use, "owner", None)
                if user is None:
                    continue
                user_op = getattr(user, "operation", user)
                if user_op == load_op:
                    continue  # the load itself was created with snap_value
                if user_op == region_op_norm:
                    exceptions.append(user_op)
                    continue
                if except_users_outside_region and not _op_is_inside_op(
                    user_op, region_op
                ):
                    exceptions.append(user_op)
                    continue
                # Except an in-region use the region-entry load does NOT dominate.
                if not _pyir_load_dominates_use(loaded, user_op):
                    exceptions.append(user_op)
            snap_value.replace_all_uses_except(loaded, exceptions)
            # 4. Region-exit store of the mutated leaf, emitted at the CURRENT
            #    IP (the region block end, traced, before the terminator).
            _pyir_emit_store(cur_value, ref)
        except Exception as exc:
            # Fail-loud wall: an un-carried mutated leaf silently pins every
            # post-region read to the trapped in-region value.
            raise DSLRuntimeError(
                f"PyIR emission self-check: {phrase_wall} failed for "
                f"value-tree leaf '{attr_name}' ({context}): {exc}"
            ) from exc
        # Record so the caller rebinds the carried value at the OUTER post-region IP (a
        # load emitted here would land inside the still-open region).  A
        # whole-object RECONSTRUCT record always keeps the caller's slot
        # index: an IMMUTABLE rebuilt compound (tuple/list) republishes into
        # the ``mix_iter_args`` slot ONLY through it (in-place copy is
        # impossible), and ``reconstruct_obj`` is always the top-level
        # binding, so the index names the right slot.
        if (
            self_leaf_arg_index_only
            and reconstruct_obj is None
            and not _is_self_leaf_record(rebind_holder, attr_name)
        ):
            rec_index = -1
        else:
            rec_index = arg_index
        records.append(
            (rebind_holder, attr_name, ref, reconstruct_obj, leaf_index, rec_index)
        )
        log().info(
            "[pyir %s] carried updated value-tree leaf '%s' as %s (%s)",
            kind,
            attr_name,
            phrase_carried,
            context,
        )

    # A STABLE memref leaf written in place needs NO record: its carry is
    # the backing memory, ordered by declared memory effects.
    return records


def _pyir_carry_loop_body_mutated_leaves(
    arg: Any,
    snapshot: "list[tuple[Any, str, ir.Value]] | None",
    loop_op: "ir.Operation",
    body_block: "ir.Block",
    context: str,
    *,
    opaque_only: bool = False,
    arg_index: int = -1,
    arg_name: "str | None" = None,
) -> "list[tuple[Any, str, ir.Value, Any, int, int]]":
    """Retroactively carry a value-tree compound's UPDATED raw ``ir.Value``
    leaves through a ``pyir.ref`` so the C++ pass lifts each to a loop
    iter_arg.  Loop policy over the shared core: scalar leaves carry too
    unless *opaque_only* (``scf.while``, which also skips leaves a nested
    loop already carried); users outside the loop op are excepted from the
    RAUW; only a SELF leaf or a whole-object RECONSTRUCT record keeps the
    caller's *arg_index* (an in-place attribute record never needs it)."""
    return _pyir_carry_region_mutated_leaves(
        arg,
        snapshot,
        loop_op,
        body_block,
        context,
        kind="loop",
        opaque_only=opaque_only,
        skip_inner_loop_carried=opaque_only,
        except_users_outside_region=True,
        self_leaf_arg_index_only=True,
        arg_index=arg_index,
        arg_name=arg_name,
    )


def _pyir_rebind_carried_leaves_post_loop(
    records: "list[tuple]",
) -> "dict[int, Any]":
    """Rebind each carried leaf to a dominating post-loop ``pyir.load %ref``."""
    if pyir is None:
        return {}
    # Group whole-object-rebind records by the object to reconstruct, tracking
    # each object's ``mix_iter_args`` slot (the last non-negative ``arg_index``).
    rebuilds: "dict[int, tuple[Any, dict[int, ir.Value], int]]" = {}
    # Self-leaf rebinds: ``{arg_index: loaded_dsl_value}`` -- slot re-pointed at the WRAPPED load.
    self_leaf_binds: "dict[int, Any]" = {}
    for record in records:
        holder, attr_name, ref, reconstruct_obj, leaf_index = record[:5]
        arg_index = record[5] if len(record) > 5 else -1
        # SELF-LEAF: keep the WRAPPED ``pyir.load`` as the new slot binding so a post-region DSL read
        # sees a proper typed value, not a bare SSA.
        if _is_self_leaf_record(holder, attr_name):
            try:
                loaded_wrapped = pyir.load(ref)
            except Exception as exc:
                # Fail-loud wall: a swallowed post-loop load failure would
                # silently leave the slot bound to the trapped in-loop value.
                raise DSLRuntimeError(
                    "PyIR emission self-check: post-loop reload failed for "
                    f"the self-leaf slot '{attr_name}': {exc}"
                ) from exc
            if loaded_wrapped is not None and arg_index >= 0:
                self_leaf_binds[arg_index] = loaded_wrapped
            continue
        try:
            # ``pyir.load`` of an opaque type comes back WRAPPED (``_Tensor`` /
            # ``_Pointer``); normalise to the backing SSA before rebinding.
            loaded = _as_arith_capable_scalar_leaf(
                _raw_backing_ir_value(pyir.load(ref))
            )
            if loaded is None:
                continue
            if reconstruct_obj is None:
                _pyir_setattr_raw(holder, attr_name, loaded)
            else:
                key = id(reconstruct_obj)
                _obj, leaves, ai = rebuilds.setdefault(
                    key, (reconstruct_obj, {}, arg_index)
                )
                leaves[leaf_index] = loaded
                if arg_index >= 0 and ai < 0:
                    rebuilds[key] = (_obj, leaves, arg_index)
        except Exception as exc:
            # Fail-loud wall: a swallowed store-back rebind failure would
            # silently drop this leaf's carry (post-loop reads go stale).
            raise DSLRuntimeError(
                "PyIR emission self-check: post-loop leaf rebind failed for "
                f"attribute '{attr_name}': {exc}"
            ) from exc
    # Reconstruct each whole-object-rebound compound from its loaded canonical
    # leaves and copy the rebuilt state in place.
    arg_index_to_obj: "dict[int, Any]" = {}
    for obj, leaves, arg_index in rebuilds.values():
        try:
            cur_leaves = _pyir_extract_any_leaf_values(obj)
            if cur_leaves is None:
                continue
            # Substitute the carried leaves at their extract positions; any leaf
            # the loop did not change keeps its current value.
            new_vals = list(cur_leaves)
            for li, lv in leaves.items():
                if 0 <= li < len(new_vals):
                    new_vals[li] = lv
            rebuilt = _pyir_new_from_mlir_values_any(obj, new_vals)
            if rebuilt is None:
                continue
            if _pyir_is_carryable_tuple(obj):
                # A tuple/list is IMMUTABLE -- it cannot be copied in place.
                if arg_index >= 0:
                    arg_index_to_obj[arg_index] = rebuilt
                continue
            # Copy the rebuilt instance state into ``obj`` so every alias observes
            # the re-derived (carried) leaves.
            for k, v in list(vars(rebuilt).items()):
                _pyir_setattr_raw(obj, k, v)
            if arg_index >= 0:
                arg_index_to_obj[arg_index] = obj
        except Exception as exc:
            # Fail-loud wall: a swallowed reconstruct failure would silently
            # leave every alias of the compound on its pre-loop leaves.
            raise DSLRuntimeError(
                "PyIR emission self-check: post-loop compound reconstruct "
                f"failed for a {type(obj).__name__} instance: {exc}"
            ) from exc
    # Self-leaf rebinds re-point their slots too (the loaded wrapped value IS the new binding).
    arg_index_to_obj.update(self_leaf_binds)
    return arg_index_to_obj


def _pyir_rebind_local_place_cells_post_region(
    mix_iter_args: "list",
    mix_iter_arg_names: "list[str]",
    op: "ir.Operation",
) -> None:
    """Post-region rebind FROM the ledger cell (clause A, read half)."""
    if pyir is None:
        return
    for idx in range(min(len(mix_iter_args), len(mix_iter_arg_names))):
        try:
            place = _pyir_local_place_for_name(mix_iter_arg_names[idx])
            if place is None:
                continue
            ref = _slot_refs.get(place)
            if ref is None:
                continue
            try:
                pointee = ref.type.pointee
            except Exception:
                continue
            # OPAQUE pointees only -- scalar places are owned by D1/M2S.
            if not _pyir_ir_type_is_opaque(pointee):
                continue
            if not _value_dominates_current_ip(ref):
                continue
            if not _pyir_slot_stored_in_body(ref, op):
                continue
            # Already the cell's dominating load -> nothing to do.
            cur_raw = _raw_backing_ir_value(mix_iter_args[idx])
            if isinstance(cur_raw, ir.Value):
                cur_owner = getattr(cur_raw, "owner", None)
                if cur_owner is not None and not isinstance(cur_owner, ir.Block):
                    cur_op = getattr(cur_owner, "operation", cur_owner)
                    if (
                        str(getattr(cur_op, "name", "")) == "pyir.load"
                        and _same_ir_value(cur_op.operands[0], ref)
                        and _value_dominates_current_ip(cur_raw)
                    ):
                        continue
            loaded = pyir.load(ref)
            if loaded is None:
                continue
            mix_iter_args[idx] = loaded
            log().info(
                "[pyir %s] post-region rebind of local '%s' from its place cell",
                getattr(getattr(op, "operation", op), "name", "region"),
                mix_iter_arg_names[idx],
            )
        except Exception:
            continue


def _pyir_rebind_unstored_scalar_carries_post_loop(
    records: "list[tuple[Any, str, MutableValue]]",
) -> None:
    """Rebind each stored-back scalar carry to a dominating post-loop ``pyir.load``."""
    if pyir is None:
        return
    for holder, attr_name, mv in records:
        try:
            # Row-authoritative reload: reconstruct from the store-time template.
            loaded = mv.load()
            _attach_mutable_ref(loaded, mv, f"post-loop carry rebind '{attr_name}'")
            _pyir_setattr_raw(holder, attr_name, loaded)
        except Exception:
            continue


def _pyir_store_back_unstored_slot_carries_sweep(
    loop_op: "ir.Operation",
    body_block: "ir.Block",
    context: str,
) -> "list[tuple[Any, str, MutableValue]]":
    """Region-close store-back driven by the central slot-holder registry."""
    records: "list[tuple[Any, str, MutableValue]]" = []
    if pyir is None:
        return records
    # Id-keyed registry entries are a ``weakref.ref`` or the holder itself
    # (non-weakrefable ``__slots__`` class held strongly for the trace).
    for entry in list(_PYIR_SLOT_HOLDERS.values()):
        holder = entry() if isinstance(entry, _weakref.ref) else entry
        if holder is None:
            continue
        for slot_name, mv in _iter_owner_slot_mvs(holder):
            # Direct attribute slots only: a composite key (``_PlaceSeg``) is
            # a value-tree element, not a ``getattr``-able attribute.
            if not isinstance(slot_name, str):
                continue
            try:
                cur_value = getattr(holder, slot_name)
            except AttributeError:
                continue
            # Only a numeric scalar leaf advances via the un-instrumented shape; an
            # opaque leaf carries through _pyir_carry_loop_body_mutated_leaves.
            if not _is_numeric_leaf_holder(cur_value):
                continue
            # A value carrying a load version is a fresh ``pyir.load`` refresh of the
            # slot (set by MutableValue.load), not a mutation -- storing it back would
            if getattr(cur_value, _PYIR_LOAD_VERSION_ATTR, None) is not None:
                continue
            # The row's own published representative, still unchanged in
            # storage, is a declared non-mutation: the cell was minted from
            # this very value at the publish choke, so there is no
            # un-instrumented advance to store back (and its raw may be
            # region-interior -- a body-exit store would serve SSA outside
            # its defining region).
            if getattr(cur_value, "_pyir_publish_representative_of", None) is mv:
                continue
            # The advanced value must be a fresh SSA defined inside the loop body. A
            # read-only carried object keeps its pre-loop SSA (defined outside).
            cur_raw = _raw_backing_ir_value(cur_value)
            if cur_raw is None or not _ir_value_defined_inside_op(cur_raw, loop_op):
                continue
            # Unify onto the EXISTING slot ref the body loads from -- never mint a
            # competing ref.
            if mv is None or not mv._is_ref_accessible():
                continue
            ref = mv.ref
            if not isinstance(ref, ir.Value):
                continue
            if _ir_value_defined_inside_op(ref, loop_op):
                continue  # an in-body lazily-created ref cannot anchor a pre-loop carry
            if not _pyir_ref_loaded_inside_op(ref, loop_op):
                continue  # never read in-body -> not a genuine carry, leave it alone
            if _pyir_slot_stored_in_body(ref, loop_op):
                continue  # instrumented mutator already stores -> no-op
            if _pyir_ref_pointee_type_changed(ref, cur_value):
                # An scf iter_arg is type-invariant: a slot rebound to a DIFFERENTLY-
                # TYPED value cannot be stored back.
                _ref_loads = []
                try:
                    for _use in ref.uses:
                        _user = getattr(_use, "owner", None)
                        if _user is None:
                            continue
                        _user_op = getattr(_user, "operation", _user)
                        if getattr(
                            _user_op, "name", None
                        ) == "pyir.load" and _op_is_inside_op(_user_op, loop_op):
                            _ref_loads.extend(list(_user_op.results))
                except Exception:
                    # An unwalkable use list is UNKNOWN: refuse loudly rather
                    # than silently skip the carry.
                    _pyir_raise_type_changed_in_region(slot_name, None, cur_raw.type)
                if _pyir_typed_update_is_advance(cur_raw, _ref_loads, loop_op):
                    _old_t = None
                    try:
                        _old_t = ref.type.pointee
                    except Exception:
                        pass
                    _pyir_raise_type_changed_in_region(slot_name, _old_t, cur_raw.type)
                continue
            # Wrapper-half leg comparison (V-4): over ONE MLIR type, an advance
            # that changed the wrapper class has no Python join type -- a
            # post-region read cannot reconstruct one consistent value.
            if not _types_match(mv._value, cur_value) and not (
                isinstance(cur_value, type(mv._value))
                or isinstance(mv._value, type(cur_value))
            ):
                raise DSLUserCodeError(
                    DiagId.WRAPPER_CLASS_MERGE,
                    var=str(slot_name),
                    old_cls=type(mv._value).__name__,
                    new_cls=type(cur_value).__name__,
                )
            try:
                # Body-exit store of the advanced scalar (the iter_arg yield);
                # at the body-block end the store dominates the yield point.
                _pyir_emit_store(cur_raw, ref)
            except Exception as exc:
                log().info(
                    "[pyir loop] registry-sweep slot store-back emit failed: %s", exc
                )
                continue
            records.append((holder, slot_name, mv))
            log().info(
                "[pyir loop] stored un-instrumented numeric-slot advance '%s' back "
                "into its existing slot ref as a loop iter_arg via registry sweep (%s)",
                slot_name,
                context,
            )
    return records


def _pyir_carry_if_region_mutated_leaves(
    arg: Any,
    snapshot: "list[tuple[Any, str, ir.Value]] | None",
    if_op: "ir.Operation",
    region_block: "ir.Block",
    ref_cache: "dict[int, ir.Value]",
    context: str,
    arg_index: int = -1,
    exclude_aliased_leaves: "list[ir.Value] | None" = None,
    arg_name: "str | None" = None,
) -> "list[tuple[Any, str, ir.Value, Any, int, int]]":
    """Carry an ``scf.if`` branch's in-place-MUTATED value-tree leaf forward
    as an ``scf.if`` result -- the read-side companion of the loop carry.
    If policy over the shared core: OPAQUE leaves only (a scalar leaf is
    already carried by the M2S function-entry slot); leaves aliased by a
    captured free variable are excluded (*exclude_aliased_leaves*); both
    arms share one ref per pre-``if`` SSA via *ref_cache*; every record
    keeps the caller's *arg_index*."""
    return _pyir_carry_region_mutated_leaves(
        arg,
        snapshot,
        if_op,
        region_block,
        context,
        kind="if",
        opaque_only=True,
        skip_inner_loop_carried=False,
        except_users_outside_region=False,
        self_leaf_arg_index_only=False,
        ref_cache=ref_cache,
        exclude_aliased_leaves=exclude_aliased_leaves,
        arg_index=arg_index,
        arg_name=arg_name,
    )


def _pyir_snapshot_region_meta(arg: Any) -> "list[tuple[Any, str, Any]] | None":
    """Snapshot *arg*'s meta-scalar leaf holders before a region body."""
    holders = _pyir_walk_meta_holders(arg)
    return holders if holders else None


def _pyir_snapshot_meta_numeric_leaves(
    arg: Any,
) -> "list[tuple[Any, str, Any]] | None":
    """Snapshot *arg*'s parent-level META Numeric leaf holders before a region. Consumed
    by :func:`_pyir_restore_meta_numeric_leaves`."""
    holders = _walk_meta_numeric_leaf_holders(arg)
    return holders if holders else None


def _pyir_loop_carried_meta_needs_rebind(
    value: Any, ref: "ir.Value", loop_op: "ir.Operation"
) -> bool:
    """Return True for a loop-carried META scalar whose slot the body STORED into."""
    if pyir is None:
        return False
    try:
        if not isinstance(value, _WatchedM):
            return False
        if not isinstance(ref, ir.Value):
            return False
        return _pyir_slot_stored_in_body(ref, loop_op)
    except Exception:
        return False


def _ensure_leaf_ref_no_load(
    owner: Any, slot_name: Any, leaf: Any, context: str
) -> Any:
    """Ensure a staged leaf has a ``pyir.ref`` slot under ``(owner, slot_name)``
    without emitting a load (the single load is deferred to the consumer)."""
    if not (_is_staged_value(leaf) and _can_carry_leaf_ref(leaf)):
        return leaf
    existing = _get_slot_mv(owner, slot_name)
    if existing is not None and existing._is_ref_accessible():
        return leaf  # already carried via a registered slot
    if _pyir_value_tracked_by_accessible_ref(leaf):
        return leaf  # already carried via the leaf's _mutable_ref
    try:
        leaf = _fresh_wrapper(leaf)
        mv = _create_ref(leaf)
        mv = _set_slot_mv(owner, slot_name, mv)
        _attach_mutable_ref(leaf, mv, f"while-carried leaf '{context}'")
    except Exception as exc:
        # Fail-loud wall: a swallowed slot-creation failure would silently
        # drop this leaf's carry (reads bake the stale pre-loop value).
        raise DSLRuntimeError(
            "PyIR emission self-check: slot creation failed for the "
            f"while-carried leaf '{context}' (slot {slot_name!r}): {exc}"
        ) from exc
    return leaf


def _promote_tuple_leaf_refs(
    owner: Any,
    slot_name: Any,
    t: tuple,
    context: str,
) -> tuple:
    """Ensure the staged leaves of a tuple have ``pyir.ref`` slots (no load), under
    ``_decompose_tuple``'s slot keys; rebuilds through the tuple's own subtype."""
    result: list = []
    for i, elem in enumerate(t):
        elem_slot = _place_seg_child(slot_name, i) if slot_name is not None else None
        if _is_staged_value(elem) and _can_carry_leaf_ref(elem):
            result.append(
                _ensure_leaf_ref_no_load(owner, elem_slot, elem, f"{context}[{i}]")
            )
        elif isinstance(elem, tuple):
            result.append(
                _promote_tuple_leaf_refs(owner, elem_slot, elem, f"{context}[{i}]")
            )
        else:
            result.append(elem)
    return _rebuild_tuple_like(t, result)


def _promote_compound_leaf_refs(
    obj: object, context: str, _visited: "set[int] | None" = None
) -> bool:
    """Materialise ``pyir.ref`` slots at the FIRST READ of a loop-carried value-tree
    compound so each staged leaf carries as an iter_arg (mutates *obj* in place)."""
    if pyir is None or not is_inside_staged_cf():
        return False
    # Break cycles in the value-tree object graph (a nested field reaching back
    # to an ancestor). Re-promoting an already-visited object is a no-op.
    if _visited is None:
        _visited = set()
    if id(obj) in _visited:
        return False
    _visited.add(id(obj))
    if not _implements_dynamic_expression(obj) or not _has_instance_storage(obj):
        return False
    if not _pyir_plain_storage_setattr(type(obj)):
        return False
    # Gate on "has any staged content", not "all fields decomposable": non-carryable
    # fields are left for the value-tree reconstruct, carryable leaves still promote.
    if not _has_any_staged_content(obj):
        return False

    promoted_any = False
    for attr_name in _get_instance_attrs(obj):
        value = getattr(obj, attr_name)
        if _is_staged_value(value) and _can_carry_leaf_ref(value):
            # Ensure the leaf has a ``pyir.ref`` slot without a load, keyed on
            # ``(obj, attr_name)`` so the bottom-of-body decompose reuses it.
            fresh = _ensure_leaf_ref_no_load(
                obj, attr_name, value, f"{context}.{attr_name}"
            )
            if fresh is not value:
                try:
                    _pyir_setattr_raw(obj, attr_name, fresh)
                    promoted_any = True
                except (AttributeError, TypeError):
                    pass
        elif isinstance(value, tuple):
            # Only touch tuples carrying a staged leaf; a pure meta tuple
            # (shapes/strides) must stay constant.
            if any(
                _is_staged_value(e) and _can_carry_leaf_ref(e)
                for e in _flatten_tuple(value)
            ):
                new_tuple = _promote_tuple_leaf_refs(
                    obj, attr_name, value, f"{context}.{attr_name}"
                )
                try:
                    _pyir_setattr_raw(obj, attr_name, new_tuple)
                    promoted_any = True
                except (AttributeError, TypeError):
                    pass
        elif (
            _has_instance_storage(value)
            and not _is_staged_value(value)
            and not isinstance(value, (int, float, bool, str, bytes, type))
            and _implements_dynamic_expression(value)
            and _has_decomposable_staged_fields(value)
        ):
            if _promote_compound_leaf_refs(value, f"{context}.{attr_name}", _visited):
                promoted_any = True
    if promoted_any:
        log().info("[pyir] promoted value-tree leaves for %s", context)
    return promoted_any


# Static export surface (regenerate with scripts/gen_pyir_all.py): the
# module's OWN names -- its namespace minus what lower chain modules
# already export and minus the generator's INTERNAL_ONLY registry.
__all__ = [
    "_pyir_push_loop_body_scope",
    "_pyir_pop_loop_body_scope",
    "_meta_promote_slot",
    "_stage_compound_value",
    "_stage_meta_compound_leaves",
    "_pyir_snapshot_region_arg",
    "_pyir_carry_loop_body_mutated_leaves",
    "_pyir_rebind_carried_leaves_post_loop",
    "_pyir_rebind_local_place_cells_post_region",
    "_pyir_rebind_unstored_scalar_carries_post_loop",
    "_pyir_store_back_unstored_slot_carries_sweep",
    "_pyir_carry_if_region_mutated_leaves",
    "_pyir_snapshot_region_meta",
    "_pyir_snapshot_meta_numeric_leaves",
    "_pyir_loop_carried_meta_needs_rebind",
    "_ensure_leaf_ref_no_load",
    "_promote_compound_leaf_refs",
]
