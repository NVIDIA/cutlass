# Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause

# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:

# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.

# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.

# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.

# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
# FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
# DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
# CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
# OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

from __future__ import annotations

import enum
from enum import auto as enum_auto

# All current Gemm shapes/strides in cutlass.operators are rank 2 or 3.
TupleRank2Or3 = tuple[int, int, int] | tuple[int, int]


def normalized_row_major() -> tuple[int, int, int]:
    """Returns the normalized row major strides for a rank 3 tensor.

    Leading dimension has stride=1. All others are 0.
    Example: shape (L=batch, M=row, K=column) => stride (0, 0, 1)

    Uses definition provided by normalized_major_stride.
    """
    return (0, 0, 1)


def normalized_col_major() -> tuple[int, int, int]:
    """Returns the normalized column major strides for a rank 3 tensor.

    Leading dimension has stride=1. All others are 0.
    Example: shape (L=batch, M=row, K=column) => stride (0, 1, 0)

    Uses definition provided by normalized_major_stride.
    """
    return (0, 1, 0)


class LayoutType(enum.Enum):
    ColumnMajor = enum_auto()
    RowMajor = enum_auto()
    ColumnMajorInterleaved2 = enum_auto()
    RowMajorInterleaved2 = enum_auto()
    ColumnMajorInterleaved32 = enum_auto()
    RowMajorInterleaved32 = enum_auto()
    ColumnMajorInterleaved64 = enum_auto()
    RowMajorInterleaved64 = enum_auto()
    TensorNWC = enum_auto()
    TensorNHWC = enum_auto()
    TensorNDHWC = enum_auto()
    TensorNCHW = enum_auto()
    TensorNGHWC = enum_auto()
    TensorNC32HW32 = enum_auto()
    TensorNC64HW64 = enum_auto()
    TensorC32RSK32 = enum_auto()
    TensorC64RSK64 = enum_auto()
    TensorKCS = enum_auto()
    TensorKCSR = enum_auto()
    TensorKCSRT = enum_auto()
