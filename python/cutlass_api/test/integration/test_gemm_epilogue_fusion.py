# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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


import os

import pytest
import torch

import cutlass_api
from cutlass_api.config import GlobalOptions
from cutlass_api.utils import is_device_cc_supported

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


def supports_sm100af():
    return is_device_cc_supported({100}) and (
        os.getenv("CUTE_DSL_ARCH", "") in ["", "sm_100a", "sm_100f"]
    )


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


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
# Restrict to D of float16 for now to avoid rounding error when converting torch f16 output to f32
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.parametrize("unary_str, unary_op", unary_ops)
@pytest.mark.skipif(
    not supports_sm100af(),
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

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, D=D)
    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference = epi(A @ B)
    torch.testing.assert_close(D, reference.to(D.dtype))


@pytest.mark.parametrize("M, N, K, L", [(256, 512, 128, 2)])
# Restrict to D of float16 for now to avoid rounding error when converting torch f16 output to f32
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.parametrize("unary_str, unary_op", [relu])
@pytest.mark.parametrize("unary_str2, unary_op2", [sigmoid, tanh])
@pytest.mark.skipif(
    not supports_sm100af(),
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

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, D=D)
    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference = epi(A @ B)
    torch.testing.assert_close(D, reference.to(D.dtype))


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
# Restrict to D of float16 for now to avoid rounding error when converting torch f16 output to f32
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
# Restrict unary to identity and relu to avoid rounding errors
@pytest.mark.parametrize("unary_str, unary_op", [identity, relu])
@pytest.mark.skipif(
    not supports_sm100af(),
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

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, D=D)
    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference = epi(A @ B)
    torch.testing.assert_close(D, reference.to(D.dtype))


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, d_dtype, accumulator_type", base_data_types()
)
@pytest.mark.parametrize("unary_str, unary_op", [identity, relu])
@pytest.mark.parametrize("binary_str, binary_op", binary_ops)
@pytest.mark.skipif(
    not supports_sm100af(),
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

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, C=C, D=D)

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference = epi(A @ B, C)
    torch.testing.assert_close(D, reference.to(D.dtype))


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
    not supports_sm100af(),
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

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, C0=C0, C1=C1, D=D)

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference = epi(A @ B, C0, C1)
    torch.testing.assert_close(D, reference.to(D.dtype))


@pytest.mark.skipif(
    not supports_sm100af(),
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
    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, D=D)

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference = epi(A @ B)
    torch.testing.assert_close(D, reference.to(D.dtype))

    #########################################################
    # Test division by an input
    #########################################################
    def epi(accum, scalar):
        D = accum / scalar
        return D

    epi_str = "def epi(accum, scalar): D = accum / scalar; return D"

    scalar = 4.0
    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, scalar=scalar, D=D)
    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference = epi(A @ B, scalar)

    torch.testing.assert_close(D, reference.to(D.dtype))


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
# Restrict to D of float16 for now to avoid rounding error when converting torch f16 output to f32
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.parametrize("unary_str, unary_op", [sigmoid, tanh])
@pytest.mark.skipif(
    not supports_sm100af(),
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

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, z=z, D=D)

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    ref_D, ref_z = epi(A @ B)
    torch.testing.assert_close(D, ref_D.to(D.dtype))
    torch.testing.assert_close(z, ref_z.to(z.dtype))


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
# Restrict to D of float16 for now to avoid rounding error when converting torch f16 output to f32
@pytest.mark.parametrize(
    "ab_dtype, d_dtype, accumulator_type",
    [(torch.float16, torch.float16, torch.float16)],
)
@pytest.mark.parametrize("c_dtype", [torch.float16, torch.float32])
@pytest.mark.parametrize("binary_str, binary_op", binary_ops)
@pytest.mark.skipif(
    not supports_sm100af(),
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

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, C=C, z=z, D=D)

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    ref_D, ref_z = epi(A @ B, C)
    torch.testing.assert_close(D, ref_D.to(D.dtype))
    torch.testing.assert_close(z, ref_z.to(z.dtype))


@pytest.mark.skipif(
    not supports_sm100af(),
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

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, C=C, D=D, accum=accum)

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference, ref_accum = epi(A @ B, C)
    torch.testing.assert_close(D, reference.to(D.dtype))
    torch.testing.assert_close(accum, ref_accum.to(accum.dtype))


@pytest.mark.skipif(
    not supports_sm100af(),
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

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, C=C, D=D)

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference = epi(A @ B, C)
    torch.testing.assert_close(D, reference.to(D.dtype))

    #########################################################
    # Test unary op inside
    #########################################################
    def epi(accum):
        D = torch.relu(torch.sigmoid(torch.relu(accum))) + accum
        return D

    epi_str = "def epi(accum): D = relu(sigmoid(relu(accum))) + accum; return D"

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, D=D)

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference = epi(A @ B)
    torch.testing.assert_close(D, reference.to(D.dtype))


@pytest.mark.skipif(
    not supports_sm100af(),
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
        D = torch.sigmoid(torch.relu(accum) * C) + A
        return D

    epi_str = "def epi(accum, C, A): D = sigmoid(relu(accum) * C) + A; return D"

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, C=C, A=A, D=D)

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference = epi(A @ B, C, A)
    torch.testing.assert_close(D, reference.to(D.dtype))

    #########################################################
    # Test unary op inside
    #########################################################
    def epi(accum, A):
        D = torch.tanh(torch.relu(accum)) + A
        return D

    epi_str = "def epi(accum, A): D = tanh(relu(accum)) + A; return D"

    epi_args = cutlass_api.arguments.EpilogueArguments(epi_str, A=A, D=D)

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

    reference = epi(A @ B, A)
    torch.testing.assert_close(D, reference.to(D.dtype))


@pytest.mark.parametrize("M, N, K, L", problem_sizes())
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, d_dtype, accumulator_type", base_data_types()
)
@pytest.mark.skipif(
    not supports_sm100af(),
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
    epi_args = cutlass_api.arguments.EpilogueArguments(
        epi, C=C, alpha=alpha, beta=beta, D=D
    )

    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernel = kernels[0]

    for a, b in [(0.5, 0.5), (1.0, 0.0), (0.0, 1.0)]:
        epi_args = cutlass_api.arguments.EpilogueArguments(
            epi, C=C, alpha=a, beta=b, D=D
        )
        args = cutlass_api.arguments.GemmArguments(
            A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
        )
        kernel.run(args)
        reference = epi(A @ B, C, a, b)
        torch.testing.assert_close(D, reference.to(D.dtype))


@pytest.mark.skipif(
    not supports_sm100af(),
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

    epi_args = cutlass_api.arguments.EpilogueArguments(
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
    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=accumulator_type, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernels[0].run(args)

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
        torch.testing.assert_close(out, ref.to(out.dtype))


@pytest.mark.skipif(
    not supports_sm100af(),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_fusion_not_available(fixture_toggle_tvm_ffi):
    M = 256
    N = 512
    K = 1024
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    D = torch.empty((M, N), device="cuda", dtype=torch.float16)

    # Non-scalar broadcasts are currently not supported
    bias = torch.randint(-1, 2, (M, 1), device="cuda", dtype=torch.float16)

    def epi(accum, bias):
        D = accum + bias
        return D

    epi_args = cutlass_api.arguments.EpilogueArguments(epi, bias=bias, D=D)
    args = cutlass_api.arguments.GemmArguments(
        A=A, B=B, out=D, accumulator_type=torch.float16, epilogue=epi_args
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) == 0
