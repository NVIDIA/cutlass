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


import logging
import os
from importlib.util import find_spec
from pprint import pformat

import pytest
import torch

import cutlass

import cutlass_api
from cutlass_api.config import GlobalOptions
from cutlass_api.utils import is_device_cc_supported

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
@pytest.mark.parametrize(
    "ab_dtype, c_dtype, accumulator_type",
    [
        (torch.float16, torch.float32, torch.float32),
        (torch.float16, torch.float16, torch.float16),
        (torch.bfloat16, torch.bfloat16, torch.float32),
    ],
)
@pytest.mark.parametrize(
    "use_tvm_ffi",
    [True, False],
)
@pytest.mark.skipif(
    not is_device_cc_supported({100})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_100f"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_gemm_sm100(
    M: int,
    N: int,
    K: int,
    L: int,
    ab_dtype: torch.dtype,
    c_dtype: torch.dtype,
    accumulator_type: torch.dtype,
    use_tvm_ffi: bool,
):
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)

    GlobalOptions().use_tvm_ffi = use_tvm_ffi

    args = cutlass_api.arguments.GemmArguments(A, B, D, accumulator_type)

    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernel = kernels[0]
    logger.debug(f"Picked kernel: {kernel.metadata.kernel_name}")
    logger.debug(f"Kernel metadata:\n{pformat(kernel.metadata)}")
    kernel.run(args)

    reference = A @ B
    torch.testing.assert_close(D, reference.to(D.dtype))


@pytest.mark.skipif(
    not is_device_cc_supported({100})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a",
)
def test_gemm_sm100_int8():
    M, N, K = 256, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.int8)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.int8)
    D = torch.empty((M, N), device="cuda", dtype=torch.int32)

    args = cutlass_api.arguments.GemmArguments(A, B, D, accumulator_type=torch.int32)
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernel = kernels[0]
    assert kernel.supports(args)
    compiled_artifact = kernel.compile(args)
    kernel.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    reference = torch._int_mm(A, B)
    torch.testing.assert_close(D, reference.to(D.dtype))


@pytest.mark.skipif(
    find_spec("tvm_ffi") is None,
    reason="FP8 currently requires TVM FFI to be installed",
)
@pytest.mark.skipif(
    not is_device_cc_supported({100})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a",
)
def test_gemm_sm100_fp8():
    # Currently, FP8 is only supported via TVM FFI.
    GlobalOptions().use_tvm_ffi = True

    M, N, K = 256, 512, 128
    # Create torch fp8 tensors for A and B
    A = torch.randint(-1, 2, (M, K), device="cuda").to(torch.float8_e4m3fn)
    D = torch.empty((M, N), device="cuda", dtype=torch.float32)

    # Transpose B because torch._scaled_mm expects B to be column-major
    B = torch.randint(-1, 2, (N, K), device="cuda").to(torch.float8_e4m3fn).T

    args = cutlass_api.arguments.GemmArguments(A, B, D, accumulator_type=torch.float32)
    kernels = cutlass_api.get_kernels(args, cc=100)

    assert len(kernels) > 0
    kernel = kernels[0]
    assert kernel.supports(args)
    compiled_artifact = kernel.compile(args)
    kernel.run(args, compiled_artifact=compiled_artifact, assume_supported_args=True)

    identity_scale = torch.ones(1, device="cuda", dtype=torch.float32)
    reference = torch._scaled_mm(
        A, B, identity_scale, identity_scale, out_dtype=torch.float32
    )
    torch.testing.assert_close(D, reference)


def test_no_gemms_available():
    M = N = K = 128
    L = 1
    A = torch.empty((L, M, K)).to(torch.float32)
    B = torch.empty((L, K, N)).to(torch.float32)
    D = torch.empty((L, M, N)).to(torch.float32)

    args = cutlass_api.arguments.GemmArguments(A, B, D, accumulator_type=torch.float32)
    kernels = cutlass_api.get_kernels(args, cc=70)

    # There are currenlty no kernels available for compute capability 70.
    assert len(kernels) == 0


@pytest.mark.skipif(
    not is_device_cc_supported({100}),
    reason="Requires compute capability 100",
)
def test_metadata_filter():
    # Test supplying metadata filter only
    def tile_size_m_filter(metadata: cutlass_api.metadata.KernelMetadata) -> bool:
        if not isinstance(metadata.design, cutlass_api.metadata.Sm100DesignMetadata):
            return False
        return metadata.design.tile_shape[0] == 64

    kernels = cutlass_api.get_kernels(cc=100, metadata_filter=tile_size_m_filter)
    for kernel in kernels:
        assert kernel.metadata.design.tile_shape[0] == 64, (
            f"Kernel {kernel.metadata.kernel_name} has tile shape {kernel.metadata.design.tile_shape}"
        )

    # Test supplying metadata filter and arguments
    A = torch.randint(-1, 2, (1, 256, 256), device="cuda").to(torch.float16)
    B = torch.randint(-1, 2, (1, 256, 256), device="cuda").to(torch.float16)
    D = torch.empty((1, 256, 256), device="cuda").to(torch.float16)

    args = cutlass_api.arguments.GemmArguments(A, B, D, accumulator_type=torch.float16)
    kernels = cutlass_api.get_kernels(
        args=args, cc=100, metadata_filter=tile_size_m_filter
    )
    for kernel in kernels:
        assert kernel.metadata.design.tile_shape[0] == 64, (
            f"Kernel {kernel.metadata.kernel_name} has tile shape {kernel.metadata.design.tile_shape}"
        )
        assert kernel.metadata.operands.A.dtype == cutlass.Float16
        assert kernel.metadata.operands.B.dtype == cutlass.Float16
        assert kernel.metadata.operands.out.dtype == cutlass.Float16
        assert kernel.metadata.operands.accumulator_type == cutlass.Float16
