/***************************************************************************************************
 * Copyright (c) 2023 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Utilities for initializing workspaces
*/

/*
  Note:  CUTLASS 3x increases the host compiler requirements to C++17. However, certain
         existing integrations of CUTLASS require C++11 host compilers.

         Until this requirement can be lifted, certain headers with this annotation are required
         to be remain consistent with C++11 syntax.

         C++11 compatibility is enforced by this unit test: `cutlass_test_unit_core_cpp11`.
*/

#pragma once

#if !defined(__CUDACC_RTC__)
#include "cuda_runtime.h"

#include "cutlass/trace.h"
#endif

#include "cutlass.h"

namespace cutlass {

/////////////////////////////////////////////////////////////////////////////////////////////////
#if !defined(__CUDACC_RTC__)
static Status
zero_workspace(void* workspace, int workspace_size, cudaStream_t stream = nullptr) {
  if (workspace_size > 0) {
    if (workspace == nullptr) {
      CUTLASS_TRACE_HOST("  error: device workspace must not be null");
      return Status::kErrorWorkspaceNull;
    }

    CUTLASS_TRACE_HOST("  clearing barrier workspace");
    cudaError_t result = cudaMemsetAsync(workspace, 0, workspace_size, stream);
    if (cudaSuccess != result) {
      result = cudaGetLastError(); // to clear the error bit
      CUTLASS_TRACE_HOST("  cudaMemsetAsync() returned error " << cudaGetErrorString(result));
      return Status::kErrorInternal;
    }
  }

  return Status::kSuccess;
}
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass
