/***************************************************************************************************
 * Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/barrier.h"
#include "cutlass/block_striped.h"
#include "cutlass/fast_math.h"
#include "cutlass/workspace.hpp"
#include "cutlass/gemm/kernel/sm90_tile_scheduler.hpp"
#include "cutlass/kernel_hardware_info.hpp"
#include "cute/layout.hpp"
#include "cute/tensor.hpp"

namespace cutlass::gemm::kernel::detail {

// Persistent Thread Block (TB) scheduler leveraging stream-K decomposition
template <
  class TileShape,
  class ClusterShape
>
class PersistentTileSchedulerSm90StreamK {
  //
  // Data members
  //

private:
  using UnderlyingScheduler = PersistentTileSchedulerSm90;
public:
  using RasterOrder = UnderlyingScheduler::RasterOrder;
private:
  using UnderlyingArguments = typename UnderlyingScheduler::Arguments;
  using UnderlyingParams = typename UnderlyingScheduler::Params;

  uint64_t current_work_linear_idx_ = 0;

  // Minimum number of k iterations that can be assigned to a stream-K unit
  static constexpr uint32_t min_iters_per_sk_unit_ = 2;

  // Use a dummy barrier manager to simply get the type used to store the barrier
  using BarrierType = typename NamedBarrierManager<1>::T;

public:

  struct WorkTileInfo {
    int32_t M_idx = 0;
    int32_t N_idx = 0;
    int32_t K_idx = 0;
    int32_t L_idx = 0;
    bool is_valid_tile = false;

    // Number of splits to be used in computing the {L_idx, M_idx, N_idx} output tile.
    // Splits = 1 indicates that this is a data-parallel block.
    uint32_t splits = 1;

    // Number of k iterations to compute for the current tile
    uint32_t k_tile_count = 0;

    // Number of k iterations remaining for the work unit as a whole
    uint32_t k_tile_remaining = 0;

    // Whether this unit of work is the final split for the given tile
    bool is_final_split = true;
  };

  struct Arguments {

    Arguments() = default;
    Arguments(Arguments const&) = default;
    Arguments(Arguments&&) = default;
    
    CUTLASS_HOST_DEVICE
    Arguments& 
    operator=(Arguments const& args) {
      splits = args.splits;
      return *this;
    }
   
    CUTLASS_HOST_DEVICE
    Arguments& 
    operator=(Arguments&& args) noexcept {
      splits = args.splits;
      return *this;
    }

    CUTLASS_HOST_DEVICE 
    Arguments(int splits_) : splits(splits_) {}

    // The splitting factor to be used in a split-K decomposition of the problem.
    // If this is set to a value greater than 1, stream-K decomposition logic
    // is bypassed in favor of a split-K decomposition.
    int splits = 1;
    const int max_swizzle_size = 1;
  };

  struct Params {
    FastDivmodU64 divmod_cluster_shape_major_{};
    FastDivmodU64 divmod_cluster_shape_minor_{};
    FastDivmodU64 divmod_batch_{};
    FastDivmodU64 divmod_k_{};
    FastDivmodU64 divmod_cluster_blk_major_{};

    int32_t log_swizzle_size_ = 0;


    uint64_t units_per_problem_ = 0;
    RasterOrder raster_order_ = RasterOrder::AlongN;
    ClusterShape cluster_shape_{};

    // The splitting factor to be used in a split-K decomposition of the problem.
    // If this is set to a value greater than 1, stream-K decomposition logic
    // is bypassed in favor of a split-K decomposition.
    uint32_t splits_ = 1;

    // Number of tiled k iterations required to compute a single output tile.
    uint32_t k_tiles_per_output_tile_ = 0;

    // Number of stream-K or split-K work units that compute an extra k iteration.
    // This is done to handle residuals in dividing up the k iteration space.
    // For stream-K, since the actual assignment of work to stream-K units will be done
    // at the granularity of a cluster, we store only the number of big clusters.
    uint32_t big_units_ = 0;

    // Workspace for holding partial accumulators to be reduced across stream-K/split-K units
    void* reduction_workspace_ = nullptr;

    // Number of tiles covered by stream-K work units
    uint32_t sk_tiles_ = 0;

    // Number of work units computing stream-K tiles
    uint32_t sk_units_ = 0;

    // Number of tiled k iterations computed by each stream-K work unit. This
    // can potentially cover more than one output tile.
    uint32_t k_tiles_per_sk_unit_ = 0;
  };

  // Sink scheduler params as a member
  Params scheduler_params;

  //
  // Methods
  //

  template <class ProblemShape>
  static Params
  to_underlying_arguments(
    ProblemShape problem_shape_mnkl,
    TileShape tile_shape,
    ClusterShape cluster_shape,
    KernelHardwareInfo const& hw_info,
    Arguments const& args,
    void* workspace) {

    static_assert(cute::is_static<TileShape>::value);
    static_assert(cute::is_static<ClusterShape>::value);

    // Round up to nearest multiple of cluster dim along each mode
    auto [problem_blocks_m, problem_blocks_n, problem_blocks_l] = get_tiled_cta_shape_mnl(
        problem_shape_mnkl, tile_shape, cluster_shape);

    uint64_t output_tiles = problem_blocks_m * problem_blocks_n * problem_blocks_l;

    // Number of k tile iterations in each output tile
    uint32_t k_tiles_per_output_tile = (cute::size<2>(problem_shape_mnkl) + cute::size<2>(tile_shape) - 1) /
                               cute::size<2>(tile_shape);

    UnderlyingArguments underlying_args;
    underlying_args.max_swizzle_size = 1;
    UnderlyingParams underlying_params = UnderlyingScheduler::to_underlying_arguments(
      problem_shape_mnkl, tile_shape, cluster_shape, hw_info, underlying_args, workspace);

    void* reduction_workspace = nullptr;

    if (workspace != nullptr) {
      // Reduction workspace is at the beginning of the workspace. Lock workspace follows.
      reduction_workspace = workspace;
    }

    if (args.splits > 1) {
      // Short circuit to basic split-K decomposition

      // Don't split by more than the available number of SMs
      auto splits = args.splits > hw_info.sm_count ? hw_info.sm_count : args.splits;

      // Don't split by more than the K tile iterations
      //
      // splits is almost certainly nonnegative here (e.g., hw_info.sm_count,
      // despite being an int, is a count), so it can safely be converted to unsigned
      // in the comparison to avoid a signed-unsigned comparison warning-as-error.
      splits = static_cast<decltype(k_tiles_per_output_tile)>(splits) > k_tiles_per_output_tile ? k_tiles_per_output_tile : splits;

      return get_params_basic(
        underlying_params, problem_blocks_m, problem_blocks_n, problem_blocks_l, cluster_shape,
        splits, k_tiles_per_output_tile, reduction_workspace);
    }

    // Calculate the maximum number of blocks from clusters of shape cluster_shape that we
    // can fit within sm_count SMs.
    dim3 grid = get_grid_shape(problem_shape_mnkl, tile_shape, cluster_shape, hw_info, args);
    uint64_t ctas_per_wave = grid.x * grid.y;

    // The number of output tiles to be computed in stream-K and data-parallel fashion, respectively.
    uint32_t sk_tiles = get_num_sk_tiles(output_tiles, ctas_per_wave, k_tiles_per_output_tile);
    uint64_t dp_tiles = output_tiles - sk_tiles;

    // Calculate the number of work units covering the data-parallel and stream-K tiles.
    // A "work unit" is a single index in the linearized ID space used by the scheduler.
    // We distinguish it from a "block," which is typically tied to a hardware unit
    // (e.g., the callers into this scheduler will be persistent thread blocks).
    // A work unit can encompass multiple output tiles worth of work (as will be the
    // case for stream-K blocks).
    // Since splitting is not required for data-parallel tiles, only one data-parallel unit
    // is needed per data-parallel tile.
    uint64_t dp_units = dp_tiles;

    // Number of k iterations computed by the stream-K units as a whole
    uint64_t k_tiles_sk_total = k_tiles_per_output_tile * sk_tiles;

    // If there are stream-K tiles to compute and a sufficiently large number of k iterations
    // across them, they will be covered by a single wave of persistent threadblocks. Thus, there
    // will be as many work units as there are threadblocks in a single wave.
    //
    // When the total k iterations across stream-K tiles is too small to justify distributing
    // across an entire wave of blocks, we instead distribute the iterations over a smaller
    // set of blocks.

    // Calculate the number of stream-K units that would be needed if each stream-K unit
    // computed the minimum allowable k iterations. Truncate this to be in units of clusters.
    uint64_t min_sized_sk_units = (k_tiles_sk_total / min_iters_per_sk_unit_);
    min_sized_sk_units = (min_sized_sk_units / cute::size(cluster_shape)) * cute::size(cluster_shape);

    uint64_t sk_units = min(ctas_per_wave, min_sized_sk_units);

    if (sk_units == 0) {
      // Short circuit to basic data-parallel decomposition
      return get_params_basic(
        underlying_params, problem_blocks_m, problem_blocks_n, problem_blocks_l, cluster_shape,
        1, k_tiles_per_output_tile, reduction_workspace);
    }

    // If the number of stream-K units is a multiple of the number of stream-K tiles, then
    // the problem can leverage a basic split-K decomposition for the stream-K tiles.
    if (sk_tiles < sk_units && sk_units % sk_tiles == 0) {
      // Short circuit to basic split-K decomposition
      uint32_t sk_splits = static_cast<uint32_t>(sk_units / sk_tiles);
      return get_params_basic(
        underlying_params, problem_blocks_m, problem_blocks_n, problem_blocks_l, cluster_shape,
        sk_splits, k_tiles_per_output_tile, reduction_workspace);
    }

    // Number of k iterations computed per stream-K units
    uint64_t k_tiles_per_sk_unit = k_tiles_sk_total / sk_units;

    // Number of stream-K units that need to compute extra iterations in order to cover
    // the residual k iterations. This assumes that each such unit computes one additional
    // iteration.
    uint64_t sk_big_units = k_tiles_sk_total - (k_tiles_per_sk_unit * sk_units);

    // The division below is guaranteed to be exact because sk_big_units is guaranteed
    // to be a multiple of cluster_size (cute::size(cluster_shape)). This is useful because
    // it allows us to use a block's linearized cluster ID  to determine whether it is
    // a big block. The reasoning behind this guarnatee is explained as follows:
    //     sk_big_units = k_tiles_sk_total - (k_tiles_per_sk_unit * sk_units);
    //
    // - k_tiles_sk_total is a multiple of cluster_size because it is the product
    //   of number of tail tiles and the number of k iterations per tile. Because
    //   both the number of output tiles and number of available SMs are rounded
    //   to be multiples of cluster shape, the number of tail tiles
    //   (output_tiles % avail_sms) is a multpile of cluster_size.
    //
    // - sk_units is a multiple of cluster_size because it is either blocks_per_wave
    //   or 0, and blocks_per_wave is a multiple of the cluster_size due to the grid-planning
    //   logic rounding to multiples of cluster dimensions
    uint64_t sk_big_units_per_cluster = sk_big_units / cute::size(cluster_shape);

    return {
      underlying_params.divmod_cluster_shape_major_,
      underlying_params.divmod_cluster_shape_minor_,
      underlying_params.divmod_batch_,
      FastDivmodU64(problem_blocks_m * problem_blocks_n),  // Static k-splitting divmod. Unused for stream-K.
      underlying_params.divmod_cluster_blk_major_,
      underlying_params.log_swizzle_size_,
      static_cast<uint32_t>(dp_units + sk_units),
      underlying_params.raster_order_,
      cluster_shape,
      1,                                                   // Static k-splitting factor. Unused for stream-K.
      k_tiles_per_output_tile,
      static_cast<uint32_t>(sk_big_units_per_cluster),
      reduction_workspace,
      sk_tiles,
      static_cast<uint32_t>(sk_units),
      static_cast<uint32_t>(k_tiles_per_sk_unit)
    };
  }

  CUTLASS_HOST_DEVICE
  PersistentTileSchedulerSm90StreamK() { };

  CUTLASS_HOST_DEVICE
  PersistentTileSchedulerSm90StreamK(Params const& params_) : scheduler_params(params_) {
    if (params_.raster_order_ == RasterOrder::AlongN) {
      current_work_linear_idx_ = static_cast<uint64_t>(int(blockIdx.x) + (int(blockIdx.y) * int(gridDim.x)));
    }
    else {
      current_work_linear_idx_ = static_cast<uint64_t>((int(blockIdx.x) * int(gridDim.y)) + int(blockIdx.y));
    }
  }

  CUTLASS_DEVICE
  WorkTileInfo
  get_current_work() const {
    return get_current_work_for_linear_idx(current_work_linear_idx_, scheduler_params);
  }

  CUTLASS_DEVICE
  static WorkTileInfo
  get_current_work_for_linear_idx(uint64_t linear_idx, Params const& params) {
    if (linear_idx >= params.units_per_problem_) {
      // Invalid work. Return an empty result.
      return {0, 0, 0, 0, false, 0};
    }

    // Determine whether this work unit is a data-parallel or stream-K work unit
    bool is_stream_k_unit = linear_idx < params.sk_units_;

    bool is_split_k = params.splits_ > 1;

    if (is_split_k || !is_stream_k_unit) {
      // Bypass the stream-K scheduling logic for basic data-parallel or split-K work
      return set_non_stream_k_work(linear_idx, params, is_split_k);
    }
    else {
      // This is a stream-K work unit
      WorkTileInfo work_tile_info;
      set_stream_k_work(params, linear_idx, work_tile_info, /*new_unit = */ true);
      return work_tile_info;
    }
  }

  // Returns whether the current work_tile_info passed in should continue to be used. This
  // occurs only in the stream-K decomposition with stream-K work units, which encompass
  // work over multiple output tiles. If the current work_tile_info should continue to be
  // used, it is updated to advance to the next output tile it should cover.
  CUTLASS_DEVICE
  bool
  continue_current_work(WorkTileInfo& work_tile_info) const {
    return continue_current_work_for_linear_idx(
      current_work_linear_idx_, work_tile_info, scheduler_params);
  }

  CUTLASS_DEVICE static
  bool
  continue_current_work_for_linear_idx(
    uint64_t linear_idx,
    WorkTileInfo& work_tile_info,
    Params const& params) {

    work_tile_info.k_tile_remaining -= work_tile_info.k_tile_count;

    if (work_tile_info.k_tile_remaining == 0) {
      return false;
    }

    set_stream_k_work(params, linear_idx, work_tile_info, /* new_unit = */ false);
    return true;
  }

  CUTLASS_DEVICE
  void
  advance_to_next_work(uint32_t advance_count = 1) {
    current_work_linear_idx_ += static_cast<uint64_t>(int(gridDim.x) * int(gridDim.y) * int(gridDim.z)) * advance_count;
  }

  // Given the inputs, computes the total number of output blocks this problem will compute over
  // Note that this is only the logical size of our grid, not the physical grid we will actually launch.
  template <class ProblemShape>
  CUTLASS_HOST_DEVICE static
  dim3
  get_tiled_cta_shape_mnl(ProblemShape problem_shape_mnkl, TileShape cta_shape, ClusterShape cluster_shape) {
    return UnderlyingScheduler::get_tiled_cta_shape_mnl(problem_shape_mnkl, cta_shape, cluster_shape);
  }

  // Given the cluster shape, computes the physical grid we should launch.
  template <class ProblemShape>
  CUTLASS_HOST_DEVICE static
  dim3
  get_grid_shape(
    ProblemShape problem_shape,
    TileShape tile_shape,
    ClusterShape cluster_shape,
    KernelHardwareInfo hw_info,
    Arguments arguments) {

    UnderlyingArguments underlying_args;
    underlying_args.max_swizzle_size = 1;
    // Call into the underlying get_grid_shape method, but do not allow the grid shape returned
    // to be truncated based on the number of output tiles in the problem.
    return UnderlyingScheduler::get_grid_shape(
      problem_shape,
      tile_shape,
      cluster_shape,
      hw_info,
      underlying_args,
      /*truncate_by_problem_size=*/false);
  }

  // Returns whether fixup is needed for `work_tile_info`.
  CUTLASS_HOST_DEVICE
  static bool
  requires_fixup(Params const& params, WorkTileInfo const& work_tile_info) {
    // Fixup is not needed for data-parallel tiles
    return work_tile_info.k_tile_count != params.k_tiles_per_output_tile_;
  }

  // Performs the reduction across splits for a given output tile.
  template <class FrgTensorC>
  CUTLASS_DEVICE
  static void
  fixup(
    Params const& params,
    WorkTileInfo const& work_tile_info,
    FrgTensorC& accumulators,
    uint32_t num_barriers,
    uint32_t barrier_idx) {
    using BarrierManager = NamedBarrierManager<NumThreadsPerWarpGroup, 2>;
    return fixup_helper<FrgTensorC, BarrierManager>(
      params, work_tile_info, accumulators, num_barriers, barrier_idx);
  }

  // Helper for performing the reduction across splits for a given output tile.
  template <class FrgTensorC, class BarrierManager>
  CUTLASS_DEVICE
  static void
  fixup_helper(
    Params const& params,
    WorkTileInfo const& work_tile_info,
    FrgTensorC& accumulators,
    uint32_t num_barriers,
    uint32_t barrier_idx) {

    using ElementAccumulator = typename FrgTensorC::value_type;

    if (!requires_fixup(params, work_tile_info)) {
      return;
    }

    auto tile_idx = output_tile_index(params, work_tile_info);

    // Index of the lock on which to wait
    auto lock_idx = (tile_idx * num_barriers) + barrier_idx;

    // Reductions use BlockStripedReduce with a width of BarrierManager::ThreadCount under the hood.
    // Thus, the start of the reduction space is the same across all threads in a warp group.
    int reduction_offset =
      (cute::size<0>(TileShape{}) * cute::size<1>(TileShape{}) * tile_idx) +
      (size(accumulators) * barrier_idx * BarrierManager::ThreadCount);

    ElementAccumulator* group_reduction_workspace = reinterpret_cast<ElementAccumulator*>(params.reduction_workspace_) + reduction_offset;

    using AccumulatorArrayT = Array<typename FrgTensorC::value_type, size(FrgTensorC{})>;
    using BlockStripedReduceT = BlockStripedReduce<BarrierManager::ThreadCount, AccumulatorArrayT>;

    AccumulatorArrayT* reduction_workspace_array = reinterpret_cast<AccumulatorArrayT*>(group_reduction_workspace);
    AccumulatorArrayT* accumulator_array = reinterpret_cast<AccumulatorArrayT*>(&accumulators);

    int barrier_group_thread_idx = threadIdx.x % BarrierManager::ThreadCount;

    // The number of tiles for which reduction is required is either:
    //   (a) the total number of output tiles (in the case of split-K)
    //   (b) the number of stream-K tiles
    // To calcualte the the total number of output tiles in the split-K case, we
    // note that, in the split-K case, the units_per_problem_ member of Params will be
    // the total number of output tiles multiplied by the number of splits.
    auto reduction_tiles = params.splits_ > 1 ? (params.units_per_problem_ / params.splits_) : params.sk_tiles_;
    auto reduction_workspace_size = get_reduction_workspace_size<ElementAccumulator>(reduction_tiles);
    BarrierType* lock_workspace = reinterpret_cast<BarrierType*>(
      reinterpret_cast<uint8_t*>(params.reduction_workspace_) + reduction_workspace_size);

    if (!work_tile_info.is_final_split) {
      if (work_tile_info.K_idx == 0) {
        // First peer initializes the workspace partials
        BlockStripedReduceT::store(reduction_workspace_array, *accumulator_array, barrier_group_thread_idx);
      }
      else {
        // Wait until the preceding split added its accumulators
        BarrierManager::wait_eq(barrier_idx, lock_workspace, barrier_group_thread_idx, lock_idx, work_tile_info.K_idx);

        // Perform reduction in workspace
        BlockStripedReduceT::reduce(reduction_workspace_array, *accumulator_array, barrier_group_thread_idx);
      }

      // Signal our arrival
      BarrierManager::arrive_inc(barrier_idx, lock_workspace, barrier_group_thread_idx, lock_idx, work_tile_info.k_tile_count);
    }
    else {
      // Wait until the preceding split added its accumulators
      BarrierManager::wait_eq(barrier_idx, lock_workspace, barrier_group_thread_idx, lock_idx, work_tile_info.K_idx);

      // The block computing the final split for the tile adds previously-reduced partials
      // to its accumulators and computes the epilogue.
      BlockStripedReduceT::load_add(*accumulator_array, reduction_workspace_array, barrier_group_thread_idx);
    }
  }

  // Splits an input tensor with MxK according to the splitting configuration specified by work_tile_info
  template<class Engine, class Layout>
  CUTLASS_DEVICE
  static auto
  split_MK(cute::Tensor<Engine, Layout> const& tensor, WorkTileInfo const& work_tile_info) {
    return split<Engine, Layout, 0>(tensor, work_tile_info);
  }

  // Splits an input tensor with NxK tiles according to the splitting configuration specified by work_tile_info
  template<class Engine, class Layout>
  CUTLASS_DEVICE
  static auto
  split_NK(cute::Tensor<Engine, Layout> const& tensor, WorkTileInfo const& work_tile_info) {
    return split<Engine, Layout, 1>(tensor, work_tile_info);
  }

  // Returns whether the block assigned this work should compute the epilogue for the corresponding
  // output tile. For the case of stream-K, this should only occur if the work is marked as the final split.
  CUTLASS_HOST_DEVICE
  static bool
  compute_epilogue(WorkTileInfo const& work_tile_info) {
    return work_tile_info.is_final_split;
  }

  // Returns the linearized index of the output tile corresponding to the tile with offset [L, M, K]
  CUTLASS_DEVICE
  static int
  output_tile_index(Params const& params, WorkTileInfo const& work_tile_info) {
    if (params.splits_ > 1) {
      auto tiles_mn = params.divmod_batch_.divisor / params.splits_;
      if (params.raster_order_ == RasterOrder::AlongN) {
        return
          (tiles_mn * work_tile_info.L_idx) +
          (params.divmod_cluster_shape_major_.divisor * 
           params.divmod_cluster_blk_major_.divisor * work_tile_info.M_idx) +
          work_tile_info.N_idx;
      }
      else {
        return
          (tiles_mn * work_tile_info.L_idx) +
          (params.divmod_cluster_shape_major_.divisor * 
           params.divmod_cluster_blk_major_.divisor * work_tile_info.N_idx) +
          work_tile_info.M_idx;
      }
    }
    else {
      auto [cta_m_in_cluster, cta_n_in_cluster, _] = cute::block_id_in_cluster();

      uint64_t cta_per_grid_dim;
      uint64_t cluster_dim_idx;
      if (params.raster_order_ == RasterOrder::AlongN) {
        uint64_t block_idx_m = (work_tile_info.M_idx - cta_m_in_cluster) / cute::size<0>(params.cluster_shape_);
        uint64_t block_idx_n = work_tile_info.N_idx;
        cta_per_grid_dim = (params.divmod_cluster_shape_major_.divisor * 
           params.divmod_cluster_blk_major_.divisor * block_idx_m) + block_idx_n;
        cluster_dim_idx = cta_m_in_cluster;
      }
      else {
        uint64_t block_idx_m = work_tile_info.M_idx;
        uint64_t block_idx_n = (work_tile_info.N_idx - cta_n_in_cluster) / cute::size<1>(params.cluster_shape_);
        cta_per_grid_dim = (params.divmod_cluster_shape_major_.divisor * 
           params.divmod_cluster_blk_major_.divisor * block_idx_n) + block_idx_m;
        cluster_dim_idx = cta_n_in_cluster;
      }

      uint64_t tile_in_batch = params.divmod_cluster_shape_minor_.divisor * cta_per_grid_dim;
      return params.divmod_batch_.divisor * work_tile_info.L_idx + tile_in_batch + cluster_dim_idx;
    }
  }

  template <class ProblemShape, class ElementAccumulator>
  static int
  get_workspace_size(
    Arguments const& args,
    ProblemShape problem_shape,
    KernelHardwareInfo const& hw_info,
    uint32_t mma_warp_groups) {

    int barrier_workspace_size = 0;
    int reduction_workspace_size = 0;

    get_workspace_component_sizes<ProblemShape, ElementAccumulator>(
      args, problem_shape, barrier_workspace_size, reduction_workspace_size, hw_info, mma_warp_groups);

    return barrier_workspace_size + reduction_workspace_size;
  }

  template <class ProblemShape, class ElementAccumulator>
  static cutlass::Status
  initialize_workspace(
    Arguments const& args,
    void* workspace,
    cudaStream_t stream,
    ProblemShape const& problem_shape,
     KernelHardwareInfo const& hw_info,
    uint32_t mma_warp_groups) {

    #if !defined(__CUDACC_RTC__)
      int barrier_workspace_size = 0;
      int reduction_workspace_size = 0;

      get_workspace_component_sizes<ProblemShape, ElementAccumulator>(
        args, problem_shape, barrier_workspace_size, reduction_workspace_size, hw_info, mma_warp_groups);

      if (barrier_workspace_size > 0) {
        if (workspace == nullptr) {
          return Status::kErrorWorkspaceNull;
        }

        // Only the barrier workspace needs to be cleared for stream-K.
        // Barrier workspace follows reduction workspace.
        uint8_t* barrier_workspace = reinterpret_cast<uint8_t*>(workspace) + reduction_workspace_size;
        return zero_workspace(static_cast<void*>(barrier_workspace), barrier_workspace_size, stream);
      }

      return Status::kSuccess;
    #endif
  }

  template <class ProblemShape>
  CUTLASS_HOST_DEVICE
  static int
  get_work_k_tile_count(WorkTileInfo const& work_tile_info, ProblemShape, TileShape) {
    return work_tile_info.k_tile_count;
  }

private:
  // Splits a tensor using the splitting configuration specified by work_tile_info using
  // a MN shape detemined by TileDim0.
  template <class Engine, class Layout, int TileDim0>
  CUTLASS_DEVICE
  static auto
  split(cute::Tensor<Engine, Layout> const& tensor, WorkTileInfo const& work_tile_info) {
    using namespace cute;

    // Divide input tensor into `splits` chunks along the k dimension
    auto div_shape = make_shape(size<TileDim0>(TileShape{}), size<2>(TileShape{}), work_tile_info.splits);
    auto split = zipped_divide(tensor, div_shape);

    // Index into the split tensor at the work tile's split index
    auto indexed = split(make_coord(make_coord(_, _, work_tile_info.K_idx), make_coord(0, 0, _)));

    // Construct a layout for the indexed tensor. The main purpose of this new layout is to
    // override the k extent to support cases in which the split computes a number of iterations
    // not equal to total_k_tiles / splits. A common example of this is in stream-K is when a
    // unit computes the final 20 of the total 32 k iterations of the output tile. In this case,
    // set splits = 32 and the split index (K_idx) to 11. The zipped divide above results in each
    // of the splits computing only one k iteration.
    auto overridden_shape = make_shape(size<0>(indexed.layout()), size<1>(indexed.layout()), work_tile_info.k_tile_count);
    auto layout = make_layout(overridden_shape, tensor.stride());

    return make_tensor(indexed.data(), layout);
  }

  // Returns the number of stream-K tiles that will be computed amongst `output_tiles` total
  // output tiles on a device with `ctas_per_wave` CTAs in each wave.
  static uint32_t
  get_num_sk_tiles(uint64_t output_tiles, uint64_t ctas_per_wave, uint32_t k_tiles_per_output_tile) {
    uint32_t full_waves = static_cast<uint32_t>(output_tiles / ctas_per_wave);
    uint32_t total_waves = static_cast<uint32_t>((output_tiles + ctas_per_wave - 1) / ctas_per_wave);

    if (full_waves == total_waves || k_tiles_per_output_tile == 1) {
      // All tiles will be data-parallel tiles if there is either no quantization
      // or if there is no work to be split.
      return 0;
    }

    //
    // The final wave is not full. Perform some stream-K work.
    //

    // Rudimentary heuristic: prefer data-parallel decomposition if we have more than
    // one wave and the tail wave is more than half full. This is subject to change.
    if (full_waves != 0) {
      uint64_t tail_tiles = output_tiles - (full_waves * ctas_per_wave);
      if (tail_tiles >= (ctas_per_wave / 2)) {
        return 0;
      }
    }

    // If there is wave quantization, assign the first two waves worth of tiles to be
    // covered by stream-K work and the remainder to be data-parallel. Since we know
    // that full_waves == total_waves - 1 in this case, the number of data-parallel
    // waves is simply full_waves-1 (unless full_waves == 0).
    uint32_t dp_waves = full_waves > 0 ? full_waves - 1 : 0;

    uint64_t dp_tiles = dp_waves * ctas_per_wave;
    return static_cast<uint32_t>(output_tiles - dp_tiles);
  }

  // Calculates the size of the workspace needed for holding reduction barriers
  CUTLASS_HOST_DEVICE
  static int
  get_barrier_workspace_size(uint64_t num_tiles, uint32_t mma_warp_groups) {
    auto workspace_bits = num_tiles * mma_warp_groups * sizeof_bits<BarrierType>::value;
    return bits_to_bytes(static_cast<int>(workspace_bits));
  }

  // Calculates the size of the workspace needed for holding partial outputs from splits
  template <class ElementAccumulator>
  CUTLASS_HOST_DEVICE
  static int
  get_reduction_workspace_size(uint64_t num_tiles) {
    auto output_tile_size = cute::size<0>(TileShape{}) * cute::size<1>(TileShape{});
    auto workspace_bits = sizeof_bits<ElementAccumulator>::value * output_tile_size * num_tiles;
    return bits_to_bytes(static_cast<int>(workspace_bits));
  }

  template <class ProblemShape, class ElementAccumulator>
  static void
  get_workspace_component_sizes(
    Arguments const& args,
    ProblemShape problem_shape,
    int& barrier_workspace_size,
    int& reduction_workspace_size,
    KernelHardwareInfo const& hw_info,
    uint32_t mma_warp_groups) {

    // Workspace is needed only for output tiles that will be split. Thus, we first determine the number
    // of output tiles that will be split, and then calculate the workspace needed to cover these.

    auto problem_shape_mnkl = cute::append<4>(problem_shape, 1);

    ClusterShape cluster_shape;
    auto [problem_blocks_m, problem_blocks_n, problem_blocks_l] = get_tiled_cta_shape_mnl(
      problem_shape_mnkl, TileShape{}, cluster_shape);
    uint64_t output_tiles = problem_blocks_m * problem_blocks_n * problem_blocks_l;

    if (args.splits > 1) {
      // Basic split-K variant requires workspace for all output tiles
      barrier_workspace_size = get_barrier_workspace_size(output_tiles, mma_warp_groups);
      reduction_workspace_size = get_reduction_workspace_size<ElementAccumulator>(output_tiles);
    }
    else {
      int sm_count = hw_info.sm_count;
      if (sm_count <= 0) {
        CUTLASS_TRACE_HOST("  WARNING: Arguments do not include a valid SM count.\n"
            "  For optimal performance, populate the arguments KernelHardwareInfo struct with the SM count.");
        sm_count = KernelHardwareInfo::query_device_multiprocessor_count(hw_info.device_id);
      }

      uint32_t k_tiles_per_output_tile = (cute::size<2>(problem_shape_mnkl) + cute::size<2>(TileShape{}) - 1) /
                                   cute::size<2>(TileShape{});

      dim3 grid = get_grid_shape(problem_shape_mnkl, TileShape{}, cluster_shape, {0, sm_count}, args);
      uint64_t ctas_per_wave = grid.x * grid.y;
      uint32_t sk_tiles = get_num_sk_tiles(output_tiles, ctas_per_wave, k_tiles_per_output_tile);

      barrier_workspace_size = get_barrier_workspace_size(sk_tiles, mma_warp_groups);
      reduction_workspace_size = get_reduction_workspace_size<ElementAccumulator>(sk_tiles);
    }
  }

  // Constructs parameters for either a basic data-parallel or basic split-K decomposition of the problem
  static Params
  get_params_basic(
    UnderlyingParams const& underlying_params,
    uint32_t blocks_m,
    uint32_t blocks_n,
    uint32_t blocks_l,
    ClusterShape cluster_shape,
    uint32_t splits,
    uint32_t k_tiles_per_output_tile,
    void* reduction_workspace) {

    uint32_t big_units = k_tiles_per_output_tile % splits;

    return {
      underlying_params.divmod_cluster_shape_major_,
      underlying_params.divmod_cluster_shape_minor_,
      FastDivmodU64(blocks_m * blocks_n * splits),
      FastDivmodU64(blocks_m * blocks_n),
      underlying_params.divmod_cluster_blk_major_,
      underlying_params.log_swizzle_size_,
      blocks_m * blocks_n * blocks_l * splits,
      underlying_params.raster_order_,
      cluster_shape,
      splits,
      k_tiles_per_output_tile,
      big_units,
      reduction_workspace
    };
  }

  // Sets the current stream-K work to compute within work_tile_info. If new_unit is true, work_tile_info
  // is populated as a new unit of work. Otherwise, state existing in work_tile_info (e.g., remaining
  // iterations) is used to find the next tile in the current work unit.
  CUTLASS_DEVICE
  static void
  set_stream_k_work(
    Params const& params,
    uint64_t linear_idx,
    WorkTileInfo& work_tile_info,
    bool new_unit) {
    // In the CUTLASS 2.x implementation of stream K, stream-K work is assigned to each stream-K
    // threadblock individually. For the most part, the set of K iterations corresponding to stream-K
    // work was divided amongst stream-K threadblocks, and a threadblock determined which tile
    // it would compute a (potentially-partial) output tile for based on the space of k iterations
    // assigned to it. This often results in stream-K threadblocks processing tiles with different
    // offsets in the K dimension from one another. This can reduce locality, but is lmitied to the
    // (generally few) waves of threadblocks assigned to compute stream-K work.
    //
    // With the introduction of threadblock clusters, there is additional benefit to maintaining
    // locality in the K dimension: shared portions of operands can be multicasted to threadblocks
    // within a cluster. Thus, we would like to ensure that the assignment of stream-K work to
    // threadblocks respects the ability to perform multicasting.
    //
    // To do so, we divide up the linearized stream-K units into clusters and share the same K
    // offsets for work within clusters.
    auto cluster_linear_work_idx = linear_idx / size(params.cluster_shape_);

    // Determine the starting k iteration computed by this stream-K work unit
    uint32_t unit_iter_start = params.k_tiles_per_sk_unit_ * cluster_linear_work_idx;

    // Adjust the starting position and number of k iterations for "big units," which
    // compute one extra iteration. These are the first big_units_ units in the
    // linearized ID space.
    bool is_big_unit = cluster_linear_work_idx < params.big_units_;
    if (is_big_unit) {
      // Since the "big units" are the first units in the linearized ID space, each
      // of the units preceding this big unit computed one extra iteration. Thus,
      // we must offset our start iteration by the number of units that precede
      // the current unit in the linearized ID space.
      unit_iter_start += cluster_linear_work_idx;
    } else {
      // Increment by one for each of the big clusters (since all big units precede this unit)
      unit_iter_start += params.big_units_;
    }

    uint32_t unit_iters;
    if (new_unit) {
      unit_iters = params.k_tiles_per_sk_unit_;

      // Only adjust iteration count for big unit if we are initializing this
      // work unit. For existing work units, the extra iteration for big units
      // has already been accounted for in k_tiles_reamaining
      if (is_big_unit) {
        ++unit_iters;
      }
    }
    else {
      unit_iters = work_tile_info.k_tile_remaining;
    }

    // Find the output tile corresponding to the final k iteration covered by this
    // work unit. Stream-K work units will work backwards in terms of the tiles they
    // are responsible computing. This is beneficial because the final (partial)
    // tile computed by a stream-K block is typically the beginning of the output
    // tile, while the beginning (partial) tile is typically the ending of another
    // output tile. Since ending portions of an output tile must reduce across
    // other work units computing portions of that output tile, it is preferable
    // for them to be computed later, so as to reduce the likelihood of blocking
    // on other work.
    uint32_t unit_iter_end = unit_iter_start + unit_iters - 1;
    uint32_t true_tile_id = unit_iter_end / params.k_tiles_per_output_tile_;
    uint32_t true_tile_iter_start = true_tile_id * params.k_tiles_per_output_tile_;
    uint32_t true_tile_iter_end = true_tile_iter_start + params.k_tiles_per_output_tile_;

    // Bring the linearized tile ID back into the space of tiles, rather than clusters
    true_tile_id *= size(params.cluster_shape_);

    auto [cta_m_in_cluster, cta_n_in_cluster, _] = cute::block_id_in_cluster();

    // The final linearized tile ID is in units of the cluster dimension over which we rasterize.
    if (params.raster_order_ == RasterOrder::AlongN) {
      true_tile_id += cta_n_in_cluster * cute::size<0>(params.cluster_shape_);
    }
    else {
      true_tile_id += cta_m_in_cluster * cute::size<1>(params.cluster_shape_);
    }

    // The unit's starting k iteration in the current tile is either the starting
    // iteration for the tile as a whole, or the starting k iteration for the unit
    // as a whole (if the latter is greater than the former).
    uint32_t tile_iter_start = max(true_tile_iter_start, unit_iter_start);

    // Similarly, the unit's ending k iteration (exclusive) is either the end of
    // the current tile it is assigned, or the ending iteration of the unit as a whole
    // (if the latter is less than the former).
    uint32_t tile_iter_end = min(true_tile_iter_end, unit_iter_end + 1);

    uint32_t tile_iters = tile_iter_end - tile_iter_start;

    uint64_t work_idx_l, remainder;
    params.divmod_batch_(work_idx_l, remainder, true_tile_id);

    uint64_t cta_per_grid_dim, dontcare;
    params.divmod_cluster_shape_minor_(cta_per_grid_dim, dontcare, remainder);

    auto [work_idx_m, work_idx_n] = UnderlyingScheduler::get_work_idx_m_and_n(
                                          cta_per_grid_dim,
                                          params.divmod_cluster_shape_major_,
                                          params.divmod_cluster_shape_minor_,
                                          params.divmod_cluster_blk_major_,
                                          params.log_swizzle_size_, 
                                          params.raster_order_);

    //
    // Update the work_tile_info
    //

    // Set the M, N, and L block offsets
    work_tile_info.M_idx = work_idx_m;
    work_tile_info.N_idx = work_idx_n;
    work_tile_info.L_idx = static_cast<int32_t>(work_idx_l);

    // Set the k offset to be the starting k tile for this output tile
    work_tile_info.K_idx = static_cast<int32_t>(tile_iter_start - true_tile_iter_start);

    // Set the split count to be the number of k tiles in the output tile
    work_tile_info.splits = params.k_tiles_per_output_tile_;

    // Any checks for invalid work units should be done prior to this call
    work_tile_info.is_valid_tile = true;

    work_tile_info.k_tile_count = tile_iters;
    work_tile_info.k_tile_remaining = unit_iters;

    // Compute the epilogue if this unit of work contains the ending k iteration for
    // the output tile in question
    work_tile_info.is_final_split = (tile_iter_end == true_tile_iter_end);
  }

  // Returns a WorkTileInfo to be computed for either the data-parallel or split-K
  // work unit identified by the provided linear ID.
  CUTLASS_DEVICE
  static WorkTileInfo
  set_non_stream_k_work(uint64_t linear_idx, Params const& params, bool is_split_k) {

    // The linearized ID space is in terms of work units, rather than tiles. However,
    // to compute the correct block offset for a data-parallel tile, we must convert
    // the current ID to the data-parallel tile it corresponds to. Each data-parallel
    // unit maps to a single data-parallel tile, but each stream-K unit can map to more
    // than one tile. Thus, we must offset the work-unit ID among the data-parallel units
    // by the total number of output tiles that will be computed by stream-K units.
    //
    // The logic below also works for the split-K case, in which sk_units_ and sk_tiles_
    // are each 0.
    uint64_t linear_work_idx = linear_idx - params.sk_units_ + params.sk_tiles_;

    // Map worker's linear index into the CTA-tiled problem shape to the corresponding MNL indices
    uint64_t work_idx_l, remainder;
    params.divmod_batch_(work_idx_l, remainder, linear_work_idx);

    uint64_t work_idx_k = 0;
    if (is_split_k) {
      params.divmod_k_(work_idx_k, remainder, remainder);
    }

    uint64_t cta_per_grid_dim, dontcare;
    params.divmod_cluster_shape_minor_(cta_per_grid_dim, dontcare, remainder);

    auto [work_idx_m, work_idx_n] = UnderlyingScheduler::get_work_idx_m_and_n(
                                        cta_per_grid_dim,
                                        params.divmod_cluster_shape_major_,
                                        params.divmod_cluster_shape_minor_,
                                        params.divmod_cluster_blk_major_,
                                        params.log_swizzle_size_,
                                        params.raster_order_);

    bool is_final_split = (work_idx_k == params.splits_ - 1);

    uint32_t k_tiles = params.k_tiles_per_output_tile_;
    if (is_split_k) {
      // Determine the number of iterations and starting iteration of this split.
      // Doing so requires accounting for residual iterations, which are handled
      // by the first big_units_ splits (with big_units_ = tiles % sm_count).

      // Offsets for "normal" units. No additional k iterations are performed,
      // and big_units_ "big" units preceded us, each of which performed one
      // additional iteration. Thus, we must increase our split starting offset
      // by big_units_.
      int additional_k_tiles = 0;
      int split_start_offset = params.big_units_;

      if (work_idx_k < params.big_units_) {
        // Offsets for "big" units. One additional k iteration is performed,
        // and each split preceding us was a big unit, so we must increase
        // our split starting offset by our split ID (work_idx_k).
        additional_k_tiles = 1;
        split_start_offset = work_idx_k;
      }

      // Set up k iteration count and split starting iteration assuming the
      // iteration space is evenly split.
      k_tiles /= params.splits_;
      work_idx_k *= k_tiles;

      // Apply any fixup needed to handle residuals
      work_idx_k += split_start_offset;
      k_tiles += additional_k_tiles;
    }

    return {
      work_idx_m,
      work_idx_n,
      static_cast<int32_t>(work_idx_k),
      static_cast<int32_t>(work_idx_l),
      true,
      params.k_tiles_per_output_tile_,
      k_tiles,
      k_tiles, // remaining iterations
      is_final_split
    };
  }
};

} // namespace cutlass::gemm::kernel::detail
