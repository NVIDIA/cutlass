#
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Metadata-level checks of the EFC GEMM operators that need no device."""

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc import (
    Sm100PersistentDenseGemmEFCOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm107_static_persistent_efc import (
    Sm107PersistentDenseGemmEFCOperator,
)


def test_rejects_16bit_reduce_destination_with_raw_tensors():
    """Discovery may receive EpilogueArguments directly, with raw torch
    tensors rather than the wrappers GemmArguments adds; the reduce-dtype
    check must read their dtypes and still reject a 16-bit destination."""
    N = 256
    D = torch.empty((N, N), device="cpu", dtype=torch.float32)
    col_max = torch.full((N,), float("-inf"), device="cpu", dtype=torch.bfloat16)

    epi_str = (
        "def epi(accum): D = accum; col_max = max(accum, dim=[0]); return D, col_max"
    )
    epi_args = ops.EpilogueArguments(epi_str, col_max=col_max, D=D)
    # Trace without GemmArguments._convert_epilogue: the tensors stay raw.
    epi_args.trace((N, N), torch.float32)
    operators = Sm100PersistentDenseGemmEFCOperator.generate_operators(
        metadata_filter=lambda metadata: True, epilogue_args=epi_args
    )
    assert operators == []


@pytest.mark.parametrize(
    "ab_dtype, accepted",
    [(torch.float8_e4m3fn, True), (torch.float16, False), (torch.int8, False)],
    ids=["fp8", "f16", "int8"],
)
def test_sm107_efc_requires_fp8_operands(ab_dtype, accepted):
    """Discovery offers the Rubin EFC operator for fp8 A/B only, since it exists
    for the K=64 fp8 MMA; fp8 is the positive control.  The result is filtered
    by class because the Blackwell EFC operator is family-portable to sm107 and
    is offered there for every dtype it supports."""
    M, N, K, L = 256, 256, 128, 1
    A = torch.zeros((L, M, K), device="cpu").to(ab_dtype)
    B = torch.zeros((L, K, N), device="cpu").to(ab_dtype)
    D = torch.empty((L, M, N), device="cpu", dtype=torch.bfloat16)

    epi_args = ops.EpilogueArguments("def epi(accum): D = relu(accum); return D", D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm="107a")
    rubin_efc = [
        op for op in operators if isinstance(op, Sm107PersistentDenseGemmEFCOperator)
    ]
    assert bool(rubin_efc) is accepted
