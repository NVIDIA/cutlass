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
    \brief Tests for Xe tf32_tf32_fp32
*/


#include "cutlass/cutlass.h"

#include "cutlass/gemm/device/gemm_universal_adapter.h"
#include "cutlass/gemm/kernel/gemm_universal.hpp"
#include "default_gemm_configuration.hpp"

#include "gemm_testbed_3x.hpp"

/* TODO(Codeplay): TF32 copy builtins don't work well with GEMM. Needs more investigation
namespace cutlass {
namespace {
template <typename LayoutA, typename LayoutB>
struct XE_Device_Gemm_tf32_tf32_f32_tensor_op_f32 {
  using Config = gemm::device::DefaultGemmConfigurationToCutlass3Types<
    arch::OpClassTensorOp, arch::IntelXe,
    tfloat32_t, LayoutA,
    tfloat32_t, LayoutB,
    float, layout::RowMajor,
    float>;

  using GemmKernel = gemm::kernel::GemmUniversal<
      cute::Shape<int,int,int,int>,
      Config::CollectiveMainloop,
      Config::CollectiveEpilogue>;

  using Gemm = gemm::device::GemmUniversalAdapter<GemmKernel>;
};

TEST(XE_Device_Gemm_tf32t_tf32t_f32t_tensor_op_f32, 256x256x32) {
  using LayoutA = RowMajor;
  using LayoutB = RowMajor;
  using Gemm = XE_Device_Gemm_tf32_tf32_f32_tensor_op_f32<LayoutA, LayoutB>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>());
}

 TODO(Codeplay): missing copy transpose builtin and prefetch builtin
TEST(XE_Device_Gemm_tf32n_tf32t_f32t_tensor_op_f32, 256x256x32) {
  using LayoutA = ColumnMajor;
  using LayoutB = RowMajor;
  using Gemm = XE_Device_Gemm_tf32_tf32_f32_tensor_op_f32<LayoutA, LayoutB>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>());
}

TEST(XE_Device_Gemm_tf32t_tf32n_f32t_tensor_op_f32, 256x256x32) {
  using LayoutA = RowMajor;
  using LayoutB = ColumnMajor;
  using Gemm = XE_Device_Gemm_tf32_tf32_f32_tensor_op_f32<LayoutA, LayoutB>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>());
}

TEST(XE_Device_Gemm_tf32n_tf32n_f32t_tensor_op_f32, 256x256x32) {
  using LayoutA = ColumnMajor;
  using LayoutB = ColumnMajor;
  using Gemm = XE_Device_Gemm_tf32_tf32_f32_tensor_op_f32<LayoutA, LayoutB>::Gemm;
  EXPECT_TRUE(test::gemm::device::TestXe<Gemm>());
}
}
} // namespace cutlass
*/
