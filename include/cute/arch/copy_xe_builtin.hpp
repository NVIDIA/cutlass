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


#undef __global
#define __global __attribute__((opencl_global))


#if defined(__SYCL_DEVICE_ONLY__) && defined(SYCL_INTEL_TARGET)
#define CUTE_ARCH_XE_COPY_ENABLED
#endif

namespace cute::detail
{
template<int ElementSize, int BlockWidth, int BlockHeight, int BlockCount>
struct XeSubgroup2DBlockPrefetch {
  static_assert(dependent_false<>, "Unsupported 2D Block Load Configuration.");
};
template<int ElementSize, int BlockWidth, int BlockHeight, int BlockCount>
struct XeSubgroup2DBlockLoad {
  static_assert(dependent_false<>, "Unsupported 2D Block Load Configuration.");
};
template<int ElementSize, int BlockWidth, int BlockHeight, int BlockCount>
struct XeSubgroup2DBlockLoadTransform {
  static_assert(dependent_false<>, "Unsupported 2D Block Load Configuration.");
};
template<int ElementSize, int BlockWidth, int BlockHeight, int BlockCount>
struct XeSubgroup2DBlockLoadTranspose {
  static_assert(dependent_false<>, "Unsupported 2D Block Load Configuration.");
};
template<int ElementSize, int BlockWidth, int BlockHeight, int BlockCount>
struct XeSubgroup2DBlockStore {
  static_assert(dependent_false<>, "Unsupported 2D Block Load Configuration.");
};
}

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

// 8bits No transform No transpose
SYCL_DEVICE_BUILTIN(
    cute::intel::uchar __builtin_IB_subgroup_block_read_flat_u8_m1k16v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort __builtin_IB_subgroup_block_read_flat_u8_m1k32v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort2 __builtin_IB_subgroup_block_read_flat_u8_m2k32v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort4 __builtin_IB_subgroup_block_read_flat_u8_m4k32v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort8 __builtin_IB_subgroup_block_read_flat_u8_m8k32v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort16 __builtin_IB_subgroup_block_read_flat_u8_m16k32v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort32 __builtin_IB_subgroup_block_read_flat_u8_m32k32v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

SYCL_DEVICE_BUILTIN(
    cute::intel::ushort __builtin_IB_subgroup_block_read_flat_u8_m1k16v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort2 __builtin_IB_subgroup_block_read_flat_u8_m1k32v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort4 __builtin_IB_subgroup_block_read_flat_u8_m2k32v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort8 __builtin_IB_subgroup_block_read_flat_u8_m4k32v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort16 __builtin_IB_subgroup_block_read_flat_u8_m8k32v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort32 __builtin_IB_subgroup_block_read_flat_u8_m16k32v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort64 __builtin_IB_subgroup_block_read_flat_u8_m32k32v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uchar64 __builtin_IB_subgroup_block_read_flat_u8_m32k16v2(
        long baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

// 8bits VNNI transform No transpose
SYCL_DEVICE_BUILTIN(
    cute::intel::uint8 __builtin_IB_subgroup_block_read_flat_transform_u8_k32(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint16 __builtin_IB_subgroup_block_read_flat_transform_u8_k32v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint32 __builtin_IB_subgroup_block_read_flat_transform_u8_k32v4(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

// 8bits No transform Transpose
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort4  __builtin_IB_subgroup_block_read_cacheopts_transpose_u8_m32k4(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord, int cacheOpt = 0));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort8  __builtin_IB_subgroup_block_read_cacheopts_transpose_u8_m32k8(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord, int cacheOpt = 0));

// 8bits No transform No transpose
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u8_m1k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uchar data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u8_m2k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uchar2 data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u8_m4k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uchar4));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u8_m8k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uchar8));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u8_m8k16v2(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uchar8));

SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u8_m1k16v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));
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
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u8_m32k32v1(
    long baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));

// // 2D prefetch
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

SYCL_DEVICE_BUILTIN(cute::intel::ushort16 intel_subgroup_block_read_u16_m8k16v2(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord));

SYCL_DEVICE_BUILTIN(cute::intel::int8 intel_subgroup_block_read_transform_u16_k16(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord));

// U16 prefetch
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v2(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v2(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v2(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, enum CacheControl cache_control));

// 16 bits No transform No transpose
SYCL_DEVICE_BUILTIN(cute::intel::ushort __builtin_IB_subgroup_block_read_flat_u16_m1k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort2 __builtin_IB_subgroup_block_read_flat_u16_m2k16v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort4 __builtin_IB_subgroup_block_read_flat_u16_m4k16v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort8 __builtin_IB_subgroup_block_read_flat_u16_m8k16v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort16 __builtin_IB_subgroup_block_read_flat_u16_m16k16v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort32 __builtin_IB_subgroup_block_read_flat_u16_m32k16v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

SYCL_DEVICE_BUILTIN(
    cute::intel::ushort2 __builtin_IB_subgroup_block_read_flat_u16_m1k16v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort4 __builtin_IB_subgroup_block_read_flat_u16_m2k16v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort8 __builtin_IB_subgroup_block_read_flat_u16_m4k16v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort16 __builtin_IB_subgroup_block_read_flat_u16_m8k16v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort32 __builtin_IB_subgroup_block_read_flat_u16_m16k16v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort64 __builtin_IB_subgroup_block_read_flat_u16_m32k16v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

// 16bits VNNI transform No transpose
SYCL_DEVICE_BUILTIN(
    cute::intel::uint8 __builtin_IB_subgroup_block_read_flat_transform_u16_k16(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint16 __builtin_IB_subgroup_block_read_flat_transform_u16_k32(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint16 __builtin_IB_subgroup_block_read_flat_transform_u16_k16v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint32 __builtin_IB_subgroup_block_read_flat_transform_u16_k32v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

// 16bits
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u16_m1k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::ushort data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u16_m2k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::ushort2 data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u16_m4k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::ushort4 data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u16_m8k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::ushort8 data));

// 2D prefetch
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_16b_1r16x2c(
    __global void* base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_16b_2r16x2c(
    __global void* base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));
SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_16b_4r16x2c(
    __global void* base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));


// 32bits specific for tf32 No transform No transpose
SYCL_DEVICE_BUILTIN(
    cute::intel::uint __builtin_IB_subgroup_block_read_flat_u32_m1k8v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint __builtin_IB_subgroup_block_read_flat_u32_m2k8v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint2 __builtin_IB_subgroup_block_read_flat_u32_m4k8v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint4 __builtin_IB_subgroup_block_read_flat_u32_m8k8v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint8 __builtin_IB_subgroup_block_read_flat_u32_m16k8v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint16 __builtin_IB_subgroup_block_read_flat_u32_m32k8v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

SYCL_DEVICE_BUILTIN(
    cute::intel::uint2 __builtin_IB_subgroup_block_read_flat_u32_m1k8v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint2 __builtin_IB_subgroup_block_read_flat_u32_m2k8v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint4 __builtin_IB_subgroup_block_read_flat_u32_m4k8v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint8 __builtin_IB_subgroup_block_read_flat_u32_m8k8v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint16 __builtin_IB_subgroup_block_read_flat_u32_m16k8v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint32 __builtin_IB_subgroup_block_read_flat_u32_m32k8v2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

// 32bits No transform No transpose
SYCL_DEVICE_BUILTIN(cute::intel::uint __builtin_IB_subgroup_block_read_flat_u32_m1k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint2 __builtin_IB_subgroup_block_read_flat_u32_m2k16v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint4 __builtin_IB_subgroup_block_read_flat_u32_m4k16v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint8 __builtin_IB_subgroup_block_read_flat_u32_m8k16v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint16 __builtin_IB_subgroup_block_read_flat_u32_m16k16v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint32 __builtin_IB_subgroup_block_read_flat_u32_m32k16v1(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));

// 32bits No transform Transpose
SYCL_DEVICE_BUILTIN(cute::intel::uint __builtin_IB_subgroup_block_read_flat_transpose_u32_k1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint2 __builtin_IB_subgroup_block_read_flat_transpose_u32_k2(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint4 __builtin_IB_subgroup_block_read_flat_transpose_u32_k4(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::uint8 __builtin_IB_subgroup_block_read_flat_transpose_u32_k8(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord));
SYCL_DEVICE_BUILTIN(
    cute::intel::ushort8 __builtin_IB_subgroup_block_read_cacheopts_transpose_u32_m8k8(
        intptr_t baseoffset, int width_minus_one, int height_minus_one,
        int pitch_minus_one, cute::intel::coord_t coord, int cacheOpt = 0));

// 32bits
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u32_m1k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uint data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u32_m2k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uint2 data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u32_m4k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uint4 data));
SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u32_m8k16v1(
    intptr_t baseoffset, int width_minus_one, int height_minus_one,
    int pitch_minus_one, cute::intel::coord_t coord, cute::intel::uint8 data));

SYCL_DEVICE_OCL(void intel_sub_group_2d_block_prefetch_32b_16r8x1c(
    __global void* base_address, int width, int height, int pitch,
    cute::intel::coord_t coord));

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

namespace cute::detail
{
template<>
struct XeSubgroup2DBlockLoad<1, 16, 1, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<cute::intel::uchar *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m1k16v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 32, 1, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<ushort *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m1k32v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 16, 1, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<cute::intel::ushort *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m1k16v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 32, 2, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort2 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m2k32v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 32, 4, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort4 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m4k32v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 32, 8, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m8k32v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 32, 16, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort16 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m16k32v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 32, 32, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort32 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m32k32v1(
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
struct XeSubgroup2DBlockLoad<1, 32, 1, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort2 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m1k32v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 32, 2, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort4 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m2k32v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 32, 4, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m4k32v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 32, 8, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort16 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m8k32v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 32, 16, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort32 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m16k32v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<1, 32, 32, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort64 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u8_m32k32v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTransform<1, 16, 32, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transform_u8_k32(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTransform<1, 16, 32, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint16 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transform_u8_k32v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTransform<1, 16, 32, 4> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint32 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transform_u8_k32v4(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
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

template<>
struct XeSubgroup2DBlockStore<1, 16, 1, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u8_m1k16v1(
           (intptr_t)(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(intel::uchar *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockStore<1, 16, 2, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u8_m2k16v1(
           (intptr_t)(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(intel::uchar2 *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockStore<1, 16, 4, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u8_m4k16v1(
           (intptr_t)(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(intel::uchar4 *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockStore<1, 16, 8, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u8_m8k16v1(
           (intptr_t)(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(intel::uchar8 *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockStore<1, 16, 8, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u8_m8k16v2(
           (intptr_t)(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(intel::uchar8 *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 16, 1, 1> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u8_m1k16v1(
            (intptr_t)srcBasePointer, memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, CacheControl::kL1C_L3C);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 1, 1> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u8_m1k32v1(
            (intptr_t)srcBasePointer, memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, CacheControl::kL1C_L3C);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 2, 1> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u8_m2k32v1(
            (intptr_t)srcBasePointer, memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, CacheControl::kL1C_L3C);
    }
};
template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 4, 1> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u8_m4k32v1(
            (intptr_t)srcBasePointer, memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, CacheControl::kL1C_L3C);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 8, 1> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u8_m8k32v1(
            (intptr_t)srcBasePointer, memoryWidth, memoryHeight, memoryPitch, coordinate, CacheControl::kL1C_L3C);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 32, 1> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u8_m32k32v1(
            (intptr_t)srcBasePointer, memoryWidth, memoryHeight, memoryPitch, coordinate, CacheControl::kL1C_L3C);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 1, 2> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        intel_sub_group_2d_block_prefetch_8b_1r32x2c(
            (__global void*)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 2, 2> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        intel_sub_group_2d_block_prefetch_8b_2r32x2c(
            (__global void*)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 4, 2> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        intel_sub_group_2d_block_prefetch_8b_4r32x2c(
            (__global void*)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 32, 8, 2> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        intel_sub_group_2d_block_prefetch_8b_8r32x2c(
            (__global void*)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<1, 16, 32, 1> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        intel_sub_group_2d_block_prefetch_8b_32r16x1c(
            (__global void*)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<2, 16, 1, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<ushort *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m1k16v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<2, 16, 2, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort2 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m2k16v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};


template<>
struct XeSubgroup2DBlockLoad<2, 16, 4, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort4 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m4k16v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<2, 16, 8, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m8k16v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<2, 16, 16, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort16 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m16k16v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<2, 16, 32, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort32 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m32k16v1(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<2, 16, 1, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort2 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m1k16v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<2, 16, 2, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort4 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m2k16v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<2, 16, 4, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m4k16v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<2, 16, 8, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort16 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m8k16v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<2, 16, 16, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort32 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m16k16v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<2, 16, 32, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort64 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u16_m32k16v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTransform<2, 16, 16, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transform_u16_k16(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTransform<2, 16, 32, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint16 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transform_u16_k32(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTransform<2, 16, 16, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint16 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transform_u16_k16v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTransform<2, 16, 32, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint32 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transform_u16_k32v2(
           (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockStore<2, 16, 1, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u16_m1k16v1(
           (intptr_t)(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(ushort *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockStore<2, 16, 2, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u16_m2k16v1(
           (intptr_t)(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(intel::ushort2 *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockStore<2, 16, 4, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u16_m4k16v1(
           (intptr_t)(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(intel::ushort4 *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockStore<2, 16, 8, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u16_m8k16v1(
           (intptr_t)(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(intel::ushort8 *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 8, 1> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v1(
            (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, CacheControl::kL1C_L3C);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 16, 1> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v1(
            (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, CacheControl::kL1C_L3C);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 32, 1> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v1(
            (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, CacheControl::kL1C_L3C);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 1, 2> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        intel_sub_group_2d_block_prefetch_16b_1r16x2c(
            (__global void*)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 2, 2> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        intel_sub_group_2d_block_prefetch_16b_2r16x2c(
            (__global void*)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 4, 2> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        intel_sub_group_2d_block_prefetch_16b_4r16x2c(
            (__global void*)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 8, 2> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u16_m8k16v2(
            (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, CacheControl::kL1C_L3C);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 16, 2> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u16_m16k16v2(
            (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, CacheControl::kL1C_L3C);
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<2, 16, 32, 2> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        __builtin_IB_subgroup_block_read_prefetch_u16_m32k16v2(
            (intptr_t)(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, CacheControl::kL1C_L3C);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 16, 1, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<uint *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m1k16v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 16, 2, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint2 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m2k16v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 16, 4, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint4 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m4k16v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 16, 8, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m8k16v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 16, 16, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint16 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m16k16v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 16, 32, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint32 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m32k16v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 1, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<uint *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m1k8v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 2, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<uint *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m2k8v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 4, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint2 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m4k8v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 8, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint4 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m8k8v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 16, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m16k8v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 32, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint16 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m32k8v1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 1, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint2 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m1k8v2(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 2, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint2 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m2k8v2(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 4, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint4 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m4k8v2(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 8, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m8k8v2(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 16, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint16 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m16k8v2(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoad<4, 8, 32, 2> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint32 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_u32_m32k8v2(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTranspose<4, 1, 16, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<uint *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transpose_u32_k1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTranspose<4, 2, 16, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint2 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transpose_u32_k2(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTranspose<4, 4, 16, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint4 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transpose_u32_k4(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTranspose<4, 8, 16, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::uint8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transpose_u32_k8(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTranspose<4, 8, 8, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ushort8 *>(dstPointer) =  __builtin_IB_subgroup_block_read_cacheopts_transpose_u32_m8k8(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockStore<4, 16, 1, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u32_m1k16v1(
           reinterpret_cast<long>(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(uint *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockStore<4, 16, 2, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u32_m2k16v1(
           reinterpret_cast<long>(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(intel::uint2 *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockStore<4, 16, 4, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u32_m4k16v1(
           reinterpret_cast<long>(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(intel::uint4 *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockStore<4, 16, 8, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* dstBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* srcPointer) {
        __builtin_IB_subgroup_block_write_flat_u32_m8k16v1(
           reinterpret_cast<long>(dstBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate, *(intel::uint8 *)(srcPointer));
    }
};

template<>
struct XeSubgroup2DBlockPrefetch<4, 8, 16, 1> {
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate) {
        intel_sub_group_2d_block_prefetch_32b_16r8x1c(
            (__global void*)(srcBasePointer), memoryWidth, memoryHeight, memoryPitch, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTranspose<8, 1, 8, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ulong *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transpose_u64_k1(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTranspose<8, 2, 8, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ulong2 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transpose_u64_k2(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

template<>
struct XeSubgroup2DBlockLoadTranspose<8, 4, 8, 1> {
    template<typename T>
    CUTE_HOST_DEVICE void 
    operator()(const void* srcBasePointer, int memoryWidth, int memoryHeight, int memoryPitch,
            cute::intel::coord_t coordinate, T* dstPointer) {
        *reinterpret_cast<intel::ulong4 *>(dstPointer) =  __builtin_IB_subgroup_block_read_flat_transpose_u64_k4(
           reinterpret_cast<long>(srcBasePointer), memoryWidth - 1, memoryHeight - 1, memoryPitch - 1, coordinate);
    }
};

} // namespace cute::detail
