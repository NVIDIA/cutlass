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

import cuda.bindings.driver as cuda

# MLIR imports
from ..._mlir.dialects import gpu

from .cuda_handle_adapter import CudaHandleAdapter
from .jit_arg_adapters import JitArgAdapterRegistry


@JitArgAdapterRegistry.register_jit_arg_adapter(
    cuda.CUstream, scope=JitArgAdapterRegistry.GPU_DIALECT_SCOPE
)
class StreamAdapter(CudaHandleAdapter):
    """
    Convert a CUDA stream to a stream representation for JIT arg generation.
    """

    def __get_mlir_types__(self) -> list:
        return [gpu.AsyncTokenType.get()]
