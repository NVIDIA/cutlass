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

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.metadata import Sm100DesignMetadata
from cutlass.operators.mma import BlackwellTcgen05Mma
from cutlass.operators.providers.cutedsl.index_ptr_grouped_gemm.sm100_moe_grouped_gemm import (
    Sm100PersistentGroupedGemmOperator,
)
from cutlass.operators.providers.cutedsl.index_ptr_grouped_gemm.sm100_moe_scaled_grouped_gemm import (
    Sm100MoEScaledGroupedGemmOperator,
)
from cutlass.operators.providers.cutedsl.index_ptr_grouped_gemm.sm100_moe_scaled_grouped_gemm import (
    _cluster_shape_candidates as scaled_cluster_shape_candidates,
)


def test_dense_cluster_shape_candidates_cover_all_legal_shapes():
    cluster_dimensions = (1, 2, 4)
    expected = {
        (cluster_m, cluster_n, 1)
        for cluster_m in cluster_dimensions
        for cluster_n in cluster_dimensions
    }
    assert set(Sm100PersistentGroupedGemmOperator.cluster_shape_candidates) == expected
    for cluster_shape in expected:
        one_cta_design = Sm100DesignMetadata(
            mma_instruction_type=BlackwellTcgen05Mma,
            tile_shape=(128, 128, 32),
            cluster_shape=cluster_shape,
            use_2cta_mma=False,
            use_tma_store=True,
        )
        two_cta_design = Sm100DesignMetadata(
            mma_instruction_type=BlackwellTcgen05Mma,
            tile_shape=(256, 256, 64),
            cluster_shape=cluster_shape,
            use_2cta_mma=True,
            use_tma_store=True,
        )
        assert Sm100PersistentGroupedGemmOperator._valid_design_metadata(one_cta_design)
        assert Sm100PersistentGroupedGemmOperator._valid_design_metadata(
            two_cta_design
        ) == (cluster_shape[0] % 2 == 0)


def test_scaled_cluster_shape_candidates_cover_all_legal_shapes():
    cluster_dimensions = (1, 2, 4)
    expected = {
        (cluster_m, cluster_n, 1)
        for cluster_m in cluster_dimensions
        for cluster_n in cluster_dimensions
    }
    assert set(scaled_cluster_shape_candidates) == expected
    for cluster_shape in expected:
        one_cta_design = Sm100DesignMetadata(
            mma_instruction_type=BlackwellTcgen05Mma,
            tile_shape=(128, 128, 64),
            cluster_shape=cluster_shape,
            use_2cta_mma=False,
            use_tma_store=True,
        )
        two_cta_design = Sm100DesignMetadata(
            mma_instruction_type=BlackwellTcgen05Mma,
            tile_shape=(256, 128, 64),
            cluster_shape=cluster_shape,
            use_2cta_mma=True,
            use_tma_store=True,
        )
        assert Sm100MoEScaledGroupedGemmOperator._valid_design_metadata(one_cta_design)
        assert Sm100MoEScaledGroupedGemmOperator._valid_design_metadata(
            two_cta_design
        ) == (cluster_shape[0] % 2 == 0)


def _matching_operators(
    args,
    operator_class,
    tile_shape,
    cluster_shape=(1, 1, 1),
    use_2cta_mma=False,
):
    return ops.get_operators(
        args,
        target_sm="100a",
        metadata_filter=lambda metadata: (
            metadata.operator_class is operator_class
            and metadata.design.tile_shape == tile_shape
            and metadata.design.cluster_shape == cluster_shape
            and metadata.design.use_2cta_mma == use_2cta_mma
        ),
        providers=[ops.CuTeDSLProvider],
    )


def _operator(
    args,
    operator_class,
    tile_shape,
    cluster_shape=(1, 1, 1),
    use_2cta_mma=False,
):
    operators = _matching_operators(
        args,
        operator_class,
        tile_shape,
        cluster_shape,
        use_2cta_mma,
    )
    assert len(operators) == 1
    return operators[0]


def _workspace(operator, args):
    requirement = operator.get_workspace_size(args)
    allocation = torch.empty(
        requirement.size_bytes,
        dtype=torch.uint8,
        device="cuda",
    )
    assert allocation.data_ptr() % requirement.ptr_alignment == 0
    workspace = ops.workspace.Workspace(
        allocation,
        alignment_bytes=requirement.ptr_alignment,
    )
    operator.initialize_workspace(args, workspace)
    return workspace


def _group_ranges(offsets):
    starts = [0, *offsets[:-1].cpu().tolist()]
    return zip(starts, offsets.cpu().tolist())


_dense_design_samples = (
    pytest.param(
        (1, 1, 1),
        (64, 32, 16),
        False,
        torch.bfloat16,
        torch.bfloat16,
        torch.float32,
        id="cluster1x1_tile64x32x16_1cta_bf16",
    ),
    pytest.param(
        (1, 2, 1),
        (128, 128, 32),
        False,
        torch.float16,
        torch.float16,
        torch.float16,
        id="cluster1x2_tile128x128x32_1cta_f16",
    ),
    pytest.param(
        (1, 4, 1),
        (128, 128, 128),
        False,
        torch.float16,
        torch.float32,
        torch.float32,
        id="cluster1x4_tile128x128x128_1cta_f32out",
    ),
    pytest.param(
        (2, 1, 1),
        (128, 128, 32),
        True,
        torch.bfloat16,
        torch.bfloat16,
        torch.float32,
        id="cluster2x1_tile128x128x32_2cta_bf16",
    ),
    pytest.param(
        (2, 2, 1),
        (256, 256, 64),
        True,
        torch.float16,
        torch.float16,
        torch.float16,
        id="cluster2x2_tile256x256x64_2cta_f16",
    ),
    pytest.param(
        (2, 4, 1),
        (128, 128, 128),
        True,
        torch.float16,
        torch.float32,
        torch.float32,
        id="cluster2x4_tile128x128x128_2cta_f32out",
    ),
    pytest.param(
        (4, 1, 1),
        (64, 32, 16),
        False,
        torch.bfloat16,
        torch.bfloat16,
        torch.float32,
        id="cluster4x1_tile64x32x16_1cta_bf16",
    ),
    pytest.param(
        (4, 2, 1),
        (256, 256, 64),
        True,
        torch.float16,
        torch.float16,
        torch.float16,
        id="cluster4x2_tile256x256x64_2cta_f16",
    ),
    pytest.param(
        (4, 4, 1),
        (128, 128, 128),
        True,
        torch.float16,
        torch.float32,
        torch.float32,
        id="cluster4x4_tile128x128x128_2cta_f32out",
    ),
)


@pytest.mark.parametrize(
    "cluster_shape,tile_shape,use_2cta_mma,input_dtype,output_dtype,accumulator_dtype",
    _dense_design_samples,
)
@pytest.mark.arch(sms=["100f"])
def test_dense_design_candidate_numeric_samples(
    cluster_shape,
    tile_shape,
    use_2cta_mma,
    input_dtype,
    output_dtype,
    accumulator_dtype,
    fixture_enable_tvm_ffi,
):
    torch.manual_seed(2026)
    cluster_m, cluster_n, _ = cluster_shape
    tile_m, tile_n, tile_k = tile_shape
    group_count = 2
    rows_per_group = cluster_m * tile_m
    output_columns = cluster_n * tile_n
    total_rows = group_count * rows_per_group

    offsets = torch.arange(
        rows_per_group,
        total_rows + 1,
        rows_per_group,
        dtype=torch.int32,
        device="cuda",
    )
    operand_a = torch.randint(
        0,
        2,
        (total_rows, tile_k),
        dtype=torch.int32,
        device="cuda",
    ).to(input_dtype)
    operand_b = torch.randint(
        0,
        2,
        (group_count, tile_k, output_columns),
        dtype=torch.int32,
        device="cuda",
    ).to(input_dtype)
    output = torch.empty(
        (total_rows, output_columns),
        dtype=output_dtype,
        device="cuda",
    )
    args = ops.IndexPtrGroupedGemmArguments(
        A=operand_a,
        B=operand_b,
        out=output,
        accumulator_type=accumulator_dtype,
        offsets=offsets,
        offsets_along="m",
    )
    operator = _operator(
        args,
        Sm100PersistentGroupedGemmOperator,
        tile_shape,
        cluster_shape=cluster_shape,
        use_2cta_mma=use_2cta_mma,
    )

    operator.run(args, workspace=_workspace(operator, args))

    reference = torch.empty_like(output)
    for expert_index, (start, end) in enumerate(_group_ranges(offsets)):
        reference[start:end] = operand_a[start:end] @ operand_b[expert_index]
    torch.testing.assert_close(output, reference, rtol=0, atol=0)


def _fp4_ones(logical_shape, packed_dim):
    packed_dim %= len(logical_shape)
    reordered_shape = list(logical_shape)
    needs_permute = packed_dim != len(logical_shape) - 1
    if needs_permute:
        reordered_shape[packed_dim], reordered_shape[-1] = (
            reordered_shape[-1],
            reordered_shape[packed_dim],
        )
    reordered_shape[-1] //= 2
    packed = torch.full(
        reordered_shape,
        0x22,
        dtype=torch.uint8,
        device="cuda",
    ).view(torch.float4_e2m1fn_x2)
    if not needs_permute:
        return packed
    permutation = list(range(len(logical_shape)))
    permutation[packed_dim], permutation[-1] = (
        permutation[-1],
        permutation[packed_dim],
    )
    return packed.permute(permutation)


@pytest.mark.arch(sms=["100f"])
def test_dense_m_offset_grouped_gemm(fixture_enable_tvm_ffi):
    torch.manual_seed(2026)
    offsets = torch.tensor([32, 64, 128], dtype=torch.int32, device="cuda")
    operand_a = torch.randint(-2, 3, (128, 128), device="cuda").to(torch.float16)
    operand_b = torch.randint(-2, 3, (3, 128, 128), device="cuda").to(torch.float16)
    output = torch.empty((128, 128), dtype=torch.float16, device="cuda")
    args = ops.IndexPtrGroupedGemmArguments(
        A=operand_a,
        B=operand_b,
        out=output,
        accumulator_type=torch.float16,
        offsets=offsets,
        offsets_along="m",
        offsets_value_divisibility=32,
    )
    operator = _operator(
        args,
        Sm100PersistentGroupedGemmOperator,
        (128, 128, 32),
    )

    operator.run(args, workspace=_workspace(operator, args))

    reference = torch.empty_like(output)
    for expert_index, (start, end) in enumerate(_group_ranges(offsets)):
        reference[start:end] = operand_a[start:end] @ operand_b[expert_index]
    torch.testing.assert_close(output, reference, rtol=0, atol=0)


@pytest.mark.arch(sms=["100f"])
def test_dense_m_offset_grouped_gemm_2cta(fixture_enable_tvm_ffi):
    torch.manual_seed(2026)
    offsets = torch.tensor([128, 256, 512], dtype=torch.int32, device="cuda")
    operand_a = torch.randint(-2, 3, (512, 128), device="cuda").to(torch.float16)
    operand_b = torch.randint(-2, 3, (3, 128, 128), device="cuda").to(torch.float16)
    output = torch.empty((512, 128), dtype=torch.float16, device="cuda")
    args = ops.IndexPtrGroupedGemmArguments(
        A=operand_a,
        B=operand_b,
        out=output,
        accumulator_type=torch.float16,
        offsets=offsets,
        offsets_along="m",
        offsets_value_divisibility=128,
    )
    operator = _operator(
        args,
        Sm100PersistentGroupedGemmOperator,
        (256, 256, 64),
        cluster_shape=(2, 1, 1),
        use_2cta_mma=True,
    )

    operator.run(args, workspace=_workspace(operator, args))

    reference = torch.empty_like(output)
    for expert_index, (start, end) in enumerate(_group_ranges(offsets)):
        reference[start:end] = operand_a[start:end] @ operand_b[expert_index]
    torch.testing.assert_close(output, reference, rtol=0, atol=0)


@pytest.mark.arch(sms=["100f"])
def test_dense_k_offset_grouped_gemm_accumulates(fixture_enable_tvm_ffi):
    torch.manual_seed(2026)
    offsets = torch.tensor([32, 64, 128], dtype=torch.int32, device="cuda")
    operand_a = torch.randint(-2, 3, (128, 128), device="cuda").to(torch.float16)
    operand_b = torch.randint(-2, 3, (128, 128), device="cuda").to(torch.float16)
    output = torch.ones((3, 128, 128), dtype=torch.float16, device="cuda")
    args = ops.IndexPtrGroupedGemmArguments(
        A=operand_a,
        B=operand_b,
        out=output,
        accumulator_type=torch.float16,
        offsets=offsets,
        offsets_along="k",
        offsets_value_divisibility=32,
        accumulate_on_output=True,
    )
    operator = _operator(
        args,
        Sm100PersistentGroupedGemmOperator,
        (128, 128, 32),
    )
    assert operator.metadata.operands.offsets_value_divisibility == 8

    operator.run(args, workspace=_workspace(operator, args))

    reference = torch.empty_like(output)
    for expert_index, (start, end) in enumerate(_group_ranges(offsets)):
        reference[expert_index] = (
            operand_a[:, start:end] @ operand_b[start:end, :]
        ) + 1
    torch.testing.assert_close(output, reference, rtol=0, atol=0)


@pytest.mark.arch(sms=["100f"])
def test_mxfp8_m_offset_grouped_gemm(fixture_enable_tvm_ffi):
    torch.manual_seed(2026)
    offsets = torch.tensor([32, 64, 128], dtype=torch.int32, device="cuda")
    quantized_a = torch.randint(-1, 2, (128, 128), device="cuda").to(
        torch.float8_e4m3fn
    )
    quantized_b = torch.randint(-1, 2, (3, 128, 128), device="cuda").to(
        torch.float8_e4m3fn
    )
    scale_a = torch.ones(
        (384, 4),
        dtype=torch.float8_e8m0fnu,
        device="cuda",
    )
    scale_b = torch.ones(
        (3, 512),
        dtype=torch.float8_e8m0fnu,
        device="cuda",
    )
    output = torch.empty((128, 128), dtype=torch.bfloat16, device="cuda")
    args = ops.IndexPtrGroupedGemmArguments(
        A=ops.ScaledOperand(
            quantized_a,
            scale_a,
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ops.ScaledOperand(
            quantized_b,
            scale_b,
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=output,
        accumulator_type=torch.float32,
        offsets=offsets,
        offsets_along="m",
        offsets_value_divisibility=32,
    )
    operator = _operator(
        args,
        Sm100MoEScaledGroupedGemmOperator,
        (128, 128, 128),
    )

    operator.run(args, workspace=_workspace(operator, args))

    reference = torch.empty_like(output)
    for expert_index, (start, end) in enumerate(_group_ranges(offsets)):
        reference[start:end] = (
            quantized_a[start:end].float() @ quantized_b[expert_index].float()
        ).to(torch.bfloat16)
    torch.testing.assert_close(output, reference, rtol=0, atol=0)


@pytest.mark.arch(sms=["100f"])
def test_mxfp8_offsets_reach_scale_padding(fixture_enable_tvm_ffi):
    # Every group is a multiple of the 128-row scale padding, so the discovered
    # Operator reuses the data offsets as its scale-factor offsets rather than
    # deriving them on the device. That choice comes from the divisibility promise
    # alone, and the result must be the same either way.
    torch.manual_seed(2026)
    offsets = torch.tensor([128, 256, 384], dtype=torch.int32, device="cuda")
    quantized_a = torch.randint(-1, 2, (384, 128), device="cuda").to(
        torch.float8_e4m3fn
    )
    quantized_b = torch.randint(-1, 2, (3, 128, 128), device="cuda").to(
        torch.float8_e4m3fn
    )
    scale_a = torch.ones(
        (384, 4),
        dtype=torch.float8_e8m0fnu,
        device="cuda",
    )
    scale_b = torch.ones(
        (3, 512),
        dtype=torch.float8_e8m0fnu,
        device="cuda",
    )
    output = torch.empty((384, 128), dtype=torch.bfloat16, device="cuda")
    args = ops.IndexPtrGroupedGemmArguments(
        A=ops.ScaledOperand(
            quantized_a,
            scale_a,
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ops.ScaledOperand(
            quantized_b,
            scale_b,
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=output,
        accumulator_type=torch.float32,
        offsets=offsets,
        offsets_along="m",
        offsets_value_divisibility=128,
    )
    operator = _operator(
        args,
        Sm100MoEScaledGroupedGemmOperator,
        (128, 128, 128),
    )
    assert operator.metadata.operands.offsets_value_divisibility == 128

    operator.run(args, workspace=_workspace(operator, args))

    reference = torch.empty_like(output)
    for expert_index, (start, end) in enumerate(_group_ranges(offsets)):
        reference[start:end] = (
            quantized_a[start:end].float() @ quantized_b[expert_index].float()
        ).to(torch.bfloat16)
    torch.testing.assert_close(output, reference, rtol=0, atol=0)


@pytest.mark.arch(sms=["100f"])
def test_mxfp8_k_offset_grouped_gemm(fixture_enable_tvm_ffi):
    torch.manual_seed(2026)
    offsets = torch.tensor([32, 64, 128], dtype=torch.int32, device="cuda")
    quantized_a = torch.randint(-1, 2, (128, 128), device="cuda").to(
        torch.float8_e4m3fn
    )
    quantized_b = (
        torch.randint(-1, 2, (128, 128), device="cuda").to(torch.float8_e4m3fn).T
    )
    scale_a = torch.ones(
        (128, 12),
        dtype=torch.float8_e8m0fnu,
        device="cuda",
    )
    scale_b = torch.ones(
        (128, 12),
        dtype=torch.float8_e8m0fnu,
        device="cuda",
    )
    output = torch.empty((3, 128, 128), dtype=torch.bfloat16, device="cuda")
    args = ops.IndexPtrGroupedGemmArguments(
        A=ops.ScaledOperand(
            quantized_a,
            scale_a,
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ops.ScaledOperand(
            quantized_b,
            scale_b,
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=output,
        accumulator_type=torch.float32,
        offsets=offsets,
        offsets_along="k",
        offsets_value_divisibility=32,
    )
    operator = _operator(
        args,
        Sm100MoEScaledGroupedGemmOperator,
        (128, 128, 128),
    )
    assert operator.metadata.operands.offsets_value_divisibility == 16

    operator.run(args, workspace=_workspace(operator, args))

    reference = torch.empty_like(output)
    for expert_index, (start, end) in enumerate(_group_ranges(offsets)):
        reference[expert_index] = (
            quantized_a[:, start:end].float() @ quantized_b[start:end].float()
        ).to(torch.bfloat16)
    torch.testing.assert_close(output, reference, rtol=0, atol=0)


@pytest.mark.arch(sms=["100f"])
def test_mxfp4_m_offset_grouped_gemm(fixture_enable_tvm_ffi):
    offsets = torch.tensor([32, 64, 128], dtype=torch.int32, device="cuda")
    quantized_a = _fp4_ones((128, 128), packed_dim=1)
    quantized_b = _fp4_ones((3, 128, 128), packed_dim=1)
    scale_a = torch.ones(
        (384, 4),
        dtype=torch.float8_e8m0fnu,
        device="cuda",
    )
    scale_b = torch.ones(
        (3, 512),
        dtype=torch.float8_e8m0fnu,
        device="cuda",
    )
    output = torch.empty((128, 128), dtype=torch.bfloat16, device="cuda")
    args = ops.IndexPtrGroupedGemmArguments(
        A=ops.ScaledOperand(
            quantized_a,
            scale_a,
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ops.ScaledOperand(
            quantized_b,
            scale_b,
            ops.ScaleMode.Blockwise1x32,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=output,
        accumulator_type=torch.float32,
        offsets=offsets,
        offsets_along="m",
        offsets_value_divisibility=32,
    )
    args_with_unsupported_epilogue = ops.IndexPtrGroupedGemmArguments(
        A=args.A,
        B=args.B,
        out=args.out,
        accumulator_type=torch.float32,
        offsets=args.offsets,
        offsets_along="m",
        offsets_value_divisibility=32,
        epilogue=ops.PerGroupScaleEpilogueArguments(
            global_scale_a=torch.ones(3, dtype=torch.float32, device="cuda"),
            global_scale_b=torch.ones(3, dtype=torch.float32, device="cuda"),
        ),
    )
    assert not _matching_operators(
        args_with_unsupported_epilogue,
        Sm100MoEScaledGroupedGemmOperator,
        (128, 128, 128),
    )
    operator = _operator(
        args,
        Sm100MoEScaledGroupedGemmOperator,
        (128, 128, 128),
    )

    operator.run(args, workspace=_workspace(operator, args))

    reference = torch.full_like(output, 128)
    torch.testing.assert_close(output, reference, rtol=0, atol=0)


@pytest.mark.arch(sms=["100f"])
def test_nvfp4_global_scales(fixture_enable_tvm_ffi):
    offsets = torch.tensor([32, 64, 128], dtype=torch.int32, device="cuda")
    quantized_a = _fp4_ones((128, 128), packed_dim=1)
    quantized_b = _fp4_ones((3, 128, 128), packed_dim=1)
    scale_a = torch.ones(
        (384, 8),
        dtype=torch.float8_e4m3fn,
        device="cuda",
    )
    scale_b = torch.ones(
        (3, 1024),
        dtype=torch.float8_e4m3fn,
        device="cuda",
    )
    global_scale_a = torch.tensor([1, 2, 3], dtype=torch.float32, device="cuda")
    global_scale_b = torch.tensor([2, 3, 4], dtype=torch.float32, device="cuda")
    output = torch.empty((128, 128), dtype=torch.bfloat16, device="cuda")
    args = ops.IndexPtrGroupedGemmArguments(
        A=ops.ScaledOperand(
            quantized_a,
            scale_a,
            ops.ScaleMode.Blockwise1x16,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        B=ops.ScaledOperand(
            quantized_b,
            scale_b,
            ops.ScaleMode.Blockwise1x16,
            ops.ScaleSwizzleMode.Swizzle32x4x4,
        ),
        out=output,
        accumulator_type=torch.float32,
        offsets=offsets,
        offsets_along="m",
        offsets_value_divisibility=32,
        epilogue=ops.PerGroupScaleEpilogueArguments(
            global_scale_a=global_scale_a,
            global_scale_b=global_scale_b,
        ),
    )
    args_without_required_epilogue = ops.IndexPtrGroupedGemmArguments(
        A=args.A,
        B=args.B,
        out=args.out,
        accumulator_type=torch.float32,
        offsets=args.offsets,
        offsets_along="m",
        offsets_value_divisibility=32,
    )
    assert not _matching_operators(
        args_without_required_epilogue,
        Sm100MoEScaledGroupedGemmOperator,
        (128, 128, 64),
    )
    operator = _operator(
        args,
        Sm100MoEScaledGroupedGemmOperator,
        (128, 128, 64),
    )

    operator.run(args, workspace=_workspace(operator, args))

    reference = torch.empty_like(output)
    for expert_index, (start, end) in enumerate(_group_ranges(offsets)):
        expected_value = (
            128 * global_scale_a[expert_index] * global_scale_b[expert_index]
        )
        reference[start:end].fill_(expected_value)
    torch.testing.assert_close(output, reference, rtol=0, atol=0)
