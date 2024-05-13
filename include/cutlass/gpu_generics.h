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

/*
 * This header file contains generic functions and definitions intended for GPU programming.
 * It serves as a collection of utilities that can be used across different GPU-accelerated
 * frameworks such as CUDA and SYCL.
 */

#if defined(CUTLASS_ENABLE_SYCL)
#include <sycl/sycl.hpp>
#include <syclcompat.hpp>
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////

static const int NumThreadsPerWarp = 32;
static const int NumThreadsPerWarpGroup = 128;
static const int NumWarpsPerWarpGroup = NumThreadsPerWarpGroup / NumThreadsPerWarp;
static const int NumThreadsPerHalfWarp = NumThreadsPerWarp / 2;
static const int NumThreadsPerQuad = 4;
static const int NumThreadsPerQuadPair = NumThreadsPerQuad * 2;

////////////////////////////////////////////////////////////////////////////////////////////////////

// Generalization of CUDA's threadIdx, blockIdx, and gridDim.

CUTLASS_HOST_DEVICE uint ThreadIdxX() {
#if defined(__CUDA_ARCH__)
  return threadIdx.x;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::local_id::x();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint ThreadIdxY() {
#if defined(__CUDA_ARCH__)
  return threadIdx.y;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::local_id::y();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint ThreadIdxZ() {
#if defined(__CUDA_ARCH__)
  return threadIdx.z;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::local_id::z();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint BlockIdxX() {
#if defined(__CUDA_ARCH__)
  return blockIdx.x;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::work_group_id::x();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint BlockIdxY() {
#if defined(__CUDA_ARCH__)
  return blockIdx.y;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::work_group_id::y();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint BlockIdxZ() {
#if defined(__CUDA_ARCH__)
  return blockIdx.z;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::work_group_id::z();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint BlockDimX() {
#if defined(__CUDA_ARCH__)
  return blockDim.x;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::local_range::x();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint BlockDimY() {
#if defined(__CUDA_ARCH__)
  return blockDim.y;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::local_range::y();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint BlockDimZ() {
#if defined(__CUDA_ARCH__)
  return blockDim.z;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::local_range::z();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint GridDimX() {
#if defined(__CUDA_ARCH__)
  return gridDim.x;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::work_group_range::x();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint GridDimY() {
#if defined(__CUDA_ARCH__)
  return gridDim.y;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::work_group_range::y();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint GridDimZ() {
#if defined(__CUDA_ARCH__)
  return gridDim.z;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::work_group_range::z();
#else
  return 0;
#endif
}


////////////////////////////////////////////////////////////////////////////////////////////////////

// Wrapper functions for intrinsics implemented exclusively in the NVCC compiler.
// https://www.intel.com/content/www/us/en/docs/dpcpp-compatibility-tool/developer-guide-reference/2023-2/cuda-and-sycl-programming-model-comparison.html

// syncthreads

CUTLASS_DEVICE void syncthreads() {
#if defined(__CUDA_ARCH__)
  __syncthreads();
#elif defined(__SYCL_DEVICE_ONLY__)
  syclcompat::wg_barrier();
#endif
}

CUTLASS_DEVICE int syncthreads_and(int cond) {
#if defined(__CUDA_ARCH__)
  return __syncthreads_and(cond);
#elif defined(__SYCL_DEVICE_ONLY__)
  auto group = syclcompat::get_nd_item<1>().get_group();
  sycl::group_barrier(group);
  return sycl::all_of_group(group, cond);
#else
  return 0;
#endif
}

CUTLASS_DEVICE void syncwarp() {
#if defined(__CUDA_ARCH__)
  __syncwarp();
#elif defined(__SYCL_DEVICE_ONLY__)
  sycl::group_barrier(syclcompat::get_nd_item<1>().get_sub_group());
#endif
}

CUTLASS_DEVICE void threadfence() {
#if defined(__CUDA_ARCH__)
  __threadfence();
#elif defined(__SYCL_DEVICE_ONLY__)
  sycl::atomic_fence(sycl::memory_order::acq_rel, sycl::memory_scope::device);
#endif
}

// byte perm

CUTLASS_DEVICE
uint byte_perm(uint x, uint y, uint s) {
#if defined(__CUDA_ARCH__)
  return __byte_perm(x, y, s);
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::byte_level_permute(x, y, s);
#else
  return 0;
#endif
}

// shfl

CUTLASS_DEVICE
uint shfl_up_sync(const unsigned mask, const uint var, const int delta, const int width = NumThreadsPerWarp) {
#if defined(__CUDA_ARCH__)
  return __shfl_up_sync(mask, var, delta, width);
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::shift_sub_group_right(syclcompat::get_nd_item<1>().get_sub_group(), var, delta, width);
#else
  return 0;
#endif
}

CUTLASS_DEVICE
uint shfl_down_sync(const unsigned mask, const uint var, const int delta, const int width = NumThreadsPerWarp) {
#if defined(__CUDA_ARCH__)
  return __shfl_down_sync(mask, var, delta, width);
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::shift_sub_group_left(syclcompat::get_nd_item<1>().get_sub_group(), var, delta, width);
#else
  return 0;
#endif
}

CUTLASS_DEVICE
uint shfl_sync(const unsigned mask, const uint var, const int delta, const int width = NumThreadsPerWarp) {
#if defined(__CUDA_ARCH__)
  return __shfl_sync(mask, var, delta, width);
#elif defined(__SYCL_DEVICE_ONLY__)
  auto g = syclcompat::get_nd_item<1>().get_sub_group();
  unsigned int start_index = (g.get_local_linear_id() / width) * width;
  return sycl::select_from_group(g, var, start_index + delta % width);
#else
  return 0;
#endif
}

// math

template <typename T>
CUTLASS_DEVICE T hfma2(const T a, const T b, const T c) {
#if defined(__CUDA_ARCH__)
  return hfma2(a, b, c);
#elif defined(__SYCL_DEVICE_ONLY__)
  return sycl::fma(a, b, c);
#else
  return T(0);
#endif
}

////////////////////////////////////////////////////////////////////////////////////////////////////

/*
 * The CUDA API has functions and types in the global namespace. Ideally, we'd generalize them for both, CUDA and SYCL,
 * but that requires major changes in Cutlass. To avoid that, we redefine them in the Cutlass namespace that is the base
 * namespace for Cutlass. When SYCL is on, the compiler uses these Cutlass namespace functions, avoiding conflicts
 * with CUDA definitions. When using CUDA, only the global definitions are available. This way we don't have to modify
 * the codebase, and we can rely on the compiler to select the right definition in both cases.
 */
#if defined(CUTLASS_ENABLE_SYCL)

namespace cutlass {

    // Stream
    using cudaStream_t = void *;

    // dim3
    struct dim3 {
        uint x, y, z;

        dim3() = default;

        dim3(uint x, uint y, uint z) : x(x), y(y), z(z) {}
    };


    // Atomic

    CUTLASS_DEVICE int atomicAdd(int *address, int val) {
#if defined(__SYCL_DEVICE_ONLY__)
      return syclcompat::atomic_fetch_add(address, val);
#endif
      return 0;
    }

    CUTLASS_DEVICE int atomicCAS(int *address, int compare, int val) {
#if defined(__SYCL_DEVICE_ONLY__)
      syclcompat::atomic_compare_exchange_strong(address, compare, val);
#endif
      return 0;
    }

    // Error
    using cudaError_t = unsigned int;
    constexpr cudaError_t cudaSuccess = 0;
    constexpr cudaError_t cudaErrorUnknown = 100;

    CUTLASS_HOST_DEVICE
    const char *cudaGetErrorString(cudaError_t error) {
      return "";
    }

    CUTLASS_HOST_DEVICE
    void cuGetErrorString(cudaError_t error, const char **) {
    }

    CUTLASS_HOST
    cudaError_t cudaGetLastError() {
      return cudaSuccess;
    }

    CUTLASS_HOST_DEVICE
    cudaError_t cudaGetDevice(int *device) {
      return cudaSuccess;
    }

    // Mem copy
    enum cudaMemcpyKind {
        cudaMemcpyHostToHost = 0,
        cudaMemcpyHostToDevice = 1,
        cudaMemcpyDeviceToHost = 2,
        cudaMemcpyDeviceToDevice = 3
    };

    CUTLASS_HOST_DEVICE
    cudaError_t cudaMemsetAsync(void *devPtr, unsigned int value, size_t count, cudaStream_t stream = nullptr) {
      syclcompat::fill_async(devPtr, value, count);
      return cudaSuccess;
    }

    using CUresult = unsigned int;
    using CUdeviceptr = unsigned int*;
    constexpr CUresult CUDA_SUCCESS = 0;

    CUTLASS_HOST_DEVICE
    CUresult cuMemsetD32Async(CUdeviceptr devPtr, uint32_t value, size_t count, cudaStream_t stream = nullptr) {
      void *ptr = reinterpret_cast<void *>(devPtr);
      syclcompat::fill_async(ptr, value, count);
      return cudaSuccess;
    }

    CUTLASS_HOST_DEVICE
    CUresult cuMemsetD16Async(CUdeviceptr devPtr, uint16_t value, size_t count, cudaStream_t stream = nullptr) {
      void *ptr = reinterpret_cast<void *>(devPtr);
      syclcompat::fill_async(ptr, value, count);
      return cudaSuccess;
    }

    CUTLASS_HOST_DEVICE
    CUresult cuMemsetD8Async(CUdeviceptr devPtr, uint8_t value, size_t count, cudaStream_t stream = nullptr) {
      void *ptr = reinterpret_cast<void *>(devPtr);
      syclcompat::fill_async(ptr, value, count);
      return cudaSuccess;
    }

    // FuncAttribute
    using cudaFuncAttribute = unsigned int;
    constexpr cudaFuncAttribute cudaFuncAttributeMaxDynamicSharedMemorySize = 0;

    CUTLASS_HOST
    cudaError_t cudaFuncSetAttribute(const void *func, cudaFuncAttribute attr, int value) {
      return cudaSuccess;
    }

    using cudaDeviceAttr = unsigned int;
    constexpr cudaDeviceAttr cudaDevAttrMultiProcessorCount = 0;

    CUTLASS_HOST_DEVICE
    cudaError_t cudaDeviceGetAttribute(int *value, cudaDeviceAttr attr, int device) {
      return cudaSuccess;
    }

    constexpr unsigned int cudaOccupancyDisableCachingOverride = 0;

    CUTLASS_HOST
    cudaError_t cudaOccupancyMaxActiveBlocksPerMultiprocessorWithFlags(
            int *numBlocks, const void *func, int blockSize, size_t dynamicSMemSize, unsigned int flags) {
      return cudaSuccess;
    }

}

// Expose dim3 in the cute namespace
namespace cute {
    using dim3 = cutlass::dim3;
}
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////
