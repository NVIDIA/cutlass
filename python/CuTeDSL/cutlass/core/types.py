# SPDX-FileCopyrightText: Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

"""Pythonic wrapper for ``!core.tensor`` MLIR type."""

from __future__ import annotations

from typing import Any, Optional, Tuple, Type, Union

from cutlass.base_dsl.typing import Numeric
from cutlass.cute.core import Swizzle
from cutlass.cute.typing import Layout, Shape

from cutlass._mlir import ir
from cutlass._mlir.dialects.core import BitLayoutTagEnum
from cutlass import AddressSpace
import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.dialects.cute_nvgpu as _cute_nvgpu_ir
from cutlass._mlir._mlir_libs._cutlass_ir._core import TensorType as _CoreTensorType


__all__ = [
    "BitfieldType",
    "TensorElementType",
]


class _BitfieldTypeMeta(type):
    """Exposes ``mlir_type`` on the class."""

    @property
    def mlir_type(cls) -> ir.Type:
        return cls._mlir_type()  # type: ignore[attr-defined]


class BitfieldType(metaclass=_BitfieldTypeMeta):
    """Element type whose values are opaque bit patterns."""

    @classmethod
    def _mlir_type(cls) -> ir.Type:
        raise NotImplementedError(f"{cls.__name__} does not define an MLIR type")


TensorElementType = Union[Type[Numeric], Type[BitfieldType]]


