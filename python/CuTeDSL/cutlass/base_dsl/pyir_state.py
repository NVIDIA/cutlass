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


"""PyIR runtime -- state layer; see facade for the public surface."""

# =============================================================================
# Standard library imports
# =============================================================================
import inspect

from collections.abc import Iterator
from contextlib import contextmanager
from typing import TYPE_CHECKING, Any, Optional
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

if TYPE_CHECKING:
    # Annotation-only; a runtime import would cycle (pyir_core imports this).
    from .pyir_core import MutableValue
# Unbind the guard so the layer chain's dynamic ``__all__`` surface is unchanged.
del TYPE_CHECKING

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

# Fold-witness table (PHASE_PREDICATE_FOLDED_STALE): slot_key -> list of
# witness records.  A witness is recorded when a ``_WatchedM`` fold is
# consumed by PLAIN-CPython control flow inside staged CF -- i.e. the folded
# Python value decided a trace-time branch that no later D1 promotion can
# rewrite (no SSA edge exists from a taken CPython branch to any tracked
# leaf).  Two events record a witness:
#
#   * ``_WatchedM.__bool__`` -- a truth-test (``if w:``, ``while w:``,
#     ``not w``, ``w and x``) of a slot-connected (directly or via
#     ``_origin_slots`` provenance) wrapper inside staged CF, and
#   * ``_cmp_ir``'s plain-Python fallback returns -- the comparison folded to
#     a bare ``bool`` (no derived wrapper with live IR), so any downstream
#     consumption is invisible to the meta table.
#
# The witness alone is NOT an error: a fold on a slot that stays constexpr
# for the whole trace is exactly the supported meta-programming model.  The
# trace only becomes unsound when the SAME slot is later promoted to a
# ``pyir.ref`` (its reads become runtime loads while the witnessed branch
# stays hard-wired to the stale trace-time value), so ``_meta_promote_slot``
# checks this table and raises ``DiagId.PHASE_PREDICATE_FOLDED_STALE`` citing
# both the fold site and the mutation site.  Cleared at trace exit.
#
# Witness record keys: ``filename``/``lineno`` (fold site, via
# ``find_user_source_location``), ``value`` (folded Python value), ``kind``
# (human-readable consumption kind).
_fold_witnesses: "dict[Any, list[dict[str, Any]]]" = {}

# The diagnostic cites only the first fold site plus a count, so any cap >= 2
# is behaviorally identical; this value merely bounds per-slot memory.
_MAX_FOLD_WITNESSES_PER_SLOT = 8

# Slots in the SYNTACTIC write-set of an open staged region (tagged by the
# before-block / body-entry prologue): a genuine store WILL land this trace
# even if it hasn't yet.  Lets the while-condition lift stage `n > 0` when
# `n` is loop-carried, while a never-stored predicate keeps its trace-time
# fold (the keep-constexpr contract).  Cleared at trace exit.
_slot_pending_store: "set[Any]" = set()


# Stack of USER ``@cute.jit`` function ids.  ``pyir_function_scope`` pushes one
# for the enclosed user function body.  Preprocessor-generated
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


# ---------------------------------------------------------------------------
# Dominance-check helpers (used by _mlir_helpers/op.py)
# ---------------------------------------------------------------------------

_SCF_REGION_NAMES = {
    "scf.for": "a for-loop body",
    "scf.if": "an if/else body",
    "scf.while": "a while-loop body",
}


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


_PYIR_READ_SIMPLE_SENTINEL = object()


_NON_DOT_FUNC_ENTRY_OPS = frozenset(("cuda.kernel",))


_MODULE_OPS = frozenset(("builtin.module", "gpu.module"))

__all__ = [name for name in list(globals()) if not name.startswith("__")]
