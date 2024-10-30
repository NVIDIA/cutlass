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

#include "cutlass/cutlass.h"
#include "cutlass/gemm/dispatch_policy.hpp"

#include "cute/algorithm/functional.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/algorithm/gemm.hpp"
#include "cute/tensor_predicate.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {
using namespace cute;
/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  int Stages,
  class TileShape_,
  class ElementA_,
  class StrideA_,
  class ElementB_,
  class StrideB_,
  class TiledMma_,
  class GmemTiledCopyA_,
  class SmemLayoutAtomA_,
  class SmemCopyAtomA_,
  class TransformA_,
  class GmemTiledCopyB_,
  class SmemLayoutAtomB_,
  class SmemCopyAtomB_,
  class TransformB_>
struct CollectiveMma<
    MainloopIntelPVC<Stages>,
    TileShape_,
    ElementA_,
    StrideA_,
    ElementB_,
    StrideB_,
    TiledMma_,
    GmemTiledCopyA_,
    SmemLayoutAtomA_,
    SmemCopyAtomA_,
    TransformA_,
    GmemTiledCopyB_,
    SmemLayoutAtomB_,
    SmemCopyAtomB_,
    TransformB_>
{
  //
  // Type Aliases
  //
  using DispatchPolicy = MainloopIntelPVC<Stages>;
  using WorkgroupTileShape = TileShape_;
  using ElementA = ElementA_;
  using StrideA = StrideA_;
  using ElementB = ElementB_;
  using StrideB = StrideB_;
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

  static constexpr int SubgroupSize = DispatchPolicy::SubgroupSize;

  using MmaAtomShape = typename TiledMma::AtomShape_MNK;

  static constexpr auto BLK_M = get<0>(WorkgroupTileShape{});
  static constexpr auto BLK_N = get<1>(WorkgroupTileShape{});
  static constexpr auto BLK_K = get<2>(WorkgroupTileShape{});
  
  static constexpr auto ATOM_M = get<1>(typename TiledMma::ThrLayoutVMNK{}.shape());
  static constexpr auto ATOM_N = get<2>(typename TiledMma::ThrLayoutVMNK{}.shape());
  static constexpr auto ATOM_K = get<3>(typename TiledMma::ThrLayoutVMNK{}.shape());

  static constexpr auto SG_M = ceil_div(BLK_M, ATOM_M);
  static constexpr auto SG_N = ceil_div(BLK_N, ATOM_N);
  static constexpr auto SG_K = ceil_div(BLK_K, ATOM_K);
  using SubgroupTileShape = Shape<decltype(SG_M), decltype(SG_N), decltype(SG_K)>;
  
  static constexpr uint32_t MaxThreadsPerBlock = size(TiledMma{});
  using traits_load_A = Copy_Traits<GmemTiledCopyA>;
  using atom_load_A = Copy_Atom<traits_load_A, ElementA>;
  using XE_Copy_A = decltype(make_tiled_copy(atom_load_A{}
                                            .with(static_cast<ElementA const*>(nullptr), int32_t(0), int32_t(0), int32_t(0)), 
                                            Layout<Shape<_1, Int<SubgroupSize>>>{},
                                            make_layout(make_shape(get<0>(typename traits_load_A::Shape_MN{}),
                                                                   get<1>(typename traits_load_A::Shape_MN{}) / Int<SubgroupSize>{}))));
  using traits_load_B = Copy_Traits<GmemTiledCopyB>;
  using atom_load_B = Copy_Atom<traits_load_B, ElementB>;
  using XE_Copy_B = decltype(make_tiled_copy(atom_load_B{}
                                            .with(static_cast<ElementB const*>(nullptr), int32_t(0), int32_t(0), int32_t(0)),
                                            Layout<Shape<_1, Int<SubgroupSize>>>{},
                                            make_layout(make_shape(get<0>(typename traits_load_B::Shape_MN{}),
                                                                   get<1>(typename traits_load_B::Shape_MN{}) / Int<SubgroupSize>{}))));

  // Host side kernel arguments
  struct Arguments {
    ElementA const* ptr_A;
    StrideA dA;
    ElementB const* ptr_B;
    StrideB dB;
  };

  struct Params {
    XE_Copy_A gmem_tiled_copy_a;
    XE_Copy_B gmem_tiled_copy_b;
  };

  //
  // Methods
  //

  CollectiveMma() = default;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    (void) workspace;

    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M,N,K,L] = problem_shape_MNKL;

    XE_Copy_A copyA = make_tiled_copy(Copy_Atom<Copy_Traits<GmemTiledCopyA>, ElementA>{}.with(args.ptr_A, K, M, K),
                                      Layout<Shape<_1, Int<SubgroupSize>>>{},
                                      make_layout(make_shape(get<0>(typename traits_load_A::Shape_MN{}),
                                                             get<1>(typename traits_load_A::Shape_MN{}) / Int<SubgroupSize>{})));
    XE_Copy_B copyB = make_tiled_copy(Copy_Atom<Copy_Traits<GmemTiledCopyB>, ElementB>{}.with(args.ptr_B, N, K, N),
                                      Layout<Shape<_1, Int<SubgroupSize>>>{},
                                      make_layout(make_shape(get<0>(typename traits_load_B::Shape_MN{}),
                                                             get<1>(typename traits_load_B::Shape_MN{}) / Int<SubgroupSize>{})));
    return Params{copyA, copyB};
  }

  /// Perform a subgroup-scoped matrix multiply-accumulate
  template <
    class FrgTensorD,
    class TensorA,
    class TensorB,
    class FrgTensorC,
    class KTileIterator,
    class ResidueMNK
  >
  CUTLASS_DEVICE void
  operator() (
      FrgTensorD &accum,
      TensorA gA,
      TensorB gB,
      FrgTensorC const &src_accum,
      KTileIterator k_tile_iter, int k_tile_count,
      ResidueMNK residue_mnk,
      int thread_idx,
      char *smem_buf,
      Params const& mainloop) 
  {
    static_assert(is_rmem<FrgTensorD>::value, "D tensor must be rmem resident.");
    static_assert(is_rmem<FrgTensorC>::value, "C tensor must be rmem resident.");

    (void)residue_mnk;
    (void)thread_idx;
    (void)smem_buf;

    // Instantiate the MMA object
    TiledMma tiled_mma;
    auto thread_mma = tiled_mma.get_slice(thread_idx);
    Tensor tCrA_partition = thread_mma.partition_fragment_A(gA(_, _, 0));
    Tensor tCrA = make_tensor(static_cast<decltype(tCrA_partition) &&>(tCrA_partition).data(),
                              tCrA_partition.shape());
    Tensor tCrB_partition = thread_mma.partition_fragment_B(gB(_, _, 0));
    Tensor tCrB = make_tensor(static_cast<decltype(tCrB_partition) &&>(tCrB_partition).data(),
                              make_shape(size<0>(tCrB_partition.shape()),
                                         size<2>(tCrB_partition.shape()),
                                         size<1>(tCrB_partition.shape())));
    // Partition the copying of A and B tiles across the threads
    auto gmem_thr_copy_A = mainloop.gmem_tiled_copy_a.get_slice(thread_idx);
    auto gmem_thr_copy_B = mainloop.gmem_tiled_copy_b.get_slice(thread_idx);

    auto tCrA_copy_view = gmem_thr_copy_A.retile_D(tCrA);
    auto tCrB_copy_view = gmem_thr_copy_B.retile_D(tCrB);

  #if CUTLASS_ENABLE_DEBUG_PRINTS
    if (thread(LOG_THREAD, LOG_GROUP)) {
        print("======================= A: \n");
        print("  gA : "); print(gA); print("\n");
        print("tCrA_copy_view : "); print(tCrA_copy_view); print("\n");
        print("  tCrA : "); print(tCrA); print("\n");

        print("=====================  B :\n");
        print("  gB : "); print(gB); print("\n");
        print("tCrB_copy_view : "); print(tCrB_copy_view); print("\n");
        print("  tCrB : "); print(tCrB); print("\n");

        print("=====================  Config: \n");
        print("  threads per workgroup : "); print(MaxThreadsPerBlock); print("\n");
        print("  SubgroupTileShape : "); print(SubgroupTileShape{}); print("\n");
      }
    #endif

    //
    // Mainloop
    //
    const int m_coord = BlockIdxY() * BLK_M + (get_sub_group_id() / ATOM_N) * SG_M;
    const int n_coord = BlockIdxX() * BLK_N + (get_sub_group_id() % ATOM_N) * SG_N;
    const int l_coord = BlockIdxZ();
    Tensor iter_a = mainloop.gmem_tiled_copy_a.get_pvc_tensor(
      make_coord(m_coord, 0, l_coord), append<4>(tCrA_copy_view.shape(), k_tile_count),
      append<3>(typename XE_Copy_A::Shape_MN{}, BLK_K), seq<0,1,1>{});
    Tensor iter_b = mainloop.gmem_tiled_copy_b.get_pvc_tensor(
      make_coord(0, n_coord, l_coord), append<4>(tCrB_copy_view.shape(), k_tile_count),
      append<3>(typename XE_Copy_B::Shape_MN{}, BLK_K), seq<0,1,0>{});
#pragma unroll
    for (int i = 0; i < DispatchPolicy::Stages; i++) {
      if constexpr(cute::detail::has_prefetch<GmemTiledCopyA>) {
        prefetch(mainloop.gmem_tiled_copy_a, iter_a(_,_,_,i));
      }
      if constexpr(cute::detail::has_prefetch<GmemTiledCopyB>) {
        prefetch(mainloop.gmem_tiled_copy_b, iter_b(_,_,_,i));  
      }
    }
#pragma unroll
    for (int k_tile = 0; k_tile < k_tile_count; ++k_tile) {
      // Copy gmem to rmem for the first k_tile
      copy(mainloop.gmem_tiled_copy_a, iter_a(_,_,_,k_tile), tCrA_copy_view);
      copy(mainloop.gmem_tiled_copy_b, iter_b(_,_,_,k_tile), tCrB_copy_view);
    if(k_tile + DispatchPolicy::Stages < k_tile_count) {
      if constexpr(cute::detail::has_prefetch<GmemTiledCopyA>) {
        prefetch(mainloop.gmem_tiled_copy_a, iter_a(_,_,_,k_tile + DispatchPolicy::Stages));
      }
      if constexpr(cute::detail::has_prefetch<GmemTiledCopyB>) {
        prefetch(mainloop.gmem_tiled_copy_b, iter_b(_,_,_,k_tile + DispatchPolicy::Stages));  
      }
    }
    for (int i = 0; i < SG_K / SubgroupSize; i++) {
      cute::gemm(tiled_mma, accum, tCrA(_, _, i), tCrB(_, i, _), src_accum);
    }
    }
  }
};

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
