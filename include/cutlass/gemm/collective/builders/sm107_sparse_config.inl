/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cute/config.hpp"                     // CUTE_STATIC_ASSERT
#include "cute/layout.hpp"                     // cute::Layout, cute::Shape, cute::Stride
#include "cute/numeric/integral_constant.hpp"  // cute::Int
#include "cute/numeric/numeric_types.hpp"      // cute::sizeof_bits_v
#include "cute/pointer_sparse.hpp"             // cute::is_sparse
#include "cute/util/type_traits.hpp"           // cute::is_same_v, cute::conditional_t
#include "cutlass/fast_math.h"                 // cutlass::round_up
#include "cutlass/layout/matrix.h"             // cutlass::layout::RowMajor

namespace cutlass {

using namespace cute;

/// Sparse layout configuration for SM107 2:4 FP4 compression.
///
/// This type prepares A/E tensors for an IR-based SM107 sparse GEMM. It is not
/// a C++ sparse GEMM kernel configuration.
template<
  class ElementAMma_,
  class LayoutATag_,
  class ElementEMma_
>
struct Sm107GemmSparseConfig {
  /// ElementAMma Check
  static_assert(cute::is_same_v<LayoutATag_, cutlass::layout::RowMajor>, "LayoutATag MUST be RowMajor"); // not used, for API compatibility
  static_assert(cute::is_sparse<ElementAMma_>::value, "ElementAMma MUST be sparse elem");
  static_assert(cute::is_sparse<ElementEMma_>::value, "ElementEMma MUST be sparse elem");

  /// A
  using ElementAMma         = ElementAMma_;
  using ElementAMmaRaw      = typename ElementAMma::raw_type; // fp4
  using ElementAMmaSparsity = Int<ElementAMma::sparsity>; // 2

  /// MetaData (E)
  using ElementEMma         = ElementEMma_;
  using ElementEMmaRaw      = typename ElementEMma::raw_type; // uint8_t
  using ElementEMmaSparsity = Int<ElementEMma::sparsity>; // 8

  /// Number of ElementARaw stored in ElementAMmaRaw
  using ElemsARawPerElementAMmaRaw = _1;

  /// ElementA Sparsity Ratio
  using ElementASparsity = _2;

  // Logical/Physical ElementA per Chunk
  // 2:4 sparse for all Rubin
  using LogicalElemsAPerChunk = _4;
  using PhysicalElemsAPerChunk = Int<LogicalElemsAPerChunk{} / ElementASparsity{}>;

  /// Metadata Bits
  using ElementEBitsPerChunk = _4;
  using ElementEBitsPerElementAMma = _2;

  /// Metadata Layout
  using TensorEAtom = Layout<Shape<_128, _128>,
                             Stride<_128, _1>>;

  // Logical elems that construct the atomK for tensorE/A.  
  using TensorEAtomK = Int<size<1>(TensorEAtom{})>;
  using TensorEAtomM = Int<size<0>(TensorEAtom{})>;

  using TensorEAlignmentM = TensorEAtomM;
  using TensorEAlignmentK = TensorEAtomK;

  // When A is K major, TensorAAlignmentK needs to be multiplier of TMA requirements times tensorA sparsity
  //   this is b.c. TensorACompressed needs to satisfy TMA requirements.
  //   (LogicalElemsAPerChunk is always smaller than TMA in this case.)
  // NOTE: TensorAAlignmentK already contains the 2x sparsity factor when k-major
  using TensorAAlignmentK = Int<128 / cute::sizeof_bits_v<ElementAMma>>;
  using TensorAAlignmentM = _1; // When A is K Major, no requirements on TensorAAlignmentM.

  // For compressor kernel compatibility
  static constexpr bool IsTF32 = false;

  // The following two functions are provided for user fill dynamic problem size to the layout_a/e.
  template <
    class ProblemShape
  >
  CUTE_HOST_DEVICE
  static constexpr auto
  fill_layoutA(ProblemShape problem_shape) {
    // * Purpose of this function
    // This function is sparse gemm equivalent of 
    //
    //   ```cpp
    //   using LayoutATag = cutlass::layout::RowMajor;
    //   using StrideA = cutlass::gemm::TagToStrideA_t<GmemLayoutBTag>; // ( cute::Stride<int64_t, cute::Int<1>, int64_t> )
    //   auto stride_a = cutlass::make_cute_packed_stride(StrideA{}, cute::make_shape(M, K, L)); // (M, cute::Int<1>, L)
    //   auto layout_a = cute::make_layout(cute::make_shape(M, K, L), stride_a);
    //   ```
    //
    // Unlike dense gemm where we can simply call `TagToStrideA_t` resp. `make_cute_packed_stride`
    // to get the shape and stride, sparse gemm needs to consider the cute::sparse_elem<> representation.
    // Thus, it's easier to construct the layout directly.
    //
    // * NOTE
    // 1. Returned layout should be used with `cute::sparse_elem<>` pointer, instead of raw element A ptr
    // 2. `TensorAAlignmentK` already include 2x sparsity factor along K dim.
    const auto [M, N, K, L] = problem_shape;

    // Round up to satisfy TensorA Alignment requirement
    const auto M_AlignedA = cutlass::round_up(M, TensorAAlignmentM{});
    const auto K_AlignedA = cutlass::round_up(K, TensorAAlignmentK{});

    return make_layout(
      make_shape(int32_t(M_AlignedA),
                  make_shape(ElementASparsity{}, int32_t(K_AlignedA / ElementASparsity{})),
                  int32_t(L)),
      make_stride(int64_t(K_AlignedA),
                  make_stride(_1{}, ElementASparsity{}),
                  (L == 1) ? int64_t(0) : int64_t(M_AlignedA * K_AlignedA))
    );
  }

  template <
    class ProblemShape
  >
  CUTE_HOST_DEVICE
  static constexpr auto
  fill_layoutE(ProblemShape problem_shape) {
    const auto [M, N, K, L] = problem_shape;

    // Round up to satisfy TensorEAlignment requirement
    const auto M_AlignedE = cutlass::round_up(M, TensorEAlignmentM{});
    const auto K_AlignedE = cutlass::round_up(K, TensorEAlignmentK{});

    return make_layout(
      make_shape(make_shape(shape<0>(TensorEAtom{}), int32_t(M_AlignedE / TensorEAlignmentM{})),
                 make_shape(shape<1>(TensorEAtom{}), int32_t(K_AlignedE / TensorEAlignmentK{})),
                 int32_t(L)),
      make_stride(make_stride(stride<0>(TensorEAtom{}), cute::Int<cute::cosize(TensorEAtom{})>{}),
                  make_stride(stride<1>(TensorEAtom{}), int64_t(M_AlignedE * TensorEAlignmentK{})),
                  (L == 1) ? int64_t(0) : int64_t(M_AlignedE * K_AlignedE))
    );
  }
};

} // namespace cutlass
