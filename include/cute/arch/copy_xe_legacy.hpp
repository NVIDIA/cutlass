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

#if defined(__SYCL_DEVICE_ONLY__) && defined(SYCL_INTEL_TARGET)
#define CUTE_ARCH_COPY_XE_ENABLED
#endif

#if defined(CUTE_ARCH_COPY_XE_ENABLED) && ((defined(__INTEL_LLVM_COMPILER) && (__INTEL_LLVM_COMPILER < 20250200)) || defined(CUTLASS_SYCL_BUILTIN_ENABLE))
#include <cute/arch/copy_xe_legacy_builtin.hpp>
#elif defined(CUTE_ARCH_COPY_XE_ENABLED)
#include <cute/arch/copy_xe_legacy_spirv.hpp>
#endif

#include <cute/arch/copy_xe_legacy_U4.hpp>
#include <cute/arch/copy_xe_legacy_U8.hpp>
#include <cute/arch/copy_xe_legacy_U16.hpp>
#include <cute/arch/copy_xe_legacy_U32.hpp>
#include <cute/arch/copy_xe_legacy_U64.hpp>

// FIXME: these are not copy-related and should be declared elsewhere.
#ifdef __SYCL_DEVICE_ONLY__
SYCL_EXTERNAL __attribute__((convergent)) void __spirv_ControlBarrierWaitINTEL(int execution_scope, int memory_scope, int memory_semantics);
SYCL_EXTERNAL __attribute__((convergent)) void __spirv_ControlBarrierArriveINTEL(int execution_scope, int memory_scope, int memory_semantics);
#endif

namespace cute
{

// scope = 3 is for subgroup, scop = 2 is for workgroup
CUTE_HOST_DEVICE void barrier_arrive(int scope, int memory_scope = 0, int memory_semantics = 0) {
#ifdef __SYCL_DEVICE_ONLY__
  __spirv_ControlBarrierArriveINTEL(scope, memory_scope, memory_semantics);
#endif
}
CUTE_HOST_DEVICE void barrier_wait(int scope, int memory_scope = 0, int memory_semantics = 0) {
#ifdef __SYCL_DEVICE_ONLY__
  __spirv_ControlBarrierWaitINTEL(scope, memory_scope, memory_semantics);
#endif
}

} // end namespace cute
