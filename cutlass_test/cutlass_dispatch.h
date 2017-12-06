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
 * \file Dispatch routines for CUTLASS GEMM kernels
 */

// CUDA includes
#include <cublas_v2.h>

// Cutlass GEMM API
#include <cutlass/util/util.h>
#include <cutlass/gemm/dispatch.h>
#include <cutlass/gemm/epilogue_function.h>

// Test utilities
#include "util/type_conversion.h"

namespace cutlass {



/******************************************************************************
 * Cutlass dispatch entrypoints
 ******************************************************************************/

//
// Compile-time overrides for alignment and ragged handling.
//

// If zero, all feasible alignment options are supported.
#ifndef GEMM_ALIGNMENT
#define GEMM_ALIGNMENT 0
#endif

// If true, kernels are compiled with ragged handling enabled.
#ifndef GEMM_RAGGED
	#define GEMM_RAGGED true
#endif

//
// Dispatch logic given problem size specialization, math operation class, layout
// and type of operands, and epilogue operation.
//

/**
 * Cutlass GEMM dispatch
 */
template <
    gemm::tiling_strategy::kind_t            _TilingStrategy,        ///< Tile-sizing classification category
    math_operation_class_t                  _math_op,            // Indicates
    matrix_transform_t::kind_t              _TransformA,         ///< Transformation op for matrix A
    matrix_transform_t::kind_t              _TransformB,         ///< Transformation op for matrix B
    typename                                _value,              ///< Multiplicand value type (matrices A and B)
    typename                                _accum,              ///< Accumulator value type (matrix C and scalars)
    typename                                _epilogue_op_t       ///< Epilogue opeartion to update matrix C
        = gemm::blas_scaled_epilogue<_accum, _accum, _accum>
>
struct cutlass_gemm_dispatch
{
    //
    // Type alias definitions
    //

    static const gemm::tiling_strategy::kind_t       TilingStrategy = _TilingStrategy;
    static const math_operation_class_t             math_op = _math_op;
    static const matrix_transform_t::kind_t         TransformA = _TransformA;
    static const matrix_transform_t::kind_t         TransformB = _TransformB;

    using value_t = _value;
    using accum_t = _accum;
    using epilogue_op_t = _epilogue_op_t;

    //
    // Methods
    //

    /// Returns leading dimension for A matrix operand
    int leading_dim_a(int m, int k) const
    {
        return (TransformA == matrix_transform_t::NonTranspose ? m : k);
    }

    /// Returns leading dimension for B matrix operand
    int leading_dim_b(int k, int n) const
    {
        return (TransformB == matrix_transform_t::NonTranspose ? k : n);
    }

    /// Launches a GEMM
    template <int operand_alignment, int accumulator_alignment>
    gemm::launch_configuration launch(
        int                                     m,
        int                                     n,
        int                                     k,
        epilogue_op_t                           epilogue_op,
        value_t                                 *A,
        value_t                                 *B,
        accum_t                                 *C,
        cudaStream_t                            stream = 0,
        bool                                    debug_synchronous = false)
    {
        return gemm::device_gemm<
                TilingStrategy,
                math_op,
                TransformA,
                operand_alignment,
                TransformB,
                operand_alignment,
                value_t,
                accum_t,
                epilogue_op_t,
                accumulator_alignment>
            (
                m,
                n,
                k,
                epilogue_op,
                A,
                B,
                C,
                stream,
                debug_synchronous);
    }

    /// Dispatches a CUTLASS GEMM
    gemm::launch_configuration operator()(
        cublasHandle_t  handle,                     ///< CUBLAS handle
        int             m,                          ///< Rows of GEMM problem
        int             n,                          ///< Columns of GEMM problem
        int             k,                          ///< Inner dimension of GEMM problem
        value_t         *A,                         ///< A matrix
        value_t         *B,                         ///< B matrix
        accum_t         *C,                         ///< C matrix
        accum_t         alpha,                      ///< Scalar used for multiplicands
        accum_t         beta,                       ///< Scalar used for addend
        cudaStream_t    stream = 0,                 ///< CUDA stream to launch kernels within.
        bool            debug_synchronous = false)  ///< Whether or not to synchronize the stream
                                                    ///  after every kernel launch to check for errors.
    {

        // Forces kernel selection to choose specific alignment (in bytes)
        int const force_operand_alignment = GEMM_ALIGNMENT;

        // Problem size must be multiple of the smallest vector load size
        typedef value_t operand_load_t;
        int const accumulator_alignment = sizeof(accum_t);

        int const lda = leading_dim_a(m, k);
        int const ldb = leading_dim_b(k, n);

        epilogue_op_t epilogue(alpha, beta);

        // TODO: opportunity for metaprogramming loop

        // Prefer the largest granularity of vector load that is compatible with
        // problem size and data alignment.
        if ((!force_operand_alignment || force_operand_alignment == 16) &&
            !((sizeof(operand_load_t) * lda) % 16) &&
            !((sizeof(operand_load_t) * ldb) % 16))
        {
            #if !(GEMM_ALIGNMENT) || (GEMM_ALIGNMENT == 16)
                return launch<__NV_STD_MAX(16, sizeof(value_t)), accumulator_alignment>(
                        m,
                        n,
                        k,
                        epilogue,
                        A,
                        B,
                        C,
                        stream,
                        debug_synchronous);
            #endif
        }
        else if ((!force_operand_alignment || force_operand_alignment == 8) &&
            !((sizeof(operand_load_t) * lda) % 8) &&
            !((sizeof(operand_load_t) * ldb) % 8))
        {
            #if !(GEMM_ALIGNMENT) || (GEMM_ALIGNMENT == 8)
                return launch<__NV_STD_MAX(8, sizeof(value_t)), accumulator_alignment>(
                        m,
                        n,
                        k,
                        epilogue,
                        A,
                        B,
                        C,
                        stream,
                        debug_synchronous);
            #endif
        }
        else if ((!force_operand_alignment || force_operand_alignment == 4) &&
            !((sizeof(operand_load_t) * lda) % 4) &&
            !((sizeof(operand_load_t) * ldb) % 4))
        {
            #if !(GEMM_ALIGNMENT) || (GEMM_ALIGNMENT == 4)
                return launch<__NV_STD_MAX(4, sizeof(value_t)), accumulator_alignment>(
                        m,
                        n,
                        k,
                        epilogue,
                        A,
                        B,
                        C,
                        stream,
                        debug_synchronous);
            #endif
        }
        else if ((!force_operand_alignment || force_operand_alignment == 2) &&
            !((sizeof(operand_load_t) * lda) % 2) &&
            !((sizeof(operand_load_t) * ldb) % 2))
        {
            // 16-bit alignment only supported for HGEMM
            #if defined(TEST_HGEMM) || defined(TEST_WGEMM)
                #if !(GEMM_ALIGNMENT) || (GEMM_ALIGNMENT == 2)
                    return launch<__NV_STD_MAX(2, sizeof(value_t)), accumulator_alignment>(
                            m,
                            n,
                            k,
                            epilogue,
                            A,
                            B,
                            C,
                            stream,
                            debug_synchronous);
                #endif
            #endif
        }

        return gemm::launch_configuration(cudaErrorInvalidValue);
    }
};


} // namespace cutlass
