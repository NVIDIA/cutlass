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
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/epilogue/dispatch_policy.hpp"
#include "cutlass/epilogue/collective/collective_epilogue.hpp"
#include "cutlass/epilogue/thread/linear_combination.h"
#include "cutlass/epilogue/thread/linear_combination_generic.h"
#include "cutlass/epilogue/thread/linear_combination_bias_elementwise.h"

#if defined(__CUDACC_RTC__)
#include <cuda/std/type_traits>
#else
#include <type_traits>
#endif

///////////////////////////////////////////////////////////////////////////////

namespace cutlass::epilogue::collective {

///////////////////////////////////////////////////////////////////////////////

namespace detail {

// Returns the smem layout atom to be used for C or D matrix
template<class GmemStrideType, class Element, class EpilogueTile_MN>
constexpr auto
sm90_get_epilogue_smem_swizzle_layout_atom() {
  using namespace cute;

  // ColMajor C/D (M-major)
  if constexpr (size<0>(GmemStrideType{}) == 1) {
    return cutlass::gemm::collective::detail::ss_smem_selector<
      cute::GMMA::Major::MN, Element, decltype(get<0>(EpilogueTile_MN{})), decltype(get<1>(EpilogueTile_MN{}))
    >();
  }
  // RowMajor C/D (N-major)
  else if constexpr (size<1>(GmemStrideType{}) == 1) {
    return cutlass::gemm::collective::detail::ss_smem_selector<
      cute::GMMA::Major::K , Element, decltype(get<0>(EpilogueTile_MN{})), decltype(get<1>(EpilogueTile_MN{}))
    >();
  }
  else {
    static_assert(cutlass::detail::dependent_false<GmemStrideType>, "Unsupported gmem layout.");
  }
}

// Attempts to compute a reasonable epilogue tile based on block tile shape or allows the user to provide one.
template <class Element, class EpilogueTileType, class Schedule>
constexpr auto
sm90_compute_tile_shape_or_override() {
  if constexpr (cute::is_same_v<EpilogueTileType, EpilogueTileAuto>) {

    if constexpr (detail::sm90_is_cooperative_v<Schedule>) {
      return Shape<_128,_16>{};
    }
    else if constexpr (detail::sm90_is_warp_specialized_v<Schedule>) {
      return Shape<_64,_32>{};
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
    static_assert(N % 8 == 0, "Unsupported tile shape");

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

// Helper for building TMA warp-specialized collective epilogues, specialized by
// the thread-level epilogue operation performed and the dispatch policy to use.
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
  class ThreadOp,
  class DispatchPolicy
>
struct TmaBuilderImpl {

  // Passing void C disables source load
  using ElementC = cute::conditional_t<cute::is_void_v<ElementC_>,ElementD,ElementC_>; // prevents void ref breakages
  using GmemLayoutTagC = cute::conditional_t<cute::is_void_v<ElementC_>,GmemLayoutTagD,GmemLayoutTagC_>;

  using GmemStrideTypeC = gemm::TagToStrideC_t<GmemLayoutTagC>;
  using GmemStrideTypeD = gemm::TagToStrideC_t<GmemLayoutTagD>;

  using EpilogueTile_MN = decltype(detail::sm90_compute_tile_shape_or_override<
      ElementD, EpilogueTileType, Schedule>());

  using CollectiveOp = cutlass::epilogue::collective::CollectiveEpilogue<
      DispatchPolicy,
      TileShape_MNK,
      EpilogueTile_MN,
      ElementC_, // Need to pass void through to expose via GemmUniversal
      GmemStrideTypeC,
      ElementD,
      GmemStrideTypeD,
      ThreadOp,
      SM90_TMA_LOAD,
      decltype(detail::sm90_get_epilogue_smem_swizzle_layout_atom<GmemStrideTypeC, ElementC, TileShape_MNK>()),
      decltype(detail::sm90_get_smem_load_op_for_source<GmemStrideTypeC, ElementC>()),
      SM90_TMA_STORE,
      decltype(detail::sm90_get_epilogue_smem_swizzle_layout_atom<GmemStrideTypeD, ElementD, EpilogueTile_MN>()),
      decltype(detail::sm90_get_smem_store_op_for_accumulator<GmemStrideTypeD, ElementD>())
    >;
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
  class Schedule
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
    Schedule,
    cute::enable_if_t<cute::is_same_v<Schedule, NoSmemWarpSpecialized>>> {

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
    ScaleType, FloatRoundStyle::round_to_nearest, ElementC>;

  using CollectiveOp = cutlass::epilogue::collective::detail::Sm90TmaWarpSpecializedAdapter<
    cutlass::epilogue::collective::DefaultEpilogue<
      cutlass::gemm::TagToStrideC_t<GmemLayoutTagC>,
      cutlass::gemm::TagToStrideC_t<GmemLayoutTagD>,
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
  class ElementC_,
  class GmemLayoutTagC,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class Schedule
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
    GmemLayoutTagC,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    Schedule,
    cute::enable_if_t<cute::is_same_v<Schedule, TmaWarpSpecialized> ||
                      cute::is_same_v<Schedule, TmaWarpSpecializedCooperative> >> {
public:
  using ElementC = cute::conditional_t<cute::is_void_v<ElementC_>,ElementD,ElementC_>; // prevents void ref breakages
  static constexpr thread::ScaleType::Kind ScaleType = cute::is_void_v<ElementC_> ?
      thread::ScaleType::OnlyAlphaScaling : thread::ScaleType::Default;

  static constexpr int FragmentSize = 4;
  using ThreadOp = thread::LinearCombination<
    ElementD, FragmentSize, ElementAccumulator, ElementCompute,
    ScaleType, FloatRoundStyle::round_to_nearest, ElementC>;

private:
  static constexpr int StagesC = 1;
  static constexpr int StagesD = 2;
  static constexpr bool DisableReuseSmemC = true;
  using Impl = detail::TmaBuilderImpl<
    TileShape_MNK, ClusterShape_MNK, EpilogueTileType, ElementAccumulator, ElementCompute,
    ElementC_, GmemLayoutTagC, AlignmentC, ElementD, GmemLayoutTagD, AlignmentD,
    Schedule, ThreadOp, cutlass::epilogue::Sm90TmaWarpSpecialized<StagesC,StagesD, DisableReuseSmemC>>;

public:
  using CollectiveOp = typename Impl::CollectiveOp;
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
  class Schedule
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
    cute::enable_if_t<cute::is_same_v<Schedule, EpilogueScheduleAuto>>> {

private:
  static constexpr bool IsTmaAligned = cutlass::gemm::collective::detail::is_aligned<
      ElementC, AlignmentC, ElementD, AlignmentD, cutlass::gemm::collective::detail::tma_alignment_bytes>();

  // Current TMA epilogues require sixteen-bit data types and epilogue tile M to be of size 64.
  // Only dispatch to the TMA builder if these requirements are satisfied.
  static constexpr bool IsSixteenBit = sizeof_bits<ElementC>::value == 16 && sizeof_bits<ElementD>::value == 16;
  static constexpr bool IsEpiTileM64 = size<0>(shape(TileShape_MNK{})) == 64;

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
    cute::conditional_t<IsTmaAligned && IsSixteenBit && IsEpiTileM64,
      TmaWarpSpecialized, NoSmemWarpSpecialized>
  >;

public:
  using ThreadOp = typename _CollectiveBuilder::ThreadOp;
  using CollectiveOp = typename _CollectiveBuilder::CollectiveOp;
};

// Tma warp-specialized builder for elementwise fusion
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
  class Schedule
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
    cute::enable_if_t<cute::is_base_of_v<TmaWarpSpecializedElementwiseBase, Schedule> ||
                      cute::is_base_of_v<TmaWarpSpecializedCooperativeElementwiseBase, Schedule> >> {
public:
  static constexpr int FragmentSize = 4;
  using ThreadOp = thread::LinearCombinationGeneric<
    Schedule::ActivationFunctor,
    ElementD, FragmentSize,
    ElementAccumulator, ElementCompute, Schedule::Scale,
    Schedule::Round>;

private:
  static constexpr int StagesC = 1;
  static constexpr int StagesD = 2;
  static constexpr bool DisableReuseSmemC = true;
  using Impl = detail::TmaBuilderImpl<
    TileShape_MNK, ClusterShape_MNK, EpilogueTileType, ElementAccumulator, ElementCompute,
    ElementC, GmemLayoutTagC, AlignmentC, ElementD, GmemLayoutTagD, AlignmentD,
    Schedule, ThreadOp, cutlass::epilogue::Sm90TmaWarpSpecialized<StagesC,StagesD,DisableReuseSmemC>>;

public:
  using CollectiveOp = typename Impl::CollectiveOp;
};

// Tma warp-specialized builder for bias + elementwise fusion
template <
  class TileShape_MNK,
  class ClusterShape_MNK,
  class EpilogueTileType,
  class ElementAccumulator,
  class ElementCompute,
  class ElementC_,
  class GmemLayoutTagC,
  int AlignmentC,
  class ElementD,
  class GmemLayoutTagD,
  int AlignmentD,
  class Schedule
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
    GmemLayoutTagC,
    AlignmentC,
    ElementD,
    GmemLayoutTagD,
    AlignmentD,
    Schedule,
    cute::enable_if_t<cute::is_base_of_v<TmaWarpSpecializedBiasElementwiseBase, Schedule> ||
                      cute::is_base_of_v<TmaWarpSpecializedCooperativeBiasElementwiseBase, Schedule> >> {
private:
  // Passing void C disables source load
  using ElementC = cute::conditional_t<cute::is_void_v<ElementC_>, ElementD, ElementC_>; // prevents void ref breakages

public:
  static constexpr int FragmentSize = 4;
  using ThreadOp = thread::LinearCombinationBiasElementwise<
      ElementC, ElementAccumulator, ElementCompute, ElementD, typename Schedule::ElementT, FragmentSize,
      typename Schedule::ActivationFunctor<ElementCompute>, typename Schedule::BiasOp<ElementCompute>,
      Schedule::StoreT, typename Schedule::ElementBias>;

private:
  static constexpr int StagesC = 1;
  static constexpr int StagesD = 2;
  using Impl = detail::TmaBuilderImpl<
    TileShape_MNK, ClusterShape_MNK, EpilogueTileType, ElementAccumulator, ElementCompute,
    ElementC_, GmemLayoutTagC, AlignmentC, ElementD, GmemLayoutTagD, AlignmentD,
    Schedule, ThreadOp, cutlass::epilogue::Sm90TmaWarpSpecializedBiasElementwise<StagesC,StagesD>>;

public:
  using CollectiveOp = typename Impl::CollectiveOp;
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
  class Schedule
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
    Schedule,
    cute::enable_if_t<cute::is_same_v<Schedule, cutlass::gemm::EpilogueTransposed>>> {
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
    ScaleType, FloatRoundStyle::round_to_nearest, ElementC>;

  using CollectiveOp = cutlass::epilogue::collective::detail::Sm90TmaWarpSpecializedAdapter<
    cutlass::epilogue::collective::DefaultEpilogue<
      cutlass::gemm::TagToStrideC_t<GmemLayoutTagC>,
      cutlass::gemm::TagToStrideC_t<GmemLayoutTagD>,
      ThreadOp,
      cutlass::gemm::EpilogueTransposed>
    >;
};

///////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::epilogue::collective
