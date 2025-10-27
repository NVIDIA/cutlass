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

#include <cute/util/sycl_vec.hpp>

namespace cute
{

// Reorder kinds.
//   "U" -> unit stride in registers
//   "V" -> VNNI format in registers
// e.g. UV means "unit to VNNI"
enum class ReorderKind : int { UU_Universal, UU, UV, VU, VV, Generic };

template <ReorderKind kind, typename SrcType, typename DstType>
struct Xe_Reorder {
  using Unimplemented = void;
};

// Check for the existence of an optimized reorder sequence.
template <ReorderKind kind, typename SrcType, typename DstType>
constexpr bool has_xe_optimized_reorder_impl(char) { return true; }
template <ReorderKind kind, typename SrcType, typename DstType, typename V = typename Xe_Reorder<kind, SrcType, DstType>::Unimplemented>
constexpr bool has_xe_optimized_reorder_impl(int) { return false; }

template <ReorderKind kind, typename SrcType, typename DstType>
constexpr bool has_xe_optimized_reorder() {
  return has_xe_optimized_reorder_impl<kind, SrcType, DstType>(0);
}

// Classify a subgroup-scope reorder.
template <int SV, int DV, class ReorderLayout>
constexpr ReorderKind classify_xe_reorder()
{
  constexpr int R = rank(ReorderLayout{});
  using Size0   = decltype(size<0>(ReorderLayout{}));
  using Stride0 = decltype(stride<0>(ReorderLayout{}));
  using _SV = Int<SV>;
  using _DV = Int<DV>;

  constexpr int VL = 16 * cute::max(SV, DV);
  if (is_constant_v<1, Stride0>) {
    // Unit stride -> unit stride. Require whole GRFs for both src and dst.
    if constexpr (is_constant_v<0, decltype(Size0{} % Int<VL>{})>) {
      return ReorderKind::UU;
    }

    // Fallback unit->unit when we do not have full GRFs.
    if constexpr (is_constant_v<0, decltype(Size0{} % _16{})>) {
      return ReorderKind::UU_Universal;
    }
  }

  // Check for VNNI reorders.
  // Fundamental assumption: values associated with a single VNNI block are contiguous in val space
  //   in both src and dst (even if only one of those is in VNNI format). All others take the generic path.
  if constexpr (R >= 2) {
    constexpr auto Modes01 = take<0,2>(ReorderLayout{});

    // Check for unit <-> VNNI reorders.
    //   unit->VNNI:  (_16, _DV, ...):(_DV, _1, ...)
    //   VNNI->unit:  (_SV, _16, ...):(_16, _1, ...)
    if constexpr (Modes01 == Layout<Shape<_16, _DV>, Stride<_DV, _1>>{}) {
      return ReorderKind::UV;
    }
    if constexpr (Modes01 == Layout<Shape<_SV, _16>, Stride<_16, _1>>{}) {
      return ReorderKind::VU;
    }

    // Check for VNNI -> VNNI reorders.
    //  SV > DV:  (_DV, _SV/DV, _16, ...):(_1, _DV*16, _DV, ...)
    //  DV > SV:  (_SV, _16, _DV/SV, ...):(_1, _SV*16, _SV, ...)
    if constexpr (R >= 3 && SV != DV) {
      constexpr auto Modes012 = take<0,3>(ReorderLayout());
      if constexpr (SV > DV && Modes012 == Layout<Shape<_DV, Int<SV/DV>, _16>, Stride<_1, Int<DV*16>, _DV>>{}) {
        return ReorderKind::VV;
      } else if constexpr (DV > SV && Modes012 == Layout<Shape<_SV, _16, Int<DV/SV>>, Stride<_1, Int<SV*16>, _SV>>{}) {
        return ReorderKind::VV;
      }
    }
  }

  return ReorderKind::Generic;
}

template <class SType, class DType,
          class SLayout, class DLayout>
auto choose_xe_reorder_impl(SLayout const& slayout,   // (src thr, src val) -> coord
                            DLayout const& dlayout) { // (dst thr, dst val) -> coord
  // Calculate data transformation, interleaving WI-owned values:
  //  (thr0,val0) ... (thr15,val0), (thr0,val1), ..., (thr15,val1), ...
  auto rlayout = coalesce(composition(right_inverse(dlayout), slayout));          // src index -> dst index

  // Classify reorder type.
  constexpr auto SV = 32 / sizeof_bits_v<SType>;  // src elements per 32-bit channel
  constexpr auto DV = 32 / sizeof_bits_v<DType>;  // dst elements per 32-bit channel
  constexpr auto rclass = classify_xe_reorder<SV, DV, decltype(rlayout)>();

  if constexpr (rclass == ReorderKind::UU_Universal)
    return Universal_Reorder_UU<SType, DType>{};
  else if constexpr (has_xe_optimized_reorder<rclass, SType, DType>())
    return Xe_Reorder<rclass, SType, DType>{};
  else if constexpr (is_subbyte_v<SType>)
    return ReorderDispatchConvertRelayout{};
  else if constexpr (is_subbyte_v<DType>)
    return ReorderDispatchRelayoutConvert{};
  else if constexpr (!is_same_v<remove_cv_t<SType>, remove_cv_t<DType>>)
    return ReorderDispatchRelayoutConvert{};
  else
    return ReorderDispatchXeGeneric{};
}


// Copy a strided vector to a strided vector in GRF.
//   src and dst must each fit within a single register.
template <int simd, int sstride, int dstride, int sidx, int didx,
          class SEngine, class SLayoutWI,
          class DEngine, class DLayoutWI>
CUTE_HOST_DEVICE
void
reorder_span(Tensor<SEngine,SLayoutWI> const& src,
             Tensor<DEngine,DLayoutWI> &      dst)
{
  using namespace intel;
  using ValType = typename SEngine::element_type;
  using StorageType = storage_vector_t<ValType, 32>;
  constexpr int grf_elems = 64 / sizeof(ValType);
  const auto& sv = *recast_ptr<StorageType>(src.data() + ((sidx / grf_elems) * (grf_elems / sg_size)));
  auto&       dv = *recast_ptr<StorageType>(dst.data() + ((didx / grf_elems) * (grf_elems / sg_size)));
  constexpr auto soff = sidx % grf_elems;
  constexpr auto doff = didx % grf_elems;
#ifdef __SYCL_DEVICE_ONLY__
  asm (
    "mov (M1_NM, %2) %0(0,%5)<%3> %1(0,%6)<%4;1,0>"
    : "+rw"(dv)
    : "rw"(sv), "P"(simd), "P"(dstride), "P"(sstride), "P"(doff), "P"(soff)
  );
#endif
}

// Generic Xe reorders, supporting arbitrary layout changes, but not type conversions.
template <class SEngine, class SLayoutWI, class SLayout,
          class DEngine, class DLayoutWI, class DLayout>
CUTE_HOST_DEVICE
void
reorder_impl(ReorderDispatchXeGeneric  const&,
             Tensor<SEngine,SLayoutWI> const& src,       // WI fragment
             Tensor<DEngine,DLayoutWI> &      dst,       // WI fragment
             SLayout                   const& slayout,   // (src thr, src val) -> coord
             DLayout                   const& dlayout)   // (dst thr, dst val) -> coord
{
  using SrcType = typename SEngine::element_type;
  using DstType = typename DEngine::element_type;
  static_assert(is_same_v<SrcType, DstType>, "No type conversions allowed on this path");

  auto rlayout = coalesce(composition(right_inverse(dlayout), slayout));          // src index -> dst index
  auto ilayout = coalesce(composition(right_inverse(slayout), dlayout));          // dst index -> src index

  // Decide whether to stride on src or dst, depending on which allows a longer vector length.
  static constexpr int elems_per_grf = 64 / sizeof(SrcType);
  static constexpr int ds_vl = cute::min(32, cute::min(shape<0>(rlayout), elems_per_grf / stride<0>(rlayout)));
  static constexpr int ss_vl = cute::min(32, cute::min(shape<0>(ilayout), elems_per_grf / stride<0>(ilayout)));

  // Make dst live, to prevent compiler from inserting its own initialization.
#ifdef __SYCL_DEVICE_ONLY__
  using StorageType = intel::storage_vector_t<DstType, 32>;

  CUTE_UNROLL
  for (int i = 0; i < dst.size(); i += 4 / sizeof(DstType)) {
    auto &dv = *recast_ptr<StorageType>(dst.data() + i);
    asm("" : "=rw"(dv));
  }
#endif

  if constexpr (ss_vl >= ds_vl) {
    // Stride on src. For simplicity, take 1 GRF at a time.
    for_each(make_seq<size(SLayout{}) / ss_vl>{}, [&](auto i) {
      constexpr auto didx = i * ss_vl;
      constexpr auto sidx = ilayout(didx);
      reorder_span<ss_vl, stride<0>(decltype(ilayout){}), 1, sidx, didx>(src, dst);
    });
  } else {
    // Stride on dst.
    for_each(make_seq<size(SLayout{}) / ds_vl>{}, [&](auto i) {
      constexpr auto sidx = i * ds_vl;
      constexpr auto didx = rlayout(sidx);
      reorder_span<ds_vl, 1, stride<0>(decltype(rlayout){}), sidx, didx>(src, dst);
    });
  }
}

//
// Display utilities
//
CUTE_HOST_DEVICE
void
print(ReorderKind kind) {
#define CASE(x) if (kind == ReorderKind::x) print(#x);
  CASE(UU_Universal)
  CASE(UU)
  CASE(UV)
  CASE(VU)
  CASE(VV)
  CASE(Generic)
#undef CASE
}

} // end namespace cute


#include <cute/arch/reorder_xe.hpp>
