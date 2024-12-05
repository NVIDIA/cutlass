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

#include "gemm_utils.hpp"

template <uint32_t wg_m, uint32_t wg_n, uint32_t sg_m, uint32_t sg_n,
          uint32_t sg_k, class dtype_a, class dtype_b, class dtype_c,
          class traits_a, class traits_b, class traits_c,
          class traits_mma = XE_8x16x16_F32BF16BF16F32_TT>
struct gemm_device_col_row {
  using TA = dtype_a;
  using TB = dtype_b;
  using TC = dtype_c;

  static constexpr bool is_a_row_major = false;
  static constexpr bool is_b_row_major = true;

  static constexpr uint32_t wg_tile_m = wg_m;
  static constexpr uint32_t wg_tile_n = wg_n;
  static constexpr uint32_t sg_tile_m = sg_m;
  static constexpr uint32_t sg_tile_n = sg_n;
  static constexpr uint32_t sg_tile_k = sg_k;

  static void func(TA const *A, TB const *B, TC *C, uint32_t m, uint32_t n,
                   uint32_t k) {

    // Represent the full tensors
    Tensor mA = make_tensor(make_gmem_ptr(A),
                            make_layout(make_shape(m, k), make_stride(1, m)));
    Tensor mB = make_tensor(make_gmem_ptr(B),
                            make_layout(make_shape(k, n), make_stride(n, 1)));
    Tensor mC = make_tensor(make_gmem_ptr(C),
                            make_layout(make_shape(m, n), make_stride(n, 1)));

    // Get the appropriate blocks for this thread block
    auto cta_coord = make_coord(BlockIdxX(),
                                BlockIdxY(), _);

    auto cta_tiler =
        make_shape(Int<wg_tile_m>{}, Int<wg_tile_n>{}, Int<sg_tile_k>{});
    Tensor gA = local_tile(mA, cta_tiler, cta_coord, Step<_1, X, _1>{});
    Tensor gB = local_tile(mB, cta_tiler, cta_coord, Step<X, _1, _1>{});
    Tensor gC = local_tile(mC, cta_tiler, cta_coord, Step<_1, _1, X>{});

    using traits_load_A = Copy_Traits<traits_a>;
    using atom_load_A = Copy_Atom<traits_load_A, TA>;
    TiledCopy copy_a = make_tiled_copy(
        atom_load_A{}.with(A, m, k, m), Layout<Shape<Int<SUBGROUP_SIZE>, _1>>{},
        make_layout(make_shape(get<1>(typename traits_load_A::Shape_MN{}),
                               get<0>(typename traits_load_A::Shape_MN{}) / Int<SUBGROUP_SIZE>{})));

    using traits_load_B = Copy_Traits<traits_b>;
    using atom_load_B = Copy_Atom<traits_load_B, TB>;
    TiledCopy copy_b = make_tiled_copy(
        atom_load_B{}.with(B, n, k, n), Layout<Shape<_1, Int<SUBGROUP_SIZE>>>{},
        make_layout(make_shape(get<0>(typename traits_load_B::Shape_MN{}),
                               get<1>(typename traits_load_B::Shape_MN{}) / Int<SUBGROUP_SIZE>{})));

    using traits_store_C = Copy_Traits<traits_c>;
    using atom_store_C = Copy_Atom<traits_store_C, TC>;
    TiledCopy copy_c = make_tiled_copy(
        atom_store_C{}.with(C, n, m, n),
        Layout<Shape<_1, Int<SUBGROUP_SIZE>>>{},
        make_layout(make_shape(get<0>(typename traits_store_C::Shape_MN{}),
                               get<1>(typename traits_store_C::Shape_MN{}) / Int<SUBGROUP_SIZE>{})));

    auto thread_idx = ThreadIdxX();
    auto mma = make_tiled_mma(
        MMA_Atom<traits_mma>{},
        Layout<Shape<Int<cute::ceil_div(wg_tile_m, sg_tile_m)>,
                     Int<cute::ceil_div(wg_tile_n, sg_tile_n)>, _1>>{});
    auto thr_mma = mma.get_thread_slice(thread_idx);
    auto tCrA = thr_mma.partition_fragment_A(gA(_, _, 0));
    auto tCrB = thr_mma.partition_fragment_B(gB(_, _, 0));
    auto tCrC = thr_mma.partition_fragment_C(gC);

    auto tiled_copy_A = make_tiled_copy_A(copy_a, mma);
    auto thr_copy_A = tiled_copy_A.get_thread_slice(thread_idx);
    auto tCrA_copy_view = thr_copy_A.retile_D(tCrA);

    auto tiled_copy_B = make_tiled_copy_B(copy_b, mma);
    auto thr_copy_B = tiled_copy_B.get_thread_slice(thread_idx);
    auto tCrB_copy_view = thr_copy_B.retile_D(tCrB);

    auto tiled_copy_C = make_tiled_copy_C(copy_c, mma);
    auto thr_copy_C = tiled_copy_C.get_thread_slice(thread_idx);
    auto tCrC_copy_view = thr_copy_C.retile_D(tCrC);

    clear(tCrC);

#if CUTLASS_ENABLE_DEBUG_PRINTS
  if (thread(LOG_THREAD, LOG_GROUP)) {
    print("=====================  A :\n");
    print("  mA : "); print(mA); print("\n");
    print("  gA : "); print(gA); print("\n");
    print("tCrA_copy_view : "); print(tCrA_copy_view); print("\n");
    print("  tCrA : "); print(tCrA); print("\n");

    print("=====================  B :\n");
    print("  mB : "); print(mB); print("\n");
    print("  gB : "); print(gB); print("\n");
    print("tCrB_copy_view : "); print(tCrB_copy_view); print("\n");
    print("  tCrB : "); print(tCrB); print("\n");

    print("=====================  C :\n");
    print("  mC : "); print(mC); print("\n");
    print("  gC : "); print(gC); print("\n");
    print("tCrC_copy_view : "); print(tCrC_copy_view); print("\n");
    print("  tCrC : "); print(tCrC); print("\n");
  }
#endif

    auto sg_per_wg_x = wg_tile_n / sg_tile_n;
    const int m_coord = BlockIdxX() * wg_tile_m +
                        (get_sub_group_id() / sg_per_wg_x) * sg_tile_m;
    const int n_coord = BlockIdxY() * wg_tile_n +
                        (get_sub_group_id() % sg_per_wg_x) * sg_tile_n;
    const int l_coord = BlockIdxZ();

    auto k_tile_max = size<2>(gA);
    for (int k_tile = 0; k_tile < k_tile_max; ++k_tile) {
      Tensor blk_tgA = tiled_copy_A.get_pvc_tensor(
          make_coord(k_tile * sg_tile_k, m_coord, l_coord),
          tCrA_copy_view.shape(), typename traits_load_A::Shape_MN{}, seq<1,0>{});
      Tensor blk_tgB = tiled_copy_B.get_pvc_tensor(
          make_coord(k_tile * sg_tile_k, n_coord, l_coord),
          tCrB_copy_view.shape(), typename traits_load_B::Shape_MN{}, seq<1,0>{});

      copy(tiled_copy_A, blk_tgA, tCrA_copy_view);
      copy(tiled_copy_B, blk_tgB, tCrB_copy_view);

      // Compute gemm on mma-partitioned smem
      for (int i = 0; i < sg_tile_k / SUBGROUP_SIZE; i++) {
        gemm(mma, tCrA(_, _, i), tCrB(_, _, i), tCrC);
      }
    }

    Tensor blk_tgC = tiled_copy_C.get_pvc_tensor(
        make_coord(m_coord, n_coord, l_coord), tCrC_copy_view.shape(), 
        typename traits_store_C::Shape_MN{});
    copy(copy_c, tCrC_copy_view, blk_tgC);
  }
};

TEST(PVC_CuTe_Xe, gemm_col_row_bf16_bf16_float_32x128x64) {
  run<gemm_device_col_row<32, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float,
                          XE_2D_U16x16x8_LD_T, XE_2D_U16x16x16_LD_V,
                          XE_2D_U32x8x16_ST_N>>(32, 128, 64);
}

TEST(PVC_CuTe_Xe, gemm_col_row_bf16_bf16_float_16x256x64) {
  run<gemm_device_col_row<16, 128, 16, 128, 32, bfloat16_t, bfloat16_t, float,
                          XE_2D_U16x16x8_LD_T, XE_2D_U16x16x16_LD_V,
                          XE_2D_U32x8x16_ST_N>>(16, 256, 64);
}

TEST(PVC_CuTe_Xe, gemm_col_row_bf16_bf16_float_64x1024x64) {
  run<gemm_device_col_row<32, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float,
                          XE_2D_U16x16x8_LD_T, XE_2D_U16x16x16_LD_V,
                          XE_2D_U32x8x16_ST_N>>(64, 1024, 64);
}

TEST(PVC_CuTe_Xe, gemm_col_row_bf16_bf16_float_128x128x64) {
  run<gemm_device_col_row<128, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float,
                          XE_2D_U16x16x8_LD_T, XE_2D_U16x16x16_LD_V,
                          XE_2D_U32x8x16_ST_N>>(128, 128, 64);
}
TEST(PVC_CuTe_Xe, gemm_col_row_bf16_bf16_float_32x1024x1024) {
  run<gemm_device_col_row<32, 1024, 32, 64, 32, bfloat16_t, bfloat16_t, float,
                          XE_2D_U16x16x8_LD_T, XE_2D_U16x16x16_LD_V,
                          XE_2D_U32x8x16_ST_N>>(32, 1024, 1024);
}

TEST(PVC_CuTe_Xe, gemm_col_row_bf16_bf16_float_4096x4096x256) {
  run<gemm_device_col_row<256, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float,
                          XE_2D_U16x16x8_LD_T, XE_2D_U16x16x16_LD_V,
                          XE_2D_U32x8x16_ST_N>>(4096, 4096, 256);
}

TEST(PVC_CuTe_Xe, gemm_col_row_bf16_bf16_float_1024x2048x512) {
  run<gemm_device_col_row<256, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float,
                          XE_2D_U16x16x8_LD_T, XE_2D_U16x16x16_LD_V,
                          XE_2D_U32x8x16_ST_N>>(1024, 2048, 512);
}

TEST(PVC_CuTe_Xe, gemm_col_row_bf16_bf16_float_1026x2048x512) {
  run<gemm_device_col_row<256, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float,
                          XE_2D_U16x16x8_LD_T, XE_2D_U16x16x16_LD_V,
                          XE_2D_U32x8x16_ST_N>>(1026, 2048, 512);
}

TEST(PVC_CuTe_Xe, gemm_col_row_bf16_bf16_float_1024x2050x512) {
  run<gemm_device_col_row<256, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float,
                          XE_2D_U16x16x8_LD_T, XE_2D_U16x16x16_LD_V,
                          XE_2D_U32x8x16_ST_N>>(1024, 2050, 512);
}

TEST(PVC_CuTe_Xe, gemm_col_row_bf16_bf16_float_1026x2050x256) {
  run<gemm_device_col_row<256, 128, 32, 64, 32, bfloat16_t, bfloat16_t, float,
                          XE_2D_U16x16x8_LD_T, XE_2D_U16x16x16_LD_V,
                          XE_2D_U32x8x16_ST_N>>(1026, 2050, 256);
}

TEST(PVC_CuTe_Xe, gemm_col_row_bf16_bf16_float_512x1024x512) {
  run<gemm_device_col_row<256, 256, 32, 64, 32, bfloat16_t, bfloat16_t, float,
                          XE_2D_U16x16x8_LD_T, XE_2D_U16x16x16_LD_V,
                          XE_2D_U32x8x16_ST_N>>(512, 1024, 512);
}
