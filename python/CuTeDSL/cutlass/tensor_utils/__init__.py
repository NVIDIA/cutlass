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

"""Tensor description utilities for kernel authoring: operand layout tags and
TMA tensormap (descriptor) management.
"""

from .layout import LayoutEnum
from .tensormap import TensorMapManager, TensorMapUpdateMode

__all__ = [
    "LayoutEnum",
    "TensorMapManager",
    "TensorMapUpdateMode",
]
