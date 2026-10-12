/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/gemm/collective/builders/sm107_common.inl"
#include "cutlass/gemm/collective/builders/sm100_pipeline_carveout.inl"
#include "cutlass/gemm/collective/builders/sm100_umma_builder.inl"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

template <class ElementA, class ElementB>
CUTLASS_HOST_DEVICE
static constexpr bool
sm107_check_input_datatypes() {
  auto is_f4f6f8_input = [&]() {
    // Allowed input element datatype for narrow precision GEMM
    return (
            (
              cute::is_same_v<ElementA, cutlass::type_erased_dynamic_float8_t> ||
              cute::is_same_v<ElementA, cutlass::type_erased_dynamic_float6_t> ||
              cute::is_same_v<ElementA, cutlass::type_erased_dynamic_float4_t>
            ) &&
            (
              cute::is_same_v<ElementB, cutlass::type_erased_dynamic_float8_t> ||
              cute::is_same_v<ElementB, cutlass::type_erased_dynamic_float6_t> ||
              cute::is_same_v<ElementB, cutlass::type_erased_dynamic_float4_t>
            )
           ) || 
           (
            (
              cute::is_same_v<ElementA, cutlass::float_e2m1_t> ||
              cute::is_same_v<ElementA, cutlass::float_e2m3_t> ||
              cute::is_same_v<ElementA, cutlass::float_e3m2_t> ||
              cute::is_same_v<ElementA, cutlass::float_e4m3_t> ||
              cute::is_same_v<ElementA, cutlass::float_e5m2_t>
            ) &&
            ( 
              cute::is_same_v<ElementB, cutlass::float_e2m1_t> ||
              cute::is_same_v<ElementB, cutlass::float_e2m3_t> ||
              cute::is_same_v<ElementB, cutlass::float_e3m2_t> ||
              cute::is_same_v<ElementB, cutlass::float_e4m3_t> ||
              cute::is_same_v<ElementB, cutlass::float_e5m2_t>
            )
           );
  };

  static_assert(is_f4f6f8_input(), "Unsupported data type for ElementA");

  return true;
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class ArchTag,
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
    ArchTag,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutATag,
    AlignmentA,
    ElementB,
    GmemLayoutBTag,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,    // (MmaAtomShapeM, MmaAtomShapeN, TileK)
    ClusterShape_MNK, // Static cluster shape or dynamic (int, int, _1)
    StageCountType,
    BuilderScheduleTag,
    cute::enable_if_t<
      cute::is_same_v<ArchTag, arch::Sm107> &&
      not cute::is_tuple_v<ElementA>   && not cute::is_tuple_v<ElementB> &&
      // Dense Gemm
      (
        cute::is_base_of_v<KernelScheduleSm107DenseGemmf8f6f4WithoutBreuse, BuilderScheduleTag> ||
        cute::is_base_of_v<KernelScheduleSm107DenseGemmf8f6f4WithBreuse, BuilderScheduleTag>
      ) &&
      // Alignment check
      detail::sm1xx_gemm_is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, BuilderScheduleTag>()>>
{
  static_assert(cute::is_static_v<TileShape_MNK>, "TileShape has to be static");
  static_assert(detail::sm107_check_input_datatypes<ElementA, ElementB>(), "Incorrect input types");

  static constexpr cute::UMMA::Major UmmaMajorA = cutlass::gemm::collective::detail::tag_to_umma_major_A<GmemLayoutATag>();
  static constexpr cute::UMMA::Major UmmaMajorB = cutlass::gemm::collective::detail::tag_to_umma_major_B<GmemLayoutBTag>();

  // Data type used by MMA instruction
  using ElementAMma = decltype(cutlass::gemm::collective::detail::sm1xx_kernel_input_element_to_mma_input_element<ElementA>());
  using ElementBMma = decltype(cutlass::gemm::collective::detail::sm1xx_kernel_input_element_to_mma_input_element<ElementB>());

  static constexpr bool is_2sm = cute::is_base_of_v<KernelSchedule2Sm, BuilderScheduleTag> ||
                        (not cute::is_base_of_v<KernelSchedule1Sm, BuilderScheduleTag> &&
                          not cute::is_base_of_v<KernelSchedule2Sm, BuilderScheduleTag> &&
                          cute::is_static_v<ClusterShape_MNK> &&
                          cute::get<0>(ClusterShape_MNK{}) % 2 == 0 );


  static constexpr bool WithBreuse =
      cute::is_base_of_v<KernelScheduleSm107DenseGemmf8f6f4WithBreuse, BuilderScheduleTag>
      ? true : false;

  using TiledMma = decltype(detail::sm107_make_trivial_tiled_mma<
      ElementAMma, ElementBMma, ElementAccumulator,
      decltype(cute::product_each(TileShape_MNK{})), ClusterShape_MNK,
      UmmaMajorA, UmmaMajorB, BuilderScheduleTag, WithBreuse>());

  using ElementAMma_SmemAllocType = cute::conditional_t<cute::sizeof_bits_v<ElementAMma> < 8, uint8_t, ElementAMma>;
  using ElementBMma_SmemAllocType = cute::conditional_t<cute::sizeof_bits_v<ElementBMma> < 8, uint8_t, ElementBMma>;

  using AtomThrID = typename TiledMma::AtomThrID;

  using AtomThrShapeMNK = cute::Shape<decltype(cute::shape<0>(typename TiledMma::ThrLayoutVMNK{})), _1, _1>;
  using CtaTileShape_MNK = decltype(cute::shape_div(TileShape_MNK{}, AtomThrShapeMNK{}));

  // ((MMA_TILE_M,MMA_TILE_K), MMA_M, MMA_K)
  using MmaShapeA_MK = decltype(partition_shape_A(TiledMma{}, make_shape(cute::size<0>(TileShape_MNK{}),
                                                                         cute::size<2>(TileShape_MNK{}))));
  // ((MMA_TILE_N,MMA_TILE_K), MMA_N, MMA_K)
  using MmaShapeB_NK = decltype(partition_shape_B(TiledMma{}, make_shape(cute::size<1>(TileShape_MNK{}),
                                                                         cute::size<2>(TileShape_MNK{}))));

  using BlockTileA_M = decltype(cute::size<0,0>(MmaShapeA_MK{}) * cute::size<1>(MmaShapeA_MK{}));
  using BlockTileA_K = decltype(cute::size<0,1>(MmaShapeA_MK{}) * cute::size<2>(MmaShapeA_MK{}));
  using BlockTileB_N = decltype(cute::size<0,0>(MmaShapeB_NK{}) * cute::size<1>(MmaShapeB_NK{}));
  using BlockTileB_K = decltype(cute::size<0,1>(MmaShapeB_NK{}) * cute::size<2>(MmaShapeB_NK{}));

  // Right divide TileShape_M/N by 1SM/2SM
  // Future work: fix partition_shape to account for hierarchies and
  // contiguity so we can pass BlockTileA/B to sm100_smem_selector instead
  using SmemShape_M = decltype(shape_div(shape<0>(TileShape_MNK{}), shape_div(shape<0>(TileShape_MNK{}), size<0>(TileShape_MNK{}) / size(AtomThrID{}))));
  using SmemShape_N = decltype(shape_div(shape<1>(TileShape_MNK{}), shape_div(shape<1>(TileShape_MNK{}), size<1>(TileShape_MNK{}) / size(AtomThrID{}))));
  using SmemShape_K = decltype(cute::get<2>(TileShape_MNK{}));

  using GmemTiledCopyA = decltype(cutlass::gemm::collective::detail::sm100_cluster_shape_to_tma_atom_A(
    ClusterShape_MNK{}, AtomThrID{}));
  using GmemTiledCopyB = decltype(cutlass::gemm::collective::detail::sm100_cluster_shape_to_tma_atom_B(
      ClusterShape_MNK{}, AtomThrID{}));

  using SmemLayoutAtomA = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      UmmaMajorA, ElementAMma_SmemAllocType, SmemShape_M, SmemShape_K>());
  using SmemLayoutAtomB = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      UmmaMajorB, ElementBMma_SmemAllocType, SmemShape_N, SmemShape_K>());
  static constexpr uint32_t TotalTmemRows = 128;
  static constexpr uint32_t Sm107TmemCapacityColumns = cutlass::arch::Sm107::kTmemCapacityColumns;
  static constexpr uint32_t TotalTmem = TotalTmemRows * Sm107TmemCapacityColumns;
  static constexpr uint32_t AccumulatorPipelineStageCount_ = TotalTmem / (cute::size<0>(CtaTileShape_MNK{}) * cute::size<1>(CtaTileShape_MNK{}));
  // 4 accumulator stages works well to buffer the accumulators, while also preventing overhead in the epilogue tail on small tile sizes.
  static constexpr uint32_t AccumulatorPipelineStageCount = cute::min(4u, AccumulatorPipelineStageCount_);                                              // Cap at 4 accumulator stages
  static_assert(AccumulatorPipelineStageCount > 0, "Accumulator pipeline stage count must be positive.  This error probably means that TileShape_MNK and/or TiledMma::ThrLayoutVMNK are wrong.");

  // Calculate scheduler pipeline stages. Having one more stage than the accumulator allows more latency hiding.
  using StrideA = cutlass::gemm::TagToStrideA_t<GmemLayoutATag>;
  using StrideB = cutlass::gemm::TagToStrideB_t<GmemLayoutBTag>;
  using InternalStrideA  = cute::remove_pointer_t<StrideA>;
  using InternalStrideB  = cute::remove_pointer_t<StrideB>;

  static constexpr bool IsArrayOfPointersGemm = false;
  static constexpr bool IsGroupGemm = false;
  static constexpr bool IsRCGroupGemm = false;

  static constexpr uint32_t SchedulerPipelineStageCount = cute::conditional_return<IsGroupGemm || IsRCGroupGemm>(8, 2);

  static constexpr uint32_t KernelSmemCarveout = detail::Sm100DenseGemmTmaUmmaCarveout<
      ClusterShape_MNK,
      AccumulatorPipelineStageCount,
      SchedulerPipelineStageCount,
      detail::CLCResponseSize,
      IsArrayOfPointersGemm
    >::KernelSmemCarveout;
  // Reduce SMEM capacity available for buffers considering barrier allocations.
  static constexpr int ReducedSmemCapacityBytes = detail::sm100_reduced_smem_capacity_bytes<ArchTag, KernelSmemCarveout>();

  using SmemTileShape = cute::Shape<BlockTileA_M, BlockTileB_N, BlockTileA_K>;
  using MainloopPipelineStorage = typename cutlass::PipelineTmaUmmaAsync<1>::SharedStorage;

  static constexpr int PipelineStages = cutlass::gemm::collective::detail::sm100_compute_stage_count_or_override<
      ReducedSmemCapacityBytes, ElementAMma_SmemAllocType, ElementBMma_SmemAllocType, SmemTileShape, MainloopPipelineStorage>(StageCountType{});
  static_assert(PipelineStages > 0, "Smem usage is too high. Can't create any SMEM buffers for A, and B.");

  using DispatchPolicy =
    cutlass::gemm::MainloopSm107TmaUmmaWarpSpecialized<
          PipelineStages,
          SchedulerPipelineStageCount,
          AccumulatorPipelineStageCount,
          ClusterShape_MNK,
          WithBreuse,
          ArchTag
    >;

  using CollectiveOp = cutlass::gemm::collective::CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      cutlass::gemm::TagToStrideA_t<GmemLayoutATag>,
      ElementB,
      cutlass::gemm::TagToStrideB_t<GmemLayoutBTag>,
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

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
