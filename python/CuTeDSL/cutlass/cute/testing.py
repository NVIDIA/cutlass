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

import random
import numpy as np
import functools
import hashlib

from cutlass.cutlass_dsl import (
    const,
    T,
    CuTeDSL,
    BaseDSL,
    t,
    Constexpr,
    detect_gpu_arch,
)

import cutlass._mlir.dialects.cute as _cute_ir
import cutlass._mlir.ir as ir
from cutlass._mlir.dialects import nvvm, cf, vector, builtin

from cutlass.cute import core
from cutlass.cute import nvgpu
from typing import Type
from inspect import isclass


def assert_(cond, msg=None):
    cf.assert_(t.Boolean(cond).ir_value(), msg if msg else "")


def _maybe_recast_tensor_from_f4(src: core.Tensor, tv_layout: core.Layout):
    if src.element_type.width == 4:
        tv_layout = core.recast_layout(8, 4, tv_layout)
        src = core.recast_tensor(src, dtype=t.Int8)
    return src, tv_layout


def _maybe_recast_to_f4(input: core.TensorSSA, dtype: Type[core.Numeric]):
    """Conditionally recasts the tensor to 4-bit type if the destination type is 4-bit.

    :param input: The input tensor to recast.
    :param dtype: The target numeric type to potentially recast to.
    :raises TypeError: If dtype is not a subclass of Numeric.
    :return: A new tensor recast to 4-bit if dtype is 4-bit, otherwise returns self unchanged.
    """
    if not isclass(dtype) or not issubclass(dtype, core.Numeric):
        raise TypeError(f"dst_ty must be a type of Numeric, but got {dtype}")

    if dtype.width == 4:
        recast_shape = core.recast_layout(4, 8, core.make_layout(input.shape)).shape
        i4_vec = vector.bitcast(
            T.vector(input.type.shape[0] * 2, T.i(4)), input.maybe_downcast()
        )
        res_vect = builtin.unrealized_conversion_cast(
            [T.vector(i4_vec.type.shape[0], dtype.mlir_type)], [i4_vec]
        )
        return core.TensorSSA(res_vect, recast_shape, dtype)
    return input


def _maybe_recast_from_f4(input: core.TensorSSA, src_dtype: Type[core.Numeric]):
    """Conditionally recasts the tensor from 4-bit type if the source type is 4-bit.

    :param input: The input tensor to recast.
    :param src_dtype: The source numeric type to potentially recast from.
    :raises TypeError: If src_dtype is not a subclass of Numeric.
    :return: A new tensor recast from 4-bit if src_dtype is 4-bit, otherwise returns self unchanged.
    """
    if not isclass(src_dtype) or not issubclass(src_dtype, core.Numeric):
        raise TypeError(f"src_ty must be a type of Numeric, but got {src_dtype}")

    if src_dtype.width == 4:
        recast_shape = core.recast_layout(8, 4, core.make_layout(input.shape)).shape
        i4_vec = builtin.unrealized_conversion_cast(
            [T.vector(input.type.shape[0], T.i(4))], [input.maybe_downcast()]
        )
        res_vect = vector.bitcast(T.vector(i4_vec.type.shape[0] // 2, T.i8()), i4_vec)
        return core.TensorSSA(res_vect, recast_shape, core.Int8)
    return input


@CuTeDSL.kernel
def _convert_kernel(
    gSrc: core.Tensor,
    gDst: core.Tensor,
    cSrc: core.Tensor,
    src_tv_layout: core.Layout,
    dst_tv_layout: core.Layout,
    src_shape: core.Shape,
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
    tidfrgSrc = core.composition(ctaSrc, src_tv_layout)  # (T,V)
    tidfrgDst = core.composition(ctaDst, dst_tv_layout)  # (T,V)
    tidfrgCSrc = core.composition(ctaCSrc, src_tv_layout)  # (T,V)
    # print(f"tidfrgSrc = {tidfrgSrc.type}")

    # slice for threads
    thr_coord = (tidx, None)
    thrSrc = tidfrgSrc[thr_coord]  # (V)
    thrDst = tidfrgDst[thr_coord]  # (V)
    thrCSrc = tidfrgCSrc[thr_coord]  # (V)
    # print(f"thrSrc = {thrSrc.type}")

    # predicate
    if core.elem_less(thrCSrc[0], src_shape):
        # allocate fragments for gmem->rmem
        frgSrc = core.make_fragment(
            core.get(src_tv_layout, mode=[1]), gSrc.element_type
        )  # (V)
        frgDst = core.make_fragment(
            core.get(dst_tv_layout, mode=[1]), gDst.element_type
        )  # (V)
        # print(f"frgSrc = {frgSrc.type}")

        # Move data to reg address space
        copy_atom_load = core.make_copy_atom(nvgpu.CopyUniversalOp(), gSrc.element_type)
        core.copy(copy_atom_load, thrSrc, frgSrc)

        vec_src = frgSrc.load()
        vec_src = _maybe_recast_to_f4(vec_src, src_ty)
        vec_dst = vec_src.to(dst_ty)
        vec_dst = _maybe_recast_from_f4(vec_dst, dst_ty)
        frgDst.store(vec_dst)

        # Copy the results back to c
        copy_atom_stg = core.make_copy_atom(nvgpu.CopyUniversalOp(), gDst.element_type)
        core.copy(copy_atom_stg, frgDst, thrDst)


@CuTeDSL.jit(preprocess=False)
def _convert(
    src: core.Tensor,
    dst: core.Tensor,
    leading_mode: Constexpr,
    elem_per_copy: Constexpr,
):

    # Step 1. figure proper tv_layout
    src_ty = src.element_type
    dst_ty = dst.element_type

    tv_layout = core.make_layout((128, elem_per_copy), stride=(elem_per_copy, 1))

    # Step 2. maybe recast from f4 tensor
    src, src_tv_layout = _maybe_recast_tensor_from_f4(src, tv_layout)
    dst, dst_tv_layout = _maybe_recast_tensor_from_f4(dst, tv_layout)
    src_shape = src.shape
    # predicate tensor
    idA = core.make_identity_tensor(src.shape)

    # Step 3. select a proper tiling pattern as (...,TileV, ...)
    src_cta_tiler = [
        1,
    ] * core.rank(src.layout)
    src_cta_tiler[leading_mode] = core.size(src_tv_layout)  # (...,TileV,...)
    dst_cta_tiler = [
        1,
    ] * core.rank(dst.layout)
    dst_cta_tiler[leading_mode] = core.size(dst_tv_layout)  # (...,TileV,...)

    # Step 4. partition input and output tensor by cta tiler.
    gS = core.zipped_divide(
        src, tuple(src_cta_tiler)
    )  # ((...,TileV,...),(...,RestV,...))
    cS = core.zipped_divide(
        idA, tuple(src_cta_tiler)
    )  # ((...,TileV,...),(...,RestV,...))
    gD = core.zipped_divide(
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
        grid=[core.size(gS, mode=[1]), 1, 1],
        block=[core.size(src_tv_layout, mode=[0]), 1, 1],
    )


# Converts from src tensor to dst tensor, their logical shape are required to be the same.
# And when src or dst dtype is narrow precision(Float4E2M1FN/Float8E8M0FNU/Float8E4M3FN), the shape of
# their leading dimension should be 4(fp8)/8(fp4) element align. (nvgpu.cvt_fptrunc/cvt_fpext
# needs 32-bits aligned input/output)
def convert(src: core.Tensor, dst: core.Tensor):
    assert len(src.shape) == len(
        dst.shape
    ), "Shape of src and dst tensors should be the same rank."
    # find leading mode
    leading_mode = np.argmin([np.min(s) for s in src.stride])

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
    import pytest
    import sys

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
