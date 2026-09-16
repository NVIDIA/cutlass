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


"""PyIR runtime -- threading layer; see facade for the public surface."""

from .pyir_corewalk import *  # noqa: F401,F403  (re-export lower layers up the chain)

# -- BEGIN explicit imports for the type checker (do not edit the list by hand;
# it mirrors names the chain re-exports at runtime via the wildcard + dynamic
# ``__all__`` above, which a static type checker cannot evaluate -- so every
# name is also imported explicitly from the layer that DEFINES it). Purely
# additive: the wildcard import stays the runtime source of truth.
from .pyir_state import (  # noqa: F401
    Any,
    _meta_uses,
    _slot_first_def_block,
    _slot_first_def_inside_cf,
    _slot_refs,
    ir,
    log,
    pyir,
)
from .pyir_core import (  # noqa: F401
    _ancestor_op_in_block,
    _emit_constant_at_ip,
    _get_function_entry_block,
    _raise_on_fold_witness,
    _replace_value_uses,
)
# -- END explicit imports for the type checker


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
    # P6: a slot whose constexpr fold already decided CPython control flow
    # cannot be promoted -- its reads would become runtime loads while the
    # baked branch stays hard-wired (silent miscompile).  Refuse here, at the
    # single promotion entry.
    _raise_on_fold_witness(slot_key, initial_py_value, target_name, filename, lineno)
    from .pyir_runtime import _get_function_entry_block, _ancestor_op_in_block

    entry_block = _get_function_entry_block()
    if entry_block is None:
        return None

    with ir.InsertionPoint.at_block_begin(entry_block):
        initial_ir = _emit_constant_at_ip(initial_py_value)
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
                        reset_ir = _emit_constant_at_ip(initial_py_value)
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


__all__ = [name for name in list(globals()) if not name.startswith("__")]
