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

namespace detail {
  template <class FusionOp>
  struct FusionOpInfo {
    static_assert(cutlass::detail::dependent_false<FusionOp>,
      "Could not find a builder specialization.");
  };

  template <
    class ElementD,
    class ElementCompute,
    class ElementC
  >
  struct FusionOpInfo<cutlass::epilogue::fusion::LinearCombination<
    ElementD, ElementCompute, ElementC, ElementCompute
  >> {
      constexpr static bool HasBuilder = true;

      template <
        class DispatchPolicy,
        class TileShape_MNK,
        class EpilogueTile,
        class>
      using FusionCallbacks = cutlass::epilogue::fusion::FusionCallbacks<
        DispatchPolicy,
        cutlass::epilogue::fusion::LinearCombination<ElementD, ElementCompute, ElementC, ElementCompute>,
        TileShape_MNK,
        EpilogueTile
      >;
  };

  template <
    template <class> class ActivationFn,
    class ElementD,
    class ElementCompute,
    class ElementC
  >
  struct FusionOpInfo<cutlass::epilogue::fusion::LinCombEltAct<
    ActivationFn, ElementD, ElementCompute, ElementC, ElementCompute
  >> {
      constexpr static bool HasBuilder = true;
      template <
        class DispatchPolicy,
        class TileShape_MNK,
        class EpilogueTile,
        class>

      using FusionCallbacks = cutlass::epilogue::fusion::FusionCallbacks<
        DispatchPolicy,
        cutlass::epilogue::fusion::LinCombEltAct<ActivationFn, ElementD, ElementCompute, ElementC, ElementCompute>,
        TileShape_MNK,
        EpilogueTile
      >;
  };

  template <
    class GmemLayoutTagC,
    template <class> class ActivationFn,
    class ElementD,
    class ElementCompute,
    class ElementC
  >
  struct FusionOpInfo<cutlass::epilogue::fusion::LinCombDeEltAct<
    GmemLayoutTagC, ActivationFn, ElementD, ElementCompute, ElementC, ElementCompute
  >> {
      constexpr static bool HasBuilder = true;

      template <
        class DispatchPolicy,
        class TileShape_MNK,
        class EpilogueTile,
        class CopyOpG2R>
      using FusionCallbacks = cutlass::epilogue::fusion::FusionCallbacks<
        DispatchPolicy,
        cutlass::epilogue::fusion::LinCombDeEltAct<GmemLayoutTagC, ActivationFn, ElementD, ElementCompute, ElementC, ElementCompute>,
        TileShape_MNK,
        EpilogueTile,
        CopyOpG2R
      >;
  };
} // namespace detail


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
  class EpilogueScheduleType,
  class FusionOpOrCallbacks
  >
  struct CollectiveBuilder<
      arch::IntelXe,
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
      EpilogueScheduleType,
      FusionOpOrCallbacks,
      cute::enable_if_t<
        cute::is_same_v<EpilogueTileType, EpilogueTileAuto> &&
        cute::is_any_of_v<EpilogueScheduleType, EpilogueScheduleAuto, IntelXeXMX16, IntelXeXMX16Group> &&
        detail::FusionOpInfo<FusionOpOrCallbacks>::HasBuilder
      >
    >{
      #ifdef SYCL_NVIDIA_TARGET
        static_assert(cutlass::detail::dependent_false<arch::IntelXe>,
          "Trying to use Intel pipeline on Non Intel hardware");
      #endif
      static_assert(is_static<TileShape_MNK>::value);
      static_assert(cute::is_any_of_v<ElementC, float, bfloat16_t, half_t, int32_t, void>,
        "ElementC needs to be one of: float, bfloat, half, int32, or void for the Intel pipeline");
      
      using EpilogueSchedule = std::conditional_t<cute::is_same_v<EpilogueScheduleType, EpilogueScheduleAuto>, 
                                                  IntelXeXMX16,
                                                  EpilogueScheduleType>;
      static constexpr bool IsGroup = cute::is_same_v<EpilogueSchedule, IntelXeXMX16Group>;
      using DispatchPolicy = std::conditional_t<IsGroup,
                                                IntelXeXMX16Group,
                                                IntelXeXMX16>;

      using StrideC = std::conditional_t<cute::is_tuple_v<std::remove_pointer_t<GmemLayoutTagC>>, GmemLayoutTagC, cutlass::detail::TagToStrideC_t<std::conditional_t<IsGroup, GmemLayoutTagC*, GmemLayoutTagC>>>;
      using StrideD = std::conditional_t<cute::is_tuple_v<std::remove_pointer_t<GmemLayoutTagD>>, GmemLayoutTagD, cutlass::detail::TagToStrideC_t<std::conditional_t<IsGroup, GmemLayoutTagD*, GmemLayoutTagD>>>;

      static_assert(IsGroup == std::is_pointer_v<StrideC>, "Group GEMM should have a pointer to strides");
      static_assert(IsGroup == std::is_pointer_v<StrideD>, "Group GEMM should have a pointer to strides");
      static_assert(get<1>(std::remove_pointer_t<StrideC>{}) == 1, "Only N-Major/Row-Major layouts for C are supported in the xe epilogue collective builder");
      static_assert(get<1>(std::remove_pointer_t<StrideD>{}) == 1, "Only N-Major/Row-Major layouts for D are supported in the xe epilogue collective builder");

      using CopyOpG2R = std::conditional_t<is_void_v<ElementC>, void, std::conditional_t<cutlass::sizeof_bits_v<ElementC> == 32, XE_2D_U32x8x16_LD_N, XE_2D_U16x8x16_LD_N>>;
      using CopyOpR2G = std::conditional_t<cutlass::sizeof_bits_v<ElementD> == 32, XE_2D_U32x8x16_ST_N, XE_2D_U16x8x16_ST_N>;

      // Intel Epilogue with Linear Combination does not use shared memory
      using SmemLayoutAtomC_ = void;
      using CopyOpS2R_ = void;
      using SmemLayoutAtomD_ = void;
      using CopyOpR2S_ = void;

      //TODO(Codeplay): Should FusionCallbacks use DispatchPolicy IntelXeGroupEpilogue for group gemm? That does not work.
      using FusionCallbacks = typename detail::FusionOpInfo<FusionOpOrCallbacks>::template FusionCallbacks<
                                  IntelXeXMX16, TileShape_MNK, TileShape_MNK, CopyOpG2R>;

      using CollectiveOp = cutlass::epilogue::collective::CollectiveEpilogue<
            DispatchPolicy,
            TileShape_MNK,
            ElementC,
            StrideC,
            ElementD,
            StrideD,
            FusionCallbacks,
            CopyOpG2R,
            SmemLayoutAtomC_,
            CopyOpS2R_,
            CopyOpR2G,
            SmemLayoutAtomD_,
            CopyOpR2S_
        >;
    };

/////////////////////////////////////////////////////////////////////////////////////////////////
// Xe12 (PVC) Epilogue CollectiveBuilder - forwards to IntelXe
/////////////////////////////////////////////////////////////////////////////////////////////////

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
  class EpilogueScheduleType,
  class FusionOpOrCallbacks
  >
struct CollectiveBuilder<
  arch::Xe12,
  arch::OpClassTensorOp,
  TileShape_MNK,
  Shape<_1, _1, _1>,
  EpilogueTileType,
  ElementAccumulator,
  ElementCompute,
  ElementC,
  GmemLayoutTagC,
  AlignmentC,
  ElementD,
  GmemLayoutTagD,
  AlignmentD,
  EpilogueScheduleType,
  FusionOpOrCallbacks
  > : CollectiveBuilder<
      arch::IntelXe,  // Forward to IntelXe
      arch::OpClassTensorOp,
      TileShape_MNK,
      Shape<_1, _1, _1>,
      EpilogueTileType,
      ElementAccumulator,
      ElementCompute,
      ElementC,
      GmemLayoutTagC,
      AlignmentC,
      ElementD,
      GmemLayoutTagD,
      AlignmentD,
      EpilogueScheduleType,
      FusionOpOrCallbacks
  > {};

/////////////////////////////////////////////////////////////////////////////////////////////////
// Xe20 (BMG) Epilogue CollectiveBuilder - forwards to IntelXe
/////////////////////////////////////////////////////////////////////////////////////////////////

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
  class EpilogueScheduleType,
  class FusionOpOrCallbacks
  >
struct CollectiveBuilder<
  arch::Xe20,
  arch::OpClassTensorOp,
  TileShape_MNK,
  Shape<_1, _1, _1>,
  EpilogueTileType,
  ElementAccumulator,
  ElementCompute,
  ElementC,
  GmemLayoutTagC,
  AlignmentC,
  ElementD,
  GmemLayoutTagD,
  AlignmentD,
  EpilogueScheduleType,
  FusionOpOrCallbacks
  > : CollectiveBuilder<
      arch::IntelXe,  // Forward to IntelXe
      arch::OpClassTensorOp,
      TileShape_MNK,
      Shape<_1, _1, _1>,
      EpilogueTileType,
      ElementAccumulator,
      ElementCompute,
      ElementC,
      GmemLayoutTagC,
      AlignmentC,
      ElementD,
      GmemLayoutTagD,
      AlignmentD,
      EpilogueScheduleType,
      FusionOpOrCallbacks
  > {};

} // namespace cutlass::epilogue::collective

