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

"""Shared base for CUDA-handle JIT-arg adapters.

``StreamAdapter`` (this package) and the four CUDA-dialect adapters in
``cutlass_dsl`` (driver/runtime stream, driver/runtime event, library) all wrap
a CUDA handle that exposes ``getPtr()`` into a JIT argument with the same four
protocol methods; they differ only in the registered Python type, the emitted
MLIR type, and (stream adapters only) the ``__cuda_stream__`` protocol. This
base holds the three identical methods and leaves ``__get_mlir_types__`` to the
subclass, since the MLIR type comes from different dialects (``gpu`` here,
``cuda`` in ``cutlass_dsl``).
"""

from typing import Any

from ..._mlir import ir


class CudaHandleAdapter:
    """Base for adapters that wrap a CUDA handle exposing ``getPtr()``.

    Subclasses must override :meth:`__get_mlir_types__` (the MLIR type is
    dialect-specific) and may override :meth:`__cuda_stream__` (streams only).
    """

    def __init__(self, arg: Any) -> None:
        self._arg = arg
        self._c_pointer = self._arg.getPtr()

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> ir.Value:
        assert len(values) == 1
        return values[0]

    def __c_pointers__(self) -> list[Any]:
        return [self._c_pointer]

    def __get_mlir_types__(self) -> list[ir.Type]:
        raise NotImplementedError(
            "CudaHandleAdapter subclasses must override __get_mlir_types__"
        )
