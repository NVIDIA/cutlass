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
 * GEMM kernel entrypoint and dispatch stub
 */

#include <stdint.h>

#include "../util/util.h"
#include "block_task.h"
#include "block_task_wmma.h"
#include "grid_raster.h"
#include "dispatch_policies.h"
#include "k_split_control.h"

namespace cutlass {
namespace gemm {


/******************************************************************************
 * param_pack
 ******************************************************************************/

/**
 * Parameter-pack structure
 *
 * Kernel launch latency is reduced when kernel arguments are wrapped into
 * a single parameter
 */
template <
    typename value_t,
    typename accum_t,
    typename epilogue_op_t>
struct param_pack
{
    int m;                      ///< Height in rows of op(A) and C
    int n;                      ///< Width in columns of op(B) and C
    int k;                      ///< Width in columns of op(A) and height in rows of op(B)
    k_split_control k_split;    ///< Abstraction for controlling inter-block k-splitting
    value_t *d_a;               ///< Pointer to matrix A array values
    value_t *d_b;               ///< Pointer to matrix B array values
    accum_t *d_c;               ///< Pointer to matrix C array values
    epilogue_op_t epilogue_op;

    param_pack(
        int m,                      ///< Height in rows of op(A) and C
        int n,                      ///< Width in columns of op(B) and C
        int k,                      ///< Width in columns of op(A) and height in rows of op(B)
        k_split_control k_split,    ///< Abstraction for controlling inter-block k-splitting
        epilogue_op_t op,           ///< Epilogue operation to update matrix C
        value_t *d_a,               ///< Pointer to matrix A array values
        value_t *d_b,               ///< Pointer to matrix B array values
        accum_t *d_c)               ///< Pointer to matrix C array values
    :
        m(m),
        n(n),
        k(k),
        k_split(k_split),
        epilogue_op(op),
        d_a(d_a),
        d_b(d_b),
        d_c(d_c)
    {}

};


/******************************************************************************
 * Conditionally select the appropriate GEMM threadblock task
 ******************************************************************************/

/// Conditional selection for block task
template <
    math_operation_class_t      math_op,            ///<
    typename                    block_task_policy_t,  ///< Parameterization of block_task_policy
    typename                    value_t,            ///< Multiplicand value type (matrices A and B)
    typename                    accum_t,            ///< Accumulator value type (matrix C and scalars)
    matrix_transform_t::kind_t  TransformA,         ///< View transform enumerant for matrix A
    int                         LdgAlignA,          ///< Alignment (in bytes) for A operand
    matrix_transform_t::kind_t  TransformB,         ///< View transform enumerant for matrix B
    int                         LdgAlignB,          ///< Alignment (in bytes) for B operand
    typename                    epilogue_op_t,      ///< Epilogue operation applied to GEMM
    int                         LdgAlignC,          ///< Alignment (in bytes) for C operand
    bool                        AllowRaggedTiles    ///< Whether GEMM supports matrix sizes other than multiple of BlockItems{XY}
>
struct gemm_block_task;

/// Scalar math operations
template <
    typename                    block_task_policy_t,  ///< Parameterization of block_task_policy
    typename                    value_t,            ///< Multiplicand value type (matrices A and B)
    typename                    accum_t,            ///< Accumulator value type (matrix C and scalars)
    matrix_transform_t::kind_t  TransformA,         ///< View transform enumerant for matrix A
    int                         LdgAlignA,          ///< Alignment (in bytes) for A operand
    matrix_transform_t::kind_t  TransformB,         ///< View transform enumerant for matrix B
    int                         LdgAlignB,          ///< Alignment (in bytes) for B operand
    typename                    epilogue_op_t,      ///< Epilogue operation applied to GEMM
    int                         LdgAlignC,          ///< Alignment (in bytes) for C operand
    bool                        AllowRaggedTiles    ///< Whether GEMM supports matrix sizes other than multiple of BlockItems{XY}
>
struct gemm_block_task<
    math_operation_class_t::scalar,
    block_task_policy_t,
    value_t,
    accum_t,
    TransformA,
    LdgAlignA,
    TransformB,
    LdgAlignB,
    epilogue_op_t,
    LdgAlignC,
    AllowRaggedTiles
>
{
    // Parameterize task type
    typedef block_task<
            block_task_policy_t,
            value_t,
            accum_t,
            TransformA,
            LdgAlignA,
            TransformB,
            LdgAlignB,
            epilogue_op_t,
            LdgAlignC,
            AllowRaggedTiles> type;
};

/// Matrix math operations
template <
    typename                    block_task_policy_t,  ///< Parameterization of block_task_policy
    typename                    value_t,            ///< Multiplicand value type (matrices A and B)
    typename                    accum_t,            ///< Accumulator value type (matrix C and scalars)
    matrix_transform_t::kind_t  TransformA,         ///< View transform enumerant for matrix A
    int                         LdgAlignA,          ///< Alignment (in bytes) for A operand
    matrix_transform_t::kind_t  TransformB,         ///< View transform enumerant for matrix B
    int                         LdgAlignB,          ///< Alignment (in bytes) for B operand
    typename                    epilogue_op_t,      ///< Epilogue operation applied to GEMM
    int                         LdgAlignC,          ///< Alignment (in bytes) for C operand
    bool                        AllowRaggedTiles    ///< Whether GEMM supports matrix sizes other than multiple of BlockItems{XY}
>
struct gemm_block_task<
    math_operation_class_t::matrix,
    block_task_policy_t,
    value_t,
    accum_t,
    TransformA,
    LdgAlignA,
    TransformB,
    LdgAlignB,
    epilogue_op_t,
    LdgAlignC,
    AllowRaggedTiles>
{

#if defined(WMMA)   // conditional compilation with WMMA headers

    // Parameterize task type
    typedef block_task_wmma<
            block_task_policy_t,
            value_t,
            accum_t,
            TransformA,
            LdgAlignA,
            TransformB,
            LdgAlignB,
            epilogue_op_t,
            LdgAlignC,
            AllowRaggedTiles> type;

#endif
};

/******************************************************************************
 * GEMM kernel entrypoint
 ******************************************************************************/

/**
 * GEMM kernel
 *
 * NB: Not sure why NVVM is doing stuff with "__launch_bounds__" instead of just
 * passing it along to PTXAS, but it is currently resulting in less optimal codegen
 */
template <
    math_operation_class_t      math_op,            ///< Indicates which class of math operation to select
    typename                    block_task_policy_t,  ///< Parameterization of block_task_policy
    matrix_transform_t::kind_t  TransformA,         ///< Transformation op for matrix A
    int                         LdgAlignA,          ///< Alignment of A matrix elements in bytes
    matrix_transform_t::kind_t  TransformB,         ///< Transformation op for matrix B
    int                         LdgAlignB,          ///< Alignment of B matrix elements in bytes
    typename                    value_t,            ///< Multiplicand value type (matrices A and B)
    typename                    accum_t,            ///< Accumulator value type (matrix C and scalars)
    typename                    epilogue_op_t,      ///< Epilogue operation applied to update matrix C
    int                         LdgAlignC,          ///< Alignment of C elements in bytes
    bool                        AllowRaggedTiles>   ///< Boolean to indicate whether AllowRaggedTiles handling is enabled
__global__ void kernel(param_pack<value_t, accum_t, epilogue_op_t> pack)
{
    // Parameterize task type
    typedef typename gemm_block_task<
        math_op,
        block_task_policy_t,
        value_t,
        accum_t,
        TransformA,
        LdgAlignA,
        TransformB,
        LdgAlignB,
        epilogue_op_t,
        LdgAlignC,
        AllowRaggedTiles>::type block_task_t;

    // Declare statically-allocated shared storage
    __shared__ typename block_task_t::scratch_storage_t smem;

    // Construct and run the task
    block_task_t(
        &smem,
        pack.d_a,
        pack.d_b,
        pack.d_c,
        pack.epilogue_op,
        pack.m,
        pack.n,
        pack.k,
        pack.k_split).run();
}


/******************************************************************************
 * Launch configuration description returned to the caller
 ******************************************************************************/

/// Return details about the launch configuration to the caller
struct launch_configuration
{
    //
    // Data members
    //

    /// cudaError_t resulting from grid launch
    cudaError_t result;

    /// Extent of a thread block's partition along the GEMM K-axis
    int split_k;

    /// Kernel grid extents in thread blocks
    dim3 grid;

    /// Thread block extents in threads
    dim3 block;

    //
    // Methods
    //

    /// Constructor
    launch_configuration():
        result(cudaSuccess),
        split_k(0),
        grid(0, 0, 0),
        block(0, 0, 0) {

    }

    /// Conversion from cudaError_t
    launch_configuration(cudaError_t result):
        result(result),
        split_k(1),
        grid(0, 0, 0),
        block(0, 0, 0) {

    }

    /// Launch configuration for Cutlass kernels
    launch_configuration(
        cudaError_t result,
        int split_k,
        dim3 grid,
        dim3 block
    ):
        result(result),
        split_k(split_k),
        grid(grid),
        block(block) {

    }
};


/******************************************************************************
 * Dispatch stub
 ******************************************************************************/

/**
 * GEMM dispatch stub
 *
 * This function also serves as the autotuning entrypoint to evaluate different
 * tuning parameterizations of kernel.
 */
template <
    math_operation_class_t      math_op,            ///< Indicates which class of math operation to select
    typename                    block_task_policy_t,  ///< Parameterization of block_task_policy
    matrix_transform_t::kind_t  TransformA,         ///< Transformation op for matrix A
    int                         LdgAlignA,          ///< Alignment of A matrix elements in bytes
    matrix_transform_t::kind_t  TransformB,         ///< Transformation op for matrix B
    int                         LdgAlignB,          ///< Alignment of B matrix elements in bytes
    typename                    value_t,            ///< Multiplicand value type (matrices A and B)
    typename                    accum_t,            ///< Accumulator value type (matrix C and scalars)
    typename                    epilogue_op_t,      ///< Epilogue operation
    int                         LdgAlignC,          ///< Alignment of C matrix elements in bytes
    bool                        AllowRaggedTiles,   ///< Boolean to indicate whether AllowRaggedTiles handling is enabled
    typename                    kernel_ptr_t>       ///< GEMM kernel function pointer type
launch_configuration dispatch(
    kernel_ptr_t    kernel_ptr,                     ///< GEMM kernel function pointer
    int             m,                              ///< Height in rows of op(A) and C
    int             n,                              ///< Width in columns of op(B) and C
    int             k,                              ///< Width in columns of op(A) and height in rows of op(B)
    epilogue_op_t   epilogue_op,                    ///< Epilogue operation to update matrix C
    value_t         *d_a,                           ///< Device pointer to matrix A array values
    value_t         *d_b,                           ///< Device pointer to matrix B array values
    accum_t         *d_c,                           ///< Device pointer to matrix C array values
    cudaStream_t    stream = 0,                     ///< CUDA stream to launch kernels within.  Default is stream<sub>0</sub>.
    bool            debug_synchronous = true)       ///< Whether or not to synchronize the stream after every kernel launch
                                                    ///  to check for errors.  Also causes launch configurations to be printed
                                                    ///  to the console if DEBUG is defined.  Default is \p false.
{
    // Thread block rasterization type
    typedef grid_raster<
            block_task_policy_t::BlockItemsY,
            block_task_policy_t::BlockItemsX,
            TransformA,
            TransformB,
            block_task_policy_t::RasterStrategy>
        grid_raster_t;

    launch_configuration config;

    // Compute block dims
    config.block = dim3(block_task_policy_t::BlockThreads);

    // Compute shared memory
    int dynamic_smem_bytes = 0;

    // Compute occupancy
    int max_sm_occupancy;
    if (CUDA_PERROR_DEBUG(config.result = cudaOccupancyMaxActiveBlocksPerMultiprocessor(
        &max_sm_occupancy,
        kernel_ptr,
        config.block.x * config.block.y,
        dynamic_smem_bytes)))
    {
        return config;
    }

    // Compute grid extents
    config.grid = grid_raster_t::grid_dims(m, n);

    // Get SM count
    int sm_count;
    if (CUDA_PERROR_DEBUG(config.result = get_sm_count(sm_count)))
        return config;

    // Get k-split flag storage (TODO: make a pool)
    int *d_flags;
    if (CUDA_PERROR_DEBUG(config.result = cudaGetSymbolAddress((void**) &d_flags, d_flags_split_k)))
        return config;

    // Construct k-split coordinator
    k_split_control k_split(
        d_flags,
        sm_count,
        max_sm_occupancy,
        k,
        block_task_policy_t::BlockItemsK,
        config.block,
        config.grid);     // in,out

    config.split_k = k_split.split_k;

    // Log kernel configuration
    if (debug_synchronous)
    {
        // Compute tiling efficiency
        float block_tiling_efficiency = float(block_task_policy_t::BlockItemsY * block_task_policy_t::BlockItemsX) /
            float(block_task_policy_t::BlockItemsY + block_task_policy_t::BlockItemsX);

        float tiling_efficiency = block_tiling_efficiency;

        float wave_efficiency = k_split.get_wave_efficiency(
            sm_count, max_sm_occupancy, config.block, config.grid);

        CUDA_LOG_DEBUG("Final wave_efficiency %.4f, tiling_efficiency %.4f\n",
            wave_efficiency, tiling_efficiency);

        CUDA_LOG_DEBUG("Invoking kernel<<<(%d, %d, %d), (%d.y,%d.x), %d, %lld>>>(), %d SM occupancy, %d split_k\n",
            config.grid.x, config.grid.y, config.grid.z,
            config.block.y, config.block.x,
            dynamic_smem_bytes,
            (long long) stream,
            max_sm_occupancy,
            k_split.split_k);
    }

    // Construct parameter-pack
    param_pack<value_t, accum_t, epilogue_op_t> pack(
        m,
        n,
        k,
        k_split,
        epilogue_op,
        d_a,
        d_b,
        d_c);

    // Prepare k-split coordinator
    if (CUDA_PERROR_DEBUG(config.result = k_split.prepare(stream, debug_synchronous)))
    {
        return config;
    }

    // Invoke kernel
    kernel_ptr<<< config.grid, config.block, dynamic_smem_bytes, stream >>>(pack);

    // Check for failure to launch
    if (CUDA_PERROR_DEBUG(config.result = cudaPeekAtLastError()))
        return config;

    // Sync the stream if specified to flush runtime errors
    if (debug_synchronous && (CUDA_PERROR_DEBUG(config.result = cudaStreamSynchronize(stream))))
        return config;

    return config;
}


/******************************************************************************
 * GEMM
 ******************************************************************************/

/**
 * Computes gemm on device matrices
 */
template <
    tiling_strategy::kind_t      TilingStrategy,    ///< Tile-sizing classification
    math_operation_class_t      math_op,        ///< Indicates which class of math operation to select
    matrix_transform_t::kind_t  TransformA,     ///< Transformation op for matrix A
    int                         LdgAlignA,      ///< Alignment (in bytes) of A operand
    matrix_transform_t::kind_t  TransformB,     ///< Transformation op for matrix B
    int                         LdgAlignB,      ///< Alignment (in bytes) of B operand
    typename                    value_t,        ///< Multiplicand value type (matrices A and B)
    typename                    accum_t,        ///< Accumulator value type (matrix C and scalars)
    typename                    epilogue_op_t,  ///< Epilogue operation to update matrix C
    int                         LdgAlignC>      ///< Alignment (in bytes) of C operand
launch_configuration device_gemm(
    int             m,                          ///< Height in rows of op(A) and C
    int             n,                          ///< Width in columns of op(B) and C
    int             k,                          ///< Width in columns of op(A) and height in rows of op(B)
    epilogue_op_t   epilogue_op,                ///< Epilogue operation to update matrix C
    value_t         *d_a,                       ///< Device pointer to matrix A array values
    value_t         *d_b,                       ///< Device pointer to matrix B array values
    accum_t         *d_c,                       ///< Device pointer to matrix C array values
    cudaStream_t    stream = 0,                 ///< CUDA stream to launch kernels within.  Default is stream<sub>0</sub>.
    bool            debug_synchronous = false)  ///< Whether or not to synchronize the stream after every kernel launch to
                                                ///  check for errors.  Also causes launch configurations to be printed to
                                                ///  the console if DEBUG is defined.  Default is \p false.
{
    // Parameterize an task policy type
    // (TODO: use a policy dispatch mechanism based upon SM version)
    typedef gemm_policy<value_t, accum_t, TransformA, TransformB, TilingStrategy> block_task_policy_t;

    // AllowRaggedTiles-tile check
    if ((m % block_task_policy_t::BlockItemsY != 0) ||
        (n % block_task_policy_t::BlockItemsX != 0) ||
        (k % block_task_policy_t::BlockItemsK != 0))
    {
        // Needs ragged tile-handling
        static const bool AllowRaggedTiles = true;

        return dispatch<math_op, block_task_policy_t, TransformA, LdgAlignA, TransformB, LdgAlignB, value_t, accum_t, epilogue_op_t, LdgAlignC, AllowRaggedTiles>(
            kernel<math_op,block_task_policy_t, TransformA, LdgAlignA, TransformB, LdgAlignB, value_t, accum_t, epilogue_op_t, LdgAlignC, AllowRaggedTiles>,
            m,
            n,
            k,
            epilogue_op,
            d_a,
            d_b,
            d_c,
            stream,
            debug_synchronous);
    }
    else
    {
        // Does not need ragged tile-handling
        static const bool AllowRaggedTiles = false;

        return dispatch<math_op, block_task_policy_t, TransformA, LdgAlignA, TransformB, LdgAlignB, value_t, accum_t, epilogue_op_t, LdgAlignC, AllowRaggedTiles>(
            kernel<math_op,block_task_policy_t, TransformA, LdgAlignA, TransformB, LdgAlignB, value_t, accum_t, epilogue_op_t, LdgAlignC, AllowRaggedTiles>,
            m,
            n,
            k,
            epilogue_op,
            d_a,
            d_b,
            d_c,
            stream,
            debug_synchronous);
    }


}


} // namespace gemm
} // namespace cutlass
