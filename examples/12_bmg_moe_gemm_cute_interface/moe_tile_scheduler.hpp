/***************************************************************************************************
 * Copyright (c) 2025 Intel Corporation. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice,
 *this list of conditions and the following disclaimer.
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
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 *ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
 *LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 *SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 *INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 *CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 *ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 *POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
#pragma once

#include "cute/layout.hpp"
#include "cute/tensor.hpp"
#include "cutlass/fast_math.h"
#include "cutlass/gemm/kernel/tile_scheduler_params.h"
#include "cutlass/gemm_coord.hpp"
#include "cutlass/kernel_hardware_info.hpp"

namespace MoE {
using namespace cutlass::gemm::kernel::detail;
using namespace cutlass;
using namespace cutlass::gemm;
using namespace cute;
///////////////////////////////////////////////////////////////////////////////
// Adapted from xe_tile_scheduler_group.hpp
// Persistent Thread Block (TB) scheduler for MoE GEMM
template <class GroupProblemShape>
class PersistentTileSchedulerXeMoE
    : public PersistentTileSchedulerXeGroup<GroupProblemShape> {
  //
  // Data members
  //

private:
  uint64_t current_work_linear_idx_ = 0;
  uint64_t total_grid_size_ = 0;
  int32_t *num_rows_per_expert_ = nullptr;
  int32_t K_ = 0;
  int32_t N_ = 0;
  int32_t num_experts_ = 0;

  // Tracking current group, its starting linear idx and total tiles
  struct GroupInfo {
    int group_idx = 0;
    uint64_t start_linear_idx = 0;
    uint64_t total_tiles = 0;
  } current_group_info_;

public:
  struct WorkTileInfo {
    int32_t M_idx = 0;
    int32_t N_idx = 0;
    int32_t L_idx = 0;
    bool is_valid_tile = false;

    CUTLASS_HOST_DEVICE
    bool is_valid() const { return is_valid_tile; }

    CUTLASS_HOST_DEVICE
    static WorkTileInfo invalid_work_tile() { return {-1, -1, -1, false}; }
  };

  using ProblemShape = typename GroupProblemShape::UnderlyingProblemShape;
  using Params = PersistentTileSchedulerSm90GroupParams<GroupProblemShape>;
  using RasterOrder = typename Params::RasterOrder;
  using RasterOrderOptions = typename Params::RasterOrderOptions;
  using BaseClass = PersistentTileSchedulerXeGroup<GroupProblemShape>;

  Params scheduler_params;

  //
  // Methods
  //

  // Given the inputs, computes the total number of output blocks this problem
  // will compute over Note that this is only the logical size of our grid, not
  // the physical grid we will actually launch.
  template <class ClusterShape>
  CUTLASS_HOST_DEVICE static dim3
  get_tiled_cta_shape_mnl(const KernelHardwareInfo &hw_info,
                          ClusterShape cluster_shape) {
    uint32_t total_ctas = 0;
    uint32_t cta_in_N_dim =
        1; // We linearize the blocks across all the problems here

    total_ctas = hw_info.sm_count;

    return Params::get_tiled_cta_shape_mnl(to_gemm_coord(cluster_shape),
                                           total_ctas, cta_in_N_dim);
  }

  template <class TileShape, class ClusterShape>
  static Params to_underlying_arguments(
      GroupProblemShape problem_shapes, TileShape tile_shape,
      ClusterShape cluster_shape, KernelHardwareInfo const &hw_info,
      typename BaseClass::Arguments const &arguments,
      [[maybe_unused]] void *workspace = nullptr,
      [[maybe_unused]] const uint32_t epilogue_subtile = 1,
      [[maybe_unused]] uint32_t ktile_start_alignment_count = 1u) {
    return BaseClass::to_underlying_arguments(problem_shapes, tile_shape,
                                              cluster_shape, hw_info, arguments,
                                              workspace);
  }

  // Given the inputs, computes the physical grid we should launch.
  template <class TileShape, class ClusterShape>
  CUTLASS_HOST_DEVICE static dim3
  get_grid_shape([[maybe_unused]] Params const &params,
                 GroupProblemShape problem_shapes, TileShape tile_shape,
                 ClusterShape cluster_shape, KernelHardwareInfo hw_info,
                 typename BaseClass::Arguments arguments,
                 bool truncate_by_problem_size = true) {

    return BaseClass::get_grid_shape(params, problem_shapes, tile_shape,
                                     cluster_shape, hw_info, arguments,
                                     truncate_by_problem_size);
  }

  CUTLASS_DEVICE explicit PersistentTileSchedulerXeMoE(
      Params const &params_, int32_t *num_rows_per_expert, int32_t N, int32_t K,
      int32_t num_experts)
      : scheduler_params(params_) {
    num_rows_per_expert_ = num_rows_per_expert;
    N_ = N;
    K_ = K;
    num_experts_ = num_experts;
    if (scheduler_params.raster_order_ == RasterOrder::AlongN) {
      current_work_linear_idx_ =
          uint64_t(BlockIdxX()) + uint64_t(BlockIdxY()) * uint64_t(GridDimX());
    } else {
      current_work_linear_idx_ =
          uint64_t(BlockIdxX()) * uint64_t(GridDimY()) + uint64_t(BlockIdxY());
    }
    total_grid_size_ =
        uint64_t(GridDimX()) * uint64_t(GridDimY()) * uint64_t(GridDimZ());
  }

  CUTLASS_DEVICE
  WorkTileInfo get_current_work() {
    return get_current_work_for_linear_idx(current_work_linear_idx_);
  }

  CUTLASS_DEVICE
  WorkTileInfo get_current_work_for_linear_idx(uint64_t linear_idx) {
    return get_work_idx_m_and_n(
        linear_idx, current_group_info_, scheduler_params.problem_shapes_,
        scheduler_params.cta_shape_, scheduler_params.cluster_shape_,
        scheduler_params.divmod_cluster_shape_major_,
        scheduler_params.divmod_cluster_shape_minor_,
        scheduler_params.divmod_cta_shape_m_,
        scheduler_params.divmod_cta_shape_n_,
        scheduler_params.log_swizzle_size_, scheduler_params.raster_order_);
  }

  CUTLASS_DEVICE
  void advance_to_next_work(uint32_t advance_count = 1) {
    current_work_linear_idx_ += total_grid_size_ * uint64_t(advance_count);
  }

  // get work_idx_m, work_idx_n from linear_idx while applying swizzle
  CUTLASS_DEVICE
  WorkTileInfo
  get_work_idx_m_and_n(uint64_t linear_idx, struct GroupInfo &group_info,
                       GroupProblemShape &problem_shapes, GemmCoord cta_shape,
                       cutlass::gemm::GemmCoord cluster_shape,
                       FastDivmodU64Pow2 const &divmod_cluster_shape_major,
                       FastDivmodU64Pow2 const &divmod_cluster_shape_minor,
                       FastDivmodU64 const &divmod_cta_shape_m,
                       FastDivmodU64 const &divmod_cta_shape_n,
                       int32_t log_swizzle_size, RasterOrder raster_order) {

    bool valid_tile = true;
    uint64_t ctas_along_m, ctas_along_n;
    int total_problem_groups = num_experts_;
    ctas_along_m = divmod_cta_shape_m.divide(
        cute::shape<0>(
            ProblemShape(num_rows_per_expert_[group_info.group_idx], N_, K_)) +
        divmod_cta_shape_m.divisor - 1);
    ctas_along_n = divmod_cta_shape_n.divide(
        cute::shape<1>(
            ProblemShape(num_rows_per_expert_[group_info.group_idx], N_, K_)) +
        divmod_cta_shape_n.divisor - 1);

    auto problem_blocks_m =
        round_up(ctas_along_m, (1 << log_swizzle_size) * cluster_shape.m());
    auto problem_blocks_n =
        round_up(ctas_along_n, (1 << log_swizzle_size) * cluster_shape.n());
    group_info.total_tiles = problem_blocks_m * problem_blocks_n;

    while (group_info.start_linear_idx + group_info.total_tiles <= linear_idx) {
      group_info.group_idx++;

      if (group_info.group_idx >= total_problem_groups)
        return WorkTileInfo::invalid_work_tile();

      group_info.start_linear_idx += group_info.total_tiles;
      ctas_along_m = divmod_cta_shape_m.divide(
          cute::shape<0>(ProblemShape(
              num_rows_per_expert_[group_info.group_idx], N_, K_)) +
          divmod_cta_shape_m.divisor - 1);
      ctas_along_n = divmod_cta_shape_n.divide(
          cute::shape<1>(ProblemShape(
              num_rows_per_expert_[group_info.group_idx], N_, K_)) +
          divmod_cta_shape_n.divisor - 1);

      problem_blocks_m =
          round_up(ctas_along_m, (1 << log_swizzle_size) * cluster_shape.m());
      problem_blocks_n =
          round_up(ctas_along_n, (1 << log_swizzle_size) * cluster_shape.n());
      group_info.total_tiles = problem_blocks_m * problem_blocks_n;
    }

    uint64_t cluster_id, cluster_major_offset = 0, cluster_minor_offset = 0;
    uint64_t blk_per_grid_dim = divmod_cluster_shape_minor.divide(
        linear_idx - group_info.start_linear_idx);
    divmod_cluster_shape_major(cluster_id, cluster_major_offset,
                               blk_per_grid_dim);

    // With static schedulers, we launch grid such that all cluster are linear
    // (1-D) order, i.e., there can only be one cluster in the minor dimension.
    // get_grid_shape() in scheduler params put cluster_shape.m/n() as the minor
    // dimension based on raster order AlongN/M resp. Therefore, the offset of a
    // CTA (inside a cluster) in the minor dimension can be directly be inferred
    // by the blockIdx along the minor dimension.
    if (raster_order == RasterOrder::AlongN) {
      cluster_minor_offset = BlockIdxX();
    } else {
      cluster_minor_offset = BlockIdxY();
    }

    uint64_t cluster_idx_minor, cluster_idx_major;

    uint64_t cluster_idx_minor_div_swizzle, extra, offset;

    offset = cluster_id & ((1 << log_swizzle_size) - 1);
    extra = cluster_id >> log_swizzle_size;

    uint64_t curr_group_cluster_blk_major;
    if (raster_order == RasterOrder::AlongN) {
      curr_group_cluster_blk_major =
          divmod_cluster_shape_major.divide(problem_blocks_n);
    } else {
      curr_group_cluster_blk_major =
          divmod_cluster_shape_major.divide(problem_blocks_m);
    }
    cluster_idx_minor_div_swizzle = extra / curr_group_cluster_blk_major;
    cluster_idx_major = extra % curr_group_cluster_blk_major;

    cluster_idx_minor =
        cluster_idx_minor_div_swizzle * (1 << log_swizzle_size) + offset;

    auto minor_work_idx = static_cast<int32_t>(
        cluster_idx_minor * divmod_cluster_shape_minor.divisor +
        cluster_minor_offset);
    auto major_work_idx = static_cast<int32_t>(
        cluster_idx_major * divmod_cluster_shape_major.divisor +
        cluster_major_offset);

    if (raster_order == RasterOrder::AlongN) {
      return {minor_work_idx, major_work_idx, group_info.group_idx, valid_tile};
    } else {
      return {major_work_idx, minor_work_idx, group_info.group_idx, valid_tile};
    }
  }

  // Kernel helper function to get next work tile
  CUTLASS_DEVICE
  auto fetch_next_work(WorkTileInfo work_tile_info) {
    advance_to_next_work();
    return get_current_work();
  }

  // Returns the initial work tile info that will be computed over
  template <class ClusterShape>
  CUTLASS_DEVICE WorkTileInfo initial_work_tile_info(ClusterShape) {
    return get_current_work();
  }
};

} // namespace MoE
