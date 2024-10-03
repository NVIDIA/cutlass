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

/*! \file
    \brief Sparse configs specific for SM90 structure sparse kernels
*/


#pragma once

#include "cute/atom/mma_traits_sm90_gmma.hpp"  // cute::GMMA::Major
#include "cute/layout.hpp"                     // cute::Layout, cute::Shape, cute::Stride
#include "cute/numeric/integral_constant.hpp"  // cute::Int
#include "cute/numeric/numeric_types.hpp"      // cute::sizeof_bits_v
#include "cute/pointer_sparse.hpp"             // cute::is_sparse
#include "cute/util/type_traits.hpp"           // cute::is_same_v, cute::conditional_t
#include "cutlass/fast_math.h"                 // cutlass::round_up
#include "cutlass/layout/matrix.h"             // cutlass::RowMajor, cutlass::ColumnMajor

namespace cutlass {

using namespace cute;

template<
  class ElementAMma_,
  GMMA::Major GmmaMajorA,
  class ElementEMma_,
  class MinTileShapeK = Int<32>
>
struct Sm90GemmSparseConfig {

  static_assert(cute::is_sparse<ElementAMma_>::value, "ElementAMma MUST be sparse elem");
  static_assert(cute::is_sparse<ElementEMma_>::value, "ElementEMma MUST be sparse elem");

  // A
  using ElementAMma         = ElementAMma_;
  using ElementAMmaRaw      = typename ElementAMma::raw_type;
  using ElementAMmaSparsity = Int<ElementAMma::sparsity>;

  // Metadata (E)
  using ElementEMma         = ElementEMma_;
  using ElementEMmaRaw      = typename ElementEMma::raw_type;
  using ElementEMmaSparsity = Int<ElementEMma::sparsity>;

  // MMA type
  static constexpr bool IsQmma = cute::is_same_v<ElementAMmaRaw, float_e4m3_t> && ElementAMmaSparsity{} == _2{} ||
                                  cute::is_same_v<ElementAMmaRaw, float_e5m2_t> && ElementAMmaSparsity{} == _2{};
  static constexpr bool IsImma = cute::is_same_v<ElementAMmaRaw, int8_t> && ElementAMmaSparsity{} == _2{} ||
                                 cute::is_same_v<ElementAMmaRaw, uint8_t> && ElementAMmaSparsity{} == _2{};
  static constexpr bool IsHmma = cute::is_same_v<ElementAMmaRaw, half_t> && ElementAMmaSparsity{} == _2{} ||
                                 cute::is_same_v<ElementAMmaRaw, bfloat16_t> && ElementAMmaSparsity{} == _2{};
  static constexpr bool IsTfmma = cute::is_same_v<ElementAMmaRaw, tfloat32_t> && ElementAMmaSparsity{} == _2{} || 
                                  cute::is_same_v<ElementAMmaRaw, float> && ElementAMmaSparsity{} == _2{};
  static_assert(int(IsQmma) + int(IsImma) + int(IsHmma) + int(IsTfmma) == 1, "Ambigious Input Type Config (failed to choose MMA type)");

  // Number of ElementARaw stored in ElementAMmaRaw. For Hopper this is always 1.
  using ElemsARawPerElementAMmaRaw = _1;

  // ElementA Sparsity Ratio
  using ElementASparsity = ElementAMmaSparsity;
  static_assert(ElementASparsity{} == _2{}, "ElementASparsity must be 2 for Hopper Sparse Gemm");

  // Logical/Physical ElementA per Chunk
  using LogicalElemsAPerChunk = conditional_t<IsTfmma, _2, _4>;
  using PhysicalElemsAPerChunk = Int<LogicalElemsAPerChunk{} / ElementASparsity{}>;

  // Metadata Bits
  using ElementEBitsPerChunk = _4;
  using ElementEBitsPerElementAMma = cute::conditional_t<IsTfmma, _4, _2>;

  // Metadata Layout. Unit in corresbonding logical elements.
  // Basic metadata block is (16,64) for 8-bit, (16,32) for 16-bit, (16,16) for 32-bit data types.
  // https://docs.nvidia.com/cuda/parallel-thread-execution/index.html#sparse-wgmma-metadata-64n32-f16bf16
  // Tensor E layout atom stacks 4 basic blocks along M mode to align with WGMMA instruction shape and
  // stacks 1-4 blocks along K mode and reorders memory layout to allow for vectorized loads from smem.
  using BlockK = Int<512 / sizeof_bits_v<ElementAMmaRaw>>;
  static_assert(MinTileShapeK{} % BlockK{} == 0, "MinTileShapeK must be a multiple of BlockK");
  using NumK = decltype(MinTileShapeK{} / BlockK{});

  using TensorEAtom_32bit = decltype(make_ordered_layout(Shape<Shape<_8,_2,_4>, Shape<_8,_2,NumK>>{}, 
                                                         Step <Step <_3,_1,_5>, Step <_0,_4,  _2>>{}));

  using TensorEAtom_16bit = decltype(make_ordered_layout(Shape<Shape<_8,_2,_4>, Shape<_16,_2,NumK>>{},
                                                         Step <Step <_3,_1,_5>, Step < _0,_4,  _2>>{}));

  using TensorEAtom_8bit  = decltype(make_ordered_layout(Shape<_64,MinTileShapeK>{},
                                                         Step < _1,           _0>{}));

  using TensorEAtom = cute::conditional_t<(IsQmma || IsImma),  TensorEAtom_8bit, 
                      cute::conditional_t<IsTfmma, TensorEAtom_32bit,
                      TensorEAtom_16bit>>;

  // Logical elems that construct the atomK for tensorE/A.  
  using TensorEAtomK = Int<size<1>(TensorEAtom{})>;
  using TensorEAtomM = Int<size<0>(TensorEAtom{})>;

  // Tensor E alignment requirements
  using TensorEAlignmentM = TensorEAtomM;
  using TensorEAlignmentK = TensorEAtomK;

  // Tensor A alignment requirements
  // When A is MN major, TensorAAlignmentK needs to be multiplier of chunk size
  // When A is K major, TensorAAlignmentK needs to be multiplier of TMA requirements times tensorA sparsity
  //   this is b.c. TensorACompressed needs to satisfy TMA requirements
  using TensorAAlignmentK = cute::conditional_t<GmmaMajorA == GMMA::Major::MN,
                                                LogicalElemsAPerChunk,
                                                Int<128 / cute::sizeof_bits_v<ElementAMma>>>;

  // When A is MN Major, TensorAAlignmentM needs to be multiplier of TMA requirements
  // When A is K Major, no requirements on TensorAAlignmentM.
  using TensorAAlignmentM = cute::conditional_t<GmmaMajorA == GMMA::Major::MN,
                                                Int<128 / cute::sizeof_bits_v<ElementAMmaRaw> * ElemsARawPerElementAMmaRaw{}>,
                                                _1>;

  // The following two functions are provided for user determine the static layouts type
  CUTE_HOST_DEVICE
  static constexpr auto
  deduce_layoutA() {
    using LayoutMMajor = Layout<Shape <int32_t,
                                       Shape<ElementASparsity, int32_t>,
                                       int32_t>,
                                Stride<ElementASparsity,
                                       Stride<_1, int64_t>,
                                       int64_t>>;

    using LayoutKMajor = Layout<Shape <int32_t,
                                       Shape<ElementASparsity, int32_t>,
                                       int32_t>,
                                Stride<int64_t,
                                       Stride<_1, ElementASparsity>,
                                       int64_t>>;

    if constexpr (GmmaMajorA == GMMA::Major::MN) {
      return LayoutMMajor{};
    }
    else {
      return LayoutKMajor{};
    }
  }

  CUTE_HOST_DEVICE
  static constexpr auto
  deduce_layoutE() {
    return make_layout(
      make_shape(make_shape(shape<0>(TensorEAtom{}), int32_t(0)),
                 make_shape(shape<1>(TensorEAtom{}), int32_t(0)),
                 int32_t(0)),
      make_stride(make_stride(stride<0>(TensorEAtom{}), cute::Int<cute::cosize(TensorEAtom{})>{}),
                  make_stride(stride<1>(TensorEAtom{}), int64_t(0)),
                  int64_t(0))
    );
  }

  // This function is used to revert a CuTe layout to a Cutlass layout tag (RowMajor/ColumnMajor)
  template <class ShapeA, class StrideA>
  CUTE_HOST_DEVICE
  static constexpr auto
  deduce_layoutA_tag(Layout<ShapeA, StrideA> layout_a) {
    /*
      (m, (2, k/2), l) : (2, (1, m*2), m*k) M-major
      (m, (2, k/2), l) : (k, (1, 2), m*k) K-major
    */
    // Check if the given layout_a is possibly a sparse tensorA layout.
    static_assert(rank_v<ShapeA> == 3 && depth_v<ShapeA> == 2, "Rank and depth mismatch with the sparse tensorA's layout.");
    static_assert(rank(get<1>(ShapeA{})) == 2 && rank(flatten(ShapeA{})) == 4,
                  "Not likely to be a sparse tensorA's layout.");
    static_assert(get<1,0>(StrideA{}) == 1 && get<1,0>(ShapeA{}) == ElementASparsity{},
                  "Not likely to be a sparse tensorA's layout.");
    static_assert(get<0>(StrideA{}) == ElementASparsity{} || get<1,1>(StrideA{}) == ElementASparsity{},
                  "Not likely to be a sparse tensorA's layout.");

    if constexpr (get<0>(StrideA{}) == ElementASparsity{}) {
      return cutlass::layout::ColumnMajor{};
    }
    else {
      return  cutlass::layout::RowMajor{};
    }
  }

  // Fill tensor A layout from dynamic problem shape
  template <class ProblemShape>
  CUTE_HOST_DEVICE
  static constexpr auto
  fill_layoutA(ProblemShape problem_shape) {

    const auto [M, N, K, L] = problem_shape;

    // Round up to satisfy TensorA Alignment requirement
    const auto M_AlignedAC = cutlass::round_up(M, TensorAAlignmentM{});
    const auto K_AlignedAC = cutlass::round_up(K, TensorAAlignmentK{});

    if constexpr (GmmaMajorA == GMMA::Major::MN) {
      return make_layout(
        make_shape(int32_t(M_AlignedAC),
                   make_shape(ElementASparsity{}, int32_t(K_AlignedAC) / ElementASparsity{}),
                   int32_t(L)),
        make_stride(ElementASparsity{},
                    make_stride(_1{}, int64_t(M_AlignedAC) * ElementASparsity{}),
                    (L == 1) ? int64_t(0) : int64_t(M_AlignedAC * K_AlignedAC))
      );
    }
    else {
      return make_layout(
        make_shape(int32_t(M_AlignedAC),
                   make_shape(ElementASparsity{}, int32_t(K_AlignedAC / ElementASparsity{})),
                   int32_t(L)),
        make_stride(int64_t(K_AlignedAC),
                    make_stride(_1{}, ElementASparsity{}),
                    (L == 1) ? int64_t(0) : int64_t(M_AlignedAC * K_AlignedAC))
      );
    }
  }

  // Fill tensor E layout from dynamic problem shape
  template <class ProblemShape>
  CUTE_HOST_DEVICE
  static constexpr auto
  fill_layoutE(ProblemShape problem_shape) {
    const auto [M, N, K, L] = problem_shape;

    // Round up to satisfy TensorEAlignment requirement
    const auto M_AlignedE = cutlass::round_up(M, TensorEAlignmentM{});
    const auto K_AlignedE = cutlass::round_up(K, TensorEAlignmentK{});

    // TensorEAtom first along m-dim, then along k-dim, then along batch
    static_assert(TensorEAlignmentM{} == TensorEAtomM{}, "Shape below assumes TensorEAlignmentM == TensorEAtomM");
    static_assert(TensorEAlignmentK{} == TensorEAtomK{}, "Shape below assumes TensorEAlignmentK == TensorEAtomK");

    return make_layout(
      make_shape(make_shape(shape<0>(TensorEAtom{}), int32_t(M_AlignedE / TensorEAtomM{})),
                 make_shape(shape<1>(TensorEAtom{}), int32_t(K_AlignedE / TensorEAtomK{})),
                 int32_t(L)),
      make_stride(make_stride(stride<0>(TensorEAtom{}), cute::Int<cute::cosize(TensorEAtom{})>{}),
                  make_stride(stride<1>(TensorEAtom{}), int64_t(M_AlignedE * TensorEAtomK{})),
                  (L == 1) ? int64_t(0) : int64_t(M_AlignedE * K_AlignedE))
    );
  }
};

} // namespace cutlass
