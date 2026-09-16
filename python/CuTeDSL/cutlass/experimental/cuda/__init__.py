# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""CUDA runtime helper and descriptor APIs."""

from .tensor_map import (
    TensorMap,
    TensorMapDataFormat,
    TensorMapFloatOOBFill,
    TensorMapInterleave,
    TensorMapL2Promotion,
    TensorMapSwizzle,
    create_tensor_map_tiled,
    create_tensor_map_tiled_from_view,
)


__all__: list[str] = [
    "TensorMap",
    "TensorMapDataFormat",
    "TensorMapFloatOOBFill",
    "TensorMapInterleave",
    "TensorMapL2Promotion",
    "TensorMapSwizzle",
    "create_tensor_map_tiled",
    "create_tensor_map_tiled_from_view",
]
