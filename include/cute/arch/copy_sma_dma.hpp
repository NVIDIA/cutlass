/***************************************************************************************************
 * Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
// #include <cute/arch/copy_sm90.hpp>
#include "cutlass/arch/synclog.hpp"

namespace cute
{

////////////////////////////////////////////////////////////////////////////////////////////////////
/// TMA_LOAD : Initiates a TMA copy from global memory to shared memory
////////////////////////////////////////////////////////////////////////////////////////////////////

struct SMA_DMA_LOAD_2D
{
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1)
  {
// #if defined(CUTE_ARCH_TMA_SM90_ENABLED)
//     uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
//     uint32_t smem_int_mbar = cast_smem_ptr_to_uint(mbar_ptr);
//     uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
//     cutlass::arch::synclog_emit_tma_load(__LINE__, gmem_int_desc, smem_int_mbar, smem_int_ptr);
//     asm volatile (
//       "cp.async.bulk.tensor.1d.shared::cluster.global.mbarrier::complete_tx::bytes.L2::cache_hint"
//       " [%0], [%1, {%3}], [%2], %4;"
//       :
//       : "r"(smem_int_ptr), "l"(gmem_int_desc), "r"(smem_int_mbar),
//         "r"(crd0), "l"(cache_hint)
//       : "memory");
// #else
//     CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM90_ENABLED.");
// #endif
  {
    uint y = threadIdx.y + blockIdx.y * blockDim.y;
    uint x = threadIdx.x + blockIdx.x * blockDim.x + gridDim.x * blockDim.x * y;
    if (x == 0)
    {
      printf("aurora load test\n");
    }
  }
      
  }

  // struct PREFETCH
  // {
  //   CUTE_HOST_DEVICE static void
  //   copy(void const* desc_ptr,
  //        int32_t const& crd0)
  //   {
  // #if defined(CUTE_ARCH_TMA_SM90_ENABLED)
  //     uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
  //     asm volatile (
  //       "cp.async.bulk.prefetch.tensor.1d.L2.global"
  //       " [%0, {%1}];"
  //       :
  //       : "l"(gmem_int_desc),
  //         "r"(crd0)
  //       : "memory");
  // #else
  //     CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM90_ENABLED.");
  // #endif
  //   }
  // };
};


struct SMA_DMA_LOAD
{
  CUTE_HOST_DEVICE static void
  copy(void const* desc_ptr, uint64_t* mbar_ptr, uint64_t cache_hint,
       void      * smem_ptr,
       int32_t const& crd0, int32_t const& crd1, int32_t const& crd2)
  {
    return SMA_DMA_LOAD_2D::copy(desc_ptr, mbar_ptr, cache_hint, smem_ptr, crd0, crd1);
  }
  
  // struct PREFETCH
  // {
  //   CUTE_HOST_DEVICE static void
  //   copy(void const* desc_ptr,
  //        int32_t const& crd0)
  //   {
  //     return SM90_TMA_LOAD_1D::PREFETCH::copy(desc_ptr, crd0);
  //   }
  // };
};

////////////////////////////////////////////////////////////////////////////////////////////////////
/// TMA_STORE : Initiates a TMA copy from shared memory to global memory
////////////////////////////////////////////////////////////////////////////////////////////////////

// struct SMA_DMA_STORE_2D
// {
//   CUTE_HOST_DEVICE static void
//   copy(void const* desc_ptr,
//        void const* smem_ptr,
//        int32_t const& crd0, int32_t const& crd1)
//   {
// #if defined(CUTE_ARCH_TMA_SM90_ENABLED)
//     uint64_t gmem_int_desc = reinterpret_cast<uint64_t>(desc_ptr);
//     uint32_t smem_int_ptr  = cast_smem_ptr_to_uint(smem_ptr);
//     cutlass::arch::synclog_emit_tma_store(__LINE__, gmem_int_desc, smem_int_ptr);
//     asm volatile (
//       "cp.async.bulk.tensor.1d.global.shared::cta.bulk_group [%0, {%2}], [%1];"
//       :
//       : "l"(gmem_int_desc), "r"(smem_int_ptr),
//         "r"(crd0)
//       : "memory");
// #else
//     CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM90_ENABLED.");
// #endif
//   }
// };


// struct SM90_TMA_STORE
// {
//   CUTE_HOST_DEVICE static void
//   copy(void const* desc_ptr,
//        void const* smem_ptr,
//        int32_t const& crd0)
//   {
//     return SM90_TMA_STORE_1D::copy(desc_ptr, smem_ptr, crd0);
//   }
// };


// // Fence for smem stores for subsequent TMA_STORE
// CUTE_HOST_DEVICE static void
// tma_store_fence() {
// #if defined(CUTE_ARCH_TMA_SM90_ENABLED)
//     cutlass::arch::synclog_emit_fence_view_async_shared(__LINE__);
//     asm volatile ("fence.proxy.async.shared::cta;");
// #elif defined(__CUDA_ARCH__)
//     CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM90_ENABLED.");
// #endif
// }

// // Indicate arrival of warp issuing TMA_STORE
// CUTE_HOST_DEVICE static void
// tma_store_arrive() {
// #if defined(CUTE_ARCH_TMA_SM90_ENABLED)
//     cutlass::arch::synclog_emit_tma_store_arrive(__LINE__);
//     asm volatile("cp.async.bulk.commit_group;");
// #else
//     CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM90_ENABLED.");
// #endif
// }


// CUTE_HOST_DEVICE static void
// tma_desc_commit_group() {
// #if defined(CUTE_ARCH_TMA_SM90_ENABLED)
//     asm volatile("cp.async.bulk.commit_group;");
// #else
//     CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM90_ENABLED.");
// #endif
// }


// // Wait until at most Count committed TMA_STOREs are pending and all prior commits are complete
// template <int Count>
// CUTE_HOST_DEVICE static void
// tma_store_wait() {
// #if defined(CUTE_ARCH_TMA_SM90_ENABLED)
//     asm volatile(
//       "cp.async.bulk.wait_group.read %0;"
//       :
//       : "n"(Count)
//       : "memory");
//     cutlass::arch::synclog_emit_tma_store_wait(__LINE__, Count);
// #else
//     CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM90_ENABLED.");
// #endif
// }


// // Wait until all TMA descriptor previously issued are safe to be modified after tma_desc_commit_group()
// CUTE_HOST_DEVICE static void
// tma_desc_wait_group() {
// #if defined(CUTE_ARCH_TMA_SM90_ENABLED)
//     asm volatile(
//       "cp.async.bulk.wait_group.read %0;"
//       :
//       : "n"(0)
//       : "memory");
// #else
//     CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM90_ENABLED.");
// #endif
// }

// for SM90 pipeline
// Fence for smem stores for subsequent TMA_STORE
CUTE_HOST_DEVICE static void
tma_store_fence() {
#if defined(CUTE_ARCH_TMA_SM90_ENABLED)
    cutlass::arch::synclog_emit_fence_view_async_shared(__LINE__);
    asm volatile ("fence.proxy.async.shared::cta;");
#elif defined(__CUDA_ARCH__)
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM90_ENABLED.");
#endif
}

// Indicate arrival of warp issuing TMA_STORE
CUTE_HOST_DEVICE static void
tma_store_arrive() {
#if defined(CUTE_ARCH_TMA_SM90_ENABLED)
    cutlass::arch::synclog_emit_tma_store_arrive(__LINE__);
    asm volatile("cp.async.bulk.commit_group;");
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM90_ENABLED.");
#endif
}

// Wait until at most Count committed TMA_STOREs are pending and all prior commits are complete
template <int Count>
CUTE_HOST_DEVICE static void
tma_store_wait() {
#if defined(CUTE_ARCH_TMA_SM90_ENABLED)
    asm volatile(
      "cp.async.bulk.wait_group.read %0;"
      :
      : "n"(Count)
      : "memory");
    cutlass::arch::synclog_emit_tma_store_wait(__LINE__, Count);
#else
    CUTE_INVALID_CONTROL_PATH("Trying to use tma without CUTE_ARCH_TMA_SM90_ENABLED.");
#endif
}


////////////////////////////////////////////////////////////////////////////////////////////////////

} // end namespace cute
