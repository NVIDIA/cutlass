/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
    \brief Architecture-specific operators on memory added for SM75
*/

#pragma once

#include "cutlass/array.h"
#include "cutlass/layout/matrix.h"

namespace cutlass {
namespace arch {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  /// Layout of destination matrix (column-major implies transpose)
  typename Layout,
  /// .x1, .x2, or .x4
  int MatrixCount
>
inline __device__ void ldsm(Array<unsigned, MatrixCount> & D, void const* ptr);

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Determine the appropriate way to target PTX's "ldmatrix" instruction.
//
/////////////////////////////////////////////////////////////////////////////////////////////////

#if (__CUDACC_VER_MAJOR__ == 10 && __CUDACC_VER_MINOR__ >= 2) || (__CUDACC_VER_MAJOR__ >= 11)

#if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 750)
#define CUDA_LDMATRIX_ACTIVATED 1
#endif

#define CUDA_LDMATRIX_SUPPORTED 1
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////
/*
#if ! defined(CUDA_NVVM_GET_SMEM_POINTER_SUPPORTED) && (__CUDACC_VER_MAJOR__ > 10)
  #define CUDA_NVVM_GET_SMEM_POINTER_SUPPORTED 1
#endif
#if ! defined(CUDA_NVVM_GET_SMEM_POINTER_SUPPORTED)
  #define CUDA_NVVM_GET_SMEM_POINTER_SUPPORTED ((__CUDACC_VER_MAJOR__ == 10) && (__CUDACC_VER_MINOR__ >= 1))
#endif

#if ! defined(CUDA_NVVM_GET_SMEM_POINTER_ENABLED)
  #define CUDA_NVVM_GET_SMEM_POINTER_ENABLED CUDA_NVVM_GET_SMEM_POINTER_SUPPORTED
#endif
*/

#if (__CUDACC_VER_MAJOR__ == 10 && __CUDACC_VER_MINOR__ >= 2)
  extern "C" {
  //
  // This NVVM intrinsic is subject to change in future versions of CUDA.
  // Clients should not call it directly. Rather, they should use the 
  // cutlass::arch::ldsm<>() template.
  //
  __device__ uint32_t __nvvm_get_smem_pointer(void *);
  }
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

/// CUTLASS helper to get SMEM pointer
inline __device__ unsigned cutlass_get_smem_pointer(void *ptr) {

// We prefer to use the new CVTA intrinsics if they are available, otherwise we will fall back to
// the previous internal intrinsics if they are available.
#if (defined(__CUDA_ARCH__) && __CUDACC_VER_MAJOR__ >= 11)
  //
  // This NVVM intrinsic converts an address in shared memory to a plain
  // unsigned integer. This is necessary to pass to shared memory instructions
  // in inline PTX.
  //
  // In CUDA 11 and beyond, this replaces __nvvm_get_smem_pointer()  [only available in 10.2].
  //
  //__device__ size_t __cvta_generic_to_shared(void* ptr);

  /// CUTLASS helper to get SMEM pointer
  return static_cast<unsigned>(__cvta_generic_to_shared(ptr));

#elif (defined(__CUDA_ARCH__) &&  __CUDACC_VER_MAJOR__ == 10 && __CUDACC_VER_MINOR__ >= 2)

  return __nvvm_get_smem_pointer(ptr);

#elif defined(__CUDA_ARCH__)

  uint32_t smem_ptr;

  asm(
  "{ .reg .u64 smem_ptr; cvta.to.shared.u64 smem_ptr, %1; cvt.u32.u64 %0, smem_ptr; }\n" 
    : "=r"(smem_ptr) : "l"(ptr));

  return smem_ptr;

#else

  return 0;
#endif
}
  
/// CUTLASS helper to get SMEM pointer
inline __device__ unsigned cutlass_get_smem_pointer(void const *ptr) {
  return cutlass_get_smem_pointer(const_cast<void *>(ptr));
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template <>
inline __device__ void ldsm<layout::RowMajor, 1>(
    Array<unsigned, 1> & D,
    void const* ptr) {

  #if defined(CUDA_LDMATRIX_ACTIVATED)

    unsigned addr = cutlass_get_smem_pointer(ptr);

    int x;
    asm volatile ("ldmatrix.sync.aligned.x1.m8n8.shared.b16 {%0}, [%1];" : "=r"(x) : "r"(addr));
    reinterpret_cast<int &>(D) = x;

  #else

    assert(0);

  #endif
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template <>
inline __device__ void ldsm<layout::RowMajor, 2>(
    Array<unsigned, 2> & D,
    void const* ptr) {

  #if defined(CUDA_LDMATRIX_ACTIVATED)

    unsigned addr = cutlass_get_smem_pointer(ptr);

    int x, y;
    asm volatile ("ldmatrix.sync.aligned.x2.m8n8.shared.b16 {%0, %1}, [%2];" : "=r"(x), "=r"(y) : "r"(addr));
    reinterpret_cast<int2 &>(D) = make_int2(x, y);

  #else

    assert(0);

  #endif
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template <>
inline __device__ void ldsm<layout::RowMajor, 4>(
    Array<unsigned, 4> & D,
    void const* ptr) {

  #if defined(CUDA_LDMATRIX_ACTIVATED)

    unsigned addr = cutlass_get_smem_pointer(ptr);

    int x, y, z, w;
    asm volatile ("ldmatrix.sync.aligned.x4.m8n8.shared.b16 {%0, %1, %2, %3}, [%4];" : "=r"(x), "=r"(y), "=r"(z), "=r"(w) : "r"(addr));
    reinterpret_cast<int4 &>(D) = make_int4(x, y, z, w);

  #else

    assert(0);

  #endif
}

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Transpose on 16b granularity
//
/////////////////////////////////////////////////////////////////////////////////////////////////

template <>
inline __device__ void ldsm<layout::ColumnMajor, 1>(
    Array<unsigned, 1> & D,
    void const* ptr) {

  #if CUDA_LDMATRIX_ACTIVATED

    unsigned addr = cutlass_get_smem_pointer(ptr);

    int x;
    asm volatile ("ldmatrix.sync.aligned.x1.trans.m8n8.shared.b16 {%0}, [%1];" : "=r"(x) : "r"(addr));
    reinterpret_cast<int &>(D) = x;

  #else

    assert(0);

  #endif
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template <>
inline __device__ void ldsm<layout::ColumnMajor, 2>(
    Array<unsigned, 2> & D,
    void const* ptr) {

  #if defined(CUDA_LDMATRIX_ACTIVATED)

    unsigned addr = cutlass_get_smem_pointer(ptr);

    int x, y;
    asm volatile ("ldmatrix.sync.aligned.x2.trans.m8n8.shared.b16 {%0, %1}, [%2];" : "=r"(x), "=r"(y) : "r"(addr));
    reinterpret_cast<int2 &>(D) = make_int2(x, y);

  #else

    assert(0);

  #endif
}

/////////////////////////////////////////////////////////////////////////////////////////////////

template <>
inline __device__ void ldsm<layout::ColumnMajor, 4>(
    Array<unsigned, 4> & D,
    void const* ptr) {

  #if defined(CUDA_LDMATRIX_ACTIVATED)

    unsigned addr = cutlass_get_smem_pointer(ptr);

    int x, y, z, w;
    asm volatile ("ldmatrix.sync.aligned.x4.trans.m8n8.shared.b16 {%0, %1, %2, %3}, [%4];" : "=r"(x), "=r"(y), "=r"(z), "=r"(w) : "r"(addr));
    reinterpret_cast<int4 &>(D) = make_int4(x, y, z, w);

  #else

    assert(0);

  #endif
}

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace arch
} // namespace cutlass
