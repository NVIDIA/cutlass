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

from cutlass.cute.typing import NumericMeta, Integer
from cutlass.base_dsl.export import CHeaderGenerator, CHeaderArguments
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.base_dsl.jit_executor import ExecutionArgs
from cutlass.cutlass_dsl.cutlass import is_cute_algebra_type
from ..runtime import Tensor, Pointer

from typing import Any, Union, get_origin, get_args
from inspect import isclass, Parameter
import cuda.bindings.driver as cuda

# =============================================================================
# Cute DSL C Header Generator for c/cpp AOT support
# =============================================================================


class CuteCHeaderGenerator(CHeaderGenerator):
    """This class provides a Export C Header Generator for cute c/cpp AOT support."""

    includes = """
#pragma once

#include <cuda_runtime.h>
#include <cuda_fp16.h>
#include <stdio.h>
#include <stdint.h>

"""
    cuda_error_check = r"""_CUDA_ERROR_CHECK(err) { \
    if ((err) != cudaSuccess) { \
        printf("Got Cuda Error %s: %s\n", cudaGetErrorName(err), cudaGetErrorString(err)); \
    } \
}
"""

    def _get_cute_algebra_type(self, arg_type: Any, arg: Any) -> str:
        """Judge if the dynamic elements of the cute algebra type are same(Int32 or Int64).
        If so, generate the corresponding C type. Otherwise, refuse to generate the argument
        in C header and raise an error.
        """
        if not isinstance(arg, (list, tuple, Integer)):
            raise DSLRuntimeError(
                f"Unsupported argument for c function argument generation: {arg} with type {arg_type}"
            )
        if isinstance(arg, Integer):
            return self.numeric_to_c_type[arg.dtype]
        dyn_type = None
        for elem in arg:
            if not isinstance(elem, (Integer, int)):
                raise DSLRuntimeError(
                    f"Unsupported argument for c function argument generation: {arg} with type {arg_type}"
                )
            if isinstance(elem, int):
                continue
            if dyn_type is not None:
                if elem.dtype != dyn_type:
                    raise DSLRuntimeError(
                        f"Expects all dynamic elements of the cute algebra type to be of the same type, but got {elem.dtype} and {dyn_type}"
                    )
            else:
                dyn_type = elem.dtype
        if dyn_type is None:
            return "int32_t "
        return self.numeric_to_c_type[dyn_type]

    def _generate_binary_declaration(self, symbol_prefix: str) -> str:
        """
        Generate the binary of the compiled function.
        """
        return ""

    def _generate_kernel_module(
        self, symbol_prefix: str, kernel_info: dict[str, list[Any]], dsl_name: str
    ) -> str:
        """
        Generate the kernel module for the compiled function.
        """
        kernel_module_struct = f"""
typedef struct {{
    cudaLibrary_t module;
}} {symbol_prefix}_Kernel_Module_t;
"""
        kernel_module_load = f"""
#ifdef __cplusplus
extern "C" {{
#endif
void _mlir_{symbol_prefix}_cuda_init(void **);
void _mlir_{symbol_prefix}_cuda_load_to_device(void **);
static inline void {symbol_prefix}_Kernel_Module_Load({symbol_prefix}_Kernel_Module_t *module) {{
    cudaLibrary_t *libraryPtr = &(module->module);
    cudaError_t ret;
    struct {{
        cudaLibrary_t **libraryPtr;
        cudaError_t *ret;
    }} initArgs = {{&libraryPtr, &ret}};
    _mlir_{symbol_prefix}_cuda_init((void **)(&initArgs));
    {dsl_name}_CUDA_ERROR_CHECK(ret);
    int32_t device_id = 0;
    struct {{
        cudaLibrary_t **library;
        int32_t *device_id;
        cudaError_t *ret;
    }} loadArgs = {{&libraryPtr, &device_id, &ret}};
    int32_t device_count;
    {dsl_name}_CUDA_ERROR_CHECK(cudaGetDeviceCount(&device_count));
    for (int32_t i = 0; i < device_count; i++) {{
        device_id = i;
        _mlir_{symbol_prefix}_cuda_load_to_device((void **)(&loadArgs));
        {dsl_name}_CUDA_ERROR_CHECK(ret);
    }}
}}
"""
        kernel_module_unload = f"""
static inline void {symbol_prefix}_Kernel_Module_Unload({symbol_prefix}_Kernel_Module_t *module) {{
    {dsl_name}_CUDA_ERROR_CHECK(cudaLibraryUnload(module->module));
}}

#ifdef __cplusplus
}}
#endif
"""

        return kernel_module_struct + kernel_module_load + kernel_module_unload

    def _generate_arguments(
        self,
        symbol_prefix: str,
        execution_args: ExecutionArgs,
        args: tuple[Any, ...],
        kwargs: dict[str, Any],
    ) -> tuple[list[str], list[str], list[str]]:
        """
        Generate the arguments of the wrapper function.
        """
        arguments = []
        packed_args = []
        declarations = []
        # traverse the runtime args_spec and generate the arguments
        rectified_args = execution_args.get_rectified_args(args, kwargs)

        for param, arg in zip(
            execution_args.signature.parameters.values(), rectified_args
        ):
            arg_type = param.annotation
            arg_name = param.name

            # process optional argument
            if arg is None:
                continue

            # Unwrap Optional[X] (i.e. Union[X, None]) to X when arg is not None
            if get_origin(arg_type) is Union:
                inner_types = [t for t in get_args(arg_type) if t is not type(None)]
                if len(inner_types) == 1:
                    arg_type = inner_types[0]

            if isinstance(arg, Pointer):
                arguments.append(f"void *{arg_name}")
                packed_args.append("&" + arg_name)
            elif isinstance(arg, Tensor):
                dynamic_shapes = (
                    f"\n    int32_t dynamic_shapes[{sum(arg.dynamic_shapes_mask)}];"  # type: ignore[attr-defined]
                    if sum(arg.dynamic_shapes_mask) > 0  # type: ignore[attr-defined]
                    else ""
                )
                stride_type = "int32_t" if arg._use_32bit_stride else "int64_t"  # type: ignore[attr-defined]
                dynamic_strides = (
                    f"\n    {stride_type} dynamic_strides[{sum(arg.dynamic_strides_mask)}];"  # type: ignore[attr-defined]
                    if sum(arg.dynamic_strides_mask) > 0  # type: ignore[attr-defined]
                    else ""
                )
                declarations.append(
                    f"""
typedef struct {{
    void *data;{dynamic_shapes}{dynamic_strides}
}} {symbol_prefix}_Tensor_{arg_name}_t;
"""
                )
                arguments.append(f"{symbol_prefix}_Tensor_{arg_name}_t *{arg_name}")
                packed_args.append(arg_name)
            # Generate basic numeric types
            elif isinstance(arg_type, NumericMeta):
                arguments.append(self._generate_numeric_argument(arg_name, arg_type))  # type: ignore[arg-type]
                packed_args.append("&" + arg_name)
            elif is_cute_algebra_type(arg_type) or isinstance(arg, (tuple, list)):
                c_type = self._get_cute_algebra_type(arg_type, arg)
                arguments.append(f"{c_type}*{arg_name}")
                for i in range(self._count_dynamic_expression(arg)):
                    packed_args.append("&" + arg_name + "[" + str(i) + "]")
            elif isclass(arg_type) and issubclass(arg_type, cuda.CUstream):
                arguments.append("cudaStream_t " + arg_name)
                packed_args.append("&" + arg_name)
            else:
                raise DSLRuntimeError(
                    f"Unsupported argument for c function argument generation: {arg_name} = {arg} with type annotation {arg_type}"
                )

        return arguments, packed_args, declarations

    def _generate_wrapper_function(
        self,
        dsl_name: str,
        symbol_prefix: str,
        execution_args: ExecutionArgs,
        function_name: str,
        kernel_info: dict[str, list[Any]],
        c_header_arguments: CHeaderArguments,
    ) -> str:
        """
        Generate the wrapper function for the compiled function which is provided to users as the entry point.
        It uses the `symbol_prefix` as the function name for identification. The host/device symbols are hidden under the bytecode.
        """
        # 1. Get the name of the function wrapper
        wrapper_function_name = f"{dsl_name.lower()}_{symbol_prefix}_wrapper"
        capi_function_name = f"_mlir_{symbol_prefix}__mlir_ciface_{function_name}"
        # 2. Generate the signature of the wrapper function
        if c_header_arguments.error_msg is not None:
            raise DSLRuntimeError(
                f"Error generating c header arguments: {c_header_arguments.error_msg}"
            )
        arguments = [
            arg.replace(c_header_arguments.dummy_prefix_name, symbol_prefix)
            for arg in c_header_arguments.arguments
        ]
        packed_args = [
            arg.replace(c_header_arguments.dummy_prefix_name, symbol_prefix)
            for arg in c_header_arguments.packed_args
        ]
        declarations = [
            declaration.replace(c_header_arguments.dummy_prefix_name, symbol_prefix)
            for declaration in c_header_arguments.declarations
        ]

        # 3. Get the return type of the wrapper function.
        # Note that this requires the return type to be properly annotated in python.
        return_type = execution_args.signature.return_annotation
        if return_type is Parameter.empty:
            return_type = "void"
        else:
            return_type = self.numeric_to_c_type[return_type][:-1]
        declarations_str = "\n".join(declarations)

        # 4. Generate the wrapper function
        function = (
            declarations_str
            + f"""
#ifdef __cplusplus
extern "C"
#endif
void {capi_function_name}(void **args, int32_t num_args);

static inline {return_type} {wrapper_function_name}({symbol_prefix}_Kernel_Module_t *module, {", ".join(arguments)}) {{
    {return_type} ret;
    void *args[{len(packed_args) + 1}] = {{
        {", ".join(packed_args)},
        &ret
    }};
    {capi_function_name}(args, {len(packed_args) + 1});
    return ret;
}}
"""
        )
        return function
