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
  class TiledMMA_,
  class EpilogueTile_,
  class ElementC_,
  class StrideC_,
  class ElementD_,
  class StrideD_,
  class FusionCallbacks_,
  class CopyOpG2R_,
  class CopyOpR2G_
>
class CollectiveEpilogue<
    IntelXeGeneric,
    TiledMMA_,
    EpilogueTile_,
    ElementC_,
    StrideC_,
    ElementD_,
    StrideD_,
    FusionCallbacks_,
    CopyOpG2R_,
    CopyOpR2G_
> {
public:
  //
  // Type Aliases
  //
  using DispatchPolicy = IntelXeXMX16;
  using TiledMMA = TiledMMA_;
  using FusionCallbacks = FusionCallbacks_;
  using ElementC = ElementC_;
  using StrideC = StrideC_;
  using ElementD = ElementD_;
  using StrideD = StrideD_;
  using CopyOpG2R = CopyOpG2R_;
  using CopyOpR2G = CopyOpR2G_;

  using WGTileMNK = decltype(TiledMMA{}.tile_mnk());
  using MMATile = decltype(take<0,2>(typename TiledMMA::AtomShape_MNK{}));

  static auto default_epi_tile_helper() {
    constexpr int R_preferred = 8;
    constexpr int C_preferred = 512 / cute::min(sizeof_bits_v<ElementC>, sizeof_bits_v<ElementD>);    // 1 cache line
    constexpr int R = cute::gcd(R_preferred, get<0>(MMATile{}));
    constexpr int C = cute::gcd(C_preferred, get<1>(MMATile{}));
    return Shape<Int<R>, Int<C>>{};
  }

  using DefaultEpilogueTile = decltype(default_epi_tile_helper());
  using EpilogueTile = replace_void_t<EpilogueTile_, DefaultEpilogueTile>;

  using ThreadEpilogueOp = typename fusion::FusionCallbacksTraits<FusionCallbacks>::Operation;
  using ElementCompute = typename ThreadEpilogueOp::ElementCompute;
  using ElementOutput = ElementD;

  static constexpr int CopyBitsC = cute::min(sizeof(ElementC) * 8, 64);
  static constexpr int CopyBitsD = cute::min(sizeof(ElementD) * 8, 64);
  using DefaultCopyOpG2R =  XE_LOAD_2D<CopyBitsC, cute::gcd(8, get<0>(EpilogueTile{})), cute::gcd(512 / CopyBitsC, get<1>(EpilogueTile{}))>;
  using DefaultCopyOpR2G = XE_STORE_2D<CopyBitsD, cute::gcd(8, get<0>(EpilogueTile{})), cute::gcd(512 / CopyBitsD, get<1>(EpilogueTile{}))>;

  using GmemTiledCopyC = replace_void_t<CopyOpG2R, DefaultCopyOpG2R>;
  using GmemTiledCopyD = replace_void_t<CopyOpR2G, DefaultCopyOpR2G>;

  static constexpr int SubgroupSize = DispatchPolicy::SubgroupSize;

  static_assert(cute::rank(StrideC{}) == 3, "StrideC must be rank-3: [M, N, L]");
  static_assert(cute::rank(StrideD{}) == 3, "StrideD must be rank-3: [M, N, L]");

  using TensorC = decltype(make_tensor(make_gmem_ptr(static_cast<ElementC const*>(nullptr)),
                                       Layout<Shape<int,int,int>, StrideC>{}));

  using TensorD = decltype(make_tensor(make_gmem_ptr(static_cast<ElementD*>(nullptr)),
                                       Layout<Shape<int,int,int>, StrideD>{}));

private:
  constexpr static bool is_source_supported      = !is_void_v<ElementC>;
  constexpr static bool is_destination_supported = !is_void_v<ElementD>;

public:
  struct SharedStorage {
    using FusionSharedStorage = typename FusionCallbacks::SharedStorage;
    FusionSharedStorage thread;
  };
  using TensorStorage = SharedStorage;    // Compatibility with legacy epilogues

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
    TensorC mC;
    TensorD mD;
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

    // Optionally append 1s until problem shape is rank-4, in case it is only rank-3 (MNK)
    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto shape_CD = select<0,1,3>(problem_shape_MNKL);        // (M,N,L)

    // Create C/D tensors here; delay TiledCopy creation to the kernel.
    auto mC = make_tensor(make_gmem_ptr(args.ptr_C), make_layout(shape_CD, args.dC));
    auto mD = make_tensor(make_gmem_ptr(args.ptr_D), make_layout(shape_CD, args.dD));

    return {
      FusionCallbacks::to_underlying_arguments(problem_shape, args.thread, workspace),
      mC,
      mD,
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
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem size doesn't meet the minimum alignment requirements for Xe 2D copy.\n");
    }

    if (!fusion_implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem size doesn't meet the minimum requirements for FusionCallbacks.\n");
    }

    return implementable && fusion_implementable;
  }

  CUTLASS_HOST_DEVICE
  CollectiveEpilogue(Params const& params_, SharedStorage const& shared_storage_)
      : params(params_), fusion_callbacks(params_.thread, shared_storage_.thread) {}

  CUTLASS_DEVICE
  bool
  is_producer_load_needed() const {
    return fusion_callbacks.is_producer_load_needed();
  }

  template<
    class ProblemShapeMNKL,
    class TileShapeMNK, /* compatibility with legacy epilogues */
    class TileCoordMNKL,
    class Accumulator
  >
  CUTLASS_DEVICE void
  operator() (
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK,     /* compatibility with legacy epilogues */
      TileCoordMNKL tile_coord_mnkl,
      Accumulator accumulators,
      TiledMMA,         /* compatibility with legacy epilogues */
      int thread_idx) {

    using namespace cute;

    auto batch_idx = get<3>(tile_coord_mnkl);

    bool is_C_load_needed = is_source_supported && fusion_callbacks.is_C_load_needed();

    auto MN = take<0,2>(problem_shape_mnkl);
    auto cCD = make_identity_tensor(MN);                                                // (m,n)
    auto gCD = local_tile(cCD, take<0,2>(WGTileMNK{}), take<0,2>(tile_coord_mnkl));     // (m_in_wg_tile, n_in_wg_tile)

    auto thr_mma = TiledMMA{}.get_slice(thread_idx);
    auto tCDgCD = thr_mma.partition_C(gCD);                                             // (mma_v,mma_m,mma_n) -> coord

    // Tile accumulator into epilogue tiles.
    auto mma_per_epi = shape_div(EpilogueTile{}, MMATile{});
    auto tiled_acc_layout = group<0,3>(prepend(flat_divide(remove<0>(accumulators.layout()), mma_per_epi),
                                               get<0>(accumulators.layout())));
    auto tiled_acc = make_tensor(accumulators.data(), tiled_acc_layout);                // ((mma_v,mma_m,mma_n),epi_m,epi_n)

    // Tile subgroup's TV coord layout into epilogue tiles.
    auto sg_v_coord = prepend(flat_divide(remove<0>(tCDgCD.layout()), mma_per_epi),
                              get<0>(tCDgCD.layout()));                                 // (mma_v,mma_m,mma_n,epi_m,epi_n) -> coord

    // Copy C/D one epilogue tile at a time. Prepare:
    //   - subgroup-scope TiledCopy objects
    //   - global coordinate tensors, partitioned into epilogue tiles
    //   - copy fragments
    //   - compute fragments (same layout as accumulator)
    // Both copy and compute fragments are SubgroupTensors, holding coordinate mappings
    //   within the epilogue tile.
    auto copy_c = make_block_2d_copy(GmemTiledCopyC{}, params.mC(_,_,batch_idx));
    auto copy_d = make_block_2d_copy(GmemTiledCopyD{}, params.mD(_,_,batch_idx));

    int wi_idx = thread_idx % intel::sg_size;
    auto thr_copy_c = copy_c.get_slice(wi_idx);
    auto thr_copy_d = copy_d.get_slice(wi_idx);

    // Partition global coordinate tensors into epilogue tiles, matching
    //  the work-division from the TiledMMA.
    auto gCD_epi_layout = append(append(make_identity_layout(EpilogueTile{}),
                                        get<3>(sg_v_coord)), get<4>(sg_v_coord));
    auto gCD_epi = make_tensor(tCDgCD.data(), gCD_epi_layout);                          // (m,n,epi_m,epi_n) -> coord

    auto tCgC = thr_copy_c.partition_S(gCD_epi);                                        // (atom_v,atom_m,atom_n,epi_m,epi_n)
    auto tDgD = thr_copy_d.partition_D(gCD_epi);                                        // (atom_v,atom_m,atom_n,epi_m,epi_n)

    auto tCrC = thr_copy_c.partition_sg_fragment_D(gCD_epi(_,_,0,0));                   // (atom_v,atom_m,atom_n,epi_m,epi_n)
    auto tDrD = thr_copy_d.partition_sg_fragment_S(gCD_epi(_,_,0,0));                   // (atom_v,atom_m,atom_n,epi_m,epi_n)

    // Create C subgroup fragments for epilogue compute.
    using AccTVLayout = decltype(thr_mma.partition_sg_fragment_C(gCD).tv_layout());
    auto cd_compute_tv = make_layout(get<0>(AccTVLayout{}),
                                     sg_v_coord(_,_,_,_0{},_0{}));

    using NonVoidElementC = replace_void_t<ElementC, int>;

    auto tCrC_compute_wi = make_fragment_like<NonVoidElementC>(tiled_acc(_,_0{},_0{}));
    auto tCrC_compute = make_subgroup_tensor(tCrC_compute_wi, cd_compute_tv);           // (mma_v,mma_m,mma_n)

    // Calculate residues.
    auto residue_gCD    = MN - gCD(_0{});                                               // (res_m, res_n)
    auto residue_tCDgCD = MN - tCDgCD(_0{});                                            // (res_m, res_n)

    // Pass data to fusions.
    // FIXME: Some Xe visitors expect subgroup tiles/coordinates here and should be updated to accept
    //        workgroup tiles/coordinates, like the NV code. Note that CuTe has no concept of a "subgroup tile."
    //        Work division within a TiledMMA is flexible, and a subgroup's data need not be contiguous.
    //        Instead, visitors should retrieve data coordinates within the WG tile via tDgD.
    constexpr bool RefSrc = true;
    auto cst_args = cutlass::epilogue::fusion::detail::ConsumerStoreArgs {
        problem_shape_mnkl,
        WGTileMNK{},
        tile_coord_mnkl,
        TiledMMA{},
        EpilogueTile{},
        copy_d,
        gCD,
        residue_gCD,
        tDgD,
        residue_tCDgCD,
        tCrC_compute,
        thread_idx,
    };
    auto cst_callbacks = fusion_callbacks.template get_consumer_store_callbacks<RefSrc>(cst_args);

    // Epilogue visitors work on cutlass::Arrays of values for better vectorization.
    // For now, choose array size so there is one array per MMA atom C tile -- later
    //   we might want to make it configurable (FragmentSize in NV code).
    using ElementAccumulator = typename Accumulator::element_type;
    constexpr int ComputeVectorLen = size<0>(Accumulator{});
    auto tiled_acc_v = recast<Array<ElementAccumulator, ComputeVectorLen>>(tiled_acc);

    // Create D subgroup fragments for epilogue compute.
    using FragmentVisit = decltype(cst_callbacks.visit(tiled_acc_v(0), 0, 0, 0));
    using ElementVisit = typename FragmentVisit::Element;

    auto tDrD_compute_wi = make_fragment_like<ElementVisit>(tiled_acc(_,_0{},_0{}));
    auto tDrD_compute = make_subgroup_tensor(tDrD_compute_wi, cd_compute_tv);           // (mma_v,mma_m,mma_n)
    auto tDrD_compute_v = recast<FragmentVisit>(tDrD_compute_wi);

    // Outer loops over epilogue tiles.
    constexpr auto EpiTilesM = size<2>(gCD_epi);
    constexpr auto EpiTilesN = size<3>(gCD_epi);

    cst_callbacks.begin();

    CUTLASS_PRAGMA_UNROLL
    for (int epi_m = 0; epi_m < EpiTilesM; epi_m++) {
      CUTLASS_PRAGMA_UNROLL
      for (int epi_n = 0; epi_n < EpiTilesN; epi_n++) {
        cst_callbacks.begin_loop(epi_m, epi_n);

        // Load C + reorder.
        if constexpr (is_source_supported) {
          if (is_C_load_needed) {
            copy(copy_c, tCgC(_,_,_,epi_m,epi_n), tCrC);
            reorder(tCrC, tCrC_compute);
          }
        }

        cst_callbacks.previsit(epi_m, epi_n, 0, is_C_load_needed);

        // Epilogue computation, one ComputeVectorLen-sized array at a time.
        CUTLASS_PRAGMA_UNROLL
        for (int epi_v = 0; epi_v < size<0>(tiled_acc_v); ++epi_v) {
          tDrD_compute_v(epi_v) = cst_callbacks.visit(tiled_acc_v(epi_v, epi_m, epi_n),
                                                      epi_v, epi_m, epi_n);
        }

        bool last_epi = (epi_m == EpiTilesM - 1) && (epi_n == EpiTilesN - 1);
        cst_callbacks.reduce(nullptr, [=]{}, epi_m, epi_n, last_epi, tDrD_compute_v);

        // Reorder D (possibly including data conversion) and store.
        if constexpr (is_destination_supported) {
          reorder(tDrD_compute, tDrD);
          copy(copy_d, tDrD, tDgD(_,_,_,epi_m,epi_n));
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
