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
#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/gemm/dispatch_policy.hpp"

#include "cute/algorithm/functional.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/algorithm/gemm.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {
using namespace cute;
/////////////////////////////////////////////////////////////////////////////////////////////////

template <int Stages, class Schedule, class TileShape_, class ElementA_, class StrideA_, class ElementB_, class StrideB_,
          class TiledMma_, class GmemTiledCopyA_, class SmemLayoutAtomA_, class SmemCopyAtomA_, class TransformA_,
          class GmemTiledCopyB_, class SmemLayoutAtomB_, class SmemCopyAtomB_, class TransformB_>
struct CollectiveMma<MainloopXeL1Staged<Stages, Schedule>, TileShape_, ElementA_, StrideA_, ElementB_, StrideB_, TiledMma_,
                     GmemTiledCopyA_, SmemLayoutAtomA_, SmemCopyAtomA_, TransformA_, GmemTiledCopyB_, SmemLayoutAtomB_,
                     SmemCopyAtomB_, TransformB_> {
  //
  // Type Aliases
  //
  using DispatchPolicy = MainloopXeL1Staged<Stages, Schedule>;
  using WorkgroupTileShape = TileShape_;
  using ElementA = ElementA_;
  using StrideA = cute::remove_pointer_t<StrideA_>;
  using ElementB = ElementB_;
  using StrideB = cute::remove_pointer_t<StrideB_>;
  using TiledMma = TiledMma_;
  using ElementAccumulator = typename TiledMma::ValTypeC;
  using GmemTiledCopyA = GmemTiledCopyA_;
  using GmemTiledCopyB = GmemTiledCopyB_;
  using SmemLayoutAtomA = SmemLayoutAtomA_;
  using SmemLayoutAtomB = SmemLayoutAtomB_;
  using SmemCopyAtomA = SmemCopyAtomA_;
  using SmemCopyAtomB = SmemCopyAtomB_;
  using TransformA = TransformA_;
  using TransformB = TransformB_;
  using ArchTag = typename DispatchPolicy::ArchTag;

  static_assert(std::is_same_v<TransformA, cute::identity>, "Transformation for A is not currently supported on Intel PVC");
  static_assert(std::is_same_v<TransformB, cute::identity>, "Transformation for B is not currently supported on Intel PVC");

  static constexpr int SubgroupSize = DispatchPolicy::SubgroupSize;

  using MmaAtomShape = typename TiledMma::AtomShape_MNK;

  static constexpr int BLK_M = get<0>(WorkgroupTileShape{});
  static constexpr int BLK_N = get<1>(WorkgroupTileShape{});
  static constexpr int BLK_K = get<2>(WorkgroupTileShape{});

  static constexpr int ATOM_M = get<1>(typename TiledMma::ThrLayoutVMNK{}.shape());
  static constexpr int ATOM_N = get<2>(typename TiledMma::ThrLayoutVMNK{}.shape());
  static constexpr int ATOM_K = get<3>(typename TiledMma::ThrLayoutVMNK{}.shape());

  static_assert(BLK_M % TiledMma{}.template tile_size_mnk<0>() == 0, "TiledMma permutation size must match block size.");
  static_assert(BLK_N % TiledMma{}.template tile_size_mnk<1>() == 0, "TiledMma permutation size must match block size.");
  static_assert(BLK_K % TiledMma{}.template tile_size_mnk<2>() == 0, "TiledMma permutation size must match block size.");

  static constexpr int SG_M = ceil_div(BLK_M, ATOM_M);
  static constexpr int SG_N = ceil_div(BLK_N, ATOM_N);
  static constexpr int SG_K = ceil_div(BLK_K, ATOM_K);
  using SubgroupTileShape = Shape<C<SG_M>, C<SG_N>, C<SG_K>>;

  // 32
  static constexpr auto Num_SGs = ATOM_N * ATOM_M * ATOM_K;
  static constexpr uint32_t MaxThreadsPerBlock = size(TiledMma{});

  // Helper to get tensor types
  template<class Element, class Stride>
  using TensorType = decltype(make_tensor(make_gmem_ptr(static_cast<Element const*>(nullptr)),
                                        make_layout(make_shape(int{}, int{}, int{}), Stride{})));

  // Host side kernel arguments
  struct Arguments {
    ElementA const* ptr_A;
    StrideA dA;
    ElementB const* ptr_B;
    StrideB dB;
  };

  struct Params {
    TensorType<ElementA, StrideA> mA_mkl;
    TensorType<ElementB, StrideB> mB_nkl;
  };

  //
  // Methods
  //

  CollectiveMma() = default;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    (void) workspace;

    auto [M,N,K,L] = problem_shape;

    auto mA_mkl = make_tensor(make_gmem_ptr(args.ptr_A),
                                make_layout(make_shape(M, K, L), args.dA));
    auto mB_nkl = make_tensor(make_gmem_ptr(args.ptr_B),
                                make_layout(make_shape(N, K, L), args.dB));
    return Params{mA_mkl, mB_nkl};
  }

  template<class ProblemShape>
  static bool
  can_implement(
      ProblemShape problem_shapes,
      Arguments const& args) {
    constexpr int copy_alignment_bits = 128;
    constexpr int batch_alignment_bits = 512;
    auto problem_shape_MNKL = append<4>(problem_shapes, 1);
    auto [M,N,K,L] = problem_shape_MNKL;

    bool implementable = true;

    constexpr int min_aligned_elements_A = copy_alignment_bits / sizeof_bits<ElementA>::value;
    implementable &= cutlass::detail::check_alignment<min_aligned_elements_A>(cute::make_shape(M,K,L), args.dA);
    constexpr int min_aligned_elements_B = copy_alignment_bits / sizeof_bits<ElementB>::value;
    implementable &= cutlass::detail::check_alignment<min_aligned_elements_B>(cute::make_shape(N,K,L), args.dB);

    if (L > 1) {
      constexpr int min_batch_aligned_elements_A = batch_alignment_bits / sizeof_bits<ElementA>::value;
      implementable &= get<2>(args.dA) % min_batch_aligned_elements_A == 0;
      constexpr int min_batch_aligned_elements_B = batch_alignment_bits / sizeof_bits<ElementB>::value;
      implementable &= get<2>(args.dB) % min_batch_aligned_elements_B == 0;
    }

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for XE 2D copy.\n");
    }

    return implementable;
  }

  /// Perform a subgroup-scoped matrix multiply-accumulate
  template <class FrgTensorD, class TensorA, class TensorB, class FrgTensorC, class KTileIterator, class BlkCoord>
  CUTLASS_DEVICE void operator()(FrgTensorD &accum, TensorA gA, TensorB gB, FrgTensorC const &src_accum,
                                 KTileIterator k_tile_iter, int k_tile_count, BlkCoord const &blk_coord, int const &K_start, int thread_idx,
                                 Params const &mainloop) {
    (void)blk_coord;
    static_assert(is_rmem<FrgTensorD>::value, "D tensor must be rmem resident.");
    static_assert(is_rmem<FrgTensorC>::value, "C tensor must be rmem resident.");

    // Current implementation - Batch indexing
    // Extract the batch index and slice the tensor before passing to make_block_2d_copy_*
    // This is required because the current compiler doesn't properly handle full tensors
    // in the make_block_2d_copy_* functions which makes it little slow.
    //
    // Future implementation - Full tensor support
    // Once there is necessary compiler support, switch to:
    //
    // auto copy_a = get_block_2d_copy_A<GmemTiledCopyA>(TiledMma{}, mainloop.mA_mkl);
    // auto copy_b = get_block_2d_copy_B<GmemTiledCopyB>(TiledMma{}, mainloop.mB_nkl);
    //
    // Required changes in copy_traits_xe_2d.hpp under make_block_2d_copy():
    // 1. tuple_repeat<rank(strides)>(_1{}) → make_tile(_1{}, _1{})
    // 2. Remove x_atom_shape, use elem_scale(ShapeTiler_MN{}, atom_shape) directly
    auto batch_idx = get<3>(blk_coord);
    auto copy_a = get_block_2d_copy_A<GmemTiledCopyA>(TiledMma{}, mainloop.mA_mkl(_,_,batch_idx));
    auto copy_b = get_block_2d_copy_B<GmemTiledCopyB>(TiledMma{}, mainloop.mB_nkl(_,_,batch_idx));

    auto thr_copy_a = copy_a.get_slice(thread_idx);
    auto thr_copy_b = copy_b.get_slice(thread_idx);

    // Instantiate the MMA object and get thread slice
    TiledMma tiled_mma;
    auto thr_mma = tiled_mma.get_slice(thread_idx);

    /* Register fragments for MMA */
    auto tCrA = thr_mma.partition_sg_fragment_A(gA(_,_,0));
    auto tCrB = thr_mma.partition_sg_fragment_B(gB(_,_,0));

    /* Register fragments for copies */
    auto tArA = thr_copy_a.partition_sg_fragment_D(gA(_,_,0));
    auto tBrB = thr_copy_b.partition_sg_fragment_D(gB(_,_,0));

    /* Partition global tensor (proxies) for copies */
    Tensor tAgA = thr_copy_a.partition_S(gA);
    Tensor tBgB = thr_copy_b.partition_S(gB);

    /* Create prefetch TiledCopy instances */
    auto prefetch_a = make_block_2d_prefetch(copy_a);
    auto prefetch_b = make_block_2d_prefetch(copy_b);

    auto thr_prefetch_A = prefetch_a.get_slice(thread_idx);
    auto thr_prefetch_B = prefetch_b.get_slice(thread_idx);

    /* Partition global tensor (proxies) for prefetch */
    auto pAgA = thr_prefetch_A.partition_S(gA);
    auto pBgB = thr_prefetch_B.partition_S(gB);

#if CUTLASS_ENABLE_DEBUG_PRINTS
#define PRINT(x) print(#x ": "); print(x); print("\n");
    if (cute::thread(LOG_THREAD, LOG_GROUP)) {
      print("======================= A: \n");
      PRINT(tAgA);

      PRINT(tCrA);
      PRINT(tArA);
      PRINT(copy_a);

      print("======================= B: \n");
      PRINT(tBgB);

      PRINT(tCrB);
      PRINT(tBrB);
      PRINT(copy_b);
      }
#undef PRINT
#endif

    //
    // Mainloop
    //
    const auto k_start_idx = crd2idx((*k_tile_iter), make_shape(K_start));
    constexpr int barrier_scope = 2;
    int prefetch_k = k_start_idx;

    CUTLASS_PRAGMA_UNROLL
    for (; prefetch_k < DispatchPolicy::Stages; prefetch_k++) {
      prefetch(prefetch_a, pAgA(_, _, _, prefetch_k));
      prefetch(prefetch_b, pBgB(_, _, _, prefetch_k));
    }

    for (int k_tile = k_start_idx; k_tile < k_tile_count + k_start_idx; k_tile++, prefetch_k++) {
      barrier_arrive(barrier_scope);
      // Copy gmem to rmem for the first k_tile
      copy(copy_a, tAgA(_,_,_,k_tile), tArA);
      copy(copy_b, tBgB(_,_,_,k_tile), tBrB);

      if (prefetch_k < k_tile_count) {
        prefetch(prefetch_a, pAgA(_, _, _, prefetch_k));
        prefetch(prefetch_b, pBgB(_, _, _, prefetch_k));
      }

      /* Shuffle data from copy fragments to MMA fragments */
      reorder(tArA, tCrA);
      reorder(tBrB, tCrB);

      cute::gemm(tiled_mma, tCrA, tCrB, accum);
      barrier_wait(barrier_scope);
    }
  }
};

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////

