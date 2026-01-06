# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

"""
Utilities for CUTLASS API.
"""

from __future__ import annotations

import importlib
from typing import TYPE_CHECKING, Any

import cutlass
import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

from cutlass_api.config import GlobalOptions
from cutlass_api.status import Status

if TYPE_CHECKING:
    import cuda
    import torch


def is_numpy_available() -> bool:
    """Check if numpy is available."""
    return importlib.util.find_spec("numpy") is not None


def is_torch_available() -> bool:
    """Check if torch is available."""
    return importlib.util.find_spec("torch") is not None


def is_numpy_tensor(inp) -> bool:
    """Check if the input is a numpy tensor."""
    if is_numpy_available():
        import numpy as np

        return isinstance(inp, np.ndarray)
    return False


def is_torch_tensor(inp) -> bool:
    """Check if the input is a torch tensor."""
    if is_torch_available():
        import torch

        return isinstance(inp, torch.Tensor)
    return False


def _lazy_import(mod_name: str) -> Any:
    """Internal utility to lazily import a module only when needed."""

    class Lazy:
        def __getattr__(self, name: str) -> Any:
            module = importlib.import_module(mod_name)
            return getattr(module, name)

    return Lazy()


def check_cuda_errors(result: list):
    """
    Checks whether `result` contains a CUDA error raises the error as an exception, if so. Otherwise,
    returns the result contained in the remaining fields of `result`.

    :param result: the results of the `cuda` method, consisting of an error code and any method results
    :type result: list

    :return: non-error-code results from the `results` parameter
    """
    # `result` is of the format : (cudaError_t, result...)
    err = result[0]
    if err.value:
        _lazy_import("cuda.cuda")
        cuda_bindings_runtime = _lazy_import("cuda.bindings.runtime")
        raise RuntimeError(
            f"CUDA error: {cuda_bindings_runtime.cudaGetErrorString(err)[1].decode('utf-8')}"
        )

    if len(result) == 1:
        return None
    elif len(result) == 2:
        return result[1]
    else:
        return result[1:]


def device_cc(device: int = 0) -> int:
    """
    Returns the compute capability of the device with ID `device`.

    :param device: ID of the device to query
    :type device: int

    :return: compute capability of the queried device (e.g., 80 for SM80)
    :rtype: int
    """
    _lazy_import("cuda.cuda")
    cuda_bindings_runtime = _lazy_import("cuda.bindings.runtime")
    deviceProp = check_cuda_errors(
        cuda_bindings_runtime.cudaGetDeviceProperties(device)
    )
    major = str(deviceProp.major)
    minor = str(deviceProp.minor)
    return int(major + minor)


def is_device_cc_supported(supported_ccs: set[int]) -> Status:
    """
    Fetch the device compute capability, and check if it is in supported ccs

    :return: Status indicating success if device CC is in supported_ccs
    :rtype: Status
    """
    try:
        cc = device_cc()
        if cc not in supported_ccs:
            return Status.fail(
                f"Compute capability {cc} is not in supported set {supported_ccs}."
            )
        return Status.success()
    except Exception as e:
        return Status.fail(e)


def cutlass_type_from_torch_type(dtype) -> type[cutlass.Numeric]:
    """
    Convert a torch dtype to a cutlass dtype.

    :param dtype: The torch dtype to convert.

    :return: The cutlass dtype.
    :rtype: type[cutlass.Numeric]
    """
    import torch

    torch_dtype_map = {
        torch.float64: cutlass.Float64,
        torch.float32: cutlass.Float32,
        torch.float16: cutlass.Float16,
        torch.bfloat16: cutlass.BFloat16,
        torch.int32: cutlass.Int32,
        torch.int8: cutlass.Int8,
        torch.uint8: cutlass.Uint8,
        torch.float8_e5m2: cutlass.Float8E5M2,
        torch.float8_e4m3fn: cutlass.Float8E4M3FN,
        torch.float8_e4m3fnuz: cutlass.Float8E4M3B11FNUZ,
    }

    try:
        return torch_dtype_map[dtype]
    except KeyError:
        raise KeyError(f"Unsupported dtype: {dtype}")


def to_cutlass_type(dtype) -> type[cutlass.Numeric]:
    """
    Convert a dtype to a cutlass dtype.

    :param dtype: The dtype to convert (e.g., torch.float32)

    :return: The cutlass dtype.
    :rtype: type[cutlass.Numeric]
    """
    if isinstance(dtype, type) and issubclass(dtype, cutlass.Numeric):
        return dtype

    converters = []
    if is_torch_available():
        converters.append(cutlass_type_from_torch_type)

    # Iterate through the available converters and return the first one that succeeds.
    for converter in converters:
        try:
            return converter(dtype)
        except KeyError:
            continue
    raise KeyError(f"Unsupported dtype: {dtype}")


def to_cuda_stream(
    stream: cuda.bindings.driver.CUstream | torch.cuda.Stream,
    skip_if_ffi: bool = True,
) -> cuda.bindings.driver.CUstream:
    """
    Convert provided stream to a cuda.CUstream.

    :param stream: The stream to convert.
    :type stream: Union[cuda.bindings.driver.CUstream, torch.cuda.Stream]
    :param skip_if_ffi: Skip the conversion if True and if TVM-FFI is enabled in GlobalOptions().
    :type skip_if_ffi: bool

    :return: The converted stream.
    :rtype: cuda.bindings.driver.CUstream
    """
    if skip_if_ffi and GlobalOptions().use_tvm_ffi:
        # TVM-FFI can directly handle streams of various types, including raw int handles
        return stream

    cuda = _lazy_import("cuda.bindings.driver")
    if isinstance(stream, cuda.CUstream):
        return stream
    if is_torch_available():
        import torch

        if isinstance(stream, torch.cuda.Stream):
            return cuda.CUstream(stream.cuda_stream)
    raise ValueError(f"Unsupported stream type: {type(stream)}")


def add_batch_mode(
    tensor: cute.Tensor | torch.Tensor,
) -> cute.Tensor | torch.Tensor:
    """
    Adds a batch mode to the tensor.
    If the tensor is a torch.Tensor and has rank 2,
    it will be unsqueezed along the first dimension.

    :param tensor: The tensor to add batch mode to.
    :type tensor: Union[cute.Tensor, "torch.Tensor"]

    :return: The tensor with batch mode added.
    :rtype: Union[cute.Tensor, "torch.Tensor"]
    """
    if is_torch_tensor(tensor):
        if tensor.dim() == 2:
            return tensor.unsqueeze(0)
        elif tensor.dim() < 2 or tensor.dim() > 3:
            raise ValueError(f"Expected 2-3 dimensions, got {tensor.dim()}")
        return tensor

    return tensor


def permute_batch_mode(
    tensor: cute.Tensor | torch.Tensor,
) -> cute.Tensor | torch.Tensor:
    """
    Permute the batch mode of the tensor.
    If the tensor is a torch.Tensor and has rank 3,
    it will be permuted along the first dimension.

    :param tensor: The tensor to permute.
    :type tensor: Union[cute.Tensor, "torch.Tensor"]

    :return: The tensor with batch mode permuted.
    :rtype: Union[cute.Tensor, "torch.Tensor"]
    """
    if is_torch_tensor(tensor):
        if tensor.dim() != 3:
            raise ValueError(f"Expected 3 dimensions, got {tensor.dim()}")
        return tensor.permute([1, 2, 0])
    else:
        raise ValueError(f"Unsupported type: {type(tensor)}")


def leading_dim(tensor) -> int:
    """
    Get the leading dimension of a tensor. This is the first mode with
    stride of 1 and non-unit shape. If the has a single element, the leading
    dimension is 0. Modes with both stride of 1 and shape of 1 are treated
    as though they have stride of 0.

    :param tensor: The tensor to get the leading dimension of.
    :type tensor: Union[cute.Tensor, "torch.Tensor"]

    :return: The leading dimension of the tensor.
    :rtype: int
    """
    if is_torch_tensor(tensor):
        if tensor.numel() == 1:
            return 0
        updated_stride = [
            s if sz != 1 else 0 for s, sz in zip(tensor.stride(), tensor.shape)
        ]
        return updated_stride.index(1)
    else:
        raise ValueError(f"Unsupported tensor type: {type(tensor)}")


def get_stride_order(stride: tuple[int, ...]) -> tuple[int, ...]:
    """
    Returns the order of the modes of a stride. The returned tuple contains
    indices of modes in `stride`, sorted from outermost to innermost.

    For example, for a stride (1024, 1, 512), the stride order is (0, 2, 1).

    :param stride: The stride of the tensor.
    :type stride: tuple[int, ...]

    :return: The order of the modes of the stride.
    :rtype: tuple[int, ...]
    """
    # The code below performs an == reverse argsort on the stride:
    #   indices = range(len(stride))
    #   Sort indices using comparison between stride[i] and stride[j] when
    #   sorting indices i and j. Sort in descending order.
    # Example: For a stride (1024, 1, 512), the reverse argsort is (0, 2, 1).
    return tuple(sorted(range(len(stride)), key=stride.__getitem__, reverse=True))


def get_stride_rank(stride: tuple[int, ...]) -> tuple[int, ...]:
    """
    Returns the rank of the each mode in the stride of a tensor. For a stride of rank N,
    the mode with the smallest stride will have stride rank 0 and the
    mode with the largest stride will have stride rank N-1.

    For example, for a stride (1024, 1, 512), the stride rank is (2, 0, 1).

    :param stride: The stride of the tensor.
    :type stride: tuple[int, ...]

    :return: The rank of the each mode in the stride of the tensor.
    :rtype: tuple[int, ...]
    """
    # The code below performs an argsort on the stride:
    #   indices = range(len(stride))
    #   Sort indices using comparison between stride[i] and stride[j] when
    #   sorting indices i and j.
    # Example: For a stride (1024, 1, 512), the argsorted is (1, 2, 0).
    argsorted = tuple(sorted(range(len(stride)), key=stride.__getitem__))

    # Set the stride order of each mode to the index of the mode in the
    # argsorted tuple.
    # Example: For a stride (1024, 1, 512), the argsorted is (1, 2, 0),
    # so the stride rank is (2, 0, 1).
    res = [-1] * len(stride)
    for i, idx in enumerate(argsorted):
        res[idx] = i
    return tuple(res)


class TensorWrapper:
    """
    Wrapper class for supporting compilation and execution both with
    and without TVM-FFI.

    When using TVM-FFI, one can pass a framework-level tensor (e.g., torch.Tensor)
    to the JIT function at run time, but not at compile time. At compile time, one
    must use a `_FakeTensor` to specify the tensor.

    When not using TVM-FFI, one passes in a cute.Tensor at both compile and run time.

    This class contains two key members:
    - runtime_tensor: The tensor to use at run time.
    - compile_time_tensor: The tensor to use at compile time.

    Users of this class should access each of these underlying members for execution
    and runtime, respectively. Users of this class do not need to know whether TVM-FFI
    is enabled.
    """

    def __init__(self, tensor: Any):
        if isinstance(tensor, cute.Tensor):
            # Regardless of whether TVM-FFI is enabled, if the tensor passed in is a cute.Tensor,
            # it can be used as the runtime tensor and compile time tensor.
            self.runtime_tensor = tensor
            self.compile_time_tensor = tensor
            self._shape = tensor.shape
            self._stride = tensor.stride
            self._data_ptr = tensor.iterator._pointer
        elif GlobalOptions().use_tvm_ffi:
            # If TVM-FFI is enabled, runtime tensor is set simply as the tensor passed in, but
            # we must make a fake tensor for compilation.
            self.runtime_tensor = tensor
            if is_torch_tensor(self.runtime_tensor):
                dtype = cutlass_type_from_torch_type(self.runtime_tensor.dtype)

                rank = self.runtime_tensor.dim()
                self._stride = self.runtime_tensor.stride()
                stride_order = get_stride_rank(self._stride)
                leading_dim_idx = stride_order.index(0)
                shape = [cute.SymInt() for _ in range(rank)]
                shape[leading_dim_idx] = cute.SymInt(divisibility=16 * 8 // dtype.width)
                self._shape = tuple(self.runtime_tensor.shape)
                self._data_ptr = self.runtime_tensor.data_ptr()
            else:
                raise ValueError(
                    f"Unsupported tensor type: {type(self.runtime_tensor)}"
                )

            self.compile_time_tensor = cute.runtime.make_fake_compact_tensor(
                dtype,
                shape,
                stride_order=stride_order,
                assumed_align=16,  # bytes
            )
        else:
            # TVM-FFI is disabled and the tensor passed in is not a cute.Tensor,
            # We must convert it to a cute.Tensor
            if is_torch_tensor(tensor):
                dtype = to_cutlass_type(tensor.dtype)
                stride = tensor.stride()
            else:
                raise ValueError(f"Unsupported tensor type: {type(tensor)}")
            stride_order = get_stride_order(stride)
            self.runtime_tensor = (
                from_dlpack(
                    tensor,
                    assumed_align=16,  # bytes
                )
                .mark_layout_dynamic(leading_dim(tensor))
                .mark_compact_shape_dynamic(
                    mode=leading_dim(tensor),
                    divisibility=16 * 8 // dtype.width,
                    stride_order=stride_order,
                )
            )

            self._shape = self.runtime_tensor.shape
            self._stride = self.runtime_tensor.stride
            self._data_ptr = self.runtime_tensor.iterator._pointer

            # Since the runtime tensor is now a cute.Tensor, we can use it at
            # compile time as well
            self.compile_time_tensor = self.runtime_tensor

    @property
    def element_type(self) -> type[cutlass.Numeric]:
        return self.compile_time_tensor.element_type

    @property
    def shape(self) -> tuple[int, ...]:
        return self._shape

    @property
    def stride(self) -> tuple[int, ...]:
        return self._stride

    @property
    def data_ptr(self) -> int:
        return self._data_ptr


def strides_to_layout_string(*strides: list[tuple[int, ...]]) -> str:
    """
    Convert list[stride tuples] to layout string ('t' for row-major, 'n' for col-major).
    Example: ((0, 1, 0), (0, 0, 1), (0, 0, 1)) -> "ntt"
    """
    row_major_stride = (0, 0, 1)
    col_major_stride = (0, 1, 0)

    layout_string_map = {
        row_major_stride: "t",
        col_major_stride: "n",
    }

    return "".join(layout_string_map[s] for s in strides)


def tuple_to_string(tuple: tuple[int, ...]) -> str:
    """
    Convert a tuple of integers to an 'x'-separated string (e.g., (2, 3, 4) -> '2x3x4').
    """
    return "x".join(str(x) for x in tuple) if len(tuple) > 1 else str(tuple[0])
