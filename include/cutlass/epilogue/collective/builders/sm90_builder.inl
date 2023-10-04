/***************************************************************************************************
 * Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cute/atom/mma_traits_sm90.hpp"
#include "cute/atom/mma_traits_sm90_gmma.hpp"
#include "cute/atom/copy_traits_sm90.hpp"

#include "cutlass/detail/dependent_false.hpp"
#include "cutlass/detail/layout.hpp"
#include "cutlass/gemm/collective/builders/sm90_common.inl"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/epilogue/thread/linear_combination_generic.h"
#include "cutlass/epilogue/thread/linear_combination_bias_elementwise.h"
#include "cutlass/epilogue/fusion/callbacks.hpp"
#include "cutlass/epilogue/fusion/sm90_callbacks_tma_warpspecialized.hpp"

#if defined(__CUDACC_RTC__)
#include <cuda/std/type_traits>
#else
#include <type_traits>
#endif

///////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::collective {

///////////////////////////////////////////////////////////////////////////////

namespace detail {

// Returns the parameterized dispatch policy for the TMA epilogue
template<class TileShapeMNK, class EpilogueTileMN, class ElementC, class ElementD, class Schedule>
constexpr auto
sm90_get_tma_dispatch_policy() {
  using namespace cute;

  constexpr int EpiTiles = size(shape_div(take<0,2>(TileShapeMNK{}), EpilogueTileMN{}));
  constexpr int FragmentSize = size(EpilogueTileMN{}) / (detail::sm90_is_cooperative_v<Schedule> ? 256 : 128);
  constexpr int ReuseSmemC = (sizeof_bits_v<ElementC> == sizeof_bits_v<ElementD>) && (sizeof_bits_v<ElementD> > 8);
  constexpr int StagesD = 2;
  constexpr int StagesC = ReuseSmemC ? cute::max(EpiTiles, StagesD + 1) : EpiTiles;

  return Sm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC>{};
}

// Returns the smem layout atom to be used for C or D matrix
template<class GmemStrideType, class Element, class EpilogueTile_MN>
constexpr auto
sm90_get_epilogue_smem_swizzle_layout_atom() {
  using namespace cute;

  // ColMajor C/D (M-major)
  if constexpr (cutlass::gemm::detail::is_major<0>(GmemStrideType{})) {
    return cutlass::gemm::collective::detail::ss_smem_selector<
      cute::GMMA::Major::MN, Element, decltype(get<0>(EpilogueTile_MN{})), decltype(get<1>(EpilogueTile_MN{}))
    >();
  }
  // RowMajor C/D (N-major)
  else if constexpr (cutlass::gemm::detail::is_major<1>(GmemStrideType{})) {
    return cutlass::gemm::collective::detail::ss_smem_selector<
      cute::GMMA::Major::K , Element, decltype(get<0>(EpilogueTile_MN{})), decltype(get<1>(EpilogueTile_MN{}))
    >();
  }
  else {
    static_assert(cutlass::detail::dependent_false<GmemStrideType>, "Unsupported gmem layout.");
  }
}

// Attempts to compute a reasonable epilogue tile based on block tile shape or allows the user to provide one.
template <class ElementD, class EpilogueTileType, class Schedule>
constexpr auto
sm90_compute_tile_shape_or_override() {
  if constexpr (cute::is_same_v<EpilogueTileType, EpilogueTileAuto>) {

    if constexpr (detail::sm90_is_cooperative_v<Schedule>) {
      return Shape<_128,_32>{};
    }
    else if constexpr (detail::sm90_is_warp_specialized_v<Schedule>) {
      if constexpr (sizeof_bits_v<ElementD> == 8) {
        return Shape<_64,_64>{};
      }
      else {
        return Shape<_64,_32>{};
      }
    }
    else {
      static_assert(cutlass::detail::dependent_false<Schedule>, "Unsupported schedule.");
    }
  }
  else if constexpr (cute::is_tuple<EpilogueTileType>::value) {
    EpilogueTileType epi_tile;
    constexpr int M = size<0>(shape(epi_tile));
    constexpr int N = size<1>(shape(epi_tile));

    static_assert(!is_layout<EpilogueTileType>::value, "EpilogueTile must be a cute::Tile or cute::Shape");
    static_assert(M ==  64 && detail::sm90_is_warp_specialized_v<Schedule> ||
                  M == 128 && detail::sm90_is_cooperative_v<Schedule>, "Unsupported tile shape");
    static_assert(N % 16 == 0, "Unsupported tile shape");

    return epi_tile;
  }
  else {
    static_assert(cutlass::detail::dependent_false<EpilogueTileType>, "Invalid type for EpilogueTileType.");
  }
}

// Selects the largest vectorized smem store atom available
template <class GmemStrideTypeD, class ElementD>
constexpr auto
sm90_get_smem_store_op_for_accumulator() {
  using namespace cute;

  if constexpr (sizeof(ElementD) == 2 && size<0>(GmemStrideTypeD{}) == 1) {
    return SM90_U16x8_STSM_T{};
  }
  else if constexpr (sizeof(ElementD) == 2 && size<1>(GmemStrideTypeD{}) == 1) {
    return SM90_U32x4_STSM_N{};
  }
  else {
    // auto-vectorizing store
    return DefaultCopy{};
  }
}

// Selects the largest vectorized smem load atom available
template <class GmemStrideTypeC, class ElementC>
constexpr auto
sm90_get_smem_load_op_for_source() {
  using namespace cute;

  // Reuse the logic from smem store selector
  using SmemStoreOp = decltype(sm90_get_smem_store_op_for_accumulator<GmemStrideTypeC, ElementC>());

  if constexpr (cute::is_same_v<SmemStoreOp, SM90_U16x8_STSM_T>) {
    return SM75_U16x8_LDSM_T{};
  }
  else if constexpr (cute::is_same_v<SmemStoreOp, SM90_U32x4_STSM_N>) {
    return SM75_U32x4_LDSM_N{};
  }
  else {
    // auto-vectorizing load
    return DefaultCopy{};
  }
}

// callbacks builder with TMA aux out
template <
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  class FusionOp,
  class TileShape_MNK,
  class EpilogueTile_MN,
  class ElementAccumulator
>
struct CallbacksBuilder<
  Sm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC>,
  FusionOp,
  TileShape_MNK,
  EpilogueTile_MN,
  ElementAccumulator,
  enable_if_t<FusionOp::IsAuxOutSupported>
> {
  using GmemStrideTypeAux = gemm::TagToStrideC_t<typename FusionOp::GmemLayoutTagAux>;
  using SmemLayoutAtomAux = decltype(detail::sm90_get_epilogue_smem_swizzle_layout_atom<
    GmemStrideTypeAux, typename FusionOp::ElementAux, EpilogueTile_MN>());
  using SmemCopyOpAux = decltype(detail::sm90_get_smem_store_op_for_accumulator<
    GmemStrideTypeAux, typename FusionOp::ElementAux>());

  using Callbacks = fusion::FusionCallbacks<
    Sm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC>,
    FusionOp, TileShape_MNK, EpilogueTile_MN,
    SmemLayoutAtomAux, SmemCopyOpAux
  >;
};

// Helper for building TMA warp-specialized collective epilogues, specialized by
// the fusion operation performed and the dispatch policy to use.
template <
  class TileShape_MNK,
  class EpilogueTile_MN,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC_,
  class GmemLayoutTagC_,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class FusionOpOrCallbacks,
  class DispatchPolicy
>
struct Sm90TmaBuilderImpl {
  // Passing void C disables source load + smem allocation
  using ElementC = cute::conditional_t<cute::is_void_v<ElementC_>,ElementD,ElementC_>; // prevents void ref breakages
  using GmemLayoutTagC = cute::conditional_t<cute::is_void_v<ElementC_>,GmemLayoutTagD,GmemLayoutTagC_>;

  using GmemStrideTypeC = cutlass::detail::TagToStrideC_t<GmemLayoutTagC>;
  using GmemStrideTypeD = cutlass::detail::TagToStrideC_t<GmemLayoutTagD>;

  // TMA builder allows for passing callbacks directly, which is either a fusion::FusionCallbacks
  // instance or a direct visitor implementation, e.g. fusion::Sm90LinearCombination
  using FusionCallbacks = 
    typename CallbacksBuilder<
      DispatchPolicy,
      FusionOpOrCallbacks,
      TileShape_MNK,
      EpilogueTile_MN,
      ElementAccumulator
    >::Callbacks;

  using CollectiveOp = cutlass::epilogue::collective::CollectiveEpilogue<
      DispatchPolicy,
      TileShape_MNK,
      EpilogueTile_MN,
      ElementC_, // Need to pass void through to expose via GemmUniversal
      GmemStrideTypeC,
      ElementD,
      GmemStrideTypeD,
      FusionCallbacks,
      SM90_TMA_LOAD,
      decltype(detail::sm90_get_epilogue_smem_swizzle_layout_atom<GmemStrideTypeC, ElementC, EpilogueTile_MN>()),
      decltype(detail::sm90_get_smem_load_op_for_source<GmemStrideTypeC, ElementC>()),
      SM90_TMA_STORE,
      decltype(detail::sm90_get_epilogue_smem_swizzle_layout_atom<GmemStrideTypeD, ElementD, EpilogueTile_MN>()),
      decltype(detail::sm90_get_smem_store_op_for_accumulator<GmemStrideTypeD, ElementD>())
    >;
};

///////////////////////////////////////////////////////////////////////////////
// Descriptor classes for defining EVT nodes
// Some of the epilogue visitor nodes require non-intuitive template arguments
// such as CopyOpS2R for AuxLoad node. Traditionaly, these are resolved by the
// builder classes. Here we provide a set of descriptor classes that resolve
// these template arguments from more intuitive types such as Stride, Layout

// Get TileShape, EpilogueTile, Dispatch Policy, StagesC, and STagesD
template<
  typename TileShape_MNK,
  typename EpilogueTileType, 
  typename ElementC,
  typename ElementD,
  typename Schedule
>
struct EpilogueDescriptor {
  using TileShape = TileShape_MNK;
  using EpilogueTile = 
    decltype(
      detail::sm90_compute_tile_shape_or_override<
        ElementD, EpilogueTileType, Schedule
      >()
    );
  using DispatchPolicy = 
    decltype(
      detail::sm90_get_tma_dispatch_policy<
        TileShape_MNK, EpilogueTile, 
        ElementC, ElementD, Schedule
      >()
    );
  constexpr static int StagesC = DispatchPolicy::StagesC;
  constexpr static int StagesD = DispatchPolicy::StagesD;
};

// Get Stride, SmemLayout, and CopyOpS2R for AuxLoad node
template<
  typename EpilogueDescriptor,
  typename StrideOrLayoutTag,
  typename ElementAux
>
struct AuxLoadDescriptor {
  constexpr static int Stages = EpilogueDescriptor::StagesC;
  using EpilogueTile = typename EpilogueDescriptor::EpilogueTile;
  using Element = ElementAux;
  using Stride = cutlass::detail::TagToStrideC_t<StrideOrLayoutTag>;
  using SmemLayoutAtom =
    decltype(
      detail::sm90_get_epilogue_smem_swizzle_layout_atom<
        Stride, ElementAux, typename EpilogueDescriptor::EpilogueTile
      >()
    );
  using CopyOpS2R =
    decltype(detail::sm90_get_smem_load_op_for_source<Stride, ElementAux>());
};

// Get Stride, SmemLayout, and CopyOpS2R for AuxStore node
template<
  typename EpilogueDescriptor,
  typename StrideOrLayoutTag,
  typename ElementAux
>
struct AuxStoreDescriptor {
  constexpr static int Stages = EpilogueDescriptor::StagesD;
  using EpilogueTile = typename EpilogueDescriptor::EpilogueTile;
  using Element = ElementAux;
  using Stride = cutlass::detail::TagToStrideC_t<StrideOrLayoutTag>;
  using SmemLayoutAtom =
    decltype(
      detail::sm90_get_epilogue_smem_swizzle_layout_atom<
        Stride, ElementAux, typename EpilogueDescriptor::EpilogueTile
      >()
    );
  using CopyOpR2S =
    decltype(detail::sm90_get_smem_store_op_for_accumulator<Stride, ElementAux>());
};

template<
  typename EpilogueDescriptor,
  typename ElementVector
>
struct RowBroadcastDescriptor {
  constexpr static int Stages = ceil_div(
    EpilogueDescriptor::StagesC, 
    size(shape_div(take<0, 2>(typename EpilogueDescriptor::TileShape{}), typename EpilogueDescriptor::EpilogueTile{}))
  ) + 1;

  using Element = ElementVector;
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////

// No-smem builder
template <
  class TileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC_,
  class GmemLayoutTagC_,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  FloatRoundStyle RoundStyle
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    TileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC_,
    GmemLayoutTagC_,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    NoSmemWarpSpecialized,
    fusion::LinearCombination<ElementD,ElementCompute,ElementCompute,RoundStyle>,
    void> {

  // Passing void C disables source load
  using ElementC = cute::conditional_t<cute::is_void_v<ElementC_>,
      ElementD, ElementC_>; // prevents cute breakages
  using GmemLayoutTagC = cute::conditional_t<cute::is_void_v<ElementC_>,
      GmemLayoutTagD, GmemLayoutTagC_>;
  static constexpr thread::ScaleType::Kind ScaleType = cute::is_void_v<ElementC_> ?
      thread::ScaleType::OnlyAlphaScaling : thread::ScaleType::Default;

  static constexpr int FragmentSize = 1;
  using ThreadOp = thread::LinearCombination<
    ElementD, FragmentSize, ElementAccumulator, ElementCompute,
    ScaleType, RoundStyle, ElementC>;

  using CollectiveOp = cutlass::epilogue::collective::detail::Sm90TmaWarpSpecializedAdapter<
    cutlass::epilogue::collective::DefaultEpilogue<
      cutlass::detail::TagToStrideC_t<GmemLayoutTagC>,
      cutlass::detail::TagToStrideC_t<GmemLayoutTagD>,
      ThreadOp,
      cutlass::gemm::EpilogueDefault>
    >;
};

// Tma warp-specialized builder
template <
  class TileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC,
  class GmemLayoutTagC,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class Schedule,
  class FusionOperation
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    TileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC,
    GmemLayoutTagC,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    Schedule,
    FusionOperation,
    cute::enable_if_t<cute::is_same_v<Schedule, TmaWarpSpecialized> ||
                      cute::is_same_v<Schedule, TmaWarpSpecializedCooperative> >> {
private:
  using EpilogueTile_MN =
    decltype(detail::sm90_compute_tile_shape_or_override<ElementD, EpilogueTileType, Schedule>());
  using DispatchPolicy =
    decltype(detail::sm90_get_tma_dispatch_policy<TileShape_MNK,EpilogueTile_MN,ElementC,ElementD,Schedule>());

public:
  using CollectiveOp =
    typename detail::Sm90TmaBuilderImpl<
      TileShape_MNK,
      EpilogueTile_MN,
      ElementAccumulator,
      ElementCompute,
      ElementC,
      GmemLayoutTagC,
      AlignmentC,
      ElementD,
      GmemLayoutTagD,
      AlignmentD,
      FusionOperation,
      DispatchPolicy
    >::CollectiveOp;
};

// Auto builder
template <
  class TileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC,
  class GmemLayoutTagC,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class FusionOperation
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    TileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC,
    GmemLayoutTagC,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    EpilogueScheduleAuto,
    FusionOperation,
    void> {
private:
  // Pick No-Smem epilogue as the Auto Epilogue Schedule (Auto schedules do not guarantee best performance) 
  // since TMA epilogues are not compatible with non-TMA non-WS mainloops
  using EpilogueSchedule = NoSmemWarpSpecialized;
  using _CollectiveBuilder = CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    TileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC,
    GmemLayoutTagC,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    EpilogueSchedule,
    FusionOperation
  >;

public:
  using CollectiveOp = typename _CollectiveBuilder::CollectiveOp;
};

// DEPRECATED Tma warp-specialized builder for elementwise fusion
template <
  class TileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC,
  class GmemLayoutTagC,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class Schedule,
  class UnusedFusionOp
>
struct [[deprecated("Use TmaWarpSpecialized with fusion::LinCombEltAct instead")]]
CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    TileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC,
    GmemLayoutTagC,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    Schedule,
    UnusedFusionOp,
    cute::enable_if_t<cute::is_base_of_v<TmaWarpSpecializedElementwiseBase, Schedule> ||
                      cute::is_base_of_v<TmaWarpSpecializedCooperativeElementwiseBase, Schedule> >> {
private:
  using FusionOp =
    fusion::LinCombEltAct<Schedule::ActivationFunctor, ElementD, ElementCompute, ElementCompute, Schedule::Round>;
  using ImplSchedule =
    cute::conditional_t<cute::is_base_of_v<TmaWarpSpecializedElementwiseBase, Schedule>,
      TmaWarpSpecialized, TmaWarpSpecializedCooperative>;

public:
  using CollectiveOp =
    typename CollectiveBuilder<
      arch::Sm90,
      arch::OpClassTensorOp,
      TileShape_MNK,
      ClusterShape_MNK,
      EpilogueTileType,
      ElementAccumulator,
      ElementCompute,
      ElementC,
      GmemLayoutTagC,
      AlignmentC,
      ElementD,
      GmemLayoutTagD,
      AlignmentD,
      ImplSchedule,
      FusionOp
    >::CollectiveOp;
};

// DEPRECATED Tma warp-specialized builder for bias + elementwise fusion
template <
  class TileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC_,
  class GmemLayoutTagC_,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class Schedule,
  class UnusedFusionOp
>
struct [[deprecated("Use TmaWarpSpecialized with fusion::LinCombPerRowBiasEltAct or fusion::LinCombPerRowBiasEltActAux instead")]]
CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    TileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC_,
    GmemLayoutTagC_,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    Schedule,
    UnusedFusionOp,
    cute::enable_if_t<cute::is_base_of_v<TmaWarpSpecializedBiasElementwiseBase, Schedule> ||
                      cute::is_base_of_v<TmaWarpSpecializedCooperativeBiasElementwiseBase, Schedule> >> {
private:
  using EpilogueTile_MN = decltype(detail::sm90_compute_tile_shape_or_override<
    ElementD, EpilogueTileType, Schedule>());
  // MSVC doesn't seem to be able to deduce DispatchPolicy correctly if it's
  // defined as decltype of a detail::sm90_get_tma_dispatch_policy call.
  // Instead, we paste in the contents of that function.  A natural refactoring
  // would be to create a type alias in the detail namespace.
  using DispatchPolicy = Sm90TmaWarpSpecialized<
    /* StagesC = */ size(shape_div(take<0, 2>(TileShape_MNK{}), EpilogueTile_MN{})),
    /* StagesD = */ 2,
    /* FragmentSize = */ size(EpilogueTile_MN{}) / (detail::sm90_is_cooperative_v<Schedule> ? 256 : 128),
    /* ReuseSmemC = */ sizeof_bits_v<ElementC_> == sizeof_bits_v<ElementD>
  >;

  using GmemStrideTypeAux = gemm::TagToStrideC_t<GmemLayoutTagD>;
  using SmemLayoutAtomAux = decltype(detail::sm90_get_epilogue_smem_swizzle_layout_atom<
    GmemStrideTypeAux, typename Schedule::ElementT, EpilogueTile_MN>());
  using SmemCopyOpAux = decltype(detail::sm90_get_smem_store_op_for_accumulator<
    GmemStrideTypeAux, typename Schedule::ElementT>());
  using FusionOperationAux = fusion::LinCombPerRowBiasEltActAux<
    GmemLayoutTagD, Schedule::ActivationFunctor, ElementD, ElementCompute,
    typename Schedule::ElementT, typename Schedule::ElementBias, ElementCompute
  >;
  using FusionCallbacksAux = fusion::FusionCallbacks<
    DispatchPolicy, FusionOperationAux, TileShape_MNK, EpilogueTile_MN, SmemLayoutAtomAux, SmemCopyOpAux
  >;

  using FusionOperationNoAux = fusion::LinCombPerRowBiasEltAct<
    Schedule::ActivationFunctor, ElementD, ElementCompute,
    typename Schedule::ElementBias, ElementCompute
  >;
  using FusionCallbacksNoAux = fusion::FusionCallbacks<
    DispatchPolicy, FusionOperationNoAux, TileShape_MNK, EpilogueTile_MN
  >;

  using ElementC = cute::conditional_t<cute::is_void_v<ElementC_>,ElementD,ElementC_>; // prevents void ref breakages
  using GmemLayoutTagC = cute::conditional_t<cute::is_void_v<ElementC_>,GmemLayoutTagD,GmemLayoutTagC_>;

  using GmemStrideTypeC = gemm::TagToStrideC_t<GmemLayoutTagC>;
  using GmemStrideTypeD = gemm::TagToStrideC_t<GmemLayoutTagD>;

public:
  using CollectiveOp = cutlass::epilogue::collective::Sm90EpilogueTmaWarpSpecializedBiasElementwise<
      DispatchPolicy::StagesC,
      DispatchPolicy::StagesD,
      DispatchPolicy::FragmentSize,
      TileShape_MNK,
      EpilogueTile_MN,
      ElementC_, // Need to pass void through to expose via GemmUniversal
      GmemStrideTypeC,
      ElementD,
      GmemStrideTypeD,
      cute::conditional_t<Schedule::StoreT, FusionCallbacksAux, FusionCallbacksNoAux>,
      SM90_TMA_LOAD,
      decltype(detail::sm90_get_epilogue_smem_swizzle_layout_atom<GmemStrideTypeC, ElementC, EpilogueTile_MN>()),
      decltype(detail::sm90_get_smem_load_op_for_source<GmemStrideTypeC, ElementC>()),
      SM90_TMA_STORE,
      decltype(detail::sm90_get_epilogue_smem_swizzle_layout_atom<GmemStrideTypeD, ElementD, EpilogueTile_MN>()),
      decltype(detail::sm90_get_smem_store_op_for_accumulator<GmemStrideTypeD, ElementD>())
    >;
};

// CollectiveBuilder that transposed epilogue below is used for sm90 gmma RS TT kernels
// since swapping NNN kernels input matrix and transposing its output at the same time then
// we can get TTN kernel.
template <
  class TileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC_,
  class GmemLayoutTagC_,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  FloatRoundStyle RoundStyle
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    TileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC_,
    GmemLayoutTagC_,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    cutlass::gemm::EpilogueTransposed,
    fusion::LinearCombination<ElementD,ElementCompute,ElementCompute,RoundStyle>,
    void> {
  // Passing void C disables source load
  using ElementC = cute::conditional_t<cute::is_void_v<ElementC_>,
      ElementD, ElementC_>; // prevents cute breakages
  using GmemLayoutTagC = cute::conditional_t<cute::is_void_v<ElementC_>,
      GmemLayoutTagD, GmemLayoutTagC_>;
  static constexpr thread::ScaleType::Kind ScaleType = cute::is_void_v<ElementC_> ?
      thread::ScaleType::OnlyAlphaScaling : thread::ScaleType::Default;

  static constexpr int FragmentSize = 1;
  using ThreadOp = thread::LinearCombination<
    ElementD, FragmentSize, ElementAccumulator, ElementCompute,
    ScaleType, RoundStyle, ElementC>;

  using CollectiveOp = cutlass::epilogue::collective::detail::Sm90TmaWarpSpecializedAdapter<
    cutlass::epilogue::collective::DefaultEpilogue<
      cutlass::detail::TagToStrideC_t<GmemLayoutTagC>,
      cutlass::detail::TagToStrideC_t<GmemLayoutTagD>,
      ThreadOp,
      cutlass::gemm::EpilogueTransposed>
    >;
};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::epilogue::collective
