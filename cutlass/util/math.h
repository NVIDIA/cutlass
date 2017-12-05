/*
 * Copyright 1993-2017 NVIDIA Corporation.  All rights reserved.
 *
 * NOTICE TO LICENSEE:
 *
 * This source code and/or documentation ("Licensed Deliverables") are
 * subject to NVIDIA intellectual property rights under U.S. and
 * international Copyright laws.
 *
 * These Licensed Deliverables contained herein is PROPRIETARY and
 * CONFIDENTIAL to NVIDIA and is being provided under the terms and
 * conditions of a form of NVIDIA software license agreement by and
 * between NVIDIA and Licensee ("License Agreement") or electronically
 * accepted by Licensee.  Notwithstanding any terms or conditions to
 * the contrary in the License Agreement, reproduction or disclosure
 * of the Licensed Deliverables to any third party without the express
 * written consent of NVIDIA is prohibited.
 *
 * NOTWITHSTANDING ANY TERMS OR CONDITIONS TO THE CONTRARY IN THE
 * LICENSE AGREEMENT, NVIDIA MAKES NO REPRESENTATION ABOUT THE
 * SUITABILITY OF THESE LICENSED DELIVERABLES FOR ANY PURPOSE.  IT IS
 * PROVIDED "AS IS" WITHOUT EXPRESS OR IMPLIED WARRANTY OF ANY KIND.
 * NVIDIA DISCLAIMS ALL WARRANTIES WITH REGARD TO THESE LICENSED
 * DELIVERABLES, INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY,
 * NONINFRINGEMENT, AND FITNESS FOR A PARTICULAR PURPOSE.
 * NOTWITHSTANDING ANY TERMS OR CONDITIONS TO THE CONTRARY IN THE
 * LICENSE AGREEMENT, IN NO EVENT SHALL NVIDIA BE LIABLE FOR ANY
 * SPECIAL, INDIRECT, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, OR ANY
 * DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
 * WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS
 * ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE
 * OF THESE LICENSED DELIVERABLES.
 *
 * U.S. Government End Users.  These Licensed Deliverables are a
 * "commercial item" as that term is defined at 48 C.F.R. 2.101 (OCT
 * 1995), consisting of "commercial computer software" and "commercial
 * computer software documentation" as such terms are used in 48
 * C.F.R. 12.212 (SEPT 1995) and is provided to the U.S. Government
 * only as a commercial end item.  Consistent with 48 C.F.R.12.212 and
 * 48 C.F.R. 227.7202-1 through 227.7202-4 (JUNE 1995), all
 * U.S. Government End Users acquire the Licensed Deliverables with
 * only those rights set forth herein.
 *
 * Any use of the Licensed Deliverables in individual and commercial
 * software must include, in the user documentation and internal
 * comments to the code, the above Disclaimer and U.S. Government End
 * Users Notice.
 */

#pragma once

/**
 * \file
 * \brief Math utilities
 */

#include "nv_std.h"

namespace cutlass {


/******************************************************************************
 * Static math utilities
 ******************************************************************************/

/**
 * Statically determine if N is a power-of-two
 */
template <int N>
struct is_pow2 : nv_std::integral_constant<bool, (N & (N - 1)) == 0>
{};





/**
 * Statically determine log2(N), rounded down
 */
template <int N, int CurrentVal = N, int Count = 0>
struct log2_down
{
    /// Static logarithm value
    enum { value = log2_down<N, (CurrentVal >> 1), Count + 1>::value };
};

// Base case
template <int N, int Count>
struct log2_down<N, 1, Count>
{
    enum { value = Count };
};




/**
 * Statically determine log2(N), rounded up
 */
template <int N, int CurrentVal = N, int Count = 0>
struct log2_up
{
    /// Static logarithm value
    enum { value = log2_up<N, (CurrentVal >> 1), Count + 1>::value };
};

// Base case
template <int N, int Count>
struct log2_up<N, 1, Count>
{
    enum { value = ((1 << Count) < N) ? Count + 1 : Count };
};



/**
 * Statically estimate sqrt(N) to the nearest power-of-two
 */
template <int N>
struct sqrt_est
{
    enum { value = 1 << (log2_up<N>::value / 2) };
};



/**
 * For performing a constant-division with a compile-time assertion that the
 * Divisor evenly-divides the Dividend.
 */
template <int Dividend, int Divisor>
struct divide_assert
{
    enum { value =  Dividend / Divisor};

    static_assert((Dividend % Divisor == 0), "Not an even multiple");
};





/******************************************************************************
 * Rounding
 ******************************************************************************/

/**
 * Round dividend up to the nearest multiple of divisor
 */
template <typename dividend_t, typename divisor_t>
inline __host__ __device__
dividend_t round_nearest(dividend_t dividend, divisor_t divisor)
{
    return ((dividend + divisor - 1) / divisor) * divisor;
}


/**
 * Greatest common divisor
 */
template <typename value_t>
inline __host__ __device__
value_t gcd(value_t a, value_t b)
{
    for (;;)
    {
        if (a == 0) return b;
        b %= a;
        if (b == 0) return a;
        a %= b;
    }
}


/**
 * Least common multiple
 */
template <typename value_t>
inline __host__ __device__
value_t lcm(value_t a, value_t b)
{
    value_t temp = gcd(a, b);

    return temp ? (a / temp * b) : 0;
}


} // namespace cutlass

