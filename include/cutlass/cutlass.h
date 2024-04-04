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
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::local_id::x();
#else
  return threadIdx.x;
#endif
}

CUTLASS_HOST_DEVICE uint ThreadIdxY() {
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::local_id::y();
#else
  return threadIdx.y;
#endif
}

CUTLASS_HOST_DEVICE uint ThreadIdxZ() {
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::local_id::z();
#else
  return threadIdx.z;
#endif
}

CUTLASS_HOST_DEVICE uint BlockIdxX() {
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::work_group_id::x();
#else
  return blockIdx.x;
#endif
}

CUTLASS_HOST_DEVICE uint BlockIdxY() {
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::work_group_id::y();
#else
  return blockIdx.y;
#endif
}

CUTLASS_HOST_DEVICE uint BlockIdxZ() {
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::work_group_id::z();
#else
  return blockIdx.z;
#endif
}

CUTLASS_HOST_DEVICE uint BlockDimX() {
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::work_group_range::x();
#else
  return blockDim.x;
#endif
}

CUTLASS_HOST_DEVICE uint BlockDimY() {
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::work_group_range::y();
#else
  return blockDim.y;
#endif
}

CUTLASS_HOST_DEVICE uint BlockDimZ() {
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::work_group_range::z();
#else
  return blockDim.z;
#endif
}

CUTLASS_HOST_DEVICE uint GridDimX() {
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::global_range::x();
#else
  return gridDim.x;
#endif
}

CUTLASS_HOST_DEVICE uint GridDimY() {
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::global_range::y();
#else
  return gridDim.y;
#endif
}

CUTLASS_HOST_DEVICE uint GridDimZ() {
#if defined(CUTLASS_ENABLE_SYCL)
  return syclcompat::global_range::z();
#else
  return gridDim.z;
#endif
}

// syncthreads

CUTLASS_DEVICE void syncthreads() {
#if defined(CUTLASS_ENABLE_SYCL)
  syclcompat::wg_barrier();
#else
  __syncthreads();
#endif
}

CUTLASS_DEVICE int syncthreads_and(int cond) {
#if defined(CUTLASS_ENABLE_SYCL)
  // TODO: Add SYCL equivalent function
  assert(false);
#else
  return __syncthreads_and(cond);
#endif
}

CUTLASS_DEVICE void syncwarp() {
#if defined(CUTLASS_ENABLE_SYCL)
  // TODO: Add SYCL equivalent function
  assert(false);
#else
  __syncwarp();
#endif
}

CUTLASS_DEVICE void threadfence() {
#if defined(CUTLASS_ENABLE_SYCL)
  // TODO: Add SYCL equivalent function
  assert(false);
#else
  __threadfence();
#endif
}

// byte perm

CUTLASS_DEVICE
uint byte_perm(uint x, uint y, uint s) {
#if defined(CUTLASS_ENABLE_SYCL)
  // TODO: Add SYCL equivalent function
  assert(false);
#else
  return __byte_perm(x, y, s);
#endif
}

// shfl

CUTLASS_DEVICE
uint shfl_up_sync(const unsigned mask, const uint var, const int delta, const int width = NumThreadsPerWarp) {
#if defined(CUTLASS_ENABLE_SYCL)
  // TODO: Add SYCL equivalent function
  assert(false);
#else
  return __shfl_up_sync(mask, var, delta, width);
#endif
}

CUTLASS_DEVICE
uint shfl_down_sync(const unsigned mask, const uint var, const int delta, const int width = NumThreadsPerWarp) {
#if defined(CUTLASS_ENABLE_SYCL)
  // TODO: Add SYCL equivalent function
  assert(false);
#else
  return __shfl_down_sync(mask, var, delta, width);
#endif
}

CUTLASS_DEVICE
uint shfl_sync(const unsigned mask, const uint var, const int delta, const int width = NumThreadsPerWarp) {
#if defined(CUTLASS_ENABLE_SYCL)
  // TODO: Add SYCL equivalent function
  assert(false);
#else
  return __shfl_sync(mask, var, delta, width);
#endif
}

// math

template <typename T>
CUTLASS_DEVICE T hfma2(const T a, const T b, const T c) {
#if defined(CUTLASS_ENABLE_SYCL)
  // TODO: Add SYCL equivalent function
  assert(false);
#else
  return hfma2(a, b, c);
#endif
}

// atomic

#if defined(CUTLASS_ENABLE_SYCL)
CUTLASS_DEVICE int atomicAdd(int *address, int val) {
  // TODO: Add SYCL equivalent function
  assert(false);
}

CUTLASS_DEVICE int atomicCAS(int *address, int compare, int val) {
  // TODO: Add SYCL equivalent function
  assert(false);
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
