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
 * Epilogue operation to compute final output
 */

namespace cutlass {
namespace gemm {

    //// Used by GEMM to compute the final result C <= alpha * accumulator + beta * C
    template <
        typename accum_t,
        typename output_t,
        typename scalar_t
    >
    class blas_scaled_epilogue
    {
    public:

        scalar_t alpha;
        scalar_t beta;

        inline __device__ __host__
        blas_scaled_epilogue(
            scalar_t alpha,
            scalar_t beta)
        :
            alpha(alpha),
            beta(beta)
        {}


        /// Epilogue operator
        inline __device__ __host__
        output_t operator()(
            accum_t accumulator,
            output_t c,
            size_t idx) const
        {
            return output_t(alpha * scalar_t(accumulator) + beta * scalar_t(c));
        }


        /// Epilogue operator
        inline __device__ __host__
        output_t operator()(
            accum_t accumulator,
            size_t idx) const
        {
            return output_t(alpha * scalar_t(accumulator));
        }

        /**
         * Configure epilogue as to whether the thread block is a secondary
         * accumulator in an inter-block k-splitting scheme
         */
        inline __device__
        void set_secondary_accumulator()
        {
            beta = scalar_t(1);
        }


        /// Return whether the beta-scaled addend needs initialization
        inline __device__
        bool must_init_addend()
        {
            return (beta != scalar_t(0));
        }
    };




} // namespace gemm
} // namespace cutlass
