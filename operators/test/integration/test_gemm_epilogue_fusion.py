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

import cutlass.torch as cutlass_torch

import cutlass.operators as ops
from cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc import (
    Sm100PersistentDenseGemmEFCOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm107_static_persistent_efc import (
    Sm107PersistentDenseGemmEFCOperator,
)
from cutlass.operators.utils.device import (
    device_or_env_supports,
    device_or_env_target_sm,
)

from test_utils import assert_close_with_reference_conversion, reference_device
from test_utils.gemm import small_integer_gemm_inputs
from test_utils.reference_check import get_torch_default_tolerances

torch.manual_seed(2025)


def problem_sizes():
    """
    Problem sizes for tests
    """
    return [
        (256, 512, 1024, 1),
        (256, 512, 128, 1),
        (256, 512, 128, 2),
    ]


def base_data_types():
    """
    Data types for (ab, c, d, accumulator)
    """
    return [
        (torch.float16, torch.float32, torch.float32, torch.float32),
        (torch.float16, torch.float16, torch.float16, torch.float16),
        (torch.bfloat16, torch.bfloat16, torch.bfloat16, torch.float32),
    ]


# Unary operation strings and functions
identity = ("", lambda x: x)
relu = ("relu", torch.relu)
tanh = ("tanh", torch.tanh)
sigmoid = ("sigmoid", torch.sigmoid)
exp = ("exp", torch.exp)

unary_ops = [identity, relu, tanh, sigmoid, exp]


# Binary operation strings and functions
add = (lambda a, b: f"{a} + {b}", lambda a, b: a + b)
sub = (lambda a, b: f"{a} - {b}", lambda a, b: a - b)
mul = (lambda a, b: f"{a} * {b}", lambda a, b: a * b)

# Don't include divide in main binary ops due to issues with division by zero in refchecks
binary_ops = [add, sub, mul]


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_no_fusion(fixture_toggle_tvm_ffi):
    """
    Tests EFC GEMM with no fusion provided.

    """
    M, N, K, L = 256, 512, 128, 2
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float16)

    def metadata_filter(metadata):
        return metadata.operator_class is Sm100PersistentDenseGemmEFCOperator

    args = ops.GemmArguments(A, B, D, accumulator_type=torch.float16)
    operators = ops.get_operators(
        args, target_sm=device_or_env_target_sm(), metadata_filter=metadata_filter
    )
    assert len(operators) > 0
    operators[0].run(args)

    reference = A @ B
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("d_dtype", [torch.bfloat16, torch.float32])
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and sm_100a or sm_100f",
)
def test_gemm_fusion_relu_fp32_accumulator(d_dtype):
    """Bare relu works with BF16 inputs, FP32 accumulation, and either output type."""
    A = torch.randint(-1, 2, (1, 128, 64), device="cuda", dtype=torch.bfloat16)
    B = torch.randint(-1, 2, (1, 64, 128), device="cuda", dtype=torch.bfloat16)
    D = torch.empty((1, 128, 128), device="cuda", dtype=d_dtype)
    source = "def epi(accum): D = relu(accum); return D"
    args = ops.GemmArguments(
        A,
        B,
        D,
        accumulator_type=torch.float32,
        epilogue=ops.EpilogueArguments(source, D=D),
    )
    operators = ops.get_operators(
        args,
        target_sm=device_or_env_target_sm(),
        metadata_filter=lambda metadata: (
            metadata.operator_class is Sm100PersistentDenseGemmEFCOperator
        ),
    )
    assert operators
    operators[0].run(args)

    # Integer inputs keep GEMM exact; evaluate ReLU before the output conversion.
    reference = torch.relu(A.float() @ B.float())
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
# Restrict to D of float16 for now to avoid rounding error when converting torch f16 output to f32
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.parametrize("unary_str, unary_op", unary_ops)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_unary(
    M, N, K, L, ab_dtype, d_dtype, accumulator_type, unary_str, unary_op
):
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum):
        D = unary_op(accum)
        return D

    epi_str = f"def epi(accum): D = {unary_str}(accum); return D"

    epi_args = ops.EpilogueArguments(epi_str, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", [(256, 512, 128, 2)])
# Restrict to D of float16 for now to avoid rounding error when converting torch f16 output to f32
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.parametrize("unary_str, unary_op", [relu])
@pytest.mark.parametrize("unary_str2, unary_op2", [sigmoid, tanh])
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_unary_composition(
    M,
    N,
    K,
    L,
    ab_dtype,
    d_dtype,
    accumulator_type,
    unary_str,
    unary_op,
    unary_str2,
    unary_op2,
):
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum):
        D = unary_op2(unary_op(accum))
        return D

    epi_str = f"def epi(accum): D = {unary_str2}({unary_str}(accum)); return D"

    epi_args = ops.EpilogueArguments(epi_str, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
# Restrict to D of float16 for now to avoid rounding error when converting torch f16 output to f32
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
# Restrict unary to identity and relu to avoid rounding errors
@pytest.mark.parametrize("unary_str, unary_op", [identity, relu])
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_unary_literal(
    M, N, K, L, ab_dtype, d_dtype, accumulator_type, unary_str, unary_op
):
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum):
        D = unary_op(accum) * 3.0 - 1.234
        return D

    epi_str = f"def epi(accum): D = {unary_str}(accum) * 3.0 - 1.234; return D"

    epi_args = ops.EpilogueArguments(epi_str, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, d_dtype, accumulator_type", base_data_types()
)
@pytest.mark.parametrize("unary_str, unary_op", [identity, relu])
@pytest.mark.parametrize("binary_str, binary_op", binary_ops)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_unary_binary_composition(
    M,
    N,
    K,
    L,
    ab_dtype,
    c_dtype,
    d_dtype,
    accumulator_type,
    unary_str,
    unary_op,
    binary_str,
    binary_op,
):
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    C = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, C):
        z = unary_op(accum)
        D = binary_op(z, C)
        return D

    epi_str = f"def epi(accum, C): z = {unary_str}(accum); D = {binary_str('z', 'C')}; return D"

    epi_args = ops.EpilogueArguments(epi_str, C=C, D=D)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B, C)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
# Restrict to D of float16 for now to avoid rounding error when converting torch f16 output to f32
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.parametrize("c0_dtype", [torch.float16, torch.float32])
@pytest.mark.parametrize("c1_dtype", [torch.float16, torch.float32])
@pytest.mark.parametrize("binary_str0, binary_op0", [add, sub])
@pytest.mark.parametrize("binary_str1, binary_op1", [add, sub])
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_binary_binary_composition(
    M,
    N,
    K,
    L,
    ab_dtype,
    d_dtype,
    accumulator_type,
    c0_dtype,
    c1_dtype,
    binary_str0,
    binary_op0,
    binary_str1,
    binary_op1,
):
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    C0 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c0_dtype)
    C1 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c1_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, C0, C1):
        z = torch.relu(accum)
        z1 = binary_op0(z, C0)
        D = binary_op1(z1, C1)
        return D

    epi_str = f"def epi(accum, C0, C1): z = relu(accum); z1 = {binary_str0('z', 'C0')}; D = {binary_str1('z1', 'C1')}; return D"

    epi_args = ops.EpilogueArguments(epi_str, C0=C0, C1=C1, D=D)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B, C0, C1)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_division():
    M, N, K, L = 256, 512, 128, 2
    ab_dtype = torch.float16
    d_dtype = torch.float16
    accumulator_type = torch.float16

    # Specifically initialize A and B with ones to avoid division by zero in refchecks
    A = torch.ones((L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.ones((L, K, N), device="cuda", dtype=ab_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    #########################################################
    # Test division by a literal
    #########################################################
    def epi(accum):
        D = accum / 2.0
        return D

    epi_str = "def epi(accum): D = accum / 2.0; return D"
    epi_args = ops.EpilogueArguments(epi_str, D=D)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B)
    assert_close_with_reference_conversion(D, reference, D.dtype)

    #########################################################
    # Test division by an input
    #########################################################
    def epi(accum, scalar):
        D = accum / scalar
        return D

    epi_str = "def epi(accum, scalar): D = accum / scalar; return D"

    scalar = 4.0
    epi_args = ops.EpilogueArguments(epi_str, scalar=scalar, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B, scalar)

    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
# Restrict to D of float16 for now to avoid rounding error when converting torch f16 output to f32
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.parametrize("unary_str, unary_op", [sigmoid, tanh])
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_unary_multi_output(
    M, N, K, L, ab_dtype, d_dtype, accumulator_type, unary_str, unary_op
):
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    z = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum):
        z0 = torch.relu(accum)
        z = unary_op(z0)
        D = z + z0
        return D, z

    epi_str = f"def epi(accum): z0 = relu(accum); z = {unary_str}(z0); D = z + z0; return D, z"

    epi_args = ops.EpilogueArguments(epi_str, z=z, D=D)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    acc = (A @ B).to(accumulator_type)
    ref_D, ref_z = epi(acc.float())
    rtol, atol = get_torch_default_tolerances()[d_dtype]
    assert_close_with_reference_conversion(D, ref_D, D.dtype, rtols=rtol, atols=atol)
    assert_close_with_reference_conversion(z, ref_z, z.dtype, rtols=rtol, atols=atol)


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
# Restrict to D of float16 for now to avoid rounding error when converting torch f16 output to f32
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.parametrize("c_dtype", [torch.float16, torch.float32])
@pytest.mark.parametrize("binary_str, binary_op", binary_ops)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_binary_multi_output(
    M, N, K, L, ab_dtype, d_dtype, accumulator_type, c_dtype, binary_str, binary_op
):
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    C = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    z = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, C):
        z0 = torch.relu(accum)
        z = binary_op(z0, C)
        D = z + z0
        return D, z

    epi_str = f"def epi(accum, C): z0 = relu(accum); z = {binary_str('z0', 'C')}; D = z + z0; return D, z"

    epi_args = ops.EpilogueArguments(epi_str, C=C, z=z, D=D)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    ref_D, ref_z = epi(A @ B, C)
    assert_close_with_reference_conversion(D, ref_D, D.dtype)
    assert_close_with_reference_conversion(z, ref_z, z.dtype)


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_return_acc():
    M, N, K, L = 256, 512, 128, 2
    ab_dtype = torch.float16
    c_dtype = torch.float32
    d_dtype = torch.float16
    accumulator_type = torch.float16

    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    C = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    accum = torch.empty((L, M, N), device="cuda", dtype=accumulator_type)

    def epi(accum, C):
        D = torch.relu(accum) + C
        return D, accum

    epi_str = "def epi(accum, C): D = relu(accum) + C; return D, accum"

    epi_args = ops.EpilogueArguments(epi_str, C=C, D=D, accum=accum)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference, ref_accum = epi(A @ B, C)
    assert_close_with_reference_conversion(D, reference, D.dtype)
    assert_close_with_reference_conversion(accum, ref_accum, accum.dtype)


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_acc_as_multiple_input():
    M, N, K, L = 256, 512, 128, 2
    ab_dtype = torch.float16
    c_dtype = torch.float32
    d_dtype = torch.float16
    accumulator_type = torch.float16

    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    C = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    #########################################################
    # Test binary op inside
    #########################################################
    def epi(accum, C):
        D = torch.relu(torch.relu(accum) * C) + accum
        return D

    epi_str = "def epi(accum, C): D = relu(relu(accum) * C) + accum; return D"

    epi_args = ops.EpilogueArguments(epi_str, C=C, D=D)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B, C)
    assert_close_with_reference_conversion(D, reference, D.dtype)

    #########################################################
    # Test unary op inside
    #########################################################
    def epi(accum):
        D = torch.relu(torch.sigmoid(torch.relu(accum))) + accum
        return D

    epi_str = "def epi(accum): D = relu(sigmoid(relu(accum))) + accum; return D"

    epi_args = ops.EpilogueArguments(epi_str, D=D)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    acc = (A @ B).to(accumulator_type)
    reference = epi(acc.to(c_dtype))
    rtol, atol = get_torch_default_tolerances()[d_dtype]
    assert_close_with_reference_conversion(
        D, reference, D.dtype, rtols=rtol, atols=atol
    )


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_matmul_input_as_aux():
    M, N, K, L = 1024, 1024, 1024, 2
    ab_dtype = torch.float16
    c_dtype = torch.float32
    d_dtype = torch.float16
    accumulator_type = torch.float16

    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    C = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    #########################################################
    # Test binary op inside
    #########################################################
    def epi(accum, C, A):
        # Match the kernel's view of C: the kernel loads C cast to the
        # operator's epi_dtype, so the reference must use C at the same
        # dtype for the exact-match comparison to be meaningful.
        D = torch.sigmoid(torch.relu(accum) * C.to(epi_dtype)) + A
        return D

    epi_str = "def epi(accum, C, A): D = sigmoid(relu(accum) * C) + A; return D"

    epi_args = ops.EpilogueArguments(epi_str, C=C, A=A, D=D)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    epi_dtype = cutlass_torch.dtype(operators[0].impl.epi_dtype)
    reference = epi(A @ B, C, A)
    assert_close_with_reference_conversion(D, reference, D.dtype)

    #########################################################
    # Test unary op inside
    #########################################################
    def epi(accum, A):
        D = torch.tanh(torch.relu(accum)) + A
        return D

    epi_str = "def epi(accum, A): D = tanh(relu(accum)) + A; return D"

    epi_args = ops.EpilogueArguments(epi_str, A=A, D=D)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B, A)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, d_dtype, accumulator_type", base_data_types()
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_alpha_beta(
    M, N, K, L, ab_dtype, c_dtype, d_dtype, accumulator_type, fixture_toggle_tvm_ffi
):
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    C = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, C, alpha, beta):
        D = alpha * accum + beta * C
        return D

    alpha = 0.5
    beta = 0.5
    epi_args = ops.EpilogueArguments(epi, C=C, alpha=alpha, beta=beta, D=D)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operator = operators[0]

    for a, b in [(0.5, 0.5), (1.0, 0.0), (0.0, 1.0)]:
        epi_args = ops.EpilogueArguments(epi, C=C, alpha=a, beta=b, D=D)
        args = ops.GemmArguments(
            A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
        )
        operator.run(args)
        reference = epi(A @ B, C, a, b)
        assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("read_via", ["tma", "sync_gmem_load", "async_gmem_load"])
@pytest.mark.parametrize("write_via", ["tma", "sync_gmem_store"])
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_alpha_beta_transports(read_via, write_via, fixture_toggle_tvm_ffi):
    M, N, K, L = 256, 512, 128, 1
    ab_dtype = c_dtype = d_dtype = torch.float16
    accumulator_type = torch.float32
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    C = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, C, alpha, beta):
        D = alpha * accum + beta * C
        return D

    alpha = beta = 0.5
    epi_args = ops.EpilogueArguments(
        epi,
        C=ops.Load(C, via=read_via),
        alpha=alpha,
        beta=beta,
        D=ops.Store(D, via=write_via),
    )
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)
    reference = epi(A @ B, C, alpha, beta)
    torch.testing.assert_close(D, reference.to(D.dtype))


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_alpha_beta_fake_tensor(fixture_toggle_tvm_ffi):
    import torch._functorch.config

    torch._functorch.config.fake_tensor_allow_unsafe_data_ptr_access = False

    M, N, K, L = 256, 512, 128, 2
    ab_dtype = torch.float16
    c_dtype = torch.float32
    d_dtype = torch.bfloat16
    accumulator_type = torch.float16

    with torch._subclasses.fake_tensor.FakeTensorMode():
        A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
        B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
        C = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
        D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, C, alpha, beta):
        D = alpha * accum + beta * C
        return D

    alpha = 0.5
    beta = 0.5
    epi_args = ops.EpilogueArguments(epi, C=C, alpha=alpha, beta=beta, D=D)

    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operator = operators[0]

    A_real = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B_real = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    C_real = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    D_real = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    for a, b in [(0.5, 0.5), (1.0, 0.0), (0.0, 1.0)]:
        epi_args = ops.EpilogueArguments(epi, C=C_real, alpha=a, beta=b, D=D_real)
        args = ops.GemmArguments(
            A=A_real,
            B=B_real,
            out=D_real,
            accumulator_type=accumulator_type,
            epilogue=epi_args,
        )
        operator.run(args)
        reference = epi(A_real @ B_real, C_real, a, b)
        assert_close_with_reference_conversion(D_real, reference, D_real.dtype)


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_scalar_reduction_fake_tensor(fixture_toggle_tvm_ffi):
    """A scalar reduction must compile from fake tensors (the torch-inductor path).

    The reduction destination is a single-element tensor forced to a *static*
    layout; this exercises the fake-tensor branch of that handling.  Operator
    discovery must succeed against fake metadata, then run on real tensors.
    """
    import torch._functorch.config

    torch._functorch.config.fake_tensor_allow_unsafe_data_ptr_access = False

    M, N, K = 256, 512, 128
    with torch._subclasses.fake_tensor.FakeTensorMode():
        A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
        B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
        D = torch.empty((M, N), device="cuda", dtype=torch.float32)
        # Single-element reduction destination -- the static_layout case.
        total = torch.zeros(1, device="cuda", dtype=torch.float32)

    epi_str = "def epi(accum): D = accum; total = sum(accum); return D, total"

    epi_args = ops.EpilogueArguments(epi_str, total=total, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0
    operator = operators[0]

    # Re-run on real tensors and verify both the GEMM output and the fold.
    A_real = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B_real = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D_real = torch.empty((M, N), device="cuda", dtype=torch.float32)
    total_real = torch.zeros(1, device="cuda", dtype=torch.float32)
    epi_args = ops.EpilogueArguments(epi_str, total=total_real, D=D_real)
    args = ops.GemmArguments(
        A=A_real,
        B=B_real,
        out=D_real,
        accumulator_type=torch.float32,
        epilogue=epi_args,
    )
    operator.run(args)

    ref_accum = A_real.float() @ B_real.float()
    torch.testing.assert_close(D_real, ref_accum)
    # Non-associative float atomic adds may reorder partial sums across tiles.
    torch.testing.assert_close(
        total_real, ref_accum.sum().unsqueeze(0), rtol=1e-2, atol=1.0
    )


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_column_reduction_fake_tensor(fixture_toggle_tvm_ffi):
    """A column reduction (keep M) must compile from fake tensors.

    The kept-axis counterpart of ``test_gemm_fusion_scalar_reduction_fake_tensor``.
    Both tests run discovery under ``FakeTensorMode``; what differs is the
    ``TensorWrapper`` layout marking of the reduction destination: the scalar
    test's single-element destination is wrapped with ``static_layout=True``
    (fully static shape), while this test's column-major ``(M, 1)`` destination
    takes the default *dynamic*-layout marking -- so the dynamic-layout wrapping
    of a reduce destination is exercised under fake tensors too.  Operator
    discovery runs from fake metadata, then a real run verifies the fold.
    """
    import torch._functorch.config

    torch._functorch.config.fake_tensor_allow_unsafe_data_ptr_access = False

    M, N, K = 256, 512, 128
    epi = "def epi(accum): D = accum; row_max = max(accum, dim=[1]); return D, row_max"

    with torch._subclasses.fake_tensor.FakeTensorMode():
        A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
        B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
        D = torch.empty((M, N), device="cuda", dtype=torch.float32)
        row_max = torch.empty_strided(
            (M, 1), (1, M), device="cuda", dtype=torch.float32
        ).fill_(float("-inf"))

    args = ops.GemmArguments(
        A=A,
        B=B,
        out=D,
        accumulator_type=torch.float32,
        epilogue=ops.EpilogueArguments(epi, row_max=row_max, D=D),
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0
    operator = operators[0]

    A_real = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B_real = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D_real = torch.empty((M, N), device="cuda", dtype=torch.float32)
    row_max_real = torch.empty_strided(
        (M, 1), (1, M), device="cuda", dtype=torch.float32
    ).fill_(float("-inf"))
    operator.run(
        ops.GemmArguments(
            A=A_real,
            B=B_real,
            out=D_real,
            accumulator_type=torch.float32,
            epilogue=ops.EpilogueArguments(epi, row_max=row_max_real, D=D_real),
        )
    )

    ref = A_real.float() @ B_real.float()
    torch.testing.assert_close(row_max_real, ref.amax(dim=1, keepdim=True))


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_big_epi(fixture_toggle_tvm_ffi):
    M, N, K, L = 256, 512, 128, 2
    ab_dtype = torch.float16
    c_dtype = torch.float32
    d_dtype = torch.bfloat16
    accumulator_type = torch.float16

    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)

    In0 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In1 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In2 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In3 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In4 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In5 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In6 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)
    In7 = torch.randint(-1, 2, (L, M, N), device="cuda", dtype=c_dtype)

    Out0 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out1 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out2 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out3 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out4 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out5 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    Out6 = torch.empty((L, M, N), device="cuda", dtype=d_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    sc0 = 1.0
    sc1 = 2.0
    sc2 = 3.0
    sc3 = 4.0
    sc4 = 5.0
    sc5 = 6.0
    sc6 = 7.0
    sc7 = 8.0

    def epi(
        accum,
        In0,
        In1,
        In2,
        In3,
        In4,
        In5,
        In6,
        In7,
        sc0,
        sc1,
        sc2,
        sc3,
        sc4,
        sc5,
        sc6,
        sc7,
    ):
        Out0 = accum * sc0 + In0
        Out1 = Out0 + In1 * sc1
        Out2 = Out1 - In2 * sc2
        Out3 = Out2 + In3 * sc3
        Out4 = Out3 - In4 * sc4
        Out5 = Out4 + In5 * sc5
        Out6 = Out5 - In6 * sc6
        D = Out6 + In7 * sc7
        return Out0, Out1, Out2, Out3, Out4, Out5, Out6, D

    epi_args = ops.EpilogueArguments(
        epi,
        In0=In0,
        In1=In1,
        In2=In2,
        In3=In3,
        In4=In4,
        In5=In5,
        In6=In6,
        In7=In7,
        Out0=Out0,
        Out1=Out1,
        Out2=Out2,
        Out3=Out3,
        Out4=Out4,
        Out5=Out5,
        Out6=Out6,
        D=D,
        sc0=sc0,
        sc1=sc1,
        sc2=sc2,
        sc3=sc3,
        sc4=sc4,
        sc5=sc5,
        sc6=sc6,
        sc7=sc7,
    )
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(
        A @ B,
        In0,
        In1,
        In2,
        In3,
        In4,
        In5,
        In6,
        In7,
        sc0,
        sc1,
        sc2,
        sc3,
        sc4,
        sc5,
        sc6,
        sc7,
    )

    for out, ref in zip([Out0, Out1, Out2, Out3, Out4, Out5, Out6, D], reference):
        assert_close_with_reference_conversion(out, ref, out.dtype)


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_row_reduction(fixture_toggle_tvm_ffi):
    """Row reduction (reduce M, keep N): per-column max over the GEMM output.

    ``max(accum, dim=[0])`` folds the M axis, leaving an (N,) result whose
    destination has strideMN (0, 1) -> RowReductionImpl -> the EFC kept-axis
    reduction with subscript ``[:, 0, :]``.  Max is order-independent, so the
    result matches the reference exactly.
    """
    M, N, K = 256, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N), device="cuda", dtype=torch.float32)
    # Max identity: start at -inf so atomic max composes correctly.
    col_max = torch.full((N,), float("-inf"), device="cuda", dtype=torch.float32)

    epi_str = (
        "def epi(accum): D = accum; col_max = max(accum, dim=[0]); return D, col_max"
    )

    epi_args = ops.EpilogueArguments(epi_str, col_max=col_max, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    ref_accum = A.float() @ B.float()
    torch.testing.assert_close(D, ref_accum)
    torch.testing.assert_close(col_max, ref_accum.amax(dim=0))


def _row_reduction_epi(accum):
    # The epilogue is never executed as Python: the tracer parses its source
    # (``inspect.getsource``), so ``max`` here resolves to the DAGIR reduction
    # op, not ``builtins.max``.  Outputs are assigned in the body, not taken
    # as parameters (a reassigned parameter would break the tracer's SSA rule).
    D = accum
    col_max = max(accum, dim=[0])  # noqa: F821 -- traced, not executed.
    return D, col_max


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_row_reduction_callable_epilogue(fixture_toggle_tvm_ffi):
    """The row-reduction epilogue passed as a Python callable, not a string.

    Twin of ``test_gemm_fusion_row_reduction``: same reduction, but the
    epilogue is the function object ``_row_reduction_epi`` so the
    ``inspect.getsource`` half of the tracer is covered for reductions --
    every other reduction test passes the epilogue as a source string.
    """
    M, N, K = 256, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N), device="cuda", dtype=torch.float32)
    # Max identity: start at -inf so atomic max composes correctly.
    col_max = torch.full((N,), float("-inf"), device="cuda", dtype=torch.float32)

    epi_args = ops.EpilogueArguments(_row_reduction_epi, col_max=col_max, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    ref_accum = A.float() @ B.float()
    torch.testing.assert_close(D, ref_accum)
    torch.testing.assert_close(col_max, ref_accum.amax(dim=0))


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_column_reduction(fixture_toggle_tvm_ffi):
    """Column reduction (reduce N, keep M): per-row max over the GEMM output.

    ``max(accum, dim=[1])`` folds the N axis, leaving a per-row (M,)
    result.  N spans four and M two 128-wide MMA tiles, so this covers
    the keep-M direct atomic scatter (``_emit_axis_reduce``,
    subscript ``[0, :, :]``) and its per-M-tile offset.

    The destination is a column-major ``(M, 1)`` on purpose: the fusion
    front-end infers a reduction's kept axis from the destination
    *layout*, not from the ``dim=`` argument.  A bare 1-D ``(M,)`` buffer
    is ambiguous and defaults to the N axis (``RowReductionImpl``), which
    folds the wrong axis and, when M != N, raises ``Invalid Broadcast``
    in ``layout_algorithm._broadcast``.  A 2-D ``(M, 1)`` carries
    strideMN ``(1, 0)`` -> ``ColumnReductionImpl`` -> keep M, but it must
    be column-major (M-dim stride 1) so its leading dimension is
    unambiguous: a *contiguous* ``(M, 1)`` has both strides equal (the
    size-1 dim is degenerate) and the non-tvm tensor path rejects it
    with ``Invalid leading dimension``.  (Row reduction keeps N, the
    default, so its dest can stay 1-D -- see
    ``test_gemm_fusion_row_reduction``.)
    """
    M, N, K = 256, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N), device="cuda", dtype=torch.float32)
    # Column-major (M, 1) so the front-end keeps M (see docstring); -inf
    # is the max identity.
    row_max = torch.empty_strided(
        (M, 1), (1, M), device="cuda", dtype=torch.float32
    ).fill_(float("-inf"))

    epi_str = (
        "def epi(accum): D = accum; row_max = max(accum, dim=[1]); return D, row_max"
    )

    epi_args = ops.EpilogueArguments(epi_str, row_max=row_max, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    ref_accum = A.float() @ B.float()
    torch.testing.assert_close(D, ref_accum)
    torch.testing.assert_close(row_max, ref_accum.amax(dim=1, keepdim=True))


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_scalar_sum_reduction(fixture_toggle_tvm_ffi):
    """Scalar sum reduction: a single float32 scalar accumulates the sum of all GEMM output elements.

    Uses atomic float32 additions across warpgroups.  The sum result may differ
    slightly from a sequential reference due to non-associativity of floating-point
    addition, so a loose tolerance is applied to the scalar output only.
    """
    M = 256
    N = 512
    K = 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N), device="cuda", dtype=torch.float32)
    # Sum identity: start at 0 so atomic additions accumulate correctly.
    total = torch.zeros(1, device="cuda", dtype=torch.float32)

    epi_str = "def epi(accum): D = accum; total = sum(accum); return D, total"

    epi_args = ops.EpilogueArguments(epi_str, total=total, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    ref_accum = A.float() @ B.float()
    torch.testing.assert_close(D, ref_accum)
    # Non-associative float32 atomic adds may reorder partial sums across tiles.
    torch.testing.assert_close(total, ref_accum.sum().unsqueeze(0), rtol=1e-2, atol=1.0)


@pytest.mark.parametrize(
    "epi_str, dest_name, dest_shape, dest_fill, reference",
    [
        (
            "def epi(accum): D = accum; total = sum(accum); return D, total",
            "total",
            (1,),
            0.0,
            lambda acc: acc.sum().unsqueeze(0),
        ),
        (
            "def epi(accum): D = accum; col_max = max(accum, dim=[0]); return D, col_max",
            "col_max",
            (512,),
            float("-inf"),
            lambda acc: acc.amax(dim=0),
        ),
    ],
    ids=["scalar_sum", "column_max"],
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_reduction_with_direct_store(
    epi_str, dest_name, dest_shape, dest_fill, reference, fixture_toggle_tvm_ffi
):
    """A reduction next to a D stored through ``SYNC_GMEM_STORE``.

    When every written tensor takes the direct store, the accumulator keeps
    its T2R register layout and the EFC kernel must not retile it (the
    retile of an already-T2R fragment aliases every register 32 times).
    The scalar sum came out 32x too large and the column max failed to
    trace with a fragment shape mismatch before that was fixed.
    """
    M, N, K = 256, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N), device="cuda", dtype=torch.float32)
    dest = torch.full(dest_shape, dest_fill, device="cuda", dtype=torch.float32)
    epi_args = ops.EpilogueArguments(
        epi_str,
        **{dest_name: dest},
        D=ops.Store(D, via=ops.Transport.SYNC_GMEM_STORE),
    )
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0
    operators[0].run(args)
    ref_accum = A.float() @ B.float()
    torch.testing.assert_close(D, ref_accum)
    # The integer-valued inputs make the sum exact up to atomic ordering.
    torch.testing.assert_close(dest, reference(ref_accum), rtol=1e-2, atol=1.0)


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_scalar_max_reduction(fixture_toggle_tvm_ffi):
    """Scalar max reduction: a single float32 scalar holds the maximum GEMM output element.

    Floating-point max is order-independent, so the result is bit-exact with
    the CPU reference.
    """
    M = 256
    N = 512
    K = 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N), device="cuda", dtype=torch.float32)
    # Max identity: start at -inf so atomic max operations find the true maximum.
    max_val = torch.full((1,), float("-inf"), device="cuda", dtype=torch.float32)

    epi_str = "def epi(accum): D = accum; max_val = max(accum); return D, max_val"

    epi_args = ops.EpilogueArguments(epi_str, max_val=max_val, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    ref_accum = A.float() @ B.float()
    torch.testing.assert_close(D, ref_accum)
    # Floating-point max is commutative and associative, so this is bit-exact.
    torch.testing.assert_close(max_val, ref_accum.max().unsqueeze(0))


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_scalar_min_reduction(fixture_toggle_tvm_ffi):
    """Scalar min reduction: a single float32 scalar holds the minimum GEMM output element.

    The ``min`` twin of ``test_gemm_fusion_scalar_max_reduction``: min is the
    one reduction whose device fold has no native float atomic, so it
    exercises the bitcast-based atomic-fmin path end to end.  Min is
    order-independent, so the result is bit-exact with the CPU reference.
    """
    M = 256
    N = 512
    K = 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N), device="cuda", dtype=torch.float32)
    # Min identity: start at +inf so atomic min operations find the true minimum.
    min_val = torch.full((1,), float("inf"), device="cuda", dtype=torch.float32)

    epi_str = "def epi(accum): D = accum; min_val = min(accum); return D, min_val"

    epi_args = ops.EpilogueArguments(epi_str, min_val=min_val, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    ref_accum = A.float() @ B.float()
    torch.testing.assert_close(D, ref_accum)
    # Floating-point min is commutative and associative, so this is bit-exact.
    torch.testing.assert_close(min_val, ref_accum.min().unsqueeze(0))


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_row_reduction_min(fixture_toggle_tvm_ffi):
    """Kept-axis min: per-column minima of the GEMM output into a (N,) vector.

    The ``min`` twin of ``test_gemm_fusion_row_reduction``, covering the
    kept-axis (SMEM-staged / atomic-scatter) fold with the bitcast-based
    atomic-fmin.  Min is order-independent, so the result is bit-exact.
    """
    M, N, K = 256, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N), device="cuda", dtype=torch.float32)
    # Min identity: start at +inf so atomic min composes correctly.
    col_min = torch.full((N,), float("inf"), device="cuda", dtype=torch.float32)

    epi_str = (
        "def epi(accum): D = accum; col_min = min(accum, dim=[0]); return D, col_min"
    )

    epi_args = ops.EpilogueArguments(epi_str, col_min=col_min, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    ref_accum = A.float() @ B.float()
    torch.testing.assert_close(D, ref_accum)
    torch.testing.assert_close(col_min, ref_accum.amin(dim=0))


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_column_broadcast(M, N, K, L, ab_dtype, d_dtype, accumulator_type):
    """Column broadcast: bias shape (L, M, 1) is broadcast along N."""
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    bias = torch.randint(-1, 2, (L, M, 1), device="cuda", dtype=d_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, bias):
        D = accum + bias
        return D

    epi_args = ops.EpilogueArguments(epi, bias=bias, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B, bias)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_row_broadcast(M, N, K, L, ab_dtype, d_dtype, accumulator_type):
    """Row broadcast: bias shape (N,) is broadcast along L and M."""
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    bias = torch.randint(-1, 2, (N,), device="cuda", dtype=d_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, bias):
        D = accum + bias
        return D

    epi_args = ops.EpilogueArguments(epi, bias=bias, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B, bias)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", [(256, 512, 128, 2)])
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.parametrize("unary_str, unary_op", [identity, relu])
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_broadcast_with_activation(
    M, N, K, L, ab_dtype, d_dtype, accumulator_type, unary_str, unary_op
):
    """Broadcast combined with activation and scalar: D = activation(alpha * accum + bias)."""
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    col_bias = torch.randint(-1, 2, (L, M, 1), device="cuda", dtype=d_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, col_bias, alpha):
        D = unary_op(alpha * accum + col_bias)
        return D

    alpha = 0.5
    epi_str = f"def epi(accum, col_bias, alpha): D = {unary_str}(alpha * accum + col_bias); return D"

    epi_args = ops.EpilogueArguments(epi_str, col_bias=col_bias, alpha=alpha, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B, col_bias, alpha)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_row_broadcast_2d(M, N, K, L, ab_dtype, d_dtype, accumulator_type):
    """Row broadcast with rank-2 bias (1, N) — size-1 batch dim is broadcast."""
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    bias = torch.randint(-1, 2, (1, N), device="cuda", dtype=d_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, bias):
        D = accum + bias
        return D

    epi_args = ops.EpilogueArguments(epi, bias=bias, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B, bias)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_column_broadcast_2d(
    M, N, K, L, ab_dtype, d_dtype, accumulator_type
):
    """Column broadcast with rank-2 bias (M, 1) — common bias-per-row pattern."""
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    bias = torch.randint(-1, 2, (M, 1), device="cuda", dtype=d_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, bias):
        D = accum + bias
        return D

    epi_args = ops.EpilogueArguments(epi, bias=bias, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B, bias)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", [(256, 512, 128, 2)])
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_row_broadcast_with_scalar_multiply(
    M, N, K, L, ab_dtype, d_dtype, accumulator_type
):
    """Row broadcast combined with scalar multiply: D = accum * alpha + bias."""
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    bias = torch.randint(-1, 2, (N,), device="cuda", dtype=d_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    def epi(accum, bias, alpha):
        D = accum * alpha + bias
        return D

    alpha = 0.5
    epi_args = ops.EpilogueArguments(epi, bias=bias, alpha=alpha, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi(A @ B, bias, alpha)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize("M, N, K, L", [(256, 512, 128, 2)])
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_both_row_and_col_broadcast(
    M, N, K, L, ab_dtype, d_dtype, accumulator_type
):
    """Both row and column broadcast in a single epilogue: D = accum + row_bias + col_bias."""
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    row_bias = torch.randint(-1, 2, (N,), device="cuda", dtype=d_dtype)
    col_bias = torch.randint(-1, 2, (L, M, 1), device="cuda", dtype=d_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=d_dtype)

    epi_str = (
        "def epi(accum, row_bias, col_bias): D = accum + row_bias + col_bias; return D"
    )

    def epi_ref(accum, row_bias, col_bias):
        return accum + row_bias + col_bias

    epi_args = ops.EpilogueArguments(epi_str, row_bias=row_bias, col_bias=col_bias, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = epi_ref(A @ B, row_bias, col_bias)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.parametrize(
    "dest_dtype, accepted",
    [(torch.float32, True), (torch.bfloat16, False), (torch.float16, False)],
    ids=["f32", "bf16", "f16"],
)
def test_gemm_efc_reduce_destination_must_be_32bit(dest_dtype, accepted):
    """Reduce destinations must be 32-bit (see the EpilogueArguments docs):
    discovery offers no operator for a narrower one instead of compiling a
    fold that would narrow the result.  The f32 case is the positive
    control that keeps the rejections from passing vacuously."""
    M, N, K = 256, 256, 128
    A = torch.empty((M, K), device="cpu", dtype=torch.float16)
    B = torch.empty((K, N), device="cpu", dtype=torch.float16)
    D = torch.empty((M, N), device="cpu", dtype=torch.float32)
    col_max = torch.full((N,), float("-inf"), device="cpu", dtype=dest_dtype)

    epi_str = (
        "def epi(accum): D = accum; col_max = max(accum, dim=[0]); return D, col_max"
    )
    epi_args = ops.EpilogueArguments(epi_str, col_max=col_max, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args)
    assert bool(operators) is accepted


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_efc_mixed_fp8_dtypes():
    """Mixed fp8 A/B (e4m3 x e5m2) through a fused epilogue: the f8f6f4 MMA
    kind decodes each operand's format independently."""
    M, N, K, L = 256, 512, 128, 2
    A, B, A_ref, B_ref = small_integer_gemm_inputs(
        M, N, K, L, b_dtype=torch.float8_e5m2
    )
    D = torch.empty((L, M, N), device="cuda", dtype=torch.bfloat16)

    epi_args = ops.EpilogueArguments("def epi(accum): D = relu(accum); return D", D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0
    operators[0].run(args)

    reference = torch.relu(A_ref @ B_ref)
    assert_close_with_reference_conversion(D, reference, D.dtype)


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_efc_fusion_narrow_store_wider_reduce():
    """A reduce destination wider than every stored output (f32 column-max
    with a bf16 D).  Pins two things: the tiling reference skips reduce
    destinations, and the fold runs at the destination's f32 precision even
    though the operator computes the epilogue in the bf16 out dtype."""
    M, N, K = 512, 512, 512
    device = reference_device()
    A_ref = torch.randint(-1, 2, (M, K), device=device, dtype=torch.float32)
    B_ref = torch.randint(-1, 2, (K, N), device=device, dtype=torch.float32)
    A = A_ref.to(torch.float8_e4m3fn).cuda()
    B = B_ref.to(torch.float8_e4m3fn).cuda()
    D = torch.empty((M, N), device="cuda", dtype=torch.bfloat16)
    # Max identity: start at -inf so atomic max composes correctly.
    col_max = torch.full((N,), float("-inf"), device="cuda", dtype=torch.float32)

    epi_str = (
        "def epi(accum): D = accum; col_max = max(accum, dim=[0]); return D, col_max"
    )
    epi_args = ops.EpilogueArguments(epi_str, col_max=col_max, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0
    operators[0].run(args)

    ref_accum = A_ref @ B_ref
    assert_close_with_reference_conversion(D, ref_accum, D.dtype)
    # The operator computes the epilogue in out.dtype (bf16), so the values
    # entering the reduce are bf16-rounded; the fold itself runs at the
    # destination's f32 precision.  (Integer-valued inputs make the bf16
    # rounding exact here, but the reference states the true contract.)
    epi_ref = ref_accum.to(torch.bfloat16).float()
    assert_close_with_reference_conversion(col_max, epi_ref.amax(dim=0), col_max.dtype)


# ---------------------------------------------------------------------------
# SM107 (Rubin) fp8 EFC operator
# ---------------------------------------------------------------------------
@pytest.mark.skipif(
    not device_or_env_supports("107f"),
    reason="Requires the Rubin fp8 MMA (sm_107)",
)
def test_gemm_sm107_fp8_fusion():
    """A scaled-relu epilogue fuses into an fp8 GEMM on Rubin.  Discovery is
    pinned to the Rubin operator: the Blackwell EFC operator is family-portable
    to sm107 and would otherwise be picked first."""
    M, N, K, L = 512, 512, 512, 1
    A, B, A_ref, B_ref = small_integer_gemm_inputs(M, N, K, L)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.bfloat16)

    epi_str = "def epi(accum, alpha): D = relu(accum * alpha); return D"
    epi_args = ops.EpilogueArguments(epi_str, D=D, alpha=2.0)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )

    def rubin_efc_only(metadata):
        return metadata.operator_class is Sm107PersistentDenseGemmEFCOperator

    operators = ops.get_operators(
        args, target_sm=device_or_env_target_sm(), metadata_filter=rubin_efc_only
    )
    assert len(operators) > 0
    operators[0].run(args)

    reference = torch.relu((A_ref @ B_ref) * 2.0)
    assert_close_with_reference_conversion(D, reference, D.dtype)


def gated_data_types():
    """(A/B, accumulator, D) combinations a gated epilogue supports.

    Every A/B and accumulator pairing the operator declares in
    ``_valid_ab_acc_combinations``, crossed with the D types it stores,
    less two families:

    * integer accumulators (Uint8/Int8 -> Int32), since a gate activation
      on an integer accumulator is not meaningful;
    * D wider than the accumulator, which the epilogue rejects on its own
      ("Can not handle acc/d type combination"), independently of gating.
    """
    combinations = []
    for ab_dtype, accumulator_type in [
        (torch.float16, torch.float16),
        (torch.float16, torch.float32),
        (torch.bfloat16, torch.float32),
        (torch.float8_e4m3fn, torch.float16),
        (torch.float8_e4m3fn, torch.float32),
        (torch.float8_e5m2, torch.float16),
        (torch.float8_e5m2, torch.float32),
    ]:
        for d_dtype in [torch.float16, torch.bfloat16, torch.float32]:
            if accumulator_type is torch.float16 and d_dtype is torch.float32:
                continue
            combinations.append((ab_dtype, accumulator_type, d_dtype))
    return combinations


def gated_problem_sizes():
    """Problem sizes spanning many N tiles for a gated epilogue.

    N grows rather than K.  N is the axis the narrowed store is tiled
    along, so it is what exercises the tile offsets, whereas the gated
    product is quadratic in K and would overflow a float16 D beyond a few
    hundred K with the +/-1 operands used here.

    Ordered by decreasing size.  This is the innermost parametrisation, so
    the order repeats within every dtype group, and running each group's
    longest case first is what keeps one from being picked up at the end
    and extending the whole run by its own duration.  ``--dist=worksteal``
    rebalances a bad split but cannot reorder work that has already
    started, so the sort is what bounds the tail.
    """
    return [(512, 4096, 128, 2), (1024, 2048, 128, 1)]


def gated_operands(M, N, K, L, ab_dtype, d_dtype):
    """Build A, B and a half-width D.

    ``randint`` cannot produce fp8, so the operands are drawn in float32
    and cast.
    """
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.float32).to(ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=torch.float32).to(ab_dtype)
    D = torch.empty((L, M, N // 2), device="cuda", dtype=d_dtype)
    return A, B, D


def gated_reference(A, B, accumulator_type, d_dtype, gate_fn):
    """The gated result along the kernel's numeric path: accumulate, round
    to the accumulator type, then gate the even N indices with the odd.

    The gate is evaluated in float32 even though the kernel loads the
    split parts into D's dtype: the kernel widens a narrow part back to
    float32 for the activation and rounds once, torch's rule for
    half-precision inputs, so a reference that gates at the storage
    precision lands *farther* from the kernel.
    """
    accum = (A.float() @ B.float()).to(accumulator_type).float()
    return (accum[..., 1::2] * gate_fn(accum[..., 0::2])).to(d_dtype)


#: Each gate activation as the kernel computes it.  EFC's gelu is the erf
#: form, torch's default.
GATE_FUNCTIONS = {
    "swiglu": torch.nn.functional.silu,
    "geglu": torch.nn.functional.gelu,
    "reglu": torch.nn.functional.relu,
}


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="The gated epilogue is provided by the SM100 EFC operator",
)
@pytest.mark.parametrize("gate", ["swiglu", "geglu", "reglu"])
def test_gemm_gated_linear_unit(gate, fixture_toggle_tvm_ffi):
    """A gated linear unit fused onto a single MMA.

    ``B`` holds the gate and up projections interleaved along N, so one
    GEMM produces both and the epilogue pairs them.  ``D`` is therefore
    half of B's N -- the one epilogue where the output is not the
    accumulator's shape.
    """
    M, N, K, L = 256, 512, 128, 2
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((L, M, N // 2), device="cuda", dtype=torch.float16)

    epi_str = f"def epi(accum): D = {gate}(accum); return D"
    epi_args = ops.EpilogueArguments(epi_str, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = gated_reference(A, B, torch.float32, D.dtype, GATE_FUNCTIONS[gate])

    # The activations go through the hardware's fast transcendentals, which
    # cannot be matched bit-for-bit.
    rtol, atol = get_torch_default_tolerances()[D.dtype]
    assert_close_with_reference_conversion(
        D, reference, D.dtype, rtols=rtol, atols=atol
    )


def test_gemm_plain_epilogue_rejects_wrong_out_n():
    """A wrong-N ``out`` fails before the epilogue is traced.

    Tracing binds ``out``'s shape into the epilogue's shape propagation,
    so without the pre-trace check the mismatch surfaces as a broadcast
    error that names neither ``out`` nor B.
    """
    M, N, K = 256, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N - 12), device="cuda", dtype=torch.float16)

    epi_args = ops.EpilogueArguments("def epi(accum): D = relu(accum); return D", D=D)
    with pytest.raises(ValueError, match=rf"{N - 12}.*{N}"):
        ops.GemmArguments(
            A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
        )


def test_gemm_gated_linear_unit_rejects_full_width_output():
    """``out`` has to be half of B's N when the epilogue gates.

    A full-width ``out`` is rejected while the epilogue is traced -- the
    store cannot reconcile its own N with the gated value's -- rather than
    silently leaving half the tensor unwritten.  The rejection names both
    extents and the gating, which is what this matches on.
    """
    M, N, K = 256, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N), device="cuda", dtype=torch.float16)  # not halved

    epi_args = ops.EpilogueArguments("def epi(accum): D = swiglu(accum); return D", D=D)
    with pytest.raises(ValueError, match=rf"{N}.*{N // 2}.*gated"):
        ops.GemmArguments(
            A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
        )


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="The gated epilogue is provided by the SM100 EFC operator",
)
@pytest.mark.L0(False)
@pytest.mark.parametrize("M, N, K, L", gated_problem_sizes())
@pytest.mark.parametrize(
    "ab_dtype, accumulator_type, d_dtype",
    gated_data_types(),
    ids=lambda dtype: str(dtype).removeprefix("torch."),
)
@pytest.mark.parametrize("gate", ["swiglu", "geglu", "reglu"])
def test_gemm_gated_linear_unit_dtypes(
    gate, ab_dtype, accumulator_type, d_dtype, M, N, K, L
):
    """A gated linear unit over every supported dtype, at MLP-sized N.

    Excluded from L0: this is the whole ``gated_data_types`` matrix
    crossed with problem sizes spanning many N tiles, which is where a
    narrowed store's tile offsets are exercised but which costs far more
    than the L0 budget allows.  ``test_gemm_gated_linear_unit`` remains
    the L0 smoke test.
    """
    A, B, D = gated_operands(M, N, K, L, ab_dtype, d_dtype)

    epi_str = f"def epi(accum): D = {gate}(accum); return D"
    epi_args = ops.EpilogueArguments(epi_str, D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    reference = gated_reference(A, B, accumulator_type, d_dtype, GATE_FUNCTIONS[gate])
    rtol, atol = get_torch_default_tolerances()[d_dtype]
    assert_close_with_reference_conversion(
        D, reference, d_dtype, rtols=rtol, atols=atol
    )


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="The gated epilogue is provided by the SM100 EFC operator",
)
def test_gemm_gated_linear_unit_offers_all_designs():
    """Discovery offers a gated epilogue on every design a plain one gets.

    The narrowed store follows the accumulator's own thread-to-value map
    (in registers where the map permits, through a cross-lane gather
    where each thread holds only one part's columns), so no design is
    withheld from a gated epilogue: an MMA tiler M of 64 and 2-CTA below
    an N tile of 128 store correctly.  Equality against the
    plain-epilogue design set is what pins that no fusion-specific
    filter exists.
    """
    M, N, K = 256, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)

    def offered_designs(epilogue_source, out_n):
        out = torch.empty((M, out_n), device="cuda", dtype=torch.float16)
        args = ops.GemmArguments(
            A,
            B,
            out,
            accumulator_type=torch.float32,
            epilogue=ops.EpilogueArguments(epilogue_source, D=out),
        )
        # (use_2cta_mma, MMA tiler M, MMA tiler N)
        return {
            (
                o.metadata.design.use_2cta_mma,
                o.metadata.design.tile_shape[0],
                o.metadata.design.tile_shape[1],
            )
            for o in ops.get_operators(args, target_sm=device_or_env_target_sm())
            if o.metadata.operator_class is Sm100PersistentDenseGemmEFCOperator
        }

    gated = offered_designs("def epi(accum): D = swiglu(accum); return D", N // 2)
    plain = offered_designs("def epi(accum): D = relu(accum); return D", N)

    assert gated == plain
    # The families needing special store handling are present.
    assert [design for design in gated if design[1] == 64]
    assert [design for design in gated if design[0] and design[2] < 128]


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="The gated epilogue is provided by the SM100 EFC operator",
)
@pytest.mark.parametrize(
    "family",
    ["tiler_m_64", "2cta_tiler_n_below_128"],
)
def test_gemm_gated_linear_unit_design_families(family):
    """The design families whose narrowed store needs its own handling.

    An MMA tiler M of 64 gives each thread only one part's columns, so
    the parts are gathered from other lanes; 2-CTA below an N tile of
    128 sizes the store fragment from the accumulator's own map.  Both
    families are selected here by their metadata rather than by taking
    ``operators[0]``, so this coverage does not depend on how discovery
    ranks the designs.
    """

    def wanted(design):
        if family == "tiler_m_64":
            return not design.use_2cta_mma and design.tile_shape[0] == 64
        return design.use_2cta_mma and design.tile_shape[1] < 128

    M, N, K = 256, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N // 2), device="cuda", dtype=torch.float16)

    epi_args = ops.EpilogueArguments("def epi(accum): D = swiglu(accum); return D", D=D)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = [
        o
        for o in ops.get_operators(args, target_sm=device_or_env_target_sm())
        if o.metadata.operator_class is Sm100PersistentDenseGemmEFCOperator
        and wanted(o.metadata.design)
    ]
    assert operators, f"no {family} design offered"
    operators[0].run(args)

    reference = gated_reference(A, B, torch.float32, D.dtype, GATE_FUNCTIONS["swiglu"])
    rtol, atol = get_torch_default_tolerances()[D.dtype]
    assert_close_with_reference_conversion(
        D, reference, D.dtype, rtols=rtol, atols=atol
    )


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="The gated epilogue is provided by the SM100 EFC operator",
)
def test_gemm_gated_linear_unit_rejects_direct_store():
    """A gated output cannot use a direct (non-TMA) store transport.

    The direct store drains the accumulator-shaped fragment at full
    width and has no narrowed variant, so a gated output must go through
    TMA.  The framework says so rather than storing the wrong elements,
    and this checks the Python API surfaces that.
    """
    M, N, K = 256, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N // 2), device="cuda", dtype=torch.float16)

    epi_args = ops.EpilogueArguments(
        "def epi(accum): D = swiglu(accum); return D",
        D=ops.Store(D, via=ops.Transport.SYNC_GMEM_STORE),
    )
    args = ops.GemmArguments(A, B, D, accumulator_type=torch.float32, epilogue=epi_args)
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0

    with pytest.raises(ValueError, match="accum_split"):
        operators[0].run(args)


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="The gated epilogue is provided by the SM100 EFC operator",
)
def test_gemm_gated_linear_unit_beside_full_width_output():
    """A gated output and a full-width one in the same epilogue.

    D is half of B's N and E is all of it, so the kernel holds two
    supplemental tensors tiled differently at once -- the case where a
    per-tensor tiler that leaked between them would show up.  It also
    covers the only path where ``out`` is narrowed while another output
    is not.
    """
    M, N, K, L = 256, 512, 128, 2
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((L, M, N // 2), device="cuda", dtype=torch.float16)
    E = torch.empty((L, M, N), device="cuda", dtype=torch.float16)

    epi_str = (
        "def epi(accum):\n    D = swiglu(accum)\n    E = relu(accum)\n    return D, E\n"
    )
    epi_args = ops.EpilogueArguments(epi_str, D=D, E=E)
    args = ops.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float32, epilogue=epi_args
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())

    assert len(operators) > 0
    operators[0].run(args)

    accum = (A.float() @ B.float()).to(torch.float32)
    rtol, atol = get_torch_default_tolerances()[D.dtype]
    assert_close_with_reference_conversion(
        D,
        gated_reference(A, B, torch.float32, D.dtype, GATE_FUNCTIONS["swiglu"]),
        D.dtype,
        rtols=rtol,
        atols=atol,
    )
    assert_close_with_reference_conversion(
        E, torch.relu(accum).to(E.dtype), E.dtype, rtols=rtol, atols=atol
    )


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and sm_100a or sm_100f",
)
@pytest.mark.parametrize(
    "epilogue",
    ["bias_relu", "scaled_relu_colmax", "residual_add", "bf16_scaled_relu"],
)
def test_mxfp8_gemm_fusion(epilogue):
    """MXFP8 scaled operands take the same fused-epilogue path as dense GEMM.

    ``ScaledOperand`` A/B (fp8 quantized values, E8M0 block scales over 32 K
    elements in the swizzled layout) plus an ``EpilogueArguments`` resolve to
    the block-scaled EFC operator, which runs the fused epilogue bit-exactly
    against the scaled fp32 reference: a broadcast bias with relu, a scaled
    relu with a column-max reduction, a residual add from an output-shaped
    tensor, and a bf16 output.  The operator computes the epilogue in the
    output dtype, so the f32-D cases keep the adds on these large scaled
    accumulators exact, and the bf16 case uses ``relu(accum * 2)``: doubling
    only changes the exponent, so rounding to bf16 before or after it gives
    the same bits.
    """
    from test_utils.gemm import (
        mxfp8_integer_inputs,
        mxfp8_reference,
        mxfp8_scaled_operands,
    )

    M, N, K = 256, 512, 1024
    A, B, SFA, SFB = mxfp8_integer_inputs(M, N, K)
    accum = mxfp8_reference(A, B, SFA, SFB, torch.float32)
    d_dtype = torch.bfloat16 if epilogue == "bf16_scaled_relu" else torch.float32
    D = torch.empty((M, N), device="cuda", dtype=d_dtype)
    extra_checks = []
    if epilogue == "bias_relu":
        bias = torch.randint(-4, 5, (N,), device="cuda").to(torch.float32)
        epi_args = ops.EpilogueArguments(
            "def epi(accum, bias): D = relu(accum + bias); return D", D=D, bias=bias
        )
        reference = torch.relu(accum + bias)
    elif epilogue == "scaled_relu_colmax":
        col_max = torch.full((N,), float("-inf"), device="cuda", dtype=torch.float32)
        epi_args = ops.EpilogueArguments(
            "def epi(accum, alpha): "
            "D = relu(accum * alpha); col_max = max(accum, dim=[0]); return D, col_max",
            D=D,
            alpha=2.0,
            col_max=col_max,
        )
        reference = torch.relu(accum * 2.0)
        extra_checks.append(
            lambda: torch.testing.assert_close(
                col_max, accum.amax(dim=0), atol=0.0, rtol=0.0
            )
        )
    elif epilogue == "residual_add":
        C = torch.randint(-4, 5, (M, N), device="cuda").to(torch.float32)
        epi_args = ops.EpilogueArguments(
            "def epi(accum, C): D = accum + C; return D", D=D, C=C
        )
        reference = accum + C
    else:
        epi_args = ops.EpilogueArguments(
            "def epi(accum, alpha): D = relu(accum * alpha); return D", D=D, alpha=2.0
        )
        reference = torch.relu(accum * 2.0)
    args = ops.GemmArguments(
        *mxfp8_scaled_operands(A, B, SFA, SFB),
        out=D,
        accumulator_type=torch.float32,
        epilogue=epi_args,
    )
    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert operators
    assert all("BlockScaledGemmEFC" in o.metadata.operator_name for o in operators)
    operators[0].run(args)

    assert_close_with_reference_conversion(D, reference, D.dtype)
    for check in extra_checks:
        check()
