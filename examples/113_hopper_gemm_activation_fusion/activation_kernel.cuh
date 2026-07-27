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

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/array.h"
#include "cutlass/numeric_conversion.h"

template <class T, class U>
CUTLASS_DEVICE
constexpr static U
array_convert(T const& input)
{
  using SrcType = typename T::Element;
  using DstType = typename U::Element;
  static_assert(T::kElements == U::kElements);
  using Converter = cutlass::NumericArrayConverter<DstType, SrcType, T::kElements>;
  return Converter{}(input);
}

template <class T>
CUTLASS_DEVICE
int64_t
lower_bound(T const* values, size_t const size, T const target) {
  T const* low = values;
  T const* high = values + size;
  while (low < high) {
      T const* mid = low + (high - low) / 2;
      if (*mid < target) {
        low = mid + 1;
      }
      else {
        high = mid;
      }
  }
  return static_cast<int64_t>(low - values);
}

template <class T>
CUTLASS_DEVICE
T
load_vec(T const& src) {
  constexpr int B = cute::min(128, cute::sizeof_bits_v<T>);
  constexpr int N = cute::sizeof_bits_v<T> / B;
  using V = cute::uint_bit_t<B>;
  V v[N];
  V const* vptr = reinterpret_cast<V const*>(&src);

  CUTLASS_PRAGMA_UNROLL
  for (int i = 0; i < N; ++i) {
    v[i] = vptr[i];
  }
  return *reinterpret_cast<T*>(&v);
}

template <class T>
CUTLASS_DEVICE
void
store_vec(T& dst, T const& src) {
  constexpr int B = cute::min(128, cute::sizeof_bits_v<T>);
  constexpr int N = cute::sizeof_bits_v<T> / B;
  using V = cute::uint_bit_t<B>;
  V v[N];
  V* vptr = reinterpret_cast<V*>(&dst);

  *reinterpret_cast<T*>(&v) = src;
  CUTLASS_PRAGMA_UNROLL
  for (int i = 0; i < N; ++i) {
    vptr[i] = v[i];
  }
}

template <
  int NumThreads,
  template <class> class ActFn,
  class ElementOutput,
  class ElementInput,
  class ElementBias,
  class ElementCompute
>
CUTLASS_GLOBAL
void
activation_kernel(
    ElementOutput* output,
    ElementInput const* input,
    ElementCompute const* scale_ptr,
    ElementBias const* bias_ptr,
    bool bias_is_broadcast,
    int64_t const* group_col_offset,
    int num_groups,
    int64_t stride,
    bool gated)
{
  int64_t const tid = threadIdx.x;
  int64_t const col = blockIdx.x;
  if (col >= group_col_offset[num_groups])
  {
    return;
  }

  size_t gated_size_mul = gated ? 2 : 1;
  size_t gated_off = gated ? stride : 0;


  input  = input  + col * stride * gated_size_mul;
  output = output + col * stride;

  float const quant_scale = scale_ptr ? *scale_ptr : 1.f;

  if (bias_ptr) {
    int64_t group = 0;
    if (bias_is_broadcast) {
      group = lower_bound(group_col_offset, num_groups, (int64_t) col + 1) - 1;
    }
    size_t bias_offset = (bias_is_broadcast ? group : col) * stride * gated_size_mul;
    bias_ptr = bias_ptr + bias_offset;
  }

  // Vectorize all loads up to 128 bits
  constexpr int64_t VecSize = 128 / cute::max(cutlass::sizeof_bits_v<ElementBias>, 
                                    cute::max(cutlass::sizeof_bits_v<ElementOutput>,
                                              cutlass::sizeof_bits_v<ElementInput>));

  using BiasElem    = cutlass::Array<ElementBias,    VecSize>;
  using InputElem   = cutlass::Array<ElementInput,   VecSize>;
  using OutputElem  = cutlass::Array<ElementOutput,  VecSize>;
  using ComputeElem = cutlass::Array<ElementCompute, VecSize>;

  auto input_vec    = reinterpret_cast<InputElem const*>(input);
  auto output_vec   = reinterpret_cast<OutputElem*>(output);
  auto bias_ptr_vec = reinterpret_cast<BiasElem const*>(bias_ptr);
  
  int64_t const num_elems_in_col = stride / VecSize;
  int64_t const gated_off_vec = gated_off / VecSize;

  ActFn<ComputeElem> fn{};
  for (int64_t elem_index = tid; elem_index < num_elems_in_col; elem_index += NumThreads)
  {
    auto fc1_value = array_convert<InputElem, ComputeElem>(load_vec(input_vec[elem_index + gated_off_vec]));
    if (bias_ptr_vec)
    {
      fc1_value = fc1_value + array_convert<BiasElem, ComputeElem>(load_vec(bias_ptr_vec[elem_index + gated_off_vec]));
    }
    auto gate_act = fn(fc1_value);

    if (gated)
    {
      auto gate_mul = array_convert<InputElem, ComputeElem>(load_vec(input_vec[elem_index]));
      if (bias_ptr_vec)
      {
        gate_mul = gate_mul + array_convert<BiasElem, ComputeElem>(load_vec(bias_ptr_vec[elem_index]));
      }
      gate_act = gate_act * gate_mul;
    }

    store_vec(output_vec[elem_index], array_convert<ComputeElem, OutputElem>(gate_act * quant_scale));
  }
}

template <
  template <class> class ActFn,
  class ElementOutput,
  class ElementInput,
  class ElementBias,
  class ElementCompute
>
void do_activation(
    ElementOutput* output,
    ElementInput const* input,
    ElementCompute const* scale,
    ElementBias const* bias,
    bool bias_is_broadcast,
    int64_t const* group_col_offset,
    int num_groups,
    int64_t stride,
    int64_t num_tokens,
    bool gated)
{
  int const blocks = num_tokens;
  int constexpr threads = 256;
  activation_kernel<threads, ActFn><<<blocks, threads>>>(
    output,
    input,
    scale,
    bias,
    bias_is_broadcast,
    group_col_offset,
    num_groups,
    stride,
    gated);
}
