/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

// CollectiveBuilder specialization for SM120 ptr-array (grouped GEMM) non-blockwise F8F6F4 MMA.
// Handles KernelPtrArrayTmaWarpSpecializedCooperativeSm120<N> and
//         KernelPtrArrayTmaWarpSpecializedPingpongSm120<N> schedule tags.

#pragma once

#include "cutlass/gemm/collective/builders/sm120_common.inl"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

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
  class BuilderScheduleTag
>
struct CollectiveBuilder<
    arch::Sm120,
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
    BuilderScheduleTag,
    cute::enable_if_t<
      not cute::is_tuple_v<ElementA> && not cute::is_tuple_v<ElementB> &&
      not cute::is_tuple_v<GmemLayoutATag> && not cute::is_tuple_v<GmemLayoutBTag> &&
      // Ptr-array (grouped GEMM) SM120 schedules without blockwise scaling.
      // Blockwise variant is handled by sm120_blockwise_mma_builder.inl (uses tuple layout tags).
      (cute::is_base_of_v<KernelPtrArrayTmaWarpSpecializedCooperative, BuilderScheduleTag> ||
       cute::is_base_of_v<KernelPtrArrayTmaWarpSpecializedPingpong, BuilderScheduleTag>) &&
      // Alignment check
      detail::sm1xx_gemm_is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, BuilderScheduleTag>()>>
{
  static_assert(detail::is_sm10x_f8f6f4_element<ElementA>() && detail::is_sm10x_f8f6f4_element<ElementB>(),
                "SM120 array TmaWarpSpecialized builder currently only supports F8F6F4 MMA.");
  static_assert(cute::is_static_v<TileShape_MNK>, "TileShape has to be static");
  static_assert(cute::is_static_v<ClusterShape_MNK>, "Cluster has to be static");
  static_assert(cute::size(ClusterShape_MNK{}) == Int<1>{}, "no programmatic multicast on this arch");

  static constexpr cute::UMMA::Major UmmaMajorA = cutlass::gemm::collective::detail::tag_to_umma_major_A<GmemLayoutATag>();
  static constexpr cute::UMMA::Major UmmaMajorB = cutlass::gemm::collective::detail::tag_to_umma_major_B<GmemLayoutBTag>();
  static_assert((UmmaMajorA == UMMA::Major::K && UmmaMajorB == UMMA::Major::K), "Only TN layout is supported.");

  using PermTileM = decltype(cute::min(size<0>(TileShape_MNK{}), _128{}));
  using PermTileN = decltype(cute::min(size<1>(TileShape_MNK{}),  _32{}));

  // Cooperative = 4x2 atom layout; Pingpong = 2x2
  static constexpr bool IsCooperative =
      cute::is_base_of_v<KernelPtrArrayTmaWarpSpecializedCooperative, BuilderScheduleTag>;
  using AtomLayoutMNK = cute::conditional_t<IsCooperative,
      Layout<Shape<_4,_2,_1>>, Layout<Shape<_2,_2,_1>>>;

  using ElementAMma = decltype(cutlass::gemm::collective::detail::sm1xx_kernel_input_element_to_mma_input_element<ElementA>());
  using ElementBMma = decltype(cutlass::gemm::collective::detail::sm1xx_kernel_input_element_to_mma_input_element<ElementB>());

  static_assert(detail::sm1xx_gemm_check_for_f8f6f4_mix8bit_requirement<ElementAMma, ElementBMma,
                                                                        TileShape_MNK, ClusterShape_MNK,
                                                                        GmemLayoutATag, GmemLayoutBTag, false /*IsSparse*/>(),
                "TileSize and MNK Major does not meet MMA Mix 8-bit TMA load requirement");

  using TiledMma = decltype(cute::make_tiled_mma(
    cute::rr_op_selector_sm120<ElementA, ElementB, ElementAccumulator>(),
    AtomLayoutMNK{},
    Tile<PermTileM, PermTileN, _32>{}
  ));

  static constexpr bool UseF8f6f4 = detail::is_sm120_f8f6f4<TiledMma, ElementA, ElementB>();
  static_assert(UseF8f6f4, "Non-blockscaled array collective builder only supports F8F6F4 MMA.\n");

  using SmemAllocTypeA = cute::conditional_t<UseF8f6f4, uint8_t, typename TiledMma::ValTypeA>;
  using SmemAllocTypeB = cute::conditional_t<UseF8f6f4, uint8_t, typename TiledMma::ValTypeB>;

  using GmemTiledCopyA = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<1>(ClusterShape_MNK{})));
  using GmemTiledCopyB = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));

  using SmemLayoutAtomA = decltype(detail::sm120_rr_smem_selector<SmemAllocTypeA, decltype(size<2>(TileShape_MNK{}))>());
  using SmemLayoutAtomB = decltype(detail::sm120_rr_smem_selector<SmemAllocTypeB, decltype(size<2>(TileShape_MNK{}))>());

  // Use PipelineTmaUmmaAsync<1> as size proxy for stage count calculation (same as dense builder)
  using MainloopPipelineStorage = typename cutlass::PipelineTmaUmmaAsync<1>::SharedStorage;

  static constexpr int PipelineStages = detail::sm100_compute_stage_count_or_override<
      detail::sm120_smem_capacity_bytes, SmemAllocTypeA,
      SmemAllocTypeB, TileShape_MNK, MainloopPipelineStorage>(StageCountType{});

  // SchedulerPipelineStageCount comes from the schedule tag (e.g. Sm120<2> → 2)
  static constexpr int SchedulerPipelineStageCount = BuilderScheduleTag::SchedulerPipelineStageCount;

  // Pass the schedule tag through directly so the kernel scheduler sees its exact type
  using KernelSchedule = BuilderScheduleTag;

  using DispatchPolicy = MainloopSm120ArrayTmaWarpSpecialized<PipelineStages,
                                                              SchedulerPipelineStageCount,
                                                              ClusterShape_MNK,
                                                              KernelSchedule>;

  using SmemCopyAtomA = Copy_Atom<decltype(detail::sm120_rr_smem_copy_selector_A<ElementA, ElementB, UseF8f6f4>()), SmemAllocTypeA>;
  using SmemCopyAtomB = Copy_Atom<decltype(detail::sm120_rr_smem_copy_selector_B<ElementA, ElementB, UseF8f6f4>()), SmemAllocTypeB>;

  // GmemLayoutATag is already a pointer type (e.g. RowMajor*) for ptr-array kernels;
  // TagToStrideA_t propagates the pointer, so no extra * needed here.
  using StrideA = TagToStrideA_t<GmemLayoutATag>;
  using StrideB = TagToStrideB_t<GmemLayoutBTag>;

  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      StrideA,
      ElementB,
      StrideB,
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

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
