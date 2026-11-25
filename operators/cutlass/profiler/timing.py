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

"""CUDA timing harness with L2 cache rotation utilities.

This module provides the core profiling infrastructure:
- CUDA event-based timing
- CUDA graph capture and replay
- L2 cache rotation for fair benchmarking
"""

from __future__ import annotations

import logging
import math
from dataclasses import dataclass
from typing import TYPE_CHECKING, Literal

import torch

try:
    import cutlass.cute as cute
except ImportError:
    cute = None

from cuda.bindings import driver as cuda_driver

from cutlass.operators.workspace import Workspace

logger = logging.getLogger(__name__)

if TYPE_CHECKING:
    from collections.abc import Callable

    import cutlass.cute.typing

    import cutlass.operators as ops


# =============================================================================
# L2 Cache Rotation Utilities (from workspace.py)
# =============================================================================


def _get_tensor_bytes(tensor: torch.Tensor | cutlass.cute.typing.Tensor) -> int:
    """Get total bytes for PyTorch/CuTe tensors and CuTe-compatible tensor-like objects.

    :param tensor: PyTorch tensor or CuTe DSL tensor
    :type tensor: torch.Tensor | cutlass.cute.typing.Tensor
    """
    is_torch_tensor = isinstance(tensor, torch.Tensor)
    is_cute_tensor = cute is not None and isinstance(tensor, cute.Tensor)
    has_cute_tensor_protocol = hasattr(tensor, "shape") and hasattr(
        tensor, "element_type"
    )

    if not (is_torch_tensor or is_cute_tensor or has_cute_tensor_protocol):
        raise TypeError(
            f"Unsupported tensor type: {type(tensor)}. Expected PyTorch tensor or CuTe DSL tensor."
        )

    if is_torch_tensor:
        return tensor.nbytes

    # CuTe tensor or tensor-like object exposing CuTe-compatible fields.
    shape = tensor.shape
    num_elements = math.prod(shape) if shape else 1
    # element_type.width is in bits; use ceiling division to correctly handle
    # sub-byte types (e.g., fp4)
    total_bits = num_elements * tensor.element_type.width
    return (total_bits + 7) // 8


def _get_l2_cache_size() -> int:
    """Get the L2 cache size in bytes for the current device.

    Queries the L2 cache size from CUTLASS's HardwareInfo first, then falls back
    to the CUDA runtime helper in ``cutlass.operators.utils.device``. Raises if both fail.
    """
    last_error = None
    try:
        from cutlass.utils import HardwareInfo

        return HardwareInfo().get_l2_cache_size_in_bytes()
    except Exception as e:
        last_error = e
    try:
        from cutlass.operators.utils.device import device_l2_cache_size

        return device_l2_cache_size()
    except Exception as e:
        last_error = e
    raise RuntimeError(
        "Failed to query L2 cache size (cutlass.utils.HardwareInfo and CUDA runtime). "
        "Profiling requires a valid CUDA device and L2 cache info."
    ) from last_error


def compute_l2_rotation_count_from_bytes(
    arg_bytes: int,
    warmup_iterations: int,
    profiling_iterations: int,
    workspace_count: int | str = "auto",
) -> int:
    """Compute argument rotation count from metadata-derived storage bytes."""
    if workspace_count != "auto":
        return int(workspace_count)
    if arg_bytes <= 0:
        raise ValueError(f"Argument storage bytes must be positive, got {arg_bytes}")

    l2_cache_bytes = _get_l2_cache_size()
    # formula: num_args = (l2_cache_size x 3) / arg_bytes + 1
    num_args = (l2_cache_bytes * 3) // arg_bytes + 1
    # cap at total iterations to avoid over-allocation
    total_iterations = warmup_iterations + profiling_iterations
    return min(num_args, total_iterations)


@dataclass(frozen=True)
class BenchmarkOptions:
    """Effective iteration and argument-rotation settings for a benchmark."""

    arg_count: int
    warmup_iterations: int
    profiling_iterations: int


def resolve_benchmark_options(
    *,
    measure_performance: bool,
    arg_bytes: int,
    warmup_iterations: int,
    profiling_iterations: int,
    workspace_count: int | str = "auto",
) -> BenchmarkOptions:
    """Resolve effective benchmark settings from profiler configuration.

    L2 rotation, warmups, and repeated timed iterations are enabled only when
    performance measurement is explicitly requested.
    """
    if warmup_iterations < 0:
        raise ValueError("warmup_iterations must be non-negative")
    if profiling_iterations <= 0:
        raise ValueError("profiling_iterations must be positive")
    if not measure_performance:
        return BenchmarkOptions(
            arg_count=1,
            warmup_iterations=0,
            profiling_iterations=1,
        )

    return BenchmarkOptions(
        arg_count=compute_l2_rotation_count_from_bytes(
            arg_bytes,
            warmup_iterations,
            profiling_iterations,
            workspace_count,
        ),
        warmup_iterations=warmup_iterations,
        profiling_iterations=profiling_iterations,
    )


# =============================================================================
# CUDA Error Handling
# =============================================================================


def _cuda_check(err, msg: str = "cuda error"):
    """Check CUDA error and raise exception if failed.

    Handles both CUDA Runtime API (cudaError_t) and Driver API (CUresult) errors,
    providing human-readable error messages.

    :param err: CUDA error code or tuple containing error code
    :param msg: Error message to include in exception
    :raises RuntimeError: If error code is non-zero
    """
    from cuda.bindings import runtime as cuda_runtime

    # handle tuple returns (err, result) from some cuda apis
    if isinstance(err, tuple):
        err = err[0]

    # Check for Runtime API errors (cudaError_t)
    if isinstance(err, cuda_runtime.cudaError_t):
        if err != cuda_runtime.cudaError_t.cudaSuccess:
            error_message = cuda_runtime.cudaGetErrorString(err)[1].decode("utf-8")
            raise RuntimeError(f"{msg}: {error_message}")
    # Check for Driver API errors (CUresult)
    elif isinstance(err, cuda_driver.CUresult):
        if err != cuda_driver.CUresult.CUDA_SUCCESS:
            error_message = cuda_driver.cuGetErrorString(err)[1].decode("utf-8")
            raise RuntimeError(f"{msg}: {error_message}")
    # Fallback for unknown types
    elif hasattr(err, "value") and err.value != 0:
        raise RuntimeError(f"{msg}: error code {err.value}")


# =============================================================================
# Benchmark Functions
# =============================================================================


def _benchmark_operator(
    operator: ops.Operator,
    arg_factory: Callable[[], ops.RuntimeArguments],
    first_args: ops.RuntimeArguments | None,
    arg_count: int,
    warmup_iterations: int = 10,
    profiling_iterations: int = 100,
    use_cuda_graphs: bool = False,
    timing_method: Literal["cuda_events"] = "cuda_events",
    stream: cuda_driver.CUstream | None = None,
) -> float:
    """Benchmark a CUTLASS Operator with argument rotation for L2 cache fairness.

    This is the low-level function that requires an argument generator. The operator is compiled
    once with the first arguments and then executed multiple times with rotated arguments to
    ensure fair L2 cache measurements.

    :param operator: CUTLASS Operator instance
    :type operator: Operator
    :param arg_factory: Callable that creates runtime arguments
    :type arg_factory: Callable[[], RuntimeArguments]
    :param first_args: Existing arguments to use as the first rotation workspace
    :type first_args: Optional[RuntimeArguments]
    :param arg_count: Number of argument sets to create for rotation
    :type arg_count: int
    :param warmup_iterations: Number of iterations before timing starts. Defaults to 10.
    :type warmup_iterations: int
    :param profiling_iterations: Number of timed iterations. Defaults to 100.
    :type profiling_iterations: int
    :param use_cuda_graphs: Whether to capture and replay via CUDA graphs. Defaults to False.
    :type use_cuda_graphs: bool
    :param stream: CUDA stream to use. If None, uses the default stream.
    :type stream: Optional[cuda_driver.CUstream]

    :return: Average time per iteration in microseconds
    :rtype: float
    """
    from cuda.bindings import runtime as cuda_runtime

    created_stream = False
    if stream is None:
        if use_cuda_graphs:
            # CUDA graph capture requires a non-default stream
            # Create a Runtime API stream which is compatible with both APIs
            err, stream = cuda_runtime.cudaStreamCreate()
            _cuda_check(err, "failed to create stream for graph capture")
            created_stream = True
        else:
            stream = cuda_driver.CUstream(0)

    try:
        return _benchmark_operator_impl(
            operator,
            arg_factory,
            first_args,
            arg_count,
            warmup_iterations,
            profiling_iterations,
            use_cuda_graphs,
            timing_method,
            stream,
        )
    finally:
        if created_stream:
            cuda_runtime.cudaStreamDestroy(stream)


def _benchmark_operator_impl(
    operator: ops.Operator,
    arg_factory: Callable[[], ops.RuntimeArguments],
    first_args: ops.RuntimeArguments | None,
    arg_count: int,
    warmup_iterations: int,
    profiling_iterations: int,
    use_cuda_graphs: bool,
    timing_method: Literal["cuda_events"],
    stream,
) -> float:
    # pre-compile operator with first args
    if first_args is None:
        first_args = arg_factory()
    compiled_artifact = operator.compile(first_args)

    # Allocate and initialize the operator's workspace once. Every rotated
    # args set shares the problem shape, so one buffer serves all launches.
    workspace = None
    requirement = operator.get_workspace_size(first_args)
    if requirement.size_bytes > 0:
        buffer = torch.empty(requirement.size_bytes, device="cuda", dtype=torch.uint8)
        workspace = Workspace(data=buffer)
        operator.initialize_workspace(first_args, workspace)

    # create args collection for rotation
    args_collection = [first_args] + [arg_factory() for _ in range(arg_count - 1)]

    def _loop_and_call_operator(iterations: int, arg_index: int = 0) -> int:
        for _ in range(iterations):
            current_args = args_collection[arg_index]
            operator.run(
                current_args,
                compiled_artifact=compiled_artifact,
                stream=stream,
                workspace=workspace,
            )
            arg_index = (arg_index + 1) % arg_count
        return arg_index

    if timing_method != "cuda_events":
        raise ValueError(f"Unsupported timing method: {timing_method}")

    if use_cuda_graphs:
        return _benchmark_with_graphs(
            _loop_and_call_operator,
            warmup_iterations,
            profiling_iterations,
            stream,
        )
    return _benchmark_direct(
        _loop_and_call_operator,
        warmup_iterations,
        profiling_iterations,
        stream,
    )


def _benchmark_direct(
    loop_fn: Callable[[int, int], int],
    warmup_iterations: int,
    profiling_iterations: int,
    stream: cuda_driver.CUstream,
) -> float:
    # create events
    err, start_event = cuda_driver.cuEventCreate(
        cuda_driver.CUevent_flags.CU_EVENT_DEFAULT
    )
    _cuda_check(err, "failed to create start event")

    err, end_event = cuda_driver.cuEventCreate(
        cuda_driver.CUevent_flags.CU_EVENT_DEFAULT
    )
    _cuda_check(err, "failed to create end event")

    try:
        # warmup
        arg_index = loop_fn(warmup_iterations, 0)

        # timed phase
        err = cuda_driver.cuEventRecord(start_event, stream)
        _cuda_check(err, "failed to record start event")

        loop_fn(profiling_iterations, arg_index)

        err = cuda_driver.cuEventRecord(end_event, stream)
        _cuda_check(err, "failed to record end event")

        # synchronize and get elapsed time
        err = cuda_driver.cuEventSynchronize(end_event)
        _cuda_check(err, "failed to synchronize")

        err, elapsed_ms = cuda_driver.cuEventElapsedTime(start_event, end_event)
        _cuda_check(err, "failed to get elapsed time")

        time_us = (elapsed_ms / profiling_iterations) * 1000.0

        return time_us

    finally:
        cuda_driver.cuEventDestroy(start_event)
        cuda_driver.cuEventDestroy(end_event)


def _benchmark_with_graphs(
    loop_fn: Callable[[int, int], int],
    warmup_iterations: int,
    profiling_iterations: int,
    stream: cuda_driver.CUstream,
) -> float:
    from cuda.bindings import runtime as cuda_runtime

    # create events
    err, start_event = cuda_driver.cuEventCreate(
        cuda_driver.CUevent_flags.CU_EVENT_DEFAULT
    )
    _cuda_check(err, "failed to create start event")

    err, end_event = cuda_driver.cuEventCreate(
        cuda_driver.CUevent_flags.CU_EVENT_DEFAULT
    )
    _cuda_check(err, "failed to create end event")

    warmup_graph_exec = None
    profile_graph_exec = None

    try:
        # capture warmup graph
        err = cuda_runtime.cudaStreamBeginCapture(
            stream, cuda_runtime.cudaStreamCaptureMode.cudaStreamCaptureModeGlobal
        )
        _cuda_check(err, "failed to begin warmup capture")

        arg_index = loop_fn(warmup_iterations, 0)

        err, warmup_graph = cuda_runtime.cudaStreamEndCapture(stream)
        _cuda_check(err, "failed to end warmup capture")

        # instantiate warmup graph
        err, warmup_graph_exec = cuda_runtime.cudaGraphInstantiate(warmup_graph, 0)
        _cuda_check(err, "failed to instantiate warmup graph")

        # capture profiling graph
        err = cuda_runtime.cudaStreamBeginCapture(
            stream, cuda_runtime.cudaStreamCaptureMode.cudaStreamCaptureModeGlobal
        )
        _cuda_check(err, "failed to begin profile capture")

        loop_fn(profiling_iterations, arg_index)

        err, profile_graph = cuda_runtime.cudaStreamEndCapture(stream)
        _cuda_check(err, "failed to end profile capture")

        # instantiate profiling graph
        err, profile_graph_exec = cuda_runtime.cudaGraphInstantiate(profile_graph, 0)
        _cuda_check(err, "failed to instantiate profile graph")

        # execute warmup
        err = cuda_runtime.cudaGraphLaunch(warmup_graph_exec, stream)
        _cuda_check(err, "failed to launch warmup graph")

        # time profiling graph
        err = cuda_driver.cuEventRecord(start_event, stream)
        _cuda_check(err, "failed to record start event")

        err = cuda_runtime.cudaGraphLaunch(profile_graph_exec, stream)
        _cuda_check(err, "failed to launch profile graph")

        err = cuda_driver.cuEventRecord(end_event, stream)
        _cuda_check(err, "failed to record end event")

        # synchronize and get elapsed time
        err = cuda_driver.cuEventSynchronize(end_event)
        _cuda_check(err, "failed to synchronize")

        err, elapsed_ms = cuda_driver.cuEventElapsedTime(start_event, end_event)
        _cuda_check(err, "failed to get elapsed time")

        time_us = (elapsed_ms / profiling_iterations) * 1000.0

        return time_us

    finally:  # need to destroy objects to avoid memory leaks if exception is raised
        if warmup_graph_exec is not None:
            cuda_runtime.cudaGraphExecDestroy(warmup_graph_exec)
        if profile_graph_exec is not None:
            cuda_runtime.cudaGraphExecDestroy(profile_graph_exec)
        cuda_driver.cuEventDestroy(start_event)
        cuda_driver.cuEventDestroy(end_event)


def benchmark_operator(
    operator: ops.Operator,
    benchmark_options: BenchmarkOptions,
    operator_args: ops.RuntimeArguments | None = None,
    arg_factory: Callable[[], ops.RuntimeArguments] | None = None,
    use_cuda_graphs: bool = False,
    timing_method: Literal["cuda_events"] = "cuda_events",
    stream: cuda_driver.CUstream | None = None,
) -> float:
    """Benchmark a CUTLASS Operator with optional argument rotation.

    This is a convenience function for benchmarking operators. Either operator_args or
    arg_factory must be provided. When both are supplied, operator_args is reused as
    the first workspace and arg_factory creates any additional rotation workspaces.

    :param operator: CUTLASS Operator instance
    :type operator: Operator
    :param benchmark_options: Effective iteration and argument-rotation settings.
    :type benchmark_options: BenchmarkOptions
    :param operator_args: Runtime arguments to reuse as the first workspace. Defaults to None.
    :type operator_args: Optional[RuntimeArguments]
    :param arg_factory: Callable that creates additional runtime arguments.
    :type arg_factory: Optional[Callable[[], RuntimeArguments]]
    :param use_cuda_graphs: Whether to capture and replay via CUDA graphs. Defaults to False.
    :type use_cuda_graphs: bool
    :param timing_method: Timing backend to use. Defaults to "cuda_events".
    :type timing_method: Literal["cuda_events"]
    :type stream: Optional[cuda_driver.CUstream]
    :param stream: CUDA stream to use. If None, uses the default stream. Defaults to None.
    :type stream: Optional[cuda_driver.CUstream]

    :return: Average time per iteration in microseconds
    :rtype: float
    :raises ValueError: If benchmark options or argument construction are invalid.
    """
    if benchmark_options.arg_count <= 0:
        raise ValueError("benchmark_options.arg_count must be positive")
    if benchmark_options.warmup_iterations < 0:
        raise ValueError("benchmark_options.warmup_iterations must be non-negative")
    if benchmark_options.profiling_iterations <= 0:
        raise ValueError("benchmark_options.profiling_iterations must be positive")
    if arg_factory is None:
        if benchmark_options.arg_count != 1:
            raise ValueError("arg_count must be 1 when not providing arg_factory")
        if operator_args is None:
            raise ValueError("must provide operator_args or arg_factory")

        def arg_factory():
            return operator_args

    return _benchmark_operator(
        operator=operator,
        arg_factory=arg_factory,
        first_args=operator_args,
        arg_count=benchmark_options.arg_count,
        warmup_iterations=benchmark_options.warmup_iterations,
        profiling_iterations=benchmark_options.profiling_iterations,
        use_cuda_graphs=use_cuda_graphs,
        timing_method=timing_method,
        stream=stream,
    )
