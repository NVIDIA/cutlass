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

"""
This module provides jit executor related classes
"""

import array
import ctypes
import inspect
import io
from typing import Union, Optional, NamedTuple, Any, Sequence
import weakref
import threading
import collections
import os
import tempfile
from dataclasses import dataclass

# MLIR modules imports
from .._mlir import ir
from .._mlir.dialects import llvm

# Local modules imports
from . import typing as t
from .common import DSLRuntimeError, DSLCudaRuntimeError
from .runtime import cuda as cuda_helpers
from .runtime.jit_arg_adapters import JitArgAdapterRegistry, is_arg_spec_constexpr
from .typing import get_c_pointers
from .utils.logger import log
from .utils.timer import timer


class CudaModuleAndKernel:
    """A loaded CUDA kernel and its metadata."""

    def __init__(self, sym, cuda_module, kernel, attrs):
        self.sym = sym
        self.cuda_module = cuda_module
        self.kernel = kernel
        self.attrs = attrs


def get_escaped_cubin_bytes(cubin_data):
    """This function escapes cubin data from mlir raw bytecode to executable binary bytes"""

    def ishex(inp):
        return (0x30 <= inp < 0x3A) or (0x41 <= inp < 0x47) or (0x61 <= inp < 0x67)

    converted = bytearray()
    idx = 0
    while idx < len(cubin_data):
        # escape the original bytes
        if cubin_data[idx] == 0x5C:
            # if data of idx is b'\\'
            if ishex(cubin_data[idx + 1]) and ishex(cubin_data[idx + 2]):
                converted += bytearray.fromhex(cubin_data[idx + 1 : idx + 3].decode())
                idx += 3
            elif cubin_data[idx + 1] == 0x5C:
                converted.append(cubin_data[idx])
                idx += 2
        else:
            # no escape, directly write
            converted.append(cubin_data[idx])
            idx += 1
    return bytes(converted)


def walk_module_and_get_cubin_data(module, sym, callback):
    """This function is used to walk gpu binary op, extract the cubin inside, and process cubin data with callback."""

    def walk_gpu_binary_op(op):
        if op.name != "gpu.binary":
            return ir.WalkResult.ADVANCE
        s = io.BytesIO()
        op.write_bytecode(s)
        cubin_data = s.getvalue()
        if sym.encode() not in cubin_data:
            return ir.WalkResult.ADVANCE

        if "kernels" != op.opview.sym_name.value and sym != op.opview.sym_name.value:
            return ir.WalkResult.ADVANCE
        # function symbol of kernel(gpu.launch_func) is equal to sym name in mlir
        func_sym = sym
        if sym == op.opview.sym_name.value and not sym.endswith("_kernel"):
            func_sym = sym.rsplit("_", 1)[0]

        cubin_data = cubin_data.split(b'bin = "')[1].split(b'">')[0]
        cubin_data = get_escaped_cubin_bytes(cubin_data)
        callback(sym, func_sym, cubin_data)
        return ir.WalkResult.ADVANCE

    module.operation.walk(walk_gpu_binary_op)


def load_kernels_from_ir_module(module, kernel_info) -> list[CudaModuleAndKernel]:
    """Loads all kernels from the IR module that match the given set of symbols."""
    if not kernel_info:
        return []  # no modules

    # don't sort because the external kernel pointers are recorded in the order called in ir module.
    kernel_symbols = tuple(kernel_info.keys())

    # load cuda module/get function pointer from module and cache
    kernel_modules = collections.OrderedDict()
    for sym in kernel_symbols:
        log().debug(f"Loading CUDA module for symbol: {sym}")

        def walk_callback(sym, func_sym, cubin_data):
            if sym in kernel_modules:
                log().debug(f"Skipping already loaded symbol: {sym}")

            cubin_module = cuda_helpers.load_library_data(cubin_data)
            kernel = cuda_helpers.get_library_kernel(cubin_module, func_sym)

            # Setup attributes we want applied to the loaded kernel functions.
            # A copy is made so we can update one of the attributes.
            attrs = dict(kernel_info[sym])
            if cuda_helpers.get_driver_version() >= 11080:
                attrs[
                    cuda_helpers.cuda.CUfunction_attribute.CU_FUNC_ATTRIBUTE_NON_PORTABLE_CLUSTER_SIZE_ALLOWED
                ] = 1

            kernel_modules[sym] = CudaModuleAndKernel(sym, cubin_module, kernel, attrs)

        walk_module_and_get_cubin_data(module, sym, walk_callback)

    return list(kernel_modules.values())


class KwargsWrapperSpec(NamedTuple):
    """A specification for keyword arguments wrapper."""

    arg_names: list[str]
    arg_defaults: tuple[Any, ...]
    kwonly_names: list[str]
    kwonly_defaults: dict[str, Any]


@dataclass
class ArgMeta:
    """Metadata for function arguments."""

    pos_names: list[str]
    kwonly_names: list[str]
    all_names: list[str]
    annotated_types: list[object]
    numeric_flags: list[bool]
    name_to_index: dict[str, int]
    pos_defaults: list[object]
    kwonly_defaults: list[object]
    arg_count: int


class ExecutionArgs:
    """Helper that wraps the function signature spec to filter execution and compile time arguments."""

    def __init__(self, spec, function_name):
        self.function_name = function_name
        self.args_spec = spec
        if spec is not None:
            self.args_spec = self.filter_runtime_arg_spec(spec)
        self.original_args_spec = spec
        self._missing = object()
        self._meta = self._build_meta()
        self._tls = threading.local()

    def _build_meta(self):
        """
        Precompute metadata for the fast-path execution.
        This metadata is static per function signature.
        """
        spec = self.args_spec
        if spec is None:
            return ArgMeta(
                pos_names=[],
                kwonly_names=[],
                all_names=[],
                annotated_types=[],
                numeric_flags=[],
                name_to_index={},
                pos_defaults=[],
                kwonly_defaults=[],
                arg_count=0,
            )

        pos_names = list(spec.args)
        kwonly_names = list(spec.kwonlyargs)
        all_names = pos_names + kwonly_names

        annotated_types = [spec.annotations.get(n) for n in all_names]
        numeric_flags = [isinstance(typ, t.NumericMeta) for typ in annotated_types]

        name_to_index = {n: i for i, n in enumerate(all_names)}

        pos_defaults = [self._missing] * len(pos_names)
        if spec.defaults:
            start = len(pos_names) - len(spec.defaults)
            for i, d in enumerate(spec.defaults):
                pos_defaults[start + i] = d

        kwonly_defaults = [self._missing] * len(kwonly_names)
        if spec.kwonlydefaults:
            for i, n in enumerate(kwonly_names):
                if n in spec.kwonlydefaults:
                    kwonly_defaults[i] = spec.kwonlydefaults[n]

        return ArgMeta(
            pos_names=pos_names,
            kwonly_names=kwonly_names,
            all_names=all_names,
            annotated_types=annotated_types,
            numeric_flags=numeric_flags,
            name_to_index=name_to_index,
            pos_defaults=pos_defaults,
            kwonly_defaults=kwonly_defaults,
            arg_count=len(all_names),
        )

    def generate_execution_args_positional(self, *args):
        """Fast execution for positional-only arguments with exact count match.

        This method is optimized for the common case where:
        - All arguments are positional (no kwargs)
        - Number of arguments matches the function signature exactly

        :param args: The positional arguments tuple
        :return: (exe_args, adapted_args) tuple
        """
        exe_arg_chunks = [None] * self._meta.arg_count
        adapted_args = []

        tls = self._tls
        adapter_caches = getattr(tls, "adapter_caches", None)
        if adapter_caches is None:
            adapter_caches = [dict() for _ in range(self._meta.arg_count)]
            tls.adapter_caches = adapter_caches

        annotated_types = self._meta.annotated_types
        numeric_flags = self._meta.numeric_flags

        for index in range(self._meta.arg_count):
            arg = args[index]

            cptr_method = getattr(arg, "__c_pointers__", None)
            if cptr_method is not None:
                exe_arg_chunks[index] = cptr_method()
                continue

            if numeric_flags[index]:
                arg = t.cast(arg, annotated_types[index])
                exe_arg_chunks[index] = get_c_pointers(arg)
            else:
                arg_type = type(arg)
                cache = adapter_caches[index]
                adapter = cache.get(arg_type)
                if adapter is None:
                    adapter = JitArgAdapterRegistry.get_registered_adapter(arg_type)
                    if adapter is not None:
                        cache[arg_type] = adapter

                if adapter is not None:
                    arg = adapter(arg)
                    adapted_args.append(arg)

                exe_arg_chunks[index] = get_c_pointers(arg)

        exe_args = [p for chunk in exe_arg_chunks for p in chunk]
        return exe_args, adapted_args

    def get_rectified_args(self, args, kwargs):
        """
        This function is used to rectify the args and kwargs to a final runtime argument list according to the args_spec.
        """
        pos_count = len(self._meta.pos_names)
        if len(args) > pos_count:
            raise DSLRuntimeError(
                "input args/kwargs length does not match runtime function signature!",
                context={
                    "input args length": len(args),
                    "input kwargs length": len(kwargs),
                    "function signature args length": len(self._meta.pos_names),
                    "function signature kwonlyargs length": len(
                        self._meta.kwonly_names
                    ),
                },
            )

        # Start with every slot marked missing, we overwrite as values/defaults bind
        rectified = [self._missing] * self._meta.arg_count
        pos_len = len(args)

        # Fill positional slots with the values from the caller
        rectified[:pos_len] = args

        # Fill positional slots the caller skipped with the defaults
        for i in range(pos_len, pos_count):
            default = self._meta.pos_defaults[i]
            if default is not self._missing:
                rectified[i] = default

        # Fill keyword-only slots with the defaults before user kwargs
        for j, default in enumerate(self._meta.kwonly_defaults):
            idx = pos_count + j
            if default is not self._missing:
                rectified[idx] = default

        # Fill keyword slots with the values from the caller
        for name, value in kwargs.items():
            idx = self._meta.name_to_index.get(name)
            if idx is None:
                raise DSLRuntimeError(
                    "unexpected keyword argument",
                    context={"argument_name": name},
                )
            if idx < pos_len:
                raise DSLRuntimeError(
                    "multiple values for argument",
                    context={"argument_name": name},
                )
            rectified[idx] = value

        if self._missing in rectified:
            missing_args = [
                name
                for i, name in enumerate(self._meta.all_names)
                if rectified[i] is self._missing
            ]
            raise DSLRuntimeError(
                "input args/kwargs length does not match runtime function signature!",
                context={
                    "missing": missing_args,
                    "function signature args length": len(self._meta.pos_names),
                    "function signature kwonlyargs length": len(
                        self._meta.kwonly_names
                    ),
                },
            )

        return rectified

    def generate_execution_args(self, args, kwargs):
        """
        This function is the prune version of `generate_mlir_function_types` which only generates execution args
        to get rid of mlir context.
        """
        if not kwargs and len(args) == self._meta.arg_count:
            return self.generate_execution_args_positional(*args)

        exe_arg_chunks = [None] * self._meta.arg_count
        adapted_args = []
        tls = self._tls
        adapter_caches = getattr(tls, "adapter_caches", None)
        if adapter_caches is None:
            adapter_caches = [dict() for _ in range(self._meta.arg_count)]
            tls.adapter_caches = adapter_caches

        input_args = self.get_rectified_args(args, kwargs)

        for index, arg in enumerate(input_args):
            cptr_method = getattr(arg, "__c_pointers__", None)
            if cptr_method is not None:
                exe_arg_chunks[index] = cptr_method()
                continue

            arg_type_anno = self._meta.annotated_types[index]

            if self._meta.numeric_flags[index]:
                arg = t.cast(arg, arg_type_anno)
                exe_arg_chunks[index] = get_c_pointers(arg)
            else:
                arg_type = type(arg)
                cache = adapter_caches[index]
                adapter = cache.get(arg_type)
                if adapter is None:
                    adapter = JitArgAdapterRegistry.get_registered_adapter(arg_type)
                    if adapter is not None:
                        cache[arg_type] = adapter

                if adapter is not None:
                    arg = adapter(arg)
                    adapted_args.append(arg)

                exe_arg_chunks[index] = get_c_pointers(arg)

        exe_args = [p for chunk in exe_arg_chunks for p in chunk]

        return exe_args, adapted_args

    def get_kwargs_wrapper_spec(
        self, exclude_arg_names: Sequence[str] = ()
    ) -> KwargsWrapperSpec:
        """
        This function is used to get the kwargs wrapper spec from the original args_spec.
        """
        excluded_arg_names = set(exclude_arg_names)
        arg_spec = self.original_args_spec

        if arg_spec.defaults:
            defaults_start_idx = len(arg_spec.args) - len(arg_spec.defaults)
        else:
            defaults_start_idx = len(arg_spec.args)

        arg_names = []
        arg_defaults = []
        kwonly_names = []
        kwonly_defaults = {}

        # Filter arguments and maintain their properties
        for i, arg_name in enumerate(arg_spec.args):
            arg_type = arg_spec.annotations.get(arg_name, None)

            # Skip compile-time arguments
            if is_arg_spec_constexpr(arg_type, arg_name, i, self.function_name):
                continue
            if arg_name in excluded_arg_names:
                continue
            arg_names.append(arg_name)

            if i >= defaults_start_idx:
                arg_defaults.append(arg_spec.defaults[i - defaults_start_idx])

        if arg_spec.kwonlyargs:
            for i, kwarg in enumerate(arg_spec.kwonlyargs):
                arg_type = arg_spec.annotations.get(kwarg, None)

                # Skip compile-time arguments
                if is_arg_spec_constexpr(arg_type, kwarg, i, self.function_name):
                    continue

                if kwarg in excluded_arg_names:
                    continue

                kwonly_names.append(kwarg)
                if arg_spec.kwonlydefaults and kwarg in arg_spec.kwonlydefaults:
                    kwonly_defaults[kwarg] = arg_spec.kwonlydefaults[kwarg]

        return KwargsWrapperSpec(
            arg_names=arg_names,
            arg_defaults=tuple(arg_defaults),
            kwonly_names=kwonly_names,
            kwonly_defaults=kwonly_defaults,
        )

    def get_rectified_args_from_original_args(self, full_args, full_kwargs):
        """
        This function is used to rectify the original arguments to the runtime
        arguments that matched the original args_spec.

        :param full_args: The original full arguments to filter.
        :param full_kwargs: The original full keyword arguments to filter.
        :return: The filtered arguments and keyword arguments.
        """
        arg_spec = self.original_args_spec

        if arg_spec.defaults:
            defaults_start_idx = len(arg_spec.args) - len(arg_spec.defaults)
        else:
            defaults_start_idx = len(arg_spec.args)

        runtime_args = []

        # Filter arguments and maintain their properties
        for i, arg_name in enumerate(arg_spec.args):
            arg_type = arg_spec.annotations.get(arg_name, None)

            # Skip compile-time arguments
            if is_arg_spec_constexpr(arg_type, arg_name, i, self.function_name):
                continue

            # Check if argument was provided by user, otherwise use default
            if i < len(full_args):
                # User provided this argument - use it
                runtime_args.append(full_args[i])
            elif i >= defaults_start_idx:
                # Argument not provided, but has default - use default
                default_idx = i - defaults_start_idx
                runtime_args.append(arg_spec.defaults[default_idx])
            else:
                # Required argument missing
                raise DSLRuntimeError(
                    f"Missing required argument '{arg_name}' at position {i}",
                    context={
                        "function_name": self.function_name,
                        "expected_args": len(arg_spec.args),
                        "provided_args": len(full_args),
                    },
                )

        # Filter keyword-only arguments
        runtime_kwargs = {}
        if arg_spec.kwonlyargs:
            for i, kwarg in enumerate(arg_spec.kwonlyargs):
                arg_type = arg_spec.annotations.get(kwarg, None)

                # Skip compile-time arguments
                if is_arg_spec_constexpr(arg_type, kwarg, i, self.function_name):
                    continue

                # Keep runtime keyword-only arguments
                if kwarg in full_kwargs:
                    runtime_kwargs[kwarg] = full_kwargs[kwarg]
                elif arg_spec.kwonlydefaults and kwarg in arg_spec.kwonlydefaults:
                    runtime_kwargs[kwarg] = arg_spec.kwonlydefaults[kwarg]

        if len(runtime_args) != len(self.args_spec.args) or len(runtime_kwargs) != len(
            self.args_spec.kwonlyargs
        ):
            raise DSLRuntimeError(
                "input args/kwargs length does not match runtime function signature!",
                context={
                    "input args length": len(runtime_args),
                    "input kwargs length": len(runtime_kwargs),
                    "function signature args length": len(self.args_spec.args),
                    "function signature kwonlyargs length": len(
                        self.args_spec.kwonlyargs
                    ),
                },
            )

        return runtime_args + list(runtime_kwargs.values())

    def filter_runtime_arg_spec(self, arg_spec: inspect.FullArgSpec):
        runtime_args = []
        runtime_annotations = {}
        runtime_defaults = []

        # Calculate the offset where defaults start in the original args
        if arg_spec.defaults:
            defaults_start_idx = len(arg_spec.args) - len(arg_spec.defaults)
        else:
            defaults_start_idx = len(arg_spec.args)

        # Filter arguments and maintain their properties
        for i, arg_name in enumerate(arg_spec.args):
            arg_type = arg_spec.annotations.get(arg_name, None)

            # Skip compile-time arguments
            if is_arg_spec_constexpr(arg_type, arg_name, i, self.function_name):
                continue

            # Keep runtime arguments
            runtime_args.append(arg_name)
            if arg_name in arg_spec.annotations:
                runtime_annotations[arg_name] = arg_type

            # Keep corresponding default if it exists
            if i >= defaults_start_idx:
                default_idx = i - defaults_start_idx
                runtime_defaults.append(arg_spec.defaults[default_idx])

        # Filter kwonlyargs and their defaults
        runtime_kwonlyargs = []
        runtime_kwonlydefaults = {}

        if arg_spec.kwonlyargs:
            for i, kwarg in enumerate(arg_spec.kwonlyargs):
                arg_type = arg_spec.annotations.get(kwarg, None)

                # Apply same filtering logic
                if is_arg_spec_constexpr(arg_type, kwarg, i, self.function_name):
                    continue

                runtime_kwonlyargs.append(kwarg)
                if kwarg in arg_spec.annotations:
                    runtime_annotations[kwarg] = arg_type
                if arg_spec.kwonlydefaults and kwarg in arg_spec.kwonlydefaults:
                    runtime_kwonlydefaults[kwarg] = arg_spec.kwonlydefaults[kwarg]

        # Convert runtime_defaults to tuple if not empty (as expected by FullArgSpec)
        runtime_defaults = tuple(runtime_defaults) if runtime_defaults else None

        return inspect.FullArgSpec(
            args=runtime_args,
            varargs=arg_spec.varargs,  # Keep original varargs
            varkw=arg_spec.varkw,  # Keep original varkw
            defaults=runtime_defaults,
            kwonlyargs=runtime_kwonlyargs,
            kwonlydefaults=runtime_kwonlydefaults if runtime_kwonlydefaults else None,
            annotations=runtime_annotations,
        )

    def get_constexpr_args(self) -> list[dict[str, Union[int, str]]]:
        """
        This function returns the constexpr args that have been pruned from the original function signature.
        The return type is a list of dicts, each dict contains the argument index (argument_index) and argument name (argument_name).

        :return: list of dicts, each dict contains the argument index (argument_index) and argument name (argument_name).
        :rtype: list[dict[str, Union[int, str]]]
        """
        if self.original_args_spec is None:
            return list()
        constexpr_args = list()
        for i, arg_name in enumerate(self.original_args_spec.args):
            if arg_name not in self.args_spec.args:
                constexpr_args.append({"argument_index": i, "argument_name": arg_name})

        if self.original_args_spec.kwonlyargs:
            for kwarg in self.original_args_spec.kwonlyargs:
                if kwarg not in self.args_spec.kwonlyargs:
                    constexpr_args.append(
                        {"argument_index": None, "argument_name": kwarg}
                    )
        return constexpr_args


class JitExecuteContext:
    """Holds device specific context for execution."""

    def __init__(
        self,
        module: "JitModule",
        kernel_fns=None,
        context: Optional[cuda_helpers.DevicePrimaryContext] = None,
    ):
        if kernel_fns is None:
            kernel_fns = []
        self.module = module
        self.kernel_functions = kernel_fns
        self.kernel_functions_ptrs = [ctypes.c_void_p(k.getPtr()) for k in kernel_fns]
        self.context = context


class JitModule:
    """Holds the execution engine and cuda modules."""

    def __init__(
        self,
        engine,
        capi_func,
        args_spec: ExecutionArgs,
        modules: list[CudaModuleAndKernel],
    ):
        self.engine = engine
        self.capi_func = capi_func
        self.args_spec = args_spec
        self.cuda_modules = modules
        self._unloaded = False

    def get_device_execute_context(self, device=None) -> JitExecuteContext:
        if self._unloaded:
            raise RuntimeError(f"Can not get executor for unloaded module.")

        # Host only code no need to setup kernels
        if not self.cuda_modules:
            return JitExecuteContext(self)

        # We need a device at this point so get one if not provided.
        if device is None:
            device = cuda_helpers.get_current_device()
        elif isinstance(device, int):
            device = cuda_helpers.get_device(device)

        # Activate a primary context for the device:
        context = cuda_helpers.DevicePrimaryContext(device)

        # Get kernel functions from the kernels
        kernel_fns = []
        for m in self.cuda_modules:
            fn = cuda_helpers.get_function_from_kernel(m.kernel)
            kernel_fns.append(fn)

            # Set attributes for the kernel function
            for attr, val in m.attrs.items():
                cuda_helpers.set_kernel_attribute(fn, attr, val)

        # This instance will "own" a reference to the primary device context.
        # It will release the the reference once its no longer alive or
        # an explicit call to unload is made.
        #
        # The default module loading mode is CU_MODULE_LAZY_LOADING so
        # the module will not be loaded to the device until the first call
        # to execute it. # This can be modified using CUDA_MODULE_LOADING
        # environment variable.
        return JitExecuteContext(self, kernel_fns, context)

    def unload(self):
        try:
            for m in set([m.cuda_module for m in self.cuda_modules]):
                cuda_helpers.unload_library(m)
            self.cuda_modules.clear()
        except Exception as e:
            pass
        finally:
            self._unloaded = True

    def __del__(self):
        self.unload()


class JitExecutor:
    """An executable function that can be called to launch a device kernel.

    JitExecutor is tired to a specific device context and should only be called
    in a context on that device.
    """

    def __init__(
        self,
        jit_module: Union[JitModule, "CudaDialectJitModule"],
        exec_context: Optional[JitExecuteContext],
        jit_time_profiling: bool,
    ):
        # JitExecutor will keep JitCompiledFunction alive so that the underlying
        # ExecutionEngine and module data is not discarded until runtime callables
        # are garbage collected.
        self.jit_module = jit_module
        self.exec_context = exec_context
        self.profiler = timer(enable=jit_time_profiling) if jit_time_profiling else None

        # Get the cuda result type from the capi function.
        # This is only set to i32 if CudaDialectJitModule is used.
        cuda_result_type = self.jit_module.capi_func.restype
        self.cuda_result = cuda_result_type() if cuda_result_type is not None else None

        # Pre-compute flags
        self._has_cuda_result = self.cuda_result is not None
        self._has_profiler = self.profiler is not None
        self._cuda_result_addr = (
            ctypes.addressof(self.cuda_result) if self._has_cuda_result else None
        )

        if jit_time_profiling:
            self._get_invoke_packed_args_func = self.profiler(
                self._get_invoke_packed_args
            )
            self.capi_func = self.profiler(self.jit_module.capi_func)
        else:
            self._get_invoke_packed_args_func = self._get_invoke_packed_args
            self.capi_func = self.jit_module.capi_func

        # Pre-compute packed args metadata
        self._num_extra_args = 0
        if self._has_cuda_result:
            self._num_extra_args += 1
        if self.exec_context is not None:
            self._kernel_ptrs = self.exec_context.kernel_functions_ptrs
            self._num_extra_args += len(self._kernel_ptrs)
        else:
            self._kernel_ptrs = None
        self._tls = threading.local()

    # Assume each execution args has type `c_void_p` to reduce the overhead of `ctypes.cast`.
    def _get_invoke_packed_args(self, exe_args):
        # Pre-calculate sizes once during init and cache
        num_base_args = len(exe_args)
        total_args = num_base_args + self._num_extra_args

        # Re-use packed args buffer if possible
        tls = self._tls
        packed_args = getattr(tls, "packed_args", None)
        capacity = getattr(tls, "capacity", 0)

        if packed_args is None or capacity < total_args:
            packed_args = (ctypes.c_void_p * total_args)()
            tls.packed_args = packed_args
            tls.capacity = total_args

            idx = num_base_args
            if self._has_cuda_result:
                packed_args[idx] = self._cuda_result_addr
                idx += 1
            if self._kernel_ptrs is not None:
                for ptr in self._kernel_ptrs:
                    packed_args[idx] = ptr
                    idx += 1

        for i in range(num_base_args):
            arg = exe_args[i]
            packed_args[i] = (
                arg if type(arg) is ctypes.c_void_p else ctypes.c_void_p(arg).value
            )

        return packed_args

    def generate_execution_args(self, *args, **kwargs):
        return self.jit_module.args_spec.generate_execution_args(args, kwargs)

    def run_compiled_program(self, exe_args):
        try:
            packed_args = self._get_invoke_packed_args_func(exe_args)
            self.capi_func(packed_args)
            if not self._has_cuda_result:
                return None
            error_code = self.cuda_result.value
            if error_code == 0:
                return error_code
            error_name = cuda_helpers._cudaGetErrorEnum(
                cuda_helpers.cuda.CUresult(error_code)
            )
            raise DSLCudaRuntimeError(error_code, error_name)
        except DSLCudaRuntimeError as e:
            raise e
        except Exception as e:
            raise DSLRuntimeError(f"💥💥💥 Runtime Crash 💥💥💥", cause=e)

    def __call__(self, *args, **kwargs):
        exe_args, adapted_args = self.generate_execution_args(*args, **kwargs)
        return self.run_compiled_program(exe_args)


@dataclass
class JitFunctionArtifacts:
    """Holds artifacts for a JIT-compiled function."""

    PTX: str
    CUBIN: str
    MLIR: str

    def __post_init__(self):
        if self.PTX is not None and os.path.exists(self.PTX):
            try:
                with open(self.PTX, "r") as f:
                    self.PTX = f.read()
            except (IOError, OSError) as e:
                raise DSLRuntimeError(f"Failed to read PTX file '{self.PTX}': {e}")
        if self.CUBIN is not None and os.path.exists(self.CUBIN):
            try:
                with open(self.CUBIN, "rb") as f:
                    self.CUBIN = f.read()
            except (IOError, OSError) as e:
                raise DSLRuntimeError(f"Failed to read CUBIN file '{self.CUBIN}': {e}")
        if self.MLIR is not None and os.path.exists(self.MLIR):
            try:
                with open(self.MLIR, "r") as f:
                    self.MLIR = f.read()
            except (IOError, OSError) as e:
                raise DSLRuntimeError(f"Failed to read MLIR file '{self.MLIR}': {e}")


class ExportProvider:
    """Holds the dsl specific settings for the export of the jit-compiled function."""

    dsl: "Type[BaseDSL]" = None
    arg_spec_processor: "ArgsSpecProcessor" = None
    c_header_generator: "CHeaderGenerator" = None
    object_file_version: str = None

    def __init__(
        self,
        dsl: "Type[BaseDSL]",
        arg_spec_processor: "ArgsSpecProcessor",
        c_header_generator: "CHeaderGenerator",
        object_file_version: str,
        mlirExecutionEngine: "MlirExecutionEngine",
    ):
        self.dsl = dsl
        self.arg_spec_processor = arg_spec_processor
        self.c_header_generator = c_header_generator
        self.object_file_version = object_file_version
        self.mlirExecutionEngine = mlirExecutionEngine


class JitCompiledFunction:
    """Holds a compiled function."""

    export_provider: ExportProvider = None

    def __init__(
        self,
        ir_module,
        engine,
        capi_func,
        args_spec,
        function_name,
        kernel_info,
        jit_time_profiling,
        jit_function_artifacts,
        prefix=None,
        load_from_binary=False,
        dynamic_args=None,
        dynamic_kwargs=None,
    ):
        self.ir_module = ir_module
        self.engine = engine
        self.capi_func = capi_func
        self.function_name = function_name
        self.kernel_info = kernel_info
        if args_spec is not None:
            self.args_spec = ExecutionArgs(args_spec, self.function_name)
        self.jit_time_profiling = jit_time_profiling

        assert (
            isinstance(jit_function_artifacts, JitFunctionArtifacts)
            or jit_function_artifacts is None
        )
        self.artifacts = jit_function_artifacts
        self.prefix = prefix
        self.load_from_binary = load_from_binary

        # This runtime state is stored here so that we can preserve the module
        # in the compiler cache. Callers can extend the lifetime of the module
        # by creating and retaining the executor.
        self.jit_module = None
        self._executor_lock = threading.RLock()
        self._default_executor = None

        # This is used to do early generation of the c header arguments to release the reference to the dynamic arguments.
        self._generate_c_header_arguments(dynamic_args, dynamic_kwargs)

    @property
    def __ptx__(self):
        """Returns the PTX code of the JIT-compiled function."""
        return self.artifacts.PTX if self.artifacts is not None else None

    @property
    def __cubin__(self):
        """Returns the CUBIN data of the JIT-compiled function."""
        return self.artifacts.CUBIN if self.artifacts is not None else None

    @property
    def __mlir__(self):
        """Returns the MLIR code of the JIT-compiled function."""
        return self.artifacts.MLIR if self.artifacts is not None else None

    def _deserializer(self):
        """Load the cuda module from the binary execution engine. This function will be injected as the
        JitCompiledFunction method which will be called by the jit executor to load the cuda module by AOT flow.
        @param self: The JitCompiledFunction object. This is the JitCompiledFunction object to load the cuda module.
        @param name: The name of the function. This is the unique identifier name of the function to avoid symbol conflict in the generated object file.
        @param execution_engine: The binary execution engine. This is the execution engine to load the cuda module.
        @param kernel_info: The kernel info. This is the kernel info to load the cuda module.
        @return: The list of cuda modules.
        """
        cubin_suffix = "cubin"
        if self.prefix is None:
            raise DSLRuntimeError("prefix is required to be set for binary loading")
        cubin_data = self.engine.lookup("_".join([self.prefix, cubin_suffix]))
        if not cubin_data:
            raise RuntimeError(
                "Unknown function " + "_".join([self.prefix, cubin_suffix])
            )
        cubin_module = cuda_helpers.load_library_data(cubin_data)
        # load cuda module/get function pointer from module and cache
        kernel_modules = collections.OrderedDict()
        for sym, attrs in self.kernel_info.items():
            kernel = cuda_helpers.get_library_kernel(cubin_module, sym)
            if cuda_helpers.get_driver_version() >= 11080:
                attrs[
                    cuda_helpers.cuda.CUfunction_attribute.CU_FUNC_ATTRIBUTE_NON_PORTABLE_CLUSTER_SIZE_ALLOWED
                ] = 1
            kernel_modules[sym] = CudaModuleAndKernel(sym, cubin_module, kernel, attrs)
        return list(kernel_modules.values())

    def _validate_engine(self):
        if self.engine is None:
            raise DSLRuntimeError(
                "The compiled function does not have a valid execution engine.",
                suggestion="For cross-compilation, please use `JitCompiledFunction.export_to_c` to serialize the compiled function and load/execute it on target device.",
            )

    def to(self, device=None) -> JitExecutor:
        """Returns an executable function bound to the given device.

        For multi-device execution this method can be called for each device where
        the kernel will run.

        :param device: Specifies the device for the executor. If None the current device is used.
        :type device: Optional[Union[int, CUdevice]]
        :return: A callable executor function.
        :rtype: JitExecutor
        """
        self._validate_engine()
        with self._executor_lock:
            # We need to ensure that the modules are loaded if not already
            if self.jit_module is None:
                if self.ir_module is not None:
                    cuda_modules = load_kernels_from_ir_module(
                        self.ir_module, self.kernel_info
                    )
                self.jit_module = JitModule(
                    self.engine, self.capi_func, self.args_spec, cuda_modules
                )

            # Create a new executor that will be tied to a device context
            # n.b. host only moduels do not load device specific modules or context.
            context = self.jit_module.get_device_execute_context(device)
            return JitExecutor(self.jit_module, context, self.jit_time_profiling)

    def generate_execution_args(self, *args, **kwargs):
        return self.args_spec.generate_execution_args(args, kwargs)

    def __call__(self, *args, **kwargs):
        """Executes the jit-compiled function under the currently active CUDA context.

        Calling this method multiple devices is not allowed and will result in unexpected
        CUDA errors. If you need to call the kernel on multiple devices use `to`
        to return a per-device function.
        """
        exe_args, adapted_args = self.args_spec.generate_execution_args(args, kwargs)
        executor = self._default_executor
        if executor is not None:  # Only lock on first call
            return executor.run_compiled_program(exe_args)
        return self.run_compiled_program(exe_args)

    def run_compiled_program(self, exe_args):
        """Executes the jit-compiled function under the currently active CUDA context.

        Calling this method multiple devices is not allowed and will result in unexpected
        CUDA errors. If you need to call the kernel on multiple devices use `to`
        to return a per-device function.
        """
        with self._executor_lock:
            if self._default_executor is None:
                log().debug("Creating default executor.")
                # We use a weak reference here so that this instance does not keep this
                # object alive as it hold a reference to self.
                proxy_self = weakref.proxy(self)
                self._default_executor = proxy_self.to(None)
        return self._default_executor.run_compiled_program(exe_args)

    def _generate_c_header_arguments(self, dynamic_args, dynamic_kwargs):
        """Generates the c header arguments for the AOT C header generation."""
        self.c_header_arguments = None
        from .export import CHeaderArguments

        if dynamic_args is not None or dynamic_kwargs is not None:
            self.dummy_prefix_name = "dummy_prefix_name"
            try:
                # This arguments may be generated failure due to not all the arguments (e.g. custom types) are supported by the AOT C header generator.
                c_header_arguments, packed_args, declarations = (
                    self.export_provider.c_header_generator._generate_arguments(
                        self.dummy_prefix_name,
                        self.args_spec,
                        dynamic_args,
                        dynamic_kwargs,
                    )
                )
                self.c_header_arguments = CHeaderArguments(
                    self.dummy_prefix_name,
                    c_header_arguments,
                    packed_args,
                    declarations,
                    None,
                )
            except Exception as e:
                self.c_header_arguments = CHeaderArguments(
                    self.dummy_prefix_name, [], [], [], str(e)
                )

    def dump_to_object(
        self,
        function_prefix: str,
    ) -> bytes:
        """Dump the compiled ir function to a bytes object with ELF format. The bytes object contains the host
        launch entry function and cubin inside.

        @param function_prefix: The prefix name of the function. This is the user provided unique identifier name of the function to avoid symbol conflict in the generated object file.
        @return: The bytes object of the function.
        """
        # lazy import to avoid circular dependency
        from .export import get_export_module, encode_metadata_into_ir_module

        assert self.export_provider is not None, (
            "Export provider is not set for JitCompiledFunction."
        )
        export_module = get_export_module(self.ir_module, function_prefix)
        export_module = encode_metadata_into_ir_module(
            function_prefix,
            export_module,
            self.args_spec.args_spec,
            self.function_name,
            self.kernel_info,
            self.export_provider.arg_spec_processor,
            self.export_provider.object_file_version,
        )

        cubin_data = None

        def strip_gpu_binary_op(op):
            if op.name == "gpu.binary":
                s = io.BytesIO()
                op.operation.write_bytecode(s)
                nonlocal cubin_data
                cubin_data = s.getvalue()
                cubin_data = cubin_data.split(b'bin = "')[1].split(b'">')[0]
                cubin_data = get_escaped_cubin_bytes(cubin_data)
                op.erase()
                return ir.WalkResult.ADVANCE
            return ir.WalkResult.ADVANCE

        # Strip gpu related to avoid the object file generating builtin module load/unload functions
        export_module.operation.walk(strip_gpu_binary_op)
        cubin_suffix = "cubin"
        if cubin_data is not None:
            cubin_array = array.array("b", cubin_data)
            with (
                export_module.context,
                ir.Location.unknown(),
                ir.InsertionPoint(export_module.body),
            ):
                new_binary_global_op = llvm.GlobalOp(
                    sym_name="_".join([function_prefix, cubin_suffix]),
                    global_type=ir.Type.parse(f"!llvm.array<{len(cubin_array)} x i8>"),
                    linkage=ir.Attribute.parse("#llvm.linkage<external>"),
                    value=ir.DenseIntElementsAttr.get(cubin_array),
                    constant=True,
                )

        if "gpu.container_module" in export_module.operation.attributes:
            del export_module.operation.attributes["gpu.container_module"]
        # Generate the object file

        try:
            with tempfile.NamedTemporaryFile() as tmp_object_file:
                self.export_provider.mlirExecutionEngine.dump_object_file_pic(
                    export_module,
                    tmp_object_file.name,
                    "_".join([function_prefix, self.function_name]),
                )
                with open(tmp_object_file.name, "rb") as f:
                    ret = f.read()
                return ret
        except Exception as e:
            raise DSLRuntimeError(f"Error dumping object file: {e}") from e

    def export_to_c(
        self,
        file_path: str,
        file_name: str,
        function_prefix: str = "",
    ):
        """Exports the jit-compiled function to a C compatible files(header/library).
        This is used for c/cpp AOT support.
        The `file_path` will be used as the directory to save the header and object files.
        The `file_name` will be used as the name of the header and object files. The same file name will always overwrite the existing file.
        The `function_prefix` will be used as the symbol prefix of the generated functions, it is guaranteed by
        the caller that the generated functions are unique.


        The c header file is generated with following components:
        1. The host launch entry function. And the structure definitions of the arguments.
        2. The device metadata load/unload functions.
        3. The cubin data array and len.

        The library contains the binary of the underlying host launch entry function.

        @param jit_function: The jit-compiled function from `cute.compile`.
        @param file_path: The path to the directory where the header and object files will be saved.
        @param file_name: The name of the header and object files.
        @param function_prefix: The prefix of the function. This is the unique identifier name of the function to avoid symbol conflict in the generated object file. Default to the `file_name`.
        """
        if function_prefix is None or function_prefix == "":
            function_prefix = file_name

        assert self.export_provider is not None, (
            "Export provider is not set for JitCompiledFunction."
        )
        # lazy import to avoid circular dependency
        from .export import get_export_module

        export_module = get_export_module(self.ir_module, function_prefix)
        # Generate the c header file
        header_file_content = self.export_provider.c_header_generator(
            function_prefix,
            export_module,
            self.args_spec,
            self.function_name,
            self.kernel_info,
            self.c_header_arguments,
            self.export_provider.dsl._get_dsl().name,
        )
        try:
            with open(os.path.join(file_path, file_name + ".h"), "w") as f:
                f.write(header_file_content)
        except Exception as e:
            raise DSLRuntimeError(f"Error writing header file: {e}") from e

        # Generate the object file
        object_file_content = self.dump_to_object(function_prefix)
        try:
            with open(os.path.join(file_path, file_name + ".o"), "wb") as f:
                f.write(object_file_content)
        except Exception as e:
            raise DSLRuntimeError(f"Error writing object file: {e}") from e
