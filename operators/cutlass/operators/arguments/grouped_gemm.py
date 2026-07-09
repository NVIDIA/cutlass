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

from dataclasses import dataclass, field

from cutlass.operators.arguments.base import Operand, RuntimeArguments
from cutlass.operators.arguments.epilogue import EpilogueArguments
from cutlass.operators.arguments.operand import _operand_or_dense
from cutlass.operators.typing import NumericLike, TensorLike


@dataclass
class GroupedGemmArguments(RuntimeArguments):
    """Arguments for a grouped GEMM operation.

    A grouped GEMM performs a series of independent GEMM operations, where each GEMM
    can have different matrix dimensions. The most basic formulation of a grouped GEMM is one that
    takes lists of tensors for each of ``A``, ``B``, and ``out``, and computes the following:

    .. code-block:: python

        for i in range(problems_in_group):
            out[i] = A[i] @ B[i]

    While the abstract formulation uses lists of tensors, in practice, the tensors are often packed
    together contiguously in memory in a single tensor for each of ``A``, ``B``, and ``out``.
    In this case, an ``offsets`` tensor delineates the ending positions of each problem in the group
    within those contiguous tensors.

    Currently-supported variants of a grouped GEMM are:

    Contiguous offset 2D-3D grouped GEMM:
      * ``A`` is a tensor of shape (TotalM, K) or (1, TotalM, K)
      * ``B`` is a tensor of shape (problems_in_group, K, N)
      * ``out`` is a tensor of shape (TotalM, N) or (1, TotalM, N)
      * ``offsets`` is a tensor delineating the ending positions of each problem in the group.

    .. code-block:: python

        start = 0
        for i in range(problems_in_group):
            end = offsets[i]
            out[start:end, :] = A[start:end, :] @ B[i, :, :]
            start = end
    """

    A: Operand
    """Input tensor A"""

    B: Operand
    """Input tensor B"""

    out: Operand
    """Output tensor"""

    accumulator_type: NumericLike
    """Data type of the accumulator"""

    offsets: Operand = field(metadata={"alignment_bytes": 4})
    """Offsets tensor delineating the ending positions of each problem in the group"""

    epilogue: EpilogueArguments | None
    """Optional custom epilogue fusion to be performed after the GEMM"""

    def __init__(
        self,
        A: TensorLike | Operand,
        B: TensorLike | Operand,
        out: TensorLike | Operand,
        accumulator_type: NumericLike,
        offsets: TensorLike | Operand,
        epilogue: EpilogueArguments | None = None,
    ):
        self.A = _operand_or_dense(A).copy()
        self.B = _operand_or_dense(B).copy()
        self.out = _operand_or_dense(out).copy()
        self.accumulator_type = accumulator_type
        self.offsets = _operand_or_dense(offsets).copy()
        self.epilogue = epilogue
        super().__init__()
