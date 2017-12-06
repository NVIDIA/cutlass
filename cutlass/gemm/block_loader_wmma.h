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
 * Tile-loading abstraction for thread blocks
 */

#include "../util/util.h"

namespace cutlass {
namespace gemm {


/**
 * block-wide tile loader supporting congruous mapping of data from source and
 * destination addressable storage. Typically, this will be used to load a
 * block-wide tile from global memory into shared memory.
 *
 * This enables the caller to specify MatrixAlignBytes guarantees of the input pointer
 * and performs memory operations on vectors. This increases the efficiency of
 * memory operations and reduces the number of guard predicates needed.
 *
 */
template <
    bool congruous,         ///< Indicates whether the "GEMM K" dimension refers to strided matrix dimension
    int BlockThreads,       ///< Number of threads participating in the streaming operation
    int BlockItemsL,       ///< Extent of block-wide tile in value_t along the L-axis (width)
    int BlockItemsK,        ///< Extent of block-wide tile in value_t along the K-axis (height)
    typename value_t,       ///< Input matrix value type
    int MatrixAlignBytes,   ///< Byte alignment of input matrix
    bool AllowRaggedTiles   ///< Whether the input matrix's dimensions need not be an even-multiple of the block-wide tile dimensions
>
struct block_loader_wmma
{
    //-------------------------------------------------------------------------
    // Constants and types
    //-------------------------------------------------------------------------

    /// Predicate bit vector
    typedef uint64_t predicate_mask_t;

    /// Data movement type, coarsened by MatrixAlignBytes
    typedef io_vector<
            value_t,
            divide_assert<MatrixAlignBytes, sizeof(value_t)>::value,
            MatrixAlignBytes>
        ldg_vector_t;

    enum
    {
        /// Number of items per ldg_vector_t
        LdgVectorItems = ldg_vector_t::VectorItems,

        /// Total number of ldg_vector_t within the block-wide tile
        BlockLdgVectors = divide_assert<(BlockItemsL * BlockItemsK), LdgVectorItems>::value,

        /// Extent of the block-wide tile in ldg_vector_t along K-axis
        BlockLdgVectorsK = BlockItemsK,

        /// Extent of the block-wide tile in ldg_vector_t along L-axis
        BlockLdgVectorsL = divide_assert<BlockItemsL, LdgVectorItems>::value,

        /// Number of ldg_vector_t within each thread tile
        ThreadLdgVectors = divide_assert<BlockLdgVectors, BlockThreads>::value,

        /// Extent of the thread tile in ldg_vector_t along the L-axis
        ThreadLdgVectorsL = __NV_STD_MAX(1, BlockLdgVectorsL / BlockThreads),

        /// Block-wide strip-mining distance between ldg_vector_t along the K-axis
        BlockLdgVectorStrideK = __NV_STD_MAX(1, BlockThreads / BlockLdgVectorsL),

        /// Extent of the thread tile in ldg_vector_t along the K-axis
        ThreadLdgVectorsK = divide_assert<BlockLdgVectorsK, BlockLdgVectorStrideK>::value,
    };


    //-------------------------------------------------------------------------
    // Assert assumptions
    //-------------------------------------------------------------------------

    /// Define assertions
    static_assert(ThreadLdgVectorsL * ThreadLdgVectorsK == ThreadLdgVectors,
        "Number of vectors must be fully covered by the thread's 2D vector tile.");

    /// Predicate masks must be large enough to guard every vector load
    static_assert(sizeof(predicate_mask_t) * 8 >= ThreadLdgVectorsL * ThreadLdgVectorsK,
        "Predicate bit vector must be large enough to guard every vector load.");

    //-------------------------------------------------------------------------
    // Members
    //-------------------------------------------------------------------------

    /// pointer to tile in global memory
    const ldg_vector_t *ptr;

    /// stride of the matrix in the K-axis
    int matrix_values_stride_k;

    /// Guard predicate
    predicate_mask_t guard;

    /// Guard for the last request iteration
    predicate_mask_t residue_guard;

    /// Number of 'whole' request iterations before encountering the residue
    int request_iterations;

    /// fetch registers
    ldg_vector_t fetch[ThreadLdgVectors];

    /// Thread's base offset from the start of a block-wide tile
    int thread_offset_l;

    /// Thread's basae offset from the start of a block-wide tile
    int thread_offset_k;


    //-------------------------------------------------------------------------
    // Constructor API
    //-------------------------------------------------------------------------

    /// Constructor
    inline __device__
    block_loader_wmma(
        const value_t *d_matrix,        ///< Pointer to input matrix
        int matrix_values_l,            ///< Extent of the input matrix in value_t along the L-axis
        int start_l,                    ///< Starting location in tile
        int dim_k,                      ///< Inner dimension of tile, used for computing guard predicates
        int _matrix_values_stride_k,    ///< Stride of K-axis of atrix
        int start_k,                    ///< Tile's starting location
        int2 block_begin_item_coords)  ///< Thread block's starting value_t coordinates (l, k) within the input matrix
    :
        ptr(reinterpret_cast<const ldg_vector_t *>(d_matrix)),
        matrix_values_stride_k(_matrix_values_stride_k / LdgVectorItems),
        guard(0),
        residue_guard(0)
    {
        // Compute block's starting coordinates in units of vectors
        int block_base_l = block_begin_item_coords.x / LdgVectorItems;
        int block_base_k = block_begin_item_coords.y;

        // Compute a thread tiling of the block-wide tile
        int tid = threadIdx.x;
        thread_offset_l = tid % BlockLdgVectorsL;
        thread_offset_k = tid / BlockLdgVectorsL;

        // Add the block and thread offsets to the source pointer
        ptr += (block_base_l + thread_offset_l) +
            (block_base_k + thread_offset_k) * matrix_values_stride_k;

        // When AllowRaggedTiles support is enabled, compute a bit vector of guard
        // predicates
        if (AllowRaggedTiles)
        {
            if (congruous)
            {
                request_iterations = (dim_k - start_k) / BlockItemsK;
            }
            else
            {
                request_iterations = (matrix_values_l - start_l) / BlockItemsL;
            }

            #pragma unroll
            for (int k_idx = 0; k_idx < ThreadLdgVectorsK; ++k_idx)
            {
                #pragma unroll
                for (int l_idx = 0; l_idx < ThreadLdgVectorsL; ++l_idx)
                {
                    int item = l_idx + k_idx * ThreadLdgVectorsL;

                    // Global vector L and K indices
                    int vec_l = l_idx * BlockThreads;
                    int vec_k = k_idx * BlockLdgVectorStrideK;

                    predicate_mask_t pred;
                    predicate_mask_t residue_pred;

                    if (congruous)
                    {
                        pred = (((block_base_l + thread_offset_l + vec_l) * LdgVectorItems < matrix_values_l) ? 1 : 0);
                        residue_pred = ((block_base_k + thread_offset_k + vec_k < (dim_k % BlockItemsK)) ? 1 : 0);
                    }
                    else
                    {
                        pred = ((block_base_k + thread_offset_k + vec_k < dim_k) ? 1 : 0);
                        residue_pred = (((block_base_l + thread_offset_l + vec_l) * LdgVectorItems < (matrix_values_l % BlockItemsL)) ? 1 : 0);
                    }

                    // Update the guard and residue_guard word with predicate bits
                    guard |= (pred << item);
                    residue_guard |= (residue_pred << item);
                }
            }

            // If there are zero full request iterations, compute the intersection
            // with the residue guard.
            if (!request_iterations)
            {
                guard &= residue_guard;
            }
        }
    }



    /**
     * Request the current block-wide tile from source memory
     */
    inline __device__
    void request()
    {
        #pragma unroll
        for (int k_idx = 0; k_idx < ThreadLdgVectorsK; ++k_idx)
        {
            #pragma unroll
            for (int l_idx = 0; l_idx < ThreadLdgVectorsL; ++l_idx)
            {
                int load_idx = l_idx + (k_idx * ThreadLdgVectorsL);
                bool pred = !AllowRaggedTiles || (guard & (predicate_mask_t(1) << load_idx));
                if (pred)
                {
                    fetch[load_idx].load(
                        ptr +
                        (k_idx * BlockLdgVectorStrideK * matrix_values_stride_k) + (l_idx * BlockThreads));
                }
                else
                {
                    #pragma unroll
                    for (int elem_idx = 0; elem_idx < LdgVectorItems; ++elem_idx)
                    {
                        fetch[load_idx].buff[elem_idx] = 0;
                    }
                }
            }
        }
    }


    /// Advance to the next block-wide tile
    inline __device__
    void next()
    {
        if (congruous)
        {
            ptr += BlockItemsK * matrix_values_stride_k;
        }
        else
        {
            ptr += BlockLdgVectorsL;
        }

        // Track number of full iterations to intersect with the residue guard predicates.
        if (AllowRaggedTiles)
        {
            --request_iterations;
            if (!request_iterations)
            {
                guard &= residue_guard;
            }
        }
    }


    /// Commit the values to the scratch tile to destination memory.
    template <int SmemStride>
    inline __device__
    void commit(value_t *scratch_tile)
    {
        static_assert(SmemStride % LdgVectorItems == 0,
            "SMEM stride must be divisible by the size of vector loads");

        ldg_vector_t *smem_ptr = reinterpret_cast<ldg_vector_t *>(scratch_tile);
        smem_ptr += thread_offset_l + thread_offset_k * SmemStride / LdgVectorItems;

        #pragma unroll
        for (int k_idx = 0; k_idx < ThreadLdgVectorsK; ++k_idx)
        {
            #pragma unroll
            for (int l_idx = 0; l_idx < ThreadLdgVectorsL; ++l_idx)
            {
                int load_idx = l_idx + (k_idx * ThreadLdgVectorsL);

                fetch[load_idx].store(smem_ptr +
                    (k_idx * BlockLdgVectorStrideK * SmemStride / LdgVectorItems) +
                    (l_idx * BlockThreads));
            }
        }
    }
};


} // namespace gemm
} // namespace cutlass

