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


import functools
import inspect
import logging
import os
from itertools import product
from time import time
from typing import Any, Callable, Dict, List, Optional, Type

from cutlass.cutlass_dsl import Constexpr, CuTeDSL, T, dsl_user_op, const_expr

from .typing import (
    Numeric,
    Int8,
    Boolean,
    Tensor,
    Layout,
    Shape,
    is_int_tuple_type,
)

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

from cutlass._mlir import ir
from cutlass._mlir.dialects import builtin, cf, nvvm, vector


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
        assert self._tensor is not None
        return self._tensor.__extract_mlir_values__()  # type: ignore[attr-defined]

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
        if const_expr(idx >= self._num_assertions):
            raise ValueError("please increase the number of assertions!!!")
        if const_expr(self._init_value is True):
            self._tensor[idx] = pred and self._tensor[idx]  # type: ignore[index]
        else:
            self._tensor[idx] = pred  # type: ignore[index]
        self._msgs[idx] = f"{msg}\nAt {loc}"
        self._used_indices.add(idx)  # type: ignore[union-attr]

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
            self.verify()


def _maybe_recast_tensor_from_f4_f6(
    src: Tensor, tv_layout: Layout
) -> tuple[Tensor, Layout]:
    elem_type = src.element_type
    assert not is_int_tuple_type(elem_type)
    if elem_type.width == 4:
        tv_layout = recast_layout(8, 4, tv_layout)
        src = recast_tensor(src, dtype=Int8)
    elif elem_type.width == 6:
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
    src_cta_tiler[leading_mode] = size(src_tv_layout)  # (...,TileV,...)
    dst_cta_tiler = [
        1,
    ] * rank(dst.layout)
    dst_cta_tiler[leading_mode] = size(dst_tv_layout)  # (...,TileV,...)

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
    src_shape = src.shape
    src_stride = src.stride
    assert isinstance(src_shape, tuple) and isinstance(src_stride, tuple)
    dst_shape = dst.shape
    assert isinstance(dst_shape, tuple)
    assert len(src_shape) == len(dst_shape), (
        "Shape of src and dst tensors should be the same rank."
    )
    # find leading mode
    leading_mode = [
        idx
        for idx, (shape, stride) in enumerate(zip(src_shape, src_stride))
        if shape > 1 and stride == 1  # type: ignore[operator]
    ]
    if len(leading_mode) != 1:
        raise ValueError(f"Leading mode should be unique, but got {leading_mode}")
    leading_mode = leading_mode[0]  # type: ignore[assignment]

    elem_per_copy = 2

    src_elem_type = src.element_type
    dst_elem_type = dst.element_type
    assert not is_int_tuple_type(src_elem_type) and not is_int_tuple_type(dst_elem_type)
    if src_elem_type.width == 4 or dst_elem_type.width == 4:
        elem_per_copy = 8
    elif src_elem_type.width == 8 or dst_elem_type.width == 8:
        elem_per_copy = 4
    elif src_elem_type.width == 6 or dst_elem_type.width == 6:
        elem_per_copy = 16  # 16*f6 elements per 96 bits(12 bytes)
    assert (
        src.shape[leading_mode] % elem_per_copy == 0  # type: ignore[index, call-overload]
        and dst.shape[leading_mode] % elem_per_copy == 0  # type: ignore[index, call-overload]
    )

    _convert(src, dst, leading_mode, elem_per_copy)


#########################################
# Tuning utilities
#########################################


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

    _logger: Optional[logging.Logger] = None

    @classmethod
    def _initialize_logger(cls) -> None:
        """Ensure the logger is initialized"""
        if cls._logger is None:
            cls._logger = logging.getLogger(__name__ + "_Autotune")
            if not cls._logger.handlers:
                handler = logging.StreamHandler()
                formatter = logging.Formatter(
                    "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
                )
                handler.setFormatter(formatter)
                cls._logger.addHandler(handler)
            if (
                os.environ.get("CUTE_DSL_LOG_AUTOTUNE") is not None
                and os.environ.get("CUTE_DSL_LOG_AUTOTUNE") != "0"
            ):
                cls._logger.setLevel(logging.INFO)

    @classmethod
    def log(cls) -> logging.Logger:
        """Return the initialized logger; asserts ``_initialize_logger`` ran first."""
        assert cls._logger is not None, "logger is not initialized"
        return cls._logger

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
        from cutlass.testing import _benchmark_for_autotune

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
                    cls.log().info(
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
                    cls.log().info(f"Tuning configuration: {current_config}")

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

                        cls.log().info(f"   Execution time: {cur_time} us")

                        # Update best results
                        if cur_time < min_time:
                            min_time = cur_time
                            best_kernel = compiled_func
                            best_config = current_config

                    except NotImplementedError as e:
                        cls.log().info(
                            f"   Encountered unimplemented error, abort execution: {e}"
                        )
                        raise e
                    except (ValueError, TypeError) as e:
                        cls.log().info(f"   Configuration parameter skipping: {e}")
                        raise e
                        continue
                    except Exception as e:
                        cls.log().info(f"   Execution error skipping: {e}")
                        raise e
                        continue

                end = time()
                tuning_time = end - start

                if best_kernel is None:
                    raise ValueError("No best kernel found")

                cls.log().info(
                    f"Best configuration: {best_config}, execution time: {min_time} us"
                )
                cls.log().info(f"Total tuning time: {tuning_time} s")
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


################################################
# Deprecated re-exports
################################################
# The symbols below have moved to ``cutlass.testing``. They are kept here as
# ``@deprecated`` shims so existing ``cutlass.cute.testing.*`` call sites keep
# working but emit ``DeprecationWarning``. Please migrate to
# ``cutlass.testing.*``; these shims will be removed in a future release.

from typing_extensions import deprecated as _deprecated

from cutlass.testing import CantImplementError as _CantImplementError
from cutlass.testing import CuptiProfiler as _CuptiProfiler
from cutlass.testing import JitArguments as _JitArguments
from cutlass.testing import TensorInitConfig as _TensorInitConfig
from cutlass.testing import add_tensor_init_args as _add_tensor_init_args
from cutlass.testing import benchmark as _benchmark
from cutlass.testing import get_workspace_count as _get_workspace_count
from cutlass.testing import sample_pytest as _sample_pytest
from cutlass.testing import should_use_normal_init as _should_use_normal_init
from cutlass.testing import (
    tensor_init_config_from_args as _tensor_init_config_from_args,
)
from cutlass.testing import tune as _tune
from cutlass.testing import validate_tensor_init_args as _validate_tensor_init_args


# --- Deprecated classes (subclass + @deprecated emits warning on instantiation) ---


@_deprecated(
    "cute.testing.CantImplementError is deprecated, use cutlass.testing.CantImplementError instead"
)
class CantImplementError(_CantImplementError):
    pass


@_deprecated(
    "cute.testing.CuptiProfiler is deprecated, use cutlass.testing.CuptiProfiler instead"
)
class CuptiProfiler(_CuptiProfiler):
    pass


@_deprecated(
    "cute.testing.JitArguments is deprecated, use cutlass.testing.JitArguments instead"
)
class JitArguments(_JitArguments):
    pass


@_deprecated(
    "cute.testing.TensorInitConfig is deprecated, use cutlass.testing.TensorInitConfig instead"
)
class TensorInitConfig(_TensorInitConfig):
    pass


# --- Deprecated free functions (decorator wraps callable; DeprecationWarning on call) ---

benchmark = _deprecated(
    "cute.testing.benchmark is deprecated, use cutlass.testing.benchmark instead"
)(_benchmark)

get_workspace_count = _deprecated(
    "cute.testing.get_workspace_count is deprecated, use cutlass.testing.get_workspace_count instead"
)(_get_workspace_count)

tune = _deprecated("cute.testing.tune is deprecated, use cutlass.testing.tune instead")(
    _tune
)

sample_pytest = _deprecated(
    "cute.testing.sample_pytest is deprecated, use cutlass.testing.sample_pytest instead"
)(_sample_pytest)

add_tensor_init_args = _deprecated(
    "cute.testing.add_tensor_init_args is deprecated, use cutlass.testing.add_tensor_init_args instead"
)(_add_tensor_init_args)

validate_tensor_init_args = _deprecated(
    "cute.testing.validate_tensor_init_args is deprecated, use cutlass.testing.validate_tensor_init_args instead"
)(_validate_tensor_init_args)

tensor_init_config_from_args = _deprecated(
    "cute.testing.tensor_init_config_from_args is deprecated, use cutlass.testing.tensor_init_config_from_args instead"
)(_tensor_init_config_from_args)

should_use_normal_init = _deprecated(
    "cute.testing.should_use_normal_init is deprecated, use cutlass.testing.should_use_normal_init instead"
)(_should_use_normal_init)
