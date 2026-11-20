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

"""
This module defines the `DSLPreprocessor` class, which acts as a Python preprocessor.
It uses Python's AST and rewrites specific Python statements such as `for` and `if-else`.

The preprocessor operates on the following constructs:
    - `for` loops:
        - Rewrites `for` loops with the `@loop_selector` decorator.
        - Supports `range`, `range_dynamic` for loop iteration.
    - `if-elif-else` statements:
        - Rewrites conditional statements with the `@if_selector` decorator.
        - Supports `dynamic_expr` and `const_expr` in the condition expressions.

Additionally, both `for` loops and `if-else` statements require `yield`
operation generation. The preprocessor handles this by:
    - Using a `ScopeManager` to track symbols across different scopes during AST traversal.
    - Identifying read-only, read-write, and active variables for DSL constructs.
    - Generating `yield` operations for symbols that are classified as read-write or write.

It is designed to be generic and can handle `for` and `if` constructs from other dialects.
In such cases, the user's DSL should implement `@loop_selector` and `@if_selector`
to generate dialect-specific operations for `for` and `if` statements.
"""

import ast
import contextlib
import importlib
import inspect
import os
import sys
import textwrap
import types
from collections.abc import Callable, Generator, Iterable, Iterator
from dataclasses import dataclass, field, fields
from enum import Enum, auto
from typing import Any, TypeVar
from types import ModuleType
from copy import deepcopy
from itertools import chain

from .ast_helpers import register_deferred_for_error

from .common import *
from .diagnostics import DiagId
from .utils.logger import log


_AstNode = TypeVar("_AstNode", bound=ast.AST)


class ControlFlowPolicy(Enum):
    """Select whether control-flow nodes are staged or kept as native Python."""

    TRACE = auto()
    NATIVE = auto()


def _deepcopy_ast_root(node: _AstNode) -> _AstNode:
    """Copy an AST subtree without following an external parent link.

    Some callers annotate nodes with ``_parent`` for diagnostics. A regular
    ``deepcopy`` then walks the entire enclosing function or module when only
    a small expression or target is needed. Preserve parent links within the
    copied subtree, but detach the copied root from its original owner.
    """
    parent = getattr(node, "_parent", None)
    memo = {id(parent): None} if isinstance(parent, ast.AST) else None
    copied = deepcopy(node, memo)
    if hasattr(copied, "_parent"):
        delattr(copied, "_parent")
    return copied


# Loop options transform_for_loop understands; any other range keyword keeps the
# trace-time dispatch (see DSLPreprocessor._literal_for_iter_kind).
_STAGED_RANGE_KEYWORDS = frozenset(
    {"unroll", "unroll_full", "prefetch_stages", "vectorize", "at_least_once"}
)


class OrderedSet:
    """
    A deterministic set implementation for ordered operations.
    """

    def __init__(self, iterable: Iterable[str] | None = None) -> None:
        self._dict: dict[str, None] = dict.fromkeys(iterable or [])

    def add(self, item: str) -> None:
        self._dict[item] = None

    def __iter__(self) -> Iterator[str]:
        return iter(self._dict)

    def __contains__(self, item: object) -> bool:
        return item in self._dict

    def __and__(self, other: "OrderedSet") -> "OrderedSet":
        return OrderedSet(key for key in self._dict if key in other)

    def __or__(self, other: "OrderedSet") -> "OrderedSet":
        new_dict = self._dict.copy()
        new_dict.update(dict.fromkeys(other))
        return OrderedSet(new_dict)

    def __sub__(self, other: "OrderedSet") -> "OrderedSet":
        return OrderedSet(key for key in self._dict if key not in other)

    def __bool__(self) -> bool:
        return bool(self._dict)

    def intersections(self, others: list[set[str]]) -> "OrderedSet":
        """Compute the intersection of this set with multiple other sets.

        :param others: A list of sets to compute intersections with
        :type others: list[set[str]]
        :return: A new ordered set containing elements that appear in this set
            and at least one of the other sets
        """
        result = OrderedSet()
        for key in self._dict:
            for other in reversed(others):
                if key in other:
                    result.add(key)
                    break
        return result


@dataclass
class ScopeManager:
    """
    Manages symbol scopes during AST traversal.
    Manage nested scopes during transformations.
    """

    scopes: list[set[str]]
    callables: list[set[str]]
    skip_reference_taking: set[str]
    local_scope_indices: list[int] = field(default_factory=list, init=False)

    @classmethod
    def create(cls) -> "ScopeManager":
        return cls([], [], set())

    def add_skip_reference_taking(self, name: str) -> None:
        self.skip_reference_taking.add(name)

    def remove_skip_reference_taking(self, name: str) -> None:
        self.skip_reference_taking.discard(name)

    def is_skip_reference_taking(self, name: str) -> bool:
        return name in self.skip_reference_taking

    def restore_from(self, snapshot: "ScopeManager") -> None:
        """Restore a snapshot without replacing this manager object."""
        if type(self) is not type(snapshot):
            raise TypeError("scope manager snapshots must have the same type")
        for state_field in fields(self):
            setattr(self, state_field.name, getattr(snapshot, state_field.name))

    def add_to_scope(self, name: str) -> None:
        if name == "_":
            return
        self.scopes[-1].add(name)

    def add_to_callables(self, name: str) -> None:
        if not self.callables:
            return
        self.callables[-1].add(name)

    def get_active_symbols(self) -> list[set[str]]:
        return self.scopes.copy()

    def get_active_callables(self) -> list[set[str]]:
        return self.callables.copy()

    def current_function_owns(self, name: str) -> bool:
        """Return whether *name* belongs to the innermost function scope."""
        return (
            bool(self.local_scope_indices)
            and name in self.scopes[self.local_scope_indices[-1]]
        )

    def enclosing_function_owns(self, name: str) -> bool:
        """Return whether *name* belongs to an enclosing function scope."""
        return any(
            name in self.scopes[index] for index in self.local_scope_indices[:-1]
        )

    @contextlib.contextmanager
    def enter_local_scope(self) -> Generator[None, None, None]:
        """
        Context manager for entering a new local variable and callable scope.

        This is conceptually Python's local scope, such as within a function or class definition.

        Use this in a ``with`` statement to temporarily push a new, empty set for both variable and callable
        tracking onto the respective ScopeManager stacks. These sets accumulate any new symbols
        introduced within the local context. When the context manager exits, the local sets are popped,
        restoring the previous scope state.

        **Example**
            .. code-block:: python

                with scope_manager.enter_local_scope():
                    # Symbols defined here are local to this scope
                    ...

        :yields: None
        """
        self.scopes.append(set())
        self.callables.append(set())
        self.local_scope_indices.append(len(self.scopes) - 1)
        saved_skip = self.skip_reference_taking
        self.skip_reference_taking = set()
        try:
            yield
        finally:
            self.local_scope_indices.pop()
            self.scopes.pop()
            self.callables.pop()
            self.skip_reference_taking = saved_skip

    @contextlib.contextmanager
    def enter_control_flow_scope(
        self, *, isolate_callables: bool = False
    ) -> Generator[None, None, None]:
        """Enter a dynamic control-flow symbol scope.

        Variables introduced in the region are discarded on exit. Callable
        definitions normally remain function-scoped; speculative dispatch
        arms pass ``isolate_callables=True`` so their definitions stay visible
        within that arm but are discarded before tracing another candidate.

        :yields: None

        **Example**
            .. code-block:: python

                with scope_manager.enter_control_flow_scope():
                    # Variables defined here are local to this control-flow scope
                    ...
        """
        self.scopes.append(set())
        if isolate_callables:
            self.callables.append(set())
        try:
            yield
        finally:
            if isolate_callables:
                self.callables.pop()
            self.scopes.pop()


class Region:
    """
    Context manager for handling regions during AST transformations.

    This class is used to manage region-scoped state during DSL preprocessing.
    It is responsible for tracking and collecting new statements generated while
    visiting and transforming regions, such as the bodies of AST nodes representing
    constructs like loops or conditional blocks.

    Upon entering a region (using a ``with`` statement), the region is pushed onto
    the session's ``region_stack``, and prepares a place for new statements to be collected.
    On exit, the region is popped from the stack and any temporary state is cleaned up.

    Parameters
    ----------
    session_data : SessionData
        The shared session context for the AST preprocessor, which holds the region stack.
    owning_node : Optional[ast.stmt], default=None
        If provided, the AST statement node that owns this region; new statements will be append to _new_value of this new node.
    new_value : Optional[list[ast.stmt]], default=None
        If provided, a list for collecting new statements for this region.

    Methods
    -------
    __enter__()
        Enter the region context, mutate state as needed.
    __exit__(exc_type, exc_value, traceback)
        Exit the context, clean up state.
    append_new_stmts(stmts)
        Append new AST statements to the region's collection.
    """

    def __init__(
        self,
        session_data: "SessionData",
        *,
        owning_node: ast.stmt | None = None,
        new_value: list[ast.stmt] | None = None,
    ) -> None:
        self.session_data = session_data
        self.owning_node = owning_node
        self.new_value = new_value

    def __enter__(self) -> "Region":
        if self.new_value is not None or isinstance(self.owning_node, ast.stmt):
            self.session_data.region_stack.append(self)
        if self.owning_node is not None:
            self.owning_node._new_value = []  # type: ignore[attr-defined]
        return self

    def __exit__(
        self,
        exc_type: type[BaseException] | None,
        exc_value: BaseException | None,
        traceback: types.TracebackType | None,
    ) -> None:
        if self.new_value is not None or isinstance(self.owning_node, ast.stmt):
            self.session_data.region_stack.pop()
        if self.owning_node is not None:
            delattr(self.owning_node, "_new_value")

    def append_new_stmts(self, stmts: list[ast.stmt]) -> None:
        """
        Append a list of statements to the region's collection.

        Parameters
        ----------
        stmts : list[ast.stmt]
            The AST statements to append to this region.
        """
        if self.owning_node is not None:
            self.owning_node._new_value.extend(stmts)  # type: ignore[attr-defined]
        else:
            assert self.new_value is not None
            self.new_value.extend(stmts)


@dataclass
class SessionData:
    """
    Session data for the DSL preprocessor.
    """

    counter: int = 0  # Unique function names for multiple loops
    scope_manager: ScopeManager = field(default_factory=ScopeManager.create)
    function_name: str = "<unknown function>"
    class_name: str | None = None
    file_name: str = "<unknown filename>"
    function_globals: dict[str, Any] | None = None
    import_top_module: bool = False
    region_stack: list[Region] = field(default_factory=list)
    generator_targets: list[str] = field(default_factory=list)
    lambda_args: list[str] = field(default_factory=list)
    captured_control_flow_writebacks: list[set[str]] = field(default_factory=list)
    control_flow_policies: list[ControlFlowPolicy] = field(
        default_factory=lambda: [ControlFlowPolicy.TRACE]
    )
    # Nesting depth inside the argument list of a ``const_expr(...)`` call.
    const_expr_arg_depth: int = 0

    @contextlib.contextmanager
    def _set_attr(self, attr: str, value: str) -> Generator[None, None, None]:
        """Temporarily set ``self.<attr>`` to ``value``, restoring it on exit."""
        old_value = getattr(self, attr)
        setattr(self, attr, value)
        try:
            yield
        finally:
            setattr(self, attr, old_value)

    def set_current_class_name(self, class_name: str) -> Any:
        return self._set_attr("class_name", class_name)

    def set_current_function_name(self, function_name: str) -> Any:
        return self._set_attr("function_name", function_name)

    @contextlib.contextmanager
    def control_flow_policy(
        self, policy: ControlFlowPolicy
    ) -> Generator[None, None, None]:
        """Temporarily select how nested control-flow nodes are transformed."""
        self.control_flow_policies.append(policy)
        try:
            yield
        finally:
            popped = self.control_flow_policies.pop()
            assert popped is policy
            assert self.control_flow_policies

    @property
    def current_control_flow_policy(self) -> ControlFlowPolicy:
        return self.control_flow_policies[-1]

    @contextlib.contextmanager
    def const_expr_arguments(self) -> Generator[None, None, None]:
        """Mark the arguments of a ``const_expr(...)`` call as declared
        trace-time constants for the duration of the visit."""
        self.const_expr_arg_depth += 1
        try:
            yield
        finally:
            self.const_expr_arg_depth -= 1

    @contextlib.contextmanager
    def deferred_body(self) -> Generator[None, None, None]:
        """Visit code that runs LATER than the expression it is written in (a
        lambda body): the surrounding ``const_expr(...)`` declaration covers
        only what argument evaluation itself executes, so it is suspended."""
        depth = self.const_expr_arg_depth
        self.const_expr_arg_depth = 0
        try:
            yield
        finally:
            self.const_expr_arg_depth = depth

    @property
    def inside_const_expr_argument(self) -> bool:
        return self.const_expr_arg_depth > 0

    @contextlib.contextmanager
    def collect_captured_control_flow_writebacks(
        self,
    ) -> Generator[set[str], None, None]:
        """Collect outlined writebacks that target an enclosing closure."""
        writebacks: set[str] = set()
        self.captured_control_flow_writebacks.append(writebacks)
        try:
            yield writebacks
        finally:
            self.captured_control_flow_writebacks.pop()

    def record_captured_control_flow_writeback(self, name: str) -> None:
        """Record a generated writeback only when it changes closure scope."""
        if self.captured_control_flow_writebacks:
            self.captured_control_flow_writebacks[-1].add(name)


def _create_module_attribute(
    func_name: str,
    *,
    use_base_dsl: bool = True,
    submodule_name: str | None = "ast_helpers",
    lineno: int | None = None,
    col_offset: int | None = None,
) -> ast.Attribute:
    """Creates an AST node representing a qualified attribute access to a function in a module or submodule.

    :param func_name: The attribute or function name to access
    :type func_name: str
    :param top_module_name: The top-level module name, defaults to "_dsl_"
    :type top_module_name: str, optional
    :param submodule_name: The submodule name to access within the top module,
        defaults to "ast_helpers"
    :type submodule_name: str, optional
    :param lineno: The line number to use for AST node location, defaults to None
    :type lineno: int, optional
    :param col_offset: The column offset to use for AST node location, defaults to None
    :type col_offset: int, optional
    :return: An AST Attribute node corresponding to the desired attribute access,
        with optional location info
    :rtype: ast.Attribute
    """

    # If we simply copy location from origin node, it contains a way to wide range, which cause location in traceback to be wrong.
    def set_location(
        node: ast.expr, lineno: int | None, col_offset: int | None
    ) -> None:
        if lineno is None or col_offset is None:
            return
        node.lineno = lineno
        node.end_lineno = lineno
        node.col_offset = col_offset
        node.end_col_offset = col_offset

    base: ast.expr = ast.Name(
        id="__base_dsl__" if use_base_dsl else "__module_dsl__", ctx=ast.Load()
    )
    set_location(base, lineno, col_offset)
    if submodule_name:
        base = ast.Attribute(value=base, attr=submodule_name, ctx=ast.Load())
        set_location(base, lineno, col_offset)
    result = ast.Attribute(value=base, attr=func_name, ctx=ast.Load())
    set_location(result, lineno, col_offset)
    return result


def _mark_synth_scope(func_def: ast.FunctionDef, origin: ast.AST) -> ast.FunctionDef:
    """SYNTHESIZED-scope fact: this def is a rewrite-created arm/body block,
    not a source scope; the call-boundary pass keys frame reflection on it.

    The def also takes *origin*'s source location here rather than at each
    construction site.  This is the one funnel every synthesized scope block
    passes through, and PyIR reads such a block's ``lineno`` while the pass is
    still running (the closure-cell registration it inserts at the block's
    entry), long before the tree-wide location fixup at the end of
    ``transform_function``.
    """
    func_def._pyir_synth_scope = True  # type: ignore[attr-defined]
    return ast.copy_location(func_def, origin)


_ComprehensionT = TypeVar(
    "_ComprehensionT", ast.ListComp, ast.SetComp, ast.GeneratorExp, ast.DictComp
)


def _while_condition_bound_names(test: ast.expr) -> list[str]:
    """Bare names a ``while`` condition binds with ``:=``, in source order.
    A comprehension's walrus binds the enclosing scope while the condition
    runs (PEP 572), so it counts; a lambda body binds only when the lambda is
    called, so its walruses are not condition bindings."""
    names: list[str] = []

    class _Targets(ast.NodeVisitor):
        def visit_NamedExpr(self, node: ast.NamedExpr) -> None:
            if isinstance(node.target, ast.Name) and node.target.id not in names:
                names.append(node.target.id)
            self.generic_visit(node)

        def _skip(self, node: ast.AST) -> None:
            return None

        visit_Lambda = _skip

    _Targets().visit(test)
    return names


class DSLPreprocessor(ast.NodeTransformer):
    """
    A preprocessor for transforming Python ASTs. It supports:

    - Rewriting `for` loops with the `@loop_selector` decorator.
    - Rewriting `if-elif-else` statements with the `@if_selector` decorator.
    - Generating `yield` operations for read-write or write symbols.
    """

    DECORATOR_FOR_STATEMENT = "loop_selector"
    DECORATOR_IF_STATEMENT = "if_selector"
    DECORATOR_WHILE_STATEMENT = "while_selector"
    IF_EXECUTOR = "if_executor"

    # F-COVER: the base rewrite emits no PyIR choke set, so functions it
    # rewrites carry no ``__pyir_rewritten__`` attestation stamp.
    choke_set_version: "int | None" = None
    IFEXP_EXECUTOR = "ifExp_executor"
    WHILE_EXECUTOR = "while_executor"
    ASSERT_EXECUTOR = "assert_executor"
    IMPLICIT_DOWNCAST_NUMERIC_TYPE = "implicitDowncastNumericType"
    CONST_EXPR_NAME = {"const_expr", "target_version"}
    COMPARE_EXECUTOR = "compare_executor"
    BUILTIN_REDIRECTOR = "redirect_builtin_function"
    NATIVE_EXIT_GUARD = "native_exit_guard"
    COMPREHENSION_CONDITION = "comprehension_condition"

    def generic_visit(self, node: ast.AST) -> ast.AST:
        """
        Copy of :meth:`ast.NodeTransformer.generic_visit` with support for inserting statements during expression visits.

        This version provides the same recursive traversal and transformation as the standard
        ``generic_visit``, but extends it to allow statement insertion when visiting expressions.
        This is particularly useful for DSL AST processing that needs to emit new statements within
        regions associated with expression nodes (e.g., using the ``Region`` context manager).

        :param node: The AST node to process.
        :type node: ast.AST
        :return: The transformed AST node.
        :rtype: ast.AST
        """
        for field, old_value in ast.iter_fields(node):
            if isinstance(old_value, list):
                with Region(self.session_data, owning_node=node):  # type: ignore[arg-type]
                    for value in old_value:
                        if isinstance(value, ast.AST):
                            value = self.visit(value)
                            if value is None:
                                continue
                            elif not isinstance(value, ast.AST):
                                node._new_value.extend(value)  # type: ignore[attr-defined]
                                continue
                        node._new_value.append(value)  # type: ignore[attr-defined]
                    old_value[:] = node._new_value  # type: ignore[attr-defined]
            elif isinstance(old_value, ast.AST):
                new_node = self.visit(old_value)
                if new_node is None:
                    delattr(node, field)
                else:
                    setattr(node, field, new_node)
        return node

    def __init__(
        self, client_module_name: list[str], *, warnings_ignore: bool = False
    ) -> None:
        super().__init__()
        # Persistent state
        self.processed_functions: set[Callable[..., Any]] = set()
        self.client_module_name = client_module_name
        self.warnings_ignore: bool = warnings_ignore
        self._session_data: SessionData | None = None

    def _create_session_data(self) -> SessionData:
        return SessionData()

    def _start_session(self) -> None:
        """Start a new preprocessing session by initializing session data."""
        self._session_data = self._create_session_data()
        # Track processed functions per preprocessing run, not for the entire
        # lifetime of this preprocessor instance. Mode switches can restore a
        # previously used preprocessor object, and stale entries here would make
        # later sessions skip transforming a function entirely.
        self.processed_functions = set()

    def _end_session(self) -> None:
        """End the current preprocessing session and clear session data."""
        self._session_data = None

    @contextlib.contextmanager
    def get_session(self) -> Generator["DSLPreprocessor", None, None]:
        try:
            self._start_session()
            yield self
        finally:
            self._end_session()

    @property
    def session_data(self) -> SessionData:
        assert self._session_data is not None, (
            "Please start a session before accessing session data"
        )
        return self._session_data

    def exec(
        self,
        function_name: str,
        original_function: Callable[..., Any],
        code_object: types.CodeType,
        exec_globals: dict[str, Any],
    ) -> Callable[..., Any] | None:
        # Execute the transformed code
        log().info(
            "ASTPreprocessor Executing transformed code for function [%s]",
            function_name,
        )
        exec(code_object, exec_globals)
        return exec_globals.get(function_name)

    @staticmethod
    def print_ast(transformed_tree: ast.AST | None = None) -> None:
        print("#", "-" * 40, "Transformed AST", "-" * 40)
        unparsed_code = ast.unparse(transformed_tree)  # type: ignore[arg-type]
        print(unparsed_code)
        print("#", "-" * 40, "End Transformed AST", "-" * 40)

    def make_func_param_name(self, base_name: str, used_names: Iterable[str]) -> str:
        """Generate a unique parameter name that doesn't collide with existing names."""
        if base_name not in used_names:
            return base_name

        i = 0
        while f"{base_name}_{i}" in used_names:
            i += 1
        return f"{base_name}_{i}"

    @staticmethod
    def _default_arg_source_names(func_ast: ast.FunctionDef) -> dict[str, str]:
        """Map parameters to source-level names used as their defaults."""
        ast_defaults: dict[str, ast.expr] = {}
        all_args = func_ast.args.posonlyargs + func_ast.args.args
        offset = len(all_args) - len(func_ast.args.defaults)
        for i, default_node in enumerate(func_ast.args.defaults):
            ast_defaults[all_args[offset + i].arg] = default_node
        for kwarg, kw_default in zip(
            func_ast.args.kwonlyargs, func_ast.args.kw_defaults
        ):
            if kw_default is not None:
                ast_defaults[kwarg.arg] = kw_default
        return {
            param_name: default_node.id
            for param_name, default_node in ast_defaults.items()
            if isinstance(default_node, ast.Name)
        }

    def _inject_default_arg_values(
        self,
        function_pointer: Callable[..., Any],
        source_names: dict[str, str],
    ) -> None:
        """Inject default-argument values whose source-level names are unresolvable.

        When a decorated function uses ``_param=name`` where ``name`` is a local
        in an enclosing factory, ``exec()`` needs ``name`` in its namespace.
        We use ``inspect.signature`` for runtime default values and the
        already-parsed source-name map for the name each default references.
        """
        exec_globals = self.session_data.function_globals
        if exec_globals is None:
            return
        sig = inspect.signature(function_pointer)
        params_with_defaults = {
            name: param.default
            for name, param in sig.parameters.items()
            if param.default is not inspect.Parameter.empty
        }
        if not params_with_defaults:
            return
        for param_name, default_val in params_with_defaults.items():
            source_name = source_names.get(param_name)
            if source_name is not None and source_name not in exec_globals:
                exec_globals[source_name] = default_val

    def _post_visit_function_body(self, func_def: ast.FunctionDef) -> "list[ast.stmt]":
        """Hook for a mode-specific post-pass over the fully instrumented
        function body; returns preamble statements to bind right after the
        module-alias imports.  The base rewrite has none."""
        return []

    def transform_function(
        self, func_name: str, function_pointer: Callable[..., Any]
    ) -> list[ast.stmt]:
        """
        Transforms a function.
        """
        # Skip if the function has already been processed
        if function_pointer in self.processed_functions:
            log().info(
                "ASTPreprocessor Skipping already processed function [%s]", func_name
            )
            return []

        # Step 1. Parse the given function
        try:
            file_name = inspect.getsourcefile(function_pointer) or "<unknown>"
            lines, start_line = inspect.getsourcelines(function_pointer)
            raw_source = "".join(lines)
            dedented_source = textwrap.dedent(raw_source)
            tree = ast.parse(dedented_source, filename=file_name)
            # Bump the line numbers so they match the real source file
            ast.increment_lineno(tree, start_line - 1)
            # ``textwrap.dedent`` stripped a constant leading-whitespace prefix,
            # so ast column offsets are relative to the dedented source.  Shift
            # them back to the original file's columns so diagnostics underline
            # the right place.  The stripped width is identical on every non-blank
            # line; derive it from the first line that still has content.
            _col_shift = 0
            for _raw, _ded in zip(raw_source.split("\n"), dedented_source.split("\n")):
                if _ded.strip():
                    _col_shift = (len(_raw) - len(_raw.lstrip())) - (
                        len(_ded) - len(_ded.lstrip())
                    )
                    break
            if _col_shift:
                for _node in ast.walk(tree):
                    if getattr(_node, "col_offset", None) is not None:
                        _node.col_offset += _col_shift  # type: ignore[attr-defined]
                    if getattr(_node, "end_col_offset", None) is not None:
                        _node.end_col_offset += _col_shift  # type: ignore[attr-defined]
        except (OSError, TypeError) as e:
            # No retrievable source (REPL / exec())
            raise DSLUserCodeError(DiagId.UNSUP_NO_SOURCE, func=func_name, cause=e)
        except Exception as e:
            raise DSLRuntimeError(f"Failed to parse function {func_name}", cause=e)

        # Step 1.2 Check the decorator (legacy Python backend)
        if not self.check_decorator(tree.body[0]):
            log().info(
                "[%s] - Skipping function due to missing decorator",
                func_name,
            )
            return []

        self.processed_functions.add(function_pointer)
        log().info("ASTPreprocessor Transforming function [%s]", func_name)

        # Step 1.3 Inject default-argument values from enclosing scopes.
        # When a decorated function uses `_param=name` where `name` is a
        # local in the enclosing factory, exec() needs `name` in its
        # namespace.  We use the already-parsed AST to find source-level
        # names and inspect.signature to get runtime values.
        func_def = tree.body[0]
        assert isinstance(func_def, ast.FunctionDef)
        self._inject_default_arg_values(
            function_pointer, self._default_arg_source_names(func_def)
        )

        # Step 2. Transform the function
        transformed_tree = self.visit(tree)

        # Step 2.5. Mode-specific post-pass over the instrumented tree (the
        # body is fully visited at this point); any returned preamble
        # statements bind after the module-alias imports below.
        preamble_stmts: "list[ast.stmt]" = []
        if isinstance(transformed_tree.body[0], ast.FunctionDef):
            preamble_stmts = self._post_visit_function_body(transformed_tree.body[0])

        # Step 3. Import cutlass and base_dsl
        top_module_name = ".".join(self.client_module_name)
        import_stmts: "list[ast.stmt]" = []
        if self.session_data.import_top_module:
            import_stmts.append(
                ast.Import(
                    names=[ast.alias(name=top_module_name, asname="__module_dsl__")]
                )
            )
        import_stmts.append(
            ast.Import(
                names=[
                    ast.alias(name=f"{top_module_name}.base_dsl", asname="__base_dsl__")
                ]
            )
        )

        assert len(transformed_tree.body) == 1
        assert isinstance(transformed_tree.body[0], ast.FunctionDef)
        import_stmts.extend(preamble_stmts)
        transformed_tree.body[0].body = import_stmts + transformed_tree.body[0].body
        # Remove all decorators from top level function
        transformed_tree.body[0].decorator_list = []

        # Step 4. Wrap the function with nonlocal captures, if has any
        # if the function has a nonlocal variable, wrap it in a function and return the function
        # pseudo code:
        # def foo():
        #      nonlocal_var_0 = None
        #      nonlocal_var_1 = None
        #      def foo(args):
        #          ...
        #      return foo
        # foo = foo()
        nonlocals = {v: None for v in function_pointer.__code__.co_freevars}

        if len(nonlocals) > 0:
            assignments = []
            for n, _ in nonlocals.items():
                assignments.append(
                    ast.Assign(
                        targets=[ast.Name(id=n, ctx=ast.Store())],
                        value=ast.Constant(value=None),
                    )
                )

            return_expr = [ast.Return(value=ast.Name(id=func_name, ctx=ast.Load()))]

            wrapper_fcn = ast.FunctionDef(
                name=func_name,
                args=ast.arguments(
                    posonlyargs=[],
                    args=[],
                    kwonlyargs=[],
                    kw_defaults=[],
                    defaults=[],
                ),
                body=assignments + transformed_tree.body + return_expr,
                decorator_list=[],
            )
            invoke = ast.Call(
                func=ast.Name(id=func_name, ctx=ast.Load()), args=[], keywords=[]
            )
            assign = ast.Assign(
                targets=[ast.Name(id=func_name, ctx=ast.Store())], value=invoke
            )
            transformed_tree.body = [wrapper_fcn, assign]

        # Step 4. Import cutlass and base_dsl
        ast.fix_missing_locations(transformed_tree)
        combined_body = transformed_tree.body

        # Step 5. Return the transformed tree
        return combined_body

    # Early exits that leave a loop rather than the whole function.
    _LOOP_EXIT_TYPES = frozenset({"break", "continue"})

    def _find_early_exit(
        self,
        tree: ast.AST,
        kind: str,
        exit_types: frozenset[str] | None = None,
    ) -> tuple[ast.AST, str] | None:
        """Find an early exit owned by the given control-flow region.

        The checker keeps the last exit it meets, so a caller interested in
        one class of exits narrows the search with *exit_types* instead of
        inspecting the reported kind.
        """

        class EarlyExitChecker(ast.NodeVisitor):
            def __init__(self, kind: str) -> None:
                self.has_early_exit = False
                self.early_exit_node: ast.AST | None = None
                self.early_exit_type: str | None = None
                self.kind = kind
                self.loop_nest_level = 0

            def record(self, node: ast.AST, exit_type: str) -> None:
                if exit_types is not None and exit_type not in exit_types:
                    return
                self.has_early_exit = True
                self.early_exit_node = node
                self.early_exit_type = exit_type

            def visit_Return(self, node: ast.Return) -> None:
                self.record(node, "return")

            def visit_Raise(self, node: ast.Raise) -> None:
                self.record(node, "raise")

            def visit_Break(self, node: ast.Break) -> None:
                if self.loop_nest_level == 0 and self.kind != "if":
                    self.record(node, "break")

            def visit_Continue(self, node: ast.Continue) -> None:
                if self.loop_nest_level == 0 and self.kind != "if":
                    self.record(node, "continue")

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
            return None
        assert checker.early_exit_node is not None
        assert checker.early_exit_type is not None
        return checker.early_exit_node, checker.early_exit_type

    def check_early_exit(self, tree: ast.AST, kind: str) -> None:
        """Reject an early exit owned by the given control-flow region."""
        early_exit = self._find_early_exit(tree, kind)
        if early_exit is None:
            return
        offender, exit_type = early_exit
        where = f"`{self.session_data.function_name}`" + (
            f" in `{self.session_data.class_name}`"
            if self.session_data.class_name
            else ""
        )
        raise DSLUserCodeError(
            DiagId.UNSUP_EARLY_EXIT,
            filename=self.session_data.file_name,
            lineno=getattr(offender, "lineno", None),
            col_offset=getattr(offender, "col_offset", None),
            end_col_offset=getattr(offender, "end_col_offset", None),
            kind=exit_type,
            where=where,
        )

    def is_const_expr_call(self, node: ast.expr) -> bool:
        """``const_expr(...)`` / ``<pkg>.const_expr(...)`` (and the
        ``target_version`` twin): the call declares its argument a trace-time
        constant expression."""
        if not isinstance(node, ast.Call):
            return False
        func = node.func
        if isinstance(func, ast.Attribute):
            return func.attr in self.CONST_EXPR_NAME
        return isinstance(func, ast.Name) and func.id in self.CONST_EXPR_NAME

    def is_node_constexpr(self, node: ast.If | ast.While) -> bool:
        """
        Determines if the node is a constexpr.
        Supported nodes are if, while statements.
        """
        if isinstance(node, (ast.If, ast.While)):
            return self.is_const_expr_call(node.test)
        return False

    def transform(
        self,
        original_function: Callable[..., Any],
        exec_globals: dict[str, Any],
    ) -> ast.Module:
        """
        Transforms the provided function using the preprocessor.
        Requires an active DSL preprocessor session.

        Args:
            original_function: The function to transform.
            exec_globals: The globals dict for the function's module.
        """
        self.session_data.file_name = (
            inspect.getsourcefile(original_function) or "<unknown>"
        )
        self.session_data.function_globals = exec_globals
        transformed_tree = self.transform_function(
            original_function.__name__, original_function
        )
        self.session_data.function_globals = None
        unified_tree = ast.Module(body=transformed_tree, type_ignores=[])
        # Both backends already fixed every returned statement's locations.
        # ast.Module adds no source-location fields, so no further walk is needed.
        return unified_tree

    def analyze_region_variables(
        self,
        node: ast.For | ast.If | ast.While,
        active_symbols: list[set[str]],
        active_callables: list[set[str]],
    ) -> tuple[list[str], int, list[str]]:
        """
        Analyze loop-carried and closure variables in a control-flow region.

        This is the reference implementation used by the Python backend. The
        full native transformer performs the same analysis internally without
        crossing back into Python for individual control-flow regions.
        """
        # we need orderedset to keep the insertion order the same. otherwise generated IR is different each time
        write_args = OrderedSet()
        invoked_args = OrderedSet()
        called_functions = OrderedSet()

        class RegionAnalyzer(ast.NodeVisitor):
            force_store = False

            def visit_Name(self, node: ast.Name) -> None:
                """
                Mark every store as write.
                """
                if isinstance(node.ctx, ast.Store) or self.force_store:
                    write_args.add(node.id)

            def visit_Subscript(self, node: ast.Subscript) -> None:
                if isinstance(node.ctx, ast.Store):
                    self.force_store = True
                    self.visit(node.value)
                    self.force_store = False
                    self.visit(node.slice)
                else:
                    self.generic_visit(node)

            def visit_Assign(self, node: ast.Assign) -> None:
                self.force_store = True
                [self.visit(target) for target in node.targets]
                self.force_store = False
                self.visit(node.value)

            def visit_AugAssign(self, node: ast.AugAssign) -> None:
                self.force_store = True
                self.visit(node.target)
                self.force_store = False
                self.visit(node.value)

            @staticmethod
            def get_call_base(func_node: ast.expr) -> str | None:
                if isinstance(func_node, ast.Attribute):
                    if isinstance(func_node.value, ast.Attribute):
                        return RegionAnalyzer.get_call_base(func_node.value)
                    elif isinstance(func_node.value, ast.Name):
                        return func_node.value.id
                    else:
                        return None
                elif isinstance(func_node, ast.Name):
                    return None
                return None

            def visit_Call(self, node: ast.Call) -> None:
                base_name = RegionAnalyzer.get_call_base(node.func)

                if isinstance(node.func, ast.Name):
                    func_name = node.func.id
                    called_functions.add(func_name)

                # Classes are mutable by default. Mark them as write. If they are
                # dataclass(frozen=True), treat them as read in runtime.
                if base_name is not None and base_name not in ("self",):
                    invoked_args.add(base_name)

                self.generic_visit(node)

        analyzer = RegionAnalyzer()
        analyzer.visit(ast.Module(body=node.body, type_ignores=[]))
        if node.orelse:
            analyzer.visit(ast.Module(body=node.orelse, type_ignores=[]))

        # While's loop condition is executed n times, as loop body
        # So collect the variables used in the loop condition
        if isinstance(node, ast.While):
            analyzer.visit(ast.Module(body=node.test, type_ignores=[]))  # type: ignore[arg-type]

        # If arg is both write and invoke, remove from invoked_args
        invoked_args = invoked_args - write_args

        write_args_list: list[str] = list(write_args.intersections(active_symbols))
        invoked_args_list: list[str] = list(invoked_args.intersections(active_symbols))
        # The current function is tracked as callable so recursive references
        # resolve inside its body, but it is not an enclosing closure. Checking
        # the decorated runtime wrapper would inspect the decorator's captures
        # instead of the user's function.
        current_function_name = (
            self._session_data.function_name if self._session_data is not None else None
        )
        called_functions_list: list[str] = [
            name
            for name in called_functions.intersections(active_callables)
            if name != current_function_name
        ]
        return (
            write_args_list + invoked_args_list,
            len(write_args_list),
            called_functions_list,
        )

    def extract_range_args(
        self, iter_node: ast.Call
    ) -> tuple[ast.expr, ast.expr, ast.expr, bool]:
        args = iter_node.args
        if len(args) == 1:
            return (
                self.visit(ast.Constant(value=0)),
                self.visit(args[0]),
                self.visit(ast.Constant(value=1)),
                False,
            )
        elif len(args) == 2:
            return (
                self.visit(args[0]),
                self.visit(args[1]),
                self.visit(ast.Constant(value=1)),
                False,
            )
        elif len(args) == 3:
            return self.visit(args[0]), self.visit(args[1]), self.visit(args[2]), True
        else:
            raise DSLUserCodeError(
                DiagId.UNSUP_RANGE_ARGS,
                filename=self.session_data.file_name,
                lineno=getattr(iter_node, "lineno", None),
                col_offset=getattr(iter_node, "col_offset", None),
                end_col_offset=getattr(iter_node, "end_col_offset", None),
            )

    @staticmethod
    def _keyword_map(iter_node: ast.Call) -> dict[str | None, ast.expr]:
        """Map a call's keyword arguments by name to their value AST nodes."""
        return {kw.arg: kw.value for kw in iter_node.keywords}

    def extract_unroll_args(self, iter_node: ast.Call) -> tuple[ast.expr, ast.expr]:
        keywords = self._keyword_map(iter_node)
        return (
            keywords.get("unroll", ast.Constant(value=-1)),
            keywords.get("unroll_full", ast.Constant(value=False)),
        )

    def extract_prefetch_stages_args(self, iter_node: ast.Call) -> ast.expr:
        keywords = self._keyword_map(iter_node)
        if "pipelining" in keywords:
            return keywords.get("pipelining", ast.Constant(value=None))
        return keywords.get("prefetch_stages", ast.Constant(value=None))

    def extract_vectorize_args(self, iter_node: ast.Call) -> ast.expr:
        keywords = self._keyword_map(iter_node)
        return keywords.get("vectorize", ast.Constant(value=None))

    def extract_at_least_once_args(self, iter_node: ast.Call) -> ast.expr:
        keywords = self._keyword_map(iter_node)
        return keywords.get("at_least_once", ast.Constant(value=False))

    def _visit_stmts_into(self, stmts: list[ast.stmt], out: list[ast.stmt]) -> None:
        """Visit each statement and append its result to ``out``, flattening lists.

        Shared inner loop for the control-flow body builders (loop / if-then /
        if-else / while-after); call inside the appropriate Region/scope context.
        """
        for stmt in stmts:
            transformed_stmt = self.visit(stmt)  # Recursively visit inner statements
            if isinstance(transformed_stmt, list):
                out.extend(transformed_stmt)
            else:
                out.append(transformed_stmt)

    def create_loop_function(
        self,
        func_name: str,
        node: ast.For,
        start: ast.expr,
        stop: ast.expr,
        step: ast.expr,
        unroll: ast.expr,
        unroll_full: ast.expr,
        prefetch_stages: ast.expr,
        vectorize: ast.expr,
        at_least_once: ast.expr,
        write_args: list[str],
        full_write_args_count: int,
    ) -> ast.FunctionDef:
        """
        Creates a loop body function with the `loop_selector` decorator.
        """

        assert isinstance(node.target, ast.Name)
        func_args = [ast.arg(arg=node.target.id, annotation=None)]
        func_args += [ast.arg(arg=var, annotation=None) for var in write_args]

        # Create the loop body
        transformed_body: list[ast.stmt] = []
        # Template-method hook: capture the pyir_promote_loop_body_arg
        # prologue against the ORIGINAL node.body BEFORE the body visit
        # mutates it (e.g. _insert_pyir_attr_reads replaces bare
        # ``Name(scale_d, Load)`` with ``Name(_pyir_name_N, Load)``).
        # The captured stmts are prepended after the body visit completes.
        body_prep_stmts = self._prepare_loop_body_vars(node, write_args)

        with Region(self.session_data, new_value=transformed_body):
            self._visit_stmts_into(node.body, transformed_body)

        if body_prep_stmts:
            transformed_body[:0] = body_prep_stmts

        # Handle the return for a single iterated argument correctly
        if len(write_args) == 0:
            transformed_body.append(ast.Return())
        else:
            transformed_body.append(
                ast.Return(
                    value=ast.List(
                        elts=[ast.Name(id=var, ctx=ast.Load()) for var in write_args],
                        ctx=ast.Load(),
                    )
                )
            )

        # Define the decorator with parameters
        decorator = ast.copy_location(
            ast.Call(
                func=_create_module_attribute(
                    self.DECORATOR_FOR_STATEMENT,
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[start, stop, step],
                keywords=[
                    ast.keyword(arg="unroll", value=unroll),
                    ast.keyword(arg="unroll_full", value=unroll_full),
                    ast.keyword(arg="prefetch_stages", value=prefetch_stages),
                    ast.keyword(arg="vectorize", value=vectorize),
                    ast.keyword(arg="at_least_once", value=at_least_once),
                    ast.keyword(
                        arg="write_args",
                        value=self.generate_get_locals_or_none_call(write_args),
                    ),
                    ast.keyword(
                        arg="full_write_args_count",
                        value=ast.Constant(value=full_write_args_count),
                    ),
                    ast.keyword(
                        arg="write_args_names",
                        value=ast.List(
                            elts=[ast.Constant(value=arg) for arg in write_args],
                            ctx=ast.Load(),
                        ),
                    ),
                ],
            ),
            node,
        )

        return _mark_synth_scope(
            ast.FunctionDef(
                name=func_name,
                args=ast.arguments(
                    posonlyargs=[],
                    args=func_args,
                    kwonlyargs=[],
                    kw_defaults=[],
                    defaults=[],
                ),
                body=transformed_body,
                decorator_list=[decorator],
            ),
            node,
        )

    def visit_BoolOp(self, node: ast.BoolOp) -> ast.expr:
        """Lower to (start < term(None, a) < term(combine, b) < ...).value.

        Python evaluates each comparator at most once, in the original scope,
        and tests only intermediate results. Emit the Compare *after* visiting
        the operands: this is interpreter control flow, not a DSL comparison.
        """
        self.generic_visit(node)

        if isinstance(node.op, ast.And):
            start_name, helper_name = "_and_start", "and_"
        elif isinstance(node.op, ast.Or):
            start_name, helper_name = "_or_start", "or_"
        else:
            # BoolOp should be either And or Or -- reaching here is a compiler
            # bug (the AST grammar only produces And/Or), not an author mistake.
            raise DSLRuntimeError(
                f"Unsupported boolean operation: {node.op}",
                filename=self.session_data.file_name,
                snippet=ast.unparse(node),
            )

        self.session_data.import_top_module = True
        terms: list[ast.expr] = []
        for index, operand in enumerate(node.values):
            combine = (
                _create_module_attribute(
                    helper_name,
                    use_base_dsl=False,
                    submodule_name=None,
                    lineno=operand.lineno,
                    col_offset=operand.col_offset,
                )
                if index
                else ast.Constant(value=None)
            )
            terms.append(
                ast.copy_location(
                    ast.Call(
                        func=_create_module_attribute(
                            "_BoolOpTerm",
                            lineno=operand.lineno,
                            col_offset=operand.col_offset,
                        ),
                        args=[combine, operand],
                        keywords=[],
                    ),
                    operand,
                )
            )
        chain = ast.Compare(
            left=_create_module_attribute(
                start_name, lineno=node.lineno, col_offset=node.col_offset
            ),
            ops=[ast.Lt() for _ in terms],
            comparators=terms,
        )
        return ast.copy_location(
            ast.Attribute(value=chain, attr="value", ctx=ast.Load()), node
        )

    def visit_UnaryOp(self, node: ast.UnaryOp) -> ast.expr:
        # Visit child nodes first
        self.generic_visit(node)

        # Transform "not" to "~" as we overload __invert__
        if isinstance(node.op, ast.Not):
            func_name = _create_module_attribute(
                "not_",
                use_base_dsl=False,
                submodule_name=None,
                lineno=node.lineno,
                col_offset=node.col_offset,
            )
            self.session_data.import_top_module = True
            return ast.copy_location(
                ast.Call(func=func_name, args=[node.operand], keywords=[]), node
            )

        return node

    def _insert_range_value_check(self, node: ast.For) -> None:
        """
        Insert a check for range arguments
        """
        assert isinstance(node.iter, ast.Call)
        range_inputs = node.iter.args
        check_call = ast.copy_location(
            ast.Call(
                func=_create_module_attribute(
                    "range_value_check", lineno=node.lineno, col_offset=node.col_offset
                ),
                args=range_inputs,
                keywords=[],
            ),
            node.iter,
        )
        node.iter = ast.copy_location(
            ast.Call(
                func=ast.Name(id="range", ctx=ast.Load()),
                args=[ast.Starred(value=check_call, ctx=ast.Load())],
                keywords=[],
            ),
            node.iter,
        )

    def _insert_cf_symbol_check(self, func: ast.expr) -> ast.Expr:
        """
        Insert a check for range symbol
        """
        check_call = ast.copy_location(
            ast.Call(
                func=_create_module_attribute(
                    "cf_symbol_check", lineno=func.lineno, col_offset=func.col_offset
                ),
                args=[_deepcopy_ast_root(func)],
                keywords=[],
            ),
            func,
        )
        return ast.Expr(check_call)

    def _create_for_iter_symbol_check(self, iter_node: ast.expr) -> ast.Expr | None:
        """Validate reserved DSL range spellings before evaluating the iterable."""
        if not isinstance(iter_node, ast.Call):
            return None

        func = iter_node.func
        if isinstance(func, ast.Name):
            if func.id in {"range_constexpr", "range_dynamic"}:
                return self._insert_cf_symbol_check(func)
            return None

        if isinstance(func, ast.Attribute):
            if func.attr == "range":
                return self._insert_cf_symbol_check(func.value)
            if func.attr in {"range_constexpr", "range_dynamic"}:
                return self._insert_cf_symbol_check(func)
        return None

    def _handle_constexpr_for(self, node: ast.For) -> ast.For | list[ast.stmt]:
        """Handle const_expr/static for loops. Override for custom behavior."""
        self.generic_visit(node)
        return node

    @staticmethod
    def _is_range_constexpr_for(node: ast.For) -> bool:
        """Return whether *node* directly uses the reserved constexpr range.

        An explicit ``range_constexpr`` is guaranteed to be a trace-time
        Python loop, so its body definitions follow Python's function-local
        scope rules. Every other iterable spelling is classified at trace
        time; its native arm follows the same Python scope rules, while its
        staged arm carries only variables bound before the loop.
        """
        if not isinstance(node.iter, ast.Call):
            return False
        func = node.iter.func
        return (isinstance(func, ast.Name) and func.id == "range_constexpr") or (
            isinstance(func, ast.Attribute) and func.attr == "range_constexpr"
        )

    def _transform_runtime_dispatched_for(self, node: ast.For) -> list[ast.stmt]:
        """Select staged or native loop handling from the trace-time iterable."""
        symbol_check = self._create_for_iter_symbol_check(node.iter)
        suffix = self.session_data.counter
        self.session_data.counter += 1
        iter_name = f"_dsl_for_iter_{suffix}"
        self.session_data.scope_manager.add_skip_reference_taking(iter_name)

        visited_iter = self.visit(node.iter)
        assert isinstance(visited_iter, ast.expr)
        if isinstance(visited_iter, ast.Call):
            factory = visited_iter.func
            if isinstance(factory, ast.Attribute) and factory.attr == "range":
                factory = _create_module_attribute(
                    "range",
                    lineno=factory.lineno,
                    col_offset=factory.col_offset,
                )
            visited_iter = ast.copy_location(
                ast.Call(
                    func=_create_module_attribute(
                        "materialize_for_iter",
                        lineno=visited_iter.lineno,
                        col_offset=visited_iter.col_offset,
                    ),
                    args=[factory, *visited_iter.args],
                    keywords=visited_iter.keywords,
                ),
                visited_iter,
            )
        iter_assign = ast.copy_location(
            ast.Assign(
                targets=[ast.Name(id=iter_name, ctx=ast.Store())],
                value=visited_iter,
            ),
            node.iter,
        )

        def iter_attr(name: str) -> ast.Attribute:
            return ast.Attribute(
                value=ast.Name(id=iter_name, ctx=ast.Load()),
                attr=name,
                ctx=ast.Load(),
            )

        def iter_option(name: str, default: int | bool | None) -> ast.Call:
            return ast.Call(
                func=ast.Name(id="getattr", ctx=ast.Load()),
                args=[
                    ast.Name(id=iter_name, ctx=ast.Load()),
                    ast.Constant(value=name),
                    ast.Constant(value=default),
                ],
                keywords=[],
            )

        dynamic_for = _deepcopy_ast_root(node)
        dynamic_for.iter = ast.copy_location(
            ast.Call(
                func=ast.Name(id="range", ctx=ast.Load()),
                args=[iter_attr("start"), iter_attr("stop"), iter_attr("step")],
                keywords=[
                    ast.keyword(arg="unroll", value=iter_option("unroll", -1)),
                    ast.keyword(
                        arg="unroll_full", value=iter_option("unroll_full", False)
                    ),
                    ast.keyword(
                        arg="prefetch_stages",
                        value=iter_option("prefetch_stages", None),
                    ),
                    ast.keyword(arg="vectorize", value=iter_option("vectorize", None)),
                    ast.keyword(
                        arg="at_least_once",
                        value=iter_option("at_least_once", False),
                    ),
                ],
            ),
            node.iter,
        )

        python_for = _deepcopy_ast_root(node)
        python_for.iter = ast.copy_location(
            ast.Name(id=iter_name, ctx=ast.Load()), node.iter
        )
        active_symbols = self.session_data.scope_manager.get_active_symbols()
        # The native arm keeps the user's spellings. Like plain Python, a name
        # first bound in the loop body belongs to the enclosing function and
        # stays readable after the loop; the ScopeManager scope below only
        # keeps such names from becoming loop-carried values of the staged arm.
        with self.session_data.scope_manager.enter_control_flow_scope(
            isolate_callables=True
        ):
            # Keep the selected arm as a native ``for``. Nested regions decide
            # locally whether an early exit requires native ownership or they
            # can return to TRACE, avoiding a pre-scan of the whole loop body.
            with self.session_data.control_flow_policy(ControlFlowPolicy.NATIVE):
                visited_python_for = self._handle_constexpr_for(python_for)
        assert isinstance(visited_python_for, ast.For)
        python_for = visited_python_for

        active_callables = self.session_data.scope_manager.get_active_callables()
        counter_snapshot = self.session_data.counter
        scope_manager_snapshot = deepcopy(self.session_data.scope_manager)
        python_preamble: list[ast.stmt] = []
        try:
            with self.session_data.scope_manager.enter_control_flow_scope():
                if isinstance(dynamic_for.target, ast.Name):
                    self.session_data.scope_manager.add_to_scope(dynamic_for.target.id)
                dynamic_body = self.transform_for_loop(
                    dynamic_for, active_symbols, active_callables
                )
        except Exception as error:
            # The dynamic arm is speculative until trace-time dispatch. Keep an
            # error from that dead arm from rejecting a native Python loop, but
            # preserve the exact exception if the iterable is actually dynamic.
            self.session_data.counter = counter_snapshot
            self.session_data.scope_manager.restore_from(scope_manager_snapshot)
            error_id = register_deferred_for_error(error)
            dynamic_body = [
                ast.copy_location(
                    ast.Expr(
                        ast.Call(
                            func=_create_module_attribute(
                                "raise_deferred_for_error",
                                lineno=node.lineno,
                                col_offset=node.col_offset,
                            ),
                            args=[ast.Constant(value=error_id)],
                            keywords=[],
                        )
                    ),
                    node,
                )
            ]
            python_preamble = [
                ast.copy_location(
                    ast.Expr(
                        ast.Call(
                            func=_create_module_attribute(
                                "discard_deferred_for_error",
                                lineno=node.lineno,
                                col_offset=node.col_offset,
                            ),
                            args=[ast.Constant(value=error_id)],
                            keywords=[],
                        )
                    ),
                    node,
                )
            ]

        dispatch = ast.copy_location(
            ast.If(
                test=ast.Call(
                    func=_create_module_attribute(
                        "is_dynamic_range",
                        lineno=node.iter.lineno,
                        col_offset=node.iter.col_offset,
                    ),
                    args=[ast.Name(id=iter_name, ctx=ast.Load())],
                    keywords=[],
                ),
                body=dynamic_body,
                orelse=[*python_preamble, python_for],
            ),
            node,
        )
        self._visit_runtime_dispatch(dispatch)
        return [
            *([symbol_check] if symbol_check is not None else []),
            iter_assign,
            dispatch,
        ]

    @staticmethod
    def _literal_for_iter_kind(iter_node: ast.expr) -> str | None:
        """Classify an iterable whose loop kind is already known before tracing.

        "range" is a ``range(...)`` / ``<module>.range(...)`` call with plain
        positional arguments and only the loop options the staged lowering
        knows; "python" is a list or tuple display; None is anything else
        (name, attribute, subscript, other call). Star-unpacking and any other
        keyword (``pipelining``, ``**kw``, unknown names) keep the dispatch, so
        the range object built at trace time still does their argument check,
        deprecation warning and unexpected-keyword error.
        """
        if isinstance(iter_node, (ast.List, ast.Tuple)):
            return "python"
        if not isinstance(iter_node, ast.Call):
            return None
        func = iter_node.func
        is_range = (isinstance(func, ast.Name) and func.id == "range") or (
            isinstance(func, ast.Attribute) and func.attr == "range"
        )
        if not is_range:
            return None
        if any(isinstance(arg, ast.Starred) for arg in iter_node.args) or any(
            keyword.arg not in _STAGED_RANGE_KEYWORDS for keyword in iter_node.keywords
        ):
            return None
        return "range"

    def _transform_staged_for(self, node: ast.For) -> list[ast.stmt]:
        """Lower a ``for`` over a literal range call straight to a staged loop."""
        assert isinstance(node.iter, ast.Call)
        symbol_check = self._create_for_iter_symbol_check(node.iter)
        # The positional bounds are visited by transform_for_loop; the loop
        # options are copied into the loop_selector call as they are, so visit
        # them here like the dispatch visits the whole iterable expression.
        for keyword in node.iter.keywords:
            visited_value = self.visit(keyword.value)
            assert isinstance(visited_value, ast.expr)
            keyword.value = visited_value
        active_symbols = self.session_data.scope_manager.get_active_symbols()
        active_callables = self.session_data.scope_manager.get_active_callables()
        with self.session_data.scope_manager.enter_control_flow_scope():
            if isinstance(node.target, ast.Name):
                self.session_data.scope_manager.add_to_scope(node.target.id)
            statements = self.transform_for_loop(node, active_symbols, active_callables)
        return [*([symbol_check] if symbol_check is not None else []), *statements]

    def _transform_native_for(self, node: ast.For) -> list[ast.stmt]:
        """Keep a ``for`` over a list or tuple display as the Python loop.

        Same shape as the Python candidate of a dispatched loop, minus the
        dispatch: the iterable is bound once and the body runs as plain
        Python, so names bound in the body follow Python's function scope.
        """
        suffix = self.session_data.counter
        self.session_data.counter += 1
        iter_name = f"_dsl_for_iter_{suffix}"
        self.session_data.scope_manager.add_skip_reference_taking(iter_name)
        visited_iter = self.visit(node.iter)
        assert isinstance(visited_iter, ast.expr)
        iter_assign = ast.copy_location(
            ast.Assign(
                targets=[ast.Name(id=iter_name, ctx=ast.Store())],
                value=visited_iter,
            ),
            node.iter,
        )
        node.iter = ast.copy_location(ast.Name(id=iter_name, ctx=ast.Load()), node.iter)
        with self.session_data.scope_manager.enter_control_flow_scope(
            isolate_callables=True
        ):
            with self.session_data.control_flow_policy(ControlFlowPolicy.NATIVE):
                visited = self._handle_constexpr_for(node)
        assert isinstance(visited, ast.For)
        return [iter_assign, visited]

    def visit_For(self, node: ast.For) -> ast.For | list[ast.stmt]:
        if self._is_range_constexpr_for(node):
            symbol_check = self._create_for_iter_symbol_check(node.iter)
            visited = self._handle_constexpr_for(node)
            self._insert_range_value_check(node)
            statements = visited if isinstance(visited, list) else [visited]
            checks = [symbol_check] if symbol_check is not None else []
            return [*checks, *statements]

        if self.session_data.current_control_flow_policy is ControlFlowPolicy.NATIVE:
            if self._find_early_exit(node, "for") is not None:
                return self._handle_constexpr_for(node)
            with self.session_data.control_flow_policy(ControlFlowPolicy.TRACE):
                return self.visit_For(node)

        # A literal iterable settles the loop kind here, so its body is
        # transformed once. Only an iterable the rewrite cannot classify pays
        # for the trace-time dispatch and its two candidate bodies.
        literal_kind = self._literal_for_iter_kind(node.iter)
        if literal_kind == "range":
            return self._transform_staged_for(node)
        if literal_kind == "python":
            return self._transform_native_for(node)
        return self._transform_runtime_dispatched_for(node)

    @staticmethod
    def _hoist_expr_to_assignments(expr: ast.expr, name: str) -> ast.Assign:
        return ast.copy_location(
            ast.Assign(targets=[ast.Name(id=name, ctx=ast.Store())], value=expr), expr
        )

    def _build_select_and_assign(
        self,
        *,
        name: str,
        test: ast.expr,
        body: ast.expr,
        orelse: ast.expr,
        location: ast.AST,
    ) -> ast.Assign:
        node = ast.copy_location(
            ast.Assign(
                targets=[ast.Name(id=name, ctx=ast.Store())],
                value=ast.IfExp(
                    test=test,
                    body=body,
                    orelse=orelse,
                ),
            ),
            location,
        )
        return node

    def _handle_negative_step(
        self,
        node: ast.For,
        start_expr: ast.expr,
        stop_expr: ast.expr,
        step_expr: ast.expr,
    ) -> tuple[ast.Name, ast.Name, ast.Name, list[ast.stmt]]:
        # hoist start, stop, step to assignments
        start_ori_name = f"start_ori_{self.session_data.counter}"
        start = self._hoist_expr_to_assignments(start_expr, start_ori_name)
        stop_ori_name = f"stop_ori_{self.session_data.counter}"
        stop = self._hoist_expr_to_assignments(stop_expr, stop_ori_name)
        step_ori_name = f"step_ori_{self.session_data.counter}"
        step = self._hoist_expr_to_assignments(step_expr, step_ori_name)

        extra_exprs: list[ast.stmt] = [start, stop, step]

        # Handle possible negative step, generates the following code in Python:
        # isNegative = step < 0
        isNegative_name = f"isNegative_{self.session_data.counter}"
        isNegative = ast.copy_location(
            ast.Assign(
                targets=[ast.Name(id=isNegative_name, ctx=ast.Store())],
                value=ast.Compare(
                    left=ast.Name(id=step_ori_name, ctx=ast.Load()),
                    ops=[ast.Lt()],
                    comparators=[ast.Constant(value=0)],
                ),
            ),
            step,
        )

        # start = stop if isNegative else start
        start_name = f"start_{self.session_data.counter}"
        start = self._build_select_and_assign(
            name=start_name,
            test=ast.Name(id=isNegative_name, ctx=ast.Load()),
            body=ast.Name(id=stop_ori_name, ctx=ast.Load()),
            orelse=ast.Name(id=start_ori_name, ctx=ast.Load()),
            location=start,
        )

        # stop = start if isNegative else stop
        stop_name = f"stop_{self.session_data.counter}"
        stop = self._build_select_and_assign(
            name=stop_name,
            test=ast.Name(id=isNegative_name, ctx=ast.Load()),
            body=ast.Name(id=start_ori_name, ctx=ast.Load()),
            orelse=ast.Name(id=stop_ori_name, ctx=ast.Load()),
            location=stop,
        )

        # step = -step if isNegative else step
        step_name = f"step_{self.session_data.counter}"
        step = self._build_select_and_assign(
            name=step_name,
            test=ast.Name(id=isNegative_name, ctx=ast.Load()),
            body=ast.UnaryOp(
                op=ast.USub(), operand=ast.Name(id=step_ori_name, ctx=ast.Load())
            ),
            orelse=ast.Name(id=step_ori_name, ctx=ast.Load()),
            location=step,
        )

        # offset = start + stop if isNegative else 0
        offset_name = f"offset_{self.session_data.counter}"
        offset = self._build_select_and_assign(
            name=offset_name,
            test=ast.Name(id=isNegative_name, ctx=ast.Load()),
            body=ast.BinOp(
                op=ast.Add(),
                left=ast.Name(id=start_name, ctx=ast.Load()),
                right=ast.Name(id=stop_name, ctx=ast.Load()),
            ),
            orelse=ast.Constant(value=0),
            location=node,
        )

        with Region(self.session_data, new_value=extra_exprs):
            extra_exprs.append(self.generic_visit(isNegative))  # type: ignore[arg-type]
            extra_exprs.append(self.generic_visit(start))  # type: ignore[arg-type]
            extra_exprs.append(self.generic_visit(stop))  # type: ignore[arg-type]
            extra_exprs.append(self.generic_visit(step))  # type: ignore[arg-type]
            extra_exprs.append(self.generic_visit(offset))  # type: ignore[arg-type]

        # Add this to beginning of loop body
        # for i in range(start, stop, step):
        #     i = offset - i if isNegative else i
        # Mark the induction variable in skip_pyir_reference_taking so PyIR does NOT
        # instrument this assignment with pyir_read/pyir_assign.
        # Creating a pyir.ref for the scf.for block argument crashes
        # the convert-pyir-to-scf pass (circular use-def chain).
        assert isinstance(node.target, ast.Name)

        target_name = node.target.id

        if target_name != "_":
            # if target_name is _, skip the assign back
            target = self._build_select_and_assign(
                name=target_name,
                test=ast.Name(id=isNegative_name, ctx=ast.Load()),
                body=ast.BinOp(
                    op=ast.Sub(),
                    left=ast.Name(id=offset_name, ctx=ast.Load()),
                    right=ast.Name(id=target_name, ctx=ast.Load()),
                ),
                orelse=ast.Name(id=target_name, ctx=ast.Load()),
                location=node.target,
            )

            node.body.insert(0, target)

        return (
            ast.Name(id=start_name, ctx=ast.Load()),
            ast.Name(id=stop_name, ctx=ast.Load()),
            ast.Name(id=step_name, ctx=ast.Load()),
            extra_exprs,
        )

    def _create_closure_check_call(
        self, called_closures: list[str], node: ast.stmt
    ) -> ast.Expr | None:
        return ast.Expr(
            ast.Call(
                func=_create_module_attribute(
                    "closure_check",
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    ast.List(
                        elts=[ast.Name(id=c, ctx=ast.Load()) for c in called_closures],
                        ctx=ast.Load(),
                    )
                ],
                keywords=[],
            )
        )

    def _prepare_loop_induction_var(
        self,
        node: ast.For,
        target_is_live_after_loop: bool = False,
        loop_carried_var_name: str | None = None,
    ) -> None:
        """Prepare loop induction variable before function creation."""
        pass  # No preparation needed in base class

    def _cleanup_loop_induction_var(self, node: ast.For) -> None:
        """Cleanup loop induction variable after function creation.

        Override for custom behavior (e.g., restore normal handling).
        """
        pass  # No cleanup needed in base class

    def transform_for_loop(
        self,
        node: ast.For,
        active_symbols: list[set[str]],
        active_callables: list[set[str]],
    ) -> list[ast.stmt]:
        # Check for early exit and raise exception
        self.check_early_exit(node, "for")
        if node.orelse:
            raise DSLUserCodeError(
                DiagId.UNSUP_LOOP_ELSE,
                filename=self.session_data.file_name,
                lineno=node.lineno,
                col_offset=node.col_offset,
                end_col_offset=getattr(node.iter, "end_col_offset", None),
            )

        # Get loop target variable name
        target_var_name: str | None = None
        target_var_is_active_before_loop = False
        if isinstance(node.target, ast.Name):
            target_var_name = node.target.id
            for idx, active_symbol in enumerate(active_symbols):
                if target_var_name in active_symbol:
                    target_var_is_active_before_loop = True
                    active_symbols[idx] = active_symbol - {target_var_name}
                    break

        # Add necessary exprs to handle this
        if target_var_is_active_before_loop:
            assert target_var_name is not None
            loop_carried_var_name = f"loop_carried_var_{self.session_data.counter}"
            pre_loop_expr = ast.copy_location(
                ast.Assign(
                    targets=[ast.Name(id=loop_carried_var_name, ctx=ast.Store())],
                    value=ast.Name(id=target_var_name, ctx=ast.Load()),
                ),
                node,
            )
            # append an extra assignment to the loop carried variable
            node.body.append(
                ast.copy_location(
                    ast.Assign(
                        targets=[ast.Name(id=loop_carried_var_name, ctx=ast.Store())],
                        value=ast.Name(id=target_var_name, ctx=ast.Load()),
                    ),
                    node,
                )
            )
            active_symbols.append({loop_carried_var_name})

        assert isinstance(node.iter, ast.Call)
        start_expr, stop_expr, step_expr, has_step = self.extract_range_args(node.iter)
        # Template method: a derived class may instrument the bound expressions,
        # consumed at loop-selector call time outside the visited body.
        start_expr = self._prepare_loop_bound_expr(start_expr)
        stop_expr = self._prepare_loop_bound_expr(stop_expr)
        step_expr = self._prepare_loop_bound_expr(step_expr)
        unroll, unroll_full = self.extract_unroll_args(node.iter)
        prefetch_stages = self.extract_prefetch_stages_args(node.iter)
        vectorize = self.extract_vectorize_args(node.iter)
        at_least_once = self.extract_at_least_once_args(node.iter)
        write_args, full_write_args_count, called_closures = (
            self.analyze_region_variables(node, active_symbols, active_callables)
        )

        has_positive_step = (
            isinstance(step_expr, ast.Constant)
            and isinstance(step_expr.value, (int, float))
            and step_expr.value > 0
        )

        if (
            has_step
            and self.client_module_name[0] == "cutlass"
            and not has_positive_step
        ):
            start_n, stop_n, step_n, exprs = self._handle_negative_step(
                node, start_expr, stop_expr, step_expr
            )
            start: ast.expr = start_n
            stop: ast.expr = stop_n
            step: ast.expr = step_n
        else:
            start, stop, step = start_expr, stop_expr, step_expr
            exprs: list[ast.stmt] = []  # type: ignore[no-redef]

        if target_var_is_active_before_loop:
            exprs.append(pre_loop_expr)

        if called_closures:
            cc = self._create_closure_check_call(called_closures, node)
            if cc is not None:
                exprs.append(cc)

        func_name = f"loop_body_{self.session_data.counter}"
        self.session_data.counter += 1

        # Template method: prepare induction variable (e.g., mark for special
        # handling); passes the live-out signal + synthetic carry name.
        self._prepare_loop_induction_var(
            node,
            target_is_live_after_loop=target_var_is_active_before_loop,
            loop_carried_var_name=(
                loop_carried_var_name if target_var_is_active_before_loop else None
            ),
        )

        func_def = self.create_loop_function(
            func_name,
            node,
            start,
            stop,
            step,
            unroll,
            unroll_full,
            prefetch_stages,
            vectorize,
            at_least_once,
            write_args,
            full_write_args_count,
        )

        # Template method: cleanup induction variable handling
        self._cleanup_loop_induction_var(node)

        assign = self.create_cf_call(func_name, write_args, node)

        # This should work fine as it modifies the AST structure
        exprs = exprs + [func_def] + assign

        if target_var_is_active_before_loop:
            assert target_var_name is not None
            exprs.append(
                ast.copy_location(
                    ast.Assign(
                        targets=[ast.Name(id=target_var_name, ctx=ast.Store())],
                        value=ast.Name(id=loop_carried_var_name, ctx=ast.Load()),
                    ),
                    node,
                )
            )

        return exprs

    def visit_Assert(self, node: ast.Assert) -> ast.Expr:
        test = self.visit(node.test)

        args = [ast.keyword(arg="test", value=test)]
        if node.msg:
            msg = self.visit(node.msg)
            args.append(ast.keyword(arg="msg", value=msg))

        # Rewrite to assert_executor(test, msg)
        new_node = ast.Expr(
            ast.Call(
                func=_create_module_attribute(
                    self.ASSERT_EXECUTOR, lineno=node.lineno, col_offset=node.col_offset
                ),
                args=[],
                keywords=args,
            )
        )

        # Propagate line number from original node to new node
        ast.copy_location(new_node, node)
        return new_node

    def processFormattedValue(self, node: ast.FormattedValue) -> ast.Call:
        """
        Converts an ast.FormattedValue node into a runtime representation of an ast.FormattedValue.

        This function takes an ast.FormattedValue node and converts it into a runtime representation of ast.FormattedValue.
        """
        keywords: list[ast.keyword] = []
        if node.conversion != -1:
            keywords.append(
                ast.keyword(arg="conversion", value=ast.Constant(value=node.conversion))
            )
        # ``f"{n:}"`` carries an empty JoinedStr: Python formats it like a bare
        # ``{n}``, so no spec is passed.
        if isinstance(node.format_spec, ast.JoinedStr) and node.format_spec.values:
            keywords.append(
                ast.keyword(
                    arg="format_spec",
                    value=ast.List(elts=node.format_spec.values, ctx=ast.Load()),
                )
            )
        call = ast.Call(
            func=_create_module_attribute(
                "FormattedValue",
                lineno=node.lineno,
                col_offset=node.col_offset,
            ),
            args=[node.value],
            keywords=keywords,
        )
        return ast.copy_location(call, node)

    def processFString(self, node: ast.Call) -> ast.Call:
        """
        Converts an f-string node into a runtime representation of an f-string.

        This function takes an ast.JoinedStr node and converts it into a list of elements,
        where each element is either a literal string or a FormattedValue.
        The FormattedValue is converted into a runtime representation of ast.FormattedValue.
        """
        elements: list[ast.expr] = []
        joinedStr = node.args[0]
        assert isinstance(joinedStr, ast.JoinedStr)
        for component in joinedStr.values:
            if isinstance(component, ast.Constant):
                elements.append(component)
            elif isinstance(component, ast.FormattedValue):
                elements.append(self.processFormattedValue(component))
            else:
                raise DSLUserCodeError(
                    DiagId.UNSUP_FSTRING,
                    filename=self.session_data.file_name,
                    lineno=getattr(component, "lineno", None),
                )
        call = ast.Call(
            func=_create_module_attribute(
                "fstring_decompose",
                lineno=node.lineno,
                col_offset=node.col_offset,
            ),
            args=[ast.copy_location(ast.List(elts=elements, ctx=ast.Load()), node)],
            keywords=[],
        )
        return ast.copy_location(call, node)

    def _try_rewrite_printf_fstring(self, node: ast.Call, name: str) -> bool:
        """Rewrite a printf/print_runtime f-string call in place; return whether done.

        When ``name`` (the callee's ``id`` for a Name callee or ``attr`` for an
        Attribute callee) is printf/print_runtime and the first arg is an f-string,
        replace that arg with a starred processFString expansion; any further
        positional args stay behind it so the callee sees (and counts) them.
        Shared by the Name and Attribute branches of visit_Call.
        """
        if (
            name in ("printf", "print_runtime")
            and len(node.args) > 0
            and isinstance(node.args[0], ast.JoinedStr)
        ):
            node.args = [
                ast.Starred(value=self.processFString(node), ctx=ast.Load())
            ] + node.args[1:]
            return True
        return False

    def visit_Call(self, node: ast.Call) -> ast.Call:
        # The callee expression is visited ONCE and the result is what the call
        # keeps.  Every rewrite below reads `func`, and none of them may reach
        # `node.func` again: visiting an already-transformed callee re-runs the
        # non-idempotent lowerings inside it (ternary blocks, and/or expansion,
        # walrus hoists), which for a chained call -- `f(...).g(...)`, whose
        # callee is an Attribute over the receiver Call -- walks the receiver's
        # whole argument list a second time.
        # Judge the callee's spelling on the SOURCE node: a callee rewrite below
        # may replace the `const_expr` Name/Attribute the predicate looks at.
        declares_const_expr = self.is_const_expr_call(node)
        func = self.visit(node.func)
        node.func = func
        # Visit args and kwargs.  ``const_expr(...)`` declares its whole
        # argument expression a trace-time constant, so the visit runs under
        # that declaration (see ``const_expr_arguments``).
        with (
            self.session_data.const_expr_arguments()
            if declares_const_expr
            else contextlib.nullcontext()
        ):
            node.args = [self.visit(arg) for arg in node.args]
            node.keywords = [self.visit(kwarg) for kwarg in node.keywords]

        # Track whether a special-case rewrite already handled this call
        already_rewritten = False

        # Rewrite call to some built-in functions
        if isinstance(func, ast.Name):
            # AST rewrite only redirect call to bool to bool_cast
            # If `bool` escapes as a symbol, usually it means type check, do not rewrite it
            # Any other call shape has no `bool_cast` spelling, so it is left as a
            # plain `bool` call for Python itself to accept or reject
            if (
                func.id == "bool"
                and len(node.args) == 1
                and node.keywords == []
                and not isinstance(node.args[0], ast.Starred)
            ):
                redirected = ast.copy_location(
                    ast.Call(
                        func=ast.Call(
                            func=_create_module_attribute(
                                self.BUILTIN_REDIRECTOR,
                                lineno=node.lineno,
                                col_offset=node.col_offset,
                            ),
                            args=[func],
                            keywords=[],
                        ),
                        args=[node.args[0]],
                        keywords=[],
                    ),
                    node,
                )
                # Machinery application of the redirector's result: the outer
                # call is not a user call, so the boundary pass skips it.
                redirected._pyir_synth = True  # type: ignore[attr-defined]
                return redirected
            elif func.id == "super" and node.args == [] and node.keywords == []:
                # Spell out super()'s implicit arguments.  The rewritten code object
                # runs on the original function, whose closure still holds the
                # lexical class in its __class__ cell, so read the class by name.
                return ast.copy_location(
                    ast.Call(
                        func=func,
                        args=node.args
                        + [
                            ast.Name(id="__class__", ctx=ast.Load()),
                            ast.Name(id="self", ctx=ast.Load()),
                        ],
                        keywords=node.keywords,
                    ),
                    node,
                )
            elif self._try_rewrite_printf_fstring(node, func.id):
                already_rewritten = True
        elif isinstance(func, ast.Attribute) and isinstance(func.value, ast.Name):
            if self._try_rewrite_printf_fstring(node, func.attr):
                already_rewritten = True
            else:

                def create_downcast_call(arg: ast.expr) -> ast.Call:
                    return ast.copy_location(
                        ast.Call(
                            func=_create_module_attribute(
                                self.IMPLICIT_DOWNCAST_NUMERIC_TYPE,
                                submodule_name="typing",
                                lineno=node.lineno,
                                col_offset=node.col_offset,
                            ),
                            args=[arg],
                            keywords=[],
                        ),
                        arg,
                    )

                fn_globals = self.session_data.function_globals
                module = fn_globals.get(func.value.id) if fn_globals else None
                if isinstance(module, ModuleType) and (
                    module.__package__ or ""
                ).endswith("._mlir.dialects"):
                    # Check if argument is Numeric, if so, call ir_value()
                    args: list[ast.expr] = []
                    for arg in node.args:
                        args.append(create_downcast_call(arg))
                    kwargs: list[ast.keyword] = []
                    for kwarg in node.keywords:
                        kwargs.append(
                            ast.copy_location(
                                ast.keyword(
                                    arg=kwarg.arg,
                                    value=create_downcast_call(kwarg.value),
                                ),
                                kwarg,
                            )
                        )
                    return ast.copy_location(
                        ast.Call(func=func, args=args, keywords=kwargs), node
                    )
        # No `else` arm: a callee that is neither a Name nor an Attribute over a
        # Name needs no rewrite here, and it is already visited and stored above.

        return node

    def visit_ClassDef(self, node: ast.ClassDef) -> ast.AST:
        with self.session_data.set_current_class_name(node.name):
            return self.generic_visit(node)

    def _visit_target(self, target: ast.expr) -> None:
        if isinstance(target, ast.Name):
            self.session_data.scope_manager.add_to_scope(target.id)
        elif isinstance(target, ast.Tuple):
            for t in target.elts:
                if isinstance(t, ast.Name):
                    self.session_data.scope_manager.add_to_scope(t.id)

    def visit_Assign(self, node: ast.Assign) -> ast.stmt | list[ast.stmt]:
        for target in node.targets:
            self._visit_target(target)
        self.generic_visit(node)
        return node

    def visit_AugAssign(self, node: ast.AugAssign) -> ast.AugAssign | list[ast.stmt]:
        self._visit_target(node.target)
        self.generic_visit(node)
        return node

    def visit_AnnAssign(self, node: ast.AnnAssign) -> "ast.stmt | list[ast.stmt]":
        self._visit_target(node.target)
        self.generic_visit(node)
        return node

    def visit_Name(self, node: ast.Name) -> ast.Name | ast.Call:
        isLoad = isinstance(node.ctx, ast.Load)
        if node.id in ["max", "min", "any", "all", "exec", "eval"] and isLoad:
            return ast.copy_location(
                ast.Call(
                    func=_create_module_attribute(
                        self.BUILTIN_REDIRECTOR,
                        lineno=node.lineno,
                        col_offset=node.col_offset,
                    ),
                    args=[node],
                    keywords=[],
                ),
                node,
            )
        elif node.id == "_" and isLoad:
            raise DSLUserCodeError(
                DiagId.UNSUP_READ_UNDERSCORE,
                filename=self.session_data.file_name,
                lineno=getattr(node, "lineno", None),
                col_offset=getattr(node, "col_offset", None),
                end_col_offset=getattr(node, "end_col_offset", None),
            )
        else:
            self.generic_visit(node)
        return node

    def get_dsl_decorator_index(self, decorator_list: list[ast.expr]) -> Any:
        # Known decorator kwargs that should not prevent decorator recognition.
        # "preprocess" controls whether AST preprocessing is enabled.
        # "attributes" passes kernel function attributes (e.g. launch bounds)
        # to the compiler — its presence shouldn't prevent the preprocessor
        # from recognizing @cute.kernel(attributes=...) as a DSL decorator.
        _known_dsl_kwargs = {
            "preprocess",
            "attributes",
        }

        for i, d in enumerate(decorator_list):
            if isinstance(d, ast.Call):
                if isinstance(d.func, ast.Attribute):
                    if d.func.attr in ["jit", "kernel"]:
                        if d.keywords == []:
                            return i

                        # Check if all keywords are known DSL kwargs
                        all_known = all(
                            keyword.arg in _known_dsl_kwargs for keyword in d.keywords
                        )
                        if all_known:
                            # Check if 'preprocess' is explicitly set
                            for keyword in d.keywords:
                                if keyword.arg == "preprocess":
                                    try:
                                        if isinstance(keyword.value, ast.Constant):
                                            return keyword.value.value
                                        else:
                                            return ast.literal_eval(keyword.value)
                                    except (ValueError, TypeError, SyntaxError):
                                        # ast.literal_eval fails for non-literal
                                        # expressions — treat as unknown.
                                        pass
                            # No 'preprocess' kwarg, but all kwargs are known — accept
                            return i

                        keyword_names = {
                            keyword.arg
                            for keyword in d.keywords
                            if keyword.arg is not None
                        }

                        # New behavior for kernel function attributes.
                        # Limit this expansion to kernel decorator with
                        # an explicit `attributes=` keyword.
                        if d.func.attr == "kernel" and "attributes" in keyword_names:
                            return i

            elif isinstance(d, ast.Attribute):
                if d.attr in ["jit", "kernel"]:
                    return i
        return None

    def check_decorator(self, node: ast.AST) -> bool:
        """
        Check if the function has the correct decorator for preprocessing.
        """
        if not isinstance(node, ast.FunctionDef):
            return False
        decorator_list = node.decorator_list
        if len(decorator_list) == 0:
            return False

        dsl_decorator_index = self.get_dsl_decorator_index(decorator_list)

        if (
            dsl_decorator_index is not None
            and dsl_decorator_index < len(decorator_list) - 1
        ):
            decorator = ast.unparse(decorator_list[dsl_decorator_index])
            raise DSLUserCodeError(
                DiagId.UNSUP_DECORATOR_ORDER,
                filename=self.session_data.file_name,
                decorator=decorator,
            )

        return dsl_decorator_index is not None

    def remove_dsl_decorator(self, decorator_list: list[ast.expr]) -> list[ast.expr]:
        """
        Remove .jit and .kernel decorators
        The decorator can be in two forms:
        - @jit(...)
        - @jit
        """
        new_decorator_list = []
        decorator_names = ["jit", "kernel"]
        for d in decorator_list:
            is_jit_or_kernel = False
            if isinstance(d, ast.Call):
                if isinstance(d.func, ast.Attribute):
                    if d.func.attr in decorator_names:
                        is_jit_or_kernel = True
            elif isinstance(d, ast.Attribute):
                if d.attr in decorator_names:
                    is_jit_or_kernel = True

            if not is_jit_or_kernel:
                new_decorator_list.append(d)
        return new_decorator_list

    def visit_Global(self, node: ast.Global) -> None:
        raise DSLUserCodeError(
            DiagId.UNSUP_GLOBAL,
            filename=self.session_data.file_name,
            lineno=getattr(node, "lineno", None),
            col_offset=getattr(node, "col_offset", None),
            end_col_offset=getattr(node, "end_col_offset", None),
        )

    def visit_Nonlocal(self, node: ast.Nonlocal) -> ast.Nonlocal:
        active_symbols = self.session_data.scope_manager.get_active_symbols()
        nonlocal_names = OrderedSet(node.names)
        intersect = nonlocal_names.intersections(active_symbols)
        for name in node.names:
            if name not in intersect:
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

    @staticmethod
    def _insert_captured_writeback_nonlocals(
        node: ast.FunctionDef,
        captured_names: set[str],
    ) -> None:
        """Declare captured names written back by outlined control flow.

        Without this declaration, a generated ``captured = region(...)``
        classifies ``captured`` as a local in the nested function and makes a
        preceding closure read fail. ``nonlocal`` keeps the writeback on the
        original closure cell while still carrying the SSA value across the
        outlined region.
        """
        if not captured_names:
            return

        existing_names = {
            name
            for statement in node.body
            if isinstance(statement, ast.Nonlocal)
            for name in statement.names
        }
        names_to_declare = sorted(captured_names - existing_names)
        if not names_to_declare:
            return

        declaration = ast.copy_location(ast.Nonlocal(names=names_to_declare), node)
        insert_at = 1 if ast.get_docstring(node, clean=False) is not None else 0
        node.body.insert(insert_at, declaration)

    def visit_FunctionDef(
        self, node: ast.FunctionDef
    ) -> "ast.FunctionDef | list[ast.stmt]":
        # Add self to active symbols of parent scope
        self.session_data.scope_manager.add_to_callables(node.name)

        with (
            self.session_data.scope_manager.enter_local_scope(),
            self.session_data.set_current_function_name(node.name),
            self.session_data.collect_captured_control_flow_writebacks() as writebacks,
        ):
            # Keep recursive calls visible as callables without pretending the
            # function name is an initialized body local. Python does not bind
            # that local, so seeding the variable scope would turn a first
            # same-spelling assignment into a read-before-write reassignment.
            self.session_data.scope_manager.add_to_callables(node.name)

            for arg in node.args.args:
                self.session_data.scope_manager.add_to_scope(arg.arg)
                arg.annotation = None

            for arg in node.args.kwonlyargs:
                self.session_data.scope_manager.add_to_scope(arg.arg)
                arg.annotation = None

            for arg in node.args.posonlyargs:
                self.session_data.scope_manager.add_to_scope(arg.arg)
                arg.annotation = None

            # Strip return annotation
            node.returns = None

            self.generic_visit(node)

        # Remove .jit and .kernel decorators
        node.decorator_list = self.remove_dsl_decorator(node.decorator_list)
        self._insert_captured_writeback_nonlocals(node, writebacks)

        return node

    def visit_With(self, node: ast.With) -> ast.AST:
        for item in node.items:
            if isinstance(item.optional_vars, ast.Name):
                self.session_data.scope_manager.add_to_scope(item.optional_vars.id)
        return self.generic_visit(node)

    def _handle_constexpr_test(self, node: ast.stmt) -> list[ast.stmt]:
        """Insert a cf-symbol check before a const_expr if/while node.

        Both nodes expose a ``.test`` that must be a Call; shared by
        _handle_constexpr_if and _handle_constexpr_while.
        """
        self.generic_visit(node)
        assert isinstance(node.test, ast.Call)  # type: ignore[attr-defined]
        check = self._insert_cf_symbol_check(node.test.func)  # type: ignore[attr-defined]
        return [check, node]

    def _handle_constexpr_while(self, node: ast.While) -> list[ast.stmt]:
        """Handle const_expr while statements. Override for custom behavior."""
        return self._handle_constexpr_test(node)

    def visit_While(self, node: ast.While) -> ast.While | list[ast.stmt]:
        if self.session_data.current_control_flow_policy is ControlFlowPolicy.NATIVE:
            if self._find_early_exit(node, "while") is not None:
                visited = self.generic_visit(node)
                assert isinstance(visited, ast.While)
                return visited
            with self.session_data.control_flow_policy(ControlFlowPolicy.TRACE):
                return self.visit_While(node)
        # Constexpr doesn't get preprocessed
        if self.is_node_constexpr(node):
            return self._handle_constexpr_while(node)

        # A staged ``while ... else:`` cannot capture its else-clause (parity with
        # the staged ``for ... else`` rejection below).
        if node.orelse:
            raise DSLUserCodeError(
                DiagId.UNSUP_LOOP_ELSE,
                filename=self.session_data.file_name,
                lineno=node.lineno,
                col_offset=node.col_offset,
                end_col_offset=getattr(node.test, "end_col_offset", None),
            )

        active_symbols = self.session_data.scope_manager.get_active_symbols()
        active_callables = self.session_data.scope_manager.get_active_callables()

        with self.session_data.scope_manager.enter_control_flow_scope():
            self.check_early_exit(node, "while")

            write_args, full_write_args_count, called_closures = (
                self.analyze_region_variables(node, active_symbols, active_callables)
            )
            # The region analysis keeps only names bound before the loop; a
            # name the condition itself binds with ``:=`` is bound on every
            # path into the body and after the loop (Python semantics).
            condition_bound = [
                name
                for name in _while_condition_bound_names(node.test)
                if name not in write_args
            ]
            if condition_bound:
                write_args, full_write_args_count = (
                    self._adopt_while_condition_bound_names(
                        node, condition_bound, write_args, full_write_args_count
                    )
                )
            exprs = []
            if called_closures:
                cc = self._create_closure_check_call(called_closures, node)
                if cc is not None:
                    exprs.append(cc)

            func_name = f"while_region_{self.session_data.counter}"
            self.session_data.counter += 1

            func_def = self.create_while_function(
                func_name, node, write_args, full_write_args_count
            )
            assign = self.create_cf_call(func_name, write_args, node)

        return exprs + [func_def] + assign

    def create_cf_call(
        self, func_name: str, yield_args: list[str], node: ast.stmt
    ) -> list[ast.stmt]:
        """Create result writeback for a rewritten control-flow region."""
        if not yield_args:
            return [
                ast.copy_location(
                    ast.Expr(value=ast.Name(id=func_name, ctx=ast.Load())), node
                )
            ]
        for name in yield_args:
            scopes = self.session_data.scope_manager
            if not scopes.current_function_owns(
                name
            ) and scopes.enclosing_function_owns(name):
                self.session_data.record_captured_control_flow_writeback(name)
        has_self = False
        for i, arg in enumerate(yield_args):
            if arg == "self":
                has_self = True
                yield_args[i] = "yield_self"
                break
        if len(yield_args) == 1:
            assign = ast.Assign(
                targets=[ast.Name(id=yield_args[0], ctx=ast.Store())],
                value=ast.Name(id=func_name, ctx=ast.Load()),
            )
        else:
            assign = ast.Assign(
                targets=[
                    ast.Tuple(
                        elts=[ast.Name(id=var, ctx=ast.Store()) for var in yield_args],
                        ctx=ast.Store(),
                    )
                ],
                value=ast.Name(id=func_name, ctx=ast.Load()),
            )

        if has_self:
            fix_self = ast.Expr(
                value=ast.Call(
                    func=_create_module_attribute(
                        "copy_members", lineno=node.lineno, col_offset=node.col_offset
                    ),
                    args=[
                        ast.Name(id="self", ctx=ast.Load()),
                        ast.Name(id="yield_self", ctx=ast.Load()),
                    ],
                    keywords=[],
                )
            )
            return [ast.copy_location(assign, node), ast.copy_location(fix_self, node)]
        else:
            return [ast.copy_location(assign, node)]

    def _visit_Comprehension(
        self, node: _ComprehensionT, ele_visitor: Callable[..., Any]
    ) -> _ComprehensionT:
        node.generators = [self.visit(generator) for generator in node.generators]
        # The filter runs in Python while the comprehension is built: a
        # runtime condition is refused as a built-in's truth test would be.
        for generator in node.generators:
            generator.ifs = [
                self._wrap_truth_guard(test, self.COMPREHENSION_CONDITION)
                for test in generator.ifs
            ]

        targets: list[str] = []

        class NameCollector(ast.NodeVisitor):
            def visit_Name(self, node: ast.Name) -> None:
                if isinstance(node.ctx, ast.Store):
                    targets.append(node.id)

        # Collect generator targets
        collector = NameCollector()
        [collector.visit(generator) for generator in node.generators]

        self.session_data.generator_targets = targets

        ele_visitor(node)

        self.session_data.generator_targets = []
        return node

    def visit_DictComp(self, node: ast.DictComp) -> ast.DictComp:
        def key_value_visitor(n: ast.DictComp) -> None:
            n.key = self.visit(n.key)
            n.value = self.visit(n.value)

        return self._visit_Comprehension(node, key_value_visitor)

    def visit_Lambda(self, node: ast.Lambda) -> ast.Lambda:
        current_lambda_args = len(self.session_data.lambda_args)
        for arg in node.args.args:
            self.session_data.lambda_args.append(arg.arg)

        # The body runs when the lambda is CALLED, not where it is written, so
        # an enclosing ``const_expr(...)`` declaration does not reach into it.
        with self.session_data.deferred_body():
            node.body = self.visit(node.body)

        self.session_data.lambda_args = self.session_data.lambda_args[
            :current_lambda_args
        ]

        return node

    def visit_ListComp(self, node: ast.ListComp) -> ast.ListComp:
        return self._visit_Comprehension(
            node, lambda n: setattr(n, "elt", self.visit(n.elt))
        )

    def visit_GeneratorExp(self, node: ast.GeneratorExp) -> ast.GeneratorExp:
        return self._visit_Comprehension(
            node, lambda n: setattr(n, "elt", self.visit(n.elt))
        )

    def visit_SetComp(self, node: ast.SetComp) -> ast.SetComp:
        return self._visit_Comprehension(
            node, lambda n: setattr(n, "elt", self.visit(n.elt))
        )

    def visit_IfExp(self, node: ast.IfExp) -> ast.Call:
        """
        Transforms an inline if-else (ternary) expression into runtime-dispatched
        control flow using synthesized function definitions for each branch.

        This converts an expression of the form ``x if cond else y`` into two local
        function blocks (for the ``then`` and ``else`` branches), inserts those blocks
        just before the current statement, and produces a call to the conditional executor.

        This lets the DSL infrastructure analyze and dispatch dynamic inline conditionals
        in a uniform way at runtime.

        Parameters
        ----------
        node : ast.IfExp
            The AST node representing the inline if-else expression.

        Returns
        -------
        ast.Call
            An AST node that calls the conditional expression executor, referencing
            the synthesized blocks and the predicate.
        """
        # Create unique names for the then and else branch function blocks
        then_block_name = f"ifexp_then_block_{self.session_data.counter}"
        else_block_name = f"ifexp_else_block_{self.session_data.counter}"
        self.session_data.counter += 1

        # Define the then-block function, with no arguments and returning the visited body
        then_block_def = ast.FunctionDef(
            name=then_block_name,
            args=ast.arguments(
                posonlyargs=[],
                args=[
                    ast.arg(arg=target, annotation=None)
                    for target in chain(
                        self.session_data.generator_targets,
                        self.session_data.lambda_args,
                    )
                ],
                kwonlyargs=[],
                kw_defaults=[],
                defaults=[],
            ),
            body=[ast.Return(value=self.visit(node.body))],
            decorator_list=[],
        )
        # Define the else-block function, with no arguments and returning the visited orelse
        else_block_def = ast.FunctionDef(
            name=else_block_name,
            args=ast.arguments(
                posonlyargs=[],
                args=[
                    ast.arg(arg=target, annotation=None)
                    for target in chain(
                        self.session_data.generator_targets,
                        self.session_data.lambda_args,
                    )
                ],
                kwonlyargs=[],
                kw_defaults=[],
                defaults=[],
            ),
            body=[ast.Return(value=self.visit(node.orelse))],
            decorator_list=[],
        )

        # Insert the block definitions into the most recent (innermost) region before the statement
        self.session_data.region_stack[-1].append_new_stmts(
            [
                _mark_synth_scope(then_block_def, node),
                _mark_synth_scope(else_block_def, node),
            ]
        )

        # Create the executor call node, wiring up the predicate and newly synthesized blocks
        executor_call = ast.Call(
            func=_create_module_attribute(self.IFEXP_EXECUTOR),
            args=[],
            keywords=[
                ast.keyword(arg="pred", value=self.visit(node.test)),
                ast.keyword(
                    arg="block_args",
                    value=ast.Tuple(
                        elts=[
                            ast.Name(id=name, ctx=ast.Load())
                            for name in chain(
                                self.session_data.generator_targets,
                                self.session_data.lambda_args,
                            )
                        ],
                        ctx=ast.Load(),
                    ),
                ),
                ast.keyword(
                    arg="then_block", value=ast.Name(id=then_block_name, ctx=ast.Load())
                ),
                ast.keyword(
                    arg="else_block", value=ast.Name(id=else_block_name, ctx=ast.Load())
                ),
            ],
        )

        # Return the transformed executor call node at the original location in the AST
        return ast.copy_location(executor_call, node)

    cmpops = {
        "Eq": "==",
        "NotEq": "!=",
        "Lt": "<",
        "LtE": "<=",
        "Gt": ">",
        "GtE": ">=",
        "Is": "is",
        "IsNot": "is not",
        "In": "in",
        "NotIn": "not in",
    }

    def compare_ops_to_str(self, node: ast.Compare) -> ast.List:
        names: list[ast.expr] = [
            ast.Constant(value=self.cmpops[op.__class__.__name__]) for op in node.ops
        ]
        return ast.List(elts=names, ctx=ast.Load())

    def visit_Compare(self, node: ast.Compare) -> ast.Call:
        self.generic_visit(node)

        comparator_strs = self.compare_ops_to_str(node)

        keywords = [
            ast.keyword(arg="left", value=node.left),
            ast.keyword(
                arg="comparators", value=ast.List(elts=node.comparators, ctx=ast.Load())
            ),
            ast.keyword(arg="ops", value=comparator_strs),
        ]
        if self.session_data.inside_const_expr_argument:
            # Inside ``const_expr(...)`` the operands are declared trace-time
            # constants, so an identity leg compares the declared PAYLOADS.
            keywords.append(
                ast.keyword(arg="const_expr", value=ast.Constant(value=True))
            )

        call = ast.copy_location(
            ast.Call(
                func=_create_module_attribute(self.COMPARE_EXECUTOR),
                args=[],
                keywords=keywords,
            ),
            node,
        )

        return call

    def _handle_constexpr_if(self, node: ast.If) -> list[ast.stmt]:
        """Handle const_expr if statements. Override for custom behavior."""
        self._visit_constexpr_if_branches(node)
        assert isinstance(node.test, ast.Call)
        check = self._insert_cf_symbol_check(node.test.func)
        return [check, node]

    def _handle_loop_exit_if(self, node: ast.If) -> ast.If:
        """Keep an ``if`` that owns a ``break``/``continue`` as native Python.

        Scoped like a const_expr ``if`` -- only one arm runs at trace time --
        without its symbol check. Override for custom behavior.
        """
        self._visit_constexpr_if_branches(node)
        return node

    def _visit_constexpr_branch(
        self, stmts: list[ast.stmt]
    ) -> tuple[list[ast.stmt], set[str]]:
        """Visit one constexpr branch without leaking its local definitions."""
        result: list[ast.stmt] = []
        with (
            Region(self.session_data, new_value=result),
            self.session_data.scope_manager.enter_control_flow_scope(),
        ):
            self._visit_stmts_into(stmts, result)
            definitions = set(self.session_data.scope_manager.scopes[-1])
        return result, definitions

    def _visit_constexpr_if_branches(self, node: ast.If) -> None:
        """Visit constexpr arms without exposing definitions to sibling arms."""
        visited_test = self.visit(node.test)
        assert isinstance(visited_test, ast.expr)
        node.test = visited_test

        node.body, body_definitions = self._visit_constexpr_branch(node.body)
        node.orelse, else_definitions = self._visit_constexpr_branch(node.orelse)
        # Publish branch definitions only after both arms have been visited. This
        # preserves Python's function-local name tracking (including possibly
        # unbound names handled by get_locals_or_none) without making a name from
        # one compile-time arm appear initialized while visiting its sibling.
        for name in body_definitions | else_definitions:
            self.session_data.scope_manager.add_to_scope(name)

    def _visit_runtime_dispatch(
        self,
        node: ast.If,
    ) -> None:
        """Visit the dispatch test without leaking for-local definitions.

        A staged for only carries names that were bound before the loop. Names
        first assigned in either dispatch arm remain internal to that arm and
        are intentionally unavailable to later staged control flow.
        """
        visited_test = self.visit(node.test)
        assert isinstance(visited_test, ast.expr)
        node.test = visited_test

    def _wrap_truth_guard(
        self, test: ast.expr, func_name: str, *consts: str
    ) -> ast.Call:
        """``ast_helpers.<func_name>(test, *consts)``: a pure predicate run just
        before Python truth-tests *test* itself, refusing a runtime condition
        with a diagnostic naming the construct."""
        return ast.copy_location(
            ast.Call(
                func=_create_module_attribute(func_name),
                args=[test, *(ast.Constant(value=c) for c in consts)],
                keywords=[],
            ),
            test,
        )

    def visit_If(self, node: ast.If) -> ast.If | list[ast.stmt]:
        if self.session_data.current_control_flow_policy is ControlFlowPolicy.NATIVE:
            # The native policy is entered only while visiting the Python arm
            # of a runtime-dispatched ``for``.  Keep an ``if`` native when
            # outlining it would detach an early exit from that loop/function;
            # ordinary nested conditions must still be staged.
            early_exit = self._find_early_exit(node, "for")
            if early_exit is not None:
                # Python truth-tests this condition at trace time: a runtime
                # value there gets the construct's own diagnostic.
                guard = not self.is_node_constexpr(node) and not isinstance(
                    node.test, ast.Constant
                )
                visited = self.generic_visit(node)
                assert isinstance(visited, ast.If)
                if guard:
                    visited.test = self._wrap_truth_guard(
                        visited.test, self.NATIVE_EXIT_GUARD, early_exit[1]
                    )
                return visited
            with self.session_data.control_flow_policy(ControlFlowPolicy.TRACE):
                return self.visit_If(node)
        # const_expr doesn't get preprocessed
        if self.is_node_constexpr(node):
            return self._handle_constexpr_if(node)

        # A ``break``/``continue`` owned by this ``if`` targets a trace-time
        # loop: a staged loop refuses early exits before visiting its body
        # and Python rejects a loop exit outside a loop. Outlining the arm
        # would detach the exit from that loop, so the ``if`` stays native:
        # a Meta predicate follows Python and a Staged one is refused by
        # ``Numeric.__bool__``.
        if self._find_early_exit(node, "for", self._LOOP_EXIT_TYPES) is not None:
            return self._handle_loop_exit_if(node)

        active_symbols = self.session_data.scope_manager.get_active_symbols()
        active_callables = self.session_data.scope_manager.get_active_callables()

        with self.session_data.scope_manager.enter_control_flow_scope():
            self.check_early_exit(node, "if")

            yield_args, full_write_args_count, called_closures = (
                self.analyze_region_variables(node, active_symbols, active_callables)
            )
            exprs = []
            if called_closures:
                cc = self._create_closure_check_call(called_closures, node)
                if cc is not None:
                    exprs.append(cc)

            func_name = f"if_region_{self.session_data.counter}"
            self.session_data.counter += 1

            func_def = self.create_if_function(
                func_name, node, yield_args, full_write_args_count
            )
            assign = self.create_cf_call(func_name, yield_args, node)

        return exprs + [func_def] + assign

    def generate_get_locals_or_none_call(self, write_args: list[str]) -> ast.Call:
        # The inner ``locals()`` is threading plumbing, not a user frame
        # reflection: mark it so the call-boundary pass leaves it bare.
        plumbing_locals = ast.Call(
            func=ast.Name(id="locals", ctx=ast.Load()), args=[], keywords=[]
        )
        plumbing_locals._pyir_synth = True  # type: ignore[attr-defined]
        return ast.Call(
            func=_create_module_attribute("get_locals_or_none"),
            args=[
                plumbing_locals,
                ast.List(
                    elts=[ast.Constant(value=arg) for arg in write_args],
                    ctx=ast.Load(),
                ),
            ],
            keywords=[],
        )

    def _handle_constexpr_elif(self, elif_node: ast.If) -> ast.stmt:
        """Handle const_expr elif nodes. Override for custom behavior.

        Returns the check statement for the const_expr call.
        """
        self._visit_constexpr_if_branches(elif_node)
        assert isinstance(elif_node.test, ast.Call)
        return self._insert_cf_symbol_check(elif_node.test.func)

    def create_if_function(
        self,
        func_name: str,
        node: ast.If,
        write_args: list[str],
        full_write_args_count: int,
    ) -> ast.FunctionDef:
        test_expr = self.visit(node.test)
        pred_name = self.make_func_param_name("pred", write_args)
        func_args = [ast.arg(arg=pred_name, annotation=None)]
        func_args += [ast.arg(arg=var, annotation=None) for var in write_args]
        func_args_then_else = [ast.arg(arg=var, annotation=None) for var in write_args]

        then_body: list[ast.stmt] = []
        with (
            Region(self.session_data, new_value=then_body),
            self.session_data.scope_manager.enter_control_flow_scope(),
        ):
            self._visit_stmts_into(node.body, then_body)

        # Create common return list for all blocks
        return_list = ast.List(
            elts=[ast.Name(id=var, ctx=ast.Load()) for var in write_args],
            ctx=ast.Load(),
        )

        # Create common function arguments
        func_decorator_arguments = ast.arguments(
            posonlyargs=[], args=func_args, kwonlyargs=[], kw_defaults=[], defaults=[]
        )
        func_then_else_arguments = ast.arguments(
            posonlyargs=[],
            args=func_args_then_else,
            kwonlyargs=[],
            kw_defaults=[],
            defaults=[],
        )

        then_block_name = f"then_block_{self.session_data.counter}"
        else_block_name = f"else_block_{self.session_data.counter}"
        elif_region_name = f"elif_region_{self.session_data.counter}"
        self.session_data.counter += 1

        # Create then block
        then_block = _mark_synth_scope(
            ast.FunctionDef(
                name=then_block_name,
                args=func_then_else_arguments,
                body=then_body + [ast.Return(value=return_list)],
                decorator_list=[],
            ),
            node,
        )

        # Decorator keywords
        decorator_keywords = [
            ast.keyword(
                arg="pred", value=test_expr
            ),  # ast.Name(id="pred", ctx=ast.Load())
            ast.keyword(
                arg="write_args",
                value=self.generate_get_locals_or_none_call(write_args),
            ),
        ]

        # Create decorator
        decorator = ast.copy_location(
            ast.Call(
                func=_create_module_attribute(
                    self.DECORATOR_IF_STATEMENT,
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[],
                keywords=decorator_keywords,
            ),
            node,
        )

        # Executor keywords
        execute_keywords = [
            ast.keyword(arg="pred", value=ast.Name(id=pred_name, ctx=ast.Load())),
            ast.keyword(
                arg="write_args",
                value=ast.List(
                    elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in write_args],
                    ctx=ast.Load(),
                ),
            ),
            ast.keyword(
                arg="full_write_args_count",
                value=ast.Constant(value=full_write_args_count),
            ),
            ast.keyword(
                arg="write_args_names",
                value=ast.List(
                    elts=[ast.Constant(value=arg) for arg in write_args],
                    ctx=ast.Load(),
                ),
            ),
            ast.keyword(
                arg="then_block", value=ast.Name(id=then_block_name, ctx=ast.Load())
            ),
        ]
        # Handle different cases
        if not write_args and node.orelse == []:
            # No write_args case - only then_block needed
            execute_call = ast.copy_location(
                ast.Call(
                    func=_create_module_attribute(
                        self.IF_EXECUTOR, lineno=node.lineno, col_offset=node.col_offset
                    ),
                    args=[],
                    keywords=execute_keywords,
                ),
                node,
            )
            func_body = [then_block, ast.Return(value=execute_call)]
        else:
            # Create else block based on node.orelse
            if node.orelse:
                if len(node.orelse) == 1 and isinstance(node.orelse[0], ast.If):
                    # Handle elif case
                    elif_node = node.orelse[0]
                    nested_if_name = elif_region_name
                    # AST cannot distinguish between the following two cases:
                    #     elif pred:
                    # and
                    #     else:
                    #         if pred:
                    # And under both cases, the `pred` can be a const_expr, so we need to handle it here.
                    # Statements hoisted while visiting the elif test (walrus
                    # lowering, read/effect anchors) must execute only when
                    # every earlier arm's condition is false: collect them
                    # into the synthesized else block, not the region
                    # enclosing the whole if.
                    elif_pre: list[ast.stmt] = []
                    if self.is_node_constexpr(elif_node):
                        with Region(self.session_data, new_value=elif_pre):
                            check = self._handle_constexpr_elif(elif_node)
                        else_block = ast.FunctionDef(
                            name=else_block_name,
                            args=func_then_else_arguments,
                            body=elif_pre
                            + [
                                check,
                                elif_node,
                                ast.Return(value=return_list),
                            ],
                            decorator_list=[],
                        )
                    else:
                        # Recursion for nested elif
                        with Region(self.session_data, new_value=elif_pre):
                            nested_if = self.create_if_function(
                                nested_if_name,
                                elif_node,
                                write_args,
                                full_write_args_count,
                            )
                        else_block = ast.FunctionDef(
                            name=else_block_name,
                            args=func_then_else_arguments,
                            body=elif_pre
                            + [
                                nested_if,
                                ast.Return(
                                    value=ast.Name(id=nested_if_name, ctx=ast.Load())
                                ),
                            ],
                            decorator_list=[],
                        )
                else:
                    else_body: list[ast.stmt] = []
                    with (
                        Region(self.session_data, new_value=else_body),
                        self.session_data.scope_manager.enter_control_flow_scope(),
                    ):
                        self._visit_stmts_into(node.orelse, else_body)

                    # Regular else block
                    else_block = ast.FunctionDef(
                        name=else_block_name,
                        args=func_then_else_arguments,
                        body=else_body + [ast.Return(value=return_list)],
                        decorator_list=[],
                    )
            else:
                # Default else block
                else_block = ast.FunctionDef(
                    name=else_block_name,
                    args=func_then_else_arguments,
                    body=[ast.Return(value=return_list)],
                    decorator_list=[],
                )

            _mark_synth_scope(else_block, node)
            # Add else_block to execute keywords
            execute_keywords.append(
                ast.keyword(
                    arg="else_block", value=ast.Name(id=else_block_name, ctx=ast.Load())
                )
            )

            execute_call = ast.copy_location(
                ast.Call(
                    func=_create_module_attribute(
                        self.IF_EXECUTOR, lineno=node.lineno, col_offset=node.col_offset
                    ),
                    args=[],
                    keywords=execute_keywords,
                ),
                node,
            )
            func_body = [
                then_block,
                else_block,
                ast.Return(value=execute_call),
            ]

        return ast.copy_location(
            ast.FunctionDef(
                name=func_name,
                args=func_decorator_arguments,
                body=func_body,
                decorator_list=[decorator],
            ),
            node,
        )

    def _adopt_while_condition_bound_names(
        self,
        node: ast.While,
        names: list[str],
        write_args: list[str],
        full_write_args_count: int,
    ) -> tuple[list[str], int]:
        """Hook for names a staged ``while`` condition binds with ``:=`` that
        have no binding before the loop.  This lowering keeps such a name a
        local of the condition block, so a body read of it is refused with
        the pre-binding fix; a name the body never reads stays as it is."""
        for name in names:
            read = next(
                (
                    sub
                    for stmt in node.body
                    for sub in ast.walk(stmt)
                    if isinstance(sub, ast.Name)
                    and sub.id == name
                    and isinstance(sub.ctx, ast.Load)
                ),
                None,
            )
            if read is not None:
                raise DSLUserCodeError(
                    DiagId.SCOPE_WALRUS_IN_WHILE_CONDITION,
                    filename=self.session_data.file_name,
                    lineno=getattr(read, "lineno", node.lineno),
                    col_offset=getattr(read, "col_offset", None),
                    end_col_offset=getattr(read, "end_col_offset", None),
                    name=name,
                )
        return write_args, full_write_args_count

    def _prepare_while_condition_vars(
        self,
        node: ast.While,
        write_args: list[str],
        while_before_stmts: list[ast.stmt],
    ) -> list[ast.stmt]:
        """Prepare write_args before while condition evaluation.

        Override for custom behavior (e.g., derived classes may insert instrumentation).
        Returns statements to insert at the beginning of while_before_block.
        """
        return []  # No preparation needed in base class

    def _prepare_loop_bound_expr(self, expr: ast.expr) -> ast.expr:
        """Instrument a staged-for range bound expression, evaluated at
        loop-selector call time outside the visited body; base is identity."""
        return expr

    def _prepare_loop_body_vars(
        self,
        node: "ast.For | ast.While",
        write_args: list[str],
    ) -> list[ast.stmt]:
        """Prepend statements at the top of a for/while body.

        Override hook: a Python-primitive write_arg whose first
        reference in the body is a Load before any Store needs explicit
        promotion via ``pyir_promote_loop_body_arg`` so the read site
        loads from the loop-carried ref instead of the trace-time
        constant.  Base class is a no-op.
        """
        return []

    def create_while_function(
        self,
        func_name: str,
        node: ast.While,
        write_args: list[str],
        full_write_args_count: int,
    ) -> ast.FunctionDef:
        """Create a while function that looks like:

        @while_selector(pred, write_args=[])
        def while_region(pred, write_args):
            def while_before_block(*write_args):
                # Note that during eval of pred can possibly alter yield_args
                return *pred, write_args
            def while_after_block(*write_args):
                ...loop_body_transformed...
                return write_args
            return self.while_executor(pred, write_args,
                while_before_block, while_after_block, constexpr)
        write_args = while_region(pred, write_args)

        Which will later be executed as psuedo-code:

        # Dynamic mode:
        scf.WhileOp(types(write_args), write_args)
        with InsertionPoint(before_block):
            cond, write_args = while_before_block(*write_args)
            scf.ConditionOp(cond, write_args)
        with InsertionPoint(after_block):
            write_args = while_after_block(write_args)
            scf.YieldOp(write_args)
        return while_op.results_

        # Const mode:
        cond, write_args = while_before_block(write_args)
        while pred:
            write_args = body_block(write_args)
            cond, write_args = while_before_block(write_args)
        return write_args
        """

        # Section: decorator construction
        decorator_keywords = [
            ast.keyword(
                arg="write_args",
                value=self.generate_get_locals_or_none_call(write_args),
            ),
        ]
        decorator = ast.copy_location(
            ast.Call(
                func=_create_module_attribute(
                    self.DECORATOR_WHILE_STATEMENT,
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[],
                keywords=decorator_keywords,
            ),
            node,
        )

        # Section: Shared initialization for before and after blocks
        while_before_block_name = f"while_before_block_{self.session_data.counter}"
        while_after_block_name = f"while_after_block_{self.session_data.counter}"
        self.session_data.counter += 1
        block_args_args = [ast.arg(arg=var, annotation=None) for var in write_args]
        block_args = ast.arguments(
            posonlyargs=[],
            args=block_args_args,
            kwonlyargs=[],
            kw_defaults=[],
            defaults=[],
        )

        yield_args_ast_name_list = ast.List(
            elts=[ast.Name(id=var, ctx=ast.Load()) for var in write_args],
            ctx=ast.Load(),
        )

        # Section: while_before_block FunctionDef, which contains condition
        while_before_stmts: list[ast.stmt] = []
        with Region(self.session_data, new_value=while_before_stmts):
            test_expr = ast.copy_location(self.visit(node.test), node.test)

        # Template method: prepare write_args before condition evaluation
        # Derived classes may insert instrumentation here
        condition_prep_stmts = self._prepare_while_condition_vars(
            node, write_args, while_before_stmts
        )
        if condition_prep_stmts:
            while_before_stmts[:0] = condition_prep_stmts

        while_before_return_list = ast.List(
            elts=[test_expr, yield_args_ast_name_list],
            ctx=ast.Load(),
        )
        while_before_stmts.append(ast.Return(value=while_before_return_list))
        while_before_block = _mark_synth_scope(
            ast.FunctionDef(
                name=while_before_block_name,
                args=block_args,
                body=while_before_stmts,
                decorator_list=[],
            ),
            test_expr,
        )

        # Mirror of for-loop body-prep hook: capture the
        # pyir_promote_loop_body_arg prologue against the original body
        # before the visit mutates Name nodes.
        body_prep_stmts = self._prepare_loop_body_vars(node, write_args)

        # Section: while_after_block FunctionDef, which contains loop body
        while_after_stmts: list[ast.stmt] = []
        with Region(self.session_data, new_value=while_after_stmts):
            self._visit_stmts_into(node.body, while_after_stmts)

        if body_prep_stmts:
            while_after_stmts[:0] = body_prep_stmts

        while_after_stmts.append(ast.Return(value=yield_args_ast_name_list))

        while_after_block = _mark_synth_scope(
            ast.FunctionDef(
                name=while_after_block_name,
                args=block_args,
                body=while_after_stmts,
                decorator_list=[],
            ),
            node,
        )

        # Section: Execute via executor
        execute_keywords = [
            ast.keyword(
                arg="write_args",
                value=ast.List(
                    elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in write_args],
                    ctx=ast.Load(),
                ),
            ),
            ast.keyword(
                arg="full_write_args_count",
                value=ast.Constant(value=full_write_args_count),
            ),
            ast.keyword(
                arg="while_before_block",
                value=ast.Name(id=while_before_block_name, ctx=ast.Load()),
            ),
            ast.keyword(
                arg="while_after_block",
                value=ast.Name(id=while_after_block_name, ctx=ast.Load()),
            ),
            ast.keyword(
                arg="write_args_names",
                value=ast.List(
                    elts=[ast.Constant(value=arg) for arg in write_args],
                    ctx=ast.Load(),
                ),
            ),
        ]
        execute_call = ast.Call(
            func=_create_module_attribute(
                self.WHILE_EXECUTOR, lineno=node.lineno, col_offset=node.col_offset
            ),
            args=[],
            keywords=execute_keywords,
        )

        # Putting everything together, FunctionDef for while_region
        func_args_args = [ast.arg(arg=var, annotation=None) for var in write_args]
        func_args = ast.arguments(
            posonlyargs=[],
            args=func_args_args,
            kwonlyargs=[],
            kw_defaults=[],
            defaults=[],
        )

        return ast.copy_location(
            ast.FunctionDef(
                name=func_name,
                args=func_args,
                body=[
                    while_before_block,
                    while_after_block,
                    ast.Return(value=execute_call),
                ],
                decorator_list=[decorator],
            ),
            node,
        )
