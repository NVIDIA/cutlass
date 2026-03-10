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

import io
import os

import ctypes
from typing import Callable
from inspect import FullArgSpec

from ..common import DSLRuntimeError
from ...base_dsl.dsl import BaseDSL
from ...base_dsl.typing import Int32, Int64, Float32, Float64
from .export import decode_metadata_from_execution_engine


def _get_ctypes_return_type(args_spec: FullArgSpec):
    """Get the ctypes return type from the args_spec."""
    return_type = args_spec.annotations.get("return", None)
    if return_type is None:
        raise DSLRuntimeError("Return type is not specified for AOT compiled function.")
    type_to_ctype = {
        Int32: ctypes.c_int32,
        Int64: ctypes.c_int64,
        Float32: ctypes.c_float,
        Float64: ctypes.c_double,
        # Add other types if needed
    }

    ctype = type_to_ctype.get(return_type)
    if ctype is None:
        raise DSLRuntimeError(f"Unsupported return type for AOT loading: {return_type}")

    return ctype


class LoadProvider:
    """The load provider is a class that stores the necessary information to construct a ExternalBinaryModule,
    it could be set later by specific DSL."""

    def __init__(
        self,
        dsl: "Type[BaseDSL]",
        args_spec_processor: "ArgsSpecProcessor",
        version_checker: Callable,
        execution_engine_constructor: Callable,
        jit_function_constructor: Callable,
    ):
        self.dsl = dsl
        self.args_spec_processor = args_spec_processor
        self.version_checker = version_checker
        self.execution_engine_constructor = execution_engine_constructor
        self.jit_function_constructor = jit_function_constructor


class ExternalBinaryModule:
    """The exported binary module is a wrapper of the previous exported object files. It is used to load a object file
    or a library in memory, allow function lookup and return the corresponding `JitCompiledFunction`.
    """

    load_provider: LoadProvider = None

    def __init__(self, file_path: str):
        assert self.load_provider is not None, (
            "Load provider is not set for ExternalBinaryModule."
        )
        shared_libs = self.load_provider.dsl._get_dsl().get_shared_libs()
        object_file_content = bytes()
        if file_path.endswith(".so"):
            shared_libs.append(file_path)
        else:
            try:
                with open(file_path, "rb") as f:
                    object_file_content = f.read()
            except Exception as e:
                raise DSLRuntimeError(f"Failed to read object file {file_path}: {e}")
        # Lifetime of the engine is same as the ExternalBinaryModule.
        self.engine = self.load_provider.execution_engine_constructor(
            object_file_content, shared_libs
        )

    def __getattr__(self, function_prefix: str) -> "JitCompiledFunction":
        """Get the jit_function from the `function_prefix`. The `function_prefix` is specified when users dump the object file. When there is no function_prefix found in the module, the function will raise an error."""
        try:
            args_spec, function_name, kernel_info, version_str = (
                decode_metadata_from_execution_engine(
                    function_prefix, self.engine, self.load_provider.args_spec_processor
                )
            )
        except Exception as e:
            raise DSLRuntimeError(
                f"Function prefix {function_prefix} not found in the module.", cause=e
            )
        self.load_provider.version_checker(version_str)
        capi_func_p = self.engine.lookup(function_name)
        if not capi_func_p:
            raise DSLRuntimeError(
                "Unknown function: "
                + "_mlir_"
                + function_prefix
                + "__mlir_ciface_"
                + function_name
            )
        return_type = _get_ctypes_return_type(args_spec)
        capi_func = ctypes.CFUNCTYPE(return_type, ctypes.c_void_p)(capi_func_p)
        jit_function = self.load_provider.jit_function_constructor(
            ir_module=None,
            engine=self.engine,
            capi_func=capi_func,
            args_spec=args_spec,
            function_name=function_name,
            kernel_info=kernel_info,
            jit_time_profiling=self.load_provider.dsl._get_dsl().envar.jit_time_profiling,
            jit_function_artifacts=None,
            prefix=function_prefix,
            load_from_binary=True,
        )
        return jit_function
