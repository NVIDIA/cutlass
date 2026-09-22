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

#include "cutlass/gemm/collective/builders/sm100_common.inl"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass::gemm::collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

template<
  class ElementAMma,
  class ElementBMma,
  class ElementAMmaccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  bool WithBreuse,
  UMMA::ScaleIn ANeg = UMMA::ScaleIn::One,
  UMMA::ScaleIn BNeg = UMMA::ScaleIn::One
>
constexpr auto
sm107_make_1sm_trivial_tiled_mma() {

  constexpr int M = cute::size<0>(TileShape_MNK{}) / (WithBreuse ? 2 : 1);
  static_assert(M == 128, "Invalid TileShape_M.");

  constexpr int N = cute::size<1>(TileShape_MNK{});
  static_assert(N % 8 == 0 && N <= 256, "Invalid TileShape_N.");

  if constexpr (cute::is_same_v<ElementAMma, cutlass::type_erased_dynamic_float8_t> ||
                cute::is_same_v<ElementAMma, cutlass::float_e4m3_t> ||
                cute::is_same_v<ElementAMma, cutlass::float_e5m2_t>) {

      return make_tiled_mma(
        cute::SM107_MMA_F8F6F4_SS<
          ElementAMma,
          ElementBMma,
          ElementAMmaccumulator,
          M,
          N,
          UmmaMajorA,
          UmmaMajorB,
          ANeg,
          BNeg>{}
      );
  }
  else {
    static_assert(cutlass::detail::dependent_false<ElementAMma>,
        "Unsupported configuration for SM107 collective builder.");
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
  bool WithBreuse,
  UMMA::ScaleIn ANeg = UMMA::ScaleIn::One,
  UMMA::ScaleIn BNeg = UMMA::ScaleIn::One
>
constexpr auto
sm107_make_2sm_trivial_tiled_mma() {

  constexpr int M = cute::size<0>(TileShape_MNK{}) / (WithBreuse ? 2 : 1);
  static_assert(M == 256, "Invalid TileShape_M.");

  constexpr int N = cute::size<1>(TileShape_MNK{});
  static_assert(N % 8 == 0 && N <= 256, "Invalid TileShape_N.");

  constexpr int K = cute::size<2>(TileShape_MNK{});
  static_assert(K == 128 || K == 64, "Invalid TileShape_K");
  if constexpr (cute::is_same_v<ElementAMma, cutlass::type_erased_dynamic_float8_t> ||
                cute::is_same_v<ElementAMma, cutlass::float_e4m3_t> ||
                cute::is_same_v<ElementAMma, cutlass::float_e5m2_t>) {

    // For the case of b-reuse and .2CTA instructions, we permute the M mode
    // such that each CTA within a pair contains a consecutive portion of the A tensor
    if constexpr (WithBreuse) {
      auto permutation_mnk = make_tile(
        Layout<Shape<_128, _2, _2>, Stride<_1, _256, _128>>{},
        cute::Int<N>{},
        cute::Int<K>{});
      return make_tiled_mma(
        cute::SM107_MMA_F8F6F4_2x1SM_SS<
          ElementAMma,
          ElementBMma,
          ElementAMmaccumulator,
          M,
          N,
          UmmaMajorA,
          UmmaMajorB,
          ANeg,
          BNeg>{},
          Layout<Shape<_1, _1, _1>>{},
          permutation_mnk
      );
    } else {
      return make_tiled_mma(
        cute::SM107_MMA_F8F6F4_2x1SM_SS<
          ElementAMma,
          ElementBMma,
          ElementAMmaccumulator,
          M,
          N,
          UmmaMajorA,
          UmmaMajorB,
          ANeg,
          BNeg>{}
      );
    }
  }
  else {
    static_assert(cutlass::detail::dependent_false<ElementAMma>,
        "Unsupported configuration for SM107 collective builder.");
  }
}

// For new MMA construction and partitioning that supports both dynamic and static cluster shape.
// Used in conjunction with make_tma_atom_(A|B)_sm100
// ClusterShape_MNK can be dynamic or static.
template<
  class ElementAMma,
  class ElementBMma,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  class BuilderScheduleTag,
  bool WithBreuse = false,
  UMMA::ScaleIn ANeg = UMMA::ScaleIn::One,
  UMMA::ScaleIn BNeg = UMMA::ScaleIn::One
>
constexpr auto
sm107_make_trivial_tiled_mma() {
  // MMA_2SM requested
  if constexpr (cute::is_base_of_v<KernelSchedule2Sm, BuilderScheduleTag>) {
    return sm107_make_2sm_trivial_tiled_mma<
        ElementAMma, ElementBMma, ElementAccumulator, TileShape_MNK,
        ClusterShape_MNK, UmmaMajorA, UmmaMajorB, WithBreuse, ANeg, BNeg>();
  }
  // MMA_1SM requested
  else
  if constexpr (cute::is_base_of_v<KernelSchedule1Sm, BuilderScheduleTag>) {
    return sm107_make_1sm_trivial_tiled_mma<
        ElementAMma, ElementBMma, ElementAccumulator, TileShape_MNK,
        ClusterShape_MNK, UmmaMajorA, UmmaMajorB, WithBreuse, ANeg, BNeg>();
  } else {
    static_assert(cutlass::detail::dependent_false<ElementAMma>,
                  "Unsupported configuration for SM107 collective builder.");
  }
}

template <
  class ElementPairA,
  class ElementPairB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  detail::blockscaled::BlockScaledInstr Instr,
  class BuilderScheduleTag,
  int SFVecSize,
  bool WithBreuse
>
constexpr auto
sm107_make_blockscaled_1sm_trivial_tiled_mma() {
  using AtomLayout_MNK = Layout<ClusterShape_MNK>;
  constexpr int M = cute::size<0>(TileShape_MNK{}) / (WithBreuse ? 2 : 1);
  static_assert(M == 128, "Invalid TileShape_M.");

  constexpr int N = cute::size<1>(TileShape_MNK{});
  static_assert(N == 64 || N == 128 || N == 192 || N == 256, "Invalid TileShape_N.");

  using ElementSFA = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairA>::sf_type;
  using ElementSFB = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairB>::sf_type;
  using ElementA = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairA>::data_type;
  using ElementB = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairB>::data_type;

  using ElementAMma = decltype(cutlass::gemm::collective::detail::sm1xx_kernel_input_element_to_mma_input_element<ElementA, Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8>());
  using ElementBMma = decltype(cutlass::gemm::collective::detail::sm1xx_kernel_input_element_to_mma_input_element<ElementB, Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8>());

  using ElementSF = ElementSFA;
  if constexpr (Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8) {
    return make_tiled_mma(cute::SM107_MMA_MXF8F6F4_SS<ElementAMma, ElementBMma, ElementAccumulator, ElementSF,
                                                        M, N, UmmaMajorA, UmmaMajorB>{});
  }
  else if constexpr (Instr == detail::blockscaled::BlockScaledInstr::MXF4_NVF4) {
    return make_tiled_mma(cute::SM107_MMA_MXF4NVF4_SS<ElementAMma, ElementBMma, ElementAccumulator, ElementSF,
                                                        M, N, SFVecSize, UmmaMajorA, UmmaMajorB>{});
  }
  else {
    static_assert(cutlass::detail::dependent_false<ElementAMma>,
        "Unsupported configuration for SM107 tiled MMA.");
  }
}

template <
  class ElementPairA,
  class ElementPairB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  detail::blockscaled::BlockScaledInstr Instr,
  class BuilderScheduleTag,
  int SFVecSize,
  bool WithBreuse
>
constexpr auto
sm107_make_blockscaled_2sm_trivial_tiled_mma() {
  constexpr int M = cute::size<0>(TileShape_MNK{}) / (WithBreuse ? 2 : 1);
  static_assert(M == 256, "Invalid TileShape_M.");

  constexpr int N = cute::size<1>(TileShape_MNK{});
  static_assert(N == 64 || N == 128 || N == 192 || N == 256, "Invalid TileShape_N.");

  constexpr int K = cute::size<2>(TileShape_MNK{});
  static_assert((Instr == detail::blockscaled::BlockScaledInstr::MXF4_NVF4)  ? (K == 256) :
                (Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8)   ? (K == 128) :
                false,
                "Invalid TileShape_K");

  using ElementSFA = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairA>::sf_type;
  using ElementSFB = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairB>::sf_type;
  using ElementA = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairA>::data_type;
  using ElementB = typename detail::blockscaled::blockscaled_type<BuilderScheduleTag, ElementPairB>::data_type;

  using ElementAMma = decltype(cutlass::gemm::collective::detail::sm1xx_kernel_input_element_to_mma_input_element<ElementA, Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8>());
  using ElementBMma = decltype(cutlass::gemm::collective::detail::sm1xx_kernel_input_element_to_mma_input_element<ElementB, Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8>());

  using ElementSF = ElementSFA;
  if constexpr (Instr == detail::blockscaled::BlockScaledInstr::MXF4F6F8) {
    // For the case of b-reuse and .2CTA instructions, we permute the M mode
    // such that each CTA within a pair contains a consecutive portion of the A tensor
    if constexpr (WithBreuse) {
      auto permutation_mnk = make_tile(
        Layout<Shape<_128, _2, _2>, Stride<_1, _256, _128>>{},
        cute::Int<N>{},
        cute::Int<K>{});
      return make_tiled_mma(
        cute::SM107_MMA_MXF8F6F4_2x1SM_SS<ElementAMma, ElementBMma, ElementAccumulator, ElementSF,
                                          M, N, UmmaMajorA, UmmaMajorB>{},
        Layout<Shape<_1, _1, _1>>{},
        permutation_mnk
      );
    }
    else {
      return make_tiled_mma(cute::SM107_MMA_MXF8F6F4_2x1SM_SS<ElementAMma, ElementBMma, ElementAccumulator, ElementSF,
                                                        M, N, UmmaMajorA, UmmaMajorB>{});
    }
  }
  else if constexpr (Instr == detail::blockscaled::BlockScaledInstr::MXF4_NVF4) {
    // For the case of b-reuse and .2CTA instructions, we permute the M mode
    // such that each CTA within a pair contains a consecutive portion of the A tensor
    if constexpr (WithBreuse) {
      auto permutation_mnk = make_tile(
        Layout<Shape<_128, _2, _2>, Stride<_1, _256, _128>>{},
        cute::Int<N>{},
        cute::Int<K>{});
      return make_tiled_mma(
        cute::SM107_MMA_MXF4NVF4_2x1SM_SS<ElementAMma, ElementBMma, ElementAccumulator, ElementSF,
                                          M, N, SFVecSize, UmmaMajorA, UmmaMajorB>{},
        Layout<Shape<_1, _1, _1>>{},
        permutation_mnk
      );
    }
    else {
      return make_tiled_mma(cute::SM107_MMA_MXF4NVF4_2x1SM_SS<ElementAMma, ElementBMma, ElementAccumulator, ElementSF,
                                                        M, N, SFVecSize, UmmaMajorA, UmmaMajorB>{});
    }
  }
  else {
    static_assert(cutlass::detail::dependent_false<ElementAMma>,
        "Unsupported configuration for SM107 tiled MMA.");
  }
}

template <
  class ElementPairA,
  class ElementPairB,
  class ElementAccumulator,
  class TileShape_MNK,
  class ClusterShape_MNK,
  UMMA::Major UmmaMajorA,
  UMMA::Major UmmaMajorB,
  detail::blockscaled::BlockScaledInstr Instr,
  class BuilderScheduleTag,
  int SFVecSize,
  bool WithBreuse = false
>
constexpr auto
sm107_make_blockscaled_trivial_tiled_mma() {
  // MMA_2SM requested
  if constexpr (cute::is_base_of_v<KernelSchedule2Sm, BuilderScheduleTag>) {
    return sm107_make_blockscaled_2sm_trivial_tiled_mma<
        ElementPairA, ElementPairB, ElementAccumulator, TileShape_MNK,
        ClusterShape_MNK, UmmaMajorA, UmmaMajorB, Instr, BuilderScheduleTag,
        SFVecSize, WithBreuse>();
  }
  // MMA_1SM requested
  else if constexpr (cute::is_base_of_v<KernelSchedule1Sm, BuilderScheduleTag>) {
    return sm107_make_blockscaled_1sm_trivial_tiled_mma<
        ElementPairA, ElementPairB, ElementAccumulator, TileShape_MNK,
        ClusterShape_MNK, UmmaMajorA, UmmaMajorB, Instr, BuilderScheduleTag,
        SFVecSize, WithBreuse>();
  }
  else {
    static_assert(cutlass::detail::dependent_false<ElementAccumulator>,
                  "Unsupported configuration for SM107 tiled mma builder");
  }
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective
