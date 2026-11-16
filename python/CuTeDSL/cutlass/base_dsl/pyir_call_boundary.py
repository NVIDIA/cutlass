# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.


"""Call-boundary effect observer: a plain (un-instrumented) callee's stores on
tracked places are diffed at the call site and replayed through the chokes.

DECLARED observation domain of the snapshot/diff walk: objects reachable from
the call's receiver, arguments, kwargs values, closure cells, the callee's
TAKEN parameter defaults (``__defaults__``/``__kwdefaults__`` objects the call
binding leaves unbound, LangRef §8.7), and the registered slot holders; per
object -- its instance storage (``__dict__`` +
set ``__slots__``), raw dict/list legs, closure-cell contents, and the
class-level data attributes of its USER-MODULE class (owner = the class
object). A returned object born in the callee enters the identity domain at
the boundary return (owner-token mint + born-class stamp); its leaves publish
at their binding chokes. Writes outside this domain are detected at their
next choked read or stay on the declared floor."""

import bisect as _bisect
import builtins as _builtins
import collections as _collections
import dataclasses as _dataclasses
import dis as _dis
import functools as _functools
import heapq as _heapq
import operator as _operator
import os as _os
import sys as _sys
import types as _types
import weakref as _weakref

from .pyir_state import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_core import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_corewalk import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_loop_carry import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_entrypoints import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_state import _Sentinel

from . import pyir_class_facts as _pyir_class_facts


# -- Callee module fact (fast-path): user code vs DSL/stdlib/third-party.

# The top-level package this base_dsl instance is vendored under (e.g.
# ``cutlass`` for ``cutlass.base_dsl``); its whole namespace is the DSL.
_PYIR_BOUNDARY_DSL_TOP = __name__.split(".")[0] if "." in __name__ else None

# The packages root the DSL is installed under (parent of the top package):
# any module whose spec origin lives under it is DSL-distribution code.
_PYIR_BOUNDARY_PKG_ROOTS: "tuple[str, ...]" = ()
try:
    _pkg_root = _os.path.dirname(
        _os.path.dirname(_os.path.dirname(_os.path.abspath(__file__)))
    )
    _PYIR_BOUNDARY_PKG_ROOTS = tuple(
        {_pkg_root + _os.sep, _os.path.realpath(_pkg_root) + _os.sep}
    )
except Exception:  # pragma: no cover - defensive
    _PYIR_BOUNDARY_PKG_ROOTS = ()

_PYIR_BOUNDARY_MODULE_VERDICT: "dict[str, bool]" = {}


def _pyir_boundary_module_is_user(mod: "str | None") -> bool:
    """MODULE fact: does *mod* resolve to user code?  DSL packages, declared
    library packages, stdlib, and site-packages are not user code (skip)."""
    if mod is None:
        return False  # C extension / builtin: no resolvable origin
    if not mod or mod == "__main__":
        return True
    cached = _PYIR_BOUNDARY_MODULE_VERDICT.get(mod)
    if cached is not None:
        return cached
    verdict = True
    top = mod.split(".", 1)[0]
    try:
        if _PYIR_BOUNDARY_DSL_TOP is not None and top == _PYIR_BOUNDARY_DSL_TOP:
            verdict = False
        elif any(
            mod == p or mod.startswith(p + ".")
            for p in _pyir_class_facts._DECLARED_PREFIXES
        ):
            verdict = False
        elif top in getattr(_sys, "stdlib_module_names", ()):
            verdict = False
        else:
            import importlib.util as _importlib_util

            try:
                spec = _importlib_util.find_spec(top)
            except (ModuleNotFoundError, ValueError, AttributeError, ImportError):
                spec = None
            origin = getattr(spec, "origin", None) if spec is not None else None
            if origin is None:
                # Namespace package / frozen / builtin: try the submodule
                # search locations before giving up.
                locations = (
                    getattr(spec, "submodule_search_locations", None)
                    if spec is not None
                    else None
                )
                if locations:
                    origin = next(iter(locations), None)
            if origin is not None:
                if "site-packages" in origin or "dist-packages" in origin:
                    verdict = False
                elif any(
                    origin.startswith(root) for root in _PYIR_BOUNDARY_PKG_ROOTS
                ) or any(
                    _os.path.realpath(origin).startswith(root)
                    for root in _PYIR_BOUNDARY_PKG_ROOTS
                ):
                    verdict = False
    except Exception:
        # Fail-soft: observation of a non-user callee is a no-op diff.
        verdict = True
    _PYIR_BOUNDARY_MODULE_VERDICT[mod] = verdict
    return verdict


# Wrapper-consuming layers: the DSL's own Python namespace takes watched-META
# wrappers by design (the retargetable ``ir_value`` channel); the compiled
# ``_mlir`` builder surface, stdlib, and third-party code take plain payloads.
_PYIR_BOUNDARY_WRAPPER_CONSUMER_VERDICT: "dict[str, bool]" = {}


def _pyir_boundary_module_consumes_wrappers(mod: "str | None") -> bool:
    """MODULE fact: does *mod* consume watched-META wrappers by design?"""
    if mod is None or _PYIR_BOUNDARY_DSL_TOP is None:
        return False
    cached = _PYIR_BOUNDARY_WRAPPER_CONSUMER_VERDICT.get(mod)
    if cached is not None:
        return cached
    top = _PYIR_BOUNDARY_DSL_TOP
    verdict = (mod == top or mod.startswith(top + ".")) and not (
        mod == top + "._mlir" or mod.startswith(top + "._mlir.")
    )
    _PYIR_BOUNDARY_WRAPPER_CONSUMER_VERDICT[mod] = verdict
    return verdict


# -- Dispatch: _pyir_call_boundary_(callee) -> callee | proxy

# Re-entrancy: function ids currently executing under an observation, so a
# recursive self-call is observed once (at the outermost boundary).
_PYIR_BOUNDARY_ACTIVE: "set[int]" = set()


class _PyirCallBoundaryProxy:
    """Transparent call-through that observes the callee's effects on tracked
    places (snapshot -> plain call -> diff -> instrumented replay)."""

    # Slot attribute types (assigned via ``object.__setattr__`` in ``__init__``
    # to stay off the proxy's attribute-forwarding path).
    _pyir_boundary_callee: Any
    _pyir_boundary_sc_rhs: bool

    __slots__ = ("_pyir_boundary_callee", "_pyir_boundary_sc_rhs")

    def __init__(self, callee: Any, sc_rhs: bool = False) -> None:
        _pyir_setattr_raw(self, "_pyir_boundary_callee", callee)
        _pyir_setattr_raw(self, "_pyir_boundary_sc_rhs", sc_rhs)

    def __repr__(self) -> str:  # pragma: no cover - debug aid
        return f"<pyir call boundary for {self._pyir_boundary_callee!r}>"

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        callee = self._pyir_boundary_callee
        try:
            active = _pyir_boundary_trace_active()
        except Exception:
            active = False
        if not active:
            return callee(*args, **kwargs)
        _pyir_global_write_guard(callee)
        func = getattr(callee, "__func__", callee)
        fid = id(func)
        if fid in _PYIR_BOUNDARY_ACTIVE:
            return callee(*args, **kwargs)
        try:
            roots = _pyir_boundary_tracked_roots(callee, args, kwargs)
        except Exception:
            roots = []
        # F-SPEC: taken parameter defaults are consumed with no read choke;
        # seal their payload rows whether or not tracked state is reachable.
        try:
            _pyir_spec_boundary_default_reads(callee, args, kwargs)
        except Exception:
            pass
        if not roots:
            watch = _pyir_global_write_watch(callee)
            result = callee(*args, **kwargs)
            _pyir_global_write_check(watch)
            return result
        try:
            _pyir_boundary_record_meta_cell_reads(callee)
        except Exception:
            pass
        # Read-half tier 1 (dominance refresh): re-bind an escaped staged attr
        # leaf to a fresh dominating load BEFORE the callee reads it raw.
        try:
            _pyir_reload_stale_staged_attr_leaves("call boundary in")
        except Exception:
            pass
        # Read-half tier 3 (imminent-write pre-stage): fields the callee's own
        # code writes run on STAGED values, so the RMW derives from the cell.
        try:
            prestaged = _pyir_boundary_prestage_imminent_writes(callee, args)
        except DSLUserCodeError:
            raise  # the off-mode promotion refusal must reach the author
        except Exception:
            prestaged = []
        # Read-half tier 2 (meta read-attribution): plain-meta attr leaves get
        # place-attributed wrappers so reads record retargetable constants.
        try:
            wrapped = _pyir_boundary_stage_meta_reads(roots)
        except Exception:
            wrapped = []
        watch = _pyir_global_write_watch(callee)
        snapshot = _pyir_boundary_snapshot(roots)
        try:
            _PYIR_BOUNDARY_ACTIVE.add(fid)
            _PYIR_BOUNDARY_CALLEE_DEPTH[0] += 1
            try:
                result = callee(*args, **kwargs)
            finally:
                _PYIR_BOUNDARY_CALLEE_DEPTH[0] -= 1
                _PYIR_BOUNDARY_ACTIVE.discard(fid)
            # Reached only on a normal return: a raising callee pops the
            # snapshot with no emission (the outer finally still restores the
            # tier-2/3 binds so no wrapper stays bound in user storage).
            _pyir_boundary_commit(
                callee, snapshot, self._pyir_boundary_sc_rhs, result=result
            )
        finally:
            try:
                _pyir_boundary_restore_meta_reads(wrapped)
            except Exception:
                pass
            try:
                _pyir_boundary_restore_prestage(prestaged)
            except Exception:
                pass
        _pyir_global_write_check(watch)
        return result


def _pyir_boundary_trace_active() -> bool:
    """True while a PyIR-instrumented function body is tracing into an
    open MLIR function (the only scope where a boundary commit can emit)."""
    if pyir is None or not _PYIR_SCOPE_STACK:
        return False
    return _get_function_entry_block() is not None


# Numeric-protocol builtins (LangRef 3.3.8): with a watched receiver they
# consume through the registered dunder arms, so the funnel must not pre-unwrap.
_PYIR_PROTOCOL_BUILTINS: "tuple[Any, ...]" = (divmod, pow, complex)


class _PyirMetaUnwrapProxy:
    """Unwrap funnel for callees outside the wrapper-consuming layers: each
    watched-META argument is consumed HERE -- recorded and passed as its plain
    payload -- so a compiled/stdlib callee never receives a wrapper."""

    _pyir_unwrap_callee: Any

    __slots__ = ("_pyir_unwrap_callee",)

    def __init__(self, callee: Any) -> None:
        self._pyir_unwrap_callee = callee

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        callee = self._pyir_unwrap_callee
        try:
            active = _pyir_boundary_trace_active()
        except Exception:
            active = False
        if active:
            _pyir_global_write_guard(callee)
            # A watched RECEIVER guarantees dunder interception (subclass
            # priority); a non-watched lhs C-slot needs the funnel witness.
            if (
                callee in _PYIR_PROTOCOL_BUILTINS
                and args
                and isinstance(args[0], _WatchedM)
            ):
                return callee(*args, **kwargs)
            if any(isinstance(a, _WatchedM) for a in args):
                args = tuple(_pyir_boundary_consume_meta_arg(a, callee) for a in args)
            if kwargs and any(isinstance(v, _WatchedM) for v in kwargs.values()):
                kwargs = {
                    k: _pyir_boundary_consume_meta_arg(v, callee)
                    for k, v in kwargs.items()
                }
            watch = _pyir_global_write_watch(callee)
            result = callee(*args, **kwargs)
            _pyir_global_write_check(watch)
            return result
        return callee(*args, **kwargs)


def _pyir_boundary_consume_meta_arg(value: Any, callee: Any = None) -> Any:
    """Record one watched-META consumption at the funnel and return the plain
    payload; a promoted place holds no trace-time constant, so it refuses."""
    if not isinstance(value, _WatchedM):
        return value
    slot_key = value._slot_key
    if slot_key is not None and _slot_refs.get(slot_key) is not None:
        filename, lineno = _first_non_dsl_caller_location()
        callee_name = getattr(callee, "__name__", None) if callee is not None else None
        raise DSLUserCodeError(
            DiagId.ATTR_BUILDER_REQUIRES_CONSTANT,
            filename=filename,
            lineno=lineno,
            callee=callee_name or "this MLIR builder call",
            var=str(slot_key[-1]) if isinstance(slot_key, tuple) else str(slot_key),
        )
    value._record_structural_consumption()
    return value._pyir_raw_payload


# -- Reflection-primitive routing (F-STORE / F-READ arm): Python's own fixed
# attribute vocabulary, keyed by FUNCTION-OBJECT identity, routed to the
# read/write chokes with owner = arg0 and slot = the runtime-exact string.


def _pyir_reflect_storage_owner(obj: Any, name: str) -> Any:
    """The namespace owner a runtime-named attribute access resolves to: the
    instance for instance storage, the defining class for a class-level data
    attribute (F-SHAPE), ``None`` for computed attributes (place is ⊥)."""
    if obj is None or _is_staged_value(obj) or isinstance(obj, _WatchedM):
        return None
    if not isinstance(obj, type):
        items = _instance_storage_items(obj)
        if items is not None and name in items:
            return obj
    mro = getattr(obj if isinstance(obj, type) else type(obj), "__mro__", ())
    for klass in mro:
        if name in klass.__dict__:
            if name in _pyir_class_facts.class_storage_items(klass):
                return klass
            return None  # descriptor / dunder / nested class: computed
    return None


def _pyir_routed_getattr(obj: Any, name: Any, *default: Any) -> Any:
    """Routed ``getattr``: the native dereference is Python truth; a storage hit
    re-resolves through the read choke (records the read, loads live cells); a
    hit that resolves to NO storage slot is judged as a fabricated read; a
    tolerated default-taken MISS seals an absence row (the bake depends on the
    name staying absent)."""
    try:
        cur = getattr(obj, name)
    except AttributeError:
        if not default:
            raise
        if _pyir_boundary_trace_active() and isinstance(name, str):
            _pyir_spec_record_attr_probe(obj, name, present=False)
        return default[0]
    if not _pyir_boundary_trace_active() or not isinstance(name, str):
        return cur
    owner = _pyir_reflect_storage_owner(obj, name)
    if owner is None:
        _pyir_judge_fabricated_attr_read(obj, name, cur)
        return cur
    return pyir_read(f"<getattr>.{name}", cur, owner=owner, slot_name=name)


def _pyir_routed_hasattr(obj: Any, name: Any) -> bool:
    """Routed ``hasattr`` (CPython's own algorithm: one ``getattr``, catching
    AttributeError): both answers seal a presence/absence probe row (the bake
    is the boolean, never the value), and a computed hit is judged like the
    getattr leg; the boolean answer is Python's."""
    try:
        cur = getattr(obj, name)
    except AttributeError:
        if _pyir_boundary_trace_active() and isinstance(name, str):
            _pyir_spec_record_attr_probe(obj, name, present=False)
        return False
    if _pyir_boundary_trace_active() and isinstance(name, str):
        if _pyir_reflect_storage_owner(obj, name) is None:
            _pyir_judge_fabricated_attr_read(obj, name, cur)
        # Presence of a region-conditional first-def is path-dependent: same
        # read-before-set refusal as a value read.
        _pyir_check_cf_attr_first_def_read(obj, name)
        _pyir_spec_record_attr_probe(obj, name, present=True)
    return True


def _pyir_reflect_store(setter: Any, obj: Any, name: Any, value: Any) -> None:
    """Routed attribute store: the native write runs first (Python truth), then
    a STORAGE write replays through the write choke at this position -- the
    same lifecycle as an instrumented ``obj.name = value``."""
    if not _pyir_boundary_trace_active() or not isinstance(name, str):
        setter(obj, name, value)
        return
    pre = _pyir_boundary_current_value(obj, name)
    setter(obj, name, value)
    if _pyir_boundary_current_value(obj, name) is not value:
        return  # a descriptor rerouted the store: not a storage write here
    label = f"<setattr>.{name}"
    filename, lineno = _first_non_dsl_caller_location()
    old = (
        None
        if pre is _PYIR_BOUNDARY_MISSING
        else pyir_read(label, pre, owner=obj, slot_name=name)
    )
    result = pyir_assign(label, old, value, filename, lineno, owner=obj, slot_name=name)
    if result is not value:
        _pyir_holder_store(obj, name, result)
    # Meta first-def through reflection: record the binding position (a
    # staged first-def records through the assign choke).
    if pre is _PYIR_BOUNDARY_MISSING and not _is_staged_value(value):
        _pyir_record_cf_attr_first_def(obj, name)


def _pyir_routed_setattr(obj: Any, name: Any, value: Any) -> None:
    _pyir_reflect_store(setattr, obj, name, value)


def _pyir_routed_object_setattr(obj: Any, name: Any, value: Any) -> None:
    _pyir_reflect_store(_pyir_setattr_raw, obj, name, value)


def _pyir_delete_attr(obj: Any, name: Any) -> None:
    """The one attribute-deletion funnel (syntactic ``del obj.name`` and routed
    ``delattr``; LangRef 3.12 sections 7.5 and 3.3.2): deletion is an
    unstageable binding effect, so inside dynamic staged CF it cannot be
    predicated on the region's runtime condition and refuses loudly.  In meta
    flow the native delete runs first (Python truth, honoring ``__delattr__``
    and descriptors), then the ledger row dies with the binding (W2) and a
    rooted place seals trace-exit ABSENCE (F-SPEC)."""
    if not _pyir_boundary_trace_active() or not isinstance(name, str):
        delattr(obj, name)
        return
    if is_inside_staged_cf():
        filename, lineno = _first_non_dsl_caller_location()
        raise DSLUserCodeError(
            DiagId.UNSUP_DEL_IN_STAGED_CF,
            filename=filename,
            lineno=lineno,
            obj=obj.__name__ if isinstance(obj, type) else type(obj).__name__,
            attr=name,
        )
    delattr(obj, name)
    _pyir_retire_place_row(None, obj, name)
    _pyir_spec_record_unbind(obj, name)


def _pyir_routed_delattr(obj: Any, name: Any) -> None:
    """Routed ``delattr``: the same funnel as an instrumented ``del obj.name``
    (one choke for both spellings, by construction)."""
    _pyir_delete_attr(obj, name)


def _pyir_import_guard(
    stmt: str, module: "str | None", level: int, package: "str | None", *names: str
) -> None:
    """Staged-CF wall ahead of an in-body import statement (LangRef 3.12
    section 7.11): a FIRST import executes the module's code once at trace
    time, a side effect that cannot be predicated on a staged region's
    runtime condition -- inside dynamic staged CF it refuses loudly, before
    that code runs.  A pure module-cache hit (section 5.3.1) executes no
    module code and passes: its bindings are ordinary meta reads, recorded
    as spec roots.  Meta flow passes through untouched."""
    if not _pyir_boundary_trace_active() or not is_inside_staged_cf():
        return
    if _pyir_import_is_cached(module, level, names, package):
        return
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.UNSUP_IMPORT_IN_STAGED_CF,
        filename=filename,
        lineno=lineno,
        stmt=stmt,
    )


_PYIR_GLOBAL_WRITE_SCANS: "dict[Any, str | None]" = {}


def _pyir_callee_global_write(callee: Any) -> "str | None":
    """Name of the first module global the callee's OWN bytecode writes
    (STORE_GLOBAL/DELETE_GLOBAL; one frame deep by construction), or None.
    Only user-module callees report -- a DSL/stdlib global write is trace-time
    machinery, not carried program state."""
    func = getattr(callee, "__func__", callee)
    code = getattr(func, "__code__", None)
    if code is None:
        return None
    if code in _PYIR_GLOBAL_WRITE_SCANS:
        return _PYIR_GLOBAL_WRITE_SCANS[code]
    name = None
    if _pyir_boundary_module_is_user(getattr(func, "__module__", None)):
        for ins in _dis.get_instructions(code):
            if ins.opname in ("STORE_GLOBAL", "DELETE_GLOBAL"):
                name = str(ins.argval)
                break
    _PYIR_GLOBAL_WRITE_SCANS[code] = name
    return name


def _pyir_global_write_guard(callee: Any) -> None:
    """Staged-CF wall ahead of a callee that writes a module global: the write
    executes once at trace time, not once per runtime iteration, so every
    later read of that global is frozen at its first traced value.  Constexpr
    regions unroll at trace time (the callee really runs per iteration) and
    pass; so does straight-line code (one execution, one write)."""
    if not is_inside_staged_cf() or is_inside_constexpr_loop():
        return
    name = _pyir_callee_global_write(callee)
    if name is None:
        return
    func = getattr(callee, "__func__", callee)
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.UNSUP_GLOBAL_WRITE_IN_STAGED_CF,
        filename=filename,
        lineno=lineno,
        callee=getattr(func, "__qualname__", None) or "the called function",
        name=name,
    )


def _pyir_global_write_watch(callee: Any) -> "tuple | None":
    """Pre-call half of the two-hop backstop: for a user-module callee inside
    dynamic staged CF, capture the callee's module dict and its current
    bindings, so a transitive global write (invisible to the one-frame
    bytecode scan) is caught as a changed binding after the call."""
    if not is_inside_staged_cf() or is_inside_constexpr_loop():
        return None
    func = getattr(callee, "__func__", callee)
    mod = getattr(func, "__module__", None)
    if mod is None or not _pyir_boundary_module_is_user(mod):
        return None
    d = getattr(_sys.modules.get(mod), "__dict__", None)
    if d is None:
        return None
    before = {k: v for k, v in d.items() if not k.startswith("__")}
    return (callee, d, before)


def _pyir_global_write_check(watch: "tuple | None") -> None:
    """Post-call half of the two-hop backstop: refuse on any rebound, added,
    or deleted module-global binding (in-place container mutation does not
    rebind and passes)."""
    if watch is None:
        return
    callee, d, before = watch
    changed = None
    for k, v in d.items():
        if not k.startswith("__") and (k not in before or before[k] is not v):
            changed = k
            break
    if changed is None:
        for k in before:
            if k not in d:
                changed = k
                break
        if changed is None:
            return
    func = getattr(callee, "__func__", callee)
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.UNSUP_GLOBAL_WRITE_IN_STAGED_CF,
        filename=filename,
        lineno=lineno,
        callee=getattr(func, "__qualname__", None) or "the called function",
        name=changed,
    )


def _pyir_import_record(
    module: "str | None", level: int, package: "str | None", *pairs: tuple
) -> None:
    """Record arm behind an executed in-body import (meta flow): each bound
    name becomes a verified spec root (F-SPEC).  ``module is None, level 0``
    is the plain-``import`` form; *package* (the defining module's declared
    package, a rewrite-time constant) anchors a relative ``from``-import
    exactly as the import system resolved it."""
    if not _pyir_boundary_trace_active():
        return
    _pyir_spec_record_import(module, level, pairs, package)


def _pyir_routed_vars(*args: Any) -> Any:
    """Routed ``vars``: each instance-storage leaf read is recorded through the
    read choke, and the returned mapping funnels through the same read choke as
    an ``obj.__dict__`` attr read (``vars(obj)`` IS ``obj.__dict__`` -- one
    adoption funnel, so writes into it carry instead of silently dropping)."""
    if not args:
        # Zero-arg ``vars()`` is the CALLER's locals; evaluating it here would
        # name this frame instead.
        return _sys._getframe(1).f_locals
    result = vars(*args)
    if _pyir_boundary_trace_active() and isinstance(result, dict):
        obj = args[0]
        if not (_is_staged_value(obj) or isinstance(obj, _WatchedM)):
            for k, v in list(result.items()):
                if isinstance(k, str) and not k.startswith("__"):
                    pyir_read(f"<vars>.{k}", v, owner=obj, slot_name=k)
            result = pyir_read("<vars>", result, owner=obj, slot_name="__dict__")
    return result


def _pyir_routed_attrgetter(*names: Any) -> Any:
    """Routed ``operator.attrgetter``: the returned getter resolves each hop
    through the routed ``getattr`` while a trace is active."""
    native = _operator.attrgetter(*names)  # native validation of the names

    def _get_path(obj: Any, dotted: str) -> Any:
        for hop in dotted.split("."):
            obj = _pyir_routed_getattr(obj, hop)
        return obj

    def _routed_getter(obj: Any) -> Any:
        if not _pyir_boundary_trace_active():
            return native(obj)
        if len(names) == 1:
            return _get_path(obj, names[0])
        return tuple(_get_path(obj, n) for n in names)

    return _routed_getter


class _PyirSynthLocalsView(dict):
    """``locals()`` mapping of a SYNTHESIZED scope (a rewritten if/ifexp/while
    arm holds only the names it rebinds, carried as parameters): a HIT is the
    live carried value (Python truth); a MISS or an enumeration cannot be
    answered from the partial view, so it refuses loudly instead of silently
    diverging from the source program's full-scope ``locals()``."""

    def _refuse(self, name: Any) -> Any:
        filename, lineno = _first_non_dsl_caller_location()
        raise DSLUserCodeError(
            DiagId.SCOPE_LOCALS_SYNTH_MISS,
            filename=filename,
            lineno=lineno,
            name=str(name),
        )

    def __getitem__(self, key: Any) -> Any:
        if dict.__contains__(self, key):
            return dict.__getitem__(self, key)
        return self._refuse(key)

    def get(self, key: Any, default: Any = None) -> Any:
        if dict.__contains__(self, key):
            return dict.__getitem__(self, key)
        return self._refuse(key)

    def __contains__(self, key: Any) -> bool:
        if dict.__contains__(self, key):
            return True
        return bool(self._refuse(key))

    def _refuse_enumeration(self) -> Any:
        return self._refuse("<enumerating the synthesized scope>")

    def __iter__(self) -> Any:
        return self._refuse_enumeration()

    def __len__(self) -> int:
        return int(self._refuse_enumeration())

    def keys(self) -> Any:  # type: ignore[override]
        return self._refuse_enumeration()

    def items(self) -> Any:  # type: ignore[override]
        return self._refuse_enumeration()

    def values(self) -> Any:  # type: ignore[override]
        return self._refuse_enumeration()

    def __repr__(self) -> str:
        return "<synthesized-scope locals() view>"


def _pyir_traced_locals(mapping: Any, callee: Any, in_synth: bool) -> Any:
    """Choke for a bare zero-arg ``locals()``/``vars()`` in a rewritten body
    (library ref section `vars`: zero-arg ``vars()`` == ``locals()``).  At
    function scope the frame mapping keeps source names live (pass-through);
    in a preprocessor-SYNTHESIZED arm scope the mapping is a partial view, so
    lookups are guarded (hit = truth, miss/enumeration = loud).  A shadowed
    builtin name keeps whatever the shadow returned (Python truth)."""
    if callee is not _builtins.locals and callee is not _builtins.vars:
        return mapping
    if not in_synth or not isinstance(mapping, dict):
        return mapping
    if not _pyir_boundary_trace_active():
        return mapping
    return _PyirSynthLocalsView(mapping)


def _pyir_routed_dict_view(view: Any) -> Any:
    """Routed unbound ``dict.keys/values/items`` (``dict.items(d)``): the
    bound spelling routes at the dispatcher's receiver check; the unbound
    base-class call carries the receiver as ``args[0]`` and must hit the same
    iteration choke before the view raw-iterates storage.  Machinery's direct
    raw walks never dispatch through the boundary, so they stay unobserved."""

    def _routed(*args: Any, **kwargs: Any) -> Any:
        if (
            args
            and isinstance(args[0], _WatchedDict)
            and _WATCHED_DICT_ITER_HOOK[0] is not None
        ):
            served = _WATCHED_DICT_ITER_HOOK[0](args[0], f".{view.__name__}()")
            if served is not None:
                return served
        return view(*args, **kwargs)

    return _routed


# The Python-fixed primitive set, keyed by function-object identity (the
# primitives are immortal; the id key can never be recycled under them).
_PYIR_REFLECTION_ROUTES: "dict[int, tuple[Any, Any]]" = {
    id(prim): (prim, router)
    for prim, router in (
        (getattr, _pyir_routed_getattr),
        (setattr, _pyir_routed_setattr),
        (delattr, _pyir_routed_delattr),
        (hasattr, _pyir_routed_hasattr),
        (object.__setattr__, _pyir_routed_object_setattr),
        (vars, _pyir_routed_vars),
        (_operator.attrgetter, _pyir_routed_attrgetter),
        (dict.keys, _pyir_routed_dict_view(dict.keys)),
        (dict.values, _pyir_routed_dict_view(dict.values)),
        (dict.items, _pyir_routed_dict_view(dict.items)),
    )
}


def _pyir_routed_reduce(*args: Any, **kwargs: Any) -> Any:
    """Routed ``functools.reduce``: the callee argument crosses a HOF boundary,
    so every application dispatches through the standard call boundary."""
    if args:
        args = (_pyir_call_boundary_(args[0]),) + args[1:]
    elif "function" in kwargs:
        kwargs = {**kwargs, "function": _pyir_call_boundary_(kwargs["function"])}
    return _functools.reduce(*args, **kwargs)


# Stdlib higher-order drivers whose CALLEE argument must cross the boundary,
# keyed by function-object identity exactly like the reflection routes.
_PYIR_HOF_ROUTES: "dict[int, tuple[Any, Any]]" = {
    id(_functools.reduce): (_functools.reduce, _pyir_routed_reduce),
}


def _pyir_routed_clevel_mutator(fn: Any, spelling: str) -> Any:
    """Routed C-implemented stdlib container mutator (the ``heapq`` module
    functions / ``bisect.insort`` family): the mutation happens inside C
    code, so it performs no Python-level attribute call or subscript store
    for the method guard or the subscript-write choke to see -- a silent
    trace-time freeze.  Refuse when a meta list/deque argument would be
    mutated inside dynamic staged CF; otherwise delegate to the standard
    unwrap funnel."""
    funnel = _PyirMetaUnwrapProxy(fn)
    module_name, _, func_name = spelling.rpartition(".")

    def _routed(*args: Any, **kwargs: Any) -> Any:
        if is_inside_staged_cf() and not is_inside_constexpr_loop():
            # Every routed function mutates ONLY its first argument (the
            # heap / the sorted sequence; ``bisect.insort`` also accepts it
            # as keyword ``a``).  An item argument that happens to be a
            # list (``heappush(heap, [k, v])``) is stored, never mutated.
            # The heapq routes are C-enforced list-only; the insort family
            # also mutates any duck-typed sequence through ``.insert``.
            mutated = args[0] if args else kwargs.get("a")
            if isinstance(mutated, (list, _collections.deque)) or (
                module_name == "bisect" and hasattr(mutated, "insert")
            ):
                filename, lineno = _first_non_dsl_caller_location()
                raise DSLUserCodeError(
                    DiagId.UNSUP_META_CONTAINER_MUTATION,
                    filename=filename,
                    lineno=lineno,
                    container=module_name,
                    method=func_name,
                    kind=(
                        "deque"
                        if isinstance(mutated, _collections.deque)
                        else "list"
                        if isinstance(mutated, list)
                        else type(mutated).__name__
                    ),
                )
        return funnel(*args, **kwargs)

    return _routed


# C-implemented stdlib functions that mutate a caller-owned container
# argument in place, keyed by function-object identity like the reflection
# routes (the table tuple holds the function, so its id cannot be recycled).
# ``bisect.insort`` aliases ``insort_right``; it is listed LAST so the
# diagnostic shows the spelling users overwhelmingly write.  The max-heap
# names are version-dependent, hence the getattr walk.
_PYIR_CLEVEL_MUTATOR_ROUTES: "dict[int, tuple[Any, Any]]" = {
    id(fn): (fn, _pyir_routed_clevel_mutator(fn, f"{mod_name}.{name}"))
    for mod, mod_name, names in (
        (
            _heapq,
            "heapq",
            (
                "heapify",
                "heappush",
                "heappop",
                "heappushpop",
                "heapreplace",
                "_heapify_max",
                "_heappop_max",
                "_heapreplace_max",
                "heapify_max",
                "heappush_max",
                "heappop_max",
                "heappushpop_max",
                "heapreplace_max",
            ),
        ),
        (_bisect, "bisect", ("insort_left", "insort_right", "insort")),
    )
    for name in names
    if (fn := getattr(mod, name, None)) is not None
}
# A comprehension's loop variables are comprehension-local, but a walrus
# target binds in the ENCLOSING scope (PEP 572) -- without this, ``fn``
# leaks into the module namespace and rides the export chain.
del fn


# Receiver-carrying spellings of a deque mutation: the method-name guard
# tables key on attribute-call SYNTAX, so an aliased bound method
# (``push = q.append; push(x)``) and the in-place dunders (``q += .../q *=
# ...`` route ``deque.__iadd__``/``__imul__`` through this dispatcher via
# ``_pyir_inplace_binop``) would otherwise mutate silently -- a plain deque
# is never adopted as a watched container, so no object-side choke exists.
_PYIR_DEQUE_BOUND_MUTATORS = _PYIR_DEQUE_MUTATORS | {"__iadd__", "__imul__"}


def _pyir_wrapped_user_module(func: Any) -> "str | None":
    """WRAPPER fact: the first user module on *func*'s ``__wrapped__`` chain
    (the ``functools.update_wrapper`` identity); None when the chain has none."""
    seen: "set[int]" = set()
    target = getattr(func, "__wrapped__", None)
    while target is not None and id(target) not in seen:
        seen.add(id(target))
        mod = getattr(target, "__module__", None)
        if _pyir_boundary_module_is_user(mod):
            return mod
        target = getattr(target, "__wrapped__", None)
    return None


def _pyir_refuse_memoized_callee(func: Any) -> None:
    """Curated wall: a memoized user callee under staged CF skips its body on
    a cache hit, so its effects can never replay per runtime execution."""
    filename, lineno = _first_non_dsl_caller_location()
    raise DSLUserCodeError(
        DiagId.BOUNDARY_MEMOIZED_IN_STAGED_CF,
        filename=filename,
        lineno=lineno,
        name=getattr(func, "__name__", "this function"),
    )


def _pyir_call_boundary_(callee: Any, sc_rhs: bool = False) -> Any:
    """Trace-time dispatcher: proxy a plain user-module callable, return anything
    else unchanged; *sc_rhs* marks a short-circuited operand (effects refuse)."""
    try:
        func = getattr(callee, "__func__", callee)
        # Memoized wall: an lru_cache hit skips the wrapped USER body, so its
        # effects can never replay per runtime execution of a staged region.
        if (
            isinstance(func, _functools._lru_cache_wrapper)
            and _pyir_boundary_module_is_user(
                getattr(getattr(func, "__wrapped__", None), "__module__", None)
            )
            and is_inside_staged_cf()
        ):
            _pyir_refuse_memoized_callee(func)
        # Tracked-dict view iteration (``d.keys()/.values()/.items()``): the
        # views raw-iterate storage, so pair/value consumption would bypass
        # the item read choke -- a trace-time snapshot.  User calls all route
        # through this dispatcher; inside dynamic staged CF the hook serves
        # ``.values()/.items()`` through the per-entry read choke (the
        # carried slot reads) and refuses a key set changed inside the region
        # (bare ``for k in d`` routes at the object-side ``__iter__``).
        _iter_recv = getattr(callee, "__self__", None)
        if (
            isinstance(_iter_recv, _WatchedDict)
            and getattr(callee, "__name__", None) in ("keys", "values", "items")
            and _WATCHED_DICT_ITER_HOOK[0] is not None
        ):
            _iter_callee = callee

            def _routed_bound_view() -> Any:
                served = _WATCHED_DICT_ITER_HOOK[0](
                    _iter_recv, f".{_iter_callee.__name__}()"
                )
                return _iter_callee() if served is None else served

            return _routed_bound_view
        # Deque mutator reached through the callable's own receiver (bound
        # method alias, or the in-place dunder ``_pyir_inplace_binop``
        # dispatches here): refuse inside dynamic staged CF exactly like the
        # attribute-call guard; trace-time and constexpr mutation stay legal.
        if (
            isinstance(_iter_recv, _collections.deque)
            and getattr(callee, "__name__", None) in _PYIR_DEQUE_BOUND_MUTATORS
            and is_inside_staged_cf()
            and not is_inside_constexpr_loop()
        ):
            filename, lineno = _first_non_dsl_caller_location()
            raise DSLUserCodeError(
                DiagId.UNSUP_META_CONTAINER_MUTATION,
                filename=filename,
                lineno=lineno,
                container="deque",
                method=callee.__name__,
                kind="deque",
            )
        # Jit-decorated / DSL-preprocessed callables trace anyway.
        if (
            hasattr(func, "_preprocessed")
            or hasattr(func, "_dsl_cls")
            or hasattr(func, "_dsl_object")
            or _pyir_callee_is_rewritten(func)
        ):
            return callee
        if isinstance(callee, (_PyirCallBoundaryProxy, _PyirMetaUnwrapProxy)):
            return callee
        if not callable(callee):
            return callee
        # functools.partial: identity and observation belong to ``.func``; the
        # frozen args re-enter the dispatched callee as ordinary call args.
        # An unchanged ``.func`` (jit / wrapper-consumer fast exit) keeps the
        # partial's own stdlib classification below (the unwrap funnel).
        if type(callee) is _functools.partial:
            inner = _pyir_call_boundary_(callee.func, sc_rhs)
            if inner is not callee.func:
                return _functools.partial(inner, *callee.args, **callee.keywords)
        # Reflection primitives route to the chokes by function-object identity.
        route = _PYIR_REFLECTION_ROUTES.get(id(func))
        if route is not None and route[0] is func:
            return route[1]
        route = _PYIR_HOF_ROUTES.get(id(func))
        if route is not None and route[0] is func:
            return route[1]
        route = _PYIR_CLEVEL_MUTATOR_ROUTES.get(id(func))
        if route is not None and route[0] is func:
            return route[1]
        # ``dataclasses.replace`` is a stdlib REBUILD shim: it forwards field
        # values untouched into the class's generated ``__init__``, so watched
        # meta fields must SURVIVE the call (the ctor-rebind carry keys on
        # them).  Classify it like the user ctor call it wraps, not like an
        # opaque stdlib callee the unwrap funnel de-watches.
        if func is _dataclasses.replace:
            return _PyirCallBoundaryProxy(callee, sc_rhs)
        mod = getattr(func, "__module__", None)
        if not _pyir_boundary_module_is_user(mod):
            if _pyir_boundary_module_consumes_wrappers(mod):
                return callee
            # A wrapper masking a user target (``__wrapped__``) is classified
            # by the target: its interior user-frame writes must be observed.
            wrapped_mod = _pyir_wrapped_user_module(func)
            if wrapped_mod is None:
                return _PyirMetaUnwrapProxy(callee)
            mod = wrapped_mod
        # A plain callee's module may carry no jit decoration; funnel it
        # through the class-facts materializer so write facts exist by commit.
        _pyir_class_facts.ensure_module_materialized(mod)
        return _PyirCallBoundaryProxy(callee, sc_rhs)
    except DSLUserCodeError:
        raise
    except Exception as exc:
        # Fail-loud wall: a swallowed classification failure would silently
        # skip observation, so the callee's effects replay unpredicated.
        raise DSLRuntimeError(
            "PyIR emission self-check: call-boundary classification failed "
            f"for a callee of type {type(callee).__name__}: {exc}"
        ) from exc


# -- In-place operator routing: an AugAssign dispatches its dunder with no
# ast.Call, so the wrap pass cannot reach it; the preprocessor rewrites the
# statement into this helper, which resolves the in-place slot exactly like
# CPython and routes the bound dunder through the SAME boundary dispatcher.

_PYIR_INPLACE_OPS: "dict[str, tuple[str, Any, Any]]" = {
    "add": ("__iadd__", _operator.add, _operator.iadd),
    "sub": ("__isub__", _operator.sub, _operator.isub),
    "mul": ("__imul__", _operator.mul, _operator.imul),
    "matmul": ("__imatmul__", _operator.matmul, _operator.imatmul),
    "truediv": ("__itruediv__", _operator.truediv, _operator.itruediv),
    "floordiv": ("__ifloordiv__", _operator.floordiv, _operator.ifloordiv),
    "mod": ("__imod__", _operator.mod, _operator.imod),
    "pow": ("__ipow__", _operator.pow, _operator.ipow),
    "lshift": ("__ilshift__", _operator.lshift, _operator.ilshift),
    "rshift": ("__irshift__", _operator.rshift, _operator.irshift),
    "or": ("__ior__", _operator.or_, _operator.ior),
    "xor": ("__ixor__", _operator.xor, _operator.ixor),
    "and": ("__iand__", _operator.and_, _operator.iand),
}

# Exact types whose in-place slots are C code: the native protocol IS the
# routed protocol (no user frame can hide behind them).
_PYIR_INPLACE_NATIVE_TYPES = frozenset(
    (
        int,
        float,
        bool,
        complex,
        str,
        bytes,
        bytearray,
        list,
        tuple,
        dict,
        set,
        frozenset,
        type(None),
    )
)


# Property-family attribute stores: the SETTER is class code invoked by the
# interpreter's setattr with no ast.Call; the preprocessor funnels the store
# here so the bound setter routes through the same boundary dispatcher.

_PYIR_PROPERTY_SETTERS: "dict[tuple[type, str], Any]" = {}


def _pyir_property_setter(cls: type, name: str) -> Any:
    """The property setter *name* resolves to on *cls* (mro-exact, cached);
    ``None`` for ordinary storage attributes and non-property descriptors."""
    key = (cls, name)
    if key in _PYIR_PROPERTY_SETTERS:
        return _PYIR_PROPERTY_SETTERS[key]
    fset = None
    for klass in cls.__mro__:
        if name in vars(klass):
            desc = vars(klass)[name]
            if isinstance(desc, property):
                fset = desc.fset
            break
    _PYIR_PROPERTY_SETTERS[key] = fset
    return fset


_PYIR_SETATTR_OVERRIDES: "dict[type, Any]" = {}


def _pyir_user_setattr_override(cls: type) -> Any:
    """The user-authored, value-TRANSFORMING ``__setattr__`` governing stores
    on *cls* instances (mro-exact, cached); ``None`` when stores are plain or
    provably storage-transparent.  DSL-internal overrides (struct field
    guards, holder write clocks) and transparent user redirects stay on the
    rewritten-choke path -- its re-binds replay the override, which is only
    safe when the override stores the unmodified value."""
    if cls in _PYIR_SETATTR_OVERRIDES:
        return _PYIR_SETATTR_OVERRIDES[cls]
    override = None
    for klass in cls.__mro__:
        if klass is object:
            break
        fn = vars(klass).get("__setattr__")
        if fn is not None:
            if _pyir_boundary_module_is_user(
                getattr(fn, "__module__", None)
            ) and not _pyir_class_facts.setattr_storage_transparent(fn):
                override = fn
            break
    _PYIR_SETATTR_OVERRIDES[cls] = override
    return override


def _pyir_is_property_store(obj: Any, name: str) -> bool:
    """Pure target fact: does storing ``obj.name`` invoke user-defined store
    code (a property setter or a user ``__setattr__`` override)?  Decides the
    store branch BEFORE the RHS evaluates (native order keeps the RHS after
    the tracer's pre-store refresh)."""
    return (
        _pyir_user_setattr_override(type(obj)) is not None
        or _pyir_property_setter(type(obj), name) is not None
    )


def _pyir_property_store(obj: Any, name: str, value: Any) -> None:
    """Route a store with user-defined store code through it exactly once at
    the call boundary (observed, predicated commit of the storage writes).
    A ``__setattr__`` override wins over a property, as in CPython; a
    setter-less property raises the native AttributeError."""
    override = _pyir_user_setattr_override(type(obj))
    if override is not None:
        _pyir_call_boundary_(override.__get__(obj, type(obj)))(name, value)
        return
    fset = _pyir_property_setter(type(obj), name)
    if fset is None:
        setattr(obj, name, value)
        return
    _pyir_call_boundary_(fset.__get__(obj, type(obj)))(value)


def _pyir_inplace_binop(op: str, lhs: Any, rhs: Any) -> Any:
    """``lhs op= rhs`` VALUE semantics (CPython's in-place protocol) with the
    resolved dunder routed through the call boundary, so a user-class
    ``__iadd__`` mutating its receiver is observed like any boundary call."""
    dunder, binop, native = _PYIR_INPLACE_OPS[op]
    if type(lhs) in _PYIR_INPLACE_NATIVE_TYPES:
        return native(lhs, rhs)
    # _PyType_Lookup semantics: the slot lives on the type's mro, never on the
    # instance, and type-level ``__getattr__`` does not participate.
    slot = None
    for klass in type(lhs).__mro__:
        if dunder in vars(klass):
            slot = vars(klass)[dunder]
            break
    if slot is None:
        return binop(lhs, rhs)
    if hasattr(type(slot), "__get__"):
        bound = slot.__get__(lhs, type(lhs))
        result = _pyir_call_boundary_(bound)(rhs)
    else:
        result = slot(lhs, rhs)
    if result is NotImplemented:
        return binop(lhs, rhs)
    return result


# -- ARGUMENT fact: does the call receive / close over tracked state?

_PYIR_BOUNDARY_PASSTHROUGH_TYPES = (
    int,
    float,
    bool,
    complex,
    str,
    bytes,
    type(None),
)


def _pyir_boundary_value_tracked(
    obj: Any, _known_untracked: "set[int] | None" = None
) -> bool:
    """Registry lookup: is *obj* state the tracer has already modeled (slot or
    candidate holder, adopted container, slot-backed wrapper, or element)?
    The gate covers the snapshot walk's whole reachability domain —
    containers, instance storage, user-module class objects — iteratively and
    unbounded (a bounded proxy would silently skip observation).

    *_known_untracked* shares work across the probes of one root-collection
    pass: a probe that returns False explored its whole reachable set, so its
    visited ids provably reach no tracked state and later probes skip them.
    Only completed-False knowledge is shared -- an early-True probe abandons
    its stack, so its visited set proves nothing and is discarded."""
    stack: "list[Any]" = [obj]
    visited: "set[int]" = set()
    while stack:
        cur = stack.pop()
        if cur is None or type(cur) in _PYIR_BOUNDARY_PASSTHROUGH_TYPES:
            continue
        if isinstance(cur, (_WatchedDict, _WatchedList, _WatchedM)):
            return True
        oid = id(cur)
        if oid in _PYIR_SLOT_HOLDERS or oid in _PYIR_CANDIDATE_HOLDERS:
            return True
        if oid in visited or (_known_untracked is not None and oid in _known_untracked):
            continue
        visited.add(oid)
        if isinstance(cur, (ir.Value, _types.ModuleType)):
            continue
        if isinstance(cur, type):
            # A user-module class object is observable state in its own
            # right: its class-level data attributes are boundary places
            # (classmethod receivers and class arguments root the diff).
            if _pyir_boundary_module_is_user(getattr(cur, "__module__", None)):
                return True
            continue
        if isinstance(cur, dict):
            stack.extend(list(dict.values(cur)))
            continue
        if isinstance(cur, (list, tuple)):
            stack.extend(list(cur))
            continue
        try:
            if getattr(cur, "_mutable_ref", None) is not None:
                return True
        except Exception:
            continue
        items = _instance_storage_items(cur)
        if items:
            stack.extend(list(items.values()))
    if _known_untracked is not None:
        _known_untracked.update(visited)
    return False


def _pyir_boundary_default_walk_root(d: Any) -> bool:
    """Mutable-shaped default objects the snapshot observes directly: a plain
    dict/list (or a tuple reaching one) and user-module-class instances;
    scalar, staged, watched, class, and module shapes stay gate-filtered."""
    if d is None or type(d) in _PYIR_BOUNDARY_PASSTHROUGH_TYPES:
        return False
    if isinstance(d, (_WatchedDict, _WatchedList, _WatchedM, ir.Value)):
        return False
    if isinstance(d, (dict, list)):
        return True
    if isinstance(d, tuple):
        return any(_pyir_boundary_default_walk_root(v) for v in d)
    if isinstance(d, (type, _types.ModuleType)) or _is_staged_value(d):
        return False
    return (
        _pyir_boundary_module_is_user(getattr(type(d), "__module__", None))
        and _instance_storage_items(d) is not None
    )


def _pyir_boundary_tracked_roots(
    callee: Any, args: "tuple", kwargs: "dict"
) -> "list[Any]":
    """Roots reachable from the call: receiver, args, kwargs values, closure
    cell contents, and the callee's taken parameter defaults -- filtered by
    the tracked-state registry fact (mutable-shaped taken defaults join
    unconditionally: they are only reachable through the callee)."""
    roots: "list[Any]" = []
    recv = getattr(callee, "__self__", None)
    candidates: "list[Any]" = []
    if recv is not None:
        candidates.append(recv)
    elif not isinstance(
        callee, (_types.FunctionType, _types.BuiltinFunctionType, type)
    ):
        # A callable-instance callee dispatches through ``type(callee).__call__``
        # with the instance as receiver: its storage is reachable call state.
        candidates.append(callee)
    candidates.extend(args)
    candidates.extend(kwargs.values())
    func = getattr(callee, "__func__", callee)
    closure = getattr(func, "__closure__", None)
    if closure:
        freevars = getattr(getattr(func, "__code__", None), "co_freevars", ())
        for _ci, cell in enumerate(closure):
            # The CELL itself is always a root: a ``nonlocal`` rebind lands on
            # the cell binding, the holder of its one ``cell_contents`` leg.
            if _ci < len(freevars):
                # Diagnostics-only: name the closure variable in refusals.
                _PYIR_BOUNDARY_CELL_NAMES[_owner_token(cell)] = freevars[_ci]
            roots.append(cell)
            try:
                candidates.append(cell.cell_contents)
            except ValueError:
                continue
    # Taken parameter defaults are persistent def-time state the callee binds
    # with no choke (LangRef §8.7): part of the declared observation domain.
    for _sel, _dflt in _pyir_boundary_taken_defaults(callee, args, kwargs):
        if _pyir_boundary_default_walk_root(_dflt):
            roots.append(_dflt)
        else:
            candidates.append(_dflt)
    known_untracked: "set[int]" = set()
    for cand in candidates:
        if _pyir_boundary_value_tracked(cand, known_untracked):
            roots.append(cand)
    return roots


class _PyirCtxBoundaryProxy:
    """WITH-protocol twin of :class:`_PyirCallBoundaryProxy`: observes each dunder
    like a boundary call, with the manager AND its class storage as roots."""

    __slots__ = ("_pyir_ctx_obj",)

    def __init__(self, obj: Any) -> None:
        _pyir_setattr_raw(self, "_pyir_ctx_obj", obj)

    def _pyir_observe(self, bound: Any, *args: Any) -> Any:
        obj = object.__getattribute__(self, "_pyir_ctx_obj")
        try:
            active = _pyir_boundary_trace_active()
        except Exception:
            active = False
        if not active:
            return bound(*args)
        # Same callee fact as the call boundary: a jit-decorated dunder traces
        # its own effects, so observing it would double-handle the callee.
        _fn = getattr(bound, "__func__", bound)
        if (
            hasattr(_fn, "_preprocessed")
            or hasattr(_fn, "_dsl_cls")
            or hasattr(_fn, "_dsl_object")
            or _pyir_callee_is_rewritten(_fn)
        ):
            return bound(*args)
        try:
            roots = _pyir_boundary_tracked_roots(bound, args, {})
        except Exception:
            roots = []
        roots.append(obj)
        _pyir_global_write_guard(bound)
        watch = _pyir_global_write_watch(bound)
        # The manager's class storage is in the snapshot's declared domain
        # (the ctx dispatcher already requires a user-module class).
        snapshot = _pyir_boundary_snapshot(roots)
        # The WITH protocol is a call boundary: tier 3 pre-stages the fields the
        # dunder writes, tier 2 records its meta reads, commit = standard replay.
        try:
            _pyir_reload_stale_staged_attr_leaves("ctx boundary in")
        except Exception:
            pass
        try:
            prestaged = _pyir_boundary_prestage_imminent_writes(bound, args)
        except DSLUserCodeError:
            raise  # the off-mode promotion refusal must reach the author
        except Exception:
            prestaged = []
        try:
            wrapped = _pyir_boundary_stage_meta_reads(roots)
        except Exception:
            wrapped = []
        try:
            _PYIR_BOUNDARY_CALLEE_DEPTH[0] += 1
            try:
                result = bound(*args)
            finally:
                _PYIR_BOUNDARY_CALLEE_DEPTH[0] -= 1
            _pyir_boundary_commit(bound, snapshot, result=result)
        finally:
            try:
                _pyir_boundary_restore_meta_reads(wrapped)
            except Exception:
                pass
            try:
                _pyir_boundary_restore_prestage(prestaged)
            except Exception:
                pass
        _pyir_global_write_check(watch)
        return result

    def __enter__(self) -> Any:
        obj = object.__getattribute__(self, "_pyir_ctx_obj")
        return self._pyir_observe(obj.__enter__)

    def __exit__(self, exc_type: Any, exc: Any, tb: Any) -> Any:
        obj = object.__getattribute__(self, "_pyir_ctx_obj")
        return self._pyir_observe(obj.__exit__, exc_type, exc, tb)


def _pyir_ctx_boundary(obj: Any) -> Any:
    """Trace-time dispatcher for the WITH-protocol boundary; a dispatch failure
    falls back to the unwrapped manager (see :class:`_PyirCtxBoundaryProxy`)."""
    try:
        if not _pyir_boundary_trace_active():
            return obj
        if isinstance(obj, _PyirCtxBoundaryProxy):
            return obj
        cls = type(obj)
        # DSL-authored managers trace their own effects.
        if hasattr(cls, "_dsl_cls") or hasattr(cls, "_dsl_object"):
            return obj
        if not _pyir_boundary_module_is_user(getattr(cls, "__module__", None)):
            return obj
        if not (hasattr(cls, "__enter__") and hasattr(cls, "__exit__")):
            return obj
        return _PyirCtxBoundaryProxy(obj)
    except Exception:
        return obj


def _pyir_boundary_record_meta_cell_reads(callee: Any) -> None:
    """Record each plain-meta closure cell of *callee* by the CELL's owner
    token: a later staged write of a local backed by the same cell (matched
    by cell identity, never by name) then refuses loudly at promotion."""
    if not is_inside_staged_cf():
        return
    func = getattr(callee, "__func__", callee)
    closure = getattr(func, "__closure__", None)
    if not closure:
        return
    code = getattr(func, "__code__", None)
    freevars = getattr(code, "co_freevars", ())
    for _ci, cell in enumerate(closure):
        try:
            contents = cell.cell_contents
        except ValueError:
            continue
        # A scalar shape whose closure read is invisible AND stale-able: a plain
        # primitive/_WatchedM, or a staged wrapper reading the pre-region SSA.
        _is_scalar_shape = type(contents) in (bool, int, float) or isinstance(
            contents, _WatchedM
        )
        if not _is_scalar_shape:
            try:
                _is_scalar_shape = (
                    _is_staged_value(contents)
                    and _can_carry_leaf_ref(contents)
                    and not _is_compound_single_leaf(contents)
                )
            except Exception:
                _is_scalar_shape = False
        if not _is_scalar_shape:
            continue
        name = freevars[_ci] if _ci < len(freevars) else "cell_contents"
        # F-SPEC: a closure-cell scalar read is a bake of external state; root
        # it (or mark the record incomplete when no root is derivable).
        _pyir_spec_boundary_closure_read(func, _ci, contents)
        tok = _owner_token(cell)
        if tok is not None:
            _PYIR_BOUNDARY_META_CELL_READS.setdefault(
                ("cell", tok),
                (
                    name,
                    getattr(code, "co_filename", "<call boundary>"),
                    getattr(code, "co_firstlineno", 0),
                ),
            )


# -- Read-half tier 3: imminent-write pre-stage (evidence = the callee's code).


def _pyir_ref_use_counts(ref: "ir.Value") -> "tuple[int, int]":
    """``(load_count, store_count)`` over *ref*'s current def-use edges."""
    loads = stores = 0
    try:
        for use in ref.uses:
            user = getattr(use, "owner", None)
            user_op = getattr(user, "operation", user)
            name = str(getattr(user_op, "name", ""))
            if name == "pyir.load":
                loads += 1
            elif name == "pyir.store":
                stores += 1
    except Exception:
        pass
    return loads, stores


def _pyir_boundary_prestage_imminent_writes(
    callee: Any, args: "tuple[Any, ...]"
) -> "list[tuple[Any, str, Any, Any, Any, Any, int, int, bool]]":
    """Pre-stage each meta receiver field in the callee's transitive write-facts
    (mint cell + fresh load); literal-write facts and celled places skip."""
    if not is_inside_staged_cf():
        return []
    func = getattr(callee, "__func__", callee)
    receiver = getattr(callee, "__self__", None)
    if receiver is None and args:
        receiver = args[0]
    if receiver is None or _is_staged_value(receiver):
        return []
    # V-7 at the class-facts lookup: facts resolve through type(receiver), so a
    # reclassed CELLED receiver would bind the wrong class's write model.
    if _pyir_owner_is_celled(receiver):
        _pyir_validate_owner_class(receiver)
    try:
        writes, _complete = _pyir_class_facts.transitive_write_facts(callee)
    except Exception:
        return []
    if not writes:
        return []
    items_map = _instance_storage_items(receiver)
    if items_map is None:
        return []
    records: "list[tuple[Any, str, Any, Any, Any, Any, int, int, bool]]" = []
    for name in writes:
        if name not in items_map:
            continue
        v = items_map[name]
        py_v = v.python_value if isinstance(v, _WatchedM) else v
        # A cell-less literal-backed staged scalar field folds at trace time
        # exactly like a meta field, so the callee's raw update would chain
        # from the entry constant: mint its cell the same way.  AUTO_M2S
        # only; the default mode keeps the loud boundary refusal.
        staged_literal = (
            is_auto_m2s_enabled()
            and not isinstance(v, _WatchedM)
            and _is_staged_value(v)
            and _is_literal_backed(v)
            and getattr(v, "_mutable_ref", None) is None
            and not _pyir_enclosing_while_cond_is_baked()
        )
        if staged_literal:
            py_v = v.value
        if type(py_v) not in (bool, int, float):
            # A compound field whose leaves the region-entry adoption staged:
            # the callee reads it RAW, so its rebuild would chain from the
            # entry constants, not from the cells the replay stores through.
            # Read it through the choke here (same label/owner as the replay,
            # so the cells are shared) and bind the load-backed result.
            if (
                is_auto_m2s_enabled()
                and not isinstance(v, _WatchedM)
                and not _is_staged_value(v)
                and (
                    # The staged-content walk has no dict branch: check the
                    # entries directly for a dict-valued field.
                    any(_is_staged_value(e) for e in dict.values(v))
                    if isinstance(v, dict)
                    else _has_any_staged_content(v)
                )
            ):
                label = _pyir_boundary_label(receiver, name)
                try:
                    if isinstance(v, dict):
                        # Dict reads do not recurse: read each staged entry
                        # under the SAME subscript place the replay's
                        # decomposition stores through, and rebind in place.
                        for k in list(dict.keys(v)):
                            e = dict.__getitem__(v, k)
                            if not _is_staged_value(e):
                                continue
                            loaded = pyir_read(
                                f"{label}[{k!r}]", e, owner=v, slot_name=k
                            )
                            if loaded is not None:
                                dict.__setitem__(v, k, loaded)
                    else:
                        staged_field = pyir_read(
                            label, v, owner=receiver, slot_name=name
                        )
                        if staged_field is not None:
                            _pyir_boundary_bind_storage(
                                receiver, name, staged_field
                            )
                except Exception:
                    pass
            continue
        if _pyir_class_facts.literal_attr_write_fact(func, name) is not None:
            continue  # latch tier: the loop-carry flip owns literal stores
        try:
            place = _make_slot_key(None, receiver, name)
        except Exception:
            place = None
        if place is None or _slot_refs.get(place) is not None:
            continue
        had_recorded_uses = bool(_meta_uses.get(place))
        try:
            ref = _meta_promote_slot(
                place,
                py_v,
                display_name=f"{type(receiver).__name__}.{name}",
                # Type the ref pointee by the field's own staged type (an
                # Int64 field must not mint an Int32 cell).
                promoted_value=v if staged_literal else None,
            )
        except DSLUserCodeError:
            raise  # the off-mode promotion refusal must reach the author
        except Exception:
            continue
        if ref is None:
            continue
        staged = _load_as_dsl(ref, place=place)
        if staged is None or not _pyir_boundary_bind_storage(receiver, name, staged):
            # Could not bind: retire the fresh row (no store can reach it).
            if not had_recorded_uses:
                _slot_refs.pop(place, None)
                _slot_templates.pop(place, None)
            continue
        loads0, stores0 = _pyir_ref_use_counts(ref)
        records.append(
            (receiver, name, staged, v, place, ref, loads0, stores0, had_recorded_uses)
        )
    return records


def _pyir_boundary_restore_prestage(
    records: "list[tuple[Any, str, Any, Any, Any, Any, int, int, bool]]",
) -> None:
    """Restore leg: an unfired pre-stage (cell neither stored nor load-consumed)
    reverts with no phase residue; a consumed load stays (a real read)."""
    for (
        receiver,
        name,
        staged,
        original,
        place,
        ref,
        loads0,
        stores0,
        had_recorded_uses,
    ) in records:
        try:
            loads1, stores1 = _pyir_ref_use_counts(ref)
            if stores1 > stores0 or had_recorded_uses:
                continue  # written / retargeted-at-mint: the cell is live
            consumed = loads1 > loads0
            if not consumed:
                raw = _raw_backing_ir_value(staged)
                if raw is not None:
                    try:
                        consumed = any(True for _ in raw.uses)
                    except Exception:
                        consumed = True  # cannot prove unused -> keep staged
            if consumed:
                continue
            items_map = _instance_storage_items(receiver)
            if items_map is not None and items_map.get(name) is staged:
                if _pyir_boundary_bind_storage(receiver, name, original):
                    _slot_refs.pop(place, None)
                    _slot_templates.pop(place, None)
        except Exception:
            continue


# -- Read-half tier 2: meta read-attribution for the callee's duration.


def _pyir_boundary_bind_storage(holder: Any, name: str, value: Any) -> bool:
    """Bind *value* into *holder*'s INSTANCE STORAGE slot *name*, never through a
    data descriptor's ``__set__`` (a storage rebind must not run a setter)."""
    d = _safe_instance_dict(holder)
    if d is not None and name in d:
        d[name] = value
        return True
    for slot_name, desc in _slots_member_descriptors(type(holder)):
        if slot_name == name:
            desc.__set__(holder, value)
            return True
    return False


def _pyir_boundary_stage_meta_reads(
    roots: "list[Any]",
) -> "list[tuple[Any, str, Any, Any]]":
    """Bind reachable plain-meta attr leaves to place-attributed ``_WatchedM`` for
    the callee's duration, so reads are RECORDED and promotions retarget them."""
    if not is_inside_staged_cf():
        return []
    records: "list[tuple[Any, str, Any, Any]]" = []
    visited: "set[int]" = set()

    def _walk(obj: Any) -> None:
        if obj is None or type(obj) in _PYIR_BOUNDARY_PASSTHROUGH_TYPES:
            return
        if isinstance(obj, (ir.Value, type, _types.ModuleType, _WatchedM)):
            return
        oid = id(obj)
        if oid in visited:
            return
        visited.add(oid)
        if isinstance(obj, _types.CellType):
            try:
                _walk(obj.cell_contents)
            except ValueError:
                pass
            return
        if isinstance(obj, (dict, list)):
            vals = list(dict.values(obj)) if isinstance(obj, dict) else list(obj)
            for v in vals:
                _walk(v)
            return
        if isinstance(obj, tuple):
            for v in obj:
                _walk(v)
            return
        if _is_staged_value(obj):
            return
        items_map = _instance_storage_items(obj)
        if items_map is None:
            return
        for name, v in list(items_map.items()):
            if isinstance(name, str) and name.startswith("__"):
                continue
            if type(v) in (bool, int, float) and isinstance(name, str):
                try:
                    place = _make_slot_key(None, obj, name)
                except Exception:
                    place = None
                if place is None:
                    continue
                wrapper = _WatchedM(v, place)
                if _pyir_boundary_bind_storage(obj, name, wrapper):
                    records.append((obj, name, wrapper, v))
            else:
                _walk(v)

    for r in roots:
        _walk(r)
    return records


def _pyir_boundary_stage_taken_default_reads(
    callee: Any, args: Any, kwargs: Any
) -> "list[tuple[Any, str, Any, Any]]":
    """Tier-2 read binds over an INLINE rewritten callee's taken defaults: a
    read-only attr chain in a rewritten body reaches no choke, so plain-meta
    leaves bind to place-attributed wrappers exactly as the dispatcher proxy
    stages its walk roots.  The caller restores the returned records."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0]:
            return []
        roots = [
            d
            for _sel, d in _pyir_boundary_taken_defaults(callee, args, kwargs)
            if not _is_staged_value(d)
        ]
        return _pyir_boundary_stage_meta_reads(roots) if roots else []
    except Exception:
        return []


def _pyir_boundary_restore_meta_reads(
    records: "list[tuple[Any, str, Any, Any]]",
) -> None:
    """Restore tier-2 binds: a slot still holding this call's wrapper reverts
    (recorded uses persist by PLACE); a slot the callee rebound is left."""
    for holder, name, wrapper, original in records:
        try:
            items_map = _instance_storage_items(holder)
            if items_map is not None and items_map.get(name) is wrapper:
                _pyir_boundary_bind_storage(holder, name, original)
        except Exception:
            continue


# -- Snapshot: tracked-place leaves reachable from the roots + slot holders.

_PYIR_BOUNDARY_MISSING = _Sentinel("boundary leaf missing")

# Diagnostics-only: cell owner token -> closure variable name (tokens are
# identity-true and never recycle, see IdentityKeyedWeakTable).
_PYIR_BOUNDARY_CELL_NAMES: "dict[int | None, str]" = {}


def _pyir_boundary_snapshot(
    roots: "list[Any]",
) -> "tuple[list[tuple[Any, Any, Any]], dict[int, tuple[Any, frozenset]], set[int]]":
    """Record ``(holder, key, pre_value)`` per leaf slot reachable from *roots*
    plus registered holders; pre key-sets let added slots replay as first defs;
    the visited-id set is the birth criterion for returned objects (see the
    module docstring for the declared observation domain)."""
    leaves: "list[tuple[Any, Any, Any]]" = []
    key_sets: "dict[int, tuple[Any, frozenset]]" = {}
    visited: "set[int]" = set()

    def _walk_class_storage(cls: type) -> None:
        # Class-level data attributes of a USER-MODULE class are places owned
        # by the CLASS object (F-SHAPE): shared writes diff on the class.
        # The user-module portion of the MRO is covered too — an inherited
        # data attribute is the same place the reflection read arm attributes
        # to its DEFINING class.
        for klass in getattr(cls, "__mro__", (cls,)):
            cid = id(klass)
            if cid in visited:
                continue
            visited.add(cid)
            if not _pyir_boundary_module_is_user(getattr(klass, "__module__", None)):
                continue
            items = _pyir_class_facts.class_storage_items(klass)
            key_sets[cid] = (klass, frozenset(items.keys()))
            for name, v in items.items():
                leaves.append((klass, name, v))
                _walk(v)

    def _walk(obj: Any) -> None:
        if obj is None or type(obj) in _PYIR_BOUNDARY_PASSTHROUGH_TYPES:
            return
        if isinstance(obj, type):
            # A class reachable as a root/receiver/leaf is observed through
            # its class storage (classmethod receivers included).
            _walk_class_storage(obj)
            return
        if isinstance(obj, (ir.Value, _types.ModuleType)):
            return
        oid = id(obj)
        if oid in visited:
            return
        visited.add(oid)
        if isinstance(obj, _WatchedM):
            return
        if isinstance(obj, _types.CellType):
            # Closure cell: one ``cell_contents`` leg; the key is the closure
            # variable name when known (diagnostics only).
            try:
                contents = obj.cell_contents
            except ValueError:
                return  # empty cell -- a later fill is not a place write
            leaves.append(
                (
                    obj,
                    _PYIR_BOUNDARY_CELL_NAMES.get(
                        _pyir_lookup_owner_token(obj), "cell_contents"
                    ),
                    contents,
                )
            )
            _walk(contents)
            return
        if isinstance(obj, dict):
            # An ADOPTED dict already instruments its writes object-level, so its
            # legs need no boundary diff; only the VALUES are walked.
            watched = isinstance(obj, _WatchedDict)
            for k, v in list(dict.items(obj)):
                if not watched:
                    leaves.append((obj, k, v))
                _walk(v)
            if not watched:
                key_sets[oid] = (obj, frozenset(dict.keys(obj)))
            return
        if isinstance(obj, list):
            watched = isinstance(obj, _WatchedList)
            elems = list(obj)
            for i, v in enumerate(elems):
                if not watched:
                    leaves.append((obj, i, v))
                _walk(v)
            if not watched:
                key_sets[oid] = (obj, frozenset(range(len(elems))))
            return
        if isinstance(obj, tuple):
            for v in obj:
                _walk(v)
            return
        if _is_staged_value(obj):
            return
        _walk_class_storage(type(obj))
        items_map = _instance_storage_items(obj)
        if items_map is None:
            return
        key_sets[oid] = (obj, frozenset(items_map.keys()))
        for name, v in items_map.items():
            if isinstance(name, str) and name.startswith("__"):
                continue
            leaves.append((obj, name, v))
            _walk(v)

    for r in roots:
        _walk(r)
    # Registered slot holders: a callee can mutate a holder not passed as an
    # argument (module-global, sibling); the registry union keeps it observable.
    for entry in list(_PYIR_SLOT_HOLDERS.values()):
        holder = entry() if isinstance(entry, _weakref.ref) else entry
        if holder is not None:
            _walk(holder)
    return leaves, key_sets, visited


# -- Diff + instrumented replay.


def _pyir_boundary_leaf_changed(holder: Any, key: Any, pre: Any, cur: Any) -> bool:
    """Did the callee CHANGE this leaf?  Exempt: identity, equal meta values, the
    same backing SSA, and values backed by the slot's own place cell."""
    if cur is pre:
        return False
    pre_p = _pyir_unwrap_meta_primitive(pre)
    cur_p = _pyir_unwrap_meta_primitive(cur)
    if pre_p is not None and cur_p is not None:
        try:
            return type(pre_p) is not type(cur_p) or pre_p != cur_p
        except Exception:
            return True
    try:
        pre_raw = _raw_backing_ir_value(pre)
        cur_raw = _raw_backing_ir_value(cur)
    except Exception:
        return True
    if pre_raw is not None and cur_raw is not None and _same_ir_value(pre_raw, cur_raw):
        return False
    # Same-ref reload exemption: the current value is backed by the slot's own
    # cell, so any advance already went through the cell.
    try:
        mv = _get_slot_mv(holder, key)
    except Exception:
        mv = None
    if mv is not None and mv.ref is not None and _pyir_same_ref_reload(cur, mv.ref):
        return False
    pre_mv = getattr(pre, "_mutable_ref", None)
    if (
        pre_mv is not None
        and getattr(pre_mv, "ref", None) is not None
        and _pyir_same_ref_reload(cur, pre_mv.ref)
    ):
        return False
    return True


def _pyir_boundary_label(holder: Any, key: Any) -> str:
    """A diagnostics label for the replayed slot: the ``<boundary>`` prefix cannot
    collide with a real access path; the tail names the slot."""
    if isinstance(holder, _types.CellType):
        return "<boundary closure cell>"
    if isinstance(holder, (dict, list)):
        return f"<boundary>[{key!r}]"
    return f"<boundary>.{key}"


def _pyir_boundary_current_value(holder: Any, key: Any) -> Any:
    """Raw post-call value of the leaf slot (no read chokes fire)."""
    if isinstance(holder, type):
        return holder.__dict__.get(key, _PYIR_BOUNDARY_MISSING)
    if isinstance(holder, _types.CellType):
        try:
            return holder.cell_contents
        except ValueError:
            return _PYIR_BOUNDARY_MISSING
    if isinstance(holder, dict):
        if not dict.__contains__(holder, key):
            return _PYIR_BOUNDARY_MISSING
        return dict.__getitem__(holder, key)
    if isinstance(holder, list):
        if not isinstance(key, int) or key >= list.__len__(holder):
            return _PYIR_BOUNDARY_MISSING
        return list.__getitem__(holder, key)
    items_map = _instance_storage_items(holder)
    if items_map is None or key not in items_map:
        return _PYIR_BOUNDARY_MISSING
    return items_map[key]


def _pyir_boundary_sc_refuse(key: Any, filename: str, lineno: int) -> None:
    """Curated refusal for an effect in a short-circuited ``and``/``or`` operand:
    the trace runs it once, so the effect cannot follow the runtime predicate."""
    raise DSLUserCodeError(
        DiagId.BOUNDARY_SHORT_CIRCUIT_EFFECT,
        name=str(key),
        filename=filename,
        lineno=lineno,
        suggestion=(
            f"Restructure the expression as an `if` statement so the update "
            f"of `{key}` is a conditional block, or make the guard a "
            f"compile-time constant (`const_expr`)."
        ),
    )


def _pyir_enclosing_while_cond_is_baked() -> bool:
    """True when an enclosing ``scf.while``'s already-traced condition is a
    baked constant: no cell minted from inside the body can reach it, so a
    carried update could never terminate the loop at runtime.  Callers keep
    the loud refusal instead of committing a carry that would hang."""
    try:
        block = ir.InsertionPoint.current.block
    except Exception:
        return False
    for _ in range(256):
        if block is None:
            return False
        try:
            parent = block.owner
        except Exception:
            return False
        op = getattr(parent, "operation", parent)
        try:
            op_name = str(op.name)
        except Exception:
            return False
        if op_name == "scf.while":
            try:
                before = op.regions[0].blocks[0]
                term = before.operations[len(before.operations) - 1]
                if str(term.operation.name) == "scf.condition":
                    cond_owner = term.operands[0].owner
                    cond_op = getattr(cond_owner, "operation", cond_owner)
                    if str(cond_op.name) == "arith.constant":
                        return True
            except Exception:
                pass
        elif _is_func_boundary_op(op_name) or _is_module_boundary_op(op_name):
            return False
        try:
            block = op.block
        except Exception:
            return False
    return False


def _pyir_boundary_loop_carry_flip(
    callee: Any,
    holder: Any,
    key: Any,
    pre: Any,
    pre_p: Any,
    cur: Any,
    cur_p: Any,
    label: str,
    filename: str,
    lineno: int,
) -> bool:
    """Commit a callee's LITERAL store to a loop-carried meta as a carried cell
    when its write fact proves iteration-stable guards; False keeps the refusal."""
    if not isinstance(key, str) or cur_p is None:
        return False
    func = getattr(callee, "__func__", callee)
    fact = _pyir_class_facts.literal_attr_write_fact(func, key)
    if fact is None:
        return False
    literals, guard_paths = fact
    if not any(type(lit) is type(cur_p) and lit == cur_p for lit in literals):
        return False  # the facts do not explain the observed value
    slot_key = _make_slot_key(None, holder, key)
    if slot_key is None:
        return False
    if _pyir_enclosing_while_cond_is_baked():
        return False  # the folded condition could never observe the carry
    recorded: "list[tuple[Any, tuple]]" = []
    if guard_paths:
        receiver = getattr(callee, "__self__", None)
        if receiver is None:
            return False  # no receiver to resolve the guard places on
        single_literal = all(
            type(lit) is type(cur_p) and lit == cur_p for lit in literals
        )
        for path in guard_paths:
            owner: Any = receiver
            for i, hop in enumerate(path):
                hop_key = _make_slot_key(None, owner, hop)
                if hop_key is not None and hop_key == slot_key:
                    # Self-gated write: re-asserting ONE literal is faithful;
                    # a multi-literal toggle is not reconstructible.
                    if not single_literal:
                        return False
                    break
                try:
                    value = getattr(owner, hop)
                except AttributeError:
                    return False
                raw = _pyir_unwrap_meta_primitive(value)
                if raw is None:
                    if i == len(path) - 1 or _is_staged_value(value):
                        # The guarding LEAF must be a trace-time meta primitive;
                        # a staged value at any hop is not provably stable.
                        return False
                if hop_key is None or hop_key in _slot_refs:
                    return False  # guard place already owns a cell
                recorded.append((hop_key, (hop, str(key), filename, lineno)))
                owner = value
    if pre_p is not None and slot_key not in _slot_refs:
        # The committed literal is the write this promotion serves: hand it to
        # the structural-consumption arm so value-equality is judged on it.
        ref = _meta_promote_slot(
            slot_key,
            pre_p,
            target_name=str(key),
            filename=filename,
            lineno=lineno,
            promoted_value=cur_p,
        )
        if ref is None:
            return False
        _pyir_emit_store(_emit_constant_for_ref(ref, cur_p), ref)
        staged = _load_as_dsl(ref, place=slot_key)
        _pyir_holder_store(holder, key, staged)
    else:
        # The slot already carries staged state: the literal arrives through
        # the instrumented write choke unchanged.
        old = (
            None
            if pre is _PYIR_BOUNDARY_MISSING
            else pyir_read(label, pre, owner=holder, slot_name=key)
        )
        result = pyir_assign(
            label, old, cur, filename, lineno, owner=holder, slot_name=key
        )
        if result is not cur:
            _pyir_holder_store(holder, key, result)
    # Recorded only after the commit succeeded: a bailed flip must leave no
    # refusal residue on its guard places.
    for hop_key, entry in recorded:
        _PYIR_BOUNDARY_FLIP_GUARD_READS.setdefault(hop_key, entry)
    log().info(
        "[pyir boundary] committed literal store '%s' as a loop-carried cell "
        "at the call site",
        label,
    )
    return True


def _pyir_boundary_replay(
    holder: Any,
    key: Any,
    pre: Any,
    cur: Any,
    filename: str,
    lineno: int,
    callee: Any = None,
) -> None:
    """Replay one observed write through the instrumented-write choke -- exactly
    the ``holder.key = cur`` lifecycle, every tier and refusal unchanged."""
    label = _pyir_boundary_label(holder, key)
    # META->META in staged CF: irreducible in a staged LOOP (refuse loudly),
    # M2S-promotable in a loop-free ``if``; plain-Python shapes are exempt.
    pre_p = (
        _pyir_unwrap_meta_primitive(pre) if pre is not _PYIR_BOUNDARY_MISSING else None
    )
    cur_p = _pyir_unwrap_meta_primitive(cur)
    # A raw-meta CURRENT value over a STAGED pre-value is the same invisible
    # arithmetic: the advance did not come through the cell.
    _pre_is_staged = False
    if pre_p is None and pre is not _PYIR_BOUNDARY_MISSING:
        try:
            _pre_is_staged = _is_staged_value(pre)
        except Exception:
            _pre_is_staged = False
    if (
        (pre_p is not None or _pre_is_staged)
        and cur_p is not None
        and is_inside_staged_cf()
        and not is_inside_constexpr_loop()
    ):
        slot_key = _make_slot_key(None, holder, key)
        if slot_key is not None:
            # In a staged LOOP both raw values meta = the advance bypassed the
            # cell: refuse, unless a guard-stable LITERAL flip is proven.
            if _innermost_enclosing_loop_op_at_ip() is not None:
                if _pyir_boundary_loop_carry_flip(
                    callee, holder, key, pre, pre_p, cur, cur_p, label, filename, lineno
                ):
                    return
                raise DSLUserCodeError(
                    DiagId.BOUNDARY_META_LOOP_CARRY,
                    filename=filename,
                    lineno=lineno,
                    name=str(key),
                )
            if pre_p is not None and slot_key not in _slot_refs:
                # The observed post-call value is the write this promotion
                # serves: value-equality at the structural arm judges it.
                ref = _meta_promote_slot(
                    slot_key,
                    pre_p,
                    target_name=str(key),
                    filename=filename,
                    lineno=lineno,
                    promoted_value=cur_p,
                )
                if ref is not None:
                    _pyir_emit_store(_emit_constant_for_ref(ref, cur_p), ref)
                    # F-SPEC write amendment: re-entry verifies the trace-exit
                    # payload of the promoted place, as on the choked path.
                    _pyir_spec_record_write(slot_key, cur_p)
                    staged = _load_as_dsl(ref, place=slot_key)
                    _pyir_holder_store(holder, key, staged)
                    log().info(
                        "[pyir boundary] promoted meta write '%s' at the call "
                        "site (loop-free staged if)",
                        label,
                    )
                    return
    if pre is _PYIR_BOUNDARY_MISSING:
        old = None
    else:
        old = pyir_read(label, pre, owner=holder, slot_name=key)
    value = cur
    if type(value) is dict:
        value = _pyir_adopt_dict_value(holder, key, value, label=label)
    elif type(value) is list:
        value = _pyir_adopt_list_value(holder, key, value, label=label)
    result = pyir_assign(
        label, old, value, filename, lineno, owner=holder, slot_name=key
    )
    # Meta first-def from a plain callee: record the binding position (a
    # staged first-def records through the assign choke).
    if pre is _PYIR_BOUNDARY_MISSING and not _is_staged_value(value):
        _pyir_record_cf_attr_first_def(holder, key)
    # A FIRST-DEF from a plain callee in a staged LOOP has unprovable
    # multiplicity: lift the keep-meta exemption so later changes fail-close.
    if (
        pre is _PYIR_BOUNDARY_MISSING
        and is_inside_staged_cf()
        and _innermost_enclosing_loop_op_at_ip() is not None
    ):
        try:
            _fd_slot = _make_slot_key(None, holder, key)
            if _fd_slot is not None:
                _slot_first_def_inside_cf[_fd_slot] = False
        except Exception:
            pass
    if result is not cur:
        _pyir_holder_store(holder, key, result)
        # F-SPEC: the value left in storage (not the assign input) is what a
        # re-entry re-derefs; re-amend the rows to the stored object.
        _spec_place = _make_slot_key(None, holder, key)
        if _spec_place is not None:
            _pyir_spec_record_write(_spec_place, result)
    log().info(
        "[pyir boundary] committed un-instrumented write '%s' at the call site",
        label,
    )


def _pyir_boundary_commit(
    callee: Any,
    snapshot: (
        "tuple[list[tuple[Any, Any, Any]], dict[int, tuple[Any, frozenset]], set[int]]"
    ),
    sc_rhs: bool = False,
    result: Any = None,
) -> None:
    """Diff the snapshot against the post-call state and replay each change,
    deduped by leaf slot; deletions stay Python, *sc_rhs* effects refuse; a
    *result* object born in the callee enters the identity domain (birth)."""
    func = getattr(callee, "__func__", callee)
    code = getattr(func, "__code__", None)
    filename = getattr(code, "co_filename", "<call boundary>")
    lineno = getattr(code, "co_firstlineno", 0)
    leaves, key_sets, visited = snapshot
    for holder, key, pre in leaves:
        cur = _pyir_boundary_current_value(holder, key)
        if cur is _PYIR_BOUNDARY_MISSING:
            continue
        if not _pyir_boundary_leaf_changed(holder, key, pre, cur):
            continue
        # The callee replaced this leaf: witness the pre-call binding so trace
        # close can restore it if the leaf is left holding a staged wrapper.
        _pyir_record_host_restore(holder, key, pre)
        if sc_rhs:
            mv = None
            try:
                mv = _get_slot_mv(holder, key)
            except Exception:
                mv = None
            if is_inside_staged_cf() or (mv is not None and mv.ref is not None):
                _pyir_boundary_sc_refuse(key, filename, lineno)
            continue  # plain trace scope: Python already has the value
        _pyir_boundary_replay(
            holder,
            key,
            pre,
            cur,
            filename,
            lineno,
            callee=callee,
        )
    # Attributes / entries ADDED by the callee replay as first defs, entering
    # the place model exactly like an instrumented first write.
    for _oid, (holder, pre_keys) in key_sets.items():
        if isinstance(holder, _WatchedDict) or isinstance(holder, _WatchedList):
            # Adopted containers intercept their own writes object-level.
            continue
        if isinstance(holder, dict):
            post_keys = list(dict.keys(holder))
        elif isinstance(holder, list):
            post_keys = list(range(list.__len__(holder)))
        elif isinstance(holder, type):
            post_keys = list(_pyir_class_facts.class_storage_items(holder).keys())
        else:
            items_map = _instance_storage_items(holder)
            if items_map is None:
                continue
            post_keys = [
                k
                for k in items_map.keys()
                if not (isinstance(k, str) and k.startswith("__"))
            ]
        for key in post_keys:
            if key in pre_keys:
                continue
            cur = _pyir_boundary_current_value(holder, key)
            if cur is _PYIR_BOUNDARY_MISSING:
                continue
            if sc_rhs:
                if is_inside_staged_cf():
                    _pyir_boundary_sc_refuse(key, filename, lineno)
                continue
            # A dict/list key CREATED by a plain callee inside dynamic staged
            # CF is a key-set change -- the same declared fact the watched
            # structural chokes refuse: a created entry has no pre-region
            # cell, so it cannot follow the region's runtime predicate.
            # Replaying it as a first def would bake it unconditionally.
            if (
                isinstance(holder, (dict, list))
                and is_inside_staged_cf()
                and not is_inside_constexpr_loop()
            ):
                raise DSLUserCodeError(
                    (
                        DiagId.CONTAINER_DICT_KEY_SET_MUTATED
                        if isinstance(holder, dict)
                        else DiagId.CONTAINER_LIST_SHAPE_MUTATED
                    ),
                    var=_pyir_boundary_label(holder, key),
                    detail=f"key {key!r} created by a plain (non-jit) callee",
                )
            _pyir_boundary_replay(
                holder,
                key,
                _PYIR_BOUNDARY_MISSING,
                cur,
                filename,
                lineno,
                callee=callee,
            )
    # Birth-at-boundary-return: a returned object born in the callee enters
    # the ledger's identity domain here (token mint + born-class stamp).
    if result is not None and not sc_rhs:
        _pyir_boundary_record_ctor_birth(result, visited)


def _pyir_boundary_record_ctor_birth(result: Any, visited: "set[int]") -> None:
    """Mint the owner token (which stamps F-CLASS) for each object in *result*
    NOT reachable at snapshot time and never tokenized -- the birth event.
    Leaf publication stays with the binding chokes: the caller's bind roots the
    object at its binding position and publishes its places there (LAW 1/3);
    a boundary-side leaf replay would pre-freeze self-rooting and
    double-publish content the trace already records."""

    def _collect(obj: Any) -> None:
        if obj is None or type(obj) in _PYIR_BOUNDARY_PASSTHROUGH_TYPES:
            return
        if isinstance(obj, (ir.Value, type, _types.ModuleType, _WatchedM)):
            return
        if id(obj) in visited:
            return  # reachable pre-call: not a birth
        visited.add(id(obj))
        if isinstance(obj, (_WatchedDict, _WatchedList)):
            return  # adopted containers instrument their own writes
        if isinstance(obj, (dict, list, tuple)):
            vals = list(dict.values(obj)) if isinstance(obj, dict) else list(obj)
            for v in vals:
                _collect(v)
            return
        if _is_staged_value(obj):
            return
        if _pyir_lookup_owner_token(obj) is not None:
            return  # already a known owner: its writes are the diff's domain
        items = _instance_storage_items(obj)
        if items is None:
            return
        # S4 floor at birth: a user-defined `__del__` fires at a GC-determined
        # instant, which has no binding position in the traced program.
        _pyir_refuse_del_finalizer_owner(obj)
        _owner_token(obj)  # birth mint (stamps F-CLASS)
        for v in list(items.values()):
            _collect(v)

    _collect(result)


def _verify_no_used_poison(module: "ir.Module") -> None:
    """Raise for a poison/placeholder-init ref read with no dominating store; the
    analysis runs in C++ (``pyir.find_first_used_poison``), this shim only raises."""
    if pyir is None:
        return
    from . import pyir_core as _pyir_core

    if _pyir_core._POISON_EMITTED == 0:
        # No poison / stamped placeholder init was produced since the last
        # verify boundary, so the module cannot contain one: skip the scan.
        return
    # Consume the counter BEFORE the scan so the raising path does not leak it;
    # a stale count from a failed trace only costs one spurious scan.
    _pyir_core._POISON_EMITTED = 0
    finder = getattr(pyir, "find_first_used_poison", None)
    if finder is None:
        return
    result = finder(module.operation)
    if result is None:
        return
    filename, lineno, loc_str = result
    if filename is None and loc_str:
        import re

        m = re.search(r'"([^"]+\.py)"\s*:\s*(\d+)', loc_str)
        if m:
            filename, lineno = m.group(1), int(m.group(2))
    raise DSLUserCodeError(
        DiagId.SCOPE_READ_NEVER_SET, filename=filename, lineno=lineno
    )


# Static export surface (regenerate with scripts/gen_pyir_all.py): the
# module's OWN names -- its namespace minus what lower chain modules
# already export and minus the generator's INTERNAL_ONLY registry.
__all__ = [
    "_bisect",
    "_collections",
    "_dataclasses",
    "_dis",
    "_heapq",
    "_operator",
    "_os",
    "_types",
    "_pyir_boundary_module_is_user",
    "_pyir_boundary_consume_meta_arg",
    "_pyir_delete_attr",
    "_pyir_import_guard",
    "_PYIR_GLOBAL_WRITE_SCANS",
    "_pyir_callee_global_write",
    "_pyir_global_write_guard",
    "_pyir_global_write_watch",
    "_pyir_global_write_check",
    "_pyir_import_record",
    "_pyir_routed_vars",
    "_pyir_traced_locals",
    "_pyir_routed_dict_view",
    "_pyir_routed_clevel_mutator",
    "_PYIR_CLEVEL_MUTATOR_ROUTES",
    "_PYIR_DEQUE_BOUND_MUTATORS",
    "_pyir_call_boundary_",
    "_PYIR_SETATTR_OVERRIDES",
    "_pyir_user_setattr_override",
    "_pyir_is_property_store",
    "_pyir_property_store",
    "_pyir_inplace_binop",
    "_pyir_boundary_value_tracked",
    "_pyir_ctx_boundary",
    "_pyir_boundary_bind_storage",
    "_pyir_boundary_stage_taken_default_reads",
    "_pyir_boundary_restore_meta_reads",
    "_pyir_enclosing_while_cond_is_baked",
    "_verify_no_used_poison",
]
