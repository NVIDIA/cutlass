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
#include "cute/config.hpp"

// TODO(Codeplay): These builtins are not available on SPIRV
SYCL_EXTERNAL extern "C"
cute::intel::uchar __builtin_IB_subgroup_block_read_flat_u8_m1k16v1(
  long baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord);

SYCL_EXTERNAL extern "C"
cute::intel::uchar64 __builtin_IB_subgroup_block_read_flat_u8_m32k16v2(
  long baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord);

SYCL_EXTERNAL extern "C"
cute::intel::uint2 __builtin_IB_subgroup_block_read_flat_transpose_u32_k2(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord);

SYCL_EXTERNAL extern "C"
cute::intel::uint4 __builtin_IB_subgroup_block_read_flat_transpose_u32_k4(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord);

SYCL_EXTERNAL extern "C"
cute::intel::ushort4  __builtin_IB_subgroup_block_read_cacheopts_transpose_u8_m32k4(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, int cacheOpt = 0);

SYCL_EXTERNAL extern "C"
cute::intel::ushort8  __builtin_IB_subgroup_block_read_cacheopts_transpose_u8_m32k8(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, int cacheOpt = 0);

enum class CacheControl {
  kDefault = 0,
  kL1UC_L3UC = 1, // Override to L1 uncached and L3 uncached
  kL1UC_L3C = 2, // Override to L1 uncached and L3 cached
  kL1C_L3UC = 3, // Override to L1 cached and L3 uncached
  kL1C_L3C = 4, // Override to L1 cached and L3 cached
  kL1S_L3UC = 5, // Override to L1 streaming load and L3 uncached
  kL1S_L3C = 6, // Override to L1 streaming load and L3 cached
  kL1IAR_L3C = 7, // Override to L1 invalidate-after-read, and L3 cached
};

// U16 prefetch
SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v1(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v2(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v1(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v1(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v2(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v2(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u8_m1k16v1(
  long baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u8_m1k32v1(
  long baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u8_m2k32v1(
  long baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u8_m4k32v1(
  long baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u8_m8k32v1(
  long baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u8_m32k32v1(
  long baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL
void intel_sub_group_2d_block_prefetch_8b_1r32x2c(
  __attribute__((opencl_global)) void *base_address, int width, int height, int pitch,
  cute::intel::coord_t coord);

SYCL_EXTERNAL
void intel_sub_group_2d_block_prefetch_8b_2r32x2c(
  __attribute__((opencl_global)) void *base_address, int width, int height, int pitch,
  cute::intel::coord_t coord);

SYCL_EXTERNAL
void intel_sub_group_2d_block_prefetch_8b_4r32x2c(
  __attribute__((opencl_global)) void *base_address, int width, int height, int pitch,
  cute::intel::coord_t coord);

SYCL_EXTERNAL
void intel_sub_group_2d_block_prefetch_8b_8r32x2c(
  __attribute__((opencl_global)) void *base_address, int width, int height, int pitch,
  cute::intel::coord_t coord);

SYCL_EXTERNAL
void intel_sub_group_2d_block_prefetch_8b_32r16x1c(
  __attribute__((opencl_global)) void *base_address, int width, int height, int pitch,
  cute::intel::coord_t coord);

SYCL_EXTERNAL
void __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v1(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL
void __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v2(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v1(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v1(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v2(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL extern "C"
void __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v2(
  intptr_t baseoffset, int width_minus_one, int height_minus_one,
  int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control);

SYCL_EXTERNAL
void intel_sub_group_2d_block_prefetch_16b_1r16x2c(
  __attribute__((opencl_global)) void *base_address, int width, int height, int pitch,
  cute::intel::coord_t coord);

SYCL_EXTERNAL
void intel_sub_group_2d_block_prefetch_16b_2r16x2c(
  __attribute__((opencl_global)) void *base_address, int width, int height, int pitch,
  cute::intel::coord_t coord);

SYCL_EXTERNAL
void intel_sub_group_2d_block_prefetch_16b_4r16x2c(
  __attribute__((opencl_global)) void *base_address, int width, int height, int pitch,
  cute::intel::coord_t coord);

SYCL_EXTERNAL
void intel_sub_group_2d_block_prefetch_32b_16r8x1c(
  __attribute__((opencl_global)) void *base_address, int width, int height, int pitch,
  cute::intel::coord_t coord);

// SPIRV copy definitions
SYCL_EXTERNAL __attribute__((convergent)) void __spirv_Subgroup2DBlockLoadINTEL(
  int ElementSize, int BlockWidth, int BlockHeight, int BlockCount,
  const void *src_base_pointer, int memory_width, int memory_height,
  int memory_pitch, cute::intel::coord_t coordinate, void *dst_pointer);

SYCL_EXTERNAL __attribute__((convergent)) void __spirv_Subgroup2DBlockLoadTransformINTEL(
  int ElementSize, int BlockWidth, int BlockHeight, int BlockCount,
  const void *src_base_pointer, int memory_width, int memory_height,
  int memory_pitch, cute::intel::coord_t coordinate, void *dst_pointer);

SYCL_EXTERNAL __attribute__((convergent)) void __spirv_Subgroup2DBlockLoadTransposeINTEL(
  int ElementSize, int BlockWidth, int BlockHeight, int BlockCount,
  const void *src_base_pointer, int memory_width, int memory_height,
  int memory_pitch, cute::intel::coord_t coordinate, void *dst_pointer);

SYCL_EXTERNAL __attribute__((convergent)) void __spirv_Subgroup2DBlockStoreINTEL(
  int ElementSize, int BlockWidth, int BlockHeight, int BlockCount,
  void *src_pointer, const void *dst_base_pointer, int memory_width,
  int memory_height, int memory_pitch, cute::intel::coord_t coordinate);

SYCL_EXTERNAL __attribute__((convergent)) void __spirv_Subgroup2DBlockPrefetchINTEL(
  int ElementSize, int BlockWidth, int BlockHeight, int BlockCount,
  const void *src_base_pointer, int memory_width, int memory_height,
  int memory_pitch, cute::intel::coord_t coordinate);

namespace cute::detail {
template<int ElementSize, int BlockWidth, int BlockHeight, int BlockCount>
struct XeSubgroup2DBlockLoad {
  template<typename T>
  CUTE_HOST_DEVICE
  void operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
                  cute::intel::coord_t coordinate, T *dstPointer) {
    __spirv_Subgroup2DBlockLoadINTEL(ElementSize, BlockWidth, BlockHeight, BlockCount,
                                     srcBasePointer, memoryWidth,
                                     memoryHeight, memoryPitch, coordinate,
                                     static_cast<void *>(dstPointer));
  }
};

template<int ElementSize, int BlockWidth, int BlockHeight, int BlockCount>
struct XeSubgroup2DBlockLoadTransform {
  template<typename T>
  CUTE_HOST_DEVICE
  void operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
                  cute::intel::coord_t coordinate, T *dstPointer) {
    __spirv_Subgroup2DBlockLoadTransformINTEL(ElementSize, BlockWidth, BlockHeight, BlockCount,
                                              srcBasePointer, memoryWidth,
                                              memoryHeight, memoryPitch, coordinate,
                                              static_cast<void *>(dstPointer));
  }
};

template<int ElementSize, int BlockWidth, int BlockHeight, int BlockCount>
struct XeSubgroup2DBlockLoadTranspose {
  template<typename T>
  CUTE_HOST_DEVICE
  void operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
                  cute::intel::coord_t coordinate, T *dstPointer) {
    __spirv_Subgroup2DBlockLoadTransposeINTEL(ElementSize, BlockWidth, BlockHeight, BlockCount,
                                              srcBasePointer, memoryWidth,
                                              memoryHeight, memoryPitch, coordinate,
                                              static_cast<void *>(dstPointer));
  }
};

template<int ElementSize, int BlockWidth, int BlockHeight, int BlockCount>
struct XeSubgroup2DBlockPrefetch {
  CUTE_HOST_DEVICE
  void operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
                  cute::intel::coord_t coordinate) {
    __spirv_Subgroup2DBlockPrefetchINTEL(ElementSize, BlockWidth, BlockHeight, BlockCount,
                                         srcBasePointer, memoryWidth,
                                         memoryHeight, memoryPitch, coordinate);
  }
};

template<int ElementSize, int BlockWidth, int BlockHeight, int BlockCount>
struct XeSubgroup2DBlockStore {
  template<typename T>
  CUTE_HOST_DEVICE
  void operator()(const void *dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
                  cute::intel::coord_t coordinate, T *srcPointer) {
    __spirv_Subgroup2DBlockStoreINTEL(ElementSize, BlockWidth, BlockHeight, BlockCount,
                                      (void *)(srcPointer), dstBasePointer,
                                      memoryWidth, memoryHeight,
                                      memoryPitch, coordinate);
  }
};

template<>
struct XeSubgroup2DBlockLoad<1, 16, 1, 1> {
  template<typename T>
  CUTE_HOST_DEVICE void
  operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
          cute::intel::coord_t coordinate, T* dstPointer) {
    *reinterpret_cast<intel::uchar *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m1k16v1(
       (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
  }
};

template<>
struct XeSubgroup2DBlockLoad<1, 16, 32, 2> {
  template<typename T>
  CUTE_HOST_DEVICE void
  operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
          cute::intel::coord_t coordinate, T* dstPointer) {
    *reinterpret_cast<intel::uchar64 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m32k16v2(
       (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
  }
};

template<>
struct XeSubgroup2DBlockLoadTranspose<4, 2, 16, 1> {
  template<typename T>
  CUTE_HOST_DEVICE
  void operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
                  cute::intel::coord_t coordinate, T *dstPointer) {
    *reinterpret_cast<intel::uint2 *>(dstPointer) = __builtin_IB_subgroup_block_read_flat_transpose_u32_k2(
      reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
  }
};

template<>
struct XeSubgroup2DBlockLoadTranspose<4, 4, 16, 1> {
  template<typename T>
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate, T *dstPointer) {
    *reinterpret_cast<intel::uint4 *>(dstPointer) = __builtin_IB_subgroup_block_read_flat_transpose_u32_k4(
      reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
  }
};


template<>
struct XeSubgroup2DBlockLoadTranspose<1, 4, 32, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort4 *>(dstPointer) =  __builtin_IB_subgroup_block_read_cacheopts_transpose_u8_m32k4(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTranspose<1, 8, 32, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_cacheopts_transpose_u8_m32k8(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

// TODO(Codeplay): Remove these Prefetch specializations once spirv prefetch performance bug is fixed.
template<>
struct XeSubgroup2DBlockPrefetch<1, 16, 1, 1> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u8_m1k16v1(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 1, 1> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u8_m1k32v1(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 2, 1> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u8_m2k32v1(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 4, 1> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u8_m4k32v1(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 8, 1> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u8_m8k32v1(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth, memoryHeight, memoryPitch, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 1, 2> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    intel_sub_group_2d_block_prefetch_8b_1r32x2c(
      (__attribute__((opencl_global)) void*)(srcBasePointer), memoryWidth, memoryHeight,
      memoryPitch, coordinate);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 2, 2> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    intel_sub_group_2d_block_prefetch_8b_2r32x2c(
      (__attribute__((opencl_global)) void *)(srcBasePointer), memoryWidth, memoryHeight,
      memoryPitch, coordinate);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 4, 2> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    intel_sub_group_2d_block_prefetch_8b_4r32x2c(
      (__attribute__((opencl_global)) void *)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch,
      coordinate);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 8, 2> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    intel_sub_group_2d_block_prefetch_8b_8r32x2c(
      (__attribute__((opencl_global)) void *)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch,
      coordinate);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 16, 32, 1> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    intel_sub_group_2d_block_prefetch_8b_32r16x1c(
      (__attribute__((opencl_global)) void *)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch,
      coordinate);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 32, 1> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u8_m32k32v1(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 8, 1> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v1(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 16, 1> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v1(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 32, 1> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v1(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 1, 2> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    intel_sub_group_2d_block_prefetch_16b_1r16x2c(
      (__attribute__((opencl_global)) void *)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch,
      coordinate);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 2, 2> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    intel_sub_group_2d_block_prefetch_16b_2r16x2c(
      (__attribute__((opencl_global)) void *)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch,
      coordinate);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 4, 2> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    intel_sub_group_2d_block_prefetch_16b_4r16x2c(
      (__attribute__((opencl_global)) void *)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch,
      coordinate);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 8, 2> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v2(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 16, 2> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v2(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 32, 2> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v2(
      reinterpret_cast<intptr_t>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate,
      CacheControl::kL1C_L3C);
  }
};

template<>
struct XeSubgroup2DBlockPrefetch<4, 8, 16, 1> {
  CUTE_HOST_DEVICE void
  operator()(const void *srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
             cute::intel::coord_t coordinate) {
    intel_sub_group_2d_block_prefetch_32b_16r8x1c(
      (__attribute__((opencl_global)) void *)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch,
      coordinate);
  }
};
} // namespace cute::detail end
