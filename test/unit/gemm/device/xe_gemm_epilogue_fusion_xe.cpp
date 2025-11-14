/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Intel Corporation. All rights reserved.
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
    \brief Consolidated tests for Xe epilogue fusion operations
    
    This file consolidates tests for various epilogue operations:
    - LinCombTopKSoftmaxCol: Top-K selection with softmax
    - LinCombPerRowBiasEltAct: Per-row bias with element-wise activation (ReLU)
    
    Tests are organized by scenario (Basic, LLaMA2, ZeroBeta, TensorParallel)
    and executed for each epilogue operation to minimize duplication.
*/

#include <gtest/gtest.h>
#include "cutlass/layout/matrix.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/collective/collective_mma.hpp"
#include "cutlass/epilogue/collective/xe_epilogue.hpp"
#include "cutlass/epilogue/fusion/xe_callbacks.hpp"
#include "gemm_testbed_3x.hpp"
#include <cute/tensor.hpp>

using namespace cute;

namespace {

// ===== LinCombTopKSoftmaxCol Configuration =====
template<int TopK, typename LayoutA, typename LayoutB>
struct XeEpilogueFusion_TopKSoftmax_Config {
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using ElementAccumulator = float;
  using ElementComputeEpilogue = float;
  using ElementA = bfloat16_t;
  using ElementB = bfloat16_t;
  using ElementOutput = float;

  using GmemTiledCopyA = XE_2D_U16x32x32_LD_N;
  using GmemTiledCopyB = XE_2D_U16x32x32_LD_V;
  using TileShape = Shape<_256, _256, _32>;

  using TiledMma =
      TiledMMA<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
               Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>,
               Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                    Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, _32>>;

  constexpr static int PipelineStages = 2;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;

  using EpilogueOp = cutlass::epilogue::fusion::LinCombTopKSoftmaxCol<
      TopK, ElementOutput, ElementComputeEpilogue>;

  using FusionCallBacks = cutlass::epilogue::fusion::FusionCallbacks<
      EpilogueDispatchPolicy, EpilogueOp, TileShape,
      decltype(tile_shape(TiledMma()))>;

  using CollectiveEpilogue = cutlass::epilogue::collective::CollectiveEpilogue<
      EpilogueDispatchPolicy, TileShape, ElementAccumulator,
      cutlass::gemm::TagToStrideC_t<LayoutC>, ElementOutput,
      cutlass::gemm::TagToStrideC_t<LayoutD>, FusionCallBacks,
      XE_2D_U32x8x16_LD_N, void, void, XE_2D_U32x8x16_ST_N, void, void>;

  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
      GEMMDispatchPolicy, TileShape, ElementA,
      cutlass::gemm::TagToStrideA_t<LayoutA>, ElementB,
      cutlass::gemm::TagToStrideB_t<LayoutB>, TiledMma,
      GmemTiledCopyA, void, void, cute::identity,
      GmemTiledCopyB, void, void, cute::identity>;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int, int, int, int>, CollectiveMainloop, CollectiveEpilogue>;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
};

// ===== LinCombPerRowBiasEltAct Configuration =====
template<typename LayoutA, typename LayoutB>
struct XeEpilogueFusion_PerRowBias_Config {
  using LayoutC = cutlass::layout::RowMajor;
  using LayoutD = cutlass::layout::RowMajor;

  using ElementAccumulator = float;
  using ElementComputeEpilogue = float;
  using ElementA = bfloat16_t;
  using ElementB = bfloat16_t;
  using ElementOutput = float;
  using ElementBias = float;

  using GmemTiledCopyA = XE_2D_U16x32x32_LD_N;
  using GmemTiledCopyB = XE_2D_U16x32x32_LD_V;
  using TileShape = Shape<_256, _256, _32>;

  using TiledMma =
      TiledMMA<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
               Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>,
               Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                    Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>, _32>>;

  constexpr static int PipelineStages = 2;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;

  using EpilogueOp = cutlass::epilogue::fusion::LinCombPerRowBiasEltAct<
      cutlass::epilogue::thread::ReLu, ElementOutput, ElementComputeEpilogue,
      ElementBias, ElementAccumulator, ElementAccumulator,
      128 / sizeof_bits_v<ElementBias>,
      cutlass::FloatRoundStyle::round_to_nearest>;

  using FusionCallBacks = cutlass::epilogue::fusion::FusionCallbacks<
      EpilogueDispatchPolicy, EpilogueOp, TileShape,
      decltype(tile_shape(TiledMma()))>;

  using CollectiveEpilogue = cutlass::epilogue::collective::CollectiveEpilogue<
      EpilogueDispatchPolicy, TileShape, ElementAccumulator,
      cutlass::gemm::TagToStrideC_t<LayoutC>, ElementOutput,
      cutlass::gemm::TagToStrideC_t<LayoutD>, FusionCallBacks,
      XE_2D_U32x8x16_LD_N, void, void, XE_2D_U32x8x16_ST_N, void, void>;

  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
      GEMMDispatchPolicy, TileShape, ElementA,
      cutlass::gemm::TagToStrideA_t<LayoutA>, ElementB,
      cutlass::gemm::TagToStrideB_t<LayoutB>, TiledMma,
      GmemTiledCopyA, void, void, cute::identity,
      GmemTiledCopyB, void, void, cute::identity>;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      Shape<int, int, int, int>, CollectiveMainloop, CollectiveEpilogue>;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
};

} // namespace

// ===== BASIC TESTS =====

TEST(XeEpilogueFusion_Consolidated, TopKSoftmax_Basic) {
  using Gemm = XeEpilogueFusion_TopKSoftmax_Config<
      2, cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(256, 256, 32, 1, 1.0f, 0.0f));
}

TEST(XeEpilogueFusion_Consolidated, PerRowBias_Basic) {
  using Gemm = XeEpilogueFusion_PerRowBias_Config<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  EXPECT_TRUE((test::gemm::device::TestXe<Gemm, cutlass::epilogue::thread::ReLu>(
      256, 256, 32, 1, 1.0f, 0.0f)));
}

// ===== LLaMA2-7B SCALE TESTS =====

TEST(XeEpilogueFusion_Consolidated, TopKSoftmax_LLaMA2) {
  using Gemm = XeEpilogueFusion_TopKSoftmax_Config<
      2, cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(1024, 1024, 2752, 1, 1.0f, 0.0f));
}

TEST(XeEpilogueFusion_Consolidated, PerRowBias_LLaMA2) {
  using Gemm = XeEpilogueFusion_PerRowBias_Config<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  EXPECT_TRUE((test::gemm::device::TestXe<Gemm, cutlass::epilogue::thread::ReLu>(
      1024, 1024, 2752, 1, 1.0f, 0.0f)));
}

// ===== ZERO BETA EDGE CASE TESTS =====

TEST(XeEpilogueFusion_Consolidated, TopKSoftmax_ZeroBeta) {
  using Gemm = XeEpilogueFusion_TopKSoftmax_Config<
      2, cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(512, 512, 2048, 1, 1.0f, 0.0f));
}

TEST(XeEpilogueFusion_Consolidated, PerRowBias_ZeroBeta) {
  using Gemm = XeEpilogueFusion_PerRowBias_Config<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  EXPECT_TRUE((test::gemm::device::TestXe<Gemm, cutlass::epilogue::thread::ReLu>(
      512, 512, 2048, 1, 1.0f, 0.0f)));
}

// ===== TENSOR PARALLEL CONFIG TESTS =====

TEST(XeEpilogueFusion_Consolidated, TopKSoftmax_TensorParallel) {
  using Gemm = XeEpilogueFusion_TopKSoftmax_Config<
      2, cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(64, 1024, 1024, 4, 1.0f, 0.0f));
}

TEST(XeEpilogueFusion_Consolidated, PerRowBias_TensorParallel) {
  using Gemm = XeEpilogueFusion_PerRowBias_Config<
      cutlass::layout::RowMajor, cutlass::layout::RowMajor>::Gemm;
  EXPECT_TRUE((test::gemm::device::TestXe<Gemm, cutlass::epilogue::thread::ReLu>(
      64, 1024, 1024, 4, 1.0f, 0.0f)));
}
