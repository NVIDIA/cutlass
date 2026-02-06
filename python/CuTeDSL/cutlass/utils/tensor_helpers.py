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

"""Utility functions for tensor creation and type handling."""

from typing import Type, Optional

# Import only the specific types needed to avoid circular import with cutlass module
from cutlass.cute.typing import Float8E5M2, Float8E4M3FN, TFloat32, Numeric
from cutlass.cute.runtime import from_dlpack


def is_fp8_dtype(dtype: Type[Numeric]) -> bool:
    """Check if dtype is a float8 type that doesn't support dlpack.
    params dtype: The cutlass numeric type to check
    type dtype: Type[cutlass.Numeric]
    return: True if the dtype is Float8E5M2 or Float8E4M3FN, False otherwise
    """
    return dtype in {Float8E5M2, Float8E4M3FN}


def create_cute_tensor_for_fp8(
    storage_tensor,
    dtype: Type[Numeric],
    leading_dim: int,
    source_f32_tensor=None,
):
    """Create cute tensor, handling float8 types that don't support dlpack.

    For float8 types, the storage_tensor should be uint8 (for DLPack compatibility).
    The source_f32_tensor provides the actual float32 values to convert to fp8.

    params storage_tensor: Tensor for DLPack (uint8 for fp8, otherwise the actual dtype)
    params dtype: Target cutlass dtype
    params leading_dim: Leading dimension for dynamic layout
    paramas source_f32_tensor: Float32 source data for fp8 conversion (required for fp8)
    return: A cute tensor with the appropriate dtype and layout
    """
    import cutlass.torch as cutlass_torch

    cute_tensor = from_dlpack(
        storage_tensor, assumed_align=16, force_tf32=dtype == TFloat32
    )
    # For float8 types, set element_type explicitly since storage is uint8
    if is_fp8_dtype(dtype):
        cute_tensor.element_type = dtype
    cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=leading_dim)
    # For float8 types, convert data from float32 using GPU kernel
    if is_fp8_dtype(dtype):
        if source_f32_tensor is None:
            raise ValueError("source_f32_tensor is required for fp8 types")
        cute_tensor = cutlass_torch.convert_cute_tensor(
            source_f32_tensor, cute_tensor, dtype, is_dynamic_layout=True
        )
    return cute_tensor
