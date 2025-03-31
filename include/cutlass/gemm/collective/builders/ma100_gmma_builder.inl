/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/gemm/collective/builders/ma100_common.inl"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/pipeline/sm90_pipeline.hpp"
#include "cutlass/gemm/collective/collective_mma_decl.hpp"
#include "cutlass/gemm/collective/collective_builder_decl.hpp"
#include "cute/arch/cluster_sm90.hpp"
#include "cute/tensor.hpp"

// SM90 Collective Builders should be used only starting CUDA 12.0
#if (__CUDACC_VER_MAJOR__ >= 12)
#define CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count.
template<int capacity_bytes, class ElementA, class ElementB, class TileShapeMNK, int stages, int alignment = 128>
constexpr int
compute_stage_count_or_override(StageCount<stages> stage_count) {
  return stages;
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count.
template<int capacity_bytes, class ElementA, class ElementB, class TileShapeMNK, int stages, int alignment = 128>
constexpr int
compute_stage_count_or_override(cute::Int<stages> stage_count) {
  return stages;
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count.
template<int capacity_bytes_, class ElementA, class ElementB, class TileShapeMNK, int carveout_bytes_, int alignment = 128>
constexpr int
compute_stage_count_or_override(StageCountAutoCarveout<carveout_bytes_> stage_count) {
  constexpr auto mainloop_pipeline_bytes = sizeof(typename cutlass::PipelineTmaAsync<1>::SharedStorage);
  constexpr auto a_bits = cute::sizeof_bits_v<ElementA>;
  constexpr auto b_bits = cute::sizeof_bits_v<ElementB>;
  constexpr int stage_bytes_ =
    cutlass::bits_to_bytes(a_bits * size<0>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    cutlass::bits_to_bytes(b_bits * size<1>(TileShapeMNK{}) * size<2>(TileShapeMNK{}));

  constexpr int stage_bytes = cutlass::round_up(stage_bytes_, alignment) +
    static_cast<int>(mainloop_pipeline_bytes);
  constexpr int carveout_bytes = cutlass::round_up(carveout_bytes_, alignment);
  constexpr int capacity_bytes = capacity_bytes_ / alignment * alignment;

  return (capacity_bytes - carveout_bytes) / stage_bytes;
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity (with an optional scale matrix), or overrides with manual count.
template<int capacity_bytes, class ElementA, class ElementB, class ElementScale, class ElementZero, class TileShapeMNK, int stages, int alignment = 128>
constexpr int
compute_stage_count_or_override_single_affine_transformed_input(StageCount<stages> stage_count) {
  return stages;
}

template <class Element>
constexpr int get_bits_for_possibly_void_element() {
  if constexpr (cute::is_same_v<Element, void>) {
    return 0;
  }
  else {
    return sizeof_bits<Element>::value;
  }
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity (with an optional scale matrix), or overrides with manual count.
template<int capacity_bytes_, class ElementA, class ElementB, class ElementScale, class ElementZero, class TileShapeMNK, int carveout_bytes_, int alignment = 128>
constexpr int
compute_stage_count_or_override_single_affine_transformed_input(StageCountAutoCarveout<carveout_bytes_> stage_count) {

  // 32 bytes to account for barriers etc.
  constexpr auto mainloop_pipeline_bytes = sizeof(typename cutlass::PipelineTmaAsync<1>::SharedStorage);
  constexpr int scale_zero_k_tile = 1;
  constexpr auto a_bits = cute::sizeof_bits_v<ElementA>;
  constexpr auto b_bits = cute::sizeof_bits_v<ElementB>;
  constexpr auto s_bits = get_bits_for_possibly_void_element<ElementScale>();
  constexpr auto z_bits = get_bits_for_possibly_void_element<ElementZero>();

  constexpr auto scale_bytes = cutlass::bits_to_bytes(s_bits * size<0>(TileShapeMNK{}) * scale_zero_k_tile);
  constexpr auto zero_bytes  = cutlass::bits_to_bytes(z_bits * size<0>(TileShapeMNK{}) * scale_zero_k_tile);
  static_assert(scale_bytes % 128 == 0, "Scale bytes must be a multiple of 128");
  static_assert(zero_bytes  % 128 == 0, "Zero bytes must be a multiple of 128");

  // When scales are void, s_bits will be 0 so no smem will be allocated for scales.
  constexpr int stage_bytes_ =
    cutlass::bits_to_bytes(a_bits * size<0>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    cutlass::bits_to_bytes(b_bits * size<1>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    scale_bytes + zero_bytes;

  constexpr int stage_bytes = cutlass::round_up(stage_bytes_, alignment) +
    static_cast<int>(mainloop_pipeline_bytes);
  constexpr int carveout_bytes = cutlass::round_up(carveout_bytes_, alignment);
  constexpr int capacity_bytes = capacity_bytes_ / alignment * alignment;

  return (capacity_bytes - carveout_bytes) / stage_bytes;
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
  // constexpr bool IsWarpSpecialized = cute::is_base_of_v<KernelTmaWarpSpecialized, KernelScheduleType>                ||
  //                                    cute::is_base_of_v<KernelTmaWarpSpecializedPingpong, KernelScheduleType>        ||
  //                                    cute::is_base_of_v<KernelTmaWarpSpecializedCooperative, KernelScheduleType>     ||
  //                                    cute::is_base_of_v<KernelCpAsyncWarpSpecialized, KernelScheduleType>            ||
  //                                    cute::is_base_of_v<KernelCpAsyncWarpSpecializedPingpong, KernelScheduleType>    ||
  //                                    cute::is_base_of_v<KernelCpAsyncWarpSpecializedCooperative, KernelScheduleType>;
  constexpr bool IsWarpSpecialized = false;
  constexpr bool IsWarpSpecializedTransposeB = !IsInputSizeTwoBytes && IsLayoutAmnBmn && IsWarpSpecialized;
  return IsWarpSpecializedTransposeB;
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_CpAsync_WS_RS
template <
  class ElementA,
  class GmemLayoutATag,
  int   AlignmentA,
  class ElementB,
  class GmemLayoutBTag,
  int   AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Ma100,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutATag,
    AlignmentA,
    ElementB,
    GmemLayoutBTag,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      (cute::is_same_v<KernelScheduleType, KernelCooperative>)
    >
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);

  // For fp32 types, map to tf32 MMA value type
  using ElementAMma = cute::conditional_t<cute::is_same_v<ElementA, float>, bfloat16_t, ElementA>;
  using ElementBMma = cute::conditional_t<cute::is_same_v<ElementB, float>, bfloat16_t, ElementB>;

  static_assert(detail::is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, detail::cp_async_min_alignment_bytes>(),
                "Minimum alignment required for cp.async is 4B.");

  static constexpr cute::GMMA::Major GmmaMajorA = detail::gmma_aurora_tag_to_major_A<GmemLayoutATag>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::gmma_aurora_tag_to_major_B<GmemLayoutBTag>();
  static constexpr bool SwapAB = detail::is_swapAB<ElementA, GmemLayoutATag, ElementB, GmemLayoutBTag>();
  // static constexpr bool IsWarpSpecializedTransposeB = detail::is_warpspecialized_transpose_B<
  //     ElementA, GmemLayoutATag, ElementB, GmemLayoutBTag, KernelScheduleType>();
  // static_assert(GmmaMajorA == GMMA::Major::MN,  "GmmaMajorA == GMMA::Major::K");
  // static_assert(GmmaMajorB == GMMA::Major::MN,  "GmmaMajorB == GMMA::Major::K");
  static_assert(GmmaMajorB == GMMA::Major::K,  "GmmaMajorB == GMMA::Major::MN");
  static_assert(GmmaMajorA == GMMA::Major::K,  "GmmaMajorA == GMMA::Major::MN");


  using AtomLayoutMNK = cute::conditional_t<cute::is_same_v<KernelScheduleType, KernelCooperative>,
      Layout<Shape<cute::Int<(size<0>(TileShape_MNK{}) < 128) ? 1 : 2>,_1,_1>>, Layout<Shape<_1,_1,_1>>>;

  //way1:
   // using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::aurora_ss_op_selector<
   //     ElementAMma, ElementBMma, ElementAccumulator, TileShape_MNK, GMMA::Major::K, GMMA::Major::K>(), AtomLayoutMNK{}));
   
   //way2:
   using TiledMma = decltype(cute::make_tiled_mma(cute::AMMA::aurora_ss_op_selector<
    ElementAMma, ElementBMma, ElementAccumulator, TileShape_MNK, AMMA::Major::K, AMMA::Major::K>(), AtomLayoutMNK{}));

  //way3:
  // using TiledMma = decltype(cute::make_tiled_mma(Aurora_64x64x16_F16F16F16_SS<AMMA::Major::K,AMMA::Major::K>{}));
  
  // static constexpr int NumLoadWarpGroups = 1;

  // using AlignmentTypeA = cute::uint_byte_t<static_cast<int>(sizeof(ElementA)) * AlignmentA>;
  // using GmemCopyAtomA = cute::Copy_Atom<SM80_CP_ASYNC_CACHEALWAYS_ZFILL<AlignmentTypeA>, ElementA>;
  // using GmemTiledCopyA = decltype(detail::make_simt_gmem_tiled_copy<
  //     GmemCopyAtomA, NumThreadsPerWarpGroup * NumLoadWarpGroups, AlignmentA, TagToStrideA_t<GmemLayoutATag>,
  //     decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  // using AlignmentTypeB = cute::uint_byte_t<static_cast<int>(sizeof(ElementB)) * AlignmentB>;
  // using GmemCopyAtomB = cute::Copy_Atom<SM80_CP_ASYNC_CACHEALWAYS_ZFILL<AlignmentTypeB>, ElementB>;
  // using GmemTiledCopyB = decltype(detail::make_simt_gmem_tiled_copy<
  //     GmemCopyAtomB, NumThreadsPerWarpGroup * NumLoadWarpGroups, AlignmentB, TagToStrideB_t<GmemLayoutBTag>,
  //     decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  // using SmemLayoutAtomA = decltype(detail::rs_smem_selector<GmmaMajorA, ElementAMma,
  //     decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), IsWarpSpecializedTransposeB>());
  // using SmemLayoutAtomB = decltype(detail::rs_smem_selector<GmmaMajorB, ElementBMma,
  //     decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), IsWarpSpecializedTransposeB>());
  // static_assert(false,  "before SmemLayoutAtomA");
  static_assert(cute::size(shape<0>(ClusterShape_MNK{})) == 1,  "cute::size(shape<0>(ClusterShape_MNK{})) != 1");
  // A loads can be optimized with multicast if cluster-n > 1
  using GmemTiledCopyA = cute::conditional_t< cute::size(shape<1>(ClusterShape_MNK{})) == 1,
                           cute::SMA_DMA_LOAD,
                           cute::SMA_DMA_LOAD>;

  // B loads can be optimized with multicast if cluster-m > 1
  using GmemTiledCopyB = cute::conditional_t< cute::size(shape<0>(ClusterShape_MNK{})) == 1,
                           cute::SMA_DMA_LOAD,
                           cute::SMA_DMA_LOAD>;
  using SmemLayoutAtomA = decltype(detail::ss_smem_selector<GmmaMajorA, ElementAMma,
      decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());
  // static_assert(false,  "after SmemLayoutAtomA");
  using SmemLayoutAtomB = decltype(detail::ss_smem_selector<GmmaMajorB, ElementBMma,
      decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());
  // static_assert(false,  "after SmemLayoutAtomB");

  // static constexpr int PipelineStages = detail::compute_stage_count_or_override<
  //     detail::sm90_smem_capacity_bytes, ElementAMma, ElementBMma, TileShape_MNK>(StageCountType{});
  static constexpr int PipelineStages = 2;

  using DispatchPolicy = MainloopMa100Cooperative<
      PipelineStages, ClusterShape_MNK, KernelScheduleType>;

  // using SmemCopyAtomA = cute::conditional_t<SwapAB, void, Copy_Atom<cute::AutoVectorizingCopy, ElementA>>;
  // using SmemCopyAtomB = cute::conditional_t<SwapAB, Copy_Atom<cute::AutoVectorizingCopy, ElementB>, void>;
  using SmemCopyAtomA = void; // Does not need a SmemCopyAtom, since A is read directly from SMEM
  using SmemCopyAtomB = void;

  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      TagToStrideA_t<GmemLayoutATag>,
      ElementB,
      TagToStrideB_t<GmemLayoutBTag>,
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
  class GmemLayoutATag,
  int AlignmentA,
  class ElementB,
  class GmemLayoutBTag,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Ma100,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutATag,
    AlignmentA,
    ElementB,
    GmemLayoutBTag,
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

  // static_assert(cutlass::detail::dependent_false<ElementA>, "Unsupported Toolkit for Ma100 Collective Builder\n");


  using ExtractedElementA = detail::deduce_mixed_width_dtype_t<0, ElementA>;
  using ExtractedElementB = detail::deduce_mixed_width_dtype_t<0, ElementB>;

  // static constexpr bool IsCooperativeCompatible = detail::is_aligned<
  //     ExtractedElementA, AlignmentA, ExtractedElementB, AlignmentB, detail::tma_alignment_bytes>();
  static constexpr bool IsCooperativeCompatible = true;            // is C mode or N mode

  // Users opt into scales via the builder by passing a tuple of Elements for the input that will be scaled. We detect
  // scale support if ONLY one of the inputs have tuples to describe them.
  static constexpr bool OnlyOneIsTuple = cute::is_tuple<ElementA>::value ^ cute::is_tuple<ElementB>::value;
  static constexpr bool IsDifferentWidth = sizeof_bits<ExtractedElementA>::value != sizeof_bits<ExtractedElementB>::value;
  static constexpr bool IsMixedWidthInput = IsDifferentWidth || (IsDifferentWidth && OnlyOneIsTuple);

// #if ((__CUDACC_VER_MAJOR__ > 12) || ((__CUDACC_VER_MAJOR__ == 12) && (__CUDACC_VER_MINOR__ >= 1)))
//   // Persistent schedules perform best for CUDA Toolkits with version >= 12.1
//   // KernelTmaWarpSpecializedCooperative requires TileShape_M to be at least 128
//   using KernelTmaWarpSpecializedSchedule = cute::conditional_t<size<0>(TileShape_MNK{}) == Int<64>{},
//       KernelTmaWarpSpecializedPingpong, KernelTmaWarpSpecializedCooperative>;
// #else
//   using KernelTmaWarpSpecializedSchedule = KernelTmaWarpSpecialized;
// #endif
  using KernelCooperativeSchedule = KernelCooperative;

  // Non-persistent schedule is a safer choice for CpAsync kernels due to register pressure
  using KernelNmodeSchedule = KernelCooperative;
  using KernelSchedule = cute::conditional_t<IsCooperativeCompatible, KernelCooperativeSchedule, KernelNmodeSchedule>;
  static_assert((cute::is_same_v<KernelSchedule, KernelCooperativeSchedule> && IsMixedWidthInput) || !IsMixedWidthInput, "Only TMA warp specialized kernels are supported for mixed width input.");
  using CollectiveOp = typename CollectiveBuilder<
      arch::Ma100,
      arch::OpClassTensorOp,
      ElementA,
      GmemLayoutATag,
      AlignmentA,
      ElementB,
      GmemLayoutBTag,
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

