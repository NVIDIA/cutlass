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
Integration tests for torch-style grouped GEMM (MoE) kernel.

Tests the full cutlass_api pipeline: get_kernels, compile, run, workspace,
and negative cases (incorrect shapes, offsets, etc.).
"""

import os

import pytest
import torch

import cutlass_api
from cutlass_api.utils import is_device_cc_supported


def _kernel_metadata_filter(metadata):
    return (
        metadata.kernel_class
        == cutlass_api.providers.cutedsl.gemm.sm100_torch_style_grouped_mm.TorchStyleGroupedMmKernel
    )


# =============================================================================
# Negative tests (no GPU required)
# =============================================================================

def test_no_kernels_for_incorrect_offsets_rank():
    """offsets must be rank 1. Verify no kernels match rank-2 offsets."""
    experts, tokens, hidden, inter = 4, 256, 512, 1024

    A = torch.empty((tokens, hidden), device="cuda", dtype=torch.bfloat16)
    B = torch.empty((experts, hidden, inter), device="cuda", dtype=torch.bfloat16)
    out = torch.empty((tokens, inter), device="cuda", dtype=torch.bfloat16)
    offsets = torch.empty((2, 2), device="cuda", dtype=torch.int32)  # rank 2, wrong

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A, B=B, out=out, accumulator_type=torch.float32, offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(args, metadata_filter=_kernel_metadata_filter, cc=100)
    assert len(kernels) == 0


def test_no_kernels_for_incorrect_offsets_count():
    """offsets element count must equal expert count."""
    experts, tokens, hidden, inter = 8, 256, 512, 1024

    A = torch.empty((tokens, hidden), device="cuda", dtype=torch.bfloat16)
    B = torch.empty((experts, hidden, inter), device="cuda", dtype=torch.bfloat16)
    out = torch.empty((tokens, inter), device="cuda", dtype=torch.bfloat16)
    offsets = torch.empty((experts + 1,), device="cuda", dtype=torch.int32)  # wrong count

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A, B=B, out=out, accumulator_type=torch.float32, offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(args, metadata_filter=_kernel_metadata_filter, cc=100)
    # Kernels may be discovered (metadata matches), but supports() should fail
    for k in kernels:
        assert not k.supports(args)


def test_no_kernels_for_wrong_scenario_shapes():
    """
    2Dx3D expects A(2D), B(3D), out(2D).
    Verify that a 3D A tensor doesn't match any 2Dx3D kernel.
    """
    experts, tokens, hidden, inter = 4, 256, 512, 1024

    # A is 3D (wrong for 2Dx3D)
    A = torch.empty((1, tokens, hidden), device="cuda", dtype=torch.bfloat16)
    B = torch.empty((experts, hidden, inter), device="cuda", dtype=torch.bfloat16)
    out = torch.empty((tokens, inter), device="cuda", dtype=torch.bfloat16)
    offsets = torch.empty((experts,), device="cuda", dtype=torch.int32)

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A, B=B, out=out, accumulator_type=torch.float32, offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(args, metadata_filter=_kernel_metadata_filter, cc=100)
    for k in kernels:
        assert not k.supports(args)


# =============================================================================
# Kernel discovery test
# =============================================================================

def test_kernels_discoverable_2dx3d():
    """Verify that at least one 2Dx3D kernel is discoverable."""
    experts, tokens, hidden, inter = 4, 256, 512, 1024

    A = torch.empty((tokens, hidden), device="cuda", dtype=torch.bfloat16)
    B = torch.empty((experts, hidden, inter), device="cuda", dtype=torch.bfloat16)
    out = torch.empty((tokens, inter), device="cuda", dtype=torch.bfloat16)
    offsets = torch.empty((experts,), device="cuda", dtype=torch.int32)

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A, B=B, out=out, accumulator_type=torch.float32, offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(args, metadata_filter=_kernel_metadata_filter, cc=100)
    assert len(kernels) > 0


def test_kernels_discoverable_2dx2d():
    """Verify that at least one 2Dx2D kernel is discoverable."""
    experts, tokens, hidden, inter = 4, 256, 512, 1024

    A = torch.empty((hidden, tokens), device="cuda", dtype=torch.bfloat16)
    B = torch.empty((tokens, inter), device="cuda", dtype=torch.bfloat16)
    out = torch.empty((experts, hidden, inter), device="cuda", dtype=torch.bfloat16)
    offsets = torch.empty((experts,), device="cuda", dtype=torch.int32)

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A, B=B, out=out, accumulator_type=torch.float32, offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(args, metadata_filter=_kernel_metadata_filter, cc=100)
    assert len(kernels) > 0


# =============================================================================
# Workspace size test
# =============================================================================

def test_workspace_size_positive():
    """Verify that workspace size is > 0 for discovered kernels."""
    experts, tokens, hidden, inter = 8, 256, 512, 1024

    A = torch.empty((tokens, hidden), device="cuda", dtype=torch.bfloat16)
    B = torch.empty((experts, hidden, inter), device="cuda", dtype=torch.bfloat16)
    out = torch.empty((tokens, inter), device="cuda", dtype=torch.bfloat16)
    offsets = torch.empty((experts,), device="cuda", dtype=torch.int32)

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A, B=B, out=out, accumulator_type=torch.float32, offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(args, metadata_filter=_kernel_metadata_filter, cc=100)
    assert len(kernels) > 0

    for kernel in kernels[:3]:
        ws_size = kernel.get_workspace_size(args)
        assert ws_size > 0, f"Workspace size must be > 0, got {ws_size}"


# =============================================================================
# End-to-end correctness (single fixed case, verifies full API pipeline)
# =============================================================================

@pytest.mark.skipif(
    not is_device_cc_supported({100})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_100f"]),
    reason="Requires compute capability 100 and sm_100a or sm_100f",
)
def test_e2e_2dx3d():
    """End-to-end test: compile, run, verify for a simple 2Dx3D case."""
    experts, tokens, hidden, inter = 4, 64, 128, 256
    tokens_sum = tokens * 4  # top_k = 4
    per_expert = tokens_sum // experts

    offsets = torch.arange(1, experts + 1, device="cuda", dtype=torch.int32) * per_expert
    A = torch.randint(-1, 2, (tokens_sum, hidden), device="cuda", dtype=torch.bfloat16)
    B = torch.randint(-1, 2, (experts, hidden, inter), device="cuda", dtype=torch.bfloat16)
    out = torch.zeros((tokens_sum, inter), device="cuda", dtype=torch.bfloat16)

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A, B=B, out=out, accumulator_type=torch.float32, offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(args, metadata_filter=_kernel_metadata_filter, cc=100)
    assert len(kernels) > 0

    kernel = kernels[0]
    ws_size = kernel.get_workspace_size(args)
    workspace = torch.empty(ws_size, dtype=torch.uint8, device="cuda")

    kernel.run(args, workspace=workspace)

    reference = torch._grouped_mm(A.float(), B.float(), offsets).to(torch.bfloat16)
    torch.testing.assert_close(out, reference)


@pytest.mark.skipif(
    not is_device_cc_supported({100})
    or (os.getenv("CUTE_DSL_ARCH", "") not in ["", "sm_100a", "sm_100f"]),
    reason="Requires compute capability 100 and sm_100a or sm_100f",
)
def test_e2e_2dx2d():
    """End-to-end test: compile, run, verify for a simple 2Dx2D case."""
    experts, tokens, hidden, inter = 4, 64, 128, 256
    tokens_sum = tokens * 4  # top_k = 4
    per_expert = tokens_sum // experts

    offsets = torch.arange(1, experts + 1, device="cuda", dtype=torch.int32) * per_expert
    A = torch.randint(-1, 2, (hidden, tokens_sum), device="cuda", dtype=torch.bfloat16)
    B = torch.randint(-1, 2, (tokens_sum, inter), device="cuda", dtype=torch.bfloat16)
    out = torch.zeros((experts, hidden, inter), device="cuda", dtype=torch.bfloat16)

    args = cutlass_api.arguments.GroupedGemmArguments(
        A=A, B=B, out=out, accumulator_type=torch.float32, offsets=offsets,
    )

    kernels = cutlass_api.get_kernels(args, metadata_filter=_kernel_metadata_filter, cc=100)
    assert len(kernels) > 0

    kernel = kernels[0]
    ws_size = kernel.get_workspace_size(args)
    workspace = torch.empty(ws_size, dtype=torch.uint8, device="cuda")

    kernel.run(args, workspace=workspace)

    reference = torch._grouped_mm(A.float(), B.float(), offsets).to(torch.bfloat16)
    torch.testing.assert_close(out, reference)
