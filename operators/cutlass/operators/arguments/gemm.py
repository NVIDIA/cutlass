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

from dataclasses import dataclass
from typing import NamedTuple

from cutlass.operators.arguments.base import Operand, RuntimeArguments
from cutlass.operators.arguments.epilogue import EpilogueArguments
from cutlass.operators.arguments.operand import _operand_or_dense
from cutlass.operators.typing import NumericLike, TensorLike


def _logical_contraction_extent(operand: Operand, k_axis: int) -> int:
    """Logical K extent of ``operand`` along ``k_axis``.

    ``_validate`` runs before ``TensorWrapper`` conversion, so PyTorch-backed
    operands report physical shapes; sub-byte dtypes (e.g. ``float4_e2m1fn_x2``)
    pack their K dimension, so scale by the storage packing factor. Falls back to
    the physical extent for non-PyTorch operands (cute tensors are already
    logical) and unknown dtypes.
    """
    extent = operand.shape[k_axis]
    try:
        import torch
    except ImportError:
        return extent
    dtype = getattr(operand, "dtype", None)
    if not isinstance(dtype, torch.dtype):
        return extent
    from cutlass.operators.utils.dtype import (
        cutlass_type_from_torch_type,
        torch_storage_packing_factor,
    )

    try:
        return extent * torch_storage_packing_factor(
            cutlass_type_from_torch_type(dtype)
        )
    except KeyError:
        return extent


class GemmProblemSize(NamedTuple):
    """Problem size for a GEMM operation.

    A GEMM with problem size (M, N, K, L) has operands with the following shapes (batch, rows, columns):

    * ``A``: (L, M, K)
    * ``B``: (L, K, N)
    * ``out``: (L, M, N)
    """

    M: int
    """Number of rows in A and out"""
    N: int
    """Number of columns in B and out"""
    K: int
    """Number of columns in A and rows in B"""
    L: int
    """Number of batches of matrix multiplications"""


@dataclass
class GemmArguments(RuntimeArguments):
    """Arguments for a Generalized Matrix Multiplication (GEMM) operation: ``out = A @ B``.

    The tensors must be all rank-3 or all rank-2.
    * ``L``: Number of batches
    * ``M``: Number of rows in A and out
    * ``K``: Number of columns in A and rows in B
    * ``N``: Number of columns in B and out

    For convenience, construction for ``A``, ``B``, and ``out`` that are operands
    to a dense GEMM can be passed in without wrapping them in ``DenseTensor``.

    .. code-block:: python

        GemmArguments(A, B, out, accumulator_type)
        # is equivalent to:
        GemmArguments(DenseTensor(A), DenseTensor(B), DenseTensor(out), accumulator_type)

    Other operand types must explicitly wrap tensors in a ``Operand`` subclass.
    For example, a scaled GEMM can be constructed as:

    .. code-block:: python

        GemmArguments(
            ScaledOperand(A, ScaleATensor, scale_mode, scale_swizzle),
            ScaledOperand(B, ScaleBTensor, scale_mode, scale_swizzle),
            out, # No need to wrap in a `DenseTensor`
            accumulator_type,
        )
    """

    A: Operand
    """Input tensor A of shape (L, M, K) or (M, K)"""

    B: Operand
    """Input tensor B of shape (L, K, N) or (K, N)"""

    out: Operand
    """Output tensor C of shape (L, M, N) or (M, N)"""

    accumulator_type: NumericLike
    """Data type of the accumulator"""

    epilogue: EpilogueArguments | None
    """Optional custom epilogue fusion to be performed after the GEMM"""

    def __init__(
        self,
        A: TensorLike | Operand,
        B: TensorLike | Operand,
        out: TensorLike | Operand,
        accumulator_type: NumericLike,
        epilogue: EpilogueArguments | None = None,
    ):
        self.A = _operand_or_dense(A).copy()
        self.B = _operand_or_dense(B).copy()
        self.out = _operand_or_dense(out).copy()

        self.accumulator_type = accumulator_type
        self.epilogue = epilogue
        super().__init__()

    @property
    def problem_size(self) -> GemmProblemSize:
        """Problem size for a GEMM operation."""
        M = self.A.shape[-2]
        N = self.B.shape[-1]
        K = self.A.shape[-1]
        L = self.A.shape[0] if len(self.A.shape) == 3 else 1

        return GemmProblemSize(M=M, N=N, K=K, L=L)

    def _validate(self):
        """Checks that the arguments are valid."""
        if len(self.A.shape) < 2 or len(self.A.shape) > 3:
            raise ValueError(
                f"A must be a tensor of rank 2 or 3 (L=1, M, K), got {self.A.shape}"
            )
        if len(self.B.shape) < 2 or len(self.B.shape) > 3:
            raise ValueError(
                f"B must be a tensor of rank 2 or 3 (L=1, K, N), got {self.B.shape}"
            )
        if len(self.out.shape) < 2 or len(self.out.shape) > 3:
            raise ValueError(
                f"out must be a tensor of rank 2 or 3 (L=1, M, N), got {self.out.shape}"
            )
        a_k = _logical_contraction_extent(self.A, -1)
        b_k = _logical_contraction_extent(self.B, -2)
        if a_k != b_k:
            raise ValueError(
                f"A's K dimension ({a_k}) must be equal to B's K dimension ({b_k}). A shape (L, M, K): {self.A.shape}, B shape (L, K, N): {self.B.shape}"
            )
        if self.out.shape[-2] != self.A.shape[-2]:
            raise ValueError(
                f"out's M dimension ({self.out.shape[-2]}) must be equal to A's M dimension ({self.A.shape[-2]}). A shape (L, M, K): {self.A.shape}, out shape (L, M, N): {self.out.shape}"
            )
        if self.out.shape[-1] != self.B.shape[-1]:
            raise ValueError(
                f"out's N dimension ({self.out.shape[-1]}) must be equal to B's N dimension ({self.B.shape[-1]}). B shape (L, K, N): {self.B.shape}, out shape (L, M, N): {self.out.shape}"
            )
        if self.A.shape[:-2] != self.B.shape[:-2]:
            raise ValueError(
                f"A & B must have the same rank and batch dimension (if any). A shape (L, M, K): {self.A.shape}, B shape (L, K, N): {self.B.shape}"
            )
        if self.out.shape[:-2] != self.A.shape[:-2]:
            raise ValueError(
                f"out & A must have the same rank and batch dimension (if any). out shape (L, M, N): {self.out.shape}, A shape (L, M, K): {self.A.shape}"
            )

    def _convert_epilogue(self):
        """Converts the epilogue to an internal representation using internal types."""
        if self.epilogue is not None:
            L = self.A.shape[0] if len(self.A.shape) == 3 else 1
            M, N = self.A.shape[-2], self.B.shape[-1]
            accum_shape = (L, M, N)
            self.epilogue.trace(accum_shape, self.accumulator_type)
            self.epilogue.to_tensor_wrappers()

    def __post_init__(self):
        self._validate()
        self._convert_epilogue()
        super().__post_init__()
