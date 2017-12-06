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
 * block-wide tile-loading abstractions
 */

#include "../util/util.h"

namespace cutlass {
namespace gemm {


/******************************************************************************
 * load_algorithm
 ******************************************************************************/

/**
 * \brief Enumeration of matrix loading algorithms
 */
struct load_algorithm
{
    /// \brief Enumerants.  See corresponding tag types.
    enum kind_t
    {
        CongruousCopy  = 0,
        CrosswiseCopy  = 1,
    };

    /**
     * \brief Generic tag
     */
    template <kind_t Kind>
    struct any_tag : nv_std::integral_constant<kind_t, Kind> {};

    /**
     * \brief Copy from a global matrix that is row-major in relation
     * to the local row-major tile
     */
    typedef any_tag<CongruousCopy> contiguous_tag_t;

    /**
     * \brief Copy from a global matrix that is column-major in relation
     * to the local row-major tile
     */
    typedef any_tag<CrosswiseCopy> crosswise_tag_t;

};


/******************************************************************************
 * block_loader
 ******************************************************************************/

/**
 * \brief A three-phase data loading abstraction (prefetch, commit, and
 * advance) for iterating over ranges of block-wide matrix tiles.
 *
 * Each iteration sequence produces a KxL (height-by-width) block-wide tile of
 * value_t in shared memory. The layout of the shared
 * block-wide tile is a row-major (L-major) tiling of dp_vector_t items, which are
 * themselves column-major (K-major) vectors of value_t.  Its dimensions are:
 *    K = BlockDpVectorsK * (sizeof(dp_vector_t) / sizeof(value_t)
 *    L = BlockDpVectorsL
 *
 * NB: This generic class is not directly constructible.  Architecture- and
 * algorithm-specific template specializations will provide the API
 * functionality prescribed here.
 *
 */
template <
    int BlockThreads,                       ///< Number of threads in each thread block (blockDim.x)
    int BlockDpVectorsK,                    ///< Extent of block-wide tile in dp_vector_t along the K-axis (height)
    int BlockDpVectorsL,                    ///< Extent of block-wide tile in dp_vector_t along the L-axis (width)
    typename value_t,                       ///< Input matrix value type
    int LeadingDimAlignBytes,               ///< Byte alignment of input matrix leading dimension
    bool AllowRaggedTiles,                  ///< Whether the input matrix's dimensions need not be an even-multiple of the block-wide tile dimensions
    typename dp_vector_t,                   ///< Dot-product vector type along the K-axis
    load_algorithm::kind_t LoadAlgorithm>   ///< Algorithm for loading a shared tile of KxL matrix data
struct block_loader
{
    //-------------------------------------------------------------------------
    // Constructor API
    //-------------------------------------------------------------------------

    /// Constructor
    block_loader(
        value_t *d_matrix,              ///< Pointer to input matrix
        int matrix_values_l,            ///< Extent of the input matrix in value_t along the L-axis
        int matrix_values_stride_k,     ///< Distance in value_t within pitched-linear memory between successive coordinates along the K-axis
        int matrix_values_stride_l,     ///< Distance in value_t within pitched-linear memory between successive coordinates along the L-axis
        int2 block_begin_item_coords,   ///< Thread block's starting value_t coordinates (l, k) within the input matrix
        int block_end_item_k);          ///< Thread block's ending coordinate (k) within the input matrix (one-past)

    //-------------------------------------------------------------------------
    // Loader API
    //-------------------------------------------------------------------------

    /**
     * Request the current block-wide tile
     */
    void request();


    /**
     * Advance the loader to the next block-wide tile in the K-axis
     */
    void next();


    /**
     * Commit the previously-requested block-wide tile to shared memory
     *
     * NB: To facilitate padding for avoiding shared memory bank conflicts, we
     * allow the row stride _BlockDpVectorsL to be arbitrarily bigger than the
     * tile width BlockDpVectorsL.
     */
    template <int _BlockDpVectorsL>
    void commit(
        dp_vector_t (&scratch_tile)[BlockDpVectorsK][_BlockDpVectorsL]);

};


} // namespace gemm
} // namespace cutlass


/******************************************************************************
 * Tail-include specializations that adhere to the block_loader API
 ******************************************************************************/

#include "block_loader_crosswise.h"
#include "block_loader_congruous_dp1.h"
#include "block_loader_congruous_idp4.h"
