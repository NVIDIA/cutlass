/***************************************************************************************************
 * Copyright (c) 2024 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include "cutlass/gemm/collective/builders/sm90_sparse_config.inl"

// SM90 Collective Builders should be used only starting CUDA 12.0
#if (__CUDACC_VER_MAJOR__ >= 12)
#define CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<int CapacityBytes, class ElementAMma, class ElementB, class ElementEMma, class TileShapeMNK, int stages>
constexpr int
compute_stage_count_or_override_sparse(StageCount<stages> stage_count) {
  return stages;
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<int CapacityBytes, class ElementAMma, class ElementB, class ElementEMma, class TileShapeMNK, int stages>
constexpr int
compute_stage_count_or_override_sparse(cute::Int<stages> stage_count) {
  return stages;
}

// Returns the maximum number of smem tiles that can be used with a given smem capacity, or overrides with manual count. 
template<int CapacityBytes, class ElementAMma, class ElementB, class ElementEMma, class TileShapeMNK, int carveout_bytes>
constexpr int
compute_stage_count_or_override_sparse(StageCountAutoCarveout<carveout_bytes> stage_count) {
  constexpr auto mainloop_pipeline_bytes = sizeof(typename cutlass::PipelineTmaAsync<1>::SharedStorage);
  constexpr auto a_bits = cute::sizeof_bits_v<ElementAMma>;
  constexpr auto b_bits = cute::sizeof_bits_v<ElementB>;
  constexpr auto e_bits = cute::sizeof_bits_v<ElementEMma>;
  constexpr int stage_bytes =
    cutlass::bits_to_bytes(a_bits * size<0>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    cutlass::bits_to_bytes(b_bits * size<1>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    cutlass::bits_to_bytes(e_bits * size<0>(TileShapeMNK{}) * size<2>(TileShapeMNK{})) +
    static_cast<int>(mainloop_pipeline_bytes);

  return (CapacityBytes - carveout_bytes) / stage_bytes;
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

// GMMA_TMA_WS_SS_SPARSE
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
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassSparseTensorOp,
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
    KernelScheduleType,
    cute::enable_if_t<
      (cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecialized> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedPingpong> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperative>) &&
       not detail::is_use_rmem_A<ElementA, GmemLayoutATag, ElementB, GmemLayoutBTag>()>
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA>, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif
  static_assert(detail::is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, detail::tma_alignment_bytes>(),
                "Should meet TMA alignment requirement\n");

  static constexpr bool IsFP8Input = detail::is_input_fp8<ElementA, ElementB>();
  static_assert(!IsFP8Input, "FP8 sparse collective currently only supports FastAccum schedules");

  // For fp32 types, map to tf32 MMA value type
  using ElementAMmaRaw = cute::conditional_t<cute::is_same_v<ElementA, float>, tfloat32_t, ElementA>;
  using ElementBMma    = cute::conditional_t<cute::is_same_v<ElementB, float>, tfloat32_t, ElementB>;

  static constexpr cute::GMMA::Major GmmaMajorA = detail::gmma_ss_tag_to_major_A<ElementAMmaRaw, GmemLayoutATag>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::gmma_ss_tag_to_major_B<ElementBMma, GmemLayoutBTag>();

  using AtomLayoutMNK = cute::conditional_t<
      cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperative>,
      Layout<Shape<_2,_1,_1>>, Layout<Shape<_1,_1,_1>>>;

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::ss_op_selector_sparse<
      ElementAMmaRaw, ElementBMma, ElementAccumulator, TileShape_MNK, GmmaMajorA, GmmaMajorB>(), AtomLayoutMNK{}));

  using ElementAMma = typename TiledMma::ValTypeA;
  using ElementAMmaSparsity = Int<ElementAMma::sparsity>;
  using ElementEMma = typename TiledMma::ValTypeE;
  using SparseConfig = cutlass::Sm90GemmSparseConfig<ElementAMma, GmmaMajorA, ElementEMma, 
                                                     decltype(cute::min(size<2>(TileShape_MNK{}),_128{}))>;

  using LayoutA = decltype(SparseConfig::deduce_layoutA());
  using LayoutE = decltype(SparseConfig::deduce_layoutE());
  using LayoutPairAE = decltype(cute::make_tuple(LayoutA{}, LayoutE{}));

  using GmemTiledCopyA = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<1>(ClusterShape_MNK{})));
  using GmemTiledCopyB = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));

  using SmemLayoutAtomA = decltype(detail::ss_smem_selector_sparse<
      GmmaMajorA, ElementAMmaRaw, decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), ElementAMmaSparsity>());
  using SmemLayoutAtomB = decltype(detail::ss_smem_selector<
      GmmaMajorB, ElementBMma, decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  static constexpr int PipelineStages = detail::compute_stage_count_or_override_sparse<detail::sm90_smem_capacity_bytes,
      ElementAMma, ElementBMma, ElementEMma, TileShape_MNK>(StageCountType{});
  using DispatchPolicy = MainloopSm90TmaGmmaWarpSpecializedSparse<PipelineStages, ClusterShape_MNK, KernelScheduleType>;

  using SmemCopyAtomA = void; 
  using SmemCopyAtomB = void; 

  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      LayoutPairAE,
      ElementB,
      TagToStrideB_t<GmemLayoutBTag>,
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

// GMMA_TMA_WS_SS_FP8_FAST_ACCUM_SPARSE
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
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassSparseTensorOp,
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
    KernelScheduleType,
    cute::enable_if_t<
      (cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedFP8FastAccum> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedPingpongFP8FastAccum> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperativeFP8FastAccum>)>
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
  static_assert(detail::is_aligned<ElementA, AlignmentA, ElementB, AlignmentB, detail::tma_alignment_bytes>(),
                "Should meet TMA alignment requirement\n");
  static_assert(detail::is_input_fp8<ElementA, ElementB>(),
                "Only FP8 datatypes are compatible with these kernel schedules\n");
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA>, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif

  static constexpr cute::GMMA::Major GmmaMajorA = detail::gmma_ss_tag_to_major_A<ElementA, GmemLayoutATag>();
  static constexpr cute::GMMA::Major GmmaMajorB = detail::gmma_ss_tag_to_major_B<ElementB, GmemLayoutBTag>();

  using AtomLayoutMNK = cute::conditional_t<
      cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperativeFP8FastAccum>,
      Layout<Shape<_2,_1,_1>>, Layout<Shape<_1,_1,_1>>>;

  using TiledMma = decltype(cute::make_tiled_mma(cute::GMMA::ss_op_selector_sparse<
      ElementA, ElementB, ElementAccumulator, TileShape_MNK, GmmaMajorA, GmmaMajorB>(), AtomLayoutMNK{}));

  using ElementAMma = typename TiledMma::ValTypeA;
  using ElementAMmaSparsity = Int<ElementAMma::sparsity>;
  using ElementEMma = typename TiledMma::ValTypeE;
  using SparseConfig = cutlass::Sm90GemmSparseConfig<ElementAMma, GmmaMajorA, ElementEMma, 
                                                     decltype(cute::min(size<2>(TileShape_MNK{}),_128{}))>;

  using LayoutA = decltype(SparseConfig::deduce_layoutA());
  using LayoutE = decltype(SparseConfig::deduce_layoutE());
  using LayoutPairAE = decltype(cute::make_tuple(LayoutA{}, LayoutE{}));

  using GmemTiledCopyA = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<1>(ClusterShape_MNK{})));
  using GmemTiledCopyB = decltype(detail::sm90_cluster_shape_to_tma_atom(shape<0>(ClusterShape_MNK{})));

  using SmemLayoutAtomA = decltype(detail::ss_smem_selector_sparse<
      GmmaMajorA, ElementA, decltype(cute::get<0>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{})), ElementAMmaSparsity>());
  using SmemLayoutAtomB = decltype(detail::ss_smem_selector<
      GmmaMajorB, ElementB, decltype(cute::get<1>(TileShape_MNK{})), decltype(cute::get<2>(TileShape_MNK{}))>());

  static constexpr int PipelineStages = detail::compute_stage_count_or_override_sparse<detail::sm90_smem_capacity_bytes,
      ElementAMma, ElementB, ElementEMma, TileShape_MNK>(StageCountType{});
  using DispatchPolicy = MainloopSm90TmaGmmaWarpSpecializedSparse<PipelineStages, ClusterShape_MNK, KernelScheduleType>;

  using SmemCopyAtomA = void; 
  using SmemCopyAtomB = void; 

  using CollectiveOp = CollectiveMma<
      DispatchPolicy,
      TileShape_MNK,
      ElementA,
      LayoutPairAE,
      ElementB,
      TagToStrideB_t<GmemLayoutBTag>,
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

// GMMA_TMA_WS_RS_SPARSE
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
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassSparseTensorOp,
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
    KernelScheduleType,
    cute::enable_if_t<
      (cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecialized> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedPingpong> ||
       cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedCooperative>) &&
       detail::is_use_rmem_A<ElementA, GmemLayoutATag, ElementB, GmemLayoutBTag>()>
> {
  static_assert(cutlass::detail::dependent_false<ElementA>, "Mainloop with sparse A sourced from RF is not implemented.");
};

// Sparse GMMA auto kernel schedule
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
  class KernelScheduleType
>
struct CollectiveBuilder<
    arch::Sm90,
    arch::OpClassSparseTensorOp,
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
    KernelScheduleType,
    cute::enable_if_t<cute::is_same_v<KernelScheduleType, KernelScheduleAuto>>
> {
  static_assert(is_static<TileShape_MNK>::value);
  static_assert(is_static<ClusterShape_MNK>::value);
#ifndef CUTLASS_SM90_COLLECTIVE_BUILDER_SUPPORTED
  static_assert(cutlass::detail::dependent_false<ElementA>, "Unsupported Toolkit for SM90 Collective Builder\n");
#endif

  static constexpr bool IsFP8Input = detail::is_input_fp8<ElementA, ElementB>();

  using KernelSchedule = cute::conditional_t<size<0>(TileShape_MNK{}) == Int<64>{},
                                             cute::conditional_t<IsFP8Input,
                                                                 KernelTmaWarpSpecializedPingpongFP8FastAccum,
                                                                 KernelTmaWarpSpecializedPingpong>,
                                             cute::conditional_t<IsFP8Input,
                                                                 KernelTmaWarpSpecializedCooperativeFP8FastAccum,
                                                                 KernelTmaWarpSpecializedCooperative>>;

  using CollectiveOp = typename CollectiveBuilder<
      arch::Sm90,
      arch::OpClassSparseTensorOp,
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
      KernelSchedule
    >::CollectiveOp;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective

/////////////////////////////////////////////////////////////////////////////////////////////////
