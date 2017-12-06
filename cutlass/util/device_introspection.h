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
 * \brief Utilities for device introspection
 */

#include "debug.h"
#include "nv_std.h"
#include "printable.h"

namespace cutlass {


/******************************************************************************
 * math_operation_class_t
 *
 * Enumeration to select the appropriate math operation
 *
 * The assumption is multiple math operations may be used to compute GEMM
 * for a given selection of operand and accumulator types.
 *
 ******************************************************************************/

/// Math operation
enum class math_operation_class_t
{
    scalar,                     // scalar (and vector) multiply-accumulate operations
    matrix                      // Volta tensor operations
};

/******************************************************************************
 * arch_family_t
 ******************************************************************************/

/**
 * \brief Enumeration of NVIDIA GPU architectural families
 */
struct arch_family_t
{
    /// \brief Enumerants
    enum kind_t
    {
        Unsupported     = 0,
        Kepler      = 3,
        Maxwell     = 5,
        Volta       = 7,
    };

    /// Enumerant value
    kind_t kind;

    /// Default constructor
    arch_family_t() : kind(Unsupported) {}

    /// Copy constructor
    arch_family_t(const kind_t &other_kind) : kind(other_kind) {}

    /// Cast to kind_t
    operator kind_t() const { return kind; }

    /// Returns the instance as a string
    __host__ __device__ inline
    char const* to_string() const
    {
        switch (kind)
        {
            case Kepler:    return "Kepler";
            case Maxwell:   return "Maxwell";
            case Volta:     return "Volta";
            case Unsupported:
            default: return "Unsupported";
        }
    }

    /// Insert the formatted instance into the output stream
    void print(std::ostream& out) const { out << to_string(); }

};


/**
 * Macro for architecture targeted by the current compiler pass
 */
#if defined(__CUDA_ARCH__)
    #define CUTLASS_ARCH __CUDA_ARCH__
#else
    #define CUTLASS_ARCH 0
#endif


/**
 * Macro for architecture family targeted by the current compiler pass
 */
#define CUTLASS_ARCH_FAMILY                         \
    (                                               \
        (CUTLASS_ARCH < 300) ?                      \
            arch_family_t::Unsupported :            \
            (CUTLASS_ARCH < 500) ?                  \
                arch_family_t::Kepler :             \
                (CUTLASS_ARCH < 700) ?              \
                    arch_family_t::Maxwell :        \
                    arch_family_t::Volta            \
    )




/******************************************************************************
 * Device introspection
 ******************************************************************************/

/**
 * Empty kernel for querying PTX manifest metadata (e.g., version) for the current device
 */
template <typename T>
__global__ void empty_kernel(void) { }



/**
 * \brief Retrieves the PTX version that will be used on the current device (major * 100 + minor * 10)
 */
cudaError_t ptx_version(int &version)
{
    struct Dummy
    {
        /// Type definition of the empty_kernel kernel entry point
        typedef void (*EmptyKernelPtr)();

        /// Force empty_kernel<void> to be generated if this class is used
        EmptyKernelPtr Empty()
        {
            return empty_kernel<void>;
        }
    };

    cudaError_t error = cudaSuccess;
    do
    {
        cudaFuncAttributes empty_kernel_attrs;
        if (CUDA_PERROR_DEBUG(error = cudaFuncGetAttributes(&empty_kernel_attrs, empty_kernel<void>))) break;
        version = empty_kernel_attrs.ptxVersion * 10;
    }
    while (0);

    return error;
}


/**
 * \brief Retrieves the SM version (major * 100 + minor * 10) for the current device
 */
cudaError_t get_sm_version(int &sm_version)
{
    cudaError_t error = cudaSuccess;

    // Get device ordinal
    int device_ordinal;
    if (CUDA_PERROR_DEBUG(error = cudaGetDevice(&device_ordinal)))
        return error;

    // Fill in SM version
    int major, minor;
    if (CUDA_PERROR_DEBUG(error = cudaDeviceGetAttribute(&major, cudaDevAttrComputeCapabilityMajor, device_ordinal)))
        return error;
    if (CUDA_PERROR_DEBUG(error = cudaDeviceGetAttribute(&minor, cudaDevAttrComputeCapabilityMinor, device_ordinal)))
        return error;
    sm_version = major * 100 + minor * 10;

    return error;
}


/**
 * \brief Retrieves the count for the current device
 */
cudaError_t get_sm_count(int &sm_count)
{
    cudaError_t error = cudaSuccess;

    // Get device ordinal
    int device_ordinal;
    if (CUDA_PERROR_DEBUG(error = cudaGetDevice(&device_ordinal)))
        return error;

    // Get SM count
    if (CUDA_PERROR_DEBUG(error = cudaDeviceGetAttribute (&sm_count, cudaDevAttrMultiProcessorCount, device_ordinal)))
        return error;

    return error;
}


} // namespace cutlass


