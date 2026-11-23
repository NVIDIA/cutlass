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

"""
Unit tests for cutlass.operators.get_operators() and Manifest functionality.
"""

from __future__ import annotations

import pprint
from typing import TYPE_CHECKING

import pytest
import torch

import cutlass.operators as ops

if TYPE_CHECKING:
    from collections.abc import Callable


# -----------------------------------------------------------------------------
# Test fixtures and helpers
# -----------------------------------------------------------------------------


def make_simple_gemm_args() -> ops.GemmArguments:
    """Create simple GemmArguments for testing."""
    A = torch.empty((2, 128, 64), dtype=torch.float16)
    B = torch.empty((2, 64, 128), dtype=torch.float16)
    out = torch.empty((2, 128, 128), dtype=torch.float16)
    return ops.GemmArguments(A=A, B=B, out=out, accumulator_type=torch.float32)


def make_epilogue_gemm_args() -> ops.GemmArguments:
    """Create GemmArguments with custom epilogue for testing."""

    def epi(accum):
        D = accum * 2.0
        return D

    A = torch.empty((2, 128, 64), dtype=torch.float16)
    B = torch.empty((2, 64, 128), dtype=torch.float16)
    out = torch.empty((2, 128, 128), dtype=torch.float16)
    epi_args = ops.EpilogueArguments(epi, D=out)
    return ops.GemmArguments(
        A=A, B=B, out=out, accumulator_type=torch.float32, epilogue=epi_args
    )


def hash_based_metadata_filter(metadata: ops.OperatorMetadata) -> bool:
    """Filter that selects ~50% of operators based on name hash."""
    return hash(metadata.operator_name) % 2 == 0


# -----------------------------------------------------------------------------
# Test parameters (use factories to avoid creating tensors at import time)
# -----------------------------------------------------------------------------

ARGS_FACTORIES = [
    pytest.param(lambda: None, id="args=None"),
    pytest.param(make_simple_gemm_args, id="args=simple_gemm"),
    pytest.param(make_epilogue_gemm_args, id="args=epilogue_gemm"),
]

TARGET_SM_KINDS = [
    pytest.param(None, id="target_sm=None"),
    pytest.param("90", id="target_sm=90_portable"),
    pytest.param("103a", id="target_sm=103a_arch_conditional"),
    pytest.param("120f", id="target_sm=120f_family_portable"),
]

METADATA_FILTERS = [
    pytest.param(None, id="filter=None"),
    pytest.param(hash_based_metadata_filter, id="filter=hash_based"),
]


# -----------------------------------------------------------------------------
# Tests
# -----------------------------------------------------------------------------


@pytest.mark.parametrize("args_factory", ARGS_FACTORIES)
@pytest.mark.parametrize("target_sm", TARGET_SM_KINDS)
@pytest.mark.parametrize("metadata_filter", METADATA_FILTERS)
def test_get_operators_supports_invariant(
    args_factory: Callable[[], ops.GemmArguments | None],
    target_sm: str | None,
    metadata_filter: Callable[[ops.OperatorMetadata], bool] | None,
):
    """All operators from get_operators() must support the provided args, target_sm, and metadata_filter."""
    args = args_factory()  # Create fresh args for each test
    operators = ops.get_operators(
        args=args, target_sm=target_sm, metadata_filter=metadata_filter
    )

    for k in operators:
        # Verify metadata_filter was respected
        if metadata_filter is not None:
            assert metadata_filter(k.metadata), (
                f"Operator {k.metadata.operator_name} does not satisfy the requested metadata_filter"
            )

        # Verify target_sm compatibility
        if target_sm is not None:
            assert ops.TargetSm(target_sm).supports_operators_from(
                k.metadata.supported_targets
            ), f"Operator {k.metadata.operator_name} is not supported on {target_sm}"

        # Verify supports() returns True for the query parameters
        if args is not None:
            status = k.supports(args, target_sm=target_sm)
            assert status, (
                f"Operator {k.metadata.operator_name} returned by get_operators "
                f"does not support args: {status.error}"
            )


def test_unsupported_target_sm_returns_no_operators():
    """No arch supports cc=0, expect no supported operators to be returned."""
    args = make_simple_gemm_args()
    operators = ops.get_operators(args=args, target_sm="0")
    assert operators == [], f"Expected no operators for cc=0, got {operators}"


def test_all_unique_operator_names():
    """All operator names should be unique. Torch Inductor is using a cache based on operator name."""
    operator_map: dict[str, ops.Operator] = {}
    operators = ops.get_operators()

    for k in operators:
        name = k.metadata.operator_name
        if name in operator_map:
            existing = pprint.pformat(operator_map[name].metadata)
            duplicate = pprint.pformat(k.metadata)
            pytest.fail(
                f"Duplicate operator name: {name}\n\n"
                f"--- First operator ---\n{existing}\n\n"
                f"--- Duplicate operator ---\n{duplicate}"
            )
        operator_map[k.metadata.operator_name] = k


class _ManifestTestOperator(ops.Operator):
    supported_args_type = ops.GemmArguments
    designed_for_min_cc = 90
    _provider = object()

    def _supports(self, args, target_sm=None):
        return ops.Status.success() if args.accepted else ops.Status.fail("rejected")

    def _compile(self, args, target_sm=None):
        raise NotImplementedError

    def _run(self, args, compiled_artifact, stream, workspace=None):
        raise NotImplementedError

    @classmethod
    def _generate_operators(
        cls, metadata_filter, epilogue_args=None, target_sm=None, args=None
    ):
        raise NotImplementedError


class _AcceptOperands:
    def supports(self, args):
        return ops.Status.success()


def _manifest_test_operator(name, target):
    metadata = ops.OperatorMetadata(
        operator_name=name,
        operator_class=_ManifestTestOperator,
        supported_targets=[ops.TargetSm(target)],
        operands=_AcceptOperands(),
    )
    return _ManifestTestOperator(metadata)


def test_manifest_filter_without_runtime_arguments():
    manifest = ops.Manifest()
    sm90 = _manifest_test_operator("sm90", "90a")
    sm100 = _manifest_test_operator("sm100", "100a")
    manifest.add_operators([sm90, sm100])

    assert manifest.filter_operators() == [sm90, sm100]
    assert manifest.filter_operators(
        metadata_filter=lambda m: m.operator_name == "sm100"
    ) == [sm100]
    assert manifest.filter_operators(providers=[]) == []
    assert manifest.filter_operators(providers=[_ManifestTestOperator._provider]) == [
        sm90,
        sm100,
    ]


def test_manifest_filter_target_without_runtime_arguments():
    manifest = ops.Manifest()
    sm90 = _manifest_test_operator("sm90", "90a")
    sm100 = _manifest_test_operator("sm100", "100a")
    manifest.add_operators([sm90, sm100])

    assert manifest.filter_operators(target_sm="90a") == [sm90]
    assert manifest.filter_operators(target_sm="100a") == [sm100]


def test_manifest_filter_with_runtime_arguments():
    from types import SimpleNamespace

    manifest = ops.Manifest()
    sm90 = _manifest_test_operator("sm90", "90a")
    sm100 = _manifest_test_operator("sm100", "100a")
    manifest.add_operators([sm90, sm100])
    accepted = SimpleNamespace(accepted=True, performance=None, epilogue=None)
    rejected = SimpleNamespace(accepted=False, performance=None, epilogue=None)

    assert manifest.filter_operators(args=accepted, target_sm="90a") == [sm90]
    assert manifest.filter_operators(args=rejected, target_sm="100a") == []
