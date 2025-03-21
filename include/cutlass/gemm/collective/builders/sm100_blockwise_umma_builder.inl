/***************************************************************************************************
 * Copyright (c) 2025 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass/gemm/collective/builders/sm100_common.inl"
#include "cutlass/gemm/collective/builders/sm100_pipeline_carveout.inl"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<
  int CapacityBytes,
  class ElementA,
  class ElementB,
  class ElementScalar,
  class ScaleShapeMNK,
  class TileShapeMNK,
  class MainloopPipelineStorage,
  class TransformLoadPipelineStorage,
  class TransformPipelineStorage,
  int stages
>
constexpr int
sm100_compute_stage_count_or_override_blockwise(StageCount<stages> stage_count) {
  return stages;
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<
  int CapacityBytes,
  class ElementA,
  class ElementB,
  class ElementScalar,
  class ScaleShapeMNK,
  class TileShapeMNK,
  class MainloopPipelineStorage,
  class TransformLoadPipelineStorage,
  class TransformPipelineStorage,
  int stages
>
constexpr int
sm100_compute_stage_count_or_override_blockwise(cute::Int<stages> stage_count) {
  return stages;
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<
  int CapacityBytes,
  class ElementA,
  class ElementB,
  class ElementScalar,
  class ScaleShapeMNK,
  class TileShapeMNK,
  class MainloopPipelineStorage,
  class TransformLoadPipelineStorage,
  class TransformPipelineStorage,
  int carveout_bytes>
constexpr int
sm100_compute_stage_count_or_override_blockwise(StageCountAutoCarveout<carveout_bytes> stage_count) {
  // For F8/F6/F4 sub-bytes, ElementA/B will be passed in as uint8_t
  // For Planar Complex, ElementA/B will be passed in as cutlass::complex<ElementARaw>
  // Each stage include (CollectiveMma::SharedStorage)
  // 1. smem for A and smem for B (CollectiveMma::SharedStorage::TensorStorage)
  // 2. one of each of the pipelines
  constexpr auto pipeline_bytes = sizeof(MainloopPipelineStorage) + 
      sizeof(TransformLoadPipelineStorage) + sizeof(TransformPipelineStorage);

  constexpr auto a_bits = cute::sizeof_bits_v<ElementA>;
  constexpr auto b_bits = cute::sizeof_bits_v<ElementB>;
  constexpr auto scale_bits = cute::sizeof_bits_v<ElementScalar>;

  constexpr int stage_bytes =
    cutlass::bits_to_bytes(a_bits * size<0>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    cutlass::bits_to_bytes(b_bits * size<1>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    cutlass::bits_to_bytes(scale_bits * size<0>(ScaleShapeMNK{}) * size<2>(ScaleShapeMNK{})) +
    cutlass::bits_to_bytes(scale_bits * size<1>(ScaleShapeMNK{}) * size<2>(ScaleShapeMNK{})) +
    static_cast<int>(pipeline_bytes);

  return (CapacityBytes - carveout_bytes) / stage_bytes;
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class ElementA,
  class GmemLayoutATagPair,
  int AlignmentA,
  class ElementB,
  class GmemLayoutBTagPair,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm100,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutATagPair,
    AlignmentA,
    ElementB,
    GmemLayoutBTagPair,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,    // (MmaAtomShapeM, MmaAtomShapeN, TileK)
    ClusterShape_MNK, // Static cluster shape or dynamic (int, int, _1)
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      not cute::is_tuple_v<ElementA>   && not cute::is_tuple_v<ElementB> &&
      not cute::is_complex_v<ElementA> && not cute::is_complex_v<ElementB> &&
      cute::is_tuple_v<GmemLayoutATagPair>   && cute::is_tuple_v<GmemLayoutBTagPair> &&
      // Dense Gemm
      cute::is_base_of_v<KernelScheduleSm100Blockwise, KernelScheduleType> &&
      // Alignment check
      detail::sm1xx_gemm_is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, KernelScheduleType>()>>
{
  static_assert(cute::is_static_v<TileShape_MNK>, "TileShape has to be static");
  static_assert(detail::check_input_datatypes<ElementA, ElementB>(), "Incorrect input types");

  using GmemLayoutATag   = cute::remove_cvref_t<decltype(get<0>(GmemLayoutATagPair{}))>;
  using GmemLayoutSFATag = cute::remove_cvref_t<decltype(get<1>(GmemLayoutATagPair{}))>;
  using GmemLayoutBTag   = cute::remove_cvref_t<decltype(get<0>(GmemLayoutBTagPair{}))>;
  using GmemLayoutSFBTag = cute::remove_cvref_t<decltype(get<1>(GmemLayoutBTagPair{}))>;

  static_assert(cute::depth(GmemLayoutSFATag{}) == 2 and cute::depth(GmemLayoutSFBTag{}) == 2, 
      "Expect SFA and SFB layout to be depth of two with shape ((SFVecMN, restMN),(SFVecK, restK), L)");
  static_assert(size<1,0>(GmemLayoutSFATag{}) == size<1, 0>(GmemLayoutSFBTag{}), 
      "SFA and SFB must have equivalent SF vector sizes along K");

  static constexpr cute::UMMA::Major UmmaMajorA = cutlass::gemm::collective::detail::tag_to_umma_major_A<GmemLayoutATag>();
  static constexpr cute::UMMA::Major UmmaMajorB = cutlass::gemm::collective::detail::tag_to_umma_major_B<GmemLayoutBTag>();

  // Data type used by MMA instruction
  using ElementAMma = decltype(cutlass::gemm::collective::detail::sm100_kernel_input_element_to_mma_input_element<ElementA>());
  using ElementBMma = decltype(cutlass::gemm::collective::detail::sm100_kernel_input_element_to_mma_input_element<ElementB>());

  static constexpr bool is_2sm = cute::is_base_of_v<KernelSchedule2Sm, KernelScheduleType> ||
                        (not cute::is_base_of_v<KernelSchedule1Sm, KernelScheduleType> &&
                          not cute::is_base_of_v<KernelSchedule2Sm, KernelScheduleType> &&
                          cute::is_static_v<ClusterShape_MNK> &&
                          cute::get<0>(ClusterShape_MNK{}) % 2 == 0 );

  static_assert(detail::sm100_gemm_check_for_f8f6f4_mix8bit_requirement<ElementAMma, ElementBMma,
                                                                      TileShape_MNK, ClusterShape_MNK,
                                                                      UmmaMajorA, UmmaMajorB, KernelScheduleType, is_2sm>(),
                "TileSize and MNK Major does not met with MMA Mix 8-bit TMA load requirement" );
  using TiledMma =  decltype(detail::sm100_make_trivial_tiled_mma<
      ElementAMma, ElementBMma, ElementAccumulator,
      decltype(cute::product_each(TileShape_MNK{})), ClusterShape_MNK,
      UmmaMajorA, UmmaMajorB, KernelScheduleType>());

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

  static_assert(BlockTileA_K{} == BlockTileB_K{}, "Block tile Ks should be equal");

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
  static constexpr uint32_t Sm100TmemCapacityColumns = 512;
  static constexpr uint32_t TotalTmem = TotalTmemRows * Sm100TmemCapacityColumns;
  static constexpr uint32_t AccumulatorPipelineStageCount = (is_2sm || (!is_2sm && size(shape<0,0>(MmaShapeA_MK{}) > 64))) ? 
                                                              TotalTmem / (cute::size<0>(CtaTileShape_MNK{}) * cute::size<1>(CtaTileShape_MNK{}))
                                                            : (Sm100TmemCapacityColumns / cute::size<1>(CtaTileShape_MNK{})) * 2;                       // 1SM MMA_M = 64 case
  static_assert(AccumulatorPipelineStageCount > 0, "Accumulator pipeline stage count must be positive.  This error probably means that TileShape_MNK and/or TiledMma::ThrLayoutVMNK are wrong.");

  // Calculate scheduler pipeline stages. Having one more stage than the accumulator allows more latency hiding.
  using StrideA = cutlass::gemm::TagToStrideA_t<GmemLayoutATag>;
  using InternalStrideA  = cute::remove_pointer_t<StrideA>;
  // Grouped GEMM (where Stride type is Stride*) does not use CLC based scheduler.
  // SchedulerPipelineStageCount could be set to zero for Grouped GEMM, but we shouldn't define CLC Pipeline's barrier arrays of size zero.
  static constexpr uint32_t SchedulerPipelineStageCount = cute::is_same_v<InternalStrideA, StrideA> ? (AccumulatorPipelineStageCount + 1) : 1;

  static constexpr uint32_t KernelSmemCarveout = detail::Sm100DenseGemmTmaUmmaCarveout<
      ClusterShape_MNK,
      AccumulatorPipelineStageCount,
      SchedulerPipelineStageCount,
      detail::CLCResponseSize,
      false
    >::KernelSmemCarveout;
  // Reduce SMEM capacity available for buffers considering barrier allocations.
  static constexpr int Sm100ReducedSmemCapacityBytes = cutlass::gemm::collective::detail::sm100_smem_capacity_bytes - KernelSmemCarveout;

  using SmemTileShape = cute::Shape<BlockTileA_M, BlockTileB_N, BlockTileA_K>;
  using MainloopPipelineStorage = typename cutlass::PipelineTmaUmmaAsync<1>::SharedStorage;
  using TransformLoadPipelineStorage = typename cutlass::PipelineAsync<1>::SharedStorage;
  using TransformPipelineStorage = typename cutlass::PipelineUmmaAsync<1>::SharedStorage;

  static constexpr int ScaleGranularityM = size<0,0>(GmemLayoutSFATag{});
  static constexpr int ScaleGranularityN = size<0,0>(GmemLayoutSFBTag{});
  static constexpr int ScaleGranularityK = size<1,0>(GmemLayoutSFBTag{});

  static_assert(size<0>(CtaTileShape_MNK{}) >= ScaleGranularityM, "Scale Granularity must be smaller than or equal to the tile shape");
  static_assert(size<1>(CtaTileShape_MNK{}) >= ScaleGranularityN, "Scale Granularity must be smaller than or equal to the tile shape");
  static_assert(size<2>(CtaTileShape_MNK{}) >= ScaleGranularityK, "Scale Granularity must be smaller than or equal to the tile shape");

  using BlockTileScale_M = Int<size<0>(TileShape_MNK{}) / ScaleGranularityM>;
  using BlockTileScale_N = Int<size<1>(TileShape_MNK{}) / ScaleGranularityN>;
  using BlockTileScale_K = Int<size<2>(TileShape_MNK{}) / ScaleGranularityK>;

  using ScaleTileShape = cute::Shape<BlockTileScale_M, BlockTileScale_N, BlockTileScale_K>;

  static constexpr int PipelineStages = cutlass::gemm::collective::detail::sm100_compute_stage_count_or_override_blockwise<
      Sm100ReducedSmemCapacityBytes, ElementAMma_SmemAllocType, ElementBMma_SmemAllocType, 
      ElementAccumulator, ScaleTileShape, SmemTileShape, MainloopPipelineStorage,
      TransformLoadPipelineStorage, TransformPipelineStorage>(StageCountType{});
  static_assert(PipelineStages > 0, "Smem usage is too high. Can't create any SMEM buffers for A, B, and scales.");

  using DispatchPolicy = cutlass::gemm::MainloopSm100TmaUmmaWarpSpecializedBlockwiseScaling<
      PipelineStages,
      SchedulerPipelineStageCount,
      AccumulatorPipelineStageCount,
      ClusterShape_MNK>;

  using CollectiveOp = cutlass::gemm::collective::CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      cute::tuple<cutlass::gemm::TagToStrideA_t<GmemLayoutATag>, cutlass::gemm::TagToStrideA_t<GmemLayoutSFATag>>,
      ElementB,
      cute::tuple<cutlass::gemm::TagToStrideB_t<GmemLayoutBTag>, cutlass::gemm::TagToStrideB_t<GmemLayoutSFBTag>>,
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
