#################################################################################################
#
# Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice, this
# list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright notice,
# this list of conditions and the following disclaimer in the documentation
# and/or other materials provided with the distribution.
#
# 3. Neither the name of the copyright holder nor the names of its
# contributors may be used to endorse or promote products derived from
# this software without specific prior written permission.
#
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
#
#################################################################################################


"""
Utilities for enumerating CUTLASS library SM107 kernels.
"""

import warnings
from itertools import product

try:
    from cutlass_library.library import *
    from cutlass_library.sm107_shapes import (
        SM107_MMA_SHAPES_F8F6F4_DENSE_1SM,
        SM107_MMA_SHAPES_F8F6F4_DENSE_2SM,
        SM107_MMA_SHAPES_MXF8F6F4_BLOCKSCALED_1SM,
        SM107_MMA_SHAPES_MXF8F6F4_BLOCKSCALED_2SM,
        SM107_MMA_SHAPES_MXNVF4_BLOCKSCALED_1SM,
        SM107_MMA_SHAPES_MXNVF4_BLOCKSCALED_2SM,
    )
    from cutlass_library.sm100_utils import get_tcgen05_level_from_global_level
except ImportError:
    from library import *
    from sm107_shapes import (
        SM107_MMA_SHAPES_F8F6F4_DENSE_1SM,
        SM107_MMA_SHAPES_F8F6F4_DENSE_2SM,
        SM107_MMA_SHAPES_MXF8F6F4_BLOCKSCALED_1SM,
        SM107_MMA_SHAPES_MXF8F6F4_BLOCKSCALED_2SM,
        SM107_MMA_SHAPES_MXNVF4_BLOCKSCALED_1SM,
        SM107_MMA_SHAPES_MXNVF4_BLOCKSCALED_2SM,
    )
    from sm100_utils import get_tcgen05_level_from_global_level


def generate_f8f6f4_math_instructions_sm107(
    level: int,
    enable_runtime_dtype: bool = True,
    enable_compile_time_dtype: bool = False,
):
    """
    Generate TensorOp MathInstruction objects for SM107 F8/F6/F4 dense GEMM.

    Args:
        level: Global instantiation level.
        enable_runtime_dtype: Whether to generate runtime-dtype instructions.
        enable_compile_time_dtype: Not yet supported for SM107; emits a warning if True.

    Returns:
        (math_instructions_1sm, math_instructions_2sm)
    """
    if enable_compile_time_dtype:
        warnings.warn(
            "SM107 does not support compile-time data types yet. "
            "enable_compile_time_dtype=True will be ignored.",
            UserWarning,
            stacklevel=2,
        )

    tcgen05_level = get_tcgen05_level_from_global_level(level)

    shapes_1sm = [
        shape for shape, min_level in SM107_MMA_SHAPES_F8F6F4_DENSE_1SM.items()
        if tcgen05_level >= min_level
    ]
    shapes_2sm = [
        shape for shape, min_level in SM107_MMA_SHAPES_F8F6F4_DENSE_2SM.items()
        if tcgen05_level >= min_level
    ]

    math_instructions_1sm = []
    math_instructions_2sm = []

    for shape in shapes_1sm:
        if enable_runtime_dtype:
            runtime_types = [
                DataType.f8,
            ]
            for a_type, b_type in product(runtime_types, repeat=2):
                math_instructions_1sm.append(
                    MathInstruction(
                        shape,
                        a_type, b_type, DataType.f32,
                        OpcodeClass.TensorOp,
                        MathOperation.multiply_add)
                )

    for shape in shapes_2sm:
        if enable_runtime_dtype:
            runtime_types = [
                DataType.f8,
            ]
            for a_type, b_type in product(runtime_types, repeat=2):
                math_instructions_2sm.append(
                    MathInstruction(
                        shape,
                        a_type, b_type, DataType.f32,
                        OpcodeClass.TensorOp,
                        MathOperation.multiply_add)
                )

    return math_instructions_1sm, math_instructions_2sm


def generate_mxf8f6f4_math_instructions_sm107(
    level: int,
    enable_runtime_dtype: bool = True,
    enable_compile_time_dtype: bool = False,
):
    """
    Generate BlockScaledTensorOp MathInstruction objects for SM107 MXF8F6F4 blockscaled GEMM.

    Mirrors sm100_utils.generate_mxf8f6f4_math_instructions_sm100(), restricted to the
    runtime f8 (a/b dynamic dtype) path only -- SM107 blockscaled currently only supports
    a/b = f8 with a runtime dtype, no f6/f4 or compile-time dtypes.

    Args:
        level: Global instantiation level.
        enable_runtime_dtype: Whether to generate runtime-dtype instructions.
        enable_compile_time_dtype: Not yet supported for SM107; emits a warning if True.

    Returns:
        (math_instructions_1sm, math_instructions_2sm)
    """
    if enable_compile_time_dtype:
        warnings.warn(
            "SM107 does not support compile-time data types yet. "
            "enable_compile_time_dtype=True will be ignored.",
            UserWarning,
            stacklevel=2,
        )

    tcgen05_level = get_tcgen05_level_from_global_level(level)

    shapes_1sm = [
        shape for shape, min_level in SM107_MMA_SHAPES_MXF8F6F4_BLOCKSCALED_1SM.items()
        if tcgen05_level >= min_level
    ]
    shapes_2sm = [
        shape for shape, min_level in SM107_MMA_SHAPES_MXF8F6F4_BLOCKSCALED_2SM.items()
        if tcgen05_level >= min_level
    ]

    math_instructions_1sm = []
    math_instructions_2sm = []

    for shape in shapes_1sm:
        if enable_runtime_dtype:
            runtime_types = [
                DataType.f8,
            ]
            for a_type, b_type in product(runtime_types, repeat=2):
                math_instructions_1sm.append(
                    MathInstruction(
                        shape,
                        a_type, b_type, DataType.f32,
                        OpcodeClass.BlockScaledTensorOp,
                        MathOperation.multiply_add,
                        DataType.ue8m0)
                )

    for shape in shapes_2sm:
        if enable_runtime_dtype:
            runtime_types = [
                DataType.f8,
            ]
            for a_type, b_type in product(runtime_types, repeat=2):
                math_instructions_2sm.append(
                    MathInstruction(
                        shape,
                        a_type, b_type, DataType.f32,
                        OpcodeClass.BlockScaledTensorOp,
                        MathOperation.multiply_add,
                        DataType.ue8m0)
                )

    return math_instructions_1sm, math_instructions_2sm


def generate_mxnvf4_math_instructions_sm107(level: int):
    """
    Generate BlockScaledTensorOp MathInstruction objects for SM107 MXNVF4 blockscaled GEMM.

    a/b are always the compile-time e2m1 type -- SM107 NVF4 has no other 4-bit element
    type, so a runtime-dtype (type-erased) a/b is pointless here. Both scale-factor
    vector sizes (16 and 32) support all three scale-factor dtypes: ue8m0, ue4m3, ue5m3.
    The shapes/instructions themselves don't differ by vector size, so callers reuse the
    same (math_instructions_1sm, math_instructions_2sm) lists for both Vs16 and Vs32
    kernel schedules; only the chosen kernel schedule type differs.

    Args:
        level: Global instantiation level.

    Returns:
        (math_instructions_1sm, math_instructions_2sm)
    """
    tcgen05_level = get_tcgen05_level_from_global_level(level)

    sf_types = [DataType.ue8m0, DataType.ue4m3, DataType.ue5m3]

    def _generate(shapes_table):
        math_instructions = []
        shapes = [
            shape for shape, min_level in shapes_table.items()
            if tcgen05_level >= min_level
        ]
        for shape in shapes:
            for sf_type in sf_types:
                math_instructions.append(
                    MathInstruction(
                        shape,
                        DataType.e2m1, DataType.e2m1, DataType.f32,
                        OpcodeClass.BlockScaledTensorOp,
                        MathOperation.multiply_add,
                        sf_type)
                )
        return math_instructions

    math_instructions_1sm = _generate(SM107_MMA_SHAPES_MXNVF4_BLOCKSCALED_1SM)
    math_instructions_2sm = _generate(SM107_MMA_SHAPES_MXNVF4_BLOCKSCALED_2SM)

    return math_instructions_1sm, math_instructions_2sm
