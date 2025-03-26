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

#include <cute/config.hpp>                 // CUTE_HOST_DEVICE

#include "cutlass/arch/synclog.hpp"

// Config
#if (defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 900) && defined(__CUDA_ARCH_FEAT_SM90_ALL))
#  define CUTE_ARCH_MMA_SM90A_ENABLED
#endif

namespace cute {

////////////////////////////////////////////////////////////////////////////////////////////////////
// Warpgroup sync primitives
//shouldn't be annotated

// CUTE_HOST_DEVICE
// void
// warpgroup_arrive()
// {
// #if defined(CUTE_ARCH_MMA_SM90A_ENABLED)
//   cutlass::arch::synclog_emit_warpgroup_arrive(__LINE__);
//   asm volatile ("wgmma.fence.sync.aligned;\n" ::: "memory");
// #else
//   CUTE_INVALID_CONTROL_PATH("Attempting to use wgmma.fence without CUTE_ARCH_MMA_SM90A_ENABLED");
// #endif
// }

// template <int N>
// CUTE_HOST_DEVICE
// void
// warpgroup_wait()
// {
//   static_assert(N >= 0 && N <= 7, "WGMMA wait: N must be in range [0, 7]");
// #if defined(CUTE_ARCH_MMA_SM90A_ENABLED)
//   cutlass::arch::synclog_emit_warpgroup_wait(__LINE__, N);
//   asm volatile("wgmma.wait_group.sync.aligned %0;\n" :: "n"(N) : "memory");
// #else
//   CUTE_INVALID_CONTROL_PATH("Attempting to use wgmma.wait_group<N> without CUTE_ARCH_MMA_SM90A_ENABLED");
// #endif
// }

// // Marks the commit point for one or more sized batch of warpgroup MMAs.
// CUTE_HOST_DEVICE
// void
// warpgroup_commit_batch()
// {
// #if defined(CUTE_ARCH_MMA_SM90A_ENABLED)
//   cutlass::arch::synclog_emit_warpgroup_commit_batch(__LINE__);
//   asm volatile("wgmma.commit_group.sync.aligned;\n" ::: "memory");
// #else
//   CUTE_INVALID_CONTROL_PATH("Attempting to use wgmma.commit_group without CUTE_ARCH_MMA_SM90A_ENABLED");
// #endif
// }

// CUTE_HOST_DEVICE
// void
// warpgroup_fence_operand(uint32_t& reg) {
//   // MSVC emits a build error for 'asm volatile'
//   // even if it only occurs in a __device__ function.
//   // This prevents the error.
// #if defined(__CUDA_ARCH__)
//   asm volatile("" : "+r"(reg) :: "memory");
// #endif
// }

// CUTE_HOST_DEVICE
// void
// warpgroup_fence_operand(float& reg) {
// #if defined(__CUDA_ARCH__)
//   asm volatile("" : "+f"(reg) :: "memory");
// #endif
// }

namespace AURORA::AMMA {
// // namespace SM90::GMMA {

enum class Major {
  K  = 0,
  MN = 1
};

enum class ScaleOut {
  Zero = 0,
  One  = 1
};

enum class ScaleIn {
  Neg = -1,
  One =  1
};

enum class SparseSel {
  Zero = 0,
  One  = 1
};


//////////////////////////////////////Aurora////////////////////////////////////////////////////////
// GMMA 64x64x16 F16+=F16*F16
template <
  AMMA::Major tnspA,
  AMMA::Major tnspB,
  AMMA::ScaleIn  scaleA = AMMA::ScaleIn::One,
  AMMA::ScaleIn  scaleB = AMMA::ScaleIn::One
>
struct MMA_Aurora_64x64x16_F16F16F16_SS
{
  using DRegisters = void;
  using ARegisters = uint64_t[1];
  using BRegisters = uint64_t[1];
  using CRegisters = uint32_t[16];

  CUTE_HOST_DEVICE static void
  gemm_cal(uint16_t const alpha, 
           uint32_t const m, 
           uint32_t const n, 
           uint32_t const k,
           void* const MatrixA, 
           void* const MatrixB, 
           void* const MatrixC){
            {
              uint y = threadIdx.y + blockIdx.y * blockDim.y;
              uint x = threadIdx.x + blockIdx.x * blockDim.x + gridDim.x * blockDim.x * y;
              if (x == 0)
              {
                printf("\n in gemm_cal\n");
                // printf("alpha:%u, m:%u, n:%u, k:%u\n", alpha, m, n, k);
                // printf("MatrixA:%p, MatrixB:%p, MatrixC:%p\n", MatrixA, MatrixB, MatrixC);
              }
            }
            //call spu
  }

  CUTE_HOST_DEVICE static void
  fma(uint64_t const& desc_a,
      uint64_t const& desc_b,
      uint32_t      & d00, uint32_t      & d01, uint32_t      & d02, uint32_t      & d03,
      uint32_t      & d04, uint32_t      & d05, uint32_t      & d06, uint32_t      & d07,
      uint32_t      & d08, uint32_t      & d09, uint32_t      & d10, uint32_t      & d11,
      uint32_t      & d12, uint32_t      & d13, uint32_t      & d14, uint32_t      & d15,
      AMMA::ScaleOut const scale_D = AMMA::ScaleOut::One)
  {
    if(threadIdx.x == 0 && blockIdx.x == 0){
      printf("hello again.\n");
    }
#if defined(CUTE_ARCH_MMA_SM90A_ENABLED)
    // cutlass::arch::synclog_emit_wgmma_smem_smem(__LINE__, desc_a, desc_b);
    // asm volatile(
    // "{\n"
    //   ".reg .pred p;\n"
    //   "setp.ne.b32 p, %18, 0;\n"
    //   "wgmma.mma_async.sync.aligned.m64n64k16.f16.f16.f16 "
    //   "{%0,  %1,  %2,  %3,  %4,  %5,  %6,  %7,  "
    //   " %8,  %9,  %10, %11, %12, %13, %14, %15},"
    //   " %16,"
    //   " %17,"
    //   " p,   %19, %20, %21, %22;\n"
    // "}\n"
    //   : "+r"(d00), "+r"(d01), "+r"(d02), "+r"(d03),
    //     "+r"(d04), "+r"(d05), "+r"(d06), "+r"(d07),
    //     "+r"(d08), "+r"(d09), "+r"(d10), "+r"(d11),
    //     "+r"(d12), "+r"(d13), "+r"(d14), "+r"(d15)
    //   :  "l"(desc_a),
    //      "l"(desc_b),
    //      "r"(int32_t(scale_D)), "n"(int32_t(scaleA)), "n"(int32_t(scaleB)), "n"(int32_t(tnspA)), "n"(int32_t(tnspB)));
#else
    CUTE_INVALID_CONTROL_PATH("Attempting to use MMA_Aurora_F16F16F16_SS without CUTE_ARCH_MMA_SM90A_ENABLED");
#endif
  }
};



////////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace SM90::GMMA

} // namespace cute

#if defined(CUTE_SM90_EXTENDED_MMA_SHAPES_ENABLED)
#include "mma_sm90_gmma_ext.hpp"
#endif
