# SPDX-FileCopyrightText: Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
from cutlass._mlir.dialects import arith, llvm, vector

from .nvvm_wrappers import (
    cvt_i8_bf16,
    cvt_i8x2_to_bf16x2,
    cvt_i8x4_to_bf16x4,
    cvt_f32x2_bf16x2,
    cvt_i8x4_to_f32x4,
    cvt_i8x2_to_f32x2,
    cvt_i4x8_to_bf16x8,
    cvt_i4x4_to_bf16x4,
    cvt_i4x2_to_bf16x2,
    cvt_i4_bf16,
    cvt_f32_bf16,
    sext_unpacked_i4x4_to_i8x4,
)
from ..typing import Int4, Int8, Float32, BFloat16, Int32


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
    arch = BaseDSL._get_dsl().get_arch_enum()
    # try to use vectorized version
    if length >= 4:
        num_vec4 = length // 4
        for _ in range(num_vec4):
            vec_i8x4 = vector.extract_strided_slice(
                vec_i8x4_type, vec_i8, [src_pos], [4], [1], loc=loc, ip=ip
            )
            if arch in cvt_i8_bf16_intrinsic.s26_bf16_supported_archs:
                vec_bf16x4 = cvt_i8x4_to_bf16x4(vec_i8x4, loc=loc, ip=ip)
                vec_dst = vector.insert_strided_slice(
                    vec_bf16x4, vec_dst, [src_pos], [1], loc=loc, ip=ip
                )
            else:
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
        if arch in cvt_i8_bf16_intrinsic.s26_bf16_supported_archs:
            vec_bf16x2 = cvt_i8x2_to_bf16x2(vec_i8x2, loc=loc, ip=ip)
        else:
            vec_f32x2 = cvt_i8x2_to_f32x2(vec_i8x2, loc=loc, ip=ip)
            vec_bf16x2 = cvt_f32x2_bf16x2(vec_f32x2, loc=loc, ip=ip)
        vec_dst = vector.insert_strided_slice(
            vec_bf16x2, vec_dst, [src_pos], [1], loc=loc, ip=ip
        )
        src_pos += 2
        length -= 2
    if length >= 1:
        if arch in cvt_i8_bf16_intrinsic.s26_bf16_supported_archs:
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
        else:
            src_i8 = vector.extractelement(
                vec_i8,
                position=arith.constant(Int32.mlir_type, src_pos),
                loc=loc,
                ip=ip,
            )
            src_i32 = llvm.sext(Int32.mlir_type, src_i8, loc=loc, ip=ip)
            src_f32 = llvm.sitofp(Float32.mlir_type, src_i32, loc=loc, ip=ip)
            val_bf16 = cvt_f32_bf16(src_f32, loc=loc, ip=ip)
        vec_dst = vector.insertelement(
            val_bf16,
            vec_dst,
            position=arith.constant(Int32.mlir_type, src_pos),
            loc=loc,
            ip=ip,
        )
    return vec_dst


@dsl_user_op
def cvt_i4_bf16_intrinsic(vec_i4, length, *, with_shuffle=False, loc=None, ip=None):
    """
    Fast conversion from int4 to bfloat16. It converts a vector of int4 to a vector of bfloat16.

    :param vec_i4: The input vector of int4.
    :type vec_i4: 1D vector of int4
    :param length: The length of the input vector.
    :type length: int
    :param with_shuffle: Whether the input vec_i4 follows a specific shuffle pattern.
        If True, for consecutive 8 int4 values with indices of (0, 1, 2, 3, 4, 5, 6, 7),
        the input elements are shuffled to (0, 2, 1, 3, 4, 6, 5, 7). For tailing elements less than 8,
        the shuffle pattern is (0, 2, 1, 3) for 4 elements. No shuffle is needed for less than 4 elements.
        Shuffle could help to produce converted bf16 values in the natural order of (0, 1, 2 ,3 ,4 ,5 ,6 ,7)
        without extra prmt instructions and thus better performance.
    :type with_shuffle: bool
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
            vec_bf16x8 = cvt_i4x8_to_bf16x8(
                vec_i4x8, with_shuffle=with_shuffle, loc=loc, ip=ip
            )
            vec_dst = vector.insert_strided_slice(
                vec_bf16x8, vec_dst, [src_pos], [1], loc=loc, ip=ip
            )
            src_pos += 8
            length -= 8
    if length >= 4:
        vec_i4x4 = vector.extract_strided_slice(
            vec_i4x4_type, vec_i4, [src_pos], [4], [1], loc=loc, ip=ip
        )
        vec_bf16x4 = cvt_i4x4_to_bf16x4(
            vec_i4x4, with_shuffle=with_shuffle, loc=loc, ip=ip
        )
        vec_dst = vector.insert_strided_slice(
            vec_bf16x4, vec_dst, [src_pos], [1], loc=loc, ip=ip
        )
        src_pos += 4
        length -= 4
    if length >= 2:
        vec_i4x2 = vector.extract_strided_slice(
            vec_i4x2_type, vec_i4, [src_pos], [2], [1], loc=loc, ip=ip
        )
        vec_bf16x2 = cvt_i4x2_to_bf16x2(
            vec_i4x2, with_shuffle=with_shuffle, loc=loc, ip=ip
        )
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
def sext_unpacked_i4_i8_intrinsic(vec_unpacked_i4, length, *, loc=None, ip=None):
    """
    Sign extend vector of int4 unpacked in 8b containers to packed int8

    :param vec_unpacked_i4: The input vector of unpacked int4.
    :type vec_unpacked_i4: 1D vector of unpacked int4
    :param length: The length of the input vector.
    :type length: int
    :return: The output 1D vector of int8 with the same length as the input vector.
    :rtype: 1D vector of int8
    """
    assert length % 4 == 0, "unsupported length"

    vec_i8x4_type = ir.VectorType.get([4], Int8.mlir_type, loc=loc)
    vec_i8_type = ir.VectorType.get([length], Int8.mlir_type, loc=loc)
    vec_i8 = llvm.mlir_zero(vec_i8_type, loc=loc, ip=ip)

    for pos in range(0, length, 4):
        vec_unpacked_i4x4 = vector.extract_strided_slice(
            vec_i8x4_type, vec_unpacked_i4, [pos], [4], [1], loc=loc, ip=ip
        )
        vec_i8x4 = sext_unpacked_i4x4_to_i8x4(vec_unpacked_i4x4, loc=loc, ip=ip)
        vec_i8 = vector.insert_strided_slice(
            vec_i8x4, vec_i8, [pos], [1], loc=loc, ip=ip
        )

    return vec_i8


# Expose supported architectures via the intrinsic symbol
cvt_i8_bf16_intrinsic.supported_archs = (
    *Arch.AmpereArchs(),
    *Arch.AdaArchs(),
    *Arch.HopperArchs(),
    *Arch.BlackwellArchs(),
)
cvt_i8_bf16_intrinsic.s26_bf16_supported_archs = (
    Arch.sm_100a,
    Arch.sm_110a,
    Arch.sm_120a,
    Arch.sm_121a,
)
cvt_i4_bf16_intrinsic.supported_archs = (
    Arch.sm_100a,
    Arch.sm_110a,
    Arch.sm_120a,
    Arch.sm_121a,
)
