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
import warnings
from collections.abc import Callable, Generator, Iterable, Iterator
from dataclasses import dataclass, field
from typing import Any, TypeVar
from types import ModuleType
from copy import deepcopy
from itertools import chain

from .common import *
from .utils.logger import log


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
class ImportInfo:
    """
    Information about an import expression.
    """

    module_path: str
    attr_name: str | None
    alias_name: str


@dataclass
class TryImportInfo:
    """
    Represents information about a try-import block in the AST.

    This dataclass is used to capture and organize the import statements that appear
    within the different clauses of a try-except-else-finally block. Each field holds
    a list of import statements (or related nodes) that are encountered in the corresponding
    clause of the try block.

    Attributes:
        try_imports (list): Import statements found in the 'try' clause.
        except_imports (list): Import statements found in any 'except' clauses.
        else_imports (list): Import statements found in the 'else' clause, if present.
        finally_imports (list): Import statements found in the 'finally' clause, if present.

    This structure allows the preprocessor to track and process imports that are conditionally
    executed depending on exception handling logic.
    """

    try_imports: "list[ImportInfo | TryImportInfo]"
    except_imports: "list[ImportInfo | TryImportInfo]"
    else_imports: "list[ImportInfo | TryImportInfo]"
    finally_imports: "list[ImportInfo | TryImportInfo]"


@dataclass
class ScopeManager:
    """
    Manages symbol scopes during AST traversal.
    Manage nested scopes during transformations.
    """

    scopes: list[set[str]]
    callables: list[set[str]]

    @classmethod
    def create(cls) -> "ScopeManager":
        return cls([], [])

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
        yield
        self.scopes.pop()
        self.callables.pop()

    @contextlib.contextmanager
    def enter_control_flow_scope(self) -> Generator[None, None, None]:
        """
        Context manager for entering a new dynamic control-flow scope.

        This scope rule diverge from Python's local scope, variables defined here are discarded after exiting the block, but callables are kept in parent scope.

        This context manager pushes a new, empty variable scope onto the stack for the
        duration of a control-flow block (such as within loops or if/else blocks). Variables
        introduced inside this block are tracked separately and discarded after exiting the block.
        Callable symbol scopes are not affected.

        :yields: None

        **Example**
            .. code-block:: python

                with scope_manager.enter_control_flow_scope():
                    # Variables defined here are local to this control-flow scope
                    ...
        """
        self.scopes.append(set())
        yield
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
    function_counter: int = 0
    function_name: str = "<unknown function>"
    class_name: str | None = None
    file_name: str = "<unknown filename>"
    function_globals: dict[str, Any] | None = None
    import_top_module: bool = False
    region_stack: list[Region] = field(default_factory=list)
    generator_targets: list[str] = field(default_factory=list)
    lambda_args: list[str] = field(default_factory=list)

    @contextlib.contextmanager
    def set_current_class_name(self, class_name: str) -> Generator[None, None, None]:
        old_class_name = self.class_name
        self.class_name = class_name
        yield
        self.class_name = old_class_name

    @contextlib.contextmanager
    def set_current_function_name(
        self, function_name: str
    ) -> Generator[None, None, None]:
        old_function_name = self.function_name
        self.function_name = function_name
        yield
        self.function_name = old_function_name


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


_ComprehensionT = TypeVar(
    "_ComprehensionT", ast.ListComp, ast.SetComp, ast.GeneratorExp, ast.DictComp
)


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
    IFEXP_EXECUTOR = "ifExp_executor"
    WHILE_EXECUTOR = "while_executor"
    ASSERT_EXECUTOR = "assert_executor"
    IMPLICIT_DOWNCAST_NUMERIC_TYPE = "implicitDowncastNumericType"
    SUPPORTED_FOR_RANGE_STATEMENTS = {"range", "range_dynamic", "range_constexpr"}
    CONST_EXPR_NAME = {"const_expr", "target_version"}
    COMPARE_EXECUTOR = "compare_executor"
    BUILTIN_REDIRECTOR = "redirect_builtin_function"

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

    def __init__(self, client_module_name: list[str]) -> None:
        super().__init__()
        # Persistent state
        self.processed_functions: set[Callable[..., Any]] = set()
        self.client_module_name = client_module_name
        self.module_cache: dict[ModuleType, list[ImportInfo | TryImportInfo]] = {}
        self._session_data: SessionData | None = None

    @contextlib.contextmanager
    def get_session(self) -> Generator["DSLPreprocessor", None, None]:
        try:
            self._session_data = SessionData()
            yield self
        finally:
            self._session_data = None

    @property
    def session_data(self) -> SessionData:
        assert self._session_data is not None, (
            "Please start a session before accessing session data"
        )
        return self._session_data

    def _get_imports_from_ast(
        self, node: ast.AST, module: ModuleType
    ) -> list[ImportInfo | TryImportInfo]:
        """
        Recursively extracts all import statements from the given AST node.

        This method traverses the AST of a Python module and collects information about all
        import statements, including standard imports, from-imports (with support for relative imports),
        and imports that appear within try/except/finally blocks. For try blocks, it also handles
        imports that may be conditionally executed in except, else, or finally clauses, specifically
        looking for handlers that catch ImportError, ModuleNotFoundError, or Exception.

        Args:
            node: The AST node (typically an ast.Module) to search for import statements.
            module: The Python module object corresponding to the AST, used for resolving relative imports.

        Returns:
            A list of ImportInfo and TryImportInfo objects representing all discovered imports in the AST.
        """
        imports: list[ImportInfo | TryImportInfo] = []
        alias: Callable[[ast.alias], str] = lambda n: n.asname if n.asname else n.name
        for child_node in ast.iter_child_nodes(node):
            if isinstance(child_node, ast.Import):
                for name in child_node.names:
                    imports.append(
                        ImportInfo(
                            module_path=name.name,
                            attr_name=None,
                            alias_name=alias(name),
                        )
                    )
            elif isinstance(child_node, ast.ImportFrom):
                module_name = child_node.module
                if child_node.level > 0:
                    # Handle relative imports.
                    if module.__package__:
                        package_name = module.__package__.rsplit(
                            ".", child_node.level - 1
                        )[0]
                        # For `from . import x`, module name is None, just use package name
                        if module_name:
                            module_name = f"{package_name}.{module_name}"
                        else:
                            module_name = package_name
                    else:
                        # Handle typically some local import like:
                        # from .common_dense_gemm import DenseGemmKernel
                        # where there is no __package__, either None
                        # when in __main__ or '' otherwise.
                        module_name = f"{module_name}"
                for name in child_node.names:
                    imports.append(
                        ImportInfo(
                            module_path=module_name or "",
                            attr_name=name.name,
                            alias_name=alias(name),
                        )
                    )
            # ast.TryStar is introduced in Python 3.11. Can't use directly in Python 3.10 and lower.
            elif isinstance(child_node, (ast.Try, getattr(ast, "TryStar", ast.Try))):
                # Handle try-catch
                try_imports = self._get_imports_from_ast(
                    ast.Module(body=child_node.body, type_ignores=[]),  # type: ignore[attr-defined]
                    module,
                )
                # search handler for ImportError or ModuleNotFoundError
                except_imports: list[ImportInfo | TryImportInfo] = []
                for handler in child_node.handlers:  # type: ignore[attr-defined]
                    if handler.type == None or handler.type.id in [
                        "ImportError",
                        "ModuleNotFoundError",
                        "Exception",
                    ]:
                        except_imports = self._get_imports_from_ast(
                            ast.Module(body=handler.body, type_ignores=[]), module
                        )
                        break
                else_imports = self._get_imports_from_ast(
                    ast.Module(body=child_node.orelse, type_ignores=[]),  # type: ignore[attr-defined]
                    module,
                )
                finally_imports = self._get_imports_from_ast(
                    ast.Module(body=child_node.finalbody, type_ignores=[]),  # type: ignore[attr-defined]
                    module,
                )
                imports.append(
                    TryImportInfo(
                        try_imports, except_imports, else_imports, finally_imports
                    )
                )
        return imports

    def _get_module_imports(
        self, decorated_func: Callable[..., Any]
    ) -> list[ImportInfo | TryImportInfo]:
        """Extract imports from the module containing the decorated function"""
        imports: list[ImportInfo | TryImportInfo] = []

        # Get the module containing the decorated function
        if module := inspect.getmodule(decorated_func):
            if module in self.module_cache:
                return self.module_cache[module]
            try:
                # Get the module source code
                source = inspect.getsource(module)
                module_ast = ast.parse(source)

                imports = self._get_imports_from_ast(module_ast, module)
                self.module_cache[module] = imports
            except (IOError, TypeError):
                pass

        return imports

    def try_import_first_and_then_local_import(self, module_path: str) -> ModuleType:
        @contextlib.contextmanager
        def local_import(module_path: str) -> Generator[ModuleType, None, None]:
            # Directory where some local import might happen:
            local_dir = os.path.dirname(self.session_data.file_name)
            # Momentarily insert the directory where the local import
            # used to happen, so the import can find the module.
            sys.path.insert(0, local_dir)
            try:
                yield importlib.import_module(module_path)
            finally:
                # Clean up even in the case of an exception.
                sys.path.pop(0)

        try:
            # Try the normal import first.
            return importlib.import_module(module_path)
        except (ImportError, AttributeError):
            # If the normal import failed, tried a local import because we might
            # have lost track of sys.path changes.
            with local_import(module_path) as module:
                return module

    def exec_import(
        self, import_info: ImportInfo, exec_globals: dict[str, Any]
    ) -> None:
        module_path, attr_name, alias_name = (
            import_info.module_path,
            import_info.attr_name,
            import_info.alias_name,
        )
        module = self.try_import_first_and_then_local_import(module_path)
        if attr_name:
            if attr_name == "*":
                if hasattr(module, "__all__"):
                    attrs = module.__all__
                else:
                    attrs = [name for name in dir(module) if not name.startswith("_")]
            else:
                attrs = [attr_name]

            for attr in attrs:
                alias = attr if attr_name == "*" else alias_name
                exec_globals[alias] = getattr(module, attr)
        else:
            exec_globals[alias_name] = module

    def exec_imports(
        self,
        import_infos: list[ImportInfo | TryImportInfo],
        exec_globals: dict[str, Any],
    ) -> None:
        for import_info in import_infos:
            if isinstance(import_info, ImportInfo):
                try:
                    self.exec_import(import_info, exec_globals)
                except (ImportError, AttributeError) as e:
                    raise ImportError(
                        f"Failed to import {import_info.module_path}: {str(e)}"
                    )
            elif isinstance(import_info, TryImportInfo):
                try:
                    self.exec_imports(import_info.try_imports, exec_globals)
                except (ImportError, AttributeError):
                    self.exec_imports(import_info.except_imports, exec_globals)
                else:
                    self.exec_imports(import_info.else_imports, exec_globals)
                finally:
                    self.exec_imports(import_info.finally_imports, exec_globals)

    def exec(
        self,
        function_name: str,
        original_function: Callable[..., Any],
        code_object: types.CodeType,
        exec_globals: dict[str, Any],
    ) -> Callable[..., Any] | None:
        """Requires an active DSL preprocessor session."""
        # Get imports from the original module
        module_imports = self._get_module_imports(original_function)

        # Import all required modules
        self.exec_imports(module_imports, exec_globals)

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

    def _inject_default_arg_values(
        self,
        function_pointer: Callable[..., Any],
        func_ast: ast.FunctionDef,
    ) -> None:
        """Inject default-argument values whose source-level names are unresolvable.

        When a decorated function uses ``_param=name`` where ``name`` is a local
        in an enclosing factory, ``exec()`` needs ``name`` in its namespace.
        We use ``inspect.signature`` for runtime default values and the
        already-parsed *func_ast* for the source-level name each default
        references.
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
        # Build map: parameter name → AST default node
        # (covers both positional and keyword-only parameters)
        ast_defaults: dict[str, ast.expr] = {}
        all_args = func_ast.args.posonlyargs + func_ast.args.args
        offset = len(all_args) - len(func_ast.args.defaults)
        for i, default_node in enumerate(func_ast.args.defaults):
            ast_defaults[all_args[offset + i].arg] = default_node
        for kwarg, kw_default in zip(func_ast.args.kwonlyargs, func_ast.args.kw_defaults):
            if kw_default is not None:
                ast_defaults[kwarg.arg] = kw_default
        for param_name, default_val in params_with_defaults.items():
            ast_node = ast_defaults.get(param_name)
            if isinstance(ast_node, ast.Name) and ast_node.id not in exec_globals:
                exec_globals[ast_node.id] = default_val

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
            dedented_source = textwrap.dedent("".join(lines))
            tree = ast.parse(dedented_source, filename=file_name)
            # Bump the line numbers so they match the real source file
            ast.increment_lineno(tree, start_line - 1)
        except Exception:
            # Under REPL mode, there is no way to get source of a function object, error out
            raise DSLRuntimeError(
                f"Failed to parse function {func_name}",
                suggestion="DSL does not support REPL mode, save the function to a file instead.",
            )

        # Step 1.2 Check the decorator
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
        self._inject_default_arg_values(function_pointer, func_def)

        # Step 2. Transform the function
        transformed_tree = self.visit(tree)

        # Step 3. Import cutlass and base_dsl
        top_module_name = ".".join(self.client_module_name)
        import_stmts = []
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

    def check_early_exit(self, tree: ast.AST, kind: str) -> None:
        """
        Checks if a given region or scope in the provided Python code has early exits.
        """

        class EarlyExitChecker(ast.NodeVisitor):
            def __init__(self, kind: str) -> None:
                self.has_early_exit = False
                self.early_exit_node: ast.AST | None = None
                self.early_exit_type: str | None = None
                self.kind = kind
                self.loop_nest_level = 0

            def visit_Return(self, node: ast.Return) -> None:
                self.has_early_exit = True
                self.early_exit_node = node
                self.early_exit_type = "return"

            def visit_Raise(self, node: ast.Raise) -> None:
                self.has_early_exit = True
                self.early_exit_node = node
                self.early_exit_type = "raise"

            def visit_Break(self, node: ast.Break) -> None:
                # For break/continue in inner loops, we don't consider it as early exit
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
                # Stop at nested function def
                return

        checker = EarlyExitChecker(kind)
        checker.generic_visit(tree)
        if not checker.has_early_exit:
            return
        raise DSLAstPreprocessorError(
            message=f"Early exit ({checker.early_exit_type}) is not allowed in `{self.session_data.function_name}`"
            + (
                f" in `{self.session_data.class_name}`"
                if self.session_data.class_name
                else ""
            ),
            filename=self.session_data.file_name,
            snippet=ast.unparse(tree),
            suggestion=(
                "If predicates are constant expression, write like "
                "`if const_expr(...)` or `for ... in range_constexpr(...)`. "
                "In that case, early exit will be executed by Python "
                "interpreter, so it's supported."
            ),
        )

    def is_node_constexpr(self, node: ast.If | ast.While) -> bool:
        """
        Determines if the node is a constexpr.
        Supported nodes are if, while statements.
        """
        if isinstance(node, ast.If) or isinstance(node, ast.While):
            if isinstance(node.test, ast.Call):
                func = node.test.func

                if (
                    isinstance(func, ast.Attribute)
                    and func.attr in self.CONST_EXPR_NAME
                ):
                    return True

                elif isinstance(func, ast.Name) and func.id in self.CONST_EXPR_NAME:
                    return True
        return False

    def _get_range_kind(
        self, iter_node: ast.expr
    ) -> tuple[str | None, bool | None, bool | None]:
        """
        Return "range", "range_dynamic", "range_constexpr" or None for the iterable
        """
        if isinstance(iter_node, ast.Call):
            func = iter_node.func
            if (
                isinstance(func, ast.Name)
                and func.id in self.SUPPORTED_FOR_RANGE_STATEMENTS
            ):
                return func.id, True, len(iter_node.keywords) != 0
            if (
                isinstance(func, ast.Attribute)
                and func.attr in self.SUPPORTED_FOR_RANGE_STATEMENTS
            ):
                return func.attr, False, len(iter_node.keywords) != 0
        return None, None, None

    def transform(
        self,
        original_function: Callable[..., Any],
        exec_globals: dict[str, Any],
        callee_rewrite: bool = False,
    ) -> ast.Module:
        """
        Transforms the provided function using the preprocessor.
        Requires an active DSL preprocessor session.
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
        unified_tree = ast.fix_missing_locations(unified_tree)

        return unified_tree

    def analyze_region_variables(
        self,
        node: ast.For | ast.If | ast.While,
        active_symbols: list[set[str]],
        active_callables: list[set[str]],
    ) -> tuple[list[str], int, list[str]]:
        """
        Analyze variables in different code regions to identify read-only, write-only,
        and active variables for DSL constructs.
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
                # When subscript occurs on the lhs of an assignment, the `Name` is still a load, but `Subscript` is marked as `Store`.
                # We need to force the store for the `Name` to be marked as write.
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
                # If the .value is another Attribute, keep digging
                if isinstance(func_node, ast.Attribute):
                    if isinstance(func_node.value, ast.Attribute):
                        return RegionAnalyzer.get_call_base(func_node.value)
                    # If the .value is a Name, that's our base
                    elif isinstance(func_node.value, ast.Name):
                        return func_node.value.id
                    else:
                        # Could be something else (lambda, call, etc.)
                        return None
                elif isinstance(func_node, ast.Name):
                    return None
                return None

            @staticmethod
            def get_function_name(func_node: ast.Call) -> str | None:
                if isinstance(func_node.func, ast.Name):
                    function_name = func_node.func.id
                # Check if it's a method or attribute call
                elif isinstance(func_node.func, ast.Attribute):
                    function_name = func_node.func.attr
                else:
                    function_name = None
                return function_name

            def visit_Call(self, node: ast.Call) -> None:
                base_name = RegionAnalyzer.get_call_base(node.func)

                if isinstance(node.func, ast.Name):
                    func_name = node.func.id
                    called_functions.add(func_name)

                # Classes are mutable by default. Mark them as write. If they are
                # dataclass(frozen=True), treat them as read in runtime.
                if base_name is not None and base_name not in ("self"):
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
        called_functions_list: list[str] = list(
            called_functions.intersections(active_callables)
        )
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
            raise DSLAstPreprocessorError(
                "Unsupported number of arguments in range",
                filename=self.session_data.file_name,
            )

    def extract_unroll_args(self, iter_node: ast.Call) -> tuple[ast.expr, ast.expr]:
        keywords = {kw.arg: kw.value for kw in iter_node.keywords}
        return (
            keywords.get("unroll", ast.Constant(value=-1)),
            keywords.get("unroll_full", ast.Constant(value=False)),
        )

    def issue_deprecation_warning(
        self, *, message: str, category: type[Warning], filename: str, lineno: int
    ) -> None:
        warnings.simplefilter("always", category)  # turn off filter
        warnings.warn_explicit(
            message, category=category, filename=filename, lineno=lineno
        )
        warnings.simplefilter("default", category)  # reset filter

    def extract_prefetch_stages_args(self, iter_node: ast.Call) -> ast.expr:
        keywords = {kw.arg: kw.value for kw in iter_node.keywords}
        if "pipelining" in keywords:
            self.issue_deprecation_warning(
                message="pipelining is deprecated, use prefetch_stages instead",
                category=DeprecationWarning,
                filename=self.session_data.file_name,
                lineno=iter_node.lineno,
            )
            return keywords.get("pipelining", ast.Constant(value=None))
        return keywords.get("prefetch_stages", ast.Constant(value=None))

    def extract_vectorize_args(self, iter_node: ast.Call) -> ast.expr:
        keywords = {kw.arg: kw.value for kw in iter_node.keywords}
        return keywords.get("vectorize", ast.Constant(value=None))

    def extract_at_least_once_args(self, iter_node: ast.Call) -> ast.expr:
        keywords = {kw.arg: kw.value for kw in iter_node.keywords}
        return keywords.get("at_least_once", ast.Constant(value=False))

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
        with Region(self.session_data, new_value=transformed_body):
            for stmt in node.body:
                transformed_stmt = self.visit(
                    stmt
                )  # Recursively visit inner statements
                if isinstance(transformed_stmt, list):
                    transformed_body.extend(transformed_stmt)
                else:
                    transformed_body.append(transformed_stmt)

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

        return ast.copy_location(
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
        # Visit child nodes first
        self.generic_visit(node)

        # It is necessary to expand short circuit evaluation explicit here
        # Although we do not support inline if-else for IR generation, this is actually evaluated in Python
        # So it's fine here
        # Transform "and" to "and_"
        if isinstance(node.op, ast.And):
            # Create an if-else statement in AST form
            # if type(lhs) == bool and lhs == False:
            #     return lhs
            # else
            #     return and_(lhs, rhs)
            short_circuit_value = ast.Constant(value=False)
            helper_func = _create_module_attribute(
                "and_",
                use_base_dsl=False,
                submodule_name=None,
                lineno=node.lineno,
                col_offset=node.col_offset,
            )
            self.session_data.import_top_module = True
        # Transform "or" to "or_"
        elif isinstance(node.op, ast.Or):
            # Create an if-else statement in AST form
            # if type(lhs) == bool and lhs == True:
            #     return lhs
            # else
            #     return or_(lhs, rhs)
            short_circuit_value = ast.Constant(value=True)
            helper_func = _create_module_attribute(
                "or_",
                use_base_dsl=False,
                submodule_name=None,
                lineno=node.lineno,
                col_offset=node.col_offset,
            )
            self.session_data.import_top_module = True
        else:
            # BoolOp should be either And or Or
            raise DSLAstPreprocessorError(
                f"Unsupported boolean operation: {node.op}",
                filename=self.session_data.file_name,
                snippet=ast.unparse(node),
            )

        def short_circuit_eval(
            value: ast.expr, short_circuit_value: ast.Constant
        ) -> ast.BoolOp:
            return ast.copy_location(
                ast.BoolOp(
                    op=ast.And(),
                    values=[
                        ast.Compare(
                            left=ast.Call(
                                func=ast.Name(id="type", ctx=ast.Load()),
                                args=[value],
                                keywords=[],
                            ),
                            ops=[ast.Eq()],
                            comparators=[ast.Name(id="bool", ctx=ast.Load())],
                        ),
                        ast.Compare(
                            left=value,
                            ops=[ast.Eq()],
                            comparators=[short_circuit_value],
                        ),
                    ],
                ),
                node,
            )

        lhs = node.values[0]

        for i in range(1, len(node.values)):
            test = short_circuit_eval(lhs, short_circuit_value)
            lhs = ast.copy_location(
                ast.IfExp(
                    test=test,
                    body=lhs,
                    orelse=ast.Call(
                        func=helper_func,
                        args=[lhs, node.values[i]],
                        keywords=[],
                    ),
                ),
                node,
            )

        return lhs

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
                args=[deepcopy(func)],
                keywords=[],
            ),
            func,
        )
        return ast.Expr(check_call)

    def visit_For(self, node: ast.For) -> ast.For | list[ast.stmt]:
        # For static for loop (for with range_constexpr or not range based for), preprocessor keeps the loop.
        range_kind, is_builtin_range, has_keyword = self._get_range_kind(node.iter)
        if range_kind == "range_constexpr" or range_kind == None:
            self.generic_visit(node)
            if range_kind == "range_constexpr":
                assert isinstance(node.iter, ast.Call)
                check_call = self._insert_cf_symbol_check(node.iter.func)
                # Rewrite range_constexpr to range
                node.iter.func = ast.Name(id="range", ctx=ast.Load())
                self._insert_range_value_check(node)
                return [check_call, node]
            return node

        active_symbols = self.session_data.scope_manager.get_active_symbols()
        active_callables = self.session_data.scope_manager.get_active_callables()

        with self.session_data.scope_manager.enter_control_flow_scope():
            if isinstance(node.target, ast.Name):
                self.session_data.scope_manager.add_to_scope(node.target.id)

            if range_kind == "range_dynamic":
                # Generate a warning
                self.issue_deprecation_warning(
                    message="range_dynamic is deprecated and will be removed in the future, please remove it.",
                    category=DeprecationWarning,
                    filename=self.session_data.file_name,
                    lineno=node.iter.lineno,
                )

            is_prefixed_range = range_kind == "range" and not is_builtin_range
            check_call: ast.Expr | None = None  # type: ignore[no-redef]
            if range_kind == "range_dynamic" or is_prefixed_range:
                assert isinstance(node.iter, ast.Call)
                if not is_prefixed_range:
                    check_call = self._insert_cf_symbol_check(node.iter.func)
                else:
                    assert isinstance(node.iter.func, ast.Attribute)
                    check_call = self._insert_cf_symbol_check(node.iter.func.value)

            new_for_node = self.transform_for_loop(
                node, active_symbols, active_callables
            )
            if check_call is not None:
                new_for_node = [check_call] + new_for_node

        return new_for_node

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

        # Add this to begining of loop body
        # for i in range(start, stop, step):
        #     i = offset - i if isNegative else i
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
    ) -> ast.Expr:
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

    def transform_for_loop(
        self,
        node: ast.For,
        active_symbols: list[set[str]],
        active_callables: list[set[str]],
    ) -> list[ast.stmt]:
        # Check for early exit and raise exception
        self.check_early_exit(node, "for")
        if node.orelse:
            raise DSLAstPreprocessorError(
                "dynamic for loop with else is not supported",
                filename=self.session_data.file_name,
                snippet=ast.unparse(node),
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
            exprs.append(self._create_closure_check_call(called_closures, node))

        func_name = f"loop_body_{self.session_data.counter}"
        self.session_data.counter += 1

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
        if node.format_spec:
            assert isinstance(node.format_spec, ast.JoinedStr)
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
                raise DSLAstPreprocessorError(
                    f"Unsupported component type in f-string: {type(component)}",
                    filename=self.session_data.file_name,
                    snippet=ast.unparse(component),
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

    def visit_Call(self, node: ast.Call) -> ast.Call:
        func = self.visit(node.func)
        # Visit args and kwargs
        node.args = [self.visit(arg) for arg in node.args]
        node.keywords = [self.visit(kwarg) for kwarg in node.keywords]

        # Rewrite call to some built-in functions
        if isinstance(func, ast.Name):
            # AST rewrite only redirect call to bool to bool_cast
            # If `bool` escapes as a symbol, usually it means type check, do not rewrite it
            if func.id == "bool":
                return ast.copy_location(
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
            elif func.id == "super" and node.args == [] and node.keywords == []:
                # If it's a Python3 argument free super(), rewrite to old style super with args
                # So if this call is under dynamic control flow, it still works.
                return ast.copy_location(
                    ast.Call(
                        func=func,
                        args=node.args
                        + [
                            ast.Attribute(
                                value=ast.Name(id="self", ctx=ast.Load()),
                                attr="__class__",
                                ctx=ast.Load(),
                            ),
                            ast.Name(id="self", ctx=ast.Load()),
                        ],
                        keywords=node.keywords,
                    ),
                    node,
                )
            elif (
                func.id in ("printf", "print_runtime")
                and len(node.args) > 0
                and isinstance(node.args[0], ast.JoinedStr)
            ):
                node.args = [
                    ast.Starred(value=self.processFString(node), ctx=ast.Load())
                ]
        elif isinstance(func, ast.Attribute) and isinstance(func.value, ast.Name):
            if (
                func.attr in ("printf", "print_runtime")
                and len(node.args) > 0
                and isinstance(node.args[0], ast.JoinedStr)
            ):
                node.args = [
                    ast.Starred(value=self.processFString(node), ctx=ast.Load())
                ]
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
        else:
            node.func = self.visit(node.func)

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

    def visit_Return(self, node: ast.Return) -> ast.stmt | list[ast.stmt]:
        self.generic_visit(node)
        return node

    def visit_Expr(self, node: ast.Expr) -> ast.stmt | list[ast.stmt]:
        self.generic_visit(node)
        return node

    def visit_AnnAssign(self, node: ast.AnnAssign) -> ast.AnnAssign:
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
            raise DSLAstPreprocessorError("Read '_' is not allowed")
        else:
            self.generic_visit(node)
        return node

    def get_dsl_decorator_index(self, decorator_list: list[ast.expr]) -> Any:
        for i, d in enumerate(decorator_list):
            if isinstance(d, ast.Call):
                if isinstance(d.func, ast.Attribute):
                    if d.func.attr in ["jit", "kernel"]:
                        if d.keywords == []:
                            return i

                        # Keep existing preprocess behavior unchanged.
                        for keyword in d.keywords:
                            if keyword.arg == "preprocess":
                                try:
                                    if isinstance(keyword.value, ast.Constant):
                                        return keyword.value.value
                                    else:
                                        return ast.literal_eval(keyword.value)
                                except:
                                    pass

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
            raise DSLAstPreprocessorError(
                f"`{decorator}` decorator must be the inner most decorator",
                suggestion=f"Please move the `{decorator}` decorator to the inner most position",
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
        raise DSLAstPreprocessorError(
            "`global` is not supported in DSL",
            suggestion="Please explicitly pass in global variables as arguments",
        )

    def visit_Nonlocal(self, node: ast.Nonlocal) -> ast.Nonlocal:
        active_symbols = self.session_data.scope_manager.get_active_symbols()
        nonlocal_names = OrderedSet(node.names)
        intersect = nonlocal_names.intersections(active_symbols)
        for name in node.names:
            if name not in intersect:
                raise DSLRuntimeError(
                    (
                        f"`{ast.unparse(node)}` is referring to `{name}` which is not tracked by current JIT context, "
                        "this is not supported in DSL"
                    ),
                    suggestion="Please explicitly pass in nonlocal variables as arguments",
                )
        self.generic_visit(node)
        return node

    def visit_FunctionDef(self, node: ast.FunctionDef) -> ast.FunctionDef:
        # Add self to active symbols of parent scope
        self.session_data.scope_manager.add_to_callables(node.name)

        with (
            self.session_data.scope_manager.enter_local_scope(),
            self.session_data.set_current_function_name(node.name),
        ):
            self.session_data.function_counter += 1

            # Add function name and arguments
            self.session_data.scope_manager.add_to_scope(node.name)
            for arg in node.args.args:
                self.session_data.scope_manager.add_to_scope(arg.arg)
                arg.annotation = None

            for arg in node.args.kwonlyargs:
                self.session_data.scope_manager.add_to_scope(arg.arg)
                arg.annotation = None

            for arg in node.args.posonlyargs:
                self.session_data.scope_manager.add_to_scope(arg.arg)
                arg.annotation = None

            self.generic_visit(node)

        # Remove .jit and .kernel decorators
        node.decorator_list = self.remove_dsl_decorator(node.decorator_list)

        # Remove return annotation from processed AST to avoid symbol requirement
        node.returns = None
        return node

    def visit_With(self, node: ast.With) -> ast.AST:
        for item in node.items:
            if isinstance(item.optional_vars, ast.Name):
                self.session_data.scope_manager.add_to_scope(item.optional_vars.id)
        return self.generic_visit(node)

    def visit_While(self, node: ast.While) -> ast.While | list[ast.stmt]:
        # Constexpr doesn't get preprocessed
        if self.is_node_constexpr(node):
            self.generic_visit(node)
            assert isinstance(node.test, ast.Call)
            check = self._insert_cf_symbol_check(node.test.func)
            return [check, node]

        active_symbols = self.session_data.scope_manager.get_active_symbols()
        active_callables = self.session_data.scope_manager.get_active_callables()

        with self.session_data.scope_manager.enter_control_flow_scope():
            self.check_early_exit(node, "while")

            write_args, full_write_args_count, called_closures = (
                self.analyze_region_variables(node, active_symbols, active_callables)
            )
            exprs = []
            if called_closures:
                exprs.append(self._create_closure_check_call(called_closures, node))

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
        """Creates the assignment statement for the if function call"""
        if not yield_args:
            return [
                ast.copy_location(
                    ast.Expr(value=ast.Name(id=func_name, ctx=ast.Load())), node
                )
            ]
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
            [then_block_def, else_block_def]
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

        call = ast.copy_location(
            ast.Call(
                func=_create_module_attribute(self.COMPARE_EXECUTOR),
                args=[],
                keywords=keywords,
            ),
            node,
        )

        return call

    def visit_If(self, node: ast.If) -> ast.If | list[ast.stmt]:
        # const_expr doesn't get preprocessed
        if self.is_node_constexpr(node):
            self.generic_visit(node)
            assert isinstance(node.test, ast.Call)
            check = self._insert_cf_symbol_check(node.test.func)
            return [check, node]

        active_symbols = self.session_data.scope_manager.get_active_symbols()
        active_callables = self.session_data.scope_manager.get_active_callables()

        with self.session_data.scope_manager.enter_control_flow_scope():
            self.check_early_exit(node, "if")

            yield_args, full_write_args_count, called_closures = (
                self.analyze_region_variables(node, active_symbols, active_callables)
            )
            exprs = []
            if called_closures:
                exprs.append(self._create_closure_check_call(called_closures, node))

            func_name = f"if_region_{self.session_data.counter}"
            self.session_data.counter += 1

            func_def = self.create_if_function(
                func_name, node, yield_args, full_write_args_count
            )
            assign = self.create_cf_call(func_name, yield_args, node)

        return exprs + [func_def] + assign

    def generate_get_locals_or_none_call(self, write_args: list[str]) -> ast.Call:
        return ast.Call(
            func=_create_module_attribute("get_locals_or_none"),
            args=[
                ast.Call(
                    func=ast.Name(id="locals", ctx=ast.Load()), args=[], keywords=[]
                ),
                ast.List(
                    elts=[ast.Constant(value=arg) for arg in write_args],
                    ctx=ast.Load(),
                ),
            ],
            keywords=[],
        )

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
            for stmt in node.body:
                transformed_stmt = self.visit(
                    stmt
                )  # Recursively visit inner statements
                if isinstance(transformed_stmt, list):
                    then_body.extend(transformed_stmt)
                else:
                    then_body.append(transformed_stmt)

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
        then_block = ast.copy_location(
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
                    if self.is_node_constexpr(elif_node):
                        self.generic_visit(elif_node)
                        assert isinstance(elif_node.test, ast.Call)
                        check = self._insert_cf_symbol_check(elif_node.test.func)
                        else_block = ast.FunctionDef(
                            name=else_block_name,
                            args=func_then_else_arguments,
                            body=[
                                check,
                                elif_node,
                                ast.Return(value=return_list),
                            ],
                            decorator_list=[],
                        )
                    else:
                        # Recursion for nested elif
                        nested_if = self.create_if_function(
                            nested_if_name, elif_node, write_args, full_write_args_count
                        )
                        else_block = ast.FunctionDef(
                            name=else_block_name,
                            args=func_then_else_arguments,
                            body=[
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
                        for stmt in node.orelse:
                            transformed_stmt = self.visit(
                                stmt
                            )  # Recursively visit inner statements
                            if isinstance(transformed_stmt, list):
                                else_body.extend(transformed_stmt)
                            else:
                                else_body.append(transformed_stmt)

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
                ast.copy_location(else_block, node),
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

        while_before_return_list = ast.List(
            elts=[test_expr, yield_args_ast_name_list],
            ctx=ast.Load(),
        )
        while_before_stmts.append(ast.Return(value=while_before_return_list))
        while_before_block = ast.copy_location(
            ast.FunctionDef(
                name=while_before_block_name,
                args=block_args,
                body=while_before_stmts,
                decorator_list=[],
            ),
            test_expr,
        )

        # Section: while_after_block FunctionDef, which contains loop body
        while_after_stmts: list[ast.stmt] = []
        with Region(self.session_data, new_value=while_after_stmts):
            for stmt in node.body:
                transformed_stmt = self.visit(
                    stmt
                )  # Recursively visit inner statements
                if isinstance(transformed_stmt, list):
                    while_after_stmts.extend(transformed_stmt)
                else:
                    while_after_stmts.append(transformed_stmt)
        while_after_stmts.append(ast.Return(value=yield_args_ast_name_list))

        while_after_block = ast.copy_location(
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
