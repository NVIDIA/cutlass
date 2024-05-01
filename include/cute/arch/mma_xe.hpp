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

#include <cute/config.hpp>
#include <cute/arch/mma.hpp>
#include <cute/util/sycl_vec.hpp>

#ifdef __SYCL_DEVICE_ONLY__ 
#define SYCL_DEVICE_OCL(x) SYCL_EXTERNAL x
#else 
#define SYCL_DEVICE_OCL(x) inline x { assert(false); }
#endif

SYCL_DEVICE_OCL(cute::intel::float8 intel_sub_group_bf16_bf16_matrix_mad_k16(cute::intel::short8 a, cute::intel::int8 b, cute::intel::float8 acc));
SYCL_DEVICE_OCL(float  intel_sub_group_bf16_bf16_matrix_mad_k16(short a, cute::intel::int8 b, float acc));
#undef SYCL_DEVICE_OCL

namespace cute {
//MxNxK_A,B,C,D
//# of vector component of a x subgroup-size x function name
//float8 intel_sub_group_bf16_bf16_matrix_mad_k16(short8 a, int8 b, float8 acc);
//TODO: Is A really not transposed? Maybe better a macro than separate define for 1,2,4,8
struct XE_8x16x16_BF16BF16F32F32_NN
{
  using DRegisters = intel::float8[1];
  using ARegisters = intel::short8[1];
  using BRegisters = intel::int8[1];
  using CRegisters = intel::float8[1];

  CUTE_HOST_DEVICE static void
  fma(intel::float8      & d,
      intel::short8 const& a,
      intel::int8   const& b,
      intel::float8 const& c)
  {
    d = intel_sub_group_bf16_bf16_matrix_mad_k16(a, b, c);
  }
};
//float  intel_sub_group_bf16_bf16_matrix_mad_k16(short  a, int8 b, float  acc)
struct XE_1x16x16_BF16BF16F32F32_NN
{
  using DRegisters = float[1];
  using ARegisters = short[1];
  using BRegisters = intel::int8[1];
  using CRegisters = float[1];

  CUTE_HOST_DEVICE static void
  fma(float      & d,
      short const& a,
      intel::int8  const& b,
      float const& c)
  {
    d = intel_sub_group_bf16_bf16_matrix_mad_k16(a, b, c);
  }
};
} //namespace cute
