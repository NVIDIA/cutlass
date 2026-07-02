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

"""Torch dtype <-> DSL Numeric type conversion utilities."""

from typing import Type

import torch

from .typing import (
    Numeric,
    Boolean,
    TFloat32,
    Float8E4M3B11FNUZ,
    Float8E4M3FN,
    Float8E5M2,
    Float8E8M0FNU,
    Float4E2M1FN,
    Float4E2M1FNx2,
)


def dtype(ty: Type[Numeric]) -> "torch.dtype":
    """
    Return the corresponding torch.dtype per the given DSL type
    """
    torch_dtype = getattr(torch, ty.__name__.lower(), None)

    torch_type_map = {
        Boolean: torch.bool,
        # TFloat32 is just alias of float32
        TFloat32: torch.float32,
        Float8E5M2: torch.float8_e5m2,
        Float8E4M3FN: torch.float8_e4m3fn,
        Float8E4M3B11FNUZ: torch.float8_e4m3fnuz,
        Float4E2M1FN: torch.float4_e2m1fn_x2,
        Float4E2M1FNx2: torch.float4_e2m1fn_x2,
    }

    # float8_e8m0fnu is introduced in latest version of torch
    if hasattr(torch, "float8_e8m0fnu"):
        torch_type_map[Float8E8M0FNU] = torch.float8_e8m0fnu

    if torch_dtype is None:
        torch_dtype = torch_type_map.get(ty)

    if torch_dtype is None:
        raise TypeError(f"{ty} is not supported by torch")
    return torch_dtype
