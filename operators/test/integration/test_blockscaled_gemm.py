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

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.metadata import Sm100DesignMetadata
from cutlass.operators.providers.cutedsl.gemm.sm100_dense_blockscaled_static_persistent import (
    PersistentDenseBlockScaledGemmOperator,
)
from cutlass.operators.utils.device import device_or_env_target_sm

import test_utils
from test_utils import assert_close_with_reference_conversion
from test_utils.gemm import (
    make_mxfp4_kmajor,
    make_random_pow2_scale,
    scaled_dense_gemm_reference,
)
from test_utils.reference_check import reference_scaled_mm

torch.manual_seed(2025)


@pytest.mark.arch(sms=["100f"])
def test_mxfp8_gemm_sm100_fake_tensor(fixture_enable_tvm_ffi):
    import torch._functorch.config

    torch._functorch.config.fake_tensor_allow_unsafe_data_ptr_access = False

    M, N, K, L = 256, 512, 1024, 1
    ab_dtype = torch.float8_e4m3fn
    c_dtype = torch.float32
    accumulator_type = torch.float32
    scale_dtype = torch.float8_e8m0fnu
    scale = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4

    with torch._subclasses.fake_tensor.FakeTensorMode():
        A = torch.randint(-1, 2, (L, M, K), device="cuda").to(ab_dtype)
        D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)
        B = torch.randint(-1, 2, (L, N, K), device="cuda").to(ab_dtype).transpose(1, 2)
        SFA = torch.rand(
            ops.ScaledOperand.numel_scale((L, M, K), scale, swizzle),
            device="cuda",
        ).to(scale_dtype)
        SFB = torch.rand(
            ops.ScaledOperand.numel_scale((L, N, K), scale, swizzle),
            device="cuda",
        ).to(scale_dtype)

    fake_args = ops.GemmArguments(
        A=ops.ScaledOperand(
            A,
            SFA,
            scale,
            swizzle,
        ),
        B=ops.ScaledOperand(
            B,
            SFB,
            scale,
            swizzle,
        ),
        out=D,
        accumulator_type=accumulator_type,
    )
    operators = ops.get_operators(fake_args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operator = operators[0]
    assert operator.supports(fake_args)
    compiled_artifact = operator.compile(fake_args)

    A_real = torch.randint(-1, 2, (L, M, K), device="cuda").to(ab_dtype)
    B_real = torch.randint(-1, 2, (L, N, K), device="cuda").to(ab_dtype).transpose(1, 2)
    D_real = torch.empty((L, M, N), device="cuda", dtype=c_dtype)
    SFA_real = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale, swizzle),
        device="cuda",
    ).to(scale_dtype)
    SFB_real = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), scale, swizzle),
        device="cuda",
    ).to(scale_dtype)
    args = ops.GemmArguments(
        A=ops.ScaledOperand(
            A_real,
            SFA_real,
            scale,
            swizzle,
        ),
        B=ops.ScaledOperand(
            B_real,
            SFB_real,
            scale,
            swizzle,
        ),
        out=D_real,
        accumulator_type=accumulator_type,
    )
    operator.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    # torch._scaled_mm does not support f8e5m2 * f8e5m2 currently.
    # Simply skip reference check in that case (but test that a CUTLASS Operator
    # is found and runs)
    if ab_dtype != torch.float8_e5m2:
        reference = reference_scaled_mm(A_real, B_real, SFA_real, SFB_real, c_dtype)
        assert_close_with_reference_conversion(D_real, reference, D_real.dtype)


@pytest.mark.parametrize(
    "M, N, K",
    [
        (256, 512, 1024),
        (1024, 640, 512),
    ],
)
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, accumulator_type, scale_dtype",
    [
        (torch.float8_e4m3fn, torch.float32, torch.float32, torch.float8_e8m0fnu),
    ],
)
@pytest.mark.arch(sms=["100f"])
def test_mxfp8_gemm_sm100_2d(
    M: int,
    N: int,
    K: int,
    ab_dtype: torch.dtype,
    c_dtype: torch.dtype,
    accumulator_type: torch.dtype,
    scale_dtype: torch.dtype,
    fixture_enable_tvm_ffi,
):
    """
    Tests valid MXFP8 GEMM cases in which A, B, and out are 2D tensors.
    """
    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (M, K), device="cuda").to(ab_dtype)
    D = torch.empty((M, N), device="cuda", dtype=c_dtype)

    # Transpose B because torch._scaled_mm expects B to be column-major
    B = torch.randint(-1, 2, (N, K), device="cuda").to(ab_dtype).transpose(0, 1)

    scale = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4

    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((M, K), scale, swizzle),
        device="cuda",
    ).to(scale_dtype)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale((N, K), scale, swizzle),
        device="cuda",
    ).to(scale_dtype)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(
            A,
            SFA,
            scale,
            swizzle,
        ),
        B=ops.ScaledOperand(
            B,
            SFB,
            scale,
            swizzle,
        ),
        out=D,
        accumulator_type=accumulator_type,
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operator = operators[0]
    assert operator.supports(args)
    compiled_artifact = operator.compile(args)
    operator.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    reference = reference_scaled_mm(A, B, SFA, SFB, c_dtype)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.arch(sms=["100f"])
@pytest.mark.parametrize(
    "M, N, K",
    [
        (256, 512, 256),
        (1024, 640, 512),
    ],
)
@pytest.mark.parametrize(
    "a_dtype, b_dtype",
    [
        (torch.float4_e2m1fn_x2, torch.float8_e4m3fn),
        (torch.float8_e4m3fn, torch.float4_e2m1fn_x2),
    ],
    ids=["mxfp4xmxfp8", "mxfp8xmxfp4"],
)
def test_mxfp4_mxfp8_mixed_gemm_sm100_2d(
    a_dtype: torch.dtype,
    b_dtype: torch.dtype,
    M: int,
    N: int,
    K: int,
    fixture_enable_tvm_ffi,
):
    """Tests valid mixed MXFP4 x MXFP8 GEMM cases with 2D A, B, and out.

    The mixed-precision analog of :func:`test_mxfp8_gemm_sm100_2d`. torch._scaled_mm
    cannot reference FP4, so the reference uses
    :func:`_emulated_scaled_dense_gemm_reference` (dequantize, unpack scales,
    float32 matmul). Covers both directions: MXFP4 x MXFP8 (A is FP4) and
    MXFP8 x MXFP4 (B is FP4).
    """
    scale = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4

    def make_kmajor(rows: int, dtype: torch.dtype) -> torch.Tensor:
        """K-major operand: FP4 via make_mxfp4_kmajor, else small-integer FP8."""
        if dtype == torch.float4_e2m1fn_x2:
            return make_mxfp4_kmajor(rows, K)
        return torch.randint(-1, 2, (rows, K), device="cuda").to(dtype)

    A = make_kmajor(M, a_dtype)  # (M, K), K-major
    B = make_kmajor(N, b_dtype).transpose(0, 1)  # (K, N), K-major

    D = torch.empty((M, N), device="cuda", dtype=torch.float32)

    SFA = make_random_pow2_scale(ops.ScaledOperand.numel_scale((M, K), scale, swizzle))
    SFB = make_random_pow2_scale(ops.ScaledOperand.numel_scale((N, K), scale, swizzle))

    args = ops.GemmArguments(
        A=ops.ScaledOperand(A, SFA, scale, swizzle),
        B=ops.ScaledOperand(B, SFB, scale, swizzle),
        out=D,
        accumulator_type=torch.float32,
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operator = operators[0]
    assert operator.supports(args)
    compiled_artifact = operator.compile(args)
    operator.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    # Integer operands and power-of-two scales make the accumulation exact.
    reference = scaled_dense_gemm_reference(args, ref_as_acc_dtype=True)
    if reference is not None:
        test_utils.reference_check.assert_close_with_reference_conversion(
            D,
            reference,
            D.dtype,
            atols=0.0,
            rtols=0.0,
        )


@pytest.mark.arch(sms=["100f"])
def test_mxfp8_reshaped_scale_factors(fixture_enable_tvm_ffi):
    """
    Tests for valid MXFP8 GEMM cases in which scale factors have correct numel but arbitrary shape
    """
    M, N, K, L = 256, 512, 1024, 1
    scale = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = (
        torch.randint(-1, 2, (L, N, K), device="cuda")
        .to(torch.float8_e4m3fn)
        .transpose(1, 2)
    )
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale, swizzle),
        device="cuda",
    ).to(torch.float8_e8m0fnu)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), scale, swizzle),
        device="cuda",
    ).to(torch.float8_e8m0fnu)

    args = ops.GemmArguments(
        # Pass in SFA and SFB viewed as (L, -1, 2, K)
        A=ops.ScaledOperand(
            A,
            SFA.view(L, -1, 2, K),
            scale,
            swizzle,
        ),
        B=ops.ScaledOperand(
            B,
            SFB.view(L, -1, 2, K),
            scale,
            swizzle,
        ),
        out=D,
        accumulator_type=torch.float32,
    )

    # Only test operators for which we know there will be an error if the scale factors are invalid
    def metadata_filter(metadata: ops.OperatorMetadata):
        return metadata.operator_class is PersistentDenseBlockScaledGemmOperator

    operators = ops.get_operators(
        args, target_sm=device_or_env_target_sm(), metadata_filter=metadata_filter
    )
    assert len(operators) > 0
    operator = operators[0]
    assert operator.supports(args)
    compiled_artifact = operator.compile(args)
    operator.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    def transform_sf(x: torch.Tensor) -> torch.Tensor:
        """Flattens scale factor tensors after indexing into the batch dimension"""
        return x.view(-1)

    reference = reference_scaled_mm(A, B, SFA, SFB, torch.float32, transform_sf)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize(
    "discovery_scale_mode, runtime_scale_mode",
    [
        ((1, 1, 32), (1, 1, 32)),
        ((1, 32), (1, 1, 32)),
        (ops.ScaleMode.Blockwise1x32, ops.ScaleMode.Blockwise1x32),
        (ops.ScaleMode.Blockwise1x32, (1, 32)),
    ],
)
@pytest.mark.arch(sms=["100f"])
def test_mxfp8_tuple_scale_mode(
    discovery_scale_mode: tuple[int, ...],
    runtime_scale_mode: tuple[int, ...],
    fixture_enable_tvm_ffi,
):
    """
    Tests for valid MXFP8 GEMM cases in which A, B, and out are 3D tensors, and
    the scale mode is specified as a tuple.
    """
    M, N, K, L = 256, 512, 1024, 1

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = (
        torch.randint(-1, 2, (L, N, K), device="cuda")
        .to(torch.float8_e4m3fn)
        .transpose(1, 2)
    )
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), discovery_scale_mode, swizzle),
        device="cuda",
    ).to(torch.float8_e8m0fnu)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), discovery_scale_mode, swizzle),
        device="cuda",
    ).to(torch.float8_e8m0fnu)

    discovery_args = ops.GemmArguments(
        A=ops.ScaledOperand(
            A,
            SFA,
            discovery_scale_mode,
            swizzle,
        ),
        B=ops.ScaledOperand(
            B,
            SFB,
            discovery_scale_mode,
            swizzle,
        ),
        out=D,
        accumulator_type=torch.float32,
    )

    # Only test operators for which we know there will be an error if the scale factors are invalid
    def metadata_filter(metadata: ops.OperatorMetadata):
        return metadata.operator_class is PersistentDenseBlockScaledGemmOperator

    operators = ops.get_operators(
        discovery_args,
        target_sm=device_or_env_target_sm(),
        metadata_filter=metadata_filter,
    )
    assert len(operators) > 0
    operator = operators[0]
    compiled_artifact = operator.compile(discovery_args)

    runtime_args = ops.GemmArguments(
        A=ops.ScaledOperand(
            A,
            SFA,
            runtime_scale_mode,
            swizzle,
        ),
        B=ops.ScaledOperand(
            B,
            SFB,
            runtime_scale_mode,
            swizzle,
        ),
        out=D,
        accumulator_type=torch.float32,
    )
    assert operator.supports(runtime_args)
    operator.run(
        runtime_args, compiled_artifact=compiled_artifact, assume_supported_args=True
    )

    reference = reference_scaled_mm(A, B, SFA, SFB, torch.float32)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.arch(sms=["100f"])
def test_mxfp8_incompatible_mode_or_swizzle(fixture_enable_tvm_ffi):
    """
    Tests for correct flagging of incompatible scale modes or swizzles:
      - Using no swizzle mode for MXFP8
      - Using an incompatible scale mode for MXFP8
    """
    M, N, K, L = 256, 512, 1024, 1
    scale = ops.ScaleMode.Blockwise1x32
    ab_dtype = torch.float8_e4m3fn
    scale_dtype = torch.float8_e8m0fnu

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(ab_dtype)
    B = torch.randint(-1, 2, (L, N, K), device="cuda").to(ab_dtype).transpose(1, 2)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    SFA = torch.rand(
        ops.ScaledOperand.numel_scale(
            (L, M, K), scale, ops.ScaleSwizzleMode.Swizzle32x4x4
        ),
        device="cuda",
    ).to(scale_dtype)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale(
            (L, N, K), scale, ops.ScaleSwizzleMode.Swizzle32x4x4
        ),
        device="cuda",
    ).to(scale_dtype)

    args_bad = ops.GemmArguments(
        # Use incompatible swizzle mode for SFA
        A=ops.ScaledOperand(
            A,
            SFA,
            scale,
            ops.ScaleSwizzleMode.SwizzleNone,
        ),
        B=ops.ScaledOperand(
            B,
            SFB,
            scale,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )

    # Only test operators for which the swizzle mode is incompatible
    def metadata_filter(metadata: ops.OperatorMetadata):
        return metadata.operator_class is PersistentDenseBlockScaledGemmOperator

    operators = ops.get_operators(
        args_bad, target_sm=device_or_env_target_sm(), metadata_filter=metadata_filter
    )
    assert len(operators) == 0

    # Find operator using compatible swizzle mode, but pass in arguments at runtime with
    # incompatible swizzle mode
    args_good = ops.GemmArguments(
        A=ops.ScaledOperand(
            A,
            SFA,
            scale,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ops.ScaledOperand(
            B,
            SFB,
            scale,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )
    operators = ops.get_operators(
        args_good, target_sm=device_or_env_target_sm(), metadata_filter=metadata_filter
    )
    assert len(operators) > 0
    operator = operators[0]

    with pytest.raises(ValueError):
        operator.run(args_bad)

    # Pass in arguments with an incompatible scale mode
    args_bad_scale = ops.GemmArguments(
        A=ops.ScaledOperand(
            A,
            SFA,
            scale,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        # Bad scale mode: SFB had scale mode Blockwise1x16
        B=ops.ScaledOperand(
            B,
            SFB,
            ops.ScaleMode.Blockwise1x16,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )
    with pytest.raises(ValueError):
        operator.run(args_bad_scale)


@pytest.mark.arch(sms=["100f"])
def test_mxfp8_missing_scale_factors(fixture_enable_tvm_ffi):
    """
    Tests for correct flagging of a missing scale factor (both must be supplied)
    """
    M, N, K, L = 256, 512, 1024, 1
    scale = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = (
        torch.randint(-1, 2, (L, N, K), device="cuda")
        .to(torch.float8_e4m3fn)
        .transpose(1, 2)
    )
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)
    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale, swizzle),
        device="cuda",
    ).to(torch.float8_e8m0fnu)

    # Construct arguments with only one scale factor
    args = ops.GemmArguments(
        A=ops.ScaledOperand(
            A,
            SFA,
            scale,
            swizzle,
        ),
        B=B,
        out=D,
        accumulator_type=torch.float32,
    )

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) == 0


@pytest.mark.arch(sms=["100f"])
def test_mxfp8_invalid_scale_factors(fixture_enable_tvm_ffi):
    """
    Tests for correct flagging of invalid scale factors:
      - Too large for the A tensor
      - Too large for the B tensor
    """
    M, N, K, L = 256, 512, 1024, 1
    scale = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
    ab_dtype = torch.float8_e4m3fn
    scale_dtype = torch.float8_e8m0fnu

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(ab_dtype)
    B = torch.randint(-1, 2, (L, N, K), device="cuda").to(ab_dtype).transpose(1, 2)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    # Pad SFA past its expected element count. This makes it too large for the A tensor.
    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale, swizzle) + 32,
        device="cuda",
    ).to(scale_dtype)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), scale, swizzle),
        device="cuda",
    ).to(scale_dtype)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(
            A,
            SFA,
            scale,
            swizzle,
        ),
        B=ops.ScaledOperand(
            B,
            SFB,
            scale,
            swizzle,
        ),
        out=D,
        accumulator_type=torch.float32,
    )

    # Only test operators for which we know there will be an error if the scale factors are invalid
    def metadata_filter(metadata: ops.OperatorMetadata):
        return metadata.operator_class is PersistentDenseBlockScaledGemmOperator

    operators = ops.get_operators(
        args, target_sm=device_or_env_target_sm(), metadata_filter=metadata_filter
    )
    assert len(operators) == 0

    # Pad SFB past its expected element count. This makes it too large for the B tensor.
    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale, swizzle),
        device="cuda",
    ).to(scale_dtype)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), scale, swizzle) + 32,
        device="cuda",
    ).to(scale_dtype)
    args = ops.GemmArguments(
        A=ops.ScaledOperand(
            A,
            SFA,
            scale,
            swizzle,
        ),
        B=ops.ScaledOperand(
            B,
            SFB,
            scale,
            swizzle,
        ),
        out=D,
        accumulator_type=torch.float32,
    )
    operators = ops.get_operators(
        args, target_sm=device_or_env_target_sm(), metadata_filter=metadata_filter
    )
    assert len(operators) == 0


@pytest.mark.arch(sms=["100f"])
def test_mxfp8_gemm_sm100_invalid_epilogue(fixture_enable_tvm_ffi):
    """
    Tests for correct flagging of invalid epilogues: currently, no MXFP8 operators support
    epilogue fusions.
    """
    M, N, K, L = 256, 512, 1024, 1

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = (
        torch.randint(-1, 2, (L, N, K), device="cuda")
        .to(torch.float8_e4m3fn)
        .transpose(1, 2)
    )
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    scale_dtype = torch.float8_e8m0fnu
    scale = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale, swizzle),
        device="cuda",
    ).to(scale_dtype)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), scale, swizzle),
        device="cuda",
    ).to(scale_dtype)

    C = torch.randint(-1, 2, (L, M, N), device="cuda").to(torch.float32)

    def epilogue(accum, alpha, beta, C):
        D = alpha * accum + beta * C
        return D

    epi_args = ops.EpilogueArguments(epilogue, alpha=1.0, beta=1.0, C=C, D=D)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(
            A,
            SFA,
            scale,
            swizzle,
        ),
        B=ops.ScaledOperand(
            B,
            SFB,
            scale,
            swizzle,
        ),
        out=D,
        accumulator_type=torch.float32,
        epilogue=epi_args,
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) == 0


@pytest.mark.arch(sms=["100f"])
def test_mxfp8_gemm_sm100_design_metadata(fixture_enable_tvm_ffi):
    """
    Tests for correct filtering of operators based on design metadata specifications
    (e.g., tile shape, cluster shape, etc.).
    """
    M, N, K, L = 256, 512, 1024, 1

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = (
        torch.randint(-1, 2, (L, N, K), device="cuda")
        .to(torch.float8_e4m3fn)
        .transpose(1, 2)
    )
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    scale_dtype = torch.float8_e8m0fnu
    scale = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale, swizzle),
        device="cuda",
    ).to(scale_dtype)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), scale, swizzle),
        device="cuda",
    ).to(scale_dtype)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(
            A,
            SFA,
            scale,
            swizzle,
        ),
        B=ops.ScaledOperand(
            B,
            SFB,
            scale,
            swizzle,
        ),
        out=D,
        accumulator_type=torch.float32,
    )

    def design_filter(metadata: ops.OperatorMetadata):
        if not isinstance(metadata.design, Sm100DesignMetadata):
            return False
        return metadata.design.tile_shape[:2] == (256, 128)

    operators = ops.get_operators(
        args, target_sm=device_or_env_target_sm(), metadata_filter=design_filter
    )
    assert len(operators) > 0

    for operator in operators:
        assert design_filter(operator.metadata)

    operator = operators[0]
    assert operator.supports(args)
    compiled_artifact = operator.compile(args)
    operator.run(args, compiled_artifact=compiled_artifact)

    reference = reference_scaled_mm(A, B, SFA, SFB, torch.float32)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize(
    "M, N, K",
    [
        (256, 512, 512),
        (512, 256, 512),
    ],
)
@pytest.mark.arch(sms=["100f"])
def test_nvfp4_gemm_sm100(
    M: int,
    N: int,
    K: int,
    fixture_enable_tvm_ffi,
):
    """
    Tests NVFP4 GEMM using the PersistentDenseBlockScaledGemmOperator.
    Float4E2M1FN requires K-major layout for both A and B.
    PyTorch stores FP4 as float4_e2m1fn_x2 (2 values packed per byte).
    """
    L = 1
    c_dtype = torch.float16
    accumulator_type = torch.float32
    scale_dtype = torch.float8_e4m3fn
    scale_mode = ops.ScaleMode.Blockwise1x16

    # FP4 tensors: K is the number of FP4 elements; PyTorch stores K//2 packed pairs
    K_packed = K // 2
    A = torch.randint(0, 2, (L, M, K_packed), dtype=torch.uint8, device="cuda").view(
        torch.float4_e2m1fn_x2
    )
    B = (
        torch.randint(0, 2, (L, N, K_packed), dtype=torch.uint8, device="cuda")
        .view(torch.float4_e2m1fn_x2)
        .transpose(1, 2)
    )
    D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)

    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4

    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale_mode, swizzle),
        device="cuda",
    ).to(scale_dtype)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), scale_mode, swizzle),
        device="cuda",
    ).to(scale_dtype)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(A, SFA, scale_mode, swizzle),
        B=ops.ScaledOperand(B, SFB, scale_mode, swizzle),
        out=D,
        accumulator_type=accumulator_type,
    )

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0, f"No NVFP4 kernels found for M={M}, N={N}, K={K}"
    operator = operators[0]
    assert operator.supports(args)
    compiled_artifact = operator.compile(args)
    operator.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    reference = scaled_dense_gemm_reference(args, ref_as_acc_dtype=True)
    test_utils.reference_check.assert_close_with_reference_conversion(
        D, reference, D.dtype, atols=1e-01, rtols=1e-02,
    )


@pytest.mark.arch(sms=["100f"])
def test_nvfp4_gemm_sm100_batched(fixture_enable_tvm_ffi):
    """
    Tests batched NVFP4 GEMM (L > 1) with Float4E2M1FN inputs and
    Float8E4M3FN scale factors using Blockwise1x16 scale mode.
    """
    M, N, K, L = 256, 512, 512, 2
    c_dtype = torch.float16
    accumulator_type = torch.float32
    scale_dtype = torch.float8_e4m3fn
    scale_mode = ops.ScaleMode.Blockwise1x16

    K_packed = K // 2
    A = torch.randint(0, 2, (L, M, K_packed), dtype=torch.uint8, device="cuda").view(
        torch.float4_e2m1fn_x2
    )
    B = (
        torch.randint(0, 2, (L, N, K_packed), dtype=torch.uint8, device="cuda")
        .view(torch.float4_e2m1fn_x2)
        .transpose(1, 2)
    )
    D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)

    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4

    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale_mode, swizzle),
        device="cuda",
    ).to(scale_dtype)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), scale_mode, swizzle),
        device="cuda",
    ).to(scale_dtype)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(A, SFA, scale_mode, swizzle),
        B=ops.ScaledOperand(B, SFB, scale_mode, swizzle),
        out=D,
        accumulator_type=accumulator_type,
    )

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0
    operator = operators[0]
    assert operator.supports(args)
    compiled_artifact = operator.compile(args)
    operator.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    reference = scaled_dense_gemm_reference(args, ref_as_acc_dtype=True)
    test_utils.reference_check.assert_close_with_reference_conversion(
        D, reference, D.dtype, atols=1e-01, rtols=1e-02,
    )


@pytest.mark.parametrize(
    "M, N, K, scale_mode",
    [
        (256, 512, 512, ops.ScaleMode.Blockwise1x16),
        (512, 256, 512, ops.ScaleMode.Blockwise1x32),
    ],
)
@pytest.mark.arch(sms=["100f"])
def test_nvfp4_gemm_sm100_e8m0_scales(
    M: int,
    N: int,
    K: int,
    scale_mode: ops.ScaleMode,
    fixture_enable_tvm_ffi,
):
    """Tests NVFP4 GEMM with Float8E8M0FNU scale factors.

    torch._scaled_mm does not support FP4 + E8M0FNU, so this exercises the
    emulated reference path (dequantize + unpack scales + float32 matmul).
    """
    L = 1
    c_dtype = torch.float16
    accumulator_type = torch.float32
    scale_dtype = torch.float8_e8m0fnu
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4

    K_packed = K // 2
    _FP4_BYTE_PATTERNS = torch.tensor(
        [0x00, 0x02, 0x0A, 0x20, 0x22, 0x2A, 0xA0, 0xA2, 0xAA],
        dtype=torch.uint8,
        device="cuda",
    )
    A = _FP4_BYTE_PATTERNS[
        torch.randint(0, len(_FP4_BYTE_PATTERNS), (L, M, K_packed), device="cuda")
    ].view(torch.float4_e2m1fn_x2)
    B = (
        _FP4_BYTE_PATTERNS[
            torch.randint(0, len(_FP4_BYTE_PATTERNS), (L, N, K_packed), device="cuda")
        ]
        .view(torch.float4_e2m1fn_x2)
        .transpose(1, 2)
    )
    D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)

    SFA = torch.ones(
        ops.ScaledOperand.numel_scale((L, M, K), scale_mode, swizzle),
        device="cuda",
    ).to(scale_dtype)
    SFB = torch.ones(
        ops.ScaledOperand.numel_scale((L, N, K), scale_mode, swizzle),
        device="cuda",
    ).to(scale_dtype)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(A, SFA, scale_mode, swizzle),
        B=ops.ScaledOperand(B, SFB, scale_mode, swizzle),
        out=D,
        accumulator_type=accumulator_type,
    )

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0, f"No NVFP4 kernels found for M={M}, N={N}, K={K}"
    operator = operators[0]
    assert operator.supports(args)
    compiled_artifact = operator.compile(args)
    operator.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    reference = scaled_dense_gemm_reference(args, ref_as_acc_dtype=True)
    test_utils.reference_check.assert_close_with_reference_conversion(
        D, reference, D.dtype, atols=1e-01, rtols=1e-02,
    )


def _make_nvfp4_tensors(M, N, K, L=1):
    """Create standard NVFP4 tensors (K-major A/B, output D, scale factors)."""
    K_packed = K // 2
    scale_mode = ops.ScaleMode.Blockwise1x16
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
    scale_dtype = torch.float8_e4m3fn

    A = torch.randint(0, 2, (L, M, K_packed), dtype=torch.uint8, device="cuda").view(
        torch.float4_e2m1fn_x2
    )
    B = (
        torch.randint(0, 2, (L, N, K_packed), dtype=torch.uint8, device="cuda")
        .view(torch.float4_e2m1fn_x2)
        .transpose(1, 2)
    )
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float16)

    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale_mode, swizzle),
        device="cuda",
    ).to(scale_dtype)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), scale_mode, swizzle),
        device="cuda",
    ).to(scale_dtype)

    return A, B, D, SFA, SFB, scale_mode


@pytest.mark.arch(sms=["100f"])
def test_nvfp4_no_kernels_for_mn_major(fixture_enable_tvm_ffi):
    """
    Tests that no kernels are found when FP4 operands use M-major layout,
    since Float4E2M1FN only supports K-major layout for both A and B.
    """
    M, N, K, L = 256, 512, 512, 1
    scale_mode = ops.ScaleMode.Blockwise1x16
    scale_dtype = torch.float8_e4m3fn

    K_packed = K // 2
    A = (
        torch.randint(0, 2, (L, K_packed, M), dtype=torch.uint8, device="cuda")
        .view(torch.float4_e2m1fn_x2)
        .transpose(1, 2)
    )
    B = (
        torch.randint(0, 2, (L, N, K_packed), dtype=torch.uint8, device="cuda")
        .view(torch.float4_e2m1fn_x2)
        .transpose(1, 2)
    )
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float16)

    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4

    SFA = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale_mode, swizzle),
        device="cuda",
    ).to(scale_dtype)
    SFB = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), scale_mode, swizzle),
        device="cuda",
    ).to(scale_dtype)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(A, SFA, scale_mode, swizzle),
        B=ops.ScaledOperand(B, SFB, scale_mode, swizzle),
        out=D,
        accumulator_type=torch.float32,
    )

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) == 0


@pytest.mark.arch(sms=["100f"])
def test_nvfp4_invalid_scale_factors(fixture_enable_tvm_ffi):
    """
    Tests for correct flagging of invalid scale factors for NVFP4:
      - SFA too large for the A tensor
      - SFB too large for the B tensor
    """
    M, N, K, L = 256, 512, 512, 1
    A, B, D, _, _, scale_mode = _make_nvfp4_tensors(M, N, K, L)
    scale_dtype = torch.float8_e4m3fn
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
    correct_sfa_numel = ops.ScaledOperand.numel_scale((L, M, K), scale_mode, swizzle)
    correct_sfb_numel = ops.ScaledOperand.numel_scale((L, N, K), scale_mode, swizzle)

    # SFA with extra elements — too large for A
    SFA_bad = torch.rand(correct_sfa_numel + 32, device="cuda").to(scale_dtype)
    SFB_good = torch.rand(correct_sfb_numel, device="cuda").to(scale_dtype)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(A, SFA_bad, scale_mode, swizzle),
        B=ops.ScaledOperand(B, SFB_good, scale_mode, swizzle),
        out=D,
        accumulator_type=torch.float32,
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) == 0

    # SFB with extra elements — too large for B
    SFA_good = torch.rand(correct_sfa_numel, device="cuda").to(scale_dtype)
    SFB_bad = torch.rand(correct_sfb_numel + 32, device="cuda").to(scale_dtype)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(A, SFA_good, scale_mode, swizzle),
        B=ops.ScaledOperand(B, SFB_bad, scale_mode, swizzle),
        out=D,
        accumulator_type=torch.float32,
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) == 0


@pytest.mark.arch(sms=["100f"])
def test_nvfp4_missing_scale_factors(fixture_enable_tvm_ffi):
    """
    Tests that no blockscaled kernels are found when B is passed as a plain
    DenseTensor (without scale factors) while A has scale factors.
    """
    M, N, K, L = 256, 512, 512, 1
    A, B, D, SFA, _, scale_mode = _make_nvfp4_tensors(M, N, K, L)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(A, SFA, scale_mode, ops.ScaleSwizzleMode.Swizzle32x4x4),
        B=B,
        out=D,
        accumulator_type=torch.float32,
    )

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) == 0


@pytest.mark.arch(sms=["100f"])
def test_nvfp4_incompatible_swizzle(fixture_enable_tvm_ffi):
    """
    Tests that no kernels are found when NVFP4 operands use SwizzleNone
    instead of the required Swizzle32x4x4.
    """
    M, N, K, L = 256, 512, 512, 1
    A, B, D, SFA, SFB, scale_mode = _make_nvfp4_tensors(M, N, K, L)

    args = ops.GemmArguments(
        A=ops.ScaledOperand(A, SFA, scale_mode, ops.ScaleSwizzleMode.SwizzleNone),
        B=ops.ScaledOperand(B, SFB, scale_mode, ops.ScaleSwizzleMode.Swizzle32x4x4),
        out=D,
        accumulator_type=torch.float32,
    )

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) == 0
