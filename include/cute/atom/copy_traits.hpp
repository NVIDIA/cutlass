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

#include <cute/arch/copy.hpp>

#include <cute/tensor.hpp>

namespace cute
{

/**
 * concept Copy_Traits
 * {
 *   using ThrID     =    // Logical thread id (tid) -> tidx
 *
 *   using SrcLayout =    // (Logical src thread id (tid), Logical src value id (vid)) -> bit
 *   using DstLayout =    // (Logical dst thread id (tid), Logical dst value id (vid)) -> bit
 *   using RefLayout =    // (Logical ref thread id (tid), Logical ref value id (vid)) -> bit
 * };
 *
 * The abstract bit ordering of the Copy_Traits (the codomain of SrcLayout, DstLayout, and RefLayout)
 * is arbitrary and only used to construct maps
 *   (ref-tid,ref-vid) -> (src-tid,src-vid)
 *   (ref-tid,ref-vid) -> (dst-tid,dst-vid)
 * in TiledCopy. The Layout_TV in TiledCopy is in accordance with the RefLayout of a Traits, then mapped to
 * the Src or Dst (tid,vid) representation on demand.
 *
 */

template <class CopyOperation, class... CopyOpArgs>
struct Copy_Traits
{
  static_assert(sizeof(CopyOperation) == 0, "Copy_Traits not implemented for this Copy_Operation.");
};

template <class S, class D>
struct Copy_Traits<UniversalCopy<S,D>>
{
  // Logical thread id to thread idx (one-thread)
  using ThrID = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,Int<sizeof_bits<S>::value>>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,Int<sizeof_bits<D>::value>>>;

  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;
};

template <>
struct Copy_Traits<DefaultCopy>
{
  // Logical thread id to thread idx (one-thread)
  using ThrID = Layout<_1>;

  // Map from (src-thr,src-val) to bit
  using SrcLayout = Layout<Shape<_1,_1>, Stride<_0,_0>>;
  // Map from (dst-thr,dst-val) to bit
  using DstLayout = Layout<Shape<_1,_1>, Stride<_0,_0>>;

  // Reference map from (thr,val) to bit
  using RefLayout = SrcLayout;
};

//
// Generic copy_unpack for any Copy_Traits
//
template <class Operation, class... Args,
          class TS, class SLayout,
          class TD, class DLayout>
CUTE_HOST_DEVICE constexpr
void
copy_unpack(Copy_Traits<Operation, Args...> const&,
            Tensor<TS,SLayout> const& src,
            Tensor<TD,DLayout>      & dst)
{
  // Specializations can generalize on these checks
  //static_assert(is_smem<TS>::value, "Expected smem for this Copy_Traits<Operation>");
  //static_assert(is_rmem<TD>::value, "Expected rmem for this Copy_Traits<Operation>");

  using RegistersSrc = typename Operation::SRegisters;
  using RegistersDst = typename Operation::DRegisters;
  using RegTypeSrc   = typename remove_extent<RegistersSrc>::type;
  using RegTypeDst   = typename remove_extent<RegistersDst>::type;
  constexpr int RegNumSrc = extent<RegistersSrc>::value;
  constexpr int RegNumDst = extent<RegistersDst>::value;

  Tensor rS = recast<RegTypeSrc>(src);
  Tensor rD = recast<RegTypeDst>(dst);

  CUTE_STATIC_ASSERT_V(size(rS) == Int<RegNumSrc>{},
    "In CopyAtom, src layout doesn't vectorize into registers. This src layout is incompatible with this tiled copy.");
  CUTE_STATIC_ASSERT_V(size(rD) == Int<RegNumDst>{},
    "In CopyAtom, dst layout doesn't vectorize into registers. This dst layout is incompatible with this tiled copy.");

  detail::explode(Operation::copy,
                  rS, make_int_sequence<RegNumSrc>{},
                  rD, make_int_sequence<RegNumDst>{});
}

} // end namespace cute
