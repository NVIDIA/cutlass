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
from cutlass.operators.arguments import (
    EarlyLaunchDependent,
    EarlyStart,
    GemmPerformanceControls,
    ProgrammaticDependentLaunchControl,
)
from cutlass.operators.providers.cutedsl.gemm.sm100_tgv_gemm import Sm100TgvGemmOperator

from test_utils.common import unpack_cuda_graph_get_edges


def _make_tgv_args(
    pdl: ProgrammaticDependentLaunchControl | None = None,
) -> ops.GemmArguments:
    M, K, N = 16, 256, 256
    A = torch.empty((M, K), dtype=torch.float16)
    B = torch.empty((N, K), dtype=torch.float16).t()
    out = torch.empty((M, N), dtype=torch.float16)
    return ops.GemmArguments(
        A,
        B,
        out,
        torch.float32,
        performance=GemmPerformanceControls(pdl=pdl) if pdl is not None else None,
    )


@pytest.mark.parametrize(
    ("performance", "expected_independent_operands"),
    (
        (
            ProgrammaticDependentLaunchControl(
                early_launch_dependent=EarlyLaunchDependent()
            ),
            (),
        ),
        (
            ProgrammaticDependentLaunchControl(
                early_start=EarlyStart(
                    pdl_stream_serialization=True,
                    independent_operands=("B",),
                )
            ),
            ("B",),
        ),
        (
            ProgrammaticDependentLaunchControl(
                early_start=EarlyStart(
                    pdl_stream_serialization=True,
                    independent_operands=("A",),
                )
            ),
            ("A",),
        ),
        (
            ProgrammaticDependentLaunchControl(
                early_start=EarlyStart(
                    pdl_stream_serialization=True,
                    independent_operands=("A", "B"),
                )
            ),
            ("A", "B"),
        ),
        (
            ProgrammaticDependentLaunchControl(
                early_launch_dependent=EarlyLaunchDependent(),
                early_start=EarlyStart(
                    pdl_stream_serialization=True,
                    independent_operands=("B",),
                ),
            ),
            ("B",),
        ),
    ),
    ids=(
        "early_launch",
        "early_start_weight_independent",
        "early_start_activation_independent",
        "early_start_both_inputs_independent",
        "early_launch_and_start",
    ),
)
def test_generate_operators_filters_invalid_pdl_metadata(
    performance: ProgrammaticDependentLaunchControl,
    expected_independent_operands: tuple[str, ...],
) -> None:
    args = _make_tgv_args(performance)
    target_sm = ops.TargetSm("100a")

    operators = Sm100TgvGemmOperator._generate_operators(
        metadata_filter=lambda metadata: bool(
            metadata.supports(args, target_sm=target_sm)
        ),
        target_sm=target_sm,
        args=args,
    )

    assert operators
    for operator in operators:
        pdl = operator.metadata.design.pdl
        assert pdl.early_launch_dependent
        assert pdl.early_start is not None
        assert pdl.early_start.independent_operands == expected_independent_operands
        assert pdl.supports(performance)


def test_generate_operators_without_pdl_controls_uses_conservative_pdl() -> None:
    args = _make_tgv_args()
    target_sm = ops.TargetSm("100a")

    operators = Sm100TgvGemmOperator._generate_operators(
        metadata_filter=lambda metadata: bool(
            metadata.supports(args, target_sm=target_sm)
        ),
        target_sm=target_sm,
        args=args,
    )

    assert operators
    for operator in operators:
        pdl = operator.metadata.design.pdl
        assert pdl.early_launch_dependent
        assert pdl.early_start is not None
        assert pdl.early_start.independent_operands == ()


def test_generate_operators_rejects_unknown_pdl_independent_operand() -> None:
    args = _make_tgv_args(
        ProgrammaticDependentLaunchControl(
            early_start=EarlyStart(
                pdl_stream_serialization=True,
                independent_operands=("C",),
            )
        )
    )
    target_sm = ops.TargetSm("100a")

    operators = Sm100TgvGemmOperator._generate_operators(
        metadata_filter=lambda metadata: bool(
            metadata.supports(args, target_sm=target_sm)
        ),
        target_sm=target_sm,
        args=args,
    )

    assert not operators


def test_unpack_cuda_graph_get_edges_size_query_4_and_5_tuple() -> None:
    """cuda-bindings 13.3.1 size query is 4-tuple; older bindings used 5."""
    error, edge_data, num_edges = unpack_cuda_graph_get_edges(
        ("ok", None, None, 2), filling=False
    )
    assert error == "ok"
    assert edge_data is None
    assert num_edges == 2

    error, edge_data, num_edges = unpack_cuda_graph_get_edges(
        ("ok", None, None, None, 2), filling=False
    )
    assert error == "ok"
    assert edge_data is None
    assert num_edges == 2


def test_unpack_cuda_graph_get_edges_fill_query_4_and_5_tuple() -> None:
    payloads = ("edge0", "edge1")

    error, edge_data, returned = unpack_cuda_graph_get_edges(
        ("ok", "from", "to", payloads, 2), filling=True
    )
    assert error == "ok"
    assert edge_data == payloads
    assert returned == 2

    error, edge_data, returned = unpack_cuda_graph_get_edges(
        ("ok", "from", "to", payloads), filling=True
    )
    assert error == "ok"
    assert edge_data == payloads
    assert returned == 2


def test_unpack_cuda_graph_get_edges_fill_lossy_query_returns_status() -> None:
    """cuda-bindings 13.3 fill without edgeData is cudaErrorLossyQuery, not arity."""

    class _CudaError:
        def __init__(self) -> None:
            self.value = 402
            self.name = "cudaErrorLossyQuery"

    status = _CudaError()
    error, edge_data, returned = unpack_cuda_graph_get_edges(
        (status, None, None, None), filling=True
    )
    assert error is status
    assert edge_data is None
    assert returned is None
