/***************************************************************************************************
 * Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cute/int_tuple.hpp"

#include "cutlass/arch/config.h"
#include "cutlass/arch/barrier.h"
#include "cutlass/detail/cluster.hpp" 
#include "cutlass/pipeline/pipeline.hpp"
#include "cutlass/gemm_coord.hpp"
#include "cutlass/gemm/kernel/sm90_tile_scheduler.hpp"
#include "cutlass/gemm/kernel/tile_scheduler_params.h"
#include "cutlass/conv/convnd_problem_shape.hpp"
#include "cutlass/conv/detail.hpp"

////////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::kernel::detail {

//////////////////// Blackwell Scheduler /////////////////////////

template<
  class ClusterShape_,
  uint32_t Stages_
>
class PersistentTileSchedulerSm100 {

private:

  using UnderlyingTileScheduler = PersistentTileSchedulerSm90;

public:

  using ClusterShape = ClusterShape_;
  using RasterOrder = UnderlyingTileScheduler::RasterOrder;
  using RasterOrderOptions = UnderlyingTileScheduler::RasterOrderOptions;
  static constexpr bool IsDynamicPersistent = true;

  static constexpr uint32_t Stages = Stages_;

  // CLC response is an opaque 16B value
  struct CLCResponse { uint32_t data[4]; };

  using WorkTileInfo = typename PersistentTileSchedulerSm90::WorkTileInfo;

  using Params = PersistentTileSchedulerSm100Params;

  using Pipeline = PipelineCLCFetchAsync<Stages, ClusterShape>;
  using PipelineStorage = typename Pipeline::SharedStorage;

  using ThrottlePipeline = PipelineAsync<Stages>;
  using ThrottlePipelineStorage = typename ThrottlePipeline::SharedStorage;

  class SharedStorage {
  public:

    CUTLASS_DEVICE PipelineStorage& pipeline() { return pipeline_; }
    CUTLASS_DEVICE ThrottlePipelineStorage& throttle_pipeline() { return throttle_pipeline_; }
    CUTLASS_DEVICE CLCResponse* data() { return data_; }

  private: 
    alignas(16) PipelineStorage pipeline_;
    alignas(16) ThrottlePipelineStorage throttle_pipeline_;
    alignas(16) CLCResponse data_[Stages];
  };

  struct Arguments {

    Arguments() = default;
    Arguments(Arguments const&) = default;
    Arguments(Arguments&&) = default;

    CUTLASS_HOST_DEVICE
    Arguments&
    operator=(Arguments const&) {
      return *this;
    }

    CUTLASS_HOST_DEVICE
    Arguments&
    operator=(Arguments &&) {
      return *this;
    }

    int max_swizzle_size = 1;
    RasterOrderOptions raster_order = RasterOrderOptions::Heuristic;
  };

  //
  // Static Host Methods
  //

  template <class ProblemShapeMNKL, class TileShape, class ClusterShape>
  static Params
  to_underlying_arguments(
    ProblemShapeMNKL problem_shape_mnkl,
    TileShape tile_shape,
    [[maybe_unused]] ClusterShape cluster_shape,
    [[maybe_unused]] KernelHardwareInfo const& hw_info,
    [[maybe_unused]] Arguments const& args,
    [[maybe_unused]] void* workspace = nullptr,
    [[maybe_unused]] uint32_t NumEpilogueSubTiles = 1,
    [[maybe_unused]] uint32_t ktile_start_alignment_count = 1u
    ) {

    auto cs = cutlass::detail::select_cluster_shape(ClusterShape_{}, hw_info.cluster_shape);

    dim3 problem_blocks = get_tiled_cta_shape_mnl(problem_shape_mnkl, tile_shape, cs);

    Params params;
    params.initialize(
      problem_blocks,
      to_gemm_coord(cs),
      hw_info,
      args.max_swizzle_size, 
      args.raster_order
    );
    return params;
  }

  template <class ProblemShapeMNKL, class TileShape, class AtomThrShape, class ClusterShape>
  static Params
  to_underlying_arguments(
      ProblemShapeMNKL problem_shape_mnkl,
      TileShape tile_shape_mnk,
      AtomThrShape atom_thr_shape_mnk,
      ClusterShape cluster_shape_mnk,
      KernelHardwareInfo const& hw_info,
      Arguments const& args,
      void* workspace = nullptr
    ) { 

    auto selected_cluster_shape = cutlass::detail::select_cluster_shape(cluster_shape_mnk, hw_info.cluster_shape);

    dim3 problem_blocks = get_tiled_cta_shape_mnl(problem_shape_mnkl, tile_shape_mnk,
                                                  atom_thr_shape_mnk, selected_cluster_shape);

    Params params;
    params.initialize(
      problem_blocks,
      to_gemm_coord(selected_cluster_shape),
      hw_info,
      args.max_swizzle_size, 
      args.raster_order
    );
    return params;
  }

  // Conv Specialization
  template <conv::Operator ConvOp, int NumSpatialDims, class TileShape, class AtomThrShape, class ClusterShape>
  static Params
  to_underlying_arguments(
      cutlass::conv::ConvProblemShape<ConvOp, NumSpatialDims> problem_shape,
      TileShape tile_shape_mnk,
      AtomThrShape atom_thr_shape_mnk,
      ClusterShape cluster_shape_mnk,
      KernelHardwareInfo const& hw_info,
      Arguments const& args,
      void* workspace = nullptr
    ) { 
    
    auto problem_shape_mnkl = [&] () {
      // Infer im2col linearization from ConvOp and TileShape
      constexpr bool is_linearized_M = (ConvOp == conv::Operator::kFprop || ConvOp == conv::Operator::kDgrad)
                                        && depth<0>(TileShape{}) == _0{};
      constexpr bool is_linearized_K = ConvOp == conv::Operator::kWgrad && depth<2>(TileShape{}) == _0{};

      if constexpr (is_linearized_M || is_linearized_K) {
        // transformation + im2col linearization
        return cutlass::conv::detail::get_linearized_problem_shape_MNKL(problem_shape);
      }
      else {
        // transformation
        return cutlass::conv::detail::get_transformed_problem_shape_MNKL(problem_shape);
      }
    }();

    return to_underlying_arguments(
      problem_shape_mnkl,
      tile_shape_mnk,
      atom_thr_shape_mnk,
      cluster_shape_mnk,
      hw_info,
      args,
      workspace
    );
  }

  // Given the inputs, computes the physical grid we should launch.
  template<class ProblemShapeMNKL, class BlockShape, class ClusterShape>
  CUTLASS_HOST_DEVICE
  static dim3
  get_grid_shape(
      Params const& params,
      ProblemShapeMNKL problem_shape_mnk,
      BlockShape cta_shape,
      ClusterShape cluster_shape,
      KernelHardwareInfo hw_info,
      [[maybe_unused]] Arguments arguments) {
    auto problem_shape_MNKL = append<4>(problem_shape_mnk, Int<1>{});
    auto grid = get_tiled_cta_shape_mnl(problem_shape_MNKL, cta_shape, cluster_shape);
    return possibly_transpose_grid(params.raster_order_, params.divmod_cluster_shape_m_, params.divmod_cluster_shape_n_, grid);
  }

  // Given the inputs, computes the physical grid we should launch.
  template<class ProblemShapeMNKL, class TileShape, class AtomThrShape, class ClusterShape>
  CUTLASS_HOST_DEVICE
  static dim3
  get_grid_shape(
      Params const& params,
      ProblemShapeMNKL problem_shape_mnkl,
      TileShape tile_shape_mnk,
      AtomThrShape atom_thr_shape_mnk,
      ClusterShape cluster_shape_mnk,
      KernelHardwareInfo hw_info) {
    auto grid = get_tiled_cta_shape_mnl(problem_shape_mnkl, tile_shape_mnk, atom_thr_shape_mnk, cluster_shape_mnk);
    return possibly_transpose_grid(params.raster_order_, params.divmod_cluster_shape_m_, params.divmod_cluster_shape_n_, grid);
  }

  // Possibly transpose the grid depending on rasterization order.
  CUTLASS_HOST_DEVICE
  static dim3
  possibly_transpose_grid(RasterOrder raster_order, FastDivmod divmod_cluster_shape_m, FastDivmod divmod_cluster_shape_n, dim3 grid) {
    if (raster_order == RasterOrder::AlongN) {
      // Swap grid.x and grid.y for AlongN rasterization order, since the CLC scheduler
      // will schedule in AlongM order by default.
      //
      // Each grid dimension must also be a multiple of the corresponding cluster dimension,
      // so we convert the untransposed x into the number of clusters along the M mode,
      // and multiply this by cluster.n (and vice-versa for y).
      auto tmp = grid.x;
      grid.x = divmod_cluster_shape_n.divide(grid.y) * divmod_cluster_shape_m;
      grid.y = divmod_cluster_shape_m.divide(tmp) * divmod_cluster_shape_n;
    }
    return grid;
  }

  template <class ProblemShape, class ElementAccumulator>
  static size_t
  get_workspace_size(
      Arguments const& args, 
      ProblemShape problem_shape, 
      KernelHardwareInfo const& hw_info, 
      [[maybe_unused]] uint32_t reduction_warp_groups,
      [[maybe_unused]] const uint32_t epilogue_subtile = 1,
      [[maybe_unused]] uint32_t num_accumulator_mtxs = 1) {
    
    auto problem_shape_mnkl = cute::append<4>(problem_shape, 1);

    auto cs = cutlass::detail::select_cluster_shape(ClusterShape_{}, hw_info.cluster_shape);

    return Params::get_workspace_size(
      to_gemm_coord(problem_shape_mnkl),
      GemmCoord(1, 1, 1),                 // Tile shape. Unused.
      to_gemm_coord(cs),
      hw_info,
      args.max_swizzle_size, 
      args.raster_order
    );
  }

  template <class ElementAccumulator, class ProblemShape, class TileShapeMNK, class AtomThrShape, class ClusterShape>
  static size_t
  get_workspace_size(Arguments const& args, ProblemShape problem_shape, TileShapeMNK, AtomThrShape, ClusterShape, KernelHardwareInfo const& hw_info,
      uint32_t reduction_warp_groups, uint32_t num_accumulator_mtxs = 1) {
    return get_workspace_size<ProblemShape, ElementAccumulator>(args, problem_shape, hw_info, reduction_warp_groups, num_accumulator_mtxs);
  }

  template <class ProblemShape, class ElementAccumulator>
  static cutlass::Status
  initialize_workspace(
    Arguments const& args,
    void* workspace,
    cudaStream_t stream,
    ProblemShape const& problem_shape,
    KernelHardwareInfo const& hw_info,
    uint32_t,     // reduction_warp_groups
    uint32_t = 1, // epilogue_subtile
    uint32_t = 1, // num_accumulator_mtxs
    CudaHostAdapter *cuda_adapter = nullptr) {
    auto problem_shape_mnkl = cute::append<4>(problem_shape, 1);

    auto cs = cutlass::detail::select_cluster_shape(ClusterShape_{}, hw_info.cluster_shape);

    return Params::initialize_workspace(
      workspace,
      stream,
      to_gemm_coord(problem_shape_mnkl),
      GemmCoord(1, 1, 1),                 // Tile shape. Unused.
      to_gemm_coord(cs),
      hw_info,
      args.max_swizzle_size,
      args.raster_order,
      cuda_adapter
    );
  }

  template <class ElementAccumulator, class ProblemShape, class TileShapeMNK, class AtomThrShape>
  static cutlass::Status
  initialize_workspace(
      Arguments const& args,
      void* workspace,
      cudaStream_t stream,
      ProblemShape const& problem_shape,
      TileShapeMNK,
      AtomThrShape,
      ClusterShape,
      KernelHardwareInfo const& hw_info,
      uint32_t reduction_warp_groups,
      uint32_t num_accumulator_mtxs = 1,
      CudaHostAdapter *cuda_adapter = nullptr) {

    return initialize_workspace<ProblemShape, ElementAccumulator>(
      args,
      workspace,
      stream,
      problem_shape,
      hw_info,
      reduction_warp_groups,
      1,  // epilogue_subtile
      num_accumulator_mtxs,
      cuda_adapter
    );
  }

  static bool
  can_implement(Arguments const& args) {
    return true;
  }

  //
  // Constructors
  //
  CUTLASS_DEVICE
  PersistentTileSchedulerSm100(Params const& params)
    : scheduler_params(params) {}

  CUTLASS_DEVICE
  PersistentTileSchedulerSm100(CLCResponse* clc_response_ptr, Params const& params, dim3 block_id_in_cluster)
    : clc_response_ptr_(clc_response_ptr), scheduler_params(params), block_id_in_cluster_(block_id_in_cluster) {}

  template <class ProblemShapeMNKL, class TileShape>
  CUTLASS_DEVICE
  PersistentTileSchedulerSm100(CLCResponse* clc_response_ptr, Params const& params, ProblemShapeMNKL problem_shape_mnkl, TileShape tile_shape, dim3 block_id_in_cluster)
    : PersistentTileSchedulerSm100(clc_response_ptr, params, block_id_in_cluster) {}
  //
  // Data Members
  //
  CLCResponse *clc_response_ptr_ = nullptr;
  Params const& scheduler_params;
  dim3 block_id_in_cluster_;

  //
  // Work Tile API
  //

  // Returns the initial work tile info that will be computed over
  template <class ClusterShape>
  CUTLASS_DEVICE
  static WorkTileInfo
  initial_work_tile_info(ClusterShape cluster_shape, Params const& params) {
    WorkTileInfo work_tile{
      static_cast<int32_t>((blockIdx.x / cute::size<0>(cluster_shape)) * cute::size<0>(cluster_shape)),
      static_cast<int32_t>((blockIdx.y / cute::size<1>(cluster_shape)) * cute::size<1>(cluster_shape)),
      static_cast<int32_t>((blockIdx.z / cute::size<2>(cluster_shape)) * cute::size<2>(cluster_shape)),
      true
    };

    possibly_transpose_work_tile(work_tile, params);
    return work_tile;
  }

  // Returns the initial work tile info that will be computed over
  template <class ClusterShape>
  CUTLASS_DEVICE
  WorkTileInfo
  initial_work_tile_info(ClusterShape cluster_shape) {
    return initial_work_tile_info(cluster_shape, scheduler_params);
  }

  CUTLASS_DEVICE
  auto
  work_tile_to_cta_coord(WorkTileInfo work_tile_info) {
    // Get every cta coord in three dimensions of the cluster
    auto [cta_m_in_cluster, cta_n_in_cluster, cta_l_in_cluster] = block_id_in_cluster_;
    return make_coord(
      work_tile_info.M_idx + static_cast<int32_t>(cta_m_in_cluster),
      work_tile_info.N_idx + static_cast<int32_t>(cta_n_in_cluster),
      _,
      work_tile_info.L_idx + static_cast<int32_t>(cta_l_in_cluster)
    );
  }

  // Convert CTA-level work tile info to cluster-level tile coord
  CUTLASS_DEVICE
  auto
  work_tile_to_cluster_coord_mnkl(WorkTileInfo work_tile_info) const {
    // TileScheduler works at CTA-level, kernel works at cluster-level
    int m_coord = idx2crd(scheduler_params.divmod_cluster_shape_m_.divide(work_tile_info.M_idx),
                          scheduler_params.problem_tiles_m_);
    int n_coord = idx2crd(scheduler_params.divmod_cluster_shape_n_.divide(work_tile_info.N_idx),
                          scheduler_params.problem_tiles_n_);
    int l_coord = idx2crd(work_tile_info.L_idx,
                          scheduler_params.problem_tiles_l_);
    return make_coord(m_coord, n_coord, _, l_coord);
  }

  CUTLASS_DEVICE
  static void
  issue_clc_query(PipelineState<Stages> state, uint32_t mbarrier_addr, CLCResponse* clc_response_ptr) {
  #if defined(CUTLASS_ARCH_CLC_ENABLED)
      uint32_t result_addr = cute::cast_smem_ptr_to_uint(reinterpret_cast<const void*>(
            &clc_response_ptr[state.index()]));
      asm volatile(
        "{\n\t"
        "clusterlaunchcontrol.try_cancel.async.shared::cta.mbarrier::complete_tx::bytes.multicast::cluster::all.b128 [%0], [%1];\n\t" 
        "}\n"
        :
        : "r"(result_addr), "r"(mbarrier_addr));
  #else
      CUTLASS_NOT_IMPLEMENTED();
  #endif
  }

  CUTLASS_DEVICE
  static WorkTileInfo
  work_tile_info_from_clc_response(uint32_t result_addr) {
    WorkTileInfo work_tile_info;
    uint32_t valid = 0;

    #if defined(CUTLASS_ARCH_CLC_ENABLED)
      asm volatile(
        "{\n"
        ".reg .pred p1;\n\t"
        ".reg .b128 clc_result;\n\t"
        "ld.shared.b128 clc_result, [%4];\n\t"
        "clusterlaunchcontrol.query_cancel.is_canceled.pred.b128 p1, clc_result;\n\t"
        "selp.u32 %3, 1, 0, p1;\n\t"
        "@p1 clusterlaunchcontrol.query_cancel.get_first_ctaid.v4.b32.b128 {%0, %1, %2, _}, clc_result;\n\t"
        "}\n"
        : "=r"(work_tile_info.M_idx), "=r"(work_tile_info.N_idx), "=r"(work_tile_info.L_idx), "=r"(valid)
        : "r"(result_addr)
        : "memory"
      );

      cutlass::arch::fence_view_async_shared();
    #else
      CUTLASS_NOT_IMPLEMENTED();
    #endif
    work_tile_info.is_valid_tile = (valid == 1);
    return work_tile_info;
  }

  CUTLASS_DEVICE
  PipelineState<Stages> 
  advance_to_next_work(Pipeline& clc_pipeline, PipelineState<Stages> clc_pipe_producer_state) const {
    uint32_t mbarrier_addr = clc_pipeline.producer_get_barrier(clc_pipe_producer_state);
    // Wait for clcID buffer to become empty with a flipped phase
    clc_pipeline.producer_acquire(clc_pipe_producer_state);

    if (cute::elect_one_sync()) {
      issue_clc_query(clc_pipe_producer_state, mbarrier_addr, clc_response_ptr_);
    }

    ++clc_pipe_producer_state;
    return clc_pipe_producer_state;
  }

  // Kernel helper function to get next work tile
  template <class TileSchedulerPipeline, class TileSchedulerPipelineState>
  CUTLASS_DEVICE
  auto
  fetch_next_work(
    WorkTileInfo work_tile_info,
    TileSchedulerPipeline& scheduler_pipeline,
    TileSchedulerPipelineState scheduler_pipe_consumer_state) {

    scheduler_pipeline.consumer_wait(scheduler_pipe_consumer_state);
    auto new_work_tile_info = get_current_work(scheduler_pipe_consumer_state);
    scheduler_pipeline.consumer_release(scheduler_pipe_consumer_state);

    // Return true to indicate that the tile scheduler pipeline state should be advanced
    return cute::make_tuple(new_work_tile_info, true);
  }

  //
  // K Tile API
  //
  // Permute K iteration loading order from [C, S, R, T] to [S, R, T, C] for better L2 locality
  template <class ProblemShapeMNKL, class TileShape, class Shape>
  CUTLASS_DEVICE
  auto
  get_k_tile_iterator(WorkTileInfo const& work_tile_info, ProblemShapeMNKL problem_shape_MNKL, TileShape tile_shape, Shape) {
    constexpr int32_t rank_t = cute::rank<2>(ProblemShapeMNKL{});
    auto k_tiles = cute::ceil_div(cute::get<2>(problem_shape_MNKL), cute::get<2>(tile_shape));
    if constexpr (rank_t == 4) {
      return cute::make_coord_iterator<cute::Step<_3, _0, _1, _2>>(k_tiles);
    }
    else if constexpr (rank_t == 3) {
      return cute::make_coord_iterator<cute::Step<_2, _0, _1>>(k_tiles);
    }
    else if constexpr (rank_t == 2) {
      return cute::make_coord_iterator<cute::Step<_1, _0>>(k_tiles);
    }
    else {
      return cute::make_coord_iterator(k_tiles);
    }
  }

  template <class ProblemShape, class TileShape>
  CUTLASS_HOST_DEVICE
  static int
  get_work_k_tile_count(WorkTileInfo const& work_tile_info, ProblemShape problem_shape, TileShape tile_shape) {
    // All work units returned by this scheduler cover the entire K iteration
    // space of the output tile assigned to the work unit.
    return cute::size(cute::ceil_div(cute::get<2>(problem_shape), cute::get<2>(tile_shape)));
  }

  // Compatible with sm90 kernel layers 
  CUTLASS_HOST_DEVICE
  static uint32_t
  get_work_k_tile_start(WorkTileInfo const&) {
    // All work units returned by this scheduler start from K tile 0
    return 0u;
  }

  // Returns whether the block assigned this work should compute the epilogue for the corresponding
  // output tile. For the basic tile scheduler, this is always true.
  CUTLASS_HOST_DEVICE
  static bool
  compute_epilogue(WorkTileInfo const&, Params const&) {
    return true;
  }

  CUTLASS_HOST_DEVICE
  static bool
  compute_epilogue(WorkTileInfo const&) {
    return true;
  }

  // Returns whether fixup is needed for `work_tile_info`. None of the work units returned by
  // this scheduler require fixup, since none of the work units partition the reduction extent.
  CUTLASS_HOST_DEVICE
  static bool
  requires_fixup(Params const& params, WorkTileInfo const work_tile_info) {
    return false;
  }

  // Performs the reduction across splits for a given output tile. No fixup is required for
  // work units returned by this scheduler.
  template <class FrgTensorC>
  CUTLASS_DEVICE
  void
  fixup(WorkTileInfo const&, FrgTensorC&, uint32_t, uint32_t, uint32_t = 1) const { }

  template <
    bool IsComplex,
    class TiledMma,
    class AccEngine,
    class AccLayout,
    class AccumulatorPipeline,
    class AccumulatorPipelineState,
    class CopyOpT2R
  >
  CUTLASS_DEVICE
  AccumulatorPipelineState
  fixup(
      TiledMma const& ,
      WorkTileInfo const&,
      cute::Tensor<AccEngine, AccLayout>&,
      AccumulatorPipeline,
      AccumulatorPipelineState acc_pipe_consumer_state,
      CopyOpT2R) const {
    return acc_pipe_consumer_state;
  }

  // Returns whether the current WorkTileInfo passed in should continue to be used. Since
  // this scheduler only schedules work in units of single, full output tiles, the WorkTileInfo
  // passed in should not be used after having been processed.
  CUTLASS_DEVICE
  static bool
  continue_current_work(WorkTileInfo&) {
    return false;
  }

  //
  // Implementation Helpers
  //
  // Given the inputs, computes the total number of output blocks this problem will compute over
  // Note that this is only the logical size of our grid, not the physical grid we will actually launch.
  template<class ProblemShapeMNKL, class BlockShape, class ClusterShape>
  CUTLASS_HOST_DEVICE static dim3
  get_tiled_cta_shape_mnl(ProblemShapeMNKL problem_shape_mnkl, BlockShape blk_shape, ClusterShape cluster_shape) {
    auto grid_shape    = shape(ceil_div(problem_shape_mnkl, blk_shape));
    auto grid_shape_up = round_up(product_each(grid_shape), cluster_shape); // Assumes ClusterShape is flat
    return dim3(size<0>(grid_shape_up),   // M
                size<1>(grid_shape_up),   // N
                size<3>(grid_shape_up));  // L
  }

  template<class ProblemShapeMNKL, class TileShape, class AtomThrShape, class ClusterShape>
  CUTLASS_HOST_DEVICE
  static dim3
  get_tiled_cta_shape_mnl(ProblemShapeMNKL problem_shape_mnkl,
                          TileShape tile_shape_mnk,
                          AtomThrShape atom_thr_shape_mnk,
                          ClusterShape cluster_shape_mnk) {
    auto [tiles_m, tiles_n, tiles_l] = product_each(ceil_div(select<0,1,3>(problem_shape_mnkl), take<0,2>(tile_shape_mnk)));
    auto ctas_m = round_nearest(tiles_m * size<0>(atom_thr_shape_mnk), size<0>(cluster_shape_mnk));
    auto ctas_n = round_nearest(tiles_n * size<1>(atom_thr_shape_mnk), size<1>(cluster_shape_mnk));
    auto ctas_l = tiles_l;

    return {static_cast<uint32_t>(ctas_m),
            static_cast<uint32_t>(ctas_n),
            static_cast<uint32_t>(ctas_l)};
  }


  // Get clcID and success bit
  [[nodiscard]] CUTLASS_DEVICE
  WorkTileInfo
  get_current_work(PipelineState<Stages> state) {
    uint32_t smem_addr = cute::cast_smem_ptr_to_uint(&clc_response_ptr_[state.index()]);
    auto work_tile = work_tile_info_from_clc_response(smem_addr);
    possibly_transpose_work_tile(work_tile);
    return work_tile;
  }

  // Set data SMEM ptr 
  CUTLASS_DEVICE
  void
  set_data_ptr(CLCResponse* clc_response_ptr) {
    clc_response_ptr_ = clc_response_ptr;
  }

  CUTLASS_DEVICE
  static bool
  valid_warpgroup_in_work_tile(WorkTileInfo const& work_tile_info) {
    return true;
  }

  CUTLASS_DEVICE
  static bool
  requires_separate_reduction(Params const& params) {
    return false;
  }

  template <class FrgTensorC>
  CUTLASS_DEVICE
  static void
  fixup(Params const&, WorkTileInfo const&, FrgTensorC&, uint32_t, uint32_t) {}


  CUTLASS_DEVICE
  auto
  fetch_next_work(WorkTileInfo work_tile_info) {
    return cute::make_tuple(work_tile_info, true);
  }

  CUTLASS_DEVICE
  static cute::tuple<int32_t, int32_t>
  possibly_transpose_work_tile(Params::RasterOrder raster_order, int32_t M_idx, int32_t N_idx, FastDivmod divmod_cluster_shape_m, FastDivmod divmod_cluster_shape_n) {
    if (raster_order == Params::RasterOrder::AlongN) {
      int cluster_m, remainder_m, cluster_n, remainder_n;
      divmod_cluster_shape_m(cluster_m, remainder_m, M_idx);
      divmod_cluster_shape_n(cluster_n, remainder_n, N_idx);
      M_idx = cluster_n * divmod_cluster_shape_m.divisor + remainder_m;
      N_idx = cluster_m * divmod_cluster_shape_n.divisor + remainder_n;
    }
    return cute::make_tuple(M_idx, N_idx);
  }


  CUTLASS_DEVICE
  static void
  possibly_transpose_work_tile(WorkTileInfo& work_tile_info, Params const& params) {
    auto [M_idx, N_idx] = possibly_transpose_work_tile(
      params.raster_order_, work_tile_info.M_idx, work_tile_info.N_idx, params.divmod_cluster_shape_m_, params.divmod_cluster_shape_n_);
    work_tile_info.M_idx = M_idx;
    work_tile_info.N_idx = N_idx;
  }

  CUTLASS_DEVICE
  void
  possibly_transpose_work_tile(WorkTileInfo& work_tile_info) {
    possibly_transpose_work_tile(work_tile_info, scheduler_params);
  }
};

///////////////////////////////////////////////////////////////////////////////

} // end namespace cutlass::gemm::kernel::detail
