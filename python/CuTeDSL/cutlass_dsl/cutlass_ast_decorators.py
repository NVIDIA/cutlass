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

from typing import List, Tuple
from cutlass._mlir import ir
from cutlass._mlir.dialects import scf, arith
from cutlass._mlir.extras import types as T

from ..base_dsl.dsl import extract_mlir_values, new_from_mlir_values
from ..base_dsl.ast_helpers import *
from ..base_dsl.utils.logger import log
from ..base_dsl import typing as t
from ..base_dsl.typing import Int32, Float32, Boolean, Numeric, get_mlir_types
from . import cutlass as cutlass_dsl

# =============================================================================
# AST Helpers
# =============================================================================


class LoopUnroll(ir.Attribute):
    def __init__(self, **kwargs):
        valid_keys = set(["count", "full"])
        def to_mlir_attr(val):
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

    def __init__(self):
        pass

    @staticmethod
    def fill_none(ir_values, unpacked_values):
        i = 0
        for idx, item in enumerate(unpacked_values):
            if item is not None:
                unpacked_values[idx] = ir_values[i]
                i += 1

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
    def check_region_result(region_values, ir_values):
        for i, (expected_value, actual_value) in enumerate(
            zip(ir_values, region_values)
        ):
            expected_value_type = get_mlir_types(expected_value)
            actual_value_type = get_mlir_types(actual_value)
            if expected_value_type != actual_value_type:
                return False, i, expected_value_type, actual_value_type
        return True, -1, None, None

    def scf_execute_dynamic(
        self,
        op_type_name: str,
        used_args: List[Any],
        mix_iter_args: List[Any],
        mix_iter_arg_names: List[str],
        create_op_func: Callable[
            [List[ir.Value], Dict[int, Tuple[int, int]], List[Any]], ir.Operation
        ],
        region_builders: List[
            Callable[
                [
                    "ir.Operation",
                    List["ir.Value"],  # block_args
                    List[Any],  # used_args
                    List["ir.Value"],  # dyn_yield_ops
                    Dict[int, Tuple[int, int]],
                    List[Any],
                ],
                Any,
            ]
        ],
        # block_term_op_builder[region_builder] = scf_op_builder
        # e.g. scf.ConditionOp for while loop
        block_term_op_builder: Dict[Callable, Callable] = {},
    ) -> Any:
        # 1) Unpack
        ir_values, dyn_unpacked_values, dyn_indices, dyn_class_types = (
            cutlass_dsl.unpack_to_irvalue(mix_iter_args, op_type_name)
        )
        # 2) Create the SCF op
        op = create_op_func(ir_values, dyn_indices, dyn_class_types)
        log().debug("Generated scf.%s \n[%s]", op_type_name, op)

        # 3) Build the regions
        for i, builder in enumerate(region_builders):
            region = op.regions[i]
            block = region.blocks[0]
            with ir.InsertionPoint(block):
                block_args = list(block.arguments)
                region_result = builder(
                    op,
                    block_args,
                    used_args,
                    dyn_unpacked_values,
                    dyn_indices,
                    dyn_class_types,
                )

                # Use custom terminator if provided for this builder, otherwise use default YieldOp
                if builder in block_term_op_builder:
                    # Use the provided terminator generator
                    block_term_op_builder[builder](region_result)
                else:
                    # Normalize region_result
                    region_result_list = ScfGenerator._normalize_region_result_to_list(
                        region_result
                    )
                    # Default behavior - generate YieldOp
                    region_values, unpacked_values, _, _ = (
                        cutlass_dsl.unpack_to_irvalue(region_result_list, op_type_name)
                    )

                    is_match, mismatch_idx, expected_type, actual_type = (
                        ScfGenerator.check_region_result(region_values, ir_values)
                    )

                    if not is_match:
                        # From unpacked index, we need to find the original index
                        original_idx = -1
                        for unpacked_idx, (original_idx, length) in dyn_indices.items():
                            if (
                                mismatch_idx >= original_idx
                                and mismatch_idx < original_idx + length
                            ):
                                original_idx = unpacked_idx
                                break
                        raise DSLRuntimeError(
                            f"`{op_type_name}` expects {expected_type} type for varible `{mix_iter_arg_names[original_idx]}`, but got {actual_type}.",
                            suggestion=f"Please make sure `{mix_iter_arg_names[original_idx]}` type is not changed inside of `{op_type_name}`.",
                        )
                    scf.YieldOp(region_values)

        log().debug("Completed scf.%s \n[%s]", op_type_name, op)
        ScfGenerator.fill_none(op.results, unpacked_values)

        # 4) Pack final results
        final_results = cutlass_dsl.pack_from_irvalue(
            unpacked_values, dyn_indices, dyn_class_types
        )

        # 5) Return in a nice pattern
        if not final_results:
            return
        if len(final_results) == 1:
            return final_results[0]
        return final_results


def _loop_execute_range_dynamic(
    func: Callable,
    start: Any,
    stop: Any,
    step: Any,
    used_args: List[Any] = [],
    mix_iter_args: List[Any] = [],
    mix_iter_arg_names: List[str] = [],
    unroll: int = -1,
    unroll_full: bool = False,
):
    """
    Example: build an scf.for with optional unroll, using our universal helper.
    """
    scf_gen = ScfGenerator()

    def create_for_op(
        dyn_yield_ops: List[ir.Value],
        dyn_indices: Dict[int, Tuple[int, int]],
        dyn_class_types: List[Any],
    ):
        for d in dyn_yield_ops:
            if not isinstance(d, ir.Value):
                raise DSLRuntimeError(
                    f"Invalid dyn_yield_ops: {dyn_yield_ops} \n\tExpected ir.Value, got {type(d)}"
                )

        # Convert Python ints or values to IR constants if needed
        start_ = t.as_numeric(start)
        stop_ = t.as_numeric(stop)
        step_ = t.as_numeric(step)
        assert start_ is not t.Int32, "Start is required for scf.for"
        assert stop_ is not t.Int32, "Stop is required for scf.for"
        assert step_ is not t.Int32, "Step is required for scf.for"
        start_ = start_.ir_value()
        stop_ = stop_.ir_value()
        step_ = step_.ir_value()

        # Possibly attach unroll attributes
        unroll_attr = None
        if unroll_full:
            unroll_attr = LoopUnroll(full=True)
        elif unroll != -1:
            unroll_attr = LoopUnroll(count=unroll)
        log().debug("Unroll attribute: %s", unroll_attr)

        log().debug(
            "Creating scf.ForOp \n\t\tstart=%s: type : %s\n\t\tstop=%s: type : %s\n\t\tstep=%s: type : %s",
            start_,
            type(start_),
            stop_,
            type(stop_),
            step_,
            type(step_),
        )
        # Create scf.ForOp, passing iteration args if any
        try:
            if not dyn_yield_ops:
                for_op = scf.ForOp(start_, stop_, step_)
            else:
                for_op = scf.ForOp(start_, stop_, step_, list(dyn_yield_ops))
        except Exception as e:
            yield_ops = "\n".join(
                f"\t\t{i} => {d} : type : {type(d)}"
                for i, d in enumerate(dyn_yield_ops)
            )
            raise DSLRuntimeError(
                f"Failed to create scf.ForOp \n\t\tstart={start_}: type : {type(start_)}"
                f"\n\t\tstop={stop_}: type : {type(stop_)}\n\t\tstep={step_}: type : {type(step_)}"
                f", \n\tdyn_yield_ops:\n{yield_ops}"
            ) from e

        if unroll_attr is not None:
            for_op.attributes["loop_annotation"] = unroll_attr

        return for_op

    def for_body_builder(
        op, block_args, used_args, dyn_yield_ops, dyn_indices, dyn_class_types
    ):
        # Insert induction variable at the beginning
        dyn_yield_ops.insert(0, block_args[0])
        ScfGenerator.fill_none(block_args, dyn_yield_ops)
        block_args = dyn_yield_ops
        # scf.ForOp block_args are typically [induction_var, iter_args...]
        # But MLIR also gives you op.induction_variable
        iv = t.as_numeric(op.induction_variable)
        log().debug(
            "For body builder: %s block_args: %s used_args: %s",
            iv,
            block_args,
            used_args,
        )
        if len(block_args) <= 1:
            # No iteration arguments, or only the induction var
            func(iv, *used_args)
            return []  # yield nothing
        else:
            # block_args[1:] are iteration variables
            func_args = [*used_args]
            func_args.extend(
                cutlass_dsl.pack_from_irvalue(
                    block_args[1:], dyn_indices, dyn_class_types
                )
            )
            updated_func_args = func(iv, *func_args)
            return updated_func_args

    # Now call the universal SCF executor with a single region builder
    return scf_gen.scf_execute_dynamic(
        op_type_name="for",
        used_args=used_args,
        mix_iter_args=mix_iter_args,
        mix_iter_arg_names=mix_iter_arg_names,
        create_op_func=create_for_op,
        region_builders=[for_body_builder],
    )


def _if_execute_dynamic(
    pred: "ir.Value",
    then_block: Callable,
    else_block: Callable = None,
    used_args: List[Any] = [],
    mix_yield_args: List[Any] = [],
    mix_yield_arg_names: List[str] = [],
    if_constexpr=None,  # ignoring for brevity
):
    """
    Build an scf.if with optional else, using our universal helper.
    """
    scf_gen = ScfGenerator()

    def create_if_op(
        dyn_yield_ops: List[ir.Value],
        dyn_indices: Dict[int, Tuple[int, int]],
        dyn_class_types: List[Any],
    ):
        # Assume final result types match the dynamic yields
        result_types = [arg.type for arg in dyn_yield_ops]

        pred_ = Boolean(pred)

        try:
            if_op = scf.IfOp(
                pred_.ir_value(),
                hasElse=(else_block is not None),
                results_=result_types,
            )
        except Exception as e:
            raise DSLRuntimeError(
                f"Failed to create scf.IfOp \n\t\tpred={pred_}: type : {type(pred_)}"
            ) from e
        return if_op

    def then_builder(
        if_op, block_args, used_args, dyn_yield_ops, dyn_indices, dyn_class_types
    ):
        flat_args = [*used_args]
        flat_args.extend(
            cutlass_dsl.pack_from_irvalue(dyn_yield_ops, dyn_indices, dyn_class_types)
        )
        return then_block(*flat_args)

    region_builders = [then_builder]

    if else_block is not None:

        def else_builder(
            if_op, block_args, used_args, dyn_yield_ops, dyn_indices, dyn_class_types
        ):
            flat_args = [*used_args]
            flat_args.extend(
                cutlass_dsl.pack_from_irvalue(
                    dyn_yield_ops, dyn_indices, dyn_class_types
                )
            )
            return else_block(*flat_args)

        region_builders.append(else_builder)

    return scf_gen.scf_execute_dynamic(
        op_type_name="if",
        used_args=used_args,
        mix_iter_args=mix_yield_args,
        mix_iter_arg_names=mix_yield_arg_names,
        create_op_func=create_if_op,
        region_builders=region_builders,
    )


def _while_execute_dynamic(
    while_before_block: Callable,
    while_after_block: Callable = None,
    used_args=[],
    yield_args=[],
    yield_arg_names=[],
):
    """
    Create and return an SCF WhileOp for dynamic loops.
    Generate the dynamic loop body using SCF WhileOp.

    Args:
        while_before_block: Function that returns (condition, updated_values)
        while_after_block: Function that returns updated values
        used_args: Additional arguments used in the loop body
        yield_args: Values that are updated in the loop

    See create_while_function in ast_preprocessor.py for details on the input structure.
    """
    log().debug("_while_execute_dynamic")
    while_op_type_name = "while"
    scf_gen = ScfGenerator()

    def create_while_op(
        dyn_yield_ops: List[ir.Value],
        dyn_indices: Dict[int, Tuple[int, int]],
        dyn_class_types: List[Any],
    ):
        # Create the while operation with the types from yield_args
        result_types = [arg.type for arg in dyn_yield_ops]
        try:
            while_op = scf.WhileOp(result_types, dyn_yield_ops)
            while_op.before.blocks.append(*result_types)
            while_op.after.blocks.append(*result_types)
            log().debug("[%s]", while_op)
            return while_op
        except Exception as e:
            yield_ops = "\n".join(
                f"\t\t{i} => {d} : type : {type(d)}"
                for i, d in enumerate(dyn_yield_ops)
            )
            raise DSLRuntimeError(
                f"Failed to create scf.WhileOp with yield_ops:\n{yield_ops}"
            ) from e

    def before_block_builder(
        op, block_args, used_args, dyn_yield_ops, dyn_indices, dyn_class_types
    ):
        # Build the before (condition) block
        ScfGenerator.fill_none(block_args, dyn_yield_ops)
        block_args = dyn_yield_ops
        flat_args = [*used_args]
        flat_args.extend(
            cutlass_dsl.pack_from_irvalue(block_args, dyn_indices, dyn_class_types)
        )

        log().debug("before block args: %s", flat_args)

        cond, before_results = while_before_block(*flat_args)

        if not isinstance(before_results, (list, ir.OpResultList)):
            before_results = [before_results]

        log().debug("cond [%s]", cond)
        log().debug(
            "before_results [%s]",
            before_results,
        )

        return cond, before_results

    def before_block_terminator(cond_and_results):
        # Generate a condition op instead of yield op
        cond = cond_and_results[0]
        before_result_list = ScfGenerator._normalize_region_result_to_list(
            cond_and_results[1]
        )
        ir_cond_list, _, _, _ = cutlass_dsl.unpack_to_irvalue(
            [cond], while_op_type_name
        )
        ir_cond = ir_cond_list[0]
        ir_results_list, _, _, _ = cutlass_dsl.unpack_to_irvalue(
            before_result_list, while_op_type_name
        )
        log().debug(
            "creating scf.ConditionOp with [%s], [%s]",
            ir_cond,
            ir_results_list,
        )
        scf.ConditionOp(ir_cond, ir_results_list)

    def after_block_builder(
        op, block_args, used_args, dyn_yield_ops, dyn_indices, dyn_class_types
    ):
        # Build the after (body) block
        ScfGenerator.fill_none(block_args, dyn_yield_ops)
        block_args = dyn_yield_ops
        flat_args = [*used_args]
        flat_args.extend(
            cutlass_dsl.pack_from_irvalue(block_args, dyn_indices, dyn_class_types)
        )

        log().debug("after block args: %s", flat_args)

        after_results = while_after_block(*flat_args)

        if not isinstance(after_results, (list, ir.OpResultList)):
            after_results = [after_results]

        log().debug(
            "after_results [%s]",
            after_results,
        )

        return after_results

    # Call the universal SCF executor with two region builders
    return scf_gen.scf_execute_dynamic(
        op_type_name=while_op_type_name,
        used_args=used_args,
        mix_iter_args=yield_args,
        mix_iter_arg_names=yield_arg_names,
        create_op_func=create_while_op,
        region_builders=[before_block_builder, after_block_builder],
        block_term_op_builder={
            before_block_builder: before_block_terminator
        },  # Only customize the before block
    )
