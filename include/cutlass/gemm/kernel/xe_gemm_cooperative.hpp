/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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
#include "cutlass/workspace.h"
#include "cutlass/kernel_hardware_info.hpp"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/kernel/tile_scheduler.hpp"
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
  cute::enable_if_t<cute::is_base_of_v<KernelPVCCooperative, typename CollectiveMainloop_::DispatchPolicy::Schedule>>>
{
public:
  //
  // Type Aliases
  //
  using ProblemShape = ProblemShape_;
  static_assert(cute::rank(ProblemShape{}) == 3 or cute::rank(ProblemShape{}) == 4,
    "ProblemShape{} should be <M,N,K> or <M,N,K,L>");
  static_assert(cute::is_same_v<TileScheduler_, StreamKScheduler> or cute::is_same_v<TileScheduler_, PersistentScheduler>,
    "Xe cooperative pipeline does not support GroupScheduler.");

  // Mainloop derived types
  using CollectiveMainloop = CollectiveMainloop_;
  using TileShape = typename CollectiveMainloop::WorkgroupTileShape;
  using WorkgroupTileShape = TileShape;
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

  // Epilogue derived types
  using CollectiveEpilogue = CollectiveEpilogue_;
  using ElementC = typename CollectiveEpilogue::ElementC;
  using StrideC  = typename CollectiveEpilogue::StrideC;
  using ElementD = typename CollectiveEpilogue::ElementD;
  using StrideD  = typename CollectiveEpilogue::StrideD;
  using EpilogueArguments = typename CollectiveEpilogue::Arguments;
  using EpilogueParams = typename CollectiveEpilogue::Params;

  using TileSchedulerTag = TileScheduler_;
  using TileScheduler = typename detail::TileSchedulerSelector<
    TileScheduler_, ArchTag, TileShape, ClusterShape>::Scheduler;
  using TileSchedulerArguments = typename TileScheduler::Arguments;
  using TileSchedulerParams = typename TileScheduler::Params;

  static constexpr int SubgroupSize = CollectiveMainloop::SubgroupSize; // sub_group size
  static constexpr uint32_t MaxThreadsPerBlock = CollectiveMainloop::MaxThreadsPerBlock;
  using MmaAtomShape = typename CollectiveMainloop::MmaAtomShape;
  using SubgroupTileShape = typename CollectiveMainloop::SubgroupTileShape;

  // Kernel level shared memory storage
  struct SharedStorage {
    using EpilogueTensorStorage = typename CollectiveEpilogue::TensorStorage;
    EpilogueTensorStorage epilogue;
  };

  static constexpr int SharedStorageSize = sizeof(SharedStorage);

  // Device side arguments
  struct Arguments {
    GemmUniversalMode mode{};
    ProblemShape problem_shape{};
    MainloopArguments mainloop{};
    EpilogueArguments epilogue{};
    KernelHardwareInfo hw_info{};
    TileSchedulerArguments scheduler{};
  };

  // Kernel entry point API
  struct Params {
    GemmUniversalMode mode{};
    ProblemShape problem_shape{};
    MainloopParams mainloop{};
    EpilogueParams epilogue{};
    KernelHardwareInfo hw_info{};
    TileSchedulerParams scheduler{};
    void* workspace{nullptr};
  };

  //
  // Methods
  //

  // Convert to underlying arguments. In this case, a simple copy for the aliased type.
  static
  Params
  to_underlying_arguments(Arguments const& args, void* workspace) {
    CUTLASS_TRACE_HOST("to_underlying_arguments():");

    auto problem_shape = args.problem_shape;

    auto problem_shape_MNKL = append<4>(problem_shape, 1);

    // Get SM count if needed, otherwise use user supplied SM count
    int sm_count = args.hw_info.sm_count;
    if (sm_count <= 0) {
      CUTLASS_TRACE_HOST("  WARNING: Arguments do not include a valid SM count.\n"
          "  For optimal performance, populate the arguments KernelHardwareInfo struct with the SM count.");
      sm_count = KernelHardwareInfo::query_device_multiprocessor_count(args.hw_info.device_id);
    }

    CUTLASS_TRACE_HOST("to_underlying_arguments(): Setting persistent grid SM count to " << sm_count);

    KernelHardwareInfo hw_info{args.hw_info.device_id, sm_count};

    // Calculate workspace pointers
    uint8_t* workspace_ptr = reinterpret_cast<uint8_t*>(workspace);

    TileSchedulerParams scheduler = TileScheduler::to_underlying_arguments(
      problem_shape_MNKL, TileShape{}, ClusterShape{}, hw_info, args.scheduler, workspace_ptr);

    return {
      args.mode,
      problem_shape,
      CollectiveMainloop::to_underlying_arguments(args.problem_shape, args.mainloop, workspace_ptr),
      CollectiveEpilogue::to_underlying_arguments(args.problem_shape, args.epilogue, workspace_ptr),
      hw_info,
      scheduler,
      workspace
    };
  }

  static bool
  can_implement(Arguments const& args) {
    bool mode_implementable = args.mode == GemmUniversalMode::kGemm or
          (args.mode == GemmUniversalMode::kBatched && rank(ProblemShape{}) == 4);
    return mode_implementable && TileScheduler::can_implement(args.scheduler);
  }

  static size_t
  get_workspace_size(Arguments const& args) {
    size_t workspace_size = 0;
    workspace_size += TileScheduler::template get_workspace_size<ProblemShape, ElementAccumulator>(
      args.scheduler, args.problem_shape, args.hw_info, 1);
    return workspace_size;
  }

  static cutlass::Status
  initialize_workspace(Arguments const& args, void* workspace = nullptr, cudaStream_t stream = nullptr,
    CudaHostAdapter* cuda_adapter = nullptr) {
    Status status = Status::kSuccess;
    uint8_t* workspace_ptr = reinterpret_cast<uint8_t*>(workspace);

    status = TileScheduler::template initialize_workspace<ProblemShape, ElementAccumulator>(
      args.scheduler, workspace_ptr, stream, args.problem_shape, args.hw_info, 1);

    return status;
  }

  // Computes the kernel launch grid shape based on runtime parameters
  static dim3
  get_grid_shape(Params const& params) {
    // Given device SM count, set grid size s.t. we do not launch more thread blocks than we can run concurrently
    TileSchedulerArguments args{};
    args.raster_order = params.scheduler.raster_order_ == TileScheduler::RasterOrder::AlongN ? TileScheduler::RasterOrderOptions::AlongN : TileScheduler::RasterOrderOptions::AlongM;
    return TileScheduler::get_grid_shape(params.scheduler, params.problem_shape, TileShape{}, ClusterShape{}, params.hw_info, args);
  }

  static dim3
  get_block_shape() {
    return dim3(MaxThreadsPerBlock, 1, 1);
  }

  CUTLASS_DEVICE
  void
  operator()(Params const& params, char* smem_buf) {
    // Preconditions
    CUTE_STATIC_ASSERT(is_static<WorkgroupTileShape>::value);

    static_assert(cute::rank(StrideA{}) == 3, "StrideA must be rank-3: [M, K, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideB{}) == 3, "StrideB must be rank-3: [N, K, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideC{}) == 3, "StrideC must be rank-3: [M, N, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(StrideD{}) == 3, "StrideD must be rank-3: [M, N, L]. If batch mode is not needed, set L stride to Int<0>.");

    // Kernel level shared memory storage
    SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(smem_buf);

    // Optionally append 1s until problem shape is rank-4 in case it is only rank-3 (MNK)
    auto problem_shape_MNKL = append<4>(params.problem_shape, Int<1>{});
    auto M = get<0>(problem_shape_MNKL);
    auto N = get<1>(problem_shape_MNKL);
    auto K = get<2>(problem_shape_MNKL);
    auto L = get<3>(problem_shape_MNKL);

    TileScheduler scheduler{params.scheduler};
    auto work_tile_info = scheduler.initial_work_tile_info(ClusterShape{});

    int thread_idx = int(ThreadIdxX());
    constexpr auto workgroup_shape = WorkgroupTileShape{};                                                  // (BLK_M,BLK_N,BLK_K)
    constexpr auto subgroup_shape = SubgroupTileShape{};                                                  // (SUB_M,SUB_N,SUB_K)

    while (work_tile_info.is_valid()) {
      const int m_coord = work_tile_info.M_idx;
      const int n_coord = work_tile_info.N_idx;
      const int l_coord = work_tile_info.L_idx;
      const auto tile_coord = make_coord(m_coord, n_coord, _, l_coord);
      
      Tensor mA_mkl = params.mainloop.copy_A.get_pvc_tensor(make_shape(M,K,L));   //(m,k,l)
      Tensor mB_nkl = params.mainloop.copy_B.get_pvc_tensor(make_shape(N,K,L));   //(n,k,l)

      Tensor mA_mk = mA_mkl(_,_,l_coord);                                                                        // (m,k)
      Tensor mB_nk = mB_nkl(_,_,l_coord);                                                                        // (n,k)

      auto gA = local_tile(mA_mk, workgroup_shape, take<0, 3>(tile_coord), Step<_1,  X, _1>{});
      auto gB = local_tile(mB_nk, workgroup_shape, take<0, 3>(tile_coord), Step< X, _1, _1>{});

      // Get the number of K tiles to compute for this work as well as the starting K tile offset of the work.
      const int work_k_tile_count = TileScheduler::get_work_k_tile_count(work_tile_info, problem_shape_MNKL, workgroup_shape);
      const int work_k_tile_start = TileScheduler::get_work_k_tile_start(work_tile_info);
      auto k_tile_iter = cute::make_coord_iterator(idx2crd(work_k_tile_start, make_shape(K)), make_shape(K));

      auto k_residue = K - get<2>(subgroup_shape) * (K / get<2>(subgroup_shape));        // K - SUB_K * k_coord_max

      // Compute tile residues for predication
      auto m_max_coord = M - get<0>(subgroup_shape) * m_coord;                             // M - SUB_M * m_coord
      auto n_max_coord = N - get<1>(subgroup_shape) * n_coord;                             // N - SUB_N * n_coord
      auto residue_mnk = make_tuple(m_max_coord, n_max_coord, k_residue);

      TiledMma tiled_mma;
      Tensor accumulators = partition_fragment_C(tiled_mma, take<0,2>(workgroup_shape)); 

      CollectiveMainloop collective_mma;

      // Perform the collective scoped MMA
      collective_mma(
        accumulators,
        gA,
        gB,
        accumulators,
        k_tile_iter, work_k_tile_count,
        residue_mnk,
        tile_coord,
        K,
        thread_idx,
        smem_buf,
        params.mainloop
      );

      // Perform reduction across splits, if needed
      if constexpr (cute::is_same_v<TileScheduler, detail::PersistentTileSchedulerXeStreamK<TileShape>>)
      {
        TileScheduler::template fixup<MaxThreadsPerBlock>(
          params.scheduler, work_tile_info, accumulators);  
      }

      if (TileScheduler::compute_epilogue(work_tile_info, params.scheduler)) {
        CollectiveEpilogue epilogue{params.epilogue, shared_storage.epilogue};

        epilogue(
          problem_shape_MNKL,
          subgroup_shape,
          tile_coord,
          accumulators,
          tiled_mma,
          residue_mnk,
          thread_idx,
          smem_buf
        );
      }

      // Get next work tile
      auto [next_work_tile_info, increment_pipe] = scheduler.fetch_next_work(work_tile_info);
      work_tile_info = next_work_tile_info;
    }
  }

};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::kernel
