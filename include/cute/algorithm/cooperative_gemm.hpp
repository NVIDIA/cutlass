/***************************************************************************************************
 * Copyright (c) 2017 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include <cute/config.hpp>
#include <cute/util/type_traits.hpp>

#include <cute/atom/mma_atom.hpp>

#include <cute/algorithm/functional.hpp>
#include <cute/algorithm/gemm.hpp>

#include <cute/tensor.hpp>

namespace cute
{

//
// Collective Shared-Memory GEMMs
//

template <class... Args,
          class Alpha, class TA, class ALayout, class TB, class BLayout,
          class Beta,  class TC, class CLayout,
          class ALoadTransformOp, class BLoadTransformOp,
          __CUTE_REQUIRES(ALayout::rank == 2 && is_smem<TA>::value &&
                          BLayout::rank == 2 && is_smem<TB>::value &&
                          CLayout::rank == 2 && is_smem<TC>::value)>
CUTE_HOST_DEVICE
void
cooperative_gemm(ThrMMA<Args...> const& thr_mma,
                 Alpha const& alpha,
                 Tensor<TA, ALayout> sA,
                 Tensor<TB, BLayout> sB,
                 Beta  const& beta,
                 Tensor<TC, CLayout> sC,
                 ALoadTransformOp const& sA_load_op /* transforms A values before used in GEMM */,
                 BLoadTransformOp const& sB_load_op /* transforms B values before used in GEMM */)
{
  CUTE_STATIC_ASSERT_V(size<0>(sA) == size<0>(sC));  // AM == CM
  CUTE_STATIC_ASSERT_V(size<0>(sB) == size<1>(sC));  // BN == CN
  CUTE_STATIC_ASSERT_V(size<1>(sA) == size<1>(sB));  // AK == BK

  using TypeA = typename TA::value_type;
  using TypeB = typename TB::value_type;
  using TypeC = typename TC::value_type;

  static_assert(is_same_v<decay_t<invoke_result_t<ALoadTransformOp, TypeA>>, TypeA>,
    "ALoadTransformOp functor must accept and return value of type TA::value_type");
  static_assert(is_same_v<decay_t<invoke_result_t<BLoadTransformOp, TypeB>>, TypeB>,
    "BLoadTransformOp functor must accept and return value of type TB::value_type");

  // Original, static size of the problem
  auto M = size<0>(sC);
  auto N = size<1>(sC);
  auto K = size<1>(sA);

  // Block size of the compute tile
  auto BLK_M = tile_size<0>(thr_mma);
  auto BLK_N = tile_size<1>(thr_mma);
  auto BLK_K = tile_size<2>(thr_mma);

  // Compute the "residues"
  auto m_residue = M - BLK_M * (ceil_div(M, BLK_M) - Int<1>{});  //  (0,BLK_M]
  auto n_residue = N - BLK_N * (ceil_div(N, BLK_N) - Int<1>{});  //  (0,BLK_N]
  auto k_residue = K - BLK_K * (ceil_div(K, BLK_K)           );  // (-BLK_K,0]

  // Shift the origin so k_residue is zeroth tile
  sA.data() = &sA(0,k_residue);
  sB.data() = &sB(0,k_residue);

#if 0
  if (thread0()) {
    printf("%d in BLK_M (%d)\n", int(m_residue), int(BLK_M));
    printf("%d in BLK_N (%d)\n", int(n_residue), int(BLK_N));
    printf("%d in BLK_K (%d)\n", int(k_residue), int(BLK_K));
  }
#endif

  //
  // MMA Partitioning
  //

  // Round the layout extents up to BLK_X
  Tensor rounded_sA = sA.compose(make_shape(ceil_div(M, BLK_M) * BLK_M, ceil_div(K, BLK_K) * BLK_K));
  Tensor rounded_sB = sB.compose(make_shape(ceil_div(N, BLK_N) * BLK_N, ceil_div(K, BLK_K) * BLK_K));
  Tensor rounded_sC = sC.compose(make_shape(ceil_div(M, BLK_M) * BLK_M, ceil_div(N, BLK_N) * BLK_N));

#if 0
  if (thread0()) {
    print("rounded_sA: "); print(rounded_sA); print("\n");
    print("rounded_sB: "); print(rounded_sB); print("\n");
    print("rounded_sC: "); print(rounded_sC); print("\n");
  }
#endif

  // Partition the sA and sB tiles across the threads for the MMA
  Tensor tCsA = thr_mma.partition_A(rounded_sA);                    // (MMA,MMA_M,MMA_K)
  Tensor tCsB = thr_mma.partition_B(rounded_sB);                    // (MMA,MMA_N,MMA_K)
  Tensor tCsC = thr_mma.partition_C(rounded_sC);                    // (MMA,MMA_M,MMA_N)
  // Create register tensors for the MMA to operate on
  Tensor tCrA = thr_mma.make_fragment_A(tCsA);                      // (MMA,MMA_M,MMA_K)
  Tensor tCrB = thr_mma.make_fragment_B(tCsB);                      // (MMA,MMA_N,MMA_K)
  Tensor tCrC = thr_mma.make_fragment_C(tCsC);                      // (MMA,MMA_M,MMA_N)

#if 0
  if (thread0()) {
    print("tCsA: "); print(tCsA); print("\n");
    print("tCsB: "); print(tCsB); print("\n");
    print("tCsC: "); print(tCsC); print("\n");
    print("tCrA: "); print(tCrA); print("\n");
    print("tCrB: "); print(tCrB); print("\n");
    print("tCrC: "); print(tCrC); print("\n");
  }
#endif

  //
  // PREDICATION
  //

  // Allocate the preds for only the MMA-mode of tCsA and tCsB
  Tensor tCpA = make_tensor<bool>(size<0>(tCsA));
  Tensor tCpB = make_tensor<bool>(size<0>(tCsB));

  // Create coordinate tensors on a single compute block for predication
  Tensor cA = make_identity_tensor(make_shape(BLK_M, BLK_K));        // (BLK_M,BLK_K) -> (blk_m,blk_k)
  Tensor cB = make_identity_tensor(make_shape(BLK_N, BLK_K));        // (BLK_M,BLK_K) -> (blk_n,blk_k)

  // Repeat partitioning with thr_mma
  Tensor tCcA = thr_mma.partition_A(cA);                             // (MMA,1,1) -> (blk_m,blk_k)
  Tensor tCcB = thr_mma.partition_B(cB);                             // (MMA,1,1) -> (blk_n,blk_k)

  // Populate the m and n predicates
  CUTE_UNROLL
  for (int i = 0; i < size(tCpA); ++i) {
    tCpA(i) = elem_less(get<0>(tCcA(i)), m_residue);
  }
  CUTE_UNROLL
  for (int i = 0; i < size(tCpB); ++i) {
    tCpB(i) = elem_less(get<0>(tCcB(i)), n_residue);
  }

#if 0
  printf("Thr %d: A(%d,%d):%d  B(%d,%d):%d\n",
         threadIdx.x,
         int(get<0>(tCcA(0))), int(get<1>(tCcA(0))), int(tCpA(0)),
         int(get<0>(tCcB(0))), int(get<1>(tCcB(0))), int(tCpB(0)));
#endif

  //
  // PREFETCH k_block = 0 (with k-predication)
  //

  CUTE_UNROLL
  for (int i = 0; i < size<0>(tCsA); ++i) {                // Copy MMA_I
    if (k_residue == 0 || get<1>(tCcA(i)) >= -k_residue) { // k_block = 0, predicated on k
      CUTE_UNROLL
      for (int m = 0; m < size<1>(tCsA); ++m) {            // Copy MMA_M, predicated on m
        tCrA(i,m,0) = (m_residue == BLK_M || m < size<1>(tCsA)-1 || tCpA(i)) ? sA_load_op(tCsA(i,m,0)) : TypeA{};
      }
    }
  }

  CUTE_UNROLL
  for (int i = 0; i < size<0>(tCsB); ++i) {                // Copy MMA_I
    if (k_residue == 0 || get<1>(tCcB(i)) >= -k_residue) { // k_block = 0, predicated on k
      CUTE_UNROLL
      for (int n = 0; n < size<1>(tCsB); ++n) {            // Copy MMA_N, predicated on n
        tCrB(i,n,0) = (n_residue == BLK_N || n < size<1>(tCsB)-1 || tCpB(i)) ? sB_load_op(tCsB(i,n,0)) : TypeB{};
      }
    }
  }
  //
  // MAINLOOP
  //

  // Clear accumulators
  clear(tCrC);

  constexpr int K_BLOCK_MAX = size<2>(tCrA);

  CUTE_UNROLL
  for (int k_block = 0; k_block < K_BLOCK_MAX; ++k_block)
  {
    // static-if load the next k_block. No k-predication required on these loads.
    if (k_block < K_BLOCK_MAX-1)
    {
      // Load the next k_block
      int k_next = k_block + 1;

      CUTE_UNROLL
      for (int m = 0; m < size<1>(tCsA); ++m) {            // Copy MMA_M
        CUTE_UNROLL
        for (int i = 0; i < size<0>(tCsA); ++i) {          // Copy_if MMA_I predicated on m
          tCrA(i,m,k_next) = (m_residue == BLK_M || m < size<1>(tCsA)-1 || tCpA(i)) ? sA_load_op(tCsA(i,m,k_next)) : TypeA{};
        }
      }

      CUTE_UNROLL
      for (int n = 0; n < size<1>(tCsB); ++n) {            // Copy MMA_N
        CUTE_UNROLL
        for (int i = 0; i < size<0>(tCsB); ++i) {          // Copy MMA_I predicated on n
          tCrB(i,n,k_next) = (n_residue == BLK_N || n < size<1>(tCsB)-1 || tCpB(i)) ? sB_load_op(tCsB(i,n,k_next)) : TypeB{};
        }
      }
    }

    // GEMM on k_block in registers
    gemm(thr_mma, tCrA(_,_,k_block), tCrB(_,_,k_block), tCrC);
  }

  //
  // Epilogue
  //

  Tensor cC   = make_identity_tensor(make_shape(BLK_M, BLK_N));      // (BLK_M,BLK_N) -> (blk_m,blk_n)
  Tensor tCcC = thr_mma.partition_C(cC);                             // (MMA, 1, 1)   -> (blk_m,blk_n)

  const bool isBetaZero = (beta == Beta{});

  // Custom axpby_if for now
  CUTE_UNROLL
  for (int m = 0; m < size<1>(tCsC); ++m)
  {
    CUTE_UNROLL
    for (int n = 0; n < size<2>(tCsC); ++n)
    {
      CUTE_UNROLL
      for (int i = 0; i < size<0>(tCsC); ++i)
      {
        if ((m_residue == BLK_M || m < size<1>(tCrC)-1 || get<0>(tCcC(i)) < m_residue) &&
            (n_residue == BLK_N || n < size<2>(tCrC)-1 || get<1>(tCcC(i)) < n_residue))
        {
          tCsC(i,m,n) = isBetaZero ? alpha * static_cast<TypeC>(tCrC(i,m,n)) : alpha * static_cast<TypeC>(tCrC(i,m,n)) + beta * static_cast<TypeC>(tCsC(i,m,n));
        }
      }
    }
  }
}

template <class... Args,
          class Alpha, class TA, class ALayout, class TB, class BLayout,
          class Beta,  class TC, class CLayout,
          __CUTE_REQUIRES(ALayout::rank == 2 && is_smem<TA>::value &&
                          BLayout::rank == 2 && is_smem<TB>::value &&
                          CLayout::rank == 2 && is_smem<TC>::value)>
CUTE_HOST_DEVICE
void
cooperative_gemm(ThrMMA<Args...> const& thr_mma,
                 Alpha const& alpha,
                 Tensor<TA, ALayout> sA,
                 Tensor<TB, BLayout> sB,
                 Beta  const& beta,
                 Tensor<TC, CLayout> sC)
{
  cooperative_gemm(thr_mma, alpha, sA, sB, beta, sC, identity() /* sA_load_op */, identity() /* sB_load_op */);
}

template <class... Args,
          class Alpha, class TA, class ALayout, class TB, class BLayout,
          class Beta,  class TC, class CLayout,
          class ALoadTransformOp, class BLoadTransformOp,
          __CUTE_REQUIRES(ALayout::rank == 2 && is_smem<TA>::value &&
                          BLayout::rank == 2 && is_smem<TB>::value &&
                          CLayout::rank == 2 && is_smem<TC>::value)>
CUTE_HOST_DEVICE
void
gemm(ThrMMA<Args...> const& thr_mma,
     Alpha const& alpha,
     Tensor<TA, ALayout> sA,
     Tensor<TB, BLayout> sB,
     Beta  const& beta,
     Tensor<TC, CLayout> sC,
     ALoadTransformOp const& sA_load_op /* transforms A values before used in GEMM */,
     BLoadTransformOp const& sB_load_op /* transforms B values before used in GEMM */)
{
  cooperative_gemm(thr_mma, alpha, sA, sB, beta, sC, sA_load_op, sB_load_op);
}

template <class... Args,
          class Alpha, class TA, class ALayout, class TB, class BLayout,
          class Beta,  class TC, class CLayout,
          __CUTE_REQUIRES(ALayout::rank == 2 && is_smem<TA>::value &&
                          BLayout::rank == 2 && is_smem<TB>::value &&
                          CLayout::rank == 2 && is_smem<TC>::value)>
CUTE_HOST_DEVICE
void
gemm(ThrMMA<Args...> const& thr_mma,
     Alpha const& alpha,
     Tensor<TA, ALayout> sA,
     Tensor<TB, BLayout> sB,
     Beta  const& beta,
     Tensor<TC, CLayout> sC)
{
  cooperative_gemm(thr_mma, alpha, sA, sB, beta, sC, identity() /* sA_load_op */, identity() /* sB_load_op */);
}

} // end namespace cute
