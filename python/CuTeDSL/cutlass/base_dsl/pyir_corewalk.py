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


"""PyIR runtime -- corewalk layer; see facade for the public surface."""

import weakref as _weakref

from .pyir_state import _PYIR_CANDIDATE_REGISTRY_ACTIVE
from .pyir_state import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_core import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)


def _pyir_auto_load_arg(arg: Any, *, row_authoritative: bool = False) -> Any:
    """If *arg* carries a ``_mutable_ref`` with an accessible ref, emit
    ``pyir.load`` and return a fresh value that dominates the current
    insertion point.  Otherwise return *arg* unchanged.

    Called by ``@dsl_user_op`` on every positional argument so post-loop
    uses of pyir-tracked variables load from the ref instead of using a
    stale SSA value from inside the loop body.  That user channel follows
    the route only while *arg* is provably the cell's current binding
    (V-2); a retained snapshot keeps its own SSA (LAW 1).

    *row_authoritative* marks the carry engine's post-region rebind of
    a carried binding: there the region just wrote the row, the row IS the
    authority, and the reload deliberately skips the snapshot judgment
    (not the superseded-scratch refusal: a sound carry presents the cell's
    current handle, so a superseded handle here is never legitimate).

    Optimization: skip the auto-load when *arg* is itself the most recent
    ``MutableValue.load()`` (same ``_load_version``) AND still dominates the
    current IP -- eliminating the redundant load after an AST ``pyir_read``.
    A ``store()`` bumps ``_load_version`` and invalidates the cache.

    D1, when *arg* is a ``_WatchedM`` wrapper: if the slot was promoted to a
    ref (in ``_slot_refs``), emit ``pyir.load`` wrapped in the matching DSL
    Numeric; otherwise return the wrapper unchanged. ``_WatchedM`` subclasses
    int/float so primitive consumers (shapes, ``isinstance``, ``const_expr``)
    work transparently, while SSA consumers invoke ``.ir_value()`` (which
    bakes AND records into ``_meta_uses`` so retroactive rewrite still fires).
    """
    # Candidate-holder registry: every ``@dsl_user_op`` argument is a sighting
    # of an object the trace touches; the recursion below registers elements.
    if _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
        _pyir_register_candidate_holder(arg)
    # None cannot carry a mutable ref or a superseded wrapper. Keep its active
    # registration above, including the registry's inert-class bookkeeping.
    if arg is None:
        return arg

    if isinstance(arg, _WatchedM):
        slot = arg._slot_key
        if slot is not None and slot in _slot_refs:
            _ref = _slot_refs[slot]
            # One declared SNAPSHOT semantics: the cell serves this wrapper's
            # read only while it still holds the creation-time value (same
            # ref, same write epoch); a superseded wrapper materializes
            # through ir_value()'s snapshot judgment instead.
            if _ref is getattr(arg, "_pyir_birth_ref", None) and _ref_write_epoch(
                _ref
            ) == getattr(arg, "_pyir_birth_epoch", None):
                return _load_as_dsl(_ref, place=slot, stamp_place=True)
            return arg
        # Unpromoted: return the bare wrapper so the consumer decides whether to
        # bake (``.ir_value()``) or use it as a Python primitive.
        return arg

    # Tuple/list recursion: containers have no ``_mutable_ref`` but their staged
    # leaves often do -- auto-load each element to mirror ``pyir_read``.
    if isinstance(arg, (tuple, list)):
        loaded = [
            _pyir_auto_load_arg(e, row_authoritative=row_authoritative) for e in arg
        ]
        # ``type(arg)(genexpr)`` collapses / breaks a namedtuple; rebuild via
        # the tuple-aware primitive and keep a list a list.
        # ``row_authoritative`` is set only where a closed region's results
        # re-source the binding, which is the tuple-subclass region carry.
        return (
            loaded
            if isinstance(arg, list)
            else _rebuild_tuple_like(arg, loaded, region_carry=row_authoritative)
        )

    # Owner-less retained-handle read (e.g. a container element's leaf) reaches
    # this auto-load with a superseded generation's own leaf wrapper.
    if _SUPERSEDED_LEAF_WRAPPERS:
        _pyir_check_superseded_wrapper_load(arg)

    mv = getattr(arg, "_mutable_ref", None)

    if mv is not None and mv.ref is not None:
        if mv._is_ref_accessible():
            # Dedup: arg is the latest load AND still dominates current IP.
            cached_version = _get_load_version(arg)
            if (
                cached_version is not None
                and cached_version == mv._load_version
                # Depth-aware: only reuse a cached load at the SAME staged-CF depth,
                # so a deeper consumer rebinds the inner loop's iter_arg.
                and _get_load_depth(arg) == current_staged_cf_depth()
                # Epoch-aware: a raw slot-ref store bumps the REF's write-epoch
                # without touching this wrapper's version -- the load is stale.
                and _get_load_epoch(arg) == _ref_write_epoch(mv.ref)
                and _value_dominates_current_ip(arg)
            ):
                return arg
            # An ADMITTED rebound memref cell must not re-serve a SUPERSEDED
            # wrapper (a handle retained from before the last in-region
            # rebind, e.g. through a container): every in-region allocation
            # aliases the one entry-hoisted buffer, so the reload would
            # observe the fresh generation's overwrites instead of the
            # buffer Python retained.  Refuse loudly at the use site.
            _pyir_refuse_stale_memref_serve(arg, mv)
            # R3: reload through the route when it IS its place's live row
            # (place authority) or while *arg* is provably the cell's current
            # binding (V-2); a retained snapshot keeps its own SSA (LAW 1).
            if row_authoritative or _pyir_route_is_current(arg, mv):
                return mv.load()
            # Clause B, shared with the read and store chokes: a routed raw
            # consumed across a region boundary with no on-path store since
            # its load observes its cell -- the region re-executes
            # later-traced stores the pre-region snapshot cannot see.
            fresh = _pyir_region_fresh_raw(arg)
            if fresh is not None:
                return fresh
            if _pyir_route_is_live_place_row(mv):
                # LAW-1 counter-evidence: an epoch-tagged product a later
                # on-path store superseded, whose own SSA dominates, is a
                # retained SNAPSHOT -- place authority does not govern it.
                if _pyir_value_superseded_on_path(
                    arg, mv.ref
                ) and _value_dominates_current_ip(arg):
                    return arg
                return mv.load()
            return _pyir_resolve_snapshot(arg, type(arg).__name__)
        # Ref inaccessible (stale, from sibling/exited CF): re-create at current scope to restore
        # dominance, but only when ``arg``'s SSA still dominates the IP -- else return ``arg``.
        if _can_create_ref(arg) and _value_dominates_current_ip(arg):
            # The guards above screen out the legitimate not-creatable cases, so
            # a failure here means re-creation was expected to succeed but did not.
            try:
                new_mv = _create_ref(arg)
                return new_mv.load()
            except Exception as e:
                raise DSLRuntimeError(
                    f"failed to re-create a dominating ref for a "
                    f"{type(arg).__name__} value after its original ref became "
                    f"inaccessible"
                ) from e
    return arg


def _has_decomposable_staged_fields(obj: object) -> bool:
    """Return True if *obj* can be auto-decomposed into per-field
    ``pyir_assign`` calls.

    All instance attributes must be meta primitives, staged+ref-compatible
    scalars, tuples of the above, or nested compounds of the above.
    At least one field must be staged (otherwise there is nothing to
    decompose).
    """
    return _check_all_fields_decomposable(obj, _visited=set())


def _has_any_staged_content(obj: object, _visited: "set[int] | None" = None) -> bool:
    """Return True if any field (deeply) is a staged value.

    Used for the error vs passthrough decision: if the object has staged
    content that cannot be decomposed, we raise an error.  If it has NO
    staged content, it is a pure meta replacement (harmless).

    A tuple/list passed directly (not as an object attribute) has no
    ``__dict__``, so the attribute walk below would report it as having no
    staged content.  Check its leaves explicitly so a top-level sequence
    carrying staged values is correctly recognised as loop-carried state
    (mirrors the nested-sequence branch inside the attribute walk).

    *_visited* breaks self-referential object graphs: an object reachable from
    itself (directly or via a cycle) is examined once, so the recursion cannot
    diverge.  Mirrors the cycle guard the sibling walk
    (:func:`_check_all_fields_decomposable`) already uses.
    """
    if _visited is None:
        _visited = set()
    oid = id(obj)
    if oid in _visited:
        return False
    _visited.add(oid)

    if isinstance(obj, (tuple, list)):
        return any(_is_staged_value(e) for e in _flatten_tuple(tuple(obj)))
    for attr_name in _get_instance_attrs(obj):
        value = getattr(obj, attr_name)
        if _is_staged_value(value):
            return True
        if isinstance(value, (tuple, list)) and any(
            _is_staged_value(e) for e in _flatten_tuple(tuple(value))
        ):
            return True
        if (
            _has_instance_storage(value)
            and not isinstance(value, (int, float, bool, str, bytes, type))
            and _has_any_staged_content(value, _visited)
        ):
            return True
    return False


def _pyir_meta_state_value_tree(obj: object) -> bool:
    """A value-protocol object holding ONLY meta content: no staged field at
    any depth and no ``ir.Value`` among its canonical extract leaves.  Its
    extract/reconstruct pair has nothing to carry, so the paths that own a
    value-protocol object cannot follow a rebind of it; the compound paths
    (per-leaf staging, the all-meta rebuild refusal) judge it like a plain
    user object.  Staged content or an extractable leaf keeps the
    value-protocol disposition."""
    if _is_staged_value(obj) or not _implements_dynamic_expression(obj):
        return False
    if _has_any_staged_content(obj):
        return False
    return not _pyir_extract_leaf_values(obj)


def _gather_captured_holders(
    exclude_ids: "set[int] | None",
    walk_obj: "Callable[[Any, set[int], list], Any]",
) -> "Any":
    """Shared registry sweep behind the captured-holder gathers: the leaf
    holders of every object the trace registered (at any stack depth) except
    the *exclude_ids* already snapshotted as ``mix_iter_args``. One visited
    set spans all roots, so each ``(holder, attr)`` is collected once.

    A custom *walk_obj* gets the plain flat record list. The value-tree walk
    returns a :class:`_PyirCapturedSnapshot`: live-walked roots in the list
    body, cacheable roots as a copy of the view table the two logs keep
    current (:func:`_pyir_gather_sync`)."""
    if exclude_ids is None:
        exclude_ids = set()
    holders: "list[tuple[Any, str, Any]]" = []
    visited_objs: "set[int]" = set()
    if walk_obj is not _walk_ir_value_holders_into:
        for cand in _pyir_registry_candidate_objects():
            if id(cand) in exclude_ids:
                continue
            walk_obj(cand, visited_objs, holders)
        return holders
    # Cached value-tree walk: view roots (records memoized against the root
    # stamp and the recorded leaf wrappers' guard stamps) are copied from the
    # table, live roots (negative rows, no stamp row) are walked. Same record
    # multiset as the uncached sweep; no consumer depends on record order.
    _pyir_gather_sync()
    cache = _PYIR_GATHER_CACHE
    registry = _PYIR_CANDIDATE_HOLDERS
    table = cache.view
    # A view root counts as visited (its records come from its row); an
    # excluded root is never replayed, so a walk may still enter it. The walk
    # marks what it visits in this copy; the cache's own id set is not touched.
    if _pyir_verify_scans() and cache.view_ids != set(table):
        raise DSLRuntimeError(
            "PyIR capture scan: the view id set is out of step with the view table"
        )
    visited: "set[int]" = cache.view_ids.copy()
    if exclude_ids:
        visited.difference_update(exclude_ids)
    for oid in list(cache.live):
        if oid in exclude_ids or oid in visited:
            continue
        entry = registry.get(oid)
        cand = entry() if isinstance(entry, _weakref.ref) else entry
        if cand is not None:
            walk_obj(cand, visited, holders)
    if exclude_ids and cache.nested:
        # An excluded root is not replayed from its row, but the full walk
        # still enters it through a parent it is nested in. A live parent's
        # walk does that above; a VIEW parent's row does not, so walk the
        # child here when such a parent is itself swept.
        nested = cache.nested
        for oid in exclude_ids:
            parents = nested.get(oid)
            if not parents or oid in visited:
                continue
            if any(p in table and p not in exclude_ids for p in parents):
                entry = registry.get(oid)
                cand = entry() if isinstance(entry, _weakref.ref) else entry
                if cand is not None:
                    walk_obj(cand, visited, holders)
    view = dict(table)
    for oid in exclude_ids:
        view.pop(oid, None)
    snap = _PyirCapturedSnapshot(holders)
    snap.pyir_view = view
    return snap


def _pyir_gather_sync() -> None:
    """Bring the sweep tables up to date: classify the roots registered since
    the last sweep and re-classify every root the write log has named since
    (its own stamp moved) or that guards on a wrapper the log named."""
    cache = _PYIR_GATHER_CACHE
    registry = _PYIR_CANDIDATE_HOLDERS
    segments = _PYIR_GATHER_SEGMENTS
    live = cache.live
    reg_log = _PYIR_REGISTRATION_LOG
    write_log = _PYIR_WRITE_LOG
    stamps = _PYIR_HOLDER_WRITE_STAMPS
    guards = cache.guards
    # Classifying a root may itself register or stamp holders (the probes it
    # runs append to the logs), so each pass takes the log end FIRST and the
    # loop repeats until both logs are drained.
    while cache.reg_cursor < len(reg_log) or cache.write_cursor < len(write_log):
        end = len(reg_log)
        for oid in reg_log[cache.reg_cursor : end]:
            if oid in segments or oid in live:
                continue
            entry = registry.get(oid)
            cand = entry() if isinstance(entry, _weakref.ref) else entry
            if cand is not None:
                _pyir_gather_classify(oid, cand, entry)
        cache.reg_cursor = end
        end = len(write_log)
        for oid in write_log[cache.write_cursor : end]:
            row = segments.get(oid)
            if row is not None and row[0] != stamps.get(oid):
                entry = registry.get(oid)
                cand = entry() if isinstance(entry, _weakref.ref) else entry
                if cand is None:
                    _pyir_gather_forget(oid)
                else:
                    _pyir_gather_classify(oid, cand, entry)
            dependents = guards.get(oid)
            if not dependents:
                continue
            for root_oid in list(dependents):
                root_row = segments.get(root_oid)
                if root_row is None:
                    continue
                for w, ws in root_row[2]:
                    if stamps.get(id(w)) != ws:
                        break
                else:
                    continue
                entry = registry.get(root_oid)
                cand = entry() if isinstance(entry, _weakref.ref) else entry
                if cand is None:
                    _pyir_gather_forget(root_oid)
                else:
                    _pyir_gather_classify(root_oid, cand, entry)
        cache.write_cursor = end


def _pyir_gather_classify(oid: int, cand: Any, entry: Any) -> None:
    """(Re)judge one root: a cacheable segment whose recorded attrs all read
    storage becomes a view row (guards registered), anything else a live root
    (negative row for a stamped root, no row for an unstamped one)."""
    _pyir_gather_forget(oid)
    cache = _PYIR_GATHER_CACHE
    stamp = _PYIR_HOLDER_WRITE_STAMPS.get(oid)
    if stamp is None:
        cache.live[oid] = None
        return
    seg = _pyir_build_gather_segment(cand)
    if seg is not None and not _pyir_segment_reads_storage(type(cand), seg[0]):
        # A foreign data descriptor shadows a recorded attr: the repair's
        # ``getattr`` would not read the cell. Same records from the live walk.
        seg = None
    if seg is None:
        _PYIR_GATHER_SEGMENTS[oid] = (stamp, None, (), ())
        cache.live[oid] = None
        return
    records, guards, nested = seg
    _PYIR_GATHER_SEGMENTS[oid] = (stamp, records, guards, nested)
    if guards:
        table = cache.guards
        for w, _ws in guards:
            table.setdefault(id(w), set()).add(oid)
    if nested:
        table = cache.nested
        for cid in nested:
            table.setdefault(cid, set()).add(oid)
    if records or nested:
        # The registry's own weakref: no pin on the root, no id-reuse hazard.
        # A root whose only content is nested holders still takes a row, so
        # the sweep counts it visited instead of walking into it.
        cache.view[oid] = (entry, records)
        cache.view_ids.add(oid)


def _pyir_segment_reads_storage(cls: type, records: "tuple") -> bool:
    """True when ``getattr`` on *cls* returns the storage cell for every
    recorded attr, so an unchanged root stamp proves the records unchanged."""
    for attr, _val in records:
        if not _pyir_getattr_reads_storage(cls, attr):
            return False
    return True


class _PyirCapturedSnapshot(list):
    """Captured-holder snapshot of one staged region: the list body holds the
    records of the live-walked roots, ``pyir_view`` the records of the
    cacheable roots as ``id(root) -> (root or its weakref, records)``. A view
    root is write-funneled and its ``getattr`` reads storage, so a root stamp
    unmoved since ``pyir_gather_clock`` (the write clock read at gather start)
    proves its records unchanged: consumers look at the view rows the write
    log names since that clock, plus the body. Record order is not meaningful
    (the repair and the carry act per record, the standalone-if alias
    collection is a membership set)."""

    __slots__ = ("pyir_gather_clock", "pyir_view")
    pyir_gather_clock: int
    pyir_view: "dict[int, tuple[Any, tuple]]"

    def __bool__(self) -> bool:
        # Truthy when it holds ANY record, view rows included.
        return len(self) > 0 or bool(self.pyir_view)

    def pyir_dirty_rows(self) -> "list[tuple[Any, tuple]]":
        """The view rows whose root was written since the gather clock."""
        view = self.pyir_view
        if not view:
            return []
        out: "list[tuple[Any, tuple]]" = []
        seen: "set[int]" = set()
        for oid in _PYIR_WRITE_LOG[self.pyir_gather_clock :]:
            if oid in seen:
                continue
            seen.add(oid)
            row = view.get(oid)
            if row is not None:
                holder = row[0]
                if isinstance(holder, _weakref.ref):
                    holder = holder()
                    if holder is None:
                        continue
                out.append((holder, row[1]))
        return out

    def pyir_changed_candidates(self) -> "list[tuple[Any, str, Any]]":
        """The records whose leaf identity may differ from the snapshot: the
        body plus the dirty view rows. Any other record still binds its leaf
        by the stamp invariant."""
        out = list(self)
        for holder, records in self.pyir_dirty_rows():
            for attr, leaf in records:
                out.append((holder, attr, leaf))
        if _pyir_verify_scans():
            covered = {(id(h), a) for h, a, _v in out}
            _pyir_verify_leaves_unchanged(
                self.pyir_materialize(), covered, "captured snapshot"
            )
        return out

    def pyir_materialize(self) -> "list[tuple[Any, str, Any]]":
        """Every record, the view rows flattened (a dead view root has no
        leaves left to check)."""
        out = list(self)
        for entry, records in self.pyir_view.values():
            holder = entry() if isinstance(entry, _weakref.ref) else entry
            if holder is not None:
                for attr, leaf in records:
                    out.append((holder, attr, leaf))
        return out


def _pyir_gather_captured_leaf_holders(
    exclude_ids: "set[int] | None" = None,
) -> "_PyirCapturedSnapshot | None":
    """Collect value-tree ``ir.Value`` leaf holders of objects CAPTURED by a staged
    region body but not passed as one of its ``mix_iter_args``."""
    clock = _PYIR_WRITE_CLOCK[0]
    snap = _gather_captured_holders(exclude_ids, _walk_ir_value_holders_into)
    if not snap:
        return None
    snap.pyir_gather_clock = clock
    if _pyir_verify_scans():
        _pyir_check_write_log()
        full = _gather_captured_holders(
            exclude_ids, lambda o, v, h: _walk_ir_value_holders_into(o, v, h)
        )
        got = snap.pyir_materialize()
        if sorted((id(h), a, id(v)) for h, a, v in got) != sorted(
            (id(h), a, id(v)) for h, a, v in full
        ):
            raise DSLRuntimeError(
                "PyIR captured snapshot differs from the full sweep: "
                f"{len(got)} cached records vs {len(full)} live records"
            )
    return snap


# Static export surface (regenerate with scripts/gen_pyir_all.py): the
# module's OWN names -- its namespace minus what lower chain modules
# already export and minus the generator's INTERNAL_ONLY registry.
__all__ = [
    "_pyir_auto_load_arg",
    "_has_decomposable_staged_fields",
    "_has_any_staged_content",
    "_pyir_meta_state_value_tree",
    "_pyir_gather_sync",
    "_pyir_gather_classify",
    "_pyir_segment_reads_storage",
    "_PyirCapturedSnapshot",
    "_pyir_gather_captured_leaf_holders",
]
