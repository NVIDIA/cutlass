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

import builtins
from typing import Any, Callable, Dict, List, Optional, Union

from cutlass._mlir import ir
from cutlass._mlir.dialects import scf
from collections.abc import Sequence

from ..base_dsl.common import is_pyir_enabled
from ..base_dsl.common import (
    DSLRuntimeError,
    DSLUserCodeError,
    DSLNotImplemented,
)
from ..base_dsl.diagnostics import DiagId
from ..base_dsl.dsl import is_dynamic_expression
from .._mlir_helpers.arith import ArithValue
from ..base_dsl.ast_helpers import *  # noqa: F401,F403
from ..base_dsl.ast_helpers import truth_of
from ..base_dsl.pyir_runtime import (
    PYIR_REGION_ATTR_WRITES_ATTR,
    PYIR_REGION_DEAD_ON_ENTRY_ATTR,
    PYIR_REGION_FREE_CALLS_ATTR,
    PYIR_REGION_METHOD_CALLS_ATTR,
    _pyir_bump_region_epoch,
    _pyir_fresh_selection_template,
    _pyir_register_staged_selection,
    _pyir_staged_selection_presight,
    _pyir_staged_selection_scope,
    _pyir_staged_selection_verdicts,
)
from ..base_dsl.utils.logger import log
from ..base_dsl import typing as t
from ..base_dsl.typing import Boolean, Numeric, as_numeric, _binary_op_type_promote
from ..base_dsl.utils.tree_utils import (
    PyTreeDef,
    check_tree_equal,
    describe_tree_difference,
)
from . import cutlass as cutlass_dsl

# =============================================================================
# AST Helpers
# =============================================================================

NoneType = type(None)


def _create_control_flow_generator() -> "ScfGenerator":
    """
    Create appropriate control flow generator based on runtime configuration.
    """
    if is_pyir_enabled():
        from .cutlass_ast_decorators_pyir import PyIRScfGenerator

        return PyIRScfGenerator()
    return ScfGenerator()


class LoopUnroll(ir.Attribute):
    def __init__(self, **kwargs: Union[int, bool]) -> None:
        valid_keys = set(["count", "full"])
        def to_mlir_attr(val: Union[int, bool]) -> str:
            if isinstance(val, bool):
                return "true" if val else "false"
            elif isinstance(val, int):
                return f"{val} : i32"
            else:
                raise DSLNotImplemented(f"{type(val)} is not supported")

        cfg = {key: to_mlir_attr(kwargs[key]) for key in valid_keys if key in kwargs}
        if kwargs.get("count", None) == 1:
            cfg["disable"] = "true"

        unroll = "<" + ", ".join(f"{key} = {value}" for key, value in cfg.items()) + ">"

        super().__init__(
            ir.Attribute.parse(f"#llvm.loop_annotation<unroll = {unroll}>")
        )


class ScfGenerator:
    """
    Encapsulates common scf dialect functionality: pack, unpack, and SCF execution.
    """

    # The (base, attr) pairs a staged loop body's ORIGINAL code assigns directly
    # (preprocessor-tagged declared fact); set by the loop executor before building
    region_attr_writes: "Optional[tuple[tuple[str, str], ...]]" = None
    # The (base, method) pairs a staged loop body's ORIGINAL code calls on
    # Name-rooted receiver paths (preprocessor-tagged; completed via class facts).
    region_method_calls: "Optional[tuple[tuple[str, str], ...]]" = None
    # The (func_name, arg_base) pairs a staged loop body's ORIGINAL code calls
    # as bare-Name free functions with a Name-rooted first argument
    # (preprocessor-tagged; completed via the callee's first-parameter facts).
    region_free_calls: "Optional[tuple[tuple[str, str], ...]]" = None
    # The (path, line) pairs of the places a staged loop body's ORIGINAL code
    # stores before any read (preprocessor-tagged; the identity re-point
    # classification's dead-on-entry fact).
    region_dead_on_entry: "Optional[tuple[tuple[str, int], ...]]" = None
    # The staged loop-body function itself: a read-only captured receiver
    # name resolves through its closure at region entry.
    region_body_func: "Optional[Callable[..., Any]]" = None

    @staticmethod
    def _normalize_region_result_to_list(region_result: Any) -> List[Any]:
        """
        Convert region_result to a list if it is not already a list
        If region_result is a list, return it as is.
        If region_result is None, return an empty list.
        If region_result is not a list, return a list containing region_result as the only element.
        """
        if region_result is None:
            region_result_list = []
        elif not isinstance(region_result, list):
            region_result_list = [region_result]
        else:
            region_result_list = region_result
        return region_result_list

    @staticmethod
    def _check_region_result(
        original_value: object, region_value: object, arg_name: str, op_type_name: str
    ) -> None:
        """
        Validate that a region result maintains the same type as the original value.

        This method checks for type consistency between the original value passed to a dynamic
        SCF operation (like for, if, while) and the value returned from the operation's region.

        Args:
            original_value: The value before entering the SCF operation region
            region_value: The value returned from the SCF operation region
            arg_name: Name of the argument being checked (for error reporting)
            op_type_name: Type of SCF operation (e.g., 'for', 'if', 'while') for error reporting

        Raises:
            DSLRuntimeError: If the region value has a different type than the original value.
                The error includes suggestions for using compile-time control flow instead.

        Note:
            This method performs relaxed type checking that allows inheritance relationships.
            For example, a child class can be returned where a parent class was expected.
            However, fundamental type changes (like None to non-None, different sequence types,
            or different numeric types) are not allowed in dynamic SCF operations.
        """

        def get_type_name(value: object) -> str:
            if isinstance(value, NoneType):
                return "None"
            elif isinstance(value, Sequence):
                return f"{type(value).__name__}<{len(value)}>"
            else:
                return type(value).__name__

        # Check for type mismatches
        type_mismatch = False
        old_type_name = None
        new_type_name = None

        # Handle None type changes
        if isinstance(original_value, NoneType) != isinstance(region_value, NoneType):
            type_mismatch = True
            old_type_name = get_type_name(original_value)
            new_type_name = get_type_name(region_value)
        # Handle sequence type/length changes
        elif isinstance(original_value, Sequence) and isinstance(
            region_value, Sequence
        ):
            if type(original_value) != type(region_value) or len(original_value) != len(
                region_value
            ):
                type_mismatch = True
                old_type_name = get_type_name(original_value)
                new_type_name = get_type_name(region_value)
        # Handle numeric type changes
        elif isinstance(
            original_value, (Numeric, ArithValue, ir.Value, int, float, bool)
        ) or isinstance(
            region_value, (Numeric, ArithValue, ir.Value, int, float, bool)
        ):
            try:
                original_numeric = as_numeric(original_value)
                region_numeric = as_numeric(region_value)
                if original_numeric.dtype != region_numeric.dtype:
                    type_mismatch = True
                    old_type_name = original_numeric.dtype.__name__
                    new_type_name = region_numeric.dtype.__name__
            except Exception:
                pass
        # Handle general type changes (relaxed for inheritance)
        elif type(original_value) != type(region_value):
            old_type = type(original_value)
            new_type = type(region_value)
            if not (issubclass(old_type, new_type) or issubclass(new_type, old_type)):
                type_mismatch = True
                old_type_name = old_type.__name__
                new_type_name = new_type.__name__

        if type_mismatch:
            raise DSLUserCodeError(
                DiagId.TYPE_UNSTABLE_JOIN,
                var=arg_name,
                old_type=old_type_name,
                new_type=new_type_name,
                op_type=op_type_name,
            )

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
        # 1) Unpack
        ir_values, pytree_def = cutlass_dsl.unpack_to_irvalue(
            mix_iter_args, op_type_name, full_write_args_count
        )

        # 2) Create the SCF op
        op = create_op_func(ir_values)
        # 3) Build the regions
        for i, builder in enumerate(region_builders):
            region = op.regions[i]
            block = region.blocks[0]
            with ir.InsertionPoint(block):
                block_args = list(block.arguments)
                region_result = builder(
                    op,
                    block_args,
                    ir_values,
                    pytree_def,
                    mix_iter_args,
                    full_write_args_count,
                )

                # Use custom terminator if provided for this builder, otherwise use default YieldOp
                if builder in block_term_op_builder:
                    # Use the provided terminator generator
                    block_term_op_builder[builder](region_result, full_write_args_count)
                else:
                    # Normalize region_result
                    region_result_list = ScfGenerator._normalize_region_result_to_list(
                        region_result
                    )
                    # For standard yield op, check result
                    for arg, result, name in zip(
                        mix_iter_args,
                        region_result_list,
                        mix_iter_arg_names,
                    ):
                        ScfGenerator._check_region_result(
                            arg, result, name, op_type_name
                        )

                    # Default behavior - generate YieldOp
                    region_values, yield_pytree_def = cutlass_dsl.unpack_to_irvalue(
                        region_result_list, op_type_name, full_write_args_count
                    )

                    assert isinstance(pytree_def, PyTreeDef)
                    assert isinstance(yield_pytree_def, PyTreeDef)
                    mismatch = check_tree_equal(pytree_def, yield_pytree_def)
                    if mismatch != -1:
                        # Get arg name
                        filterd_arg_names = (
                            mix_iter_arg_names
                            if op_type_name == "ifexp"
                            else cutlass_dsl.filter_readonly_frozen_dataclass_names(
                                mix_iter_args, mix_iter_arg_names, full_write_args_count
                            )
                        )
                        detail = describe_tree_difference(
                            pytree_def.child_treedefs[mismatch],
                            yield_pytree_def.child_treedefs[mismatch],
                            filterd_arg_names[mismatch],
                        )
                        if detail:
                            detail = f" ({detail})"

                        raise DSLUserCodeError(
                            DiagId.CONTAINER_STRUCTURE_CHANGED,
                            var=filterd_arg_names[mismatch],
                            op_type=op_type_name,
                            detail=detail,
                        )

                    scf.YieldOp(region_values)

        # 4) Pack final results.
        #
        # Rebind pass-through loop-carried slots to their INIT value instead of
        # the op result: a slot every region terminator forwards unchanged (the
        # terminator operand IS the entry block argument) has a result that is
        # value-equal to its init for every trip count, and the init is the
        # only form guaranteed to dominate the enclosing scope.  The loop may
        # sit inside a region-opening context manager (``with elect_one():``)
        # that the AST-level value threading cannot see; a result-backed rebind
        # leaks this region's SSA outward, and the enclosing staged-CF executor
        # then yields it from a non-dominating region.
        # Operand/argument accessors return value-caster wrappers (ArithValue,
        # cute pointers) whose ``==`` stages an IR comparison; SSA identity must
        # go through the base ir.Value equality on the unwrapped values.
        def _same_ssa(a: object, b: object) -> bool:
            def unwrap(v: object) -> Optional[ir.Value]:
                if isinstance(v, ir.Value):
                    return v
                inner = getattr(v, "value", None)
                return inner if isinstance(inner, ir.Value) else None

            raw_a, raw_b = unwrap(a), unwrap(b)
            if raw_a is None or raw_b is None:
                return False
            return ir.Value.__eq__(ir.Value(raw_a), ir.Value(raw_b)) is True

        # Accessing operands/arguments runs the registered value casters, and
        # wrapper construction (e.g. the memref _Tensor caster) emits IR at the
        # current insertion point -- park the insertion point at the region's
        # terminator during inspection so those emissions land as valid (dead)
        # in-region ops instead of parent-block ops referencing region values.
        def _terminator_operands_and_args(
            block: ir.Block, skip_args: int = 0
        ) -> "tuple[List[Any], List[Any]]":
            term = block.operations[len(block.operations) - 1]
            with ir.InsertionPoint(term):
                return list(term.operands), list(block.arguments)[skip_args:]

        results: List[ir.Value] = list(op.results)
        if len(results) == len(ir_values):
            if op_type_name == "for":
                # Block args are [induction var, carried...].
                yield_operands, carried_args = _terminator_operands_and_args(
                    op.regions[0].blocks[0], skip_args=1
                )
                for i, (yielded, entry) in enumerate(zip(yield_operands, carried_args)):
                    if _same_ssa(yielded, entry):
                        results[i] = ir_values[i]
            elif op_type_name == "while":
                cond_operands, before_args = _terminator_operands_and_args(
                    op.regions[0].blocks[0]
                )
                yield_operands, after_args = _terminator_operands_and_args(
                    op.regions[1].blocks[0]
                )
                for i, (yielded, entry) in enumerate(zip(yield_operands, after_args)):
                    # cond_operands[0] is the loop condition; forwards start at 1.
                    if _same_ssa(yielded, entry) and _same_ssa(
                        cond_operands[i + 1], before_args[i]
                    ):
                        results[i] = ir_values[i]

        assert isinstance(pytree_def, PyTreeDef)
        final_results = cutlass_dsl.pack_from_irvalue(
            results, pytree_def, mix_iter_args, full_write_args_count, op_type_name
        )

        # 5) Return in a nice pattern
        if not final_results:
            return
        if len(final_results) == 1:
            return final_results[0]
        return final_results


def _attr_const_check(attr: object, expected_type: type, attr_name: str) -> None:
    # Use strict type equality to prevent `bool` being accepted where `int` is required.
    # PyIR's ``_WatchedM`` wraps Python primitives as ``int``/``float`` subclasses for
    # transparent ``isinstance`` propagation; unwrap to the underlying primitive so a
    # ``_WatchedInt`` is accepted where ``int`` is expected.  Bool-vs-int separation is
    # preserved because ``_WatchedBool.python_value`` still returns a real ``bool``.
    raw = getattr(attr, "python_value", attr) if hasattr(attr, "_slot_key") else attr
    if is_dynamic_expression(attr) or type(raw) is not expected_type:
        raise DSLUserCodeError(
            DiagId.PHASE_ASSIGN_PYTHON_TO_TRACKED,
            attr_name=attr_name,
        )


def _loop_execute_range_dynamic(
    func: Callable[..., Any],
    start: Any,
    stop: Any,
    step: Any,
    *,
    write_args: List[Any] = [],
    full_write_args_count: int = 0,
    write_args_names: List[str] = [],
    unroll: int = -1,
    unroll_full: bool = False,
    prefetch_stages: Optional[int] = None,
    vectorize: Optional[bool] = None,
    at_least_once: bool = False,
    **kwargs: Any,
) -> Any:
    """
    Example: build an scf.for with optional unroll, using our universal helper.
    """
    scf_gen = _create_control_flow_generator()
    # The (base, attr) pairs the loop body's ORIGINAL code assigns directly (declared
    # syntactic fact tagged by the PyIR preprocessor); the PyIR generator adopts each
    scf_gen.region_attr_writes = getattr(func, PYIR_REGION_ATTR_WRITES_ATTR, None)
    scf_gen.region_method_calls = getattr(func, PYIR_REGION_METHOD_CALLS_ATTR, None)
    scf_gen.region_free_calls = getattr(func, PYIR_REGION_FREE_CALLS_ATTR, None)
    scf_gen.region_dead_on_entry = getattr(func, PYIR_REGION_DEAD_ON_ENTRY_ATTR, None)
    scf_gen.region_body_func = func

    def create_for_op(dyn_yield_ops: List[ir.Value]) -> ir.Operation:
        for d in dyn_yield_ops:
            if not isinstance(d, ir.Value):
                raise DSLRuntimeError(
                    f"Invalid dyn_yield_ops: {dyn_yield_ops} \n\tExpected ir.Value, got {type(d)}"
                )

        # Convert to Numeric, require integers, then promote to a common integer type
        start_n = as_numeric(start)
        stop_n = as_numeric(stop)
        step_n = as_numeric(step)
        for name, n in (("start", start_n), ("stop", stop_n), ("step", step_n)):
            if not n.dtype.is_integer:
                raise DSLUserCodeError(
                    DiagId.ARG_WRONG_TYPE,
                    name=name,
                    dtype=n.dtype,
                )
        # Promote to a common integer type using pairwise type promotion
        _, _, tmp_dtype = _binary_op_type_promote(start_n, stop_n)
        _, _, dst_dtype = _binary_op_type_promote(start_n.to(tmp_dtype), step_n)
        start_ = start_n.to(dst_dtype)
        stop_ = stop_n.to(dst_dtype)
        step_ = step_n.to(dst_dtype)

        # Attributes must be pure Python value, add a check
        _attr_const_check(unroll, int, "unroll")
        _attr_const_check(unroll_full, bool, "unroll_full")

        # Possibly attach unroll attributes
        unroll_attr = None
        if unroll_full:
            unroll_attr = LoopUnroll(full=True)
        elif unroll != -1:
            unroll_attr = LoopUnroll(count=unroll)
        log().debug("Unroll attribute: %s", unroll_attr)

        prefetch_stages_attr = None
        if prefetch_stages is not None:
            _attr_const_check(prefetch_stages, int, "prefetch_stages")
            if prefetch_stages >= 0:
                prefetch_stages_attr = ir.IntegerAttr.get(
                    ir.IntegerType.get_signless(32), prefetch_stages
                )
            else:
                raise DSLUserCodeError(
                    DiagId.CONFIG_INVALID_VALUE,
                    value=prefetch_stages,
                )
        log().debug("prefetch_stages attribute: %s", prefetch_stages_attr)

        vectorize_attr = None
        if vectorize:
            from ..base_dsl import Arch

            arch = cutlass_dsl.CuTeDSL._get_dsl().get_arch_enum()
            if arch < Arch.sm_100:
                raise DSLUserCodeError(
                    DiagId.UNSUP_ARCH,
                    arch=arch,
                )
            _attr_const_check(vectorize, bool, "vectorize")
            vectorize_attr = ir.BoolAttr.get(True)
        log().debug("vectorize attribute: %s", vectorize_attr)

        log().debug(
            "Creating scf.ForOp \n\t\tstart=%s: type : %s\n\t\tstop=%s: type : %s\n\t\tstep=%s: type : %s",
            start_,
            type(start_),
            stop_,
            type(stop_),
            step_,
            type(step_),
        )
        # LOC_TRACEBACKS captures full Python call stacks automatically —
        # no explicit loc needed.

        # Create scf.ForOp, passing iteration args if any
        try:
            if not dyn_yield_ops:
                for_op = scf.ForOp(
                    start_.ir_value(), stop_.ir_value(), step_.ir_value()
                )
            else:
                for_op = scf.ForOp(
                    start_.ir_value(),
                    stop_.ir_value(),
                    step_.ir_value(),
                    list(dyn_yield_ops),
                )
        except Exception as e:
            yield_ops = "\n".join(
                f"\t\t{i} => {d} : type : {type(d)}"
                for i, d in enumerate(dyn_yield_ops)
            )
            raise DSLRuntimeError(
                f"Failed to create dynamic for loop \n\t\tstart={start_}: type : {type(start_)}"
                f"\n\t\tstop={stop_}: type : {type(stop_)}\n\t\tstep={step_}: type : {type(step_)}"
                f", \n\tdyn_yield_ops:\n{yield_ops}"
            ) from e

        if unroll_attr is not None:
            for_op.attributes["loop_annotation"] = unroll_attr

        if prefetch_stages_attr is not None:
            for_op.attributes["cutlass.pipelining"] = prefetch_stages_attr

        if vectorize_attr is not None:
            for_op.attributes["cutlass.vectorize"] = vectorize_attr

        if at_least_once:
            for_op.attributes["at_least_once"] = ir.UnitAttr.get()

        return for_op

    def for_body_builder(
        op: ir.Operation,
        block_args: List[ir.Value],
        _: List[ir.Value],
        pytree_def: Optional[PyTreeDef],
        mix_iter_args: List[object],
        full_write_args_count: int,
    ) -> object:
        # scf.ForOp block_args are typically [induction_var, iter_args...]
        # But MLIR also gives you op.induction_variable
        iv = t.as_numeric(op.induction_variable)
        if pytree_def is None:
            # PyIR mode: no iter_arg block_args.  Pass original objects.
            func_args = list(mix_iter_args)
        else:
            # Non-pyir: reconstruct from block_args
            func_args = list(
                cutlass_dsl.pack_from_irvalue(
                    block_args[1:], pytree_def, mix_iter_args, full_write_args_count
                )
            )
        if not func_args:
            func(iv)
            return []
        else:
            updated_func_args = func(iv, *func_args)
            return updated_func_args

    # Now call the universal SCF executor with a single region builder
    return scf_gen.scf_execute_dynamic(
        op_type_name="for",
        mix_iter_args=write_args,
        full_write_args_count=full_write_args_count,
        mix_iter_arg_names=write_args_names,
        create_op_func=create_for_op,
        region_builders=[for_body_builder],
    )


def _if_execute_dynamic(
    pred: "ir.Value",
    then_block: Callable[..., object],
    else_block: Optional[Callable[..., object]] = None,
    mix_yield_args: List[object] = [],
    full_write_args_count: int = 0,
    mix_yield_arg_names: List[str] = [],
    branch_weights: Optional[Sequence[int]] = None,
) -> object:
    """
    Build an scf.if with optional else, using our universal helper.
    """
    scf_gen = _create_control_flow_generator()

    def create_if_op(dyn_yield_ops: List[ir.Value]) -> ir.Operation:
        # Assume final result types match the dynamic yields
        result_types = [arg.type for arg in dyn_yield_ops]

        pred_ = Boolean(pred)

        try:
            if_op = scf.IfOp(
                pred_.ir_value(),
                results_=result_types,
                has_else=else_block is not None,
            )
            cutlass_dsl._set_cute_branch_weights(if_op, branch_weights)
        except Exception as e:
            raise DSLRuntimeError(
                f"Failed to create dynamic if \n\t\tpred={pred_}: type : {type(pred_)}"
            ) from e
        return if_op

    def then_builder(
        if_op: ir.Operation,
        _: List[ir.Value],
        dyn_yield_ops: List[ir.Value],
        pytree_def: Optional[PyTreeDef],
        mix_iter_args: List[object],
        full_write_args_count: int,
    ) -> object:
        if pytree_def is None:
            # PyIR mode: pass original objects directly
            return then_block(*mix_iter_args)
        flat_args = list(
            cutlass_dsl.pack_from_irvalue(
                dyn_yield_ops, pytree_def, mix_iter_args, full_write_args_count
            )
        )
        return then_block(*flat_args)

    region_builders = [then_builder]

    if else_block is not None:

        def else_builder(
            if_op: ir.Operation,
            _: List[ir.Value],
            dyn_yield_ops: List[ir.Value],
            pytree_def: Optional[PyTreeDef],
            mix_iter_args: List[object],
            full_write_args_count: int,
        ) -> object:
            if pytree_def is None:
                # PyIR mode: pass original objects directly
                return else_block(*mix_iter_args)
            flat_args = list(
                cutlass_dsl.pack_from_irvalue(
                    dyn_yield_ops, pytree_def, mix_iter_args, full_write_args_count
                )
            )
            return else_block(*flat_args)

        region_builders.append(else_builder)

    return scf_gen.scf_execute_dynamic(
        op_type_name="if",
        mix_iter_args=mix_yield_args,
        full_write_args_count=full_write_args_count,
        mix_iter_arg_names=mix_yield_arg_names,
        create_op_func=create_if_op,
        region_builders=region_builders,
    )


def _while_execute_dynamic(
    while_before_block: Callable[..., Any],
    while_after_block: Optional[Callable[..., Any]] = None,
    write_args: List[Any] = [],
    full_write_args_count: int = 0,
    write_args_names: List[str] = [],
) -> Any:
    """
    Create and return an SCF WhileOp for dynamic loops.
    Generate the dynamic loop body using SCF WhileOp.

    Args:
        while_before_block: Function that returns (condition, updated_values)
        while_after_block: Function that returns updated values
        write_args: Values that are updated in the loop

    See create_while_function in ast_preprocessor.py for details on the input structure.
    """
    log().debug("_while_execute_dynamic")
    while_op_type_name = "while"
    scf_gen = _create_control_flow_generator()

    # PyIR-specific path for while loops
    if is_pyir_enabled():
        from .cutlass_ast_decorators_pyir import PyIRScfGenerator

        assert isinstance(scf_gen, PyIRScfGenerator)
        return scf_gen.create_while_op_pyir(
            while_before_block,
            while_after_block,
            write_args,
            full_write_args_count,
            write_args_names,
        )

    # Non-PyIR path
    def create_while_op(dyn_yield_ops: List[ir.Value]) -> ir.Operation:
        # Create the while operation with the types from yield_args
        result_types = [arg.type for arg in dyn_yield_ops]

        try:
            while_op = scf.WhileOp(result_types, dyn_yield_ops)
            while_op.before.blocks.append(*result_types)
            while_op.after.blocks.append(*result_types)
            return while_op
        except Exception as e:
            yield_ops = "\n".join(
                f"\t\t{i} => {d} : type : {type(d)}"
                for i, d in enumerate(dyn_yield_ops)
            )
            raise DSLRuntimeError(
                f"Failed to create dynamic while loop with yield_ops:\n{yield_ops}"
            ) from e

    def before_block_builder(
        op: ir.Operation,
        block_args: List[ir.Value],
        _: List[ir.Value],
        pytree_def: PyTreeDef,
        mix_iter_args: List[Any],
        full_write_args_count: int,
    ) -> Any:
        # Build the before (condition) block
        flat_args = list(
            cutlass_dsl.pack_from_irvalue(
                block_args, pytree_def, mix_iter_args, full_write_args_count
            )
        )

        cond, before_results = while_before_block(*flat_args)

        if not isinstance(before_results, (list, ir.OpResultList)):
            before_results = [before_results]

        log().debug("cond [%s]", cond)
        return cond, before_results

    def before_block_terminator(
        cond_and_results: Any, full_write_args_count: int
    ) -> None:
        # Generate a condition op instead of yield op.
        cond = cond_and_results[0]
        ir_cond = Boolean(truth_of(cond)).ir_value()
        before_result_list = ScfGenerator._normalize_region_result_to_list(
            cond_and_results[1]
        )
        ir_results_list, pytree_def = cutlass_dsl.unpack_to_irvalue(
            before_result_list, while_op_type_name, full_write_args_count
        )
        scf.ConditionOp(ir_cond, ir_results_list)

    def after_block_builder(
        op: ir.Operation,
        block_args: List[ir.Value],
        _: List[ir.Value],
        pytree_def: PyTreeDef,
        mix_iter_args: List[object],
        full_write_args_count: int,
    ) -> object:
        # Build the after (body) block
        flat_args = list(
            cutlass_dsl.pack_from_irvalue(
                block_args, pytree_def, mix_iter_args, full_write_args_count
            )
        )

        assert while_after_block is not None
        after_results = while_after_block(*flat_args)

        if not isinstance(after_results, (list, ir.OpResultList)):
            after_results = [after_results]

        return after_results

    # Call the universal SCF executor with two region builders
    return scf_gen.scf_execute_dynamic(
        op_type_name=while_op_type_name,
        mix_iter_args=write_args,
        full_write_args_count=full_write_args_count,
        mix_iter_arg_names=write_args_names,
        create_op_func=create_while_op,
        region_builders=[before_block_builder, after_block_builder],
        block_term_op_builder={
            before_block_builder: before_block_terminator
        },  # Only customize the before block
    )


def _ifexp_execute_dynamic(
    pred: "ir.Value",
    block_args: tuple,
    then_block: Callable[..., object],
    else_block: Callable[..., object],
    branch_weights: Optional[Sequence[int]] = None,
) -> object:
    """
    Dynamically execute a Python inline if-expression (ternary) as a runtime-dispatched control flow op.

    This function builds an SCF (Structured Control Flow) `if` operation in the IR, using the given
    predicate and block functions for the 'then' and 'else' branches, and infers the result types
    from the return signature of those blocks. It ensures that both branches return values of the same
    tree structure and types, so that the IR op can properly yield their results.

    Parameters
    ----------
    pred : ir.Value
        The predicate value (a boolean IR value) that determines which branch is executed.
    block_args : tuple
        The block arguments that are passed to the then and else blocks.
    then_block : Callable
        A Python function that executes the 'then' branch and returns the result(s). This will be
        executed if `pred` evaluates to True.
    else_block : Callable
        A Python function that executes the 'else' branch and returns the result(s). This will be
        executed if `pred` evaluates to False.

    Returns
    -------
    list
        The evaluated result(s) of the selected branch, in a standardized (possibly list-wrapped) format.

    Raises
    ------
    DSLRuntimeError
        If the 'then' and 'else' blocks return values of different tree structures or types,
        or if IR construction fails.

    Notes
    -----
    This function is a low-level implementation intended for use by the AST transformation machinery,
    and not for direct user invocation. It acts as the backend for transformed Python inline if-expressions.
    """
    # scf.IfOp needs its result types at creation, but they are only known
    # once the arms have been traced.  Trace each arm exactly once into its own
    # scratch block of a temporary execute_region, create the IfOp from the
    # inferred types, then MOVE the traced ops into the real regions.  Tracing
    # the arm closures a second time would replay their Python side effects
    # and leave every object they mutated (e.g. a PipelineState advanced in
    # the arm) holding SSA values of the erased scratch ops.
    execution_region = scf.ExecuteRegionOp(result=[])
    then_scratch = execution_region.region.blocks.append()
    else_scratch = execution_region.region.blocks.append()

    try:
        # PyIR: judge each arm's candidate objects right after the arm is
        # traced and BEFORE extraction (which sights every object it walks):
        # a candidate that pre-exists the open region, or that storage
        # outliving the expression holds, gets the write wall on the merged
        # result; a merge of two unsighted temporaries is a fresh object
        # whose writes are exact.  The result list and the arm closure are
        # the executor's own references, not sightings.
        with ir.InsertionPoint(then_scratch):
            # Each scratch block is a staged-region boundary for the read choke
            # (like an scf.if branch): a load cached in one branch must not serve
            # the other branch or the code after the ternary.
            _pyir_bump_region_epoch()
            then_results = ScfGenerator._normalize_region_result_to_list(
                then_block(*block_args)
            )
            then_sight = _pyir_staged_selection_presight(
                then_results,
                (then_results, getattr(then_block, "__closure__", None)),
            )
            ir_values, then_tree = cutlass_dsl.unpack_to_irvalue(
                then_results, "ifexp", 0
            )

        with ir.InsertionPoint(else_scratch):
            _pyir_bump_region_epoch()
            else_results = ScfGenerator._normalize_region_result_to_list(
                else_block(*block_args)
            )
            else_sight = _pyir_staged_selection_presight(
                else_results,
                (else_results, getattr(else_block, "__closure__", None)),
            )
            _, else_tree = cutlass_dsl.unpack_to_irvalue(else_results, "ifexp", 0)

        # Back at the outer scope: another boundary, so nothing cached inside
        # a scratch block (erased below) is served out here.
        _pyir_bump_region_epoch()

        assert isinstance(then_tree, PyTreeDef)
        assert isinstance(else_tree, PyTreeDef)
        if (
            len(then_tree.child_treedefs) != len(else_tree.child_treedefs)
            or check_tree_equal(then_tree, else_tree) != -1
        ):
            raise DSLUserCodeError(
                DiagId.TYPE_CONDITIONAL_BRANCH_MISMATCH,
            )

        # Collect result types for the SCF IfOp
        result_types = [arg.type for arg in ir_values]
        mix_iter_args = list(then_results)

        # PyIR: pair the two arms' candidate objects once for the packing
        # bracket below (a pair that is one object adopts it).
        arm_verdicts = _pyir_staged_selection_verdicts(
            then_results, else_results, then_sight, else_sight
        )
        # PyIR: a plain dataclass result is packed IN PLACE on its template,
        # so pack into fresh instances instead of the then-arm objects (the
        # program still holds those); each fresh node is recorded below as a
        # staged selection like a rebuilt value-protocol product.
        selection_copies: List[Any] = []
        if is_pyir_enabled():
            mix_iter_args = [
                _pyir_fresh_selection_template(t_res, e_res, selection_copies)
                for t_res, e_res in zip(then_results, else_results)
            ] + mix_iter_args[len(else_results) :]

        # Set up a generator for SCF op creation
        scf_gen = ScfGenerator()

        # Function to create the IfOp with correct predicate and result types
        def create_if_op(_: List[ir.Value]) -> ir.Operation:
            pred_ = Boolean(pred)
            try:
                if_op = scf.IfOp(
                    pred_.ir_value(),
                    results_=result_types,
                    has_else=else_block is not None,
                )
                cutlass_dsl._set_cute_branch_weights(if_op, branch_weights)
            except Exception as e:
                raise DSLRuntimeError(
                    f"Failed to create dynamic if-expression \n\t\tpred={pred_}: type : {type(pred_)}"
                ) from e
            return if_op

        def _adopt_scratch_ops(scratch: ir.Block, target: ir.Block) -> None:
            """Move the ops traced into ``scratch`` to the end of ``target``
            (the region block the generator is about to terminate)."""
            for scratch_op in list(scratch.operations):
                target.append(scratch_op)

        def then_builder(if_op: ir.Operation, *args: object) -> object:
            _adopt_scratch_ops(then_scratch, if_op.regions[0].blocks[0])
            return then_results

        def else_builder(if_op: ir.Operation, *args: object) -> object:
            _adopt_scratch_ops(else_scratch, if_op.regions[1].blocks[0])
            return else_results

        # Prepare the list of region builders for the SCF IfOp: first for "then", then for "else"
        region_builders = [then_builder, else_builder]

        # IfExp (ternary) always has results and its create_if_op hardcodes
        # result_types, so use "ifexp" as op_type_name to ensure standard execution.
        #
        # The packed result is rebuilt from the THEN arm's template object; it
        # is a merge of both arms' values, not that object.  The PyIR bracket
        # keeps the rebuilt object from adopting the then-arm object's slot
        # identity (a field read would otherwise serve the then-arm value and
        # a field write would land on the then-arm object) and records it so
        # a later field write through it refuses (OWNER_STAGED_SELECTION_WRITE).
        with _pyir_staged_selection_scope(arm_verdicts):
            ret = scf_gen.scf_execute_dynamic(
                op_type_name="ifexp",
                mix_iter_args=mix_iter_args,
                full_write_args_count=0,
                mix_iter_arg_names=["unknown" for _ in mix_iter_args],
                create_op_func=create_if_op,
                region_builders=region_builders,
            )
            for fresh, then_node in selection_copies:
                _pyir_register_staged_selection(fresh, arm_verdicts.get(id(then_node)))
    finally:
        # Clean up: Remove the (now empty) temporary execution region from the IR graph
        execution_region.operation.erase()

    return ret
