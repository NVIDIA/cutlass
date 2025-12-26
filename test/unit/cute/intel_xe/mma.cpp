/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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

#include "cutlass_unit_test.h"

#include <cute/tensor.hpp>

#include "../cooperative_gemm_common.hpp"

using namespace cute;

namespace {
  constexpr uint32_t thread_block_size = 128;
  constexpr uint32_t max_vec_bits = 128;
}

template<typename MMAAtom, typename TA, typename TB, typename TC,
         typename ShapeMNK, typename LayoutShape>
void run_mma_test(ShapeMNK shape_mnk, LayoutShape layout_shape) {
  auto tiled_mma = TiledMMA<MMA_Atom<MMAAtom>, Layout<LayoutShape>>{};
  test_cooperative_gemm_col_major_layout<thread_block_size, max_vec_bits, TA, TB, TC>(
    shape_mnk, tiled_mma);
}

TEST(PVC_CuTe_Xe, MMA_XE_8x16x32_S32S8S8S32_TT) {
  run_mma_test<XE_8x16x32_S32S8S8S32_TT, int8_t, int8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_4x16x32_S32S8S8S32_TT) {
  run_mma_test<XE_4x16x32_S32S8S8S32_TT, int8_t, int8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_2x16x32_S32S8S8S32_TT) {
  run_mma_test<XE_2x16x32_S32S8S8S32_TT, int8_t, int8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_4, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_1x16x32_S32S8S8S32_TT) {
  run_mma_test<XE_1x16x32_S32S8S8S32_TT, int8_t, int8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_1, _1, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_8x16x32_S32U8U8S32_TT) {
  run_mma_test<XE_8x16x32_S32U8U8S32_TT, uint8_t, uint8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_4x16x32_S32U8U8S32_TT) {
  run_mma_test<XE_4x16x32_S32U8U8S32_TT, uint8_t, uint8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_2x16x32_S32U8U8S32_TT) {
  run_mma_test<XE_2x16x32_S32U8U8S32_TT, uint8_t, uint8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_4, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_1x16x32_S32U8U8S32_TT) {
  run_mma_test<XE_1x16x32_S32U8U8S32_TT, uint8_t, uint8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_1, _1, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_8x16x16_F32BF16BF16F32_TT) {
  run_mma_test<XE_8x16x16_F32BF16BF16F32_TT, 
               cutlass::bfloat16_t, cutlass::bfloat16_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_4x16x16_F32BF16BF16F32_TT) {
  run_mma_test<XE_4x16x16_F32BF16BF16F32_TT, 
               cutlass::bfloat16_t, cutlass::bfloat16_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_2x16x16_F32BF16BF16F32_TT) {
  run_mma_test<XE_2x16x16_F32BF16BF16F32_TT, 
               cutlass::bfloat16_t, cutlass::bfloat16_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _4, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_1x16x16_F32BF16BF16F32_TT) {
  run_mma_test<XE_1x16x16_F32BF16BF16F32_TT, 
               cutlass::bfloat16_t, cutlass::bfloat16_t, float>(
    Shape<_128, _128, _16>{}, Shape<_1, _1, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_8x16x16_F32F16F16F32_TT) {
  run_mma_test<XE_8x16x16_F32F16F16F32_TT, 
               cutlass::half_t, cutlass::half_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_4x16x16_F32F16F16F32_TT) {
  run_mma_test<XE_4x16x16_F32F16F16F32_TT, 
               cutlass::half_t, cutlass::half_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_2x16x16_F32F16F16F32_TT) {
  run_mma_test<XE_2x16x16_F32F16F16F32_TT, 
               cutlass::half_t, cutlass::half_t, float>(
    Shape<_128, _128, _16>{}, Shape<_4, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_1x16x16_F32F16F16F32_TT) {
  run_mma_test<XE_1x16x16_F32F16F16F32_TT, 
               cutlass::half_t, cutlass::half_t, float>(
    Shape<_128, _128, _16>{}, Shape<_1, _1, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_8x16x8_F32TF32TF32F32_TT) {
  run_mma_test<XE_8x16x8_F32TF32TF32F32_TT, 
               cutlass::tfloat32_t, cutlass::tfloat32_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_4x16x8_F32TF32TF32F32_TT) {
  run_mma_test<XE_4x16x8_F32TF32TF32F32_TT, 
               cutlass::tfloat32_t, cutlass::tfloat32_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_2x16x8_F32TF32TF32F32_TT) {
  run_mma_test<XE_2x16x8_F32TF32TF32F32_TT, 
               cutlass::tfloat32_t, cutlass::tfloat32_t, float>(
    Shape<_128, _128, _16>{}, Shape<_4, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_XE_1x16x8_F32TF32TF32F32_TT) {
  run_mma_test<XE_1x16x8_F32TF32TF32F32_TT, 
               cutlass::tfloat32_t, cutlass::tfloat32_t, float>(
    Shape<_128, _128, _16>{}, Shape<_1, _1, _1>{});
}

TEST(PVC_CuTe_Xe, FMA_XE_UniversalFMA_F32F32F32F32) {
  run_mma_test<UniversalFMA<float, float, float, float>, float, float, float>(
    Shape<_128, _128, _16>{}, Shape<_1, _1, _1>{});
}

#if (IGC_VERSION_MAJOR > 2) || (IGC_VERSION_MAJOR == 2 && IGC_VERSION_MINOR >= 18)

TEST(PVC_CuTe_Xe, MMA_DPAS_S8_8x16) {
  run_mma_test<XE_DPAS_TT<8, int32_t, int8_t>, int8_t, int8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_S8_4x16) {
  run_mma_test<XE_DPAS_TT<4, int32_t, int8_t>, int8_t, int8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_S8_2x16) {
  run_mma_test<XE_DPAS_TT<2, int32_t, int8_t>, int8_t, int8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_4, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_S8_1x16) {
  run_mma_test<XE_DPAS_TT<1, int32_t, int8_t>, int8_t, int8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_1, _1, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_U8_8x16) {
  run_mma_test<XE_DPAS_TT<8, int32_t, uint8_t>, uint8_t, uint8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_U8_4x16) {
  run_mma_test<XE_DPAS_TT<4, int32_t, uint8_t>, uint8_t, uint8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_U8_2x16) {
  run_mma_test<XE_DPAS_TT<2, int32_t, uint8_t>, uint8_t, uint8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_4, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_U8_1x16) {
  run_mma_test<XE_DPAS_TT<1, int32_t, uint8_t>, uint8_t, uint8_t, int32_t>(
    Shape<_128, _128, _16>{}, Shape<_1, _1, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_BF16_8x16) {
  run_mma_test<XE_DPAS_TT<8, float, cutlass::bfloat16_t>, 
               cutlass::bfloat16_t, cutlass::bfloat16_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_BF16_4x16) {
  run_mma_test<XE_DPAS_TT<4, float, cutlass::bfloat16_t>, 
               cutlass::bfloat16_t, cutlass::bfloat16_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_BF16_2x16) {
  run_mma_test<XE_DPAS_TT<2, float, cutlass::bfloat16_t>, 
               cutlass::bfloat16_t, cutlass::bfloat16_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _4, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_BF16_1x16) {
  run_mma_test<XE_DPAS_TT<1, float, cutlass::bfloat16_t>, 
               cutlass::bfloat16_t, cutlass::bfloat16_t, float>(
    Shape<_128, _128, _32>{}, Shape<_1, _1, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_F16_8x16) {
  run_mma_test<XE_DPAS_TT<8, float, cutlass::half_t>, 
               cutlass::half_t, cutlass::half_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_F16_4x16) {
  run_mma_test<XE_DPAS_TT<4, float, cutlass::half_t>, 
               cutlass::half_t, cutlass::half_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_F16_2x16) {
  run_mma_test<XE_DPAS_TT<2, float, cutlass::half_t>, 
               cutlass::half_t, cutlass::half_t, float>(
    Shape<_128, _128, _16>{}, Shape<_4, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_F16_1x16) {
  run_mma_test<XE_DPAS_TT<1, float, cutlass::half_t>, 
               cutlass::half_t, cutlass::half_t, float>(
    Shape<_128, _128, _16>{}, Shape<_1, _1, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_TF32_8x16) {
  run_mma_test<XE_DPAS_TT<8, float, cutlass::tfloat32_t>, 
               cutlass::tfloat32_t, cutlass::tfloat32_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_TF32_4x16) {
  run_mma_test<XE_DPAS_TT<4, float, cutlass::tfloat32_t>, 
               cutlass::tfloat32_t, cutlass::tfloat32_t, float>(
    Shape<_128, _128, _16>{}, Shape<_2, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_TF32_2x16) {
  run_mma_test<XE_DPAS_TT<2, float, cutlass::tfloat32_t>, 
               cutlass::tfloat32_t, cutlass::tfloat32_t, float>(
    Shape<_128, _128, _16>{}, Shape<_4, _2, _1>{});
}

TEST(PVC_CuTe_Xe, MMA_DPAS_TF32_1x16) {
  run_mma_test<XE_DPAS_TT<1, float, cutlass::tfloat32_t>, 
               cutlass::tfloat32_t, cutlass::tfloat32_t, float>(
    Shape<_128, _128, _16>{}, Shape<_1, _1, _1>{});
}

#else

// For the fallback case
#include "cutlass_unit_test.h"

TEST(PVC_CuTe_Xe, MMA_DPAS_TESTS) {
  GTEST_SKIP() << "MMA DPAS tests require IGC version 2.18 or higher. skipped";
}

#endif
