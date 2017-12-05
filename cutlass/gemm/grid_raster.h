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
 * Abstraction for enumerating \p block_task within an input matrix
 */

#include <stdint.h>

#include "../util/util.h"


namespace cutlass {
namespace gemm {


/******************************************************************************
 * grid_raster_strategy
 ******************************************************************************/

/**
 * \brief Strategies for enumerating \p block_task within an input matrix
 */
struct grid_raster_strategy
{
    /// \brief Enumerants
    enum kind_t
    {
        /**
         * Default \p block_task assignment (currently ColumnMajor for N*,
         * RowMajor for TT, and TiledCohort for TN)
         */
        Default,

        /**
         * Column-major \p block_task assignment
         */
        ColumnMajor,

        /**
         * Row-major \p block_task assignment
         */
        RowMajor,

        /**
         * Two-level \p block_task assignment (both column-major)
         */
        TiledCohort,
    };
};



/******************************************************************************
 * grid_raster
 ******************************************************************************/

/**
 * \brief Abstraction for enumerating \p block_task within an input matrix
 *
 * NB: This generic class is not directly constructible.  Algorithm-specific
 * template specializations will provide the API functionality prescribed here.
 */
template <
    int                             BlockItemsY,    ///< Height in rows of a block-wide tile in matrix C
    int                             BlockItemsX,    ///< Width in columns of a block-wide tile in matrix C
    matrix_transform_t::kind_t      TransformA,     ///< View transform enumerant for matrix A
    matrix_transform_t::kind_t      TransformB,     ///< View transform enumerant for matrix B
    grid_raster_strategy::kind_t    RasterStrategy> ///< Strategy for enumerating \p block_task within an input matrix
struct grid_raster
{
    //-------------------------------------------------------------------------
    // Device API
    //-------------------------------------------------------------------------

    /// Thread block's base item coordinates (x, y) in matrix C
    int2 block_item_coords;

    /// Constructor
    grid_raster();

    /// Whether the thread block base coordinates are out-of-bounds for an m*n matrix C
    bool is_block_oob(int m, int n);


    //-------------------------------------------------------------------------
    // Grid launch API
    //-------------------------------------------------------------------------

    /// Compute the kernel grid extents (in thread blocks) for consuming an m*n matrix C
    static dim3 grid_dims(int m, int n);
};



/******************************************************************************
 * grid_raster (ColumnMajor specialization)
 ******************************************************************************/

/**
 * \brief Abstraction for enumerating \p block_task within an input matrix
 * (ColumnMajor specialization)
 *
 * Maps thread blocksin column-major fashion
 */
template <
    int                         BlockItemsY,          ///< Height in rows of a block-wide tile in matrix C
    int                         BlockItemsX,          ///< Width in columns of a block-wide tile in matrix C
    matrix_transform_t::kind_t  TransformA,         ///< View transform enumerant for matrix A
    matrix_transform_t::kind_t  TransformB>         ///< View transform enumerant for matrix B
struct grid_raster<
    BlockItemsY,
    BlockItemsX,
    TransformA,
    TransformB,
    grid_raster_strategy::ColumnMajor>                   ///< Strategy for enumerating \p block_task within an input matrix
{
    //-------------------------------------------------------------------------
    // Device API
    //-------------------------------------------------------------------------

    /// Thread block's base item coordinates (x, y) in matrix C
    int2 block_item_coords;

    /// Constructor
    inline __device__
    grid_raster()
    {
        // blockDim.x is the fastest changing grid dim on current architectures
        block_item_coords = make_int2(
            BlockItemsX * blockIdx.y,
            BlockItemsY * blockIdx.x);
    }

    /// Whether the base \p block_item_coords are out-of-bounds for an m*n matrix C
    inline __device__
    bool is_block_oob(int m, int n)
    {
        // ColumnMajor never rasterizes fully out-of-bounds thread blocks
        return false;
    }

    //-------------------------------------------------------------------------
    // Grid launch API
    //-------------------------------------------------------------------------

    /// Compute the kernel grid extents (in thread blocks) for consuming an m*n matrix C
    inline __host__ __device__
    static dim3 grid_dims(int m, int n)
    {
        // blockDim.x is the fastest changing grid dim on current architectures
        return dim3(
            (m + BlockItemsY - 1) / BlockItemsY,
            (n + BlockItemsX - 1) / BlockItemsX);
    }
};



/******************************************************************************
 * grid_raster (RowMajor specialization)
 ******************************************************************************/

/**
 * \brief Abstraction for enumerating \p block_task within an input matrix
 * (RowMajor specialization)
 *
 * Enumerates \p block_task in row-major fashion
 */
template <
    int                         BlockItemsY,    ///< Height in rows of a block-wide tile in matrix C
    int                         BlockItemsX,    ///< Width in columns of a block-wide tile in matrix C
    matrix_transform_t::kind_t  TransformA,     ///< View transform enumerant for matrix A
    matrix_transform_t::kind_t  TransformB>     ///< View transform enumerant for matrix B
struct grid_raster<
    BlockItemsY,
    BlockItemsX,
    TransformA,
    TransformB,
    grid_raster_strategy::RowMajor>             ///< Strategy for enumerating \p block_task within an input matrix
{
    //-------------------------------------------------------------------------
    // Device API
    //-------------------------------------------------------------------------

    /// Thread block's base item coordinates (x, y) in matrix C
    int2 block_item_coords;

    /// Constructor
    inline __device__
    grid_raster()
    {
        // blockDim.x is the fastest changing grid dim on current architectures
        block_item_coords = make_int2(
            BlockItemsX * blockIdx.x,
            BlockItemsY * blockIdx.y);
    }

    /// Whether the base \p block_item_coords are out-of-bounds for an m*n matrix C
    inline __device__
    bool is_block_oob(int m, int n)
    {
        // RowMajor never rasterizes fully out-of-bounds thread blocks
        return false;
    }

    //-------------------------------------------------------------------------
    // Grid launch API
    //-------------------------------------------------------------------------

    /// Compute the kernel grid extents (in thread blocks) for consuming an m*n matrix C
    inline __host__ __device__
    static dim3 grid_dims(int m, int n)
    {
        // blockDim.x is the fastest changing grid dim on current architectures
        return dim3(
            (n + BlockItemsX - 1) / BlockItemsX,
            (m + BlockItemsY - 1) / BlockItemsY);
    }

};



/******************************************************************************
 * grid_raster (TiledCohort specialization)
 ******************************************************************************/

/**
 * \brief Abstraction for enumerating \p block_task within an input matrix
 * (TiledCohort specialization)
 *
 * Enumerates \p block_task in column-major fashion across "cohort" tiles (where
 * cohorts are CohortBlocksY high and CohortBlocksX wide), and enumerates cohorts
 * across the matrix in column-major fashion.
 *
 * Grid layout:
 *  - gridDim.y is the height of the grid in cohorts
 *  - gridDim.x is the width of the grid in cohorts multiplied by the number of
 *    thread blocks per cohort
 */
template <
    int                         BlockItemsY,    ///< Height in rows of a block-wide tile in matrix C
    int                         BlockItemsX,    ///< Width in columns of a block-wide tile in matrix C
    matrix_transform_t::kind_t  TransformA,     ///< View transform enumerant for matrix A
    matrix_transform_t::kind_t  TransformB>     ///< View transform enumerant for matrix B
struct grid_raster<
    BlockItemsY,
    BlockItemsX,
    TransformA,
    TransformB,
    grid_raster_strategy::TiledCohort>       ///< Strategy for enumerating \p block_task within an input matrix
{
    enum
    {
        /// Height in thread blocks of a grid rasterization cohort
        CohortBlocksY = 2,

        /// Width in thread blocks of a grid rasterization cohort
        CohortBlocksX = 2,

        /// Number of thread blocks per cohort
        BlocksPerCohort = CohortBlocksY * CohortBlocksX,

        /// Height in items of a grid rasterization cohort
        CohortItemsY = CohortBlocksY * BlockItemsY,

        /// Width in items of a grid rasterization cohort
        CohortItemsX = CohortBlocksX * BlockItemsX,

    };

    //-------------------------------------------------------------------------
    // Device API
    //-------------------------------------------------------------------------

    /// Thread block's base item coordinates (x, y) in matrix C
    int2 block_item_coords;

    /// Constructor
    inline __device__
    grid_raster()
    {
        int block_idx_cohort = blockIdx.x % BlocksPerCohort;
        int2 cohort_coords_grid = make_int2(
            blockIdx.x / BlocksPerCohort,
            blockIdx.y);

        // Cohort is rastered in column-major order
        int2 block_coords_cohort = make_int2(
            block_idx_cohort / CohortBlocksY,
            block_idx_cohort % CohortBlocksY);

        block_item_coords = make_int2(
            ((cohort_coords_grid.x * CohortBlocksX) + block_coords_cohort.x) * BlockItemsX,
            ((cohort_coords_grid.y * CohortBlocksY) + block_coords_cohort.y) * BlockItemsY);
    }

    /// Whether the base \p block_item_coords are out-of-bounds for an m*n matrix C
    inline __device__
    bool is_block_oob(int m, int n)
    {
        /// thread blocks within the cohort may be fully out-of-bounds
        return (block_item_coords.x >= n) || (block_item_coords.y >= m);
    }

    //-------------------------------------------------------------------------
    // Grid launch API
    //-------------------------------------------------------------------------

    /// Compute the kernel grid extents (in thread blocks) for consuming an m*n matrix C
    inline __host__ __device__
    static dim3 grid_dims(int m, int n)
    {
        // Extents of C matrix in cohorts
        int2 grid_cohort_dims = make_int2(
            (n + CohortItemsX - 1) / CohortItemsX,
            (m + CohortItemsY - 1) / CohortItemsY);

        return dim3(
            grid_cohort_dims.x * BlocksPerCohort,   // gridDim.x is width of grid in cohorts * size of cohort in blocks
            grid_cohort_dims.y,                     // gridDim.y is height of grid in cohorts
            1);                                     // gridDim.z is reserved for optional k-splitting
    }
};


/******************************************************************************
 * grid_raster (Default specializations)
 ******************************************************************************/

/**
 * \brief Abstraction for enumerating \p block_task within an input matrix
 * (Default N* specialization)
 *
 * Maps thread blocksin column-major fashion
 */
template <
    int BlockItemsY,                        ///< Height in rows of a block-wide tile in matrix C
    int BlockItemsX,                        ///< Width in columns of a block-wide tile in matrix C
    matrix_transform_t::kind_t TransformB>  ///< View transform enumerant for matrix B
struct grid_raster<
    BlockItemsY,
    BlockItemsX,
    matrix_transform_t::NonTranspose,       ///< View transform enumerant for matrix A
    TransformB,
    grid_raster_strategy::Default>         ///< Strategy for enumerating \p block_task within an input matrix
:
    grid_raster<
        BlockItemsY,
        BlockItemsX,
        matrix_transform_t::NonTranspose,
        TransformB,
        grid_raster_strategy::ColumnMajor>
{};


/**
 * \brief Abstraction for enumerating \p block_task within an input matrix
 * (Default TT specialization)
 *
 * Maps thread blocksin row-major fashion
 */
template <
    int BlockItemsY,                    ///< Height in rows of a block-wide tile in matrix C
    int BlockItemsX>                    ///< Width in columns of a block-wide tile in matrix C
struct grid_raster<
    BlockItemsY,
    BlockItemsX,
    matrix_transform_t::Transpose,      ///< View transform enumerant for matrix A
    matrix_transform_t::Transpose,      ///< View transform enumerant for matrix B
    grid_raster_strategy::Default>     ///< Strategy for enumerating \p block_task within an input matrix
:
    grid_raster<
        BlockItemsY,
        BlockItemsX,
        matrix_transform_t::Transpose,
        matrix_transform_t::Transpose,
        grid_raster_strategy::RowMajor>
{};


/**
 * \brief Abstraction for enumerating \p block_task within an input matrix
 * (Default TN specialization)
 *
 * Maps thread blocksin blocked cohorts
 */
template <
    int BlockItemsY,                    ///< Height in rows of a block-wide tile in matrix C
    int BlockItemsX>                    ///< Width in columns of a block-wide tile in matrix C
struct grid_raster<
    BlockItemsY,
    BlockItemsX,
    matrix_transform_t::Transpose,      ///< View transform enumerant for matrix A
    matrix_transform_t::NonTranspose,   ///< View transform enumerant for matrix B
    grid_raster_strategy::Default>     ///< Strategy for enumerating \p block_task within an input matrix
:
    grid_raster<
        BlockItemsY,
        BlockItemsX,
        matrix_transform_t::Transpose,
        matrix_transform_t::NonTranspose,
        grid_raster_strategy::TiledCohort>
{};


} // namespace gemm
} // namespace cutlass
