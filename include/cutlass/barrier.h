/***************************************************************************************************
 * Copyright (c) 2017 - 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
/*! \file
    \brief Implementation of a CTA-wide barrier for inter-CTA synchronization.
*/

#pragma once

#include "cutlass/cutlass.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// CTA-wide semaphore for inter-CTA synchronization.
struct Barrier
{

public:

  /// Flag type
  using T = int;

  /// Initial flag value
  static const T INIT = 0;


protected:

  /// Load flag, as a strong operation (int specialization)
  CUTLASS_DEVICE
  static int ld_strong(int *ptr)
  {
    int state = 0;

#if (__CUDA_ARCH__ >= 700)
      /// SM70 and newer use memory consistency qualifiers
      asm volatile ("ld.global.relaxed.gpu.b32 %0, [%1];\n" : "=r"(state) : "l"(ptr));
#else
      asm volatile ("ld.cg.global.b32 %0, [%1];\n" : "=r"(state) : "l"(ptr));
#endif // (__CUDA_ARCH__ >= 700)

    return state;
  }

  /// Store flag, as a strong operation (int specialization)
  CUTLASS_DEVICE
  static void st_strong(int *ptr, int val)
  {
#if (__CUDA_ARCH__ >= 700)
      /// SM70 and newer use memory consistency qualifiers
      asm volatile ("st.global.relaxed.gpu.b32 [%0], %1;\n" : : "l"(ptr), "r"(val));
#else
      asm volatile ("st.cg.global.b32 [%0], %1;\n" : : "l"(ptr), "r"(val));
#endif // (__CUDA_ARCH__ >= 700)
  }


  /// Reduce into flag, with release pattern (int specialization)
  CUTLASS_DEVICE
  static void red_release(int *ptr, int val)
  {
#if defined(__NVCC__) || (defined(__clang__) && defined(__CUDA__)) || defined(__CUDACC_RTC__)
#if (__CUDA_ARCH__ >= 700)
      /// SM70 and newer use memory consistency qualifiers
      asm volatile ("red.release.gpu.global.add.s32 [%0], %1;\n" : : "l"(ptr), "r"(val));
#else
      __threadfence();
      atomicAdd(ptr, val);
#endif // (__CUDA_ARCH__ >= 700)
#endif
  }


public:

  /// Uses thread[0] to wait for at least the specified count of signals on the given flag counter
  CUTLASS_DEVICE
  static void wait_lt(void *lock_ptr, int thread_idx, int flag_idx, int count)
  {
#if defined(__NVCC__) || (defined(__clang__) && defined(__CUDA__)) || defined(__CUDACC_RTC__)
    T *flag_ptr = reinterpret_cast<T*>(lock_ptr) + flag_idx;

    if (thread_idx == 0)
    {
        // Spin-loop
        #pragma unroll 1
        while(ld_strong(flag_ptr) < count) {}
    }

    __syncthreads();
#endif
  }

  /// Uses thread[0] to wait for at least the specified count of signals on the given flag counter
  CUTLASS_DEVICE
  static void wait_eq(void *lock_ptr, int thread_idx, int flag_idx, T val = 1)
  {
#if defined(__NVCC__) || (defined(__clang__) && defined(__CUDA__)) || defined(__CUDACC_RTC__)
    T *flag_ptr = reinterpret_cast<T*>(lock_ptr) + flag_idx;

    if (thread_idx == 0)
    {
        // Spin-loop
        #pragma unroll 1
        while(ld_strong(flag_ptr) != val) {}
    }

    __syncthreads();
#endif
  }

  /// Uses thread[0] to wait for the specified count of signals on the given flag counter
  CUTLASS_DEVICE
  static void wait_eq_reset(void *lock_ptr, int thread_idx, int flag_idx, T val = 1) {
#if defined(__NVCC__) || (defined(__clang__) && defined(__CUDA__)) || defined(__CUDACC_RTC__)
    T *flag_ptr = reinterpret_cast<T*>(lock_ptr) + flag_idx;

    if (thread_idx == 0)
    {
        // Spin-loop
        #pragma unroll 1
        while(atomicCAS(flag_ptr, val, 0) != val) {}
    }

    __syncthreads();
#endif
  }

  /// Increment the arrival count for a flag
  CUTLASS_DEVICE
  static void arrive_inc(void *lock_ptr, int thread_idx, int flag_idx)
  {
#if defined(__NVCC__) || (defined(__clang__) && defined(__CUDA__)) || defined(__CUDACC_RTC__)
    T* flag_ptr = reinterpret_cast<T*>(lock_ptr) + flag_idx;

    __syncthreads();

    if (thread_idx == 0) {
      red_release(flag_ptr, 1);
    }
#endif
  }


  /// Increment the arrival counts for a range of flags
  CUTLASS_DEVICE
  static void arrive_range_inc(void *lock_ptr, int thread_idx, int first_flag_idx, int count = 1)
  {
#if defined(__NVCC__) || (defined(__clang__) && defined(__CUDA__)) || defined(__CUDACC_RTC__)
    int flag_idx = first_flag_idx + thread_idx;
    T* flag_ptr = reinterpret_cast<T*>(lock_ptr) + flag_idx;

    // Barrier to make sure all other threads in block have written their data
    __syncthreads();

    // Select threads increment their flags
    if (thread_idx < count) {
      red_release(flag_ptr, 1);
    }
#endif
  }
};



/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
