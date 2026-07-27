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

"""Utilities for assisting with operator metadata generation."""

from __future__ import annotations

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from cutlass.cute.typing import Numeric

    from cutlass.operators.metadata.operands.gemm import GemmOperandsMetadata


def construct_dense_gemm_operands(
    a_dtype: Numeric,
    b_dtype: Numeric,
    out_dtype: Numeric,
    acc_dtype: Numeric,
    stride_A: tuple[int, ...],
    stride_B: tuple[int, ...],
    stride_out: tuple[int, ...],
    alignment_bytes: int,
) -> GemmOperandsMetadata:
    """Constructs a GemmOperandsMetadata object based on the provided data types and strides.

    Each operand is assumed to be a dense tensor.

    :param a_dtype: The data type of the A operand.
    :type a_dtype: cutlass.Numeric
    :param b_dtype: The data type of the B operand.
    :type b_dtype: cutlass.Numeric
    :param out_dtype: The data type of the out operand.
    :type out_dtype: cutlass.Numeric
    :param acc_dtype: The data type of the accumulator operand.
    :type acc_dtype: cutlass.Numeric
    :param stride_A: The stride of the A operand.
    :type stride_A: tuple[int, ...]
    :param stride_B: The stride of the B operand.
    :type stride_B: tuple[int, ...]
    :param stride_out: The stride of the out operand.
    :type stride_out: tuple[int, ...]
    :param alignment_bytes: The alignment of the operands, in bytes.
    :type alignment_bytes: int

    :return: A GemmOperandsMetadata object.
    :rtype: GemmOperandsMetadata
    """
    import cutlass.operators.metadata as metadata

    a_divisibility = alignment_bytes * 8 // a_dtype.width
    b_divisibility = alignment_bytes * 8 // b_dtype.width
    out_divisibility = alignment_bytes * 8 // out_dtype.width

    return metadata.GemmOperandsMetadata(
        A=metadata.DenseTensorConstraints(
            dtype=a_dtype,
            stride=stride_A,
            divisibility=a_divisibility,
        ),
        B=metadata.DenseTensorConstraints(
            dtype=b_dtype,
            stride=stride_B,
            divisibility=b_divisibility,
        ),
        out=metadata.DenseTensorConstraints(
            dtype=out_dtype,
            stride=stride_out,
            divisibility=out_divisibility,
        ),
        accumulator_type=acc_dtype,
    )


