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

template <typename ElementA, typename ElementB>
struct TypeWidths {
  static constexpr bool IsElementALarger = (cute::sizeof_bits_v<ElementA>) > cute::sizeof_bits_v<ElementB>;
  using WideType   = cute::conditional_t<IsElementALarger, ElementA, ElementB>;                               
  using NarrowType = cute::conditional_t<IsElementALarger, ElementB, ElementA>;
};


template <class ElementA, class ElementB>
constexpr bool
is_different_width_operands() {
  return cute::sizeof_bits_v<ElementA> != cute::sizeof_bits_v<ElementB>;
}

template <class ElementA, class LayoutA, class ElementB, class LayoutB>
constexpr bool
is_valid_mixed_operand() {
  using Widths = TypeWidths<ElementA, ElementB>;
  using NarrowType = typename Widths::NarrowType;
  using WideType = typename Widths::WideType;

  constexpr bool IsANarrow = cute::is_same_v<NarrowType, ElementA>;
  constexpr cute::GMMA::Major NarrowGmmaMajor = IsANarrow ? detail::gmma_rs_tag_to_major_A<LayoutA>() : 
                                                            detail::gmma_rs_tag_to_major_B<LayoutB>();

  constexpr bool IsDifferentWidthOperands = is_different_width_operands<ElementA, ElementB>();

  constexpr bool WidthsValidForCast = ( cute::sizeof_bits_v<WideType> == 16 ) &&
                                      ( cute::sizeof_bits_v<NarrowType> == 8 ||
                                        cute::sizeof_bits_v<NarrowType> == 4  );

  constexpr bool IsNarrowLayoutKMajor = NarrowGmmaMajor == cute::GMMA::Major::K;

  static_assert(IsDifferentWidthOperands, "Operands must be of different widths");
  static_assert(WidthsValidForCast, "Narrow type must be 4/8 bits and wide type must be 16 bits");
  static_assert(IsNarrowLayoutKMajor, "Narrow type must be K major.");

  return IsDifferentWidthOperands && WidthsValidForCast && IsNarrowLayoutKMajor;
}

template <class ElementA, class ElementB, MixedInputCastDirection CastDirection>
constexpr bool
is_swapAB() {
  // If we want to upcast and the wider type is in A, we must swap A and B to make sure the narrow
  // type ends up in registers.
  constexpr bool SwapForUpcast = (CastDirection == MixedInputCastDirection::NARROW_TO_WIDE) &&
                                 (cute::sizeof_bits_v<ElementA>) > cute::sizeof_bits_v<ElementB>;
  
  // If we want to downcast and the narrow type in in A, we must swap A and B to ensure the wide type 
  // ends up in registers.
  constexpr bool SwapForDowncast = (CastDirection == MixedInputCastDirection::WIDE_TO_NARROW) &&
                                   (cute::sizeof_bits_v<ElementB>) > cute::sizeof_bits_v<ElementA>;

  return SwapForUpcast || SwapForDowncast;
}

template <class ElementA, class LayoutA, class ElementB, class LayoutB, class KernelScheduleType>
constexpr bool
is_mixed_warpspecialized_transpose_B() {

  using Widths = TypeWidths<ElementA, ElementB>;
  using WideType = typename Widths::WideType;
  static_assert(sizeof(WideType) == 2, "The wide type must be 2 bytes. WS transpose disabled.");

  // constexpr bool IsWarpSpecialized = cute::is_base_of_v<KernelTmaWarpSpecialized, KernelScheduleType>         ||
  //                                    cute::is_base_of_v<KernelTmaWarpSpecializedPingpong, KernelScheduleType> ||
  //                                    cute::is_base_of_v<KernelTmaWarpSpecializedCooperative, KernelScheduleType>;
  return false;
}

// Extract all MMA information needed for mixed types. 
template <typename ElementA, typename ElementB, MixedInputCastDirection CastDirection>
struct MixedMmaInfo {

  static_assert(cute::sizeof_bits_v<ElementA> != cute::sizeof_bits_v<ElementB>, 
    "Operand width must be different to used the mixed input collective.");

  using Widths = TypeWidths<ElementA, ElementB>;
  using WideType   = typename Widths::WideType;                         
  using NarrowType = typename Widths::NarrowType;

  static constexpr bool IsUpcast = CastDirection == MixedInputCastDirection::NARROW_TO_WIDE;
  static_assert(IsUpcast, "Only upcasting is currently supported");
  using ConverterSrcType = cute::conditional_t<IsUpcast, NarrowType, WideType>;
  using ConverterDstType = cute::conditional_t<IsUpcast, WideType, NarrowType>;

  static_assert(sizeof(ConverterDstType) == 2, "Mixed input MMA only supports 2 byte B operand.");
  // Mma must run using the type after conversion, since A and B will now be the same type.
  using MmaElementA = ConverterDstType;
  using MmaElementB = ConverterDstType;
};

}

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_MIXED_TMA_WS_RS
template <
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int AlignmentB,
  class ElementScale,
  class GmemLayoutScale,
  int AlignmentScale,
  MixedInputCastDirection CastDirection,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct MixedInputCollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementScale,
    GmemLayoutScale,
    AlignmentScale,
    CastDirection,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      (cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecialized> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedPingpong> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperative>) &&
      detail::is_valid_mixed_operand<ElementA, GmemLayoutA, ElementB, GmemLayoutB>()> 
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
  static constexpr bool SwapAB = detail::is_swapAB<ElementA, ElementB, CastDirection>();
  static constexpr bool IsWarpSpecializedTransposeB = detail::is_mixed_warpspecialized_transpose_B<
      ElementA, GmemLayoutA, ElementB, GmemLayoutB, KernelScheduleType>();


  using MmaInfo = detail::MixedMmaInfo<ElementA, ElementB, CastDirection>;

  using MmaElementA = typename MmaInfo::MmaElementA;
  using MmaElementB = typename MmaInfo::MmaElementB;

  using AtomLayoutMNK = cute::conditional_t<cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperative>,
      Layout<Shape<_2,_1,_1>>, Layout<Shape<_1,_1,_1>>>;

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::rs_op_selector<
      MmaElementA, MmaElementB, ElementAccumulator, TileShape_MNK, GMMA::Major::K, GMMA::Major::K>(), AtomLayoutMNK{}));

  using GmemTiledCopyA = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<1>(ClusterShape_MNK{})));
  using GmemTiledCopyB = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));

  using SmemLayoutAtomA = decltype(detail::rs_smem_selector<GmmaMajorA, ElementA,
      decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), IsWarpSpecializedTransposeB>());
  using SmemLayoutAtomB = decltype(detail::rs_smem_selector<GmmaMajorB, ElementB,
      decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), IsWarpSpecializedTransposeB>());

  static constexpr int PipelineStages = detail::compute_stage_count_or_override<detail::sm90_smem_capacity_bytes,
      typename MmaInfo::ConverterSrcType, typename MmaInfo::ConverterDstType, TileShape_MNK>(StageCountType{});

  using DispatchPolicy = MainloopSm90TmaGmmaRmemAWarpSpecialized<
      PipelineStages, ClusterShape_MNK, KernelScheduleType>;

  using SmemCopyAtomA = cute::conditional_t<SwapAB, void, Copy_Atom<cute::DefaultCopy, ElementA>>;
  using SmemCopyAtomB = cute::conditional_t<SwapAB, Copy_Atom<cute::DefaultCopy, ElementB>, void>;

  // If the src type of the converter is the same as ElementA, interpret as we want to apply
  // the scale to the A matrix.
  using StrideScale = cute::conditional_t<cute::is_same_v<typename MmaInfo::ConverterSrcType, ElementA>,
                                          TagToStrideA_t<GmemLayoutScale>, TagToStrideB_t<GmemLayoutScale>>;


  // All scale info is void for now since it is not actually used.
  using CollectiveOp = MixedInputCollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      TagToStrideA_t<GmemLayoutA>,
      ElementB,
      TagToStrideB_t<GmemLayoutB>,
      ElementScale,
      StrideScale,
      CastDirection,
      TiledMma,
      GmemTiledCopyA,
      SmemLayoutAtomA,
      SmemCopyAtomA,
      cute::identity,
      GmemTiledCopyB,
      SmemLayoutAtomB,
      SmemCopyAtomB,
      cute::identity,
      void,
      void,
      void,
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA auto kernel schedule
// GMMA_MIXED_TMA_WS_RS
template <
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int AlignmentB,
  class ElementScale,
  class GmemLayoutScale,
  int AlignmentScale,
  MixedInputCastDirection CastDirection,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct MixedInputCollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementScale,
    GmemLayoutScale,
    AlignmentScale,
    CastDirection,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    cute::enable_if_t<
      cute::is_same_v<KernelScheduleType, KernelScheduleAuto>> 
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA> == 0, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif

static constexpr bool IsTmaCompatible = detail::is_aligned<
    ElementA, AlignmentA, ElementB, AlignmentB, detail::tma_alignment_bytes>();

static_assert(IsTmaCompatible, "Only TMA kernels supported for Mixed dtype");
#if ((__CUDACC_VER_MAJOR__ > 12) || ((__CUDACC_VER_MAJOR__ == 12) && (__CUDACC_VER_MINOR__ >= 1)))
  // Persistent schedules perform best for CUDA Toolkits with version >= 12.1
  // KernelTmaWarpSpecializedCooperative requires TileShape_M to be at least 128
  using KernelWarpSpecializedSchedule = cute::conditional_t<size<0>(TileShape_MNK{}) == Int<64>{},
      KernelTmaWarpSpecializedPingpong, KernelTmaWarpSpecializedCooperative>;
#else
  using KernelWarpSpecializedSchedule = KernelTmaWarpSpecialized;
#endif

  using CollectiveOp = typename MixedInputCollectiveBuilder<
      arch::Sm90,
      arch::OpClassTensorOp,
      ElementA,
      GmemLayoutA,
      AlignmentA,
      ElementB,
      GmemLayoutB,
      AlignmentB,
      ElementScale,
      GmemLayoutScale,
      AlignmentScale,
      CastDirection,
      ElementAccumulator,
      TileShape_MNK,
      ClusterShape_MNK,
      StageCountType,
      cute::conditional_t<IsTmaCompatible, KernelWarpSpecializedSchedule, KernelMultistage>
    >::CollectiveOp;
};
} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////