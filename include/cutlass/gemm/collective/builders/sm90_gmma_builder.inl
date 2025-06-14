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

#include "cutlass/arch/mma.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/dispatch_policy.hpp"

#include "cutlass/gemm/collective/builders/sm90_common.inl"

// SM90 Collective Builders should be used only starting CUDA 12.0
#if (__CUDACC_VER_MAJOR__ >= 12)
#define CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<int CapacityBytes, class ElementA, class ElementB, class TileShapeMNK, int stages>
constexpr int
compute_stage_count_or_override(StageCount<stages> stage_count) {
  return stages;
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<int CapacityBytes, class ElementA, class ElementB, class TileShapeMNK, int stages>
constexpr int
compute_stage_count_or_override(cute::Int<stages> stage_count) {
  return stages;
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<int CapacityBytes, class ElementA, class ElementB, class TileShapeMNK, int carveout_bytes>
constexpr int
compute_stage_count_or_override(StageCountAutoCarveout<carveout_bytes> stage_count) {
  // 32 bytes to account for barriers etc.
  constexpr int stage_barrier_bytes = 32;
  constexpr int a_bits = static_cast<int>(sizeof_bits<ElementA>::value);
  constexpr int b_bits = static_cast<int>(sizeof_bits<ElementB>::value);
  constexpr int stage_bytes =
    (a_bits * size<0>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) / 8 +
    (b_bits * size<1>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) / 8 +
    stage_barrier_bytes;

  return (CapacityBytes - carveout_bytes) / stage_bytes;
}

template <class ElementA, class LayoutA, class ElementB, class LayoutB>
constexpr bool
is_swapAB(){
  constexpr bool IsInputSizeTwoBytes = is_input_size_two_bytes<ElementA, ElementB>();
  constexpr bool IsLayoutAkBmn = cutlass::gemm::detail::is_k_major_A<LayoutA>() &&
                                 cutlass::gemm::detail::is_mn_major_B<LayoutB>();
  constexpr bool SwapAB = !IsInputSizeTwoBytes && IsLayoutAkBmn;
  return SwapAB;
}

template <class ElementA, class LayoutA, class ElementB, class LayoutB, class KernelScheduleType>
constexpr bool
is_warpspecialized_transpose_B(){
  constexpr bool IsInputSizeTwoBytes = is_input_size_two_bytes<ElementA, ElementB>();
  constexpr bool IsLayoutAmnBmn = cutlass::gemm::detail::is_mn_major_A<LayoutA>() &&
                                  cutlass::gemm::detail::is_mn_major_B<LayoutB>();
  constexpr bool IsWarpSpecialized = cute::is_base_of_v<KernelTmaWarpSpecialized, KernelScheduleType>                ||
                                     cute::is_base_of_v<KernelTmaWarpSpecializedPingpong, KernelScheduleType>        ||
                                     cute::is_base_of_v<KernelTmaWarpSpecializedCooperative, KernelScheduleType>     || 
                                     cute::is_base_of_v<KernelCpAsyncWarpSpecialized, KernelScheduleType>            ||
                                     cute::is_base_of_v<KernelCpAsyncWarpSpecializedPingpong, KernelScheduleType>    ||
                                     cute::is_base_of_v<KernelCpAsyncWarpSpecializedCooperative, KernelScheduleType>;
  constexpr bool IsWarpSpecializedTransposeB = !IsInputSizeTwoBytes && IsLayoutAmnBmn && IsWarpSpecialized;
  return IsWarpSpecializedTransposeB;
}

template <typename ElementA, typename ElementB>
struct Sm90TypeWidths {
  static constexpr bool IsElementALarger = (cute::sizeof_bits_v<ElementA>) > cute::sizeof_bits_v<ElementB>;
  using WideType   = cute::conditional_t<IsElementALarger, ElementA, ElementB>;                               
  using NarrowType = cute::conditional_t<IsElementALarger, ElementB, ElementA>;
};


template <class ElementA, class LayoutA, class ElementB, class LayoutB>
constexpr bool
sm90_is_narrow_type_k_major() {
  using Widths = Sm90TypeWidths<ElementA, ElementB>;
  using NarrowType = typename Widths::NarrowType;
  using WideType = typename Widths::WideType;

  constexpr bool IsANarrow = cute::is_same_v<NarrowType, ElementA>;
  constexpr cute::GMMA::Major NarrowGmmaMajor = IsANarrow ? detail::gmma_rs_tag_to_major_A<LayoutA>() : 
                                                            detail::gmma_rs_tag_to_major_B<LayoutB>();

  constexpr bool IsNarrowLayoutKMajor = NarrowGmmaMajor == cute::GMMA::Major::K;
  return IsNarrowLayoutKMajor;
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_TMA_WS_SS
template <
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      (cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecialized> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedPingpong> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperative>) &&
       not detail::is_use_rmem_A<ElementA, GmemLayoutA, ElementB, GmemLayoutB>()>
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA> == 0, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif
  static_assert(detail::is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, detail::tma_alignment_bytes>(),
                "Should meet TMA alignment requirement\n");

static constexpr bool IsFP8Input = detail::is_input_fp8<ElementA, ElementB>();

  // For fp32 types, map to tf32 MMA value type
  using MmaElementA = cute::conditional_t<cute::is_same_v<ElementA, float>, tfloat32_t, ElementA>;
  using MmaElementB = cute::conditional_t<cute::is_same_v<ElementB, float>, tfloat32_t, ElementB>;

  static constexpr cute::GMMA::Major GmmaMajorA = detail::gmma_ss_tag_to_major_A<MmaElementA, GmemLayoutA>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::gmma_ss_tag_to_major_B<MmaElementB, GmemLayoutB>();

  using AtomLayoutMNK = cute::conditional_t<cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperative>,
      Layout<Shape<_2,_1,_1>>, Layout<Shape<_1,_1,_1>>>;

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::ss_op_selector<
      MmaElementA, MmaElementB, ElementAccumulator, TileShape_MNK, GmmaMajorA, GmmaMajorB>(), AtomLayoutMNK{}));

  using GmemTiledCopyA = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<1>(ClusterShape_MNK{})));
  using GmemTiledCopyB = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));

  using SmemLayoutAtomA = decltype(detail::ss_smem_selector<
      GmmaMajorA, MmaElementA, decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());
  using SmemLayoutAtomB = decltype(detail::ss_smem_selector<
      GmmaMajorB, MmaElementB, decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  static constexpr int PipelineStages = detail::compute_stage_count_or_override<detail::sm90_smem_capacity_bytes,
      MmaElementA, MmaElementB, TileShape_MNK>(StageCountType{});
  /* For FP8 use a separate mainloop compared to other datatypes */
  using DispatchPolicy = cute::conditional_t<IsFP8Input,
   MainloopSm90TmaGmmaWarpSpecializedFP8<PipelineStages, ClusterShape_MNK, KernelScheduleType>,
   MainloopSm90TmaGmmaWarpSpecialized<PipelineStages, ClusterShape_MNK, KernelScheduleType>>;

  using SmemCopyAtomA = void; 
  using SmemCopyAtomB = void; 

  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      TagToStrideA_t<GmemLayoutA>,
      ElementB,
      TagToStrideB_t<GmemLayoutB>,
      TiledMma,
      GmemTiledCopyA,
      SmemLayoutAtomA,
      SmemCopyAtomA,
      cute::identity,
      GmemTiledCopyB,
      SmemLayoutAtomB,
      SmemCopyAtomB,
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_TMA_WS_RS
template <
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      (cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecialized> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedPingpong> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperative>) &&
      detail::is_use_rmem_A<ElementA, GmemLayoutA, ElementB, GmemLayoutB>()> 
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
  static_assert(detail::is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, detail::tma_alignment_bytes>(),
                "Should meet TMA alignment requirement\n");
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA> == 0, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif
  static constexpr cute::GMMA::Major GmmaMajorA = detail::gmma_rs_tag_to_major_A<GmemLayoutA>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::gmma_rs_tag_to_major_B<GmemLayoutB>();
  static constexpr bool SwapAB = detail::is_swapAB<ElementA, GmemLayoutA, ElementB, GmemLayoutB>();
  static constexpr bool IsWarpSpecializedTransposeB = detail::is_warpspecialized_transpose_B<
      ElementA, GmemLayoutA, ElementB, GmemLayoutB, KernelScheduleType>();

  // For fp32 types, map to tf32 MMA value type
  using MmaElementA = cute::conditional_t<cute::is_same_v<ElementA, float>, tfloat32_t, ElementA>;
  using MmaElementB = cute::conditional_t<cute::is_same_v<ElementB, float>, tfloat32_t, ElementB>;

  using AtomLayoutMNK = cute::conditional_t<cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperative>,
      Layout<Shape<_2,_1,_1>>, Layout<Shape<_1,_1,_1>>>;

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::rs_op_selector<
      MmaElementA, MmaElementB, ElementAccumulator, TileShape_MNK, GMMA::Major::K, GMMA::Major::K>(), AtomLayoutMNK{}));

  using GmemTiledCopyA = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<1>(ClusterShape_MNK{})));
  using GmemTiledCopyB = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));

  using SmemLayoutAtomA = decltype(detail::rs_smem_selector<GmmaMajorA, MmaElementA,
      decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), IsWarpSpecializedTransposeB>());
  using SmemLayoutAtomB = decltype(detail::rs_smem_selector<GmmaMajorB, MmaElementB,
      decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), IsWarpSpecializedTransposeB>());

  static constexpr int PipelineStages = detail::compute_stage_count_or_override<detail::sm90_smem_capacity_bytes,
      MmaElementA, MmaElementB, TileShape_MNK>(StageCountType{});

  using DispatchPolicy = MainloopSm90TmaGmmaRmemAWarpSpecialized<
      PipelineStages, ClusterShape_MNK, KernelScheduleType>;

  using SmemCopyAtomA = cute::conditional_t<SwapAB, void, Copy_Atom<cute::DefaultCopy, ElementA>>;
  using SmemCopyAtomB = cute::conditional_t<SwapAB, Copy_Atom<cute::DefaultCopy, ElementB>, void>;

  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      TagToStrideA_t<GmemLayoutA>,
      ElementB,
      TagToStrideB_t<GmemLayoutB>,
      TiledMma,
      GmemTiledCopyA,
      SmemLayoutAtomA,
      SmemCopyAtomA,
      cute::identity,
      GmemTiledCopyB,
      SmemLayoutAtomB,
      SmemCopyAtomB,
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_TMA_WS_RS Mixed GEMM
template <
  class ElementPairA_,
  class GmemLayoutPairA_,
  int AlignmentA,
  class ElementPairB_,
  class GmemLayoutPairB_,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementPairA_,
    GmemLayoutPairA_,
    AlignmentA,
    ElementPairB_,
    GmemLayoutPairB_,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      (cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedMixedInput> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedPingpongMixedInput> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperativeMixedInput>)>
> {

public:
  static constexpr bool IsATransformed = cute::sizeof_bits_v<ElementPairA_> < cute::sizeof_bits_v<ElementPairB_>;

  // Split out items for processessing, no splitting for now since scales aren't supported.
  using ElementA = ElementPairA_;
  using ElementB = ElementPairB_;

  using GmemLayoutA = GmemLayoutPairA_; 
  using GmemLayoutB = GmemLayoutPairB_;

  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
  static_assert(detail::is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, detail::tma_alignment_bytes>(),
                "Should meet TMA alignment requirement\n");
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA> == 0, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif
  static constexpr cute::GMMA::Major GmmaMajorA = detail::gmma_rs_tag_to_major_A<GmemLayoutA>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::gmma_rs_tag_to_major_B<GmemLayoutB>();
  static constexpr bool IsWarpSpecializedTransposeB = detail::is_warpspecialized_transpose_B<
      ElementA, GmemLayoutA, ElementB, GmemLayoutB, KernelScheduleType>();
  static_assert(!IsWarpSpecializedTransposeB, "Mixed input GEMM does not support WS transpose B.");

  // If A is scaled, then we don't need to swap. Otherwise, we must ensure B goes to RF and we must swap the operands.
  static constexpr bool SwapAB = !IsATransformed;
  static_assert(detail::sm90_is_narrow_type_k_major<ElementA, GmemLayoutA, ElementB, GmemLayoutB>(), "The narrow type must be K-major.");

  static_assert((IsATransformed && (cute::sizeof_bits_v<ElementA> <= 8) && (sizeof(ElementB) == 2)) ||
                (!IsATransformed && (cute::sizeof_bits_v<ElementB> <= 8) && (sizeof(ElementA) == 2)) ||
                (GmmaMajorA == cute::GMMA::Major::K && GmmaMajorB ==  cute::GMMA::Major::K), 
                "The unscaled element must be 2 bytes OR both inputs must be K-major");
  // When we relax the above assertion, we must handle setting the tile mma GmmaMajorB correctly.
  static constexpr cute::GMMA::Major TiledMmaGmmaMajorB = SwapAB ? GmmaMajorA : GmmaMajorB;

  using ElementMma = cute::conditional_t<IsATransformed, ElementB, ElementA>;
  using AtomLayoutMNK = cute::conditional_t<cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperativeMixedInput>,
      Layout<Shape<_2,_1,_1>>, Layout<Shape<_1,_1,_1>>>;

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::rs_op_selector<
      ElementMma, ElementMma, ElementAccumulator, TileShape_MNK, GMMA::Major::K, TiledMmaGmmaMajorB>(), AtomLayoutMNK{}));

  using GmemTiledCopyA = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<1>(ClusterShape_MNK{})));
  using GmemTiledCopyB = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));
  using SmemLayoutAtomA = decltype(detail::rs_smem_selector<GmmaMajorA, ElementA,
      decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), IsWarpSpecializedTransposeB>());
  using SmemLayoutAtomB = decltype(detail::rs_smem_selector<GmmaMajorB, ElementB,
      decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), IsWarpSpecializedTransposeB>());

  using RealElementA = cute::conditional_t<SwapAB, ElementB, ElementA>;
  using RealElementB = cute::conditional_t<SwapAB, ElementA, ElementB>;
  static constexpr int PipelineStages = detail::compute_stage_count_or_override<detail::sm90_smem_capacity_bytes,
      RealElementA, RealElementB, TileShape_MNK>(StageCountType{});

  using SmemCopyAtomA = cute::conditional_t<SwapAB, void, Copy_Atom<cute::DefaultCopy, ElementA>>;
  using SmemCopyAtomB = cute::conditional_t<SwapAB, Copy_Atom<cute::DefaultCopy, ElementB>, void>;

  using DispatchPolicy = MainloopSm90TmaGmmaRmemAWarpSpecializedMixedInput<PipelineStages, ClusterShape_MNK, KernelScheduleType>;

  // We pack the scale data with the operand that will be optionally scaled and converted before MMA.
  using StrideAPair = TagToStrideA_t<GmemLayoutA>;
  using StrideBPair = TagToStrideB_t<GmemLayoutB>;

  using GmemTiledCopyAPair  = GmemTiledCopyA;
  using SmemLayoutAtomAPair = SmemLayoutAtomA;
  using SmemCopyAtomAPair   = SmemCopyAtomA;

  using GmemTiledCopyBPair  = GmemTiledCopyB;
  using SmemLayoutAtomBPair = SmemLayoutAtomB;
  using SmemCopyAtomBPair   = SmemCopyAtomB;


  // If the src type of the converter is the same as ElementA,
  // interpret this as if the user wanted to apply the scale to the A matrix.
  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementPairA_,
      StrideAPair,
      ElementPairB_,
      StrideBPair,
      TiledMma,
      GmemTiledCopyAPair,
      SmemLayoutAtomAPair,
      SmemCopyAtomAPair,
      cute::identity,
      GmemTiledCopyBPair,
      SmemLayoutAtomBPair,
      SmemCopyAtomBPair,
      cute::identity
    >;

};

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_TMA_WS_FP8_FAST_ACCUM_SS
template <
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedFP8FastAccum> ||
      cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedPingpongFP8FastAccum> ||
      cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperativeFP8FastAccum>>
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
  static_assert(detail::is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, detail::tma_alignment_bytes>(),
                "Not meet TMA alignment requirement yet\n");
  static_assert(detail::is_input_fp8<ElementA, ElementB>(),
                "Only FP8 datatypes are compatible with these kernel schedules\n");
  // Dispatch TN fp8 kernels only to TMA warp specialized FP8 builder
  static_assert(!detail::is_use_rmem_A<ElementA, GmemLayoutA, ElementB, GmemLayoutB>(),
                 "Not supported for fp8 non-TN warp specialized kernels yet\n");
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA> == 0, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif

  static constexpr cute::GMMA::Major GmmaMajorA = detail::gmma_ss_tag_to_major_A<ElementA, GmemLayoutA>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::gmma_ss_tag_to_major_B<ElementB, GmemLayoutB>();

  using AtomLayoutMNK = cute::conditional_t<cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperativeFP8FastAccum>,
      Layout<Shape<_2,_1,_1>>, Layout<Shape<_1,_1,_1>>>;

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::ss_op_selector<
      ElementA, ElementB, ElementAccumulator, TileShape_MNK, GmmaMajorA, GmmaMajorB>(), AtomLayoutMNK{}));

  using GmemTiledCopyA = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<1>(ClusterShape_MNK{})));
  using GmemTiledCopyB = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));

  using SmemLayoutAtomA = decltype(detail::ss_smem_selector<
      GmmaMajorA, ElementA, decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());
  using SmemLayoutAtomB = decltype(detail::ss_smem_selector<
      GmmaMajorB, ElementB, decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  static constexpr int PipelineStages = detail::compute_stage_count_or_override<detail::sm90_smem_capacity_bytes,
      ElementA, ElementB, TileShape_MNK>(StageCountType{});
  using DispatchPolicy = MainloopSm90TmaGmmaWarpSpecialized<
      PipelineStages, ClusterShape_MNK, KernelScheduleType>;

  using SmemCopyAtomA = void;
  using SmemCopyAtomB = void;

  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      TagToStrideA_t<GmemLayoutA>,
      ElementB,
      TagToStrideB_t<GmemLayoutB>,
      TiledMma,
      GmemTiledCopyA,
      SmemLayoutAtomA,
      SmemCopyAtomA,
      cute::identity,
      GmemTiledCopyB,
      SmemLayoutAtomB,
      SmemCopyAtomB,
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_TMA_SS
template <
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<cute::is_same_v<KernelScheduleType, KernelTma> &&
                     not detail::is_use_rmem_A<ElementA, GmemLayoutA, ElementB, GmemLayoutB>()>
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
  static_assert(detail::is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, detail::tma_alignment_bytes>(),
                "Should meet TMA alignment requirement\n");
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA> == 0, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif

  // For fp32 types, map to tf32 MMA value type
  using MmaElementA = cute::conditional_t<cute::is_same_v<ElementA, float>, tfloat32_t, ElementA>;
  using MmaElementB = cute::conditional_t<cute::is_same_v<ElementB, float>, tfloat32_t, ElementB>;

  static constexpr cute::GMMA::Major GmmaMajorA = detail::gmma_ss_tag_to_major_A<MmaElementA, GmemLayoutA>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::gmma_ss_tag_to_major_B<MmaElementB, GmemLayoutB>();

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::ss_op_selector<
      MmaElementA, MmaElementB, ElementAccumulator, TileShape_MNK, GmmaMajorA, GmmaMajorB>()));

  using GmemTiledCopyA = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<1>(ClusterShape_MNK{})));
  using GmemTiledCopyB = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));

  using SmemLayoutAtomA = decltype(detail::ss_smem_selector<
      GmmaMajorA, MmaElementA, decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());
  using SmemLayoutAtomB = decltype(detail::ss_smem_selector<
      GmmaMajorB, MmaElementB, decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  static constexpr int PipelineStages = detail::compute_stage_count_or_override<detail::sm90_smem_capacity_bytes,
      MmaElementA, MmaElementB, TileShape_MNK>(StageCountType{});
  using DispatchPolicy = MainloopSm90TmaGmma<PipelineStages, ClusterShape_MNK>;

  using SmemCopyAtomA = void;
  using SmemCopyAtomB = void;

  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      TagToStrideA_t<GmemLayoutA>,
      ElementB,
      TagToStrideB_t<GmemLayoutB>,
      TiledMma,
      GmemTiledCopyA,
      SmemLayoutAtomA,
      SmemCopyAtomA,
      cute::identity,
      GmemTiledCopyB,
      SmemLayoutAtomB,
      SmemCopyAtomB,
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_CpAsync
template <
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct [[deprecated("Use one of KernelCpAsyncWarpSpecialized schedules instead")]]
CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      cute::is_same_v<KernelScheduleType, KernelMultistage>>
> {
  // Map to warp-specialized kernels for better performance
  using CollectiveOp = typename CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelCpAsyncWarpSpecialized
  >::CollectiveOp;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_CpAsync_WS_SS
template <
  class ElementA,
  class GmemLayoutA,
  int   AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int   AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      (cute::is_same_v<KernelScheduleType, KernelCpAsyncWarpSpecialized> ||
       cute::is_same_v<KernelScheduleType, KernelCpAsyncWarpSpecializedCooperative> ||
       cute::is_same_v<KernelScheduleType, KernelCpAsyncWarpSpecializedPingpong>) &&
      not detail::is_use_rmem_A<ElementA, GmemLayoutA, ElementB, GmemLayoutB>()
    >
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA> == 0, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif

  // For fp32 types, map to tf32 MMA value type
  using MmaElementA = cute::conditional_t<cute::is_same_v<ElementA, float>, tfloat32_t, ElementA>;
  using MmaElementB = cute::conditional_t<cute::is_same_v<ElementB, float>, tfloat32_t, ElementB>;

  static_assert(detail::is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, detail::cp_async_min_alignment_bytes>(),
                "Minimum alignment required for cp.async is 4B.");

  static constexpr cute::GMMA::Major GmmaMajorA = detail::gmma_ss_tag_to_major_A<ElementA, GmemLayoutA>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::gmma_ss_tag_to_major_B<ElementB, GmemLayoutB>();

  using AtomLayoutMNK = cute::conditional_t<cute::is_same_v<KernelScheduleType, KernelCpAsyncWarpSpecializedCooperative>,
      Layout<Shape<cute::Int<(size<0>(TileShape_MNK{}) < 128) ? 1 : 2>,_1,_1>>, Layout<Shape<_1,_1,_1>>>;

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::ss_op_selector<
      MmaElementA, MmaElementB, ElementAccumulator, TileShape_MNK, GmmaMajorA, GmmaMajorB>(), AtomLayoutMNK{}));

  static constexpr int NumLoadWarpGroups = cute::is_same_v<KernelScheduleType, KernelCpAsyncWarpSpecialized> ? 2 : 1;

  using GmemTiledCopyA = decltype(detail::make_cp_async_gmem_tiled_copy<
      NumThreadsPerWarpGroup * NumLoadWarpGroups, ElementA, AlignmentA, TagToStrideA_t<GmemLayoutA>,
      decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());
  using GmemTiledCopyB = decltype(detail::make_cp_async_gmem_tiled_copy<
      NumThreadsPerWarpGroup * NumLoadWarpGroups, ElementB, AlignmentB, TagToStrideB_t<GmemLayoutB>,
      decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  using SmemLayoutAtomA = decltype(detail::ss_smem_selector<
      GmmaMajorA, MmaElementA, decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());
  using SmemLayoutAtomB = decltype(detail::ss_smem_selector<
      GmmaMajorB, MmaElementB, decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  static constexpr int PipelineStages = detail::compute_stage_count_or_override<
      detail::sm90_smem_capacity_bytes, MmaElementA, MmaElementB, TileShape_MNK>(StageCountType{});

  using DispatchPolicy = MainloopSm90CpAsyncGmmaWarpSpecialized<
      PipelineStages, ClusterShape_MNK, KernelScheduleType>;

  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      TagToStrideA_t<GmemLayoutA>,
      ElementB,
      TagToStrideB_t<GmemLayoutB>,
      TiledMma,
      GmemTiledCopyA,
      SmemLayoutAtomA,
      void,
      cute::identity,
      GmemTiledCopyB,
      SmemLayoutAtomB,
      void,
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_CpAsync_WS_RS
template <
  class ElementA,
  class GmemLayoutA,
  int   AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int   AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      (cute::is_same_v<KernelScheduleType, KernelCpAsyncWarpSpecialized> ||
       cute::is_same_v<KernelScheduleType, KernelCpAsyncWarpSpecializedCooperative> ||
       cute::is_same_v<KernelScheduleType, KernelCpAsyncWarpSpecializedPingpong>) &&
      detail::is_use_rmem_A<ElementA, GmemLayoutA, ElementB, GmemLayoutB>()
    >
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA> == 0, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif

  // For fp32 types, map to tf32 MMA value type
  using MmaElementA = cute::conditional_t<cute::is_same_v<ElementA, float>, tfloat32_t, ElementA>;
  using MmaElementB = cute::conditional_t<cute::is_same_v<ElementB, float>, tfloat32_t, ElementB>;

  static_assert(detail::is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, detail::cp_async_min_alignment_bytes>(),
                "Minimum alignment required for cp.async is 4B.");

  static constexpr cute::GMMA::Major GmmaMajorA = detail::gmma_rs_tag_to_major_A<GmemLayoutA>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::gmma_rs_tag_to_major_B<GmemLayoutB>();
  static constexpr bool SwapAB = detail::is_swapAB<ElementA, GmemLayoutA, ElementB, GmemLayoutB>();
  static constexpr bool IsWarpSpecializedTransposeB = detail::is_warpspecialized_transpose_B<
      ElementA, GmemLayoutA, ElementB, GmemLayoutB, KernelScheduleType>();

  using AtomLayoutMNK = cute::conditional_t<cute::is_same_v<KernelScheduleType, KernelCpAsyncWarpSpecializedCooperative>,
      Layout<Shape<cute::Int<(size<0>(TileShape_MNK{}) < 128) ? 1 : 2>,_1,_1>>, Layout<Shape<_1,_1,_1>>>;

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::rs_op_selector<
      MmaElementA, MmaElementB, ElementAccumulator, TileShape_MNK, GMMA::Major::K, GMMA::Major::K>(), AtomLayoutMNK{}));

  static constexpr int NumLoadWarpGroups = 1;

  using GmemTiledCopyA = decltype(detail::make_cp_async_gmem_tiled_copy<
      NumThreadsPerWarpGroup * NumLoadWarpGroups, ElementA, AlignmentA, TagToStrideA_t<GmemLayoutA>,
      decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());
  using GmemTiledCopyB = decltype(detail::make_cp_async_gmem_tiled_copy<
      NumThreadsPerWarpGroup * NumLoadWarpGroups, ElementB, AlignmentB, TagToStrideB_t<GmemLayoutB>,
      decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  using SmemLayoutAtomA = decltype(detail::rs_smem_selector<GmmaMajorA, MmaElementA, 
      decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), IsWarpSpecializedTransposeB>());
  using SmemLayoutAtomB = decltype(detail::rs_smem_selector<GmmaMajorB, MmaElementB,
      decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), IsWarpSpecializedTransposeB>());

  static constexpr int PipelineStages = detail::compute_stage_count_or_override<
      detail::sm90_smem_capacity_bytes, MmaElementA, MmaElementB, TileShape_MNK>(StageCountType{});

  using DispatchPolicy = MainloopSm90CpAsyncGmmaRmemAWarpSpecialized<
      PipelineStages, ClusterShape_MNK, KernelScheduleType>;

  using SmemCopyAtomA = cute::conditional_t<SwapAB, void, Copy_Atom<cute::DefaultCopy, ElementA>>;
  using SmemCopyAtomB = cute::conditional_t<SwapAB, Copy_Atom<cute::DefaultCopy, ElementB>, void>;

  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      TagToStrideA_t<GmemLayoutA>,
      ElementB,
      TagToStrideB_t<GmemLayoutB>,
      TiledMma,
      GmemTiledCopyA,
      SmemLayoutAtomA,
      SmemCopyAtomA,
      cute::identity,
      GmemTiledCopyB,
      SmemLayoutAtomB,
      SmemCopyAtomB,
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA auto kernel schedule
template <
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<cute::is_same_v<KernelScheduleType, KernelScheduleAuto>>
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA> == 0, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif

static constexpr bool IsTmaCompatible = detail::is_aligned<
    ElementA, AlignmentA, ElementB, AlignmentB, detail::tma_alignment_bytes>();

static constexpr bool IsMixedWidthInput = cute::sizeof_bits_v<ElementA> != cute::sizeof_bits_v<ElementB>;

#if ((__CUDACC_VER_MAJOR__ > 12) || ((__CUDACC_VER_MAJOR__ == 12) && (__CUDACC_VER_MINOR__ >= 1)))
  // Persistent schedules perform best for CUDA Toolkits with version >= 12.1
  // KernelTmaWarpSpecializedCooperative requires TileShape_M to be at least 128
  using KernelTmaWarpSpecializedScheduleSameInput = cute::conditional_t<size<0>(TileShape_MNK{}) == Int<64>{},
      KernelTmaWarpSpecializedPingpong, KernelTmaWarpSpecializedCooperative>;

  using KernelTmaWarpSpecializedScheduleMixedInput = cute::conditional_t<size<0>(TileShape_MNK{}) == Int<64>{},
      KernelTmaWarpSpecializedPingpongMixedInput, KernelTmaWarpSpecializedCooperativeMixedInput>;

  using KernelTmaWarpSpecializedSchedule = cute::conditional_t<IsMixedWidthInput, KernelTmaWarpSpecializedScheduleMixedInput, KernelTmaWarpSpecializedScheduleSameInput>;
#else
  using KernelTmaWarpSpecializedSchedule = cute::conditional_t<IsMixedWidthInput, KernelTmaWarpSpecializedMixedInput, KernelTmaWarpSpecialized>;
#endif

  // Non-persistent schedule is a safer choice for CpAsync kernels due to register pressure
  using KernelCpAsyncWarpSpecializedSchedule = KernelCpAsyncWarpSpecialized;
  using KernelSchedule = cute::conditional_t<IsTmaCompatible, KernelTmaWarpSpecializedSchedule, KernelCpAsyncWarpSpecializedSchedule>;
  static_assert((cute::is_same_v<KernelSchedule, KernelTmaWarpSpecializedSchedule> && IsMixedWidthInput) || !IsMixedWidthInput, "Only TMA warp specialized kernels are supported for mixed width input.");
  using CollectiveOp = typename CollectiveBuilder<
      arch::Sm90,
      arch::OpClassTensorOp,
      ElementA,
      GmemLayoutA,
      AlignmentA,
      ElementB,
      GmemLayoutB,
      AlignmentB,
      ElementAccumulator,
      TileShape_MNK,
      ClusterShape_MNK,
      StageCountType,
      KernelSchedule
    >::CollectiveOp;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
