/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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

// fwd declare OCL function and OCL types
#include <sycl.hpp> //for sycl::vec

namespace cute
{
namespace intel
{
#ifdef __SYCL_DEVICE_ONLY__
template <class T, int N> using vector_t = typename sycl::vec<T, N>::vector_t;
#else
template <class T, int N> using vector_t = sycl::vec<T, N>;
#endif

using float8 = vector_t<float, 8>;
using short8 = vector_t<short, 8>;
using int8 = vector_t<int, 8>;
using int16 = vector_t<int, 16>;
using uint8 = vector_t<uint, 8>;
using uint16 = vector_t<uint, 16>;

typedef ushort __attribute__((ext_vector_type(8))) ushort8;
typedef ushort __attribute__((ext_vector_type(16))) ushort16;
typedef ushort __attribute__((ext_vector_type(32))) ushort32;
typedef ushort __attribute__((ext_vector_type(64))) ushort64;
typedef uint __attribute__((ext_vector_type(32))) uint32;

using coord_t = vector_t<int, 2>;
} // namespace intel end
} // namespace cute end
