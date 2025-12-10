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

from cutlass.base_dsl.tvm_ffi_builder import (
    DynamicParamPackCallProvider,
    CallContext,
    rename_tvm_ffi_function,
    spec,
)
from cutlass._mlir import ir
from cutlass._mlir.dialects import llvm
from cutlass._mlir._mlir_libs._cutlass_ir import _execution_engine_extra
from cutlass.cutlass_dsl.cuda_jit_executor import CudaDialectJitCompiledFunction
from cutlass.base_dsl.common import DSLRuntimeError
from typing import Optional
import tvm_ffi


class TVMFFICuteCallProvider(DynamicParamPackCallProvider):
    """Cute call provider that uses cute call convention."""

    cuda_device_index: Optional[ir.Value]
    cuda_error_handle_block: Optional[ir.Block]

    def __init__(self, target_func: str):
        super().__init__(target_func, struct_call=True)
        self.cuda_global_state_symbol = f"__{target_func}_cuda_state"
        self.cuda_device_index = None
        self.cuda_error_handle_block = None

    def get_callee_struct_for_param_tensor(
        self,
        param: spec.Tensor,
        current_block: ir.Block,
        data: ir.Value,
        shape: list[ir.Value],
        strides: list[ir.Value],
        flatten_struct: ir.Type,
    ) -> ir.Type:
        """Routine used to override the tensor passing struct convention"""
        with ir.InsertionPoint(current_block):
            if param.dlpack_device_type == tvm_ffi.DLDeviceType.kDLCPU:
                data_type = self.ptr_type
            else:
                data_type = self.gpu_ptr_type
            strides_type = (
                self.struct_type(fields=[x.type for x in strides])
                if len(strides) != 1
                else strides[0].type
            )
            shape_type = (
                self.struct_type(fields=[x.type for x in shape])
                if len(shape) != 1
                else shape[0].type
            )
            shape_stride_tuple_type = self.struct_type(
                fields=[shape_type, strides_type]
            )
            tensor_type = self.struct_type(fields=[data_type, shape_stride_tuple_type])
            return tensor_type

    def pack_param_shape(
        self, current_block: ir.Block, context: CallContext, param: spec.Shape
    ) -> tuple[tuple[ir.Type], tuple[ir.Value]]:
        """Pack a shape parameter to a struct."""
        allocas: list[ir.Value] = []
        arg_types: list[ir.Type] = []
        for dim in param.shape:
            if isinstance(dim, spec.Var):
                allocas.append(
                    self.pack_values_to_alloca(
                        current_block,
                        context.entry_block,
                        [context.matched_var_binding[dim]],
                    )[1]
                )
                arg_types.append(context.matched_var_binding[dim].type)
        return tuple(arg_types), tuple(allocas)

    def declare_extern_funcs(self, current_block: ir.Block, context: CallContext):
        """Append the error handling function to the current block."""
        with ir.InsertionPoint(context.module.body):
            context.builder.find_or_declare_extern_func(
                "cuda_dialect_get_error_name",
                [self.i32_type],
                self.ptr_type,
            )
            context.builder.find_or_declare_extern_func(
                "_cudaGetDevice",
                [self.ptr_type],
                self.i32_type,
            )
            context.builder.find_or_declare_extern_func(
                "_cudaSetDevice",
                [self.i32_type],
                self.i32_type,
            )
            context.builder.find_or_declare_extern_func(
                "cuda_dialect_init_library_once",
                [self.ptr_type, self.ptr_type, self.ptr_type, self.ptr_type],
                self.i32_type,
            )
            context.builder.find_or_declare_extern_func(
                "cuda_dialect_unload_library_once",
                [self.ptr_type],
                self.void_type,
            )
        return current_block

    def insert_lazy_init_cuda(self, current_block: ir.Block, context: CallContext):
        """Insert the lazy init cuda function."""
        # create global private static that is initialized to nullptr
        with ir.InsertionPoint(context.module.body):
            parsed_op = ir.Operation.parse(
                f"llvm.mlir.global private @{self.cuda_global_state_symbol}(0 : i64) : i64"
            )
            context.module.body.append(parsed_op)


        with ir.InsertionPoint(current_block):
            cuda_global_state_ptr = self.address_of(
                self.cuda_global_state_symbol, self.ptr_type
            )
            cuda_init_ptr = self.address_of("cuda_init", self.ptr_type)
            cuda_load_to_device_ptr = self.address_of("cuda_load_to_device", self.ptr_type)
            set_error_ptr = self.address_of(
                "TVMFFIErrorSetRaisedFromCStr", self.ptr_type
            )
            # Call the callback function with the loaded ptr value
            init_result = llvm.call(
                result=self.i32_type,  # function returns i32
                callee="cuda_dialect_init_library_once",
                callee_operands=[
                    cuda_global_state_ptr,
                    cuda_init_ptr,
                    cuda_load_to_device_ptr,
                    set_error_ptr,
                ],
                op_bundle_sizes=[],
                op_bundle_operands=[],
            )
            # Create blocks for conditional branching
            error_block = current_block.create_after()
            success_block = error_block.create_after()
            # Check if initialization failed (non-zero return code)
            llvm.cond_br(
                self.equal(init_result, self.i32(0)),
                true_dest_operands=[],
                false_dest_operands=[],
                true_dest=success_block,
                false_dest=error_block,
            )
        # Error block: return the error code
        # error is already set by cuda_dialect_init_library_once
        with ir.InsertionPoint(error_block):
            llvm.return_(arg=self.i32(-1))

        # Continue with success block
        return success_block

    def append_unload_to_global_dtors(
        self, current_block: ir.Block, context: CallContext
    ) -> ir.Block:
        """Append the cuda_dialect_unload_library_once function to the global destructor list."""
        unload_func_symbol = "cuda_dialect_unload_library_once"
        # define a private function to call the extern function, we need this wrapper function
        # since llvm.mlir.global_dtors require the dtor defined in the module
        unload_func_wrapper_symbol = f"__dtor_{unload_func_symbol}"
        with ir.InsertionPoint(context.module.body):
            params, entry_block = self.function(
                name=unload_func_wrapper_symbol,
                params_type=[],
                ret_type=self.void_type,
                internal=True,
            )
            with ir.InsertionPoint(entry_block):
                llvm.call(
                    result=None,
                    callee=unload_func_symbol,
                    callee_operands=[
                        self.address_of(self.cuda_global_state_symbol, self.ptr_type)
                    ],
                    op_bundle_sizes=[],
                    op_bundle_operands=[],
                )
                llvm.return_()

        # find or create the global destructors
        global_dtors_list: list[ir.Operation] = self.find_operations_in_module(
            context.module, "llvm.mlir.global_dtors"
        )
        if len(global_dtors_list) == 0:
            # create the global destructors
            with ir.InsertionPoint(context.module.body):
                global_dtors = llvm.mlir_global_dtors(
                    dtors=[],
                    priorities=[],
                )
        else:
            # use the existing global destructors
            global_dtors = global_dtors_list[0]

        # append the unload function to the global destructors
        global_dtors.attributes["dtors"] += [
            ir.FlatSymbolRefAttr.get(unload_func_wrapper_symbol)
        ]
        global_dtors.attributes["priorities"] += [
            ir.IntegerAttr.get(self.i32_type, 65535)
        ]  # the default priority

        return current_block

    def check_cuda_error(
        self, code: ir.Value, current_block: ir.Block, context: CallContext
    ):
        """Check if the CUDA error is raised and return the error string if so.

        Uses a shared error handling block to avoid code duplication. The error code
        is passed as a block argument to the shared error handler.
        """
        assert self.cuda_error_handle_block is not None
        with ir.InsertionPoint(current_block):
            # check if the call is successful
            success_block = current_block.create_after()
            # Check if call is successful (zero return code means success)
            self.cond_br(
                cond=self.equal(code, self.i32(0)),
                true_block=success_block,
                false_block=self.cuda_error_handle_block,
                branch_weights=self.BRANCH_WEIGHTS_LIKELY,
                false_dest_operands=[code],  # Pass error code to shared error block
            )
        return success_block

    def set_cuda_device_if_mismatch(
        self,
        current_block: ir.Block,
        context: CallContext,
        current_device: Optional[ir.Value],
        target_device: Optional[ir.Value],
    ) -> ir.Block:
        """Set the CUDA device index if it differs from the target device.
        """
        # If either device is None, no switching needed
        if current_device is None:
            assert target_device is None
            return current_block

        with ir.InsertionPoint(current_block):
            # Check if devices are different
            devices_differ = self.not_equal(current_device, target_device)

            # Create blocks for conditional device switching
            switch_device_block = current_block.create_after()
            continuation_block = switch_device_block.create_after()
            # For this specific case, avoid branch weights for now
            # mainly to avoid too drastic reordering of the code
            self.cond_br(
                cond=devices_differ,
                true_block=switch_device_block,
                false_block=continuation_block
            )

        # Switch device block: call cudaSetDevice
        with ir.InsertionPoint(switch_device_block):
            result = llvm.call(
                result=self.i32_type,
                callee="_cudaSetDevice",
                callee_operands=[target_device],
                op_bundle_sizes=[],
                op_bundle_operands=[],
            )

        # Check for errors and branch to continuation
        switch_device_block = self.check_cuda_error(result, switch_device_block, context)
        with ir.InsertionPoint(switch_device_block):
            self.br(continuation_block)

        return continuation_block

    def generate_llvm_call(
        self,
        current_block: ir.Block,
        call_operands: list[ir.Value],
        context: CallContext,
    ) -> ir.Block:
        """Generate the LLVM call operation and check if the call is successful."""
        old_cuda_device_index: Optional[ir.Value] = None

        # If we need to manage CUDA device context
        if self.cuda_device_index is not None:
            # Create an alloca in the entry block to store the current device index
            device_index_alloca = context.builder.create_alloca(
                context.entry_block, self.i32_type, array_size=1
            )

            # Get the current device
            with ir.InsertionPoint(current_block):
                get_device_result = llvm.call(
                    result=self.i32_type,
                    callee="_cudaGetDevice",
                    callee_operands=[device_index_alloca],
                    op_bundle_sizes=[],
                    op_bundle_operands=[],
                )
            current_block = self.check_cuda_error(get_device_result, current_block, context)

            # Load the current device index from the alloca
            with ir.InsertionPoint(current_block):
                old_cuda_device_index = llvm.load(self.i32_type, device_index_alloca)

            # Switch to target device if different
            current_block = self.set_cuda_device_if_mismatch(
                current_block, context, old_cuda_device_index, self.cuda_device_index
            )

        # Execute the main call
        with ir.InsertionPoint(current_block):
            result = llvm.call(
                result=self.i32_type,
                callee=self.target_func,
                callee_operands=call_operands,
                op_bundle_sizes=[],
                op_bundle_operands=[],
            )

        # Restore the original device BEFORE checking for errors
        # This ensures device is restored even if the main call failed
        current_block = self.set_cuda_device_if_mismatch(
            current_block, context, self.cuda_device_index, old_cuda_device_index
        )

        # Now check for errors from the main call
        current_block = self.check_cuda_error(result, current_block, context)

        return current_block


    def find_cuda_device_index_from_params(self, context: CallContext):
        """Find the CUDA device index from tensor parameters."""
        for param in context.params:
            if (
                isinstance(param, spec.Tensor)
                and param.dlpack_device_type != tvm_ffi.DLDeviceType.kDLCPU
            ):
                return context.matched_var_binding[param.device_id]
        return None

    def create_shared_cuda_error_block(
        self,
        current_block: ir.Block,
        context: CallContext
    ) -> ir.Block:
        """Create a shared error handling block for all CUDA errors.
        """
        # Create the shared error block after the current block (setup phase)
        # This block will be branched to from multiple error checking sites
        # It accepts the error code as a block argument
        error_block = current_block.create_after()
        error_code = error_block.add_argument(self.i32_type, ir.Location.unknown())

        # Populate the error block
        with ir.InsertionPoint(error_block):
            error_str = llvm.call(
                result=self.ptr_type,
                callee="cuda_dialect_get_error_name",
                callee_operands=[error_code],
                op_bundle_sizes=[],
                op_bundle_operands=[],
            )
            # Raise error and return -1
            context.builder.raise_error_and_return(
                error_kind="RuntimeError",
                error_message_parts=["CUDA Error: ", error_str],
            )

        return error_block

    def __call__(self, current_block: ir.Block, context: CallContext) -> ir.Block:
        current_block = self.declare_extern_funcs(current_block, context)
        current_block = self.insert_lazy_init_cuda(current_block, context)
        current_block = self.append_unload_to_global_dtors(current_block, context)
        # Create shared CUDA error handling block after the setup blocks
        # This reduces code duplication - all CUDA errors branch to this single block
        self.cuda_error_handle_block = self.create_shared_cuda_error_block(current_block, context)
        # setup device index, will be set around the call to the target function
        self.cuda_device_index = self.find_cuda_device_index_from_params(context)
        current_block = super().__call__(current_block, context)
        self.cuda_device_index = None
        self.cuda_error_handle_block = None
        # reset the device index and error block
        return current_block


class TVMFFIJitCompiledFunction(tvm_ffi.Function, CudaDialectJitCompiledFunction):
    """TVM FFI Function that contains metadata of the compiled function and interface to the FFI layer.

    This function should not be directly used after
    """

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # initialize the tvm_ffi.Function from the current execution engine
        self._init_ffi_function()

    # use direct call to the tvm_ffi.Function.__call__
    # to avoid most of python overhead
    __call__ = tvm_ffi.Function.__call__

    def _init_ffi_function(self):
        """Initialize the tvm_ffi.Function from the current execution engine.

        This function must be called at once during compilation time.
        The reason why it is not called during init is because the original
        flow may already created an execution engine and the function is not
        guaranteed to be initialized at that time.
        """
        if self.__chandle__() != 0:
            raise DSLRuntimeError("TVM FFI function is already initialized")
        # get the MLIR function pointer from the execution engine
        if self.engine is not None:
            tvm_ffi_function_ptr = self.engine.raw_lookup(
                "__tvm_ffi_" + self.function_name
            )
            tvm_ffi_function = tvm_ffi.Function.__from_mlir_packed_safe_call__(
                tvm_ffi_function_ptr
            )
            # move the handle from the tvm_ffi.Function to the current instance
            self.__move_handle_from__(tvm_ffi_function)

    def to(self, device=None):
        """TVM FFI function itself is already support all devices."""
        return self

    def run_compiled_program(self, exe_args: list[ir.Value]):
        """Run the compiled program. This override is needed for implicit compile and execution."""
        return self.__call__(*exe_args)

    def export_to_c(self, object_file_path: str, function_name: str = None):
        """Export the TVM FFI function to an object file.

        :param object_file_path: The path to the object file.
        :param function_name: The name of the function to export.
        """
        if function_name is not None and function_name != self.function_name:
            mod = self.ir_module
            rename_tvm_ffi_function(mod, self.function_name, function_name)
        else:
            mod = self.ir_module

        _execution_engine_extra.dump_object_file_pic(
            mod, object_file_path, "__tvm_ffi_" + function_name, 2
        )
