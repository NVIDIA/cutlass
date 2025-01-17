/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *this list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 *LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/

#include "gemm_common.hpp"
#include "utils.hpp"

TEST(PVC_CuTe_Xe, gemm_float_bf16_bf16_float) {
  run<gemm_device_partition_fragment_abc<
      32, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N, XE_8x16x16_F32BF16BF16F32_TT>>(32, 128, 64);
}

TEST(PVC_CuTe_Xe, gemm_int32_int8_int8_int32) {
  run<gemm_device_partition_fragment_abc<
      64, 128, 32, 32, 32, int8_t, int8_t, int32_t, XE_2D_U8x32x32_LD_N,
      XE_2D_U8x32x32_LD_V, XE_2D_U32x8x16_ST_N, XE_8x16x32_S32S8S8S32_TT>>(16, 256, 64);
}

TEST(PVC_CuTe_Xe, gemm_int32_uint8_uint8_int32) {
  run<gemm_device_partition_fragment_abc<
      32, 128, 32, 64, 32, uint8_t, uint8_t, int32_t, XE_2D_U8x32x32_LD_N,
      XE_2D_U8x32x32_LD_V, XE_2D_U32x8x16_ST_N, XE_8x16x32_S32U8U8S32_TT>>(32, 128, 64);
}

TEST(PVC_CuTe_Xe, gemm_float_fp16_fp16_float) {
  run<gemm_device_partition_fragment_abc<
      64, 128, 32, 32, 32, half_t, half_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N, XE_8x16x16_F32F16F16F32_TT>>(16, 256, 64);
}

// TODO: don't know how to enable this
#if 0
TEST(PVC_CuTe_Xe, gemm_float_tf32_tf32_float_XE_1x16x8_F32TF32TF32F32_TT) {
  run<gemm_device_partition_fragment_abc<
      64, 64, 64, 64, 128, tfloat32_t, tfloat32_t, float, XE_2D_TF32x32x16_LD_N,
      XE_2D_U32x32x16_LD_N, XE_2D_U32x1x16_ST_N, XE_1x16x8_F32TF32TF32F32_TT>>(256, 512, 1024);
}
#endif

TEST(PVC_CuTe_Xe, gemm_float_tf32_tf32_float_XE_2x16x8_F32TF32TF32F32_TT) {
  run<gemm_device_partition_fragment_abc<
      64, 64, 64, 64, 128, tfloat32_t, tfloat32_t, float, XE_2D_TF32x32x16_LD_N,
      XE_2D_U32x32x16_LD_N, XE_2D_U32x2x16_ST_N, XE_2x16x8_F32TF32TF32F32_TT>>(256, 512, 1024);
}

TEST(PVC_CuTe_Xe, gemm_float_tf32_tf32_float_XE_4x16x8_F32TF32TF32F32_TT) {
  run<gemm_device_partition_fragment_abc<
      64, 64, 64, 64, 128, tfloat32_t, tfloat32_t, float, XE_2D_TF32x32x16_LD_N,
      XE_2D_U32x32x16_LD_N, XE_2D_U32x4x16_ST_N, XE_4x16x8_F32TF32TF32F32_TT>>(256, 512, 1024);
}

TEST(PVC_CuTe_Xe, gemm_float_tf32_tf32_float_XE_8x16x8_F32TF32TF32F32_TT) {
  run<gemm_device_partition_fragment_abc<
      64, 64, 64, 64, 128, tfloat32_t, tfloat32_t, float, XE_2D_TF32x32x16_LD_N,
      XE_2D_U32x32x16_LD_N, XE_2D_U32x8x16_ST_N, XE_8x16x8_F32TF32TF32F32_TT>>(256, 512, 1024);
}
