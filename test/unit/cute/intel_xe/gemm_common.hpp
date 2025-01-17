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

#pragma once

#include "utils.hpp"

using namespace cutlass::detail;
using namespace cute::detail;

template <uint32_t wg_m, uint32_t wg_n, uint32_t sg_m, uint32_t sg_n,
          uint32_t sg_k, class dtype_a, class dtype_b, class dtype_c,
          class traits_a, class traits_b, class traits_c,
          class traits_mma = XE_8x16x16_F32BF16BF16F32_TT,
          class layout_a = cute::LayoutRight,
          class layout_b = cute::LayoutLeft>
struct gemm_device_partition_fragment_abc {
  using TA = dtype_a;
  using TB = dtype_b;
  using TC = dtype_c;

  static constexpr bool is_a_row_major = std::is_same_v<layout_a, cute::LayoutRight>;
  static constexpr bool is_b_row_major = std::is_same_v<layout_b, cute::LayoutLeft>;;

  static constexpr uint32_t wg_tile_m = wg_m;
  static constexpr uint32_t wg_tile_n = wg_n;
  static constexpr uint32_t sg_tile_m = sg_m;
  static constexpr uint32_t sg_tile_n = sg_n;
  static constexpr uint32_t sg_tile_k = sg_k;

  static void func(TA const *A, TB const *B, TC *C, uint32_t m, uint32_t n,
                   uint32_t k) {
    using namespace cute;

    // Represent the full tensors
    Tensor mA = make_tensor(make_gmem_ptr(A), make_shape(m, k), layout_a{});
    Tensor mB = make_tensor(make_gmem_ptr(B), make_shape(n, k), layout_b{});
    Tensor mC = make_tensor(make_gmem_ptr(C), make_shape(m, n), cute::LayoutRight{});

    // Get the appropriate blocks for this thread block
    auto cta_coord = make_coord(BlockIdxX(), BlockIdxY(), _); // (m,n,k)

    auto cta_tiler =
        make_shape(Int<wg_tile_m>{}, Int<wg_tile_n>{}, Int<sg_tile_k>{});
    Tensor gA = local_tile(mA, cta_tiler, cta_coord, Step<_1, X, _1>{});
    Tensor gB = local_tile(mB, cta_tiler, cta_coord, Step<X, _1, _1>{});
    Tensor gC = local_tile(mC, cta_tiler, cta_coord, Step<_1, _1, X>{});

    using traits_load_A = Copy_Traits<traits_a, decltype(mA)>;
    using atom_load_A = Copy_Atom<traits_load_A, TA>;
    auto copy_a = make_xe_2d_copy(
        atom_load_A{}.with(mA), Layout<Shape<_1, Int<SUBGROUP_SIZE>>>{});

    using traits_load_B = Copy_Traits<traits_b, decltype(mB)>;
    using atom_load_B = Copy_Atom<traits_load_B, TB>;
    auto copy_b = make_xe_2d_copy(
        atom_load_B{}.with(mB), Layout<Shape<_1, Int<SUBGROUP_SIZE>>>{});

    using traits_store_C = Copy_Traits<traits_c, decltype(mC)>;
    using atom_store_C = Copy_Atom<traits_store_C, TC>;
    auto copy_c = make_xe_2d_copy(
        atom_store_C{}.with(mC), Layout<Shape<_1, Int<SUBGROUP_SIZE>>>{});

    auto thread_idx = ThreadIdxX();

    auto mma = make_tiled_mma(
        MMA_Atom<traits_mma>{},
        Layout<Shape<Int<cute::ceil_div(wg_tile_m, sg_tile_m)>,
                     Int<cute::ceil_div(wg_tile_n, sg_tile_n)>>>{});
    auto thrd_mma = mma.get_thread_slice(thread_idx);

    Tensor fragment_A = thrd_mma.partition_fragment_A(gA(_, _, 0));
    Tensor fragment_B = thrd_mma.partition_fragment_B(gB(_, _, 0));
    Tensor fragment_C = thrd_mma.partition_fragment_C(gC);


    auto thr_copy_a = copy_a.get_slice(thread_idx);
    auto copy_view_A = thr_copy_a.retile_D(fragment_A);

    auto thr_copy_b = copy_b.get_slice(thread_idx);
    auto copy_view_B = thr_copy_b.retile_D(fragment_B);

    auto thr_copy_c = copy_c.get_slice(thread_idx);
    auto copy_view_C = thr_copy_c.retile_D(fragment_C);

    Tensor mma_A = thr_copy_a.retile_MMA(thrd_mma, fragment_A);
    Tensor mma_B = thr_copy_b.retile_MMA(thrd_mma, fragment_B);

    clear(fragment_C);

#if CUTLASS_ENABLE_DEBUG_PRINTS
    if (thread(LOG_THREAD, LOG_GROUP)) {
      print("=====================  A :\n");
      print("  mA : ");
      print(mA);
      print("\n");
      print("  gA : ");
      print(gA);
      print("\n");
      print("  fragment_A : ");
      print(fragment_A);
      print("\n");
      print("  copy_view_A : ");
      print(copy_view_A);
      print("\n");

      print("=====================  B :\n");
      print("  mB : ");
      print(mB);
      print("\n");
      print("  gB : ");
      print(gB);
      print("\n");
      print("  fragment_B : ");
      print(fragment_B);
      print("\n");
      print("  copy_view_B : ");
      print(copy_view_B);
      print("\n");

      print("=====================  C :\n");
      print("  mC : ");
      print(mC);
      print("\n");
      print("  gC : ");
      print(gC);
      print("\n");
      print("  fragment_C : ");
      print(fragment_C);
      print("\n");
      print("  copy_view_C : ");
      print(copy_view_C);
      print("\n");
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
      Tensor blk_tgA = copy_a.get_pvc_tensor(make_coord(m_coord, k_tile * sg_tile_k, l_coord),
                                             copy_view_A.shape());
      Tensor blk_tgB = copy_b.get_pvc_tensor(make_coord(n_coord, k_tile * sg_tile_k, l_coord),
                                             copy_view_B.shape());

#if CUTLASS_ENABLE_DEBUG_PRINTS
      if (thread(LOG_THREAD, LOG_GROUP) && k_tile == 1) {
        print("blk_tgA : ");
        print(blk_tgA);
        print("\n");
        print("blk_tgB : ");
        print(blk_tgB);
        print("\n");
      }
#endif

      // Copy gmem to rmem for k_tile+1 with tA|tB thread-partitioned tensors
      copy(copy_a, blk_tgA, copy_view_A);
      copy(copy_b, blk_tgB, copy_view_B);

      // Compute gemm on mma-partitioned smem
      cute::gemm(mma, mma_A, mma_B, fragment_C);
    }

    Tensor blk_tgC =
        copy_c.get_pvc_tensor(make_coord(m_coord, n_coord, l_coord), fragment_C.shape());

    copy(copy_c, fragment_C, blk_tgC);
  }
};
