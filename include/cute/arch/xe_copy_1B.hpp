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
#include <cute/arch/xe_copy_2B.hpp>
#include "cute/pointer.hpp"

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

// 8bits No transform No transpose
SYCL_DEVICE_BUILTIN(ushort __builtin_IB_subgroup_block_read_flat_u8_m1k32v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort2 __builtin_IB_subgroup_block_read_flat_u8_m2k32v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort4 __builtin_IB_subgroup_block_read_flat_u8_m4k32v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort8 __builtin_IB_subgroup_block_read_flat_u8_m8k32v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort16 __builtin_IB_subgroup_block_read_flat_u8_m16k32v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort32 __builtin_IB_subgroup_block_read_flat_u8_m32k32v1(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

SYCL_DEVICE_BUILTIN(
    cute::intel::ushort2 __builtin_IB_subgroup_block_read_flat_u8_m1k32v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort4 __builtin_IB_subgroup_block_read_flat_u8_m2k32v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort8 __builtin_IB_subgroup_block_read_flat_u8_m4k32v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort16 __builtin_IB_subgroup_block_read_flat_u8_m8k32v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort32 __builtin_IB_subgroup_block_read_flat_u8_m16k32v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort64 __builtin_IB_subgroup_block_read_flat_u8_m32k32v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));


// 8bits VNNI transform No transpose
SYCL_DEVICE_BUILTIN(
    cute::intel::uint8 __builtin_IB_subgroup_block_read_flat_transform_u8_k32(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint16 __builtin_IB_subgroup_block_read_flat_transform_u8_k32v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint32 __builtin_IB_subgroup_block_read_flat_transform_u8_k32v4(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

// 8bits No transform No transpose
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u8_m1k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uchar data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u8_m2k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uchar2 data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u8_m4k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uchar4));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u8_m8k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uchar8));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u8_m8k16v2(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uchar8));

// U8 prefetch
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u8_m1k32v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u8_m2k32v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u8_m4k32v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u8_m8k32v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));

#undef SYCL_DEVICE_BUILTIN

#undef __global
#define __global __attribute__((opencl_global))
// 8 bits No transform No transpose
SYCL_DEVICE_OCL(ushort intel_sub_group_block_read_8b_1r32c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::ushort2 intel_sub_group_block_read_8b_2r32c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::ushort4 intel_sub_group_block_read_8b_4r32c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::ushort8 intel_sub_group_block_read_8b_8r32c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::ushort16 intel_sub_group_block_read_8b_16r32c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));

SYCL_DEVICE_OCL(cute::intel::ushort2 intel_sub_group_block_read_8b_1r32x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::ushort4 intel_sub_group_block_read_8b_2r32x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::ushort8 intel_sub_group_block_read_8b_4r32x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::ushort16 intel_sub_group_block_read_8b_8r32x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::ushort32 intel_sub_group_block_read_8b_16r32x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::ushort64 intel_sub_group_block_read_8b_32r32x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));

// 8bits VNNI transform No transpose
SYCL_DEVICE_OCL(cute::intel::uint8 intel_sub_group_block_read_transform_8b_32r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint16 intel_sub_group_block_read_transform_8b_32r16x2c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(cute::intel::uint32 intel_sub_group_block_read_transform_8b_32r16x4c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));

// 8bits store
SYCL_DEVICE_OCL(void intel_sub_group_block_write_8b_1r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord, cute::intel::uchar data));
SYCL_DEVICE_OCL(void intel_sub_group_block_write_8b_2r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord, cute::intel::uchar2 data));
SYCL_DEVICE_OCL(void intel_sub_group_block_write_8b_4r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord, cute::intel::uchar4 data));
SYCL_DEVICE_OCL(void intel_sub_group_block_write_8b_8r16c(
    const __global void *base_address, int width, int height, int pitch,
    cute::intel::coord_t coord, cute::intel::uchar8 data));


// 2D prefetch
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_8b_1r32x2c(
    __global void* base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_8b_2r32x2c(
    __global void* base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_8b_4r32x2c(
    __global void* base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_8b_8r32x2c(
    __global void* base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_8b_32r16x1c(
    __global void* base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));

#undef SYCL_DEVICE_OCL

namespace cute
{
struct XE_2D_U8x2x32_ST_N {
  using BlockShape = Shape<_2, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *src) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    __builtin_IB_subgroup_block_write_flat_u16_m2k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::ushort2 *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U8x1x32_LD_N {
  using BlockShape = Shape<_1, _32>;
  using inst_dtype = int8_t;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<ushort *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m1k32v1(
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
      __builtin_IB_subgroup_block_read_prefetch_u8_m1k32v1(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord, CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U8x2x32_LD_N {
  using BlockShape = Shape<_2, _32>;
  using inst_dtype = int8_t;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort2 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m2k32v1(
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
      __builtin_IB_subgroup_block_read_prefetch_u8_m2k32v1(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord, CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };

};

struct XE_2D_U8x4x32_LD_N {
  using BlockShape = Shape<_4, _32>;
  using inst_dtype = int8_t;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort4 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m4k32v1(
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
      __builtin_IB_subgroup_block_read_prefetch_u8_m4k32v1(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U8x8x32_LD_N {
  using BlockShape = Shape<_8, _32>;
  using inst_dtype = int8_t;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort8 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m8k32v1(
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
      __builtin_IB_subgroup_block_read_prefetch_u8_m8k32v1(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U8x16x32_LD_N {
  using BlockShape = Shape<_16, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort16 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m16k32v1(
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

struct XE_2D_U8x32x32_LD_N {
  using BlockShape = Shape<_32, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort32 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m32k32v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U4x16x16_LD_T {
  using BlockShape = Shape<_16, _16>;
  using inst_dtype = uint32_t;
  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    *reinterpret_cast<intel::uint2 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transpose_u32_k2(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U4x32x16_LD_T {
  using BlockShape = Shape<_32, _16>;
  using inst_dtype = uint32_t;
  static constexpr bool is_transpose = true;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    *reinterpret_cast<intel::uint4 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transpose_u32_k4(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U4x32x64_LD_N {
  using BlockShape = Shape<_32, _64>;
  using inst_dtype = int8_t;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort32 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m32k32v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);

   // ================= shuffle begin =================
   // FIXME: the performance of shuffle algorithm here is too bad, we are working with
   // compiler/IGC team to optimize it.

    static constexpr auto subgroup_size = 16;
    static constexpr auto copy_W = decltype(size<1>(BlockShape{}))::value / subgroup_size;
    static constexpr auto copy_H = decltype(size<0>(BlockShape{}))::value;

    auto sg = syclcompat::get_nd_item<1>().get_sub_group();
    auto id = int(ThreadIdxX()) % subgroup_size;

    cute::subbyte_iterator<int4_t> dst_iter(dst);
    cute::array_subbyte<int4_t, copy_W * copy_H> dst_tmp{};

    #pragma unroll
    for (int cw = 0; cw < copy_W; cw++) {
      auto remote_id = (id + cw * subgroup_size) / copy_W;

      // TODO: select 'ushort32' will cause compiling error, use 'ushort16' instead, why?
      intel::ushort16 remote_dst[2];
      remote_dst[0] = sycl::select_from_group(sg, *(reinterpret_cast<intel::ushort16 *>(dst)), remote_id);
      remote_dst[1] = sycl::select_from_group(sg, *((reinterpret_cast<intel::ushort16 *>(dst)) + 1), remote_id);

      cute::subbyte_iterator<int4_t> remote_dst_iter(remote_dst);

      #pragma unroll
      for (int row = 0; row < copy_H; row++) {
        dst_tmp[row + cw * copy_H] = remote_dst_iter[row * copy_W + id % copy_W].get();
      }
    }

   *reinterpret_cast<intel::ushort32 *>(cute::raw_pointer_cast(dst_iter)) = *reinterpret_cast<intel::ushort32 *>(cute::raw_pointer_cast(dst_tmp.begin()));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U4x16x64_LD_N {
  using BlockShape = Shape<_16, _64>;
  using inst_dtype = int8_t;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort16 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m16k32v1(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);

   // ================= shuffle begin =================
   // FIXME: the performance of shuffle algorithm here is too bad, we are working with
   // compiler/IGC team to optimize it.

    static constexpr auto subgroup_size = 16;
    static constexpr auto copy_W = decltype(size<1>(BlockShape{}))::value / subgroup_size;
    static constexpr auto copy_H = decltype(size<0>(BlockShape{}))::value;

    auto sg = syclcompat::get_nd_item<1>().get_sub_group();
    auto id = int(ThreadIdxX()) % subgroup_size;

    cute::subbyte_iterator<int4_t> dst_iter(dst);
    cute::array_subbyte<int4_t, copy_W * copy_H> dst_tmp{};

    #pragma unroll
    for (int cw = 0; cw < copy_W; cw++) {
      auto remote_id = (id + cw * subgroup_size) / copy_W;

      intel::ushort16 remote_dst;
      remote_dst = sycl::select_from_group(sg, *(reinterpret_cast<intel::ushort16 *>(dst)), remote_id);

      cute::subbyte_iterator<int4_t> remote_dst_iter(&remote_dst);


      #pragma unroll
      for (int row = 0; row < copy_H; row++) {
        dst_tmp[row + cw * copy_H] = remote_dst_iter[row * copy_W + id % copy_W].get();
      }
    }

   *reinterpret_cast<intel::ushort16 *>(cute::raw_pointer_cast(dst_iter)) = *reinterpret_cast<intel::ushort16 *>(cute::raw_pointer_cast(dst_tmp.begin()));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U8x1x64_LD_N {
  using BlockShape = Shape<_1, _64>;
  
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort2 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m1k32v2(
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
      intel_sub_group_2d_block_prefetch_8b_1r32x2c(
          (__global void*)baseoffset, width - 1, height - 1, pitch - 1, coord);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U8x2x64_LD_N {
  using BlockShape = Shape<_2, _64>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort4 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m2k32v2(
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
      intel_sub_group_2d_block_prefetch_8b_2r32x2c(
          (__global void*)baseoffset, width - 1, height - 1, pitch - 1, coord);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U8x4x64_LD_N {
  using BlockShape = Shape<_4, _64>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort8 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m4k32v2(
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
      intel_sub_group_2d_block_prefetch_8b_4r32x2c(
          (__global void*)baseoffset, width - 1, height - 1, pitch - 1, coord);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U8x8x64_LD_N {
  using BlockShape = Shape<_8, _64>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort16 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m8k32v2(
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
      intel_sub_group_2d_block_prefetch_8b_8r32x2c(
          (__global void*)baseoffset, width - 1, height - 1, pitch - 1, coord);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U8x16x64_LD_N {
  using BlockShape = Shape<_16, _64>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort32 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m16k32v2(
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

struct XE_2D_U8x32x64_LD_N {
  using BlockShape = Shape<_32, _64>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::ushort64 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_u8_m32k32v2(
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
      __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v2(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          CacheControl::kL1C_L3C);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};



struct XE_2D_U8x32x16_LD_V {
  using BlockShape = Shape<_32, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::uint8 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transform_u8_k32(
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
      intel_sub_group_2d_block_prefetch_8b_32r16x1c(
          (__global void*)baseoffset, width - 1, height - 1, pitch - 1, coord);
#else
      CUTE_INVALID_CONTROL_PATH(
          "Trying to use block prefetch on non-PVC hardware");
#endif
    }
  };
};

struct XE_2D_U8x32x32_LD_V {
  using BlockShape = Shape<_32, _32>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::uint16 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transform_u8_k32v2(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U8x32x64_LD_V {
  using BlockShape = Shape<_32, _64>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    *reinterpret_cast<intel::uint32 *>(dst) =
        __builtin_IB_subgroup_block_read_flat_transform_u8_k32v4(
            (long)(baseoffset), width - 1, height - 1, pitch - 1, coord);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U8x1x16_ST_N {
  using BlockShape = Shape<_1, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    __builtin_IB_subgroup_block_write_flat_u8_m1k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::uchar *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U8x2x16_ST_N {
  using BlockShape = Shape<_2, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    __builtin_IB_subgroup_block_write_flat_u8_m2k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::uchar2 *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U8x4x16_ST_N {
  using BlockShape = Shape<_4, _16>;

  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    __builtin_IB_subgroup_block_write_flat_u8_m4k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::uchar4 *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U8x8x16_ST_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    __builtin_IB_subgroup_block_write_flat_u8_m8k16v1(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::uchar8 *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};

struct XE_2D_U8x8x32_ST_N {
  template <class T>
  CUTE_HOST_DEVICE static void copy(void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord,
                                    const T *src) {
#if defined(SYCL_INTEL_TARGET)
    static_assert(sizeof(T) == 1, "Expected T to have size 1");
    __builtin_IB_subgroup_block_write_flat_u8_m8k16v2(
        (long)(baseoffset), width - 1, height - 1, pitch - 1, coord,
        *(intel::uchar8 *)(src));
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
#endif
  }
};
} // end namespace cute
