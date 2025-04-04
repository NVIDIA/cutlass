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

#include <cute/arch/copy.hpp>
#include <cute/config.hpp>
#include <cute/util/sycl_vec.hpp>

#ifdef __SYCL_DEVICE_ONLY__
#define SYCL_DEVICE_BUILTIN(x) SYCL_EXTERNAL extern "C" x
#else
#define SYCL_DEVICE_BUILTIN(x)                                                 \
  inline x {                                                                   \
    CUTE_INVALID_CONTROL_PATH(                                                 \
        "Attempting to use a device built-in in host code.");                  \
  }
#endif

#ifdef __SYCL_DEVICE_ONLY__
#define SYCL_DEVICE_OCL(x) SYCL_EXTERNAL x
#else
#define SYCL_DEVICE_OCL(x)                                                     \
  inline x {                                                                   \
    CUTE_INVALID_CONTROL_PATH(                                                 \
        "Attempting to use a device built-in in host code.");                  \
  }
#endif

// 64bits No transform Transpose
SYCL_DEVICE_BUILTIN(
    cute::intel::ulong __builtin_IB_subgroup_block_read_flat_transpose_u64_k1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ulong2 __builtin_IB_subgroup_block_read_flat_transpose_u64_k2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ulong4 __builtin_IB_subgroup_block_read_flat_transpose_u64_k4(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
#undef SYCL_DEVICE_BUILTIN

#undef __global
#define __global __attribute__((opencl_global))

// 64bits No transform Transpose
SYCL_DEVICE_OCL(cute::intel::ulong intel_sub_group_block_read_transpose_64b_8r1c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::ulong2 intel_sub_group_block_read_transpose_64b_8r2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::ulong4 intel_sub_group_block_read_transpose_64b_8r4c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
#undef SYCL_DEVICE_OCL

namespace cute
{
struct XE_2D_U64x8x1_LD_T {
  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 8, "Expected T to have size 8");
    *reinterpret_cast<ulong *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transpose_u64_k1(
            (intptr_t)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U64x8x2_LD_T {
  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 8, "Expected T to have size 8");
    *reinterpret_cast<intel::ulong2 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transpose_u64_k2(
            (intptr_t)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U64x8x4_LD_T {
  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 8, "Expected T to have size 8");
    *reinterpret_cast<intel::ulong4 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transpose_u64_k4(
            (intptr_t)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};
} // end namespace cute
