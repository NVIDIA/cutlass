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

#include "cute/atom/mma_atom.hpp"
#include "cute/atom/copy_atom.hpp"

#include "cutlass/cutlass.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/arch/arch.h"
#include "cutlass/arch/mma.h"
#include "cutlass/layout/layout.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/gemm/collective/collective_mma.hpp"
#include "cutlass/epilogue/collective/collective_builder.hpp"

#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"

using namespace cute;

namespace cutlass {
namespace gemm {
namespace device {

template<
  class ArchTag,
  class ElementA, class LayoutA,
  class ElementB, class LayoutB,
  class ElementC, class LayoutC,
  class ElementAccumulator>
struct GemmConfiguration {
  static_assert(sizeof(ElementA) == 0, "No valid GemmConfiguration configuration exists.");
};

/////////////////////////////////////////////////////////////////////////

// bfloat16

namespace detail {

template<typename Element, typename Layout>
struct Gemm_OperandA;

template<typename Element, typename Layout>
struct Gemm_OperandB;

template<>
struct Gemm_OperandA<bfloat16_t, layout::RowMajor> {
  using GmemTiledCopy = XE_2D_U16x32x32_LD_N;
};

template<>
struct Gemm_OperandB<bfloat16_t, layout::RowMajor> {
  using GmemTiledCopy = XE_2D_U16x32x32_LD_V;
};

} // namespace details

template<typename LayoutA, typename LayoutB, typename LayoutC>
struct GemmConfiguration<
      arch::IntelPVC,
      bfloat16_t, LayoutA,
      bfloat16_t, LayoutB,
      float, LayoutC,
      float> {
  using TileShape = Shape<_256, _256, _32>;
  using DispatchPolicy = MainloopIntelPVC<3>;;
  using TiledMma = TiledMMA<
    MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
    Layout<Shape<_8,_4,_1>>,
    Tile<_64,_64,_32>>;

  // A
  using OperandA = detail::Gemm_OperandA<bfloat16_t, LayoutA>;
  using GmemTiledCopyA = typename OperandA::GmemTiledCopy;

  // B
  using OperandB = detail::Gemm_OperandB<bfloat16_t, LayoutB>;
  using GmemTiledCopyB = typename OperandB::GmemTiledCopy;

  // Mainloop
  using CollectiveMainloop = collective::CollectiveMma<
    DispatchPolicy, TileShape,
    bfloat16_t, TagToStrideA_t<LayoutA>,
    bfloat16_t, TagToStrideB_t<LayoutB>,
    TiledMma,
    GmemTiledCopyA, void, void, identity, // A
    GmemTiledCopyB, void, void, identity // B
  >;

  // Epilogue
  using EpilogueDispatchPolicy = epilogue::IntelPVCEpilogue;
  using EpilogueOp = epilogue::fusion::LinearCombination<float, float, float, float, FloatRoundStyle::round_to_nearest>;
  using FusionCallBacks = epilogue::fusion::FusionCallbacks<EpilogueDispatchPolicy, EpilogueOp, TileShape,
          decltype(tile_shape(TiledMma()))>;

  using CollectiveEpilogue = epilogue::collective::CollectiveEpilogue<
        EpilogueDispatchPolicy,
        TileShape,
        float,
        TagToStrideC_t<LayoutC>,
        float,
        TagToStrideC_t<LayoutC>,
        FusionCallBacks,
        XE_2D_U32x8x16_LD_N,
        void, void,
        XE_2D_U32x8x16_ST_N,
        void, void>;

  using GemmKernel = kernel::GemmUniversal<
    Shape<int, int, int, int>,
    CollectiveMainloop,
    CollectiveEpilogue
  >;

  using Gemm = GemmUniversalAdapter<GemmKernel>;
};

} // namespace device
} // namespace gemm
} // namespace cutlass
