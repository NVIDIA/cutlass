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

import cutlass
from cutlass.cute.runtime import from_dlpack

import cutlass.operators as ops
from cutlass.operators.utils.device import (
    device_or_env_supports,
    device_or_env_target_sm,
)
from cutlass.operators.utils.dtype import to_cutlass_type
from cutlass.operators.utils.tensor import get_stride_order, major_mode

from test_utils.reference_check import (
    assert_close_with_reference_conversion,
    reference_scaled_mm,
)

"""
Tests that cute.Tensor can be passed directly as RuntimeArguments to an Operator.
"""


@pytest.mark.arch(sms=["100f"])
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="sm80_tensorop_gemm_impl has an ICE because it attempts to compile using sm90+ cluster launch instructions",
)
def test_gemm_args_for_cute_tensor(fixture_toggle_tvm_ffi):
    M, N, K, L = 256, 256, 256, 1

    with torch.device("cuda"):
        A_torch = torch.randint(-1, 2, (L, M, K), dtype=torch.float16)
        B_torch = torch.randint(-1, 2, (L, K, N), dtype=torch.float16)
        out_torch = torch.empty((L, M, N), dtype=torch.float16)
    reference_output = A_torch @ B_torch

    A = (
        from_dlpack(
            A_torch, assumed_align=16, enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi
        )
        .mark_layout_dynamic(major_mode(A_torch.shape, A_torch.stride()))
        .mark_compact_shape_dynamic(
            mode=major_mode(A_torch.shape, A_torch.stride()),
            divisibility=16 * 8 // to_cutlass_type(A_torch.dtype).width,
            stride_order=get_stride_order(A_torch.stride()),
        )
    )
    B = (
        from_dlpack(
            B_torch, assumed_align=16, enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi
        )
        .mark_layout_dynamic(major_mode(B_torch.shape, B_torch.stride()))
        .mark_compact_shape_dynamic(
            mode=major_mode(B_torch.shape, B_torch.stride()),
            divisibility=16 * 8 // to_cutlass_type(B_torch.dtype).width,
            stride_order=get_stride_order(B_torch.stride()),
        )
    )
    out = (
        from_dlpack(
            out_torch, assumed_align=16, enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi
        )
        .mark_layout_dynamic(major_mode(out_torch.shape, out_torch.stride()))
        .mark_compact_shape_dynamic(
            mode=major_mode(out_torch.shape, out_torch.stride()),
            divisibility=16 * 8 // to_cutlass_type(out_torch.dtype).width,
            stride_order=get_stride_order(out_torch.stride()),
        )
    )

    accumulator_type = cutlass.Float32

    args = ops.GemmArguments(A=A, B=B, out=out, accumulator_type=accumulator_type)

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0
    operator = operators[0]
    operator.run(args)
    assert_close_with_reference_conversion(
        args.out.tensor.cuda(), reference_output, args.out.dtype
    )


@pytest.mark.arch(sms=["100a"])
@pytest.mark.skipif(
    not device_or_env_supports("100a"),
    reason="from_dlpack for scale factors on <sm100 is not supported",
)
def test_scaled_gemm_args_for_cute_tensor(fixture_toggle_tvm_ffi):
    from cutlass.operators.utils.common import ceil_div, round_up

    def prep_k(k: int, scale: ops.ScaleMode) -> int:
        return round_up(ceil_div(k, ops.ScaleMode.numel(scale)), 4)

    M, N, K, L = 1024, 1024, 1024, 1

    scale_mode = ops.ScaleMode.Blockwise1x32
    torch_scale_dtype = torch.float8_e8m0fnu

    with torch.device("cuda"):
        A_torch = torch.randint(-1, 2, (L, M, K)).to(torch.float8_e4m3fn)
        scale_A_torch = torch.rand((L, round_up(M, 128), prep_k(K, scale_mode))).to(
            torch_scale_dtype
        )
        B_torch = (
            torch.randint(-1, 2, (L, K, N)).to(torch.float8_e4m3fn).transpose(1, 2)
        )
        scale_B_torch = torch.rand((L, prep_k(K, scale_mode), round_up(N, 128))).to(
            torch_scale_dtype
        )
        out_torch = torch.empty((L, M, N), dtype=torch.float32)

    reference_output = reference_scaled_mm(
        A_torch, B_torch, scale_A_torch, scale_B_torch, out_torch.dtype
    )
    scale_dtype = to_cutlass_type(torch_scale_dtype)

    A = (
        from_dlpack(
            A_torch, assumed_align=16, enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi
        )
        .mark_layout_dynamic(major_mode(A_torch.shape, A_torch.stride()))
        .mark_compact_shape_dynamic(
            mode=major_mode(A_torch.shape, A_torch.stride()),
            divisibility=16 * 8 // to_cutlass_type(A_torch.dtype).width,
            stride_order=get_stride_order(A_torch.stride()),
        )
    )

    scale_A = (
        from_dlpack(
            scale_A_torch,
            assumed_align=32,
            enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi,
        )
        .mark_layout_dynamic(major_mode(scale_A_torch.shape, scale_A_torch.stride()))
        .mark_compact_shape_dynamic(
            mode=major_mode(scale_A_torch.shape, scale_A_torch.stride()),
            divisibility=32 * 8 // scale_dtype.width,
            stride_order=get_stride_order(scale_A_torch.stride()),
        )
    )
    B = (
        from_dlpack(
            B_torch, assumed_align=16, enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi
        )
        .mark_layout_dynamic(major_mode(B_torch.shape, B_torch.stride()))
        .mark_compact_shape_dynamic(
            mode=major_mode(B_torch.shape, B_torch.stride()),
            divisibility=16 * 8 // to_cutlass_type(B_torch.dtype).width,
            stride_order=get_stride_order(B_torch.stride()),
        )
    )
    scale_B = (
        from_dlpack(
            scale_B_torch,
            assumed_align=32,
            enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi,
        )
        .mark_layout_dynamic(major_mode(scale_B_torch.shape, scale_B_torch.stride()))
        .mark_compact_shape_dynamic(
            mode=major_mode(scale_B_torch.shape, scale_B_torch.stride()),
            divisibility=32 * 8 // scale_dtype.width,
            stride_order=get_stride_order(scale_B_torch.stride()),
        )
    )
    out = (
        from_dlpack(
            out_torch, assumed_align=16, enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi
        )
        .mark_layout_dynamic(major_mode(out_torch.shape, out_torch.stride()))
        .mark_compact_shape_dynamic(
            mode=major_mode(out_torch.shape, out_torch.stride()),
            divisibility=16 * 8 // to_cutlass_type(out_torch.dtype).width,
            stride_order=get_stride_order(out_torch.stride()),
        )
    )

    accumulator_type = cutlass.Float32

    args = ops.GemmArguments(
        A=ops.ScaledOperand(A, scale_A, scale_mode, ops.ScaleSwizzleMode.Swizzle32x4x4),
        B=ops.ScaledOperand(B, scale_B, scale_mode, ops.ScaleSwizzleMode.Swizzle32x4x4),
        out=out,
        accumulator_type=accumulator_type,
    )

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0
    operator = operators[0]
    operator.run(args)

    out_dtype = args.out.dtype
    assert_close_with_reference_conversion(
        args.out.tensor.cuda(), reference_output, out_dtype
    )


@pytest.mark.arch(sms=["100f"])
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Library only supports Grouped Gemm for >=sm100",
)
def test_grouped_gemm_args_for_cute_tensor(fixture_toggle_tvm_ffi):
    groups = 2
    M = 256
    TotalM = groups * M
    M_offsets = [M, TotalM]
    N, K = 256, 256

    with torch.device("cuda"):
        A_torch = torch.randint(-1, 2, (TotalM, K), dtype=torch.float16)
        B_torch = torch.randint(-1, 2, (groups, N, K), dtype=torch.float16).permute(
            0, 2, 1
        )
        out_torch = torch.empty((TotalM, N), dtype=torch.float16)
        offsets_torch = torch.tensor(M_offsets, dtype=torch.int32)

    reference_output = torch._grouped_mm(A_torch, B_torch, offsets_torch)

    A = (
        from_dlpack(
            A_torch, assumed_align=16, enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi
        )
        .mark_layout_dynamic(major_mode(A_torch.shape, A_torch.stride()))
        .mark_compact_shape_dynamic(
            mode=major_mode(A_torch.shape, A_torch.stride()),
            divisibility=16 * 8 // to_cutlass_type(A_torch.dtype).width,
            stride_order=get_stride_order(A_torch.stride()),
        )
    )
    B = (
        from_dlpack(
            B_torch, assumed_align=16, enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi
        )
        .mark_layout_dynamic(major_mode(B_torch.shape, B_torch.stride()))
        .mark_compact_shape_dynamic(
            mode=major_mode(B_torch.shape, B_torch.stride()),
            divisibility=16 * 8 // to_cutlass_type(B_torch.dtype).width,
            stride_order=get_stride_order(B_torch.stride()),
        )
    )
    out = (
        from_dlpack(
            out_torch, assumed_align=16, enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi
        )
        .mark_layout_dynamic(major_mode(out_torch.shape, out_torch.stride()))
        .mark_compact_shape_dynamic(
            mode=major_mode(out_torch.shape, out_torch.stride()),
            divisibility=16 * 8 // to_cutlass_type(out_torch.dtype).width,
            stride_order=get_stride_order(out_torch.stride()),
        )
    )
    offsets = from_dlpack(
        offsets_torch, assumed_align=16, enable_tvm_ffi=ops.GlobalOptions().use_tvm_ffi
    ).mark_layout_dynamic(major_mode(offsets_torch.shape, offsets_torch.stride()))

    accumulator_type = cutlass.Float32

    args = ops.GroupedGemmArguments(
        A=A, B=B, out=out, offsets=offsets, accumulator_type=accumulator_type
    )

    operators = ops.get_operators(args, target_sm=device_or_env_target_sm())
    assert len(operators) > 0
    operator = operators[0]
    operator.run(args)
    assert_close_with_reference_conversion(
        args.out.tensor.cuda(), reference_output, args.out.dtype
    )


