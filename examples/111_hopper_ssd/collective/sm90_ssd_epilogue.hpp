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
#include "cutlass/fast_math.h"

namespace cutlass::ssd::collective {
using namespace cute;

template<
  class ElementAcc_,
  class Element_,
  class TileShape_,
  class EpilogueTile_,
  class SmemLayoutX_,
  class SmemLayoutY_,
  class SmemLayoutPartialY_,
  class SmemLayoutP_,
  class SmemLayoutZ_,
  int   StagesD_,
  int   StagesY_,
  int   StagesZ_,
  bool  HAS_D_,
  bool  D_HAS_HDIM_,
  bool  HAS_Z_>
struct SsdEpilogue {

  using TileShape = TileShape_;
  using ElementAcc = ElementAcc_;
  using Element = Element_;
  using ElementY = Element_;
  using ElementP = Element_;
  using ElementD = Element_;
  using ElementX = Element_;
  using ElementZ = Element_;
  using EpilogueTile = EpilogueTile_;
  using SmemLayoutX = SmemLayoutX_;
  using SmemLayoutY = SmemLayoutY_;
  using SmemLayoutPartialY = SmemLayoutPartialY_;
  using SmemLayoutP = SmemLayoutP_;
  using SmemLayoutZ = SmemLayoutZ_;

  static constexpr int StagesD = StagesD_;
  static constexpr int StagesY = StagesY_;
  static constexpr int StagesZ = StagesZ_;
  static constexpr bool HAS_D = HAS_D_;
  static constexpr bool D_HAS_HDIM = D_HAS_HDIM_;
  static constexpr bool HAS_Z = HAS_Z_;

  // avoid "warning #3357-D: capturing structured bindings is a C++20 feature"
  static constexpr auto L = get<0>(TileShape{});
  static constexpr auto D = get<1>(TileShape{});
  static constexpr auto N = get<2>(TileShape{});

  constexpr static size_t SmemAlignmentY = cutlass::detail::alignment_for_swizzle(SmemLayoutY{});

  struct CollectiveStorage {
    alignas(SmemAlignmentY) ArrayEngine<ElementAcc, cosize_v<SmemLayoutPartialY>> smem_y_partial;
    alignas(SmemAlignmentY) ArrayEngine<ElementY  , cosize_v<SmemLayoutY>>        smem_y;
    alignas(SmemAlignmentY) ArrayEngine<ElementZ  , cosize_v<SmemLayoutZ>>        smem_z;
  };

  using EpiloadPipelineD = cutlass::PipelineTmaAsync<StagesD>;
  using EpiloadPipelineZ = cutlass::PipelineTmaAsync<StagesZ>;
  static constexpr int kEpiloadDBytes = D_HAS_HDIM ? D * sizeof(ElementD) : 0;
  static constexpr int kEpiloadZBytes = HAS_Z ? cosize_v<SmemLayoutZ> * sizeof(ElementZ) : 0;

  // TMA pipeline for storing D
  using StorePipeline = cutlass::PipelineTmaStore<StagesY>;
  using StorePipelineState = cutlass::PipelineState<StagesY>;
  
  // TMA pipeline for storing P
  using StorePPipeline = cutlass::PipelineTmaStore<1>;
  using StorePPipelineState = cutlass::PipelineState<1>;

  using CooperatePipeline = cutlass::PipelineAsync<StagesY>;
  using CooperatePipelineState = cutlass::PipelineState<StagesY>;

  struct SharedStorage {
    using TensorStorage = CollectiveStorage;
    TensorStorage tensors;
  };
  using TensorStorage = typename SharedStorage::TensorStorage;

  using StrideY     = cute::tuple<_1, int, int, int>;     // (L,D,C,B)
  using StrideP     = cute::tuple<int, _1, int>;          // (D,N,B)
  using StrideZ     = cute::tuple<_1, int, int, int>;     // (L,D,C,B)

  using LayoutY     = decltype(make_layout(make_shape(L, D, int32_t(0), int32_t(0)), 
                                           make_stride(_1{}, int32_t(0), L, int32_t(0))));              // (L,D,C,B)
  using LayoutP     = decltype(make_layout(make_shape(D, N, int32_t(0)), make_stride(N, _1{}, D*N)));   // (D,N,B)

  using LayoutD_2D  = decltype(make_layout(make_shape(D, int32_t(0)), make_stride(_1{}, D)));         // (D,EH)
  using LayoutD_1D  = decltype(make_layout(make_shape(_1{}, int32_t(0)), make_stride(_0{}, _1{})));   // (D,EH)
  using LayoutD     = cute::conditional_t<
      D_HAS_HDIM,
      LayoutD_2D,
      LayoutD_1D
    >;
  using LayoutZ     = decltype(make_layout(make_shape(L, D, int32_t(0), int32_t(0)), 
                                           make_stride(_1{}, int32_t(0), L, int32_t(0))));              // (L,D,C,B)

  struct Arguments {
    ElementY* ptr_Y{nullptr};
    ElementP* ptr_P{nullptr};
    const ElementD* ptr_D{nullptr};
    const ElementZ* ptr_Z{nullptr};
    LayoutY   layout_Y{};
    LayoutP   layout_P{};
    LayoutD   layout_D{};
    LayoutZ   layout_Z{};
  };

  using CopyOpS2G = SM90_TMA_STORE;
  using CopyOpG2S = SM90_TMA_LOAD;

  struct Params {
    using TMA_Y = decltype(make_tma_atom(
            CopyOpS2G{},
            make_tensor(make_gmem_ptr(static_cast<ElementY const*>(nullptr)),LayoutY{}),
            take<0,2>(SmemLayoutY{}),
            EpilogueTile{}));
    using TMA_P = decltype(make_tma_atom(
            CopyOpS2G{},
            make_tensor(make_gmem_ptr(static_cast<ElementP const*>(nullptr)),LayoutP{}),
            take<0,2>(SmemLayoutP{}),
            make_tile(shape<1>(TileShape{}), shape<2>(TileShape{}))));
    using TMA_Z = decltype(make_tma_atom(
            CopyOpG2S{},
            make_tensor(make_gmem_ptr(static_cast<ElementZ const*>(nullptr)),LayoutZ{}),
            take<0,2>(SmemLayoutZ{}),
            make_tile(shape<0>(TileShape{}), shape<1>(TileShape{}))));
    using TensorD = decltype(make_tensor(
      make_gmem_ptr(static_cast<ElementD const*>(nullptr)),
      LayoutD{}));

    TMA_Y tma_store_y;
    TMA_P tma_store_p;
    TMA_Z tma_load_z;
    TensorD tensor_d;
  };

  template<class ProblemShape>
  static Params to_underlying_arguments(ProblemShape const& problem_size, Arguments const& args, void* workspace = nullptr) {
    
    using X = Underscore;
    auto [G, B, EH, C, L, D, N] = problem_size;

    auto tensor_y = make_tensor(make_gmem_ptr(args.ptr_Y), args.layout_Y);
    auto tensor_p = make_tensor(make_gmem_ptr(args.ptr_P), args.layout_P);
    auto tensor_d = make_tensor(make_gmem_ptr(args.ptr_D), args.layout_D);
    auto tensor_z = make_tensor(make_gmem_ptr(args.ptr_Z), args.layout_Z);
  
    auto tma_store_y = make_tma_atom(
        CopyOpS2G{},
        tensor_y,
        take<0,2>(SmemLayoutY{}),
        EpilogueTile{});
    auto tma_store_p = make_tma_atom(
        CopyOpS2G{},
        tensor_p,
        take<0,2>(SmemLayoutP{}),
        make_tile(shape<1>(TileShape{}), shape<2>(TileShape{})));
    auto tma_load_z = make_tma_atom(
        CopyOpG2S{},
        tensor_z,
        take<0,2>(SmemLayoutZ{}),
        make_tile(shape<0>(TileShape{}), shape<1>(TileShape{})));
    return Params{
      tma_store_y,
      tma_store_p,
      tma_load_z,
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
    EpiloadPipeline& pipeline, PipelineState& pipeline_state,
    TensorStorage& shared_tensors) {
    
    if constexpr (D_HAS_HDIM) {

      int lane_predicate = cute::elect_one_sync();

      if (lane_predicate) {

        auto& gD = params.tensor_d;

        ElementD* ptr_d = shared_tensors.smem_d.data();
        auto smem_layout = make_layout(make_shape(get<1>(TileShape{}), Int<StagesD>{}));  // (D,)
        auto sD = cute::as_position_independent_swizzle_tensor(make_tensor(make_smem_ptr(ptr_d), smem_layout));

        auto bulk_atom = Copy_Atom<SM90_BULK_COPY_AUTO, ElementD>{};

        int write_stage = pipeline_state.index();

        // LOCK pipeline_state for _writing_
        pipeline.producer_acquire(pipeline_state);

        using BarrierType = typename EpiloadPipeline::ProducerBarrierType;
        BarrierType* tma_barrier = pipeline.producer_get_barrier(pipeline_state);
        copy(bulk_atom.with(*tma_barrier), gD(_,blk_coord), sD(_,write_stage));

        // Advance pipeline_state
        ++pipeline_state;
      }
    }

  }

  template<
    class EpiloadPipeline, class PipelineState
  >
  CUTLASS_DEVICE void
  load_d_tail(EpiloadPipeline pipeline, PipelineState pipeline_state) {
    int lane_predicate = cute::elect_one_sync();

    if (lane_predicate) {
      pipeline.producer_tail(pipeline_state);
    }
  }

  template <
    class Params, class ProblemShape
  >
  CUTLASS_DEVICE 
  auto load_z_init(Params const& params, ProblemShape const& problem_size) {

    using X = Underscore;
    auto [G, B, EH, C, L, D, N] = problem_size;

    Tensor mZ_mkl = params.tma_load_z.get_tma_tensor(make_shape(L,D,C,EH*B));
    Tensor gZ_mkl = local_tile(mZ_mkl, TileShape{}, make_coord(_,_,_), Step<_1,_1,X>{});

    return make_tuple(gZ_mkl);
  }

  template<
    class Params, class ProblemShape,
    class EpiLoadPipeline, class PipelineState,
    class GTensor,
    class TensorStorage
  >
  CUTLASS_DEVICE
  void load_z(
    int const& blk_coord, Params const& params, ProblemShape const& problem_size,
    EpiLoadPipeline& pipeline, PipelineState& pipeline_state,
    cute::tuple<GTensor> const& load_inputs,
    TensorStorage& shared_tensors) {
    
    if constexpr (HAS_Z) {
      int lane_predicate = cute::elect_one_sync();

      if (lane_predicate) {
        Tensor sZ_ = make_tensor(make_smem_ptr(shared_tensors.smem_z.begin()), SmemLayoutZ{});
        Tensor sZ  = as_position_independent_swizzle_tensor(sZ_);

        //
        // Prepare the TMA loads for Z
        //

        Tensor gZ_mkl = get<0>(load_inputs);

        // Partition the inputs based on the current block coordinates.
        Tensor gZ = gZ_mkl(_,_,_0{},_0{},_,blk_coord);

        auto oprands = tma_partition(params.tma_load_z, Int<0>{}, Layout<_1>{},
                                        group_modes<0,2>(sZ), group_modes<0,2>(gZ));  // (TMA,k) and (TMA,PIPE)
        // avoid "warning #3357-D: capturing structured bindings is a C++20 feature"
        auto tZgZ = get<0>(oprands);
        auto tZsZ = get<1>(oprands);

        // Disable multicast
        uint16_t mcast_mask_z = 0;

        auto chunk = get<3>(problem_size);
        // Mainloop
        CUTLASS_PRAGMA_NO_UNROLL
        for (int chunk_idx = 0; chunk_idx < chunk; ++chunk_idx) {
          int write_stage = pipeline_state.index();

          // LOCK pipeline_state for _writing_
          pipeline.producer_acquire(pipeline_state);

          using BarrierType = typename EpiLoadPipeline::ProducerBarrierType;
          BarrierType* tma_barrier = pipeline.producer_get_barrier(pipeline_state);

          copy(params.tma_load_z.with(*tma_barrier, mcast_mask_z), tZgZ(_,chunk_idx), tZsZ(_,write_stage));

          // Advance pipeline_state
          ++pipeline_state;
        }
      }
    }
  }

  template<
    class EpiLoadPipeline, class PipelineState
  >
  CUTLASS_DEVICE void
  load_z_tail(EpiLoadPipeline pipeline, PipelineState pipeline_state) {
    int lane_predicate = cute::elect_one_sync();

    // Issue the epilogue waits
    if (lane_predicate) {
      /* This helps avoid early exit of blocks in Cluster
       * Waits for all stages to either be released (all 
       * Consumer UNLOCKs), or if the stage was never used
       * then would just be acquired since the phase was 
       * still inverted from make_producer_start_state
       */
      pipeline.producer_tail(pipeline_state);
    }
  }

  template<
    class Params, class ProblemShape,
    class CooperatePipeline, class CooperatePipelineState,
    class TensorIntra,
    class TiledMma,
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto store_intra(
    int& chunk, int const& blk_coord, Params const& params, ProblemShape const& problem_size,
    CooperatePipeline& cooperate_pipeline, CooperatePipelineState& cooperate_pipe_producer_state,
    TensorIntra& tIntra,
    TiledMma tiled_mma,
    TensorStorage& shared_tensors) {

    int thread_idx = int(threadIdx.x % 128);
    auto [G, B, EH, C, L, D, N] = problem_size;

    Tensor mY_mn = params.tma_store_y.get_tma_tensor(make_shape(L,D,C,B*EH));
    Tensor gY_mn = local_tile(mY_mn, take<0,2>(TileShape{}), make_coord(_,_,_))(_,_,_0{},_0{},chunk,blk_coord);
    // Apply epilogue subtiling
    Tensor gY_epi = flat_divide(gY_mn, EpilogueTile{});                             // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)

    auto epi_tile_m = size<0>(EpilogueTile{});
    auto epi_tile_n = size<1>(EpilogueTile{});
    auto partial_m = Int<128>{};
    auto partial_n = Int<epi_tile_m * epi_tile_n / 128>{};
    
    auto ptr_sY = shared_tensors.smem_y_partial.begin();
    Tensor sY_epi = cute::as_position_independent_swizzle_tensor(
                      make_tensor(make_smem_ptr(ptr_sY), 
                                    tile_to_shape(UMMA::Layout_K_SW64_Atom<ElementAcc>{}, make_shape(partial_m, partial_n, Int<2>{}))));
    using CopyAtomC = Copy_Atom<SM90_U32x4_STSM_N, Element>;
    TiledCopy tiled_copy_C_atom = make_tiled_copy_C_atom(CopyAtomC{}, tiled_mma);
    using CopyOpR2S = SM90_U16x8_STSM_T;
    TiledCopy tiled_r2s = make_tiled_copy_S(Copy_Atom<CopyOpR2S,ElementY>{}, tiled_copy_C_atom);
    ThrCopy thread_r2s = tiled_r2s.get_slice(thread_idx);
    Tensor tRS_rIntra   = thread_r2s.retile_S(tIntra);                                          // ((R2S,R2S_V),MMA_M,MMA_N)

    // Hard code
    static constexpr int FragmentSize = 4;
    auto tRS_rY = make_tensor<ElementAcc>(shape(sY_epi(thread_idx,_,_0{})));
    Tensor tRS_rIntra_frg = recast<Array<ElementAcc, FragmentSize>>(tRS_rIntra);
    Tensor tRS_sY_frg     = recast<Array<ElementAcc, FragmentSize>>(sY_epi(thread_idx,_,_));
    Tensor tRS_rY_frg     = recast<Array<ElementAcc, FragmentSize>>(tRS_rY);
  
    auto mma_tile_m = size<0>(TileShape{}) / size<1>(tRS_rIntra);
    auto mma_tile_n = size<1>(TileShape{}) / size<2>(tRS_rIntra);

    // For each output tile
    CUTLASS_PRAGMA_UNROLL
    for (int epi_n = 0; epi_n < size<3>(gY_epi); ++epi_n) {
      CUTLASS_PRAGMA_UNROLL
      for (int epi_m = 0; epi_m < size<2>(gY_epi); ++epi_m) {

        int mma_m = epi_m;
        int mma_n = (epi_n * size<1>(EpilogueTile{})) / mma_tile_n;
        Tensor tRS_rIntra_frg_mn = tRS_rIntra_frg(_,mma_m,mma_n);

        // Vectorized fragment loop with visitor callback entry point
        // Epilogue op
        int epi_n_in_mma = epi_n % (mma_tile_n / epi_tile_n);
        int r2s_v = epi_n_in_mma * size(tRS_rY_frg);

        CUTLASS_PRAGMA_UNROLL
        for (int epi_v = 0; epi_v < size(tRS_rY_frg); ++epi_v) {
          tRS_rY_frg(epi_v) = tRS_rIntra_frg_mn(r2s_v + epi_v);
        }

        cooperate_pipeline.producer_acquire(cooperate_pipe_producer_state);

        copy(tRS_rY_frg, tRS_sY_frg(_,cooperate_pipe_producer_state.index()));
        cutlass::arch::fence_view_async_shared(); // ensure smem writes are visible to Cooperate warps

        cooperate_pipeline.producer_commit(cooperate_pipe_producer_state);
        ++cooperate_pipe_producer_state;
      }
    }
  }

  template<
    class Params,
    class EpiloadPipeline, class EpiloadPipelineState,
    class TiledMma,
    class TensorStorage
  >
  CUTLASS_DEVICE
  auto update_d(
    int const& blk_coord, Params params,
    bool is_first_iteration,
    EpiloadPipeline& epi_load_pipeline, EpiloadPipelineState& epi_load_pipe_consumer_state,
    TiledMma tiled_mma,
    TensorStorage& shared_tensors
  ) {

    int thread_idx = int(threadIdx.x % 128);

    int read_stage = epi_load_pipe_consumer_state.index();
    // Load delta for epilogue
    auto row_layout = make_layout(make_shape(get<0>(TileShape{}), get<1>(TileShape{}), Int<StagesD>{}), make_stride(_0{}, _1{}, get<1>(TileShape{})));
    auto c_tv_layout = typename TiledMma::LayoutC_TV{};
    auto tile_mn     = make_shape(tile_size<0>(tiled_mma), tile_size<1>(tiled_mma));
    auto d_layout = zipped_divide(row_layout, tile_mn);
    auto d_tv_layout = composition(d_layout, make_tuple(c_tv_layout,_));

    auto sD  = make_tensor(make_smem_ptr(shared_tensors.smem_d.data()), d_tv_layout)(make_coord(thread_idx,_), make_coord(_,_,read_stage));
    auto tSR_sD = as_position_independent_swizzle_tensor(sD); 
    auto tSR_rD = make_tensor<ElementD>(shape(sD));
    auto tD = make_tensor<ElementAcc>(shape(sD));

    if constexpr (D_HAS_HDIM) {
      if (is_first_iteration) {
        epi_load_pipeline.consumer_wait(epi_load_pipe_consumer_state);
      } 
      copy(tSR_sD, tSR_rD);
      type_convert<ElementD, ElementAcc>(tSR_rD, tD);
    }
    else if constexpr (HAS_D) {
      auto& gD = params.tensor_d;
      auto value = static_cast<ElementAcc>(gD(_0{}, blk_coord));
      CUTLASS_PRAGMA_UNROLL
      for (int ii = 0; ii < size(tSR_rD); ++ii) {
        tD(ii) = value;
      }
    }
    
    return make_tuple(tD);
  }

  template<
    class Params, class ProblemShape,
    class StorePipeline, class StorePipelineState,
    class CooperatePipeline, class CooperatePipelineState,
    class MainloopPipelineX, class PipelineStateX,
    class EpiloadPipelineZ, class PipelineStateZ,
    class TensorInter, class TensorDeltaA, class TensorD,
    class TiledMma,
    class TensorStorage, class TensorStorageX
  >
  CUTLASS_DEVICE
  auto store(
    int& chunk, int const& blk_coord, Params const& params, ProblemShape const& problem_size,
    StorePipeline& store_pipeline, StorePipelineState& store_pipe_producer_state,
    CooperatePipeline& cooperate_pipeline, CooperatePipelineState& cooperate_pipe_consumer_state,
    MainloopPipelineX& pipeline_x, PipelineStateX& pipeline_state_x,
    EpiloadPipelineZ& pipeline_z, PipelineStateZ& pipeline_state_z,
    TensorInter& tInter, TensorDeltaA& tDeltaA, TensorD& tD,
    TiledMma tiled_mma,
    TensorStorage& shared_tensors, TensorStorageX& shared_tensors_x) {

    int thread_idx = int(threadIdx.x % 128);
    auto [G, B, EH, C, L, D, N] = problem_size;
    
    Tensor mY_mn = params.tma_store_y.get_tma_tensor(make_shape(L,D,C,B*EH));
    Tensor gY_mn = local_tile(mY_mn, take<0,2>(TileShape{}), make_coord(_,_,_))(_,_,_0{},_0{},chunk,blk_coord);

    // Apply epilogue subtiling
    Tensor gY_epi = flat_divide(gY_mn, EpilogueTile{});                             // (EPI_TILE_M,EPI_TILE_N,EPI_M,EPI_N)

    // Construct the corresponding pipelined smem tensors
    auto ptr_sY = shared_tensors.smem_y.begin();
    Tensor sY_epi = cute::as_position_independent_swizzle_tensor(
                      make_tensor(make_smem_ptr(ptr_sY), SmemLayoutY{}));             // (EPI_TILE_M,EPI_TILE_N,PIPE_D)

    auto ptr_sX = shared_tensors_x.smem_x.data();
    Tensor sX_epi = cute::as_position_independent_swizzle_tensor(
                      make_tensor(make_smem_ptr(ptr_sX), SmemLayoutX{}));             // (EPI_TILE_M,EPI_TILE_N,PIPE_D)

    auto ptr_sZ = shared_tensors.smem_z.begin();
    Tensor sZ_epi = cute::as_position_independent_swizzle_tensor(
                      make_tensor(make_smem_ptr(ptr_sZ), SmemLayoutZ{}));             // (EPI_TILE_M,EPI_TILE_N,PIPE_D)

    auto epi_tile_m = size<0>(EpilogueTile{});
    auto epi_tile_n = size<1>(EpilogueTile{});
    auto partial_m = Int<128>{};
    auto partial_n = Int<epi_tile_m * epi_tile_n / 128>{};

    auto ptr_sY_partial = shared_tensors.smem_y_partial.begin();
    Tensor sY_epi_partial = cute::as_position_independent_swizzle_tensor(
                              make_tensor(make_smem_ptr(ptr_sY_partial), 
                                          tile_to_shape(UMMA::Layout_K_SW64_Atom<ElementAcc>{}, make_shape(partial_m, partial_n, Int<2>{}))));

    using CopyAtomC = Copy_Atom<SM90_U32x4_STSM_N, Element>;
    TiledCopy tiled_copy_C_atom = make_tiled_copy_C_atom(CopyAtomC{}, tiled_mma);

    using CopyOpR2S = SM90_U16x8_STSM_T;
    TiledCopy tiled_r2s = make_tiled_copy_S(Copy_Atom<CopyOpR2S,ElementY>{}, tiled_copy_C_atom);
    ThrCopy thread_r2s = tiled_r2s.get_slice(thread_idx);

    Tensor tRS_rInter   = thread_r2s.retile_S(tInter);                                          // ((R2S,R2S_V),MMA_M,MMA_N)
    Tensor tRS_rDeltaA  = thread_r2s.retile_S(tDeltaA);                                          // ((R2S,R2S_V),MMA_M,MMA_N)
    Tensor tRS_rD       = thread_r2s.retile_S(tD);                                          // ((R2S,R2S_V),MMA_M,MMA_N)
    Tensor tRS_sY   = thread_r2s.partition_D(sY_epi);                                       // (R2S,R2S_M,R2S_N,PIPE_D)

    using CopyOpS2R = SM75_U16x8_LDSM_T;
    TiledCopy tiled_s2r = make_tiled_copy_S(Copy_Atom<CopyOpS2R,ElementX>{}, tiled_copy_C_atom);
    ThrCopy thread_s2r = tiled_s2r.get_slice(thread_idx);
    Tensor tSR_sX = thread_s2r.partition_S(flat_divide(sX_epi, EpilogueTile{}));
    Layout tSR_rX_layout = make_layout(take<0,3>(shape(thread_s2r.partition_D(flat_divide(sX_epi, EpilogueTile{})))));
    Tensor tSR_rX = make_tensor<ElementX>(tSR_rX_layout);
    Tensor tRS_rX = make_tensor<ElementAcc>(tSR_rX_layout);

    using CopyOpS2R_Z = SM75_U16x8_LDSM_T;
    TiledCopy tiled_s2r_z = make_tiled_copy_S(Copy_Atom<CopyOpS2R_Z,ElementZ>{}, tiled_copy_C_atom);
    ThrCopy thread_s2r_z = tiled_s2r_z.get_slice(thread_idx);
    Tensor tSR_sZ = thread_s2r_z.partition_S(flat_divide(sZ_epi, EpilogueTile{}));
    Layout tSR_rZ_layout = make_layout(take<0,3>(shape(thread_s2r_z.partition_D(flat_divide(sZ_epi, EpilogueTile{})))));
    Tensor tSR_rZ = make_tensor<ElementX>(tSR_rZ_layout);
    Tensor tRS_rZ = make_tensor<ElementAcc>(tSR_rZ_layout);

    // Hard code
    static constexpr int FragmentSize = 4;
    // Allocate Y registers
    Layout tRS_rY_layout = make_layout(take<0,3>(shape(thread_r2s.partition_S(sY_epi))));
    Tensor tRS_rY = make_tensor<ElementY>(tRS_rY_layout);                                          // (R2S,R2S_M,R2S_N)
    Tensor tRS_rY_frg   = recast<Array<ElementY, FragmentSize>>(tRS_rY);
    Tensor tRS_rX_frg   = recast<Array<ElementAcc, FragmentSize>>(tRS_rX);
    Tensor tRS_rZ_frg   = recast<Array<ElementAcc, FragmentSize>>(tRS_rZ);
    // Tensor tRS_rIntra_frg = recast<Array<ElementAcc, FragmentSize>>(tRS_rIntra);
    Tensor tRS_rInter_frg = recast<Array<ElementAcc, FragmentSize>>(tRS_rInter);
    Tensor tRS_rDeltaA_frg = recast<Array<ElementAcc, FragmentSize>>(tRS_rDeltaA);
    Tensor tRS_rD_frg = recast<Array<ElementAcc, FragmentSize>>(tRS_rD);
    Tensor tRS_rCompute = make_tensor<ElementAcc>(tRS_rY_layout);                         // (R2S,R2S_M,R2S_N)
    Tensor tRS_rCompute_frg = recast<Array<ElementAcc, FragmentSize>>(tRS_rCompute);

    auto tSR_rY = make_tensor<ElementAcc>(shape(sY_epi_partial(thread_idx,_,_0{})));
    Tensor tSR_sY_frg     = recast<Array<ElementAcc, FragmentSize>>(sY_epi_partial(thread_idx,_,_));
    Tensor tSR_rY_frg     = recast<Array<ElementAcc, FragmentSize>>(tSR_rY);

    // thread(b)lock-partition for (s)mem to (g)mem copy (bSG_)
    auto oprands = tma_partition(params.tma_store_y, Int<0>{}, Layout<_1>{},
                                    group_modes<0,2>(sY_epi), group_modes<0,2>(gY_epi));  // (TMA,k) and (TMA,PIPE)
    // avoid "warning #3357-D: capturing structured bindings is a C++20 feature"
    auto bSG_gY = get<0>(oprands);
    auto bSG_sY = get<1>(oprands);

    auto mma_tile_m = size<0>(TileShape{}) / size<1>(tRS_rInter);
    auto mma_tile_n = size<1>(TileShape{}) / size<2>(tRS_rInter);

#if 0
    if (threadIdx.x % 128 == 0 && (blockIdx.x + blockIdx.y + blockIdx.z == 0) && chunk == 0) {
      print("tRS_rInter   : ");print(tRS_rInter);print("\n");
      print("tRS_sY       : ");print(tRS_sY);print("\n");
      print("bSG_sY       : ");print(bSG_sY);print("\n");
      print("bSG_gY       : ");print(bSG_gY);print("\n");

      print("tRS_rY_frg         : ");print(tRS_rY_frg);print("\n");
      print("tSR_rY_frg         : ");print(tSR_rY_frg);print("\n");
      print("tRS_rInter_frg     : ");print(tRS_rInter_frg);print("\n");
      print("tRS_rCompute_frg   : ");print(tRS_rCompute_frg);print("\n");
    }
#endif

    // Thread synchronizer for previously issued waits or fences
    // to ensure visibility of smem reads/writes to threads or TMA unit
    auto synchronize = [&] () { cutlass::arch::NamedBarrier::sync(128, cutlass::arch::ReservedNamedBarriers::EpilogueBarrier); };

    // Predication for TMA store (one warp issues TMA store)
    bool issue_tma_store = (thread_idx / NumThreadsPerWarp) == 0;

    int epi_m_prev = 0, epi_n_prev = 0;

    auto tma_store_fn = [&] (int epi_m, int epi_n) {
      // Write the tile from smem to gmem with TMA
      cutlass::arch::fence_view_async_shared(); // ensure smem writes are visible to TMA
      synchronize(); // ensure all threads have issued their async fence
      if (issue_tma_store) {
        copy(params.tma_store_y, bSG_sY(_,store_pipe_producer_state.index()), bSG_gY(_,epi_m,epi_n));
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

    static constexpr bool DelayTmaStore = true;
    int subtile_idx = -1;

    if constexpr (HAS_Z) {
      pipeline_z.consumer_wait(pipeline_state_z);
    }

    // For each output tile
    CUTLASS_PRAGMA_UNROLL
    for (int epi_n = 0; epi_n < size<3>(gY_epi); ++epi_n) {
      CUTLASS_PRAGMA_UNROLL
      for (int epi_m = 0; epi_m < size<2>(gY_epi); ++epi_m) {
        bool is_first_iteration = epi_m == 0 && epi_n == 0;
        bool is_last_iteration = epi_m == size<2>(gY_epi)-1 && epi_n == size<3>(gY_epi)-1;

        if (subtile_idx != -1 && (epi_n * static_cast<int>(size<2>(gY_epi)) + epi_m) != subtile_idx) {
          continue;
        }

        if constexpr (HAS_D) {
          // load x 
          copy(tiled_s2r, tSR_sX(_,_,_,epi_m,epi_n,pipeline_state_x.index()), tSR_rX);
          type_convert<ElementX, ElementAcc>(tSR_rX, tRS_rX);
        }

        if constexpr (HAS_Z) {
          // load x 
          copy(tiled_s2r_z, tSR_sZ(_,_,_,epi_m,epi_n,pipeline_state_z.index()), tSR_rZ);
          type_convert<ElementZ, ElementAcc>(tSR_rZ, tRS_rZ);
            // SiLu
            cutlass::epilogue::thread::SiLu<ElementAcc> op;
            for (int ii = 0; ii < size(tRS_rZ); ++ii) {
              tRS_rZ(ii) = op(tRS_rZ(ii));
            }
        }

        cooperate_pipeline.consumer_wait(cooperate_pipe_consumer_state);
        
        copy(tSR_sY_frg(_,cooperate_pipe_consumer_state.index()), tSR_rY_frg);

        cooperate_pipeline.consumer_release(cooperate_pipe_consumer_state);
        ++cooperate_pipe_consumer_state;
        
        cutlass::arch::fence_view_async_shared();
        synchronize();

        int mma_m = epi_m;
        int mma_n = (epi_n * size<1>(EpilogueTile{})) / mma_tile_n;
        // Tensor tRS_rIntra_frg_mn = tRS_rIntra_frg(_,mma_m,mma_n);
        Tensor tRS_rInter_frg_mn = tRS_rInter_frg(_,mma_m,mma_n);
        Tensor tRS_rDeltaA_frg_mn = tRS_rDeltaA_frg(_,mma_m,mma_n);
        Tensor tRS_rD_frg_mn = tRS_rD_frg(_,mma_m,mma_n);

        // Vectorized fragment loop with visitor callback entry point
        // Epilogue op
        int epi_n_in_mma = epi_n % (mma_tile_n / epi_tile_n);
        int r2s_v = epi_n_in_mma * size(tRS_rCompute_frg);
        CUTLASS_PRAGMA_UNROLL
        for (int epi_v = 0; epi_v < size(tRS_rCompute_frg); ++epi_v) {
          tRS_rCompute_frg(epi_v) = tRS_rDeltaA_frg_mn(r2s_v + epi_v) * tRS_rInter_frg_mn(r2s_v + epi_v) + tSR_rY_frg(epi_v);
          if constexpr (HAS_D) {
            tRS_rCompute_frg(epi_v) = tRS_rD_frg_mn(r2s_v + epi_v) * tRS_rX_frg(epi_v) + tRS_rCompute_frg(epi_v);
          }
          if constexpr (HAS_Z) {
            tRS_rCompute_frg(epi_v) = tRS_rCompute_frg(epi_v) * tRS_rZ_frg(epi_v);
          }
        }

        // The latest we can delay the TMA store is right before the smem store of the next iteration
        // since the current TMA store needs to be committed before we can acquire the next smem buffer
        if constexpr (DelayTmaStore) {
          // Issue TMA stores for the previous subtile
          if (not is_first_iteration and subtile_idx == -1) {
            tma_store_fn(epi_m_prev, epi_n_prev);
          }
          epi_m_prev = epi_m;
          epi_n_prev = epi_n;
        }

        CUTLASS_PRAGMA_UNROLL
        for (int i = 0; i < size(tRS_rY_frg); ++i) {
          tRS_rY_frg(i) = cutlass::NumericArrayConverter<ElementY, ElementAcc, FragmentSize>{}(tRS_rCompute_frg(i));
        }

        copy(tiled_r2s, tRS_rY, tRS_sY(_,_,_,store_pipe_producer_state.index()));

        if constexpr (not DelayTmaStore) {
          // Issue TMA stores for this subtile
          tma_store_fn(epi_m, epi_n);
        }

      } // for epi_m
    } // for epi_n

    pipeline_x.consumer_release(pipeline_state_x);
    ++pipeline_state_x;
    pipeline_z.consumer_release(pipeline_state_z);
    ++pipeline_state_z;

    if constexpr (DelayTmaStore) {
      // Issue TMA stores for the last subtile
      tma_store_fn(epi_m_prev, epi_n_prev);
    }

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
                      make_tensor(make_smem_ptr(ptr_sP), SmemLayoutP{}));             // (EPI_TILE_M,EPI_TILE_N)

    // thread(b)lock-partition for (s)mem to (g)mem copy (bSG_)
    auto oprands = tma_partition(params.tma_store_p, Int<0>{}, Layout<_1>{},
                                    group_modes<0,2>(sP_epi), group_modes<0,2>(gP_epi));  // (TMA,k) and (TMA,PIPE)
    // avoid "warning #3357-D: capturing structured bindings is a C++20 feature"
    auto bSG_gY = get<0>(oprands);
    auto bSG_sY = get<1>(oprands);

#if 0
    if (threadIdx.x % 128 == 0 && (blockIdx.x + blockIdx.y + blockIdx.z == 0)) {
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

