/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
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
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/

#include "gemm_common.hpp"
#include "utils.hpp"

TEST(PVC_CuTe_Xe, gemm_partition_fragment_abc_bf16_bf16_float_32x128x64) {
  run<gemm_device_partition_fragment_abc<
      32, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N>>(32, 128, 64);
}

TEST(PVC_CuTe_Xe, gemm_partition_fragment_abc_bf16_bf16_float_16x256x64) {
  run<gemm_device_partition_fragment_abc<
      64, 128, 32, 32, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N>>(16, 256, 64);
}

TEST(PVC_CuTe_Xe, gemm_partition_fragment_abc_bf16_bf16_float_64x1024x64) {
  run<gemm_device_partition_fragment_abc<
      32, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N>>(64, 1024, 64);
}

TEST(PVC_CuTe_Xe, gemm_partition_fragment_abc_bf16_bf16_float_128x128x64) {
  run<gemm_device_partition_fragment_abc<
      128, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N>>(128, 128, 64);
}
TEST(PVC_CuTe_Xe, gemm_partition_fragment_abc_bf16_bf16_float_32x1024x1024) {
  run<gemm_device_partition_fragment_abc<
      32, 1024, 32, 64, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N>>(32, 1024, 1024);
}

TEST(PVC_CuTe_Xe, gemm_partition_fragment_abc_bf16_bf16_float_4096x4096x256) {
  run<gemm_device_partition_fragment_abc<
      256, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N>>(4096, 4096, 256);
}

TEST(PVC_CuTe_Xe, gemm_partition_fragment_abc_bf16_bf16_float_1024x2048x512) {
  run<gemm_device_partition_fragment_abc<
      256, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N>>(1024, 2048, 512);
}

TEST(PVC_CuTe_Xe, gemm_partition_fragment_abc_bf16_bf16_float_1026x2048x512) {
  run<gemm_device_partition_fragment_abc<
      256, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N>>(1026, 2048, 512);
}

TEST(PVC_CuTe_Xe, gemm_partition_fragment_abc_bf16_bf16_float_1024x2050x512) {
  run<gemm_device_partition_fragment_abc<
      256, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N>>(1024, 2050, 512);
}

TEST(PVC_CuTe_Xe, gemm_partition_fragment_abc_bf16_bf16_float_1026x2050x256) {
  run<gemm_device_partition_fragment_abc<
      256, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N>>(1026, 2050, 256);
}

TEST(PVC_CuTe_Xe, gemm_partition_fragment_abc_bf16_bf16_float_512x1024x512) {
  run<gemm_device_partition_fragment_abc<
      256, 256, 32, 64, 32, bfloat16_t, bfloat16_t, float, XE_2D_U16x32x32_LD_N,
      XE_2D_U16x32x32_LD_V, XE_2D_U32x8x16_ST_N>>(512, 1024, 512);
}
