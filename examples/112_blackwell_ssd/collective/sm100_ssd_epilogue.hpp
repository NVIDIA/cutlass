/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "cutlass/epilogue/collective/collective_builder.hpp"

namespace cutlass::ssd::collective {
using namespace cute;

template<
  class ElementAcc_,
  class Element_,
  class ElementDA_,
  class TileShape_,
  class EpilogueTile_,
  class SmemLayoutY_,
  class SmemLayoutP_,
  class SmemLayoutX_,
  int   StagesInput,
  int   StagesOutput,
  bool  HasScaleD_,
  bool  HasBlockScaleD_>
struct SsdEpilogue {

  using TileShape = TileShape_;
  using ElementAcc = ElementAcc_;
  using Element = Element_;
  using ElementD = Element_;
  using ElementDA = ElementDA_;
  using ElementY = Element_;
  using ElementP = Element_;
  using EpilogueTile = EpilogueTile_;
  using SmemLayoutY = SmemLayoutY_;
  using SmemLayoutP = SmemLayoutP_;
  using SmemLayoutX = SmemLayoutX_;

  static constexpr bool HasScaleD = HasScaleD_;
  static constexpr bool HasBlockScaleD = HasBlockScaleD_;

  // avoid "warning #3357-D: capturing structured bindings is a C++20 feature"
  static constexpr auto L = get<0>(TileShape{});
  static constexpr auto D = get<1>(TileShape{});
  static constexpr auto N = get<2>(TileShape{});

  constexpr static int ThreadCount = 128;
  constexpr static size_t SmemAlignmentY = cutlass::detail::alignment_for_swizzle(SmemLayoutY{});

  struct CollectiveStorage {
    alignas(SmemAlignmentY) ArrayEngine<ElementY  , cosize_v<SmemLayoutY>>        smem_y;
  };

  // TMA pipeline for storing D
  using StorePipeline = cutlass::PipelineTmaStore<StagesOutput>;
  using StorePipelineState = cutlass::PipelineState<StagesOutput>;

  using StorePPipeline = cutlass::PipelineTmaStore<1>;
  using StorePPipelineState = cutlass::PipelineState<1>;

  using CooperatePipeline = cutlass::PipelineAsync<StagesInput>;
  using CooperatePipelineState = cutlass::PipelineState<StagesInput>;

  using EpiloadPipelineD = cutlass::PipelineTmaAsync<StagesInput>;
  static constexpr int kEpiloadDBytes = HasBlockScaleD ? D * sizeof(ElementD) : 0;

  struct SharedStorage {
    using TensorStorage = CollectiveStorage;
    TensorStorage tensors;
  };
  using TensorStorage = typename SharedStorage::TensorStorage;

  using LayoutY     = decltype(make_layout(make_shape(L, D, int32_t(0), int32_t(0)), 
                                           make_stride(_1{}, int32_t(0), L, int32_t(0))));           // (L,D,C,B)
  using LayoutP     = decltype(make_layout(make_shape(D, N, int32_t(0)), make_stride(N, _1{}, D*N)));   // (D,N,B)
  using LayoutD_2D  = decltype(make_layout(make_shape(D, int32_t(0)), make_stride(_1{}, D)));         // (D,EH)
  using LayoutD_1D  = decltype(make_layout(make_shape(_1{}, int32_t(0)), make_stride(_0{}, _1{})));   // (D,EH)
  using LayoutD     = cute::conditional_t<
      HasBlockScaleD,
      LayoutD_2D,
      LayoutD_1D
    >;

  struct Arguments {
    ElementY* ptr_Y{nullptr};
    ElementP* ptr_P{nullptr};
    const ElementD* ptr_D{nullptr};
    LayoutY   layout_Y{};
    LayoutP   layout_P{};
    LayoutD   layout_D{};
  };

  using StrideY     = cute::tuple<_1, int, int, int>;     // (L,D,C,B)
  using StrideP     = cute::tuple<int, _1, int>;          // (D,N,B)
  
  using CopyOpS2G = SM90_TMA_STORE;

  struct Params {
    using TMA_Y = decltype(make_tma_copy(
            CopyOpS2G{},
            make_tensor(make_gmem_ptr(static_cast<ElementY const*>(nullptr)),
                repeat_like(StrideY{}, int32_t(0)), StrideY{}),
            take<0,2>(SmemLayoutY{}),
            EpilogueTile{},
            _1{}));
    using TMA_P = decltype(make_tma_copy(
            CopyOpS2G{},
            make_tensor(make_gmem_ptr(static_cast<ElementP const*>(nullptr)),
                repeat_like(StrideP{}, int32_t(0)), StrideP{}),
            take<0,3>(SmemLayoutP{}),
            make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})), // (D,N)
            _1{}));
    using TensorD = decltype(make_tensor(
      make_gmem_ptr(static_cast<ElementD const*>(nullptr)),
      LayoutD{}));

    TMA_Y tma_store_y;
    TMA_P tma_store_p;
    TensorD tensor_d;
  };

  template<class ProblemShape>
  static Params to_underlying_arguments(ProblemShape const& problem_size, Arguments const& args, void* workspace = nullptr) {
    
    using X = Underscore;
    auto [G, B, EH, C, L, D, N] = problem_size;

    auto tensor_y = make_tensor(make_gmem_ptr(args.ptr_Y), args.layout_Y);
    auto tensor_p = make_tensor(make_gmem_ptr(args.ptr_P), args.layout_P);
    auto tensor_d = make_tensor(make_gmem_ptr(args.ptr_D), args.layout_D);

    auto tma_store_y = make_tma_copy_C_sm90(
        CopyOpS2G{},
        tensor_y,
        take<0,2>(SmemLayoutY{}),
        EpilogueTile{});
    auto tma_store_p = make_tma_copy_C_sm90(
        CopyOpS2G{},
        tensor_p,
        take<0,2>(SmemLayoutP{}),
        make_shape(shape<1>(TileShape{}), shape<2>(TileShape{})));
    return Params{
      tma_store_y,
      tma_store_p,
      tensor_d
    };
  }

  template<
    class Params, class ProblemShape,
    class EpiloadPipeline, class PipelineState,
    class TensorStorage
  >
  CUTLASS_DEVICE
  void load_d(
    int const& blk_coord, Params const& params, ProblemShape const& problem_size,
    EpiloadPipeline& pipeline, PipelineState& pipeline_d_producer_state,
    TensorStorage& shared_tensors) {
    
    if constexpr (HasBlockScaleD) {

      int lane_predicate = cute::elect_one_sync();

      if (lane_predicate) {

        auto& gD = params.tensor_d;

        ElementD* ptr_d = shared_tensors.smem_d.data();
        auto smem_layout = make_layout(make_shape(get<1>(TileShape{}), Int<StagesInput>{}));  // (D,)
        auto sD = cute::as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(ptr_d), smem_layout));

        auto bulk_atom = Copy_Atom<SM90_BULK_COPY_AUTO, ElementD>{};

        int write_stage = pipeline_d_producer_state.index();

        // LOCK pipeline_state for _writing_
        pipeline.producer_acquire(pipeline_d_producer_state);

        using BarrierType = typename EpiloadPipeline::ProducerBarrierType;
        BarrierType* tma_barrier = pipeline.producer_get_barrier(pipeline_d_producer_state);
        copy(bulk_atom.with(*tma_barrier), gD(_,blk_coord), sD(_,write_stage));

        // Advance pipeline_state
        ++pipeline_d_producer_state;
      }
    }

  }

  template<
    class Params, class ProblemShape,
    class MainloopPipelineIntra, class PipelineStateIntra,
    class MainloopPipelineAcc, class PipelineStateAcc,
    class MainloopPipelineDelta, class PipelineStateDelta,
    class MainloopPipelineX, class PipelineStateX,
    class EpiloadPipelineD, class PipelineStateD,
    class FragmentC_Intra_1, class FragmentC_Intra_2,
    class FragmentC_Inter_1, class FragmentC_Inter_2,
    class MainloopStorage, class EpilogueStorage
  >
  CUTLASS_DEVICE
  auto store(
    int& chunk, int const& blk_coord, int const& blk_coord_eh, 
    Params const& params, ProblemShape const& problem_size,
    MainloopPipelineIntra& pipeline_intra, PipelineStateIntra& pipeline_intra_consumer_state,
    MainloopPipelineAcc& pipeline_acc, PipelineStateAcc& pipeline_acc_consumer_state,
    MainloopPipelineDelta& pipeline_delta, PipelineStateDelta& pipeline_delta_consumer_state,
    MainloopPipelineX& pipeline_x, PipelineStateX& pipeline_x_consumer_state,
    EpiloadPipelineD& pipeline_d, PipelineStateD& pipeline_d_producer_state,
    StorePipeline& store_pipeline, StorePipelineState& store_pipe_producer_state,
    cute::tuple<FragmentC_Intra_1, FragmentC_Intra_2>& acc_intra,
    cute::tuple<FragmentC_Inter_1, FragmentC_Inter_2>& acc_inter,
    MainloopStorage& mainloop_tensors, EpilogueStorage& epilogue_tensors,
    bool is_first_iteration) {
    
    using CopyOpT2R = SM100_TMEM_LOAD_16dp256b4x;
    using CopyOpR2S = SM90_U16x8_STSM_T;
    using CopyOpS2R = SM75_U16x8_LDSM_T;

    // Epilogue

    int thread_idx = int(threadIdx.x % 128);
    int warp_idx = thread_idx / 32;
    auto [G, B, EH, C, L, D, N] = problem_size;

    Tensor mY_mn = params.tma_store_y.get_tma_tensor(make_shape(L,D,C,B*EH));
    Tensor gY_mn = local_tile(mY_mn, take<0,2>(TileShape{}), make_coord(_,_,_))(_,_,_0{},_0{},chunk,blk_coord);

    auto ptr_sY = epilogue_tensors.smem_y.begin();
    Tensor sY_epi = cute::as_position_independent_swizzle_tensor(
                      make_tensor(make_smem_ptr(ptr_sY), SmemLayoutY{}));
    auto ptr_sX = mainloop_tensors.smem_x.data();
    Tensor sX_epi = cute::as_position_independent_swizzle_tensor(
                      make_tensor(make_smem_ptr(ptr_sX), SmemLayoutX{}));

    auto ts0 = size<0>(TileShape{});
    auto ts1 = size<1>(TileShape{});
    Layout col_layout = make_layout(make_shape ( ts0,  ts1, Int<StagesInput>{}),
                                    make_stride(_1{}, _0{}, ts0));
    Tensor sDeltaA = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(mainloop_tensors.smem_delta_a.data()), col_layout));
    auto tDeltaA = sDeltaA(_,_,pipeline_delta_consumer_state.index());
    Layout row_layout = make_layout(make_shape ( ts0,  ts1, Int<StagesInput>{}),
                                    make_stride(_0{}, _1{}, ts1));
    Tensor sD = as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(mainloop_tensors.smem_d.data()), row_layout));
    auto tD = sD(_,_,pipeline_d_producer_state.index());
    
    auto accumulator_intra_2 = get<1>(acc_intra);
    auto accumulator_inter_2 = get<1>(acc_inter);
    auto tIntra = accumulator_intra_2(make_coord(_,_),_0{},_0{},_0{});
    auto tInter = accumulator_inter_2(make_coord(_,_),_0{},_0{},_0{});
    Tensor tIntra_epi = flat_divide(tIntra, EpilogueTile{});
    Tensor tInter_epi = flat_divide(tInter, EpilogueTile{});
    Tensor tDeltaA_epi = flat_divide(tDeltaA, EpilogueTile{});
    Tensor tD_epi = flat_divide(tD, EpilogueTile{});
    Tensor gY_epi     = flat_divide(gY_mn, EpilogueTile{});

    TiledCopy tiled_t2r = make_tmem_copy(CopyOpT2R{}, tIntra_epi(_,_,_0{},_0{}));
    ThrCopy thread_t2r = tiled_t2r.get_slice(thread_idx);
    Tensor tTR_tIntra = thread_t2r.partition_S(tIntra_epi);
    Tensor tTR_tInter = thread_t2r.partition_S(tInter_epi);
    Tensor tTR_tDeltaA = thread_t2r.partition_D(tDeltaA_epi);
    Tensor tTR_tD     = thread_t2r.partition_D(tD_epi);
    Tensor tTR_sY     = thread_t2r.partition_D(sY_epi(_,_,_0{}));
    Tensor tTR_rIntra = make_tensor<ElementAcc>(shape(thread_t2r.partition_D(gY_epi)));
    // Tensor tTR_rInter = make_tensor<ElementAcc>(shape(thread_t2r.partition_D(gY_epi)));

    // Tensor tTR_rIntra = make_tensor<ElementAcc>(shape(tTR_sY)); 
    Tensor tTR_rInter = make_tensor<ElementAcc>(shape(tTR_sY));
    Tensor tTR_rY     = make_tensor<Element>(shape(tTR_sY));
    Tensor tTR_rDeltaA = make_tensor<ElementDA>(shape(tTR_sY));
    Tensor tTR_rD     = make_tensor<Element>(shape(tTR_sY));
    Tensor tTR_rD_Acc = make_tensor<ElementAcc>(shape(tTR_sY));
    Tensor tTR_rX     = make_tensor<Element>(shape(tTR_sY));
    Tensor tTR_rX_Acc = make_tensor<ElementAcc>(shape(tTR_sY));

    // (t)hread-partition for (r)egister to (s)mem copy (tRS_)
    TiledCopy tiled_r2s = make_tiled_copy_D(Copy_Atom<CopyOpR2S, Element>{}, tiled_t2r);
    ThrCopy thread_r2s  = tiled_r2s.get_slice(thread_idx);
    Tensor tRS_sY       = thread_r2s.partition_D(sY_epi);
    Tensor tRS_rY       = thread_r2s.retile_S(tTR_rY);
    Tensor tRS_rDeltaA  = thread_r2s.retile_S(tTR_rDeltaA);
    Tensor tRS_rD       = thread_r2s.retile_S(tTR_rD);
    Tensor tRS_rCompute = make_tensor<ElementAcc>(shape(tRS_rY));

    TiledCopy tiled_s2r = make_tiled_copy_D(Copy_Atom<CopyOpS2R, Element>{}, tiled_t2r);
    ThrCopy thread_s2r  = tiled_s2r.get_slice(thread_idx);
    Tensor tSR_sX       = thread_s2r.partition_S(flat_divide(sX_epi, EpilogueTile{}));
    Tensor tSR_rX       = thread_s2r.retile_D(tTR_rX);

    constexpr int FragmentSize = 4;
    // Tensor tTR_rIntra_frg   = recast<Array<ElementAcc, FragmentSize>>(coalesce(tTR_rIntra));
    // Tensor tTR_rInter_frg   = recast<Array<ElementAcc, FragmentSize>>(coalesce(tTR_rInter));
    Tensor tTR_rY_frg       = recast<Array<Element   , FragmentSize>>(coalesce(tTR_rY));
    Tensor tRS_rY_frg       = recast<Array<Element   , FragmentSize>>(coalesce(tRS_rY));
    Tensor tRS_rDeltaA_frg  = recast<Array<ElementDA , FragmentSize>>(coalesce(tRS_rDeltaA));
    Tensor tRS_rD_frg       = recast<Array<Element   , FragmentSize>>(coalesce(tRS_rD));
    Tensor tRS_rCompute_frg = recast<Array<ElementAcc, FragmentSize>>(coalesce(tRS_rCompute));

    // thread(b)lock-partition for (s)mem to (g)mem copy (bSG_)
    ThrCopy thrblk_s2g = params.tma_store_y.get_slice(Int<0>{});
    Tensor bSG_sY = thrblk_s2g.partition_S(sY_epi);
    Tensor bSG_gY = thrblk_s2g.partition_D(gY_epi);

    auto synchronize = [] () { cutlass::arch::NamedBarrier::sync(ThreadCount, cutlass::arch::ReservedNamedBarriers::EpilogueBarrier); };
    [[maybe_unused]] bool issue_smem_store = true;
    [[maybe_unused]] bool issue_tma_store = warp_idx == 0;

    // The TMA store sequence for one subtile iteration
    auto tma_store_fn = [&] (int epi_m, int epi_n) {
      // Write the tile from smem to gmem with TMA
      cutlass::arch::fence_view_async_shared(); // ensure smem writes are visible to TMA
      synchronize(); // ensure all threads have issued their async fence
      if (issue_tma_store) {
        copy(params.tma_store_y, bSG_sY(_,_,_,store_pipe_producer_state.index()), bSG_gY(_,_,_,epi_m,epi_n));
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
    };

    // Require Acc
    pipeline_intra.consumer_wait(pipeline_intra_consumer_state);
    copy(tiled_t2r, tTR_tIntra, tTR_rIntra);

    cutlass::arch::fence_view_async_tmem_load();

    pipeline_intra.consumer_release(pipeline_intra_consumer_state); 
    ++pipeline_intra_consumer_state;

    // Require Inter Acc
    pipeline_acc.consumer_wait(pipeline_acc_consumer_state);

    CUTLASS_PRAGMA_UNROLL
    for (int iter_n = 0; iter_n < size<3>(gY_epi); ++iter_n) {
      CUTLASS_PRAGMA_UNROLL
      for (int iter_m = 0; iter_m < size<2>(gY_epi); ++iter_m) {
        int epi_m = iter_m, epi_n = iter_n;

        Tensor tTR_rIntra_mn = tTR_rIntra(_,_,_,epi_m,epi_n);
        Tensor tTR_tInter_mn = tTR_tInter(_,_,_,epi_m,epi_n);
        Tensor tTR_tDeltaA_mn = tTR_tDeltaA(_,_,_,epi_m,epi_n);
        Tensor tTR_tD_mn = tTR_tD(_,_,_,epi_m,epi_n);

        copy(tiled_t2r, tTR_tInter_mn, tTR_rInter);
        cutlass::arch::fence_view_async_tmem_load();
        
        copy(tTR_tDeltaA_mn, tTR_rDeltaA);

        if constexpr (HasScaleD) {
          copy(tiled_s2r, tSR_sX(_,_,_,epi_m,epi_n,pipeline_x_consumer_state.index()), tSR_rX);
          type_convert<Element, ElementAcc>(tTR_rX, tTR_rX_Acc);
        }

        if constexpr (HasBlockScaleD) {
          if (is_first_iteration) {
            pipeline_d.consumer_wait(pipeline_d_producer_state);
          }
          copy(tTR_tD_mn, tTR_rD);
          type_convert<ElementD, ElementAcc>(tTR_rD, tTR_rD_Acc);
        }
        else if constexpr (HasScaleD) {
          auto& gD = params.tensor_d;
          auto value = static_cast<ElementAcc>(gD(_0{}, blk_coord_eh));
          CUTLASS_PRAGMA_UNROLL
          for (int ii = 0; ii < size(tTR_rD_Acc); ++ii) {
            tTR_rD_Acc(ii) = value;
          }
        }
        // ?
        synchronize();

        NumericArrayConverter<Element, ElementAcc, FragmentSize> converter;

        CUTLASS_PRAGMA_UNROLL
        for (int ii = 0; ii < size(tRS_rCompute); ++ii) {
          tRS_rCompute(ii) = tTR_rIntra_mn(ii) + tTR_rInter(ii) * expf(tTR_rDeltaA(ii));
          if constexpr (HasScaleD) {
            tRS_rCompute(ii) += tTR_rD_Acc(ii) * tTR_rX_Acc(ii);
          }
        }

        CUTLASS_PRAGMA_UNROLL
        for (int epi_v = 0; epi_v < size(tTR_rY_frg); ++epi_v) {
          tRS_rY_frg(epi_v) = converter(tRS_rCompute_frg(epi_v));
        }

        copy(tiled_r2s, tRS_rY, tRS_sY(_,_,_,store_pipe_producer_state.index()));

        tma_store_fn(epi_m, epi_n);
      }
    }

    pipeline_acc.consumer_release(pipeline_acc_consumer_state);
    ++pipeline_acc_consumer_state;
    pipeline_x.consumer_release_from_threads(pipeline_x_consumer_state);
    ++pipeline_x_consumer_state;

    pipeline_delta.consumer_release_from_threads(pipeline_delta_consumer_state); 
    ++pipeline_delta_consumer_state;
  }

  template<
    class Params, class ProblemShape,
    class StorePipeline, class StorePipelineState,
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto store_p(
    int const& blk_coord, Params const& params, ProblemShape const& problem_size,
    StorePipeline& store_pipeline, StorePipelineState& store_pipe_producer_state,
    TensorStorage& shared_tensors) {

    int thread_idx = int(threadIdx.x % 128);
    auto [G, B, EH, C, L, D, N] = problem_size;
    
    Tensor mP_mn = params.tma_store_p.get_tma_tensor(make_shape(D,N,B*EH));
    Tensor gP_mn = local_tile(mP_mn, take<1,3>(TileShape{}), make_coord(_,_,blk_coord));
    auto gP_epi = gP_mn(_,_,_0{},_0{});

    // Construct the corresponding pipelined smem tensors
    auto ptr_sP = shared_tensors.smem_p.begin();
    Tensor sP_epi = cute::as_position_independent_swizzle_tensor(
                      make_tensor(make_smem_ptr(ptr_sP), SmemLayoutP{}))(_,_,_0{});       // (EPI_TILE_M,EPI_TILE_N)

    // thread(b)lock-partition for (s)mem to (g)mem copy (bSG_)
    auto oprands = tma_partition(params.tma_store_p, Int<0>{}, Layout<_1>{},
                                    group_modes<0,2>(sP_epi), group_modes<0,2>(gP_epi));  // (TMA,k) and (TMA,PIPE)
    // avoid "warning #3357-D: capturing structured bindings is a C++20 feature"
    auto bSG_gY = get<0>(oprands);
    auto bSG_sY = get<1>(oprands);

#if 0
    if (threadIdx.x % 128 == 0 && (blockIdx.x + blockIdx.y + blockIdx.z == 0)) {
      print("mP_mn        : ");print(mP_mn);print("\n");
      print("gP_mn        : ");print(gP_mn);print("\n");
      print("sP_epi       : ");print(sP_epi);print("\n");
      print("gP_epi       : ");print(gP_epi);print("\n");
      print("bSG_sY       : ");print(bSG_sY);print("\n");
      print("bSG_gY       : ");print(bSG_gY);print("\n");
    }
#endif

    // Thread synchronizer for previously issued waits or fences
    // to ensure visibility of smem reads/writes to threads or TMA unit
    // Use the reserved named barrier `streamkbarrier` since this kernel doesn't support streamk
    auto synchronize = [&] () { cutlass::arch::NamedBarrier::sync(128, cutlass::arch::ReservedNamedBarriers::StreamkBarrier0); };

    // Predication for TMA store (one warp issues TMA store)
    bool issue_tma_store = (thread_idx / NumThreadsPerWarp) == 0;

    auto tma_store_fn = [&] () {
      // Write the tile from smem to gmem with TMA
      cutlass::arch::fence_view_async_shared(); // ensure smem writes are visible to TMA
      synchronize(); // ensure all threads have issued their async fence
      if (issue_tma_store) {
        copy(params.tma_store_p, bSG_sY, bSG_gY);
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
      // don't need pipeline
      synchronize();
    };

    tma_store_fn();
  }

  template<
    class ElementSrc, class ElementDst,
    class TensorSrc, class TensorDst
  >
  CUTLASS_DEVICE
  auto type_convert(
    TensorSrc& tS,
    TensorDst& tD) {

    static constexpr int FragmentSize = 2;
    NumericArrayConverter<ElementDst, ElementSrc, FragmentSize> converter;

    auto tS_frg = recast<Array<ElementSrc, FragmentSize>>(tS);
    auto tD_frg = recast<Array<ElementDst, FragmentSize>>(tD);

    CUTLASS_PRAGMA_UNROLL
    for (int ii = 0; ii < size(tS_frg); ++ii) {
      tD_frg(ii) = converter(tS_frg(ii));
    }
  }
};

}  // namespace cutlass::fmha::collective
