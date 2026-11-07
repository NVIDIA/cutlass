/***************************************************************************************************
* Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

/*! \file
    \brief Host-side checks that the SM90 grouped scheduler's tile count matches
    the device-side per-group computation, including swizzle rounding.
*/

#include "../common/cutlass_unit_test.h"

#include "cutlass/pipeline/pipeline.hpp"
#include "cutlass/gemm/kernel/sm90_tile_scheduler_group.hpp"
#include "cutlass/gemm/group_array_problem_shape.hpp"
#include "cutlass/kernel_hardware_info.hpp"

#include <cute/tensor.hpp>

using namespace cute;

namespace {

using ProblemShape = Shape<int, int, int>;
using GroupShapes = cutlass::gemm::GroupProblemShape<ProblemShape>;
using Scheduler = cutlass::gemm::kernel::detail::PersistentTileSchedulerSm90Group<GroupShapes, 2>;

uint64_t expected_group_tiles(int m, int n, int cta_m, int cta_n, int cluster_m, int cluster_n, int max_swizzle) {
  int cm = (m + cta_m - 1) / cta_m; if (cm <= 0) { cm = 1; }
  int cn = (n + cta_n - 1) / cta_n; if (cn <= 0) { cn = 1; }

  int log_swizzle = Scheduler::get_log_swizzle_size(cm, cn, max_swizzle);
  int mult = 1 << log_swizzle;

  uint64_t blocks_m = ((cm + mult * cluster_m - 1) / (mult * cluster_m)) * uint64_t(mult * cluster_m);
  uint64_t blocks_n = ((cn + mult * cluster_n - 1) / (mult * cluster_n)) * uint64_t(mult * cluster_n);
  return blocks_m * blocks_n;
}

} // namespace

// Regression test for #3497: the host-side tile count must apply the same
// per-group swizzle rounding as the device mapping, otherwise groups after a
// swizzled one shift past blocks_across_problem_ and their tail tiles are
// never scheduled.
TEST(Sm90GroupTileScheduler, host_tile_count_matches_device_formula) {
  ProblemShape shapes[] = {{128, 128, 32}, {192, 192, 32}};   // 2x2 and 3x3 CTAs of 64
  GroupShapes ps;
  ps.num_groups = 2;
  ps.host_problem_shapes = shapes;

  cutlass::KernelHardwareInfo hw;
  hw.sm_count = 148;

  auto cta_shape = Shape<_64, _64, _8>{};
  auto cluster = Shape<_1, _1, _1>{};

  for (int swz : {1, 2, 4, 8}) {
    dim3 got = Scheduler::get_tiled_cta_shape_mnl(ps, hw, cta_shape, cluster, swz);

    uint64_t want = expected_group_tiles(128, 128, 64, 64, 1, 1, swz)
                  + expected_group_tiles(192, 192, 64, 64, 1, 1, swz);

    EXPECT_EQ(uint64_t(got.x) * got.y * got.z, want) << "swz=" << swz;
  }
}

TEST(Sm90GroupTileScheduler, host_tile_count_matches_device_formula_sweep) {
  struct Case {
    int groups[4][2];
    int num_groups;
    int cluster_m, cluster_n;
  };

  Case cases[] = {
    {{{37, 41}, {5, 130}, {64, 3}, {17, 17}}, 4, 1, 1},
    {{{128, 64}, {96, 256}},                 2, 2, 1},
    {{{70, 70}, {33, 200}, {8, 8}},          3, 1, 2},
    {{{256, 256}, {1, 1}, {129, 65}, {7, 9}}, 4, 2, 2},
  };

  cutlass::KernelHardwareInfo hw;
  hw.sm_count = 132;

  for (auto const &c : cases) {
    ProblemShape shapes[4];
    for (int g = 0; g < c.num_groups; ++g) {
      shapes[g] = {c.groups[g][0], c.groups[g][1], 32};
    }
    GroupShapes ps;
    ps.num_groups = c.num_groups;
    ps.host_problem_shapes = shapes;

    auto cta_shape = Shape<_64, _64, _8>{};
    auto cluster = make_shape(c.cluster_m, c.cluster_n, _1{});

    for (int swz : {1, 2, 4, 8}) {
      dim3 got = Scheduler::get_tiled_cta_shape_mnl(ps, hw, cta_shape, cluster, swz);

      uint64_t want = 0;
      for (int g = 0; g < c.num_groups; ++g) {
        want += expected_group_tiles(c.groups[g][0], c.groups[g][1], 64, 64,
                                     c.cluster_m, c.cluster_n, swz);
      }

      EXPECT_EQ(uint64_t(got.x) * got.y * got.z, want)
          << "groups=" << c.num_groups << " cluster=(" << c.cluster_m << "," << c.cluster_n << ")"
          << " swz=" << swz;
    }
  }
}
