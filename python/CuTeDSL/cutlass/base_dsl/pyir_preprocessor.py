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

"""
PyIR-specific DSL preprocessor.

This module defines the `PyIRDSLPreprocessor` class, which extends `DSLPreprocessor`
with PyIR-specific AST transformations for maintaining SSA form and proper scoping.
"""

import ast
import contextlib
import types
from collections.abc import Generator
from dataclasses import dataclass, field
from typing import Any, Callable
from typing_extensions import override

from .ast_preprocessor import (
    DSLPreprocessor,
    OrderedSet,
    Region,
    ScopeManager,
    _create_module_attribute,
    _ComprehensionT,
    _deepcopy_ast_root,
    SessionData,
)
from .common import DSLRuntimeError, DSLUserCodeError
from .diagnostics import DiagId
from .pyir_class_facts import (
    on_pyir_preprocess_session_start,
)

# Imported for its module-attribute side effect too: the rewritten-function
# preamble binds ``__pyir_runtime__ = __base_dsl__.pyir_runtime``, so the
# submodule must be loaded before any rewritten function runs.
from . import pyir_runtime

# Runtime-module alias bound once in every rewritten function's preamble:
# generated code names pyir_runtime symbols through their owning module.
_PYIR_RUNTIME_ALIAS = "__pyir_runtime__"

# Emission-time fact: a symbol referenced through the runtime alias must be
# one the pyir_runtime facade exports (its non-dunder module namespace: the
# facade re-exports the chain surface and carries no ``__all__`` of its own).
_PYIR_RUNTIME_EXPORTS = frozenset(
    n for n in vars(pyir_runtime) if not n.startswith("__")
)


def _create_runtime_attribute(
    func_name: str,
    *,
    lineno: "int | None" = None,
    col_offset: "int | None" = None,
) -> ast.Attribute:
    """``__pyir_runtime__.<func_name>`` with optional location info."""
    assert func_name in _PYIR_RUNTIME_EXPORTS, func_name
    base = ast.Name(id=_PYIR_RUNTIME_ALIAS, ctx=ast.Load())
    result = ast.Attribute(value=base, attr=func_name, ctx=ast.Load())
    if lineno is not None and col_offset is not None:
        for node in (base, result):
            node.lineno = lineno
            node.end_lineno = lineno
            node.col_offset = col_offset
            node.end_col_offset = col_offset
    return result


def _unparse_safe(node: ast.AST) -> str:
    """Best-effort ``ast.unparse`` -- falls back to the node class name
    when unparse trips on a synthetic node missing source attributes.
    """
    try:
        return ast.unparse(node)
    except Exception:
        return type(node).__name__


def _whole_name_rebound_names(body: "list[ast.stmt]") -> set[str]:
    """Bare names the statements in *body* REBIND as a whole (assign / augassign /
    for-target), lambda/nested-def bodies excluded; the list-carry promotion fact."""
    names: set[str] = set()

    def _record(t: "ast.expr") -> None:
        stack: "list[ast.expr]" = [t]
        while stack:
            n = stack.pop()
            if isinstance(n, (ast.Tuple, ast.List)):
                stack.extend(n.elts)
            elif isinstance(n, ast.Starred):
                stack.append(n.value)
            elif isinstance(n, ast.Name):
                names.add(n.id)

    stack: "list[ast.AST]" = list(body)
    while stack:
        node = stack.pop()
        if isinstance(node, (ast.Lambda, ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        if isinstance(node, ast.Assign):
            for t in node.targets:
                _record(t)
        elif isinstance(node, (ast.AugAssign, ast.AnnAssign)):
            _record(node.target)
        elif isinstance(node, (ast.For, ast.AsyncFor)):
            _record(node.target)
        stack.extend(ast.iter_child_nodes(node))
    return names


def _locally_bound_names(node: ast.AST) -> set[str]:
    """Names bound only in a nested comprehension/lambda scope inside *node*;
    a statement-scope hoist must never reference them."""
    bound: set[str] = set()
    for child in ast.walk(node):
        if isinstance(
            child, (ast.ListComp, ast.SetComp, ast.DictComp, ast.GeneratorExp)
        ):
            for gen in child.generators:
                for tgt in ast.walk(gen.target):
                    if isinstance(tgt, ast.Name) and isinstance(tgt.ctx, ast.Store):
                        bound.add(tgt.id)
        elif isinstance(child, ast.Lambda):
            args = child.args
            for arg in (
                *args.posonlyargs,
                *args.args,
                *args.kwonlyargs,
            ):
                bound.add(arg.arg)
            if args.vararg is not None:
                bound.add(args.vararg.arg)
            if args.kwarg is not None:
                bound.add(args.kwarg.arg)
    return bound


# Emission budget for one access chain's hop reads: chains are instrumented at
# their exact AST depth; a deeper chain refuses loudly instead of truncating.
_READ_CHAIN_HOP_BUDGET = 64


def _ast_node_depths(node: ast.AST) -> dict[int, int]:
    """Depth of every AST node id under *node*: a chain nested inside another
    chain's base (call argument, subscript key) has strictly greater depth."""
    depths: dict[int, int] = {}
    stack: list[tuple[ast.AST, int]] = [(node, 0)]
    while stack:
        cur, d = stack.pop()
        depths[id(cur)] = d
        for child in ast.iter_child_nodes(cur):
            stack.append((child, d + 1))
    return depths


def _deferred_execution_node_ids(node: ast.AST) -> set[int]:
    """Ids of AST nodes whose evaluation Python defers past the statement:
    lambda bodies and a genexp's lazy parts (elt / targets / ifs / inner iters)."""
    deferred: set[int] = set()
    for child in ast.walk(node):
        if isinstance(child, ast.Lambda):
            for sub in ast.walk(child.body):
                deferred.add(id(sub))
        elif isinstance(child, ast.GeneratorExp):
            for sub in ast.walk(child.elt):
                deferred.add(id(sub))
            for pos, gen in enumerate(child.generators):
                for sub in ast.walk(gen.target):
                    deferred.add(id(sub))
                if pos > 0:
                    for sub in ast.walk(gen.iter):
                        deferred.add(id(sub))
                for cond in gen.ifs:
                    for sub in ast.walk(cond):
                        deferred.add(id(sub))
    return deferred


@dataclass
class PyIRScopeManager(ScopeManager):
    """
    PyIR-specific scope manager that tracks variables to skip for PyIR instrumentation.

    Extends the base ScopeManager with functionality to mark variables that should NOT
    be instrumented with pyir_read/pyir_assign operations (e.g., loop induction variables).
    """

    # Variables that should NOT be instrumented with pyir_read/pyir_assign.
    # Currently: for-loop induction variables when _handle_negative_step
    # injects `idx = offset - idx if isNeg else idx`.
    skip_pyir_reference_taking: set[str]
    # Track which self.<attr> names have been assigned in current __init__.
    # First assignment is a definition (skip instrumentation); subsequent
    # assignments are mutations (instrument with pyir_assign).
    seen_init_attrs: set[str]

    @classmethod
    def create(cls) -> "PyIRScopeManager":
        return cls([], [], set(), set())

    def add_skip_reference_taking(self, name: str) -> None:
        """Mark *name* so pyir_read/pyir_assign are NOT emitted for it."""
        self.skip_pyir_reference_taking.add(name)

    def remove_skip_reference_taking(self, name: str) -> None:
        self.skip_pyir_reference_taking.discard(name)

    def is_skip_reference_taking(self, name: str) -> bool:
        return name in self.skip_pyir_reference_taking

    @contextlib.contextmanager
    def enter_local_scope(self) -> Generator[None, None, None]:
        """
        Override to save/restore skip_pyir_reference_taking state across scopes.
        """
        self.scopes.append(set())
        self.callables.append(set())
        saved_skip = self.skip_pyir_reference_taking
        self.skip_pyir_reference_taking = set()
        saved_init_attrs = self.seen_init_attrs
        self.seen_init_attrs = set()
        yield
        self.scopes.pop()
        self.callables.pop()
        self.skip_pyir_reference_taking = saved_skip
        self.seen_init_attrs = saved_init_attrs


@dataclass
class PyIRSessionData(SessionData):
    """
    PyIR-specific session data.
    """

    scope_manager: PyIRScopeManager = field(default_factory=PyIRScopeManager.create)
    # Synthetic live-out carry name per loop node, keyed by ``id(node)`` so
    # nested loops don't collide; forces a body-entry promotion of the carry.
    liveout_loop_carried_vars: dict[int, str] = field(default_factory=dict)


def _collect_direct_attr_write_pairs(body: "list[ast.stmt]") -> "set[tuple[str, str]]":
    """``(base, attr)`` pairs the statements in *body* assign directly with a
    Name-rooted base; a nested target (``c.sub.n``) records the dotted base
    (``("c.sub", "n")``).  Lambda/nested-def bodies excluded (they bind at
    call time)."""
    pairs: "set[tuple[str, str]]" = set()

    def _record(t: "ast.expr") -> None:
        stack: "list[ast.expr]" = [t]
        while stack:
            n = stack.pop()
            if isinstance(n, (ast.Tuple, ast.List)):
                stack.extend(n.elts)
            elif isinstance(n, ast.Starred):
                stack.append(n.value)
            elif isinstance(n, ast.Attribute):
                base = _name_rooted_receiver_path(n.value)
                if base is not None:
                    pairs.add((base, n.attr))

    stack: "list[ast.AST]" = list(body)
    while stack:
        node = stack.pop()
        if isinstance(node, (ast.Lambda, ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        if isinstance(node, ast.Assign):
            for t in node.targets:
                _record(t)
        elif isinstance(node, (ast.AugAssign, ast.AnnAssign)):
            _record(node.target)
        elif isinstance(node, (ast.For, ast.AsyncFor)):
            _record(node.target)
        stack.extend(ast.iter_child_nodes(node))
    return pairs


def _name_rooted_receiver_path(node: "ast.expr") -> "str | None":
    """Dotted receiver path when *node* is a Name-rooted attribute chain
    (``a`` or ``a.b.c``); ``None`` for any other receiver shape."""
    parts: "list[str]" = []
    while isinstance(node, ast.Attribute):
        parts.append(node.attr)
        node = node.value
    if not isinstance(node, ast.Name):
        return None
    parts.append(node.id)
    return ".".join(reversed(parts))


def _collect_receiver_method_call_pairs(
    body: "list[ast.stmt]",
) -> "set[tuple[str, str]]":
    """``(base, method)`` pairs the statements in *body* call with a Name-rooted
    receiver path (``base.method(...)``, ``root.attr.method(...)``); the base is
    the dotted path.  Lambda/nested-def bodies excluded (they bind at call
    time).  The callee's receiver-attr write facts complete each pair into
    region write facts at region entry."""
    pairs: "set[tuple[str, str]]" = set()
    stack: "list[ast.AST]" = list(body)
    while stack:
        node = stack.pop()
        if isinstance(node, (ast.Lambda, ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        if isinstance(node, ast.Call):
            f = node.func
            if isinstance(f, ast.Attribute):
                base = _name_rooted_receiver_path(f.value)
                if base is not None:
                    pairs.add((base, f.attr))
        stack.extend(ast.iter_child_nodes(node))
    return pairs


def _collect_free_call_arg_pairs(
    body: "list[ast.stmt]",
) -> "set[tuple[str, str]]":
    """``(func_name, arg_base)`` pairs the statements in *body* call as a
    bare-Name free function with a Name-rooted first argument (``step(c)``);
    lambda/nested-def bodies excluded (they bind at call time).  The callee's
    first-parameter write facts complete each pair into region write facts at
    region entry."""
    pairs: "set[tuple[str, str]]" = set()
    stack: "list[ast.AST]" = list(body)
    while stack:
        node = stack.pop()
        if isinstance(node, (ast.Lambda, ast.FunctionDef, ast.AsyncFunctionDef)):
            continue
        if isinstance(node, ast.Call):
            f = node.func
            if isinstance(f, ast.Name) and node.args:
                base = _name_rooted_receiver_path(node.args[0])
                if base is not None:
                    pairs.add((f.id, base))
        stack.extend(ast.iter_child_nodes(node))
    return pairs


# F-COVER: version of the choke set this preprocessor emits.  Stamped as
# ``__pyir_rewritten__`` on every rewritten function object; bump on any
# change to the emitted choke vocabulary so stale rewrites fail attestation.
PYIR_CHOKE_SET_VERSION: int = 6


def _own_scope_nonlocal_names(body: "list[ast.stmt]") -> "list[str]":
    """Names declared ``nonlocal`` by THIS function's own statements, in
    first-seen order; nested function/class scopes declare for themselves."""
    names: "list[str]" = []
    queue: "list[ast.AST]" = list(body)
    i = 0
    while i < len(queue):
        stmt = queue[i]
        i += 1
        if isinstance(
            stmt, (ast.FunctionDef, ast.AsyncFunctionDef, ast.Lambda, ast.ClassDef)
        ):
            continue
        if isinstance(stmt, ast.Nonlocal):
            for n in stmt.names:
                if n not in names:
                    names.append(n)
            continue
        queue.extend(ast.iter_child_nodes(stmt))
    return names


class _ScopeBindingCollector(ast.NodeVisitor):
    """Collect the names ONE function scope binds anywhere in its body
    (CPython symbol-table locality rule), without descending into nested
    function/class/lambda scopes or comprehension scopes."""

    def __init__(self) -> None:
        self.bound: set[str] = set()
        self.declared_global: set[str] = set()
        self.declared_nonlocal: set[str] = set()

    def visit_Name(self, node: ast.Name) -> None:
        if isinstance(node.ctx, (ast.Store, ast.Del)):
            self.bound.add(node.id)

    def visit_FunctionDef(self, node: ast.FunctionDef) -> None:
        self.bound.add(node.name)  # the def binds its name; its body is a new scope

    def visit_AsyncFunctionDef(self, node: "ast.AsyncFunctionDef") -> None:
        self.bound.add(node.name)

    def visit_ClassDef(self, node: ast.ClassDef) -> None:
        self.bound.add(node.name)

    def visit_Lambda(self, node: ast.Lambda) -> None:
        pass  # inner scope

    def visit_ListComp(self, node: ast.ListComp) -> None:
        pass  # comprehension targets live in their own scope

    visit_SetComp = visit_ListComp  # type: ignore[assignment]
    visit_DictComp = visit_ListComp  # type: ignore[assignment]
    visit_GeneratorExp = visit_ListComp  # type: ignore[assignment]

    def visit_Import(self, node: ast.Import) -> None:
        for alias in node.names:
            self.bound.add((alias.asname or alias.name).split(".")[0])

    def visit_ImportFrom(self, node: ast.ImportFrom) -> None:
        for alias in node.names:
            self.bound.add(alias.asname or alias.name)

    def visit_ExceptHandler(self, node: ast.ExceptHandler) -> None:
        if node.name:
            self.bound.add(node.name)
        self.generic_visit(node)

    def visit_MatchAs(self, node: "ast.MatchAs") -> None:
        if node.name:
            self.bound.add(node.name)
        self.generic_visit(node)

    def visit_MatchStar(self, node: "ast.MatchStar") -> None:
        if node.name:
            self.bound.add(node.name)
        self.generic_visit(node)

    def visit_Global(self, node: ast.Global) -> None:
        self.declared_global.update(node.names)

    def visit_Nonlocal(self, node: ast.Nonlocal) -> None:
        self.declared_nonlocal.update(node.names)


def _function_scope_bindings(
    fn_node: "ast.FunctionDef | ast.AsyncFunctionDef",
) -> set[str]:
    """All names *fn_node*'s scope owns anywhere in its body: parameters plus
    collected bindings, minus ``global`` declarations; a name the scope itself
    declares ``nonlocal`` resolves further up a chain CPython already
    validated when the user's module compiled, so it also counts as owned."""
    collector = _ScopeBindingCollector()
    for stmt in fn_node.body:
        collector.visit(stmt)
    args = fn_node.args
    for arg in args.posonlyargs + args.args + args.kwonlyargs:
        collector.bound.add(arg.arg)
    if args.vararg is not None:
        collector.bound.add(args.vararg.arg)
    if args.kwarg is not None:
        collector.bound.add(args.kwarg.arg)
    return (collector.bound | collector.declared_nonlocal) - collector.declared_global


def _is_synthetic_call(func_node: ast.expr) -> bool:
    """True for a direct preprocessor-emitted helper invocation (an
    attribute chain rooted at ``__base_dsl__``/``__module_dsl__`` or the
    runtime-module alias).  A call WHOSE CALLEE is such a helper call is a
    user call over a choke-produced value and stays wrapped;
    machinery-built outer calls mark themselves ``_pyir_synth`` at
    construction."""
    node = func_node
    while isinstance(node, ast.Attribute):
        node = node.value
    return isinstance(node, ast.Name) and node.id in (
        "__base_dsl__",
        "__module_dsl__",
        _PYIR_RUNTIME_ALIAS,
    )


class _CallBoundaryWrapPass(ast.NodeTransformer):
    """Post-instrumentation pass turning ``f(args)`` into
    ``_pyir_call_boundary_(f)(args)`` (the pyir_runtime dispatcher, bound as
    an alias in the rewritten-function preamble) after the main visitor, so
    no pattern matcher sees the wrapper; synthetic calls skipped, and
    conditioned short-circuit operands carry the ``sc_rhs`` fact."""

    _SHORT_CIRCUIT_HELPERS = ("and_", "or_")

    # Bare-name builtin calls the MAIN VISITOR emits in synthetic statements
    # (marked ``_pyir_synth`` where they carry user expressions) plus builtins
    # whose behavior depends on the calling frame (``super``) or that are pure
    # w.r.t. tracked places, so wrapping them only adds dispatch cost.
    _BARE_BUILTIN_SKIP = frozenset({"range", "type", "super", "locals"})

    # Zero-arg frame-reflection builtins: rewritten to the position-aware
    # ``_pyir_traced_locals`` choke (the synthesized-scope fact is a rewrite-
    # time fact, so it is passed as a constant at emission).
    _FRAME_REFLECTION_BUILTINS = frozenset({"locals", "vars"})

    # Dispatcher alias bound once at function entry (one local/closure load per
    # wrapped call); a nested CLASS body uses the module-attribute form instead.
    ALIAS_NAME = "_pyir_call_boundary_"

    def __init__(self) -> None:
        super().__init__()
        self._sc_depth = 0
        self._class_depth = 0
        # Scope-kind stack over nested defs/lambdas met in the body: True for
        # a preprocessor-SYNTHESIZED scope (arm/body block defs), False for a
        # user-authored nested scope (its locals() is its own frame -- truth).
        self._scope_synth: list[bool] = []
        self.wrapped_any = False
        # Identity memo: each node OBJECT is transformed exactly once.  On a
        # proper tree this never fires; if the input degenerates to a DAG a
        # re-entered node returns its first result instead of being re-wrapped
        # once per path (the memo value pins the key object, keeping ids
        # stable for the pass lifetime).
        self._memo: dict[int, tuple[ast.AST, ast.AST]] = {}

    def visit(self, node: ast.AST) -> Any:
        entry = self._memo.get(id(node))
        if entry is not None and entry[0] is node:
            return entry[1]
        result = super().visit(node)
        self._memo[id(node)] = (node, result)
        return result

    def run_on_function_body(self, func_def: ast.FunctionDef) -> bool:
        """Wrap calls in *func_def*'s BODY only (decorators/defaults evaluate
        outside the alias's scope); True when at least one call was wrapped."""
        func_def.body = [self.visit(stmt) for stmt in func_def.body]
        return self.wrapped_any

    def visit_ClassDef(self, node: ast.ClassDef) -> ast.ClassDef:
        self._class_depth += 1
        try:
            self.generic_visit(node)
        finally:
            self._class_depth -= 1
        return node

    def _visit_scope(self, node: Any) -> Any:
        """Visit a nested def/lambda: decorators and argument defaults evaluate
        in the ENCLOSING scope; only the body runs in the new scope."""
        if hasattr(node, "decorator_list"):
            node.decorator_list = [self.visit(d) for d in node.decorator_list]
        args = node.args
        args.defaults = [self.visit(d) for d in args.defaults]
        args.kw_defaults = [
            self.visit(d) if d is not None else None for d in args.kw_defaults
        ]
        self._scope_synth.append(getattr(node, "_pyir_synth_scope", False))
        try:
            if isinstance(node, ast.Lambda):
                node.body = self.visit(node.body)
            else:
                node.body = [self.visit(stmt) for stmt in node.body]
        finally:
            self._scope_synth.pop()
        return node

    def visit_FunctionDef(self, node: ast.FunctionDef) -> ast.FunctionDef:
        return self._visit_scope(node)

    def visit_AsyncFunctionDef(
        self, node: ast.AsyncFunctionDef
    ) -> ast.AsyncFunctionDef:
        return self._visit_scope(node)

    def visit_Lambda(self, node: ast.Lambda) -> ast.Lambda:
        return self._visit_scope(node)

    @staticmethod
    def _short_circuit_helper_name(func: ast.expr) -> bool:
        # ``__module_dsl__.and_`` / bare ``and_`` (module-attribute form
        # emitted by visit_BoolOp).
        if isinstance(func, ast.Attribute):
            return func.attr in _CallBoundaryWrapPass._SHORT_CIRCUIT_HELPERS
        if isinstance(func, ast.Name):
            return func.id in _CallBoundaryWrapPass._SHORT_CIRCUIT_HELPERS
        return False

    def _wrap_frame_reflection(self, node: ast.Call) -> ast.Call:
        """``locals()`` / zero-arg ``vars()`` -> ``_pyir_traced_locals(
        locals(), locals, <in_synth>)``: the mapping still evaluates in the
        calling frame; the callee load lets the choke verify the builtin
        (a shadowed name passes through); the synthesized-scope fact is a
        rewrite-time constant."""
        node._pyir_synth = True  # type: ignore[attr-defined]
        callee_name = node.func.id  # type: ignore[attr-defined]
        callee_load = ast.copy_location(ast.Name(id=callee_name, ctx=ast.Load()), node)
        in_synth = bool(self._scope_synth and self._scope_synth[-1])
        wrapper = ast.Call(
            func=_create_module_attribute(
                "_pyir_traced_locals",
                submodule_name="pyir_runtime",
                lineno=getattr(node, "lineno", None),
                col_offset=getattr(node, "col_offset", None),
            ),
            args=[node, callee_load, ast.Constant(value=in_synth)],
            keywords=[],
        )
        return ast.copy_location(wrapper, node)

    def visit_Call(self, node: ast.Call) -> ast.Call:
        if self._short_circuit_helper_name(node.func) and len(node.args) >= 2:
            # First operand is unconditioned (Python evaluates it always);
            # the remaining operands are the short-circuited RHS.
            node.args[0] = self.visit(node.args[0])
            self._sc_depth += 1
            try:
                node.args[1:] = [self.visit(a) for a in node.args[1:]]
                node.keywords = [self.visit(kw) for kw in node.keywords]
            finally:
                self._sc_depth -= 1
            return node
        self.generic_visit(node)
        if getattr(node, "_pyir_synth", False):
            return node
        if _is_synthetic_call(node.func):
            return node
        if (
            isinstance(node.func, ast.Name)
            and node.func.id in self._FRAME_REFLECTION_BUILTINS
            and not node.args
            and not node.keywords
        ):
            return self._wrap_frame_reflection(node)
        if isinstance(node.func, ast.Name) and node.func.id in self._BARE_BUILTIN_SKIP:
            return node
        wrap_args: list[ast.expr] = [node.func]
        if self._sc_depth > 0:
            wrap_args.append(ast.Constant(value=True))
        if self._class_depth == 0:
            wrap_func: ast.expr = ast.Name(id=self.ALIAS_NAME, ctx=ast.Load())
            ast.copy_location(wrap_func, node)
        else:
            wrap_func = _create_module_attribute(
                "_pyir_call_boundary_",
                submodule_name="pyir_runtime",
                lineno=getattr(node, "lineno", None),
                col_offset=getattr(node, "col_offset", None),
            )
        node.func = ast.copy_location(
            ast.Call(
                func=wrap_func,
                args=wrap_args,
                keywords=[],
            ),
            node,
        )
        self.wrapped_any = True
        return node


class PyIRDSLPreprocessor(DSLPreprocessor):
    """
    A DSL preprocessor with PyIR-specific transformations.

    This derived class adds PyIR instrumentation for:
    - Maintaining SSA form through pyir_read/pyir_assign operations
    - Scope isolation for const_expr control flow
    - Attribute read instrumentation to prevent reference leakage
    - Tuple unpacking decomposition
    """

    # F-COVER carrier: the rewrite point stamps this version on the function
    # object; the base (non-PyIR) preprocessor advertises no choke set.
    choke_set_version: "int | None" = PYIR_CHOKE_SET_VERSION

    @override
    def _start_session(self) -> None:
        # Materialize decoration-recorded per-class self-field write facts before
        # any PyIR tracing, so the registry is complete when a region consults it.
        on_pyir_preprocess_session_start()
        super()._start_session()

    @override
    def _create_session_data(self) -> SessionData:
        return PyIRSessionData()

    @property
    def session_data(self) -> PyIRSessionData:
        sd = super().session_data
        assert isinstance(sd, PyIRSessionData)
        return sd

    @override
    def _create_closure_check_call(
        self, called_closures: list[str], node: ast.stmt
    ) -> ast.Expr | None:
        # PyIR's ref mechanism handles captured variables correctly —
        # pyir_read/pyir_assign inside the closure create refs that
        # PYIRToSCF promotes to iter_args, so the check is unnecessary.
        return None

    def _refuse_construct(self, diag: DiagId, node: ast.AST) -> None:
        """Curated refusal for a construct the rewrite cannot compile."""
        raise DSLUserCodeError(
            diag,
            filename=self.session_data.file_name,
            lineno=getattr(node, "lineno", None),
            col_offset=getattr(node, "col_offset", None),
            end_col_offset=getattr(node, "end_col_offset", None),
        )

    # A generator or coroutine body never runs at its call site (calling only
    # mints the generator/coroutine object), so a rewritten def containing one
    # of these constructs would compile to a body the trace can never observe.
    # The wall is a PyIR-mode fact: the base rewrite compiles these constructs
    # exactly as before.
    def visit_Yield(self, node: ast.Yield) -> None:
        self._refuse_construct(DiagId.UNSUP_YIELD, node)

    def visit_YieldFrom(self, node: ast.YieldFrom) -> None:
        self._refuse_construct(DiagId.UNSUP_YIELD, node)

    def visit_AsyncFunctionDef(self, node: "ast.AsyncFunctionDef") -> None:
        self._refuse_construct(DiagId.UNSUP_ASYNC, node)

    def visit_Await(self, node: "ast.Await") -> None:
        self._refuse_construct(DiagId.UNSUP_ASYNC, node)

    def visit_AsyncFor(self, node: "ast.AsyncFor") -> None:
        self._refuse_construct(DiagId.UNSUP_ASYNC, node)

    def visit_AsyncWith(self, node: "ast.AsyncWith") -> None:
        self._refuse_construct(DiagId.UNSUP_ASYNC, node)

    def visit_TryStar(self, node: ast.AST) -> None:
        self._refuse_construct(DiagId.UNSUP_EXCEPT_STAR, node)

    # Innermost-last stack of the function defs being visited: the whole-scope
    # owner table for ``nonlocal`` name resolution (a PyIR-mode fact; the base
    # rewrite resolves nonlocal from the visitation position only).
    _function_scope_stack: "tuple[ast.FunctionDef, ...]" = ()

    def visit_Nonlocal(self, node: ast.Nonlocal) -> ast.Nonlocal:
        active_symbols = self.session_data.scope_manager.get_active_symbols()
        nonlocal_names = OrderedSet(node.names)
        intersect = nonlocal_names.intersections(active_symbols)
        # Ownership is a whole-scope fact: an enclosing scope's binding owns
        # the name even when it appears textually after this nested def.
        enclosing_bindings: "list[set[str]] | None" = None
        for name in node.names:
            if name in intersect:
                continue
            if enclosing_bindings is None:
                enclosing_bindings = [
                    _function_scope_bindings(fn)
                    for fn in self._function_scope_stack[:-1]
                ]
            if any(name in bound for bound in enclosing_bindings):
                continue
            raise DSLUserCodeError(
                DiagId.UNSUP_NONLOCAL,
                filename=self.session_data.file_name,
                lineno=getattr(node, "lineno", None),
                col_offset=getattr(node, "col_offset", None),
                end_col_offset=getattr(node, "end_col_offset", None),
                stmt=ast.unparse(node),
                name=name,
            )
        self.generic_visit(node)
        return node

    def _expand_boolop_evaluate_once(self, node: ast.BoolOp) -> ast.expr:
        # Visit child nodes first
        self.generic_visit(node)

        # Short-circuit evaluation expands explicitly, like the base rewrite,
        # but in the evaluate-once form (a PyIR-mode fact: the call-boundary
        # post-pass re-visits shared nodes, so the emitted module must stay a
        # tree, and a watched meta bool must evaluate its producer once).
        if isinstance(node.op, ast.And):
            # Emitted form (one lhs evaluation, Python short-circuit):
            # tmp if bool_short_circuits((tmp := lhs), False) else and_(tmp, rhs)
            short_circuit_value = ast.Constant(value=False)
            self.session_data.import_top_module = True
        elif isinstance(node.op, ast.Or):
            # Emitted form (one lhs evaluation, Python short-circuit):
            # tmp if bool_short_circuits((tmp := lhs), True) else or_(tmp, rhs)
            short_circuit_value = ast.Constant(value=True)
            self.session_data.import_top_module = True
        else:
            # BoolOp should be either And or Or -- reaching here is a compiler
            # bug (the AST grammar only produces And/Or), not an author mistake.
            raise DSLRuntimeError(
                f"Unsupported boolean operation: {node.op}",
                filename=self.session_data.file_name,
                snippet=ast.unparse(node),
            )

        # Evaluate-once lowering: the lhs binds to a synthesized temp INSIDE
        # the test (a named expression), so every synthesized position reads
        # that one evaluation -- the re-evaluating form runs the lhs per
        # position and deepcopies it per chain link (super-linear on chains,
        # and a side-effecting lhs fires more than once).  The test asks
        # ``bool_short_circuits`` whether the temp is a Python-truth bool (a
        # plain bool or a watched meta bool) equal to the short-circuit
        # value; only the non-short-circuit arm evaluates the rhs, exactly
        # like Python.  Every synthesized node is built fresh per position
        # (the emitted module must stay a tree).
        helper_name = "and_" if isinstance(node.op, ast.And) else "or_"
        sc_value = short_circuit_value.value

        lhs = node.values[0]
        for i in range(1, len(node.values)):
            tmp_name = f"_pyir_bool_{self.session_data.counter}"
            self.session_data.counter += 1
            test = ast.Call(
                func=_create_module_attribute(
                    "bool_short_circuits",
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    ast.NamedExpr(
                        target=ast.Name(id=tmp_name, ctx=ast.Store()),
                        value=lhs,
                    ),
                    ast.Constant(value=sc_value),
                ],
                keywords=[],
            )
            lhs = ast.copy_location(
                ast.IfExp(
                    test=ast.copy_location(test, node),
                    body=ast.Name(id=tmp_name, ctx=ast.Load()),
                    orelse=ast.Call(
                        func=_create_module_attribute(
                            helper_name,
                            use_base_dsl=False,
                            submodule_name=None,
                            lineno=node.lineno,
                            col_offset=node.col_offset,
                        ),
                        args=[
                            ast.Name(id=tmp_name, ctx=ast.Load()),
                            node.values[i],
                        ],
                        keywords=[],
                    ),
                ),
                node,
            )

        return ast.fix_missing_locations(lhs)

    def check_early_exit(self, tree: ast.AST, kind: str) -> None:
        """
        Checks if a given region or scope in the provided Python code has early
        exits.  Local-catch awareness is a PyIR-mode fact: a ``raise`` in the
        try suite of a region-local try/except is offered to that try's
        handlers before it can unwind out, so it is not an early exit.
        """

        class EarlyExitChecker(ast.NodeVisitor):
            def __init__(self, kind: str) -> None:
                self.has_early_exit = False
                self.early_exit_node: ast.AST | None = None
                self.early_exit_type: str | None = None
                self.kind = kind
                self.loop_nest_level = 0
                self.guarded_try_depth = 0

            def visit_Return(self, node: ast.Return) -> None:
                self.has_early_exit = True
                self.early_exit_node = node
                self.early_exit_type = "return"

            def visit_Raise(self, node: ast.Raise) -> None:
                # A raise in the try suite of a region-local try/except is
                # offered to that try's handlers before it can unwind out.
                if self.guarded_try_depth > 0:
                    return
                self.has_early_exit = True
                self.early_exit_node = node
                self.early_exit_type = "raise"

            def visit_Try(self, node: ast.Try) -> None:
                # Only the try suite is guarded; handler/else/finally bodies
                # are not caught by this statement's own except clauses.
                if node.handlers:
                    self.guarded_try_depth += 1
                for stmt in node.body:
                    self.visit(stmt)
                if node.handlers:
                    self.guarded_try_depth -= 1
                for handler in node.handlers:
                    self.visit(handler)
                for stmt in node.orelse:
                    self.visit(stmt)
                for stmt in node.finalbody:
                    self.visit(stmt)

            def visit_Break(self, node: ast.Break) -> None:
                if self.loop_nest_level == 0 and self.kind != "if":
                    self.has_early_exit = True
                    self.early_exit_node = node
                    self.early_exit_type = "break"

            def visit_Continue(self, node: ast.Continue) -> None:
                if self.loop_nest_level == 0 and self.kind != "if":
                    self.has_early_exit = True
                    self.early_exit_node = node
                    self.early_exit_type = "continue"

            def visit_For(self, node: ast.For) -> None:
                self.loop_nest_level += 1
                self.generic_visit(node)
                self.loop_nest_level -= 1

            def visit_While(self, node: ast.While) -> None:
                self.loop_nest_level += 1
                self.generic_visit(node)
                self.loop_nest_level -= 1

            def visit_FunctionDef(self, node: ast.FunctionDef) -> None:
                return

        checker = EarlyExitChecker(kind)
        checker.generic_visit(tree)
        if not checker.has_early_exit:
            return
        where = f"`{self.session_data.function_name}`" + (
            f" in `{self.session_data.class_name}`"
            if self.session_data.class_name
            else ""
        )
        offender = checker.early_exit_node or tree
        raise DSLUserCodeError(
            DiagId.UNSUP_EARLY_EXIT,
            filename=self.session_data.file_name,
            lineno=getattr(offender, "lineno", None),
            col_offset=getattr(offender, "col_offset", None),
            end_col_offset=getattr(offender, "end_col_offset", None),
            kind=checker.early_exit_type,
            where=where,
        )

    def _visit_stmts_in_cf_scope(
        self, stmts: list[ast.stmt], collect_bindings: "set[str] | None" = None
    ) -> list[ast.stmt]:
        """Visit statements in an isolated scope for const_expr branches.

        Used when visiting bodies of ``const_expr`` if/for/while — meta-level
        control flow where only one branch executes at runtime.

        The scope isolation gates INSTRUMENTATION only: a sibling branch must
        not see this branch's first-definitions (it would wrap its own
        first-def as a reassignment and pre-read an unbound name).  The
        BINDING fact itself survives — the caller collects this branch's
        first-defs via *collect_bindings* and re-adds the union to the
        enclosing scope after every arm is visited, so a later region's
        write_args ∩ active_symbols keeps the carried name (Python truth:
        the selected arm binds it).

        Outer-scope variables still work::

            x = Int32(0)              # x in outer scope
            if const_expr(True):
                x = Int32(42)         # reassignment — outer x IS visible,
                                      #   so pyir_assign IS emitted (correct)
        """
        with self.session_data.scope_manager.enter_control_flow_scope():
            result: list[ast.stmt] = []
            # Statement-insertion region for THIS body: hoists emitted while
            # visiting these statements (walrus lowering, read/effect anchors)
            # must land inside the const_expr body, not in the enclosing
            # statement list where they would execute unconditionally (a
            # never-taken arm's side effect) or before the loop (an unbound
            # induction variable).
            with Region(self.session_data, new_value=result):
                for stmt in stmts:
                    visited = self.visit(stmt)
                    if isinstance(visited, list):
                        result.extend(visited)
                    elif visited is not None:
                        result.append(visited)
            if collect_bindings is not None:
                collect_bindings |= self.session_data.scope_manager.scopes[-1]
            return result

    def _readd_constexpr_arm_bindings(self, born: "set[str]") -> None:
        """R5c: after every arm of a const_expr statement is visited, its
        arm-born bindings rejoin the enclosing scope as declared facts."""
        for name in born:
            self.session_data.scope_manager.add_to_scope(name)

    def _handle_constexpr_for(self, node: ast.For) -> ast.For | list[ast.stmt]:
        """Override to add PyIR scope isolation for const_expr loops, and
        to bracket the body with ``enter_constexpr_loop()`` /
        ``exit_constexpr_loop()`` calls so the M->M and container-
        mutation guards know the body is trace-time-unrolled (not
        loop-carried) even when the enclosing CF is dynamic.
        """
        # A constexpr induction var is a fresh Meta int per iteration; skip-reference
        # it so a name colliding with an earlier slot doesn't resurrect it.
        induction_names = self._constexpr_induction_names(node.target)
        already_skipped = {
            name
            for name in induction_names
            if self.session_data.scope_manager.is_skip_reference_taking(name)
        }
        for name in induction_names:
            self.session_data.scope_manager.add_skip_reference_taking(name)
        born: set[str] = set()
        try:
            # Visit loop body in its own scope so first-definitions inside
            # the body don't leak into the outer scope (PyIR only).
            node.body = self._visit_stmts_in_cf_scope(node.body, collect_bindings=born)
        finally:
            for name in induction_names - already_skipped:
                self.session_data.scope_manager.remove_skip_reference_taking(name)
        self._readd_constexpr_arm_bindings(born - induction_names)

        # Wrap the unrolled body: enter; try: body; finally: exit.  The
        # per-iteration bracket keeps the constexpr scope open inside the
        # body, with break / return / exception safety.
        node.body = self._wrap_body_in_constexpr_scope(node, node.body)
        return node

    @staticmethod
    def _constexpr_induction_names(target: ast.expr) -> set[str]:
        """Collect the bare ``Name`` ids bound by a ``for`` target (tuple targets
        included) so every rebound induction name is shielded."""
        names: set[str] = set()
        if isinstance(target, ast.Name):
            names.add(target.id)
        elif isinstance(target, (ast.Tuple, ast.List)):
            for elt in target.elts:
                if isinstance(elt, ast.Name):
                    names.add(elt.id)
        return names

    # Names of the ``base_dsl.ast_helpers`` callbacks the preprocessor
    # emits to bracket a constexpr-governed loop/branch body.
    _ENTER_CONSTEXPR_LOOP = "enter_constexpr_loop"
    _EXIT_CONSTEXPR_LOOP = "exit_constexpr_loop"

    def _wrap_body_in_constexpr_scope(
        self, node: ast.stmt, body: list[ast.stmt]
    ) -> list[ast.stmt]:
        """Bracket *body* with ``enter_constexpr_loop()`` /
        ``exit_constexpr_loop()`` so the M->M and container-mutation
        guards treat mutations directly inside the body as
        constexpr-governed (not dynamically loop-carried).  Returns
        *body* unchanged when empty (an empty ``try`` body is invalid).
        """
        if not body:
            return body

        lineno = node.lineno
        col_offset = node.col_offset

        def _call(name: str) -> ast.Expr:
            return ast.copy_location(
                ast.fix_missing_locations(
                    ast.Expr(
                        value=ast.Call(
                            func=_create_module_attribute(
                                name, lineno=lineno, col_offset=col_offset
                            ),
                            args=[],
                            keywords=[],
                        )
                    )
                ),
                node,
            )

        return [
            _call(self._ENTER_CONSTEXPR_LOOP),
            ast.copy_location(
                ast.fix_missing_locations(
                    ast.Try(
                        body=body,
                        handlers=[],
                        orelse=[],
                        finalbody=[_call(self._EXIT_CONSTEXPR_LOOP)],
                    )
                ),
                node,
            ),
        ]

    # Function-name prefixes the preprocessor synthesizes for loops / branches.
    # These helper functions must NOT open a user-function scope -- they inherit
    # their enclosing user function's scope so a loop-carried local (carried
    # through generated loop-body functions) stays on ONE slot key.
    _GENERATED_FN_PREFIXES = (
        "loop_body_",
        "while_region_",
        "while_before_block_",
        "while_after_block_",
        "if_region_",
        "ifexp_then_block_",
        "ifexp_else_block_",
        "then_block_",
        "else_block_",
        "elif_region_",
    )

    @staticmethod
    def _scope_cellvar_names(node: ast.AST) -> "list[str]":
        """Names bound at *node*'s scope level and referenced inside a nested
        scope (def / lambda / comprehension / class body): the frame's closure
        cellvars.  Over-approximation is transparent (the registration lambda
        itself closes over the name); global-declared names resolve as globals
        in the lambda and self-filter at registration."""
        bound: "set[str]" = set()
        nested_refs: "set[str]" = set()
        args = getattr(node, "args", None)
        if args is not None:
            for a in (*args.posonlyargs, *args.args, *args.kwonlyargs):
                bound.add(a.arg)
            if args.vararg is not None:
                bound.add(args.vararg.arg)
            if args.kwarg is not None:
                bound.add(args.kwarg.arg)
        _nested_kinds = (
            ast.FunctionDef,
            ast.AsyncFunctionDef,
            ast.Lambda,
            ast.ClassDef,
            ast.ListComp,
            ast.SetComp,
            ast.DictComp,
            ast.GeneratorExp,
        )

        def _walk(n: ast.AST, in_nested: bool) -> None:
            for child in ast.iter_child_nodes(n):
                if isinstance(child, ast.Name):
                    if in_nested:
                        nested_refs.add(child.id)
                    elif isinstance(child.ctx, (ast.Store, ast.Del)):
                        bound.add(child.id)
                elif not in_nested and isinstance(
                    child, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)
                ):
                    bound.add(child.name)
                elif not in_nested and isinstance(child, ast.Global):
                    bound.difference_update(child.names)
                elif not in_nested and isinstance(child, (ast.Import, ast.ImportFrom)):
                    for alias in child.names:
                        bound.add((alias.asname or alias.name).split(".")[0])
                # `except ... as name` and match capture patterns are binding
                # forms too; their targets are str fields, not Store Names.
                elif not in_nested and isinstance(
                    child, (ast.ExceptHandler, ast.MatchAs, ast.MatchStar)
                ):
                    if child.name is not None:
                        bound.add(child.name)
                elif not in_nested and isinstance(child, ast.MatchMapping):
                    if child.rest is not None:
                        bound.add(child.rest)
                _walk(child, in_nested or isinstance(child, _nested_kinds))

        for stmt in getattr(node, "body", []):
            if isinstance(stmt, ast.Name):
                continue
            _walk(stmt, isinstance(stmt, _nested_kinds))
            if isinstance(stmt, (ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
                bound.add(stmt.name)
        return sorted(bound & nested_refs)

    def _scope_cell_registration_stmt(
        self, node: "ast.FunctionDef"
    ) -> "ast.Expr | None":
        """The ``pyir_register_scope_cells(lambda: (c1, ..))`` entry statement
        for *node*, or ``None`` when the scope owns no cells.  The lambda's
        ``__closure__`` exposes the frame's cell objects without evaluating
        any cellvar (creation never touches the bindings).  The scope's own
        ``nonlocal`` names ride the same probe: their freevar cells ARE the
        enclosing scope's cells, so registration exposes the shared identity."""
        cell_names = self._scope_cellvar_names(node)
        for n in _own_scope_nonlocal_names(node.body):
            if n not in cell_names:
                cell_names.append(n)
        if not cell_names:
            return None
        probe = ast.Lambda(
            args=ast.arguments(
                posonlyargs=[],
                args=[],
                kwonlyargs=[],
                kw_defaults=[],
                defaults=[],
            ),
            body=ast.Tuple(
                elts=[ast.Name(id=n, ctx=ast.Load()) for n in cell_names],
                ctx=ast.Load(),
            ),
        )
        stmt = ast.Expr(
            value=ast.Call(
                func=_create_runtime_attribute(
                    "pyir_register_scope_cells",
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[probe],
                keywords=[],
            )
        )
        return ast.copy_location(ast.fix_missing_locations(stmt), node)

    def _wrap_body_in_fn_scope(
        self, node: ast.stmt, body: list[ast.stmt]
    ) -> list[ast.stmt]:
        """Bracket a USER function body with ``pyir_enter_fn(<id>)`` /
        ``pyir_exit_fn()`` so frame-local slot keys are qualified by the owning
        user function (preventing same-named locals in two different functions
        from colliding on one ``pyir.ref``).  ``<id>`` is ``id(node)`` -- unique
        per ``FunctionDef`` and stable for the preprocessing pass.  Generated
        loop / branch helper functions are not wrapped (see ``visit_FunctionDef``)
        so they inherit this scope at runtime."""
        if not body:
            return body

        lineno = node.lineno
        col_offset = node.col_offset

        def _call(name: str, args: list[ast.expr]) -> ast.Expr:
            return ast.copy_location(
                ast.fix_missing_locations(
                    ast.Expr(
                        value=ast.Call(
                            func=_create_runtime_attribute(
                                name, lineno=lineno, col_offset=col_offset
                            ),
                            args=args,
                            keywords=[],
                        )
                    )
                ),
                node,
            )

        # F-CEPLACE: parameters are DECLARED outside-born at scope entry (the
        # seeding is the fact producer; absence is never defaulted).
        args = getattr(node, "args", None)
        param_names: "list[str]" = []
        if args is not None:
            for a in (*args.posonlyargs, *args.args, *args.kwonlyargs):
                param_names.append(a.arg)
            if args.vararg is not None:
                param_names.append(args.vararg.arg)
            if args.kwarg is not None:
                param_names.append(args.kwarg.arg)
        entry_calls: "list[ast.stmt]" = [
            _call("pyir_enter_fn", [ast.Constant(value=id(node))])
        ]
        if param_names:
            entry_calls.append(
                _call(
                    "pyir_seed_param_bindings",
                    [ast.Constant(value=n) for n in param_names],
                )
            )
        # DECLARE the function's own ``nonlocal`` names on the scope (syntactic
        # fact): a bare-name choke then recognizes closure-cell bindings.
        nonlocal_names = _own_scope_nonlocal_names(body)
        if nonlocal_names:
            entry_calls.append(
                _call(
                    "pyir_register_nonlocal_names",
                    [ast.Constant(value=n) for n in nonlocal_names],
                )
            )
        # A parameter binding IS this scope's first-def: re-home a binding
        # routed to another scope's live row onto this scope's own row.
        if args is not None:
            for a in (*args.posonlyargs, *args.args, *args.kwonlyargs):
                entry_calls.append(
                    ast.copy_location(
                        ast.fix_missing_locations(
                            ast.Assign(
                                targets=[ast.Name(id=a.arg, ctx=ast.Store())],
                                value=ast.Call(
                                    func=_create_runtime_attribute(
                                        "pyir_bind_param",
                                        lineno=lineno,
                                        col_offset=col_offset,
                                    ),
                                    args=[
                                        ast.Constant(value=a.arg),
                                        ast.Name(id=a.arg, ctx=ast.Load()),
                                    ],
                                    keywords=[],
                                ),
                            )
                        ),
                        node,
                    )
                )
        return entry_calls + [
            ast.copy_location(
                ast.fix_missing_locations(
                    ast.Try(
                        body=body,
                        handlers=[],
                        orelse=[],
                        finalbody=[_call("pyir_exit_fn", [])],
                    )
                ),
                node,
            ),
        ]

    # >0 while visiting a def nested inside the outermost one: a nested def
    # compiles from this same instrumented AST, so the dispatcher fast-exits it.
    _pyir_fn_def_depth: int = 0

    @override
    def visit_FunctionDef(
        self, node: ast.FunctionDef
    ) -> "ast.FunctionDef | list[ast.stmt]":
        """Wrap USER function bodies with ``pyir_enter_fn`` / ``pyir_exit_fn`` so
        local slot keys are unique per user function.  Generated loop / branch
        helper functions are skipped -- they inherit the enclosing user scope."""
        _saved_class_depth = self._pyir_class_body_depth
        self._pyir_class_body_depth = 0
        self._pyir_fn_def_depth += 1
        self._pyir_import_scope_stack = self._pyir_import_scope_stack + (
            self._scope_import_bindings(node),
        )
        # This def's whole body is one scope of the nonlocal owner table.
        self._function_scope_stack = self._function_scope_stack + (node,)
        try:
            result = super().visit_FunctionDef(node)
        finally:
            self._pyir_fn_def_depth -= 1
            self._pyir_class_body_depth = _saved_class_depth
            self._pyir_import_scope_stack = self._pyir_import_scope_stack[:-1]
            self._function_scope_stack = self._function_scope_stack[:-1]
        if isinstance(result, ast.FunctionDef):
            # Register the frame's closure cells at entry (user AND generated
            # fns own cells); generated region fns register on the inherited
            # scope, matching where their locals' slot keys resolve.
            _cell_reg = self._scope_cell_registration_stmt(result)
            if _cell_reg is not None:
                result.body.insert(0, _cell_reg)
            # Region-synthesized defs (created by the CF outliners, never
            # revisited here) own the carry-param cells nested closures
            # capture; register them so cell identity resolves to the row.
            for _fd in ast.walk(result):
                if (
                    isinstance(_fd, ast.FunctionDef)
                    and getattr(_fd, "_pyir_synth_scope", False)
                    and not getattr(_fd, "_pyir_cells_registered", False)
                ):
                    _fd._pyir_cells_registered = True  # type: ignore[attr-defined]
                    _synth_reg = self._scope_cell_registration_stmt(_fd)
                    if _synth_reg is not None:
                        _fd.body.insert(0, _synth_reg)
        if isinstance(result, ast.FunctionDef) and not result.name.startswith(
            self._GENERATED_FN_PREFIXES
        ):
            result.body = self._wrap_body_in_fn_scope(result, result.body)
            # A nested user def's writes already commit through the instrumented
            # chokes; mark its runtime object so the dispatcher fast-exits it.
            # The stamp applies as the INNERMOST decorator so it attests exactly
            # the raw function object compiled from this instrumented AST — a
            # decorator wrapper around it is never attested (its uninstrumented
            # writes stay visible to the boundary observer), and an
            # undecoratable decoration result (e.g. ``@property``) never
            # receives a post-decoration attribute store.
            if self._pyir_fn_def_depth > 0:
                stamp = _create_runtime_attribute(
                    "_pyir_stamp_rewritten",
                    lineno=result.lineno,
                    col_offset=result.col_offset,
                )
                result.decorator_list.append(stamp)
                ast.fix_missing_locations(result)
        return result

    @override
    def _post_visit_function_body(self, func_def: ast.FunctionDef) -> "list[ast.stmt]":
        """Bind the runtime-module alias once at function entry (every
        emitted choke call resolves through it; nested regions close over
        it), then run the call-boundary wrap pass; when any call was
        wrapped, also bind the dispatcher alias the same way."""
        stmts: "list[ast.stmt]" = [
            ast.Assign(
                targets=[ast.Name(id=_PYIR_RUNTIME_ALIAS, ctx=ast.Store())],
                value=_create_module_attribute("pyir_runtime", submodule_name=None),
            )
        ]
        if _CallBoundaryWrapPass().run_on_function_body(func_def):
            stmts.append(
                ast.Assign(
                    targets=[
                        ast.Name(id=_CallBoundaryWrapPass.ALIAS_NAME, ctx=ast.Store())
                    ],
                    value=_create_runtime_attribute("_pyir_call_boundary_"),
                )
            )
        return stmts

    # >0 while visiting a CLASS body's immediate statements: an ``AnnAssign``
    # there is a field declaration and must not decompose to an assignment.
    _pyir_class_body_depth: int = 0

    # One (bound, plain-import-only, from-import-only) name frame per function
    # scope being visited; import-only names classify as module spellings,
    # from-import-only names as symbol-rooted reads (the global-read contract).
    _pyir_import_scope_stack: "tuple[tuple[frozenset, frozenset, frozenset], ...]" = ()

    @staticmethod
    def _scope_import_bindings(
        node: ast.AST,
    ) -> "tuple[frozenset, frozenset, frozenset]":
        """(names bound at *node*'s scope level, the subset bound ONLY by plain
        ``import`` statements, the subset bound ONLY by ``from`` imports).
        Every plain-import binding is a module object (LangRef 3.12 section
        7.11), so those names classify as module spellings for the read chokes;
        a from-import binding is a symbol read off its source module, so its
        attr reads classify like function-scope global-object reads.  Any other
        binding construct on the name disqualifies it (over-approximation of
        "other" is transparent: the name keeps its ordinary-local class)."""
        imported: "set[str]" = set()
        from_imported: "set[str]" = set()
        other: "set[str]" = set()
        args = getattr(node, "args", None)
        if args is not None:
            for a in (*args.posonlyargs, *args.args, *args.kwonlyargs):
                other.add(a.arg)
            if args.vararg is not None:
                other.add(args.vararg.arg)
            if args.kwarg is not None:
                other.add(args.kwarg.arg)
        _nested_scopes = (
            ast.FunctionDef,
            ast.AsyncFunctionDef,
            ast.Lambda,
            ast.ClassDef,
        )

        def _walk(n: ast.AST) -> None:
            for child in ast.iter_child_nodes(n):
                if isinstance(child, ast.Import):
                    for alias in child.names:
                        imported.add(alias.asname or alias.name.split(".")[0])
                elif isinstance(child, ast.ImportFrom):
                    for alias in child.names:
                        from_imported.add(alias.asname or alias.name)
                elif isinstance(child, ast.Name) and isinstance(
                    child.ctx, (ast.Store, ast.Del)
                ):
                    other.add(child.id)
                elif isinstance(child, (ast.Global, ast.Nonlocal)):
                    other.update(child.names)
                elif isinstance(child, ast.ExceptHandler) and child.name:
                    other.add(child.name)
                elif isinstance(child, (ast.MatchAs, ast.MatchStar)) and child.name:
                    other.add(child.name)
                elif isinstance(child, ast.MatchMapping) and child.rest:
                    other.add(child.rest)
                elif isinstance(child, _nested_scopes):
                    name = getattr(child, "name", None)
                    if name is not None:
                        other.add(name)
                    continue  # a nested scope's own bindings stay its own
                _walk(child)

        _walk(node)
        return (
            frozenset(imported | from_imported | other),
            frozenset(imported - from_imported - other),
            frozenset(from_imported - imported - other),
        )

    def _pyir_from_import_bound(self, name: str) -> bool:
        """True when *name*, in its nearest binding scope, is bound ONLY by
        ``from``-import statements: its attr reads take the symbol-rooted
        record-only choke (the function-scope global-object read contract)."""
        for bound, _imported, from_imported in reversed(self._pyir_import_scope_stack):
            if name in from_imported:
                return True
            if name in bound:
                return False
        return False

    def visit_Import(self, node: ast.Import) -> "ast.stmt | list[ast.stmt]":
        """Bracket an in-body ``import`` with the staged-CF wall and the F-SPEC
        record arm: the import executes once at trace (LangRef 3.12 section
        7.11), so inside dynamic staged CF the wall refuses BEFORE the module's
        side effects run; in meta flow every bound name records a verified
        spec root (a plain import binds only modules)."""
        pairs = [
            (alias.name, alias.asname or alias.name.split(".")[0])
            for alias in node.names
        ]
        return self._pyir_wrap_import(node, None, 0, pairs)

    def visit_ImportFrom(self, node: ast.ImportFrom) -> "ast.stmt | list[ast.stmt]":
        """``from``-import twin of :py:meth:`visit_Import`: the record arm
        re-derives each bound value off the resolved source module (scalars
        pin value rows, objects root for their leaf reads)."""
        pairs = [(alias.name, alias.asname or alias.name) for alias in node.names]
        return self._pyir_wrap_import(node, node.module, node.level, pairs)

    def _pyir_reading_package(self) -> "str | None":
        """The defining module's declared package (``__package__``, falling
        back to ``__spec__.parent`` -- LangRef 3.12 section 5.4.2): a
        rewrite-time constant anchoring relative-import resolution."""
        g = self.session_data.function_globals
        if not g:
            return None
        pkg = g.get("__package__")
        if isinstance(pkg, str):
            return pkg
        parent = getattr(g.get("__spec__"), "parent", None)
        return parent if isinstance(parent, str) else None

    def _pyir_wrap_import(
        self,
        node: ast.stmt,
        module: "str | None",
        level: int,
        pairs: "list[tuple[str, str]]",
    ) -> "ast.stmt | list[ast.stmt]":
        """[guard, import, record] bracket for one import statement; the native
        statement itself is untouched (Python truth for binding semantics)."""
        if getattr(node, "_pyir_import_wrapped", False):
            return node
        node._pyir_import_wrapped = True  # type: ignore[attr-defined]
        package = self._pyir_reading_package() if level else None
        guard: ast.stmt = ast.Expr(
            value=ast.Call(
                func=_create_runtime_attribute(
                    "_pyir_import_guard",
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    ast.Constant(value=ast.unparse(node)),
                    ast.Constant(value=module),
                    ast.Constant(value=level),
                    ast.Constant(value=package),
                    *(ast.Constant(value=public) for public, _bound in pairs),
                ],
                keywords=[],
            )
        )
        record: ast.stmt = ast.Expr(
            value=ast.Call(
                func=_create_runtime_attribute(
                    "_pyir_import_record",
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    ast.Constant(value=module),
                    ast.Constant(value=level),
                    ast.Constant(value=package),
                    *(
                        ast.Tuple(
                            elts=[
                                ast.Constant(value=public),
                                ast.Name(id=bound, ctx=ast.Load()),
                            ],
                            ctx=ast.Load(),
                        )
                        for public, bound in pairs
                    ),
                ],
                keywords=[],
            )
        )
        return [
            ast.copy_location(ast.fix_missing_locations(guard), node),
            node,
            ast.copy_location(ast.fix_missing_locations(record), node),
        ]

    def visit_ClassDef(self, node: ast.ClassDef) -> ast.AST:
        """Run a class body in its own PyIR scope so a field annotation does not
        leak into the enclosing function scope and mask a local's first-def."""
        self._pyir_class_body_depth += 1
        try:
            with self.session_data.scope_manager.enter_local_scope():
                return super().visit_ClassDef(node)
        finally:
            self._pyir_class_body_depth -= 1

    def visit_With(self, node: ast.With) -> ast.AST:
        """Route each context expression through the ctx boundary: ``with``
        runs its dunders outside ``ast.Call``, invisible to the call wrap."""
        result = super().visit_With(node)  # scope registration + child visits
        if isinstance(result, ast.With):
            for item in result.items:
                item.context_expr = ast.copy_location(
                    ast.Call(
                        func=_create_runtime_attribute(
                            "_pyir_ctx_boundary",
                            lineno=getattr(item.context_expr, "lineno", 0),
                            col_offset=getattr(item.context_expr, "col_offset", 0),
                        ),
                        args=[item.context_expr],
                        keywords=[],
                    ),
                    item.context_expr,
                )
            ast.fix_missing_locations(result)
        return result

    def _prepare_loop_induction_var(
        self,
        node: ast.For,
        target_is_live_after_loop: bool = False,
        loop_carried_var_name: str | None = None,
    ) -> None:
        """Skip instrumentation of the induction target (a ref on the block
        argument would not dominate), and record the synthetic live-out carry."""
        if isinstance(node.target, ast.Name):
            self.session_data.scope_manager.add_skip_reference_taking(node.target.id)
        if target_is_live_after_loop and loop_carried_var_name is not None:
            # Write-only in the body, so record it for the prologue's forced
            # promotion and scope it so the body write stores into that cell.
            self.session_data.liveout_loop_carried_vars[id(node)] = (
                loop_carried_var_name
            )
            self.session_data.scope_manager.add_to_scope(loop_carried_var_name)

    def _cleanup_loop_induction_var(self, node: ast.For) -> None:
        """Override to remove skip flag after loop function creation."""
        if isinstance(node.target, ast.Name):
            self.session_data.scope_manager.remove_skip_reference_taking(node.target.id)
        self.session_data.liveout_loop_carried_vars.pop(id(node), None)

    def _is_element_in_scope(self, elt: ast.expr) -> bool:
        """Check if a single tuple element needs pyir instrumentation."""
        if isinstance(elt, ast.Name):
            active = self.session_data.scope_manager.get_active_symbols()
            return any(elt.id in scope for scope in active)
        if isinstance(elt, ast.Attribute):
            # Same __init__ first-def skip as _is_target_in_scope.
            if (
                self.session_data.function_name == "__init__"
                and isinstance(elt.value, ast.Name)
                and elt.value.id == "self"
            ):
                attr_key = f"self.{elt.attr}"
                if attr_key not in self.session_data.scope_manager.seen_init_attrs:
                    self.session_data.scope_manager.seen_init_attrs.add(attr_key)
                    return False
            return True
        if isinstance(elt, ast.Subscript):
            if self._is_subscript_skippable(elt):
                return False
            return True
        # Nested tuples, starred: not instrumented
        return False

    def _is_target_in_scope(self, target: ast.expr) -> bool:
        """Return True if target is a variable already defined in scope.

        Only returns True for simple Names and Attributes that are
        already tracked by the scope manager.  Returns False for:
        - Tuple unpacking where no element is in scope
        - First-time definitions (not yet in scope)
        - Variables in skip_pyir_reference_taking (e.g. loop induction variables)
        """
        if isinstance(target, (ast.Tuple, ast.List)):
            return any(self._is_element_in_scope(elt) for elt in target.elts)
        if isinstance(target, ast.Name):
            if self.session_data.scope_manager.is_skip_reference_taking(target.id):
                return False
            active = self.session_data.scope_manager.get_active_symbols()
            return any(target.id in scope for scope in active)
        if isinstance(target, ast.Attribute):
            # In __init__, the first self.<attr> = val is a definition —
            # the attribute doesn't exist on the object yet. Skip
            # instrumentation. Subsequent assignments to the same attr
            # ARE instrumented.
            if (
                self.session_data.function_name == "__init__"
                and isinstance(target.value, ast.Name)
                and target.value.id == "self"
            ):
                attr_key = f"self.{target.attr}"
                if attr_key not in self.session_data.scope_manager.seen_init_attrs:
                    self.session_data.scope_manager.seen_init_attrs.add(attr_key)
                    return False  # first-def — skip
            return True  # reassignment — instrument
        if isinstance(target, ast.Subscript):
            if self._is_subscript_skippable(target):
                return False
            return True
        return False

    @staticmethod
    def _is_subscript_skippable(node: ast.Subscript) -> bool:
        """Return True if this subscript can never be dict-style.

        Slice subscripts (``arr[0:4]``) and tuple subscripts
        (``arr[i, j]``) are GPU array operations -- skip them at AST
        time to avoid any runtime overhead.
        """
        return isinstance(node.slice, (ast.Slice, ast.Tuple))

    @staticmethod
    def _is_meta_primitive_literal(node: ast.expr) -> bool:
        """Return True if *node* is a bare Python-primitive literal.

        Used by the first-def-attr instrumentation to skip ``self.X = 2192``
        style init lines while still firing for ``self.X = Int32(...)`` /
        ``Boolean(...)`` (whose RHS is a Call).
        """
        return isinstance(node, ast.Constant) and isinstance(
            node.value, (bool, int, float, str, bytes, type(None))
        )

    @staticmethod
    def _is_subscript_read_skippable(node: ast.Subscript) -> bool:
        """Return True for subscript reads that cannot be dict-style.

        Integer/float/bool constants (``arr[0]``, ``arr[1]``) are GPU
        array indexing, not dict reads.  Only string-constant subscripts
        (``d["key"]``) may be dict reads and need instrumentation.
        """
        return isinstance(node.slice, ast.Constant) and not isinstance(
            node.slice.value, str
        )

    def _is_subscript_dict_style(self, node: ast.Subscript) -> bool:
        """Return True for dict-style subscripts ``d['key']`` whose base is in scope.

        Only string-constant keys are supported.  Integer/variable subscripts
        (tensor[i], array[idx]) are genuine memory ops handled by MLIR and do
        not need PyIR SSA carry.
        """
        if (
            isinstance(node.slice, ast.Constant)
            and isinstance(node.slice.value, str)
            and isinstance(node.value, ast.Name)
        ):
            active = self.session_data.scope_manager.get_active_symbols()
            return any(node.value.id in scope for scope in active)
        return False

    @staticmethod
    def _walrus_stored_names(value: ast.expr) -> list[str]:
        """Names walrus'd anywhere in a statement's value expression
        (lambda subtrees are opaque: their walrus binds lambda-locally)."""
        names: list[str] = []
        _scan_stack: list[ast.AST] = [value]
        while _scan_stack:
            n = _scan_stack.pop()
            if isinstance(n, ast.Lambda):
                continue
            if isinstance(n, ast.NamedExpr) and isinstance(n.target, ast.Name):
                if n.target.id not in names:
                    names.append(n.target.id)
            _scan_stack.extend(ast.iter_child_nodes(n))
        return names

    def _hoist_pre_walrus_reads(self, node: ast.stmt, value: "ast.expr | None") -> None:
        """Statement-top read anchors for pre-walrus reads (Python evaluation order)."""
        if (
            value is None
            or self._pyir_lambda_depth
            or not self.session_data.region_stack
        ):
            return
        walrus_names = self._walrus_stored_names(value)
        if not walrus_names:
            return
        anchor_by_read_id: dict[int, str] = {}
        anchor_stmts: list[ast.stmt] = []
        for name in walrus_names:
            reads: list[ast.Name] = []

            def _walk(n: ast.AST) -> bool:
                """DFS in field order (Python evaluation order for the
                expression forms allowed here); True = walrus reached."""
                if isinstance(n, ast.Lambda):
                    return False
                if (
                    isinstance(n, ast.NamedExpr)
                    and isinstance(n.target, ast.Name)
                    and n.target.id == name
                ):
                    return True
                if (
                    isinstance(n, ast.Name)
                    and isinstance(n.ctx, ast.Load)
                    and n.id == name
                ):
                    reads.append(n)
                    return False
                for child in ast.iter_child_nodes(n):
                    if _walk(child):
                        return True
                return False

            _walk(value)
            if not reads or not self._is_target_in_scope(
                ast.Name(id=name, ctx=ast.Store())
            ):
                continue
            anchor = f"_pyir_wpre_{self.session_data.counter}"
            self.session_data.counter += 1
            anchor_call = ast.Call(
                func=_create_runtime_attribute(
                    "_pyir_anchor_statement_read",
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[ast.Name(id=name, ctx=ast.Load())],
                keywords=[],
            )
            anchor_assign = ast.Assign(
                targets=[ast.Name(id=anchor, ctx=ast.Store())],
                value=anchor_call,
            )
            anchor_stmts.append(
                ast.copy_location(ast.fix_missing_locations(anchor_assign), node)
            )
            for r in reads:
                anchor_by_read_id[id(r)] = anchor
        if not anchor_stmts:
            return

        class _RewritePreWalrusReads(ast.NodeTransformer):
            def visit_Name(self, n: ast.Name) -> ast.Name:
                repl = anchor_by_read_id.get(id(n))
                if repl is not None:
                    return ast.copy_location(ast.Name(id=repl, ctx=ast.Load()), n)
                return n

            def visit_Lambda(self, n: ast.Lambda) -> ast.Lambda:
                return n  # opaque

        _RewritePreWalrusReads().visit(node)
        ast.fix_missing_locations(node)
        # Before the walrus's own hoisted assign (visit_NamedExpr appends
        # during the statement's generic_visit, which runs after this).
        self.session_data.region_stack[-1].append_new_stmts(anchor_stmts)

    def _hoist_pre_walrus_augassign_base(self, node: ast.AugAssign) -> "str | None":
        """Statement-top anchor for the implicit base read of ``name op= value``
        when *value* walrus-rebinds ``name``.  Python loads the base BEFORE
        evaluating the RHS, but the walrus lowers to an assign hoisted ahead of
        the statement, so a statement-position base read would see the
        post-walrus value.  Returns the anchor temp for
        ``_insert_pyir_augassign`` to consume as the in-place-op base; the
        statement-position ``pyir_read`` refresh still runs (staged-slot load
        semantics for the store's own old-value capture)."""
        if (
            self._pyir_lambda_depth
            or not self.session_data.region_stack
            or not isinstance(node.target, ast.Name)
            or not self._is_target_in_scope(node.target)
            or node.target.id not in self._walrus_stored_names(node.value)
        ):
            return None
        anchor = f"_pyir_wbase_{self.session_data.counter}"
        self.session_data.counter += 1
        anchor_call = ast.Call(
            func=_create_runtime_attribute(
                "_pyir_anchor_statement_read",
                lineno=node.lineno,
                col_offset=node.col_offset,
            ),
            args=[ast.Name(id=node.target.id, ctx=ast.Load())],
            keywords=[],
        )
        anchor_assign = ast.Assign(
            targets=[ast.Name(id=anchor, ctx=ast.Store())],
            value=anchor_call,
        )
        # Before the walrus's own hoisted assign (visit_NamedExpr appends
        # during the statement's generic_visit, which runs after this).
        self.session_data.region_stack[-1].append_new_stmts(
            [ast.copy_location(ast.fix_missing_locations(anchor_assign), node)]
        )
        return anchor

    def _hoist_pre_walrus_effects(
        self, node: ast.stmt, value: "ast.expr | None"
    ) -> None:
        """Statement-top effect anchors (Python evaluation order): a call that
        completes BEFORE the first walrus in *value* is hoisted into a temp, in
        completion order, so the walrus lowering's own hoist cannot move it
        after the walrus's write.  A call the anchor cannot represent
        order-faithfully — one in a conditionally-evaluated position before a
        walrus, or one completing between two walruses — refuses loudly
        (never silently reordered)."""
        if (
            value is None
            or self._pyir_lambda_depth
            or not self.session_data.region_stack
        ):
            return
        # Effect units in completion (post-DFS) order == Python effect order.
        events: "list[tuple[str, ast.AST, bool]]" = []

        def _contains_call(n: ast.AST) -> bool:
            return any(isinstance(sub, ast.Call) for sub in ast.walk(n))

        def _scan(n: ast.AST, conditional: bool) -> None:
            if isinstance(n, (ast.Lambda, ast.GeneratorExp)):
                return  # deferred execution: not this statement's effects
            if isinstance(n, (ast.ListComp, ast.SetComp, ast.DictComp)):
                # Eager comprehension: one opaque effect unit when it can call.
                if _contains_call(n):
                    events.append(("call", n, conditional))
                return
            if isinstance(n, ast.BoolOp):
                _scan(n.values[0], conditional)
                for v in n.values[1:]:
                    _scan(v, True)
                return
            if isinstance(n, ast.IfExp):
                _scan(n.test, conditional)
                _scan(n.body, True)
                _scan(n.orelse, True)
                return
            for child in ast.iter_child_nodes(n):
                _scan(child, conditional)
            if isinstance(n, ast.NamedExpr):
                events.append(("walrus", n, conditional))
            elif isinstance(n, ast.Call):
                events.append(("call", n, conditional))

        _scan(value, False)
        walrus_positions = [i for i, (k, _, _) in enumerate(events) if k == "walrus"]
        if not walrus_positions:
            return
        first_w, last_w = walrus_positions[0], walrus_positions[-1]

        def _refuse(call_node: ast.AST, walrus_node: ast.AST) -> None:
            target = getattr(walrus_node, "target", None)
            raise DSLUserCodeError(
                DiagId.UNSUP_WALRUS_EVAL_ORDER,
                filename=self.session_data.file_name,
                lineno=getattr(call_node, "lineno", None),
                col_offset=getattr(call_node, "col_offset", None),
                end_col_offset=getattr(call_node, "end_col_offset", None),
                call=_unparse_safe(call_node),
                name=target.id
                if isinstance(target, ast.Name)
                else _unparse_safe(walrus_node),
            )

        anchors: "list[ast.AST]" = []
        for i, (kind, n, conditional) in enumerate(events):
            if kind != "call":
                continue
            if i < first_w:
                if conditional:
                    _refuse(n, events[first_w][1])
                anchors.append(n)
            elif i < last_w:
                # Completes between two walruses: the lowering would run it
                # after every hoisted walrus assign.
                nxt = next(j for j in walrus_positions if j > i)
                _refuse(n, events[nxt][1])
        if not anchors:
            return
        # Only outermost units hoist; an inner call evaluates inside its
        # enclosing anchored unit, so order is preserved within.
        outer = [
            c
            for c in anchors
            if not any(
                c2 is not c and any(sub is c for sub in ast.walk(c2)) for c2 in anchors
            )
        ]
        replace_by_id: "dict[int, str]" = {}
        for c in outer:
            temp = f"_pyir_weff_{self.session_data.counter}"
            self.session_data.counter += 1
            assign = ast.copy_location(
                ast.Assign(
                    targets=[ast.copy_location(ast.Name(id=temp, ctx=ast.Store()), c)],
                    value=c,  # type: ignore[arg-type]
                ),
                node,
            )
            ast.fix_missing_locations(assign)
            # The synthetic temp is machinery-owned (no pyir_assign choke),
            # but the hoisted VALUE still visits: its reads and call-boundary
            # instrumentation execute at the anchor position, as Python does.
            self.session_data.scope_manager.add_skip_reference_taking(temp)
            visited = self.visit(assign)
            self.session_data.region_stack[-1].append_new_stmts(
                visited if isinstance(visited, list) else [visited]
            )
            replace_by_id[id(c)] = temp

        class _RewriteAnchoredEffects(ast.NodeTransformer):
            def visit(self, n: ast.AST) -> ast.AST:
                repl = replace_by_id.get(id(n))
                if repl is not None:
                    return ast.copy_location(ast.Name(id=repl, ctx=ast.Load()), n)
                return super().visit(n)

        _RewriteAnchoredEffects().visit(node)
        ast.fix_missing_locations(node)

    # ------------------------------------------------------------------
    # Walrus (``ast.NamedExpr``) lowering
    # ------------------------------------------------------------------
    # >0 while visiting an ``ast.Lambda`` body: a walrus there binds in the LAMBDA's own
    # scope at call time (PEP 572), so it is not this statement's write and must be left
    _pyir_lambda_depth: int = 0

    @staticmethod
    def _find_eager_walrus(root: ast.AST) -> "ast.NamedExpr | None":
        """First ``ast.NamedExpr`` under *root* whose write would land in the ENCLOSING
        function scope when *root* evaluates."""
        stack: list[ast.AST] = [root]
        while stack:
            n = stack.pop()
            if isinstance(n, ast.Lambda):
                continue
            if isinstance(n, ast.NamedExpr):
                return n
            stack.extend(ast.iter_child_nodes(n))
        return None

    def _refuse_conditional_walrus(self, sub: "ast.expr | None") -> None:
        """Curated refusal for a walrus in a conditionally-evaluated position."""
        if sub is None:
            return
        walrus = self._find_eager_walrus(sub)
        if walrus is None:
            return
        raise DSLUserCodeError(
            DiagId.UNSUP_WALRUS_CONDITIONAL,
            filename=self.session_data.file_name,
            lineno=getattr(walrus, "lineno", None),
            col_offset=getattr(walrus, "col_offset", None),
            end_col_offset=getattr(walrus, "end_col_offset", None),
            name=walrus.target.id
            if isinstance(walrus.target, ast.Name)
            else ast.unparse(walrus.target),
        )

    def visit_BoolOp(self, node: ast.BoolOp) -> ast.expr:
        # ``values[1:]`` of and/or are conditionally evaluated; ``values[0]``
        # always evaluates, so a walrus there lowers normally.
        for v in node.values[1:]:
            self._refuse_conditional_walrus(v)
        return self._expand_boolop_evaluate_once(node)

    def visit_IfExp(self, node: ast.IfExp) -> ast.Call:
        # Ternary arms evaluate conditionally; the test always evaluates.
        self._refuse_conditional_walrus(node.body)
        self._refuse_conditional_walrus(node.orelse)
        return super().visit_IfExp(node)

    def visit_Lambda(self, node: ast.Lambda) -> ast.Lambda:
        self._pyir_lambda_depth += 1
        try:
            return super().visit_Lambda(node)
        finally:
            self._pyir_lambda_depth -= 1

    def _visit_Comprehension(
        self, node: "_ComprehensionT", ele_visitor: "Callable[..., Any]"
    ) -> "_ComprehensionT":
        # A comprehension walrus writes the ENCLOSING function scope from the
        # comprehension's looped scope (PEP 572): iteration-dependent, refuse.
        self._refuse_conditional_walrus(node)
        return super()._visit_Comprehension(node, ele_visitor)

    def visit_NamedExpr(self, node: ast.NamedExpr) -> ast.expr:
        """Lower ``name := value`` into a real, fully instrumented assignment."""
        if self._pyir_lambda_depth or not self.session_data.region_stack:
            self.generic_visit(node)
            return node
        # PEP 572: a NamedExpr target is always a plain name.
        assert isinstance(node.target, ast.Name)
        name = node.target.id
        assign = ast.copy_location(
            ast.Assign(
                targets=[ast.copy_location(ast.Name(id=name, ctx=ast.Store()), node)],
                value=node.value,
            ),
            node,
        )
        ast.fix_missing_locations(assign)
        visited = self.visit(assign)
        self.session_data.region_stack[-1].append_new_stmts(
            visited if isinstance(visited, list) else [visited]
        )
        return ast.copy_location(ast.Name(id=name, ctx=ast.Load()), node)

    def _nested_unpack_preread(self, name: str, node: ast.Assign) -> ast.stmt:
        """Guarded ``name = pyir_read(name, name)`` (the flat Step-1 shape):
        re-binds the name to its ref-loaded value BEFORE the original RHS
        evaluates, since the follow-up's own Step-1 read fires only after."""
        read_call = ast.Call(
            func=_create_runtime_attribute(
                "pyir_read",
                lineno=node.lineno,
                col_offset=node.col_offset,
            ),
            args=[
                ast.Constant(value=name),
                ast.Name(id=name, ctx=ast.Load()),
            ],
            keywords=[],
        )
        tried = ast.Try(
            body=[
                ast.Assign(
                    targets=[ast.Name(id=name, ctx=ast.Store())],
                    value=read_call,
                )
            ],
            handlers=[
                ast.ExceptHandler(
                    type=ast.Tuple(
                        elts=[
                            ast.Name(id="NameError", ctx=ast.Load()),
                            ast.Name(id="UnboundLocalError", ctx=ast.Load()),
                        ],
                        ctx=ast.Load(),
                    ),
                    name=None,
                    body=[ast.Pass()],
                )
            ],
            orelse=[],
            finalbody=[],
        )
        return ast.copy_location(ast.fix_missing_locations(tried), node)

    @staticmethod
    def _is_multi_targets_assign(node: ast.Assign) -> bool:
        """``t1 = t2 = rhs``: more than one target shares one RHS."""
        return len(node.targets) > 1

    @staticmethod
    def _is_nested_unpack_target(node: ast.Assign) -> bool:
        """``a, (b, c) = rhs``: some element of a sequence target is itself a
        sequence, which is what opens the extra unpack level."""
        return any(
            isinstance(
                elt.value if isinstance(elt, ast.Starred) else elt,
                (ast.Tuple, ast.List),
            )
            for target in node.targets
            if isinstance(target, (ast.Tuple, ast.List))
            for elt in target.elts
        )

    def _split_nested_unpack_target(self, node: ast.Assign) -> "list[ast.stmt]":
        """Split nested unpack targets so every level goes through the flat
        tuple decompose: ``a, (b, c) = rhs`` becomes
        ``_pyir_nest_0, _pyir_nest_1 = rhs`` followed by ``a = _pyir_nest_0``
        and ``b, c = _pyir_nest_1``.  A nested Tuple/List element otherwise
        unpacks bare -- no pyir_read/pyir_assign -- so its stores never reach
        the ledger and staged loops carry frozen values.  Python evaluates the
        whole RHS before any element store, so the split preserves swap
        pinning; deeper nesting recurses through the re-visit.

        EVERY element of EVERY sequence target is staged, not just the nested
        ones, so the head statement makes no user-visible store and the
        follow-ups replay the whole target list in source order.  Python stores
        targets strictly left to right while a follow-up runs after the head
        statement, so an element left behind would store ahead of the staged
        ones -- inverting the last writer when the two name the same place:
        ``(x, y), x = (1, 2), 3`` must leave ``x == 3``, not ``1``.  Staging
        only the colliding elements is not an option: ``p = o`` makes
        ``(o.a, y), p.a = ...`` name one place through two syntactically
        distinct elements, so the collision is not decidable here.

        Returns the rewritten statements, already visited.  The prereads
        re-bind every in-scope Name before the RHS (flat
        Step-1 ordering): a staged element no longer takes the head statement's
        Step-1 read, so it would otherwise lose that read entirely.  Follow-up
        statements are marked so their recursive split skips redundant prereads
        (their RHS is the already-pinned temp)."""
        is_followup = getattr(node, "_pyir_nest_followup", False)
        prereads: list[ast.stmt] = []
        preread_names: set[str] = set()

        def _unstar(elt: ast.expr) -> ast.expr:
            return elt.value if isinstance(elt, ast.Starred) else elt

        def _collect_prereads(elt: ast.expr) -> None:
            inner = _unstar(elt)
            if isinstance(inner, (ast.Tuple, ast.List)):
                for e in inner.elts:
                    _collect_prereads(e)
            elif (
                isinstance(inner, ast.Name)
                and inner.id != "_"
                and inner.id not in preread_names
                and self._is_element_in_scope(inner)
            ):
                preread_names.add(inner.id)
                prereads.append(self._nested_unpack_preread(inner.id, node))

        followups: list[ast.Assign] = []
        for target in node.targets:
            if not isinstance(target, (ast.Tuple, ast.List)):
                continue
            for i in range(len(target.elts)):
                elt = target.elts[i]
                inner = _unstar(elt)
                if not is_followup:
                    _collect_prereads(elt)
                tmp = f"_pyir_nest_{self.session_data.counter}"
                self.session_data.counter += 1
                # The synthetic temp is machinery-owned: no first-def
                # pyir_assign choke, no carry.
                self.session_data.scope_manager.add_skip_reference_taking(tmp)
                tmp_store: ast.expr = ast.Name(id=tmp, ctx=ast.Store())
                if isinstance(elt, ast.Starred):
                    tmp_store = ast.Starred(value=tmp_store, ctx=ast.Store())
                target.elts[i] = tmp_store
                # A List element unpacks identically to a Tuple; normalize so
                # the follow-up hits the tuple decompose.  A non-nested element
                # (star-stripped Name / Attribute / Subscript) is already its
                # own follow-up target.
                follow_target = (
                    ast.Tuple(elts=inner.elts, ctx=ast.Store())
                    if isinstance(inner, ast.List)
                    else inner
                )
                followup = ast.Assign(
                    targets=[follow_target],
                    value=ast.Name(id=tmp, ctx=ast.Load()),
                )
                followup._pyir_nest_followup = True  # type: ignore[attr-defined]
                followups.append(followup)
        # ``_is_nested_unpack_target`` gated the call, so at least one element
        # was staged and ``followups`` is never empty here.
        result: list[ast.stmt] = list(prereads)
        for stmt in [node, *followups]:
            visited = self.visit(
                ast.copy_location(ast.fix_missing_locations(stmt), node)
            )
            result.extend(visited if isinstance(visited, list) else [visited])
        return result

    def _collect_assign_facts(self, node: ast.Assign) -> "list[ast.expr]":
        """Collect the STATEMENT-level facts the exits below need, BEFORE any
        target is visited.

        Returns ``targets_to_instrument`` (the dispatch needs it) and ATTACHES
        the other two facts to the AST, where the exit that consumes each can
        reach it from *node* alone: the first-def target list on the statement,
        and each sequence target's in-scope element indices on that target.
        Both have to be captured here and cannot be recomputed later --
        ``_visit_target`` adds first-definitions to scope right after this
        call, which would make every element look in-scope.

        Order matters twice over: every fact must be read before
        ``_visit_target`` runs, and ``_is_target_in_scope`` records
        ``__init__`` attributes in ``seen_init_attrs`` as a side effect -- so
        the blocks below keep their relative order.
        """
        # This distinguishes first-time definitions from reassignments.
        targets_to_instrument = [t for t in node.targets if self._is_target_in_scope(t)]
        # First-def Name targets: not yet in scope AND not excluded
        # from pyir reference taking.  These will get
        # ``pyir_assign(name, None, value)`` AFTER the original
        # assignment so that pyir_assign can create an eager ref
        # when the first-def occurs inside staged CF.
        first_def_targets: list[ast.expr] = [
            t
            for t in node.targets
            if isinstance(t, ast.Name)
            and not self._is_target_in_scope(t)
            and not self.session_data.scope_manager.is_skip_reference_taking(t.id)
        ]
        # First-def TUPLE-unpack elements: ``a, _, _ = obj.attr``
        # (the ``[a, _, _] = obj.attr`` List spelling unpacks identically)
        for t in node.targets:
            if isinstance(t, (ast.Tuple, ast.List)) and not self._is_target_in_scope(t):
                for elt in t.elts:
                    if (
                        isinstance(elt, ast.Name)
                        and elt.id != "_"
                        and not self.session_data.scope_manager.is_skip_reference_taking(
                            elt.id
                        )
                    ):
                        first_def_targets.append(elt)
        # Include first-def ``self.X`` Attribute targets in ``__init__``
        # so they receive owner/slot-keyed post-assignment
        # ``pyir_assign(name, None, self.X, ..., owner=self,
        # slot_name="X")`` instrumentation.  Emitted AFTER the original
        # assignment so there is no pre-assignment ``_pyir_old = self.X``
        # read that would crash with ``AttributeError``.
        # ``_is_target_in_scope`` already filtered these via
        # ``seen_init_attrs``; we re-detect them here.  Only ``self.X``
        # in ``__init__`` qualifies -- other receivers fall through to
        # the existing reassignment / hasattr-guarded path.
        #
        # IMPORTANT: skip when the RHS is a bare Python-primitive literal
        # (``self.base = 2192``).  ``pyir_assign`` would record the slot
        # in ``_slot_first_def_inside_cf`` and the subsequent
        # ``_WatchedInt`` snapshot read of that slot inside staged CF
        # would short-circuit the per-region ``arith.constant``
        # rematerialisation -- pinning the const at the for body instead
        # of each sibling ``scf.if``.  This instrumentation is only
        # needed for staged DSL init values (Int32 / Boolean / Float32
        # etc.); literal-int init values stay on the legacy
        # ``seen_init_attrs`` skip path.
        if self.session_data.function_name == "__init__":
            for t in node.targets:
                if (
                    isinstance(t, ast.Attribute)
                    and isinstance(t.value, ast.Name)
                    and t.value.id == "self"
                ):
                    attr_key = f"self.{t.attr}"
                    # ``_is_target_in_scope`` set seen_init_attrs for the
                    # first-def attrs above; reassignments live in
                    # ``targets_to_instrument`` instead.
                    if (
                        attr_key in self.session_data.scope_manager.seen_init_attrs
                        and t not in targets_to_instrument
                        and not self._is_meta_primitive_literal(node.value)
                    ):
                        first_def_targets.append(t)
        # For tuple targets, snapshot which elements are in scope NOW, before
        # _visit_target adds first-definitions to scope.  Attached to the
        # target itself so it survives a statement rebuild that hands back a
        # different node object.
        for t in targets_to_instrument:
            if isinstance(t, (ast.Tuple, ast.List)):
                t._pyir_scope_snapshot = {  # type: ignore[union-attr]
                    i for i, elt in enumerate(t.elts) if self._is_element_in_scope(elt)
                }
        node._pyir_first_def_targets = first_def_targets  # type: ignore[attr-defined]
        return targets_to_instrument

    def _assign_sequence_target(self, node: ast.Assign) -> "ast.stmt | list[ast.stmt]":
        """Rebuild an assignment whose single target is a Tuple/List."""
        assert len(node.targets) == 1, "chained assign was not normalised"
        target = node.targets[0]
        assert isinstance(target, (ast.Tuple, ast.List))
        # Read the snapshot off the target BEFORE the rewrite below, which may
        # hand back a different statement object: the fact is attached to THIS
        # target, and a rebound ``node.targets`` would miss it (a lost snapshot
        # silently downgrades in-scope elements to first-defs).
        all_stmts: list[ast.stmt] = []

        exclude = {self._target_to_path_str(elt) for elt in target.elts}
        attr_read_result = self._insert_pyir_attr_reads(node, exclude)
        if isinstance(attr_read_result, list):
            all_stmts.extend(attr_read_result[:-1])
            # The reads substitute into the statement the call returns, which
            # is what the decompose must pin.
            rewritten = attr_read_result[-1]
            assert isinstance(rewritten, ast.Assign)
            node = rewritten

        snapshot: set[int] = getattr(target, "_pyir_scope_snapshot", set())
        decomposed = self._decompose_unpack_assign(node, target, snapshot)
        if isinstance(decomposed, list):
            all_stmts.extend(decomposed)
        else:
            # Starred or no instrumented elements -- keep the original node.
            all_stmts.append(decomposed)
        return all_stmts if all_stmts else node

    def _assign_subscript_target(self, node: ast.Assign) -> "ast.stmt | list[ast.stmt]":
        """Instrument a subscript target (``c[k] = rhs``)."""
        assert len(node.targets) == 1, "chained assign was not normalised"
        target = node.targets[0]
        assert isinstance(target, ast.Subscript)
        exclude = {self._target_to_path_str(target)}
        # Same ordering invariant as scalar_targets above: collect RHS
        # reads first so the subscript-assign sees rewritten reads.
        self_reads = self._collect_attr_reads(node.value, exclude)
        other_reads = self._collect_other_attr_reads(node.value, exclude)
        deep_reads = self._collect_deep_attr_reads(node.value, exclude)
        global_reads = self._collect_global_name_reads(node.value, exclude)
        prologue_reads: list[ast.stmt] | None = None
        if self_reads or other_reads or deep_reads or global_reads:
            attr_read_result = self._insert_pyir_attr_reads(node, exclude)
            if isinstance(attr_read_result, list):
                prologue_reads = attr_read_result
        else:
            # Function-scope: no read instrumentation fires here, so add
            # only the superseded-generation probes (no rewrites).
            probe_stmts = self._build_generation_probe_stmts(node, exclude)
            if probe_stmts:
                prologue_reads = [*probe_stmts, node]
        sub_result = self._insert_pyir_subscript_assign(node, target)
        if isinstance(sub_result, list) and prologue_reads is not None:
            return prologue_reads[:-1] + sub_result
        return sub_result

    def _assign_scalar_target(self, node: ast.Assign) -> "ast.stmt | list[ast.stmt]":
        """Instrument an in-scope plain-name / attribute target."""
        assert len(node.targets) == 1, "chained assign was not normalised"
        target = node.targets[0]
        assert isinstance(target, (ast.Name, ast.Attribute))
        exclude = {self._target_to_path_str(target)}
        # Run attr-read instrumentation FIRST so node.value's reads are
        # rewritten to _pyir_attr_N locals BEFORE _insert_pyir_assign
        # deepcopies node into its hasattr branches.  Without this, both
        # ``self._x = self._x + 1`` (covered by ``_collect_attr_reads``)
        # and ``obj = Cls(obj.x + 1)`` rebinding patterns (covered by
        # ``_collect_other_attr_reads``) keep the raw attribute access
        # in the RHS and bypass the read.
        self_reads = self._collect_attr_reads(node.value, exclude)
        other_reads = self._collect_other_attr_reads(node.value, exclude)
        deep_reads = self._collect_deep_attr_reads(node.value, exclude)
        global_reads = self._collect_global_name_reads(node.value, exclude)
        prologue_reads = None
        if self_reads or other_reads or deep_reads or global_reads:
            attr_read_result = self._insert_pyir_attr_reads(node, exclude)
            if isinstance(attr_read_result, list):
                prologue_reads = attr_read_result
        else:
            # Function-scope: no read instrumentation fires here, so add
            # only the superseded-generation probes (no rewrites).
            probe_stmts = self._build_generation_probe_stmts(node, exclude)
            if probe_stmts:
                prologue_reads = [*probe_stmts, node]
        assign_result = self._insert_pyir_assign(node, [target])
        if isinstance(assign_result, list) and prologue_reads is not None:
            return prologue_reads[:-1] + assign_result
        return assign_result

    def _assign_first_def_fallthrough(
        self, node: ast.Assign
    ) -> "ast.stmt | list[ast.stmt]":
        """No target needs reassignment instrumentation: still rewrite the RHS
        reads, and commit any first-def target (``_collect_assign_facts``
        attached the list) so a first definition inside staged CF gets its
        eager ref."""
        assert len(node.targets) == 1, "chained assign was not normalised"
        first_def_targets = getattr(node, "_pyir_first_def_targets", [])
        # First-time definitions: still scan RHS for self.X reads,
        # and emit pyir_assign(name, None, name) for first-def Name
        # targets so that pyir_assign can create an eager ref when the
        # first definition occurs inside staged CF.
        base = self._insert_pyir_attr_reads(node)
        if first_def_targets:
            first_def_stmts = self._build_first_def_pyir_assigns(
                node, first_def_targets
            )
            if first_def_stmts:
                if isinstance(base, list):
                    return base + first_def_stmts
                return [base] + first_def_stmts
        return base

    def _split_multiple_targets(self, node: ast.Assign) -> "list[ast.stmt]":
        """Rewrite ``t1 = t2 = rhs`` into one RHS temp plus one store per target.

        Python evaluates the RHS ONCE and then stores into each target left to
        right, which is exactly this shape::

            _pyir_rhs_N = rhs
            t1 = _pyir_rhs_N
            t2 = _pyir_rhs_N

        Every downstream exit then sees a SINGLE target, so none of them has to
        carry its own chained-assign machinery -- three different ones existed
        (the tuple decompose's shared pin, ``_insert_pyir_assign``'s
        ``_pyir_chain_N``, and the subscript exit, which simply ignored every
        target after the first).

        Only for a chained assign (``_is_multi_targets_assign``): rewriting a
        single-target statement would add a temp to nearly every statement in
        the program and buy nothing.
        """
        tmp = f"_pyir_rhs_{self.session_data.counter}"
        self.session_data.counter += 1
        # The synthetic temp is machinery-owned: no first-def choke, no ledger
        # row (same treatment the nested-unpack temps get).
        self.session_data.scope_manager.add_skip_reference_taking(tmp)
        hoist = ast.Assign(
            targets=[ast.Name(id=tmp, ctx=ast.Store())],
            value=node.value,
        )
        rewritten: list[ast.stmt] = [
            ast.copy_location(ast.fix_missing_locations(hoist), node)
        ]
        for target in node.targets:
            store = ast.Assign(
                targets=[_deepcopy_ast_root(target)],
                value=ast.Name(id=tmp, ctx=ast.Load()),
            )
            rewritten.append(ast.copy_location(ast.fix_missing_locations(store), node))
        result: list[ast.stmt] = []
        for stmt in rewritten:
            visited = self.visit(stmt)
            result.extend(visited if isinstance(visited, list) else [visited])
        return result

    def visit_Assign(self, node: ast.Assign) -> ast.stmt | list[ast.stmt]:
        """Override to add PyIR instrumentation for reassignments.

        Everything here is statement level: the two rewrites that reduce a
        statement to ONE target, the pre-walrus hoists, the facts the exits
        share, and the dispatch to one of four exits -- one per target kind,
        each a method below taking just the statement.

        The rewrites run outside-in: a chained assign is split into one store
        per target FIRST, so each store then faces the nested-unpack question
        on its own.  Everything after them sees a single target, which is what
        lets each exit assert its shape instead of grouping target lists.
        """
        if self._is_multi_targets_assign(node):
            return self._split_multiple_targets(node)
        if self._is_nested_unpack_target(node):
            return self._split_nested_unpack_target(node)
        self._hoist_pre_walrus_reads(node, node.value)
        self._hoist_pre_walrus_effects(node, node.value)

        targets_to_instrument = self._collect_assign_facts(node)

        for target in node.targets:
            self._visit_target(target)
        self.generic_visit(node)

        # A sequence target takes its exit whether or not any element needs
        # instrumentation: that exit REPLACES the statement, so a target it
        # declined would be dropped outright and its names never bound.
        assert len(node.targets) == 1, (
            "multiple targets should have been split into multiple statements."
        )
        target = node.targets[0]
        if isinstance(target, (ast.Tuple, ast.List)):
            return self._assign_sequence_target(node)
        if targets_to_instrument:
            if isinstance(target, ast.Subscript):
                return self._assign_subscript_target(node)
            return self._assign_scalar_target(node)
        return self._assign_first_def_fallthrough(node)

    def visit_AnnAssign(self, node: ast.AnnAssign) -> "ast.stmt | list[ast.stmt]":
        """An annotated assignment with a value IS an assignment: route it through the
        full ``visit_Assign`` instrumentation."""
        if node.value is None or self._pyir_class_body_depth > 0:
            return super().visit_AnnAssign(node)
        assign = ast.copy_location(
            ast.Assign(targets=[node.target], value=node.value), node
        )
        ast.fix_missing_locations(assign)
        return self.visit_Assign(assign)

    def visit_Delete(self, node: ast.Delete) -> ast.stmt | list[ast.stmt]:
        """Reject ``del`` of a LOOP-CARRIED local inside control flow, and route
        attribute targets through the one attribute-deletion funnel.

        A name defined BEFORE the enclosing for/while/if carries a value into
        the region; ``del``'ing it mid-body drops that carry (the following
        rebind is a body-local first-def with no pre-region init), so the next
        read has no value -- baseline raises a raw ``NameError``.  Refuse with a
        curated, del-aware diagnostic instead.  A name present only in the
        INNERMOST region scope was defined inside the region (a trace-time temp)
        and deleting it is benign -> pass, constexpr-unrolled or dynamic.  A
        top-level ``del`` and a skip-reference name (loop induction var) pass.

        ``del obj.attr`` rewrites to ``_pyir_delete_attr(obj, "attr")`` -- the
        funnel the routed ``delattr`` also uses (it performs the native delete,
        refuses inside dynamic staged CF, and records the unbind in meta flow).
        Subscript targets stay native: watched containers choke in their own
        ``__delitem__``, trace-internal ones keep Python protocol semantics.
        """
        active = self.session_data.scope_manager.get_active_symbols()
        if len(active) > 1:
            enclosing = active[:-1]
            for tgt in node.targets:
                if (
                    isinstance(tgt, ast.Name)
                    and not self.session_data.scope_manager.is_skip_reference_taking(
                        tgt.id
                    )
                    and any(tgt.id in scope for scope in enclosing)
                ):
                    raise DSLUserCodeError(
                        DiagId.SCOPE_DEL_LOOP_CARRIED,
                        filename=self.session_data.file_name,
                        lineno=node.lineno,
                        col_offset=node.col_offset,
                        end_col_offset=getattr(node, "end_col_offset", None),
                        var=tgt.id,
                    )
        if self._pyir_class_body_depth > 0 or not any(
            isinstance(t, ast.Attribute) for t in node.targets
        ):
            return node
        stmts: list[ast.stmt] = []
        for tgt in node.targets:
            if isinstance(tgt, ast.Attribute):
                new_stmt: ast.stmt = ast.Expr(
                    value=ast.Call(
                        func=_create_runtime_attribute(
                            "_pyir_delete_attr",
                            lineno=node.lineno,
                            col_offset=node.col_offset,
                        ),
                        args=[
                            self._target_as_load(tgt.value),
                            ast.Constant(value=tgt.attr),
                        ],
                        keywords=[],
                    )
                )
            else:
                new_stmt = ast.Delete(targets=[tgt])
            stmts.append(ast.copy_location(ast.fix_missing_locations(new_stmt), node))
        return stmts

    def visit_AugAssign(self, node: ast.AugAssign) -> ast.AugAssign | list[ast.stmt]:
        """Override to add PyIR instrumentation for augmented assignments."""
        # Base load precedes all RHS evaluation in Python, so its anchor is
        # emitted first.
        base_anchor = self._hoist_pre_walrus_augassign_base(node)
        self._hoist_pre_walrus_reads(node, node.value)
        self._hoist_pre_walrus_effects(node, node.value)
        self._visit_target(node.target)
        self.generic_visit(node)

        # Skip pyir instrumentation for excluded variables (e.g. induction vars)
        if isinstance(
            node.target, ast.Name
        ) and self.session_data.scope_manager.is_skip_reference_taking(node.target.id):
            return node
        target_path = self._target_to_path_str(node.target)

        if isinstance(node.target, ast.Subscript) and self._is_subscript_skippable(
            node.target
        ):
            return node

        # OTHER-attr parity with visit_Assign: an augassign RHS reading a
        # non-self receiver must hoist through the same instrumented read.
        # Deep-chain reads (``d["k"].val``, ``self.helper().x``) count too:
        # visit_Assign's gate consults all three collectors.  The hoist runs
        # FIRST (it rewrites node.value in place) so the in-place-op rewrite
        # below copies the hoisted RHS, never the raw attribute reads.
        attr_reads = (
            self._collect_attr_reads(node.value, {target_path})
            or self._collect_other_attr_reads(node.value, {target_path})
            or self._collect_deep_attr_reads(node.value, {target_path})
            or self._collect_global_name_reads(node.value, {target_path})
        )
        read_stmts: "list[ast.stmt] | None" = None
        if attr_reads:
            hoisted = self._insert_pyir_attr_reads(node, {target_path})
            if isinstance(hoisted, list):
                read_stmts = hoisted

        if isinstance(node.target, ast.Subscript):
            result = self._insert_pyir_subscript_augassign(node, node.target)
            if read_stmts is not None and isinstance(result, list):
                return read_stmts[:-1] + result
            return result

        result = self._insert_pyir_augassign(node, base_anchor)
        if read_stmts is not None and isinstance(result, list):
            return read_stmts[:-1] + result
        return result

    def visit_Subscript(self, node: ast.Subscript) -> ast.expr:
        """Instrument dict subscript reads.

        Transforms ``d[key]`` in Load context into::

            _pyir_post_subscript_read("d[key]", d, key)

        which calls ``pyir_read`` on the dict value to emit ``pyir.load``
        when the value carries a ``_mutable_ref``.  Non-dict containers
        pass through with only an ``isinstance`` check as overhead.

        Skips Store/Del context (handled by ``_insert_pyir_subscript_assign``)
        and slice/tuple subscripts (GPU array ops, never dicts).
        """
        self.generic_visit(node)
        if (
            not isinstance(node.ctx, ast.Load)
            or self._is_subscript_skippable(node)
            or self._is_subscript_read_skippable(node)
        ):
            return node

        lineno = getattr(node, "lineno", 0)
        col_offset = getattr(node, "col_offset", 0)
        target_name = self._target_to_path_str(node)

        # _pyir_post_subscript_read("d[key]", d, key)
        call = ast.Call(
            func=_create_runtime_attribute(
                "_pyir_post_subscript_read",
                lineno=lineno,
                col_offset=col_offset,
            ),
            args=[
                ast.Constant(value=target_name),
                _deepcopy_ast_root(node.value),  # container expression
                _deepcopy_ast_root(node.slice),  # key expression
            ],
            keywords=[],
        )
        return ast.copy_location(ast.fix_missing_locations(call), node)

    def visit_Return(self, node: ast.Return) -> ast.stmt | list[ast.stmt]:
        """Override to add PyIR instrumentation for attribute reads in returns."""
        self._hoist_pre_walrus_effects(node, node.value)
        self.generic_visit(node)
        if node.value is not None:
            return self._insert_pyir_attr_reads(node)
        return node

    # Method names whose call on a meta ``list`` / ``dict`` / ``set`` /
    # ``collections.deque`` mutates the container in place.  When the call
    # appears as a statement inside staged CF,
    # ``_pyir_check_no_complex_m2m_call`` raises a ``DSLUserCodeError`` so
    # users see a clear diagnostic instead of silent single-iteration baking.
    _CONTAINER_MUTATOR_METHODS: frozenset[str] = frozenset(
        {
            "append",
            "extend",
            "insert",
            "pop",
            "remove",
            "clear",
            "sort",
            "reverse",
            "update",
            "popitem",
            "setdefault",
            "add",
            "discard",
            "intersection_update",
            "difference_update",
            "symmetric_difference_update",
            "appendleft",
            "popleft",
            "extendleft",
            "rotate",
        }
    )

    def visit_Expr(self, node: ast.Expr) -> ast.stmt | list[ast.stmt]:
        """Override to add PyIR instrumentation for attribute reads in
        expressions, plus a runtime mutation guard for ``a.append(...)``
        style calls on meta Python containers inside staged CF.
        """
        self._hoist_pre_walrus_effects(node, node.value)
        self.generic_visit(node)
        # An Attribute-rooted receiver evaluates once natively; hoist it to a
        # shared temp so the guard/freeze brackets below add no re-evaluation
        # (a property getter would fire once per bracketing statement).
        recv_hoist = self._hoist_mutator_receiver(node)
        # Build the guard from the original call BEFORE read-hoisting rewrites its
        # args into later-defined temps (the guard is emitted ahead of them).
        guard = self._build_container_mutator_guard(node)
        # Emitted AFTER the (read-hoisted) call: it inspects the CONTAINER
        # after the mutation.
        freeze = self._build_container_insert_freeze(node)
        result = self._insert_pyir_attr_reads(node)
        stmts = result if isinstance(result, list) else [result]
        if guard is not None:
            stmts = [guard, *stmts]
        if recv_hoist is not None:
            stmts = [recv_hoist, *stmts]
        if recv_hoist is None and guard is None and freeze is None:
            return result
        if freeze is not None:
            stmts = [*stmts, freeze]
        return stmts

    def _hoist_mutator_receiver(self, node: ast.Expr) -> ast.stmt | None:
        """Hoist an Attribute-rooted mutator receiver into a shared temp.

        ``obj.field.append(x)`` evaluates ``obj.field`` once natively, but
        the mutator guard and the insert freeze would each re-evaluate it
        (a property getter fires once per bracket).  Bind the receiver to
        a temp ahead of the brackets and rewrite the call so the brackets
        (which read ``call.func.value`` after this) share the one
        evaluation.  Name receivers stay put: re-reading a local is
        effect-free."""
        call = node.value
        if not isinstance(call, ast.Call):
            return None
        func = call.func
        if not isinstance(func, ast.Attribute):
            return None
        if (
            func.attr not in self._CONTAINER_MUTATOR_METHODS
            and func.attr not in self._CONTAINER_INSERT_METHODS
        ):
            return None
        if not isinstance(func.value, ast.Attribute):
            return None
        recv_name = f"_pyir_recv_{self.session_data.counter}"
        self.session_data.counter += 1
        # The guard's diagnostic keeps the user's spelling, not the temp.
        call._pyir_recv_spelling = _unparse_safe(func.value)  # type: ignore[attr-defined]
        hoist = ast.Assign(
            targets=[ast.Name(id=recv_name, ctx=ast.Store())],
            value=func.value,
        )
        func.value = ast.Name(id=recv_name, ctx=ast.Load())
        return ast.copy_location(ast.fix_missing_locations(hoist), node)

    def _build_container_mutator_guard(self, node: ast.Expr) -> ast.stmt | None:
        """Return an ``_pyir_check_no_complex_m2m_call(container, ...)``
        statement to prepend before *node* when *node* is a statement-
        level call of the form ``<Name>.<mutator>(...)``.  Returns
        ``None`` when the pattern doesn't match.
        """
        call = node.value
        if not isinstance(call, ast.Call):
            return None
        func = call.func
        if not isinstance(func, ast.Attribute):
            return None
        if func.attr not in self._CONTAINER_MUTATOR_METHODS:
            return None
        container = func.value
        # Simple container expressions only; an Attribute-rooted receiver
        # arrives here as the shared temp `_hoist_mutator_receiver` bound.
        if not isinstance(container, (ast.Name, ast.Attribute)):
            return None
        # Pass values only when every arg is side-effect-free to re-evaluate;
        # else ``None`` (conservative).
        if not call.keywords and all(
            isinstance(a, (ast.Name, ast.Constant)) for a in call.args
        ):
            values_arg: ast.expr = ast.List(
                elts=[_deepcopy_ast_root(a) for a in call.args], ctx=ast.Load()
            )
        else:
            values_arg = ast.Constant(value=None)
        return ast.copy_location(
            ast.fix_missing_locations(
                ast.Expr(
                    value=ast.Call(
                        func=_create_runtime_attribute(
                            "_pyir_check_no_complex_m2m_call",
                            lineno=node.lineno,
                            col_offset=node.col_offset,
                        ),
                        args=[
                            _deepcopy_ast_root(container),
                            ast.Constant(value=func.attr),
                            ast.Constant(
                                value=getattr(call, "_pyir_recv_spelling", None)
                                or _unparse_safe(container)
                            ),
                            ast.Constant(value=self.session_data.file_name),
                            ast.Constant(value=node.lineno),
                            values_arg,
                        ],
                        keywords=[],
                    ),
                )
            ),
            node,
        )

    # Insert-like mutators add the call's value argument; a STAGED appended value
    # re-resolving a loop-carried slot freezes to its current SSA (see the freeze).
    _CONTAINER_INSERT_METHODS: frozenset[str] = frozenset(
        {"append", "extend", "insert", "update", "setdefault"}
    )

    def _build_container_insert_freeze(self, node: ast.Expr) -> ast.stmt | None:
        """Emit ``_pyir_freeze_staged_container_inserts(container, method)`` after a
        statement-level insert-mutator call; gating lives in the runtime."""
        call = node.value
        if not isinstance(call, ast.Call):
            return None
        func = call.func
        if not isinstance(func, ast.Attribute):
            return None
        if func.attr not in self._CONTAINER_INSERT_METHODS:
            return None
        container = func.value
        if not isinstance(container, (ast.Name, ast.Attribute)):
            return None
        return ast.copy_location(
            ast.fix_missing_locations(
                ast.Expr(
                    value=ast.Call(
                        func=_create_runtime_attribute(
                            "_pyir_freeze_staged_container_inserts",
                            lineno=node.lineno,
                            col_offset=node.col_offset,
                        ),
                        args=[
                            _deepcopy_ast_root(container),
                            ast.Constant(value=func.attr),
                        ],
                        keywords=[],
                    ),
                )
            ),
            node,
        )

    def _handle_constexpr_while(self, node: ast.While) -> list[ast.stmt]:
        """Override to add PyIR scope isolation for const_expr while loops."""
        # Visit test expression outside branch scopes; test-position reads
        # skip the statement hoist, so they take record-only chokes here.
        self.visit(node.test)
        node.test = self._wrap_test_observation_reads(node.test)
        # Visit body in its own scope so first-definitions don't leak.
        born: set[str] = set()
        node.body = self._visit_stmts_in_cf_scope(node.body, collect_bindings=born)
        self._readd_constexpr_arm_bindings(born)
        # Bracket the (trace-time-unrolled) body so mutations directly
        # inside it are treated as constexpr-governed by the guards.
        node.body = self._wrap_body_in_constexpr_scope(node, node.body)
        assert isinstance(node.test, ast.Call)
        check = self._insert_cf_symbol_check(node.test.func)
        return [check, node]

    def _handle_constexpr_if(self, node: ast.If) -> list[ast.stmt]:
        """Override to add PyIR scope isolation for const_expr if statements."""
        # Visit test expression outside branch scopes; test-position reads
        # skip the statement hoist, so they take record-only chokes here.
        self.visit(node.test)
        node.test = self._wrap_test_observation_reads(node.test)
        # Visit each branch in its own scope so first-definitions in one
        # branch don't leak into sibling branches (fixes UnboundLocalError
        # when only one const_expr branch runs at runtime).
        born: set[str] = set()
        node.body = self._visit_stmts_in_cf_scope(node.body, collect_bindings=born)
        node.orelse = self._visit_stmts_in_cf_scope(node.orelse, collect_bindings=born)
        self._readd_constexpr_arm_bindings(born)
        # Bracket each branch (the trace-time-selected one runs once) so
        # mutations directly inside it are treated as constexpr-governed.
        node.body = self._wrap_body_in_constexpr_scope(node, node.body)
        node.orelse = self._wrap_body_in_constexpr_scope(node, node.orelse)
        assert isinstance(node.test, ast.Call)
        check = self._insert_cf_symbol_check(node.test.func)
        return [check, node]

    def _handle_constexpr_elif(self, elif_node: ast.If) -> ast.stmt:
        """Override to add PyIR scope isolation for const_expr elif nodes."""
        # Visit test outside branch scopes; visit each
        # branch in its own scope to prevent cross-branch
        # first-definition leakage.  Test-position reads skip the statement
        # hoist, so they take record-only chokes here.
        self.visit(elif_node.test)
        elif_node.test = self._wrap_test_observation_reads(elif_node.test)
        born: set[str] = set()
        elif_node.body = self._visit_stmts_in_cf_scope(
            elif_node.body, collect_bindings=born
        )
        elif_node.orelse = self._visit_stmts_in_cf_scope(
            elif_node.orelse, collect_bindings=born
        )
        self._readd_constexpr_arm_bindings(born)
        # Bracket each branch so mutations directly inside the
        # trace-time-selected branch are treated as constexpr-governed.
        elif_node.body = self._wrap_body_in_constexpr_scope(elif_node, elif_node.body)
        elif_node.orelse = self._wrap_body_in_constexpr_scope(
            elif_node, elif_node.orelse
        )
        assert isinstance(elif_node.test, ast.Call)
        return self._insert_cf_symbol_check(elif_node.test.func)

    def _wrap_test_observation_reads(self, expr: ast.expr) -> ast.expr:
        """Record-only observation chokes for symbol reads in TEST position:
        test expressions never pass through the statement-level read hoist, so
        their meta reads bake unrecorded.  Wraps each read INLINE (same
        evaluation site and count), never altering staging semantics."""
        mod_name = self._reading_module_name()
        fn_globals = self.session_data.function_globals or {}
        active = self.session_data.scope_manager.get_active_symbols()
        bound = _locally_bound_names(expr)
        sm = self.session_data.scope_manager
        outer = self

        def in_scope(name: str) -> bool:
            return any(name in scope for scope in active)

        class _Wrapper(ast.NodeTransformer):
            # Late-bound bodies keep their raw reads (deferred contract).
            def visit_Lambda(self, n: ast.Lambda) -> ast.Lambda:
                return n

            def visit_FunctionDef(self, n: ast.FunctionDef) -> ast.FunctionDef:
                return n

            def visit_Call(self, n: ast.Call) -> ast.Call:
                # The call target is never a value read; args/keywords are.
                n.args = [self.visit(a) for a in n.args]
                for kw in n.keywords:
                    kw.value = self.visit(kw.value)
                return n

            def visit_Attribute(self, n: ast.Attribute) -> ast.expr:
                if not isinstance(n.ctx, ast.Load):
                    return n
                root: ast.expr = n.value
                while isinstance(root, ast.Attribute):
                    root = root.value
                if isinstance(root, ast.Name) and root.id in (
                    "__base_dsl__",
                    "__module_dsl__",
                    _PYIR_RUNTIME_ALIAS,
                ):
                    return n
                n.value = self.visit(n.value)
                spelling = outer._access_path_str(n) or f"<test>.{n.attr}"
                call = ast.Call(
                    func=_create_runtime_attribute("_pyir_obs_read"),
                    args=[
                        ast.Constant(value=spelling),
                        n.value,
                        ast.Constant(value=n.attr),
                        ast.Constant(value=mod_name),
                    ],
                    keywords=[],
                )
                return ast.copy_location(ast.fix_missing_locations(call), n)

            def visit_Name(self, n: ast.Name) -> ast.expr:
                if not isinstance(n.ctx, ast.Load):
                    return n
                name = n.id
                if (
                    name in bound
                    or name.startswith("_pyir_")
                    or name in ("__base_dsl__", "__module_dsl__", _PYIR_RUNTIME_ALIAS)
                    or sm.is_skip_reference_taking(name)
                    or in_scope(name)
                    or name not in fn_globals
                ):
                    return n
                obj = fn_globals.get(name)
                if isinstance(
                    obj,
                    (
                        types.ModuleType,
                        type,
                        types.FunctionType,
                        types.BuiltinFunctionType,
                    ),
                ):
                    return n
                call = ast.Call(
                    func=_create_runtime_attribute("_pyir_obs_global_read"),
                    args=[
                        ast.Constant(value=name),
                        ast.Name(id=name, ctx=ast.Load()),
                        ast.Constant(value=mod_name),
                    ],
                    keywords=[],
                )
                return ast.copy_location(ast.fix_missing_locations(call), n)

        wrapped = _Wrapper().visit(expr)
        ast.fix_missing_locations(wrapped)
        return wrapped

    def create_if_function(
        self,
        func_name: str,
        node: ast.If,
        write_args: list[str],
        full_write_args_count: int,
    ) -> ast.FunctionDef:
        """Override: observe symbol reads in the dynamic-if TEST before the
        region synthesis embeds it (tests skip the statement-level hoist)."""
        node.test = self._wrap_test_observation_reads(node.test)
        return super().create_if_function(
            func_name, node, write_args, full_write_args_count
        )

    @staticmethod
    def _attr_chain_root_path(node: ast.expr) -> "tuple[str, tuple[str, ...]] | None":
        """``(root_name, hops)`` for a pure Name-rooted attribute chain, e.g.
        ``c0.inner.v0`` -> ``("c0", ("inner", "v0"))``; ``None`` otherwise."""
        hops: list[str] = []
        cur = node
        while isinstance(cur, ast.Attribute):
            hops.append(cur.attr)
            cur = cur.value
        if isinstance(cur, ast.Name) and hops:
            return cur.id, tuple(reversed(hops))
        return None

    @classmethod
    def _while_cond_carried_attr_paths(
        cls, node: ast.While
    ) -> "dict[str, tuple[tuple[str, ...], ...]]":
        """Attribute paths both READ in the while condition and WRITTEN in the
        body, per root name (the runtime promotes and re-loads exactly these)."""
        read_paths: "dict[str, set[tuple[str, ...]]]" = {}
        for n in ast.walk(node.test):
            if isinstance(n, ast.Attribute) and isinstance(n.ctx, ast.Load):
                chain = cls._attr_chain_root_path(n)
                if chain is not None:
                    read_paths.setdefault(chain[0], set()).add(chain[1])
        # Keep only maximal chains: ast.walk yields every sub-chain of a
        # dotted read; a proper prefix is the traversal, not the read.
        for root, paths in read_paths.items():
            read_paths[root] = {
                p for p in paths if not any(q != p and q[: len(p)] == p for q in paths)
            }

        write_paths: "dict[str, set[tuple[str, ...]]]" = {}

        class _BodyWriteWalker(ast.NodeVisitor):
            def _record(self, tgt: ast.expr) -> None:
                if isinstance(tgt, ast.Attribute):
                    chain = cls._attr_chain_root_path(tgt)
                    if chain is not None:
                        write_paths.setdefault(chain[0], set()).add(chain[1])
                elif isinstance(tgt, ast.Name):
                    # A whole-name rebind replaces the object, so every
                    # condition-read attr path rooted at it is written.
                    write_paths.setdefault(tgt.id, set()).update(
                        read_paths.get(tgt.id, ())
                    )
                elif isinstance(tgt, (ast.Tuple, ast.List)):
                    for e in tgt.elts:
                        self._record(e)
                elif isinstance(tgt, ast.Starred):
                    self._record(tgt.value)

            def visit_Assign(self, n: ast.Assign) -> None:
                for t in n.targets:
                    self._record(t)
                self.generic_visit(n)

            def visit_AugAssign(self, n: ast.AugAssign) -> None:
                self._record(n.target)
                self.generic_visit(n)

            def visit_AnnAssign(self, n: ast.AnnAssign) -> None:
                self._record(n.target)
                self.generic_visit(n)

            # Nested scopes analyze themselves; their writes are not this
            # loop body's writes.
            def visit_FunctionDef(self, n: ast.FunctionDef) -> None:
                return

            def visit_AsyncFunctionDef(self, n: ast.AsyncFunctionDef) -> None:
                return

            def visit_Lambda(self, n: ast.Lambda) -> None:
                return

            def visit_ClassDef(self, n: ast.ClassDef) -> None:
                return

        walker = _BodyWriteWalker()
        for stmt in node.body:
            walker.visit(stmt)

        out: "dict[str, tuple[tuple[str, ...], ...]]" = {}
        for root, rpaths in read_paths.items():
            carried = rpaths & write_paths.get(root, set())
            if carried:
                out[root] = tuple(sorted(carried))
        return out

    def _prepare_while_condition_vars(
        self,
        node: ast.While,
        write_args: list[str],
        while_before_stmts: list[ast.stmt],
    ) -> list[ast.stmt]:
        """Insert a PyIR write_arg prologue in the ``scf.while`` condition so
        carried values load their cells before the condition reads them."""
        # is_condition_read=False is exactness-gated: emitted only when the
        # condition's read set is fully AST-enumerable, else promote-by-default.
        opaque_test = any(
            isinstance(
                sub,
                (
                    ast.Call,
                    ast.Lambda,
                    ast.GeneratorExp,
                    ast.ListComp,
                    ast.SetComp,
                    ast.DictComp,
                    ast.Subscript,
                    ast.Starred,
                    ast.Await,
                ),
            )
            for sub in ast.walk(node.test)
        )
        condition_read: "set[str] | None"
        if opaque_test:
            condition_read = None
        else:
            condition_read = {
                name.id
                for name in ast.walk(node.test)
                if isinstance(name, ast.Name) and isinstance(name.ctx, ast.Load)
            }
        return self._build_pyir_read_prologue(
            node,
            write_args,
            helper="pyir_promote_while_carried_arg",
            condition_read=condition_read,
            attr_paths=self._while_cond_carried_attr_paths(node),
            attr_paths_kwarg="condition_attr_paths",
        )

    @staticmethod
    def _region_facts_tag(node: "ast.For | ast.While") -> "ast.Call | None":
        """The ``pyir_tag_region_attr_writes`` decorator call carrying the
        declared write facts of *node*'s ORIGINAL body: the ``(base, attr)``
        pairs it assigns directly, the ``(base, method)`` pairs it calls on
        Name-rooted receiver paths, and the ``(func_name, arg_base)`` pairs it
        calls as free functions with a Name-rooted first argument; ``None``
        with no facts."""
        attr_writes = sorted(_collect_direct_attr_write_pairs(node.body))
        method_calls = sorted(_collect_receiver_method_call_pairs(node.body))
        free_calls = sorted(_collect_free_call_arg_pairs(node.body))
        if not (attr_writes or method_calls or free_calls):
            return None

        def _pairs_tuple(pairs: "list[tuple[str, str]]") -> "ast.Tuple":
            return ast.Tuple(
                elts=[
                    ast.Tuple(
                        elts=[
                            ast.Constant(value=b),
                            ast.Constant(value=a),
                        ],
                        ctx=ast.Load(),
                    )
                    for b, a in pairs
                ],
                ctx=ast.Load(),
            )

        tag = ast.Call(
            func=_create_runtime_attribute(
                "pyir_tag_region_attr_writes",
                lineno=node.lineno,
                col_offset=node.col_offset,
            ),
            args=[
                _pairs_tuple(attr_writes),
                _pairs_tuple(method_calls),
                _pairs_tuple(free_calls),
            ],
            keywords=[],
        )
        ast.copy_location(tag, node)
        ast.fix_missing_locations(tag)
        return tag

    @override
    def create_loop_function(
        self, func_name: str, node: ast.For, *args: Any, **kwargs: Any
    ) -> ast.FunctionDef:
        """Tag the staged loop-body function with the declared write facts of
        its ORIGINAL body (direct assigns, receiver method calls, free calls)."""
        tag = self._region_facts_tag(node)
        func_def = super().create_loop_function(func_name, node, *args, **kwargs)
        if tag is not None:
            func_def.decorator_list.append(tag)
        return func_def

    @override
    def create_while_function(
        self, func_name: str, node: ast.While, *args: Any, **kwargs: Any
    ) -> ast.FunctionDef:
        """Tag the staged while AFTER block (the loop body) with the declared
        write facts of its ORIGINAL body, same vocabulary as the for tag."""
        tag = self._region_facts_tag(node)
        func_def = super().create_while_function(func_name, node, *args, **kwargs)
        if tag is not None:
            for stmt in func_def.body:
                if isinstance(stmt, ast.FunctionDef) and stmt.name.startswith(
                    "while_after_block_"
                ):
                    stmt.decorator_list.append(tag)
                    break
        return func_def

    def _prepare_loop_body_vars(
        self,
        node: "ast.For | ast.While",
        write_args: list[str],
    ) -> list[ast.stmt]:
        """Emit ``pyir_promote_loop_body_arg`` for write_args whose first
        body reference is a Load before any Store.  Shared between
        ``ast.For`` and ``ast.While``: both expose ``node.body`` as the
        staged region.  Without this, a Python-primitive write_arg that
        is read before being re-stored sees its trace-time constant
        instead of the loop-carried value.
        """
        needs_prologue = [
            var
            for var in write_args
            if self._var_read_before_write(node.body, var)
            # A var whose precise first reference is a pure (re)definition is a
            # per-iteration recompute, not a carry; promoting it would demote it.
            and self._classify_first_ref(node.body, var) != "store"
        ]
        # ``bare_first_use``: True when the first body reference is a plain-use
        # Load (no ref created), False for an assignment-context read.
        bare_first_use = {
            var: self._var_first_ref_is_bare_use(node.body, var)
            for var in needs_prologue
        }
        # The synthetic live-out carry is write-only in the body, so the scan
        # above cannot flag it: force it into the prologue as a bare first use.
        liveout_carry = self.session_data.liveout_loop_carried_vars.get(id(node))
        if (
            liveout_carry is not None
            and liveout_carry in write_args
            and liveout_carry not in bare_first_use
        ):
            needs_prologue.append(liveout_carry)
            bare_first_use[liveout_carry] = True
        # Re-load the same declared carried attr paths at the after-block top:
        # a cross-region use of the before-block SSA would break dominance.
        attr_paths: "dict[str, tuple[tuple[str, ...], ...]]" = {}
        if isinstance(node, ast.While):
            attr_paths = self._while_cond_carried_attr_paths(node)
            for root in attr_paths:
                if root in write_args and root not in needs_prologue:
                    needs_prologue.append(root)
                    bare_first_use[root] = self._var_first_ref_is_bare_use(
                        node.body, root
                    )
        # WHOLE-Name-rebound fact (list carry gate): a rebound name marks a genuine
        # loop-carried list; element-only writes keep the watched-choke lifecycle.
        whole_rebound = {
            var: var in _whole_name_rebound_names(node.body) for var in needs_prologue
        }
        return self._build_pyir_read_prologue(
            node,
            needs_prologue,
            bare_first_use=bare_first_use,
            attr_paths=attr_paths,
            attr_paths_kwarg="carried_attr_paths",
            whole_rebound=whole_rebound,
        )

    @classmethod
    def _var_first_ref_is_bare_use(cls, body: list[ast.stmt], var: str) -> bool:
        """True iff the FIRST reference to *var* in *body* is a plain-use Load
        (creates no ref), not the read of an assignment (which creates the ref)."""
        verdict = cls._classify_first_ref(body, var)
        # "assign" creates its own ref; "store" and ``None`` are not bare uses.
        return verdict == "bare"

    @classmethod
    def _classify_first_ref(cls, stmts: list[ast.stmt], var: str) -> "str | None":
        """First reference to *var* in execution order: ``"assign"`` (read of a
        self/augmented assign), ``"store"``, ``"bare"`` Load, or ``None``."""

        def reads_var(node: "ast.AST | None") -> bool:
            if node is None:
                return False
            for sub in ast.walk(node):
                if (
                    isinstance(sub, ast.Name)
                    and sub.id == var
                    and isinstance(sub.ctx, ast.Load)
                ):
                    return True
            return False

        def stores_var(target: ast.expr) -> bool:
            for sub in ast.walk(target):
                if (
                    isinstance(sub, ast.Name)
                    and sub.id == var
                    and isinstance(sub.ctx, ast.Store)
                ):
                    return True
            return False

        def classify_block(block: "list[ast.stmt] | None") -> "str | None":
            return cls._classify_first_ref(block, var) if block else None

        for stmt in stmts:
            # A value that reads *var* is the assignment-context read; a pure
            # store (RHS does not read *var*) (re)defines it before any read.
            if isinstance(stmt, ast.Assign) and any(
                stores_var(t) for t in stmt.targets
            ):
                if not reads_var(stmt.value):
                    return "store"
                # A CHAINED assign is normalised into ``tmp = rhs`` plus one
                # store per target, so the read lands in the hoist as a plain
                # use that creates no ref -- exactly the hand-written spelling,
                # which the prologue has to promote.  Classifying it "assign"
                # would leave nobody creating the ref before the RHS runs.
                return "bare" if len(stmt.targets) > 1 else "assign"
            if isinstance(stmt, ast.AnnAssign) and stores_var(stmt.target):
                return "assign" if reads_var(stmt.value) else "store"
            if (
                isinstance(stmt, ast.AugAssign)
                and isinstance(stmt.target, ast.Name)
                and stmt.target.id == var
            ):
                return "assign"

            # Compound statements: the guard/iterable runs first, then the
            # sub-blocks in execution order.
            if isinstance(stmt, ast.If):
                if reads_var(stmt.test):
                    return "bare"
                for blk in (stmt.body, stmt.orelse):
                    v = classify_block(blk)
                    if v is not None:
                        return v
                continue
            if isinstance(stmt, (ast.For, ast.AsyncFor)):
                if reads_var(stmt.iter):
                    return "bare"
                for blk in (stmt.body, stmt.orelse):
                    v = classify_block(blk)
                    if v is not None:
                        return v
                continue
            if isinstance(stmt, (ast.While,)):
                if reads_var(stmt.test):
                    return "bare"
                for blk in (stmt.body, stmt.orelse):
                    v = classify_block(blk)
                    if v is not None:
                        return v
                continue
            if isinstance(stmt, (ast.With, ast.AsyncWith)):
                for item in stmt.items:
                    if reads_var(item.context_expr):
                        return "bare"
                v = classify_block(stmt.body)
                if v is not None:
                    return v
                continue

            # Any other statement referencing *var*: first reference is a plain use.
            if reads_var(stmt):
                return "bare"
        return None

    @staticmethod
    def _var_read_before_write(body: list[ast.stmt], var: str) -> bool:
        """Returns True iff *var* is read before -- or within the statement that
        first stores -- it (an Assign/AugAssign binds only after the RHS reads)."""

        def reads_var(node: "ast.expr | None") -> bool:
            if node is None:
                return False
            for sub in ast.walk(node):
                if (
                    isinstance(sub, ast.Name)
                    and sub.id == var
                    and isinstance(sub.ctx, ast.Load)
                ):
                    return True
            return False

        def stores_var(target: ast.expr) -> bool:
            for sub in ast.walk(target):
                if (
                    isinstance(sub, ast.Name)
                    and sub.id == var
                    and isinstance(sub.ctx, ast.Store)
                ):
                    return True
            return False

        for stmt in body:
            if isinstance(stmt, ast.Assign) and any(
                stores_var(t) for t in stmt.targets
            ):
                # ``x = f(x)`` reads before the bind; ``x = f(other)`` does not.
                return reads_var(stmt.value)
            if isinstance(stmt, ast.AnnAssign) and stores_var(stmt.target):
                return reads_var(stmt.value)
            if (
                isinstance(stmt, ast.AugAssign)
                and isinstance(stmt.target, ast.Name)
                and stmt.target.id == var
            ):
                # ``x += expr`` always reads ``x`` first.
                return True
            for sub in ast.walk(stmt):
                if (
                    isinstance(sub, ast.Name)
                    and sub.id == var
                    and isinstance(sub.ctx, ast.Load)
                ):
                    return True
        return False

    def _build_pyir_read_prologue(
        self,
        node: ast.stmt,
        write_args: list[str],
        helper: str = "pyir_promote_loop_body_arg",
        bare_first_use: "dict[str, bool] | None" = None,
        condition_read: "set[str] | None" = None,
        attr_paths: "dict[str, tuple[tuple[str, ...], ...]] | None" = None,
        attr_paths_kwarg: str = "condition_attr_paths",
        whole_rebound: "dict[str, bool] | None" = None,
    ) -> list[ast.stmt]:
        read_stmts: list[ast.stmt] = []
        for var in write_args:
            keywords: list[ast.keyword] = []
            # Only ``pyir_promote_loop_body_arg`` reads ``whole_rebound``, and
            # only the True case changes behaviour (the list-carry gate).
            if whole_rebound is not None and whole_rebound.get(var):
                keywords.append(
                    ast.keyword(
                        arg="whole_rebound",
                        value=ast.Constant(value=True),
                    )
                )
            # The declared first-reference shape: gates the staged-scalar
            # body-entry ref materialisation in the runtime hook.
            if bare_first_use is not None and var in bare_first_use:
                keywords.append(
                    ast.keyword(
                        arg="bare_first_use",
                        value=ast.Constant(value=bare_first_use[var]),
                    )
                )
            # Emit ``is_condition_read=False`` only for a write_arg the condition
            # does not read, so a recomputed meta-primitive stays a Python value.
            if condition_read is not None and var not in condition_read:
                keywords.append(
                    ast.keyword(
                        arg="is_condition_read",
                        value=ast.Constant(value=False),
                    )
                )
            # Declared carried attr paths for this root, emitted as a
            # tuple-of-tuples of literal hop names.
            if attr_paths and attr_paths.get(var):
                keywords.append(
                    ast.keyword(
                        arg=attr_paths_kwarg,
                        value=ast.Tuple(
                            elts=[
                                ast.Tuple(
                                    elts=[ast.Constant(value=hop) for hop in path],
                                    ctx=ast.Load(),
                                )
                                for path in attr_paths[var]
                            ],
                            ctx=ast.Load(),
                        ),
                    )
                )
            pyir_read_call = ast.Call(
                func=_create_runtime_attribute(
                    helper,
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    ast.Constant(value=var),
                    ast.Name(id=var, ctx=ast.Load()),
                ],
                keywords=keywords,
            )
            read_stmt = ast.Assign(
                targets=[ast.Name(id=var, ctx=ast.Store())],
                value=pyir_read_call,
            )
            ast.fix_missing_locations(read_stmt)
            read_stmts.append(read_stmt)
        return read_stmts

    def _slot_kwargs_for(self, target: ast.expr) -> list[ast.keyword]:
        """Build ``owner=...`` / ``slot_name=...`` kwargs for *target*.

        ``pyir_assign`` and ``pyir_read`` accept optional ``owner`` /
        ``slot_name`` kwargs so they can key ref identity on the storage
        slot instead of on the value object.  This helper turns an
        assignment target AST node into the matching keyword list:

        - ``ast.Name("x")``       -> ``[]`` (local -- legacy path)
        - ``ast.Attribute(obj, "X")`` -> ``[owner=<deepcopy obj>, slot_name="X"]``
        - ``ast.Subscript(c, k)`` -> ``[owner=<deepcopy c>, slot_name=<deepcopy k>]``

        Deep copies ensure the caller's target node isn't mutated when the
        emitted Call is pasted into the AST and later visited again.
        """
        if isinstance(target, ast.Attribute):
            owner_node = self._target_as_load(target.value)
            slot_node: ast.expr = ast.Constant(value=target.attr)
            return [
                ast.keyword(arg="owner", value=owner_node),
                ast.keyword(arg="slot_name", value=slot_node),
            ]
        if isinstance(target, ast.Subscript):
            owner_node = self._target_as_load(target.value)
            slot_node = _deepcopy_ast_root(target.slice)
            if hasattr(slot_node, "ctx"):
                slot_node.ctx = ast.Load()
            return [
                ast.keyword(arg="owner", value=owner_node),
                ast.keyword(arg="slot_name", value=slot_node),
            ]
        return []

    @staticmethod
    def _nested_fresh_container_paths(value_node: ast.expr) -> "tuple[tuple, ...]":
        """Constant-keyed paths of NESTED container constructions in a fresh literal
        RHS; alias entries, computed keys, and call results never appear."""
        _CTOR_NODES = (
            ast.List,
            ast.Dict,
            ast.Set,
            ast.ListComp,
            ast.SetComp,
            ast.DictComp,
        )
        paths: list[tuple] = []

        def _walk(node: ast.expr, prefix: tuple) -> None:
            if isinstance(node, ast.Dict):
                for k_node, v_node in zip(node.keys, node.values):
                    # ``None`` key = ``**expansion``; non-Constant = computed key.
                    if k_node is None or not isinstance(k_node, ast.Constant):
                        continue
                    if isinstance(v_node, _CTOR_NODES):
                        p = prefix + (k_node.value,)
                        paths.append(p)
                        _walk(v_node, p)
            elif isinstance(node, ast.List):
                for i, v_node in enumerate(node.elts):
                    if isinstance(v_node, _CTOR_NODES):
                        p = prefix + (i,)
                        paths.append(p)
                        _walk(v_node, p)

        _walk(value_node, ())
        return tuple(paths)

    @staticmethod
    def _callee_root_name(func: ast.expr) -> "str | None":
        """Root ``ast.Name`` id of a callee that is a pure attribute-load chain
        (``Ctor`` / ``pkg.mod.Ctor``), else ``None`` (not re-loadable as a witness)."""
        node = func
        while isinstance(node, ast.Attribute):
            node = node.value
        if isinstance(node, ast.Name):
            return node.id
        return None

    def _target_to_path_str(self, target: ast.expr) -> str:
        """Convert an AST target node to a dotted path string for logging."""
        if isinstance(target, ast.Name):
            return target.id
        elif isinstance(target, ast.Attribute):
            return f"{self._target_to_path_str(target.value)}.{target.attr}"
        elif isinstance(target, ast.Subscript):
            base = self._target_to_path_str(target.value)
            if isinstance(target.slice, ast.Constant):
                return f"{base}[{target.slice.value!r}]"
            return f"{base}[...]"
        return "?"

    def _target_as_load(self, target: ast.expr) -> ast.expr:
        """Deep-copy an assignment target and set context to Load."""
        t = _deepcopy_ast_root(target)
        if isinstance(t, (ast.Name, ast.Attribute, ast.Subscript, ast.Starred)):
            t.ctx = ast.Load()
        # Recursively fix nested ctx (e.g., for a.b where a has Store ctx)
        for child in ast.walk(t):
            if isinstance(child, (ast.Name, ast.Attribute, ast.Subscript)):
                child.ctx = ast.Load()
        return t

    def _subscript_safe_read(self, target: ast.expr) -> ast.expr:
        """Return an AST expression that reads *target* safely.

        For dict-style subscripts ``d['key']``, returns ``d.get('key')``
        so that first-time key insertions don't raise ``KeyError``.
        For all other targets, returns the normal ``_target_as_load`` copy.
        """
        if (
            isinstance(target, ast.Subscript)
            and isinstance(target.slice, ast.Constant)
            and isinstance(target.slice.value, str)
        ):
            return ast.Call(
                func=ast.Attribute(
                    value=_deepcopy_ast_root(target.value),
                    attr="get",
                    ctx=ast.Load(),
                ),
                args=[ast.Constant(value=target.slice.value)],
                keywords=[],
            )
        return self._target_as_load(target)

    def _collect_attr_reads(
        self, node: ast.AST, exclude_paths: set[str] | None = None
    ) -> list[tuple[str, str, str]]:
        """Collect ``self.X`` attribute reads from *node*.

        Returns a deduplicated list of ``(path_str, base_name, attr_name)``
        for every ``ast.Attribute(ctx=Load)`` whose ``value`` is the plain
        ``ast.Name`` ``self`` -- i.e. ``self.x`` but not ``self.x.y``.
        Skips attributes that are call targets (``self.advance()``), and
        any path in *exclude_paths*.
        """
        if exclude_paths is None:
            exclude_paths = set()

        call_func_ids = self._collect_call_func_ids(node)
        # Comprehension/lambda-local names live in a private scope; must not be
        # hoisted to the statement-scope prologue.
        bound = _locally_bound_names(node)
        # Lambda-body / genexp reads are LATE-BOUND by Python; hoisting them
        # would early-bind the capture at statement time.
        deferred = _deferred_execution_node_ids(node)
        # Short-circuited positions (BoolOp tails, IfExp arms) may never
        # evaluate; hoisting a read out of them would fire accessors Python
        # short-circuits past.  A path with an unconditional occurrence
        # still hoists (and its temp substitutes every occurrence).
        conditional = self._conditional_eval_node_ids(node)

        seen: set[str] = set()
        results: list[tuple[str, str, str]] = []
        for child in ast.walk(node):
            if (
                isinstance(child, ast.Attribute)
                and isinstance(child.ctx, ast.Load)
                and isinstance(child.value, ast.Name)
                and child.value.id == "self"
                and child.value.id not in bound
                and id(child) not in call_func_ids
                and id(child) not in deferred
                and id(child) not in conditional
            ):
                path_str = f"{child.value.id}.{child.attr}"
                if path_str not in exclude_paths and path_str not in seen:
                    seen.add(path_str)
                    results.append((path_str, child.value.id, child.attr))
        return results

    @staticmethod
    def _collect_call_func_ids(node: ast.AST) -> set[int]:
        """Build the set of AST node ``id()`` values that appear as call targets.

        For ``self.state.advance()``, this set contains the outer
        ``.advance`` Attribute AND every Attribute up its ``.value`` chain
        (so we also skip ``self.state``). Plain Name call targets
        (``range(...)``, ``Boo()``) are added too so D1 Name-Load
        instrumentation skips them.
        """
        call_func_ids: set[int] = set()
        for child in ast.walk(node):
            if not isinstance(child, ast.Call):
                continue
            func = child.func
            if isinstance(func, ast.Name):
                call_func_ids.add(id(func))
            elif isinstance(func, ast.Attribute):
                call_func_ids.add(id(func))
                val = func.value
                while isinstance(val, ast.Attribute):
                    call_func_ids.add(id(val))
                    val = val.value
        return call_func_ids

    def _is_module_or_class_name(self, name: str) -> bool:
        """Return True when *name* resolves to a Python module / class / type.

        Looked up through ``session_data.function_globals``. Used by D1
        Name-Load instrumentation to skip module names
        and class/type references (``Boo``, ``Int32``) that should never
        be rewritten to ``pyir_read``.

        A local bound ONLY by plain ``import`` statements IS a module spelling
        (nearest binding scope decides; other local bindings fall through to
        the global view, today's answer).
        """
        from types import ModuleType

        for bound, import_only, _from_only in reversed(self._pyir_import_scope_stack):
            if name in import_only:
                return True
            if name in bound:
                break
        fn_globals = self.session_data.function_globals
        if not fn_globals:
            return False
        obj = fn_globals.get(name)
        if obj is None:
            return False
        if isinstance(obj, ModuleType):
            return True
        if isinstance(obj, type):
            return True
        return False

    def _reading_module_name(self) -> "str | None":
        """The ``__name__`` of the module whose globals resolve this function's
        symbol reads; the record-only chokes root module-level bakes there."""
        fn_globals = self.session_data.function_globals
        if not fn_globals:
            return None
        name = fn_globals.get("__name__")
        return name if isinstance(name, str) else None

    def _collect_other_attr_reads(
        self, node: ast.AST, exclude_paths: set[str] | None = None
    ) -> list[tuple[str, str, str, bool]]:
        """Collect ``obj.X`` attribute reads from *node* (D1 Attribute-Load).

        Returns a deduplicated list of ``(path_str, base_name, attr_name,
        record_only)`` for every ``ast.Attribute(ctx=Load)`` whose ``value``
        is a plain ``ast.Name`` other than ``self``. ``self.X`` is handled by
        :py:meth:`_collect_attr_reads`.

        ``record_only=False`` legs route through the staging ``pyir_read``
        hoist (in-CF reads of instance receivers, unchanged).  A module/class
        spelling, or a symbol-rooted read at function scope, has no staging
        role but still bakes its value: those legs hoist through the
        record-only ``_pyir_obs_read`` choke instead (F-SPEC observation).
        """
        if exclude_paths is None:
            exclude_paths = set()
        inside_cf = self._is_inside_cf_scope()
        active = self.session_data.scope_manager.get_active_symbols()

        def _in_scope(name: str) -> bool:
            return any(name in scope for scope in active)

        fn_globals = self.session_data.function_globals or {}
        call_func_ids = self._collect_call_func_ids(node)
        # Comprehension/lambda-local names live in a private scope; must not be
        # hoisted to the statement-scope prologue.
        bound = _locally_bound_names(node)
        # Lambda-body / genexp reads are LATE-BOUND by Python; hoisting them
        # would early-bind the capture at statement time.
        deferred = _deferred_execution_node_ids(node)
        # Short-circuited positions (BoolOp tails, IfExp arms) may never
        # evaluate; hoisting a read out of them would fire accessors Python
        # short-circuits past.
        conditional = self._conditional_eval_node_ids(node)

        seen: set[str] = set()
        results: list[tuple[str, str, str, bool]] = []
        for child in ast.walk(node):
            if not (
                isinstance(child, ast.Attribute)
                and isinstance(child.ctx, ast.Load)
                and isinstance(child.value, ast.Name)
            ):
                continue
            base = child.value.id
            if base == "self":
                continue  # handled by _collect_attr_reads
            if base in bound:
                continue  # comprehension/lambda-local; not in statement scope
            if id(child) in call_func_ids:
                continue
            if id(child) in deferred:
                continue  # lambda-body / genexp read: late-bound at call time
            if id(child) in conditional:
                continue  # short-circuited position: read stays in place
            if base in ("__base_dsl__", "__module_dsl__", _PYIR_RUNTIME_ALIAS):
                continue
            if self._is_module_or_class_name(base):
                record_only = True  # module/class spelling: observe, no staging
            elif inside_cf:
                record_only = False  # staging hoist (unchanged in-CF contract)
            elif (
                not _in_scope(base) and base in fn_globals
            ) or self._pyir_from_import_bound(base):
                record_only = True  # symbol-rooted read (global or from-import)
            else:
                continue  # function-scope local receiver: staging owns it
            path_str = f"{base}.{child.attr}"
            if path_str in exclude_paths or path_str in seen:
                continue
            seen.add(path_str)
            results.append((path_str, base, child.attr, record_only))
        return results

    @staticmethod
    def _subscript_read_choke_parts(node: ast.expr) -> "tuple[str, ast.expr] | None":
        """``(recorded_path, container_expr)`` when *node* is an already-emitted
        ``_pyir_post_subscript_read(path, container, key)`` choke call, else None."""
        if (
            isinstance(node, ast.Call)
            and isinstance(node.func, ast.Attribute)
            and node.func.attr == "_pyir_post_subscript_read"
            and len(node.args) == 3
            and isinstance(node.args[0], ast.Constant)
            and isinstance(node.args[0].value, str)
        ):
            return node.args[0].value, node.args[1]
        return None

    def _access_path_str(self, node: ast.expr) -> "str | None":
        """Dotted path string for a PURE access-path expression (Name / Attribute /
        Subscript chains and the subscript-read choke); ``None`` otherwise."""
        if isinstance(node, ast.Name):
            return node.id
        if isinstance(node, ast.Attribute):
            base = self._access_path_str(node.value)
            return None if base is None else f"{base}.{node.attr}"
        if isinstance(node, ast.Subscript):
            base = self._access_path_str(node.value)
            if base is None:
                return None
            if isinstance(node.slice, ast.Constant):
                return f"{base}[{node.slice.value!r}]"
            key = self._access_path_str(node.slice)
            return None if key is None else f"{base}[{key}]"
        choke = self._subscript_read_choke_parts(node)
        if choke is not None:
            path, container = choke
            return None if self._access_path_str(container) is None else path
        return None

    def _access_path_root_name(self, node: ast.expr) -> "str | None":
        """Root ``ast.Name`` id of a pure access-path expression, else None."""
        while True:
            if isinstance(node, ast.Name):
                return node.id
            if isinstance(node, (ast.Attribute, ast.Subscript)):
                node = node.value
                continue
            choke = self._subscript_read_choke_parts(node)
            if choke is None:
                return None
            node = choke[1]

    @staticmethod
    def _conditional_eval_node_ids(node: ast.AST) -> set[int]:
        """AST node ids in positions the statement may never evaluate (BoolOp
        operands after the first, IfExp arms): a hoisted pre-read of a deep
        path there would evaluate what Python short-circuits past."""
        cond_ids: set[int] = set()
        for child in ast.walk(node):
            lazy_parts: list[ast.expr] = []
            if isinstance(child, ast.BoolOp):
                lazy_parts = child.values[1:]
            elif isinstance(child, ast.IfExp):
                lazy_parts = [child.body, child.orelse]
            for part in lazy_parts:
                for sub in ast.walk(part):
                    cond_ids.add(id(sub))
        return cond_ids

    def _access_chain_segments(
        self, node: ast.expr
    ) -> "tuple[ast.expr, list[tuple[str, Any, Any]]] | None":
        """Decompose a read-chain base into ``(root, hops)`` walking out from
        the root.  The root is an ``ast.Name`` or a call expression (hoisted
        into a synthetic local at emission); each hop is ``("attr", name,
        None)`` or ``("sub", key_expr, choked)`` where *choked* marks an
        already-emitted subscript-read choke.  Returns ``None`` for shapes
        that are not access chains or whose raw subscript keys are neither
        constants nor pure access paths."""
        hops: list[tuple[str, Any, Any]] = []
        while True:
            if isinstance(node, ast.Name):
                return node, list(reversed(hops))
            if isinstance(node, ast.Attribute):
                hops.append(("attr", node.attr, None))
                node = node.value
                continue
            if isinstance(node, ast.Subscript):
                if not (
                    isinstance(node.slice, ast.Constant)
                    or self._access_path_str(node.slice) is not None
                ):
                    return None
                hops.append(("sub", node.slice, False))
                node = node.value
                continue
            if self._subscript_read_choke_parts(node) is not None:
                assert isinstance(node, ast.Call)
                hops.append(("sub", node.args[2], True))
                node = node.args[1]
                continue
            if isinstance(node, ast.Call):
                return node, list(reversed(hops))
            return None

    def _collect_deep_attr_reads(
        self, node: ast.AST, exclude_paths: set[str] | None = None
    ) -> list[tuple[str, ast.expr, str, list[int]]]:
        """Collect attribute reads whose base is itself an access chain
        (``a.b.x``, ``self.d["k"].x``, ``self.helper().x``): every
        ``ast.Attribute(ctx=Load)`` whose ``.value`` decomposes into hops over
        a pure access path or a call-bearing root (temp-hoisted at emission).
        The write side (``_slot_kwargs_for``) accepts ANY base; this hands
        standalone reads the same owner/slot place fact, hop by hop.

        ``self``-rooted paths follow the ``self.X`` collector's scope rules;
        other roots (including call roots) follow the ``obj.X`` collector's
        CF-scope gate.  Returns ``(path_str, base_node, attr_name, node_ids)``
        -- replacement is keyed on node identity because the base is an
        expression, not a name.  A chain deeper than the per-statement budget
        refuses loudly rather than truncating.
        """
        if exclude_paths is None:
            exclude_paths = set()
        inside_cf = self._is_inside_cf_scope()
        call_func_ids = self._collect_call_func_ids(node)
        # Hop receivers and keys are hoisted to statement scope; a chain
        # touching a comprehension/lambda-local name cannot be hoisted.
        bound = _locally_bound_names(node)
        deferred = _deferred_execution_node_ids(node)
        conditional = self._conditional_eval_node_ids(node)
        # Only MAXIMAL chains: an Attribute serving as the base of a longer
        # attribute chain is covered by that chain's read.
        inner_base_ids = {
            id(c.value)
            for c in ast.walk(node)
            if isinstance(c, ast.Attribute) and isinstance(c.value, ast.Attribute)
        }
        grouped: dict[str, tuple[ast.expr, str, list[int]]] = {}
        for child in ast.walk(node):
            if not (
                isinstance(child, ast.Attribute)
                and isinstance(child.ctx, ast.Load)
                and not isinstance(child.value, ast.Name)
            ):
                continue
            if (
                id(child) in call_func_ids
                or id(child) in deferred
                or id(child) in conditional
                or id(child) in inner_base_ids
            ):
                continue
            seg = self._access_chain_segments(child.value)
            if seg is None:
                continue
            root, hops = seg
            if bound and any(
                isinstance(sub, ast.Name) and sub.id in bound
                for sub in ast.walk(child.value)
            ):
                continue
            if isinstance(root, ast.Name):
                root_name = root.id
                if root_name in ("__base_dsl__", "__module_dsl__", _PYIR_RUNTIME_ALIAS):
                    continue
                if root_name != "self" and (
                    not inside_cf or self._is_module_or_class_name(root_name)
                ):
                    continue
                base_path = self._access_path_str(child.value)
                if base_path is None:
                    continue
                path_str = f"{base_path}.{child.attr}"
                if path_str in exclude_paths:
                    continue
                group_key = path_str
            else:
                # Call-rooted chain: one hoisted evaluation per occurrence,
                # so occurrences are never merged by spelling.
                if not inside_cf:
                    continue
                path_str = f"<call>.{child.attr}"
                group_key = f"<call#{id(child)}>"
            if len(hops) + 1 > _READ_CHAIN_HOP_BUDGET:
                raise DSLUserCodeError(
                    DiagId.READ_DEPTH_OVERFLOW,
                    var=ast.unparse(child),
                    depth=len(hops) + 1,
                    budget=_READ_CHAIN_HOP_BUDGET,
                )
            entry = grouped.get(group_key)
            if entry is None:
                grouped[group_key] = (child.value, child.attr, [id(child)])
            else:
                entry[2].append(id(child))
        return [(p, b, a, ids) for p, (b, a, ids) in grouped.items()]

    def _is_inside_cf_scope(self) -> bool:
        """Return True when we are currently visiting statements that are
        nested inside a control-flow scope (for/if/while body).

        ``ScopeManager.enter_control_flow_scope`` only pushes a new
        variable scope; ``enter_local_scope`` pushes both a variable
        scope and a callable scope. So ``len(scopes) > len(callables)``
        whenever we are inside at least one CF body. Used by D1's
        Name-Load instrumentation to gate writeback emission: at
        function scope a redundant ``a = pyir_read('a', a)`` would
        introduce an extra ``pyir.load`` (legacy ``_mutable_ref`` path
        already handles post-loop reads via ``_pyir_auto_load_arg``).
        """
        sm = self.session_data.scope_manager
        try:
            return len(sm.scopes) > len(sm.callables)
        except Exception:
            return False

    def _collect_name_loads(
        self, node: ast.AST, exclude_names: set[str] | None = None
    ) -> list[str]:
        """Collect plain ``Name`` reads from *node* (D1 Name-Load).

        Returns a deduplicated list of variable names for every
        ``ast.Name(ctx=Load)`` that:
          * is currently in scope (a local of the enclosing function);
          * is not a skip-pyir variable (loop induction etc.);
          * is not a module / class / type identifier;
          * is not the function of a Call (``range(...)``, ``Boo()``);
          * is not the ``.value`` of an Attribute (already covered by
            attribute-read instrumentation);
          * is not the synthetic ``__base_dsl__`` / ``__module_dsl__``
            module references injected by the preprocessor.

        Function-scope Name reads remain handled by ``_pyir_auto_load_arg``
        (which now routes through the unified `_SLOT_REGISTRY`); wrapping
        them here would be redundant.  The CF-scope gate stays.
        """
        if not self._is_inside_cf_scope():
            return []
        if exclude_names is None:
            exclude_names = set()

        call_func_ids = self._collect_call_func_ids(node)
        # Comprehension/lambda-local names live in a private scope; must not be
        # hoisted to the statement-scope prologue.
        bound = _locally_bound_names(node)
        # Lambda-body / genexp reads are LATE-BOUND by Python; hoisting them
        # would early-bind the capture at statement time.
        deferred = _deferred_execution_node_ids(node)
        # Short-circuited positions (BoolOp tails, IfExp arms) may never
        # evaluate; hoisting a read out of them would evaluate what Python
        # short-circuits past (an unbound name would raise eagerly).
        conditional = self._conditional_eval_node_ids(node)

        # Names that appear as the .value of an Attribute (and so are
        # already handled by attribute-read instrumentation) — skip them
        # to keep the rewritten AST tidy. We still wrap names that ALSO
        # appear elsewhere as bare reads.
        attr_value_only_ids: set[int] = set()
        bare_name_ids: set[int] = set()
        for child in ast.walk(node):
            if isinstance(child, ast.Attribute) and isinstance(child.value, ast.Name):
                attr_value_only_ids.add(id(child.value))
            elif isinstance(child, ast.Name) and isinstance(child.ctx, ast.Load):
                bare_name_ids.add(id(child))

        active = self.session_data.scope_manager.get_active_symbols()

        def _in_scope(name: str) -> bool:
            return any(name in scope for scope in active)

        seen: set[str] = set()
        results: list[str] = []
        for child in ast.walk(node):
            if not (isinstance(child, ast.Name) and isinstance(child.ctx, ast.Load)):
                continue
            if id(child) in call_func_ids:
                continue
            if id(child) in deferred:
                continue  # lambda-body / genexp read: late-bound at call time
            if id(child) in conditional:
                continue  # short-circuited position: read stays in place
            if (
                id(child) in attr_value_only_ids
                and id(child) not in bare_name_ids - attr_value_only_ids
            ):
                # The only occurrences are as Attribute bases — the
                # attribute-read instrumentation already covers reads
                # through obj.attr. Wrapping the bare obj would be
                # redundant.
                pass  # but we still allow if it appears as bare elsewhere
            name = child.id
            if name in exclude_names or name in seen:
                continue
            if name in bound:
                continue  # comprehension/lambda-local; not in statement scope
            if name in ("__base_dsl__", "__module_dsl__", _PYIR_RUNTIME_ALIAS):
                continue
            if self.session_data.scope_manager.is_skip_reference_taking(name):
                continue
            if not _in_scope(name):
                continue
            if self._is_module_or_class_name(name):
                continue
            # Skip names that ONLY appear as Attribute base. Without this
            # we emit `boo = pyir_read('boo', boo)` for every `boo.val`,
            # which is correct but noisy.
            other_uses = [
                c
                for c in ast.walk(node)
                if isinstance(c, ast.Name)
                and isinstance(c.ctx, ast.Load)
                and c.id == name
                and id(c) not in attr_value_only_ids
                and id(c) not in call_func_ids
                and id(c) not in deferred
                and id(c) not in conditional
            ]
            if not other_uses:
                continue
            seen.add(name)
            results.append(name)
        return results

    def _collect_global_name_reads(
        self, node: ast.AST, exclude_names: set[str] | None = None
    ) -> list[str]:
        """Collect bare GLOBAL ``Name(ctx=Load)`` reads from *node*: names not
        bound in any active local scope that resolve through the function's
        globals to a non-module/class/function value.  These reads have no
        staging choke at any scope, so they hoist through the record-only
        ``_pyir_obs_global_read`` choke (F-SPEC observation)."""
        if exclude_names is None:
            exclude_names = set()
        fn_globals = self.session_data.function_globals
        if not fn_globals:
            return []
        active = self.session_data.scope_manager.get_active_symbols()

        def _in_scope(name: str) -> bool:
            return any(name in scope for scope in active)

        call_func_ids = self._collect_call_func_ids(node)
        bound = _locally_bound_names(node)
        deferred = _deferred_execution_node_ids(node)
        # Short-circuited positions (BoolOp tails, IfExp arms) may never
        # evaluate; hoisting a read out of them would evaluate what Python
        # short-circuits past (a missing global would raise eagerly).
        conditional = self._conditional_eval_node_ids(node)
        # Names serving only as Attribute bases are observed by the attr choke.
        attr_base_ids = {
            id(child.value)
            for child in ast.walk(node)
            if isinstance(child, ast.Attribute) and isinstance(child.value, ast.Name)
        }

        seen: set[str] = set()
        results: list[str] = []
        for child in ast.walk(node):
            if not (isinstance(child, ast.Name) and isinstance(child.ctx, ast.Load)):
                continue
            name = child.id
            if name in exclude_names or name in seen:
                continue
            if id(child) in call_func_ids or id(child) in deferred:
                continue
            if id(child) in conditional:
                continue  # short-circuited position: read stays in place
            if id(child) in attr_base_ids:
                continue
            if name in bound or name.startswith("_pyir_"):
                continue
            if name in ("__base_dsl__", "__module_dsl__", _PYIR_RUNTIME_ALIAS):
                continue
            if self.session_data.scope_manager.is_skip_reference_taking(name):
                continue
            if _in_scope(name):
                continue  # a local binding, never the module global
            if name not in fn_globals:
                continue  # builtin / closure free var: no module root
            obj = fn_globals.get(name)
            if isinstance(
                obj,
                (
                    types.ModuleType,
                    type,
                    types.FunctionType,
                    types.BuiltinFunctionType,
                ),
            ):
                continue  # symbol references, never scalar bakes
            seen.add(name)
            results.append(name)
        return results

    def _build_first_def_pyir_assigns(
        self,
        node: ast.Assign,
        first_def_targets: list[ast.expr],
    ) -> list[ast.stmt]:
        """Build ``pyir_assign(name, None, target, file, line)`` for first-defs.

        For a first-time definition ``x = expr``, emits (AFTER the original
        assignment):

            x = pyir_assign("x", None, x, __file__, lineno)

        This allows ``pyir_assign`` to create an eager ref when the first
        definition occurs inside staged CF (e.g., inside a for-loop body).
        The ``None`` old_value signals a first-def to ``pyir_assign``.

        For ``self.X`` first-defs in ``__init__`` we emit owner/slot-keyed
        instrumentation so ``pyir_assign`` registers the ref in the slot
        store::

            self.X = pyir_assign("self.X", None, self.X, file, line,
                                 owner=self, slot_name="X")

        Critically, the original assignment runs BEFORE this call, so
        ``self.X`` exists by the time ``pyir_assign`` reads it -- no
        ``AttributeError`` (the crash that motivated the
        ``seen_init_attrs`` first-def skip in the first place).
        """
        stmts: list[ast.stmt] = []
        for target in first_def_targets:
            lineno = node.lineno
            path_str = self._target_to_path_str(target)
            slot_kwargs = self._slot_kwargs_for(target)
            target_load = self._target_as_load(target)

            written_kwargs = [_deepcopy_ast_root(kw) for kw in slot_kwargs]
            # Declare a CONSTRUCTED container RHS (literal/comprehension/concat):
            # fresh, so element slots may be replaced in place. Alias RHS: no fact.
            if isinstance(target, ast.Name) and isinstance(
                node.value,
                (
                    ast.List,
                    ast.Dict,
                    ast.Set,
                    ast.ListComp,
                    ast.SetComp,
                    ast.DictComp,
                    ast.BinOp,
                ),
            ):
                written_kwargs = written_kwargs + [
                    ast.keyword(arg="fresh_binding", value=ast.Constant(value=True))
                ]
                # Declare constant-keyed NESTED constructions so the re-init recurses
                # exactly into re-constructed sub-containers (never an alias entry).
                _fresh_paths = self._nested_fresh_container_paths(node.value)
                if _fresh_paths:
                    written_kwargs = written_kwargs + [
                        ast.keyword(
                            arg="fresh_paths",
                            value=ast.Tuple(
                                elts=[
                                    ast.Tuple(
                                        elts=[ast.Constant(value=_c) for _c in _p],
                                        ctx=ast.Load(),
                                    )
                                    for _p in _fresh_paths
                                ],
                                ctx=ast.Load(),
                            ),
                        )
                    ]
            # Declare a direct-call RHS's callee so the runtime can witness a
            # plain-allocating construction (a chain via the new binding never can).
            if (
                isinstance(target, ast.Name)
                and isinstance(node.value, ast.Call)
                and self._callee_root_name(node.value.func) not in (None, target.id)
            ):
                written_kwargs = written_kwargs + [
                    ast.keyword(
                        arg="rhs_ctor",
                        value=self._target_as_load(node.value.func),
                    )
                ]

            pyir_call = ast.Call(
                func=_create_runtime_attribute(
                    "pyir_assign",
                    lineno=lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    ast.Constant(value=path_str),
                    ast.Constant(value=None),
                    target_load,
                    ast.Constant(value=self.session_data.file_name),
                    ast.Constant(value=lineno),
                ],
                keywords=written_kwargs,
            )
            reassign = ast.Assign(
                targets=[_deepcopy_ast_root(target)],
                value=pyir_call,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(reassign), node))
        return stmts

    def _build_generation_probe_stmts(
        self, node: ast.stmt, exclude_paths: set[str] | None = None
    ) -> list[ast.stmt]:
        """One ``pyir_generation_probe("base.attr")`` per Name-rooted attribute load
        of a function-scope statement; empty inside a CF scope."""
        if self._is_inside_cf_scope():
            return []
        call_func_ids = self._collect_call_func_ids(node)
        bound = _locally_bound_names(node)
        seen: set[str] = set()
        stmts: list[ast.stmt] = []
        for child in ast.walk(node):
            if not (
                isinstance(child, ast.Attribute)
                and isinstance(child.ctx, ast.Load)
                and isinstance(child.value, ast.Name)
            ):
                continue
            base = child.value.id
            if base in bound or id(child) in call_func_ids:
                continue
            if base in ("__base_dsl__", "__module_dsl__", _PYIR_RUNTIME_ALIAS):
                continue
            if self._is_module_or_class_name(base):
                continue
            path_str = f"{base}.{child.attr}"
            if (exclude_paths and path_str in exclude_paths) or path_str in seen:
                continue
            seen.add(path_str)
            lineno = node.lineno
            col_offset = getattr(node, "col_offset", 0)
            probe = ast.Expr(
                value=ast.Call(
                    func=_create_runtime_attribute(
                        "pyir_generation_probe",
                        lineno=lineno,
                        col_offset=col_offset,
                    ),
                    args=[ast.Constant(value=path_str)],
                    keywords=[],
                )
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(probe), node))
        return stmts

    def _insert_pyir_attr_reads(
        self, node: ast.stmt, exclude_paths: set[str] | None = None
    ) -> ast.stmt | list[ast.stmt]:
        """Insert pyir_read instrumentation for D1 meta-value tracking.

        Three patterns are emitted, in this order, BEFORE *node*:

          * For ``self.X`` Attribute-Load reads: ``_pyir_attr_N =
            pyir_read("self.X", self.X, attach_ref=False, owner=self,
            slot_name="X")`` and a substitution that replaces the
            attribute access with ``_pyir_attr_N`` (local-var pattern --
            existing behaviour, preserved to avoid ``_mutable_ref``
            leakage across object boundaries in returns / constructor
            args).

          * For ``obj.X`` Attribute-Load reads (D1 extension): write
            back to the attribute, ``obj.X = pyir_read("obj.X", obj.X,
            owner=obj, slot_name="X")``. Module receivers and call
            targets are skipped.

          * For ``name`` Name-Load reads (D1 extension): write back to
            the local, ``name = pyir_read("name", name)``. Modules /
            classes / skip-vars / call targets are filtered out.

        Returns ``[read_stmt, ..., modified_node]`` if any pattern fired,
        else *node* unchanged. All three patterns run on the same node so
        a single downstream-DSL print call ``print_api(boo.val, bar)`` statement instruments both
        ``boo.val`` and ``bar`` in one call.
        """
        exclude_paths_set = exclude_paths or set()
        self_reads = self._collect_attr_reads(node, exclude_paths)
        other_attr_reads = self._collect_other_attr_reads(node, exclude_paths)
        deep_attr_reads = self._collect_deep_attr_reads(node, exclude_paths)
        name_loads = self._collect_name_loads(node, exclude_paths)
        global_name_reads = self._collect_global_name_reads(node, exclude_paths)

        # Don't emit a Name-Load writeback for a name that already serves
        # as the owner of a non-self Attribute writeback we just emitted:
        # `boo = pyir_read('boo', boo)` is redundant with
        # `boo.val = pyir_read('boo.val', boo.val, owner=boo, ...)`.
        attr_owner_names = {base for _, base, _, _ in other_attr_reads}
        name_loads = [n for n in name_loads if n not in attr_owner_names]

        # Function-scope superseded-generation probes (empty inside CF scope,
        # where the collectors above carry the access-root name instead).
        probe_stmts = self._build_generation_probe_stmts(node, exclude_paths)

        if (
            not self_reads
            and not other_attr_reads
            and not deep_attr_reads
            and not name_loads
            and not global_name_reads
        ):
            if probe_stmts:
                return [*probe_stmts, node]
            return node

        stmts: list[ast.stmt] = []
        # Map from (base_name, attr_name) -> local var name for replacement
        replacements: dict[tuple[str, str], str] = {}
        # Path -> temp of every read emitted for this statement; deep chains
        # reuse these as hop receivers instead of re-reading a prefix.
        hop_temps: dict[str, str] = {}

        # ----- (1) self.X reads using local-var pattern (existing) -----
        for path_str, base_name, attr_name in self_reads:
            lineno = node.lineno
            col_offset = getattr(node, "col_offset", 0)

            local_var = f"_pyir_attr_{self.session_data.counter}"
            self.session_data.counter += 1
            replacements[(base_name, attr_name)] = local_var
            hop_temps[path_str] = local_var

            attr_load = ast.Attribute(
                value=ast.Name(id=base_name, ctx=ast.Load()),
                attr=attr_name,
                ctx=ast.Load(),
            )
            pyir_read_call = ast.Call(
                func=_create_runtime_attribute(
                    "pyir_read",
                    lineno=lineno,
                    col_offset=col_offset,
                ),
                args=[
                    ast.Constant(value=path_str),
                    attr_load,
                ],
                keywords=[
                    ast.keyword(arg="attach_ref", value=ast.Constant(value=False)),
                    ast.keyword(
                        arg="owner",
                        value=ast.Name(id=base_name, ctx=ast.Load()),
                    ),
                    ast.keyword(
                        arg="slot_name",
                        value=ast.Constant(value=attr_name),
                    ),
                ],
            )
            read_stmt = ast.Assign(
                targets=[ast.Name(id=local_var, ctx=ast.Store())],
                value=pyir_read_call,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(read_stmt), node))

        # ----- (2) obj.X reads using local-var pattern (D1) -----
        # We avoid the write-back ``obj.X = pyir_read(...)`` shape here
        # because some receivers expose ``X`` as a read-only ``@property``
        # (e.g. PipelineState.index) and ``setattr`` would raise
        # ``AttributeError: property has no setter``. A local var also
        # mirrors the self.X behaviour, keeping ``_mutable_ref`` from
        # leaking through object boundaries when the load is fed into
        # constructors or returns.
        for path_str, base_name, attr_name, record_only in other_attr_reads:
            lineno = node.lineno
            col_offset = getattr(node, "col_offset", 0)

            local_var = f"_pyir_attr_{self.session_data.counter}"
            self.session_data.counter += 1
            replacements[(base_name, attr_name)] = local_var
            hop_temps[path_str] = local_var

            if record_only:
                # Symbol-rooted read with no staging role (module/class
                # spelling or function-scope global object): the record-only
                # observation choke evaluates the same getattr in place.
                pyir_read_call = ast.Call(
                    func=_create_runtime_attribute(
                        "_pyir_obs_read",
                        lineno=lineno,
                        col_offset=col_offset,
                    ),
                    args=[
                        ast.Constant(value=path_str),
                        ast.Name(id=base_name, ctx=ast.Load()),
                        ast.Constant(value=attr_name),
                        ast.Constant(value=self._reading_module_name()),
                    ],
                    keywords=[],
                )
            else:
                attr_load = ast.Attribute(
                    value=ast.Name(id=base_name, ctx=ast.Load()),
                    attr=attr_name,
                    ctx=ast.Load(),
                )
                pyir_read_call = ast.Call(
                    func=_create_runtime_attribute(
                        "pyir_read",
                        lineno=lineno,
                        col_offset=col_offset,
                    ),
                    args=[
                        ast.Constant(value=path_str),
                        attr_load,
                    ],
                    keywords=[
                        ast.keyword(arg="attach_ref", value=ast.Constant(value=False)),
                        ast.keyword(
                            arg="owner",
                            value=ast.Name(id=base_name, ctx=ast.Load()),
                        ),
                        ast.keyword(
                            arg="slot_name",
                            value=ast.Constant(value=attr_name),
                        ),
                    ],
                )
            read_stmt = ast.Assign(
                targets=[ast.Name(id=local_var, ctx=ast.Store())],
                value=pyir_read_call,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(read_stmt), node))

        # ----- (3) Name-Load reads using substitution pattern (D1) -----
        # We use a substitution pattern (``_pyir_name_N = pyir_read(...)``)
        # rather than write-back (``name = pyir_read(...)``) for two
        # reasons:
        #   * Write-back inside a closure body shadows the outer name,
        #     forcing it into the loop's ``write_args``. Read-only loop
        #     variables like ``tar`` in mixing.py would then be carried
        #     through SCF and emerge as dynamic ``Boolean`` SSA, breaking
        #     ``const_expr(tar)``.
        #   * Wrapping a closure-captured function-arg (``n`` in
        #     ``while x < n``) with write-back would also create a wasted
        #     ``pyir.ref %arg``.
        # The substitution is purely local: the original Name uses in
        # ``node`` get rewritten to ``_pyir_name_N`` references.
        #
        # ``attach_ref=False`` is passed so ``pyir_read`` does NOT lazily
        # create a ``pyir.ref`` for staged DSL values that lack a
        # ``_mutable_ref``. We only need the D1 ``_meta_uses`` recording
        # path (for Python primitives) -- DSL values are passed through
        # untouched, and the existing ``_pyir_auto_load_arg`` boundary
        # still emits ``pyir.load`` for values that DO carry a ref.
        #
        # Emitted BEFORE the deep-chain hoists: a hoisted call base
        # references the name temps, and a local name binding cannot be
        # changed by evaluating the call, so the pre-read is safe.
        name_replacements: dict[str, str] = {}
        for name in name_loads:
            lineno = node.lineno
            col_offset = getattr(node, "col_offset", 0)

            local_var = f"_pyir_name_{self.session_data.counter}"
            self.session_data.counter += 1
            name_replacements[name] = local_var

            pyir_read_call = ast.Call(
                func=_create_runtime_attribute(
                    "pyir_read",
                    lineno=lineno,
                    col_offset=col_offset,
                ),
                args=[
                    ast.Constant(value=name),
                    ast.Name(id=name, ctx=ast.Load()),
                ],
                keywords=[
                    ast.keyword(arg="attach_ref", value=ast.Constant(value=False)),
                ],
            )
            read_stmt = ast.Assign(
                targets=[ast.Name(id=local_var, ctx=ast.Store())],
                value=pyir_read_call,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(read_stmt), node))

        # ----- (3b) bare GLOBAL Name reads: record-only observation -----
        # No staging choke exists for a module-level binding at any scope;
        # the baked value still records under its module root (F-SPEC).
        for name in global_name_reads:
            if name in name_replacements:
                continue
            lineno = node.lineno
            col_offset = getattr(node, "col_offset", 0)

            local_var = f"_pyir_name_{self.session_data.counter}"
            self.session_data.counter += 1
            name_replacements[name] = local_var

            obs_call = ast.Call(
                func=_create_runtime_attribute(
                    "_pyir_obs_global_read",
                    lineno=lineno,
                    col_offset=col_offset,
                ),
                args=[
                    ast.Constant(value=name),
                    ast.Name(id=name, ctx=ast.Load()),
                    ast.Constant(value=self._reading_module_name()),
                ],
                keywords=[],
            )
            read_stmt = ast.Assign(
                targets=[ast.Name(id=local_var, ctx=ast.Store())],
                value=obs_call,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(read_stmt), node))

        # ----- (2b) deep-path reads: hop-wise three-address lowering -----
        # Each hop is choked on its runtime-resolved receiver (owner = the
        # previous hop's temp), so every leg of a.b["k"].x lands on the place
        # the write side names; a call-bearing base hoists the call into a
        # temp first (single evaluation) and later hops chain off the temp.
        deep_replacements: dict[int, str] = {}
        call_hoist_stmts: list[ast.stmt] = []
        if deep_attr_reads:
            # Chains nested inside another chain's base (call args, keys)
            # emit first so the enclosing hoist references their temps.
            node_depths = _ast_node_depths(node)
            deep_attr_reads = sorted(
                deep_attr_reads,
                key=lambda rec: -max(node_depths.get(nid, 0) for nid in rec[3]),
            )
        for _, base_node, attr_name, node_ids in deep_attr_reads:
            lineno = node.lineno
            col_offset = getattr(node, "col_offset", 0)
            seg = self._access_chain_segments(base_node)
            if seg is None:
                continue
            root, hops = seg
            hops = [*hops, ("attr", attr_name, None)]
            if isinstance(root, ast.Name):
                recv = root.id
                cur_path = root.id
            else:
                recv = f"_pyir_call_{self.session_data.counter}"
                self.session_data.counter += 1
                # The call node moves out of the statement verbatim (its
                # occurrence is replaced wholesale by the final hop temp).
                hoist = ast.Assign(
                    targets=[ast.Name(id=recv, ctx=ast.Store())],
                    value=root,
                )
                hoist = ast.copy_location(ast.fix_missing_locations(hoist), node)
                stmts.append(hoist)
                call_hoist_stmts.append(hoist)
                cur_path = recv
            for kind, payload, choked in hops:
                if kind == "attr":
                    hop_path = f"{cur_path}.{payload}"
                elif isinstance(payload, ast.Constant):
                    hop_path = f"{cur_path}[{payload.value!r}]"
                else:
                    hop_path = f"{cur_path}[{self._access_path_str(payload)}]"
                existing = hop_temps.get(hop_path)
                if existing is not None:
                    recv, cur_path = existing, hop_path
                    continue
                local_var = f"_pyir_attr_{self.session_data.counter}"
                self.session_data.counter += 1
                recv_load = ast.Name(id=recv, ctx=ast.Load())
                value: ast.expr
                if kind == "attr":
                    attr_load = ast.Attribute(
                        value=recv_load, attr=payload, ctx=ast.Load()
                    )
                    if hop_path in exclude_paths_set:
                        # Excluded place: plain three-address leg, no choke.
                        value = attr_load
                    else:
                        value = ast.Call(
                            func=_create_runtime_attribute(
                                "pyir_read",
                                lineno=lineno,
                                col_offset=col_offset,
                            ),
                            args=[ast.Constant(value=hop_path), attr_load],
                            keywords=[
                                ast.keyword(
                                    arg="attach_ref",
                                    value=ast.Constant(value=False),
                                ),
                                ast.keyword(
                                    arg="owner",
                                    value=ast.Name(id=recv, ctx=ast.Load()),
                                ),
                                ast.keyword(
                                    arg="slot_name",
                                    value=ast.Constant(value=payload),
                                ),
                            ],
                        )
                else:
                    key_node = self._target_as_load(payload)
                    if choked and hop_path not in exclude_paths_set:
                        value = ast.Call(
                            func=_create_runtime_attribute(
                                "_pyir_post_subscript_read",
                                lineno=lineno,
                                col_offset=col_offset,
                            ),
                            args=[
                                ast.Constant(value=hop_path),
                                recv_load,
                                key_node,
                            ],
                            keywords=[],
                        )
                    else:
                        value = ast.Subscript(
                            value=recv_load, slice=key_node, ctx=ast.Load()
                        )
                read_stmt = ast.Assign(
                    targets=[ast.Name(id=local_var, ctx=ast.Store())],
                    value=value,
                )
                stmts.append(
                    ast.copy_location(ast.fix_missing_locations(read_stmt), node)
                )
                hop_temps[hop_path] = local_var
                recv, cur_path = local_var, hop_path
            for nid in node_ids:
                deep_replacements[nid] = recv

        # Replace self.X / non-self Attribute references with their
        # local vars, then bare Name references with their local vars.
        # Deferred regions (lambda bodies / genexp lazy parts) keep their
        # original reads so the capture stays late-bound (Python semantics).
        deferred = _deferred_execution_node_ids(node)
        replaced = self._replace_attr_with_local(
            node, replacements, deferred, deep_replacements
        )
        if name_replacements:
            replaced = self._replace_name_with_local(
                replaced, name_replacements, deferred
            )
        # A hoisted call base moved out of the statement before replacement
        # ran; its argument reads route through the same temps (node ids are
        # preserved by the move, so id-keyed replacement still applies).
        for hoist_stmt in call_hoist_stmts:
            self._replace_attr_with_local(
                hoist_stmt, replacements, deferred, deep_replacements
            )
            if name_replacements:
                self._replace_name_with_local(hoist_stmt, name_replacements, deferred)
        assert isinstance(replaced, ast.stmt)
        stmts.append(replaced)
        return stmts

    def _replace_name_with_local(
        self,
        node: ast.AST,
        replacements: dict[str, str],
        deferred: set[int] | None = None,
    ) -> ast.AST:
        """Replace bare ``Name(ctx=Load)`` references in *node* with
        ``Name(local_var, ctx=Load)``. Used by D1 Name-Load
        instrumentation.

        Does NOT descend into ``ast.Attribute``'s ``.value`` slot --
        ``obj.X`` writes/reads on ``obj`` are already handled by the
        attribute-read pass. Does NOT replace Store-context Names.
        Nodes in *deferred* (lambda bodies / genexp lazy parts) are left
        untouched so their evaluation stays late-bound.
        """
        if not replacements:
            return node
        deferred_ids = deferred or set()

        class NameReplacer(ast.NodeTransformer):
            def visit_Name(self, child: ast.Name) -> ast.AST:
                if isinstance(child.ctx, ast.Load) and id(child) not in deferred_ids:
                    new_id = replacements.get(child.id)
                    if new_id is not None:
                        return ast.copy_location(
                            ast.Name(id=new_id, ctx=ast.Load()), child
                        )
                return child

            def visit_Attribute(self, child: ast.Attribute) -> ast.AST:
                # Avoid rewriting `obj.X`'s base `obj` when an attribute
                # rewrite is the right place to handle it; the attr-read
                # pass already substituted the whole Attribute when
                # applicable.
                return child

        return NameReplacer().visit(node)

    def _replace_attr_with_local(
        self,
        node: ast.AST,
        replacements: dict[tuple[str, str], str],
        deferred: set[int] | None = None,
        deep_replacements: dict[int, str] | None = None,
    ) -> ast.AST:
        """Replace ``self.X`` attribute reads in *node* with local variable
        names from *replacements*.

        *replacements* maps ``(base_name, attr_name)`` → ``local_var_name``.
        Only replaces ``ast.Attribute(ctx=Load)`` with matching base Name.
        *deep_replacements* maps the ``id()`` of a collected deep-path
        Attribute node → local var (deep bases are expressions, not names).
        Nodes in *deferred* (lambda bodies / genexp lazy parts) are left
        untouched so their evaluation stays late-bound.
        """
        deep_ids = deep_replacements or {}
        if not replacements and not deep_ids:
            return node
        deferred_ids = deferred or set()

        class AttrReplacer(ast.NodeTransformer):
            def visit_Attribute(self, child: ast.Attribute) -> ast.AST:
                if id(child) in deep_ids and id(child) not in deferred_ids:
                    return ast.copy_location(
                        ast.Name(id=deep_ids[id(child)], ctx=ast.Load()), child
                    )
                self.generic_visit(child)
                if (
                    isinstance(child.ctx, ast.Load)
                    and isinstance(child.value, ast.Name)
                    and id(child) not in deferred_ids
                ):
                    key = (child.value.id, child.attr)
                    local_var = replacements.get(key)
                    if local_var is not None:
                        return ast.copy_location(
                            ast.Name(id=local_var, ctx=ast.Load()), child
                        )
                return child

        return AttrReplacer().visit(node)

    def _insert_pyir_assign(
        self, node: ast.Assign, targets: list[ast.expr]
    ) -> ast.stmt | list[ast.stmt]:
        """Insert pyir_read + pyir_assign around a reassignment.

        Only called for targets already in scope (checked by visit_Assign).

        Transforms:  target = expr
        To:          target = pyir_read(name, target)  # load from ref
                     _old = target                      # capture old
                     target = expr                      # original
                     target = pyir_assign(name, _old, target, file, line)

        For attribute targets in callee mode, the instrumentation is
        wrapped in ``if hasattr(obj, attr)`` so that first definitions
        (e.g. ``self._idx = idx`` in ``__init__``) are skipped safely.
        """
        stmts: list[ast.stmt] = []

        # A chained assignment (``a = b = expr``) evaluates its RHS ONCE; hoist
        # it to a shared temp so each target assigns from the temp exactly once.
        chain_name: "str | None" = None
        if len(node.targets) > 1 and len(targets) > 1:
            chain_name = f"_pyir_chain_{self.session_data.counter}"
            self.session_data.counter += 1
            rhs_hoist = ast.Assign(
                targets=[ast.Name(id=chain_name, ctx=ast.Store())],
                value=node.value,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(rhs_hoist), node))

        node_reinserted = False

        def _orig_stmt_for(tgt: ast.expr) -> ast.stmt:
            """The 'original assignment' statement for *tgt*: the whole node
            in the single-eval case, else ``tgt = <shared temp>``.

            The returned statements take the tree position *node* vacates,
            so the first single-eval insertion reuses *node* itself; only a
            second insertion (the hasattr guard and first-def fallback
            branches of an Attribute target) copies, keeping every tree
            position a distinct node."""
            nonlocal node_reinserted
            if chain_name is None:
                if node_reinserted:
                    return _deepcopy_ast_root(node)
                node_reinserted = True
                return node
            single = ast.Assign(
                targets=[_deepcopy_ast_root(tgt)],
                value=ast.Name(id=chain_name, ctx=ast.Load()),
            )
            return ast.copy_location(ast.fix_missing_locations(single), node)

        iter_targets = list(node.targets) if chain_name is not None else targets
        for target in iter_targets:
            if chain_name is not None and not any(t is target for t in targets):
                # Uninstrumented sibling of a chained assign (e.g. a first-def):
                # assign it from the shared temp exactly once.
                stmts.append(_orig_stmt_for(target))
                continue
            path_str = self._target_to_path_str(target)
            lineno = node.lineno

            slot_kwargs = self._slot_kwargs_for(target)
            # An Attribute target routes both instrumentation calls through
            # the attr-assign wrappers, which return ``_PYIR_SKIP`` when the
            # owner keeps handle-shaped state behind a custom ``__setattr__``
            # (a downstream-DSL struct field reads back as its scalar-slot
            # pointer handle -- writing that handle back through the real
            # ``__setattr__`` raises).  The generated shape mirrors the
            # subscript pre-hook protocol: capture into a temp, store only
            # when the temp is not ``_PYIR_SKIP``.  Every other target keeps
            # the plain single-statement shape.
            is_attr_target = isinstance(target, ast.Attribute)

            def _skip_guarded_store(tmp_name: str) -> ast.stmt:
                """``if <tmp> is not _PYIR_SKIP: target = <tmp>``."""
                return ast.If(
                    test=ast.Compare(
                        left=ast.Name(id=tmp_name, ctx=ast.Load()),
                        ops=[ast.IsNot()],
                        comparators=[
                            _create_runtime_attribute(
                                "_PYIR_SKIP",
                                lineno=lineno,
                                col_offset=node.col_offset,
                            )
                        ],
                    ),
                    body=[
                        ast.Assign(
                            targets=[_deepcopy_ast_root(target)],
                            value=ast.Name(id=tmp_name, ctx=ast.Load()),
                        )
                    ],
                    orelse=[],
                )

            # target = pyir_read("target", target, owner=..., slot_name=...)
            # For dict-style subscripts (d['key']), use d.get('key') to
            # avoid KeyError on first-time key insertion.
            target_load_for_read = self._subscript_safe_read(target)
            pyir_read_call = ast.Call(
                func=_create_runtime_attribute(
                    "_pyir_pre_attr_assign" if is_attr_target else "pyir_read",
                    lineno=lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    ast.Constant(value=path_str),
                    target_load_for_read,
                ],
                keywords=[_deepcopy_ast_root(kw) for kw in slot_kwargs],
            )
            if is_attr_target:
                read_tmp_name = f"_pyir_read_{self.session_data.counter}"
                self.session_data.counter += 1
                read_stmts: list[ast.stmt] = [
                    ast.Assign(
                        targets=[ast.Name(id=read_tmp_name, ctx=ast.Store())],
                        value=pyir_read_call,
                    ),
                    _skip_guarded_store(read_tmp_name),
                ]
            else:
                read_stmts = [
                    ast.Assign(
                        targets=[_deepcopy_ast_root(target)],
                        value=pyir_read_call,
                    )
                ]

            # _old = target
            old_name = f"_pyir_old_{self.session_data.counter}"
            self.session_data.counter += 1
            target_load = self._target_as_load(target)
            capture_old = ast.Assign(
                targets=[ast.Name(id=old_name, ctx=ast.Store())],
                value=target_load,
            )

            # target = pyir_assign(path, _old, target, __file__, lineno,
            #                      owner=..., slot_name=...)
            target_load2 = self._target_as_load(target)
            pyir_call = ast.Call(
                func=_create_runtime_attribute(
                    "_pyir_post_attr_assign" if is_attr_target else "pyir_assign",
                    lineno=lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    ast.Constant(value=path_str),
                    ast.Name(id=old_name, ctx=ast.Load()),
                    target_load2,
                    ast.Constant(value=self.session_data.file_name),
                    ast.Constant(value=lineno),
                ],
                keywords=[_deepcopy_ast_root(kw) for kw in slot_kwargs],
            )
            if is_attr_target:
                assign_tmp_name = f"_pyir_assign_{self.session_data.counter}"
                self.session_data.counter += 1
                reassign_stmts: list[ast.stmt] = [
                    ast.Assign(
                        targets=[ast.Name(id=assign_tmp_name, ctx=ast.Store())],
                        value=pyir_call,
                    ),
                    _skip_guarded_store(assign_tmp_name),
                ]
            else:
                reassign_stmts = [
                    ast.Assign(
                        targets=[_deepcopy_ast_root(target)],
                        value=pyir_call,
                    )
                ]

            # Attribute targets might be first definitions (e.g.
            # self._idx = idx in __init__).  Guard with hasattr so
            # the pyir_read of the old value doesn't crash when the
            # attribute doesn't exist yet.  Applies in both callee
            # rewrite AND top-level jit paths.
            if isinstance(target, ast.Attribute):
                # Guard the pre-read on hasattr(obj, attr); obj may itself be a
                # nested load (self.inner.newattr), so load the value chain.
                hasattr_test = ast.Call(
                    func=ast.Name(id="hasattr", ctx=ast.Load()),
                    args=[
                        self._target_as_load(target.value),
                        ast.Constant(value=target.attr),
                    ],
                    keywords=[],
                )
                # Tracer-internal storage probe, not a user reflection read:
                # keep it bare through the call-boundary pass.
                hasattr_test._pyir_synth = True  # type: ignore[attr-defined]
                guarded_body: list[ast.stmt] = [
                    *(
                        ast.copy_location(ast.fix_missing_locations(s), node)
                        for s in read_stmts
                    ),
                    ast.copy_location(ast.fix_missing_locations(capture_old), node),
                    _orig_stmt_for(target),
                    *(
                        ast.copy_location(ast.fix_missing_locations(s), node)
                        for s in reassign_stmts
                    ),
                ]
                # First-def branch: the plain assignment plus a trace-only note
                # recording the binding-position fact (read-before-set).
                note_call = ast.Expr(
                    value=ast.Call(
                        func=_create_runtime_attribute(
                            "pyir_note_attr_first_def",
                            lineno=lineno,
                            col_offset=node.col_offset,
                        ),
                        args=[
                            ast.Constant(value=path_str),
                            self._target_as_load(target.value),
                            ast.Constant(value=target.attr),
                            self._target_as_load(target),
                        ],
                        keywords=[],
                    )
                )
                fallback_body: list[ast.stmt] = [
                    _orig_stmt_for(target),
                    ast.copy_location(ast.fix_missing_locations(note_call), node),
                ]
                if_guard: ast.stmt = ast.If(
                    test=hasattr_test,
                    body=guarded_body,
                    orelse=fallback_body,
                )
                # A property target dispatches its SETTER through the call
                # boundary (class code, no ast.Call): the native store pattern
                # would re-invoke the setter per bracketing statement and
                # promote a placeless (computed) leg.  The branch fact is
                # value-free, so the RHS keeps its native evaluation position
                # (after the pre-store refresh) in whichever branch runs.  A
                # multi-target assign without a chain temp re-executes the
                # whole node, so it keeps the storage-only shape.
                if chain_name is not None or len(node.targets) == 1:
                    is_prop_test = ast.Call(
                        func=_create_runtime_attribute(
                            "_pyir_is_property_store",
                            lineno=lineno,
                            col_offset=node.col_offset,
                        ),
                        args=[
                            self._target_as_load(target.value),
                            ast.Constant(value=target.attr),
                        ],
                        keywords=[],
                    )
                    is_prop_test._pyir_synth = True  # type: ignore[attr-defined]
                    prop_store = ast.Expr(
                        value=ast.Call(
                            func=_create_runtime_attribute(
                                "_pyir_property_store",
                                lineno=lineno,
                                col_offset=node.col_offset,
                            ),
                            args=[
                                self._target_as_load(target.value),
                                ast.Constant(value=target.attr),
                                (
                                    ast.Name(id=chain_name, ctx=ast.Load())
                                    if chain_name is not None
                                    else _deepcopy_ast_root(node.value)
                                ),
                            ],
                            keywords=[],
                        )
                    )
                    if_guard = ast.If(
                        test=is_prop_test,
                        body=[
                            ast.copy_location(
                                ast.fix_missing_locations(prop_store), node
                            )
                        ],
                        orelse=[if_guard],
                    )
                stmts.append(
                    ast.copy_location(ast.fix_missing_locations(if_guard), node)
                )
            else:
                # A statically in-scope Name can be UNBOUND at run time (prior
                # ``del`` / failed bind): seed ``_pyir_old = None`` on unbound read.
                set_old_none = ast.Assign(
                    targets=[ast.Name(id=old_name, ctx=ast.Store())],
                    value=ast.Constant(value=None),
                )
                guarded_read = ast.Try(
                    body=[
                        *(
                            ast.copy_location(ast.fix_missing_locations(s), node)
                            for s in read_stmts
                        ),
                        ast.copy_location(ast.fix_missing_locations(capture_old), node),
                    ],
                    handlers=[
                        ast.ExceptHandler(
                            type=ast.Tuple(
                                elts=[
                                    ast.Name(id="NameError", ctx=ast.Load()),
                                    ast.Name(id="UnboundLocalError", ctx=ast.Load()),
                                ],
                                ctx=ast.Load(),
                            ),
                            name=None,
                            body=[
                                ast.copy_location(
                                    ast.fix_missing_locations(set_old_none), node
                                )
                            ],
                        )
                    ],
                    orelse=[],
                    finalbody=[],
                )
                stmts.append(
                    ast.copy_location(ast.fix_missing_locations(guarded_read), node)
                )
                stmts.append(_orig_stmt_for(target))  # original assignment
                stmts.extend(
                    ast.copy_location(ast.fix_missing_locations(s), node)
                    for s in reassign_stmts
                )

        if len(stmts) == 0:
            return node
        return stmts

    # ``ast.AugAssign`` operator -> the in-place routing key consumed by
    # ``_pyir_inplace_binop`` (total over Python's binary operators).
    _AUGASSIGN_OP_KEYS: "dict[type, str]" = {
        ast.Add: "add",
        ast.Sub: "sub",
        ast.Mult: "mul",
        ast.MatMult: "matmul",
        ast.Div: "truediv",
        ast.FloorDiv: "floordiv",
        ast.Mod: "mod",
        ast.Pow: "pow",
        ast.LShift: "lshift",
        ast.RShift: "rshift",
        ast.BitOr: "or",
        ast.BitXor: "xor",
        ast.BitAnd: "and",
    }

    def _inplace_binop_stmt(
        self, node: ast.AugAssign, base_name: "str | None" = None
    ) -> ast.stmt:
        """``target op= value`` -> ``target = _pyir_inplace_binop("op", target,
        value)``: value-identical (CPython's in-place protocol), with the dunder
        routed through the call boundary (operator dispatch has no ast.Call).
        *base_name* substitutes a pre-walrus anchor temp for the target load
        (Python loads the base before a same-statement walrus store)."""
        base_load: ast.expr = (
            ast.Name(id=base_name, ctx=ast.Load())
            if base_name is not None
            else self._target_as_load(node.target)
        )
        call = ast.Call(
            func=_create_runtime_attribute(
                "_pyir_inplace_binop",
                lineno=node.lineno,
                col_offset=node.col_offset,
            ),
            args=[
                ast.Constant(value=self._AUGASSIGN_OP_KEYS[type(node.op)]),
                base_load,
                _deepcopy_ast_root(node.value),
            ],
            keywords=[],
        )
        stmt = ast.Assign(targets=[_deepcopy_ast_root(node.target)], value=call)
        return ast.copy_location(ast.fix_missing_locations(stmt), node)

    def _insert_pyir_augassign(
        self, node: ast.AugAssign, base_anchor: "str | None" = None
    ) -> list[ast.stmt]:
        """Insert pyir_read + pyir_assign around an augmented assignment.

        Transforms:  target += expr
        To:          target = pyir_read(name, target)    # load from ref
                     _old = target
                     target = _pyir_inplace_binop(op, target, expr)
                     target = pyir_assign(name, _old, target, file, line)

        *base_anchor* (a Name target walrus-rebound in its own RHS) replaces
        the in-place op's target load with the statement-top anchor temp; the
        pyir_read refresh and old-capture keep the post-walrus slot state for
        the store.

        A property target instead branch-selects on the same value-free
        target fact as plain assigns: one getter read feeds the in-place
        op and the bound setter runs once at the call boundary (the
        storage pattern would re-invoke the accessors per bracketing
        statement and promote a placeless leg).
        """
        target = node.target
        path_str = self._target_to_path_str(target)
        lineno = node.lineno
        slot_kwargs = self._slot_kwargs_for(target)
        # Attribute targets route through the attr-assign wrappers and the
        # ``_PYIR_SKIP``-guarded store, exactly like ``_insert_pyir_assign``
        # (see the comment there): a handle-shaped owner (a downstream-DSL
        # struct whose fields read back as pointer handles) must not receive
        # its own read-back through the real __setattr__.
        is_attr_target = isinstance(target, ast.Attribute)

        def _skip_guarded_store(tmp_name: str) -> ast.stmt:
            """``if <tmp> is not _PYIR_SKIP: target = <tmp>``."""
            return ast.If(
                test=ast.Compare(
                    left=ast.Name(id=tmp_name, ctx=ast.Load()),
                    ops=[ast.IsNot()],
                    comparators=[
                        _create_runtime_attribute(
                            "_PYIR_SKIP",
                            lineno=lineno,
                            col_offset=node.col_offset,
                        )
                    ],
                ),
                body=[
                    ast.Assign(
                        targets=[_deepcopy_ast_root(target)],
                        value=ast.Name(id=tmp_name, ctx=ast.Load()),
                    )
                ],
                orelse=[],
            )

        # target = pyir_read("target", target, owner=..., slot_name=...)
        # (load before the += computation)
        target_load_for_read = self._target_as_load(target)
        pyir_read_call = ast.Call(
            func=_create_runtime_attribute(
                "_pyir_pre_attr_assign" if is_attr_target else "pyir_read",
                lineno=lineno,
                col_offset=node.col_offset,
            ),
            args=[
                ast.Constant(value=path_str),
                target_load_for_read,
            ],
            keywords=[_deepcopy_ast_root(kw) for kw in slot_kwargs],
        )
        if is_attr_target:
            read_tmp_name = f"_pyir_read_{self.session_data.counter}"
            self.session_data.counter += 1
            read_stmts: list[ast.stmt] = [
                ast.Assign(
                    targets=[ast.Name(id=read_tmp_name, ctx=ast.Store())],
                    value=pyir_read_call,
                ),
                _skip_guarded_store(read_tmp_name),
            ]
        else:
            read_stmts = [
                ast.Assign(
                    targets=[_deepcopy_ast_root(target)],
                    value=pyir_read_call,
                )
            ]

        old_name = f"_pyir_old_{self.session_data.counter}"
        self.session_data.counter += 1

        # _old = target (always exists for +=)
        target_load = self._target_as_load(target)
        capture_old = ast.Assign(
            targets=[ast.Name(id=old_name, ctx=ast.Store())],
            value=target_load,
        )

        # target = pyir_assign(path, _old, target, __file__, lineno,
        #                      owner=..., slot_name=...)
        target_load2 = self._target_as_load(target)
        pyir_call = ast.Call(
            func=_create_runtime_attribute(
                "_pyir_post_attr_assign" if is_attr_target else "pyir_assign",
                lineno=lineno,
                col_offset=node.col_offset,
            ),
            args=[
                ast.Constant(value=path_str),
                ast.Name(id=old_name, ctx=ast.Load()),
                target_load2,
                ast.Constant(value=self.session_data.file_name),
                ast.Constant(value=lineno),
            ],
            keywords=[_deepcopy_ast_root(kw) for kw in slot_kwargs],
        )
        if is_attr_target:
            assign_tmp_name = f"_pyir_assign_{self.session_data.counter}"
            self.session_data.counter += 1
            reassign_stmts: list[ast.stmt] = [
                ast.Assign(
                    targets=[ast.Name(id=assign_tmp_name, ctx=ast.Store())],
                    value=pyir_call,
                ),
                _skip_guarded_store(assign_tmp_name),
            ]
        else:
            reassign_stmts = [
                ast.Assign(
                    targets=[_deepcopy_ast_root(target)],
                    value=pyir_call,
                )
            ]

        native_stmts: list[ast.stmt] = [
            *(
                ast.copy_location(ast.fix_missing_locations(s), node)
                for s in read_stmts
            ),  # load from ref
            ast.copy_location(
                ast.fix_missing_locations(capture_old), node
            ),  # capture old
            self._inplace_binop_stmt(node, base_anchor),  # boundary-routed in-place op
            *(
                ast.copy_location(ast.fix_missing_locations(s), node)
                for s in reassign_stmts
            ),  # store + reload
        ]
        if not isinstance(target, ast.Attribute):
            return native_stmts

        # A property target dispatches through the boundary store (native
        # accessor counts: getter once into the in-place op, setter once);
        # ordinary attributes keep the storage pattern.
        is_prop_test = ast.Call(
            func=_create_runtime_attribute(
                "_pyir_is_property_store",
                lineno=lineno,
                col_offset=node.col_offset,
            ),
            args=[
                self._target_as_load(target.value),
                ast.Constant(value=target.attr),
            ],
            keywords=[],
        )
        is_prop_test._pyir_synth = True  # type: ignore[attr-defined]
        inplace_call = ast.Call(
            func=_create_runtime_attribute(
                "_pyir_inplace_binop",
                lineno=lineno,
                col_offset=node.col_offset,
            ),
            args=[
                ast.Constant(value=self._AUGASSIGN_OP_KEYS[type(node.op)]),
                self._target_as_load(target),
                _deepcopy_ast_root(node.value),
            ],
            keywords=[],
        )
        prop_store = ast.Expr(
            value=ast.Call(
                func=_create_runtime_attribute(
                    "_pyir_property_store",
                    lineno=lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    self._target_as_load(target.value),
                    ast.Constant(value=target.attr),
                    inplace_call,
                ],
                keywords=[],
            )
        )
        if_guard = ast.If(
            test=is_prop_test,
            body=[ast.copy_location(ast.fix_missing_locations(prop_store), node)],
            orelse=native_stmts,
        )
        return [ast.copy_location(ast.fix_missing_locations(if_guard), node)]

    def _hoist_subscript_parts(
        self, node: ast.stmt, target: ast.Subscript
    ) -> list[ast.stmt]:
        """Bind an effectful container/key expression of a subscript target
        to a temp once and rewrite *target* in place, so the pre-hook, the
        guarded writeback, the original statement, and the post-assign all
        share the one evaluation (native counts -- a property-backed
        container or a call-bearing key otherwise fires per site).
        Name/Constant parts stay put: re-reading them is effect-free."""
        hoists: list[ast.stmt] = []
        if not isinstance(target.value, (ast.Name, ast.Constant)):
            cont_name = f"_pyir_cont_{self.session_data.counter}"
            self.session_data.counter += 1
            cont_hoist = ast.Assign(
                targets=[ast.Name(id=cont_name, ctx=ast.Store())],
                value=self._target_as_load(target.value),
            )
            hoists.append(
                ast.copy_location(ast.fix_missing_locations(cont_hoist), node)
            )
            target.value = ast.Name(id=cont_name, ctx=ast.Load())
        key = target.slice
        if not isinstance(key, (ast.Name, ast.Constant, ast.Slice, ast.Tuple)):
            key_name = f"_pyir_key_{self.session_data.counter}"
            self.session_data.counter += 1
            key_load = _deepcopy_ast_root(key)
            for child in ast.walk(key_load):
                if isinstance(child, (ast.Name, ast.Attribute, ast.Subscript)):
                    child.ctx = ast.Load()
            key_hoist = ast.Assign(
                targets=[ast.Name(id=key_name, ctx=ast.Store())],
                value=key_load,
            )
            hoists.append(ast.copy_location(ast.fix_missing_locations(key_hoist), node))
            target.slice = ast.Name(id=key_name, ctx=ast.Load())
        return hoists

    @staticmethod
    def _part_hoists_can_effect(hoists: list[ast.stmt]) -> bool:
        """True when a hoisted container/key temp's expression can fire an
        effect (a call or a walrus binding) if evaluated early."""
        return any(
            isinstance(sub, (ast.Call, ast.NamedExpr))
            for h in hoists
            for sub in ast.walk(h.value)  # type: ignore[attr-defined]
        )

    def _insert_pyir_subscript_assign(
        self, node: ast.stmt, target: ast.Subscript
    ) -> list[ast.stmt]:
        """Generate conditional pyir instrumentation for a subscript assignment."""
        lineno = node.lineno
        col_offset = node.col_offset
        path_str = self._target_to_path_str(target)

        old_name = f"_pyir_sub_old_{self.session_data.counter}"
        self.session_data.counter += 1

        # One shared evaluation of effectful container/key parts (rewrites
        # *target*, and with it the original statement, in place).
        part_hoists = self._hoist_subscript_parts(node, target)
        # Native assign order is RHS -> container -> key; a part hoist that
        # can CALL front-loads its effect ahead of the RHS, so the RHS must
        # pin ahead of it.  Effect-free hoists keep the plain layout: the
        # pre-hook writeback must precede the RHS, whose read of the
        # target's own path is un-instrumented (excluded in visit_Assign)
        # and reads the container directly.
        if self._part_hoists_can_effect(part_hoists) and isinstance(node, ast.Assign):
            rhs_name = f"_pyir_rhs_{self.session_data.counter}"
            self.session_data.counter += 1
            rhs_hoist = ast.Assign(
                targets=[ast.Name(id=rhs_name, ctx=ast.Store())],
                value=node.value,
            )
            part_hoists.insert(
                0, ast.copy_location(ast.fix_missing_locations(rhs_hoist), node)
            )
            node.value = ast.Name(id=rhs_name, ctx=ast.Load())

        container_node = self._target_as_load(target.value)
        key_node = _deepcopy_ast_root(target.slice)

        pre_call = ast.Call(
            func=_create_runtime_attribute(
                "_pyir_pre_subscript_assign",
                lineno=lineno,
                col_offset=col_offset,
            ),
            args=[
                ast.Constant(value=path_str),
                container_node,
                key_node,
            ],
            keywords=[],
        )
        pre_assign = ast.Assign(
            targets=[ast.Name(id=old_name, ctx=ast.Store())],
            value=pre_call,
        )

        target_load = self._target_as_load(target)
        slot_kwargs = self._slot_kwargs_for(target)
        pyir_call = ast.Call(
            func=_create_runtime_attribute(
                "pyir_assign",
                lineno=lineno,
                col_offset=col_offset,
            ),
            args=[
                ast.Constant(value=path_str),
                ast.Name(id=old_name, ctx=ast.Load()),
                target_load,
                ast.Constant(value=self.session_data.file_name),
                ast.Constant(value=lineno),
            ],
            keywords=[_deepcopy_ast_root(kw) for kw in slot_kwargs],
        )
        reassign = ast.Assign(
            targets=[_deepcopy_ast_root(target)],
            value=pyir_call,
        )

        skip_sentinel = _create_runtime_attribute(
            "_PYIR_SKIP",
            lineno=lineno,
            col_offset=col_offset,
        )
        guard = ast.Compare(
            left=ast.Name(id=old_name, ctx=ast.Load()),
            ops=[ast.IsNot()],
            comparators=[skip_sentinel],
        )
        if_stmt = ast.If(
            test=guard,
            body=[reassign],
            orelse=[],
        )

        # Writeback: write loaded value back into the dict so the RHS of
        # the original assignment reads the fresh (ref-loaded) value.
        # Without this, `d[key] = d[key] + Int32(1)` reads stale d[key].
        skip_sentinel_wb = _create_runtime_attribute(
            "_PYIR_SKIP",
            lineno=lineno,
            col_offset=col_offset,
        )
        writeback = ast.Assign(
            targets=[_deepcopy_ast_root(target)],
            value=ast.Name(id=old_name, ctx=ast.Load()),
        )
        guard_wb = ast.Compare(
            left=ast.Name(id=old_name, ctx=ast.Load()),
            ops=[ast.IsNot()],
            comparators=[skip_sentinel_wb],
        )
        if_writeback = ast.If(
            test=guard_wb,
            body=[writeback],
            orelse=[],
        )

        return [
            *part_hoists,
            ast.copy_location(ast.fix_missing_locations(pre_assign), node),
            ast.copy_location(ast.fix_missing_locations(if_writeback), node),
            node,
            ast.copy_location(ast.fix_missing_locations(if_stmt), node),
        ]

    def _insert_pyir_subscript_augassign(
        self, node: ast.AugAssign, target: ast.Subscript
    ) -> list[ast.stmt]:
        """Generate conditional pyir instrumentation for a subscript augmented assignment."""
        lineno = node.lineno
        col_offset = node.col_offset
        path_str = self._target_to_path_str(target)

        old_name = f"_pyir_sub_old_{self.session_data.counter}"
        self.session_data.counter += 1

        # One shared evaluation of effectful container/key parts (rewrites
        # *target*, and with it the boundary-routed in-place op, in place).
        part_hoists = self._hoist_subscript_parts(node, target)

        container_node = self._target_as_load(target.value)
        key_node = _deepcopy_ast_root(target.slice)

        pre_call = ast.Call(
            func=_create_runtime_attribute(
                "_pyir_pre_subscript_assign",
                lineno=lineno,
                col_offset=col_offset,
            ),
            args=[
                ast.Constant(value=path_str),
                container_node,
                key_node,
            ],
            keywords=[],
        )
        pre_assign = ast.Assign(
            targets=[ast.Name(id=old_name, ctx=ast.Store())],
            value=pre_call,
        )

        skip_sentinel_1 = _create_runtime_attribute(
            "_PYIR_SKIP",
            lineno=lineno,
            col_offset=col_offset,
        )
        writeback = ast.Assign(
            targets=[_deepcopy_ast_root(target)],
            value=ast.Name(id=old_name, ctx=ast.Load()),
        )
        guard_1 = ast.Compare(
            left=ast.Name(id=old_name, ctx=ast.Load()),
            ops=[ast.IsNot()],
            comparators=[skip_sentinel_1],
        )
        if_writeback = ast.If(
            test=guard_1,
            body=[writeback],
            orelse=[],
        )

        target_load = self._target_as_load(target)
        slot_kwargs = self._slot_kwargs_for(target)
        pyir_call = ast.Call(
            func=_create_runtime_attribute(
                "pyir_assign",
                lineno=lineno,
                col_offset=col_offset,
            ),
            args=[
                ast.Constant(value=path_str),
                ast.Name(id=old_name, ctx=ast.Load()),
                target_load,
                ast.Constant(value=self.session_data.file_name),
                ast.Constant(value=lineno),
            ],
            keywords=[_deepcopy_ast_root(kw) for kw in slot_kwargs],
        )
        reassign = ast.Assign(
            targets=[_deepcopy_ast_root(target)],
            value=pyir_call,
        )
        skip_sentinel_2 = _create_runtime_attribute(
            "_PYIR_SKIP",
            lineno=lineno,
            col_offset=col_offset,
        )
        guard_2 = ast.Compare(
            left=ast.Name(id=old_name, ctx=ast.Load()),
            ops=[ast.IsNot()],
            comparators=[skip_sentinel_2],
        )
        if_post = ast.If(
            test=guard_2,
            body=[reassign],
            orelse=[],
        )

        return [
            *part_hoists,
            ast.copy_location(ast.fix_missing_locations(pre_assign), node),
            ast.copy_location(ast.fix_missing_locations(if_writeback), node),
            self._inplace_binop_stmt(node),  # boundary-routed in-place op
            ast.copy_location(ast.fix_missing_locations(if_post), node),
        ]

    def _make_rhs_pin(self, node: ast.Assign) -> "tuple[str, ast.stmt]":
        """Build ``_pyir_tmp_N = _pyir_pin_tuple_capture(<RHS>)``.

        Evaluates the RHS once, wrapped in the capture pin: Python evaluates
        the WHOLE RHS before any element store, so a swap source pins its read
        here.  Returns the temp name and the statement, so a caller that has to
        place the pin itself (a chained assign whose FIRST target is not a
        sequence) can emit it ahead of every target.
        """
        tmp = f"_pyir_tmp_{self.session_data.counter}"
        self.session_data.counter += 1
        pin = ast.Assign(
            targets=[ast.Name(id=tmp, ctx=ast.Store())],
            value=ast.Call(
                func=_create_runtime_attribute(
                    "_pyir_pin_tuple_capture",
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[node.value],  # the original RHS expression
                keywords=[
                    ast.keyword(arg="unpack_source", value=ast.Constant(value=True))
                ],
            ),
        )
        return tmp, ast.copy_location(ast.fix_missing_locations(pin), node)

    def _decompose_unpack_assign(
        self,
        node: ast.Assign,
        sequence_target: "ast.Tuple | ast.List",
        in_scope_indices: set[int],
        *,
        rhs_temp_name: str | None = None,
    ) -> ast.stmt | list[ast.stmt]:
        """Decompose a sequence-unpacking assignment into individual pyir-instrumented assigns.

        ``sequence_target`` is the ``ast.Tuple`` or ``ast.List`` target of the
        unpack.  Both spellings are accepted because ``[a, b] = rhs`` and
        ``a, b = rhs`` compile to identical bytecode -- only the AST node type
        differs -- so they must be instrumented the same way.

        ``in_scope_indices`` is the set of element indices that were in scope
        BEFORE ``_visit_target`` added first-definitions.  This prevents
        instrumenting first-definition elements that were added to scope after
        the scope check in ``visit_Assign``.

        When ``rhs_temp_name`` is provided the RHS has already been evaluated
        into that temporary by a prior call (multi-target assignment) so step 3
        is skipped.

        Transforms:
            a, b = expr
        Into:
            a = pyir_read("a", a)       # only if a is in scope
            b = pyir_read("b", b)       # only if b is in scope
            _pyir_old_0 = a             # only if a is in scope
            _pyir_old_1 = b             # only if b is in scope
            _pyir_tmp_N = expr          # evaluate RHS once (skipped when rhs_temp_name set)
            a = _pyir_tmp_N[0]          # individual extractions
            b = _pyir_tmp_N[1]
            a = pyir_assign(...)        # only if a is in scope
            b = pyir_assign(...)        # only if b is in scope

        A Subscript element ``c[k]`` instead adopts the single-subscript
        pre-hook protocol: ``_pyir_old_N = _pyir_pre_subscript_assign(...)``
        classifies the container BEFORE any element access, and the
        writeback and ``pyir_assign`` steps are guarded on
        ``_pyir_old_N is not _PYIR_SKIP``.
        """
        stmts: list[ast.stmt] = []
        lineno = node.lineno
        col_offset = node.col_offset
        elts = sequence_target.elts

        # Starred unpacking: the star target binds a fresh LIST (never
        # instrumented here); positional siblings keep star-aware indices.
        star_idx: "int | None" = None
        for _i, _elt in enumerate(elts):
            if isinstance(_elt, ast.Starred):
                if star_idx is not None:
                    return node  # ill-formed (Python allows only one star)
                star_idx = _i

        # Use the pre-computed in-scope indices from visit_Assign.
        instrumented: list[tuple[int, ast.expr]] = [
            (i, elt) for i, elt in enumerate(elts) if i in in_scope_indices
        ]

        # A Name element outside the ACTIVE region scopes is still a first-def
        # of the enclosing FUNCTION's place at the unpack position (region
        # scopes are an AST artifact; Python scoping is function-wide), so it
        # commits through the first-def choke -- the runtime ledger decides
        # first-def vs live-row rebind.
        first_def_elts: list[tuple[int, ast.Name]] = [
            (i, elt)
            for i, elt in enumerate(elts)
            if i not in in_scope_indices
            and isinstance(elt, ast.Name)
            and elt.id != "_"
            and not self.session_data.scope_manager.is_skip_reference_taking(elt.id)
        ]

        # A possibly-first-def attribute element: gate its read/old-capture/post-assign
        # on a ``hasattr`` flag (as scalar assigns do) to avoid ``AttributeError``.
        # A property element instead branch-selects on the same value-free
        # target fact as scalar assigns: the probe and the read/old/post
        # steps would fire the accessors, so the flag stays False and the
        # Step-4 store dispatches the bound setter through the boundary.
        has_flags: dict[int, str] = {}  # index -> _pyir_has_N flag name
        prop_flags: dict[int, str] = {}  # index -> _pyir_isprop_N flag name
        for idx, elt in instrumented:
            if isinstance(elt, ast.Attribute):
                isprop_name = f"_pyir_isprop_{self.session_data.counter}"
                self.session_data.counter += 1
                prop_flags[idx] = isprop_name
                is_prop_test = ast.Call(
                    func=_create_runtime_attribute(
                        "_pyir_is_property_store",
                        lineno=lineno,
                        col_offset=col_offset,
                    ),
                    args=[
                        self._target_as_load(elt.value),
                        ast.Constant(value=elt.attr),
                    ],
                    keywords=[],
                )
                is_prop_test._pyir_synth = True  # type: ignore[attr-defined]
                isprop_assign = ast.Assign(
                    targets=[ast.Name(id=isprop_name, ctx=ast.Store())],
                    value=is_prop_test,
                )
                stmts.append(
                    ast.copy_location(ast.fix_missing_locations(isprop_assign), node)
                )
                flag_name = f"_pyir_has_{self.session_data.counter}"
                self.session_data.counter += 1
                has_flags[idx] = flag_name
                hasattr_call = ast.Call(
                    func=ast.Name(id="hasattr", ctx=ast.Load()),
                    args=[
                        self._target_as_load(elt.value),
                        ast.Constant(value=elt.attr),
                    ],
                    keywords=[],
                )
                # Tracer-internal storage probe, not a user reflection read:
                # keep it bare through the call-boundary pass.
                hasattr_call._pyir_synth = True  # type: ignore[attr-defined]
                flag_assign = ast.Assign(
                    targets=[ast.Name(id=flag_name, ctx=ast.Store())],
                    value=ast.BoolOp(
                        op=ast.And(),
                        values=[
                            ast.UnaryOp(
                                op=ast.Not(),
                                operand=ast.Name(id=isprop_name, ctx=ast.Load()),
                            ),
                            hasattr_call,
                        ],
                    ),
                )
                stmts.append(
                    ast.copy_location(ast.fix_missing_locations(flag_assign), node)
                )

        def _maybe_guard(stmt: ast.stmt, idx: int) -> ast.stmt:
            """Wrap *stmt* in ``if <has-flag>:`` for possible-first-def attrs."""
            flag = has_flags.get(idx)
            if flag is None:
                return stmt
            guard = ast.If(
                test=ast.Name(id=flag, ctx=ast.Load()),
                body=[stmt],
                orelse=[],
            )
            return ast.copy_location(ast.fix_missing_locations(guard), node)

        def _guard_unbound_name(stmt: ast.stmt, on_unbound: list[ast.stmt]) -> ast.stmt:
            """Wrap a bare-name element's old-value read/capture so an unbound name
            degrades to a first-def instead of crashing."""
            tried = ast.Try(
                body=[stmt],
                handlers=[
                    ast.ExceptHandler(
                        type=ast.Tuple(
                            elts=[
                                ast.Name(id="NameError", ctx=ast.Load()),
                                ast.Name(id="UnboundLocalError", ctx=ast.Load()),
                            ],
                            ctx=ast.Load(),
                        ),
                        name=None,
                        body=on_unbound or [ast.Pass()],
                    )
                ],
                orelse=[],
                finalbody=[],
            )
            return ast.copy_location(ast.fix_missing_locations(tried), node)

        def _skip_guarded(stmt: ast.stmt, old_name: str) -> ast.stmt:
            """Wrap *stmt* in ``if <old_name> is not _PYIR_SKIP:`` (the
            single-subscript pre-hook guard shape)."""
            guard = ast.Compare(
                left=ast.Name(id=old_name, ctx=ast.Load()),
                ops=[ast.IsNot()],
                comparators=[
                    _create_runtime_attribute(
                        "_PYIR_SKIP",
                        lineno=lineno,
                        col_offset=col_offset,
                    )
                ],
            )
            guarded = ast.If(test=guard, body=[stmt], orelse=[])
            return ast.copy_location(ast.fix_missing_locations(guarded), node)

        def _pin_rhs() -> str:
            tmp, pin = self._make_rhs_pin(node)
            stmts.append(pin)
            return tmp

        # One shared evaluation of effectful container/key parts per
        # subscript element (rewrites each *elt*, and with it the Step-4
        # extraction and Step-5 post-assign, in place); emitted at the
        # element's Step-1 slot below.  Native unpack evaluates the WHOLE
        # RHS before any target part, so a hoist that can CALL pulls the
        # Step-3 RHS pin ahead of it; effect-free hoists keep the plain
        # layout (their Step-1 writeback must precede the RHS's
        # un-instrumented same-path reads).
        part_hoists_by_idx = {
            idx: self._hoist_subscript_parts(node, elt)
            for idx, elt in instrumented
            if isinstance(elt, ast.Subscript)
        }
        if rhs_temp_name is None and any(
            self._part_hoists_can_effect(h) for h in part_hoists_by_idx.values()
        ):
            rhs_temp_name = _pin_rhs()

        # --- Step 1: pyir_read for each instrumented element ---
        # Subscript elements adopt the single-subscript pre-hook protocol
        # (fusing Step 2): one runtime call classifies the container and
        # captures the old value -- or returns ``_PYIR_SKIP`` BEFORE any
        # element access -- and a guarded writeback re-binds the element so
        # the RHS reads the fresh (ref-loaded) value.
        old_names: dict[int, str] = {}  # index -> old_name
        for idx, elt in instrumented:
            path_str = self._target_to_path_str(elt)
            if isinstance(elt, ast.Subscript):
                old_name = f"_pyir_old_{self.session_data.counter}"
                self.session_data.counter += 1
                old_names[idx] = old_name
                stmts.extend(part_hoists_by_idx[idx])
                pre_call = ast.Call(
                    func=_create_runtime_attribute(
                        "_pyir_pre_subscript_assign",
                        lineno=lineno,
                        col_offset=col_offset,
                    ),
                    args=[
                        ast.Constant(value=path_str),
                        self._target_as_load(elt.value),
                        _deepcopy_ast_root(elt.slice),
                    ],
                    keywords=[],
                )
                pre_assign = ast.Assign(
                    targets=[ast.Name(id=old_name, ctx=ast.Store())],
                    value=pre_call,
                )
                stmts.append(
                    ast.copy_location(ast.fix_missing_locations(pre_assign), node)
                )
                writeback = ast.Assign(
                    targets=[_deepcopy_ast_root(elt)],
                    value=ast.Name(id=old_name, ctx=ast.Load()),
                )
                writeback = ast.copy_location(
                    ast.fix_missing_locations(writeback), node
                )
                stmts.append(_skip_guarded(writeback, old_name))
                continue
            target_load = self._target_as_load(elt)
            slot_kwargs = self._slot_kwargs_for(elt)
            read_call = ast.Call(
                func=_create_runtime_attribute(
                    "pyir_read",
                    lineno=lineno,
                    col_offset=col_offset,
                ),
                args=[ast.Constant(value=path_str), target_load],
                keywords=[_deepcopy_ast_root(kw) for kw in slot_kwargs],
            )
            read_stmt: ast.stmt = ast.Assign(
                targets=[_deepcopy_ast_root(elt)],
                value=read_call,
            )
            read_stmt = ast.copy_location(ast.fix_missing_locations(read_stmt), node)
            if isinstance(elt, ast.Attribute):
                stmts.append(_maybe_guard(read_stmt, idx))
            else:
                # Bare name possibly unbound (const_expr-branch first-def): skip
                # the read if unbound; Step 4 binds it and Step 5 sees old=None.
                stmts.append(_guard_unbound_name(read_stmt, []))

        # Step 2: capture old values. For possible-first-def attrs, capture only inside
        # the ``hasattr`` guard; the ``else`` arm seeds ``_pyir_old`` with ``None``.
        # (Subscript elements were captured by the Step-1 pre-hook.)
        for idx, elt in instrumented:
            if isinstance(elt, ast.Subscript):
                continue
            old_name = f"_pyir_old_{self.session_data.counter}"
            self.session_data.counter += 1
            old_names[idx] = old_name
            target_load = self._target_as_load(elt)
            capture: ast.stmt = ast.Assign(
                targets=[ast.Name(id=old_name, ctx=ast.Store())],
                value=target_load,
            )
            capture = ast.copy_location(ast.fix_missing_locations(capture), node)
            flag = has_flags.get(idx)
            if flag is None:
                # Bare name may be unbound (const_expr-branch first-def); seed
                # _pyir_old = None on an unbound read so Step 5 treats it as a first-def.
                name_else_seed = ast.Assign(
                    targets=[ast.Name(id=old_name, ctx=ast.Store())],
                    value=ast.Constant(value=None),
                )
                stmts.append(
                    _guard_unbound_name(
                        capture,
                        [
                            ast.copy_location(
                                ast.fix_missing_locations(name_else_seed), node
                            )
                        ],
                    )
                )
            else:
                else_seed = ast.Assign(
                    targets=[ast.Name(id=old_name, ctx=ast.Store())],
                    value=ast.Constant(value=None),
                )
                guard = ast.If(
                    test=ast.Name(id=flag, ctx=ast.Load()),
                    body=[capture],
                    orelse=[
                        ast.copy_location(ast.fix_missing_locations(else_seed), node)
                    ],
                )
                stmts.append(ast.copy_location(ast.fix_missing_locations(guard), node))

        # --- Step 3: evaluate RHS into temp ---
        if rhs_temp_name is not None:
            # RHS already evaluated — by a prior tuple target (multi-target
            # assignment) or by the pre-Step-1 pin above.
            tmp_name = rhs_temp_name
        else:
            tmp_name = _pin_rhs()

        # --- Step 3b: this target's own arity, checked against the temp ---
        # Step 4 stores by index, and indexing does not check length: a surplus
        # value is dropped silently and a missing one raises ``IndexError``
        # where Python raises ``ValueError``.  The check restores both.
        #
        # Per TARGET, not per statement: targets of one chained assign can want
        # different lengths (``(p, q) = (c, r, s) = rhs`` -- Python rejects one
        # of them).  ``_split_multiple_targets`` has already turned that into
        # one store statement per target, so each arrives here on its own and
        # validates the shared ``_pyir_rhs_N`` against its own element count.
        arity_check = ast.Expr(
            value=ast.Call(
                func=_create_runtime_attribute(
                    "_pyir_check_unpack_arity",
                    lineno=lineno,
                    col_offset=col_offset,
                ),
                args=[
                    ast.Name(id=tmp_name, ctx=ast.Load()),
                    ast.Constant(value=len(elts) - (1 if star_idx is not None else 0)),
                    ast.Constant(value=star_idx is not None),
                ],
                keywords=[],
            )
        )
        stmts.append(ast.copy_location(ast.fix_missing_locations(arity_check), node))

        # --- Step 4: decompose -- extract each element from temp ---
        n_elts = len(elts)
        for i, elt in enumerate(elts):
            extract_value: ast.expr
            if star_idx is not None and i == star_idx:
                assert isinstance(elt, ast.Starred)
                # rest = list(tmp[star : star - (n-1) or end])
                tail_count = n_elts - 1 - star_idx
                slice_node = ast.Slice(
                    lower=ast.Constant(value=star_idx),
                    upper=ast.Constant(value=-tail_count) if tail_count else None,
                    step=None,
                )
                extract_value = ast.Call(
                    func=ast.Name(id="list", ctx=ast.Load()),
                    args=[
                        ast.Subscript(
                            value=ast.Name(id=tmp_name, ctx=ast.Load()),
                            slice=slice_node,
                            ctx=ast.Load(),
                        )
                    ],
                    keywords=[],
                )
                target_node: ast.expr = _deepcopy_ast_root(elt.value)  # strip the Star
            else:
                # Position from the left before the star, from the RIGHT after.
                idx_val = i if star_idx is None or i < star_idx else i - n_elts
                extract_value = ast.Subscript(
                    value=ast.Name(id=tmp_name, ctx=ast.Load()),
                    slice=ast.Constant(value=idx_val),
                    ctx=ast.Load(),
                )
                target_node = _deepcopy_ast_root(elt)
            prop_flag = prop_flags.get(i)
            if prop_flag is not None and isinstance(elt, ast.Attribute):
                # Extract once, then branch the store: a property target runs
                # its bound setter through the boundary (observed, predicated);
                # an ordinary attribute keeps the native store.
                elt_name = f"_pyir_elt_{self.session_data.counter}"
                self.session_data.counter += 1
                elt_hoist = ast.Assign(
                    targets=[ast.Name(id=elt_name, ctx=ast.Store())],
                    value=extract_value,
                )
                stmts.append(
                    ast.copy_location(ast.fix_missing_locations(elt_hoist), node)
                )
                prop_store = ast.Expr(
                    value=ast.Call(
                        func=_create_runtime_attribute(
                            "_pyir_property_store",
                            lineno=lineno,
                            col_offset=col_offset,
                        ),
                        args=[
                            self._target_as_load(elt.value),
                            ast.Constant(value=elt.attr),
                            ast.Name(id=elt_name, ctx=ast.Load()),
                        ],
                        keywords=[],
                    )
                )
                plain_store = ast.Assign(
                    targets=[target_node],
                    value=ast.Name(id=elt_name, ctx=ast.Load()),
                )
                branch = ast.If(
                    test=ast.Name(id=prop_flag, ctx=ast.Load()),
                    body=[
                        ast.copy_location(ast.fix_missing_locations(prop_store), node)
                    ],
                    orelse=[
                        ast.copy_location(ast.fix_missing_locations(plain_store), node)
                    ],
                )
                stmts.append(ast.copy_location(ast.fix_missing_locations(branch), node))
                continue
            nest_root = elt.value if isinstance(elt, ast.Starred) else elt
            if isinstance(nest_root, ast.Name) and nest_root.id.startswith(
                "_pyir_nest_"
            ):
                # Nested-unpack temp (split in visit_Assign): pin its elements
                # HERE, before this statement's Step-5 stores, so the follow-up
                # unpack consumes capture-time values (swap safety).
                extract_value = ast.Call(
                    func=_create_runtime_attribute(
                        "_pyir_pin_tuple_capture",
                        lineno=lineno,
                        col_offset=col_offset,
                    ),
                    args=[extract_value],
                    keywords=[],
                )
            extract = ast.Assign(
                targets=[target_node],
                value=extract_value,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(extract), node))

        # --- Step 5: pyir_assign for each instrumented element ---
        for idx, elt in instrumented:
            path_str = self._target_to_path_str(elt)
            target_load = self._target_as_load(elt)
            slot_kwargs = self._slot_kwargs_for(elt)
            old_name = old_names[idx]
            pyir_call = ast.Call(
                func=_create_runtime_attribute(
                    "pyir_assign",
                    lineno=lineno,
                    col_offset=col_offset,
                ),
                args=[
                    ast.Constant(value=path_str),
                    ast.Name(id=old_name, ctx=ast.Load()),
                    target_load,
                    ast.Constant(value=self.session_data.file_name),
                    ast.Constant(value=lineno),
                ],
                keywords=[_deepcopy_ast_root(kw) for kw in slot_kwargs],
            )
            reassign: ast.stmt = ast.Assign(
                targets=[_deepcopy_ast_root(elt)],
                value=pyir_call,
            )
            reassign = ast.copy_location(ast.fix_missing_locations(reassign), node)
            if isinstance(elt, ast.Subscript):
                # Pre-hook-skipped elements record no facts and never fire
                # another element access (single-subscript guard shape).
                stmts.append(_skip_guarded(reassign, old_name))
            else:
                stmts.append(_maybe_guard(reassign, idx))

        # --- Step 5b: first-def commit for out-of-scope Name elements ---
        for idx, elt in first_def_elts:
            fd_call = ast.Call(
                func=_create_runtime_attribute(
                    "pyir_assign",
                    lineno=lineno,
                    col_offset=col_offset,
                ),
                args=[
                    ast.Constant(value=elt.id),
                    ast.Constant(value=None),
                    self._target_as_load(elt),
                    ast.Constant(value=self.session_data.file_name),
                    ast.Constant(value=lineno),
                ],
                keywords=[],
            )
            fd_stmt: ast.stmt = ast.Assign(
                targets=[_deepcopy_ast_root(elt)],
                value=fd_call,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(fd_stmt), node))

        if len(stmts) == 0:
            return node
        return stmts
