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
import functools
import inspect
import logging
import os
from dataclasses import dataclass
from itertools import product
from time import time
from typing import Type, Union, Callable, Optional, Dict, List, Any

import cuda.bindings.driver as cuda_driver
import cuda.bindings.runtime as cuda_runtime

from cutlass.cutlass_dsl import Constexpr, CuTeDSL, T, dsl_user_op, const_expr

from .typing import Numeric, Int8, Uint8, Boolean, Tensor, Layout, Shape

from . import nvgpu
from .core import recast_layout, make_layout, composition, get, rank, size
from .tuple import elem_less
from .tensor import (
    make_rmem_tensor,
    recast_tensor,
    make_identity_tensor,
    TensorSSA,
    _Tensor,
)
from .atom import make_copy_atom
from .algorithm import copy
from .core import zipped_divide
from .runtime import from_dlpack

from cutlass._mlir.dialects import builtin, cf, nvvm, vector

from functools import partial
from cutlass._mlir import ir


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
            start = activity.start if hasattr(activity, "start") else "nil"
            end = activity.end if hasattr(activity, "end") else "nil"
            duration = end - start if start != "nil" and end != "nil" else "nil"  # type: ignore[operator]
            name = activity.name[:100] if hasattr(activity, "name") else "unknown"
            # Convert to milliseconds
            if duration != "nil":
                self.timings.append((name, duration / 1e6))  # type: ignore[operator]

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


@dsl_user_op
def assert_(
    cond: object,
    msg: Optional[str] = None,
    *,
    loc: Optional[ir.Location] = None,
    ip: Optional[ir.InsertionPoint] = None,
) -> None:
    cf.assert_(Boolean(cond).ir_value(), msg if msg else "", loc=loc, ip=ip)


################################################
# Runtime Assertion Helper Utilities For Testing
################################################


class AssertionError(RuntimeError):
    """Custom assertion error for runtime assertions."""

    pass


class Assertion:
    """Base class for runtime assertion."""

    pass


class _CompileTimeAssertion(Assertion):
    """Compile-time assertion helper that tracks assertion results during execution.

    This assertion is used internally when RuntimeAssertion is passed through
    JIT compilation. It stores assertion results in a tensor and provides compile-time
    tracking of assertion results.
    """

    def __init__(
        self,
        tensor: Optional[Tensor],
        num_assertions: int = 1,
        msgs: Optional[list[str]] = None,
        device: Optional[str] = None,
        disable: bool = False,
        init_value: bool = False,
        used_indices: Optional[set[int]] = None,
    ) -> None:
        """Initialize _CompileTimeAssertion.

        :param tensor: Tensor to store assertion results
        :param num_assertions: Number of assertions to support
        :param msgs: List of assertion messages
        :param device: Device to run assertions on
        :param disable: If True, assertions are disabled
        :param init_value: Initial value for assertion tensor
        :param used_indices: Set of used assertion indices
        """
        if msgs is None:
            msgs = []
        self._tensor = tensor
        self._num_assertions = num_assertions
        self._device = device
        self._disable = disable
        self._msgs = msgs
        self._init_value = init_value
        self._used_indices = used_indices

    def __new_from_mlir_values__(
        self, values: list[ir.Value]
    ) -> "_CompileTimeAssertion":
        if self._disable:
            return _CompileTimeAssertion(
                None,
                self._num_assertions,
                self._msgs,
                self._device,
                self._disable,
                self._init_value,
                self._used_indices,
            )
        return _CompileTimeAssertion(
            _Tensor(values[0], dtype=Boolean),
            self._num_assertions,
            self._msgs,
            self._device,
            self._disable,
            self._init_value,
            self._used_indices,
        )

    def __extract_mlir_values__(self) -> list[ir.Value]:
        if self._disable:
            return []
        return self._tensor.__extract_mlir_values__()  # type: ignore[union-attr]

    @dsl_user_op
    @CuTeDSL.jit
    def store(
        self,
        idx: Constexpr,
        pred: Boolean,
        msg: str = "",
        *,
        loc: Optional[ir.Location] = None,
        ip: Optional[ir.InsertionPoint] = None,
    ) -> None:
        """Assert a predicate condition.

        :param idx: Assertion index
        :type idx: int
        :param pred: Predicate condition to assert
        :type pred: Boolean
        :param msg: Assertion message
        :type msg: str, optional
        :param loc: MLIR location information for debugging, defaults to None
        :type loc: optional
        :param ip: MLIR insertion point for code generation, defaults to None
        :type ip: optional
        """
        if const_expr(self._disable):
            return
        if const_expr(not isinstance(idx, int)):
            raise ValueError(f"expects idx to be 'int', but got {type(idx)}")
        if const_expr(idx >= self._num_assertions):  # type: ignore[operator]
            raise ValueError("please increase the number of assertions!!!")
        if const_expr(self._init_value is True):
            self._tensor[idx] = pred and self._tensor[idx]  # type: ignore[index]
        else:
            self._tensor[idx] = pred  # type: ignore[index]
        self._msgs[idx] = f"{msg}\nAt {loc}"  # type: ignore[call-overload]
        self._used_indices.add(idx)  # type: ignore[union-attr, arg-type]

    def __enter__(self) -> "_CompileTimeAssertion":
        """Enter context manager."""
        return self

    def __exit__(
        self,
        exc_type: Optional[type[BaseException]],
        exc_val: Optional[BaseException],
        exc_tb: Optional[object],
    ) -> None:
        """Exit context manager and verify assertions if no exception occurred."""
        # Only verify if there was no exception in the with block
        if exc_type is None and not self._disable:
            # _CompileTimeAssertion doesn't have verify method as it's checked at compile time
            pass


class RuntimeAssertion(Assertion):
    """Runtime assertion helper that verifies conditions at runtime.
    ```python
    There are two modes to use RuntimeAssertion:
    1. Manual mode - explicitly call verify():
    ```python
        @cute.jit
        def jit_func(assertions: Assertion):
            assertions.store(0, pred, "assertion failed")
        assertions = cute.testing.RuntimeAssertion(num_assertions=1)
        jit_func(assertions)
        assertions.verify()
    ```

    2. Context manager mode - automatically verifies on exit:
    ```python
        with cute.testing.RuntimeAssertion(num_assertions=1) as assertions:
            jit_func(assertions)
        # verify() is called automatically after the with block
    ```
    """

    def __init__(
        self,
        num_assertions: int = 1,
        device: Optional[str] = None,
        disable: bool = False,
        init_value: bool = False,
    ) -> None:
        """Initialize _RuntimeAssertion.

        :param num_assertions: Number of assertions to support
        :param device: Device to run assertions on (None for CPU, "cuda" for GPU)
        :param disable: If True, assertions are disabled
        :param init_value: Initial value for assertion tensor
        """
        self._num_assertions = num_assertions
        self._device = device
        self._disable = disable
        self._msgs = [""] * num_assertions
        self._init_value = init_value
        self._used_indices: set[int] = set()
        if self._disable:
            return
        import torch

        self._torch_tensor = torch.full(
            (self._num_assertions,),
            device=self._device,
            dtype=torch.bool,
            fill_value=init_value,
        )
        self._tensor = from_dlpack(self._torch_tensor)

    def __c_pointers__(self) -> list[Any]:
        """Get C pointers for passing to JIT functions."""
        if self._disable:
            return []
        return self._tensor.__c_pointers__()  # type: ignore[attr-defined]

    def __get_mlir_types__(self) -> list[Any]:
        """Get MLIR types for code generation."""
        if self._disable:
            return []
        return self._tensor.__get_mlir_types__()  # type: ignore[attr-defined]

    def __new_from_mlir_values__(self, values: list[ir.Value]) -> _CompileTimeAssertion:
        """Create new instance from MLIR values (for JIT compilation)."""
        if self._disable:
            return _CompileTimeAssertion(
                None,
                self._num_assertions,
                self._msgs,
                self._device,
                self._disable,
                self._init_value,
                self._used_indices,
            )
        return _CompileTimeAssertion(
            _Tensor(values[0], dtype=Boolean),
            self._num_assertions,
            self._msgs,
            self._device,
            self._disable,
            self._init_value,
            self._used_indices,
        )

    def verify(self) -> None:
        """Verify all assertions have passed."""
        if self._disable:
            return
        import torch

        if self._device is not None:
            torch.cuda.synchronize()
        false_indices = torch.where(self._torch_tensor == False)[0].tolist()
        valid_indices = [idx for idx in false_indices if idx in self._used_indices]
        if len(valid_indices) > 0:
            # emit the first assertion error.
            raise AssertionError(self._msgs[valid_indices[0]])

    def __enter__(self) -> "RuntimeAssertion":
        """Enter the context manager, returns self for use in 'with' statement."""
        return self

    def __exit__(
        self,
        exc_type: Optional[type[BaseException]],
        exc_val: Optional[BaseException],
        exc_tb: Optional[object],
    ) -> None:
        """Exit the context manager, automatically calls verify()."""
        if exc_type is None:
            # Only verify if no exception occurred in the with block
            self.verify()


def _maybe_recast_tensor_from_f4_f6(
    src: Tensor, tv_layout: Layout
) -> tuple[Tensor, Layout]:
    if src.element_type.width == 4:  # type: ignore[union-attr]
        tv_layout = recast_layout(8, 4, tv_layout)
        src = recast_tensor(src, dtype=Int8)
    elif src.element_type.width == 6:  # type: ignore[union-attr]
        tv_layout = recast_layout(8, 6, tv_layout)
        src = recast_tensor(src, dtype=Int8)
    return src, tv_layout


def _maybe_recast_to_f4_f6(input: TensorSSA, dtype: Type[Numeric]) -> TensorSSA:
    """Conditionally recasts the tensor to 4-bit or 6-bit type if the destination type is 4-bit or 6-bit.

    :param input: The input tensor to recast.
    :param dtype: The target numeric type to potentially recast to.
    :raises TypeError: If dtype is not a subclass of Numeric.
    :return: A new tensor recast to 4-bit or 6-bit if dtype is 4-bit or 6-bit, otherwise returns self unchanged.
    """
    if not inspect.isclass(dtype) or not issubclass(dtype, Numeric):
        raise TypeError(f"dst_ty must be a type of Numeric, but got {dtype}")

    if dtype.width == 4:
        recast_shape = recast_layout(4, 8, make_layout(input.shape)).shape
        i4_vec = vector.bitcast(
            T.vector(input.type.shape[0] * 2, T.i(4)), input.maybe_downcast()
        )
        res_vect = builtin.unrealized_conversion_cast(
            [T.vector(i4_vec.type.shape[0], dtype.mlir_type)], [i4_vec]
        )
        return TensorSSA(res_vect, recast_shape, dtype)
    elif dtype.width == 6:
        recast_shape = recast_layout(6, 8, make_layout(input.shape)).shape
        n = input.type.shape[0]
        assert (n * 8) % 6 == 0, (
            f"N * 8 must be divisible by 6 for fp6 unpacking, got N={n}"
        )
        res_vect = vector.bitcast(
            T.vector(n * 8 // 6, dtype.mlir_type), input.maybe_downcast()
        )
        return TensorSSA(res_vect, recast_shape, dtype)
    return input


def _maybe_recast_from_f4_f6(input: TensorSSA, src_dtype: Type[Numeric]) -> TensorSSA:
    """Conditionally recasts the tensor from 4-bit or 6-bit type if the source type is 4-bit or 6-bit.

    :param input: The input tensor to recast.
    :param src_dtype: The source numeric type to potentially recast from.
    :raises TypeError: If src_dtype is not a subclass of Numeric.
    :return: A new tensor recast from 4-bit or 6-bit if src_dtype is 4-bit or 6-bit, otherwise returns self unchanged.
    """
    if not inspect.isclass(src_dtype) or not issubclass(src_dtype, Numeric):
        raise TypeError(f"src_ty must be a type of Numeric, but got {src_dtype}")

    if src_dtype.width == 4:
        recast_shape = recast_layout(8, 4, make_layout(input.shape)).shape
        i4_vec = builtin.unrealized_conversion_cast(
            [T.vector(input.type.shape[0], T.i(4))], [input.maybe_downcast()]
        )
        res_vect = vector.bitcast(T.vector(i4_vec.type.shape[0] // 2, T.i8()), i4_vec)
        return TensorSSA(res_vect, recast_shape, Int8)
    elif src_dtype.width == 6:
        recast_shape = recast_layout(8, 6, make_layout(input.shape)).shape
        n = input.type.shape[0]
        assert (n * 6) % 8 == 0, (
            f"N * 6 must be divisible by 8 for i8 packing, got N={n}"
        )
        res_vect = vector.bitcast(T.vector(n * 6 // 8, T.i8()), input.maybe_downcast())
        return TensorSSA(res_vect, recast_shape, Int8)
    return input


@CuTeDSL.kernel
def _convert_kernel(
    gSrc: Tensor,
    gDst: Tensor,
    cSrc: Tensor,
    src_tv_layout: Layout,
    dst_tv_layout: Layout,
    src_shape: Shape,
    src_ty: Type[Numeric],
    dst_ty: Type[Numeric],
) -> None:
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
    tidfrgSrc = composition(ctaSrc, src_tv_layout)  # type: ignore[arg-type]  # (T,V)
    tidfrgDst = composition(ctaDst, dst_tv_layout)  # type: ignore[arg-type]  # (T,V)
    tidfrgCSrc = composition(ctaCSrc, src_tv_layout)  # type: ignore[arg-type]  # (T,V)
    # print(f"tidfrgSrc = {tidfrgSrc.type}")

    # slice for threads
    thr_coord = (tidx, None)
    thrSrc = tidfrgSrc[thr_coord]  # (V)
    thrDst = tidfrgDst[thr_coord]  # (V)
    thrCSrc = tidfrgCSrc[thr_coord]  # (V)
    # print(f"thrSrc = {thrSrc.type}")

    # predicate
    if elem_less(thrCSrc[0], src_shape):
        # allocate fragments for gmem->rmem
        frgSrc = make_rmem_tensor(
            get(src_tv_layout, mode=[1]), gSrc.element_type
        )  # (V)
        frgDst = make_rmem_tensor(
            get(dst_tv_layout, mode=[1]), gDst.element_type
        )  # (V)
        # print(f"frgSrc = {frgSrc.type}")

        # Move data to reg address space
        copy_atom_load = make_copy_atom(nvgpu.CopyUniversalOp(), gSrc.element_type)
        copy(copy_atom_load, thrSrc, frgSrc)

        vec_src = frgSrc.load()
        vec_src = _maybe_recast_to_f4_f6(vec_src, src_ty)
        vec_dst = vec_src.to(dst_ty)
        vec_dst = _maybe_recast_from_f4_f6(vec_dst, dst_ty)
        frgDst.store(vec_dst)

        # Copy the results back to c
        copy_atom_stg = make_copy_atom(nvgpu.CopyUniversalOp(), gDst.element_type)
        copy(copy_atom_stg, frgDst, thrDst)


@CuTeDSL.jit(preprocess=False)
def _convert(
    src: Tensor,
    dst: Tensor,
    leading_mode: Constexpr,
    elem_per_copy: Constexpr,
) -> None:
    # Step 1. figure proper tv_layout
    src_ty = src.element_type
    dst_ty = dst.element_type

    tv_layout = make_layout((128, elem_per_copy), stride=(elem_per_copy, 1))

    # Step 2. maybe recast from f4 tensor
    src, src_tv_layout = _maybe_recast_tensor_from_f4_f6(src, tv_layout)
    dst, dst_tv_layout = _maybe_recast_tensor_from_f4_f6(dst, tv_layout)
    src_shape = src.shape
    # predicate tensor
    idA = make_identity_tensor(src.shape)

    # Step 3. select a proper tiling pattern as (...,TileV, ...)
    src_cta_tiler = [
        1,
    ] * rank(src.layout)
    src_cta_tiler[leading_mode] = size(src_tv_layout)  # type: ignore[call-overload]  # (...,TileV,...)
    dst_cta_tiler = [
        1,
    ] * rank(dst.layout)
    dst_cta_tiler[leading_mode] = size(dst_tv_layout)  # type: ignore[call-overload]  # (...,TileV,...)

    # Step 4. partition input and output tensor by cta tiler.
    gS = zipped_divide(src, tuple(src_cta_tiler))  # ((...,TileV,...),(...,RestV,...))
    cS = zipped_divide(idA, tuple(src_cta_tiler))  # ((...,TileV,...),(...,RestV,...))
    gD = zipped_divide(dst, tuple(dst_cta_tiler))  # ((...,TileV,...),(...,RestV,...))
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
        grid=[size(gS, mode=[1]), 1, 1],
        block=[size(src_tv_layout, mode=[0]), 1, 1],
    )


# Converts from src tensor to dst tensor, their logical shape are required to be the same.
# And when src or dst dtype is narrow precision(Float4E2M1FN/Float8E8M0FNU/Float8E4M3FN), the shape of
# their leading dimension should be 4(fp8)/8(fp4) element align. (nvgpu.cvt_fptrunc/cvt_fpext
# needs 32-bits aligned input/output)
def convert(src: Tensor, dst: Tensor) -> None:
    assert len(src.shape) == len(dst.shape), (  # type: ignore[arg-type]
        "Shape of src and dst tensors should be the same rank."
    )
    # find leading mode
    leading_mode = [
        idx
        for idx, (shape, stride) in enumerate(zip(src.shape, src.stride))  # type: ignore[arg-type]
        if shape > 1 and stride == 1  # type: ignore[operator]
    ]
    if len(leading_mode) != 1:
        raise ValueError(f"Leading mode should be unique, but got {leading_mode}")
    leading_mode = leading_mode[0]  # type: ignore[assignment]

    elem_per_copy = 2

    if src.element_type.width == 4 or dst.element_type.width == 4:  # type: ignore[union-attr]
        elem_per_copy = 8
    elif src.element_type.width == 8 or dst.element_type.width == 8:  # type: ignore[union-attr]
        elem_per_copy = 4
    elif src.element_type.width == 6 or dst.element_type.width == 6:  # type: ignore[union-attr]
        elem_per_copy = 16  # 16*f6 elements per 96 bits(12 bytes)
    assert (
        src.shape[leading_mode] % elem_per_copy == 0  # type: ignore[index, call-overload]
        and dst.shape[leading_mode] % elem_per_copy == 0  # type: ignore[index, call-overload]
    )

    _convert(src, dst, leading_mode, elem_per_copy)


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

    seed, sample_ratio = rand_cfg  # type: ignore[misc]
    random.seed(seed)

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
    kernel: Callable[..., Any], stream: cuda_driver.CUstream, *args: Any, **kwargs: Any
) -> bool:
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

    try:
        kernel(*args, **kwargs)
    except Exception:
        # Always end the capture even on failure to avoid zombie capture state
        # that would poison all subsequent graph capture operations in the process.
        try:
            cuda_runtime.cudaStreamEndCapture(stream)
        except Exception:
            pass
        raise

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
    use_cupti: bool = False,
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
        if type(workspace) != JitArguments:
            raise TypeError(
                "workspace_generator and/or kernel_arguments should use JitArguments type"
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

        if int(stream) != int(
            cuda_driver.CUstream_flags.CU_STREAM_DEFAULT
        ) and not _does_kernel_use_stream(
            callable, stream, *workspaces[0].args, **workspaces[0].kwargs
        ):
            raise ValueError(
                "CUDA stream passed to benchmark does not match the stream the kernel was launched in"
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

    logger: Optional[logging.Logger] = None

    @classmethod
    def _initialize_logger(cls) -> None:
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
        cls,
        func: Callable[..., Any],
        warmup_iterations: int,
        iterations: int,
        autotune_update_params: list[str],
    ) -> Callable[..., Any]:
        """Create a wrapper function that performs auto-tuning

        Args:
            func: Original function

        Returns:
            Decorated wrapper function
        """
        from cutlass.cute import compile

        # Initialize autotune parameters
        if not hasattr(func, "_autotune_params"):
            func._original_func = func  # type: ignore[attr-defined]
            func._autotune_params = {}  # type: ignore[attr-defined]
            func._autotune_update_params = autotune_update_params  # type: ignore[attr-defined]
            func._best_kernel = dict()  # type: ignore[attr-defined]
            func._best_config = dict()  # type: ignore[attr-defined]

            # Create wrapper function for auto-tuning
            @functools.wraps(func)
            def tuning_wrapper(*args: Any, **kwargs: Any) -> Any:
                parameters = inspect.signature(func._original_func).parameters.keys()  # type: ignore[attr-defined]
                tuning_key: Any = list()
                for param_name in func._autotune_update_params:  # type: ignore[attr-defined]
                    if param_name in kwargs.keys():
                        tuning_key.append(kwargs[param_name])
                    else:
                        index = list(parameters).index(param_name)
                        if index < len(args):
                            tuning_key.append(args[index])
                tuning_key = tuple(tuning_key)
                if tuning_key in func._best_kernel.keys():  # type: ignore[attr-defined]
                    cls.logger.info(  # type: ignore[union-attr]
                        f"Using cached best configuration: {func._best_config[tuning_key]}"  # type: ignore[attr-defined]
                    )
                    return func._best_kernel[tuning_key](*args, **kwargs)  # type: ignore[attr-defined]

                # Get all parameter configurations
                params_dict = func._autotune_params  # type: ignore[attr-defined]
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
                    cls.logger.info(f"Tuning configuration: {current_config}")  # type: ignore[union-attr]

                    try:
                        # Call the original function, using current configuration to replace default parameters
                        # For example, if current_config contains "cluster_shape_mn": (2, 1)
                        # It will override func's default parameter value
                        merged_kwargs = {**kwargs, **current_config}
                        compiled_func = compile(
                            func._original_func,  # type: ignore[attr-defined]
                            *args,
                            **merged_kwargs,
                        )

                        # Detect which constexpr arguments we need to remove from args and merged_kwargs
                        # This is done because after compiling our function signature will change, removing all constexpr arguments.
                        indexes_to_remove = list()
                        for arg in compiled_func.execution_args.get_constexpr_args():
                            if arg["argument_name"] in merged_kwargs:
                                del merged_kwargs[arg["argument_name"]]
                            elif arg["argument_index"] is not None:
                                indexes_to_remove.append(arg["argument_index"])
                            if arg["argument_name"] not in func._autotune_update_params:  # type: ignore[attr-defined]
                                # Handle the case where the programmer avoided autotuning over constexpr values, and
                                # recompile in that case
                                func._autotune_update_params.append(  # type: ignore[attr-defined]
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

                        cls.logger.info(f"   Execution time: {cur_time} us")  # type: ignore[union-attr]

                        # Update best results
                        if cur_time < min_time:
                            min_time = cur_time
                            best_kernel = compiled_func
                            best_config = current_config

                    except NotImplementedError as e:
                        cls.logger.info(  # type: ignore[union-attr]
                            f"   Encountered unimplemented error, abort execution: {e}"
                        )
                        raise e
                    except (ValueError, TypeError) as e:
                        cls.logger.info(f"   Configuration parameter skipping: {e}")  # type: ignore[union-attr]
                        raise e
                        continue
                    except Exception as e:
                        cls.logger.info(f"   Execution error skipping: {e}")  # type: ignore[union-attr]
                        raise e
                        continue

                end = time()
                tuning_time = end - start

                if best_kernel is None:
                    raise ValueError("No best kernel found")

                cls.logger.info(  # type: ignore[union-attr]
                    f"Best configuration: {best_config}, execution time: {min_time} us"
                )
                cls.logger.info(f"Total tuning time: {tuning_time} s")  # type: ignore[union-attr]
                func._best_kernel[tuning_key] = best_kernel  # type: ignore[attr-defined]
                func._best_config[tuning_key] = best_config  # type: ignore[attr-defined]
                return best_kernel(*args, **kwargs)

            # Append autotune wrapper to not conflict with the jit kernel names
            tuning_wrapper.__name__ = func.__name__ + "_autotune_wrapper"
            tuning_wrapper.__qualname__ = func.__qualname__ + "_autotune_wrapper"

            return tuning_wrapper

        return func  # If already has a wrapper, return the original function

    def __init__(
        self,
        params_dict: Optional[Dict[str, List[Any]]] = None,
        update_on_change: Optional[List[str]] = None,
        warmup_iterations: int = 10,
        iterations: int = 100,
    ) -> None:
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

    def __call__(self, func: Callable[..., Any]) -> Callable[..., Any]:
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
    func: Callable[..., Callable[[], Any]],
    params_dict: Optional[Dict[str, List[Any]]] = None,
    kernel_arguments: JitArguments = JitArguments(),
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

    if params_dict is None:
        raise ValueError("params_dict must be provided")

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
