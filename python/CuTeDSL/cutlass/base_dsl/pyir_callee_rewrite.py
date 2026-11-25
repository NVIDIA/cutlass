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


"""Plain callees and calls from traced code.

A jit body is rewritten by the preprocessor so its accesses run through the
PyIR chokes; a plain (undecorated) user callable reached from that body is
rewritten here with the same access vocabulary and its ``__code__`` swapped for
the trace.  ``_pyir_call_boundary_(callee)`` is the dispatch every call goes
through: a traced callable passes, a reflection primitive becomes its routed
form, a wrapper-consuming DSL/stdlib callee runs under the result observer, any
other native callable under the unwrap proxy with the module-global write
guard, a user callable as its rewrite.

Contract: a mutation a callee performs on state the kernel reaches is carried
by the chokes where it happens, or refused with a curated diagnostic.  Host
state native code advances, code without source, a class statement, a module
global or class attribute advanced in a loop, and an aliased holder rebound in
a region refuse inside dynamic staged control flow.
"""

import array as _array
import bisect as _bisect
import ast as _ast
import builtins as _builtins
import collections as _collections
import collections.abc as _abc
import contextvars as _contextvars
import copy as _copy
import dataclasses as _dataclasses
import dis as _dis
import functools as _functools
import itertools as _itertools
import heapq as _heapq
import inspect as _inspect
import linecache as _linecache
import operator as _operator
import os as _os
import random as _random
import sys as _sys
import sysconfig as _sysconfig
import symtable as _symtable
import threading as _threading
import types as _types
import warnings as _warnings
import weakref as _weakref
from typing import Any, NoReturn

from .pyir_state import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_core import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_corewalk import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_loop_carry import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .pyir_entrypoints import *  # noqa: F401,F403  (siblings: each layer imports ALL lower layers)
from .common import DSLBaseError
from .pyir_core import (
    _first_non_dsl_caller_location,
    _pyir_current_region_arm_path,
    _pyir_lookup_owner_token,
    _pyir_retire_place_row,
    _pyir_spec_record_unbind,
    _safe_instance_dict,
    _slot_store_for_tier1,
    _slots_member_descriptors,
    _instance_storage_items,
    _pyir_note_absent_probe,
    _META_CONST_REPLACEMENTS,
    _innermost_enclosing_loop_op_at_ip,
)
from .pyir_entrypoints import (
    _PYIR_SKIP,
    _pyir_post_attr_assign,
    _pyir_post_subscript_read,
    _pyir_pre_attr_assign,
    _pyir_pre_subscript_assign,
)
from .pyir_state import (
    _PYIR_DEQUE_MUTATORS,
    _PYIR_SIGHT_HOOK,
    _PYIR_TRACE_CLOSE_HOOKS,
    _PYIR_TRACE_THREAD,
    _pyir_fatal_trace_error,
    _pyir_setattr_raw,
    _SLOT_STORE_ATTR,
    _PYIR_PENDING_USER_DIAGNOSTIC,
    _slot_refs,
    _pyir_delattr_raw,
)
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
# wrappers by design (the retargetable ``ir_value`` channel); the compiled ``_mlir``
# builder surface, stdlib, and third-party code take plain payloads.
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


# A leaf slot the post-call probe finds absent, and a callee result that never
# materialised (the call raised).
_PYIR_BOUNDARY_MISSING = _Sentinel("boundary leaf missing")


# -- Host-state facts: state native code advances that no choke can carry
# (an iterator cursor, a generator frame, an RNG, a deque's order, a memo
# cache, a native buffer).

_PYIR_UNOBSERVABLE = _Sentinel("host state unobservable")


def _pyir_cursor_atom(part: Any, depth: int = 0) -> Any:
    """A comparable, reference-free image of one fingerprint component:
    scalars by value, tuples/lists element-wise, nested iterators by their own
    cursor, anything else by identity."""
    if part is None or type(part) in (bool, int, float, str, bytes):
        return part
    if depth > 4:
        return ("id", id(part))
    if isinstance(part, (tuple, list)):
        return (
            type(part).__name__,
            tuple(_pyir_cursor_atom(p, depth + 1) for p in part),
        )
    if isinstance(part, _types.FunctionType):
        # A callable-sentinel iterator keeps its cursor in the callable's
        # closure (``iter(lambda: next(it), 0)``): image the cells too.
        cells = []
        for cell in part.__closure__ or ():
            try:
                cells.append(_pyir_cursor_atom(cell.cell_contents, depth + 1))
            except ValueError:
                cells.append(("empty",))
        return ("fn", id(part), tuple(cells))
    if isinstance(part, _types.MethodType):
        return (
            "method",
            id(part.__func__),
            _pyir_cursor_atom(part.__self__, depth + 1),
        )
    if hasattr(type(part), "__next__") and type(part).__module__ in (
        "builtins",
        "itertools",
        "_collections",
    ):
        return _pyir_iterator_cursor(part, depth + 1)
    return ("id", id(part))


def _pyir_iterator_cursor(obj: Any, depth: int = 0) -> Any:
    """A C iterator's position, read through its pickling protocol (the only
    public cursor; the deprecation of itertools pickling is silenced)."""
    with _warnings.catch_warnings():
        _warnings.simplefilter("ignore", DeprecationWarning)
        try:
            state = obj.__reduce__()
        except Exception:
            return _PYIR_UNOBSERVABLE
    if not isinstance(state, tuple):
        return _PYIR_UNOBSERVABLE
    return _pyir_cursor_atom(state, depth)


def _pyir_module_is_host_state(mod: Any) -> bool:
    """A module object whose attributes a callee may write: one built with
    ``types.ModuleType`` (never imported) or an imported USER module."""
    name = getattr(mod, "__name__", None)
    if not isinstance(name, str) or _sys.modules.get(name) is not mod:
        return True
    return _pyir_boundary_module_is_user(name)


_PYIR_OPERATOR_DUNDERS = frozenset(
    f"__{prefix}{op}__"
    for op in (
        "add",
        "sub",
        "mul",
        "truediv",
        "floordiv",
        "mod",
        "pow",
        "and",
        "or",
        "xor",
        "lshift",
        "rshift",
        "matmul",
    )
    for prefix in ("", "r", "i")
) | frozenset(
    (
        "__lt__",
        "__le__",
        "__gt__",
        "__ge__",
        "__eq__",
        "__ne__",
        "__neg__",
        "__index__",
        "__bool__",
    )
)


def _pyir_boundary_overrides_operators(cls: type) -> bool:
    """Does a USER class in *cls*'s MRO define an operator/comparison dunder?"""
    for klass in cls.__mro__:
        if klass in (int, float, bool, object):
            continue
        if not _pyir_boundary_module_is_user(getattr(klass, "__module__", None)):
            continue
        if _PYIR_OPERATOR_DUNDERS & set(vars(klass)):
            return True
    return False


def _pyir_boundary_is_traced_callable(func: Any) -> bool:
    """A jit-decorated / DSL-rewritten function: it traces, and its own
    attributes are compiler bookkeeping, not user state."""
    return (
        hasattr(func, "_preprocessed")
        or hasattr(func, "_dsl_cls")
        or hasattr(func, "_dsl_object")
        or _pyir_callee_is_rewritten(func)
    )


_PYIR_BUILTIN_CONTAINER_BASES = (dict, list, tuple, set, frozenset)

# -- Native callees: the unwrap proxy and the result observer.


def _pyir_builtin_subclass_storage(obj: Any) -> "dict[str, Any] | None":
    """Instance storage of a USER-MODULE dict/list/tuple/set subclass instance (the
    base types keep none; the tracer's own adopted wrappers are not user
    holders), else ``None``."""
    if not isinstance(obj, _PYIR_BUILTIN_CONTAINER_BASES):
        return None
    if type(obj) in _PYIR_BUILTIN_CONTAINER_BASES or isinstance(
        obj, (_WatchedDict, _WatchedList)
    ):
        return None
    if not _pyir_boundary_module_is_user(getattr(type(obj), "__module__", None)):
        return None
    items = _instance_storage_items(obj)
    if items is None:
        return None
    return {
        k: v
        for k, v in items.items()
        if not (isinstance(k, str) and k.startswith("__"))
    }


def _pyir_boundary_is_user_holder(value: Any) -> bool:
    """A plain user-module instance with instance storage (not staged, not a
    watched wrapper, not a class): the receiver shape whose implicit
    protocol methods are plain user code."""
    if value is None or isinstance(value, (type, _WatchedM, _types.ModuleType)):
        return False
    if type(value) in _PYIR_BOUNDARY_PASSTHROUGH_TYPES or _is_staged_value(value):
        return False
    if not _pyir_boundary_module_is_user(getattr(type(value), "__module__", None)):
        return False
    return _instance_storage_items(value) is not None


def _pyir_boundary_observe_truth(value: Any) -> bool:
    """``bool(value)`` for the rewrite's truth tests: a user object's implicit
    ``__bool__``/``__len__`` is plain code with no ``ast.Call`` for the wrap
    pass, so inside staged CF it runs under a call boundary like any plain
    call and its effects replay."""
    if _PYIR_SIGHT_HOOK[0] is not None:
        # The object's class is instrumented at the sighting, so its own
        # ``__bool__`` / ``__len__`` code observes.
        _PYIR_SIGHT_HOOK[0](value)
    return bool(value)


_PYIR_EXPLICIT_RAISE_OPNAMES = frozenset(("RAISE_VARARGS", "RERAISE"))


def _pyir_exception_born_native(exc: BaseException) -> bool:
    """Whether *exc* was raised by native code the innermost Python frame invoked (a
    C-level call, subscript or attribute store) rather than by a ``raise``
    statement of that frame."""
    tb = exc.__traceback__
    if tb is None:
        return False
    while tb.tb_next is not None:
        tb = tb.tb_next
    try:
        offset = tb.tb_lasti
        for ins in _dis.get_instructions(tb.tb_frame.f_code):
            if ins.offset == offset:
                return ins.opname not in _PYIR_EXPLICIT_RAISE_OPNAMES
    except Exception:
        return False
    return False


def _pyir_boundary_native_rejection_vars(
    prestaged: "list[Any]", args: Any, kwargs: Any
) -> "str | None":
    """The staged values a native callee inside the plain call may have been
    handed: the fields this call pre-staged (named), else the staged content
    of the arguments; ``None`` when the call saw no staged value at all."""
    names: "list[str]" = []
    for rec in prestaged:
        label = f"{type(rec[0]).__name__}.{rec[1]}"
        if label not in names:
            names.append(label)
    if names:
        return ", ".join(f"`{n}`" for n in sorted(names))
    values = list(args) + list(kwargs.values())
    if any(
        _is_staged_value(a)
        or _has_any_staged_content(a)
        or _pyir_holds_promoted_meta(a)
        for a in values
    ):
        return "an argument"
    return None


def _pyir_holds_promoted_meta(value: Any, _depth: int = 0) -> bool:
    """A staged value or a watched meta whose place has a cell, or a holder /
    container carrying one two levels deep (a dict entry included): compiler
    state a native cannot reduce."""
    if _is_staged_value(value):
        return True
    if isinstance(value, _WatchedM):
        key = value._slot_key
        return key is not None and _slot_refs.get(key) is not None
    if _depth >= 2 or value is None or type(value) in _SCALAR_TYPES:
        return False
    if isinstance(value, dict):
        parts = list(value.values())
    elif isinstance(value, (list, tuple, set, frozenset)):
        parts = list(value)
    else:
        items = (
            _instance_storage_items(value)
            if _pyir_boundary_is_user_holder(value)
            else None
        )
        parts = list(items.values()) if items else []
    return any(_pyir_holds_promoted_meta(p, _depth + 1) for p in parts)


def _pyir_boundary_refuse_native_raise(
    callee: Any, exc: BaseException, prestaged: "list[Any]", args: Any, kwargs: Any
) -> None:
    """An ordinary ``TypeError`` born in native code during a call that ran on
    staged values inside staged control flow: Python would run the same call on
    plain values, so the exception is the compiler's, not the author's -- refuse
    instead of letting the author's ``except`` steer the trace down a path Python
    never takes."""
    # Plain trace scope keeps the native TypeError as the author's trace-time
    # exception; only a body traced once for many runtime paths must refuse.
    if not is_inside_staged_cf():
        return
    if not isinstance(exc, TypeError) or not _pyir_exception_born_native(exc):
        return
    what = _pyir_boundary_native_rejection_vars(prestaged, args, kwargs)
    if what is None:
        return
    filename, lineno = _first_non_dsl_caller_location()
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.BOUNDARY_NATIVE_REJECTED_STAGED,
            filename=filename,
            lineno=lineno,
            callee=_pyir_boundary_callee_name(callee),
            exc=f"{type(exc).__name__}: {exc}",
            vars=what,
        )
    ) from exc


# Lazy iterators whose C-level step truth-tests a predicate result: a consumer
# draining one (``tuple(filter(...))``) reports the iterator, not itself.
_PYIR_PREDICATE_ITERATORS: "tuple[type, ...]" = (
    filter,
    _itertools.filterfalse,
    _itertools.takewhile,
    _itertools.dropwhile,
)


def _pyir_boundary_native_callee_display(callee: Any, args: Any) -> str:
    """Diagnostics-only: the native callee as the author spelled it -- the
    predicate iterator a consumer drains, a tracked container's method under
    its builtin name (``list.index``, not the tracker class CPython puts in
    the bound method's qualname), else the qualified name."""
    for arg in args:
        if isinstance(arg, _PYIR_PREDICATE_ITERATORS):
            return f"`{type(arg).__name__}`"
    name = _pyir_boundary_callee_name(callee)
    receiver = getattr(callee, "__self__", None)
    if receiver is not None and "." in name:
        for base in _BUILTIN_CONTAINER_BASES:
            if isinstance(receiver, base):
                name = f"{base.__name__}.{name.rsplit('.', 1)[1]}"
                break
    return f"`{name}`"


# (block hash, verdict) of the last entry-block walk: every block of one
# function answers alike, and the module block outlives the trace.
_PYIR_TRACE_ACTIVE_MEMO: "list[Any]" = [None, False]


def _pyir_boundary_trace_active() -> bool:
    """True while a PyIR-instrumented function body is tracing into an
    open MLIR function (the only scope where a boundary commit can emit)."""
    if pyir is None or not _PYIR_SCOPE_STACK:
        return False
    try:
        key = hash(ir.InsertionPoint.current.block)
    except Exception:
        return False
    memo = _PYIR_TRACE_ACTIVE_MEMO
    if memo[0] == key:
        return memo[1]
    verdict = _get_function_entry_block() is not None
    memo[0], memo[1] = key, verdict
    return verdict


# Numeric-protocol builtins (LangRef 3.3.8): with a watched receiver they
# consume through the registered dunder arms, so the funnel must not pre-unwrap.
_PYIR_PROTOCOL_BUILTINS: "tuple[Any, ...]" = (divmod, pow, complex)


class _PyirMetaUnwrapProxy:
    """Unwrap funnel for callees outside the wrapper-consuming layers: each
    watched-META argument is consumed HERE -- recorded and passed as its plain
    payload -- so a compiled/stdlib callee never receives a wrapper."""

    _pyir_unwrap_callee: Any
    _pyir_unwrap_fresh: "tuple[int, ...]"
    _pyir_unwrap_births_seen: bool

    __slots__ = (
        "_pyir_unwrap_callee",
        "_pyir_unwrap_fresh",
        "_pyir_unwrap_births_seen",
    )

    def __init__(
        self,
        callee: Any,
        fresh_args: "tuple[int, ...]" = (),
        births_seen: bool = False,
    ) -> None:
        self._pyir_unwrap_callee = callee
        self._pyir_unwrap_fresh = tuple(fresh_args)
        self._pyir_unwrap_births_seen = births_seen

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
                any(callee is builtin for builtin in _PYIR_PROTOCOL_BUILTINS)
                and args
                and isinstance(args[0], _WatchedM)
            ):
                return callee(*args, **kwargs)
            # User callables / classes the native callee receives are
            # swapped first; host state it advances refuses.
            _replaced = _pyir_cal_native_policy(
                callee,
                args,
                kwargs,
                self._pyir_unwrap_fresh,
                self._pyir_unwrap_births_seen,
            )
            if _replaced is not None:
                args, kwargs = _replaced
            if any(isinstance(a, _WatchedM) for a in args):
                args = tuple(_pyir_boundary_consume_meta_arg(a, callee) for a in args)
            if kwargs and any(isinstance(v, _WatchedM) for v in kwargs.values()):
                kwargs = {
                    k: _pyir_boundary_consume_meta_arg(v, callee)
                    for k, v in kwargs.items()
                }
            watch = _pyir_global_write_watch(callee)
            try:
                result = callee(*args, **kwargs)
            except TypeError as exc:
                _pyir_boundary_refuse_native_raise(callee, exc, [], args, kwargs)
                raise
            except DSLUserCodeError as exc:
                _pyir_translate_native_truth(
                    _pyir_boundary_native_callee_display(callee, args), exc
                )
                raise
            _pyir_global_write_check(watch)
            if isinstance(callee, type) and isinstance(result, BaseException):
                # An exception born in an open loop body is a per-iteration
                # object: its slot writes there are not loop-carried state.
                _pyir_boundary_note_birth(result)
            _pyir_cal_native_result(callee, result, args, kwargs)
            return result
        return callee(*args, **kwargs)


_PYIR_NATIVE_INVOKE_CODES.add(_PyirMetaUnwrapProxy.__call__.__code__)


def _pyir_cal_meta_payload(value: Any, callee: Any) -> Any:
    """The plain payload of a watched-META wrapper whose place is not promoted
    (a promoted place keeps its wrapper: its consumers load the cell), applied
    through tuples; the consumption is recorded like the funnel's."""
    if isinstance(value, _WatchedM):
        slot = value._slot_key
        if slot is not None and _slot_refs.get(slot) is not None:
            return value
        value._record_structural_consumption()
        return value._pyir_raw_payload
    if isinstance(value, tuple):
        parts = [_pyir_cal_meta_payload(e, callee) for e in value]
        if all(a is b for a, b in zip(parts, value)):
            return value
        return _rebuild_tuple_like(value, parts)
    return value


class _PyirMetaPayloadCall:
    """A wrapper-consuming (DSL-layer) callee at a REWRITTEN call site: its
    watched-META arguments arrive as payloads (see ``_pyir_cal_meta_payload``)."""

    __slots__ = ("_pyir_inner", "_pyir_callee")

    def __init__(self, inner: Any, callee: Any) -> None:
        self._pyir_inner = inner
        self._pyir_callee = callee

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        callee = self._pyir_callee
        args = tuple(_pyir_cal_meta_payload(a, callee) for a in args)
        if kwargs:
            kwargs = {k: _pyir_cal_meta_payload(v, callee) for k, v in kwargs.items()}
        return self._pyir_inner(*args, **kwargs)


class _PyirResultObserver:
    """A wrapper-consuming (DSL-layer) callee called inside dynamic staged
    CF: called as it is, its result handed to the native result arm so a
    container the call created is born in the region."""

    __slots__ = ("_pyir_callee",)

    def __init__(self, callee: Any) -> None:
        self._pyir_callee = callee

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        result = self._pyir_callee(*args, **kwargs)
        _pyir_cal_native_result(self._pyir_callee, result, args, kwargs, False)
        return result


_PYIR_NATIVE_INVOKE_CODES.add(_PyirResultObserver.__call__.__code__)
_PYIR_NATIVE_INVOKE_CODES.add(_PyirMetaPayloadCall.__call__.__code__)


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
    instance for instance storage (a storage-transparent property resolves to
    the instance holding its backing field), the defining class for a
    class-level data attribute (F-SHAPE), ``None`` for computed attributes
    (place is ⊥)."""
    if obj is None or _is_staged_value(obj) or isinstance(obj, _WatchedM):
        return None
    if not isinstance(obj, type):
        items = _instance_storage_items(obj)
        if items is not None and name in items:
            return obj
        if items is not None and _pyir_canonical_slot_name(obj, name) in items:
            return obj
    mro = getattr(obj if isinstance(obj, type) else type(obj), "__mro__", ())
    for klass in mro:
        if name in klass.__dict__:
            if name in _pyir_class_facts.class_storage_items(klass):
                return klass
            return None  # descriptor / dunder / nested class: computed
    return None


def _pyir_seed_absent_attr_read(obj: Any, name: str, default: Any) -> Any:
    """Default-taken ``getattr`` MISS inside an open staged LOOP body: when the
    default is a Python primitive and *obj* has plain instance storage for
    *name*, the miss is the read half of a carried accumulator the body creates
    by its own first update (``o.n = getattr(o, "n", 0) + 1``): the default is
    the leaf's value at the loop's entry, so the place is seeded with it
    (anchored at the holder's birth when that is an open body) and the read
    routes through the read choke -- a later write then promotes the place, or
    refuses in the default mode."""
    if (
        not is_inside_staged_cf()
        or is_inside_constexpr_loop()
        or not _pyir_open_loop_body_blocks
        or type(default) not in (bool, int, float)
    ):
        return None
    if obj is None or isinstance(obj, (type, _types.ModuleType, _WatchedM)):
        return None
    if _is_staged_value(obj) or _safe_instance_dict(obj) is None:
        return None
    # A user setter / ``__setattr__`` governs stores of this name: the raw
    # storage seed would bypass it, so the leaf is not seedable.
    if _pyir_is_property_store(obj, name):
        return None
    place = _make_slot_key(None, obj, name)
    if place is None:
        return None
    _pyir_check_absent_probe_then_bound(obj, name)
    # The storage stays untouched (Python creates the attribute only at the write):
    # the record alone makes a later first-def of the place in this region the
    # seeded leaf's first UPDATE, and a probe of it refuse.
    _pyir_boundary_declare_birth_place(obj, place)
    src_file, src_line = _first_non_dsl_caller_location()
    _PYIR_CF_SEEDED_ATTRS.setdefault(
        (id(obj), name),
        {
            "arms": _pyir_current_region_arm_path(),
            "site": (src_file, src_line),
            "default": default,
        },
    )
    _pyir_keepalive_generation_obj(obj)
    return pyir_read(f"<getattr>.{name}", default, owner=obj, slot_name=name)


def _pyir_routed_getattr(obj: Any, name: Any, *default: Any) -> Any:
    """Routed ``getattr``: the native dereference is Python truth; a storage hit
    re-resolves through the read choke (records the read, loads live cells); a
    hit that resolves to NO storage slot is judged as a fabricated read; a
    tolerated default-taken MISS seals an absence row (the bake depends on the
    name staying absent) and, inside an open loop body, seeds the leaf or
    records the probe (see :func:`_pyir_seed_absent_attr_read`)."""
    try:
        cur = getattr(obj, name)
    except AttributeError:
        if not default:
            raise
        if _pyir_boundary_trace_active() and isinstance(name, str):
            _pyir_spec_record_attr_probe(obj, name, present=False)
            served = _pyir_seed_absent_attr_read(obj, name, default[0])
            if served is not None:
                return served
            _pyir_note_absent_probe(obj, name, "a default-taken `getattr`")
        return default[0]
    if not _pyir_boundary_trace_active() or not isinstance(name, str):
        return cur
    if default:
        # A default-taken read of a seeded leaf outside its seeding region
        # depends on the trip count (the leaf may not exist).
        _pyir_check_seeded_place_probe(obj, name, presence_only=False)
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
            # Absent at trace time yet seeded in this region: present from
            # the second iteration on, so the answer is path-dependent.
            _pyir_check_seeded_place_probe(obj, name)
            _pyir_note_absent_probe(obj, name, "`hasattr`")
        return False
    if _pyir_boundary_trace_active() and isinstance(name, str):
        if _pyir_reflect_storage_owner(obj, name) is None:
            _pyir_judge_fabricated_attr_read(obj, name, cur)
        # Presence of a region-conditional first-def is path-dependent: same
        # read-before-set refusal as a value read.
        _slot = _pyir_canonical_slot_name(obj, name)
        _pyir_check_cf_attr_first_def_read(obj, _slot)
        # A leaf seeded by its own default-taken miss in this region is
        # absent on the first iteration: its presence is path-dependent.
        _pyir_check_seeded_place_probe(obj, _slot)
        _pyir_spec_record_attr_probe(obj, name, present=True)
    return True


# Their native ``getattr`` runs the program's read: a property that consumes a
# trace-time payload (``python_value``) consumes it on the program's behalf.
_PYIR_NATIVE_INVOKE_CODES.add(_pyir_routed_getattr.__code__)
_PYIR_NATIVE_INVOKE_CODES.add(_pyir_routed_hasattr.__code__)


def _pyir_reflect_store(setter: Any, obj: Any, name: Any, value: Any) -> None:
    """Routed attribute store: the native write runs first (Python truth), then a
    STORAGE write replays through the write choke at this position -- the same
    lifecycle as an instrumented ``obj.name = value``."""
    if not _pyir_boundary_trace_active() or not isinstance(name, str):
        setter(obj, name, value)
        return
    raw = setter is _pyir_setattr_raw
    if not isinstance(obj, type) and (
        (not raw and _pyir_user_setattr_override(type(obj)) is not None)
        or (
            _pyir_property_setter(type(obj), name) is not None
            and _pyir_class_facts.transparent_property_backing(type(obj), name) is None
        )
    ):
        _pyir_property_store(obj, name, value, raw=raw)
        return
    if isinstance(obj, BaseException) and name in _PYIR_EXCEPTION_SLOT_NAMES:
        # Not instance storage: the syntactic choke's judgment, then the
        # native store (the setter's own type check runs first).
        setter(obj, name, value)
        filename, lineno = _first_non_dsl_caller_location()
        _pyir_judge_exception_slot_write(
            f"<setattr>.{name}", obj, name, filename, lineno
        )
        return
    slot = _pyir_canonical_slot_name(obj, name)
    pre = _pyir_boundary_current_value(obj, slot)
    setter(obj, name, value)
    if _pyir_boundary_current_value(obj, slot) is not value:
        return  # a descriptor rerouted the store: not a storage write here
    label = f"<setattr>.{name}"
    filename, lineno = _first_non_dsl_caller_location()
    old = (
        None
        if pre is _PYIR_BOUNDARY_MISSING
        else pyir_read(label, pre, owner=obj, slot_name=slot)
    )
    # A meta first-def of an attribute a SIBLING arm first defined (the arm
    # entry unbound it) is a write over the sibling's value: bind it as such
    # and the sibling-arm rule judges it; nothing else to assign or record.
    if (
        pre is _PYIR_BOUNDARY_MISSING
        and not _is_staged_value(value)
        and _pyir_bind_sibling_first_def(obj, slot, label, value=value)
    ):
        return
    result = pyir_assign(label, old, value, filename, lineno, owner=obj, slot_name=slot)
    if result is not value:
        _pyir_holder_store(obj, slot, result)
    # Meta first-def through reflection: record the binding position (a
    # staged first-def records through the assign choke).
    if pre is _PYIR_BOUNDARY_MISSING and not _is_staged_value(value):
        _pyir_record_cf_attr_first_def(obj, slot)


def _pyir_routed_setattr(obj: Any, name: Any, value: Any) -> None:
    _pyir_reflect_store(setattr, obj, name, value)


def _pyir_routed_object_setattr(obj: Any, name: Any, value: Any) -> None:
    _pyir_reflect_store(_pyir_setattr_raw, obj, name, value)


def _pyir_delete_attr(obj: Any, name: Any) -> None:
    """The one attribute-deletion funnel (syntactic ``del obj.name`` and routed
    ``delattr``; LangRef 3.12 sections 7.5 and 3.3.2): deletion is an unstageable
    binding effect, so inside dynamic staged CF it cannot be predicated on the
    region's runtime condition and refuses loudly."""
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
    """Staged-CF wall ahead of an in-body import statement (LangRef 3.12 section
    7.11): a FIRST import executes the module's code once at trace time, a side
    effect that cannot be predicated on a staged region's runtime condition --
    inside dynamic staged CF it refuses loudly, before that code runs."""
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
    (STORE_GLOBAL/DELETE_GLOBAL; one frame deep by construction), or None."""
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
    executes once at trace time, not once per runtime iteration, so every later
    read of that global is frozen at its first traced value."""
    if not is_inside_staged_cf() or is_inside_constexpr_loop():
        return
    name = _pyir_callee_global_write(callee)
    if name is None:
        return
    func = getattr(callee, "__func__", callee)
    filename, lineno = _first_non_dsl_caller_location()
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.UNSUP_GLOBAL_WRITE_IN_STAGED_CF,
            filename=filename,
            lineno=lineno,
            callee=getattr(func, "__qualname__", None) or "the called function",
            name=name,
        )
    )


_PYIR_GLOBAL_CONTAINER_TYPES = (list, dict, set)
# Above this many elements only the length of a module-global container is
# compared (bounded trace-time cost per boundary call).
_PYIR_GLOBAL_CONTAINER_IMAGE_CAP = 4096
_PYIR_STAGED_TOKEN = ("staged",)


def _pyir_global_container_image(value: Any, depth: int = 0) -> Any:
    """Reference-free image of a module-global container's META content: element
    count and order, Python-valued entries, nested builtin containers."""
    if _is_staged_value(value):
        return _PYIR_STAGED_TOKEN
    t = type(value)
    if t not in _PYIR_GLOBAL_CONTAINER_TYPES or depth > 3:
        return _pyir_cursor_atom(value)
    if len(value) > _PYIR_GLOBAL_CONTAINER_IMAGE_CAP:
        return (t.__name__, "len", len(value))
    if t is dict:
        return (
            "dict",
            tuple(
                (_pyir_cursor_atom(k), _pyir_global_container_image(v, depth + 1))
                for k, v in dict.items(value)
                if not _is_staged_value(v)
            ),
        )
    if t is list:
        return (
            "list",
            tuple(_pyir_global_container_image(v, depth + 1) for v in value),
        )
    return (
        "set",
        len(value),
        frozenset(_pyir_global_container_image(v, depth + 1) for v in value),
    )


# Method names that change a builtin container without observing it.
_PYIR_GLOBAL_MUTATOR_ATTRS = frozenset(
    (
        "append",
        "extend",
        "insert",
        "pop",
        "remove",
        "clear",
        "add",
        "discard",
        "update",
        "setdefault",
        "popitem",
        "sort",
        "reverse",
    )
)
_PYIR_PURE_LOAD_OPS = frozenset(
    ("LOAD_CONST", "LOAD_FAST", "LOAD_FAST_CHECK", "LOAD_FAST_AND_CLEAR", "LOAD_DEREF")
)
_PYIR_GLOBAL_VALUE_READ_SCANS: "dict[Any, frozenset]" = {}


# Stack shuffles and the arithmetic of ``G[k] OP= v`` between the subscript read and
# the store back into the same slot; a CALL, a store into a name or a jump means the
# read value escapes.
_PYIR_INPLACE_UPDATE_OPS = frozenset(
    {"COPY", "SWAP", "BINARY_SUBSCR", "BINARY_OP", "UNARY_NEGATIVE", "UNARY_NOT"}
)


def _pyir_is_inplace_subscr_update(ins: "list[Any]", j: int) -> bool:
    """Whether the instructions from *j* are ``G[k] OP= v`` (or the spelled-out
    ``G[k] = G[k] OP v``): the subscript is read only to be written back, so
    the global is mutated in place, not observed for its value."""
    k = j
    while k < len(ins) and k - j < 24:
        op = ins[k].opname
        if op == "STORE_SUBSCR":
            return k > j
        if op not in _PYIR_INPLACE_UPDATE_OPS and op not in _PYIR_PURE_LOAD_OPS:
            return False
        k += 1
    return False


def _pyir_callee_global_value_reads(callee: Any) -> "frozenset[str]":
    """Names of the module globals the callee's OWN bytecode reads for their VALUE
    (one frame deep, like the STORE_GLOBAL scan)."""
    func = getattr(callee, "__func__", callee)
    code = getattr(func, "__code__", None)
    if code is None:
        return frozenset()
    cached = _PYIR_GLOBAL_VALUE_READ_SCANS.get(code)
    if cached is not None:
        return cached
    names: "set[str]" = set()
    ins = list(_dis.get_instructions(code))
    for i, x in enumerate(ins):
        if x.opname != "LOAD_GLOBAL":
            continue
        j = i + 1
        if (
            j < len(ins)
            and ins[j].opname == "LOAD_ATTR"
            and ins[j].argval in _PYIR_GLOBAL_MUTATOR_ATTRS
        ):
            continue
        while j < len(ins) and ins[j].opname in _PYIR_PURE_LOAD_OPS:
            j += 1
        if (
            j > i + 1
            and j < len(ins)
            and ins[j].opname in ("STORE_SUBSCR", "DELETE_SUBSCR")
        ):
            continue
        if j > i + 1 and _pyir_is_inplace_subscr_update(ins, j):
            continue
        names.add(str(x.argval))
    result = frozenset(names)
    _PYIR_GLOBAL_VALUE_READ_SCANS[code] = result
    return result


# One outermost staged-loop trace: [outermost open loop block, value reads
# {(id(module dict), name)}, taints {(id(module dict), name): writer name}].
_PYIR_GLOBAL_LOOP_TRACE: "list[Any]" = [None, set(), {}]


def _pyir_global_loop_trace() -> "tuple[set, dict] | None":
    if not _pyir_open_loop_body_blocks:
        return None
    block = _pyir_open_loop_body_blocks[0]
    st = _PYIR_GLOBAL_LOOP_TRACE
    if st[0] is not block:
        st[0] = block
        st[1] = set()
        st[2] = {}
    return st[1], st[2]


def _pyir_refuse_global_write(writer: str, name: str) -> None:
    filename, lineno = _first_non_dsl_caller_location()
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.UNSUP_GLOBAL_WRITE_IN_STAGED_CF,
            filename=filename,
            lineno=lineno,
            callee=writer,
            name=name,
        )
    )


def _pyir_global_write_watch(callee: Any) -> "tuple | None":
    """Pre-call half of the two-hop backstop: for a user-module callee inside
    dynamic staged CF, capture the callee's module dict, its current bindings and
    -- inside a staged loop -- the META image of each builtin container bound
    there, so a transitive global write (invisible to the one-frame bytecode
    scan) is caught as a changed binding after the call, and an in-place
    container mutation as a changed image."""
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
    images: "dict[str, Any]" = {}
    trace = _pyir_global_loop_trace()
    if trace is not None:
        # A staged ``if`` body executes at most once at runtime as well, so outside
        # a loop the containers helpers bump stay trace-time bookkeeping (only a
        # rebinding is refused there).
        images = {
            k: _pyir_global_container_image(v)
            for k, v in before.items()
            if type(v) in _PYIR_GLOBAL_CONTAINER_TYPES
        }
        reads, taints = trace
        for name in _pyir_callee_global_value_reads(callee):
            key = (id(d), name)
            reads.add(key)
            writer = taints.get(key)
            if writer is not None:
                _pyir_refuse_global_write(writer, name)
    return (callee, d, before, images)


def _pyir_global_write_check(watch: "tuple | None") -> None:
    """Post-call half of the two-hop backstop: refuse on any rebound, added,
    or deleted module-global binding, and on a module-global list/dict/set
    whose META image changed in place (the binding is the same object; its
    frozen content is what every later read would see)."""
    if watch is None:
        return
    callee, d, before, images = watch
    changed = None
    for k, v in d.items():
        if not k.startswith("__") and (k not in before or before[k] is not v):
            changed = k
            break
    if changed is None:
        changed = next((k for k in before if k not in d), None)
    if changed is None and images:
        trace = _pyir_global_loop_trace()
        reads, taints = trace if trace is not None else (set(), {})
        func = getattr(callee, "__func__", callee)
        writer = getattr(func, "__qualname__", None) or "the called function"
        for k, image in images.items():
            if _pyir_global_container_image(before[k]) == image:
                continue
            key = (id(d), k)
            if key in reads:
                changed = k
                break
            # Mutated but never read for value so far: a log.  A later
            # value read in this loop trace names this callee as the writer.
            taints.setdefault(key, writer)
    if changed is None:
        return
    func = getattr(callee, "__func__", callee)
    filename, lineno = _first_non_dsl_caller_location()
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.UNSUP_GLOBAL_WRITE_IN_STAGED_CF,
            filename=filename,
            lineno=lineno,
            callee=getattr(func, "__qualname__", None) or "the called function",
            name=changed,
        )
    )


def _pyir_import_record(
    module: "str | None", level: int, package: "str | None", *pairs: tuple
) -> None:
    """Record arm behind an executed in-body import (meta flow): each bound name
    becomes a verified spec root (F-SPEC)."""
    if not _pyir_boundary_trace_active():
        return
    _pyir_spec_record_import(module, level, pairs, package)


def _pyir_routed_vars(*args: Any) -> Any:
    """Routed ``vars``: each instance-storage leaf read is recorded through the
    read choke, and the returned mapping funnels through the same read choke as
    an ``obj.__dict__`` attr read (``vars(obj)`` IS ``obj.__dict__`` -- one
    adoption funnel, so writes into it carry)."""
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
    answered from the partial view, so it refuses; the source program's
    full-scope ``locals()`` has no counterpart here."""

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
    (library ref section `vars`: zero-arg ``vars()`` == ``locals()``)."""
    if callee is not _builtins.locals and callee is not _builtins.vars:
        return mapping
    if not in_synth or not isinstance(mapping, dict):
        return mapping
    if not _pyir_boundary_trace_active():
        return mapping
    return _PyirSynthLocalsView(mapping)


def _pyir_routed_dict_view(view: Any) -> Any:
    """Routed unbound ``dict.keys/values/items`` (``dict.items(d)``): the bound
    spelling routes at the dispatcher's receiver check; the unbound base-class
    call carries the receiver as ``args[0]`` and must hit the same iteration
    choke before the view raw-iterates storage."""

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
    """Routed C-implemented stdlib container mutator (the ``heapq`` module functions
    / ``bisect.insort`` family): the mutation happens inside C code, so it
    performs no Python-level attribute call or subscript store for the method
    guard or the subscript-write choke to see."""
    funnel = _PyirMetaUnwrapProxy(fn)
    module_name, _, func_name = spelling.rpartition(".")

    def _routed(*args: Any, **kwargs: Any) -> Any:
        if is_inside_staged_cf() and not is_inside_constexpr_loop():
            # Every routed function mutates ONLY its first argument (the heap / the
            # sorted sequence; ``bisect.insort`` also accepts it as keyword ``a``).
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


# C-implemented stdlib functions that mutate a caller-owned container argument in
# place, keyed by function-object identity like the reflection routes (the table
# tuple holds the function, so its id cannot be recycled).
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
# A comprehension's loop variables are comprehension-local, but a walrus target
# binds in the ENCLOSING scope (PEP 572) -- without this, ``fn`` leaks into the
# module namespace and rides the export chain.
del fn


# Receiver-carrying spellings of a deque mutation: the method-name guard tables key
# on attribute-call SYNTAX, so an aliased bound method (``push = q.append;
# push(x)``) and the in-place dunders (``q += .../q *= ...`` route
# ``deque.__iadd__``/``__imul__`` through this dispatcher via
# ``_pyir_inplace_binop``) have no object-side choke -- a plain deque is never
# adopted as a watched container -- so they route here.
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
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.BOUNDARY_MEMOIZED_IN_STAGED_CF,
            filename=filename,
            lineno=lineno,
            name=getattr(func, "__name__", "this function"),
        )
    )


def _pyir_call_boundary_(
    callee: Any,
    sc_rhs: bool = False,
    fresh_args: "tuple[int, ...]" = (),
    births_seen: bool = False,
) -> Any:
    """Trace-time dispatcher: proxy a plain user-module callable, return anything
    else unchanged; *sc_rhs* marks a short-circuited operand (effects refuse);
    *fresh_args* are the positional arguments the rewrite proved born for the
    call (a comprehension or generator expression); *births_seen* marks a call
    site in a rewritten body, whose displays and results the rewriter births (the
    traced body's own guard owns the receivers it spells)."""
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
        # Tracked-dict view iteration (``d.keys()/.values()/.items()``): the views
        # raw-iterate storage, so pair/value consumption would bypass the item read
        # choke -- a trace-time snapshot.
        _iter_recv = getattr(callee, "__self__", None)
        if isinstance(_iter_recv, _WatchedDict):
            # A tracked dict's own mutator spelled as a method call: the
            # element hooks serve it entry by entry.
            routed = _pyir_cal_native_callee(callee)
            if routed is not None:
                return routed
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
        # Deque mutator reached through the callable's own receiver (bound method
        # alias, or the in-place dunder ``_pyir_inplace_binop`` dispatches here):
        # refuse inside dynamic staged CF exactly like the attribute-call guard;
        # trace-time and constexpr mutation stay legal.
        if (
            isinstance(_iter_recv, _collections.deque)
            and getattr(callee, "__name__", None) in _PYIR_DEQUE_BOUND_MUTATORS
            and is_inside_staged_cf()
            and not is_inside_constexpr_loop()
        ):
            filename, lineno = _first_non_dsl_caller_location()
            raise _pyir_fatal_trace_error(
                DSLUserCodeError(
                    DiagId.UNSUP_META_CONTAINER_MUTATION,
                    filename=filename,
                    lineno=lineno,
                    container="deque",
                    method=callee.__name__,
                    kind="deque",
                )
            )
        # Jit-decorated / DSL-preprocessed callables trace anyway; so does a def /
        # lambda nested in a preprocessed body (its code object came out of the same
        # compile), whose free-variable reads are recorded.
        if (
            hasattr(func, "_preprocessed")
            or hasattr(func, "_dsl_cls")
            or hasattr(func, "_dsl_object")
            or _pyir_callee_is_rewritten(func)
        ):
            return callee
        if _pyir_code_is_preprocessed(getattr(func, "__code__", None)):
            _pyir_boundary_note_nested_scope_reads(func)
            return callee
        if isinstance(callee, _PyirMetaUnwrapProxy):
            return callee
        if not callable(callee):
            return callee
        # functools.partial: identity and observation belong to ``.func``; the
        # frozen args re-enter the dispatched callee as ordinary call args, so a
        # born argument's position shifts past them.
        if type(callee) is _functools.partial:
            shift = len(callee.args)
            inner = _pyir_call_boundary_(
                callee.func,
                sc_rhs,
                tuple(i + shift for i in fresh_args),
                births_seen,
            )
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
        mod = getattr(func, "__module__", None)
        # A function compiled from a string in a bare namespace carries no module:
        # it is user-shaped code without a source file, and the rewrite arm refuses
        # it inside staged CF.
        generated_user_code = mod is None and isinstance(func, _types.FunctionType)
        if not generated_user_code and not _pyir_boundary_module_is_user(mod):
            if _pyir_boundary_module_consumes_wrappers(mod):
                dsl_callee: Any = callee
                if is_inside_staged_cf() and not is_inside_constexpr_loop():
                    dsl_callee = _PyirResultObserver(callee)
                if births_seen:
                    # A rewritten body hands the DSL layer the meta PAYLOAD of an
                    # unpromoted place, as the native callee it replaces did (a
                    # wrapper would bake an SSA constant and turn a static shape
                    # dynamic); the consumption is witnessed for a later promotion.
                    return _PyirMetaPayloadCall(dsl_callee, callee)
                return dsl_callee
            # A wrapper masking a user target (``__wrapped__``) is classified
            # by the target: its interior user-frame writes must be observed.
            wrapped_mod = _pyir_wrapped_user_module(func)
            if wrapped_mod is None:
                routed = _pyir_cal_native_callee(callee, births_seen)
                if routed is not None:
                    return routed
                return _PyirMetaUnwrapProxy(callee, fresh_args, births_seen)
            mod = wrapped_mod
        # A plain callee's module may carry no jit decoration; funnel it
        # through the class-facts materializer so write facts exist by commit.
        if isinstance(mod, str):
            _pyir_class_facts.ensure_module_materialized(mod)
        return _pyir_callee_rewrite_dispatch(callee, sc_rhs, fresh_args)
    except DSLUserCodeError:
        raise
    except Exception as exc:
        # A classification failure is fatal: a swallowed one would skip the
        # observation and let the callee's effects replay unpredicated.
        raise DSLRuntimeError(
            "PyIR emission self-check: call-boundary classification failed "
            f"for a callee of type {type(callee).__name__}: {exc}"
        ) from exc


# -- In-place operator routing: an AugAssign dispatches its dunder with no
# ast.Call, so the wrap pass cannot reach it; the preprocessor rewrites the
# statement into this helper, which resolves the in-place slot exactly like CPython
# and routes the bound dunder through the SAME boundary dispatcher.

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
# interpreter's setattr with no ast.Call; the preprocessor funnels the store here so
# the bound setter routes through the same boundary dispatcher.

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
    """The user-authored, value-TRANSFORMING ``__setattr__`` governing stores on
    *cls* instances (mro-exact, cached); ``None`` when stores are plain or
    provably storage-transparent."""
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
    """Pure target fact: does storing ``obj.name`` invoke user-defined store code (a
    property setter or a user ``__setattr__`` override) that the rewritten-choke
    store pattern may NOT replay? Decides the store branch BEFORE the RHS
    evaluates (native order keeps the RHS after the tracer's pre-store refresh)."""
    if _pyir_user_setattr_override(type(obj)) is not None:
        return True
    if _pyir_property_setter(type(obj), name) is None:
        return False
    return _pyir_class_facts.transparent_property_backing(type(obj), name) is None


def _pyir_property_store(obj: Any, name: str, value: Any, *, raw: bool = False) -> None:
    """Route a store with user-defined store code through it exactly once at the
    call boundary (observed, predicated commit of the storage writes)."""
    _pyir_register_candidate_holder(obj)
    override = None if raw else _pyir_user_setattr_override(type(obj))
    if override is not None:
        _pyir_call_boundary_(override.__get__(obj, type(obj)))(name, value)
        return
    fset = _pyir_property_setter(type(obj), name)
    if fset is None:
        (_pyir_setattr_raw if raw else setattr)(obj, name, value)
        return
    _pyir_call_boundary_(fset.__get__(obj, type(obj)))(value)


def _pyir_boundary_routed_setitem(container: "Any") -> "Any | None":
    """The USER-defined ``__setitem__`` a store into *container* has to run through
    the call boundary, or None when the native store stands."""
    if isinstance(container, (dict, list)):
        return None
    if _is_staged_value(container) or _implements_dynamic_expression(container):
        return None
    if not is_inside_staged_cf() or is_inside_constexpr_loop():
        return None
    for klass in type(container).__mro__:
        setter = vars(klass).get("__setitem__")
        if setter is None:
            continue
        func = getattr(setter, "__func__", setter)
        if not _pyir_boundary_module_is_user(getattr(func, "__module__", None)):
            return None
        return setter if hasattr(setter, "__get__") else None
    return None


def _pyir_subscript_store(container: Any, key: Any, value: Any) -> None:
    """The single store choke for ``container[key] = value``."""
    setter = _pyir_boundary_routed_setitem(container)
    if setter is None:
        container[key] = value
        return
    bound = setter.__get__(container, type(container))
    _pyir_call_boundary_(bound)(key, value)


def _pyir_delete_item(container: Any, key: Any, label: str) -> None:
    """The single delete choke for ``del container[key]`` in a traced body
    (*label* is the target's spelling): the plain dict / list key wall ahead
    of the native delete, so a Staged key refuses instead of missing by
    identity; a container running its own ``__delitem__`` (an adopted watched
    container included) is left to it."""
    _pyir_item_key_wall(container, key, label.split("[", 1)[0], "__delitem__")
    del container[key]


def _pyir_inplace_binop(op: str, lhs: Any, rhs: Any, label: "str | None" = None) -> Any:
    """``lhs op= rhs`` VALUE semantics (CPython's in-place protocol) with the
    resolved dunder routed through the call boundary, so a user-class
    ``__iadd__`` mutating its receiver is observed like any boundary call.
    ``d |= other`` on a plain dict is ``d.update(other)``: the union's keys
    take the dict key wall ahead of the native ``__ior__`` (*label* names the
    target when the rewriter knows it), where a Staged key would otherwise
    insert an identity-keyed entry silently."""
    if op == "or" and type(lhs) is dict:
        (rhs,) = _pyir_cal_method_key_wall(lhs, "update", (rhs,), label)
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


def _pyir_ctx_boundary(obj: Any) -> Any:
    """Trace-time dispatcher for the WITH-protocol boundary; a dispatch failure
    falls back to the unwrapped manager (see :class:`_PyirCtxBoundaryProxy`)."""
    try:
        if not _pyir_boundary_trace_active():
            return obj
        cls = type(obj)
        # DSL-authored managers trace their own effects.
        if hasattr(cls, "_dsl_cls") or hasattr(cls, "_dsl_object"):
            return obj
        if not _pyir_boundary_module_is_user(getattr(cls, "__module__", None)):
            return obj
        if _PYIR_SIGHT_HOOK[0] is not None:
            _PYIR_SIGHT_HOOK[0](obj)  # its ``__enter__`` / ``__exit__`` observe
        return obj
    except Exception:
        return obj


# -- Births: objects created inside the open region.


def _pyir_strong_handle(obj: Any) -> Any:
    """A weakref-shaped handle (``handle() is obj``) that pins *obj*."""
    return lambda: obj


def _pyir_boundary_note_birth(obj: Any) -> None:
    """Record that *obj* was born inside the innermost open loop body (if any)."""
    if not _pyir_open_loop_body_blocks:
        return
    try:
        handle = _weakref.ref(obj)
    except TypeError:
        # ``__slots__`` without ``__weakref__``: a strong pin would show up as an
        # extra referrer to the fresh-object witness, so record nothing.
        if not isinstance(obj, BaseException) or _pyir_boundary_module_is_user(
            getattr(type(obj), "__module__", None)
        ):
            return
        handle = _pyir_strong_handle(obj)
    _PYIR_BOUNDARY_BIRTH_BLOCK[id(obj)] = (handle, _pyir_open_loop_body_blocks[-1])


def _pyir_boundary_birth_anchor(holder: Any) -> "ir.Block | None":
    """The still-open loop-body block *holder* was born in, else ``None``."""
    entry = _PYIR_BOUNDARY_BIRTH_BLOCK.get(id(holder))
    if entry is None:
        return None
    handle, block = entry
    if handle() is not holder:
        return None  # a recycled address: not this object's birth
    return (
        block
        if any(block == open_block for open_block in _pyir_open_loop_body_blocks)
        else None
    )


def _pyir_boundary_declare_birth_place(holder: Any, place: Any) -> "ir.Block | None":
    """Declare *place* region-born when *holder* was born in an open loop body
    (F-BIRTHPOS): a promotion then seeds the cell in that body, per iteration,
    and an SSA-backed mint anchors there."""
    anchor = _pyir_boundary_birth_anchor(holder)
    if anchor is not None and place is not None:
        _slot_first_def_inside_cf[place] = True
        _slot_first_def_block[place] = anchor
    return anchor


def _pyir_boundary_callee_name(callee: Any) -> str:
    """Diagnostics-only: the callee's qualified name, or its type's name."""
    func = getattr(callee, "__func__", callee)
    return getattr(func, "__qualname__", None) or type(callee).__name__


def _pyir_boundary_bind_leaf(holder: Any, key: Any, value: Any) -> bool:
    """Raw rebind of one snapshot leaf: instance storage never runs a data
    descriptor's ``__set__``; class, dict, list and closure-cell holders take
    the raw holder store."""
    if isinstance(holder, (dict, list, _types.CellType, type)):
        try:
            _pyir_holder_store(holder, key, value)
        except Exception:
            return False
        return True
    return _pyir_boundary_bind_storage(holder, key, value)


# -- Jit-entry read binds over a call's taken defaults (dsl.py).


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
        if isinstance(obj, _types.FunctionType):
            # A nested def held in storage (a closure counter, LangRef §8.7
            # defaults): its cells and attributes are leaves the callee can read
            # raw, keyed exactly as the snapshot diff keys them.
            if not _pyir_boundary_module_is_user(
                getattr(obj, "__module__", None)
            ) or _pyir_boundary_is_traced_callable(obj):
                return
            for cell in obj.__closure__ or ():
                _bind_scalar_leaf(
                    cell,
                    "cell_contents",
                )
            _walk(obj.__defaults__)
            _walk(obj.__kwdefaults__)
            for name, v in list((getattr(obj, "__dict__", None) or {}).items()):
                if not _bind_scalar_leaf(obj, name):
                    _walk(v)
            return
        if isinstance(obj, _types.MethodType):
            _walk(obj.__self__)
            _walk(obj.__func__)
            return
        sub_items = _pyir_builtin_subclass_storage(obj)
        if sub_items is not None:
            for v in list(sub_items.values()):
                _walk(v)
        if isinstance(obj, (dict, list)):
            vals = list(dict.values(obj)) if isinstance(obj, dict) else list(obj)
            for v in vals:
                _walk(v)
            return
        if isinstance(obj, (tuple, set, frozenset)):
            for v in list(obj):
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
            if not _bind_scalar_leaf(obj, name):
                _walk(v)

    def _bind_scalar_leaf(holder: Any, name: str) -> bool:
        """Bind a plain-scalar leaf to its place-attributed wrapper; ``False``
        when the leaf is not a plain scalar (the caller walks into it)."""
        v = _pyir_boundary_current_value(holder, name)
        if type(v) not in (bool, int, float) or not isinstance(name, str):
            return False
        try:
            place = _make_slot_key(None, holder, name)
        except Exception:
            place = None
        if place is None:
            return True
        wrapper = _WatchedM(v, place)
        if _pyir_boundary_bind_leaf(holder, name, wrapper):
            records.append((holder, name, wrapper, v))
        return True

    for r in roots:
        _walk(r)
    return records


def _pyir_boundary_stage_taken_default_reads(
    callee: Any, args: Any, kwargs: Any
) -> "list[tuple[Any, str, Any, Any]]":
    """Tier-2 read binds over an INLINE rewritten callee's taken defaults: a read-
    only attr chain in a rewritten body reaches no choke, so plain-meta leaves
    bind to place-attributed wrappers exactly as the dispatcher proxy stages its
    walk roots."""
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
            if _pyir_boundary_current_value(holder, name) is wrapper:
                _pyir_boundary_bind_leaf(holder, name, original)
        except Exception:
            continue


# -- Storage values, nested-scope reads, constructor births, poison check.


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


def _pyir_boundary_note_nested_scope_reads(func: Any) -> None:
    """A def or lambda nested in an instrumented body reads a free variable from the
    enclosing frame's cell, while a region body carries its writes of that local
    through parameters and results: the cell keeps the value from before the
    region."""
    if not is_inside_staged_cf():
        return
    closure = getattr(func, "__closure__", None)
    code = getattr(func, "__code__", None)
    if not closure or code is None:
        return
    for name, cell in zip(code.co_freevars, closure):
        tok = _pyir_lookup_owner_token(cell)
        if tok is None or tok not in _PYIR_CELL_HOME_BINDING:
            continue
        try:
            contents = cell.cell_contents
        except ValueError:
            continue
        if type(contents) in (bool, int, float) or isinstance(contents, _WatchedM):
            _PYIR_BOUNDARY_META_CELL_READS.setdefault(
                ("cell", tok), (name, code.co_filename, code.co_firstlineno)
            )


def _pyir_boundary_record_ctor_birth(result: Any, visited: "set[int]") -> None:
    """Mint the owner token (which stamps F-CLASS) for each object in *result* NOT
    reachable at snapshot time and never tokenized -- the birth event."""

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
        if isinstance(obj, (dict, list, tuple, set, frozenset)):
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
        tok = _owner_token(obj)  # birth mint (stamps F-CLASS)
        # The bind choke's call-born witness reads this mint as "born by the
        # returning statement", not as an earlier sighting.
        if tok is not None:
            _PYIR_BOUNDARY_BORN_TOKENS.add(tok)
        _pyir_boundary_note_birth(obj)
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


# -- Registries -------------------------------------------------------------

# Code objects produced by a rewrite (the rewritten function's own code and every
# nested code object inside it): a function running one of these is already
# observed, whatever object carries it.
_REWRITTEN_CODES: "set[Any]" = set()
# Original code object -> rewritten code object, or None when the source is
# unreachable; a second function object sharing the original code (a nested def or
# lambda created per call) swaps in O(1) instead of parsing again.
_REWRITE_CACHE: "dict[Any, Any]" = {}
# Rewritten code object -> the original (debug listing, rewrite-time facts).
_ORIGINAL_CODES: "dict[Any, Any]" = {}
# Classes whose own callables are swapped for the open trace.
_INSTRUMENTED_CLASSES: "set[type]" = set()
# Functions swapped for the open trace: id -> (function, original code); the
# trace-close hook restores them so host code runs the original bodies.
_SWAPPED_FUNCTIONS: "dict[int, tuple[Any, Any]]" = {}
# Class attribute replacements for the open trace: (class, name, original).
_SWAPPED_CLASS_ATTRS: "list[tuple[type, str, Any]]" = []
# class -> observed replacement for its generated dataclass __init__.
_DATACLASS_INITS: "dict[type, Any]" = {}
# Depth of plain callees currently running as a short-circuited ``and``/``or``
# operand: their stores cannot follow the runtime guard, so they refuse.
_PYIR_SC_RHS_DEPTH: "list[int]" = [0]
# Parsed module ASTs / symbol tables keyed by filename (a file does not
# change mid-process).
_FILE_AST_CACHE: "dict[str, Any]" = {}
_FILE_SYMTABLE_CACHE: "dict[str, Any]" = {}
# filename -> is this file user code (not stdlib / site-packages / the DSL)?
_FILE_USER_VERDICT: "dict[str, bool]" = {}
# id(obj) -> (pin, region-arm path) for objects born inside a plain callee at trace
# time (see the module docstring): trace-internal while the same region arm is open,
# published when stored into a place.
_REGION_BORN: "dict[int, tuple[Any, tuple]]" = {}
# (id(owner), name) of the attribute accesses currently inside a hook on the tracing
# thread: a user ``__getattr__`` / ``__setattr__`` re-entering the same access is
# served natively instead of recursing through the chokes.
_ACTIVE_ACCESS: "set[tuple[int, str]]" = set()
# (id(owner), name) -> (owner, pre-delete value, region-arm path): an attribute
# deleted inside dynamic staged CF, pending its re-binding in the same region
# (delete-then-rebind is a store); left pending when the region closes, it refuses.
_PENDING_DELETES: "dict[tuple[int, str], tuple[Any, Any, tuple]]" = {}
# id(obj) -> (pin, field label): tracked user objects a field rebind inside
# dynamic staged CF displaced from their field path this trace.
_DETACHED: "dict[int, tuple[Any, str]]" = {}
# id(obj) -> pin: user holders read into a VALUE position this trace (bound to a
# local, stored into another place, held by a bound method): a later rebind of the
# field that holds them would update the holder in place under the alias.
_HELD: "dict[int, Any]" = {}
# id -> pin: user objects that have a home (read out of a place, or bound
# once).  A further binding of a homed object is an alias and holds it.
_HOMED: "dict[int, Any]" = {}
# id -> (pin, label): the source spelling a non-scalar value was last read under in
# a plain callee (``self.members``, a module-global name); names the receiver /
# argument in the refusals of native calls.
_READ_LABELS: "dict[int, tuple[Any, str]]" = {}


def _pyir_cal_note_label(value: Any, label: str) -> None:
    if (
        value is None
        or type(value) in _SCALAR_TYPES
        or (
            isinstance(value, _CALLABLE_VALUE_TYPES)
            and not isinstance(value, _types.ModuleType)
        )
    ):
        return
    if len(_READ_LABELS) > 65536:
        _READ_LABELS.clear()
    _READ_LABELS[id(value)] = (_pyir_cal_pin(value), label)


def _pyir_cal_label_of(obj: Any, default: str = "<receiver>") -> str:
    entry = _READ_LABELS.get(id(obj))
    return entry[1] if entry is not None and entry[0]() is obj else default


def _pyir_cal_has_label(obj: Any) -> bool:
    entry = _READ_LABELS.get(id(obj))
    return entry is not None and entry[0]() is obj


# id(dict) -> dict: module namespaces handed out as ``module.__dict__`` this trace
# (host state: element writes inside dynamic staged CF refuse).
_HOST_CONTAINERS: "dict[int, tuple[Any, str]]" = {}


class _PyirTracePin:
    """A strong hold on a traced value that allows no weak reference (a list, a
    ``__slots__`` instance)."""

    __slots__ = ("_pyir_value",)

    def __init__(self, value: Any) -> None:
        self._pyir_value = value

    def __call__(self) -> Any:
        return self._pyir_value


class _PyirItemProbe(_PyirTracePin):
    """``container[key]`` re-read at trace close (the destination probe of a
    watched-meta store)."""

    __slots__ = ("_pyir_key",)

    def __init__(self, container: Any, key: Any) -> None:
        super().__init__(container)
        self._pyir_key = key

    def __call__(self) -> Any:
        try:
            return self._pyir_value[self._pyir_key]
        except Exception:
            return None


class _PyirAttrProbe(_PyirTracePin):
    """The owner's own binding of an attribute re-read at trace close."""

    __slots__ = ("_pyir_name",)

    def __init__(self, obj: Any, name: Any) -> None:
        super().__init__(obj)
        self._pyir_name = name

    def __call__(self) -> Any:
        return _pyir_cal_stored_value(self._pyir_value, self._pyir_name)


class _PyirCellProbe(_PyirTracePin):
    """A closure cell's contents re-read at trace close."""

    __slots__ = ()

    def __call__(self) -> Any:
        return getattr(self._pyir_value, "cell_contents", None)


def _pyir_cal_pin(obj: Any) -> Any:
    """A weak reference to *obj*, or a trace pin where the type allows none;
    both answer the object when called."""
    try:
        return _weakref.ref(obj)
    except TypeError:
        return _PyirTracePin(obj)


_PYIR_TRACE_BOOKKEEPING_HOOKS.append(lambda ref, value: isinstance(ref, _PyirTracePin))
_PYIR_WRITER_AT_HOOK[0] = lambda filename, lineno: _pyir_cal_writer_at(filename, lineno)
_PYIR_TRACE_KEEPALIVES.append(_HOST_CONTAINERS)
# id(obj) -> (pin, set of names): owners whose instance-storage KEY SET changed
# inside a dynamic staged region this trace (a first binding or a deletion).
_KEYSET_CHANGED: "dict[int, tuple[Any, set]]" = {}
# (id(obj), name) -> (pin, region arm path): attributes first bound inside a dynamic
# staged region arm this trace (a deletion in the same arm unbinds a binding the
# region itself made).
_BORN_BINDINGS: "dict[tuple[int, str], tuple[Any, tuple]]" = {}
# Generators a native callee is about to advance: (generator, suspension
# point before the call); a moved point after the call is host state.
_GEN_PROBES: "list[list[tuple[Any, Any]]]" = []
# (class, name) -> the cached_property / user descriptor object, or None.
_CACHED_PROPERTY_FACTS: "dict[tuple[type, str], Any]" = {}
_DESCRIPTOR_FACTS: "dict[tuple[type, str], Any]" = {}
_MEMBER_MISS = object()

_RT = "__pyir_rt__"
# The rewritten code imports THIS module (every choke it calls is defined here
# or star-imported from the chain below); the facade re-exports nothing of it.
_RT_MODULE = __name__
_CELL_PREFIX = "__pyir_cell_"

_BARE_BUILTIN_SKIP = frozenset({"range", "type", "super", "locals", "vars"})

_AUG_OPS: "dict[type, str]" = {
    _ast.Add: "add",
    _ast.Sub: "sub",
    _ast.Mult: "mul",
    _ast.MatMult: "matmul",
    _ast.Div: "truediv",
    _ast.FloorDiv: "floordiv",
    _ast.Mod: "mod",
    _ast.Pow: "pow",
    _ast.LShift: "lshift",
    _ast.RShift: "rshift",
    _ast.BitOr: "or",
    _ast.BitXor: "xor",
    _ast.BitAnd: "and",
}

_SCALAR_TYPES = (int, float, bool, str, bytes, type(None), complex)
_CALLABLE_VALUE_TYPES = (
    _types.MethodType,
    _types.FunctionType,
    _types.BuiltinMethodType,
    _types.MethodWrapperType,
    _types.WrapperDescriptorType,
    _types.MethodDescriptorType,
    type,
    _types.ModuleType,
)
_EXCEPTION_SLOTS = frozenset(
    {
        "args",
        "__cause__",
        "__context__",
        "__suppress_context__",
        "__traceback__",
        "__notes__",
    }
)
_BUILTIN_CONTAINER_BASES = (tuple, list, dict, set, frozenset)
_DESCRIPTOR_TYPES = (_types.MemberDescriptorType, _types.GetSetDescriptorType, property)
# Native callables whose result is a NEW object (a constructor or factory): the
# result is born in the region.
_FACTORY_MODULES = frozenset(
    {
        "copy",
        "itertools",
        "inspect",
        "dataclasses",
        "collections",
        "operator",
        "weakref",
        "re",
    }
)
_FACTORY_BUILTINS = frozenset(
    getattr(_builtins, n)
    for n in ("sorted", "reversed", "enumerate", "zip", "map", "filter", "iter")
)
_FACTORY_METHODS = frozenset(
    {"bind", "bind_partial", "copy", "fromkeys", "keys", "values", "items"}
)

# -- Host state: what native code advances and no choke can carry -------------

_KIND_MODULE = "a module object (its attributes are host state, not carried fields)"
_KIND_THREAD_LOCAL = (
    "a thread-local object (its attributes are host state, not carried fields)"
)
_KIND_GENERATOR = "a suspended Python generator/coroutine"
_KIND_RNG = "a Python random-number generator"
_KIND_DEQUE = "a Python deque"
_KIND_ORDERED_DICT = "an OrderedDict (its entry order is host state)"
_KIND_BUFFER = "a mutable native buffer"
_KIND_FINALIZER = "a weakref finalizer (its callback runs at most once)"
_KIND_ITERATOR = "a Python iterator"
_KIND_CONTEXTVAR = "a context variable (its value is host state)"
_KIND_EXCEPTION = (
    "an exception object's built-in state (args, __cause__, __context__, "
    "__suppress_context__, __traceback__, __notes__)"
)
_KIND_FUNCTION = (
    "a function object (its __defaults__, __code__ and __dict__ are host state)"
)
_KIND_CALLABLE_ATTR = (
    "a callable-valued attribute (which code runs was decided at trace time)"
)
_KIND_OPERATOR_SCALAR = (
    "a user-defined int/float subclass with its own operator methods"
)
_KIND_CACHED_PROPERTY = "a functools.cached_property (its getter runs at most once)"
_KIND_EXEC = "code compiled from a string at trace time"
_KIND_BORN_CLOSURE = (
    "a closure created inside the body (its cells hold the values of this trace pass)"
)
_KIND_PLAIN_SET = "set"
_KIND_PLAIN_LIST = "list"
_KIND_PLAIN_DICT = "dict"
_PLAIN_CONTAINER_KINDS: "dict[type, str]" = {
    set: _KIND_PLAIN_SET,
    list: _KIND_PLAIN_LIST,
    dict: _KIND_PLAIN_DICT,
}

_PLAIN_CONTAINER_TYPES = tuple(_PLAIN_CONTAINER_KINDS)

_ITERATOR_MODULES = frozenset({"builtins", "itertools", "_collections", "_io", "io"})

# Mutating methods of the plain builtin containers (the unbound-descriptor
# routes and the plain-receiver wall share these spellings).
_SET_MUTATORS = (
    "__ior__",
    "__iand__",
    "__isub__",
    "__ixor__",
    "add",
    "discard",
    "remove",
    "pop",
    "clear",
    "update",
    "difference_update",
    "intersection_update",
    "symmetric_difference_update",
    "__ior__",
    "__iand__",
    "__isub__",
    "__ixor__",
)
_LIST_MUTATORS = (
    "__iadd__",
    "__imul__",
    "append",
    "extend",
    "insert",
    "pop",
    "remove",
    "clear",
    "reverse",
    "sort",
    "__setitem__",
    "__delitem__",
    "__iadd__",
    "__imul__",
)
_DICT_MUTATORS = (
    "__setitem__",
    "__delitem__",
    "__ior__",
    "update",
    "pop",
    "popitem",
    "setdefault",
    "clear",
)
# ``x op= y`` on a container mutates it in place through this dunder.
_INPLACE_CONTAINER_DUNDERS = {
    "add": "__iadd__",
    "mul": "__imul__",
    "or": "__ior__",
    "and": "__iand__",
    "sub": "__isub__",
    "xor": "__ixor__",
}

# Per kind: the receiver methods that ADVANCE the state (None = every method).
_MUTATORS: "dict[str, frozenset | None]" = {
    _KIND_GENERATOR: None,
    _KIND_ITERATOR: None,
    _KIND_RNG: None,
    _KIND_FINALIZER: frozenset({"__call__", "detach"}),
    _KIND_CONTEXTVAR: frozenset({"set", "reset"}),
    _KIND_DEQUE: _PYIR_DEQUE_MUTATORS
    | frozenset({"__iadd__", "__imul__", "__setitem__", "__delitem__"}),
    _KIND_ORDERED_DICT: frozenset(
        {
            "move_to_end",
            "popitem",
            "update",
            "pop",
            "setdefault",
            "clear",
            "__setitem__",
            "__delitem__",
            "__ior__",
        }
    ),
    _KIND_BUFFER: frozenset(
        {
            "append",
            "extend",
            "insert",
            "pop",
            "remove",
            "reverse",
            "clear",
            "frombytes",
            "fromlist",
            "fromfile",
            "fromunicode",
            "byteswap",
            "__setitem__",
            "__delitem__",
            "__iadd__",
            "__imul__",
        }
    ),
    _KIND_EXCEPTION: frozenset({"with_traceback", "add_note"}),
    _KIND_PLAIN_SET: frozenset(_SET_MUTATORS),
    _KIND_PLAIN_LIST: frozenset(_LIST_MUTATORS),
    _KIND_PLAIN_DICT: frozenset(_DICT_MUTATORS),
}
_RNG_READERS = frozenset(
    {"getstate", "__repr__", "__str__", "__reduce__", "__getstate__"}
)
_ITERATOR_INSPECTORS = frozenset(
    {"type", "id", "isinstance", "issubclass", "repr", "iter", "hash", "callable"}
)
_BUFFER_INSPECTORS = _ITERATOR_INSPECTORS | frozenset(
    {
        "len",
        "bytes",
        "str",
        "memoryview",
        "list",
        "tuple",
        "sum",
        "min",
        "max",
        "any",
        "all",
        "sorted",
        "print",
        "unpack",
        "unpack_from",
        "iter_unpack",
        "calcsize",
    }
)
# Unbound builtin container mutators (``list.append(lst, x)`` spelling).
_UNBOUND_MUTATOR_NAMES: "dict[type, tuple[str, ...]]" = {
    list: _LIST_MUTATORS,
    dict: _DICT_MUTATORS,
    set: _SET_MUTATORS,
}


def _pyir_cal_host_state_kind(obj: Any) -> "str | None":
    """The host-state family *obj* belongs to, or None for carried state."""
    if obj is None:
        return None
    cls = type(obj)
    if cls in _SCALAR_TYPES:
        return None
    if issubclass(cls, _types.ModuleType):
        return _KIND_MODULE if _pyir_module_is_host_state(obj) else None
    if issubclass(cls, _threading.local):
        return _KIND_THREAD_LOCAL
    if issubclass(
        cls, (_types.GeneratorType, _types.CoroutineType, _types.AsyncGeneratorType)
    ):
        return _KIND_GENERATOR
    if issubclass(cls, _random.Random):
        return _KIND_RNG
    if issubclass(cls, _collections.deque):
        return _KIND_DEQUE
    if issubclass(cls, _collections.OrderedDict):
        return _KIND_ORDERED_DICT
    if issubclass(cls, (bytearray, memoryview, _array.array)):
        return _KIND_BUFFER
    if cls.__module__ == "numpy" and cls.__name__ == "ndarray":
        return _KIND_BUFFER
    if cls in _DICT_VIEW_TYPES:
        return _KIND_DICT_VIEW
    if cls is _types.MappingProxyType:
        return _KIND_MAPPING_PROXY
    if issubclass(cls, _weakref.finalize):
        return _KIND_FINALIZER
    if issubclass(cls, _contextvars.ContextVar):
        return _KIND_CONTEXTVAR
    if issubclass(cls, (_types.FunctionType, _types.MethodType)):
        return _KIND_FUNCTION
    if hasattr(cls, "__next__") and cls.__module__ in _ITERATOR_MODULES:
        return _KIND_ITERATOR
    if issubclass(cls, BaseException):
        return _KIND_EXCEPTION
    return None


# (filename, lineno) -> qualified def name: the file's AST is static, so the
# answer is too (bounded; cleared with the other registries at trace close).
_WRITER_AT_CACHE: "dict[tuple[str, int], str]" = {}


def _pyir_cal_writer_at(filename: "str | None", lineno: "int | None") -> str:
    """The qualified name of the def enclosing source position
    *filename*:*lineno* (``Outer.method``), or the position itself when no
    def of the file's AST spans it."""
    fallback = f"plain code at {_os.path.basename(filename or '<unknown>')}:{lineno}"
    if not filename or not lineno:
        return fallback
    cached = _WRITER_AT_CACHE.get((filename, lineno))
    if cached is not None:
        return cached
    tree = _pyir_module_ast(filename)
    if tree is None:
        return fallback
    best: "list[str] | None" = None
    stack: "list[tuple[_ast.AST, list[str]]]" = [(tree, [])]
    while stack:
        node, chain = stack.pop()
        for child in _ast.iter_child_nodes(node):
            child_chain = chain
            if isinstance(
                child, (_ast.FunctionDef, _ast.AsyncFunctionDef, _ast.ClassDef)
            ):
                end = getattr(child, "end_lineno", None) or child.lineno
                if child.lineno <= lineno <= end:
                    child_chain = [*chain, child.name]
                    if not isinstance(child, _ast.ClassDef) and (
                        best is None or len(child_chain) > len(best)
                    ):
                        best = child_chain
                else:
                    continue
            stack.append((child, child_chain))
    result = ".".join(best) if best else fallback
    if len(_WRITER_AT_CACHE) > 4096:
        _WRITER_AT_CACHE.clear()
    _WRITER_AT_CACHE[(filename, lineno)] = result
    return result


def _pyir_cal_refuse_host_state(name: str, kind: str, callee: Any = None) -> None:
    """Curated host-state refusal; *callee* names the native callee, or the
    plain code that is the witness itself."""
    filename, lineno = _first_non_dsl_caller_location()
    if callee is None:
        callee = _pyir_cal_writer_at(filename, lineno)
    elif not isinstance(callee, str):
        callee = (
            getattr(callee, "__qualname__", None)
            or getattr(callee, "__name__", None)
            or type(callee).__name__
        )
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.BOUNDARY_HOST_STATE_IN_STAGED_CF,
            filename=filename,
            lineno=lineno,
            name=name,
            kind=kind,
            callee=callee,
        )
    )


def _pyir_cal_active() -> bool:
    """A hook observes only on the tracing thread while a trace is open -- and
    never inside a value-tree protocol body the tracer itself runs
    (``__extract_mlir_values__``): that body is the object's own storage
    plumbing, native like the attribute-protocol dunders."""
    return (
        not _PYIR_VALUE_PROTOCOL_DEPTH[0]
        and _PYIR_TRACE_THREAD[0] == _threading.get_ident()
        and _pyir_boundary_trace_active()
    )


def _pyir_cal_dynamic_staged() -> bool:
    """Inside staged control flow whose body runs once for many executions."""
    return is_inside_staged_cf() and (
        not is_inside_constexpr_loop() or constexpr_scope_under_staged_cf()
    )


# Depth of attribute-protocol dunder bodies (``__getattribute__``, ``__getattr__``,
# ``__setattr__``, ``__delattr__``) running on the tracing thread.
_PROTOCOL_DUNDERS = frozenset(
    {"__getattribute__", "__getattr__", "__setattr__", "__delattr__"}
)
_PROTOCOL_READ_DUNDERS = frozenset({"__getattribute__"})
# id(receiver) -> nesting count, per protocol kind: "read" while the object's own
# ``__getattribute__`` / ``__getattr__`` body runs (its attribute reads on itself
# are storage plumbing), "write" while its ``__setattr__`` / ``__delattr__`` body
# runs (its attribute stores on itself likewise).
_PROTOCOL_ACTIVE: "dict[tuple[str, int], int]" = {}
# Nesting of protocol dunder bodies serving a DUNDER request: the tracer's own
# probes (``isinstance`` resolves ``__class__`` through a user ``__getattribute__``,
# ``vars`` reads ``__dict__``), never a place read of the program, so the body's raw
# storage reads are not choked there.
_PROBE_DEPTH: "list[int]" = [0]


class _PyirProtocolScope:
    __slots__ = ("_key", "_probe")

    def __init__(self, kind: str, receiver: Any, name: Any = None) -> None:
        self._key = (kind, id(receiver))
        self._probe = (
            isinstance(name, str) and name.startswith("__") and name.endswith("__")
        )

    def __enter__(self) -> None:
        _PROTOCOL_ACTIVE[self._key] = _PROTOCOL_ACTIVE.get(self._key, 0) + 1
        if self._probe:
            _PROBE_DEPTH[0] += 1

    def __exit__(self, *exc: Any) -> None:
        if self._probe:
            _PROBE_DEPTH[0] -= 1
        left = _PROTOCOL_ACTIVE.get(self._key, 0) - 1
        if left <= 0:
            _PROTOCOL_ACTIVE.pop(self._key, None)
        else:
            _PROTOCOL_ACTIVE[self._key] = left


def _pyir_cal_protocol(
    kind: str, receiver: Any, name: Any = None
) -> _PyirProtocolScope:
    return _PyirProtocolScope(kind, receiver, name)


# Attribute names the tracer itself asks a user object for (is it one of the
# DSL's own values? does it carry a route / a load version / a birth stamp?).
_TRACER_PROBE_NAMES = frozenset(
    {
        "ir_value",
        "_mutable_ref",
        "_slot_key",
        "_place",
        "_ref",
        "_cached_ir",
        "_struct_type",
        "__c_pointers__",
        "__dlpack__",
        "_tvm_ffi_tensor",
        "_preprocessed",
        "_original_code",
    }
)
_TRACER_PROBE_PREFIXES = ("_pyir", "__pyir", "_dsl_", "__dsl_")


def _pyir_cal_probe_name(name: Any) -> bool:
    """A user ``__getattr__`` answers the program's attribute misses, not the
    tracer's probes: a tracer-internal name misses before the hook body runs,
    so the body's effects stay exactly the program's."""
    if not isinstance(name, str):
        return False
    return (
        name in _TRACER_PROBE_NAMES
        or name.startswith(_TRACER_PROBE_PREFIXES)
        or "mlir" in name
    )


def _pyir_cal_in_protocol(kind: str, obj: Any) -> bool:
    return bool(_PROTOCOL_ACTIVE) and (kind, id(obj)) in _PROTOCOL_ACTIVE


def _pyir_cal_hooks_on() -> bool:
    """The access hooks observe on the tracing thread while a trace is open."""
    return _pyir_cal_active()


def _fatal(fn: Any) -> Any:
    """A diagnostic raised inside a hook is terminal for the open trace even
    when the author's ``except`` around the access catches it."""

    @_functools.wraps(fn)
    def wrapper(*args: Any, **kwargs: Any) -> Any:
        try:
            return fn(*args, **kwargs)
        except DSLUserCodeError as exc:
            raise _pyir_fatal_trace_error(exc)

    return wrapper


# -- Trace-internal (region-born) objects --------------------------------------


def _pyir_cal_same_region(recorded: tuple) -> bool:
    current = _pyir_current_region_arm_path()
    return len(recorded) == len(current) and all(
        a is b for a, b in zip(recorded, current)
    )


def _pyir_cal_mark_born(obj: Any) -> None:
    """*obj* was created by the callee in the current region execution."""
    if (
        obj is None
        or type(obj) in _SCALAR_TYPES
        or isinstance(obj, _CALLABLE_VALUE_TYPES)
    ):
        return
    if isinstance(obj, (_WatchedDict, _WatchedList, _WatchedM)):
        return
    if _pyir_cal_host_state_kind(obj) == _KIND_BUFFER:
        return  # a view / array may alias storage that outlives the region
    if len(_REGION_BORN) > 65536:
        _REGION_BORN.clear()
    _REGION_BORN[id(obj)] = (_pyir_cal_pin(obj), _pyir_current_region_arm_path())
    # The innermost open loop body is the object's birth block: a leaf of it seeded
    # or promoted later anchors its per-iteration seed store there; the objects it
    # holds are born with it.
    _pyir_boundary_note_birth(obj)
    _pyir_boundary_record_ctor_birth(obj, set())


def _pyir_cal_mark_born_def(fn: Any) -> None:
    """A ``def`` statement executed by a rewritten body births its function
    object in the current region execution (callables are otherwise never born)."""
    if not _pyir_cal_active() or not callable(fn):
        return
    if len(_REGION_BORN) > 65536:
        _REGION_BORN.clear()
    _REGION_BORN[id(fn)] = (_pyir_cal_pin(fn), _pyir_current_region_arm_path())


def _pyir_cal_is_born(obj: Any) -> bool:
    """Born in the callee and still inside the same region arm."""
    entry = _REGION_BORN.get(id(obj))
    if entry is None or entry[0]() is not obj:
        return False
    return _pyir_cal_same_region(entry[1])


def _pyir_cal_escaped(value: Any) -> None:
    """*value* was stored into a place: it is published state from here on."""
    if _REGION_BORN and value is not None and type(value) not in _SCALAR_TYPES:
        _REGION_BORN.pop(id(value), None)


# (id(owner), name): places read as None inside a dynamic staged region this
# trace (the None was consumed as a trace-time fact).
_NONE_READS: "set[tuple[int, str]]" = set()


def _pyir_cal_none_rebind_wall(
    obj: Any, name: str, value: Any, label: str, filename: str, lineno: int
) -> None:
    """A place whose None was read inside this region, rebound to a staged
    value: the reads decided on None for every runtime pass."""
    if not _pyir_cal_dynamic_staged() or value is None:
        return
    if (id(obj), name) not in _NONE_READS or _pyir_cal_stored_value(
        obj, name
    ) is not None:
        return
    kind = _pyir_cal_host_state_kind(value)
    if kind is not None and kind not in (_KIND_FUNCTION, _KIND_MODULE):
        # The None the region decided on is replaced by host state whose
        # later transitions would replay the first trace-time one.
        _pyir_cal_refuse_host_state(label, kind)
    if not _is_staged_value(value):
        return
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.PHASE_OPAQUE_READ_THEN_PROMOTED,
            filename=filename,
            lineno=lineno,
            var=label,
            reader="a use of its `None` value in this body",
        )
    )


# (wrapper, label, file, line): watched-meta values a plain callee's own ``if`` /
# ``while`` / conditional expression decided on inside dynamic staged CF (the fold
# is that trace pass's); judged at trace close like the stores.
_TRUTH_FOLDS: "list[tuple[Any, str, str, int]]" = []


@_fatal
def _pyir_cal_truth(test: Any, label: str, filename: str, lineno: int) -> Any:
    """The test of an ``if`` / ``while`` / conditional expression in a plain callee:
    Python decides it at trace time."""
    if not _pyir_cal_hooks_on():
        return test
    if test is not None and type(test) not in _SCALAR_TYPES:
        _pyir_cal_note_host_read(test)
        if isinstance(test, dict) and not isinstance(test, _WatchedDict):
            _pyir_cal_keyset_wall(test)
    if not _pyir_cal_dynamic_staged():
        return test
    if isinstance(test, _WatchedM) and _pyir_cal_src_places(test):
        if getattr(test, "_slot_key", None) is not None:
            try:
                test.ir_value()
            except DSLBaseError:
                raise
            except Exception:
                pass
        _TRUTH_FOLDS.append((_PyirTracePin(test), label, filename, lineno))
    return test


@_fatal
def _pyir_cal_assert(test: Any, label: str, filename: str, lineno: int) -> Any:
    """The test of an ``assert`` in a plain callee: a compile-time check that
    Python decides at trace time (the statement stays a real ``assert``, so a
    Python condition costs nothing and ``-O`` still strips it).  A Staged
    condition is refused here with the assert-specific diagnostic instead of
    failing in ``Numeric.__bool__``."""
    if type(test) in _SCALAR_TYPES:
        return test
    test = _pyir_cal_truth(test, label, filename, lineno)
    if isinstance(test, _WatchedM):
        return test
    from .typing import Numeric, is_staged_numeric
    from .utils.mlir_value_tree import is_dynamic_expression

    if isinstance(test, Numeric):
        staged = is_staged_numeric(test)
    else:
        staged = is_dynamic_expression(test)
    if staged:
        raise DSLUserCodeError(
            DiagId.ASSERT_DYNAMIC_CONDITION, filename=filename, lineno=lineno
        )
    return test


_BINOP_NAMES: "dict[type, tuple[str, str]]" = {
    _ast.Add: ("add", "__radd__"),
    _ast.Sub: ("sub", "__rsub__"),
    _ast.Mult: ("mul", "__rmul__"),
    _ast.Div: ("truediv", "__rtruediv__"),
    _ast.FloorDiv: ("floordiv", "__rfloordiv__"),
    _ast.Mod: ("mod", "__rmod__"),
    _ast.Pow: ("pow", "__rpow__"),
    _ast.LShift: ("lshift", "__rlshift__"),
    _ast.RShift: ("rshift", "__rrshift__"),
    _ast.BitAnd: ("and_", "__rand__"),
    _ast.BitOr: ("or_", "__ror__"),
    _ast.BitXor: ("xor", "__rxor__"),
    _ast.MatMult: ("matmul", "__rmatmul__"),
}
_COMPARE_NAMES: "dict[type, tuple[str, str]]" = {
    _ast.Lt: ("lt", "__gt__"),
    _ast.LtE: ("le", "__ge__"),
    _ast.Gt: ("gt", "__lt__"),
    _ast.GtE: ("ge", "__le__"),
    _ast.Eq: ("eq", "__eq__"),
    _ast.NotEq: ("ne", "__ne__"),
}
_PLAIN_SCALARS = (bool, int, float)


def _pyir_cal_binop(op: str, reflected: str, left: Any, right: Any) -> Any:
    """``left <op> right`` in a plain callee."""
    if (
        isinstance(right, _WatchedM)
        and not isinstance(left, _WatchedM)
        and type(left) in _PLAIN_SCALARS
    ):
        arm = getattr(right, reflected, None)
        if arm is not None:
            result = arm(left)
            if result is not NotImplemented:
                return result
    return getattr(_operator, op)(left, right)


def _pyir_cal_compare(op: str, reflected: str, left: Any, right: Any) -> Any:
    """``left <cmp> right`` in a plain callee, the watched-meta right operand
    rule of :func:`_pyir_cal_binop`."""
    if (
        isinstance(right, _WatchedM)
        and not isinstance(left, _WatchedM)
        and type(left) in _PLAIN_SCALARS
    ):
        arm = getattr(right, reflected, None)
        if arm is not None:
            result = arm(left)
            if result is not NotImplemented:
                return result
    return getattr(_operator, op)(left, right)


# Gate-once evidence for a plain callee's ``if`` (the traced body's
# ``_maybe_fold_constant_if`` counterpart): the membership choke fills the register
# only for a provable ``not in`` over a plain set; the ``if`` choke consumes it, one
# gate candidate per open arm.
_CAL_LAST_NOTIN_COMPARE: "list[Any]" = [None]
_CAL_GATE_STACK: "list[Any]" = []


def _pyir_cal_membership_is_staged(left: Any, right: Any) -> bool:
    """A membership test the traced body lowers as staged: a Staged lhs over a
    tuple/list/set/frozenset or a mapping (the latter refuses there), or a
    Staged member of such a collection.  A ``_WatchedM`` lhs is meta, so the
    gate-once ``k not in seen`` keeps its native test."""
    from .utils.mlir_value_tree import _is_staged_membership_operand

    if isinstance(right, (tuple, list, set, frozenset)):
        return _is_staged_membership_operand(left) or any(
            _is_staged_membership_operand(r) for r in right
        )
    if isinstance(
        right, (_abc.Mapping, _abc.KeysView, _abc.ItemsView, _abc.ValuesView)
    ):
        return _is_staged_membership_operand(left)
    return False


def _pyir_cal_membership(
    left: Any,
    right: Any,
    negate: bool,
    label: "str | None" = None,
    keys_of: bool = False,
) -> Any:
    """``left in right`` / ``left not in right`` in a plain callee: the native
    test, recorded as gate-once evidence when it is a ``not in`` over a plain
    set keyed by a trace-time scalar.  A plain dict, or a ``keys()`` view (live
    over its dict; *label* is the dict's spelling when the rewriter saw it),
    judges *left* by the dict key wall first.  ``k in d.keys()`` arrives with
    *keys_of* set and the dict itself as *right*: a tracked dict judges the
    test itself, as ``k in d`` (its ``__contains__`` observes the key set,
    which the raw view a key walk hands out outside staged CF would consume
    unseen); any other receiver has the view taken off it through the chokes
    the spelled call runs.  With a Staged operand over a tuple/list/set/
    frozenset the native test would answer by IR-handle identity
    (``Numeric.__hash__``), so it takes the traced body's lowering instead: a
    chain of staged ``==`` compares (``UNSUP_IN_OPERATOR`` over a mapping)."""
    if keys_of and isinstance(right, _WatchedDict):
        if _pyir_cal_hooks_on():
            _pyir_dict_key_wall(
                left, label or getattr(right, "_pyir_label", None) or "dict"
            )
    elif keys_of:
        right = _pyir_call_boundary_(
            _pyir_cal_getattr(right, "keys", f"{label}.keys"), births_seen=True
        )()
    if _pyir_cal_hooks_on() and right is not None and type(right) not in _SCALAR_TYPES:
        _pyir_cal_note_host_read(right)
        _pyir_cal_method_key_wall(right, "__contains__", (left,))
        if type(right) is _DICT_KEYS_TYPE:
            _pyir_dict_key_wall(left, label or _pyir_cal_label_of(right, "dict"))
        if isinstance(right, dict) and not isinstance(right, _WatchedDict):
            _pyir_cal_keyset_wall(right)
    if _pyir_cal_membership_is_staged(left, right):
        from .ast_helpers import compare_executor

        _CAL_LAST_NOTIN_COMPARE[0] = None
        return compare_executor(left, [right], ["not in" if negate else "in"])
    result = (left not in right) if negate else (left in right)
    if (
        negate
        and type(result) is bool
        and type(left) in (str, int, bool)
        and type(right) is set
    ):
        _CAL_LAST_NOTIN_COMPARE[0] = (right, left, result)
    else:
        _CAL_LAST_NOTIN_COMPARE[0] = None
    return result


# ``a and b`` / ``a or b`` / ``not a`` / ``a < b < c`` in a plain callee expand
# like the traced body's (evaluate-once, Python's short-circuit).  A staged
# operand -- an SSA-backed scalar, or a watched meta int/float whose place a
# later promotion may carry -- goes through the DSL's ``and_`` / ``or_`` /
# ``not_`` (one select / xor), reached through ``ast_helpers.executor``, so a
# straight-line helper computes the same value with or without the decorator.
# Python decides a Python-truth operand (a plain object, a plain or watched
# bool) exactly once; for a watched payload that truth test is the program's
# own consumption, witnessed through the payload dunder like the native
# operator's from the callee's frame, so a later promotion of the place
# refuses (PHASE_STRUCTURAL_CONSTANT_MUTATED) instead of keeping one trace's
# fold.


def _pyir_cal_staged_operand(value: Any) -> bool:
    """An operand whose truth is not Python's to decide at trace time: an
    SSA-backed ``Numeric`` (no Python payload), a raw ``ir.Value``, or a
    watched meta int/float.  Only a Python-truth bool -- plain or watched --
    short-circuits: the traced body's ``bool_short_circuits`` rule."""
    if isinstance(value, ir.Value):
        return True
    if isinstance(value, _WatchedM):
        return type(value._pyir_raw_payload) is not bool
    from .typing import is_staged_numeric

    return is_staged_numeric(value)


def _pyir_cal_dsl_operand(value: Any) -> bool:
    """An operand the DSL's ``and_`` / ``or_`` accept next to a staged operand."""
    if isinstance(value, (bool, int, float, ir.Value, _WatchedM)):
        return True
    from .typing import Numeric

    return isinstance(value, Numeric)


def _pyir_cal_bool_sc(value: Any, short_circuit_value: bool) -> bool:
    """The short-circuit test of a plain callee's ``and`` / ``or``: Python's
    truth of a Python-truth lhs, run once (a watched payload's fold is
    witnessed here); False for a staged operand, whose ``_pyir_cal_and_`` /
    ``_pyir_cal_or_`` arm stages the choice."""
    if _pyir_cal_hooks_on() and _pyir_cal_staged_operand(value):
        return False
    return bool(value) == short_circuit_value


def _pyir_cal_and_(left: Any, right: Any) -> Any:
    """``left and right`` once *left* did not short-circuit: a staged *left*
    selects through the DSL's ``and_``; a Python-truth *left*, already known
    truthy, yields *right* as Python does (its truth test ran exactly once)."""
    if _pyir_cal_hooks_on() and _pyir_cal_staged_operand(left):
        if _pyir_cal_dsl_operand(right):
            from .ast_helpers import executor

            return executor.logical_and(left, right)
        return left and right  # Python's own truth test (an SSA scalar refuses)
    return right


def _pyir_cal_or_(left: Any, right: Any) -> Any:
    """``left or right`` once *left* did not short-circuit (see ``_pyir_cal_and_``)."""
    if _pyir_cal_hooks_on() and _pyir_cal_staged_operand(left):
        if _pyir_cal_dsl_operand(right):
            from .ast_helpers import executor

            return executor.logical_or(left, right)
        return left or right  # Python's own truth test (an SSA scalar refuses)
    return right


def _pyir_cal_not_(value: Any) -> Any:
    """``not value`` in a plain callee: the DSL's ``not_`` for a staged operand,
    Python's ``not`` (a watched payload's fold witnessed here) for anything else."""
    if _pyir_cal_hooks_on() and _pyir_cal_staged_operand(value):
        from .ast_helpers import executor

        return executor.logical_not(value)
    return not value


# Their ``bool()`` / ``not`` / ``and`` / ``or`` run the program's truth test: a
# C-level truth test is frame-transparent, so the payload dunder sees the choke
# as its caller and must count it as the program's consumption.
_PYIR_NATIVE_INVOKE_CODES.add(_pyir_cal_bool_sc.__code__)
_PYIR_NATIVE_INVOKE_CODES.add(_pyir_cal_and_.__code__)
_PYIR_NATIVE_INVOKE_CODES.add(_pyir_cal_or_.__code__)
_PYIR_NATIVE_INVOKE_CODES.add(_pyir_cal_not_.__code__)


_BUILTIN_REDIRECT_NAMES = frozenset({"max", "min", "any", "all"})
_BUILTIN_REDIRECT_TARGETS = (_builtins.max, _builtins.min, _builtins.any, _builtins.all)


class _PyirCalReduction:
    """``max`` / ``min`` / ``any`` / ``all`` read in a plain callee.

    A Staged operand (or a generator, which the builtin would drain) takes the
    traced body's redirect so the DSL's reduction stages it.  Every other call
    is the native builtin reached through the call boundary exactly as before
    the redirect existed: the boundary's proxy unwraps a watched trace-time
    payload to its single compile-time value and refuses one that has none (a
    read of a place a later promotion carried), so the helper keeps that
    protection.
    """

    __slots__ = ("_native", "_redirected")

    def __init__(self, native: Any, redirected: Any) -> None:
        self._native = native
        self._redirected = redirected

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        from .utils.mlir_value_tree import is_dynamic_expression

        if any(
            isinstance(a, _types.GeneratorType) or is_dynamic_expression(a)
            for a in args
        ):
            return self._redirected(*args, **kwargs)
        return _pyir_call_boundary_(self._native, births_seen=True)(*args, **kwargs)

    # The builtin's own attributes (``__name__``, ``__doc__``, ...), equality
    # and hash, so a read that is passed along (``key=max``, ``fn == max``, a
    # dict keyed by the builtin) behaves like the builtin it stands for; only
    # ``is`` tells the two apart.
    def __getattr__(self, name: str) -> Any:
        return getattr(self._native, name)

    def __eq__(self, other: object) -> bool:
        if isinstance(other, _PyirCalReduction):
            other = other._native
        return other is self._native

    def __hash__(self) -> int:
        return hash(self._native)

    def __repr__(self) -> str:
        return repr(self._native)


def _pyir_cal_redirect_builtin(fcn: Any) -> Any:
    """A read of ``max`` / ``min`` / ``any`` / ``all``, or the callee of a
    literal ``bool(x)``, in a plain callee: the traced body's builtin redirect
    (``ast_helpers.redirect_builtin_function``), so staged arguments reach the
    DSL's reduction and ``bool(x)`` reports the decorated body's diagnostic; a
    user binding of the name passes through unchanged.  Imported lazily:
    ``ast_helpers`` sits above the chain (it imports ``pyir_runtime``)."""
    if not _pyir_cal_hooks_on():
        return fcn
    from .ast_helpers import redirect_builtin_function

    redirected = redirect_builtin_function(fcn)
    if redirected is fcn or fcn not in _BUILTIN_REDIRECT_TARGETS:
        return redirected
    return _PyirCalReduction(fcn, redirected)


def _pyir_cal_fold_if_enter(test: Any) -> Any:
    """Open a plain callee's ``if``: when *test* is the true ``not in`` the register
    describes, inside dynamic staged CF, the arm's first-defs collect on the fold
    stack so a latched gate can lift their keep-meta."""
    cand = _CAL_LAST_NOTIN_COMPARE[0]
    _CAL_LAST_NOTIN_COMPARE[0] = None
    if (
        cand is None
        or test is not True
        or cand[2] is not True
        or not _pyir_cal_hooks_on()
        or not _pyir_cal_dynamic_staged()
    ):
        cand = None
    _CAL_GATE_STACK.append(cand)
    if cand is not None:
        _PYIR_FOLD_FIRSTDEF_STACK.append([])
    return test


def _pyir_cal_fold_if_exit() -> None:
    """Close the arm: a latched gate (its key is now a member) proves a
    once-per-key init, so the arm's first-defs leave keep-meta (contract row
    U9) and a later meta change of the entry promotes into a carried cell."""
    cand = _CAL_GATE_STACK.pop() if _CAL_GATE_STACK else None
    if cand is None:
        return
    firstdefs = _PYIR_FOLD_FIRSTDEF_STACK.pop() if _PYIR_FOLD_FIRSTDEF_STACK else []
    gset, gkey, _ = cand
    if gkey not in gset:
        return
    for fd in firstdefs:
        if isinstance(fd, tuple) and len(fd) == 2 and fd[0] == CF_ATTR_FIRST_DEF:
            _PYIR_CF_ATTR_FIRST_DEFS.pop(fd[1], None)
            continue
        _slot_first_def_inside_cf[fd] = False
        _PYIR_GATE_ONCE_INIT_SLOTS.add(fd)


def _pyir_cal_check_truth_folds() -> None:
    if not _TRUTH_FOLDS or _PYIR_PENDING_USER_DIAGNOSTIC[0] is not None:
        return
    for pin, label, filename, lineno in list(_TRUTH_FOLDS):
        value = pin()
        if not _pyir_cal_source_promoted(value):
            continue
        raise _pyir_fatal_trace_error(
            DSLUserCodeError(
                DiagId.PHASE_PREDICATE_FOLDED_STALE,
                filename=filename,
                lineno=lineno,
                var=label,
                value=repr(getattr(value, "_pyir_raw_payload", value)),
                read_file=filename,
                read_line=lineno,
            )
        )


_KIND_DICT_VIEW = "a dict view (live over its dict's raw storage)"
_KIND_MAPPING_PROXY = "a read-only mapping proxy (live over its dict's raw storage)"
_VIEW_KINDS = (_KIND_DICT_VIEW, _KIND_MAPPING_PROXY)
_DICT_KEYS_TYPE: type = type({}.keys())
_DICT_VIEW_TYPES: "tuple[type, ...]" = (
    _DICT_KEYS_TYPE,
    type({}.values()),
    type({}.items()),
)
_VIEW_TYPES: "tuple[type, ...]" = (*_DICT_VIEW_TYPES, _types.MappingProxyType)


def _pyir_cal_refuse_dict_view(label: str, view: Any = None) -> None:
    kind = (
        "read-only mapping proxy (`types.MappingProxyType`)"
        if isinstance(view, _types.MappingProxyType)
        else f"`{type(view).__name__}` view"
        if view is not None
        else "dict view"
    )
    filename, lineno = _first_non_dsl_caller_location()
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.CONTAINER_DICT_VIEW_ALIAS_IN_STAGED_CF,
            filename=filename,
            lineno=lineno,
            var=label,
            kind=kind,
            target="its dict",
        )
    )


def _pyir_cal_view_wall(view: Any, label: str) -> None:
    """A dict view or mapping proxy read (an item, an attribute, an
    iteration, a native consumer) inside dynamic staged CF: it reads its
    dict's raw storage, never the entries' cells."""
    if (
        type(view) in _VIEW_TYPES
        and _pyir_cal_dynamic_staged()
        and not _pyir_cal_is_born(view)
    ):
        _pyir_cal_refuse_dict_view(_pyir_cal_label_of(view, label), view)


_KIND_CLASS_DEF = (
    "a class statement (its body and its descriptors' hooks run once, at trace time)"
)


@_fatal
def _pyir_cal_type(obj: Any) -> Any:
    """``type(x)`` in a plain callee: a tracked dict / list is carried through
    a subclass of its builtin type, so the exact type is not the program's."""
    if _pyir_cal_hooks_on() and isinstance(obj, (_WatchedDict, _WatchedList)):
        filename, lineno = _first_non_dsl_caller_location()
        raise _pyir_fatal_trace_error(
            DSLUserCodeError(
                DiagId.BOUNDARY_EXACT_CONTAINER_TYPE_PROBED,
                filename=filename,
                lineno=lineno,
                callee=_pyir_cal_writer_at(filename, lineno),
                name="the tested value",
                kind="dict" if isinstance(obj, _WatchedDict) else "list",
            )
        )
    return type(obj)


@_fatal
def _pyir_cal_class_def_wall(name: str) -> None:
    """A class statement inside dynamic staged CF runs its body (and the
    descriptors' ``__set_name__`` / ``__init_subclass__`` hooks) once."""
    if _pyir_cal_hooks_on() and _pyir_cal_dynamic_staged():
        _pyir_cal_refuse_host_state(name, _KIND_CLASS_DEF)


def _pyir_cal_born_cells(*cells: Any) -> None:
    """A def's own closure cells exist per activation: inside a region they
    are trace-internal until a closure over them escapes into a place."""
    if _pyir_cal_hooks_on() and is_inside_staged_cf():
        for cell in cells:
            if isinstance(cell, _types.CellType):
                _pyir_cal_mark_born(cell)


def _pyir_cal_init_receiver(obj: Any) -> None:
    """An ``__init__`` receiver with no storage yet is an object under
    construction: inside a region it is born there (its constructor's field
    binds are the object's initial state, published when the object escapes)."""
    if not _pyir_cal_hooks_on() or not is_inside_staged_cf() or obj is None:
        return
    if _pyir_cal_is_born(obj) or _pyir_lookup_owner_token(obj) is not None:
        return
    if _slot_store_for_tier1(obj):
        return
    storage = _safe_instance_dict(obj)
    if storage:
        return  # an existing object re-initialised: its fields are published state
    if storage is None and any(
        _pyir_cal_slot_bound(obj, d) for _n, d in _slots_member_descriptors(type(obj))
    ):
        return
    _pyir_cal_mark_born(obj)


def _pyir_cal_new_result(obj: Any) -> Any:
    """The result of an explicit ``X.__new__(cls, ...)`` call is an instance
    under construction, like an ``__init__`` receiver: the attributes a
    ``__new__`` stores beside a tuple subclass's leaves are its initial state,
    not a write to published state."""
    _pyir_cal_init_receiver(obj)
    return obj


def _pyir_cal_slot_bound(obj: Any, descriptor: Any) -> bool:
    try:
        descriptor.__get__(obj, type(obj))
    except AttributeError:
        return False
    return True


def _pyir_cal_born_closure(value: Any) -> bool:
    """A function created inside the open region, closing over cells born there."""
    if not isinstance(value, _types.FunctionType) or not _REGION_BORN:
        return False
    return any(_pyir_cal_is_born(cell) for cell in value.__closure__ or ())


def _pyir_cal_closure_escape_wall(value: Any, label: str) -> None:
    """A closure over this activation's cells stored into a place inside
    dynamic staged CF: the cells hold this trace pass's values."""
    if _pyir_cal_dynamic_staged() and _pyir_cal_born_closure(value):
        _pyir_cal_refuse_host_state(label, _KIND_BORN_CLOSURE)


def _pyir_cal_mark_born_parts(obj: Any, _depth: int = 0) -> None:
    """The plain containers and untracked user objects a born object holds
    (a copy's or factory's fresh parts) are born with it; a part the ledger
    already tracks (an element shared with published state) is not."""
    if _depth > 2:
        return
    parts: "list[Any]" = []
    if isinstance(obj, dict) and not isinstance(obj, _WatchedDict):
        parts = list(obj.values())
    elif isinstance(obj, (list, tuple)) and not isinstance(obj, _WatchedList):
        parts = list(obj)
    elif _pyir_boundary_is_user_holder(obj):
        parts = [
            v
            for k, v in (_instance_storage_items(obj) or {}).items()
            if k != _SLOT_STORE_ATTR
        ]
    for part in parts:
        if (
            part is None
            or type(part) in _SCALAR_TYPES
            or isinstance(part, _CALLABLE_VALUE_TYPES)
        ):
            continue
        if isinstance(
            part, (_WatchedDict, _WatchedList, _WatchedM)
        ) or _is_staged_value(part):
            continue
        if _pyir_lookup_owner_token(part) is not None or _pyir_cal_tracked_holder(part):
            continue
        if type(part) in _PLAIN_CONTAINER_KINDS or isinstance(part, tuple):
            _pyir_cal_mark_born(part)
            _pyir_cal_mark_born_parts(part, _depth + 1)
        elif (
            _pyir_boundary_is_user_holder(part)
            and _pyir_cal_host_state_kind(part) is None
        ):
            _pyir_cal_mark_born(part)
            _pyir_cal_mark_born_parts(part, _depth + 1)


def _pyir_cal_born(obj: Any) -> Any:
    """Hook on a literal / comprehension / generator expression in a callee."""
    if _pyir_cal_hooks_on():
        _pyir_cal_mark_born(obj)
    return obj


def _pyir_cal_refuse_pending_delete(holder: Any, attr: str) -> None:
    filename, lineno = _first_non_dsl_caller_location()
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.UNSUP_DEL_IN_STAGED_CF,
            filename=filename,
            lineno=lineno,
            obj=holder.__name__ if isinstance(holder, type) else type(holder).__name__,
            attr=attr,
        )
    )


def _pyir_cal_pending_deletes_check() -> None:
    """A deletion pending from a region arm that is no longer open was never
    re-bound in its region: refuse it now."""
    for key, (holder_pin, _old, path) in list(_PENDING_DELETES.items()):
        holder = holder_pin()
        if _pyir_cal_same_region(path):
            continue
        del _PENDING_DELETES[key]
        _pyir_cal_refuse_pending_delete(holder, key[1])


# -- Sighting and observation of values --------------------------------------


def _pyir_cal_refuse_replaced(label: str, what: str) -> None:
    filename, lineno = _first_non_dsl_caller_location()
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.BOUNDARY_REPLACED_OBJECT_ALIASED,
            filename=filename,
            lineno=lineno,
            name=label,
            callee=_pyir_cal_writer_at(filename, lineno),
            what=what,
        )
    )


def _pyir_cal_tracked_holder(obj: Any) -> bool:
    """Has the ledger rows or an owner token for *obj* (it is in the tracked state)?"""
    if _pyir_lookup_owner_token(obj) is not None:
        return True
    return bool(_slot_store_for_tier1(obj))


def _pyir_cal_hold(value: Any) -> Any:
    """*value* is bound (a local name, a store into a place, a cell): the object's
    first binding is its home; a further one is an alias, and the object is held
    from here on."""
    if _pyir_cal_hooks_on() and _pyir_boundary_is_user_holder(value):
        pin = _HOMED.get(id(value))
        if pin is not None and pin() is value:
            _HELD[id(value)] = pin
        else:
            _HOMED[id(value)] = _pyir_cal_pin(value)
    elif _pyir_cal_hooks_on() and isinstance(value, _types.MethodType):
        _pyir_cal_hold(value.__self__)
    return value


def _pyir_cal_bind(value: Any, name: str) -> Any:
    """``name = value`` in a plain callee: the binding holds the value (see
    :func:`_pyir_cal_hold`) and names it when no read labelled it yet."""
    _pyir_cal_hold(value)
    if (
        _pyir_cal_hooks_on()
        and value is not None
        and type(value) not in _SCALAR_TYPES
        and not isinstance(value, _CALLABLE_VALUE_TYPES)
    ):
        if not _pyir_cal_has_label(value):
            _pyir_cal_note_label(value, name)
    return value


def _pyir_cal_note_homed(value: Any) -> None:
    """*value* was read out of a place: it has a home there."""
    if _pyir_boundary_is_user_holder(value):
        pin = _HOMED.get(id(value))
        if pin is None or pin() is not value:
            _HOMED[id(value)] = _pyir_cal_pin(value)


def _pyir_cal_is_held(obj: Any) -> bool:
    pin = _HELD.get(id(obj))
    return pin is not None and pin() is obj


def _pyir_cal_replaced_object(
    pre: Any, cur: Any, label: str, cur_born: bool = False
) -> bool:
    """A field holding a tracked user object is rebound to another object inside
    dynamic staged CF."""
    if pre is cur or not _pyir_cal_dynamic_staged():
        return False
    if not _pyir_boundary_is_user_holder(pre) or not _pyir_cal_tracked_holder(pre):
        return False
    if (
        _pyir_boundary_is_user_holder(cur)
        and _pyir_cal_tracked_holder(cur)
        and not (cur_born or _pyir_cal_is_born(cur))
    ):
        _pyir_cal_refuse_replaced(
            label, "an object that already existed elsewhere in the tracked state"
        )
    if _pyir_cal_is_held(pre):
        _pyir_cal_refuse_replaced(
            label, "a new object while the previous one stays reachable"
        )
    return False


def _pyir_cal_mark_detached(pre: Any, label: str) -> None:
    return None


def _pyir_cal_detached_wall(obj: Any) -> None:
    if not _DETACHED:
        return
    entry = _DETACHED.get(id(obj))
    if entry is not None and entry[0]() is obj:
        _pyir_cal_refuse_replaced(
            entry[1], "a new object while the previous one stays reachable"
        )


def _pyir_cal_sight(value: Any) -> None:
    """A user-class instance seen at a choke: its class's callables (methods,
    properties, dunders) are swapped so implicit invocations observe too."""
    cls = type(value)
    if cls in _SCALAR_TYPES or cls in _INSTRUMENTED_CLASSES:
        return
    if not _pyir_boundary_module_is_user(getattr(cls, "__module__", None)):
        return
    _pyir_instrument_class(cls)


def _pyir_cal_route_callable(value: Any) -> Any:
    """The routed twin of a reflection / mutator builtin handed to native code
    as a callback (``map(setattr, ...)``), else *value* itself."""
    if value is _builtins.setattr:
        return _pyir_cal_reflect_setattr
    if value is _builtins.delattr:
        return _pyir_cal_reflect_delattr
    for table in (
        _PYIR_REFLECTION_ROUTES,
        _PYIR_HOF_ROUTES,
        _PYIR_CLEVEL_MUTATOR_ROUTES,
    ):
        route = table.get(id(value))
        if route is not None and route[0] is value:
            return route[1]
    route = _UNBOUND_MUTATOR_ROUTES.get(id(value))
    if route is not None and route[0] is value:
        return route[1]
    if value is type.__setattr__:
        return _pyir_cal_class_store
    if value is _builtins.setattr:
        return _pyir_cal_reflect_setattr
    if value is _builtins.delattr:
        return _pyir_cal_reflect_delattr
    return value


def _pyir_cal_observe_value(value: Any) -> Any:
    """Swap what *value* carries -- a user function's code, a user class, the
    class of a user instance, one level into builtin containers -- and return
    the value to pass on (a routed builtin replaces itself)."""
    if value is None or type(value) in _SCALAR_TYPES:
        return value
    _pyir_cal_detached_wall(value)
    if isinstance(value, _types.MethodType):
        if not isinstance(value.__self__, type):
            _pyir_cal_sight(value.__self__)
        _pyir_rewrite_function_in_place(value.__func__)
        return value
    if isinstance(value, _types.FunctionType):
        _pyir_rewrite_function_in_place(value)
        return value
    if isinstance(value, type):
        if _pyir_boundary_module_is_user(getattr(value, "__module__", None)):
            _pyir_instrument_class(value)
        return value
    if isinstance(
        value,
        (
            _types.BuiltinFunctionType,
            _types.MethodDescriptorType,
            _types.WrapperDescriptorType,
        ),
    ):
        return _pyir_cal_route_callable(value)
    if isinstance(value, (list, tuple, set, frozenset)):
        for item in value:
            _pyir_cal_observe_leaf(item)
        return value
    if isinstance(value, dict):
        for item in value.values():
            _pyir_cal_observe_leaf(item)
        return value
    _pyir_cal_sight(value)
    return value


def _pyir_cal_observe_leaf(value: Any) -> None:
    if value is None or type(value) in _SCALAR_TYPES:
        return
    if isinstance(value, (_types.FunctionType, _types.MethodType, type)):
        _pyir_cal_observe_value(value)
        return
    _pyir_cal_sight(value)


def _pyir_cal_scalar_subclass_wall(value: Any) -> None:
    """A user int/float subclass with its own operator methods read from a
    place: staged arithmetic dispatches on the DSL side, so the subclass's
    operator code (and any effect in it) would never run per iteration."""
    if (
        isinstance(value, (int, float))
        and type(value) not in _SCALAR_TYPES
        and not isinstance(value, _WatchedM)
        and _pyir_cal_dynamic_staged()
        and not _pyir_cal_is_born(value)
        and _pyir_boundary_module_is_user(getattr(type(value), "__module__", None))
        and _pyir_boundary_overrides_operators(type(value))
    ):
        _pyir_cal_refuse_host_state(type(value).__name__, _KIND_OPERATOR_SCALAR)


def _pyir_cal_read_pin(value: Any) -> Any:
    """A watched-meta wrapper read in a plain callee is a Python local until
    consumed; inside dynamic staged CF its cell may be stored to first, so the
    read position's load is materialised now (the traced body binds through
    the assign choke, which pins the same way)."""
    if isinstance(value, _WatchedM):
        if getattr(value, "_slot_key", None) is not None and _pyir_cal_dynamic_staged():
            value.ir_value()
        return value
    # A loaded staged value is the read's own snapshot: the source cell's route must
    # not follow it into another slot (a later store would reload the source at the
    # store position instead of storing the value read).
    if _is_staged_value(value) and getattr(value, "_mutable_ref", None) is not None:
        try:
            _pyir_delattr_raw(value, "_mutable_ref")
        except (AttributeError, TypeError):
            pass
    return value


def _pyir_cal_builtin_subclass_base(obj: Any) -> "type | None":
    """The builtin container base of a USER subclass instance (a namedtuple
    subclass, ``class Bag(dict)``), else None; adopted watched containers and
    the exact builtins are not subclasses in this sense."""
    cls = type(obj)
    if cls in _SCALAR_TYPES or cls in _BUILTIN_CONTAINER_BASES:
        return None
    if isinstance(obj, (_WatchedDict, _WatchedList, _WatchedM)):
        return None
    for base in _BUILTIN_CONTAINER_BASES:
        if isinstance(obj, base):
            return base
    return None


def _pyir_cal_refuse_builtin_subclass(
    obj: Any, base: type, name: str, what: str
) -> None:
    filename, lineno = _first_non_dsl_caller_location()
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.BOUNDARY_BUILTIN_SUBCLASS_ATTR_CHANGED,
            filename=filename,
            lineno=lineno,
            name=name,
            type=type(obj).__name__,
            base=base.__name__,
            what=what,
            callee=_pyir_cal_writer_at(filename, lineno),
        )
    )


def _pyir_cal_host_state_owner(obj: Any, name: str) -> bool:
    """Is ``obj.name`` host state (not a place)?  A function's or exception's
    protocol attributes are; their plain ``__dict__`` attributes are ordinary
    fields."""
    kind = _pyir_cal_host_state_kind(obj)
    if kind is None:
        return False
    if kind == _KIND_FUNCTION:
        return name.startswith("__")
    if kind == _KIND_EXCEPTION:
        return name in _EXCEPTION_SLOTS or name.startswith("__")
    return True


def _pyir_cal_owner_is_opaque(obj: Any) -> bool:
    """Owners whose attributes are not places: ``super`` proxies and classes
    outside user code (their attributes are trace-time machinery)."""
    if isinstance(obj, super):
        return True
    if isinstance(obj, type):
        return not _pyir_boundary_module_is_user(getattr(obj, "__module__", None))
    return False


def _pyir_cal_mro_member(cls: type, name: str) -> Any:
    for klass in cls.__mro__:
        member = vars(klass).get(name, _MEMBER_MISS)
        if member is not _MEMBER_MISS:
            return member
    return None


def _pyir_cal_cached_property(cls: type, name: str) -> Any:
    key = (cls, name)
    fact = _CACHED_PROPERTY_FACTS.get(key, _MEMBER_MISS)
    if fact is _MEMBER_MISS:
        member = _pyir_cal_mro_member(cls, name)
        fact = member if isinstance(member, _functools.cached_property) else None
        _CACHED_PROPERTY_FACTS[key] = fact
    return fact


def _pyir_cal_user_descriptor(cls: type, name: str) -> Any:
    """A descriptor object of a USER class found for *name* on *cls*'s MRO
    (its ``__get__`` / ``__set__`` bodies are observed code, and the name is
    not storage), else None."""
    key = (cls, name)
    fact = _DESCRIPTOR_FACTS.get(key, _MEMBER_MISS)
    if fact is _MEMBER_MISS:
        member = _pyir_cal_mro_member(cls, name)
        fact = None
        if (
            member is not None
            and not isinstance(member, _CALLABLE_VALUE_TYPES)
            and not isinstance(member, _DESCRIPTOR_TYPES)
            and not isinstance(
                member, (staticmethod, classmethod, _functools.cached_property)
            )
            and (hasattr(type(member), "__get__") or hasattr(type(member), "__set__"))
            and _pyir_boundary_module_is_user(getattr(type(member), "__module__", None))
        ):
            fact = member
        _DESCRIPTOR_FACTS[key] = fact
    return fact


def _pyir_cal_descriptor_owns_store(cls: type, name: str) -> bool:
    """A user DATA descriptor (``__set__`` / ``__delete__``) owns the store."""
    desc = _pyir_cal_user_descriptor(cls, name)
    return desc is not None and (
        hasattr(type(desc), "__set__") or hasattr(type(desc), "__delete__")
    )


def _pyir_cal_descriptor_owns_read(obj: Any, name: str) -> bool:
    """A user data descriptor always serves the read; a non-data one only
    while the instance storage does not bind the name (CPython precedence)."""
    desc = _pyir_cal_user_descriptor(type(obj), name)
    if desc is None:
        return False
    if hasattr(type(desc), "__set__") or hasattr(type(desc), "__delete__"):
        return True
    storage = _safe_instance_dict(obj)
    return not (storage is not None and name in storage)


def _pyir_cal_stored_value(obj: Any, name: str) -> Any:
    """The value the owner's own storage binds for *name* (an instance's dict
    or slot, a class's dict along its MRO), None when unbound; class attributes
    of an instance's class are not the instance's storage."""
    if isinstance(obj, type):
        for klass in obj.__mro__:
            if name in vars(klass):
                return vars(klass)[name]
        return None
    storage = _safe_instance_dict(obj)
    if storage is not None and name in storage:
        return storage[name]
    value = _pyir_boundary_current_value(obj, name)
    return None if value is _PYIR_BOUNDARY_MISSING else value


# -- Runtime hooks emitted by the rewrite -----------------------------------


@_fatal
def _pyir_cal_getattr(obj: Any, name: str, label: str) -> Any:
    """``obj.name`` in Load context: the read choke with the owner identity."""
    if not _pyir_cal_hooks_on():
        return getattr(obj, name)
    key = (id(obj), name)
    if key in _ACTIVE_ACCESS or _pyir_cal_in_protocol("read", obj):
        return getattr(obj, name)  # a user attribute hook re-entering its own access
    _ACTIVE_ACCESS.add(key)
    try:
        if _PENDING_DELETES:
            _pyir_cal_pending_deletes_check()
        _pyir_cal_detached_wall(obj)
        _pyir_cal_sight(obj)
        if "." in label and not _pyir_cal_has_label(obj):
            _pyir_cal_note_label(obj, label.rsplit(".", 1)[0])
        _pyir_cal_view_wall(obj, label.rsplit(".", 1)[0])
        if name == "__dict__" and not isinstance(obj, type):
            return _pyir_cal_dict_view(obj)
        if isinstance(obj, _types.ModuleType) or _pyir_cal_owner_is_opaque(obj):
            value = getattr(obj, name)
            if name == "__dict__" and isinstance(value, dict):
                _HOST_CONTAINERS[id(value)] = (value, f"{obj.__name__}.__dict__")
            elif isinstance(obj, _types.ModuleType):
                _pyir_cal_note_host_container(value, name)
            return value
        if (
            _pyir_cal_is_born(obj)
            or _pyir_cal_host_state_owner(obj, name)
            or _pyir_cal_builtin_subclass_base(obj) is not None
        ):
            # Trace-internal owner, host state, or a per-instance attribute of
            # a builtin-container subclass (not a place): native.
            value = getattr(obj, name)
            _pyir_cal_sight(value)
            _pyir_cal_note_label(value, label)
            return value
        cls = obj if isinstance(obj, type) else type(obj)
        if not isinstance(obj, type) and _pyir_cal_descriptor_owns_read(obj, name):
            return getattr(obj, name)  # the descriptor's own body is observed
        dynamic = _pyir_cal_dynamic_staged()
        if (
            dynamic
            and not isinstance(obj, type)
            and _pyir_cal_cached_property(cls, name) is not None
            and name not in (getattr(obj, "__dict__", None) or {})
        ):
            _pyir_cal_refuse_host_state(label, _KIND_CACHED_PROPERTY)
        try:
            value = getattr(obj, name)
        except Exception:
            if (
                dynamic
                and not isinstance(obj, type)
                and not _pyir_cal_has_stored(obj, name)
            ):
                _pyir_note_absent_probe(obj, name, "a raising attribute read")
            raise
        if isinstance(value, _CALLABLE_VALUE_TYPES):
            if isinstance(value, _types.ModuleType):
                _pyir_cal_note_label(value, label)
            elif isinstance(value, _types.FunctionType) and not isinstance(obj, type):
                storage = _safe_instance_dict(obj)
                if storage is not None and storage.get(name) is value:
                    # An instance-stored def's cells and defaults root only through this slot.
                    _pyir_spec_chain_value(value, obj, name)
            return value  # callables and symbol bases are not places
        if name.startswith("__") and name.endswith("__"):
            return value  # protocol attributes are not carried fields
        if value is None:
            if dynamic and not isinstance(obj, type):
                _NONE_READS.add((id(obj), name))
            return None
        if _pyir_cal_stale_value(value):
            _pyir_cal_refuse_stale(label)
        _pyir_cal_note_homed(value)
        _pyir_cal_note_label(value, label)
        if not isinstance(obj, type) and not _pyir_cal_has_stored(obj, name):
            # Served by the class's attribute protocol (``__getattribute__`` /
            # ``__getattr__``), bound in no storage: the read IS its value (the hook
            # body's own reads went through the chokes).
            _pyir_cal_sight(value)
            return value
        if (
            _pyir_cal_builtin_subclass_base(value) is not None
            and _safe_instance_dict(value) is not None
        ):
            # A builtin-container subclass instance with instance storage: the read
            # choke rebuilds containers element-wise, which would hand back a plain
            # container; the instance is Python truth.
            _pyir_cal_sight(value)
            return value
        _pyir_cal_sight(value)
        _pyir_cal_scalar_subclass_wall(value)
        return _pyir_cal_read_pin(
            pyir_read(label, value, attach_ref=False, owner=obj, slot_name=name)
        )
    finally:
        _ACTIVE_ACCESS.discard(key)


def _pyir_cal_container_internal(container: Any) -> bool:
    """A container whose element accesses stay native: born in the callee in
    the open region (every other container is reachable state, and the
    element chokes decide on it)."""
    return _pyir_cal_is_born(container)


def _pyir_cal_container_name(container: Any, label: str, default: str) -> str:
    """The author's name for *container* in a diagnostic: the subscript
    label's root, else the label its binding or adoption noted."""
    root = label.split("[", 1)[0]
    if root and root != "<receiver>":
        return root
    return getattr(container, "_pyir_label", None) or _pyir_cal_label_of(
        container, default
    )


def _pyir_cal_subscript_wall(
    container: Any, key: Any, label: str, slot: str = "__getitem__"
) -> None:
    """``container[key]`` in a plain callee, whatever the container's birth: the
    traced body's dict key / list index wall (:func:`_pyir_item_key_wall`)
    ahead of the native path a callee-born container's element accesses
    otherwise take; an adopted watched container walls in its own dunder."""
    default = "dict" if isinstance(container, dict) else "list"
    _pyir_item_key_wall(
        container, key, _pyir_cal_container_name(container, label, default), slot
    )


# Dict methods whose first argument is a KEY.
_DICT_KEYED_METHODS = frozenset(
    {
        "get",
        "pop",
        "setdefault",
        "__getitem__",
        "__setitem__",
        "__delitem__",
        "__contains__",
    }
)
# List methods whose first argument is an INDEX.
_LIST_INDEXED_METHODS = frozenset(
    {"pop", "insert", "__getitem__", "__setitem__", "__delitem__"}
)


def _pyir_cal_method_key_wall(
    container: Any, method: str, args: tuple, label: "str | None" = None
) -> tuple:
    """The keyed dict METHODS and indexed list METHODS spelled on a plain
    container in a plain callee take the subscript key / index wall too (an
    adopted watched container's own methods do); ``update`` judges the keys of
    its mapping or pair-sequence argument.  *label* is the container's
    spelling when the caller knows it.  Returns *args*; an iterator handed to
    ``update`` comes back materialised into the pair tuple the wall inspected
    (the native call consumes it once either way)."""
    if not args:
        return args
    if isinstance(container, list):
        if method in _LIST_INDEXED_METHODS and _pyir_builtin_item_slot(
            container, list, method
        ):
            _pyir_list_index_wall(
                args[0], label or _pyir_cal_label_of(container, "list")
            )
        return args
    if not _pyir_builtin_item_slot(container, dict, method):
        return args
    if method in _DICT_KEYED_METHODS:
        keys: Any = (args[0],)
    elif method == "update":
        other = args[0]
        if isinstance(other, dict):
            keys = tuple(dict.keys(other))  # raw: the native update reads it raw
        elif isinstance(other, _abc.Mapping) or hasattr(other, "keys"):
            keys = tuple(other.keys())
        elif isinstance(other, _abc.Iterable):
            if not isinstance(other, (list, tuple)):
                if _pyir_cal_host_state_kind(other) in (
                    _KIND_GENERATOR,
                    _KIND_ITERATOR,
                ) and not _pyir_cal_is_born(other):
                    # A persisted generator / iterator: draining it here would
                    # hide its advance from the host-state scan that refuses
                    # it inside dynamic staged CF; hand it on untouched.
                    return args
                other = tuple(other)
                args = (other, *args[1:])
            keys = tuple(
                pair[0] for pair in other if isinstance(pair, (list, tuple)) and pair
            )
        else:
            return args  # the native call's TypeError
    else:
        return args
    label = label or _pyir_cal_label_of(container, "dict")
    for key in keys:
        _pyir_dict_key_wall(key, label)
    return args


def _pyir_cal_compound_key_wall(key: Any, label: str) -> None:
    """A user object used as a dict key inside dynamic staged CF whose fields
    hold a watched-meta or staged value: its hash would name a place from a
    value that may be promoted."""
    if not _pyir_cal_dynamic_staged() or not _pyir_boundary_is_user_holder(key):
        return
    if type(key).__hash__ is object.__hash__ and type(key).__eq__ is object.__eq__:
        return  # identity-hashed: the key names the object, not its fields
    items = _instance_storage_items(key) or {}
    for v in items.values():
        if isinstance(v, _WatchedM) or _is_staged_value(v):
            filename, lineno = _first_non_dsl_caller_location()
            raise _pyir_fatal_trace_error(
                DSLUserCodeError(
                    DiagId.CONTAINER_DICT_KEY_STAGED_HASH,
                    filename=filename,
                    lineno=lineno,
                    var=label,
                    staged=(
                        "value read from a place inside this for/while/if (a "
                        "compile-time constant here that may become a Runtime value)"
                    ),
                )
            )


@_fatal
def _pyir_cal_getitem(label: str, container: Any, key: Any) -> Any:
    """``container[key]`` in Load context: the traced body's subscript read choke."""
    if not _pyir_cal_hooks_on():
        return container[key]
    _pyir_cal_subscript_wall(container, key, label)
    if isinstance(key, slice):
        return container[key]  # a new object built by the read; the caller births it
    _pyir_cal_sight(container)
    _pyir_cal_view_wall(container, label.split("[", 1)[0])
    root = _pyir_cal_host_container(container)
    if root is not None:
        _pyir_cal_note_host_read(container)
        if type(container) in _PLAIN_CONTAINER_KINDS:
            value = container[key]
            if (
                type(value) in _PLAIN_CONTAINER_KINDS
                or _pyir_cal_builtin_subclass_base(value) in _PLAIN_CONTAINER_KINDS
            ):
                # A container held by module state is module state itself:
                # its own walls apply, not the element chokes' adoption.
                _pyir_cal_note_host_container(value, root)
                _pyir_cal_sight(value)
                return value
    if isinstance(container, dict) and not _pyir_cal_container_internal(container):
        _pyir_cal_compound_key_wall(key, label)
    if _pyir_cal_container_internal(container):
        value = container[key]
        _pyir_cal_sight(value)
        return value
    if (
        isinstance(container, dict)
        and type(container) is not dict
        and not isinstance(container, _WatchedDict)
        and not dict.__contains__(container, key)
    ):
        if (
            isinstance(container, _collections.defaultdict)
            and _pyir_cal_dynamic_staged()
        ):
            # The native ``__missing__`` INSERTS the key: a key-set change.
            filename, lineno = _first_non_dsl_caller_location()
            raise _pyir_fatal_trace_error(
                DSLUserCodeError(
                    DiagId.CONTAINER_DICT_KEY_SET_MUTATED,
                    filename=filename,
                    lineno=lineno,
                    var=label,
                    detail=f"key {key!r} inserted by the default factory",
                )
            )
        return container[key]  # a user ``__missing__``: its body is observed
    if (
        isinstance(container, dict)
        and type(container) is not dict
        and not isinstance(container, _WatchedDict)
        and isinstance(
            _pyir_cal_mro_member(type(container), "__getitem__"), _types.FunctionType
        )
    ):
        # A user ``__getitem__``: its body is observed; the value it serves is
        # the entry's read.
        value = container[key]
        if value is not None and type(value) not in _SCALAR_TYPES:
            _pyir_cal_sight(value)
            _pyir_cal_note_homed(value)
        if isinstance(value, _CALLABLE_VALUE_TYPES):
            return value
        return _pyir_cal_read_pin(
            pyir_read(label, value, attach_ref=False, owner=container, slot_name=key)
        )
    value = _pyir_post_subscript_read(label, container, key)
    if value is not None and type(value) not in _SCALAR_TYPES:
        _pyir_cal_sight(value)
        _pyir_cal_note_homed(value)
        _pyir_cal_note_label(value, label)
        _pyir_cal_scalar_subclass_wall(value)
    return _pyir_cal_read_pin(value)


@_fatal
def _pyir_cal_global_read(value: Any, name: str) -> Any:
    """A module-global name read inside a plain callee: the binding itself is
    not a place, but a user object it holds is reached from one."""
    if _pyir_cal_hooks_on() and value is not None and type(value) not in _SCALAR_TYPES:
        if _pyir_cal_stale_value(value):
            _pyir_cal_refuse_stale(name)
        if not isinstance(value, _CALLABLE_VALUE_TYPES):
            _pyir_cal_sight(value)
            _pyir_cal_note_host_container(value, name)
            _pyir_cal_note_label(value, name)
    return value


def _pyir_cal_note_host_container(value: Any, name: str) -> None:
    """*value*, reached from module global *name*, is a plain builtin
    container: its storage is module state."""
    if (
        type(value) in _PLAIN_CONTAINER_KINDS
        or _pyir_cal_builtin_subclass_base(value) in _PLAIN_CONTAINER_KINDS
    ) and _HOST_CONTAINERS.get(id(value), (None,))[0] is not value:
        if len(_HOST_CONTAINERS) > 65536:
            _HOST_CONTAINERS.clear()
        _HOST_CONTAINERS[id(value)] = (value, name)


def _pyir_cal_host_container(container: Any) -> "str | None":
    """The module-global name *container* was reached from, or None."""
    entry = _HOST_CONTAINERS.get(id(container))
    return entry[1] if entry is not None and entry[0] is container else None


# id -> pinned container: module-global containers whose contents the trace
# consumed (an element read, iteration, a native consumer such as ``len``).
_HOST_READS: "dict[int, Any]" = {}
# id -> (pin, (filename, lineno, writer, root)): the first shape change of a
# module-global container inside a dynamic staged loop.
_HOST_SHAPE_WRITES: "dict[int, tuple[Any, tuple]]" = {}


def _pyir_cal_refuse_host_shape(site: tuple) -> None:
    filename, lineno, writer, root = site
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.UNSUP_GLOBAL_WRITE_IN_STAGED_CF,
            filename=filename,
            lineno=lineno,
            callee=writer,
            name=root,
        )
    )


def _pyir_cal_host_shape_wall(container: Any, root: str) -> None:
    """A shape change (length / key set / order) of a module-global container inside
    a dynamic staged LOOP runs once while the program is built, not once per
    iteration."""
    if not _pyir_cal_dynamic_staged() or _innermost_enclosing_loop_op_at_ip() is None:
        return
    filename, lineno = _first_non_dsl_caller_location()
    site = (filename, lineno, _pyir_cal_writer_at(filename, lineno), root)
    if _HOST_READS.get(id(container)) is container:
        _pyir_cal_refuse_host_shape(site)
    if id(container) not in _HOST_SHAPE_WRITES:
        _HOST_SHAPE_WRITES[id(container)] = (_PyirTracePin(container), site)


def _pyir_cal_note_host_read(container: Any) -> None:
    """The trace consumes *container*'s contents (a module-global container):
    a shape change inside a staged loop, recorded or later, refuses."""
    if _pyir_cal_host_container(container) is None:
        return
    entry = _HOST_SHAPE_WRITES.get(id(container))
    if entry is not None and entry[0]() is container:
        _pyir_cal_refuse_host_shape(entry[1])
    _HOST_READS[id(container)] = container


_WHOLE_CONSUMER_BUILTINS = frozenset(
    {
        "len",
        "iter",
        "sorted",
        "list",
        "tuple",
        "set",
        "frozenset",
        "dict",
        "bool",
        "any",
        "all",
        "min",
        "max",
        "sum",
        "enumerate",
        "zip",
        "reversed",
        "repr",
        "str",
        "map",
        "filter",
        "print",
        "format",
    }
)
_DICT_WHOLE_METHODS = frozenset(
    {
        "keys",
        "values",
        "items",
        "copy",
        "__len__",
        "__iter__",
        "__contains__",
        "__reversed__",
        "__eq__",
        "__ne__",
        "__or__",
        "__ror__",
    }
)


def _pyir_cal_note_consumption(
    callee: Any, method: str, receiver: Any, args: tuple, kwargs: dict
) -> None:
    """Reads a native callee performs on its inputs: every module-global
    container among them is consumed (see :func:`_pyir_cal_note_host_read`),
    and a plain dict handed to a whole-mapping consumer (``len``, iteration,
    ``.keys()``) has its key set observed (judged at trace close against keys
    created inside the region)."""
    if receiver is not None and not isinstance(receiver, _types.ModuleType):
        kind = _PLAIN_CONTAINER_KINDS.get(type(receiver)) or _PLAIN_CONTAINER_KINDS.get(
            _pyir_cal_builtin_subclass_base(receiver)  # type: ignore[arg-type]
        )
        mutators = _MUTATORS.get(kind) if kind is not None else None
        if kind is not None and not (mutators and method in mutators):
            _pyir_cal_note_host_read(receiver)
            if isinstance(receiver, dict) and method in _DICT_WHOLE_METHODS:
                _pyir_cal_keyset_wall(receiver)
    whole = getattr(callee, "__module__", None) == "builtins" and method in (
        _WHOLE_CONSUMER_BUILTINS
    )
    for a in (*args, *kwargs.values()):
        if a is None or type(a) in _SCALAR_TYPES:
            continue
        if _pyir_cal_host_container(a) is not None:
            _pyir_cal_note_host_read(a)
        if whole and isinstance(a, dict) and not isinstance(a, _WatchedDict):
            _pyir_cal_keyset_wall(a)


def _pyir_cal_host_element_native(container: Any, key: Any, value: Any) -> bool:
    """Whether ``container[key] = value`` on a module-global container is the traced
    body's native item write: a meta payload replacing a meta payload in a loop-
    free staged region."""
    if _is_staged_value(value) or isinstance(value, _WatchedM):
        return False
    try:
        old = container[key]
    except Exception:
        return True
    if _is_staged_value(old) or isinstance(old, _WatchedM):
        return False
    return _innermost_enclosing_loop_op_at_ip() is None


def _pyir_cal_has_key(container: Any, key: Any) -> bool:
    if isinstance(container, dict):
        return dict.__contains__(container, key)
    try:
        container[key]
    except (IndexError, KeyError, TypeError):
        return False
    return True


def _pyir_cal_sc_wall(label: str, filename: str, lineno: int) -> None:
    if _PYIR_SC_RHS_DEPTH[0] > 0 and is_inside_staged_cf():
        raise DSLUserCodeError(
            DiagId.BOUNDARY_SHORT_CIRCUIT_EFFECT,
            name=label,
            filename=filename,
            lineno=lineno,
            suggestion=(
                "Restructure the expression as an `if` statement so the update "
                f"of `{label}` is a conditional block, or make the guard a "
                "compile-time constant (`const_expr`)."
            ),
        )


def _pyir_cal_store_walls(obj: Any, name: str, value: Any, label: str) -> bool:
    """Walls ahead of an attribute store from a plain callee."""
    if _pyir_cal_owner_is_opaque(obj) or _pyir_cal_is_born(obj):
        return True
    dynamic = _pyir_cal_dynamic_staged()
    if isinstance(obj, BaseException):
        if dynamic and name in _EXCEPTION_SLOTS:
            filename, lineno = _first_non_dsl_caller_location()
            raise DSLUserCodeError(
                DiagId.UNSUP_EXCEPTION_SLOT_WRITE_IN_STAGED_CF,
                filename=filename,
                lineno=lineno,
                target=label,
                attr=name,
            )
        return name in _EXCEPTION_SLOTS
    kind = _pyir_cal_host_state_kind(obj)
    if kind is not None and _pyir_cal_host_state_owner(obj, name):
        if dynamic:
            owner_label = label.rsplit(".", 1)[0] if "." in label else label
            _pyir_cal_refuse_host_state(_pyir_cal_label_of(obj, owner_label), kind)
        return True  # host state is written natively, never a place
    base = _pyir_cal_builtin_subclass_base(obj)
    if base is not None:
        if dynamic:
            _pyir_cal_refuse_builtin_subclass(obj, base, label, "is written")
        return True  # a per-instance attribute of a builtin subclass is not a place
    if not dynamic:
        return False
    if isinstance(
        value,
        (_types.FunctionType, _types.MethodType, _types.BuiltinFunctionType, type),
    ):
        old = _pyir_cal_stored_value(obj, name)
        if old is not None and old is not value:
            _pyir_cal_refuse_host_state(label, _KIND_CALLABLE_ATTR)
    return False


def _pyir_cal_stale_value(value: Any, _depth: int = 0) -> bool:
    """A staged value minted under another MLIR context (a previous
    compilation), or a user holder whose fields carry one: the backing IR is
    gone, so it can be overwritten but never read here."""
    if _is_staged_value(value):
        return _pyir_is_stale_staged(value)
    if _depth < 2 and _pyir_boundary_is_user_holder(value):
        items = _instance_storage_items(value) or {}
        return any(
            k != _SLOT_STORE_ATTR and _pyir_cal_stale_value(v, _depth + 1)
            for k, v in items.items()
        )
    return False


# (wrapper, label, file, line): watched-meta values stored into places inside
# dynamic staged CF this trace.
_META_STORES: "list[tuple[Any, str, str, int, Any]]" = []


def _pyir_cal_meta_store_pin(
    value: Any, label: str, filename: str, lineno: int, bound: Any = None
) -> None:
    """*bound* answers whether the destination still holds *value* at trace
    close (a destination promoted by then carries the retargeted load and is
    consistent)."""
    if not isinstance(value, _WatchedM) or not _pyir_cal_src_places(value):
        return
    if not _pyir_cal_dynamic_staged():
        return
    if getattr(value, "_slot_key", None) is not None:
        try:
            value.ir_value()
        except DSLBaseError:
            raise
        except Exception:
            return
    _META_STORES.append((_PyirTracePin(value), label, filename, lineno, bound))


def _pyir_cal_source_promoted(value: Any) -> bool:
    """Was the place a watched-meta *value* was read from promoted to a cell
    after the read (the pinned constant is rewritten to a load, or the place
    now has a ref)?"""
    cached = getattr(value, "_cached_ir", None)
    if cached is not None and _META_CONST_REPLACEMENTS.get(cached) is not None:
        return True
    for place, _payload in _pyir_cal_src_places(value):
        if isinstance(_slot_refs.get(place), ir.Value):
            return True
    return False


def _pyir_cal_src_places(value: Any) -> "tuple[tuple[Any, Any], ...]":
    try:
        return tuple(value._pyir_src_pairs())
    except Exception:
        key = getattr(value, "_slot_key", None)
        return ((key, None),) if key is not None else ()


def _pyir_cal_meta_binding(cur: Any) -> bool:
    return isinstance(cur, _WatchedM) or type(cur) in (int, float, bool)


def _pyir_cal_check_meta_stores() -> None:
    if not _META_STORES or _PYIR_PENDING_USER_DIAGNOSTIC[0] is not None:
        return
    for pin, label, filename, lineno, bound in list(_META_STORES):
        value = pin()
        if not _pyir_cal_source_promoted(value):
            continue
        if bound is not None:
            try:
                if not _pyir_cal_meta_binding(bound()):
                    continue  # the destination was promoted: it carries the load
            except Exception:
                continue
        raise _pyir_fatal_trace_error(
            DSLUserCodeError(
                DiagId.PHASE_OPAQUE_READ_THEN_PROMOTED,
                filename=filename,
                lineno=lineno,
                var=label,
                reader="a plain callee that stored the value before the update",
            )
        )


def _pyir_cal_refuse_stale(label: str) -> None:
    filename, lineno = _first_non_dsl_caller_location()
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.STATE_FROM_PREVIOUS_COMPILATION,
            filename=filename,
            lineno=lineno,
            name=label,
        )
    )


def _pyir_cal_has_stored(obj: Any, name: str) -> bool:
    """Does the owner's storage (or its class, for a default) bind *name*?
    Answered without ``hasattr``: a probe would run a user ``__getattr__``
    for a name that is about to be bound for the first time."""
    if isinstance(obj, type):
        return any(name in vars(k) for k in obj.__mro__)
    storage = _safe_instance_dict(obj)
    if storage is not None and name in storage:
        return True
    if _pyir_boundary_current_value(obj, name) is not _PYIR_BOUNDARY_MISSING:
        return True
    member = _pyir_cal_mro_member(type(obj), name)
    if member is None:
        return False
    if isinstance(member, _types.MemberDescriptorType):
        try:
            member.__get__(obj, type(obj))  # an empty slot binds nothing
        except AttributeError:
            return False
    return True


def _pyir_cal_note_born_binding(obj: Any, name: str) -> None:
    if not _pyir_cal_dynamic_staged():
        return
    _pyir_cal_note_keyset_change(obj, name)
    _BORN_BINDINGS[(id(obj), name)] = (
        _pyir_cal_pin(obj),
        _pyir_current_region_arm_path(),
    )


def _pyir_cal_unbind_born(obj: Any, name: str) -> bool:
    """True when *name* was first bound on *obj* in the open region arm: the
    deletion unbinds the arm's own binding, leaving no published state."""
    entry = _BORN_BINDINGS.pop((id(obj), name), None)
    if entry is None or entry[0]() is not obj or not _pyir_cal_same_region(entry[1]):
        return False
    _pyir_cal_note_keyset_change(obj, name, unbind=True)
    _pyir_retire_place_row(None, obj, name)
    _pyir_spec_record_unbind(obj, name)
    return True


def _pyir_cal_finish_pending_delete(obj: Any, name: str) -> None:
    """A store to an attribute deleted earlier in the same region: the
    deletion and the rebind are one write, so the pre-delete binding is
    restored first and the store proceeds as an update."""
    entry = _PENDING_DELETES.pop((id(obj), name), None)
    if entry is None:
        return
    holder, old = entry[0](), entry[1]()
    if holder is obj and old is not _PYIR_BOUNDARY_MISSING:
        try:
            _pyir_setattr_raw(obj, name, old)
        except (AttributeError, TypeError):
            pass
        _pyir_cal_note_keyset_change(obj, name)  # re-inserted: its position moved


@_fatal
def _pyir_cal_setattr(
    obj: Any,
    name: str,
    value: Any,
    label: str,
    filename: str,
    lineno: int,
    rmw: bool = False,
) -> None:
    """``obj.name = value``: the traced-body attribute-store lifecycle (property
    / ``__setattr__`` / descriptor route, pre-store refresh, native store,
    post-store bookkeeping, first-def note), evaluated at the callee's own
    position."""
    if not _pyir_cal_hooks_on():
        setattr(obj, name, value)
        return
    key = (id(obj), "=" + name)
    if key in _ACTIVE_ACCESS or _pyir_cal_in_protocol("write", obj):
        setattr(obj, name, value)  # a user ``__setattr__`` re-entering its own store
        return
    _ACTIVE_ACCESS.add(key)
    try:
        if _PENDING_DELETES:
            _pyir_cal_pending_deletes_check()
            _pyir_cal_finish_pending_delete(obj, name)
        _pyir_cal_detached_wall(obj)
        _pyir_cal_sight(obj)
        if _pyir_cal_store_walls(obj, name, value, label):
            setattr(obj, name, value)
            return
        _pyir_cal_closure_escape_wall(value, label)
        born = _pyir_cal_is_born(value)
        _pyir_cal_escaped(value)
        _pyir_cal_sc_wall(label, filename, lineno)
        _pyir_cal_hold(value)
        _pyir_cal_meta_store_pin(
            value, label, filename, lineno, _PyirAttrProbe(obj, name)
        )
        _pyir_cal_none_rebind_wall(obj, name, value, label, filename, lineno)
        if _pyir_is_property_store(obj, name):
            _pyir_property_store(obj, name, value)
            return
        if _pyir_cal_descriptor_owns_store(type(obj), name):
            setattr(obj, name, value)  # the descriptor's ``__set__`` body is observed
            return
        if _pyir_cal_has_stored(obj, name) and not _pyir_cal_stale_value(
            getattr(obj, name)
        ):
            # A rewrite on the enclosing path of an in-region first-def widens
            # the record before the pre-store refresh reads the place (the
            # refresh takes the read check like any read); the assign choke's
            # own update then finds the path recorded.
            if _PYIR_CF_ATTR_FIRST_DEFS:
                _pyir_update_cf_attr_first_def_on_write(obj, name)
            fresh = _pyir_pre_attr_assign(
                label, getattr(obj, name), owner=obj, slot_name=name
            )
            if fresh is not _PYIR_SKIP:
                setattr(obj, name, fresh)
            old = getattr(obj, name)
            detach = _pyir_cal_replaced_object(old, value, label, born)
            setattr(obj, name, value)
            result = _pyir_post_attr_assign(
                label,
                old,
                getattr(obj, name),
                filename,
                lineno,
                owner=obj,
                slot_name=name,
                rmw_self=rmw,
                rmw_path=label if rmw else None,
            )
            if result is not _PYIR_SKIP:
                setattr(obj, name, result)
            if detach:
                _pyir_cal_mark_detached(old, label)
            return
        setattr(obj, name, value)
        pyir_note_attr_first_def(label, obj, name, getattr(obj, name))
        _pyir_cal_note_born_binding(obj, name)
    finally:
        _ACTIVE_ACCESS.discard(key)


@_fatal
def _pyir_cal_iattr(
    obj: Any,
    name: str,
    op: str,
    old: Any,
    rhs: Any,
    label: str,
    filename: str,
    lineno: int,
) -> None:
    """``obj.name op= rhs``: *old* is the target's value read before the RHS
    (Python's order); the in-place protocol runs through the routed dunder
    with the read-modify-write witness the loop audits key on."""
    if not _pyir_cal_hooks_on():
        setattr(obj, name, _pyir_inplace_binop(op, old, rhs, label))
        return
    key = (id(obj), "=" + name)
    if key in _ACTIVE_ACCESS or _pyir_cal_in_protocol("write", obj):
        setattr(obj, name, _pyir_inplace_binop(op, old, rhs, label))
        return
    _ACTIVE_ACCESS.add(key)
    try:
        _pyir_cal_detached_wall(obj)
        _pyir_cal_sight(obj)
        _pyir_cal_inplace_container_wall(old, op, label)
        if op == "or" and isinstance(old, dict):
            _pyir_cal_dict_update(old, label, filename, lineno, rhs)
            return  # ``d |= other`` is ``d.update(other)``: the same object stays bound
        if _pyir_cal_store_walls(obj, name, None, label):
            setattr(obj, name, _pyir_inplace_binop(op, old, rhs, label))
            return
        _pyir_cal_sc_wall(label, filename, lineno)
        if _pyir_is_property_store(obj, name):
            _pyir_property_store(obj, name, _pyir_inplace_binop(op, old, rhs, label))
            return
        if _pyir_cal_descriptor_owns_store(type(obj), name):
            setattr(obj, name, _pyir_inplace_binop(op, old, rhs, label))
            return
        fresh = _pyir_pre_attr_assign(
            label, getattr(obj, name), owner=obj, slot_name=name
        )
        if fresh is not _PYIR_SKIP:
            setattr(obj, name, fresh)
        stored_old = getattr(obj, name)
        setattr(obj, name, _pyir_inplace_binop(op, old, rhs, label))
        result = _pyir_post_attr_assign(
            label,
            stored_old,
            getattr(obj, name),
            filename,
            lineno,
            owner=obj,
            slot_name=name,
            rmw_self=True,
            rmw_path=label,
        )
        if result is not _PYIR_SKIP:
            setattr(obj, name, result)
    finally:
        _ACTIVE_ACCESS.discard(key)


@_fatal
def _pyir_cal_delattr(obj: Any, name: str, label: str) -> None:
    """``del obj.name``: Python truth first (``__delattr__``, descriptors, the
    AttributeError of an unbound name); in meta flow the ledger row dies with
    the binding; inside dynamic staged CF the deletion of a published
    attribute stays pending until the same region re-binds it (one write),
    and refuses if the region closes first."""
    if not _pyir_cal_hooks_on() or _pyir_cal_in_protocol("write", obj):
        delattr(obj, name)
        return
    _pyir_cal_detached_wall(obj)
    _pyir_cal_sight(obj)
    if _pyir_cal_owner_is_opaque(obj) or _pyir_cal_is_born(obj):
        delattr(obj, name)
        return
    if not _pyir_cal_dynamic_staged():
        _pyir_delete_attr(obj, name)
        return
    old = _pyir_cal_stored_value(obj, name)
    delattr(obj, name)
    if _pyir_cal_host_state_owner(obj, name) or _pyir_cal_descriptor_owns_store(
        type(obj), name
    ):
        return
    _pyir_cal_note_keyset_change(obj, name)
    if _pyir_cal_unbind_born(obj, name):
        return
    _PENDING_DELETES[(id(obj), name)] = (
        _PyirTracePin(obj),
        _PyirTracePin(_PYIR_BOUNDARY_MISSING if old is None else old),
        _pyir_current_region_arm_path(),
    )


def _pyir_cal_raw_read_choke(obj: Any, name: Any, value: Any, label: str) -> Any:
    """The read choke for a value obtained by a raw attribute lookup (a user
    attribute hook reaching past itself): a stored name loads its slot's cell."""
    if not isinstance(name, str) or (name.startswith("__") and name.endswith("__")):
        return value
    if (
        isinstance(value, _CALLABLE_VALUE_TYPES)
        or _PROBE_DEPTH[0]
        or not _pyir_cal_hooks_on()
    ):
        return value
    key = (id(obj), name)
    if key in _ACTIVE_ACCESS or (id(obj), "=" + name) in _ACTIVE_ACCESS:
        # The choke's own probes, or a store's storage reads around its
        # native write, re-entering the user's hook: the raw value.
        return value
    _ACTIVE_ACCESS.add(key)
    try:
        _pyir_cal_detached_wall(obj)
        if (
            _pyir_cal_owner_is_opaque(obj)
            or _pyir_cal_is_born(obj)
            or _pyir_cal_host_state_owner(obj, name)
            or _pyir_cal_builtin_subclass_base(obj) is not None
            or not _pyir_cal_has_stored(obj, name)
        ):
            return value
        if _pyir_cal_stale_value(value):
            _pyir_cal_refuse_stale(label)
        _pyir_cal_sight(value)
        return _pyir_cal_read_pin(
            pyir_read(label, value, attach_ref=False, owner=obj, slot_name=name)
        )
    finally:
        _ACTIVE_ACCESS.discard(key)


@_fatal
def _pyir_cal_object_getattr(obj: Any, name: Any, label: str) -> Any:
    """``object.__getattribute__(obj, name)`` in a plain callee."""
    return _pyir_cal_raw_read_choke(
        obj, name, object.__getattribute__(obj, name), label
    )


@_fatal
def _pyir_cal_super_getattr(sup: Any, name: Any, label: str) -> Any:
    """``super().__getattribute__(name)`` in a plain callee."""
    value = super.__getattribute__(sup, name)
    owner = object.__getattribute__(sup, "__self__")
    return _pyir_cal_raw_read_choke(owner, name, value, label)


@_fatal
def _pyir_cal_object_delattr(obj: Any, name: Any) -> None:
    """``object.__delattr__(obj, name)`` in a plain callee: the raw storage
    delete (a user ``__delattr__`` override is bypassed, as in CPython), with
    the deletion protocol of ``del obj.name``."""
    if (
        not _pyir_cal_hooks_on()
        or not isinstance(name, str)
        or _pyir_cal_owner_is_opaque(obj)
        or _pyir_cal_is_born(obj)
    ):
        _pyir_delattr_raw(obj, name)
        return
    _pyir_cal_sight(obj)
    if not _pyir_cal_dynamic_staged():
        _pyir_delattr_raw(obj, name)
        _pyir_retire_place_row(None, obj, name)
        _pyir_spec_record_unbind(obj, name)
        return
    old = _pyir_cal_stored_value(obj, name)
    _pyir_delattr_raw(obj, name)
    if _pyir_cal_host_state_owner(obj, name) or _pyir_cal_descriptor_owns_store(
        type(obj), name
    ):
        return
    _pyir_cal_note_keyset_change(obj, name)
    if _pyir_cal_unbind_born(obj, name):
        return
    _PENDING_DELETES[(id(obj), name)] = (
        _PyirTracePin(obj),
        _PyirTracePin(_PYIR_BOUNDARY_MISSING if old is None else old),
        _pyir_current_region_arm_path(),
    )


def _pyir_cal_dict_update(
    container: Any, label: str, filename: str, lineno: int, *args: Any, **kwargs: Any
) -> None:
    """``d.update(...)`` / ``d |= other`` on a dict reachable from state:
    every entry write is an element store through the subscript choke (a
    new key is a key-set change the choke judges)."""
    if len(args) > 1:
        raise TypeError(f"update expected at most 1 argument, got {len(args)}")
    items: "list[tuple[Any, Any]]" = []
    if args:
        other = args[0]
        if isinstance(other, _abc.Mapping) or hasattr(other, "keys"):
            items.extend((k, other[k]) for k in other.keys())
        else:
            items.extend((k, v) for k, v in other)
    items.extend(kwargs.items())
    new_keys = [k for k, _ in items if not _pyir_cal_has_key(container, k)]
    if (
        new_keys
        and _pyir_cal_dynamic_staged()
        and not _pyir_cal_container_internal(container)
    ):
        root = _pyir_cal_host_container(container)
        if root is not None:
            _pyir_cal_host_shape_wall(container, root)
        else:
            # The traced body's own ``update()`` rule: a key created by a whole-
            # mapping mutator inside dynamic staged CF (the per-key subscript
            # spelling is the first-def form the chokes carry).
            raise _pyir_fatal_trace_error(
                DSLUserCodeError(
                    DiagId.CONTAINER_DICT_KEY_SET_MUTATED,
                    filename=filename,
                    lineno=lineno,
                    var=label,
                    detail=f"update() inserting {new_keys!r}",
                )
            )
    for k, v in items:
        _pyir_cal_setitem(container, k, v, f"{label}[{k!r}]", filename, lineno)


class _PyirItemStore:
    """Bound ``__setitem__`` of a builtin container (or a user subclass
    instance) spelled explicitly: the element store on the raw storage."""

    __slots__ = ("_pyir_container",)

    def __init__(self, container: Any) -> None:
        self._pyir_container = container

    def __call__(self, key: Any, value: Any) -> None:
        filename, lineno = _first_non_dsl_caller_location()
        _pyir_cal_setitem(
            self._pyir_container,
            key,
            value,
            "<receiver>",
            filename or "",
            lineno or 0,
            raw=True,
        )


class _PyirItemDelete:
    """Bound ``__delitem__`` of a builtin container spelled explicitly."""

    __slots__ = ("_pyir_container",)

    def __init__(self, container: Any) -> None:
        self._pyir_container = container

    def __call__(self, key: Any) -> None:
        _pyir_cal_delitem(self._pyir_container, key, "<receiver>", raw=True)


def _pyir_cal_user_item_dunder(container: Any, name: str) -> bool:
    """Does ``type(container)`` define *name* (``__setitem__`` /
    ``__delitem__``) in user code ahead of the builtin base?  Such a dunder
    is observed itself; the storage write it performs routes here raw."""
    for klass in type(container).__mro__:
        member = vars(klass).get(name)
        if member is None:
            continue
        return isinstance(
            member, _types.FunctionType
        ) and _pyir_boundary_module_is_user(getattr(klass, "__module__", None))
    return False


def _pyir_cal_item_store_raw(container: Any, key: Any, value: Any) -> None:
    """``container[key] = value`` on the builtin storage, bypassing a user
    ``__setitem__`` (whose body is the observed code that led here)."""
    base = _pyir_cal_builtin_subclass_base(container)
    if base is dict:
        dict.__setitem__(container, key, value)
    elif base is list:
        list.__setitem__(container, key, value)
    else:
        container[key] = value


class _PyirDictUpdate:
    """Bound ``update`` of a dict reachable from state, routed element-wise."""

    __slots__ = ("_pyir_container",)

    def __init__(self, container: Any) -> None:
        self._pyir_container = container

    def __call__(self, *args: Any, **kwargs: Any) -> None:
        filename, lineno = _first_non_dsl_caller_location()
        _pyir_cal_dict_update(
            self._pyir_container,
            _pyir_cal_label_of(self._pyir_container),
            filename or "",
            lineno or 0,
            *args,
            **kwargs,
        )


def _pyir_cal_inplace_container_wall(old: Any, op: str, label: str) -> None:
    """``old op= rhs`` where *old* is a builtin container (or a subclass
    instance) mutates it in place: the plain-container wall applies."""
    dunder = _INPLACE_CONTAINER_DUNDERS.get(op)
    if dunder is None or old is None or isinstance(old, (_WatchedDict, _WatchedList)):
        return
    if dunder == "__ior__" and isinstance(old, dict):
        return  # served element-wise by the update route
    if type(old) in _PLAIN_CONTAINER_KINDS or _pyir_cal_builtin_subclass_base(old) in (
        list,
        dict,
        set,
    ):
        _pyir_cal_plain_container_wall(old, dunder, label)


def _pyir_cal_buffer_wall(container: Any, label: str) -> None:
    if (
        _pyir_cal_host_state_kind(container) == _KIND_BUFFER
        and _pyir_cal_dynamic_staged()
    ):
        _pyir_cal_refuse_host_state(label, _KIND_BUFFER)


def _pyir_cal_plain_container_wall(
    container: Any,
    method: str,
    label: str,
    values: Any = None,
    births_seen: bool = True,
) -> None:
    """A mutator on a PLAIN list/dict/set the ledger tracks, inside dynamic staged
    CF: the traced body's meta-container wall (an adopted container has its own
    hooks; a container born in the callee is trace-internal).  A receiver the
    traced body spells (*births_seen* False) has no birth record to judge: its
    verdict is the body's own mutator guard."""
    kind = _PLAIN_CONTAINER_KINDS.get(type(container))
    if kind is None:
        base = _pyir_cal_builtin_subclass_base(container)
        kind = _PLAIN_CONTAINER_KINDS.get(base) if base is not None else None
    if kind is None or not _pyir_cal_dynamic_staged():
        return
    if _pyir_cal_container_internal(container):
        return
    if method not in _MUTATORS[kind]:  # type: ignore[operator]
        return
    root = _pyir_cal_host_container(container)
    if root is not None:
        _pyir_cal_host_shape_wall(container, root)
        return  # loop-free: the module state's own native mutator
    if not births_seen:
        return
    if (
        kind == _KIND_PLAIN_SET
        and method == "add"
        and values is not None
        and not any(_is_staged_value(v) or isinstance(v, _WatchedM) for v in values)
    ):
        return
    filename, lineno = _first_non_dsl_caller_location()
    if kind == _KIND_PLAIN_SET:
        raise _pyir_fatal_trace_error(
            DSLUserCodeError(
                DiagId.CONTAINER_SET_REBUILT_IN_CF,
                filename=filename,
                lineno=lineno,
                var=label,
                old_value=set(container),
                new_value=f"<after .{method}()>",
            )
        )
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.UNSUP_META_CONTAINER_MUTATION,
            filename=filename,
            lineno=lineno,
            container=label,
            method=method,
            kind=kind,
        )
    )


@_fatal
def _pyir_cal_setitem(
    container: Any,
    key: Any,
    value: Any,
    label: str,
    filename: str,
    lineno: int,
    raw: bool = False,
) -> None:
    """``container[key] = value``: the traced-body subscript-store lifecycle."""
    if not _pyir_cal_hooks_on():
        container[key] = value
        return
    _pyir_cal_subscript_wall(container, key, label, "__setitem__")
    _pyir_cal_sight(container)
    if _pyir_cal_container_internal(container):
        container[key] = value
        return
    if not raw and _pyir_cal_user_item_dunder(container, "__setitem__"):
        container[key] = value  # the user dunder is observed; it stores raw
        return
    store = _pyir_cal_item_store_raw if raw else _pyir_cal_native_item_store
    root = _pyir_cal_host_container(container)
    if root is not None and not (
        _is_staged_value(value) or isinstance(value, _WatchedM)
    ):
        if not _pyir_cal_has_key(container, key):
            _pyir_cal_host_shape_wall(container, root)
            store(container, key, _unwrap(value))
            return
        if _pyir_cal_host_element_native(container, key, value):
            store(container, key, _unwrap(value))
            return
    _pyir_cal_closure_escape_wall(value, label)
    _pyir_cal_hold(value)
    _pyir_cal_escaped(value)
    _pyir_cal_buffer_wall(container, label)
    if isinstance(container, dict):
        _pyir_cal_compound_key_wall(key, label)
        if not _pyir_cal_has_key(container, key) and _pyir_cal_dynamic_staged():
            # A key created here: a later whole-key-set read refuses at
            # trace close (the traced body's baked-key-set witness).
            _pyir_cal_note_keyset_change(container, key)
    _pyir_cal_sc_wall(label, filename, lineno)

    _pyir_cal_meta_store_pin(
        value, label, filename, lineno, _PyirItemProbe(container, key)
    )
    old = _pyir_pre_subscript_assign(label, container, key)
    if old is not _PYIR_SKIP:
        store(container, key, old)
    if raw:
        store(container, key, value)
    else:
        _pyir_subscript_store(container, key, value)
    if old is not _PYIR_SKIP:
        store(
            container,
            key,
            pyir_assign(
                label,
                old,
                container[key],
                filename,
                lineno,
                owner=container,
                slot_name=key,
            ),
        )


def _pyir_cal_native_item_store(container: Any, key: Any, value: Any) -> None:
    container[key] = value


@_fatal
def _pyir_cal_getitem_rmw(label: str, container: Any, key: Any) -> Any:
    """The old value of ``container[key] op= rhs``: a meta element of module
    state is read raw, as the traced body's augmented assignment reads it
    (module state is trace-time scratch by contract, so the store follows the
    body's promotion gate, not the read's constant bake); every other read is
    the item read choke."""
    if not _pyir_cal_hooks_on():
        return container[key]
    _pyir_cal_subscript_wall(container, key, label)
    if (
        type(container) in _PLAIN_CONTAINER_KINDS
        and _pyir_cal_host_container(container) is not None
    ):
        _pyir_cal_note_host_read(container)
        value = container[key]
        if not (_is_staged_value(value) or isinstance(value, _WatchedM)):
            return value
    return _pyir_cal_getitem(label, container, key)


@_fatal
def _pyir_cal_iitem(
    container: Any,
    key: Any,
    op: str,
    old: Any,
    rhs: Any,
    label: str,
    filename: str,
    lineno: int,
) -> None:
    """``container[key] op= rhs`` (*old* read before the RHS) through the same
    lifecycle as a plain store."""
    if not _pyir_cal_hooks_on():
        container[key] = _pyir_inplace_binop(op, old, rhs)
        return
    _pyir_cal_sight(container)
    if _pyir_cal_container_internal(container):
        container[key] = _pyir_inplace_binop(op, old, rhs)
        return
    if _pyir_cal_user_item_dunder(container, "__setitem__"):
        container[key] = _pyir_inplace_binop(op, old, rhs)  # observed dunder
        return
    root = _pyir_cal_host_container(container)
    if (
        root is not None
        and not isinstance(_unwrap(old), _PLAIN_CONTAINER_TYPES)
        and _pyir_cal_host_element_native(container, key, rhs)
    ):
        container[key] = _unwrap(_pyir_inplace_binop(op, _unwrap(old), _unwrap(rhs)))
        return
    _pyir_cal_inplace_container_wall(old, op, label)
    _pyir_cal_buffer_wall(container, label)
    _pyir_cal_sc_wall(label, filename, lineno)
    if op == "or" and isinstance(old, dict):
        _pyir_cal_dict_update(old, label, filename, lineno, rhs)
        return
    stored_old = _pyir_pre_subscript_assign(label, container, key)
    if stored_old is not _PYIR_SKIP:
        container[key] = stored_old
    _pyir_subscript_store(container, key, _pyir_inplace_binop(op, old, rhs))
    if stored_old is not _PYIR_SKIP:
        container[key] = pyir_assign(
            label,
            stored_old,
            container[key],
            filename,
            lineno,
            owner=container,
            slot_name=key,
        )


@_fatal
def _pyir_cal_delitem(container: Any, key: Any, label: str, raw: bool = False) -> None:
    """``del container[key]``: an adopted container's own hook, the plain tracked-
    container wall, the native delete otherwise."""
    if _pyir_cal_hooks_on():
        _pyir_cal_subscript_wall(container, key, label, "__delitem__")
        _pyir_cal_sight(container)
        if not raw and _pyir_cal_user_item_dunder(container, "__delitem__"):
            del container[key]  # the user dunder is observed; it deletes raw
            return
        if not _pyir_cal_container_internal(container):
            _pyir_cal_buffer_wall(container, label)
            _pyir_cal_plain_container_wall(container, "__delitem__", label)
    base = _pyir_cal_builtin_subclass_base(container) if raw else None
    if base is dict:
        dict.__delitem__(container, key)
    elif base is list:
        list.__delitem__(container, key)
    else:
        del container[key]


# ``obj.__dict__[k]``: the instance mapping IS the attribute storage, so the
# spellings below are attribute accesses that bypass descriptors.


def _pyir_cal_dict_storage(obj: Any) -> Any:
    """The raw instance mapping (the chokes' storage)."""
    if isinstance(obj, (type, _types.ModuleType)):
        return vars(obj)  # a class's mapping proxy / a module namespace: never a place
    storage = _safe_instance_dict(obj)
    if storage is None:
        raise TypeError(f"{type(obj).__name__!r} object has no instance dictionary")
    return storage


def _pyir_cal_dict_view(obj: Any) -> Any:
    """``obj.__dict__`` / ``vars(obj)`` as a VALUE in a plain callee: for an
    instance, a live mapping over its storage that hides the ledger's row
    table and routes item reads / writes through the chokes."""
    if isinstance(obj, (type, _types.ModuleType)) or not _pyir_cal_hooks_on():
        return _pyir_cal_dict_storage(obj)
    storage = _pyir_cal_dict_storage(obj)
    if _pyir_cal_is_born(obj):
        return storage
    return _PyirStorageView(obj, storage)


@_fatal
def _pyir_cal_vars(obj: Any) -> Any:
    return _pyir_cal_dict_view(obj)


class _PyirStorageView(_abc.MutableMapping):
    """Live view of an instance's storage mapping: the tracer's row table is
    not an entry; items route through the ``__dict__[k]`` chokes; whole-mapping
    observations (length, iteration, membership) refuse once the key set
    changed inside a dynamic staged region this trace."""

    __slots__ = ("_pyir_obj", "_pyir_storage")
    _pyir_obj: Any
    _pyir_storage: dict

    def __init__(self, obj: Any, storage: dict) -> None:
        _pyir_setattr_raw(self, "_pyir_obj", obj)
        _pyir_setattr_raw(self, "_pyir_storage", storage)

    def _keys(self) -> "list[Any]":
        return [k for k in self._pyir_storage if k != _SLOT_STORE_ATTR]

    def __getitem__(self, key: Any) -> Any:
        if key == _SLOT_STORE_ATTR or key not in self._pyir_storage:
            _pyir_cal_keyset_wall(self._pyir_obj)
            raise KeyError(key)
        return _pyir_cal_dict_read(self._pyir_obj, key, f"<dict>[{key!r}]")

    def __setitem__(self, key: Any, value: Any) -> None:
        filename, lineno = _first_non_dsl_caller_location()
        _pyir_cal_dict_store(
            self._pyir_obj, key, value, f"<dict>[{key!r}]", filename or "", lineno or 0
        )

    def __delitem__(self, key: Any) -> None:
        if key == _SLOT_STORE_ATTR or key not in self._pyir_storage:
            raise KeyError(key)
        _pyir_cal_dict_del(self._pyir_obj, key, f"<dict>[{key!r}]")

    def __iter__(self) -> Any:
        _pyir_cal_keyset_wall(self._pyir_obj)
        return iter(self._keys())

    def __len__(self) -> int:
        _pyir_cal_keyset_wall(self._pyir_obj)
        return len(self._keys())

    def __contains__(self, key: Any) -> bool:
        if key == _SLOT_STORE_ATTR:
            return False
        present = key in self._pyir_storage
        if not present:
            _pyir_cal_keyset_wall(self._pyir_obj)
            if isinstance(key, str) and _pyir_cal_dynamic_staged():
                _pyir_note_absent_probe(
                    self._pyir_obj, key, "a `__dict__` membership test"
                )
        return present

    def get(self, key: Any, default: Any = None) -> Any:
        return _pyir_cal_dict_get(self._pyir_obj, key, default)

    def copy(self) -> dict:
        return dict(self.items())

    __copy__ = copy

    def __repr__(self) -> str:
        return repr(dict(self.items()))


# id(obj) -> (pin, first observation site): instances whose storage mapping
# was observed as a whole (length, iteration, membership) this trace.
_KEYSET_OBSERVED: "dict[int, tuple[Any, tuple]]" = {}


def _pyir_cal_keyset_wall(obj: Any) -> None:
    """Record a whole-mapping observation of an instance's storage."""
    if not _pyir_cal_hooks_on() or _pyir_cal_is_born(obj):
        return
    if id(obj) in _KEYSET_OBSERVED and _KEYSET_OBSERVED[id(obj)][0]() is obj:
        return
    _KEYSET_OBSERVED[id(obj)] = (_pyir_cal_pin(obj), _first_non_dsl_caller_location())


def _pyir_cal_check_keyset_observations() -> None:
    if not _KEYSET_OBSERVED or _PYIR_PENDING_USER_DIAGNOSTIC[0] is not None:
        return
    for oid, (pin, site) in list(_KEYSET_OBSERVED.items()):
        obj = pin()
        changed = _KEYSET_CHANGED.get(oid)
        if obj is None or changed is None or changed[0]() is not obj or not changed[1]:
            continue
        filename, lineno = site
        raise _pyir_fatal_trace_error(
            DSLUserCodeError(
                DiagId.CONTAINER_DICT_KEY_SET_BAKED_READ,
                filename=filename,
                lineno=lineno,
                var=(
                    _pyir_cal_host_container(obj) or "dict"
                    if isinstance(obj, dict)
                    else f"{type(obj).__name__}.__dict__"
                ),
                detail=", ".join(repr(k) for k in sorted(changed[1], key=repr)),
            )
        )


def _pyir_cal_note_keyset_change(obj: Any, name: Any, *, unbind: bool = False) -> None:
    """Record a key-set change of *obj*'s storage inside a dynamic staged
    region; *unbind* retracts a birth recorded earlier in the same region
    (the binding never persisted)."""
    if not _pyir_cal_dynamic_staged():
        return
    entry = _KEYSET_CHANGED.get(id(obj))
    if entry is None or entry[0]() is not obj:
        if unbind:
            return
        entry = (_pyir_cal_pin(obj), set())
        _KEYSET_CHANGED[id(obj)] = entry
    if unbind:
        entry[1].discard(name)
    else:
        entry[1].add(name)


@_fatal
def _pyir_cal_dict_read(obj: Any, key: Any, label: str) -> Any:
    storage = _pyir_cal_dict_storage(obj)
    value = storage[key]
    if (
        not _pyir_cal_hooks_on()
        or not isinstance(key, str)
        or isinstance(obj, type)
        or _pyir_cal_is_born(obj)
    ):
        return value
    if isinstance(value, _CALLABLE_VALUE_TYPES):
        return value
    _pyir_cal_sight(value)
    return _pyir_cal_read_pin(
        pyir_read(label, value, attach_ref=False, owner=obj, slot_name=key)
    )


@_fatal
def _pyir_cal_dict_store(
    obj: Any, key: Any, value: Any, label: str, filename: str, lineno: int
) -> None:
    storage = _pyir_cal_dict_storage(obj)
    if not _pyir_cal_hooks_on() or _pyir_cal_is_born(obj):
        storage[key] = value
        return
    if not isinstance(key, str):
        if key not in storage and not isinstance(obj, (type, _types.ModuleType)):
            _pyir_cal_note_keyset_change(obj, key)
        storage[key] = value
        return
    if isinstance(obj, _types.ModuleType):
        if _pyir_cal_dynamic_staged():
            _pyir_cal_refuse_host_state(label, _KIND_MODULE)
        storage[key] = value
        return
    # The store choke may route the write back through the type-level setter (a data
    # descriptor of the same name), whose body spells this very store: the inner
    # occurrence is the storage write itself.
    guard = (id(obj), "#" + key)
    if guard in _ACTIVE_ACCESS:
        storage[key] = value
        return
    _ACTIVE_ACCESS.add(guard)
    try:
        if _PENDING_DELETES:
            _pyir_cal_finish_pending_delete(obj, key)
        _pyir_cal_closure_escape_wall(value, label)
        born = _pyir_cal_is_born(value)
        _pyir_cal_escaped(value)
        _pyir_cal_sc_wall(label, filename, lineno)
        _pyir_cal_hold(value)
        _pyir_cal_meta_store_pin(
            value, label, filename, lineno, _PyirItemProbe(storage, key)
        )
        # The mapping IS the storage: no descriptor and no ``__setattr__`` override
        # stands between this spelling and the slot, so the store lifecycle runs on
        # the slot directly.
        pre = storage.get(key, _PYIR_BOUNDARY_MISSING)
        detach = False
        if pre is _PYIR_BOUNDARY_MISSING:
            old = None
        else:
            old = pyir_read(label, pre, owner=obj, slot_name=key)
            if old is not pre:
                dict.__setitem__(storage, key, old)
            detach = _pyir_cal_replaced_object(old, value, label, born)
        dict.__setitem__(storage, key, value)
        result = pyir_assign(
            label, old, value, filename, lineno, owner=obj, slot_name=key
        )
        if result is not value:
            dict.__setitem__(storage, key, result)
        if detach:
            _pyir_cal_mark_detached(old, label)
        if pre is _PYIR_BOUNDARY_MISSING:
            if not _is_staged_value(value):
                _pyir_record_cf_attr_first_def(obj, key)
            _pyir_cal_note_born_binding(obj, key)
    finally:
        _ACTIVE_ACCESS.discard(guard)


@_fatal
def _pyir_cal_dict_get(obj: Any, key: Any, *default: Any) -> Any:
    """``obj.__dict__.get(key[, default])``: the attribute read with a default."""
    storage = _pyir_cal_dict_storage(obj)
    if key not in storage or key == _SLOT_STORE_ATTR:
        if _pyir_cal_hooks_on() and not isinstance(obj, (type, _types.ModuleType)):
            _pyir_cal_keyset_wall(obj)
            if isinstance(key, str) and _pyir_cal_dynamic_staged():
                _pyir_note_absent_probe(obj, key, "a default-taken `__dict__.get`")
        if default:
            return default[0]
        return None
    return _pyir_cal_dict_read(obj, key, f"<dict>.{key}")


@_fatal
def _pyir_cal_dict_del(obj: Any, key: Any, label: str) -> None:
    storage = _pyir_cal_dict_storage(obj)
    if not _pyir_cal_hooks_on() or _pyir_cal_is_born(obj):
        del storage[key]
        return
    if not isinstance(key, str):
        del storage[key]
        if not isinstance(obj, (type, _types.ModuleType)):
            _pyir_cal_note_keyset_change(obj, key)
        return
    if not _pyir_cal_dynamic_staged():
        del storage[key]
        _pyir_retire_place_row(None, obj, key)
        _pyir_spec_record_unbind(obj, key)
        return
    old = storage.get(key, _PYIR_BOUNDARY_MISSING)
    del storage[key]
    _pyir_cal_note_keyset_change(obj, key)
    if _pyir_cal_unbind_born(obj, key):
        return
    _PENDING_DELETES[(id(obj), key)] = (
        _PyirTracePin(obj),
        _PyirTracePin(old),
        _pyir_current_region_arm_path(),
    )


@_fatal
def _pyir_cal_global_store(
    namespace: Any,
    name: str,
    value: Any,
    label: str,
    filename: str,
    lineno: int,
    writer: str = "",
) -> None:
    """A ``global`` name bound inside a plain callee: module state, written
    natively; inside dynamic staged CF the write cannot be predicated or
    carried, so it refuses (*writer* names the callee whose body writes)."""
    if _pyir_cal_hooks_on() and _pyir_cal_dynamic_staged():
        raise _pyir_fatal_trace_error(
            DSLUserCodeError(
                DiagId.UNSUP_GLOBAL_WRITE_IN_STAGED_CF,
                filename=filename,
                lineno=lineno,
                callee=writer or _pyir_cal_writer_at(filename, lineno),
                name=name,
            )
        )
    namespace[name] = value


@_fatal
def _pyir_cal_cell_read(cell: Any, name: str, label: str) -> Any:
    """A free variable read: the closure cell is the place owner."""
    try:
        value = cell.cell_contents
    except ValueError:
        raise NameError(
            f"cannot access free variable '{name}' where it is not associated "
            "with a value in enclosing scope"
        ) from None
    if (
        not _pyir_cal_hooks_on()
        or isinstance(value, _CALLABLE_VALUE_TYPES)
        or _pyir_cal_is_born(cell)
    ):
        return value
    if _pyir_cal_dynamic_staged() and (
        type(value) in (bool, int, float) or isinstance(value, _WatchedM)
    ):
        # A scalar read through a shared cell inside dynamic staged CF bakes the
        # cell's value; recorded by cell identity so a later staged write of the
        # owning local refuses (BOUNDARY_CLOSURE_READ_THEN_*).
        tok = _owner_token(cell)
        if tok is not None:
            def_file, def_line = _first_non_dsl_caller_location()
            _PYIR_BOUNDARY_META_CELL_READS.setdefault(
                ("cell", tok), (name, def_file or "<closure read>", def_line or 0)
            )
    _pyir_cal_sight(value)
    _pyir_cal_note_homed(value)
    return _pyir_cal_read_pin(
        pyir_read(label, value, attach_ref=False, owner=cell, slot_name="cell_contents")
    )


@_fatal
def _pyir_cal_cell_del(cell: Any, name: str, label: str) -> None:
    """``del x`` on a ``nonlocal`` name: the deletion protocol of ``del obj.name``
    on the closure cell."""
    if not _pyir_cal_hooks_on() or _pyir_cal_is_born(cell):
        del cell.cell_contents
        return
    if not _pyir_cal_dynamic_staged():
        del cell.cell_contents
        _pyir_retire_place_row(None, cell, "cell_contents")
        _pyir_spec_record_unbind(cell, "cell_contents")
        return
    try:
        old = cell.cell_contents
    except ValueError:
        old = _PYIR_BOUNDARY_MISSING
    del cell.cell_contents
    if _pyir_cal_unbind_born(cell, "cell_contents"):
        return
    _PENDING_DELETES[(id(cell), "cell_contents")] = (
        _PyirTracePin(cell),
        _PyirTracePin(old),
        _pyir_current_region_arm_path(),
    )


@_fatal
def _pyir_cal_cell_store(
    cell: Any, name: str, value: Any, label: str, filename: str, lineno: int
) -> None:
    """A ``nonlocal`` store: the closure cell is the place owner."""
    if not _pyir_cal_hooks_on() or _pyir_cal_is_born(cell):
        cell.cell_contents = value
        return
    if _PENDING_DELETES:
        _pyir_cal_pending_deletes_check()
        _pyir_cal_finish_pending_delete(cell, "cell_contents")
    _pyir_cal_closure_escape_wall(value, label)
    born = _pyir_cal_is_born(value)
    _pyir_cal_escaped(value)
    _pyir_cal_sc_wall(label, filename, lineno)
    _pyir_cal_hold(value)
    _pyir_cal_meta_store_pin(value, label, filename, lineno, _PyirCellProbe(cell))
    try:
        current = cell.cell_contents
    except ValueError:
        cell.cell_contents = value
        pyir_note_attr_first_def(label, cell, "cell_contents", value)
        return
    detach = _pyir_cal_replaced_object(current, value, label, born)
    fresh = _pyir_pre_attr_assign(label, current, owner=cell, slot_name="cell_contents")
    if fresh is not _PYIR_SKIP:
        cell.cell_contents = fresh
    old = cell.cell_contents
    cell.cell_contents = value
    result = _pyir_post_attr_assign(
        label,
        old,
        cell.cell_contents,
        filename,
        lineno,
        owner=cell,
        slot_name="cell_contents",
    )
    if result is not _PYIR_SKIP:
        cell.cell_contents = result
    if detach:
        _pyir_cal_mark_detached(old, label)


@_fatal
def _pyir_cal_cell_iop(
    cell: Any, name: str, op: str, rhs: Any, label: str, filename: str, lineno: int
) -> None:
    """``x op= rhs`` on a ``nonlocal`` name."""
    old = _pyir_cal_cell_read(cell, name, label)
    _pyir_cal_cell_store(
        cell, name, _pyir_inplace_binop(op, old, rhs), label, filename, lineno
    )


@_fatal
def _pyir_cal_iter(iterable: Any) -> Any:
    """``for x in iterable`` inside a plain callee: iterating a persisted
    iterator/generator inside dynamic staged CF advances host state."""
    if _pyir_cal_hooks_on():
        if iterable is not None and type(iterable) not in _SCALAR_TYPES:
            _pyir_cal_sight(iterable)
            _pyir_cal_note_host_read(iterable)
            if isinstance(iterable, dict) and not isinstance(iterable, _WatchedDict):
                _pyir_cal_keyset_wall(iterable)
        if _pyir_cal_dynamic_staged():
            kind = _pyir_cal_host_state_kind(iterable)
            if kind in (_KIND_ITERATOR, _KIND_GENERATOR) and not _pyir_cal_is_born(
                iterable
            ):
                _pyir_cal_refuse_host_state("the iterated object", kind)
            if kind in _VIEW_KINDS and not _pyir_cal_is_born(iterable):
                _pyir_cal_refuse_dict_view(
                    _pyir_cal_label_of(iterable, "the iterated object"), iterable
                )
    return iterable


def _pyir_cal_reraise(exc: BaseException) -> None:
    """Handler prologue: a DSL diagnostic raised by a choke inside the guarded
    block is the trace's verdict, never the user's exception to handle."""
    if isinstance(exc, DSLBaseError):
        raise exc


def _pyir_cal_class_arg(cls: Any) -> Any:
    """A base or metaclass of a class statement inside a plain callee: a user
    class is instrumented so the inherited / metaclass code observes."""
    if isinstance(cls, type) and _pyir_boundary_module_is_user(
        getattr(cls, "__module__", None)
    ):
        _pyir_instrument_class(cls)
    return cls


# -- Native callees ---------------------------------------------------------


def _pyir_cal_unbound_mutator(descriptor: Any, owner: type, name: str) -> Any:
    def _routed(container: Any, *args: Any, **kwargs: Any) -> Any:
        if _pyir_cal_active() and isinstance(container, owner):
            if isinstance(container, (_WatchedDict, _WatchedList)):
                # An adopted (watched) container: its own method is the hook.
                return getattr(container, name)(*args, **kwargs)
            if name == "__setitem__" and len(args) == 2 and not kwargs:
                filename, lineno = _first_non_dsl_caller_location()
                _pyir_cal_setitem(
                    container,
                    args[0],
                    args[1],
                    "<receiver>",
                    filename or "",
                    lineno or 0,
                    raw=True,
                )
                return None
            if name == "__delitem__" and len(args) == 1 and not kwargs:
                _pyir_cal_delitem(container, args[0], "<receiver>", raw=True)
                return None
            args = _pyir_cal_method_key_wall(container, name, args)
            _pyir_cal_plain_container_wall(container, name, "<receiver>", args)
        return descriptor(container, *args, **kwargs)

    _routed.__name__ = name
    _routed.__qualname__ = f"{owner.__name__}.{name}"
    return _routed


_UNBOUND_MUTATOR_ROUTES: "dict[int, tuple[Any, Any]]" = {
    id(desc): (desc, _pyir_cal_unbound_mutator(desc, owner, name))
    for owner, names in _UNBOUND_MUTATOR_NAMES.items()
    for name in names
    if (desc := vars(owner).get(name)) is not None
}


def _pyir_cal_descriptor_store(descriptor: Any, method: str) -> Any:
    """``Cls.attr.__set__(inst, v)`` / ``__delete__``: the explicit descriptor
    protocol on a slot / getset / property descriptor is the attribute store
    on the instance, choked like ``inst.attr = v``."""
    name = getattr(descriptor, "__name__", None) or getattr(
        getattr(descriptor, "fset", None), "__name__", "<descriptor>"
    )

    owner_cls = getattr(descriptor, "__objclass__", None)

    def _applies(inst: Any) -> bool:
        return not isinstance(owner_cls, type) or isinstance(inst, owner_cls)

    def _set(inst: Any, value: Any) -> None:
        if not _applies(inst):
            descriptor.__set__(inst, value)  # the native TypeError
            return
        filename, lineno = _first_non_dsl_caller_location()
        _pyir_cal_setattr(
            inst, name, value, f"<descriptor>.{name}", filename or "", lineno or 0
        )

    def _delete(inst: Any) -> None:
        if not _applies(inst):
            descriptor.__delete__(inst)
            return
        _pyir_cal_delattr(inst, name, f"<descriptor>.{name}")

    return _set if method == "__set__" else _delete


def _pyir_cal_descriptor_read(descriptor: Any) -> Any:
    """``Cls.attr.__get__(inst, owner)``: the explicit descriptor protocol is
    the attribute read on the instance, choked like ``inst.attr``."""
    name = getattr(descriptor, "__name__", None) or getattr(
        getattr(descriptor, "fget", None), "__name__", "<descriptor>"
    )

    owner_cls = getattr(descriptor, "__objclass__", None)

    def _get(inst: Any, owner: Any = None) -> Any:
        if inst is None:
            return descriptor
        if isinstance(owner_cls, type) and not isinstance(inst, owner_cls):
            return descriptor.__get__(inst, owner)  # the native TypeError
        return _pyir_cal_getattr(inst, name, f"<descriptor>.{name}")

    return _get


def _pyir_cal_super_setattr(sup: Any, name: Any, value: Any) -> None:
    """``super().__setattr__(name, value)`` inside a protocol dunder: the slot
    of ``object``/``type`` is the choked raw store; a user base's override is
    observed code and is called directly."""
    target = getattr(sup, "__self__")
    method = getattr(sup, "__setattr__")
    if isinstance(method, (_types.MethodWrapperType, _types.BuiltinMethodType)):
        if isinstance(target, type):
            _pyir_cal_class_store(target, name, value)
        else:
            _pyir_routed_object_setattr(target, name, value)
        return
    method(name, value)


def _pyir_cal_super_delattr(sup: Any, name: Any) -> None:
    target = getattr(sup, "__self__")
    method = getattr(sup, "__delattr__")
    if isinstance(method, (_types.MethodWrapperType, _types.BuiltinMethodType)):
        _pyir_cal_delattr(target, name, f"<delattr>.{name}")
        return
    method(name)


def _pyir_cal_object_setattr(obj: Any, name: Any, value: Any) -> None:
    """``object.__setattr__(obj, name, value)`` spelled in a plain callee: the
    routed raw store (the choke sees the storage write)."""
    _pyir_routed_object_setattr(obj, name, value)


def _pyir_cal_reflect_setattr(obj: Any, name: Any, value: Any) -> None:
    """Bare ``setattr(obj, name, value)`` in a plain callee: the attribute
    store with the name resolved at run time."""
    if _pyir_cal_active() and isinstance(name, str):
        filename, lineno = _first_non_dsl_caller_location()
        _pyir_cal_setattr(
            obj, name, value, f"<setattr>.{name}", filename or "", lineno or 0
        )
        return
    setattr(obj, name, value)


def _pyir_cal_reflect_delattr(obj: Any, name: Any) -> None:
    if _pyir_cal_active() and isinstance(name, str):
        _pyir_cal_delattr(obj, name, f"<delattr>.{name}")
        return
    delattr(obj, name)


def _pyir_cal_user_owner(obj: Any) -> bool:
    cls = obj if isinstance(obj, type) else type(obj)
    return _pyir_boundary_module_is_user(getattr(cls, "__module__", None))


def _pyir_cal_class_store(cls: Any, name: Any, value: Any) -> None:
    """``type.__setattr__(cls, name, value)`` (explicit or via ``super()`` in a
    metaclass): the class-attribute store, choked like ``cls.name = value``."""
    if _pyir_cal_active() and isinstance(cls, type) and _pyir_cal_user_owner(cls):
        _pyir_reflect_store(type.__setattr__, cls, name, value)
        return
    type.__setattr__(cls, name, value)


def _pyir_cal_native_callee(callee: Any, births_seen: bool = True) -> Any:
    """Dispatcher arm for a native callee: the routed twin when the native
    spelling is a reflection / descriptor / unbound-mutator access, else None.
    The unbound-mutator twin judges its receiver's birth, so only a rewritten
    body's spelling routes to it."""
    if births_seen:
        route = _UNBOUND_MUTATOR_ROUTES.get(id(callee))
        if route is not None and route[0] is callee:
            return route[1]
    receiver0 = getattr(callee, "__self__", None)
    if (
        isinstance(receiver0, dict)
        and getattr(callee, "__name__", None) == "update"
        and _pyir_cal_hooks_on()
        and _pyir_cal_dynamic_staged()
        and not _pyir_cal_is_born(receiver0)
        and (
            isinstance(receiver0, _WatchedDict)
            or _pyir_cal_mro_member(type(receiver0), "update")
            is dict.__dict__["update"]
        )
    ):
        return _PyirDictUpdate(receiver0)
    if (
        isinstance(receiver0, BaseException)
        and getattr(callee, "__name__", None) == "__setstate__"
        and _pyir_cal_hooks_on()
        and not _pyir_cal_is_born(receiver0)
    ):
        return _PyirExceptionSetState(receiver0)
    if callee is type.__setattr__:
        return _pyir_cal_class_store
    if callee is type.__delattr__:
        return lambda cls, attr: _pyir_cal_delattr(cls, attr, f"<type>.{attr}")
    if isinstance(callee, (_types.MethodWrapperType, _types.BuiltinMethodType)):
        receiver = getattr(callee, "__self__", None)
        name = getattr(callee, "__name__", None)
        if (
            name in ("__setitem__", "__delitem__")
            and receiver is not None
            and not isinstance(receiver, (_WatchedDict, _WatchedList))
            and (
                type(receiver) in _PLAIN_CONTAINER_KINDS
                or _pyir_cal_builtin_subclass_base(receiver) in _PLAIN_CONTAINER_KINDS
            )
            and _pyir_cal_hooks_on()
        ):
            # ``super().__setitem__(k, v)`` inside a user ``__setitem__``: the
            # storage write of the observed dunder.
            return (
                _PyirItemStore(receiver)
                if name == "__setitem__"
                else _PyirItemDelete(receiver)
            )
        if name in ("__setattr__", "__delattr__") and receiver is not None:
            target = (
                getattr(receiver, "__self__")
                if isinstance(receiver, super)
                else receiver
            )
            if _pyir_cal_user_owner(target):
                if name == "__setattr__":
                    if isinstance(target, type):
                        return lambda attr, value: _pyir_cal_class_store(
                            target, attr, value
                        )
                    return lambda attr, value: _pyir_routed_object_setattr(
                        target, attr, value
                    )
                return lambda attr: _pyir_cal_delattr(target, attr, f"<delattr>.{attr}")
        if isinstance(receiver, _DESCRIPTOR_TYPES):
            if name in ("__set__", "__delete__"):
                return _pyir_cal_descriptor_store(receiver, name)
            if name == "__get__":
                return _pyir_cal_descriptor_read(receiver)
    return None


class _PyirExceptionSetState:
    """``exc.__setstate__(state)``: the native protocol installs each entry of
    *state* as an attribute; here each install is an attribute store."""

    __slots__ = ("_pyir_exc",)

    def __init__(self, exc: Any) -> None:
        self._pyir_exc = exc

    def __call__(self, state: Any) -> None:
        exc = self._pyir_exc
        if state is None:
            return
        if not isinstance(state, dict):
            BaseException.__setstate__(exc, state)  # the native TypeError
            return
        filename, lineno = _first_non_dsl_caller_location()
        for k, v in state.items():
            if isinstance(k, str):
                _pyir_cal_setattr(
                    exc, k, v, f"<__setstate__>.{k}", filename or "", lineno or 0
                )
            else:
                BaseException.__setstate__(exc, {k: v})


def _pyir_cal_generator_point(gen: Any) -> Any:
    frame = getattr(gen, "gi_frame", None)
    if frame is None:
        frame = getattr(gen, "cr_frame", None)
    if frame is None:
        frame = getattr(gen, "ag_frame", None)
    return None if frame is None else frame.f_lasti


def _pyir_cal_native_policy(
    callee: Any, args: Any, kwargs: Any, fresh: Any = (), births_seen: bool = True
) -> Any:
    """Pre-call arm for a native (non-user) callee: swap the user callables and
    classes it receives so its calls back into user code observe (routed builtins
    replace themselves as callbacks); inside dynamic staged CF, refuse when it
    advances host state through its receiver or an argument, or compiles code
    from a string."""
    if not _pyir_cal_active():
        _GEN_PROBES.append([])  # keep the probe stack paired with the result arm
        return None
    new_args = tuple(_pyir_cal_observe_value(a) for a in args)
    new_kwargs = (
        {k: _pyir_cal_observe_value(v) for k, v in kwargs.items()} if kwargs else kwargs
    )
    replaced = any(a is not b for a, b in zip(new_args, args)) or any(
        new_kwargs[k] is not kwargs[k] for k in kwargs
    )
    if _PENDING_DELETES:
        _pyir_cal_pending_deletes_check()
    _pyir_cal_note_consumption(
        callee,
        getattr(callee, "__name__", None) or "",
        getattr(callee, "__self__", None),
        new_args,
        new_kwargs or {},
    )
    receiver0 = getattr(callee, "__self__", None)
    key_args = new_args
    if receiver0 is None and getattr(callee, "__objclass__", None) is dict and new_args:
        # An unbound dict method spelled on the class: ``dict.get(d, k)``.
        receiver0, key_args = new_args[0], new_args[1:]
    walled = _pyir_cal_method_key_wall(
        receiver0, getattr(callee, "__name__", None) or "", key_args
    )
    if walled is not key_args:
        new_args, replaced = (*new_args[: len(new_args) - len(key_args)], *walled), True
    if not _pyir_cal_dynamic_staged():
        _GEN_PROBES.append([])
        return (new_args, new_kwargs) if replaced else None
    _GEN_PROBES.append([])
    fresh_positions = set(fresh or ())
    if getattr(callee, "__module__", None) in _FIELD_READING_MODULES:
        for a in new_args:
            if _pyir_boundary_is_user_holder(a) and not _pyir_cal_is_born(a):
                _pyir_cal_refresh_holder(a)
    method = getattr(callee, "__name__", None) or ""
    if (
        callee is _builtins.exec
        or callee is _builtins.eval
        or callee is _builtins.compile
    ):
        _pyir_cal_refuse_host_state(f"the code given to `{method}`", _KIND_EXEC, callee)
    receiver = getattr(callee, "__self__", None)
    if receiver is None and _pyir_cal_host_state_kind(callee) == _KIND_FINALIZER:
        receiver, method = callee, "__call__"
    if receiver is not None and (
        type(receiver) in _PLAIN_CONTAINER_KINDS
        or _pyir_cal_builtin_subclass_base(receiver) in _PLAIN_CONTAINER_KINDS
    ):
        _pyir_cal_plain_container_wall(
            receiver, method, _pyir_cal_label_of(receiver), new_args, births_seen
        )
    if receiver is not None and not isinstance(receiver, _types.ModuleType):
        kind = _pyir_cal_host_state_kind(receiver)
        if kind is not None and kind not in (_KIND_FUNCTION, _KIND_MODULE):
            if kind == _KIND_GENERATOR:
                if not _pyir_cal_is_born(receiver):
                    _GEN_PROBES[-1].append(
                        (receiver, _pyir_cal_generator_point(receiver))
                    )
            else:
                mutators = _MUTATORS.get(kind)
                advances = (
                    method not in _RNG_READERS
                    if kind == _KIND_RNG
                    else (mutators is None or method in mutators)
                )
                if advances and not (
                    kind in (_KIND_ITERATOR, _KIND_FINALIZER)
                    and _pyir_cal_is_born(receiver)
                ):
                    _pyir_cal_refuse_host_state(
                        _pyir_cal_label_of(receiver, f"<receiver>.{method}"),
                        kind,
                        callee,
                    )
    for pos, a in enumerate(new_args):
        if pos in fresh_positions:
            continue  # born for this call (a comprehension / generator expression)
        kind = _pyir_cal_host_state_kind(a)
        if kind == _KIND_GENERATOR:
            if method not in _ITERATOR_INSPECTORS and not _pyir_cal_is_born(a):
                _GEN_PROBES[-1].append((a, _pyir_cal_generator_point(a)))
        elif kind == _KIND_ITERATOR:
            if method in _ITERATOR_INSPECTORS or _pyir_cal_is_born(a):
                continue
            _pyir_cal_refuse_host_state(
                _pyir_cal_label_of(a, f"the {type(a).__name__} passed to {method}()"),
                kind,
                callee,
            )
        elif kind == _KIND_BUFFER and method not in _BUFFER_INSPECTORS:
            _pyir_cal_refuse_host_state(
                _pyir_cal_label_of(a, f"the {type(a).__name__} passed to {method}()"),
                kind,
                callee,
            )
        elif kind in _VIEW_KINDS:
            # A view over a dict born in this region reads trace-internal state.
            mapping = getattr(a, "mapping", None)
            if _pyir_cal_is_born(a) or (
                mapping is not None and _pyir_cal_is_born(mapping)
            ):
                continue
            _pyir_cal_refuse_dict_view(
                _pyir_cal_label_of(a, f"the {type(a).__name__} passed to {method}()"), a
            )
    return (new_args, new_kwargs) if replaced else None


# Native code that reads a user object's fields raw (copies, serialisers):
# the fields it sees must be the region's live values, not the trace pass's.
_FIELD_READING_MODULES = frozenset(
    {"copy", "dataclasses", "pickle", "json", "pprint", "reprlib"}
)


def _pyir_cal_refresh_holder(holder: Any) -> None:
    """Load every scalar field of *holder* at this position and rebind the storage
    to the read: native code reading the storage raw sees the live staged value,
    and a meta field it copies out reaches the copy as its watched read, so a
    later promotion of the field retargets the copy's derived values."""
    if _is_staged_value(holder) or isinstance(holder, _WatchedM):
        return
    items = _instance_storage_items(holder)
    if not items:
        return
    for name, value in list(items.items()):
        if name == _SLOT_STORE_ATTR or not isinstance(name, str):
            continue
        if not (
            _is_staged_value(value)
            or isinstance(value, _WatchedM)
            or type(value) in (int, float, bool)
        ):
            continue
        fresh = _pyir_cal_read_pin(
            pyir_read(
                f"<native>.{name}",
                value,
                attach_ref=False,
                owner=holder,
                slot_name=name,
            )
        )
        if fresh is not value:
            _pyir_boundary_bind_storage(holder, name, fresh)


def _pyir_cal_is_factory(callee: Any) -> bool:
    if isinstance(callee, type):
        return True
    if any(callee is builtin for builtin in _FACTORY_BUILTINS):
        return True
    if getattr(callee, "__module__", None) in _FACTORY_MODULES:
        return True
    receiver = getattr(callee, "__self__", None)
    return (
        receiver is not None and getattr(callee, "__name__", None) in _FACTORY_METHODS
    )


def _pyir_cal_direct_parts(obj: Any) -> Any:
    """The objects *obj* holds directly: a mapping's values, a sequence's
    or set's items, an instance's attribute values."""
    if obj is None or type(obj) in _SCALAR_TYPES:
        return ()
    if isinstance(obj, dict):
        return list(dict.values(obj))
    if isinstance(obj, (list, tuple, set, frozenset)):
        return list(obj)
    storage = _safe_instance_dict(obj)
    parts = list(storage.values()) if storage else []
    for klass in type(obj).__mro__:
        for slot in getattr(klass, "__slots__", ()):
            if isinstance(slot, str) and slot not in ("__dict__", "__weakref__"):
                member = klass.__dict__.get(slot)
                if isinstance(member, _types.MemberDescriptorType):
                    try:
                        parts.append(member.__get__(obj, type(obj)))
                    except AttributeError:
                        pass
    return parts


def _pyir_cal_fresh_result(
    result: Any, receiver: Any, args: tuple, kwargs: dict
) -> bool:
    """A plain builtin container or user object a native callee returned that none
    of its inputs held before the call (not an input itself, not held directly by
    one, no home yet): the call created it, so it is trace-internal like a
    literal or a constructor result."""
    if not (
        type(result) in _PLAIN_CONTAINER_KINDS
        or _pyir_cal_builtin_subclass_base(result) in _PLAIN_CONTAINER_KINDS
        or _pyir_boundary_is_user_holder(result)
    ):
        return False
    if _pyir_cal_is_held(result) or _pyir_cal_host_container(result) is not None:
        return False
    if isinstance(receiver, _contextvars.ContextVar):
        return False  # the variable held the value; the walk cannot see inside it
    homed = _HOMED.get(id(result))
    if homed is not None and homed() is result:
        return False
    for source in (receiver, *args, *kwargs.values()):
        if source is result:
            return False
        for part in _pyir_cal_direct_parts(source):
            if part is result:
                return False
    return True


def _pyir_cal_freeze_born_fields(obj: Any, _depth: int = 0) -> None:
    """A native constructor / factory binds the born object's fields to the RHS
    objects themselves: a field still re-resolving a foreign cell would follow
    that cell's later stores, so it is frozen to its construction-time value
    (the attr first-def freeze for stores no choke saw)."""
    if _depth > 2 or obj is None or type(obj) in _SCALAR_TYPES:
        return
    if type(obj) in (list, dict):
        if _carries_foreign_slot_binding(obj):
            _freeze_foreign_slot_binding(obj, "born container", fresh_container=True)
        for part in list(obj.values() if isinstance(obj, dict) else obj):
            if _pyir_cal_is_born(part):
                _pyir_cal_freeze_born_fields(part, _depth + 1)
        return
    items = _instance_storage_items(obj)
    if not items:
        return
    for name, value in list(items.items()):
        if name == _SLOT_STORE_ATTR:
            continue
        if _carries_foreign_slot_binding(value):
            frozen = _freeze_foreign_slot_binding(value, f"born field '{name}'")
            if frozen is not value:
                _pyir_holder_store(obj, name, frozen)
        elif _pyir_cal_is_born(value):
            _pyir_cal_freeze_born_fields(value, _depth + 1)


def _pyir_cal_native_result(
    callee: Any,
    result: Any,
    args: tuple = (),
    kwargs: "dict | None" = None,
    probed: bool = True,
) -> None:
    """Post-call arm for a native callee: a probed generator that moved to another
    suspension point refuses; a constructor / factory result, or a container none
    of the inputs held, is born in the region; a user object it returns is
    sighted."""
    probes = _GEN_PROBES.pop() if probed and _GEN_PROBES else []
    if not _pyir_cal_active():
        return
    inputs = (getattr(callee, "__self__", None), args, kwargs or {})
    for gen, before in probes:
        if _pyir_cal_generator_point(gen) != before:
            _pyir_cal_refuse_host_state(
                _pyir_cal_label_of(gen), _KIND_GENERATOR, callee
            )
    if result is None or type(result) in _SCALAR_TYPES:
        return
    if isinstance(result, _CALLABLE_VALUE_TYPES):
        return
    if (
        is_inside_staged_cf()
        and not isinstance(result, (_WatchedDict, _WatchedList, _WatchedM))
        and _pyir_lookup_owner_token(result) is None
        and (_pyir_cal_is_factory(callee) or _pyir_cal_fresh_result(result, *inputs))
    ):
        _pyir_cal_mark_born(result)
        _pyir_cal_mark_born_parts(result)
        _pyir_cal_freeze_born_fields(result)
        return
    if type(result) not in _SCALAR_TYPES:
        # A result that holds an input directly (``[obj]``, a wrapper over
        # it) is a further binding of that input.
        parts = _pyir_cal_direct_parts(result)
        if parts:
            for source in (inputs[0], *inputs[1], *inputs[2].values()):
                if source is not None and _pyir_boundary_is_user_holder(source):
                    if any(part is source for part in parts):
                        _pyir_cal_hold(source)
    if _pyir_cal_host_state_kind(result) is None:
        _pyir_cal_observe_leaf(result)


# -- Source-level rewrite ----------------------------------------------------


def _pyir_mangle(name: str, class_name: "str | None") -> str:
    """CPython private-name mangling for a body compiled outside its class."""
    if (
        class_name is None
        or not name.startswith("__")
        or name.endswith("__")
        or "." in name
    ):
        return name
    stripped = class_name.lstrip("_")
    if not stripped:
        return name
    return f"_{stripped}{name}"


def _pyir_cal_label(node: "_ast.AST") -> str:
    try:
        text = _ast.unparse(node)
    except Exception:
        return "<expr>"
    return text if len(text) <= 80 else text[:77] + "..."


def _is_simple(node: "_ast.expr") -> bool:
    return isinstance(node, (_ast.Name, _ast.Constant))


def _is_dunder_dict(node: "_ast.expr") -> bool:
    """``x.__dict__`` or ``vars(x)``: the instance mapping spelled directly."""
    if isinstance(node, _ast.Attribute) and node.attr == "__dict__":
        return True
    return (
        isinstance(node, _ast.Call)
        and isinstance(node.func, _ast.Name)
        and node.func.id == "vars"
        and len(node.args) == 1
        and not node.keywords
        and not isinstance(node.args[0], _ast.Starred)
    )


def _dunder_dict_owner(node: "_ast.expr") -> "_ast.expr":
    return node.value if isinstance(node, _ast.Attribute) else node.args[0]  # type: ignore[attr-defined]


def _table_free_names(table: Any) -> "frozenset[str]":
    """Names of *table*'s scope that live in a closure cell of an enclosing
    function (free or declared ``nonlocal``)."""
    if table is None:
        return frozenset()
    names = set()
    for sym in table.get_symbols():
        if (sym.is_free() or sym.is_nonlocal()) and sym.get_name() != "__class__":
            names.add(sym.get_name())
    return frozenset(names)


def _table_cell_names(table: Any) -> "tuple[str, ...]":
    """Names of *table*'s scope that a nested scope closes over (the scope's
    own closure cells), in a stable order."""
    if table is None:
        return ()
    own = {sym.get_name() for sym in table.get_symbols() if not sym.is_free()}
    names: "set[str]" = set()
    for child in table.get_children():
        names |= set(_table_free_names(child)) & own
    return tuple(sorted(names))


def _table_nonlocal_names(table: Any) -> "frozenset[str]":
    if table is None:
        return frozenset()
    return frozenset(s.get_name() for s in table.get_symbols() if s.is_nonlocal())


class _PyirCalleeAccessRewriter(_ast.NodeTransformer):
    """Access-only rewrite of one plain callee (see the module docstring)."""

    def __init__(
        self,
        filename: str,
        class_name: "str | None",
        table: Any,
        global_names: "frozenset[str]" = frozenset(),
        qualname: str = "",
    ):
        self.filename = filename
        # Qualified name of the def being rewritten (diagnostics name the writer).
        self._qualname_stack: "list[str]" = [qualname]
        self._class_stack: "list[str | None]" = [class_name]
        self._first_param_stack: "list[str | None]" = [None]
        self._table_stack: "list[Any]" = [table]
        self._free_stack: "list[frozenset[str]]" = [_table_free_names(table)]
        self._nonlocal_stack: "list[frozenset[str]]" = [_table_nonlocal_names(table)]
        self._cells_stack: "list[set[str]]" = [set()]
        # Innermost scope kind: annotations are evaluated in a class body only.
        self._scope_kinds: "list[str]" = ["function"]
        # Module-global names bound in the callee's ``__globals__`` at rewrite
        # time: their reads route through the global read hook.
        self._global_names = global_names
        # Lambda bodies have no statement position for the runtime alias, so
        # inside one the hooks resolve the runtime module by import expression.
        self._lambda_depth = 0
        # Attribute-protocol dunder bodies being visited: their reflection
        # calls are emitted as direct routed stores / raw reads.
        self._protocol_depth = 0
        self._counter = 0
        # Comprehension iterables being visited: a synthesized ``:=`` is a
        # syntax error there, so the and/or/chain expansions stay native.
        self._comp_iter_depth = 0

    # -- helpers

    @property
    def _class_name(self) -> "str | None":
        return self._class_stack[-1]

    def _tmp(self) -> str:
        self._counter += 1
        return f"_pyir_cal_t{self._counter}"

    def _rt(self, name: str, at: "_ast.AST") -> "_ast.expr":
        if self._lambda_depth > 0:
            module: "_ast.expr" = _ast.Call(
                func=_ast.Name(id="__import__", ctx=_ast.Load()),
                args=[_ast.Constant(value=_RT_MODULE)],
                keywords=[
                    _ast.keyword(
                        arg="fromlist",
                        value=_ast.Tuple(
                            elts=[_ast.Constant(value="_")], ctx=_ast.Load()
                        ),
                    )
                ],
            )
        else:
            module = _ast.Name(id=_RT, ctx=_ast.Load())
        return _ast.copy_location(
            _ast.Attribute(value=module, attr=name, ctx=_ast.Load()), at
        )

    @staticmethod
    def _import_stmt() -> "_ast.stmt":
        return _ast.Import(names=[_ast.alias(name=_RT_MODULE, asname=_RT)])

    def _call(self, name: str, args: "list[_ast.expr]", at: "_ast.AST") -> "_ast.Call":
        return _ast.copy_location(
            _ast.Call(func=self._rt(name, at), args=args, keywords=[]), at
        )

    def _pos(self, node: "_ast.AST") -> "list[_ast.expr]":
        return [
            _ast.Constant(value=self.filename),
            _ast.Constant(value=getattr(node, "lineno", 0)),
        ]

    @staticmethod
    def _pure_chain(node: "_ast.expr") -> "tuple[str, ...] | None":
        parts: "list[str]" = []
        while isinstance(node, _ast.Attribute):
            parts.append(node.attr)
            node = node.value
        if isinstance(node, _ast.Name):
            parts.append(node.id)
            return tuple(reversed(parts))
        return None

    @staticmethod
    def _skippable_subscript(node: "_ast.Subscript") -> bool:
        return isinstance(node.slice, (_ast.Slice, _ast.Tuple))

    def _hoist(
        self, expr: "_ast.expr", at: "_ast.AST", pre: "list[_ast.stmt]"
    ) -> "_ast.expr":
        """Evaluate *expr* once into a temp (appended to *pre*) unless trivial."""
        if _is_simple(expr):
            return expr
        name = self._tmp()
        pre.append(
            _ast.copy_location(
                _ast.Assign(targets=[_ast.Name(id=name, ctx=_ast.Store())], value=expr),
                at,
            )
        )
        return _ast.Name(id=name, ctx=_ast.Load())

    def _cell(self, name: str, at: "_ast.AST") -> "_ast.expr":
        self._cells_stack[-1].add(name)
        return _ast.copy_location(
            _ast.Name(id=_CELL_PREFIX + name + "__", ctx=_ast.Load()), at
        )

    def _is_free(self, name: str) -> bool:
        return name in self._free_stack[-1]

    def _is_nonlocal(self, name: str) -> bool:
        return name in self._nonlocal_stack[-1]

    def _is_module_global(self, name: str) -> bool:
        if name not in self._global_names:
            return False
        table = self._table_stack[-1]
        if table is None:
            return False
        try:
            sym = table.lookup(name)
        except KeyError:
            return False
        return sym.is_global() and not sym.is_local() and not sym.is_free()

    def entry_prologue(
        self, node: Any, class_name: "str | None", cellvars: "tuple[str, ...]"
    ) -> "list[_ast.stmt]":
        """Statements at a def's entry: the def's own closure cells are born
        for this activation; a ``__init__`` receiver is born for the region
        it is constructed in."""
        stmts: "list[_ast.stmt]" = []
        if cellvars:
            cells = [self._cell_of(name, node) for name in cellvars]
            stmts.append(
                _ast.copy_location(
                    _ast.Expr(value=self._call("_pyir_cal_born_cells", cells, node)),
                    node,
                )
            )
        if class_name is not None and getattr(node, "name", None) == "__init__":
            args = node.args
            first = None
            if args.posonlyargs:
                first = args.posonlyargs[0].arg
            elif args.args:
                first = args.args[0].arg
            if first is not None:
                stmts.append(
                    _ast.copy_location(
                        _ast.Expr(
                            value=self._call(
                                "_pyir_cal_init_receiver",
                                [_ast.Name(id=first, ctx=_ast.Load())],
                                node,
                            )
                        ),
                        node,
                    )
                )
        return [_ast.fix_missing_locations(st) for st in stmts]

    @staticmethod
    def _cell_of(name: str, at: "_ast.AST") -> "_ast.expr":
        lam = _ast.Lambda(
            args=_ast.arguments(
                posonlyargs=[], args=[], kwonlyargs=[], kw_defaults=[], defaults=[]
            ),
            body=_ast.Name(id=name, ctx=_ast.Load()),
        )
        return _ast.copy_location(
            _ast.Subscript(
                value=_ast.Attribute(value=lam, attr="__closure__", ctx=_ast.Load()),
                slice=_ast.Constant(value=0),
                ctx=_ast.Load(),
            ),
            at,
        )

    def cell_prologue(self, cells: "set[str]", at: "_ast.AST") -> "list[_ast.stmt]":
        """``__pyir_cell_x__ = (lambda: x).__closure__[0]`` per hooked cell: the
        lambda closes over the same cell the function does."""
        stmts: "list[_ast.stmt]" = []
        for name in sorted(cells):
            lam = _ast.Lambda(
                args=_ast.arguments(
                    posonlyargs=[], args=[], kwonlyargs=[], kw_defaults=[], defaults=[]
                ),
                body=_ast.Name(id=name, ctx=_ast.Load()),
            )
            value = _ast.Subscript(
                value=_ast.Attribute(value=lam, attr="__closure__", ctx=_ast.Load()),
                slice=_ast.Constant(value=0),
                ctx=_ast.Load(),
            )
            stmts.append(
                _ast.copy_location(
                    _ast.Assign(
                        targets=[
                            _ast.Name(id=_CELL_PREFIX + name + "__", ctx=_ast.Store())
                        ],
                        value=value,
                    ),
                    at,
                )
            )
        return [_ast.fix_missing_locations(s) for s in stmts]

    # -- scopes

    def _child_table(self, name: str, lineno: int) -> Any:
        parent = self._table_stack[-1]
        if parent is None:
            return None
        for child in parent.get_children():
            if child.get_lineno() == lineno and child.get_name() == name:
                return child
        return None

    def visit_ClassDef(self, node: "_ast.ClassDef") -> Any:
        node.decorator_list = [self._wrap_callee_expr(d) for d in node.decorator_list]
        wall = _ast.copy_location(
            _ast.Expr(
                value=self._call(
                    "_pyir_cal_class_def_wall", [_ast.Constant(value=node.name)], node
                )
            ),
            node,
        )
        node.bases = [
            self._call("_pyir_cal_class_arg", [self.visit(b)], b) for b in node.bases
        ]
        for kw in node.keywords:
            kw.value = self.visit(kw.value)
            if kw.arg == "metaclass":
                kw.value = self._call("_pyir_cal_class_arg", [kw.value], kw.value)
        table = self._child_table(node.name, node.lineno)
        self._class_stack.append(node.name)
        self._table_stack.append(table)
        self._free_stack.append(_table_free_names(table))
        self._nonlocal_stack.append(frozenset())
        self._cells_stack.append(set())
        self._scope_kinds.append("class")
        try:
            node.body = self._visit_body(node.body)
            cells = self._cells_stack[-1]
        finally:
            self._class_stack.pop()
            self._table_stack.pop()
            self._free_stack.pop()
            self._nonlocal_stack.pop()
            self._cells_stack.pop()
            self._scope_kinds.pop()
        if cells:
            node.body = self.cell_prologue(cells, node) + node.body
        return [_ast.fix_missing_locations(wall), node]

    def _visit_function(self, node: Any) -> Any:
        if hasattr(node, "decorator_list"):
            node.decorator_list = [
                self._wrap_callee_expr(d) for d in node.decorator_list
            ]
        args = node.args
        args.defaults = [self.visit(d) for d in args.defaults]
        args.kw_defaults = [
            self.visit(d) if d is not None else None for d in args.kw_defaults
        ]
        for a in args.posonlyargs + args.args + args.kwonlyargs:
            self.visit_arg(a)
        if args.vararg is not None:
            self.visit_arg(args.vararg)
        if args.kwarg is not None:
            self.visit_arg(args.kwarg)
        first = None
        if args.posonlyargs:
            first = args.posonlyargs[0].arg
        elif args.args:
            first = args.args[0].arg
        is_lambda = isinstance(node, _ast.Lambda)
        protocol = (
            not is_lambda
            and self._class_name is not None
            and node.name in _PROTOCOL_DUNDERS
        )
        table = self._child_table("lambda" if is_lambda else node.name, node.lineno)
        outer = self._qualname_stack[-1]
        self._qualname_stack.append(
            f"{outer}.<locals>.{'<lambda>' if is_lambda else node.name}"
            if outer
            else node.name
        )
        self._first_param_stack.append(first)
        self._table_stack.append(table)
        self._free_stack.append(
            _table_free_names(table) if not is_lambda else frozenset()
        )
        self._nonlocal_stack.append(
            _table_nonlocal_names(table) if not is_lambda else frozenset()
        )
        self._cells_stack.append(set())
        self._scope_kinds.append("function")
        if is_lambda:
            self._lambda_depth += 1
        if protocol:
            self._protocol_depth += 1
        try:
            if is_lambda:
                node.body = self.visit(node.body)
            else:
                node.body = self._visit_body(node.body)
                if protocol:
                    node.body = self._protocol_scope(node.name, node.body, node)
            cells = self._cells_stack[-1]
        finally:
            if is_lambda:
                self._lambda_depth -= 1
            if protocol:
                self._protocol_depth -= 1
            self._scope_kinds.pop()
            self._qualname_stack.pop()
            self._first_param_stack.pop()
            self._table_stack.pop()
            self._free_stack.pop()
            self._nonlocal_stack.pop()
            self._cells_stack.pop()
        if not is_lambda:
            # A nested def binds its own runtime alias: closing over the outer
            # one would add a cell and shift the function's ``__closure__``.
            own_cells = _table_cell_names(table)
            node.body = [
                self._import_stmt(),
                *self.entry_prologue(node, self._class_name, own_cells),
                *self.cell_prologue(cells, node),
                *node.body,
            ]
            _ast.fix_missing_locations(node)
        return node

    def visit_FunctionDef(self, node: "_ast.FunctionDef") -> Any:
        node.name = _pyir_mangle(node.name, self._class_name)
        result = self._visit_function(node)
        if self._scope_kinds[-1] != "function":
            return result
        # The def statement births its function object in the executing region.
        mark = _ast.copy_location(
            _ast.Expr(
                value=self._call(
                    "_pyir_cal_mark_born_def",
                    [_ast.Name(id=node.name, ctx=_ast.Load())],
                    node,
                )
            ),
            node,
        )
        return [*(result if isinstance(result, list) else [result]), mark]

    def visit_AsyncFunctionDef(self, node: "_ast.AsyncFunctionDef") -> Any:
        return self._visit_function(node)

    def visit_Lambda(self, node: "_ast.Lambda") -> Any:
        return self._visit_function(node)

    def _protocol_scope(
        self, name: str, body: "list[_ast.stmt]", at: "_ast.AST"
    ) -> "list[_ast.stmt]":
        receiver = self._first_param_stack[-1]
        if receiver is None:
            return body
        if name == "__getattr__":
            # ``__getattr__`` runs for MISSING names only: its reads of bound
            # attributes take the normal path and are choked like any other.
            out: "list[_ast.stmt]" = list(body)
        else:
            kind = "read" if name in _PROTOCOL_READ_DUNDERS else "write"
            params = [*at.args.posonlyargs, *at.args.args]  # type: ignore[attr-defined]
            scope_args: "list[_ast.expr]" = [
                _ast.Constant(value=kind),
                _ast.Name(id=receiver, ctx=_ast.Load()),
            ]
            if len(params) >= 2:
                # The requested attribute name: a dunder marks a probe.
                scope_args.append(_ast.Name(id=params[1].arg, ctx=_ast.Load()))
            item = _ast.withitem(
                context_expr=self._call("_pyir_cal_protocol", scope_args, at),
                optional_vars=None,
            )
            out = [_ast.copy_location(_ast.With(items=[item], body=body), at)]
        if name == "__getattr__":
            params = [*at.args.posonlyargs, *at.args.args]  # type: ignore[attr-defined]
            if len(params) >= 2:
                attr = _ast.Name(id=params[1].arg, ctx=_ast.Load())
                guard = _ast.If(
                    test=self._call("_pyir_cal_probe_name", [attr], at),
                    body=[
                        _ast.Raise(
                            exc=_ast.Call(
                                func=_ast.Name(id="AttributeError", ctx=_ast.Load()),
                                args=[_ast.Name(id=params[1].arg, ctx=_ast.Load())],
                                keywords=[],
                            ),
                            cause=None,
                        )
                    ],
                    orelse=[],
                )
                out.insert(0, _ast.copy_location(guard, at))
        return out

    def rewrite_root(self, node: Any) -> "list[_ast.stmt]":
        """Rewrite the located def/lambda in place; returns the cell prologue
        the caller places after the runtime import."""
        args = node.args
        first = None
        if args.posonlyargs:
            first = args.posonlyargs[0].arg
        elif args.args:
            first = args.args[0].arg
        self._first_param_stack[-1] = first
        if isinstance(node, _ast.Lambda):
            node.body = self.visit(node.body)
            return self.cell_prologue(self._cells_stack[-1], node)
        protocol = self._class_name is not None and node.name in _PROTOCOL_DUNDERS
        if protocol:
            self._protocol_depth += 1
        try:
            node.body = self._visit_body(node.body)
        finally:
            if protocol:
                self._protocol_depth -= 1
        if protocol:
            node.body = self._protocol_scope(node.name, node.body, node)
        return self.cell_prologue(self._cells_stack[-1], node)

    def _visit_body(self, body: "list[_ast.stmt]") -> "list[_ast.stmt]":
        out: "list[_ast.stmt]" = []
        for stmt in body:
            result = self.visit(stmt)
            if result is None:
                continue
            if isinstance(result, list):
                out.extend(result)
            else:
                out.append(result)
        return out

    # -- names

    def visit_Name(self, node: "_ast.Name") -> Any:
        node.id = _pyir_mangle(node.id, self._class_name)
        if not isinstance(node.ctx, _ast.Load):
            return node
        read: "_ast.expr" = node
        if self._is_free(node.id):
            read = self._call(
                "_pyir_cal_cell_read",
                [
                    self._cell(node.id, node),
                    _ast.Constant(value=node.id),
                    _ast.Constant(value=f"<closure>.{node.id}"),
                ],
                node,
            )
        elif self._is_module_global(node.id):
            read = self._call(
                "_pyir_cal_global_read", [node, _ast.Constant(value=node.id)], node
            )
        if node.id in _BUILTIN_REDIRECT_NAMES:
            # ``max`` / ``min`` / ``any`` / ``all`` take the traced body's
            # builtin redirect (a user binding of the name passes through).
            return self._call("_pyir_cal_redirect_builtin", [read], node)
        return read

    def visit_arg(self, node: "_ast.arg") -> Any:
        node.arg = _pyir_mangle(node.arg, self._class_name)
        node.annotation = None
        return node

    def visit_Global(self, node: "_ast.Global") -> Any:
        node.names = [_pyir_mangle(n, self._class_name) for n in node.names]
        return node

    def visit_Nonlocal(self, node: "_ast.Nonlocal") -> Any:
        node.names = [_pyir_mangle(n, self._class_name) for n in node.names]
        return node

    # -- reads

    def visit_Attribute(self, node: "_ast.Attribute") -> Any:
        label = _pyir_cal_label(node)
        node.attr = _pyir_mangle(node.attr, self._class_name)
        node.value = self.visit(node.value)
        if not isinstance(node.ctx, _ast.Load):
            return node
        return self._call(
            "_pyir_cal_getattr",
            [node.value, _ast.Constant(value=node.attr), _ast.Constant(value=label)],
            node,
        )

    def visit_Subscript(self, node: "_ast.Subscript") -> Any:
        label = _pyir_cal_label(node)
        if isinstance(node.ctx, _ast.Load) and _is_dunder_dict(node.value):
            recv = self.visit(_dunder_dict_owner(node.value))
            key = self.visit(node.slice)
            return self._call(
                "_pyir_cal_dict_read", [recv, key, _ast.Constant(value=label)], node
            )
        node.value = self.visit(node.value)
        node.slice = self.visit(node.slice)
        if isinstance(node.ctx, _ast.Load) and isinstance(node.slice, _ast.Slice):
            # A slice is a new object built by the read: trace-internal like
            # a container literal (its elements stay the source's); its
            # bounds pass the read choke's index wall first.
            return self._born(
                self._call(
                    "_pyir_cal_getitem",
                    [_ast.Constant(value=label), node.value, node.slice],
                    node,
                )
            )
        if not isinstance(node.ctx, _ast.Load) or self._skippable_subscript(node):
            return node
        return self._call(
            "_pyir_cal_getitem",
            [_ast.Constant(value=label), node.value, node.slice],
            node,
        )

    # -- births: literals, comprehensions, generator expressions

    def _born(self, node: "_ast.expr") -> "_ast.expr":
        return self._call("_pyir_cal_born", [node], node)

    def visit_List(self, node: "_ast.List") -> Any:
        self.generic_visit(node)
        return self._born(node) if isinstance(node.ctx, _ast.Load) else node

    def visit_Dict(self, node: "_ast.Dict") -> Any:
        self.generic_visit(node)
        return self._born(node)

    def visit_Set(self, node: "_ast.Set") -> Any:
        self.generic_visit(node)
        return self._born(node)

    def visit_ListComp(self, node: "_ast.ListComp") -> Any:
        self.generic_visit(node)
        return self._born(node)

    def visit_SetComp(self, node: "_ast.SetComp") -> Any:
        self.generic_visit(node)
        return self._born(node)

    def visit_DictComp(self, node: "_ast.DictComp") -> Any:
        self.generic_visit(node)
        return self._born(node)

    def visit_GeneratorExp(self, node: "_ast.GeneratorExp") -> Any:
        self.generic_visit(node)
        return self._born(node)

    # -- iteration and context managers

    def _split_target(
        self, target: "_ast.expr", at: "_ast.stmt"
    ) -> "tuple[_ast.expr, list[_ast.stmt]]":
        """A binding target with attribute / subscript / nonlocal elements:
        bind temporaries, then store through the chokes."""
        pending: "list[tuple[str, _ast.expr]]" = []

        def rebuild(node: "_ast.expr") -> "_ast.expr":
            if isinstance(node, (_ast.Tuple, _ast.List)):
                node.elts = [rebuild(e) for e in node.elts]
                return node
            if isinstance(node, _ast.Starred):
                node.value = rebuild(node.value)
                return node
            if isinstance(node, (_ast.Attribute, _ast.Subscript)) or (
                isinstance(node, _ast.Name) and self._is_nonlocal(node.id)
            ):
                name = self._tmp()
                pending.append((name, node))
                return _ast.copy_location(_ast.Name(id=name, ctx=_ast.Store()), node)
            return self.visit(node)

        new_target = rebuild(target)
        stores: "list[_ast.stmt]" = []
        for name, node in pending:
            stores.extend(
                self._store(node, _ast.Name(id=name, ctx=_ast.Load()), at, rmw=False)
            )
        return new_target, [_ast.fix_missing_locations(s) for s in stores]

    def visit_For(self, node: "_ast.For") -> Any:
        stores: "list[_ast.stmt]" = []
        if self._needs_split(node.target):
            node.target, stores = self._split_target(node.target, node)
        else:
            node.target = self.visit(node.target)
        node.iter = self._call("_pyir_cal_iter", [self.visit(node.iter)], node.iter)
        node.body = stores + self._visit_body(node.body)
        node.orelse = self._visit_body(node.orelse)
        return node

    def visit_With(self, node: "_ast.With") -> Any:
        stores: "list[_ast.stmt]" = []
        for item in node.items:
            item.context_expr = self.visit(item.context_expr)
            if item.optional_vars is not None:
                if self._needs_split(item.optional_vars):
                    item.optional_vars, more = self._split_target(
                        item.optional_vars, node
                    )
                    stores.extend(more)
                else:
                    item.optional_vars = self.visit(item.optional_vars)
        node.body = stores + self._visit_body(node.body)
        return node

    def _truth(self, test: "_ast.expr", at: "_ast.AST") -> "_ast.expr":
        label = _pyir_cal_label(test)
        return self._call(
            "_pyir_cal_truth",
            [self.visit(test), _ast.Constant(value=label), *self._pos(at)],
            at,
        )

    def visit_BinOp(self, node: "_ast.BinOp") -> Any:
        names = _BINOP_NAMES.get(type(node.op))
        left = self.visit(node.left)
        right = self.visit(node.right)
        if names is None:
            node.left, node.right = left, right
            return node
        return self._call(
            "_pyir_cal_binop",
            [_ast.Constant(value=names[0]), _ast.Constant(value=names[1]), left, right],
            node,
        )

    @staticmethod
    def _keys_view_owner(comparator: "_ast.expr") -> "_ast.expr | None":
        """``d.keys()`` spelled as a membership comparator: the owning dict node
        (the view has no spelling of its own, so the choke names the dict)."""
        return (
            comparator.func.value
            if isinstance(comparator, _ast.Call)
            and isinstance(comparator.func, _ast.Attribute)
            and comparator.func.attr == "keys"
            and not comparator.args
            and not comparator.keywords
            else None
        )

    def _compare_leg(
        self,
        op: "_ast.cmpop",
        left: "_ast.expr",
        right: "_ast.expr",
        at: "_ast.AST",
        keys_label: "str | None" = None,
        keys_of: bool = False,
    ) -> "_ast.expr":
        """One ``left <cmp> right`` leg over rewritten operands (``is`` /
        ``is not`` stay Python's).  *keys_label* is the dict's spelling when
        the comparator was ``<dict>.keys()``; with *keys_of* set, *right* is
        the rewritten dict itself and the choke takes the view off it."""
        if isinstance(op, (_ast.In, _ast.NotIn)):
            # The membership choke records the gate-once evidence the ``if`` choke
            # consumes (a plain ``if`` never reaches the traced body's compare
            # choke).
            args = [left, right, _ast.Constant(value=isinstance(op, _ast.NotIn))]
            if keys_label is not None:
                args.append(_ast.Constant(value=keys_label))
                if keys_of:
                    args.append(_ast.Constant(value=True))
            return self._call("_pyir_cal_membership", args, at)
        names = _COMPARE_NAMES.get(type(op))
        if names is None:
            return _ast.copy_location(
                _ast.Compare(left=left, ops=[op], comparators=[right]), at
            )
        return self._call(
            "_pyir_cal_compare",
            [_ast.Constant(value=names[0]), _ast.Constant(value=names[1]), left, right],
            at,
        )

    def visit_Compare(self, node: "_ast.Compare") -> Any:
        # ``k in d.keys()``: the view has no spelling of its own, so the
        # membership choke is handed the DICT (evaluated once, as the view's
        # receiver) with its spelling, and takes the view off it.  A middle
        # comparator of a chain stays whole: its walrus temp is the next leg's
        # left operand.
        last = len(node.ops) - 1
        owners = [self._keys_view_owner(c) for c in node.comparators]
        labels: "list[str | None]" = [
            None if o is None else _pyir_cal_label(o) for o in owners
        ]
        keys_of = [
            i == last and o is not None and isinstance(op, (_ast.In, _ast.NotIn))
            for i, (op, o) in enumerate(zip(node.ops, owners))
        ]
        left = self.visit(node.left)
        rights = [
            self.visit(c if o is None or not k else o)
            for c, o, k in zip(node.comparators, owners, keys_of)
        ]
        if len(node.ops) == 1:
            return self._compare_leg(
                node.ops[0], left, rights[0], node, labels[0], keys_of[0]
            )
        if not self._walrus_ok():
            node.left, node.comparators = left, rights
            return node
        # ``a < b < c`` -> ``(a < (t := b)) and (t < c)``: every leg keeps its
        # choke, a middle comparator evaluates once, the legs join like ``and``.
        legs: "list[_ast.expr]" = []
        last = len(rights) - 1
        for i, (op, right) in enumerate(zip(node.ops, rights)):
            if i < last:
                tmp = self._tmp()
                right = _ast.copy_location(
                    _ast.NamedExpr(
                        target=_ast.Name(id=tmp, ctx=_ast.Store()), value=right
                    ),
                    node,
                )
            legs.append(
                self._compare_leg(op, left, right, node, labels[i], keys_of[i])
            )
            if i < last:
                left = _ast.Name(id=tmp, ctx=_ast.Load())
        return self._join_boolop(_ast.And, legs, node)

    _BOOLOP_ARMS: "dict[type, tuple[str, bool]]" = {
        _ast.And: ("_pyir_cal_and_", False),
        _ast.Or: ("_pyir_cal_or_", True),
    }

    def _walrus_ok(self) -> bool:
        """A synthesized ``:=`` temp is legal here: not a comprehension's
        iterable, not a class body (where it would bind a class attribute)."""
        return self._comp_iter_depth == 0 and self._scope_kinds[-1] != "class"

    def _join_boolop(
        self, op: type, values: "list[_ast.expr]", at: "_ast.AST"
    ) -> "_ast.expr":
        """``v0 and v1 and ...`` (or ``or``) over rewritten operands in the
        traced body's evaluate-once form, keeping Python's short-circuit:
        ``t if _pyir_cal_bool_sc((t := v0), sc) else _pyir_cal_and_(t, v1)``."""
        helper, short_circuit_value = self._BOOLOP_ARMS[op]
        lhs = values[0]
        for rhs in values[1:]:
            tmp = self._tmp()
            walrus = _ast.NamedExpr(
                target=_ast.Name(id=tmp, ctx=_ast.Store()), value=lhs
            )
            test = self._call(
                "_pyir_cal_bool_sc",
                [walrus, _ast.Constant(value=short_circuit_value)],
                at,
            )
            lhs = _ast.IfExp(
                test=test,
                body=_ast.Name(id=tmp, ctx=_ast.Load()),
                orelse=self._call(
                    helper, [_ast.Name(id=tmp, ctx=_ast.Load()), rhs], at
                ),
            )
        return _ast.fix_missing_locations(_ast.copy_location(lhs, at))

    def visit_BoolOp(self, node: "_ast.BoolOp") -> Any:
        node.values = [self.visit(v) for v in node.values]
        if not self._walrus_ok():
            return node
        return self._join_boolop(type(node.op), node.values, node)

    def visit_UnaryOp(self, node: "_ast.UnaryOp") -> Any:
        node.operand = self.visit(node.operand)
        if isinstance(node.op, _ast.Not):
            return self._call("_pyir_cal_not_", [node.operand], node)
        return node

    def visit_If(self, node: "_ast.If") -> Any:
        # ``if T: A else: B`` -> ``t = enter(T)`` then ``try: if t: A else: B
        # finally: exit()``: the arm's first-defs collect on the fold stack while a
        # provable membership gate is open.
        test = self._truth(node.test, node)
        node.body = self._visit_body(node.body)
        node.orelse = self._visit_body(node.orelse)
        name = self._tmp()
        node.test = _ast.copy_location(_ast.Name(id=name, ctx=_ast.Load()), node)
        enter = _ast.copy_location(
            _ast.Assign(
                targets=[_ast.Name(id=name, ctx=_ast.Store())],
                value=self._call("_pyir_cal_fold_if_enter", [test], node),
            ),
            node,
        )
        close = _ast.copy_location(
            _ast.Try(
                body=[node],
                handlers=[],
                orelse=[],
                finalbody=[
                    _ast.copy_location(
                        _ast.Expr(value=self._call("_pyir_cal_fold_if_exit", [], node)),
                        node,
                    )
                ],
            ),
            node,
        )
        return [enter, close]

    def visit_While(self, node: "_ast.While") -> Any:
        node.test = self._truth(node.test, node)
        node.body = self._visit_body(node.body)
        node.orelse = self._visit_body(node.orelse)
        return node

    def visit_Match(self, node: "_ast.Match") -> Any:
        # A pattern admits only literals and dotted names, never a call: its
        # names are mangled in place and read natively against the observed subject.
        node.subject = self.visit(node.subject)
        for case in node.cases:
            for sub in _ast.walk(case.pattern):
                if isinstance(sub, _ast.Name):
                    sub.id = _pyir_mangle(sub.id, self._class_name)
                elif isinstance(sub, _ast.Attribute):
                    sub.attr = _pyir_mangle(sub.attr, self._class_name)
            if case.guard is not None:
                case.guard = self.visit(case.guard)
            case.body = self._visit_body(case.body)
        return node

    def visit_IfExp(self, node: "_ast.IfExp") -> Any:
        node.test = self._truth(node.test, node)
        node.body = self.visit(node.body)
        node.orelse = self.visit(node.orelse)
        return node

    def visit_Assert(self, node: "_ast.Assert") -> Any:
        # A literal test (``assert False, "unreachable"``) needs no choke.
        if not isinstance(node.test, _ast.Constant):
            label = _pyir_cal_label(node.test)
            node.test = self._call(
                "_pyir_cal_assert",
                [self.visit(node.test), _ast.Constant(value=label), *self._pos(node)],
                node,
            )
        if node.msg is not None:
            node.msg = self.visit(node.msg)
        return node

    def visit_comprehension(self, node: "_ast.comprehension") -> Any:
        node.target = self.visit(node.target)
        self._comp_iter_depth += 1
        try:
            iterable = self.visit(node.iter)
        finally:
            self._comp_iter_depth -= 1
        node.iter = self._call("_pyir_cal_iter", [iterable], node.iter)
        node.ifs = [self.visit(i) for i in node.ifs]
        return node

    @staticmethod
    def _is_text_call(node: "_ast.Call") -> bool:
        func = node.func
        if isinstance(func, _ast.Name):
            return (
                func.id in ("str", "repr", "format")
                and len(node.args) >= 1
                and not node.keywords
                and not isinstance(node.args[0], _ast.Starred)
            )
        return (
            isinstance(func, _ast.Attribute)
            and func.attr == "format"
            and isinstance(func.value, _ast.Constant)
            and isinstance(func.value.value, str)
        )

    # -- calls

    def _wrap_callee_expr(self, func: "_ast.expr") -> "_ast.expr":
        func = self.visit(func)
        return _ast.copy_location(
            _ast.Call(
                func=self._rt("_pyir_call_boundary_", func),
                args=[func],
                keywords=[_ast.keyword(arg="births_seen", value=_ast.Constant(True))],
            ),
            func,
        )

    def visit_Call(self, node: "_ast.Call") -> Any:
        callee = node.func
        if (
            isinstance(callee, _ast.Attribute)
            and callee.attr == "get"
            and _is_dunder_dict(callee.value)
            and 1 <= len(node.args) <= 2
            and not node.keywords
        ):
            recv = self.visit(_dunder_dict_owner(callee.value))
            return self._call(
                "_pyir_cal_dict_get", [recv, *[self.visit(a) for a in node.args]], node
            )
        text_call = self._is_text_call(node)
        node.args = [self.visit(a) for a in node.args]
        node.keywords = [self.visit(k) for k in node.keywords]
        func = node.func
        if self._protocol_depth > 0:
            routed = self._protocol_call(node)
            if routed is not None:
                return routed
        if text_call:
            # Text builtins run raw, as in the traced body.
            return node
        if isinstance(func, _ast.Name) and not node.keywords:
            if func.id == "setattr" and len(node.args) == 3:
                return self._call("_pyir_cal_reflect_setattr", node.args, node)
            if func.id == "delattr" and len(node.args) == 2:
                return self._call("_pyir_cal_reflect_delattr", node.args, node)
            if func.id == "type" and len(node.args) == 1 and self._protocol_depth == 0:
                return self._call("_pyir_cal_type", node.args, node)
            if (
                func.id == "bool"
                and len(node.args) == 1
                and not isinstance(node.args[0], _ast.Starred)
            ):
                # Only this call shape has a ``bool_cast`` spelling (the entry
                # preprocessor's rule); every other shape stays a plain call.
                return _ast.copy_location(
                    _ast.Call(
                        func=self._call(
                            "_pyir_cal_redirect_builtin", [self.visit(func)], node
                        ),
                        args=[node.args[0]],
                        keywords=[],
                    ),
                    node,
                )
        if isinstance(func, _ast.Name) and func.id in _BARE_BUILTIN_SKIP:
            if func.id == "super" and not node.args and not node.keywords:
                first = self._first_param_stack[-1]
                if first is not None:
                    node.args = [
                        _ast.Name(id="__class__", ctx=_ast.Load()),
                        _ast.Name(id=first, ctx=_ast.Load()),
                    ]
                return _ast.fix_missing_locations(node)
            if func.id == "vars" and node.args:
                if (
                    len(node.args) == 1
                    and not node.keywords
                    and not isinstance(node.args[0], _ast.Starred)
                ):
                    return self._call("_pyir_cal_vars", [node.args[0]], node)
                node.func = self._wrap_callee_expr(func)
                return node
            return node
        node.func = self._wrap_callee_expr(func)
        if isinstance(func, _ast.Attribute) and func.attr == "__new__" and node.args:
            return self._call("_pyir_cal_new_result", [node], node)
        return node

    _PROTOCOL_RAW_BUILTINS = frozenset(
        {
            "getattr",
            "hasattr",
            "vars",
            "isinstance",
            "issubclass",
            "len",
            "id",
            "type",
            "repr",
            "str",
            "object",
            "super",
            "dict",
            "list",
            "set",
            "tuple",
            "iter",
            "next",
            "print",
        }
    )

    def _protocol_call(self, node: "_ast.Call") -> "_ast.expr | None":
        """Inside an attribute-protocol dunder body: the reflection calls on
        ``object``/``type``/``super()`` and the bare builtins bypass the
        dispatcher; a store spelling routes to the reflect-store choke."""
        func = node.func
        label = _ast.Constant(value=_pyir_cal_label(node))
        if isinstance(func, _ast.Name):
            if func.id == "setattr":
                return self._call("_pyir_cal_reflect_setattr", node.args, node)
            if func.id == "delattr":
                return self._call("_pyir_cal_reflect_delattr", node.args, node)
            if func.id in self._PROTOCOL_RAW_BUILTINS:
                return _ast.fix_missing_locations(node)
            return None
        if not isinstance(func, _ast.Attribute):
            return None
        base = func.value
        is_object = isinstance(base, _ast.Name) and base.id == "object"
        is_type = isinstance(base, _ast.Name) and base.id == "type"
        is_super = (
            isinstance(base, _ast.Call)
            and isinstance(base.func, _ast.Name)
            and base.func.id == "super"
        )
        if not (is_object or is_type or is_super):
            return None
        if is_super:
            base = self.visit(base)  # zero-argument form gets its __class__ / self
        if func.attr == "__getattribute__" and not node.keywords:
            if is_object and len(node.args) == 2:
                return self._call("_pyir_cal_object_getattr", [*node.args, label], node)
            if is_super and len(node.args) == 1:
                return self._call(
                    "_pyir_cal_super_getattr", [base, *node.args, label], node
                )
        if func.attr in ("__getattribute__", "__getattr__"):
            node.func = _ast.copy_location(
                _ast.Attribute(value=base, attr=func.attr, ctx=_ast.Load()), func
            )
            return _ast.fix_missing_locations(node)
        if func.attr == "__setattr__":
            if is_super:
                return self._call("_pyir_cal_super_setattr", [base, *node.args], node)
            if is_type:
                return self._call("_pyir_cal_class_store", node.args, node)
            return self._call("_pyir_cal_object_setattr", node.args, node)
        if func.attr == "__delattr__":
            if is_super:
                return self._call("_pyir_cal_super_delattr", [base, *node.args], node)
            if is_type:
                return _ast.fix_missing_locations(node)  # a class attribute: raw
            return self._call("_pyir_cal_object_delattr", node.args, node)
        return None

    # -- stores

    def _store(
        self, target: "_ast.expr", value: "_ast.expr", at: "_ast.stmt", rmw: bool
    ) -> "list[_ast.stmt]":
        """Choked store of an already-evaluated *value* (a temp or trivial
        expression) into an attribute / subscript / nonlocal target; the
        target's receiver and key evaluate after the value, as in Python."""
        pre: "list[_ast.stmt]" = []
        if isinstance(target, _ast.Name) and self._is_module_global(target.id):
            label = _pyir_cal_label(target)
            if not _is_simple(value):
                value = self._hoist(value, at, pre)
            call = self._call(
                "_pyir_cal_global_store",
                [
                    _ast.Call(
                        func=_ast.Name(id="globals", ctx=_ast.Load()),
                        args=[],
                        keywords=[],
                    ),
                    _ast.Constant(value=target.id),
                    value,
                    _ast.Constant(value=label),
                    *self._pos(at),
                    _ast.Constant(value=self._qualname_stack[-1]),
                ],
                at,
            )
            pre.append(_ast.copy_location(_ast.Expr(value=call), at))
            return pre
        if isinstance(target, _ast.Attribute):
            attr = _pyir_mangle(target.attr, self._class_name)
            label = _pyir_cal_label(target)
            recv = self.visit(target.value)
            if not _is_simple(value):
                value = self._hoist(value, at, pre)
            call = self._call(
                "_pyir_cal_setattr",
                [
                    recv,
                    _ast.Constant(value=attr),
                    value,
                    _ast.Constant(value=label),
                    *self._pos(at),
                    _ast.Constant(value=rmw),
                ],
                at,
            )
            pre.append(_ast.copy_location(_ast.Expr(value=call), at))
            return pre
        if isinstance(target, _ast.Subscript) and not self._skippable_subscript(target):
            label = _pyir_cal_label(target)
            if _is_dunder_dict(target.value):
                recv = self.visit(_dunder_dict_owner(target.value))
                key = self.visit(target.slice)
                if not _is_simple(value):
                    value = self._hoist(value, at, pre)
                call = self._call(
                    "_pyir_cal_dict_store",
                    [recv, key, value, _ast.Constant(value=label), *self._pos(at)],
                    at,
                )
                pre.append(_ast.copy_location(_ast.Expr(value=call), at))
                return pre
            recv = self.visit(target.value)
            key = self.visit(target.slice)
            if not _is_simple(value):
                value = self._hoist(value, at, pre)
            call = self._call(
                "_pyir_cal_setitem",
                [recv, key, value, _ast.Constant(value=label), *self._pos(at)],
                at,
            )
            pre.append(_ast.copy_location(_ast.Expr(value=call), at))
            return pre
        if isinstance(target, _ast.Name) and self._is_nonlocal(target.id):
            name = _pyir_mangle(target.id, self._class_name)
            call = self._call(
                "_pyir_cal_cell_store",
                [
                    self._cell(name, at),
                    _ast.Constant(value=name),
                    value,
                    _ast.Constant(value=f"<closure>.{name}"),
                    *self._pos(at),
                ],
                at,
            )
            return [_ast.copy_location(_ast.Expr(value=call), at)]
        target = self.visit(target)
        return [_ast.copy_location(_ast.Assign(targets=[target], value=value), at)]

    def _needs_split(self, target: "_ast.expr") -> bool:
        for sub in _ast.walk(target):
            if isinstance(sub, (_ast.Attribute, _ast.Subscript)) and isinstance(
                sub.ctx, _ast.Store
            ):
                return True
            if (
                isinstance(sub, _ast.Name)
                and isinstance(sub.ctx, _ast.Store)
                and (self._is_nonlocal(sub.id) or self._is_module_global(sub.id))
            ):
                return True
        return False

    def _is_rmw(self, target: "_ast.expr", value: "_ast.expr") -> bool:
        chain = self._pure_chain(target)
        if chain is None:
            return False
        for sub in _ast.walk(value):
            if isinstance(sub, _ast.Attribute) and self._pure_chain(sub) == chain:
                return True
        return False

    def visit_Assign(self, node: "_ast.Assign") -> Any:
        if not any(self._needs_split(t) for t in node.targets):
            node.value = self.visit(node.value)
            if any(isinstance(t, _ast.Name) for t in node.targets) and isinstance(
                node.value, (_ast.Call, _ast.Attribute, _ast.Subscript, _ast.Name)
            ):
                if len(node.targets) == 1 and isinstance(node.targets[0], _ast.Name):
                    node.value = self._call(
                        "_pyir_cal_bind",
                        [node.value, _ast.Constant(value=node.targets[0].id)],
                        node.value,
                    )
                else:
                    node.value = self._call("_pyir_cal_hold", [node.value], node.value)
            node.targets = [self.visit(t) for t in node.targets]
            return node
        if len(node.targets) == 1 and isinstance(
            node.targets[0], (_ast.Attribute, _ast.Subscript, _ast.Name)
        ):
            target: Any = node.targets[0]
            rmw = isinstance(target, _ast.Attribute) and self._is_rmw(
                target, node.value
            )
            value = self.visit(node.value)
            return [
                _ast.fix_missing_locations(s)
                for s in self._store(target, value, node, rmw)
            ]
        value = self.visit(node.value)
        tmp = self._tmp()
        stmts: "list[_ast.stmt]" = [
            _ast.copy_location(
                _ast.Assign(targets=[_ast.Name(id=tmp, ctx=_ast.Store())], value=value),
                node,
            )
        ]
        for target in node.targets:
            load = _ast.Name(id=tmp, ctx=_ast.Load())
            if isinstance(target, (_ast.Attribute, _ast.Subscript)) or (
                isinstance(target, _ast.Name)
                and (self._is_nonlocal(target.id) or self._is_module_global(target.id))
            ):
                stmts.extend(self._store(target, load, node, rmw=False))
            elif self._needs_split(target):
                new_target, stores = self._split_target(target, node)
                stmts.append(
                    _ast.copy_location(
                        _ast.Assign(targets=[new_target], value=load), node
                    )
                )
                stmts.extend(stores)
            else:
                stmts.append(
                    _ast.copy_location(
                        _ast.Assign(targets=[self.visit(target)], value=load), node
                    )
                )
        return [_ast.fix_missing_locations(s) for s in stmts]

    def visit_AnnAssign(self, node: "_ast.AnnAssign") -> Any:
        if node.value is None or not self._needs_split(node.target):
            if node.value is not None:
                node.value = self.visit(node.value)
            node.target = self.visit(node.target)
            if self._scope_kinds[-1] == "class":
                # Evaluated at class creation into ``__annotations__``.
                node.annotation = self.visit(node.annotation)
            else:
                node.annotation = _ast.Constant(value=None)
            return node
        rmw = isinstance(node.target, _ast.Attribute) and self._is_rmw(
            node.target, node.value
        )
        value = self.visit(node.value)
        return [
            _ast.fix_missing_locations(s)
            for s in self._store(node.target, value, node, rmw)
        ]

    def visit_AugAssign(self, node: "_ast.AugAssign") -> Any:
        op = _AUG_OPS.get(type(node.op))
        target = node.target
        if op is None or not self._needs_split(target):
            node.value = self.visit(node.value)
            node.target = self.visit(node.target)
            if op == "or" and isinstance(node.target, _ast.Name):
                # ``d |= other`` on a local name: the in-place protocol funnel
                # (value-identical), whose dict arm walls the union's keys
                # ahead of the native ``__ior__``.
                value = self._call(
                    "_pyir_inplace_binop",
                    [
                        _ast.Constant(value=op),
                        _ast.Name(id=node.target.id, ctx=_ast.Load()),
                        node.value,
                        _ast.Constant(value=node.target.id),
                    ],
                    node,
                )
                return _ast.fix_missing_locations(
                    _ast.copy_location(
                        _ast.Assign(targets=[node.target], value=value), node
                    )
                )
            return node
        if isinstance(target, _ast.Subscript) and self._skippable_subscript(target):
            node.value = self.visit(node.value)
            node.target = self.visit(target)
            return node
        pre: "list[_ast.stmt]" = []
        label = _pyir_cal_label(target)
        if isinstance(target, _ast.Name) and self._is_module_global(target.id):
            old = self._call(
                "_pyir_cal_global_read",
                [
                    _ast.Name(id=target.id, ctx=_ast.Load()),
                    _ast.Constant(value=target.id),
                ],
                target,
            )
            new = self._call(
                "_pyir_inplace_binop",
                [_ast.Constant(value=op), old, self.visit(node.value)],
                node,
            )
            return [
                _ast.fix_missing_locations(st)
                for st in self._store(target, new, node, rmw=False)
            ]
        if isinstance(target, _ast.Attribute):
            attr = _pyir_mangle(target.attr, self._class_name)
            recv = self._hoist(self.visit(target.value), node, pre)
            old = self._call(
                "_pyir_cal_getattr",
                [recv, _ast.Constant(value=attr), _ast.Constant(value=label)],
                target,
            )
            call = self._call(
                "_pyir_cal_iattr",
                [
                    recv,
                    _ast.Constant(value=attr),
                    _ast.Constant(value=op),
                    old,
                    self.visit(node.value),
                    _ast.Constant(value=label),
                    *self._pos(node),
                ],
                node,
            )
        elif isinstance(target, _ast.Subscript) and _is_dunder_dict(target.value):
            recv = self._hoist(self.visit(_dunder_dict_owner(target.value)), node, pre)
            key = self._hoist(self.visit(target.slice), node, pre)
            old = self._call(
                "_pyir_cal_dict_read", [recv, key, _ast.Constant(value=label)], target
            )
            new = self._call(
                "_pyir_inplace_binop",
                [_ast.Constant(value=op), old, self.visit(node.value)],
                node,
            )
            call = self._call(
                "_pyir_cal_dict_store",
                [recv, key, new, _ast.Constant(value=label), *self._pos(node)],
                node,
            )
        elif isinstance(target, _ast.Subscript):
            recv = self._hoist(self.visit(target.value), node, pre)
            key = self._hoist(self.visit(target.slice), node, pre)
            old = self._call(
                "_pyir_cal_getitem_rmw", [_ast.Constant(value=label), recv, key], target
            )
            call = self._call(
                "_pyir_cal_iitem",
                [
                    recv,
                    key,
                    _ast.Constant(value=op),
                    old,
                    self.visit(node.value),
                    _ast.Constant(value=label),
                    *self._pos(node),
                ],
                node,
            )
        else:
            name = _pyir_mangle(target.id, self._class_name)  # type: ignore[attr-defined]
            call = self._call(
                "_pyir_cal_cell_iop",
                [
                    self._cell(name, node),
                    _ast.Constant(value=name),
                    _ast.Constant(value=op),
                    self.visit(node.value),
                    _ast.Constant(value=f"<closure>.{name}"),
                    *self._pos(node),
                ],
                node,
            )
        pre.append(_ast.copy_location(_ast.Expr(value=call), node))
        return [_ast.fix_missing_locations(s) for s in pre]

    def visit_Delete(self, node: "_ast.Delete") -> Any:
        stmts: "list[_ast.stmt]" = []
        for target in node.targets:
            label = _pyir_cal_label(target)
            if isinstance(target, _ast.Attribute):
                attr = _pyir_mangle(target.attr, self._class_name)
                call = self._call(
                    "_pyir_cal_delattr",
                    [
                        self.visit(target.value),
                        _ast.Constant(value=attr),
                        _ast.Constant(value=label),
                    ],
                    node,
                )
                stmts.append(_ast.copy_location(_ast.Expr(value=call), node))
            elif isinstance(target, _ast.Name) and self._is_free(target.id):
                name = _pyir_mangle(target.id, self._class_name)
                call = self._call(
                    "_pyir_cal_cell_del",
                    [
                        self._cell(name, target),
                        _ast.Constant(value=name),
                        _ast.Constant(value=label),
                    ],
                    node,
                )
                stmts.append(_ast.copy_location(_ast.Expr(value=call), node))
            elif isinstance(target, _ast.Subscript) and _is_dunder_dict(target.value):
                call = self._call(
                    "_pyir_cal_dict_del",
                    [
                        self.visit(_dunder_dict_owner(target.value)),
                        self.visit(target.slice),
                        _ast.Constant(value=label),
                    ],
                    node,
                )
                stmts.append(_ast.copy_location(_ast.Expr(value=call), node))
            elif isinstance(target, _ast.Subscript) and not self._skippable_subscript(
                target
            ):
                call = self._call(
                    "_pyir_cal_delitem",
                    [
                        self.visit(target.value),
                        self.visit(target.slice),
                        _ast.Constant(value=label),
                    ],
                    node,
                )
                stmts.append(_ast.copy_location(_ast.Expr(value=call), node))
            else:
                stmts.append(
                    _ast.copy_location(_ast.Delete(targets=[self.visit(target)]), node)
                )
        return [_ast.fix_missing_locations(s) for s in stmts]

    # -- exception handlers

    def visit_ExceptHandler(self, node: "_ast.ExceptHandler") -> Any:
        if node.type is not None:
            node.type = self.visit(node.type)
        if node.name is None:
            node.name = self._tmp()
        prologue = _ast.copy_location(
            _ast.Expr(
                value=self._call(
                    "_pyir_cal_reraise",
                    [_ast.Name(id=node.name, ctx=_ast.Load())],
                    node,
                )
            ),
            node,
        )
        node.body = [_ast.fix_missing_locations(prologue)] + self._visit_body(node.body)
        return node


# -- Locating and compiling ---------------------------------------------------


def _pyir_module_source(filename: str) -> "str | None":
    if not filename or filename.startswith("<"):
        return None
    lines = _linecache.getlines(filename)
    if not lines:
        return None
    return "".join(lines)


def _pyir_module_ast(filename: str) -> "_ast.Module | None":
    tree = _FILE_AST_CACHE.get(filename)
    if tree is not None:
        return tree
    source = _pyir_module_source(filename)
    if source is None:
        return None
    try:
        tree = _ast.parse(source, filename=filename)
    except SyntaxError:
        return None
    _FILE_AST_CACHE[filename] = tree
    return tree


def _pyir_module_symtable(filename: str) -> Any:
    table = _FILE_SYMTABLE_CACHE.get(filename, _MEMBER_MISS)
    if table is not _MEMBER_MISS:
        return table
    source = _pyir_module_source(filename)
    table = None
    if source is not None:
        try:
            table = _symtable.symtable(source, filename, "exec")
        except SyntaxError:
            table = None
    _FILE_SYMTABLE_CACHE[filename] = table
    return table


def _pyir_locate_def(code: Any) -> "tuple[Any, str | None, Any] | None":
    """The def/lambda node compiled into *code*, the private-name mangling
    class it is lexically inside of, and its symbol table."""
    tree = _pyir_module_ast(code.co_filename)
    if tree is None:
        return None
    first = code.co_firstlineno
    is_lambda = code.co_name == "<lambda>"
    parents: "dict[int, _ast.AST]" = {}
    candidates: "list[Any]" = []
    stack: "list[_ast.AST]" = [tree]
    while stack:
        node = stack.pop()
        for child in _ast.iter_child_nodes(node):
            parents[id(child)] = node
            stack.append(child)
        if is_lambda:
            if isinstance(node, _ast.Lambda) and node.lineno == first:
                candidates.append(node)
        elif isinstance(node, (_ast.FunctionDef, _ast.AsyncFunctionDef)):
            start = min([node.lineno] + [d.lineno for d in node.decorator_list])
            if node.name == code.co_name and start <= first <= node.lineno:
                candidates.append(node)
    if len(candidates) != 1:
        cols = (
            {
                pos[2]
                for pos in code.co_positions()
                if pos[0] == first and pos[2] is not None
            }
            if hasattr(code, "co_positions")
            else set()
        )
        narrowed = [c for c in candidates if c.col_offset in cols] if cols else []
        if len(narrowed) != 1:
            return None
        candidates = narrowed
    node = candidates[0]
    # The lexical chain of scopes from the module down to the node, for the
    # mangling class and the symbol table.
    chain: "list[_ast.AST]" = []
    parent = parents.get(id(node))
    while parent is not None:
        chain.append(parent)
        parent = parents.get(id(parent))
    chain.reverse()  # module first
    class_name = None
    for scope in reversed(chain):
        if isinstance(scope, _ast.ClassDef):
            class_name = scope.name
            break
    table = _pyir_module_symtable(code.co_filename)
    for scope in chain[1:] + [node]:
        if table is None:
            break
        if isinstance(scope, (_ast.FunctionDef, _ast.AsyncFunctionDef, _ast.ClassDef)):
            name = scope.name
        elif isinstance(scope, _ast.Lambda):
            name = "lambda"
        else:
            continue
        found = None
        for child in table.get_children():
            if child.get_lineno() == scope.lineno and child.get_name() == name:
                found = child
                break
        table = found
    return node, class_name, table


def _pyir_global_names(func: Any) -> "frozenset[str]":
    return frozenset(
        k for k in (getattr(func, "__globals__", None) or {}) if not k.startswith("__")
    )


def _pyir_compile_rewrite(func: Any) -> Any:
    """The rewritten code object for *func*, or None when its source is not
    reachable (generated code, C code, an ambiguous line)."""
    code = func.__code__
    located = _pyir_locate_def(code)
    if located is None:
        return None
    node, class_name, table = located
    node = _copy.deepcopy(node)
    args = node.args
    rewriter = _PyirCalleeAccessRewriter(
        code.co_filename,
        class_name,
        table,
        _pyir_global_names(func),
        getattr(func, "__qualname__", None) or code.co_name,
    )
    # The function object keeps its own decorators, defaults and annotations;
    # only the body's code is taken, so these evaluate as plain placeholders.
    args.defaults = [_ast.Constant(value=None) for _ in args.defaults]
    args.kw_defaults = [
        _ast.Constant(value=None) if d is not None else None for d in args.kw_defaults
    ]
    for a in args.posonlyargs + args.args + args.kwonlyargs:
        a.annotation = None
    if args.vararg is not None:
        args.vararg.annotation = None
    if args.kwarg is not None:
        args.kwarg.annotation = None
    import_stmt: "_ast.stmt" = _ast.Import(
        names=[_ast.alias(name=_RT_MODULE, asname=_RT)]
    )
    prologue = rewriter.rewrite_root(node)
    prologue = [
        *rewriter.entry_prologue(node, class_name, tuple(code.co_cellvars)),
        *prologue,
    ]
    if isinstance(node, _ast.Lambda):
        # A lambda has no statement position: compile it as a def whose code
        # object takes the lambda's name.
        inner_stmt: "_ast.stmt" = _ast.FunctionDef(
            name="_pyir_cal_lambda",
            args=args,
            body=[import_stmt, *prologue, _ast.Return(value=node.body)],
            decorator_list=[],
            returns=None,
        )
        inner_name = "_pyir_cal_lambda"
    else:
        node.decorator_list = []
        node.returns = None
        node.body = [import_stmt, *prologue, *node.body]
        # Compiled under a private name: the def's own name stays a global /
        # enclosing-scope reference inside its body (recursion, ``f.attr``), not a
        # closure over the wrapper's binding of the def.
        node.name = "_pyir_cal_def"
        inner_name = "_pyir_cal_def"
        inner_stmt = node
    wrapper_body: "list[_ast.stmt]" = [
        _ast.Assign(
            targets=[_ast.Name(id=n, ctx=_ast.Store())], value=_ast.Constant(value=None)
        )
        for n in code.co_freevars
    ]
    wrapper_body.append(inner_stmt)
    wrapper_body.append(_ast.Return(value=_ast.Name(id=inner_name, ctx=_ast.Load())))
    module = _ast.parse("def _pyir_cal_wrapper():\n    pass\n")
    wrapper = module.body[0]
    assert isinstance(wrapper, _ast.FunctionDef)
    wrapper.body = wrapper_body
    module = _ast.fix_missing_locations(module)
    for sub in _ast.walk(wrapper):
        if getattr(sub, "lineno", None) is None:
            sub.lineno = code.co_firstlineno  # type: ignore[attr-defined]
    compiled = compile(module, code.co_filename, "exec")
    namespace: "dict[str, Any]" = {"__builtins__": _builtins}
    exec(compiled, namespace)
    inner = namespace["_pyir_cal_wrapper"]()
    new_code = inner.__code__
    if tuple(new_code.co_freevars) != tuple(code.co_freevars):
        return None
    try:
        new_code = new_code.replace(co_name=code.co_name, co_qualname=code.co_qualname)
    except (AttributeError, ValueError):
        pass
    log().info(
        "[pyir callee] rewrote %s (%s:%d)",
        getattr(func, "__qualname__", code.co_name),
        code.co_filename,
        code.co_firstlineno,
    )
    return new_code


def _pyir_register_rewritten_code(code: Any) -> None:
    _REWRITTEN_CODES.add(code)
    for const in code.co_consts:
        if isinstance(const, _types.CodeType):
            _pyir_register_rewritten_code(const)


def _pyir_cal_code_is_user(code: Any) -> bool:
    """FILE fact: is *code* from user source (not the stdlib, a site package
    or the DSL distribution)?  Keyed by filename; a wrapper that copied a user
    ``__module__`` (``functools.wraps``) is classified by where its body lives."""
    filename = getattr(code, "co_filename", "") or ""
    verdict = _FILE_USER_VERDICT.get(filename)
    if verdict is not None:
        return verdict
    verdict = True
    if not filename or filename.startswith("<"):
        verdict = False
    else:
        real = _os.path.realpath(filename)
        roots = [
            _sysconfig.get_paths().get(k)
            for k in ("stdlib", "platstdlib", "purelib", "platlib")
        ]
        for root in roots:
            if root and (
                filename.startswith(root + _os.sep)
                or real.startswith(_os.path.realpath(root) + _os.sep)
            ):
                verdict = False
                break
        if verdict and ("site-packages" in filename or "dist-packages" in filename):
            verdict = False
        if verdict and any(
            filename.startswith(r) or real.startswith(r)
            for r in _PYIR_BOUNDARY_PKG_ROOTS
        ):
            verdict = False
    _FILE_USER_VERDICT[filename] = verdict
    return verdict


def _pyir_rewrite_function_in_place(func: Any) -> bool:
    """Swap *func*'s code for its observed rewrite for the open trace; False when
    its source is unreachable."""
    code = getattr(func, "__code__", None)
    if code is None or not isinstance(func, _types.FunctionType):
        return False
    if code in _REWRITTEN_CODES:
        return True
    if not _pyir_cal_code_is_user(code):
        return False
    if code in _REWRITE_CACHE:
        new_code = _REWRITE_CACHE[code]
    else:
        try:
            new_code = _pyir_compile_rewrite(func)
        except (SyntaxError, ValueError, TypeError, RecursionError) as exc:
            log().info(
                "[pyir callee] rewrite of %s not possible: %s",
                getattr(func, "__qualname__", func),
                exc,
            )
            new_code = None
        _REWRITE_CACHE[code] = new_code
        if new_code is not None:
            _pyir_register_rewritten_code(new_code)
            _ORIGINAL_CODES[new_code] = code
    if new_code is None:
        return False
    try:
        func.__code__ = new_code
    except (ValueError, TypeError, AttributeError):
        _REWRITE_CACHE[code] = None
        return False
    _SWAPPED_FUNCTIONS[id(func)] = (func, code)
    if not hasattr(func, "_original_code"):
        try:
            setattr(func, "_original_code", code)  # noqa: B010
        except (AttributeError, TypeError):
            pass
    return True


def _pyir_cal_trace_close() -> None:
    """Trace-close hook: host code keeps the original bodies and classes; a
    deletion still pending from a staged region refuses."""
    pending = list(_PENDING_DELETES.items())
    _PENDING_DELETES.clear()
    for func, code in list(_SWAPPED_FUNCTIONS.values()):
        try:
            func.__code__ = code
        except (ValueError, TypeError, AttributeError):
            pass
    _SWAPPED_FUNCTIONS.clear()
    for klass, name, original in reversed(_SWAPPED_CLASS_ATTRS):
        try:
            setattr(klass, name, original)
        except (AttributeError, TypeError):
            pass
    _SWAPPED_CLASS_ATTRS.clear()
    _INSTRUMENTED_CLASSES.clear()
    _REGION_BORN.clear()
    _DETACHED.clear()
    _HELD.clear()
    _HOMED.clear()
    _READ_LABELS.clear()
    _HOST_CONTAINERS.clear()
    _HOST_READS.clear()
    _HOST_SHAPE_WRITES.clear()
    _NONE_READS.clear()
    try:
        _pyir_cal_check_keyset_observations()
        _pyir_cal_check_meta_stores()
        _pyir_cal_check_truth_folds()
    finally:
        _BORN_BINDINGS.clear()
        _KEYSET_CHANGED.clear()
        _KEYSET_OBSERVED.clear()
        _META_STORES.clear()
        _TRUTH_FOLDS.clear()
    _ACTIVE_ACCESS.clear()
    _GEN_PROBES.clear()
    _PYIR_TRACE_ACTIVE_MEMO[0] = None
    if pending and _PYIR_PENDING_USER_DIAGNOSTIC[0] is None:  # the first cause is kept
        (_oid, attr), (holder_pin, _old, _path) = pending[0]
        _pyir_cal_refuse_pending_delete(holder_pin(), attr)


_PYIR_TRACE_CLOSE_HOOKS.append(_pyir_cal_trace_close)


# -- Classes -------------------------------------------------------------------


def _pyir_dataclass_init(cls: type, orig_init: Any) -> Any:
    """Observed replacement for a generated dataclass ``__init__`` (no source):
    the field binds it performs are known from the class's field table, so
    they run through the attribute-store choke in declaration order, then
    ``__post_init__`` runs through the dispatcher."""
    cached = _DATACLASS_INITS.get(cls)
    if cached is not None and cached.__wrapped__ is orig_init:  # type: ignore[attr-defined]
        return cached
    fields = list(getattr(cls, "__dataclass_fields__", {}).values())
    params = getattr(cls, "__dataclass_params__", None)
    frozen = bool(getattr(params, "frozen", False))
    sig = _inspect.signature(orig_init)
    filename = getattr(orig_init.__code__, "co_filename", "<dataclass>")
    lineno = getattr(orig_init.__code__, "co_firstlineno", 0)
    init_vars = [
        f for f in fields if f._field_type is getattr(_dataclasses, "_FIELD_INITVAR")
    ]

    def __init__(self: Any, *args: Any, **kwargs: Any) -> None:
        if not _pyir_cal_active():
            orig_init(self, *args, **kwargs)
            return
        _pyir_cal_init_receiver(self)
        bound = sig.bind(self, *args, **kwargs)
        bound.apply_defaults()
        values = bound.arguments
        for f in fields:
            if f._field_type is not getattr(_dataclasses, "_FIELD"):
                continue
            if f.init:
                value = values[f.name]
                if value is getattr(_dataclasses, "_HAS_DEFAULT_FACTORY"):
                    value = f.default_factory()
            elif f.default_factory is not _dataclasses.MISSING:
                value = f.default_factory()
            elif f.default is not _dataclasses.MISSING:
                value = f.default
            else:
                continue
            label = f"{cls.__name__}.{f.name}"
            if frozen:
                if _pyir_cal_owner_is_opaque(self) or _pyir_cal_is_born(self):
                    # The raw store binds the constructor argument as-is; the
                    # object's escape into a place publishes the routed value.
                    _pyir_setattr_raw(self, f.name, value)
                else:
                    _pyir_routed_object_setattr(self, f.name, value)
            else:
                _pyir_cal_setattr(self, f.name, value, label, filename, lineno)
        post = getattr(self, "__post_init__", None)
        if post is not None:
            _pyir_call_boundary_(post)(*[values[v.name] for v in init_vars])

    __init__.__qualname__ = getattr(orig_init, "__qualname__", "__init__")
    __init__.__wrapped__ = orig_init  # type: ignore[attr-defined]
    _DATACLASS_INITS[cls] = __init__
    return __init__


def _pyir_cal_unwrap_function(fn: Any) -> Any:
    """The plain function behind a ``functools.partial`` / method / wrapper
    chain (an accessor's callable), else *fn* itself."""
    seen: "set[int]" = set()
    while (
        fn is not None
        and id(fn) not in seen
        and not isinstance(fn, _types.FunctionType)
    ):
        seen.add(id(fn))
        if isinstance(fn, _functools.partial):
            fn = fn.func
        elif isinstance(fn, _types.MethodType):
            fn = fn.__func__
        elif getattr(fn, "__wrapped__", None) is not None:
            fn = fn.__wrapped__
        else:
            break
    return fn


def _pyir_instrument_class(cls: type) -> None:
    """Swap the callables a user class defines (its own ``__dict__``, its
    user-module bases', its metaclass's and its descriptors') so calls
    reaching them by any path observe, for the open trace."""
    for klass in cls.__mro__:
        if klass in _INSTRUMENTED_CLASSES or klass is object:
            continue
        if not _pyir_boundary_module_is_user(getattr(klass, "__module__", None)):
            continue
        _INSTRUMENTED_CLASSES.add(klass)
        meta = type(klass)
        if meta is not type and _pyir_boundary_module_is_user(
            getattr(meta, "__module__", None)
        ):
            _pyir_instrument_class(meta)
        for name, member in list(vars(klass).items()):
            target = member
            if isinstance(member, (staticmethod, classmethod)):
                target = member.__func__
            elif isinstance(member, property):
                for fn in (member.fget, member.fset, member.fdel):
                    fn = _pyir_cal_unwrap_function(fn)
                    if isinstance(fn, _types.FunctionType):
                        _pyir_rewrite_function_in_place(fn)
                continue
            elif isinstance(member, _functools.cached_property):
                target = _pyir_cal_unwrap_function(member.func)
            if not isinstance(target, _types.FunctionType):
                if (
                    not isinstance(target, (type, _types.ModuleType))
                    and type(target) not in _SCALAR_TYPES
                ):
                    _pyir_cal_sight(target)  # a descriptor instance of a user class
                continue
            if (
                name == "__init__"
                and hasattr(klass, "__dataclass_fields__")
                and target.__code__.co_filename == "<string>"
            ):
                _SWAPPED_CLASS_ATTRS.append((klass, "__init__", member))
                setattr(klass, "__init__", _pyir_dataclass_init(klass, target))
                continue
            _pyir_rewrite_function_in_place(target)


# -- Dispatch ------------------------------------------------------------------


def _pyir_cal_generated_method(func: Any) -> bool:
    """A method generated by ``dataclasses`` / ``namedtuple`` (source-less,
    reads fields or raises): native semantics are its semantics."""
    code = getattr(func, "__code__", None)
    if code is None or code.co_filename != "<string>":
        return False
    qualname = getattr(func, "__qualname__", "")
    owner_name, _, _ = qualname.rpartition(".")
    module = _sys.modules.get(getattr(func, "__module__", None) or "")
    owner: Any = module
    for part in owner_name.split(".") if owner_name else []:
        owner = getattr(owner, part, None)
        if owner is None:
            break
    if isinstance(owner, type):
        return hasattr(owner, "__dataclass_fields__") or hasattr(owner, "_fields")
    return False


def _pyir_cal_observe_wrapper_targets(func: Any) -> None:
    """A stdlib wrapper around user code (``functools.wraps``, ``singledispatch``
    overloads): swap what it forwards to."""
    seen: "set[int]" = set()
    target = getattr(func, "__wrapped__", None)
    while target is not None and id(target) not in seen:
        seen.add(id(target))
        if isinstance(target, _types.FunctionType):
            _pyir_rewrite_function_in_place(target)
        target = getattr(target, "__wrapped__", None)
    registry = getattr(func, "registry", None)
    register = getattr(func, "register", None)
    if registry is None and register is not None:
        dispatcher = getattr(getattr(register, "__self__", None), "dispatcher", None)
        registry = getattr(dispatcher, "registry", None)
    if isinstance(registry, _abc.Mapping):
        for overload in list(registry.values()):
            if isinstance(overload, _types.FunctionType):
                _pyir_rewrite_function_in_place(overload)


class _PyirCalleeCall:
    """Thin call-through for a plain callee that needs a call-time wall: the
    short-circuit operand depth, the module-global write guard, the
    source-unavailable refusal inside staged CF, or a birth mark on the
    result (a constructor, generator or coroutine function)."""

    __slots__ = ("_callee", "_sc_rhs", "_observed", "_mark_result", "_fresh")

    def __init__(
        self,
        callee: Any,
        sc_rhs: bool,
        observed: bool,
        mark_result: bool,
        fresh: "tuple[int, ...]" = (),
    ) -> None:
        self._callee = callee
        self._sc_rhs = sc_rhs
        self._observed = observed
        self._mark_result = mark_result
        self._fresh = fresh

    def __call__(self, *args: Any, **kwargs: Any) -> Any:
        callee = self._callee
        if not _pyir_cal_active():
            return callee(*args, **kwargs)
        sourceless = None
        if not self._observed and _pyir_cal_dynamic_staged():
            sourceless = _pyir_cal_sourceless_prepare(callee, args, kwargs)
        # A comprehension / generator expression in argument position is born
        # for this call: the callee's native consumers see it as region-born.
        for pos in self._fresh:
            if pos < len(args):
                _pyir_cal_mark_born(args[pos])
        _pyir_global_write_guard(callee)
        # F-SPEC: a parameter default this call leaves unbound is def-time state the
        # body reads as a plain local (no choke sees the binding); its rows seal at
        # the callee's ``__defaults__`` path here.
        if _pyir_cal_has_defaults(callee):
            _pyir_register_taken_default_holders(callee, args, kwargs)
            _pyir_spec_boundary_default_reads(callee, args, kwargs)
        watch = _pyir_global_write_watch(callee)
        if self._sc_rhs:
            _PYIR_SC_RHS_DEPTH[0] += 1
        try:
            if sourceless is None:
                result = callee(*args, **kwargs)
            else:
                result = _pyir_cal_run_sourceless(callee, sourceless, args, kwargs)
        finally:
            if self._sc_rhs:
                _PYIR_SC_RHS_DEPTH[0] -= 1
        _pyir_global_write_check(watch)
        if self._mark_result and is_inside_staged_cf():
            _pyir_cal_mark_born(result)
        return result


def _pyir_cal_has_defaults(callee: Any) -> bool:
    """Does *callee* (a function or a bound method) declare parameter defaults?"""
    func = getattr(callee, "__func__", callee)
    return isinstance(func, _types.FunctionType) and bool(
        func.__defaults__ or func.__kwdefaults__
    )


def _pyir_refuse_unrewritable_callee(
    callee: Any, location: "tuple[str | None, int | None] | None" = None
) -> "NoReturn":
    func = getattr(callee, "__func__", callee)
    filename, lineno = location or _first_non_dsl_caller_location()
    raise _pyir_fatal_trace_error(
        DSLUserCodeError(
            DiagId.BOUNDARY_CALLEE_SOURCE_UNAVAILABLE,
            filename=filename,
            lineno=lineno,
            name=getattr(func, "__qualname__", None)
            or getattr(func, "__name__", "this callable"),
        )
    )


# Opcodes that bind state outside the executing frame's own locals.
_PYIR_SOURCELESS_WRITE_OPS = frozenset(
    {
        "STORE_ATTR",
        "DELETE_ATTR",
        "STORE_SUBSCR",
        "DELETE_SUBSCR",
        "STORE_SLICE",
        "STORE_GLOBAL",
        "DELETE_GLOBAL",
        "STORE_NAME",
        "DELETE_NAME",
        "STORE_DEREF",
        "DELETE_DEREF",
    }
)
# Names a body without source may load to reach a mutator or a reflection
# route the rewriter would otherwise choke.
_PYIR_SOURCELESS_HAZARD_NAMES = (
    frozenset(
        {
            "setattr",
            "delattr",
            "exec",
            "eval",
            "compile",
            "globals",
            "locals",
            "vars",
            "__dict__",
            "__setattr__",
            "__delattr__",
            "__setitem__",
            "__delitem__",
        }
    )
    | _PYIR_GLOBAL_MUTATOR_ATTRS
    | frozenset(_LIST_MUTATORS)
    | frozenset(_DICT_MUTATORS)
    | frozenset(_SET_MUTATORS)
)
_PYIR_SOURCELESS_SCANS: "dict[Any, frozenset | None]" = {}


def _pyir_cal_sourceless_codes(code: Any) -> "frozenset | None":
    """The code objects a source-less body runs as its own frames (the root and
    its nested defs, lambdas and comprehensions), or None when one of them binds
    state outside its frame or names a mutator / reflection route."""
    if code in _PYIR_SOURCELESS_SCANS:
        return _PYIR_SOURCELESS_SCANS[code]
    found: "set[Any]" = set()
    stack = [code]
    verdict: "frozenset | None" = None
    while stack:
        current = stack.pop()
        found.add(current)
        if set(current.co_names) & _PYIR_SOURCELESS_HAZARD_NAMES:
            break
        if any(
            ins.opname in _PYIR_SOURCELESS_WRITE_OPS
            for ins in _dis.get_instructions(current)
        ):
            break
        stack.extend(c for c in current.co_consts if isinstance(c, _types.CodeType))
    else:
        verdict = frozenset(found)
    _PYIR_SOURCELESS_SCANS[code] = verdict
    return verdict


def _pyir_cal_sourceless_prepare(callee: Any, args: Any, kwargs: Any) -> Any:
    """Pre-call arm for a plain callee whose body cannot be rewritten, inside
    dynamic staged CF: its bytecode may bind only its own locals, it may not be
    a generator / coroutine (its frames would run outside the watched window),
    and the user callables and receivers it is handed are swapped first; else
    refuse."""
    func = getattr(callee, "__func__", callee)
    code = getattr(func, "__code__", None)
    location = _first_non_dsl_caller_location()
    if (
        not isinstance(func, _types.FunctionType)
        or code is None
        or _inspect.isgeneratorfunction(func)
        or _inspect.iscoroutinefunction(func)
        or _inspect.isasyncgenfunction(func)
    ):
        _pyir_refuse_unrewritable_callee(callee, location)
    codes = _pyir_cal_sourceless_codes(code)
    previous = _sys.getprofile()
    if codes is None or (previous is not None and not callable(previous)):
        _pyir_refuse_unrewritable_callee(callee, location)
    for value in args:
        _pyir_cal_observe_value(value)
    for value in kwargs.values():
        _pyir_cal_observe_value(value)
    for cell in getattr(func, "__closure__", None) or ():
        try:
            _pyir_cal_observe_leaf(cell.cell_contents)
        except ValueError:
            pass
    namespace = getattr(func, "__globals__", None) or {}
    for name in getattr(code, "co_names", ()):
        if name in namespace:
            _pyir_cal_observe_leaf(namespace[name])
    return codes, location


def _pyir_cal_run_sourceless(callee: Any, prepared: Any, args: Any, kwargs: Any) -> Any:
    """Run a source-less body under a frame watch: a frame it enters (directly or
    through native code) must run rewritten code, native code, or another
    source-less body that passes the same scan; any other user frame refuses."""
    codes, location = prepared
    watched = set(codes)
    previous = _sys.getprofile()

    def _pyir_cal_sourceless_frame_watch(frame: Any, event: str, arg: Any) -> None:
        # Detector only: the frame climb decides refusal, never emission.
        if previous is not None:
            previous(frame, event, arg)
        if event != "call":
            return
        code = frame.f_code
        if code in watched or code in _REWRITTEN_CODES:
            return
        sourceless = code.co_filename.startswith("<")
        if not sourceless and not _pyir_cal_code_is_user(code):
            return
        back = frame.f_back
        while back is not None and back.f_code not in watched:
            if back.f_code in _REWRITTEN_CODES or _pyir_cal_code_is_user(back.f_code):
                return
            back = back.f_back
        if back is None:
            return
        nested = _pyir_cal_sourceless_codes(code) if sourceless else None
        if nested is None:
            _pyir_refuse_unrewritable_callee(callee, location)
        watched.update(nested)

    _sys.setprofile(_pyir_cal_sourceless_frame_watch)
    try:
        return callee(*args, **kwargs)
    finally:
        _sys.setprofile(previous)


def _pyir_spec_record_callee_cells(func: Any) -> None:
    """F-SPEC arm for a plain callee dispatched inside staged CF: its scalar closure
    cells are def-time state the rewritten body reads through the cell choke
    (which sees the cell, never the function), so they root here at the callee's
    re-resolvable path."""
    try:
        if not _PYIR_CANDIDATE_REGISTRY_ACTIVE[0] or not is_inside_staged_cf():
            return
        _pyir_spec_note_dispatched_callee(func)
        closure = getattr(func, "__closure__", None)
        if not closure:
            return
        for ci, cell in enumerate(closure):
            tok = _pyir_lookup_owner_token(cell)
            if tok is not None and tok in _PYIR_CELL_HOME_BINDING:
                continue
            try:
                contents = cell.cell_contents
            except ValueError:
                continue
            _pyir_spec_boundary_closure_read(func, ci, contents)
    except Exception:
        pass  # recording must never break the call it observes


def _pyir_callee_rewrite_dispatch(
    callee: Any, sc_rhs: bool, fresh: "tuple[int, ...]" = ()
) -> Any:
    """Dispatcher arm for a user-module callable: swap its code (and its
    class's) in place, then return it -- wrapped only when a call-time wall
    applies (*fresh* names the positional arguments born for the call); a
    stdlib wrapper carrying a user ``__module__`` is a native callee whose
    forwarding targets are swapped."""
    func = getattr(callee, "__func__", callee)
    mark_result = False
    if isinstance(callee, type):
        _pyir_instrument_class(callee)
        observed = True
        mark_result = is_inside_staged_cf()
    elif isinstance(callee, _types.MethodType):
        owner = callee.__self__
        if isinstance(owner, type):
            _pyir_instrument_class(owner)
        elif owner is not None:
            _pyir_cal_sight(owner)
        observed = _pyir_rewrite_function_in_place(func)
        mark_result = _inspect.isgeneratorfunction(
            func
        ) or _inspect.iscoroutinefunction(func)
    elif isinstance(func, _types.FunctionType):
        observed = _pyir_rewrite_function_in_place(func)
        mark_result = _inspect.isgeneratorfunction(
            func
        ) or _inspect.iscoroutinefunction(func)
    else:
        # A callable instance: its ``__call__`` is a method of a user class.
        _pyir_cal_sight(callee)
        observed = type(callee) in _INSTRUMENTED_CLASSES
    if isinstance(func, _types.FunctionType):
        _pyir_spec_record_callee_cells(func)
    if not observed and isinstance(func, _types.FunctionType):
        code = func.__code__
        if code.co_filename != "<string>" and not _pyir_cal_code_is_user(code):
            _pyir_cal_observe_wrapper_targets(func)
            return _PyirMetaUnwrapProxy(callee)
        if _pyir_cal_generated_method(func):
            return callee
    if (
        observed
        and not sc_rhs
        and not mark_result
        and not fresh
        and not _pyir_cal_has_defaults(callee)
        and (
            not isinstance(func, _types.FunctionType)
            or _pyir_callee_global_write(func) is None
        )
    ):
        return callee
    return _PyirCalleeCall(callee, sc_rhs, observed, mark_result, fresh)


_PYIR_SIGHT_HOOK[0] = _pyir_cal_sight


def _pyir_callee_debug_source(func: Any) -> "str | None":
    """Unparsed rewritten body of *func* (debug aid, the callee counterpart of
    ``PRINT_AFTER_PREPROCESSOR``)."""
    code = getattr(func, "__code__", None)
    if code is None:
        return None
    orig = _ORIGINAL_CODES.get(code, code if code in _REWRITE_CACHE else None)
    if orig is None:
        return None
    located = _pyir_locate_def(orig)
    if located is None:
        return None
    node, class_name, table = located
    node = _copy.deepcopy(node)
    rewriter = _PyirCalleeAccessRewriter(
        orig.co_filename, class_name, table, _pyir_global_names(func)
    )
    prologue = rewriter.rewrite_root(node)
    if isinstance(node, _ast.Lambda):
        return _ast.unparse(_ast.fix_missing_locations(node))
    node.body = [*prologue, *node.body]
    return _ast.unparse(_ast.fix_missing_locations(node))


# Static export surface (regenerate with scripts/gen_pyir_all.py): the
# module's OWN names -- its namespace minus what lower chain modules
# already export and minus the generator's INTERNAL_ONLY registry.
__all__ = [
    "_array",
    "_bisect",
    "_ast",
    "_collections",
    "_abc",
    "_contextvars",
    "_copy",
    "_dataclasses",
    "_dis",
    "_heapq",
    "_inspect",
    "_linecache",
    "_operator",
    "_os",
    "_random",
    "_sysconfig",
    "_symtable",
    "_threading",
    "_types",
    "_warnings",
    "DSLBaseError",
    "_pyir_boundary_module_is_user",
    "_PYIR_UNOBSERVABLE",
    "_pyir_cursor_atom",
    "_pyir_iterator_cursor",
    "_pyir_module_is_host_state",
    "_PYIR_OPERATOR_DUNDERS",
    "_pyir_boundary_overrides_operators",
    "_pyir_boundary_is_traced_callable",
    "_PYIR_BUILTIN_CONTAINER_BASES",
    "_pyir_builtin_subclass_storage",
    "_pyir_boundary_is_user_holder",
    "_pyir_boundary_observe_truth",
    "_PYIR_EXPLICIT_RAISE_OPNAMES",
    "_pyir_exception_born_native",
    "_pyir_boundary_native_rejection_vars",
    "_pyir_holds_promoted_meta",
    "_pyir_boundary_refuse_native_raise",
    "_PYIR_PREDICATE_ITERATORS",
    "_pyir_boundary_native_callee_display",
    "_PYIR_TRACE_ACTIVE_MEMO",
    "_pyir_cal_meta_payload",
    "_PyirMetaPayloadCall",
    "_PyirResultObserver",
    "_pyir_boundary_consume_meta_arg",
    "_pyir_seed_absent_attr_read",
    "_pyir_delete_attr",
    "_pyir_import_guard",
    "_PYIR_GLOBAL_WRITE_SCANS",
    "_pyir_callee_global_write",
    "_pyir_global_write_guard",
    "_PYIR_GLOBAL_CONTAINER_TYPES",
    "_PYIR_GLOBAL_CONTAINER_IMAGE_CAP",
    "_PYIR_STAGED_TOKEN",
    "_pyir_global_container_image",
    "_PYIR_GLOBAL_MUTATOR_ATTRS",
    "_PYIR_PURE_LOAD_OPS",
    "_PYIR_GLOBAL_VALUE_READ_SCANS",
    "_PYIR_INPLACE_UPDATE_OPS",
    "_pyir_is_inplace_subscr_update",
    "_pyir_callee_global_value_reads",
    "_PYIR_GLOBAL_LOOP_TRACE",
    "_pyir_global_loop_trace",
    "_pyir_refuse_global_write",
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
    "_pyir_subscript_store",
    "_pyir_delete_item",
    "_pyir_inplace_binop",
    "_pyir_ctx_boundary",
    "_pyir_strong_handle",
    "_pyir_boundary_note_birth",
    "_pyir_boundary_birth_anchor",
    "_pyir_boundary_declare_birth_place",
    "_pyir_boundary_callee_name",
    "_pyir_boundary_bind_leaf",
    "_pyir_boundary_bind_storage",
    "_pyir_boundary_stage_taken_default_reads",
    "_pyir_boundary_restore_meta_reads",
    "_pyir_boundary_note_nested_scope_reads",
    "_verify_no_used_poison",
    "_REWRITTEN_CODES",
    "_REWRITE_CACHE",
    "_ORIGINAL_CODES",
    "_INSTRUMENTED_CLASSES",
    "_SWAPPED_FUNCTIONS",
    "_SWAPPED_CLASS_ATTRS",
    "_DATACLASS_INITS",
    "_PYIR_SC_RHS_DEPTH",
    "_FILE_AST_CACHE",
    "_FILE_SYMTABLE_CACHE",
    "_FILE_USER_VERDICT",
    "_REGION_BORN",
    "_ACTIVE_ACCESS",
    "_PENDING_DELETES",
    "_DETACHED",
    "_HELD",
    "_HOMED",
    "_READ_LABELS",
    "_pyir_cal_note_label",
    "_pyir_cal_label_of",
    "_pyir_cal_has_label",
    "_HOST_CONTAINERS",
    "_PyirTracePin",
    "_PyirItemProbe",
    "_PyirAttrProbe",
    "_PyirCellProbe",
    "_pyir_cal_pin",
    "_KEYSET_CHANGED",
    "_BORN_BINDINGS",
    "_GEN_PROBES",
    "_CACHED_PROPERTY_FACTS",
    "_DESCRIPTOR_FACTS",
    "_MEMBER_MISS",
    "_RT",
    "_RT_MODULE",
    "_CELL_PREFIX",
    "_BARE_BUILTIN_SKIP",
    "_AUG_OPS",
    "_SCALAR_TYPES",
    "_CALLABLE_VALUE_TYPES",
    "_EXCEPTION_SLOTS",
    "_BUILTIN_CONTAINER_BASES",
    "_DESCRIPTOR_TYPES",
    "_FACTORY_MODULES",
    "_FACTORY_BUILTINS",
    "_FACTORY_METHODS",
    "_KIND_MODULE",
    "_KIND_THREAD_LOCAL",
    "_KIND_GENERATOR",
    "_KIND_RNG",
    "_KIND_DEQUE",
    "_KIND_ORDERED_DICT",
    "_KIND_BUFFER",
    "_KIND_FINALIZER",
    "_KIND_ITERATOR",
    "_KIND_CONTEXTVAR",
    "_KIND_EXCEPTION",
    "_KIND_FUNCTION",
    "_KIND_CALLABLE_ATTR",
    "_KIND_OPERATOR_SCALAR",
    "_KIND_CACHED_PROPERTY",
    "_KIND_EXEC",
    "_KIND_BORN_CLOSURE",
    "_KIND_PLAIN_SET",
    "_KIND_PLAIN_LIST",
    "_KIND_PLAIN_DICT",
    "_PLAIN_CONTAINER_KINDS",
    "_PLAIN_CONTAINER_TYPES",
    "_ITERATOR_MODULES",
    "_SET_MUTATORS",
    "_LIST_MUTATORS",
    "_DICT_MUTATORS",
    "_INPLACE_CONTAINER_DUNDERS",
    "_MUTATORS",
    "_RNG_READERS",
    "_ITERATOR_INSPECTORS",
    "_BUFFER_INSPECTORS",
    "_UNBOUND_MUTATOR_NAMES",
    "_pyir_cal_host_state_kind",
    "_WRITER_AT_CACHE",
    "_pyir_cal_writer_at",
    "_pyir_cal_refuse_host_state",
    "_pyir_cal_active",
    "_pyir_cal_dynamic_staged",
    "_PROTOCOL_DUNDERS",
    "_PROTOCOL_READ_DUNDERS",
    "_PROTOCOL_ACTIVE",
    "_PROBE_DEPTH",
    "_PyirProtocolScope",
    "_pyir_cal_protocol",
    "_TRACER_PROBE_NAMES",
    "_TRACER_PROBE_PREFIXES",
    "_pyir_cal_probe_name",
    "_pyir_cal_in_protocol",
    "_pyir_cal_hooks_on",
    "_fatal",
    "_pyir_cal_same_region",
    "_pyir_cal_mark_born",
    "_pyir_cal_mark_born_def",
    "_pyir_cal_is_born",
    "_pyir_cal_escaped",
    "_NONE_READS",
    "_pyir_cal_none_rebind_wall",
    "_TRUTH_FOLDS",
    "_pyir_cal_truth",
    "_pyir_cal_assert",
    "_BINOP_NAMES",
    "_COMPARE_NAMES",
    "_PLAIN_SCALARS",
    "_pyir_cal_binop",
    "_pyir_cal_compare",
    "_CAL_LAST_NOTIN_COMPARE",
    "_CAL_GATE_STACK",
    "_pyir_cal_membership_is_staged",
    "_pyir_cal_membership",
    "_pyir_cal_staged_operand",
    "_pyir_cal_dsl_operand",
    "_pyir_cal_bool_sc",
    "_pyir_cal_and_",
    "_pyir_cal_or_",
    "_pyir_cal_not_",
    "_BUILTIN_REDIRECT_NAMES",
    "_BUILTIN_REDIRECT_TARGETS",
    "_PyirCalReduction",
    "_pyir_cal_redirect_builtin",
    "_pyir_cal_fold_if_enter",
    "_pyir_cal_fold_if_exit",
    "_pyir_cal_check_truth_folds",
    "_KIND_DICT_VIEW",
    "_KIND_MAPPING_PROXY",
    "_VIEW_KINDS",
    "_DICT_KEYS_TYPE",
    "_DICT_VIEW_TYPES",
    "_VIEW_TYPES",
    "_pyir_cal_refuse_dict_view",
    "_pyir_cal_view_wall",
    "_KIND_CLASS_DEF",
    "_pyir_cal_type",
    "_pyir_cal_class_def_wall",
    "_pyir_cal_born_cells",
    "_pyir_cal_init_receiver",
    "_pyir_cal_new_result",
    "_pyir_cal_slot_bound",
    "_pyir_cal_born_closure",
    "_pyir_cal_closure_escape_wall",
    "_pyir_cal_mark_born_parts",
    "_pyir_cal_born",
    "_pyir_cal_refuse_pending_delete",
    "_pyir_cal_pending_deletes_check",
    "_pyir_cal_refuse_replaced",
    "_pyir_cal_tracked_holder",
    "_pyir_cal_hold",
    "_pyir_cal_bind",
    "_pyir_cal_note_homed",
    "_pyir_cal_is_held",
    "_pyir_cal_replaced_object",
    "_pyir_cal_mark_detached",
    "_pyir_cal_detached_wall",
    "_pyir_cal_sight",
    "_pyir_cal_route_callable",
    "_pyir_cal_observe_value",
    "_pyir_cal_observe_leaf",
    "_pyir_cal_scalar_subclass_wall",
    "_pyir_cal_read_pin",
    "_pyir_cal_builtin_subclass_base",
    "_pyir_cal_refuse_builtin_subclass",
    "_pyir_cal_host_state_owner",
    "_pyir_cal_owner_is_opaque",
    "_pyir_cal_mro_member",
    "_pyir_cal_cached_property",
    "_pyir_cal_user_descriptor",
    "_pyir_cal_descriptor_owns_store",
    "_pyir_cal_descriptor_owns_read",
    "_pyir_cal_stored_value",
    "_pyir_cal_getattr",
    "_pyir_cal_container_internal",
    "_pyir_cal_container_name",
    "_pyir_cal_subscript_wall",
    "_DICT_KEYED_METHODS",
    "_LIST_INDEXED_METHODS",
    "_pyir_cal_method_key_wall",
    "_pyir_cal_compound_key_wall",
    "_pyir_cal_getitem",
    "_pyir_cal_global_read",
    "_pyir_cal_note_host_container",
    "_pyir_cal_host_container",
    "_HOST_READS",
    "_HOST_SHAPE_WRITES",
    "_pyir_cal_refuse_host_shape",
    "_pyir_cal_host_shape_wall",
    "_pyir_cal_note_host_read",
    "_WHOLE_CONSUMER_BUILTINS",
    "_DICT_WHOLE_METHODS",
    "_pyir_cal_note_consumption",
    "_pyir_cal_host_element_native",
    "_pyir_cal_has_key",
    "_pyir_cal_sc_wall",
    "_pyir_cal_store_walls",
    "_pyir_cal_stale_value",
    "_META_STORES",
    "_pyir_cal_meta_store_pin",
    "_pyir_cal_source_promoted",
    "_pyir_cal_src_places",
    "_pyir_cal_meta_binding",
    "_pyir_cal_check_meta_stores",
    "_pyir_cal_refuse_stale",
    "_pyir_cal_has_stored",
    "_pyir_cal_note_born_binding",
    "_pyir_cal_unbind_born",
    "_pyir_cal_finish_pending_delete",
    "_pyir_cal_setattr",
    "_pyir_cal_iattr",
    "_pyir_cal_delattr",
    "_pyir_cal_raw_read_choke",
    "_pyir_cal_object_getattr",
    "_pyir_cal_super_getattr",
    "_pyir_cal_object_delattr",
    "_pyir_cal_dict_update",
    "_PyirItemStore",
    "_PyirItemDelete",
    "_pyir_cal_user_item_dunder",
    "_pyir_cal_item_store_raw",
    "_PyirDictUpdate",
    "_pyir_cal_inplace_container_wall",
    "_pyir_cal_buffer_wall",
    "_pyir_cal_plain_container_wall",
    "_pyir_cal_setitem",
    "_pyir_cal_native_item_store",
    "_pyir_cal_getitem_rmw",
    "_pyir_cal_iitem",
    "_pyir_cal_delitem",
    "_pyir_cal_dict_storage",
    "_pyir_cal_dict_view",
    "_pyir_cal_vars",
    "_PyirStorageView",
    "_KEYSET_OBSERVED",
    "_pyir_cal_keyset_wall",
    "_pyir_cal_check_keyset_observations",
    "_pyir_cal_note_keyset_change",
    "_pyir_cal_dict_read",
    "_pyir_cal_dict_store",
    "_pyir_cal_dict_get",
    "_pyir_cal_dict_del",
    "_pyir_cal_global_store",
    "_pyir_cal_cell_read",
    "_pyir_cal_cell_del",
    "_pyir_cal_cell_store",
    "_pyir_cal_cell_iop",
    "_pyir_cal_iter",
    "_pyir_cal_reraise",
    "_pyir_cal_class_arg",
    "_pyir_cal_unbound_mutator",
    "desc",
    "_UNBOUND_MUTATOR_ROUTES",
    "_pyir_cal_descriptor_store",
    "_pyir_cal_descriptor_read",
    "_pyir_cal_super_setattr",
    "_pyir_cal_super_delattr",
    "_pyir_cal_object_setattr",
    "_pyir_cal_reflect_setattr",
    "_pyir_cal_reflect_delattr",
    "_pyir_cal_user_owner",
    "_pyir_cal_class_store",
    "_pyir_cal_native_callee",
    "_PyirExceptionSetState",
    "_pyir_cal_generator_point",
    "_pyir_cal_native_policy",
    "_FIELD_READING_MODULES",
    "_pyir_cal_refresh_holder",
    "_pyir_cal_is_factory",
    "_pyir_cal_direct_parts",
    "_pyir_cal_fresh_result",
    "_pyir_cal_freeze_born_fields",
    "_pyir_cal_native_result",
    "_pyir_mangle",
    "_pyir_cal_label",
    "_is_simple",
    "_is_dunder_dict",
    "_dunder_dict_owner",
    "_table_free_names",
    "_table_cell_names",
    "_table_nonlocal_names",
    "_PyirCalleeAccessRewriter",
    "_pyir_module_source",
    "_pyir_module_ast",
    "_pyir_module_symtable",
    "_pyir_locate_def",
    "_pyir_global_names",
    "_pyir_compile_rewrite",
    "_pyir_register_rewritten_code",
    "_pyir_cal_code_is_user",
    "_pyir_rewrite_function_in_place",
    "_pyir_cal_trace_close",
    "_pyir_dataclass_init",
    "_pyir_cal_unwrap_function",
    "_pyir_instrument_class",
    "_pyir_cal_generated_method",
    "_pyir_cal_observe_wrapper_targets",
    "_PyirCalleeCall",
    "_pyir_cal_has_defaults",
    "_pyir_refuse_unrewritable_callee",
    "_PYIR_SOURCELESS_WRITE_OPS",
    "_PYIR_SOURCELESS_HAZARD_NAMES",
    "_PYIR_SOURCELESS_SCANS",
    "_pyir_cal_sourceless_codes",
    "_pyir_cal_sourceless_prepare",
    "_pyir_cal_run_sourceless",
    "_pyir_spec_record_callee_cells",
    "_pyir_callee_rewrite_dispatch",
    "_pyir_callee_debug_source",
]
