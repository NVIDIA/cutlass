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

import warnings

from .enums import Arch as ArchEnum


def __getattr__(name: str) -> object:
    if name == "Arch":
        warnings.warn(
            message="Arch from arch.py is deprecated. Use Arch from enums.py instead.",
            category=DeprecationWarning,
            stacklevel=2,
        )
        return ArchEnum
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")
