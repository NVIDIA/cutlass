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


"""PyIR runtime -- cleanup layer; see facade for the public surface."""

from .pyir_call_boundary import *  # noqa: F401,F403  (re-export lower layers up the chain)

from .._mlir import ir

# -- BEGIN explicit imports for the type checker (do not edit the list by hand;
# it mirrors names the chain re-exports at runtime via the wildcard + dynamic
# ``__all__`` above, which a static type checker cannot evaluate -- so every
# name is also imported explicitly from the layer that DEFINES it). Purely
# additive: the wildcard import stays the runtime source of truth.
from .pyir_state import (  # noqa: F401
    Any,
    DSLUserCodeError,
    DiagId,
    ub,
)
# -- END explicit imports for the type checker


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
    from . import pyir_core as _pyir_core

    if _pyir_core._POISON_EMITTED == 0:
        # ``_make_poison_like`` is the only producer of ``ub.poison``; if it
        # never ran since the last verify boundary the module cannot contain
        # one.  Skips the whole-module walk on every classic-mode (and most
        # pyir) compiles.
        return
    # Consume the counter at the verify boundary: traces are sequential
    # in-process, so every poison op built since the previous verify belongs
    # to THIS module and is accounted for by the walk below.  Consumed BEFORE
    # the walk so the raising path (poison-read diagnostic) does not leak the
    # count either.  A failing trace that never reaches build_module (and so
    # skips this verify) can leave a stale count behind -- that is fail-safe:
    # the next verify walks once spuriously (sound, just slower) and re-arms
    # the skip.
    _pyir_core._POISON_EMITTED = 0

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


__all__ = [name for name in list(globals()) if not name.startswith("__")]
