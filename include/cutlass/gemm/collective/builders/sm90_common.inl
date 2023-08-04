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

#include "cutlass/detail/layout.hpp"

#include "cute/atom/mma_traits_sm90_gmma.hpp"
#include "cute/atom/copy_traits_sm90_tma.hpp"

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
gmma_ss_tag_to_major_A() {
  // MN major mode is only valid for non-TF32, non-int and non-fp8 MMAs
  if constexpr (cutlass::gemm::detail::is_mn_major_A<LayoutA>() &&
                not cute::is_same_v<ElementA, tfloat32_t> &&
                sizeof(ElementA) != 1) {
    return cute::GMMA::Major::MN;
  }
  else {
    return cute::GMMA::Major::K;
  }
}

// Maps 2.x B matrix layout tag to respective GMMA major mode enum
template <class ElementB, class LayoutB>
constexpr cute::GMMA::Major
gmma_ss_tag_to_major_B() {
  // MN major mode is only valid for non-TF32, non-int and non-fp8 MMAs
  if constexpr (cutlass::gemm::detail::is_mn_major_B<LayoutB>() &&
                not cute::is_same_v<ElementB, tfloat32_t> &&
                sizeof(ElementB) != 1) {
    return cute::GMMA::Major::MN;
  }
  else {
    return cute::GMMA::Major::K;
  }
}

template <class LayoutA>
constexpr cute::GMMA::Major
gmma_rs_tag_to_major_A() {
  // MN major mode is only valid for non-TF32 and non-int MMAs
  if constexpr (cutlass::gemm::detail::is_mn_major_A<LayoutA>()) {
    return cute::GMMA::Major::MN;
  }
  else {
    return cute::GMMA::Major::K;
  }
}

template <class LayoutB>
constexpr cute::GMMA::Major
gmma_rs_tag_to_major_B() {
  // MN major mode is only valid for non-TF32 and non-int MMAs
  if constexpr (cutlass::gemm::detail::is_mn_major_B<LayoutB>()) {
    return cute::GMMA::Major::MN;
  }
  else {
    return cute::GMMA::Major::K;
  }
}
// Maps a rank-1 cute::Shape<> representing the cluster shape on to the TMA atom that should be used with it
template <class UnimodalClusterShape>
constexpr auto
sm90_cluster_shape_to_tma_atom(UnimodalClusterShape) {
  static_assert(cute::rank(UnimodalClusterShape{}) == 1,
    "Use this function to figure out TMA for each mode individually.");

  if constexpr (cute::size(UnimodalClusterShape{}) == 1) {
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

  if constexpr (cutlass::gemm::detail::is_k_major<StrideType>()) {
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
  else if constexpr (cutlass::gemm::detail::is_mn_major<StrideType>()) {
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
    static_assert(cute::is_void_v<Element>, "Unsupported gmem layout for automatic gmem tiled copy builder.");
  }
}

// Helper for SS GMMA smem selection that considers a tensor TileShape:
//   (BLK_MN, BLK_K)
//   or hierarchically
//   ((BLK_MN0,BLK_MN1,...),(BLK_K0,BLK_K1,...))
//   and returns the optimal GMMA::Layout that fits BLK_MN0 and BLK_K0
template <GMMA::Major major, class ElementType, class BLK_MN, class BLK_K, const bool is_ws_transposed_B = false>
constexpr auto
rs_smem_selector() {
  auto BLK_MN0 = size<0>(BLK_MN{});
  auto BLK_K0  = size<0>(BLK_K{});

  static_assert(BLK_MN0 % 8 == 0, "BLK_MN0 must be a multiple of 8.");
  static_assert(BLK_K0 % 8 == 0,  "BLK_K0 must be a multiple of 8.");
  if constexpr (major == GMMA::Major::MN) {
    if constexpr (sizeof(ElementType) == 4){
      if constexpr (is_ws_transposed_B) {
        // only optimized transpositionB(SW32 and SW128 for tf32) can be used, but prefer SW32 due to free bank conflict
        if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_SW32_Atom<ElementType>{}) == 0) {
          return GMMA::Layout_MN_SW32_Atom<ElementType>{};
        }
        else {
          static_assert(BLK_MN0 % size<0>(GMMA::Layout_MN_SW32_Atom<ElementType>{}) == 0,
                       "BLK_MN0 must be a multiple of size<0>(GMMA::Layout_MN_SW32_Atom<ElementType>{})");
        }
      }
      else {
        // Fall into SW32 due to free bank conflict
        if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_SW32_Atom<ElementType>{}) == 0) {
          return GMMA::Layout_MN_SW32_Atom<ElementType>{};
        }
        else if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_INTER_Atom<ElementType>{}) == 0) {
          return GMMA::Layout_MN_INTER_Atom<ElementType>{};
        }
        else {
          static_assert(BLK_MN0 % size<0>(GMMA::Layout_MN_INTER_Atom<ElementType>{}) == 0,
                       "BLK_MN0 must be a multiple of size<0>(GMMA::Layout_MN_INTER_Atom<ElementType>{})");
        }
      }
    }
    // Used for int8, fp8, fp16 and bf16 I/O kernels
    else if constexpr (sizeof(ElementType) == 1 || sizeof(ElementType) == 2) {
      if constexpr (sizeof(ElementType) == 1 && is_ws_transposed_B) {
        // Only optimized transpositionB (SW32 for int8 and fp8) can be used
        if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_SW128_Atom<ElementType>{}) == 0) {
          return GMMA::Layout_MN_SW128_Atom<ElementType>{};
        }
        else {
          static_assert(BLK_MN0 % size<0>(GMMA::Layout_MN_SW128_Atom<ElementType>{}) == 0,
                       "BLK_MN0 must be a multiple of size<0>(GMMA::Layout_MN_128_Atom<ElementType>{})");
        }
      }
      else {
        if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_SW128_Atom<ElementType>{}) == 0) {
          return GMMA::Layout_MN_SW128_Atom<ElementType>{};
        }
        else if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_SW64_Atom<ElementType>{}) == 0) {
          return GMMA::Layout_MN_SW64_Atom<ElementType>{};
        }
        else if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_SW32_Atom<ElementType>{}) == 0) {
          return GMMA::Layout_MN_SW32_Atom<ElementType>{};
        }
        else if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_INTER_Atom<ElementType>{}) == 0) {
          return GMMA::Layout_MN_INTER_Atom<ElementType>{};
        }
        else {
          static_assert(BLK_MN0 % size<0>(GMMA::Layout_MN_INTER_Atom<ElementType>{}) == 0,
                       "BLK_MN0 must be a multiple of size<0>(GMMA::Layout_MN_INTER_Atom<ElementType>{})");
        }
      }
    }
    else {
      static_assert(cutlass::detail::dependent_false<ElementType>, "Smem selector does not support this element type");
    }
  }
  else if constexpr (major == GMMA::Major::K) {
    if constexpr (BLK_K0 % size<1>(GMMA::Layout_K_SW128_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_K_SW128_Atom<ElementType>{};
    }
    else if constexpr (BLK_K0 % size<1>(GMMA::Layout_K_SW64_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_K_SW64_Atom<ElementType>{};
    }
    else if constexpr (BLK_K0 % size<1>(GMMA::Layout_K_SW32_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_K_SW32_Atom<ElementType>{};
    }
    else if constexpr (BLK_K0 % size<1>(GMMA::Layout_K_INTER_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_K_INTER_Atom<ElementType>{};
    }
    else {
      static_assert(BLK_K0 % size<1>(GMMA::Layout_K_INTER_Atom<ElementType>{}) == 0,
                    "BLK_K0 must be a multiple of size<1>(GMMA::Layout_K_INTER_Atom<ElementType>{})");
    }
  }
}

// Helper for SS GMMA smem selection that considers a tensor TileShape:
//   (BLK_MN, BLK_K)
//   or hierarchically
//   ((BLK_MN0,BLK_MN1,...),(BLK_K0,BLK_K1,...))
//   and returns the largest GMMA::Layout that fits BLK_MN0 and BLK_K0
template <GMMA::Major major, class ElementType, class BLK_MN, class BLK_K>
CUTE_HOST_DEVICE constexpr
auto
ss_smem_selector()
{
  auto BLK_MN0 = size<0>(BLK_MN{});
  auto BLK_K0  = size<0>(BLK_K{});

  static_assert(BLK_MN0 % 8 == 0, "BLK_MN0 must be a multiple of 8.");
  static_assert(BLK_K0 % 8 == 0,  "BLK_K0 must be a multiple of 8.");


  if constexpr (major == GMMA::Major::MN) {
    if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_SW128_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_MN_SW128_Atom<ElementType>{};
    }
    else if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_SW64_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_MN_SW64_Atom<ElementType>{};
    }
    else if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_SW32_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_MN_SW32_Atom<ElementType>{};
    }
    else if constexpr (BLK_MN0 % size<0>(GMMA::Layout_MN_INTER_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_MN_INTER_Atom<ElementType>{};
    }
    else {
      static_assert(BLK_MN0 % size<0>(GMMA::Layout_MN_INTER_Atom<ElementType>{}) == 0,
                    "BLK_MN0 must be a multiple of size<0>(GMMA::Layout_MN_INTER_Atom<ElementType>{})");
    }
  }
  else if constexpr (major == GMMA::Major::K) {
    if constexpr (BLK_K0 % size<1>(GMMA::Layout_K_SW128_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_K_SW128_Atom<ElementType>{};
    }
    else if constexpr (BLK_K0 % size<1>(GMMA::Layout_K_SW64_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_K_SW64_Atom<ElementType>{};
    }
    else if constexpr (BLK_K0 % size<1>(GMMA::Layout_K_SW32_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_K_SW32_Atom<ElementType>{};
    }
    else if constexpr (BLK_K0 % size<1>(GMMA::Layout_K_INTER_Atom<ElementType>{}) == 0) {
      return GMMA::Layout_K_INTER_Atom<ElementType>{};
    }
    else {
      static_assert(BLK_K0 % size<1>(GMMA::Layout_K_INTER_Atom<ElementType>{}) == 0,
                    "BLK_K0 must be a multiple of size<1>(GMMA::Layout_K_INTER_Atom<ElementType>{})");
    }
  }
}

template <class ElementA, class ElementB>
constexpr bool
is_input_size_two_bytes() {
  return (sizeof(ElementA) == 2 && sizeof(ElementB) == 2);
}

template <class ElementA, class ElementB>
constexpr bool
is_input_fp8() {
  return ((cute::is_same_v<ElementA, float_e4m3_t> || cute::is_same_v<ElementA, float_e5m2_t>) &&
          (cute::is_same_v<ElementB, float_e4m3_t> || cute::is_same_v<ElementB, float_e5m2_t>));
}

template <class ElementA, class LayoutA, class ElementB, class LayoutB>
constexpr bool
is_use_rmem_A() {
  constexpr bool IsInputSizeTwoBytes = is_input_size_two_bytes<ElementA, ElementB>();
  constexpr bool IsLayoutAkBk = cutlass::gemm::detail::is_k_major_A<LayoutA>() &&
                                cutlass::gemm::detail::is_k_major_B<LayoutB>();
  constexpr bool IsUseRmemA = !IsInputSizeTwoBytes && !IsLayoutAkBk;
  return IsUseRmemA;
}

template <class ElementA, int AlignmentA, class ElementB, int AlignmentB, int RequiredAlignment>
constexpr bool
is_aligned() {
  return ((sizeof(ElementA) * AlignmentA) % RequiredAlignment == 0) &&
         ((sizeof(ElementB) * AlignmentB) % RequiredAlignment == 0);
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective
