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

from cutlass.cute.typing import NumericMeta, Integer
from cutlass.base_dsl.export import CHeaderGenerator
from cutlass.base_dsl.dsl import is_dynamic_expression
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.base_dsl.jit_executor import ExecutionArgs
from cutlass.cutlass_dsl.cutlass import is_cute_algebra_type
from ..runtime import Tensor, Pointer

from typing import List, Any, Dict
from inspect import isclass
import cuda.bindings.driver as cuda

# =============================================================================
# Cute DSL C Header Generator for c/cpp AOT support
# =============================================================================


class CuteCHeaderGenerator(CHeaderGenerator):
    """This class provides a Export C Header Generator for cute c/cpp AOT support."""

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

    def _generate_binary_declaration(self, symbol_prefix: str):
        """
        Generate the binary of the compiled function.
        """
        return ""

    def _generate_kernel_metadata(
        self, symbol_prefix: str, kernel_info: Dict[str, List], dsl_name: str
    ):
        """
        Generate the kernel metadata for the compiled function.
        """
        kernel_metadata_struct = f"""
typedef struct {{
    CUlibrary module;
}} {symbol_prefix}_Kernel_Metadata_t;
"""
        kernel_metadata_load = f"""
#ifdef __cplusplus
extern "C" {{
#endif
void _mlir_{symbol_prefix}_cuda_init(void **);
void _mlir_{symbol_prefix}_cuda_load(void **);
static inline void {symbol_prefix}_Kernel_Metadata_Load({symbol_prefix}_Kernel_Metadata_t *metadata) {{
    CUlibrary *libraryPtr = &(metadata->module);
    int32_t ret;
    struct {{
        CUlibrary **libraryPtr;
        int32_t *ret;
    }} initArgs = {{&libraryPtr, &ret}};
    _mlir_{symbol_prefix}_cuda_init((void **)(&initArgs));
    {dsl_name}_CUDA_ERROR_CHECK((CUresult)(ret));
    struct {{
        CUlibrary *library;
        int32_t *ret;
    }} loadArgs = {{libraryPtr, &ret}};
    _mlir_{symbol_prefix}_cuda_load((void **)(&loadArgs));
    {dsl_name}_CUDA_ERROR_CHECK((CUresult)(ret));
    CUdevice device;
    {dsl_name}_CUDA_ERROR_CHECK(cuCtxGetDevice(&device));
    int max_shared_memory_per_block_optin;
    {dsl_name}_CUDA_ERROR_CHECK(cuDeviceGetAttribute(&max_shared_memory_per_block_optin, CU_DEVICE_ATTRIBUTE_MAX_SHARED_MEMORY_PER_BLOCK_OPTIN, device));
    unsigned int num_kernels;
    {dsl_name}_CUDA_ERROR_CHECK(cuLibraryGetKernelCount(&num_kernels, metadata->module));
    CUkernel *kernels = (CUkernel *)malloc(num_kernels * sizeof(CUkernel));
    {dsl_name}_CUDA_ERROR_CHECK(cuLibraryEnumerateKernels(kernels, num_kernels, metadata->module));
    for (unsigned int i = 0; i < num_kernels; i++) {{
        {dsl_name}_CUDA_ERROR_CHECK(cuKernelSetAttribute(CU_FUNC_ATTRIBUTE_MAX_DYNAMIC_SHARED_SIZE_BYTES, max_shared_memory_per_block_optin, kernels[i], device));
    }}
    free(kernels);
}}
"""
        kernel_metadata_unload = f"""
static inline void {symbol_prefix}_Kernel_Metadata_Unload({symbol_prefix}_Kernel_Metadata_t *metadata) {{
    {dsl_name}_CUDA_ERROR_CHECK(cuLibraryUnload(metadata->module));
}}

#ifdef __cplusplus
}}
#endif
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

            if isinstance(arg, Pointer):
                arguments.append(f"void *{arg_name}")
                packed_args.append("&" + arg_name)
            elif isinstance(arg, Tensor):
                dynamic_shapes = (
                    f"\n    int32_t dynamic_shapes[{sum(arg.dynamic_shapes_mask)}];"
                    if sum(arg.dynamic_shapes_mask) > 0
                    else ""
                )
                stride_type = "int32_t" if arg._use_32bit_stride else "int64_t"
                dynamic_strides = (
                    f"\n    {stride_type} dynamic_strides[{sum(arg.dynamic_strides_mask)}];"
                    if sum(arg.dynamic_strides_mask) > 0
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
                arguments.append(self._generate_numeric_argument(arg_name, arg_type))
                packed_args.append("&" + arg_name)
            elif is_cute_algebra_type(arg_type):
                c_type = self._get_cute_algebra_type(arg_type, arg)
                arguments.append(f"{c_type}*{arg_name}")
                for i in range(self._count_dynamic_expression(arg)):
                    packed_args.append("&" + arg_name + "[" + str(i) + "]")
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
        # 3. Get the return type of the wrapper function.
        # Note that this requires the return type to be properly annotated in python.
        return_type = args_spec.args_spec.annotations.get("return", None)
        if return_type is None:
            return_type = "void"
        else:
            return_type = self.numeric_to_c_type[return_type][:-1]
        declarations = "\n".join(declarations)

        # 4. Generate the wrapper function
        function = (
            declarations
            + f"""
#ifdef __cplusplus
extern "C"
#endif
void {capi_function_name}(void **args, int32_t num_args);

static inline {return_type} {wrapper_function_name}({symbol_prefix}_Kernel_Metadata_t *metadata, {", ".join(arguments)}) {{
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
