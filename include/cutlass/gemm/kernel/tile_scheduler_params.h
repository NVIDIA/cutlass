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

/*! \file
    \brief Parameters structures for persistent tile schedulers
*/

/*
  Note:  CUTLASS 3x increases the host compiler requirements to C++17. However, certain
         existing integrations of CUTLASS require C++11 host compilers.

         Until this requirement can be lifted, certain headers with this annotation are required
         to be remain consistent with C++11 syntax.

         C++11 compatibility is enforced by this unit test: `cutlass_test_unit_core_cpp11`.
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

//
// Parameters for SM90 tile schedulers
//

// Parameters for SM90 persistent tile scheduler
struct PersistentTileSchedulerSm90Params {

  enum class RasterOrder {
    AlongM,
    AlongN
  };

  enum class RasterOrderOptions {
    Heuristic,
    AlongM,
    AlongN
  };

  FastDivmodU64Pow2 divmod_cluster_shape_major_{};
  FastDivmodU64Pow2 divmod_cluster_shape_minor_{};
  FastDivmodU64 divmod_batch_{};
  FastDivmodU64 divmod_cluster_blk_major_{};

  uint64_t blocks_per_problem_ = 0;
  int32_t log_swizzle_size_ = 0;
  RasterOrder raster_order_ = RasterOrder::AlongN;

  // Initializes members. This variant of the method should only be used when
  // problem_shape and tile_shape contain modes of only rank 1.
  void
  initialize(
    BatchedGemmCoord problem_shape,
    GemmCoord tile_shape,
    GemmCoord cluster_shape,
    KernelHardwareInfo const& hw_info,
    int max_swizzle_size,
    RasterOrderOptions raster_order_option
  ) {
    dim3 problem_blocks = get_tiled_cta_shape_mnl(problem_shape, tile_shape, cluster_shape);
    return initialize(
      problem_blocks,
      cluster_shape,
      hw_info,
      max_swizzle_size,
      raster_order_option
    );
  }

  // Version of initialize that takes in as input the number of CTAs in the M and N and L dimensions.
  // This is useful for calculating the tiled shape when a mode of problem and/or CTA shape has rank > 1,
  // for which using CuTe algebra for calculating tile shapes is easiest.
  void
  initialize(
    dim3 problem_blocks,
    GemmCoord cluster_shape,
    KernelHardwareInfo const& hw_info,
    int max_swizzle_size,
    RasterOrderOptions raster_order_option
  ) {
    
    CUTLASS_UNUSED(hw_info);
    
    // Round up to nearest multiple of swizzle_size along each mode
    auto log_swizzle_size = get_log_swizzle_size(problem_blocks.x, problem_blocks.y, max_swizzle_size);
    auto problem_blocks_m = round_up(problem_blocks.x, (1 << log_swizzle_size) * cluster_shape.m());
    auto problem_blocks_n = round_up(problem_blocks.y, (1 << log_swizzle_size) * cluster_shape.n());

    RasterOrder raster_order = get_rasterization_order(
      problem_blocks_m,
      problem_blocks_n,
      raster_order_option
    );

    //
    // Set members
    //

    blocks_per_problem_ = problem_blocks_m * problem_blocks_n * problem_blocks.z;
    log_swizzle_size_ = log_swizzle_size;
    raster_order_ = raster_order;
    divmod_batch_ = FastDivmodU64(problem_blocks_m * problem_blocks_n);

    if (raster_order == RasterOrder::AlongN) {
      divmod_cluster_shape_major_ = FastDivmodU64Pow2(cluster_shape.n());
      divmod_cluster_shape_minor_ = FastDivmodU64Pow2(cluster_shape.m());
      divmod_cluster_blk_major_ = FastDivmodU64(problem_blocks_n / cluster_shape.n());
    }
    else {
      divmod_cluster_shape_major_ = FastDivmodU64Pow2(cluster_shape.m());
      divmod_cluster_shape_minor_ = FastDivmodU64Pow2(cluster_shape.n());
      divmod_cluster_blk_major_ = FastDivmodU64(problem_blocks_m / cluster_shape.m());
    }
  }

  // Given the inputs, computes the physical grid we should launch.
  // This variant of the method should only be used when
  // problem_shape and tile_shape contain modes of only rank 1.
  CUTLASS_HOST_DEVICE static
  dim3
  get_grid_shape(
    BatchedGemmCoord problem_shape,
    GemmCoord cta_shape,
    GemmCoord cluster_shape,
    KernelHardwareInfo hw_info,
    int max_swizzle_size,
    RasterOrderOptions raster_order_option,
    bool truncate_by_problem_size=true) {

    dim3 problem_blocks = get_tiled_cta_shape_mnl(problem_shape, cta_shape, cluster_shape);
    return get_grid_shape(
      problem_blocks,
      cluster_shape,
      hw_info,
      max_swizzle_size,
      raster_order_option,
      truncate_by_problem_size
    );
  }

  // Version of get_grid_shape that takes in as input the number of CTAs in the M and N and L dimensions.
  // This is useful for calculating the tiled shape when a mode of problem and/or CTA shape has rank > 1,
  // for which using CuTe algebra for calculating tile shapes is easiest.
  CUTLASS_HOST_DEVICE static
  dim3
  get_grid_shape(
    dim3 problem_blocks,
    GemmCoord cluster_shape,
    KernelHardwareInfo hw_info,
    int max_swizzle_size,
    RasterOrderOptions raster_order_option,
    bool truncate_by_problem_size=true) {

    int const sm_count = hw_info.sm_count;

    // Round up to nearest multiple of swizzle_size along each mode
    auto log_swizzle_size = get_log_swizzle_size(problem_blocks.x, problem_blocks.y, max_swizzle_size);
    auto problem_blocks_m = round_up(problem_blocks.x, (1 << log_swizzle_size) * cluster_shape.m());
    auto problem_blocks_n = round_up(problem_blocks.y, (1 << log_swizzle_size) * cluster_shape.n());

    int problem_blocks_total = problem_blocks_m * problem_blocks_n * problem_blocks.z;

    RasterOrder raster_order = get_rasterization_order(
      problem_blocks_m,
      problem_blocks_n,
      raster_order_option
    );

    dim3 launch_grid;

    if (raster_order == RasterOrder::AlongN) {
      launch_grid = dim3(cluster_shape.m(), 1, 1);
    }
    else {
      launch_grid = dim3(1, cluster_shape.n(), 1);
    }

    auto possibly_truncate = [&](int x, int y) {
      if (truncate_by_problem_size) {
        return cutlass::platform::min(x, y);
      }
      else {
        return x;
      }
    };

    // The else path is generic, however, we can avoid some divs if we know cluster size is 1
    auto cluster_size = cluster_shape.m() * cluster_shape.n();
    if (cluster_size == 1) {
      if (raster_order == RasterOrder::AlongN) {
        launch_grid.y = possibly_truncate(sm_count, problem_blocks_total);
      }
      else {
        launch_grid.x = possibly_truncate(sm_count, problem_blocks_total);
      }
    }
    else {
      /*
      * Optimal grid size calculation is based on
      * GH100: 8 GPCs, 72 TPCs (9 TPCs/GPC), 2 SMs/TPC, 144 SMs per full GPU
      * Hence, maximum SMs per GPC = 18
      */
      constexpr int max_sm_per_gpc = 18;
      // Provided SM count could possibly be less than the assumed maximum SMs per GPC
      auto cluster_size = cluster_shape.m() * cluster_shape.n();
      int const min_num_gpc = sm_count < max_sm_per_gpc ? 1 : sm_count / max_sm_per_gpc;
      int const max_cta_occupancy_per_gpc = max_sm_per_gpc - (max_sm_per_gpc % cluster_size);
      int cta_per_device = min_num_gpc * max_cta_occupancy_per_gpc;

      // The calculation below allows for larger grid size launch for different GPUs.
      int const num_gpc_residual = sm_count < max_sm_per_gpc ? 0 : sm_count % max_sm_per_gpc;
      int const max_cta_occupancy_per_residual_gpc = num_gpc_residual - (num_gpc_residual % cluster_size);
      cta_per_device += max_cta_occupancy_per_residual_gpc;

      cta_per_device = sm_count < cta_per_device ? sm_count : cta_per_device;

      if (raster_order == RasterOrder::AlongN) {
        launch_grid.y = possibly_truncate(
            cta_per_device       / cluster_shape.m(),
            problem_blocks_total / cluster_shape.m());
      }
      else {
        launch_grid.x = possibly_truncate(
            cta_per_device       / cluster_shape.n(),
            problem_blocks_total / cluster_shape.n());
      }
    }
    return launch_grid;
  }

  CUTLASS_HOST_DEVICE
  static int32_t
  get_log_swizzle_size(int problem_ctas_m, int problem_ctas_n, int max_swizzle_size) {
    int min_cta_dim = cutlass::platform::min(problem_ctas_m, problem_ctas_n);
    if (max_swizzle_size >= 8 && min_cta_dim >= 6) {
      return 3;
    }
    else if (max_swizzle_size >= 4 && min_cta_dim >= 3) {
      return 2;
    }
    else if (max_swizzle_size >= 2 && min_cta_dim >= 2) {
      return 1;
    }
    else {
      return 0;
    }
  }

  CUTLASS_HOST_DEVICE
  static RasterOrder
  get_rasterization_order(
    uint32_t tiles_m,
    uint32_t tiles_n,
    RasterOrderOptions raster_order_option
  ) {

    if (raster_order_option == RasterOrderOptions::Heuristic) {
      if (tiles_n > tiles_m) {
        return RasterOrder::AlongM;
      }
      else {
        return RasterOrder::AlongN;
      }
    }
    else {
      switch (raster_order_option) {
        case RasterOrderOptions::AlongN:
          return RasterOrder::AlongN;
          break;
        default:
          return RasterOrder::AlongM;
      }
    }
  }

  // Get the number of CTA tiles in this problem. This variant of the method should only be used when
  // problem_shape and tile_shape contain modes of only rank 1.
  CUTLASS_HOST_DEVICE
  static dim3
  get_tiled_cta_shape_mnl(BatchedGemmCoord problem_shape, GemmCoord cta_shape, GemmCoord cluster_shape) {
    auto cta_m = (problem_shape.m() + cta_shape.m() - 1) / cta_shape.m();
    auto cta_n = (problem_shape.n() + cta_shape.n() - 1) / cta_shape.n();

    return get_tiled_cta_shape_mnl(problem_shape, cluster_shape, cta_m, cta_n);
  }

  // Version of get_tiled_cta_shape_mnl that takes in as input the number of CTAs in the M and N dimensions.
  // This is useful for calculating the tiled shape when a mode of problem and/or CTA shape has rank > 1,
  // for which using CuTe algebra for calculating tile shapes is easiest.
  CUTLASS_HOST_DEVICE
  static dim3
  get_tiled_cta_shape_mnl(BatchedGemmCoord problem_shape, GemmCoord cluster_shape, uint32_t cta_m, uint32_t cta_n) {

    // Round up to nearest multiple of cluster dim along each mode
    auto problem_blocks_m = ((cta_m + cluster_shape.m() - 1) / cluster_shape.m()) * cluster_shape.m();
    auto problem_blocks_n = ((cta_n + cluster_shape.n() - 1) / cluster_shape.n()) * cluster_shape.n();

    return {
      static_cast<uint32_t>(problem_blocks_m),
      static_cast<uint32_t>(problem_blocks_n),
      static_cast<uint32_t>(problem_shape.batch())
    };
  }
};

////////////////////////////////////////////////////////////////////////////////

// Parameters for SM90 persistent stream-K scheduler
struct PersistentTileSchedulerSm90StreamKParams {

  // Strategies for computing reductions between CTAs computing portions of a given output tile
  enum class ReductionMode {
    // Participating CTAs perform reduction in a turnstile fashion in order of the K extent
    // covered by each CTA. This requires a lock to be held exclusively be the CTA that is
    // currently accumulating.
    //
    // Turnstile accumulation ensures deterministic numeric behavior when using this mode.
    Deterministic,

    // Participating CTAs perform reduction atomically to the same workspace (mostly) without locking.
    // Locks are used only to wait for the first CTA to write its partial values (to initialize the
    // workspace), and for all but the final CTA to have accumulated (so that the final CTA can load
    // the accumulated value and accumulate it into registers on top of which the epilogue will
    // be performed).
    //
    // Due to the nondeterminsitic ordering of accumulation, deterministic numeric behavior cannot
    // be guaranteed with this mode (e.g., floating-point rounding error will depend on the order
    // of accumulation)
    Nondeterministic
  };

  using UnderlyingParams = PersistentTileSchedulerSm90Params;
  using RasterOrder = UnderlyingParams::RasterOrder;
  using RasterOrderOptions = UnderlyingParams::RasterOrderOptions;

  // Cluster dimensions are typically always a power of 2, so use
  // the power-of-two variants of FastDivmod for these.
  FastDivmodU64Pow2 divmod_cluster_shape_major_{};
  FastDivmodU64Pow2 divmod_cluster_shape_minor_{};

  FastDivmodU64 divmod_batch_{};
  FastDivmodU64 divmod_cluster_blk_major_{};

  // Total number of cluster-sized output tiles (i.e., not including any
  // splitting factors). This is primarily used for split-K decompositions,
  // and may be overridden in other decompositions.
  FastDivmodU64 divmod_clusters_mnl_{};

  uint64_t units_per_problem_ = 0;
  FastDivmod divmod_tiles_per_output_tile_{};
  int32_t log_swizzle_size_ = 0;
  RasterOrder raster_order_ = RasterOrder::AlongN;

  // The splitting factor to be used in a split-K decomposition of the problem.
  // If this is set to a value greater than 1, stream-K decomposition logic
  // is bypassed in favor of a split-K decomposition.
  uint32_t splits_ = 1;

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

  // Strategy to use when reducing between collaborating CTAs
  ReductionMode reduction_mode_ = ReductionMode::Deterministic;

  // Minimum number of tiled k that can be assigned to a stream-K unit
  static constexpr uint32_t min_iters_per_sk_unit_ = 4u;

  // Initializes members. This variant of the method should only be used when
  // problem_shape and tile_shape contain modes of only rank 1.
  void
  initialize(
    BatchedGemmCoord problem_shape,
    GemmCoord tile_shape,
    GemmCoord cluster_shape,
    KernelHardwareInfo hw_info,
    int splits,
    int max_swizzle,
    RasterOrderOptions raster_order_option,
    ReductionMode reduction_mode,
    void* workspace
  ) {
    dim3 problem_blocks = UnderlyingParams::get_tiled_cta_shape_mnl(
      problem_shape, tile_shape, cluster_shape);

    // Number of k tiles in each output tile
    uint32_t k_tiles_per_output_tile = (problem_shape.k() + tile_shape.k() - 1) / tile_shape.k();

    initialize(
      problem_blocks,
      k_tiles_per_output_tile,
      cluster_shape,
      hw_info,
      splits,
      max_swizzle,
      raster_order_option,
      reduction_mode,
      workspace
    );
  }

  // Version of initialize that takes in as input the number of CTAs in the M and N and L dimensions.
  // This is useful for calculating the tiled shape when a mode of problem and/or CTA shape has rank > 1,
  // for which using CuTe algebra for calculating tile shapes is easiest.
  void
  initialize(
    dim3 problem_blocks,
    uint32_t k_tiles_per_output_tile,
    GemmCoord cluster_shape,
    KernelHardwareInfo hw_info,
    int splits,
    int max_swizzle,
    RasterOrderOptions raster_order_option,
    ReductionMode reduction_mode,
    void* workspace
  ) {
    UnderlyingParams underlying_params;
    underlying_params.initialize(
      problem_blocks,
      cluster_shape,
      hw_info,
      max_swizzle,
      raster_order_option
    );

    auto problem_blocks_l = problem_blocks.z;

    auto problem_blocks_m = round_up(problem_blocks.x, (1 << underlying_params.log_swizzle_size_) * cluster_shape.m());
    auto problem_blocks_n = round_up(problem_blocks.y, (1 << underlying_params.log_swizzle_size_) * cluster_shape.n());
    uint64_t output_tiles = problem_blocks_m * problem_blocks_n * problem_blocks_l;

    // Reduction workspace is at the beginning of the workspace. Lock workspace follows.
    void* reduction_workspace = workspace;

    if (splits > 1) {
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

      set_params_basic(
        underlying_params,
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

    // Calculate the maximum number of blocks from clusters of shape cluster_shape that we
    // can fit within sm_count SMs.
    dim3 grid = get_grid_shape(
      problem_blocks,
      cluster_shape,
      hw_info,
      max_swizzle,
      raster_order_option
    );

    uint64_t ctas_per_wave = grid.x * grid.y;

    // The number of output tiles to be computed in stream-K and data-parallel fashion, respectively.
    uint32_t sk_tiles = get_num_sk_tiles(output_tiles, ctas_per_wave, k_tiles_per_output_tile);
    uint64_t dp_tiles = output_tiles - sk_tiles;

    if (sk_tiles == 0) {
      // Short circuit to basic data-parallel decomposition
      set_params_basic(
        underlying_params,
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
    auto cluster_size = cluster_shape.m() * cluster_shape.n();
    uint64_t min_sized_sk_units = (k_tiles_sk_total / min_iters_per_sk_unit_);
    min_sized_sk_units = (min_sized_sk_units / cluster_size) * cluster_size;

    uint64_t sk_units = cutlass::platform::min(ctas_per_wave, min_sized_sk_units);

    // If the number of stream-K units is a multiple of the number of stream-K tiles, then
    // the problem can leverage a basic split-K decomposition for the stream-K tiles.
    if (sk_tiles < sk_units && sk_units % sk_tiles == 0) {
      // Short circuit to basic split-K decomposition
      uint32_t sk_splits = static_cast<uint32_t>(sk_units / sk_tiles);
      set_params_basic(
        underlying_params,
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

    // Number of k iterations computed per stream-K units
    uint64_t k_tiles_per_sk_unit = k_tiles_sk_total / sk_units;

    // Number of stream-K units that need to compute extra iterations in order to cover
    // the residual k iterations. This assumes that each such unit computes one additional
    // iteration.
    uint64_t sk_big_units = k_tiles_sk_total - (k_tiles_per_sk_unit * sk_units);

    // The division below is guaranteed to be exact because sk_big_units is guaranteed
    // to be a multiple of cluster_size. This is useful because
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
    uint64_t sk_big_units_per_cluster = sk_big_units / cluster_size;

    divmod_cluster_shape_major_ = underlying_params.divmod_cluster_shape_major_;
    divmod_cluster_shape_minor_ = underlying_params.divmod_cluster_shape_minor_;
    divmod_batch_ = underlying_params.divmod_batch_;
    divmod_tiles_per_output_tile_ = FastDivmod(k_tiles_per_output_tile);
    divmod_cluster_blk_major_ = underlying_params.divmod_cluster_blk_major_;

    // Override divmod_clusters_mnl_ to be the number of cluster-sized stream-K units.
    // This setting ensures that the use of this divmod for stream-K decompositions
    // is essentially a no-op.
    divmod_clusters_mnl_ = FastDivmodU64(sk_units / cluster_size);
    splits_ = 1;
    log_swizzle_size_ = underlying_params.log_swizzle_size_;
    units_per_problem_ = static_cast<uint32_t>(dp_units + sk_units);
    raster_order_ = underlying_params.raster_order_;
    big_units_ = static_cast<uint32_t>(sk_big_units_per_cluster);
    reduction_workspace_ = reduction_workspace;
    sk_tiles_ = sk_tiles;
    sk_units_ = static_cast<uint32_t>(sk_units);
    k_tiles_per_sk_unit_ = static_cast<uint32_t>(k_tiles_per_sk_unit);
    reduction_mode_ = reduction_mode;
  }

  // Given the inputs, computes the physical grid we should launch.
  // This variant of the method should only be used when
  // problem_shape and tile_shape contain modes of only rank 1.
  CUTLASS_HOST_DEVICE
  static dim3
  get_grid_shape(
    BatchedGemmCoord problem_shape,
    GemmCoord cta_shape,
    GemmCoord cluster_shape,
    KernelHardwareInfo hw_info,
    int max_swizzle_size,
    RasterOrderOptions raster_order_option
  ) {

    dim3 problem_blocks = UnderlyingParams::get_tiled_cta_shape_mnl(problem_shape, cta_shape, cluster_shape);

    return get_grid_shape(
      problem_blocks,
      cluster_shape,
      hw_info,
      max_swizzle_size,
      raster_order_option
    );
  }

  // Version of get_grid_shape that takes in as input the number of CTAs in the M and N and L dimensions.
  // This is useful for calculating the tiled shape when a mode of problem and/or CTA shape has rank > 1,
  // for which using CuTe algebra for calculating tile shapes is easiest.
  CUTLASS_HOST_DEVICE
  static dim3
  get_grid_shape(
    dim3 problem_blocks,
    GemmCoord cluster_shape,
    KernelHardwareInfo hw_info,
    int max_swizzle_size,
    RasterOrderOptions raster_order_option
  ) {

    // Call into the underlying get_grid_shape method, but do not allow the grid shape returned
    // to be truncated based on the number of output tiles in the problem.
    return UnderlyingParams::get_grid_shape(
      problem_blocks,
      cluster_shape,
      hw_info,
      max_swizzle_size,
      raster_order_option,
      /* truncate_by_problem_size = */false
    );
  }

  // Returns the number of stream-K tiles that will be computed amongst `output_tiles` total
  // output tiles on a device with `ctas_per_wave` CTAs in each wave.
  static uint32_t
  get_num_sk_tiles(uint64_t output_tiles, uint64_t ctas_per_wave, uint32_t k_tiles_per_output_tile) {
    uint32_t full_waves = static_cast<uint32_t>(output_tiles / ctas_per_wave);
    uint32_t total_waves = static_cast<uint32_t>((output_tiles + ctas_per_wave - 1) / ctas_per_wave);

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
  get_barrier_workspace_size(uint64_t num_tiles, uint32_t mma_warp_groups, uint32_t barrier_bits) {
    auto workspace_bits = num_tiles * mma_warp_groups * barrier_bits;
    return round_up_to_l2_alignment(bits_to_bytes(static_cast<int>(workspace_bits)));
  }

  // Calculates the size of the workspace needed for holding partial outputs from splits
  CUTLASS_HOST_DEVICE
  static int
  get_reduction_workspace_size(uint64_t num_tiles, GemmCoord tile_shape, uint32_t accumulator_bits) {
    auto output_tile_size = tile_shape.m() * tile_shape.n();
    auto workspace_bits = accumulator_bits * output_tile_size * num_tiles;
    return round_up_to_l2_alignment(bits_to_bytes(static_cast<int>(workspace_bits)));
  }

  #if !defined(__CUDACC_RTC__)
  static void
  get_workspace_component_sizes(
    dim3 problem_blocks,
    uint32_t k_tiles_per_output_tile,
    GemmCoord tile_shape,
    GemmCoord cluster_shape,
    int& barrier_workspace_size,
    int& reduction_workspace_size,
    KernelHardwareInfo const& hw_info,
    int splits,
    int max_swizzle,
    RasterOrderOptions raster_order_option,
    uint32_t mma_warp_groups,
    uint32_t barrier_bits,
    uint32_t accumulator_bits) {

    auto log_swizzle_size = UnderlyingParams::get_log_swizzle_size(problem_blocks.x, problem_blocks.y, max_swizzle);
    problem_blocks.x = round_up(problem_blocks.x, (1 << log_swizzle_size) * cluster_shape.m());
    problem_blocks.y = round_up(problem_blocks.y, (1 << log_swizzle_size) * cluster_shape.n());

    // Workspace is needed only for output tiles that will be split. Thus, we first determine the number
    // of output tiles that will be split, and then calculate the workspace needed to cover these.
    uint64_t output_tiles = problem_blocks.x * problem_blocks.y * problem_blocks.z;

    if (splits > 1) {
      // Basic split-K variant requires workspace for all output tiles
      barrier_workspace_size = get_barrier_workspace_size(output_tiles, mma_warp_groups, barrier_bits);
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
        cluster_shape,
        new_hw_info,
        max_swizzle,
        raster_order_option
      );
      uint64_t ctas_per_wave = grid.x * grid.y;
      uint32_t sk_tiles = get_num_sk_tiles(output_tiles, ctas_per_wave, static_cast<uint32_t>(k_tiles_per_output_tile));

      barrier_workspace_size = get_barrier_workspace_size(sk_tiles, mma_warp_groups, barrier_bits);
      reduction_workspace_size = get_reduction_workspace_size(sk_tiles, tile_shape, accumulator_bits);
    }
  }
  #endif // !defined(__CUDACC_RTC__)

  // Get the amount of scratch workspace needed for the kernel. This variant of the method should only be used when
  // problem_shape and tile_shape contain modes of only rank 1.
  static int
  get_workspace_size(
    BatchedGemmCoord problem_shape,
    GemmCoord tile_shape,
    GemmCoord cluster_shape,
    KernelHardwareInfo const& hw_info,
    int splits,
    int max_swizzle,
    RasterOrderOptions raster_order_option,
    uint32_t mma_warp_groups,
    uint32_t barrier_bits,
    uint32_t element_accumulator_bits) {

    dim3 problem_blocks = UnderlyingParams::get_tiled_cta_shape_mnl(problem_shape, tile_shape, cluster_shape);
    uint32_t k_tiles_per_output_tile = (problem_shape.k() + tile_shape.k() - 1) / tile_shape.k();

    return get_workspace_size(
      problem_blocks,
      k_tiles_per_output_tile,
      tile_shape,
      cluster_shape,
      hw_info,
      splits,
      max_swizzle,
      raster_order_option,
      mma_warp_groups,
      barrier_bits,
      element_accumulator_bits
    );
  }

  // Version of get_workspace_size that takes in as input the number of CTAs in the M and N dimensions.
  // This is useful for calculating the tiled shape when a mode of problem and/or CTA shape has rank > 1,
  // for which using CuTe algebra for calculating tile shapes is easiest.
  static int
  get_workspace_size(
    dim3 problem_blocks,
    uint32_t k_tiles_per_output_tile,
    GemmCoord tile_shape,
    GemmCoord cluster_shape,
    KernelHardwareInfo const& hw_info,
    int splits,
    int max_swizzle,
    RasterOrderOptions raster_order_option,
    uint32_t mma_warp_groups,
    uint32_t barrier_bits,
    uint32_t element_accumulator_bits) {

    int barrier_workspace_size = 0;
    int reduction_workspace_size = 0;

    #if !defined(__CUDACC_RTC__)
      get_workspace_component_sizes(
        problem_blocks,
        k_tiles_per_output_tile,
        tile_shape,
        cluster_shape,
        barrier_workspace_size,
        reduction_workspace_size,
        hw_info,
        splits,
        max_swizzle,
        raster_order_option,
        mma_warp_groups,
        barrier_bits,
        element_accumulator_bits
      );
    #endif

    return barrier_workspace_size + reduction_workspace_size;
  }

  // Initialize the workspace to be used for the kernel. This variant of the method should only be used when
  // problem_shape and tile_shape contain modes of only rank 1.
  static cutlass::Status
  initialize_workspace(
    void* workspace,
    cudaStream_t stream,
    BatchedGemmCoord problem_shape,
    GemmCoord tile_shape,
    GemmCoord cluster_shape,
    KernelHardwareInfo const& hw_info,
    int splits,
    int max_swizzle,
    RasterOrderOptions raster_order_option,
    uint32_t mma_warp_groups,
    uint32_t barrier_bits,
    uint32_t element_accumulator_bits) {

    dim3 problem_blocks = UnderlyingParams::get_tiled_cta_shape_mnl(problem_shape, tile_shape, cluster_shape);
    uint32_t k_tiles_per_output_tile = (problem_shape.k() + tile_shape.k() - 1) / tile_shape.k();

    return initialize_workspace(
      workspace,
      stream,
      problem_blocks,
      k_tiles_per_output_tile,
      tile_shape,
      cluster_shape,
      hw_info,
      splits,
      max_swizzle,
      raster_order_option,
      mma_warp_groups,
      barrier_bits,
      element_accumulator_bits
    );
  }

  // Version of initialize_workspace that takes in as input the number of CTAs in the M and N dimensions.
  // This is useful for calculating the tiled shape when a mode of problem and/or CTA shape has rank > 1,
  // for which using CuTe algebra for calculating tile shapes is easiest.
  static cutlass::Status
  initialize_workspace(
    void* workspace,
    cudaStream_t stream,
    dim3 problem_blocks,
    uint32_t k_tiles_per_output_tile,
    GemmCoord tile_shape,
    GemmCoord cluster_shape,
    KernelHardwareInfo const& hw_info,
    int splits,
    int max_swizzle,
    RasterOrderOptions raster_order_option,
    uint32_t mma_warp_groups,
    uint32_t barrier_bits,
    uint32_t element_accumulator_bits) {

    #if !defined(__CUDACC_RTC__)
      int barrier_workspace_size = 0;
      int reduction_workspace_size = 0;

      get_workspace_component_sizes(
        problem_blocks,
        k_tiles_per_output_tile,
        tile_shape,
        cluster_shape,
        barrier_workspace_size,
        reduction_workspace_size,
        hw_info,
        splits,
        max_swizzle,
        raster_order_option,
        mma_warp_groups,
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
        return zero_workspace(static_cast<void*>(barrier_workspace), barrier_workspace_size, stream);
      }
    #endif // !defined(__CUDACC_RTC__)

    return Status::kSuccess;
  }

  void
  set_params_basic(
    UnderlyingParams const& underlying_params,
    uint32_t blocks_m,
    uint32_t blocks_n,
    uint32_t blocks_l,
    uint32_t splits,
    uint32_t k_tiles_per_output_tile,
    void* reduction_workspace,
    ReductionMode reduction_mode) {

    divmod_cluster_shape_major_ = underlying_params.divmod_cluster_shape_major_;
    divmod_cluster_shape_minor_ = underlying_params.divmod_cluster_shape_minor_;
    divmod_batch_ = FastDivmodU64(blocks_m * blocks_n);
    divmod_tiles_per_output_tile_ = FastDivmod(k_tiles_per_output_tile);
    auto cluster_size = underlying_params.divmod_cluster_shape_major_.divisor * underlying_params.divmod_cluster_shape_minor_.divisor;
    divmod_clusters_mnl_ = FastDivmodU64((blocks_m * blocks_n * blocks_l) / cluster_size);
    splits_ = splits;
    divmod_cluster_blk_major_ = underlying_params.divmod_cluster_blk_major_;
    log_swizzle_size_ = underlying_params.log_swizzle_size_;
    units_per_problem_ = blocks_m * blocks_n * blocks_l;
    raster_order_ = underlying_params.raster_order_;
    big_units_ = k_tiles_per_output_tile % splits;
    reduction_workspace_ = reduction_workspace;
    reduction_mode_ = reduction_mode;
    k_tiles_per_sk_unit_ = k_tiles_per_output_tile / splits;

    // No stream-K work is performed for "basic" data-parallel and split-K decompositions
    sk_tiles_ = 0;
    sk_units_ = 0;
  }

private:
  // Round up number of bytes to the nearest multiple of L2 cache line alignment
  CUTLASS_HOST_DEVICE
  static int
  round_up_to_l2_alignment(int bytes) {
    constexpr static uint32_t L2CacheLineSizeBytes = 128;
    return (bytes + L2CacheLineSizeBytes - 1) / L2CacheLineSizeBytes * L2CacheLineSizeBytes;
  }
};

////////////////////////////////////////////////////////////////////////////////
} // namespace detail
} // namespace kernel
} // namespace gemm
} // namespace cutlass

////////////////////////////////////////////////////////////////////////////////
