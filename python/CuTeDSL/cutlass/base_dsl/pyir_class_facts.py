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


"""Decoration-time per-class ``self.<field>`` write-fact registry: modules
parse ONCE at decoration/preprocess scope, never inside a trace-time walk."""

import ast
import hashlib
import inspect
import os
import sys
import tempfile
import textwrap
import types
from typing import Any, Optional

from .pyir_state import _Sentinel

# (module_name, def qualname, first lineno) -> {attr: (literal_values,
# guard_paths)} for defs whose ``attr`` writes are ALL guard-enumerable
# literal-constant stores.  The lineno keeps qualname TWINS (a re-defined
# name shares the qualname) from colliding onto one row.
_LITERAL_WRITE_FACTS: "dict[tuple[str, str, int], dict[str, tuple[tuple, tuple]]]" = {}
# (module_name, def qualname, first lineno) -> (receiver attr writes, receiver
# method calls, root-first-arg free calls, other free calls, incomplete);
# exact-identity keyed rows for every def.  ``incomplete`` is True when the
# write set is not provably complete: an opaque call, or a deep receiver-rooted
# write target (``self.sub.n``) the one-hop name schema cannot express.
_DEF_FACTS: "dict[tuple[str, str, int], tuple[frozenset, frozenset, frozenset, frozenset, bool]]" = {}
# Module names recorded by a decoration but not yet parsed.
_PENDING_MODULES: "list[str]" = []
_PENDING_SET: "set[str]" = set()
# Modules already parsed (or unparseable -- both final).
_MATERIALIZED_MODULES: "set[str]" = set()
# Set on the first PyIR preprocessing session; from then on decorations
# materialize their module eagerly (decoration scope) instead of pending.
_PYIR_ACTIVE: bool = False
# DSL-declared module/package prefixes; re-resolved against ``sys.modules`` at
# every drain so a submodule imported later materializes at the next session.
_DECLARED_PREFIXES: "set[str]" = set()


def _receiver_attr_write_names(
    fn: "ast.FunctionDef | ast.AsyncFunctionDef",
) -> "tuple[frozenset[str], bool]":
    """``(attr_names, enumerable)``: attribute names *fn* assigns on its
    first-parameter receiver, nested defs included (a nested impl's write
    attributes to the enclosing callable).  ``enumerable`` is False when a
    write target is a deep receiver-rooted path (``self.sub.n``)."""
    args = fn.args.posonlyargs + fn.args.args
    if not args:
        return frozenset(), True
    recv = args[0].arg
    found: "set[str]" = set()
    enumerable = True
    for node in ast.walk(fn):
        targets: "list[ast.expr]" = []
        if isinstance(node, ast.Assign):
            targets = node.targets
        elif isinstance(node, (ast.AugAssign, ast.AnnAssign)):
            targets = [node.target]
        elif isinstance(node, (ast.For, ast.AsyncFor)):
            targets = [node.target]
        elif isinstance(node, (ast.With, ast.AsyncWith)):
            targets = [
                item.optional_vars
                for item in node.items
                if item.optional_vars is not None
            ]
        for t in targets:
            stack = [t]
            while stack:
                n = stack.pop()
                if isinstance(n, (ast.Tuple, ast.List)):
                    stack.extend(n.elts)
                elif isinstance(n, ast.Starred):
                    stack.append(n.value)
                elif isinstance(n, ast.Attribute):
                    if isinstance(n.value, ast.Name) and n.value.id == recv:
                        found.add(n.attr)
                        continue
                    base = n.value
                    while isinstance(base, (ast.Attribute, ast.Subscript)):
                        base = base.value
                    if isinstance(base, ast.Name) and base.id == recv:
                        enumerable = False
    return frozenset(found), enumerable


def _def_call_shapes(
    fn: "ast.FunctionDef | ast.AsyncFunctionDef",
) -> "tuple[frozenset[str], frozenset[str], frozenset[str], bool]":
    """Call shapes of *fn* for the per-def transitive-write closure:
    ``(receiver_method_calls, root_first_arg_free_calls, other_free_calls,
    has_opaque_calls)``.  A free call joins the root set only when the
    receiver is provably its first parameter (first positional argument is
    the bare receiver name and the receiver escapes into no other position) —
    the aliasing fact the closure needs to attribute the callee's
    first-parameter writes to the root."""
    args = fn.args.posonlyargs + fn.args.args
    recv = args[0].arg if args else None
    methods: "set[str]" = set()
    frees_root: "set[str]" = set()
    frees_other: "set[str]" = set()
    opaque = False
    for node in ast.walk(fn):
        if not isinstance(node, ast.Call):
            continue
        f = node.func
        if isinstance(f, ast.Name):
            first = node.args[0] if node.args else None
            root_first = (
                recv is not None and isinstance(first, ast.Name) and first.id == recv
            )
            root_elsewhere = recv is not None and any(
                isinstance(a, ast.Name) and a.id == recv
                for a in [
                    *node.args[1:],
                    *(kw.value for kw in node.keywords),
                ]
            )
            if root_first and not root_elsewhere:
                frees_root.add(f.id)
            else:
                frees_other.add(f.id)
        elif (
            isinstance(f, ast.Attribute)
            and isinstance(f.value, ast.Name)
            and recv is not None
            and f.value.id == recv
        ):
            methods.add(f.attr)
        else:
            opaque = True
    return frozenset(methods), frozenset(frees_root), frozenset(frees_other), opaque


def _receiver_attr_chain(expr: "ast.expr", recv: str) -> "tuple[str, ...] | None":
    """``self.a.b`` -> ``("a", "b")`` when rooted at the Name *recv*."""
    hops: "list[str]" = []
    node = expr
    while isinstance(node, ast.Attribute):
        hops.append(node.attr)
        node = node.value
    if isinstance(node, ast.Name) and node.id == recv and hops:
        return tuple(reversed(hops))
    return None


def _guard_attr_paths(expr: "ast.expr", recv: str) -> "set[tuple[str, ...]] | None":
    """Receiver-rooted attribute paths a guard expression reads, or ``None``
    when it reads anything the fact cannot enumerate."""
    if isinstance(expr, ast.Constant):
        return set()
    chain = _receiver_attr_chain(expr, recv)
    if chain is not None:
        return {chain}
    if isinstance(expr, ast.BoolOp):
        subs = [_guard_attr_paths(v, recv) for v in expr.values]
    elif isinstance(expr, ast.UnaryOp):
        subs = [_guard_attr_paths(expr.operand, recv)]
    elif isinstance(expr, ast.Compare):
        subs = [_guard_attr_paths(expr.left, recv)] + [
            _guard_attr_paths(c, recv) for c in expr.comparators
        ]
    elif isinstance(expr, ast.IfExp):
        subs = [
            _guard_attr_paths(expr.test, recv),
            _guard_attr_paths(expr.body, recv),
            _guard_attr_paths(expr.orelse, recv),
        ]
    else:
        return None
    paths: "set[tuple[str, ...]]" = set()
    for s in subs:
        if s is None:
            return None
        paths.update(s)
    return paths


def _collect_literal_attr_write_facts(
    fn: "ast.FunctionDef | ast.AsyncFunctionDef",
) -> "dict[str, tuple[tuple, tuple]]":
    """Per-def literal-write facts ``{attr: (literal_values, guard_paths)}``:
    an attr qualifies only when its EVERY write is a literal store under
    guards that read only enumerable receiver-rooted attribute chains."""
    pos_args = list(fn.args.posonlyargs) + list(fn.args.args)
    recv = pos_args[0].arg if pos_args else None
    if recv is None:
        return {}
    # A call can write receiver attributes only when the receiver escapes
    # into it: a receiver-rooted method call, the bare receiver as an
    # argument or alias, or a dynamic-access builtin.  A call the receiver
    # cannot reach (`Int32(self.x)`) leaves every write of this def visible
    # to the scan below, so literal rows survive it; on any escape the def
    # keeps no rows and the consumer keeps its loud refusal.  (The def's own
    # decorators/defaults evaluate at def time, not per call.)
    consumed_recv: "set[int]" = set()
    for st in fn.body:
        for sub in ast.walk(st):
            if isinstance(sub, ast.Call):
                if (
                    isinstance(sub.func, ast.Name)
                    and sub.func.id in _SURFACE_OPAQUE_CALLS
                ):
                    return {}
                if (
                    isinstance(sub.func, ast.Attribute)
                    and _receiver_attr_chain(sub.func, recv) is not None
                ):
                    # Receiver-rooted method call (self.m(), self.child.m()):
                    # the callee can reach the receiver, its writes are unseen.
                    return {}
            if (
                isinstance(sub, ast.Attribute)
                and isinstance(sub.value, ast.Name)
                and sub.value.id == recv
            ):
                consumed_recv.add(id(sub.value))
    for st in fn.body:
        for sub in ast.walk(st):
            if (
                isinstance(sub, ast.Name)
                and sub.id == recv
                and id(sub) not in consumed_recv
            ):
                return {}  # bare receiver escape (call arg, return, rebind)

    def _touched_attrs(t: "ast.expr", out: "set[str]") -> None:
        if isinstance(t, (ast.Tuple, ast.List)):
            for e in t.elts:
                _touched_attrs(e, out)
            return
        if isinstance(t, ast.Starred):
            _touched_attrs(t.value, out)
            return
        while isinstance(t, ast.Subscript):
            t = t.value
        if isinstance(t, ast.Attribute):
            out.add(t.attr)

    def _stmt_touched_attrs(st: "ast.AST") -> "set[str]":
        out: "set[str]" = set()
        if isinstance(st, ast.Assign):
            for t in st.targets:
                _touched_attrs(t, out)
        elif isinstance(st, (ast.AugAssign, ast.AnnAssign)):
            _touched_attrs(st.target, out)
        return out

    literals: "dict[str, list]" = {}
    guard_map: "dict[str, set[tuple[str, ...]]]" = {}
    max_write_lineno: "dict[str, int]" = {}
    disqualified: "set[str]" = set()
    min_exit_lineno: "list[int | None]" = [None]

    def _disqualify_writes_under(node: "ast.AST") -> None:
        for sub in ast.walk(node):
            disqualified.update(_stmt_touched_attrs(sub))

    def _scan(stmts: "list[ast.stmt]", guards: "list[ast.expr]") -> None:
        for st in stmts:
            if isinstance(st, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                # A write hidden in a nested scope executes under call
                # conditions the fact cannot enumerate.
                _disqualify_writes_under(st)
                continue
            if isinstance(st, (ast.Return, ast.Raise, ast.Break, ast.Continue)):
                if min_exit_lineno[0] is None or st.lineno < min_exit_lineno[0]:
                    min_exit_lineno[0] = st.lineno
                continue
            if isinstance(st, (ast.Assign, ast.AugAssign, ast.AnnAssign)):
                touched = _stmt_touched_attrs(st)
                if not touched:
                    continue
                targets = st.targets if isinstance(st, ast.Assign) else [st.target]
                t = targets[0] if len(targets) == 1 else None
                value = getattr(st, "value", None)
                if (
                    isinstance(st, ast.AugAssign)  # reads the (invisible) old value
                    or t is None
                    or not (
                        isinstance(t, ast.Attribute)
                        and isinstance(t.value, ast.Name)
                        and t.value.id == recv
                    )
                    or not isinstance(value, ast.Constant)
                ):
                    disqualified.update(touched)
                    continue
                attr = t.attr
                paths: "set[tuple[str, ...]]" = set()
                for g in guards:
                    gp = _guard_attr_paths(g, recv)
                    if gp is None:
                        disqualified.add(attr)
                        break
                    paths.update(gp)
                else:
                    literals.setdefault(attr, []).append(value.value)
                    guard_map.setdefault(attr, set()).update(paths)
                    max_write_lineno[attr] = max(
                        max_write_lineno.get(attr, 0), st.lineno
                    )
                continue
            if isinstance(st, ast.If):
                _scan(st.body, guards + [st.test])
                _scan(st.orelse, guards + [st.test])
                continue
            if isinstance(st, ast.While):
                _scan(st.body + st.orelse, guards + [st.test])
                continue
            if isinstance(st, (ast.For, ast.AsyncFor)):
                _scan(st.body + st.orelse, guards + [st.iter])
                continue
            # Any other compound statement (with/try/match) has execution
            # conditions the fact cannot enumerate.
            _disqualify_writes_under(st)

    _scan(fn.body, [])
    result: "dict[str, tuple[tuple, tuple]]" = {}
    for attr, lits in literals.items():
        if attr in disqualified:
            continue
        if min_exit_lineno[0] is not None and min_exit_lineno[0] < max_write_lineno.get(
            attr, 0
        ):
            continue  # an early exit above a write acts as an unseen guard
        result[attr] = (tuple(lits), tuple(sorted(guard_map.get(attr, ()))))
    return result


def _walk_defs(
    node: "ast.AST",
    prefix: str,
    out: "list[tuple[str, ast.FunctionDef | ast.AsyncFunctionDef]]",
) -> None:
    """Collect every def under *node* with its runtime ``__qualname__``
    (class methods append ``<Class>.``; nested defs ``<func>.<locals>.``)."""
    for child in ast.iter_child_nodes(node):
        if isinstance(child, (ast.FunctionDef, ast.AsyncFunctionDef)):
            qual = prefix + child.name
            out.append((qual, child))
            _walk_defs(child, qual + ".<locals>.", out)
        elif isinstance(child, ast.ClassDef):
            _walk_defs(child, prefix + child.name + ".", out)
        else:
            _walk_defs(child, prefix, out)


def _def_fact_key(func: Any) -> "tuple[str, str, int] | None":
    """Exact def identity for the fact tables: (module, qualname, first line
    of the decorated def block).  A wrapper resolves through its declared
    ``__wrapped__`` chain; a callable without a code object names no def, so
    its lookups miss (consumers fail closed)."""
    hops = 0
    while hasattr(func, "__wrapped__") and hops < 8:
        func = func.__wrapped__
        hops += 1
    mod = getattr(func, "__module__", None)
    qualname = getattr(func, "__qualname__", None)
    code = getattr(func, "__code__", None)
    if mod is None or qualname is None or code is None:
        return None
    return (mod, qualname, code.co_firstlineno)


def literal_attr_write_fact(func: Any, attr: str) -> "tuple[tuple, tuple] | None":
    """The literal-write fact of ``func``'s exact def for ``attr``; ``None``
    without a qualifying row. Materializes ``func``'s module on first lookup
    (memoized), so every fact read funnels through the single parse site."""
    key = _def_fact_key(func)
    if key is None or not isinstance(attr, str):
        return None
    _materialize_module(key[0])
    row = _LITERAL_WRITE_FACTS.get(key)
    if row is None:
        return None
    return row.get(attr)


# On-disk facts cache. WHAT is cached: one module's parse products, i.e. the
# rows the ast collectors above would install, keyed ``(qualname, lineno)``
# per def:
#   - literal rows (-> _LITERAL_WRITE_FACTS): for defs whose receiver-attr
#     writes are all literal-constant stores, ``{attr: (literals, guards)}``.
#   - def rows (-> _DEF_FACTS): every def's write/call shape: receiver attrs
#     written, receiver methods called, free calls, and the incomplete flag.
# The trace-time attr-write fast paths read those registries; a cache hit
# installs the rows without re-parsing the module source (the expensive step).
#
# HOW it is stored: ``{dir}/{sha256(source)[:32]}.v{FORMAT}.facts`` holds the
# rows as a Python literal (``repr`` on write, ``ast.literal_eval`` on read,
# never pickle). Keyed by the exact source text the parser would see, so an
# edited module can never be served stale rows; unconfigured or disabled
# processes always parse. Bump the format when the collectors change shape.
_FACTS_CACHE_FORMAT = 1
# None: not configured yet; "": configured off; else the cache directory.
_FACTS_CACHE_DIR: "list[str | None]" = [None]


def configure_facts_cache(cache_dir: str, enabled: bool) -> None:
    """Configure the on-disk facts cache once per process (first DSL wins);
    the rows are DSL-agnostic parse products, so one shared store is sound."""
    if _FACTS_CACHE_DIR[0] is None:
        _FACTS_CACHE_DIR[0] = cache_dir if enabled else ""


def _facts_cache_path(source: str) -> "str | None":
    d = _FACTS_CACHE_DIR[0]
    if not d:
        return None
    digest = hashlib.sha256(source.encode("utf-8", "replace")).hexdigest()[:32]
    return os.path.join(d, f"{digest}.v{_FACTS_CACHE_FORMAT}.facts")


def _facts_cache_load(
    source: str,
) -> "tuple[dict, dict] | None":
    """Cached ``(literal_rows, def_rows)`` for the exact *source* text, keyed
    ``(qualname, lineno)``, or ``None``; a missing, corrupt or unreadable file
    reports a miss (the caller parses), never raises."""
    path = _facts_cache_path(source)
    if path is None:
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            payload = ast.literal_eval(f.read())
        if payload["format"] != _FACTS_CACHE_FORMAT:
            return None
        def_rows = {
            key: (
                frozenset(w),
                frozenset(m),
                frozenset(fr),
                frozenset(fo),
                bool(inc),
            )
            for key, (w, m, fr, fo, inc) in payload["defs"].items()
        }
        return payload["literal"], def_rows
    except Exception:
        return None


def _facts_cache_dump(source: str, literal_rows: dict, def_rows: dict) -> None:
    """Best-effort write-through. The payload must round-trip as a Python
    literal (a module with an exotic constant is skipped, it just re-parses);
    concurrent writers are safe, the text lands via temp file + atomic rename."""
    path = _facts_cache_path(source)
    if path is None:
        return
    payload = {
        "format": _FACTS_CACHE_FORMAT,
        "literal": literal_rows,
        "defs": {
            key: (
                tuple(sorted(w)),
                tuple(sorted(m)),
                tuple(sorted(fr)),
                tuple(sorted(fo)),
                bool(inc),
            )
            for key, (w, m, fr, fo, inc) in def_rows.items()
        },
    }
    text = repr(payload)
    try:
        if ast.literal_eval(text) != payload:
            return
    except Exception:
        return
    tmp = None
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(path), suffix=".tmp")
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            f.write(text)
        os.replace(tmp, path)
    except Exception:
        if tmp is not None:
            try:
                os.unlink(tmp)
            except OSError:
                pass


def _materialize_module(module_name: str) -> None:
    """Parse *module_name*'s source once and register facts; unparseable
    source marks it materialized with no facts (consumers do not engage).
    The parse is skipped when the facts cache holds rows for the exact
    source text."""
    if module_name in _MATERIALIZED_MODULES:
        return
    _MATERIALIZED_MODULES.add(module_name)
    module = sys.modules.get(module_name)
    if module is None:
        return
    try:
        source = textwrap.dedent(inspect.getsource(module))
    except (OSError, TypeError, SyntaxError, ValueError):
        return
    cached = _facts_cache_load(source)
    if cached is not None:
        for key, facts in cached[0].items():
            _LITERAL_WRITE_FACTS[(module_name, *key)] = facts
        for key, row in cached[1].items():
            _DEF_FACTS[(module_name, *key)] = row
        return
    try:
        tree = ast.parse(source)
    except (OSError, TypeError, SyntaxError, ValueError):
        return
    # Exact-identity literal-write facts for every def (the call-boundary
    # loop-carry flip's positive evidence; absence keeps the loud refusal).
    defs: "list[tuple[str, ast.FunctionDef | ast.AsyncFunctionDef]]" = []
    _walk_defs(tree, "", defs)
    literal_rows: "dict[tuple[str, int], dict]" = {}
    def_rows: "dict[tuple[str, int], tuple]" = {}
    for qualname, fnode in defs:
        # Runtime ``co_firstlineno`` starts at the FIRST DECORATOR line.
        first_lineno = min([fnode.lineno] + [d.lineno for d in fnode.decorator_list])
        key = (module_name, qualname, first_lineno)
        facts = _collect_literal_attr_write_facts(fnode)
        if facts:
            _LITERAL_WRITE_FACTS[key] = facts
            literal_rows[(qualname, first_lineno)] = facts
        # Per-code-object row for the boundary pre-stage's transitive
        # write-closure (exact runtime identity, never bare-name-keyed).
        _methods, _frees_root, _frees_other, _opaque = _def_call_shapes(fnode)
        _writes, _enumerable = _receiver_attr_write_names(fnode)
        row = (
            _writes,
            _methods,
            _frees_root,
            _frees_other,
            _opaque or not _enumerable,
        )
        _DEF_FACTS[key] = row
        def_rows[(qualname, first_lineno)] = row
    _facts_cache_dump(source, literal_rows, def_rows)


def ensure_module_materialized(module_name: "str | None") -> None:
    """Materialize *module_name* through the single memoized parse site; an
    already-materialized module is an O(1) set lookup."""
    if not module_name:
        return
    _materialize_module(module_name)


def record_jit_decoration(func: Any) -> None:
    """Record the decorated *func*'s module: pending while PyIR is inactive
    (non-PyIR flows never pay a parse), materialized eagerly once active."""
    module_name = getattr(func, "__module__", None)
    if not isinstance(module_name, str) or not module_name:
        return
    if module_name in _MATERIALIZED_MODULES:
        return
    if _PYIR_ACTIVE:
        _materialize_module(module_name)
        return
    if module_name not in _PENDING_SET:
        _PENDING_SET.add(module_name)
        _PENDING_MODULES.append(module_name)


def register_class_fact_modules(*prefixes: str) -> None:
    """Declare DSL module/package prefixes: the call boundary classifies them
    as substrate; their write facts materialize lazily at each fact lookup."""
    _DECLARED_PREFIXES.update(prefixes)


def on_pyir_preprocess_session_start() -> None:
    """Materialize the pending decoration-recorded modules and mark PyIR
    active; all other modules parse lazily at their first fact lookup."""
    global _PYIR_ACTIVE
    _PYIR_ACTIVE = True
    if not _PENDING_MODULES:
        return
    pending = _PENDING_MODULES[:]
    _PENDING_MODULES.clear()
    _PENDING_SET.clear()
    for module_name in pending:
        _materialize_module(module_name)


# cls -> the MRO class defining ``__getattr__`` (None when absent); class
# protocol facts are definition-time facts, memoized like the parse rows.
_DUNDER_DEFINER_ABSENT: Any = _Sentinel("dunder definer absent")
_DUNDER_DEFINER_FACTS: "dict[tuple[type, str], Optional[type]]" = {}


def _mro_definer(cls: type, dunder: str) -> "Optional[type]":
    """Class-fact: the MRO class defining *dunder* for instances of *cls*,
    ``None`` when absent; memoized per ``(cls, dunder)``."""
    cached = _DUNDER_DEFINER_FACTS.get((cls, dunder), _DUNDER_DEFINER_ABSENT)
    if cached is not _DUNDER_DEFINER_ABSENT:
        return cached
    definer = None
    for klass in inspect.getmro(cls):
        if dunder in klass.__dict__:
            definer = klass
            break
    _DUNDER_DEFINER_FACTS[(cls, dunder)] = definer
    return definer


def getattr_fabrication_definer(cls: type) -> "Optional[type]":
    """Class-fact: the MRO class defining ``__getattr__`` for instances of
    *cls*, ``None`` when absent.  A failed attribute lookup on such instances
    FABRICATES a value with no storage slot (LangRef 3.12 section 3.3.2); for
    a metaclass *cls* the fabricated reads are on its classes."""
    return _mro_definer(cls, "__getattr__")


def del_finalizer_definer(cls: type) -> "Optional[type]":
    """Class-fact: the MRO class defining ``__del__`` for instances of *cls*,
    ``None`` when absent.  Finalization (LangRef 3.12 section 3.3.1,
    ``object.__del__``) runs at a garbage-collection-determined instant,
    which has no binding position in a traced program."""
    return _mro_definer(cls, "__del__")


_EXTRACT_SURFACE_ABSENT: Any = _Sentinel("extract surface absent")
# type -> frozenset of touched field names, or None (surface underivable).
_EXTRACT_SURFACE_FACTS: "dict[type, Optional[frozenset]]" = {}

# Calls whose result can reach the receiver's storage without a syntactic
# ``self.<attr>`` spelling: the touched-field set cannot be proven complete.
_SURFACE_OPAQUE_CALLS = frozenset(
    ("super", "getattr", "setattr", "delattr", "vars", "eval", "exec", "locals")
)


def _surface_def_ast(fn: Any) -> "Optional[ast.FunctionDef]":
    """The plain-def AST of *fn* (source parsed, never executed); ``None``
    when there is no source or the object is not a plain def."""
    if not isinstance(fn, types.FunctionType):
        return None
    try:
        tree = ast.parse(textwrap.dedent(inspect.getsource(fn)))
    except Exception:
        return None
    node = tree.body[0] if tree.body else None
    if not isinstance(node, ast.FunctionDef):
        return None
    return node


def _surface_collect(
    cls: type, fn: Any, touched: "set[str]", seen: "set[int]", depth: int
) -> bool:
    """Union *fn*'s receiver-attribute touches (every branch: reads, writes,
    method calls) into *touched*; recurse into receiver methods and touched
    properties so backing storage names join.  ``False`` when the receiver
    escapes the syntactic ``self.<attr>`` discipline (bare receiver use,
    dynamic attribute access, ``super()`` delegation) or a touched protocol
    leg cannot be followed: the set cannot be proven complete, so no fact
    may be produced."""
    if callable(fn):
        try:
            fn = inspect.unwrap(fn)  # decorator wrappers: follow the real def
        except Exception:
            return False
    if not isinstance(fn, types.FunctionType):
        return False
    # Cycle key: the resolved function object (wrapper code objects are
    # SHARED across distinct wrapped defs, so code identity under-visits).
    if id(fn) in seen:
        return True  # already unioned (cycle / repeated helper)
    if depth <= 0:
        return False
    seen.add(id(fn))
    node = _surface_def_ast(fn)
    if node is None or not node.args.args:
        return False
    recv = node.args.args[0].arg
    # Receiver Name nodes consumed as an Attribute root (the one licensed use).
    consumed: "set[int]" = set()
    names: "set[str]" = set()
    for sub in ast.walk(node):
        if isinstance(sub, ast.Call):
            if isinstance(sub.func, ast.Name) and sub.func.id in _SURFACE_OPAQUE_CALLS:
                return False
        if (
            isinstance(sub, ast.Attribute)
            and isinstance(sub.value, ast.Name)
            and sub.value.id == recv
        ):
            consumed.add(id(sub.value))
            if not sub.attr.startswith("__"):
                names.add(sub.attr)
    for sub in ast.walk(node):
        if isinstance(sub, ast.Name) and sub.id == recv and id(sub) not in consumed:
            return False  # bare receiver escape (call arg, return, rebind)
    touched.update(names)
    # Follow receiver methods and properties: their interior reads name the
    # backing storage the protocol depends on.
    for name in sorted(names):
        static = inspect.getattr_static(cls, name, _EXTRACT_SURFACE_ABSENT)
        if static is _EXTRACT_SURFACE_ABSENT or isinstance(static, type):
            continue  # instance storage / class data: the touch is the fact
        if isinstance(static, (types.MemberDescriptorType, types.GetSetDescriptorType)):
            continue  # __slots__ storage: the touch is the fact
        if isinstance(static, property):
            for leg in (static.fget, static.fset):
                if leg is not None and not _surface_collect(
                    cls, leg, touched, seen, depth - 1
                ):
                    return False
            continue
        if callable(static):
            if not _surface_collect(cls, static, touched, seen, depth - 1):
                return False
            continue
        if hasattr(type(static), "__get__"):
            return False  # a descriptor leg the walk cannot follow
    return True


def declared_extract_surface(cls: type) -> "Optional[frozenset]":
    """Class-fact: the instance-field names *cls*'s own
    ``__extract_mlir_values__`` touches (reads feeding or selecting its
    leaves, plus extraction-internal bookkeeping writes), or ``None`` when
    the surface is underivable.

    Derived from the protocol itself, statically: the extraction def's AST
    is unioned over every branch (a superset of any one execution), receiver
    method calls recurse, and a touched property contributes its getter's
    and setter's backing reads.  The extraction body is NEVER executed --
    observation must not run user code.  A shape the walk cannot prove
    complete (bare receiver escape, dynamic attribute access, ``super()``)
    yields ``None``: no fact, so the consumer admits the write."""
    cached = _EXTRACT_SURFACE_FACTS.get(cls, _EXTRACT_SURFACE_ABSENT)
    if cached is not _EXTRACT_SURFACE_ABSENT:
        return cached
    fn = None
    for klass in inspect.getmro(cls):
        fn = klass.__dict__.get("__extract_mlir_values__")
        if fn is not None:
            break
    touched: "set[str]" = set()
    result: "Optional[frozenset]" = None
    try:
        if _surface_collect(cls, fn, touched, set(), 8):
            result = frozenset(touched)
    except Exception:
        result = None
    _EXTRACT_SURFACE_FACTS[cls] = result
    return result


_HASH_OVERRIDE_ABSENT: Any = _Sentinel("hash override absent")
_HASH_OVERRIDE_FACTS: "dict[type, Optional[type]]" = {}


def staged_wrapper_hash_override(cls: type) -> "Optional[type]":
    """Class-fact: the MRO class whose ``__hash__`` SHADOWS a staged
    wrapper's own ``__hash__`` for instances of *cls*, ``None`` when absent.
    A wrapper's ``__hash__`` is a consumption/identity witness; a subclass
    override silently answers in its place, so hashing bypasses the witness.
    ``__hash__ = None`` is exempt: an unhashable subclass fails loudly."""
    cached = _HASH_OVERRIDE_FACTS.get(cls, _HASH_OVERRIDE_ABSENT)
    if cached is not _HASH_OVERRIDE_ABSENT:
        return cached
    result: "Optional[type]" = None
    mro = inspect.getmro(cls)
    definer_idx = -1
    for i, klass in enumerate(mro):
        if "__hash__" in klass.__dict__:
            definer_idx = i
            break
    if (
        definer_idx >= 0
        and mro[definer_idx] is not object
        and callable(mro[definer_idx].__dict__.get("__hash__"))
    ):
        for klass in mro[definer_idx + 1 :]:
            if "__hash__" not in klass.__dict__:
                continue
            # The entry the override shadows: a violation only when it is a
            # staged wrapper's own (callable) hash.
            if (
                klass is not object
                and callable(klass.__dict__.get("__hash__"))
                and callable(getattr(klass, "ir_value", None))
            ):
                result = mro[definer_idx]
            break
    _HASH_OVERRIDE_FACTS[cls] = result
    return result


def class_storage_items(cls: type) -> "dict[str, Any]":
    """Class-level DATA attributes of *cls* (own ``__dict__`` only): the
    class-attr places the boundary diff observes, with the CLASS object as
    owner (F-SHAPE). Descriptors (functions, properties, classmethods, slot
    members) and nested classes are protocol, not storage."""
    items: "dict[str, Any]" = {}
    for name, v in cls.__dict__.items():
        if not isinstance(name, str) or name.startswith("__"):
            continue
        if isinstance(v, type) or hasattr(type(v), "__get__"):
            continue
        items[name] = v
    return items


# Builtin predicates a transparent guard may call: pure, replay-stable.
_PURE_GUARD_CALLS = frozenset(("type", "isinstance", "len"))


def setattr_storage_transparent(fn: Any) -> bool:
    """Can the ``__setattr__`` override *fn* be proven to store only its
    UNMODIFIED value parameter (a storage redirect, e.g. into a dict field)?
    Only a transparent override may stay on the rewritten-choke store path:
    the choke's instrumentation re-binds REPLAY the override once per
    re-bind, so every replayed expression -- guards, store targets, slot
    keys -- must be side-effect-free, and the stored value must be the bare
    parameter.  ``False`` whenever the proof fails (no source, helper calls,
    computed stores, effectful guards)."""
    node = _surface_def_ast(fn)
    if node is None or len(node.args.args) != 3:
        return False
    value_param = node.args.args[2].arg

    def _bare_value(expr: "ast.expr") -> bool:
        return isinstance(expr, ast.Name) and expr.id == value_param

    def _simple(expr: "ast.expr") -> bool:
        if isinstance(expr, (ast.Name, ast.Constant)):
            return True
        if isinstance(expr, ast.Attribute):
            return _simple(expr.value)
        if isinstance(expr, ast.Subscript):
            return _simple(expr.value) and _simple(expr.slice)
        if isinstance(expr, ast.Tuple):
            return all(_simple(e) for e in expr.elts)
        if isinstance(expr, ast.UnaryOp):
            return _simple(expr.operand)
        if isinstance(expr, ast.BoolOp):
            return all(_simple(v) for v in expr.values)
        if isinstance(expr, ast.Compare):
            return _simple(expr.left) and all(_simple(c) for c in expr.comparators)
        if isinstance(expr, ast.Call):
            return (
                isinstance(expr.func, ast.Name)
                and expr.func.id in _PURE_GUARD_CALLS
                and not expr.keywords
                and all(_simple(a) for a in expr.args)
            )
        return False

    def _stmt_ok(st: "ast.stmt") -> bool:
        if isinstance(st, ast.If):
            return _simple(st.test) and all(_stmt_ok(s) for s in st.body + st.orelse)
        if isinstance(st, (ast.Raise, ast.Pass)):
            return True
        if isinstance(st, ast.Return):
            return st.value is None
        if isinstance(st, ast.Assign):
            return _bare_value(st.value) and all(_simple(t) for t in st.targets)
        if isinstance(st, ast.Expr):
            if isinstance(st.value, ast.Constant):
                return True  # docstring
            call = st.value
            return (
                isinstance(call, ast.Call)
                and isinstance(call.func, ast.Attribute)
                and call.func.attr == "__setattr__"
                and isinstance(call.func.value, ast.Name)
                and call.func.value.id == "object"
                and len(call.args) == 3
                and not call.keywords
                and _simple(call.args[0])
                and _simple(call.args[1])
                and _bare_value(call.args[2])
            )
        return False

    return all(_stmt_ok(s) for s in node.body)


# (def identity key, receiver type or None) -> (attr_writes, complete);
# memoized like the definer facts above (the substrate tables never re-parse).
_TRANSITIVE_WRITE_CACHE: "dict[tuple[tuple[str, str, int], Optional[type]], tuple[frozenset[str], bool]]" = {}


def transitive_write_facts(callee: Any) -> "tuple[frozenset[str], bool]":
    """Receiver-attribute write set of *callee*'s exact def closed over its
    resolvable call edges: ``(attr_writes, complete)``; under-approximates.
    Memoized per (def identity, receiver type): the walk reads the receiver
    only through ``type(recv).__mro__``, and the parse tables freeze at first
    materialization, so the closure is a definition-time fact of that pair."""
    func = getattr(callee, "__func__", callee)
    receiver = getattr(callee, "__self__", None)
    root_key = _def_fact_key(func)
    if root_key is None:
        return frozenset(), False
    cache_key = (root_key, type(receiver) if receiver is not None else None)
    cached = _TRANSITIVE_WRITE_CACHE.get(cache_key)
    if cached is not None:
        return cached
    ensure_module_materialized(root_key[0])
    root = _DEF_FACTS.get(root_key)
    if root is None:
        _TRANSITIVE_WRITE_CACHE[cache_key] = (frozenset(), False)
        return frozenset(), False
    writes: "set[str]" = set()
    complete = True
    seen: "set[tuple[str, str, int]]" = set()
    stack: "list[tuple[tuple[str, str, int], Any, Any]]" = [(root_key, func, receiver)]
    while stack:
        key, fobj, recv = stack.pop()
        if key in seen:
            continue
        seen.add(key)
        row = _DEF_FACTS.get(key)
        if row is None:
            complete = False
            continue
        row_writes, row_methods, row_frees_root, row_frees_other, row_incomplete = row
        writes.update(row_writes)
        if row_incomplete:
            complete = False
        for m in row_methods:
            target = None
            if recv is not None:
                for klass in type(recv).__mro__:
                    cand = klass.__dict__.get(m)
                    if cand is not None:
                        target = getattr(cand, "__func__", cand)
                        break
            if not callable(target):
                complete = False
                continue
            t_key = _def_fact_key(target)
            if t_key is None:
                complete = False
                continue
            ensure_module_materialized(t_key[0])
            stack.append((t_key, target, recv))
        fglobals = getattr(fobj, "__globals__", None) or {}
        for fname in row_frees_root | row_frees_other:
            target = fglobals.get(fname)
            target = getattr(target, "__func__", target)
            if not callable(target) or not hasattr(target, "__code__"):
                # No def row and no syntactic attribute writes (builtin / C
                # function); a dynamic setattr is the boundary diff's to observe.
                continue
            t_key = _def_fact_key(target)
            if t_key is None:
                continue
            if fname in row_frees_other:
                # The receiver is not provably the callee's first parameter
                # at (at least) one call site: those writes belong to ANOTHER
                # object, so merging them onto the root would promote
                # never-written fields.  The unattributable edge marks the
                # set incomplete; a root-first call site of the same name
                # still contributes below.
                complete = False
                if fname not in row_frees_root:
                    continue
            ensure_module_materialized(t_key[0])
            if t_key not in _DEF_FACTS:
                complete = False
                continue
            # A root-first-arg free call binds the ROOT as its first
            # parameter; its row contributes writes and keeps the root
            # receiver for its own method edges.
            stack.append((t_key, target, recv))
    result = (frozenset(writes), complete)
    _TRANSITIVE_WRITE_CACHE[cache_key] = result
    return result


# Static export surface (regenerate with scripts/gen_pyir_all.py): the
# module's OWN names -- its namespace minus what lower chain modules
# already export and minus the generator's INTERNAL_ONLY registry.
__all__ = [
    "ast",
    "hashlib",
    "inspect",
    "os",
    "sys",
    "tempfile",
    "textwrap",
    "types",
    "Any",
    "Optional",
    "_Sentinel",
    "_DECLARED_PREFIXES",
    "literal_attr_write_fact",
    "configure_facts_cache",
    "_materialize_module",
    "ensure_module_materialized",
    "record_jit_decoration",
    "register_class_fact_modules",
    "on_pyir_preprocess_session_start",
    "getattr_fabrication_definer",
    "del_finalizer_definer",
    "_EXTRACT_SURFACE_ABSENT",
    "_EXTRACT_SURFACE_FACTS",
    "_SURFACE_OPAQUE_CALLS",
    "_surface_def_ast",
    "_surface_collect",
    "declared_extract_surface",
    "_HASH_OVERRIDE_ABSENT",
    "_HASH_OVERRIDE_FACTS",
    "staged_wrapper_hash_override",
    "class_storage_items",
    "_PURE_GUARD_CALLS",
    "setattr_storage_transparent",
    "transitive_write_facts",
]
