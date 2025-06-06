# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
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
        - Supports `range`, `range_dynamic`, and `range_constexpr` for loop iteration.
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
import importlib
import inspect
import textwrap
from dataclasses import dataclass
from typing import List, Set, Dict, Any, Callable, Optional
from types import ModuleType

from .common import *
from .utils.logger import log


class OrderedSet:
    """
    A deterministic set implementation for ordered operations.
    """

    def __init__(self, iterable=None):
        self._dict = dict.fromkeys(iterable or [])

    def add(self, item):
        self._dict[item] = None

    def __iter__(self):
        return iter(self._dict)

    def __and__(self, other):
        return OrderedSet(key for key in self._dict if key in other)

    def __or__(self, other):
        new_dict = self._dict.copy()
        new_dict.update(dict.fromkeys(other))
        return OrderedSet(new_dict)

    def __sub__(self, other):
        return OrderedSet(key for key in self._dict if key not in other)


@dataclass
class ScopeManager:
    """
    Manages symbol scopes during AST traversal.
    Manage nested scopes during transformations.
    """

    scopes: List[Set[str]]
    current_scope: Set[str]

    @classmethod
    def create(cls) -> "ScopeManager":
        return cls([], set())

    def enter_scope(self) -> None:
        self.scopes.append(self.current_scope.copy())

    def exit_scope(self) -> None:
        self.current_scope = self.scopes.pop()

    def add_to_scope(self, name: str) -> None:
        self.current_scope.add(name)

    def get_active_symbols(self) -> Set[str]:
        return set(self.current_scope)


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
    WHILE_EXECUTOR = "while_executor"
    ASSERT_EXECUTOR = "assert_executor"
    BOOL_CAST = "bool_cast"
    IMPLICIT_DOWNCAST_NUMERIC_TYPE = "implicitDowncastNumericType"
    SUPPORTED_FOR_RANGE_STATEMENTS = {"range", "range_dynamic", "range_constexpr"}

    def __init__(self):
        super().__init__()
        self.counter = 0  # Unique function names for multiple loops
        self.scope_manager = ScopeManager.create()
        self.processed_functions = set()
        self.function_counter = 0
        self.function_name = "<unknown function>"
        self.class_name = None
        self.file_name = "<unknown filename>"
        self.function_depth = 0
        self.local_closures = set()
        self.function_globals = None

    def _get_module_imports(self, decorated_func):
        """Extract imports from the module containing the decorated function"""
        # Get the module containing the decorated function
        module = inspect.getmodule(decorated_func)
        if module is None:
            return {}

        # Get the module source code
        try:
            source = inspect.getsource(module)
            module_ast = ast.parse(source)

            # Extract imports from the full module
            imports = {}
            for node in ast.walk(module_ast):
                if isinstance(node, ast.Import):
                    for name in node.names:
                        imports[name.name] = name.asname if name.asname else name.name
                elif isinstance(node, ast.ImportFrom):
                    module_name = node.module
                    for name in node.names:
                        if name.name == "*":
                            # Handle wildcard imports
                            try:
                                imported_module = importlib.import_module(module_name)
                                imports[module_name] = imported_module
                            except ImportError:
                                pass
                        else:
                            full_name = f"{module_name}.{name.name}"
                            imports[full_name] = (
                                name.asname if name.asname else name.name
                            )
            return imports
        except (IOError, TypeError):
            return {}

    def exec(self, function_name, original_function, code_object, exec_globals):
        # Get imports from the original module
        module_imports = self._get_module_imports(original_function)

        # Import all required modules
        for module_path, alias in module_imports.items():
            try:
                if "." in module_path:
                    base_module, attribute = module_path.rsplit(".", 1)
                    module = importlib.import_module(base_module)
                    if hasattr(module, attribute):
                        attr = getattr(module, attribute)
                        exec_globals[alias] = attr
                else:
                    path = importlib.import_module(module_path)
                    exec_globals[alias] = path
            except (ImportError, AttributeError) as e:
                raise ImportError(f"Failed to import {module_path}: {str(e)}")

        # Execute the transformed code
        log().info(
            "ASTPreprocessor Executing transformed code for function [%s]",
            function_name,
        )
        exec(code_object, exec_globals)
        return exec_globals.get(function_name)

    @staticmethod
    def print_ast(transformed_tree=None):
        print("#", "-" * 40, "Transformed AST", "-" * 40)
        unparsed_code = ast.unparse(transformed_tree)
        print(unparsed_code)
        print("#", "-" * 40, "End Transformed AST", "-" * 40)

    def make_func_param_name(self, base_name, used_names):
        """Generate a unique parameter name that doesn't collide with existing names."""
        if base_name not in used_names:
            return base_name

        i = 0
        while f"{base_name}_{i}" in used_names:
            i += 1
        return f"{base_name}_{i}"

    def transform_function(self, func_name, function_pointer):
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
        file_name = inspect.getsourcefile(function_pointer)
        lines, start_line = inspect.getsourcelines(function_pointer)
        dedented_source = textwrap.dedent("".join(lines))
        tree = ast.parse(dedented_source, filename=file_name)
        # Bump the line numbers so they match the real source file
        ast.increment_lineno(tree, start_line - 1)

        # Step 1.2 Check the decorator
        if not self.check_decorator(tree.body[0]):
            log().info(
                "[%s] - Skipping function due to missing decorator",
                func_name,
            )
            return []

        self.processed_functions.add(function_pointer)
        log().info("ASTPreprocessor Transforming function [%s]", func_name)

        # Step 2. Transform the function
        transformed_tree = self.visit(tree)
        ast.fix_missing_locations(transformed_tree)
        combined_body = transformed_tree.body

        # Step 3. Return the transformed tree
        return combined_body

    def check_early_exit(self, tree, kind):
        """
        Checks if a given region or scope in the provided Python code has early exits.
        """

        class EarlyExitChecker(ast.NodeVisitor):
            def __init__(self, kind):
                self.has_early_exit = False
                self.early_exit_node = None
                self.early_exit_type = None
                self.kind = kind
                self.loop_nest_level = 0

            # Early exit is not allowed in any level of dynamic control flow
            def visit_Return(self, node):
                self.has_early_exit = True
                self.early_exit_node = node
                self.early_exit_type = "return"

            def visit_Raise(self, node):
                self.has_early_exit = True
                self.early_exit_node = node
                self.early_exit_type = "raise"

            def visit_Break(self, node):
                # For break/continue in inner loops, we don't consider it as early exit
                if self.loop_nest_level == 0 and self.kind != "if":
                    self.has_early_exit = True
                    self.early_exit_node = node
                    self.early_exit_type = "break"

            def visit_Continue(self, node):
                if self.loop_nest_level == 0 and self.kind != "if":
                    self.has_early_exit = True
                    self.early_exit_node = node
                    self.early_exit_type = "continue"

            def visit_For(self, node):
                self.loop_nest_level += 1
                self.generic_visit(node)
                self.loop_nest_level -= 1

            def visit_While(self, node):
                self.loop_nest_level += 1
                self.generic_visit(node)
                self.loop_nest_level -= 1

        checker = EarlyExitChecker(kind)
        checker.generic_visit(tree)
        if not checker.has_early_exit:
            return
        raise DSLAstPreprocessorError(
            message=f"Early exit ({checker.early_exit_type}) is not allowed in `{self.function_name}`"
            + (f" in `{self.class_name}`" if self.class_name else ""),
            filename=self.file_name,
            snippet=ast.unparse(tree),
            suggestion=(
                "If predicates are constant expression, write like "
                "`if const_expr(...)` or `for ... in range_constexpr`. "
                "In that case, early exit will be executed by Python "
                "interpreter, so it's supported."
            ),
        )

    def is_node_constexpr(self, node) -> bool:
        """
        Determines if the node is a constexpr.
        Supported nodes are if, for, while statements.
        """
        if isinstance(node, ast.If) or isinstance(node, ast.While):
            if isinstance(node.test, ast.Call):
                func = node.test.func

                if isinstance(func, ast.Attribute) and func.attr == "const_expr":
                    return True

                elif isinstance(func, ast.Name) and func.id == "const_expr":
                    return True
        elif isinstance(node, ast.For):
            if isinstance(node.iter, ast.Call):
                func = node.iter.func
                if isinstance(func, ast.Attribute) and func.attr == "range_constexpr":
                    return True

                elif isinstance(func, ast.Name) and func.id == "range_constexpr":
                    return True
        return False

    def transform(self, original_function, exec_globals):
        """
        Transforms the provided function using the preprocessor.
        """
        self.file_name = inspect.getsourcefile(original_function)
        self.function_globals = exec_globals
        transformed_tree = self.transform_function(
            original_function.__name__, original_function
        )
        unified_tree = ast.Module(body=transformed_tree, type_ignores=[])
        unified_tree = ast.fix_missing_locations(unified_tree)

        return unified_tree

    def analyze_region_variables(self, node: Union[ast.For, ast.If], active_symbols):
        """
        Analyze variables in different code regions to identify read-only, write-only,
        and active variables for DSL constructs.
        """

        # we need orderedset to keep the insertion order the same. otherwise generated IR is different each time
        read_args = OrderedSet()
        write_args = OrderedSet()
        local_closure = self.local_closures
        file_name = self.file_name
        region_node = node

        class RegionAnalyzer(ast.NodeVisitor):

            def visit_Name(self, node):
                """
                Mark every load as read, and every store as write.
                """
                if isinstance(node.ctx, ast.Load):
                    read_args.add(node.id)
                elif isinstance(node.ctx, ast.Store):
                    write_args.add(node.id)

            @staticmethod
            def get_call_base(func_node):
                if isinstance(func_node, ast.Attribute):
                    # If the .value is another Attribute, keep digging
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
            def get_function_name(func_node: ast.Call):
                if isinstance(func_node.func, ast.Name):
                    function_name = func_node.func.id
                # Check if it's a method or attribute call
                elif isinstance(func_node.func, ast.Attribute):
                    function_name = func_node.func.attr
                else:
                    function_name = None
                return function_name

            def visit_Call(self, node):
                base_name = RegionAnalyzer.get_call_base(node.func)

                if isinstance(node.func, ast.Name):
                    func_name = node.func.id
                    if func_name in local_closure:
                        raise DSLAstPreprocessorError(
                            f"Function `{func_name}` is a closure and is not supported in for/if statements",
                            filename=file_name,
                            snippet=ast.unparse(region_node),
                        )

                # Classes are mutable by default. Mark them as write. If they are
                # dataclass(frozen=True), treat them as read in runtime.
                if base_name is not None and base_name not in ("self"):
                    write_args.add(base_name)

                self.generic_visit(node)

        analyzer = RegionAnalyzer()
        analyzer.visit(ast.Module(body=node))

        # Argument can be Load and Store. We should just mark it as Store.
        read_args = read_args - write_args

        used_args = read_args & active_symbols
        iter_args = write_args & active_symbols
        flattend_args = used_args | iter_args

        return list(used_args), list(iter_args), list(flattend_args)

    def extract_range_args(self, iter_node):
        args = iter_node.args
        if len(args) == 1:
            return ast.Constant(value=0), self.visit(args[0]), ast.Constant(value=1)
        elif len(args) == 2:
            return self.visit(args[0]), self.visit(args[1]), ast.Constant(value=1)
        elif len(args) == 3:
            return self.visit(args[0]), self.visit(args[1]), self.visit(args[2])
        else:
            raise DSLAstPreprocessorError(
                "Unsupported number of arguments in range", filename=self.file_name
            )

    def extract_unroll_args(self, iter_node):
        keywords = {kw.arg: kw.value for kw in iter_node.keywords}
        return (
            keywords.get("unroll", ast.Constant(value=-1)),
            keywords.get("unroll_full", ast.Constant(value=False)),
        )

    def create_loop_function(
        self,
        func_name,
        node,
        start,
        stop,
        step,
        unroll,
        unroll_full,
        used_args,
        iter_args,
        flattened_args,
        is_loop_constexpr,
    ):
        """
        Creates a loop body function with the `loop_selector` decorator.
        """

        func_args = [ast.arg(arg=node.target.id, annotation=None)]
        func_args += [ast.arg(arg=var, annotation=None) for var in flattened_args]

        # Create the loop body
        transformed_body = []
        for stmt in node.body:
            transformed_stmt = self.visit(stmt)  # Recursively visit inner statements
            if isinstance(transformed_stmt, list):
                transformed_body.extend(transformed_stmt)
            else:
                transformed_body.append(transformed_stmt)

        # Handle the return for a single iterated argument correctly
        if len(iter_args) == 0:
            transformed_body.append(ast.Return())
        else:
            transformed_body.append(
                ast.Return(
                    value=ast.List(
                        elts=[ast.Name(id=var, ctx=ast.Load()) for var in iter_args],
                        ctx=ast.Load(),
                    )
                )
            )

        # Define the decorator with parameters
        decorator = ast.copy_location(
            ast.Call(
                func=ast.Name(id=self.DECORATOR_FOR_STATEMENT, ctx=ast.Load()),
                args=[start, stop, step],
                keywords=[
                ast.keyword(arg="unroll", value=unroll),
                ast.keyword(arg="unroll_full", value=unroll_full),
                ast.keyword(arg="constexpr", value=is_loop_constexpr),
                ast.keyword(
                    arg="used_args",
                    value=ast.List(
                        elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in used_args],
                        ctx=ast.Load(),
                    ),
                ),
                ast.keyword(
                    arg="iter_args",
                    value=ast.List(
                        elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in iter_args],
                        ctx=ast.Load(),
                        ),
                    ),
                    ast.keyword(
                        arg="iter_arg_names",
                        value=ast.List(
                            elts=[ast.Constant(value=arg) for arg in iter_args],
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

    def create_loop_call(self, func_name, iter_args):
        """
        Assigns the returned value from the loop function directly (without a tuple unpacking).
        """
        if len(iter_args) == 0:
            return ast.Expr(value=ast.Name(id=func_name, ctx=ast.Load()))
        elif len(iter_args) == 1:
            return ast.Assign(
                targets=[ast.Name(id=iter_args[0], ctx=ast.Store())],
                value=ast.Name(id=func_name, ctx=ast.Load()),
            )
        else:
            return ast.Assign(
                targets=[
                    ast.Tuple(
                        elts=[ast.Name(id=var, ctx=ast.Store()) for var in iter_args],
                        ctx=ast.Store(),
                    )
                ],
                value=ast.Name(id=func_name, ctx=ast.Load()),
            )

    def is_supported_range_call(self, node):
        return (
            isinstance(node, ast.For)
            and isinstance(node.iter, ast.Call)
            and (
                (
                    isinstance(node.iter.func, ast.Name)
                    and node.iter.func.id in self.SUPPORTED_FOR_RANGE_STATEMENTS
                )
                or (
                    isinstance(node.iter.func, ast.Attribute)
                    and node.iter.func.attr in self.SUPPORTED_FOR_RANGE_STATEMENTS
                )
            )
        )

    def get_loop_constexpr(self, node):
        if not self.is_supported_range_call(node):
            return None

        # Map function names to their constexpr values
        constexpr_map = {"range": None, "range_dynamic": False, "range_constexpr": True}
        range_name = (
            node.iter.func.id
            if isinstance(node.iter.func, ast.Name)
            else node.iter.func.attr
        )
        return ast.Constant(value=constexpr_map[range_name])

    def transform_for_loop(self, node, active_symbols):
        # Constexpr doesn't get preprocessed
        if self.is_node_constexpr(node):
            self.generic_visit(node)
            return node

        # We only support range, range_constexpr, range_dynamic
        if self.is_supported_range_call(node):
            constexpr_val = self.get_loop_constexpr(node)
            # Check for early exit and raise exception
            self.check_early_exit(node, "for")
            start, stop, step = self.extract_range_args(node.iter)
            unroll, unroll_full = self.extract_unroll_args(node.iter)
            used_args, iter_args, flat_args = self.analyze_region_variables(
                node, active_symbols
            )

            func_name = f"loop_body_{self.counter}"
            self.counter += 1

            func_def = self.create_loop_function(
                func_name,
                node,
                start,
                stop,
                step,
                unroll,
                unroll_full,
                used_args,
                iter_args,
                flat_args,
                constexpr_val,
            )

            assign = ast.copy_location(
                self.create_loop_call(func_name, iter_args), node
            )

            # This should work fine as it modifies the AST structure
            return [func_def, assign]

        self.generic_visit(node)

        return node

    def visit_BoolOp(self, node):
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
            helper_func = ast.Name(id="and_", ctx=ast.Load())
        # Transform "or" to "or_"
        elif isinstance(node.op, ast.Or):
            # Create an if-else statement in AST form
            # if type(lhs) == bool and lhs == True:
            #     return lhs
            # else
            #     return or_(lhs, rhs)
            short_circuit_value = ast.Constant(value=True)
            helper_func = ast.Name(id="or_", ctx=ast.Load())
        else:
            # BoolOp should be either And or Or
            raise DSLAstPreprocessorError(
                f"Unsupported boolean operation: {node.op}",
                filename=self.file_name,
                snippet=ast.unparse(node),
            )

        def short_circuit_eval(value, short_circuit_value):
            return ast.BoolOp(
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
            )

        lhs = node.values[0]

        for i in range(1, len(node.values)):
            test = short_circuit_eval(lhs, short_circuit_value)
            lhs = ast.IfExp(
                test=test,
                body=lhs,
                orelse=ast.Call(
                    func=helper_func,
                    args=[lhs, node.values[i]],
                    keywords=[],
                ),
            )

        return ast.copy_location(lhs, node)

    def visit_UnaryOp(self, node):
        # Visit child nodes first
        self.generic_visit(node)

        # Transform "not" to "~" as we overload __invert__
        if isinstance(node.op, ast.Not):
            func_name = ast.Name(id="not_", ctx=ast.Load())
            return ast.copy_location(
                ast.Call(func=func_name, args=[node.operand], keywords=[]), node
            )

        return node

    def visit_For(self, node):
        active_symbols = self.scope_manager.get_active_symbols()
        self.scope_manager.enter_scope()

        if isinstance(node.target, ast.Name):
            self.scope_manager.add_to_scope(node.target.id)

        new_for_node = self.transform_for_loop(node, active_symbols)
        self.scope_manager.exit_scope()
        return new_for_node

    def visit_Name(self, node):
        self.generic_visit(node)
        return node

    def visit_Assert(self, node):
        test = self.visit(node.test)

        args = [ast.keyword(arg="test", value=test)]
        if node.msg:
            msg = self.visit(node.msg)
            args.append(ast.keyword(arg="msg", value=msg))

        # Rewrite to assert_executor(test, msg)
        new_node = ast.Expr(
            ast.Call(
                func=ast.Name(id=self.ASSERT_EXECUTOR, ctx=ast.Load()),
                args=[],
                keywords=args,
            )
        )

        # Propagate line number from original node to new node
        ast.copy_location(new_node, node)
        return new_node

    def visit_Call(self, node):
        func = node.func
        self.generic_visit(node)

        # Check if the function is 'bool'
        if isinstance(func, ast.Name) and func.id == "bool":
            return ast.copy_location(
                ast.Call(
                    func=ast.Name(id=self.BOOL_CAST, ctx=ast.Load()),
                    args=[node.args[0]],
                    keywords=[],
                ),
                node,
            )
        elif isinstance(func, ast.Attribute) and isinstance(func.value, ast.Name):
            def create_downcast_call(arg):
                return ast.copy_location(
                    ast.Call(
                        func=ast.Name(
                            id=self.IMPLICIT_DOWNCAST_NUMERIC_TYPE, ctx=ast.Load()
                        ),
                        args=[arg],
                        keywords=[],
                    ),
                    arg,
                )
            module = self.function_globals.get(func.value.id)
            if isinstance(module, ModuleType) and module.__package__.endswith(
                "._mlir.dialects"
            ):
                # Check if argument is Numeric, if so, call ir_value()
                args = []
                for arg in node.args:
                    args.append(create_downcast_call(arg))
                kwargs = []
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

        return node

    def visit_ClassDef(self, node):
        self.class_name = node.name
        self.generic_visit(node)
        self.class_name = None
        return node

    def _visit_target(self, target):
        if isinstance(target, ast.Name):
            self.scope_manager.add_to_scope(target.id)
        elif isinstance(target, ast.Tuple):
            for t in target.elts:
                if isinstance(t, ast.Name):
                    self.scope_manager.add_to_scope(t.id)

    def visit_Assign(self, node):
        for target in node.targets:
            self._visit_target(target)
        self.generic_visit(node)
        return node

    def visit_AugAssign(self, node):
        self._visit_target(node.target)
        self.generic_visit(node)
        return node

    def check_decorator(self, node: ast.AST) -> bool:
        """
        Check if the function has the correct decorator for preprocessing.
        """
        if not isinstance(node, ast.FunctionDef):
            return False
        decorator_list = node.decorator_list
        if len(decorator_list) == 0:
            return False

        for d in decorator_list:
            if isinstance(d, ast.Call):
                if isinstance(d.func, ast.Attribute):
                    if d.func.attr in ["jit", "kernel"]:
                        if d.keywords == []:
                            return True
                        for keyword in d.keywords:
                            if keyword.arg == "preprocess":
                                try:
                                    if isinstance(keyword.value, ast.Constant):
                                        return keyword.value.value
                                    else:
                                        return ast.literal_eval(keyword.value)
                                except:
                                    pass

            elif isinstance(d, ast.Attribute):
                if d.attr in ["jit", "kernel"]:
                    return True

        return False

    def remove_dsl_decorator(self, decorator_list):
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

    def visit_FunctionDef(self, node):
        self.scope_manager.enter_scope()
        self.function_counter += 1
        self.function_name = node.name
        if self.function_depth > 0:
            self.local_closures.add(node.name)

        self.function_depth += 1

        # Add function name and arguments
        self.scope_manager.add_to_scope(node.name)
        for arg in node.args.args:
            self.scope_manager.add_to_scope(arg.arg)

        self.generic_visit(node)
        self.scope_manager.exit_scope()

        self.function_depth -= 1

        # Remove .jit and .kernel decorators
        node.decorator_list = self.remove_dsl_decorator(node.decorator_list)
        return node

    def visit_With(self, node):
        self.scope_manager.enter_scope()

        for item in node.items:
            if isinstance(item.optional_vars, ast.Name):
                self.scope_manager.add_to_scope(item.optional_vars.id)
        self.generic_visit(node)

        self.scope_manager.exit_scope()
        return node

    def visit_While(self, node):
        active_symbols = self.scope_manager.get_active_symbols()
        self.scope_manager.enter_scope()

        # Constexpr doesn't get preprocessed
        if self.is_node_constexpr(node):
            self.generic_visit(node)
            self.scope_manager.exit_scope()
            return node

        # Check for early exit and raise exception
        self.check_early_exit(node, "while")

        used_args, yield_args, flat_args = self.analyze_region_variables(
            node, active_symbols
        )
        func_name = f"while_region_{self.counter}"
        self.counter += 1

        func_def = self.create_while_function(
            func_name, node, used_args, yield_args, flat_args
        )
        assign = ast.copy_location(self.create_loop_call(func_name, yield_args), node)

        self.scope_manager.exit_scope()
        return [func_def, assign]

    def visit_Try(self, node):
        self.scope_manager.enter_scope()
        self.generic_visit(node)
        self.scope_manager.exit_scope()
        return node

    def visit_ExceptHandler(self, node):
        self.scope_manager.enter_scope()
        if node.name:  # Exception variable
            self.scope_manager.add_to_scope(node.name)
        self.generic_visit(node)
        self.scope_manager.exit_scope()
        return node

    def create_if_call(self, func_name, yield_args, flat_args):
        """Creates the assignment statement for the if function call"""
        if not yield_args:
            return ast.Expr(value=ast.Name(id=func_name, ctx=ast.Load()))
        elif len(yield_args) == 1:
            return ast.Assign(
                targets=[ast.Name(id=yield_args[0], ctx=ast.Store())],
                value=ast.Name(id=func_name, ctx=ast.Load()),
            )
        else:
            return ast.Assign(
                targets=[
                    ast.Tuple(
                        elts=[ast.Name(id=var, ctx=ast.Store()) for var in yield_args],
                        ctx=ast.Store(),
                    )
                ],
                value=ast.Name(id=func_name, ctx=ast.Load()),
            )

    def visit_IfExp(self, node):
        """
        Visits an inline if-else expression (ternary operator).
        This is the Python equivalent of `x if condition else y`.
        """
        # Check if the condition is constexpr
        constexpr_val, test = self.is_constexpr(node)

        node.test = test
        node.body = self.visit(node.body)
        node.orelse = self.visit(node.orelse)

        # If it's a constexpr node, we don't need to transform it
        if constexpr_val.value is True:
            return node

        # Emit
        # node if type(pred) == bool else select_(pred, body, orelse)
        # so if pred is a python bool, use python to short-circuit and avoid emit arith.select
        return ast.copy_location(
            ast.IfExp(
                test=ast.Compare(
                    left=ast.Call(
                        func=ast.Name(id="type", ctx=ast.Load()),
                        args=[node.test],
                        keywords=[],
                    ),
                    ops=[ast.Eq()],
                    comparators=[ast.Name(id="bool", ctx=ast.Load())],
                ),
                body=node,  # Original ternary expression
                orelse=ast.Call(
                    func=ast.Name(id="select_", ctx=ast.Load()),
                    args=[
                        node.test,
                        node.body,
                        node.orelse,
                    ],
                    keywords=[],
                ),
            ),
            node,
        )

    def visit_If(self, node):
        active_symbols = self.scope_manager.get_active_symbols()
        self.scope_manager.enter_scope()

        # Constexpr doesn't get preprocessed
        if self.is_node_constexpr(node):
            self.generic_visit(node)
            self.scope_manager.exit_scope()
            return node

        # Check for early exit and raise exception
        self.check_early_exit(node, "if")

        used_args, yield_args, flat_args = self.analyze_region_variables(
            node, active_symbols
        )
        func_name = f"if_region_{self.counter}"
        self.counter += 1

        func_def = self.create_if_function(
            func_name, node, used_args, yield_args, flat_args
        )
        assign = ast.copy_location(
            self.create_if_call(func_name, yield_args, flat_args), node
        )

        self.scope_manager.exit_scope()
        return [func_def, assign]

    def is_constexpr(self, node):
        """Determines if the if condition is wrapped in const_expr or dynamic_expr"""
        if isinstance(node.test, ast.Call):
            func = node.test.func

            # Check if the function is 'const_expr'
            if isinstance(func, ast.Name) and func.id == "const_expr":
                return ast.Constant(value=True), node.test.args[0]

            # Check if the function is 'dynamic_expr'
            elif isinstance(func, ast.Name) and func.id == "dynamic_expr":
                return ast.Constant(value=False), self.visit(node.test.args[0])

            # Check if it's an attribute access for 'const_expr' or 'dynamic_expr'
            elif isinstance(func, ast.Attribute):
                if func.attr == "const_expr":
                    return ast.Constant(value=True), node.test.args[0]
                elif func.attr == "dynamic_expr":
                    return ast.Constant(value=False), self.visit(node.test.args[0])

        return ast.Constant(value=None), self.visit(node.test)

    def create_if_function(
        self, func_name, node, used_args, yield_args, flattened_args
    ):
        is_constexpr, test_expr = self.is_constexpr(node)
        pred_name = self.make_func_param_name("pred", flattened_args)
        func_args = [ast.arg(arg=pred_name, annotation=None)]
        func_args += [ast.arg(arg=var, annotation=None) for var in flattened_args]
        func_args_then_else = [
            ast.arg(arg=var, annotation=None) for var in flattened_args
        ]

        then_body = []
        for stmt in node.body:
            transformed_stmt = self.visit(stmt)  # Recursively visit inner statements
            if isinstance(transformed_stmt, list):
                then_body.extend(transformed_stmt)
            else:
                then_body.append(transformed_stmt)

        # Create common return list for all blocks
        return_list = ast.List(
            elts=[ast.Name(id=var, ctx=ast.Load()) for var in yield_args],
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

        then_block_name = f"then_block_{self.counter}"
        else_block_name = f"else_block_{self.counter}"
        elif_region_name = f"elif_region_{self.counter}"
        self.counter += 1

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
                arg="used_args",
                value=ast.List(
                    elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in used_args],
                    ctx=ast.Load(),
                ),
            ),
            ast.keyword(
                arg="yield_args",
                value=ast.List(
                    elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in yield_args],
                    ctx=ast.Load(),
                ),
            ),
        ]

        # Create decorator
        decorator = ast.copy_location(
            ast.Call(
                func=ast.Name(id=self.DECORATOR_IF_STATEMENT, ctx=ast.Load()),
                args=[],
                keywords=decorator_keywords,
            ),
            node,
        )

        # Executor keywords
        execute_keywords = [
            ast.keyword(arg="pred", value=ast.Name(id=pred_name, ctx=ast.Load())),
            ast.keyword(
                arg="used_args",
                value=ast.List(
                    elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in used_args],
                    ctx=ast.Load(),
                ),
            ),
            ast.keyword(
                arg="yield_args",
                value=ast.List(
                    elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in yield_args],
                    ctx=ast.Load(),
                ),
            ),
            ast.keyword(
                arg="yield_arg_names",
                value=ast.List(
                    elts=[ast.Constant(value=arg) for arg in yield_args],
                    ctx=ast.Load(),
                ),
            ),
            ast.keyword(
                arg="then_block", value=ast.Name(id=then_block_name, ctx=ast.Load())
            ),
        ]

        # Handle different cases
        if not yield_args and node.orelse == []:
            # No yield_args case - only then_block needed
            execute_call = ast.copy_location(
                ast.Call(
                    func=ast.copy_location(
                        ast.Name(id=self.IF_EXECUTOR, ctx=ast.Load()), node
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
                    # Recursion for nested elif
                    nested_if = self.create_if_function(
                        nested_if_name, elif_node, used_args, yield_args, flattened_args
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

                    else_body = []
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
            # Add constexpr
            execute_keywords.append(ast.keyword(arg="constexpr", value=is_constexpr))

            execute_call = ast.copy_location(
                ast.Call(
                    func=ast.Name(id=self.IF_EXECUTOR, ctx=ast.Load()),
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
        self, func_name, node, used_args, yield_args, flattened_args
    ):
        """Create a while function that looks like:

        @while_selector(pred, used_args=[], yield_args=[])
        def while_region(pred, flattened_args):
            def while_before_block(*used_args, *yield_args):
                # Note that during eval of pred can possibly alter yield_args
                return *pred, yield_args
            def while_after_block(*used_args, yield_args):
                ...loop_body_transformed...
                return yield_args
            return self.while_executor(pred, used_args, yield_args,
                while_before_block, while_after_block, constexpr)
        yield_args = while_region(pred, flattened_args)

        Which will later be executed as psuedo-code:

        # Dynamic mode:
        scf.WhileOp(types(yield_args), yield_args)
        with InsertionPoint(before_block):
            cond, yield_args = while_before_block(*flattened_args)
            scf.ConditionOp(cond, yield_args)
        with InsertionPoint(after_block):
            yield_args = while_after_block(yield_args)
            scf.YieldOp(yield_args)
        return while_op.results_

        # Const mode:
        cond, yield_args = while_before_block(yield_args)
        while pred:
            yield_args = body_block(yield_args)
            cond, yield_args = while_before_block(yield_args)
        return yield_args
        """
        is_constexpr, test_expr = self.is_constexpr(node)
        pred_name = self.make_func_param_name("pred", flattened_args)

        # Section: decorator construction
        decorator_keywords = [
            ast.keyword(arg="pred", value=test_expr),
            ast.keyword(
                arg="used_args",
                value=ast.List(
                    elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in used_args],
                    ctx=ast.Load(),
                ),
            ),
            ast.keyword(
                arg="yield_args",
                value=ast.List(
                    elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in yield_args],
                    ctx=ast.Load(),
                ),
            ),
        ]
        decorator = ast.copy_location(
            ast.Call(
                func=ast.Name(id=self.DECORATOR_WHILE_STATEMENT, ctx=ast.Load()),
                args=[],
                keywords=decorator_keywords,
            ),
            node,
        )

        # Section: Shared initialization for before and after blocks
        while_before_block_name = f"while_before_block_{self.counter}"
        while_after_block_name = f"while_after_block_{self.counter}"
        self.counter += 1
        block_args_args = [ast.arg(arg=var, annotation=None) for var in used_args]
        block_args_args += [ast.arg(arg=var, annotation=None) for var in yield_args]
        block_args = ast.arguments(
            posonlyargs=[],
            args=block_args_args,
            kwonlyargs=[],
            kw_defaults=[],
            defaults=[],
        )

        yield_args_ast_name_list = ast.List(
            elts=[ast.Name(id=var, ctx=ast.Load()) for var in yield_args],
            ctx=ast.Load(),
        )

        # Section: while_before_block FunctionDef, which contains condition
        while_before_return_list = ast.List(
            elts=[test_expr, yield_args_ast_name_list],
            ctx=ast.Load(),
        )
        while_before_stmts = [ast.Return(value=while_before_return_list)]
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
        while_after_stmts = []
        for stmt in node.body:
            transformed_stmt = self.visit(stmt)  # Recursively visit inner statements
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
            ast.keyword(arg="pred", value=ast.Name(id=pred_name, ctx=ast.Load())),
            ast.keyword(
                arg="used_args",
                value=ast.List(
                    elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in used_args],
                    ctx=ast.Load(),
                ),
            ),
            ast.keyword(
                arg="yield_args",
                value=ast.List(
                    elts=[ast.Name(id=arg, ctx=ast.Load()) for arg in yield_args],
                    ctx=ast.Load(),
                ),
            ),
            ast.keyword(
                arg="while_before_block",
                value=ast.Name(id=while_before_block_name, ctx=ast.Load()),
            ),
            ast.keyword(
                arg="while_after_block",
                value=ast.Name(id=while_after_block_name, ctx=ast.Load()),
            ),
            ast.keyword(arg="constexpr", value=is_constexpr),
            ast.keyword(
                arg="yield_arg_names",
                value=ast.List(
                    elts=[ast.Constant(value=arg) for arg in yield_args],
                    ctx=ast.Load(),
                ),
            ),
        ]

        execute_call = ast.Call(
            func=ast.Name(id=self.WHILE_EXECUTOR, ctx=ast.Load()),
            args=[],
            keywords=execute_keywords,
        )

        # Putting everything together, FunctionDef for while_region
        func_args_args = [ast.arg(arg=pred_name, annotation=None)]
        func_args_args += [ast.arg(arg=var, annotation=None) for var in flattened_args]
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
