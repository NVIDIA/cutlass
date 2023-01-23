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
#include "cute/atom/mma_traits_sm90_gmma.hpp"
#include "cute/atom/copy_traits_sm90_tma.hpp"

// SM90 Collective Builders should be used only starting CUDA 12.0
#if (__CUDACC_VER_MAJOR__ >= 12)
#define CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

//
// Some named constants
//
constexpr int tma_alignment_bytes = 16;
constexpr int cp_async_min_alignment_bytes = 4;
constexpr int sm90_smem_capacity_bytes = 232448;

// Maps 2.x A matrix layout tag to respective GMMA major mode enum
template <class ElementA, class LayoutA>
constexpr cute::GMMA::Major
tag_to_gmma_major_A() {
  // MN major mode is only valid for non-TF32 and non-int MMAs
  if constexpr (std::is_same_v<LayoutA, cutlass::layout::ColumnMajor> &&
                not std::is_same_v<ElementA, tfloat32_t> &&
                not std::is_same_v<ElementA, int8_t> &&
                not std::is_same_v<ElementA, uint8_t>) {
    return cute::GMMA::Major::MN;
  }
  else {
    return cute::GMMA::Major::K;
  }
}

// Maps 2.x B matrix layout tag to respective GMMA major mode enum
template <class ElementB, class LayoutB>
constexpr cute::GMMA::Major
tag_to_gmma_major_B() {
  // MN major mode is only valid for non-TF32 and non-int MMAs
  if constexpr (std::is_same_v<LayoutB, cutlass::layout::RowMajor> &&
                not std::is_same_v<ElementB, tfloat32_t> &&
                not std::is_same_v<ElementB, int8_t> &&
                not std::is_same_v<ElementB, uint8_t>) {
    return cute::GMMA::Major::MN;
  }
  else {
    return cute::GMMA::Major::K;
  }
}

// Maps a rank-1 cute::Shape<> representing the cluster shape on to the TMA atom that should be used with it
template <class UnimodalClusterShape>
constexpr auto
cluster_shape_to_tma_atom(UnimodalClusterShape unimodal_cluster_shape) {
  static_assert(cute::rank(unimodal_cluster_shape) == 1,
    "Use this function to figure out TMA for each mode individually.");

  if constexpr (cute::size(unimodal_cluster_shape) == 1) {
    return cute::SM90_TMA_LOAD{};
  }
  else {
    return cute::SM90_TMA_LOAD_MULTICAST{};
  }
}

// Generates the most efficient possible TiledCopy with cp.async copy atom given a set of parameters.
template<int ThreadCount, class Element, int Alignment, class StrideType, class TileMN, class TileK>
constexpr auto
make_cp_async_gmem_tiled_copy() {
  using AlignmentType = cute::uint_byte_t<static_cast<int>(sizeof(Element)) * Alignment>;
  constexpr int TileSizeMN  = cute::size(TileMN{});
  constexpr int TileSizeK   = cute::size(TileK{});

  // Maximize the number of threads along the gmem major mode to promote coalesced reads
  // While making sure our thread layout tiles the threadblock tile evenly
  if constexpr (cute::size<1>(StrideType{}) == 1) {
    // K major thread layout for K major gmem
    constexpr int threads_major = TileSizeK   / Alignment;
    constexpr int threads_minor = ThreadCount / threads_major;
    static_assert(threads_major > 0);
    static_assert(ThreadCount % threads_major == 0);
    static_assert(threads_minor == 0 || (TileSizeMN % threads_minor == 0));
    return make_tiled_copy(
      Copy_Atom<SM80_CP_ASYNC_CACHEALWAYS<AlignmentType>, Element>{},
      Layout<Shape <Int<threads_minor>,Int<threads_major>>,
             Stride<Int<threads_major>,                _1>>{},
      Layout<Shape<_1,Int<Alignment>>>{});
  }
  else if constexpr (cute::size<0>(StrideType{}) == 1) {
    // MN major thread layout for MN major gmem
    constexpr int threads_major = TileSizeMN  / Alignment;
    constexpr int threads_minor = ThreadCount / threads_major;
    static_assert(threads_major > 0);
    static_assert(ThreadCount % threads_major == 0);
    static_assert(threads_minor == 0 || (TileSizeK % threads_minor == 0));
    return make_tiled_copy(
      Copy_Atom<SM80_CP_ASYNC_CACHEALWAYS<AlignmentType>, Element>{},
      Layout<Shape <Int<threads_major>,Int<threads_minor>>,
             Stride<                _1,Int<threads_major>>>{},
      Layout<Shape<Int<Alignment>,_1>>{});
  }
  else {
    static_assert(std::is_void_v<Element>, "Unsupported gmem layout for automatic gmem tiled copy builder.");
  }
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<int CapacityBytes, class ElementA, class ElementB, class TileShapeMNK, class StageCountType>
constexpr int
compute_stage_count_or_override(int KernelSmemCarveout = 0) {
  if constexpr (std::is_same_v<StageCountType, StageCountAuto>) {
    // 32 bytes to account for barriers etc.
    constexpr int stage_barrier_bytes = 32;
    constexpr int a_bytes = static_cast<int>(sizeof(ElementA));
    constexpr int b_bytes = static_cast<int>(sizeof(ElementB));
    constexpr int stage_bytes =
      (a_bytes * size<0>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
      (b_bytes * size<1>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
      stage_barrier_bytes;

    return (CapacityBytes - KernelSmemCarveout) / stage_bytes;
  }
  else {
    return StageCountType::value;
  }
}

// Kernel policy selection logic: auto dispatches to KernelTmaWarpSpecialized for now. Subject to change.
template <
  class ElementA,
  class ElementB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
constexpr auto
generate_gmma_dispatch_policy() {
  if constexpr      (std::is_base_of_v<KernelTmaWarpSpecialized, KernelScheduleType> or
                     std::is_same_v<KernelScheduleAuto, KernelScheduleType>) {
    constexpr int PipelineStages = compute_stage_count_or_override<
        sm90_smem_capacity_bytes, ElementA, ElementB, TileShape_MNK, StageCountType>();

    if constexpr (std::is_same_v<KernelScheduleType, KernelScheduleAuto> or
                  std::is_same_v<KernelScheduleType, KernelTmaWarpSpecialized>) {
      return MainloopSm90TmaGmmaWarpSpecialized<PipelineStages, ClusterShape_MNK, KernelTmaWarpSpecialized>{};
    }
    else {
      static_assert(sizeof(ElementA) == 0, "Invalid kernel schedule type.");
    }
  }

  else if constexpr (std::is_base_of_v<KernelTmaWarpSpecializedPersistent, KernelScheduleType>) {
    // For the persistent kernel, assume that the epilogue uses 1 MN tile worth of smem
    constexpr int EpilogueTileCarveout = sizeof(ElementAccumulator) *
        (size<0>(TileShape_MNK{}) * size<1>(TileShape_MNK{}));
    constexpr int PipelineStages = compute_stage_count_or_override<
        sm90_smem_capacity_bytes, ElementA, ElementB, TileShape_MNK, StageCountType>(EpilogueTileCarveout);

    if constexpr (std::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedPersistent>) {
      return MainloopSm90TmaGmmaWarpSpecialized<PipelineStages, ClusterShape_MNK, KernelTmaWarpSpecializedPersistent>{};
    }
    else {
      static_assert(sizeof(ElementA) == 0, "Invalid kernel schedule type.");
    }
  }

  else if constexpr (std::is_base_of_v<KernelTma, KernelScheduleType>) {
    constexpr int PipelineStages = compute_stage_count_or_override<
        sm90_smem_capacity_bytes, ElementA, ElementB, TileShape_MNK, StageCountType>();

    return MainloopSm90TmaGmma<PipelineStages, ClusterShape_MNK>{};
  }

  else {
    static_assert(sizeof(ElementA) == 0, "Invalid kernel schedule type.");
  }
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_TMA_SS
template <
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    std::enable_if_t<
      // TMA requires alignment be 16 bytes
      ((sizeof(ElementA) * AlignmentA) % detail::tma_alignment_bytes == 0)  &&
      ((sizeof(ElementB) * AlignmentB) % detail::tma_alignment_bytes == 0)  &&
      not std::is_same_v<KernelScheduleType, KernelMultistage>              &&
      // dispatch TN tf32 and int8 kernels only to TMA builder
      ((sizeof(ElementA) == 2 && sizeof(ElementB) == 2)                     ||
       (std::is_same_v<GmemLayoutA, layout::RowMajor> && std::is_same_v<GmemLayoutB, layout::ColumnMajor>))>
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);

  #ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
    static_assert(sizeof(ElementA) == 0, "Unsupported Toolkit for SM90 Collective Builder\n");
  #endif

  // For fp32 types, map to tf32 MMA value type
  using MmaElementA = std::conditional_t<std::is_same_v<ElementA, float>, tfloat32_t, ElementA>;
  using MmaElementB = std::conditional_t<std::is_same_v<ElementB, float>, tfloat32_t, ElementB>;

  static constexpr cute::GMMA::Major GmmaMajorA = detail::tag_to_gmma_major_A<MmaElementA, GmemLayoutA>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::tag_to_gmma_major_B<MmaElementB, GmemLayoutB>();

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::ss_op_selector<
      MmaElementA, MmaElementB, ElementAccumulator, TileShape_MNK, GmmaMajorA, GmmaMajorB>()));

  using GmemTiledCopyA = decltype(detail::cluster_shape_to_tma_atom(shape<1>(ClusterShape_MNK{})));
  using GmemTiledCopyB = decltype(detail::cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));

  using SmemLayoutAtomA = decltype(cute::GMMA::smem_selector<
      GmmaMajorA, MmaElementA, decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))
    >());
  using SmemLayoutAtomB = decltype(cute::GMMA::smem_selector<
      GmmaMajorB, MmaElementB, decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))
    >());

  using DispatchPolicy = decltype(detail::generate_gmma_dispatch_policy<
      MmaElementA, MmaElementB, ElementAccumulator, TileShape_MNK, ClusterShape_MNK, StageCountType, KernelScheduleType>());

  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      TagToStrideA_t<GmemLayoutA>,
      ElementB,
      TagToStrideB_t<GmemLayoutB>,
      TiledMma,
      GmemTiledCopyA,
      SmemLayoutAtomA,
      void, // GMMA_SS does not need an SmemCopyAtom
      cute::identity,
      GmemTiledCopyB,
      SmemLayoutAtomB,
      void, // GMMA_SS does not need an SmemCopyAtom
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_CpAsync_SS
template <
  class ElementA,
  class GmemLayoutA,
  int AlignmentA,
  class ElementB,
  class GmemLayoutB,
  int AlignmentB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  class StageCountType,
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassTensorOp,
    ElementA,
    GmemLayoutA,
    AlignmentA,
    ElementB,
    GmemLayoutB,
    AlignmentB,
    ElementAccumulator,
    TileShape_MNK,
    ClusterShape_MNK,
    StageCountType,
    KernelScheduleType,
    std::enable_if_t<
      // Even if we could build a TMA kernel, let the user override and use cp_async instead
      std::is_same_v<KernelScheduleType, KernelMultistage>                  ||
      // But always guard against invalid TMA alignments and dispatch to cp_async
      ((sizeof(ElementA) * AlignmentA) % detail::tma_alignment_bytes != 0)  ||
      ((sizeof(ElementB) * AlignmentB) % detail::tma_alignment_bytes != 0)  ||
      // dispatch non-TN tf32 and int8 kernels only to cp_async builder
      ((sizeof(ElementA) != 2 || sizeof(ElementB) != 2)                     &&
       (not std::is_same_v<GmemLayoutA, layout::RowMajor> || not std::is_same_v<GmemLayoutB, layout::ColumnMajor>))>
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);

  #ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
    static_assert(sizeof(ElementA) == 0, "Unsupported Toolkit for SM90 Collective Builder\n");
  #endif

  // For fp32 types, map to tf32 MMA value type
  using MmaElementA = std::conditional_t<std::is_same_v<ElementA, float>, tfloat32_t, ElementA>;
  using MmaElementB = std::conditional_t<std::is_same_v<ElementB, float>, tfloat32_t, ElementB>;

  static_assert((sizeof(ElementA) * AlignmentA) % detail::cp_async_min_alignment_bytes == 0 and
                (sizeof(ElementB) * AlignmentB) % detail::cp_async_min_alignment_bytes == 0,
                "Minimum alignment required for cp.async is 4B.");

  static constexpr cute::GMMA::Major GmmaMajorA = detail::tag_to_gmma_major_A<ElementA, GmemLayoutA>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::tag_to_gmma_major_B<ElementB, GmemLayoutB>();

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::ss_op_selector<
      MmaElementA, MmaElementB, ElementAccumulator, TileShape_MNK, GmmaMajorA, GmmaMajorB>()));

  using GmemTiledCopyA = decltype(detail::make_cp_async_gmem_tiled_copy<
      128, ElementA, AlignmentA, TagToStrideA_t<GmemLayoutA>,
      decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  using GmemTiledCopyB = decltype(detail::make_cp_async_gmem_tiled_copy<
      128, ElementB, AlignmentB, TagToStrideB_t<GmemLayoutB>,
      decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  using SmemLayoutAtomA = decltype(cute::GMMA::smem_selector<
      GmmaMajorA, MmaElementA, decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))
    >());

  using SmemLayoutAtomB = decltype(cute::GMMA::smem_selector<
      GmmaMajorB, MmaElementB, decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))
    >());

  static constexpr int PipelineStages = detail::compute_stage_count_or_override<
      detail::sm90_smem_capacity_bytes, MmaElementA, MmaElementB, TileShape_MNK, StageCountType>();

  using CollectiveOp = CollectiveMma<
      MainloopSm90CpAsyncGmma<PipelineStages, ClusterShape_MNK>,
      TileShape_MNK,
      ElementA,
      TagToStrideA_t<GmemLayoutA>,
      ElementB,
      TagToStrideB_t<GmemLayoutB>,
      TiledMma,
      GmemTiledCopyA,
      SmemLayoutAtomA,
      void, // GMMA_SS does not need an SmemCopyAtom
      cute::identity,
      GmemTiledCopyB,
      SmemLayoutAtomB,
      void, // GMMA_SS does not need an SmemCopyAtom
      cute::identity
    >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
