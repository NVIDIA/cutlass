/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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

#pragma once

#include "gemm_configuration.hpp"

template <
    typename LayoutA,
    typename LayoutB,
    typename LayoutC,
    typename LayoutD
    >
struct AmpereGemmFP16FP16FP32 {
  using ElementAccumulator = float;
  using ElementComputeEpilogue = float;
  using ElementInputA = half_t;
  using ElementInputB = half_t;
  using ElementOutput = float;

  using TileShape = Shape<_128, _128, _32>;

  using TiledMma = TiledMMA<
          MMA_Atom<SM80_16x8x16_F32F16F16F32_TN>,
          Layout<Shape<_2,_2,_1>>,
          Tile<_32,_32,_16>>;

  static constexpr int kAlignmentA = 8;
  using DefaultOperandA = DefaultGemm_TensorOpSm80_OperandA<
          ElementInputA, LayoutA, kAlignmentA, 32>;
  using SmemLayoutAtomA = typename DefaultOperandA::SmemLayoutAtom; // M, K
  using SmemCopyAtomA = typename DefaultOperandA::SmemCopyAtom;
  using GmemTiledCopyA = typename DefaultOperandA::GmemTiledCopy;

  static constexpr int kAlignmentB = 8;
  using DefaultOperandB = DefaultGemm_TensorOpSm80_OperandB<
          ElementInputB, LayoutB, kAlignmentB, 32>;
  using SmemLayoutAtomB = typename DefaultOperandB::SmemLayoutAtom; // N, K
  using SmemCopyAtomB = typename DefaultOperandB::SmemCopyAtom;
  using GmemTiledCopyB = typename DefaultOperandB::GmemTiledCopy;

  using Stages = Int<3>;

  // This code section describes the epilogue part of the kernel
  using EpilogueOp = cutlass::epilogue::thread::LinearCombination<
          ElementOutput,                                     // <- data type of output matrix
          128 / cutlass::sizeof_bits<ElementOutput>::value,  // <- the number of elements per vectorized
                                                             // memory access. For a byte, it's 16
                                                             // elements. This becomes the vector width of
                                                             // math instructions in the epilogue too
          ElementAccumulator,                                // <- data type of accumulator
          ElementComputeEpilogue>;  // <- data type for alpha/beta in linear combination function

  using DispatchPolicy = cutlass::gemm::MainloopSm80CpAsync<Stages{}>;

  // Define strides (mixed)
  using StrideA = cutlass::detail::TagToStrideA_t<LayoutA>;
  using StrideB = cutlass::detail::TagToStrideB_t<LayoutB>;
  using StrideC = cutlass::detail::TagToStrideC_t<LayoutC>;
  using StrideD = cutlass::detail::TagToStrideC_t<LayoutD>;

  using CollectiveEpilogue = cutlass::epilogue::collective::DefaultEpilogue<
          StrideC,
          StrideD,
          EpilogueOp,
          cutlass::gemm::EpilogueDefault>;

  // Mainloop
  using CollectiveMainloop = cutlass::gemm::collective::CollectiveMma<
          DispatchPolicy,
          TileShape,
          ElementInputA,
          StrideA,
          ElementInputB,
          StrideB,
          TiledMma,
          GmemTiledCopyA, SmemLayoutAtomA, SmemCopyAtomA, cute::identity,  // A
          GmemTiledCopyB, SmemLayoutAtomB, SmemCopyAtomB, cute::identity   // B
  >;

  using GemmKernel = cutlass::gemm::kernel::GemmUniversal<
          Shape<int, int, int, int>,
          CollectiveMainloop,
          CollectiveEpilogue
  >;

  using Gemm = cutlass::gemm::device::GemmUniversalAdapter<GemmKernel>;
};

using AmpereGemmFP16FP16FP32_CCCC = AmpereGemmFP16FP16FP32<
    cutlass::layout::ColumnMajor,
    cutlass::layout::ColumnMajor,
    cutlass::layout::ColumnMajor,
    cutlass::layout::ColumnMajor>;
