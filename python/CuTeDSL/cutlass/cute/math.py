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

"""CuTeDSL math API — thin re-export from :mod:`cutlass._mlir_helpers.math`.

All math implementations live in the foundation module. This file
curates the CuTeDSL-side public surface (historical transcendentals,
rounding, abs / copysign) and aliases ``abs`` to ``absf`` for backwards
compatibility.

``TensorSSA`` inherits from ``Vector``, so the foundation's Vector
dispatch path handles CuTeDSL tensor values directly — no
CuTeDSL-specific wrapper is needed here. Per-element math ops preserve
a ``TensorSSA``'s CuTe nested shape via the ``_wrap_like`` polymorphic
hook on the Vector base class.
"""

from cutlass._mlir_helpers.math import (
    # Trigonometric
    sin,
    cos,
    tan,
    acos,
    asin,
    atan,
    atan2,
    # Hyperbolic
    sinh,
    cosh,
    tanh,
    acosh,
    asinh,
    atanh,
    # Exponential / logarithmic
    exp,
    exp2,
    expm1,
    log,
    log2,
    log10,
    log1p,
    # Error functions
    erf,
    erfc,
    # Power / root
    pow,
    cbrt,
    sqrt,
    rsqrt,
    # Rounding
    ceil,
    floor,
    round,
    roundeven,
    trunc,
    # Sign
    copysign,
)
from cutlass._mlir_helpers.math import abs as absf  # historical CuTeDSL name

__all__ = [
    # Trigonometric
    "sin",
    "cos",
    "tan",
    "acos",
    "asin",
    "atan",
    "atan2",
    # Hyperbolic
    "sinh",
    "cosh",
    "tanh",
    "acosh",
    "asinh",
    "atanh",
    # Exponential / logarithmic
    "exp",
    "exp2",
    "expm1",
    "log",
    "log2",
    "log10",
    "log1p",
    # Error functions
    "erf",
    "erfc",
    # Power / root
    "pow",
    "cbrt",
    "sqrt",
    "rsqrt",
    # Rounding
    "ceil",
    "floor",
    "round",
    "roundeven",
    "trunc",
    # Abs / sign
    "absf",
    "copysign",
]
