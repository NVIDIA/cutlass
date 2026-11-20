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


def _pyir_const_int_operand(value: Any) -> "int | None":
    """The integer an ``arith.constant`` defines for *value*; ``None`` for any
    other producer (a block argument, a computed value)."""
    try:
        owner = value.owner
        if owner is None or isinstance(owner, ir.Block):
            return None
        op = getattr(owner, "operation", owner)
        if op.name != "arith.constant":
            return None
        return ir.IntegerAttr(op.attributes["value"]).value
    except Exception:
        return None


def _pyir_loop_guaranteed_trip(loop_op: Any, kind: str) -> bool:
    """True when the staged loop body provably runs at least once: an
    ``scf.for`` carrying ``at_least_once``, or one whose lower bound, upper
    bound and step are all ``arith.constant`` with a trip count >= 1.  An
    ``scf.while`` may always run zero times."""
    if kind != "for" or loop_op is None:
        return False
    try:
        op = getattr(loop_op, "operation", loop_op)
        if "at_least_once" in op.attributes:
            return True
        operands = list(op.operands)
    except Exception:
        return False
    if len(operands) < 3:
        return False
    lb, ub, step = (_pyir_const_int_operand(v) for v in operands[:3])
    if lb is None or ub is None or step is None or step == 0:
        return False
    if step > 0:
        return (ub - lb + step - 1) // step >= 1
    return (lb - ub - step - 1) // -step >= 1


def _pyir_push_loop_body_scope(
    body_block: "ir.Block",
    loop_op: Any = None,
    kind: str = "for",
    dead_on_entry: "Iterable[tuple[str, int]] | None" = None,
) -> None:
    """Declare *body_block* as the innermost open staged-loop body (F-BIRTHPOS);
    a body-region entry is a region-epoch boundary (F-GEN).

    Also pushes the body's trace-time facts (``_pyir_open_loop_body_facts``):
    the loop *kind*, whether *loop_op* provably runs at least once, and the
    preprocessor's *dead_on_entry* ``(path, line)`` pairs."""
    _pyir_bump_region_epoch()
    _pyir_region_entry_push()
    _pyir_open_loop_body_blocks.append(body_block)
    _pyir_open_loop_body_facts.append(
        {
            "kind": kind,
            "guaranteed_trip": _pyir_loop_guaranteed_trip(loop_op, kind),
            "dead_on_entry": dict(dead_on_entry or ()),
            "entry": _pyir_region_entry_watermark(),
        }
    )
    _pyir_stmt_rebind_reset()
    # The loop's meta-leaf audit (opened with its entry snapshot) judges
    # places born in this body as re-executing with it.
    _pyir_meta_leaf_audit_attach_block(body_block)


def _pyir_pop_loop_body_scope() -> None:
    """Close the innermost open loop-body declaration (a region-epoch boundary)."""
    _pyir_bump_region_epoch()
    facts = _pyir_open_loop_body_facts[-1] if _pyir_open_loop_body_facts else None
    _pyir_region_entry_pop(
        guaranteed=bool(
            facts is not None
            and facts["entry"] == _pyir_region_entry_watermark()
            and facts["guaranteed_trip"]
        )
    )
    if _pyir_open_loop_body_blocks:
        _pyir_open_loop_body_blocks.pop()
    if _pyir_open_loop_body_facts:
        _pyir_open_loop_body_facts.pop()
    _pyir_stmt_rebind_reset()
    # An opaque read is a hazard only while a loop that re-runs it is open:
    # once the outermost loop closes, a place that never promoted kept its
    # exact bake, and a later promotion cannot re-run the read.
    if not _pyir_open_loop_body_blocks:
        _PYIR_BOUNDARY_OPAQUE_ATTR_READS.clear()


def _meta_promote_slot(
    slot_key: Any,
    initial_py_value: Any,
    target_name: str | None = None,
    filename: str | None = None,
    lineno: int | None = None,
    promoted_value: Any = None,
    display_name: str | None = None,
    already_staged: bool = False,
) -> "ir.Value | None":
    """Promote a slot to D1 tracking (AUTO_M2S only; refuses when the flag
    is off -- ``PHASE_AUTO_PROMOTE_DISABLED``).  *already_staged* marks a
    cell for a value that is ALREADY runtime (a literal-backed staged scalar):
    no Python value is promoted, so neither the mode gate nor the promotion
    warning applies.

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
    if not is_auto_m2s_enabled() and not already_staged:
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

    # This place was reachable by a plain callee inside an open loop body that
    # may read it, and no wrapper arm witnessed the read: the callee consumed
    # the payload through an operation with no retargetable constant (a float
    # or bool left operand, a C-level builtin), so the promotion cannot make
    # its value follow the carried cell -- refuse loudly.
    _opaque_read = _PYIR_BOUNDARY_OPAQUE_ATTR_READS.get(slot_key)
    if _opaque_read is not None:
        _or_callee, _or_file, _or_line = _opaque_read
        raise DSLUserCodeError(
            DiagId.PHASE_OPAQUE_READ_THEN_PROMOTED,
            filename=filename,
            lineno=lineno,
            var=target_name or display_name or str(slot_key),
            reader=(
                f"the plain, non-jit function `{_or_callee}` "
                f"(defined at {_or_file}:{_or_line})"
            ),
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
    # An attribute first-def inside a staged body records its birth only in
    # the region-birth ledger (``pyir_note_attr_first_def``), not in the
    # first-def tables above.  A place born in a loop body that is still open
    # around this promotion, at a binding position that dominates this
    # write, re-runs its binding on every execution of the write, so
    # it is a per-iteration reset, not a carry: seed it at the birth block
    # like any other region-born place instead of hoisting the seed to the
    # entry block.  Two facts keep the entry-seeded carry: an explicit
    # ``False`` in ``_slot_first_def_inside_cf`` (a discharged birth: a
    # latched once-per-key gate, or a plain-callee first-def of unprovable
    # multiplicity), and a birth position that does not dominate the write
    # (the binding sat under a folded constant-if arm or a region arm the
    # write is not under, e.g. a membership-gated once-per-key init, which
    # Python does not re-run every iteration).
    if _birth_block is None and slot_key not in _slot_first_def_inside_cf:
        _birth_path = _slot_region_birth_path.get(slot_key)
        if (
            _birth_path is not None
            and _pyir_arm_path_covers(_birth_path[0], _pyir_current_region_arm_path())
            and _pyir_arm_path_covers(_birth_path[1], tuple(_PYIR_FOLDED_IF_PATH))
            and _pyir_place_is_region_born(slot_key)
        ):
            _birth_block = _slot_region_birth_block.get(slot_key)
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
    _warn_name = target_name or display_name
    if _warn_name is not None and not already_staged:
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
            var=_warn_name,
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
    from .pyir_callee_rewrite import _pyir_boundary_module_is_user

    if value is None or type(value) in (str, bytes):
        return (value, False)
    py = _pyir_unwrap_meta_primitive(value)
    if py is not None and type(py) in (bool, int, float):
        promoted = _auto_promote_primitive(py)
        if (
            promoted is not None
            and isinstance(value, _WatchedM)
            and value._pyir_src_pairs()
        ):
            # A DERIVED watched leaf (``old.x + 1`` computed by a plain
            # callee) carries the IR of its derivation.  Staging its payload
            # as a fresh constant would bake the trace-time value: the source
            # place's later promotion rewrites recorded constant reads to
            # loads, never a constant minted here.
            try:
                promoted = _wrap_ir_like(promoted, value.ir_value())
            except (DSLUserCodeError, DSLRuntimeError):
                raise  # a typed diagnostic reaches the author as itself
            except Exception:
                return None
        return None if promoted is None else (promoted, True)
    if _is_staged_value(value):
        return (value, False)  # already staged: the carry engine handles it
    if _implements_dynamic_expression(value) and not _pyir_meta_state_value_tree(value):
        # A value-protocol object with staged leaves carries through its own
        # extract/reconstruct pair: leave it alone, as the all-meta gate does.
        # One holding only meta leaves has nothing that pair can carry, so its
        # fields stage below like a plain compound's.
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
        return (_rebuild_tuple_like(value, elems, region_carry=True), True)
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


def _pyir_structure_kind(value: Any) -> str:
    """``tuple`` or ``list`` for a sequence container; an adopted (watched)
    list is the list it wraps, and a region result rebuilt from IR values is
    a plain list, so the wrapper class is not part of the shape."""
    return "tuple" if isinstance(value, tuple) else "list"


def _pyir_structure_signature(value: Any) -> Any:
    """Container shape of *value* for the region join check: a tuple/list is
    ``(kind, arity, element shapes)``; everything else is one leaf.
    Only the shape is judged here -- compiled types are the type rules' job."""
    if isinstance(value, (tuple, list)):
        return (
            _pyir_structure_kind(value),
            len(value),
            tuple(_pyir_structure_signature(e) for e in value),
        )
    return "leaf"


def _pyir_structure_desc(value: Any) -> str:
    """Human-readable shape of *value* for the join diagnostic."""
    if isinstance(value, (tuple, list)):
        return f"{_pyir_structure_kind(value)}<{len(value)}>"
    return type(value).__name__


def _pyir_verify_region_structure(
    entry_value: Any, exit_value: Any, name: Any, op_type_name: str
) -> None:
    """Refuse a write-arg whose container shape at a region's exit differs
    from its shape at entry.  Every region result joins with the entry value
    (the untaken arm, the zero-trip loop, the back-edge), so a shape that
    differs is branch-dependent structure no single trace-time binding can
    represent; whichever arm traced last would be served on every path.

    A ``None`` entry is a binding born inside the region (no join partner);
    a ``None`` exit is a slot the arm did not rebind."""
    if entry_value is None or exit_value is None or entry_value is exit_value:
        return
    if _pyir_structure_signature(entry_value) == _pyir_structure_signature(exit_value):
        return
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.CONTAINER_STRUCTURE_CHANGED,
        filename=filename,
        lineno=lineno,
        var=str(name) if name is not None else "<value>",
        op_type=op_type_name,
        detail=(
            f" (was {_pyir_structure_desc(entry_value)}, "
            f"now {_pyir_structure_desc(exit_value)})"
        ),
    )


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
        # One cell per place: a bare-local write_arg whose place row already
        # carries this update (the update IS a load of, or a store into, that
        # row) was celled at body entry / by the write choke, and its reads
        # load the row.  A second anonymous cell would RAUW every in-region
        # use of the pre-region SSA -- including reads of an ALIAS bound to
        # the same handle, which must keep the entry value.
        if _pyir_local_place_row_carries(arg_name, cur_value, region_op):
            continue
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
            (
                rebind_holder,
                attr_name,
                ref,
                reconstruct_obj,
                leaf_index,
                rec_index,
                snap_owner if reconstruct_obj is not None else None,
            )
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
    rebuilds: "dict[int, tuple[Any, dict[int, ir.Value], int, Any]]" = {}
    # Self-leaf rebinds: ``{arg_index: loaded_dsl_value}`` -- slot re-pointed at the WRAPPED load.
    self_leaf_binds: "dict[int, Any]" = {}
    for record in records:
        holder, attr_name, ref, reconstruct_obj, leaf_index = record[:5]
        arg_index = record[5] if len(record) > 5 else -1
        alias_owner = record[6] if len(record) > 6 else None
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
                _obj, leaves, ai, owner = rebuilds.setdefault(
                    key, (reconstruct_obj, {}, arg_index, alias_owner)
                )
                leaves[leaf_index] = loaded
                if arg_index >= 0 and ai < 0:
                    rebuilds[key] = (_obj, leaves, arg_index, owner)
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
    for obj, leaves, arg_index, alias_owner in rebuilds.values():
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
            # the re-derived (carried) leaves.  A generated region binding may be
            # a reconstructed twin of the pre-region owner; update that owner too.
            targets = [obj]
            if (
                alias_owner is not None
                and alias_owner is not obj
                and _pyir_same_container_structure(alias_owner, obj)
            ):
                targets.append(alias_owner)
            for target in targets:
                for k, v in list(vars(rebuilt).items()):
                    _pyir_setattr_raw(target, k, v)
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


def _pyir_rematerialize_escaped_tuple_local(
    arg: Any,
    name: "str | None",
    region_op: "ir.Operation",
    context: str,
) -> Any:
    """Post-region re-materialisation of a TUPLE-valued local, per element
    (clause A, read half, for the elements): every staged element whose
    backing SSA was born inside the just-closed *region_op* is re-sourced from
    its element ledger cell (``name[i]``, the ``_decompose_tuple`` spelling)
    through a dominating ``pyir.load``, and the tuple is rebuilt through its
    own subtype (a namedtuple keeps its fields).  Post-region element reads
    are plain subscripts / field accessors and take no read choke, so the
    binding itself must dominate.

    Why the whole-object carry does not cover this: a NESTED region's exit
    rebinds the enclosing body's tuple to loads emitted INSIDE that body, so
    at the enclosing loop's close the tuple's leaves are already loads of the
    (pre-loop) element cells and the carry records nothing for them.  A
    scalar local survives through the read choke's dominance reload and a
    holder attribute through the stale-leaf sweep; a tuple local had neither.
    Structural, not syntactic: it does not matter which nested region
    produced the rebind.

    An escaped element with NO cell at all is a body-born binding read after
    the region (refused with the body-born code); a cell that does not
    dominate is an internal invariant violation and fails loudly here rather
    than at ``module.verify()``.
    """
    if pyir is None or not isinstance(arg, tuple) or not arg:
        return arg
    if not isinstance(name, str) or not name:
        return arg
    new_elems: "list[Any]" = []
    changed = False
    for i, elem in enumerate(arg):
        elem_name = f"{name}[{i}]"
        if isinstance(elem, tuple):
            new = _pyir_rematerialize_escaped_tuple_local(
                elem, elem_name, region_op, context
            )
            changed = changed or new is not elem
            new_elems.append(new)
            continue
        raw = _raw_backing_ir_value(elem) if _is_staged_value(elem) else None
        if raw is None or not _ir_value_defined_inside_op(raw, region_op):
            new_elems.append(elem)
            continue
        if not _can_carry_leaf_ref(elem):
            new_elems.append(elem)
            continue
        # Escaped element: born inside the closed region, read after it.  The
        # element cell is the place-registry row ``_decompose_tuple`` /
        # ``pyir_read`` publish under the ``name[i]`` local key; the published
        # D1 slot table is the fallback; the escaped value's own attached
        # ref is never followed (the ledger row is authoritative).
        place = _pyir_local_place_for_name(elem_name)
        mv = _PLACE_REGISTRY.get(place) if place is not None else None
        if mv is not None and not mv._is_ref_accessible():
            mv = None
        ref = _slot_refs.get(place) if (mv is None and place is not None) else None
        if mv is None and ref is None:
            if place is None:
                # No trackable local place here (constexpr unroll): leave the
                # binding to the existing repair paths.
                new_elems.append(elem)
                continue
            raise DSLUserCodeError(DiagId.BODY_BORN_SEED_UNPLACEABLE, var=elem_name)
        if ref is not None and not _value_dominates_current_ip(ref):
            raise DSLRuntimeError(
                "PyIR emission self-check: the ledger cell of tuple element "
                f"'{elem_name}' does not dominate the exit of the closed "
                f"{context}, so the element cannot be re-materialised"
            )
        if mv is not None:
            fresh = mv.load()
            _attach_mutable_ref(fresh, mv, f"{context} tuple element {elem_name}")
        else:
            fresh = _load_as_dsl(ref, place=place)
        if fresh is None:
            raise DSLRuntimeError(
                "PyIR emission self-check: post-region reload of tuple element "
                f"'{elem_name}' failed ({context})"
            )
        new_elems.append(fresh)
        changed = True
        log().info(
            "[pyir region] re-materialised escaped tuple element '%s' from its "
            "ledger cell (%s)",
            elem_name,
            context,
        )
    if not changed:
        return arg
    return _rebuild_tuple_like(arg, new_elems, region_carry=True)


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


def _pyir_snapshot_region_entry_compounds(
    roots: "list[Any]",
) -> "list[Any]":
    """The compound user objects reachable at a staged-region entry that have
    NO candidate-holder registry row: the region's live-in *roots*, the
    traced function's live locals (its registered closure cells,
    :func:`_pyir_scope_cell_values` -- a local list/tuple/dict the body only
    READS is reachable from nothing else) and every registered holder, walked
    through instance storage, tuples, lists and dict values (the same graph
    :func:`_pyir_snapshot_loop_meta_leaves` covers).  A registered object is
    already ordered by the registry watermark the entry push records; the
    returned ones are the objects the chokes never sighted (nested in a plain
    holder or a container), which :func:`_pyir_region_entry_pin_holders`
    pins as pre-existing for the identity re-point classification in
    ``pyir_assign``."""
    out: "list[Any]" = []
    if not is_pyir_enabled():
        return out
    import collections as _collections
    import types as _types

    skip = (
        bool,
        int,
        float,
        str,
        bytes,
        complex,
        type(None),
        type,
        _types.ModuleType,
        _types.FunctionType,
        _types.MethodType,
        _types.BuiltinFunctionType,
    )
    visited: "set[int]" = set()

    def walk(obj: Any, depth: int) -> None:
        if depth > 8 or isinstance(obj, skip):
            return
        if isinstance(obj, (ir.Value, MutableValue)) or _is_staged_value(obj):
            return
        oid = id(obj)
        if oid in visited:
            return
        visited.add(oid)
        # Sets and deques too: an object only a pre-loop ``frozenset`` or
        # ``deque`` local holds pre-exists the region as surely as a list
        # element does, and no choke ever sighted it either.
        if isinstance(obj, (tuple, list, _collections.deque)):
            for elem in list(obj):
                walk(elem, depth + 1)
            return
        if isinstance(obj, (set, frozenset)):
            for elem in list(obj):
                walk(elem, depth + 1)
            return
        if isinstance(obj, dict):
            for elem in list(dict.values(obj)):
                walk(elem, depth + 1)
            return
        storage = _instance_storage_items(obj)
        if storage is None:
            return
        if oid not in _PYIR_HOLDER_SEQ and _pyir_is_generation_compound(obj):
            out.append(obj)
        for attr, val in list(storage.items()):
            if not isinstance(attr, str) or attr.startswith("_pyir"):
                continue
            walk(val, depth + 1)

    root_ids: "set[int]" = set()
    for root in roots:
        root_ids.add(id(root))
        walk(root, 0)
    for local in _pyir_scope_cell_values():
        walk(local, 0)
    for cand in _pyir_registry_candidate_objects():
        if id(cand) not in root_ids:
            walk(cand, 0)
    return out


def _pyir_select_join_for(obj: Any) -> "dict | None":
    """The open whole-object select record *obj* stands for, if any."""
    oid = id(obj)
    for join in _PYIR_SELECT_JOINS:
        if oid in join["aliases"]:
            return join
    return None


def _pyir_join_whole_object_select(
    target_name: Any,
    old_value: Any,
    new_value: Any,
    if_ops: "list[ir.Operation]",
    filename: "str | None",
    lineno: "int | None",
) -> bool:
    """Thread a whole-object branch-select's canonical leaves through the
    enclosing loop-free ``scf.if`` chain: one ``pyir.ref`` per leaf that
    differs from the entry prototype's (init = the prototype's leaf, so the
    untaken arm keeps it), stored in this arm and rebuilt at each ``if`` close.

    False when the prototype's leaves do not dominate even the innermost
    ``if`` (the binding was born in this arm; there is no entry to join)."""
    if pyir is None or not if_ops:
        return False
    join = _pyir_select_join_for(old_value)
    if join is None:
        anchor: Any = None
        entry_leaves: "list[ir.Value] | None" = None
        chain: "list[ir.Operation]" = []
        # Anchor at the outermost ``if`` of the chain the prototype's leaves
        # dominate; a select nested in an arm-born binding's own ``if`` is
        # joined at that ``if`` only.
        for cand in if_ops:
            cand_op = getattr(cand, "operation", cand)
            try:
                with ir.InsertionPoint(cand_op):
                    leaves = _pyir_extract_leaf_values(old_value)
                if not leaves or not all(
                    pyir.value_dominates_ip(lf, cand_op.block, cand_op) for lf in leaves
                ):
                    break
            except Exception:
                break
            anchor, entry_leaves = cand_op, leaves
            chain.append(cand_op)
        if anchor is None or entry_leaves is None:
            return False
        join = {
            "prototype": old_value,
            "aliases": {id(old_value)},
            "keepalive": [old_value],
            "entry_leaves": entry_leaves,
            "refs": {},
            "anchor": anchor,
            "if_ops": chain,
        }
        _PYIR_SELECT_JOINS.append(join)
    new_leaves = _pyir_extract_leaf_values(new_value)
    entry_leaves = join["entry_leaves"]
    if new_leaves is None or len(new_leaves) != len(entry_leaves):
        # Fail-loud wall: the caller established aligned canonical leaves.
        raise DSLRuntimeError(
            "PyIR emission self-check: whole-object branch-select of "
            f"'{target_name}' lost its canonical-leaf alignment"
        )
    differing = [
        i
        for i, (el, nl) in enumerate(zip(entry_leaves, new_leaves))
        if not _same_ir_value(el, nl)
    ]
    for i in differing:
        el, nl = entry_leaves[i], new_leaves[i]
        if el.type != nl.type:
            raise DSLUserCodeError(
                DiagId.CONTAINER_OBJECT_PROTOTYPE_MISMATCH,
                filename=filename,
                lineno=lineno,
                var=target_name,
                type=type(new_value).__name__,
                detail=_value_tree_prototype_mismatch(join["prototype"], new_value)
                or "a compile-time field differs",
                leaf_detail=(
                    f"runtime field #{i} is {el.type} on one path and "
                    f"{nl.type} on another"
                ),
            )
    # Mint every missing cell before the first store so a failed mint leaves
    # no half-joined binding behind.
    for i in differing:
        if i not in join["refs"]:
            ref, _minted = _pyir_adopt_region_carry_ref(
                None, entry_leaves[i], join["anchor"]
            )
            if ref is None:
                # Fail-loud wall: an uncarried leaf would serve one arm's
                # value on every path.
                raise DSLRuntimeError(
                    "PyIR emission self-check: no `pyir.ref` cell could be "
                    f"minted for canonical leaf #{i} of '{target_name}'"
                )
            join["refs"][i] = ref
    for i in differing:
        _pyir_emit_store(
            new_leaves[i],
            join["refs"][i],
            choke="whole-object branch-select",
            var=target_name,
        )
    join["aliases"].add(id(new_value))
    join["keepalive"].append(new_value)
    log().info(
        "[pyir if] '%s' whole-object branch-select joined through the `if` "
        "(%d of %d canonical leaves carried)",
        target_name,
        len(differing),
        len(entry_leaves),
    )
    return True


def _pyir_rebind_select_joins_post_if(
    if_op: "ir.Operation",
    entry_mix_iter_args: "list",
    mix_iter_args: "list",
) -> None:
    """At a loop-free ``scf.if`` close, rebuild every binding joined through it
    from its entry prototype and the post-``if`` loads of its carried leaves,
    re-pointing the binding's ``mix_iter_args`` slot; the record retires at
    its anchor ``if``."""
    if pyir is None or not _PYIR_SELECT_JOINS:
        return
    op_norm = getattr(if_op, "operation", if_op)
    for join in list(_PYIR_SELECT_JOINS):
        if not any(op_norm == cand for cand in join["if_ops"]):
            continue
        try:
            vals = list(join["entry_leaves"])
            for i, ref in join["refs"].items():
                loaded = _as_arith_capable_scalar_leaf(
                    _raw_backing_ir_value(pyir.load(ref))
                )
                if loaded is None:
                    raise DSLRuntimeError(f"post-`if` load of leaf #{i} failed")
                vals[i] = loaded
            # A fresh birth, as the pytree frontend's reconstruct is: the joined
            # object owns no place of either arm's object, and its constructor
            # is the protocol's own storage plumbing (native, no chokes).
            _PYIR_VALUE_PROTOCOL_DEPTH[0] += 1
            try:
                rebuilt = _pyir_new_from_mlir_values_any(
                    join["prototype"], vals, adopt_token=False
                )
            finally:
                _PYIR_VALUE_PROTOCOL_DEPTH[0] -= 1
            if rebuilt is None:
                raise DSLRuntimeError("the prototype could not be rebuilt")
        except Exception as exc:
            # Fail-loud wall: a binding left on one arm's object would serve
            # that arm's leaves on every path.
            raise DSLRuntimeError(
                "PyIR emission self-check: whole-object branch-select rebuild "
                f"failed for a {type(join['prototype']).__name__} instance: {exc}"
            ) from exc
        join["aliases"].add(id(rebuilt))
        join["keepalive"].append(rebuilt)
        for idx in range(len(mix_iter_args)):
            if id(mix_iter_args[idx]) in join["aliases"] or (
                idx < len(entry_mix_iter_args)
                and id(entry_mix_iter_args[idx]) in join["aliases"]
            ):
                mix_iter_args[idx] = rebuilt
        if op_norm == join["anchor"]:
            _PYIR_SELECT_JOINS.remove(join)


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
    "_pyir_const_int_operand",
    "_pyir_loop_guaranteed_trip",
    "_pyir_push_loop_body_scope",
    "_pyir_pop_loop_body_scope",
    "_meta_promote_slot",
    "_stage_compound_value",
    "_stage_meta_compound_leaves",
    "_pyir_snapshot_region_arg",
    "_pyir_structure_kind",
    "_pyir_structure_signature",
    "_pyir_structure_desc",
    "_pyir_verify_region_structure",
    "_pyir_carry_loop_body_mutated_leaves",
    "_pyir_rebind_carried_leaves_post_loop",
    "_pyir_rebind_local_place_cells_post_region",
    "_pyir_rebind_unstored_scalar_carries_post_loop",
    "_pyir_store_back_unstored_slot_carries_sweep",
    "_pyir_rematerialize_escaped_tuple_local",
    "_pyir_carry_if_region_mutated_leaves",
    "_pyir_snapshot_region_entry_compounds",
    "_pyir_select_join_for",
    "_pyir_join_whole_object_select",
    "_pyir_rebind_select_joins_post_if",
    "_pyir_snapshot_region_meta",
    "_pyir_snapshot_meta_numeric_leaves",
    "_pyir_loop_carried_meta_needs_rebind",
    "_ensure_leaf_ref_no_load",
    "_promote_compound_leaf_refs",
]
