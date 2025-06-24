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

template <typename EncodingType, typename TensorIn, typename TensorOut>
CUTLASS_DEVICE void
convert_FP8_to_FP16(TensorIn const &in,
                    TensorOut &out) {

  static_assert(cute::is_rmem<typename TensorIn::engine_type>::value,
                "Input tensor for A conversion must come from registers");
  static_assert(cute::is_rmem<typename TensorOut::engine_type>::value,
                "Output tensor for A conversion must come from registers");
  static_assert(cute::cosize_v<typename TensorIn::layout_type> == cute::cosize_v<typename TensorOut::layout_type>);
  static_assert(cute::size_v<typename TensorIn::layout_type> == cute::cosize_v<typename TensorIn::layout_type>);
  static_assert(cute::size_v<typename TensorOut::layout_type> == cute::cosize_v<typename TensorOut::layout_type>);

  using SrcType = typename TensorIn::value_type;
  using DstType = typename TensorOut::value_type;

  static_assert(std::is_same_v<SrcType, uint8_t>,
                "Expected fp8 input as uint8_t");
  static_assert(cute::is_any_of_v<EncodingType, cute::float_e5m2_t, cute::float_e4m3_t>,
                "Expected EncodingType to be float_e5m2_t or float_e4m3_t");

  constexpr int num_elements = decltype(size(in))::value;
  constexpr int fragment_size = std::is_same_v<EncodingType, cute::float_e5m2_t> ? 4 : 8;

  static_assert(num_elements % fragment_size == 0,
                "Currently, FP8 -> FP16 conversion is only supported when "
                "each work-item converts a multiple of fragment_size");

  auto in_frag = cute::recast<cutlass::Array<EncodingType, fragment_size>>(in);
  auto out_frag = cute::recast<cutlass::Array<DstType, fragment_size>>(out);

  CUTLASS_PRAGMA_UNROLL
  for (int i = 0; i < num_elements / fragment_size; ++i) {
    out_frag(i) = cutlass::NumericArrayConverter<DstType, EncodingType, fragment_size>{}(in_frag(i));
  }
}
