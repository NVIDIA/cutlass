/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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

// Choose an appropriate XE_DPAS_TT overload for a given
//   combination of types.
template <int M, typename TA, typename TB, typename TC>
auto
xe_dpas_tt_op_selector() {
  if constexpr (is_complete_v<XE_DPAS_TT<M, TC, TA, TB>>)
    return XE_DPAS_TT<M, TC, TA, TB>{};
  else if constexpr (is_same_v<TA, cute::bfloat16_t>)
    return XE_DPAS_TT<M, float, cute::bfloat16_t>{};
  else  /* Use f16 by default as upconversion sequences are typically faster */
    return XE_DPAS_TT<M, float, cute::half_t>{};
}


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
  arch::IntelXe,
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
  cute::enable_if_t<cute::is_any_of_v<KernelScheduleType, KernelScheduleAuto, KernelXe, KernelXeCooperative, KernelXePtrArrayCooperative>>
> {
#ifdef SYCL_NVIDIA_TARGET
  static_assert(cutlass::detail::dependent_false<arch::IntelXe>,
    "Trying to use Xe pipeline on non-Xe hardware");
#endif
  static_assert(is_static<TileShape_MNK>::value);

  using DPAS_M = decltype(cute::gcd(_8{}, get<0>(TileShape_MNK{})));
  using MMAAtom = MMA_Atom<decltype(xe_dpas_tt_op_selector<DPAS_M::value, ElementA, ElementB, ElementAccumulator>())>;

  static constexpr auto MMAAtomGrid = shape_div(TileShape_MNK{}, typename MMAAtom::Shape_MNK{});

  // Choose subgroup configuration.
  static constexpr int MaxSG = 32;
  static constexpr int SG_M0 = cute::min(get<0>(MMAAtomGrid), 8);
  static constexpr int SG_N = cute::min(get<1>(MMAAtomGrid), MaxSG / SG_M0);
  static constexpr int SG_M = cute::min(get<0>(MMAAtomGrid), MaxSG / SG_N);

  using TiledMMA =
      typename TiledMMAHelper<MMAAtom,
                              Layout<TileShape_MNK>,
                              Layout<Shape<C<SG_M>, C<SG_N>, _1>, Stride<C<SG_N>, _1, _0>>>::TiledMMA;

  using KernelSchedule = std::conditional_t<cute::is_same_v<KernelScheduleType, KernelScheduleAuto>, KernelXe, KernelScheduleType>;

  static constexpr bool IsGroup = cute::is_same_v<KernelScheduleType, KernelXePtrArrayCooperative>;
  static constexpr int PipelineStages = IsGroup ? 2 : 3;
  using DispatchPolicy = std::conditional_t<!IsGroup, cutlass::gemm::MainloopXeL1Staged<PipelineStages, KernelSchedule>,
                                                      cutlass::gemm::MainloopXeL1StagedGroup<PipelineStages, KernelSchedule>>;

  using GmemTiledCopyA = void;    // autoselect
  using GmemTiledCopyB = void;    // autoselect

  using SmemLayoutAtomA = void;   // No shared memory usage
  using SmemLayoutAtomB = void;
  using SmemCopyAtomA = void;
  using SmemCopyAtomB = void;

  using TransformA = cute::identity;
  using TransformB = cute::identity;

  using ElementA_ = ElementA;
  using ElementB_ = ElementB;


  using CollectiveOp = cutlass::gemm::collective::CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA_,
      cutlass::gemm::TagToStrideA_t<std::conditional_t<IsGroup, GmemLayoutATag*, GmemLayoutATag>>,
      ElementB_,
      cutlass::gemm::TagToStrideB_t<std::conditional_t<IsGroup, GmemLayoutBTag*, GmemLayoutBTag>>,
      TiledMMA,
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

/////////////////////////////////////////////////////////////////////////////////////////////////
// Forward Xe12/Xe20 builders to IntelXe
/////////////////////////////////////////////////////////////////////////////////////////////////

#define CUTLASS_FORWARD_XE_MMA_BUILDER(Arch)                                             \
template <class ElementA, class GmemLayoutATag, int AlignmentA,                          \
          class ElementB, class GmemLayoutBTag, int AlignmentB,                          \
          class ElementAccumulator, class TileShape_MNK, class KernelScheduleType>       \
struct CollectiveBuilder<arch::Arch, arch::OpClassTensorOp,                              \
                         ElementA, GmemLayoutATag, AlignmentA,                           \
                         ElementB, GmemLayoutBTag, AlignmentB,                           \
                         ElementAccumulator, TileShape_MNK, Shape<_1, _1, _1>,           \
                         cutlass::gemm::collective::StageCountAuto, KernelScheduleType>  \
     : CollectiveBuilder<arch::IntelXe, arch::OpClassTensorOp,                           \
                         ElementA, GmemLayoutATag, AlignmentA,                           \
                         ElementB, GmemLayoutBTag, AlignmentB,                           \
                         ElementAccumulator, TileShape_MNK, Shape<_1, _1, _1>,           \
                         cutlass::gemm::collective::StageCountAuto, KernelScheduleType> {};

CUTLASS_FORWARD_XE_MMA_BUILDER(Xe12)
CUTLASS_FORWARD_XE_MMA_BUILDER(Xe20)

#undef CUTLASS_FORWARD_XE_MMA_BUILDER

} // namespace cutlass::gemm::collective

