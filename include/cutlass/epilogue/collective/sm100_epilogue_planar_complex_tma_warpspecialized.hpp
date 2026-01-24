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
  \brief Functor performing elementwise operations used by Planar Complex Gemm epilogues.
*/



#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/arch/barrier.h"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/detail.hpp"
#include "cutlass/epilogue/thread/scale_type.h"
#include "cutlass/epilogue/thread/linear_combination_planar_complex.h"
#include "cutlass/detail/layout.hpp"
#include "cutlass/trace.h"

#include "cute/tensor.hpp"
#include "cutlass/cuda_host_adapter.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  int StagesC_,
  int StagesD_,
  int FragmentSize_,
  bool ReuseSmemC_,
  bool DelayTmaStore_,
  class CtaTileShape_, // (CTA_M,CTA_N,CTA_K, optional: Tile_L)
  class EpilogueTile_, // (EPI_TILE_M, EPI_TILE_N)
  class ElementC_,
  class StrideC_,
  class ElementD_,
  class StrideD_,
  class ThreadEpilogueOp_,
  class CopyOpT2R_,
  class CopyOpG2S_,
  class SmemLayoutAtomC_,
  class CopyOpS2R_,
  class CopyOpS2G_,
  class SmemLayoutAtomD_,
  class CopyOpR2S_,
  class CopyOpR2R_
>
class CollectiveEpilogue<
    Sm100PlanarComplexTmaWarpSpecialized<StagesC_, StagesD_, FragmentSize_, ReuseSmemC_, DelayTmaStore_>,
    CtaTileShape_,
    EpilogueTile_,
    ElementC_,
    StrideC_,
    ElementD_,
    StrideD_,
    ThreadEpilogueOp_,
    CopyOpT2R_,
    CopyOpG2S_,
    SmemLayoutAtomC_,
    CopyOpS2R_,
    CopyOpS2G_,
    SmemLayoutAtomD_,
    CopyOpR2S_,
    CopyOpR2R_
> {
public:
  //
  // Type Aliases
  //
  using DispatchPolicy = Sm100PlanarComplexTmaWarpSpecialized<StagesC_, StagesD_, FragmentSize_, ReuseSmemC_, DelayTmaStore_>;
  using CtaTileShape = CtaTileShape_;
  using EpilogueTile = EpilogueTile_;
  using ThreadEpilogueOp = ThreadEpilogueOp_;
  using ElementC = ElementC_;
  using StrideC = StrideC_;
  using ElementD = ElementD_;
  using StrideD = StrideD_;
  using CopyOpT2R = CopyOpT2R_;
  using CopyOpG2S = CopyOpG2S_;
  using SmemLayoutAtomC = SmemLayoutAtomC_;
  using CopyOpS2R = CopyOpS2R_;
  using CopyOpS2G = CopyOpS2G_;
  using SmemLayoutAtomD = SmemLayoutAtomD_;
  using CopyOpR2S = CopyOpR2S_;
  using CopyOpR2R = CopyOpR2R_;

  using GmemTiledCopyC = CopyOpG2S;
  using GmemTiledCopyD = CopyOpS2G;

  constexpr static int ThreadCount = 128;

  static_assert(!is_layout<EpilogueTile>::value && is_tuple<EpilogueTile>::value, "EpilogueTile must be a cute::Tile or cute::Shape");
  static_assert(rank(EpilogueTile{}) == 2, "EpilogueTile must be rank-2: [EPI_TILE_M, EPI_TILE_N]");

private:
  using SmemElementD = typename cutlass::detail::get_unpacked_element_type<ElementD>::type;
  using SmemElementC = typename cutlass::detail::get_unpacked_element_type<cute::conditional_t<cute::is_void_v<ElementC>,ElementD,ElementC>>::type; // prevents void ref breakages
  constexpr static int StagesC = StagesC_;
  constexpr static int StagesD = StagesD_;
  constexpr static bool ReuseSmemC = ReuseSmemC_;
  constexpr static bool DelayTmaStore = DelayTmaStore_;
  constexpr static bool is_source_supported = ThreadEpilogueOp::kScale == cutlass::epilogue::thread::ScaleType::Default;

  constexpr static bool is_m_major_C = detail::is_m_major<StrideC>();
  constexpr static bool is_m_major_D = detail::is_m_major<StrideD>();

  using SmemLayoutC = decltype(tile_to_shape(
      SmemLayoutAtomC{},
      make_shape(size<0>(shape(EpilogueTile{})), size<1>(shape(EpilogueTile{})), Int<StagesC>{}),
      cute::conditional_t<is_m_major_C, Step<_2,_1,_3>, Step<_1,_2,_3>>{} ));
  using SmemLayoutD = decltype(tile_to_shape(
      SmemLayoutAtomD{},
      make_shape(size<0>(shape(EpilogueTile{})), size<1>(shape(EpilogueTile{})), Int<ReuseSmemC ? StagesC : StagesD>{}),
      cute::conditional_t<is_m_major_D, Step<_2,_1,_3>, Step<_1,_2,_3>>{} ));

  constexpr static bool support_smem_reuse = is_source_supported && StagesD <= StagesC
                                            && cosize(take<0,2>(SmemLayoutC{})) == cosize(take<0,2>(SmemLayoutD{}));
  static_assert(not (ReuseSmemC && not support_smem_reuse), "Smem reuse requirements not met");

  constexpr static size_t SmemAlignmentD = cutlass::detail::alignment_for_swizzle(SmemLayoutD{});
  constexpr static size_t SmemAlignmentC = cutlass::detail::alignment_for_swizzle(SmemLayoutC{});

public :
  struct TensorStorageWithC {
    alignas(SmemAlignmentC) cute::ArrayEngine<SmemElementC, cute::cosize_v<SmemLayoutC>> smem_C_real;
    alignas(SmemAlignmentC) cute::ArrayEngine<SmemElementC, cute::cosize_v<SmemLayoutC>> smem_C_imag;

    alignas(SmemAlignmentD) cute::ArrayEngine<SmemElementD, cute::cosize_v<SmemLayoutD>> smem_D_real;
    alignas(SmemAlignmentD) cute::ArrayEngine<SmemElementD, cute::cosize_v<SmemLayoutD>> smem_D_imag;
  };

  struct TensorStorageWithoutC {
    alignas(SmemAlignmentD) cute::ArrayEngine<SmemElementD, cute::cosize_v<SmemLayoutD>> smem_D_real;
    alignas(SmemAlignmentD) cute::ArrayEngine<SmemElementD, cute::cosize_v<SmemLayoutD>> smem_D_imag;
  };

public:
  // TMA pipeline for loading C
  using LoadPipeline = cutlass::PipelineTransactionAsync<StagesC>;
  using LoadPipelineState = cutlass::PipelineState<StagesC>;
  constexpr static uint32_t TmaTransactionBytes =
    2 * ((size(take<0,2>(SmemLayoutC{})) * static_cast<uint32_t>(sizeof_bits<SmemElementC>::value)) / 8);

  // TMA pipeline for storing D
  using StorePipeline = cute::conditional_t<ReuseSmemC,
                          cutlass::PipelineTmaStore<StagesC, StagesD-1>,
                          cutlass::PipelineTmaStore<StagesD>>;
  using StorePipelineState = cutlass::PipelineState<ReuseSmemC ? StagesC : StagesD>;

  struct SharedStorage {
    using TensorStorage =
      cute::conditional_t<not is_source_supported or ReuseSmemC, TensorStorageWithoutC, TensorStorageWithC>;
    TensorStorage tensors;

    using PipelineStorage = typename LoadPipeline::SharedStorage;
    PipelineStorage pipeline;
  };
  using TensorStorage = typename SharedStorage::TensorStorage;
  using PipelineStorage = typename SharedStorage::PipelineStorage;

  // Planar complex kernels have two accumulator copies for the real and imaginary tensors.
  constexpr static int NumAccumulatorMtxs = 2;

  // Host side epilogue arguments
  struct Arguments {
    typename ThreadEpilogueOp::Params thread{};
    ElementC const* ptr_C_real = nullptr;
    StrideC dC_real{};
    ElementC const* ptr_C_imag = nullptr;
    StrideC dC_imag{};
    ElementD* ptr_D_real = nullptr;
    StrideD dD_real{};
    ElementD* ptr_D_imag = nullptr;
    StrideD dD_imag{};
  };

  // Device side epilogue params
  struct Params {
    using TMA_C = decltype(make_tma_copy(
        CopyOpG2S{},
        make_tensor(
            make_gmem_ptr(static_cast<cute::conditional_t<cute::is_void_v<ElementC>,ElementD,ElementC> const*>(nullptr)),
            repeat_like(append<3>(StrideC{}, _1{}), int32_t(0)),
            append<3>(StrideC{}, _0{})),
        take<0,2>(SmemLayoutC{}),
        EpilogueTile{},
        _1{}));
    using TMA_D = decltype(make_tma_copy(
        CopyOpS2G{},
        make_tensor(
            make_gmem_ptr(static_cast<ElementD*>(nullptr)),
            repeat_like(append<3>(StrideD{}, _1{}), int32_t(0)),
            append<3>(StrideD{}, _0{})),
        take<0,2>(SmemLayoutC{}),
        EpilogueTile{},
        _1{}));

    typename ThreadEpilogueOp::Params thread{};
    TMA_C tma_load_c_real;
    TMA_C tma_load_c_imag;
    TMA_D tma_store_d_real;
    TMA_D tma_store_d_imag;
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
    auto problem_shape_mnkl = append<4>(problem_shape, 1);
    auto [M, N, K, L] = problem_shape_mnkl;

    typename Params::TMA_C tma_load_c_real{};
    typename Params::TMA_C tma_load_c_imag{};
    if constexpr (not cute::is_void_v<ElementC>) {
      Tensor tensor_c_real = make_tensor(make_gmem_ptr(args.ptr_C_real), make_layout(make_shape(M,N,L), append<3>(args.dC_real, _0{})));
      Tensor tensor_c_imag = make_tensor(make_gmem_ptr(args.ptr_C_imag), make_layout(make_shape(M,N,L), append<3>(args.dC_imag, _0{})));

      tma_load_c_real = make_tma_copy(CopyOpG2S{}, tensor_c_real, take<0,2>(SmemLayoutC{}), EpilogueTile{}, _1{});
      tma_load_c_imag = make_tma_copy(CopyOpG2S{}, tensor_c_imag, take<0,2>(SmemLayoutC{}), EpilogueTile{}, _1{});
    }

    Tensor tensor_d_real = make_tensor(make_gmem_ptr(args.ptr_D_real), make_layout(make_shape(M,N,L), append<3>(args.dD_real, _0{})));
    Tensor tensor_d_imag = make_tensor(make_gmem_ptr(args.ptr_D_imag), make_layout(make_shape(M,N,L), append<3>(args.dD_imag, _0{})));

    typename Params::TMA_D tma_store_d_real =
      make_tma_copy(CopyOpS2G{}, tensor_d_real, take<0,2>(SmemLayoutD{}), EpilogueTile{}, _1{});
    typename Params::TMA_D tma_store_d_imag =
      make_tma_copy(CopyOpS2G{}, tensor_d_imag, take<0,2>(SmemLayoutD{}), EpilogueTile{}, _1{});

    return {
      args.thread,
      tma_load_c_real,
      tma_load_c_imag,
      tma_store_d_real,
      tma_store_d_imag
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
    return cutlass::Status::kSuccess;
  }

  template <class ProblemShape>
  static bool
  can_implement(
      ProblemShape const& problem_shape,
      [[maybe_unused]] Arguments const& args) {
    constexpr int tma_alignment_bits_d = cutlass::detail::get_output_alignment_bits<ElementD>();
    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M,N,K,L] = problem_shape_MNKL;

    constexpr int min_tma_aligned_elements_D = tma_alignment_bits_d / cutlass::sizeof_bits<ElementD>::value;
    bool implementable = cutlass::detail::check_alignment<min_tma_aligned_elements_D>(cute::make_shape(M,N,L), StrideD{});

    if constexpr (not cute::is_void_v<ElementC>) {
      constexpr int tma_alignment_bits_c = cutlass::detail::get_output_alignment_bits<ElementC>();
      constexpr int min_tma_aligned_elements_C = tma_alignment_bits_c / cutlass::sizeof_bits<ElementC>::value;
      implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_C>(cute::make_shape(M,N,L), StrideC{});
    }

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for TMA.\n");
    }

    bool beta_implementable = true;

    if constexpr (cute::is_void_v<ElementC>) {
      if constexpr (detail::has_beta<Arguments>::value) {
        beta_implementable = args.thread.beta == 0.0;
      }
      if constexpr (detail::has_beta_ptr<Arguments>::value) {
        beta_implementable = beta_implementable && args.thread.beta_ptr == nullptr;
      }
    }

    if (!beta_implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Beta/beta pointer was set, but epilogue is sourceless (void-C).\n");
    }

    return implementable && beta_implementable;
  }

  template<class CtaTileMNK>
  CUTLASS_HOST_DEVICE
  static constexpr int
  get_load_pipe_increment(CtaTileMNK cta_tile_mnk) {
    // Compute number of epilogue subtiles
    constexpr int epi_m = size<0>(cta_tile_mnk) / size<0>(EpilogueTile{});
    constexpr int epi_n = size<1>(cta_tile_mnk) / size<1>(EpilogueTile{});

    return epi_m * epi_n;
  }

  template<class CtaTileMNK>
  CUTLASS_HOST_DEVICE
  static constexpr int
  get_store_pipe_increment(CtaTileMNK cta_tile_mnk) {
    return get_load_pipe_increment(cta_tile_mnk);
  }

  /// Issue Tma Descriptor Prefetch -- ideally from a single thread for best performance
  CUTLASS_DEVICE static void
  prefetch_tma_descriptors(Params const& epilogue_params) {
    cute::prefetch_tma_descriptor(epilogue_params.tma_load_c_real.get_tma_descriptor());
    cute::prefetch_tma_descriptor(epilogue_params.tma_load_c_imag.get_tma_descriptor());
    cute::prefetch_tma_descriptor(epilogue_params.tma_store_d_real.get_tma_descriptor());
    cute::prefetch_tma_descriptor(epilogue_params.tma_store_d_imag.get_tma_descriptor());
  }

  CUTLASS_HOST_DEVICE
  CollectiveEpilogue(Params const& params_, TensorStorage&)
      : params(params_), epilogue_op(params_.thread) {}

  CUTLASS_DEVICE bool
  is_producer_load_needed() const {
    return epilogue_op.is_source_needed();
  }

  template<
    bool ReuseTmem = false,
    class ProblemShapeMNKL,
    class CtaTileMNK,
    class CtaCoordMNKL,
    class MmaTileMNK,
    class TiledMma
  >
  CUTLASS_DEVICE auto
  load(
      LoadPipeline load_pipeline,
      LoadPipelineState load_pipe_producer_state,
      ProblemShapeMNKL problem_shape_mnkl,
      CtaTileMNK cta_tile_mnk,
      CtaCoordMNKL cta_coord_mnkl,
      MmaTileMNK mma_tile_mnk,
      TiledMma tiled_mma,
      TensorStorage& shared_tensors,
      bool reverse_epi_n = false) {
    using namespace cute;

    int lane_idx = canonical_lane_idx();
    auto [M, N, K, L] = problem_shape_mnkl;
    auto [m_coord, n_coord, k_coord, l_coord] = cta_coord_mnkl;

    auto coord_shape = make_coord(m_coord, n_coord, l_coord);

    // Tile residue
    auto m_max_coord = unwrap(cute::transform(make_seq<rank<0>(cta_tile_mnk)>{}, [&](auto i) {
      return get<0,i>(problem_shape_mnkl) - get<0,i>(cta_tile_mnk) * get<0,i>(cta_coord_mnkl);
    }));
    auto n_max_coord = unwrap(cute::transform(make_seq<rank<1>(cta_tile_mnk)>{}, [&](auto i) {
      return get<1,i>(problem_shape_mnkl) - get<1,i>(cta_tile_mnk) * get<1,i>(cta_coord_mnkl);
    }));
    auto residue_mn = make_coord(m_max_coord, n_max_coord);

    // Represent the full source tensor, slice to get the tile this CTA is currently responsible for
    Tensor mC_real_mn = params.tma_load_c_real.get_tma_tensor(make_shape(M,N,L));                                //       (M,N,L)
    Tensor mC_imag_mn = params.tma_load_c_imag.get_tma_tensor(make_shape(M,N,L));                                //       (M,N,L)

    Tensor mC_real = coalesce(mC_real_mn, take<0,2>(cta_tile_mnk));
    Tensor mC_imag = coalesce(mC_imag_mn, take<0,2>(cta_tile_mnk));

    Tensor gC_real = local_tile(mC_real, take<0,2>(cta_tile_mnk), coord_shape);                                // (CTA_M,CTA_N)
    Tensor gC_imag = local_tile(mC_imag, take<0,2>(cta_tile_mnk), coord_shape);                                // (CTA_M,CTA_N)


    // Apply epilogue subtile, get matching smem tensor
    auto ptr_sC_real = [&]() {
      if constexpr (not ReuseSmemC and is_source_supported) {
        return shared_tensors.smem_C_real.begin();
      }
      else {
        return shared_tensors.smem_D_real.begin();
      }
    }();
    auto ptr_sC_imag = [&]() {
      if constexpr (not ReuseSmemC and is_source_supported) {
        return shared_tensors.smem_C_imag.begin();
      }
      else {
        return shared_tensors.smem_D_imag.begin();
      }
    }();

    Tensor gC_real_epi = flat_divide(gC_real, EpilogueTile{});                             // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)
    Tensor gC_imag_epi = flat_divide(gC_imag, EpilogueTile{});                             // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)

    Tensor sC_real_epi = make_tensor(make_smem_ptr(ptr_sC_real), SmemLayoutC{});           // (EPI_TILE_M,EPI_TILE_N,PIPE_C)
    Tensor sC_imag_epi = make_tensor(make_smem_ptr(ptr_sC_imag), SmemLayoutC{});           // (EPI_TILE_M,EPI_TILE_N,PIPE_C)

    // Prepare the thread(b)lock's (G)mem to (S)mem TMA tiled copy (bGS_)
    ThrCopy thrblk_g2s_real = params.tma_load_c_real.get_slice(Int<0>{});
    ThrCopy thrblk_g2s_imag = params.tma_load_c_imag.get_slice(Int<0>{});

    Tensor bGS_gC_real = thrblk_g2s_real.partition_S(gC_real_epi);                          // (TMA,TMA_M,TMA_N,EPI_M,EPI_N)
    Tensor bGS_gC_imag = thrblk_g2s_imag.partition_S(gC_imag_epi);                          // (TMA,TMA_M,TMA_N,EPI_M,EPI_N)

    Tensor bGS_sC_real = thrblk_g2s_real.partition_D(sC_real_epi);                          // (TMA,TMA_M,TMA_N,PIPE_C)
    Tensor bGS_sC_imag = thrblk_g2s_imag.partition_D(sC_imag_epi);                          // (TMA,TMA_M,TMA_N,PIPE_C)

    // Predication for TMA load (one thread issues TMA load)
    bool issue_tma_load = cute::elect_one_sync();

    // Acquire the lock for the first stage
    uint64_t* tma_barrier = load_pipeline.producer_get_barrier(load_pipe_producer_state);
    load_pipeline.producer_acquire(load_pipe_producer_state);

    CUTLASS_PRAGMA_UNROLL
    for (int iter_n = 0; iter_n < size<3>(gC_real_epi); ++iter_n) {
      CUTLASS_PRAGMA_UNROLL
      for (int iter_m = 0; iter_m < size<2>(gC_real_epi); ++iter_m) {
        int epi_m = iter_m, epi_n = iter_n;
        if constexpr (ReuseTmem) {
          if (reverse_epi_n) {
            epi_n = size<3>(gC_real_epi) - 1 - iter_n;
          }
        }
        // Acquire the lock for this stage
        constexpr uint16_t mcast_mask = 0;
        uint64_t* tma_barrier = load_pipeline.producer_get_barrier(load_pipe_producer_state);
        load_pipeline.producer_acquire(load_pipe_producer_state);

        // Execute the TMA load for C
        if (issue_tma_load) {
          copy(params.tma_load_c_real.with(*tma_barrier, mcast_mask),
              bGS_gC_real(_,_,_,epi_m,epi_n), bGS_sC_real(_,_,_,load_pipe_producer_state.index()));
          copy(params.tma_load_c_imag.with(*tma_barrier, mcast_mask),
              bGS_gC_imag(_,_,_,epi_m,epi_n), bGS_sC_imag(_,_,_,load_pipe_producer_state.index()));
          load_pipeline.producer_expect_transaction(load_pipe_producer_state);
        }

        // Commit TMA loads for this stage and release the lock
        load_pipeline.producer_commit(load_pipe_producer_state);
        ++load_pipe_producer_state;
      }
    }

    return load_pipe_producer_state;
  }

  CUTLASS_DEVICE void
  load_tail(
      LoadPipeline load_pipeline,
      LoadPipelineState load_pipe_producer_state,
      [[maybe_unused]] StorePipeline store_pipeline,
      [[maybe_unused]] StorePipelineState store_pipe_producer_state) {
    load_pipeline.producer_tail(load_pipe_producer_state);
  }

  template<
    bool ReuseTmem = false,
    class AccumulatorPipeline,
    class AccumulatorPipelineState,
    class ProblemShapeMNKL,
    class CtaTileMNK,
    class CtaCoordMNKL,
    class MmaTileMNK,
    class TiledMma,
    class AccEngine,
    class AccLayout
  >
  CUTLASS_DEVICE auto
  store(
      LoadPipeline load_pipeline,
      LoadPipelineState load_pipe_consumer_state,
      StorePipeline store_pipeline,
      StorePipelineState store_pipe_producer_state,
      AccumulatorPipeline acc_pipeline,
      AccumulatorPipelineState acc_pipe_consumer_state,
      ProblemShapeMNKL problem_shape_mnkl,
      CtaTileMNK cta_tile_mnk,
      CtaCoordMNKL cta_coord_mnkl,
      MmaTileMNK mma_tile_mnk,
      TiledMma tiled_mma,
      cute::Tensor<AccEngine,AccLayout> accumulators,
      TensorStorage& shared_tensors
      ) {
    using namespace cute;
    using ElementAccumulator = typename AccEngine::value_type;
    using ElementCompute = typename ThreadEpilogueOp::ElementCompute;

    static_assert(is_tmem<AccEngine>::value, "Accumulator must be TMEM resident.");
    //static_assert(rank(accumulators) == 4, "Accumulators must be MMA-partitioned: [MMA, MMA_M, MMA_N]");
    static_assert(size<1>(accumulators) == 1 && size<2>(accumulators) == 1, "TiledMMA must match partitioned ShapeMN");
    static_assert(rank(ProblemShapeMNKL{}) == 4, "ProblemShapeMNKL must be rank 4");
    static_assert(rank(CtaCoordMNKL{}) == 4, "CoordMNKL must be rank 4");

    // Indexing variables
    auto [M, N, K, L] = problem_shape_mnkl;
    auto [m_coord, n_coord, k_coord, l_coord] = cta_coord_mnkl;
    int thread_idx = threadIdx.x % ThreadCount;
    int warp_idx = thread_idx / NumThreadsPerWarp;
    [[maybe_unused]] int lane_idx = thread_idx % NumThreadsPerWarp;

    auto accumulators_real = accumulators(_,_,_,0);
    auto accumulators_imag = accumulators(_,_,_,1);

    auto coord_shape = make_coord(m_coord, n_coord, l_coord);

    // Represent the full output tensor, slice to get the tile this CTA is responsible for
    Tensor mD_real_mn = params.tma_store_d_real.get_tma_tensor(make_shape(M,N,L));                               //       (M,N,L)
    Tensor mD_imag_mn = params.tma_store_d_imag.get_tma_tensor(make_shape(M,N,L));                               //       (M,N,L)

    Tensor mD_real = coalesce(mD_real_mn, take<0,2>(cta_tile_mnk));
    Tensor mD_imag = coalesce(mD_imag_mn, take<0,2>(cta_tile_mnk));

    Tensor gD_real = local_tile(mD_real, take<0,2>(cta_tile_mnk), coord_shape);                                // (CTA_M,CTA_N)
    Tensor gD_imag = local_tile(mD_imag, take<0,2>(cta_tile_mnk), coord_shape);                                // (CTA_M,CTA_N)

    Tensor tAcc_real = accumulators_real(make_coord(_,_),_0{},_0{});                                             // (CTA_M,CTA_N)
    Tensor tAcc_imag = accumulators_imag(make_coord(_,_),_0{},_0{});                                             // (CTA_M,CTA_N)

    // Apply epilogue subtiling
    Tensor tAcc_real_epi = flat_divide(tAcc_real, EpilogueTile{});                         // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)
    Tensor tAcc_imag_epi = flat_divide(tAcc_imag, EpilogueTile{});                         // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)

    Tensor gD_real_epi   = flat_divide(gD_real, EpilogueTile{});                           // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)
    Tensor gD_imag_epi   = flat_divide(gD_imag, EpilogueTile{});                           // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)

    // Construct the corresponding pipelined smem tensors
    auto ptr_sC_real = [&]() {
      if constexpr (not ReuseSmemC and is_source_supported) {
        return shared_tensors.smem_C_real.begin();
      }
      else {
        return shared_tensors.smem_D_real.begin();
      }
    }();
    auto ptr_sC_imag = [&]() {
      if constexpr (not ReuseSmemC and is_source_supported) {
        return shared_tensors.smem_C_imag.begin();
      }
      else {
        return shared_tensors.smem_D_imag.begin();
      }
    }();

    auto ptr_sD_real = shared_tensors.smem_D_real.begin();
    auto ptr_sD_imag = shared_tensors.smem_D_imag.begin();

    Tensor sC_real_epi = cute::as_position_independent_swizzle_tensor(
                      make_tensor(make_smem_ptr(ptr_sC_real), SmemLayoutC{}));                  // (EPI_TILE_M,EPI_TILE_N,PIPE_C)
    Tensor sC_imag_epi = cute::as_position_independent_swizzle_tensor(
                      make_tensor(make_smem_ptr(ptr_sC_imag), SmemLayoutC{}));                  // (EPI_TILE_M,EPI_TILE_N,PIPE_C)

    Tensor sD_real_epi = cute::as_position_independent_swizzle_tensor(
                      make_tensor(make_smem_ptr(ptr_sD_real), SmemLayoutD{}));                  // (EPI_TILE_M,EPI_TILE_N,PIPE_D)
    Tensor sD_imag_epi = cute::as_position_independent_swizzle_tensor(
                      make_tensor(make_smem_ptr(ptr_sD_imag), SmemLayoutD{}));                  // (EPI_TILE_M,EPI_TILE_N,PIPE_D)

    // (t)hread-partition for (t)mem to (r)egister copy (tTR_)
    TiledCopy tiled_t2r = make_tmem_copy(CopyOpT2R{}, tAcc_real_epi(_,_,_0{},_0{}));
    ThrCopy thread_t2r = tiled_t2r.get_slice(thread_idx);
    Tensor tTR_tAcc_real = thread_t2r.partition_S(tAcc_real_epi);                                // (T2R,T2R_M,T2R_N,EPI_M,EPI_N)
    Tensor tTR_sD_real   = thread_t2r.partition_D(sD_real_epi(_,_,_0{}));                        // (T2R,T2R_M,T2R_N)
    Tensor tTR_tAcc_imag = thread_t2r.partition_S(tAcc_imag_epi);                                // (T2R,T2R_M,T2R_N,EPI_M,EPI_N)
    Tensor tTR_sD_imag   = thread_t2r.partition_D(sD_imag_epi(_,_,_0{}));                        // (T2R,T2R_M,T2R_N)

    // Allocate D and accumulator registers
    Tensor tTR_rAcc = make_tensor<ElementAccumulator>(append(shape(tTR_sD_real), Int<NumAccumulatorMtxs>{})); // (T2R,T2R_M,T2R_N,2)
    Tensor tTR_rD   = make_tensor<SmemElementD>(append(shape(tTR_sD_real), Int<NumAccumulatorMtxs>{}));       // (T2R,T2R_M,T2R_N,2)

    // Vectorized fragment view
    constexpr int FragmentSize = DispatchPolicy::FragmentSize;
    Tensor tTR_rAcc_frg = recast<ArrayPlanarComplex<ElementAccumulator, FragmentSize>>(coalesce(tTR_rAcc));            // (EPI_V)
    Tensor tTR_rD_frg = recast<ArrayPlanarComplex<SmemElementD, FragmentSize>>(coalesce(tTR_rD));                      // (EPI_V)

    CUTE_STATIC_ASSERT(size(tTR_rAcc) % DispatchPolicy::FragmentSize == 0, "Fragment size does not vectorize properly");

    // (t)hread-partition for (s)mem to (r)egister copy (tSR_)
    TiledCopy tiled_s2r = make_tiled_copy_D(Copy_Atom<CopyOpS2R, SmemElementC>{}, tiled_t2r);
    ThrCopy thread_s2r  = tiled_s2r.get_slice(thread_idx);
    Tensor tSR_sC_real  = thread_s2r.partition_S(sC_real_epi);                                        // (S2R,S2R_M,S2R_N,PIPE_C)
    Tensor tSR_sC_imag  = thread_s2r.partition_S(sC_imag_epi);                                        // (S2R,S2R_M,S2R_N,PIPE_C)

    Layout tSR_rC_layout = thread_s2r.retile_D(tTR_rD(_,_,_,_0{})).layout();                                 // (S2R,S2R_M,S2R_N)

    // Allocate C registers
    // If C smem load is a non-vectorized dst(i) = src(i) then we can allocate C registers directly in the compute type
    // to eliminate some redundant pack+unpack instruction sequences for sub-word types
    constexpr bool IsDirectS2R = cute::is_same_v<CopyOpS2R,DefaultCopy>
                                && decltype(max_common_vector(tSR_rC_layout, tSR_sC_real.layout()))::value <= 1;
    using RegisterElementC = cute::conditional_t<IsDirectS2R, ElementCompute, SmemElementC>;
    Tensor tTR_rC = make_tensor<RegisterElementC>(append(shape(tTR_sD_real), _2{}));                         // (T2R,T2R_M,T2R_N)
    Tensor tSR_rC = thread_s2r.retile_D(tTR_rC);                                                             // (S2R,S2R_M,S2R_N)
    Tensor tTR_rC_frg = recast<ArrayPlanarComplex<SmemElementD, FragmentSize>>(tTR_rC);                                // (EPI_V)

    // (t)hread-partition for (r)egister to (s)mem copy (tRS_)
    TiledCopy tiled_r2s = make_tiled_copy_D(Copy_Atom<CopyOpR2S,SmemElementD>{}, tiled_t2r);
    ThrCopy thread_r2s = tiled_r2s.get_slice(thread_idx);
    Tensor tRS_rD = thread_r2s.retile_S(tTR_rD);                                                             // (R2S,R2S_M,R2S_N)
    Tensor tRS_sD_real = thread_r2s.partition_D(sD_real_epi);                                         // (R2S,R2S_M,R2S_N,PIPE_D)
    Tensor tRS_sD_imag = thread_r2s.partition_D(sD_imag_epi);                                         // (R2S,R2S_M,R2S_N,PIPE_D)

    // thread(b)lock-partition for (s)mem to (g)mem copy (bSG_)
    ThrCopy thrblk_s2g = params.tma_store_d_real.get_slice(Int<0>{});
    Tensor bSG_sD_real = thrblk_s2g.partition_S(sD_real_epi);                                         // (S2G,S2G_M,S2G_N,PIPE_D)
    Tensor bSG_gD_real = thrblk_s2g.partition_D(gD_real_epi);                                    // (S2G,S2G_M,S2G_N,EPI_M,EPI_N)
    Tensor bSG_sD_imag = thrblk_s2g.partition_S(sD_imag_epi);                                         // (S2G,S2G_M,S2G_N,PIPE_D)
    Tensor bSG_gD_imag = thrblk_s2g.partition_D(gD_imag_epi);                                    // (S2G,S2G_M,S2G_N,EPI_M,EPI_N)

    // Coordinate tensors and residue for tile quantization
    auto m_max_coord = unwrap(cute::transform(make_seq<rank<0>(cta_tile_mnk)>{}, [&](auto i) {
      auto c_m = get<0,i>(problem_shape_mnkl) - get<0,i>(cta_tile_mnk) * get<0,i>(cta_coord_mnkl);
      return cute::max(0, c_m);
    }));
    auto n_max_coord = unwrap(cute::transform(make_seq<rank<1>(cta_tile_mnk)>{}, [&](auto i) {
      auto c_n = get<1,i>(problem_shape_mnkl) - get<1,i>(cta_tile_mnk) * get<1,i>(cta_coord_mnkl);
      return cute::max(0, c_n);
    }));
    auto residue_mn = make_coord(m_max_coord, n_max_coord);
    Tensor cD = make_identity_tensor(take<0,2>(cta_tile_mnk));
    Tensor tTR_cD = thread_t2r.partition_D(flat_divide(cD, EpilogueTile{}));

    bool is_source_needed = epilogue_op.is_source_needed();
    // Thread synchronizer for previously issued waits or fences
    // to ensure visibility of smem reads/writes to threads or TMA unit
    auto synchronize = [] () { cutlass::arch::NamedBarrier::sync(ThreadCount, cutlass::arch::ReservedNamedBarriers::EpilogueBarrier); };

    // Predication for sub-128 thread T2R tiled copy
    Layout tmem_warp_layout = typename decltype(make_tmem_warp_partitioner(tAcc_real_epi(_,_,0,0)))::TiledLayout_TV{};
    constexpr bool predicate_tmem_load = size(tmem_warp_layout) != cosize(tmem_warp_layout);
    bool issue_tmem_load = true;

    // If tmem doesn't have enough capacity to support double buffering, a portion of tmem (a column of epilogue tiles)
    // is overlapped between 2 pseudo-buffers. The shared tmem portion corresponds to the last epilogue tile column of
    // tmem accumulator buffer 0, and the first epilogue tile column of tmem accumulator 1.
    // Thus, whenever we are processing tmem accumulator buffer 0, we process the epilogue tiles with reversed column order.
    // Once the last epilogue tile column is loaded from tmem, the acc_pipeline is released.
    // Then, the next accumulation stage for buffer 1 can start.
    [[maybe_unused]] bool reverse_epi_n = ReuseTmem && acc_pipe_consumer_state.phase() == 0;
    static_assert(not (ReuseTmem && AccumulatorPipeline::Stages != 1), "Tmem reuse requires 1 accumulator stage");

    // Predication for TMA store (one warp issues TMA store)
    bool issue_tma_store = warp_idx == 0;

    // In the reuse smem configuration we have StagesC smem buffers and at most StagesD committed TMA stores in flight.
    // The TMA store pipeline producer acquire returns when at most StagesD-1 committed stores are in-flight, so we can
    // only guarantee store completion after StagesD iterations, then we can begin issuing releases on the smem buffer locks.
    // store_pipe_producer_state tracks the acquire and load_pipe_consumer_state tracks the release, in circular buffer fashion.
    // If TMA store supported async transaction mbarriers we would not need this synchronous release behavior.
    LoadPipelineState load_wait_state = load_pipe_consumer_state;
    if constexpr (ReuseSmemC) {
      load_wait_state = store_pipe_producer_state;
      load_wait_state.phase_ ^= 1;
    }

    // We can delay issue of TMA store by one iteration to achieve better interleaving of non-TMA instructions
    // Sync requirements of smem reuse may preclude this optimization
    [[maybe_unused]] int epi_m_prev = 0;
    [[maybe_unused]] int epi_n_prev = 0;
    static_assert(not (DelayTmaStore and ReuseSmemC and StagesC <= StagesD), "This TMA epilogue configuration will deadlock");

    // The TMA store sequence for one subtile iteration
    auto tma_store_fn = [&] (int epi_m, int epi_n) {
      // Write the tile from smem to gmem with TMA
      cutlass::arch::fence_view_async_shared(); // ensure smem writes are visible to TMA
      synchronize(); // ensure all threads have issued their async fence
      if (issue_tma_store) {
        copy(params.tma_store_d_real, bSG_sD_real(_,_,_,store_pipe_producer_state.index()), bSG_gD_real(_,_,_,epi_m,epi_n));
        copy(params.tma_store_d_imag, bSG_sD_imag(_,_,_,store_pipe_producer_state.index()), bSG_gD_imag(_,_,_,epi_m,epi_n));
      }

      // Commit the TMA stores for this stage
      if (issue_tma_store) {
        store_pipeline.producer_commit(store_pipe_producer_state);
      }
      ++store_pipe_producer_state;

      // Wait for the next smem buffer to be available
      if (issue_tma_store) {
        store_pipeline.producer_acquire(store_pipe_producer_state);
      }
      synchronize();

      if constexpr (ReuseSmemC) {
        // producer_acquire returns when at most StagesD-1 committed stores are pending
        bool store_finished = store_pipe_producer_state.count() > StorePipeline::UnacquiredStages;
        // Let dma warp know earliest smem buffer is consumed and empty after StagesD producer commits
        if (store_finished) {
          if (is_source_needed) {
            load_pipeline.consumer_release(load_pipe_consumer_state);
          }
          ++load_pipe_consumer_state;
        }
      }
    };

    //
    // BEGIN EPILOGUE
    //

    // Begin the wait for the producer load results
    ConsumerToken load_wait_token{BarrierStatus::WaitDone};
    if (is_source_needed) {
      load_wait_token = load_pipeline.consumer_try_wait(load_wait_state);
    }
    // Begin the wait for the accumulator results
    ConsumerToken acc_wait_token = acc_pipeline.consumer_try_wait(acc_pipe_consumer_state);

    // For each epilogue subtile within the CTA tile
    CUTLASS_PRAGMA_UNROLL
    for (int iter_n = 0; iter_n < size<3>(gD_real_epi); ++iter_n) {
      CUTLASS_PRAGMA_UNROLL
      for (int iter_m = 0; iter_m < size<2>(gD_real_epi); ++iter_m) {
        int epi_m = iter_m, epi_n = iter_n;
        bool is_first_iteration = iter_m == 0 && iter_n == 0;
        bool is_last_iteration = iter_m == size<2>(gD_real_epi)-1 && iter_n == size<3>(gD_real_epi)-1;
        bool do_acc_release = is_last_iteration;

        // Reverse subtile order for tmem reuse if necessary
        if constexpr (ReuseTmem) {
          if (reverse_epi_n) {
            epi_n = size<3>(gD_real_epi) - 1 - iter_n;
          }
          do_acc_release = iter_m == size<2>(gD_real_epi)-1 && iter_n == 0;
        }

        if (is_source_needed) {
          // Wait for the producer load to fill smem
          load_pipeline.consumer_wait(load_wait_state, load_wait_token);

          // Copy source tile from smem to register // residual smem -> reg
          copy(tiled_s2r, tSR_sC_real(_,_,_,load_wait_state.index()), tSR_rC(_,_,_,0));
          copy(tiled_s2r, tSR_sC_imag(_,_,_,load_wait_state.index()), tSR_rC(_,_,_,1));
        }

        if (is_source_needed) {
          // Let producer load warp know smem buffers are consumed and empty
          if constexpr (not ReuseSmemC) {
            cutlass::arch::fence_view_async_shared();
            load_pipeline.consumer_release(load_pipe_consumer_state);
            ++load_pipe_consumer_state;
          }
          ++load_wait_state;
        }

        if (is_first_iteration) {
          // Wait for mma warp to fill tmem buffer with accumulator results
          acc_pipeline.consumer_wait(acc_pipe_consumer_state, acc_wait_token);
        }

        // The current tile in tmem
        Tensor tTR_tAcc_real_mn = tTR_tAcc_real(_,_,_,epi_m,epi_n);
        Tensor tTR_tAcc_imag_mn = tTR_tAcc_imag(_,_,_,epi_m,epi_n);

        // Compute tmem load predication if necessary
        if constexpr (predicate_tmem_load) {
          // Issue tmem load if this tile's tmem subpartition is accessible by this warp
          int subpart_idx = (tTR_tAcc_real_mn.data().dp_ / 32) % 4;
          issue_tmem_load = warp_idx == subpart_idx;
        }

        // Copy accumulator tile from tmem to register
        if (issue_tmem_load) { // acc tmem -> reg
          copy(tiled_t2r, tTR_tAcc_real_mn, tTR_rAcc(_,_,_,0));
          copy(tiled_t2r, tTR_tAcc_imag_mn, tTR_rAcc(_,_,_,1));
        }

        // After the last tmem load, signal that tmem buffer is consumed and empty
        if (do_acc_release) {
          cutlass::arch::fence_view_async_tmem_load();
          acc_pipeline.consumer_release(acc_pipe_consumer_state);
          ++acc_pipe_consumer_state;
        }

        // Vectorized fragment loop with visitor callback entry point
        if (epilogue_op.is_source_needed()) {
          CUTLASS_PRAGMA_UNROLL
          for (int i = 0; i < size(tTR_rD_frg); ++i) {
            tTR_rD_frg(i) = epilogue_op(tTR_rAcc_frg(i), tTR_rC_frg(i));
          }
        } else {
          CUTLASS_PRAGMA_UNROLL
          for (int i = 0; i < size(tTR_rD_frg); ++i) {
            tTR_rD_frg(i) = epilogue_op(tTR_rAcc_frg(i));
          }
        }

        if constexpr (DelayTmaStore) {
          // Issue TMA stores for the previous subtile
          if (not is_first_iteration) {
            tma_store_fn(epi_m_prev, epi_n_prev);
          }
          epi_m_prev = epi_m;
          epi_n_prev = epi_n;
        }

        // Copy output tile from register to smem
        bool issue_smem_store = issue_tmem_load;
        if (issue_smem_store) { //  after scale, reg -> smem
          copy(tiled_r2s, tRS_rD(_,_,_,0), tRS_sD_real(_,_,_,store_pipe_producer_state.index()));
          copy(tiled_r2s, tRS_rD(_,_,_,1), tRS_sD_imag(_,_,_,store_pipe_producer_state.index()));
        }

        if constexpr (not DelayTmaStore) {
          // Issue TMA stores for this subtile
          tma_store_fn(epi_m, epi_n);
        }

        if (is_source_needed) {
          // Begin the wait for the next subtile producer load
          load_wait_token = load_pipeline.consumer_try_wait(load_wait_state, is_last_iteration);
        }
      } // for epi_m
    } // for epi_n

    if constexpr (DelayTmaStore) {
      // Issue TMA stores for the last subtile
      tma_store_fn(epi_m_prev, epi_n_prev);
    }

    return cute::make_tuple(load_pipe_consumer_state, store_pipe_producer_state, acc_pipe_consumer_state);
  }

  template <class CtaTileMNK>
  CUTLASS_DEVICE void
  store_tail(
      LoadPipeline load_pipeline,
      LoadPipelineState load_pipe_consumer_state,
      StorePipeline store_pipeline,
      StorePipelineState store_pipe_producer_state,
      CtaTileMNK cta_tile_mnk) {
    if constexpr (ReuseSmemC) {
      if (epilogue_op.is_source_needed()) {
        // wait for all TMA stores to complete
        store_pipeline.producer_tail(store_pipe_producer_state);

        // Issue releases on up to StagesD-1 previously issued TMA stores
        constexpr int release_stages = cute::min(StorePipeline::UnacquiredStages, get_load_pipe_increment(cta_tile_mnk));
        CUTLASS_PRAGMA_UNROLL
        for (int stage = 0; stage < release_stages; ++stage) {
          load_pipeline.consumer_release(load_pipe_consumer_state);
          ++load_pipe_consumer_state;
        }
      }
    }
  }

private:
  Params const& params;
  ThreadEpilogueOp epilogue_op;
};


/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::epilogue::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
