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

from typing import Type, List, Any, Dict
from inspect import isclass
import cuda.bindings.driver as cuda

# =============================================================================
# C Header Generator for c/cpp AOT support
# =============================================================================
cubin_suffix = "cubin"


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

    def _count_dynamic_expression(self, arg):
        """
        Count the number of dynamic values in the argument.
        """
        if isinstance(arg, (list, tuple)):
            return sum(self._count_dynamic_expression(x) for x in arg)
        elif is_dynamic_expression(arg):
            return 1
        return 0

    def _generate_numeric_argument(self, arg_name: str, arg_type: Type[Numeric]):
        """
        Generate the argument of the wrapper function.
        """
        if arg_type in self.numeric_to_c_type:
            return self.numeric_to_c_type[arg_type] + arg_name
        raise DSLRuntimeError(
            f"Unsupported argument type for c function argument generation: {arg_type}"
        )

    def _generate_check_cuda(self, dsl_name: str):
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

    def _generate_kernel_metadata(
        self, symbol_prefix: str, kernel_info: Dict[str, List], dsl_name: str
    ):
        """
        Generate the kernel metadata for the compiled function.
        """
        function_declarations = []
        function_loads = []
        function_set_attributes = []
        function_non_portable_cluster_size_allowed = []
        for sym, attrs in kernel_info.items():
            function_declaration = f"CUfunction {sym};"
            function_load = f'{dsl_name}_CUDA_ERROR_CHECK(cuModuleGetFunction(&metadata->{sym}, metadata->module, "{sym}"));'
            function_declarations.append(function_declaration)
            function_loads.append(function_load)
            for attr in attrs:
                function_set_attributes.append(
                    f"{dsl_name}_CUDA_ERROR_CHECK(cuFuncSetAttribute(metadata->{sym}, {attr.name}, {attr.value}));"
                )
            function_non_portable_cluster_size_allowed.append(
                f"{dsl_name}_CUDA_ERROR_CHECK(cuFuncSetAttribute(metadata->{sym}, CU_FUNC_ATTRIBUTE_NON_PORTABLE_CLUSTER_SIZE_ALLOWED, 1));"
            )
        function_declarations_str = "\n    ".join(function_declarations)
        kernel_metadata_struct = f"""
typedef struct {{
    CUmodule module;
    {function_declarations_str}
}} {symbol_prefix}_Kernel_Metadata_t;
"""
        function_loads_str = "\n    ".join(function_loads)
        function_set_attributes_str = "\n    ".join(function_set_attributes)
        function_non_portable_cluster_size_allowed_str = "\n        ".join(
            function_non_portable_cluster_size_allowed
        )
        kernel_metadata_load = f"""
static inline void {symbol_prefix}_Kernel_Metadata_Load({symbol_prefix}_Kernel_Metadata_t *metadata) {{
    {dsl_name}_CUDA_ERROR_CHECK(cuModuleLoadData(&metadata->module, {symbol_prefix}_{cubin_suffix}));
    {function_loads_str}
    {function_set_attributes_str}
    int driver_version;
    {dsl_name}_CUDA_ERROR_CHECK(cuDriverGetVersion(&driver_version));
    if (driver_version >= 11080) {{
        {function_non_portable_cluster_size_allowed_str}
    }}
}}
"""
        kernel_metadata_unload = f"""
static inline void {symbol_prefix}_Kernel_Metadata_Unload({symbol_prefix}_Kernel_Metadata_t *metadata) {{
    {dsl_name}_CUDA_ERROR_CHECK(cuModuleUnload(metadata->module));
}}
"""

        return kernel_metadata_struct + kernel_metadata_load + kernel_metadata_unload

    def _generate_arguments(
        self,
        symbol_prefix: str,
        args_spec: ExecutionArgs,
        args: List[Any],
        kwargs: Dict[str, Any],
    ):
        """
        Generate the arguments of the wrapper function.
        """
        arguments = []
        packed_args = []
        declarations = []
        # traverse the runtime args_spec and generate the arguments
        rectified_args = args_spec.get_rectified_args(args, kwargs)
        input_arg_names = args_spec.args_spec.args + args_spec.args_spec.kwonlyargs
        for arg_name, arg in zip(input_arg_names, rectified_args):
            arg_type = args_spec.args_spec.annotations.get(arg_name, None)

            # process optional argument
            if arg is None:
                continue

            # Generate basic numeric types
            if isinstance(arg_type, NumericMeta):
                arguments.append(self._generate_numeric_argument(arg_name, arg_type))
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
        symbol_prefix: str,
        args_spec: ExecutionArgs,
        function_name: str,
        kernel_info: Dict[str, List],
        dynamic_args: list,
        dynamic_kwargs: dict,
    ):
        """
        Generate the wrapper function for the compiled function which is provided to users as the entry point.
        It uses the `symbol_prefix` as the function name for identification. The host/device symbols are hidden under the bytecode.
        """
        # 1. Get the name of the function wrapper
        wrapper_function_name = f"{symbol_prefix}_wrapper"
        capi_function_name = f"_mlir_{symbol_prefix}__mlir_ciface_{function_name}"
        # 2. Generate the signature of the wrapper function
        arguments, packed_args, declarations = self._generate_arguments(
            symbol_prefix, args_spec, dynamic_args, dynamic_kwargs
        )
        declarations = "\n".join(declarations)

        # 3. Generate the wrapper function
        kernel_symbols = tuple(kernel_info.keys())
        kernel_symbols_str = ", ".join([f"&metadata->{sym}" for sym in kernel_symbols])
        function = (
            declarations
            + f"""
#ifdef __cplusplus
extern "C"
#endif
void {capi_function_name}(void **args, int32_t num_args);

static inline void {wrapper_function_name}({symbol_prefix}_Kernel_Metadata_t *metadata, {", ".join(arguments)}) {{
    void *args[{len(packed_args) + len(kernel_symbols)}] = {{
        {", ".join(packed_args)}, {kernel_symbols_str}
    }};
    {capi_function_name}(args, {len(packed_args) + len(kernel_symbols)});
}}
"""
        )
        return function

    def _generate_binary_declaration(self, symbol_prefix: str):
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
        kernel_info: Dict[str, List],
        dynamic_args: list,
        dynamic_kwargs: dict,
        dsl_name: str,
    ) -> str:
        if len(kernel_info) > 0:
            check_cuda = self._generate_check_cuda(dsl_name)
            kernel_metadata = self._generate_kernel_metadata(
                symbol_prefix, kernel_info, dsl_name
            )
            binary = self._generate_binary_declaration(symbol_prefix)
        else:
            check_cuda = ""
            kernel_metadata = ""
            binary = ""
        function = self._generate_wrapper_function(
            symbol_prefix,
            args_spec,
            function_name,
            kernel_info,
            dynamic_args,
            dynamic_kwargs,
        )
        header = self.includes + check_cuda + binary + kernel_metadata + function
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
# } gemm_Kernel_Metadata_t;

# static inline void gemm_Kernel_Metadata_Load(gemm_Kernel_Metadata_t *metadata) {
#     CUTE_DSL_CUDA_ERROR_CHECK(cuModuleLoadData(&metadata->module, gemm_cubin));
#     CUTE_DSL_CUDA_ERROR_CHECK(cuModuleGetFunction(&metadata->kernel_cutlass_dummy_gemm_tensorptrf32generico1_tensorptrf32generico1_tensorptrf32generico1_0, metadata->module, "kernel_cutlass_dummy_gemm_tensorptrf32generico1_tensorptrf32generico1_tensorptrf32generico1_0"));

#     int driver_version;
#     CUTE_DSL_CUDA_ERROR_CHECK(cuDriverGetVersion(&driver_version));
#     if (driver_version >= 11080) {
#         CUTE_DSL_CUDA_ERROR_CHECK(cuFuncSetAttribute(metadata->kernel_cutlass_dummy_gemm_tensorptrf32generico1_tensorptrf32generico1_tensorptrf32generico1_0, CU_FUNC_ATTRIBUTE_NON_PORTABLE_CLUSTER_SIZE_ALLOWED, 1));
#     }
# }

# static inline void gemm_Kernel_Metadata_Unload(gemm_Kernel_Metadata_t *metadata) {
#     CUTE_DSL_CUDA_ERROR_CHECK(cuModuleUnload(metadata->module));
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

# static inline void gemm_wrapper(gemm_Kernel_Metadata_t *metadata, gemm_Tensor_a_t *a, gemm_Tensor_b_t *b, gemm_Tensor_c_t *c) {
#     void *args[4] = {
#         a, b, c, &metadata->kernel_cutlass_dummy_gemm_tensorptrf32generico1_tensorptrf32generico1_tensorptrf32generico1_0
#     };
#     _mlir_gemm__mlir_ciface_cutlass_host_func_Tensorgenericoi641_Tensorgenericoi641_Tensorgenericoi641(args, 4);
# }
