/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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

enum SPIRVScope {
  ScopeCrossDevice = 0,
  ScopeDevice = 1,
  ScopeWorkgroup = 2,
  ScopeSubgroup = 3,
  ScopeInvocation = 4,
};

enum SPIRVMemorySemantics {
  SemanticsNone = 0,
  SemanticsAcquire = 0x2,
  SemanticsRelease = 0x4,
  SemanticsAcquireRelease = 0x8,
  SemanticsSGMemory = 0x80,
  SemanticsWGMemory = 0x100,
  SemanticsCrossWGMemory = 0x200,
};

#ifdef __SYCL_DEVICE_ONLY__
SYCL_EXTERNAL __attribute__((convergent)) void __spirv_ControlBarrierWaitINTEL(int execution_scope, int memory_scope, int memory_semantics);
SYCL_EXTERNAL __attribute__((convergent)) void __spirv_ControlBarrierArriveINTEL(int execution_scope, int memory_scope, int memory_semantics);
#endif

namespace cute
{

CUTE_HOST_DEVICE void barrier_arrive(SPIRVScope scope, int memory_semantics = SemanticsNone) {
#ifdef __SYCL_DEVICE_ONLY__
  __spirv_ControlBarrierArriveINTEL(scope, scope, memory_semantics);
#endif
}
CUTE_HOST_DEVICE void barrier_wait(SPIRVScope scope, int memory_semantics = SemanticsNone) {
#ifdef __SYCL_DEVICE_ONLY__
  __spirv_ControlBarrierWaitINTEL(scope, scope, memory_semantics);
#endif
}

CUTE_HOST_DEVICE void barrier_arrive(int scope, int memory_scope = ScopeCrossDevice, int memory_semantics = SemanticsNone) {
#ifdef __SYCL_DEVICE_ONLY__
  __spirv_ControlBarrierArriveINTEL(scope, memory_scope, memory_semantics);
#endif
}
CUTE_HOST_DEVICE void barrier_wait(int scope, int memory_scope = ScopeCrossDevice, int memory_semantics = SemanticsNone) {
#ifdef __SYCL_DEVICE_ONLY__
  __spirv_ControlBarrierWaitINTEL(scope, memory_scope, memory_semantics);
#endif
}

} // end namespace cute
