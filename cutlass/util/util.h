/******************************************************************************
 * Copyright (c) 2017, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 ******************************************************************************/

#pragma once

/**
 * \file
 * \brief Umbrella header file for utilities
 */

#include "debug.h"
#include "device_introspection.h"
#include "io_intrinsics.h"
#include "math.h"
#include "nv_std.h"
#include "printable.h"
#include "matrix_transform.h"



namespace cutlass {


/******************************************************************************
 * int_constant
 ******************************************************************************/

/**
 * Shorthand for nv_std::integral_constant of int32_t type
 */
template <int V>
struct int_constant : nv_std::integral_constant<int32_t, V>
{};


/******************************************************************************
 * Uninitialized
 ******************************************************************************/

/**
 * \brief A storage-backing wrapper that allows types with non-trivial constructors to be aliased in unions
 */
template <typename T>
struct __align__(16) uninitialized
{
    /// Backing storage
    uint8_t storage[sizeof(T)];

    /// Alias
    __host__ __device__ __forceinline__ T& alias()
    {
        return reinterpret_cast<T&>(*this);
    }
};



} // namespace cutlass
