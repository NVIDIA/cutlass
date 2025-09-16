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

#if defined(__SYCL_DEVICE_ONLY__) && defined(SYCL_INTEL_TARGET)
#define CUTE_ARCH_MMA_XE_ENABLED
#endif

#include <cute/config.hpp>
#include <cute/arch/mma.hpp>
#include <cute/util/sycl_vec.hpp>

namespace cute {

template <int M, typename TypeD, typename TypeA, typename TypeB = TypeA, typename TypeC = TypeD>
struct XE_DPAS_TT;

template <int M, typename TypeD, typename TypeA, typename TypeB, typename TypeC>
struct XE_DPAS_TT_Base
{
  static constexpr int K = 256 / cute::max(sizeof_bits_v<TypeA>, sizeof_bits_v<TypeB>);

  using DVector = intel::vector_t<TypeD, M>;
  using AVector = intel::vector_t<TypeA, (M * K + 15) / 16>;
  using BVector = intel::vector_t<TypeB, K>;
  using CVector = intel::vector_t<TypeC, M>;

  using DRegisters = DVector[1];
  using ARegisters = AVector[1];
  using BRegisters = BVector[1];
  using CRegisters = CVector[1];
};

namespace dpas_type {

using f = float;
using tf32 = tfloat32_t;
using bf = bfloat16_t;
using hf = half_t;
using ud = uint32_t;
using d = int32_t;
using u8 = uint8_t;
using s8 = int8_t;
using u4 = uint4_t;
using s4 = int4_t;

}; /* namespace dpas_type */

#ifdef CUTE_ARCH_MMA_XE_ENABLED

#define CUTE_DECLARE_XE_DPAS_TT(TD, TA, TB, TC) \
template <int M> struct XE_DPAS_TT<M, dpas_type::TD, dpas_type::TA, dpas_type::TB, dpas_type::TC> \
    : public XE_DPAS_TT_Base<M, dpas_type::TD, dpas_type::TA, dpas_type::TB, dpas_type::TC> { \
  using Base = XE_DPAS_TT_Base<M, dpas_type::TD, dpas_type::TA, dpas_type::TB, dpas_type::TC>; \
  using AVector = typename Base::AVector; \
  using BVector = typename Base::BVector; \
  using CVector = typename Base::CVector; \
  using DVector = typename Base::DVector; \
  template <typename CVector_ = CVector> \
  CUTE_DEVICE static void \
  fma(DVector& d, AVector const& a, BVector const& b, CVector_ const& c) { \
    if constexpr (std::is_same_v<CVector_, DVector>) { \
      d = c; \
      asm ( \
        "{\n" \
        ".decl DST     v_type=G type=" #TD " num_elts=%5 alias=<%0,0>\n" \
        ".decl SRC1_UD v_type=G type=UD num_elts=128 alias=<%2,0>\n" \
        ".decl SRC2_UD v_type=G type=UD num_elts=%4 alias=<%1,0>\n" \
        "dpas." #TB "." #TA ".8.%3 (M1, 16) DST.0 DST.0 SRC1_UD.0 SRC2_UD(0,0)\n" \
        "}\n" \
        : "+rw"(d) : "rw"(a), "rw"(b), "P"(M), "P"(M*8), "P"(M*16) \
      ); \
    } else { \
      asm ( \
        "{\n" \
        ".decl DST     v_type=G type=" #TD " num_elts=%6 alias=<%0,0>\n" \
        ".decl SRC0    v_type=G type=" #TC " num_elts=%6 alias=<%3,0>\n" \
        ".decl SRC1_UD v_type=G type=UD num_elts=128 alias=<%2,0>\n" \
        ".decl SRC2_UD v_type=G type=UD num_elts=%5 alias=<%1,0>\n" \
        "dpas." #TB "." #TA ".8.%4 (M1, 16) DST.0 SRC0.0 SRC1_UD.0 SRC2_UD(0,0)\n" \
        "}\n" \
        : "=rw"(d) : "rw"(a), "rw"(b), "rw"(c), "P"(M), "P"(M*8), "P"(M*16) \
      ); \
    } \
  } \
};

#else /* !defined(CUTE_ARCH_MMA_XE_ENABLED) */

#define CUTE_DECLARE_XE_DPAS_TT(TD, TA, TB, TC) \
template <int M> struct XE_DPAS_TT<M, dpas_type::TD, dpas_type::TA, dpas_type::TB, dpas_type::TC> \
  : public XE_DPAS_TT_Base<M, dpas_type::TD, dpas_type::TA, dpas_type::TB, dpas_type::TC> { \
  using Base = XE_DPAS_TT_Base<M, dpas_type::TD, dpas_type::TA, dpas_type::TB, dpas_type::TC>; \
  using AVector = typename Base::AVector; \
  using BVector = typename Base::BVector; \
  using CVector = typename Base::CVector; \
  using DVector = typename Base::DVector; \
  CUTE_HOST_DEVICE static void \
  fma(DVector& d, AVector const& a, BVector const& b, CVector const& c) { \
    CUTE_INVALID_CONTROL_PATH("Cannot use Xe DPAS MMA atom on non-Xe hardware"); \
  } \
};
#endif


CUTE_DECLARE_XE_DPAS_TT(f,   tf32, tf32, f)

CUTE_DECLARE_XE_DPAS_TT(f,   bf,   bf,   f)
CUTE_DECLARE_XE_DPAS_TT(bf,  bf,   bf,   f)
CUTE_DECLARE_XE_DPAS_TT(f,   bf,   bf,   bf)
CUTE_DECLARE_XE_DPAS_TT(bf,  bf,   bf,   bf)

CUTE_DECLARE_XE_DPAS_TT(f,   hf,   hf,   f)
CUTE_DECLARE_XE_DPAS_TT(f,   hf,   hf,   hf)
CUTE_DECLARE_XE_DPAS_TT(hf,  hf,   hf,   f)
CUTE_DECLARE_XE_DPAS_TT(hf,  hf,   hf,   hf)

CUTE_DECLARE_XE_DPAS_TT(ud,  u8,   u8,   ud)
CUTE_DECLARE_XE_DPAS_TT(d,   u8,   u8,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   u8,   s8,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   s8,   u8,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   s8,   s8,   d)

CUTE_DECLARE_XE_DPAS_TT(ud,  u8,   u4,   ud)
CUTE_DECLARE_XE_DPAS_TT(d,   u8,   u4,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   u8,   s4,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   s8,   u4,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   s8,   s4,   d)

CUTE_DECLARE_XE_DPAS_TT(ud,  u4,   u8,   ud)
CUTE_DECLARE_XE_DPAS_TT(d,   u4,   u8,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   u4,   s8,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   s4,   u8,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   s4,   s8,   d)

CUTE_DECLARE_XE_DPAS_TT(ud,  u4,   u4,   ud)
CUTE_DECLARE_XE_DPAS_TT(d,   u4,   u4,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   u4,   s4,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   s4,   u4,   d)
CUTE_DECLARE_XE_DPAS_TT(d,   s4,   s4,   d)

#undef CUTE_DECLARE_XE_DPAS_TT

} //namespace cute
