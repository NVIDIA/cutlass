/***************************************************************************************************
 * Copyright 2025 Intel corporation. All rights reserved.
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

#include "cute/tensor.hpp"
#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/group_array_problem_shape.hpp"
#include "cutlass/gemm/kernel/tile_scheduler.hpp"
#include "cutlass/kernel_hardware_info.hpp"
#include "cutlass/platform/platform.h"
#include "moe_gemms.hpp"
#include "moe_tile_scheduler.hpp"
#include <cute/util/compat.hpp>

#pragma clang diagnostic ignored "-Wpass-failed"
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

namespace MoE {
using namespace cute;

using ProblemShapeMNKL = Shape<int, int, int, int>;
using ProblemShape = cutlass::gemm::GroupProblemShape<Shape<int, int, int>>;
using TileScheduler = typename MoE::PersistentTileSchedulerXeMoE<ProblemShape>;
using RasterOrderOptions = typename TileScheduler::RasterOrderOptions;

template <typename T, char LayoutKind>
CUTE_DEVICE auto make_moe_tensor(T *ptr, int r, int c) {
  auto shape = make_shape(r, c);
  if constexpr (LayoutKind == 'C')
    return make_tensor(make_gmem_ptr<T>(ptr),
                       make_layout(shape, make_stride(_1{}, r)));
  else
    return make_tensor(make_gmem_ptr<T>(ptr),
                       make_layout(shape, make_stride(c, _1{})));
}

template <class GmemTiledCopyA, class GmemTiledCopyB, class GmemTiledCopyD,
          char LayoutKindA, char LayoutKindB, char LayoutKindD, class TiledMMA,
          typename ElementA, typename ElementB, typename ElementS,
          typename ElementD>
CUTE_DEVICE void
MoEGEMM(const ElementA *Activations, const ElementB *Weights,
        const ElementS *Scales, ElementD *Outputs, TiledMMA const &mma,
        const int32_t *M_per_group, const int32_t num_experts, const int32_t N,
        const int32_t K,
        PersistentTileSchedulerSm90GroupParams<ProblemShape> scheduler_params) {

  TileScheduler scheduler{scheduler_params, const_cast<int32_t *>(M_per_group),
                          N, K, num_experts};

  auto work_tile_info = scheduler.initial_work_tile_info(Shape<_1, _1, _1>{});
  constexpr char actual_layout_of_B = LayoutKindB ^ ('R' ^ 'C');
  bool did_group_change = true;
  int32_t curr_group = 0;
  int32_t prev_group = 0;
  int32_t cumulative_M = 0;
  int32_t M = 0;

  if (work_tile_info.is_valid()) {
    // We don't really need this conditional outside the while loop.
    // It simply helps initialize tensors. If using nullptr would be
    // fine for their initialization, then we can remove this conditional.
    curr_group = work_tile_info.L_idx;
    M = M_per_group[curr_group];
  }

  auto A_tensor = make_moe_tensor<ElementA, LayoutKindA>(
      const_cast<ElementA *>(Activations), M, K);
  auto B_tensor = make_moe_tensor<ElementB, actual_layout_of_B>(
      const_cast<ElementB *>(Weights), N, K);
  auto D_tensor = make_moe_tensor<ElementD, LayoutKindD>(Outputs, M, N);

  while (work_tile_info.is_valid()) {
    auto m_coord = work_tile_info.M_idx;
    auto n_coord = work_tile_info.N_idx;
    auto tile_coord = make_coord(m_coord, n_coord, _, 0);

    if (did_group_change) {
      curr_group = work_tile_info.L_idx;
      M = M_per_group[curr_group];
      // recompute each time because the groups don't necessarily increment by 1
      for (int i = prev_group; i < curr_group; i++) {
        cumulative_M += M_per_group[i];
      }
      prev_group = curr_group;

      ElementA *ptr_A_curr_batch =
          const_cast<ElementA *>(Activations) + cumulative_M * K;
      ElementB *ptr_B_curr_batch =
          const_cast<ElementB *>(Weights) + curr_group * K * N;
      ElementD *ptr_D_curr_batch = Outputs + cumulative_M * N;

      A_tensor = make_moe_tensor<ElementA, LayoutKindA>(ptr_A_curr_batch, M, K);
      B_tensor =
          make_moe_tensor<ElementB, actual_layout_of_B>(ptr_B_curr_batch, N, K);
      D_tensor = make_moe_tensor<ElementD, LayoutKindD>(ptr_D_curr_batch, M, N);
      did_group_change = false;
    }

    // After adding scaledMM mainloops, add something like
    // if constexpr (!cute::is_void_v<ElementS>) {
    //   moe_gemm<GmemTiledCopyA, GmemTiledCopyB, GmemTiledCopyD>(
    //      A_tensor, B_tensor, Scales, D_tensor, tile_coord, mma);
    // } else {
    moe_gemm<GmemTiledCopyA, GmemTiledCopyB, GmemTiledCopyD>(
        A_tensor, B_tensor, D_tensor, tile_coord, mma);

    // Get next work tile
    auto next_work_tile_info = scheduler.fetch_next_work(work_tile_info);
    work_tile_info = next_work_tile_info;
    did_group_change = curr_group != work_tile_info.L_idx;
  } // end while loop
}

} // namespace MoE
