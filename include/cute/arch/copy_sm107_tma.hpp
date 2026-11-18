/***************************************************************************************************
 * Copyright (c) 2020 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include <cute/config.hpp>

#include <cute/arch/config.hpp> // CUTE_ARCH_TMA_SMxx_ENABLED
#include <cute/arch/copy.hpp>
#include <cute/arch/copy_sm90.hpp>
#include <cute/arch/copy_sm90_tma.hpp>
#include <cute/arch/copy_sm100_tma.hpp>    // Sm100MmaPeerBitMask
#include <cute/numeric/numeric_types.hpp>  // cute::half_t, bfloat16_t, float_e*_t
#include <cute/util/type_traits.hpp>       // cute::is_same_v
#include "cutlass/constants.h"             // cutlass::constants::negative_zero_bitpattern
#include "cutlass/arch/synclog.hpp"

namespace cute
{


namespace detail {

template <class T>
CUTE_HOST_DEVICE constexpr uint32_t get_sentinel_bitpattern()
{
  if constexpr (   cute::is_same_v<T, cute::half_t>
                || cute::is_same_v<T, cute::bfloat16_t>
                || cute::is_same_v<T, float>
                || cute::is_same_v<T, cute::float_e4m3_t>
                || cute::is_same_v<T, cute::float_e5m2_t>
                || cute::is_same_v<T, cute::float_e2m1_t>) {
    return cutlass::constants::negative_zero_bitpattern<T>;
  } else {
    return uint32_t{0};
  }
}

} // namespace detail

////////////////////////////////////////////////////////////////////////////////////////////////////
/// TMA_LOAD : Initiates a TMA copy from global memory to shared memory
////////////////////////////////////////////////////////////////////////////////////////////////////

template <class T>
struct SM107_TMA_LOAD_1D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr);
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.L2::cache_hint"
        " [%0], [%1, {%3}], [%2], %4;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.L2::cache_hint"
        " [%0], [%1, {%3}], [%2], %4;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.L2::cache_hint"
        " [%0], [%1, {%3}], [%2], %4;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.L2::cache_hint"
        " [%0], [%1, {%3}], [%2], %4;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.L2::cache_hint"
        " [%0], [%1, {%3}], [%2], %4;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_LOAD_2D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr);
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.L2::cache_hint"
        " [%0], [%1, {%3, %4}], [%2], %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.L2::cache_hint"
        " [%0], [%1, {%3, %4}], [%2], %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.L2::cache_hint"
        " [%0], [%1, {%3, %4}], [%2], %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.L2::cache_hint"
        " [%0], [%1, {%3, %4}], [%2], %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.L2::cache_hint"
        " [%0], [%1, {%3, %4}], [%2], %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_LOAD_3D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr);
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5}], [%2], %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5}], [%2], %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5}], [%2], %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5}], [%2], %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5}], [%2], %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_LOAD_4D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr);
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6}], [%2], %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6}], [%2], %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6}], [%2], %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6}], [%2], %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6}], [%2], %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_LOAD_5D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3, int32_t const& crd4)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr);
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.5d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6, %7}], [%2], %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.5d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6, %7}], [%2], %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.5d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6, %7}], [%2], %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.5d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6, %7}], [%2], %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.5d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6, %7}], [%2], %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T_>
struct SM107_TMA_LOAD
{
  using T = T_;

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0)
  {
    return SM107_TMA_LOAD_1D<T>::copy(desc_ptr, mbar_ptr, cache_hint, smem_ptr, crd0);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1)
  {
    return SM107_TMA_LOAD_2D<T>::copy(desc_ptr, mbar_ptr, cache_hint, smem_ptr, crd0, crd1);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2)
  {
    return SM107_TMA_LOAD_3D<T>::copy(desc_ptr, mbar_ptr, cache_hint, smem_ptr, crd0, crd1, crd2);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3)
  {
    return SM107_TMA_LOAD_4D<T>::copy(desc_ptr, mbar_ptr, cache_hint, smem_ptr, crd0, crd1, crd2, crd3);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3, int32_t const& crd4)
  {
    return SM107_TMA_LOAD_5D<T>::copy(desc_ptr, mbar_ptr, cache_hint, smem_ptr, crd0, crd1, crd2, crd3, crd4);
  }
};

////////////////////////////////////////////////////////////////////////////////////////////////////
/// TMA_LOAD_MULTICAST: Initiates a TMA copy from global memory to shared memory
////////////////////////////////////////////////////////////////////////////////////////////////////

template <class T>
struct SM107_TMA_LOAD_MULTICAST_1D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr);
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4}], [%2], %3, %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4}], [%2], %3, %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4}], [%2], %3, %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4}], [%2], %3, %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4}], [%2], %3, %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_LOAD_MULTICAST_2D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr);
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5}], [%2], %3, %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5}], [%2], %3, %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5}], [%2], %3, %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5}], [%2], %3, %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.2d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5}], [%2], %3, %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_LOAD_MULTICAST_3D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr);
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6}], [%2], %3, %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6}], [%2], %3, %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6}], [%2], %3, %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6}], [%2], %3, %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.3d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6}], [%2], %3, %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_LOAD_MULTICAST_4D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr);
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7}], [%2], %3, %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2),  "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7}], [%2], %3, %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2),  "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7}], [%2], %3, %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2),  "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7}], [%2], %3, %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2),  "r"(crd3), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.4d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7}], [%2], %3, %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2),  "r"(crd3), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_LOAD_MULTICAST_5D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3, int32_t const& crd4)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr);
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.5d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7, %8}], [%2], %3, %9;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.5d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7, %8}], [%2], %3, %9;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.5d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7, %8}], [%2], %3, %9;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.5d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7, %8}], [%2], %3, %9;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.5d.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7, %8}], [%2], %3, %9;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T_>
struct SM107_TMA_LOAD_MULTICAST
{
  using T = T_;

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0)
  {
    return SM107_TMA_LOAD_MULTICAST_1D<T>::copy(desc_ptr, mbar_ptr, multicast_mask, cache_hint, smem_ptr, crd0);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1)
  {
    return SM107_TMA_LOAD_MULTICAST_2D<T>::copy(desc_ptr, mbar_ptr, multicast_mask, cache_hint, smem_ptr, crd0, crd1);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2)
  {
    return SM107_TMA_LOAD_MULTICAST_3D<T>::copy(desc_ptr, mbar_ptr, multicast_mask, cache_hint, smem_ptr, crd0, crd1, crd2);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3)
  {
    return SM107_TMA_LOAD_MULTICAST_4D<T>::copy(desc_ptr, mbar_ptr, multicast_mask, cache_hint, smem_ptr, crd0, crd1, crd2, crd3);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3, int32_t const& crd4)
  {
    return SM107_TMA_LOAD_MULTICAST_5D<T>::copy(desc_ptr, mbar_ptr, multicast_mask, cache_hint, smem_ptr, crd0, crd1, crd2, crd3, crd4);
  }
};


////////////////////////////////////////////////////////////////////////////////////////////////////
/// TMA_LOAD (2SM) : Initiates a TMA copy from global memory to shared memory
////////////////////////////////////////////////////////////////////////////////////////////////////

template <class T>
struct SM107_TMA_2SM_LOAD_1D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy([[maybe_unused]] void const* desc_ptr, [[maybe_unused]] uint64_t* mbar_ptr, [[maybe_unused]] uint64_t cache_hint,
       [[maybe_unused]] void      * smem_ptr,
       [[maybe_unused]] int32_t const& crd0)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    // Executed by both CTAs. Set peer bit to 0 so that the
    // transaction bytes will update CTA0's barrier.
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr) & Sm100MmaPeerBitMask;
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.1d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.L2::cache_hint"
        " [%0], [%1, {%3}], [%2], %4;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.1d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.L2::cache_hint"
        " [%0], [%1, {%3}], [%2], %4;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.1d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.L2::cache_hint"
        " [%0], [%1, {%3}], [%2], %4;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.1d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.L2::cache_hint"
        " [%0], [%1, {%3}], [%2], %4;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.1d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.L2::cache_hint"
        " [%0], [%1, {%3}], [%2], %4;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_2SM_LOAD_2D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy([[maybe_unused]] void const* desc_ptr, [[maybe_unused]] uint64_t* mbar_ptr, [[maybe_unused]] uint64_t cache_hint,
       [[maybe_unused]] void      * smem_ptr,
       [[maybe_unused]] int32_t const& crd0, int32_t const& crd1)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    // Executed by both CTAs. Set peer bit to 0 so that the
    // transaction bytes will update CTA0's barrier.
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr) & Sm100MmaPeerBitMask;
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.2d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.L2::cache_hint"
        " [%0], [%1, {%3, %4}], [%2], %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.2d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.L2::cache_hint"
        " [%0], [%1, {%3, %4}], [%2], %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.2d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.L2::cache_hint"
        " [%0], [%1, {%3, %4}], [%2], %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.2d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.L2::cache_hint"
        " [%0], [%1, {%3, %4}], [%2], %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.2d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.L2::cache_hint"
        " [%0], [%1, {%3, %4}], [%2], %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_2SM_LOAD_3D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy([[maybe_unused]] void const* desc_ptr, [[maybe_unused]] uint64_t* mbar_ptr, [[maybe_unused]] uint64_t cache_hint,
       [[maybe_unused]] void      * smem_ptr,
       [[maybe_unused]] int32_t const& crd0, int32_t const& crd1, int32_t const& crd2)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    // Executed by both CTAs. Set peer bit to 0 so that the
    // transaction bytes will update CTA0's barrier.
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr) & Sm100MmaPeerBitMask;
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.3d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5}], [%2], %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.3d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5}], [%2], %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.3d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5}], [%2], %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.3d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5}], [%2], %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.3d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5}], [%2], %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_2SM_LOAD_4D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    // Executed by both CTAs. Set peer bit to 0 so that the
    // transaction bytes will update CTA0's barrier.
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr) & Sm100MmaPeerBitMask;
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.4d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6}], [%2], %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.4d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6}], [%2], %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.4d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6}], [%2], %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.4d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6}], [%2], %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.4d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6}], [%2], %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_2SM_LOAD_5D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3, int32_t const& crd4)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    // Executed by both CTAs. Set peer bit to 0 so that the
    // transaction bytes will update CTA0's barrier.
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr) & Sm100MmaPeerBitMask;
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.5d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6, %7}], [%2], %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.5d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6, %7}], [%2], %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.5d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6, %7}], [%2], %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.5d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6, %7}], [%2], %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.5d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.L2::cache_hint"
        " [%0], [%1, {%3, %4, %5, %6, %7}], [%2], %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T_>
struct SM107_TMA_2SM_LOAD
{
  using T = T_; // used in unit tests

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0)
  {
    return SM107_TMA_2SM_LOAD_1D<T>::copy(desc_ptr, mbar_ptr, cache_hint, smem_ptr, crd0);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1)
  {
    return SM107_TMA_2SM_LOAD_2D<T>::copy(desc_ptr, mbar_ptr, cache_hint, smem_ptr, crd0, crd1);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2)
  {
    return SM107_TMA_2SM_LOAD_3D<T>::copy(desc_ptr, mbar_ptr, cache_hint, smem_ptr, crd0, crd1, crd2);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3)
  {
    return SM107_TMA_2SM_LOAD_4D<T>::copy(desc_ptr, mbar_ptr, cache_hint, smem_ptr, crd0, crd1, crd2, crd3);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3, int32_t const& crd4)
  {
    return SM107_TMA_2SM_LOAD_5D<T>::copy(desc_ptr, mbar_ptr, cache_hint, smem_ptr, crd0, crd1, crd2, crd3, crd4);
  }
};

////////////////////////////////////////////////////////////////////////////////////////////////////
/// TMA_LOAD_MULTICAST (2SM): Initiates a TMA copy from global memory to shared memory
////////////////////////////////////////////////////////////////////////////////////////////////////

template <class T>
struct SM107_TMA_2SM_LOAD_MULTICAST_1D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    // Executed by both CTAs. Set peer bit to 0 so that the
    // transaction bytes will update CTA0's barrier.
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr) & Sm100MmaPeerBitMask;
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.1d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4}], [%2], %3, %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.1d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4}], [%2], %3, %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.1d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4}], [%2], %3, %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.1d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4}], [%2], %3, %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.1d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4}], [%2], %3, %5;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_2SM_LOAD_MULTICAST_2D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    // Executed by both CTAs. Set peer bit to 0 so that the
    // transaction bytes will update CTA0's barrier.
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr) & Sm100MmaPeerBitMask;
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.2d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5}], [%2], %3, %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.2d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5}], [%2], %3, %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.2d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5}], [%2], %3, %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.2d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5}], [%2], %3, %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.2d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5}], [%2], %3, %6;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_2SM_LOAD_MULTICAST_3D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    // Executed by both CTAs. Set peer bit to 0 so that the
    // transaction bytes will update CTA0's barrier.
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr) & Sm100MmaPeerBitMask;
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.3d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6}], [%2], %3, %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.3d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6}], [%2], %3, %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.3d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6}], [%2], %3, %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.3d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6}], [%2], %3, %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.3d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6}], [%2], %3, %7;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_2SM_LOAD_MULTICAST_4D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    // Executed by both CTAs. Set peer bit to 0 so that the
    // transaction bytes will update CTA0's barrier.
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr) & Sm100MmaPeerBitMask;
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.4d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7}], [%2], %3, %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.4d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7}], [%2], %3, %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.4d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7}], [%2], %3, %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.4d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7}], [%2], %3, %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.4d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7}], [%2], %3, %8;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T>
struct SM107_TMA_2SM_LOAD_MULTICAST_5D
{
  // Per-element validity-report mask; 0 (disabled) for void / unsupported element types.
  static constexpr uint32_t SentinelBitPattern = cute::detail::get_sentinel_bitpattern<T>();

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3, int32_t const& crd4)
  {
#if defined(CUTE_ARCH_TMA_SM107_ENABLED)
    uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
    // Executed by both CTAs. Set peer bit to 0 so that the
    // transaction bytes will update CTA0's barrier.
    uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr) & Sm100MmaPeerBitMask;
    uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
    cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
    if constexpr (SentinelBitPattern == 0x80000000) {
      asm volatile (
        "cp.async.bulk.tensor.5d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80000000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7, %8}], [%2], %3, %9;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8000) {
      asm volatile (
        "cp.async.bulk.tensor.5d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8000.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7, %8}], [%2], %3, %9;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x80) {
      asm volatile (
        "cp.async.bulk.tensor.5d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::80.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7, %8}], [%2], %3, %9;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else if constexpr (SentinelBitPattern == 0x8) {
      asm volatile (
        "cp.async.bulk.tensor.5d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::validity::per_16bytes::8.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7, %8}], [%2], %3, %9;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    } else {
      // T == void --> disable validity reporting
      asm volatile (
        "cp.async.bulk.tensor.5d.cta_group::2.shared::cluster.global.mbarrier::complete_tx::bytes.mbarrier::report::disabled.multicast::cluster.L2::cache_hint"
        " [%0], [%1, {%4, %5, %6, %7, %8}], [%2], %3, %9;"
        :
        : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar), "h"(multicast_mask),
          "r"(crd0), "r"(crd1), "r"(crd2), "r"(crd3), "r"(crd4), "l"(cache_hint)
        : "memory");
    }
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM107_ENABLED.");
#endif
  }
};

template <class T_>
struct SM107_TMA_2SM_LOAD_MULTICAST
{
  using T = T_; // used in unit tests

  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0)
  {
    return SM107_TMA_2SM_LOAD_MULTICAST_1D<T>::copy(desc_ptr, mbar_ptr, multicast_mask, cache_hint, smem_ptr, crd0);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1)
  {
    return SM107_TMA_2SM_LOAD_MULTICAST_2D<T>::copy(desc_ptr, mbar_ptr, multicast_mask, cache_hint, smem_ptr, crd0, crd1);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2)
  {
    return SM107_TMA_2SM_LOAD_MULTICAST_3D<T>::copy(desc_ptr, mbar_ptr, multicast_mask, cache_hint, smem_ptr, crd0, crd1, crd2);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3)
  {
    return SM107_TMA_2SM_LOAD_MULTICAST_4D<T>::copy(desc_ptr, mbar_ptr, multicast_mask, cache_hint, smem_ptr, crd0, crd1, crd2, crd3);
  }
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint16_t multicast_mask, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2, int32_t const& crd3, int32_t const& crd4)
  {
    return SM107_TMA_2SM_LOAD_MULTICAST_5D<T>::copy(desc_ptr, mbar_ptr, multicast_mask, cache_hint, smem_ptr, crd0, crd1, crd2, crd3, crd4);
  }
};



} // end namespace cute
