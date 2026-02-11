# Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
Implementation-level correctness tests for torch-style grouped GEMM (MoE) kernel.

For each hand-crafted problem case (scenario, problem dims, routing, etc.),
discovers all matching kernels via cutlass_api.get_kernels() and verifies
correctness against torch._grouped_mm reference.
"""

import os
import random

import pytest
import torch

import cutlass
import cutlass_api
from cutlass_api.utils import is_device_cc_supported


torch.manual_seed(2025)
random.seed(2025)


# =============================================================================
# Problem cases: (scenario, tokens, experts, top_k, balance_route,
#                  hidden, intermediate, ab_dtype, out_dtype, grad_accumulate)
# =============================================================================

PROBLEM_CASES = [
    # ---- 2Dx3D (Forward) ----
    # (scenario, tokens, experts, top_k, balance, hidden, inter, ab_dtype, out_dtype, grad_acc)
    #
    # Small balanced
    ("2Dx3D", 16, 4, 2, True, 128, 128, torch.bfloat16, torch.bfloat16, False),
    # Medium skewed routing
    ("2Dx3D", 64, 16, 2, False, 512, 1024, torch.float16, torch.float16, False),
    # Larger balanced, mixed dtypes
    ("2Dx3D", 256, 32, 8, True, 2048, 4096, torch.float16, torch.float32, False),
    # Edge: many experts, few tokens, skewed → most experts empty
    ("2Dx3D", 33, 367, 3, False, 512, 1024, torch.bfloat16, torch.bfloat16, False),
    # High token count (non-aligned), many tiles per expert
    ("2Dx3D", 4112, 8, 4, False, 1024, 2048, torch.bfloat16, torch.bfloat16, False),

    # ---- 2Dx2D (Backward / Weight Gradient) ----
    # Small balanced
    ("2Dx2D", 16, 4, 2, True, 128, 128, torch.bfloat16, torch.bfloat16, False),
    # Medium skewed, with grad accumulate
    ("2Dx2D", 64, 8, 4, False, 512, 1024, torch.bfloat16, torch.bfloat16, True),
    # Mixed dtypes, grad acc, balanced
    ("2Dx2D", 128, 8, 4, True, 1024, 2048, torch.float16, torch.float32, True),
    # Edge: many experts, few tokens, skewed → most experts empty
    ("2Dx2D", 33, 367, 3, False, 512, 1024, torch.bfloat16, torch.bfloat16, False),
    # High token count (non-aligned), many K-tiles per expert
    ("2Dx2D", 4112, 8, 4, False, 256, 512, torch.bfloat16, torch.bfloat16, True),
]


# =============================================================================
# Helpers
# =============================================================================

def _generate_offsets(tokens_after_repeat: int, expert_cnt: int, balance: bool) -> torch.Tensor:
    """
    Generate cumulative sum offsets for token-to-expert assignment.

    When balance=False, uses Dirichlet(α=0.2) to produce a skewed distribution
    where tokens concentrate on a subset of experts, with many experts receiving
    zero tokens. This better stresses scheduler edge cases than uniform random.
    """
    if balance:
        sizes = torch.full((expert_cnt,), tokens_after_repeat // expert_cnt, dtype=torch.int32)
        sizes[: tokens_after_repeat % expert_cnt] += 1
    else:
        # Dirichlet(0.2) produces skewed probabilities: a few experts get most tokens
        probs = torch.distributions.Dirichlet(
            torch.full((expert_cnt,), 0.2)
        ).sample()
        bucket_ids = torch.multinomial(probs, tokens_after_repeat, replacement=True)
        sizes = torch.bincount(bucket_ids, minlength=expert_cnt).to(torch.int32)
    return torch.cumsum(sizes, dim=0).cuda().to(torch.int32)


def _generate_tensor(shape, dtype) -> torch.Tensor:
    """Generate a small-value integer tensor for exact comparison."""
    return torch.randint(-1, 2, shape, device="cuda", dtype=torch.int8).to(dtype)


def _compute_reference(A, B, offsets, scenario, out_dtype):
    """Compute reference via torch._grouped_mm."""
    return torch._grouped_mm(
        A.float(), B.float(), offsets
    ).to(out_dtype)


def _make_problem_id(case) -> str:
    scenario, tokens, experts, top_k, balance, hidden, inter, ab_dt, out_dt, grad_acc = case
    d = lambda t: str(t).split(".")[-1]
    return (
        f"{scenario}-tok{tokens}-E{experts}-k{top_k}-"
        f"{'bal' if balance else 'rnd'}-h{hidden}-i{inter}-"
        f"{d(ab_dt)}->{d(out_dt)}"
        f"{'-grad_acc' if grad_acc else ''}"
    )


def _kernel_metadata_filter(metadata):
    """Filter to only discover TorchStyleGroupedMmKernel instances."""
    return (
        metadata.kernel_class
        == cutlass_api.providers.cutedsl.gemm.sm100_torch_style_grouped_mm.TorchStyleGroupedMmKernel
    )


def _discover_kernels_for_case(case):
    """
    Discover all matching kernels for a problem case using args=None.

    Uses metadata-only filtering (scenario, grad_acc, dtype) so that all
    layout variants (different stride patterns) are included. The actual
    tensor layout is determined per-kernel in _build_args_and_ref.
    """
    scenario, tokens, experts, top_k, balance, hidden, intermediate, ab_dtype, out_dtype, grad_acc = case

    ab_cutlass = cutlass.torch.dtype(ab_dtype)
    out_cutlass = cutlass.torch.dtype(out_dtype)

    def combined_filter(metadata):
        if not _kernel_metadata_filter(metadata):
            return False
        if not hasattr(metadata.design, "scenario"):
            return False
        if metadata.design.scenario != scenario:
            return False
        if metadata.design.accumulate_on_output != grad_acc:
            return False
        if metadata.operands.A.dtype != ab_cutlass:
            return False
        if metadata.operands.out.dtype != out_cutlass:
            return False
        return True

    kernels = cutlass_api.get_kernels(args=None, metadata_filter=combined_filter, cc=100)
    return kernels


def _make_tensor_with_stride(shape, dtype, stride_meta):
    """
    Create a tensor whose layout matches the metadata stride pattern.

    Stride convention: 1 = stride-1 (contiguous), 0 = non-contiguous or batch.
    For a 2D tensor (X, Y) with stride (0, 1): Y is contiguous → normal row-major.
    For a 2D tensor (X, Y) with stride (1, 0): X is contiguous → allocate (Y, X).T.
    For a 3D tensor (L, X, Y) with stride (0, 0, 1): Y contiguous → normal.
    For a 3D tensor (L, X, Y) with stride (0, 1, 0): X contiguous → allocate (L, Y, X).permute(0, 2, 1).
    """
    inner_stride = stride_meta[-2:]
    contiguous_idx = list(inner_stride).index(1)

    if len(shape) == 2:
        if contiguous_idx == 1:
            # Last dim contiguous → normal layout
            return _generate_tensor(shape, dtype)
        else:
            # First dim contiguous → allocate transposed
            return _generate_tensor((shape[1], shape[0]), dtype).T
    elif len(shape) == 3:
        if contiguous_idx == 1:
            # Last dim of inner 2D contiguous → normal layout
            return _generate_tensor(shape, dtype)
        else:
            # Middle dim (of inner 2D) contiguous → allocate with swapped inner dims, then permute back
            L, X, Y = shape
            return _generate_tensor((L, Y, X), dtype).permute(0, 2, 1)
    else:
        raise ValueError(f"Unsupported tensor rank: {len(shape)}")


def _build_args_and_ref(case, metadata):
    """
    Build real tensors, args, and reference for a given (case, kernel) pair.

    Tensor layouts are determined from the kernel's metadata strides,
    ensuring they match the kernel's expected stride pattern.

    Returns: (args, reference, out_tensor)
    """
    scenario, tokens, experts, top_k, balance, hidden, intermediate, ab_dtype, out_dtype, grad_acc = case
    tokens_sum = tokens * top_k
    offsets = _generate_offsets(tokens_sum, experts, balance)

    if scenario == "2Dx3D":
        A = _make_tensor_with_stride((tokens_sum, hidden), ab_dtype, metadata.operands.A.stride)
        B = _make_tensor_with_stride((experts, hidden, intermediate), ab_dtype, metadata.operands.B.stride)
        if grad_acc:
            out = torch.zeros((tokens_sum, intermediate), dtype=out_dtype, device="cuda")
        else:
            out = torch.full((tokens_sum, intermediate), -1, dtype=out_dtype, device="cuda")
        # out must also match metadata stride
        if metadata.operands.out.stride[-2:].index(1) != 1:
            out = torch.full((intermediate, tokens_sum), -1, dtype=out_dtype, device="cuda").T
    else:  # 2Dx2D
        A = _make_tensor_with_stride((hidden, tokens_sum), ab_dtype, metadata.operands.A.stride)
        B = _make_tensor_with_stride((tokens_sum, intermediate), ab_dtype, metadata.operands.B.stride)
        if grad_acc:
            out_shape = (experts, hidden, intermediate)
            out = torch.zeros(out_shape, dtype=out_dtype, device="cuda")
        else:
            out_shape = (experts, hidden, intermediate)
            out = torch.full(out_shape, -1, dtype=out_dtype, device="cuda")
        # out must also match metadata stride for 3D
        if metadata.operands.out.stride[-2:].index(1) != 1:
            L, X, Y = experts, hidden, intermediate
            if grad_acc:
                out = torch.zeros((L, Y, X), dtype=out_dtype, device="cuda").permute(0, 2, 1)
            else:
                out = torch.full((L, Y, X), -1, dtype=out_dtype, device="cuda").permute(0, 2, 1)

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A, B=B, out=out,
        accumulator_type=torch.float32,
        offsets=offsets,
    )

    reference = _compute_reference(A, B, offsets, scenario, out_dtype)

    return args, reference, out


# =============================================================================
# Kernel collection (at module load time)
# =============================================================================

def _kernels_for_case(case):
    """Discover kernels for a case; return a subsample for L0."""
    kernels = _discover_kernels_for_case(case)

    try:
        from conftest import get_test_level
        test_level = get_test_level()
    except ImportError:
        test_level = "L0"

    if test_level == "L0" and len(kernels) > 3:
        return random.sample(kernels, 3)
    return kernels


# =============================================================================
# Tests
# =============================================================================

@pytest.mark.parametrize(
    "case",
    PROBLEM_CASES,
    ids=[_make_problem_id(c) for c in PROBLEM_CASES],
)
@pytest.mark.skipif(
    not is_device_cc_supported({100})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_100f"]),
    reason="Requires compute capability 100 and sm_100a or sm_100f",
)
def test_torch_style_grouped_mm(case):
    """
    For each problem case, discover matching kernels and verify correctness
    against torch._grouped_mm reference.
    """
    kernels = _kernels_for_case(case)
    if len(kernels) == 0:
        pytest.skip(f"No kernels found for case: {_make_problem_id(case)}")

    for kernel in kernels:
        args, reference, out = _build_args_and_ref(case, kernel.metadata)

        if not (status := kernel.supports(args)):
            continue  # Skip kernels that don't support this specific args

        # Allocate workspace
        ws_size = kernel.get_workspace_size(args)
        workspace = torch.empty(ws_size, dtype=torch.uint8, device="cuda")

        # Run
        kernel.run(args, workspace=workspace)

        # Verify
        torch.testing.assert_close(
            out,
            reference,
            msg=f"Kernel {kernel.metadata.kernel_name} failed on case {_make_problem_id(case)}",
        )
