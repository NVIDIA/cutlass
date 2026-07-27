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
Integration tests for the preferred-cluster dense GEMM Operator.

These tests verify the user-facing API for the Blackwell
``PersistentDenseGemmPreferredClusterOperator``, which uses a preferred (larger)
cluster shape with a fallback (smaller) cluster to let the driver fill the grid
with the preferred shape where SMs are available and fall back where they are
not.

Exhaustive correctness testing across all Operator variants, tile shapes, and
cluster configurations is handled by the implementation tests in
``test/implementation/test_gemm_kernel.py``, which includes
``PersistentDenseGemmPreferredClusterOperator``.

These integration tests focus on:
- Per-scheduler (CLC dynamic and static persistent) correctness
- 2D tensor support
- API behaviors: Operator discovery, metadata filtering, argument validation
- Compile-and-reuse workflow

Problem sizes are chosen to be at least one preferred cluster tile
(``preferred_cluster_m × cta_m``, ``preferred_cluster_n × cta_n``) in each of M
and N. This is a hard requirement for the operator: smaller problems produce a
zero-sized launch grid because ``max_preferred_cluster_count`` floor-divides
the fallback CTA count by the preferred cluster size.
"""

import logging
from pprint import pformat

import pytest
import torch

import cutlass.operators as ops
from cutlass.operators.metadata.design.sm100 import Sm100DesignMetadata
from cutlass.operators.metadata.design.tile_scheduler import (
    CLCDynamicPersistentTileSchedulerMetadata,
    StaticPersistentTileSchedulerMetadata,
    TileSchedulerMetadata,
)
from cutlass.operators.utils.device import (
    device_or_env_supports,
    device_or_env_target_sm,
)

from test_utils import assert_close_with_reference_conversion

torch.manual_seed(2025)
logger = logging.getLogger(__name__)


# =============================================================================
# Helpers
# =============================================================================


def _preferred_cluster_filter(
    metadata: ops.OperatorMetadata,
    scheduler_type: type[TileSchedulerMetadata] | None = None,
) -> bool:
    """Select a preferred-cluster Operator variant.

    Args:
        metadata: Operator metadata to test.
        scheduler_type: If given, only match this scheduler variant; otherwise
            match any preferred-cluster variant (scheduler-agnostic).

    Returns:
        bool: Whether the operator is a matching preferred-cluster variant.
    """
    design = metadata.design
    if not isinstance(design, Sm100DesignMetadata):
        return False
    if not design.use_fallback_cluster():
        return False
    if scheduler_type is None:
        return True
    return isinstance(getattr(design, "tile_scheduler", None), scheduler_type)


# =============================================================================
# 2D Tensor Support
# =============================================================================


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_preferred_cluster_gemm_2d(fixture_toggle_tvm_ffi):
    """2D (non-batched) tensor support.

    Exercises the ``add_batch_mode`` path in the Operator's ``__call__`` that
    normalises rank-2 inputs to rank-3 before the main GEMM body.
    """
    M, N, K = 512, 512, 128
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=torch.float16)
    out = torch.empty((M, N), device="cuda", dtype=torch.float16)

    args = ops.GemmArguments(A=A, B=B, out=out, accumulator_type=torch.float32)
    operators = ops.get_operators(args, metadata_filter=_preferred_cluster_filter)

    assert len(operators) > 0, "No preferred-cluster Operator matched the filter"
    operator = operators[0]
    logger.debug(f"Picked operator: {operator.metadata.operator_name}")

    assert operator.supports(args)
    operator.run(args)

    reference = A.float() @ B.float()
    assert_close_with_reference_conversion(
        out,
        reference,
        out.dtype,
        atols=0.0,
        rtols=0.0,
        msg=f"preferred-cluster 2D GEMM failed: M={M}, N={N}, K={K}",
    )


# =============================================================================
# Per-Scheduler Correctness Tests
# =============================================================================


@pytest.mark.parametrize(
    "M, N, K, L",
    [
        (256, 256, 256, 1),
        (512, 512, 128, 1),
        (512, 512, 128, 2),
    ],
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_preferred_cluster_gemm_clc_scheduler(
    M: int,
    N: int,
    K: int,
    L: int,
    fixture_toggle_tvm_ffi,
):
    """Preferred-cluster GEMM with CLC dynamic scheduler produces correct results."""
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=torch.float16)
    out = torch.empty((L, M, N), device="cuda", dtype=torch.float16)

    args = ops.GemmArguments(A=A, B=B, out=out, accumulator_type=torch.float32)
    operators = ops.get_operators(
        args,
        metadata_filter=lambda m: _preferred_cluster_filter(
            m, CLCDynamicPersistentTileSchedulerMetadata
        ),
        target_sm=device_or_env_target_sm(),
    )

    assert len(operators) > 0, "No preferred-cluster CLC operator matched the filter"
    operator = operators[0]
    logger.debug(f"Picked operator: {operator.metadata.operator_name}")
    logger.debug(f"Operator metadata:\n{pformat(operator.metadata)}")

    assert operator.supports(args)
    operator.run(args)

    reference = A.float() @ B.float()
    assert_close_with_reference_conversion(
        out,
        reference,
        out.dtype,
        atols=0.0,
        rtols=0.0,
        msg=f"CLC preferred-cluster GEMM failed: M={M}, N={N}, K={K}, L={L}",
    )


@pytest.mark.parametrize(
    "M, N, K, L",
    [
        (256, 256, 256, 1),
        (512, 512, 128, 1),
        (512, 512, 128, 2),
    ],
)
@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_preferred_cluster_gemm_static_scheduler(
    M: int,
    N: int,
    K: int,
    L: int,
    fixture_toggle_tvm_ffi,
):
    """Preferred-cluster GEMM with static persistent scheduler produces correct results."""
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=torch.float16)
    out = torch.empty((L, M, N), device="cuda", dtype=torch.float16)

    args = ops.GemmArguments(A=A, B=B, out=out, accumulator_type=torch.float32)
    operators = ops.get_operators(
        args,
        metadata_filter=lambda m: _preferred_cluster_filter(
            m, StaticPersistentTileSchedulerMetadata
        ),
        target_sm=device_or_env_target_sm(),
    )

    assert len(operators) > 0, "No preferred-cluster static operator matched the filter"
    operator = operators[0]
    logger.debug(f"Picked operator: {operator.metadata.operator_name}")
    logger.debug(f"Operator metadata:\n{pformat(operator.metadata)}")

    assert operator.supports(args)
    operator.run(args)

    reference = A.float() @ B.float()
    assert_close_with_reference_conversion(
        out,
        reference,
        out.dtype,
        atols=0.0,
        rtols=0.0,
        msg=f"Static preferred-cluster GEMM failed: M={M}, N={N}, K={K}, L={L}",
    )


# =============================================================================
# API Behaviors: Operator Discovery and Metadata Filtering
# =============================================================================


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_preferred_cluster_gemm_discovery():
    """Verify the Operator class is registered and discoverable via metadata filter."""
    M, N, K, L = 512, 512, 128, 1
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=torch.float16)
    out = torch.empty((L, M, N), device="cuda", dtype=torch.float16)

    args = ops.GemmArguments(A=A, B=B, out=out, accumulator_type=torch.float32)

    operators = ops.get_operators(args, metadata_filter=_preferred_cluster_filter)
    assert len(operators) > 0, (
        "Expected at least one preferred-cluster Operator variant to be registered"
    )

    for operator in operators:
        design = operator.metadata.design
        assert isinstance(design, Sm100DesignMetadata)
        assert design.use_fallback_cluster()
        assert design.fallback_cluster_shape is not None
        assert design.fallback_cluster_shape != design.cluster_shape
        assert isinstance(
            design.tile_scheduler,
            (
                CLCDynamicPersistentTileSchedulerMetadata,
                StaticPersistentTileSchedulerMetadata,
            ),
        )


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_preferred_cluster_both_schedulers_discoverable():
    """Both CLC and static scheduler preferred-cluster variants are registered."""
    M, N, K, L = 512, 512, 128, 1
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=torch.float16)
    out = torch.empty((L, M, N), device="cuda", dtype=torch.float16)

    args = ops.GemmArguments(A=A, B=B, out=out, accumulator_type=torch.float32)

    clc_ops = ops.get_operators(
        args,
        metadata_filter=lambda m: _preferred_cluster_filter(
            m, CLCDynamicPersistentTileSchedulerMetadata
        ),
        target_sm=device_or_env_target_sm(),
    )
    static_ops = ops.get_operators(
        args,
        metadata_filter=lambda m: _preferred_cluster_filter(
            m, StaticPersistentTileSchedulerMetadata
        ),
        target_sm=device_or_env_target_sm(),
    )

    assert len(clc_ops) > 0, (
        "Expected at least one preferred-cluster CLC variant to be registered"
    )
    assert len(static_ops) > 0, (
        "Expected at least one preferred-cluster static variant to be registered"
    )

    for operator in clc_ops:
        assert isinstance(
            operator.metadata.design.tile_scheduler,
            CLCDynamicPersistentTileSchedulerMetadata,
        )

    for operator in static_ops:
        assert isinstance(
            operator.metadata.design.tile_scheduler,
            StaticPersistentTileSchedulerMetadata,
        )


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_preferred_cluster_gemm_not_available_on_unsupported_cc():
    """No preferred-cluster operators are offered for pre-Blackwell targets."""
    M, N, K, L = 256, 256, 128, 1
    A = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.float16)
    B = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=torch.float16)
    out = torch.empty((L, M, N), device="cuda", dtype=torch.float16)

    args = ops.GemmArguments(A=A, B=B, out=out, accumulator_type=torch.float32)

    # SM90 (Hopper) does not have the preferred-cluster launch mechanism.
    operators = ops.get_operators(
        args, metadata_filter=_preferred_cluster_filter, target_sm="90"
    )
    assert len(operators) == 0, "Expected no preferred-cluster operators for SM90"


# =============================================================================
# Compile-and-Reuse Workflow
# =============================================================================


@pytest.mark.skipif(
    not device_or_env_supports("100f"),
    reason="Requires compute capability 100 and to be compiled with sm_100a or sm_100f",
)
def test_preferred_cluster_gemm_compile_and_reuse(fixture_toggle_tvm_ffi):
    """Compile once, run twice with different input data.

    Exercises the same compiled artifact across multiple ``run`` invocations,
    which is the typical inference-serving pattern.
    """
    M, N, K, L = 512, 512, 128, 1
    A1 = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.float16)
    B1 = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=torch.float16)
    out1 = torch.empty((L, M, N), device="cuda", dtype=torch.float16)

    args1 = ops.GemmArguments(A=A1, B=B1, out=out1, accumulator_type=torch.float32)
    operators = ops.get_operators(args1, metadata_filter=_preferred_cluster_filter)
    assert len(operators) > 0
    operator = operators[0]

    compiled_artifact = operator.compile(args1)
    operator.run(args1, compiled_artifact=compiled_artifact)
    assert_close_with_reference_conversion(
        out1,
        A1.float() @ B1.float(),
        out1.dtype,
        atols=0.0,
        rtols=0.0,
        msg="first run after compile failed",
    )

    # Reuse the compiled artifact with different inputs of the same shape.
    A2 = torch.randint(-1, 2, (L, M, K), device="cuda", dtype=torch.float16)
    B2 = torch.randint(-1, 2, (L, K, N), device="cuda", dtype=torch.float16)
    out1 = torch.empty((L, M, N), device="cuda", dtype=torch.float16)
    args2 = ops.GemmArguments(A=A2, B=B2, out=out1, accumulator_type=torch.float32)

    operator.run(args2, compiled_artifact=compiled_artifact)
    assert_close_with_reference_conversion(
        out1,
        A2.float() @ B2.float(),
        out1.dtype,
        atols=0.0,
        rtols=0.0,
        msg="reused compile artifact failed on second inputs",
    )
