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
/////////////////////////////////////////////////////////////////////////////////////////////////
// Planar Complex f16/bf16 TCGEN05 kernels builder
template <
  class ArchTag,
  class ElementA,
  class GmemLayoutATag,
  class TransformA,
  class ElementB,
  class GmemLayoutBTag,
  class TransformB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class BuilderScheduleTag
>
struct CollectiveBuilder<
    ArchTag,
    arch::OpClassTensorOp,
    cute::tuple<ElementA, TransformA>,
    GmemLayoutATag,
    8,
    cute::tuple<ElementB, TransformB>,
    GmemLayoutBTag,
    8,
    ElementAccumulator,
    TileShape_MNK,    // (MmaAtomShapeM, MmaAtomShapeN, TileK)
    ClusterShape_MNK, // Static cluster shape or dynamic (int, int, _1)
    StageCountType,
    BuilderScheduleTag,
    cute::enable_if_t<
      (cute::is_same_v<ArchTag, arch::Sm100>
      ) &&
       // Element Types AB should be set as real type in Planar Complex f16/bf16 TCGEN05 kernels builder.
       (cute::is_same_v<ElementA, cutlass::half_t> || cute::is_same_v<ElementA, cutlass::bfloat16_t>) &&
       (cute::is_same_v<ElementB, cutlass::half_t> || cute::is_same_v<ElementB, cutlass::bfloat16_t>) &&
       // Planar Complex f16/bf16 kernels don't support auto-scheduling for mainloop builder.
       cute::is_base_of_v<KernelScheduleSm100PlanarComplexGemm, BuilderScheduleTag>>>
{
  static_assert(cute::is_static_v<TileShape_MNK>, "TileShape has to be static");

  static constexpr cute::UMMA::Major UmmaMajorA = cutlass::gemm::collective::detail::tag_to_umma_major_A<GmemLayoutATag>();
  static constexpr cute::UMMA::Major UmmaMajorB = cutlass::gemm::collective::detail::tag_to_umma_major_B<GmemLayoutBTag>();

  using TiledMma = decltype(detail::sm100_make_trivial_tiled_mma<
      ElementA, ElementB, ElementAccumulator,
      TileShape_MNK, ClusterShape_MNK,
      UmmaMajorA, UmmaMajorB, BuilderScheduleTag, UMMA::ScaleIn::One>());
  using TiledMmaANeg = decltype(detail::sm100_make_trivial_tiled_mma<
      ElementA, ElementB, ElementAccumulator,
      TileShape_MNK, ClusterShape_MNK,
      UmmaMajorA, UmmaMajorB, BuilderScheduleTag, UMMA::ScaleIn::Neg>());
  using TiledMmaPair = cutlass::gemm::collective::detail::Sm100CollectiveMmaPlanarComplexTiledMmaType<TiledMma, TiledMmaANeg>;

  using AtomThrID = typename TiledMma::AtomThrID;

  // Define A and B block shapes for reduced size TMA_LOADs
  // ((MMA_TILE_M,MMA_TILE_K), MMA_M, MMA_K)
  using MmaShapeA_MK = decltype(partition_shape_A(TiledMma{}, make_shape(cute::size<0>(TileShape_MNK{}),
                                                                         cute::size<2>(TileShape_MNK{}))));
  // ((MMA_TILE_N,MMA_TILE_K), MMA_N, MMA_K)
  using MmaShapeB_NK = decltype(partition_shape_B(TiledMma{}, make_shape(cute::size<1>(TileShape_MNK{}),
                                                                         cute::size<2>(TileShape_MNK{}))));

  using GmemTiledCopyA = decltype(detail::sm100_cluster_shape_to_tma_atom_A(ClusterShape_MNK{}, AtomThrID{}));

  using BlockTileA_M = decltype(cute::size<0,0>(MmaShapeA_MK{}) * cute::size<1>(MmaShapeA_MK{}));
  using BlockTileA_K = decltype(cute::size<0,1>(MmaShapeA_MK{}) * cute::size<2>(MmaShapeA_MK{}));
  using SmemLayoutAtomA = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      UmmaMajorA, ElementA, BlockTileA_M, BlockTileA_K>());

  using GmemTiledCopyB = decltype(detail::sm100_cluster_shape_to_tma_atom_B(ClusterShape_MNK{}, AtomThrID{}));

  using BlockTileB_N = decltype(cute::size<0,0>(MmaShapeB_NK{}) * cute::size<1>(MmaShapeB_NK{}));
  using BlockTileB_K = decltype(cute::size<0,1>(MmaShapeB_NK{}) * cute::size<2>(MmaShapeB_NK{}));
  using SmemLayoutAtomB = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      UmmaMajorB, ElementB, BlockTileB_N, BlockTileB_K>());

  // Calculate SMEM matrix A and B buffers' pipeline stages
  static constexpr uint32_t AccumulatorPipelineStageCount = 2;
  // Ptr-arry gemm requires extra TensorMap storage
  static constexpr bool IsArrayOfPointersGemm = (cute::is_base_of_v<KernelScheduleSm100PtrArrayPlanarComplexGemm, BuilderScheduleTag>);
  // Calculate scheduler pipeline stages. Having one more stage than the accumulator allows more latency hiding.
  static constexpr uint32_t SchedulerPipelineStageCount = IsArrayOfPointersGemm ? AccumulatorPipelineStageCount + 1: 1;

  static constexpr uint32_t KernelSmemCarveout = detail::Sm100DenseGemmTmaUmmaCarveout<
        ClusterShape_MNK,
        AccumulatorPipelineStageCount,
        SchedulerPipelineStageCount,
        detail::CLCResponseSize,
        IsArrayOfPointersGemm,
        4 // 4 Tensor maps for A_{imag|real} and B_{imag|real}
    >::KernelSmemCarveout;

  // Reduce SMEM capacity available for buffers considering barrier allocations.

  static constexpr int ReducedSmemCapacityBytes =
    cutlass::gemm::collective::detail::sm100_smem_capacity_bytes - KernelSmemCarveout;

  using SmemTileShape = cute::Shape<BlockTileA_M, BlockTileB_N, BlockTileA_K>;

  // Use complex type to calculate SMEM stage count
  using ComplexElementA = cutlass::complex<ElementA>;
  using ComplexElementB = cutlass::complex<ElementB>;

  using MainloopPipelineStorage = typename cutlass::PipelineTmaUmmaAsync<1>::SharedStorage;
  static constexpr int PipelineStages = detail::sm100_compute_stage_count_or_override<
      ReducedSmemCapacityBytes, ComplexElementA, ComplexElementB, SmemTileShape, MainloopPipelineStorage>(StageCountType{});

  using DispatchPolicy = cute::conditional_t<IsArrayOfPointersGemm,
      cutlass::gemm::MainloopSm100ArrayTmaUmmaWarpSpecializedPlanarComplex<
          PipelineStages,
          SchedulerPipelineStageCount,
          AccumulatorPipelineStageCount,
          ClusterShape_MNK
      >,
      cutlass::gemm::MainloopSm100TmaUmmaWarpSpecializedPlanarComplex<
          PipelineStages,
          SchedulerPipelineStageCount,
          AccumulatorPipelineStageCount,
          ClusterShape_MNK
      >
    >;

  using CollectiveOp = cutlass::gemm::collective::CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      cutlass::gemm::TagToStrideA_t<GmemLayoutATag>,
      ElementB,
      cutlass::gemm::TagToStrideB_t<GmemLayoutBTag>,
      TiledMmaPair,
      GmemTiledCopyA,
      SmemLayoutAtomA,
      void,
      TransformA,
      GmemTiledCopyB,
      SmemLayoutAtomB,
      void,
      TransformB
    >;
};

} // cutlass::gemm::collective
