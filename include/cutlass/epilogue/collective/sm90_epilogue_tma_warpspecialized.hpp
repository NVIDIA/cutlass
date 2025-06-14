/***************************************************************************************************
 * Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/cutlass.h"
#include "cutlass/arch/barrier.h"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/detail.hpp"
#include "cutlass/epilogue/thread/scale_type.h"
#include "cutlass/epilogue/fusion/callbacks.hpp"
#include "cutlass/trace.h"

#include "cute/tensor.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace epilogue {
namespace collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  int StagesC_,
  int StagesD_,
  int FragmentSize_,
  bool ReuseSmemC_,
  class CtaTileMNK_,   //     (CTA_M,CTA_N,CTA_K)
  class EpilogueTile_, // (EPI_TILE_M,EPI_TILE_N)
  class ElementC_,
  class StrideC_,
  class ElementD_,
  class StrideD_,
  class FusionCallbacks_,
  class CopyOpG2S_,
  class SmemLayoutAtomC_,
  class CopyOpS2R_,
  class CopyOpS2G_,
  class SmemLayoutAtomD_,
  class CopyOpR2S_
>
class CollectiveEpilogue<
    Sm90TmaWarpSpecialized<StagesC_,StagesD_,FragmentSize_,ReuseSmemC_>,
    CtaTileMNK_,
    EpilogueTile_,
    ElementC_,
    StrideC_,
    ElementD_,
    StrideD_,
    FusionCallbacks_,
    CopyOpG2S_,
    SmemLayoutAtomC_,
    CopyOpS2R_,
    CopyOpS2G_,
    SmemLayoutAtomD_,
    CopyOpR2S_
> {
public:
  //
  // Type Aliases
  //
  using DispatchPolicy = Sm90TmaWarpSpecialized<StagesC_,StagesD_,FragmentSize_,ReuseSmemC_>;
  using CtaTileMNK = CtaTileMNK_;
  using EpilogueTile = EpilogueTile_;
  using FusionCallbacks = FusionCallbacks_;
  using ElementC = ElementC_;
  using StrideC = StrideC_;
  using ElementD = ElementD_;
  using StrideD = StrideD_;
  using CopyOpG2S = CopyOpG2S_;
  using SmemLayoutAtomC = SmemLayoutAtomC_;
  using CopyOpS2R = CopyOpS2R_;
  using CopyOpS2G = CopyOpS2G_;
  using SmemLayoutAtomD = SmemLayoutAtomD_;
  using CopyOpR2S = CopyOpR2S_;

  using ThreadEpilogueOp = typename epilogue::fusion::FusionCallbacksTraits<FusionCallbacks>::Operation;
  using GmemTiledCopyC = SM90_TMA_LOAD;
  using GmemTiledCopyD = SM90_TMA_STORE;

  static_assert(!is_layout<EpilogueTile>::value && is_tuple<EpilogueTile>::value, "EpilogueTile must be a cute::Tile or cute::Shape");
  static_assert(rank(CtaTileMNK{}) == 3, "CtaTileMNK must be rank-3: [CTA_M, CTA_N, CTA_K]");
  static_assert(rank(EpilogueTile{}) == 2, "EpilogueTile must be rank-2: [EPI_TILE_M, EPI_TILE_N]");
  static_assert(size<0>(CtaTileMNK{}) % size<0>(shape(EpilogueTile{})) == 0, "EPI_TILE_M must divide CTA_M");
  static_assert(size<1>(CtaTileMNK{}) % size<1>(shape(EpilogueTile{})) == 0, "EPI_TILE_N must divide CTA_N");
  static_assert(rank(StrideC{}) == 3, "StrideC must be rank-3: [M, N, L]");
  static_assert(rank(StrideD{}) == 3, "StrideD must be rank-3: [M, N, L]");

private:
  using InternalElementC = cute::conditional_t<cute::is_void_v<ElementC>,ElementD,ElementC>; // prevents void ref breakages
  constexpr static int StagesC = StagesC_;
  constexpr static int StagesD = StagesD_;
  constexpr static bool is_source_supported = not cute::is_void_v<ElementC>;

  // internal optimization to reuse C shared memory for storing D
  using SmemLayoutAtomBitsC = decltype(downcast<sizeof_bits<InternalElementC>::value>(SmemLayoutAtomC{}));
  using SmemLayoutAtomBitsD = decltype(downcast<sizeof_bits<ElementD>::value>(SmemLayoutAtomD{}));
  constexpr static bool support_smem_reuse = is_source_supported &&
                                              sizeof(InternalElementC) == sizeof(ElementD) &&
                                              StrideC{} == StrideD{} &&
                                              StagesD <= StagesC &&
                                              cute::is_same_v<SmemLayoutAtomBitsC,SmemLayoutAtomBitsD>;
  constexpr static bool ReuseSmemC = DispatchPolicy::ReuseSmemC;
  static_assert(not (ReuseSmemC && not support_smem_reuse), "Smem reuse requirements not met");

  constexpr static bool is_m_major_C = detail::is_m_major<StrideC>();
  constexpr static bool is_m_major_D = detail::is_m_major<StrideD>();

public:
  using SmemLayoutC = decltype(tile_to_shape(
      SmemLayoutAtomC{},
      make_shape(size<0>(EpilogueTile{}), size<1>(EpilogueTile{}), Int<StagesC>{}),
      cute::conditional_t<is_m_major_C, Step<_2,_1,_3>, Step<_1,_2,_3>>{} ));
  using SmemLayoutD = decltype(tile_to_shape(
      SmemLayoutAtomD{},
      make_shape(size<0>(EpilogueTile{}), size<1>(EpilogueTile{}), Int<StagesD>{}),
      cute::conditional_t<is_m_major_D, Step<_2,_1,_3>, Step<_1,_2,_3>>{} ));

  // TMA pipeline for loading C
  using LoadPipeline = cutlass::PipelineTransactionAsync<StagesC>;
  using LoadPipelineState = cutlass::PipelineState<StagesC>;
  constexpr static uint32_t TmaTransactionBytes =
    size(take<0,2>(SmemLayoutC{})) * static_cast<uint32_t>(sizeof(InternalElementC));

  // TMA pipeline for storing D
  using StorePipeline = cute::conditional_t<ReuseSmemC,
                          cutlass::PipelineTmaStore<StagesC, StagesD-1>,
                          cutlass::PipelineTmaStore<StagesD>>;
  using StorePipelineState = cutlass::PipelineState<ReuseSmemC ? StagesC : StagesD>;

  struct SharedStorage {
    struct TensorStorage : aligned_struct<128> {
      cute::conditional_t<not is_source_supported,
        detail::EmptyStorage<InternalElementC>,
        array_aligned<InternalElementC, size(SmemLayoutC{})>> smem_C;
      alignas(128) cute::conditional_t<ReuseSmemC,
        detail::EmptyStorage<ElementD>,
        array_aligned<ElementD, size(SmemLayoutD{})>> smem_D;

      using FusionStorage = typename FusionCallbacks::SharedStorage;
      alignas(128) FusionStorage thread;
    } tensors;

    using PipelineStorage = typename LoadPipeline::SharedStorage;
    PipelineStorage pipeline;
  };
  using TensorStorage = typename SharedStorage::TensorStorage;
  using PipelineStorage = typename SharedStorage::PipelineStorage;

  // Host side epilogue arguments
  struct Arguments {
    typename FusionCallbacks::Arguments thread{};
    ElementC const* ptr_C;
    StrideC dC;
    ElementD const* ptr_D;
    StrideD dD;
  };

  // Device side epilogue params
  struct Params {
    using TMA_C = decltype(make_tma_copy(
        CopyOpG2S{},
        make_tensor(static_cast<InternalElementC const*>(nullptr),
            repeat_like(StrideC{}, int32_t(0)), StrideC{}),
        SmemLayoutC{}(_,_,0)));
    using TMA_D = decltype(make_tma_copy(
        CopyOpS2G{},
        make_tensor(static_cast<ElementD const*>(nullptr),
            repeat_like(StrideD{}, int32_t(0)), StrideD{}),
        SmemLayoutD{}(_,_,0)));

    typename FusionCallbacks::Params thread{};
    TMA_C tma_load_c;
    TMA_D tma_store_d;
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

    typename Params::TMA_C tma_load_c;
    if constexpr (not cute::is_void_v<ElementC>) {
      Tensor tensor_c = make_tensor(args.ptr_C, make_layout(make_shape(M,N,L), args.dC));
      tma_load_c = make_tma_copy(CopyOpG2S{}, tensor_c, SmemLayoutC{}(_,_,0));
    }

    Tensor tensor_d = make_tensor(args.ptr_D, make_layout(make_shape(M,N,L), args.dD));
    typename Params::TMA_D tma_store_d = make_tma_copy(
        CopyOpS2G{},
        tensor_d,
        SmemLayoutD{}(_,_,0));

    return {
      FusionCallbacks::to_underlying_arguments(problem_shape, args.thread, workspace),
      tma_load_c,
      tma_store_d
    };
  }

  template<class ProblemShape>
  CUTLASS_HOST_DEVICE static bool
  can_implement(
      ProblemShape const& problem_shape,
      [[maybe_unused]] Arguments const& args) {
    constexpr int tma_alignment_bits = 128;
    auto problem_shape_MNKL = append<4>(problem_shape, 1);
    auto [M,N,K,L] = problem_shape_MNKL;
    
    constexpr int min_tma_aligned_elements_D = tma_alignment_bits / cutlass::sizeof_bits<ElementD>::value;
    bool implementable = cutlass::detail::check_alignment<min_tma_aligned_elements_D>(cute::make_shape(M,N,L), StrideD{});

    if constexpr (not cute::is_void_v<ElementC>) {
      constexpr int min_tma_aligned_elements_C = tma_alignment_bits / cutlass::sizeof_bits<ElementC>::value;
      implementable = implementable && cutlass::detail::check_alignment<min_tma_aligned_elements_C>(cute::make_shape(M,N,L), StrideC{});
    }

    if (!implementable) {
      CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Problem Size doesn't meet the minimum alignment requirements for TMA.\n");
    }

    return implementable;
  }

  template<class TileShapeMNK>
  CUTLASS_HOST_DEVICE
  static constexpr int
  get_load_pipe_increment(TileShapeMNK tile_shape_MNK) {
    // Compute number of epilogue subtiles
    constexpr int epi_m = size<0>(tile_shape_MNK) / size<0>(EpilogueTile{});
    constexpr int epi_n = size<1>(tile_shape_MNK) / size<1>(EpilogueTile{});
    
    return epi_m * epi_n;
  }

  template<class TileShapeMNK>
  CUTLASS_HOST_DEVICE
  static constexpr int
  get_store_pipe_increment(TileShapeMNK tile_shape_MNK) {
    return get_load_pipe_increment(tile_shape_MNK);
  }

  /// Issue Tma Descriptor Prefetch -- ideally from a single thread for best performance
  CUTLASS_DEVICE
  static void
  prefetch_tma_descriptors(Params const& epilogue_params) {
    cute::prefetch_tma_descriptor(epilogue_params.tma_load_c.get_tma_descriptor());
    cute::prefetch_tma_descriptor(epilogue_params.tma_store_d.get_tma_descriptor());
  }

  CUTLASS_HOST_DEVICE
  CollectiveEpilogue(Params const& params_, TensorStorage& shared_tensors)
      : params(params_), fusion_callbacks(params_.thread, shared_tensors.thread) {}

  CUTLASS_DEVICE
  bool
  is_producer_load_needed() const {
    return fusion_callbacks.is_producer_load_needed();
  }

  template<
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class TiledMma
  >
  CUTLASS_DEVICE auto
  load(
      LoadPipeline load_pipeline,
      LoadPipelineState load_pipe_producer_state,
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_MNK,
      TileCoordMNKL tile_coord_mnkl,
      TiledMma tiled_mma,
      int thread_idx,
      TensorStorage& shared_tensors) {
    using namespace cute;
    using _X = Underscore;

    // Indexing variables
    auto [M, N, K, L] = problem_shape_mnkl;
    auto [m_coord, n_coord, k_coord, l_coord] = tile_coord_mnkl;

    // Represent the full source tensor, slice to get the tile this CTA is currently responsible for
    Tensor mC_mnl = params.tma_load_c.get_tma_tensor(make_shape(M,N,L));                        //              (M,N,L)
    Tensor gC_mnl = local_tile(mC_mnl, tile_shape_MNK, make_coord(_,_,_), Step<_1,_1,_X>{});    //  (CTA_M,CTA_N,m,n,l)
    Tensor gC = gC_mnl(_,_,m_coord,n_coord,l_coord);                                            //        (CTA_M,CTA_N)

    // Apply epilogue subtile, get matching smem tensor
    auto ptr_sC = make_smem_ptr(shared_tensors.smem_C.data());
    Tensor gC_epi = local_tile(gC, EpilogueTile{}, _);                           // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)
    Tensor sC_epi = make_tensor(ptr_sC, SmemLayoutC{});                          // (EPI_TILE_M,EPI_TILE_N,PIPE_C)

    // Prepare the thread(b)lock's (G)mem to (S)mem TMA tiled copy (bGS_)
    ThrCopy thrblk_g2s = params.tma_load_c.get_slice(Int<0>{});
    Tensor bGS_gC = thrblk_g2s.partition_S(gC_epi);                                    // (G2S,G2S_M,G2S_N,EPI_M,EPI_N)
    Tensor bGS_sC = thrblk_g2s.partition_D(sC_epi);                                    // (G2S,G2S_M,G2S_N,PIPE_C)

    // Get the fusion callbacks for the producer load warp
    auto pld_callbacks = fusion_callbacks.get_producer_load_callbacks(
                              problem_shape_mnkl,
                              CtaTileMNK{},
                              tile_coord_mnkl,
                              EpilogueTile{},
                              thread_idx);
    bool is_C_load_needed = is_source_supported && fusion_callbacks.is_C_load_needed();

    // Predication for TMA load (one thread issues TMA load)
    bool issue_tma_load = cute::elect_one_sync();

    // Acquire the lock for the first stage
    uint64_t* tma_barrier = load_pipeline.producer_get_barrier(load_pipe_producer_state);
    load_pipeline.producer_acquire(load_pipe_producer_state);

    // Pre-loop fusion callback entry point
    pld_callbacks.begin(tma_barrier, load_pipe_producer_state.count(), issue_tma_load);

    CUTLASS_PRAGMA_UNROLL
    for (int epi_n = 0; epi_n < size<3>(gC_epi); ++epi_n) {
      CUTLASS_PRAGMA_UNROLL
      for (int epi_m = 0; epi_m < size<2>(gC_epi); ++epi_m) {
        // Acquire the lock for this stage
        constexpr uint16_t mcast_mask = 0;
        uint64_t* tma_barrier = load_pipeline.producer_get_barrier(load_pipe_producer_state);
        load_pipeline.producer_acquire(load_pipe_producer_state);

        // Loop fusion callback entry point
        pld_callbacks.step(tma_barrier, epi_m, epi_n, load_pipe_producer_state.count(), issue_tma_load);

        // Execute the TMA load for C if needed
        if (issue_tma_load && is_C_load_needed) {
          copy(params.tma_load_c.with(*tma_barrier, mcast_mask),
              bGS_gC(_,_,_,epi_m,epi_n), bGS_sC(_,_,_,load_pipe_producer_state.index()));
          load_pipeline.producer_expect_transaction(load_pipe_producer_state);
        }

        // Commit TMA loads for this stage and release the lock
        load_pipeline.producer_commit(load_pipe_producer_state);
        ++load_pipe_producer_state;
      }
    }

    // Post-loop fusion callback entry point
    pld_callbacks.end();

    return load_pipe_producer_state;
  }

  CUTLASS_DEVICE auto
  load_tail(
      LoadPipeline load_pipeline,
      LoadPipelineState load_pipe_producer_state) {
    bool issue_tma_load = cute::elect_one_sync();
    if (issue_tma_load) {
      load_pipeline.producer_tail(load_pipe_producer_state);
    }

    return load_pipe_producer_state;
  }

  template<
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class AccEngine, class AccLayout,
    class TiledMma
  >
  CUTLASS_DEVICE auto
  store(
      LoadPipeline load_pipeline,
      LoadPipelineState load_pipe_consumer_state,
      StorePipeline store_pipeline,
      StorePipelineState store_pipe_producer_state,
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_MNK,
      TileCoordMNKL tile_coord_mnkl,
      cute::Tensor<AccEngine,AccLayout> accumulators,
      TiledMma tiled_mma,
      int thread_idx,
      TensorStorage& shared_tensors) {
    using namespace cute;
    using _X = Underscore;
    using ElementAccumulator = typename AccEngine::value_type;

    static_assert(is_rmem<AccEngine>::value, "Accumulator must be RF resident.");
    static_assert(rank(AccLayout{}) == 3, "Accumulator must be MMA-partitioned: (MMA,MMA_M,MMA_N)");
    static_assert(rank(ProblemShapeMNKL{}) == 4, "ProblemShapeMNKL must be rank 4");
    static_assert(is_static<TileShapeMNK>::value, "TileShapeMNK must be static");
    static_assert(rank(TileShapeMNK{}) == 3, "TileShapeMNK must be rank 3");
    static_assert(rank(TileCoordMNKL{}) == 4, "TileCoordMNKL must be rank 4");

    // Indexing variables
    auto [M, N, K, L] = problem_shape_mnkl;
    auto [m_coord, n_coord, k_coord, l_coord] = tile_coord_mnkl;
    auto mma_tile_m = size<0>(typename TiledMma::TiledShape_MNK{});
    auto mma_tile_n = size<1>(typename TiledMma::TiledShape_MNK{});
    auto epi_tile_m = size<0>(EpilogueTile{});
    auto epi_tile_n = size<1>(EpilogueTile{});

    // Represent the full output tensor, slice to get the tile this CTA is responsible for
    Tensor mD_mnl = params.tma_store_d.get_tma_tensor(make_shape(M,N,L));                                    // (M,N,L)
    Tensor gD_mnl = local_tile(mD_mnl, tile_shape_MNK, make_coord(_,_,_), Step<_1,_1,_X>{});     // (CTA_M,CTA_N,m,n,l)
    Tensor gD = gD_mnl(_,_,m_coord,n_coord,l_coord);                                                   // (CTA_M,CTA_N)

    // Apply epilogue subtiling, construct corresponding pipelined smem tensors
    auto ptr_sC = make_smem_ptr(shared_tensors.smem_C.data());
    auto ptr_sD = make_smem_ptr(shared_tensors.smem_D.data());
    Tensor gD_epi = local_tile(gD, EpilogueTile{}, _);                           // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)
    Tensor sC_epi = make_tensor(ptr_sC, SmemLayoutC{});                          // (EPI_TILE_M,EPI_TILE_N,PIPE_C)
    Tensor sD_epi = make_tensor(ptr_sD, SmemLayoutD{});                          // (EPI_TILE_M,EPI_TILE_N,PIPE_D)

    // Get the smallest tiled copy we can use to retile the accumulators
    using CopyAtomC = Copy_Atom<SM90_U32x4_STSM_N, cutlass::half_t>;
    TiledCopy tiled_copy_C_atom = make_tiled_copy_C_atom(CopyAtomC{}, tiled_mma);

    // (t)hread-partition for (r)egister to (s)mem copy (tRS_)
    TiledCopy tiled_r2s = make_tiled_copy_S(Copy_Atom<CopyOpR2S,ElementD>{}, tiled_copy_C_atom);
    ThrCopy thread_r2s = tiled_r2s.get_slice(thread_idx);
    Tensor tRS_rAcc = thread_r2s.retile_S(accumulators);                                   // ((R2S,R2S_V),MMA_M,MMA_N)
    Tensor tRS_sD   = conditional_return<ReuseSmemC>(
                      thread_r2s.partition_D(recast<ElementD>(sC_epi)),                     // (R2S,R2S_M,R2S_N,PIPE_C)
                      thread_r2s.partition_D(sD_epi) );                                     // (R2S,R2S_M,R2S_N,PIPE_D)

    // Allocate register tensors
    auto tRS_rD_shape = take<0,3>(shape(thread_r2s.partition_S(sD_epi)));
    Tensor tRS_rC = make_tensor<InternalElementC>(tRS_rD_shape);                                   // (R2S,R2S_M,R2S_N)
    Tensor tRS_rD = make_tensor<ElementD        >(tRS_rD_shape);                                   // (R2S,R2S_M,R2S_N)

    // Vectorized fragment view
    constexpr int FragmentSize = DispatchPolicy::FragmentSize;
    Tensor tRS_rAcc_frg = recast<Array<ElementAccumulator, FragmentSize>>(tRS_rAcc);
    Tensor tRS_rD_frg   = recast<Array<ElementD          , FragmentSize>>(tRS_rD);
    CUTE_STATIC_ASSERT(size<0>(tRS_rAcc) % FragmentSize == 0, "Fragment size does not vectorize properly");

    // (t)hread-partition for (s)mem to (r)egister copy (tSR_)
    TiledCopy tiled_s2r = make_tiled_copy_S(Copy_Atom<CopyOpS2R,InternalElementC>{}, tiled_copy_C_atom);
    ThrCopy thread_s2r = tiled_s2r.get_slice(thread_idx);
    Tensor tSR_sC = thread_s2r.partition_S(sC_epi);                                         // (S2R,S2R_M,S2R_N,PIPE_C)
    Tensor tSR_rC = thread_s2r.retile_D(tRS_rC);                                            // (S2R,S2R_M,S2R_N)

    // thread(b)lock-partition for (s)mem to (g)mem copy (bSG_)
    ThrCopy thrblk_s2g = params.tma_store_d.get_slice(Int<0>{});
    Tensor bSG_sD = conditional_return<ReuseSmemC>(
                    thrblk_s2g.partition_S(recast<ElementD>(sC_epi)),                  // (S2G,S2G_M,S2G_N,PIPE_C)
                    thrblk_s2g.partition_S(sD_epi) );                                  // (S2G,S2G_M,S2G_N,PIPE_D)
    Tensor bSG_gD = thrblk_s2g.partition_D(gD_epi);                                    // (S2G,S2G_M,S2G_N,EPI_M,EPI_N)

    CUTE_STATIC_ASSERT(mma_tile_m == epi_tile_m, "EPI_TILE_M must equal MMA_TILE_M");
    CUTE_STATIC_ASSERT(mma_tile_n % epi_tile_n == 0, "EPI_TILE_N must divide MMA_TILE_N");

    // Get the fusion callbacks for the consumer store warps
    constexpr bool RefSrc = true; // Register tensors reference R2S copy src layout
    auto cst_callbacks = fusion_callbacks.get_consumer_store_callbacks<RefSrc>(
                              problem_shape_mnkl,
                              CtaTileMNK{},
                              tile_coord_mnkl,
                              EpilogueTile{},
                              tiled_copy_C_atom,
                              thread_idx,
                              tRS_rC);
    bool is_producer_load_needed = fusion_callbacks.is_producer_load_needed();
    bool is_C_load_needed = is_source_supported && fusion_callbacks.is_C_load_needed();

    // Thread synchronizer for previously issued waits or fences
    // to ensure visibility of smem reads/writes to threads or TMA unit
    auto synchronize = [&] () { cutlass::arch::NamedBarrier::sync(size(TiledMma{}), 0); };

    // Predication for TMA store (one warp issues TMA store)
    bool issue_tma_store = (thread_idx / NumThreadsPerWarp) == 0;

    // In the reuse smem configuration we have StagesC smem buffers and at most StagesD committed TMA stores in flight.
    // The TMA store pipeline producer acquire returns when at most StagesD-1 committed stores are in-flight, so we can
    // only guarantee store completion after StagesD iterations, then we can begin issuing releases on the smem buffer locks.
    // store_pipe_producer_state tracks the acquire and load_pipe_consumer_state tracks the release, in circular buffer fashion.
    LoadPipelineState load_wait_state = load_pipe_consumer_state;
    if constexpr (ReuseSmemC) {
      load_wait_state = store_pipe_producer_state;
      load_wait_state.phase_ ^= 1;
    }

    //
    // BEGIN EPILOGUE
    //

    // Pre-loop fusion callback entry point
    cst_callbacks.begin();

    // For each output tile
    CUTLASS_PRAGMA_UNROLL
    for (int epi_n = 0; epi_n < size<3>(gD_epi); ++epi_n) {
      CUTLASS_PRAGMA_UNROLL
      for (int epi_m = 0; epi_m < size<2>(gD_epi); ++epi_m) {
        // The current tile in accumulator
        int mma_m = epi_m;
        int mma_n = (epi_n * epi_tile_n) / mma_tile_n;
        Tensor tRS_rAcc_frg_mn = tRS_rAcc_frg(_,mma_m,mma_n);

        // Wait for a smem buffer to be available
        if (issue_tma_store) {
          store_pipeline.producer_acquire(store_pipe_producer_state);
        }
        synchronize();

        if constexpr (ReuseSmemC) {
          // Let dma warp know smem buffer is consumed and empty after StagesD producer commits
          if (issued_stores >= StagesD) {
            if (is_producer_load_needed) {
              load_pipeline.consumer_release(load_pipe_consumer_state);
            }
            ++load_pipe_consumer_state;
          }
        }

        if (is_producer_load_needed) {
          // Wait for the producer load to fill smem
          load_pipeline.consumer_wait(load_wait_state);

          if (is_C_load_needed) {
            // Copy source tile from smem to register
            copy(tiled_s2r, tSR_sC(_,_,_,load_wait_state.index()), tSR_rC);
          }
        }

        // First loop fusion callback entry point
        cst_callbacks.step_begin(epi_m, epi_n, load_wait_state.count(), is_producer_load_needed);

        if (is_producer_load_needed) {
          if constexpr (not ReuseSmemC) {
            // Let producer load warp know smem buffers are consumed and empty
            cutlass::arch::fence_view_async_shared();
            load_pipeline.consumer_release(load_pipe_consumer_state);
            ++load_pipe_consumer_state;
          }
          ++load_wait_state;
        }

        // Vectorized fragment loop with visitor callback entry point
        int r2s_v = epi_n * size(tRS_rD_frg);
        CUTLASS_PRAGMA_UNROLL
        for (int epi_v = 0; epi_v < size(tRS_rD_frg); ++epi_v) {
          tRS_rD_frg(epi_v) = cst_callbacks.visit(tRS_rAcc_frg_mn(r2s_v + epi_v), epi_v, epi_m, epi_n);
        }

        // Copy tile from register to smem
        copy(tiled_r2s, tRS_rD, tRS_sD(_,_,_,store_pipe_producer_state.index()));

        // Next loop fusion callback entry point
        constexpr bool issue_smem_store = true; // No smem store predication
        cst_callbacks.step_next(epi_m, epi_n, store_pipe_producer_state.count(), issue_smem_store);

        // Write the tile from smem to gmem with TMA
        cutlass::arch::fence_view_async_shared(); // ensure smem writes are visible to TMA
        synchronize(); // ensure all threads have issued their async fence
        if (issue_tma_store) {
          copy(params.tma_store_d, bSG_sD(_,_,_,store_pipe_producer_state.index()), bSG_gD(_,_,_,epi_m,epi_n));
        }

        // Last loop fusion callback entry point
        cst_callbacks.step_end(epi_m, epi_n, store_pipe_producer_state.count(), issue_tma_store);

        // Commit the TMA stores for this stage
        if (issue_tma_store) {
          store_pipeline.producer_commit(store_pipe_producer_state);
        }
        ++store_pipe_producer_state;
        ++issued_stores;
      } // for epi_m
    } // for epi_n

    // Post-loop fusion callback entry point
    cst_callbacks.end();

    return cute::make_tuple(load_pipe_consumer_state, store_pipe_producer_state);
  }

  CUTLASS_DEVICE auto
  store_tail(
      LoadPipeline load_pipeline,
      LoadPipelineState load_pipe_consumer_state,
      StorePipeline store_pipeline,
      StorePipelineState store_pipe_producer_state) {
    // wait for all TMA stores to complete
    store_pipeline.producer_tail(store_pipe_producer_state);
    // reset store counter
    issued_stores = 0;

    if constexpr (ReuseSmemC) {
      if (fusion_callbacks.is_producer_load_needed()) {
        // Issue releases on up to StagesD previously issued TMA stores
        constexpr int release_stages =
          cute::min(StagesD, get_load_pipe_increment(CtaTileMNK{}));
        CUTLASS_PRAGMA_UNROLL
        for (int stage = 0; stage < release_stages; ++stage) {
          load_pipeline.consumer_release(load_pipe_consumer_state);
          ++load_pipe_consumer_state;
        }
      }
    }

    return cute::make_tuple(load_pipe_consumer_state, store_pipe_producer_state);
  }

private:
  Params const& params;
  FusionCallbacks fusion_callbacks;
  int issued_stores = 0;
};


/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace collective
} // namespace epilogue
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
