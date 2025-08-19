/***************************************************************************************************
* Copyright (C) 2025 Intel Corporation, All rights reserved.
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

#include <cute/config.hpp>            // CUTE_HOST_DEVICE
#include <cute/tensor_impl.hpp>       // cute::Tensor
#include <cute/atom/reorder_atom.hpp>

// Subgroup-level ("warp" in CUDA terminology) register-to-register reorder operations.
// Currently implemented for Xe only.


namespace cute
{

namespace detail {

// Modify subgroup TV layout for subbyte types.
//
// In general on Xe successive elements in registers are assigned to work-items in
//   round-robin order (interleaved at element granularity). However, subbyte types are
//   only interleaved at byte granularity.
//
// This routine modifies the incoming layout to appear as though work-item ownership for subbyte
//   types is also at element granularity, to uniformize later logic.
template <class T, class InLayout>
CUTE_HOST_DEVICE
constexpr decltype(auto)
subbyte_sg_tv_swizzle(const InLayout &layout)
{
#ifdef SYCL_INTEL_TARGET
  using namespace intel;
  if constexpr (sizeof_bits_v<T> >= 8)
    return layout;
  else {
    static_assert(is_static_v<InLayout>, "Layout must be static");
    constexpr auto values = size(InLayout{}) / sg_size;
    constexpr auto per_byte = 8 / sizeof_bits_v<T>;
    static_assert(values % per_byte == 0, "Partially-occupied bytes in layout");
    return composition(layout, Layout<Shape<Shape<C<per_byte>, C<sg_size/per_byte>>, Shape<C<per_byte>, C<values/per_byte>>>,
                                      Stride<Stride<_SGSize, _1>, Stride<C<sg_size/per_byte>, C<sg_size*per_byte>>>>{});
  }
#else
  return layout;
#endif
}

} /* namespace detail */

// Subgroup-cooperative reorder.
//          src, dst: WI-owned fragments
//  slayout, dlayout: subgroup TV-layouts for these fragments.
//
// The layout of src/dst can be arbitrary. The TV layouts
//   are used to map values in src to values in dst.
template <class SEngine, class SLayoutWI, class SLayout,
          class DEngine, class DLayoutWI, class DLayout>
CUTE_HOST_DEVICE
void
reorder(Tensor<SEngine,SLayoutWI> const& src,       // WI fragment
        Tensor<DEngine,DLayoutWI> &      dst,       // WI fragment
        SLayout                   const& slayout,   // (src thr, src val) -> coord
        DLayout                   const& dlayout)   // (dst thr, dst val) -> coord
{
  using SType = typename SEngine::element_type;
  using DType = typename DEngine::element_type;

  static_assert(is_static_v<SLayout>, "Reorder source layout must be static");
  static_assert(is_static_v<DLayout>, "Reorder destination layout must be static");

  auto sl0 = detail::subbyte_sg_tv_swizzle<SType>(project_strides(slayout));
  auto dl0 = detail::subbyte_sg_tv_swizzle<DType>(project_strides(dlayout));

#ifdef SYCL_INTEL_TARGET
  auto impl = choose_xe_reorder_impl<SType, DType>(sl0, dl0);   // -> atom or dispatch tag
#else
  static_assert("Reorder only implemented on Xe");
#endif

  reorder_impl(impl, src, dst, sl0, dl0);
}

template <class SEngine, class SLayoutWI, class SLayout,
          class DEngine, class DLayoutWI, class DLayout>
CUTE_HOST_DEVICE
void
reorder(SubgroupTensor<SEngine,SLayoutWI,SLayout> const& src,
        SubgroupTensor<DEngine,DLayoutWI,DLayout> &      dst)
{
  reorder(src, dst, src.tv_layout(), dst.tv_layout());
}

// Accept mutable temporaries
template <class SEngine, class SLayoutWI, class SLayout,
          class DEngine, class DLayoutWI, class DLayout>
CUTE_HOST_DEVICE
void
reorder(Tensor<SEngine,SLayoutWI> const& src,       // WI fragment
        Tensor<DEngine,DLayoutWI>     && dst,       // WI fragment
        SLayout                   const& slayout,   // (src thr, src val) -> coord
        DLayout                   const& dlayout)   // (dst thr, dst val) -> coord
{
  reorder(src, dst, slayout, dlayout);
}

template <class SEngine, class SLayoutWI, class SLayout,
          class DEngine, class DLayoutWI, class DLayout>
CUTE_HOST_DEVICE
void
reorder(SubgroupTensor<SEngine,SLayoutWI,SLayout> const& src,
        SubgroupTensor<DEngine,DLayoutWI,DLayout>     && dst)
{
  reorder(src, dst);
}

// Base case for reorders: loop over reorder atoms
template <class ReorderAtom,
          class SEngine, class SLayoutWI, class SLayout,
          class DEngine, class DLayoutWI, class DLayout>
CUTE_HOST_DEVICE
void
reorder_impl(ReorderAtom               const& atom,
             Tensor<SEngine,SLayoutWI> const& src,       // WI fragment
             Tensor<DEngine,DLayoutWI> &      dst,       // WI fragment
             SLayout                   const& slayout,   // (src thr, src val) -> coord
             DLayout                   const& dlayout)   // (dst thr, dst val) -> coord
{
  using _SG = intel::_SGSize;
  using SType = typename SEngine::element_type;
  using RegistersSrc = typename ReorderAtom::SRegisters;
  using RegistersDst = typename ReorderAtom::DRegisters;
  using RegTypeSrc   = typename remove_extent<RegistersSrc>::type;
  using RegTypeDst   = typename remove_extent<RegistersDst>::type;
  constexpr int RegNumSrc = extent<RegistersSrc>::value;
  constexpr int RegNumDst = extent<RegistersDst>::value;
  constexpr int values = size(SLayout{}) / size<0>(SLayout{});
  constexpr int vchunk = sizeof_bits_v<RegistersSrc> / sizeof_bits_v<SType>;

  // Calculate mapping from src val -> dst val on a chunk-by-chunk basis. Unlike a plain copy, there is no intrinsic
  //   correspondence of src/dst values for subgroup reorders.
  auto rlayout = coalesce(composition(right_inverse(dlayout), slayout));                 // src index -> dst index
  auto vrlayout = composition(composition(Layout<Shape<_SG, Int<values>>, Stride<_0, _1>>{},
                                          rlayout),
                              Layout<Shape<_1, Int<values>>, Stride<_0, _SG>>{});        // src val -> dst val

  CUTE_UNROLL
  for (int sv = 0; sv < values; sv += vchunk) {
    auto pS = recast_ptr<RegTypeSrc>(src.data() + sv);
    auto pD = recast_ptr<RegTypeDst>(dst.data() + vrlayout(sv));

    detail::explode(detail::CallReorder<ReorderAtom>{},
                    pS, make_int_sequence<RegNumSrc>{},
                    pD, make_int_sequence<RegNumDst>{});
  }
}

template <typename T>
using upcast_subbyte_t = conditional_t<is_subbyte_v<T>,
                                       conditional_t<cutlass::platform::numeric_limits<T>::is_integer,
                                                     conditional_t<cutlass::platform::numeric_limits<T>::is_signed,
                                                                   int8_t, uint8_t>,
                                                     half_t>,
                                       T>;

// Reorder strategy: type conversion, then layout change.
template <class SEngine, class SLayoutWI, class SLayout,
          class DEngine, class DLayoutWI, class DLayout>
CUTE_HOST_DEVICE
void
reorder_impl(ReorderDispatchConvertRelayout const&,
             Tensor<SEngine,SLayoutWI> const& src,       // WI fragment
             Tensor<DEngine,DLayoutWI> &      dst,       // WI fragment
             SLayout                   const& slayout,   // (src thr, src val) -> coord
             DLayout                   const& dlayout)   // (dst thr, dst val) -> coord
{
  using SrcType = typename SEngine::element_type;
  using DstType = typename DEngine::element_type;
  using NewSrcType = conditional_t<is_subbyte_v<SrcType>, upcast_subbyte_t<SrcType>, DstType>;
  auto src_c = make_fragment_like<NewSrcType>(src);

  reorder(src, src_c, slayout, slayout);
  reorder(src_c, dst, slayout, dlayout);
}

// Reorder strategy: layout change, then type conversion
template <class SEngine, class SLayoutWI, class SLayout,
          class DEngine, class DLayoutWI, class DLayout>
CUTE_HOST_DEVICE
void
reorder_impl(ReorderDispatchRelayoutConvert const&,
             Tensor<SEngine,SLayoutWI> const& src,       // WI fragment
             Tensor<DEngine,DLayoutWI> &      dst,       // WI fragment
             SLayout                   const& slayout,   // (src thr, src val) -> coord
             DLayout                   const& dlayout)   // (dst thr, dst val) -> coord
{
  using SrcType = typename SEngine::element_type;
  using DstType = typename DEngine::element_type;
  using NewDstType = conditional_t<is_same_v<SrcType, DstType>, upcast_subbyte_t<DstType>, SrcType>;
  auto dst_c = make_fragment_like<NewDstType>(dst);

  reorder(src, dst_c, slayout, dlayout);
  reorder(dst_c, dst, dlayout, dlayout);
}


} // end namespace cute
