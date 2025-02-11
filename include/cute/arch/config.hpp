/***************************************************************************************************
 * Copyright (c) 2024 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include <cutlass/arch/config.h> // CUTLASS_ARCH_MMA_SMxx_ENABLED

// TMA instructions
#if defined(CUTLASS_ARCH_MMA_SM90_ENABLED)
#  define CUTE_ARCH_TMA_SM90_ENABLED
#endif

#if defined(CUTLASS_ARCH_MMA_MODIFIABLE_TMA_SM90_ENABLED)
#  define CUTE_ARCH_DEVICE_MODIFIABLE_TMA_SM90_ENABLED
#endif

// STSM
#if defined(CUTLASS_ARCH_MMA_SM90_ENABLED)
#  define CUTE_ARCH_STSM_SM90_ENABLED
#endif

////////////////////////////////////////////////////////////////////////////////////////////////////


#if (defined(CUTLASS_ARCH_MMA_SM100A_ENABLED))
#  define CUTE_ARCH_TMA_SM90_ENABLED
#  define CUTE_ARCH_DEVICE_MODIFIABLE_TMA_SM90_ENABLED
#  define CUTE_ARCH_STSM_SM90_ENABLED
#endif

#if defined(CUTLASS_ARCH_MMA_SM100A_ENABLED)
#  define CUTE_ARCH_TCGEN05_TF32_MMA_ENABLED
#  define CUTE_ARCH_TCGEN05_F16F32_MMA_ENABLED
#  define CUTE_ARCH_TCGEN05_MXF8F6F4_MMA_ENABLED
#  define CUTE_ARCH_TCGEN05_MXF4_MMA_ENABLED
#  define CUTE_ARCH_TCGEN05_MXF4NVF4_MMA_ENABLED
#  define CUTE_ARCH_TCGEN05_F16BF16_MMA_SCALED_ENABLED
#endif

#if defined(CUTLASS_ARCH_MMA_SM100A_ENABLED)
#  define CUTE_ARCH_TCGEN05_S8_MMA_ENABLED
#endif

#if defined(CUTLASS_ARCH_MMA_SM100A_ENABLED)
#  define CUTE_ARCH_LDSM_SM100A_ENABLED
#  define CUTE_ARCH_STSM_SM100A_ENABLED
#endif

#if defined(CUTLASS_ARCH_MMA_SM100A_ENABLED)
#  define CUTE_ARCH_TCGEN05_TMEM_ENABLED
#endif

#if defined(CUTLASS_ARCH_MMA_SM100A_ENABLED)
#  define CUTE_ARCH_TMA_SM100_ENABLED
#endif

// {add, mul, fma}.f32x2 PTX
#if defined(CUTLASS_ARCH_MMA_SM100A_ENABLED)
  #define CUTE_ARCH_FLOAT2_MATH_ENABLED
#endif



