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

namespace cute
{

#ifdef __SYCL_DEVICE_ONLY__
#define SYCL_DEVICE_BUILTIN(x) SYCL_EXTERNAL extern "C" x
#else
#define SYCL_DEVICE_BUILTIN(x)  \
  inline x { assert(false); }
#endif

SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u32_m8k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord, intel::uint8 data));
SYCL_DEVICE_BUILTIN(intel::ushort8 __builtin_IB_subgroup_block_read_flat_u16_m8k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(intel::uint8 __builtin_IB_subgroup_block_read_flat_u32_m8k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(intel::ushort64 __builtin_IB_subgroup_block_read_flat_u16_m32k16v2(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(intel::ushort32 __builtin_IB_subgroup_block_read_flat_u16_m16k16v2(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(intel::ushort16 intel_subgroup_block_read_u16_m8k16v2(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(intel::ushort32 __builtin_IB_subgroup_block_read_flat_u16_m32k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(intel::uint16 __builtin_IB_subgroup_block_read_flat_u32_m16k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(intel::uint32 __builtin_IB_subgroup_block_read_flat_transform_u16_k32v2(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(intel::int16 __builtin_IB_subgroup_block_read_flat_transform_u16_k16v2(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(intel::int16 __builtin_IB_subgroup_block_read_flat_transform_u16_k32(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));
SYCL_DEVICE_BUILTIN(intel::int8 intel_subgroup_block_read_transform_u16_k16(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, intel::coord_t coord));


#undef SYCL_DEVICE_BUILTIN

struct XE_2D_U16x8x16x1x1_LD_N
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 2, "Expected T to have size 2");
      *(intel::ushort8 *)dst = __builtin_IB_subgroup_block_read_flat_u16_m8k16v1(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

struct XE_2D_U32x8x16x1x1_LD_N
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 4, "Expected T to have size 4");
      *(intel::uint8 *)dst = __builtin_IB_subgroup_block_read_flat_u32_m8k16v1(
            (long)baseoffset, width - 1, height - 1, pitch - 1, coord); 
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif                                     
  }
};

struct XE_2D_U16x16x16x1x1_LD_N
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 2, "Expected T to have size 2");
      *(intel::uint8 *)dst = __builtin_IB_subgroup_block_read_flat_u32_m8k16v1(
            (long)baseoffset, width - 1, height - 1, pitch - 1, coord);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif                                      
  }
};

struct XE_2D_U16x8x16x4x2_LD_N
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 2, "Expected T to have size 2");
      *(intel::ushort64 *)dst = __builtin_IB_subgroup_block_read_flat_u16_m32k16v2(
          long(baseoffset), width - 1, height - 1, pitch - 1, coord);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

struct XE_2D_U16x8x16x2x2_LD_N
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 2, "Expected T to have size 2");
      *(intel::ushort32*) dst = __builtin_IB_subgroup_block_read_flat_u16_m16k16v2(
          long(baseoffset), width - 1, height - 1, pitch - 1, coord);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

struct XE_2D_U16x8x16x1x2_LD_N
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 2, "Expected T to have size 2");
      intel::ushort16 tmp = (intel_subgroup_block_read_u16_m8k16v2(
          (long)baseoffset, width, height, pitch, coord));
      *(intel::ushort16 *)dst = *reinterpret_cast<intel::ushort16 *>(&tmp);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

struct XE_2D_U16x8x16x4x1_LD_N
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 2, "Expected T to have size 2");
        *(intel::ushort32*) dst = __builtin_IB_subgroup_block_read_flat_u16_m32k16v1(
            long(baseoffset), width - 1, height - 1, pitch - 1, coord);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

struct XE_2D_U32x8x16x2x1_LD_N
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 4, "Expected T to have size 4");
      intel::uint16 tmp = __builtin_IB_subgroup_block_read_flat_u32_m16k16v1(
          long(baseoffset), width - 1, height - 1, pitch - 1, coord);
      *(intel::uint16 *)dst = *reinterpret_cast<intel::uint16 *>(&tmp);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

struct XE_2D_U16x16x16x2x1_LD_N
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width,
                                    int height, int pitch, intel::coord_t coord,
                                    T *dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 2, "Expected T to have size 2");
      intel::uint16 tmp = __builtin_IB_subgroup_block_read_flat_u32_m16k16v1(
          long(baseoffset), width - 1, height - 1, pitch - 1, coord);
      *(intel::uint16 *)dst = *reinterpret_cast<intel::uint16 *>(&tmp);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

struct XE_2D_U16x16x16x2x2_V
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *base_address, int width, int height, int pitch, intel::coord_t coord, T* dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 2, "Expected T to have size 2");
      *(intel::uint32*) dst = __builtin_IB_subgroup_block_read_flat_transform_u16_k32v2(long(base_address), width - 1, height - 1, pitch - 1, coord);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

struct XE_2D_U16x16x16x1x2_V
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *base_address, int width, int height, int pitch, intel::coord_t coord, T* dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 2, "Expected T to have size 2");
      *(intel::int16*) dst = __builtin_IB_subgroup_block_read_flat_transform_u16_k16v2(long(base_address), width - 1, height - 1, pitch - 1, coord);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

struct XE_2D_U16x16x16x2x1_V
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *base_address, int width, int height, int pitch, intel::coord_t coord, T* dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 2, "Expected T to have size 2");
      *(intel::int16*) dst = __builtin_IB_subgroup_block_read_flat_transform_u16_k32(long(base_address), width - 1, height - 1, pitch - 1, coord);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

struct XE_2D_U16x16x16x1x1_V
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *base_address, int width, int height, int pitch, intel::coord_t coord, T* dst) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 2, "Expected T to have size 2");
      // Note: this function is in the headers, but is named confusingly and returns unsigned integers rather than signed integers:
      *(intel::int8*) dst = intel_subgroup_block_read_transform_u16_k16((long)base_address, width, height, pitch, coord);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

struct XE_2D_U32x8x16x1x1_ST_N
{
  template <class T>
  CUTE_HOST_DEVICE static void copy(const void *baseoffset, int width, int height,
                                    int pitch, intel::coord_t coord, const T *src) {
    #if defined(SYCL_INTEL_TARGET)
      static_assert(sizeof(T) == 4, "Expected T to have size 4");
      __builtin_IB_subgroup_block_write_flat_u32_m8k16v1(
          (long)baseoffset, width - 1, height - 1, pitch - 1, coord,
          *(intel::uint8 *)src);
    #else
      CUTE_INVALID_CONTROL_PATH("Trying to use block loads on non-PVC hardware");
    #endif
  }
};

} // end namespace cute
