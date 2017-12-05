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
 * Matrix data structure providing basic CPU-based algorithms and
 * operations that can be cloned and synchronized in GPU device memory
 */

#include <vector>
#include <fstream>

#include <cutlass/util/debug.h>
#include "../cutlass/util/matrix_transform.h"
#include "half.h"


namespace cutlass {

/**
 * \brief Matrix data structure providing basic CPU-based algorithms and
 * operations that be synchronized with a GPU-based replica
 */
template <typename value_t>
struct matrix
{
    // Host value type (must be convertible to/from value_t)
    typedef typename nv_std::conditional<
            (nv_std::is_same<value_t, __half>::value),  // If (value_t == __half) ...
            half_t,                                     // ... use half_t internally for host storage, else...
            value_t>::type                              // ... use value_t directly
        host_value_t;


    //-----------------------------------------------------------------------------
    // Data members
    //-----------------------------------------------------------------------------

private:

    /// M dimension (height in rows)
    int _m;

    /// N dimension (width in columns)
    int _n;

    /// Data array on host
    std::vector<host_value_t> _h_data;

    /// Clone of data array on GPU device
    value_t *_d_data;

    /// GPU Device identifier that clone synchronizes with
    int _device_id;

public:

    //-----------------------------------------------------------------------------
    // Lifetime and synchronization
    //-----------------------------------------------------------------------------

    /**
     * Constructor: zero-initializes the matrix.
     */
    matrix(
        int m,  ///< Height of the matrix in rows
        int n)  ///< Width of the matrix in columns
    :
        _m(m),
        _n(n),
        _d_data(NULL),
        _device_id(0)
    {
        _h_data.resize(_m * _n, 0);
        CUDA_PERROR_EXIT(cudaMalloc((void ** )&_d_data, sizeof(value_t) * _m * _n));
        CUDA_PERROR_EXIT(cudaGetDevice(&_device_id));
    }

    /// Destructor
    ~matrix()
    {
        if (_d_data)
        {
            CUDA_PERROR_EXIT(cudaFree(_d_data));
        }
    }

    /**
     * Synchronize the GPU-based replica with the current host-based matrix data
     */
    void sync_device()
    {
        size_t bytes = _m * _n * sizeof(value_t);
        CUDA_PERROR_EXIT(cudaMemcpy(_d_data, &_h_data[0], bytes, cudaMemcpyHostToDevice));
    }


    /**
     * Synchronize the host-based replica with the current GPU-based matrix data
     */
    void sync_host()
    {
        size_t bytes = _m * _n * sizeof(value_t);
        CUDA_PERROR_EXIT(cudaMemcpy(&_h_data[0], _d_data, bytes, cudaMemcpyDeviceToHost));
    }


    //-----------------------------------------------------------------------------
    // Inspectors
    //-----------------------------------------------------------------------------

    /**
     * Return the height of the matrix, subject to the optional \p transpose_op
     */
    int height(matrix_transform_t transpose_op = matrix_transform_t::NonTranspose) const
    {
        switch (transpose_op)
        {
            case matrix_transform_t::NonTranspose :    return _m;
            case matrix_transform_t::Transpose :       return _n;
            default: return -1;
        }
    }


    /**
     * Return the width of the matrix, subject to the optional \p transpose_op
     */
    int width(matrix_transform_t transpose_op = matrix_transform_t::NonTranspose) const
    {
        switch (transpose_op)
        {
            case matrix_transform_t::NonTranspose :    return _n;
            case matrix_transform_t::Transpose :       return _m;
            default: return -1;
        }
    }


    /**
     * Return item at (x, y) coordinate of matrix, subject to the optional \p transform op
     */
    host_value_t get(
        int x,
        int y,
        matrix_transform_t transpose_op = matrix_transform_t::NonTranspose) const
    {
        switch (transpose_op)
        {
            case matrix_transform_t::NonTranspose :    return _h_data[y + (x * _m)];
            case matrix_transform_t::Transpose :       return _h_data[x + (y * _m)];
            default: return 0;
        }
    }


    /**
     * Return the distance (in items) within memory between elements of two
     * consecutive columns which have the same row index, subject to the optional \p transform op
     */
    int leading_dim(matrix_transform_t transpose_op = matrix_transform_t::NonTranspose) const
    {
        switch (transpose_op)
        {
            case matrix_transform_t::NonTranspose :    return _m;
            case matrix_transform_t::Transpose :       return _n;
            default: return 0;
        }
    }

    /**
     * Get host data pointer
     */
    value_t* h_data()
    {
        return _h_data.data();
    }


    /**
     * Get host data pointer
     */
    value_t const* h_data() const
    {
        return _h_data.data();
    }

    /**
     * Get device data pointer
     */
    value_t const* d_data() const
    {
        return _d_data;
    }

    /**
     * Get device data pointer
     */
    value_t * d_data()
    {
        return _d_data;
    }

    //-----------------------------------------------------------------------------
    // Initialization
    //-----------------------------------------------------------------------------

	/**
     * Initialize matrix values with a 2D "ramp" defined as
     * <tt>values(x, y) = (y * rs) + (x * cs)</tt>
     */
    void fill_ramp(
        host_value_t rs,
        host_value_t cs)
    {
        for (int x = 0; x < _n; x++)
        {
            for (int y = 0; y < _m; y++)
            {
                _h_data[y + (x * _m)] = host_value_t((y * rs) + (x * cs));
            }
        }
    }


	/**
	 * Initialize matrix values such that all the elements of the principal diagonal
     * are ones and all other elements are zeros
     */
    void fill_identity()
    {
        for (int j = 0; j < _n; j++)
        {
            for (int i = 0; i < _m; i++)
            {
                _h_data[i + j * _m] = host_value_t(i == j ? 1 : 0);
            }
        }
    }


	/**
	 * Initialize matrix values using the random number \p generator.  The
     * \p generator reference is assumed to be a nullary functor that returns
     * values convertible to the matrix \p value_t.
     */
    template <typename T>
    void fill_random(T & generator)
    {
        for (int j = 0; j < _n; j++)
        {
            for (int i = 0; i < _m; i++)
            {
                _h_data[i + j * _m] = (value_t) generator();
            }
        }
    }


    /**
     * Element-wise matrix addition
     */
    matrix & operator+=(matrix const &mat)
    {
        for (int j = 0; j < _n; j++)
        {
            for (int i = 0; i < _m; i++)
            {
                _h_data[i + j * _m] += mat._h_data[i + j * _m];
            }
        }
        return *this;
    }

    /**
     * Element-wise matrix subtraction
     */
    matrix & operator-=(matrix const &mat)
    {
        for (int j = 0; j < _n; j++)
        {
            for (int i = 0; i < _m; i++)
            {
                _h_data[i + j * _m] -= mat._h_data[i + j * _m];
            }
        }
        return *this;
    }

    //-----------------------------------------------------------------------------
    // Output
    //-----------------------------------------------------------------------------

    /**
     * Prints matrix in CSV to output stream
     */
    template <typename _hv_t>
    std::ostream & write_matrix(std::ostream &out, _hv_t)
    {
        for (int i = 0; i < _m; i++)
        {
            for (int j = 0; j < _n; j++)
            {
                out << (j ? "," : "") << _h_data[i + j * _m];
            }
            out << "\n";
        }
        return out;
    }


    /**
     * Prints matrix in CSV to output stream
     */
    std::ostream & write_matrix(std::ostream &out, int8_t)
    {
        for (int i = 0; i < _m; i++)
        {
            for (int j = 0; j < _n; j++)
            {
                out << (j ? "," : "") << int32_t(_h_data[i + j * _m]);
            }
            out << "\n";
        }
        return out;
    }


    /**
     * Prints matrix in CSV to output stream
     */
    std::ostream & write_matrix(std::ostream &out)
    {
        return write_matrix(out, _h_data[0]);
    }


    //-----------------------------------------------------------------------------
    // Floating point "almost-equal" utilities
    //-----------------------------------------------------------------------------

    static bool almost_equal_ulps(half_t a, half_t b, int max_ulps)
    {
        if (a == b)
            return true;

        int32_t int_diff = abs(a.raw() - b.raw());
        if (int_diff <= max_ulps)
            return true;
        return false;
    }


    static bool almost_equal_ulps(float a, float b, int max_ulps)
    {
        if (a == b)
            return true;
        int32_t int_diff = abs(*(int32_t*)&a - *(int32_t*)&b);
        if (int_diff <= max_ulps)
            return true;
        return false;
    }


    static bool almost_equal_ulps(double a, double b, int max_ulps)
    {
        if (a == b)
            return true;
        int64_t int_diff = abs(*(int64_t*)&a - *(int64_t*)&b);
        if (int_diff <= max_ulps)
            return true;
        return false;
    }

    static bool almost_equal_ulps(int32_t a, int32_t b, int max_ulps)
    {
        return (a == b);
    }


    //-----------------------------------------------------------------------------
    // matrix operations
    //-----------------------------------------------------------------------------


    /**
     * Returns matrix equality
     */
    bool operator==(const matrix<value_t> &mat) const
    {
        int max_ulps = 30;

        if (_m != mat._m || _n != mat._n)
        {
            fprintf(stderr, "Error: dimension mismatch during matrix comparison.\n"); exit(1);
        }

        for (int j = 0; j < _n; j++)
        {
            for (int i = 0; i < _m; i++)
            {
                if (!almost_equal_ulps(_h_data[i + j * _m], mat._h_data[i + j * _m], max_ulps))
                {
                    return false;
                }
            }
        }
        return true;
    }


    /**
     * Returns matrix inequality
     */
    bool operator!=(const matrix<value_t> &mat) const
    {
        return !(*this == mat);
    }


    /**
     * Computes this = (alpha * op(A) * op(B)) + (beta * this), specialized for gemm_nn
     */
    template <typename multiplicand_t>
    void gemm(
        matrix_transform_t              transform_a,
        matrix_transform_t              transform_b,
        host_value_t                    alpha,
        const matrix<multiplicand_t>    &A,
        const matrix<multiplicand_t>    &B,
        host_value_t                    beta)
    {
        // Sanity check dimensions
        if ((_m != A.height(transform_a)) ||
            (_n != B.width(transform_b)) ||
            (A.width(transform_a) != B.height(transform_b)))
        {
            fprintf(stderr, "Error: dimension mismatch during gemm.\n");
            exit(1);
        }

        int M = A.height(transform_a);
        int K = A.width(transform_a);
        int N = B.width(transform_b);

        // Even the host-side implementation utilizes a blocking structure to improve
        // verification performance
        int DimBlockM = (M % 16 == 0)  ? 16 : 1;
        int DimBlockN = (N % 16 == 0)  ? 16 : 1;

        for (int i = 0; i < M; i += DimBlockM)
        {
            for (int j = 0; j < N; j += DimBlockN)
            {
                for (int block_y = 0; block_y < DimBlockM; block_y++)
                {
                    for (int block_x = 0; block_x < DimBlockN; block_x++)
                    {
                        int y = i + block_y;
                        int x = j + block_x;

                        host_value_t accum(0);
                        for (int k = 0; k < K; k++)
                        {
                            accum += host_value_t(A.get(k, y, transform_a)) * host_value_t(B.get(x, k, transform_b));
                        }

                        _h_data[y + x * M] = (alpha * accum) + (beta * _h_data[y + x * M]);
                    }
                }
            }
        }
    }
};


} // namespace cutlass
