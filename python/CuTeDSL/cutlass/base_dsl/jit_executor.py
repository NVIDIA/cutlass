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

"""
This module provides jit executor related classes
"""

import ctypes
import inspect
import io
from typing import Union, Optional
import weakref
import threading
import collections
import os
from dataclasses import dataclass

# MLIR modules imports
from .._mlir import ir

# Local modules imports
from . import typing as t
from .common import DSLRuntimeError
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


class ExecutionArgs:
    """Helper that wraps the function signature spec to filter exeuction and compile time arguments."""

    def __init__(self, spec, function_name):
        self.function_name = function_name
        self.args_spec = spec
        if spec is not None:
            self.args_spec = self.filter_runtime_arg_spec(spec)
        self.original_args_spec = spec

    def generate_execution_args(self, args, kwargs):
        """
        This function is the prune version of `generate_mlir_function_types` which only generates execution args
        to get rid of mlir context.
        """
        args_spec = self.args_spec

        # Process positional arguments with defaults
        rectified_args = list(args)
        if args_spec.defaults and len(args) < len(args_spec.args):
            rectified_args.extend(args_spec.defaults[len(args) - len(args_spec.args) :])
        for k, v in kwargs.items():
            if k in args_spec.args:
                idx = args_spec.args.index(k)
                if idx < len(rectified_args):
                    rectified_args[idx] = v
                else:
                    rectified_args.append(v)

        # Process keyword arguments
        rectified_kwargs = {k: v for k, v in kwargs.items() if k not in args_spec.args}
        if args_spec.kwonlydefaults and len(rectified_kwargs) < len(
            args_spec.kwonlyargs
        ):
            rectified_kwargs.update(args_spec.kwonlydefaults)

        # args/kwargs must match arg_specs
        if len(rectified_args) != len(args_spec.args) or len(rectified_kwargs) != len(
            args_spec.kwonlyargs
        ):
            raise DSLRuntimeError(
                "input args/kwargs length does not match runtime function signature!",
                context={
                    "input args length": len(rectified_args),
                    "input kwargs length": len(rectified_kwargs),
                    "function signature args length": len(args_spec.args),
                    "function signature kwonlyargs length": len(args_spec.kwonlyargs),
                },
            )

        exe_args = []
        adapted_args = []
        input_args = rectified_args + list(rectified_kwargs.values())
        input_arg_names = args_spec.args + args_spec.kwonlyargs
        for arg, arg_name in zip(input_args, input_arg_names):
            # short-cut for args already converted
            if hasattr(arg, "__c_pointers__"):
                exe_args.extend(arg.__c_pointers__())
                continue

            arg_type = args_spec.annotations.get(arg_name, None)

            # Implicit cast to NumericMeta
            if isinstance(arg_type, t.NumericMeta):
                arg = t.cast(arg, arg_type)
            else:
                # If not any known type, try registered adapter to do the conversion
                adapter = JitArgAdapterRegistry.get_registered_adapter(type(arg))
                if adapter:
                    arg = adapter(arg)
                    adapted_args.append(arg)

            exe_args.extend(get_c_pointers(arg))

        return exe_args, adapted_args

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
            for kwarg in arg_spec.kwonlyargs:
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
        kernel_fns=[],
        context: Optional[cuda_helpers.DevicePrimaryContext] = None,
    ):
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
        jit_module: JitModule,
        exec_context: JitExecuteContext,
        jit_time_profiling: bool,
    ):
        # JitExecutor will keep JitCompiledFunction alive so that the underlying
        # ExecutionEngine and module data is not discarded until runtime callables
        # are garbage collected.
        self.jit_module = jit_module
        self.exec_context = exec_context
        self.profiler = timer(enable=jit_time_profiling)

    # Assume each execution args has type `c_void_p` to reduce the overhead of `ctypes.cast`.
    def _get_invoke_packed_args(self, exe_args):
        exe_args += self.exec_context.kernel_functions_ptrs
        packed_args = (ctypes.c_void_p * len(exe_args))()
        for argNum in range(len(exe_args)):
            packed_args[argNum] = exe_args[argNum]
        return packed_args

    def generate_execution_args(self, *args, **kwargs):
        return self.jit_module.args_spec.generate_execution_args(args, kwargs)

    def run_compiled_program(self, exe_args):
        try:
            packed_args = self.profiler(self._get_invoke_packed_args)(exe_args)
            self.profiler(self.jit_module.capi_func)(packed_args)
        except Exception as e:
            raise DSLRuntimeError(f"💥💥💥 Runtime Crash 💥💥💥", cause=e)

    def __call__(self, *args, **kwargs):
        exe_args, adapted_args = self.generate_execution_args(*args, **kwargs)
        self.run_compiled_program(exe_args)


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


class JitCompiledFunction:
    """Holds a compiled function."""

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

        # This runtime state is stored here so that we can preserve the module
        # in the compiler cache. Callers can extend the lifetime of the module
        # by creating and retaining the executor.
        self.jit_module = None
        self._executor_lock = threading.RLock()
        self._default_executor = None

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

    def to(self, device=None) -> JitExecutor:
        """Returns an executable function bound to the given device.

        For multi-device execution this method can be called for each device where
        the kernel will run.

        :param device: Specifies the device for the executor. If None the current device is used.
        :type device: Optional[Union[int, CUdevice]]
        :return: A callable executor function.
        :rtype: JitExecutor
        """
        with self._executor_lock:
            # We need to ensure that the modules are loaded if not already
            if self.jit_module is None:
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
        exe_args, adapted_args = self.generate_execution_args(*args, **kwargs)
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
        self._default_executor.run_compiled_program(exe_args)
