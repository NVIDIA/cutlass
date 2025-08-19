/***************************************************************************************************
 * Copyright (c) 2024 - 2025 Codeplay Software Ltd. All rights reserved.
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
#include <cute/util/sycl_vec.hpp>

// mma_bf16
SYCL_EXTERNAL cute::intel::float8 intel_sub_group_bf16_bf16_matrix_mad_k16(cute::intel::short8 a, cute::intel::int8 b, cute::intel::float8 acc);
SYCL_EXTERNAL cute::intel::float4 intel_sub_group_bf16_bf16_matrix_mad_k16(cute::intel::short4 a, cute::intel::int8 b, cute::intel::float4 acc);
SYCL_EXTERNAL cute::intel::float2 intel_sub_group_bf16_bf16_matrix_mad_k16(cute::intel::short2 a, cute::intel::int8 b, cute::intel::float2 acc);
SYCL_EXTERNAL               float intel_sub_group_bf16_bf16_matrix_mad_k16(              short a, cute::intel::int8 b,               float acc);
// mma_half
SYCL_EXTERNAL cute::intel::float8 intel_sub_group_f16_f16_matrix_mad_k16(cute::intel::short8 a, cute::intel::int8 b, cute::intel::float8 acc);
SYCL_EXTERNAL cute::intel::float4 intel_sub_group_f16_f16_matrix_mad_k16(cute::intel::short4 a, cute::intel::int8 b, cute::intel::float4 acc);
SYCL_EXTERNAL cute::intel::float2 intel_sub_group_f16_f16_matrix_mad_k16(cute::intel::short2 a, cute::intel::int8 b, cute::intel::float2 acc);
SYCL_EXTERNAL               float intel_sub_group_f16_f16_matrix_mad_k16(              short a, cute::intel::int8 b,               float acc);
// mma_s8
SYCL_EXTERNAL cute::intel::int8 intel_sub_group_i8_i8_matrix_mad_k32(cute::intel::short8 a, cute::intel::int8 b, cute::intel::int8 acc);
SYCL_EXTERNAL cute::intel::int4 intel_sub_group_i8_i8_matrix_mad_k32(cute::intel::short4 a, cute::intel::int8 b, cute::intel::int4 acc);
SYCL_EXTERNAL cute::intel::int2 intel_sub_group_i8_i8_matrix_mad_k32(cute::intel::short2 a, cute::intel::int8 b, cute::intel::int2 acc);
SYCL_EXTERNAL               int intel_sub_group_i8_i8_matrix_mad_k32(              short a, cute::intel::int8 b,               int acc);
// mma_u8
SYCL_EXTERNAL cute::intel::int8 intel_sub_group_u8_u8_matrix_mad_k32(cute::intel::ushort8 a, cute::intel::uint8 b, cute::intel::int8 acc);
SYCL_EXTERNAL cute::intel::int4 intel_sub_group_u8_u8_matrix_mad_k32(cute::intel::ushort4 a, cute::intel::uint8 b, cute::intel::int4 acc);
SYCL_EXTERNAL cute::intel::int2 intel_sub_group_u8_u8_matrix_mad_k32(cute::intel::ushort2 a, cute::intel::uint8 b, cute::intel::int2 acc);
SYCL_EXTERNAL               int intel_sub_group_u8_u8_matrix_mad_k32(              ushort a, cute::intel::uint8 b,               int acc);
// mma_tf32
SYCL_EXTERNAL cute::intel::float8 intel_sub_group_tf32_tf32_matrix_mad_k8(cute::intel::float4 a, cute::intel::float8 b, cute::intel::float8 acc);
SYCL_EXTERNAL cute::intel::float4 intel_sub_group_tf32_tf32_matrix_mad_k8(cute::intel::float2 a, cute::intel::float8 b, cute::intel::float4 acc);
SYCL_EXTERNAL cute::intel::float2 intel_sub_group_tf32_tf32_matrix_mad_k8(              float a, cute::intel::float8 b, cute::intel::float2 acc);
SYCL_EXTERNAL               float intel_sub_group_tf32_tf32_matrix_mad_k8(              float a, cute::intel::float8 b,               float acc);
// mma_bfloat16 with bfloat16 accumulator:
SYCL_EXTERNAL cute::intel::short8 intel_sub_group_bf16_bf16_matrix_mad_k16(cute::intel::short8 a, cute::intel::int8 b, cute::intel::short8 acc);
SYCL_EXTERNAL cute::intel::short4 intel_sub_group_bf16_bf16_matrix_mad_k16(cute::intel::short4 a, cute::intel::int8 b, cute::intel::short4 acc);
SYCL_EXTERNAL cute::intel::short2 intel_sub_group_bf16_bf16_matrix_mad_k16(cute::intel::short2 a, cute::intel::int8 b, cute::intel::short2 acc);
SYCL_EXTERNAL               short intel_sub_group_bf16_bf16_matrix_mad_k16(              short a, cute::intel::int8 b,               short acc);

// Use the spirv functions as the builtins do not work
SYCL_EXTERNAL cute::intel::half8 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short8, cute::intel::int8, cute::intel::half8, int32_t);
SYCL_EXTERNAL cute::intel::half4 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short4, cute::intel::int8, cute::intel::half4, int32_t);
SYCL_EXTERNAL cute::intel::half2 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short2, cute::intel::int8, cute::intel::half2, int32_t);
SYCL_EXTERNAL cute::intel::half  __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t,               short, cute::intel::int8,  cute::intel::half, int32_t);

struct SPIRV_MMAOperands {
  static constexpr int SPIRV_MatrixAFp16 = 0x400;
  static constexpr int SPIRV_MatrixBFp16 = 0x800;
};

namespace cute::detail
{

template <class ElementD, class ElementA, class ElementB, class ElementC>
struct XeSubgroupMatrixMultiplyAccumulate {
    static_assert(dependent_false<>, "Unsupported MMA Configuration.");
};

template<>
struct XeSubgroupMatrixMultiplyAccumulate<float, bfloat16_t, bfloat16_t, float> {
    template<typename ARegisters, typename BRegisters, typename CRegisters>
    CUTE_HOST_DEVICE
    auto operator()(ARegisters a, BRegisters b, CRegisters c) {
      return intel_sub_group_bf16_bf16_matrix_mad_k16(a, b, c);
    }
};
  
template<>
struct XeSubgroupMatrixMultiplyAccumulate<float, half_t, half_t, float> {
    template<typename ARegisters, typename BRegisters, typename CRegisters>
    CUTE_HOST_DEVICE
    auto operator()(ARegisters a, BRegisters b, CRegisters c) {
      return intel_sub_group_f16_f16_matrix_mad_k16(a, b, c);
    }
};

template<>
struct XeSubgroupMatrixMultiplyAccumulate<bfloat16_t, bfloat16_t, bfloat16_t, bfloat16_t> {
    template<typename ARegisters, typename BRegisters, typename CRegisters>
    CUTE_HOST_DEVICE
    auto operator()(ARegisters a, BRegisters b, CRegisters c) {
      return intel_sub_group_bf16_bf16_matrix_mad_k16(a, b, c);
    }
};

template<>
struct XeSubgroupMatrixMultiplyAccumulate<half_t, half_t, half_t, half_t> {
  template<typename ARegisters, typename BRegisters, typename CRegisters>
  CUTE_HOST_DEVICE
  auto operator()(ARegisters a, BRegisters b, CRegisters c) {
    return __spirv_SubgroupMatrixMultiplyAccumulateINTEL(16, a, b, c,
             SPIRV_MMAOperands::SPIRV_MatrixAFp16 | SPIRV_MMAOperands::SPIRV_MatrixBFp16);
  }
};

template<>
struct XeSubgroupMatrixMultiplyAccumulate<int32_t, int8_t, int8_t, int32_t> {
    template<typename ARegisters, typename BRegisters, typename CRegisters>
    CUTE_HOST_DEVICE
    auto operator()(ARegisters a, BRegisters b, CRegisters c) {
      return intel_sub_group_i8_i8_matrix_mad_k32(a, b, c);
    }
};
  
template<>
struct XeSubgroupMatrixMultiplyAccumulate<int32_t, uint8_t, uint8_t, int32_t> {
    template<typename ARegisters, typename BRegisters, typename CRegisters>
    CUTE_HOST_DEVICE
    auto operator()(ARegisters a, BRegisters b, CRegisters c) {
      return intel_sub_group_u8_u8_matrix_mad_k32(a, b, c);
    }
};
  
template<>
struct XeSubgroupMatrixMultiplyAccumulate<float, tfloat32_t, tfloat32_t, float> {
    template<typename ARegisters, typename BRegisters, typename CRegisters>
    CUTE_HOST_DEVICE
    auto operator()(ARegisters a, BRegisters b, CRegisters c) {
      return intel_sub_group_tf32_tf32_matrix_mad_k8(a, b, c);
    }
};
} // namespace cute::detail end
