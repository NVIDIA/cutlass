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
    \brief Tests for Xe s8_s8_s32
*/

#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "default_gemm_configuration.hpp"

#include "gemm_testbed_3x.hpp"
namespace cutlass {
namespace {
template <typename LayoutA, typename LayoutB>
struct XE_Device_Gemm_s8_s8_s32_tensor_op_s32_cooperative {
  using ElementA = int8_t;
  using ElementB = int8_t;

  using Config = gemm::device::DefaultGemmConfigurationToCutlass3Types<
    arch::OpClassTensorOp, arch::IntelXe,
    ElementA, LayoutA,
    ElementB, LayoutB,
    int32_t, layout::RowMajor,
    int32_t>;

  using DispatchPolicy = gemm::MainloopIntelXeXMX16<3, gemm::KernelPVCCooperative>;

  using CollectiveMainloop = gemm::collective::CollectiveMma<
    DispatchPolicy, Config::TileShape,
    ElementA, detail::TagToStrideA_t<LayoutA>,
    ElementB, detail::TagToStrideB_t<LayoutB>,
    Config::TiledMma,
    Config::GmemTiledCopyA, void, void, cute::identity,  // A
    Config::GmemTiledCopyB, void, void, cute::identity   // B
  >;

  using GemmKernel = gemm::kernel::GemmUniversal<
      cute::Shape<int,int,int,int>,
      CollectiveMainloop,
      Config::CollectiveEpilogue,
      gemm::StreamKScheduler>;

  using Gemm = gemm::device::GemmUniversalAdapter<GemmKernel>;
};

TEST(XE_Device_Gemm_s8t_s8t_s32t_tensor_op_s32_cooperative, 64x128x32) {
  using LayoutA = layout::RowMajor;
  using LayoutB = layout::RowMajor;
  using Gemm = XE_Device_Gemm_s8_s8_s32_tensor_op_s32_cooperative<LayoutA, LayoutB>::Gemm;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>());
}

/* TODO(Codeplay): Transposed copy are not implemented
TEST(XE_Device_Gemm_s8n_s8t_s32t_tensor_op_s32_cooperative, 64x128x32) {
  using LayoutA = layout::ColumnMajor;
  using LayoutB = layout::RowMajor;
  using Gemm = XE_Device_Gemm_s8_s8_s32_tensor_op_s32_cooperative<LayoutA, LayoutB>::Gemm;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>());
}

TEST(XE_Device_Gemm_s8t_s8n_s32t_tensor_op_s32_cooperative, 64x128x32) {
  using LayoutA = layout::RowMajor;
  using LayoutB = layout::ColumnMajor;
  using Gemm = XE_Device_Gemm_s8_s8_s32_tensor_op_s32_cooperative<LayoutA, LayoutB>::Gemm;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>());
}

TEST(XE_Device_Gemm_s8n_s8n_s32t_tensor_op_s32_cooperative, 64x128x32) {
  using LayoutA = layout::ColumnMajor;
  using LayoutB = layout::ColumnMajor;
  using Gemm = XE_Device_Gemm_s8_s8_s32_tensor_op_s32_cooperative<LayoutA, LayoutB>::Gemm;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>());
}
*/
}
} // namespace cutlass
