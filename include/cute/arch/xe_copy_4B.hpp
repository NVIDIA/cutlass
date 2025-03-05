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

enum class CacheControl {
    kDefault   = 0,
    kL1UC_L3UC = 1, // Override to L1 uncached and L3 uncached
    kL1UC_L3C  = 2, // Override to L1 uncached and L3 cached
    kL1C_L3UC  = 3, // Override to L1 cached and L3 uncached
    kL1C_L3C   = 4, // Override to L1 cached and L3 cached
    kL1S_L3UC  = 5, // Override to L1 streaming load and L3 uncached
    kL1S_L3C   = 6, // Override to L1 streaming load and L3 cached
    kL1IAR_L3C = 7, // Override to L1 invalidate-after-read, and L3 cached
};

// 32bits specific for tf32 No transform No transpose
SYCL_DEVICE_BUILTIN(
    uint __builtin_IB_subgroup_block_read_flat_u32_m1k8v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    uint __builtin_IB_subgroup_block_read_flat_u32_m2k8v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint2 __builtin_IB_subgroup_block_read_flat_u32_m4k8v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint4 __builtin_IB_subgroup_block_read_flat_u32_m8k8v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint8 __builtin_IB_subgroup_block_read_flat_u32_m16k8v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint16 __builtin_IB_subgroup_block_read_flat_u32_m32k8v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

SYCL_DEVICE_BUILTIN(
    cute::intel::uint2 __builtin_IB_subgroup_block_read_flat_u32_m1k8v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint2 __builtin_IB_subgroup_block_read_flat_u32_m2k8v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint4 __builtin_IB_subgroup_block_read_flat_u32_m4k8v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint8 __builtin_IB_subgroup_block_read_flat_u32_m8k8v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint16 __builtin_IB_subgroup_block_read_flat_u32_m16k8v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint32 __builtin_IB_subgroup_block_read_flat_u32_m32k8v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

// 32bits No transform No transpose
SYCL_DEVICE_BUILTIN(uint __builtin_IB_subgroup_block_read_flat_u32_m1k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint2 __builtin_IB_subgroup_block_read_flat_u32_m2k16v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint4 __builtin_IB_subgroup_block_read_flat_u32_m4k16v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint8 __builtin_IB_subgroup_block_read_flat_u32_m8k16v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint16 __builtin_IB_subgroup_block_read_flat_u32_m16k16v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint32 __builtin_IB_subgroup_block_read_flat_u32_m32k16v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

// 32bits No transform Transpose
SYCL_DEVICE_BUILTIN(uint __builtin_IB_subgroup_block_read_flat_transpose_u32_k1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint2 __builtin_IB_subgroup_block_read_flat_transpose_u32_k2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint4 __builtin_IB_subgroup_block_read_flat_transpose_u32_k4(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint8 __builtin_IB_subgroup_block_read_flat_transpose_u32_k8(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

// 32bits
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u32_m1k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, uint data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u32_m2k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uint2 data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u32_m4k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uint4 data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u32_m8k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uint8 data));

#undef SYCL_DEVICE_BUILTIN

#undef __global
#define __global __attribute__((opencl_global))
// 32bits specific for tf32 No transform No transpose
SYCL_DEVICE_OCL(uint intel_sub_group_block_read_32b_1r8c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(uint intel_sub_group_block_read_32b_2r8c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint2 intel_sub_group_block_read_32b_4r8c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint4 intel_sub_group_block_read_32b_8r8c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint8 intel_sub_group_block_read_32b_16r8c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint16 intel_sub_group_block_read_32b_32r8c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));

SYCL_DEVICE_OCL(cute::intel::uint2 intel_sub_group_block_read_32b_1r8x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint2 intel_sub_group_block_read_32b_2r8x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint4 intel_sub_group_block_read_32b_4r8x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint8 intel_sub_group_block_read_32b_8r8x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint16 intel_sub_group_block_read_32b_16r8x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint32 intel_sub_group_block_read_32b_32r8x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));

// 32bits No transform No transpose
SYCL_DEVICE_OCL(uint intel_sub_group_block_read_32b_1r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint2 intel_sub_group_block_read_32b_2r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint4 intel_sub_group_block_read_32b_4r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint8 intel_sub_group_block_read_32b_8r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint16 intel_sub_group_block_read_32b_16r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint32 intel_sub_group_block_read_32b_32r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));

// 32bits No transform Transpose
SYCL_DEVICE_OCL(uint intel_sub_group_block_read_transpose_32b_16r1c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint2 intel_sub_group_block_read_transpose_32b_16r2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint4 intel_sub_group_block_read_transpose_32b_16r4c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint8 intel_sub_group_block_read_transpose_32b_16r8c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));

// 32bits store
SYCL_DEVICE_OCL(void intel_sub_group_block_write_32b_1r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord, uint data));
SYCL_DEVICE_OCL(void intel_sub_group_block_write_32b_2r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord, cute::intel::uint2 data));
SYCL_DEVICE_OCL(void intel_sub_group_block_write_32b_4r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord, cute::intel::uint4 data));
SYCL_DEVICE_OCL(void intel_sub_group_block_write_32b_8r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord, cute::intel::uint8 data));
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_32b_16r8x1c(
    __global void* base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
#undef SYCL_DEVICE_OCL

namespace cute
{
struct XE_2D_U32x1x16_LD_N {
  using BlockShape = Shape<_1, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<uint *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m1k16v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U32x2x16_LD_N {
  using BlockShape = Shape<_2, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint2 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m2k16v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U32x4x16_LD_N {
  using BlockShape = Shape<_4, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint4 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m4k16v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U32x8x16_LD_N {
  using BlockShape = Shape<_8, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint8 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m8k16v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U32x16x16_LD_N {
  using BlockShape = Shape<_16, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint16 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m16k16v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U32x32x16_LD_N {
  using BlockShape = Shape<_32, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint32 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m32k16v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x1x8_LD_N {
  using BlockShape = Shape<_32, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<uint *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m1k8v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x2x8_LD_N {
  using BlockShape = Shape<_2, _8>;
  using ValueShape = Shape<_1, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<uint *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m2k8v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x4x8_LD_N {
  using BlockShape = Shape<_4, _8>;
  using ValueShape = Shape<_2, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint2 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m4k8v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x8x8_LD_N {
  using BlockShape = Shape<_8, _8>;
  using ValueShape = Shape<_4, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint4 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m8k8v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x16x8_LD_N {
  using BlockShape = Shape<_16, _8>;
  using ValueShape = Shape<_8, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint8 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m16k8v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x32x8_LD_N {
  using BlockShape = Shape<_32, _8>;
  using ValueShape = Shape<_16, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint16 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m32k8v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x1x16_LD_N {
  using BlockShape = Shape<_1, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint2 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m1k8v2(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x2x16_LD_N {
  using BlockShape = Shape<_2, _16>;
  using ValueShape = Shape<_1, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint2 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m2k8v2(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x4x16_LD_N {
  using BlockShape = Shape<_4, _16>;
  using ValueShape = Shape<_2, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint4 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m4k8v2(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x8x16_LD_N {
  using BlockShape = Shape<_8, _16>;
  using ValueShape = Shape<_4, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint8 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m8k8v2(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x16x16_LD_N {
  using BlockShape = Shape<_16, _16>;
  using ValueShape = Shape<_8, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint16 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m16k8v2(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_TF32x32x16_LD_N {
  using BlockShape = Shape<_32, _16>;
  using ValueShape = Shape<_16, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint32 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u32_m32k8v2(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};


struct XE_2D_U32x16x1_LD_T {
  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<uint *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transpose_u32_k1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U32x16x2_LD_T {
  using BlockShape = Shape<_2, _16>;

  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint2 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transpose_u32_k2(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U32x16x4_LD_T {
  using BlockShape = Shape<_4, _16>;

  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint4 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transpose_u32_k4(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U32x16x8_LD_T {
  using BlockShape = Shape<_8, _16>;

  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    *reinterpret_cast<intel::uint8 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transpose_u32_k8(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }

  struct PREFETCH {
    CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                      int height, int pitch,
                                      intel::coord_t coord) {
#if defined(SYCL_INTEL_TARGET)
      intel_sub_group_2d_block_prefetch_32b_16r8x1c(
          (__global void*)baseoffset, width - 1, height - 1, pitch - 1, coord);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U32x1x16_ST_N {
  using BlockShape = Shape<_1, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    // static_assert(sizeof(T) == 4, "Expected T to have size 4");
    __builtin_IB_subgroup_block_write_flat_u32_m1k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(uint *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U32x2x16_ST_N {
  using BlockShape = Shape<_2, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    __builtin_IB_subgroup_block_write_flat_u32_m2k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::uint2 *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U32x4x16_ST_N {
  using BlockShape = Shape<_4, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 4, "Expected T to have size 4");
    __builtin_IB_subgroup_block_write_flat_u32_m4k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::uint4 *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U32x8x16_ST_N {
  using BlockShape = Shape<_8, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    // static_assert(sizeof(T) == 4, "Expected T to have size 4");
    __builtin_IB_subgroup_block_write_flat_u32_m8k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::uint8 *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

} // end namespace cute
