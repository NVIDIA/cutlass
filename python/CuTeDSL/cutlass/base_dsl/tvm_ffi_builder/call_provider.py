# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Call provider that implements a specific calling convention."""

from dataclasses import dataclass
from typing import Optional, Union

from . import spec
from ..._mlir import ir
from ..._mlir.dialects import llvm
from .tvm_ffi_builder import CallContext, CallProvider, TVMFFIBuilder


def _flatten_tuple_params(params: list[spec.Param]) -> list[spec.Param]:
    """Recursively flatten TupleParam into list of params."""
    flattened = []
    for param in params:
        if isinstance(param, spec.TupleParam):
            # Recursively flatten nested tuples
            flattened.extend(_flatten_tuple_params(param.params))
        else:
            flattened.append(param)
    return flattened


class NopCallProvider(CallProvider):
    """No-op call provider for testing purposes."""

    def __call__(self, current_block: ir.Block, context: CallContext) -> ir.Block:
        """No-op call provider that just returns the current block."""
        return current_block


class DynamicParamPackCallProvider(CallProvider, TVMFFIBuilder):
    """Packs dynamic arguments to a struct then calls the function.

    .. code-block:: c

        void call(Tensor0 t0, Tensor1 t1) {
            // packed arguments
            void** packed_args[] = {&t0, &t1};
            // call target
            target_func(packed_args);
        }

    Parameters
    ----------
    target_func: str
        The name of the target function.

    include_num_args: bool
        Whether to include the number of arguments in the packed arguments.

    struct_call: bool
        Whether to use the struct call convention.
    """

    def __init__(
        self,
        target_func: str,
        include_num_args: bool = False,
        struct_call: bool = False,
        flatten_tuple_params: bool = True,
    ) -> None:
        import tvm_ffi

        TVMFFIBuilder.__init__(self)
        self.target_func = target_func
        self.include_num_args = include_num_args
        self.struct_call = struct_call
        self.flatten_tuple_params = flatten_tuple_params
        self.float4x2_dtype = tvm_ffi.dtype("float4_e2m1fnx2")

        if not self.flatten_tuple_params:
            raise RuntimeError("flatten_tuple_params=False is not supported yet")

    def get_callee_struct_for_param_tensor(
        self,
        param: spec.Tensor,
        current_block: ir.Block,
        data: ir.Value,
        shape: list[ir.Value],
        strides: list[ir.Value],
        flatten_struct: ir.Type,
    ) -> ir.Type:
        """Routine used to override tensor passsing struct conention."""
        return flatten_struct

    def pack_param_tensor(
        self, current_block: ir.Block, context: CallContext, param: spec.Tensor
    ) -> tuple[ir.Type, ir.Value]:
        """Pack a tensor parameter to a struct."""
        map_shape_value = lambda _, value: value
        map_stride_value = lambda _, value: value

        if param.map_tensor_dtype_f4x2_to_f4 and param.dtype == self.float4x2_dtype:
            # specially handle f4x2 to f4 tensor conversion
            # we multiply the stride by 2 for all dimensions except the one with stride=1
            # we also multiply the shape by 2 for the specific dimension with stride=1
            def find_stride_one_index() -> int:
                if param.strides is None:
                    return len(param.shape) - 1
                for i, stride in enumerate(param.strides):
                    if isinstance(stride, int) and stride == 1:
                        return i
                raise ValueError("stride=1 index not found, needed for f4 tensor")
            stride_one_index = find_stride_one_index()

            def map_shape_for_tensor_dtype_f4x2_to_f4(index: int, value: ir.Value) -> ir.Value:
                if index == stride_one_index:
                    with ir.InsertionPoint(current_block):
                        return self.mul(value, self.integer_constant(value.type, 2))
                return value

            def map_stride_for_tensor_dtype_f4x2_to_f4(index, value: ir.Value) -> ir.Value:
                if index != stride_one_index:
                    with ir.InsertionPoint(current_block):
                        return self.mul(value, self.integer_constant(value.type, 2))
                return value

            map_shape_value = map_shape_for_tensor_dtype_f4x2_to_f4
            map_stride_value = map_stride_for_tensor_dtype_f4x2_to_f4

        data = context.matched_var_binding[param.data]
        shape = []
        strides = []
        # append all vars in shape
        for index, dim in enumerate(param.shape):
            if isinstance(dim, spec.Var):
                shape.append(map_shape_value(index, context.matched_var_binding[dim]))
        # append all vars in strides
        if param.strides is not None:
            for index, dim in enumerate(param.strides):
                if isinstance(dim, spec.Var):
                    strides.append(map_stride_value(index, context.matched_var_binding[dim]))
        flatten_struct, alloca = self.pack_values_to_alloca(
            current_block, context.entry_block, [data, *shape, *strides]
        )
        callee_struct = self.get_callee_struct_for_param_tensor(
            param, current_block, data, shape, strides, flatten_struct
        )

        return callee_struct, alloca

    def pack_param_var(
        self, current_block: ir.Block, context: CallContext, param: spec.Var
    ) -> tuple[ir.Type, ir.Value]:
        """Pack a var parameter to a struct."""
        value: ir.Value = context.matched_var_binding[param]
        _, alloca = self.pack_values_to_alloca(
            current_block, context.entry_block, [value]
        )
        return (value.type, alloca)

    def pack_param_shape(
        self, current_block: ir.Block, context: CallContext, param: spec.Shape
    ) -> tuple[ir.Type, ir.Value]:
        """Pack a shape parameter to a struct."""
        dynamic_args: list[ir.Value] = []
        for dim in param.shape:
            if isinstance(dim, spec.Var):
                dynamic_args.append(context.matched_var_binding[dim])
        return self.pack_values_to_alloca(
            current_block, context.entry_block, dynamic_args
        )

    def pack_params(
        self, current_block: ir.Block, context: CallContext
    ) -> list[tuple[ir.Type, ir.Value]]:
        """Pack a parameter to a struct."""
        # Flatten TupleParam into list of params if enabled
        if self.flatten_tuple_params:
            flattened_params = _flatten_tuple_params(context.params)
        else:
            flattened_params = context.params

        # Pack each parameter
        packed_params = []
        for param in flattened_params:
            if isinstance(param, spec.Tensor):
                packed_params.append(
                    self.pack_param_tensor(current_block, context, param)
                )
            elif isinstance(param, spec.Var):
                packed_params.append(self.pack_param_var(current_block, context, param))
            elif isinstance(param, spec.Shape):
                packed_params.append(
                    self.pack_param_shape(current_block, context, param)
                )
            elif isinstance(param, (spec.Stream, spec.EnvStream)):
                packed_params.append(
                    self.pack_param_var(current_block, context, param.var)
                )
            elif isinstance(param, spec.DataPointer):
                packed_params.append(
                    self.pack_param_var(current_block, context, param.var)
                )
            elif isinstance(param, spec.ConstNone):
                # const none is not packed
                continue
            else:
                raise NotImplementedError(f"Unsupported parameter type: {type(param)}")
        return packed_params

    def generate_llvm_call(
        self,
        current_block: ir.Block,
        call_operands: list[ir.Value],
        context: CallContext,
    ) -> ir.Block:
        """Generate the LLVM call operation."""
        with ir.InsertionPoint(current_block):
            llvm.call(
                result=None,
                callee=self.target_func,
                callee_operands=call_operands,
                op_bundle_sizes=[],
                op_bundle_operands=[],
            )
        return current_block

    def load_to_call_operands(
        self,
        struct_type: Union[ir.Type, tuple[ir.Type]],
        alloca: Union[ir.Value, tuple[ir.Value]],
    ) -> list[ir.Value]:
        """Load the packed parameters to the call operands."""
        assert (isinstance(struct_type, ir.Type) and isinstance(alloca, ir.Value)) or (
            isinstance(struct_type, tuple) and isinstance(alloca, tuple)
        )
        if isinstance(struct_type, tuple):
            return [
                llvm.load(struct_type[i], alloca[i]) for i in range(len(struct_type))
            ]
        return [llvm.load(struct_type, alloca)]

    def __call__(self, current_block: ir.Block, context: CallContext) -> ir.Block:
        """Alloca call provider that uses dynamic param pack call convention."""
        packed_params = self.pack_params(current_block, context)

        if self.struct_call:
            # load back arguments as structs from alloca
            call_operands = []
            with ir.InsertionPoint(current_block):
                for struct_type, alloca in packed_params:
                    call_operands += self.load_to_call_operands(struct_type, alloca)
        else:
            # pack the values to an alloca that we can pass as void**
            all_values = []
            for _, value in packed_params:
                if isinstance(value, tuple):
                    all_values.extend(value)
                else:
                    all_values.append(value)
            _, packed_args_value = self.pack_values_to_alloca(
                current_block, context.entry_block, all_values
            )

            call_operands = [packed_args_value]
            if self.include_num_args:
                with ir.InsertionPoint(current_block):
                    num_args = self.i32(len(all_values))
                    call_operands.append(num_args)

        current_block = self.generate_llvm_call(current_block, call_operands, context)
        return current_block
