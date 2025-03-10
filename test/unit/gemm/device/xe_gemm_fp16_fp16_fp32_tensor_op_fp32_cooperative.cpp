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
    \brief Tests for Xe fp16_fp16_fp32
*/

#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "default_gemm_configuration.hpp"

#include "gemm_testbed_3x.hpp"

TEST(XE_Device_Gemm_fp16t_fp16t_f32t_tensor_op_f32_cooperative, 256x256x32) {
  using ElementA = cute::half_t;
  using ElementB = cute::half_t;
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::RowMajor;

  using Config = cutlass::gemm::device::DefaultGemmConfigurationToCutlass3Types<
    cutlass::arch::OpClassTensorOp, cutlass::arch::IntelPVC,
    ElementA, LayoutA,
    ElementB, LayoutB,
    float, cutlass::layout::RowMajor,
    float>;

  using DispatchPolicy = cutlass::gemm::MainloopIntelPVC<3, cutlass::gemm::KernelPVCCooperative>;

  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
    DispatchPolicy, Config::TileShape,
    ElementA, cutlass::detail::TagToStrideA_t<LayoutA>,
    ElementB, cutlass::detail::TagToStrideB_t<LayoutB>,
    Config::TiledMma,
    Config::GmemTiledCopyA, void, void, cute::identity,  // A
    Config::GmemTiledCopyB, void, void, cute::identity   // B
  >;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      cute::Shape<int,int,int,int>,
      CollectiveMainloop,
      Config::CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(1.0, 0.0, false));
}

TEST(XE_Device_Gemm_fp16n_fp16t_f32t_tensor_op_f32_cooperative, 256x256x32) {
  using ElementA = cute::half_t;
  using ElementB = cute::half_t;
  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::RowMajor;

  using Config = cutlass::gemm::device::DefaultGemmConfigurationToCutlass3Types<
    cutlass::arch::OpClassTensorOp, cutlass::arch::IntelPVC,
    ElementA, LayoutA,
    ElementB, LayoutB,
    float, cutlass::layout::RowMajor,
    float>;

  using DispatchPolicy = cutlass::gemm::MainloopIntelPVC<3, cutlass::gemm::KernelPVCCooperative>;

  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
    DispatchPolicy, Config::TileShape,
    ElementA, cutlass::detail::TagToStrideA_t<LayoutA>,
    ElementB, cutlass::detail::TagToStrideB_t<LayoutB>,
    Config::TiledMma,
    Config::GmemTiledCopyA, void, void, cute::identity,  // A
    Config::GmemTiledCopyB, void, void, cute::identity   // B
  >;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      cute::Shape<int,int,int,int>,
      CollectiveMainloop,
      Config::CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(1.0, 0.0, false));
}

TEST(XE_Device_Gemm_fp16t_fp16n_f32t_tensor_op_f32_cooperative, 256x256x32) {
  using ElementA = cute::half_t;
  using ElementB = cute::half_t;
  using LayoutA = cutlass::layout::RowMajor;
  using LayoutB = cutlass::layout::ColumnMajor;

  using Config = cutlass::gemm::device::DefaultGemmConfigurationToCutlass3Types<
    cutlass::arch::OpClassTensorOp, cutlass::arch::IntelPVC,
    ElementA, LayoutA,
    ElementB, LayoutB,
    float, cutlass::layout::RowMajor,
    float>;

  using DispatchPolicy = cutlass::gemm::MainloopIntelPVC<3, cutlass::gemm::KernelPVCCooperative>;

  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
    DispatchPolicy, Config::TileShape,
    ElementA, cutlass::detail::TagToStrideA_t<LayoutA>,
    ElementB, cutlass::detail::TagToStrideB_t<LayoutB>,
    Config::TiledMma,
    Config::GmemTiledCopyA, void, void, cute::identity,  // A
    Config::GmemTiledCopyB, void, void, cute::identity   // B
  >;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      cute::Shape<int,int,int,int>,
      CollectiveMainloop,
      Config::CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(1.0, 0.0, false));
}

TEST(XE_Device_Gemm_fp16n_fp16n_f32t_tensor_op_f32_cooperative, 256x256x32) {
  using ElementA = cute::half_t;
  using ElementB = cute::half_t;
  using LayoutA = cutlass::layout::ColumnMajor;
  using LayoutB = cutlass::layout::ColumnMajor;

  using Config = cutlass::gemm::device::DefaultGemmConfigurationToCutlass3Types<
    cutlass::arch::OpClassTensorOp, cutlass::arch::IntelPVC,
    ElementA, LayoutA,
    ElementB, LayoutB,
    float, cutlass::layout::RowMajor,
    float>;

  using DispatchPolicy = cutlass::gemm::MainloopIntelPVC<3, cutlass::gemm::KernelPVCCooperative>;

  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
    DispatchPolicy, Config::TileShape,
    ElementA, cutlass::detail::TagToStrideA_t<LayoutA>,
    ElementB, cutlass::detail::TagToStrideB_t<LayoutB>,
    Config::TiledMma,
    Config::GmemTiledCopyA, void, void, cute::identity,  // A
    Config::GmemTiledCopyB, void, void, cute::identity   // B
  >;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
      cute::Shape<int,int,int,int>,
      CollectiveMainloop,
      Config::CollectiveEpilogue,
      cutlass::gemm::StreamKScheduler
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
  // TODO(Codeplay): Enable batch tests
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>(1.0, 0.0, false));
}
