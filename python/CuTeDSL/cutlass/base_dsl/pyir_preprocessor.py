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
from collections.abc import Generator
from copy import deepcopy
from dataclasses import dataclass, field
from typing_extensions import override

from .ast_preprocessor import (
    DSLPreprocessor,
    ScopeManager,
    _create_module_attribute,
    _deepcopy_ast_root,
    SessionData,
)
from .common import DSLUserCodeError
from .diagnostics import DiagId


def _unparse_safe(node: ast.AST) -> str:
    """Best-effort ``ast.unparse`` -- falls back to the node class name
    when unparse trips on a synthetic node missing source attributes.
    """
    try:
        return ast.unparse(node)
    except Exception:
        return type(node).__name__


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


class PyIRDSLPreprocessor(DSLPreprocessor):
    """
    A DSL preprocessor with PyIR-specific transformations.

    This derived class adds PyIR instrumentation for:
    - Maintaining SSA form through pyir_read/pyir_assign operations
    - Scope isolation for const_expr control flow
    - Attribute read instrumentation to prevent reference leakage
    - Tuple unpacking decomposition
    """

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

    @override
    def _create_lambda_check_call(
        self, called_value_symbols: list[str], node: ast.stmt
    ) -> ast.Expr | None:
        # Emit ``lambda_capture_check([names...])`` at staged-region entry.
        # A raw lambda invoked in the region reads its captures from the
        # ENCLOSING frame, not the region's loop-carried slots (pyir's ref
        # mechanism does not reach an un-preprocessed lambda body), so a
        # captured meta mutated inside the region would freeze at its
        # first-pass value — a silent miscompile. The check rejects that at
        # trace time (non-lambdas/jit-lambdas/region-local lambdas pass).
        #
        # This override lives ONLY on the PyIR subclass (instantiated only when
        # pyir is enabled, see preprocess_mode). The base returns None, so
        # non-pyir compilation emits a byte-identical region with no
        # lambda_capture_check call — pyir-gated by construction.
        if not called_value_symbols:
            return None
        return ast.Expr(
            ast.Call(
                func=_create_module_attribute(
                    "lambda_capture_check",
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    ast.List(
                        elts=[
                            ast.Name(id=c, ctx=ast.Load()) for c in called_value_symbols
                        ],
                        ctx=ast.Load(),
                    )
                ],
                keywords=[],
            )
        )

    def visit_With(self, node: ast.With) -> ast.AST:
        # Base handling first: register optional-vars in scope + recurse into
        # children. Then wrap each context-manager expression in the trace-time
        # guard ``with_ctxmgr_check`` so a ``with`` whose __enter__/__exit__ are
        # raw-Python user dunders is rejected inside staged CF (their effects
        # would run once at trace time and freeze — a silent miscompile).
        #
        # This override lives ONLY on the PyIR subclass, which the DSL
        # instantiates exclusively when pyir is enabled (see preprocess_mode).
        # The base ``DSLPreprocessor.visit_With`` is untouched, so non-pyir
        # compilation emits a byte-identical plain ``with`` — the wrapping is
        # pyir-gated by construction, no runtime flag needed. Decorated /
        # DSL-internal / stdlib managers pass through unchanged at run time.
        visited = super().visit_With(node)
        with_node = visited if isinstance(visited, ast.With) else None
        if with_node is None:
            return visited
        for item in with_node.items:
            ctx = item.context_expr
            item.context_expr = ast.copy_location(
                ast.Call(
                    func=_create_module_attribute(
                        "with_ctxmgr_check",
                        submodule_name="pyir_runtime",
                        lineno=getattr(ctx, "lineno", None),
                        col_offset=getattr(ctx, "col_offset", None),
                    ),
                    args=[ctx],
                    keywords=[],
                ),
                ctx,
            )
        return with_node

    def _visit_stmts_in_cf_scope_and_collect_definitions(
        self, stmts: list[ast.stmt]
    ) -> tuple[list[ast.stmt], set[str]]:
        """Visit an isolated const_expr scope and return its definitions.

        Used when visiting bodies of ``const_expr`` if/for/while — meta-level
        control flow where only one branch executes at runtime.

        The scope isolation prevents this bug::

            if const_expr(False):
                cfg = make_a()   # (1) adds 'cfg' to scope during AST visit
            else:
                cfg = make_b()   # (2) without isolation, sees 'cfg' in scope
                                 #     → wraps with pyir_assign(pyir_read(cfg))
                                 #     → UnboundLocalError at runtime because
                                 #       the if-branch never ran

        With isolation, each branch gets its own scope. 'cfg' from (1) is
        discarded before visiting (2), so (2) is correctly treated as a
        first-definition (no pyir instrumentation).

        Outer-scope variables still work::

            x = Int32(0)              # x in outer scope
            if const_expr(True):
                x = Int32(42)         # reassignment — outer x IS visible,
                                      #   so pyir_assign IS emitted (correct)
        """
        with self.session_data.scope_manager.enter_control_flow_scope():
            result: list[ast.stmt] = []
            for stmt in stmts:
                visited = self.visit(stmt)
                if isinstance(visited, list):
                    result.extend(visited)
                elif visited is not None:
                    result.append(visited)
            definitions = set(self.session_data.scope_manager.scopes[-1])
        return result, definitions

    def _visit_stmts_in_cf_scope(self, stmts: list[ast.stmt]) -> list[ast.stmt]:
        """Visit statements in an isolated const_expr scope."""
        result, _ = self._visit_stmts_in_cf_scope_and_collect_definitions(stmts)
        return result

    def _handle_constexpr_for(self, node: ast.For) -> ast.For | list[ast.stmt]:
        """Override to add PyIR scope isolation for const_expr loops, and
        to bracket the body with ``enter_constexpr_loop()`` /
        ``exit_constexpr_loop()`` calls so the M->M and container-
        mutation guards know the body is trace-time-unrolled (not
        loop-carried) even when the enclosing CF is dynamic.
        """
        # Visit loop body in its own scope so first-definitions inside
        # the body don't leak into the outer scope (PyIR only).
        node.body = self._visit_stmts_in_cf_scope(node.body)

        # Wrap the unrolled body: enter; try: body; finally: exit.  The
        # per-iteration bracket keeps the constexpr scope open inside the
        # body, with break / return / exception safety.
        node.body = self._wrap_body_in_constexpr_scope(node, node.body)
        return node

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
                                name,
                                submodule_name="multi_stage_manager",
                                lineno=lineno,
                                col_offset=col_offset,
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
    # their enclosing user function's scope so a loop-carried local (threaded
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

    def _wrap_body_in_fn_scope(
        self, node: ast.stmt, body: list[ast.stmt]
    ) -> list[ast.stmt]:
        """Bracket a USER function body with ``pyir_function_scope(<id>)`` /
        ``pyir_function_scope()`` so frame-local slot keys are qualified by the owning
        user function (preventing same-named locals in two different functions
        from colliding on one ``pyir.ref``).  ``<id>`` is ``id(node)`` -- unique
        per ``FunctionDef`` and stable for the preprocessing pass."""
        if not body:
            return body

        lineno = node.lineno
        col_offset = node.col_offset

        withStmt = ast.With(
            items=[
                ast.withitem(
                    context_expr=ast.Call(
                        func=_create_module_attribute(
                            "pyir_function_scope",
                            submodule_name="pyir_runtime",
                            lineno=lineno,
                            col_offset=col_offset,
                        ),
                        args=[ast.Constant(value=id(node))],
                        keywords=[],
                    ),
                    optional_vars=None,
                )
            ],
            body=body,
        )
        return [ast.copy_location(ast.fix_missing_locations(withStmt), node)]

    @override
    def visit_FunctionDef(self, node: ast.FunctionDef) -> ast.FunctionDef:
        """Wrap USER function bodies so local slot keys are unique per user function.
        Generated loop / branch helper functions are skipped -- they inherit the
        enclosing user scope."""
        result = super().visit_FunctionDef(node)
        if isinstance(result, ast.FunctionDef) and not result.name.startswith(
            self._GENERATED_FN_PREFIXES
        ):
            result.body = self._wrap_body_in_fn_scope(result, result.body)
        return result

    def _prepare_loop_induction_var(self, node: ast.For) -> None:
        """Override to mark induction variable for skip instrumentation.

        Mark the induction variable so _handle_negative_step's injected
        `idx = offset - idx if isNeg else idx` is not instrumented.
        Creating a reference for the block argument would cause issues.
        """
        if isinstance(node.target, ast.Name):
            self.session_data.scope_manager.add_skip_reference_taking(node.target.id)

    def _cleanup_loop_induction_var(self, node: ast.For) -> None:
        """Override to remove skip flag after loop function creation."""
        if isinstance(node.target, ast.Name):
            self.session_data.scope_manager.remove_skip_reference_taking(node.target.id)

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
        if isinstance(target, ast.Tuple):
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
        not need PyIR SSA threading.
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
    def _names_read_before_and_after_walrus(node: ast.AST) -> set[str]:
        """Names ``X`` read BOTH before AND after the same-statement walrus
        ``(X := ...)`` (outside the walrus subtree).  Such a name is
        UN-ANCHORABLE: element0 wants the pre-walrus value and a later element
        wants the post-walrus value from ONE ``X``.  ``a, b, c = m1, (m1 :=
        m1+1), m1`` silently miscompiled the mismatched read (verified on this
        base), so these shapes are refused loudly instead.  Self-contained AST
        scan (same-statement, positional, walrus-RHS reads excluded)."""
        walrus_pos: dict[str, tuple[int, int]] = {}
        for sub in ast.walk(node):
            if isinstance(sub, ast.NamedExpr) and isinstance(sub.target, ast.Name):
                pos = (sub.lineno, sub.col_offset)
                tgt = sub.target.id
                if tgt not in walrus_pos or pos < walrus_pos[tgt]:
                    walrus_pos[tgt] = pos
        if not walrus_pos:
            return set()
        loads: dict[str, list[tuple[int, int]]] = {}

        def _scan(n: ast.AST, in_walrus: bool) -> None:
            child_in_walrus = in_walrus or isinstance(n, ast.NamedExpr)
            if (
                isinstance(n, ast.Name)
                and isinstance(n.ctx, ast.Load)
                and n.id in walrus_pos
                and not in_walrus
            ):
                loads.setdefault(n.id, []).append((n.lineno, n.col_offset))
            for child in ast.iter_child_nodes(n):
                _scan(child, child_in_walrus)

        _scan(node, False)
        both: set[str] = set()
        for name, w_pos in walrus_pos.items():
            positions = loads.get(name)
            if (
                positions
                and any(p < w_pos for p in positions)
                and any(p > w_pos for p in positions)
            ):
                both.add(name)
        return both

    def visit_Assign(self, node: ast.Assign) -> ast.stmt | list[ast.stmt]:
        """Override to add PyIR instrumentation for reassignments."""
        # A walrus-target name read on BOTH sides of its walrus in a tuple RHS
        # is un-anchorable and silently miscompiled the mismatched read (fresh-
        # Name AND subscript targets).  Scoped to a Tuple target so the
        # positional before/after test matches left-to-right RHS evaluation (a
        # ternary/boolop RHS has positional != eval order).
        _walrus_both = self._names_read_before_and_after_walrus(node)
        if _walrus_both:
            for _tgt in node.targets:
                if isinstance(_tgt, ast.Tuple):
                    raise DSLUserCodeError(
                        DiagId.UNSUP_WALRUS_TUPLE_REBIND,
                        filename=self.session_data.file_name,
                        lineno=node.lineno,
                        col_offset=node.col_offset,
                        end_col_offset=getattr(node, "end_col_offset", None),
                        var=sorted(_walrus_both)[0],
                    )
        # Check scope BEFORE _visit_target adds the target.
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
        for t in node.targets:
            if isinstance(t, ast.Tuple) and not self._is_target_in_scope(t):
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
        # For tuple targets, snapshot which elements are in scope NOW,
        # before _visit_target adds first-definitions to scope.
        # Use a dict keyed by id(target) so each tuple target gets its
        # own snapshot — this is needed for multi-target assignments
        # like ``(a, b) = (c, d) = expr``.
        tuple_scope_snapshots: dict[int, set[int]] = {}
        for t in targets_to_instrument:
            if isinstance(t, ast.Tuple):
                tuple_scope_snapshots[id(t)] = {
                    i for i, elt in enumerate(t.elts) if self._is_element_in_scope(elt)
                }

        for target in node.targets:
            self._visit_target(target)
        self.generic_visit(node)

        tuple_targets = [t for t in targets_to_instrument if isinstance(t, ast.Tuple)]
        subscript_targets = [
            t for t in targets_to_instrument if isinstance(t, ast.Subscript)
        ]
        scalar_targets = [
            t
            for t in targets_to_instrument
            if not isinstance(t, (ast.Tuple, ast.Subscript))
        ]

        non_empty = sum(
            1 for group in (tuple_targets, subscript_targets, scalar_targets) if group
        )
        if non_empty > 1:
            raise DSLUserCodeError(
                DiagId.UNSUP_MIXED_ASSIGN_TARGETS,
                filename=self.session_data.file_name,
            )

        if tuple_targets:
            # Evaluate the RHS into a shared temp once, then decompose
            # each tuple target using its own per-target scope snapshot.
            all_stmts: list[ast.stmt] = []
            shared_tmp: str | None = None
            for tt in tuple_targets:
                snapshot = tuple_scope_snapshots[id(tt)]
                result = self._decompose_tuple_assign(
                    node, tt, snapshot, rhs_temp_name=shared_tmp
                )
                if isinstance(result, list):
                    all_stmts.extend(result)
                else:
                    # Starred or no instrumented elements — keep original
                    all_stmts.append(result)
                # After the first target creates the temp, reuse it.
                if shared_tmp is None and isinstance(result, list):
                    # The temp name is _pyir_tmp_N; find it from the
                    # statements emitted by _decompose_tuple_assign.
                    for s in result:
                        if (
                            isinstance(s, ast.Assign)
                            and len(s.targets) == 1
                            and isinstance(s.targets[0], ast.Name)
                            and s.targets[0].id.startswith("_pyir_tmp_")
                        ):
                            shared_tmp = s.targets[0].id
                            break
            return all_stmts if all_stmts else node

        if subscript_targets:
            exclude = {self._target_to_path_str(t) for t in subscript_targets}
            # Same ordering invariant as scalar_targets above: collect RHS
            # reads first so the subscript-assign sees rewritten reads.
            rhs_call_func_ids = self._collect_call_func_ids(node.value)
            self_reads = self._collect_attr_reads(
                node.value, exclude, rhs_call_func_ids
            )
            other_reads = self._collect_other_attr_reads(
                node.value, exclude, rhs_call_func_ids
            )
            prologue_reads: list[ast.stmt] | None = None
            if self_reads or other_reads:
                attr_read_result = self._insert_pyir_attr_reads(node, exclude)
                if isinstance(attr_read_result, list):
                    prologue_reads = attr_read_result
            sub_result = self._insert_pyir_subscript_assign(node, subscript_targets[0])
            if isinstance(sub_result, list) and prologue_reads is not None:
                return prologue_reads[:-1] + sub_result
            return sub_result

        if scalar_targets:
            exclude = {self._target_to_path_str(t) for t in scalar_targets}
            # Run attr-read instrumentation FIRST so node.value's reads are
            # rewritten to _pyir_attr_N locals BEFORE _insert_pyir_assign
            # deepcopies node into its hasattr branches.  Without this, both
            # ``self._x = self._x + 1`` (covered by ``_collect_attr_reads``)
            # and ``obj = Cls(obj.x + 1)`` rebinding patterns (covered by
            # ``_collect_other_attr_reads``) keep the raw attribute access
            # in the RHS and bypass the read.
            rhs_call_func_ids = self._collect_call_func_ids(node.value)
            self_reads = self._collect_attr_reads(
                node.value, exclude, rhs_call_func_ids
            )
            other_reads = self._collect_other_attr_reads(
                node.value, exclude, rhs_call_func_ids
            )
            prologue_reads = None
            if self_reads or other_reads:
                attr_read_result = self._insert_pyir_attr_reads(node, exclude)
                if isinstance(attr_read_result, list):
                    prologue_reads = attr_read_result
            result = self._insert_pyir_assign(node, scalar_targets)
            if isinstance(result, list) and prologue_reads is not None:
                return prologue_reads[:-1] + result
            return result

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

    def visit_Delete(self, node: ast.Delete) -> ast.stmt | list[ast.stmt]:
        """Reject ``del`` of a LOOP-CARRIED local inside control flow.

        A name defined BEFORE the enclosing for/while/if carries a value into
        the region; ``del``'ing it mid-body drops that carry (the following
        rebind is a body-local first-def with no pre-region init), so the next
        read has no value -- baseline raises a raw ``NameError``.  Refuse with a
        curated, del-aware diagnostic instead.  A name present only in the
        INNERMOST region scope was defined inside the region (a trace-time temp)
        and deleting it is benign -> pass, constexpr-unrolled or dynamic.  A
        top-level ``del`` and a skip-reference name (loop induction var) pass.
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
        return node

    def visit_AugAssign(self, node: ast.AugAssign) -> ast.AugAssign | list[ast.stmt]:
        """Override to add PyIR instrumentation for augmented assignments."""
        self._visit_target(node.target)
        self.generic_visit(node)

        # Skip pyir instrumentation for excluded variables (e.g. induction vars)
        if isinstance(
            node.target, ast.Name
        ) and self.session_data.scope_manager.is_skip_reference_taking(node.target.id):
            return node
        target_path = self._target_to_path_str(node.target)

        if isinstance(node.target, ast.Subscript):
            if self._is_subscript_skippable(node.target):
                return node
            result = self._insert_pyir_subscript_augassign(node, node.target)
            attr_reads = self._collect_attr_reads(node.value, {target_path})
            if attr_reads and isinstance(result, list):
                read_stmts = self._insert_pyir_attr_reads(node, {target_path})
                if isinstance(read_stmts, list):
                    return read_stmts[:-1] + result
            return result

        result = self._insert_pyir_augassign(node)
        attr_reads = self._collect_attr_reads(node.value, {target_path})
        if attr_reads and isinstance(result, list):
            read_stmts = self._insert_pyir_attr_reads(node, {target_path})
            if isinstance(read_stmts, list):
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
            func=_create_module_attribute(
                "_pyir_post_subscript_read",
                submodule_name="pyir_runtime",
                lineno=lineno,
                col_offset=col_offset,
            ),
            args=[
                ast.Constant(value=target_name),
                deepcopy(node.value),  # container expression
                deepcopy(node.slice),  # key expression
            ],
            keywords=[],
        )
        return ast.copy_location(ast.fix_missing_locations(call), node)

    def visit_Return(self, node: ast.Return) -> ast.stmt | list[ast.stmt]:
        """Override to add PyIR instrumentation for attribute reads in returns."""
        self.generic_visit(node)
        if node.value is not None:
            return self._insert_pyir_attr_reads(node)
        return node

    # Method names whose call on a meta ``list`` / ``dict`` / ``set``
    # mutates the container in place.  When the call appears as a
    # statement inside staged CF, ``_pyir_check_no_complex_m2m_call``
    # raises a ``DSLUserCodeError`` so users see a clear diagnostic
    # instead of silent single-iteration baking.
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
        }
    )

    def visit_Expr(self, node: ast.Expr) -> ast.stmt | list[ast.stmt]:
        """Override to add PyIR instrumentation for attribute reads in
        expressions, plus a runtime mutation guard for ``a.append(...)``
        style calls on meta Python containers inside staged CF.
        """
        # Build the mutation guard BEFORE generic_visit: generic_visit rewrites
        # a subscript receiver (``d["xs"]``) into a ``_pyir_post_subscript_read``
        # Call, hiding the ``<subscript>.<mutator>`` pattern the guard matches on.
        guard = self._build_container_mutator_guard(node)
        self.generic_visit(node)
        result = self._insert_pyir_attr_reads(node)
        if guard is None:
            return result
        if isinstance(result, list):
            return [guard, *result]
        return [guard, result]

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
        # Only instrument simple container expressions; complex
        # container expressions (e.g. ``obj.field.list``) would require
        # a temporary to avoid re-evaluation and are out of scope for
        # this guard.
        if isinstance(container, (ast.Name, ast.Attribute)):
            pass
        elif isinstance(container, ast.Subscript) and not any(
            isinstance(_n, ast.Call) for _n in ast.walk(container)
        ):
            # A dict/list-held container reached one indirection deep
            # (``d["xs"].append``); accept only side-effect-free receivers so
            # re-evaluating the receiver for the guard cannot double-execute.
            pass
        else:
            return None
        return ast.copy_location(
            ast.fix_missing_locations(
                ast.Expr(
                    value=ast.Call(
                        func=_create_module_attribute(
                            "_pyir_check_no_complex_m2m_call",
                            submodule_name="pyir_runtime",
                            lineno=node.lineno,
                            col_offset=node.col_offset,
                        ),
                        args=[
                            deepcopy(container),
                            ast.Constant(value=func.attr),
                            ast.Constant(value=_unparse_safe(container)),
                            ast.Constant(value=self.session_data.file_name),
                            ast.Constant(value=node.lineno),
                        ],
                        keywords=[],
                    ),
                )
            ),
            node,
        )

    def _handle_constexpr_while(self, node: ast.While) -> list[ast.stmt]:
        """Override to add PyIR scope isolation for const_expr while loops."""
        # Visit test expression outside branch scopes.
        self.visit(node.test)
        # Visit body in its own scope so first-definitions don't leak.
        node.body = self._visit_stmts_in_cf_scope(node.body)
        # Bracket the (trace-time-unrolled) body so mutations directly
        # inside it are treated as constexpr-governed by the guards.
        node.body = self._wrap_body_in_constexpr_scope(node, node.body)
        assert isinstance(node.test, ast.Call)
        check = self._insert_cf_symbol_check(node.test.func)
        return [check, node]

    def _handle_constexpr_if(self, node: ast.If) -> list[ast.stmt]:
        """Override to add PyIR scope isolation for const_expr if statements."""
        # Visit test expression outside branch scopes.
        has_else = bool(node.orelse)
        self.visit(node.test)
        # Visit each branch in its own scope so first-definitions in one
        # branch don't leak into sibling branches (fixes UnboundLocalError
        # when only one const_expr branch runs at runtime).
        node.body, body_definitions = (
            self._visit_stmts_in_cf_scope_and_collect_definitions(node.body)
        )
        node.orelse, else_definitions = (
            self._visit_stmts_in_cf_scope_and_collect_definitions(node.orelse)
        )
        # An exhaustive if/else definitely initializes names defined by every
        # arm. Propagate only that intersection; one-sided definitions remain
        # out of scope and retain Python's possible-UnboundLocal semantics.
        if has_else:
            for name in body_definitions & else_definitions:
                self.session_data.scope_manager.add_to_scope(name)
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
        # first-definition leakage.
        has_else = bool(elif_node.orelse)
        self.visit(elif_node.test)
        elif_node.body, body_definitions = (
            self._visit_stmts_in_cf_scope_and_collect_definitions(elif_node.body)
        )
        elif_node.orelse, else_definitions = (
            self._visit_stmts_in_cf_scope_and_collect_definitions(elif_node.orelse)
        )
        # Feed definitions from a complete elif/else tail into its parent's
        # temporary branch scope. The outer if then intersects that set with
        # its own body, handling arbitrary exhaustive elif chains.
        if has_else:
            for name in body_definitions & else_definitions:
                self.session_data.scope_manager.add_to_scope(name)
        # Bracket each branch so mutations directly inside the
        # trace-time-selected branch are treated as constexpr-governed.
        elif_node.body = self._wrap_body_in_constexpr_scope(elif_node, elif_node.body)
        elif_node.orelse = self._wrap_body_in_constexpr_scope(
            elif_node, elif_node.orelse
        )
        assert isinstance(elif_node.test, ast.Call)
        return self._insert_cf_symbol_check(elif_node.test.func)

    def visit_While(self, node: ast.While) -> "ast.While | list[ast.stmt]":
        """Route a staged ``while`` condition through ``_pyir_while_cond``.

        The base preprocessor moves ``node.test`` into ``while_before_block``
        verbatim, where a watched fold bakes ``scf.condition(true)`` -- an
        unkillable runtime hang once the body mutates a condition slot.
        Wrapping the condition in ``_pyir_while_cond`` BEFORE ``super()``
        embeds the lift inside the before-block (evaluated per iteration),
        so a to-be-stored slot lifts to a dynamic ``scf.condition(cmpi...)``.

        Constexpr whiles keep the base behavior (they unroll at trace time).
        """
        if self.is_node_constexpr(node):
            return super().visit_While(node)
        node.test = ast.copy_location(
            ast.Call(
                func=_create_module_attribute(
                    "_pyir_while_cond",
                    submodule_name="pyir_runtime",
                    lineno=getattr(node.test, "lineno", None),
                    col_offset=getattr(node.test, "col_offset", None),
                ),
                args=[node.test],
                keywords=[],
            ),
            node.test,
        )
        return super().visit_While(node)

    def _prepare_while_condition_vars(
        self,
        node: ast.While,
        write_args: list[str],
        while_before_stmts: list[ast.stmt],
    ) -> list[ast.stmt]:
        """Override to insert PyIR-specific pyir_read for write_args in condition.

        Without this, literal-backed values (e.g. Int32(0)) rematerialize
        arith.constant instead of loading from the pyir.ref.

        Also prepends the ``pyir_tag_pending_writes`` write-set prologue so
        ``_pyir_while_cond`` can see the body's not-yet-landed stores when it
        decides fold-vs-lift.  Both land at the top of
        ``while_before_block`` (evaluated once per iteration, before the
        condition): the tag FIRST so the write-set is populated before the
        operand reload and the condition eval.
        """
        prep = self._build_pyir_read_prologue(node, write_args, helper="pyir_read")
        tag_stmt = self._build_pending_write_tags(node, write_args)
        return tag_stmt + prep

    def _build_pending_write_tags(
        self,
        node: ast.While,
        write_args: list[str],
    ) -> list[ast.stmt]:
        """Build the ``pyir_tag_pending_writes(...)`` before-block prologue.

        Collects the while BODY's syntactic write-set: the plain-name
        write_args, plus attribute/subscript targets whose owner Name also
        appears in the CONDITION (only those can affect the condition's
        fold, and only those are guaranteed readable in the before-block
        scope).  See ``pyir_tag_pending_writes`` for why this must run
        before the condition evaluates.
        """
        cond_names = {
            n.id
            for n in ast.walk(node.test)
            if isinstance(n, ast.Name) and isinstance(n.ctx, ast.Load)
        }
        specs: list[ast.expr] = []
        seen: set[str] = set()
        for name in write_args:
            if name in seen:
                continue
            seen.add(name)
            specs.append(
                ast.Tuple(
                    elts=[
                        ast.Constant(value=name),
                        ast.Constant(value=None),
                        ast.Constant(value=None),
                    ],
                    ctx=ast.Load(),
                )
            )
        for stmt in ast.walk(node):
            targets: list[ast.expr] = []
            if isinstance(stmt, ast.Assign):
                targets = list(stmt.targets)
            elif isinstance(stmt, (ast.AugAssign, ast.AnnAssign)):
                targets = [stmt.target]
            for t in targets:
                owner_expr: ast.expr | None = None
                slot_const: ast.expr | None = None
                if isinstance(t, ast.Attribute) and isinstance(t.value, ast.Name):
                    owner_expr = ast.Name(id=t.value.id, ctx=ast.Load())
                    slot_const = ast.Constant(value=t.attr)
                    dotted = f"{t.value.id}.{t.attr}"
                elif (
                    isinstance(t, ast.Subscript)
                    and isinstance(t.value, ast.Name)
                    and isinstance(t.slice, ast.Constant)
                ):
                    owner_expr = ast.Name(id=t.value.id, ctx=ast.Load())
                    slot_const = ast.Constant(value=t.slice.value)
                    dotted = f"{t.value.id}[{t.slice.value!r}]"
                else:
                    continue
                if t.value.id not in cond_names or dotted in seen:
                    continue
                seen.add(dotted)
                specs.append(
                    ast.Tuple(
                        elts=[ast.Constant(value=dotted), owner_expr, slot_const],
                        ctx=ast.Load(),
                    )
                )
        if not specs:
            return []
        call = ast.Expr(
            value=ast.Call(
                func=_create_module_attribute(
                    "pyir_tag_pending_writes",
                    submodule_name="pyir_runtime",
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=specs,
                keywords=[],
            )
        )
        return [ast.copy_location(ast.fix_missing_locations(call), node)]

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
            var for var in write_args if self._var_read_before_write(node.body, var)
        ]
        return self._build_pyir_read_prologue(node, needs_prologue)

    @staticmethod
    def _var_read_before_write(body: list[ast.stmt], var: str) -> bool:
        """Returns True iff *var* is read (Load context) before any Store
        of itself anywhere in *body*.  Walks every stmt -- a Load found
        before a Store wins; once a Store is encountered (Assign /
        AnnAssign / AugAssign of a matching Name), the function bails."""

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
                return False
            if isinstance(stmt, ast.AnnAssign) and stores_var(stmt.target):
                return False
            if (
                isinstance(stmt, ast.AugAssign)
                and isinstance(stmt.target, ast.Name)
                and stmt.target.id == var
            ):
                return False
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
    ) -> list[ast.stmt]:
        read_stmts: list[ast.stmt] = []
        for var in write_args:
            pyir_read_call = ast.Call(
                func=_create_module_attribute(
                    helper,
                    submodule_name="pyir_runtime",
                    lineno=node.lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    ast.Constant(value=var),
                    ast.Name(id=var, ctx=ast.Load()),
                ],
                keywords=[],
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
            slot_node = deepcopy(target.slice)
            if hasattr(slot_node, "ctx"):
                slot_node.ctx = ast.Load()
            return [
                ast.keyword(arg="owner", value=owner_node),
                ast.keyword(arg="slot_name", value=slot_node),
            ]
        return []

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
        t = deepcopy(target)
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
                    value=deepcopy(target.value),
                    attr="get",
                    ctx=ast.Load(),
                ),
                args=[ast.Constant(value=target.slice.value)],
                keywords=[],
            )
        return self._target_as_load(target)

    def _collect_attr_reads(
        self,
        node: ast.AST,
        exclude_paths: set[str] | None = None,
        call_func_ids: set[int] | None = None,
    ) -> list[tuple[str, str, str]]:
        """Collect ``self.X`` attribute reads from *node*.

        Returns a deduplicated list of ``(path_str, base_name, attr_name)``
        for every ``ast.Attribute(ctx=Load)`` whose ``value`` is the plain
        ``ast.Name`` ``self`` -- i.e. ``self.x`` but not ``self.x.y``.
        Skips attributes that are call targets (``self.advance()``), and
        any path in *exclude_paths*.

        *call_func_ids* lets a caller that already walked *node* pass the
        call-target id set in, so we skip a redundant ``ast.walk``; it is
        computed on demand when omitted.
        """
        if exclude_paths is None:
            exclude_paths = set()

        if call_func_ids is None:
            call_func_ids = self._collect_call_func_ids(node)

        seen: set[str] = set()
        results: list[tuple[str, str, str]] = []
        for child in ast.walk(node):
            if (
                isinstance(child, ast.Attribute)
                and isinstance(child.ctx, ast.Load)
                and isinstance(child.value, ast.Name)
                and child.value.id == "self"
                and id(child) not in call_func_ids
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
        Name-Load instrumentation to skip module names (``cute``, ``cutlass``)
        and class/type references (``Boo``, ``Int32``) that should never
        be rewritten to ``pyir_read``.
        """
        from types import ModuleType

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

    def _collect_other_attr_reads(
        self,
        node: ast.AST,
        exclude_paths: set[str] | None = None,
        call_func_ids: set[int] | None = None,
    ) -> list[tuple[str, str, str]]:
        """Collect ``obj.X`` attribute reads from *node* (D1 Attribute-Load).

        Returns a deduplicated list of ``(path_str, base_name, attr_name)``
        for every ``ast.Attribute(ctx=Load)`` whose ``value`` is a plain
        ``ast.Name`` other than ``self``. ``self.X`` is handled by
        :py:meth:`_collect_attr_reads`.

        Only fires inside a control-flow scope -- function-scope reads
        are already handled by the existing ``_mutable_ref`` /
        ``_pyir_auto_load_arg`` machinery.

        *call_func_ids* lets a caller that already walked *node* pass the
        call-target id set in, so we skip a redundant ``ast.walk``; it is
        computed on demand when omitted.
        """
        if not self._is_inside_cf_scope():
            return []
        if exclude_paths is None:
            exclude_paths = set()

        if call_func_ids is None:
            call_func_ids = self._collect_call_func_ids(node)

        seen: set[str] = set()
        results: list[tuple[str, str, str]] = []
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
            if id(child) in call_func_ids:
                continue
            if base in ("__base_dsl__", "__module_dsl__"):
                continue
            if self._is_module_or_class_name(base):
                continue
            path_str = f"{base}.{child.attr}"
            if path_str in exclude_paths or path_str in seen:
                continue
            seen.add(path_str)
            results.append((path_str, base, child.attr))
        return results

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
        self,
        node: ast.AST,
        exclude_names: set[str] | None = None,
        call_func_ids: set[int] | None = None,
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

        if call_func_ids is None:
            call_func_ids = self._collect_call_func_ids(node)

        # Single walk: record every Attribute-base Name id (already covered by
        # attribute-read instrumentation) and every Name-Load occurrence in
        # source order. Iterating the collected occurrences below preserves the
        # original first-occurrence result ordering without re-walking.
        attr_value_only_ids: set[int] = set()
        load_name_nodes: list[tuple[int, str]] = []
        for child in ast.walk(node):
            if isinstance(child, ast.Attribute) and isinstance(child.value, ast.Name):
                attr_value_only_ids.add(id(child.value))
            elif isinstance(child, ast.Name) and isinstance(child.ctx, ast.Load):
                load_name_nodes.append((id(child), child.id))

        # A name qualifies only if it has at least one "bare" Load occurrence —
        # one that is neither an Attribute base nor a call target. Otherwise
        # `boo = pyir_read('boo', boo)` would be redundant with the attribute
        # instrumentation for `boo.val`. Precomputing this set replaces the
        # per-candidate ``ast.walk`` rescan the loop used to do.
        names_with_bare_load = {
            name
            for node_id, name in load_name_nodes
            if node_id not in attr_value_only_ids and node_id not in call_func_ids
        }

        active = self.session_data.scope_manager.get_active_symbols()

        def _in_scope(name: str) -> bool:
            return any(name in scope for scope in active)

        seen: set[str] = set()
        results: list[str] = []
        for node_id, name in load_name_nodes:
            if node_id in call_func_ids:
                continue
            if name in exclude_names or name in seen:
                continue
            if name in ("__base_dsl__", "__module_dsl__"):
                continue
            if self.session_data.scope_manager.is_skip_reference_taking(name):
                continue
            if not _in_scope(name):
                continue
            if self._is_module_or_class_name(name):
                continue
            if name not in names_with_bare_load:
                continue
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

            pyir_call = ast.Call(
                func=_create_module_attribute(
                    "pyir_assign",
                    submodule_name="pyir_runtime",
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
                keywords=[deepcopy(kw) for kw in slot_kwargs],
            )
            reassign = ast.Assign(
                targets=[_deepcopy_ast_root(target)],
                value=pyir_call,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(reassign), node))
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
        a single ``cute.printf(boo.val, bar)`` statement instruments both
        ``boo.val`` and ``bar`` in one call.
        """
        # All three collectors need the call-target id set for *node*; compute
        # it once here instead of three identical ``ast.walk`` passes.
        call_func_ids = self._collect_call_func_ids(node)
        self_reads = self._collect_attr_reads(node, exclude_paths, call_func_ids)
        other_attr_reads = self._collect_other_attr_reads(
            node, exclude_paths, call_func_ids
        )
        name_loads = self._collect_name_loads(node, exclude_paths, call_func_ids)

        # Don't emit a Name-Load writeback for a name that already serves
        # as the owner of a non-self Attribute writeback we just emitted:
        # `boo = pyir_read('boo', boo)` is redundant with
        # `boo.val = pyir_read('boo.val', boo.val, owner=boo, ...)`.
        attr_owner_names = {base for _, base, _ in other_attr_reads}
        name_loads = [n for n in name_loads if n not in attr_owner_names]

        if not self_reads and not other_attr_reads and not name_loads:
            return node

        stmts: list[ast.stmt] = []
        # Map from (base_name, attr_name) -> local var name for replacement
        replacements: dict[tuple[str, str], str] = {}

        # ----- (1) self.X reads using local-var pattern (existing) -----
        for path_str, base_name, attr_name in self_reads:
            lineno = node.lineno
            col_offset = getattr(node, "col_offset", 0)

            local_var = f"_pyir_attr_{self.session_data.counter}"
            self.session_data.counter += 1
            replacements[(base_name, attr_name)] = local_var

            attr_load = ast.Attribute(
                value=ast.Name(id=base_name, ctx=ast.Load()),
                attr=attr_name,
                ctx=ast.Load(),
            )
            pyir_read_call = ast.Call(
                func=_create_module_attribute(
                    "pyir_read",
                    submodule_name="pyir_runtime",
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
        for path_str, base_name, attr_name in other_attr_reads:
            lineno = node.lineno
            col_offset = getattr(node, "col_offset", 0)

            local_var = f"_pyir_attr_{self.session_data.counter}"
            self.session_data.counter += 1
            replacements[(base_name, attr_name)] = local_var

            attr_load = ast.Attribute(
                value=ast.Name(id=base_name, ctx=ast.Load()),
                attr=attr_name,
                ctx=ast.Load(),
            )
            pyir_read_call = ast.Call(
                func=_create_module_attribute(
                    "pyir_read",
                    submodule_name="pyir_runtime",
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
        #     variables like ``tar`` in mixing.py would then be threaded
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
        name_replacements: dict[str, str] = {}
        for name in name_loads:
            lineno = node.lineno
            col_offset = getattr(node, "col_offset", 0)

            local_var = f"_pyir_name_{self.session_data.counter}"
            self.session_data.counter += 1
            name_replacements[name] = local_var

            pyir_read_call = ast.Call(
                func=_create_module_attribute(
                    "pyir_read",
                    submodule_name="pyir_runtime",
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

        # Replace self.X / non-self Attribute references with their
        # local vars, then bare Name references with their local vars.
        replaced = self._replace_attr_with_local(node, replacements)
        if name_replacements:
            replaced = self._replace_name_with_local(replaced, name_replacements)
        assert isinstance(replaced, ast.stmt)
        stmts.append(replaced)
        return stmts

    def _replace_name_with_local(
        self, node: ast.AST, replacements: dict[str, str]
    ) -> ast.AST:
        """Replace bare ``Name(ctx=Load)`` references in *node* with
        ``Name(local_var, ctx=Load)``. Used by D1 Name-Load
        instrumentation.

        Does NOT descend into ``ast.Attribute``'s ``.value`` slot --
        ``obj.X`` writes/reads on ``obj`` are already handled by the
        attribute-read pass. Does NOT replace Store-context Names.
        """
        if not replacements:
            return node

        class NameReplacer(ast.NodeTransformer):
            def visit_Name(self, child: ast.Name) -> ast.AST:
                if isinstance(child.ctx, ast.Load):
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
        self, node: ast.AST, replacements: dict[tuple[str, str], str]
    ) -> ast.AST:
        """Replace ``self.X`` attribute reads in *node* with local variable
        names from *replacements*.

        *replacements* maps ``(base_name, attr_name)`` → ``local_var_name``.
        Only replaces ``ast.Attribute(ctx=Load)`` with matching base Name.
        """
        if not replacements:
            return node

        class AttrReplacer(ast.NodeTransformer):
            def visit_Attribute(self, child: ast.Attribute) -> ast.AST:
                self.generic_visit(child)
                if isinstance(child.ctx, ast.Load) and isinstance(
                    child.value, ast.Name
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
        for target in targets:
            path_str = self._target_to_path_str(target)
            lineno = node.lineno

            slot_kwargs = self._slot_kwargs_for(target)
            # target = pyir_read("target", target, owner=..., slot_name=...)
            # For dict-style subscripts (d['key']), use d.get('key') to
            # avoid KeyError on first-time key insertion.
            target_load_for_read = self._subscript_safe_read(target)
            pyir_read_call = ast.Call(
                func=_create_module_attribute(
                    "pyir_read",
                    submodule_name="pyir_runtime",
                    lineno=lineno,
                    col_offset=node.col_offset,
                ),
                args=[
                    ast.Constant(value=path_str),
                    target_load_for_read,
                ],
                keywords=[deepcopy(kw) for kw in slot_kwargs],
            )
            read_stmt = ast.Assign(
                targets=[deepcopy(target)],
                value=pyir_read_call,
            )

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
                func=_create_module_attribute(
                    "pyir_assign",
                    submodule_name="pyir_runtime",
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
                keywords=[deepcopy(kw) for kw in slot_kwargs],
            )
            reassign = ast.Assign(
                targets=[deepcopy(target)],
                value=pyir_call,
            )

            # Attribute targets might be first definitions (e.g.
            # self._idx = idx in __init__).  Guard with hasattr so
            # the pyir_read of the old value doesn't crash when the
            # attribute doesn't exist yet.  Applies in both callee
            # rewrite AND top-level @cute.jit paths.
            if isinstance(target, ast.Attribute) and isinstance(target.value, ast.Name):
                # if hasattr(obj, attr):
                #     pyir_read + capture_old + original + pyir_assign
                # else:
                #     original
                hasattr_test = ast.Call(
                    func=ast.Name(id="hasattr", ctx=ast.Load()),
                    args=[
                        ast.Name(id=target.value.id, ctx=ast.Load()),
                        ast.Constant(value=target.attr),
                    ],
                    keywords=[],
                )
                guarded_body: list[ast.stmt] = [
                    ast.copy_location(ast.fix_missing_locations(read_stmt), node),
                    ast.copy_location(ast.fix_missing_locations(capture_old), node),
                    deepcopy(node),
                    ast.copy_location(ast.fix_missing_locations(reassign), node),
                ]
                fallback_body: list[ast.stmt] = [deepcopy(node)]
                if_guard = ast.If(
                    test=hasattr_test,
                    body=guarded_body,
                    orelse=fallback_body,
                )
                stmts.append(
                    ast.copy_location(ast.fix_missing_locations(if_guard), node)
                )
            else:
                stmts.append(
                    ast.copy_location(ast.fix_missing_locations(read_stmt), node)
                )
                stmts.append(
                    ast.copy_location(ast.fix_missing_locations(capture_old), node)
                )
                stmts.append(node)  # original assignment
                stmts.append(
                    ast.copy_location(ast.fix_missing_locations(reassign), node)
                )

        if len(stmts) == 0:
            return node
        return stmts

    def _insert_pyir_augassign(self, node: ast.AugAssign) -> list[ast.stmt]:
        """Insert pyir_read + pyir_assign around an augmented assignment.

        Transforms:  target += expr
        To:          target = pyir_read(name, target)    # load from ref
                     _old = target
                     target += expr                       # uses loaded value
                     target = pyir_assign(name, _old, target, file, line)
        """
        target = node.target
        path_str = self._target_to_path_str(target)
        lineno = node.lineno
        slot_kwargs = self._slot_kwargs_for(target)

        # target = pyir_read("target", target, owner=..., slot_name=...)
        # (load before the += computation)
        target_load_for_read = self._target_as_load(target)
        pyir_read_call = ast.Call(
            func=_create_module_attribute(
                "pyir_read",
                submodule_name="pyir_runtime",
                lineno=lineno,
                col_offset=node.col_offset,
            ),
            args=[
                ast.Constant(value=path_str),
                target_load_for_read,
            ],
            keywords=[deepcopy(kw) for kw in slot_kwargs],
        )
        read_stmt = ast.Assign(
            targets=[deepcopy(target)],
            value=pyir_read_call,
        )

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
            func=_create_module_attribute(
                "pyir_assign",
                submodule_name="pyir_runtime",
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
            keywords=[deepcopy(kw) for kw in slot_kwargs],
        )
        reassign = ast.Assign(
            targets=[deepcopy(target)],
            value=pyir_call,
        )

        return [
            ast.copy_location(
                ast.fix_missing_locations(read_stmt), node
            ),  # load from ref
            ast.copy_location(
                ast.fix_missing_locations(capture_old), node
            ),  # capture old
            node,  # original augmented assignment (uses loaded value)
            ast.copy_location(
                ast.fix_missing_locations(reassign), node
            ),  # store + reload
        ]

    def _insert_pyir_subscript_assign(
        self, node: ast.stmt, target: ast.Subscript
    ) -> list[ast.stmt]:
        """Generate conditional pyir instrumentation for a subscript assignment."""
        lineno = node.lineno
        col_offset = node.col_offset
        path_str = self._target_to_path_str(target)

        old_name = f"_pyir_sub_old_{self.session_data.counter}"
        self.session_data.counter += 1

        container_node = self._target_as_load(target.value)
        key_node = deepcopy(target.slice)

        pre_call = ast.Call(
            func=_create_module_attribute(
                "_pyir_pre_subscript_assign",
                submodule_name="pyir_runtime",
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
            func=_create_module_attribute(
                "pyir_assign",
                submodule_name="pyir_runtime",
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
            keywords=[deepcopy(kw) for kw in slot_kwargs],
        )
        reassign = ast.Assign(
            targets=[deepcopy(target)],
            value=pyir_call,
        )

        skip_sentinel = _create_module_attribute(
            "_PYIR_SKIP",
            submodule_name="pyir_runtime",
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
        skip_sentinel_wb = _create_module_attribute(
            "_PYIR_SKIP",
            submodule_name="pyir_runtime",
            lineno=lineno,
            col_offset=col_offset,
        )
        writeback = ast.Assign(
            targets=[deepcopy(target)],
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

        container_node = self._target_as_load(target.value)
        key_node = deepcopy(target.slice)

        pre_call = ast.Call(
            func=_create_module_attribute(
                "_pyir_pre_subscript_assign",
                submodule_name="pyir_runtime",
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

        skip_sentinel_1 = _create_module_attribute(
            "_PYIR_SKIP",
            submodule_name="pyir_runtime",
            lineno=lineno,
            col_offset=col_offset,
        )
        writeback = ast.Assign(
            targets=[deepcopy(target)],
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
            func=_create_module_attribute(
                "pyir_assign",
                submodule_name="pyir_runtime",
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
            keywords=[deepcopy(kw) for kw in slot_kwargs],
        )
        reassign = ast.Assign(
            targets=[deepcopy(target)],
            value=pyir_call,
        )
        skip_sentinel_2 = _create_module_attribute(
            "_PYIR_SKIP",
            submodule_name="pyir_runtime",
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
            ast.copy_location(ast.fix_missing_locations(pre_assign), node),
            ast.copy_location(ast.fix_missing_locations(if_writeback), node),
            node,
            ast.copy_location(ast.fix_missing_locations(if_post), node),
        ]

    def _decompose_tuple_assign(
        self,
        node: ast.Assign,
        tuple_target: ast.Tuple,
        in_scope_indices: set[int],
        *,
        rhs_temp_name: str | None = None,
    ) -> ast.stmt | list[ast.stmt]:
        """Decompose a tuple unpacking assignment into individual pyir-instrumented assigns.

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
        """
        stmts: list[ast.stmt] = []
        lineno = node.lineno
        col_offset = node.col_offset
        elts = tuple_target.elts

        # Starred unpacking not supported -- fall through without instrumentation.
        if any(isinstance(elt, ast.Starred) for elt in elts):
            return node

        # Use the pre-computed in-scope indices from visit_Assign.
        instrumented: list[tuple[int, ast.expr]] = [
            (i, elt) for i, elt in enumerate(elts) if i in in_scope_indices
        ]

        # --- Step 1: pyir_read for each instrumented element ---
        for _i, elt in instrumented:
            path_str = self._target_to_path_str(elt)
            target_load = self._target_as_load(elt)
            slot_kwargs = self._slot_kwargs_for(elt)
            read_call = ast.Call(
                func=_create_module_attribute(
                    "pyir_read",
                    submodule_name="pyir_runtime",
                    lineno=lineno,
                    col_offset=col_offset,
                ),
                args=[ast.Constant(value=path_str), target_load],
                keywords=[deepcopy(kw) for kw in slot_kwargs],
            )
            read_stmt = ast.Assign(
                targets=[deepcopy(elt)],
                value=read_call,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(read_stmt), node))

        # --- Step 2: capture old values ---
        old_names: dict[int, str] = {}  # index -> old_name
        for _i, elt in instrumented:
            old_name = f"_pyir_old_{self.session_data.counter}"
            self.session_data.counter += 1
            old_names[_i] = old_name
            target_load = self._target_as_load(elt)
            capture = ast.Assign(
                targets=[ast.Name(id=old_name, ctx=ast.Store())],
                value=target_load,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(capture), node))

        # --- Step 3: evaluate RHS into temp ---
        if rhs_temp_name is not None:
            # RHS already evaluated by a prior tuple target — reuse the temp.
            tmp_name = rhs_temp_name
        else:
            tmp_name = f"_pyir_tmp_{self.session_data.counter}"
            self.session_data.counter += 1
            tmp_assign = ast.Assign(
                targets=[ast.Name(id=tmp_name, ctx=ast.Store())],
                value=node.value,  # the original RHS expression
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(tmp_assign), node))

        # --- Step 4: decompose -- extract each element from temp ---
        for i, elt in enumerate(elts):
            subscript = ast.Subscript(
                value=ast.Name(id=tmp_name, ctx=ast.Load()),
                slice=ast.Constant(value=i),
                ctx=ast.Load(),
            )
            extract = ast.Assign(
                targets=[deepcopy(elt)],
                value=subscript,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(extract), node))

        # --- Step 5: pyir_assign for each instrumented element ---
        for idx, elt in instrumented:
            path_str = self._target_to_path_str(elt)
            target_load = self._target_as_load(elt)
            slot_kwargs = self._slot_kwargs_for(elt)
            old_name = old_names[idx]
            pyir_call = ast.Call(
                func=_create_module_attribute(
                    "pyir_assign",
                    submodule_name="pyir_runtime",
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
                keywords=[deepcopy(kw) for kw in slot_kwargs],
            )
            reassign = ast.Assign(
                targets=[deepcopy(elt)],
                value=pyir_call,
            )
            stmts.append(ast.copy_location(ast.fix_missing_locations(reassign), node))

        if len(stmts) == 0:
            return node
        return stmts
