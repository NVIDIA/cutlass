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

import functools
import os
import pytest
import random
import torch

import cutlass

import cutlass_api
from cutlass_api.utils import is_device_cc_supported


torch.manual_seed(2025)
random.seed(2025)


def create_offsets(
    problems_in_group: int,
    expect_m: int,
    force_empty_problems: bool,
) -> tuple[int, list[int], torch.Tensor]:
    """
    Utility to create offsets for the contiguous offset tensor.

    :param problems_in_group: Number of problems to create offsets for.
    :type problems_in_group: int
    :param expect_m: Expected number of rows in each group.
    :type expect_m: int
    :param force_empty_problems: Whether to force some problems in the group to be empty.
    :type force_empty_problems: bool

    :return: Total number of rows, list of group sizes, and offset mapping tensor.
    :rtype: tuple[int, list[int], torch.Tensor]
    """
    valid_m = 0
    problem_m_list = []
    for i in range(problems_in_group):
        problem_m = random.randint(int(expect_m * 0.7), int(expect_m * 1.3))
        valid_m += problem_m
        # handle the case that valid_m == 0
        if (i == problems_in_group - 1) and (valid_m == 0):
            problem_m = 128
            valid_m += problem_m
        problem_m_list.append(problem_m)

    if force_empty_problems:
        problems_to_zero = random.sample(
            range(problems_in_group), max(problems_in_group - 2, 1)
        )
        for problem_idx in problems_to_zero:
            valid_m -= problem_m_list[problem_idx]
            problem_m_list[problem_idx] = 0

    end_mapping = torch.cumsum(torch.tensor(problem_m_list, dtype=torch.int32), dim=0)
    offsets = torch.tensor(end_mapping, device="cuda", dtype=torch.int32)
    return valid_m, problem_m_list, offsets


def args_and_ref_from_metadata(
    metadata: cutlass_api.metadata.KernelMetadata,
    mnkl: tuple[int, int, int, int],
    force_empty_problems: bool,
):
    m, n, k, l = mnkl

    valid_m, problem_m_list, offsets = create_offsets(l, m, force_empty_problems)

    # Create A (1, valid_m, k)
    if metadata.operands.A.stride[-2:].index(1) == 1:
        A = torch.randint(-1, 2, (valid_m, k), device="cuda").to(
            cutlass.torch.dtype(metadata.operands.A.dtype)
        )
    else:
        A = (
            torch.randint(-1, 2, (k, valid_m), device="cuda")
            .to(cutlass.torch.dtype(metadata.operands.A.dtype))
            .T
        )

    # Create B (l, k, n)
    if metadata.operands.B.stride[-2:].index(1) == 1:
        B = torch.randint(-1, 2, (l, k, n), device="cuda").to(
            cutlass.torch.dtype(metadata.operands.B.dtype)
        )
    else:
        B = (
            torch.randint(-1, 2, (l, n, k), device="cuda")
            .to(cutlass.torch.dtype(metadata.operands.B.dtype))
            .permute(0, 2, 1)
        )

    # Create out (1, valid_m, n)
    if metadata.operands.out.stride[-2:].index(1) == 1:
        out = torch.zeros(
            (valid_m, n),
            device="cuda",
            dtype=cutlass.torch.dtype(metadata.operands.out.dtype),
        )
    else:
        out = torch.zeros(
            (n, valid_m),
            device="cuda",
            dtype=cutlass.torch.dtype(metadata.operands.out.dtype),
        ).T

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A,
        B=B,
        out=out,
        accumulator_type=cutlass.torch.dtype(metadata.operands.accumulator_type),
        offsets=offsets,
    )

    #
    # Compute reference
    #

    out_type = cutlass.torch.dtype(metadata.operands.out.dtype)

    # Compute reference in F32 because torch does not support GEMMs
    # for all FP8 types
    if hasattr(torch.nn.functional, "grouped_mm"):
        reference = torch.nn.functional.grouped_mm(
            A.float(), B.float(), offs=offsets
        ).to(out_type)
    else:
        reference = torch._grouped_mm(A.float(), B.float(), offsets).to(out_type)

    return args, reference, out


def kernels_for_class(kernel_class):
    def metadata_filter(metadata):
        return metadata.kernel_class == kernel_class

    kernels = cutlass_api.get_kernels(
        args=None, metadata_filter=metadata_filter, cc=100
    )
    assert len(kernels) > 0

    # Toggle the number of kernels to return based on the test level
    try:
        from conftest import get_test_level

        test_level = get_test_level()
    except ImportError:
        test_level = "L0"

    if test_level == "L0":
        return random.sample(kernels, 10)
    else:
        return kernels


@pytest.mark.parametrize(
    "mnkl, force_empty_problems",
    [
        ((13, 16, 32, 3), False),
        ((253, 32, 32, 7), False),
        ((256, 256, 512, 1), False),
        ((256, 256, 512, 10), False),
        ((8192, 8192, 8192, 4), False),
        ((8192, 8192, 8192, 4), True),
        ((1024, 4096, 4096, 15), False),
        ((256, 16384, 128, 20), False),
    ],
)
@pytest.mark.parametrize(
    "kernel",
    kernels_for_class(
        cutlass_api.providers.cutedsl.gemm.sm100_contiguous_offset_2d3d_dense_gemm.ContiguousOffset2D3DGemmDenseKernel
    ),
)
@pytest.mark.skipif(
    not is_device_cc_supported({100})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_100f"]),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_contiguous_offset_gemm_dense(mnkl, force_empty_problems, kernel):
    m, n, k, l = mnkl

    args, reference, out = args_and_ref_from_metadata(
        kernel.metadata, mnkl, force_empty_problems
    )

    if not (status := kernel.supports(args)):
        pytest.fail(
            f"Kernel {kernel.metadata.kernel_name} does not support the given arguments: {status}"
        )

    kernel.run(args)
    torch.testing.assert_close(
        out, reference, msg=f"Kernel {kernel.metadata.kernel_name} failed"
    )


def kernel_metadata_filter(metadata):
    return (
        metadata.kernel_class
        == cutlass_api.providers.cutedsl.gemm.sm100_contiguous_offset_2d3d_dense_gemm.ContiguousOffset2D3DGemmDenseKernel
    )


def test_incorrect_ab_contiguous():
    """
    Contiguous offset GEMMs currently require A to be in contiguous offset form.
    Test that no kernels are found when only B is in contiguous offset form.
    """

    problem_count, m, n, k = 12, 8192, 128, 512

    A = torch.empty((problem_count, m, k), device="cuda", dtype=torch.float16)
    B = torch.empty((1, n, k), device="cuda", dtype=torch.float16).permute(0, 2, 1)
    out = torch.empty((1, m, n), device="cuda", dtype=torch.float32)

    offsets = torch.empty((problem_count,), device="cuda", dtype=torch.int32)

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A,
        B=B,
        out=out,
        accumulator_type=torch.float32,
        offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(
        args, metadata_filter=kernel_metadata_filter, cc=100
    )
    assert len(kernels) == 0


def test_incorrect_offset_length():
    """
    Offset tensors are required to have `problem_count` elements.

    Test that no kernels are found when this is violated.
    """

    problem_count, m, n, k = 12, 8192, 128, 512

    A = torch.empty((1, m, k), device="cuda", dtype=torch.float16)
    B = torch.empty((problem_count, n, k), device="cuda", dtype=torch.float16).permute(
        0, 2, 1
    )
    out = torch.empty((1, m, n), device="cuda", dtype=torch.float32)

    # Incorrect: should have `problem_count` elements
    offsets = torch.empty((problem_count + 1,), device="cuda", dtype=torch.int32)

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A,
        B=B,
        out=out,
        accumulator_type=torch.float32,
        offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(
        args, metadata_filter=kernel_metadata_filter, cc=100
    )
    assert len(kernels) == 0


def test_incorrect_offsets_shape():
    """
    Offset maps are expected to be rank 1. Test that no kernels are found when this is not the case.
    """
    problem_count, m, n, k = 12, 8192, 128, 512

    A = torch.empty((1, m, k), device="cuda", dtype=torch.float16)
    B = torch.empty((problem_count, n, k), device="cuda", dtype=torch.float16).permute(
        0, 2, 1
    )
    out = torch.empty((1, m, n), device="cuda", dtype=torch.float32)

    # Correct representation of offsets. Kernels should be found.
    offsets = torch.empty((problem_count,), device="cuda", dtype=torch.int32)

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A,
        B=B,
        out=out,
        accumulator_type=torch.float32,
        offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(
        args, metadata_filter=kernel_metadata_filter, cc=100
    )
    assert len(kernels) > 0

    # Reformat to be rank 2. No kernels should be found
    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A,
        B=B,
        out=out,
        accumulator_type=torch.float32,
        offsets=offsets.view(3, 4),
    )

    kernels = cutlass_api.get_kernels(
        args, metadata_filter=kernel_metadata_filter, cc=100
    )
    assert len(kernels) == 0
