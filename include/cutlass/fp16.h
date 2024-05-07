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
#include <sycl/sycl.hpp>
#else
#include <cuda_fp16.h>
#endif

// Add these definitions in the cutlass namespace, so they do not clash with the ones in cuda
namespace cutlass {

#if defined(CUTLASS_ENABLE_SYCL)
    using half = sycl::half;
    using half2 = sycl::half2;
#else
    using half_raw = __half_raw;
    using half2 = __half2;
#endif

    CUTLASS_HOST_DEVICE
    float half2float (half const& flt) {
#if defined(CUTLASS_ENABLE_SYCL)
      return static_cast<float>(flt);
#else
      return __half2float(flt);
#endif
    }

    CUTLASS_HOST_DEVICE
    half float2half (float const& flt) {
#if defined(CUTLASS_ENABLE_SYCL)
      return static_cast<half>(flt);
#else
      return __float2half(flt);
#endif
    }

    CUTLASS_HOST_DEVICE
    half float2half_rn (float const& flt) {
#if defined(CUTLASS_ENABLE_SYCL)
      return static_cast<half>(flt);
#else
      return __float2half_rn(flt);
#endif
    }

    CUTLASS_HOST_DEVICE
    int int2half_rn (half const& flt) {
#if defined(CUTLASS_ENABLE_SYCL)
      return static_cast<int>(flt);
#else
      return __int2half_rn(flt);
#endif
    }

    CUTLASS_HOST_DEVICE
    half2 hsub2(const half2 a, const half2 b) {
#if defined(CUTLASS_ENABLE_SYCL)
      return a - b;
#else
      return __hsub2(a, b);
#endif
    }
}
