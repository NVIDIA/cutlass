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

from ..typing import (
    Numeric,
    NumericMeta,
    Int8,
    Int16,
    Int32,
    Int64,
    Uint8,
    Uint16,
    Uint32,
    Uint64,
    Boolean,
    Float16,
    Float32,
    Float64,
    TFloat32,
)
from ..dsl import is_dynamic_expression
from ..common import DSLRuntimeError
from ..jit_executor import ExecutionArgs
from ..._mlir import ir

from dataclasses import dataclass
from typing import Any, Union, get_origin, get_args
import inspect
from inspect import isclass
import cuda.bindings.driver as cuda

# =============================================================================
# C Header Generator for c/cpp AOT support
# =============================================================================
cubin_suffix = "cubin"


@dataclass
class CHeaderArguments:
    """This class is used to store the arguments generation of the wrapper function.
    The arguments are generated when the JitCompiledFunction is created and used to avoid
    the long-term reference of the arguments by the JitCompiledFunction.
    """

    dummy_prefix_name: str
    arguments: list[str]
    packed_args: list[str]
    declarations: list[str]
    error_msg: str | None = None

    def __bool__(self) -> bool:
        return self.error_msg is None

    def __str__(self) -> str:
        return self.error_msg or ""


class CHeaderGenerator:
    """This class provides a Export C Header Generator for c/cpp AOT support."""

    includes = """
#pragma once

#include <cuda.h>
#include <cuda_fp16.h>
#include <stdio.h>

"""
    cuda_error_check = r"""_CUDA_ERROR_CHECK(err) { \
    if ((err) != CUDA_SUCCESS) { \
        const char *pErrStr = NULL; \
        if (cuGetErrorString(err, &pErrStr) != CUDA_SUCCESS) { \
            printf("Error: cuGetErrorString failed\n"); \
            exit(err); \
        } \
        const char *pErrName = NULL; \
        if (cuGetErrorName(err, &pErrName) != CUDA_SUCCESS) { \
            printf("Error: cuGetErrorName failed\n"); \
            exit(err); \
        } \
        printf("Got Cuda Error: %s %s\n", pErrName, pErrStr); \
        exit(err); \
    } \
}
"""

    numeric_to_c_type = {
        Int8: "int8_t ",
        Int16: "int16_t ",
        Int32: "int32_t ",
        Int64: "int64_t ",
        Uint8: "uint8_t ",
        Uint16: "uint16_t ",
        Uint32: "uint32_t ",
        Uint64: "uint64_t ",
        Boolean: "uint8_t ",
        Float32: "float ",
        TFloat32: "float ",
        Float64: "double ",
        Float16: "__half_raw ",
    }

    def _count_dynamic_expression(self, arg: Any) -> int:
        """
        Count the number of dynamic values in the argument.
        """
        if isinstance(arg, (list, tuple)):
            return sum(self._count_dynamic_expression(x) for x in arg)
        elif is_dynamic_expression(arg):
            return 1
        return 0

    def _generate_numeric_argument(self, arg_name: str, arg_type: type[Numeric]) -> str:
        """
        Generate the argument of the wrapper function.
        """
        if arg_type in self.numeric_to_c_type:
            return self.numeric_to_c_type[arg_type] + arg_name
        raise DSLRuntimeError(
            f"Unsupported argument type for c function argument generation: {arg_type}"
        )

    def _generate_check_cuda(self, dsl_name: str) -> str:
        check_cuda = (
            f"""
// Macro to check for cuda errors.
#ifndef {dsl_name}_CUDA_ERROR_CHECK
#define {dsl_name}"""
            + self.cuda_error_check
            + f"""
#endif
"""
        )

        return check_cuda

    def _generate_kernel_module(
        self,
        symbol_prefix: str,
        kernel_info: dict[str, list[Any]],
        dsl_name: str,
    ) -> str:
        """
        Generate the kernel module for the compiled function.
        """
        function_declarations = []
        function_loads = []
        function_set_attributes = []
        function_non_portable_cluster_size_allowed = []
        for sym, attrs in kernel_info.items():
            function_declaration = f"CUfunction {sym};"
            function_load = f'{dsl_name}_CUDA_ERROR_CHECK(cuModuleGetFunction(&module->{sym}, module->module, "{sym}"));'
            function_declarations.append(function_declaration)
            function_loads.append(function_load)
            for attr in attrs:
                function_set_attributes.append(
                    f"{dsl_name}_CUDA_ERROR_CHECK(cuFuncSetAttribute(module->{sym}, {attr.name}, {attr.value}));"
                )
            function_non_portable_cluster_size_allowed.append(
                f"{dsl_name}_CUDA_ERROR_CHECK(cuFuncSetAttribute(module->{sym}, CU_FUNC_ATTRIBUTE_NON_PORTABLE_CLUSTER_SIZE_ALLOWED, 1));"
            )
        function_declarations_str = "\n    ".join(function_declarations)
        kernel_module_struct = f"""
typedef struct {{
    CUmodule module;
    {function_declarations_str}
}} {symbol_prefix}_Kernel_Module_t;
"""
        function_loads_str = "\n    ".join(function_loads)
        function_set_attributes_str = "\n    ".join(function_set_attributes)
        function_non_portable_cluster_size_allowed_str = "\n        ".join(
            function_non_portable_cluster_size_allowed
        )
        kernel_module_load = f"""
static inline void {symbol_prefix}_Kernel_Module_Load({symbol_prefix}_Kernel_Module_t *module) {{
    {dsl_name}_CUDA_ERROR_CHECK(cuModuleLoadData(&module->module, {symbol_prefix}_{cubin_suffix}));
    {function_loads_str}
    {function_set_attributes_str}
    int driver_version;
    {dsl_name}_CUDA_ERROR_CHECK(cuDriverGetVersion(&driver_version));
    if (driver_version >= 11080) {{
        {function_non_portable_cluster_size_allowed_str}
    }}
}}
"""
        kernel_module_unload = f"""
static inline void {symbol_prefix}_Kernel_Module_Unload({symbol_prefix}_Kernel_Module_t *module) {{
    {dsl_name}_CUDA_ERROR_CHECK(cuModuleUnload(module->module));
}}
"""

        return kernel_module_struct + kernel_module_load + kernel_module_unload

    def _generate_arguments(
        self,
        symbol_prefix: str,
        args_spec: ExecutionArgs,
        args: tuple[Any],
        kwargs: dict[str, Any],
    ) -> tuple[list[str], list[str], list[str]]:
        """
        Generate the arguments of the wrapper function.
        """
        arguments: list[str] = []
        packed_args: list[str] = []
        declarations: list[str] = []
        # traverse the runtime args_spec and generate the arguments
        rectified_args = args_spec.get_rectified_args(args, kwargs)
        for param, arg in zip(args_spec.signature.parameters.values(), rectified_args):
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

            # Generate basic numeric types
            if isinstance(arg_type, NumericMeta):
                arguments.append(self._generate_numeric_argument(arg_name, arg_type))  # type: ignore[arg-type]
                packed_args.append("&" + arg_name)
            elif isclass(arg_type) and issubclass(arg_type, cuda.CUstream):
                arguments.append("CUstream " + arg_name)
                packed_args.append("&" + arg_name)
            else:
                raise DSLRuntimeError(
                    f"Unsupported argument for c function argument generation: {arg} with type {arg_type}"
                )

        return arguments, packed_args, declarations

    def _generate_wrapper_function(
        self,
        dsl_name: str,
        symbol_prefix: str,
        args_spec: ExecutionArgs,
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
        declaration_lines = [
            declaration.replace(c_header_arguments.dummy_prefix_name, symbol_prefix)
            for declaration in c_header_arguments.declarations
        ]
        declarations_joined = "\n".join(declaration_lines)

        # 3. Generate the wrapper function
        kernel_symbols = tuple(kernel_info.keys())
        kernel_symbols_str = ", ".join([f"&module->{sym}" for sym in kernel_symbols])
        function = (
            declarations_joined
            + f"""
#ifdef __cplusplus
extern "C"
#endif
void {capi_function_name}(void **args, int32_t num_args);

static inline void {wrapper_function_name}({symbol_prefix}_Kernel_Module_t *module, {", ".join(arguments)}) {{
    void *args[{len(packed_args) + len(kernel_symbols)}] = {{
        {", ".join(packed_args)}, {kernel_symbols_str}
    }};
    {capi_function_name}(args, {len(packed_args) + len(kernel_symbols)});
}}
"""
        )
        return function

    def _generate_binary_declaration(self, symbol_prefix: str) -> str:
        """
        Generate the binary of the compiled function.
        """
        varname = symbol_prefix + "_" + cubin_suffix
        binary = f"""
extern const unsigned char {varname}[];
"""
        return binary

    def __call__(
        self,
        symbol_prefix: str,
        export_module: ir.Module,
        args_spec: ExecutionArgs,
        function_name: str,
        kernel_info: dict[str, list[Any]],
        c_header_arguments: CHeaderArguments,
        dsl_name: str,
    ) -> str:
        if len(kernel_info) > 0:
            check_cuda = self._generate_check_cuda(dsl_name)
            kernel_module = self._generate_kernel_module(
                symbol_prefix, kernel_info, dsl_name
            )
            binary = self._generate_binary_declaration(symbol_prefix)
        else:
            check_cuda = ""
            kernel_module = ""
            binary = ""
        function = self._generate_wrapper_function(
            dsl_name,
            symbol_prefix,
            args_spec,
            function_name,
            kernel_info,
            c_header_arguments,
        )
        header = self.includes + check_cuda + binary + kernel_module + function
        return header


# =============================================================================
# Below is the example output of a complete header file.
# =============================================================================
# #pragma once

# #include <cuda.h>
# #include <cuda_fp16.h>
# #include <stdio.h>


# // Macro to check for cuda errors.
# #ifndef CUTE_DSL_CUDA_ERROR_CHECK
# #define CUTE_DSL_CUDA_ERROR_CHECK(err) { \
#     if ((err) != CUDA_SUCCESS) { \
#         const char *pErrStr = NULL; \
#         if (cuGetErrorString(err, &pErrStr) != CUDA_SUCCESS) { \
#             printf("Error: cuGetErrorString failed\n"); \
#             exit(err); \
#         } \
#         const char *pErrName = NULL; \
#         if (cuGetErrorName(err, &pErrName) != CUDA_SUCCESS) { \
#             printf("Error: cuGetErrorName failed\n"); \
#             exit(err); \
#         } \
#         printf("Got Cuda Error: %s %s\n", pErrName, pErrStr); \
#         exit(err); \
#     } \
# }
# #endif

# extern const unsigned char gemm_cubin[];

# typedef struct {
#     CUmodule module;
#     CUfunction kernel_cutlass_dummy_gemm_tensorptrf32generico1_tensorptrf32generico1_tensorptrf32generico1_0;
# } gemm_Kernel_Module_t;

# static inline void gemm_Kernel_Module_Load(gemm_Kernel_Module_t *module) {
#     CUTE_DSL_CUDA_ERROR_CHECK(cuModuleLoadData(&module->module, gemm_cubin));
#     CUTE_DSL_CUDA_ERROR_CHECK(cuModuleGetFunction(&module->kernel_cutlass_dummy_gemm_tensorptrf32generico1_tensorptrf32generico1_tensorptrf32generico1_0, module->module, "kernel_cutlass_dummy_gemm_tensorptrf32generico1_tensorptrf32generico1_tensorptrf32generico1_0"));

#     int driver_version;
#     CUTE_DSL_CUDA_ERROR_CHECK(cuDriverGetVersion(&driver_version));
#     if (driver_version >= 11080) {
#         CUTE_DSL_CUDA_ERROR_CHECK(cuFuncSetAttribute(module->kernel_cutlass_dummy_gemm_tensorptrf32generico1_tensorptrf32generico1_tensorptrf32generico1_0, CU_FUNC_ATTRIBUTE_NON_PORTABLE_CLUSTER_SIZE_ALLOWED, 1));
#     }
# }

# static inline void gemm_Kernel_Module_Unload(gemm_Kernel_Module_t *module) {
#     CUTE_DSL_CUDA_ERROR_CHECK(cuModuleUnload(module->module));
# }

# typedef struct {
#     void *data;
#     int32_t dynamic_shapes[2];
#     int64_t dynamic_strides[1];
# } gemm_Tensor_a_t;


# typedef struct {
#     void *data;
#     int32_t dynamic_shapes[2];
#     int64_t dynamic_strides[1];
# } gemm_Tensor_b_t;


# typedef struct {
#     void *data;
#     int32_t dynamic_shapes[2];
#     int64_t dynamic_strides[1];
# } gemm_Tensor_c_t;

# #ifdef __cplusplus
# extern "C"
# #endif
# void _mlir_gemm__mlir_ciface_cutlass_host_func_Tensorgenericoi641_Tensorgenericoi641_Tensorgenericoi641(void **args, int32_t num_args);

# static inline void cute_dsl_gemm_wrapper(gemm_Kernel_Module_t *module, gemm_Tensor_a_t *a, gemm_Tensor_b_t *b, gemm_Tensor_c_t *c) {
#     void *args[4] = {
#         a, b, c, &module->kernel_cutlass_dummy_gemm_tensorptrf32generico1_tensorptrf32generico1_tensorptrf32generico1_0
#     };
#     _mlir_gemm__mlir_ciface_cutlass_host_func_Tensorgenericoi641_Tensorgenericoi641_Tensorgenericoi641(args, 4);
# }
