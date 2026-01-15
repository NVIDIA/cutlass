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

from collections.abc import Callable
from importlib.util import find_spec
import os

import pytest
import torch

import cutlass

import cutlass_api
from cutlass_api.arguments import EpilogueArguments, ScaledTensor
from cutlass_api.config import GlobalOptions
from cutlass_api.library import ScaleMode, ScaleSwizzleMode
from cutlass_api.metadata import KernelMetadata, Sm100DesignMetadata
from cutlass_api.utils import ceil_div, is_device_cc_supported, round_up


torch.manual_seed(2025)


def prep_k(K: int, scale_size: int):
    """
    Prepares K mode for requirements needed for 32-4-4 swizzling

    :param K: The value to prepare.
    :type K: int
    :param scale_size: The scale size.
    :type scale_size: int

    :return: The K mode rounded up to the requirements needed for 32-4-4 swizzling
    :rtype: int
    """
    return round_up(ceil_div(K, scale_size), 4)


def reference_scaled_mm(
    A: torch.Tensor,
    B: torch.Tensor,
    scale_A: torch.Tensor,
    scale_B: torch.Tensor,
    out_dtype: torch.dtype,
    transform_sf: Callable[[torch.Tensor], torch.Tensor] = lambda x : x
):
    """
    Computes a reference scaled mm operation. Currently, torch._scaled_mm does not support batch mode.
    When a batch mode is present, this function iterates through each problem in the batch.

    :param A: The A tensor
    :type A: torch.Tensor
    :param B: The B tensor
    :type B: torch.Tensor
    :param scale_A: The scale factor tensor for operand A
    :type scale_A: torch.Tensor
    :param scale_B: The scale factor tensor for operand B
    :type scale_B: torch.Tensor
    :param out_dtype: The output dtype
    :type out_dtype: torch.dtype
    :param transform_sf: A function to transform the scale factor tensors to the correct shape for the scaled mm operation
    :type transform_sf: Callable
    :return: The reference scaled mm operation
    """
    if len(A.shape) == 2:
        return torch._scaled_mm(
            A, B, scale_a=scale_A, scale_b=scale_B, out_dtype=out_dtype
        )
    else:
        # torch._scaled_mm does not support batch mode. Iterate through each problem in the batch
        L, M, N = A.shape[0], A.shape[1], B.shape[2]
        reference = torch.empty((L, M, N), device=A.device, dtype=out_dtype)
        for l in range(L):
            reference[l, :, :] = torch._scaled_mm(
                A[l, :, :],
                B[l, :, :],
                scale_a=transform_sf(scale_A[l, :, :]),
                scale_b=transform_sf(scale_B[l, :, :]),
                out_dtype=out_dtype
            )
        return reference


@pytest.mark.parametrize(
    "M, N, K, L",
    [
        (256, 512, 1024, 1),
        (1024, 640, 512, 2),
        (256, 512, 1024 + 496, 1), # Test where K is not divisible by scale_size (32)
    ],
)
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, accumulator_type, scale_dtype",
    [
        (torch.float8_e4m3fn, torch.float32, torch.float32, torch.float8_e8m0fnu),
        (torch.float8_e5m2, torch.float32, torch.float32, torch.float8_e8m0fnu),
    ],
)
@pytest.mark.skipif(
    not is_device_cc_supported({100, 103})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_103a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_103a",
)
def test_mxfp8_gemm_sm100(
    M: int,
    N: int,
    K: int,
    L: int,
    ab_dtype: torch.dtype,
    c_dtype: torch.dtype,
    accumulator_type: torch.dtype,
    scale_dtype: torch.dtype,
    fixture_enable_tvm_ffi,
):
    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(ab_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)

    # Transpose B because torch._scaled_mm expects B to be column-major
    B = torch.randint(-1, 2, (L, N, K), device="cuda").to(ab_dtype).transpose(1, 2)

    scale_size = 32

    SFA = torch.rand((L, M, prep_k(K, scale_size),), device="cuda").to(scale_dtype)
    SFB = torch.rand((L, prep_k(K, scale_size), N), device="cuda").to(scale_dtype)

    args = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B,
            SFB,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=accumulator_type,
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernel = kernels[0]
    assert kernel.supports(args)
    compiled_artifact = kernel.compile(args)
    kernel.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    # torch._scaled_mm does not support f8e5m2 * f8e5m2 currently.
    # Simply skip reference check in that case (but test that a CUTLASS API kernel
    # is found and runs)
    if ab_dtype != torch.float8_e5m2:
        reference = reference_scaled_mm(A, B, SFA, SFB, c_dtype)
        torch.testing.assert_close(D, reference)


@pytest.mark.skipif(
    not is_device_cc_supported({100, 103})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_103a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_103a",
)
def test_mxfp8_gemm_sm100_fake_tensor(fixture_enable_tvm_ffi):
    import torch._functorch.config

    torch._functorch.config.fake_tensor_allow_unsafe_data_ptr_access = False

    M, N, K, L = 256, 512, 1024, 1
    ab_dtype = torch.float8_e4m3fn
    c_dtype = torch.float32
    accumulator_type = torch.float32
    scale_dtype = torch.float8_e8m0fnu
    scale_size = 32

    with torch._subclasses.fake_tensor.FakeTensorMode():
        A = torch.randint(-1, 2, (L, M, K), device="cuda").to(ab_dtype)
        D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)
        B = torch.randint(-1, 2, (L, N, K), device="cuda").to(ab_dtype).transpose(1, 2)
        SFA = torch.rand(
            (
                L,
                M,
                prep_k(K, scale_size),
            ),
            device="cuda",
        ).to(scale_dtype)
        SFB = torch.rand((L, prep_k(K, scale_size), N), device="cuda").to(scale_dtype)

    fake_args = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B,
            SFB,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=accumulator_type,
    )
    kernels = cutlass_api.get_kernels(fake_args, cc=100)

    assert len(kernels) > 0
    kernel = kernels[0]
    assert kernel.supports(fake_args)
    compiled_artifact = kernel.compile(fake_args)

    A_real = torch.randint(-1, 2, (L, M, K), device="cuda").to(ab_dtype)
    B_real = torch.randint(-1, 2, (L, N, K), device="cuda").to(ab_dtype).transpose(1, 2)
    D_real = torch.empty((L, M, N), device="cuda", dtype=c_dtype)
    SFA_real = torch.rand(
        (
            L,
            M,
            prep_k(K, scale_size),
        ),
        device="cuda",
    ).to(scale_dtype)
    SFB_real = torch.rand((L, prep_k(K, scale_size), N), device="cuda").to(scale_dtype)
    args = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A_real,
            SFA_real,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B_real,
            SFB_real,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D_real,
        accumulator_type=accumulator_type,
    )
    kernel.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    # torch._scaled_mm does not support f8e5m2 * f8e5m2 currently.
    # Simply skip reference check in that case (but test that a CUTLASS API kernel
    # is found and runs)
    if ab_dtype != torch.float8_e5m2:
        reference = reference_scaled_mm(A_real, B_real, SFA_real, SFB_real, c_dtype)
        torch.testing.assert_close(D_real, reference)


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
@pytest.mark.skipif(
    not is_device_cc_supported({100, 103})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_103a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_103a",
)
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

    scale_size = 32
    SFA = torch.rand((M, prep_k(K, scale_size),), device="cuda").to(scale_dtype)
    SFB = torch.rand((prep_k(K, scale_size), N), device="cuda").to(scale_dtype)

    args = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B,
            SFB,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=accumulator_type,
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernel = kernels[0]
    assert kernel.supports(args)
    compiled_artifact = kernel.compile(args)
    kernel.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    reference = reference_scaled_mm(A, B, SFA, SFB, c_dtype)
    torch.testing.assert_close(D, reference)


@pytest.mark.skipif(
    not is_device_cc_supported({100, 103})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_103a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_103a",
)
def test_mxfp8_1d_scale_factors(fixture_enable_tvm_ffi):
    """
    Tests for valid MXFP8 GEMM cases in which A, B, and out are 3D tensors, and the scale factors are 1D tensors.
    """
    M, N, K, L = 256, 512, 1024, 1
    scale_size = 32

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = torch.randint(-1, 2, (L, N, K), device="cuda").to(torch.float8_e4m3fn).transpose(1, 2)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    SFA = torch.rand((L, M, prep_k(K, scale_size),), device="cuda").to(torch.float8_e8m0fnu)
    SFB = torch.rand((L, prep_k(K, scale_size), N), device="cuda").to(torch.float8_e8m0fnu)

    args = cutlass_api.arguments.GemmArguments(
        # Pass in SFA and SFB in flattened form (.view(-1))
        A=ScaledTensor(
            A,
            SFA.view(-1),
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B,
            SFB.view(-1),
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )

    # Only test kernels for which we know there will be an error if the scale factors are invalid
    def metadata_filter(metadata: KernelMetadata):
        return metadata.kernel_class == cutlass_api.providers.cutedsl.gemm.sm100_dense_blockscaled_static_persistent.PersistentDenseBlockScaledGemmKernel

    kernels = cutlass_api.get_kernels(args, cc=100, metadata_filter=metadata_filter)
    assert len(kernels) > 0
    kernel = kernels[0]
    assert kernel.supports(args)
    compiled_artifact = kernel.compile(args)
    kernel.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    def transform_sf(x: torch.Tensor) -> torch.Tensor:
        """Flattens scale factor tensors after indexing into the batch dimension"""
        return x.view(-1)

    reference = reference_scaled_mm(A, B, SFA, SFB, torch.float32, transform_sf)
    torch.testing.assert_close(D, reference)


@pytest.mark.parametrize(
    "discovery_scale_mode, runtime_scale_mode",
    [
        ((1, 1, 32), (1, 1, 32)),
        ((1, 32), (1, 1, 32)),
        (ScaleMode.Blockwise1x32, ScaleMode.Blockwise1x32),
        (ScaleMode.Blockwise1x32, (1, 32)),
    ],
)
@pytest.mark.skipif(
    not is_device_cc_supported({100, 103})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_103a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_103a",
)
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
    scale_size = 32

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = (
        torch.randint(-1, 2, (L, N, K), device="cuda")
        .to(torch.float8_e4m3fn)
        .transpose(1, 2)
    )
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    SFA = torch.rand(
        (
            L,
            M,
            prep_k(K, scale_size),
        ),
        device="cuda",
    ).to(torch.float8_e8m0fnu)
    SFB = torch.rand((L, prep_k(K, scale_size), N), device="cuda").to(
        torch.float8_e8m0fnu
    )

    discovery_args = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            discovery_scale_mode,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B,
            SFB,
            discovery_scale_mode,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )

    # Only test kernels for which we know there will be an error if the scale factors are invalid
    def metadata_filter(metadata: KernelMetadata):
        return (
            metadata.kernel_class
            == cutlass_api.providers.cutedsl.gemm.sm100_dense_blockscaled_static_persistent.PersistentDenseBlockScaledGemmKernel
        )

    kernels = cutlass_api.get_kernels(
        discovery_args, cc=100, metadata_filter=metadata_filter
    )
    assert len(kernels) > 0
    kernel = kernels[0]
    compiled_artifact = kernel.compile(discovery_args)

    runtime_args = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            runtime_scale_mode,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B,
            SFB,
            runtime_scale_mode,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )
    assert kernel.supports(runtime_args)
    kernel.run(
        runtime_args, compiled_artifact=compiled_artifact, assume_supported_args=True
    )

    reference = reference_scaled_mm(A, B, SFA, SFB, torch.float32)
    torch.testing.assert_close(D, reference)

@pytest.mark.skipif(
    not is_device_cc_supported({100, 103})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_103a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_103a",
)
def test_mxfp8_incompatible_mode_or_swizzle(fixture_enable_tvm_ffi):
    """
    Tests for correct flagging of incompatible scale modes or swizzles:
      - Using no swizzle mode for MXFP8
      - Using an incompatible scale mode for MXFP8
    """
    M, N, K, L = 256, 512, 1024, 1
    scale_size = 32

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = torch.randint(-1, 2, (L, N, K), device="cuda").to(torch.float8_e4m3fn).transpose(1, 2)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    SFA = torch.rand((L, M, prep_k(K, scale_size),), device="cuda").to(torch.float8_e8m0fnu)
    SFB = torch.rand((L, prep_k(K, scale_size), N), device="cuda").to(torch.float8_e8m0fnu)

    args_bad = cutlass_api.arguments.GemmArguments(
        # Use incompatible swizzle mode for SFA
        A=ScaledTensor(
            A,
            SFA,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.SwizzleNone,
        ),
        B=ScaledTensor(
            B,
            SFB,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )

    # Only test kernels for which the swizzle mode is incompatible
    def metadata_filter(metadata: KernelMetadata):
        return metadata.kernel_class == cutlass_api.providers.cutedsl.gemm.sm100_dense_blockscaled_static_persistent.PersistentDenseBlockScaledGemmKernel

    kernels = cutlass_api.get_kernels(args_bad, cc=100, metadata_filter=metadata_filter)
    assert len(kernels) == 0

    # Find kernel using compatible swizzle mode, but pass in arguments at runtime with
    # incompatible swizzle mode
    args_good = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B,
            SFB,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )
    kernels = cutlass_api.get_kernels(args_good, cc=100, metadata_filter=metadata_filter)
    assert len(kernels) > 0
    kernel = kernels[0]

    try:
        kernel.run(args_bad)
        assert False, "Expected ValueError for failed supports() check"
    except ValueError as e:
        pass

    # Pass in arguments with an incompatible scale mode
    args_bad_scale = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        # Bad scale mode: SFB had scale mode Blockwise1x16
        B=ScaledTensor(
            B,
            SFB,
            ScaleMode.Blockwise1x16,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )
    try:
        kernel.run(args_bad_scale)
        assert False, "Expected ValueError for failed supports() check"
    except ValueError as e:
        pass

@pytest.mark.skipif(
    not is_device_cc_supported({100, 103})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_103a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_103a",
)
def test_mxfp8_missing_scale_factors(fixture_enable_tvm_ffi):
    """
    Tests for correct flagging of a missing scale factor (both must be supplied)
    """
    M, N, K, L = 256, 512, 1024, 1
    scale_size = 32

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = torch.randint(-1, 2, (L, N, K), device="cuda").to(torch.float8_e4m3fn).transpose(1, 2)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)
    SFA = torch.rand((L, M, prep_k(K, scale_size),), device="cuda").to(torch.float8_e8m0fnu)

    # Construct arguments with only one scale factor
    args = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=B,
        out=D,
        accumulator_type=torch.float32,
    )

    # Only test kernels for which we know there will be an error if the scale factors are missing
    def metadata_filter(metadata: KernelMetadata):
        return metadata.kernel_class == cutlass_api.providers.cutedsl.gemm.sm100_dense_blockscaled_static_persistent.PersistentDenseBlockScaledGemmKernel

    kernels = cutlass_api.get_kernels(args, cc=100, metadata_filter=metadata_filter)
    assert len(kernels) == 0


@pytest.mark.skipif(
    not is_device_cc_supported({100, 103})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_103a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_103a",
)
def test_mxfp8_invalid_scale_factors(fixture_enable_tvm_ffi):
    """
    Tests for correct flagging of invalid scale factors:
      - Too large for the A tensor
      - Too large for the B tensor
    """
    M, N, K, L = 256, 512, 1024, 1
    scale_size = 32

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = torch.randint(-1, 2, (L, N, K), device="cuda").to(torch.float8_e4m3fn).transpose(1, 2)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    # Add 32 elements to the K mode of SFA. This makes it too large for the A tensor
    SFA = torch.rand((L, M, prep_k(K, scale_size) + 32,), device="cuda").to(torch.float8_e8m0fnu)
    SFB = torch.rand((L, prep_k(K, scale_size), N), device="cuda").to(torch.float8_e8m0fnu)

    args = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B,
            SFB,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )

    # Only test kernels for which we know there will be an error if the scale factors are invalid
    def metadata_filter(metadata: KernelMetadata):
        return metadata.kernel_class == cutlass_api.providers.cutedsl.gemm.sm100_dense_blockscaled_static_persistent.PersistentDenseBlockScaledGemmKernel

    kernels = cutlass_api.get_kernels(args, cc=100, metadata_filter=metadata_filter)
    assert len(kernels) == 0

    # Add 32 elements to the K mode of SFB. This makes it too large for the B tensor
    SFA = torch.rand((L, M, prep_k(K, scale_size),), device="cuda").to(torch.float8_e8m0fnu)
    SFB = torch.rand((L, prep_k(K, scale_size) + 32, N), device="cuda").to(torch.float8_e8m0fnu)
    args = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B,
            SFB,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )
    kernels = cutlass_api.get_kernels(args, cc=100, metadata_filter=metadata_filter)
    assert len(kernels) == 0


@pytest.mark.skipif(
    not is_device_cc_supported({100, 103})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_103a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_103a",
)
def test_mxfp8_gemm_sm100_invalid_epilogue(fixture_enable_tvm_ffi):
    """
    Tests for correct flagging of invalid epilogues: currently, no MXFP8 kernels support
    epilogue fusions.
    """
    M, N, K, L = 256, 512, 1024, 1

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = torch.randint(-1, 2, (L, N, K), device="cuda").to(torch.float8_e4m3fn).transpose(1, 2)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    scale_size = 32
    SFA = torch.rand((L, M, prep_k(K, scale_size),), device="cuda").to(torch.float8_e8m0fnu)
    SFB = torch.rand((L, prep_k(K, scale_size), N), device="cuda").to(torch.float8_e8m0fnu)

    C = torch.randint(-1, 2, (L, M, N), device="cuda").to(torch.float32)
    def epilogue(accum, alpha, beta, C):
        D = alpha * accum + beta * C
        return D

    epi_args = EpilogueArguments(epilogue, alpha=1.0, beta=1.0, C=C, D=D)

    args = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B,
            SFB,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
        epilogue=epi_args,
    )
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) == 0


@pytest.mark.skipif(
    not is_device_cc_supported({100, 103})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_103a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_103a",
)
def test_mxfp8_gemm_sm100_design_metadata(fixture_enable_tvm_ffi):
    """
    Tests for correct filtering of kernels based on design metadata specifications
    (e.g., tile shape, cluster shape, etc.).
    """
    M, N, K, L = 256, 512, 1024, 1

    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (L, M, K), device="cuda").to(torch.float8_e4m3fn)
    B = torch.randint(-1, 2, (L, N, K), device="cuda").to(torch.float8_e4m3fn).transpose(1, 2)
    D = torch.empty((L, M, N), device="cuda", dtype=torch.float32)

    scale_size = 32
    SFA = torch.rand((L, M, prep_k(K, scale_size),), device="cuda").to(torch.float8_e8m0fnu)
    SFB = torch.rand((L, prep_k(K, scale_size), N), device="cuda").to(torch.float8_e8m0fnu)

    args = cutlass_api.arguments.GemmArguments(
        A=ScaledTensor(
            A,
            SFA,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ScaledTensor(
            B,
            SFB,
            ScaleMode.Blockwise1x32,
            ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=D,
        accumulator_type=torch.float32,
    )

    def design_filter(metadata: KernelMetadata):
        if not isinstance(metadata.design, Sm100DesignMetadata):
            return False
        return metadata.design.tile_shape[:2] == (256, 128)

    kernels = cutlass_api.get_kernels(args, cc=100, metadata_filter=design_filter)
    assert len(kernels) > 0
    
    for kernel in kernels:
        assert design_filter(kernel.metadata)

    kernel = kernels[0]
    assert kernel.supports(args)
    compiled_artifact = kernel.compile(args)
    kernel.run(args, compiled_artifact=compiled_artifact)

    reference = reference_scaled_mm(A, B, SFA, SFB, torch.float32)
    torch.testing.assert_close(D, reference)
