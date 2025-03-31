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
#pragma once

#include "cutlass/arch/mma.h"
#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/dispatch_policy.hpp"
#include "cutlass/detail/layout.hpp"
#include "cutlass/detail/collective.hpp"
#include "cutlass/detail/dependent_false.hpp"

#include "cute/atom/mma_traits_sm90_gmma.hpp"

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
template <class LayoutA>
constexpr cute::GMMA::Major
gmma_aurora_tag_to_major_A() {
  if constexpr (cutlass::gemm::detail::is_mn_major_A<LayoutA>()) {
    return cute::GMMA::Major::MN;
  }
  else {
    return cute::GMMA::Major::K;
  }
}

template <class LayoutB>
constexpr cute::GMMA::Major
gmma_aurora_tag_to_major_B() {
  if constexpr (cutlass::gemm::detail::is_mn_major_B<LayoutB>()) {
    return cute::GMMA::Major::MN;
  }
  else {
    return cute::GMMA::Major::K;
  }
}

// Helper for SS GMMA smem selection that considers a tensor TileShape:
//   (BLK_MN, BLK_K)
//   or hierarchically
//   ((BLK_MN0,BLK_MN1,...),(BLK_K0,BLK_K1,...))
//   and returns the largest GMMA::Layout that fits BLK_MN0 and BLK_K0
template <cute::GMMA::Major major, class ElementType, class BLK_MN, class BLK_K>
CUTE_HOST_DEVICE constexpr
auto
ss_smem_selector()
{
  using namespace cute;

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

template <class ElementA, int AlignmentA, class ElementB, int AlignmentB, int RequiredAlignment>
constexpr bool
is_aligned() {
  return ((sizeof(ElementA) * AlignmentA) % RequiredAlignment == 0) &&
         ((sizeof(ElementB) * AlignmentB) % RequiredAlignment == 0);
}

} // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::gemm::collective
