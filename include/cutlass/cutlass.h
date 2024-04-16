/***************************************************************************************************
 * Copyright (c) 2017 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Basic include for CUTLASS.
*/

#pragma once

#include "cutlass/detail/helper_macros.hpp"

#if defined(CUTLASS_ENABLE_SYCL)
#include "syclcompat.hpp"
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {

/// Status code returned by CUTLASS operations
enum class Status {
  kSuccess,                    ///< Operation was successful.
  kErrorMisalignedOperand,     ///< operands fail alignment requirements.
  kErrorInvalidDataType,       ///< DataType fails requirement.
  kErrorInvalidLayout,         ///< Layout fails alignment requirement.
  kErrorInvalidProblem,        ///< Specified problem size is not supported by operator.
  kErrorNotSupported,          ///< Operation is not supported on current device.
  kErrorWorkspaceNull,         ///< The given workspace is null when it is required to be non-null.
  kErrorInternal,              ///< An error within CUTLASS occurred.
  kErrorArchMismatch,          ///< CUTLASS runs on a device that it was not compiled for.
  kErrorInsufficientDriver,    ///< CUTLASS runs with a driver that is too old.
  kErrorMemoryAllocation,      ///< Kernel launch failed due to insufficient device memory.
  kInvalid                     ///< Status is unspecified.
};

/// Convert cutlass status to status strings
CUTLASS_HOST_DEVICE
static char const* cutlassGetStatusString(cutlass::Status status) {
  switch (status) {
    case cutlass::Status::kSuccess:
      return "Success";
    case cutlass::Status::kErrorMisalignedOperand:
      return "Error Misaligned Operand";
    case cutlass::Status::kErrorInvalidDataType:
      return "Error Invalid Data Type";
    case cutlass::Status::kErrorInvalidLayout:
      return "Error Invalid Layout";
    case cutlass::Status::kErrorInvalidProblem:
      return "Error Invalid Problem";
    case cutlass::Status::kErrorNotSupported:
      return "Error Not Supported";
    case cutlass::Status::kErrorWorkspaceNull:
      return "Error Workspace Null";
    case cutlass::Status::kErrorInternal:
      return "Error Internal";
    case cutlass::Status::kErrorInsufficientDriver:
      return "Error Insufficient Driver";
    case cutlass::Status::kErrorArchMismatch:
      return "Error Architecture Mismatch";
    case cutlass::Status::kErrorMemoryAllocation:
      return "Error Memory Allocation failed";
    case cutlass::Status::kInvalid: break;
  }

  return "Invalid status";
}

////////////////////////////////////////////////////////////////////////////////////////////////////

static const int NumThreadsPerWarp = 32;
static const int NumThreadsPerWarpGroup = 128;
static const int NumWarpsPerWarpGroup = NumThreadsPerWarpGroup / NumThreadsPerWarp;
static const int NumThreadsPerHalfWarp = NumThreadsPerWarp / 2;
static const int NumThreadsPerQuad = 4;
static const int NumThreadsPerQuadPair = NumThreadsPerQuad * 2;

////////////////////////////////////////////////////////////////////////////////////////////////////

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
  return syclcompat::work_group_range::x();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint BlockDimY() {
#if defined(__CUDA_ARCH__) 
  return blockDim.y;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::work_group_range::y();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint BlockDimZ() {
#if defined(__CUDA_ARCH__) 
  return blockDim.z;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::work_group_range::z();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint GridDimX() {
#if defined(__CUDA_ARCH__) 
  return gridDim.x;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::global_range::x();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint GridDimY() {
#if defined(__CUDA_ARCH__) 
  return gridDim.y;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::global_range::y();
#else
  return 0;
#endif
}

CUTLASS_HOST_DEVICE uint GridDimZ() {
#if defined(__CUDA_ARCH__) 
  return gridDim.z;
#elif defined(__SYCL_DEVICE_ONLY__)
  return syclcompat::global_range::z();
#else
  return 0;
#endif
}

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
  // TODO: Add SYCL equivalent function
  assert(false);
#else
  return 0;
#endif
}

CUTLASS_DEVICE void syncwarp() {
#if defined(__CUDA_ARCH__) 
    __syncwarp();
#elif defined(__SYCL_DEVICE_ONLY__)
  // TODO: Add SYCL equivalent function
  assert(false);
#endif
}

CUTLASS_DEVICE void threadfence() {
#if defined(__CUDA_ARCH__) 
    __threadfence();
#elif defined(__SYCL_DEVICE_ONLY__)
  // TODO: Add SYCL equivalent function
  assert(false);
#endif
}

// byte perm

CUTLASS_DEVICE
uint byte_perm(uint x, uint y, uint s) {
#if defined(__CUDA_ARCH__) 
   return __byte_perm(x, y, s);
#elif defined(__SYCL_DEVICE_ONLY__)
  // TODO: Add SYCL equivalent function
  assert(false);
  return 0;
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
  // TODO: Add SYCL equivalent function
  assert(false);
  return 0;
#else
  return 0;
#endif
}

CUTLASS_DEVICE
uint shfl_down_sync(const unsigned mask, const uint var, const int delta, const int width = NumThreadsPerWarp) {
#if defined(__CUDA_ARCH__) 
  return __shfl_down_sync(mask, var, delta, width);
#elif defined(__SYCL_DEVICE_ONLY__)
  // TODO: Add SYCL equivalent function
  assert(false);
  return 0;
#else
  return 0;
#endif
}

CUTLASS_DEVICE
uint shfl_sync(const unsigned mask, const uint var, const int delta, const int width = NumThreadsPerWarp) {
#if defined(__CUDA_ARCH__) 
  return __shfl_sync(mask, var, delta, width);
#elif defined(__SYCL_DEVICE_ONLY__)
  // TODO: Add SYCL equivalent function
  assert(false);
  return 0;
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
  // TODO: Add SYCL equivalent function
  assert(false);
  return  T(0);
#else
  return T(0);
#endif
}

// atomic

#if defined(CUTLASS_ENABLE_SYCL)
CUTLASS_DEVICE int atomicAdd(int *address, int val) {
#if defined(__SYCL_DEVICE_ONLY__)
  // TODO: Add SYCL equivalent function
  assert(false);
#else 
  return 0;
#endif  
}

CUTLASS_DEVICE int atomicCAS(int *address, int compare, int val) {
#if defined(__SYCL_DEVICE_ONLY__)
  // TODO: Add SYCL equivalent function
  assert(false);
#else 
  return 0;
#endif  
}
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper function to return true when called by thread 0 of threadblock 0.
CUTLASS_HOST_DEVICE bool thread0() {
  #if defined(__CUDA_ARCH__)
    return (!threadIdx.x && !threadIdx.y && !threadIdx.z) && (!blockIdx.x && !blockIdx.y && !blockIdx.z);
  #else
    return false;
  #endif
}

/// Returns a lane index in the warp. The threads in warp may not be convergent
CUTLASS_DEVICE
int canonical_lane_idx() { 
  #if defined(__CUDA_ARCH__)
    return threadIdx.x % NumThreadsPerWarp;
  #else
    return 0;
  #endif
}

/// Returns a warp-uniform value indicating the canonical warp index of the calling threads.
/// Threads within the warp must be converged.
CUTLASS_DEVICE
int canonical_warp_idx_sync() { 
  #if defined(__CUDA_ARCH__)
    return __shfl_sync(0xffffffff, threadIdx.x / NumThreadsPerWarp, 0);
  #else
    return 0;
  #endif
}

/// Returns a warp index in the CTA. The threads in warp may not be convergent
/// As it doesn't sync the warp, it faster and allows forward progress
CUTLASS_DEVICE
int canonical_warp_idx() { 
  #if defined(__CUDA_ARCH__)
    return threadIdx.x / NumThreadsPerWarp;
  #else
    return 0;
  #endif
}

/// Returns a warp-uniform value indicating the canonical warp group index of the calling threads.
/// Threads within the warp must be converged.
CUTLASS_DEVICE
int canonical_warp_group_idx() {
  #if defined(__CUDA_ARCH__)
    return __shfl_sync(0xffffffff, threadIdx.x / NumThreadsPerWarpGroup, 0);
  #else
    return 0;
  #endif
}

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace cutlass

////////////////////////////////////////////////////////////////////////////////////////////////////
