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

"""
This module provides jit executor related classes for CUTLASS.
"""

import ctypes
import functools
import inspect
import weakref
import threading
from typing import Any, List, Optional, Tuple, Union

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
from ..base_dsl.common import DSLRuntimeError
from ..base_dsl.typing import Int32
from ..base_dsl.runtime.cuda import checkCudaErrors

from .._mlir import ir, execution_engine


class CudaDialectJitModule:
    """Holds the execution engine and cuda libraries."""

    def __init__(
        self,
        engine: execution_engine.ExecutionEngine,
        capi_func: Any,
        execution_args: ExecutionArgs,
        cuda_library: list["cuda_runtime.cudaLibrary_t"],
    ) -> None:
        self.engine = engine
        self.capi_func = capi_func
        self.execution_args = execution_args
        self.cuda_library = cuda_library
        self._unloaded = False

    def is_unloaded(self) -> bool:
        return self._unloaded

    def unload(self) -> None:
        try:
            for library in self.cuda_library:
                cuda_runtime.cudaLibraryUnload(library)
            self.cuda_library.clear()
        except Exception as e:
            pass
        finally:
            self._unloaded = True

    def __del__(self) -> None:
        self.unload()


class CudaDialectJitCompiledFunction(JitCompiledFunction):
    """Holds a compiled function and its module."""

    def __init__(
        self,
        ir_module: ir.Module,
        engine: Optional[execution_engine.ExecutionEngine],
        capi_func: Any,
        signature: Optional[inspect.Signature],
        function_name: str,
        kernel_info: Optional[dict],
        jit_time_profiling: bool,
        jit_function_artifacts: Optional[JitFunctionArtifacts],
        prefix: Optional[str] = None,
        load_from_binary: bool = False,
        dynamic_args: tuple[Any] = tuple[Any](),
        dynamic_kwargs: dict[str, Any] = dict[str, Any](),
        has_gpu_module: bool = True,
    ) -> None:
        super().__init__(
            ir_module,
            engine,
            capi_func,
            signature,
            function_name,
            kernel_info,
            jit_time_profiling,
            jit_function_artifacts,
            prefix,
            load_from_binary,
            dynamic_args,
            dynamic_kwargs,
            has_gpu_module,
        )

        # Populated from module attributes by CuteExperimentalDSL.compile_and_cache;
        # defaults match pre-pass state and non-experimental CUDA JIT functions.
        self.kernel_extra_args: dict[str, int] = {}
        self.total_added_arguments: int = 0

        # Set cuda result return type.
        # When execution engine/capi function is None, do not set the return type.
        if self.capi_func:
            self.capi_func.restype = ctypes.c_int32
        if self.execution_args:
            self.execution_args.signature = self.execution_args.signature.replace(
                return_annotation=Int32
            )

    @functools.cached_property
    def num_devices(self) -> int:
        """Returns the number of CUDA devices available."""
        return checkCudaErrors(cuda_runtime.cudaGetDeviceCount())

    def _deserializer(self) -> List["cuda_runtime.cudaLibrary_t"]:
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
            packed_args[i] = ctypes.cast(cuda_init_args[i], ctypes.c_void_p)  # type: ignore[arg-type]
        cuda_init(packed_args)

        checkCudaErrors((cuda_runtime.cudaError_t(err.value),))

        cuda_load_args = [pointer_to_library, pointer_to_err]
        packed_args = (ctypes.c_void_p * len(cuda_load_args))()
        for i in range(len(cuda_load_args)):
            packed_args[i] = ctypes.cast(cuda_load_args[i], ctypes.c_void_p)  # type: ignore[arg-type]
        cuda_load(packed_args)

        checkCudaErrors((cuda_runtime.cudaError_t(err.value),))

        return [cuda_runtime.cudaLibrary_t(library.value)]

    def _get_cuda_init_and_load(self) -> Tuple[Any, Any]:
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

    def _load_cuda_library(self) -> List["cuda_runtime.cudaLibrary_t"]:
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
            packed_args[i] = ctypes.cast(cuda_init_args[i], ctypes.c_void_p)  # type: ignore[arg-type]
        cuda_init(packed_args)

        checkCudaErrors((cuda_runtime.cudaError_t(err.value),))

        device_id = ctypes.c_int32(0)
        pointer_to_device_id = ctypes.pointer(device_id)

        cuda_load_args = [
            pointer_to_pointer_to_library,
            pointer_to_device_id,
            pointer_to_err,
        ]
        packed_args = (ctypes.c_void_p * len(cuda_load_args))()
        for i, arg in enumerate(cuda_load_args):
            packed_args[i] = ctypes.cast(arg, ctypes.c_void_p)  # type: ignore[arg-type]

        for dev in range(self.num_devices):
            device_id.value = dev
            cuda_load_to_device(packed_args)
            checkCudaErrors((cuda_runtime.cudaError_t(err.value),))

        checkCudaErrors((cuda_runtime.cudaError_t(err.value),))

        return [cuda_runtime.cudaLibrary_t(library.value)]

    def to(self, device: Optional[int] = None) -> JitExecutor:
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
            if self.jit_module is None or (
                isinstance(self.jit_module, CudaDialectJitModule)
                and self.jit_module.is_unloaded()
            ):
                cuda_library = self._load_cuda_library() if self.has_gpu_module else []
                self.jit_module = CudaDialectJitModule(  # type: ignore[assignment]
                    self.engine,
                    self.capi_func,
                    self.execution_args,
                    cuda_library,
                )

            return JitExecutor(self.jit_module, None, self.jit_time_profiling)
