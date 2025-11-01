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
/*! \file
  \brief Functor performing elementwise operations used by epilogues.
*/

#pragma once

#include <sycl/sycl.hpp>
#include "cutlass/cutlass.h"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_epilogue.hpp"
#include "cutlass/epilogue/collective/detail.hpp"
#include "cutlass/epilogue/fusion/callbacks.hpp"
#include "cutlass/epilogue/fusion/sm90_visitor_tma_warpspecialized.hpp"
#include "cutlass/detail/layout.hpp"

#include "cute/tensor.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace epilogue {
namespace collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class CtaTileMNK_,
  class ElementC_,
  class StrideC_,
  class ElementD_,
  class StrideD_,
  class FusionCallbacks_,
  class CopyOpG2R_,
  class SmemLayoutAtomC_,
  class CopyOpS2R_,
  class CopyOpR2G_,
  class SmemLayoutAtomD_,
  class CopyOpR2S_
>
class CollectiveEpilogue<
    IntelXeXMX16,
    CtaTileMNK_,
    ElementC_,
    StrideC_,
    ElementD_,
    StrideD_,
    FusionCallbacks_,
    CopyOpG2R_,
    SmemLayoutAtomC_,
    CopyOpS2R_,
    CopyOpR2G_,
    SmemLayoutAtomD_,
    CopyOpR2S_
> {
public:
  //
  // Type Aliases
  //
  using DispatchPolicy = IntelXeXMX16;
  using CtaTileMNK = CtaTileMNK_;
  using FusionCallbacks = FusionCallbacks_;
  using ElementC = ElementC_;
  using StrideC = StrideC_;
  using ElementD = ElementD_;
  using StrideD = StrideD_;
  using CopyOpG2R = CopyOpG2R_;
  using SmemLayoutAtomC = SmemLayoutAtomC_;
  using CopyOpS2R = CopyOpS2R_;
  using CopyOpR2G = CopyOpR2G_;
  using SmemLayoutAtomD = SmemLayoutAtomD_;
  using CopyOpR2S = CopyOpR2S_;

  using ThreadEpilogueOp = typename fusion::FusionCallbacksTraits<FusionCallbacks>::Operation;
  using GmemTiledCopyC = conditional_t<cute::is_void_v<CopyOpG2R>, XE_2D_U32x8x16_LD_N, CopyOpG2R>;
  using GmemTiledCopyD = cute::conditional_t<not cute::is_void_v<ElementD> && not cute::is_void_v<CopyOpR2G>,
                                             CopyOpR2G, XE_2D_U32x8x16_ST_N>;
  using ElementOutput = ElementD;
  using ElementCompute = typename ThreadEpilogueOp::ElementCompute;
  using ElementAccumulator = ElementCompute;
  static constexpr int SubgroupSize = DispatchPolicy::SubgroupSize;

  static_assert(cute::rank(CtaTileMNK{}) == 3, "CtaTileMNK must be rank-3: [CTA_M, CTA_N, CTA_K]");
  static_assert(cute::rank(StrideC{}) == 3, "StrideC must be rank-3: [M, N, L]");
  static_assert(cute::rank(StrideD{}) == 3, "StrideD must be rank-3: [M, N, L]");

  static_assert(std::is_same_v<CopyOpS2R, void>, "Copy operation to shared memory is not supported");
  static_assert(std::is_same_v<CopyOpR2S, void>, "Copy operation to shared memory is not supported");
  static_assert(std::is_same_v<SmemLayoutAtomC, void>, "Copy operation to shared memory is not supported");
  static_assert(std::is_same_v<SmemLayoutAtomD, void>, "Copy operation to shared memory is not supported");

  using CopyThreadShape = Shape<_1, Int<SubgroupSize>>;
  
  using Trait_D = Copy_Traits<GmemTiledCopyD, StrideD>;
  using val_layout_store_D = decltype(make_layout(shape_div(typename Trait_D::BlockShape{}, CopyThreadShape{})));
  using XE_Copy_D = decltype(make_tiled_copy(Copy_Atom<Trait_D, ElementD>{}, Layout<CopyThreadShape>{}, val_layout_store_D{}));

private:
  constexpr static bool is_source_supported = not cute::is_void_v<ElementC> && not cute::is_void_v<CopyOpG2R>;
  constexpr static bool is_destination_supported = not cute::is_void_v<ElementD> && not cute::is_void_v<CopyOpR2G>;

  using NonVoidElementC = conditional_t<is_source_supported, ElementC, ElementD>;
  using Trait_C = Copy_Traits<GmemTiledCopyC, StrideC>;
  using NonVoidTrait_C = conditional_t<is_source_supported, Trait_C, Trait_D>;
  using val_layout_load_C = decltype(make_layout(shape_div(typename NonVoidTrait_C::BlockShape{}, CopyThreadShape{})));
  using NonVoidValLayoutLoad_C = conditional_t<is_source_supported, val_layout_load_C, val_layout_store_D>;
  using XE_Copy_C = decltype(make_tiled_copy(Copy_Atom<NonVoidTrait_C, NonVoidElementC>{}, Layout<CopyThreadShape>{}, NonVoidValLayoutLoad_C{}));

  constexpr static bool is_m_major_C = detail::is_m_major<StrideC>();
  constexpr static bool is_m_major_D = detail::is_m_major<StrideD>();

public:

  using EmptyType = cute::tuple<>;
  using SmemCStorage = EmptyType;
  using SmemDStorage = EmptyType;

  struct TensorStorageImpl: cute::tuple<SmemCStorage, SmemDStorage> {
    using FusionStorage = typename FusionCallbacks::SharedStorage;
    FusionStorage thread;
  };

  struct SharedStorage {
    using TensorStorage = TensorStorageImpl;

    TensorStorage tensors;
  };
  using TensorStorage = typename SharedStorage::TensorStorage;

  // Host side epilogue arguments
  struct Arguments {
    typename FusionCallbacks::Arguments thread{};
    ElementC const* ptr_C;
    StrideC dC;
    ElementD* ptr_D;
    StrideD dD;
  };

  // Device side epilogue params
  struct Params {
    typename FusionCallbacks::Params thread{};
    XE_Copy_C xe_load_c;
    XE_Copy_D xe_store_d;
  };

  //
  // Methods
  //

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(
      ProblemShape const& problem_shape,
      Arguments const& args,
      [[maybe_unused]] void* workspace) {
    // Optionally append 1s until problem shape is rank-4 in case its is only rank-3 (MNK)
    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M, N, K, L] = problem_shape_MNKL;

    XE_Copy_C xe_load_c = {};
    if constexpr (is_source_supported) {
      auto mC = make_tensor(make_gmem_ptr(args.ptr_C), make_layout(make_shape(M, N, L), args.dC));
      xe_load_c = {xe_load_c.with(mC)};
    }

    XE_Copy_D xe_store_d = {};
    if constexpr (is_destination_supported) {
      auto mD = make_tensor(make_gmem_ptr(args.ptr_D), make_layout(make_shape(M, N, L), args.dD));
      xe_store_d = {xe_store_d.with(mD)};
    }

    return {
      FusionCallbacks::to_underlying_arguments(problem_shape, args.thread, workspace),
      xe_load_c,
      xe_store_d,
    };
  }

  template <class ProblemShape>
  static size_t
  get_workspace_size(ProblemShape const& problem_shape, Arguments const& args) {
    return 0;
  }

  template <class ProblemShape>
  static cutlass::Status
  initialize_workspace(ProblemShape const& problem_shape, Arguments const& args, void* workspace, cudaStream_t stream, 
    CudaHostAdapter* cuda_adapter = nullptr) {
    return Status::kSuccess;
  }

  template <class ProblemShape>
  CUTLASS_HOST_DEVICE static bool
  can_implement(
      ProblemShape const& problem_shapes,
      Arguments const& args) {
    constexpr int copy_alignment_bits = 128;
    constexpr int batch_alignment_bits = 512;
    auto problem_shape_MNKL = append<4>(problem_shapes, 1);
    auto [M,N,K,L] = problem_shape_MNKL;

    bool implementable = true;
    bool fusion_implementable = true;

    if constexpr (is_destination_supported) {
      constexpr int min_aligned_elements_D = copy_alignment_bits / sizeof_bits<ElementD>::value;
      implementable &= cutlass::detail::check_alignment<min_aligned_elements_D>(cute::make_shape(M,N,L), args.dD);
      if (L > 1) {
        constexpr int min_batch_aligned_elements_D = batch_alignment_bits / sizeof_bits<ElementD>::value;
        implementable &= get<2>(args.dD) % min_batch_aligned_elements_D == 0;
      }
    }

    if constexpr (is_source_supported) {
      constexpr int min_aligned_elements_C = copy_alignment_bits / sizeof_bits<ElementC>::value;
      implementable &= cutlass::detail::check_alignment<min_aligned_elements_C>(cute::make_shape(M,N,L), args.dC);
      if (L > 1) {
        constexpr int min_batch_aligned_elements_C = batch_alignment_bits / sizeof_bits<ElementC>::value;
        implementable &= get<2>(args.dC) % min_batch_aligned_elements_C == 0;
      }
    }

    fusion_implementable = fusion_implementable && FusionCallbacks::can_implement(problem_shape_MNKL, args.thread);

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for XE 2D copy.\n");
    }

    if (!fusion_implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum requirements for FusionCallbacks.\n");
    }

    return implementable && fusion_implementable;
  }

  CUTLASS_HOST_DEVICE
  CollectiveEpilogue(Params const& params_, TensorStorage const& shared_storage_)
      : params(params_), fusion_callbacks(params_.thread, shared_storage_.thread) {}

  CUTLASS_DEVICE
  bool
  is_producer_load_needed() const {
    return fusion_callbacks.is_producer_load_needed();
  }

  template<
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class Accumulator,
    class TiledMma
  >
  CUTLASS_DEVICE void
  operator() (
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_MNK,
      TileCoordMNKL tile_coord_mnkl,
      Accumulator accumulators, 
      TiledMma tiled_mma,
      int thread_idx) {

    (void) tiled_mma;
    using namespace cute;

    static_assert(cute::rank(CtaTileMNK{}) == 3, "CtaTileMNK must be rank-3: [CTA_M, CTA_N, CTA_K]");
    static_assert(cute::rank(StrideC{}) == 3, "StrideC must be rank-3: [M, N, L]");
    static_assert(cute::rank(StrideD{}) == 3, "StrideD must be rank-3: [M, N, L]");

    using MmaAtomShape = typename TiledMma::AtomShape_MNK;
    static constexpr auto BLK_M = get<0>(CtaTileMNK{});
    static constexpr auto BLK_N = get<1>(CtaTileMNK{});
    static constexpr auto BLK_K = get<2>(CtaTileMNK{});
    // static_assert(is_same_v<typename TiledMma::ThrLayoutVMNK, int>, "assertation fail");
    static constexpr auto ATOM_M = get<1>(typename TiledMma::ThrLayoutVMNK{}.shape());
    static constexpr auto ATOM_N = get<2>(typename TiledMma::ThrLayoutVMNK{}.shape());
    static constexpr auto ATOM_K = get<3>(typename TiledMma::ThrLayoutVMNK{}.shape());
    
    static_assert(
      BLK_M % ATOM_M == 0 &&
      BLK_N % ATOM_N == 0 &&
      BLK_K % ATOM_K == 0,
      "expected CTATileMNK to be evenly divided by TiledMma::ThrLayoutVMNK");
    static constexpr auto SG_M = BLK_M / ATOM_M;
    static constexpr auto SG_N = BLK_N / ATOM_N;
    static constexpr auto SG_K = BLK_K / ATOM_K;
    using SubgroupTileShape = Shape<decltype(SG_M), decltype(SG_N), decltype(SG_K)>;

    static constexpr int FragsM = get<0>(SubgroupTileShape{}) / get<0>(MmaAtomShape()); // A frags per sub_group
    static constexpr int FragsN = get<1>(SubgroupTileShape{}) / get<1>(MmaAtomShape()); // B frags per sub_group

    static constexpr int FragmentSize = (get<0>(MmaAtomShape()) * get<1>(MmaAtomShape())) / SubgroupSize;

    // Indexing variables
    auto [M, N, K, L] = problem_shape_mnkl;
    auto [m_coord, n_coord, k_coord, l_coord] = tile_coord_mnkl;
    auto m_sg = get_sub_group_id() / ATOM_N;
    auto n_sg = get_sub_group_id() % ATOM_N;

    auto mn_shape = shape(typename decltype(params.xe_store_d)::Tiler_MN{});

    auto sg_local_m_coord = get_sub_group_id() / ATOM_N;
    auto sg_local_n_coord = get_sub_group_id() % ATOM_N;

    auto sg_m_coord = m_coord * ATOM_M + sg_local_m_coord;
    auto sg_n_coord = n_coord * ATOM_N + sg_local_n_coord;
    auto sg_coord = make_coord(sg_m_coord, sg_n_coord, k_coord, l_coord);

    bool is_C_load_needed = is_source_supported && fusion_callbacks.is_C_load_needed();

    // Represent the full output tensor
    Tensor mD_mnl = cute::get_xe_tensor(make_shape(M,N,L));

    // Tile the output tensor per WG and select the tile for current WG
    Tensor g_wg_D = local_tile(mD_mnl, take<0,2>(CtaTileMNK{}), make_coord(m_coord,n_coord,l_coord));  // (BLK_M,BLK_N)
    
    // Tile the output tensor per SG and select tile for the current SG
    Tensor gD = local_tile(g_wg_D, take<0,2>(SubgroupTileShape{}), make_coord(m_sg,n_sg));            // (SG_M,SG_N)

    auto thread_xe_load_c = params.xe_load_c.get_thread_slice(thread_idx);
    Tensor tCgC = thread_xe_load_c.partition_S(gD);

    auto thread_xe_store_d = params.xe_store_d.get_thread_slice(thread_idx);
    Tensor tCgD = thread_xe_store_d.partition_D(gD);

    Tensor trC = make_tensor<NonVoidElementC>(Shape<Int<FragmentSize>>{});
    Tensor trD_compute = make_tensor<ElementCompute>(Shape<Int<FragmentSize>>{});

    // Because Sm90 uses shared memory, they are not tied to using the same accumulator values
    // for MMA and Epilogue. But because we are operating directly in the accumulators, we need to be
    // sure that we are operating on the same values.
    ThrCopy thread_g2r = params.xe_load_c.get_slice(thread_idx);

    // OOB predication for tile quantization "residue"
    // Absolute coordinate tensors (dynamic)
    Tensor mD_crd = make_identity_tensor(make_shape(M,N));                                                     // (M,N)
    Tensor cD = local_tile(mD_crd, take<0,2>(SubgroupTileShape{}), make_coord(sg_m_coord, sg_n_coord));
    Tensor cD_mn = local_tile(mD_crd, take<0,2>(CtaTileMNK{}), make_coord(m_coord, n_coord));          // (CTA_M,CTA_N)
    Tensor tRS_cD_mn = thread_g2r.partition_S(flat_divide(cD_mn, mn_shape));     // (G2R,G2R_M,G2R_N,EPI_M,EPI_N)

    Tensor tRS_cD = make_coord_tensor(tRS_cD_mn.layout());                          // (G2R,G2R_M,G2R_N,EPI_M,EPI_N)

    // Get the fusion callbacks
    // Arguments passed here relate to sub-group tiles, rather than CTA (work-group) tiles
    constexpr bool RefSrc = true;
    auto residue_mn = make_coord(M, N); //TODO(Codeplay): this is not correct
    auto cst_args = cutlass::epilogue::fusion::detail::ConsumerStoreArgs{
                      problem_shape_mnkl,
                      SubgroupTileShape{},
                      sg_coord,
                      tiled_mma,
                      mn_shape,
                      params.xe_store_d,
                      cD,
                      residue_mn,
                      tRS_cD,
                      residue_mn,
                      trC,
                      thread_idx,
                    };
    auto cst_callbacks = fusion_callbacks.template get_consumer_store_callbacks<RefSrc>(cst_args);

    cst_callbacks.begin();

    auto acc_frag = recast<Array<ElementCompute, FragmentSize>>(accumulators);
    using FragmentVisit = decltype(cst_callbacks.visit(acc_frag(0), 0, 0, 0));
    constexpr bool IsDirectR2S = cute::is_same_v<FragmentVisit, Array<ElementD, FragmentSize>>;
    using RegisterElementD = cute::conditional_t<!IsDirectR2S, ElementCompute, ElementD>;
    auto trD_compute_frag = recast<Array<RegisterElementD, FragmentSize>>(trD_compute);

    Tensor trD = make_tensor<ElementOutput>(Shape<Int<FragmentSize>>{});
    auto trD_frag = recast<Array<ElementOutput, FragmentSize>>(trD);

    constexpr int ValuesLoaded =
      FragsM * FragsN * FragmentSize * SubgroupSize * ATOM_M * ATOM_N * ATOM_K;
    constexpr int MN = get<0>(CtaTileMNK{}) * get<1>(CtaTileMNK{});
    static_assert(ValuesLoaded == MN, "the total elements loaded by all threads should be the same as MxN" );
    
    auto synchronize = [&] () {};
    CUTLASS_PRAGMA_UNROLL
    for (int epi_n = 0; epi_n < FragsN; epi_n++) {
      CUTLASS_PRAGMA_UNROLL
      for (int epi_m = 0; epi_m < FragsM; epi_m++) {
        cst_callbacks.begin_loop(epi_m, epi_n);
        
        //avoid evaluating xe_load_c when ElementC is void during compilation
        if (is_C_load_needed) {
          if constexpr (is_source_supported) {
            copy(params.xe_load_c, tCgC(_, epi_m, epi_n), trC);
          }
        }

        cst_callbacks.previsit(epi_m, epi_n, 0, is_C_load_needed);

        auto acc_frag_mn = acc_frag(_, epi_m, epi_n);

        CUTLASS_PRAGMA_UNROLL
        for (int epi_v = 0; epi_v < size<0>(trD_compute_frag); ++epi_v) {
          trD_compute_frag(epi_v) = cst_callbacks.visit(acc_frag_mn(epi_v), epi_v, epi_m, epi_n);
        }
        cst_callbacks.reduce(nullptr, synchronize, epi_m, epi_n, (epi_m == FragsM - 1 && epi_n == FragsN - 1), trD_compute_frag);
        
        if constexpr (is_destination_supported) {
          CUTLASS_PRAGMA_UNROLL
          for (int i = 0; i < size(trD_compute_frag); ++i) {
            trD_frag(i) = cutlass::NumericArrayConverter<ElementOutput, RegisterElementD, FragmentSize>{}(trD_compute_frag(i));
          }
          copy(params.xe_store_d, trD, tCgD(_, epi_m, epi_n));
        }
        
        cst_callbacks.end_loop(epi_m, epi_n);
      }
    }

    cst_callbacks.end();
  }

private:
  Params const& params;
  FusionCallbacks fusion_callbacks;
};


/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace collective
} // namespace epilogue
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
