/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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

#include <sycl/sycl.hpp>                        // sycl::vec
#include "cute/numeric/int.hpp"                 // int_byte_t
#include "cute/numeric/numeric_types.hpp"       // bfloat16_t, half_t, etc.

namespace cute::intel
{

constexpr int sg_size = 16;
using _SGSize = Int<sg_size>;

#ifdef __SYCL_DEVICE_ONLY__
template <class T> struct vector_element_helper        { using type = T; };
template <> struct vector_element_helper<tfloat32_t>   { using type = uint32_t; };
template <> struct vector_element_helper<bfloat16_t>   { using type = uint16_t; };
template <> struct vector_element_helper<half_t>       { using type = uint16_t; };
template <> struct vector_element_helper<float_e5m2_t> { using type = uint8_t;  };
template <> struct vector_element_helper<float_e4m3_t> { using type = uint8_t;  };

template <class T, int N> using vector_t = typename vector_element_helper<T>::type __attribute__((ext_vector_type(N)));
#else
template <class T, int N> using vector_t = sycl::marray<T, N>;
#endif

template <typename T, int bits>
using storage_vector_t = vector_t<int_byte_t<bits_to_bytes(sizeof_bits_v<T>)>,
                                  bits / bytes_to_bits(bits_to_bytes(sizeof_bits_v<T>))>;

using uint = unsigned int;
using ushort = unsigned short;
using ulong = unsigned long;
using uchar = unsigned char;

using uchar2 = vector_t<uchar, 2>;
using uchar4 = vector_t<uchar, 4>;
using uchar8 = vector_t<uchar, 8>;
using uchar16 = vector_t<uchar, 16>;
using uchar32 = vector_t<uchar, 32>;
using uchar64 = vector_t<uchar, 64>;

using float2 = vector_t<float, 2>;
using float4 = vector_t<float, 4>;
using float8 = vector_t<float, 8>;

using half = _Float16;
using half2 = vector_t<_Float16, 2>;
using half4 = vector_t<_Float16, 4>;
using half8 = vector_t<_Float16, 8>;

using short2 = vector_t<short, 2>;
using short4 = vector_t<short, 4>;
using short8 = vector_t<short, 8>;

using int2 = vector_t<int, 2>;
using int4 = vector_t<int, 4>;
using int8 = vector_t<int, 8>;
using int16 = vector_t<int, 16>;

using uint2 = vector_t<uint, 2>;
using uint4 = vector_t<uint, 4>;
using uint8 = vector_t<uint, 8>;
using uint16 = vector_t<uint, 16>;
using uint32 = vector_t<uint, 32>;

using ushort2 = vector_t<ushort, 2>;
using ushort4 = vector_t<ushort, 4>;
using ushort8 = vector_t<ushort, 8>;
using ushort16 = vector_t<ushort, 16>;
using ushort32 = vector_t<ushort, 32>;
using ushort64 = vector_t<ushort, 64>;

using ulong2 = vector_t<ulong, 2>;
using ulong4 = vector_t<ulong, 4>;

using coord_t = vector_t<int, 2>;
} // namespace cute::intel
