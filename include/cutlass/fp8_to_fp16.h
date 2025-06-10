/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
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

#include <cute/layout.hpp>
#include <cute/numeric/numeric_types.hpp>
#include <cute/pointer.hpp>
#include <cute/tensor_impl.hpp>
#include <cute/underscore.hpp>
#include <cute/util/sycl_vec.hpp>
#include <cutlass/detail/helper_macros.hpp>
#include <cutlass/half.h>

using uchar8 = cute::intel::uchar8;
using ushort8 = cute::intel::ushort8;

static inline ushort8 convert_ushort8(uchar8 x) {
  ushort8 result;
  CUTLASS_PRAGMA_UNROLL
  for (int i = 0; i < 8; ++i) {
    result[i] = static_cast<uint16_t>(x[i]);
  }
  return result;
}

static inline ushort8 E4M3_to_FP16_chunk8(uchar8 xin) {
  uchar8 xa = xin & 0x7F;
  uchar8 sgn_x = xin ^ xa;

  uchar8 zero_mask;
  CUTLASS_PRAGMA_UNROLL
  for (int i = 0; i < 8; ++i) {
    zero_mask[i] = (xa[i] == 0) ? 1 : 0;
  }
  uchar8 nan_mask = (0x7E - xa) & 0x80;
  uchar8 den_mask = ((xa - 8) >> 7) & 0x01;

  xa += (nan_mask >> 1);
  xa |= (den_mask & 8);
  den_mask &= 0x48;
  xa += 0x40 & ~(zero_mask * 0x40);

  ushort8 x16 = convert_ushort8(xa) << 7;
  ushort8 den_corr = convert_ushort8(den_mask & ~zero_mask) << 7;

  ushort8 result = x16 - den_corr;
  result &= ~(convert_ushort8(zero_mask) << 7);

  ushort8 sign_ext = convert_ushort8(sgn_x) << 8;
  result ^= sign_ext;

  return result;
}

template <int N>
static inline void E5M2_to_FP16(cutlass::Array<uint32_t, N / 4> const &xin,
                                cutlass::Array<uint32_t, N / 2> &xout) {
// Since 32-bit registers & int32 ALUs are used, convert 4 FP8 elements
// in one iteration.
  CUTLASS_PRAGMA_UNROLL
  for (int i = 0, j = 0; i < N / 2; i += 2, j += 1) {
    // 3 shifts, 4 "and" & 2 "or" instructions for each set of 4 FP8 elements.
    uint32_t tmp0 = xin[j];
    uint32_t first = (tmp0 & 0x000000FF) << 8;
    uint32_t second = (tmp0 & 0x0000FF00) << 16;
    uint32_t third = (tmp0 & 0x00FF0000) >> 8;
    uint32_t fourth = (tmp0 & 0xFF000000);
    xout[i] = first | second;
    xout[i + 1] = third | fourth;
  }
}

template <typename ElementA, class EngineIn, class EngineOut, class LayoutIn,
          class LayoutOut, class... Ts>
CUTLASS_DEVICE void
convert_FP8_to_FP16(cute::Tensor<EngineIn, LayoutIn> const &in,
                    cute::Tensor<EngineOut, LayoutOut> &out) {

  static_assert(cute::is_rmem<EngineIn>::value,
                "Input tensor for A conversion must come from registers");
  static_assert(cute::is_rmem<EngineOut>::value,
                "Output tensor for A conversion must come from registers");
  static_assert(cute::cosize_v<LayoutIn> == cute::cosize_v<LayoutOut>);
  static_assert(cute::size_v<LayoutIn> == cute::cosize_v<LayoutIn>);
  static_assert(cute::size_v<LayoutOut> == cute::cosize_v<LayoutOut>);

  using SrcType = typename EngineIn::value_type;
  using DstType = typename EngineOut::value_type;

  static_assert(std::is_same_v<SrcType, uint8_t>,
                "Expected fp8 (E4M3) input as uint8_t");
  static_assert(std::is_same_v<DstType, cute::half_t>,
                "Expected fp16 output as half_t");

  SrcType const *pSrc = reinterpret_cast<SrcType const *>(in.data());
  DstType *pDst = reinterpret_cast<DstType *>(out.data());

  constexpr int num_elements = decltype(size(in))::value;

  // TODO(Codeplay): Move conversion to NumericArrayConverter
  if constexpr (std::is_same_v<ElementA, cute::float_e5m2_t>) {
    static_assert(num_elements % 4 == 0,
                  "Currently, E5M2 -> FP16 conversion is only supported when "
                  "each work-item converts a multiple of 4 elements");
    using SrcArray = cutlass::Array<uint32_t, num_elements / 4>;
    using DstArray = cutlass::Array<uint32_t, num_elements / 2>;
    SrcArray const *pSrcArr = reinterpret_cast<SrcArray const *>(pSrc);
    DstArray *pDstArr = reinterpret_cast<DstArray *>(pDst);
    // convert 4 FP8 elements at a time
    E5M2_to_FP16<num_elements>(*pSrcArr, *pDstArr);
  } else {
    // E4M3 -> FP16 conversion
    constexpr int chunk_size = 8;
    constexpr int iters = num_elements / chunk_size;
    static_assert(num_elements % chunk_size == 0,
                  "Currently, E4M3 -> FP16 conversion is only supported when "
                  "each work-item converts a multiple of 8 elements");
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < iters; ++i) {
      cute::intel::uchar8 src_vec;
      CUTLASS_PRAGMA_UNROLL
      for (int j = 0; j < chunk_size; ++j) {
        src_vec[j] = pSrc[i * chunk_size + j];
      }
      cute::intel::ushort8 dst_vec;
      dst_vec = E4M3_to_FP16_chunk8(src_vec);
      CUTLASS_PRAGMA_UNROLL
      for (int j = 0; j < chunk_size; ++j) {
        reinterpret_cast<uint16_t *>(pDst)[i * chunk_size + j] = dst_vec[j];
      }
    }
  }
}
