/***************************************************************************************************
 * Copyright (c) 2017 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Architecture-specific operators on memory added for SM80
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/complex.h"
#include "cutlass/arch/memory.h"
#include "cutlass/arch/memory_sm75.h"
#include "cutlass/arch/memory_sm80.h"
#include "cutlass/arch/cache_operation.h"

namespace cutlass {
namespace arch {

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Initiates an asynchronous copy from global memory to shared memory.
///
/// cp.async
///
template <
    /// Size of the access in bytes
    int SizeInBytes,
    /// Cache operation
    CacheOperation::Kind cache_op = CacheOperation::Always,
    bool GlobalToShared = true>
struct copy;

/// Initiates an asynchronous copy from global memory to shared memory. Rather than predicate
/// the entire transfer, zeros are written to SMEM if the guard predicate is false.
///
/// cp.async
///
template <
    /// Size of the access in bytes
    int SizeInBytes,
    /// Cache operation
    CacheOperation::Kind cache_op = CacheOperation::Always,
    bool GlobalToShared = true>
struct copy_zfill;

/// Blocks until all but <N> previous cp.async.commit_group operations have committed.
///
/// cp.async
///
template <int N, bool GlobalToShared = true>
struct copy_wait;

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Partial specialization
template <
    /// Size of the access in bytes
    int SizeInBytes>
struct copy<SizeInBytes, CacheOperation::Always, true> {

  /// Copy
  CUTLASS_DEVICE
  copy(void *smem_ptr, void const *global_ptr, bool pred_guard = true) {
      cp_async<SizeInBytes, CacheOperation::Always>(smem_ptr, global_ptr, pred_guard);
  }
};

/// Partial specialization
template <
    /// Size of the access in bytes
    int SizeInBytes>
struct copy<SizeInBytes, CacheOperation::Always, false> {

  /// Copy
  CUTLASS_DEVICE
  copy(void *smem_ptr, void const *global_ptr, bool pred_guard = true) {
      using AccessType  = Array<uint8_t, SizeInBytes>;

      if (pred_guard) {
        *static_cast<AccessType *>(smem_ptr) = *static_cast<AccessType const *>(global_ptr);
      }
  }
};

/// Partial specialization
template <
    /// Size of the access in bytes
    int SizeInBytes>
struct copy_zfill<SizeInBytes, CacheOperation::Always, true> {

  /// Copy with zero fill
  CUTLASS_DEVICE
  copy_zfill(void *smem_ptr, void const *global_ptr, bool pred_guard) {
      cp_async_zfill<SizeInBytes, CacheOperation::Always>(smem_ptr, global_ptr, pred_guard);
  }
};

/// Partial specialization
template <
    /// Size of the access in bytes
    int SizeInBytes>
struct copy_zfill<SizeInBytes, CacheOperation::Always, false> {

  /// Copy with zero fill
  CUTLASS_DEVICE
  copy_zfill(void *smem_ptr, void const *global_ptr, bool pred_guard) {
      using AccessType  = Array<uint8_t, SizeInBytes>;

      if (pred_guard) {
        *static_cast<AccessType *>(smem_ptr) = *static_cast<AccessType const *>(global_ptr);
      }
      else {
        AccessType zeros;
        zeros.clear();
        *static_cast<AccessType *>(smem_ptr) = zeros;
      }
  }
};

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Partial specialization
template <
    /// Size of the access in bytes
    int SizeInBytes>
struct copy<SizeInBytes, CacheOperation::Global, true> {

  /// Copy
  CUTLASS_DEVICE
  copy(void *smem_ptr, void const *global_ptr, bool pred_guard = true) {
      cp_async<SizeInBytes, CacheOperation::Global>(smem_ptr, global_ptr, pred_guard);
  }
};

/// Partial specialization
template <
    /// Size of the access in bytes
    int SizeInBytes>
struct copy<SizeInBytes, CacheOperation::Global, false> {

  /// Copy
  CUTLASS_DEVICE
  copy(void *smem_ptr, void const *global_ptr, bool pred_guard = true) {
      using AccessType  = Array<uint8_t, SizeInBytes>;

      if (pred_guard) {
        *static_cast<AccessType *>(smem_ptr) = *static_cast<AccessType const *>(global_ptr);
      }
  }
};

/// Partial specialization
template <
    /// Size of the access in bytes
    int SizeInBytes>
struct copy_zfill<SizeInBytes, CacheOperation::Global, true> {

  /// Copy with zero fill
  CUTLASS_DEVICE
  copy_zfill(void *smem_ptr, void const *global_ptr, bool pred_guard = true) {
      cp_async_zfill<SizeInBytes, CacheOperation::Global>(smem_ptr, global_ptr, pred_guard);
  }
};

/// Partial specialization
template <
    /// Size of the access in bytes
    int SizeInBytes>
struct copy_zfill<SizeInBytes, CacheOperation::Global, false> {

  /// Copy with zero fill
  CUTLASS_DEVICE
  copy_zfill(void *smem_ptr, void const *global_ptr, bool pred_guard = true) {
      using AccessType  = Array<uint8_t, SizeInBytes>;

      if (pred_guard) {
        *static_cast<AccessType *>(smem_ptr) = *static_cast<AccessType const *>(global_ptr);
      }
      else {
        AccessType zeros;
        zeros.clear();
        *static_cast<AccessType *>(smem_ptr) = zeros;
      }
  }
};

/// Establishes an ordering w.r.t previously issued cp.async instructions. Does not block.
template <bool GlobalToShared>
CUTLASS_DEVICE
void copy_fence() {}

template <>
CUTLASS_DEVICE
void copy_fence<true>() {
  cp_async_fence();
}

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Partial specialization
template <int N>
struct copy_wait<N, false> {

  CUTLASS_DEVICE
  copy_wait() {}
};

/// Partial specialization
template <int N>
struct copy_wait<N, true> {

  CUTLASS_DEVICE
  copy_wait() { cp_async_wait<N>(); }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace arch
}  // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
