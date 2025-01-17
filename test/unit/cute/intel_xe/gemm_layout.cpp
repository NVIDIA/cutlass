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

TEST(PVC_CuTe_Xe, gemm_RowMajor_RowMajor) {
  run<gemm_device_partition_fragment_abc<
      256, 128, 32, 64, 128, bfloat16_t, bfloat16_t, float,
      XE_2D_U16x16x32_LD_N, XE_2D_U16x32x32_LD_V,
      XE_2D_U32x8x16_ST_N, XE_8x16x16_F32BF16BF16F32_TT,
      cute::LayoutRight, cute::LayoutLeft>>(
      512, 256, 1024);
}

TEST(PVC_CuTe_Xe, gemm_RowMajor_ColumnMajor) {
  run<gemm_device_partition_fragment_abc<
      64, 128, 32, 64, 128, bfloat16_t, bfloat16_t, float,
      XE_2D_U16x16x32_LD_N, XE_2D_U16x16x16_LD_T,
      XE_2D_U32x8x16_ST_N, XE_8x16x16_F32BF16BF16F32_TT,
      cute::LayoutRight, cute::LayoutRight>>(
      128, 256, 512);
}

TEST(PVC_CuTe_Xe, gemm_ColumnMajor_RowMajor) {
  run<gemm_device_partition_fragment_abc<
      256, 128, 32, 64, 128, bfloat16_t, bfloat16_t, float,
      XE_2D_U16x16x16_LD_T, XE_2D_U16x32x32_LD_V,
      XE_2D_U32x8x16_ST_N, XE_8x16x16_F32BF16BF16F32_TT,
      cute::LayoutLeft, cute::LayoutLeft>>(
      256, 512, 1024);
}

TEST(PVC_CuTe_Xe, gemm_ColumnMajor_ColumnMajor) {
  run<gemm_device_partition_fragment_abc<
      128, 128, 32, 64, 128, bfloat16_t, bfloat16_t, float,
      XE_2D_U16x16x16_LD_T, XE_2D_U16x16x16_LD_T,
      XE_2D_U32x8x16_ST_N, XE_8x16x16_F32BF16BF16F32_TT,
      cute::LayoutLeft, cute::LayoutRight>>(
      256, 512, 1024);
}
