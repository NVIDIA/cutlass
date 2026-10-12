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

# Standard library imports
import inspect
import sys
import types
import weakref as _weakref

from typing import (
    TYPE_CHECKING,
    Any,
    Callable,
    Literal as _Literal,
    NamedTuple as _NamedTuple,
    Optional,
)

if TYPE_CHECKING:
    # Type-only: a runtime import of pyir_core would close an import cycle, so
    # these names appear only inside string annotations.
    from .pyir_core import MutableValue, _SlotId

# Local imports
from .multi_stage_manager import (
    is_inside_staged_cf,
    is_inside_locally_staged_cf,
    is_inside_constexpr_loop,
    constexpr_scope_under_staged_cf,
    current_staged_cf_depth,
    _is_staged_value,
    assign_meta_staged_check,
)

# MLIR imports
from .common import (
    DSLRuntimeError,
    DSLUserCodeError,
    is_auto_m2s_enabled,
    is_pyir_enabled,
)
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


# PyIR-mode fact per DSL env prefix, registered when the env manager is created.
# Half-enabled tracing is a supported mode for helper jits (one DSL layer may
# legitimately trace with PyIR while a helper layer traces without), so no
# refusal keys on this; the verify-failure funnel consults it to NAME the
# mixed-flag configuration when a cross-DSL kernel compile leaves
# region-crossing SSA behind (an otherwise-opaque dominance ICE).
_PYIR_MODE_BY_PREFIX: "dict[str, bool]" = {}


def _pyir_register_mode_fact(prefix: str, enabled: bool) -> None:
    """Record one DSL prefix's PyIR enablement (declared config fact), and bind
    the Numeric wrapper write funnel the first time any prefix enables PyIR."""
    _PYIR_MODE_BY_PREFIX[str(prefix)] = bool(enabled)
    if enabled:
        from .typing import _pyir_install_numeric_write_funnel

        _pyir_install_numeric_write_funnel()


def _pyir_mixed_mode_hint() -> "str | None":
    """A configuration sentence when the process's DSL prefixes disagree on
    PyIR enablement, or None when the modes are coherent."""
    if len(set(_PYIR_MODE_BY_PREFIX.values())) < 2:
        return None
    on = sorted(p for p, v in _PYIR_MODE_BY_PREFIX.items() if v)
    off = sorted(p for p, v in _PYIR_MODE_BY_PREFIX.items() if not v)
    return (
        "PyIR is enabled for {on} but not for {off}: a kernel compiled "
        "across the two DSL layers mixes traced modes, which can leave "
        "region-crossing SSA behind (the verification failure above). Set "
        "the *_ENABLE_PYIR flags coherently for every DSL layer in the "
        "trace.".format(on=", ".join(on), off=", ".join(off))
    )


# --- Dominance-check helpers (used by _mlir_helpers/op.py) ---

_SCF_REGION_NAMES = {
    "scf.for": "a for-loop body",
    "scf.if": "an if/else body",
    "scf.while": "a while-loop body",
}


# Ref placement helpers

# Function-like entry ops NOT following the ``*.func`` convention; ``*.func`` ops
# are matched structurally by :func:`_is_func_boundary_op`.
_NON_DOT_FUNC_ENTRY_OPS = frozenset(("cuda.kernel",))

# Symbol-table container ops: the entry-block walk terminates here (no SSA
# region to host a ``pyir.ref``).
_MODULE_OPS = frozenset(("builtin.module", "gpu.module"))


# Retroactive promotion: ``_meta_uses[slot]`` = LEAF constants baked from reads in
# staged CF; ``_slot_refs[slot]`` = promoted ref. Per-trace, cleared at exit.

_meta_uses: "dict[Any, list[ir.Value]]" = {}
# Idempotent Mp->Mp rebinds skipped by the promotion gates leave an anchor
# constant at each write site.  If the slot LATER promotes (a different-value
# write), ``_meta_promote_slot`` re-materialises every skipped write as a
# per-site reset store so the cell is reset exactly where Python executed
# the assignment.  Never-promoted anchors are dead constants (canonicalized
# away).  Per-trace, cleared at exit.
_meta_idempotent_write_anchors: "dict[Any, list[ir.Value]]" = {}
_slot_refs: "dict[Any, ir.Value]" = {}
# Wrapper-template half of the bare-ref row above (F-TYPEID): the wrapper the
# place's last store/publish choke held, advanced per store; reads reconstruct
# the row through it (never from a read-site sample). Per-trace, cleared at exit.
_slot_templates: "dict[Any, Any]" = {}
# Gate-once evidence for trace-folded ``if`` gates: the compare choke fills the
# register only for a provable ``not in`` over a plain set; the folder consumes it.
_PYIR_LAST_NOTIN_COMPARE: "list[Any]" = [None]
_PYIR_FOLD_FIRSTDEF_STACK: "list[list[Any]]" = []
# Tag for attr first-def entries on the fold stack (plain slot keys are locals).
CF_ATTR_FIRST_DEF = "cf-attr-first-def"
# Slots whose first-def was proven a once-per-key init (latched membership gate):
# a later meta arithmetic write is the loop-carried advance and promotes.
_PYIR_GATE_ONCE_INIT_SLOTS: "set[Any]" = set()
# Depth of plain-callee executions observed by a call boundary: first-defs there
# have unprovable multiplicity, so keep-meta must not apply.
_PYIR_BOUNDARY_CALLEE_DEPTH: "list[int]" = [0]

# True when the slot's first assignment ran inside staged CF.
_slot_first_def_inside_cf: "dict[Any, bool]" = {}
# Birth block of a place's first binding (F-BIRTHPOS): the insertion block open
# when the first-def choke ran. A region-born cell seeds itself with a real
# store at this block instead of a fabricated dominating init.
_slot_first_def_block: "dict[Any, ir.Block]" = {}
# Birth block recorded for EVERY local first-def (F-BIRTHPOS, meta bindings
# too): a rebind in the SAME block is provably trace-local -- no back-edge or
# branch merge separates birth from rebind.
_slot_first_def_block_any: "dict[Any, ir.Block]" = {}
# Staged-CF depth at the slot's literal first-def: distinguishes an outer-loop
# per-iteration reset from a same-level accumulator.
_slot_first_def_depth: "dict[Any, int]" = {}
# Like ``_slot_first_def_depth`` but recorded for EVERY local first-def (compound
# staged values too); the type-change-at-join guard compares it to the current depth.
_slot_first_def_depth_any: "dict[Any, int]" = {}
# Staged-CF depth at which the slot's CURRENT binding was last written; the
# type-stability gate distinguishes a same-depth shadow from a shallower loop-carry.
_slot_binding_depth: "dict[Any, int]" = {}

# Innermost-open staged-loop body blocks (F-BIRTHPOS declaration): a first-def
# choke running while a body block is open records that block as the binding's
# birth position.
_pyir_open_loop_body_blocks: "list[ir.Block]" = []

# Trace-global region-epoch clock: bumped at every staged-region entry AND exit
# (depth cannot serve: an enter+exit round trip returns to the same depth), so
# two choke events with equal epochs lie in one straight-line trace interval.
_PYIR_REGION_EPOCH: "list[int]" = [0]

# Region-ENTRY clock + stack of entry indices for the currently-open staged
# regions: a value choke-stamped at entry-clock C is re-readable through its
# cell only where every open region predates C (no re-executing region was
# entered after the stamp, so no later-traced store can precede the read).
_PYIR_REGION_ENTRY_CLOCK: "list[int]" = [0]
_PYIR_REGION_ENTRY_STACK: "list[int]" = []


def _pyir_bump_region_epoch() -> None:
    """Advance the region-epoch clock: a staged-region boundary is crossed."""
    _PYIR_REGION_EPOCH[0] += 1


def _pyir_current_region_epoch() -> int:
    """The current region-epoch (recorded on cells at store/load chokes)."""
    return _PYIR_REGION_EPOCH[0]


def _pyir_region_entry_push() -> None:
    """Record a staged-region ENTRY on the entry clock and the open stack."""
    _PYIR_REGION_ENTRY_CLOCK[0] += 1
    _PYIR_REGION_ENTRY_STACK.append(_PYIR_REGION_ENTRY_CLOCK[0])


def _pyir_region_entry_pop() -> None:
    """Close the innermost recorded staged-region entry (no-op when empty)."""
    if _PYIR_REGION_ENTRY_STACK:
        _PYIR_REGION_ENTRY_STACK.pop()


def _pyir_region_entry_clock() -> int:
    """The current region-entry clock value (stamped on choke products)."""
    return _PYIR_REGION_ENTRY_CLOCK[0]


def _pyir_region_entry_watermark() -> int:
    """Entry index of the innermost open staged region (0 when none)."""
    return _PYIR_REGION_ENTRY_STACK[-1] if _PYIR_REGION_ENTRY_STACK else 0


# Unified slot registry keyed by the structural triple ``_SlotId(kind, id(owner), key)``:
# refs follow storage location, not the object in the slot. Weakref finalizer purges on GC.
_SLOT_REGISTRY: "dict[_SlotId, MutableValue]" = {}
_OWNER_KEEPALIVE: "dict[int, _weakref.ReferenceType]" = {}

# Owner places promoted through the D1 write choke: id(owner) -> (owner handle,
# keys). Feeds the stale-leaf region reload; trace-scoped, cleared at exit.
_PYIR_PROMOTED_PLACE_LEAVES: "dict[int, tuple[Any, set]]" = {}


class _Sentinel:
    """A named absence/miss marker: identity-compared like a bare ``object()``
    but self-describing in reprs and debugger views."""

    __slots__ = ("_name",)

    def __init__(self, name: str) -> None:
        self._name = name

    def __repr__(self) -> str:
        return f"<{self._name}>"


_NO_CONST_VALUE = _Sentinel("no const value")


# Watched-container adoption (dict entries / list elements as places)

# Adopt-once registry: ``id(raw dict|list) -> watched instance`` so aliases converge
# on one object and one set of places; trace-scoped, raw containers kept alive.
_WATCHED_CONTAINER_ADOPTIONS: "dict[int, Any]" = {}
_WATCHED_CONTAINER_KEEPALIVE: "list[Any]" = []
# F-SPEC root chaining: ``twin token -> (holder token, hop step)`` declared at
# the adoption choke, so container-leg places resolve to re-resolvable root
# paths; trace-scoped (cleared with the adoption registry, NOT at ledger open,
# because argument adoption precedes the F-SPEC open for the same trace).
_PYIR_SPEC_CONTAINER_CHAIN: "dict[int, tuple[int, tuple]]" = {}
# Memo of object ids the adoption walk already visited this trace, so the
# per-sighting walk at the candidate-holder choke is amortised to one traversal.
# Visited objects are pinned for the trace so a recycled id can never be
# mistaken for an already-walked object.
_WATCHED_CONTAINER_WALKED: "set[int]" = set()
_WATCHED_CONTAINER_WALKED_KEEPALIVE: "list[Any]" = []
# Re-entrancy depth: nested watched dunders raw-delegate while a choke handles an
# access; traces are single-carried, so a depth counter suffices.
_WATCHED_CONTAINER_BYPASS: "list[int]" = [0]
# Choke hooks, installed by the entrypoints layer at import (the hook bodies
# need pyir_read / pyir_assign, which live layers above this module).
_WATCHED_DICT_READ_HOOK: "list[Any]" = [None]
_WATCHED_DICT_WRITE_HOOK: "list[Any]" = [None]
_WATCHED_DICT_GET_MISS_HOOK: "list[Any]" = [None]
_WATCHED_DICT_MUTATOR_HOOK: "list[Any]" = [None]
_WATCHED_DICT_ITER_HOOK: "list[Any]" = [None]
# List-leg hooks: an integer-index leg guarded by the length/order structural
# rule -- separate hook bodies, shared adoption tables.
_WATCHED_LIST_READ_HOOK: "list[Any]" = [None]
_WATCHED_LIST_WRITE_HOOK: "list[Any]" = [None]
_WATCHED_LIST_MUTATOR_HOOK: "list[Any]" = [None]

# ``id(obj)`` membership set for objects held as tracked-container leg values:
# their attributes are places one leg deeper; trace-scoped.
_WATCHED_CONTAINER_HELD_OBJECTS: "set[int]" = set()
_WATCHED_CONTAINER_HELD_KEEPALIVE: "list[Any]" = []

# Registry of the trace's keepalive containers: bookkeeping references that
# pin traced values against GC.  Referrer audits (e.g. the fresh-leaf descend
# witness) must treat these as non-aliases.  Every keepalive list MUST
# register here at its definition site -- an unregistered keepalive makes
# referrer audits conservatively read its bookkeeping reference as a user
# alias, silently degrading the analyses built on them.
_PYIR_TRACE_KEEPALIVES: "list[Any]" = [
    _WATCHED_CONTAINER_KEEPALIVE,
    _WATCHED_CONTAINER_WALKED_KEEPALIVE,
    _WATCHED_CONTAINER_HELD_KEEPALIVE,
]


# Track refs by storage SLOT, not value: ``__dict__``-backed owners store under
# ``__pyir_slots__`` (tier-1); other owners route through ``_SLOT_REGISTRY``.

_SLOT_STORE_ATTR = "__pyir_slots__"

# Every object that registered a slot this trace, keyed by ``id(owner)`` in sighting
# order (plain dict: deterministic iteration; never invokes user __hash__/__eq__).
_PYIR_SLOT_HOLDERS: "dict[int, Any]" = {}


# Trace-scoped registry of objects sighted at PyIR choke points that can root a
# captured-holder walk; same keying/weakref rules as ``_PYIR_SLOT_HOLDERS``.
_PYIR_CANDIDATE_HOLDERS: "dict[int, Any]" = {}

# Sighting front gate: ids of REGISTERED candidates whose repeat sighting is
# provably a no-op (adoption memoized or protocol-filtered), skipped before
# the adoption walk. Strictly a subset of the registry's ids: an id drops
# with its registry row and the set clears with the registry at trace exit.
_PYIR_SIGHTING_SETTLED: "set[int]" = set()

# Fast gate for candidate registration: armed at trace-arg intake, disarmed at
# outermost trace exit, so non-PyIR sighting sites pay one truth test.
_PYIR_CANDIDATE_REGISTRY_ACTIVE: "list[bool]" = [False]


# Holder storage write clock: one monotone counter; every declared storage
# write on a registered holder stamps the holder row with the current tick.
_PYIR_WRITE_CLOCK: "list[int]" = [0]

# ``id(holder) -> last-write tick`` for registered weakrefable candidates;
# rows are minted at registration and die with the registry entry, so a row
# never outlives (or predates) the object it describes.
_PYIR_HOLDER_WRITE_STAMPS: "dict[int, int]" = {}

# ``id(holder) -> (stamp_at_build, records tuple, guards tuple)`` gather-walk
# segments for funneled flat roots (builtin scalars, bare ``ir.Value``,
# SSA-backed Numeric leaves, walk-inert values); root stamp AND per-record
# wrapper guard stamps are validated at splice time; rows are dropped with the
# registry entry (trace-scoped).
_PYIR_GATHER_SEGMENTS: "dict[int, tuple]" = {}

# The declared wrapper write funnel: ``(base class, payload property,
# __setattr__, __delattr__)`` registered by the class that owns the funnel.
_PYIR_WRITE_FUNNEL_DECL: "list[Any]" = [None]

# Per-class memo of the write-funnel fact (class shape is definition-stable).
_PYIR_WRITE_FUNNEL_CLASS_FACTS: "dict[type, bool]" = {}

# Per-class ``{attr: bool}`` memo: ``getattr(instance, attr)`` resolves to the
# instance-storage cell (no foreign MRO data descriptor shadows *attr*).
_PYIR_GETATTR_STORAGE_FACTS: "dict[type, dict]" = {}


def _pyir_note_holder_write(obj: Any) -> None:
    """Stamp a declared storage write on *obj*'s holder row (no-op when the
    object is not a registered candidate)."""
    oid = id(obj)
    if oid in _PYIR_HOLDER_WRITE_STAMPS:
        _PYIR_WRITE_CLOCK[0] += 1
        _PYIR_HOLDER_WRITE_STAMPS[oid] = _PYIR_WRITE_CLOCK[0]


def _pyir_setattr_raw(obj: Any, name: str, value: Any) -> None:
    """The raw-write funnel: ``object.__setattr__`` plus the write stamp, so a
    funnel-bypassing internal write stays visible to the storage-epoch facts."""
    object.__setattr__(obj, name, value)
    oid = id(obj)
    if oid in _PYIR_HOLDER_WRITE_STAMPS:
        _PYIR_WRITE_CLOCK[0] += 1
        _PYIR_HOLDER_WRITE_STAMPS[oid] = _PYIR_WRITE_CLOCK[0]


def _pyir_delattr_raw(obj: Any, name: str) -> None:
    """The raw-delete funnel: ``object.__delattr__`` plus the write stamp."""
    object.__delattr__(obj, name)
    oid = id(obj)
    if oid in _PYIR_HOLDER_WRITE_STAMPS:
        _PYIR_WRITE_CLOCK[0] += 1
        _PYIR_HOLDER_WRITE_STAMPS[oid] = _PYIR_WRITE_CLOCK[0]


def _pyir_declare_write_funnel(base_cls: type) -> None:
    """Declare *base_cls* as the wrapper write-funnel owner: its verbatim
    ``value`` property, ``__setattr__`` and ``__delattr__`` become the identity
    anchors of the per-class funnel fact."""
    _PYIR_WRITE_FUNNEL_DECL[0] = (
        base_cls,
        base_cls.__dict__["value"],
        base_cls.__dict__["__setattr__"],
        base_cls.__dict__["__delattr__"],
    )
    _PYIR_WRITE_FUNNEL_CLASS_FACTS.clear()
    _PYIR_GETATTR_STORAGE_FACTS.clear()


def _pyir_wrapper_write_funneled(cls: type) -> bool:
    """DECLARED write-funnel fact: every language-level attribute write or
    delete on a *cls* instance lands in plain ``__dict__`` storage AND stamps
    the holder write clock.  Requires the declared funnel base in the MRO with
    its verbatim ``__setattr__``/``__delattr__``/``value`` property resolved
    (no override), no custom ``__getattribute__``, and no ``__slots__``."""
    fact = _PYIR_WRITE_FUNNEL_CLASS_FACTS.get(cls)
    if fact is not None:
        return fact
    decl = _PYIR_WRITE_FUNNEL_DECL[0]
    ok = False
    if decl is not None and isinstance(cls, type):
        base, value_prop, setattr_fn, delattr_fn = decl
        try:
            ok = (
                issubclass(cls, base)
                and cls.__setattr__ is setattr_fn
                and cls.__delattr__ is delattr_fn
                and cls.__getattribute__ is object.__getattribute__
                and all("__slots__" not in k.__dict__ for k in cls.__mro__)
                and next(
                    (k.__dict__["value"] for k in cls.__mro__ if "value" in k.__dict__),
                    None,
                )
                is value_prop
            )
        except Exception:
            ok = False
    _PYIR_WRITE_FUNNEL_CLASS_FACTS[cls] = ok
    return ok


def _pyir_getattr_reads_storage(cls: type, attr: str) -> bool:
    """True when ``getattr(instance, attr)`` returns the instance-storage cell
    verbatim on funneled *cls*: either no MRO entry shadows *attr* (instance
    dict wins over non-data descriptors), or the entry IS the declared payload
    property, whose getter returns the stored cell."""
    per_cls = _PYIR_GETATTR_STORAGE_FACTS.get(cls)
    if per_cls is None:
        per_cls = _PYIR_GETATTR_STORAGE_FACTS[cls] = {}
    fact = per_cls.get(attr)
    if fact is not None:
        return fact
    ok = _pyir_wrapper_write_funneled(cls)
    if ok:
        decl = _PYIR_WRITE_FUNNEL_DECL[0]
        for k in cls.__mro__:
            entry = k.__dict__.get(attr)
            if entry is None:
                continue
            if entry is decl[1]:
                break
            entry_cls = type(entry)
            if hasattr(entry_cls, "__set__") or hasattr(entry_cls, "__delete__"):
                ok = False  # foreign data descriptor: getattr resolves through it
            break
    per_cls[attr] = ok
    return ok


def _pyir_plain_storage_setattr(cls: type) -> bool:
    """True when *cls* writes attributes through plain object storage: no
    override at all, or the declared wrapper funnel (a verbatim delegate whose
    only addition is the write stamp)."""
    setattr_fn = cls.__setattr__
    if setattr_fn is object.__setattr__:
        return True
    decl = _PYIR_WRITE_FUNNEL_DECL[0]
    return decl is not None and setattr_fn is decl[2]


# Inert attr placeholder for a SELF-LEAF snapshot record (the leaf IS the loop-carried
# local); the record category is recognised structurally by the dedicated holder type.
_PYIR_SELF_LEAF_ATTR = "<self>"


# Numeric-leaf classification: carryable scalar Numeric wrapper backing kinds.
# not a carryable scalar Numeric wrapper
_NUMERIC_LEAF_NONE: "_Literal['none']" = "none"
# carryable scalar Numeric backed by a baked SSA
_NUMERIC_LEAF_SSA: "_Literal['ssa']" = "ssa"
# carryable scalar Numeric still a meta literal
_NUMERIC_LEAF_META: "_Literal['meta']" = "meta"


# Unit attribute marking a carry ``pyir.ref`` so the while-path dedup recognises a
# post-close load of a nested loop's ref (an op attr, not an id set: wrappers re-mint).
_PYIR_LOOP_ITER_ARGS_ATTR = "pyir.loop_iter_args"


# Inert attr placeholder for a TOP-LEVEL-TUPLE leaf snapshot record: the tuple itself is
# the holder (recognised structurally by ``_pyir_is_carryable_tuple``); the leaf walk
_PYIR_TUPLE_LEAF_ATTR = "<tuple-leaf>"


# Memref write/alias facts are dialect-specific and DECLARED at the IR layer;
# consumers without the pyir binding degrade to no memref-write detection.


# Mutator methods forbidden on plain Python containers inside staged CF: the body
# is traced once, so per-iteration mutations would be silently discarded.
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
        "pop",
        "clear",
        "update",
        "intersection_update",
        "difference_update",
        "symmetric_difference_update",
    }
)
_PYIR_DEQUE_MUTATORS = frozenset(
    {
        "append",
        "appendleft",
        "pop",
        "popleft",
        "rotate",
        "extend",
        "extendleft",
        "clear",
        "remove",
        "insert",
        "reverse",
    }
)


# Mutators that store the caller-supplied object itself, so a staged value with a
# live foreign slot binding would be trapped; non-inserting mutators are excluded.
_PYIR_LIST_INSERT_MUTATORS = frozenset({"append", "extend", "insert"})
_PYIR_DICT_INSERT_MUTATORS = frozenset({"update", "setdefault"})


# --- Place-identity layer: the ledger key space ---

# A "place" is a value-independent key for a logical storage location (never an
# id()), so a reconstructed object at the same binding resolves to the SAME key.

import itertools as _itertools

# Monotonic id sources; never reset per trace, so a stale cross-trace reference
# can never collide with a fresh id.
_SCOPE_ID_COUNTER = _itertools.count()
_TOKEN_COUNTER = _itertools.count()


class _ScopeFrame(_NamedTuple):
    scope_id: int
    kind: str  # 'fn' (user-function/kernel trace) | 'region' (scf region body)


# Authoritative scope stack for bare-name identity (no frame walking): one 'fn'
# frame per instrumented activation; a 'region' frame inherits its 'fn' scope_id.
_PYIR_SCOPE_STACK: "list[_ScopeFrame]" = []


class _PlaceSeg:
    """One composite place segment: a base slot plus the exact item-hop keys
    that reached the leaf (``t[2][0]`` == base ``'t'``, keys ``(2, 0)``).

    Born at the runtime decomposition sites that hold the parent path and the
    hop key as separate Python values, so recording them is a projection of
    local knowledge, never an inference; the bracketed string spelling is
    DISPLAY-ONLY (``__str__``) and is never parsed back.  Deliberately neither
    a ``str`` nor a ``tuple`` subclass: an unaudited boundary must fail
    loudly on it, never absorb it as an attr name or an exact item key."""

    __slots__ = ("base", "keys")
    base: Any
    keys: "tuple[Any, ...]"

    def __init__(self, base: Any, keys: "tuple[Any, ...]" = ()) -> None:
        _pyir_setattr_raw(self, "base", base)
        _pyir_setattr_raw(self, "keys", tuple(keys))

    def __setattr__(self, name: str, value: Any) -> None:
        raise AttributeError("_PlaceSeg is immutable")

    def child(self, key: Any) -> "_PlaceSeg":
        """Extend by one item hop (O(1) at each decomposition level)."""
        return _PlaceSeg(self.base, self.keys + (key,))

    def steps(self) -> "tuple[tuple, ...]":
        """Mechanical unfold into F-SPEC re-resolution steps; a str base is an
        attribute hop, any other base is an exact item key on the owner."""
        first = (
            ("attr", self.base) if isinstance(self.base, str) else ("item", self.base)
        )
        return (first, *(("item", k) for k in self.keys))

    def __eq__(self, other: Any) -> bool:
        return (
            type(other) is _PlaceSeg
            and other.base == self.base
            and other.keys == self.keys
        )

    def __ne__(self, other: Any) -> bool:
        return not self.__eq__(other)

    def __hash__(self) -> int:
        return hash((_PlaceSeg, self.base, self.keys))

    def __str__(self) -> str:
        # Rendering parity with the historical composite spelling
        # (f"{base}[{k!r}]..."): for int keys f"{i}" == f"{i!r}".
        return f"{self.base}" + "".join(f"[{k!r}]" for k in self.keys)

    def __repr__(self) -> str:
        return f"_PlaceSeg({self.base!r}, {self.keys!r})"


def _place_seg_child(parent: Any, key: Any) -> _PlaceSeg:
    """One composite hop below *parent*: a ``_PlaceSeg`` parent extends; any
    other parent (a plain attr name or an exact container key) is the base."""
    if isinstance(parent, _PlaceSeg):
        return parent.child(key)
    return _PlaceSeg(parent, (key,))


class IdentityKeyedWeakTable:
    """Object->value map keyed by referent IDENTITY (the standard identity-map
    algorithm): bookkeeping never invokes user ``__hash__``/``__eq__``, so a
    lookup on a staged value can emit no IR and value-equal distinct owners
    can never alias one row.  Weakrefable keys purge their row at collection
    (the callback runs during deallocation, before the address can recycle);
    non-weakrefable keys are pinned until :meth:`clear`."""

    __slots__ = ("_rows",)

    def __init__(self) -> None:
        # id(key) -> (anchor, value); anchor is a weakref or the pinned key.
        self._rows: "dict[int, tuple[Any, Any]]" = {}

    def get(self, obj: Any, default: Any = None) -> Any:
        row = self._rows.get(id(obj))
        return default if row is None else row[1]

    def __contains__(self, obj: Any) -> bool:
        return id(obj) in self._rows

    def __setitem__(self, obj: Any, value: Any) -> None:
        oid = id(obj)
        row = self._rows.get(oid)
        if row is not None:
            self._rows[oid] = (row[0], value)
            return
        rows = self._rows

        def _drop_row(_r: Any, _oid: int = oid) -> None:
            rows.pop(_oid, None)

        try:
            anchor: Any = _weakref.ref(obj, _drop_row)
        except TypeError:
            anchor = obj
        rows[oid] = (anchor, value)

    def pop(self, obj: Any, default: Any = None) -> Any:
        row = self._rows.pop(id(obj), None)
        return default if row is None else row[1]

    def is_pinned(self, obj: Any) -> bool:
        """True when *obj*'s row holds a strong pin (non-weakrefable key)."""
        row = self._rows.get(id(obj))
        return row is not None and row[0] is obj

    def clear(self) -> None:
        self._rows.clear()

    def __len__(self) -> int:
        return len(self._rows)


# Stable id()-independent owner tokens, propagated across reconstruction.
# Identity-keyed: token bookkeeping can never route through a payload dunder.
_OWNER_TOKENS: "IdentityKeyedWeakTable" = IdentityKeyedWeakTable()

# Rebuild-protocol frame bit (F-BIRTH): non-zero while the
# ``__new_from_mlir_values__`` machinery rebuilds a carried object; owner-token
# adoption asserts it (V-6) -- a constructor call births a fresh token.
_PYIR_REBUILD_PROTOCOL_DEPTH: "list[int]" = [0]

# Owner-token birth class (F-CLASS): token -> type(owner) at mint; carried
# uses validate the live class against it (V-7).
_PYIR_TOKEN_BORN_CLASS: "dict[int, type]" = {}

# The place-keyed cell store; holds MLIR-context-bound MutableValues, cleared per trace.
_PLACE_REGISTRY: "dict[Any, MutableValue]" = {}

# Place -> row store-version at the restructuring rebind that could NOT advance
# the row's cell: serving the row unadvanced would read the superseded
# generation, so the place-routed read refuses instead (discharged by any
# later tracked store or a fresh cell registered at the place).
_PYIR_SUPERSEDED_PLACE_ROWS: "dict[Any, int]" = {}

# Attr-chain places root at the nearest STABLE anchor with a symbolic suffix.
# ``_OWNER_PLACE_PREFIX``: owner object -> (root_token, attr-name suffix from anchor).
_OWNER_PLACE_PREFIX: "IdentityKeyedWeakTable" = IdentityKeyedWeakTable()
# ``_ROOT_NAME_TOKENS``: (scope_id, name) of a dotted access's outermost binding
# name -> anchor token; scoped per activation (a name rebinds per method).
_ROOT_NAME_TOKENS: "dict[tuple, int]" = {}

# ``(scope_id, name) -> owner tokens of the closure CELLS registered for the
# binding``, in registration order (a frame's entry registers first; region-
# synthesized frames sharing the scope append their carry-param cells).
# A cell is the one binding a nested closure and its owning frame share, so
# the tokens are the exact aliasing facts between a boundary closure read and
# a later local write.
_PYIR_SCOPE_CELL_TOKENS: "dict[tuple[int, str], tuple[int, ...]]" = {}

# ``cell token -> (scope_id, name) of the cell's OWNING binding`` (the scope
# whose entry registered the cell as its own cellvar, not as a ``nonlocal``
# freevar); every scope sharing the cell resolves its place key to this row.
_PYIR_CELL_HOME_BINDING: "dict[int, tuple[int, str]]" = {}

# ``scope_id -> frozenset of names the function DECLARES nonlocal``, registered
# at instrumented-function entry (rewrite-time syntactic fact); a bare-name
# choke consults the innermost scope's set to recognize closure-cell bindings.
_PYIR_SCOPE_NONLOCAL_NAMES: "dict[int, frozenset]" = {}

# F-CEPLACE binding-birth ownership: ``(scope_id, name) -> serial of the
# constexpr instance that was innermost-open at the binding's BIRTH`` (or
# ``None`` for an outside-born binding; parameters are seeded ``None`` at
# scope entry so the fact is declared, never defaulted).  A row persists past
# its instance's close -- the qualified place key stays derivable for post-if
# and post-loop reads -- until a dead-owner rebind births a new binding.
_CE_BINDING_OWNER: "dict[tuple[int, str], int | None]" = {}

# One-cell-per-place violation records: a staged access whose authoritative and
# place-cell resolutions name two live cells. Appended before the raise; capped.
_EMISSION_SELF_CHECK_LOG: "list[dict]" = []
_EMISSION_SELF_CHECK_LOG_CAP = 10000

# --- F-SPEC: per-trace specialization ledger -------------------------------
# spec = { root_path -> exact payload } where root_path = (kind, key, steps),
# kind in {"arg", "global", "closure"}; steps are ("attr", name) | ("item", k)
# | ("cell", i) hops from the root object.  Payloads are exact values compared
# structurally at executor re-entry -- never repr digests.

# Owner token -> root path of the object it was minted for (arg graph at trace
# intake, plus lazily identity-resolved globals of the entry function).
_PYIR_SPEC_TOKEN_ROOTS: "dict[int, tuple]" = {}
# Local place ("local", scope_id, name) -> root path (entry parameter locals).
_PYIR_SPEC_LOCAL_ROOTS: "dict[Any, tuple]" = {}
# Entry parameter roots staged at trace intake; adopted by the next 'fn' scope
# (the entry body opens it immediately after intake).
_PYIR_SPEC_PENDING_PARAM_ROOTS: "list[tuple[str, tuple]]" = []
# Tokens that failed a global-identity scan; never re-scanned this trace.
_PYIR_SPEC_UNROOTED_TOKENS: "set[int]" = set()
# Tokens of TRACE-EPOCH objects (IR wrappers written to persistent places
# during this trace, plus values hopped off them): a row chain passing
# through one is trace-internal -- nothing at a later launch can re-derive
# it, so it never records a launch-recheckable row.
_PYIR_SPEC_TRACE_BORN_TOKENS: "set[int]" = set()
# Strong pins for stamped trace-epoch values: a token in the set provably
# names the stamped object for the whole trace (no dead-object aliasing).
_PYIR_SPEC_TRACE_BORN_PINS: "list[Any]" = []
# The recorded specialization set (first read per root path wins: the payload
# closest to entry state is what the trace baked).
_PYIR_SPEC_RECORD: "dict[tuple, Any]" = {}
# Cleared by any bake event not pathable to a re-resolvable root (R6b) and by
# a recording failure (an unrecorded bake is unverifiable); an incomplete
# record refuses executor re-entry instead of guessing.
_PYIR_SPEC_COMPLETE: "list[bool]" = [True]
# The traced entry function: the live root for global/closure re-dereference.
_PYIR_SPEC_ENTRY_FUNC: "list[Any]" = [None]
# Entry-signature facts captured at trace OPEN and sealed with the record
# (DF-1): (first_param_name, {name: ("pos", default_idx) | ("kwonly",)});
# the default map is None when the live __defaults__/__kwdefaults__ shape
# disagreed with the signature at capture (those rows seal unverifiable).
_PYIR_SPEC_ENTRY_SIG: "list[Any]" = [None]
# The traced entry receiver (a bound method's fixed first binding): the live
# root for verifying receiver-rooted rows at re-entry, where the launch
# binding never names the receiver.
_PYIR_SPEC_ENTRY_RECEIVER: "list[Any]" = [None]


class _SpecReceiverDead:
    """Sentinel sealed when the record roots rows at the receiver parameter
    but the receiver object died before the seal: the rows exist and nothing
    live can re-verify them (distinct from ``None`` = no receiver was ever
    part of this entry, e.g. a plain function)."""


_SPEC_RECEIVER_DEAD = _SpecReceiverDead()


class _SpecTraceExitObject:
    """F-SPEC payload for a row the trace itself WROTE with an object-shaped
    value (a receiver field populated during setup, e.g. ``None`` -> struct):
    the trace-exit fact is the written object itself, so re-entry verifies
    live-value IDENTITY.  The referent is held weakly when the object supports
    it (the record never extends a lifetime the verified live state does not
    already hold) and directly otherwise (tuple subclasses, builtin
    containers); a collected referent can no longer be the live value, so it
    reads as drift and refuses."""

    __slots__ = ("_weak", "_strong", "_desc")

    def __init__(self, obj: Any) -> None:
        self._desc = f"{type(obj).__module__}.{type(obj).__qualname__}"
        try:
            self._weak: Any = _weakref.ref(obj)
            self._strong: Any = None
        except TypeError:
            self._weak = None
            self._strong = obj

    def matches(self, live: Any) -> bool:
        obj = self._strong if self._weak is None else self._weak()
        return obj is not None and obj is live

    def __repr__(self) -> str:
        return f"<the {self._desc} object this trace assigned>"


class _SpecContainerSnapshot:
    """F-SPEC payload for a WHOLE-container consumption (``x in lst`` routes
    through C-level ``__contains__``, so no per-item choke fires): the bake
    depends on the full contents, so the row holds an exact contents snapshot
    -- scalar legs by value, object legs by identity -- and re-entry compares
    length plus every leg against the live container."""

    __slots__ = ("kind", "elems")

    def __init__(self, kind: str, elems: tuple) -> None:
        self.kind = kind  # "list" (items) | "dict-keys" (key order + values)
        self.elems = elems

    def matches(self, live: Any) -> bool:
        # One comparator for every F-SPEC row shape: per-leg equality is
        # _spec_payloads_equal (late import: pyir_spec imports this module).
        # The retired private _leg_eq had drifted from it -- it scalarized
        # only the live side, only via the ``python_value`` protocol, and
        # refused nested container-snapshot legs a fresh equal container
        # should satisfy.
        try:
            from .pyir_spec import _spec_payloads_equal

            if self.kind == "list":
                if not isinstance(live, list) or list.__len__(live) != len(self.elems):
                    return False
                items: Any = list.__iter__(live)
            else:
                if not isinstance(live, dict) or dict.__len__(live) != len(self.elems):
                    return False
                items = dict.keys(live)
            return all(_spec_payloads_equal(b, v) for b, v in zip(self.elems, items))
        except Exception:
            return False

    def __repr__(self) -> str:
        return f"<{self.kind} contents snapshot, {len(self.elems)} leg(s)>"


class _SpecAttrAbsent:
    """F-SPEC payload for a tolerated attribute-probe MISS (``hasattr`` False,
    3-arg ``getattr`` default): the bake depends on the name staying absent,
    so re-entry re-probes the final attr hop and refuses when it resolves."""

    def __repr__(self) -> str:
        return "<attribute absent at trace>"


_SPEC_ATTR_ABSENT = _SpecAttrAbsent()


class _SpecAttrPresent:
    """F-SPEC payload for a ``hasattr`` storage HIT: the bake is the PRESENCE
    boolean (never the value), so re-entry re-probes the final attr hop and
    refuses only when the name stops resolving."""

    def __repr__(self) -> str:
        return "<attribute present at trace>"


_SPEC_ATTR_PRESENT = _SpecAttrPresent()


# Sealed (record, complete, entry_func) of the last closed outer trace; the
# compile flow moves it onto the JitCompiledFunction it builds.
_PYIR_SPEC_SEALED: "list[Any]" = [None]


def _reset_spec_state() -> None:
    """Clear the live F-SPEC ledger (the sealed snapshot is left in place for
    the compile flow to collect)."""
    _PYIR_SPEC_TOKEN_ROOTS.clear()
    _PYIR_SPEC_LOCAL_ROOTS.clear()
    _PYIR_SPEC_PENDING_PARAM_ROOTS.clear()
    _PYIR_SPEC_UNROOTED_TOKENS.clear()
    _PYIR_SPEC_TRACE_BORN_TOKENS.clear()
    _PYIR_SPEC_TRACE_BORN_PINS.clear()
    _PYIR_SPEC_RECORD.clear()
    _PYIR_SPEC_COMPLETE[0] = True
    _PYIR_SPEC_ENTRY_FUNC[0] = None
    _PYIR_SPEC_ENTRY_SIG[0] = None
    _PYIR_SPEC_ENTRY_RECEIVER[0] = None


def _reset_scope_state() -> None:
    """Clear per-trace place-layer state; monotonic counters intentionally
    survive trace exit."""
    _PYIR_SCOPE_STACK.clear()
    _PYIR_REBUILD_PROTOCOL_DEPTH[0] = 0
    _PYIR_TOKEN_BORN_CLASS.clear()
    _PLACE_REGISTRY.clear()
    _PYIR_SUPERSEDED_PLACE_ROWS.clear()
    _ROOT_NAME_TOKENS.clear()
    _PYIR_SCOPE_CELL_TOKENS.clear()
    _PYIR_CELL_HOME_BINDING.clear()
    _PYIR_SCOPE_NONLOCAL_NAMES.clear()
    _CE_BINDING_OWNER.clear()
    _PYIR_REGION_EPOCH[0] = 0
    _PYIR_REGION_ENTRY_CLOCK[0] = 0
    _PYIR_REGION_ENTRY_STACK.clear()
    _OWNER_TOKENS.clear()
    _OWNER_PLACE_PREFIX.clear()
    _PYIR_GATE_ONCE_INIT_SLOTS.clear()


# Base-form spine state: the fn-id stack the entrypoints spine drives; the
# enter/exit hooks double as the ledger scope bracket.

# Stack of USER jit-decorated function ids (generated loop bodies do not push):
# frame-local slot keys are unique per USER function; loop-carried locals keep ONE.
_pyir_fn_id_stack: "list[Any]" = []


def pyir_enter_fn(fn_id: Any) -> None:
    """Push *fn_id* as the current user-function scope and open the place-ledger
    'fn' frame: one scope_id per instrumented user-function activation."""
    _pyir_fn_id_stack.append(fn_id)
    scope_id = next(_SCOPE_ID_COUNTER)
    _PYIR_SCOPE_STACK.append(_ScopeFrame(scope_id, "fn"))
    # F-SPEC: the first 'fn' scope after trace intake is the entry body; its
    # parameter locals adopt the staged argument roots.
    if _PYIR_SPEC_PENDING_PARAM_ROOTS:
        for name, root in _PYIR_SPEC_PENDING_PARAM_ROOTS:
            _PYIR_SPEC_LOCAL_ROOTS[("local", scope_id, name)] = root
        _PYIR_SPEC_PENDING_PARAM_ROOTS.clear()


def pyir_exit_fn() -> None:
    """Pop the current user-function scope (in the function body's ``finally``)."""
    if _pyir_fn_id_stack:
        _pyir_fn_id_stack.pop()
    if _PYIR_SCOPE_STACK:
        _PYIR_SCOPE_STACK.pop()


class _Skip:
    """Sentinel type: the subscript-write container is not a tracked dict, so
    the AST-injected pre/post hooks skip instrumentation. Compare by identity
    against the single ``_PYIR_SKIP`` instance below."""

    __slots__ = ()

    def __repr__(self) -> str:
        return "_PYIR_SKIP"


_PYIR_SKIP: "_Skip" = _Skip()

# The extraction walk's DECLARED owner objects (innermost last): an unpaired
# read under the walk resolves its place row against these holders only.
_EXTRACTION_WALK_OWNERS: "list[Any]" = []


_PYIR_READ_SIMPLE_SENTINEL = _Sentinel("read-simple miss")


# Superseded-generation detection: one live cell per leaf place survives a
# whole-object rebind, so stamped non-current generations must refuse reads.

# id(non-current generation) -> stamp record ({"target", "site", "cells",
# "wrapper_refs"}); leaf-cell store versions recorded before the rebind lands.
_SUPERSEDED_GENERATIONS: "dict[int, dict]" = {}
# id(leaf wrapper) -> (stamp record, slot_name) for the superseded generation's
# own staged leaves at stamp time; catches owner-less auto-load reads.
_SUPERSEDED_LEAF_WRAPPERS: "dict[int, tuple]" = {}
# Pin for the stamp's id key: weakref whose callback drops the stamp, or a
# strong ref for non-weakrefable objects so the id cannot be recycled.
_GEN_OBJ_KEEPALIVE: "dict[int, Any]" = {}
_PYIR_TRACE_KEEPALIVES.append(_GEN_OBJ_KEEPALIVE)
# Binding-place slot key -> rebind-generation counter, bumped at every
# whole-object rebind of that place (m2m and Python-phase polarity alike).
_BINDING_GEN: "dict[Any, int]" = {}
# Per bumped key: pre-rebind leaf-cell store-version snapshot + rebind site --
# the baseline the alias-capture fire rule compares against.
_BINDING_REBIND_CELLS: "dict[Any, dict]" = {}
# Plain-local slot key -> {"root", "gen"}: a compound rooted at another
# binding place got bound to a bare local (the alias-capture read channel).
_ALIAS_CAPTURES: "dict[Any, dict]" = {}
# Bare local NAMES with live alias captures, so the read choke can pre-screen
# a dotted read's access root without a frame walk.
_ALIAS_CAPTURE_ROOT_NAMES: "set[str]" = set()
# id(compound) -> the binding-place slot it was FIRST bound at (its root);
# feeds alias capture and the m2m generation bump.
_COMPOUND_BINDING_SLOTS: "dict[int, Any]" = {}
# Reentrancy depth: walk-internal per-field assigns and framework carry run
# with generation events and checks suppressed.
_PYIR_GEN_EVENT_SUPPRESS: "list[int]" = [0]

# Region-conditional attr first-defs: (id(owner), slot_name) -> {"arms", "site"};
# a read whose arm path does not extend the first-def's raises. Cleared at exit.
_PYIR_CF_ATTR_FIRST_DEFS: "dict[tuple, dict]" = {}


# Static export surface (regenerate with scripts/gen_pyir_all.py): the
# module's OWN names -- its namespace minus what lower chain modules
# already export and minus the generator's INTERNAL_ONLY registry.
__all__ = [
    "inspect",
    "sys",
    "types",
    "_weakref",
    "TYPE_CHECKING",
    "Any",
    "Callable",
    "_Literal",
    "_NamedTuple",
    "Optional",
    "is_inside_staged_cf",
    "is_inside_locally_staged_cf",
    "is_inside_constexpr_loop",
    "constexpr_scope_under_staged_cf",
    "current_staged_cf_depth",
    "_is_staged_value",
    "assign_meta_staged_check",
    "DSLRuntimeError",
    "DSLUserCodeError",
    "is_auto_m2s_enabled",
    "is_pyir_enabled",
    "DiagId",
    "ir",
    "log",
    "pyir",
    "ub",
    "_PYIR_MODE_BY_PREFIX",
    "_pyir_register_mode_fact",
    "_pyir_mixed_mode_hint",
    "_SCF_REGION_NAMES",
    "_NON_DOT_FUNC_ENTRY_OPS",
    "_MODULE_OPS",
    "_meta_uses",
    "_meta_idempotent_write_anchors",
    "_slot_refs",
    "_slot_templates",
    "_PYIR_LAST_NOTIN_COMPARE",
    "_PYIR_FOLD_FIRSTDEF_STACK",
    "CF_ATTR_FIRST_DEF",
    "_PYIR_GATE_ONCE_INIT_SLOTS",
    "_PYIR_BOUNDARY_CALLEE_DEPTH",
    "_slot_first_def_inside_cf",
    "_slot_first_def_block",
    "_slot_first_def_block_any",
    "_slot_first_def_depth",
    "_slot_first_def_depth_any",
    "_slot_binding_depth",
    "_pyir_open_loop_body_blocks",
    "_pyir_bump_region_epoch",
    "_pyir_current_region_epoch",
    "_pyir_region_entry_push",
    "_pyir_region_entry_pop",
    "_pyir_region_entry_clock",
    "_pyir_region_entry_watermark",
    "_SLOT_REGISTRY",
    "_OWNER_KEEPALIVE",
    "_PYIR_PROMOTED_PLACE_LEAVES",
    "_Sentinel",
    "_NO_CONST_VALUE",
    "_WATCHED_CONTAINER_ADOPTIONS",
    "_WATCHED_CONTAINER_KEEPALIVE",
    "_PYIR_SPEC_CONTAINER_CHAIN",
    "_WATCHED_CONTAINER_WALKED",
    "_WATCHED_CONTAINER_WALKED_KEEPALIVE",
    "_WATCHED_CONTAINER_BYPASS",
    "_WATCHED_DICT_READ_HOOK",
    "_WATCHED_DICT_WRITE_HOOK",
    "_WATCHED_DICT_GET_MISS_HOOK",
    "_WATCHED_DICT_MUTATOR_HOOK",
    "_WATCHED_DICT_ITER_HOOK",
    "_WATCHED_LIST_READ_HOOK",
    "_WATCHED_LIST_WRITE_HOOK",
    "_WATCHED_LIST_MUTATOR_HOOK",
    "_WATCHED_CONTAINER_HELD_OBJECTS",
    "_WATCHED_CONTAINER_HELD_KEEPALIVE",
    "_PYIR_TRACE_KEEPALIVES",
    "_SLOT_STORE_ATTR",
    "_PYIR_SLOT_HOLDERS",
    "_PYIR_CANDIDATE_HOLDERS",
    "_PYIR_SIGHTING_SETTLED",
    "_PYIR_CANDIDATE_REGISTRY_ACTIVE",
    "_PYIR_WRITE_CLOCK",
    "_PYIR_HOLDER_WRITE_STAMPS",
    "_PYIR_GATHER_SEGMENTS",
    "_pyir_note_holder_write",
    "_pyir_setattr_raw",
    "_pyir_delattr_raw",
    "_pyir_declare_write_funnel",
    "_pyir_wrapper_write_funneled",
    "_pyir_getattr_reads_storage",
    "_pyir_plain_storage_setattr",
    "_PYIR_SELF_LEAF_ATTR",
    "_NUMERIC_LEAF_NONE",
    "_NUMERIC_LEAF_SSA",
    "_NUMERIC_LEAF_META",
    "_PYIR_LOOP_ITER_ARGS_ATTR",
    "_PYIR_TUPLE_LEAF_ATTR",
    "_PYIR_LIST_MUTATORS",
    "_PYIR_DICT_MUTATORS",
    "_PYIR_SET_MUTATORS",
    "_PYIR_DEQUE_MUTATORS",
    "_PYIR_LIST_INSERT_MUTATORS",
    "_PYIR_DICT_INSERT_MUTATORS",
    "_SCOPE_ID_COUNTER",
    "_TOKEN_COUNTER",
    "_ScopeFrame",
    "_PYIR_SCOPE_STACK",
    "_PlaceSeg",
    "_place_seg_child",
    "IdentityKeyedWeakTable",
    "_OWNER_TOKENS",
    "_PYIR_REBUILD_PROTOCOL_DEPTH",
    "_PYIR_TOKEN_BORN_CLASS",
    "_PLACE_REGISTRY",
    "_PYIR_SUPERSEDED_PLACE_ROWS",
    "_OWNER_PLACE_PREFIX",
    "_ROOT_NAME_TOKENS",
    "_PYIR_SCOPE_CELL_TOKENS",
    "_PYIR_CELL_HOME_BINDING",
    "_PYIR_SCOPE_NONLOCAL_NAMES",
    "_CE_BINDING_OWNER",
    "_EMISSION_SELF_CHECK_LOG",
    "_EMISSION_SELF_CHECK_LOG_CAP",
    "_PYIR_SPEC_TOKEN_ROOTS",
    "_PYIR_SPEC_LOCAL_ROOTS",
    "_PYIR_SPEC_PENDING_PARAM_ROOTS",
    "_PYIR_SPEC_UNROOTED_TOKENS",
    "_PYIR_SPEC_TRACE_BORN_TOKENS",
    "_PYIR_SPEC_TRACE_BORN_PINS",
    "_PYIR_SPEC_RECORD",
    "_PYIR_SPEC_COMPLETE",
    "_PYIR_SPEC_ENTRY_FUNC",
    "_PYIR_SPEC_ENTRY_SIG",
    "_PYIR_SPEC_ENTRY_RECEIVER",
    "_SPEC_RECEIVER_DEAD",
    "_SpecTraceExitObject",
    "_SpecContainerSnapshot",
    "_SPEC_ATTR_ABSENT",
    "_SPEC_ATTR_PRESENT",
    "_PYIR_SPEC_SEALED",
    "_reset_spec_state",
    "_reset_scope_state",
    "pyir_enter_fn",
    "pyir_exit_fn",
    "_Skip",
    "_PYIR_SKIP",
    "_EXTRACTION_WALK_OWNERS",
    "_PYIR_READ_SIMPLE_SENTINEL",
    "_SUPERSEDED_GENERATIONS",
    "_SUPERSEDED_LEAF_WRAPPERS",
    "_GEN_OBJ_KEEPALIVE",
    "_BINDING_GEN",
    "_BINDING_REBIND_CELLS",
    "_ALIAS_CAPTURES",
    "_ALIAS_CAPTURE_ROOT_NAMES",
    "_COMPOUND_BINDING_SLOTS",
    "_PYIR_GEN_EVENT_SUPPRESS",
    "_PYIR_CF_ATTR_FIRST_DEFS",
]
