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

"""Typed problem descriptions produced by operation profilers."""

from dataclasses import dataclass
from typing import Literal

import cutlass

import cutlass.operators as ops


@dataclass(frozen=True)
class GemmProblemDesc:
    """GEMM-specific problem shape and operand descriptions."""

    M: int
    N: int
    K: int
    L: int
    a_dtype: type[cutlass.Numeric]
    b_dtype: type[cutlass.Numeric]
    out_dtype: type[cutlass.Numeric]
    layout: str = "ttt"
    ab_scale_dtype: type[cutlass.Numeric] | None = None
    ab_scale_mode: ops.ScaleMode | None = None
    ab_scale_swizzle: ops.ScaleSwizzleMode | None = None


@dataclass(frozen=True)
class GroupedGemmProblemDesc:
    """Contiguous-offset grouped-GEMM shape and operand descriptions."""

    M: int
    N: int
    K: int
    offsets: tuple[int, ...]
    offsets_along: Literal["m", "n", "k"]
    a_dtype: type[cutlass.Numeric]
    b_dtype: type[cutlass.Numeric]
    out_dtype: type[cutlass.Numeric]
    layout: str = "ttt"


ProblemDesc = GemmProblemDesc | GroupedGemmProblemDesc
"""Problem description accepted by the built-in operation profilers."""
