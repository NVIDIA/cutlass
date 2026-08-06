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
    \brief Tests SM89 FP8 blockwise GEMM with threadblock swizzling.
*/

#include "../../common/cutlass_unit_test.h"

#include "cutlass/arch/arch.h"
#include "cutlass/cutlass.h"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/gemm/device/gemm_blockwise.h"
#include "cutlass/gemm/threadblock/threadblock_swizzle.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/numeric_types.h"
#include "cutlass/util/host_tensor.h"
#include "cutlass/util/reference/host/tensor_fill.h"

#if defined(CUTLASS_ARCH_MMA_F32_SM89_SUPPORTED)

namespace {

using ElementA = cutlass::float_e4m3_t;
using ElementB = cutlass::float_e4m3_t;
using ElementOutput = cutlass::bfloat16_t;
using ElementAccumulator = float;
using LayoutA = cutlass::layout::RowMajor;
using LayoutB = cutlass::layout::ColumnMajor;
using LayoutC = cutlass::layout::RowMajor;
using LayoutScale = cutlass::layout::RowMajor;

int const kM = 256;
int const kN = 256;
int const kK = 128;
int const kScaleBlock = 128;

using EpilogueOutputOp = cutlass::epilogue::thread::LinearCombination<
    ElementOutput, 8, ElementAccumulator, ElementAccumulator>;

template <typename ThreadblockSwizzle>
using Gemm = cutlass::gemm::device::GemmBlockwise<
    ElementA, LayoutA, ElementB, LayoutB, ElementOutput, LayoutC,
    ElementAccumulator, cutlass::arch::OpClassTensorOp, cutlass::arch::Sm89,
    cutlass::gemm::GemmShape<64, 128, 128>,
    cutlass::gemm::GemmShape<64, 64, 128>,
    cutlass::gemm::GemmShape<16, 8, 32>, float, LayoutScale, kScaleBlock,
    EpilogueOutputOp, ThreadblockSwizzle, 3, 16, 16, false,
    cutlass::arch::OpMultiplyAdd>;

template <typename ThreadblockSwizzle>
::testing::AssertionResult run_blockwise_gemm() {
  using Operator = Gemm<ThreadblockSwizzle>;

  cutlass::HostTensor<ElementA, LayoutA> tensor_a({kM, kK});
  cutlass::HostTensor<ElementB, LayoutB> tensor_b({kK, kN});
  cutlass::HostTensor<ElementOutput, LayoutC> tensor_c({kM, kN});
  cutlass::HostTensor<ElementOutput, LayoutC> tensor_d({kM, kN});
  cutlass::HostTensor<float, LayoutScale> scale_a({kM / kScaleBlock, 1});
  cutlass::HostTensor<float, LayoutScale> scale_b({kN / kScaleBlock, 1});

  cutlass::reference::host::TensorFill(tensor_a.host_view(), ElementA(1));
  cutlass::reference::host::TensorFill(tensor_b.host_view(), ElementB(1));
  cutlass::reference::host::TensorFill(tensor_c.host_view(), ElementOutput(0));
  cutlass::reference::host::TensorFill(tensor_d.host_view(), ElementOutput(0));

  // Powers-of-two scales keep the expected BF16 outputs exactly representable.
  scale_a.host_view().at({0, 0}) = 1.0f;
  scale_a.host_view().at({1, 0}) = 4.0f;
  scale_b.host_view().at({0, 0}) = 2.0f;
  scale_b.host_view().at({1, 0}) = 8.0f;

  tensor_a.sync_device();
  tensor_b.sync_device();
  tensor_c.sync_device();
  tensor_d.sync_device();
  scale_a.sync_device();
  scale_b.sync_device();

  typename Operator::TensorRefScale scale_a_ref(
      scale_a.device_data(), LayoutScale(1));
  typename Operator::TensorRefScale scale_b_ref(
      scale_b.device_data(), LayoutScale(1));
  typename Operator::Arguments arguments(
      {kM, kN, kK}, {tensor_a.device_data(), kK},
      {tensor_b.device_data(), kK}, {tensor_c.device_data(), kN},
      {tensor_d.device_data(), kN}, scale_a_ref, scale_b_ref,
      typename Operator::EpilogueOutputOp::Params(1.0f, 0.0f));

  cutlass::Status status = Operator::can_implement(arguments);
  if (status != cutlass::Status::kSuccess) {
    return ::testing::AssertionFailure()
           << "can_implement failed with status " << int(status);
  }

  Operator gemm;
  status = gemm.initialize(arguments, nullptr);
  if (status != cutlass::Status::kSuccess) {
    return ::testing::AssertionFailure()
           << "initialize failed with status " << int(status);
  }

  status = gemm();
  if (status != cutlass::Status::kSuccess) {
    return ::testing::AssertionFailure()
           << "launch failed with status " << int(status);
  }

  cudaError_t cuda_status = cudaDeviceSynchronize();
  if (cuda_status != cudaSuccess) {
    return ::testing::AssertionFailure()
           << "synchronize failed: " << cudaGetErrorString(cuda_status);
  }

  tensor_d.sync_host();

  uint64_t mismatches = 0;
  int first_m = -1;
  int first_n = -1;
  float first_expected = 0;
  float first_observed = 0;
  float const scale_a_values[] = {1.0f, 4.0f};
  float const scale_b_values[] = {2.0f, 8.0f};

  for (int m = 0; m < kM; ++m) {
    for (int n = 0; n < kN; ++n) {
      float expected = float(kK) * scale_a_values[m / kScaleBlock] *
                       scale_b_values[n / kScaleBlock];
      float observed = float(tensor_d.host_view().at({m, n}));
      if (observed != expected) {
        if (!mismatches) {
          first_m = m;
          first_n = n;
          first_expected = expected;
          first_observed = observed;
        }
        ++mismatches;
      }
    }
  }

  if (mismatches) {
    return ::testing::AssertionFailure()
           << mismatches << " mismatches; first at (" << first_m << ", "
           << first_n << "): expected " << first_expected << ", observed "
           << first_observed;
  }

  return ::testing::AssertionSuccess();
}

}  // namespace

TEST(SM89_Device_GemmBlockwise_fe4m3t_fe4m3n_bf16t_tensor_op_f32,
     identity_1_256x256x128_64x128x128) {
  using Swizzle =
      cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<1>;
  EXPECT_TRUE(run_blockwise_gemm<Swizzle>());
}

// Identity<2> exercises a nontrivial physical-to-logical CTA mapping.
TEST(SM89_Device_GemmBlockwise_fe4m3t_fe4m3n_bf16t_tensor_op_f32,
     identity_2_256x256x128_64x128x128) {
  using Swizzle =
      cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<2>;
  EXPECT_TRUE(run_blockwise_gemm<Swizzle>());
}

#endif  // CUTLASS_ARCH_MMA_F32_SM89_SUPPORTED
