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

#include "cutlass/gemm/collective/builders/sm90_common.inl"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/pipeline/sm90_pipeline.hpp"
#include "cutlass/gemm/collective/collective_mma_decl.hpp"
#include "cutlass/gemm/collective/collective_builder_decl.hpp"
#include "cute/arch/cluster_sm90.hpp"
#include "cute/tensor.hpp"
#include "cutlass/gemm/collective/collective_builder.hpp"

#include "dispatch_policy_extra.hpp"
#include "sm90_mma_tma_gmma_ss_warpspecialized_dual.hpp"

// SM90 Collective Builders should be used only starting CUDA 12.0
#if (__CUDACC_VER_MAJOR__ >= 12)
#define CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

template <
  class ArchTag,
  class OpClass,
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB0,
  class GmemLayoutB1,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType,
  class Enable = void
>
struct DualCollectiveBuilder {
  static_assert(sizeof(ElementA) == 0,
    "DualCollectiveBuilder: unsupported configuration.");
};

// GMMA_TMA_WS_SS
template <
  class ElementA,
  class GmemLayoutATag,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB0Tag,
  class GmemLayoutB1Tag,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct DualCollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutATag,
    AlignmentA,
    ElementB,
    GmemLayoutB0Tag,
    GmemLayoutB1Tag,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      cute::is_same_v<KernelScheduleType, DualKernelTmaWarpSpecializedCooperative>>
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA>, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif
  static_assert(detail::is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, detail::tma_alignment_bytes>(),
                "Should meet TMA alignment requirement\n");

  static constexpr bool IsArrayOfPointersGemm = (cute::is_any_of_v<KernelScheduleType,
                                                                   KernelPtrArrayTmaWarpSpecializedCooperative,
                                                                   KernelPtrArrayTmaWarpSpecializedPingpong>);
  static constexpr bool IsFP8Input = detail::is_input_fp8<ElementA, ElementB>();

  // For fp32 types, map to tf32 MMA value type
  using ElementAMma = cute::conditional_t<cute::is_same_v<ElementA, float>, tfloat32_t, ElementA>;
  using ElementBMma = cute::conditional_t<cute::is_same_v<ElementB, float>, tfloat32_t, ElementB>;

  static constexpr cute::GMMA::Major GmmaMajorA = detail::gmma_ss_tag_to_major_A<ElementAMma, GmemLayoutATag>();
  static constexpr cute::GMMA::Major GmmaMajorB0 = detail::gmma_ss_tag_to_major_B<ElementBMma, GmemLayoutB0Tag>();
  static constexpr cute::GMMA::Major GmmaMajorB1 = detail::gmma_ss_tag_to_major_B<ElementBMma, GmemLayoutB1Tag>();

  static constexpr bool IsCooperative = cute::is_any_of_v<KernelScheduleType,
                                                          DualKernelTmaWarpSpecializedCooperative,
                                                          KernelPtrArrayTmaWarpSpecializedCooperative>;
  using AtomLayoutMNK = cute::conditional_t<IsCooperative,
      Layout<Shape<_2,_1,_1>>, Layout<Shape<_1,_1,_1>>>;

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::ss_op_selector<
      ElementAMma, ElementBMma, ElementAccumulator, TileShape_MNK, GmmaMajorA, GmmaMajorB0>(), AtomLayoutMNK{}));

  using GmemTiledCopyA = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<1>(ClusterShape_MNK{})));
  using GmemTiledCopyB0 = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));
  using GmemTiledCopyB1 = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));

  using SmemLayoutAtomA = decltype(detail::ss_smem_selector<
      GmmaMajorA, ElementAMma, decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());
  using SmemLayoutAtomB0 = decltype(detail::ss_smem_selector<
      GmmaMajorB0, ElementBMma, decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());
  using SmemLayoutAtomB1 = decltype(detail::ss_smem_selector<
      GmmaMajorB1, ElementBMma, decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  static constexpr size_t TensorMapStorage = IsArrayOfPointersGemm ? sizeof(cute::TmaDescriptor) * 2 /* for A and B */ : 0;
  static constexpr size_t SchedulerPipelineStorage = cute::is_pointer_v<TagToStrideA_t<GmemLayoutATag>> ? 
      sizeof(cutlass::PipelineDetail::PipelineAsyncSharedStorage<8>) : 0;
  static constexpr int KernelSmemCarveout = static_cast<int>(TensorMapStorage + SchedulerPipelineStorage);
  static constexpr int Sm90ReducedSmemCapacityBytes = detail::sm90_smem_capacity_bytes - KernelSmemCarveout;

  static constexpr int PipelineStages = detail::compute_stage_count_or_override<Sm90ReducedSmemCapacityBytes,
      ElementAMma, ElementBMma, TileShape_MNK>(StageCountType{});
  /* For FP8 use a separate mainloop compared to other datatypes */
  using DispatchPolicy = cute::conditional_t<IsArrayOfPointersGemm,
      cute::conditional_t<IsFP8Input,
          MainloopSm90ArrayTmaGmmaWarpSpecializedFP8<PipelineStages, ClusterShape_MNK, KernelScheduleType>,
          MainloopSm90ArrayTmaGmmaWarpSpecialized<PipelineStages, ClusterShape_MNK, KernelScheduleType>
      >,
      cute::conditional_t<IsFP8Input,
          MainloopSm90TmaGmmaWarpSpecializedFP8<PipelineStages, ClusterShape_MNK, KernelScheduleType>,
          DualMainloopSm90TmaGmmaWarpSpecialized<PipelineStages, ClusterShape_MNK, KernelScheduleType>
      >
  >;

  using SmemCopyAtomA = void;
  using SmemCopyAtomB0 = void;
  using SmemCopyAtomB1 = void;

  using CollectiveOp = DualCollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      TagToStrideA_t<GmemLayoutATag>,
      ElementB,
      TagToStrideB_t<GmemLayoutB0Tag>,
      TagToStrideB_t<GmemLayoutB1Tag>,
      TiledMma,
      GmemTiledCopyA,
      SmemLayoutAtomA,
      SmemCopyAtomA,
      cute::identity,
      GmemTiledCopyB0,
      SmemLayoutAtomB0,
      SmemCopyAtomB0,
      cute::identity,
      GmemTiledCopyB1,
      SmemLayoutAtomB1,
      SmemCopyAtomB1,
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
