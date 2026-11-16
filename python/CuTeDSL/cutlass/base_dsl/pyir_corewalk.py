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
    _pyir_register_candidate_holder(arg)

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
        return loaded if isinstance(arg, list) else _rebuild_tuple_like(arg, loaded)

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
            if _pyir_route_is_live_place_row(mv):
                # LAW-1 counter-evidence: an epoch-tagged product a later
                # store superseded, whose own SSA dominates, is a retained
                # SNAPSHOT -- place authority does not govern that read.
                _epoch_tag = _get_load_epoch(arg)
                if (
                    _epoch_tag is not None
                    and _epoch_tag != _ref_write_epoch(mv.ref)
                    and _value_dominates_current_ip(arg)
                ):
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


def _gather_captured_holders(
    exclude_ids: "set[int] | None",
    walk_obj: "Callable[[Any, set[int], list], Any]",
) -> "list[tuple[Any, str, Any]]":
    """Shared registry sweep behind the captured-holder gathers.

    Collects leaf holders of objects CAPTURED by a staged region/loop body but
    not passed as one of its ``mix_iter_args`` (captured free variables).

    Discovery iterates the trace-scoped candidate-holder registry
    (:data:`_PYIR_CANDIDATE_HOLDERS`) in sighting order.

    Each live candidate is fed to *walk_obj*, which appends ``(holder, attr,
    value)`` triples into the shared accumulator; the per-walker gate lives
    entirely in *walk_obj*.

    One shared visited set spans all candidates, so a holder reachable from
    several candidates is walked once and each ``(holder, attr)`` pair is
    collected exactly once.

    Registration follows what the trace actually touched, not what happens to
    sit in a Python frame, so a captured holder is reached at any stack depth.

    *exclude_ids* holds ``id()`` of objects already snapshotted via
    ``mix_iter_args``.  An empty result maps to the wrappers' sentinel.

    Cross-sweep caching (value-tree walk only): a cacheable root's record
    segment (:func:`_pyir_build_gather_segment`) is memoized against its
    write stamp and spliced at the root's registry position when the root
    stamp AND every recorded Numeric leaf's own guard stamp are unchanged AND
    no earlier live walk already consumed the root this sweep (positional
    splice validation); any failing takes the live walk in position, so
    record multiset AND order equal the uncached sweep's."""
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
    # Per-root decision flow (cached value-tree walk):
    #
    #   root already visited this sweep? ──yes──► live walk (a no-op; replay
    #     │no                                     here would emit duplicate rows)
    #   root has a write stamp? ──────────no───► live walk (no stamp to validate
    #     │yes                                   a cached row against yet)
    #   cached row at the SAME stamp?
    #     │        ├─ negative row ────────────► live walk (judged uncacheable)
    #     │        ├─ a leaf guard stamp moved ► rebuild segment below
    #     │        └─ all guards intact ───────► replay cached (attr, val) rows
    #     │no (stale or missing row)
    #   build a fresh segment ── cacheable? ──yes──► store + replay it
    #                                └──────────no──► store negative row + live walk
    segments = _PYIR_GATHER_SEGMENTS
    stamps = _PYIR_HOLDER_WRITE_STAMPS
    for cand in _pyir_registry_candidate_objects():
        oid = id(cand)
        if oid in exclude_ids:
            continue
        if oid in visited_objs:
            # An earlier live walk consumed this root at ITS position.
            walk_obj(cand, visited_objs, holders)
            continue
        stamp = stamps.get(oid)
        if stamp is None:
            walk_obj(cand, visited_objs, holders)
            continue
        row = segments.get(oid)
        if row is not None and row[0] == stamp:
            records = row[1]
            if records is None:
                # Negative row: judged not cacheable at this stamp; no
                # re-judgment until the root is written again.
                walk_obj(cand, visited_objs, holders)
                continue
            # Numeric-leaf guards: an in-place write on a recorded wrapper
            # stamps the WRAPPER's row (not the root's) and may flip its leaf
            # classification -- any moved stamp takes the rebuild instead.
            for w, ws in row[2]:
                if stamps.get(id(w)) != ws:
                    break
            else:
                visited_objs.add(oid)
                for attr, val in records:
                    holders.append((cand, attr, val))
                continue
        seg = _pyir_build_gather_segment(cand)
        if seg is None:
            segments[oid] = (stamp, None, ())
            walk_obj(cand, visited_objs, holders)
            continue
        records, guards = seg
        segments[oid] = (stamp, records, guards)
        visited_objs.add(oid)
        for attr, val in records:
            holders.append((cand, attr, val))
    return holders


class _PyirCapturedSnapshot(list):
    """Captured-holder snapshot carrying the write clock read at gather START
    (any write during or after the sweep stamps later, so the repair's
    stamp<=clock skip is exact); behaves as a plain record list."""

    __slots__ = ("pyir_gather_clock",)
    pyir_gather_clock: int


def _pyir_gather_captured_leaf_holders(
    exclude_ids: "set[int] | None" = None,
) -> "list[tuple[Any, str, ir.Value]] | None":
    """Collect value-tree ``ir.Value`` leaf holders of objects CAPTURED by a staged
    region body but not passed as one of its ``mix_iter_args``."""
    clock = _PYIR_WRITE_CLOCK[0]
    holders = _gather_captured_holders(exclude_ids, _walk_ir_value_holders_into)
    if not holders:
        return None
    snap = _PyirCapturedSnapshot(holders)
    snap.pyir_gather_clock = clock
    return snap


# Static export surface (regenerate with scripts/gen_pyir_all.py): the
# module's OWN names -- its namespace minus what lower chain modules
# already export and minus the generator's INTERNAL_ONLY registry.
__all__ = [
    "_pyir_auto_load_arg",
    "_has_decomposable_staged_fields",
    "_has_any_staged_content",
    "_PyirCapturedSnapshot",
    "_pyir_gather_captured_leaf_holders",
]
