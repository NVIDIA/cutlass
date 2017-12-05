/******************************************************************************
 * Copyright (c) 2011-2017, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are not permitted.
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


/******************************************************************************
 * block_loader (CongruousCopy + idp4 specialization)
 ******************************************************************************/

/**
 * \brief A three-phase data loading abstraction (prefetch, commit, and
 * advance) for iterating over ranges of block-wide matrix tiles.
 * (CongruousCopy + idp4 specialization)
 *
 * Each iteration sequence produces a KxL (height-by-width) block-wide tile of
 * value_t in shared memory. The layout of the shared block-wide tile is
 * a row-major (L-major) tiling of int32_t dp_vector_t, which are themselves
 * column-major (K-major) vectors of int8_t value_t.  Its dimensions are:
 *    K = BlockDpVectorsK * (sizeof(dp_vector_t) / sizeof(value_t)
 *    L = BlockDpVectorsL
 *
 * The data is copied from a corresponding tile of global matrix data whose
 * layout of value_t is also L-major. This constitutes a CongruousCopy between
 * the L-major global tile and the L-major shared tile.
 *
 * NB: The K-major value_t in shared dp_vector_t are imperfectly congruous
 * with the L-major value_t in global memory. As a result, the granularity
 * of data transfer is a "dp-square" of (DpVectorItems * DpVectorItems) values
 * that must be transposed from L-oriented dp_vector_t to K-oriented
 * dp_vector_t prior to commitment.
 *
 * NB: Consecutive threads within a block are mapped in L-major
 * fashion across a first-set of squares within their global tile. Successive
 * sets of squares are then strip-mined as necessary down the K-axis.  These
 * discontiguous squares comprise the thread's "slice" of the block-wide tile.
 */
template <
    int BlockThreads,           ///< Number of threads in each thread block (blockDim.x)
    int _BlockDpVectorsK,        ///< Extent of block-wide tile in dp_vector_t along the K-axis (height)
    int _BlockDpVectorsL,        ///< Extent of block-wide tile in dp_vector_t along the L-axis (width)
    int LeadingDimAlignBytes,   ///< Byte alignment of input matrix leading dimension
    bool AllowRaggedTiles       ///< Whether the input matrix's dimensions need not be an even-multiple of the block-wide tile dimensions
>
struct block_loader<
    BlockThreads,
    _BlockDpVectorsK,
    _BlockDpVectorsL,
    int8_t,                         ///< Input matrix value type (idp4 specialization)
    LeadingDimAlignBytes,
    AllowRaggedTiles,
    int32_t,                        ///< Dot-product vector type along the K-axis (idp4 specialization)
    load_algorithm::CongruousCopy>  ///< Algorithm for loading a shared tile of KxL matrix data (CrosswiseCopy specialization)
{
    //-------------------------------------------------------------------------
    // Constants and types
    //-------------------------------------------------------------------------

    /// Input matrix value type
    typedef int8_t value_t;

    /// Dot-product vector type along the K-axis
    typedef int32_t dp_vector_t;

    enum
    {
        /// Number of value_t in a dp_vector_t
        DpVectorItems = divide_assert<sizeof(dp_vector_t), sizeof(value_t)>::value,

        /// Number of dp_vector_t in a block-wide tile
        BlockDpVectors = _BlockDpVectorsK * _BlockDpVectorsL,

        /// Number of dp_vector_t in a thread-tile
        ThreadDpVectors = divide_assert<BlockDpVectors, BlockThreads>::value,

        /// Number of dp_vector_t in a dp-square
        SquareDpVectors = DpVectorItems,

        /// Number of dp-square tiles in a thread-tile
        ThreadSquares = divide_assert<ThreadDpVectors, SquareDpVectors>::value,

        /// Extent of block-wide tile in transposed dp_vector_t along the K-axis (height)
        BlockTransDpVectorsK = _BlockDpVectorsK * DpVectorItems,

        /// Extent of block-wide tile in transposed dp_vector_t along the L-axis (height)
        BlockTransDpVectorsL = divide_assert<_BlockDpVectorsL, DpVectorItems>::value,


    };

    /// Load-from-global data movement type, coarsened by LeadingDimAlignBytes, capped by the
    /// smaller of either ThreadSquares or BlockTransDpVectorsL
    typedef io_vector<
            dp_vector_t,
            __NV_STD_MIN(ThreadSquares, BlockTransDpVectorsL),
            LeadingDimAlignBytes>
        ldg_vector_t;

    /// Store-to-shared data movement type equivalent to a dp-square
    typedef io_vector<
            dp_vector_t,
            SquareDpVectors>
        sts_vector_t;

    enum
    {
        /// Number of dp_vector_t per ldg_vector_t
        LdgVectorDpVectors = ldg_vector_t::VectorItems,

        /// Number of value_t per ldg_vector_t
        LdgVectorItems = LdgVectorDpVectors * DpVectorItems,



        /// Total number of ldg_vector_t within each block-wide tile
        BlockLdgVectors = divide_assert<BlockDpVectors, LdgVectorDpVectors>::value,

        /// Extent of the block-wide tile in ldg_vector_t along L-axis
        BlockLdgVectorsL = divide_assert<BlockTransDpVectorsL, LdgVectorDpVectors>::value,

        /// Extent of the block-wide tile in ldg_vector_t along K-axis
        BlockLdgVectorsK = BlockTransDpVectorsK,



        /// Number of ldg_vector_t within each thread-tile
        ThreadLdgVectors = divide_assert<BlockLdgVectors, BlockThreads>::value,

        /// Extent of the thread tile in ldg_vector_t along L-axis
        ThreadLdgVectorsL = __NV_STD_MAX(1, (BlockLdgVectorsL / BlockThreads)),

        /// Extent of the thread tile in ldg_vector_t along K-axis
        ThreadLdgVectorsK = divide_assert<ThreadLdgVectors, ThreadLdgVectorsL>::value,

        /// Extent of the thread tile in dp-square tiles along K-axis
        ThreadSquaresK = divide_assert<ThreadLdgVectorsK, SquareDpVectors>::value,



        /// Number of ldg_vector_t within each stripmine-tile
        StripmineLdgVectors = BlockThreads * SquareDpVectors,

        /// Extent of the stripmine tile in ldg_vector_t along L-axis
        StripmineLdgVectorsL = __NV_STD_MIN(BlockLdgVectorsL, BlockThreads),

        /// Extent of the stripmine tile in ldg_vector_t along K-axis
        StripmineLdgVectorsK = divide_assert<StripmineLdgVectors, StripmineLdgVectorsL>::value,

        /// Extent of the stripmine tile in dp-square tiles along K-axis
        StripmineSquaresK = divide_assert<StripmineLdgVectorsK, SquareDpVectors>::value,



        /// Alignment in dp_vector_t along L needed for committing prefetch
        AlignmentDpVectorsL = LdgVectorDpVectors,
    };

    /// Predicate mask type
    typedef uint32_t predicate_mask_t;


    //-------------------------------------------------------------------------
    // Assert assumptions
    //-------------------------------------------------------------------------

    static_assert((LeadingDimAlignBytes >= 4) && (LeadingDimAlignBytes % 4 == 0),
        "Alignment for matrix operands to IGEMM must be a multiple of 4 bytes.");

    static_assert(
        (ThreadLdgVectors <= sizeof(predicate_mask_t) * 8),
        "Predicate mask type does not contain enough bits for encoding load predicates");


    //-------------------------------------------------------------------------
    // Members
    //-------------------------------------------------------------------------

    /// Input pointer to matrix in ldg_vector_t
    ldg_vector_t *d_matrix_ldgvecs;

    /// Extent of the input matrix in ldg_vector_t along the L-axis
    int matrix_ldgvecs_l;

    /// Thread block's ending ldg_vector_t coordinate (k) within the input matrix (one-past)
    int block_end_ldgvec_k;

    /// Predicate bits for guarding ldg_vector_t loads within "whole-k" block-wide tiles
    predicate_mask_t guard;

    /// Predicate bits for guarding ldg_vector_t loads within the final block-wide "residue" tile
    predicate_mask_t residue_guard;

    /// Iteration span in "whole-k" block-wide tiles
    int wholek_tiles_remaining;

    /// Distance in ldg_vector_t within pitched-linear memory between successive coordinates along the K-axis
    int matrix_ldgvec_stride_k;

    /// Distance in ldg_vector_t within pitched-linear memory between successive coordinates along the L-axis
    int matrix_ldgvec_stride_l;

    /// ldg_vector_t coordinates (l, k) of thread-tile within the block-wide tile
    int2 block_thread_ldgvec_coords;

    /// Thread-wide tile of prefetch data
    ldg_vector_t thread_tile[ThreadSquaresK][SquareDpVectors][ThreadLdgVectorsL];



    //-------------------------------------------------------------------------
    // Utility methods
    //-------------------------------------------------------------------------


    /**
     * \brief Byte-permute. Pick four arbitrary bytes from two 32-bit registers, and reassemble them into a 32-bit destination register.  For SM2.0 or later.
     *
     * \par
     * The bytes in the two source registers \p a and \p b are numbered from 0 to 7:
     * {\p b, \p a} = {{b7, b6, b5, b4}, {b3, b2, b1, b0}}. For each of the four bytes
     * {b3, b2, b1, b0} selected in the return value, a 4-bit selector is defined within
     * the four lower "nibbles" of \p index: {\p index } = {n7, n6, n5, n4, n3, n2, n1, n0}
     *
     * \par Snippet
     * The code snippet below illustrates byte-permute.
     * \par
     * \code
     * #include <cub/cub.cuh>
     *
     * __global__ void ExampleKernel(...)
     * {
     *     int a        = 0x03020100;
     *     int b        = 0x07060504;
     *     int index    = 0x00007531;
     *
     *     int selected = prmt(a, b, index);    // 0x07050301
     *
     * \endcode
     *
     */
    inline __device__
    int32_t prmt(int32_t a, int32_t b, unsigned int index)
    {
        int ret;
        asm volatile("prmt.b32 %0, %1, %2, %3;" : "=r"(ret) : "r"(a), "r"(b), "r"(index));
        return ret;
    }


    /**
     * Convert a "dp-square" from L-major to K-major
     */
    inline __device__
    void transpose_dp_square(dp_vector_t (&dp_square)[SquareDpVectors])
    {
        // Transpose dp_vector_t squares
        int32_t y = prmt(dp_square[0], dp_square[1], 0x00007362);
        int32_t w = prmt(dp_square[2], dp_square[3], 0x00007362);
        int32_t x = prmt(dp_square[0], dp_square[1], 0x00005140);
        int32_t z = prmt(dp_square[2], dp_square[3], 0x00005140);

        dp_square[0] = prmt(x, z, 0x00005410);
        dp_square[1] = prmt(x, z, 0x00007632);
        dp_square[2] = prmt(y, w, 0x00005410);
        dp_square[3] = prmt(y, w, 0x00007632);
    }

    //-------------------------------------------------------------------------
    // Constructor API
    //-------------------------------------------------------------------------

    /// Constructor
    inline __device__
    block_loader(
        value_t *d_matrix_items,        ///< Input pointer to matrix in value_t
        int matrix_items_l,             ///< Extent of the input matrix in value_t along the L-axis
        int matrix_items_stride_k,      ///< Distance in value_t within pitched-linear memory between successive coordinates along the K-axis
        int matrix_items_stride_l,      ///< Distance in value_t within pitched-linear memory between successive coordinates along the L-axis
        int2 matrix_block_item_coords,  ///< value_t coordinates (l, k) of first block-wide tile within the input matrix
        int block_end_item_k)           ///< Thread block's ending coordinate (k) within the input matrix (one-past)
    :
        block_end_ldgvec_k(block_end_item_k),
        guard(0),
        residue_guard(0)
    {
        matrix_ldgvecs_l = matrix_items_l / LdgVectorItems;
        matrix_ldgvec_stride_k = matrix_items_stride_k / LdgVectorItems,
        matrix_ldgvec_stride_l = matrix_items_stride_l;

        // ldg_vector_t coordinates (l, k) of thread-tile within the block-wide tile
        block_thread_ldgvec_coords = make_int2(
            threadIdx.x % BlockLdgVectorsL,                      // l-coordinate
            (threadIdx.x / BlockLdgVectorsL) * SquareDpVectors); // k-coordinate

        // ldg_vector_t coordinates (l, k) of first block-wide tile within the input matrix
        int2 matrix_block_ldgvec_coords = make_int2(
            matrix_block_item_coords.x / LdgVectorItems,         // l-coordinate
            matrix_block_item_coords.y);                        // k-coordinate

        // Iteration span in ldg_vector_t
        int span_ldgvec_k = (block_end_item_k - matrix_block_item_coords.y);



        // ldg_vector_t coordinates (l, k) of first thread-tile tile within the input matrix
        int2 matrix_thread_ldgvec_coords = make_int2(
            block_thread_ldgvec_coords.x + matrix_block_ldgvec_coords.x,
            block_thread_ldgvec_coords.y + matrix_block_ldgvec_coords.y);

        // Iteration range in "whole-k" block-wide tiles
        wholek_tiles_remaining = span_ldgvec_k / BlockLdgVectorsK;

        // Extent of final residue-tile in ldg_vector_t along K-axis
        int residue_ldgvecs_k = span_ldgvec_k % BlockLdgVectorsK;

        // Initialize I/O predicates
        if (AllowRaggedTiles)
        {
            // Iterate through rows of squares in thread tile
            #pragma unroll
            for (int thread_square_k = 0; thread_square_k < ThreadSquaresK; ++thread_square_k)
            {
                // Iterate through rows of dp_vector_t in each square
                #pragma unroll
                for (int square_dpvec = 0; square_dpvec < SquareDpVectors; ++square_dpvec)
                {
                    // ldg_vector_t K-coordinate in block-wide tile (K-axis strip-mining of ldg_vector_t within block-tile)
                    int block_ldgvec_k =
                        block_thread_ldgvec_coords.y +
                        (thread_square_k * StripmineLdgVectorsK) +
                        square_dpvec;

                    // Whether block_ldgvec_coords.y is valid in the final residue tile
                    predicate_mask_t valid_k = (block_ldgvec_k < residue_ldgvecs_k);

                    // L-axis strip-mining of block-tile
                    #pragma unroll
                    for (int thread_ldgvec_l = 0; thread_ldgvec_l < ThreadLdgVectorsL; ++thread_ldgvec_l)
                    {
                        // ldg_vector_t L-coordinate in block-wide tile (L-axis strip-mining of ldg_vector_t within block-tile)
                        int block_ldgvec_l = block_thread_ldgvec_coords.x + (thread_ldgvec_l * StripmineLdgVectorsL);

                        // Whether block_ldgvec_coords.x is valid any block-wide tile
                        predicate_mask_t valid_l = (matrix_block_ldgvec_coords.x + block_ldgvec_l < matrix_ldgvecs_l);

                        // Linear index of ldg_vector_t load
                        int ldgvec_idx =
                            (thread_square_k * SquareDpVectors * ThreadLdgVectorsL) +
                            (square_dpvec * ThreadLdgVectorsL) +
                            thread_ldgvec_l;

                        // Set predicate guard bits
                        guard |= (valid_l << ldgvec_idx);
                        residue_guard |= ((valid_l & valid_k) << ldgvec_idx);
                    }
                }
            }

            // Promote residue-guard to primary-guard if no full tiles remain
            if (!wholek_tiles_remaining)
            {
                guard = residue_guard;
            }
        }

        // Update the input pointer to be matrix_thread_ldgvec_coords
        this->d_matrix_ldgvecs =
            reinterpret_cast<ldg_vector_t*>(d_matrix_items) +
            (matrix_thread_ldgvec_coords.y * matrix_ldgvec_stride_k) +
            (matrix_thread_ldgvec_coords.x * matrix_ldgvec_stride_l);
    }


    //-------------------------------------------------------------------------
    // Loader API
    //-------------------------------------------------------------------------

    /**
     * Request the current block-wide tile
     */
    inline __device__
    void request()
    {
        // Each thread iterates through the ldg_vector_t in its thread tile

        // Iterate through rows of squares in thread tile
        #pragma unroll
        for (int thread_square_k = 0; thread_square_k < ThreadSquaresK; ++thread_square_k)
        {
            // Iterate through rows of dp_vector_t in each square
            #pragma unroll
            for (int square_dpvec = 0; square_dpvec < SquareDpVectors; ++square_dpvec)
            {
                // Iterate through ldg_vector_t in each row
                #pragma unroll
                for (int thread_ldgvec_l = 0; thread_ldgvec_l < ThreadLdgVectorsL; ++thread_ldgvec_l)
                {
                    // Linear index of ldg_vector_t load
                    int ldgvec_idx =
                        (thread_square_k * SquareDpVectors * ThreadLdgVectorsL) +
                        (square_dpvec * ThreadLdgVectorsL) +
                        thread_ldgvec_l;

                    // Unpack predicate guard
                    predicate_mask_t valid = ((guard >> ldgvec_idx) & 1);

                    if (!AllowRaggedTiles || valid)
                    {
                        // Perform load
                        thread_tile[thread_square_k][square_dpvec][thread_ldgvec_l].load(
                            d_matrix_ldgvecs +
                            (((thread_square_k * StripmineLdgVectorsK) + square_dpvec) * matrix_ldgvec_stride_k) +
                            (thread_ldgvec_l * StripmineLdgVectorsL * matrix_ldgvec_stride_l));
                    }
                    else
                    {
                        // Zero-initialize
                        #pragma unroll
                        for (int dpvec = 0; dpvec < LdgVectorDpVectors; ++dpvec)
                            thread_tile[thread_square_k][square_dpvec][thread_ldgvec_l].buff[dpvec] = 0;
                    }
                }
            }
        }
    }


    /**
     * Advance the loader to the next block-wide tile in the K-axis
     */
    inline __device__
    void next()
    {
        d_matrix_ldgvecs += (matrix_ldgvec_stride_k * BlockLdgVectorsK);

        if (AllowRaggedTiles)
        {
            --wholek_tiles_remaining;

            // Promote residue-guard to primary-guard if no full tiles remain
            if (!wholek_tiles_remaining)
            {
                guard = residue_guard;
            }
        }
    }


    /**
     * Commit the previously-requested block-wide tile to shared memory
     *
     * NB: To facilitate padding for avoiding shared memory bank conflicts, we
     * allow the row stride SmemDpVectorsL to be arbitrarily bigger than the
     * tile width BlockDpVectorsL.
     */
    template <int SmemDpVectorsL>
    inline __device__
    void commit(
        dp_vector_t (&scratch_tile)[_BlockDpVectorsK][SmemDpVectorsL])
    {
        static_assert(SmemDpVectorsL >= _BlockDpVectorsL, "Row stride must be >= tile width.");

        // Square K-coordinate of thread tile in block-wide tile
        int block_thread_square_k = block_thread_ldgvec_coords.y / SquareDpVectors;

        // Iterate through rows of squares in thread tile
        #pragma unroll
        for (int thread_square_k = 0; thread_square_k < ThreadSquaresK; ++thread_square_k)
        {
            // Square K-coordinate in block-wide tile (K-axis strip-mining of squares within block-tile)
            int block_square_k = block_thread_square_k + (thread_square_k * StripmineSquaresK);

            // Iterate through ldg_vector_t in each row
            #pragma unroll
            for (int thread_ldgvec_l = 0; thread_ldgvec_l < ThreadLdgVectorsL; ++thread_ldgvec_l)
            {
                // ldg_vector_t L-coordinate in block-wide tile (L-axis strip-mining of ldg_vector_t within block-tile)
                int block_ldgvec_l = block_thread_ldgvec_coords.x + (thread_ldgvec_l * StripmineLdgVectorsL);

                // Iterate through squares in each ldg_vector_t
                #pragma unroll
                for (int ldgvec_dpvec_l = 0; ldgvec_dpvec_l < LdgVectorDpVectors; ++ldgvec_dpvec_l)
                {
                    // Square L-coordinate in block-wide tile (L-axis raking of square-slices within ldg_vector_t)
                    int block_square_l = (block_ldgvec_l * LdgVectorDpVectors) + ldgvec_dpvec_l;

                    // Assemble square of L-major dp_vector_t from stack of slices
                    sts_vector_t square;

                    // Iterate through rows of dp_vector_t in each square
                    #pragma unroll
                    for (int square_dpvec = 0; square_dpvec < SquareDpVectors; ++square_dpvec)
                    {
                        square.buff[square_dpvec] = thread_tile[thread_square_k][square_dpvec][thread_ldgvec_l].buff[ldgvec_dpvec_l];
                    }

                    // Un-transpose square from L-major to K-major
                    transpose_dp_square(square.buff);

                    // Store dp-square
                    square.store(&scratch_tile[block_square_k][block_square_l * SquareDpVectors]);
                }
            }
        }
    }
};


} // namespace gemm
} // namespace cutlass
