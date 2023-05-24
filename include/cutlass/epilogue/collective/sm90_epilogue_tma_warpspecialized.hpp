/***************************************************************************************************
 * Copyright (c) 2023, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
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

#include "cute/tensor.hpp"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace epilogue {
namespace collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  int StagesC_,
  int StagesD_,
  bool DisableSmemReuseC_,
  class BlockTileShape_,    //     (BLK_M,BLK_N,BLK_K)
  class EpilogueTileShape_, // (EPI_TILE_M,EPI_TILE_N)
  class ElementC_,
  class StrideC_,
  class ElementD_,
  class StrideD_,
  class ThreadEpilogueOp_,
  class CopyOpG2S_,
  class SmemLayoutAtomC_,
  class CopyOpS2R_,
  class CopyOpS2G_,
  class SmemLayoutAtomD_,
  class CopyOpR2S_
>
class CollectiveEpilogue<
    Sm90TmaWarpSpecialized<StagesC_,StagesD_,DisableSmemReuseC_>,
    BlockTileShape_,
    EpilogueTileShape_,
    ElementC_,
    StrideC_,
    ElementD_,
    StrideD_,
    ThreadEpilogueOp_,
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
  using DispatchPolicy = Sm90TmaWarpSpecialized<StagesC_,StagesD_,DisableSmemReuseC_>;
  using BlockTileShape = BlockTileShape_;
  using EpilogueTileShape = EpilogueTileShape_;
  using ThreadEpilogueOp = ThreadEpilogueOp_;
  using ElementAccumulator = typename ThreadEpilogueOp::ElementAccumulator;
  using ElementCompute = typename ThreadEpilogueOp::ElementCompute;
  using ElementScalar = ElementCompute;
  using ElementBias = typename detail::IsThreadEpilogueOpWithBias<ThreadEpilogueOp>::type;
  using ElementOutput = typename ThreadEpilogueOp::ElementOutput;
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

  using GmemTiledCopyC = SM90_TMA_LOAD;
  using GmemTiledCopyD = SM90_TMA_STORE;

  constexpr static int kOutputAlignment = ThreadEpilogueOp::kCount;
  constexpr static bool iskThreadEpilogueOpWithBias = detail::IsThreadEpilogueOpWithBias<ThreadEpilogueOp>::value;
  using AlignmentType = typename uint_bit<sizeof_bits<ElementOutput>::value * kOutputAlignment>::type;

  static_assert(!is_layout<EpilogueTileShape>::value && is_tuple<EpilogueTileShape>::value, "EpilogueTileShape must be a cute::Shape");
  static_assert(rank(BlockTileShape{}) == 3, "BlockTileShape must be rank-3: [BLK_M,BLK_N,BLK_K]");
  static_assert(rank(EpilogueTileShape{}) == 2, "EpilogueTileShape must be rank-2: [EPI_TILE_M,EPI_TILE_N]");
  static_assert(rank(StrideC{}) == 3, "StrideCD must be rank-3: [M, N, L]");
  static_assert(rank(StrideD{}) == 3, "StrideCD must be rank-3: [M, N, L]");

private:
  using InternalElementC = cute::conditional_t<cute::is_void_v<ElementC>,ElementD,ElementC>; // prevents void ref breakages
  constexpr static int StagesC = StagesC_;
  constexpr static int StagesD = StagesD_;
  constexpr static bool is_source_supported = ThreadEpilogueOp::kScale == cutlass::epilogue::thread::ScaleType::Default ||
                                              ThreadEpilogueOp::kScale == cutlass::epilogue::thread::ScaleType::NoBetaScaling;
  static_assert((cute::is_void_v<ElementC> && not is_source_supported) || (not cute::is_void_v<ElementC> && is_source_supported),
                "Inconsistent C type and Scale kind");

  // internal optimization to reuse C shared memory for storing D
  using SmemLayoutAtomBitsC = decltype(downcast<sizeof_bits<InternalElementC>::value>(SmemLayoutAtomC{}));
  using SmemLayoutAtomBitsD = decltype(downcast<sizeof_bits<ElementD>::value>(SmemLayoutAtomD{}));
  constexpr static bool ReuseSmemC = not DispatchPolicy::DisableSmemReuseC &&
                                     is_source_supported &&
                                     sizeof(InternalElementC) == sizeof(ElementD) &&
                                     StrideC{} == StrideD{} &&
                                     cute::is_same_v<SmemLayoutAtomBitsC,SmemLayoutAtomBitsD>;

public:
  using SmemLayoutC = decltype(tile_to_shape(
      SmemLayoutAtomC{},
      make_shape(size<0>(BlockTileShape{}), size<1>(BlockTileShape{}), Int<StagesC>{}),
      cute::conditional_t<get<0>(StrideC{}) == 1, Step<_2,_1,_3>, Step<_1,_2,_3>>{} ));
  using SmemLayoutD = decltype(tile_to_shape(
      SmemLayoutAtomD{},
      make_shape(size<0>(EpilogueTileShape{}), size<1>(EpilogueTileShape{}), Int<StagesD>{}),
      cute::conditional_t<get<0>(StrideD{}) == 1, Step<_2,_1,_3>, Step<_1,_2,_3>>{} ));

  // TMA pipeline for loading C
  using LoadPipeline = cutlass::PipelineTransactionAsync<is_source_supported ? StagesC : 0>;
  using LoadPipelineState = cutlass::PipelineState<is_source_supported ? StagesC : 0>;
  constexpr static uint32_t TmaTransactionBytes =
    size(take<0,2>(SmemLayoutC{})) * static_cast<uint32_t>(sizeof(InternalElementC));

  // TMA pipeline for storing D
  using StorePipeline = cutlass::PipelineTmaStore<ReuseSmemC ? StagesC : StagesD>;
  using StorePipelineState = cutlass::PipelineState<ReuseSmemC ? StagesC : StagesD>;

  struct SharedStorage {
    struct TensorStorage : aligned_struct<128> {
      cute::conditional_t<not is_source_supported,
        detail::EmptyStorage<InternalElementC>,
        array_aligned<InternalElementC, size(SmemLayoutC{})>> smem_C;
      alignas(128) cute::conditional_t<ReuseSmemC,
        detail::EmptyStorage<ElementD>,
        array_aligned<ElementD, size(SmemLayoutD{})>> smem_D;
    } tensors;

    using PipelineStorage = typename LoadPipeline::SharedStorage;
    PipelineStorage pipeline;
  };
  using TensorStorage = typename SharedStorage::TensorStorage;
  using PipelineStorage = typename SharedStorage::PipelineStorage;

  // Host side epilogue arguments
  struct Arguments {
    typename ThreadEpilogueOp::Params thread;
    ElementC const* ptr_C;
    StrideC dC;
    ElementD const* ptr_D;
    StrideD dD;
  };

  // Device side epilgoue params
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

    typename ThreadEpilogueOp::Params thread{};
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
    // Optionally append _1s until problem shape is rank-4 in case its is only rank-3 (MNK)
    auto problem_shape_MNKL = append<4>(problem_shape, Int<1>{});
    auto M = get<0>(problem_shape_MNKL);
    auto N = get<1>(problem_shape_MNKL);
    auto L = get<3>(problem_shape_MNKL);

    typename Params::TMA_C tma_load_c = [&]() {
      if constexpr (not cute::is_void_v<ElementC>) {
        Tensor tensor_c = make_tensor(static_cast<InternalElementC const*>(args.ptr_C), make_layout(make_shape(M,N,L), args.dC));
        return make_tma_copy(
            CopyOpG2S{},
            tensor_c,
            SmemLayoutC{}(_,_,0));
      }
      else {
        return typename Params::TMA_C{};
      }
    }();

    Tensor tensor_d = make_tensor(args.ptr_D, make_layout(make_shape(M,N,L), args.dD));
    typename Params::TMA_D tma_store_d = make_tma_copy(
        CopyOpS2G{},
        tensor_d,
        SmemLayoutD{}(_,_,0));

    return {
      args.thread,
      tma_load_c,
      tma_store_d
    };
  }

  template<class TileShapeMNK>
  CUTLASS_HOST_DEVICE
  static constexpr int
  get_load_pipe_increment(TileShapeMNK tile_shape_MNK) {
    // Compute number of C subtiles (currently always one)
    constexpr int epi_m = size<0>(tile_shape_MNK) / size<0>(SmemLayoutC{});
    constexpr int epi_n = size<1>(tile_shape_MNK) / size<1>(SmemLayoutC{});
    
    return epi_m * epi_n;
  }

  template<class TileShapeMNK>
  CUTLASS_HOST_DEVICE
  static constexpr int
  get_store_pipe_increment(TileShapeMNK tile_shape_MNK) {
    if constexpr (ReuseSmemC) {
      return get_load_pipe_increment(tile_shape_MNK);
    }

    // Compute number of D subtiles
    constexpr int epi_m = size<0>(tile_shape_MNK) / size<0>(SmemLayoutD{});
    constexpr int epi_n = size<1>(tile_shape_MNK) / size<1>(SmemLayoutD{});
    
    return epi_m * epi_n;
  }

  CUTLASS_HOST_DEVICE
  CollectiveEpilogue(Params const& params_)
      : params(params_), epilogue_op(params_.thread) { }

  CUTLASS_DEVICE
  bool
  is_source_needed() {
    return epilogue_op.is_source_needed();
  }

  /// Issue Tma Descriptor Prefetch -- ideally from a single thread for best performance
  CUTLASS_DEVICE
  static void prefetch_tma_descriptors(Params const& epilogue_params) {
    cute::prefetch_tma_descriptor(epilogue_params.tma_load_c.get_tma_descriptor());
    cute::prefetch_tma_descriptor(epilogue_params.tma_store_d.get_tma_descriptor());
  }

  template<
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class TiledMma
  >
  CUTLASS_DEVICE void
  load(
      LoadPipeline load_pipeline,
      LoadPipelineState load_pipe_producer_state,
      ProblemShapeMNKL problem_shape_mnkl,
      TileShapeMNK tile_shape_MNK,
      TileCoordMNKL tile_coord_mnkl,
      TiledMma tiled_mma,
      [[maybe_unused]] int thread_idx,
      TensorStorage& shared_tensors) {
    using namespace cute;
    using X = Underscore;

    int warp_idx = canonical_warp_idx();
    int warp_idx_in_warp_group = warp_idx % 4;
    int lane_predicate = cute::elect_one_sync();

    auto M = get<0>(problem_shape_mnkl);
    auto N = get<1>(problem_shape_mnkl);
    auto L = get<3>(problem_shape_mnkl);
    auto [m_coord, n_coord, k_coord, l_coord] = tile_coord_mnkl;

    // Represent the full source tensor
    Tensor mC_mnl = params.tma_load_c.get_tma_tensor(make_shape(M,N,L));                       //               (m,n,l)
    Tensor gC_mnl = local_tile(mC_mnl, tile_shape_MNK, make_coord(_,_,_), Step<_1,_1, X>{});   // (TILE_M,TILE_N,m,n,l)
    // Slice to get the gmem tile of C (gC) this CTA is currently responsible for
    Tensor gC = gC_mnl(_,_,m_coord,n_coord,l_coord);                                           //       (TILE_M,TILE_N)
    // Get the corresponding smem tile of C (sC)
    Tensor sC = make_tensor(make_smem_ptr(shared_tensors.smem_C.data()), SmemLayoutC{});       //  (TILE_M,TILE_N,PIPE)

    // Prepare the thread(b)lock (G)mem to (S)mem TMA copy (bGS_)
    ThrCopy thrblk_g2s = params.tma_load_c.get_slice(Int<0>{});
    Tensor bGS_gC = thrblk_g2s.partition_S(gC);                                               //      (TMA,TMA_M,TMA_N)
    Tensor bGS_sC = thrblk_g2s.partition_D(sC);                                               // (TMA,TMA_M,TMA_N,PIPE)

    auto* tma_barrier = load_pipeline.producer_get_barrier(load_pipe_producer_state);
    uint16_t mcast_mask = 0;

    // Execute the TMA load for C
    if (warp_idx_in_warp_group == 0 and lane_predicate) { 
      load_pipeline.producer_acquire(load_pipe_producer_state);
      copy(params.tma_load_c.with(*tma_barrier, mcast_mask), bGS_gC, bGS_sC(_,_,_,load_pipe_producer_state.index()));
      load_pipeline.producer_commit(load_pipe_producer_state);
    }
  }

  CUTLASS_DEVICE void
  load_tail(
      LoadPipeline load_pipeline,
      LoadPipelineState load_pipe_producer_state) {
    int warp_idx = canonical_warp_idx();
    int warp_idx_in_warp_group = warp_idx % 4;
    int lane_predicate = cute::elect_one_sync();

    if (warp_idx_in_warp_group == 0 and lane_predicate) {
      load_pipeline.producer_tail(load_pipe_producer_state);
    }
  }

  template<
    class ProblemShapeMNKL,
    class TileShapeMNK,
    class TileCoordMNKL,
    class AccEngine, class AccLayout,
    class TiledMma
  >
  CUTLASS_DEVICE void
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
    using X = Underscore;

    static_assert(is_rmem<AccEngine>::value, "Accumulator must be RF resident.");
    static_assert(rank(AccLayout{}) == 3, "Accumulator must be MMA-partitioned: (MMA,MMA_M,MMA_N)");
    static_assert(rank(ProblemShapeMNKL{}) == 4, "ProblemShapeMNKL must be rank 4");
    static_assert(is_static<TileShapeMNK>::value, "TileShapeMNK must be static");
    static_assert(rank(TileShapeMNK{}) == 3, "TileShapeMNK must be rank 3");
    static_assert(rank(TileCoordMNKL{}) == 4, "TileCoordMNKL must be rank 4");

    // Separate out problem shape for convenience
    auto M = get<0>(problem_shape_mnkl);
    auto N = get<1>(problem_shape_mnkl);
    auto L = get<3>(problem_shape_mnkl);
    auto mma_tile_m = size<0>(typename TiledMma::TiledShape_MNK{});
    auto mma_tile_n = size<1>(typename TiledMma::TiledShape_MNK{});
    auto epi_tile_m = size<0>(EpilogueTileShape{});
    auto epi_tile_n = size<1>(EpilogueTileShape{});

    // Represent the full output tensor
    Tensor mD_mnl = params.tma_store_d.get_tma_tensor(make_shape(M,N,L));                                    // (m,n,l)
    Tensor gD_mnl = local_tile(mD_mnl, tile_shape_MNK, make_coord(_,_,_), Step<_1,_1, X>{});   // (TILE_M,TILE_N,m,n,l)

    // Slice to get the tile this CTA is responsible for
    auto [m_coord, n_coord, k_coord, l_coord] = tile_coord_mnkl;
    Tensor gD = gD_mnl(_,_,m_coord,n_coord,l_coord);                                                 // (TILE_M,TILE_N)

    // Construct the smem tensors for source (sC) and output (sD)
    Tensor sC   = make_tensor(make_smem_ptr(shared_tensors.smem_C.data()),              //              (TILE_M,TILE_N)
                              SmemLayoutC{})(_,_,load_pipe_consumer_state.index());
    Tensor bEsD = make_tensor(make_smem_ptr(shared_tensors.smem_D.data()),              // (EPI_TILE_M,EPI_TILE_N,PIPE)
                              SmemLayoutD{});

    // Tile thread(b)lock tensors by (E)pilogue output tile shape (bE)
    Tensor bEsC = local_tile(sC, EpilogueTileShape{}, _);                        // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)
    Tensor bEgD = local_tile(gD, EpilogueTileShape{}, _);                        // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)

    // Partition for register to smem copy (tRS_)
    using CopyAtomR2S = cute::conditional_t<cute::is_same_v<CopyOpR2S,DefaultCopy>,
                          Copy_Atom<UniversalCopy<uint_byte_t<sizeof(ElementD)*2>>,ElementD>,
                          Copy_Atom<CopyOpR2S,ElementD>>;
    TiledCopy tiled_r2s = make_tiled_copy_C_atom(CopyAtomR2S{}, tiled_mma);
    ThrCopy thread_r2s = tiled_r2s.get_slice(thread_idx);
    Tensor tRS_rAcc = thread_r2s.retile_S(accumulators);                               //     ((R2S,R2S_V),MMA_M,MMA_N)
    Tensor tRS_sD   = conditional_return<ReuseSmemC>(
                      thread_r2s.partition_D(recast<ElementD>(bEsC)),                  // (R2S,R2S_M,R2S_N,EPI_M,EPI_N)
                      thread_r2s.partition_D(bEsD) );                                  //        (R2S,R2S_M,R2S_N,PIPE)

    // Allocate register tensors
    auto tRS_rD_shape = take<0,3>(shape(thread_r2s.partition_S(bEsD)));                            // (R2S,R2S_M,R2S_N)
    Tensor tRS_rC = make_tensor<InternalElementC>(tRS_rD_shape);                                   // (R2S,R2S_M,R2S_N)
    Tensor tRS_rD = make_tensor<ElementD>(tRS_rD_shape);                                           // (R2S,R2S_M,R2S_N)

    // Vectorized fragment view for thread epilogue op
    Tensor tRS_rAcc_frg = recast<typename ThreadEpilogueOp::FragmentAccumulator>(tRS_rAcc);
    Tensor tRS_rC_frg   = recast<typename ThreadEpilogueOp::FragmentSource>(tRS_rC);
    Tensor tRS_rD_frg   = recast<typename ThreadEpilogueOp::FragmentOutput>(tRS_rD);

    // Partition for smem to register copy (tSR_)
    TiledCopy tiled_s2r = make_tiled_copy_S(Copy_Atom<CopyOpS2R,InternalElementC>{}, tiled_r2s);
    ThrCopy thread_s2r = tiled_s2r.get_slice(thread_idx);
    Tensor tSR_sC = thread_s2r.partition_S(bEsC);                                      // (S2R,S2R_M,S2R_N,EPI_M,EPI_N)
    Tensor tSR_rC = thread_s2r.retile_D(tRS_rC);                                       //             (S2R,S2R_M,S2R_N)

    // Partition for smem to gmem copy (tSG_)
    ThrCopy thrblk_s2g = params.tma_store_d.get_slice(Int<0>{});
    Tensor tSG_sD = conditional_return<ReuseSmemC>(
                    thrblk_s2g.partition_S(recast<ElementD>(bEsC)),                    // (S2G,S2G_M,S2G_N,EPI_M,EPI_N)
                    thrblk_s2g.partition_S(bEsD) );                                    //        (S2G,S2G_M,S2G_N,PIPE)
    Tensor tSG_gD = thrblk_s2g.partition_D(bEgD);                                      // (S2G,S2G_M,S2G_N,EPI_M,EPI_N)

    CUTE_STATIC_ASSERT(size<0>(tRS_rAcc) % ThreadEpilogueOp::kCount == 0, "ThreadEpilogueOp does not vectorize properly");
    CUTE_STATIC_ASSERT(mma_tile_m == epi_tile_m, "EPI_TILE_M must equal MMA_TILE_M");
    CUTE_STATIC_ASSERT(mma_tile_n % epi_tile_n == 0, "EPI_TILE_N must divide MMA_TILE_N");

    // Thread synchronizer for previously issued waits or fences
    // to ensure visibility of smem reads/writes to threads or TMA unit
    auto synchronize = [&] () { cutlass::arch::NamedBarrier::sync(size(TiledMma{}), 0); };

    // Predication for TMA store (one warp issues TMA store)
    bool issue_tma_store = (thread_idx / NumThreadsPerWarp) == 0;

    if (epilogue_op.is_source_needed()) {
      // Wait for epilogue load to fill smem buffer with C
      load_pipeline.consumer_wait(load_pipe_consumer_state);
    }

    // Delay issue of TMA store by 1 iteration to achieve better instruction pipelining
    PipelineState store_pipe_producer_state_prev = store_pipe_producer_state;
    int epi_m_prev = 0, epi_n_prev = 0;

    // For each output tile
    CUTLASS_PRAGMA_UNROLL
    for (int epi_n = 0; epi_n < size<3>(bEgD); ++epi_n) {
      CUTLASS_PRAGMA_UNROLL
      for (int epi_m = 0; epi_m < size<2>(bEgD); ++epi_m) {
        // The current tile in accumulator
        int mma_m = epi_m;
        int mma_n = (epi_n * epi_tile_n) / mma_tile_n;
        Tensor tRS_rAcc_frg_mn = tRS_rAcc_frg(_,mma_m,mma_n);

        // Elementwise operation with conversion
        int r2s_v = epi_n * size(tRS_rD_frg);
        if (epilogue_op.is_source_needed()) {
          // Copy source tile to register from smem
          if constexpr (cute::is_same_v<CopyOpS2R,DefaultCopy>) {
            copy(tSR_sC(_,_,_,epi_m,epi_n), tSR_rC);
          }
          else {
            copy(tiled_s2r, tSR_sC(_,_,_,epi_m,epi_n), tSR_rC);
          }

          CUTLASS_PRAGMA_UNROLL
          for (int i = 0; i < size(tRS_rD_frg); ++i) {
            tRS_rD_frg(i) = epilogue_op(tRS_rAcc_frg_mn(r2s_v + i), tRS_rC_frg(i));
          }
        }
        else {
          CUTLASS_PRAGMA_UNROLL
          for (int i = 0; i < size(tRS_rD_frg); ++i) {
            tRS_rD_frg(i) = epilogue_op(tRS_rAcc_frg_mn(r2s_v + i));
          }
        }

        if constexpr (ReuseSmemC) {
          // Issue the TMA store of the previous iteration
          if (not (epi_m == 0 && epi_n == 0)) {
            // Make sure smem writes are visible to TMA
            cutlass::arch::fence_view_async_shared();
            synchronize(); // ensure all threads have issued their async fence

            // Write the tile to gmem from smem with TMA
            if (issue_tma_store) {
              copy(params.tma_store_d, tSG_sD(_,_,_,epi_m_prev,epi_n_prev), tSG_gD(_,_,_,epi_m_prev,epi_n_prev));
            }
          }

          // Copy output tile to smem from register
          if constexpr (cute::is_same_v<CopyOpR2S,DefaultCopy>) {
            copy(tRS_rD, tRS_sD(_,_,_,epi_m,epi_n));
          }
          else {
            copy(tiled_r2s, tRS_rD, tRS_sD(_,_,_,epi_m,epi_n));
          }
        }
        else {
          // Issue the TMA store of the previous iteration
          if (not (epi_m == 0 && epi_n == 0)) {
            // Make sure smem writes are visible to TMA
            cutlass::arch::fence_view_async_shared();
            synchronize(); // ensure all threads have issued their async fence

            // Write the tile to gmem from smem with TMA
            if (issue_tma_store) {
              copy(params.tma_store_d, tSG_sD(_,_,_,store_pipe_producer_state_prev.index()), tSG_gD(_,_,_,epi_m_prev,epi_n_prev));
              store_pipeline.producer_commit(store_pipe_producer_state_prev);
            }
          }

          // Wait for a smem buffer to be available
          if (issue_tma_store) {
            store_pipeline.producer_acquire(store_pipe_producer_state);
          }
          synchronize();

          // Copy tile to smem from register
          if constexpr (cute::is_same_v<CopyOpR2S,DefaultCopy>) {
            copy(tRS_rD, tRS_sD(_,_,_,store_pipe_producer_state.index()));
          }
          else {
            copy(tiled_r2s, tRS_rD, tRS_sD(_,_,_,store_pipe_producer_state.index()));
          }

          // Advance pipeline state
          store_pipe_producer_state_prev = store_pipe_producer_state;
          ++store_pipe_producer_state;
        }

        epi_m_prev = epi_m;
        epi_n_prev = epi_n;
      }
    }

    if constexpr (ReuseSmemC) {
      // Fence and issue the TMA store of the last iteration
      cutlass::arch::fence_view_async_shared();
      synchronize(); // ensure all threads have issued their async fence
      if (issue_tma_store) {
        copy(params.tma_store_d, tSG_sD(_,_,_,epi_m_prev,epi_n_prev), tSG_gD(_,_,_,epi_m_prev,epi_n_prev));
      }

      // Arrive and advance pipeline state
      if (issue_tma_store) {
        store_pipeline.producer_commit(store_pipe_producer_state);
      }
      ++store_pipe_producer_state;

      // Wait for a smem buffer to be available
      if (issue_tma_store) {
        store_pipeline.producer_acquire(store_pipe_producer_state);
      }
      synchronize();

      // Let dma warp know smem buffer is consumed and empty
      if (epilogue_op.is_source_needed()) {
        load_pipeline.consumer_release(store_pipe_producer_state);
      }
    }
    else {
      // Fence and issue the TMA store of the last iteration
      cutlass::arch::fence_view_async_shared();
      synchronize(); // ensure all threads have issued their async fence
      if (issue_tma_store) {
        copy(params.tma_store_d, tSG_sD(_,_,_,store_pipe_producer_state_prev.index()), tSG_gD(_,_,_,epi_m_prev,epi_n_prev));
        store_pipeline.producer_commit(store_pipe_producer_state_prev);
      }

      // Let dma warp know smem buffer is consumed and empty
      if (epilogue_op.is_source_needed()) {
        load_pipeline.consumer_release(load_pipe_consumer_state);
      }
    }
  }

private:
  Params const& params;
  ThreadEpilogueOp epilogue_op;
};


/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace collective
} // namespace epilogue
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
