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
#include "cutlass/gemm/collective/builders/sm100_blockscaled_umma_builder.inl"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  class ArchTag,
  class ElementPairA,
  class GmemLayoutATag,
  int AlignmentA,
  class ElementPairB,
  class GmemLayoutBTag,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,        // (MmaAtomShapeM, MmaAtomShapeN, TileK)
  class ClusterShape_MNK,     // Static cluster shape or dynamic (int, int, _1)
  class StageCountType,
  class BuilderScheduleTag
>
struct CollectiveBuilder<
    ArchTag,
    arch::OpClassBlockScaledTensorOp,
    ElementPairA,
    GmemLayoutATag,
    AlignmentA,
    ElementPairB,
    GmemLayoutBTag,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    BuilderScheduleTag,
    cute::enable_if_t<
      cute::is_same_v<ArchTag, arch::Sm107>
      &&
      // Blockscaled Gemm
      (
        cute::is_base_of_v<KernelScheduleSm107BlockScaledMxf8f6f4, BuilderScheduleTag> ||
        cute::is_base_of_v<KernelScheduleSm107BlockScaledMxNvf4, BuilderScheduleTag>
      )
       &&
      // Alignment check
      detail::sm1xx_blockscaled_gemm_is_aligned<typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairA>::data_type,
                                                AlignmentA,
                                                typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairB>::data_type,
                                                AlignmentB,
                                                BuilderScheduleTag>()>>
{
  using ElementSFA = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairA>::sf_type;
  using ElementSFB = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairB>::sf_type;
  using ElementA = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairA>::data_type;
  using ElementB = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairB>::data_type;
  using ElementSF = ElementSFA;

  static constexpr cute::UMMA::Major UmmaMajorA = cutlass::gemm::collective::detail::tag_to_umma_major_A<GmemLayoutATag>();
  static constexpr cute::UMMA::Major UmmaMajorB = cutlass::gemm::collective::detail::tag_to_umma_major_B<GmemLayoutBTag>();

  static_assert(cute::is_static_v<TileShape_MNK>, "TileShape has to be static");
  static_assert(detail::blockscaled::check_input_datatypes<BuilderScheduleTag, ElementPairA, ElementPairB, UmmaMajorA, UmmaMajorB>(), "Incorrect input types");

  static constexpr bool is_2sm = detail::blockscaled::is_2sm<TileShape_MNK, ClusterShape_MNK, BuilderScheduleTag>();
  static constexpr auto Instr = detail::blockscaled::select_instr<ElementPairA, ElementPairB, ElementAccumulator, UmmaMajorA, UmmaMajorB, BuilderScheduleTag>();

  static constexpr bool WithBreuse =
      (cute::is_base_of_v<KernelScheduleSm107BlockScaledMxf8f6f4WithBreuse, BuilderScheduleTag> ||
       cute::is_base_of_v<KernelScheduleSm107BlockScaledMxNvf4Vs16WithBreuse, BuilderScheduleTag> ||
       cute::is_base_of_v<KernelScheduleSm107BlockScaledMxNvf4Vs32WithBreuse, BuilderScheduleTag>)
      ? true : false;

  static_assert(
      cute::is_base_of_v<KernelScheduleSm107BlockScaledMxf8f6f4, BuilderScheduleTag> ||
      cute::is_base_of_v<KernelScheduleSm107BlockScaledMxNvf4, BuilderScheduleTag>,
      "SM107 blockscaled builder only supports MXF8F6F4 (SF vector size 32) and MXNVF4 (SF vector size 16 or 32) kernel schedules.");
  static constexpr uint32_t SFVecSize =
      cute::is_base_of_v<KernelScheduleSm107BlockScaledMxNvf4Vs16, BuilderScheduleTag> ? 16 : 32;

  using TiledMma = decltype(cutlass::gemm::collective::detail::sm107_make_blockscaled_trivial_tiled_mma<
                                  ElementPairA, ElementPairB, ElementAccumulator,
                                  TileShape_MNK, ClusterShape_MNK,
                                  UmmaMajorA, UmmaMajorB, Instr, BuilderScheduleTag, SFVecSize, WithBreuse>());

  static constexpr bool UseMxf8f6f4 = Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8;

  static_assert(UseMxf8f6f4 || (cutlass::gemm::detail::is_k_major_A<GmemLayoutATag>() && cutlass::gemm::detail::is_k_major_B<GmemLayoutBTag>()), "Only MMA.MXF8F6F4 supports non-K major inputs");

  // Data type used by MMA instruction
  using ElementAMma = decltype(cutlass::gemm::collective::detail::sm1xx_kernel_input_element_to_mma_input_element<ElementA, UseMxf8f6f4>());
  using ElementBMma = decltype(cutlass::gemm::collective::detail::sm1xx_kernel_input_element_to_mma_input_element<ElementB, UseMxf8f6f4>());

  // Basic storage block for new Scaling Factor Layouts
  using AtomThrID = typename TiledMma::AtomThrID;
  using Sm107BlkScaledConfig = cutlass::detail::Sm107BlockScaledConfig<SFVecSize>;

  using ElementAMma_SmemAllocType = cute::conditional_t<UseMxf8f6f4, uint8_t, ElementAMma>;
  using ElementBMma_SmemAllocType = cute::conditional_t<UseMxf8f6f4, uint8_t, ElementBMma>;

  // ((MMA_TILE_M,MMA_TILE_K), MMA_M, MMA_K)
  using MmaShapeA_MK = decltype(partition_shape_A(TiledMma{}, make_shape(cute::size<0>(TileShape_MNK{}),
                                                                         cute::size<2>(TileShape_MNK{}))));
  // ((MMA_TILE_N,MMA_TILE_K), MMA_N, MMA_K)
  using MmaShapeB_NK = decltype(partition_shape_B(TiledMma{}, make_shape(cute::size<1>(TileShape_MNK{}),
                                                                         cute::size<2>(TileShape_MNK{}))));

  using GmemTiledCopyA = decltype(cutlass::gemm::collective::detail::sm100_cluster_shape_to_tma_atom_A(
      ClusterShape_MNK{}, AtomThrID{}));

  using GmemTiledCopyB = decltype(cutlass::gemm::collective::detail::sm100_cluster_shape_to_tma_atom_B(
      ClusterShape_MNK{}, AtomThrID{}));

  using GmemTiledCopySFA = decltype(cutlass::gemm::collective::detail::sm100_cluster_shape_to_tma_atom_A(
      ClusterShape_MNK{}, AtomThrID{}));

  using GmemTiledCopySFB = decltype(cutlass::gemm::collective::detail::sm100_cluster_shape_to_tma_atom_SFB(
      ClusterShape_MNK{}, AtomThrID{}));

  using GmemTiledCopyPairA = decltype(cute::make_tuple(GmemTiledCopyA{}, GmemTiledCopySFA{}));
  using GmemTiledCopyPairB = decltype(cute::make_tuple(GmemTiledCopyB{}, GmemTiledCopySFB{}));

  //
  // Construct SMEM layout (SmemLayoutAtom) for A and SFA
  //
  using BlockTileA_M = decltype(cute::size<0,0>(MmaShapeA_MK{}) * cute::size<1>(MmaShapeA_MK{}));
  using BlockTileA_K = decltype(cute::size<0,1>(MmaShapeA_MK{}) * cute::size<2>(MmaShapeA_MK{}));
  using SmemLayoutAtomA = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      UmmaMajorA, ElementAMma_SmemAllocType, BlockTileA_M, BlockTileA_K>());

  // A single indivisible block will hold 4 scale factors of 128 rows/columns (A/B matrix).
  // 4 is chosen to make consecutive 32bits of data to have scale factors for only a single row (col). 32bits corresponds to the TMEM word size
  using Blk_MN    = typename Sm107BlkScaledConfig::Blk_MN;
  using Blk_SF    = typename Sm107BlkScaledConfig::Blk_SF;
  using Blk_Elems = decltype(Blk_MN{} * Blk_SF{});
  using SmemLayoutAtomSFA = decltype(Sm107BlkScaledConfig::deduce_smem_layoutSFA(TiledMma{}, TileShape_MNK{}));
  using SmemLayoutAtomsA = decltype(cute::make_tuple(SmemLayoutAtomA{}, SmemLayoutAtomSFA{}));

  //
  // Construct SMEM layout (SmemLayoutAtom) for B and SFB
  //
  using BlockTileB_N = decltype(cute::size<0,0>(MmaShapeB_NK{}) * cute::size<1>(MmaShapeB_NK{}));
  using BlockTileB_K = decltype(cute::size<0,1>(MmaShapeB_NK{}) * cute::size<2>(MmaShapeB_NK{}));
  using SmemLayoutAtomB = decltype(cutlass::gemm::collective::detail::sm100_smem_selector<
      UmmaMajorB, ElementBMma_SmemAllocType, BlockTileB_N, BlockTileB_K>());
  using SmemLayoutAtomSFB = decltype(Sm107BlkScaledConfig::deduce_smem_layoutSFB(TiledMma{}, TileShape_MNK{}));
  using SmemLayoutAtomsB = decltype(cute::make_tuple(SmemLayoutAtomB{}, SmemLayoutAtomSFB{}));

  //
  // Construct Strides for A, SFA, B, and SFB
  //
  using StrideA = cutlass::gemm::TagToStrideA_t<GmemLayoutATag>;
  using StrideB = cutlass::gemm::TagToStrideB_t<GmemLayoutBTag>;
  using InternalStrideA  = cute::remove_pointer_t<StrideA>;
  using InternalStrideB  = cute::remove_pointer_t<StrideB>;
  using InternalLayoutSFA = decltype(Sm107BlkScaledConfig::deduce_layoutSFA());
  using InternalLayoutSFB = decltype(Sm107BlkScaledConfig::deduce_layoutSFB());
  using LayoutSFA = cute::conditional_t<cute::is_same_v<InternalStrideA, StrideA>, InternalLayoutSFA, InternalLayoutSFA *>;
  using LayoutSFB = cute::conditional_t<cute::is_same_v<InternalStrideB, StrideB>, InternalLayoutSFB, InternalLayoutSFB *>;
  using StridePairA = decltype(cute::make_tuple(StrideA{}, LayoutSFA{}));
  using StridePairB = decltype(cute::make_tuple(StrideB{}, LayoutSFB{}));

  static constexpr int MMA_N = cute::size<1>(TileShape_MNK{});
  static constexpr uint32_t AccumulatorPipelineStageCount = (WithBreuse && (MMA_N == 192 || MMA_N == 256)) ? 1 : 2;
  static constexpr bool IsArrayOfPointersGemm = false;
  // Grouped GEMM(where Stride type is Stride*) uses specific static tile scheduler.
  static constexpr bool IsGroupGemm = false;
  static constexpr bool IsRCGroupGemm = false;
  static constexpr uint32_t SchedulerPipelineStageCount = cute::conditional_return<IsGroupGemm || IsRCGroupGemm>(8, 2);

  static constexpr uint32_t KernelSmemCarveout = detail::Sm100DenseGemmTmaUmmaCarveout<
      ClusterShape_MNK,
      AccumulatorPipelineStageCount,
      SchedulerPipelineStageCount,
      detail::CLCResponseSize,
      IsArrayOfPointersGemm,
      4 // 4 Tensor maps for A, SFA, B and SFB
    >::KernelSmemCarveout;
  // Reduce SMEM capacity available for buffers considering barrier allocations.

  static constexpr int ReducedSmemCapacityBytes = detail::sm100_reduced_smem_capacity_bytes<ArchTag, KernelSmemCarveout>();

  using SmemTileShape = cute::Shape<BlockTileA_M, BlockTileB_N, BlockTileA_K>;

  static constexpr int PipelineStages = cutlass::gemm::collective::detail::sm100_compute_stage_count_or_override_blockscaled<
      ReducedSmemCapacityBytes, ElementAMma_SmemAllocType, ElementBMma_SmemAllocType, SmemTileShape, SmemLayoutAtomSFA, SmemLayoutAtomSFB>(StageCountType{});
  static_assert(PipelineStages > 0, "Smem usage is too high. Can't create any SMEM buffers for A, B, SFA, and SFB.");

  using DispatchPolicy =
    cutlass::gemm::MainloopSm107TmaUmmaWarpSpecializedBlockScaled<
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
      cute::tuple<ElementA, ElementSF>,
      StridePairA,
      cute::tuple<ElementB, ElementSF>,
      StridePairB,
      TiledMma,
      GmemTiledCopyPairA,
      SmemLayoutAtomsA,
      void,
      cute::identity,
      GmemTiledCopyPairB,
      SmemLayoutAtomsB,
      void,
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
