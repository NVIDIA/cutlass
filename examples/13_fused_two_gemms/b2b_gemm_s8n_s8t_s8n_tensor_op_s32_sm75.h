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
#pragma once

#include <iostream>

#include "cutlass/cutlass.h"
#include "cutlass/gemm/device/gemm.h"

#include "cutlass/util/host_tensor.h"
#include "cutlass/util/tensor_view_io.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/util/reference/host/tensor_copy.h"
#include "cutlass/util/reference/host/tensor_compare.h"
#include "cutlass/util/reference/host/gemm.h"

#include "device/b2b_gemm.h"
#include "b2b_interleaved_gemm_run.h"

#if defined(CUTLASS_ARCH_MMA_SM75_SUPPORTED)

////////////////////////////////////////////////////////////////////////////////

void run_nonfused_gemm_s8() {

  using ElementOutput = int8_t;
  using ElementAccumulator = int32_t;
  using ElementCompute = float;

  cutlass::gemm::GemmCoord problem_size_0(128*1600, 64, 576);
  cutlass::gemm::GemmCoord problem_size_1(128*1600, 128, 64);
  ElementCompute alpha0 = ElementCompute(2);
  ElementCompute beta0 = ElementCompute(0);
  ElementCompute alpha1 = ElementCompute(2);
  ElementCompute beta1 = ElementCompute(1);

  using ThreadblockShape0 = cutlass::gemm::GemmShape<64, 64, 64>;
  using WarpShape0 = cutlass::gemm::GemmShape<32, 32, 64>;
  using ThreadblockShape1 = cutlass::gemm::GemmShape<64, 64, 64>;
  using WarpShape1 = cutlass::gemm::GemmShape<32, 32, 64>;
  using InstructionShape = cutlass::gemm::GemmShape<8, 8, 16>;

  using Gemm0 = cutlass::gemm::device::Gemm<
    int8_t,
    cutlass::layout::ColumnMajorInterleaved<32>,
    int8_t,
    cutlass::layout::RowMajorInterleaved<32>,
    ElementOutput,
    cutlass::layout::ColumnMajorInterleaved<32>,
    ElementAccumulator,
    cutlass::arch::OpClassTensorOp,
    cutlass::arch::Sm75,
    ThreadblockShape0,
    WarpShape0,
    InstructionShape,
    cutlass::epilogue::thread::LinearCombinationRelu<
      ElementOutput,
      64 / cutlass::sizeof_bits<ElementOutput>::value,
      ElementAccumulator,
      ElementCompute
    >,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<1>,
    2
  >;
  using Gemm1 = cutlass::gemm::device::Gemm<
    int8_t,
    cutlass::layout::ColumnMajorInterleaved<32>,
    int8_t,
    cutlass::layout::RowMajorInterleaved<32>,
    ElementOutput,
    cutlass::layout::ColumnMajorInterleaved<32>,
    ElementAccumulator,
    cutlass::arch::OpClassTensorOp,
    cutlass::arch::Sm75,
    ThreadblockShape1,
    WarpShape1,
    InstructionShape,
    cutlass::epilogue::thread::LinearCombinationRelu<
      ElementOutput,
      64 / cutlass::sizeof_bits<ElementOutput>::value,
      ElementAccumulator,
      ElementCompute
    >,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<1>,
    2
  >;

  B2bInterleavedNonFusedGemmRun<Gemm0, Gemm1, 32> nonFusedGemm;

  std::cout << "Running Non-fused back-to-back INT8 NT interleaved GEMMs...\n";
  bool pass = nonFusedGemm.run(problem_size_0, problem_size_1, alpha0, beta0, alpha1, beta1);
  if(pass)
    std::cout << "Pass\n";
  else
    std::cout << "Fail\n";
}

void run_fused_gemm_s8() {

  using ElementOutput = int8_t;
  using ElementAccumulator = int32_t;
  using ElementCompute = float;

  cutlass::gemm::GemmCoord problem_size_0(128*1600, 64, 576);
  cutlass::gemm::GemmCoord problem_size_1(128*1600, 128, 64);
  ElementCompute alpha0 = ElementCompute(2);
  ElementCompute beta0 = ElementCompute(0);
  ElementCompute alpha1 = ElementCompute(2);
  ElementCompute beta1 = ElementCompute(1);

  using ThreadblockShape0 = cutlass::gemm::GemmShape<128, 64, 64>;
  using WarpShape0 = cutlass::gemm::GemmShape<32, 64, 64>;
  using ThreadblockShape1 = cutlass::gemm::GemmShape<128, 128, 64>;
  using WarpShape1 = cutlass::gemm::GemmShape<32, 128, 64>;
  using InstructionShape = cutlass::gemm::GemmShape<8, 8, 16>;

  using EpilogueOutputOp0 = 
    cutlass::epilogue::thread::LinearCombinationRelu<
      ElementOutput,
      InstructionShape::kM * InstructionShape::kN / 32,
      ElementAccumulator,
      ElementCompute
    >;

  using EpilogueOutputOp1 = 
    cutlass::epilogue::thread::LinearCombinationRelu<
      ElementOutput,
      64 / cutlass::sizeof_bits<ElementOutput>::value,
      ElementAccumulator,
      ElementCompute
    >;



  using B2bGemm = cutlass::gemm::device::B2bGemm<
    int8_t,
    cutlass::layout::ColumnMajorInterleaved<32>,
    int8_t,
    cutlass::layout::RowMajorInterleaved<32>,
    ElementOutput,
    cutlass::layout::ColumnMajorInterleaved<32>,
    ElementAccumulator,
    cutlass::arch::OpClassTensorOp,
    cutlass::arch::Sm75,
    ThreadblockShape0,
    ThreadblockShape1,
    WarpShape0,
    WarpShape1,
    InstructionShape,
    EpilogueOutputOp0,
    EpilogueOutputOp1,
    cutlass::gemm::threadblock::GemmIdentityThreadblockSwizzle<1>,
    2
  >;

  B2bInterleavedFusedGemmRun<B2bGemm, 32> fusedGemm;

  std::cout << "Running Fused back-to-back INT8 NT interleaved GEMMs...\n";
  bool passed = fusedGemm.run(problem_size_0, problem_size_1, alpha0, beta0, alpha1, beta1);
  if(passed)
    std::cout << "Pass\n";
  else
    std::cout << "Fail\n";

}
////////////////////////////////////////////////////////////////////////////////

#endif  // #if defined(CUTLASS_ARCH_MMA_SM75_SUPPORTED)
