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

#include "cutlass/barrier.h"
#include "cutlass/block_striped.h"
#include "cutlass/fast_math.h"
#include "cutlass/gemm/kernel/sm90_tile_scheduler.hpp"
#include "cutlass/kernel_hardware_info.hpp"
#include "cute/layout.hpp"
#include "cute/tensor.hpp"
#include "cutlass/gemm/kernel/xe_persistent_tile_scheduler_params_streamk.hpp"

namespace cutlass::gemm::kernel::detail {

// Persistent Thread Block (TB) scheduler leveraging stream-K decomposition
template <
  class TileShape
>
class PersistentTileSchedulerXeStreamK {
  //
  // Data members
  //

private:
  uint64_t current_work_linear_idx_ = 0;

public:

  // Use a dummy barrier manager to simply get the type used to store the barrier
  using BarrierType = typename NamedBarrierManager<1>::T;

  using Params = PersistentTileSchedulerXeStreamKParams;
  using ReductionMode = Params::ReductionMode;
  using DecompositionMode = Params::DecompositionMode;
  using RasterOrder = Params::RasterOrder;
  using RasterOrderOptions = Params::RasterOrderOptions;

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
      // A work tile that computes no K tiles is invalid
      return k_tile_count > 0;
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
      reduction_mode = args.reduction_mode;
      decomposition_mode = args.decomposition_mode;
      return *this;
    }

    CUTLASS_HOST_DEVICE
    Arguments&
    operator=(Arguments&& args) noexcept {
      splits = args.splits;
      reduction_mode = args.reduction_mode;
      decomposition_mode = args.decomposition_mode;
      return *this;
    }

    CUTLASS_HOST_DEVICE
    Arguments(int splits_) : splits(splits_) {}

    CUTLASS_HOST_DEVICE
    Arguments(int splits_, DecompositionMode decomposition_mode_) :
      splits(splits_),
      decomposition_mode(decomposition_mode_) {}

    // The splitting factor to be used in a split-K decomposition of the problem.
    // If this is set to a value greater than 1, stream-K decomposition logic
    // is bypassed in favor of a split-K decomposition.
    int splits = 1;
    RasterOrderOptions raster_order = RasterOrderOptions::Heuristic;
    ReductionMode reduction_mode = ReductionMode::Deterministic;
    DecompositionMode decomposition_mode = DecompositionMode::Heuristic;
  };

  // Sink scheduler params as a member
  Params scheduler_params;

  //
  // Methods
  //

  template <class ProblemShape, class ClusterShape>
  static Params
  to_underlying_arguments(
    ProblemShape problem_shape,
    TileShape tile_shape,
    [[maybe_unused]] ClusterShape cluster_shape,
    KernelHardwareInfo const& hw_info,
    Arguments const& args,
    void* workspace,
    [[maybe_unused]] const uint32_t epilogue_subtile = 1,
    [[maybe_unused]] uint32_t ktile_start_alignment_count = 1u) {

    static_assert(cute::is_static<TileShape>::value);

    auto problem_shape_mnkl = cute::append<4>(problem_shape, cute::Int<1>{});
    dim3 problem_blocks = get_tiled_wg_shape_mnl(problem_shape_mnkl, tile_shape);
    uint32_t k_tile_per_output_tile = cute::size(cute::ceil_div(cute::shape<2>(problem_shape_mnkl), cute::shape<2>(TileShape{})));

    Params params;
    params.initialize(
      problem_blocks,
      k_tile_per_output_tile,
      hw_info,
      args.splits,
      args.reduction_mode,
      args.decomposition_mode,
      workspace
    );
    return params;
  }

  static bool
  can_implement(Arguments const& args) {
    // Split count > 1 is only valid for heuristic and split-K decomposition modes
    return (args.splits == 1 ||
            args.decomposition_mode == DecompositionMode::Heuristic ||
            args.decomposition_mode == DecompositionMode::SplitK);
  }

  CUTLASS_HOST_DEVICE
  PersistentTileSchedulerXeStreamK() { };

  CUTLASS_HOST_DEVICE
  PersistentTileSchedulerXeStreamK(Params const& params_) : scheduler_params(params_) {
    current_work_linear_idx_ = uint64_t(BlockIdxX());
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
    if(linear_idx >= (params.units_per_problem_ * params.divmod_splits_.divisor)) {
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

  CUTLASS_DEVICE
  static bool
  continue_current_work_for_linear_idx(
    uint64_t linear_idx,
    WorkTileInfo& work_tile_info,
    Params const& params) {

    work_tile_info.k_tile_remaining -= work_tile_info.k_tile_count;

    if (work_tile_info.k_tile_remaining == 0) {
      return false;
    }
    assign_work(params, linear_idx, work_tile_info);
    return work_tile_info.is_valid();
  }

  CUTLASS_DEVICE
  void
  advance_to_next_work(uint32_t advance_count = 1) {
    current_work_linear_idx_ += uint64_t(GridDimX()) * uint64_t(GridDimY()) * uint64_t(GridDimZ()) * uint64_t(advance_count);
  }

  // Given the inputs, computes the total number of output work-groups this problem will compute over.
  template <class ProblemShape>
  CUTLASS_HOST_DEVICE static
  dim3
  get_tiled_wg_shape_mnl(ProblemShape problem_shape_mnkl, TileShape cta_shape) {
    return Params::get_tiled_wg_shape_mnl(to_gemm_coord(problem_shape_mnkl), to_gemm_coord(cta_shape));
  }

  // Computes the physical grid we should launch.
  template <class ProblemShape, class ClusterShape>
  CUTLASS_HOST_DEVICE static
  dim3
  get_grid_shape(
    [[maybe_unused]] Params const& params,
    ProblemShape problem_shape,
    TileShape tile_shape,
    [[maybe_unused]] ClusterShape cluster_shape,
    KernelHardwareInfo hw_info,
    [[maybe_unused]] Arguments arguments = Arguments{},
    [[maybe_unused]] bool truncate_by_problem_size=true) {

    auto problem_shape_mnkl = cute::append<4>(problem_shape, cute::Int<1>{});
    dim3 problem_blocks = get_tiled_wg_shape_mnl(problem_shape_mnkl, tile_shape);

    return Params::get_grid_shape(
      problem_blocks,
      hw_info
    );
  }

  // Returns whether fixup is needed for `work_tile_info`.
  CUTLASS_HOST_DEVICE
  static bool
  requires_fixup(Params const& params, WorkTileInfo const& work_tile_info) {
    // Fixup is not needed for invalid or data-parallel tiles
    return work_tile_info.is_valid() && work_tile_info.k_tile_count != params.divmod_tiles_per_output_tile_.divisor;
  }

  // Performs the reduction across splits for a given output tile.
template <int ThreadsPerBlock, class FrgTensorC>
  CUTLASS_DEVICE
  static void
  fixup(
    Params const& params,
    WorkTileInfo const& work_tile_info,
    FrgTensorC& accumulators,
    uint32_t num_barriers = 1,
    uint32_t barrier_idx = 0) {
    static constexpr uint32_t Offset = static_cast<int>(cutlass::arch::ReservedNamedBarriers::StreamkBarrier0);
    static constexpr uint32_t MaxNumNamedBarriers = 1;
    using BarrierManager = NamedBarrierManager<ThreadsPerBlock, Offset, MaxNumNamedBarriers>;
    return fixup_helper<ThreadsPerBlock, FrgTensorC, BarrierManager>(
      params, work_tile_info, accumulators, num_barriers, barrier_idx);
  }

  // Helper for performing the reduction across splits for a given output tile.
  template <int ThreadsPerBlock, class FrgTensorC, class BarrierManager>
  CUTLASS_DEVICE
  static void
  fixup_helper(
    Params const& params,
    WorkTileInfo const& work_tile_info,
    FrgTensorC& accumulators,
    uint32_t num_barriers,
    uint32_t barrier_idx,
    uint32_t num_accumulator_mtxs = 1) {

    using ElementAccumulator = typename FrgTensorC::value_type;

    if (!requires_fixup(params, work_tile_info)) {
      return;
    }
    auto tile_idx = output_tile_index(params, work_tile_info);

    // Index of the lock on which to wait
    auto lock_idx = (tile_idx * num_barriers) + barrier_idx;

    auto reduction_tile_idx = tile_idx;
    auto reduction_peer_offset = 0;
    int barrier_group_thread_idx = ThreadIdxX();

    // Reductions use BlockStripedReduce with a width of BarrierManager::ThreadCount under the hood.
    // Thus, the start of the reduction space is the same across all threads in a work group.
    int reduction_offset =
      (cute::size<0>(TileShape{}) * cute::size<1>(TileShape{}) * reduction_tile_idx * num_accumulator_mtxs) +
      reduction_peer_offset;

    ElementAccumulator* group_reduction_workspace = reinterpret_cast<ElementAccumulator*>(params.reduction_workspace_) + reduction_offset;

    using AccumulatorArrayT = Array<typename FrgTensorC::value_type, size(FrgTensorC{})>;
    using BlockStripedReduceT = BlockStripedReduce<ThreadsPerBlock, AccumulatorArrayT>;

    AccumulatorArrayT* reduction_workspace_array = reinterpret_cast<AccumulatorArrayT*>(group_reduction_workspace);
    AccumulatorArrayT* accumulator_array = reinterpret_cast<AccumulatorArrayT*>(accumulators.data());

    // The number of tiles for which reduction is required is either:
    //   (a) the total number of output tiles (in the case of split-K)
    //   (b) the number of stream-K tiles
    // To calculate the total number of output tiles in the split-K case, we
    // note that, in the split-K case, the units_per_problem_ member of Params will be
    // the total number of output tiles.
    uint32_t reduction_tiles = 0;
    if (params.divmod_splits_.divisor > 1) {
      reduction_tiles = params.units_per_problem_;
    }
    else {
      reduction_tiles = params.sk_tiles_;
    }

    auto reduction_workspace_size = Params::get_reduction_workspace_size(
      reduction_tiles, to_gemm_coord(TileShape{}), sizeof_bits<ElementAccumulator>::value, num_accumulator_mtxs);
    BarrierType* lock_workspace = reinterpret_cast<BarrierType*>(
      reinterpret_cast<uint8_t*>(params.reduction_workspace_) + reduction_workspace_size);

    if (!compute_epilogue(work_tile_info, params)) {
      if (work_tile_info.K_idx == 0) {
        // The first peer initializes the workspace partials
        BlockStripedReduceT::store(reduction_workspace_array, *accumulator_array, barrier_group_thread_idx);
      }
      else {
        // Wait until the preceding split added its accumulators
        BarrierManager::wait_eq(barrier_idx, lock_workspace, barrier_group_thread_idx, lock_idx, work_tile_info.K_idx);

        // Perform reduction in workspace
        BlockStripedReduceT::reduce(reduction_workspace_array, *accumulator_array, barrier_group_thread_idx);
      }

      // Each participating stream-K unit increments the barrier by the K tile count that this unit has
      // processed.
      int32_t increment = work_tile_info.k_tile_count;

      // Signal our arrival
      BarrierManager::arrive_inc(barrier_idx, lock_workspace, barrier_group_thread_idx, lock_idx, increment);
    }
    else {
      if (params.reduction_mode_ == ReductionMode::Deterministic) {
        // Wait until the preceding split added its accumulators
        BarrierManager::wait_eq(barrier_idx, lock_workspace, barrier_group_thread_idx, lock_idx, work_tile_info.K_idx);
      }
      else {
        // Wait until the first split has stored its accumulators
        BarrierManager::wait_lt(barrier_idx, lock_workspace, barrier_group_thread_idx, lock_idx, 1);
      }

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
    // `is_final_split` will be set to `true` for the following scenarios, all of which must compute the epilogue:
    //  1. The tile is computed in data-parallel mode
    //  2. The tile is computed in split-/stream-K mode and this work unit represents the final split of the tile
    return work_tile_info.is_valid() &&
            work_tile_info.is_final_split(params.divmod_tiles_per_output_tile_.divisor);
  }

  // Returns the linearized index of the output tile corresponding to the tile with offset [L, M, K]
  CUTLASS_DEVICE
  static int
  output_tile_index(Params const& params, WorkTileInfo const& work_tile_info) {
    uint64_t linear_idx_in_batch = Params::get_linear_idx_from_m_and_n(
      work_tile_info.M_idx, work_tile_info.N_idx,
      params.divmod_blk_major_
    );

    uint64_t tiles_mn = params.divmod_batch_.divisor;
    return tiles_mn * work_tile_info.L_idx + linear_idx_in_batch;
  }

  template <class ProblemShape, class ElementAccumulator>
  static size_t
  get_workspace_size(
    Arguments const& args,
    ProblemShape problem_shape,
    KernelHardwareInfo const& hw_info,
    [[maybe_unused]] uint32_t mma_warp_groups = 1,
    [[maybe_unused]] const uint32_t epilogue_subtile = 1,
    [[maybe_unused]] uint32_t num_accumulator_mtxs = 1) {

    auto problem_shape_mnkl = cute::append<4>(problem_shape, 1);

    TileShape tile_shape;

    dim3 problem_blocks = get_tiled_wg_shape_mnl(problem_shape_mnkl, tile_shape);
    uint32_t k_tile_per_output_tile = cute::size(cute::ceil_div(cute::shape<2>(problem_shape_mnkl), cute::shape<2>(TileShape{})));

    return Params::get_workspace_size(
      problem_blocks,
      k_tile_per_output_tile,
      to_gemm_coord(tile_shape),
      hw_info,
      args.splits,
      args.decomposition_mode,
      sizeof_bits<BarrierType>::value,
      sizeof_bits<ElementAccumulator>::value
    );
  }

  template <class ProblemShape, class ElementAccumulator>
  static cutlass::Status
  initialize_workspace(
    Arguments const& args,
    void* workspace,
    [[maybe_unused]] cudaStream_t stream,
    ProblemShape const& problem_shape,
    KernelHardwareInfo const& hw_info,
    [[maybe_unused]] uint32_t mma_warp_groups = 1,
    [[maybe_unused]] const uint32_t epilogue_subtile = 1,
    [[maybe_unused]] uint32_t num_accumulator_mtxs = 1,
    [[maybe_unused]] CudaHostAdapter* cuda_adapter = nullptr) {

    auto problem_shape_mnkl = cute::append<4>(problem_shape, 1);

    TileShape tile_shape;

    dim3 problem_blocks = get_tiled_wg_shape_mnl(problem_shape_mnkl, tile_shape);
    uint32_t k_tile_per_output_tile = cute::size(cute::ceil_div(cute::shape<2>(problem_shape_mnkl), cute::shape<2>(TileShape{})));

    return Params::initialize_workspace(
      workspace,
      problem_blocks,
      k_tile_per_output_tile,
      to_gemm_coord(tile_shape),
      hw_info,
      args.splits,
      args.decomposition_mode,
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

  // Kernel helper function to get next work tile
  CUTLASS_DEVICE
  auto
  fetch_next_work(WorkTileInfo work_tile_info) {
    if (continue_current_work(work_tile_info)) {
      return cute::make_tuple(work_tile_info, true);
    }

    advance_to_next_work();
    return cute::make_tuple(get_current_work(), true);
  }

  // Returns the initial work tile info that will be computed over
  template <class ClusterShape>
  CUTLASS_DEVICE
  WorkTileInfo
  initial_work_tile_info(ClusterShape cluster_shape) {
    return get_current_work();
  }

private:
  // Sets the current stream-K work to compute within work_tile_info. If new_unit is true, work_tile_info
  // is populated as a new unit of work. Otherwise, state existing in work_tile_info (e.g., remaining
  // iterations) is used to find the next tile in the current work unit.
CUTLASS_DEVICE
  static void
  assign_work(
    Params const& params,
    uint64_t linear_idx,
    WorkTileInfo& work_tile_info) {

    uint64_t output_tile_id = linear_idx;
    if (linear_idx >= params.sk_units_ && params.divmod_splits_.divisor == 1) {
      // Data-parallel work
      output_tile_id = linear_idx - params.sk_units_ + params.sk_tiles_;
      work_tile_info.K_idx = 0;
      work_tile_info.k_tile_count = params.divmod_tiles_per_output_tile_.divisor;
      work_tile_info.k_tile_remaining = params.divmod_tiles_per_output_tile_.divisor;
    }
    else {

      // Determine whether we are in a "big unit" within the group, that will process
      // an additional K chunk in the group.
      auto sk_tiles_in_group = params.sk_tiles_;
      auto k_tiles_in_group = sk_tiles_in_group * params.divmod_tiles_per_output_tile_.divisor;
      auto k_tiles_per_unit_in_group = params.divmod_sk_units_per_group_.divide(k_tiles_in_group);
      auto big_units_in_group = k_tiles_in_group - (k_tiles_per_unit_in_group * params.divmod_sk_units_per_group_.divisor);

      uint64_t split;
      params.divmod_sk_units_per_group_(split, output_tile_id, output_tile_id);

      bool is_split_k = params.divmod_splits_.divisor > 1;
      auto big_unit_cmp_lhs = is_split_k ? split : output_tile_id;
      auto big_unit_cmp_rhs = is_split_k ? params.big_units_ : big_units_in_group;
      auto linear_idx_mult = is_split_k ? params.divmod_tiles_per_output_tile_.divisor : k_tiles_per_unit_in_group;
      auto k_tiles_per_split = is_split_k ? params.divmod_k_tiles_per_sk_unit_.divisor : k_tiles_per_unit_in_group;

      // Determine the starting k iteration computed by this stream-K work unit
      uint32_t unit_iter_start = (linear_idx_mult * linear_idx) + (k_tiles_per_split * split);

      // Adjust the starting position and number of k iterations for "big units," which
      // compute one extra iteration. If there are any big units, they will be the first
      // in the linearized ID space.
      auto k_tiles_in_my_split = k_tiles_per_split;
      if (big_unit_cmp_lhs < big_unit_cmp_rhs) {
        // Since the "big units" are the first units in the linearized ID space, each
        // of the units preceding this big unit computed one extra iteration. Thus,
        // we must offset our start iteration by the number of units that precede
        // the current unit in the linearized ID space.
        unit_iter_start += big_unit_cmp_lhs;
        ++k_tiles_in_my_split;
      }
      else {
        // Increment by one for each of the big clusters (since all big units precede this unit)
        unit_iter_start += big_unit_cmp_rhs;
      }

      if (!is_split_k) {
        // Adjust the unit starting position and number of tiles to avoid
        // computing splits of size less than min_iters_per_sk_unit_
        int unused, start_tile_k_tile;
        params.divmod_tiles_per_output_tile_(unused, start_tile_k_tile, unit_iter_start);
        if (start_tile_k_tile < Params::min_iters_per_sk_unit_) {
          // Starting K tile is in range [0, Params::min_iters_per_sk_unit_), which means that another
          // stream-K unit will be computing a split with fewer than Params::min_iters_per_sk_unit_ K tiles.
          // Adjust our work to take over these K tiles.
          unit_iter_start -= start_tile_k_tile;
          k_tiles_in_my_split += start_tile_k_tile;
        }
        else if (start_tile_k_tile > (params.divmod_tiles_per_output_tile_.divisor - Params::min_iters_per_sk_unit_)) {
          // Starting K tile is within the final Params::min_iters_per_sk_unit_ K tiles of some output tile,
          // which means that this unit will compute a split with fewer than Params::min_iters_per_sk_unit_ K tiles.
          // Adjust our work to shed these K tiles to a neighboring stream-K unit that will compute more consecutive K tiles.
          auto adjustment_tiles = (params.divmod_tiles_per_output_tile_.divisor - start_tile_k_tile);
          unit_iter_start += adjustment_tiles;
          k_tiles_in_my_split -= adjustment_tiles;
        }
        else if (params.ktile_start_alignment_count == 2 && start_tile_k_tile % 2 != 0) {
          // ktile for each SM start from even number
          // If start from odd number ktile within the output tile
          //    now start at the ktile one before my initial ktile start (take one ktile from prev sm)
          // if end on odd number ktile within the output tile
          //    now end at ktile that one before my ktile end (give one ktile to next sm)
          unit_iter_start -= 1;
          k_tiles_in_my_split += 1;
        }
      }

      if (work_tile_info.k_tile_count == 0) {
        // This is a new unit

        if (!is_split_k) {
          //
          // Adjust the unit ending position and number of tiles to avoid
          // computing splits of size less than min_iters_per_sk_unit_
          //

          // Begin by assuming that no adjustment is needed
          auto initial_unit_iter_end = unit_iter_start + k_tiles_in_my_split;

          int unused, end_tile_k_tile;
          params.divmod_tiles_per_output_tile_(unused, end_tile_k_tile, initial_unit_iter_end);

          if (end_tile_k_tile < Params::min_iters_per_sk_unit_) {
            // Ending K tile is within the first Params::min_iters_per_sk_unit_ K tiles of some output tile,
            // which means that this unit will compute a split with fewer than Params::min_iters_per_sk_unit_ K tiles.
            // Adjust our work to shed these K tiles to a neighboring stream-K unit that will compute more consecutive K tiles.
            k_tiles_in_my_split -= end_tile_k_tile;
          }
          else if (end_tile_k_tile > (params.divmod_tiles_per_output_tile_.divisor - Params::min_iters_per_sk_unit_)) {
            // Ending K tile is within the final Params::min_iters_per_sk_unit_ K tiles of some output tile,
            // which means that some other unit will compute a split with fewer than Params::min_iters_per_sk_unit_ K tiles.
            // Adjust our work to take on these K tiles.
            k_tiles_in_my_split += (params.divmod_tiles_per_output_tile_.divisor - end_tile_k_tile);
          }
          else if (params.ktile_start_alignment_count == 2 && end_tile_k_tile % 2 != 0) {
            // ktile for each SM start from even number
            // If start from odd number ktile within the output tile
            //    now start at the ktile one before my initial ktile start (take one ktile from prev sm)
            // If end on odd number ktile within the output tile,
            //    now end at ktile that one before my ktile end (give one ktile to next sm)
            k_tiles_in_my_split -= 1;
          }
        }

        work_tile_info.k_tile_remaining = k_tiles_in_my_split;
      }

      uint32_t unit_iter_end = unit_iter_start + work_tile_info.k_tile_remaining - 1;

      // Find the output tile corresponding to the final k tile covered by this
      // work unit. Stream-K work units will work backwards in terms of the tiles they
      // are responsible computing. This is beneficial because the final (partial)
      // tile computed by a stream-K block is typically the beginning of the output
      // tile, while the beginning (partial) tile is typically the ending of another
      // output tile. Since ending portions of an output tile must reduce across
      // other work units computing portions of that output tile, it is preferable
      // for them to be computed later, so as to reduce the likelihood of blocking
      // on other work.

      auto output_tile_id_in_group = params.divmod_tiles_per_output_tile_.divide(unit_iter_end);
      uint32_t output_tile_iter_start = output_tile_id_in_group * params.divmod_tiles_per_output_tile_.divisor;
      uint32_t output_tile_iter_end = output_tile_iter_start + params.divmod_tiles_per_output_tile_.divisor;

      // Convert the output tile from the linearized space within each group to the
      // overall linearized space.
      output_tile_id = output_tile_id_in_group * params.divmod_sk_groups_.divisor;

      // The unit's starting k iteration in the current tile is either the starting
      // iteration for the tile as a whole, or the starting k iteration for the unit
      // as a whole (if the latter is greater than the former).
      uint32_t tile_iter_start = max(output_tile_iter_start, unit_iter_start);

      // Similarly, the unit's ending k iteration (exclusive) is either the end of
      // the current tile it is assigned, or the ending iteration of the unit as a whole
      // (if the latter is less than the former).
      uint32_t tile_iter_end = min(output_tile_iter_end, unit_iter_end + 1);

      // Set the k offset to be the starting k tile for this output tile
      work_tile_info.K_idx = static_cast<int32_t>(tile_iter_start - output_tile_iter_start);
      work_tile_info.k_tile_count = tile_iter_end - tile_iter_start;
    }

    uint64_t work_idx_l, remainder;

    if(params.divmod_splits_.divisor > 1) {
      output_tile_id %= params.units_per_problem_;
    }

    params.divmod_batch_(work_idx_l, remainder, output_tile_id);

    uint64_t cta_per_grid_dim = remainder;

    auto [work_idx_m, work_idx_n] = Params::get_work_idx_m_and_n(
                                          cta_per_grid_dim,
                                          params.divmod_blk_major_
                                        );

    // Set the M, N, and L block offsets
    work_tile_info.M_idx = work_idx_m;
    work_tile_info.N_idx = work_idx_n;
    work_tile_info.L_idx = work_idx_l;
  }

};

} // namespace cutlass::gemm::kernel::detail
