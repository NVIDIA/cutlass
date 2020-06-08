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
    \brief Tests for device-level GEMM API for Planar Complex.
*/

#include <iostream>

#include "../../common/cutlass_unit_test.h"
#include "cutlass/cutlass.h"

#include "cutlass/gemm/kernel/default_gemm_planar_complex_universal.h"
#include "cutlass/gemm/device/gemm_universal_adapter.h"

#include "testbed_planar_complex.h"

#if defined(CUTLASS_ARCH_MMA_SM70_SUPPORTED)

////////////////////////////////////////////////////////////////////////////////

using gemm_planar_complex_s884_tn_base = typename cutlass::gemm::kernel::DefaultGemmPlanarComplexUniversal<
  cutlass::half_t,
  cutlass::layout::RowMajor,
  cutlass::ComplexTransform::kNone,
  8,
  cutlass::half_t,
  cutlass::layout::ColumnMajor,
  cutlass::ComplexTransform::kNone,
  8,
  float,
  cutlass::layout::RowMajor,
  float,
  cutlass::arch::OpClassTensorOp,
  cutlass::arch::Sm70,
  cutlass::gemm::GemmShape<64, 64, 32>,
  cutlass::gemm::GemmShape<32, 32, 32>,
  cutlass::gemm::GemmShape<8, 8, 4>,
  cutlass::epilogue::thread::LinearCombinationPlanarComplex<
    float,
    4,
    float,
    float
  >,
  cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>,
  2,
  cutlass::arch::OpMultiplyAdd
>::GemmKernel;

struct gemm_planar_complex_s884_tn : gemm_planar_complex_s884_tn_base {

};

////////////////////////////////////////////////////////////////////////////////

TEST(SM70_Device_GemmPlanarComplex_f16t_f16n_f32n_tensor_op_f32_884, 64x64x32_32x32x32) {

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<gemm_planar_complex_s884_tn>;

  EXPECT_TRUE(test::gemm::device::TestAllGemmPlanarComplex<Gemm>());
}


////////////////////////////////////////////////////////////////////////////////

using gemm_planar_complex_s884_nt_base = typename cutlass::gemm::kernel::DefaultGemmPlanarComplexUniversal<
  cutlass::half_t,
  cutlass::layout::ColumnMajor,
  cutlass::ComplexTransform::kNone,
  8,
  cutlass::half_t,
  cutlass::layout::RowMajor,
  cutlass::ComplexTransform::kNone,
  8,
  float,
  cutlass::layout::RowMajor,
  float,
  cutlass::arch::OpClassTensorOp,
  cutlass::arch::Sm70,
  cutlass::gemm::GemmShape<64, 64, 32>,
  cutlass::gemm::GemmShape<32, 32, 32>,
  cutlass::gemm::GemmShape<8, 8, 4>,
  cutlass::epilogue::thread::LinearCombinationPlanarComplex<
    float,
    4,
    float,
    float
  >,
  cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<>,
  2,
  cutlass::arch::OpMultiplyAdd
>::GemmKernel;

struct gemm_planar_complex_s884_nt : gemm_planar_complex_s884_nt_base {

};

////////////////////////////////////////////////////////////////////////////////

TEST(SM70_Device_GemmPlanarComplex_f16n_f16t_f32n_tensor_op_f32_884, 64x64x32_32x32x32) {

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<gemm_planar_complex_s884_nt>;

  EXPECT_TRUE(test::gemm::device::TestAllGemmPlanarComplex<Gemm>());
}


////////////////////////////////////////////////////////////////////////////////

#endif // #if defined(CUTLASS_ARCH_MMA_SM70_SUPPORTED)
