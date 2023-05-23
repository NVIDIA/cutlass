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

#include "cutlass/fast_math.h"
#include "cutlass/kernel_hardware_info.hpp"
#include "cute/layout.hpp"

namespace cutlass::gemm::kernel::detail {

///////////////////////////////////////////////////////////////////////////////

// Persistent Thread Block (TB) scheduler
class PersistentTileSchedulerSm90 {
  //
  // Data members
  //

private:
  uint64_t current_work_linear_idx_{static_cast<uint64_t>((int(blockIdx.x) * int(gridDim.y)) + int(blockIdx.y))};
  uint64_t grid_blocks_total_{static_cast<uint64_t>(int(gridDim.x) * int(gridDim.y))};

  struct WorkTileInfo {
    int32_t M_idx = 0;
    int32_t N_idx = 0;
    int32_t L_idx = 0;
    uint32_t is_valid_tile = false;
  };

  //
  // Methods
  //

public:

  struct Params {
    FastDivmodU64 divmod_batch_{};
    FastDivmodU64 divmod_grid_y_{};
    FastDivmodU64 divmod_blk_m_{};

    uint64_t blocks_per_problem_ = 0;
  };

  template <class ProblemShapeMNKL, class TileShape, class ClusterShape>
  static Params
  to_underlying_arguments(ProblemShapeMNKL problem_shape_mnkl, TileShape tile_shape, ClusterShape cluster_shape) {
    // We only need the tile and cluster shape during scheduler setup, so let FTAD do the magic
    static_assert(is_static<TileShape>::value);
    static_assert(is_static<ClusterShape>::value);

    // Round up to nearest multiple of cluster dim along each mode
    auto [problem_blocks_m, problem_blocks_n, problem_blocks_l] = get_tiled_blk_shape_mnl(
        problem_shape_mnkl, tile_shape, cluster_shape);

    return {
      FastDivmodU64(problem_blocks_m * problem_blocks_n),
      FastDivmodU64(size<1>(cluster_shape)),
      FastDivmodU64(problem_blocks_m),
      problem_blocks_m * problem_blocks_n * problem_blocks_l
    };
  }

  PersistentTileSchedulerSm90() = default;

  CUTLASS_DEVICE
  WorkTileInfo
  get_current_work(Params const& scheduler_params) const {
    // Map worker's linear index into the CTA tiled problem shape to the corresponding MNL indices
    uint64_t work_idx_l, remainder;
    scheduler_params.divmod_batch_(work_idx_l, remainder, current_work_linear_idx_);

    uint64_t blk_per_grid_dim, dontcare;
    scheduler_params.divmod_grid_y_(blk_per_grid_dim, dontcare, remainder);

    uint64_t block_idx_m, block_idx_n;
    scheduler_params.divmod_blk_m_(block_idx_n, block_idx_m, blk_per_grid_dim);
    int32_t work_idx_m = static_cast<int32_t>(block_idx_m);
    int32_t work_idx_n = static_cast<int32_t>((block_idx_n * gridDim.y) + blockIdx.y);

    return {work_idx_m, work_idx_n, static_cast<int32_t>(work_idx_l), current_work_linear_idx_ < scheduler_params.blocks_per_problem_};
  }

  CUTLASS_DEVICE
  void
  advance_to_next_work(uint32_t advance_count = 1) {
    current_work_linear_idx_ += grid_blocks_total_ * advance_count;
  }

  // Given the inputs, computes the total number of output blocks this problem will compute over
  // Note that this is only the logical size of our grid, not the physical grid we will actually launch.
  template<class ProblemShapeMNKL, class BlockShape, class ClusterShape>
  CUTLASS_HOST_DEVICE static
  dim3
  get_tiled_blk_shape_mnl(ProblemShapeMNKL problem_shape_mnkl, BlockShape blk_shape, ClusterShape cluster_shape) {
    // Across M and N is our Cluster tile, so we must round up the blocks to the nearest whole number of Cluster tiles
    auto blk_m = cute::size(cute::ceil_div(cute::shape<0>(problem_shape_mnkl), cute::shape<0>(blk_shape)));
    auto blk_n = cute::size(cute::ceil_div(cute::shape<1>(problem_shape_mnkl), cute::shape<1>(blk_shape)));

    // Round up to nearest multiple of cluster dim along each mode
    int problem_blocks_m = round_up(blk_m, cute::size<0>(cluster_shape));
    int problem_blocks_n = round_up(blk_n, cute::size<1>(cluster_shape));

    // Cluster tile does not span the batch mode, so no extra rounding up required for it
    int problem_blocks_l = int(cute::size<3>(problem_shape_mnkl));
    return {uint32_t(problem_blocks_m), uint32_t(problem_blocks_n), uint32_t(problem_blocks_l)};
  }

  // Given the inputs, computes the physical grid we should launch.
  template<class ProblemShapeMNKL, class BlockShape, class ClusterShape>
  CUTLASS_HOST_DEVICE static
  dim3
  get_grid_shape(ProblemShapeMNKL problem_shape_mnk, BlockShape blk_shape, ClusterShape cluster_shape, KernelHardwareInfo hw_info) {
    int const sm_count = hw_info.sm_count;
    CUTLASS_TRACE_HOST("get_grid_shape(): Persistent schedule grid plan using SM count = " << sm_count);
    // Compute the total number of output tiles our problem has
    auto problem_shape_MNKL = append<4>(problem_shape_mnk, Int<1>{});
    auto [problem_blocks_m, problem_blocks_n, problem_blocks_l] =
        get_tiled_blk_shape_mnl(problem_shape_MNKL, blk_shape, cluster_shape);
    int problem_blocks_total = problem_blocks_m * problem_blocks_n * problem_blocks_l;

    dim3 launch_grid(1, cute::size<1>(cluster_shape), 1);

    // The else path is generic, however, we can avoid some divs if we know Cluster size is 1
    if constexpr (size(cluster_shape) == 1) {
      launch_grid.x = std::min(sm_count, problem_blocks_total);
    }
    else {
      /*
      * Optimal grid size calculation is based on
      * GH100: 8 GPCs, 72 TPCs (9 TPCs/GPC), 2 SMs/TPC, 144 SMs per full GPU
      * Hence, maximum SMs per GPC = 18
      */
      constexpr int max_sm_per_gpc = 18;
      // Provided SM count could possibly be less than the assumed maximum SMs per GPC
      int const min_num_gpc = sm_count < max_sm_per_gpc ? 1 : sm_count / max_sm_per_gpc;
      int const max_blk_occupancy_per_gpc = max_sm_per_gpc - (max_sm_per_gpc % size(cluster_shape));
      int blk_per_device = min_num_gpc * max_blk_occupancy_per_gpc;

      // The calculation below allows for larger grid size launch for different GPUs.
      int const num_gpc_residual = sm_count < max_sm_per_gpc ? 0 : sm_count % max_sm_per_gpc;
      int const max_blk_occupancy_per_residual_gpc = num_gpc_residual - (num_gpc_residual % size(cluster_shape));
      blk_per_device += max_blk_occupancy_per_residual_gpc;

      blk_per_device = sm_count < blk_per_device ? sm_count : blk_per_device;

      launch_grid.x = std::min(
          blk_per_device       / size<1>(cluster_shape),
          problem_blocks_total / size<1>(cluster_shape));
    }
    return launch_grid;
  }
};

} // namespace cutlass::gemm::kernel::detail
