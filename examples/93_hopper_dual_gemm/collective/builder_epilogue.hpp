/***************************************************************************************************
 * Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "cutlass/epilogue/collective/collective_builder.hpp"
#include "cutlass/gemm/collective/builders/sm90_common.inl"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_epilogue.hpp"
#include "cutlass/epilogue/collective/builders/sm90_common.inl"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/epilogue/thread/linear_combination_generic.h"
#include "cutlass/epilogue/thread/linear_combination_bias_elementwise.h"
#include "cutlass/epilogue/fusion/callbacks.hpp"
#include "cutlass/epilogue/fusion/sm90_callbacks_tma_warpspecialized.hpp"

#include "dispatch_policy_extra.hpp"
#include "sm90_epilogue_tma_warpspecialized_dual.hpp"
#include "../fusion/callbacks.hpp"
#include "../fusion/sm90_callbacks_tma_warpspecialized_dual.hpp"

#if defined(__CUDACC_RTC__)
#include <cuda/std/type_traits>
#else
#include <type_traits>
#endif

///////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::collective {

///////////////////////////////////////////////////////////////////////////////

namespace detail {

template <class EpilogueSchedule>
static constexpr bool dual_sm90_is_cooperative_v =
  cute::is_base_of_v<cutlass::epilogue::DualTmaWarpSpecializedCooperative, EpilogueSchedule> ||
  sm90_is_ptr_array_tma_cooperative_v<EpilogueSchedule>;

// Returns the parameterized dispatch policy for the TMA epilogue
template<class TileShapeMNK, class EpilogueTileMN, class ElementC, class ElementD, class Schedule>
constexpr auto
dual_sm90_get_tma_dispatch_policy() {
  using namespace cute;

  constexpr int EpiTiles = size(shape_div(take<0,2>(TileShapeMNK{}), EpilogueTileMN{}));
  constexpr int FragmentSize = size(EpilogueTileMN{}) / (detail::dual_sm90_is_cooperative_v<Schedule> ? 256 : 128);
  // 8b residuals load fast and consume little smem, so the perf cost of waiting on stores to finish outweighs the cost of extra allocation
  constexpr bool ReuseSmem = (sizeof_bits_v<ElementC> == sizeof_bits_v<ElementD>) && (sizeof_bits_v<ElementD> > 8);
  // TMA store delay performs worse with residual loads and compilicates tensormap updates for Ptr-Array GEMMs
  constexpr bool DelayTmaStore = is_void_v<ElementC> && !detail::sm90_is_ptr_array_tma_v<Schedule>;
  constexpr int StagesD = cute::min(EpiTiles, 2);
  constexpr int StagesC = ReuseSmem ? cute::max(cute::min(EpiTiles, 4), StagesD+1)
                                    : cute::min(EpiTiles, 4);

  if constexpr (detail::sm90_is_ptr_array_tma_v<Schedule>) {
      return Sm90PtrArrayTmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmem, 
                                            DelayTmaStore, Schedule::NumEpilogueWarpGroups>{};
  } 
  else {
    return DualSm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmem, DelayTmaStore>{};
  }
}

// Returns the smem layout atom to be used for C or D matrix
template<class GmemStrideType, class Element, class EpilogueTile_MN>
constexpr auto
dual_sm90_get_epilogue_smem_swizzle_layout_atom() {
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

template <class EpilogueSchedule>
static constexpr bool dual_sm90_is_warp_specialized_v =
  (!sm90_is_ptr_array_tma_cooperative_v<EpilogueSchedule> && sm90_is_ptr_array_tma_v<EpilogueSchedule>) ||
  cute::is_base_of_v<cutlass::epilogue::DualTmaWarpSpecialized, EpilogueSchedule>;

// Attempts to compute a reasonable epilogue tile based on block tile shape or allows the user to provide one.
template <class ElementD, class EpilogueTileType, class Schedule, class TileShape_MNK>
constexpr auto
dual_sm90_compute_tile_shape_or_override() {
  if constexpr (cute::is_same_v<EpilogueTileType, EpilogueTileAuto>) {
    auto epi_tile = [&] () {
      if constexpr (detail::dual_sm90_is_cooperative_v<Schedule>) {

        auto tile_m = cute::min(_128{}, size<0>(TileShape_MNK{}));
        auto tile_n = cute::gcd(cute::min(_32{}, size<1>(TileShape_MNK{})), size<1>(TileShape_MNK{}));
        return make_shape(tile_m, tile_n);
      }
      else if constexpr (detail::dual_sm90_is_warp_specialized_v<Schedule>) {
        constexpr int N_perf = (sizeof_bits_v<ElementD> == 8) && (size<1>(TileShape_MNK{}) % 64 == 0) ? 64 : 32;
        auto tile_m = cute::min(_64{}, size<0>(TileShape_MNK{}));
        auto tile_n = cute::gcd(cute::min(Int<N_perf>{}, size<1>(TileShape_MNK{})), size<1>(TileShape_MNK{}));
        return make_shape(tile_m, tile_n);
      }
      else {
        static_assert(cutlass::detail::dependent_false<Schedule>, "Unsupported schedule.");
      }
    }();

    return cute::transform(epi_tile, seq<0,1>{},
      [] (auto epi_tiler, auto I) {
        auto cta_tiler = make_layout(get<I>(TileShape_MNK{}));
        // This is a multimodal CTA tiler, transform before returning
        if constexpr (depth(cta_tiler) > 0) {
          // This is an implicit multimodal tiler, match profile and return
          if constexpr (tuple_size_v<decltype(shape(cta_tiler))> == 1) {
            return make_tile(epi_tiler);
          }
          // This is an explicit multimodal tiler, compose out epi tiler
          else {
            return composition(cta_tiler, epi_tiler);
          }
        }
        // This is a flat CTA tiler, no need for transformation
        else {
          return epi_tiler;
        }
      });
  }
  else if constexpr (cute::is_tuple<EpilogueTileType>::value) {
    EpilogueTileType epi_tile;
    constexpr int M = size<0>(shape(epi_tile));
    constexpr int N = size<1>(shape(epi_tile));

    static_assert(!is_layout<EpilogueTileType>::value, "EpilogueTile must be a cute::Tile or cute::Shape");
    static_assert(M ==  64 && detail::dual_sm90_is_warp_specialized_v<Schedule> ||
                  M == 128 && detail::dual_sm90_is_cooperative_v<Schedule>, "Unsupported tile shape");
    static_assert(N % 16 == 0, "Unsupported tile shape");

    return epi_tile;
  }
  else {
    static_assert(cutlass::detail::dependent_false<EpilogueTileType>, "Invalid type for EpilogueTileType.");
  }
}
// callbacks builder with operation tag
template<
  class DispatchPolicy,
  class FusionOp,
  class TileShape_MNK,
  class EpilogueTile_MN,
  class ElementAccumulator,
  class AccLoadOp = cute::DefaultCopy,
  class = void
>
struct DualCallbacksBuilder {
  using Callbacks = fusion::DualFusionCallbacks<DispatchPolicy, FusionOp, TileShape_MNK, EpilogueTile_MN>;
};

// aux fusion callbacks builder for sm90 tma epilogue
template <
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  bool DelayTmaStore,
  class FusionOp,
  class TileShape_MNK,
  class EpilogueTile_MN,
  class AccLoadOp,
  class ElementAccumulator
>
struct DualCallbacksBuilder<
  DualSm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
  FusionOp,
  TileShape_MNK,
  EpilogueTile_MN,
  ElementAccumulator,
  AccLoadOp,
  cute::enable_if_t<(FusionOp::IsAuxOutSupported ^ FusionOp::IsAuxInSupported) // only one aux tensor
              && not cute::is_subbyte_v<typename FusionOp::ElementAux>> // aux subbyte tensor doesn't use smem
> {
  using GmemStrideTypeAux = gemm::TagToStrideC_t<typename FusionOp::GmemLayoutTagAux>;
  using SmemLayoutAtomAux = decltype(detail::dual_sm90_get_epilogue_smem_swizzle_layout_atom<
    GmemStrideTypeAux, typename FusionOp::ElementAux, EpilogueTile_MN>());
  using CopyOpR2S = decltype(detail::sm90_get_smem_store_op_for_accumulator<
    GmemStrideTypeAux, typename FusionOp::ElementAux, EpilogueTile_MN>());
  using CopyOpS2R = decltype(detail::sm90_get_smem_load_op_for_source<
    GmemStrideTypeAux, typename FusionOp::ElementAux, EpilogueTile_MN>());
  using SmemCopyOpAux = cute::conditional_t<FusionOp::IsAuxOutSupported, CopyOpR2S, CopyOpS2R>;

  using Callbacks = fusion::DualFusionCallbacks<
    DualSm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
    FusionOp, TileShape_MNK, EpilogueTile_MN,
    SmemLayoutAtomAux, SmemCopyOpAux
  >;
};

template <
  int StagesC,
  int StagesD,
  int FragmentSize,
  bool ReuseSmemC,
  bool DelayTmaStore,
  class FusionOp,
  class TileShape_MNK,
  class EpilogueTile_MN,
  class AccLoadOp,
  class ElementAccumulator
>
struct DualCallbacksBuilder<
  DualSm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
  FusionOp,
  TileShape_MNK,
  EpilogueTile_MN,
  ElementAccumulator,
  AccLoadOp,
  cute::enable_if_t<(FusionOp::IsAuxOutSupported ^ FusionOp::IsAuxInSupported) // only one aux tensor
              && sizeof_bits_v<typename FusionOp::ElementAux> == 1>
> {
  using Callbacks = fusion::DualFusionCallbacks<
    DualSm90TmaWarpSpecialized<StagesC, StagesD, FragmentSize, ReuseSmemC, DelayTmaStore>,
    FusionOp, TileShape_MNK, EpilogueTile_MN,
    Layout<_1,_0>, DefaultCopy // aux bit tensor doesn't use smem
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
  class ElementD_,
  class GmemLayoutTagD,
  int AlignmentD,
  class FusionOpOrCallbacks,
  class DispatchPolicy
>
struct DualSm90TmaBuilderImpl {
  // C/D should meet TMA alignment requirement if not void
  static_assert(detail::is_aligned<ElementC_, AlignmentC, ElementD_, AlignmentD>(),
                "C/D Should meet TMA alignment requirement\n");
  // Passing void D disables destination store + smem allocation
  using ElementD = cute::conditional_t<cute::is_void_v<ElementD_>,
                     fusion::get_element_aux_t<FusionOpOrCallbacks>, ElementD_>;

  // Passing void C disables source load + smem allocation
  using ElementC = cute::conditional_t<cute::is_void_v<ElementC_>,ElementD,ElementC_>; // prevents void ref breakages
  using GmemLayoutTagC = cute::conditional_t<cute::is_void_v<ElementC_>,GmemLayoutTagD,GmemLayoutTagC_>;

  using GmemStrideTypeC = cutlass::detail::TagToStrideC_t<GmemLayoutTagC>;
  using GmemStrideTypeD = cutlass::detail::TagToStrideC_t<GmemLayoutTagD>;
  
  using UnderlyingGmemStrideTypeC = cute::remove_pointer_t<GmemStrideTypeC>;
  using UnderlyingGmemStrideTypeD = cute::remove_pointer_t<GmemStrideTypeD>;

  using CopyOpS2G = cute::conditional_t<detail::is_im2col_mode<GmemLayoutTagD>,
      SM90_TMA_STORE_IM2COL,
      SM90_TMA_STORE
    >;
  using CopyOpG2S = cute::conditional_t<detail::is_im2col_mode<GmemLayoutTagC>,
      SM90_TMA_LOAD_IM2COL,
      SM90_TMA_LOAD
    >;

  // Get the smallest tiled copy we can use to retile the accumulators
  // using CopyAtomC = Copy_Atom<SM90_U32x4_STSM_N, cutlass::half_t>;
  using CopyAtomC = cute::conditional_t<
    size<1>(EpilogueTile_MN{}) % 16 == 0,
    Copy_Atom<SM90_U32x4_STSM_N, cutlass::half_t>,
    cute::conditional_t<
      size<1>(EpilogueTile_MN{}) % 8 == 0,
      Copy_Atom<SM90_U32x2_STSM_N, cutlass::half_t>,
      void
    >
  >;
  static_assert(!cute::is_same_v<CopyAtomC, void>, "CopyAtomC can't be void, divisiblity check for EpilogueTile_MN failed");
  // Get register to register tiled copy that happen before shared memory store.
  // Apply void as no register transform op needed currently.
  using CopyOpR2R = void;

  // TMA builder allows for passing callbacks directly, which is either a fusion::FusionCallbacks
  // instance or a direct visitor implementation, e.g. fusion::Sm90LinearCombination
  using DualFusionCallbacks = 
    typename DualCallbacksBuilder<
      DispatchPolicy,
      FusionOpOrCallbacks,
      TileShape_MNK,
      EpilogueTile_MN,
      ElementAccumulator
    >::Callbacks;

  using CollectiveOp = cutlass::epilogue::collective::DualCollectiveEpilogue<
      DispatchPolicy,
      TileShape_MNK,
      EpilogueTile_MN,
      ElementC_, // Need to pass void through to expose via GemmUniversal
      GmemStrideTypeC,
      ElementD_,
      GmemStrideTypeD,
      DualFusionCallbacks,
      CopyOpG2S,
      decltype(detail::dual_sm90_get_epilogue_smem_swizzle_layout_atom<UnderlyingGmemStrideTypeC, ElementC, EpilogueTile_MN>()),
      decltype(detail::sm90_get_smem_load_op_for_source<UnderlyingGmemStrideTypeC, ElementC, EpilogueTile_MN>()),
      CopyOpS2G,
      decltype(detail::dual_sm90_get_epilogue_smem_swizzle_layout_atom<UnderlyingGmemStrideTypeD, ElementD, EpilogueTile_MN>()),
      decltype(detail::sm90_get_smem_store_op_for_accumulator<UnderlyingGmemStrideTypeD, ElementD, EpilogueTile_MN>()),
      CopyAtomC,
      CopyOpR2R
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
struct DualEpilogueDescriptor {
  using TileShape = TileShape_MNK;
  using EpilogueTile = 
    decltype(
      detail::dual_sm90_compute_tile_shape_or_override<
        ElementD, EpilogueTileType, Schedule, TileShape_MNK
      >()
    );
  using DispatchPolicy = 
    decltype(
      detail::dual_sm90_get_tma_dispatch_policy<
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
struct DualAuxLoadDescriptor {
  constexpr static int Stages = EpilogueDescriptor::StagesC;
  using EpilogueTile = typename EpilogueDescriptor::EpilogueTile;
  using Element = ElementAux;
  using Stride = cutlass::detail::TagToStrideC_t<StrideOrLayoutTag>;
  using SmemLayoutAtom =
    decltype(
      detail::dual_sm90_get_epilogue_smem_swizzle_layout_atom<
        Stride, ElementAux, typename EpilogueDescriptor::EpilogueTile
      >()
    );
  using CopyOpS2R =
    decltype(detail::sm90_get_smem_load_op_for_source<Stride, ElementAux, EpilogueTile>());
};

// Get Stride, SmemLayout, and CopyOpS2R for AuxStore node
template<
  typename EpilogueDescriptor,
  typename StrideOrLayoutTag,
  typename ElementAux
>
struct DualAuxStoreDescriptor {
  constexpr static int Stages = EpilogueDescriptor::StagesD;
  using EpilogueTile = typename EpilogueDescriptor::EpilogueTile;
  using Element = ElementAux;
  using Stride = cutlass::detail::TagToStrideC_t<StrideOrLayoutTag>;
  using SmemLayoutAtom =
    decltype(
      detail::dual_sm90_get_epilogue_smem_swizzle_layout_atom<
        Stride, ElementAux, typename EpilogueDescriptor::EpilogueTile
      >()
    );
  using CopyOpR2S =
    decltype(detail::sm90_get_smem_store_op_for_accumulator<Stride, ElementAux, EpilogueTile>());
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////

template <
  class ArchTag,
  class OpClass,
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
  class EpilogueScheduleType,
  class FusionOpOrCallbacks = cutlass::epilogue::fusion::DualLinearCombination<ElementD,ElementCompute,ElementC,ElementCompute>,
  class Enable = void
>
struct DualCollectiveBuilder {
  static_assert(cutlass::detail::dependent_false<ArchTag>,
      "Could not build a collective epilogue for given parameters.");
};

// Tma warp-specialized builder
template <
  class OpClass,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC,
  class GmemLayoutTagC,
  int AlignmentC,
  class ElementD_,
  class GmemLayoutTagD,
  int AlignmentD,
  class Schedule,
  class FusionOperation
>
struct DualCollectiveBuilder<
    arch::Sm90,
    OpClass,
    TileShape_MNK,
    ClusterShape_MNK,
    EpilogueTileType,
    ElementAccumulator,
    ElementCompute,
    ElementC,
    GmemLayoutTagC,
    AlignmentC,
    ElementD_,
    GmemLayoutTagD,
    AlignmentD,
    Schedule,
    FusionOperation,
    cute::enable_if_t<
                      cute::is_same_v<Schedule, DualTmaWarpSpecializedCooperative>
                     >> {
private:
  using ElementD = cute::conditional_t<cute::is_void_v<ElementD_>,
                     fusion::dual_get_element_aux_t<FusionOperation>, ElementD_>;
  using EpilogueTile_MN =
    decltype(detail::dual_sm90_compute_tile_shape_or_override<ElementD, EpilogueTileType, Schedule, TileShape_MNK>());
  using DispatchPolicy =
    decltype(detail::dual_sm90_get_tma_dispatch_policy<TileShape_MNK,EpilogueTile_MN,ElementC,ElementD,Schedule>());

public:
  using CollectiveOp =
    typename detail::DualSm90TmaBuilderImpl<
      TileShape_MNK,
      EpilogueTile_MN,
      ElementAccumulator,
      ElementCompute,
      ElementC,
      GmemLayoutTagC,
      AlignmentC,
      ElementD_,
      GmemLayoutTagD,
      AlignmentD,
      FusionOperation,
      DispatchPolicy
    >::CollectiveOp;
};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::epilogue::collective
