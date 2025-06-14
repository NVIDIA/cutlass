/***************************************************************************************************
 * Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
  \brief Functor performing elementwise operations used by Ptr-Array and Grouped GEMM epilogues.
*/



#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/epilogue/collective/detail.hpp"

#include "cute/tensor.hpp"
#include "cute/numeric/numeric_types.hpp"
#include "cutlass/cuda_host_adapter.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace epilogue {
namespace collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

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
    Sm100PtrArrayNoSmem,
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
  using DispatchPolicy = Sm100PtrArrayNoSmem;
  using EpilogueTile = EpilogueTile_;
  // derived types of output thread level operator
  using ThreadEpilogueOp = ThreadEpilogueOp_;
  using ElementOutput = typename ThreadEpilogueOp::ElementOutput;
  using ElementAccumulator = typename ThreadEpilogueOp::ElementAccumulator;
  using ElementCompute = typename ThreadEpilogueOp::ElementCompute;
  using ElementScalar = ElementCompute;
  using ElementBias = typename detail::IsThreadEpilogueOpWithBias<ThreadEpilogueOp>::type;
  using ElementC = typename ThreadEpilogueOp::ElementC;
  using StrideC = StrideC_;
  using InternalStrideC = cute::remove_pointer_t<StrideC>;
  using ElementD = ElementD_;
  using StrideD = StrideD_;
  using InternalStrideD = cute::remove_pointer_t<StrideD>;
  using CopyOpT2R = CopyOpT2R_;

  using GmemTiledCopyC = void;
  using GmemTiledCopyD = void;

  constexpr static int ThreadCount = 128;
  constexpr static int kOutputAlignment = ThreadEpilogueOp::kCount;
  constexpr static bool isEpilogueBiasSupported = detail::IsThreadEpilogueOpWithBias<ThreadEpilogueOp>::value;
  using AlignmentType = typename cute::uint_bit<sizeof_bits<ElementOutput>::value * kOutputAlignment>::type;
  constexpr static uint32_t TmaTransactionBytes = 0;

  struct SharedStorage {
    struct TensorStorage { };
    struct TensorMapStorage { };
  };
  using TensorStorage = typename SharedStorage::TensorStorage;
  using TensorMapStorage = typename SharedStorage::TensorMapStorage;

  // Host side epilogue arguments
  struct Arguments {
    typename ThreadEpilogueOp::Params thread{};
    ElementC const** ptr_C = nullptr;
    StrideC dC{};
    ElementD** ptr_D = nullptr;
    StrideD dD{};
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
  get_workspace_size(ProblemShape const& problem_shape, Arguments const& args, int sm_count = 0) {
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
    bool ReuseTmem = false,
    class AccumulatorPipeline,
    class AccumulatorPipelineState,
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class AccEngine, class AccLayout
  >
  CUTLASS_DEVICE auto
  operator()(
      AccumulatorPipeline acc_pipeline,
      AccumulatorPipelineState acc_pipe_consumer_state,
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
    // Slice to get the tile this CTA is responsible for
    auto [m_coord, n_coord, k_coord, l_coord] = cta_coord_mnkl;

    // Batches are managed by using appropriate pointers to C and D matrices
    auto problem_shape_mnl = append<3>(make_shape(M,N),Int<1>{});
    auto cta_coord_mnl = append<3>(make_shape(m_coord, n_coord),Int<0>{});
    auto cta_tiler = take<0,2>(cta_tile_shape_mnk);

    // If scalar alpha/beta are provided, i.e., same alpha/beta applies to all batches/groups.
    // If pointers to alpha/beta are provided, i.e., alpha/beta can differ between batches/groups,
    // we get the correct alpha/beta values for the current batch/group using group index.
    ThreadEpilogueOp epilogue_op = ThreadEpilogueOp(params.thread, l_coord);

    auto [stride_c, stride_d] = [&, l = l_coord]() {
      if constexpr (!cute::is_same_v<InternalStrideC, StrideC>) {
        // If grouped gemm
        if (epilogue_op.is_source_needed()) {
            return make_tuple(
                detail::get_epilogue_stride<DispatchPolicy>(params.dC[l]),
                detail::get_epilogue_stride<DispatchPolicy>(params.dD[l])
            );
        } 
        else {
          return make_tuple(
              InternalStrideC{}, 
              detail::get_epilogue_stride<DispatchPolicy>(params.dD[l])
          );
        }
      } 
      else {
        return make_tuple(
            detail::get_epilogue_stride<DispatchPolicy>(params.dC),
            detail::get_epilogue_stride<DispatchPolicy>(params.dD)
        );
      }
    }();

    // Get the residual tensor for the current batch
    ElementC const* ptr_C_l = nullptr;
    if (epilogue_op.is_source_needed()) {
      ptr_C_l = params.ptr_C[l_coord];
    }

    // Represent the full output tensor, slice to get the tile this CTA is responsible for
    Tensor mC = make_tensor(make_gmem_ptr(ptr_C_l), problem_shape_mnl, stride_c);      // (M,N,L)
    Tensor mD = make_tensor(make_gmem_ptr(params.ptr_D[l_coord]), problem_shape_mnl, stride_d);      // (M,N,L)
    Tensor gC = local_tile(mC, cta_tiler, cta_coord_mnl);                                              // (CTA_M,CTA_N)
    Tensor gD = local_tile(mD, cta_tiler, cta_coord_mnl);                                              // (CTA_M,CTA_N)

    // Partition source and destination tiles according to tmem copy T2R partitioning (tTR_)
    auto tiled_t2r = make_tmem_copy(CopyOpT2R{}, tensor<0>(accumulators));
    auto thread_t2r = tiled_t2r.get_slice(threadIdx.x % size(tiled_t2r));
    Tensor tTR_gC   = thread_t2r.partition_D(gC);                                                  // (T2R,T2R_M,T2R_N)
    Tensor tTR_gD   = thread_t2r.partition_D(gD);                                                  // (T2R,T2R_M,T2R_N)
    Tensor tTR_rAcc = make_tensor<ElementAccumulator>(shape(tTR_gD));                              // (T2R,T2R_M,T2R_N)

    Tensor coordD = make_identity_tensor(problem_shape_mnl);                                      // (M,N,L) -> (m,n,l)
    Tensor cD = local_tile(coordD, cta_tiler, cta_coord_mnl);                               // (CTA_M,CTA_N) -> (m,n,l)
    Tensor tTR_cD = thread_t2r.partition_D(cD);                                         // (T2R,T2R_M,T2R_N) -> (m,n,l)

    // Detect interleaved complex fp32 kernels
    Tensor accs = accumulators;
    using ElementTmem = typename decltype(accs)::value_type;
    constexpr bool is_interleaved_complex_f32 = is_complex<ElementAccumulator>::value && cute::is_same_v<ElementTmem, float>;

    // 1. Load accumulators into register from tmem
    // Tmem -> rmem and transformation for interleaved complex kernels
    if constexpr (is_interleaved_complex_f32) {
      using ElementComputeAccumulator = float;

      Tensor tAccReal = accumulators(make_coord(_,_),_0{},_0{},_0{});                                  // (CTA_M,CTA_N)
      Tensor tAccImag = accumulators(make_coord(_,_),_0{},_0{},_1{});                                  // (CTA_M,CTA_N)
      Tensor tTR_tAccReal = thread_t2r.partition_S(tAccReal);                                      // (T2R,T2R_M,T2R_N)
      Tensor tTR_tAccImag = thread_t2r.partition_S(tAccImag);                                      // (T2R,T2R_M,T2R_N)
      Tensor tTR_rAccReal = make_tensor<ElementComputeAccumulator>(shape(tTR_gD));                 // (T2R,T2R_M,T2R_N)
      Tensor tTR_rAccImag = make_tensor<ElementComputeAccumulator>(shape(tTR_gD));                 // (T2R,T2R_M,T2R_N)

      copy(tiled_t2r, tTR_tAccReal, tTR_rAccReal);
      copy(tiled_t2r, tTR_tAccImag, tTR_rAccImag);

      // 1.1. Transform accumulators in registers
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size(tTR_rAccReal); i++) {
        tTR_rAcc(i) = {tTR_rAccReal(i), tTR_rAccImag(i)};
      }
    }

    // Standard tmem -> rmem epilogue
    else {
      Tensor tAcc = accumulators(make_coord(_,_),_0{},_0{});                                           // (CTA_M,CTA_N)
      Tensor tTR_tAcc = thread_t2r.partition_S(tAcc);                                              // (T2R,T2R_M,T2R_N)

      copy(tiled_t2r, tTR_tAcc, tTR_rAcc);
    }

    // 2. Apply element-wise operation and store to gmem
    // source is needed
    if (epilogue_op.is_source_needed()) {
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size(tTR_rAcc); ++i) {
        if (elem_less(tTR_cD(i), problem_shape_mnl)) {
          tTR_gD(i) = epilogue_op(tTR_rAcc(i), tTR_gC(i));
        }
      }
    }
    // source is not needed, avoid load
    else {
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size(tTR_rAcc); ++i) {
        if (elem_less(tTR_cD(i), problem_shape_mnl)) {
          tTR_gD(i) = epilogue_op(tTR_rAcc(i));
        }
      }
    }
    cutlass::arch::fence_view_async_tmem_load();
    acc_pipeline.consumer_release(acc_pipe_consumer_state);
    ++acc_pipe_consumer_state;
    return cute::make_tuple(acc_pipe_consumer_state);
  }

  // API with Global Accumulator in registers for FastFP32 (emulated MMA) kernels.
  // The accumulator in TMEM periodically loaded into the registers so that the MMA can clear out the TMEM accumulator
  // values for better accuracy. This epilogue accepts the accumulator in registers and take TiledCopy for the
  // TMEM->Reg as a parameter to be used in partitioning GMEM tensors C and D.
  template<
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class AccEngine, class AccLayout,
    class TiledCopy
  >
  CUTLASS_DEVICE void
  operator()(
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK cta_tile_shape_mnk,
      TileCoordMNKL cta_coord_mnkl,
      cute::Tensor<AccEngine, AccLayout>& tTR_rGlobAcc,                                      // (MMA,MMA_M,MMA_N)
      [[maybe_unused]] SharedStorage&,
      TiledCopy tiled_t2r) {

    using namespace cute;
    using X = Underscore;

    static_assert(is_rmem<AccEngine>::value, "Accumulator must be Register resident.");
    static_assert(rank(ProblemShapeMNKL{}) == 4, "ProblemShapeMNKL must be rank 4");
    static_assert(rank(AccLayout{}) == 5, "Accumulators must be copy-partitioned:  (T2R,T2R_M,T2R_N,EPI_M,EPI_N)");
    static_assert(rank(TileCoordMNKL{}) == 4, "TileCoordMNKL must be rank 4");

    // Separate out problem shape for convenience
    auto M = get<0>(problem_shape_mnkl);
    auto N = get<1>(problem_shape_mnkl);
    auto L = get<3>(problem_shape_mnkl);
    // Slice to get the tile this CTA is responsible for
    auto [m_coord, n_coord, k_coord, l_coord] = cta_coord_mnkl;

    // Batches are managed by using appropriate pointers to C and D matrices
    auto problem_shape_mnl = append<3>(make_shape(M,N),Int<1>{});
    auto cta_coord_mnl = append<3>(make_shape(m_coord, n_coord),Int<0>{});
    auto cta_tiler = take<0,2>(cta_tile_shape_mnk);

    ThreadEpilogueOp epilogue_op{params.thread};
    // Get the residual tensor for the current batch
    ElementC const* ptr_C_l = nullptr;
    if (epilogue_op.is_source_needed()) {
      ptr_C_l = params.ptr_C[l_coord];
    }

    // Represent the full output tensor, slice to get the tile this CTA is responsible for
    Tensor mC = make_tensor(make_gmem_ptr(ptr_C_l), problem_shape_mnl, append<3>(params.dC,_0{}));           // (M,N,L)
    Tensor mD = make_tensor(make_gmem_ptr(params.ptr_D[l_coord]), problem_shape_mnl, append<3>(params.dD,_0{})); // (M,N,L)
    Tensor gC = local_tile(mC, cta_tiler, cta_coord_mnl);                                              // (CTA_M,CTA_N)
    Tensor gD = local_tile(mD, cta_tiler, cta_coord_mnl);                                              // (CTA_M,CTA_N)


    // Partition source and destination tiles according to tmem copy T2R partitioning (tTR_)
    auto thread_t2r = tiled_t2r.get_slice(threadIdx.x % size(tiled_t2r));
    Tensor tTR_gC   = thread_t2r.partition_D(gC);                                                  // (T2R,T2R_M,T2R_N)
    Tensor tTR_gD   = thread_t2r.partition_D(gD);                                                  // (T2R,T2R_M,T2R_N)
 

    Tensor coordD = make_identity_tensor(problem_shape_mnl);                                      // (M,N,L) -> (m,n,l)
    Tensor cD = local_tile(coordD, cta_tiler, cta_coord_mnl);                               // (CTA_M,CTA_N) -> (m,n,l)
    Tensor tTR_cD = thread_t2r.partition_D(cD);                                         // (T2R,T2R_M,T2R_N) -> (m,n,l)

    // 2. Apply element-wise operation and store to gmem
    // source is needed
    if (epilogue_op.is_source_needed()) {
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size(tTR_rGlobAcc); ++i) {
        if (elem_less(tTR_cD(i), problem_shape_mnl)) {
          tTR_gD(i) = epilogue_op(tTR_rGlobAcc(i), tTR_gC(i));
        }
      }
    }
    // source is not needed, avoid load
    else {
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < size(tTR_rGlobAcc); ++i) {
        if (elem_less(tTR_cD(i), problem_shape_mnl)) {
          tTR_gD(i) = epilogue_op(tTR_rGlobAcc(i));
        }
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
    Sm100PtrArrayNoSmemWarpSpecialized,
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
      Sm100PtrArrayNoSmem,
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
      Sm100PtrArrayNoSmem,
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
