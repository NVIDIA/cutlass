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

#include "cutlass/detail/layout.hpp"

#include <cute/tensor.hpp>
#include <sycl/sycl.hpp>
#include <syclcompat.hpp>

#include "cutlass_unit_test.h"
#include "utils.hpp"

using namespace cute;
using namespace cutlass;
using namespace syclcompat::experimental;

#define SUBGROUP_SIZE (16)

template <class MMA, uint32_t wg_tile_m, uint32_t wg_tile_n, uint32_t sg_tile_m,
          uint32_t sg_tile_n, uint32_t sg_tile_k, class TA, class TB, class TC>
void gemm_device(TA const *A, TB const *B, TC *C, uint32_t m, uint32_t n,
                 uint32_t k) {
  using namespace cute;

  // Represent the full tensors
  Tensor mA = make_tensor(make_gmem_ptr(A),
                          make_layout(make_shape(m, k), make_stride(k, 1)));
  Tensor mB = make_tensor(make_gmem_ptr(B),
                          make_layout(make_shape(n, k), make_stride(1, n)));
  Tensor mC = make_tensor(make_gmem_ptr(C),
                          make_layout(make_shape(m, n), make_stride(n, 1)));

  // Get the appropriate blocks for this thread block
  auto cta_coord = make_coord(BlockIdxX(), BlockIdxY(), _); // (m,n,k)

  auto cta_tiler =
      make_shape(Int<wg_tile_m>{}, Int<wg_tile_n>{}, Int<sg_tile_k>{});
  Tensor gA = local_tile(mA, cta_tiler, cta_coord, Step<_1, X, _1>{});
  Tensor gB = local_tile(mB, cta_tiler, cta_coord, Step<X, _1, _1>{});
  Tensor gC = local_tile(mC, cta_tiler, cta_coord, Step<_1, _1, X>{});

  TiledMMA mma = make_tiled_mma(
      MMA_Atom<MMA>{},
      Layout< // Require: subgroup_layout
          Shape<Int<cute::ceil_div(wg_tile_m, sg_tile_m)>,
                Int<cute::ceil_div(wg_tile_n, sg_tile_n)>, _1>>{});

  ThrMMA thrd_mma = mma.get_slice(ThreadIdxX());

  Tensor tgA = thrd_mma.partition_A(gA);
  Tensor fragment_A =
      thrd_mma.make_fragment_A(tgA(_, _, _, 0)); // (MMA, MMA_M, MMA_K)

  Tensor tgB = thrd_mma.partition_B(gB);
  Tensor fragment_B =
      thrd_mma.make_fragment_B(tgB(_, _, _, 0)); // (MMA, MMA_N, MMA_K)

  Tensor tgC = thrd_mma.partition_C(gC);
  Tensor fragment_C = thrd_mma.make_fragment_C(tgC); // (MMA, MMA_M, MMA_N)
  clear(fragment_C);

#define CUTLASS_ENABLE_DEBUG_PRINTS (0)

#undef LOG_THREAD
#define LOG_THREAD (16)

#if CUTLASS_ENABLE_DEBUG_PRINTS
  if (thread(LOG_THREAD)) {
    print("=====================  A :\n");

    print("  mA : ");
    print(mA);
    print("\n");
    print("  gA : ");
    print(gA);
    print("\n");
    print("tgA : ");
    print(tgA);
    print("\n");
    print("fragment_A : ");
    print(fragment_A);
    print("\n\n");
  }
#endif

#if CUTLASS_ENABLE_DEBUG_PRINTS
  if (thread(LOG_THREAD)) {
    print("=====================  B :\n");

    print("  mB : ");
    print(mB);
    print("\n");
    print("  gB : ");
    print(gB);
    print("\n");
    print("tgB : ");
    print(tgB);
    print("\n");
    print("fragment_B : ");
    print(fragment_B);
    print("\n\n");
  }
#endif

#if CUTLASS_ENABLE_DEBUG_PRINTS
  if (thread(LOG_THREAD)) {
    print("=====================  C :\n");

    print("  mC : ");
    print(mC);
    print("\n");
    print("  gC : ");
    print(gC);
    print("\n");
    print("tgC : ");
    print(tgC);
    print("\n");
    print("fragment_C : ");
    print(fragment_C);
    print("\n\n");
  }
#endif

  auto k_tile_max = size<3>(tgA);
  for (int k_tile = 0; k_tile < k_tile_max; ++k_tile) {
    auto kA = tgA(_, _, _, k_tile);
    auto kB = tgB(_, _, _, k_tile);
    // Copy gmem to rmem for k_tile+1 with tA|tB thread-partitioned tensors
    copy(kA, fragment_A);
    copy(kB, fragment_B);

    // Compute gemm on mma-partitioned smem
    cute::gemm(mma, fragment_A, fragment_B, fragment_C);
  }

  copy(fragment_C, tgC);
}

// Setup params for a NT GEMM
template <class MMA, uint32_t wg_tile_m, uint32_t wg_tile_n, uint32_t sg_tile_m,
          uint32_t sg_tile_n, uint32_t sg_tile_k, class TA, class TB, class TC>
void gemm(int m, int n, int k, TA *A, TB *B, TC *C) {
  using namespace cute;

  auto dimBlock = syclcompat::dim3(SUBGROUP_SIZE * (wg_tile_m * wg_tile_n) /
                                   (sg_tile_m * sg_tile_n));
  auto dimGrid = syclcompat::dim3(size(ceil_div(m, wg_tile_m)),
                                  size(ceil_div(n, wg_tile_n)));

  launch<gemm_device<MMA, wg_tile_m, wg_tile_n, sg_tile_m, sg_tile_n, sg_tile_k,
                     TA, TB, TC>>(
      launch_policy{dimGrid, dimBlock,
                    kernel_properties{sycl_exp::sub_group_size<SUBGROUP_SIZE>}},
      A, B, C, m, n, k);
}

template <class MMA, uint32_t wg_tile_m, uint32_t wg_tile_n, uint32_t sg_tile_m,
          uint32_t sg_tile_n, uint32_t sg_tile_k, class TA, class TB, class TC>
void MMA_Test(int m, int n, int k) {
  cutlass::host_vector<TA> h_A(m * k);
  cutlass::host_vector<TB> h_B(n * k);
  cutlass::host_vector<TC> h_C(m * n);

  fill_matrix(h_A);
  fill_matrix(h_B);

  cutlass::device_vector<TA> d_A = h_A;
  cutlass::device_vector<TB> d_B = h_B;
  cutlass::device_vector<TC> d_C = h_C;

  ::gemm<MMA, wg_tile_m, wg_tile_n, sg_tile_m, sg_tile_n, sg_tile_k>(
      m, n, k, d_A.data(), d_B.data(), d_C.data());
  syclcompat::wait();

  h_C = d_C;
  verify(m, n, k, h_A.data(), h_B.data(), h_C.data());
}

TEST(PVC_CuTe_Xe, MMA_XE_8x16x32_S32S8S8S32_TT) {
  MMA_Test<XE_8x16x32_S32S8S8S32_TT, 64, 64, 8, 16, 32, int8_t, int8_t,
           int32_t>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_4x16x32_S32S8S8S32_TT) {
  MMA_Test<XE_4x16x32_S32S8S8S32_TT, 32, 64, 4, 16, 32, int8_t, int8_t,
           int32_t>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_2x16x32_S32S8S8S32_TT) {
  MMA_Test<XE_2x16x32_S32S8S8S32_TT, 16, 64, 2, 16, 32, int8_t, int8_t,
           int32_t>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_1x16x32_S32S8S8S32_TT) {
  MMA_Test<XE_1x16x32_S32S8S8S32_TT, 8, 64, 1, 16, 32, int8_t, int8_t, int32_t>(
      512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_8x16x32_S32U8U8S32_TT) {
  MMA_Test<XE_8x16x32_S32U8U8S32_TT, 64, 64, 8, 16, 32, uint8_t, uint8_t,
           int32_t>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_4x16x32_S32U8U8S32_TT) {
  MMA_Test<XE_4x16x32_S32U8U8S32_TT, 32, 64, 4, 16, 32, uint8_t, uint8_t,
           int32_t>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_2x16x32_S32U8U8S32_TT) {
  MMA_Test<XE_2x16x32_S32U8U8S32_TT, 16, 64, 2, 16, 32, uint8_t, uint8_t,
           int32_t>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_1x16x32_S32U8U8S32_TT) {
  MMA_Test<XE_1x16x32_S32U8U8S32_TT, 8, 64, 1, 16, 32, uint8_t, uint8_t,
           int32_t>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_8x16x16_F32BF16BF16F32_TT) {
  MMA_Test<XE_8x16x16_F32BF16BF16F32_TT, 256, 256, 32, 64, 32, bfloat16_t,
           bfloat16_t, float>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_4x16x16_F32BF16BF16F32_TT) {
  MMA_Test<XE_4x16x16_F32BF16BF16F32_TT, 32, 64, 4, 16, 16, bfloat16_t,
           bfloat16_t, float>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_2x16x16_F32BF16BF16F32_TT) {
  MMA_Test<XE_2x16x16_F32BF16BF16F32_TT, 16, 64, 2, 16, 16, bfloat16_t,
           bfloat16_t, float>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_1x16x16_F32BF16BF16F32_TT) {
  MMA_Test<XE_1x16x16_F32BF16BF16F32_TT, 8, 64, 1, 16, 16, bfloat16_t,
           bfloat16_t, float>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_8x16x16_F32F16F16F32_TT) {
  MMA_Test<XE_8x16x16_F32F16F16F32_TT, 64, 64, 8, 16, 16, half_t, half_t,
           float>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_4x16x16_F32F16F16F32_TT) {
  MMA_Test<XE_4x16x16_F32F16F16F32_TT, 32, 64, 4, 16, 16, half_t, half_t,
           float>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_2x16x16_F32F16F16F32_TT) {
  MMA_Test<XE_2x16x16_F32F16F16F32_TT, 16, 64, 2, 16, 16, half_t, half_t,
           float>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_1x16x16_F32F16F16F32_TT) {
  MMA_Test<XE_1x16x16_F32F16F16F32_TT, 8, 64, 1, 16, 16, half_t, half_t, float>(
      512, 512, 256);
}

TEST(PVC_CuTe_Xe, FMA_XE_UniversalFMA_F32F32F32F32) {
  MMA_Test<UniversalFMA<float, float, float, float>, 64, 64, 8, 16, 16, float,
           float, float>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_1x16x8_F32TF32TF32F32_TT) {
  MMA_Test<XE_1x16x8_F32TF32TF32F32_TT, 64, 64, 8, 16, 16, tfloat32_t,
           tfloat32_t, float>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_2x16x8_F32TF32TF32F32_TT) {
  MMA_Test<XE_2x16x8_F32TF32TF32F32_TT, 64, 64, 8, 16, 16, tfloat32_t,
           tfloat32_t, float>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_4x16x8_F32TF32TF32F32_TT) {
  MMA_Test<XE_4x16x8_F32TF32TF32F32_TT, 64, 64, 8, 16, 16, tfloat32_t,
           tfloat32_t, float>(512, 512, 256);
}

TEST(PVC_CuTe_Xe, MMA_XE_8x16x8_F32TF32TF32F32_TT) {
  MMA_Test<XE_8x16x8_F32TF32TF32F32_TT, 64, 64, 8, 16, 32, tfloat32_t,
           tfloat32_t, float>(512, 512, 256);
}
