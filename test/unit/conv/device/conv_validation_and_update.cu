/***************************************************************************************************
 * Copyright (c) 2017 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights
 * reserved. SPDX-License-Identifier: BSD-3-Clause
 **************************************************************************************************/

#include "cute/tensor.hpp"
#include "cutlass/conv/conv2d_problem_size.h"
#include "cutlass/conv/convnd_problem_shape.hpp"
#include "cutlass/conv/convolution.h"
#include "cutlass/conv/device/direct_convolution.h"
#include "cutlass/conv/device/implicit_gemm_convolution.h"
#include "cutlass/conv/device/implicit_gemm_convolution_fusion.h"
#include "cutlass/conv/kernel/default_conv2d_fprop.h"
#include "cutlass/cutlass.h"

#include "../../common/cutlass_unit_test.h"

namespace test {
namespace conv {
namespace device {

TEST(ConvDeviceValidation, DegenerateSpatialExtentsNotNegative) {
  // Input 5x5, Filter 8x8, Pad 0, Stride 1 -> Numerator: 5 + 0 - 8 = -3 < 0
  cutlass::conv::Conv2dProblemSize problem_size(
      {1, 5, 5, 32},  // N, H, W, C
      {32, 8, 8, 32}, // K, R, S, C
      {0, 0, 0, 0},   // pad_h, pad_h, pad_w, pad_w
      {1, 1},         // stride_h, stride_w
      {1, 1},         // dilation_h, dilation_w
      cutlass::conv::Mode::kCrossCorrelation);

  EXPECT_EQ(problem_size.P, 0);
  EXPECT_EQ(problem_size.Q, 0);

  int64_t linear_m = int64_t(problem_size.N) * problem_size.P * problem_size.Q;
  EXPECT_EQ(linear_m, 0);
}

TEST(ConvDeviceValidation, TwoGiBOverflowGate) {
  using ElementA = cutlass::half_t;
  using ElementB = cutlass::half_t;
  using ElementC = cutlass::half_t;
  using ElementAccumulator = float;

  cutlass::conv::Conv2dProblemSize large_problem(
      {2, 1024, 1024, 512}, {64, 1, 1, 512}, {0, 0, 0, 0}, {1, 1}, {1, 1},
      cutlass::conv::Mode::kCrossCorrelation);

  using Conv2dFpropKernel = typename cutlass::conv::kernel::DefaultConv2dFprop<
      ElementA, cutlass::layout::TensorNHWC, ElementB,
      cutlass::layout::TensorNHWC, ElementC, cutlass::layout::TensorNHWC,
      ElementAccumulator, cutlass::arch::OpClassTensorOp, cutlass::arch::Sm80,
      cutlass::gemm::GemmShape<128, 128, 32>,
      cutlass::gemm::GemmShape<64, 64, 32>, cutlass::gemm::GemmShape<16, 8, 16>,
      cutlass::epilogue::thread::LinearCombination<
          ElementC, 8, ElementAccumulator, ElementAccumulator>,
      cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>, 3,
      cutlass::arch::OpMultiplyAdd>::Kernel;

  using ImplicitGemmConv =
      cutlass::conv::device::ImplicitGemmConvolution<Conv2dFpropKernel>;

  typename ImplicitGemmConv::Arguments args_plain{
      large_problem,
      {nullptr, cutlass::layout::TensorNHWC::packed({2, 1024, 1024, 512})},
      {nullptr, cutlass::layout::TensorNHWC::packed({64, 1, 1, 512})},
      {nullptr, cutlass::layout::TensorNHWC::packed({2, 1024, 1024, 64})},
      {nullptr, cutlass::layout::TensorNHWC::packed({2, 1024, 1024, 64})},
      {1.0f, 0.0f}};

  cutlass::Status status_plain = ImplicitGemmConv::can_implement(args_plain);
  EXPECT_EQ(status_plain, cutlass::Status::kErrorInvalidProblem);
}

TEST(ConvDeviceValidation, UpdateGeometryAndPointerRefresh) {
  using Element = float;
  using ElementAccumulator = float;

  using Conv2dFpropKernel = typename cutlass::conv::kernel::DefaultConv2dFprop<
      Element, cutlass::layout::TensorNHWC, Element,
      cutlass::layout::TensorNHWC, Element, cutlass::layout::TensorNHWC,
      ElementAccumulator, cutlass::arch::OpClassSimt, cutlass::arch::Sm80,
      cutlass::gemm::GemmShape<64, 64, 8>, cutlass::gemm::GemmShape<32, 32, 8>,
      cutlass::gemm::GemmShape<1, 1, 1>,
      cutlass::epilogue::thread::LinearCombination<
          Element, 1, ElementAccumulator, ElementAccumulator>,
      cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>, 2,
      cutlass::arch::OpMultiplyAdd>::Kernel;

  using ImplicitGemmConv =
      cutlass::conv::device::ImplicitGemmConvolution<Conv2dFpropKernel>;

  cutlass::conv::Conv2dProblemSize problem_1(
      {1, 16, 16, 32}, {32, 3, 3, 32}, {1, 1, 1, 1}, {1, 1}, {1, 1},
      cutlass::conv::Mode::kCrossCorrelation);
  cutlass::conv::Conv2dProblemSize problem_2(
      {1, 32, 32, 64}, {64, 1, 1, 64}, {0, 0, 0, 0}, {1, 1}, {1, 1},
      cutlass::conv::Mode::kCrossCorrelation);

  Element dummy_a1, dummy_b1, dummy_c1, dummy_d1;
  Element dummy_a2, dummy_b2, dummy_c2, dummy_d2;

  typename ImplicitGemmConv::Arguments args_1{
      problem_1,
      {&dummy_a1, cutlass::layout::TensorNHWC::packed({1, 16, 16, 32})},
      {&dummy_b1, cutlass::layout::TensorNHWC::packed({32, 3, 3, 32})},
      {&dummy_c1, cutlass::layout::TensorNHWC::packed({1, 16, 16, 32})},
      {&dummy_d1, cutlass::layout::TensorNHWC::packed({1, 16, 16, 32})},
      {1.0f, 0.0f}};

  typename ImplicitGemmConv::Arguments args_2{
      problem_2,
      {&dummy_a2, cutlass::layout::TensorNHWC::packed({1, 32, 32, 64})},
      {&dummy_b2, cutlass::layout::TensorNHWC::packed({64, 1, 1, 64})},
      {&dummy_c2, cutlass::layout::TensorNHWC::packed({1, 32, 32, 64})},
      {&dummy_d2, cutlass::layout::TensorNHWC::packed({1, 32, 32, 64})},
      {1.0f, 0.0f}};

  ImplicitGemmConv op;
  cutlass::Status status = op.initialize(args_1);
  EXPECT_EQ(status, cutlass::Status::kSuccess);

  status = op.update(args_2);
  EXPECT_EQ(status, cutlass::Status::kSuccess);
}

} // namespace device
} // namespace conv
} // namespace test
