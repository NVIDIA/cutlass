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
This module provides jit executor related classes for CUTLASS.
"""
import ctypes
import functools
import weakref
import threading

import cuda.bindings.runtime as cuda_runtime
import cuda.bindings.driver as cuda_driver

# Local modules imports
from ..base_dsl.jit_executor import (
    JitExecutor,
    JitCompiledFunction,
    ExecutionArgs,
    JitFunctionArtifacts,
)
from ..base_dsl.utils.logger import log
from ..base_dsl.common import DSLCudaRuntimeError, DSLRuntimeError
from ..base_dsl.typing import Int32

class CudaDialectJitModule:
    """Holds the execution engine and cuda libraries."""

    def __init__(
        self,
        engine,
        capi_func,
        args_spec: ExecutionArgs,
        cuda_library: list["cuda_runtime.cudaLibrary_t"],
    ):
        self.engine = engine
        self.capi_func = capi_func
        self.args_spec = args_spec
        self.cuda_library = cuda_library
        self._unloaded = False

    def is_unloaded(self):
        return self._unloaded

    def unload(self):
        try:
            for library in self.cuda_library:
                cuda_runtime.cudaLibraryUnload(library)
            self.cuda_library.clear()
        except Exception as e:
            pass
        finally:
            self._unloaded = True

    def __del__(self):
        self.unload()


class CudaDialectJitCompiledFunction(JitCompiledFunction):
    """Holds a compiled function and its module."""

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
    ):
        self.ir_module = ir_module
        self.engine = engine
        self.capi_func = capi_func
        self.function_name = function_name
        self.kernel_info = kernel_info
        if args_spec is not None:
            self.args_spec = ExecutionArgs(args_spec, self.function_name)
        self.jit_time_profiling = jit_time_profiling
        self.prefix = prefix
        assert (
            isinstance(jit_function_artifacts, JitFunctionArtifacts)
            or jit_function_artifacts is None
        )
        self.artifacts = jit_function_artifacts
        self.load_from_binary = load_from_binary

        # Set cuda result return type.
        # When execution engine/capi function is None, do not set the return type.
        if self.capi_func:
            self.capi_func.restype = ctypes.c_int32
        if self.args_spec:
            self.args_spec.args_spec.annotations["return"] = Int32

        # This runtime state is stored here so that we can preserve the module
        # in the compiler cache. Callers can extend the lifetime of the module
        # by creating and retaining the executor.
        self.jit_module = None
        self._executor_lock = threading.RLock()
        self._default_executor = None

    @functools.cached_property
    def num_devices(self):
        """Returns the number of CUDA devices available."""
        dev_err, devs = cuda_runtime.cudaGetDeviceCount()
        if dev_err != cuda_runtime.cudaError_t.cudaSuccess:
            raise DSLCudaRuntimeError(dev_err, cuda_runtime.cudaGetErrorName(dev_err))
        return devs

    def _deserializer(self):
        """Load the cuda library from the binary execution engine.
        @return: The list of cuda kernels.
        """
        library = ctypes.c_void_p()
        pointer_to_library = ctypes.pointer(library)
        pointer_to_pointer_to_library = ctypes.pointer(pointer_to_library)
        err = ctypes.c_int32(0)
        pointer_to_err = ctypes.pointer(err)

        # cuda init takes in a pointer to a cudaLibrary_t and returns
        # a i32 cudaError_t. It initialized (lazy loads) our cudaLibrary_t
        cuda_init = self.engine.lookup(f"_mlir_{self.prefix}_cuda_init")
        if cuda_init is None:
            raise DSLRuntimeError("cuda_init not found")
        cuda_init = ctypes.CFUNCTYPE(None, ctypes.c_void_p)(cuda_init)
        # cuda load takes in a pointer to a cudaLibrary_t and returns
        # a i32 cudaError_t. It loads the functions from the cuda library,
        # sets function attributes, and returns an error if encountered.
        cuda_load = self.engine.lookup(f"_mlir_{self.prefix}_cuda_load")
        if cuda_load is None:
            raise DSLRuntimeError("cuda_load not found")
        cuda_load = ctypes.CFUNCTYPE(None, ctypes.c_void_p)(cuda_load)

        cuda_init_args = [pointer_to_pointer_to_library, pointer_to_err]
        packed_args = (ctypes.c_void_p * len(cuda_init_args))()
        for i in range(len(cuda_init_args)):
            packed_args[i] = ctypes.cast(cuda_init_args[i], ctypes.c_void_p)
        cuda_init(packed_args)

        if err.value != 0:
            error_code = err.value
            error_name = cuda_runtime.cudaGetErrorName(
                cuda_runtime.cudaError_t(error_code)
            )
            raise DSLCudaRuntimeError(error_code, error_name)

        cuda_load_args = [pointer_to_library, pointer_to_err]
        packed_args = (ctypes.c_void_p * len(cuda_load_args))()
        for i in range(len(cuda_load_args)):
            packed_args[i] = ctypes.cast(cuda_load_args[i], ctypes.c_void_p)
        cuda_load(packed_args)

        if err.value != 0:
            error_code = err.value
            error_name = cuda_runtime.cudaGetErrorName(
                cuda_runtime.cudaError_t(error_code)
            )
            raise DSLCudaRuntimeError(error_code, error_name)

        return [cuda_runtime.cudaLibrary_t(library.value)]

    def _get_cuda_init_and_load(self):
        """Returns the cuda init and load functions from the engine."""
        # cuda init takes in a pointer to a cudaLibrary_t and returns
        # a i32 cudaError_t. It initialized (lazy loads) our cudaLibrary_t

        cuda_init = None

        # cuda load for device takes in a pointer to a cudaLibrary_t and a device index and returns
        # a i32 cudaError_t. It resolves each kernel from the cuda library,
        # and applies device scoped attributes for the given device id, and returns an error if encountered.
        cuda_load_to_device = None

        # When load_from_binary is true, the symbols are prefixed by _mlir_<prefix>_ and are looked
        # up from the JIT engine. Otherwise we look for the unprefixed forms. Looking up cuda_init
        # and cuda_load_to_device from the engine which are defined in CudaToLLVM.
        if self.load_from_binary:
            if self.prefix is None:
                raise DSLRuntimeError("prefix is required to be set for binary loading")
            cuda_init = self.engine.lookup(f"_mlir_{self.prefix}_cuda_init")
            if cuda_init is None:
                raise DSLRuntimeError(f"cuda_init not found for prefix {self.prefix}")
            cuda_load_to_device = self.engine.lookup(
                f"_mlir_{self.prefix}_cuda_load_to_device"
            )
            if cuda_load_to_device is None:
                raise DSLRuntimeError(
                    f"cuda_load_to_device not found for prefix {self.prefix}"
                )
        else:
            cuda_init = self.engine.raw_lookup("cuda_init")
            if cuda_init is None:
                raise DSLRuntimeError("cuda_init not found")
            cuda_load_to_device = self.engine.raw_lookup("cuda_load_to_device")
            if cuda_load_to_device is None:
                raise DSLRuntimeError("cuda_load_to_device not found")
        cuda_init = ctypes.CFUNCTYPE(ctypes.c_int32, ctypes.c_void_p)(cuda_init)
        cuda_load_to_device = ctypes.CFUNCTYPE(ctypes.c_int32, ctypes.c_void_p)(
            cuda_load_to_device
        )

        return cuda_init, cuda_load_to_device

    def _load_cuda_library(self):
        """Loads the CUDA library from the engine."""

        cuda_init, cuda_load_to_device = self._get_cuda_init_and_load()

        library = ctypes.c_void_p()
        pointer_to_library = ctypes.pointer(library)
        pointer_to_pointer_to_library = ctypes.pointer(pointer_to_library)
        err = ctypes.c_int32(0)
        pointer_to_err = ctypes.pointer(err)

        cuda_init_args = [pointer_to_pointer_to_library, pointer_to_err]
        packed_args = (ctypes.c_void_p * len(cuda_init_args))()
        for i in range(len(cuda_init_args)):
            packed_args[i] = ctypes.cast(cuda_init_args[i], ctypes.c_void_p)
        cuda_init(packed_args)

        if err.value != 0:
            error_code = err.value
            error_name = cuda_runtime.cudaGetErrorName(
                cuda_runtime.cudaError_t(error_code)
            )
            raise DSLCudaRuntimeError(error_code, error_name)

        device_id = ctypes.c_int32(0)
        pointer_to_device_id = ctypes.pointer(device_id)

        cuda_load_args = [pointer_to_library, pointer_to_device_id, pointer_to_err]
        packed_args = (ctypes.c_void_p * len(cuda_load_args))()
        for i, arg in enumerate(cuda_load_args):
            packed_args[i] = ctypes.cast(arg, ctypes.c_void_p)

        for dev in range(self.num_devices):
            device_id.value = dev
            cuda_load_to_device(packed_args)
            if err.value != 0:
                raise DSLCudaRuntimeError(
                    err.value,
                    cuda_runtime.cudaGetErrorName(cuda_runtime.cudaError_t(err.value)),
                )

        if err.value != 0:
            error_code = err.value
            error_name = cuda_runtime.cudaGetErrorName(
                cuda_runtime.cudaError_t(error_code)
            )
            raise DSLCudaRuntimeError(error_code, error_name)

        return [cuda_runtime.cudaLibrary_t(library.value)]

    def to(self, device=None) -> JitExecutor:
        """Returns an executable function bound to the given device.

        For multi-device execution this method can be called for each device where
        the kernel will run.

        Since CudaJitCompiledFunction uses CUDA libraries, which are context free,
        binding to a device is not necessary and the device is ignored. Device is
        kept in for compatibility with the JitCompiledFunction.

        :param device: Specifies the device for the executor. If None the current device is used.
        :type device: Optional[Union[int, CUdevice]]
        :return: A callable executor function.
        :rtype: JitExecutor
        """
        super()._validate_engine()
        with self._executor_lock:
            # We need to ensure that the modules are loaded if not already
            if self.jit_module is None or self.jit_module.is_unloaded():
                cuda_library = self._load_cuda_library()
                self.jit_module = CudaDialectJitModule(
                    self.engine,
                    self.capi_func,
                    self.args_spec,
                    cuda_library,
                )

            return JitExecutor(self.jit_module, None, self.jit_time_profiling)
