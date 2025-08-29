/***************************************************************************************************
* Copyright (c) 2025 ----
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

#include "cute/tensor.hpp"

//
// Common routines for SYCL CuTe examples.
//

// Variant of make_signed_t that works for both integer and floating point types.
template <typename T>
auto ensure_signed_helper_t() {
  if constexpr (cute::is_unsigned_v<T>)
    return cute::make_signed_t<T>{};
  else
    return T{};
}

template <typename T>
using ensure_signed_t = decltype(ensure_signed_helper_t<T>());

template <typename T>
T random_value()
{
  using Limits = cutlass::platform::numeric_limits<T>;

  static std::vector<T> saved;
  static constexpr size_t nsave = 65537;
  static size_t idx = 0;

  if (saved.empty()) {
    float range = Limits::is_integer ? 10.f : 1.f;
    float v_min = cute::max(-range, float(Limits::lowest()));
    float v_max = cute::min(+range, float(Limits::max()));

    saved.resize(nsave);
    for (auto &x: saved)
      x = T(v_min + (v_max - v_min) * (float(rand()) / float(RAND_MAX)));
  }

  auto v = saved[idx++];
  if (idx >= nsave) idx -= nsave;

  return v;
}

template <typename InTensor>
void
random_fill(InTensor &X)
{
  using T = typename InTensor::element_type;

  for (int i = 0; i < size(X); i++)
    X(i) = random_value<T>();
}

template <typename InTensor>
void
zero_fill(InTensor &X)
{
  using T = typename InTensor::element_type;

  for (int i = 0; i < size(X); i++)
    X(i) = T(0);
}

// Pack sub-byte types in a gmem tensor.
// On input, the backing array holds one sub-byte value per byte.
// On exit, the backing array contains packed values.
template <typename InTensor>
void
subbyte_pack(InTensor &X)
{
  using namespace cute;
  using T = typename InTensor::element_type;

  if constexpr (sizeof_bits_v<T> % 8 != 0) {
    static_assert(sizeof_bits_v<T> == 4, "Unsupported sub-byte data size");

    auto ptr = recast_ptr<uint8_t>(&*X.data());
    auto bytes = X.size();

    for (size_t i = 0; i < bytes/2; i++)
        ptr[i] = ptr[2*i] | (ptr[2*i + 1] << 4);
    if (bytes & 1)
        ptr[bytes >> 1] = ptr[bytes - 1];
  }
}

// Retrieve a user-friendly string representation of an element type.
template <typename T>
const char *type_str()
{
  using namespace cute;
  using T_ = remove_cvref_t<T>;
#define CASE(x, y) if (is_same_v<T_,x>) return #y;
#define ICASE(x) CASE(x, x)
  ICASE(double)
  ICASE(float)
  CASE(tfloat32_t, tf32)
  CASE(half_t, half)
  CASE(bfloat16_t, bf16)
  CASE(float_e5m2_t, e5m2)
  CASE(float_e4m3_t, e4m3)
  CASE(float_e2m1_t, e2m1)
  CASE(int32_t, int32)
  CASE(uint32_t, uint32)
  CASE(int8_t, int8)
  CASE(uint8_t, uint8)
  CASE(int4_t, int4)
  CASE(uint4_t, uint4)
#undef CASE
  return "<unknown type>";
}


template <typename T, char LayoutKind>
auto
make_shared_usm_tensor(sycl::queue &Q, int r, int c)
{
  using namespace cute;
  auto ptr = make_gmem_ptr(sycl::malloc_shared<T>(r*c, Q));
  auto shape = make_shape(r, c);
  if constexpr (LayoutKind == 'C')
    return make_tensor(ptr, make_layout(shape, make_stride(_1{}, r)));
  else
    return make_tensor(ptr, make_layout(shape, make_stride(c, _1{})));
}

template <typename InTensor>
void
free_usm_tensor(InTensor &X, sycl::queue &Q)
{
  // RAII? What's that?
  sycl::free(&*X.data(), Q);
}
