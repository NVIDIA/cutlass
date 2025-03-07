/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
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
    MainloopIntelPVCMixedPrecision<Stages>,
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
  using DispatchPolicy = MainloopIntelPVCMixedPrecision<Stages>;
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

  static_assert(
      sizeof(ElementA) < sizeof(ElementB),
      "MainloopIntelPVCMixedPrecision requires that A is narrower than B.");

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

  static constexpr size_t cacheline_bytes = 64;
  static constexpr auto block_size_w_a = cute::min(SG_K, cacheline_bytes / sizeof(ElementA));
  static constexpr auto block_size_w_b = cute::min(SG_N, cacheline_bytes / sizeof(ElementB));
  static constexpr auto nums_block_w_a = ceil_div(SG_K, block_size_w_a);
  static constexpr auto nums_block_w_b = ceil_div(SG_N, block_size_w_b);
  using PrefetchAThrShape = Shape<Int<ATOM_N /cute::gcd(ATOM_N, nums_block_w_a)>, Int<cute::gcd(ATOM_N, nums_block_w_a)>>;
  using PrefetchBThrShape = Shape<Int<ATOM_M /cute::gcd(ATOM_M, nums_block_w_b)>, Int<cute::gcd(ATOM_M, nums_block_w_b)>>;
  using PrefetchATileSize = decltype(ceil_div(Shape<Int<SG_M>, Int<SG_K>>{},PrefetchAThrShape{}));
  using PrefetchBTileSize = decltype(ceil_div(Shape<Int<SG_K>, Int<SG_N>>{},PrefetchBThrShape{}));
  
  static constexpr uint32_t MaxThreadsPerBlock = size(TiledMma{});
  using traits_load_A = Copy_Traits<GmemTiledCopyA, StrideA>;
  using atom_load_A = Copy_Atom<traits_load_A, ElementA>;

  using traits_load_B = Copy_Traits<GmemTiledCopyB, StrideB>;
  using atom_load_B = Copy_Atom<traits_load_B, ElementB>;

  using XE_Prefetch_A = decltype(cute::detail::prefetch_selector<PrefetchATileSize, ElementA>());
  using XE_Prefetch_B = decltype(cute::detail::prefetch_selector<PrefetchBTileSize, ElementB>());

  using  TensorMKL = decltype(make_tensor(make_gmem_ptr(static_cast<ElementA const*>(nullptr)), make_shape(0,0,0), StrideA{}));   //(m, k)
  using  TensorNKL = decltype(make_tensor(make_gmem_ptr(static_cast<ElementB const*>(nullptr)), make_shape(0,0,0), StrideB{}));   //(n, k)
  
  using CopyThreadShape = Shape<_1, Int<SubgroupSize>>;
  using Copy_A = decltype(make_tiled_copy(atom_load_A{},
                                   Layout<CopyThreadShape>{},
                                   make_layout(shape_div(typename traits_load_A::BlockShape{}, CopyThreadShape{}))));
  
  using Copy_B = decltype(make_tiled_copy(atom_load_B{},
                                   Layout<CopyThreadShape>{},
                                   make_layout(shape_div(typename traits_load_B::BlockShape{}, CopyThreadShape{}))));
  // Host side kernel arguments
  struct Arguments {
    ElementA const* ptr_A;
    StrideA dA;
    ElementB const* ptr_B;
    StrideB dB;
  };

  struct Params {
    Copy_A copy_A;
    Copy_B copy_B;
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

    auto mA_mkl = make_tensor(make_gmem_ptr(static_cast<ElementA const*>(args.ptr_A)),
                              make_layout(make_shape(M, K, L), args.dA));

    auto mB_nkl = make_tensor(make_gmem_ptr(static_cast<ElementB const*>(args.ptr_B)),
                              make_layout(make_shape(N, K, L), args.dB));

    auto tiled_copy_a = make_tiled_copy(atom_load_A{}.with(mA_mkl),
                                   Layout<CopyThreadShape>{},
                                   make_layout(shape_div(typename traits_load_A::BlockShape{}, CopyThreadShape{})));
    auto tiled_copy_b = make_tiled_copy(atom_load_B{}.with(mB_nkl),
                                   Layout<CopyThreadShape>{},
                                   make_layout(shape_div(typename traits_load_B::BlockShape{}, CopyThreadShape{})));

    return Params{tiled_copy_a, tiled_copy_b};
  }

  // Helper functions to select packing for conversion
  template <class SrcType,
            class DstType,
            int Cosize>
  struct select_packing { // Naive packing policy
    static constexpr auto value() {
      return Int<cute::gcd(Cosize, 32 / cute::min(sizeof_bits_v<SrcType>, sizeof_bits_v<DstType>))>{};
    }
  };

  /// Utilities to transform A.
  template <class EngineIn,
            class EngineOut, 
            class LayoutIn,
            class LayoutOut,
            class... Ts>
  CUTLASS_DEVICE
  void transform_A(
    Tensor<EngineIn, LayoutIn> const& tCrA_load, 
    Tensor<EngineOut, LayoutOut>& tCrA_mma) {

    static_assert(is_rmem<EngineIn>::value, "Input tensor for A conversion must come from registers");
    static_assert(is_rmem<EngineOut>::value, "Output tensor for A conversion must come from registers");
    static_assert(cosize_v<LayoutIn> == cosize_v<LayoutOut>);
    static_assert(size_v<LayoutIn> == cosize_v<LayoutIn>);
    static_assert(size_v<LayoutOut> == cosize_v<LayoutOut>);
    using SrcType = typename EngineIn::value_type;
    using DstType = typename EngineOut::value_type;

    auto const& src = tCrA_load(_, _, _);
    auto const& dst = tCrA_mma(_, _, _);
    auto pSrc = raw_pointer_cast(src.data());
    auto pDst = const_cast<DstType*>(raw_pointer_cast(dst.data()));
    constexpr int num_elements = decltype(size(src))::value;

    constexpr int pack = decltype(select_packing<SrcType, DstType, num_elements>::value())::value;
    using Converter = cutlass::NumericArrayConverter<DstType, SrcType, pack, cutlass::FloatRoundStyle::round_to_nearest>;
    using SrcArray = cutlass::Array<SrcType, pack>;
    using DstArray = cutlass::Array<DstType, pack>;
    constexpr int iters = num_elements / pack;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < iters; ++i) {
      SrcArray const* pSrcArr = reinterpret_cast<SrcArray const*>(pSrc) + i;
      DstArray* pDstArr = reinterpret_cast<DstArray*>(pDst) + i;
      *pDstArr = Converter::convert(*pSrcArr);
    }
  }

  /// Perform a subgroup-scoped matrix multiply-accumulate
  template <class FrgTensorD,
    class TensorA,
    class TensorB,
    class FrgTensorC,
    class KTileIterator,
    class ResidueMNK,
    class BlkCoord
  >
  CUTLASS_DEVICE void
  operator() (
      FrgTensorD &accum,
      TensorA gA,
      TensorB gB,
      FrgTensorC const &src_accum,
      KTileIterator k_tile_iter, int k_tile_count,
      ResidueMNK residue_mnk,
      BlkCoord const &blk_coord,
      int const &K_start,
      int thread_idx,
      char *smem_buf,
      Params const& mainloop) 
  {
    static_assert(is_rmem<FrgTensorD>::value, "D tensor must be rmem resident.");
    static_assert(is_rmem<FrgTensorC>::value, "C tensor must be rmem resident.");

    (void)residue_mnk;
    (void)thread_idx;
    (void)smem_buf;

    // Partition the copying of A and B tiles across the threads
    auto thr_copy_A = mainloop.copy_A.get_slice(thread_idx);
    auto thr_copy_B = mainloop.copy_B.get_slice(thread_idx);

    // Instantiate the MMA object and get thread slice
    TiledMma tiled_mma;
    auto sg = syclcompat::get_nd_item<1>().get_sub_group();
    auto first_thread_in_sg_idx = sg.get_group_linear_id() * DispatchPolicy::SubgroupSize;
    auto thr_mma = tiled_mma.get_slice(first_thread_in_sg_idx);

    // Partition
    Tensor tCgA = thr_mma.partition_A(gA);
    Tensor tCgB = thr_mma.partition_B(gB);

    // Create fragments
    Tensor tCrA = make_tensor<ElementB>(mainloop.copy_A.make_fragment_layout(tCgA(_,_,_,0).shape()));
    Tensor tCrB = make_tensor<ElementB>(mainloop.copy_B.make_fragment_layout(tCgB(_,_,_,0).shape()));

    // narrow input fragment
    Tensor tCrA_input = make_tensor<ElementA>(tCrA.shape());

    // Retile registers for copies
    Tensor tArA = thr_copy_A.retile_D(tCrA_input);
    Tensor tBrB = thr_copy_B.retile_D(tCrB);
    
    // Retile global tile for copies
    Tensor tAgA = thr_copy_A.retile_S(tCgA);
    Tensor tBgB = thr_copy_B.retile_S(tCgB);

    static_assert(std::is_same_v<typename decltype(tCrA_input)::value_type, ElementA>);
    static_assert(std::is_same_v<typename decltype(tCrA)::value_type, ElementB>);

  #if CUTLASS_ENABLE_DEBUG_PRINTS
    if (cutlass::thread(LOG_THREAD, LOG_GROUP)) {
        print("======================= A: \n");
        print("  gA : "); print(gA); print("\n");
        print("tCgA : "); print(tCgA); print("\n");
        print("tAgA : "); print(tAgA); print("\n");

        print("=====================  B :\n");
        print("  gB : "); print(gB); print("\n");
        print("tCgB : "); print(tCgB); print("\n");
        print("tBgB : "); print(tBgB); print("\n");

        print("=====================  Config: \n");
        print("  threads per workgroup : "); print(MaxThreadsPerBlock); print("\n");
        print("  SubgroupTileShape : "); print(SubgroupTileShape{}); print("\n");

        print(" PrefetchAThrShape :    ");print(PrefetchAThrShape{});print("\n");
        print(" PrefetchBThrShape :    ");print(PrefetchBThrShape{});print("\n");
        print(" PrefetchATileSize :    ");print(PrefetchATileSize{});print("\n");
        print(" PrefetchBTileSize :    ");print(PrefetchBTileSize{});print("\n");
      }
  #endif

    //
    // Mainloop
    //
    auto [m_idx, n_idx, k_idx, l_idx] = blk_coord;

    const int m_coord = m_idx * BLK_M + (get_sub_group_id() / ATOM_N) * SG_M;
    const int n_coord = n_idx * BLK_N + (get_sub_group_id() % ATOM_N) * SG_N;
    const int l_coord = l_idx;

    const int k_start_idx = crd2idx((*k_tile_iter), make_shape(K_start));
    int prefetch_k = 0;

    Tensor block2d_prefetch_iter_a = XE_Prefetch_A{}.get_pvc_tensor(
                               make_coord(m_coord + (get_sub_group_id() % ATOM_N) / get<1>(PrefetchAThrShape{}) * get<0>(PrefetchATileSize{}),
                                          (k_start_idx + (get_sub_group_id() % ATOM_N) % get<1>(PrefetchAThrShape{})) * get<1>(PrefetchATileSize{}),
                                          l_coord),
                               make_shape(_1{}, _1{}, _1{}));
    auto prefetch_iter_a = append_pvc_tensor<1>(block2d_prefetch_iter_a, k_tile_count, BLK_K);

    Tensor block2d_prefetch_iter_b = XE_Prefetch_B{}.get_pvc_tensor(
                               make_coord((get_sub_group_id() / ATOM_N / get<1>(PrefetchBThrShape{}) + k_start_idx) * get<0>(PrefetchBTileSize{}),
                                           n_coord + (get_sub_group_id() / ATOM_N) % get<1>(PrefetchBThrShape{}) * get<1>(PrefetchBTileSize{}),
                                           l_coord),
                               make_shape(_1{}, _1{}, _1{}));
    auto prefetch_iter_b = append_pvc_tensor<0>(block2d_prefetch_iter_b, k_tile_count, BLK_K);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < DispatchPolicy::Stages; i++, prefetch_k++) {
      if constexpr(cute::detail::has_prefetch<GmemTiledCopyA>) {
        prefetch(mainloop.copy_A, prefetch_iter_a(_,_,_,prefetch_k));
      }
      if constexpr(cute::detail::has_prefetch<GmemTiledCopyB>) {
        prefetch(mainloop.copy_B, prefetch_iter_b(_,_,_,prefetch_k));
      }
    }

    CUTLASS_PRAGMA_UNROLL
    for (int k_tile = 0, k = k_start_idx; k_tile < k_tile_count; ++k_tile, ++k, ++prefetch_k) {
      // Copy gmem to rmem for the first k_tile
      copy(mainloop.copy_A, tAgA(_,_,_,k), tArA);
      copy(mainloop.copy_B, tBgB(_,_,_,k), tBrB);
      transform_A(tCrA_input, tCrA);
      if(prefetch_k < k_tile_count) {
        if constexpr(cute::detail::has_prefetch<GmemTiledCopyA>) {
          prefetch(mainloop.copy_A, prefetch_iter_a(_,_,_,prefetch_k));
        }
        if constexpr(cute::detail::has_prefetch<GmemTiledCopyB>) {
          prefetch(mainloop.copy_B, prefetch_iter_b(_,_,_,prefetch_k));
        } 
      }

      cute::gemm(tiled_mma, tCrA, tCrB, accum);
    }
  }
};


} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
