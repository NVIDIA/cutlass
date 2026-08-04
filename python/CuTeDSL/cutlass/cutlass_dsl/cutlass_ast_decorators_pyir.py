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
PyIR-specific SCF (Structured Control Flow) generator.

This module contains the PyIRScfGenerator class that extends the base ScfGenerator
with PyIR-specific functionality for handling control flow operations with SSA form
maintenance through pyir.ref/store/load operations.
"""

import builtins
from typing import Any, Callable, Dict, List, Optional

from cutlass._mlir import ir
from cutlass._mlir.dialects import scf

from ..base_dsl.multi_stage_manager import enter_staged_cf, exit_staged_cf
from ..base_dsl.pyir_runtime import (
    _pyir_auto_load_arg,
    _pyir_lookup_slot_from_value,
)
from ..base_dsl.typing import as_numeric
from ..base_dsl.utils.logger import log
from .cutlass_ast_decorators import ScfGenerator


class PyIRScfGenerator(ScfGenerator):
    """
    PyIR-specific SCF generator that handles control flow with SSA form maintenance.

    Extends the base ScfGenerator with functionality to generate PyIR-instrumented
    control flow operations (if/for/while) that use pyir.ref/store/load for state
    management instead of traditional iter_args.

    The PyIR path creates SCF operations with zero iter_args, relying on the
    AST-inserted pyir_assign/pyir_read calls to handle all mutable state through
    pyir.ref/store/load operations. The C++ PYIRToSCFPass later converts these
    into proper SCF operations with iter_args.
    """

    def scf_execute_dynamic(
        self,
        op_type_name: str,
        mix_iter_args: List[object],
        full_write_args_count: int,
        mix_iter_arg_names: List[str],
        create_op_func: Callable[[List[ir.Value]], ir.Operation],
        region_builders: List[Callable[..., Any]],
        block_term_op_builder: Dict[Callable[..., Any], Callable[..., Any]] = {},
    ) -> Any:
        """
        Override to route PyIR-enabled if/for/while ops to PyIR-specific path.

        IfExp (ternary) always uses the non-PyIR path since it requires result types
        to be hardcoded in create_op_func.
        """
        # PyIR path: for if/for/while ops from the AST preprocessor.
        # IfExp (ternary) always has results and its create_op hardcodes
        # result_types, so it must use the non-pyir path.
        if op_type_name in ("if", "for", "while"):
            return self._scf_execute_pyir(
                op_type_name,
                mix_iter_args,
                mix_iter_arg_names,
                create_op_func,
                region_builders,
                block_term_op_builder,
            )

        # For ifexp or any other op, delegate to base class
        return super().scf_execute_dynamic(
            op_type_name,
            mix_iter_args,
            full_write_args_count,
            mix_iter_arg_names,
            create_op_func,
            region_builders,
            block_term_op_builder,
        )

    def _scf_execute_pyir(
        self,
        op_type_name: str,
        mix_iter_args: List[object],
        mix_iter_arg_names: List[str],
        create_op_func: Callable[..., ir.Operation],
        region_builders: List[Callable[..., Any]],
        block_term_op_builder: Dict[Callable[..., Any], Callable[..., Any]],
    ) -> Any:
        """Pure PyIR path: zero iter_args, pyir.ref/store/load handles all state.

        AST-inserted ``pyir_assign`` / ``pyir_read`` calls create
        ``pyir.ref`` / ``pyir.store`` / ``pyir.load`` ops. The C++
        ``PYIRToSCFPass`` converts these into ``scf.for`` / ``scf.if`` /
        ``scf.while`` with proper ``iter_args``.
        """
        log().info(
            "[pyir] === _scf_execute_pyir: %s, %d mix_iter_args ===",
            op_type_name,
            len(mix_iter_args),
        )

        # Create SCF op with zero iter_args — pyir refs handle all state
        op = create_op_func([])
        log().debug("Generated scf.%s (pyir) \n[%s]", op_type_name, op)

        # For multi-region ops (scf.if), save originals so the else-block
        # doesn't see MLIR values from inside the then-block's region.
        is_multi_region = op_type_name == "if" and len(region_builders) > 1
        original_mix_iter_args: Optional[List[object]] = (
            list(mix_iter_args) if is_multi_region else None
        )

        enter_staged_cf()
        try:
            for i, builder in enumerate(region_builders):
                # Reset to original values before building non-first regions
                # (e.g. else-block) so they don't see then-block's region-
                # local MLIR values that would violate SSA dominance.
                if is_multi_region and i > 0:
                    assert original_mix_iter_args is not None
                    for idx in builtins.range(len(mix_iter_args)):
                        mix_iter_args[idx] = original_mix_iter_args[idx]

                region = op.regions[i]
                block = region.blocks[0]
                with ir.InsertionPoint(block):
                    block_args = list(block.arguments)

                    # Execute body -- AST-inserted pyir_assign/pyir_read
                    # handle ref creation, load, store for all mutable values.
                    region_result = builder(
                        op,
                        block_args,
                        [],  # ir_values: empty (no iter_args)
                        None,  # pytree_def: not used (pyir handles everything)
                        mix_iter_args,
                        0,  # full_write_args_count: 0
                    )

                    # Update mix_iter_args from body result so that
                    # slot-backed objects are accessible after the loop
                    # (slot-backed values carry ``_mutable_ref`` /
                    # ``_pyir_load_version`` tags the post-loop bridge
                    # below re-loads from).
                    if region_result is not None:
                        result_list = (
                            region_result
                            if isinstance(region_result, (list, tuple))
                            else [region_result]
                        )
                        for idx, val in enumerate(result_list):
                            if idx < len(mix_iter_args) and val is not None:
                                mix_iter_args[idx] = val

                    # Terminator
                    if builder in block_term_op_builder:
                        block_term_op_builder[builder](region_result, 0)
                    else:
                        scf.YieldOp([])
        finally:
            exit_staged_cf()

        log().debug("Completed scf.%s (pyir) \n[%s]", op_type_name, op)

        # Emit pyir.load for slot-backed values so that returned
        # values are valid at the outer scope (not trapped inside the
        # scf.if/for/while body where they were defined).
        # Primary slot detection routes through _pyir_lookup_slot_from_value
        # (the _pyir_load_version + _mutable_ref tags on the value); when the
        # inner-scope value has no load tag yet, we additionally consult the
        # ``_mutable_ref`` attribute as a fallback so "slot-backed but never loaded" cases
        # still get the post-loop load.  The ``_mutable_ref`` marker is
        # then bridged onto the loaded value so the outer scope's
        # ``_pyir_auto_load_arg`` -- which consults ``_mutable_ref`` per
        # the current pyir_runtime contract -- can chain loads at each
        # nested-CF scope exit.
        for idx in builtins.range(len(mix_iter_args)):
            arg = mix_iter_args[idx]
            mv = _pyir_lookup_slot_from_value(arg)
            if mv is None:
                # Slot-backed but never loaded in this scope: fall back
                # to ``_mutable_ref`` so the bridge below still fires.
                mv = getattr(arg, "_mutable_ref", None)
            loaded = _pyir_auto_load_arg(arg)
            if loaded is not arg:
                if mv is not None and _pyir_lookup_slot_from_value(loaded) is None:
                    object.__setattr__(loaded, "_mutable_ref", mv)
                mix_iter_args[idx] = loaded

        # Return in standard pattern
        if not mix_iter_args:
            return
        if len(mix_iter_args) == 1:
            return mix_iter_args[0]
        return mix_iter_args

    def create_while_op_pyir(
        self,
        while_before_block: Callable[..., Any],
        while_after_block: Optional[Callable[..., Any]],
        write_args: List[Any],
        full_write_args_count: int,
        write_args_names: List[str],
    ) -> Any:
        """
        Create PyIR-specific while loop with zero iter_args.

        Uses pyir.ref/store/load for all mutable state management.
        """
        log().debug("_while_execute_dynamic (PyIR path)")
        while_op_type_name = "while"

        _pyir_cond = [None]  # list for nonlocal mutation in closures

        def create_while_op_impl(dyn_yield_ops: List[ir.Value]) -> ir.Operation:
            while_op = scf.WhileOp([], [])
            while_op.before.blocks.append()
            while_op.after.blocks.append()
            return while_op

        def before_block_builder_pyir(
            op: ir.Operation,
            block_args: List[ir.Value],
            _: List[ir.Value],
            pytree_def: Any,
            mix_iter_args: List[Any],
            full_write_args_count: int,
        ) -> None:
            # Execute condition block with original Python objects.
            # AST-inserted pyir_read/pyir_assign handle ref loads/stores.
            flat_args = list(mix_iter_args)
            cond, _before_results = while_before_block(*flat_args)
            _pyir_cond[0] = cond
            # Return None: do not contaminate mix_iter_args with condition
            return None

        def before_block_terminator_pyir(
            region_result: Any, full_write_args_count: int
        ) -> None:
            # Emit scf.condition with empty pass-through args
            ir_cond = as_numeric(_pyir_cond[0]).ir_value()
            scf.ConditionOp(ir_cond, [])

        def after_block_builder_pyir(
            op: ir.Operation,
            block_args: List[ir.Value],
            _: List[ir.Value],
            pytree_def: Any,
            mix_iter_args: List[object],
            full_write_args_count: int,
        ) -> None:
            # Execute loop body. AST-inserted pyir_assign handles stores.
            flat_args = list(mix_iter_args)
            assert while_after_block is not None
            while_after_block(*flat_args)
            # Return None: pyir.store already updated refs.
            # Default terminator in _scf_execute_pyir emits scf.YieldOp([]).
            return None

        return self.scf_execute_dynamic(
            op_type_name=while_op_type_name,
            mix_iter_args=write_args,
            full_write_args_count=full_write_args_count,
            mix_iter_arg_names=write_args_names,
            create_op_func=create_while_op_impl,
            region_builders=[before_block_builder_pyir, after_block_builder_pyir],
            block_term_op_builder={
                before_block_builder_pyir: before_block_terminator_pyir,
            },
        )
