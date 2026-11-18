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

"""Integration tests for the TGV low-latency GEMM Operator.

TGV is optimized for narrow-batch decode inference (small M).
It requires specific layouts:
  A (activation): row-major (K-contiguous)
  B (weight): col-major (K-contiguous)
  C (output): row-major (N-contiguous)
"""

import ctypes
import ctypes.util
import logging
import types

import pytest
import torch
from cuda.bindings import runtime as cuda_runtime

import cutlass.operators as ops
from cutlass.operators.arguments import (
    EarlyLaunchDependent,
    EarlyStart,
    GemmPerformanceControls,
    PDLProgrammaticEvent,
    ProgrammaticDependentLaunchControl,
)
from cutlass.operators.providers.cutedsl.gemm.sm100_tgv_gemm import Sm100TgvGemmOperator
from cutlass.operators.utils.device import (
    device_or_env_supports,
    device_or_env_target_sm,
)

from test_utils.common import unpack_cuda_graph_get_edges

pytestmark = pytest.mark.skipif(
    not device_or_env_supports(("100f", "110f")),
    reason="TGV requires an architecture in the sm_100f or sm_110f family",
)

torch.manual_seed(2026)
logger = logging.getLogger(__name__)


def _make_col_major_B(K, N, L=None, dtype=torch.float16):
    """Create a col-major B tensor (K-contiguous) as expected by TGV.

    Allocates as (N, K) row-major then transposes, so K has stride 1.
    """
    if L is not None:
        B = torch.randint(-1, 2, (L, N, K), device="cuda", dtype=dtype)
        return B.transpose(-1, -2)  # (L, K, N) with K stride=1
    B = torch.randint(-1, 2, (N, K), device="cuda", dtype=dtype)
    return B.t()  # (K, N) with K stride=1


def _get_operators(args):
    """Get operators from the manifest that support the runtime arguments."""
    return ops.get_operators(
        args,
        target_sm=device_or_env_target_sm(),
    )


def test_tgv_not_returned_for_row_major_B():
    """TGV Operator should NOT be returned when B is row-major (N-contiguous)."""

    M, K, N = 16, 256, 128
    dtype = torch.float16
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=dtype)
    # Standard row-major B — NOT K-contiguous
    B = torch.randint(-1, 2, (K, N), device="cuda", dtype=dtype)
    D = torch.empty((M, N), device="cuda", dtype=dtype)

    args = ops.GemmArguments(A, B, D, torch.float32)

    tgv_operators = [
        operator
        for operator in _get_operators(args)
        if operator.metadata.operator_class is Sm100TgvGemmOperator
    ]

    assert len(tgv_operators) == 0, (
        f"Expected no TGV operators for row-major B, got {len(tgv_operators)}"
    )


# =============================================================================
# Integration test for the TGV GEMM Operator with Programmatic Dependent Launch (PDL). Three cases are tested:
# =============================================================================
#   - PDL stream-serialization dependency
#   - PDL programmatic event dependency with trigger at block start = 0
#   - PDL programmatic event dependency with trigger at block start = 1
#
#   The PDL dependency is captured in the CUDA graph and verified by asserting the expected from port.
#
#   For more details about PDL in CUDA graphs, see:
#       https://docs.nvidia.com/cuda/cuda-programming-guide/04-special-topics/programmatic-dependent-launch.html#use-in-cuda-graphs
def _check_cuda(error: cuda_runtime.cudaError_t, operation: str) -> None:
    if error != cuda_runtime.cudaError_t.cudaSuccess:
        raise RuntimeError(f"{operation} failed: {error}")


class _CudaGraphEdgeDataC(ctypes.Structure):
    """C layout of ``cudaGraphEdgeData`` (CUDA 12.3+)."""

    _fields_ = (
        ("from_port", ctypes.c_uint8),
        ("to_port", ctypes.c_uint8),
        ("type", ctypes.c_uint8),
        ("reserved", ctypes.c_uint8 * 5),
    )


def _cuda_graph_handle_value(raw_graph) -> int:
    """Return the ``cudaGraph_t`` pointer value, not pointer-to-handle.

    ``getPtr()`` on cuda-bindings wrappers is the address of the stored
    handle. The runtime API takes the handle by value, which is the same
    integer Torch exposes as ``CUDAGraph.raw_cuda_graph()``.
    """
    pvt = getattr(raw_graph, "_pvt_ptr", None)
    if pvt is not None:
        return int(pvt[0])
    return int(raw_graph)


def _load_cudart() -> ctypes.CDLL:
    libname = ctypes.util.find_library("cudart")
    candidates = (libname, "libcudart.so.13", "libcudart.so.12", "libcudart.so")
    for candidate in candidates:
        if candidate is None:
            continue
        try:
            return ctypes.CDLL(candidate)
        except OSError:
            continue
    raise RuntimeError(
        "Could not load libcudart to retry cudaGraphGetEdges with edgeData"
    )


def _cuda_graph_get_edges_ctypes(graph_handle: int, num_edges: int):
    """Fill-query via libcudart with a non-NULL edgeData buffer."""
    lib = _load_cudart()
    lib.cudaGraphGetEdges.restype = ctypes.c_int
    lib.cudaGraphGetEdges.argtypes = (
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.c_void_p,
        ctypes.POINTER(ctypes.c_size_t),
    )
    from_nodes = (ctypes.c_void_p * num_edges)()
    to_nodes = (ctypes.c_void_p * num_edges)()
    edge_data = (_CudaGraphEdgeDataC * num_edges)()
    count = ctypes.c_size_t(num_edges)
    err = lib.cudaGraphGetEdges(
        graph_handle,
        from_nodes,
        to_nodes,
        edge_data,
        ctypes.byref(count),
    )
    payloads = tuple(
        types.SimpleNamespace(
            from_port=int(edge.from_port),
            to_port=int(edge.to_port),
            type=cuda_runtime.cudaGraphDependencyType(int(edge.type)),
        )
        for edge in edge_data
    )
    return cuda_runtime.cudaError_t(err), payloads, int(count.value)


def _cuda_graph_get_edges(
    raw_graph,
    num_edges: int | None = None,
    *,
    graph_handle: int | None = None,
):
    """Call ``cudaGraphGetEdges`` and unpack 4- or 5-tuple bindings."""
    filling = num_edges is not None
    result = (
        cuda_runtime.cudaGraphGetEdges(raw_graph)
        if not filling
        else cuda_runtime.cudaGraphGetEdges(raw_graph, num_edges)
    )
    error, edge_data, count = unpack_cuda_graph_get_edges(result, filling=filling)
    lossy_query = getattr(cuda_runtime.cudaError_t, "cudaErrorLossyQuery", None)
    if filling and lossy_query is not None and error == lossy_query:
        handle = (
            graph_handle
            if graph_handle is not None
            else _cuda_graph_handle_value(raw_graph)
        )
        return _cuda_graph_get_edges_ctypes(handle, num_edges)
    return error, edge_data, count


def _assert_programmatic_graph_edge(
    graph: torch.cuda.CUDAGraph, expected_from_port: int
) -> None:
    """Assert that a captured graph contains the expected PDL dependency edge."""

    graph_handle = graph.raw_cuda_graph()
    raw_graph = cuda_runtime.cudaGraph_t(graph_handle)
    error, _, num_edges = _cuda_graph_get_edges(raw_graph, graph_handle=graph_handle)
    _check_cuda(error, "cudaGraphGetEdges size query")
    error, edge_data, returned_edges = _cuda_graph_get_edges(
        raw_graph, num_edges, graph_handle=graph_handle
    )
    _check_cuda(error, "cudaGraphGetEdges")
    assert returned_edges == num_edges
    programmatic_edges = [
        edge
        for edge in edge_data
        if edge.type
        == cuda_runtime.cudaGraphDependencyType.cudaGraphDependencyTypeProgrammatic
    ]
    assert len(programmatic_edges) == 1, (
        f"Expected exactly one programmatic CUDA graph edge, got {programmatic_edges}"
    )
    assert programmatic_edges[0].from_port == expected_from_port, (
        "Expected the programmatic CUDA graph edge to originate from port "
        f"{expected_from_port}, got {programmatic_edges[0].from_port}"
    )


def test_tgv_pdl_stream_serialization(
    fixture_toggle_tvm_ffi,
):
    """Capture a TGV PDL stream-serialization dependency."""
    M, K, N = 16, 256, 256
    dtype = torch.float16
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=dtype)
    B = _make_col_major_B(K, N, dtype=dtype)
    intermediate = torch.empty((M, N), device="cuda", dtype=dtype)
    output = torch.empty_like(intermediate)
    producer_args = ops.GemmArguments(
        A,
        B,
        intermediate,
        torch.float32,
        performance=GemmPerformanceControls(
            pdl=ProgrammaticDependentLaunchControl(
                early_launch_dependent=EarlyLaunchDependent(),
            )
        ),
    )
    consumer_args = ops.GemmArguments(
        intermediate,
        B,
        output,
        torch.float32,
        performance=GemmPerformanceControls(
            pdl=ProgrammaticDependentLaunchControl(
                early_start=EarlyStart(
                    pdl_stream_serialization=True,
                    independent_operands=("B",),
                ),
            )
        ),
    )

    producer_operators = _get_operators(producer_args)
    consumer_operators = _get_operators(consumer_args)
    assert producer_operators, "Expected a PDL producer TGV operator"
    assert consumer_operators, "Expected a PDL consumer TGV operator"
    assert all(
        operator.metadata.design.pdl.early_launch_dependent
        for operator in producer_operators
    ), (
        f"Expected all producer operators to have PDL early launch dependent. {producer_operators}"
    )
    assert all(
        operator.metadata.design.pdl.early_start is not None
        for operator in consumer_operators
    ), f"Expected all consumer operators to have PDL early start. {consumer_operators}"

    def first_tgv(operators):
        try:
            return next(
                op
                for op in operators
                if op.metadata.operator_class is Sm100TgvGemmOperator
            )
        except StopIteration as err:
            raise ValueError(
                f"Expected at least one TGV operator in {operators}"
            ) from err

    producer = first_tgv(producer_operators)
    consumer = first_tgv(consumer_operators)
    producer_artifact = producer.compile(producer_args)
    consumer_artifact = consumer.compile(consumer_args)
    stream = torch.cuda.Stream()

    graph = torch.cuda.CUDAGraph(keep_graph=True)
    with torch.cuda.graph(graph, stream=stream):
        producer.run(producer_args, producer_artifact, stream=stream)
        consumer.run(consumer_args, consumer_artifact, stream=stream)

    _assert_programmatic_graph_edge(
        graph,
        expected_from_port=cuda_runtime.cudaGraphKernelNodePortProgrammatic,
    )


@pytest.mark.parametrize(
    ("trigger_at_block_start", "expected_from_port"),
    (
        (False, cuda_runtime.cudaGraphKernelNodePortProgrammatic),
        (True, cuda_runtime.cudaGraphKernelNodePortLaunchCompletion),
    ),
    ids=("trigger_at_block_start=0", "trigger_at_block_start=1"),
)
def test_tgv_pdl_programmatic_event(
    fixture_toggle_tvm_ffi,
    trigger_at_block_start,
    expected_from_port,
):
    M, K, N = 16, 256, 256
    dtype = torch.float16
    A = torch.randint(-1, 2, (M, K), device="cuda", dtype=dtype)
    B = _make_col_major_B(K, N, dtype=dtype)
    intermediate = torch.empty((M, N), device="cuda", dtype=dtype)
    output = torch.empty_like(intermediate)

    error, programmatic_event = cuda_runtime.cudaEventCreateWithFlags(
        cuda_runtime.cudaEventDisableTiming
    )
    _check_cuda(error, "cudaEventCreateWithFlags")
    stream1 = torch.cuda.Stream()
    stream2 = torch.cuda.Stream()
    graph = None

    try:
        producer_args = ops.GemmArguments(
            A,
            B,
            intermediate,
            torch.float32,
            performance=GemmPerformanceControls(
                pdl=ProgrammaticDependentLaunchControl(
                    early_launch_dependent=EarlyLaunchDependent(
                        pdl_programmatic_event=PDLProgrammaticEvent(
                            programmatic_event=programmatic_event,
                            programmatic_event_trigger_at_block_start=trigger_at_block_start,
                        ),
                    ),
                    early_start=EarlyStart(
                        independent_operands=("B",),
                    ),
                )
            ),
        )
        consumer_args = ops.GemmArguments(
            intermediate,
            B,
            output,
            torch.float32,
            performance=GemmPerformanceControls(
                pdl=ProgrammaticDependentLaunchControl(
                    early_start=EarlyStart(
                        independent_operands=("B",),
                    ),
                )
            ),
        )
        operators = _get_operators(producer_args)
        assert operators, "Expected a PDL-capable TGV operator"
        assert all(
            operator.metadata.operator_class is Sm100TgvGemmOperator
            and operator.metadata.design.pdl.early_launch_dependent
            and operator.metadata.design.pdl.early_start is not None
            for operator in operators
        )
        operator = operators[0]
        producer_artifact = operator.compile(producer_args)
        consumer_artifact = operator.compile(consumer_args)

        graph = torch.cuda.CUDAGraph(keep_graph=True)
        with torch.cuda.graph(graph, stream=stream1):
            operator.run(producer_args, producer_artifact, stream=stream1)
            (error,) = cuda_runtime.cudaStreamWaitEvent(
                cuda_runtime.cudaStream_t(stream2.cuda_stream),
                programmatic_event,
                0,
            )
            _check_cuda(error, "cudaStreamWaitEvent")
            operator.run(consumer_args, consumer_artifact, stream=stream2)
            stream1.wait_stream(stream2)

        _assert_programmatic_graph_edge(
            graph,
            expected_from_port=expected_from_port,
        )
    finally:
        del graph
        (error,) = cuda_runtime.cudaEventDestroy(programmatic_event)
        _check_cuda(error, "cudaEventDestroy")
