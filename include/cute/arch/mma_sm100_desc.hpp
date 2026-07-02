/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
//

//

#pragma once

#if !defined(__CUDACC_RTC__)
#include <cinttypes>
#endif

#include <cute/arch/config.hpp>

#include <cute/arch/mma.hpp>

#include <cute/container/bit_field.hpp>
#include <cute/container/array.hpp> // cute::array

#include <cute/tensor_impl.hpp>     // Tensor, make_tensor, recast, Layout, logical_divide, etc.
#include <cute/swizzle.hpp>         // get_swizzle_t

////////////////////////////////////////////////////////////////////////////////////////////////////

namespace cute {

////////////////////////////////////////////////////////////////////////////////////////////////////
// UMMA Descriptor and utilities

// UMMA enums and utilities
namespace UMMA
{

enum class Major : uint8_t {
  K  = 0,
  MN = 1
};

enum class ScaleIn : uint8_t {
  One = 0,
  Neg = 1
};

enum class ScaleOut : uint8_t {
  Zero = 0,
  One  = 1
};

enum class Saturate : uint8_t {
  False = 0,
  True = 1
};

enum class LayoutType : uint8_t {
  SWIZZLE_NONE = 0,
  SWIZZLE_128B_BASE32B = 1,
  SWIZZLE_128B = 2,
  SWIZZLE_64B = 4,
  SWIZZLE_32B = 6
};

CUTE_HOST_DEVICE char const* to_string(LayoutType const& t) {
  switch (t) {
    case LayoutType::SWIZZLE_NONE:         return "SWIZZLE_NONE";
    case LayoutType::SWIZZLE_128B_BASE32B: return "SWIZZLE_128B_BASE32B";
    case LayoutType::SWIZZLE_128B:         return "SWIZZLE_128B";
    case LayoutType::SWIZZLE_64B:          return "SWIZZLE_64B";
    case LayoutType::SWIZZLE_32B:          return "SWIZZLE_32B";
  }
  return nullptr;
}

union SmemDescriptor
{
  uint64_t desc_ = 0;
  // Bitfield implementation avoids the need for shifts in assignment
  struct {
    // start_address, bit [0,14), 4LSB not included
    uint16_t start_address_ : 14, : 2;                     // 14 bits [0,14), 2 bits unused
    // leading dimension byte offset, bit [16,30), 4LSB not included
    uint16_t leading_byte_offset_ : 14, : 2;               // 14 bits [0,14), 2 bits unused
    // stride dimension byte offset, bit [32,46), 4LSB not included
    uint16_t stride_byte_offset_ : 14, version_ : 2;       // 14 bits [0,14), 2 bits [14,16)
    // base_offset, bit [49,52). leading_byte_offset_mode, bit [52,53).
    uint8_t : 1, base_offset_ : 3, lbo_mode_ : 1, : 3;     // 1 bit unused, 3 bits [1,4), 1 bit [4,5), 3 bits unused
    // layout type, bit [61,64), SWIZZLE_NONE matrix descriptor = 0, SWIZZLE_128B matrix descriptor = 2, SWIZZLE_64B descriptor = 4, SWIZZLE_32B descriptor = 6, SWIZZLE_128B_BASE32B = 1, N/A = 3, N/A = 5, N/A = 7
    uint8_t : 5, layout_type_ : 3;                         // 6 bits unused, 3 bits [5,8)
  };
  // Seperate the field, as we may only update one part of desc
  struct {
    uint32_t lo;
    uint32_t hi;
  };

  // Decay to a uint64_t
  CUTE_HOST_DEVICE constexpr
  operator uint64_t() const noexcept { return desc_; }
};

enum class F16F32Format : uint8_t {
  F16  = 0,
  BF16 = 1,
  TF32 = 2,
};

CUTE_HOST_DEVICE char const* to_string(F16F32Format const& t) {
  switch (t) {
    case F16F32Format::F16:  return "F16";
    case F16F32Format::BF16: return "BF16";
    case F16F32Format::TF32: return "TF32";
  }
  return nullptr;
}

template <class T>
CUTE_HOST_DEVICE constexpr F16F32Format to_F16F32Format() {
  if constexpr (is_same_v<T,     half_t>) { return F16F32Format::F16;  } else
  if constexpr (is_same_v<T, bfloat16_t>) { return F16F32Format::BF16; } else
  if constexpr (is_same_v<T, tfloat32_t>) { return F16F32Format::TF32; } else
  { static_assert(sizeof(T) == 0, "Unknown type for F16F32Format"); }
}

enum class S8Format : uint8_t {
  UINT8 = 0,
  INT8  = 1,
};

CUTE_HOST_DEVICE char const* to_string(S8Format const& t) {
  switch (t) {
    case S8Format::UINT8:   return "UINT8";
    case S8Format::INT8:    return "INT8";
  }
  return nullptr;
}

template <class T>
CUTE_HOST_DEVICE constexpr S8Format to_S8Format() {
  if constexpr (is_same_v<T, uint8_t>) { return S8Format::UINT8;  } else
  if constexpr (is_same_v<T,  int8_t>) { return S8Format::INT8;   } else
  { static_assert(sizeof(T) == 0, "Unknown type for S8Format"); }
}

enum class MXF8F6F4Format : uint8_t {
  E4M3 = 0,
  E5M2 = 1,
  E2M3 = 3,  
  E3M2 = 4,  
  E2M1 = 5,  
  INVALID = 7 // an invalid datatype for runtime proxy type
};

CUTE_HOST_DEVICE char const* to_string(MXF8F6F4Format const& t) {
  switch (t) {
    case MXF8F6F4Format::E4M3:   return "E4M3";
    case MXF8F6F4Format::E5M2:   return "E5M2";
    case MXF8F6F4Format::E2M3:   return "E2M3";  
    case MXF8F6F4Format::E3M2:   return "E3M2";  
    case MXF8F6F4Format::E2M1:   return "E2M1";  
    case MXF8F6F4Format::INVALID:   return "INVALID";
  }
  return nullptr;
}

template <class T>
CUTE_HOST_DEVICE constexpr MXF8F6F4Format to_MXF8F6F4Format() {
  if constexpr (is_same_v<T, float_e4m3_t>) { return MXF8F6F4Format::E4M3;  } else
  if constexpr (is_same_v<T, float_e5m2_t>) { return MXF8F6F4Format::E5M2;  } else
  if constexpr (is_same_v<T, detail::float_e2m3_unpacksmem_t>) { return MXF8F6F4Format::E2M3;  } else 
  if constexpr (is_same_v<T, detail::float_e3m2_unpacksmem_t>) { return MXF8F6F4Format::E3M2;  } else 
  if constexpr (is_same_v<T, detail::float_e2m1_unpacksmem_t>) { return MXF8F6F4Format::E2M1;  } else 
  { static_assert(sizeof(T) == 0, "Unknown type for MXF8F6F4Format"); }
}

enum class MXF4Format : uint8_t {
  E2M1 = 1,
};

CUTE_HOST_DEVICE char const* to_string(MXF4Format const& t) {
  switch (t) {
    case MXF4Format::E2M1:   return "E2M1";
  }
  return nullptr;
}

template <class T>
CUTE_HOST_DEVICE constexpr MXF4Format to_MXF4Format() {
  if constexpr (is_same_v<T, float_e2m1_t>) { return MXF4Format::E2M1;  } else
  { static_assert(sizeof(T) == 0, "Unknown type for MXF4Format"); }
}

enum class ScaleFormat : uint8_t {
  UE4M3 = 0, 
  UE8M0 = 1,
};

CUTE_HOST_DEVICE char const* to_string(ScaleFormat const& t) {
  switch (t) {
    case ScaleFormat::UE4M3:   return "UE4M3"; 
    case ScaleFormat::UE8M0:   return "UE8M0";
  }
  return nullptr;
}

template <class T>
CUTE_HOST_DEVICE constexpr ScaleFormat to_ScaleFormat() {
  if constexpr (is_same_v<T, float_ue4m3_t>) { return ScaleFormat::UE4M3;  } else
  if constexpr (is_same_v<T, float_ue8m0_t>) { return ScaleFormat::UE8M0;  } else
  { static_assert(sizeof(T) == 0, "Unknown type for ScaleFormat"); }
}

enum class CFormat : uint8_t {
  F16 = 0,
  F32 = 1,
  S32 = 2,
};

CUTE_HOST_DEVICE char const* to_string(CFormat const& t) {
  switch (t) {
    case CFormat::F16:  return "F16";
    case CFormat::F32:  return "F32";
    case CFormat::S32:  return "S32";
  }
  return nullptr;
}

enum class MaxShift : uint8_t {
  NoShift    = 0,
  MaxShift8  = 1,
  MaxShift16 = 2,
  MaxShift32 = 3
};

enum class BMatrixBufferId : uint8_t {
  Zero  = 0u,
  One   = 1u,
  Two   = 2u,
  Three = 3u
};

enum class BMatrixBufferReuse : uint8_t {
  None           = 0u,
  Keep           = 1u,
  Reuse          = 2u,
  ReuseAndKeep   = 3u
};

// using MaskAndShiftB = uint32_t[2];
union MaskAndShiftB
{
  uint32_t uri[2];

  struct {
    // Bitfield implementation avoids the need for shifts in assignment
    uint8_t  start_count_ [4];  // bit [ 0:32) : 8 bits each. Specifies the start count for mask generation.
    uint32_t first_span_  : 4,  // bit [32:36) : 1 bit each. 0 = start where B is used. 1 = start with where B is skipped(0 value is used).
                          : 3,  //
             nzm_         : 1,  // bit [39:40) : 0 = Enable the mask. 1 = Disable the mask.
             skip_span_   : 8,  // bit [40:48) : Count-1 (zero encoded in this field specifies use span of 1) of consecutive columns where 0 value is used.
             use_span_    : 8,  // bit [48:55) : Count-1 (zero encoded in this field specifies use span of 1) of consecutive columns where B matrix data is used.
             shift_       : 6,  // bit [56:62) : Shift value for B matrix data.
                          : 2;
  };
};

template <typename ShapeType, int FLT_S, int CTA_M, int CTA_N>
CUTE_HOST_DEVICE constexpr auto
make_column_zero_mask(ShapeType conv_q, int32_t cta_coord_q, int32_t num_pixels_skip_left) {

  static_assert(cute::is_same_v<ShapeType, cutlass::FastDivmod> || cute::is_integral<ShapeType>::value);

  cute::array<MaskAndShiftB, FLT_S> column_zero_masks{};

  static_assert(FLT_S == 3, "Filter size not supported.");
  constexpr int MAX_USE_SPAN_COUNT = 256;
  constexpr int MAX_SKIP_SPAN_COUNT = 256;

  // conv_q_int used for non-divmod case (add/minus/..) 
  // conv_q used for divmod case (div/mod/...)
  int32_t conv_q_int = int(conv_q);
  auto [_, cta_q] = divmod(cta_coord_q * CTA_N, conv_q);

  int step_q =   CTA_M == 128 ? CTA_N / 1
               : CTA_M == 64  ? CTA_N / 2
               : CTA_M == 32  ? CTA_N / 4
                              : 0;

  for (int mask_iter = 0; mask_iter < int(CTA_N / step_q); ++mask_iter) {

    for (int s_iter = 0; s_iter < FLT_S; s_iter += 1) {

      int32_t skip_span{0}, use_span{0}, nzm{1}, first_span{0}, start_count{0}, shift{0};

      shift = s_iter;

      // Examples for CZM setting
      // CASE0: (skip_span_ < 0)
      //        | padding  |<-          conv_q            ->|
      //        |skip_span_|<-     use_span    ->|skip_span_|
      //  -skip_span       0         ^cta_q              conv_q-1
      //        0                    ^index
      //
      // CASE1: (skip_span_ > 0)
      //        |<-          conv_q            ->|
      //        |skip_span_|<-     use_span    ->|skip_span_|
      //        0         ^cta_q              conv_q-1
      //        0         ^index
      //
      // line  0   an input vector from 0 to conv_q with the padding
      // line  1   shows the different spans we need to skip or load
      // lines 2-3 show the different coordinates of different boundaries.
      // CTQ_q is the coordinate of the present cta.

      int32_t skip_span_ = num_pixels_skip_left - shift;
      int32_t index{0};
      if (skip_span_ > 0) {
        auto [_, index_mod] = divmod(cta_q, conv_q);
        index = index_mod;
      } else if (skip_span_ < 0) {
        auto [_, index_mod] = divmod((cta_q - skip_span_), conv_q);
        index = index_mod;
      } else {
        nzm = 0;
      }
      skip_span = cute::max(cute::abs(skip_span_), 1);
      use_span = cute::min(conv_q_int - static_cast<int32_t>(skip_span), MAX_USE_SPAN_COUNT);
      if (use_span > 0) {
        first_span = index >= skip_span ? 0 : 1;
        if ((first_span == 0) && (index + CTA_N < conv_q_int + skip_span)) {
          nzm = 0;
        } else {
          start_count = first_span == 0 ? (use_span - (conv_q_int - index)) : index;
        }
      } else {
        skip_span = MAX_SKIP_SPAN_COUNT;
        use_span = 1;
        first_span = 1;
        start_count = 0;
      }

      column_zero_masks[s_iter].start_count_[mask_iter] = start_count;
      column_zero_masks[s_iter].first_span_             |= first_span << mask_iter;
      column_zero_masks[s_iter].nzm_                    |= nzm;
      column_zero_masks[s_iter].skip_span_              = skip_span - 1;
      column_zero_masks[s_iter].use_span_               = use_span - 1;
      column_zero_masks[s_iter].shift_                  = shift;

    }

    cta_q += step_q;
  }

  return column_zero_masks;
}

template <class T>
CUTE_HOST_DEVICE constexpr auto to_UMMAFormat() {
  if constexpr (is_same_v<T,       half_t>) { return F16F32Format::F16;   } else
  if constexpr (is_same_v<T,   bfloat16_t>) { return F16F32Format::BF16;  } else
  if constexpr (is_same_v<T,   tfloat32_t>) { return F16F32Format::TF32;  } else
  if constexpr (is_same_v<T,      uint8_t>) { return S8Format::UINT8; } else
  if constexpr (is_same_v<T,       int8_t>) { return S8Format::INT8;  } else
  if constexpr (is_same_v<T, type_erased_dynamic_float8_t>) {return MXF8F6F4Format::INVALID; } else
  
  if constexpr (is_same_v<T, type_erased_dynamic_float6_t>) {return MXF8F6F4Format::INVALID; } else
  if constexpr (is_same_v<T, type_erased_dynamic_float4_t>) {return MXF8F6F4Format::INVALID; } else
  if constexpr (is_same_v<T, detail::type_erased_dynamic_float4_unpacksmem_t>) {return MXF8F6F4Format::INVALID; } else
  
  if constexpr (is_same_v<T, float_e4m3_t>) { return MXF8F6F4Format::E4M3;  } else
  if constexpr (is_same_v<T, float_e5m2_t>) { return MXF8F6F4Format::E5M2;  } else
  if constexpr (is_same_v<T, detail::type_erased_dynamic_float6_unpacksmem_t>) {return MXF8F6F4Format::INVALID; } else
  if constexpr (is_same_v<T, detail::float_e2m3_unpacksmem_t>) { return MXF8F6F4Format::E2M3;  } else
  if constexpr (is_same_v<T, detail::float_e3m2_unpacksmem_t>) { return MXF8F6F4Format::E3M2;  } else
  if constexpr (is_same_v<T, float_e2m3_t>) { return MXF8F6F4Format::E2M3;  } else
  if constexpr (is_same_v<T, float_e3m2_t>) { return MXF8F6F4Format::E3M2;  } else
  if constexpr (is_same_v<T, detail::float_e2m1_unpacksmem_t>) { return MXF8F6F4Format::E2M1;  } else
  if constexpr (is_same_v<T, float_e2m1_t>) { return MXF4Format::E2M1;  } else
  { static_assert(sizeof(T) == 0, "Unknown type for UMMAFormat"); }
}

template <class T>
CUTE_HOST_DEVICE constexpr CFormat to_CFormat() {
  if constexpr (is_same_v<T,  half_t>) { return CFormat::F16; } else
  if constexpr (is_same_v<T,   float>) { return CFormat::F32; } else
  if constexpr (is_same_v<T, int32_t>) { return CFormat::S32; } else
  { static_assert(sizeof(T) == 0, "Unknown type for CFormat"); }
}

union InstrDescriptor
{
  uint32_t desc_;

  struct {
    // Bitfield implementation avoids the need for shifts in assignment
    uint16_t sparse_id2_    : 2,  // bit [ 0, 2) : Sparse meta data id2
             sparse_flag_   : 1,  // bit [ 2, 3) : 0 = dense. 1 = sparse. 1 value valid only for F32F16/S8/MXF8F6F4
             saturate_      : 1,  // bit [ 3, 4) : 0 = no saturate. 1 = saturate. 1 value valid only for S8
             c_format_      : 2,  // bit [ 4, 6) : 0 = F16. 1 = F32, 2 = S32
                            : 1,  //
             a_format_      : 3,  // bit [ 7,10) : MXF8F6F4Format:0 = E4M3, 1 = E5M2, 3 = E2M3, 4 = E3M2, 5 = E2M1. F32F16Format: 0 = F16, 1 = BF16, 2 = TF32. S8: 0 unsigned 8 bit, 1 signed 8 bit. Boolean MMA: 0 Boolean
             b_format_      : 3,  // bit [10,13) : MXF8F6F4Format:0 = E4M3, 1 = E5M2, 3 = E2M3, 4 = E3M2, 5 = E2M1. F32F16Format: 0 = F16, 1 = BF16, 2 = TF32. S8: 0 unsigned 8 bit, 1 signed 8 bit. Boolean MMA: 0 Boolean
             a_negate_      : 1,  // bit [13,14) : 0 = no negate. 1 = negate. 1 value valid only for F32F16Format and MXF8F6F4Format
             b_negate_      : 1,  // bit [14,15) : 0 = no negate. 1 = negate. 1 value valid only for F32F16Format and MXF8F6F4Format
             a_major_       : 1;  // bit [15,16) : 0 = K-major. 1 = MN-major. Major value of 1 is only valid for E4M3, E5M2, INT8 (signed and unsigned), F16, BF16 and TF32 source formats
    uint16_t b_major_       : 1,  // bit [16,17) : 0 = K-major. 1 = MN-major. Major value of 1 is only valid for E4M3, E5M2, INT8 (signed and unsigned), F16, BF16 and TF32 source formats
             n_dim_         : 6,  // bit [17,23) : 3 LSBs not included. Valid values range from 1 (N=8) to 32 (N=256).  All values are not valid for all instruction formats
                            : 1,  //
             m_dim_         : 5,  // bit [24,29) : 4 LSBs not included. Valid values are: 4 (M=64), 8 (M=128), 16 (M=256)
                            : 1,  //
             max_shift_     : 2;  // bit [30,32) : Maximum shift for WS instruction. Encoded as follows: 0 = no shift, 1 = maximum shift of 8, 2 = maximum shift of 16, 3 = maximum shift of 32.
  };

  // Decay to a uint32_t
  CUTE_HOST_DEVICE constexpr explicit
  operator uint32_t() const noexcept { return desc_; }
};

union InstrDescriptorBlockScaled
{
  uint32_t desc_;

  struct {
    // Bitfield implementation avoids the need for shifts in assignment
    uint16_t sparse_id2_    : 2,  // bit [ 0, 2) : Sparse meta data id2
             sparse_flag_   : 1,  // bit [ 2, 3) : 0 = dense. 1 = sparse. 1 value valid only for F32F16/S8/MXF8F6F4
                            : 1,  //
             b_sf_id_       : 2,  // bit [ 4, 6) : Matrix B Scale Factor ID
                            : 1,  //
             a_format_      : 3,  // bit [ 7, 10): MXF8F6F4Format:0 = E4M3, 1 = E5M2, 3 = E2M3, 4 = E3M2, 5 = E2M1. F32F16Format: 0 = F16, 1 = BF16, 2 = TF32. S8: 0 unsigned 8 bit, 1 signed 8 bit. BMMA: 0 Boolean
             b_format_      : 3,  // bit [10,13) : MXF8F6F4Format:0 = E4M3, 1 = E5M2, 3 = E2M3, 4 = E3M2, 5 = E2M1. F32F16Format: 0 = F16, 1 = BF16, 2 = TF32. S8: 0 unsigned 8 bit, 1 signed 8 bit. BMMA: 0 Boolean
             a_negate_      : 1,  // bit [13,14) : 0 = no negate. 1 = negate. 1 value valid only for F32F16Format and MXF8F6F4Format
             b_negate_      : 1,  // bit [14,15) : 0 = no negate. 1 = negate. 1 value valid only for F32F16Format and MXF8F6F4Format
             a_major_       : 1;  // bit [15,16) : 0 = K-major. 1 = MN-major. Major value of 1 is only valid for E4M3, E5M2, INT8 (signed and unsigned), F16, BF16 and TF32 source formats
    uint16_t b_major_       : 1,  // bit [16,17) : 0 = K-major. 1 = MN-major. Major value of 1 is only valid for E4M3, E5M2, INT8 (signed and unsigned), F16, BF16 and TF32 source formats
             n_dim_         : 6,  // bit [17,23) : 3 LSBs not included. Valid values range from 1 (N=8) to 32 (N=256).  All values are not valid for all instruction formats
             scale_format_  : 1,  // bit [23,24) : 0=E4M3, 1=E8M0
             m_dim_         : 5,  // bit [24,29) : 4 LSBs not included. Valid values are: 4 (M=64), 8 (M=128), 16 (M=256)
             a_sf_id_       : 2,  // bit [29,31) : Matrix A Scale Factor ID
             k_size_        : 1;  // bit [31,32) : MMA-K Dim. MXF8F6F4Format: 0=[dense: K32, sparse: K64]. S8Format: 0=[dense: K32, sparse: invalid]. MXF4Format: 0=[dense: K64, sparse: K128], 1=[dense: K96, sparse: invalid].
  };

  // Decay to a uint32_t
  CUTE_HOST_DEVICE constexpr
  operator uint32_t() const noexcept { return desc_; }
};

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg = UMMA::ScaleIn::One, UMMA::ScaleIn b_neg = UMMA::ScaleIn::One,
          UMMA::Saturate c_sat = UMMA::Saturate::False,
          bool is_sparse = false,
          UMMA::MaxShift max_shift = UMMA::MaxShift::NoShift>
CUTE_HOST_DEVICE constexpr
UMMA::InstrDescriptor
make_instr_desc()
{
  UMMA::InstrDescriptor desc_i = {};

  desc_i.a_format_ = uint8_t(UMMA::to_UMMAFormat<a_type>());
  desc_i.b_format_ = uint8_t(UMMA::to_UMMAFormat<b_type>());
  desc_i.c_format_ = uint8_t(UMMA::to_CFormat<c_type>());

  desc_i.m_dim_ = (M >> 4);
  desc_i.n_dim_ = (N >> 3);

  desc_i.a_major_ = uint8_t(a_major);
  desc_i.b_major_ = uint8_t(b_major);

  desc_i.a_negate_ = uint8_t(a_neg);
  desc_i.b_negate_ = uint8_t(b_neg);
  desc_i.saturate_ = uint8_t(c_sat);

  desc_i.sparse_flag_   = is_sparse;    // 1 = Sparse
  desc_i.sparse_id2_    = 0;

  desc_i.max_shift_ = uint8_t(max_shift);

  return desc_i;
}

template <class a_type, class b_type, class c_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg = UMMA::ScaleIn::One, UMMA::ScaleIn b_neg = UMMA::ScaleIn::One,
          UMMA::Saturate c_sat = UMMA::Saturate::False,
          bool is_sparse = false,
          UMMA::MaxShift max_shift = UMMA::MaxShift::NoShift>
CUTE_HOST_DEVICE
constexpr uint64_t
make_runtime_instr_desc(uint16_t sparse_id2 = 0u, uint32_t tmem_e = 0u) {
  UMMA::InstrDescriptor desc_i = UMMA::make_instr_desc<
      a_type, b_type, c_type, M, N, a_major, b_major, a_neg, b_neg, c_sat, is_sparse,
      max_shift>();

  if constexpr (is_sparse) {
    desc_i.sparse_id2_ = sparse_id2;
  }
  else {
    assert(sparse_id2 == 0u);
  }
  // In current compiler exposure, idescE is a uint64_t. It should contain:
  // -  Lower 32b URe: Specifies the tmem address that stores the sparse metadata.
  //                   Only needed for Sparse MMA instructions. Otherwise, ignored.
  // -  Upper 32b URh: Specifies the instruction descriptor.
  uint64_t idescE =  (static_cast<uint64_t>(static_cast<uint32_t>(desc_i)) << 32);

  return idescE;
}

template <bool is_sparse = false>
CUTE_HOST_DEVICE
constexpr uint64_t
make_runtime_instr_desc(UMMA::InstrDescriptor desc_i, uint16_t sparse_id2 = 0u, uint32_t tmem_e = 0u)
{
  if constexpr (is_sparse) {
    desc_i.sparse_id2_ = sparse_id2;
  }
  else {
    assert(sparse_id2 == 0u);
  }
  // In current compiler exposure, idescE is a uint64_t. It should contain:
  // -  Lower 32b URe: Specifies the tmem address that stores the sparse metadata.
  //                   Only needed for Sparse MMA instructions. Otherwise, ignored.
  // -  Upper 32b URh: Specifies the instruction descriptor.
  uint64_t idescE =  (static_cast<uint64_t>(static_cast<uint32_t>(desc_i)) << 32);

  return idescE;
}

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg = UMMA::ScaleIn::One, UMMA::ScaleIn b_neg = UMMA::ScaleIn::One,
          bool is_sparse = false
          >
CUTE_HOST_DEVICE constexpr
UMMA::InstrDescriptorBlockScaled
make_instr_desc_block_scaled()
{
  UMMA::InstrDescriptorBlockScaled desc_i = {};

  desc_i.a_format_ = uint8_t(UMMA::to_UMMAFormat<a_type>());
  desc_i.b_format_ = uint8_t(UMMA::to_UMMAFormat<b_type>());

  desc_i.scale_format_ = uint8_t(UMMA::to_ScaleFormat<sf_type>());
  desc_i.a_sf_id_ = 0;
  desc_i.b_sf_id_ = 0;

  desc_i.m_dim_ = (M >> 4);
  desc_i.n_dim_ = (N >> 3);

  desc_i.a_major_ = uint8_t(a_major);
  desc_i.b_major_ = uint8_t(b_major);

  desc_i.a_negate_ = uint8_t(a_neg);
  desc_i.b_negate_ = uint8_t(b_neg);
  desc_i.sparse_flag_   = is_sparse;    // 1 = Sparse
  desc_i.sparse_id2_    = 0;

  // Below would bring some warnings.
#if defined(__GNUC__)
#  pragma GCC diagnostic ignored "-Wconversion"
#endif
  return desc_i;
}

template <class a_type, class b_type, class c_type, class sf_type,
          int M, int N, UMMA::Major a_major, UMMA::Major b_major,
          UMMA::ScaleIn a_neg = UMMA::ScaleIn::One, UMMA::ScaleIn b_neg = UMMA::ScaleIn::One,
          bool is_sparse = false>
CUTE_HOST_DEVICE
constexpr uint64_t
make_runtime_instr_desc_block_scaled(uint32_t const tmem_sfa_addr, uint32_t const tmem_sfb_addr,
                                     uint16_t const sparse_id2 = 0u, uint32_t const tmem_e = 0u)
{
  UMMA::InstrDescriptorBlockScaled desc_i = UMMA::make_instr_desc_block_scaled<
      a_type, b_type, c_type, sf_type, M, N, 
      a_major, b_major, 
      a_neg, b_neg, 
      is_sparse>();

  // The first 2-bits of TMEM address includes byte address.
  desc_i.a_sf_id_ = (tmem_sfa_addr & 0xC0000000) >> 30;
  desc_i.b_sf_id_ = (tmem_sfb_addr & 0xC0000000) >> 30;

  if constexpr (is_sparse) {
    desc_i.sparse_id2_ = sparse_id2;
  }
  else {
    assert(sparse_id2 == 0u);
  }

  // In current compiler exposure, idescE is a uint64_t. It should contain:
  // -  Lower 32b URe: Specifies the tmem address that stores the sparse metadata.
  //                   Only needed for Sparse MMA instructions. Otherwise, ignored.
  // -  Upper 32b URh: Specifies the instruction descriptor.
  uint64_t idescE =  (static_cast<uint64_t>(static_cast<uint32_t>(desc_i)) << 32);

  return idescE;
}

template <bool is_sparse = false>
CUTE_HOST_DEVICE
constexpr uint64_t
make_runtime_instr_desc_block_scaled(UMMA::InstrDescriptorBlockScaled desc_i,
                                     uint32_t const tmem_sfa_addr, uint32_t const tmem_sfb_addr,
                                     uint16_t const sparse_id2 = 0u, uint32_t const tmem_e = 0u)
{
  // The first 2-bits of TMEM address includes byte address.
  desc_i.a_sf_id_ = (tmem_sfa_addr & 0xC0000000) >> 30;
  desc_i.b_sf_id_ = (tmem_sfb_addr & 0xC0000000) >> 30;

  if constexpr (is_sparse) {
    desc_i.sparse_id2_ = sparse_id2;
  }
  else {
    assert(sparse_id2 == 0u);
  }

  // In current compiler exposure, idescE is a uint64_t. It should contain:
  // -  Lower 32b URe: Specifies the tmem address that stores the sparse metadata.
  //                   Only needed for Sparse MMA instructions. Otherwise, ignored.
  // -  Upper 32b URh: Specifies the instruction descriptor.
  uint64_t idescE =  (static_cast<uint64_t>(static_cast<uint32_t>(desc_i)) << 32);

  return idescE;
}

///////////////////////////////////////////////////////////////////////////////
// Tensor (position-dependent swizzle) to LayoutType utility
///////////////////////////////////////////////////////////////////////////////

template <class Engine, class Shape, class Stride>
CUTE_HOST_DEVICE constexpr
LayoutType
layout_type(Tensor<Engine, Layout<Shape,Stride>> const&)
{
  static_assert(is_same<uint128_t, typename Engine::value_type>::value,
                "Expected uint128_t type in LayoutType conversion.");

  using Swizzle = get_swizzle_t<Engine>;
  constexpr int B = Swizzle::num_bits;
  constexpr int M = Swizzle::num_base;
  constexpr int S = Swizzle::num_shft;

  if constexpr (M == 4) {
    static_assert(S == 3, "Expected S = 3 when M == 4. Unsupported layout swizzle.");
    switch (B) {
      default: static_assert(0 <= B && B <= 3, "Expected B = 0,1,2, or 3 when M == 4. Unsupported layout swizzle.");
      case 0:  return LayoutType::SWIZZLE_NONE;
      case 1:  return LayoutType::SWIZZLE_32B;
      case 2:  return LayoutType::SWIZZLE_64B;
      case 3:  return LayoutType::SWIZZLE_128B;
    }
  } else
  if constexpr (M == 5) {
    static_assert(B == 2, "Expected B = 2 when M == 5. Unsupported layout swizzle.");
    static_assert(S == 2, "Expected S = 2 when M == 5. Unsupported layout swizzle.");
    return LayoutType::SWIZZLE_128B_BASE32B;
  } else {
    static_assert(M==5,   "Only 16B and 32B Atoms are supported for UMMA. Unsupported layout swizzle.");
    return LayoutType::SWIZZLE_NONE;  // ERROR
  }
}

///////////////////////////////////////////////////////////////////////////////
// Construction method for UMMA Descriptors
///////////////////////////////////////////////////////////////////////////////

/**
* ///////////////////////////////
* // make_umma_desc<Major::MN> //
* ///////////////////////////////
* Each UmmaDescriptor Major-MN describes a canonical layout of the form
*
* LayoutType::INTERLEAVE   : Swizzle<0,4,3> o smem_ptr o ((T,1,m),(8,k)):((1,T,SBO),(1T,LBO))
* LayoutType::B32          : Swizzle<1,4,3> o smem_ptr o ((T,2,m),(8,k)):((1,T,LBO),(2T,SBO))
* LayoutType::B64          : Swizzle<2,4,3> o smem_ptr o ((T,4,m),(8,k)):((1,T,LBO),(4T,SBO))
* LayoutType::B128         : Swizzle<3,4,3> o smem_ptr o ((T,8,m),(8,k)):((1,T,LBO),(8T,SBO))
* LayoutType::128B_BASE32B : Swizzle<2,5,2> o smem_ptr o ((T,8,m),(4,k)):((1,T,LBO),(?T,SBO))
*
* where
*   T  : sizeof(uint128_t) / sizeof(value_type)
*   m  : integer in [1,16] corresponding to UMMA shape
*   k  : integer in [1,32] corresponding to UMMA shape
*   SBO: stride byte offset
*   LBO: leading byte offset
*
* See UMMA::Layout_MN_XXX_Atom<value_type> for building canonical UmmaDescriptor Major-MN layouts.
* For example,
*   auto smem_layout = tile_to_shape(Layout_MN_SW128_Atom<value_type>{}, Shape<_128,_64>{});
* is guaranteed to be accepted by make_umma_desc<Major::MN> for appropriate value_type.
*
* //////////////////////////////
* // make_umma_desc<Major::K> //
* //////////////////////////////
* Each UmmaDescriptor Major-K describes a canonical layout of the form
*
* LayoutType::INTERLEAVE : Swizzle<0,4,3> o smem_ptr o ((8,m),(T,2)):((1T,SBO),(1,LBO))
* LayoutType::B32        : Swizzle<1,4,3> o smem_ptr o ((8,m),(T,2)):((2T,SBO),(1, T ))
* LayoutType::B64        : Swizzle<2,4,3> o smem_ptr o ((8,m),(T,2)):((4T,SBO),(1, T ))
* LayoutType::B128       : Swizzle<3,4,3> o smem_ptr o ((8,m),(T,2)):((8T,SBO),(1, T ))
*
* See UMMA::Layout_K_XXX_Atom<value_type> for building canonical UmmaDescriptor Major-K layouts.
* For example,
*   auto smem_layout = tile_to_shape(Layout_K_SW128_Atom<value_type>{}, Shape<_128,_64>{});
* is guaranteed to be accepted by make_umma_desc<Major::K> for appropriate value_type.
*/
template <UMMA::Major MajorMode, class TEngine, class TLayout>
CUTE_HOST_DEVICE constexpr
SmemDescriptor
make_umma_desc(Tensor<TEngine,TLayout> const& tensor)
{
  static_assert(is_smem<TEngine>::value, "UMMA Descriptors can only be constructed on smem.");
  static_assert(TLayout::rank == 2, "UMMA Descriptors can only be constructed on rank-2 tensors.");

  Tensor u128_tensor = recast<uint128_t const>(tensor);

  // Result
  SmemDescriptor desc;
  desc.version_ = 1;     // Set the version for blackwell
  desc.lbo_mode_ = 0; // set to legacy mode by default

  // Layout type
  constexpr UMMA::LayoutType LAYOUT_TYPE = UMMA::layout_type(u128_tensor);
  desc.layout_type_ = uint8_t(LAYOUT_TYPE);

  // Start address (4LSB not included)
  uint32_t start_address = cast_smem_ptr_to_uint(raw_pointer_cast(u128_tensor.data()));
  desc.start_address_ = static_cast<uint16_t>(start_address >> 4);

  constexpr uint8_t base_offset = 0;
  desc.base_offset_ = base_offset;

  // LayoutType meta
  constexpr int SwizzleAtomMNSize = LAYOUT_TYPE == UMMA::LayoutType::SWIZZLE_NONE         ? 1 :
                                    LAYOUT_TYPE == UMMA::LayoutType::SWIZZLE_32B          ? 2 :
                                    LAYOUT_TYPE == UMMA::LayoutType::SWIZZLE_64B          ? 4 :
                                    LAYOUT_TYPE == UMMA::LayoutType::SWIZZLE_128B         ? 8 :
                                    LAYOUT_TYPE == UMMA::LayoutType::SWIZZLE_128B_BASE32B ? 8 : -1;

  if constexpr (MajorMode == UMMA::Major::MN)
  {
    /* In units of uint128_t, each UmmaDescriptor Major-MN describes a canonical layout of the form
     *
     * LayoutType::INTERLEAVE         : Swizzle<0,4,3> o smem_ptr o ((1,n),(8,k)):((X,SBO),(1,LBO))
     * LayoutType::B32                : Swizzle<1,4,3> o smem_ptr o ((2,n),(8,k)):((1,LBO),(2,SBO))
     * LayoutType::B64                : Swizzle<2,4,3> o smem_ptr o ((4,n),(8,k)):((1,LBO),(4,SBO))
     * LayoutType::B128               : Swizzle<3,4,3> o smem_ptr o ((8,n),(8,k)):((1,LBO),(8,SBO))
     * LayoutType::B128_BASE32B       : Swizzle<2,5,2> o smem_ptr o ((8,n),(4,k)):((1,LBO),(4,SBO))
     */

    constexpr int SwizzleAtomKSize = LAYOUT_TYPE == UMMA::LayoutType::SWIZZLE_128B_BASE32B ? 4 : 8;

    // Construct the canonical UMMA T Layout with shape ((SwizzleAtomMNSize,n),(SwizzleAtomKSize,2))
    Layout canonical_layout = logical_divide(layout(u128_tensor), Tile<Layout<Int<SwizzleAtomMNSize>>,Layout<Int<SwizzleAtomKSize>>>{});

    // Check profile of canonical
    CUTE_STATIC_ASSERT_V(congruent(canonical_layout, Shape<Shape<_1,_1>,Shape<_1,_1>>{}), "Not a canonical UMMA_MN Layout: Expected profile failure.");
    // Check canonical mode strides
    constexpr uint32_t stride_00 = stride<0,0>(canonical_layout);
    constexpr uint32_t expected_stride_00 = LAYOUT_TYPE == UMMA::LayoutType::SWIZZLE_NONE ? stride<0,0>(canonical_layout) : 1;
    static_assert(stride_00 == expected_stride_00, "Not a canonical UMMA_MN Layout: Expected stride failure.");
    constexpr uint32_t stride_10 = stride<1,0>(canonical_layout);
    constexpr uint32_t expected_stride_10 = SwizzleAtomMNSize;
    static_assert(stride_10 == expected_stride_10, "Not a canonical UMMA_MN Layout: Expected stride failure.");

    // stride dimension byte offset and leading dimension byte offset (4LSB not included == uint128_t units)
    constexpr uint32_t stride_01 = stride<0,1>(canonical_layout);
    constexpr uint32_t stride_11 = stride<1,1>(canonical_layout);

    desc.stride_byte_offset_  = (LAYOUT_TYPE == UMMA::LayoutType::SWIZZLE_NONE) ? stride_01 : stride_11;
    desc.leading_byte_offset_ = (LAYOUT_TYPE == UMMA::LayoutType::SWIZZLE_NONE) ? stride_11 : stride_01;
  } else
  if constexpr (MajorMode == UMMA::Major::K)
  {
    /* In units of uint128_t, each UmmaDescriptor Major-K describes a canonical layout of the form
     *
     * LayoutType::INTERLEAVE    : Swizzle<0,4,3> o smem_ptr o ((8,n),2):((1,SBO),LBO)
     * LayoutType::B32           : Swizzle<1,4,3> o smem_ptr o ((8,n),2):((2,SBO),1)
     * LayoutType::B64           : Swizzle<2,4,3> o smem_ptr o ((8,n),2):((4,SBO),1)
     * LayoutType::B128          : Swizzle<3,4,3> o smem_ptr o ((8,n),2):((8,SBO),1)
     * LayoutType::B128_BASE32B  : Not applicable for Major-K
     */

    static_assert(LAYOUT_TYPE != UMMA::LayoutType::SWIZZLE_128B_BASE32B, "SWIZZLE_128B_BASE32B is invalid for Major-K");
    CUTE_STATIC_ASSERT_V(size<0>(u128_tensor) % Int<8>{} == Int<0>{},          // N|M size
                         "Not a canonical UMMA_K Layout: Expected MN-size multiple of 8.");

    // Construct the canonical UMMA N Layout with shape ((8,n),(2,1))
    Layout canonical_layout = logical_divide(layout(u128_tensor), Tile<Layout<_8,_1>,Layout<_2,_1>>{});

    // Check profile of canonical
    CUTE_STATIC_ASSERT_V(congruent(canonical_layout, Shape<Shape<_1,_1>,Shape<_1,_1>>{}), "Not a canonical UMMA_K Layout: Expected profile failure.");
    // Check canonical mode strides
    constexpr uint32_t stride_00 = stride<0,0>(canonical_layout);
    constexpr uint32_t expected_stride_00 = SwizzleAtomMNSize;
    static_assert(stride_00 == expected_stride_00, "Not a canonical UMMA_K Layout: Expected stride failure.");
    constexpr uint32_t stride_10 = stride<1,0>(canonical_layout);
    constexpr uint32_t expected_stride_10 = (LAYOUT_TYPE == UMMA::LayoutType::SWIZZLE_NONE) ? stride<1,0>(canonical_layout) : 1;
    static_assert(stride_10 == expected_stride_10, "Not a canonical UMMA_K Layout: Expected stride failure.");

    // stride dimension byte offset and leading dimension byte offset (4LSB not included == uint128_t units)
    constexpr uint32_t stride_01 = stride<0,1>(canonical_layout);

    desc.stride_byte_offset_  = stride_01;
    desc.leading_byte_offset_ = stride_10;
  } else {
    static_assert(MajorMode != UMMA::Major::MN && MajorMode != UMMA::Major::K, "Unrecognized MajorMode!");
  }
  return desc;
}

///////////////////////////////////////////////////////////////////////////////
// Higher level UMMA Descriptor utilities
///////////////////////////////////////////////////////////////////////////////

struct DescriptorIterator
{
  using reference    = SmemDescriptor;
  using element_type = SmemDescriptor;
  using value_type   = SmemDescriptor;

  SmemDescriptor desc_;

  // Dereference returns the UmmaDescriptor
  CUTE_HOST_DEVICE constexpr
  reference operator*() const { return desc_; }

  // Advance and return a new UmmaDescriptor
  template <class Index>
  CUTE_HOST_DEVICE constexpr
  reference operator[](Index const& i) const { return *(*this + i); }

  // Return an advanced iterator
  template <class Index>
  CUTE_HOST_DEVICE constexpr
  DescriptorIterator operator+(Index const& offset) const
  {
#if (__CUDACC_VER_MAJOR__ > 13) || ((__CUDACC_VER_MAJOR__ == 13) && (__CUDACC_VER_MINOR__ > 3))
    return { desc_ + uint64_t(offset) };
#else
    // Use 32-bit calculation rather than 64-bit calculation as we only update part of desc.
    SmemDescriptor ret;
    ret.lo = desc_.lo + uint32_t(offset);
    ret.hi = desc_.hi;
    return { ret };
#endif
  }
};

template <class T>
CUTE_HOST_DEVICE constexpr
SmemDescriptor
raw_pointer_cast(DescriptorIterator const& ptr) {
  return ptr.desc_;
}

CUTE_HOST_DEVICE void
print(DescriptorIterator const&) {
  printf("UMMA::DescriptorIterator");
}

// Flag for smem descriptor allocation/creation
template <UMMA::Major>
struct smem_desc : DescriptorIterator {};

template <UMMA::Major>
struct sparse_smem_desc : DescriptorIterator {};

} // end namespace UMMA

// Customization point for creating a UMMA::smem_desc Tensor
template <UMMA::Major MajorMode>
struct MakeTensor<UMMA::smem_desc<MajorMode>>
{
  template <class TEngine, class TLayout>
  CUTE_HOST_DEVICE constexpr auto
  operator()(Tensor<TEngine,TLayout> const& smem_tensor)
  {
    static_assert(is_smem<TEngine>::value, "Expected SMEM Tensor to construct a UMMA Desc Tensor");
    return make_tensor(UMMA::DescriptorIterator{UMMA::make_umma_desc<MajorMode>(tensor<0>(smem_tensor))},
                       replace<0>(recast<uint128_t const>(smem_tensor).layout(), Layout<_1,_0>{}));
  }
};

// Customization point for creating a UMMA::sparse_smem_desc Tensor
template <UMMA::Major MajorMode>
struct MakeTensor<UMMA::sparse_smem_desc<MajorMode>>
{
  // Note that this is the exact same as UMMA::smem_desc above.
  // Only the interface validates that we are passed a sparse_ptr, which is recast away to construct
  //   the smem desc tensor
  template <class TEngine, class TLayout>
  CUTE_HOST_DEVICE constexpr auto
  operator()(Tensor<TEngine,TLayout> const& smem_tensor)
  {
    static_assert(is_smem<TEngine>::value, "Expected SMEM Tensor to construct a UMMA Desc Tensor");
    static_assert(is_sparse<typename TEngine::value_type>::value, "Expected sparse value_type.");
    static_assert(is_sparse_ptr<TEngine>::value, "Expected sparse iter.");
    return make_tensor(UMMA::DescriptorIterator{UMMA::make_umma_desc<MajorMode>(tensor<0>(smem_tensor))},
                       replace<0>(recast<uint128_t const>(smem_tensor).layout(), Layout<_1,_0>{}));
  }
};

} // namespace cute
