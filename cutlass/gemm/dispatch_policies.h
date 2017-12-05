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
 * Architecture-specific GEMM block_task policies
 */

#include <stdint.h>

#include "../util/util.h"
#include "block_task.h"
#include "grid_raster.h"

namespace cutlass {
namespace gemm {


/******************************************************************************
 * tiling_strategy
 ******************************************************************************/

/**
 * Enumeration of tile-sizing granularities
 */
struct tiling_strategy : printable_t
{
    /// \brief Enumerants
    enum kind_t
    {
        Unknown,
        Small,
        Medium,
        Large,
        Tall,
        Wide,
        Huge,
    };

    /// Enumerant value
    kind_t kind;

    /// Default constructor
    tiling_strategy() : kind(Unknown) {}

    /// Copy constructor
    tiling_strategy(const kind_t &other_kind) : kind(other_kind) {}

    /// Cast to kind_t
    operator kind_t() const { return kind; }

    /// Returns the instance as a string
    __host__ __device__ inline
    char const* to_string() const
    {
        switch (kind)
        {
            case Small:     return "small";
            case Medium:    return "medium";
            case Large:     return "large";
            case Tall:      return "tall";
            case Wide:      return "wide";
            case Huge:      return "huge";
            case Unknown:
            default:        return "unknown";
        }
    }

    /// Insert the formatted instance into the output stream
    void print(std::ostream& out) const { out << to_string(); }
};


/******************************************************************************
 * GEMM
 ******************************************************************************/

/**
 * GEMM task policy specialization for sgemm
 */
template <
    typename value_t,
    typename accum_t,
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB,      ///< Transformation op for matrix B
    tiling_strategy::kind_t TilingStrategy>     ///< Tile-sizing classification
struct gemm_policy;


/******************************************************************************
 * SGEMM
 ******************************************************************************/

/**
 * GEMM task policy specialization for small sgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<float, float, TransformA, TransformB, tiling_strategy::Small> :
    block_task_policy<
        16,     // _BlockItemsY
        16,     // _BlockItemsX
        16,     // _BlockItemsK
        2,      // _ThreadItemsY
        2,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};


/**
 * GEMM task policy specialization for medium sgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<float, float, TransformA, TransformB, tiling_strategy::Medium> :
    block_task_policy<
        32,     // _BlockItemsY
        32,     // _BlockItemsX
        8,      // _BlockItemsK
        4,      // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for large sgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<float, float, TransformA, TransformB, tiling_strategy::Large> :
    block_task_policy<
        64,     // _BlockItemsY
        64,     // _BlockItemsX
        8,      // _BlockItemsK
        8,      // _ThreadItemsY
        8,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for tall sgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<float, float, TransformA, TransformB, tiling_strategy::Tall> :
    block_task_policy<
        128,    // _BlockItemsY
        32,     // _BlockItemsX
        8,      // _BlockItemsK
        8,      // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for wide sgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<float, float, TransformA, TransformB, tiling_strategy::Wide> :
    block_task_policy<
        32,     // _BlockItemsY
        128,    // _BlockItemsX
        8,      // _BlockItemsK
        4,      // _ThreadItemsY
        8,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for huge sgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<float, float, TransformA, TransformB, tiling_strategy::Huge> :
    block_task_policy<
        128,    // _BlockItemsY
        128,    // _BlockItemsX
        8,      // _BlockItemsK
        8,      // _ThreadItemsY
        8,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};


/******************************************************************************
 * DGEMM
 ******************************************************************************/

/**
 * GEMM task policy specialization for small dgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<double, double, TransformA, TransformB, tiling_strategy::Small> :
    block_task_policy<
        16,     // _BlockItemsY
        16,     // _BlockItemsX
        16,     // _BlockItemsK
        2,      // _ThreadItemsY
        2,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};


/**
 * GEMM task policy specialization for medium dgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<double, double, TransformA, TransformB, tiling_strategy::Medium> :
    block_task_policy<
        32,     // _BlockItemsY
        32,     // _BlockItemsX
        16,     // _BlockItemsK
        4,      // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for large dgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<double, double, TransformA, TransformB, tiling_strategy::Large> :
    block_task_policy<
        64,     // _BlockItemsY
        64,     // _BlockItemsX
        8,      // _BlockItemsK
        4,      // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for tall dgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<double, double, TransformA, TransformB, tiling_strategy::Tall> :
    block_task_policy<
        128,    // _BlockItemsY
        32,     // _BlockItemsX
        8,      // _BlockItemsK
        8,      // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for wide dgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<double, double, TransformA, TransformB, tiling_strategy::Wide> :
    block_task_policy<
        32,     // _BlockItemsY
        128,    // _BlockItemsX
        8,      // _BlockItemsK
        4,      // _ThreadItemsY
        8,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for huge dgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<double, double, TransformA, TransformB, tiling_strategy::Huge> :
    block_task_policy<
        64,     // _BlockItemsY
        128,    // _BlockItemsX
        8,      // _BlockItemsK
        8,      // _ThreadItemsY
        8,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};


/******************************************************************************
 * HGEMM
 ******************************************************************************/

/**
 * GEMM task policy specialization for small hgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<__half, __half, TransformA, TransformB, tiling_strategy::Small> :
    block_task_policy<
        32,     // _BlockItemsY
        32,     // _BlockItemsX
        8,      // _BlockItemsK
        4,      // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for medium hgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<__half, __half, TransformA, TransformB, tiling_strategy::Medium> :
    block_task_policy<
        32,     // _BlockItemsY
        32,     // _BlockItemsX
        16,     // _BlockItemsK
        8,      // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for large hgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<__half, __half, TransformA, TransformB, tiling_strategy::Large> :
    block_task_policy<
        64,     // _BlockItemsY
        64,     // _BlockItemsX
        8,      // _BlockItemsK
        16,     // _ThreadItemsY
        8,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for tall hgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<__half, __half, TransformA, TransformB, tiling_strategy::Tall> :
    block_task_policy<
        128,    // _BlockItemsY
        32,     // _BlockItemsX
        8,      // _BlockItemsK
        16,     // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};


/**
 * GEMM task policy specialization for wide hgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<__half, __half, TransformA, TransformB, tiling_strategy::Wide> :
    block_task_policy<
        32,     // _BlockItemsY
        128,    // _BlockItemsX
        8,      // _BlockItemsK
        8,      // _ThreadItemsY
        8,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for huge hgemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<__half, __half, TransformA, TransformB, tiling_strategy::Huge> :
    block_task_policy<
        128,    // _BlockItemsY
        128,    // _BlockItemsX
        8,      // _BlockItemsK
        16,     // _ThreadItemsY
        8,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};


/******************************************************************************
 * IGEMM
 ******************************************************************************/

/**
 * GEMM task policy specialization for small igemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<int8_t, int32_t, TransformA, TransformB, tiling_strategy::Small> :
    block_task_policy<
        16,     // _BlockItemsY
        32,     // _BlockItemsX
        32,     // _BlockItemsK
        4,      // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};


/**
 * GEMM task policy specialization for medium igemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<int8_t, int32_t, TransformA, TransformB, tiling_strategy::Medium> :
    block_task_policy<
        32,     // _BlockItemsY
        32,     // _BlockItemsX
        32,     // _BlockItemsK
        4,      // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for large igemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<int8_t, int32_t, TransformA, TransformB, tiling_strategy::Large> :
    block_task_policy<
        64,     // _BlockItemsY
        64,     // _BlockItemsX
        32,     // _BlockItemsK
        8,      // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>  // _RasterStrategy
{};

/**
 * GEMM task policy specialization for large igemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<int8_t, int32_t, TransformA, TransformB, tiling_strategy::Tall> :
    block_task_policy<
        128,    // _BlockItemsY
        64,     // _BlockItemsX
        64,     // _BlockItemsK
        8,      // _ThreadItemsY
        4,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>   // _RasterStrategy
{};

/**
 * GEMM task policy specialization for large igemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<int8_t, int32_t, TransformA, TransformB, tiling_strategy::Wide> :
    block_task_policy<
        64,     // _BlockItemsY
        128,    // _BlockItemsX
        64,     // _BlockItemsK
        4,      // _ThreadItemsY
        8,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>  // _RasterStrategy
{};

/**
 * GEMM task policy specialization for huge igemm
 */
template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<int8_t, int32_t, TransformA, TransformB, tiling_strategy::Huge> :
    block_task_policy<
        128,    // _BlockItemsY
        128,    // _BlockItemsX
        32,     // _BlockItemsK
        8,      // _ThreadItemsY
        8,      // _ThreadItemsX
        false,  // _UseDoubleScratchTiles
        grid_raster_strategy::Default>  // _RasterStrategy
{};


/******************************************************************************
 * WMMA GEMM
 ******************************************************************************/

// WMMA is a preview feature in CUDA. Conditionally enable wmma_gemm policies.
#if defined(WMMA)

template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<half, float, TransformA, TransformB, tiling_strategy::Small> :
    gemm::block_task_wmma_policy<
        16,     // _BlockItemsY
        16,     // _BlockItemsX
        16,     // _BlockItemsK
        16,     // _WarpItemsY
        16,     // _WarpItemsX
        16,     // _WmmaItemsY
        16,     // _WmmaItemsX
        16,     // _WmmaItemsK
        false,  // _UseDoubleScratchTiles
        gemm::grid_raster_strategy::Default>    // _RasterStrategy
{};

template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy<half, float, TransformA, TransformB, tiling_strategy::Medium> :
    gemm::block_task_wmma_policy<
        32,     // _BlockItemsY
        32,     // _BlockItemsX
        32,     // _BlockItemsK
        32,     // _WarpItemsY
        32,     // _WarpItemsX
        16,     // _WmmaItemsY
        16,     // _WmmaItemsX
        16,     // _WmmaItemsK
        false,  // _UseDoubleScratchTiles
        gemm::grid_raster_strategy::Default>    // _RasterStrategy
{};

template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy< half, float, TransformA, TransformB, tiling_strategy::Large> :
    gemm::block_task_wmma_policy<
        64,     // _BlockItemsY
        64,     // _BlockItemsX
        32,     // _BlockItemsK
        32,     // _WarpItemsY
        64,     // _WarpItemsX
        16,     // _WmmaItemsY
        16,     // _WmmaItemsX
        16,     // _WmmaItemsK
        false,  // _UseDoubleScratchTiles
        gemm::grid_raster_strategy::Default>    // _RasterStrategy
{};

template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy< half, float, TransformA, TransformB, tiling_strategy::Tall> :
    gemm::block_task_wmma_policy<
        128,    // _BlockItemsY
        64,     // _BlockItemsX
        64,     // _BlockItemsK
        32,     // _WarpItemsY
        64,     // _WarpItemsX
        16,     // _WmmaItemsY
        16,     // _WmmaItemsX
        16,     // _WmmaItemsK
        false,  // _UseDoubleScratchTiles
        gemm::grid_raster_strategy::Default>    // _RasterStrategy
{};

template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy< half, float, TransformA, TransformB, tiling_strategy::Wide> :
    gemm::block_task_wmma_policy<
        64,     // _BlockItemsY
        128,    // _BlockItemsX
        64,     // _BlockItemsK
        32,     // _WarpItemsY
        64,     // _WarpItemsX
        16,     // _WmmaItemsY
        16,     // _WmmaItemsX
        16,     // _WmmaItemsK
        false,  // _UseDoubleScratchTiles
        gemm::grid_raster_strategy::Default>    // _RasterStrategy
{};

template <
    matrix_transform_t::kind_t TransformA,      ///< Transformation op for matrix A
    matrix_transform_t::kind_t TransformB>      ///< Transformation op for matrix B
struct gemm_policy< half, float, TransformA, TransformB, tiling_strategy::Huge> :
    gemm::block_task_wmma_policy<
        128,    // _BlockItemsY
        128,    // _BlockItemsX
        64,     // _BlockItemsK
        32,     // _WarpItemsY
        64,     // _WarpItemsX
        16,     // _WmmaItemsY
        16,     // _WmmaItemsX
        16,     // _WmmaItemsK
        false,  // _UseDoubleScratchTiles
        gemm::grid_raster_strategy::Default>    // _RasterStrategy
{};

#endif


} // namespace gemm
} // namespace cutlass
