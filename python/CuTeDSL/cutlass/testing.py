# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/latest/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.


import argparse
import logging
import os
from dataclasses import dataclass
from functools import partial
from itertools import product
from time import time
from typing import Any, Callable, Dict, List, Optional, Type, Union

import cuda.bindings.driver as cuda_driver
import cuda.bindings.runtime as cuda_runtime

from cutlass.cute.typing import Int8, Numeric, Uint8


class CuptiProfiler:
    """A class for managing CUPTI profiling measurements with start, stop, and duration methods.

    This class provides a clean interface for measuring CUDA kernel execution times
    using CUPTI (CUDA Profiling Tools Interface). It encapsulates the complexity
    of buffer management, callback registration, and activity tracking.

    Example usage:
        profiler = CuptiProfiler()
        profiler.start()
        # ... run your CUDA kernels ...
        profiler.stop()
        duration = profiler.get_duration()  # Returns total duration in milliseconds
    """

    def __init__(self, buffer_size: int = 8 * 1024 * 1024) -> None:
        """Initialize the CUPTI profiler.

        Args:
            buffer_size: Size of the CUPTI buffer in bytes (default: 8MB)

        Raises:
            ImportError: If the cupti-python package is not installed
        """
        try:
            from cupti import cupti

            self._cupti = cupti
        except ModuleNotFoundError:
            raise ModuleNotFoundError(
                "CUPTI is not available. Install the 'cupti-python' package to use CuptiProfiler."
            )
        self.buffer_size = buffer_size
        self.timings: list[tuple[str, float]] = []
        self._is_active = False
        self._buffer_requested_callback: Optional[Callable[..., Any]] = None
        self._buffer_completed_callback: Optional[Callable[..., Any]] = None

    def _buffer_requested(self) -> tuple[int, int]:
        """Internal callback for CUPTI buffer requests."""
        max_num_records = 0
        return self.buffer_size, max_num_records

    def _buffer_completed(self, activities: list[Any]) -> None:
        """Internal callback for processing completed CUPTI activities."""
        for activity in activities:
            start: Any = activity.start if hasattr(activity, "start") else "nil"
            end: Any = activity.end if hasattr(activity, "end") else "nil"
            if start != "nil" and end != "nil":
                duration: Any = end - start
            else:
                duration = "nil"
            name = activity.name[:100] if hasattr(activity, "name") else "unknown"
            # Convert to milliseconds
            if duration != "nil":
                self.timings.append((name, duration / 1e6))

    def start(self) -> None:
        """Start CUPTI profiling.

        Enables CUPTI activity tracking for concurrent kernels and registers
        the necessary callbacks for buffer management.

        Raises:
            ValueError: If CUPTI activity cannot be enabled
        """
        if self._is_active:
            raise RuntimeError("CUPTI profiler is already active")

        # Clear previous timings
        self.timings = []

        try:
            self._cupti.activity_enable(self._cupti.ActivityKind.CONCURRENT_KERNEL)
        except self._cupti.cuptiError as e:
            raise ValueError(
                f"\033[91mError while enabling Activity Kind {self._cupti.ActivityKind.CONCURRENT_KERNEL.name}: {e}. Please disable CUPTI if you using profilers\033[0m"
            )

        # Register callbacks
        self._buffer_requested_callback = self._buffer_requested
        self._buffer_completed_callback = partial(self._buffer_completed)

        self._cupti.activity_register_callbacks(
            self._buffer_requested_callback, self._buffer_completed_callback
        )

        self._is_active = True

    def stop(self) -> None:
        """Stop CUPTI profiling.

        Flushes all activities, disables CUPTI tracking, and finalizes the profiler.
        This method should be called after the kernels you want to measure have completed.
        """
        if not self._is_active:
            raise RuntimeError("CUPTI profiler is not active")

        # Flush all activities and cleanup
        self._cupti.activity_flush_all(0)
        self._cupti.activity_disable(self._cupti.ActivityKind.CONCURRENT_KERNEL)
        self._cupti.finalize()

        self._is_active = False

    def get_duration(self) -> float:
        """Get the total duration of all measured activities in milliseconds.

        Returns:
            Total duration in milliseconds. Returns 0.0 if no activities were recorded.
        """
        return sum(timing[1] for timing in self.timings)


#########################################
# Testing utilities
#########################################


def sample_pytest(rand_cfg: Optional[tuple[int, float]] = None) -> Callable[..., Any]:
    """
    Decorator to randomly sample pytest parametrized tests.
    rand_cfg: Tuple[int, float] - (random_seed, sample_ratio)
    Sampling is disabled when:
    - A specific test is selected (via -k or direct test path)
    - Not running under pytest
    """
    import functools
    import os
    import random
    import sys

    import pytest

    if rand_cfg is not None:
        seed, sample_ratio = rand_cfg
        random.seed(seed)
    else:
        sample_ratio = 1.0  # No sampling when rand_cfg is None

    def decorator(func: Callable[..., Any]) -> Callable[..., Any]:
        @functools.wraps(func)
        def wrapper(*args: Any, **kwargs: Any) -> Any:
            if rand_cfg is not None and "PYTEST_CURRENT_TEST" in os.environ:
                # Check if test was explicitly selected like ::test_name[param1-param2-...]
                if "-k" in sys.argv or any(".py::" in arg for arg in sys.argv):
                    # Test was explicitly selected, don't skip
                    return func(*args, **kwargs)

                if random.uniform(0.0, 1.0) > sample_ratio:
                    pytest.skip(f"Randomly skipped (sampling ratio: {sample_ratio})")
            return func(*args, **kwargs)

        return wrapper

    return decorator


#########################################
# Benchmarking utilities
#########################################


class JitArguments:
    """
    A type to hold both args and kwargs for passing to a kernel while benchmarking.
    """

    def __init__(self, *args: Any, **kwargs: Any) -> None:
        self.args = args
        self.kwargs = kwargs
        self.references: list[Any] = list()

    def add_to_scope(self, references: Any) -> None:
        """
        Keeps references to external variables (e.g., Torch tensors when taking a view)
        in the scope of the lifetime of the JitArguments object.
        """
        self.references.extend(references)


def _cuda_success(
    err: Union[tuple[Any, ...], cuda_runtime.cudaError_t, cuda_driver.CUresult],
    message: str,
) -> None:
    """
    Helper function to check CUDA API errors.
    """
    if isinstance(err, tuple):
        _cuda_success(err[0], message)
    elif isinstance(err, cuda_runtime.cudaError_t):
        error_message = cuda_runtime.cudaGetErrorString(err)[1].decode("utf-8")
        if err != cuda_runtime.cudaError_t.cudaSuccess:
            raise RuntimeError(f"{message} : {error_message}")
    elif isinstance(err, cuda_driver.CUresult):
        if err != cuda_driver.CUresult.CUDA_SUCCESS:
            error_message = cuda_driver.cuGetErrorString(err)[1].decode("utf-8")
            raise RuntimeError(f"{message} : {error_message}")
    else:
        raise TypeError(
            f"{err} is an unexpected type : it should be a cudaError_t or CUresult"
        )


def _does_kernel_use_stream(
    kernel: Callable[..., Any],
    stream: cuda_driver.CUstream,
    args: tuple[Any, ...],
    kwargs: dict[str, Any],
) -> bool:
    """
    This function checks if the kernel uses the provided non-default stream.
    It does this by capturing the stream and then checking whether any work was
    recorded on it. A kernel that launches on a different stream records no nodes;
    on more recent drivers such a foreign-stream launch additionally fails
    fast during capture. Both outcomes are reported as "does not use the stream"
    (return False) rather than propagated, so callers can raise a clear error.

    Note: the function accepts positional/keyword arguments for the kernel in non-unpacked form
    (as tuple/dict, respectively) to avoid name clashes with function's own arguments (e.g. stream).

    :param kernel: The kernel to check
    :type kernel: Callable
    :param stream: The stream to check
    :type stream: cuda_driver.CUstream
    :param args: Positional arguments to pass to the kernel
    :type args: tuple[Any, ...]
    :param kwargs: Keyword arguments to pass to the kernel
    :type kwargs: dict[str, Any]
    :return: True if the kernel uses the stream, False otherwise
    :rtype: bool
    """

    assert int(stream) != int(cuda_driver.CUstream_flags.CU_STREAM_DEFAULT), (
        "Stream must be a non-default stream"
    )

    err = cuda_runtime.cudaStreamBeginCapture(
        stream, cuda_runtime.cudaStreamCaptureMode.cudaStreamCaptureModeThreadLocal
    )
    _cuda_success(err, "Error on stream capture")

    launch_error = None
    try:
        kernel(*args, **kwargs)
    except Exception as exc:
        launch_error = exc

    err, graph = cuda_runtime.cudaStreamEndCapture(stream)
    if err != cuda_runtime.cudaError_t.cudaSuccess:
        if launch_error is not None:
            raise launch_error
        _cuda_success(err, "Error on stream capture")

    err, _, num_nodes = cuda_runtime.cudaGraphGetNodes(graph)
    _cuda_success(err, "Error on querying graph")

    if num_nodes > 0:
        if launch_error is not None:
            raise launch_error
        return True

    return False


def benchmark(
    callable: Callable,
    *,
    warmup_iterations: int = 10,
    iterations: int = 100,
    stream: Optional[cuda_driver.CUstream] = None,
    kernel_arguments: Optional[JitArguments] = None,
    workspace_generator: Optional[Callable[[], JitArguments]] = None,
    workspace_count: int = 1,
    use_cuda_graphs: bool = False,
    use_cupti: bool = False,
) -> float:
    """Benchmarks a callable function with the specified parameters.

    For example,
    .. code-block:: python

        from cutlass.testing import benchmark

        @cute.jit
        def user_function(a: cute.Tensor, b: cute.Tensor, c: cute.Tensor, stream: cuda_driver.CUstream):
            # contents of the function
            pass

        time_us = benchmark(user_function, kernel_arguments=JitArguments(a, b, c, stream)
                            warmup_iterations=10, iterations=100
                            stream=stream)

    To prevent skewing results by repeately accessing the L2 cache, use the workspace_count and workspace_generator
    parameters to cycle through a number of different workspaces.

    .. code-block:: python

        from cutlass.testing import benchmark

        @cute.jit
        def user_function(a: cute.Tensor, b: cute.Tensor, c: cute.Tensor):
            # contents of the function
            pass

        def workspace_generator():
            # create a, b, and c
            return JitArguments(a, b, c)

        time_us = benchmark(user_function,
                            workspace_generator=workspace_generator,
                            workspace_count=10,
                            warmup_iterations=10000,
                            iterations=1000)

    To benchmark you may always configure the function being profiled (callable), the warmup iterations, and
    the number of profiling iterations.

    Whenever the kernel being benchmarked runs in a non-default stream, the stream must be provided through the stream parameter.

    To use CUDA graphs, the callable must be a compiled @cute.jit annotated function.
    When using CUDA graphs, the kernel must be launched in a non-default stream.

    :param callable: The function to benchmark. For jit function, it must be compiled functions.
    :type callable: Callable
    :param warmup_iterations: Number of warmup iterations, defaults to 10
    :type warmup_iterations: int, optional
    :param iterations: Number of benchmark iterations, defaults to 100
    :type iterations: int, optional
    :param stream: Stream kernel is launched in, defaults to CUDA stream default
    :type stream: CUstream, None
    :param kernel_arguments: Kernel arguments to launch callable with, defaults to None
    :type kernel_arguments: JitArguments, None
    :param workspace_generator: Function that returns kernel arguments, defaults to None
    :type workspace_generator: Callable
    :param workspace_count: Number of workspaces (arguments) to loop through, looping through enough workspaces will keep the L2 cache cold
    :type workspace_count: int, optional
    :param use_cuda_graphs: Whether to use cuda graphs, defaults to False
    :type use_cuda_graphs: bool, optional

    :return: The benchmark time in microseconds
    :rtype: float
    """
    import cutlass.base_dsl.jit_executor  # noqa: F401
    import cutlass.cutlass_dsl.cuda_jit_executor  # noqa: F401

    if stream is None:
        stream = cuda_driver.CUstream(cuda_driver.CUstream_flags.CU_STREAM_DEFAULT)

    if workspace_count < 1:
        raise ValueError("workspace_count must be at least 1")

    _time_us = float("nan")
    if workspace_generator == None:
        # If no workspace generator is provided, we need a single workspace
        if workspace_count != 1:
            raise ValueError("Need a single workspace if not providing a generator")

        # If no workspace generator is provided, we need a kernel_argument
        if kernel_arguments == None:
            raise ValueError(
                "Please pass a kernel argument if not providing a generator"
            )
        workspace_generator = lambda: kernel_arguments

    workspaces = [workspace_generator() for _ in range(workspace_count)]

    for workspace in workspaces:
        if not isinstance(workspace, JitArguments):
            raise TypeError(
                "workspace_generator and/or kernel_arguments should use JitArguments type"
            )

    if (
        not use_cuda_graphs
        and int(stream) != int(cuda_driver.CUstream_flags.CU_STREAM_DEFAULT)
        and not _does_kernel_use_stream(
            callable, stream, workspaces[0].args, workspaces[0].kwargs
        )
    ):
        raise ValueError(
            "CUDA stream passed to benchmark does not match the stream the kernel was launched in"
        )

    # use memset to flush L2 cache after workspace h2d copies
    if workspace_count > 1:
        from cutlass.utils import HardwareInfo

        hardware_info = HardwareInfo()
        num_l2_cache_bytes = hardware_info.get_l2_cache_size_in_bytes()
        l2_flush_bytes = num_l2_cache_bytes * 2
        err, cache_ptr = cuda_driver.cuMemAlloc(int(l2_flush_bytes))
        _cuda_success(err, "Error on allocating memory")

        err = cuda_driver.cuMemsetD32Async(
            cache_ptr, 0, int(l2_flush_bytes // 4), stream
        )
        _cuda_success(err, "Error on memset")

        err = cuda_driver.cuMemFree(cache_ptr)
        _cuda_success(err, "Error on freeing memory")

    def _loop_and_call_kernel(iterations: int, workspace_index: int = 0) -> int:
        for _ in range(iterations):
            current_workspace = workspaces[workspace_index]
            callable(*current_workspace.args, **current_workspace.kwargs)
            workspace_index = (workspace_index + 1) % workspace_count
        return workspace_index

    # Create CUDA events for timing
    err, start_event = cuda_driver.cuEventCreate(
        cuda_driver.CUevent_flags.CU_EVENT_DEFAULT
    )
    _cuda_success(err, "Error on creating event")
    err, end_event = cuda_driver.cuEventCreate(
        cuda_driver.CUevent_flags.CU_EVENT_DEFAULT
    )
    _cuda_success(err, "Error on creating event")

    elapsed_time = float("nan")

    # =========================================================================
    # Helper: Measure kernel execution time using CUPTI profiler
    # =========================================================================
    def _measure_with_cupti(kernel_launcher: Callable[[], Any]) -> float:
        """
        Measure kernel execution time using NVIDIA CUPTI profiler.
        :param kernel_launcher: Callable that launches the kernel(s) to be profiled
        :type kernel_launcher: Callable
        :return: Elapsed time in milliseconds
        :rtype: float
        """
        if not hasattr(kernel_launcher, "__call__"):
            raise TypeError(
                f"kernel_launcher must be callable, got {type(kernel_launcher).__name__}"
            )

        cupti_profiler = CuptiProfiler()

        cupti_profiler.start()
        kernel_launcher()

        err = cuda_runtime.cudaDeviceSynchronize()
        _cuda_success(err, "Error on synchronizing device")

        cupti_profiler.stop()
        duration_ms = cupti_profiler.get_duration()
        return duration_ms

    def _measure_with_cuda_event(kernel_launcher: Callable[[], Any]) -> float:
        """
        Measure kernel execution time using CUDA events.
        :param kernel_launcher: Callable that launches the kernel(s) to be profiled
        :type kernel_launcher: Callable
        :return: Elapsed time in milliseconds
        :rtype: float
        """
        if not hasattr(kernel_launcher, "__call__"):
            raise TypeError(
                f"kernel_launcher must be callable, got {type(kernel_launcher).__name__}"
            )

        err = cuda_driver.cuEventRecord(start_event, stream)
        _cuda_success(err, "Error on recording start event")

        kernel_launcher()

        err = cuda_driver.cuEventRecord(end_event, stream)
        _cuda_success(err, "Error on recording end event")

        err = cuda_driver.cuEventSynchronize(end_event)
        _cuda_success(err, "Error on synchronizing end event")

        err, duration_ms = cuda_driver.cuEventElapsedTime(start_event, end_event)
        _cuda_success(err, "Error on querying elapsed time")
        return duration_ms

    # =========================================================================
    # Branch 1: CUDA Graphs mode - Capture and replay kernel execution
    # =========================================================================
    if use_cuda_graphs:
        if hasattr(callable, "_dsl_cls"):
            raise TypeError(
                "Uncompiled @cute.jit function cannot be captured into a CUDA Graph. "
                "Use cute.compile() first, or wrap compiled calls in a plain function."
            )

        # ---------------------------------------------------------------------
        # Step 1: Capture warmup graph
        # ---------------------------------------------------------------------
        import gc as _gc

        # Disable GC during capture to prevent __del__ methods (e.g., cudaFree)
        # from invalidating the capture with a non-capturable CUDA call.
        _gc.collect()
        _gc.disable()
        err = cuda_runtime.cudaStreamBeginCapture(
            stream, cuda_runtime.cudaStreamCaptureMode.cudaStreamCaptureModeThreadLocal
        )
        _cuda_success(err, "Error on beginning warmup stream capture")

        try:
            warmup_workspace_idx = _loop_and_call_kernel(warmup_iterations)
        except Exception:
            _gc.enable()
            try:
                cuda_runtime.cudaStreamEndCapture(stream)
            except Exception:
                pass
            raise

        err, warmup_graph = cuda_runtime.cudaStreamEndCapture(stream)
        _gc.enable()
        _cuda_success(err, "Error on ending warmup stream capture")

        # Validate warmup graph node count
        # Each kernel launch should produce at least one graph node
        err, _, warmup_node_count = cuda_runtime.cudaGraphGetNodes(warmup_graph)
        _cuda_success(err, "Error on querying warmup graph nodes")
        # Use >= since one host function may launch multiple kernels
        if warmup_node_count < warmup_iterations:
            raise ValueError(
                "CUDA stream passed to benchmark does not match the stream the kernel was launched in"
            )

        # ---------------------------------------------------------------------
        # Step 2: Capture profiling graph
        # ---------------------------------------------------------------------
        _gc.collect()
        _gc.disable()
        err = cuda_runtime.cudaStreamBeginCapture(
            stream, cuda_runtime.cudaStreamCaptureMode.cudaStreamCaptureModeThreadLocal
        )
        _cuda_success(err, "Error on beginning profiling stream capture")

        try:
            _loop_and_call_kernel(iterations, warmup_workspace_idx)
        except Exception:
            _gc.enable()
            try:
                cuda_runtime.cudaStreamEndCapture(stream)
            except Exception:
                pass
            raise

        err, profiling_graph = cuda_runtime.cudaStreamEndCapture(stream)
        _gc.enable()
        _cuda_success(err, "Error on ending profiling stream capture")

        # ---------------------------------------------------------------------
        # Step 3: Instantiate executable graphs
        # ---------------------------------------------------------------------
        err, warmup_graph_exec = cuda_runtime.cudaGraphInstantiate(warmup_graph, 0)
        _cuda_success(err, "Error on instantiating warmup graph")
        err, profiling_graph_exec = cuda_runtime.cudaGraphInstantiate(
            profiling_graph, 0
        )
        _cuda_success(err, "Error on instantiating profiling graph")

        # ---------------------------------------------------------------------
        # Step 4: Execute warmup graph (cache warming)
        # ---------------------------------------------------------------------
        err = cuda_runtime.cudaGraphLaunch(warmup_graph_exec, stream)
        _cuda_success(err, "Error on launching warmup graph")

        # ---------------------------------------------------------------------
        # Step 5: Profile execution using selected profiler
        # ---------------------------------------------------------------------
        def launch_profiling_graph() -> None:
            err = cuda_runtime.cudaGraphLaunch(profiling_graph_exec, stream)
            _cuda_success(err, "Error on launching profiling graph")

        if use_cupti:
            elapsed_time = _measure_with_cupti(launch_profiling_graph)
        else:
            elapsed_time = _measure_with_cuda_event(launch_profiling_graph)

        # ---------------------------------------------------------------------
        # Step 6: Cleanup - Destroy graph executables
        # ---------------------------------------------------------------------
        err = cuda_runtime.cudaGraphExecDestroy(warmup_graph_exec)
        _cuda_success(err, "Error on destroying warmup graph executable")
        err = cuda_runtime.cudaGraphExecDestroy(profiling_graph_exec)
        _cuda_success(err, "Error on destroying profiling graph executable")

    # =========================================================================
    # Branch 2: CUPTI profiler mode (without CUDA Graphs)
    # =========================================================================
    elif use_cupti:
        # Warmup iterations to stabilize GPU state
        warmup_workspace_idx = _loop_and_call_kernel(warmup_iterations)

        def run_profiling_iterations() -> None:
            _loop_and_call_kernel(iterations, warmup_workspace_idx)

        elapsed_time = _measure_with_cupti(run_profiling_iterations)

    # =========================================================================
    # Branch 3: CUDA event profiler mode (default)
    # =========================================================================
    else:
        # Warmup iterations to stabilize GPU state
        warmup_workspace_idx = _loop_and_call_kernel(warmup_iterations)

        def run_profiling_iterations() -> None:
            _loop_and_call_kernel(iterations, warmup_workspace_idx)

        elapsed_time = _measure_with_cuda_event(run_profiling_iterations)

    # Destroy events
    err = cuda_driver.cuEventDestroy(start_event)
    _cuda_success(err, "Error on destroying event")
    err = cuda_driver.cuEventDestroy(end_event)
    _cuda_success(err, "Error on destroying event")

    return elapsed_time / iterations * 1e3


def get_workspace_count(
    one_workspace_bytes: int, warmup_iterations: int, iterations: int
) -> int:
    """Calculate the number of workspaces needed to fill L2 cache.

    :param one_workspace_bytes: Size of one workspace in bytes
    :type one_workspace_bytes: int
    :param warmup_iterations: Number of warmup iterations
    :type warmup_iterations: int
    :param iterations: Number of iterations
    :type iterations: int
    :return: Number of workspaces needed
    :rtype: int
    """
    from cutlass.utils import HardwareInfo

    num_l2_cache_bytes = HardwareInfo().get_l2_cache_size_in_bytes()
    num_workspaces = (num_l2_cache_bytes * 3) // one_workspace_bytes + 1
    num_iters = warmup_iterations + iterations
    return num_iters if num_iters < num_workspaces else num_workspaces


#########################################
# Autotuning/Tuning utilities
#########################################


def _benchmark_for_autotune(
    callable: Callable[..., Any],
    *args: Any,
    warmup_iterations: int,
    iterations: int,
    use_cold_l2: bool,
    print_verbose: bool,
    current_stream: Optional[cuda_driver.CUstream] = None,
    **kwargs: Any,
) -> float:
    """Benchmarks a callable function with the specified parameters.

    This function differs from the benchmark function in that it is used for autotuning. In this case we
    do not loop through workspaces to keep the L2 cache cold. Instead we rely on writing to an L2 cache sized address to keep the L2 cache cold.

    The primary reason for doing this is that we do not have information on how to generate the workspaces for the kernel when autotuning.
    We also do not have information on how much memory the workspaces take up.

    This benchmarking is done as a close approximation of the actual runtime of the kernel in an E2E system,
    where we may have clock throttling, a warm cache, or other factors that could affect the runtime of the kernel.

    :param callable: The function to benchmark
    :type callable: Callable
    :param args: Arguments to pass to the callable function
    :param warmup_iterations: Number of warmup iterations, defaults to 10
    :type warmup_iterations: int, optional
    :param iterations: Number of benchmark iterations, defaults to 100
    :type iterations: int, optional
    :param use_cold_l2: Whether to clear L2 cache between runs, defaults to True
    :type use_cold_l2: bool, optional
    :param print_verbose: Whether to print verbose output, defaults to False
    :type print_verbose: bool, optional
    :param current_stream: Stream to benchmark in, defaults to CUDA stream default
    :type current_stream: CUstream, None
    :param kwargs: Additional keyword arguments to pass to the callable function

    :return: The benchmark time in microseconds
    :rtype: float
    """
    if current_stream is None:
        current_stream = cuda_driver.CUstream(
            cuda_driver.CUstream_flags.CU_STREAM_DEFAULT
        )

    if int(current_stream) != int(
        cuda_driver.CUstream(cuda_driver.CUstream_flags.CU_STREAM_DEFAULT)
    ) and not _does_kernel_use_stream(callable, current_stream, args, kwargs):
        raise ValueError(f"Incorrect stream passed to kernel: {current_stream}")

    if use_cold_l2:
        from cutlass.utils import HardwareInfo

        # use memset to clear L2 cache
        hardware_info = HardwareInfo()
        num_l2_cache_bytes = hardware_info.get_l2_cache_size_in_bytes()
        err, cache_ptr = cuda_driver.cuMemAlloc(int(num_l2_cache_bytes))
        _cuda_success(err, "Error on allocating memory")

    # Create CUDA events for timing
    err, start_event = cuda_driver.cuEventCreate(
        cuda_driver.CUevent_flags.CU_EVENT_DEFAULT
    )
    _cuda_success(err, "Error on creating event")
    err, end_event = cuda_driver.cuEventCreate(
        cuda_driver.CUevent_flags.CU_EVENT_DEFAULT
    )
    _cuda_success(err, "Error on creating event")
    try:
        # warmup
        for _ in range(warmup_iterations):
            callable(*args, **kwargs)

        _time = 0
        execution_time_ms = []
        for _ in range(iterations):
            if use_cold_l2:
                # clear L2 cache by memset to zero for every run
                err = cuda_driver.cuMemsetD32Async(
                    cache_ptr, 0, int(num_l2_cache_bytes // 4), current_stream
                )
                _cuda_success(err, "Error on memset")
            err = cuda_driver.cuEventRecord(start_event, current_stream)
            _cuda_success(err, "Error on recording event")
            callable(*args, **kwargs)
            err = cuda_driver.cuEventRecord(end_event, current_stream)
            _cuda_success(err, "Error on recording event")
            err = cuda_driver.cuEventSynchronize(end_event)
            _cuda_success(err, "Error on synchronizing event")
            err, elapsed_time = cuda_driver.cuEventElapsedTime(start_event, end_event)
            _cuda_success(err, "Error on querying event")
            execution_time_ms.append(elapsed_time)
        # unit: us
        time_us = sum(execution_time_ms) * 1e3 / len(execution_time_ms)
    except Exception as e:
        print(f"This config execution error: {e}")
        time_us = float("inf")
    if print_verbose:
        print(f"Execution time: {time_us:.4f} us")

    if use_cold_l2:
        err = cuda_driver.cuMemFree(cache_ptr)
        _cuda_success(err, "Error on freeing memory")
    err = cuda_driver.cuEventDestroy(start_event)
    _cuda_success(err, "Error on destroying event")
    err = cuda_driver.cuEventDestroy(end_event)
    _cuda_success(err, "Error on destroying event")
    return time_us


def tune(
    func: Callable[..., Callable[[], Any]],
    params_dict: Optional[Dict[str, List[Any]]] = None,
    kernel_arguments: "JitArguments" = JitArguments(),
    warmup_iterations: int = 10,
    iterations: int = 100,
    stream: Optional[cuda_driver.CUstream] = None,
) -> Dict[str, Any]:
    """Tuning tool to suport arbitrary functions. The user must provide a function that returns a callable, which
    takes no arguments to be tuned over.
    Best practice is to return a jit function that is compiled with cute.compile for optimal performance.
    For example:
    .. code-block:: python

        def user_function(param1=1, param2=2, param3=3) -> Callable[[], Any]:
            # contents of the function
            return lambda : compiled_func(param1, param2, param3)

        config = tune(user_function, params_dict={'param1': [1, 2, 3], 'param2': [4, 5, 6]}, update_on_change=['param3'])

    :param func: Function to be tuned, note that errors raised in the function will be ignored and the next configuration will be tried.
    :type func: Callable[[Any], Callable[[], Any]]
    :param params_dict: Dictionary containing parameter names and their possible values
    :type params_dict: Dict[str, List[Any]], optional
    :param kernel_arguments: Kernel arguments to launch callable with, defaults to JitArguments()
    :type kernel_arguments: JitArguments, optional
    :param warmup_iterations: Number of warmup iterations, defaults to 10
    :type warmup_iterations: int, optional
    :param iterations: Number of benchmark iterations, defaults to 100
    :type iterations: int, optional
    :param stream: Stream kernel is launched in, defaults to CUDA stream default
    :type stream: CUstream, None
    :return: Best configuration
    :rtype: Dict[str, Any]
    """
    logger = logging.getLogger(__name__ + "_Autotune")
    if not logger.handlers:
        handler = logging.StreamHandler()
        formatter = logging.Formatter(
            "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
        )
        handler.setFormatter(formatter)
        logger.addHandler(handler)
    if (
        os.environ.get("CUTE_DSL_LOG_AUTOTUNE") is not None
        and os.environ.get("CUTE_DSL_LOG_AUTOTUNE") != "0"
    ):
        logger.setLevel(logging.INFO)

    if stream is None:
        stream = cuda_driver.CUstream(cuda_driver.CUstream_flags.CU_STREAM_DEFAULT)

    # Get all parameter configurations
    if params_dict is None:
        raise ValueError("params_dict must be provided")
    keys = list(params_dict.keys())
    values = list(params_dict.values())

    min_time = float("inf")

    best_config = None
    # Record start time
    start = time()

    # Iterate through all possible configuration combinations
    for config_values in product(*values):
        # Build current configuration
        current_config = dict(zip(keys, config_values))
        logger.info(f"Tuning configuration: {current_config}")

        try:
            merged_kwargs = {**kernel_arguments.kwargs, **current_config}

            compiled_func = func(*kernel_arguments.args, **merged_kwargs)
            # Benchmark the compiled function
            cur_time = _benchmark_for_autotune(
                compiled_func,
                warmup_iterations=warmup_iterations,
                iterations=iterations,
                use_cold_l2=True,
                print_verbose=False,
                current_stream=stream,
            )

            logger.info(f"   Execution time: {cur_time} us")

            # Update best results
            if cur_time < min_time:
                min_time = cur_time
                best_config = current_config

        except NotImplementedError as e:
            logger.info(f"   Encountered unimplemented error, abort execution: {e}")
            raise e
        except (ValueError, TypeError, CantImplementError) as e:
            logger.info(f"   Configuration parameter skipping: {e}")
            continue
        except Exception as e:
            logger.info(f"   Execution error skipping: {e}")
            continue

    end = time()
    tuning_time = end - start

    if best_config is None:
        raise ValueError("No best kernel found")

    logger.info(f"Best configuration: {best_config}, execution time: {min_time} us")
    logger.info(f"Total tuning time: {tuning_time} s")
    return best_config


class CantImplementError(Exception):
    """Exception raised when a function is not implemented."""

    def __init__(self, message: Optional[str] = None) -> None:
        self.message = message or "The current config is invalid/unsupported"
        super().__init__(self.message)

    def __str__(self) -> str:
        return self.message

    def __repr__(self) -> str:
        return self.message


#########################################
# Tensor initialization configuration
#########################################


@dataclass(frozen=True)
class TensorInitConfig:
    """Configuration for tensor initialization policy.

    When init_normal=True, tensors are initialized from a normal distribution
    with the specified mean and std. Int8/Uint8 dtypes always use random
    integer initialization regardless of this flag.
    """

    init_normal: bool = False
    normal_mean: float = 0.0
    normal_std: float = 1.0


def add_tensor_init_args(
    parser: argparse.ArgumentParser,
    supports_int_dtypes: bool = True,
) -> None:
    """Add --init_normal, --normal_mean, --normal_std arguments to a parser.

    :param parser: ArgumentParser to add arguments to.
    :param supports_int_dtypes: If True, appends Int8/Uint8 caveat to --init_normal
        help text. Set to False for files whose ab_dtype choices do not include
        Int8/Uint8 (e.g. grouped_gemm, dense_blockscaled_gemm_persistent).
    """
    init_normal_help = (
        "Use normal distribution for tensor initialization instead of random integers."
    )
    if supports_int_dtypes:
        init_normal_help += (
            " Note: Int8/Uint8 dtypes always use random init regardless of this flag"
        )
    parser.add_argument(
        "--init_normal",
        action="store_true",
        help=init_normal_help,
    )
    parser.add_argument(
        "--normal_mean",
        type=float,
        default=0.0,
        help="Mean for normal distribution initialization",
    )
    parser.add_argument(
        "--normal_std",
        type=float,
        default=1.0,
        help="Standard deviation for normal distribution initialization (must be >= 0)",
    )


def validate_tensor_init_args(
    args: argparse.Namespace,
    parser: argparse.ArgumentParser,
) -> None:
    """Validate tensor init arguments after parse_args().

    :param args: Parsed arguments namespace.
    :param parser: Parser instance (used for error reporting).
    """
    if args.normal_std < 0:
        parser.error("--normal_std must be non-negative")


def tensor_init_config_from_args(args: argparse.Namespace) -> TensorInitConfig:
    """Extract a TensorInitConfig from parsed arguments."""
    return TensorInitConfig(
        init_normal=args.init_normal,
        normal_mean=args.normal_mean,
        normal_std=args.normal_std,
    )


def should_use_normal_init(
    config: TensorInitConfig,
    dtype: Type[Numeric],
) -> bool:
    """Determine whether normal initialization should be used for the given dtype.

    Returns False if config.init_normal is False or if dtype is Int8/Uint8
    (which do not support normal distribution initialization).
    """
    return config.init_normal and dtype not in (Int8, Uint8)
