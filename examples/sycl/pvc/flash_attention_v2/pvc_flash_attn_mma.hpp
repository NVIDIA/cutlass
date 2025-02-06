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
  class DispatchPolicy,
  class TileShape_,
  class ElementQ_,
  class StrideQ_,
  class ElementK_,
  class StrideK_,
  class ElementV_,
  class StrideV_,
  class TiledMma_,
  class GmemTiledCopyQ_,
  class GmemTiledCopyK_,
  class GmemTiledCopyV_,
  bool CausalMask_>
struct CollectiveMmaAttention {
  static_assert(cutlass::detail::dependent_false<ElementQ_>, "Could not find a mainloop specialization.");
};

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  int Stages,
  class TileShape_,
  class ElementQ_,
  class StrideQ_,
  class ElementK_,
  class StrideK_,
  class ElementV_,
  class StrideV_,
  class TiledMma_,
  class GmemTiledCopyQ_,
  class GmemTiledCopyK_,
  class GmemTiledCopyV_,
  bool CausalMask_>
struct CollectiveMmaAttention<
  MainloopIntelPVC<Stages>,
  TileShape_,
  ElementQ_,
  StrideQ_,
  ElementK_,
  StrideK_,
  ElementV_,
  StrideV_,
  TiledMma_,
  GmemTiledCopyQ_,
  GmemTiledCopyK_,
  GmemTiledCopyV_,
  CausalMask_>
{
  //
  // Type Aliases
  //
  using DispatchPolicy = MainloopIntelPVC<Stages>;
  using WorkgroupTileShape = TileShape_;
  using ElementQ = ElementQ_;
  using StrideQ = StrideQ_;
  using ElementK = ElementK_;
  using StrideK = StrideK_;
  using ElementV = ElementV_;
  using StrideV = StrideV_;
  using TiledMma = TiledMma_;
  using ElementAccumulator = typename TiledMma::ValTypeC;
  using GmemTiledCopyQ = GmemTiledCopyQ_;
  using GmemTiledCopyK = GmemTiledCopyK_;
  using GmemTiledCopyV = GmemTiledCopyV_;
  using ArchTag = typename DispatchPolicy::ArchTag;

  static constexpr bool CausalMask = CausalMask_;
  static constexpr int SubgroupSize = DispatchPolicy::SubgroupSize;

  using MmaAtomShape = typename TiledMma::AtomShape_MNK;

  static constexpr auto BLK_M = get<0>(WorkgroupTileShape{}); // 128
  static constexpr auto BLK_N = get<1>(WorkgroupTileShape{});// 64
  static constexpr auto BLK_K = get<2>(WorkgroupTileShape{});// 32
  
  static constexpr auto ATOM_M = get<1>(typename TiledMma::ThrLayoutVMNK{}.shape()); //4
  static constexpr auto ATOM_N = get<2>(typename TiledMma::ThrLayoutVMNK{}.shape()); //2 
  static constexpr auto ATOM_K = get<3>(typename TiledMma::ThrLayoutVMNK{}.shape()); //1

  static constexpr auto SG_M = ceil_div(BLK_M, ATOM_M); //32
  static constexpr auto SG_N = ceil_div(BLK_N, ATOM_N); //32
  static constexpr auto SG_K = ceil_div(BLK_K, ATOM_K); //32
  using SubgroupTileShape = Shape<decltype(SG_M), decltype(SG_N), decltype(SG_K)>;

  static constexpr size_t cacheline_bytes = 64;
  static constexpr auto block_size_w_a = cute::min(SG_K, cacheline_bytes / sizeof(ElementQ)); //32
  static constexpr auto block_size_w_b = cute::min(SG_N, cacheline_bytes / sizeof(ElementK)); //32
  static constexpr auto nums_block_w_a = ceil_div(SG_K, block_size_w_a); // 1
  static constexpr auto nums_block_w_b = ceil_div(SG_N, block_size_w_b); // 1
  using PrefetchQThrShape = Shape<Int<ATOM_N /cute::gcd(ATOM_N, nums_block_w_a)>, Int<cute::gcd(ATOM_N, nums_block_w_a)>>; //shape<2,1>
  using PrefetchKThrShape = Shape<Int<ATOM_M /cute::gcd(ATOM_M, nums_block_w_b)>, Int<cute::gcd(ATOM_M, nums_block_w_b)>>; //shape <4,1>
  using PrefetchVThrShape = Shape<Int<ATOM_M /cute::gcd(ATOM_M, nums_block_w_b)>, Int<cute::gcd(ATOM_M, nums_block_w_b)>>; //shape <4,1>
  using PrefetchQTileSize = decltype(ceil_div(Shape<Int<SG_M>, Int<SG_K>>{},PrefetchQThrShape{})); //16x32
  using PrefetchKTileSize = decltype(ceil_div(Shape<Int<SG_K>, Int<SG_N>>{},PrefetchKThrShape{})); //8x32
  using PrefetchVTileSize = decltype(ceil_div(Shape<Int<SG_K>, Int<SG_N>>{},PrefetchVThrShape{})); // 8x32
  static constexpr bool is_k_transposed = cute::detail::is_transpose_load<GmemTiledCopyK_>;
  static constexpr uint32_t MaxThreadsPerBlock = size(TiledMma{});
  using traits_load_Q = Copy_Traits<GmemTiledCopyQ, StrideQ>;
  using atom_load_Q = Copy_Atom<traits_load_Q, ElementQ>;
  using XE_Copy_Q = decltype(make_xe_2d_copy(atom_load_Q{}
                                            .with(make_tensor(make_gmem_ptr(static_cast<ElementQ const*>(nullptr)), make_layout(make_shape(0, 0, 0), StrideQ{}))),
                                            Layout<Shape<_1, Int<SubgroupSize>>>{}));
  using traits_load_K = Copy_Traits<GmemTiledCopyK, StrideK>;
  using atom_load_K = Copy_Atom<traits_load_K, ElementK>;
  using XE_Copy_K = decltype(make_xe_2d_copy(atom_load_K{}
                                            .with(make_tensor(make_gmem_ptr(static_cast<ElementK const*>(nullptr)), make_layout(make_shape(0, 0, 0), StrideK{}))),
                                            Layout<Shape<_1, Int<SubgroupSize>>>{}));

  using traits_load_V = Copy_Traits<GmemTiledCopyV, StrideV>;
  using atom_load_V = Copy_Atom<traits_load_V, ElementV>;
  using XE_Copy_V = decltype(make_xe_2d_copy(atom_load_V{}
                                            .with(make_tensor(make_gmem_ptr(static_cast<ElementV const*>(nullptr)), make_layout(make_shape(0, 0, 0), StrideV{}))),
                                            Layout<Shape<_1, Int<SubgroupSize>>>{}));

// The prefetch copy is different from the main copy here we use the subgroup collectively to load the data
  using XE_Prefetch_Q = decltype(cute::detail::prefetch_selector<PrefetchQTileSize, ElementQ, StrideQ, SubgroupSize>(make_tensor(make_gmem_ptr(static_cast<ElementQ const*>(nullptr)), make_layout(make_shape(0, 0, 0), StrideQ{}))));
  using XE_Prefetch_K = decltype(cute::detail::prefetch_selector<PrefetchKTileSize, ElementK, StrideK, SubgroupSize>(make_tensor(make_gmem_ptr(static_cast<ElementK const*>(nullptr)), make_layout(make_shape(0, 0, 0), StrideK{}))));
  using XE_Prefetch_V = decltype(cute::detail::prefetch_selector<PrefetchVTileSize, ElementV, StrideV, SubgroupSize>(make_tensor(make_gmem_ptr(static_cast<ElementV const*>(nullptr)), make_layout(make_shape(0, 0, 0), StrideV{})))); 

  // Host side kernel arguments
  struct Arguments {
    ElementQ const* ptr_Q;
    StrideQ dQ;
    ElementK const* ptr_K;
    StrideK dK;
    ElementV const* ptr_V;
    StrideV dV;
  };

  struct Params {
    XE_Copy_Q gmem_tiled_copy_q;
    XE_Copy_K gmem_tiled_copy_k;
    XE_Copy_V gmem_tiled_copy_v;

    XE_Prefetch_Q gmem_prefetch_q;
    XE_Prefetch_K gmem_prefetch_k;
    XE_Prefetch_V gmem_prefetch_v;
  };

  //
  // Methods
  //

  CollectiveMmaAttention() = default;

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(ProblemShape const& problem_shape, Arguments const& args, void* workspace) {
    (void) workspace;

    auto [batch, num_heads, seq_len, head_size] = problem_shape;

    auto tensorQ = make_tensor(make_gmem_ptr(static_cast<ElementQ const*>(args.ptr_Q)), make_layout(make_shape(seq_len, head_size, batch * num_heads), args.dQ));
    auto tensorK = make_tensor(make_gmem_ptr(static_cast<ElementK const*>(args.ptr_K)), make_layout(make_shape(seq_len, head_size, batch * num_heads), args.dK));
    auto tensorV = make_tensor(make_gmem_ptr(static_cast<ElementV const*>(args.ptr_V)), make_layout(make_shape(head_size, seq_len, batch * num_heads), args.dV));

    XE_Copy_Q copyQ = make_xe_2d_copy(Copy_Atom<Copy_Traits<GmemTiledCopyQ, StrideQ>, ElementQ>{}.with(tensorQ),
                                      Layout<Shape<_1, Int<SubgroupSize>>>{});
    XE_Copy_K copyK = make_xe_2d_copy(Copy_Atom<Copy_Traits<GmemTiledCopyK, StrideK>, ElementK>{}.with(tensorK),
                                      Layout<Shape<_1, Int<SubgroupSize>>>{});
    XE_Copy_V copyV = make_xe_2d_copy(Copy_Atom<Copy_Traits<GmemTiledCopyV, StrideV>, ElementV>{}.with(tensorV),
                                      Layout<Shape<_1, Int<SubgroupSize>>>{});
    
    XE_Prefetch_Q prefetchQ {tensorQ};
    XE_Prefetch_K prefetchK {tensorK};
    XE_Prefetch_V prefetchV {tensorV};
    return Params{copyQ, copyK, copyV, prefetchQ, prefetchK, prefetchV};
  }

  template <
  class TileCoord,
  class FragAccum,
  class TensorQ,
  class TensorK,
  class FragSrc
  >
  CUTLASS_DEVICE void
  mmaQK(
    TileCoord tile_coord,
    FragAccum& accum,
    TensorQ gA,
    TensorK gB,
    FragSrc const &frag_src,
    int const &k_tile_count,
    Params const &params) {

    int thread_idx = static_cast<int>(ThreadIdxX());
    // Instantiate the MMA object
    TiledMma tiled_mma;
    auto thread_mma = tiled_mma.get_slice(thread_idx);
    Tensor tCrA_partition = thread_mma.partition_fragment_A(gA(_, _, 0));
    Tensor tCrB_partition = thread_mma.partition_fragment_B(gB(_, _, 0));
    // Partition the copying of A and B tiles across the threads
    auto gmem_thr_copy_A = params.gmem_tiled_copy_q.get_slice(thread_idx);
    auto gmem_thr_copy_B = params.gmem_tiled_copy_k.get_slice(thread_idx);

    auto tCrA_copy_view = gmem_thr_copy_A.retile_D(tCrA_partition);
    auto tCrB_copy_view = gmem_thr_copy_B.retile_D(tCrB_partition);

    Tensor tCrA = gmem_thr_copy_A.retile_MMA(thread_mma, tCrA_partition);
    Tensor tCrB = gmem_thr_copy_B.retile_MMA(thread_mma, tCrB_partition);

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

        print(" PrefetchQThrShape :    ");print(PrefetchQThrShape{});print("\n");
        print(" PrefetchKThrShape :    ");print(PrefetchKThrShape{});print("\n");
        print(" PrefetchQTileSize :    ");print(PrefetchQTileSize{});print("\n");
        print(" PrefetchKTileSize :    ");print(PrefetchKTileSize{});print("\n");
      }
    #endif

    //
    // Mainloop
    //
    auto [m_coord, n_coord, k_coord, l_coord] = tile_coord;
    Tensor iter_2d_a = params.gmem_tiled_copy_q.get_pvc_tensor(
      make_coord(m_coord, 0, l_coord), tCrA_copy_view.shape());
    Tensor iter_a = append_pvc_tensor<1>(iter_2d_a, k_tile_count, BLK_K);
    Tensor iter_2d_b = params.gmem_tiled_copy_k.get_pvc_tensor(
      make_coord(n_coord, 0, l_coord), tCrB_copy_view.shape());
    Tensor iter_b = append_pvc_tensor<1>(iter_2d_b, k_tile_count, BLK_K);

    CUTLASS_PRAGMA_UNROLL
    for (int k_tile = 0; k_tile < k_tile_count; ++k_tile) {
      // Copy gmem to rmem for the first k_tile
      copy(params.gmem_tiled_copy_q, iter_a(_,_,_,k_tile), tCrA_copy_view);
      copy(params.gmem_tiled_copy_k, iter_b(_,_,_,k_tile), tCrB_copy_view);
      cute::gemm(tiled_mma, accum, tCrA, tCrB, frag_src);
    }
  }

  template <
  class TileCoord,
  class FragAccum,
  class FragP,
  class TensorV,
  class FragSrc
  >
  CUTLASS_DEVICE void
  mmaPV(
    TileCoord tile_coord,
    FragAccum& accum,
    FragP const &tPr,
    TensorV gB,
    FragSrc const &frag_src,
    int const &k_tile_count,
    int const &load_idx,
    Params const &params) {

    int thread_idx = static_cast<int>(ThreadIdxX());
    // Instantiate the MMA object
    TiledMma tiled_mma;
    auto thread_mma = tiled_mma.get_slice(thread_idx);

    Tensor tCrB_partition = thread_mma.partition_fragment_B(gB(_, _, 0));
    // Partition the copying of A and B tiles across the threads
    auto gmem_thr_copy_B = params.gmem_tiled_copy_v.get_slice(thread_idx);

    auto tCrB_copy_view = gmem_thr_copy_B.retile_D(tCrB_partition);

    Tensor tCrB = gmem_thr_copy_B.retile_MMA(thread_mma, tCrB_partition);

  #if CUTLASS_ENABLE_DEBUG_PRINTS
    if (thread(LOG_THREAD, LOG_GROUP)) {
        print("=====================  B :\n");
        print("  gB : "); print(gB); print("\n");
        print("tCrB_copy_view : "); print(tCrB_copy_view); print("\n");
        print("  tCrB : "); print(tCrB); print("\n");

        print("=====================  Config: \n");
        print("  threads per workgroup : "); print(MaxThreadsPerBlock); print("\n");
        print("  SubgroupTileShape : "); print(SubgroupTileShape{}); print("\n");

        print(" PrefetchVThrShape :    ");print(PrefetchVThrShape{});print("\n");
        print(" PrefetchVTileSize :    ");print(PrefetchVTileSize{});print("\n");
      }
  #endif

    //
    // Mainloop
    //
    auto [m_coord, n_coord, k_coord, l_coord] = tile_coord;

    Tensor iter_2d_b = params.gmem_tiled_copy_v.get_pvc_tensor(
      make_coord(n_coord, 0, l_coord), tCrB_copy_view.shape());
    Tensor iter_b = append_pvc_tensor<1>(iter_2d_b, k_tile_count, BLK_K);

    copy(params.gmem_tiled_copy_v, iter_b(_,_,_, load_idx), tCrB_copy_view);

    cute::gemm(tiled_mma, accum, tPr, tCrB, frag_src);
  }

};

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
