/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/gemm/kernel/tile_scheduler.hpp"

// A version of Persistent Group scheduler that preserves multimodal tiling
template <class GroupProblemShape, uint32_t SchedulerPipelineStageCount, class TileShape>
class PersistentTileSchedulerSm90GroupTileShapeDependent
: public cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90Group<GroupProblemShape, SchedulerPipelineStageCount> {

public:

  static_assert(cute::is_static_v<TileShape>, "TileShape must be static");

  using Base = cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90Group<GroupProblemShape, SchedulerPipelineStageCount>;
  using Base::Base;
  using WorkTileInfo = typename Base::WorkTileInfo;

  // Customize this function to pass static (hierarchical) tile shape instead of dynamic flattened tile shape
  CUTLASS_DEVICE
  WorkTileInfo
  get_current_work_for_linear_idx(uint64_t linear_idx) {
    if (this->scheduler_params.pre_processed_problem_shapes && linear_idx >= this->scheduler_params.blocks_across_problem_) {
      return WorkTileInfo::invalid_work_tile();
    }

    return this->template get_work_idx_m_and_n<WorkTileInfo>(
      linear_idx,
      this->current_group_info_,
      this->scheduler_params.problem_shapes_,
      this->cached_problem_shapes_,
      TileShape{},
      this->scheduler_params.cluster_shape_,
      this->scheduler_params.divmod_cluster_shape_major_,
      this->scheduler_params.divmod_cluster_shape_minor_,
      this->scheduler_params.divmod_cta_shape_m_,
      this->scheduler_params.divmod_cta_shape_n_,
      this->scheduler_params.max_swizzle_size_, 
      this->scheduler_params.raster_order_);
  }

  // Must re-implement every function that calls get_current_work_for_linear_idx() to get the call to resolve to correct version

  template <typename TileSchedulerPipeline, typename TileSchedulerPipelineState,
            typename CallbackBeforeCommit = WorkTileInfo(*)(WorkTileInfo)>
  CUTLASS_DEVICE
  auto
  advance_to_next_work(
    TileSchedulerPipeline& scheduler_pipeline,
    TileSchedulerPipelineState scheduler_pipe_producer_state,
    uint32_t advance_count = 1,
    CallbackBeforeCommit callback_before_commit = [] (WorkTileInfo info) { return info; }) {

    this->current_work_linear_idx_ += this->total_grid_size_ * uint64_t(advance_count);
    auto work_tile = get_current_work_for_linear_idx(this->current_work_linear_idx_);
    using WorkTileWithCallbackInfo = decltype(callback_before_commit(work_tile));
    WorkTileWithCallbackInfo work_tile_with_callback_info = work_tile;
    scheduler_pipeline.producer_acquire(scheduler_pipe_producer_state);
    if (work_tile_with_callback_info.is_valid()) {
      work_tile_with_callback_info = callback_before_commit(work_tile);
    }
    if (cute::elect_one_sync()) {
      reinterpret_cast<WorkTileWithCallbackInfo *>(this->response_ptr_)[scheduler_pipe_producer_state.index()] = work_tile_with_callback_info;
      cutlass::arch::fence_view_async_shared();
      scheduler_pipeline.producer_commit(scheduler_pipe_producer_state);
    }
    return cute::make_tuple(work_tile_with_callback_info, true);
  }
  
  // Returns the initial work tile info that will be computed over
  template <class ClusterShape>
  CUTLASS_DEVICE
  WorkTileInfo
  initial_work_tile_info(ClusterShape) {
    return get_current_work_for_linear_idx(this->current_work_linear_idx_);
  }
};

// Derives from GroupScheduler so the cooperative kernel's scheduler-compatibility
// static_assert (is_base_of_v<GroupScheduler, TileScheduler_>) accepts this tag.
struct GroupSchedulerTileShapeDependent : cutlass::gemm::GroupScheduler {};

namespace cutlass::gemm::kernel::detail {

template <
  class TileShape,
  class ClusterShape,
  uint32_t SchedulerPipelineStageCount,
  class GroupProblemShape
>
struct TileSchedulerSelector<
    GroupSchedulerTileShapeDependent,
    arch::Sm90,
    TileShape,
    ClusterShape
    , SchedulerPipelineStageCount
    , GroupProblemShape
  > {
  using Scheduler = PersistentTileSchedulerSm90GroupTileShapeDependent<GroupProblemShape, SchedulerPipelineStageCount, TileShape>;
};

}
