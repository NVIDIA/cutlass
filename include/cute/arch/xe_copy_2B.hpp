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
#include <cute/arch/xe_copy_4B.hpp>

#ifdef __SYCL_DEVICE_ONLY__
#define SYCL_DEVICE_BUILTIN(x) SYCL_EXTERNAL extern "C" x
#else
#define SYCL_DEVICE_BUILTIN(x) inline x { assert(false); }
#endif

#ifdef __SYCL_DEVICE_ONLY__
#define SYCL_DEVICE_OCL(x) SYCL_EXTERNAL x
#else
#define SYCL_DEVICE_OCL(x) inline x { assert(false); }
#endif

using namespace cute;

SYCL_DEVICE_BUILTIN(intel::ushort16 intel_subgroup_block_read_u16_m8k16v2(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));

SYCL_DEVICE_BUILTIN(intel::int8 intel_subgroup_block_read_transform_u16_k16(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));

SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v2(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v2(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v2(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord, enum CacheControl cache_control));

// 16 bits No transform No transpose
SYCL_DEVICE_BUILTIN(ushort __builtin_IB_subgroup_block_read_flat_u16_m1k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::ushort2 __builtin_IB_subgroup_block_read_flat_u16_m2k16v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::ushort4 __builtin_IB_subgroup_block_read_flat_u16_m4k16v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::ushort8 __builtin_IB_subgroup_block_read_flat_u16_m8k16v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::ushort16 __builtin_IB_subgroup_block_read_flat_u16_m16k16v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::ushort32 __builtin_IB_subgroup_block_read_flat_u16_m32k16v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));

SYCL_DEVICE_BUILTIN(
    intel::ushort2 __builtin_IB_subgroup_block_read_flat_u16_m1k16v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::ushort4 __builtin_IB_subgroup_block_read_flat_u16_m2k16v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::ushort8 __builtin_IB_subgroup_block_read_flat_u16_m4k16v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::ushort16 __builtin_IB_subgroup_block_read_flat_u16_m8k16v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::ushort32 __builtin_IB_subgroup_block_read_flat_u16_m16k16v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::ushort64 __builtin_IB_subgroup_block_read_flat_u16_m32k16v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));

// 16bits VNNI transform No transpose
SYCL_DEVICE_BUILTIN(
    intel::uint8 __builtin_IB_subgroup_block_read_flat_transform_u16_k16(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::uint16 __builtin_IB_subgroup_block_read_flat_transform_u16_k32(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::uint16 __builtin_IB_subgroup_block_read_flat_transform_u16_k16v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    intel::uint32 __builtin_IB_subgroup_block_read_flat_transform_u16_k32v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, intel::coord_t coord));

// 16bits
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u16_m1k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord, ushort data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u16_m2k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord, intel::ushort2 data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u16_m4k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord, intel::ushort4 data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u16_m8k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord, intel::ushort8 data));
#undef SYCL_DEVICE_BUILTIN

#undef __global__
#define __global __attribute__((opencl_global))
// 16bits No transform No transpose
SYCL_DEVICE_OCL(ushort intel_sub_group_block_read_16b_1r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::ushort2 intel_sub_group_block_read_16b_2r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::ushort4 intel_sub_group_block_read_16b_4r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::ushort8 intel_sub_group_block_read_16b_8r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::ushort16 intel_sub_group_block_read_16b_16r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::ushort32 intel_sub_group_block_read_16b_32r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));

SYCL_DEVICE_OCL(intel::ushort2 intel_sub_group_block_read_16b_1r16x2c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::ushort4 intel_sub_group_block_read_16b_2r16x2c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::ushort8 intel_sub_group_block_read_16b_4r16x2c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::ushort16 intel_sub_group_block_read_16b_8r16x2c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::ushort32 intel_sub_group_block_read_16b_16r16x2c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::ushort64 intel_sub_group_block_read_16b_32r16x2c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));

// 16bits VNNI transform No transpose
SYCL_DEVICE_OCL(intel::uint8 intel_sub_group_block_read_transform_16b_16r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::uint16 intel_sub_group_block_read_transform_16b_32r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::uint16 intel_sub_group_block_read_transform_16b_16r16x2c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(intel::uint32 intel_sub_group_block_read_transform_16b_32r16x2c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord));

// 16bits store
SYCL_DEVICE_OCL(void intel_sub_group_block_write_16b_1r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord, ushort data));
SYCL_DEVICE_OCL(void intel_sub_group_block_write_16b_2r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord, intel::ushort2 data));
SYCL_DEVICE_OCL(void intel_sub_group_block_write_16b_4r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord, intel::ushort4 data));
SYCL_DEVICE_OCL(void intel_sub_group_block_write_16b_8r16c(
    const __global void *base_address, int width, int height, int pitch,
    intel::coord_t coord, intel::ushort8 data));

// 2D prefetch
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_16b_1r16x2c(
    __global void* base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_16b_2r16x2c(
    __global void* base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_16b_4r16x2c(
    __global void* base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_16b_8r16x2c(
    __global void* base_address, int width, int height, int pitch,
    intel::coord_t coord));
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_16b_16r16x1c(
    __global void* base_address, int width, int height, int pitch,
    intel::coord_t coord));
#undef SYCL_DEVICE_OCL

namespace cute
{
struct XE_2D_U16x1x16_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<ushort *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m1k16v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U16x2x16_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::ushort2 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m2k16v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U16x4x16_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::ushort4 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m4k16v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U16x8x16_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::ushort8 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m8k16v1(
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
      __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v1(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x16x16_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::ushort16 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m16k16v1(
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
      __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v1(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x32x16_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::ushort32 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m32k16v1(
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
      __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v1(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x1x32_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::ushort2 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m1k16v2(
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
      intel_sub_group_2d_block_prefetch_16b_1r16x2c(
          (__global void*)baseoffset, width - 1, height - 1, pitch - 1, coord);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x2x32_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::ushort4 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m2k16v2(
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
      intel_sub_group_2d_block_prefetch_16b_2r16x2c(
          (__global void*)baseoffset, width - 1, height - 1, pitch - 1, coord);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x4x32_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::ushort8 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m4k16v2(
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
      intel_sub_group_2d_block_prefetch_16b_4r16x2c(
          (__global void*)baseoffset, width - 1, height - 1, pitch - 1, coord);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x8x32_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::ushort16 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m8k16v2(
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
      __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v2(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x16x32_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::ushort32 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m16k16v2(
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
      __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v2(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x32x32_LD_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::ushort64 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u16_m32k16v2(
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
      // __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v2(
      __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v2(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x16x16_LD_V {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::uint8 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transform_u16_k16(
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
      __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v1(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x32x16_LD_V {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::uint16 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transform_u16_k32(
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
      __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v1(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x16x32_LD_V {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::uint16 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transform_u16_k16v2(
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
      __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v2(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x32x32_LD_V {
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::uint32 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transform_u16_k32v2(
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
      __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v2(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U16x16x8_LD_T {
  using inst_dtype = uint32_t;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 4");
    *reinterpret_cast<intel::uint4 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transpose_u32_k4(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U16x16x16_LD_T {
  using inst_dtype = uint32_t;
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 2, "Expected T to have size 2");
    *reinterpret_cast<intel::uint8 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transpose_u32_k8(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U16x1x16_ST_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    // static_assert(sizeof(T) == 2, "Expected T to have size 2");
    __builtin_IB_subgroup_block_write_flat_u16_m1k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(ushort *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U16x2x16_ST_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    // static_assert(sizeof(T) == 2, "Expected T to have size 2");
    __builtin_IB_subgroup_block_write_flat_u16_m2k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::ushort2 *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U16x4x16_ST_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    // static_assert(sizeof(T) == 2, "Expected T to have size 2");
    __builtin_IB_subgroup_block_write_flat_u16_m4k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::ushort4 *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U16x8x16_ST_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    // static_assert(sizeof(T) == 2, "Expected T to have size 2");
    __builtin_IB_subgroup_block_write_flat_u16_m8k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::ushort8 *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};
} // end namespace cute
