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
 * C++ interface for dispatching CUBLAS GEMM calls
 */

#include <cublas_v2.h>

namespace cutlass {


/******************************************************************************
 * cuBLAS dispatch entrypoints
 ******************************************************************************/

/**
 * Dispatch cuBLAS igemm
 */
cublasStatus_t cublas_gemm_dispatch(
    cublasHandle_t    cublas_handle,            ///< CUBLAS handle
    cublasOperation_t transform_a,               ///< Transform op(A) that is non- or (conj.) transpose.
    cublasOperation_t transform_b,               ///< Transform op(B) that is non- or (conj.) transpose.
    int             m,                          ///< Height in rows of op(A) and C
    int             n,                          ///< Width in columns of op(B) and C
    int             k,                          ///< Width in columns of op(A) and height in rows of op(B)
    int32_t         alpha,                      ///< Scalar used for multiplicands
    int8_t          *d_a,                       ///< Device pointer to matrix A array values
    int8_t          *d_b,                       ///< Device pointer to matrix B array values
    int32_t         beta,                       ///< Scalar used for addend
    int32_t         *d_c,                       ///< Device pointer to matrix C array values
    cudaStream_t    stream = 0,                 ///< CUDA stream to launch kernels within.  Default is stream<sub>0</sub>.
    bool            debug_synchronous = false)  ///< Whether or not to synchronize the stream after every kernel launch to check for errors.
{
    return cublasGemmEx(
        cublas_handle,
        transform_a,
        transform_b,
        m,
        n,
        k,
        (void*) &alpha,
        (void*) d_a,
        CUDA_R_8I,
        (transform_a == CUBLAS_OP_N) ? m : k,
        (void*) d_b,
        CUDA_R_8I,
        (transform_b == CUBLAS_OP_N) ? k : n,
        (void*) &beta,
        (void*) d_c,
        CUDA_R_32I,
        m,
        CUDA_R_32I,
        CUBLAS_GEMM_DFALT);
}


/**
 * Dispatch cuBLAS hgemm
 */
cublasStatus_t cublas_gemm_dispatch(
    cublasHandle_t    cublas_handle,            ///< CUBLAS handle
    cublasOperation_t transform_a,               ///< Transform op(A) that is non- or (conj.) transpose.
    cublasOperation_t transform_b,               ///< Transform op(B) that is non- or (conj.) transpose.
    int             m,                          ///< Height in rows of op(A) and C
    int             n,                          ///< Width in columns of op(B) and C
    int             k,                          ///< Width in columns of op(A) and height in rows of op(B)
    __half          alpha,                      ///< Scalar used for multiplicands
    __half          *d_a,                       ///< Device pointer to matrix A array values
    __half          *d_b,                       ///< Device pointer to matrix B array values
    __half          beta,                       ///< Scalar used for addend
    __half          *d_c,                       ///< Device pointer to matrix C array values
    cudaStream_t    stream = 0,                 ///< CUDA stream to launch kernels within.  Default is stream<sub>0</sub>.
    bool            debug_synchronous = false)  ///< Whether or not to synchronize the stream after every kernel launch to check for errors.
{
    return cublasHgemm(
        cublas_handle, transform_a, transform_b,
        m, n, k,
        &alpha,
        d_a,
        (transform_a == CUBLAS_OP_N) ? m : k,
        d_b,
        (transform_b == CUBLAS_OP_N) ? k : n,
        &beta,
        d_c,
        m);

}


/**
 * Dispatch cuBLAS sgemm
 */
cublasStatus_t cublas_gemm_dispatch(
    cublasHandle_t    cublas_handle,            ///< CUBLAS handle
    cublasOperation_t transform_a,               ///< Transform op(A) that is non- or (conj.) transpose.
    cublasOperation_t transform_b,               ///< Transform op(B) that is non- or (conj.) transpose.
    int             m,                          ///< Height in rows of op(A) and C
    int             n,                          ///< Width in columns of op(B) and C
    int             k,                          ///< Width in columns of op(A) and height in rows of op(B)
    float           alpha,                      ///< Scalar used for multiplicands
    float           *d_a,                       ///< Device pointer to matrix A array values
    float           *d_b,                       ///< Device pointer to matrix B array values
    float           beta,                       ///< Scalar used for addend
    float           *d_c,                       ///< Device pointer to matrix C array values
    cudaStream_t    stream = 0,                 ///< CUDA stream to launch kernels within.  Default is stream<sub>0</sub>.
    bool            debug_synchronous = false)  ///< Whether or not to synchronize the stream after every kernel launch to check for errors.
{
    return cublasSgemm(
        cublas_handle, transform_a, transform_b,
        m, n, k,
        &alpha,
        d_a,
        (transform_a == CUBLAS_OP_N) ? m : k,
        d_b,
        (transform_b == CUBLAS_OP_N) ? k : n,
        &beta,
        d_c,
        m);
}


/**
 * Dispatch cuBLAS dgemm
 */
cublasStatus_t cublas_gemm_dispatch(
    cublasHandle_t    cublas_handle,            ///< CUBLAS handle
    cublasOperation_t transform_a,               ///< Transform op(A) that is non- or (conj.) transpose.
    cublasOperation_t transform_b,               ///< Transform op(B) that is non- or (conj.) transpose.
    int             m,                          ///< Height in rows of op(A) and C
    int             n,                          ///< Width in columns of op(B) and C
    int             k,                          ///< Width in columns of op(A) and height in rows of op(B)
    double          alpha,                      ///< Scalar used for multiplicands
    double          *d_a,                       ///< Device pointer to matrix A array values
    double          *d_b,                       ///< Device pointer to matrix B array values
    double          beta,                       ///< Scalar used for addend
    double          *d_c,                       ///< Device pointer to matrix C array values
    cudaStream_t    stream = 0,                 ///< CUDA stream to launch kernels within.  Default is stream<sub>0</sub>.
    bool            debug_synchronous = false)  ///< Whether or not to synchronize the stream after every kernel launch to check for errors.
{
    return cublasDgemm(
        cublas_handle, transform_a, transform_b,
        m, n, k,
        &alpha,
        d_a, (transform_a == CUBLAS_OP_N) ? m : k,
        d_b, (transform_b == CUBLAS_OP_N) ? k : n,
        &beta,
        d_c, m);
}

/**
 * Dispatch cuBLAS Tensor Cores GEMM
 */
cublasStatus_t cublas_gemm_dispatch(
    cublasHandle_t    cublas_handle,            ///< CUBLAS handle
    cublasOperation_t transform_a,               ///< Transform op(A) that is non- or (conj.) transpose.
    cublasOperation_t transform_b,               ///< Transform op(B) that is non- or (conj.) transpose.
    int             m,                          ///< Height in rows of op(A) and C
    int             n,                          ///< Width in columns of op(B) and C
    int             k,                          ///< Width in columns of op(A) and height in rows of op(B)
    float           alpha,                      ///< Scalar used for multiplicands
    half            *d_a,                       ///< Device pointer to matrix A array values
    half            *d_b,                       ///< Device pointer to matrix B array values
    float           beta,                       ///< Scalar used for addend
    float           *d_c,                       ///< Device pointer to matrix C array values
    cudaStream_t    stream = 0,                 ///< CUDA stream to launch kernels within.  Default is stream<sub>0</sub>.
    bool            debug_synchronous = false)  ///< Whether or not to synchronize the stream after every kernel launch to check for errors.
{
    return cublasGemmEx(
        cublas_handle,
        transform_a,
        transform_b,
        m,
        n,
        k,
        (void*) &alpha,
        (void*) d_a,
        CUDA_R_16F,
        (transform_a == CUBLAS_OP_N) ? m : k,
        (void*) d_b,
        CUDA_R_16F,
        (transform_b == CUBLAS_OP_N) ? k : n,
        (void*) &beta,
        (void*) d_c,
        CUDA_R_32F,
        m,
        CUDA_R_32F,
        CUBLAS_GEMM_DFALT_TENSOR_OP);
}


/**
 * Uses cuBLAS to compute gemm on device matrices (unspecialized)
 */
template <
    gemm::tiling_strategy::kind_t            _TilingStrategy,   ///< Tile-sizing classification category
    math_operation_class_t                  _math_op,
    matrix_transform_t::kind_t              _TransformA,    ///< Transformation op for matrix A
    matrix_transform_t::kind_t              _TransformB,    ///< Transformation op for matrix B
    typename                                _value,         ///< Multiplicand value type (matrices A and B)
    typename                                _accum          ///< Accumulator value type (matrix C and scalars)
>
struct cublas_gemm
{
    //
    // Type alias definitions
    //

    static const gemm::tiling_strategy::kind_t   TilingStrategy = _TilingStrategy;
    static const math_operation_class_t         math_op = _math_op;
    static const matrix_transform_t::kind_t     TransformA = _TransformA;
    static const matrix_transform_t::kind_t     TransformB = _TransformB;

    using value_t = _value;
    using accum_t = _accum;

    /// Launches a GEMM
    gemm::launch_configuration operator()(
        cublasHandle_t                          cublas_handle,              ///< CUBLAS handle
        int m,
        int n,
        int k,
        value_t                                 *A,                         ///< A matrix
        value_t                                 *B,                         ///< B matrix
        accum_t                                 *C,                         ///< C matrix
        accum_t                                 alpha,                      ///< Scalar used for multiplicands
        accum_t                                 beta,                       ///< Scalar used for addend
        cudaStream_t                            stream = 0,                 ///< CUDA stream to launch kernels within.  Default is stream<sub>0</sub>.
        bool                                    debug_synchronous = false)  ///< Whether or not to synchronize the stream after every kernel launch to check for errors.
    {
        cublasStatus_t cublas_error = cublas_gemm_dispatch(
            cublas_handle,
            (cublasOperation_t) TransformA,
            (cublasOperation_t) TransformB,
            m,
            n,
            k,
            alpha,
            A,
            B,
            beta,
            C,
            stream,
            debug_synchronous);

        cudaError_t error;
        if (cublas_error != CUBLAS_STATUS_SUCCESS)
        {
            if (cublas_error == CUBLAS_STATUS_NOT_SUPPORTED) {
                return gemm::launch_configuration(cudaErrorInvalidValue);
            }

            error = cudaGetLastError();
            if (error == cudaSuccess) {
                return gemm::launch_configuration(cudaErrorUnknown);
            }
            return error;
        }

        // Check for failure to launch
        if (CUDA_PERROR_DEBUG(error = cudaPeekAtLastError()))
            return gemm::launch_configuration(error);

        // Sync the stream if specified to flush runtime errors
        if (debug_synchronous && (CUDA_PERROR_DEBUG(error = cudaStreamSynchronize(stream))))
            return gemm::launch_configuration(error);

        return gemm::launch_configuration(error);
    }
};


} // namespace cutlass
