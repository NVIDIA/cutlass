#
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

"""Metadata-level checks of the block-scaled (MXFP8) EFC GEMM operators that
need no device."""

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.providers.cutedsl.gemm.sm100_blockscaled_static_persistent_efc import (
    Sm100PersistentBlockScaledGemmEFCOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm100_static_persistent_efc import (
    Sm100PersistentDenseGemmEFCOperator,
)
from cutlass.operators.providers.cutedsl.gemm.sm107_blockscaled_static_persistent_efc import (
    Sm107PersistentBlockScaledGemmEFCOperator,
)

_MXFP8 = (ops.ScaleMode.Blockwise1x32, ops.ScaleSwizzleMode.Swizzle32x4x4)


def _cpu_scaled_args(
    *,
    a_dtype=torch.float8_e4m3fn,
    b_dtype=torch.float8_e4m3fn,
    sf_dtype=torch.float8_e8m0fnu,
    mode=_MXFP8[0],
    swizzle=_MXFP8[1],
    accumulator_type=torch.float32,
    out_dtype=torch.bfloat16,
    sfa_numel=None,
):
    """MXFP8-shaped ``GemmArguments`` on the CPU: discovery reads dtypes,
    strides and scale modes."""
    M, N, K, L = 256, 256, 256, 1
    A = torch.zeros((L, M, K), device="cpu").to(a_dtype)
    B = torch.zeros((L, N, K), device="cpu").to(b_dtype).transpose(1, 2)
    numel_a = ops.ScaledOperand.numel_scale((L, M, K), mode, swizzle)
    numel_b = ops.ScaledOperand.numel_scale((L, N, K), mode, swizzle)
    SFA = torch.zeros(sfa_numel or numel_a, device="cpu").to(sf_dtype)
    SFB = torch.zeros(numel_b, device="cpu").to(sf_dtype)
    D = torch.empty((L, M, N), device="cpu", dtype=out_dtype)
    return ops.GemmArguments(
        A=ops.ScaledOperand(A, SFA, mode, swizzle),
        B=ops.ScaledOperand(B, SFB, mode, swizzle),
        out=D,
        accumulator_type=accumulator_type,
    )


def _offered(operator_class, args):
    return operator_class.generate_operators(
        metadata_filter=lambda metadata: True, args=args
    )


def test_blockscaled_efc_offered_for_mxfp8():
    """Discovery offers the SM100 block-scaled EFC operator for MXFP8 scaled
    operands, over the block-scaled tile menu only: the MMA tiler M is the
    instruction M, tile N is 64, 128, 192 or 256, and tile K is one 128-byte swizzle
    period of fp8."""
    operators = _offered(Sm100PersistentBlockScaledGemmEFCOperator, _cpu_scaled_args())
    assert operators
    for operator in operators:
        design = operator.metadata.design
        assert design.tile_shape[0] == (256 if design.use_2cta_mma else 128)
        assert design.tile_shape[1] in (64, 128, 192, 256)
        assert design.tile_shape[2] == 128
        assert "_SFAFloat8E8M0FNU_" in operator.metadata.operator_name
        assert "_scale1x32_swizzle32x4x4_" in operator.metadata.operator_name
    tiles = {d.tile_shape[:2] for d in (o.metadata.design for o in operators)}
    assert tiles == {(m, n) for m in (128, 256) for n in (64, 128, 192, 256)}


def test_blockscaled_efc_offers_mixed_fp8_formats():
    """e4m3 x e5m2 quantized operands are offered: the f8f6f4 MMA kind decodes
    each operand's format independently."""
    args = _cpu_scaled_args(a_dtype=torch.float8_e4m3fn, b_dtype=torch.float8_e5m2)
    assert _offered(Sm100PersistentBlockScaledGemmEFCOperator, args)


@pytest.mark.parametrize(
    "kwargs",
    [
        pytest.param(
            {"a_dtype": torch.float16, "b_dtype": torch.float16}, id="f16_operands"
        ),
        pytest.param(
            {"mode": ops.ScaleMode.Blockwise1x16, "sf_dtype": torch.float8_e4m3fn},
            id="nvf4_scale_mode",
        ),
        pytest.param({"sf_dtype": torch.float8_e4m3fn}, id="e4m3_scales"),
        pytest.param({"accumulator_type": torch.float16}, id="f16_accumulator"),
    ],
)
def test_blockscaled_efc_rejects(kwargs):
    """The operand menu is MXFP8: fp8 quantized operands, E8M0 scales over
    32 K elements, f32 accumulation."""
    assert (
        _offered(Sm100PersistentBlockScaledGemmEFCOperator, _cpu_scaled_args(**kwargs))
        == []
    )


def test_dense_and_blockscaled_efc_operators_partition_arguments():
    """Scaled operands resolve to the block-scaled operator and dense tensors
    to the dense one."""
    scaled = _cpu_scaled_args()
    assert _offered(Sm100PersistentDenseGemmEFCOperator, scaled) == []
    M, N, K = 256, 256, 256
    A = torch.zeros((M, K), device="cpu").to(torch.float8_e4m3fn)
    B = torch.zeros((K, N), device="cpu").to(torch.float8_e4m3fn)
    D = torch.empty((M, N), device="cpu", dtype=torch.bfloat16)
    dense = ops.GemmArguments(A=A, B=B, out=D, accumulator_type=torch.float32)
    assert _offered(Sm100PersistentBlockScaledGemmEFCOperator, dense) == []
    assert _offered(Sm100PersistentDenseGemmEFCOperator, dense)


def test_blockscaled_efc_supports_checks_scale_element_counts():
    """The scale buffers' shapes are free, but their element count must be
    the one the swizzled layout needs for the operand's logical shape."""
    good = _cpu_scaled_args()
    operator = _offered(Sm100PersistentBlockScaledGemmEFCOperator, good)[0]
    assert operator._supports(good)
    bad = _cpu_scaled_args(
        sfa_numel=ops.ScaledOperand.numel_scale((1, 256, 256), *_MXFP8) + 128
    )
    status = operator._supports(bad)
    assert not status
    assert "Scale factor A" in str(status)


# --- SM107 (Rubin) ---------------------------------------------------------


def test_sm107_blockscaled_efc_offers_breuse_designs():
    """The Rubin block-scaled EFC operator is offered for MXFP8 operands over
    the same tile-N menu, with the K=64 per-CTA tile law and the Bkeep-Breuse
    doubled tile."""
    operators = _offered(Sm107PersistentBlockScaledGemmEFCOperator, _cpu_scaled_args())
    assert operators
    assert all(
        operator.metadata.operator_name.startswith(
            "cutedsl.Sm107PersistentBlockScaledGemmEFCOperator_"
        )
        for operator in operators
    )
    designs = {
        (d.use_2cta_mma, d.enable_breuse, d.tile_shape[:2])
        for d in (o.metadata.design for o in operators)
    }
    assert all(n in (64, 128, 192, 256) for _, _, (_, n) in designs)
    assert (False, False, (128, 128)) in designs
    assert (False, False, (128, 64)) in designs
    assert (False, True, (256, 128)) in designs
    assert (False, True, (256, 192)) in designs
    assert (True, False, (128, 256)) in designs
    assert (True, True, (256, 256)) in designs
    assert any("_breuse_" in o.metadata.operator_name for o in operators)
