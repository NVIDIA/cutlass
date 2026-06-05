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

import ctypes
from typing import List, Tuple

import cuda.bindings.driver as cuda_driver

# MLIR imports
from .._mlir import ir
from .._mlir.dialects import cuda

# Local module imports
from ..base_dsl.runtime.jit_arg_adapters import JitArgAdapterRegistry


@JitArgAdapterRegistry.register_jit_arg_adapter(cuda_driver.CUstream)
class CudaDialectStreamAdapter:
    """
    Convert a CUDA stream to a stream representation for JIT arg generation.
    """

    def __init__(self, arg: "cuda_driver.CUstream") -> None:
        self._arg = arg
        self._c_pointer = self._arg.getPtr()

    def __new_from_mlir_values__(self, values: List[ir.Value]) -> ir.Value:
        assert len(values) == 1
        return values[0]

    def __c_pointers__(self) -> List[ctypes.c_void_p]:
        return [self._c_pointer]

    def __get_mlir_types__(self) -> List[ir.Type]:
        return [cuda.StreamType.get()]

    def __cuda_stream__(self) -> Tuple[int, int]:
        # support cuda stream protocol
        return (0, int(self._arg))
