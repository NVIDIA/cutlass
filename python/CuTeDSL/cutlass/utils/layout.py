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
from typing import Any


# Enum members compare by object identity, so the canonical class itself must
# be handed out rather than a deprecated subclass copy. A module-level
# __getattr__ (PEP 562) adds the deprecation warning a wrapper class cannot.
def __getattr__(name: str) -> Any:
    if name == "LayoutEnum":
        warnings.warn(
            "cutlass.utils.layout.LayoutEnum is deprecated; use "
            "cutlass.tensor_utils.LayoutEnum instead. It will be removed in a "
            "future release.",
            DeprecationWarning,
            stacklevel=2,
        )
        from cutlass.tensor_utils.layout import LayoutEnum

        return LayoutEnum
    raise AttributeError(f"module {__name__!r} has no attribute {name!r}")


__all__ = [
    "LayoutEnum",  # noqa: F822  # provided by module __getattr__
]
