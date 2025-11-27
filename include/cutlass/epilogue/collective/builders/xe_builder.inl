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
#include "cutlass/epilogue/collective/default_epilogue.hpp"
#include "cutlass/epilogue/collective/xe_epilogue.hpp"
#include "cutlass/epilogue/fusion/xe_callbacks.hpp"


namespace cutlass::epilogue::collective {

// Xe epilogue builder
template <
  class TileShape_MNK,
  class EpilogueTile_MN,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC,
  class GmemLayoutTagC,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class EpilogueScheduleType,
  class FusionOpOrCallbacks
  >
struct CollectiveBuilder<
    arch::IntelXe,
    arch::OpClassTensorOp,
    TileShape_MNK,
    Shape<_1, _1, _1>,    // Cluster Shape
    EpilogueTile_MN,
    ElementAccumulator,
    ElementCompute,
    ElementC,
    GmemLayoutTagC,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    EpilogueScheduleType,
    FusionOpOrCallbacks,
    cute::enable_if_t<
      cute::is_same_v<EpilogueTile_MN, EpilogueTileAuto> &&
      cute::is_any_of_v<EpilogueScheduleType, EpilogueScheduleAuto, IntelXeGeneric, IntelXeGenericGroup>
    >
> {
#ifdef SYCL_NVIDIA_TARGET
  static_assert(cutlass::detail::dependent_false<arch::IntelXe>,
    "Trying to use Intel pipeline on Non Intel hardware");
#endif
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(cute::is_any_of_v<ElementC, float, bfloat16_t, half_t, int32_t, void>,
    "ElementC needs to be one of: float, bfloat, half, int32, or void for the Intel pipeline");

  using EpilogueSchedule = std::conditional_t<cute::is_same_v<EpilogueScheduleType, EpilogueScheduleAuto>,
                                              IntelXeGeneric,
                                              EpilogueScheduleType>;
  static constexpr bool IsGroup = cute::is_same_v<EpilogueSchedule, IntelXeGenericGroup>;
  using DispatchPolicy = std::conditional_t<IsGroup,
                                            IntelXeGenericGroup,
                                            IntelXeGeneric>;

  using StrideC = std::conditional_t<cute::is_tuple_v<std::remove_pointer_t<GmemLayoutTagC>>,
                                     GmemLayoutTagC,
                                     cutlass::detail::TagToStrideC_t<std::conditional_t<IsGroup, GmemLayoutTagC*, GmemLayoutTagC>>>;
  using StrideD = std::conditional_t<cute::is_tuple_v<std::remove_pointer_t<GmemLayoutTagD>>,
                                     GmemLayoutTagD,
                                     cutlass::detail::TagToStrideC_t<std::conditional_t<IsGroup, GmemLayoutTagD*, GmemLayoutTagD>>>;

  static_assert(IsGroup == std::is_pointer_v<StrideC>, "Group GEMM should have a pointer to strides");
  static_assert(IsGroup == std::is_pointer_v<StrideD>, "Group GEMM should have a pointer to strides");
  static_assert(get<1>(std::remove_pointer_t<StrideC>{}) == 1, "Only N-major/row-major layouts for C are supported in the Xe epilogue collective builder");
  static_assert(get<1>(std::remove_pointer_t<StrideD>{}) == 1, "Only N-major/row-major layouts for D are supported in the Xe epilogue collective builder");

  // Use default copy operations.
  using CopyOpG2R = void;
  using CopyOpR2G = void;

  using FusionCallbacks =
    typename detail::CallbacksBuilder<
      DispatchPolicy,
      FusionOpOrCallbacks,
      TileShape_MNK,
      EpilogueTile_MN,
      ElementAccumulator
    >::Callbacks;

  using CollectiveOp = cutlass::epilogue::collective::CollectiveEpilogue<
      DispatchPolicy,
      TileShape_MNK,      // xxx
      EpilogueTile_MN,
      ElementC,
      StrideC,
      ElementD,
      StrideD,
      FusionCallbacks,
      CopyOpG2R,
      CopyOpR2G
  >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////
// Forward Xe12/Xe20 builders to IntelXe
/////////////////////////////////////////////////////////////////////////////////////////////////

#define CUTLASS_FORWARD_XE_EPI_BUILDER(Arch)                                \
template <class TileShape_MNK, class EpilogueTile_MN,                       \
          class ElementAccumulator, class ElementCompute,                   \
          class ElementC, class GmemLayoutTagC, int AlignmentC,             \
          class ElementD, class GmemLayoutTagD, int AlignmentD,             \
          class EpilogueScheduleType, class FusionOpOrCallbacks>            \
struct CollectiveBuilder<arch::Arch, arch::OpClassTensorOp,                 \
                         TileShape_MNK, Shape<_1, _1, _1>, EpilogueTile_MN, \
                         ElementAccumulator, ElementCompute,                \
                         ElementC, GmemLayoutTagC, AlignmentC,              \
                         ElementD, GmemLayoutTagD, AlignmentD,              \
                         EpilogueScheduleType, FusionOpOrCallbacks>         \
     : CollectiveBuilder<arch::IntelXe, arch::OpClassTensorOp,              \
                         TileShape_MNK, Shape<_1, _1, _1>, EpilogueTile_MN, \
                         ElementAccumulator, ElementCompute,                \
                         ElementC, GmemLayoutTagC, AlignmentC,              \
                         ElementD, GmemLayoutTagD, AlignmentD,              \
                         EpilogueScheduleType, FusionOpOrCallbacks> {};

CUTLASS_FORWARD_XE_EPI_BUILDER(Xe12)
CUTLASS_FORWARD_XE_EPI_BUILDER(Xe20)

#undef CUTLASS_FORWARD_XE_EPI_BUILDER

} // namespace cutlass::epilogue::collective

