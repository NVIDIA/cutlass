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

SYCL_EXTERNAL cute::intel::float8 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short8, cute::intel::int8, cute::intel::float8, int32_t);
SYCL_EXTERNAL cute::intel::float4 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short4, cute::intel::int8, cute::intel::float4, int32_t);
SYCL_EXTERNAL cute::intel::float2 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short2, cute::intel::int8, cute::intel::float2, int32_t);
SYCL_EXTERNAL               float __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t,               short, cute::intel::int8,               float, int32_t);

SYCL_EXTERNAL cute::intel::int8 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short8, cute::intel::int8, cute::intel::int8, int32_t);
SYCL_EXTERNAL cute::intel::int4 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short4, cute::intel::int8, cute::intel::int4, int32_t);
SYCL_EXTERNAL cute::intel::int2 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short2, cute::intel::int8, cute::intel::int2, int32_t);
SYCL_EXTERNAL               int __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t,               short, cute::intel::int8,               int, int32_t);

SYCL_EXTERNAL cute::intel::int8 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::ushort8, cute::intel::uint8, cute::intel::int8, int32_t);
SYCL_EXTERNAL cute::intel::int4 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::ushort4, cute::intel::uint8, cute::intel::int4, int32_t);
SYCL_EXTERNAL cute::intel::int2 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::ushort2, cute::intel::uint8, cute::intel::int2, int32_t);
SYCL_EXTERNAL               int __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t,               ushort, cute::intel::uint8,               int, int32_t);

SYCL_EXTERNAL cute::intel::float8 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::float4, cute::intel::float8, cute::intel::float8, int32_t);
SYCL_EXTERNAL cute::intel::float4 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::float2, cute::intel::float8, cute::intel::float4, int32_t);
SYCL_EXTERNAL cute::intel::float2 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t,               float, cute::intel::float8, cute::intel::float2, int32_t);
SYCL_EXTERNAL               float __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t,               float, cute::intel::float8,               float, int32_t);

SYCL_EXTERNAL cute::intel::short8 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short8, cute::intel::int8, cute::intel::short8, int32_t);
SYCL_EXTERNAL cute::intel::short4 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short4, cute::intel::int8, cute::intel::short4, int32_t);
SYCL_EXTERNAL cute::intel::short2 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short2, cute::intel::int8, cute::intel::short2, int32_t);
SYCL_EXTERNAL               short __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t,               short, cute::intel::int8,               short, int32_t);

SYCL_EXTERNAL cute::intel::half8 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short8, cute::intel::int8, cute::intel::half8, int32_t);
SYCL_EXTERNAL cute::intel::half4 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short4, cute::intel::int8, cute::intel::half4, int32_t);
SYCL_EXTERNAL cute::intel::half2 __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t, cute::intel::short2, cute::intel::int8, cute::intel::half2, int32_t);
SYCL_EXTERNAL cute::intel::half  __spirv_SubgroupMatrixMultiplyAccumulateINTEL(int32_t,               short, cute::intel::int8,  cute::intel::half, int32_t);

struct SPIRV_MMAOperands {
  static constexpr int SPIRV_MatrixASigned = 0x1;
  static constexpr int SPIRV_MatrixBSigned = 0x2;
  static constexpr int SPIRV_MatrixAInt8 = 0x10;
  static constexpr int SPIRV_MatrixBInt8 = 0x20;
  static constexpr int SPIRV_MatrixAFp16 = 0x400;
  static constexpr int SPIRV_MatrixBFp16 = 0x800;
  static constexpr int SPIRV_MatrixABf16 = 0x1000;
  static constexpr int SPIRV_MatrixBBf16 = 0x2000;
  static constexpr int SPIRV_MatrixCBf16 = 0xC;
  static constexpr int SPIRV_MatrixATf32 = 0x100;
  static constexpr int SPIRV_MatrixBTf32 = 0x200;
};

namespace cute::detail
{

template <class DElement, class AElement, class BElement, class CElement>
struct XeSubgroupMatrixMultiplyAccumulate {
  static_assert(dependent_false<>, "Unsupported MMA Configuration.");
};

template<>
struct XeSubgroupMatrixMultiplyAccumulate<float, bfloat16_t, bfloat16_t, float> {
    template<typename ARegisters, typename BRegisters, typename CRegisters>
    CUTE_HOST_DEVICE
    auto operator()(ARegisters a, BRegisters b, CRegisters c) {
      return __spirv_SubgroupMatrixMultiplyAccumulateINTEL(16, a, b, c,
               SPIRV_MMAOperands::SPIRV_MatrixABf16 | SPIRV_MMAOperands::SPIRV_MatrixBBf16 );
    }
};

template<>
struct XeSubgroupMatrixMultiplyAccumulate<float, half_t, half_t, float> {
    template<typename ARegisters, typename BRegisters, typename CRegisters>
    CUTE_HOST_DEVICE
    auto operator()(ARegisters a, BRegisters b, CRegisters c) {
      return __spirv_SubgroupMatrixMultiplyAccumulateINTEL(16, a, b, c,
             SPIRV_MMAOperands::SPIRV_MatrixAFp16 | SPIRV_MMAOperands::SPIRV_MatrixBFp16);
    }
};

template<>
struct XeSubgroupMatrixMultiplyAccumulate<bfloat16_t, bfloat16_t, bfloat16_t, bfloat16_t> {
    template<typename ARegisters, typename BRegisters, typename CRegisters>
    CUTE_HOST_DEVICE
    auto operator()(ARegisters a, BRegisters b, CRegisters c) {
      return __spirv_SubgroupMatrixMultiplyAccumulateINTEL(16, a, b, c,
               SPIRV_MMAOperands::SPIRV_MatrixABf16 | SPIRV_MMAOperands::SPIRV_MatrixBBf16 |
               SPIRV_MMAOperands::SPIRV_MatrixCBf16);
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
      return __spirv_SubgroupMatrixMultiplyAccumulateINTEL(32, a, b, c,
               SPIRV_MMAOperands::SPIRV_MatrixASigned | SPIRV_MMAOperands::SPIRV_MatrixBSigned |
               SPIRV_MMAOperands::SPIRV_MatrixAInt8 | SPIRV_MMAOperands::SPIRV_MatrixBInt8);
    }
};

template<>
struct XeSubgroupMatrixMultiplyAccumulate<int32_t, uint8_t, uint8_t, int32_t> {
    template<typename ARegisters, typename BRegisters, typename CRegisters>
    CUTE_HOST_DEVICE
    auto operator()(ARegisters a, BRegisters b, CRegisters c) {
      return __spirv_SubgroupMatrixMultiplyAccumulateINTEL(32, a, b, c,
               SPIRV_MMAOperands::SPIRV_MatrixAInt8 | SPIRV_MMAOperands::SPIRV_MatrixBInt8);
    }
};

template<>
struct XeSubgroupMatrixMultiplyAccumulate<float, tfloat32_t, tfloat32_t, float> {
    template<typename ARegisters, typename BRegisters, typename CRegisters>
    CUTE_HOST_DEVICE
    auto operator()(ARegisters a, BRegisters b, CRegisters c) {
      return __spirv_SubgroupMatrixMultiplyAccumulateINTEL(8, a, b, c,
               SPIRV_MMAOperands::SPIRV_MatrixATf32 | SPIRV_MMAOperands::SPIRV_MatrixBTf32);
    }
};
} // namespace cute::detail end
