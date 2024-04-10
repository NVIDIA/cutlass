#pragma once

#include <cute/config.hpp>
#include <cute/arch/copy.hpp>
#include <cute/util/sycl_vec.hpp>

#ifdef __SYCL_DEVICE_ONLY__
#define SYCL_DEVICE_BUILTIN(x) SYCL_EXTERNAL extern "C" x
#else
#define SYCL_DEVICE_BUILTIN(x) \
    inline x { assert(false); }
#endif

SYCL_DEVICE_BUILTIN(void __builtin_IB_subgroup_block_write_flat_u32_m8k16v1(long baseoffset, int width_minus_one, int height_minus_one, int pitch_minus_one, int2_ coord, uint8 data));
SYCL_DEVICE_BUILTIN(ushort8 __builtin_IB_subgroup_block_read_flat_u16_m8k16v1(long baseoffset, int width_minus_one, int height_minus_one, int pitch_minus_one, int2_ coord));
SYCL_DEVICE_BUILTIN(uint8 __builtin_IB_subgroup_block_read_flat_u32_m8k16v1(long baseoffset, int width_minus_one, int height_minus_one, int pitch_minus_one, int2_ coord));
#undef SYCL_DEVICE_BUILTIN

struct XE_2D_LOAD //m8k16
{
    template<class T>
    CUTE_HOST_DEVICE static void copy(const void* baseoffset, int width, int height, int pitch, int2_ coord, T* dst)
    {
        if constexpr(sizeof(T)==sizeof(ushort)) {
            *(ushort8*)dst = __builtin_IB_subgroup_block_read_flat_u16_m8k16v1((long)baseoffset, width - 1, height - 1, pitch - 1, coord);    
        } else if constexpr(sizeof(T)==sizeof(uint)) {
            *(uint8*)dst = __builtin_IB_subgroup_block_read_flat_u32_m8k16v1((long)baseoffset, width - 1, height - 1, pitch - 1, coord);
        } else {
            static_assert(false);
        }
    }
};

struct XE_2D_SAVE //m8k16
{
    template<class T>
    CUTE_HOST_DEVICE static void copy(void* baseoffset, int width, int height, int pitch, int2_ coord, const T* src)
    {
        if constexpr(sizeof(T)==sizeof(uint)) {
            __builtin_IB_subgroup_block_write_flat_u32_m8k16v1((long)baseoffset, width - 1, height - 1, pitch - 1, coord, *(uint8*)src);
        } else {
            static_assert(false);
        }
    }
};
