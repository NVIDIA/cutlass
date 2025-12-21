# SPDX-FileCopyrightText: Copyright (c) 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: LicenseRef-NvidiaProprietary
#
# Use of this software is governed by the terms and conditions of the
# NVIDIA End User License Agreement (EULA), available at:
# https://docs.nvidia.com/cutlass/media/docs/pythonDSL/license.html
#
# Any use, reproduction, disclosure, or distribution of this software
# and related documentation outside the scope permitted by the EULA
# is strictly prohibited.

import functools
import inspect
import logging
import os
from itertools import product
from time import time
from typing import Type, Union, Callable, Optional, Dict, List, Any

import cuda.bindings.driver as cuda_driver
import cuda.bindings.runtime as cuda_runtime

import cutlass
import cutlass.base_dsl.jit_executor
from cutlass.cutlass_dsl import Constexpr, CuTeDSL, T, dsl_user_op

from .typing import Numeric, Int8, Boolean

import cutlass.cute as cute
from cutlass.cute import nvgpu

from cutlass._mlir.dialects import builtin, cf, nvvm, vector


@dsl_user_op
def assert_(cond, msg=None, *, loc=None, ip=None):
    cf.assert_(Boolean(cond).ir_value(), msg if msg else "", loc=loc, ip=ip)


def _maybe_recast_tensor_from_f4(src: cute.Tensor, tv_layout: cute.Layout):
    if src.element_type.width == 4:
        tv_layout = cute.recast_layout(8, 4, tv_layout)
        src = cute.recast_tensor(src, dtype=Int8)
    return src, tv_layout


def _maybe_recast_to_f4(input: cute.TensorSSA, dtype: Type[Numeric]):
    """Conditionally recasts the tensor to 4-bit type if the destination type is 4-bit.

    :param input: The input tensor to recast.
    :param dtype: The target numeric type to potentially recast to.
    :raises TypeError: If dtype is not a subclass of Numeric.
    :return: A new tensor recast to 4-bit if dtype is 4-bit, otherwise returns self unchanged.
    """
    if not inspect.isclass(dtype) or not issubclass(dtype, Numeric):
        raise TypeError(f"dst_ty must be a type of Numeric, but got {dtype}")

    if dtype.width == 4:
        recast_shape = cute.recast_layout(4, 8, cute.make_layout(input.shape)).shape
        i4_vec = vector.bitcast(
            T.vector(input.type.shape[0] * 2, T.i(4)), input.maybe_downcast()
        )
        res_vect = builtin.unrealized_conversion_cast(
            [T.vector(i4_vec.type.shape[0], dtype.mlir_type)], [i4_vec]
        )
        return cute.TensorSSA(res_vect, recast_shape, dtype)
    return input


def _maybe_recast_from_f4(input: cute.TensorSSA, src_dtype: Type[Numeric]):
    """Conditionally recasts the tensor from 4-bit type if the source type is 4-bit.

    :param input: The input tensor to recast.
    :param src_dtype: The source numeric type to potentially recast from.
    :raises TypeError: If src_dtype is not a subclass of Numeric.
    :return: A new tensor recast from 4-bit if src_dtype is 4-bit, otherwise returns self unchanged.
    """
    if not inspect.isclass(src_dtype) or not issubclass(src_dtype, Numeric):
        raise TypeError(f"src_ty must be a type of Numeric, but got {src_dtype}")

    if src_dtype.width == 4:
        recast_shape = cute.recast_layout(8, 4, cute.make_layout(input.shape)).shape
        i4_vec = builtin.unrealized_conversion_cast(
            [T.vector(input.type.shape[0], T.i(4))], [input.maybe_downcast()]
        )
        res_vect = vector.bitcast(T.vector(i4_vec.type.shape[0] // 2, T.i8()), i4_vec)
        return cute.TensorSSA(res_vect, recast_shape, Int8)
    return input


@CuTeDSL.kernel
def _convert_kernel(
    gSrc: cute.Tensor,
    gDst: cute.Tensor,
    cSrc: cute.Tensor,
    src_tv_layout: cute.Layout,
    dst_tv_layout: cute.Layout,
    src_shape: cute.Shape,
    src_ty,
    dst_ty,
):
    tidx = nvvm.read_ptx_sreg_tid_x(T.i32())
    bidx = nvvm.read_ptx_sreg_ctaid_x(T.i32())

    cta_coord = (None, bidx)
    # logical idx -> address
    ctaSrc = gSrc[cta_coord]  # (...,TileV,...)
    ctaDst = gDst[cta_coord]  # (...,TileV,...)
    ctaCSrc = cSrc[cta_coord]  # (...,TileV,...)
    # print(f"ctaSrc = {ctaSrc.type}")

    # compose with CTA TV layout
    # tid, vid -> address
    tidfrgSrc = cute.composition(ctaSrc, src_tv_layout)  # (T,V)
    tidfrgDst = cute.composition(ctaDst, dst_tv_layout)  # (T,V)
    tidfrgCSrc = cute.composition(ctaCSrc, src_tv_layout)  # (T,V)
    # print(f"tidfrgSrc = {tidfrgSrc.type}")

    # slice for threads
    thr_coord = (tidx, None)
    thrSrc = tidfrgSrc[thr_coord]  # (V)
    thrDst = tidfrgDst[thr_coord]  # (V)
    thrCSrc = tidfrgCSrc[thr_coord]  # (V)
    # print(f"thrSrc = {thrSrc.type}")

    # predicate
    if cute.elem_less(thrCSrc[0], src_shape):
        # allocate fragments for gmem->rmem
        frgSrc = cute.make_rmem_tensor(
            cute.get(src_tv_layout, mode=[1]), gSrc.element_type
        )  # (V)
        frgDst = cute.make_rmem_tensor(
            cute.get(dst_tv_layout, mode=[1]), gDst.element_type
        )  # (V)
        # print(f"frgSrc = {frgSrc.type}")

        # Move data to reg address space
        copy_atom_load = cute.make_copy_atom(nvgpu.CopyUniversalOp(), gSrc.element_type)
        cute.copy(copy_atom_load, thrSrc, frgSrc)

        vec_src = frgSrc.load()
        vec_src = _maybe_recast_to_f4(vec_src, src_ty)
        vec_dst = vec_src.to(dst_ty)
        vec_dst = _maybe_recast_from_f4(vec_dst, dst_ty)
        frgDst.store(vec_dst)

        # Copy the results back to c
        copy_atom_stg = cute.make_copy_atom(nvgpu.CopyUniversalOp(), gDst.element_type)
        cute.copy(copy_atom_stg, frgDst, thrDst)


@CuTeDSL.jit(preprocess=False)
def _convert(
    src: cute.Tensor,
    dst: cute.Tensor,
    leading_mode: Constexpr,
    elem_per_copy: Constexpr,
):
    # Step 1. figure proper tv_layout
    src_ty = src.element_type
    dst_ty = dst.element_type

    tv_layout = cute.make_layout((128, elem_per_copy), stride=(elem_per_copy, 1))

    # Step 2. maybe recast from f4 tensor
    src, src_tv_layout = _maybe_recast_tensor_from_f4(src, tv_layout)
    dst, dst_tv_layout = _maybe_recast_tensor_from_f4(dst, tv_layout)
    src_shape = src.shape
    # predicate tensor
    idA = cute.make_identity_tensor(src.shape)

    # Step 3. select a proper tiling pattern as (...,TileV, ...)
    src_cta_tiler = [
        1,
    ] * cute.rank(src.layout)
    src_cta_tiler[leading_mode] = cute.size(src_tv_layout)  # (...,TileV,...)
    dst_cta_tiler = [
        1,
    ] * cute.rank(dst.layout)
    dst_cta_tiler[leading_mode] = cute.size(dst_tv_layout)  # (...,TileV,...)

    # Step 4. partition input and output tensor by cta tiler.
    gS = cute.zipped_divide(
        src, tuple(src_cta_tiler)
    )  # ((...,TileV,...),(...,RestV,...))
    cS = cute.zipped_divide(
        idA, tuple(src_cta_tiler)
    )  # ((...,TileV,...),(...,RestV,...))
    gD = cute.zipped_divide(
        dst, tuple(dst_cta_tiler)
    )  # ((...,TileV,...),(...,RestV,...))
    # print(f"{gS.type=}")

    _convert_kernel(
        gS,
        gD,
        cS,
        src_tv_layout,
        dst_tv_layout,
        src_shape,
        src_ty,
        dst_ty,
    ).launch(
        grid=[cute.size(gS, mode=[1]), 1, 1],
        block=[cute.size(src_tv_layout, mode=[0]), 1, 1],
    )


# Converts from src tensor to dst tensor, their logical shape are required to be the same.
# And when src or dst dtype is narrow precision(Float4E2M1FN/Float8E8M0FNU/Float8E4M3FN), the shape of
# their leading dimension should be 4(fp8)/8(fp4) element align. (nvgpu.cvt_fptrunc/cvt_fpext
# needs 32-bits aligned input/output)
def convert(src: cute.Tensor, dst: cute.Tensor):
    assert len(src.shape) == len(dst.shape), (
        "Shape of src and dst tensors should be the same rank."
    )
    # find leading mode
    leading_mode = [
        idx
        for idx, (shape, stride) in enumerate(zip(src.shape, src.stride))
        if shape > 1 and stride == 1
    ]
    if len(leading_mode) != 1:
        raise ValueError(f"Leading mode should be unique, but got {leading_mode}")
    leading_mode = leading_mode[0]

    elem_per_copy = 2

    if src.element_type.width == 4 or dst.element_type.width == 4:
        elem_per_copy = 8
    elif src.element_type.width == 8 or dst.element_type.width == 8:
        elem_per_copy = 4
    assert (
        src.shape[leading_mode] % elem_per_copy == 0
        and dst.shape[leading_mode] % elem_per_copy == 0
    )

    _convert(src, dst, leading_mode, elem_per_copy)


#########################################
# Testing utilities
#########################################


def sample_pytest(rand_cfg=None):
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

    seed, sample_ratio = rand_cfg
    random.seed(seed)

    def decorator(func):
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
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

    def __init__(self, *args, **kwargs):
        self.args = args
        self.kwargs = kwargs


def _cuda_success(
    err: Union[tuple, cuda_runtime.cudaError_t, cuda_driver.CUresult], message: str
):
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
    kernel: Callable, stream: cuda_driver.CUstream, *args, **kwargs
):
    """
    This function checks if the kernel uses the provided non-default stream.
    It does this by capturing the stream and then checking if any kernels were launched.
    :param kernel: The kernel to check
    :type kernel: Callable
    :param stream: The stream to check
    :type stream: cuda_driver.CUstream
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

    kernel(*args, **kwargs)

    err, graph = cuda_runtime.cudaStreamEndCapture(stream)
    _cuda_success(err, "Error on stream capture")

    # Get number of nodes in warmup graph to check it matches what is expected
    err, _, num_nodes = cuda_runtime.cudaGraphGetNodes(graph)
    _cuda_success(err, "Error on querying graph")
    return num_nodes > 0


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
) -> float:
    """Benchmarks a callable function with the specified parameters.

    For example,
    .. code-block:: python

        from cutlass.cute.testing import benchmark

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

        from cutlass.cute.testing import benchmark

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

    if stream is None:
        stream = cuda_driver.CUstream(cuda_driver.CUstream_flags.CU_STREAM_DEFAULT)

    if workspace_count < 1:
        raise ValueError("workspace_count must be at least 1")

    time_us = float("nan")
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
        if type(workspace) != JitArguments:
            raise TypeError(
                "workspace_generator and/or kernel_arguments should use JitArguments type"
            )

    def _loop_and_call_kernel(iterations: int, workspace_index: int = 0):
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

    if use_cuda_graphs:
        # Check if the stream is a non-default stream
        if int(stream) == int(cuda_driver.CUstream_flags.CU_STREAM_DEFAULT):
            raise ValueError(
                "Measuring with CUDA Graphs requires executing in a non-default stream"
            )

        workspace_index = 0

        # Capture warmup graph
        err = cuda_runtime.cudaStreamBeginCapture(
            stream, cuda_runtime.cudaStreamCaptureMode.cudaStreamCaptureModeThreadLocal
        )
        _cuda_success(err, "Error on stream capture")

        workspace_index = _loop_and_call_kernel(warmup_iterations)
        err, gwarm = cuda_runtime.cudaStreamEndCapture(stream)
        _cuda_success(err, "Error on stream capture")

        # Get number of nodes in warmup graph to check it matches what is expected
        err, _, num_nodes = cuda_runtime.cudaGraphGetNodes(gwarm)
        _cuda_success(err, "Error on querying graph")
        # Assertion is >= since we may launch multiple kernels in one host function
        if num_nodes < warmup_iterations:
            raise ValueError(
                "CUDA stream passed to benchmark does not match the stream the kernel was launched in"
            )

        # Capture profiling graph
        err = cuda_runtime.cudaStreamBeginCapture(
            stream, cuda_runtime.cudaStreamCaptureMode.cudaStreamCaptureModeThreadLocal
        )
        _cuda_success(err, "Error on stream capture")
        _loop_and_call_kernel(iterations, workspace_index)
        err, gprofile = cuda_runtime.cudaStreamEndCapture(stream)
        _cuda_success(err, "Error on stream capture")

        # Instantiate graphs
        err, gwarm = cuda_runtime.cudaGraphInstantiate(gwarm, 0)
        _cuda_success(err, "Error on graph instantiation")
        err, gprofile = cuda_runtime.cudaGraphInstantiate(gprofile, 0)
        _cuda_success(err, "Error on graph instantiation")

        # Launch warmup graph
        err = cuda_runtime.cudaGraphLaunch(gwarm, stream)
        _cuda_success(err, "Error on graph launch")

        # Record start time
        err = cuda_driver.cuEventRecord(start_event, stream)
        _cuda_success(err, "Error on recording event")

        # Launch profiling graph
        err = cuda_runtime.cudaGraphLaunch(gprofile, stream)
        _cuda_success(err, "Error on graph launch")

        # Record end time
        err = cuda_driver.cuEventRecord(end_event, stream)
        _cuda_success(err, "Error on recording event")
        err = cuda_driver.cuEventSynchronize(end_event)
        _cuda_success(err, "Error on synchronizing event")

        # Get elapsed time
        err, elapsed_time = cuda_driver.cuEventElapsedTime(start_event, end_event)
        _cuda_success(err, "Error on querying event")

        # Destroy graphs
        err = cuda_runtime.cudaGraphExecDestroy(gwarm)
        _cuda_success(err, "Error on destroying graph")
        err = cuda_runtime.cudaGraphExecDestroy(gprofile)
        _cuda_success(err, "Error on destroying graph")

    else:
        if int(stream) != int(
            cuda_driver.CUstream_flags.CU_STREAM_DEFAULT
        ) and not _does_kernel_use_stream(
            callable, stream, *workspaces[0].args, **workspaces[0].kwargs
        ):
            raise ValueError(
                "CUDA stream passed to benchmark does not match the stream the kernel was launched in"
            )

        # Not using graphs
        # Warmup
        workspace_index = _loop_and_call_kernel(warmup_iterations)
        # Record start event
        err = cuda_driver.cuEventRecord(start_event, stream)
        _cuda_success(err, "Error on recording event")
        _loop_and_call_kernel(iterations, workspace_index)
        # Record end event
        err = cuda_driver.cuEventRecord(end_event, stream)
        _cuda_success(err, "Error on recording event")
        # Synchronize end event
        err = cuda_driver.cuEventSynchronize(end_event)
        _cuda_success(err, "Error on synchronizing event")
        err, elapsed_time = cuda_driver.cuEventElapsedTime(start_event, end_event)
        _cuda_success(err, "Error on querying event")

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
    num_l2_cache_bytes = cutlass.utils.HardwareInfo().get_l2_cache_size_in_bytes()
    num_workspaces = (num_l2_cache_bytes * 3) // one_workspace_bytes + 1
    num_iters = warmup_iterations + iterations
    return num_iters if num_iters < num_workspaces else num_workspaces


#########################################
# Autotuning/Tuning utilities
#########################################


def _benchmark_for_autotune(
    callable: Callable,
    *args,
    warmup_iterations: int,
    iterations: int,
    use_cold_l2: bool,
    print_verbose: bool,
    current_stream: Optional[cuda_driver.CUstream] = None,
    **kwargs,
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
    ) and not _does_kernel_use_stream(callable, current_stream, *args, **kwargs):
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

        time = 0
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
        time_us = sum(execution_time_ms) / len(execution_time_ms)
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


class autotune_jit:
    """Auto-tuning tool supporting both dictionary and parameterized decorator styles.
    The autotune_jit class can be used as a decorator or a function.
    When used as a decorator, it will automatically tune the function based on the parameters.
    When used as a function, it will return a decorator that can be used to decorate a function.
    For example:
    .. code-block:: python

        @autotune_jit(params_dict={'param1': [1, 2, 3], 'param2': [4, 5, 6]}, update_on_change=['param3'])
        @cute.jit
        def user_function(param1=1, param2=2, param3=3):
            # contents of the function
            pass

    The function will be automatically tuned over all combinations of param1 and param2 whenever param3 changes .
    For non-specified parameters, the default value in user_function will be used (e.g., `param3` in `user_function`).
    .. code-block:: python
        user_function(a, b, c) # Autotunes code
        user_function(a, b, c) # This call pulls the best kernel from cache

    Known Limitations:
    - Only supports functions that are decorated with cute.jit
    - If the function which is decorated with cute.jit is call method of a class, and the class has internal state that
      is used as constexpr arguments in the function, the autotuner will not be able to find the best configuration.

    Note: The autotuner has the same semantics as cute.compile. If the function is compiled, but global variables are changed,
    the autotuner will not recompile the kernel.
    """

    logger = None

    @classmethod
    def _initialize_logger(cls):
        """Ensure the logger is initialized"""
        if cls.logger is None:
            cls.logger = logging.getLogger(__name__ + "_Autotune")
            if not cls.logger.handlers:
                handler = logging.StreamHandler()
                formatter = logging.Formatter(
                    "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
                )
                handler.setFormatter(formatter)
                cls.logger.addHandler(handler)
            if (
                os.environ.get("CUTE_DSL_LOG_AUTOTUNE") is not None
                and os.environ.get("CUTE_DSL_LOG_AUTOTUNE") != "0"
            ):
                cls.logger.setLevel(logging.INFO)

    @classmethod
    def _create_tuning_wrapper(
        cls, func, warmup_iterations, iterations, autotune_update_params
    ):
        """Create a wrapper function that performs auto-tuning

        Args:
            func: Original function

        Returns:
            Decorated wrapper function
        """

        # Initialize autotune parameters
        if not hasattr(func, "_autotune_params"):
            func._original_func = func
            func._autotune_params = {}
            func._autotune_update_params = autotune_update_params
            func._best_kernel = dict()
            func._best_config = dict()

            # Create wrapper function for auto-tuning
            @functools.wraps(func)
            def tuning_wrapper(*args, **kwargs):
                parameters = inspect.signature(func._original_func).parameters.keys()
                tuning_key = list()
                for param_name in func._autotune_update_params:
                    if param_name in kwargs.keys():
                        tuning_key.append(kwargs[param_name])
                    else:
                        index = list(parameters).index(param_name)
                        if index < len(args):
                            tuning_key.append(args[index])
                tuning_key = tuple(tuning_key)
                if tuning_key in func._best_kernel.keys():
                    cls.logger.info(
                        f"Using cached best configuration: {func._best_config[tuning_key]}"
                    )
                    return func._best_kernel[tuning_key](*args, **kwargs)

                # Get all parameter configurations
                params_dict = func._autotune_params
                keys = list(params_dict.keys())
                values = list(params_dict.values())

                min_time = float("inf")

                best_kernel = None
                # Record start time
                start = time()

                # Iterate through all possible configuration combinations
                for config_values in product(*values):
                    # Build current configuration
                    current_config = dict(zip(keys, config_values))
                    cls.logger.info(f"Tuning configuration: {current_config}")

                    try:
                        # Call the original function, using current configuration to replace default parameters
                        # For example, if current_config contains "cluster_shape_mn": (2, 1)
                        # It will override func's default parameter value
                        merged_kwargs = {**kwargs, **current_config}
                        compiled_func = cute.compile(
                            func._original_func, *args, **merged_kwargs
                        )

                        # Detect which constexpr arguments we need to remove from args and merged_kwargs
                        # This is done because after compiling our function signature will change, removing all constexpr arguments.
                        indexes_to_remove = list()
                        for arg in compiled_func.args_spec.get_constexpr_args():
                            if arg["argument_name"] in merged_kwargs:
                                del merged_kwargs[arg["argument_name"]]
                            elif arg["argument_index"] is not None:
                                indexes_to_remove.append(arg["argument_index"])
                            if arg["argument_name"] not in func._autotune_update_params:
                                # Handle the case where the programmer avoided autotuning over constexpr values, and
                                # recompile in that case
                                func._autotune_update_params.append(
                                    arg["argument_name"]
                                )

                        # Remove constexpr arguments from args
                        args_no_constexpr = list(args)
                        for index in sorted(indexes_to_remove, reverse=True):
                            del args_no_constexpr[index]

                        # Benchmark the compiled function
                        cur_time = _benchmark_for_autotune(
                            compiled_func,
                            *args_no_constexpr,
                            warmup_iterations=warmup_iterations,
                            iterations=iterations,
                            use_cold_l2=True,
                            print_verbose=False,
                            **merged_kwargs,
                        )

                        cls.logger.info(f"   Execution time: {cur_time} us")

                        # Update best results
                        if cur_time < min_time:
                            min_time = cur_time
                            best_kernel = compiled_func
                            best_config = current_config

                    except NotImplementedError as e:
                        cls.logger.info(
                            f"   Encountered unimplemented error, abort execution: {e}"
                        )
                        raise e
                    except (ValueError, TypeError) as e:
                        cls.logger.info(f"   Configuration parameter skipping: {e}")
                        raise e
                        continue
                    except Exception as e:
                        cls.logger.info(f"   Execution error skipping: {e}")
                        raise e
                        continue

                end = time()
                tuning_time = end - start

                if best_kernel is None:
                    raise ValueError("No best kernel found")

                cls.logger.info(
                    f"Best configuration: {best_config}, execution time: {min_time} us"
                )
                cls.logger.info(f"Total tuning time: {tuning_time} s")
                func._best_kernel[tuning_key] = best_kernel
                func._best_config[tuning_key] = best_config
                return best_kernel(*args, **kwargs)

            # Append autotune wrapper to not conflict with the jit kernel names
            tuning_wrapper.__name__ = func.__name__ + "_autotune_wrapper"
            tuning_wrapper.__qualname__ = func.__qualname__ + "_autotune_wrapper"

            return tuning_wrapper

        return func  # If already has a wrapper, return the original function

    def __init__(
        self,
        params_dict: Dict[str, List[Any]] = None,
        update_on_change: List[str] = None,
        warmup_iterations=10,
        iterations=100,
    ):
        """Initialize the autotune_jit decorator.

        :param params_dict: Dictionary containing parameter names and their possible values
        :type params_dict: Dict[str, List[Any]], optional
        :param update_on_change: Whether to retune when the parameters changes, defaults to None
        :type update_on_change: bool, optional
        :param warmup_iterations: Number of warmup iterations, defaults to 100
        :type warmup_iterations: int, optional
        :param iterations: Number of benchmark iterations, defaults to 100
        :type iterations: int, optional
        """
        # Initialize logger
        self._initialize_logger()

        # Save parameter dictionary
        self.params_dict = params_dict or {}
        self.update_on_change = update_on_change or list()

        # Save iterations
        self.warmup_iterations = warmup_iterations
        self.iterations = iterations

    def __call__(self, func):
        """Called when class instance is used as a decorator.

        :param func: Function to be decorated
        :type func: Callable
        :return: Decorated function
        :rtype: Callable
        """
        # Create wrapper function
        decorated_func = self._create_tuning_wrapper(
            func, self.warmup_iterations, self.iterations, self.update_on_change
        )

        # Use the wrapper if it exists, otherwise use the original function
        result_func = (
            decorated_func if hasattr(decorated_func, "_autotune_params") else func
        )

        # Add parameters from the dictionary to the function's autotune parameters
        for param_name, param_values in self.params_dict.items():
            result_func._autotune_params[param_name] = param_values

        return result_func


def tune(
    func: Callable[[Any], Callable[[], Any]],
    params_dict: Dict[str, List[Any]] = None,
    kernel_arguments: JitArguments = JitArguments(),
    warmup_iterations=10,
    iterations=100,
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

    def __init__(self, message=None):
        self.message = message or "The current config is invalid/unsupported"
        super().__init__(self.message)

    def __str__(self):
        return self.message

    def __repr__(self):
        return self.message
