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

#include <cutlass/arch/arch.h>
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/collective/intel_pvc_epilogue.hpp"
#include "cutlass/epilogue/fusion/intel_pvc_callbacks.hpp"


namespace cutlass::epilogue::collective {

  // Intel epilogue builder

template <
  class TileShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC,
  class GmemLayoutTagC,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class FusionOpOrCallbacks
  >
  struct CollectiveBuilder<
      arch::IntelPVC,
      arch::OpClassTensorOp, 
      TileShape_MNK,
      Shape<_1, _1, _1>,    // Cluster Shape
      EpilogueTileType,
      ElementAccumulator,
      ElementCompute,
      ElementC,
      GmemLayoutTagC,
      AlignmentC,
      ElementD,
      GmemLayoutTagD,
      AlignmentD,
      EpilogueScheduleAuto, // We do not have different type of epilogue support yet
      FusionOpOrCallbacks,
      cute::enable_if_t<
        cute::is_same_v<GmemLayoutTagC,  cutlass::layout::RowMajor> &&
        cute::is_same_v<GmemLayoutTagD,  cutlass::layout::RowMajor> &&
        cute::is_same_v<EpilogueTileType, EpilogueTileAuto> &&
        // Only linear combination is supported at the moment
        (cute::is_same_v<FusionOpOrCallbacks, 
                        cutlass::epilogue::fusion::LinearCombination<ElementD,ElementCompute,ElementC,ElementCompute>> ||
        cute::is_same_v<FusionOpOrCallbacks,
                        cutlass::epilogue::fusion::LinCombEltAct<cutlass::epilogue::thread::ReLu,
                        ElementD,ElementCompute,ElementC,ElementCompute>>)
      >
    >{
      #ifdef SYCL_NVIDIA_TARGET
        static_assert(cutlass::detail::dependent_false<arch::IntelPVC>, 
          "Trying to use Intel pipeline on Non Intel hardware");
      #endif
      static_assert(is_static<TileShape_MNK>::value);
      static_assert(cute::is_same_v<ElementC, float>, "ElementC needs to be float for the Intel pipeline");
      
      using TiledMma = TiledMMA<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
              Layout<Shape<_1,_1,_1>>,
              Tile<_32,_64,_32>>;  // Subgroup level-tile
      
      using DispatchPolicy = cutlass::epilogue::IntelPVCEpilogue;
      using CopyOpG2R = XE_2D_U32x8x16x1x1_LD_N;
      using CopyOpR2G = XE_2D_U32x8x16x1x1_ST_N;

      // Intel Epilogue with Linear Combination does not use shared memory
      using SmemLayoutAtomC_ = void;
      using CopyOpS2R_ = void;
      using SmemLayoutAtomD_ = void;
      using CopyOpR2S_ = void;

      using FusionCallBacks = cutlass::epilogue::fusion::FusionCallbacks<
          DispatchPolicy, FusionOpOrCallbacks, TileShape_MNK,
          decltype(tile_shape(TiledMma()))>;

      using CollectiveOp = cutlass::epilogue::collective::CollectiveEpilogue<
            DispatchPolicy,
            TileShape_MNK,
            ElementAccumulator,
            cutlass::gemm::TagToStrideC_t<GmemLayoutTagC>,
            ElementD,
            cutlass::gemm::TagToStrideC_t<GmemLayoutTagD>,
            FusionCallBacks,
            CopyOpG2R,
            SmemLayoutAtomC_,
            CopyOpS2R_,
            CopyOpR2G,
            SmemLayoutAtomD_,
            CopyOpR2S_   
        >;
    };
}
