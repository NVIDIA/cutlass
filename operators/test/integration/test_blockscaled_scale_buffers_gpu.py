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
from cutlass.operators.utils.device import device_or_env_target_sm


@pytest.mark.arch(sms=["100f"])
def test_blockscaled_rejects_noncontiguous_scale(fixture_enable_tvm_ffi):
    m = n = k = 128
    a = torch.ones((1, m, k), device="cuda").to(torch.float8_e4m3fn)
    b = torch.ones((1, n, k), device="cuda").to(torch.float8_e4m3fn).transpose(1, 2)
    out = torch.empty((1, m, n), device="cuda", dtype=torch.float32)
    mode = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
    count = ops.ScaledOperand.numel_scale((1, m, k), mode, swizzle)
    good = torch.ones(count, device="cuda").to(torch.float8_e8m0fnu)
    backing = torch.full((count * 32,), 2.0, device="cuda")
    backing[::32] = 1.0
    noncontiguous = backing.to(torch.float8_e8m0fnu)[::32]
    assert torch.equal(noncontiguous.float(), good.float())

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
            target_sm=device_or_env_target_sm(),
            metadata_filter=lambda metadata: metadata.operator_class
            is PersistentDenseBlockScaledGemmOperator,
        )

    good_args = arguments(good, good)
    operators = find(good_args)
    assert operators
    operator = operators[0]
    operator.run(good_args)
    torch.cuda.synchronize()
    torch.testing.assert_close(out, torch.full_like(out, float(k)))
    for args in (arguments(noncontiguous, good), arguments(good, noncontiguous)):
        assert not operator.supports(args)
        assert not find(args)
