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

#if defined(CUTLASS_ENABLE_SYCL)
#include "cutlass/detail/helper_macros.hpp"

// Add these definitions in the cutlass namespace, so they do not clash with the ones in cuda
namespace cutlass {
    // We use this struct instead of sycl::int4 because the sycl version requires x() to access x,
    // while the struct does not need the (). This prevents us from having to modify the Cutlass
    // implementation in all the places where these vector types are used.
    using int2 = struct alignas(8) {
        int x, y;
    };

    using int4 = struct alignas(16) {
        int x, y, z, w;
    };

    using uint2 = struct alignas(8) {
        unsigned int x, y;
    };

    using uint4 = struct alignas(16) {
        unsigned int x, y, z, w;
    };

    using float4 = struct alignas(16) {
        float x, y, z, w;
    };

    using long4 = struct alignas(16) {
        long int x, y, z, w;
    };

    using ulong4 = struct alignas(16) {
        unsigned long int x, y, z, w;
    };

    using longlong2 = struct alignas(16) {
        long long int x, y;
    };

    using ulonglong2 = struct alignas(16) {
        unsigned long long int x, y;
    };

    using longlong4 = struct alignas(16) {
        long long int x, y, z, w;
    };

    using ulonglong4 = struct alignas(16) {
        unsigned long long int x, y, z, w;
    };

    using double2 = struct alignas(16) {
        long long int x, y;
    };

    using double4 = struct alignas(16) {
        long long int x, y, z, w;
    };

    CUTLASS_HOST_DEVICE
    int2 make_int2(int x, int y) {
      return int2{x,y};
    }

    CUTLASS_HOST_DEVICE
    int4 make_int4(int x, int y, int z, int w) {
      return int4 {x,y,z,w};
    }
}
#else
#include <vector_types.h>
#endif
