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

#include "cutlass/cutlass.h"
#include <cute/tensor.hpp>

namespace cutlass::fmha::collective {

using namespace cute;

struct VariableLength {
  int max_length;
  int* cumulative_length = nullptr;

  CUTE_HOST_DEVICE operator int() const {
    return max_length;
  }
};

template<class T> struct is_variable_length : std::false_type {};
template<> struct is_variable_length<VariableLength> : std::true_type {};
template<class T> constexpr bool is_variable_length_v = is_variable_length<T>::value;

template<class Shape, class Idx>
CUTE_HOST_DEVICE
constexpr auto
apply_variable_length(Shape const& shape, Idx const& idx) {
  return transform_leaf(shape, [&](auto const& s) {
    if constexpr (is_variable_length_v<remove_cvref_t<decltype(s)>>) {
      return s.cumulative_length[idx+1] - s.cumulative_length[idx];
    }
    else {
      return s;
    }
  });
}

template<class Shape, class Coord, class Idx>
CUTE_HOST_DEVICE
constexpr auto
apply_variable_length(Shape const& shape, Coord const& coord, Idx const& idx) {
  auto new_shape = apply_variable_length(shape, idx);
  auto new_coord = transform_leaf(shape, coord, [&](auto const& s, auto const& c) {
    if constexpr (is_variable_length_v<remove_cvref_t<decltype(s)>>) {
      return cute::make_tuple(c, s.cumulative_length[idx]);
    }
    else {
      return c;
    }
  });
  return cute::make_tuple(new_shape, new_coord);
}

}  // namespace cutlass::fmha::collective

namespace cute {

template<>
struct is_integral<cutlass::fmha::collective::VariableLength> : true_type {};

CUTE_HOST_DEVICE
void print(cutlass::fmha::collective::VariableLength a) {
  printf("Varlen<%d, %p>", a.max_length, a.cumulative_length);
}

}
