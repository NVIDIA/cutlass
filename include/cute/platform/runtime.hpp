/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 **************************************************************************************************/
#pragma once

#if defined(__MACACC__) || defined(__MACA_ARCH__)
#  if defined(__has_include)
#    if __has_include(<maca_runtime_api.h>)
#      include <maca_runtime_api.h>
#      define CUTE_HAS_MXMACA_RUNTIME 1
#    elif __has_include(<maca_runtime.h>)
#      include <maca_runtime.h>
#      define CUTE_HAS_MXMACA_RUNTIME 1
#    endif
#  endif
#elif defined(__HIPCC__) || defined(__HIP_DEVICE_COMPILE__) || defined(__HIP_PLATFORM_AMD__)
#  if defined(__has_include)
#    if __has_include(<hip/hip_runtime_api.h>)
#      include <hip/hip_runtime_api.h>
#      define CUTE_HAS_HIP_RUNTIME 1
#    elif __has_include(<hip/hip_runtime.h>)
#      include <hip/hip_runtime.h>
#      define CUTE_HAS_HIP_RUNTIME 1
#    endif
#  endif
#else
#  if !defined(__CUDACC_RTC__)
#    if defined(CUTE_ENABLE_CUDA)
#      include <cuda_runtime_api.h>
#      define CUTE_HAS_CUDA_RUNTIME 1
#    elif defined(__CUDACC__) || defined(__CUDA_ARCH__) || defined(_NVHPC_CUDA)
#      include <cuda_runtime_api.h>
#      define CUTE_HAS_CUDA_RUNTIME 1
#    endif
#  endif
#endif

#if !defined(CUTE_HAS_MXMACA_RUNTIME)
#  define CUTE_HAS_MXMACA_RUNTIME 0
#endif

#if !defined(CUTE_HAS_HIP_RUNTIME)
#  define CUTE_HAS_HIP_RUNTIME 0
#endif

#if !defined(CUTE_HAS_CUDA_RUNTIME)
#  define CUTE_HAS_CUDA_RUNTIME 0
#endif
