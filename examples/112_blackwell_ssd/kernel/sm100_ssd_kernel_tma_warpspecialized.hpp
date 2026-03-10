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
#include "cutlass/arch/reg_reconfig.h"
#include "cutlass/pipeline/pipeline.hpp"
#include "cutlass/arch/arch.h"

namespace cutlass::ssd::kernel {

using namespace cute;
    
template<
  class CollectiveMainloop_,
  class CollectiveEpilogue_,
  class TileScheduler_
>
struct SsdKernelTmaWarpSpecialized {

  using CollectiveMainloop = CollectiveMainloop_;
  using CollectiveEpilogue = CollectiveEpilogue_;
  using TileScheduler = TileScheduler_;

  // TileShape: LDN
  using TileShape = typename CollectiveMainloop::TileShape;
  // Force to use 1x1x1
  using ClusterShape = typename CollectiveMainloop::ClusterShape;
  using ArchTag = cutlass::arch::Sm100;

  static constexpr uint32_t NumMmaThreads            = NumThreadsPerWarp; // 1 warp
  static constexpr uint32_t NumEpilogueThreads       = CollectiveEpilogue::ThreadCount;
  static constexpr uint32_t NumEpilogueWarps         = NumEpilogueThreads / NumThreadsPerWarp;

  // Pipeline for Tensor X
  using MainloopPipelineX = typename CollectiveMainloop::MainloopPipelineX;
  using PipelineStateX    = typename cutlass::PipelineState<MainloopPipelineX::Stages>;
  using PipelineParamsX   = typename MainloopPipelineX::Params;

  // Pipeline for Tensor Delta && DeltaA
  using MainloopPipelineDelta = typename CollectiveMainloop::MainloopPipelineDelta;
  using PipelineStateDelta    = typename cutlass::PipelineState<MainloopPipelineDelta::Stages>;
  using PipelineParamsDelta   = typename MainloopPipelineDelta::Params;

  // Pipeline for Tensor X
  using MainloopPipelineB = typename CollectiveMainloop::MainloopPipelineB;
  using PipelineStateB    = typename cutlass::PipelineState<MainloopPipelineB::Stages>;
  using PipelineParamsB   = typename MainloopPipelineB::Params;

  // Pipeline for Tensor X
  using MainloopPipelineC = typename CollectiveMainloop::MainloopPipelineC;
  using PipelineStateC    = typename cutlass::PipelineState<MainloopPipelineC::Stages>;
  using PipelineParamsC   = typename MainloopPipelineC::Params;

  // Pipeline for Intra Fusion
  using MainloopPipelineIntra = typename CollectiveMainloop::MainloopPipelineIntra;
  using PipelineStateIntra    = typename cutlass::PipelineState<MainloopPipelineIntra::Stages>;
  using PipelineParamsIntra   = typename MainloopPipelineIntra::Params;

  // Pipeline for Inter Fusion
  using MainloopPipelineInter = typename CollectiveMainloop::MainloopPipelineInter;
  using PipelineStateInter    = typename cutlass::PipelineState<MainloopPipelineInter::Stages>;
  using PipelineParamsInter   = typename MainloopPipelineInter::Params;

  // Pipeline for Accumulator
  using AccumulatorPipeline = typename CollectiveMainloop::AccumulatorPipeline;
  using AccumulatorPipelineState = typename CollectiveMainloop::AccumulatorPipelineState;
  using PipelineParamsAcc   = typename AccumulatorPipeline::Params;

  // Pipeline for Epilgoue store
  using EpiStorePipeline = typename CollectiveEpilogue::StorePipeline;
  using EpiStorePipelineState = typename CollectiveEpilogue::StorePipelineState;

  // Pipeline for Epilgoue load D
  using EpiloadPipelineD  = typename CollectiveEpilogue::EpiloadPipelineD;
  using PipelineParamsD   = typename EpiloadPipelineD::Params;
  using PipelineStateD    = typename cutlass::PipelineState<EpiloadPipelineD::Stages>;
  using TmemAllocator = typename cute::TMEM::Allocator1Sm;

  struct SharedStorage {
    struct PipelineStorage : cute::aligned_struct<16, _1> {
      using PipelineStorageX = typename MainloopPipelineX::SharedStorage;
      using PipelineStorageDelta = typename MainloopPipelineDelta::SharedStorage;
      using PipelineStorageB = typename MainloopPipelineB::SharedStorage;
      using PipelineStorageC = typename MainloopPipelineC::SharedStorage;
      using PipelineStorageIntra = typename MainloopPipelineIntra::SharedStorage;
      using PipelineStorageInter = typename MainloopPipelineInter::SharedStorage;
      using PipelineStorageAcc   = typename AccumulatorPipeline::SharedStorage;
      using PipelineStorageD     = typename EpiloadPipelineD::SharedStorage;
      alignas(16) PipelineStorageX      pipeline_storage_x;
      alignas(16) PipelineStorageDelta  pipeline_storage_delta;
      alignas(16) PipelineStorageB      pipeline_storage_b;
      alignas(16) PipelineStorageC      pipeline_storage_c;
      alignas(16) PipelineStorageD      pipeline_storage_d;
      alignas(16) PipelineStorageIntra  pipeline_storage_intra;
      alignas(16) PipelineStorageInter  pipeline_storage_inter;
      alignas(16) PipelineStorageAcc    pipeline_storage_acc;
    } pipelines;

    uint32_t tmem_base_ptr;

    struct TensorStorage : cute::aligned_struct<128, _1> {
      using EpilogueTensorStorage = typename CollectiveEpilogue::TensorStorage;
      using MainloopTensorStorage = typename CollectiveMainloop::TensorStorage;

      EpilogueTensorStorage epilogue;
      MainloopTensorStorage mainloop;
    } tensors;
  };

  static constexpr int SharedStorageSize = sizeof(SharedStorage);
  // [G, B, EH, C, L, D, N]
  using ProblemShape = cute::tuple<int, int, int, int, int, int, int>;

  struct Arguments {
    ProblemShape problem_size;
    typename CollectiveMainloop::Arguments mainloop;
    typename CollectiveEpilogue::Arguments epilogue;
    KernelHardwareInfo hw_info;
  };

  struct Params {
    ProblemShape problem_size;
    typename CollectiveMainloop::Params mainloop;
    typename CollectiveEpilogue::Params epilogue;
    typename TileScheduler::Params tile_scheduler;
  };

  static const int MinBlocksPerMultiprocessor = 1;
  static const int MaxThreadsPerBlock = 384;

  static size_t get_workspace_size(Arguments const& args) { return 0; }
  static cutlass::Status initialize_workspace(Arguments const&, void*, cudaStream_t) {
    return cutlass::Status::kSuccess;
  }

  static bool can_implement(Arguments const& args) {
    return CollectiveMainloop::can_implement(args.problem_size, args.mainloop);
  }

  static dim3 get_grid_shape(Params const& params) {
    return TileScheduler::get_grid_shape(params.tile_scheduler);
  }

  static dim3 get_block_shape() {
    dim3 block(MaxThreadsPerBlock, 1, 1);
    return block;
  }

  static Params to_underlying_arguments(Arguments const& args, void* workspace) {
    return Params{
        args.problem_size,
        CollectiveMainloop::to_underlying_arguments(args.problem_size, args.mainloop, workspace),
        CollectiveEpilogue::to_underlying_arguments(args.problem_size, args.epilogue, workspace),
        TileScheduler::to_underlying_arguments(args.problem_size, args.hw_info, ClusterShape{}, TileShape{})
    };
  }

  CUTLASS_DEVICE void operator()(const Params &params, char* smem) {

    using namespace cute;
    using X = Underscore;

    // TBD
    enum class WarpCategory : int32_t {
      MMAInter      = 0,
      MMAIntra      = 1,
      DMA0          = 2, // Delta, X
      DMA1          = 3, // B, C
      PreInter      = 4,
      PreIntra      = 8
    };

    // Parameters
    // [G, B, EH, C, L, D, N]
    auto C = get<3>(params.problem_size);

    // Shared memory.
    auto& storage = *reinterpret_cast<SharedStorage*>(smem);
  
    int lane_predicate = cute::elect_one_sync();
    int lane_idx = cutlass::canonical_lane_idx();
    int warp_idx = cutlass::canonical_warp_idx_sync();
    auto warp_category = (WarpCategory(warp_idx) < WarpCategory::PreInter) ?
                            WarpCategory(warp_idx) : 
                            (WarpCategory(warp_idx) < WarpCategory::PreIntra) ?
                            WarpCategory::PreInter : WarpCategory::PreIntra;

    // Issue Tma Descriptor Prefetch from a single thread
    if ((warp_idx == 0) && lane_predicate) {
      CollectiveMainloop::prefetch_tma_descriptors(params.mainloop);
    }

    // Pipeline (TBD)
    PipelineParamsX pipeline_params_x;
    pipeline_params_x.transaction_bytes = CollectiveMainloop::kXLoadBytes;
    pipeline_params_x.is_leader = lane_predicate && (warp_category == WarpCategory::DMA0);
    pipeline_params_x.num_consumers = 1 + 1 + cutlass::NumThreadsPerWarpGroup; // MMA0 + MMA1 + PreInter
    pipeline_params_x.initializing_warp = 4;

    PipelineParamsDelta pipeline_params_delta;
    pipeline_params_delta.transaction_bytes = CollectiveMainloop::kDeltaLoadBytes + CollectiveMainloop::kDeltaALoadBytes;
    pipeline_params_delta.is_leader = lane_predicate && (warp_category == WarpCategory::DMA0);
    pipeline_params_delta.num_consumers = cutlass::NumThreadsPerWarpGroup + cutlass::NumThreadsPerWarpGroup; // PreInter + PreIntra
    pipeline_params_delta.initializing_warp = 5;

    PipelineParamsB pipeline_params_b;
    pipeline_params_b.transaction_bytes = CollectiveMainloop::kBLoadBytes;
    pipeline_params_b.is_leader = lane_predicate && (warp_category == WarpCategory::DMA1);
    pipeline_params_b.num_consumers = 1 + cutlass::NumThreadsPerWarpGroup;
    pipeline_params_b.initializing_warp = 6;

    PipelineParamsC pipeline_params_c;
    pipeline_params_c.transaction_bytes = CollectiveMainloop::kCLoadBytes;
    pipeline_params_c.is_leader = lane_predicate && (warp_category == WarpCategory::DMA1);
    pipeline_params_c.num_consumers = 1 + 1;
    pipeline_params_c.initializing_warp = 7;

    PipelineParamsIntra pipeline_params_intra;
    pipeline_params_intra.producer_arv_count = 1;
    pipeline_params_intra.consumer_arv_count = cutlass::NumThreadsPerWarpGroup;
    pipeline_params_intra.initializing_warp = 8;

    PipelineParamsIntra pipeline_params_inter;
    pipeline_params_inter.producer_arv_count = 1;
    pipeline_params_inter.consumer_arv_count = cutlass::NumThreadsPerWarpGroup;
    pipeline_params_inter.initializing_warp = 9;

    PipelineParamsAcc pipeline_params_acc;
    pipeline_params_acc.producer_arv_count = 1;
    pipeline_params_acc.consumer_arv_count = cutlass::NumThreadsPerWarpGroup;
    pipeline_params_acc.initializing_warp = 10;

    PipelineParamsD pipeline_params_d;
    pipeline_params_d.transaction_bytes = CollectiveEpilogue::kEpiloadDBytes;
    pipeline_params_d.is_leader = lane_predicate && (warp_category == WarpCategory::DMA0);
    pipeline_params_d.num_consumers = cutlass::NumThreadsPerWarpGroup;
    pipeline_params_d.initializing_warp = 11;
    

    if (warp_category == WarpCategory::DMA0) {
      pipeline_params_x.role = MainloopPipelineX::ThreadCategory::Producer;
      pipeline_params_delta.role = MainloopPipelineDelta::ThreadCategory::Producer;
      pipeline_params_d.role = EpiloadPipelineD::ThreadCategory::Producer;
    }
    if (warp_category == WarpCategory::DMA1) {
      pipeline_params_b.role = MainloopPipelineB::ThreadCategory::Producer;
      pipeline_params_c.role = MainloopPipelineC::ThreadCategory::Producer;
    }
    // TBD
    if (warp_category == WarpCategory::MMAInter) {
      pipeline_params_x.role      = MainloopPipelineX::ThreadCategory::Consumer;
      // pipeline_params_b.role      = MainloopPipelineB::ThreadCategory::Consumer;
      pipeline_params_c.role      = MainloopPipelineC::ThreadCategory::Consumer;
      pipeline_params_inter.role  = MainloopPipelineInter::ThreadCategory::Producer;
      pipeline_params_acc.role    = AccumulatorPipeline::ThreadCategory::Producer;
    }
    if (warp_category == WarpCategory::MMAIntra) {
      pipeline_params_x.role      = MainloopPipelineX::ThreadCategory::Consumer;
      pipeline_params_b.role      = MainloopPipelineB::ThreadCategory::Consumer;
      pipeline_params_c.role      = MainloopPipelineC::ThreadCategory::Consumer;
      pipeline_params_intra.role  = MainloopPipelineIntra::ThreadCategory::Producer;
    }
    if (warp_category == WarpCategory::PreInter) {
      pipeline_params_b.role      = MainloopPipelineB::ThreadCategory::Consumer;
      pipeline_params_delta.role  = MainloopPipelineDelta::ThreadCategory::Consumer;
      pipeline_params_inter.role  = MainloopPipelineInter::ThreadCategory::Consumer;
    }
    if (warp_category == WarpCategory::PreIntra) {
      pipeline_params_x.role      = MainloopPipelineX::ThreadCategory::Consumer;
      pipeline_params_delta.role  = MainloopPipelineDelta::ThreadCategory::Consumer;
      pipeline_params_acc.role    = AccumulatorPipeline::ThreadCategory::Consumer;
      pipeline_params_intra.role  = MainloopPipelineIntra::ThreadCategory::Consumer;
      pipeline_params_d.role      = EpiloadPipelineD::ThreadCategory::Consumer;
    }

    MainloopPipelineX pipeline_x(storage.pipelines.pipeline_storage_x, pipeline_params_x, Shape<_1,_1,_1>{});
    PipelineStateX mainloop_pipe_x_consumer;
    PipelineStateX mainloop_pipe_x_producer = cutlass::make_producer_start_state<MainloopPipelineX>();

    MainloopPipelineDelta pipeline_delta(storage.pipelines.pipeline_storage_delta, pipeline_params_delta, Shape<_1,_1,_1>{});
    PipelineStateDelta mainloop_pipe_delta_consumer;
    PipelineStateDelta mainloop_pipe_delta_producer = cutlass::make_producer_start_state<MainloopPipelineDelta>();

    MainloopPipelineB pipeline_b(storage.pipelines.pipeline_storage_b, pipeline_params_b, Shape<_1,_1,_1>{});
    PipelineStateB mainloop_pipe_b_consumer;
    PipelineStateB mainloop_pipe_b_producer = cutlass::make_producer_start_state<MainloopPipelineB>();

    MainloopPipelineC pipeline_c(storage.pipelines.pipeline_storage_c, pipeline_params_c, Shape<_1,_1,_1>{});
    PipelineStateC mainloop_pipe_c_consumer;
    PipelineStateC mainloop_pipe_c_producer = cutlass::make_producer_start_state<MainloopPipelineC>();

    EpiloadPipelineD pipeline_d(storage.pipelines.pipeline_storage_d, pipeline_params_d, Shape<_1,_1,_1>{});
    PipelineStateD epi_load_pipe_d_consumer;
    PipelineStateD epi_load_pipe_d_producer = cutlass::make_producer_start_state<EpiloadPipelineD>();
  
    MainloopPipelineIntra pipeline_intra(storage.pipelines.pipeline_storage_intra, pipeline_params_intra, Shape<_1,_1,_1>{});
    PipelineStateIntra mainloop_pipe_intra_consumer;
    PipelineStateIntra mainloop_pipe_intra_producer = cutlass::make_producer_start_state<MainloopPipelineIntra>();

    MainloopPipelineInter pipeline_inter(storage.pipelines.pipeline_storage_inter, pipeline_params_inter, Shape<_1,_1,_1>{});
    // Opposite pipeline state
    PipelineStateInter mainloop_pipe_inter_consumer = cutlass::make_producer_start_state<MainloopPipelineIntra>();
    PipelineStateInter mainloop_pipe_inter_producer;

    AccumulatorPipeline pipeline_acc(storage.pipelines.pipeline_storage_acc, pipeline_params_acc, Shape<_1,_1,_1>{});
    AccumulatorPipelineState mainloop_pipe_acc_consumer;
    AccumulatorPipelineState mainloop_pipe_acc_producer = cutlass::make_producer_start_state<AccumulatorPipeline>();

    // Epilogue Store pipeline
    using EpiStorePipeline = typename CollectiveEpilogue::StorePipeline;
    typename EpiStorePipeline::Params epi_store_pipeline_params;
    epi_store_pipeline_params.always_wait = true;
    EpiStorePipeline epi_store_pipeline(epi_store_pipeline_params);

    PipelineState epi_store_pipe_producer_state = cutlass::make_producer_start_state<EpiStorePipeline>();
    
    // Epilogue Store P pipeline
    using EpiStorePPipeline = typename CollectiveEpilogue::StorePPipeline;
    typename EpiStorePPipeline::Params epi_store_p_pipeline_params;
    epi_store_p_pipeline_params.always_wait = true;
    EpiStorePPipeline epi_store_p_pipeline(epi_store_p_pipeline_params);

    PipelineState epi_store_p_pipe_producer_state = cutlass::make_producer_start_state<EpiStorePPipeline>();

    // Tmem allocator
    TmemAllocator tmem_allocator{};
    // We need this to guarantee that the Pipeline init is visible
    // To all producers and consumer blocks in the Cluster
    // and to finish smem init
    if constexpr (size(ClusterShape{}) > 1) {
      cute::cluster_arrive_relaxed();
      cute::cluster_wait();
    }
    else {
      __syncthreads();
    }

    // ignore the tmem alloc 
    arch::NamedBarrier tmem_allocation_result_barrier(NumMmaThreads + NumMmaThreads + NumEpilogueThreads + NumEpilogueThreads,
                                                      cutlass::arch::ReservedNamedBarriers::TmemAllocBarrier);
    if (warp_category == WarpCategory::MMAIntra) {
      tmem_allocator.allocate(TmemAllocator::Sm100TmemCapacityColumns, &storage.tmem_base_ptr);
      __syncwarp();
      tmem_allocation_result_barrier.arrive();
    }
    if (warp_category == WarpCategory::MMAInter || warp_category == WarpCategory::PreIntra || warp_category == WarpCategory::PreInter) {
      tmem_allocation_result_barrier.arrive_and_wait();
    }

    // Kernel implement(TBD)
    
    CollectiveMainloop collective_mainloop;
    CollectiveEpilogue collective_epilogue;
    TileScheduler tile_scheduler{params.tile_scheduler};

    auto mma_output_intra = collective_mainloop.get_mma_intra_acc();
    auto mma_output_inter = collective_mainloop.get_mma_inter_acc();

    if (warp_category == WarpCategory::DMA0) {
      auto load_input = collective_mainloop.load_x_init(params.mainloop, params.problem_size);
      for (; tile_scheduler.is_valid(); ++tile_scheduler) {
        auto blk_coord = tile_scheduler.get_block_coord();
        auto blk_coord_eh = tile_scheduler.get_block_coord_eh();
        // Load D
        collective_epilogue.load_d(
          blk_coord_eh, params.epilogue, params.problem_size,
          pipeline_d, epi_load_pipe_d_producer,
          storage.tensors.mainloop
        );
        // Load X
        // Load Delta
        // Load DeltaA
        collective_mainloop.load_x_delta(
          blk_coord, params.mainloop, params.problem_size,
          pipeline_x, mainloop_pipe_x_producer,
          pipeline_delta, mainloop_pipe_delta_producer,
          load_input,
          storage.tensors.mainloop
        );
      }
    }
    else if (warp_category == WarpCategory::DMA1) {
      auto load_input_b = collective_mainloop.load_b_init(params.mainloop, params.problem_size);
      auto load_input_c = collective_mainloop.load_c_init(params.mainloop, params.problem_size);
      for (; tile_scheduler.is_valid(); ++tile_scheduler) {
        auto blk_coord = tile_scheduler.get_block_coord_b();
        // Load B
        // Load C
        collective_mainloop.load_b_c(
          blk_coord, params.mainloop, params.problem_size,
          pipeline_b, mainloop_pipe_b_producer,
          pipeline_c, mainloop_pipe_c_producer,
          load_input_b, load_input_c,
          storage.tensors.mainloop
        );
      }
    }
    else if (warp_category == WarpCategory::MMAIntra) {
      auto [mma_inputs_1, mma_inputs_2] = collective_mainloop.mma_intra_init(storage.tensors.mainloop);
      for (; tile_scheduler.is_valid(); ++tile_scheduler) {
        for (int chunk = 0; chunk < C; ++chunk) {
          collective_mainloop.mma_intra(
            pipeline_b, mainloop_pipe_b_consumer,
            pipeline_c, mainloop_pipe_c_consumer,
            pipeline_x, mainloop_pipe_x_consumer,
            pipeline_intra, mainloop_pipe_intra_producer,
            mma_inputs_1, mma_inputs_2,
            mma_output_intra
          );
        }
      }
    }
    else if (warp_category == WarpCategory::MMAInter) {
      auto [mma_inputs_1, mma_inputs_2] = collective_mainloop.mma_inter_init(storage.tensors.mainloop);
      for (; tile_scheduler.is_valid(); ++tile_scheduler) {
        for (int chunk = 0; chunk < C; ++chunk) {
          collective_mainloop.mma_inter(
            pipeline_c, mainloop_pipe_c_consumer,
            pipeline_x, mainloop_pipe_x_consumer,
            pipeline_inter, mainloop_pipe_inter_producer,
            pipeline_acc, mainloop_pipe_acc_producer,
            mma_inputs_1, mma_inputs_2,
            mma_output_inter
          );
        }
      }
    }
    else if (warp_category == WarpCategory::PreIntra) {
      for (; tile_scheduler.is_valid(); ++tile_scheduler) {
        auto blk_coord = tile_scheduler.get_block_coord();
        auto blk_coord_eh = tile_scheduler.get_block_coord_eh();
        bool is_first_iteration = true;
        for (int chunk = 0; chunk < C; ++chunk) {
          collective_mainloop.pre_intra(
            pipeline_delta, mainloop_pipe_delta_consumer,
            pipeline_intra, mainloop_pipe_intra_consumer,
            mma_output_intra,
            storage.tensors.mainloop
          );
          collective_epilogue.store(
            chunk, blk_coord, blk_coord_eh, params.epilogue, params.problem_size,
            pipeline_intra, mainloop_pipe_intra_consumer,
            pipeline_acc, mainloop_pipe_acc_consumer,
            pipeline_delta, mainloop_pipe_delta_consumer,
            pipeline_x, mainloop_pipe_x_consumer,
            pipeline_d, epi_load_pipe_d_consumer,
            epi_store_pipeline, epi_store_pipe_producer_state,
            mma_output_intra,
            mma_output_inter,
            storage.tensors.mainloop, storage.tensors.epilogue,
            is_first_iteration
          );
          is_first_iteration = false;
        }
        if constexpr (CollectiveEpilogue::HasBlockScaleD) {
          // update the barrier
          pipeline_d.consumer_release(epi_load_pipe_d_consumer);
          ++epi_load_pipe_d_consumer;
        }
      }
      uint32_t free_stage_ptr = storage.tmem_base_ptr;
      tmem_allocator.free(free_stage_ptr, TmemAllocator::Sm100TmemCapacityColumns);
    }
    else if (warp_category == WarpCategory::PreInter) {
      for (; tile_scheduler.is_valid(); ++tile_scheduler) {
        auto [tState] = collective_mainloop.state_init(mma_output_inter, storage.tensors.mainloop);
        for (int chunk = 0; chunk < C; ++chunk) {
          collective_mainloop.pre_inter(
            pipeline_b, mainloop_pipe_b_consumer,
            pipeline_delta, mainloop_pipe_delta_consumer,
            pipeline_inter, mainloop_pipe_inter_consumer,
            mma_output_inter,
            tState,
            storage.tensors.mainloop
          );
        }
        auto blk_coord = tile_scheduler.get_block_coord();
        // Epilogue Fstate store
        collective_epilogue.store_p(
          blk_coord, params.epilogue, params.problem_size,
          epi_store_p_pipeline, epi_store_p_pipe_producer_state,
          storage.tensors.mainloop
        );
      }
    }
  }
};

}  // namespace cutlass::ssd::kernel
