/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Tests for device-wide Implicit GEMM interface
*/

#include "../../common/cutlass_unit_test.h"
#include "cutlass/cutlass.h"


#include "cutlass/conv/kernel/default_conv2d_dgrad.h"
#include "cutlass/conv/device/implicit_gemm_convolution.h"

#include "conv2d_testbed.h"

#if defined(CUTLASS_ARCH_MMA_SM80_SUPPORTED)

////////////////////////////////////////////////////////////////////////////////
TEST(SM80_Device_Conv2d_Dgrad_Analytic_ImplicitGemm_f32nhwc_f32nhwc_f32nhwc_simt_f32,
  32x64_8x4_32x64x8) {

  /// Conv operation element types for the Gemm equivalent (ImplicitGemm)
  using ElementA           = float;
  using ElementB           = float;
  using ElementC           = float;
  using ElementAccumulator = float;
  using ElementCompute     = float;


  /// Device-level Conv2d instance
  using Conv2dDgradKernel = typename cutlass::conv::kernel::DefaultConv2dDgrad<
    ElementA, 
    cutlass::layout::TensorNHWC,
    ElementB, 
    cutlass::layout::TensorNHWC,
    ElementC, 
    cutlass::layout::TensorNHWC,
    ElementAccumulator,
    cutlass::arch::OpClassSimt,
    cutlass::arch::Sm80,
    cutlass::gemm::GemmShape<32, 64, 8>,
    cutlass::gemm::GemmShape<32, 64, 8>, 
    cutlass::gemm::GemmShape<1, 1, 1>,
    cutlass::epilogue::thread::LinearCombination<
      ElementC,
      1,
      ElementAccumulator,
      ElementCompute
    >,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>,
    4,
    cutlass::arch::OpMultiplyAdd,
    cutlass::conv::IteratorAlgorithm::kAnalytic
  >::Kernel;

  using Conv2dDgrad = cutlass::conv::device::ImplicitGemmConvolution<Conv2dDgradKernel>;

  /// Run all unit test sizes with device-level Conv2d instance
  EXPECT_TRUE(test::conv::device::TestAllConv2d<Conv2dDgrad>());

}

////////////////////////////////////////////////////////////////////////////////
TEST(SM80_Device_Conv2d_Dgrad_Analytic_ImplicitGemm_f32nhwc_f32nhwc_f32nhwc_simt_f32,
  64x64_8x4_32x64x8) {

  /// Conv operation element types for the Gemm equivalent (ImplicitGemm)
  using ElementA           = float;
  using ElementB           = float;
  using ElementC           = float;
  using ElementAccumulator = float;
  using ElementCompute     = float;


  /// Device-level Conv2d instance
  using Conv2dDgradKernel = typename cutlass::conv::kernel::DefaultConv2dDgrad<
    ElementA, 
    cutlass::layout::TensorNHWC,
    ElementB, 
    cutlass::layout::TensorNHWC,
    ElementC, 
    cutlass::layout::TensorNHWC,
    ElementAccumulator,
    cutlass::arch::OpClassSimt,
    cutlass::arch::Sm80,
    cutlass::gemm::GemmShape<64, 64, 8>,
    cutlass::gemm::GemmShape<32, 64, 8>, 
    cutlass::gemm::GemmShape<1, 1, 1>,
    cutlass::epilogue::thread::LinearCombination<
      ElementC,
      1,
      ElementAccumulator,
      ElementCompute
    >,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>,
    4,
    cutlass::arch::OpMultiplyAdd,
    cutlass::conv::IteratorAlgorithm::kAnalytic
  >::Kernel;

  using Conv2dDgrad = cutlass::conv::device::ImplicitGemmConvolution<Conv2dDgradKernel>;

  /// Run all unit test sizes with device-level Conv2d instance
  EXPECT_TRUE(test::conv::device::TestAllConv2d<Conv2dDgrad>());

}

////////////////////////////////////////////////////////////////////////////////
TEST(SM80_Device_Conv2d_Dgrad_Analytic_ImplicitGemm_f32nhwc_f32nhwc_f32nhwc_simt_f32,
  128x128_8x4_32x64x8) {

  /// Conv operation element types for the Gemm equivalent (ImplicitGemm)
  using ElementA           = float;
  using ElementB           = float;
  using ElementC           = float;
  using ElementAccumulator = float;
  using ElementCompute     = float;


  /// Device-level Conv2d instance
  using Conv2dDgradKernel = typename cutlass::conv::kernel::DefaultConv2dDgrad<
    ElementA, 
    cutlass::layout::TensorNHWC,
    ElementB, 
    cutlass::layout::TensorNHWC,
    ElementC, 
    cutlass::layout::TensorNHWC,
    ElementAccumulator,
    cutlass::arch::OpClassSimt,
    cutlass::arch::Sm80,
    cutlass::gemm::GemmShape<128, 128, 8>,
    cutlass::gemm::GemmShape<32, 64, 8>, 
    cutlass::gemm::GemmShape<1, 1, 1>,
    cutlass::epilogue::thread::LinearCombination<
      ElementC,
      1,
      ElementAccumulator,
      ElementCompute
    >,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>,
    4,
    cutlass::arch::OpMultiplyAdd,
    cutlass::conv::IteratorAlgorithm::kAnalytic
  >::Kernel;

  using Conv2dDgrad = cutlass::conv::device::ImplicitGemmConvolution<Conv2dDgradKernel>;

  test::conv::device::Conv2dProblemVector user_size;

  user_size.push_back(cutlass::conv::Conv2dProblemSize(
      {1, 8, 8, 4},   // input size  (NHWC)
      {8, 1, 1, 4},   // filter size (KRSC)
      {0, 0, 0, 0},                      // padding (pad_h, _, pad_w, _)
      {1, 1},                            // stride (stride_h, stride_w)
      {1, 1}                             // dilation (dilation_h, dilation_w) 
    ));

  /// Run all unit test sizes with device-level Conv2d instance
  EXPECT_TRUE(test::conv::device::TestAllConv2d<Conv2dDgrad>(user_size));

}

////////////////////////////////////////////////////////////////////////////////
TEST(SM80_Device_Conv2d_Dgrad_Analytic_ImplicitGemm_f32nhwc_f32nhwc_f32nhwc_simt_f32,
  128x128_8x4_64x32x8) {

  /// Conv operation element types for the Gemm equivalent (ImplicitGemm)
  using ElementA           = float;
  using ElementB           = float;
  using ElementC           = float;
  using ElementAccumulator = float;
  using ElementCompute     = float;


  /// Device-level Conv2d instance
  using Conv2dDgradKernel = typename cutlass::conv::kernel::DefaultConv2dDgrad<
    ElementA, 
    cutlass::layout::TensorNHWC,
    ElementB, 
    cutlass::layout::TensorNHWC,
    ElementC, 
    cutlass::layout::TensorNHWC,
    ElementAccumulator,
    cutlass::arch::OpClassSimt,
    cutlass::arch::Sm80,
    cutlass::gemm::GemmShape<128, 128, 8>,
    cutlass::gemm::GemmShape<64, 32, 8>, 
    cutlass::gemm::GemmShape<1, 1, 1>,
    cutlass::epilogue::thread::LinearCombination<
      ElementC,
      1,
      ElementAccumulator,
      ElementCompute
    >,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>,
    4,
    cutlass::arch::OpMultiplyAdd,
    cutlass::conv::IteratorAlgorithm::kAnalytic
  >::Kernel;

  using Conv2dDgrad = cutlass::conv::device::ImplicitGemmConvolution<Conv2dDgradKernel>;

  /// Run all unit test sizes with device-level Conv2d instance
  EXPECT_TRUE(test::conv::device::TestAllConv2d<Conv2dDgrad>());

}

////////////////////////////////////////////////////////////////////////////////
TEST(SM80_Device_Conv2d_Dgrad_Optimized_ImplicitGemm_f32nhwc_f32nhwc_f32nhwc_simt_f32,
  32x64_8x4_32x64x8) {

  /// Conv operation element types for the Gemm equivalent (ImplicitGemm)
  using ElementA           = float;
  using ElementB           = float;
  using ElementC           = float;
  using ElementAccumulator = float;
  using ElementCompute     = float;


  /// Device-level Conv2d instance
  using Conv2dDgradKernel = typename cutlass::conv::kernel::DefaultConv2dDgrad<
    ElementA, 
    cutlass::layout::TensorNHWC,
    ElementB, 
    cutlass::layout::TensorNHWC,
    ElementC, 
    cutlass::layout::TensorNHWC,
    ElementAccumulator,
    cutlass::arch::OpClassSimt,
    cutlass::arch::Sm80,
    cutlass::gemm::GemmShape<32, 64, 8>,
    cutlass::gemm::GemmShape<32, 64, 8>, 
    cutlass::gemm::GemmShape<1, 1, 1>,
    cutlass::epilogue::thread::LinearCombination<
      ElementC,
      1,
      ElementAccumulator,
      ElementCompute
    >,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>,
    4,
    cutlass::arch::OpMultiplyAdd,
    cutlass::conv::IteratorAlgorithm::kOptimized,
    cutlass::conv::StrideSupport::kUnity
  >::Kernel;

  using Conv2dDgrad = cutlass::conv::device::ImplicitGemmConvolution<Conv2dDgradKernel>;

  /// Run all unit test sizes with device-level Conv2d instance
  EXPECT_TRUE(test::conv::device::TestAllConv2d<Conv2dDgrad>());

}

////////////////////////////////////////////////////////////////////////////////
TEST(SM80_Device_Conv2d_Dgrad_Optimized_ImplicitGemm_f32nhwc_f32nhwc_f32nhwc_simt_f32,
  128x128_8x4_64x32x8) {

  /// Conv operation element types for the Gemm equivalent (ImplicitGemm)
  using ElementA           = float;
  using ElementB           = float;
  using ElementC           = float;
  using ElementAccumulator = float;
  using ElementCompute     = float;


  /// Device-level Conv2d instance
  using Conv2dDgradKernel = typename cutlass::conv::kernel::DefaultConv2dDgrad<
    ElementA, 
    cutlass::layout::TensorNHWC,
    ElementB, 
    cutlass::layout::TensorNHWC,
    ElementC, 
    cutlass::layout::TensorNHWC,
    ElementAccumulator,
    cutlass::arch::OpClassSimt,
    cutlass::arch::Sm80,
    cutlass::gemm::GemmShape<128, 128, 8>,
    cutlass::gemm::GemmShape<64, 32, 8>, 
    cutlass::gemm::GemmShape<1, 1, 1>,
    cutlass::epilogue::thread::LinearCombination<
      ElementC,
      1,
      ElementAccumulator,
      ElementCompute
    >,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>,
    4,
    cutlass::arch::OpMultiplyAdd,
    cutlass::conv::IteratorAlgorithm::kOptimized,
    cutlass::conv::StrideSupport::kUnity
  >::Kernel;

  using Conv2dDgrad = cutlass::conv::device::ImplicitGemmConvolution<Conv2dDgradKernel>;

  /// Run all unit test sizes with device-level Conv2d instance
  EXPECT_TRUE(test::conv::device::TestAllConv2d<Conv2dDgrad>());

}

////////////////////////////////////////////////////////////////////////////////
#endif  // CUTLASS_ARCH_MMA_SM80_SUPPORTED
