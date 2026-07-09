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

"""Utility functions for tensor creation and type handling."""

from typing import Any, Optional, Type

import cutlass.cute as cute

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
    storage_tensor: Any,
    dtype: Type[Numeric],
    leading_dim: int,
    source_f32_tensor: Optional[Any] = None,
    assumed_align: int = 16,
    mark_dynamic_layout: bool = True,
) -> cute.Tensor:
    """Create cute tensor, handling float8 types that don't support dlpack.

    For float8 types, the storage_tensor should use byte storage (for DLPack compatibility).
    The source_f32_tensor provides the actual float32 values to convert to fp8.

    params storage_tensor: Tensor for DLPack (byte storage for fp8, otherwise the actual dtype)
    params dtype: Target cutlass dtype
    params leading_dim: Leading dimension for dynamic layout
    paramas source_f32_tensor: Float32 source data for fp8 conversion (required for fp8)
    params assumed_align: Assumed alignment for the DLPack tensor
    params mark_dynamic_layout: Whether to mark the resulting tensor layout dynamic
    return: A cute tensor with the appropriate dtype and layout
    """
    import cutlass.torch as cutlass_torch

    fp8_source_tensor: Optional[Any] = None
    if is_fp8_dtype(dtype):
        if source_f32_tensor is None:
            raise ValueError("source_f32_tensor is required for fp8 types")
        fp8_source_tensor = source_f32_tensor
        try:
            import torch

            if storage_tensor.dtype not in {torch.int8, torch.uint8}:
                storage_tensor = storage_tensor.view(dtype=torch.uint8)
        except AttributeError:
            pass

    cute_tensor = from_dlpack(
        storage_tensor, assumed_align=assumed_align, force_tf32=dtype == TFloat32
    )
    # For float8 types, set element_type explicitly since storage is uint8
    if is_fp8_dtype(dtype):
        cute_tensor.element_type = dtype
    if mark_dynamic_layout:
        cute_tensor = cute_tensor.mark_layout_dynamic(leading_dim=leading_dim)
    # For float8 types, convert data from float32 using GPU kernel
    if fp8_source_tensor is not None:
        cute_tensor = cutlass_torch.convert_cute_tensor(
            fp8_source_tensor, cute_tensor, dtype, is_dynamic_layout=True
        )
    return cute_tensor
