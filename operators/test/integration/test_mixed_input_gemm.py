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

"""
Integration tests for Mixed-Input GEMM Operators.

These tests verify the user-facing API for mixed-input GEMM operations where
tensor A uses narrow precision (Int8/Uint8) and tensor B uses wide precision
(BFloat16/Float16).

Exhaustive correctness testing across all Operator variants, tile shapes, and
problem geometries is handled by the implementation tests in
test/implementation/test_gemm_operator.py, which includes MixedInputGemmOperator.

These integration tests focus on:
- Basic end-to-end correctness with a representative configuration
- 2D tensor support
- API behaviors: Operator discovery, argument validation, metadata filtering
- Compile-and-reuse workflow
"""

import logging

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.utils.device import device_or_env_supports

from test_utils import assert_close_with_reference_conversion

torch.manual_seed(2025)
logger = logging.getLogger(__name__)


# =============================================================================
# Basic Correctness Tests (representative configurations only)
# =============================================================================


@pytest.mark.parametrize(
    "M, N, K, L",
    [
        (256, 512, 256, 1),
        (128, 128, 128, 2),
        (256, 256, 512, 1),
    ],
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_mixed_input_gemm(
    M: int,
    N: int,
    K: int,
    L: int,
    fixture_toggle_tvm_ffi,
):
    """
    Test basic mixed-input GEMM with Int8 A and BFloat16 B.
    """
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.int8)
    B = torch.randint(-1, 2, (L, K, N), device="cuda").to(torch.bfloat16)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.bfloat16)

    args = ops.GemmArguments(A=A, B=B, out=D, accumulator_type=torch.float32)
    operators = ops.get_operators(args)

    assert len(operators) > 0
    operator = operators[0]
    logger.debug(f"Picked operator: {operator.metadata.operator_name}")

    assert operator.supports(args)
    operator.run(args)

    reference = A.to(torch.float32) @ B.to(torch.float32)
    assert_close_with_reference_conversion(
        D,
        reference,
        D.dtype,
    )


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_mixed_input_gemm_2d(fixture_toggle_tvm_ffi):
    """
    Test 2D tensors (non-batched case).
    """
    M, N, K = 256, 512, 256
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.int8)
    B = torch.randint(-1, 2, (K, N), device="cuda").to(torch.bfloat16)
    D = torch.empty((M, N), device="cuda", dtype=torch.bfloat16)

    args = ops.GemmArguments(A=A, B=B, out=D, accumulator_type=torch.float32)
    operators = ops.get_operators(args)

    assert len(operators) > 0
    operator = operators[0]
    logger.debug(f"Picked operator: {operator.metadata.operator_name}")

    assert operator.supports(args)
    operator.run(args)

    reference = A.to(torch.float32) @ B.to(torch.float32)
    assert_close_with_reference_conversion(
        D,
        reference,
        D.dtype,
    )


# =============================================================================
# Convert-Scale Mode Tests (Int4)
# =============================================================================
# NOTE: These tests are skipped because PyTorch does not have native Int4 support.
# Testing Int4 requires packed Int4 tensors using CUTLASS utilities (like
# create_i4_tensor_and_scale from mixed_input_host_utils.py) which are not yet
# exposed through the cutlass.operators. To enable these tests:
# 1. Add Int4 tensor creation utilities to cutlass.operators
# 2. Or use cutlass.cute tensor creation with proper packing


@pytest.mark.skip(
    reason="Int4 tensors require CUTLASS packed format not available through PyTorch"
)
def test_mixed_input_gemm_convert_scale_int4():
    """
    Test convert-scale mode with Int4 A tensors.

    Convert-scale mode: out = (type_convert(A) * scale) @ B

    This test is skipped because PyTorch does not support Int4 dtype.
    Int4 tensors must be created using CUTLASS utilities with proper
    2-element packing into 8-bit storage.
    """


# =============================================================================
# Edge Cases and Error Handling
# =============================================================================


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_mixed_input_gemm_no_operators_for_unsupported_cc():
    """
    Test that no operators are returned for unsupported compute capabilities.
    """
    M, N, K, L = 128, 128, 128, 1
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.int8)
    B = torch.randint(-1, 2, (L, K, N), device="cuda").to(torch.bfloat16)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.bfloat16)

    args = ops.GemmArguments(A=A, B=B, out=D, accumulator_type=torch.float32)

    # Request operators for SM80 (not supported for mixed-input)
    operators = ops.get_operators(args, target_sm="80")

    # Mixed-input GEMM is only supported on SM100+
    assert len(operators) == 0, "Expected no operators for SM80"


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_mixed_input_gemm_invalid_accumulator_for_bfloat16():
    """
    Test that operators correctly reject invalid accumulator type for BFloat16 B.
    BFloat16 B requires Float32 accumulator.
    """
    M, N, K, L = 128, 128, 128, 1
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.int8)
    B = torch.randint(-1, 2, (L, K, N), device="cuda").to(torch.bfloat16)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.bfloat16)

    # Try Float16 accumulator with BFloat16 B (invalid)
    args = ops.GemmArguments(A=A, B=B, out=D, accumulator_type=torch.float16)

    # Should return no operators (invalid accumulator for BFloat16)
    operators = ops.get_operators(args)
    assert len(operators) == 0, (
        "Expected no operators for Float16 accumulator with BFloat16 B"
    )


def test_mixed_input_gemm_argument_validation():
    """
    Test argument validation in GemmArguments for mixed-input.
    """
    M, N, K, L = 128, 128, 128, 1
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.int8)
    B = torch.randint(-1, 2, (L, K, N), device="cuda").to(torch.bfloat16)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.bfloat16)

    # Valid arguments should work
    args = ops.GemmArguments(A=A, B=B, out=D, accumulator_type=torch.float32)
    assert args is not None

    # Test shape mismatch - A and B must have matching K dimension
    B_wrong_k = torch.randint(-1, 2, (L, K + 1, N), device="cuda").to(torch.bfloat16)
    with pytest.raises(ValueError, match="K dimension"):
        ops.GemmArguments(A=A, B=B_wrong_k, out=D, accumulator_type=torch.float32)


# =============================================================================
# Operator Selection and Compilation Tests
# =============================================================================


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_mixed_input_gemm_metadata_filter(fixture_toggle_tvm_ffi):
    """
    Test that metadata filter correctly filters operators.
    """
    M, N, K, L = 256, 256, 256, 1
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.int8)
    B = torch.randint(-1, 2, (L, K, N), device="cuda").to(torch.bfloat16)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.bfloat16)

    args = ops.GemmArguments(A=A, B=B, out=D, accumulator_type=torch.float32)

    # Get all matching operators
    all_operators = ops.get_operators(args)

    if len(all_operators) == 0:
        pytest.skip("No operators available")

    # Filter by specific tile shape
    def tile_filter(metadata):
        return metadata.design is not None and metadata.design.tile_shape == (
            128,
            128,
            64,
        )

    filtered_operators = ops.get_operators(args, metadata_filter=tile_filter)

    # Filtered list should be a subset
    assert len(filtered_operators) <= len(all_operators)
