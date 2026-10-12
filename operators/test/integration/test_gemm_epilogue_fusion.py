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
    PersistentDenseGemmEFCOperator,
)
from cutlass.operators.utils.device import (
    device_or_env_supports,
    device_or_env_target_sm,
)

from test_utils import assert_close_with_reference_conversion
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
        return metadata.operator_class is PersistentDenseGemmEFCOperator

    args = ops.GemmArguments(A, B, D, accumulator_type=torch.float16)
    operators = ops.get_operators(
        args, target_sm=device_or_env_target_sm(), metadata_filter=metadata_filter
    )
    assert len(operators) > 0
    operators[0].run(args)

    reference = A @ B
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
