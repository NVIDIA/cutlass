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
 * Abstraction for exposing architecture-specific "dot-product-accumulate"
 * ISA operations
 */

#include <stdint.h>

#include "../util/util.h"


namespace cutlass {
namespace gemm {


/******************************************************************************
 * dp_accummulate
 ******************************************************************************/


/**
 * \brief Abstraction for exposing architecture-specific "dot-product-accumulate"
 * ISA operations
 *
 * Given two K-component vectors a and b having type value_t[K] and an addend c
 * of type accum_t, the "dot-product-accumulate" of type accum_t is computed
 * as d = x[0]*y[0] + x[1]*y[1] + ...  + x[K-1]*y[K-1] + c.
 *
 * We use the notation "dpK" to connote a K-component dot-product-accumulate.
 * For example, "dp1" is a simple multiply-add.
 *
 * For given pairing of value_t and accum_t types, the corresponding
 * dp_accummulate class will:
 *
 * - Define the member-type dp_vector_t as the appropriate K-component vector
 *   type needed to leverage architecture-specific "dot-product accumulate"
 *   ISA operations.
 * - Implement the corresponding dot-product operation between two dp_vector_t
 *   inputs a and b.
 *
 */
template <
    typename value_t,       ///< Component value type
    typename accum_t>       ///< Accumulator value type
struct dp_accummulate;



/// Default "dp1" dot-product-accumulate traits specialization for value_t->accum_t
template <
    typename value_t,       ///< Component value type
    typename accum_t>       ///< Accumulator value type
struct dp_accummulate
{
    /// Single-component "dp1" dot-product vector type
    typedef value_t dp_vector_t;


    /// Compute "dp1" float->float
    inline __device__
    static void mad(
        float &d,
        const float &a,
        const float &b,
        const float &c)
    {
        asm volatile ( "fma.rn.f32 %0, %1, %2, %3;\n"
            : "=f"(d) : "f"(a), "f"(b), "f"(c));
    }


    /// Compute "dp1" double->double
    inline __device__
    static void mad(
        double &d,
        const double &a,
        const double &b,
        const double &c)
    {
        asm volatile ("fma.rn.f64 %0, %1, %2, %3;\n"
            : "=d"(d) : "d"(a), "d"(b), "d"(c));
    }


    /// Compute "dp1" int16_t->int32_t
    inline __device__
    static void mad(
        int32_t &d,
        const int16_t &a,
        const int16_t &b,
        const int32_t &c)
    {
        asm volatile ("mad.wide.s16 %0, %1, %2, %3;\n"
            : "=r"(d) : "h"(a), "h"(b), "r"(c));
    }


    /// Compute "dp1" uint16_t->uint32_t
    inline __device__
    static void mad(
        uint32_t &d,
        const uint16_t &a,
        const uint16_t &b,
        const uint32_t &c)
    {
        asm volatile ("mad.wide.u16 %0, %1, %2, %3;\n"
            : "=r"(d) : "h"(a), "h"(b), "r"(c));
    }


    /// Compute "dp1" int32_t->int32_t
    inline __device__
    static void mad(
        int32_t &d,
        const int32_t &a,
        const int32_t &b,
        const int32_t &c)
    {
        asm volatile ("mad.lo.s32 %0, %1, %2, %3;\n"
            : "=r"(d) : "r"(a), "r"(b), "r"(c));
    }


    /// Compute "dp1" uint32_t->uint32_t
    inline __device__
    static void mad(
        uint32_t &d,
        const uint32_t &a,
        const uint32_t &b,
        const uint32_t &c)
    {
        asm volatile ("mad.lo.u32 %0, %1, %2, %3;\n"
            : "=r"(d) : "r"(a), "r"(b), "r"(c));
    }

};



#if (CUTLASS_ARCH >= 610)   // Specializations only enabled for Pascal SM610+


/// "dp4" dot-product-accumulate traits specialization for int8_t->int32_t
template <>
struct dp_accummulate<
    int8_t,                 ///< Component value type
    int32_t>                ///< Accumulator value type
{
    /// Four-component signed "idp4"
    typedef int32_t dp_vector_t;

    /// Compute "dp4" int16_t->int32_t
    inline __device__
    static void mad(
        int32_t &d,
        const int32_t &a,
        const int32_t &b,
        const int32_t &c)
    {
        asm volatile ( "dp4a.s32.s32 %0, %1, %2, %3;\n"
            : "=r"(d) : "r"(a), "r"(b), "r"(c));
    }
};


/// "dp4" dot-product-accumulate traits specialization for uint8_t->uint32_t
template <>
struct dp_accummulate<
    uint8_t,                ///< Component value type
    uint32_t>               ///< Accumulator value type
{
    /// Four-component unsigned "idp4"
    typedef uint32_t dp_vector_t;

    /// Compute "dp4" uint16_t->uint32_t
    inline __device__
    static void mad(
        uint32_t &d,
        const uint32_t &a,
        const uint32_t &b,
        const uint32_t &c)
    {
        asm volatile ( "dp4a.u32.u32 %0, %1, %2, %3;\n"
            : "=r"(d) : "r"(a), "r"(b), "r"(c));
    }
};


#endif // Specializations only enabled for Pascal SM610+


} // namespace gemm
} // namespace cutlass

