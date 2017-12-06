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
 * (Volta 4B accum_t specialization)
 */

#include <mma.h>

#include "../util/util.h"
#include "dp_accummulate.h"

namespace cutlass {
namespace gemm {


/*!
 *\brief  matrix_layout to perform conversion between Cutlass types and WMMA types
 */
template <matrix_transform_t::kind_t>
struct matrix_layout;

/// Maps matrix_transform_t::NonTranspose to nvcuda::wmma::mem_col_major
template <>
struct matrix_layout<matrix_transform_t::NonTranspose>
{
    /// Type tag in nvcuda::wmma namespace
    typedef nvcuda::wmma::col_major tag;

    /// Column major layout
    static const nvcuda::wmma::layout_t kind = nvcuda::wmma::mem_col_major;

    /// Cutlass matrix transform kind
    static const matrix_transform_t::kind_t cutlass_kind = matrix_transform_t::NonTranspose;
};

/// Maps matrix_transform_t::NonTranspose to nvcuda::wmma::mem_row_major
template <>
struct matrix_layout<matrix_transform_t::Transpose>
{
    /// Type tag in nvcuda::wmma namespace
    typedef nvcuda::wmma::row_major tag;

    /// Column major layout
    static const nvcuda::wmma::layout_t kind = nvcuda::wmma::mem_row_major;

    /// Cutlass matrix transform kind
    static const matrix_transform_t::kind_t cutlass_kind = matrix_transform_t::Transpose;
};

/*!
 * \brief Warp-synchronous matrix multiply-accumulate abstraction
 *
 * wmma_accumulator maps the CUDA WMMA API onto the GEMM structure
 */
template <
    int WarpItemsY,                         /// Number of rows of the warp's accumulator tile
    int WarpItemsX,                         /// Number of columns of the warp's accumulator tile
    int WmmaItemsY,                         /// Number of rows in a single WMMA operation
    int WmmaItemsX,                         /// Number of columns in a single WMMA operation
    int WmmaItemsK,                         /// Inner dimension of WMMA operation
    typename value_a_t,                     /// Type of A operand
    typename value_b_t,                     /// Type of B operand
    typename accum_t,                       /// Type of source and destination accumulators
    matrix_transform_t::kind_t TransformA,  /// Layout of A operand
    matrix_transform_t::kind_t TransformB   /// Layout of B operand
>
struct wmma_accumulator
{
public:

    //-------------------------------------------------------------------------
    // Constants and types
    //-------------------------------------------------------------------------

    enum
    {
        /// Number of WMMA blocks in warp row
        WmmaBlocksX = divide_assert<WarpItemsX, WmmaItemsX>::value,

        /// Number of WMMA blocks in a warp column
        WmmaBlocksY = divide_assert<WarpItemsY, WmmaItemsY>::value,
    };

    /// Fragment type for matrix operand A
    typedef nvcuda::wmma::fragment<
            nvcuda::wmma::matrix_a,
            WmmaItemsY,
            WmmaItemsX,
            WmmaItemsK,
            value_a_t,
            typename matrix_layout<TransformA>::tag>
        fragment_a_t;

    /// Fragment type for matrix operand B
    typedef nvcuda::wmma::fragment<
            nvcuda::wmma::matrix_b,
            WmmaItemsY,
            WmmaItemsX,
            WmmaItemsK,
            value_b_t,
            typename matrix_layout<TransformB>::tag>
        fragment_b_t;

    /// Fragment type for accumulator
    typedef nvcuda::wmma::fragment<
            nvcuda::wmma::accumulator,
            WmmaItemsY,
            WmmaItemsX,
            WmmaItemsK,
            accum_t>
        accumulator_t;

    /// Scratch storage layout
    struct scratch_storage_t
    {
        /// Initialization vector
        uint4 zero_slab;
    };

public:
    //-------------------------------------------------------------------------
    // Data members
    //-------------------------------------------------------------------------

    /// Thread's tile of accumulators
    accumulator_t accumulators[WmmaBlocksX][WmmaBlocksY];

public:

    //-------------------------------------------------------------------------
    // Constructor API
    //-------------------------------------------------------------------------

    /// Constructor initializes accumulators to zero
    inline __device__
    wmma_accumulator()
    {
        init();
    }


    //-------------------------------------------------------------------------
    // Accumulator API
    //-------------------------------------------------------------------------

    /**
     * \brief Zero-initialize thread accumulators.
     */
    inline __device__
    void init()
    {
        #pragma unroll
        for (int x = 0; x < WmmaBlocksX; ++x)
        {
            #pragma unroll
            for (int y = 0; y < WmmaBlocksY; ++y)
            {
                nvcuda::wmma::fill_fragment(accumulators[x][y], accum_t(0));
            }
        }
    }

    /**
     * \brief Compute the product of tile_a and tile_b and add the result to
     * the tile of accumulators.
     */
    inline __device__
    void multiply_accumulate(
        fragment_a_t (&tile_a)[WmmaBlocksY],
        fragment_b_t (&tile_b)[WmmaBlocksX])
    {
        #pragma unroll
        for (int x = 0; x < WmmaBlocksX; ++x)
        {
            #pragma unroll
            for (int y = 0; y < WmmaBlocksY; ++y)
            {
                nvcuda::wmma::mma_sync(accumulators[x][y], tile_a[y], tile_b[x], accumulators[x][y]);
            }
        }
    }
};


} // namespace gemm
} // namespace cutlass
