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

"""
This module provides CUDA Python helper functions
"""

from typing import List

import cuda.bindings.driver as cuda_driver
import cuda.bindings.runtime as cuda_runtime

# MLIR imports
from .._mlir import ir
from .._mlir.dialects import cuda

# Local module imports
from ..base_dsl.runtime.cuda_handle_adapter import CudaHandleAdapter
from ..base_dsl.runtime.jit_arg_adapters import JitArgAdapterRegistry


@JitArgAdapterRegistry.register_jit_arg_adapter(
    cuda_driver.CUevent, scope=JitArgAdapterRegistry.CUDA_DIALECT_SCOPE
)
class CudaDriverEventAdapter(CudaHandleAdapter):
    """
    Convert a CUDA event to a event representation for JIT arg generation.
    """

    def __get_mlir_types__(self) -> List[ir.Type]:
        return [cuda.EventType.get()]


@JitArgAdapterRegistry.register_jit_arg_adapter(
    cuda_runtime.cudaEvent_t, scope=JitArgAdapterRegistry.CUDA_DIALECT_SCOPE
)
class CudaRuntimeEventAdapter(CudaHandleAdapter):
    """
    Convert a CUDA event to a event representation for JIT arg generation.
    """

    def __get_mlir_types__(self) -> List[ir.Type]:
        return [cuda.EventType.get()]
