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
#include "cute/tensor.hpp"
#include "cute/arch/cluster_sm90.hpp"

namespace cutlass::gemm::kernel::detail {

///////////////////////////////////////////////////////////////////////////////

// Persistent Thread Block (TB) scheduler
class PersistentTileSchedulerSm90 {
  //
  // Data members
  //

private:
  uint64_t current_work_linear_idx_;

public:
  struct WorkTileInfo {
    int32_t M_idx = 0;
    int32_t N_idx = 0;
    int32_t L_idx = 0;
    bool is_valid_tile = false;
  };

  //
  // Methods
  //

  enum class RasterOrder {
    AlongM,
    AlongN
  };

  struct Arguments {
    int max_swizzle_size = 1;
  };

  struct Params {

    FastDivmodU64 divmod_cluster_shape_major_{};
    FastDivmodU64 divmod_cluster_shape_minor_{};
    FastDivmodU64 divmod_batch_{};
    FastDivmodU64 divmod_cluster_blk_major_{};

    uint64_t blocks_per_problem_ = 0;
    int32_t log_swizzle_size_ = 0;
    RasterOrder raster_order_ = RasterOrder::AlongN;
  };
  // Sink scheduler params as a member
  Params scheduler_params;

  //
  // Methods
  //

  template <class ProblemShapeMNKL, class TileShape, class ClusterShape>
  static Params
  to_underlying_arguments(
    ProblemShapeMNKL problem_shape_mnkl,
    TileShape tile_shape,
    ClusterShape cluster_shape,
    [[maybe_unused]] KernelHardwareInfo const& hw_info,
    Arguments const& arguments,
    [[maybe_unused]] void* workspace=nullptr) {

    // We only need the tile and cluster shape during scheduler setup, so let FTAD do the magic
    static_assert(cute::is_static<TileShape>::value);
    static_assert(cute::is_static<ClusterShape>::value);

    // Round up to nearest multiple of cluster dim along each mode
    auto [problem_blocks_m, problem_blocks_n, problem_blocks_l] = get_tiled_cta_shape_mnl(
        problem_shape_mnkl, tile_shape, cluster_shape);

    // Round up to nearest multiple of swizzle_size along each mode
    auto log_swizzle_size = get_log_swizzle_size(problem_blocks_m, problem_blocks_n, arguments.max_swizzle_size);
    problem_blocks_m = round_up(problem_blocks_m, (1 << log_swizzle_size) * cute::size<0>(cluster_shape));
    problem_blocks_n = round_up(problem_blocks_n, (1 << log_swizzle_size) * cute::size<1>(cluster_shape));
  

    RasterOrder raster_order;
    raster_order = get_rasterization_order(problem_shape_mnkl, tile_shape);
    if (raster_order == RasterOrder::AlongN) {
      return {
        FastDivmodU64(cute::size<1>(cluster_shape)),
        FastDivmodU64(cute::size<0>(cluster_shape)),
        FastDivmodU64(problem_blocks_m * problem_blocks_n),
        FastDivmodU64(problem_blocks_n / cute::size<1>(cluster_shape)),
        problem_blocks_m * problem_blocks_n * problem_blocks_l,
        log_swizzle_size,
        raster_order
      };
    }
    else {
      return {
        FastDivmodU64(cute::size<0>(cluster_shape)),
        FastDivmodU64(cute::size<1>(cluster_shape)),
        FastDivmodU64(problem_blocks_m * problem_blocks_n),
        FastDivmodU64(problem_blocks_m / cute::size<0>(cluster_shape)),
        problem_blocks_m * problem_blocks_n * problem_blocks_l,
        log_swizzle_size,
        raster_order
      };
    }
  }

  CUTLASS_HOST_DEVICE
  PersistentTileSchedulerSm90() { };

  CUTLASS_DEVICE explicit PersistentTileSchedulerSm90(Params const& params_) : scheduler_params(params_) {
    // MSVC requires protecting use of CUDA-specific nonstandard syntax,
    // like blockIdx and gridDim, with __CUDA_ARCH__.
#if defined(__CUDA_ARCH__)
    if (params_.raster_order_ == RasterOrder::AlongN) {
      current_work_linear_idx_ = static_cast<uint64_t>(int(blockIdx.x) + (int(blockIdx.y) * int(gridDim.x)));
    }
    else {
      current_work_linear_idx_ = static_cast<uint64_t>((int(blockIdx.x) * int(gridDim.y)) + int(blockIdx.y));
    }
#else
    CUTLASS_ASSERT(false && "This line should never be reached");
#endif
  }

  CUTLASS_DEVICE
  WorkTileInfo
  get_current_work() const {
    return get_current_work_for_linear_idx(current_work_linear_idx_);
  }

  CUTLASS_DEVICE
  WorkTileInfo
  get_current_work_for_linear_idx(uint64_t linear_idx) const {
    // Map worker's linear index into the CTA tiled problem shape to the corresponding MNL indices
    uint64_t work_idx_l, remainder;
    scheduler_params.divmod_batch_(work_idx_l, remainder, linear_idx);

    uint64_t blk_per_grid_dim = scheduler_params.divmod_cluster_shape_minor_.divide(remainder);

    auto [work_idx_m, work_idx_n] = get_work_idx_m_and_n(blk_per_grid_dim,
                                                         scheduler_params.divmod_cluster_shape_major_,
                                                         scheduler_params.divmod_cluster_shape_minor_,
                                                         scheduler_params.divmod_cluster_blk_major_,
                                                         scheduler_params.log_swizzle_size_, 
                                                         scheduler_params.raster_order_);

    return {work_idx_m, work_idx_n, static_cast<int32_t>(work_idx_l), linear_idx < scheduler_params.blocks_per_problem_};
  }

  CUTLASS_DEVICE
  void
  advance_to_next_work(uint32_t advance_count = 1) {
    // MSVC requires protecting use of CUDA-specific nonstandard syntax,
    // like blockIdx and gridDim, with __CUDA_ARCH__.
#if defined(__CUDA_ARCH__)
    current_work_linear_idx_ += static_cast<uint64_t>(int(gridDim.x) * int(gridDim.y) * int(gridDim.z)) * advance_count;
#else
    CUTLASS_ASSERT(false && "This line should never be reached");
#endif
  }

  // get work_idx_m, work_idx_n from blk_per_grid_dim while applying swizzle
  static CUTLASS_DEVICE
  cute::tuple<int32_t, int32_t>
  get_work_idx_m_and_n(
      uint64_t blk_per_grid_dim, 
      FastDivmodU64 const& divmod_cluster_shape_major,
      FastDivmodU64 const& divmod_cluster_shape_minor,
      FastDivmodU64 const& divmod_cluster_blk_major,
      int32_t log_swizzle_size, 
      RasterOrder raster_order) {

    uint64_t cluster_id, cluster_major_offset = 0, cluster_minor_offset = 0;
    divmod_cluster_shape_major(cluster_id, cluster_major_offset, blk_per_grid_dim);

    auto [cta_m_in_cluster, cta_n_in_cluster, _] = cute::block_id_in_cluster();
    if (raster_order == RasterOrder::AlongN) {
      cluster_minor_offset = cta_m_in_cluster;
    }
    else {
      cluster_minor_offset = cta_n_in_cluster;
    }

    uint64_t cluster_idx_minor, cluster_idx_major;
    
    uint64_t cluster_idx_minor_div_swizzle, extra, offset;

    offset = cluster_id & ((1 << log_swizzle_size) - 1);
    extra = cluster_id >> log_swizzle_size;
    
    divmod_cluster_blk_major(cluster_idx_minor_div_swizzle, cluster_idx_major, extra);

    cluster_idx_minor = cluster_idx_minor_div_swizzle * (1 << log_swizzle_size) + offset;

    auto minor_work_idx = static_cast<int32_t>(cluster_idx_minor * divmod_cluster_shape_minor.divisor + 
                                               cluster_minor_offset);
    auto major_work_idx = static_cast<int32_t>(cluster_idx_major * divmod_cluster_shape_major.divisor + 
                                               cluster_major_offset);

    if (raster_order == RasterOrder::AlongN) {
      return {minor_work_idx, major_work_idx};
    }
    else {
      return {major_work_idx, minor_work_idx}; 
    }

  }

  // Given the inputs, computes the total number of output blocks this problem will compute over
  // Note that this is only the logical size of our grid, not the physical grid we will actually launch.
  template<class ProblemShapeMNKL, class BlockShape, class ClusterShape>
  CUTLASS_HOST_DEVICE static
  dim3
  get_tiled_cta_shape_mnl(ProblemShapeMNKL problem_shape_mnkl, BlockShape cta_shape, ClusterShape cluster_shape) {
    // Across M and N is our Cluster tile, so we must round up the blocks to the nearest whole number of Cluster tiles
    auto cta_m = cute::size(cute::ceil_div(cute::shape<0>(problem_shape_mnkl), cute::shape<0>(cta_shape)));
    auto cta_n = cute::size(cute::ceil_div(cute::shape<1>(problem_shape_mnkl), cute::shape<1>(cta_shape)));

    // Round up to nearest multiple of cluster dim along each mode
    int problem_blocks_m = round_up(cta_m, cute::size<0>(cluster_shape));
    int problem_blocks_n = round_up(cta_n, cute::size<1>(cluster_shape));

    // Cluster tile does not span the batch mode, so no extra rounding up required for it
    int problem_blocks_l = int(cute::size<3>(problem_shape_mnkl));
    return {uint32_t(problem_blocks_m), uint32_t(problem_blocks_n), uint32_t(problem_blocks_l)};
  }

  CUTLASS_HOST_DEVICE 
  static int32_t 
  get_log_swizzle_size(int problem_ctas_m, int problem_ctas_n, int max_swizzle_size) {
    int min_cta_dim = min(problem_ctas_m, problem_ctas_n);
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

  // Given the inputs, computes the physical grid we should launch.
  template<class ProblemShapeMNKL, class BlockShape, class ClusterShape>
  CUTLASS_HOST_DEVICE static
  dim3
  get_grid_shape(
    ProblemShapeMNKL problem_shape_mnk,
    BlockShape cta_shape,
    ClusterShape cluster_shape,
    KernelHardwareInfo hw_info,
    Arguments arguments,
    bool truncate_by_problem_size=true) {

    int const sm_count = hw_info.sm_count;
    CUTLASS_TRACE_HOST("get_grid_shape(): Persistent schedule grid plan using SM count = " << sm_count);

    // Compute the total number of output tiles our problem has
    auto problem_shape_MNKL = cute::append<4>(problem_shape_mnk, cute::Int<1>{});
    auto [problem_blocks_m, problem_blocks_n, problem_blocks_l] =
        get_tiled_cta_shape_mnl(problem_shape_MNKL, cta_shape, cluster_shape);
    
    // Round up to nearest multiple of swizzle_size along each mode
    auto swizzle_size = 1 << get_log_swizzle_size(problem_blocks_m, problem_blocks_n, arguments.max_swizzle_size);
    problem_blocks_m = round_up(problem_blocks_m, swizzle_size * cute::size<0>(cluster_shape));
    problem_blocks_n = round_up(problem_blocks_n, swizzle_size * cute::size<1>(cluster_shape));

    int problem_blocks_total = problem_blocks_m * problem_blocks_n * problem_blocks_l;

    RasterOrder raster_order;
    raster_order = get_rasterization_order(problem_shape_mnk, cta_shape);
    dim3 launch_grid;

    if (raster_order == RasterOrder::AlongN) {
      launch_grid = dim3(cute::size<0>(cluster_shape), 1, 1);
    }
    else {
      launch_grid = dim3(1, cute::size<1>(cluster_shape), 1);
    }

    auto possibly_truncate = [&](int x, int y) {
      if (truncate_by_problem_size) {
        return std::min(x, y);
      }
      else {
        return x;
      }
    };

    // The else path is generic, however, we can avoid some divs if we know cluster size is 1
    if constexpr (size(cluster_shape) == 1) {
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
      int const min_num_gpc = sm_count < max_sm_per_gpc ? 1 : sm_count / max_sm_per_gpc;
      int const max_cta_occupancy_per_gpc = max_sm_per_gpc - (max_sm_per_gpc % size(cluster_shape));
      int cta_per_device = min_num_gpc * max_cta_occupancy_per_gpc;

      // The calculation below allows for larger grid size launch for different GPUs.
      int const num_gpc_residual = sm_count < max_sm_per_gpc ? 0 : sm_count % max_sm_per_gpc;
      int const max_cta_occupancy_per_residual_gpc = num_gpc_residual - (num_gpc_residual % size(cluster_shape));
      cta_per_device += max_cta_occupancy_per_residual_gpc;

      cta_per_device = sm_count < cta_per_device ? sm_count : cta_per_device;

      if (raster_order == RasterOrder::AlongN) {
        launch_grid.y = possibly_truncate(
            cta_per_device       / cute::size<0>(cluster_shape),
            problem_blocks_total / cute::size<0>(cluster_shape));
      }
      else {
        launch_grid.x = possibly_truncate(
            cta_per_device       / cute::size<1>(cluster_shape),
            problem_blocks_total / cute::size<1>(cluster_shape));
      }
    }
    return launch_grid;
  }

  template <class ProblemShapeMNKL, class BlockShape>
  CUTLASS_HOST_DEVICE static RasterOrder get_rasterization_order(ProblemShapeMNKL problem_shape_mnkl, BlockShape cta_shape) {
    auto tiles_m = cute::size(cute::ceil_div(cute::shape<0>(problem_shape_mnkl), cute::shape<0>(cta_shape)));
    auto tiles_n = cute::size(cute::ceil_div(cute::shape<1>(problem_shape_mnkl), cute::shape<1>(cta_shape)));

    if (tiles_n > tiles_m) {
      return RasterOrder::AlongM;
    }

    return RasterOrder::AlongN;
  }

  // Splits an input tensor with MxK according to the splitting configuration specified by work_tile_info.
  // Since the basic tile scheduler does not split output tiles, this method is a no-op.
  template<class Engine, class Layout>
  CUTLASS_DEVICE
  static auto
  split_MK(cute::Tensor<Engine, Layout> const& tensor, WorkTileInfo const&) {
    return tensor;
  }

  // Splits an input tensor with NxK tiles according to the splitting configuration specified by work_tile_info.
  // Since the basic tile scheduler does not split output tiles, this method is a no-op.
  template<class Engine, class Layout>
  CUTLASS_DEVICE
  static auto
  split_NK(cute::Tensor<Engine, Layout> const& tensor, WorkTileInfo const&) {
    return tensor;
  }

  // Returns whether the block assigned this work should compute the epilogue for the corresponding
  // output tile. For the basic tile scheduler, this is always true.
  CUTLASS_HOST_DEVICE
  static bool
  compute_epilogue(WorkTileInfo const&) {
    return true;
  }

  // Performs the reduction across splits for a given output tile. Since this scheduler does
  // not split output tiles, no reduction is needed.
  template <class FrgTensorC>
  CUTLASS_DEVICE
  static void
  fixup(Params const&, WorkTileInfo const&, FrgTensorC&, uint32_t, uint32_t) {}

  // Returns whether the current WorkTileInfo passed in should continue to be used. Since
  // this scheduler only schedules work in units of single, full output tiles, the WorkTileInfo
  // passed in should not be used after having been processed.
  CUTLASS_DEVICE
  static bool
  continue_current_work(WorkTileInfo&) {
    return false;
  }

  // The basic tile scheduler does not require any additional workspace
  template <class ProblemShape, class ElementAccumulator>
  static int
  get_workspace_size(Arguments const&, ProblemShape, KernelHardwareInfo const&, uint32_t) {
    return 0;
  }

  template <class ProblemShape, class ElementAccumulator>
  static cutlass::Status
  initialize_workspace(Arguments const&, void*, cudaStream_t, ProblemShape, KernelHardwareInfo const&, uint32_t) {
    return Status::kSuccess;
  }

  template <class ProblemShape, class TileShape>
  CUTLASS_HOST_DEVICE
  static int
  get_work_k_tile_count(WorkTileInfo const& work_tile_info, ProblemShape problem_shape, TileShape tile_shape) {
    // All work units returned by this scheduler cover the entire K iteration
    // space of the output tile assigned to the work unit.
    return cute::size(cute::ceil_div(cute::get<2>(problem_shape), cute::get<2>(tile_shape)));
  }
};

} // namespace cutlass::gemm::kernel::detail
