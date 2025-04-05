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
    cute::is_any_of_v<KernelScheduleType, KernelScheduleAuto, KernelPVC, KernelPVCCooperative, KernelPVCPtrArrayCooperative> &&
    cute::is_same_v<ElementA, ElementB> &&
    cute::is_any_of_v<ElementA, bfloat16_t, half_t> &&
    cute::is_any_of_v<ElementB, bfloat16_t, half_t>
  >
    >{

      #ifdef SYCL_NVIDIA_TARGET
        static_assert(cutlass::detail::dependent_false<arch::IntelPVC>, 
          "Trying to use Intel pipeline on Non Intel hardware");
      #endif
      static_assert(is_static<TileShape_MNK>::value);
      static_assert(cute::is_same_v<ElementAccumulator, float>, "Intel multi-stage pipeline requires ElementC to be of type float");

      using MMAAtom = MMA_Atom<std::conditional_t<cute::is_same_v<ElementA, bfloat16_t>,
                                                  XE_8x16x16_F32BF16BF16F32_TT,
                                                  XE_8x16x16_F32F16F16F32_TT>>;
      
      // Prepare Template arguments required of CollectiveMainLoop
      using atoms_M = _8;
      using atoms_N = _4;
      using TiledMma =
          typename TiledMMAHelper<MMAAtom,
                                  Layout<TileShape_MNK>,
                                  Layout<Shape<atoms_M, atoms_N, _1>, Stride<atoms_N, _1, _0>>>::TiledMMA;

      static constexpr bool IsGroup = cute::is_same_v<KernelScheduleType, KernelPVCPtrArrayCooperative>;

      using KernelSchedule = std::conditional_t<cute::is_same_v<KernelScheduleType, KernelScheduleAuto>, KernelPVC, KernelScheduleType>;
      static constexpr int PipelineStages = IsGroup ? 2 : 3;
      using DispatchPolicy = std::conditional_t<IsGroup, 
                                                cutlass::gemm::MainloopIntelPVCGroup<PipelineStages, KernelSchedule>,
                                                cutlass::gemm::MainloopIntelPVC<PipelineStages, KernelSchedule>>;

      static constexpr auto tile_M = get<0>(TileShape_MNK{});
      static constexpr auto tile_N = get<1>(TileShape_MNK{});
      static constexpr auto tile_K = get<2>(TileShape_MNK{});
      using GmemTiledCopyA = std::conditional_t<cute::is_same_v<GmemLayoutATag, cutlass::layout::RowMajor>,
                                                std::conditional_t< tile_M/atoms_M{}>=_32{} && tile_K>=_32{}, 
                                                                    XE_2D_U16x32x32_LD_N, 
                                                                    XE_2D_U16x16x16_LD_N>,
                                                XE_2D_U16x16x16_LD_T>;
      using GmemTiledCopyB = std::conditional_t<cute::is_same_v<GmemLayoutBTag, cutlass::layout::RowMajor>,
                                                std::conditional_t< tile_N/atoms_N{}>=_32{} && tile_K>=_32{}, 
                                                                    XE_2D_U16x32x32_LD_V, 
                                                                    XE_2D_U16x16x16_LD_V>,
                                                XE_2D_U16x16x16_LD_T>;

      // PVC pipeline does not use shared memory
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
              cutlass::gemm::TagToStrideA_t<std::conditional_t<IsGroup, GmemLayoutATag*, GmemLayoutATag>>,
              ElementB,
              cutlass::gemm::TagToStrideB_t<std::conditional_t<IsGroup, GmemLayoutBTag*, GmemLayoutBTag>>,
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
