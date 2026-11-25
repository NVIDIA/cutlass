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
// Run from the repository root with a C++17 host compiler and CUDA headers:
// c++ -std=c++17 -Iinclude -I"$CUDA_HOME/include" -I"$CUDA_HOME/include/cccl" test/unit/cute/core/subbyte_reference_scenario.cpp -o /tmp/subbyte_reference
// /tmp/subbyte_reference
#include <cute/container/array_subbyte.hpp>
#include <cute/container/tuple.hpp>

#include <array>
#include <cstdint>
#include <cstring>
#include <iostream>
#include <type_traits>

namespace {

void put_bits(std::array<uint8_t, 32>& bytes, int element, int width, uint8_t code) {
  for (int bit = 0; bit < width; ++bit) {
    int position = element * width + bit;
    auto mask = uint8_t(1u << (position % 8));
    auto& byte = bytes[2 + position / 8];
    byte = uint8_t((byte & ~mask) | (((code >> bit) & 1u) ? mask : 0));
  }
}

template <class T>
T from_bits(uint8_t code) {
  T value;
  std::memcpy(&value, &code, sizeof(value));
  return value;
}

template <class T>
uint8_t to_bits(T value) {
  uint8_t code;
  std::memcpy(&code, &value, sizeof(value));
  return uint8_t(code & ((1u << cute::sizeof_bits_v<T>) - 1));
}

template <class T>
uint8_t read_by_value(cute::subbyte_reference<T> reference) {
  return to_bits(reference.get());
}

template <class T>
bool exercise(char const* name) {
  using Reference = cute::subbyte_reference<T>;
  using ConstReference = cute::subbyte_reference<T const>;
  if (sizeof(T) != 1 || !std::is_convertible_v<Reference, ConstReference> ||
      std::is_constructible_v<Reference, ConstReference const&>) {
    std::cerr << name << ": invalid const conversion contract\n";
    return false;
  }
  constexpr int width = cute::sizeof_bits_v<T>;
  constexpr auto mask = uint8_t((1u << width) - 1);
  for (int index = 0; index < 17; ++index) {
    std::array<uint8_t, 32> bytes;
    bytes.fill(0xa5);
    for (int i = 0; i < 17; ++i) put_bits(bytes, i, width, uint8_t(i) & mask);
    auto expected = bytes;
    cute::subbyte_iterator<T> pointer(bytes.data() + 2);
    auto original = pointer[index];
    auto copied = original;
    ConstReference readonly = original;
    auto readonly_copy = readonly;
    cute::tuple<Reference> saved(original);
    auto tuple_copy = cute::get<0>(saved);
    if (bytes != expected || read_by_value(copied) != (uint8_t(index) & mask) ||
        read_by_value(readonly_copy) != (uint8_t(index) & mask)) {
      std::cerr << name << ": construction or value passing changed element " << index << '\n';
      return false;
    }

    copied = from_bits<T>(mask);
    put_bits(expected, index, width, mask);
    if (bytes != expected || read_by_value(original) != mask ||
        read_by_value(readonly) != mask || read_by_value(tuple_copy) != mask) {
      std::cerr << name << ": copy lost reference identity at element " << index << '\n';
      return false;
    }

    int target_index = (index + 1) % 17;
    auto target = pointer[target_index];
    target = copied;
    put_bits(expected, target_index, width, mask);
    target = from_bits<T>(0);
    put_bits(expected, target_index, width, 0);
    if (bytes != expected || read_by_value(copied) != mask) {
      std::cerr << name << ": assignment rebound its destination at element " << index << '\n';
      return false;
    }
    target = readonly_copy;
    put_bits(expected, target_index, width, mask);
    if (bytes != expected) {
      std::cerr << name << ": const source assignment changed neighboring bits at element " << index << '\n';
      return false;
    }
  }
  std::cout << name << ": copied and converted 17 packed references\n";
  return true;
}

} // namespace

int main() {
  using Ref2 = cute::subbyte_reference<cutlass::uint2b_t>;
  using Ref4 = cute::subbyte_reference<cutlass::uint4b_t>;
  using ConstRef4 = cute::subbyte_reference<cutlass::uint4b_t const>;
  if (std::is_constructible_v<Ref4, Ref2 const&> ||
      std::is_constructible_v<ConstRef4, Ref2 const&>) {
    std::cerr << "shared byte storage must not permit an element type conversion\n";
    return 1;
  }
  bool ok = exercise<bool>("bool");
  ok &= exercise<cutlass::uint1b_t>("uint1b");
  ok &= exercise<cutlass::int2b_t>("int2b");
  ok &= exercise<cutlass::uint2b_t>("uint2b");
  ok &= exercise<cutlass::int4b_t>("int4b");
  ok &= exercise<cutlass::uint4b_t>("uint4b");
  ok &= exercise<cutlass::int6b_t>("int6b");
  ok &= exercise<cutlass::uint6b_t>("uint6b");
  ok &= exercise<cutlass::float_e2m1_t>("float_e2m1");
  ok &= exercise<cutlass::float_e2m3_t>("float_e2m3");
  ok &= exercise<cutlass::float_e3m2_t>("float_e3m2");
  ok &= exercise<cutlass::type_erased_dynamic_float4_t>("dynamic_float4");
  ok &= exercise<cutlass::type_erased_dynamic_float6_t>("dynamic_float6");
  ok &= exercise<uint8_t>("uint8");
  return ok ? 0 : 1;
}
