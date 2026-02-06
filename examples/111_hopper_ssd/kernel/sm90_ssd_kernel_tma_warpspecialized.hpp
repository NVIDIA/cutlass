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
  class CollectiveMainloop,
  class CollectiveEpilogue,
  class TileScheduler
>
struct SsdKernelTmaWarpSpecialized {

  static const int NumLoadWarpGroups = 1;
  // hard code
  static constexpr int NumMmaWarpGroups = 2;

  // TileShape: LDN
  using TileShape = typename CollectiveMainloop::TileShape;
  // Force to use 1x1x1
  using ClusterShape = typename CollectiveMainloop::ClusterShape;

  // Pipeline for Tensor X
  using MainloopPipelineX = typename CollectiveMainloop::MainloopPipelineX;
  using PipelineParamsX   = typename MainloopPipelineX::Params;
  using PipelineStateX    = typename cutlass::PipelineState<MainloopPipelineX::Stages>;

  // Pipeline for Tensor Delta && DeltaA
  using MainloopPipelineDelta = typename CollectiveMainloop::MainloopPipelineDelta;
  using PipelineParamsDelta   = typename MainloopPipelineDelta::Params;
  using PipelineStateDelta    = typename cutlass::PipelineState<MainloopPipelineDelta::Stages>;

  // Pipeline for Tensor X
  using MainloopPipelineB = typename CollectiveMainloop::MainloopPipelineB;
  using PipelineParamsB   = typename MainloopPipelineB::Params;
  using PipelineStateB    = typename cutlass::PipelineState<MainloopPipelineB::Stages>;

  // Pipeline for Tensor X
  using MainloopPipelineC = typename CollectiveMainloop::MainloopPipelineC;
  using PipelineParamsC   = typename MainloopPipelineC::Params;
  using PipelineStateC    = typename cutlass::PipelineState<MainloopPipelineC::Stages>;

  // Pipeline for cooperate-warps
  using CooperatePipeline = typename CollectiveEpilogue::CooperatePipeline;
  using PipelineParamsCo  = typename CooperatePipeline::Params;
  using PipelineStateCo   = typename cutlass::PipelineState<CooperatePipeline::Stages>;

  // Pipeline for Tensor D
  using EpiloadPipelineD  = typename CollectiveEpilogue::EpiloadPipelineD;
  using PipelineParamsD   = typename EpiloadPipelineD::Params;
  using PipelineStateD    = typename cutlass::PipelineState<EpiloadPipelineD::Stages>;

  // Pipeline for Tensor Z
  using EpiloadPipelineZ  = typename CollectiveEpilogue::EpiloadPipelineZ;
  using PipelineParamsZ   = typename EpiloadPipelineZ::Params;
  using PipelineStateZ    = typename cutlass::PipelineState<EpiloadPipelineZ::Stages>;

  struct TensorStorage {
    typename CollectiveMainloop::SharedStorage mainloop;
    typename CollectiveEpilogue::TensorStorage epilogue;
  };

  struct SharedStorage {
    TensorStorage tensors;

    using PipelineStorageX = typename MainloopPipelineX::SharedStorage;
    using PipelineStorageDelta = typename MainloopPipelineDelta::SharedStorage;
    using PipelineStorageB = typename MainloopPipelineB::SharedStorage;
    using PipelineStorageC = typename MainloopPipelineC::SharedStorage;
    using PipelineStorageCo = typename CooperatePipeline::SharedStorage;
    using PipelineStorageD = typename EpiloadPipelineD::SharedStorage;
    using PipelineStorageZ = typename EpiloadPipelineZ::SharedStorage;

    // pipeline
    alignas(16) PipelineStorageX     pipeline_storage_x;
    alignas(16) PipelineStorageDelta pipeline_storage_delta;
    alignas(16) PipelineStorageB     pipeline_storage_b;
    alignas(16) PipelineStorageC     pipeline_storage_c;
    alignas(16) PipelineStorageCo    pipeline_storage_co;
    alignas(16) PipelineStorageD     pipeline_storage_d;
    alignas(16) PipelineStorageZ     pipeline_storage_z;
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
  static const int MaxThreadsPerBlock = (NumMmaWarpGroups + NumLoadWarpGroups) * cutlass::NumThreadsPerWarpGroup;
  using ArchTag = cutlass::arch::Sm90;

  // CTA reconfig (TBD)
  static constexpr uint32_t LoadRegisterRequirement = 40 - 2 * 8;
  static constexpr uint32_t TotalRegisterSupply = (64*1024 / MaxThreadsPerBlock / MinBlocksPerMultiprocessor / 8) * 8 * MaxThreadsPerBlock / cutlass::NumThreadsPerWarpGroup;
  static constexpr uint32_t MmaRegisterRequirement = ((TotalRegisterSupply - LoadRegisterRequirement) / NumMmaWarpGroups / 8) * 8;
  // static constexpr uint32_t LoadRegisterRequirement = 40;
  // static constexpr uint32_t MmaRegisterRequirement = 232;

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

    // TBD
    enum class WarpGroupRole {
      Producer = 0,
      Consumer0 = 1,
      Consumer1 = 2
    };
    // TBD
    enum class ProducerWarpRole {
      LoadX = 0,
      LoadDelta = 1,
      LoadBC = 2,
      LoadZ = 3
    };


    // Parameters
    // [G, B, EH, C, L, D, N]
    auto C = get<3>(params.problem_size);

    // Shared memory.
    auto& storage = *reinterpret_cast<SharedStorage*>(smem);
  
    int lane_idx = cutlass::canonical_lane_idx();
    int warp_idx = cutlass::canonical_warp_idx_sync();
    int warp_idx_in_warp_group = warp_idx % cutlass::NumWarpsPerWarpGroup;
    int warp_group_idx = cutlass::canonical_warp_group_idx();
    auto warp_group_role = WarpGroupRole(warp_group_idx);
    auto producer_warp_role = ProducerWarpRole(warp_idx_in_warp_group);
    int lane_predicate = cute::elect_one_sync();
    uint32_t block_rank_in_cluster = cute::block_rank_in_cluster();

    // Issue Tma Descriptor Prefetch from a single thread
    if ((warp_idx == 0) && lane_predicate) {
      CollectiveMainloop::prefetch_tma_descriptors(params.mainloop);
    }

    // Pipeline (TBD)
    PipelineParamsX pipeline_params_x;
    pipeline_params_x.transaction_bytes = CollectiveMainloop::kXLoadBytes;
    pipeline_params_x.is_leader = lane_predicate && (producer_warp_role == ProducerWarpRole::LoadX);
    pipeline_params_x.num_consumers = cutlass::NumThreadsPerWarpGroup * NumMmaWarpGroups;
    pipeline_params_x.initializing_warp = 4;

    PipelineParamsDelta pipeline_params_delta;
    pipeline_params_delta.transaction_bytes = CollectiveMainloop::kDeltaLoadBytes + CollectiveMainloop::kDeltaALoadBytes;
    pipeline_params_delta.is_leader = lane_predicate && (producer_warp_role == ProducerWarpRole::LoadDelta);
    pipeline_params_delta.num_consumers = cutlass::NumThreadsPerWarpGroup * NumMmaWarpGroups;
    pipeline_params_delta.initializing_warp = 5;

    PipelineParamsB pipeline_params_b;
    pipeline_params_b.transaction_bytes = CollectiveMainloop::kBLoadBytes;
    pipeline_params_b.is_leader = lane_predicate && (producer_warp_role == ProducerWarpRole::LoadBC);
    pipeline_params_b.num_consumers = cutlass::NumThreadsPerWarpGroup * NumMmaWarpGroups;
    pipeline_params_b.initializing_warp = 6;

    PipelineParamsC pipeline_params_c;
    pipeline_params_c.transaction_bytes = CollectiveMainloop::kCLoadBytes;
    pipeline_params_c.is_leader = lane_predicate && (producer_warp_role == ProducerWarpRole::LoadBC);
    pipeline_params_c.num_consumers = cutlass::NumThreadsPerWarpGroup * NumMmaWarpGroups;
    pipeline_params_c.initializing_warp = 7;

    PipelineParamsCo pipeline_params_co;
    pipeline_params_co.producer_arv_count = cutlass::NumThreadsPerWarpGroup;
    pipeline_params_co.consumer_arv_count = cutlass::NumThreadsPerWarpGroup;
    pipeline_params_co.initializing_warp = 8;

    PipelineParamsD pipeline_params_d;
    pipeline_params_d.transaction_bytes = CollectiveEpilogue::kEpiloadDBytes;
    pipeline_params_d.is_leader = lane_predicate && (producer_warp_role == ProducerWarpRole::LoadDelta);
    pipeline_params_d.num_consumers = cutlass::NumThreadsPerWarpGroup;
    pipeline_params_d.initializing_warp = 9;

    PipelineParamsZ pipeline_params_z;
    pipeline_params_z.transaction_bytes = CollectiveEpilogue::kEpiloadZBytes;
    pipeline_params_z.is_leader = lane_predicate && (producer_warp_role == ProducerWarpRole::LoadZ);
    pipeline_params_z.num_consumers = cutlass::NumThreadsPerWarpGroup;
    pipeline_params_z.initializing_warp = 10;

    if (warp_group_role == WarpGroupRole::Producer && producer_warp_role == ProducerWarpRole::LoadX) {
      pipeline_params_x.role = MainloopPipelineX::ThreadCategory::Producer;
    }
    if (warp_group_role == WarpGroupRole::Producer && producer_warp_role == ProducerWarpRole::LoadDelta) {
      pipeline_params_delta.role = MainloopPipelineDelta::ThreadCategory::Producer;
      pipeline_params_d.role = EpiloadPipelineD::ThreadCategory::Producer;
    }
    if (warp_group_role == WarpGroupRole::Producer && producer_warp_role == ProducerWarpRole::LoadBC) {
      pipeline_params_b.role = MainloopPipelineB::ThreadCategory::Producer;
      pipeline_params_c.role = MainloopPipelineC::ThreadCategory::Producer;
    }
    if (warp_group_role == WarpGroupRole::Producer && producer_warp_role == ProducerWarpRole::LoadZ) {
      pipeline_params_z.role = EpiloadPipelineZ::ThreadCategory::Producer;
    }
    if (warp_group_role == WarpGroupRole::Consumer0 || warp_group_role == WarpGroupRole::Consumer1) {
      pipeline_params_x.role      = MainloopPipelineX::ThreadCategory::Consumer;
      pipeline_params_delta.role  = MainloopPipelineDelta::ThreadCategory::Consumer;
      pipeline_params_b.role      = MainloopPipelineB::ThreadCategory::Consumer;
      pipeline_params_c.role      = MainloopPipelineC::ThreadCategory::Consumer;
    }
    if (warp_group_role == WarpGroupRole::Consumer0) {
      pipeline_params_co.role = CooperatePipeline::ThreadCategory::Producer;
    }
    if (warp_group_role == WarpGroupRole::Consumer1) {
      pipeline_params_co.role = CooperatePipeline::ThreadCategory::Consumer;
      pipeline_params_d.role = EpiloadPipelineD::ThreadCategory::Consumer;
      pipeline_params_z.role = EpiloadPipelineZ::ThreadCategory::Consumer;
    }

    MainloopPipelineX pipeline_x(storage.pipeline_storage_x, pipeline_params_x, Shape<_1,_1,_1>{});
    PipelineStateX mainloop_pipe_x_consumer;
    PipelineStateX mainloop_pipe_x_producer = cutlass::make_producer_start_state<MainloopPipelineX>();

    MainloopPipelineDelta pipeline_delta(storage.pipeline_storage_delta, pipeline_params_delta, Shape<_1,_1,_1>{});
    PipelineStateDelta mainloop_pipe_delta_consumer;
    PipelineStateDelta mainloop_pipe_delta_producer = cutlass::make_producer_start_state<MainloopPipelineDelta>();

    MainloopPipelineB pipeline_b(storage.pipeline_storage_b, pipeline_params_b, Shape<_1,_1,_1>{});
    PipelineStateB mainloop_pipe_b_consumer;
    PipelineStateB mainloop_pipe_b_producer = cutlass::make_producer_start_state<MainloopPipelineB>();

    MainloopPipelineC pipeline_c(storage.pipeline_storage_c, pipeline_params_c, Shape<_1,_1,_1>{});
    PipelineStateC mainloop_pipe_c_consumer;
    PipelineStateC mainloop_pipe_c_producer = cutlass::make_producer_start_state<MainloopPipelineC>();

    CooperatePipeline pipeline_co(storage.pipeline_storage_co, pipeline_params_co);
    PipelineStateCo cooperate_pipe_consumer_state;
    PipelineStateCo cooperate_pipe_producer_state = cutlass::make_producer_start_state<CooperatePipeline>();
  
    EpiloadPipelineD pipeline_d(storage.pipeline_storage_d, pipeline_params_d, Shape<_1,_1,_1>{});
    PipelineStateD epi_load_pipe_d_consumer;
    PipelineStateD epi_load_pipe_d_producer = cutlass::make_producer_start_state<EpiloadPipelineD>();

    EpiloadPipelineZ pipeline_z(storage.pipeline_storage_z, pipeline_params_z, Shape<_1,_1,_1>{});
    PipelineStateZ epi_load_pipe_z_consumer;
    PipelineStateZ epi_load_pipe_z_producer = cutlass::make_producer_start_state<EpiloadPipelineZ>();

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

    // Kernel implement(TBD)
    
    CollectiveMainloop collective_mainloop;
    CollectiveEpilogue collective_epilogue;

    if (warp_group_role == WarpGroupRole::Producer) {
      // disable reg dealloc to enable print
      cutlass::arch::warpgroup_reg_dealloc<LoadRegisterRequirement>();
      if (producer_warp_role == ProducerWarpRole::LoadX) {
        // use local variable to avoid STL/LDL
        TileScheduler tile_scheduler{params.tile_scheduler};
        auto load_input = collective_mainloop.load_x_init(params.mainloop, params.problem_size);
        for (; tile_scheduler.is_valid(); ++tile_scheduler) {
          auto blk_coord = tile_scheduler.get_block_coord();
          // Load X
          collective_mainloop.load_x(
            blk_coord, params.mainloop, params.problem_size,
            pipeline_x, mainloop_pipe_x_producer,
            load_input,
            storage.tensors.mainloop
          );
        }
        collective_mainloop.load_x_tail(
          pipeline_x, mainloop_pipe_x_producer
        );
      }
      else if (producer_warp_role == ProducerWarpRole::LoadDelta) {
        TileScheduler tile_scheduler{params.tile_scheduler};
        for (; tile_scheduler.is_valid(); ++tile_scheduler) {
          auto blk_coord = tile_scheduler.get_block_coord();
          auto blk_coord_eh = tile_scheduler.get_block_coord_eh();
          // Epiload 
          collective_epilogue.load_d(
            blk_coord_eh, params.epilogue, params.problem_size,
            pipeline_d, epi_load_pipe_d_producer,
            storage.tensors.mainloop
          );
          // Load Delta
          // Load DeltaA
          collective_mainloop.load_delta(
            blk_coord, params.mainloop, params.problem_size,
            pipeline_delta, mainloop_pipe_delta_producer,
            storage.tensors.mainloop
          );
        }
        collective_mainloop.load_delta_tail(
          pipeline_delta, mainloop_pipe_delta_producer
        );
      }
      else if (producer_warp_role == ProducerWarpRole::LoadBC) {
        TileScheduler tile_scheduler{params.tile_scheduler};
        auto load_input_b = collective_mainloop.load_b_init(params.mainloop, params.problem_size);
        auto load_input_c = collective_mainloop.load_c_init(params.mainloop, params.problem_size);
        for (; tile_scheduler.is_valid(); ++tile_scheduler) {
          auto blk_coord = tile_scheduler.get_block_coord_b();
          // Load B
          collective_mainloop.load_b_c(
            blk_coord, params.mainloop, params.problem_size,
            pipeline_b, mainloop_pipe_b_producer,
            pipeline_c, mainloop_pipe_c_producer,
            load_input_b,
            load_input_c,
            storage.tensors.mainloop
          );
        }
        collective_mainloop.load_b_c_tail(
          pipeline_b, mainloop_pipe_b_producer,
          pipeline_c, mainloop_pipe_c_producer
        );
      }
      else if (producer_warp_role == ProducerWarpRole::LoadZ) {
        // use local variable to avoid STL/LDL
        TileScheduler tile_scheduler{params.tile_scheduler};
        auto load_input = collective_epilogue.load_z_init(params.epilogue, params.problem_size);
        for (; tile_scheduler.is_valid(); ++tile_scheduler) {
          auto blk_coord = tile_scheduler.get_block_coord();
          // Load X
          collective_epilogue.load_z(
            blk_coord, params.epilogue, params.problem_size,
            pipeline_z, epi_load_pipe_z_producer,
            load_input,
            storage.tensors.epilogue
          );
        }
        collective_epilogue.load_z_tail(
          pipeline_z, epi_load_pipe_z_producer
        );
      }
    }
    // Warpgroup1 for Intra
    // Warpgroup2 for Inter
    else if (warp_group_role == WarpGroupRole::Consumer0) {
      TileScheduler tile_scheduler{params.tile_scheduler};
      cutlass::arch::warpgroup_reg_alloc<MmaRegisterRequirement>();
      for (; tile_scheduler.is_valid(); ++tile_scheduler) {
        for (int chunk = 0; chunk < C; ++chunk) {
          auto blk_coord = tile_scheduler.get_block_coord();
          // IntraBMM1
          // Wait B
          // Wait C
          auto [tIntra1] = collective_mainloop.mma_intra_1(
            chunk,
            pipeline_b, mainloop_pipe_b_consumer,
            pipeline_c, mainloop_pipe_c_consumer,
            storage.tensors.mainloop
          );
          // Pre Intra2
          auto [tPreIntra2] = collective_mainloop.pre_intra_2(
            chunk,
            pipeline_delta, mainloop_pipe_delta_consumer,
            tIntra1,
            storage.tensors.mainloop
          );
          // IntraBMM2
          auto [tIntra2] = collective_mainloop.mma_intra_2(
            chunk,
            pipeline_x, mainloop_pipe_x_consumer,
            tPreIntra2,
            storage.tensors.mainloop
          );
          collective_epilogue.store_intra(
            chunk, blk_coord, params.epilogue, params.problem_size,
            pipeline_co, cooperate_pipe_producer_state,
            tIntra2,
            typename CollectiveMainloop::TiledMmaIntra2{},
            storage.tensors.epilogue
          );
        }
      }
    }
    else if (warp_group_role == WarpGroupRole::Consumer1) {
      TileScheduler tile_scheduler{params.tile_scheduler};
      cutlass::arch::warpgroup_reg_alloc<MmaRegisterRequirement>();
      for (; tile_scheduler.is_valid(); ++tile_scheduler) {
        auto [tState] = collective_mainloop.state_init(storage.tensors.mainloop);
        auto blk_coord_eh = tile_scheduler.get_block_coord_eh();
        bool is_first_iteration = true;
        for (int chunk = 0; chunk < C; ++chunk) {
          auto blk_coord = tile_scheduler.get_block_coord();
          // Pre Inter1
          // Wait delta
          // Wait deltaA
          auto [tPreInter1, last_column] = collective_mainloop.pre_inter_1(
            chunk,
            pipeline_b, mainloop_pipe_b_consumer,
            pipeline_delta, mainloop_pipe_delta_consumer,
            storage.tensors.mainloop
          );
          // InterBMM1
          // Wait X
          auto [tInter1] = collective_mainloop.mma_inter_1(
            chunk,
            pipeline_x, mainloop_pipe_x_consumer,
            tPreInter1,
            storage.tensors.mainloop
          );
          collective_mainloop.pre_inter_2(
            last_column,
            tInter1,
            tState
          );
          // InterBMM2
          auto [tInter2, tDelta] = collective_mainloop.mma_inter_2(
            chunk,
            pipeline_c, mainloop_pipe_c_consumer,
            pipeline_delta, mainloop_pipe_delta_consumer,
            storage.tensors.mainloop
          );
          // Pre Inter2
          collective_mainloop.post_inter_2(
            tState,
            storage.tensors.mainloop
          );
          // update_d
          auto [tD] = collective_epilogue.update_d(
            blk_coord_eh, params.epilogue, 
            is_first_iteration,
            pipeline_d, epi_load_pipe_d_consumer,
            typename CollectiveMainloop::TiledMmaInter2{},
            storage.tensors.mainloop
          );
          is_first_iteration = false;
          // Epilogue TensorY store
          collective_epilogue.store(
            chunk, blk_coord, params.epilogue, params.problem_size,
            epi_store_pipeline, epi_store_pipe_producer_state,
            pipeline_co, cooperate_pipe_consumer_state,
            pipeline_x, mainloop_pipe_x_consumer,
            pipeline_z, epi_load_pipe_z_consumer,
            tInter2, tDelta, tD,
            typename CollectiveMainloop::TiledMmaInter2{},
            storage.tensors.epilogue, storage.tensors.mainloop
          );
        }
        
        if constexpr (CollectiveEpilogue::D_HAS_HDIM) {
          // update the barrier
          pipeline_d.consumer_release(epi_load_pipe_d_consumer);
          ++epi_load_pipe_d_consumer;
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

}  // namespace cutlass::fmha::kernel
