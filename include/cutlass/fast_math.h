/***************************************************************************************************
 * Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/

#pragma once

#if defined(__CUDACC_RTC__)
#include <cuda/std/cstdint>
#else
#include <cstdint>
#endif

#include "cutlass/cutlass.h"

/**
 * \file
 * \brief Math utilities
 */

namespace cutlass {

/******************************************************************************
 * Static math utilities
 ******************************************************************************/

/**
 * Statically determine if N is a power-of-two
 */
template <int N>
struct is_pow2 {
  static bool const value = ((N & (N - 1)) == 0);
};

/**
 * Statically determine log2(N), rounded down
 */
template <int N, int CurrentVal = N, int Count = 0>
struct log2_down {
  /// Static logarithm value
  enum { value = log2_down<N, (CurrentVal >> 1), Count + 1>::value };
};

// Base case
template <int N, int Count>
struct log2_down<N, 1, Count> {
  enum { value = Count };
};

/**
 * Statically determine log2(N), rounded up
 */
template <int N, int CurrentVal = N, int Count = 0>
struct log2_up {
  /// Static logarithm value
  enum { value = log2_up<N, (CurrentVal >> 1), Count + 1>::value };
};

// Base case
template <int N, int Count>
struct log2_up<N, 1, Count> {
  enum { value = ((1 << Count) < N) ? Count + 1 : Count };
};

/**
 * Statically estimate sqrt(N) to the nearest power-of-two
 */
template <int N>
struct sqrt_est {
  enum { value = 1 << (log2_up<N>::value / 2) };
};

/**
 * For performing a constant-division with a compile-time assertion that the
 * Divisor evenly-divides the Dividend.
 */
template <int Dividend, int Divisor>
struct divide_assert {
  enum { value = Dividend / Divisor };

  static_assert((Dividend % Divisor == 0), "Not an even multiple");
};

/******************************************************************************
 * Rounding
 ******************************************************************************/

/**
 * Round dividend up to the nearest multiple of divisor
 */
template <typename dividend_t, typename divisor_t>
CUTLASS_HOST_DEVICE dividend_t round_nearest(dividend_t dividend, divisor_t divisor) {
  return ((dividend + divisor - 1) / divisor) * divisor;
}

/**
 * Greatest common divisor
 */
template <typename value_t>
CUTLASS_HOST_DEVICE value_t gcd(value_t a, value_t b) {
  for (;;) {
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
CUTLASS_HOST_DEVICE value_t lcm(value_t a, value_t b) {
  value_t temp = gcd(a, b);

  return temp ? (a / temp * b) : 0;
}

/**
 * log2 computation, what's the
 * difference between the below codes and
 * log2_up/down codes?
 */
template <typename value_t>
CUTLASS_HOST_DEVICE value_t clz(value_t x) {
  for (int i = 31; i >= 0; --i) {
    if ((1 << i) & x) return 31 - i;
  }
  return 32;
}

template <typename value_t>
CUTLASS_HOST_DEVICE value_t find_log2(value_t x) {
  int a = int(31 - clz(x));
  a += (x & (x - 1)) != 0;  // Round up, add 1 if not a power of 2.
  return a;
}


/**
 * Find divisor, using find_log2
 */
CUTLASS_HOST_DEVICE 
void find_divisor(unsigned int& mul, unsigned int& shr, unsigned int denom) {
  if (denom == 1) {
    mul = 0;
    shr = 0;
  } else {
    unsigned int p = 31 + find_log2(denom);
    unsigned m = unsigned(((1ull << p) + unsigned(denom) - 1) / unsigned(denom));

    mul = m;
    shr = p - 32;
  }
}

/**
 * Find quotient and remainder using device-side intrinsics
 */
CUTLASS_HOST_DEVICE 
void fast_divmod(int& quo, int& rem, int src, int div, unsigned int mul, unsigned int shr) {

  #if defined(__CUDA_ARCH__)
  // Use IMUL.HI if div != 1, else simply copy the source.
  quo = (div != 1) ? __umulhi(src, mul) >> shr : src;
  #else
  quo = int((div != 1) ? int(src * mul) >> shr : src);
  #endif

  // The remainder.
  rem = src - (quo * div);

}

// For long int input
CUTLASS_HOST_DEVICE
void fast_divmod(int& quo, int64_t& rem, int64_t src, int div, unsigned int mul, unsigned int shr) {

  #if defined(__CUDA_ARCH__)
  // Use IMUL.HI if div != 1, else simply copy the source.
  quo = (div != 1) ? __umulhi(src, mul) >> shr : src;
  #else
  quo = int((div != 1) ? (src * mul) >> shr : src);
  #endif
  // The remainder.
  rem = src - (quo * div);
}

/// Returns the smallest value in the half-open range [a, a+b) that is a multiple of b
CUTLASS_HOST_DEVICE
int round_up(int a, int b) {
  return ((a + b - 1) / b) * b;
}

/// Returns the ceiling of (a / b)
CUTLASS_HOST_DEVICE
int ceil_div(int a, int b) {
  return (a + b - 1) / b;
}

/******************************************************************************
 * Min/Max
 ******************************************************************************/

template <int A, int B>
struct Min {
  static int const kValue = (A < B) ? A : B;
};

template <int A, int B>
struct Max {
  static int const kValue = (A > B) ? A : B;
};

CUTLASS_HOST_DEVICE
constexpr int const_min(int a, int b) {
    return (b < a ? b : a);
}

CUTLASS_HOST_DEVICE
constexpr int const_max(int a, int b) {
    return (b > a ? b : a);
}

}  // namespace cutlass
