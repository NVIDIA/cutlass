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
#include <cutlass/gemm/dispatch_policy.hpp>

#include "cutlass/gemm/collective/collective_mma.hpp"

namespace cutlass::gemm::collective {

  // Intel PVC 3 stage pipeline, using prefetch
  // Also the auto builder

template <
  class ElementA,
  class GmemLayoutATag,
  int AlignmentA,
  class ElementB,
  class GmemLayoutBTag,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class KernelScheduleType
  > 
struct CollectiveBuilder<
  arch::IntelPVC,
  arch::OpClassTensorOp,   // Reusing opClassTensorOp for Intel devices
  ElementA,
  GmemLayoutATag,
  AlignmentA,
  ElementB,
  GmemLayoutBTag,
  AlignmentB,
  ElementAccumulator,
  TileShape_MNK,
  Shape<_1, _1, _1>,    // Cluster Shape
  cutlass::gemm::collective::StageCountAuto, 
  KernelScheduleType,
  cute::enable_if_t<
    (cute::is_same_v<KernelScheduleType, KernelPVC> ||
     cute::is_same_v<KernelScheduleType, KernelScheduleAuto>) &&  
    cute::is_same_v<GmemLayoutATag, cutlass::layout::RowMajor> && // Different struct specialization because this will change copy atoms
    cute::is_same_v<GmemLayoutBTag, cutlass::layout::RowMajor>
  >
    >{

      #ifdef SYCL_NVIDIA_TARGET
        static_assert(cutlass::detail::dependent_false<arch::IntelPVC>, 
          "Trying to use Intel pipeline on Non Intel hardware");
      #endif
      static_assert(is_static<TileShape_MNK>::value);
      static_assert(cute::is_same_v<ElementA, bfloat16_t>, "Intel multi-stage pipeline requires ElementA to be of type bfloat16_t");
      static_assert(cute::is_same_v<ElementB, bfloat16_t>, "Intel multi-stage pipeline requires ElementB to be of type bfloat16_t");
      static_assert(cute::is_same_v<ElementAccumulator, float>, "Intel multi-stage pipeline requires ElementC to be of type float");

      //Prepare Template arguments required of CollectiveMainLoop

      using Tile_M = decltype(get<0>(TileShape_MNK{}));
      using Tile_N = decltype(get<1>(TileShape_MNK{}));
      using Tile_K = decltype(get<2>(TileShape_MNK{}));
      using Atom_M = decltype(get<0>(typename MMA_Traits<XE_8x16x16_F32BF16BF16F32_TT>::Shape_MNK{}));
      using Atom_N = decltype(get<1>(typename MMA_Traits<XE_8x16x16_F32BF16BF16F32_TT>::Shape_MNK{}));
      using SGs_M = _8;
      using SGs_N = _4;
      using Iters_M = decltype(Tile_M{} / Atom_M{} / SGs_M{});
      using Iters_N = decltype(Tile_N{} / Atom_N{} / SGs_N{});
      using Stride_M = decltype(Iters_M{} * Atom_M{});
      using Stride_N = decltype(Iters_N{} * Atom_N{});

      using TiledMma =
          TiledMMA<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
                   Layout<Shape<SGs_M, SGs_N, _1>, Stride<SGs_N, _1, _0>>,
                   Tile<Layout<Shape<Atom_M, SGs_M, Iters_M>, Stride<_1, Stride_M, Atom_M>>,
                        Layout<Shape<Atom_N, SGs_N, Iters_N>, Stride<_1, Stride_N, Atom_N>>, Tile_K>>;
      
      static constexpr int PipelineStages = 3;
      using DispatchPolicy = cutlass::gemm::MainloopIntelPVC<PipelineStages>;

      using GmemTiledCopyA = XE_2D_U16x16x16_LD_N;
      using GmemTiledCopyB = XE_2D_U16x16x16_LD_V;

      //PVC pipeline does not use shared memory
      using SmemLayoutAtomA = void; 
      using SmemLayoutAtomB = void; 
      using SmemCopyAtomA = void;
      using SmemCopyAtomB = void;

      using TransformA = cute::identity;
      using TransformB = cute::identity;

      using CollectiveOp = cutlass::gemm::collective::CollectiveMma<
              DispatchPolicy,
              TileShape_MNK,
              ElementA,
              cutlass::gemm::TagToStrideA_t<GmemLayoutATag>,
              ElementB,
              cutlass::gemm::TagToStrideB_t<GmemLayoutBTag>,
              TiledMma,
              GmemTiledCopyA,
              SmemLayoutAtomA,
              SmemCopyAtomA,
              TransformA,
              GmemTiledCopyB,
              SmemLayoutAtomB,
              SmemCopyAtomB,
              TransformB
          >;
    };
}
