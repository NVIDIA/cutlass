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
    BFloat16,
    Float16,
    Float32,
    Float64,
    TFloat32,
)
from ..dsl import is_dynamic_expression
from ..common import DSLRuntimeError, DSLUserCodeError
from ..diagnostics import DiagId
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

    # AOT cross-compile invariant: every C type emitted into the generated
    # .h must be either fixed-width (intN_t / uintN_t / float / double) or an
    # opaque target-defined typedef (e.g. cudaLibrary_t). Never use bare
    # `long`, `int`, `size_t`, or pointer-arithmetic literals — those bind
    # the struct ABI to the *build* machine, which silently miscompiles when
    # the host cross-target has a different word size.
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
        BFloat16: "__nv_bfloat16 ",
    }

    # Device functions use __half (not __half_raw used by host export headers).
    device_type_overrides = {
        Float16: "__half ",
    }

    @classmethod
    def get_c_type(cls, ann: Any, device: bool = False) -> str:
        """Map a DSL type annotation to its C type string (without trailing space).

        Args:
            ann: DSL type annotation (e.g., Float32, Int64, or a @native_struct class).
            device: If True, use device-specific mappings (e.g., __half vs __half_raw).
        """
        if device:
            c = cls.device_type_overrides.get(ann)
            if c is not None:
                return c.strip()
        c = cls.numeric_to_c_type.get(ann)
        if c is not None:
            return c.strip()
        if hasattr(ann, "_field_names"):
            return ann.__name__
        raise DSLUserCodeError(DiagId.TYPE_UNSUPPORTED_C_EXPORT, type_name=ann)

    @classmethod
    def generate_struct_typedef(cls, struct_cls: Any, device: bool = False) -> str:
        """Generate a C struct typedef from a @native_struct class.

        Nested struct fields are referenced by their typedef name (not
        inlined as anonymous structs), so all transitive struct dependencies
        must be emitted before this typedef.  Use
        :meth:`_collect_struct_typedefs` to gather them in dependency order.
        """
        fields = []
        for fname in struct_cls._field_names:
            ann = struct_cls._field_annotations[fname]
            fields.append(f"    {cls.get_c_type(ann, device=device)} {fname};")
        packed = getattr(struct_cls, "_struct_packed", False)
        attr = " __attribute__((packed))" if packed else ""
        name = struct_cls.__name__
        return f"typedef struct{attr} {{\n" + "\n".join(fields) + f"\n}} {name};"

    @classmethod
    def _collect_struct_typedefs(
        cls, struct_cls: Any, *, device: bool = False, seen: set | None = None
    ) -> list[str]:
        """Recursively collect C struct typedefs in dependency order.

        Walks the struct's field annotations; any field that is itself a
        @native_struct is visited first so its typedef appears before the
        struct that references it.  Deduplicates by class name.
        """
        if seen is None:
            seen = set()
        name = struct_cls.__name__
        if name in seen:
            return []
        seen.add(name)

        result: list[str] = []
        for fname in struct_cls._field_names:
            ann = struct_cls._field_annotations[fname]
            if hasattr(ann, "_field_names"):
                result.extend(
                    cls._collect_struct_typedefs(ann, device=device, seen=seen)
                )
        result.append(cls.generate_struct_typedef(struct_cls, device=device))
        return result

    @classmethod
    def generate_device_header(
        cls,
        function_name: str,
        signature: inspect.Signature,
        ret_annotation: Any = None,
        pointer_types: tuple[type, ...] = (),
    ) -> str:
        """Generate a .cuh header declaring a __device__ function.

        Works entirely from DSL type annotations — no MLIR types needed.
        Handles scalar types, @native_struct types (including nested structs),
        and opaque pointer annotations.

        Args:
            pointer_types: Annotation types that should be rendered as
                ``void*`` in the generated header (e.g. upstream pointer
                wrappers).
        """
        seen_structs: set[str] = set()
        typedefs: list[str] = []

        def _add_struct(struct_cls: Any) -> None:
            """Collect typedefs for *struct_cls* (and its transitive deps)."""
            if struct_cls.__name__ not in seen_structs:
                for td in cls._collect_struct_typedefs(
                    struct_cls, device=True, seen=seen_structs
                ):
                    typedefs.append(td)

        # Return type
        if ret_annotation is None:
            ret_c = "void"
        elif hasattr(ret_annotation, "_field_names"):
            _add_struct(ret_annotation)
            ret_c = ret_annotation.__name__
        else:
            ret_c = cls.get_c_type(ret_annotation, device=True)

        # Parameters
        params = []
        for name, param in signature.parameters.items():
            ann = param.annotation
            if ann is inspect.Parameter.empty:
                ann = None
            if pointer_types and ann in pointer_types:
                params.append(f"void* {name}")
            elif ann is not None and hasattr(ann, "_field_names"):
                _add_struct(ann)
                params.append(f"{ann.__name__} {name}")
            elif ann is not None:
                params.append(f"{cls.get_c_type(ann, device=True)} {name}")
            else:
                params.append(f"void* {name}")
        param_str = ", ".join(params) if params else "void"

        typedef_block = "\n\n".join(typedefs)
        if typedef_block:
            typedef_block += "\n\n"

        return f"""\
#pragma once

#include <cuda_fp16.h>
#include <cuda_bf16.h>
#include <stdint.h>

{typedef_block}extern "C" __device__ {ret_c} {function_name}({param_str});
"""

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
        raise DSLUserCodeError(DiagId.TYPE_UNSUPPORTED_C_ARG, arg_type=arg_type)

    def _generate_tensor_element_typedef(
        self,
        symbol_prefix: str,
        arg_name: str,
        n_dyn_shape: int,
        n_dyn_stride: int,
        stride_type: str,
        shape_type: str | None = None,
    ) -> str:
        """
        Format a per-element tensor descriptor typedef (`{prefix}_Tensor_{name}_t`).
        Reused by both scalar-Tensor and list/tuple-of-Tensor dispatch branches in
        subclasses so the on-wire descriptor layout stays identical. When
        ``shape_type`` is ``None`` it defaults to ``stride_type`` so callers that
        only pass ``stride_type`` get a struct whose shape and stride fields share
        the same dynamic-int width (matching the runtime memref descriptor built
        by ``cute::abi::MemRef::build``).
        """
        shape_type = shape_type if shape_type is not None else stride_type
        dyn_shape_decl = (
            f"\n    {shape_type} dynamic_shapes[{n_dyn_shape}];"
            if n_dyn_shape > 0
            else ""
        )
        dyn_stride_decl = (
            f"\n    {stride_type} dynamic_strides[{n_dyn_stride}];"
            if n_dyn_stride > 0
            else ""
        )
        return f"""
typedef struct {{
    void *data;{dyn_shape_decl}{dyn_stride_decl}
}} {symbol_prefix}_Tensor_{arg_name}_t;
"""

    def _generate_check_cuda(self, dsl_name: str) -> str:
        check_cuda = (
            f"""
// Macro to check for cuda errors.
#ifndef {dsl_name}_CUDA_ERROR_CHECK
#define {dsl_name}"""
            + self.cuda_error_check
            + """
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
                raise DSLUserCodeError(
                    DiagId.ARG_UNSUPPORTED_C_EXPORT,
                    arg_name=arg_name,
                    arg_type=arg_type,
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
