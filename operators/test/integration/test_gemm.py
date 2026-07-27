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


import logging
from pprint import pformat

import pytest
import torch

import cutlass

import cutlass.operators as ops
from cutlass.operators.metadata import (
    Sm100DesignMetadata,
)
from cutlass.operators.utils.device import device_or_env_target_sm

from test_utils import assert_close_with_reference_conversion

torch.manual_seed(2025)
logger = logging.getLogger(__name__)


@pytest.mark.parametrize(
    "M, N, K, L",
    [
        (256, 512, 1024, 1),
        (256, 512, 64, 1),
        (256, 512, 64, 2),
    ],
)
def test_gemm(
    M: int,
    N: int,
    K: int,
    L: int,
    fixture_toggle_tvm_ffi,
):
    device = "cuda"
    ab_dtype = torch.float16
    c_dtype = torch.float16
    accumulator_type = torch.float32
    A = torch.randint(-1, 2, (L, M, K), device=device, dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device=device, dtype=ab_dtype)
    D = torch.empty((L, M, N), device=device, dtype=c_dtype)

    args = ops.GemmArguments(A.cuda(), B.cuda(), D.cuda(), accumulator_type)

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0
    operator = operators[0]
    logger.debug(f"Picked operator: {operator.metadata.operator_name}")
    logger.debug(f"Operator metadata:\n{pformat(operator.metadata)}")
    operator.run(args)

    reference = A.float() @ B.float()
    assert_close_with_reference_conversion(
        D,
        reference,
        D.dtype,
    )


def test_gemm_2d(fixture_toggle_tvm_ffi):
    device = "cuda"
    ab_dtype = torch.float16
    c_dtype = torch.float16
    accumulator_type = torch.float32
    M = 256
    N = 512
    K = 128
    A = torch.randint(-1, 2, (M, K), device=device, dtype=ab_dtype)
    B = torch.randint(-1, 2, (K, N), device=device, dtype=ab_dtype)
    D = torch.empty((M, N), device=device, dtype=c_dtype)

    args = ops.GemmArguments(A.cuda(), B.cuda(), D.cuda(), accumulator_type)

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operator = operators[0]
    logger.debug(f"Picked operator: {operator.metadata.operator_name}")
    logger.debug(f"Operator metadata:\n{pformat(operator.metadata)}")
    operator.run(args)

    reference = A.float() @ B.float()
    assert_close_with_reference_conversion(
        D,
        reference,
        D.dtype,
    )


def test_no_gemms_available():
    M = N = K = 128
    L = 1
    A = torch.empty((L, M, K)).to(torch.float32)
    B = torch.empty((L, K, N)).to(torch.float32)
    D = torch.empty((L, M, N)).to(torch.float32)

    args = ops.GemmArguments(A, B, D, accumulator_type=torch.float32)
    operators = ops.get_operators(args, target_sm="70")

    # There are currently no operators available for compute capability 70.
    assert len(operators) == 0


def test_metadata_filter():
    device = "cuda"
    # Test supplying metadata filter only
    def tile_size_m_filter(metadata: ops.OperatorMetadata) -> bool:
        if not isinstance(metadata.design, Sm100DesignMetadata):
            return False
        return metadata.design.tile_shape[0] == 64

    operators = ops.get_operators(metadata_filter=tile_size_m_filter)
    for operator in operators:
        assert operator.metadata.design.tile_shape[0] == 64, (
            f"Operator {operator.metadata.operator_name} has tile shape "
            f"{operator.metadata.design.tile_shape}"
        )

    # Test supplying metadata filter and arguments
    A = torch.randint(-1, 2, (1, 256, 256), device=device).to(torch.float16)
    B = torch.randint(-1, 2, (1, 256, 256), device=device).to(torch.float16)
    D = torch.empty((1, 256, 256), device=device).to(torch.float16)

    args = ops.GemmArguments(
        A.cuda(), B.cuda(), D.cuda(), accumulator_type=torch.float16
    )
    operators = ops.get_operators(args=args, metadata_filter=tile_size_m_filter)
    for operator in operators:
        assert operator.metadata.design.tile_shape[0] == 64, (
            f"Operator {operator.metadata.operator_name} has tile shape "
            f"{operator.metadata.design.tile_shape}"
        )
        assert operator.metadata.operands.A.dtype == cutlass.Float16
        assert operator.metadata.operands.B.dtype == cutlass.Float16
        assert operator.metadata.operands.out.dtype == cutlass.Float16
        assert operator.metadata.operands.accumulator_type == cutlass.Float16


def test_gemm_fake_tensor(fixture_toggle_tvm_ffi):
    import torch._functorch.config

    torch._functorch.config.fake_tensor_allow_unsafe_data_ptr_access = False

    device = "cuda"
    M, N, K, L = 256, 512, 128, 1
    ab_dtype = torch.float16
    c_dtype = torch.float16
    accumulator_type = torch.float32

    with torch._subclasses.fake_tensor.FakeTensorMode():
        A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
        B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
        D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)

    fake_args = ops.GemmArguments(A, B, D, accumulator_type)

    operators = ops.get_operators(fake_args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operator = operators[0]

    compiled_artifact = operator.compile(fake_args)

    A = torch.randint(-1, 2, (L, M, K), device=device, dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device=device, dtype=ab_dtype)
    D = torch.empty((L, M, N), device=device, dtype=c_dtype)
    args = ops.GemmArguments(A.cuda(), B.cuda(), D.cuda(), accumulator_type)

    operator.run(args, compiled_artifact=compiled_artifact)

    reference = A.float() @ B.float()
    assert_close_with_reference_conversion(
        D,
        reference,
        D.dtype,
    )
