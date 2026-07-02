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

from typing import TYPE_CHECKING

from cutlass.cute.typing import (
    BFloat16,
    Boolean,
    Float4E2M1FN,
    Float8E4M3B11FNUZ,
    Float8E4M3FN,
    Float8E5M2,
    Float8E8M0FNU,
    Float16,
    Float32,
    Float64,
    Int8,
    Int16,
    Int32,
    Int64,
    Numeric,
    Uint8,
    Uint16,
    Uint64,
    Float4E2M1FN,
)

import cutlass.operators.utils.common as common

if TYPE_CHECKING:
    import jax.numpy as jnp
    import torch


def get_torch_to_cutlass_dtype_map() -> dict[torch.dtype, type[Numeric]]:
    """Return the mapping from torch dtypes to their CUTLASS ``Numeric`` types."""
    import torch

    torch_dtype_map = {
        torch.float64: Float64,
        torch.float32: Float32,
        torch.float16: Float16,
        torch.bfloat16: BFloat16,
        torch.int64: Int64,
        torch.int32: Int32,
        torch.int16: Int16,
        torch.int8: Int8,
        torch.uint8: Uint8,
        torch.uint16: Uint16,
        torch.uint64: Uint64,
        torch.bool: Boolean,
        torch.float8_e5m2: Float8E5M2,
        torch.float8_e4m3fn: Float8E4M3FN,
        torch.float8_e4m3fnuz: Float8E4M3B11FNUZ,
        torch.float8_e8m0fnu: Float8E8M0FNU,
        # NB: float4_e2m1fn_x2 packs 2 FP4 values per byte, so torch shapes
        # are physical (K/2).  TensorWrapper converts to logical shapes/strides
        # automatically; all operator-level code should go through TensorWrapper.
        torch.float4_e2m1fn_x2: Float4E2M1FN,
    }
    return torch_dtype_map


def cutlass_type_from_torch_type(dtype) -> type[Numeric]:
    """Convert a torch dtype to a cutlass dtype.

    Args:
        dtype (torch.dtype): The torch dtype to convert.

    Returns:
        The cutlass dtype.

    Raises:
        KeyError: If the dtype is not supported.
    """
    torch_dtype_map = get_torch_to_cutlass_dtype_map()
    try:
        return torch_dtype_map[dtype]
    except KeyError as err:
        raise KeyError(f"Unsupported dtype: {dtype}") from err


def torch_type_from_cutlass_type(dtype) -> torch.dtype:
    """Convert a cutlass dtype to a torch dtype."""
    torch_dtype_map = {
        value: key for key, value in get_torch_to_cutlass_dtype_map().items()
    }
    try:
        return torch_dtype_map[dtype]
    except KeyError as err:
        raise KeyError(f"Unsupported dtype: {dtype}") from err


def get_jax_to_cutlass_dtype_map() -> dict[jnp.dtype, type[Numeric]]:
    """Create a map between jax dtype and cutlass dtype."""
    import jax.numpy as jnp

    # jax tensor.dtype returns numpy.dtype instances, so use jnp.dtype() as keys
    jax_dtype_map = {
        jnp.dtype("float64"): Float64,
        jnp.dtype("float32"): Float32,
        jnp.dtype("float16"): Float16,
        jnp.dtype("bfloat16"): BFloat16,
        jnp.dtype("int64"): Int64,
        jnp.dtype("int32"): Int32,
        jnp.dtype("int16"): Int16,
        jnp.dtype("int8"): Int8,
        jnp.dtype("uint8"): Uint8,
        jnp.dtype("uint16"): Uint16,
        jnp.dtype("uint64"): Uint64,
        jnp.dtype("bool"): Boolean,
        jnp.float8_e5m2.dtype: Float8E5M2,
        jnp.float8_e4m3fn.dtype: Float8E4M3FN,
        jnp.float8_e8m0fnu.dtype: Float8E8M0FNU,
    }
    return jax_dtype_map


def cutlass_type_from_jax_type(dtype) -> type[Numeric]:
    """Convert a jax dtype to a cutlass dtype."""
    jax_dtype_map = get_jax_to_cutlass_dtype_map()
    try:
        return jax_dtype_map[dtype]
    except KeyError as err:
        raise KeyError(f"Unsupported dtype: {dtype}") from err


def jax_type_from_cutlass_type(dtype) -> jnp.dtype:
    """Convert a cutlass dtype to a jax dtype."""
    jax_dtype_map = {
        value: key for key, value in get_jax_to_cutlass_dtype_map().items()
    }
    try:
        return jax_dtype_map[dtype]
    except KeyError as err:
        raise KeyError(f"Unsupported dtype: {dtype}") from err


def torch_storage_packing_factor(dtype: type[Numeric]) -> int:
    """Return the number of logical elements per PyTorch storage element.

    For most types this is 1. For subbyte types like Float4E2M1FN, PyTorch
    uses a packed representation (``float4_e2m1fn_x2``) that stores 2 logical
    elements per byte, so this returns 2.

    Args:
        dtype: A CUTLASS numeric type.

    Returns:
        int: The packing factor (logical elements per stored element).
    """
    import torch

    torch_dtype = torch_type_from_cutlass_type(dtype)
    torch_bits = torch_dtype.itemsize * 8
    return torch_bits // dtype.width


def to_cutlass_type(dtype) -> type[Numeric]:
    """Convert a dtype to a cutlass dtype.

    Args:
        dtype (torch.dtype | jnp.dtype | np.dtype): The dtype to convert

    Returns:
        The cutlass dtype.

    Raises:
        KeyError: If the dtype is not supported.
    """
    if isinstance(dtype, type) and issubclass(dtype, Numeric):
        return dtype

    converters = []
    if common.is_torch_available():
        converters.append(cutlass_type_from_torch_type)
    if common.is_jax_available():
        converters.append(cutlass_type_from_jax_type)

    # Iterate through the available converters and return the first one that succeeds.
    for converter in converters:
        try:
            return converter(dtype)
        except KeyError:  # noqa: PERF203
            continue
    raise KeyError(f"Unsupported dtype: {dtype}")
