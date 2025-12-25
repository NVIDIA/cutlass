/***************************************************************************************************
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
#include <gtest/gtest.h>
#include "cutlass/layout/matrix.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/collective/collective_mma.hpp"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/collective/xe_array_epilogue.hpp"
#include "cutlass/epilogue/fusion/xe_callbacks.hpp"
#include "cutlass/gemm/group_array_problem_shape.hpp"
#include "gemm_testbed_3x_ptr_array.hpp"

using namespace cute;
using ProblemShape = cutlass::gemm::GroupProblemShape<Shape<int,int,int>>; // <M,N,K> per group

using ElementAccumulator = float;
using ElementComputeEpilogue = float;
using ElementA = float_e4m3_t;
using ElementB = float_e4m3_t;
using ElementOutput = float;

// FP8 Grouped GEMM config for Xe
template<typename LayoutA, typename LayoutB>
struct MainloopIntelXeXMX16GroupFP8_GemmConfig {
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using GmemTiledCopyA = XE_2D_U8x32x32_LD_N;
  using GmemTiledCopyB = XE_2D_U8x32x32_LD_V;

  using TileShape = Shape<_256, _256, _32>;

  using TiledMma =
      TiledMMA<MMA_Atom<XE_8x16x16_F32F16F16F32_TT>,
               Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>,
               Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                    Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, _32>>;

  constexpr static int PipelineStages = 2;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16GroupFP8<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16Group;

  using EpilogueOp = cutlass::epilogue::fusion::LinearCombination<ElementOutput, ElementComputeEpilogue,
          ElementAccumulator, ElementAccumulator, cutlass::FloatRoundStyle::round_to_nearest>;

  using FusionCallBacks = cutlass::epilogue::fusion::FusionCallbacks<EpilogueDispatchPolicy, EpilogueOp, TileShape,
          decltype(tile_shape(TiledMma()))>;
  using CollectiveEpilogue = cutlass::epilogue::collective::CollectiveEpilogue<
          EpilogueDispatchPolicy,
          TileShape,
          ElementAccumulator,
          cutlass::gemm::TagToStrideC_t<LayoutC*>,
          ElementOutput,
          cutlass::gemm::TagToStrideC_t<LayoutD*>,
          FusionCallBacks,
          XE_2D_U32x8x16_LD_N,
          void, void,
          XE_2D_U32x8x16_ST_N,
          void, void>;

  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
          GEMMDispatchPolicy,
          TileShape,
          ElementA,
          cutlass::gemm::TagToStrideA_t<LayoutA*>,
          ElementB,
          cutlass::gemm::TagToStrideB_t<LayoutB*>,
          TiledMma,
          GmemTiledCopyA, void, void, cute::identity,
          GmemTiledCopyB, void, void, cute::identity
  >;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    ProblemShape,
    CollectiveMainloop,
    CollectiveEpilogue,
    cutlass::gemm::GroupScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
};

// Basic grouped FP8 test
TEST(MainloopIntelXeXMX16GroupFP8_Special, GroupedGemm_Basic) {
  using Gemm = typename MainloopIntelXeXMX16GroupFP8_GemmConfig<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  int groups = 2, m = 512, n = 512, k = 1024;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes;
  for (int i = 0; i < groups; ++i) {
    problem_sizes.push_back({m, n, k});
  }
  EXPECT_TRUE(test::gemm::device::TestXeGrouped<Gemm>(problem_sizes, 1.0f, 0.0f));
}

// Single group, small square
TEST(MainloopIntelXeXMX16GroupFP8_Special, SingleGroup_SmallSquare) {
  using Gemm = typename MainloopIntelXeXMX16GroupFP8_GemmConfig<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  int groups = 1, m = 128, n = 128, k = 128;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes;
  for (int i = 0; i < groups; ++i) {
    problem_sizes.push_back({m, n, k});
  }
  EXPECT_TRUE(test::gemm::device::TestXeGrouped<Gemm>(problem_sizes, 1.0f, 0.0f));
}

// Two groups, rectangular
TEST(MainloopIntelXeXMX16GroupFP8_Special, TwoGroups_Rectangular) {
  using Gemm = typename MainloopIntelXeXMX16GroupFP8_GemmConfig<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  int groups = 2;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes;
  problem_sizes.push_back({256, 128, 64});
  problem_sizes.push_back({128, 256, 64});
  EXPECT_TRUE(test::gemm::device::TestXeGrouped<Gemm>(problem_sizes, 1.0f, 0.0f));
}
 
