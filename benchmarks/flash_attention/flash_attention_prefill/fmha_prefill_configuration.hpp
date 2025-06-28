/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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
#include "cutlass/gemm/dispatch_policy.hpp"

namespace cutlass {
namespace flash_attention{
  template<typename DispatchPolicy, typename input, typename output> struct MMAOP {
    static_assert(cutlass::detail::dependent_false<DispatchPolicy>, "Could not find a supported MMA ATOM Operation for flash attention");
  };
  
  template <typename DispatchPolicy> struct MMAOP <DispatchPolicy, bfloat16_t, float> {
    using Type=cute::XE_8x16x16_F32BF16BF16F32_TT;
  };
  
  template <typename DispatchPolicy> struct MMAOP <DispatchPolicy, half_t, float> {
    using Type = cute::XE_8x16x16_F32F16F16F32_TT;
  };
  
template<typename ElementInputType, typename ElementAccumulatorType, typename ElementOutputType,  
          typename GmemTiledCopyQ, typename GmemTiledCopyK, typename GmemTiledCopyV, typename GmemTiledCopyO,
          typename TileShapeQK, typename TileShapePV, typename TileShapeOutput, typename SubgroupLayout, 
          bool HasCausal, bool IsVarLen, int PipelineStages>
struct FMHAPrefillConfig {

  using ElementOutput = ElementOutputType;        // <- data type of output
  using ElementInputQ = ElementInputType;    // <- data type of elements in input matrix Q
  using ElementInputK = ElementInputType;    // <- data type of elements in input matrix K
  using ElementInputV = ElementInputType;    // <- data type of elements in input matrix V
  using ElementAccumulator = ElementAccumulatorType;   // <- data type of accumulator for mma operation
  using LayoutQ = cutlass::layout::RowMajor;
  using LayoutK = cutlass::layout::ColumnMajor;
  using LayoutV = cutlass::layout::RowMajor;
  using LayoutO = cutlass::layout::RowMajor;
  static constexpr bool Causal = HasCausal;
  static constexpr bool VarLen = IsVarLen;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;
  using MMAOperation = typename MMAOP<GEMMDispatchPolicy, ElementInputType,ElementAccumulator>::Type;
  using CollectiveEpilogue = cutlass::flash_attention::collective::FlashPrefillEpilogue<
                                    EpilogueDispatchPolicy, MMAOperation, TileShapeOutput, 
                                    SubgroupLayout, ElementAccumulator, ElementOutputType,
                                    cutlass::gemm::TagToStrideC_t<LayoutO>, ElementOutput,
                                    GmemTiledCopyO>;

 using CollectiveSoftmaxEpilogue = cutlass::flash_attention::collective::FlashPrefillSoftmaxEpilogue<Causal, 
                                EpilogueDispatchPolicy, ElementAccumulator>;

  using ProblemShapeRegular = cute::tuple<int, int, int, int, int, int, int>;
  using ProblemShapeVarlen = cute::tuple<int, int, int, fmha::collective::VariableLength, fmha::collective::VariableLength, int, int>;
  using ProblemShapeType = std::conditional_t<VarLen, ProblemShapeVarlen, ProblemShapeRegular>;

  // Mainloop
  using CollectiveMainloop = 
        cutlass::flash_attention::collective::FlashPrefillMma<GEMMDispatchPolicy, ProblemShapeType, 
                                                              ElementInputQ, cutlass::gemm::TagToStrideA_t<LayoutQ>, 
                                                              ElementInputK,cutlass::gemm::TagToStrideB_t<LayoutK>, 
                                                              ElementInputV, cutlass::gemm::TagToStrideB_t<LayoutV>, 
                                                              MMAOperation, TileShapeQK, TileShapePV, SubgroupLayout,
                                                              GmemTiledCopyQ, 
                                                              GmemTiledCopyK, 
                                                              GmemTiledCopyV, 
                                                              Causal>;

  using GemmKernel = cutlass::flash_attention::kernel::FMHAPrefill<ProblemShapeType, CollectiveMainloop,
                                                                    CollectiveSoftmaxEpilogue, CollectiveEpilogue>;
};

} // namespace flash_attention
} // namespace cutlass
