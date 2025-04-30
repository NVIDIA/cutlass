/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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
  cute::enable_if_t<cute::is_base_of_v<KernelXePtrArrayCooperative, typename CollectiveMainloop_::DispatchPolicy::Schedule>>>
{
public:
  //
  // Type Aliases
  //
  using ProblemShape = ProblemShape_;
  static_assert(cute::rank(typename ProblemShape::UnderlyingProblemShape{}) == 3 or cute::rank(typename ProblemShape::UnderlyingProblemShape{}) == 4,
    "ProblemShape{} should be <M,N,K> or <M,N,K,L>");

  // Mainloop derived types
  using CollectiveMainloop = CollectiveMainloop_;
  using TileShape = typename CollectiveMainloop::WorkgroupTileShape;
  using WorkgroupTileShape = TileShape;
  using TiledMma  = typename CollectiveMainloop::TiledMma;
  using ArchTag   = typename CollectiveMainloop::ArchTag;
  using ElementA  = typename CollectiveMainloop::ElementA;
  using StrideA   = typename CollectiveMainloop::StrideA;
  using InternalStrideA   = typename CollectiveMainloop::InternalStrideA;
  using ElementB  = typename CollectiveMainloop::ElementB;
  using StrideB   = typename CollectiveMainloop::StrideB;
  using InternalStrideB   = typename CollectiveMainloop::InternalStrideB;
  using DispatchPolicy = typename CollectiveMainloop::DispatchPolicy;
  using ElementAccumulator = typename CollectiveMainloop::ElementAccumulator;
  using ClusterShape = typename DispatchPolicy::ClusterShape;
  using MainloopArguments = typename CollectiveMainloop::Arguments;
  using MainloopParams = typename CollectiveMainloop::Params;

  // Epilogue derived types
  using CollectiveEpilogue = CollectiveEpilogue_;
  using ElementC = typename CollectiveEpilogue::ElementC;
  using StrideC  = typename CollectiveEpilogue::StrideC;
  using InternalStrideC = typename CollectiveEpilogue::InternalStrideC;
  using ElementD = typename CollectiveEpilogue::ElementD;
  using StrideD  = typename CollectiveEpilogue::StrideD;
  using InternalStrideD = typename CollectiveEpilogue::InternalStrideD;
  using EpilogueArguments = typename CollectiveEpilogue::Arguments;
  using EpilogueParams = typename CollectiveEpilogue::Params;

  static_assert(cute::is_same_v<TileScheduler_, GroupScheduler>,
    "Only Group Scheduler is supported with this code.");
  using TileSchedulerTag = TileScheduler_;
  using TileScheduler = typename detail::TileSchedulerSelector<
    TileScheduler_, ArchTag, TileShape, ClusterShape, 0, ProblemShape>::Scheduler;
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

  static_assert(cute::is_same_v<ClusterShape, cute::Shape<_1, _1, _1>>);

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
      problem_shape, TileShape{}, ClusterShape{}, hw_info, args.scheduler, workspace_ptr);

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
    bool mode_implementable = args.mode == GemmUniversalMode::kGrouped
          && rank(typename ProblemShape::UnderlyingProblemShape{}) == 3;
    return mode_implementable && TileScheduler::can_implement(args.scheduler);
  }

  static size_t
  get_workspace_size(Arguments const& args) {
    size_t workspace_size = 0;
    workspace_size += TileScheduler::template get_workspace_size<typename ProblemShape::UnderlyingProblemShape, ElementAccumulator>(
      args.scheduler, typename ProblemShape::UnderlyingProblemShape{}, args.hw_info, -1);
    return workspace_size;
  }

  static cutlass::Status
  initialize_workspace(Arguments const& args, void* workspace = nullptr, cudaStream_t stream = nullptr,
    CudaHostAdapter* cuda_adapter = nullptr) {
    Status status = Status::kSuccess;
    uint8_t* workspace_ptr = reinterpret_cast<uint8_t*>(workspace);

    status = TileScheduler::template initialize_workspace<typename ProblemShape::UnderlyingProblemShape, ElementAccumulator>(
      args.scheduler, workspace_ptr, stream, typename ProblemShape::UnderlyingProblemShape{}, args.hw_info, -1);

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

    static_assert(cute::rank(InternalStrideA{}) == 3, "StrideA must be rank-3: [M, K, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(InternalStrideB{}) == 3, "StrideB must be rank-3: [N, K, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(InternalStrideC{}) == 3, "StrideC must be rank-3: [M, N, L]. If batch mode is not needed, set L stride to Int<0>.");
    static_assert(cute::rank(InternalStrideD{}) == 3, "StrideD must be rank-3: [M, N, L]. If batch mode is not needed, set L stride to Int<0>.");

    // Kernel level shared memory storage
    SharedStorage& shared_storage = *reinterpret_cast<SharedStorage*>(smem_buf);

    TileScheduler scheduler{params.scheduler};
    auto work_tile_info = scheduler.initial_work_tile_info(ClusterShape{});
    constexpr auto workgroup_shape = WorkgroupTileShape{};                                                  // (BLK_M,BLK_N,BLK_K)

    int thread_idx = int(ThreadIdxX());
    constexpr auto subgroup_shape = SubgroupTileShape{};                                                  // (SUB_M,SUB_N,SUB_K)
    bool did_group_change = true;
    int32_t curr_group = -1;
    using ProblemShapeMNKL = Shape<int, int, int, int>;
    ProblemShapeMNKL problem_shape_MNKL;
    cute::tuple<typename CollectiveMainloop::TensorMKL, typename CollectiveMainloop::TensorNKL> AB_tensors;
    cute::tuple<typename CollectiveEpilogue::TensorC, typename CollectiveEpilogue::TensorD> CD_tensors;

    if (work_tile_info.is_valid()) {
      curr_group = work_tile_info.L_idx;
      problem_shape_MNKL = append<4>(params.problem_shape.get_problem_shape(curr_group), 1);
    }

    while (work_tile_info.is_valid()) {
      auto M = get<0>(problem_shape_MNKL);
      auto N = get<1>(problem_shape_MNKL);
      auto K = get<2>(problem_shape_MNKL);
      auto L = get<3>(problem_shape_MNKL);

      Tensor mA_mkl = cute::get_xe_tensor(make_shape(M,K,L));   //(m,k,l)
      Tensor mB_nkl = cute::get_xe_tensor(make_shape(N,K,L));   //(n,k,l)

      auto m_coord = work_tile_info.M_idx;
      auto n_coord = work_tile_info.N_idx;

      auto gA_mkl = local_tile(mA_mkl, select<0,2>(workgroup_shape), make_coord(m_coord, _, 0));
      auto gB_nkl = local_tile(mB_nkl, select<1,2>(workgroup_shape), make_coord(n_coord, _, 0));

      CollectiveMainloop collective_mma;
      if(did_group_change) {
        AB_tensors = collective_mma.update_tensor_shape_stride(params.mainloop, curr_group, problem_shape_MNKL);
      }
      auto tile_coord = make_coord(m_coord, n_coord, _, 0);

      // Get the number of K tiles to compute for this work as well as the starting K tile offset of the work.
      int work_k_tile_count = TileScheduler::get_work_k_tile_count(work_tile_info, problem_shape_MNKL, workgroup_shape);
      int work_k_tile_start = TileScheduler::get_work_k_tile_start(work_tile_info);
      auto k_tile_iter = cute::make_coord_iterator(idx2crd(work_k_tile_start, make_shape(K)), make_shape(K));

      TiledMma tiled_mma;
      Tensor accumulators = partition_fragment_C(tiled_mma, take<0,2>(workgroup_shape));

      // Perform the collective scoped MMA
      collective_mma(
        accumulators,
        gA_mkl,
        gB_nkl,
        accumulators,
        k_tile_iter, work_k_tile_count,
        tile_coord,
        K,
        thread_idx,
        params.mainloop,
        AB_tensors
      );

      TileScheduler::fixup(
        params.scheduler, work_tile_info, accumulators, -1, -1);

      if (TileScheduler::compute_epilogue(work_tile_info, params.scheduler)) {
        CollectiveEpilogue epilogue{params.epilogue, shared_storage.epilogue};

        if(did_group_change) {
          CD_tensors = epilogue.update_tensor_shape_stride(curr_group, problem_shape_MNKL);
          did_group_change = false;
        }

        epilogue(
          problem_shape_MNKL,
          subgroup_shape,
          tile_coord,
          accumulators,
          tiled_mma,
          thread_idx,
          CD_tensors
        );
      }

      // Get next work tile
      auto [next_work_tile_info, temp] = scheduler.fetch_next_work(work_tile_info);
      work_tile_info = next_work_tile_info;

      did_group_change = curr_group != work_tile_info.L_idx;

      if(did_group_change && work_tile_info.is_valid()) {
        curr_group = work_tile_info.L_idx;
        problem_shape_MNKL = append<4>(params.problem_shape.get_problem_shape(curr_group), 1);
      }
    }
  }

};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::kernel
