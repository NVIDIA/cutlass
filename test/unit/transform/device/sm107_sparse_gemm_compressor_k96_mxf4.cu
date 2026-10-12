/***************************************************************************************************
 * Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cute/arch/mma_sm100_desc.hpp"                             // cute::UMMA::Major
#include "cutlass/gemm/collective/builders/sm100_common.inl"        // tag_to_umma_major_A
#include "cutlass/gemm/collective/builders/sm107_sparse_config.inl" // Sm107GemmSparseConfig
#include "cutlass/gemm/collective/builders/sm1xx_sparse_config.inl" // Sm107GemmSparseConfig
#include "cutlass/transform/kernel/sparse_gemm_compressor.hpp"      // StructuredSparseCompressor
#include "cutlass/transform/device/transform_universal_adapter.hpp" // TransformUniversalAdapter
#include "testbed_sparse_gemm_compressor.hpp"                       // TestbedSparseGemmCompressor

///////////////////////////////////////////////////////////////////////////////////////////////////
// * Test Plan
// ElementA : mxf4
// LayoutA : row (mxf4 dont support transposeA)
// Gemm : 1x 2x 3x multiplier of alignment requirement. corner case that smaller than alignment requirement
///////////////////////////////////////////////////////////////////////////////////////////////////

#if defined(CUTLASS_ARCH_MMA_SM100_SUPPORTED) || defined(CUTLASS_ARCH_MMA_SM107_SUPPORTED)

TEST(SM100_Structured_Sparse_Gemm_Compressor_Device, k96_mxf4_t_128x32)
{
  // Test Settings
  using ElementA = cutlass::float_e2m1_t;
  using LayoutATag = cutlass::layout::RowMajor;

  // Deduct From Test Setting
  using ElementAMma = cute::sparse_elem<2, ElementA>;
  using ElementEMma = cute::sparse_elem<8, uint8_t>;

  using Sm107SparseConfig = cutlass::Sm107GemmSparseConfig<ElementAMma, LayoutATag, ElementEMma>;

  using CompressorKernel = cutlass::transform::kernel::
      StructuredSparseCompressor<cute::Shape<int, int, int, int>,
                                ElementA,
                                LayoutATag,
                                Sm107SparseConfig,
                                cutlass::arch::Sm100>;

  using Compressor = cutlass::transform::device::TransformUniversalAdapter<CompressorKernel>;

  // Test Bed
  test::transform::device::TestbedSparseGemmCompressor<Compressor> testbed;
  EXPECT_TRUE(testbed.run({128, 128, 32, 1}));
}

TEST(SM100_Structured_Sparse_Gemm_Compressor_Device, k96_mxf4_t_128x64)
{
  // Test Settings
  using ElementA = cutlass::float_e2m1_t;
  using LayoutATag = cutlass::layout::RowMajor;

  // Deduct From Test Setting
  using ElementAMma = cute::sparse_elem<2, ElementA>;
  using ElementEMma = cute::sparse_elem<8, uint8_t>;

  using Sm107SparseConfig = cutlass::Sm107GemmSparseConfig<ElementAMma, LayoutATag, ElementEMma>;

  using CompressorKernel = cutlass::transform::kernel::
      StructuredSparseCompressor<cute::Shape<int, int, int, int>,
                                ElementA,
                                LayoutATag,
                                Sm107SparseConfig,
                                cutlass::arch::Sm100>;

  using Compressor = cutlass::transform::device::TransformUniversalAdapter<CompressorKernel>;

  // Test Bed
  test::transform::device::TestbedSparseGemmCompressor<Compressor> testbed;
  EXPECT_TRUE(testbed.run({128, 128, 64, 1}));
}

TEST(SM100_Structured_Sparse_Gemm_Compressor_Device, k96_mxf4_t_128x128)
{
  // Test Settings
  using ElementA = cutlass::float_e2m1_t;
  using LayoutATag = cutlass::layout::RowMajor;

  // Deduct From Test Setting
  using ElementAMma = cute::sparse_elem<2, ElementA>;
  using ElementEMma = cute::sparse_elem<8, uint8_t>;

  using Sm107SparseConfig = cutlass::Sm107GemmSparseConfig<ElementAMma, LayoutATag, ElementEMma>;

  using CompressorKernel = cutlass::transform::kernel::
      StructuredSparseCompressor<cute::Shape<int, int, int, int>,
                                ElementA,
                                LayoutATag,
                                Sm107SparseConfig,
                                cutlass::arch::Sm100>;

  using Compressor = cutlass::transform::device::TransformUniversalAdapter<CompressorKernel>;

  // Test Bed
  test::transform::device::TestbedSparseGemmCompressor<Compressor> testbed;
  EXPECT_TRUE(testbed.run({128, 128, 128, 1}));
}

TEST(SM100_Structured_Sparse_Gemm_Compressor_Device, k96_mxf4_t)
{
  // Test Settings
  using ElementA = cutlass::float_e2m1_t;
  using LayoutATag = cutlass::layout::RowMajor;

  // Deduct From Test Setting
  using ElementAMma = cute::sparse_elem<2, ElementA>;
  using ElementEMma = cute::sparse_elem<8, uint8_t>;

  using Sm107SparseConfig = cutlass::Sm107GemmSparseConfig<ElementAMma, LayoutATag, ElementEMma>;

  using CompressorKernel = cutlass::transform::kernel::
      StructuredSparseCompressor<cute::Shape<int, int, int, int>,
                                ElementA,
                                LayoutATag,
                                Sm107SparseConfig,
                                cutlass::arch::Sm100>;

  using Compressor = cutlass::transform::device::TransformUniversalAdapter<CompressorKernel>;

  // Test Bed
  test::transform::device::TestbedSparseGemmCompressor<Compressor> testbed;
  EXPECT_TRUE(testbed.run_auto());
}

#endif
