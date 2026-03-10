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

"""
This module provides a NumPy related utility functions that are needed for
the DSL.
"""

import numpy as np
from ..._mlir.extras import types as T

# =============================================================================
# Codegen Utils
# =============================================================================


def _numpy_type_to_mlir_type(dtype):
    if dtype == np.float64:
        return T.f64()
    if dtype == np.float16:
        return T.f16()
    if dtype == np.float32:
        return T.f32()
    if dtype == np.int64:
        return T.i64()
    if dtype == np.int32:
        return T.i32()
    if dtype == np.int16:
        return T.i16()
    if dtype == np.int8:
        return T.i8()
    if dtype == np.uint64:
        return T.ui64()
    if dtype == np.uint32:
        return T.ui32()
    if dtype == np.uint16:
        return T.ui16()
    if dtype == np.uint8:
        return T.ui8()
    if dtype == np.bool_:
        return T.bool()
    if dtype == f8E5M2:
        return T.f8E5M2()
    if dtype == f8E4M3FN:
        return T.f8E4M3FN()
    if dtype == f8E8M0FNU:
        return T.f8E8M0FNU()
    if dtype == f6E3M2FN:
        return T.f6E3M2FN()
    if dtype == f6E2M3FN:
        return T.f6E2M3FN()
    if dtype == f4E2M1FN:
        return T.f4E2M1FN()
    raise TypeError(f"Unknown NumPy dtype for MLIR conversion: {dtype!r}")


def _mlir_type_to_numpy_type(mlir_type):
    if mlir_type == T.f64():
        return np.float64
    if mlir_type == T.f16():
        return np.float16
    if mlir_type == T.f32():
        return np.float32
    if mlir_type == T.i64():
        return np.int64
    if mlir_type == T.i32():
        return np.int32
    if mlir_type == T.i16():
        return np.int16
    if mlir_type == T.i8():
        return np.int8
    if mlir_type == T.ui64():
        return np.uint64
    if mlir_type == T.ui32():
        return np.uint32
    if mlir_type == T.ui16():
        return np.uint16
    if mlir_type == T.ui8():
        return np.uint8
    if mlir_type == T.bool():
        return np.bool_
    raise TypeError(f"Unknown MLIR type for NumPy conversion: {mlir_type!r}")
