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

"""
Integration tests for the Operator API heuristics layer.

Verifies that selecting a heuristic never returns an Operator that wasn't
already a valid candidate for the problem: the set of ``operator_name``
values with a heuristic must be a subset of the set without one. It need not
be the same set -- a heuristic may narrow the candidates to the subset it can
actually evaluate (e.g. ``nvmatmul`` excludes Operators outside the hardware
generation it was constructed to model).
"""

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.heuristics.nvmatmul import NvMatmulHeuristics
from cutlass.operators.metadata import Sm100DesignMetadata
from cutlass.operators.providers.cutedsl.gemm.sm100_blockscaled_static_persistent import (
    Sm100BlockscaledStaticPersistentOperator,
)
from cutlass.operators.utils.device import device_or_env_target_sm

from test_utils import assert_close_with_reference_conversion, reference_device

pytestmark = pytest.mark.skipif(
    not torch.cuda.is_available(), reason="CUDA device required"
)


def _operator_names(operators: list[ops.Operator]) -> set[str]:
    """Stable identity of an Operator list across two discovery calls."""
    return {op.metadata.operator_name for op in operators}


def _require_sm100_for_nvmatmul() -> None:
    """Skip when the host target is not SM100 (``cc == 100``)."""
    target_sm = device_or_env_target_sm()
    if target_sm.cc != 100:
        pytest.skip(
            f"nvmatmul heuristic requires SM100 target (cc=100); got {target_sm}"
        )


def _make_gemm_args(m: int, n: int, k: int, L: int = 1) -> ops.GemmArguments:
    # Allocate where Torch can launch, then .cuda() for the Operator.
    alloc_device = reference_device()
    a = torch.empty((L, m, k), device=alloc_device, dtype=torch.float16)
    b = torch.empty((L, k, n), device=alloc_device, dtype=torch.float16)
    out = torch.empty((L, m, n), device=alloc_device, dtype=torch.float16)
    return ops.GemmArguments(a.cuda(), b.cuda(), out.cuda(), torch.float32)


@pytest.mark.parametrize(
    "m, n, k, L",
    [
        (256, 512, 1024, 1),
        (256, 512, 64, 1),
        (128, 256, 128, 2),
    ],
)
def test_heuristic_returns_subset_of_operator_set(m: int, n: int, k: int, L: int):
    """``heuristic=`` must never discover an Operator absent without one.

    Compares by ``operator_name`` because each ``get_operators`` call builds
    fresh Operator instances (object identity is not stable across calls).
    ``nvmatmul`` may narrow the set (e.g. excluding older-generation
    Operators that are portable to this target but outside what it models),
    so equality is not asserted -- only the subset relationship.
    """
    _require_sm100_for_nvmatmul()
    args = _make_gemm_args(m, n, k, L)
    target_sm = device_or_env_target_sm()

    without = ops.get_operators(args, target_sm=target_sm)
    with_heuristic = ops.get_operators(
        args, target_sm=target_sm, heuristic=NvMatmulHeuristics(gpu="B200")
    )

    names_without = _operator_names(without)
    names_with = _operator_names(with_heuristic)

    assert names_with.issubset(names_without), (
        "Heuristic returned Operators not present without a heuristic: "
        f"{names_with - names_without}"
    )
    assert len(with_heuristic) <= len(without)


def test_heuristic_top_pick_runs():
    """The top-ranked Operator after ``nvmatmul`` must still execute correctly.

    Deliberately does not restrict discovery to a specific Operator class or
    generation -- picking whichever Operator the heuristic actually ranks
    first, the way a real caller would, is the point of this test.
    """
    _require_sm100_for_nvmatmul()
    m, n, k, L = 256, 512, 128, 1
    device = reference_device()
    target_sm = device_or_env_target_sm()

    a = torch.randint(-1, 2, (L, m, k), device=device, dtype=torch.float16)
    b = torch.randint(-1, 2, (L, k, n), device=device, dtype=torch.float16)
    out = torch.empty((L, m, n), device="cuda", dtype=torch.float16)
    args = ops.GemmArguments(a.cuda(), b.cuda(), out, torch.float32)

    ranked = ops.get_operators(
        args, target_sm=target_sm, heuristic=NvMatmulHeuristics(gpu="B200")
    )
    if not ranked:
        pytest.skip("No SM100 GEMM operators available to rank for this problem")

    ranked[0].run(args)

    reference = a.float() @ b.float()
    assert_close_with_reference_conversion(out, reference, out.dtype)


def test_heuristic_none_matches_unranked_discovery():
    """``heuristic=None`` (default) must match an explicit no-heuristic call."""
    args = _make_gemm_args(256, 256, 128)
    target_sm = device_or_env_target_sm()

    default = ops.get_operators(args, target_sm=target_sm)
    explicit_none = ops.get_operators(args, target_sm=target_sm, heuristic=None)

    assert _operator_names(default) == _operator_names(explicit_none)
    assert [op.metadata.operator_name for op in default] == [
        op.metadata.operator_name for op in explicit_none
    ]


def _sm100_blockscaled_only(metadata: ops.OperatorMetadata) -> bool:
    return (
        isinstance(metadata.design, Sm100DesignMetadata)
        and metadata.operator_class is Sm100BlockscaledStaticPersistentOperator
    )


def _make_sm100_blockscaled_gemm_args(
    M: int = 256, N: int = 512, K: int = 1024, L: int = 1
) -> ops.GemmArguments:
    ab_dtype = torch.float8_e4m3fn
    scale_dtype = torch.float8_e8m0fnu
    scale_mode = ops.ScaleMode.Blockwise1x32
    swizzle = ops.ScaleSwizzleMode.Swizzle32x4x4
    device = reference_device()

    a = torch.randint(-1, 2, (L, M, K), device=device).to(ab_dtype)
    b = torch.randint(-1, 2, (L, N, K), device=device).to(ab_dtype).transpose(1, 2)
    out = torch.empty((L, M, N), device="cuda", dtype=torch.float32)
    sfa = torch.rand(
        ops.ScaledOperand.numel_scale((L, M, K), scale_mode, swizzle), device="cuda"
    ).to(scale_dtype)
    sfb = torch.rand(
        ops.ScaledOperand.numel_scale((L, N, K), scale_mode, swizzle), device="cuda"
    ).to(scale_dtype)

    return ops.GemmArguments(
        A=ops.ScaledOperand(a.cuda(), sfa, scale_mode, swizzle),
        B=ops.ScaledOperand(b.cuda(), sfb, scale_mode, swizzle),
        out=out,
        accumulator_type=torch.float32,
    )


def test_blockscaled_heuristic_returns_subset_of_operator_set():
    """Block-scaled analogue of ``test_heuristic_returns_subset_of_operator_set``.

    Same subset relationship as the dense case -- ``match_operators_to_configs``
    prunes candidates that match no recommended config or fall outside the
    modeled compute capability, so the ranked block-scaled set need not equal
    the unranked one either.
    """
    _require_sm100_for_nvmatmul()
    args = _make_sm100_blockscaled_gemm_args()
    target_sm = device_or_env_target_sm()

    without = ops.get_operators(
        args, target_sm=target_sm, metadata_filter=_sm100_blockscaled_only
    )
    if not without:
        pytest.skip("No SM100 PersistentBlockScaledGemm operators for this problem")

    with_heuristic = ops.get_operators(
        args,
        target_sm=target_sm,
        metadata_filter=_sm100_blockscaled_only,
        heuristic=NvMatmulHeuristics(gpu="B200"),
    )

    names_without = _operator_names(without)
    names_with = _operator_names(with_heuristic)
    assert names_with <= names_without, (
        "Heuristic returned Operators not present without a heuristic: "
        f"{names_with - names_without}"
    )


def test_blockscaled_heuristic_top_pick_runs():
    """The top-ranked block-scaled Operator after ``nvmatmul`` must still execute correctly."""
    _require_sm100_for_nvmatmul()
    target_sm = device_or_env_target_sm()
    args = _make_sm100_blockscaled_gemm_args()

    ranked = ops.get_operators(
        args,
        target_sm=target_sm,
        metadata_filter=_sm100_blockscaled_only,
        heuristic=NvMatmulHeuristics(gpu="B200"),
    )
    if not ranked:
        pytest.skip("No SM100 PersistentBlockScaledGemm operators for this problem")

    ranked[0].run(args)
