/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
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
    \brief Tests for Xe bf16_bf16_fp32
*/

#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "default_gemm_configuration.hpp"

#include "gemm_testbed_3x.hpp"

namespace cutlass {
namespace {

template <typename LayoutA, typename LayoutB>
struct XE_Device_Gemm_bf16_bf16_f32_tensor_op_f32_cooperative {
  using ElementA = cute::bfloat16_t;
  using ElementB = cute::bfloat16_t;

  using Config = gemm::device::DefaultGemmConfigurationToCutlass3Types<
    arch::OpClassTensorOp, arch::IntelXe,
    ElementA, LayoutA,
    ElementB, LayoutB,
    float, layout::RowMajor,
    float>;

  using CollectiveMainloop = typename cutlass::gemm::collective::CollectiveBuilder<
    cutlass::arch::IntelXe, cutlass::arch::OpClassTensorOp,
    ElementA, LayoutA, 1,
    ElementB, LayoutB, 1,
    float,
    typename Config::TileShape, Shape<_1, _1, _1>,
    cutlass::gemm::collective::StageCountAuto,
    cutlass::gemm::KernelXeCooperative
  >::CollectiveOp;

  using Gemm = gemm::device::GemmUniversalAdapter<
    gemm::kernel::GemmUniversal<
     cute::Shape<int,int,int,int>,
     CollectiveMainloop,
     typename Config::CollectiveEpilogue,
     gemm::StreamKScheduler>>;
};

TEST(XE_Device_Gemm_bf16t_bf16t_f32t_tensor_op_f32_cooperative, 256x256x32) {
  using Gemm = XE_Device_Gemm_bf16_bf16_f32_tensor_op_f32_cooperative<
    layout::RowMajor, layout::RowMajor>::Gemm;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(1.0, 0.0, false));
}

TEST(XE_Device_Gemm_bf16n_bf16t_f32t_tensor_op_f32_cooperative, 256x256x32) {
  using Gemm = XE_Device_Gemm_bf16_bf16_f32_tensor_op_f32_cooperative<
    layout::ColumnMajor, layout::RowMajor>::Gemm;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(1.0, 0.0, false));
}

TEST(XE_Device_Gemm_bf16t_bf16n_f32t_tensor_op_f32_cooperative, 256x256x32) {
  using Gemm = XE_Device_Gemm_bf16_bf16_f32_tensor_op_f32_cooperative<
    layout::RowMajor, layout::ColumnMajor>::Gemm;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(1.0, 0.0, false));
}

TEST(XE_Device_Gemm_bf16n_bf16n_f32t_tensor_op_f32_cooperative, 256x256x32) {
  using Gemm = XE_Device_Gemm_bf16_bf16_f32_tensor_op_f32_cooperative<
    layout::ColumnMajor, layout::ColumnMajor>::Gemm;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(1.0, 0.0, false));
}
}
} // namespace cutlass
