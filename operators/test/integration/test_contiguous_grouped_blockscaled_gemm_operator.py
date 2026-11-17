# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

"""Correctness coverage for the SM107 contiguous grouped block-scaled GEMM."""

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.providers.cutedsl.index_ptr_grouped_gemm.sm107_contiguous_grouped_blockscaled_gemm import (
    Sm107ContiguousGroupedBlockScaledGemmOperator,
)

import test_utils


@pytest.mark.parametrize("offsets_value_divisibility", [64, 128, 256, 512, 1024])
@pytest.mark.arch(sms=["107a"])
def test_sm107_contiguous_grouped_blockscaled_gemm_offsets_value_divisibility(
    offsets_value_divisibility: int,
    fixture_toggle_tvm_ffi,
) -> None:
    """Reject insufficient divisibility and run every supported divisibility.

    1. Currently available SM107 contiguous grouped block-scaled GEMM operators
       require every offset to be divisible by 128, 256, or 512.
    2. If the original offsets are not divisible, callers must pad each group to
       a supported offsets_value_divisibility before invoking the operator.
    3. For an existing operator, its required offsets divisibility is recorded in
       operator.metadata.operands.offsets_value_divisibility.
    """
    N, K = 128, 128

    Ms = (31, 128, 0, 127, 512, 255)
    padded_Ms = tuple(
        ((M + offsets_value_divisibility - 1) // offsets_value_divisibility)
        * offsets_value_divisibility
        for M in Ms
    )
    group_count = len(padded_Ms)
    valid_m = sum(padded_Ms)
    # A fixed value for the total M
    # Keep one extra row beyond a commonly aligned capacity to verify that the
    # unused tail does not need to satisfy offsets_value_divisibility.
    M = 32769
    assert valid_m <= M

    scale_mode = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4

    # Random/fill CUDA kernels may not yet be available when a new architecture
    # is first enabled in PyTorch. Initialize on the host and copy to the GPU.
    a = torch.randint(-2, 3, (M, K)).to(torch.float8_e4m3fn).cuda()
    b = (
        torch.randint(-2, 3, (group_count, N, K))
        .to(torch.float8_e4m3fn)
        .transpose(1, 2)
        .cuda()
    )
    out = torch.full((M, N), torch.nan, dtype=torch.float32).cuda()
    sfa = torch.ones(
        ops.ScaledOperand.numel_scale((1, M, K), scale_mode, swizzle),
        dtype=torch.float8_e8m0fnu,
    ).cuda()
    sfb = torch.ones(
        ops.ScaledOperand.numel_scale((group_count, N, K), scale_mode, swizzle),
        dtype=torch.float8_e8m0fnu,
    ).cuda()
    offsets = (
        torch.tensor(padded_Ms, dtype=torch.int32).cumsum(0, dtype=torch.int32).cuda()
    )
    global_scale_a = torch.tensor([0.5, -1, 2, 0, 1.5, -2], dtype=torch.float32)
    args = ops.IndexPtrGroupedGemmArguments(
        A=ops.ScaledOperand(a, sfa, scale_mode, swizzle),
        B=ops.ScaledOperand(b, sfb, scale_mode, swizzle),
        out=out,
        accumulator_type=torch.float32,
        offsets=offsets,
        offsets_along="m",
        offsets_value_divisibility=offsets_value_divisibility,
        epilogue=ops.PerGroupScaleEpilogueArguments(
            global_scale_a=global_scale_a.cuda(),
        ),
    )

    operators = ops.get_operators(
        args,
        providers=[ops.CuTeDSLProvider],
    )
    operators = [
        operator
        for operator in operators
        if isinstance(operator, Sm107ContiguousGroupedBlockScaledGemmOperator)
    ]
    if not any(
        offsets_value_divisibility % supported_offsets_value_divisibility == 0
        for supported_offsets_value_divisibility in (128, 256, 512)
    ):
        assert not operators
        return

    assert operators
    operator = operators[0]
    workspace_allocation_requirement = operator.get_workspace_size(args)
    workspace_tensor = torch.empty(
        workspace_allocation_requirement.size_bytes, dtype=torch.uint8, device="cuda"
    )
    workspace = ops.workspace.Workspace(
        workspace_tensor,
        leading_zero_bytes=0,
        alignment_bytes=workspace_allocation_requirement.ptr_alignment,
    )
    operator.run(args, workspace=workspace)
    torch.cuda.synchronize()

    reference = torch.empty((valid_m, N), dtype=out.dtype)
    a_f32 = a.cpu().float()
    b_f32 = b.cpu().float()
    start = 0
    for group_idx, group_m in enumerate(padded_Ms):
        end = start + group_m
        reference[start:end] = a_f32[start:end] @ b_f32[group_idx]
        reference[start:end] *= global_scale_a[group_idx]
        start = end

    out_cpu = out.cpu()
    test_utils.assert_close_with_reference_conversion(
        out_cpu[:valid_m],
        reference,
        out.dtype,
        msg=f"Operator {operator.metadata.operator_name} failed",
    )
    assert torch.isnan(out_cpu[valid_m:]).all()
