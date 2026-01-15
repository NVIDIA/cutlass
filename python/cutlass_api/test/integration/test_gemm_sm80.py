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
from cutlass_api.utils import is_device_cc_supported

logger = logging.getLogger(__name__)

# Set to None to test all kernels, otherwise set to the number of kernels to test
_MAX_KERNELS_TO_TEST = 1

# ab_dtype, c_dtype, accumulator_type
# NOTE: The current Sm80TensorOpGemmKernel implementation only generates kernels
# for Float32 accumulators (see _metadata_operand_combinations in sm80_tensorop_gemm.py),
# so we restrict tests to those combinations for now.
_DTYPES = [
    (torch.float16, torch.float16, torch.float32),
    (torch.bfloat16, torch.bfloat16, torch.float32),
]

# M, N, K, L and L is optional
def get_sizes_mnkl(level: int = 0) -> list[tuple[int, int, int, int]]:
    problem_sizes = []

    if level == 0:
        problem_sizes.append((128, 128, 64, 1))
        problem_sizes.append((256, 256, 128, 1))
        problem_sizes.append((512, 256, 256, 1))
        problem_sizes.append((256, 512, 384, 2))
    else:
        raise ValueError(f"Invalid level: {level}")

    return problem_sizes

# Layout combinations to test: (A_layout, B_layout, C_layout)
# 't' = transposed/row-major (last dim contiguous, stride=1)
# 'n' = normal/column-major (middle dim contiguous, stride=1)
def get_layouts() -> list[tuple[str, str, str]]:
    return [
    ("t", "t", "t"),  # All row-major
    ("t", "n", "t"),  # A row-major, B column-major, C row-major
    ("n", "t", "t"),  # A column-major, B row-major, C row-major
    ("n", "n", "t"),  # A,B column-major, C row-major
    ("t", "t", "n"),
    ("t", "n", "n"),
    ("n", "t", "n"),
    ("n", "n", "n"),
    ]

def create_layout_tensor(shape: tuple, layout: str, dtype: torch.dtype, device: str = "cuda") -> torch.Tensor:
    """Create a tensor with specified layout ensuring proper alignment.

    For layout 't' (row-major): last dimension is contiguous
    For layout 'n' (column-major): middle dimension is contiguous
    """
    L, dim1, dim2 = shape

    if layout == "t":
        # Row-major: last dimension contiguous
        return torch.randint(-1, 2, (L, dim1, dim2), device=device, dtype=dtype)
    else:
        # Column-major: middle dimension contiguous
        tensor_temp = torch.randint(-1, 2, (L, dim2, dim1), device=device, dtype=dtype)
        return tensor_temp.transpose(1, 2)


@pytest.mark.parametrize(
    "M, N, K, L, ab_dtype, c_dtype, accumulator_type",
    [(*sizes, *dtypes) for sizes in get_sizes_mnkl() for dtypes in _DTYPES],
)
def test_gemm_sm80(
    M: int,
    N: int,
    K: int,
    L: int,
    ab_dtype: torch.dtype,
    c_dtype: torch.dtype,
    accumulator_type: torch.dtype,
    fixture_toggle_tvm_ffi,
):
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)

    args = cutlass_api.arguments.GemmArguments(A, B, D, accumulator_type)
    kernels = cutlass_api.get_kernels(args, cc=80)

    assert len(kernels) > 0, "No kernels returned for the given configuration"

    max_kernels = len(kernels) if _MAX_KERNELS_TO_TEST is None else _MAX_KERNELS_TO_TEST
    kernels_to_test = kernels[:max_kernels]
    
    # Compute reference using PyTorch's GPU matmul
    reference = (A.to(torch.float32) @ B.to(torch.float32)).to(c_dtype)
    
    # Test the selected kernels
    for idx, kernel in enumerate(kernels_to_test):
        logger.debug(f"Testing kernel {idx+1}/{len(kernels_to_test)}: {kernel.metadata.kernel_name}")
        logger.debug(f"Kernel metadata:\n{pformat(kernel.metadata)}")
        
        # Create fresh output tensor for each kernel to avoid interference
        D_test = torch.empty((L, M, N), device="cuda", dtype=c_dtype)
        args_test = cutlass_api.arguments.GemmArguments(A, B, D_test, accumulator_type)
        
        try:
            kernel.run(args_test)
            # Verify correctness against PyTorch reference
            torch.testing.assert_close(D_test, reference, atol=1e-2, rtol=1e-2)
            logger.debug(f"Kernel {idx+1}/{len(kernels_to_test)} passed")
        except Exception as e:
            pytest.fail(
                f"Kernel {idx+1}/{len(kernels_to_test)} ({kernel.metadata.kernel_name}) failed: {e}"
            )


@pytest.mark.parametrize(
    "M, N, K, L, ab_dtype, c_dtype, accumulator_type, layouts",
    [
        (*sizes, *dtypes, layouts)
        for sizes in [(248, 264, 248, 1)]  # Test with one size to keep test time reasonable
        for dtypes in _DTYPES
        for layouts in get_layouts()
    ],
)
def test_gemm_sm80_layouts(
    M: int,
    N: int,
    K: int,
    L: int,
    ab_dtype: torch.dtype,
    c_dtype: torch.dtype,
    accumulator_type: torch.dtype,
    layouts: tuple[str, str, str],
    fixture_disable_tvm_ffi,
):
    """Test different tensor layouts (row-major vs column-major).
    
    Note: Currently only tests with use_tvm_ffi=False because TVM-FFI has strict
    stride alignment requirements that are violated by transposed column-major layouts.
    """
    layout_A, layout_B, layout_C = layouts
    
    # Create tensors with specified layouts
    A = create_layout_tensor((L, M, K), layout_A, ab_dtype)
    B = create_layout_tensor((L, K, N), layout_B, ab_dtype)
    D = create_layout_tensor((L, M, N), layout_C, c_dtype)

    args = cutlass_api.arguments.GemmArguments(A, B, D, accumulator_type)
    kernels = cutlass_api.get_kernels(args, cc=80)

    assert len(kernels) > 0, f"No kernels returned for layout {layout_A}{layout_B}{layout_C}"
    
    max_kernels = len(kernels) if _MAX_KERNELS_TO_TEST is None else _MAX_KERNELS_TO_TEST
    kernels_to_test = kernels[:max_kernels]
    
    # Compute reference using PyTorch's GPU matmul
    reference = (A.to(torch.float32) @ B.to(torch.float32)).to(c_dtype)
    
    # Test the selected kernels
    for idx, kernel in enumerate(kernels_to_test):
        logger.debug(f"Testing kernel {idx+1}/{len(kernels_to_test)}: {kernel.metadata.kernel_name}")
        
        # Create fresh output tensor for each kernel with same layout
        D_test = create_layout_tensor((L, M, N), layout_C, c_dtype)
        args_test = cutlass_api.arguments.GemmArguments(A, B, D_test, accumulator_type)
        
        try:
            kernel.run(args_test)
            # Verify correctness against PyTorch reference
            torch.testing.assert_close(D_test, reference, atol=1e-2, rtol=1e-2)
            logger.debug(f"Kernel {idx+1}/{len(kernels_to_test)} passed for layout {layout_A}{layout_B}{layout_C}")
        except Exception as e:
            pytest.fail(
                f"Kernel {idx+1}/{len(kernels_to_test)} ({kernel.metadata.kernel_name}) failed for layout {layout_A}{layout_B}{layout_C}: {e}"
            )


def test_gemm_sm80_fake_tensor(fixture_toggle_tvm_ffi):
    import torch._functorch.config

    torch._functorch.config.fake_tensor_allow_unsafe_data_ptr_access = False

    M, N, K, L = 256, 512, 128, 2
    ab_dtype = torch.float16
    c_dtype = torch.float16
    accumulator_type = torch.float32

    with torch._subclasses.fake_tensor.FakeTensorMode():
        A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
        B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
        D = torch.empty((L, M, N), device="cuda", dtype=c_dtype)

    fake_args = cutlass_api.arguments.GemmArguments(A, B, D, accumulator_type)
    kernels = cutlass_api.get_kernels(fake_args, cc=80)

    assert len(kernels) > 0
    kernel = kernels[0]
    compiled_artifact = kernel.compile(fake_args)

    A_real = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=ab_dtype)
    B_real = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=ab_dtype)
    D_real = torch.empty((L, M, N), device="cuda", dtype=c_dtype)
    args = cutlass_api.arguments.GemmArguments(A_real, B_real, D_real, accumulator_type)
    kernel.run(args, compiled_artifact=compiled_artifact)

    reference = A_real @ B_real
    torch.testing.assert_close(D_real, reference.to(D_real.dtype))
