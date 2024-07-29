/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "cutlass/fast_math.h"
#include "cutlass/kernel_hardware_info.hpp"

#include "cute/tensor.hpp"
#include "cute/arch/cluster_sm90.hpp"

#include "cutlass/conv/convolution.h"
#include "cutlass/conv/dispatch_policy.hpp"
#include "cutlass/pipeline/sm90_pipeline.hpp"
#include "cutlass/gemm/kernel/tile_scheduler.hpp"

///////////////////////////////////////////////////////////////////////////////

namespace cutlass::conv::kernel {

///////////////////////////////////////////////////////////////////////////////

template <
  class CollectiveMainloop_,
  class CollectiveEpilogue_,
  class TileSchedulerTag_
>
class ConvUniversal<
  CollectiveMainloop_,
  CollectiveEpilogue_,
  TileSchedulerTag_,
  cute::enable_if_t<cute::is_base_of_v<cutlass::conv::KernelImplicitTmaWarpSpecializedSm90,
                                       typename CollectiveMainloop_::DispatchPolicy::Schedule>>>
{
public:
  //
  // Type Aliases
  //

  // Mainloop derived types
  using CollectiveMainloop = CollectiveMainloop_;
  using TileShape = typename CollectiveMainloop::TileShape;
  using TiledMma  = typename CollectiveMainloop::TiledMma;
  using ArchTag   = typename CollectiveMainloop::ArchTag;
  using ElementA  = typename CollectiveMainloop::ElementA;
  using StrideA   = typename CollectiveMainloop::StrideA;
  using ElementB  = typename CollectiveMainloop::ElementB;
  using StrideB   = typename CollectiveMainloop::StrideB;
  using DispatchPolicy = typename CollectiveMainloop::DispatchPolicy;
  using ElementAccumulator = typename CollectiveMainloop::ElementAccumulator;
  using ClusterShape = typename DispatchPolicy::ClusterShape;
  using MainloopArguments = typename CollectiveMainloop::Arguments;
  using MainloopParams = typename CollectiveMainloop::Params;
  static constexpr int NumSpatialDimensions = CollectiveMainloop::NumSpatialDimensions;
  static_assert(ArchTag::kMinComputeCapability >= 90);
  // Epilogue derived types
  using CollectiveEpilogue = CollectiveEpilogue_;
  using ElementC = typename CollectiveEpilogue::ElementC;
  using StrideC  = typename CollectiveEpilogue::StrideC;
  using ElementD = typename CollectiveEpilogue::ElementD;
  using StrideD  = typename CollectiveEpilogue::StrideD;
  using EpilogueArguments = typename CollectiveEpilogue::Arguments;
  using EpilogueParams = typename CollectiveEpilogue::Params;

  using TileSchedulerTag = TileSchedulerTag_;
  static_assert(cute::is_void_v<TileSchedulerTag>,
    "TMA warp-specialized kernel does not support specializing the tile scheduler.");
  using TileScheduler = typename cutlass::gemm::kernel::detail::TileSchedulerSelector<
      TileSchedulerTag, ArchTag, TileShape, ClusterShape>::Scheduler;
  using TileSchedulerArguments = typename TileScheduler::Arguments;

  // Kernel level shared memory storage
  struct SharedStorage {
    union TensorStorage {
      using MainloopTensorStorage = typename CollectiveMainloop::TensorStorage;
      using EpilogueTensorStorage = typename CollectiveEpilogue::TensorStorage;

      MainloopTensorStorage mainloop;
      EpilogueTensorStorage epilogue;
    } tensors;

    struct PipelineStorage : cute::aligned_struct<16> {
      using MainloopPipelineStorage = typename CollectiveMainloop::PipelineStorage;
      using EpiLoadPipelineStorage = typename CollectiveEpilogue::PipelineStorage;

      alignas(16) MainloopPipelineStorage mainloop;
      alignas(16) EpiLoadPipelineStorage epi_load;
    } pipelines;
  };

  static constexpr int SharedStorageSize = sizeof(SharedStorage);
  static constexpr uint32_t NumLoadWarpGroups = 1;
  static constexpr uint32_t NumMmaWarpGroups = 1;
  static constexpr uint32_t MaxThreadsPerBlock = CUTE_STATIC_V(size(TiledMma{})) + (NumLoadWarpGroups * NumThreadsPerWarpGroup);
  static constexpr uint32_t MinBlocksPerMultiprocessor = 1;

  // Host facing host arguments
  struct Arguments {
    MainloopArguments mainloop{};
    EpilogueArguments epilogue{};
    KernelHardwareInfo hw_info{};
    TileSchedulerArguments scheduler{};
  };

  // Kernel device entry point API
  struct Params {
    MainloopParams mainloop;
    EpilogueParams epilogue;
  };

  //
  // Methods
  //

  // Map user facing arguments to device facing params
  static Params
  to_underlying_arguments(Arguments const& args, void* workspace) {
    (void) workspace;
    auto mainloop_params = CollectiveMainloop::to_underlying_arguments(args.mainloop, workspace);
    auto problem_shape_MNKL = args.mainloop.problem_shape.get_transformed_problem_shape_MNKL();

    return {
      mainloop_params,
      CollectiveEpilogue::to_underlying_arguments(problem_shape_MNKL, args.epilogue, workspace)
    };
  }

  // Given arguemnts, returns true if the kernel can successfully compute upon them. False otherwise.
  static bool
  can_implement(Arguments const& args) {
    bool implementable = true;
    implementable &= CollectiveMainloop::can_implement(args.mainloop.problem_shape, args.mainloop);
    implementable &= CollectiveEpilogue::can_implement(args.mainloop.problem_shape.get_transformed_problem_shape_MNKL(), args.epilogue);
    return implementable;
  }

  static size_t
  get_workspace_size(Arguments const& args) {
    return 0;
  }

  static cutlass::Status
  initialize_workspace(Arguments const& args, void* workspace = nullptr, cudaStream_t stream = nullptr,
    CudaHostAdapter* cuda_adapter = nullptr) {
    return Status::kSuccess;
  }

  // Computes the kernel launch grid shape based on runtime parameters
  static dim3
  get_grid_shape(Params const& params) {
    return cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90::get_tiled_cta_shape_mnl(
        params.mainloop.problem_shape, TileShape{}, ClusterShape{});
  }

  static dim3
  get_block_shape() {
    return dim3(MaxThreadsPerBlock, 1, 1);
  }

  CUTLASS_DEVICE
  void
  operator()(Params const& params, char* smem_buf) {
    using namespace cute;
    using X = Underscore;

    // Any Tensor Op MMA Atom in the WGMMA ISA is arch conditional to sm90a.
    #if ! defined(__CUDA_ARCH_FEAT_SM90_ALL)
      if constexpr(size<0>(typename TiledMma::AtomShape_MNK{}) == 64) {
        printf("ERROR : Arch conditional MMA instruction used without targeting sm90a compute capability. Aborting.\n");
        return;
      }
    #endif

    enum class WarpGroupRole {
      Producer = 0,
      Consumer = 1,
    };

    enum class ProducerWarpRole {
      MainloopEpilogue = 0,
      Warp1 = 1,
      Warp2 = 2,
      Warp3 = 3
    };
    
    // Kernel level shared memory storage
    SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(smem_buf);

    int thread_idx = int(threadIdx.x);
    int lane_idx = canonical_lane_idx();
    int warp_idx   = canonical_warp_idx_sync();
    int warp_idx_in_warp_group = warp_idx % NumWarpsPerWarpGroup;
    int warp_group_thread_idx = thread_idx % NumThreadsPerWarpGroup;
    auto warp_group_role = WarpGroupRole(canonical_warp_group_idx());
    auto producer_warp_role = ProducerWarpRole(warp_idx_in_warp_group);
    int lane_predicate = cute::elect_one_sync();
    uint32_t block_rank_in_cluster = cute::block_rank_in_cluster();

    // Issue Tma Descriptor Prefetch from a single thread
    if ((warp_idx == 0) && lane_predicate) {
      CollectiveMainloop::prefetch_tma_descriptors(params.mainloop);
      CollectiveEpilogue::prefetch_tma_descriptors(params.epilogue);
    }

    // Mainloop Load pipeline
    using MainloopPipeline = typename CollectiveMainloop::MainloopPipeline;
    typename MainloopPipeline::Params mainloop_pipeline_params;
    if (warp_group_role == WarpGroupRole::Producer && producer_warp_role == ProducerWarpRole::MainloopEpilogue) {
      mainloop_pipeline_params.role = MainloopPipeline::ThreadCategory::Producer;
    }
    if (warp_group_role == WarpGroupRole::Consumer) {
      mainloop_pipeline_params.role = MainloopPipeline::ThreadCategory::Consumer;
    }
    mainloop_pipeline_params.is_leader = warp_group_thread_idx == 0;
    mainloop_pipeline_params.num_consumers = NumThreadsPerWarpGroup;
    mainloop_pipeline_params.transaction_bytes = params.mainloop.tma_transaction_bytes;
    MainloopPipeline mainloop_pipeline(shared_storage.pipelines.mainloop, mainloop_pipeline_params, ClusterShape{});

    // Epilogue Load pipeline
    using EpiLoadPipeline = typename CollectiveEpilogue::LoadPipeline;
    typename EpiLoadPipeline::Params epi_load_pipeline_params;
    if (warp_group_role == WarpGroupRole::Producer && producer_warp_role == ProducerWarpRole::MainloopEpilogue) {
      epi_load_pipeline_params.role = EpiLoadPipeline::ThreadCategory::Producer;
    }
    if (warp_group_role == WarpGroupRole::Consumer) {
      epi_load_pipeline_params.role = EpiLoadPipeline::ThreadCategory::Consumer;
    }
    epi_load_pipeline_params.dst_blockid = cute::block_rank_in_cluster();
    epi_load_pipeline_params.producer_arv_count = NumThreadsPerWarp;
    epi_load_pipeline_params.consumer_arv_count = NumThreadsPerWarpGroup;
    if constexpr (CollectiveEpilogue::RequiresTransactionBytes) {
      epi_load_pipeline_params.transaction_bytes = params.epilogue.tma_transaction_bytes;
    }
    EpiLoadPipeline epi_load_pipeline(shared_storage.pipelines.epi_load, epi_load_pipeline_params);

    // Epilogue Store pipeline
    using EpiStorePipeline = typename CollectiveEpilogue::StorePipeline;
    typename EpiStorePipeline::Params epi_store_pipeline_params;
    epi_store_pipeline_params.always_wait = true;
    EpiStorePipeline epi_store_pipeline(epi_store_pipeline_params);

    // Initialize starting pipeline states for the collectives
    // Epilogue store pipe is producer-only (consumer is TMA unit, waits via scoreboarding)
    typename CollectiveMainloop::PipelineState mainloop_pipe_consumer_state;
    typename CollectiveEpilogue::LoadPipelineState epi_load_pipe_consumer_state;

    // For the DMA Load (producer) we start with an opposite phase
    // i.e., we skip all waits since we know that the buffer is indeed empty
    PipelineState mainloop_pipe_producer_state = cutlass::make_producer_start_state<MainloopPipeline>();
    PipelineState epi_load_pipe_producer_state = cutlass::make_producer_start_state<EpiLoadPipeline>();
    PipelineState epi_store_pipe_producer_state = cutlass::make_producer_start_state<EpiStorePipeline>();

    auto cluster_wait_fn = [&] () {
      // We need this to guarantee that the Pipeline init is visible
      // To all producers and consumer thread blocks in the Cluster
      if constexpr (size(ClusterShape{}) > 1) {
        cute::cluster_arrive_relaxed();
        return [] () { cute::cluster_wait(); };
      }
      else {
        __syncthreads();
        return [] () {}; // do nothing
      }
    } ();

    // Separate out problem shape for convenience
    auto problem_shape_MNKL = append<4>(params.mainloop.problem_shape, _1{});
    auto [M, N, K, L] = problem_shape_MNKL;

    // TMA requires special handling of strides to deal with coord codomain mapping
    // Represent the full tensors -- get these from TMA
    Tensor mA_mk = params.mainloop.tma_load_a.get_tma_tensor(make_shape(M, K));
    Tensor mB_nk = params.mainloop.tma_load_b.get_tma_tensor(make_shape(N, K));

    // Get the appropriate blocks for this thread block -- potential for thread block locality
    auto cta_tile_shape = TileShape{};                                                           // (BLK_M,BLK_N,BLK_K)
    TiledMma tiled_mma;

    // Make tiled views, defer the slice
    Tensor gA_mk = local_tile(mA_mk, cta_tile_shape, make_coord(_,_,_), Step<_1, X,_1>{});         // (BLK_M,BLK_K,m,k)
    Tensor gB_nk = local_tile(mB_nk, cta_tile_shape, make_coord(_,_,_), Step< X,_1,_1>{});         // (BLK_N,BLK_K,n,k)

    // Compute m_coord, n_coord, and l_coord with their post-tiled shapes
    auto m_coord = idx2crd(int(blockIdx.x), shape<2>(gA_mk));
    auto n_coord = idx2crd(int(blockIdx.y), shape<2>(gB_nk), compact_col_major(shape<2>(gB_nk)));

    // The output shape M is linearized so the output coord M here should also be linearized.
    auto output_tile_coord = make_coord(int(blockIdx.x), n_coord, _, Int<0>{});

    // Slice with m_coord and n_coord
    Tensor gA = gA_mk(_,_,m_coord,_);                                                                // (BLK_M,BLK_K,k)
    Tensor gB = gB_nk(_,_,n_coord,_);                                                                // (BLK_N,BLK_K,k)

    // Get pipeline iterators and increments from tensor shapes
    auto k_tile_iter  = cute::make_coord_iterator(shape<2>(gA));
    auto k_tile_count = size<2>(gA);

    // In a warp specialized kernel, collectives expose data movement and compute operations separately
    CollectiveMainloop collective_mainloop;
    CollectiveEpilogue collective_epilogue{params.epilogue, shared_storage.tensors.epilogue};

    // Wait for all thread blocks in Cluster
    cluster_wait_fn();

    if (warp_group_role == WarpGroupRole::Producer) {
      if (producer_warp_role == ProducerWarpRole::MainloopEpilogue) {
        collective_mainloop.load(
          mainloop_pipeline,
          mainloop_pipe_producer_state,
          gA, params.mainloop.tma_load_a,
          gB, params.mainloop.tma_load_b,
          k_tile_iter, k_tile_count,
          lane_idx,
          block_rank_in_cluster,
          shared_storage.tensors.mainloop
        );
        // Update starting mainloop pipeline state for the pipeline drain
        mainloop_pipe_producer_state.advance(k_tile_count);
        // Make sure mainloop consumer has been waited upon before issuing epilogue load
        collective_mainloop.load_tail(mainloop_pipeline, mainloop_pipe_producer_state);
      
        if (collective_epilogue.is_producer_load_needed()) {
          epi_load_pipe_producer_state = collective_epilogue.load(
            epi_load_pipeline,
            epi_load_pipe_producer_state,
            problem_shape_MNKL,
            cta_tile_shape,
            output_tile_coord,
            tiled_mma,
            lane_idx,
            shared_storage.tensors.epilogue
          );
          collective_epilogue.load_tail(epi_load_pipeline, epi_load_pipe_producer_state);
        }
      }
    }
    else if (warp_group_role == WarpGroupRole::Consumer) {
      Tensor accumulators = partition_fragment_C(tiled_mma, take<0,2>(cta_tile_shape));            // (MMA,MMA_M,MMA_N)

      collective_mainloop.mma(
        mainloop_pipeline,
        mainloop_pipe_consumer_state,
        accumulators,
        k_tile_count,
        thread_idx,
        shared_storage.tensors.mainloop,
        params.mainloop
      );

      // Make sure the math instructions are done and free buffers before entering the epilogue
      collective_mainloop.mma_tail(
        mainloop_pipeline,
        mainloop_pipe_consumer_state,
        k_tile_count
      );

      // Epilogue and write to gD
      auto [epi_load_pipe_consumer_state_next, epi_store_pipe_producer_state_next] =
      collective_epilogue.store(
        epi_load_pipeline,
        epi_load_pipe_consumer_state,
        epi_store_pipeline,
        epi_store_pipe_producer_state,
        problem_shape_MNKL,
        cta_tile_shape,
        output_tile_coord,
        accumulators,
        tiled_mma,
        warp_group_thread_idx,
        shared_storage.tensors.epilogue
      );

      collective_epilogue.store_tail(
        epi_load_pipeline,
        epi_load_pipe_consumer_state_next,
        epi_store_pipeline,
        epi_store_pipe_producer_state_next
      );
    }
  }
};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::conv::kernel
