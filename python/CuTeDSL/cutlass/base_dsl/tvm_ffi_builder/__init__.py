# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Helper tool to build TVM-FFI functions using MLIR."""

from .call_provider import DynamicParamPackCallProvider, NopCallProvider
from .spec import Param, Var
from .tvm_ffi_builder import (
    CallContext,
    CallProvider,
    attach_ffi_func,
    rename_tvm_ffi_function,
)

__all__ = [
    "CallContext",
    "CallProvider",
    "DynamicParamPackCallProvider",
    "NopCallProvider",
    "Param",
    "Var",
    "attach_ffi_func",
    "rename_tvm_ffi_function",
]
