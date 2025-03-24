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
#include "cute/arch/cluster_sm90.hpp"
#include "cutlass/arch/reg_reconfig.h"
#include "cutlass/arch/mma_sm90.h"
#include "cutlass/epilogue/collective/detail.hpp"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/kernel/sm90_tile_scheduler.hpp"
#include "cutlass/pipeline/pipeline.hpp"
#include "cute/tensor.hpp"
///////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::kernel {

///////////////////////////////////////////////////////////////////////////////

template <
  class ProblemShape_,
  class CollectiveMainloop_,
  class CollectiveEpilogue_,
  class TileScheduler_
>
class GemmUniversal<
  ProblemShape_,
  CollectiveMainloop_,
  CollectiveEpilogue_,
  TileScheduler_,
  cute::enable_if_t<cute::is_base_of_v<KernelCooperative, typename CollectiveMainloop_::DispatchPolicy::Schedule>>>
{
public:
  //
  // Type Aliases
  //
  using ProblemShape = ProblemShape_;
  static_assert(cute::rank(ProblemShape{}) == 3 or cute::rank(ProblemShape{}) == 4,
    "ProblemShape{} should be <M,N,K> or <M,N,K,L>");
  static constexpr bool IsGdcEnabled = false;

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
  static_assert(ArchTag::kMinComputeCapability >= 90);

  // Epilogue derived types
  using CollectiveEpilogue = CollectiveEpilogue_;
  using ElementC = typename CollectiveEpilogue::ElementC;
  using StrideC  = typename CollectiveEpilogue::StrideC;
  using ElementD = typename CollectiveEpilogue::ElementD;
  using StrideD  = typename CollectiveEpilogue::StrideD;
  using EpilogueArguments = typename CollectiveEpilogue::Arguments;
  using EpilogueParams = typename CollectiveEpilogue::Params;

  static_assert(cute::is_void_v<TileScheduler_> or cute::is_same_v<TileScheduler_, PersistentScheduler>,
    "Non-persistent warp-specialized kernel does not support specializing the tile scheduler.");
  using TileSchedulerTag = TileScheduler_;
  using TileScheduler = typename detail::TileSchedulerSelector<
    TileScheduler_, ArchTag, TileShape, ClusterShape>::Scheduler;
  using TileSchedulerArguments = typename TileScheduler::Arguments;

  // Kernel level shared memory storage
  struct SharedStorage {
    union TensorStorage {
      using MainloopTensorStorage = typename CollectiveMainloop::TensorStorage;
      using EpilogueTensorStorage = typename CollectiveEpilogue::TensorStorage;

      MainloopTensorStorage mainloop;
      EpilogueTensorStorage epilogue;
    } tensors;

    struct PipelineStorage : cute::aligned_struct<16, _1> {
      using MainloopPipelineStorage = typename CollectiveMainloop::PipelineStorage;
      using EpiLoadPipelineStorage = typename CollectiveEpilogue::PipelineStorage;

      alignas(16) MainloopPipelineStorage mainloop;
      alignas(16) EpiLoadPipelineStorage epi_load;
    } pipelines;
  };

  using GmemTiledCopyA = typename CollectiveMainloop::GmemTiledCopyA;
  using GmemTiledCopyB = typename CollectiveMainloop::GmemTiledCopyB;
  static_assert(cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyA, SM90_TMA_LOAD_MULTICAST>,
      "GmemTiledCopy - invalid SM90 TMA copy atom specified.");
  static_assert(cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD> || cute::is_same_v<GmemTiledCopyB, SM90_TMA_LOAD_MULTICAST>,
      "GmemTiledCopy - invalid SM90 TMA copy atom specified.");

  static constexpr int SharedStorageSize = sizeof(SharedStorage);
  static constexpr uint32_t NumLoadWarpGroups = 1;
  static constexpr uint32_t NumMmaWarpGroups = 1;
  static constexpr uint32_t MaxThreadsPerBlock = CUTE_STATIC_V(size(TiledMma{})) + (NumLoadWarpGroups * NumThreadsPerWarpGroup);
  static constexpr uint32_t MinBlocksPerMultiprocessor = 1;

    // Device side arguments
  struct Arguments {
    GemmUniversalMode mode{};
    ProblemShape problem_shape{};
    MainloopArguments mainloop{};
    EpilogueArguments epilogue{};
    KernelHardwareInfo hw_info{};
    TileSchedulerArguments scheduler{};

    // Default constructor
    Arguments() = default;

    // Constructor with specified mode 
    // It is used for Gemm
    Arguments(
        cutlass::gemm::GemmUniversalMode mode_,
        ProblemShape problem_shape_,
        MainloopArguments mainloop_,
        EpilogueArguments epilogue_,
        KernelHardwareInfo hw_info_ = KernelHardwareInfo(),
        TileSchedulerArguments scheduler_ = TileSchedulerArguments())
    : mode(mode_)
      , problem_shape(problem_shape_)
      , mainloop(mainloop_)
      , epilogue(epilogue_)
      , hw_info(hw_info_)
      , scheduler(scheduler_) {}

    // Constructor with default value for 'mode'
    // This allows us to set GemmUniversal mode as kGemm for Conv right away
    // while keeping the testbeds unchanged
    Arguments(
        ProblemShape problem_shape_,
        MainloopArguments mainloop_,
        EpilogueArguments epilogue_,
        KernelHardwareInfo hw_info_ = KernelHardwareInfo(),
        TileSchedulerArguments scheduler_ = TileSchedulerArguments())
    : mode(cutlass::gemm::GemmUniversalMode::kGemm) // Default mode
      , problem_shape(problem_shape_)
      , mainloop(mainloop_)
      , epilogue(epilogue_)
      , hw_info(hw_info_)
      , scheduler(scheduler_) {}
  };

  // Kernel entry point API
  struct Params {
    GemmUniversalMode mode{};
    using ProblemShapeMNKL = decltype(cutlass::conv::detail::get_problem_shape_MNKL_helper<CollectiveMainloop>(ProblemShape{}, cute::false_type{}));
    ProblemShape problem_shape{};
    MainloopParams mainloop{};
    EpilogueParams epilogue{};
  };

  //
  // Methods
  //

  // Convert to underlying arguments. In this case, a simple copy for the aliased type.
  static
  Params
  to_underlying_arguments(Arguments const& args, void* workspace) {
    (void) workspace;
    auto problem_shape_mnkl = cutlass::conv::detail::get_problem_shape_MNKL_helper<CollectiveMainloop>(args.problem_shape, cute::false_type{});
    auto transformed_problem_shape = cutlass::conv::detail::get_transformed_problem_shape_MNKL(args.problem_shape);

    auto swapped_problem_shape = problem_shape_mnkl;
    if constexpr (detail::Has_SwapAB_v<CollectiveMainloop>) {
      // swap M/N
      get<0>(swapped_problem_shape) = get<1>(problem_shape_mnkl);
      get<1>(swapped_problem_shape) = get<0>(problem_shape_mnkl);
    }
    return {
      args.mode,
      swapped_problem_shape,
      CollectiveMainloop::to_underlying_arguments(args.problem_shape, args.mainloop, workspace),
      CollectiveEpilogue::to_underlying_arguments(transformed_problem_shape, args.epilogue, workspace)
    };
  }

  static bool
  can_implement(Arguments const& args) {
    bool implementable = true;
    auto transformed_problem_shape = cutlass::conv::detail::get_transformed_problem_shape_MNKL(args.problem_shape);

    if (!implementable) {
        CUTLASS_TRACE_HOST("  CAN IMPLEMENT: Arguments or Problem Shape don't meet the requirements.\n");
        return implementable;
    }

    implementable &= CollectiveMainloop::can_implement(args.problem_shape, args.mainloop);
    implementable &= CollectiveEpilogue::can_implement(transformed_problem_shape, args.epilogue);
    implementable &= TileScheduler::can_implement(args.scheduler);

    return implementable;
  }

  static
  size_t
  get_workspace_size(Arguments const& args) {
    return 0;
  }

  static
  cutlass::Status
  initialize_workspace(Arguments const& args, void* workspace = nullptr, cudaStream_t stream = nullptr,
    CudaHostAdapter* cuda_adapter = nullptr) {
    return Status::kSuccess;
  }

  // Computes the kernel launch grid shape based on runtime parameters
  static dim3
  get_grid_shape(Params const& params) {
    auto cluster_shape = ClusterShape{};
    auto tile_shape = TileShape{};
    auto problem_shape_MNKL = append<4>(params.problem_shape, Int<1>{});
    return TileScheduler::get_tiled_cta_shape_mnl(
        problem_shape_MNKL, tile_shape, cluster_shape);
  }

  static dim3
  get_block_shape() {
    return dim3(MaxThreadsPerBlock, 1, 1);
  }

  /*
  CUTLASS_DEVICE
  void
  operator()(Params const& params, char* smem_buf) {
    using namespace cute;
    using X = Underscore;

    // Kernel level shared memory storage
    SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(smem_buf);

    int thread_idx = int(threadIdx.x);
    int warp_group_thread_idx = thread_idx % NumThreadsPerWarpGroup;

    // Preconditions
    static_assert(cute::rank(StrideA{}) == 3, "StrideA must be rank-3: [M, K, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideB{}) == 3, "StrideB must be rank-3: [N, K, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideC{}) == 3, "StrideC must be rank-3: [M, N, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideD{}) == 3, "StrideD must be rank-3: [M, N, L]. If batch mode is not needed, set L stride to Int<0>.");

    // Separate out problem shape for convenience
    // Optionally append 1s until problem shape is rank-4 in case its is only rank-3 (MNK)
    auto problem_shape_MNKL = append<4>(params.problem_shape, Int<1>{});
    auto M = get<0>(problem_shape_MNKL);
    auto N = get<1>(problem_shape_MNKL);
    auto K = get<2>(problem_shape_MNKL);
    auto L = get<3>(problem_shape_MNKL);

    // Represent the full tensors
    Tensor mA_mkl = make_tensor(make_gmem_ptr(params.mainloop.ptr_A), make_shape(M,K,L), params.mainloop.dA); //(m,k,l)
    Tensor mB_nkl = make_tensor(make_gmem_ptr(params.mainloop.ptr_B), make_shape(N,K,L), params.mainloop.dB); //(n,k,l)

    // Get the appropriate blocks for this thread block -- potential for thread block locality
    auto blk_shape = TileShape{};                                                                // (BLK_M,BLK_N,BLK_K)
    TiledMma tiled_mma;

    // Make tiled views, defer the slice
    Tensor gA_mkl = local_tile(mA_mkl, blk_shape, make_coord(_,_,_), Step<_1, X,_1>{});          // (BLK_M,BLK_K,m,k,l)
    Tensor gB_nkl = local_tile(mB_nkl, blk_shape, make_coord(_,_,_), Step< X,_1,_1>{});          // (BLK_N,BLK_K,n,k,l)

    // Compute m_coord, n_coord, and l_coord with their post-tiled shapes
    auto m_coord = idx2crd(int(blockIdx.x), shape<2>(gA_mkl));
    auto n_coord = idx2crd(int(blockIdx.y), shape<2>(gB_nkl));
    auto l_coord = idx2crd(int(blockIdx.z), shape<4>(gB_nkl));
    auto blk_coord = make_coord(m_coord, n_coord, _, l_coord);

    // Slice with m_coord and n_coord
    Tensor gA = gA_mkl(_,_,m_coord,_,l_coord);                                                       // (BLK_M,BLK_K,k)
    Tensor gB = gB_nkl(_,_,n_coord,_,l_coord);                                                       // (BLK_N,BLK_K,k)

    // Get pipeline iterators and increments from tensor shapes
    auto k_tile_iter  = cute::make_coord_iterator(shape<2>(gA));
    auto k_tile_count = size<2>(gA);
    auto k_tile_total = size<2>(gA);
    auto c_tile_count = CollectiveEpilogue::get_load_pipe_increment(blk_shape);
    auto d_tile_count = CollectiveEpilogue::get_store_pipe_increment(blk_shape);

    // Wait for all threads in the thread block
    __syncthreads();

    // In a warp specialized kernel, collectives expose data movement and compute operations separately
    CollectiveMainloop collective_mainloop;
    CollectiveEpilogue collective_epilogue{params.epilogue, shared_storage.tensors.epilogue};

    Tensor accumulators = partition_fragment_C(tiled_mma, take<0,2>(blk_shape));                 // (MMA,MMA_M,MMA_N)

    {
      // Compute tile residues for predication
      auto m_max_coord = M - size<0>(gA) * get<0>(blk_coord);                             // M - BLK_M * m_coord
      auto n_max_coord = N - size<0>(gB) * get<1>(blk_coord);                             // N - BLK_N * n_coord
      auto k_residue   = K - size<1>(gA) * size<2>(gA);                                   // K - BLK_K * k_coord_max
      auto residue_mnk = make_tuple(m_max_coord, n_max_coord, k_residue);

      collective_mainloop.load(
        gA,
        gB,
        k_tile_iter, k_tile_count, k_tile_total,
        residue_mnk,
        thread_idx,
        shared_storage.tensors.mainloop
      );

      collective_mainloop.mma(
        accumulators,
        k_tile_count, k_tile_total,
        warp_group_thread_idx,
        shared_storage.tensors.mainloop,
        params.mainloop
      );

      ++k_tile_iter;
      --k_tile_count;
    }

    for ( ; k_tile_count > 0; --k_tile_count) 
    {
      // Compute tile residues for predication
      auto m_max_coord = M - size<0>(gA) * get<0>(blk_coord);                             // M - BLK_M * m_coord
      auto n_max_coord = N - size<0>(gB) * get<1>(blk_coord);                             // N - BLK_N * n_coord
      auto k_residue   = K - size<1>(gA) * size<2>(gA);                                   // K - BLK_K * k_coord_max
      auto residue_mnk = make_tuple(m_max_coord, n_max_coord, k_residue);

      collective_mainloop.load(
        gA,
        gB,
        k_tile_iter, k_tile_count, k_tile_total,
        residue_mnk,
        thread_idx,
        shared_storage.tensors.mainloop
      );      

      collective_mainloop.mma(
        accumulators,
        k_tile_count, k_tile_total,
        warp_group_thread_idx,
        shared_storage.tensors.mainloop,
        params.mainloop
      );

      ++k_tile_iter;

    }
    // // Epilogue and write to gD
    // collective_epilogue.store(
    //   epi_load_pipeline,
    //   epi_load_pipe_consumer_state,
    //   epi_store_pipeline,
    //   epi_store_pipe_producer_state,
    //   problem_shape_MNKL,
    //   blk_shape,
    //   blk_coord,
    //   accumulators,
    //   tiled_mma,
    //   warp_group_thread_idx,
    //   shared_storage.tensors.epilogue
    // );
  }
  */

  ///*
  CUTLASS_DEVICE
  void
  operator()(Params const& params, char* smem_buf) {
    using namespace cute;
    using X = Underscore;

    // Kernel level shared memory storage
    SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(smem_buf);

    int thread_idx = int(threadIdx.x);

    int warp_group_thread_idx = thread_idx % NumThreadsPerWarpGroup;
    [[maybe_unused]] int lane_idx = thread_idx % NumThreadsPerWarp;
    [[maybe_unused]] uint32_t block_rank_in_cluster = cute::block_rank_in_cluster();

    // Mainloop Load pipeline
    using MainloopPipeline = typename CollectiveMainloop::MainloopPipeline;
    typename MainloopPipeline::Params mainloop_pipeline_params;
    // mainloop_pipeline_params.is_leader = warp_group_thread_idx == 0;
    // mainloop_pipeline_params.num_consumers = NumThreadsPerWarpGroup;
    mainloop_pipeline_params.transaction_bytes = params.mainloop.tma_transaction_bytes;
    MainloopPipeline mainloop_pipeline(shared_storage.pipelines.mainloop, mainloop_pipeline_params, ClusterShape{});

    // Epilogue Load pipeline
    using EpiLoadPipeline = typename CollectiveEpilogue::LoadPipeline;
    typename EpiLoadPipeline::Params epi_load_pipeline_params;
    // if (warp_group_role == WarpGroupRole::Producer) {
      epi_load_pipeline_params.role = EpiLoadPipeline::ThreadCategory::Producer;
    // }
    // if (warp_group_role == WarpGroupRole::Consumer) {
      epi_load_pipeline_params.role = EpiLoadPipeline::ThreadCategory::Consumer;
    // }
    epi_load_pipeline_params.dst_blockid = cute::block_rank_in_cluster();
    epi_load_pipeline_params.producer_arv_count = NumThreadsPerWarp;
    epi_load_pipeline_params.consumer_arv_count = NumThreadsPerWarpGroup;
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

    // Preconditions
    static_assert(cute::rank(StrideA{}) == 3, "StrideA must be rank-3: [M, K, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideB{}) == 3, "StrideB must be rank-3: [N, K, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideC{}) == 3, "StrideC must be rank-3: [M, N, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideD{}) == 3, "StrideD must be rank-3: [M, N, L]. If batch mode is not needed, set L stride to Int<0>.");

    // Separate out problem shape for convenience
    // Optionally append 1s until problem shape is rank-4 in case its is only rank-3 (MNK)
    auto problem_shape_MNKL = append<4>(params.problem_shape, Int<1>{});
    auto M = get<0>(problem_shape_MNKL);
    auto N = get<1>(problem_shape_MNKL);
    auto K = get<2>(problem_shape_MNKL);
    auto L = get<3>(problem_shape_MNKL);

    // Represent the full tensors
    // Tensor mA_mkl = make_tensor(make_gmem_ptr(params.mainloop.ptr_A), make_shape(M,K,L), params.mainloop.dA); //(m,k,l)
    // Tensor mB_nkl = make_tensor(make_gmem_ptr(params.mainloop.ptr_B), make_shape(N,K,L), params.mainloop.dB); //(n,k,l)

    // Get the appropriate blocks for this thread block -- potential for thread block locality
    auto blk_shape = TileShape{};                                                                // (BLK_M,BLK_N,BLK_K)
    TiledMma tiled_mma;

    // In a warp specialized kernel, collectives expose data movement and compute operations separately
    CollectiveMainloop collective_mainloop;
    CollectiveEpilogue collective_epilogue{params.epilogue, shared_storage.tensors.epilogue};


    // Prepare and partition the input tensors. 
    // Expects a tuple of tensors for conv where:
    // get<0>(load_inputs) is the tma tensor A after local tiling so that it has shape (BLK_M,BLK_K,m,k)
    // get<1>(load_inputs) is the tma tensor B after local tiling so that it has shape (BLK_N,BLK_K,n,k)
    auto load_inputs = collective_mainloop.load_init(problem_shape_MNKL, params.mainloop);
    static_assert(cute::tuple_size_v<decltype(load_inputs)> >= 2, "Output of load_init must have at least two elements (A, B)");
    
    // Extract out partitioned A and B.
    Tensor gA_mkl = get<0>(load_inputs);
    Tensor gB_nkl = get<1>(load_inputs);

    // Compute m_coord, n_coord, and l_coord with their post-tiled shapes
    auto m_coord = idx2crd(int(blockIdx.x), shape<2>(gA_mkl));
    auto n_coord = idx2crd(int(blockIdx.y), shape<2>(gB_nkl));
    auto l_coord = idx2crd(int(blockIdx.z), shape<4>(gB_nkl));
    auto blk_coord = make_coord(m_coord, n_coord, _, l_coord);
    auto k_tile_iter  = cute::make_coord_iterator(shape<3>(gA_mkl));
    auto k_tile_count = size<3>(gA_mkl);

    // Slice with m_coord and n_coord
    Tensor gA = gA_mkl(_,_,m_coord,_,l_coord);                                                       // (BLK_M,BLK_K,k)
    Tensor gB = gB_nkl(_,_,n_coord,_,l_coord);                                                       // (BLK_N,BLK_K,k)

    // Get pipeline iterators and increments from tensor shapes
    // auto k_tile_iter  = cute::make_coord_iterator(shape<2>(gA));
    // auto k_tile_count = size<2>(gA);
    auto c_tile_count = CollectiveEpilogue::get_load_pipe_increment(blk_shape);
    auto d_tile_count = CollectiveEpilogue::get_store_pipe_increment(blk_shape);

    // Wait for all threads in the thread block
    __syncthreads();

    #if 0
    Tensor accumulators = partition_fragment_C(tiled_mma, take<0,2>(blk_shape));                 // (MMA,MMA_M,MMA_N)
    auto k_tile_total = size<2>(gA);

    {
      // Compute tile residues for predication
      auto m_max_coord = M - size<0>(gA) * get<0>(blk_coord);                             // M - BLK_M * m_coord
      auto n_max_coord = N - size<0>(gB) * get<1>(blk_coord);                             // N - BLK_N * n_coord
      auto k_residue   = K - size<1>(gA) * size<2>(gA);                                   // K - BLK_K * k_coord_max
      auto residue_mnk = make_tuple(m_max_coord, n_max_coord, k_residue);

      collective_mainloop.load(
        params.mainloop,
        mainloop_pipeline,
        mainloop_pipe_producer_state,
        load_inputs,
        blk_coord,
        k_tile_iter, k_tile_count,
        lane_idx,
        block_rank_in_cluster,
        shared_storage.tensors.mainloop
      );

      collective_mainloop.mma(
        mainloop_pipeline,
        mainloop_pipe_consumer_state,
        accumulators,
        k_tile_count,
        warp_group_thread_idx,
        shared_storage.tensors.mainloop,
        params.mainloop
      );

      ++k_tile_iter;
      --k_tile_count;
    }

    for ( ; k_tile_count > 0; --k_tile_count) 
    {
      // Compute tile residues for predication
      auto m_max_coord = M - size<0>(gA) * get<0>(blk_coord);                             // M - BLK_M * m_coord
      auto n_max_coord = N - size<0>(gB) * get<1>(blk_coord);                             // N - BLK_N * n_coord
      auto k_residue   = K - size<1>(gA) * size<2>(gA);                                   // K - BLK_K * k_coord_max
      auto residue_mnk = make_tuple(m_max_coord, n_max_coord, k_residue);

      collective_mainloop.load(
        params.mainloop,
        mainloop_pipeline,
        mainloop_pipe_producer_state,
        load_inputs,
        blk_coord,
        k_tile_iter, k_tile_count,
        lane_idx,
        block_rank_in_cluster,
        shared_storage.tensors.mainloop
      );      

      collective_mainloop.mma(
        mainloop_pipeline,
        mainloop_pipe_consumer_state,
        accumulators,
        k_tile_count,
        warp_group_thread_idx,
        shared_storage.tensors.mainloop,
        params.mainloop
      );

      ++k_tile_iter;

    }
    #endif

    #if 1
    {
      // Compute tile residues for predication
      auto m_max_coord = M - size<0>(gA) * get<0>(blk_coord);                             // M - BLK_M * m_coord
      auto n_max_coord = N - size<0>(gB) * get<1>(blk_coord);                             // N - BLK_N * n_coord
      auto k_residue   = K - size<1>(gA) * size<2>(gA);                                   // K - BLK_K * k_coord_max
      auto residue_mnk = make_tuple(m_max_coord, n_max_coord, k_residue);

      collective_mainloop.load(
        params.mainloop,
        mainloop_pipeline,
        mainloop_pipe_producer_state,
        load_inputs,
        blk_coord,
        k_tile_iter, k_tile_count,
        lane_idx,
        block_rank_in_cluster,
        shared_storage.tensors.mainloop
      );

      // mma consumer 
      Tensor accumulators = partition_fragment_C(tiled_mma, take<0,2>(blk_shape));                 // (MMA,MMA_M,MMA_N)

      collective_mainloop.mma(
        mainloop_pipeline,
        mainloop_pipe_consumer_state,
        accumulators,
        k_tile_count,
        warp_group_thread_idx,
        shared_storage.tensors.mainloop,
        params.mainloop
      );

      // Update starting mainloop pipeline state for the pipeline drain
      mainloop_pipe_producer_state.advance(k_tile_count);
      // Make sure mainloop consumer has been waited upon before issuing epilogue load
      collective_mainloop.load_tail(mainloop_pipeline, mainloop_pipe_producer_state);
      // Make sure the math instructions are done and free buffers before entering the epilogue
      collective_mainloop.mma_tail(
        mainloop_pipeline,
        mainloop_pipe_consumer_state,
        k_tile_count
      );

      // Epilogue and write to gD
      // collective_epilogue.store(
      //   epi_load_pipeline,
      //   epi_load_pipe_consumer_state,
      //   epi_store_pipeline,
      //   epi_store_pipe_producer_state,
      //   problem_shape_MNKL,
      //   blk_shape,
      //   blk_coord,
      //   accumulators,
      //   tiled_mma,
      //   warp_group_thread_idx,
      //   shared_storage.tensors.epilogue
      // );
    }
    #endif
  }
  //*/
};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::kernel
