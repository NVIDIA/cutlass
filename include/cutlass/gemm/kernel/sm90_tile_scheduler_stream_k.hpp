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

private:
  using UnderlyingArguments = typename UnderlyingScheduler::Arguments;
  using UnderlyingParams = typename UnderlyingScheduler::Params;

  uint64_t current_work_linear_idx_ = 0;

public:

  using RasterOrder = UnderlyingScheduler::RasterOrder;
  using RasterOrderOptions = UnderlyingScheduler::RasterOrderOptions;
  // Use a dummy barrier manager to simply get the type used to store the barrier
  using BarrierType = typename NamedBarrierManager<1>::T;

  using Params = PersistentTileSchedulerSm90StreamKParams;
  using ReductionMode = Params::ReductionMode;

  struct WorkTileInfo {
    int32_t M_idx = 0;
    int32_t N_idx = 0;
    int32_t K_idx = 0;
    int32_t L_idx = 0;

    // Number of k tiles to compute for this unit of work. For stream-K, this
    // can indicate the number of K tiles across multiple output tiles.
    uint32_t k_tile_count = 0;

    // Number of k tiles remaining for the work unit as a whole
    uint32_t k_tile_remaining = 0;

    CUTLASS_HOST_DEVICE
    bool
    is_valid() const {
      // Use negative indices to denote invalid work
      return M_idx >= 0;
    }

    CUTLASS_HOST_DEVICE
    static WorkTileInfo
    invalid_work_tile() {
      return {-1, -1, -1, -1, 0};
    }

    CUTLASS_HOST_DEVICE
    bool
    is_final_split(uint32_t k_tiles_per_output_tile) const {
      return (K_idx + k_tile_count) == k_tiles_per_output_tile;
    }
  };

  struct Arguments {

    Arguments() = default;
    Arguments(Arguments const&) = default;
    Arguments(Arguments&&) = default;

    CUTLASS_HOST_DEVICE
    Arguments&
    operator=(Arguments const& args) {
      splits = args.splits;
      raster_order = args.raster_order;
      return *this;
    }

    CUTLASS_HOST_DEVICE
    Arguments&
    operator=(Arguments&& args) noexcept {
      splits = args.splits;
      raster_order = args.raster_order;
      return *this;
    }

    CUTLASS_HOST_DEVICE
    Arguments(int splits_) : splits(splits_) {}

    CUTLASS_HOST_DEVICE
    Arguments(int splits_, int max_swizzle_size_, RasterOrderOptions raster_order_) :
      splits(splits_),
      max_swizzle_size(max_swizzle_size_),
      raster_order(raster_order_) {}

    // The splitting factor to be used in a split-K decomposition of the problem.
    // If this is set to a value greater than 1, stream-K decomposition logic
    // is bypassed in favor of a split-K decomposition.
    int splits = 1;
    const int max_swizzle_size = 1;
    RasterOrderOptions raster_order = RasterOrderOptions::Heuristic;
    ReductionMode reduction_mode = ReductionMode::Deterministic;
  };

  // Sink scheduler params as a member
  Params scheduler_params;

  //
  // Methods
  //

  template <class ProblemShape>
  static Params
  to_underlying_arguments(
    ProblemShape problem_shape,
    TileShape tile_shape,
    ClusterShape cluster_shape,
    KernelHardwareInfo const& hw_info,
    Arguments const& args,
    void* workspace) {

    static_assert(cute::is_static<TileShape>::value);
    static_assert(cute::is_static<ClusterShape>::value);

    auto problem_shape_mnkl = cute::append<4>(problem_shape, cute::Int<1>{});
    dim3 problem_blocks = get_tiled_cta_shape_mnl(problem_shape_mnkl, tile_shape, cluster_shape);
    uint32_t k_tile_per_output_tile = cute::size(cute::ceil_div(cute::shape<2>(problem_shape_mnkl), cute::shape<2>(TileShape{})));

    Params params;
    params.initialize(
      problem_blocks,
      k_tile_per_output_tile,
      to_gemm_coord(cluster_shape),
      hw_info,
      args.splits,
      args.max_swizzle_size,
      args.raster_order,
      args.reduction_mode,
      workspace
    );
    return params;
  }

  CUTLASS_HOST_DEVICE
  PersistentTileSchedulerSm90StreamK() { };

  CUTLASS_HOST_DEVICE
  PersistentTileSchedulerSm90StreamK(Params const& params_) : scheduler_params(params_) {
    if (params_.raster_order_ == RasterOrder::AlongN) {
      current_work_linear_idx_ = uint64_t(blockIdx.x) + uint64_t(blockIdx.y) * uint64_t(gridDim.x);
    }
    else {
      current_work_linear_idx_ = uint64_t(blockIdx.x) * uint64_t(gridDim.y) + uint64_t(blockIdx.y);
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
    // The maximum number of work units is units_per_problem_ * splits_.
    // The multiplication by splits_ is used for handling split-K, in which
    // units_per_problem_ is equal to the total number of output tiles. To account
    // for the fact that we have splits_ peers per output tile, we multiply this
    // value by splits_. For stream-K, this multiplication ends up being a no-op
    // because splits_ is set to 1 for stream-K.
    if (linear_idx >= params.units_per_problem_ * params.splits_) {
      // Invalid work. Return an empty result.
      return WorkTileInfo::invalid_work_tile();
    }

    WorkTileInfo work_tile_info;
    assign_work(params, linear_idx, work_tile_info);
    return work_tile_info;
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

    assign_work(params, linear_idx, work_tile_info);
    return true;
  }

  CUTLASS_DEVICE
  void
  advance_to_next_work(uint32_t advance_count = 1) {
    current_work_linear_idx_ += uint64_t(gridDim.x) * uint64_t(gridDim.y) * uint64_t(gridDim.z) * uint64_t(advance_count);
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

    auto problem_shape_mnkl = cute::append<4>(problem_shape, cute::Int<1>{});
    dim3 problem_blocks = get_tiled_cta_shape_mnl(problem_shape_mnkl, tile_shape, cluster_shape);

    return Params::get_grid_shape(
      problem_blocks,
      to_gemm_coord(cluster_shape),
      hw_info,
      arguments.max_swizzle_size, 
      arguments.raster_order
    );
  }

  // Returns whether fixup is needed for `work_tile_info`.
  CUTLASS_HOST_DEVICE
  static bool
  requires_fixup(Params const& params, WorkTileInfo const& work_tile_info) {
    // Fixup is not needed for data-parallel tiles
    return work_tile_info.k_tile_count != params.divmod_tiles_per_output_tile_.divisor;
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
    static constexpr uint32_t Offset = 2;
    static constexpr uint32_t MaxNumNamedBarriers = 2;
    using BarrierManager = NamedBarrierManager<NumThreadsPerWarpGroup, Offset, MaxNumNamedBarriers>;
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

    // The number of tiles for which reduction is required is either:
    //   (a) the total number of output tiles (in the case of split-K)
    //   (b) the number of stream-K tiles
    // To calculate the total number of output tiles in the split-K case, we
    // note that, in the split-K case, the units_per_problem_ member of Params will be
    // the total number of output tiles.
    auto reduction_tiles = params.splits_ > 1 ? params.units_per_problem_ : params.sk_tiles_;
    auto reduction_workspace_size = Params::get_reduction_workspace_size(
      reduction_tiles, to_gemm_coord(TileShape{}), sizeof_bits<ElementAccumulator>::value);
    BarrierType* lock_workspace = reinterpret_cast<BarrierType*>(
      reinterpret_cast<uint8_t*>(params.reduction_workspace_) + reduction_workspace_size);

    AccumulatorArrayT* reduction_workspace_array = reinterpret_cast<AccumulatorArrayT*>(group_reduction_workspace);
    AccumulatorArrayT* accumulator_array = reinterpret_cast<AccumulatorArrayT*>(&accumulators);
    int barrier_group_thread_idx = threadIdx.x % BarrierManager::ThreadCount;

    if (!work_tile_info.is_final_split(params.divmod_tiles_per_output_tile_.divisor)) {
      if (work_tile_info.K_idx == 0) {
        // First peer initializes the workspace partials
        BlockStripedReduceT::store(reduction_workspace_array, *accumulator_array, barrier_group_thread_idx);
      }
      else {
        if (params.reduction_mode_ == ReductionMode::Deterministic) {
          // Wait until the preceding split added its accumulators
          BarrierManager::wait_eq(barrier_idx, lock_workspace, barrier_group_thread_idx, lock_idx, work_tile_info.K_idx);
        }
        else {
          // Wait until the first split has stored its accumulators. Note that the first split will have
          // accumulated a value into the lock potentially greater than one (since the locked value is
          // incremented by work_tile_info.k_tile_count below for both the deterministic and non-deterministic)
          // cases. For non-deterministic reductions, all that non-first or last splits care about is whether
          // the first split has been written, so we only wait while the locked value is less than 1. This
          // avoids having to add logic to determine the work_tile_info.k_tile_count for the first split.
          BarrierManager::wait_lt(barrier_idx, lock_workspace, barrier_group_thread_idx, lock_idx, 1);
        }

        // Perform reduction in workspace
        BlockStripedReduceT::reduce(reduction_workspace_array, *accumulator_array, barrier_group_thread_idx);
      }

      // Signal our arrival
      BarrierManager::arrive_inc(barrier_idx, lock_workspace, barrier_group_thread_idx, lock_idx, work_tile_info.k_tile_count);
    }
    else {
      // Wait until the preceding split added its accumulators.
      // For both the deterministic and non-deterministic case, each preceding split will have incremented
      // the locked value by work_tile_info.k_tile_count. Thus, the final split konws that it can begin
      // loading the partially-reduced value when the locked value reaches its starting K tile index (i.e.,
      // work_tile_info.K_idx).
      BarrierManager::wait_eq(barrier_idx, lock_workspace, barrier_group_thread_idx, lock_idx, work_tile_info.K_idx);

      // The block computing the final split for the tile adds previously-reduced partials
      // to its accumulators and computes the epilogue.
      BlockStripedReduceT::load_add(*accumulator_array, reduction_workspace_array, barrier_group_thread_idx);
    }
  }

  // Returns whether the block assigned this work should compute the epilogue for the corresponding
  // output tile. For the case of stream-K, this should only occur if the work is marked as the final split.
  CUTLASS_HOST_DEVICE
  static bool
  compute_epilogue(WorkTileInfo const& work_tile_info, Params const& params) {
    return work_tile_info.is_final_split(params.divmod_tiles_per_output_tile_.divisor);
  }

  // Returns the linearized index of the output tile corresponding to the tile with offset [L, M, K]
  CUTLASS_DEVICE
  static int
  output_tile_index(Params const& params, WorkTileInfo const& work_tile_info) {
    uint64_t linear_idx_in_batch = UnderlyingScheduler::get_linear_idx_from_m_and_n(
      work_tile_info.M_idx, work_tile_info.N_idx,
      params.divmod_cluster_shape_major_,
      params.divmod_cluster_shape_minor_,
      params.divmod_cluster_blk_major_,
      params.log_swizzle_size_,
      params.raster_order_
    );

    uint64_t tiles_mn = params.divmod_batch_.divisor;
    return tiles_mn * work_tile_info.L_idx + linear_idx_in_batch;
  }

  template <class ProblemShape, class ElementAccumulator>
  static int
  get_workspace_size(
    Arguments const& args,
    ProblemShape problem_shape,
    KernelHardwareInfo const& hw_info,
    uint32_t mma_warp_groups) {

    auto problem_shape_mnkl = cute::append<4>(problem_shape, 1);

    ClusterShape cluster_shape;
    TileShape tile_shape;

    dim3 problem_blocks = get_tiled_cta_shape_mnl(problem_shape_mnkl, tile_shape, cluster_shape);
    uint32_t k_tile_per_output_tile = cute::size(cute::ceil_div(cute::shape<2>(problem_shape_mnkl), cute::shape<2>(TileShape{})));

    return Params::get_workspace_size(
      problem_blocks,
      k_tile_per_output_tile,
      to_gemm_coord(tile_shape),
      to_gemm_coord(cluster_shape),
      hw_info,
      args.splits,
      args.max_swizzle_size,
      args.raster_order,
      mma_warp_groups,
      sizeof_bits<BarrierType>::value,
      sizeof_bits<ElementAccumulator>::value
    );
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

    auto problem_shape_mnkl = cute::append<4>(problem_shape, 1);

    ClusterShape cluster_shape;
    TileShape tile_shape;

    dim3 problem_blocks = get_tiled_cta_shape_mnl(problem_shape_mnkl, tile_shape, cluster_shape);
    uint32_t k_tile_per_output_tile = cute::size(cute::ceil_div(cute::shape<2>(problem_shape_mnkl), cute::shape<2>(TileShape{})));

    return Params::initialize_workspace(
      workspace,
      stream,
      problem_blocks,
      k_tile_per_output_tile,
      to_gemm_coord(tile_shape),
      to_gemm_coord(cluster_shape),
      hw_info,
      args.splits,
      args.max_swizzle_size,
      args.raster_order,
      mma_warp_groups,
      sizeof_bits<BarrierType>::value,
      sizeof_bits<ElementAccumulator>::value
    );
  }

  template <class ProblemShape>
  CUTLASS_HOST_DEVICE
  static int
  get_work_k_tile_count(WorkTileInfo const& work_tile_info, ProblemShape, TileShape) {
    return work_tile_info.k_tile_count;
  }

  CUTLASS_HOST_DEVICE
  static uint32_t
  get_work_k_tile_start(WorkTileInfo const& work_tile_info) {
    return work_tile_info.K_idx;
  }

  // Sets the current stream-K work to compute within work_tile_info. If new_unit is true, work_tile_info
  // is populated as a new unit of work. Otherwise, state existing in work_tile_info (e.g., remaining
  // iterations) is used to find the next tile in the current work unit.
  CUTLASS_DEVICE
  static void
  assign_work(
    Params const& params,
    uint64_t linear_idx,
    WorkTileInfo& work_tile_info) {

    uint64_t true_tile_id = linear_idx;
    if (linear_idx >= params.sk_units_ && params.splits_ == 1) {
      // Data-parallel work
      true_tile_id = linear_idx - params.sk_units_ + params.sk_tiles_;
      work_tile_info.K_idx = 0;
      work_tile_info.k_tile_count = params.divmod_tiles_per_output_tile_.divisor;
      work_tile_info.k_tile_remaining = params.divmod_tiles_per_output_tile_.divisor;
    }
    else {
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

      // Equivalent to linear_idx / cluster_size
      auto cluster_linear_work_idx = params.divmod_cluster_shape_minor_.divide(
        params.divmod_cluster_shape_major_.divide(linear_idx)
      );

      uint64_t split;
      params.divmod_clusters_mnl_(split, cluster_linear_work_idx, cluster_linear_work_idx);
      auto big_unit_cmp = params.splits_ > 1 ? split : cluster_linear_work_idx;
      auto linear_idx_mult = params.splits_ > 1 ? params.divmod_tiles_per_output_tile_.divisor : params.k_tiles_per_sk_unit_;

      // Determine the starting k iteration computed by this stream-K work unit
      uint32_t unit_iter_start = (linear_idx_mult * cluster_linear_work_idx) + (params.k_tiles_per_sk_unit_ * split);

      // Adjust the starting position and number of k iterations for "big units," which
      // compute one extra iteration. These are the first big_units_ units in the
      // linearized ID space.
      bool is_big_unit = big_unit_cmp < params.big_units_;
      if (is_big_unit) {
        // Since the "big units" are the first units in the linearized ID space, each
        // of the units preceding this big unit computed one extra iteration. Thus,
        // we must offset our start iteration by the number of units that precede
        // the current unit in the linearized ID space.
        unit_iter_start += big_unit_cmp;
      }
      else {
        // Increment by one for each of the big clusters (since all big units precede this unit)
        unit_iter_start += params.big_units_;
      }

      if (work_tile_info.k_tile_count == 0) {
        // This is a new unit
        work_tile_info.k_tile_remaining = params.k_tiles_per_sk_unit_;

        // Only adjust iteration count for big unit if we are initializing this
        // work unit. For existing work units, the extra iteration for big units
        // has already been accounted for in k_tiles_reamaining
        if (is_big_unit) {
          ++work_tile_info.k_tile_remaining;
        }
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
      uint32_t unit_iter_end = unit_iter_start + work_tile_info.k_tile_remaining - 1;

      true_tile_id = params.divmod_tiles_per_output_tile_.divide(unit_iter_end);
      uint32_t true_tile_iter_start = true_tile_id * params.divmod_tiles_per_output_tile_.divisor;
      uint32_t true_tile_iter_end = true_tile_iter_start + params.divmod_tiles_per_output_tile_.divisor;

      // Bring the linearized tile ID back into the space of tiles, rather than clusters
      true_tile_id *= params.divmod_cluster_shape_major_.divisor * params.divmod_cluster_shape_minor_.divisor;

      auto [cta_m_in_cluster, cta_n_in_cluster, _] = cute::block_id_in_cluster();

      // The final linearized tile ID is in units of the cluster dimension over which we rasterize.
      if (params.raster_order_ == RasterOrder::AlongN) {
        true_tile_id += cta_n_in_cluster * params.divmod_cluster_shape_minor_.divisor;
      }
      else {
        true_tile_id += cta_m_in_cluster * params.divmod_cluster_shape_minor_.divisor;
      }

      // The unit's starting k iteration in the current tile is either the starting
      // iteration for the tile as a whole, or the starting k iteration for the unit
      // as a whole (if the latter is greater than the former).
      uint32_t tile_iter_start = max(true_tile_iter_start, unit_iter_start);

      // Similarly, the unit's ending k iteration (exclusive) is either the end of
      // the current tile it is assigned, or the ending iteration of the unit as a whole
      // (if the latter is less than the former).
      uint32_t tile_iter_end = min(true_tile_iter_end, unit_iter_end + 1);

      // Set the k offset to be the starting k tile for this output tile
      work_tile_info.K_idx = static_cast<int32_t>(tile_iter_start - true_tile_iter_start);

      work_tile_info.k_tile_count = tile_iter_end - tile_iter_start;
    }

    uint64_t work_idx_l, remainder;
    params.divmod_batch_(work_idx_l, remainder, true_tile_id);

    uint64_t cta_per_grid_dim = params.divmod_cluster_shape_minor_.divide(remainder);

    auto [work_idx_m, work_idx_n] = UnderlyingScheduler::get_work_idx_m_and_n(
                                          cta_per_grid_dim,
                                          params.divmod_cluster_shape_major_,
                                          params.divmod_cluster_shape_minor_,
                                          params.divmod_cluster_blk_major_,
                                          params.log_swizzle_size_,
                                          params.raster_order_);

    // Set the M, N, and L block offsets
    work_tile_info.M_idx = work_idx_m;
    work_tile_info.N_idx = work_idx_n;
    work_tile_info.L_idx = static_cast<int32_t>(work_idx_l);

  }
};

} // namespace cutlass::gemm::kernel::detail
