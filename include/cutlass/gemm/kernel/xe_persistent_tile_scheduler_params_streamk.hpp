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

/*! \file
    \brief Parameters structures for persistent tile schedulers
*/

#include "cutlass/coord.h"
#include "cutlass/kernel_hardware_info.h"
#include "cutlass/workspace.h"
#include "cutlass/platform/platform.h"
#include "cutlass/fast_math.h"
#include "cutlass/gemm_coord.h"
////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace gemm {
namespace kernel {
namespace detail {

////////////////////////////////////////////////////////////////////////////////
// Parameters for Xe persistent stream-K scheduler
struct PersistentTileSchedulerXeStreamKParams {

  // Strategies for computing reductions between work-groups computing portions of a given output tile
  enum class ReductionMode {
    // Participating work-groups perform reduction in a turnstile fashion in order of the K extent
    // covered by each work-group. This requires a lock to be held exclusively be the work-group that is
    // currently accumulating.
    //
    // Turnstile accumulation ensures deterministic numeric behavior when using this mode.
    Deterministic,

    // Participating work-groups perform reduction atomically to the same workspace (mostly) without locking.
    // Locks are used only to wait for the first work-group to write its partial values (to initialize the
    // workspace), and for all but the final work-group to have accumulated (so that the final work-group can load
    // the accumulated value and accumulate it into registers on top of which the epilogue will
    // be performed).
    //
    // Due to the nondeterminsitic ordering of accumulation, deterministic numeric behavior cannot
    // be guaranteed with this mode (e.g., floating-point rounding error will depend on the order
    // of accumulation)
    Nondeterministic
  };

  // Strategies for decomposing the problem
  enum class DecompositionMode {
    // Use a heuristic to determine whether data-parallel, split-K, or stream-K decomposition should be performed
    Heuristic,
    // Force a data-parallel decomposition
    DataParallel,
    // Force a split-K decomposition. This should be paired with setting the `splits` parameter
    SplitK,
    // Force a stream-K decomposition
    StreamK
  };

  using UnderlyingParams = PersistentTileSchedulerSm90Params;
  using RasterOrder = UnderlyingParams::RasterOrder;
  using RasterOrderOptions = UnderlyingParams::RasterOrderOptions;

  FastDivmodU64 divmod_batch_{};
  FastDivmodU64 divmod_blk_major_{};

  // Divide up the number of stream-K tiles amongst G groups of stream-K units.
  // Currently defaults to 1 since we don't create groups for Xe.
  FastDivmodU64 divmod_sk_groups_{};

  // Number of stream-K units in each group
  FastDivmodU64 divmod_sk_units_per_group_{};

  uint64_t units_per_problem_ = 0;
  FastDivmod divmod_tiles_per_output_tile_{};
  RasterOrder raster_order_ = RasterOrder::AlongN;

  // The splitting factor to be used in a split-K decomposition of the problem.
  // If this is set to a value greater than 1, stream-K decomposition logic
  // is bypassed in favor of a split-K decomposition.
  FastDivmod divmod_splits_{};

  // Number of stream-K or split-K work units that compute an extra k iteration.
  // This is done to handle residuals in dividing up the k iteration space.
  uint32_t big_units_ = 0;

  // The number of groups of stream-K units that will process an extra stream-K tile.
  uint32_t big_groups_ = 0;

  // Workspace for holding partial accumulators to be reduced across stream-K/split-K units
  void* reduction_workspace_ = nullptr;

  // Number of tiles covered by stream-K work units
  uint32_t sk_tiles_ = 0;

  // Number of work units computing stream-K tiles
  uint32_t sk_units_ = 0;

  // Number of tiled k iterations computed by each stream-K work unit. This
  // can potentially cover more than one output tile.
  FastDivmod divmod_k_tiles_per_sk_unit_{};
  // Number of tiled k iterations computed by each "big" stream-K units, which
  // processes one more K chunk than a "normal" stream-K unit.
  FastDivmod divmod_k_tiles_per_sk_big_unit_{};

  // Strategy to use when reducing between collaborating work-groups
  ReductionMode reduction_mode_ = ReductionMode::Deterministic;

  // Minimum number of k tiles that can be assigned to a stream-K unit
  static constexpr uint32_t min_iters_per_sk_unit_ = 8u;

  // Maximum number of groups of stream-K units
  static constexpr uint32_t max_sk_groups_ = 1u;

  // ktile start from even for each cta
  uint32_t ktile_start_alignment_count { 1u };

  // Initializes members. This variant of the method should only be used when
  // problem_shape and tile_shape contain modes of only rank 1.
  void
  initialize(
    BatchedGemmCoord problem_shape,
    GemmCoord tile_shape,
    KernelHardwareInfo hw_info,
    int splits,
    ReductionMode reduction_mode,
    DecompositionMode decomposition_mode,
    void* workspace
  ) {

    dim3 problem_blocks = get_tiled_wg_shape_mnl(problem_shape, tile_shape);
    // Number of k tiles in each output tile
    uint32_t k_tiles_per_output_tile = (problem_shape.k() + tile_shape.k() - 1) / tile_shape.k();

    initialize(
      problem_blocks,
      k_tiles_per_output_tile,
      hw_info,
      splits,
      reduction_mode,
      decomposition_mode,
      workspace
    );
  }

  // Version of initialize that takes in as input the number of work-groups in the M and N and L dimensions.
  // This is useful for calculating the tiled shape when a mode of problem and/or work-group shape has rank > 1,
  // for which using CuTe algebra for calculating tile shapes is easiest.
  void
  initialize(
    dim3 problem_blocks,
    uint32_t k_tiles_per_output_tile,
    KernelHardwareInfo hw_info,
    int splits,
    ReductionMode reduction_mode,
    DecompositionMode decomposition_mode,
    void* workspace
  ) {

    auto problem_blocks_l = problem_blocks.z;

    auto problem_blocks_m = problem_blocks.x;
    auto problem_blocks_n = problem_blocks.y;
    uint64_t output_tiles = problem_blocks_m * problem_blocks_n * problem_blocks_l;

    // Reduction workspace is at the beginning of the workspace. Lock workspace follows.
    void* reduction_workspace = workspace;

    if (decomposition_mode == DecompositionMode::SplitK ||
        (decomposition_mode == DecompositionMode::Heuristic && splits > 1)) {
      // Short circuit to basic split-K decomposition

      // Don't split by more than the available number of SMs
      if (splits > hw_info.sm_count) {
        splits = hw_info.sm_count;
      }

      // Don't split by more than the K tile iterations
      //
      // splits is almost certainly nonnegative here (e.g., hw_info.sm_count,
      // despite being an int, is a count), so it can safely be converted to unsigned
      // in the comparison to avoid a signed-unsigned comparison warning-as-error.
      if (static_cast<decltype(k_tiles_per_output_tile)>(splits) > k_tiles_per_output_tile) {
        splits = k_tiles_per_output_tile;
      }

      // If splits == k_tiles_per_output_tiles, there will be one k_tile per cta
      //   and this violate k_tile start from even requirements. Thus we need to
      //   reduce the number of splits.
      if (ktile_start_alignment_count > 1u &&
           static_cast<decltype(k_tiles_per_output_tile)>(splits) == k_tiles_per_output_tile) { 
        splits = k_tiles_per_output_tile / ktile_start_alignment_count;
      }

      set_params_basic(
        problem_blocks_m,
        problem_blocks_n,
        problem_blocks_l,
        splits,
        k_tiles_per_output_tile,
        reduction_workspace,
        reduction_mode
      );
      return;
    }

    // Calculate the maximum number of blocks that we can fit within sm_count SMs.
    dim3 grid = get_grid_shape(
      problem_blocks,
      hw_info
    );

    uint64_t wgs_per_wave = grid.x * grid.y;
    // The number of output tiles to be computed in stream-K and data-parallel fashion, respectively.
    uint32_t sk_tiles = get_num_sk_tiles(
      output_tiles,
      wgs_per_wave,
      k_tiles_per_output_tile,
      decomposition_mode
    );
    uint64_t dp_tiles = output_tiles - sk_tiles;

    // Calculate the number of work units covering the data-parallel and stream-K tiles.
    // A "work unit" is a single index in the linearized ID space used by the scheduler.
    // A work unit can encompass multiple output tiles worth of work (as will be the
    // case for stream-K blocks).
    // Since splitting is not required for data-parallel tiles, only one data-parallel unit
    // is needed per data-parallel tile.
    uint64_t dp_units = dp_tiles;

    uint64_t wgs_per_sk_wave = wgs_per_wave;
    uint64_t sk_units = get_num_sk_units(wgs_per_sk_wave, sk_tiles, k_tiles_per_output_tile);

    if (decomposition_mode == DecompositionMode::DataParallel ||
        (decomposition_mode == DecompositionMode::Heuristic && sk_tiles == 0) ||
        sk_units == 0) {
      // Short circuit to basic data-parallel decomposition
      set_params_basic(
        problem_blocks_m,
        problem_blocks_n,
        problem_blocks_l,
        /* splits = */ 1,
        k_tiles_per_output_tile,
        reduction_workspace,
        reduction_mode
      );
      return;
    }

    uint32_t groups = max_sk_groups_;

    auto sk_units_per_group = sk_units / groups;

    uint64_t sk_tiles_per_group = sk_tiles / groups;

    // Groups that will process an extra stream-K tile. These differ from "big_units," which
    // are stream-K units within a group that process an extra K chunk.
    uint64_t sk_big_groups = sk_tiles % groups;

    uint64_t k_tiles_per_group = k_tiles_per_output_tile * sk_tiles_per_group;

    // Number of k tiles computed per stream-K unit
    uint64_t k_tiles_per_sk_unit = k_tiles_per_group / sk_units_per_group;

    uint32_t reduction_units = 0;

    // Use separate reduction when we have less than one wave of output tiles (dp_tiles == 0)
    // and when each tile will be operated on by at least two stream-K units (sk_units > 2 * sk_tiles)
    if (decomposition_mode == DecompositionMode::Heuristic && sk_tiles < sk_units && sk_units % sk_tiles == 0) {
      // If the number of stream-K units is a multiple of the number of stream-K tiles, then
      // the problem can leverage a basic split-K decomposition for the stream-K tiles.
      // This case happens when separate reduction is disable.
      uint32_t sk_splits = static_cast<uint32_t>(sk_units / sk_tiles);
      set_params_basic(
        problem_blocks_m,
        problem_blocks_n,
        problem_blocks_l,
        sk_splits,
        k_tiles_per_output_tile,
        reduction_workspace,
        reduction_mode
      );
      return;
    }

    divmod_batch_ = FastDivmodU64(problem_blocks_m * problem_blocks_n);
    divmod_tiles_per_output_tile_ = FastDivmod(k_tiles_per_output_tile);
    divmod_sk_groups_ = FastDivmodU64(static_cast<uint64_t>(groups));
    divmod_sk_units_per_group_ = FastDivmodU64(static_cast<uint64_t>(sk_units / groups));

    divmod_blk_major_ = FastDivmodU64(problem_blocks_n);

    divmod_splits_ = FastDivmod(splits);
    units_per_problem_ = static_cast<uint32_t>(dp_units + sk_units);

    // Assign big_units_ assuming that group count == 1. This is unused by stream-K
    // when group count > 1.
    big_units_ = static_cast<uint32_t>(k_tiles_per_group % k_tiles_per_sk_unit);

    big_groups_ = static_cast<uint32_t>(sk_big_groups);
    reduction_workspace_ = reduction_workspace;
    sk_tiles_ = sk_tiles;
    sk_units_ = static_cast<uint32_t>(sk_units);
    divmod_k_tiles_per_sk_unit_ = FastDivmod(static_cast<uint32_t>(k_tiles_per_sk_unit));
    divmod_k_tiles_per_sk_big_unit_ = FastDivmod(static_cast<uint32_t>(k_tiles_per_sk_unit + 1));
    reduction_mode_ = reduction_mode;
  }

  static CUTLASS_DEVICE
  cute::tuple<int32_t, int32_t>
  get_work_idx_m_and_n(
      uint64_t blk_per_grid_dim,
      FastDivmodU64 const& divmod_blk_major) {

    uint64_t m_idx, n_idx;
    divmod_blk_major(m_idx, n_idx, blk_per_grid_dim);
    auto i = static_cast<int32_t>(m_idx);
    auto j = static_cast<int32_t>(n_idx);

    return {i, j};
  }

  // Computes the linear index within a batch given M and N tile offsets within the batch.
  // This essentially inverts the mapping performed in get_work_idx_m_and_n
  static CUTLASS_DEVICE
  uint64_t
  get_linear_idx_from_m_and_n(
    int32_t tile_m,
    int32_t tile_n,
    FastDivmodU64 const& divmod_blk_major) {
    return static_cast<uint64_t>(tile_m * divmod_blk_major.divisor + tile_n);
  }

  // Get the number of work-group tiles in this problem. This variant of the method should only be used when
  // problem_shape and tile_shape contain modes of only rank 1.
  CUTLASS_HOST_DEVICE
  static dim3
  get_tiled_wg_shape_mnl(BatchedGemmCoord problem_shape, GemmCoord cta_shape) {
    auto cta_m = (problem_shape.m() + cta_shape.m() - 1) / cta_shape.m();
    auto cta_n = (problem_shape.n() + cta_shape.n() - 1) / cta_shape.n();

    return {
      static_cast<uint32_t>(cta_m), 
      static_cast<uint32_t>(cta_n),
      static_cast<uint32_t>(problem_shape.batch())
    };
  }

  CUTLASS_HOST_DEVICE
  static dim3
  get_grid_shape(
    dim3 problem_blocks,
    KernelHardwareInfo hw_info,
    bool truncate_range = true
  ) {
    uint32_t available_sms = hw_info.sm_count;
    auto possibly_truncate = [&](int x, int y) {
      if(truncate_range)
        return static_cast<unsigned int>(platform::min(x, y));
      else
        return static_cast<unsigned int>(x);
    };
    return dim3{possibly_truncate(available_sms, problem_blocks.x * problem_blocks.y * problem_blocks.z), 1, 1};
  }

  // Returns the number of stream-K tiles that will be computed amongst `output_tiles` total
  // output tiles on a device with `wgs_per_wave` work-groups in each wave.
  static uint32_t
  get_num_sk_tiles(
    uint64_t output_tiles,
    uint64_t wgs_per_wave,
    uint32_t k_tiles_per_output_tile,
    DecompositionMode decomposition_mode
  ) {
    uint32_t full_waves = static_cast<uint32_t>(output_tiles / wgs_per_wave);
    uint32_t total_waves = static_cast<uint32_t>((output_tiles + wgs_per_wave - 1) / wgs_per_wave);

    if (decomposition_mode == DecompositionMode::DataParallel ||
        decomposition_mode == DecompositionMode::SplitK) {
      return 0;
    }

    // If there is wave quantization, assign the first two waves worth of tiles to be
    // covered by stream-K work and the remainder to be data-parallel. Since we know
    // that full_waves == total_waves - 1 in this case, the number of data-parallel
    // waves is simply full_waves-1 (unless full_waves == 0).
    uint32_t dp_waves = full_waves > 1 ? full_waves - 1 : 0;
    uint64_t dp_tiles = dp_waves * wgs_per_wave;
    uint64_t sk_tiles = output_tiles - dp_tiles;

    if (decomposition_mode == DecompositionMode::Heuristic) {
      if (full_waves == total_waves || k_tiles_per_output_tile <= min_iters_per_sk_unit_) {
        // All tiles will be data-parallel tiles if there is either no quantization
        // or if there is no work to be split.
        return 0;
      }

      //
      // The final wave is not full. Perform some stream-K work.
      //

      // Rudimentary heuristic: prefer data-parallel decomposition if we have more than
      // one wave and the tail wave is more than half full. This is subject to change.
      uint64_t tail_tiles = output_tiles - (full_waves * wgs_per_wave);
      if (2 * tail_tiles >= wgs_per_wave) {
        return 0;
      }
    }

    return static_cast<uint32_t>(sk_tiles);
  }

  CUTLASS_HOST_DEVICE
  static uint64_t
  get_num_sk_units(uint64_t wgs_per_sk_wave, uint32_t sk_tiles, uint32_t k_tiles_per_output_tile) {
    // If there are stream-K tiles to compute and a sufficiently large number of k iterations
    // across them, they will be covered by a single wave of persistent work_groups. Thus, there
    // will be as many work units as there are work_groups in a single wave.
    //
    // When the total k iterations across stream-K tiles is too small to justify distributing
    // across an entire wave of work_groups, we instead distribute the iterations over a smaller
    // set of work_groups.

    // Calculate the number of stream-K units that would be needed if each stream-K unit
    // computed the minimum allowable k iterations.

    // Number of k iterations computed by the stream-K units as a whole
    uint64_t k_tiles_sk_total = k_tiles_per_output_tile * sk_tiles;

    // Calculate the number of stream-K units that would be needed if each stream-K unit
    // computed the minimum allowable k iterations.
    uint64_t min_sized_sk_units = (k_tiles_sk_total / min_iters_per_sk_unit_);

    uint64_t sk_units = platform::min(wgs_per_sk_wave, min_sized_sk_units);
    return sk_units;
  }

  // Calculates the size of the workspace needed for holding reduction barriers
  CUTLASS_HOST_DEVICE
  static size_t
  get_barrier_workspace_size(uint64_t num_tiles, uint32_t barrier_bits) {
    size_t workspace_bits = num_tiles * static_cast<size_t>(barrier_bits);
    return bits_to_bytes<size_t>(workspace_bits);
  }

  // Calculates the size of the workspace needed for holding partial outputs from splits
  CUTLASS_HOST_DEVICE
  static size_t
  get_reduction_workspace_size(uint64_t num_tiles, GemmCoord tile_shape, uint32_t accumulator_bits, uint32_t num_accumulator_mtxs = 1) {
    size_t output_tile_size = tile_shape.m() * tile_shape.n();
    size_t workspace_bits = accumulator_bits * output_tile_size * num_tiles * num_accumulator_mtxs;
    return bits_to_bytes<size_t>(workspace_bits);
  }

  static void
  get_workspace_component_sizes(
    dim3 problem_blocks,
    uint32_t k_tiles_per_output_tile,
    GemmCoord tile_shape,
    size_t& barrier_workspace_size,
    size_t& reduction_workspace_size,
    KernelHardwareInfo const& hw_info,
    int splits,
    DecompositionMode decomposition_mode,
    uint32_t barrier_bits,
    uint32_t accumulator_bits) {

    // Workspace is needed only for output tiles that will be split. Thus, we first determine the number
    // of output tiles that will be split, and then calculate the workspace needed to cover these.
    uint64_t output_tiles = problem_blocks.x * problem_blocks.y * problem_blocks.z;

    if (decomposition_mode == DecompositionMode::DataParallel) {
      barrier_workspace_size = 0;
      reduction_workspace_size = 0;
    }
    else if (splits > 1 &&
             (decomposition_mode == DecompositionMode::SplitK || decomposition_mode == DecompositionMode::Heuristic)) {
      // Basic split-K variant requires workspace for all output tiles
      barrier_workspace_size = get_barrier_workspace_size(output_tiles, barrier_bits);
      reduction_workspace_size = get_reduction_workspace_size(output_tiles, tile_shape, accumulator_bits);
    }
    else {
      KernelHardwareInfo new_hw_info;
      new_hw_info.device_id = hw_info.device_id;
      new_hw_info.sm_count = hw_info.sm_count;
      if (new_hw_info.sm_count <= 0) {
        CUTLASS_TRACE_HOST("  WARNING: Arguments do not include a valid SM count.\n"
            "  For optimal performance, populate the arguments KernelHardwareInfo struct with the SM count.");
        new_hw_info.sm_count = KernelHardwareInfo::query_device_multiprocessor_count(new_hw_info.device_id);
      }

      dim3 grid = get_grid_shape(
        problem_blocks,
        new_hw_info
      );
      uint64_t wgs_per_wave = grid.x * grid.y;
      uint32_t sk_tiles = get_num_sk_tiles(
        output_tiles,
        wgs_per_wave,
        static_cast<uint32_t>(k_tiles_per_output_tile),
        decomposition_mode
      );
      uint64_t wgs_per_sk_wave = wgs_per_wave;
      uint64_t sk_units = get_num_sk_units(wgs_per_sk_wave, sk_tiles, k_tiles_per_output_tile);
      uint64_t dp_tiles = output_tiles - sk_tiles;

      uint64_t reduction_tiles = sk_tiles;

      barrier_workspace_size = get_barrier_workspace_size(sk_tiles, barrier_bits);
      reduction_workspace_size = get_reduction_workspace_size(reduction_tiles, tile_shape, accumulator_bits);
    }
  }

  // Get the amount of scratch workspace needed for the kernel. This variant of the method should only be used when
  // problem_shape and tile_shape contain modes of only rank 1.
  static size_t
  get_workspace_size(
    BatchedGemmCoord problem_shape,
    GemmCoord tile_shape,
    KernelHardwareInfo const& hw_info,
    int splits,
    DecompositionMode decomposition_mode,
    uint32_t barrier_bits,
    uint32_t element_accumulator_bits) {

    dim3 problem_blocks = get_tiled_wg_shape_mnl(problem_shape, tile_shape);
    uint32_t k_tiles_per_output_tile = (problem_shape.k() + tile_shape.k() - 1) / tile_shape.k();

    return get_workspace_size(
      problem_blocks,
      k_tiles_per_output_tile,
      tile_shape,
      hw_info,
      splits,
      decomposition_mode,
      barrier_bits,
      element_accumulator_bits
    );
  }

  // Version of get_workspace_size that takes in as input the number of work-groups in the M and N dimensions.
  // This is useful for calculating the tiled shape when a mode of problem and/or work-group shape has rank > 1,
  // for which using CuTe algebra for calculating tile shapes is easiest.
  static size_t
  get_workspace_size(
    dim3 problem_blocks,
    uint32_t k_tiles_per_output_tile,
    GemmCoord tile_shape,
    KernelHardwareInfo const& hw_info,
    int splits,
    DecompositionMode decomposition_mode,
    uint32_t barrier_bits,
    uint32_t element_accumulator_bits) {

    size_t barrier_workspace_size = 0;
    size_t reduction_workspace_size = 0;

    get_workspace_component_sizes(
      problem_blocks,
      k_tiles_per_output_tile,
      tile_shape,
      barrier_workspace_size,
      reduction_workspace_size,
      hw_info,
      splits,
      decomposition_mode,
      barrier_bits,
      element_accumulator_bits
    );

    return barrier_workspace_size + reduction_workspace_size;
  }

  // Initialize the workspace to be used for the kernel. This variant of the method should only be used when
  // problem_shape and tile_shape contain modes of only rank 1.
  static cutlass::Status
  initialize_workspace(
    void* workspace,
    BatchedGemmCoord problem_shape,
    GemmCoord tile_shape,
    KernelHardwareInfo const& hw_info,
    int splits,
    DecompositionMode decomposition_mode,
    uint32_t barrier_bits,
    uint32_t element_accumulator_bits) {

    dim3 problem_blocks = get_tiled_wg_shape_mnl(problem_shape, tile_shape);
    uint32_t k_tiles_per_output_tile = (problem_shape.k() + tile_shape.k() - 1) / tile_shape.k();

    return initialize_workspace(
      workspace,
      problem_blocks,
      k_tiles_per_output_tile,
      tile_shape,
      hw_info,
      splits,
      decomposition_mode,
      barrier_bits,
      element_accumulator_bits
    );
  }

  // Version of initialize_workspace that takes in as input the number of work-groups in the M and N dimensions.
  // This is useful for calculating the tiled shape when a mode of problem and/or work-group shape has rank > 1,
  // for which using CuTe algebra for calculating tile shapes is easiest.
  static cutlass::Status
  initialize_workspace(
    void* workspace,
    dim3 problem_blocks,
    uint32_t k_tiles_per_output_tile,
    GemmCoord tile_shape,
    KernelHardwareInfo const& hw_info,
    int splits,
    DecompositionMode decomposition_mode,
    uint32_t barrier_bits,
    uint32_t element_accumulator_bits) {

      uint64_t barrier_workspace_size = 0;
      uint64_t reduction_workspace_size = 0;

      get_workspace_component_sizes(
        problem_blocks,
        k_tiles_per_output_tile,
        tile_shape,
        barrier_workspace_size,
        reduction_workspace_size,
        hw_info,
        splits,
        decomposition_mode,
        barrier_bits,
        element_accumulator_bits
      );

      if (barrier_workspace_size > 0) {
        if (workspace == nullptr) {
          return Status::kErrorWorkspaceNull;
        }

        // Only the barrier workspace needs to be cleared for stream-K.
        // Barrier workspace follows reduction workspace.
        uint8_t* barrier_workspace = reinterpret_cast<uint8_t*>(workspace) + reduction_workspace_size;
        return zero_workspace(static_cast<void*>(barrier_workspace), barrier_workspace_size);
      }

    return Status::kSuccess;
  }

  void
  set_params_basic(
    uint32_t blocks_m,
    uint32_t blocks_n,
    uint32_t blocks_l,
    uint32_t splits,
    uint32_t k_tiles_per_output_tile,
    void* reduction_workspace,
    ReductionMode reduction_mode) {

    divmod_batch_ = FastDivmodU64(blocks_m * blocks_n);
    divmod_tiles_per_output_tile_ = FastDivmod(k_tiles_per_output_tile);
    divmod_sk_groups_ = FastDivmodU64(1u);
    divmod_splits_ = FastDivmod(splits);
    divmod_blk_major_ = FastDivmodU64(blocks_n);
    units_per_problem_ = blocks_m * blocks_n * blocks_l;
    big_units_ = k_tiles_per_output_tile % splits;
    reduction_workspace_ = reduction_workspace;
    reduction_mode_ = reduction_mode;
    divmod_k_tiles_per_sk_unit_ = FastDivmod(k_tiles_per_output_tile / splits);

    // No stream-K work is performed for "basic" data-parallel and split-K decompositions
    sk_tiles_ = 0;
    sk_units_ = 0;
    divmod_sk_units_per_group_ = FastDivmodU64(blocks_m * blocks_n * blocks_l);
  }
};

////////////////////////////////////////////////////////////////////////////////
} // namespace detail
} // namespace kernel
} // namespace gemm
} // namespace cutlass

////////////////////////////////////////////////////////////////////////////////
