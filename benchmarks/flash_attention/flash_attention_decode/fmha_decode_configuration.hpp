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
    using TYPE = cute::XE_1x16x16_F32BF16BF16F32_TT;
};

template <typename DispatchPolicy> struct MMAOP <DispatchPolicy, half_t, float> {
    using TYPE = cute::XE_1x16x16_F32F16F16F32_TT;
};

template <typename ElementInputType_, typename ElementAccumulatorType_, typename ElementOutputType_,
          typename GmemTiledCopyQ_, typename GmemTiledCopyK_, typename GmemTiledCopyV_, typename GmemTiledCopyO_, 
          typename TileShapeQK_, typename TileShapePV_, typename TileShapeOutput_, typename SubgroupLayout_,
          bool Causal_, bool VarLen_>
struct FMHADecodeConfig {

  using ElementO = ElementOutputType_;     // <- data type of output
  using ElementInputQ = ElementInputType_;     // <- data type of elements in input matrix Q
  using ElementInputK = ElementInputType_;    // <- data type of elements in input matrix K
  using ElementInputV = ElementInputType_;    // <- data type of elements in input matrix V
  using ElementAccumulator = ElementAccumulatorType_; // <- data type of accumulator

  using LayoutQ = cutlass::layout::RowMajor;
  using LayoutK = cutlass::layout::ColumnMajor;
  using LayoutV = cutlass::layout::RowMajor;
  using LayoutO = cutlass::layout::RowMajor;

  using TileShapeQK = TileShapeQK_;
  using TileShapePV = TileShapePV_;
  using TileShapeOutput = TileShapeOutput_;
  using SubgroupLayout = SubgroupLayout_;

  static constexpr bool Causal = Causal_;
  static constexpr bool VarLen = VarLen_;
  
  static constexpr int PipelineStages = 2;
  using GEMMDispatchPolicy = cutlass::gemm::MainloopIntelXeXMX16<PipelineStages>;
  using EpilogueDispatchPolicy = cutlass::epilogue::IntelXeXMX16;

  using MMAOperation = typename MMAOP<GEMMDispatchPolicy, ElementInputQ, ElementAccumulator>::TYPE;

  using GmemTiledCopyQ = GmemTiledCopyQ_;
  using GmemTiledCopyK = GmemTiledCopyK_;
  using GmemTiledCopyV = GmemTiledCopyV_;
  using GmemTiledCopyO = GmemTiledCopyO_;
  using CollectiveEpilogue = cutlass::flash_attention::collective::FlashDecodeEpilogue<
      EpilogueDispatchPolicy, MMAOperation, TileShapeOutput, SubgroupLayout, ElementAccumulator, cutlass::gemm::TagToStrideC_t<LayoutO>, ElementO,
      GmemTiledCopyO>;

  using CollectiveSoftmaxEpilogue = cutlass::flash_attention::collective::FlashDecodeSoftmaxEpilogue<Causal, EpilogueDispatchPolicy, ElementAccumulator>;

  using ProblemShapeRegular = cute::tuple<int, int, int, int, int, int, int, int>;
  using ProblemShapeVarlen = cute::tuple<int, int, int, fmha::collective::VariableLength, fmha::collective::VariableLength, fmha::collective::VariableLength, int, int>;
  using ProblemShapeType = std::conditional_t<VarLen, ProblemShapeVarlen, ProblemShapeRegular>;

  // Mainloop
  using CollectiveMainloop = cutlass::flash_attention::collective::FlashDecodeMma<
      GEMMDispatchPolicy, ProblemShapeType, ElementInputQ, cutlass::gemm::TagToStrideA_t<LayoutQ>, ElementInputK,
      cutlass::gemm::TagToStrideB_t<LayoutK>, ElementInputV, cutlass::gemm::TagToStrideB_t<LayoutV>, MMAOperation,
      TileShapeQK, TileShapePV, SubgroupLayout,
      GmemTiledCopyQ, // Q
      GmemTiledCopyK, // K
      GmemTiledCopyV, // V,
      Causal>;

  using FMHADecodeKernel = cutlass::flash_attention::kernel::FMHADecode<ProblemShapeType, CollectiveMainloop,
                                                                    CollectiveSoftmaxEpilogue, CollectiveEpilogue>;
};

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
template <int KVTile, int NumSGs>
struct Shape_h64 {
  using ShapeQK = Shape<_1, Int<KVTile>, _64>;
  using ShapePV = Shape<_1, _32, Int<KVTile>>;
  using ShapeOutput = Shape<_1, _64, Int<KVTile>>;
  using SubgroupLayout = Layout<Shape<Int<NumSGs>, _1, _1>>;
};

template <int KVTile, int NumSGs>
struct Shape_h96 {
  using ShapeQK = Shape<_1, Int<KVTile>, _64>;
  using ShapePV = Shape<_1, _32, Int<KVTile>>;
  using ShapeOutput = Shape<_1, _96, Int<KVTile>>;
  using SubgroupLayout = Layout<Shape<Int<NumSGs>, _1, _1>>;
};

template <int KVTile, int NumSGs>
struct Shape_h128 {
  using ShapeQK = Shape<_1, Int<KVTile>, _64>;
  using ShapePV = Shape<_1, _32, Int<KVTile>>;
  using ShapeOutput = Shape<_1, _128, Int<KVTile>>;
  using SubgroupLayout = Layout<Shape<Int<NumSGs>, _1, _1>>;
};

template <int KVTile, int NumSGs>
struct Shape_h192 {
  using ShapeQK = Shape<_1, Int<KVTile>, _64>;
  using ShapePV = Shape<_1, _32, Int<KVTile>>;
  using ShapeOutput = Shape<_1, _192, Int<KVTile>>;
  using SubgroupLayout = Layout<Shape<Int<NumSGs>, _1, _1>>;
};

template<class QKVType, bool Causal, bool VarLen, class TileShapeConfig>
struct FMHADecodeConfigGen {

using GmemTiledCopyQ = cute::XE_2D_U16x1x16_LD_N;
using GmemTiledCopyK = cute::XE_2D_U16x16x16_LD_T;
using GmemTiledCopyV = cute::XE_2D_U16x32x32_LD_V;
using GmemTiledCopyO = cute::XE_2D_U32x1x16_ST_N;

using type = cutlass::flash_attention::FMHADecodeConfig<
      QKVType, float, float, GmemTiledCopyQ, GmemTiledCopyK, GmemTiledCopyV,
      GmemTiledCopyO, typename TileShapeConfig::ShapeQK, typename TileShapeConfig::ShapePV,
      typename TileShapeConfig::ShapeOutput, typename TileShapeConfig::SubgroupLayout,
      Causal, VarLen>;
};

} // namespace flash_attention
} // namespace cutlass
