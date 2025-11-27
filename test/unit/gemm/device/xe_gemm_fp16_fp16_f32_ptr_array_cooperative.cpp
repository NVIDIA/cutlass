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
/*! \file
    \brief Tests for device-wide GEMM interface

*/
#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/group_array_problem_shape.hpp"
#include "cute/atom/mma_atom.hpp"
#include "cute/atom/copy_atom.hpp"
#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/arch/arch.h"
#include "cutlass/arch/mma.h"
#include "cutlass/layout/layout.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_mma.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"

#include "default_gemm_configuration.hpp"
#include "gemm_testbed_3x_ptr_array.hpp"
using namespace cute;
namespace cutlass {
namespace {

// Default GEMM group configuration for Intel XE architecture
template<
  class OperatorClass, class ArchTag,
  class ElementA, class LayoutA,
  class ElementB, class LayoutB,
  class ElementC, class LayoutC,
  class ElementAccumulator>
struct DefaultGemmGroupConfiguration {
  static_assert(sizeof(ElementA) == 0, "No valid DefaultGemmGroupConfiguration configuration exists.");
};
// Intel XE MMA f16s8f32
template <typename ElementA, typename LayoutA, typename ElementB, typename LayoutB, typename LayoutC, typename ElementOutput>
struct DefaultGemmGroupConfiguration<
    arch::OpClassTensorOp, arch::IntelXe,
    ElementA, LayoutA,
    ElementB, LayoutB,
    float, LayoutC,
    ElementOutput>
{
  static_assert(cute::is_any_of_v<ElementA, bfloat16_t, half_t, int8_t, float_e5m2_t, float_e4m3_t>, "ElementA needs to be of 16 or 8 bit type");
  static_assert(cute::is_any_of_v<ElementB, bfloat16_t, half_t, int8_t, float_e5m2_t, float_e4m3_t, uint4_t>, "ElementB needs to be of 16, 8 or 4 bit type");
  using TileShape = cute::Shape<cute::C<256>, cute::C<256>, cute::C<32>>;

  using CollectiveMainloop = typename gemm::collective::CollectiveBuilder<
    arch::IntelXe, arch::OpClassTensorOp,
    ElementA, LayoutA, 1,
    ElementB, LayoutB, 1,
    float,
    TileShape, cute::Shape<cute::C<1>, cute::C<1>, cute::C<1>>,
    gemm::collective::StageCountAuto,
    gemm::KernelXePtrArrayCooperative
  >::CollectiveOp;

  using TiledMma = typename CollectiveMainloop::TiledMma;

  using EpilogueOp = epilogue::fusion::LinearCombination<float, float>;

  using CollectiveEpilogue = typename epilogue::collective::CollectiveBuilder<
      arch::IntelXe, arch::OpClassTensorOp,
      TileShape, cute::Shape<cute::C<1>, cute::C<1>, cute::C<1>>,
      epilogue::collective::EpilogueTileAuto,
      float, float,
      float, LayoutC, 1,
      ElementOutput, LayoutC, 1,
      epilogue::IntelXeXMX16Group,
      EpilogueOp
    >::CollectiveOp;
};

} // namespace (unnamed)
} // namespace cutlass

namespace cutlass {
namespace {

template <typename LayoutA, typename LayoutB>
struct XE_Device_Gemm_fp16_fp16_f32_group {
  using ProblemShape = gemm::GroupProblemShape<cute::Shape<int,int,int>>;
  using ElementA = cute::half_t;
  using ElementB = cute::half_t;
  using ElementC = float;
  using ElementAccumulator = float;
  using LayoutC = layout::RowMajor;

  using Config = DefaultGemmGroupConfiguration<
    arch::OpClassTensorOp, arch::IntelXe,
    ElementA, LayoutA, ElementB, LayoutB, ElementC, LayoutC, ElementAccumulator>;

  using Gemm = gemm::device::GemmUniversalAdapter<
    gemm::kernel::GemmUniversal<
      ProblemShape,
      typename Config::CollectiveMainloop, 
      typename Config::CollectiveEpilogue,
      gemm::GroupScheduler
    >>;
};


// Test: Small uniform problem sizes with same dimensions (RowMajor A, RowMajor B)
TEST(XE_Device_Gemm_fp16_PtrArray_Cooperative, small_uniform_rowmajor) {
  using Gemm = XE_Device_Gemm_fp16_fp16_f32_group<layout::RowMajor, layout::RowMajor>::Gemm;
  std::vector<gemm::GemmCoord> problems = {{256, 256, 256}, {256, 256, 256}};
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(problems, 1.0, 1.0));
}

// Test: Varied problem sizes with different M, N, K dimensions
TEST(XE_Device_Gemm_fp16_PtrArray_Cooperative, varied_sizes_rowmajor) {
  using Gemm = XE_Device_Gemm_fp16_fp16_f32_group<layout::RowMajor, layout::RowMajor>::Gemm;
  std::vector<gemm::GemmCoord> problems = {{128, 256, 512}, {256, 512, 256}, {512, 256, 128}};
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(problems, 1.0, 0.0));
}

// Test: Large group with mixed layout (ColumnMajor A, RowMajor B)
TEST(XE_Device_Gemm_fp16_PtrArray_Cooperative, large_group_colrow) {
  using Gemm = XE_Device_Gemm_fp16_fp16_f32_group<layout::ColumnMajor, layout::RowMajor>::Gemm;
  std::vector<gemm::GemmCoord> problems = {{128, 128, 64}, {256, 256, 128}, {512, 512, 256}, {256, 128, 64}};
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(problems, 1.0, 1.0));
}

// Test: Both inputs in column-major format
TEST(XE_Device_Gemm_fp16_PtrArray_Cooperative, both_colmajor) {
  using Gemm = XE_Device_Gemm_fp16_fp16_f32_group<layout::ColumnMajor, layout::ColumnMajor>::Gemm;
  std::vector<gemm::GemmCoord> problems = {{256, 256, 256}, {512, 256, 128}};
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(problems, 1.0, 1.0));
}

// Test: Multiple identical problems with scaling variations
TEST(XE_Device_Gemm_fp16_PtrArray_Cooperative, scaling_variations_rowmajor) {
  using Gemm = XE_Device_Gemm_fp16_fp16_f32_group<layout::RowMajor, layout::RowMajor>::Gemm;
  std::vector<gemm::GemmCoord> problems = {{256, 256, 256}, {256, 256, 256}, {256, 256, 256}};
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(problems, 2.0, 1.0));
}

// Test: Five problem batch with various dimensions and mixed layouts
TEST(XE_Device_Gemm_fp16_PtrArray_Cooperative, five_problem_batch_colrow) {
  using Gemm = XE_Device_Gemm_fp16_fp16_f32_group<layout::ColumnMajor, layout::RowMajor>::Gemm;
  std::vector<gemm::GemmCoord> problems = {{128, 128, 128}, {256, 256, 128}, {256, 128, 256}, {128, 256, 256}, {256, 256, 256}};
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(problems, 1.0, 1.0));
}

// Test: Single problem (edge case - minimal batch size)
TEST(XE_Device_Gemm_fp16_PtrArray_Cooperative, single_problem_rowmajor) {
  using Gemm = XE_Device_Gemm_fp16_fp16_f32_group<layout::RowMajor, layout::RowMajor>::Gemm;
  std::vector<gemm::GemmCoord> problems = {{256, 256, 256}};
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(problems, 1.0, 1.0));
}

// Test: Very small matrices (below typical tile size)
TEST(XE_Device_Gemm_fp16_PtrArray_Cooperative, tiny_matrices_rowmajor) {
  using Gemm = XE_Device_Gemm_fp16_fp16_f32_group<layout::RowMajor, layout::RowMajor>::Gemm;
  std::vector<gemm::GemmCoord> problems = {{32, 32, 32}, {64, 64, 32}};
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(problems, 1.0, 0.0));
}

// Test: Non-square matrices with various aspect ratios
TEST(XE_Device_Gemm_fp16_PtrArray_Cooperative, nonsquare_matrices_rowmajor) {
  using Gemm = XE_Device_Gemm_fp16_fp16_f32_group<layout::RowMajor, layout::RowMajor>::Gemm;
  std::vector<gemm::GemmCoord> problems = {{128, 256, 512}, {512, 128, 256}, {256, 512, 128}};
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(problems, 1.0, 1.0));
}

} // namespace
} // namespace cutlass
