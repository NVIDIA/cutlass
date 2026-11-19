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

"""Runtime operand construction for operation profilers."""

from dataclasses import dataclass

import torch

import cutlass

import cutlass.operators as ops
from cutlass.operators.utils.dtype import (
    torch_storage_packing_factor,
    torch_type_from_cutlass_type,
)
from cutlass.profiler.cli import AUTO_INITIALIZATION

# Unsigned integer types are initialized from 0 rather than a signed range.
_UNSIGNED_DTYPES = frozenset(
    {cutlass.Uint8, cutlass.Uint16, cutlass.Uint32, cutlass.Uint64}
)


@dataclass(frozen=True)
class _LowVarianceRange:
    """Half-open integer range ``[min_val, max_val)`` and a scale applied to it."""

    min_val: int
    max_val: int
    global_scale: float


def _low_variance_range(
    dtype: type[cutlass.Numeric],
    out_dtype: type[cutlass.Numeric],
) -> _LowVarianceRange:
    """Derive a low-variance initialization range from an operand/output pair.

    The narrower the operand or output, the narrower the range, so that products
    and their sums stay exactly representable and the reference comparison can
    use tolerances derived from K alone. Keep in sync with
    analysis.reference_tolerances, which assumes this scheme.
    """
    if dtype.is_float:
        # {-2, -1, 0, 1, 2}, halved to {-1, -0.5, 0, 0.5, 1} for narrow types.
        scale = 0.5 if (dtype.width <= 8 or out_dtype.width <= 8) else 1.0
        return _LowVarianceRange(min_val=-2, max_val=3, global_scale=scale)

    if dtype.is_integer:
        if dtype.width <= 8 or out_dtype.width <= 8:
            min_val, max_val = -1, 2
        else:
            min_val, max_val = -2, 3
        if dtype in _UNSIGNED_DTYPES:
            min_val = 0
        return _LowVarianceRange(min_val=min_val, max_val=max_val, global_scale=1.0)

    raise ValueError(f"Unsupported dtype for '{AUTO_INITIALIZATION}': {dtype}")


def _initialize_low_variance(
    shape: tuple[int, ...],
    torch_dtype: torch.dtype,
    device: str,
    value_range: _LowVarianceRange,
) -> torch.Tensor:
    """Fill a tensor with scaled random integers drawn from ``value_range``."""
    values = torch.randint(
        value_range.min_val, value_range.max_val, shape, device=device
    )
    return (value_range.global_scale * values).to(torch_dtype)


def initialize_tensor(
    shape: tuple[int, ...],
    dtype: torch.dtype,
    device: str,
    init_spec: str,
) -> torch.Tensor:
    """Initialize a tensor based on the initialization specification.

    Supported formats:
    - uniform:min,max - uniform distribution in [min, max]
    - normal:mean,std - normal distribution with given mean and std
    - randint:min,max - random integers in [min, max]
    - constant:value - constant value

    The ``"auto"`` spec is not handled here: its range depends on the operand
    and output CUTLASS dtypes, so :func:`tensor_from_dtype` intercepts it.

    :param shape: Tensor shape
    :type shape: tuple[int, ...]
    :param dtype: Target dtype
    :type dtype: torch.dtype
    :param device: Device ('cuda' or 'cpu')
    :type device: str
    :param init_spec: Initialization specification string
    :type init_spec: str

    :return: Initialized tensor
    :rtype: torch.Tensor
    """
    parts = init_spec.split(":", 1)
    if len(parts) != 2:
        raise ValueError(f"Invalid initialization format: {init_spec}")

    init_type, params = parts
    init_type = init_type.lower()

    if init_type == "uniform":
        # uniform:min,max
        min_val, max_val = map(float, params.split(","))
        tensor = torch.rand(shape, dtype=torch.float32, device=device)
        tensor = tensor * (max_val - min_val) + min_val
        output_tensor = tensor.to(dtype)

    elif init_type == "normal":
        # normal:mean,std
        mean, std = map(float, params.split(","))
        tensor = torch.randn(shape, dtype=torch.float32, device=device)
        tensor = tensor * std + mean
        output_tensor = tensor.to(dtype)

    elif init_type == "randint":
        # randint:min,max
        min_val, max_val = map(int, params.split(","))
        output_tensor = torch.randint(
            min_val, max_val + 1, shape, dtype=dtype, device=device
        )

    elif init_type == "constant":
        # constant:value
        value = float(params)
        output_tensor = torch.full(shape, value, dtype=dtype, device=device)

    else:
        raise ValueError(
            f"Unknown initialization type: {init_type}. "
            "Supported: uniform, normal, randint, constant"
        )

    return output_tensor


def _physical_shape(
    logical_shape: tuple[int, ...],
    dtype: type[cutlass.Numeric],
    column_major: bool,
) -> tuple[int, ...]:
    """Convert a logical tensor shape to its PyTorch storage shape."""
    packing = torch_storage_packing_factor(dtype)
    if packing == 1:
        return logical_shape

    contiguous_mode = len(logical_shape) - 2 if column_major else len(logical_shape) - 1
    extent = logical_shape[contiguous_mode]
    if extent % packing != 0:
        raise ValueError(
            f"Logical extent {extent} for {dtype} must be divisible by "
            f"storage packing factor {packing}"
        )
    physical_shape = list(logical_shape)
    physical_shape[contiguous_mode] //= packing
    return tuple(physical_shape)


def _apply_layout(tensor: torch.Tensor, column_major: bool) -> torch.Tensor:
    if not column_major or tensor.dim() < 2:
        return tensor
    return tensor.transpose(-2, -1)


def _storage_shape(
    physical_shape: tuple[int, ...], column_major: bool
) -> tuple[int, ...]:
    if not column_major or len(physical_shape) < 2:
        return physical_shape
    return physical_shape[:-2] + (physical_shape[-1], physical_shape[-2])


def _initialize_fp4_storage(shape: tuple[int, ...], device: str) -> torch.Tensor:
    """Initialize packed FP4 storage with valid pairs of {-1, 0, 1}."""
    patterns = torch.tensor(
        [0x00, 0x02, 0x0A, 0x20, 0x22, 0x2A, 0xA0, 0xA2, 0xAA],
        dtype=torch.uint8,
        device=device,
    )
    indices = torch.randint(0, len(patterns), shape, device=device)
    return patterns[indices].view(torch.float4_e2m1fn_x2)


def tensor_from_dtype(
    logical_shape: tuple[int, ...],
    dtype: type[cutlass.Numeric],
    initialization: str,
    device: str,
    *,
    column_major: bool = False,
    empty: bool = False,
    out_dtype: type[cutlass.Numeric] | None = None,
) -> torch.Tensor:
    """Allocate a compact runtime tensor with the requested logical layout.

    ``out_dtype`` is required when ``initialization`` is ``"auto"``: the
    low-variance range depends on both the operand and the output width.
    """
    physical_shape = _physical_shape(logical_shape, dtype, column_major)
    storage_shape = _storage_shape(physical_shape, column_major)
    torch_dtype = torch_type_from_cutlass_type(dtype)

    if empty:
        tensor = torch.empty(storage_shape, dtype=torch_dtype, device=device)
    elif dtype == cutlass.Float4E2M1FN:
        # Packed FP4 bypasses both paths; its byte patterns already encode
        # pairs drawn from {-1, 0, 1}.
        tensor = _initialize_fp4_storage(storage_shape, device)
    elif initialization == AUTO_INITIALIZATION:
        if out_dtype is None:
            raise ValueError(
                f"'{AUTO_INITIALIZATION}' initialization requires out_dtype"
            )
        tensor = _initialize_low_variance(
            storage_shape, torch_dtype, device, _low_variance_range(dtype, out_dtype)
        )
    else:
        tensor = initialize_tensor(storage_shape, torch_dtype, device, initialization)
    return _apply_layout(tensor, column_major)


def runtime_operand_nbytes(operand: ops.Operand) -> int:
    """Return the bytes owned by a runtime dense or scaled operand."""
    if isinstance(operand, ops.DenseTensor):
        tensor = operand.tensor.runtime_tensor
        if not isinstance(tensor, torch.Tensor):
            raise TypeError(
                f"Expected a torch.Tensor runtime operand, got {type(tensor)}"
            )
        return tensor.nbytes
    if isinstance(operand, ops.ScaledOperand):
        return runtime_operand_nbytes(operand.quantized) + runtime_operand_nbytes(
            operand.scale
        )
    raise TypeError(f"Unsupported runtime operand type: {type(operand).__name__}")
