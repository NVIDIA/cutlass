# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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


from __future__ import annotations

from typing import TYPE_CHECKING, Any

if TYPE_CHECKING:
    from typing import Literal

    import cutlass.cute as cute
    from cutlass.cute.typing import Numeric

    from cutlass.operators.typing import TensorLike

import cuda.bindings.driver as cuda_driver

import cutlass.cute as cute
from cutlass.cute.runtime import from_dlpack

import cutlass.operators.utils.common as common
import cutlass.operators.utils.dtype as dtype_utils
from cutlass.operators.config import GlobalOptions


def major_mode(shape: tuple[int, ...], stride: tuple[int, ...]) -> int | None:
    """Get the major mode of a tensor from its shape and stride.

    This is the first mode with stride[mode]==1 and shape[mode]>1.
    If the tensor has a single element, the major mode is the final mode.
    Modes with both stride of 1 and shape of 1 are treated
    as though they have stride of 0.

    :param shape: The shape of the tensor.
    :type shape: tuple[int, ...]
    :param stride: The stride of the tensor.
    :type stride: tuple[int, ...]

    :return: The major mode of the tensor, or None if the tensor has no major mode.
    :rtype: int | None
    """
    if all(s == 1 for s in shape):
        return len(shape) - 1

    if not any(s == 1 for s in stride):
        return None

    updated_stride = [s if sz != 1 else 0 for s, sz in zip(stride, shape)]
    if 1 not in updated_stride:
        return None
    return updated_stride.index(1)


def major_mode_from_tensor(tensor: TensorWrapper) -> int | None:
    """Get the major mode of a tensor.

    See ``major_mode`` for more details.

    :param tensor: The tensor to get the major mode of.
    :type tensor: TensorWrapper

    :return: The major mode of the tensor, or None if the tensor has no major mode.
    :rtype: int | None
    """
    return major_mode(tensor.shape, tensor.stride)


def normalized_major_stride(
    shape: tuple[int, ...], stride: tuple[int, ...], prepend_zeros_to_rank: int = None
) -> tuple[int, ...] | None:
    """Get the normalized major stride of a tensor.

    This is a tuple of rank equal to that of stride,
    where the major mode has stride 1 and the other modes have stride 0.

    :param shape: The shape of the tensor.
    :type shape: tuple[int, ...]
    :param stride: The stride of the tensor.
    :type stride: tuple[int, ...]
    :param prepend_zeros_to_rank: If set, prepends zeros to the returned stride until the given rank
    is reached.
    :type prepend_zeros_to_rank: int | None

    :return: The normalized major stride of the tensor, or None if the tensor has no major mode.
    :rtype: tuple[int, ...] | None
    """
    major_mode_idx = major_mode(shape, stride)
    if major_mode_idx is None:
        return None

    extra_zeros = (
        tuple((0,) * max(prepend_zeros_to_rank - len(shape), 0))
        if prepend_zeros_to_rank is not None
        else ()
    )

    return extra_zeros + tuple(
        0 if i != major_mode_idx else 1 for i in range(len(stride))
    )


def get_stride_order(stride: tuple[int, ...]) -> tuple[int, ...]:
    """Return the order of the modes of a stride.

    The returned tuple contains indices of modes in `stride`, sorted from outermost to innermost.

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
    """Returns the rank of the each mode in the stride of a tensor.

    For a stride of rank N, the mode with the smallest stride will
    have stride rank 0 and the mode with the largest stride will have stride rank N-1.

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


def is_torch_tensor(inp) -> bool:
    """Check if the input is a torch tensor."""
    if common.is_torch_available():
        import torch

        return isinstance(inp, torch.Tensor)
    return False


def is_torch_fake_tensor(inp) -> bool:
    """Check if the input is a torch fake tensor."""
    if common.is_torch_available():
        import torch

        return isinstance(inp, torch._subclasses.fake_tensor.FakeTensor)
    return False


def is_numpy_tensor(inp) -> bool:
    """Check if the input is a numpy tensor."""
    if common.is_numpy_available():
        import numpy as np

        return isinstance(inp, np.ndarray)
    return False


def is_jax_array(inp) -> bool:
    """Check if the input is a JAX array."""
    if common.is_jax_available():
        import jax

        return isinstance(inp, jax.Array)
    return False


def _compute_row_major_contiguous_stride(shape: tuple[int, ...]) -> tuple[int, ...]:
    """Compute row-major (C-contiguous) strides from a shape tuple."""
    strides = [1] * len(shape)
    for i in range(len(shape) - 2, -1, -1):
        strides[i] = strides[i + 1] * shape[i + 1]
    return tuple(strides)


def _validate_jax_array(tensor) -> None:
    """Validate that a JAX array is suitable for use with CUTLASS operators.

    Checks that the array is on a single GPU device, is not sharded, and has
    a row-major (C-contiguous) layout.
    """
    import jax

    if tensor.is_deleted():
        raise ValueError("JAX array has been deleted and cannot be used.")

    if hasattr(tensor, "sharding") and not isinstance(
        tensor.sharding, jax.sharding.SingleDeviceSharding
    ):
        raise ValueError(
            f"Sharded JAX arrays are not supported. "
            f"Got sharding type: {type(tensor.sharding).__name__}. "
            f"Please use a single-device array."
        )

    device = tensor.devices().pop()
    if device.platform != "gpu":
        raise ValueError(
            f"JAX array must reside on a GPU device, but got device: {device} "
            f"(platform='{device.platform}'). Move the array to GPU first."
        )

    if not _is_jax_array_c_contiguous(tensor):
        raise ValueError(
            "Only row-major (C-contiguous) JAX arrays are currently supported."
        )


def _is_jax_array_c_contiguous(tensor) -> bool:
    """Check whether a JAX array has C-contiguous (row-major) layout."""
    shape = tensor.shape
    if any(s == 0 for s in shape):
        return True
    expected_size = 1
    for s in shape:
        expected_size *= s
    return tensor.size == expected_size


class TensorWrapper:
    """Wrapper class for supporting compilation and execution both with and without TVM-FFI.

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

    _alignment_bytes: int
    _runtime_tensor: TensorLike
    compile_time_tensor: TensorLike
    _shape: tuple[int, ...]
    _stride: tuple[int, ...]
    _data_ptr: int

    def __init__(self, tensor: Any, alignment_bytes: int = 16):
        self._alignment_bytes = alignment_bytes
        if isinstance(tensor, TensorWrapper):
            # Instead of double-nested TensorWrapper, we grab runtime tensor and flatten
            self._alignment_bytes = tensor._alignment_bytes
            self._runtime_tensor = tensor._runtime_tensor
            self._shape = tensor._shape
            self._stride = tensor._stride
            self._data_ptr = tensor._data_ptr
        elif isinstance(tensor, cute.Tensor):
            # Regardless of whether TVM-FFI is enabled, if the tensor passed in is a cute.Tensor,
            # it can be used as the runtime tensor and compile time tensor.
            self._runtime_tensor = tensor
            self.compile_time_tensor = tensor
            self._shape = tensor.shape
            self._stride = tensor.stride
            self._data_ptr = tensor.iterator._pointer
        elif is_torch_fake_tensor(tensor) or (
            is_torch_tensor(tensor) and GlobalOptions().use_tvm_ffi
        ):
            if is_torch_fake_tensor(tensor):
                self._data_ptr = 0
                self._runtime_tensor = None
            else:
                self._runtime_tensor = tensor
                self._data_ptr = tensor.data_ptr()

            dtype = dtype_utils.cutlass_type_from_torch_type(tensor.dtype)

            # For packed sub-byte torch dtypes (e.g. float4_e2m1fn_x2 which
            # stores 2 FP4 values per byte), convert from physical (packed)
            # shape/stride to logical (unpacked) shape/stride so that
            # TensorWrapper reports the same logical layout as from_dlpack.
            packing = tensor.element_size() * 8 // dtype.width
            if packing > 1:
                phys_shape = tuple(tensor.shape)
                phys_stride = tensor.stride()
                contiguous_dim = phys_stride.index(1)
                self._shape = tuple(
                    s * packing if i == contiguous_dim else s
                    for i, s in enumerate(phys_shape)
                )
                self._stride = tuple(
                    s * packing if i != contiguous_dim else s
                    for i, s in enumerate(phys_stride)
                )
            else:
                self._shape = tuple(tensor.shape)
                self._stride = tensor.stride()
            stride_order = get_stride_rank(tensor.stride())
            major_mode_idx = stride_order.index(0)
            shape = [cute.SymInt() for _ in range(tensor.dim())]
            shape[major_mode_idx] = cute.SymInt(
                divisibility=alignment_bytes * 8 // dtype.width
            )

            self.compile_time_tensor = cute.runtime.make_fake_compact_tensor(
                dtype,
                shape,
                stride_order=stride_order,
                assumed_align=alignment_bytes,
            )

        elif is_jax_array(tensor) and GlobalOptions().use_tvm_ffi:
            _validate_jax_array(tensor)
            self._shape = tuple(int(s) for s in tensor.shape)
            self._stride = _compute_row_major_contiguous_stride(self._shape)
            self._runtime_tensor = tensor
            self._data_ptr = tensor.unsafe_buffer_pointer()

            dtype = dtype_utils.cutlass_type_from_jax_type(tensor.dtype)
            stride_order = get_stride_rank(self._stride)
            major_mode_idx = stride_order.index(0)
            shape = [cute.SymInt() for _ in range(len(self._shape))]
            shape[major_mode_idx] = cute.SymInt(
                divisibility=alignment_bytes * 8 // dtype.width
            )

            self.compile_time_tensor = cute.runtime.make_fake_compact_tensor(
                dtype,
                shape,
                stride_order=stride_order,
                assumed_align=alignment_bytes,
            )

        elif GlobalOptions().use_tvm_ffi:
            raise ValueError(
                "TVM-FFI is currently only supported for torch tensors and JAX arrays."
            )
        else:
            # TVM-FFI is disabled and the tensor passed in is not a cute.Tensor or torch fake tensor,
            # We must convert it to a cute.Tensor
            if is_torch_tensor(tensor):
                dtype = dtype_utils.to_cutlass_type(tensor.dtype)
                shape = tuple(tensor.shape)
                stride = tensor.stride()
            elif is_jax_array(tensor):
                _validate_jax_array(tensor)
                dtype = dtype_utils.to_cutlass_type(tensor.dtype)
                shape = tuple(int(s) for s in tensor.shape)
                stride = _compute_row_major_contiguous_stride(shape)
            else:
                raise ValueError(f"Unsupported tensor type: {type(tensor)}")

            major_mode_idx = major_mode(shape, stride)
            if major_mode_idx is None:
                raise ValueError(f"Tensor has no major mode: {tensor}")
            stride_order = get_stride_order(stride)
            self._runtime_tensor = (
                from_dlpack(
                    tensor,
                    assumed_align=alignment_bytes,
                )
                .mark_layout_dynamic(major_mode_idx)
                .mark_compact_shape_dynamic(
                    mode=major_mode_idx,
                    divisibility=alignment_bytes * 8 // dtype.width,
                    stride_order=stride_order,
                )
            )

            self._shape = self._runtime_tensor.shape
            self._stride = self._runtime_tensor.stride
            self._data_ptr = self._runtime_tensor.iterator._pointer

            # Since the runtime tensor is now a cute.Tensor, we can use it at
            # compile time as well
            self.compile_time_tensor = self._runtime_tensor

    @property
    def runtime_tensor(self):
        if self._runtime_tensor is None:
            raise ValueError(
                "Attempting to access runtime tensor from argument constructed with a fake tensor."
            )
        return self._runtime_tensor

    @property
    def dtype(self) -> type[Numeric]:
        """Return the Cute element type of the tensor."""
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

    def to(
        self,
        dtype: type[Numeric] | None = None,
        device: Literal["cpu", "cuda"] | None = None,
    ) -> TensorLike | None:
        """Copy the tensor to the given dtype and/or device and return a new framework tensor.

        When ``_runtime_tensor`` is a framework tensor (torch / JAX) the copy
        is delegated to the framework.  When it is a ``cute.Tensor`` (non-TVM-FFI
        path), data is copied from GPU memory via ``cuMemcpyDtoH`` /
        ``cuMemcpyDtoD`` into a freshly allocated torch tensor.

        :param dtype: The dtype to convert the tensor to.
        :param device: ``"cpu"`` or ``"cuda"``.
        """
        if self._runtime_tensor is None:
            return None

        if is_torch_tensor(self._runtime_tensor):
            return self._runtime_tensor.to(dtype=dtype, device=device)
        elif is_jax_array(self._runtime_tensor):
            import jax

            new_tensor = self._runtime_tensor
            if dtype is not None:
                new_tensor = new_tensor.astype(dtype)
            if device is not None:
                device_str = "gpu" if device == "cuda" else "cpu"
                jax_device = jax.devices(device_str)[0]
                new_tensor = jax.device_put(new_tensor, jax_device)

            return new_tensor
        elif isinstance(self._runtime_tensor, cute.Tensor):
            device_str = "cuda" if device is None else device
            new_tensor = self._copy_cute_tensor_to_torch(device=device_str)
            if dtype is not None:
                new_tensor = new_tensor.to(dtype=dtype)
            return new_tensor

        return None

    def cuda(self) -> TensorLike | None:
        return self.to(device="cuda")

    def cpu(self) -> TensorLike | None:
        return self.to(device="cpu")

    def _copy_cute_tensor_to_torch(
        self, device: Literal["cpu", "cuda"]
    ) -> TensorLike | None:
        """Copy ``_runtime_tensor`` (a cute.Tensor on GPU) into a new torch tensor.

        Uses ``cuMemcpyDtoH`` for device-to-host and ``cuMemcpyDtoD`` for
        device-to-device copies so that the returned tensor owns its own
        memory and is independent of the runtime tensor.
        """
        import torch

        import cutlass.torch as cutlass_torch

        rt = self._runtime_tensor
        num_bits = self.numel() * rt.element_type.width
        assert num_bits % 8 == 0, (
            "Assumes that tensors are always byte-aligned even for subbyte types"
        )
        num_bytes = num_bits // 8
        torch_dtype = cutlass_torch.dtype(rt.element_type)

        if device == "cpu":
            dest = torch.empty_strided(rt.shape, rt.stride, dtype=torch_dtype)
            (err,) = cuda_driver.cuMemcpyDtoH(dest.data_ptr(), rt.data_ptr, num_bytes)
        elif device == "cuda":
            dest = torch.empty_strided(
                rt.shape, rt.stride, dtype=torch_dtype, device="cuda"
            )
            (err,) = cuda_driver.cuMemcpyDtoD(dest.data_ptr(), rt.data_ptr, num_bytes)

        if err != cuda_driver.CUresult.CUDA_SUCCESS:
            err_name = cuda_driver.cuGetErrorString(err)[1]
            raise RuntimeError(f"CUDA memcpy to {device} failed: {err_name}")
        return dest

    def numel(self) -> int:
        num = self._shape[0]
        for i in range(1, len(self._shape)):
            num *= self._shape[i]
        return num

    def __dlpack__(self, *, stream: Any = None) -> Any:
        """Return a DLPack capsule representing the tensor data."""
        if self._runtime_tensor is None:
            raise ValueError("Attempting to call dlpack with a fake tensor.")
        if not hasattr(self._runtime_tensor, "__dlpack__"):
            raise NotImplementedError(
                f"{type(self._runtime_tensor).__name__} does not support DLPack export."
            )
        return self._runtime_tensor.__dlpack__(stream=stream)

    def __dlpack_device__(self) -> tuple[int, int]:
        """Return the device type and device id as a tuple."""
        if self._runtime_tensor is None:
            raise ValueError("Attempting to call dlpack_device with a fake tensor.")
        if not hasattr(self._runtime_tensor, "__dlpack_device__"):
            raise NotImplementedError(
                f"{type(self._runtime_tensor).__name__} does not support DLPack export."
            )
        return self._runtime_tensor.__dlpack_device__()


def strides_to_layout_string(*strides: list[tuple[int, ...]]) -> str:
    """Convert list[stride tuples] to layout string ('t' for row-major, 'n' for col-major).

    Example:
        >>> strides_to_layout_string((0, 1, 0), (0, 0, 1), (0, 0, 1))
        'ntt'
    """
    row_major_stride_rank3 = (0, 0, 1)
    col_major_stride_rank3 = (0, 1, 0)
    row_major_stride_rank2 = (0, 1)
    col_major_stride_rank2 = (1, 0)

    layout_string_map = {
        row_major_stride_rank3: "t",
        col_major_stride_rank3: "n",
        row_major_stride_rank2: "t",
        col_major_stride_rank2: "n",
    }

    return "".join(layout_string_map[s] for s in strides)
