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
#include <cute/tensor.hpp>

using namespace cute;
using ProblemShape = cutlass::gemm::GroupProblemShape<Shape<int,int,int>>; // <M,N,K> per group

using ElementAccumulator = float;     
using ElementComputeEpilogue = float; 
using ElementA = bfloat16_t;          
using ElementB = bfloat16_t;          
using ElementOutput = float;          

///////////////////////////////////////////////////////////////////////////////////////////////////

template<typename LayoutA, typename LayoutB>
struct MainloopIntelXeXMX16Group_GemmConfig {
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using GmemTiledCopyA = XE_2D_U16x32x32_LD_N;
  using GmemTiledCopyB = XE_2D_U16x32x32_LD_V;

  // Workgroup-level tile
  using TileShape = Shape<_256, _256, _32>;

  using TiledMma =
      TiledMMA<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
               Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>,
               Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                    Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, _32>>;

  constexpr static int PipelineStages = 2;
  // Dispatch to grouped gemm algorithm
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16Group<PipelineStages>;
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

  // Mainloop
  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
          GEMMDispatchPolicy,
          TileShape,
          ElementA,
          cutlass::gemm::TagToStrideA_t<LayoutA*>,
          ElementB,
          cutlass::gemm::TagToStrideB_t<LayoutB*>,
          TiledMma,
          GmemTiledCopyA, void, void, cute::identity,  // A
          GmemTiledCopyB, void, void, cute::identity   // B
  >;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
    ProblemShape,
    CollectiveMainloop,
    CollectiveEpilogue,
    cutlass::gemm::GroupScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
};

// Helper to generate LLM-like grouped GEMM shapes
inline std::vector<cutlass::gemm::GemmCoord> make_llm_grouped_shapes(int groups, int m, int n, int k, int m_stride = 0, int n_stride = 0, int k_stride = 0) {
  std::vector<cutlass::gemm::GemmCoord> shapes;
  for (int i = 0; i < groups; ++i) {
    shapes.emplace_back(
      m + i * m_stride,
      n + i * n_stride,
      k + i * k_stride
    );
  }
  return shapes;
}

// GPT-2: M=1024, N=1024, K=4096, groups=2, with stride in K
TEST(MainloopIntelXeXMX16Group_LLM, GPT2_KStride) {
  using Gemm = typename MainloopIntelXeXMX16Group_GemmConfig<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  int groups = 2, m = 1024, n = 1024, k = 4096, k_stride = 512;
  auto problem_sizes = make_llm_grouped_shapes(groups, m, n, k, 0, 0, k_stride);
  EXPECT_TRUE(test::gemm::device::TestXeGrouped<Gemm>(problem_sizes, 1.0f, 0.0f));
}

// Basic grouped GEMM test
TEST(MainloopIntelXeXMX16Group_NonParam, BasicGroupedGemm) {
  using Gemm = typename MainloopIntelXeXMX16Group_GemmConfig<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes = {
    {256, 256, 256},
    {512, 512, 512}
  };
  EXPECT_TRUE(test::gemm::device::TestXeGrouped<Gemm>(problem_sizes, 1.0f, 0.0f));
}

// Small batch, single group
TEST(MainloopIntelXeXMX16Group_NonParam, SmallBatchSingleGroup) {
  using Gemm = typename MainloopIntelXeXMX16Group_GemmConfig<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes = {
    {128, 128, 512}
  };
  EXPECT_TRUE(test::gemm::device::TestXeGrouped<Gemm>(problem_sizes, 1.0f, 0.0f));
}

// Edge case: zero beta
TEST(MainloopIntelXeXMX16Group_NonParam, ZeroBetaEdgeCase) {
  using Gemm = typename MainloopIntelXeXMX16Group_GemmConfig<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes = {
    {512, 512, 2048},
    {1024, 1024, 4096}
  };
  EXPECT_TRUE(test::gemm::device::TestXeGrouped<Gemm>(problem_sizes, 1.0f, 0.0f));
}

// Edge case: zero alpha
TEST(MainloopIntelXeXMX16Group_NonParam, ZeroAlphaEdgeCase) {
  using Gemm = typename MainloopIntelXeXMX16Group_GemmConfig<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes = {
    {512, 512, 2048},
    {1024, 1024, 4096}
  };
  EXPECT_TRUE(test::gemm::device::TestXeGrouped<Gemm>(problem_sizes, 0.0f, 1.0f));
}

// Edge case: tiny matrices
TEST(MainloopIntelXeXMX16Group_NonParam, TinyMatrices) {
  using Gemm = typename MainloopIntelXeXMX16Group_GemmConfig<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes = {
    {8, 8, 8},
    {16, 16, 16}
  };
  EXPECT_TRUE(test::gemm::device::TestXeGrouped<Gemm>(problem_sizes, 1.0f, 1.0f));
}

// Edge case: large K, small M/N
TEST(MainloopIntelXeXMX16Group_NonParam, LargeKSmallMN) {
  using Gemm = typename MainloopIntelXeXMX16Group_GemmConfig<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  std::vector<cutlass::gemm::GemmCoord> problem_sizes = {
    {32, 32, 8192},
    {64, 64, 16384}
  };
  EXPECT_TRUE(test::gemm::device::TestXeGrouped<Gemm>(problem_sizes, 1.0f, 0.0f));
}
