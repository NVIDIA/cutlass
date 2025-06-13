/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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
    \brief Tests for Xe Group fp16_fp16_fp32 with epilogue data conversion to fp16
*/

#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "cutlass/gemm/group_array_problem_shape.hpp"

#include "default_gemm_configuration.hpp"
#include "default_gemm_group_configuration.hpp"
#include "gemm_testbed_3x_ptr_array.hpp"

namespace cutlass {
namespace {
template <typename LayoutA, typename LayoutB>
struct XE_Device_Gemm_fp16_fp16_f16_tensor_op_f32_group_gemm {
  using ProblemShape = gemm::GroupProblemShape<cute::Shape<int,int,int>>; // <M,N,K> per group
  using ElementA = cute::half_t;
  using ElementB = cute::half_t;
  using ElementD = cute::half_t;
  using ElementAccumulator = float;
  using LayoutC = layout::RowMajor;

  using Config = gemm::device::DefaultGemmGroupConfiguration<
    arch::OpClassTensorOp, arch::IntelXe,
    ElementA, LayoutA,
    ElementB, LayoutB,
    ElementAccumulator, LayoutC,
    ElementD>;

  using GemmKernel = gemm::kernel::GemmUniversal<
      ProblemShape,
      typename Config::CollectiveMainloop,
      typename Config::CollectiveEpilogue,
      gemm::GroupScheduler
  >;

  using Gemm = gemm::device::GemmUniversalAdapter<GemmKernel>;
};

TEST(XE_Device_Gemm_fp16t_fp16t_f16t_tensor_op_f32_group_gemm, 256x256x32) {
  using LayoutA = layout::RowMajor;
  using LayoutB = layout::RowMajor;
  using Gemm = XE_Device_Gemm_fp16_fp16_f16_tensor_op_f32_group_gemm<LayoutA, LayoutB>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(1.0, 1.0));
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(1.0, 0.0));
}

TEST(XE_Device_Gemm_fp16n_fp16t_f16t_tensor_op_f32_group_gemm, 256x256x32) {
  using LayoutA = layout::ColumnMajor;
  using LayoutB = layout::RowMajor;
  using Gemm = XE_Device_Gemm_fp16_fp16_f16_tensor_op_f32_group_gemm<LayoutA, LayoutB>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(1.0, 1.0));
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(1.0, 0.0));
}

TEST(XE_Device_Gemm_fp16t_fp16n_f16t_tensor_op_f32_group_gemm, 256x256x32) {
  using LayoutA = layout::RowMajor;
  using LayoutB = layout::ColumnMajor;
  using Gemm = XE_Device_Gemm_fp16_fp16_f16_tensor_op_f32_group_gemm<LayoutA, LayoutB>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(1.0, 1.0));
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(1.0, 0.0));
}

TEST(XE_Device_Gemm_fp16n_fp16n_f16t_tensor_op_f32_group_gemm, 256x256x32) {
  using LayoutA = layout::ColumnMajor;
  using LayoutB = layout::ColumnMajor;
  using Gemm = XE_Device_Gemm_fp16_fp16_f16_tensor_op_f32_group_gemm<LayoutA, LayoutB>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(1.0, 1.0));
  EXPECT_TRUE(test::gemm::device::TestAll<Gemm>(1.0, 0.0));
}
}
} // namespace cutlass
