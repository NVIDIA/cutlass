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

#include <cute/util/sycl_vec.hpp>           // native vector types
#include <cute/arch/reorder.hpp>            // Universal_Reorder_UU

#if defined(__SYCL_DEVICE_ONLY__) && defined(SYCL_INTEL_TARGET)
#define CUTE_ARCH_REORDER_XE_ENABLED
#endif

namespace cute {

template <typename SrcType, typename DstType>
struct Xe_Reorder<ReorderKind::UU, SrcType, DstType> : Universal_Reorder_UU<SrcType, DstType> {};

template <typename T>
struct Xe_Reorder<ReorderKind::UU, T, T> {
  using StorageT = conditional_t<(sizeof_bits_v<T> >= 8), T, uint8_t>;
  using SRegisters = StorageT[1];
  using DRegisters = StorageT[1];

  CUTE_HOST_DEVICE static void
  reorder(StorageT const& src0, StorageT& dst0) {
    dst0 = src0;
  }
};

template <>
struct Xe_Reorder<ReorderKind::UU, uint8_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 2 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      ".decl OUT_HF v_type=G type=HF num_elts=64 alias=<%0,0>\n"
      "or  (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;1,0>  0x6400:uw\n"
      "or  (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,32)<1;1,0> 0x6400:uw\n"
      "add (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0xE400:hf\n"
      "add (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0xE400:hf\n"
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, uint8_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 2 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      ".decl OUT_HF v_type=G type=HF num_elts=64 alias=<%0,0>\n"
      "or  (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,1>  0x6400:uw\n"
      "or  (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,2)<4;2,1>  0x6400:uw\n"
      "add (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0xE400:hf\n"
      "add (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0xE400:hf\n"
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::UU, int8_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 2 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      ".decl OUT_HF v_type=G type=HF num_elts=64 alias=<%0,0>\n"
      "xor (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;1,0>  0x6480:uw\n"
      "xor (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,32)<1;1,0> 0x6480:uw\n"
      "add (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0xE480:hf\n"
      "add (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0xE480:hf\n"
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, int8_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 2 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      ".decl OUT_HF v_type=G type=HF num_elts=64 alias=<%0,0>\n"
      "xor (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,1>  0x6480:uw\n"
      "xor (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,2)<4;2,1>  0x6480:uw\n"
      "add (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0xE480:hf\n"
      "add (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0xE480:hf\n"
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

// Common uint8 -> bfloat16 conversion sequence, after unpacking bytes to words.
// This is defined as a macro as the compiler produces more efficient code
//   when inline asm blocks are merged.
#define CUTE_XE_REORDER_U8_BF16_SEQ \
    ".decl OUT_HF v_type=G type=HF num_elts=64 alias=<%0,0>\n" \
    ".decl OUT_BF v_type=G type=BF num_elts=64 alias=<%0,0>\n" \
    "mul (M1_NM, 32) OUT_BF(0,0)<1> OUT_BF(0,0)<1;1,0> 0x7E000000:f\n" \
    "mul (M1_NM, 32) OUT_BF(1,0)<1> OUT_BF(1,0)<1;1,0> 0x7E000000:f\n" \
    "mul (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0x4000:hf\n" \
    "mul (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0x4000:hf\n"


template <>
struct Xe_Reorder<ReorderKind::UU, uint8_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "mov (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;1,0>\n"
      "mov (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,32)<1;1,0>\n"
      CUTE_XE_REORDER_U8_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, uint8_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "mov (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,1>\n"
      "mov (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,2)<4;2,1>\n"
      CUTE_XE_REORDER_U8_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};


// Common int8 -> bfloat16 conversion sequence, after unpacking bytes to words.
#define CUTE_XE_REORDER_S8_BF16_SEQ \
    ".decl OUT_HF v_type=G type=HF num_elts=64 alias=<%0,0>\n" \
    ".decl OUT_BF v_type=G type=BF num_elts=64 alias=<%0,0>\n" \
    ".decl F_7E000000 v_type=G type=F num_elts=1 alias=<%2,0>\n" \
    ".decl F_BF000000 v_type=G type=F num_elts=1 alias=<%3,0>\n" \
    "mad (M1_NM, 32) OUT_BF(0,0)<1> F_7E000000(0,0)<0;1,0> OUT_BF(0,0)<1;1,0> F_BF000000(0,0)<0;1,0>\n" \
    "mad (M1_NM, 32) OUT_BF(1,0)<1> F_7E000000(0,0)<0;1,0> OUT_BF(1,0)<1;1,0> F_BF000000(0,0)<0;1,0>\n" \
    "mul (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0x4000:hf\n" \
    "mul (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0x4000:hf\n"


template <>
struct Xe_Reorder<ReorderKind::UU, int8_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t scale = 0x7E000000;
    const uint32_t shift = 0xBF000000;
    asm (     /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "xor (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;1,0>  0x80:uw\n"
      "xor (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,32)<1;1,0> 0x80:uw\n"
      CUTE_XE_REORDER_S8_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(scale), "rw.u"(shift)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, int8_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t scale = 0x7E000000;
    const uint32_t shift = 0xBF000000;
    asm (     /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "xor (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,1> 0x80:uw\n"
      "xor (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,2)<4;2,1> 0x80:uw\n"
      CUTE_XE_REORDER_S8_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(scale), "rw.u"(shift)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::UU, float_e5m2_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 1 cycle/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;1,0> 8:uw\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,32)<1;1,0> 8:uw\n"
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, float_e5m2_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 1 cycle/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,1> 8:uw\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,2)<4;2,1> 8:uw\n"
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

// Common e5m2 -> bfloat16 conversion sequence, after shl by 8.
#define CUTE_XE_REORDER_E5M2_BF16_SEQ \
    ".decl OUT_W v_type=G type=W num_elts=64 alias=<%0,0>\n" \
    ".decl OUT_UD v_type=G type=UD num_elts=32 alias=<%0,0>\n" \
    ".decl OUT_BF v_type=G type=BF num_elts=64 alias=<%0,0>\n" \
    "asr (M1_NM, 32) OUT_W(0,0)<1> OUT_W(0,0)<1;1,0> 3:uw\n" \
    "asr (M1_NM, 32) OUT_W(1,0)<1> OUT_W(1,0)<1;1,0> 3:uw\n" \
    "and (M1_NM, 32) OUT_UD(0,0)<1> OUT_UD(0,0)<1;1,0> 0x8FFF8FFF:ud\n" \
    "mul (M1_NM, 32) OUT_BF(0,0)<1> OUT_BF(0,0)<1;1,0> 0x77800000:f\n" \
    "mul (M1_NM, 32) OUT_BF(1,0)<1> OUT_BF(1,0)<1;1,0> 0x77800000:f\n"

template <>
struct Xe_Reorder<ReorderKind::UU, float_e5m2_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 5 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;1,0> 8:uw\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,32)<1;1,0> 8:uw\n"
      CUTE_XE_REORDER_E5M2_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, float_e5m2_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 5 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,1> 8:uw\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,2)<4;2,1> 8:uw\n"
      CUTE_XE_REORDER_E5M2_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};


// Common e4m3 -> half conversion sequence, after shl by 8.
#define CUTE_XE_REORDER_E4M3_HALF_SEQ \
    ".decl OUT_W v_type=G type=W num_elts=64 alias=<%0,0>\n" \
    ".decl OUT_UD v_type=G type=UD num_elts=32 alias=<%0,0>\n" \
    ".decl OUT_HF v_type=G type=HF num_elts=64 alias=<%0,0>\n" \
    "asr (M1_NM, 32) OUT_W(0,0)<1> OUT_W(0,0)<1;1,0> 1:uw\n" \
    "asr (M1_NM, 32) OUT_W(1,0)<1> OUT_W(1,0)<1;1,0> 1:uw\n" \
    "and (M1_NM, 32) OUT_UD(0,0)<1> OUT_UD(0,0)<1;1,0> 0xBFFFBFFF:ud\n" \
    /* If no NaN inputs, the rest of the sequence can be replaced with: */ \
    /*  "mul (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0x5C00:hf\n" */ \
    /*  "mul (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0x5C00:hf\n" */ \
    "mul (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0x7880:hf\n" \
    "mul (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0x7880:hf\n" \
    "mul (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0x1F1C:hf\n" \
    "mul (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0x1F1C:hf\n" \
    "mad (M1_NM, 32) OUT_HF(0,0)<1> 0x0:hf OUT_HF(0,0)<1;1,0> OUT_HF(0,0)<1;1,0>\n" \
    "mad (M1_NM, 32) OUT_HF(1,0)<1> 0x0:hf OUT_HF(1,0)<1;1,0> OUT_HF(1,0)<1;1,0>\n"

template <>
struct Xe_Reorder<ReorderKind::UU, float_e4m3_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 6 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;1,0> 8:uw\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,32)<1;1,0> 8:uw\n"
      CUTE_XE_REORDER_E4M3_HALF_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, float_e4m3_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 6 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,1> 8:uw\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,2)<4;2,1> 8:uw\n"
      CUTE_XE_REORDER_E4M3_HALF_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

// Common e4m3 -> bfloat16 conversion sequence, after shl by 8.
#define CUTE_XE_REORDER_E4M3_BF16_SEQ \
    ".decl OUT_W v_type=G type=W num_elts=64 alias=<%0,0>\n" \
    ".decl OUT_UD v_type=G type=UD num_elts=32 alias=<%0,0>\n" \
    ".decl OUT_HF v_type=G type=HF num_elts=64 alias=<%0,0>\n" \
    ".decl OUT_BF v_type=G type=BF num_elts=64 alias=<%0,0>\n" \
    ".decl NZ_PRED0 v_type=P num_elts=32\n" \
    ".decl NZ_PRED1 v_type=P num_elts=32\n" \
    "asr (M1_NM, 32) OUT_W(0,0)<1> OUT_W(0,0)<1;1,0> 4:uw\n" \
    "asr (M1_NM, 32) OUT_W(1,0)<1> OUT_W(1,0)<1;1,0> 4:uw\n" \
    "and (M1_NM, 32) OUT_UD(0,0)<1> OUT_UD(0,0)<1;1,0> 0x87FF87FF:ud\n" \
    "cmp.ge (M1_NM, 32) NZ_PRED0 (abs)OUT_HF(0,0)<1;1,0> 0x07F0:hf\n" \
    "cmp.ge (M1_NM, 32) NZ_PRED1 (abs)OUT_HF(1,0)<1;1,0> 0x07F0:hf\n" \
    "mul (M1_NM, 32) OUT_BF(0,0)<1> OUT_BF(0,0)<1;1,0> 0x7B800000:f\n" \
    "mul (M1_NM, 32) OUT_BF(1,0)<1> OUT_BF(1,0)<1;1,0> 0x7B800000:f\n" \
    "(NZ_PRED0) mov (M1_NM, 32) OUT_UW(0,0)<1> 0x7FC0:uw\n" \
    "(NZ_PRED1) mov (M1_NM, 32) OUT_UW(1,0)<1> 0x7FC0:uw\n"

template <>
struct Xe_Reorder<ReorderKind::UU, float_e4m3_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 7 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;1,0> 8:uw\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,32)<1;1,0> 8:uw\n"
      CUTE_XE_REORDER_E4M3_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, float_e4m3_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort4[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort4& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    asm (     /* 7 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=64 alias=<%0,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,1> 8:uw\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,2)<4;2,1> 8:uw\n"
      CUTE_XE_REORDER_E4M3_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

// Common uint4 -> half conversion sequence, after expanding nybbles to words.
#define CUTE_XE_REORDER_U4_HALF_SEQ \
    ".decl OUT_HF v_type=G type=HF num_elts=128 alias=<%0,0>\n" \
    "bfn.xCA (M1_NM, 32) OUT_UW(0,0)<1> 0x6400:uw OUT_UW(0,0)<1;1,0> 0xF:uw\n" \
    "bfn.xCA (M1_NM, 32) OUT_UW(1,0)<1> 0x6400:uw OUT_UW(1,0)<1;1,0> 0xF:uw\n" \
    "bfn.xCA (M1_NM, 32) OUT_UW(2,0)<1> 0x6400:uw OUT_UW(2,0)<1;1,0> 0xF:uw\n" \
    "bfn.xCA (M1_NM, 32) OUT_UW(3,0)<1> 0x6400:uw OUT_UW(3,0)<1;1,0> 0xF:uw\n" \
    "add (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0xE400:hf\n" \
    "add (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0xE400:hf\n" \
    "add (M1_NM, 32) OUT_HF(2,0)<1> OUT_HF(2,0)<1;1,0> 0xE400:hf\n" \
    "add (M1_NM, 32) OUT_HF(3,0)<1> OUT_HF(3,0)<1;1,0> 0xE400:hf\n"


template <>
struct Xe_Reorder<ReorderKind::UU, uint4_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 3 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;2,0>  SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_U4_HALF_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::UV, uint4_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 16) OUT_UW(0,0)<2> IN_UB(0,0)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(0,1)<2> IN_UB(0,8)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(1,0)<2> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(1,1)<2> IN_UB(0,24)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(2,0)<2> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(2,1)<2> IN_UB(0,40)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(3,0)<2> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(3,1)<2> IN_UB(0,56)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_U4_HALF_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, uint4_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 3 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,1)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,2)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,3)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_U4_HALF_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

// Common int4 -> half conversion sequence, after expanding nybbles to words.
#define CUTE_XE_REORDER_S4_HALF_SEQ \
    ".decl OUT_HF v_type=G type=HF num_elts=128 alias=<%0,0>\n" \
    "bfn.x6A (M1_NM, 32) OUT_UW(0,0)<1> 0x6408:uw OUT_UW(0,0)<1;1,0> 0xF:uw\n" \
    "bfn.x6A (M1_NM, 32) OUT_UW(1,0)<1> 0x6408:uw OUT_UW(1,0)<1;1,0> 0xF:uw\n" \
    "bfn.x6A (M1_NM, 32) OUT_UW(2,0)<1> 0x6408:uw OUT_UW(2,0)<1;1,0> 0xF:uw\n" \
    "bfn.x6A (M1_NM, 32) OUT_UW(3,0)<1> 0x6408:uw OUT_UW(3,0)<1;1,0> 0xF:uw\n" \
    "add (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0xE408:hf\n" \
    "add (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0xE408:hf\n" \
    "add (M1_NM, 32) OUT_HF(2,0)<1> OUT_HF(2,0)<1;1,0> 0xE408:hf\n" \
    "add (M1_NM, 32) OUT_HF(3,0)<1> OUT_HF(3,0)<1;1,0> 0xE408:hf\n"


template <>
struct Xe_Reorder<ReorderKind::UU, int4_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 3 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;2,0>  SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_S4_HALF_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::UV, int4_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 16) OUT_UW(0,0)<2> IN_UB(0,0)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(0,1)<2> IN_UB(0,8)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(1,0)<2> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(1,1)<2> IN_UB(0,24)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(2,0)<2> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(2,1)<2> IN_UB(0,40)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(3,0)<2> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(3,1)<2> IN_UB(0,56)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_S4_HALF_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, int4_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 3 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,1)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,2)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,3)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_S4_HALF_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

// Common uint4 -> bfloat16 conversion sequence, after expanding nybbles to words.
#define CUTE_XE_REORDER_U4_BF16_SEQ \
    ".decl OUT_BF v_type=G type=BF num_elts=128 alias=<%0,0>\n" \
    "bfn.xCA (M1_NM, 32) OUT_UW(0,0)<1> 0x4300:uw OUT_UW(0,0)<1;1,0> 0xF:uw\n" \
    "bfn.xCA (M1_NM, 32) OUT_UW(1,0)<1> 0x4300:uw OUT_UW(1,0)<1;1,0> 0xF:uw\n" \
    "bfn.xCA (M1_NM, 32) OUT_UW(2,0)<1> 0x4300:uw OUT_UW(2,0)<1;1,0> 0xF:uw\n" \
    "bfn.xCA (M1_NM, 32) OUT_UW(3,0)<1> 0x4300:uw OUT_UW(3,0)<1;1,0> 0xF:uw\n" \
    "add (M1_NM, 32) OUT_BF(0,0)<1> OUT_BF(0,0)<1;1,0> 0xC3000000:f\n" \
    "add (M1_NM, 32) OUT_BF(1,0)<1> OUT_BF(1,0)<1;1,0> 0xC3000000:f\n" \
    "add (M1_NM, 32) OUT_BF(2,0)<1> OUT_BF(2,0)<1;1,0> 0xC3000000:f\n" \
    "add (M1_NM, 32) OUT_BF(3,0)<1> OUT_BF(3,0)<1;1,0> 0xC3000000:f\n"


template <>
struct Xe_Reorder<ReorderKind::UU, uint4_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;2,0>  SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_U4_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::UV, uint4_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 5 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 16) OUT_UW(0,0)<2> IN_UB(0,0)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(0,1)<2> IN_UB(0,8)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(1,0)<2> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(1,1)<2> IN_UB(0,24)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(2,0)<2> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(2,1)<2> IN_UB(0,40)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(3,0)<2> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(3,1)<2> IN_UB(0,56)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_U4_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, uint4_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,1)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,2)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,3)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_U4_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

// Common int4 -> bfloat16 conversion sequence, after expanding nybbles to words.
#define CUTE_XE_REORDER_S4_BF16_SEQ \
    ".decl OUT_BF v_type=G type=BF num_elts=128 alias=<%0,0>\n" \
    "bfn.x6A (M1_NM, 32) OUT_UW(0,0)<1> 0x4308:uw OUT_UW(0,0)<1;1,0> 0xF:uw\n" \
    "bfn.x6A (M1_NM, 32) OUT_UW(1,0)<1> 0x4308:uw OUT_UW(1,0)<1;1,0> 0xF:uw\n" \
    "bfn.x6A (M1_NM, 32) OUT_UW(2,0)<1> 0x4308:uw OUT_UW(2,0)<1;1,0> 0xF:uw\n" \
    "bfn.x6A (M1_NM, 32) OUT_UW(3,0)<1> 0x4308:uw OUT_UW(3,0)<1;1,0> 0xF:uw\n" \
    "add (M1_NM, 32) OUT_BF(0,0)<1> OUT_BF(0,0)<1;1,0> 0xC3080000:f\n" \
    "add (M1_NM, 32) OUT_BF(1,0)<1> OUT_BF(1,0)<1;1,0> 0xC3080000:f\n" \
    "add (M1_NM, 32) OUT_BF(2,0)<1> OUT_BF(2,0)<1;1,0> 0xC3080000:f\n" \
    "add (M1_NM, 32) OUT_BF(3,0)<1> OUT_BF(3,0)<1;1,0> 0xC3080000:f\n"


template <>
struct Xe_Reorder<ReorderKind::UU, int4_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;2,0>  SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_S4_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::UV, int4_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 5 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 16) OUT_UW(0,0)<2> IN_UB(0,0)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(0,1)<2> IN_UB(0,8)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(1,0)<2> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(1,1)<2> IN_UB(0,24)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(2,0)<2> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(2,1)<2> IN_UB(0,40)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(3,0)<2> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 16) OUT_UW(3,1)<2> IN_UB(0,56)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_S4_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, int4_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x00040000;
    asm (     /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shr (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,1)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,2)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shr (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,3)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_S4_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

// Common e2m1 -> half conversion sequence, after moving nybbles to highest 4 bits of each word.
#define CUTE_XE_REORDER_E2M1_HALF_SEQ \
    ".decl OUT_W v_type=G type=W num_elts=128 alias=<%0,0>\n" \
    ".decl OUT_UD v_type=G type=UD num_elts=64 alias=<%0,0>\n" \
    ".decl OUT_HF v_type=G type=HF num_elts=128 alias=<%0,0>\n" \
    "asr (M1_NM, 32) OUT_W(0,0)<1> OUT_W(0,0)<1;1,0> 3:uw\n" \
    "asr (M1_NM, 32) OUT_W(1,0)<1> OUT_W(1,0)<1;1,0> 3:uw\n" \
    "asr (M1_NM, 32) OUT_W(2,0)<1> OUT_W(2,0)<1;1,0> 3:uw\n" \
    "asr (M1_NM, 32) OUT_W(3,0)<1> OUT_W(3,0)<1;1,0> 3:uw\n" \
    "and (M1_NM, 32) OUT_UD(0,0)<1> OUT_UD(0,0)<1;1,0> 0x8E008E00:ud\n" \
    "and (M1_NM, 32) OUT_UD(2,0)<1> OUT_UD(2,0)<1;1,0> 0x8E008E00:ud\n" \
    "mul (M1_NM, 32) OUT_HF(0,0)<1> OUT_HF(0,0)<1;1,0> 0x7400:hf\n" \
    "mul (M1_NM, 32) OUT_HF(1,0)<1> OUT_HF(1,0)<1;1,0> 0x7400:hf\n" \
    "mul (M1_NM, 32) OUT_HF(2,0)<1> OUT_HF(2,0)<1;1,0> 0x7400:hf\n" \
    "mul (M1_NM, 32) OUT_HF(3,0)<1> OUT_HF(3,0)<1;1,0> 0x7400:hf\n"

template <>
struct Xe_Reorder<ReorderKind::UU, float_e2m1_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x0008000C;
    asm (   /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;2,0>  SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_E2M1_HALF_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::UV, float_e2m1_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x0008000C;
    asm (     /* 5 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shl (M1_NM, 16) OUT_UW(0,0)<2> IN_UB(0,0)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(0,1)<2> IN_UB(0,8)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(1,0)<2> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(1,1)<2> IN_UB(0,24)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(2,0)<2> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(2,1)<2> IN_UB(0,40)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(3,0)<2> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(3,1)<2> IN_UB(0,56)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_E2M1_HALF_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, float_e2m1_t, half_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x0008000C;
    asm (   /* 4 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,1)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,2)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,3)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_E2M1_HALF_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

// Common e2m1 -> bfloat16 conversion sequence, after moving nybbles to highest 4 bits of each word.
#define CUTE_XE_REORDER_E2M1_BF16_SEQ \
    ".decl OUT_W v_type=G type=W num_elts=128 alias=<%0,0>\n" \
    ".decl OUT_UD v_type=G type=UD num_elts=64 alias=<%0,0>\n" \
    ".decl OUT_BF v_type=G type=BF num_elts=128 alias=<%0,0>\n" \
    "asr (M1_NM, 32) OUT_W(0,0)<1> OUT_W(0,0)<1;1,0> 6:uw\n" \
    "asr (M1_NM, 32) OUT_W(1,0)<1> OUT_W(1,0)<1;1,0> 6:uw\n" \
    "asr (M1_NM, 32) OUT_W(2,0)<1> OUT_W(2,0)<1;1,0> 6:uw\n" \
    "asr (M1_NM, 32) OUT_W(3,0)<1> OUT_W(3,0)<1;1,0> 6:uw\n" \
    "and (M1_NM, 32) OUT_UD(0,0)<1> OUT_UD(0,0)<1;1,0> 0x81C081C0:ud\n" \
    "and (M1_NM, 32) OUT_UD(2,0)<1> OUT_UD(2,0)<1;1,0> 0x81C081C0:ud\n" \
    "mul (M1_NM, 32) OUT_BF(0,0)<1> OUT_BF(0,0)<1;1,0> 0x7E800000:f\n" \
    "mul (M1_NM, 32) OUT_BF(1,0)<1> OUT_BF(1,0)<1;1,0> 0x7E800000:f\n" \
    "mul (M1_NM, 32) OUT_BF(2,0)<1> OUT_BF(2,0)<1;1,0> 0x7E800000:f\n" \
    "mul (M1_NM, 32) OUT_BF(3,0)<1> OUT_BF(3,0)<1;1,0> 0x7E800000:f\n"

template <>
struct Xe_Reorder<ReorderKind::UU, float_e2m1_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x0008000C;
    asm (   /* 5 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<1;2,0>  SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_E2M1_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::UV, float_e2m1_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x0008000C;
    asm (     /* 6 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shl (M1_NM, 16) OUT_UW(0,0)<2> IN_UB(0,0)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(0,1)<2> IN_UB(0,8)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(1,0)<2> IN_UB(0,16)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(1,1)<2> IN_UB(0,24)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(2,0)<2> IN_UB(0,32)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(2,1)<2> IN_UB(0,40)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(3,0)<2> IN_UB(0,48)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 16) OUT_UW(3,1)<2> IN_UB(0,56)<1;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_E2M1_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};

template <>
struct Xe_Reorder<ReorderKind::VV, float_e2m1_t, bfloat16_t>
{
  using SRegisters = intel::uchar4[1];
  using DRegisters = intel::ushort8[1];

  CUTE_HOST_DEVICE static void
  reorder(intel::uchar4 const& src0, intel::ushort8& dst0)
  {
#if defined(CUTE_ARCH_COPY_XE_ENABLED)
    const uint32_t shifts = 0x0008000C;
    asm (   /* 5 cycles/output register */
      "{\n"
      ".decl IN_UB v_type=G type=UB num_elts=64 alias=<%1,0>\n"
      ".decl OUT_UW v_type=G type=UW num_elts=128 alias=<%0,0>\n"
      ".decl SHIFTS v_type=G type=UW num_elts=2 alias=<%2,0>\n"
      "shl (M1_NM, 32) OUT_UW(0,0)<1> IN_UB(0,0)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(1,0)<1> IN_UB(0,1)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(2,0)<1> IN_UB(0,2)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      "shl (M1_NM, 32) OUT_UW(3,0)<1> IN_UB(0,3)<4;2,0> SHIFTS(0,0)<0;2,1>\n"
      CUTE_XE_REORDER_E2M1_BF16_SEQ
      "}\n"
      : "=rw"(dst0)
      : "rw"(src0), "rw.u"(shifts)
    );
#else
  CUTE_INVALID_CONTROL_PATH("Not Xe");
#endif
  }
};




} // end namespace cute
