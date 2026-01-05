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


from cutlass.base_dsl.arch import Arch
from cutlass.base_dsl.common import DSLRuntimeError
from cutlass.cutlass_dsl import BaseDSL, dsl_user_op

from cutlass._mlir import ir
from cutlass._mlir.dialects import builtin, arith, llvm, vector

from .nvvm_wrappers import (
    cvt_i8_bf16,
    cvt_f32x2_bf16x2,
    cvt_i8x4_to_f32x4,
    cvt_i8x2_to_f32x2,
    cvt_i4x8_to_bf16x8,
    cvt_i4x4_to_bf16x4,
    cvt_i4x2_to_bf16x2,
    cvt_i4_bf16,
    cvt_f4e2m1x8_to_f16x8,
    cvt_f4e2m1x4_to_f16x4,
    cvt_f4e2m1x2_to_f16x2,
    cvt_f4e2m1_f16,
)

from ..typing import (
    Int4,
    Int8,
    Int32,
    Float16,
    Float32,
    BFloat16,
    Float32,
)

@dsl_user_op
def cvt_i8_bf16_intrinsic(vec_i8, length, *, loc=None, ip=None):
    """
    Fast conversion from int8 to bfloat16. It converts a vector of int8 to a vector of bfloat16.

    :param vec_i8: The input vector of int8.
    :type vec_i8: 1D vector of int8
    :param length: The length of the input vector.
    :type length: int
    :return: The output 1D vector of bfloat16 with the same length as the input vector.
    :rtype: 1D vector of bfloat16
    """
    arch = BaseDSL._get_dsl().get_arch_enum()
    if not arch in cvt_i8_bf16_intrinsic.supported_archs:
        raise DSLRuntimeError(f"cvt_i8_bf16_intrinsic is not supported on {arch}")
    src_pos = 0
    vec_i8x4_type = ir.VectorType.get([4], Int8.mlir_type, loc=loc)
    vec_i8x2_type = ir.VectorType.get([2], Int8.mlir_type, loc=loc)
    vec_f32x2_type = ir.VectorType.get([2], Float32.mlir_type, loc=loc)
    vec_dst_type = ir.VectorType.get([length], BFloat16.mlir_type, loc=loc)
    vec_dst = llvm.mlir_zero(vec_dst_type, loc=loc, ip=ip)
    # try to use vectorized version
    if length >= 4:
        num_vec4 = length // 4
        for _ in range(num_vec4):
            vec_i8x4 = vector.extract_strided_slice(
                vec_i8x4_type, vec_i8, [src_pos], [4], [1], loc=loc, ip=ip
            )
            vec_f32x4 = cvt_i8x4_to_f32x4(vec_i8x4, loc=loc, ip=ip)
            vec_f32x2_lo = vector.extract_strided_slice(
                vec_f32x2_type, vec_f32x4, [0], [2], [1], loc=loc, ip=ip
            )
            vec_f32x2_hi = vector.extract_strided_slice(
                vec_f32x2_type, vec_f32x4, [2], [2], [1], loc=loc, ip=ip
            )
            vec_bf16x2_lo = cvt_f32x2_bf16x2(vec_f32x2_lo, loc=loc, ip=ip)
            vec_bf16x2_hi = cvt_f32x2_bf16x2(vec_f32x2_hi, loc=loc, ip=ip)
            vec_dst = vector.insert_strided_slice(
                vec_bf16x2_lo, vec_dst, [src_pos], [1], loc=loc, ip=ip
            )
            vec_dst = vector.insert_strided_slice(
                vec_bf16x2_hi, vec_dst, [src_pos + 2], [1], loc=loc, ip=ip
            )
            src_pos += 4
            length -= 4
    if length >= 2:
        vec_i8x2 = vector.extract_strided_slice(
            vec_i8x2_type, vec_i8, [src_pos], [2], [1], loc=loc, ip=ip
        )
        vec_f32x2 = cvt_i8x2_to_f32x2(vec_i8x2, loc=loc, ip=ip)
        vec_bf16x2 = cvt_f32x2_bf16x2(vec_f32x2, loc=loc, ip=ip)
        vec_dst = vector.insert_strided_slice(
            vec_bf16x2, vec_dst, [src_pos], [1], loc=loc, ip=ip
        )
        src_pos += 2
        length -= 2
    if length >= 1:
        val_bf16 = cvt_i8_bf16(
            vector.extractelement(
                vec_i8,
                position=arith.constant(Int32.mlir_type, src_pos),
                loc=loc,
                ip=ip,
            ),
            loc=loc,
            ip=ip,
        )
        vec_dst = vector.insertelement(
            val_bf16,
            vec_dst,
            position=arith.constant(Int32.mlir_type, src_pos),
            loc=loc,
            ip=ip,
        )
    return vec_dst


@dsl_user_op
def cvt_i4_bf16_intrinsic(vec_i4, length, *, loc=None, ip=None):
    """
    Fast conversion from int4 to bfloat16. It converts a vector of int4 to a vector of bfloat16.

    :param vec_i4: The input vector of int4.
    :type vec_i4: 1D vector of int4
    :param length: The length of the input vector.
    :type length: int
    :return: The output 1D vector of bfloat16 with the same length as the input vector.
    :rtype: 1D vector of bfloat16
    """
    arch = BaseDSL._get_dsl().get_arch_enum()
    if not arch in cvt_i4_bf16_intrinsic.supported_archs:
        raise DSLRuntimeError(f"cvt_i4_bf16_intrinsic is not supported on {arch}")
    src_pos = 0
    vec_i4x8_type = ir.VectorType.get([8], Int4.mlir_type, loc=loc)
    vec_i4x4_type = ir.VectorType.get([4], Int4.mlir_type, loc=loc)
    vec_i4x2_type = ir.VectorType.get([2], Int4.mlir_type, loc=loc)
    vec_dst_type = ir.VectorType.get([length], BFloat16.mlir_type, loc=loc)
    vec_dst = llvm.mlir_zero(vec_dst_type, loc=loc, ip=ip)
    # try to use vectorized version
    if length >= 8:
        num_vec8 = length // 8
        for _ in range(num_vec8):
            vec_i4x8 = vector.extract_strided_slice(
                vec_i4x8_type, vec_i4, [src_pos], [8], [1], loc=loc, ip=ip
            )
            vec_bf16x8 = cvt_i4x8_to_bf16x8(vec_i4x8, loc=loc, ip=ip)
            vec_dst = vector.insert_strided_slice(
                vec_bf16x8, vec_dst, [src_pos], [1], loc=loc, ip=ip
            )
            src_pos += 8
            length -= 8
    if length >= 4:
        vec_i4x4 = vector.extract_strided_slice(
            vec_i4x4_type, vec_i4, [src_pos], [4], [1], loc=loc, ip=ip
        )
        vec_bf16x4 = cvt_i4x4_to_bf16x4(vec_i4x4, loc=loc, ip=ip)
        vec_dst = vector.insert_strided_slice(
            vec_bf16x4, vec_dst, [src_pos], [1], loc=loc, ip=ip
        )
        src_pos += 4
        length -= 4
    if length >= 2:
        vec_i4x2 = vector.extract_strided_slice(
            vec_i4x2_type, vec_i4, [src_pos], [2], [1], loc=loc, ip=ip
        )
        vec_bf16x2 = cvt_i4x2_to_bf16x2(vec_i4x2, loc=loc, ip=ip)
        vec_dst = vector.insert_strided_slice(
            vec_bf16x2, vec_dst, [src_pos], [1], loc=loc, ip=ip
        )
        src_pos += 2
        length -= 2
    if length >= 1:
        val_bf16 = cvt_i4_bf16(
            vector.extractelement(
                vec_i4,
                position=arith.constant(Int32.mlir_type, src_pos),
                loc=loc,
                ip=ip,
            ),
            loc=loc,
            ip=ip,
        )
        vec_dst = vector.insertelement(
            val_bf16,
            vec_dst,
            position=arith.constant(Int32.mlir_type, src_pos),
            loc=loc,
            ip=ip,
        )
    return vec_dst


@dsl_user_op
def cvt_f4e2m1_f16_intrinsic(vec_f4e2m1, length, *, loc=None, ip=None):
    """
    Convert a vector of float4e2m1 to a vector of float16.

    :param vec_f4e2m1: The input vector of float4e2m1.
    :type vec_f4e2m1: 1D vector of float4e2m1
    :param length: The length of the input vector.
    :type length: int
    :return: The output 1D vector of float16 with the same length as the input vector.
    :rtype: 1D vector of float16
    """
    src_pos = 0
    vec_src_i4 = builtin.unrealized_conversion_cast(
        [ir.VectorType.get([length], Int4.mlir_type, loc=loc)],
        [vec_f4e2m1],
        loc=loc,
        ip=ip,
    )
    vec_i4x8_type = ir.VectorType.get([8], Int4.mlir_type, loc=loc)
    vec_i4x4_type = ir.VectorType.get([4], Int4.mlir_type, loc=loc)
    vec_i4x2_type = ir.VectorType.get([2], Int4.mlir_type, loc=loc)
    vec_dst_type = ir.VectorType.get([length], Float16.mlir_type, loc=loc)
    vec_dst = llvm.mlir_zero(vec_dst_type, loc=loc, ip=ip)
    # try to use vectorized version
    if length >= 8:
        num_vec8 = length // 8
        for _ in range(num_vec8):
            vec_f4e2m1x8 = vector.extract_strided_slice(
                vec_i4x8_type, vec_src_i4, [src_pos], [8], [1], loc=loc, ip=ip
            )
            vec_f16x8 = cvt_f4e2m1x8_to_f16x8(vec_f4e2m1x8, loc=loc, ip=ip)
            vec_dst = vector.insert_strided_slice(
                vec_f16x8, vec_dst, [src_pos], [1], loc=loc, ip=ip
            )
            src_pos += 8
            length -= 8
    if length >= 4:
        vec_f4e2m1x4 = vector.extract_strided_slice(
            vec_i4x4_type, vec_src_i4, [src_pos], [4], [1], loc=loc, ip=ip
        )
        vec_f16x4 = cvt_f4e2m1x4_to_f16x4(vec_f4e2m1x4, loc=loc, ip=ip)
        vec_dst = vector.insert_strided_slice(
            vec_f16x4, vec_dst, [src_pos], [1], loc=loc, ip=ip
        )
        src_pos += 4
        length -= 4
    if length >= 2:
        vec_f4e2m1x2 = vector.extract_strided_slice(
            vec_i4x2_type, vec_src_i4, [src_pos], [2], [1], loc=loc, ip=ip
        )
        vec_f16x2 = cvt_f4e2m1x2_to_f16x2(vec_f4e2m1x2, loc=loc, ip=ip)
        vec_dst = vector.insert_strided_slice(
            vec_f16x2, vec_dst, [src_pos], [1], loc=loc, ip=ip
        )
        src_pos += 2
        length -= 2
    if length >= 1:
        val_f16 = cvt_f4e2m1_f16(
            vector.extractelement(
                vec_src_i4,
                position=arith.constant(Int32.mlir_type, src_pos),
                loc=loc,
                ip=ip,
            ),
            loc=loc,
            ip=ip,
        )
        vec_dst = vector.insertelement(
            val_f16,
            vec_dst,
            position=arith.constant(Int32.mlir_type, src_pos),
            loc=loc,
            ip=ip,
        )
    return vec_dst


# Expose supported architectures via the intrinsic symbol
cvt_i8_bf16_intrinsic.supported_archs = (
    *Arch.AmpereArchs(),
    *Arch.AdaArchs(),
    *Arch.HopperArchs(),
    *Arch.BlackwellArchs(),
)
cvt_i4_bf16_intrinsic.supported_archs = (
    Arch.sm_100a,
    Arch.sm_110a,
    Arch.sm_120a,
    Arch.sm_121a,
)
