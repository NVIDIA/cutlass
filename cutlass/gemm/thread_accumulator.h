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
 * Thread-level multiply-accumulate abstraction
 */

#include "../util/util.h"
#include "dp_accummulate.h"


namespace cutlass {
namespace gemm {


/******************************************************************************
 * thread_accumulator (generic specialization)
 ******************************************************************************/

/**
 * \brief Thread-level multiply-accumulate abstraction (generic specialization)
 *
 * The thread_accumulator class maintains a MxN tile of accumulators in
 * registers to which MxNxK matrix products of two thread tiles A (MxK)
 * and B (KxN) can be added, where:
 *   M = ThreadItemsY
 *   N = ThreadItemsX
 *   K = sizeof(dp_vector_t) / sizeof(value_t).
 *
 * In order to leverage architecture-specific "dot-product accumulate" ISA
 * operations, K is dictated by the thread_accumulator class in the form of
 * the member-type dp_vector_t, which defines a K-component vector of value_t.
 * The multiplicand inputs A and B are provided as arrays of dp_vector_t having
 * extents ThreadItemsY and ThreadItemsX, respectively. (In the single
 * component "dp1" scenario where dp_vector_t == value_t and thus K == 1, the
 * multiplication is simply the outer product of two vectors.)
 *
 * The accumulators are zero-initialized in a two-phase process (construction +
 * initialization) that requires shared storage in the form of the member-type
 * scratch_storage_t during construction. (A single scratch_storage_t instance
 * can be uniformly referenced across all threads in the block during
 * construction *if* the block is synchronized between construction and
 * initialization.)
 *
 * NB: This generic class is not directly constructible.  Architecture- and
 * algorithm-specific template specializations will provide the API
 * functionality prescribed here.
 */
template <
    int ThreadItemsY,                   ///< Height of thread tile in accum_t
    int ThreadItemsX,                   ///< Width of thread tile in accum_t
    typename value_t,                   ///< Multiplicand value type
    typename accum_t,                   ///< Accumulator value type
    int ACCUM_BYTES =                   ///< Size in bytes of accum_t
        sizeof(accum_t),
    arch_family_t::kind_t ArchFamily =  ///< Architectural family enumerant
        CUTLASS_ARCH_FAMILY>
struct thread_accumulator
{
protected:

    //-------------------------------------------------------------------------
    // Constants and types
    //-------------------------------------------------------------------------

    /// Specialized dot-product traits type
    typedef dp_accummulate<value_t, accum_t> dp_accum_traits_t;


public:

    //-------------------------------------------------------------------------
    // Member types
    //-------------------------------------------------------------------------

    /// Dot-product vector type
    typedef typename dp_accum_traits_t::dp_vector_t dp_vector_t;

    /// Scratch storage layout
    struct scratch_storage_t {};


protected:

    //-------------------------------------------------------------------------
    // Data members
    //-------------------------------------------------------------------------

    /// Thread's tile of accumulators
    accum_t accumulators[ThreadItemsY][ThreadItemsX];


    //-------------------------------------------------------------------------
    // Utility methods
    //-------------------------------------------------------------------------

    /**
     * Compute a multiply-add at accumulator coordinates (x, y)
     */
    inline __device__
    void mad_xy(
        dp_vector_t (&tile_a)[ThreadItemsY],
        dp_vector_t (&tile_b)[ThreadItemsX],
        int x,
        int y)
    {
        dp_accum_traits_t::mad(
            accumulators[y][x],
            tile_a[y],
            tile_b[x],
            accumulators[y][x]);
    }

public:

    //-------------------------------------------------------------------------
    // Constructor API
    //-------------------------------------------------------------------------

    /// Constructor
    inline __device__
    thread_accumulator(
        scratch_storage_t &scratch)
    {}


    //-------------------------------------------------------------------------
    // Accumulator API
    //-------------------------------------------------------------------------

    /**
     * \brief Zero-initialize thread accumulators.
     *
     * If a common reference to a single block-wide shared instance of scratch_storage_t
     * is used during construction, the block must be synchronized after construction
     * but prior to the invocation of init().
     */
    inline __device__
    void init()
    {
        #pragma unroll
        for (int y = 0; y < ThreadItemsY; ++y) {
            #pragma unroll
            for (int x = 0; x < ThreadItemsX; ++x)
            {
                accumulators[y][x] = accum_t(0);
            }
        }
    }


    /**
     * Retrieve the accumulator at thread tile coordinates (x, y)
     */
    inline __device__
    accum_t get(int x, int y)
    {
        // Accumulators are row-major
        return accumulators[y][x];
    }


    /**
     * \brief Compute the product of tile_a and tile_b and add the result to
     * the tile of accumulators.
     */
    inline __device__
    void multiply_accumulate(
        dp_vector_t (&tile_a)[ThreadItemsY],
        dp_vector_t (&tile_b)[ThreadItemsX])
    {
        // Simply traverse the accumulator tile in row-major order
        #pragma unroll
        for (int y = 0; y < ThreadItemsY; ++y)
        {
            #pragma unroll
            for (int x = 0; x < ThreadItemsX; ++x)
            {
                mad_xy(tile_a, tile_b, x, y);
            }
        }
    }
};




/******************************************************************************
 * thread_accumulator (__half->__half specialization)
 ******************************************************************************/

/**
 * \brief Thread-level multiply-accumulate abstraction (__half->__half specialization)
 *
 * NB: Because we use the 2-item SIMD instruction HFMA2:
 *   - ThreadItemsX must be an even multiple of 2
 *   - ThreadItemsY must be an even multiple of 2
 *
 */
template <
    int ThreadItemsY,                   ///< Height in rows of thread tile in C
    int ThreadItemsX,                   ///< Width in columns of thread tile in C
    arch_family_t::kind_t ArchFamily>   ///< Architectural family enumerant
struct thread_accumulator<
    ThreadItemsY,
    ThreadItemsX,
    __half,                             ///< Multiplicand value type (matrices A and B)
    __half,                             ///< Accumulator value type (matrix C and scalars)
    2,                                  ///< Size in bytes of accum_t
    ArchFamily>
{
protected:

    //-------------------------------------------------------------------------
    // Constants and types
    //-------------------------------------------------------------------------

    /// Constants
    enum
    {
        /// Height of thread tile in column-major uint32_t SIMD pairs along Y dimension
        ThreadTilePairsY = divide_assert<ThreadItemsY, 2>::value,

        /// Width of thread tile in column-major uint32_t SIMD pairs along X dimension
        ThreadTilePairsX = ThreadItemsX,

        /// Number of SIMD pairs in thread's slice of block-wide tile multiplicand A
        ThreadPairsA = divide_assert<ThreadItemsY, 2>::value,

        /// Number of SIMD pairs in thread's slice of block-wide tile multiplicand B
        ThreadPairsB = divide_assert<ThreadItemsX, 2>::value,
    };

public:

    //-------------------------------------------------------------------------
    // Member types
    //-------------------------------------------------------------------------

    /// Dot-product vector type
    typedef __half dp_vector_t;

    /// Scratch storage layout
    struct scratch_storage_t {};


private:

    //-------------------------------------------------------------------------
    // Members
    //-------------------------------------------------------------------------

    /// Thread's tile of C accumulator pairs (the uint32_t SIMD pairs are
    /// column-major, the 2D tile layout is also column-major)
    uint32_t accumulator_pairs[ThreadTilePairsX][ThreadTilePairsY];


    //-------------------------------------------------------------------------
    // Utility methods
    //-------------------------------------------------------------------------

    /**
     * Compute an HFMA2 MAD
     */
    inline __device__ void mad(
        uint32_t &d,
        const uint32_t &a,
        const uint32_t &b,
        const uint32_t &c)
    {

        asm volatile ("fma.rn.f16x2 %0, %1, %2, %3;\n"
            : "=r"(d) : "r"(a), "r"(b), "r"(c));
    }


    /**
     * Compute an HFMA2 MAD with replicated b.lo:
     *   d{hi} = a{hi} * b{lo} + c{hi};
     *   d{lo} = a{lo} * b{lo} + c{lo};
     */
    inline __device__ void mad_replicate_low(
        uint32_t &d,
        const uint32_t &a,
        const uint32_t &b,
        const uint32_t &c)
    {
        // Replicate low halves of b
        uint32_t replicate;
        asm volatile (
            "{"
            "  .reg .b16 b_low,b_high;\n"
            "  mov.b32 {b_low,b_high}, %1;\n"
            "  mov.b32 %0, {b_low,b_low};\n"
            "}" : "=r"(replicate) : "r"(b));

        mad(d, a, replicate, c);
    }


    /**
     * Compute an HFMA2 MAD with replicated b.hi:
     *   d{hi} = a{hi} * b{hi} + c{hi};
     *   d{lo} = a{lo} * b{hi} + c{lo};
     */
    inline __device__ void mad_replicate_high(
        uint32_t &d,
        const uint32_t &a,
        const uint32_t &b,
        const uint32_t &c)
    {
        // Replicate high halves of b
        uint32_t replicate;
        asm volatile (
            "{"
            "  .reg .b16 b_low,b_high;\n"
            "  mov.b32 {b_low,b_high}, %1;\n"
            "  mov.b32 %0, {b_high,b_high};\n"
            "}" : "=r"(replicate) : "r"(b));

        mad(d, a, replicate, c);
    }


    /**
     * Compute a multiply-add at accumulator SIMD-pair coordinates (pair_x, pair_y)
     */
    inline __device__
    void mad_xy_even(
        uint32_t (&pairs_tile_a)[ThreadPairsA],
        uint32_t (&pairs_tile_b)[ThreadPairsB],
        int pair_x,
        int pair_y)
    {
        // Even column: use low half of the b pair
        mad_replicate_low(
            accumulator_pairs[pair_x][pair_y],
            pairs_tile_a[pair_y],
            pairs_tile_b[pair_x / 2],
            accumulator_pairs[pair_x][pair_y]);
    }


    /**
     * Compute a multiply-add at accumulator SIMD-pair coordinates (pair_x, pair_y)
     */
    inline __device__
    void mad_xy_odd(
        uint32_t (&pairs_tile_a)[ThreadPairsA],
        uint32_t (&pairs_tile_b)[ThreadPairsB],
        int pair_x,
        int pair_y)
    {
        // Odd column: use high half of the b pair
        mad_replicate_high(
            accumulator_pairs[pair_x][pair_y],
            pairs_tile_a[pair_y],
            pairs_tile_b[pair_x / 2],
            accumulator_pairs[pair_x][pair_y]);
    }


public:

    //-------------------------------------------------------------------------
    // Constructor API
    //-------------------------------------------------------------------------

    /// Constructor
    inline __device__
    thread_accumulator(
        scratch_storage_t &scratch)
    {}


    //-------------------------------------------------------------------------
    // Accumulator API
    //-------------------------------------------------------------------------

    /**
     * Zero-initialize thread accumulators.
     */
    inline __device__
    void init()
    {
        #pragma unroll
        for (int y = 0; y < ThreadTilePairsY; ++y)
        {
            #pragma unroll
            for (int x = 0; x < ThreadTilePairsX; ++x)
            {
                accumulator_pairs[x][y] = 0;
            }
        }
    }


    /**
     * Retrieve the accumulator at thread tile coordinates (x, y)
     */
    inline __device__
    __half get(int x, int y)
    {
        // SIMD pairs are column-major
        uint32_t pair = accumulator_pairs[x][y / 2];

        return reinterpret_cast<__half (&)[2]>(pair)[y % 2];
    }


    /**
     * \brief Compute the product of pairs_tile_a and pairs_tile_b and add the result to
     * the tile of accumulators.
     */
    inline __device__
    void multiply_accumulate(
        dp_vector_t (&tile_a)[ThreadItemsY],
        dp_vector_t (&tile_b)[ThreadItemsX])
    {
        typedef uint32_t pairs_tile_a_t[ThreadPairsA];
        typedef uint32_t pairs_tile_b_t[ThreadPairsB];

        // Alias slices in pairs
        pairs_tile_a_t &pairs_tile_a = reinterpret_cast<pairs_tile_a_t&>(tile_a);
        pairs_tile_b_t &pairs_tile_b = reinterpret_cast<pairs_tile_b_t&>(tile_b);

        // Simply traverse the accumulator tile in column-major order
        #pragma unroll
        for (int x = 0; x < ThreadTilePairsX; ++x)
        {
            #pragma unroll
            for (int y = 0; y < ThreadTilePairsY; ++y)
            {
                mad_xy_even(pairs_tile_a, pairs_tile_b, x, y);
            }
        }
    }
};


} // namespace gemm
} // namespace cutlass
