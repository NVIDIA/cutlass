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

"""Unit tests for :mod:`cutlass.operators.arguments`."""

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.providers.cutedsl.gemm.sm100_dense_blockscaled_static_persistent import (
    PersistentDenseBlockScaledGemmOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm107_dense_blockscaled_gemm import (
    Sm107DenseBlockScaledGemmOperator,
)


@pytest.mark.parametrize(
    ("target", "operator_class"),
    [
        ("103a", PersistentDenseBlockScaledGemmOperator),
        ("107a", Sm107DenseBlockScaledGemmOperator),
    ],
)
def test_blockscaled_scale_buffer_validation(
    target, operator_class, fixture_enable_tvm_ffi
):
    m, n, k = 128, 256, 128
    a = torch.empty((1, m, k), dtype=torch.float8_e4m3fn)
    b = torch.empty((1, n, k), dtype=torch.float8_e4m3fn).transpose(1, 2)
    out = torch.empty((1, m, n), dtype=torch.float32)
    mode = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
    count_a = ops.ScaledOperand.numel_scale((1, m, k), mode, swizzle)
    count_b = ops.ScaledOperand.numel_scale((1, n, k), mode, swizzle)
    good_a = torch.empty(count_a, dtype=torch.float8_e8m0fnu)
    good_b = torch.empty(count_b, dtype=torch.float8_e8m0fnu)

    def invalid_buffers(count):
        short = torch.empty(1, dtype=torch.float8_e8m0fnu)
        long = torch.empty(count + 1, dtype=torch.float8_e8m0fnu)
        strided = torch.empty(count * 32, dtype=torch.float8_e8m0fnu)[::32]
        transposed = torch.empty(
            (count // 16, 16), dtype=torch.float8_e8m0fnu
        ).transpose(0, 1)
        return short, long, strided, transposed

    def arguments(sfa, sfb):
        return ops.GemmArguments(
            A=ops.ScaledOperand(a, sfa, mode, swizzle),
            B=ops.ScaledOperand(b, sfb, mode, swizzle),
            out=out,
            accumulator_type=torch.float32,
        )

    def find(args):
        return ops.get_operators(
            args,
            target_sm=target,
            metadata_filter=lambda metadata: metadata.operator_class is operator_class,
        )

    operators = find(arguments(good_a, good_b))
    assert operators
    operator = operators[0]
    assert operator.supports(
        arguments(good_a.view(16, -1), good_b.view(16, -1)), target_sm=target
    )
    singleton = torch.as_strided(good_a, (1, count_a), (count_a * 2, 1))
    assert operator.supports(arguments(singleton, good_b), target_sm=target)
    for invalid in invalid_buffers(count_a):
        assert not operator.supports(arguments(invalid, good_b), target_sm=target)
        assert not find(arguments(invalid, good_b))
    for invalid in invalid_buffers(count_b):
        assert not operator.supports(arguments(good_a, invalid), target_sm=target)
        assert not find(arguments(good_a, invalid))
