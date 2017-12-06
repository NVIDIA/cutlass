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
 * A block-wide task abstraction for computing device-wide GEMM
 */

#include <stdint.h>

#include "../util/util.h"

#include "grid_raster.h"
#include "block_loader.h"
#include "k_split_control.h"
#include "thread_accumulator.h"

namespace cutlass {
namespace gemm {


/******************************************************************************
 * block_task_policy
 ******************************************************************************/

/**
 * \brief Parameterizable tuning policy for \p block_task
 *
 * Once parameterized, \p block_task_policy provides the member constant
 * \p BlockThreads indicating to the required thread block size
 */
template <
    int _BlockItemsY,                               ///< Height in rows of a block-wide tile in matrix C
    int _BlockItemsX,                               ///< Width in columns of a block-wide tile in matrix C
    int _BlockItemsK,                               ///< Extent of block-wide A|B tiles in value_t along the K-axis
    int _ThreadItemsY,                              ///< Height in rows of a thread tile in C
    int _ThreadItemsX,                              ///< Width in columns of a thread tile in C
    bool _UseDoubleScratchTiles,                    ///< Whether to halve synchronization overhead at the expense of doubled shared memory and addressing overhead
    grid_raster_strategy::kind_t _RasterStrategy>   ///< Strategy for enumerating \p block_task within an input matrix
struct block_task_policy
{
    enum
    {
        /// Height in rows of a block-wide tile in matrix C
        BlockItemsY = _BlockItemsY,

        /// Width in columns of a block-wide tile in matrix C
        BlockItemsX = _BlockItemsX,

        /// Height in rows of a thread tile in C
        ThreadItemsY = _ThreadItemsY,

        /// Width in columns of a thread tile in C
        ThreadItemsX = _ThreadItemsX,

        /// Extent of block-wide A|B tiles in value_t along the K-axis
        BlockItemsK = _BlockItemsK,

        /// Whether to halve synchronization overhead at the expense of doubled shared memory and addressing overhead
        UseDoubleScratchTiles = _UseDoubleScratchTiles,

        /// Number of threads in each thread block (blockDim.x)
        BlockThreads = divide_assert<
                            (BlockItemsY * BlockItemsX),
                            (ThreadItemsY * ThreadItemsX)>::value,
    };

    /// Strategy for enumerating \p block_task within an input matrix
    static const grid_raster_strategy::kind_t RasterStrategy = _RasterStrategy;
};


/******************************************************************************
 * block_task
 ******************************************************************************/

/**
 * \brief A block-wide task abstraction for computing device-wide GEMM
 *
 * Each thread_block is assigned a unique tile of output matrix C to compute by
 * consuming the corresponding stripes of the input matrices A and B.
 */
template <
    typename                    block_task_policy_t,    ///< Parameterization of block_task_policy
    typename                    value_t,                ///< Multiplicand value type (matrices A and B)
    typename                    accum_t,                ///< Accumulator value type (matrix C and scalars)
    matrix_transform_t::kind_t  TransformA,             ///< View transform enumerant for matrix A
    int                         LdgAlignA,              ///< Alignment (in bytes) for A operand
    matrix_transform_t::kind_t  TransformB,             ///< View transform enumerant for matrix B
    int                         LdgAlignB,              ///< Alignment (in bytes) for B operand
    typename                    epilogue_op_t,          ///< Epilogue operation applied to GEMM
    int                         LdgAlignC,              ///< Alignment (in bytes) for C operand
    bool                        AllowRaggedTiles        ///< Whether the input matrix's dimensions need not be an even-multiple of the block-wide tile dimensions
>
struct block_task
{
    //-------------------------------------------------------------------------
    // Constants and types
    //-------------------------------------------------------------------------

    enum
    {
        /// Number of threads in each thread block (blockDim.x)
        BlockThreads = block_task_policy_t::BlockThreads,

        /// Extent of thread tile in value_t along M-axis
        ThreadItemsY = block_task_policy_t::ThreadItemsY,

        /// Extent of thread tile in value_t along N-axis
        ThreadItemsX = block_task_policy_t::ThreadItemsX,
    };

    /// Accumulator type
    typedef thread_accumulator<
            ThreadItemsY,
            ThreadItemsX,
            value_t,
            accum_t>
        thread_accumulator_t;

    /// Dot-product vector type along the K-axis (e.g, uchar4 when using IDP4A)
    typedef typename thread_accumulator_t::dp_vector_t dp_vector_t;

    enum
    {
        /// Whether this is a small, latency-bound tile
        IsSmallTile = (ThreadItemsY < 4) && (ThreadItemsX < 4),

        /// Number of value_t in dp_vector_t
        DpVectorItems = divide_assert<sizeof(dp_vector_t), sizeof(value_t)>::value,

        /// Extent of block-wide C-tile in accum_t (and A-tiles in value_t) along M-axis (height)
        BlockItemsY = block_task_policy_t::BlockItemsY,

        /// Extent of block-wide C-tile in accum_t (and B-tiles in value_t) along N-axis (width)
        BlockItemsX = block_task_policy_t::BlockItemsX,

        /// Extent of block-wide A|B tiles in value_t along the K-axis
        BlockItemsK = block_task_policy_t::BlockItemsK,

        /// Whether to halve synchronization overhead at the expense of doubled shared memory and addressing overhead
        UseDoubleScratchTiles = block_task_policy_t::UseDoubleScratchTiles,

        /// Extent of block-wide A|B tiles in dp_vector_t along the K-axis
        BlockDpVectorsK = divide_assert<BlockItemsK, DpVectorItems>::value,

        /// Number of dp_vector_t along M-axis that can be read in a single LDS from the shared A-tile (up to 128b if more than one value_t)
        LdsVectorDpVectorsA = __NV_STD_MIN(
            ThreadItemsY, 
            __NV_STD_MAX(1, (128 / (__NV_STD_MAX(sizeof(dp_vector_t), sizeof(accum_t)) * 8)))),

        /// Number of dp_vector_t along N-axis that can be read in a single LDS from the shared B-tile (up to 128b if more than one value_t)
        LdsVectorDpVectorsB = __NV_STD_MIN(
            ThreadItemsX, 
            __NV_STD_MAX(1, (128 / (__NV_STD_MAX(sizeof(dp_vector_t), sizeof(accum_t)) * 8)))),

        /// Number of strip-mined LDS vector reads from shared A-tile
        ThreadLdsVectorsA = divide_assert<ThreadItemsY, LdsVectorDpVectorsA>::value,

        /// Number of strip-mined LDS vector reads from shared B-tile
        ThreadLdsVectorsB = divide_assert<ThreadItemsX, LdsVectorDpVectorsB>::value,

        /// Number of elements in one LDG/STG vector of C-tile
        ThreadLdgVectorSizeC = __NV_STD_MIN(LdgAlignC, 16) / (sizeof(accum_t)),

        /// Number of threads in warp
        WarpThreads = 32,

        /// Extent of warp in threads along the M-axis
        WarpThreadsY = (BlockItemsY > BlockItemsX) ? 8 : 4,

        /// Extent of warp in threads along the N-axis
        WarpThreadsX = divide_assert<WarpThreads, WarpThreadsY>::value,

        /// Extent of warp-wide tile in items along the M-axis
        WarpItemsY = WarpThreadsY * ThreadItemsY,

        /// Extent of warp-wide tile in items along the N-axis
        WarpItemsX = WarpThreadsX * ThreadItemsX,

        /// Extent of block in warps along M-axis
        BlockWarpsY = divide_assert<BlockItemsY, WarpItemsY>::value,

        /// Extent of block in warps along N-axis
        BlockWarpsX = divide_assert<BlockItemsX, WarpItemsX>::value,
    };

    /// Load-from-shared data movement type for A-tile, coarsened by LdsVectorDpVectorsA
    typedef io_vector<dp_vector_t, LdsVectorDpVectorsA> lds_vector_a_t;

    /// Load-from-shared data movement type for B-tile, coarsened by LdsVectorDpVectorsB
    typedef io_vector<dp_vector_t, LdsVectorDpVectorsB> lds_vector_b_t;

    /// Thread block rasterization helper type
    typedef grid_raster<
            BlockItemsY,
            BlockItemsX,
            TransformA,
            TransformB,
            block_task_policy_t::RasterStrategy>
        grid_raster_t;


    /// Tile loader type for matrix A
    typedef block_loader<
            BlockThreads,                                       // BlockThreads
            BlockDpVectorsK,                                    // BlockDpVectorsK
            BlockItemsY,                                        // BlockItemsL
            value_t,                                            // value_t
            LdgAlignA,                                          // MatrixAlignBytes
            AllowRaggedTiles,                                   // AllowRaggedTiles
            dp_vector_t,                                        // dp_vector_t
            (TransformA == matrix_transform_t::NonTranspose) ?  // LoadAlgorithm
                load_algorithm::CongruousCopy :
                load_algorithm::CrosswiseCopy>
        block_loader_a_t;


    /// Tile loader type for matrix B
    typedef block_loader<
            BlockThreads,                                       // BlockThreads
            BlockDpVectorsK,                                    // BlockDpVectorsK
            BlockItemsX,                                        // BlockItemsL
            value_t,                                            // value_t
            LdgAlignB,                                          // MatrixAlignBytes
            AllowRaggedTiles,                                   // AllowRaggedTiles
            dp_vector_t,                                        // dp_vector_t
            (TransformB == matrix_transform_t::NonTranspose) ?  // LoadAlgorithm
                load_algorithm::CrosswiseCopy :
                load_algorithm::CongruousCopy>
        block_loader_b_t;


    enum
    {
        /// Number of value_t to pad the end of each row of the shared A-tile
        PadItemsA = (TransformA == matrix_transform_t::NonTranspose) ?
            __NV_STD_MAX(LdsVectorDpVectorsA, block_loader_a_t::AlignmentDpVectorsL) :
            LdsVectorDpVectorsA,

        /// Number of value_t to pad the end of each row of the shared B-tile
        PadItemsB = (TransformB == matrix_transform_t::NonTranspose) ?
            LdsVectorDpVectorsB :
            __NV_STD_MAX(LdsVectorDpVectorsB, block_loader_b_t::AlignmentDpVectorsL),
    };


    /// Shared memory layout for a prefetch page
    struct page_storage_t
    {
        /// Tile of A
        dp_vector_t __align__(16) block_a[BlockDpVectorsK][BlockItemsY + PadItemsA];

        /// Tile of B
        dp_vector_t __align__(16) block_b[BlockDpVectorsK][BlockItemsX + PadItemsB];
    };


    /// Shared memory layout for scratch storage
    struct scratch_storage_t
    {
        /// Prefetch pages
        page_storage_t pages[UseDoubleScratchTiles ? 2 : 1];

        /// Accumulator shared scratch
        typename thread_accumulator_t::scratch_storage_t accum_scratch;
    };


    //-------------------------------------------------------------------------
    // Assert assumptions
    //-------------------------------------------------------------------------

    // Ensure we have at least two unrolled innermost loop iterations (one to prefetch
    // the next global tile and then one to prefetch the first strip of it from shared)
    static_assert ((BlockDpVectorsK >= 2), "BlockDpVectorsK must be >= 2.");


    //-------------------------------------------------------------------------
    // Members
    //-------------------------------------------------------------------------

    /// Scratch storage reference
    scratch_storage_t *scratch;

    /// Which page of scratch tiles we're currently reading from
    int page_idx;

    /// Pointer to matrix C
    accum_t *d_c;

    /// Epilogue operation applied to update matrix C
    epilogue_op_t epilogue_op;

    /// Matrix height in rows of trans_op(A) and C
    int dim_m;

    /// Matrix width in columns of trans_op(B) and C
    int dim_n;

    /// Control for inter-block k-splitting
    k_split_control k_split;

    /// Thread block's base value_t coordinates (m, n) in matrix C
    grid_raster_t grid_raster;

    /// Thread block's current coordinate (k) within A|B matrices
    int block_item_coords_k;

    /// Thread block's ending coordinate (k) within A|B matrices (one-past)
    int block_end_item_k;

    /// Warp's coordinates (x, y) in thread block
    int2 block_warp_coords;

    /// Thread's coordinates (x, y) in warp
    int2 warp_thread_coords;

    /// Thread's base item offset within strip of A tile
    int thread_strip_offset_a;

    /// Thread's base item offset within strip of B tile
    int thread_strip_offset_b;

    /// Thread's active-k/prefetch-k slices from shared A tile
    lds_vector_a_t local_slices_a[2][ThreadLdsVectorsA];

    /// Thread's active-k/prefetch-k slices from shared B tile
    lds_vector_b_t local_slices_b[2][ThreadLdsVectorsB];

    /// A tile loader
    block_loader_a_t loader_a;

    /// B tile loader
    block_loader_b_t loader_b;

    /// C tile accumulator
    thread_accumulator_t accumulator;


    //-------------------------------------------------------------------------
    // Coordinate system helpers
    //-------------------------------------------------------------------------

    /// Compute the warp's coordinates (x, y) in thread block
    inline __device__
    int2 warp_coords()
    {
        int warp_id = threadIdx.x / WarpThreads;
        return make_int2(
            warp_id % BlockWarpsX,
            warp_id / BlockWarpsX);
    }


    /// Compute the thread's lane-coordinates (x, y) in warp
    inline __device__
    int2 thread_coords()
    {
        int lane_id = threadIdx.x % WarpThreads;

        // Maxwell+ mapping of threads within a 2D warp for maximal LDS bandwidth
        return make_int2(
            lane_id / WarpThreadsY,
            lane_id % WarpThreadsY);
    }


    //-------------------------------------------------------------------------
    // Constructor API
    //-------------------------------------------------------------------------

    /// Constructor
    inline __device__
    block_task(
        scratch_storage_t *scratch,
        value_t *d_a,
        value_t *d_b,
        accum_t *d_c,
        epilogue_op_t epilogue_op,
        int dim_m,
        int dim_n,
        int dim_k,
        k_split_control k_split)
    :
        scratch(scratch),
        page_idx(0),
        d_c(d_c),
        epilogue_op(epilogue_op),
        dim_m(dim_m),
        dim_n(dim_n),
        k_split(k_split),
        block_item_coords_k(k_split.block_begin_item_k()),
        block_end_item_k(k_split.block_end_item_k(dim_k)),
        block_warp_coords(warp_coords()),
        warp_thread_coords(thread_coords()),
        thread_strip_offset_a((warp_thread_coords.y * LdsVectorDpVectorsA) + (block_warp_coords.y * WarpItemsY)),
        thread_strip_offset_b((warp_thread_coords.x * LdsVectorDpVectorsB) + (block_warp_coords.x * WarpItemsX)),

        loader_a(
            d_a,                                                            // d_matrix
            dim_m,                                                          // matrix_values_l
            (TransformA == matrix_transform_t::NonTranspose) ? dim_m : 1,   // matrix_values_stride_k
            (TransformA == matrix_transform_t::NonTranspose) ? 1 : dim_k,   // matrix_values_stride_l
            make_int2(                                                      // block_begin_item_coords
                grid_raster.block_item_coords.y,
                block_item_coords_k),
            block_end_item_k),                                              // block_end_item_k

        loader_b(
            d_b,                                                            // d_matrix
            dim_n,                                                          // matrix_values_l
            (TransformB == matrix_transform_t::NonTranspose) ? 1 : dim_n,   // matrix_values_stride_k
            (TransformB == matrix_transform_t::NonTranspose) ? dim_k : 1,   // matrix_values_stride_l
            make_int2(                                                      // block_begin_item_coords
                grid_raster.block_item_coords.x,
                block_item_coords_k),
            block_end_item_k),                                              // block_end_item_k

        accumulator(scratch->accum_scratch)
    {}


    //-------------------------------------------------------------------------
    // Prefetching utility methods
    //-------------------------------------------------------------------------

    /**
     * Request the calling thread's slices of the shared tiles at depth \p tile_offset_k
     */
    inline __device__ void request_local_prefetch(
        lds_vector_a_t (&slice_a)[ThreadLdsVectorsA],  ///< Slice from A
        lds_vector_b_t (&slice_b)[ThreadLdsVectorsB],  ///< Slice from B
        int tile_offset_k)
    {
        // Load B strip
        for (int i = 0; i < ThreadLdsVectorsB; ++i)
        {
            slice_b[i].load(
                &scratch->pages[page_idx].block_b[tile_offset_k][thread_strip_offset_b + (i * WarpThreadsX * LdsVectorDpVectorsB)]);
        }

        // Load A strip
        for (int i = 0; i < ThreadLdsVectorsA; ++i)
        {
            slice_a[i].load(
                &scratch->pages[page_idx].block_a[tile_offset_k][thread_strip_offset_a + (i * WarpThreadsY * LdsVectorDpVectorsA)]);
        }
    }


    //-------------------------------------------------------------------------
    // Epilogue
    //-------------------------------------------------------------------------

    /**
     * Performs the GEMM epilogue:
     *   - Applies the scalar multipliers and addends to the accumulators
     *   - Write the result to the output matrix
     */
    inline __device__ void epilogue()
    {
        // Wait for predecessor thread block(s) to produce block-wide tile of
        // exclsuive partial-sums
        k_split.wait();

        // Configure epilogue as to whether the thread block is a secondary
        // accumulator in an inter-block k-splitting scheme
        if (k_split.is_secondary_accumulator())
            epilogue_op.set_secondary_accumulator();

        // Whether the addend from C needs loading
        bool must_init_addend = epilogue_op.must_init_addend();

        #pragma unroll
        for (int x = 0; x < ThreadItemsX; ++x)
        {
            #pragma unroll
            for (int y = 0; y < ThreadItemsY; y += LdsVectorDpVectorsA)
            {
                int thread_strip_b = x / LdsVectorDpVectorsB;
                int thread_strip_a = y / LdsVectorDpVectorsA;

                int thread_item_coords_tile_x = thread_strip_offset_b + (thread_strip_b * WarpThreadsX * LdsVectorDpVectorsB) + (x % LdsVectorDpVectorsB);
                int thread_item_coords_tile_y = thread_strip_offset_a + (thread_strip_a * WarpThreadsY * LdsVectorDpVectorsA) + (y % LdsVectorDpVectorsA);

                int c_idx = (grid_raster.block_item_coords.x + thread_item_coords_tile_x) * dim_m +
                    grid_raster.block_item_coords.y + thread_item_coords_tile_y;

                accum_t *my_c = d_c + c_idx;

                #pragma unroll
                for (int i = 0; i < LdsVectorDpVectorsA; ++i)
                {
                    accum_t c_slice = accum_t(0);
                    accum_t *c_ptr = my_c + i;

                    if ((grid_raster.block_item_coords.x + thread_item_coords_tile_x) < dim_n &&
                        (grid_raster.block_item_coords.y + thread_item_coords_tile_y + i) < dim_m)
                    {
                        if (must_init_addend)
                        {
                            ldg_cg(c_slice, c_ptr);
                        }

                        c_slice = epilogue_op(accumulator.get(x, y + i), c_slice, c_idx + i);

                        stg_cg(c_ptr, c_slice);
                    }
                }
            }
        }

        // Signal k-split successor thread_block that we have produced our block-wide
        // tile of inclusive partial-sums
        k_split.signal();
    }


    //-------------------------------------------------------------------------
    // Tile consumption
    //-------------------------------------------------------------------------

    /**
     * Consume a tile of A and B each
     */
    template <bool DoGlobalPrefetch>
    inline __device__
    void consume_tile()
    {
        // Unroll BlockDpVectorsK iterations of outer-product accumulations
        #pragma unroll
        for (int tile_offset_k = 0; tile_offset_k < BlockDpVectorsK; tile_offset_k += 1)
        {
            // Last strip commits global prefetch for next tile
            if ((tile_offset_k == BlockDpVectorsK - 1) && DoGlobalPrefetch)
            {
                // If not using two pages of scratch tiles, protect the above prefetch loads from the committing writes below
                if (!UseDoubleScratchTiles)
                    __syncthreads();

                // If using two pages of scratch tiles, switch to next page before writing
                if (UseDoubleScratchTiles)
                {
                    page_idx = (page_idx ? 0 : 1);
                }

                // Commit global prefetch data to scratch page
                loader_a.commit(scratch->pages[page_idx].block_a);
                loader_b.commit(scratch->pages[page_idx].block_b);

                __syncthreads();
            }

            // Request local prefetch for next strip
            request_local_prefetch(
                local_slices_a[(tile_offset_k + 1) % 2],
                local_slices_b[(tile_offset_k + 1) % 2],
                (tile_offset_k + 1) % BlockDpVectorsK);

            // Request global prefetch for next tile on first strip
            if ((tile_offset_k == 0) && DoGlobalPrefetch)
            {
                loader_b.request();
                loader_b.next();
                loader_a.request();
                loader_a.next();
            }

            // Cast strip-mined loads to contiguous array of dp_vector_t
            typedef dp_vector_t thread_tile_a_t[ThreadLdsVectorsA * LdsVectorDpVectorsA];
            typedef dp_vector_t thread_tile_b_t[ThreadLdsVectorsB * LdsVectorDpVectorsB];
            thread_tile_a_t &thread_tile_a = reinterpret_cast<thread_tile_a_t&>(local_slices_a[(tile_offset_k) % 2]);
            thread_tile_b_t &thread_tile_b = reinterpret_cast<thread_tile_b_t&>(local_slices_b[(tile_offset_k) % 2]);

            // Accumulate this dp-stripe product
            accumulator.multiply_accumulate(thread_tile_a, thread_tile_b);
        }
    }


    //-------------------------------------------------------------------------
    // GEMM API
    //-------------------------------------------------------------------------

    /**
     * Compute GEMM
     */
    inline __device__
    void run()
    {
        // Quit if the thread block is fully out-of-bounds
        if (grid_raster.is_block_oob(dim_m, dim_n))
        {
            asm volatile("exit;");
        }

        // Request global prefetch of first tile
        loader_a.request();
        loader_a.next();
        loader_b.request();
        loader_b.next();

        // Commit global prefetch of first tile to shared memory
        loader_a.commit(scratch->pages[page_idx].block_a);
        loader_b.commit(scratch->pages[page_idx].block_b);

        // Advance to next A,B tiles in K-axis
        block_item_coords_k += BlockItemsK;

        // Synchronize shared tiles and prepared accumulator
        __syncthreads();

        // Initialize thread's slice of accumulators
        accumulator.init();

        // Request first iteration of local prefetch strips
        request_local_prefetch(
            local_slices_a[0],
            local_slices_b[0],
            0);

        //
        // Main loop
        //

        // Consume tiles in A and B along the K-axis (all but last tile)
        #pragma unroll 1
        while (block_item_coords_k < block_end_item_k)
        {
            consume_tile<true>();

            // Advance to next A,B tiles in K-axis
            block_item_coords_k += BlockItemsK;
        }

        // Consume last tile
        consume_tile<false>();

        //
        // Eplilogue
        //

        epilogue();
    }
};


} // namespace gemm
} // namespace cutlass
