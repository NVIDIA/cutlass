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
//

//
#pragma once

#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/kernel/sm100_tile_scheduler.hpp"
#include "cutlass/gemm/dispatch_policy.hpp" // KernelSchedule1Sm, KernelSchedule2Sm
#include "cutlass/gemm/collective/builders/sm90_common.inl" // detail::sm90_cluster_shape_to_tma_atom()
#include "cutlass/numeric_types.h" // all numeric types
#include "cutlass/detail/dependent_false.hpp" // detail::dependent_false
#include "cutlass/pipeline/pipeline.hpp"
#include "cutlass/detail/layout.hpp" // cutlass::detail::get_input_alignment_bits()
#include "cutlass/layout/matrix.h" // cutlass::layout::RowMajor, cutlass::layout::ColumnMajor
#include "cutlass/fast_math.h" // cutlass::round_up, cutlass::const_max
#include "cutlass/arch/arch.h"

#include "cute/atom/mma_traits_sm100.hpp" // UMMA::Layout_MN_SW*
#include "cute/atom/copy_traits_sm100_tma.hpp" // SM100_TMA_*SM_LOAD_*
#include "cute/arch/tmem_allocator_sm100.hpp"
#include "cute/arch/mma_sm100_desc.hpp" // cute::UMMA::Major
#include "cute/arch/mma_sm100_umma.hpp" // SM100_*MMA_SS_*
#include "cute/numeric/integral_constant.hpp" // is_static_v, cute::integral_constant
#include "cute/util/type_traits.hpp" // cute::alignment_of_v

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

// Forward Declaration
struct KernelScheduleAuto;

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

//
// Some named constants
//
constexpr int sm100_smem_capacity_bytes = cutlass::arch::sm100_smem_capacity_bytes;
constexpr int CLCResponseSize =
    sizeof(typename cutlass::gemm::kernel::detail::PersistentTileSchedulerSm100<Shape<_1,_1,_1>,1>::CLCResponse{});

// Maps input element to umma element
template <class Element, bool IsF8F6F4 = true>
constexpr auto
sm100_kernel_input_element_to_mma_input_element() {
  if constexpr (cute::is_same_v<Element, float>) {
    return cutlass::tfloat32_t{};
  }
  else if constexpr (cute::is_same_v<Element, cutlass::float_e2m1_t> && IsF8F6F4) {
    return cutlass::detail::float_e2m1_unpacksmem_t{};
  }
  else if constexpr (cute::is_same_v<Element, cutlass::float_e3m2_t> && IsF8F6F4) {
    return cutlass::detail::float_e3m2_unpacksmem_t{};
  }
  else if constexpr (cute::is_same_v<Element, cutlass::float_e2m3_t> && IsF8F6F4) {
    return cutlass::detail::float_e2m3_unpacksmem_t{};
  }
  else if constexpr (cute::is_same_v<Element, cutlass::type_erased_dynamic_float4_t> && IsF8F6F4) {
    return cutlass::detail::type_erased_dynamic_float4_unpacksmem_t{};
  }
  else if constexpr (cute::is_same_v<Element, cutlass::type_erased_dynamic_float6_t> && IsF8F6F4) {
    return cutlass::detail::type_erased_dynamic_float6_unpacksmem_t{};
  }
  else {
    return Element{};
  }
}

// Maps 2.x A matrix layout tag to respective UMMA major mode enum
template <class Layout>
constexpr cute::UMMA::Major
tag_to_umma_major_A() {
  using LayoutA = cute::remove_pointer_t<Layout>;
  if constexpr (cute::is_same_v<LayoutA, cutlass::layout::RowMajor>) {
    return cute::UMMA::Major::K;
  }
  else if constexpr (cute::is_same_v<LayoutA, cutlass::layout::ColumnMajor>) {
    return cute::UMMA::Major::MN;
  }
  else if constexpr (cutlass::detail::is_major<0, LayoutA>()) {
    return cute::UMMA::Major::MN;
  }
  else if constexpr (cutlass::detail::is_major<1, LayoutA>()) {
    return cute::UMMA::Major::K;
  }
  else {
    static_assert(sizeof(LayoutA) == 0, "Invalid layout.");
  }
}

// Maps 2.x B matrix layout tag to respective UMMA major mode enum
template <class Layout>
constexpr cute::UMMA::Major
tag_to_umma_major_B() {
  using LayoutB = cute::remove_pointer_t<Layout>;
  if constexpr (cute::is_same_v<LayoutB, cutlass::layout::RowMajor>) {
    return cute::UMMA::Major::MN;
  }
  else if constexpr (cute::is_same_v<LayoutB, cutlass::layout::ColumnMajor>) {
    return cute::UMMA::Major::K;
  }
  else if constexpr (cutlass::detail::is_major<0, LayoutB>()) {
    return cute::UMMA::Major::MN;
  }
  else if constexpr (cutlass::detail::is_major<1, LayoutB>()) {
    return cute::UMMA::Major::K;
  }
  else {
    static_assert(sizeof(LayoutB) == 0, "Invalid layout.");
  }
}

// Helper for SS UMMA smem selection that considers a tensor TileShape:
//   (BLK_MN, BLK_K)
//   or hierarchically
//   ((BLK_MN0,BLK_MN1,...),(BLK_K0,BLK_K1,...))
//   and returns the largest UMMA::Layout that fits BLK_MN0 and BLK_K0
template <cute::UMMA::Major major, class ElementType, class BLK_MN, class BLK_K>
CUTE_HOST_DEVICE constexpr
auto
sm100_smem_selector() {
  auto BLK_MN0 = size<0>(BLK_MN{});
  auto BLK_K0  = size<0>(BLK_K{});

  static_assert(BLK_MN0 % 8 == 0, "BLK_MN0 must be a multiple of 8.");
  static_assert(BLK_K0 % 8 == 0,  "BLK_K0 must be a multiple of 8.");

  if constexpr (major == cute::UMMA::Major::MN) {
    // Handle the special case for F32 NT kernels
    if constexpr ((sizeof(ElementType) == 4)) {
       static_assert(BLK_MN0 % size<0>(UMMA::Layout_MN_SW128_32B_Atom<ElementType>{}) == 0, "for mn-major tf32 operands, SW128_32B is the only available smem layout");
      return UMMA::Layout_MN_SW128_32B_Atom<ElementType>{};
    }
    else {
      // All other data types are handled as SM90
      if constexpr      (BLK_MN0 % size<0>(UMMA::Layout_MN_SW128_Atom<ElementType>{}) == 0) {
        return UMMA::Layout_MN_SW128_Atom<ElementType>{};
      }
      else if constexpr (BLK_MN0 % size<0>(UMMA::Layout_MN_SW64_Atom<ElementType>{}) == 0) {
        return UMMA::Layout_MN_SW64_Atom<ElementType>{};
      }
      else if constexpr (BLK_MN0 % size<0>(UMMA::Layout_MN_SW32_Atom<ElementType>{}) == 0) {
        return UMMA::Layout_MN_SW32_Atom<ElementType>{};
      }
      else if constexpr (BLK_MN0 % size<0>(UMMA::Layout_MN_INTER_Atom<ElementType>{}) == 0) {
        return UMMA::Layout_MN_INTER_Atom<ElementType>{};
      }
      else {
        static_assert(BLK_MN0 % size<0>(UMMA::Layout_MN_INTER_Atom<ElementType>{}) == 0,
                      "BLK_MN0 must be a multiple of size<0>(UMMA::Layout_MN_INTER_Atom<ElementType>{})");
      }
    }
  }
  else if constexpr (major == cute::UMMA::Major::K) {
    if constexpr      (BLK_K0 % size<1>(UMMA::Layout_K_SW128_Atom<ElementType>{}) == 0) {
      return UMMA::Layout_K_SW128_Atom<ElementType>{};
    }
    else if constexpr (BLK_K0 % size<1>(UMMA::Layout_K_SW64_Atom<ElementType>{}) == 0) {
      return UMMA::Layout_K_SW64_Atom<ElementType>{};
    }
    else if constexpr (BLK_K0 % size<1>(UMMA::Layout_K_SW32_Atom<ElementType>{}) == 0) {
      return UMMA::Layout_K_SW32_Atom<ElementType>{};
    }
    else if constexpr (BLK_K0 % size<1>(UMMA::Layout_K_INTER_Atom<ElementType>{}) == 0) {
      return UMMA::Layout_K_INTER_Atom<ElementType>{};
    }
    else {
      static_assert(BLK_K0 % size<1>(UMMA::Layout_K_INTER_Atom<ElementType>{}) == 0,
                    "BLK_K0 must be a multiple of size<1>(UMMA::Layout_K_INTER_Atom<ElementType>{})");
    }
  }
}

template <class ClusterShapeMNK, class AtomThrId>
constexpr auto
sm100_cluster_shape_to_tma_atom_A(ClusterShapeMNK cluster_shape_mnk, AtomThrId atom_thr_id) {
  static_assert(cute::rank(cluster_shape_mnk) == 3);
  constexpr bool IsDynamicCluster = not cute::is_static_v<ClusterShapeMNK>;

  if constexpr (cute::size(atom_thr_id) == 2) {
    if constexpr (!IsDynamicCluster) {
      static_assert(cute::size<0>(cluster_shape_mnk) % 2 == 0, "Cluster shape not divisible by MMA size");
      if constexpr (cute::size<1>(cluster_shape_mnk) == 1) {
        return cute::SM100_TMA_2SM_LOAD{};
      }
      else {
        return cute::SM100_TMA_2SM_LOAD_MULTICAST{};
      }
    }
    else {
      return cute::SM100_TMA_2SM_LOAD_MULTICAST{};
    }
  }
  else if constexpr (size(atom_thr_id) == 1) {
    if constexpr (!IsDynamicCluster) {
      return detail::sm90_cluster_shape_to_tma_atom(cute::size<1>(cluster_shape_mnk));
    }
    else {
      // In the case of dynamic cluster, multicast decision is not known at compile time.
      // A multicast instruction is forced by passing a cute::Int<2>{} to this helper. 
      return detail::sm90_cluster_shape_to_tma_atom(cute::Int<2>{});
    }
  }
  else {
    static_assert(cutlass::detail::dependent_false<ClusterShapeMNK>,
        "Unsupported Configuration for SM100 TMA");
  }
}

template <class ClusterShapeMNK, class AtomThrId>
constexpr auto
sm100_cluster_shape_to_tma_atom_B(ClusterShapeMNK cluster_shape_mnk, AtomThrId atom_thr_id) {
  static_assert(cute::rank(cluster_shape_mnk) == 3);
  constexpr bool IsDynamicCluster = not cute::is_static_v<ClusterShapeMNK>;

  if constexpr (cute::size(atom_thr_id) == 2) {
    if constexpr (!IsDynamicCluster) {
      static_assert(cute::size<0>(cluster_shape_mnk) % 2 == 0, "Cluster shape not divisible by MMA size");
      if constexpr (cute::size<0>(cluster_shape_mnk) == 2) {
        return cute::SM100_TMA_2SM_LOAD{};
      }
      else {
        return cute::SM100_TMA_2SM_LOAD_MULTICAST{};
      }
    }
    else {
      return cute::SM100_TMA_2SM_LOAD_MULTICAST{};
    }
  } else if constexpr (size(atom_thr_id) == 1) {
    if constexpr (!IsDynamicCluster) {
      return detail::sm90_cluster_shape_to_tma_atom(cute::size<0>(cluster_shape_mnk));
    }
    else {
      // In the case of dynamic cluster, multicast decision is not known at compile time.
      // A multicast instruction is forced by passing a cute::Int<2>{} to this helper. 
      return detail::sm90_cluster_shape_to_tma_atom(cute::Int<2>{});
    }
  }
  else {
    static_assert(cutlass::detail::dependent_false<ClusterShapeMNK>,
        "Unsupported Configuration for SM100 TMA");
  }
}

template<class KernelScheduleType>
constexpr uint32_t find_vector_size() {
  if constexpr (cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecialized1SmNvf4Sm100> ||
                cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecialized2SmNvf4Sm100> ||
                cute::is_same_v<KernelScheduleType, KernelPtrArrayTmaWarpSpecialized1SmNvf4Sm100> ||
                cute::is_same_v<KernelScheduleType, KernelPtrArrayTmaWarpSpecialized2SmNvf4Sm100>
              ) {
    return 16;
  }
  else {
    return 32;
  }
}

template<
  class ElementAMma,
  class ElementBMma,
  class ElementAMmaccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  UMMA::ScaleIn ANeg = UMMA::ScaleIn::One,
  UMMA::ScaleIn BNeg = UMMA::ScaleIn::One
>
constexpr auto
sm100_make_1sm_trivial_tiled_mma() {

  constexpr int M = cute::size<0>(TileShape_MNK{});
  static_assert(M == 64 || M == 128, "Invalid TileShape_M.");

  // Do not allow a tiled MMA N mode > 1, as that is not reasonable.
  constexpr int N = cute::size<1>(TileShape_MNK{});
  static_assert(N % 8 == 0 && N <= 256, "Invalid TileShape_N.");

  if constexpr     (cute::is_same_v<ElementAMma, cutlass::tfloat32_t>) {
    static_assert(cute::is_same_v<ElementAMma, ElementBMma>, "ElementAMma and ElementBMma must match.");
    return make_tiled_mma(cute::SM100_MMA_TF32_SS<ElementAMma, ElementBMma, ElementAMmaccumulator,
                                              M, N, UmmaMajorA, UmmaMajorB, ANeg, BNeg>{});
  }
  else if constexpr (cute::is_same_v<ElementAMma,     cutlass::half_t> ||
                     cute::is_same_v<ElementAMma, cutlass::bfloat16_t>) {
    static_assert(cute::is_same_v<ElementAMma, ElementBMma>, "ElementAMma and ElementBMma must match.");
    return make_tiled_mma(cute::SM100_MMA_F16BF16_SS<ElementAMma, ElementBMma, ElementAMmaccumulator,
                                              M, N, UmmaMajorA, UmmaMajorB, ANeg, BNeg>{});
  }
  else if constexpr (cute::is_same_v<ElementAMma,  int8_t> ||
                     cute::is_same_v<ElementAMma, uint8_t>) {
    return make_tiled_mma(cute::SM100_MMA_S8_SS<ElementAMma, ElementBMma, ElementAMmaccumulator,
                                              M, N, UmmaMajorA, UmmaMajorB>{});
  }
  else if constexpr (cute::is_same_v<ElementAMma, cutlass::type_erased_dynamic_float8_t> 
                    || cute::is_same_v<ElementAMma, cutlass::detail::type_erased_dynamic_float6_unpacksmem_t> 
                    || cute::is_same_v<ElementAMma, cutlass::detail::type_erased_dynamic_float4_unpacksmem_t> 
                    || cute::is_same_v<ElementAMma, cutlass::float_e4m3_t>
                    || cute::is_same_v<ElementAMma, cutlass::float_e5m2_t>
                    || cute::is_same_v<ElementAMma, cutlass::detail::float_e2m3_unpacksmem_t>
                    || cute::is_same_v<ElementAMma, cutlass::detail::float_e3m2_unpacksmem_t>
                    || cute::is_same_v<ElementAMma, cutlass::detail::float_e2m1_unpacksmem_t>
                    ) {
  
      return make_tiled_mma(
        cute::MMA_Traits<
          cute::SM100_MMA_F8F6F4_SS,
          ElementAMma,
          ElementBMma, 
          ElementAMmaccumulator, 
          cute::C<M>, 
          cute::C<N>, 
          cute::integral_constant<UMMA::Major, UmmaMajorA>,
          cute::integral_constant<UMMA::Major, UmmaMajorB>,
          cute::integral_constant<UMMA::ScaleIn, ANeg>,
          cute::integral_constant<UMMA::ScaleIn, BNeg>
        >{}
      );
  }
  else {
    static_assert(cutlass::detail::dependent_false<ElementAMma>,
        "Unsupported configuration for SM100 collective builder.");
  }
}

template<
  class ElementAMma,
  class ElementBMma,
  class ElementAMmaccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  UMMA::ScaleIn ANeg = UMMA::ScaleIn::One,
  UMMA::ScaleIn BNeg = UMMA::ScaleIn::One
>
constexpr auto
sm100_make_2sm_trivial_tiled_mma() {

  constexpr int M = cute::size<0>(TileShape_MNK{});
  static_assert(M == 128 || M == 256, "Invalid TileShape_M.");

  // Do not allow a tiled MMA N mode > 1, as that is not reasonable.
  constexpr int N = cute::size<1>(TileShape_MNK{});
  static_assert(N % 8 == 0 && N <= 256, "Invalid TileShape_N.");

  if constexpr     (cute::is_same_v<ElementAMma, cutlass::tfloat32_t>) {
    static_assert(cute::is_same_v<ElementAMma, ElementBMma>, "ElementAMma and ElementBMma must match.");
    return make_tiled_mma(cute::SM100_MMA_TF32_2x1SM_SS<ElementAMma, ElementBMma, ElementAMmaccumulator,
                                                     M, N, UmmaMajorA, UmmaMajorB, ANeg, BNeg>{});
  }
  else if constexpr (cute::is_same_v<ElementAMma,     cutlass::half_t> ||
                     cute::is_same_v<ElementAMma, cutlass::bfloat16_t>) {
    static_assert(cute::is_same_v<ElementAMma, ElementBMma>, "ElementAMma and ElementBMma must match.");
    return make_tiled_mma(cute::SM100_MMA_F16BF16_2x1SM_SS<ElementAMma, ElementBMma, ElementAMmaccumulator,
                                                    M, N, UmmaMajorA, UmmaMajorB, ANeg, BNeg>{});
  }
  else if constexpr (cute::is_same_v<ElementAMma, int8_t> ||
                     cute::is_same_v<ElementAMma, uint8_t>) {
    return make_tiled_mma(cute::SM100_MMA_S8_2x1SM_SS<ElementAMma, ElementBMma, ElementAMmaccumulator,
                                                    M, N, UmmaMajorA, UmmaMajorB>{});
  }
  else if constexpr (cute::is_same_v<ElementAMma, cutlass::type_erased_dynamic_float8_t> 
                    || cute::is_same_v<ElementAMma, cutlass::detail::type_erased_dynamic_float6_unpacksmem_t> 
                    || cute::is_same_v<ElementAMma, cutlass::detail::type_erased_dynamic_float4_unpacksmem_t> 
                    || cute::is_same_v<ElementAMma, cutlass::float_e4m3_t>
                    || cute::is_same_v<ElementAMma, cutlass::float_e5m2_t>
                    || cute::is_same_v<ElementAMma, cutlass::detail::float_e2m3_unpacksmem_t>
                    || cute::is_same_v<ElementAMma, cutlass::detail::float_e3m2_unpacksmem_t>
                    || cute::is_same_v<ElementAMma, cutlass::detail::float_e2m1_unpacksmem_t>
                    ) {

    return make_tiled_mma(
      cute::MMA_Traits<
        cute::SM100_MMA_F8F6F4_2x1SM_SS, 
        ElementAMma,
        ElementBMma,
        ElementAMmaccumulator, 
        cute::C<M>, 
        cute::C<N>, 
        cute::integral_constant<UMMA::Major, UmmaMajorA>,
        cute::integral_constant<UMMA::Major, UmmaMajorB>,
        cute::integral_constant<UMMA::ScaleIn, ANeg>,
        cute::integral_constant<UMMA::ScaleIn, BNeg>
      >{}
    );

  }
  else {
    static_assert(cutlass::detail::dependent_false<ElementAMma>,
        "Unsupported configuration for SM100 collective builder.");
  }
}

// For new MMA construction and partitioning that supports both dynamic and static cluster shape.
// Used in conjunction with make_tma_atom_(A|B)_sm100
// TileShape_MNK is always static and has shape (MmaAtomShapeM, MmaAtomShapeN, TileK)
// ClusterShape_MNK can be dynamic or static.
template<
  class ElementAMma,
  class ElementBMma,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  class KernelScheduleType,
  UMMA::ScaleIn ANeg = UMMA::ScaleIn::One,
  UMMA::ScaleIn BNeg = UMMA::ScaleIn::One
>
constexpr auto
sm100_make_trivial_tiled_mma() {
  // MMA_2SM requested
  if constexpr (cute::is_base_of_v<KernelSchedule2Sm, KernelScheduleType> ) {
    return sm100_make_2sm_trivial_tiled_mma<ElementAMma, ElementBMma, ElementAccumulator,
                                    TileShape_MNK, ClusterShape_MNK, UmmaMajorA, UmmaMajorB, ANeg, BNeg>();
  }
  // MMA_1SM requested
  else if constexpr (cute::is_base_of_v<KernelSchedule1Sm, KernelScheduleType> ) {
    return sm100_make_1sm_trivial_tiled_mma<ElementAMma, ElementBMma, ElementAccumulator,
                                    TileShape_MNK, ClusterShape_MNK, UmmaMajorA, UmmaMajorB, ANeg, BNeg>();
  }
  // Auto scheduling requested
  else if constexpr (cute::is_same_v<KernelScheduleType, KernelScheduleAuto>) {
    // Static cluster
    if constexpr (cute::is_static_v<ClusterShape_MNK>) {
      // For MMA_2SM we need a cluster shape that is multiple of 2x1
      // and only M=128 and M=256 are supported, otherwise, fall back to MMA_1SM
      if constexpr (cute::size<0>(ClusterShape_MNK{}) % 2 == 0 &&
                    cute::size<0>(TileShape_MNK{}) % 128 == 0) {
        return sm100_make_2sm_trivial_tiled_mma<ElementAMma, ElementBMma, ElementAccumulator,
                                        TileShape_MNK, ClusterShape_MNK, UmmaMajorA, UmmaMajorB, ANeg, BNeg>();
      }
      else {
        return sm100_make_1sm_trivial_tiled_mma<ElementAMma, ElementBMma, ElementAccumulator,
                                        TileShape_MNK, ClusterShape_MNK, UmmaMajorA, UmmaMajorB, ANeg, BNeg>();
      }
    // Dynamic cluster shape means we cannot assume we can use 2SM MMA 
    }
    else {
        return sm100_make_1sm_trivial_tiled_mma<ElementAMma, ElementBMma, ElementAccumulator,
                                        TileShape_MNK, ClusterShape_MNK, UmmaMajorA, UmmaMajorB, ANeg, BNeg>();
    }
  }
}

template<
  class ElementAMma,
  class ElementBMma,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  int Scale,
  class KernelScheduleType
>
constexpr auto
sm100_make_trivial_fastFP32_tiled_mma() {
  // MMA_2SM requested
  if constexpr (cute::is_base_of_v<KernelSchedule2Sm, KernelScheduleType> ) {
    using AtomLayout_MNK = decltype(make_layout(shape_div(ClusterShape_MNK{}, Shape<_2,_1,_1>{})));
    constexpr int M = cute::size<0>(TileShape_MNK{});
    constexpr int N = cute::size<1>(TileShape_MNK{});
    if constexpr (UmmaMajorA == cute::UMMA::Major::K && !cute::is_base_of_v<KernelTmaWarpSpecializedFastFP32SmemSm100, KernelScheduleType>) {
      return make_tiled_mma(cute::SM100_MMA_F16BF16_2x1SM_TS_SCALED<ElementAMma, ElementBMma, ElementAccumulator,
                                                     M, N,  UmmaMajorA,  UmmaMajorB, Scale>{});
    }
    else { // If A needs to be transposed by MMA, fall back to SMEM from A MMA instructions
      return make_tiled_mma(cute::SM100_MMA_F16BF16_2x1SM_SS_SCALED<ElementAMma, ElementBMma, ElementAccumulator,
                                                     M, N,  UmmaMajorA,  UmmaMajorB, Scale>{});
    }
  }
  // MMA_1SM requested
  else if constexpr (cute::is_base_of_v<KernelSchedule1Sm, KernelScheduleType> ) {
    // using AtomLayout_MNK = Layout<ClusterShape_MNK>;
    constexpr int M = cute::size<0>(TileShape_MNK{});
    constexpr int N = cute::size<1>(TileShape_MNK{});
    if constexpr (UmmaMajorA == cute::UMMA::Major::K  && !cute::is_base_of_v<KernelTmaWarpSpecializedFastFP32SmemSm100, KernelScheduleType>) {
      return make_tiled_mma(cute::SM100_MMA_F16BF16_TS_SCALED<ElementAMma, ElementBMma, ElementAccumulator,
                                                      M, N,  UmmaMajorA,  UmmaMajorB, Scale>{});
    }
    else { // If A needs to be transposed by MMA, fall back to SMEM from A MMA instructions
      return make_tiled_mma(cute::SM100_MMA_F16BF16_SS_SCALED<ElementAMma, ElementBMma, ElementAccumulator,
                                                      M, N,  UmmaMajorA,  UmmaMajorB, Scale>{});
    }
  }
  else if constexpr (cute::is_same_v<KernelScheduleType, KernelScheduleSm100FastFP32Gemm> ||
                     cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedFastFP32SmemSm100> ||
                     cute::is_same_v<KernelScheduleType, KernelScheduleSm100PtrArrayFastFP32Gemm> ||
                     cute::is_same_v<KernelScheduleType, KernelTmaWarpSpecializedPtrArrayFastFP32SmemSm100>) {
    // Static cluster
    if constexpr (cute::is_static_v<ClusterShape_MNK>) {
      // For MMA_2SM we need a cluster shape that is multiple of 2x1
      // and only M=128 and M=256 are supported, otherwise, fall back to MMA_1SM
      if constexpr (cute::get<0>(ClusterShape_MNK{}) % 2 == 0 &&
                  (cute::get<0>(TileShape_MNK{}) / cute::get<0>(ClusterShape_MNK{})) % 64 == 0) {
        if constexpr (!cute::is_base_of_v<KernelTmaWarpSpecializedFastFP32SmemSm100, KernelScheduleType>) {
          return sm100_make_trivial_fastFP32_tiled_mma<ElementAMma, ElementBMma, ElementAccumulator, TileShape_MNK,
                                            ClusterShape_MNK, UmmaMajorA, UmmaMajorB, Scale, KernelTmaWarpSpecialized2SmFastFP32Sm100>();
        }
        else {
          return sm100_make_trivial_fastFP32_tiled_mma<ElementAMma, ElementBMma, ElementAccumulator, TileShape_MNK,
                                            ClusterShape_MNK, UmmaMajorA, UmmaMajorB, Scale, KernelTmaWarpSpecialized2SmFastFP32SmemSm100>();
        }
      }
      else {
        if constexpr (!cute::is_base_of_v<KernelTmaWarpSpecializedFastFP32SmemSm100, KernelScheduleType>) {
          return sm100_make_trivial_fastFP32_tiled_mma<ElementAMma, ElementBMma, ElementAccumulator, TileShape_MNK,
                                              ClusterShape_MNK, UmmaMajorA, UmmaMajorB, Scale, KernelTmaWarpSpecialized1SmFastFP32Sm100>();
        }
        else {
          return sm100_make_trivial_fastFP32_tiled_mma<ElementAMma, ElementBMma, ElementAccumulator, TileShape_MNK,
                                            ClusterShape_MNK, UmmaMajorA, UmmaMajorB, Scale, KernelTmaWarpSpecialized1SmFastFP32SmemSm100>();
        }
      }
    }
    // Dynamic cluster shape means we cannot assume we can use 2SM MMA 
    else {
      if constexpr (!cute::is_base_of_v<KernelTmaWarpSpecializedFastFP32SmemSm100, KernelScheduleType>) {
        return sm100_make_trivial_fastFP32_tiled_mma<ElementAMma, ElementBMma, ElementAccumulator, TileShape_MNK,
                                            ClusterShape_MNK, UmmaMajorA, UmmaMajorB, Scale, KernelTmaWarpSpecialized1SmFastFP32Sm100>();
      }
      else {
        return sm100_make_trivial_fastFP32_tiled_mma<ElementAMma, ElementBMma, ElementAccumulator, TileShape_MNK,
                                          ClusterShape_MNK, UmmaMajorA, UmmaMajorB, Scale, KernelTmaWarpSpecialized1SmFastFP32SmemSm100>();
      }
    }
  }
  else {
    static_assert(cutlass::detail::dependent_false<TileShape_MNK> == 0,
        "Unsupported policy for SM100 collective builder.");
  }
}

/**
 * @brief Check for U4_UNPACK_U8, U6_UNPACK_U8 alignment requirement
 * 
 * @tparam TileShape_MNK (MmaAtomShape_M, MmaAtomShape_N, TileShape_K)
 * @tparam ClusterShape_MNK (cluster_M, cluster_N, cluster_K)
 * @tparam KernelScheduleType Builder tag
 */
template<
  class ElementAMma,
  class ElementBMma,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  class KernelScheduleType,
  bool Is2sm
>
constexpr bool sm100_gemm_check_for_f8f6f4_mix8bit_requirement(){
  

  [[maybe_unused]] constexpr int TileShape_M = Is2sm ? size<0>(TileShape_MNK{}) / 2 : size<0>(TileShape_MNK{});
  [[maybe_unused]] constexpr int TileShape_N = size<1>(TileShape_MNK{});
  [[maybe_unused]] constexpr int TileShape_K = size<2>(TileShape_MNK{});

  constexpr bool is_b_unpack_f4_f6 = cute::is_same_v<ElementBMma, cutlass::detail::float_e2m1_unpacksmem_t> ||
                                   cute::is_same_v<ElementBMma, cutlass::detail::float_e3m2_unpacksmem_t> ||
                                   cute::is_same_v<ElementBMma, cutlass::detail::float_e2m3_unpacksmem_t> ||
                                   cute::is_same_v<ElementBMma, cutlass::detail::type_erased_dynamic_float4_unpacksmem_t> ||
                                   cute::is_same_v<ElementBMma, cutlass::detail::type_erased_dynamic_float6_unpacksmem_t>;
  constexpr bool is_a_unpack_f4_f6 = cute::is_same_v<ElementAMma, cutlass::detail::float_e2m1_unpacksmem_t> ||
                                   cute::is_same_v<ElementAMma, cutlass::detail::float_e3m2_unpacksmem_t> ||
                                   cute::is_same_v<ElementAMma, cutlass::detail::float_e2m3_unpacksmem_t> ||
                                   cute::is_same_v<ElementAMma, cutlass::detail::type_erased_dynamic_float4_unpacksmem_t> ||
                                   cute::is_same_v<ElementAMma, cutlass::detail::type_erased_dynamic_float6_unpacksmem_t>;

  [[maybe_unused]] constexpr bool is_b_n_major = UmmaMajorB == UMMA::Major::MN;
  [[maybe_unused]] constexpr bool is_b_k_major = !is_b_n_major;
  [[maybe_unused]] constexpr bool is_a_m_major = UmmaMajorA == UMMA::Major::MN;
  [[maybe_unused]] constexpr bool is_a_k_major = !is_a_m_major;

  // 2SM
  if constexpr (Is2sm) {
    constexpr bool valid_a = !is_a_unpack_f4_f6 || (is_a_k_major ?
                                                  TileShape_K % 128 == 0 :
                                                  TileShape_M % 128 == 0);

    constexpr bool valid_b = !is_b_unpack_f4_f6 || (is_b_n_major ?
                                                  TileShape_N % 256 == 0: 
                                                  TileShape_K % 128 == 0);
    return valid_a && valid_b;
  }
  // 1SM
  else {
    constexpr bool valid_a = !is_a_unpack_f4_f6 || (is_a_k_major ?
                                                  TileShape_K % 128 == 0 :
                                                  TileShape_M % 128 == 0);

    constexpr bool valid_b = !is_b_unpack_f4_f6 || (is_b_n_major ? 
                                                  TileShape_N % 128 == 0 : 
                                                  TileShape_K % 128 == 0);

    return valid_a && valid_b;
  }
}

template <class ElementA, int AlignmentA, class ElementB, int AlignmentB, class KernelScheduleType>
constexpr bool
sm1xx_gemm_is_aligned() {
  // Only support dense gemm alignment check
  constexpr bool is_f8f6f4_subbytes = cute::sizeof_bits_v<ElementA> < 8 || cute::sizeof_bits_v<ElementB> < 8;

  return ((cute::sizeof_bits_v<ElementA> * AlignmentA) % cutlass::detail::get_input_alignment_bits<ElementA, is_f8f6f4_subbytes>() == 0) &&
         ((cute::sizeof_bits_v<ElementB> * AlignmentB) % cutlass::detail::get_input_alignment_bits<ElementB, is_f8f6f4_subbytes>() == 0);
}

template <class ElementA, int AlignmentA, class ElementB, int AlignmentB, class KernelScheduleType>
constexpr bool
sm1xx_blockscaled_gemm_is_aligned() {
  // Only support blocksscaled gemm alignment check
  constexpr bool is_mxf8f6f4_subbytes = (cute::sizeof_bits_v<ElementA> < 8 || cute::sizeof_bits_v<ElementB> < 8) &&
                                    (cute::is_base_of_v<KernelScheduleMxf8f6f4Sm100, KernelScheduleType> 
                                    );

  return ((cute::sizeof_bits_v<ElementA> * AlignmentA) % cutlass::detail::get_input_alignment_bits<ElementA, is_mxf8f6f4_subbytes>() == 0) &&
         ((cute::sizeof_bits_v<ElementB> * AlignmentB) % cutlass::detail::get_input_alignment_bits<ElementB, is_mxf8f6f4_subbytes>() == 0);
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective
