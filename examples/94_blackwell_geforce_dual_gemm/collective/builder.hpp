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

#include "cutlass/gemm/collective/collective_builder.hpp"
#include "cutlass/gemm/collective/builders/sm120_common.inl"
#include "dispatch_policy_extra.hpp"
#include "sm120_blockscaled_mma_tma_dual.hpp"

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

template <
  class ElementPairA,
  class GmemLayoutATag,
  int AlignmentA,
  class ElementPairB,
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
    arch::Sm120,
    arch::OpClassBlockScaledTensorOp,
    ElementPairA,
    GmemLayoutATag,
    AlignmentA,
    ElementPairB,
    GmemLayoutB0Tag,
    GmemLayoutB1Tag,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      cute::is_same_v<KernelScheduleType, DualKernelTmaWarpSpecializedCooperativeBlockScaledSm120<3>>>> 
{

  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
  static_assert(detail::is_aligned<ElementPairA, AlignmentA, ElementPairB, AlignmentB, detail::tma_alignment_bytes>(),
                "Not meet TMA alignment requirement yet\n");
  // Let the blockscaled helpers auto-deduce instruction and SF vector size from ElementPair types.
  using KernelScheduleTag = KernelScheduleAuto;

  // Deduce data/scalefactor types from the pair wrappers
  using ElementSFA = typename detail::blockscaled::blockscaled_type<KernelScheduleTag, ElementPairA>::sf_type;
  using ElementSFB = typename detail::blockscaled::blockscaled_type<KernelScheduleTag, ElementPairB>::sf_type;
  static_assert(cute::is_same_v<ElementSFA, ElementSFB>, "Scale factor types for A and B must be the same.");
  using ElementA  = typename detail::blockscaled::blockscaled_type<KernelScheduleTag, ElementPairA>::data_type;
  using ElementB  = typename detail::blockscaled::blockscaled_type<KernelScheduleTag, ElementPairB>::data_type;
  using ElementSF = ElementSFA;
  static constexpr auto SFVectorSizeA = detail::blockscaled::blockscaled_type<KernelScheduleTag, ElementPairA>::SfVectorSize;
  static constexpr auto SFVectorSizeB = detail::blockscaled::blockscaled_type<KernelScheduleTag, ElementPairB>::SfVectorSize;
  static_assert(SFVectorSizeA == SFVectorSizeB, "Scale factor vector size for A and B must be the same.");
  static constexpr int SFVectorSize = SFVectorSizeA;

  // Supported layout
  static constexpr cute::UMMA::Major UmmaMajorA = cutlass::gemm::collective::detail::tag_to_umma_major_A<GmemLayoutATag>();
  static constexpr cute::UMMA::Major UmmaMajorB0 = cutlass::gemm::collective::detail::tag_to_umma_major_B<GmemLayoutB0Tag>();
  static constexpr cute::UMMA::Major UmmaMajorB1 = cutlass::gemm::collective::detail::tag_to_umma_major_B<GmemLayoutB1Tag>();
  static_assert((UmmaMajorA == UMMA::Major::K && UmmaMajorB0 == UMMA::Major::K && UmmaMajorB1 == UMMA::Major::K), "Only TN layout is supported.");

  static_assert(cute::is_static_v<TileShape_MNK>, "TileShape has to be static");
  static_assert(cute::is_static_v<ClusterShape_MNK>, "Cluster has to be static");
  static_assert(detail::blockscaled::check_input_datatypes<KernelScheduleTag, ElementPairA, ElementPairB, UmmaMajorA, UmmaMajorB0>(), "Incorrect input types");
  static_assert(detail::blockscaled::check_input_datatypes<KernelScheduleTag, ElementPairA, ElementPairB, UmmaMajorA, UmmaMajorB1>(), "Incorrect input types");
  static_assert(cute::size(ClusterShape_MNK{}) == Int<1>{}, "No programmatic multicast on this arch");
  static_assert(size<1>(TileShape_MNK{}) >= 32, "Invalid tile shape N.");

  static constexpr auto Instr0 = detail::blockscaled::select_instr<ElementPairA, ElementPairB, ElementAccumulator,
                                                                  UmmaMajorA, UmmaMajorB0, KernelScheduleTag>();
  static constexpr auto Instr1 = detail::blockscaled::select_instr<ElementPairA, ElementPairB, ElementAccumulator,
                                                                  UmmaMajorA, UmmaMajorB1, KernelScheduleTag>();
  static constexpr bool UseMxf8f6f4 = (Instr0 == detail::blockscaled::BlockScaledInstr::MXF4F6F8);

  using PermTileM = decltype(cute::min(size<0>(TileShape_MNK{}), _128{}));
  using PermTileN = decltype(detail::sm120_tile_n_permute_selector<SFVectorSize>());
  using PermTileK = cute::conditional_t<(UseMxf8f6f4), _32, _64>;

  // Cooperative schedule only
  using AtomLayoutMNK = Layout<Shape<_4,_2,_1>>;

  // MMA
  using TiledMma = decltype(cute::make_tiled_mma(
    cute::rr_blockscaled_op_selector_sm120<ElementA, ElementB, ElementAccumulator, ElementSF, SFVectorSize, UseMxf8f6f4>(),
    AtomLayoutMNK{},
    Tile<PermTileM, PermTileN, PermTileK>{}
  ));

  static constexpr int MMA_NSF = size<2>(typename TiledMma::AtomShape_MNK{}) / SFVectorSize;

  // SMEM allocation types
  using SmemAllocTypeA  = cute::conditional_t<UseMxf8f6f4, uint8_t, typename TiledMma::ValTypeA>;
  using SmemAllocTypeB  = cute::conditional_t<UseMxf8f6f4, uint8_t, typename TiledMma::ValTypeB>;
  using SmemAllocTypeSF = ElementSF;

  // GMEM TMA copies
  using GmemTiledCopyA   = SM90_TMA_LOAD;
  using GmemTiledCopyB0  = SM90_TMA_LOAD;
  using GmemTiledCopyB1  = SM90_TMA_LOAD;
  using GmemTiledCopySFA  = SM90_TMA_LOAD;
  using GmemTiledCopySFB0 = SM90_TMA_LOAD;
  using GmemTiledCopySFB1 = SM90_TMA_LOAD;

  using GmemTiledCopyPairA = decltype(cute::make_tuple(GmemTiledCopyA{}, GmemTiledCopySFA{}));
  using GmemTiledCopyPairB0 = decltype(cute::make_tuple(GmemTiledCopyB0{}, GmemTiledCopySFB0{}));
  using GmemTiledCopyPairB1 = decltype(cute::make_tuple(GmemTiledCopyB1{}, GmemTiledCopySFB1{}));

  // Config and SMEM layouts
  using Sm1xxBlkScaledConfig = cutlass::detail::Sm1xxBlockScaledConfig<SFVectorSize>;

  using SmemLayoutAtomA = decltype(detail::sm120_rr_smem_selector<SmemAllocTypeA, decltype(size<2>(TileShape_MNK{}))>());
  using SmemLayoutAtomB0 = decltype(detail::sm120_rr_smem_selector<SmemAllocTypeB, decltype(size<2>(TileShape_MNK{}))>());
  using SmemLayoutAtomB1 = decltype(detail::sm120_rr_smem_selector<SmemAllocTypeB, decltype(size<2>(TileShape_MNK{}))>());

  using SmemCopyAtomA = Copy_Atom<decltype(detail::sm120_rr_smem_copy_selector_A<ElementA, ElementB, UseMxf8f6f4>()), SmemAllocTypeA>;
  using SmemCopyAtomB0 = Copy_Atom<decltype(detail::sm120_rr_smem_copy_selector_B<ElementA, ElementB, UseMxf8f6f4>()), SmemAllocTypeB>;
  using SmemCopyAtomB1 = Copy_Atom<decltype(detail::sm120_rr_smem_copy_selector_B<ElementA, ElementB, UseMxf8f6f4>()), SmemAllocTypeB>;

  using SmemCopyAtomSF  = Copy_Atom<UniversalCopy<SmemAllocTypeSF>, SmemAllocTypeSF>;
  using SmemCopyAtomSFA = SmemCopyAtomSF;
  using SmemCopyAtomSFB0 = SmemCopyAtomSF;
  using SmemCopyAtomSFB1 = SmemCopyAtomSF;

  using SmemCopyAtomsA = decltype(cute::make_tuple(SmemCopyAtomA{}, SmemCopyAtomSFA{}));
  using SmemCopyAtomsB0 = decltype(cute::make_tuple(SmemCopyAtomB0{}, SmemCopyAtomSFB0{}));
  using SmemCopyAtomsB1 = decltype(cute::make_tuple(SmemCopyAtomB1{}, SmemCopyAtomSFB1{}));

  // Construct SMEM layout for SF
  // A single indivisible block will hold 4 scale factors of 128 rows/columns (A/B matrix).
  // 4 is chosen to make consecutive 32bits of data to have scale factors for only a single row (col). 32bits corresponds to the TMEM word size 
  using Blk_MN    = typename Sm1xxBlkScaledConfig::Blk_MN;
  using Blk_SF    = typename Sm1xxBlkScaledConfig::Blk_SF;
  using Blk_Elems = decltype(Blk_MN{} * Blk_SF{});

  // Basic storage block for new Scaling Factor Layouts
  using mnBasicBlockShape  = Shape<_32,_4>;
  using mnBasicBlockStride = Stride<_16,_4>;
  using kBasicBlockShape   = Shape<Int<SFVectorSize>, Int<MMA_NSF>>;
  using kBasicBlockStride  = Stride<_0,_1>;

  using sSFA_shapeM   = decltype(prepend(size<0>(TileShape_MNK{}) / Blk_MN{}, mnBasicBlockShape{}));
  using sSF_strideMN  = decltype(prepend(Blk_Elems{}, mnBasicBlockStride{}));
  using sSFA_strideM  = sSF_strideMN;
  using sSF_shapeK    = decltype(prepend(make_shape(Blk_SF{} / Int<MMA_NSF>{}, size<2>(TileShape_MNK{}) / Int<SFVectorSize>{} / Blk_SF{}), kBasicBlockShape{}));

  using sSFA_strideK  = decltype(prepend(make_stride(Int<MMA_NSF>{}, size<0>(TileShape_MNK{}) / Blk_MN{} * Blk_Elems{}), kBasicBlockStride{}));
  using sSFA_shape    = decltype(make_shape(sSFA_shapeM{}, sSF_shapeK{}));
  using sSFA_stride   = decltype(make_stride(sSFA_strideM{}, sSFA_strideK{}));
  using SmemLayoutAtomSFA = decltype(make_layout(sSFA_shape{}, sSFA_stride{}));

  using sSFB0_shapeN   = decltype(prepend(size<1>(TileShape_MNK{}) / Blk_MN{}, mnBasicBlockShape{}));
  using sSFB0_strideN  = sSF_strideMN;
  using sSFB0_strideK  = decltype(prepend(make_stride(Int<MMA_NSF>{}, size<1>(TileShape_MNK{}) / Blk_MN{} * Blk_Elems{}), kBasicBlockStride{}));
  using sSFB1_shapeN   = decltype(prepend(size<1>(TileShape_MNK{}) / Blk_MN{}, mnBasicBlockShape{}));
  using sSFB1_strideN  = sSF_strideMN;
  using sSFB1_strideK  = decltype(prepend(make_stride(Int<MMA_NSF>{}, size<1>(TileShape_MNK{}) / Blk_MN{} * Blk_Elems{}), kBasicBlockStride{}));
  using sSFB0_shape    = decltype(make_shape(sSFB0_shapeN{}, sSF_shapeK{}));
  using sSFB0_stride   = decltype(make_stride(sSFB0_strideN{}, sSFB0_strideK{}));
  using sSFB1_shape    = decltype(make_shape(sSFB1_shapeN{}, sSF_shapeK{}));
  using sSFB1_stride   = decltype(make_stride(sSFB1_strideN{}, sSFB1_strideK{}));
  using SmemLayoutAtomSFB0 = decltype(make_layout(sSFB0_shape{}, sSFB0_stride{}));
  using SmemLayoutAtomSFB1 = decltype(make_layout(sSFB1_shape{}, sSFB1_stride{}));

  using SmemLayoutAtomsA = decltype(cute::make_tuple(SmemLayoutAtomA{}, SmemLayoutAtomSFA{}));
  using SmemLayoutAtomsB0 = decltype(cute::make_tuple(SmemLayoutAtomB0{}, SmemLayoutAtomSFB0{}));
  using SmemLayoutAtomsB1 = decltype(cute::make_tuple(SmemLayoutAtomB1{}, SmemLayoutAtomSFB1{}));

  static constexpr int PipelineStages = cutlass::gemm::collective::detail::sm100_compute_stage_count_or_override_blockscaled<
    detail::sm120_smem_capacity_bytes, SmemAllocTypeA, SmemAllocTypeB, TileShape_MNK, SmemLayoutAtomSFA, SmemLayoutAtomSFB0>(StageCountType{});

  static constexpr uint32_t SchedulerPipelineStageCount = 3;      
  
  // Strides and interleaved SF layouts
  using StrideA  = cutlass::gemm::TagToStrideA_t<GmemLayoutATag>;
  using StrideB0 = cutlass::gemm::TagToStrideB_t<GmemLayoutB0Tag>;
  using StrideB1 = cutlass::gemm::TagToStrideB_t<GmemLayoutB1Tag>;
  using InternalStrideA   = cute::remove_pointer_t<StrideA>;
  using InternalStrideB0  = cute::remove_pointer_t<StrideB0>;
  using InternalStrideB1  = cute::remove_pointer_t<StrideB1>;
  using InternalLayoutSFA  = decltype(Sm1xxBlkScaledConfig::deduce_layoutSFA());
  using InternalLayoutSFB0 = decltype(Sm1xxBlkScaledConfig::deduce_layoutSFB());
  using InternalLayoutSFB1 = decltype(Sm1xxBlkScaledConfig::deduce_layoutSFB());
  using LayoutSFA = cute::conditional_t<cute::is_same_v<InternalStrideA, StrideA>, InternalLayoutSFA, InternalLayoutSFA*>;
  using LayoutSFB0 = cute::conditional_t<cute::is_same_v<InternalStrideB0, StrideB0>, InternalLayoutSFB0, InternalLayoutSFB0*>;
  using LayoutSFB1 = cute::conditional_t<cute::is_same_v<InternalStrideB1, StrideB1>, InternalLayoutSFB1, InternalLayoutSFB1*>;
  using StridePairA = decltype(cute::make_tuple(StrideA{}, LayoutSFA{}));
  using StridePairB0 = decltype(cute::make_tuple(StrideB0{}, LayoutSFB0{}));
  using StridePairB1 = decltype(cute::make_tuple(StrideB1{}, LayoutSFB1{}));

  using DispatchPolicy = DualMainloopSm120TmaWarpSpecializedBlockScaled<
      PipelineStages,
      SchedulerPipelineStageCount,
      ClusterShape_MNK,
      KernelScheduleType>;

  using CollectiveOp = DualCollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      cute::tuple<ElementA, ElementSF>,
      StridePairA,
      cute::tuple<ElementB, ElementSF>,
      StridePairB0,
      StridePairB1,
      TiledMma,
      GmemTiledCopyPairA,
      SmemLayoutAtomsA,
      SmemCopyAtomsA,
      cute::identity,
      GmemTiledCopyPairB0,
      SmemLayoutAtomsB0,
      SmemCopyAtomsB0,
      cute::identity,
      GmemTiledCopyPairB1,
      SmemLayoutAtomsB1,
      SmemCopyAtomsB1,
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
