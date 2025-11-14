/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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


#include "cutlass/cutlass.h"
#include "cutlass/fast_math.h"
#include "cutlass/kernel_hardware_info.h"

namespace cutlass::fmha::kernel {

struct XeFHMAIndividualTileScheduler {

  struct Params {
    dim3 grid;
    FastDivmod divmod_num_heads;
  };

  bool valid_ = true;
  Params params;

  CUTLASS_DEVICE
  XeFHMAIndividualTileScheduler(Params const& params) : params(params) {}

  template <class ProblemShape, class TileShape>
  static Params to_underlying_arguments(
      ProblemShape const& shape, KernelHardwareInfo hw_info,
      TileShape const& tile_shape)
  {
    using namespace cute;

    dim3 grid(size(ceil_div(shape.head_size_vo, get<1>(tile_shape))),     // V
              size(ceil_div(shape.seq_len_qo,   get<0>(tile_shape))),     // Q
              size(shape.batch * shape.num_heads_q));                     // (h,b) -- split later
    return Params{grid, {shape.num_heads_q}};
  }

  template <int Num_SGs>
  static dim3 get_grid_shape(Params const& params) {
    return params.grid;
  }

  CUTLASS_DEVICE
  bool is_valid() {
    return valid_;
  }

  CUTLASS_DEVICE
  auto get_block_coord() {
    using namespace cute;
    int idx_b = BlockIdxZ();
    int head;
    params.divmod_num_heads(idx_b, head, idx_b);
    return make_coord(BlockIdxY(), BlockIdxX(), head, idx_b);
  }

  CUTLASS_DEVICE
  XeFHMAIndividualTileScheduler& operator++() {
    valid_ = false;
    return *this;
  }
};

struct XeFHMAIndividualPersistentTileScheduler {

  struct Params {
    dim3 grid;
    FastDivmod divmod_num_heads;
  };

  bool valid_ = true;
  Params params;
  int kv_tile_size_;
  // num of kv blocks for each head
  int local_num_kv_blocks_;
  int num_batch_heads_;

  CUTLASS_DEVICE
  XeFHMAIndividualPersistentTileScheduler(Params const& params, int kv_tile_size,
    int local_num_kv_blocks, int num_batch_heads)
    : params(params), kv_tile_size_(kv_tile_size), local_num_kv_blocks_(local_num_kv_blocks), num_batch_heads_(num_batch_heads) {}

  template <class ProblemShape, class TileShape>
  static Params to_underlying_arguments(
      ProblemShape const& shape, KernelHardwareInfo hw_info,
      TileShape const& tile_shape)
  {
    using namespace cute;

    dim3 grid(size(ceil_div(shape.head_size_vo, get<1>(tile_shape))),     // V
              size(ceil_div(shape.seq_len_qo,   get<0>(tile_shape))),     // Q
              size(shape.batch * shape.num_heads_q));                     // (h,b) -- split later
    int num_heads = shape.num_heads_q;
    grid.z = hw_info.sm_count;

    return Params{grid, {num_heads}};
  }

  template <int Num_SGs>
  static dim3 get_grid_shape(Params const& params) {
    return params.grid;
  }

  CUTLASS_DEVICE
  bool is_valid() {
    return valid_;
  }

  CUTLASS_DEVICE
  auto get_block_coord() {
    using namespace cute;
    int wg_id = BlockIdxZ();

    // total number of blocks need to be processed across all wgs
    int total_num_kv_blocks = local_num_kv_blocks_ * num_batch_heads_;
    // guarantee all wg process similar number of blocks of KV (load balance)
    int num_blocks_per_wg = cute::ceil_div(total_num_kv_blocks, GridDimZ());

    // compute start batch head id for current wg
    int start_batch_head_id = wg_id * num_blocks_per_wg / local_num_kv_blocks_;

    return make_coord(BlockIdxY(), BlockIdxX(), start_batch_head_id);
  }

  CUTLASS_DEVICE
  XeFHMAIndividualPersistentTileScheduler& operator++() {
    valid_ = false;
    return *this;
  }
};

}  // namespace cutlass::fmha::kernel
