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


# Re-export non-callable public symbols straight through.
from cutlass._mlir_helpers.math import *  # noqa: F401

from cutlass._mlir_helpers import math as _base_math

absf = _base_math.abs

# Same public surface as the foundation, plus the ``absf`` alias.
__all__ = [*_base_math.__all__, "absf"]
