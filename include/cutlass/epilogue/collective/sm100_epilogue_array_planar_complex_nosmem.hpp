/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
  \brief Functor performing elementwise operations used by Ptr-Array Planar Complex Gemm epilogue.
*/



#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/epilogue/collective/detail.hpp"
#include "cutlass/epilogue/thread/linear_combination_planar_complex.h"

#include "cute/tensor.hpp"
#include "cute/numeric/numeric_types.hpp"
#include "cutlass/cuda_host_adapter.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace epilogue {
namespace collective {

/// Applies an element wise operation to all elements within the fragment
/// and writes it out to destination storage.
template <
  class EpilogueTile_, // (EPI_TILE_M, EPI_TILE_N)
  class ElementC_,
  class StrideC_,
  class ElementD_,
  class StrideD_,
  class ThreadEpilogueOp_,
  class CopyOpT2R_
>
class CollectiveEpilogue<
    Sm100PtrArrayPlanarComplexNoSmem,
    EpilogueTile_,
    ElementC_,
    StrideC_,
    ElementD_,
    StrideD_,
    ThreadEpilogueOp_,
    CopyOpT2R_
> {
public:
  //
  // Type Aliases
  //
  using DispatchPolicy = Sm100PtrArrayPlanarComplexNoSmem;
  using EpilogueTile = EpilogueTile_;
  // derived types of output thread level operator
  using ThreadEpilogueOp = ThreadEpilogueOp_;
  using ElementOutput = typename ThreadEpilogueOp::ElementOutput;
  using ElementAccumulator = typename ThreadEpilogueOp::ElementAccumulator;
  using ElementCompute = typename ThreadEpilogueOp::ElementCompute;
  using ElementScalar = typename ThreadEpilogueOp::ElementScalar;
  using ElementC = ElementC_;
  using StrideC = StrideC_;
  using InternalStrideC = cute::remove_pointer_t<StrideC>;
  using ElementD = ElementD_;
  using StrideD = StrideD_;
  using InternalStrideD = cute::remove_pointer_t<StrideD>;
  using CopyOpT2R = CopyOpT2R_;

  using GmemTiledCopyC = void;
  using GmemTiledCopyD = void;

  constexpr static int ThreadCount = 128;
  constexpr static uint32_t TmaTransactionBytes = 0;
  constexpr static int FragmentSize = ThreadEpilogueOp::kCount;

  struct SharedStorage {
    struct TensorStorage { };
    struct TensorMapStorage { };
  };
  using TensorStorage = typename SharedStorage::TensorStorage;
  using TensorMapStorage = typename SharedStorage::TensorMapStorage;

  // Planar complex kernels have two accumulator copies for the real and imaginary tensors.
  constexpr static int NumAccumulatorMtxs = 2;

  // Host side epilogue arguments
  struct Arguments {
    typename ThreadEpilogueOp::Params thread{};
    ElementC const** ptr_C_real = nullptr;
    StrideC dC_real{};
    ElementC const** ptr_C_imag = nullptr;
    StrideC dC_imag{};
    ElementD** ptr_D_real = nullptr;
    StrideD dD_real{};
    ElementD** ptr_D_imag = nullptr;
    StrideD dD_imag{};
  };

  // Device side epilogue params
  using Params = Arguments;

  //
  // Methods
  //

  template <class ProblemShape>
  static constexpr Params
  to_underlying_arguments(
      [[maybe_unused]] ProblemShape const& problem_shape,
      Arguments const& args,
      [[maybe_unused]] void* workspace) {
    return args;
  }

  template <class ProblemShape>
  static size_t
  get_workspace_size(ProblemShape const& problem_shape, Arguments const& args, int sm_count) {
    return 0;
  }

  template <class ProblemShape>
  static cutlass::Status
  initialize_workspace(ProblemShape const& problem_shape, Arguments const& args, void* workspace, cudaStream_t stream,
    CudaHostAdapter* cuda_adapter = nullptr) {
    return cutlass::Status::kSuccess;
  }

  template <class ProblemShape>
  static bool
  can_implement(
      [[maybe_unused]] ProblemShape const& problem_shape,
      [[maybe_unused]] Arguments const& args) {
    return true;
  }

  CUTLASS_HOST_DEVICE
  CollectiveEpilogue(Params const& params, SharedStorage&) : params(params) { };

  template<
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class AccEngine, class AccLayout
  >
  CUTLASS_DEVICE void
  operator()(
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK cta_tile_shape_mnk,
      TileCoordMNKL cta_coord_mnkl,
      cute::Tensor<AccEngine, AccLayout> const& accumulators,                                      // (MMA,MMA_M,MMA_N)
      [[maybe_unused]] SharedStorage&) {

    using namespace cute;
    using X = Underscore;

    static_assert(is_tmem<AccEngine>::value, "Accumulator must be TMEM resident.");
    static_assert(rank(ProblemShapeMNKL{}) == 4, "ProblemShapeMNKL must be rank 4");
    static_assert(rank(TileCoordMNKL{}) == 4, "TileCoordMNKL must be rank 4");

    // Separate out problem shape for convenience
    auto M = get<0>(problem_shape_mnkl);
    auto N = get<1>(problem_shape_mnkl);
    auto L = get<3>(problem_shape_mnkl);
    // Batches are managed by using appropriate pointers to C and D matrices
    const int32_t mock_L = 1;
    // Slice to get the tile this CTA is responsible for
    auto [m_coord, n_coord, k_coord, l_coord] = cta_coord_mnkl;
    const int32_t mock_l_coord = 0;

    auto problem_shape_mnl = make_shape(M,N,mock_L);
    auto cta_coord_mnl = make_shape(m_coord, n_coord, mock_l_coord);
    auto cta_tiler = take<0,2>(cta_tile_shape_mnk);

    // Represent the full output tensor, slice to get the tile this CTA is responsible for
    Tensor mC_real = make_tensor(make_gmem_ptr(params.ptr_C_real[l_coord]), problem_shape_mnl, append<3>(params.dC_real,_0{}));      // (M,N,L)
    Tensor mC_imag = make_tensor(make_gmem_ptr(params.ptr_C_imag[l_coord]), problem_shape_mnl, append<3>(params.dC_imag,_0{}));      // (M,N,L)
  
    Tensor mD_real = make_tensor(make_gmem_ptr(params.ptr_D_real[l_coord]), problem_shape_mnl, append<3>(params.dD_real,_0{}));      // (M,N,L)
    Tensor mD_imag = make_tensor(make_gmem_ptr(params.ptr_D_imag[l_coord]), problem_shape_mnl, append<3>(params.dD_imag,_0{}));      // (M,N,L)

    Tensor gC_real = local_tile(mC_real, cta_tiler, cta_coord_mnl);                                                            // (CTA_M,CTA_N)
    Tensor gC_imag = local_tile(mC_imag, cta_tiler, cta_coord_mnl);                                                            // (CTA_M,CTA_N)

    Tensor gD_real = local_tile(mD_real, cta_tiler, cta_coord_mnl);                                                            // (CTA_M,CTA_N)
    Tensor gD_imag = local_tile(mD_imag, cta_tiler, cta_coord_mnl);                                                            // (CTA_M,CTA_N)

    // Partition source and destination tiles according to tmem copy T2R partitioning (tTR_)
    auto tiled_t2r = make_tmem_copy(CopyOpT2R{}, tensor<0>(accumulators));
    auto thread_t2r = tiled_t2r.get_slice(threadIdx.x % size(tiled_t2r));
    Tensor tTR_gC_real   = thread_t2r.partition_D(gC_real);                                                                // (T2R,T2R_M,T2R_N)
    Tensor tTR_gC_imag   = thread_t2r.partition_D(gC_imag);                                                                // (T2R,T2R_M,T2R_N)

    Tensor tTR_gD_real   = thread_t2r.partition_D(gD_real);                                                                // (T2R,T2R_M,T2R_N)
    Tensor tTR_gD_imag   = thread_t2r.partition_D(gD_imag);                                                                // (T2R,T2R_M,T2R_N)

    Tensor tTR_rAcc = make_tensor<ElementAccumulator>(append(shape(tTR_gD_real), Int<NumAccumulatorMtxs>{}));            // (T2R,T2R_M,T2R_N,2)
    Tensor tTR_rD = make_tensor<ElementD>(append(shape(tTR_gD_real), Int<NumAccumulatorMtxs>{}));                        // (T2R,T2R_M,T2R_N,2)

    Tensor tTR_rAcc_frg = recast<ArrayPlanarComplex<ElementAccumulator, FragmentSize>>(coalesce(tTR_rAcc));                          // (EPI_V)
    Tensor tTR_rD_frg   = recast<ArrayPlanarComplex<ElementD, FragmentSize>>(coalesce(tTR_rD));                                      // (EPI_V)

    Tensor coordD = make_identity_tensor(problem_shape_mnl);                                                              // (M,N,L) -> (m,n,l)
    Tensor cD = local_tile(coordD, cta_tiler, cta_coord_mnl);                                                       // (CTA_M,CTA_N) -> (m,n,l)
    Tensor tTR_cD = thread_t2r.partition_D(cD);                                                                 // (T2R,T2R_M,T2R_N) -> (m,n,l)

    // 1. Load accumulators into register from tmem
    auto accumulators_real = accumulators(_,_,_,0);
    auto accumulators_imag = accumulators(_,_,_,1);
    Tensor tAcc_real = accumulators_real(make_coord(_,_),_0{},_0{});                                                          // (CTA_M,CTA_N)
    Tensor tAcc_imag = accumulators_imag(make_coord(_,_),_0{},_0{});                                                          // (CTA_M,CTA_N)
    Tensor tTR_tAcc_real = thread_t2r.partition_S(tAcc_real);                                                 // (T2R,T2R_M,T2R_N,EPI_M,EPI_N)
    Tensor tTR_tAcc_imag = thread_t2r.partition_S(tAcc_imag);                                                 // (T2R,T2R_M,T2R_N,EPI_M,EPI_N)

    // tmem -> rmem
    copy(tiled_t2r, tTR_tAcc_real, tTR_rAcc(_,_,_,0));
    copy(tiled_t2r, tTR_tAcc_imag, tTR_rAcc(_,_,_,1));

    // 2. Apply element-wise operation and store to gmem
    ThreadEpilogueOp epilogue_op{params.thread};
    // source is needed
    if (epilogue_op.is_source_needed()) {
      Tensor tTR_rC = make_tensor<ElementC>(append(shape(tTR_gC_real), Int<NumAccumulatorMtxs>{}));                   // (T2R,T2R_M,T2R_N,2)
      Tensor tTR_rC_frg = recast<ArrayPlanarComplex<ElementC, FragmentSize>>(coalesce(tTR_rC));                                   // (EPI_V)

      auto tTR_rC_real = tTR_rC(_,_,_,0);
      auto tTR_rC_imag = tTR_rC(_,_,_,1);

      for( int i = 0; i < size(tTR_gC_real); ++i) {
        if (elem_less(tTR_cD(i), problem_shape_mnl)) {
          tTR_rC_real(i) = tTR_gC_real(i);
          tTR_rC_imag(i) = tTR_gC_imag(i);
        }
      }

      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size(tTR_rAcc_frg); ++i) { 
        tTR_rD_frg(i) = epilogue_op(tTR_rAcc_frg(i), tTR_rC_frg(i));
      }
    }
    // source is not needed, avoid load
    else {
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size(tTR_rAcc_frg); ++i) {
        tTR_rD_frg(i) = epilogue_op(tTR_rAcc_frg(i));
      }
    }

    auto tTR_rD_real = tTR_rD(_,_,_,0);
    auto tTR_rD_imag = tTR_rD(_,_,_,1);

    for( int i = 0; i < size(tTR_gD_real); ++i) {
      if (elem_less(tTR_cD(i), problem_shape_mnl)) {
        tTR_gD_real(i) = tTR_rD_real(i);
        tTR_gD_imag(i) = tTR_rD_imag(i);
      }
    }
  }

protected:
  Params const& params;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// For sm100 kernels requiring warp specialized epilogues
template <
  class EpilogueTile_, // (EPI_TILE_M, EPI_TILE_N)
  class ElementC_,
  class StrideC_,
  class ElementD_,
  class StrideD_,
  class ThreadEpilogueOp_,
  class CopyOpT2R_,
  class AlignmentC,
  class AlignmentD
>
class CollectiveEpilogue<
    Sm100PtrArrayPlanarComplexNoSmemWarpSpecialized,
    EpilogueTile_,
    ElementC_,
    StrideC_,
    ElementD_,
    StrideD_,
    ThreadEpilogueOp_,
    CopyOpT2R_,
    AlignmentC,
    AlignmentD
> : public detail::Sm100TmaWarpSpecializedAdapter<CollectiveEpilogue<
      Sm100PtrArrayPlanarComplexNoSmem,
      EpilogueTile_,
      ElementC_,
      StrideC_,
      ElementD_,
      StrideD_,
      ThreadEpilogueOp_,
      CopyOpT2R_>>
{
public:
  // ctor inheritance
  using detail::Sm100TmaWarpSpecializedAdapter<CollectiveEpilogue<
      Sm100PtrArrayPlanarComplexNoSmem,
      EpilogueTile_,
      ElementC_,
      StrideC_,
      ElementD_,
      StrideD_,
      ThreadEpilogueOp_,
      CopyOpT2R_>>::Sm100TmaWarpSpecializedAdapter;
};

/////////////////////////////////////////////////////////////////////////////////////////////////




} // namespace collective
} // namespace epilogue
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
