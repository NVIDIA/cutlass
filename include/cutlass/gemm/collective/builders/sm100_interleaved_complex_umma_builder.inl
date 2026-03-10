/***************************************************************************************************
 * Copyright (c) 2024 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

namespace detail {

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<
  int CapacityBytes,
  class TileShapeMNK,
  int stages
>
constexpr int
sm100_compute_stage_count_or_override_interleaved_complex_tf32(StageCount<stages> stage_count) {
  return stages;
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<
  int CapacityBytes,
  class TileShapeMNK,
  int carveout_bytes
>
constexpr int
sm100_compute_stage_count_or_override_interleaved_complex_tf32(StageCountAutoCarveout<carveout_bytes> stage_count) {
  // Each stage include (CollectiveMma::SharedStorage)
  // 1. smem for A and smem for B (CollectiveMma::SharedStorage::TensorStorage)
  // 2. one Load2TransformPipeline = PipelineTmaTransformAsync
  constexpr auto load2transform_pipeline_bytes = sizeof(typename cutlass::PipelineTmaTransformAsync<1>::SharedStorage);
  constexpr auto a_bits = cute::sizeof_bits_v<complex<tfloat32_t>>;
  constexpr auto b_bits = cute::sizeof_bits_v<complex<tfloat32_t>>;
  constexpr int stage_bytes =
    cutlass::bits_to_bytes(a_bits * size<0>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    cutlass::bits_to_bytes(b_bits * size<1>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    static_cast<int>(load2transform_pipeline_bytes);

  return (CapacityBytes - carveout_bytes) / stage_bytes;
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////
// Interleaved complex tf32 TCGEN05 kernels builder
template <
  class ArchTag,
  class GmemLayoutATag,
  class TransformA,
  class GmemLayoutBTag,
  class TransformB,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class BuilderScheduleTag
>
struct CollectiveBuilder<
    ArchTag,
    arch::OpClassTensorOp,
    cute::tuple<cutlass::complex<float>, TransformA>,
    GmemLayoutATag,
    2,
    cute::tuple<cutlass::complex<float>, TransformB>,
    GmemLayoutBTag,
    2,
    cutlass::complex<float>,
    TileShape_MNK,    // (MmaAtomShapeM, MmaAtomShapeN, TileK)
    ClusterShape_MNK, // Static cluster shape or dynamic (int, int, _1)
    StageCountType,
    BuilderScheduleTag,
    cute::enable_if_t<
      (cute::is_same_v<ArchTag, arch::Sm100> 
      ) &&
      (cute::is_base_of_v<KernelScheduleSm100InterleavedComplexTF32Gemm, BuilderScheduleTag> ||
      cute::is_same_v<KernelScheduleAuto, BuilderScheduleTag>)>>
{
  static_assert(cute::is_static_v<TileShape_MNK>, "TileShape_MNK has to be static");
  // ElementA and ElementB are cutlass::complex<float>, which are used as GMEM input and output data type.
  // ElementAMma and ElementBMma are cutlass::complex<tfloat32_t>, which are used as SMEM and RF data type.
  using ElementA = complex<float>;
  using ElementB = complex<float>;
  using ElementAccumulator = cutlass::complex<float>;
  using ElementAMma = complex<tfloat32_t>;
  using ElementBMma = complex<tfloat32_t>;

  static constexpr cute::UMMA::Major UmmaMajorA = cutlass::gemm::collective::detail::tag_to_umma_major_A<GmemLayoutATag>();
  static constexpr cute::UMMA::Major UmmaMajorB = cutlass::gemm::collective::detail::tag_to_umma_major_B<GmemLayoutBTag>();

  using TiledMma = decltype(detail::sm100_make_trivial_interleaved_complex_tf32_tiled_mma<
      TileShape_MNK,ClusterShape_MNK,BuilderScheduleTag>());

  using AtomThrID = typename TiledMma::AtomThrID;

  // Define A and B block shapes for reduced size TMA_LOADs
  // ((MMA_TILE_M,MMA_TILE_K), MMA_M, MMA_K)
  using MmaShapeA_MK = decltype(partition_shape_A(TiledMma{}, make_shape(cute::size<0>(TileShape_MNK{}),
                                                                         cute::size<2>(TileShape_MNK{}))));
  // ((MMA_TILE_N,MMA_TILE_K), MMA_N, MMA_K)
  using MmaShapeB_NK = decltype(partition_shape_B(TiledMma{}, make_shape(cute::size<1>(TileShape_MNK{}),
                                                                         cute::size<2>(TileShape_MNK{}))));
  // Input transform kernel can not use TMA 2SM instructions.
  using GmemTiledCopyA = decltype(detail::sm90_cluster_shape_to_tma_atom(cute::size<1>(ClusterShape_MNK{})));

  using BlockTileA_M = decltype(cute::size<0,0>(MmaShapeA_MK{}) * cute::size<1>(MmaShapeA_MK{}));
  using BlockTileA_K = decltype(cute::size<0,1>(MmaShapeA_MK{}) * cute::size<2>(MmaShapeA_MK{}));

  using SmemLayoutAtomA = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<UmmaMajorA, ElementAMma,
    BlockTileA_M, BlockTileA_K>());
  using SmemLayoutAtomACompute = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<cute::UMMA::Major::K, ElementAMma,
    BlockTileA_M, BlockTileA_K>());
  using SmemLayoutAtomPairA = cutlass::gemm::collective::detail::Sm100CollectiveMmaComplexLayoutAtomType<SmemLayoutAtomA,
                                SmemLayoutAtomACompute>;

  static constexpr int MMA_M = cute::size<0>(TileShape_MNK{});

  using CopyAtomPairA = cutlass::gemm::collective::detail::Sm100CollectiveMmaComplexCopyType<
    Copy_Atom<AutoVectorizingCopyWithAssumedAlignment<128>, ElementAMma>,
    conditional_t<MMA_M == 64, SM100_TMEM_STORE_16dp256b1x, SM100_TMEM_STORE_32dp32b32x>
  >;

  // Input transform kernel can not use TMA 2SM instructions.
  using GmemTiledCopyB = decltype(detail::sm90_cluster_shape_to_tma_atom(cute::size<0>(ClusterShape_MNK{})));

  using BlockTileB_N = decltype(cute::size<0,0>(MmaShapeB_NK{}) * cute::size<1>(MmaShapeB_NK{}));
  using BlockTileB_K = decltype(cute::size<0,1>(MmaShapeB_NK{}) * cute::size<2>(MmaShapeB_NK{}));

  using SmemLayoutAtomB = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<UmmaMajorB, ElementBMma,
    BlockTileB_N, BlockTileB_K>());
  using SmemLayoutAtomBCompute = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<cute::UMMA::Major::K, ElementBMma,
    BlockTileB_N, BlockTileB_K>());
  using SmemLayoutAtomPairB = cutlass::gemm::collective::detail::Sm100CollectiveMmaComplexLayoutAtomType<SmemLayoutAtomB,
                                SmemLayoutAtomBCompute>;

  using CopyAtomPairB = cutlass::gemm::collective::detail::Sm100CollectiveMmaComplexCopyType<
    Copy_Atom<AutoVectorizingCopyWithAssumedAlignment<128>, ElementBMma>,
    Copy_Atom<AutoVectorizingCopyWithAssumedAlignment<128>, ElementBMma>
  >;

  // Calculate SMEM matrix A and B buffers' pipeline stages
  static constexpr int MMA_N = cute::size<1>(TileShape_MNK{});
  static constexpr uint32_t TransformationStageCount = 4;
  static constexpr uint32_t AccumulatorPipelineStageCount = (MMA_N >= 128) ? 1 : 2;
  static constexpr uint32_t SchedulerPipelineStageCount = 3;
  static constexpr bool IsArrayOfPointersGemm = (cute::is_base_of_v<KernelScheduleSm100PtrArrayInterleavedComplexTF32Gemm, BuilderScheduleTag>);

  // SmemCarveout
  // B needs extra smem for smem tranpose (CollectiveMma::TensorStorageTransformed)
  static constexpr auto TensorStorageTransformedSmemBStorage = TransformationStageCount * 
                            static_cast<int>(sizeof(ElementBMma)) * size<0>(BlockTileB_N{}) * size<0>(BlockTileA_K{});
  // CLCPipeline = PipelineCLCFetchAsync
  static constexpr auto CLCPipelineStorage = sizeof(typename cutlass::PipelineCLCFetchAsync<SchedulerPipelineStageCount, ClusterShape_MNK>::SharedStorage);
  // Transform2MmaPipeline = PipelineUmmaConsumerAsync (CollectiveMma)
  static constexpr auto Transform2MmaPipelineStorage = sizeof(typename cutlass::PipelineUmmaConsumerAsync<TransformationStageCount>::SharedStorage);
  // Mma2AccumPipeline = PipelineUmmaAsync (CollectiveMma)
  static constexpr auto Mma2AccumPipelineStorage = sizeof(typename cutlass::PipelineUmmaAsync<AccumulatorPipelineStageCount>::SharedStorage);
  // CLC (scheduler) response
  static constexpr auto CLCResponseStorage = SchedulerPipelineStageCount * detail::CLCResponseSize;
  // CLC Throttle pipeline storage
  static constexpr auto CLCThrottlePipelineStorage = sizeof(typename cutlass::PipelineAsync<SchedulerPipelineStageCount>::SharedStorage);
  // Tmem dealloc
  static constexpr auto TmemDeallocStorage = sizeof(cutlass::arch::ClusterBarrier);
  // Tmem ptr storage
  static constexpr auto TmemBasePtrsStorage = sizeof(uint32_t);
  // Tensormap Storage
  
  static constexpr size_t TensorMapStorage = IsArrayOfPointersGemm ? sizeof(cute::TmaDescriptor) * 2 /* for A and B */ : 0;

  // Smem usage that's not part of CollectiveEpilogue::SharedStorage & CollectiveMainloop::SharedStorage
  static constexpr auto KernelSmemCarveout = static_cast<int>( CLCPipelineStorage +
                                                               CLCResponseStorage +
                                                               CLCThrottlePipelineStorage +
                                                               Transform2MmaPipelineStorage +
                                                               Mma2AccumPipelineStorage +
                                                               TensorStorageTransformedSmemBStorage +
                                                               TmemDeallocStorage +
                                                               TmemBasePtrsStorage +
                                                               TensorMapStorage);
  // Reduce SMEM capacity available for buffers considering extra B smem and barrier smem allocations
  
  static constexpr int ReducedSmemCapacityBytes = 
    cutlass::gemm::collective::detail::sm100_smem_capacity_bytes - KernelSmemCarveout;

  using SmemTileShape = cute::Shape<BlockTileA_M, BlockTileB_N, BlockTileA_K>;

  static constexpr int PipelineStages_ = detail::sm100_compute_stage_count_or_override_interleaved_complex_tf32<
      ReducedSmemCapacityBytes, SmemTileShape>(StageCountType{});
  // Complex kernels allow TileShape_N = 64, while SmemLayoutAtomB contains Swizzle<3,4,3>.
  static constexpr int PipelineStages = size<1>(TileShape_MNK{}) == 64 ? PipelineStages_ / 2 * 2 : PipelineStages_;
  static_assert(PipelineStages >= 2, "Pipeline Stages has to be at least 2");

  using AccumulatorCopyAtom = cute::SM100_TMEM_LOAD_16dp256b1x;

  using DispatchPolicy = cute::conditional_t<IsArrayOfPointersGemm,
      cutlass::gemm::MainloopSm100ArrayTmaUmmaWarpSpecializedInterleavedComplexTF32<
        PipelineStages,
        SchedulerPipelineStageCount,
        AccumulatorPipelineStageCount,
        TransformationStageCount,
        ClusterShape_MNK,
        AccumulatorCopyAtom
      >,
      cutlass::gemm::MainloopSm100TmaUmmaWarpSpecializedInterleavedComplexTF32<
        PipelineStages,
        SchedulerPipelineStageCount,
        AccumulatorPipelineStageCount,
        TransformationStageCount,
        ClusterShape_MNK,
        AccumulatorCopyAtom
      >
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
      SmemLayoutAtomPairA,
      CopyAtomPairA,
      TransformA,
      GmemTiledCopyB,
      SmemLayoutAtomPairB,
      CopyAtomPairB,
      TransformB
    >;
};

} // cutlass::gemm::collective
