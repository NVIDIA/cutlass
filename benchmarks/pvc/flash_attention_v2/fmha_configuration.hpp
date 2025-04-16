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

namespace cutlass {
namespace flash_attention{

template <typename ElementQ_, typename ElementK_, typename ElementV_, typename LayoutQ_,
          typename LayoutK_, typename LayoutV_, typename LayoutO_, bool Causal_, bool VarLen_,
          typename TileShape_, typename TiledMma_> 
struct FMHAConfig {

  using ElementO = float;     // <- data type of accumulator
  using ElementInputQ = ElementQ_;     // <- data type of elements in input matrix Q
  using ElementInputK = ElementK_;    // <- data type of elements in input matrix K
  using ElementInputV = ElementV_;    // <- data type of elements in input matrix V

  using LayoutQ = LayoutQ_;
  using LayoutK = LayoutK_;
  using LayoutV = LayoutV_;
  using LayoutO = LayoutO_;

  using TileShape = TileShape_;
  using TiledMma = TiledMma_;

  static constexpr bool Causal = Causal_;
  static constexpr bool VarLen = VarLen_;
  
  static constexpr int PipelineStages = 2;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelPVC<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelPVCEpilogue;

  using GmemTiledCopyQ = XE_2D_U16x16x32_LD_N;
  using GmemTiledCopyK = XE_2D_U16x16x16_LD_T;
  using GmemTiledCopyV = XE_2D_U16x32x32_LD_V;
  using GmemTiledCopyO = XE_2D_U32x8x16_ST_N;
  using CollectiveEpilogue = cutlass::flash_attention::collective::CollectiveEpilogueAttention<
      EpilogueDispatchPolicy, TileShape, ElementO, cutlass::gemm::TagToStrideC_t<LayoutO>, ElementO,
      GmemTiledCopyO>;

  using CollectiveSoftmaxEpilogue = cutlass::flash_attention::collective::CollectiveSoftmaxEpilogue<Causal, EpilogueDispatchPolicy, ElementO>;

  using ProblemShapeRegular = cute::tuple<int, int, int, int, int, int, int>;
  using ProblemShapeVarlen = cute::tuple<int, int, int, fmha::collective::VariableLength, fmha::collective::VariableLength, int, int>;
  using ProblemShapeType = std::conditional_t<VarLen, ProblemShapeVarlen, ProblemShapeRegular>;

  // Mainloop
  using CollectiveMainloop = cutlass::flash_attention::collective::CollectiveMmaAttention<
      GEMMDispatchPolicy, ProblemShapeType, TileShape, ElementInputQ, cutlass::gemm::TagToStrideA_t<LayoutQ>, ElementInputK,
      cutlass::gemm::TagToStrideB_t<LayoutK>, ElementInputV, cutlass::gemm::TagToStrideB_t<LayoutV>, TiledMma,
      GmemTiledCopyQ, // Q
      GmemTiledCopyK, // K
      GmemTiledCopyV, // V,
      Causal>;

  using GemmKernel = cutlass::flash_attention::kernel::GemmUniversalAttention<ProblemShapeType, CollectiveMainloop,
                                                                    CollectiveSoftmaxEpilogue, CollectiveEpilogue>;
};

} // namespace flash_attention
} // namespace cutlass
