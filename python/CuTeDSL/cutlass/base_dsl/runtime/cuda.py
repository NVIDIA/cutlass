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
This module provides CUDA Python helper functions
"""

from functools import lru_cache
from dataclasses import dataclass
from typing import List, Optional
import numpy as np
import os
import ctypes

import cuda.bindings.driver as cuda
import cuda.bindings.nvrtc as nvrtc

# MLIR imports
from ..._mlir import ir
from ..._mlir.dialects import gpu

# Local module imports
from ..utils.logger import log as _log
from ..common import *
from .jit_arg_adapters import JitArgAdapterRegistry


# =============================================================================
# Utils
# =============================================================================


def _cudaGetErrorEnum(error):
    """
    Get the error name of a CUDA error.
    :param error: The CUDA error.
    :type error: cuda.CUresult or nvrtc.nvrtcResult
    :raise DSLRuntimeError: If the error type is unknown.
    :return: The error name.
    :rtype: str
    """
    if isinstance(error, cuda.CUresult):
        err, name = cuda.cuGetErrorName(error)
        return name if err == cuda.CUresult.CUDA_SUCCESS else "<unknown>"
    elif isinstance(error, nvrtc.nvrtcResult):
        return nvrtc.nvrtcGetErrorString(error)[1]
    else:
        raise DSLRuntimeError("Unknown error type: {}".format(error))


def _get_gpu_arch_info(major, minor):
    """
    Get GPU architecture information and compatibility details.
    Return [Unknown, f"sm_{major}{minor}", [f"sm_{major}{minor}"]] if the major and minor version is not in the map.
    :param major: The major version of the CUDA device.
                  usually obtained by calling cuda.cuDeviceGetAttribute(cuda.CUdevice_attribute.CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR, device)
    :type major: int
    :param minor: The minor version of the CUDA device.
                  usually obtained by calling cuda.cuDeviceGetAttribute(cuda.CUdevice_attribute.CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR, device)
    :type minor: int
    :return: The GPU architecture information.
    :rtype: tuple(str, str, list[str])
    """
    gpu_arch_map = {
        (7, 0): ("Volta", "sm_70", ["sm_70"]),  # V100
        (7, 5): ("Turing", "sm_75", ["sm_75"]),  # RTX 20 Series, Quadro RTX
        (8, 0): ("Ampere", "sm_80", ["sm_80"]),  # A100
        (8, 6): ("Ampere", "sm_86", ["sm_86", "sm_80"]),  # RTX 30 Series
        (8, 9): ("Ada", "sm_89", ["sm_89", "sm_86"]),  # RTX 40 Series
        (8, 7): ("Ampere", "sm_87", ["sm_87", "sm_86", "sm_80"]),  # A10, A40
        (9, 0): ("Hopper", "sm_90a", ["sm_90a"]),  # H100
        (10, 0): ("Blackwell", "sm_100a", ["sm_100a"]),  # B200
    }
    return gpu_arch_map.get(
        (major, minor), ("Unknown", f"sm_{major}{minor}", [f"sm_{major}{minor}"])
    )


def get_compute_capability_major_minor(device_id: int = 0):
    """
    Get the compute capability of the CUDA device.
    :param device_id: The ID of the CUDA device.
    :type device_id: int
    :raise DSLRuntimeError: If the CUDA operation fails.
    :return: The compute capability of the CUDA device as a tuple of (major, minor).
    :rtype: tuple(int, int)
    Example: (8, 0) for Ampere, (9, 0) for Hopper, (10, 0) for Blackwell.
    """
    try:
        checkCudaErrors(cuda.cuInit(0))
        device = checkCudaErrors(cuda.cuDeviceGet(device_id))
        major = checkCudaErrors(
            cuda.cuDeviceGetAttribute(
                cuda.CUdevice_attribute.CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR,
                device,
            )
        )
        minor = checkCudaErrors(
            cuda.cuDeviceGetAttribute(
                cuda.CUdevice_attribute.CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR,
                device,
            )
        )
        return major, minor
    except RuntimeError as e:
        _log().info(f"Failed to get CUDA compute capability: {e}")
        return None, None


@dataclass
class DeviceInfo:
    """
    Data class to store CUDA device information.

    :param device_count: The number of CUDA devices.
    :type device_count: int
    :param current_device: The current CUDA device.
    :type current_device: int
    :param device_name: The name of the CUDA device.
    :type device_name: str
    :param major_version: The major version of the CUDA device.
    :type major_version: int
    :param minor_version: The minor version of the CUDA device.
    :type minor_version: int
    :param arch_name: The name of the CUDA architecture.
    :type arch_name: str
    :param sm_arch: The SM architecture of the CUDA device.
    :type sm_arch: str
    :param compatible_archs: The compatible SM architectures of the CUDA device.
    :type compatible_archs: list[str]
    :param memory_gb: The total memory of the CUDA device in GB.
    :type memory_gb: float
    :param target_arch: The target architecture of the CUDA device.
    :type target_arch: str
    :param error_message: The error message of the CUDA device.
    :type error_message: str
    :param initialization_failed: Whether the CUDA initialization failed.
    :type initialization_failed: bool

    """

    device_count: int = 0
    current_device: int = 0
    device_name: Optional[str] = None
    major_version: Optional[int] = None
    minor_version: Optional[int] = None
    arch_name: Optional[str] = None
    sm_arch: Optional[str] = None
    compatible_archs: Optional[List[str]] = None
    memory_gb: Optional[float] = None
    target_arch: Optional[str] = None
    error_message: Optional[str] = None
    initialization_failed: bool = False

    def pretty_str(self) -> str:
        """
        Convert DeviceInfo to a formatted string for display.
        :return: The formatted string.
        :rtype: str
        Example:
        On success:
            CUDA devices available: <device_count> (current: <current_device>)
           - Architecture: <arch_name> (<sm_arch>)
           - Compatible SM archs: <compatible_archs>
           - Total Memory: <memory_gb> GB
        On failure:
            1. CUDA initialization failed
            2. Failed to get GPU info: <error_message>
            3. No devices available
        """
        info = ""

        if self.initialization_failed:
            return f"{Colors.BOLD}- CUDA initialization failed{Colors.RESET}"

        if self.error_message:
            return f"{Colors.BOLD}- Failed to get GPU info: {self.error_message}{Colors.RESET}"

        if self.device_count > 0:
            info += f"{Colors.BOLD}- CUDA devices available: {self.device_count} (current: {self.current_device})\n"

            if self.major_version is not None and self.minor_version is not None:
                info += f"- Architecture: {Colors.BLUE}{self.arch_name}{Colors.RESET} ({Colors.GREEN}{self.sm_arch}{Colors.RESET})\n"
                info += f"- Compatible SM archs: {Colors.GREEN}{', '.join(self.compatible_archs or [])}{Colors.RESET}\n"

                if self.memory_gb is not None:
                    info += f"- Total Memory: {Colors.BLUE}{self.memory_gb:.2f} GB{Colors.RESET}\n"

            else:
                info += f"- Compute capability: unknown\n"
                info += f"- SM arch: unknown{Colors.RESET}\n"
        else:
            info += f"- No devices available\n"

        return info


def get_device_info() -> DeviceInfo:
    """
    Get detailed information about CUDA devices.
    :return: A DeviceInfo dataclass with device information.
    :rtype: DeviceInfo
    """
    device_info = DeviceInfo()

    # Initialize CUDA if not already initialized
    try:
        result = cuda.cuInit(0)
        if result[0].value:  # Check for error
            device_info.initialization_failed = True
            return device_info
    except:
        pass

    try:
        # Get device count
        result = cuda.cuDeviceGetCount()
        device_info.device_count = result[1] if result[0].value == 0 else 0

        if device_info.device_count > 0:
            # Get current device
            try:
                result = cuda.cuCtxGetDevice()
                if result[0].value == 0:
                    device_info.current_device = result[1]
            except:
                pass

            # Get device name
            try:
                name_result = cuda.cuDeviceGetName(100, device_info.current_device)
                if name_result[0].value == 0:
                    device_info.device_name = name_result[1]
            except:
                pass

            # Get compute capability and architecture info
            try:
                major, minor = get_compute_capability_major_minor(
                    device_info.current_device
                )

                # Check if we successfully got the compute capability
                if major is not None and minor is not None:
                    device_info.major_version = major
                    device_info.minor_version = minor

                    arch_name, sm_arch, compatible_archs = _get_gpu_arch_info(
                        device_info.major_version, device_info.minor_version
                    )

                    device_info.arch_name = arch_name
                    device_info.sm_arch = sm_arch
                    device_info.compatible_archs = compatible_archs

                    # Get memory info
                    try:
                        total_mem = cuda.cuDeviceTotalMem(device_info.current_device)
                        if total_mem[0].value == 0:
                            device_info.memory_gb = total_mem[1] / (
                                1024 * 1024 * 1024
                            )  # Convert to GB
                    except:
                        pass

            except Exception as e:
                pass  # Compute capability info will remain None

    except Exception as e:
        device_info.error_message = str(e)

    return device_info


def checkCudaErrors(result):
    """Check CUDA errors and provide detailed error messages.
    :param result: The result of the CUDA operation.
    :type result: tuple(CUresult, ...)
    :raise DSLCudaRuntimeError: If the CUDA operation fails.
    :return: The result of the CUDA operation, excluding the first element(CUresult) of the tuple
    :rtype: tuple()
    """
    if result[0].value:
        error_code = result[0].value
        error_name = _cudaGetErrorEnum(result[0])

        raise DSLCudaRuntimeError(error_code, error_name)

    if len(result) == 1:
        return None
    elif len(result) == 2:
        return result[1]
    else:
        return result[1:]


# =============================================================================
# Driver Helpers
# =============================================================================


def get_current_device():
    """
    Gets the current device on the active context.
    :return: The current device.
    :rtype: cuda.CUdevice
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuCtxGetDevice")
    dev = checkCudaErrors(cuda.cuCtxGetDevice())
    _log().info(f"{dev} <-- cuCtxGetDevice")
    return dev


def get_device(device_id: int):
    """
    Gets a device given its ordinal.
    :param device_id: The ID of the device.
    :type device_id: int
    :return: The device.
    :rtype: cuda.CUdevice
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuDeviceGet {device_id}")
    dev = checkCudaErrors(cuda.cuDeviceGet(device_id))
    _log().info(f"{dev} <-- cuDeviceGet")
    return dev


@lru_cache(maxsize=1)
def initialize_cuda_context(device_id: int = 0, flags: int = 0):
    """
    Initializes the CUDA context for a specified device.
    :param device_id: The ID of the device.
    :type device_id: int
    :param flags: The flags for the CUDA context.
    :type flags: int
    :return: The context.
    :rtype: cuda.CUcontext
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    # Initialize CUDA Driver API
    _log().info(f"cuInit {flags}")
    checkCudaErrors(cuda.cuInit(flags))
    # Retrieve handle for device
    cuDevice = get_device(device_id)
    # Create context
    _log().info(f"cuCtxCreate {0} {cuDevice}")
    if cuda.CUDA_VERSION >= 13000:
        # Use cuCtxCreate_v4 API with explicit CUctxCreateParams None, since v2
        # and v3 API has been removed from CTK 13.
        # See https://github.com/NVIDIA/cuda-python/pull/792
        context = checkCudaErrors(cuda.cuCtxCreate(None, 0, cuDevice))
    else:
        context = checkCudaErrors(cuda.cuCtxCreate(0, cuDevice))
    _log().info(f"{context} <-- cuCtxCreate")

    return context


def device_primary_context_retain(device):
    """
    Retains the primary context on the device.
    :param device: The device.
    :type device: cuda.CUdevice
    :return: The context.
    :rtype: cuda.CUcontext
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuDevicePrimaryCtxRetain {device}")
    return checkCudaErrors(cuda.cuDevicePrimaryCtxRetain(device))


def device_primary_context_release(device):
    """
    Releases the primary context on the device.
    :param device: The device.
    :type device: cuda.CUdevice
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuDevicePrimaryCtxRelease {device}")
    checkCudaErrors(cuda.cuDevicePrimaryCtxRelease(device))


class DevicePrimaryContext:
    """
    Owns a reference to a device primary context and ensures it is released once
    the object is no longer alive.
    """

    def __init__(self, device):
        self.device = device
        self.context = device_primary_context_retain(self.device)

    def __del__(self):
        device_primary_context_release(self.device)


def load_cubin_module(cubin_file):
    """
    Loads a CUBIN file and returns the module.
    :param cubin_file: The path to the CUBIN file.
    :type cubin_file: str
    :return: The module.
    :rtype: cuda.CUmodule
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    # Load CUBIN file as binary data
    _log().info(f"read cubin {cubin_file}")
    with open(cubin_file, "rb") as f:
        cubin_data = f.read()
    # Load module data
    _log().info(f"cuModuleLoadData {np.char.array(cubin_data).ctypes.data}")
    module = checkCudaErrors(
        cuda.cuModuleLoadData(np.char.array(cubin_data).ctypes.data)
    )
    return module


def unload_cubin_module(module):
    """
    Unloads a CUBIN module.
    :param module: The module.
    :type module: cuda.CUmodule
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuModuleUnload {module}")
    checkCudaErrors(cuda.cuModuleUnload(module))


def load_cubin_module_data(cubin_data):
    """
    Loads a CUBIN from data and returns the module.
    :param cubin_data: The binary data of the CUBIN.
    :type cubin_data: bytes
    :return: The module.
    :rtype: cuda.CUmodule
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    # Load module data
    _log().info(f"cuModuleLoadData {np.char.array(cubin_data).ctypes.data}")
    module = checkCudaErrors(
        cuda.cuModuleLoadData(np.char.array(cubin_data).ctypes.data)
    )
    return module


def get_kernel_function(module, kernel_name):
    """
    Retrieves the kernel function from the module.
    :param module: The module.
    :type module: cuda.CUmodule
    :param kernel_name: The name of the kernel.
    :type kernel_name: str
    :return: The kernel function.
    :rtype: cuda.CUfunction
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuModuleGetFunction {module} {kernel_name}")
    kernel = checkCudaErrors(
        cuda.cuModuleGetFunction(module, bytes(kernel_name, "utf-8"))
    )
    _log().info(f"{kernel} <-- cuModuleGetFunction")
    return kernel


def load_library(cubin_file):
    """
    Loads a CUBIN file and returns the library.
    :param cubin_file: The path to the CUBIN file.
    :type cubin_file: str
    :return: The library.
    :rtype: cuda.CUlibrary
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    # Load CUBIN file as binary data
    _log().info(f"read cubin {cubin_file}")
    with open(cubin_file, "rb") as f:
        cubin_data = f.read()
    return load_library_data(cubin_data)


def unload_library(library):
    """
    Unloads a CUBIN library.
    :param library: The library.
    :type library: cuda.CUlibrary
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuLibraryUnload {library}")
    checkCudaErrors(cuda.cuLibraryUnload(library))
    _log().info(f"cuLibraryUnload done {library}")


def load_library_data(cubin_data):
    """
    Loads a CUBIN from data and returns the library.
    :param cubin_data: The binary data of the CUBIN.
    :type cubin_data: bytes
    :return: The library.
    :rtype: cuda.CUlibrary
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    # Load module data
    _log().info(f"cuLibraryLoadData {np.char.array(cubin_data).ctypes.data}")

    library = checkCudaErrors(
        cuda.cuLibraryLoadData(
            np.char.array(cubin_data).ctypes.data, None, None, 0, None, None, 0
        )
    )
    return library


def get_library_kernel(library, kernel_name):
    """
    Retrieves the kernel from the library.
    :param library: The library.
    :type library: cuda.CUlibrary
    :param kernel_name: The name of the kernel.
    :type kernel_name: str
    :return: The kernel.
    :rtype: cuda.CUfunction
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuLibraryGetKernel {library} {kernel_name}")
    kernel = checkCudaErrors(
        cuda.cuLibraryGetKernel(library, bytes(kernel_name, "utf-8"))
    )
    _log().info(f"{kernel} <-- cuLibraryGetKernel")
    return kernel


def get_function_from_kernel(kernel):
    """
    Retrieves the kernel function from the kernel.
    :param kernel: The kernel.
    :type kernel: cuda.CUfunction
    :return: The kernel function.
    :rtype: cuda.CUfunction
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuKernelGetFunction {kernel}")
    kernel_fn = checkCudaErrors(cuda.cuKernelGetFunction(kernel))
    _log().info(f"{kernel_fn} <-- cuKernelGetFunction")

    return kernel_fn


def launch_kernel(kernel, grid_dims, block_dims, stream, smem_size, kernel_args=None):
    """
    Launches the CUDA kernel.
    :param kernel: The kernel.
    :type kernel: cuda.CUfunction
    :param grid_dims: The grid dimensions.
    :type grid_dims: tuple(int, int, int)
    :param block_dims: The block dimensions.
    :type block_dims: tuple(int, int, int)
    :param stream: The stream.
    :type stream: cuda.CUstream
    :param smem_size: The shared memory size.
    :type smem_size: int
    :param kernel_args: The kernel arguments.
    :type kernel_args: tuple
    :raise DSLRuntimeError: If the CUDA operation fails.
    Example:
    ```
    launch_kernel(kernel, (1, 1, 1), (1, 1, 1), stream, 0, (1, 2, 3))
    ```
    """
    _log().info(
        f"cuLaunchKernel {kernel} grid={grid_dims} blocks={block_dims} smem_size={smem_size} stream={stream} {kernel_args}"
    )
    checkCudaErrors(
        cuda.cuLaunchKernel(
            kernel,
            grid_dims[0],
            grid_dims[1],
            grid_dims[2],
            block_dims[0],
            block_dims[1],
            block_dims[2],
            smem_size,  # Shared memory size
            stream,
            kernel_args,
            0,  # Extra parameters
        )
    )


def stream_sync(stream):
    """
    Synchronizes the CUDA stream.
    :param stream: The stream.
    :type stream: cuda.CUstream
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuStreamSynchronize {stream}")
    checkCudaErrors(cuda.cuStreamSynchronize(stream))


def stream_create(id=0):
    """
    Creates the CUDA stream.
    :param id: The ID of the stream.
    :type id: int
    :return: The stream.
    :rtype: cuda.CUstream
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuStreamCreate {id}")
    stream = checkCudaErrors(cuda.cuStreamCreate(id))
    _log().info(f"{stream} <-- cuStreamCreate")
    return stream


def stream_destroy(stream):
    """
    Destroys the CUDA stream.
    :param stream: The stream.
    :type stream: cuda.CUstream
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuStreamDestroy {stream}")
    checkCudaErrors(cuda.cuStreamDestroy(stream))


def context_destroy(context):
    """
    Destroys the CUDA context.
    :param context: The context.
    :type context: cuda.CUcontext
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(f"cuCtxDestroy {context}")
    checkCudaErrors(cuda.cuCtxDestroy(context))


def allocate(size_in_bytes: int, stream=None):
    """
    Allocate device memory based on numpy host array size.
    :param size_in_bytes: The size of the memory to allocate.
    :type size_in_bytes: int
    :param stream: The stream.
    :type stream: cuda.CUstream
    :return: The device memory.
    :rtype: cuda.CUdeviceptr
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info("Allocate size_in_bytes=[%s] stream=[%s]", size_in_bytes, stream)
    if stream is None:
        device_memory = checkCudaErrors(cuda.cuMemAlloc(size_in_bytes))
    else:
        device_memory = checkCudaErrors(cuda.cuMemAllocAsync(size_in_bytes, stream))
    _log().info("Allocated [%s]", device_memory)
    return device_memory


def deallocate(device_pointer, stream=None):
    """
    Deallocate the specified device memory pointer.
    :param device_pointer: The device memory pointer.
    :type device_pointer: cuda.CUdeviceptr
    :param stream: The stream.
    :type stream: cuda.CUstream
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(
        "Deallocate device_pointer=[%s] stream=[%s]", hex(int(device_pointer)), stream
    )
    if stream is None:
        checkCudaErrors(cuda.cuMemFree(device_pointer))
    else:
        checkCudaErrors(cuda.cuMemFreeAsync(device_pointer, stream))


def memcpy_h2d(host_pointer, device_pointer, size_in_bytes, stream=None):
    """
    Copy data from host to device memory
    if stream is None, the copy is synchronous otherwise it is asynchronous.
    :param host_pointer: The host contiguous memory pointer.
    :type host_pointer: cuda.CUdeviceptr
    :param device_pointer: The device memory pointer.
    :type device_pointer: cuda.CUdeviceptr
    :param size_in_bytes: The size of the memory to copy.
    :type size_in_bytes: int
    :param stream: The stream. default to None.
    :type stream: cuda.CUstream
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(
        "Copy host-to-device host_pointer[%s] device_ptr=[%s] size_in_bytes=[%s] stream=[%s]",
        hex(host_pointer),
        hex(int(device_pointer)),
        size_in_bytes,
        stream,
    )
    if stream is None:
        checkCudaErrors(cuda.cuMemcpyHtoD(device_pointer, host_pointer, size_in_bytes))
    else:
        checkCudaErrors(
            cuda.cuMemcpyHtoDAsync(device_pointer, host_pointer, size_in_bytes, stream)
        )


def memcpy_d2h(host_pointer, device_pointer, size_in_bytes, stream=None):
    """
    Copy data from device to host memory
    if stream is None, the copy is synchronous otherwise it is asynchronous.
    :param host_pointer: The host contiguous memory pointer.
    :type host_pointer: cuda.CUdeviceptr
    :param device_pointer: The device memory pointer.
    :type device_pointer: cuda.CUdeviceptr
    :param size_in_bytes: The size of the memory to copy.
    :type size_in_bytes: int
    :param stream: The stream. default to None.
    :type stream: cuda.CUstream
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    _log().info(
        "Copy device-host-to device_pointer=[%s] host_pointer[%s]  size_in_bytes=[%s] stream=[%s]",
        hex(int(device_pointer)),
        hex(host_pointer),
        size_in_bytes,
        stream,
    )
    if stream is None:
        checkCudaErrors(cuda.cuMemcpyDtoH(host_pointer, device_pointer, size_in_bytes))
    else:
        checkCudaErrors(
            cuda.cuMemcpyDtoHAsync(host_pointer, device_pointer, size_in_bytes, stream)
        )


def default_stream():
    """
    Returns the default stream.
    :return: The default stream.
    :rtype: cuda.CUstream
    """
    return cuda.CUstream(0)


@lru_cache(maxsize=1)
def get_driver_version():
    """
    Returns the CUDA driver version.
    Note: the value is cached after the first call.
    :return: The CUDA driver version.
    :rtype: int
    Example:
        version = get_driver_version()
        print(f"CUDA driver version: {version}")
        >>> 12050
    """
    return checkCudaErrors(cuda.cuDriverGetVersion())


def set_kernel_attribute(kernel, attribute, value, device=None):
    """
    Sets a CUDA kernel attribute.
    If the device is not provided, the attribute is set for the current device.
    and cuda.cuFuncSetAttribute is called.
    Otherwise, cuda.cuKernelSetAttribute is called.
    :param kernel: The kernel.
    :type kernel: cuda.CUfunction
    :param attribute: The attribute.
    :type attribute: cuda.CUfunction_attribute
    :param value: The value.
    :type value: int
    :param device: The device.
    :type device: cuda.CUdevice
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    if device is None:
        _log().info(f"cuFuncSetAttribute {kernel} {attribute} {value}")
        return checkCudaErrors(cuda.cuFuncSetAttribute(kernel, attribute, value))
    else:
        _log().info(f"cuKernelSetAttribute {attribute} {value} {kernel} {device}")
        return checkCudaErrors(
            cuda.cuKernelSetAttribute(attribute, value, kernel, device)
        )


def get_device_attribute(attribute, device_id: int = 0):
    """
    Gets a CUDA device attribute.
    :param attribute: The attribute.
    :type attribute: cuda.CUdevice_attribute
    :param device_id: The ID of the device.
    :type device_id: int
    :return: The attribute value.
    :rtype: int
    :raise DSLRuntimeError: If the CUDA operation fails.
    """
    device = checkCudaErrors(cuda.cuDeviceGet(device_id))
    return checkCudaErrors(cuda.cuDeviceGetAttribute(attribute, device))


@JitArgAdapterRegistry.register_jit_arg_adapter(cuda.CUstream)
class StreamAdapter:
    """
    Convert a CUDA stream to a stream representation for JIT arg generation.
    """

    def __init__(self, arg):
        self._arg = arg
        self._c_pointer = self._arg.getPtr()

    def __new_from_mlir_values__(self, values):
        assert len(values) == 1
        return values[0]

    def __c_pointers__(self):
        return [self._c_pointer]

    def __get_mlir_types__(self):
        return [gpu.AsyncTokenType.get()]
