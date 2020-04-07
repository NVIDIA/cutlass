/***************************************************************************************************
 * Copyright (c) 2019, NVIDIA CORPORATION.  All rights reserved.
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
/*! 
    \file
    \brief Boost-like numeric conversion operator for CUTLASS numeric types
*/
#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"

#include "cutlass/array.h"
#include "cutlass/half.h"

namespace cutlass {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Floating-point rounding style similare to Standard Library's formats but supporting
/// additional rounding options.
enum class FloatRoundStyle {
  round_indeterminate,          ///< rounding mode unknown
  round_toward_zero,            ///< round toward zero
  round_to_nearest,             ///< round to nearest even
  round_toward_infinity,        ///< round toward infinity
  round_toward_neg_infinity     ///< round toward negative infinity
};

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  typename T,
  typename S,
  FloatRoundStyle Round = FloatRoundStyle::round_to_nearest
>
struct NumericConverter {

  using result_type = T;
  using source_type = S;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
    static result_type convert(source_type const & s) {

    return static_cast<result_type>(s);
  }

  CUTLASS_HOST_DEVICE
    result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Partial specializations for float => int8_t
//
/////////////////////////////////////////////////////////////////////////////////////////////////
template <FloatRoundStyle Round>
struct NumericConverter<int8_t, float, Round> {

  using result_type = int8_t;
  using source_type = float;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & s) {

    result_type result = static_cast<int8_t>(s);

    return result;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Partial specialization for float <= half_t
template <typename T, FloatRoundStyle Round>
struct NumericConverter<T, T, Round> {

  using result_type = T;
  using source_type = T;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & s) {

    return s;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Partial specializations for float <=> half_t
//
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Partial specialization for float <= half_t
template <FloatRoundStyle Round>
struct NumericConverter<float, half_t, Round> {

  using result_type = float;
  using source_type = half_t;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & s) {

    result_type result = static_cast<float>(s);

    return result;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/// Specialization for round-to-nearest
template <>
struct NumericConverter<half_t, float, FloatRoundStyle::round_to_nearest> {

  using result_type = half_t;
  using source_type = float;
  static FloatRoundStyle const round_style = FloatRoundStyle::round_to_nearest;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & s) {

    result_type result = static_cast<half_t>(s);

    return result;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/// Specialization for round-toward-zero
template <>
struct NumericConverter<half_t, float, FloatRoundStyle::round_toward_zero> {

  using result_type = half_t;
  using source_type = float;
  static FloatRoundStyle const round_style = FloatRoundStyle::round_toward_zero;

  /// Round toward zero
  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & flt) {

  #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)
    return half_t(__float2half_rz(flt));
  #else
    // software implementation rounds toward nearest even
    unsigned const& s = reinterpret_cast<unsigned const &>(flt);
    uint16_t sign = uint16_t((s >> 16) & 0x8000);
    int16_t exp = uint16_t(((s >> 23) & 0xff) - 127);
    int mantissa = s & 0x7fffff;
    uint16_t u = 0;

    if ((s & 0x7fffffff) == 0) {
      // sign-preserving zero
      return half_t::bitcast(sign);
    }

    if (exp > 15) {
      if (exp == 128 && mantissa) {
        // not a number
        u = 0x7fff;
      } else {
        // overflow to infinity
        u = sign | 0x7c00;
      }
      return half_t::bitcast(u);
    }

    if (exp >= -14) {
      // normal fp32 to normal fp16
      exp = uint16_t(exp + uint16_t(15));
      u = uint16_t(((exp & 0x1f) << 10));
      u = uint16_t(u | (mantissa >> 13));
    } else {
      // normal single-precision to subnormal half_t-precision representation
      int rshift = (-14 - exp);
      if (rshift < 32) {
        mantissa |= (1 << 23);
        mantissa = (mantissa >> rshift);
        u = (uint16_t(mantissa >> 13) & 0x3ff);
      } else {
        mantissa = 0;
        u = 0;
      }
    }

    u |= sign;

    return half_t::bitcast(u);

  #endif // defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Conversion and Clamp operator for Integers
//
/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  typename T,
  typename S
>
struct NumericConverterClamp {

  using result_type = T;
  using source_type = S;

  static_assert((platform::is_same<result_type, int32_t>::value ||
                 platform::is_same<result_type, int8_t>::value ||
                 platform::is_same<result_type, cutlass::int4b_t>::value),
                "Clamp is only needed for integer types");

  CUTLASS_HOST_DEVICE
    static result_type convert(source_type const & s) {
    NumericConverter<result_type, source_type> convert_op;
    result_type const kClamp_max =
        (0x1U << (sizeof_bits<result_type>::value - 1)) - 1;
    result_type const kClamp_min = -kClamp_max - 1;
    bool is_int_min = !(s > kClamp_min);
    bool is_int_max = !(s < kClamp_max);
    return is_int_min ? kClamp_min : (is_int_max ? kClamp_max : convert_op(s));
  }

  CUTLASS_HOST_DEVICE
    result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/// Partial specialization for clamping from a single-precision float.
template <
  typename T
>
struct NumericConverterClamp<T, float> {

  using result_type = T;
  using source_type = float;

  static_assert((platform::is_same<result_type, int32_t>::value ||
                 platform::is_same<result_type, int8_t>::value ||
                 platform::is_same<result_type, cutlass::int4b_t>::value),
                "Clamp is only needed for integer types");

  CUTLASS_HOST_DEVICE
    static result_type convert(source_type const & s) {

    NumericConverter<result_type, double> convert_op;

    double kClamp_max = double((1U << (sizeof_bits<result_type>::value - 1)) - 1);
    double kClamp_min = -kClamp_max - 1;

    double source = s;

    source = fmax(source, kClamp_min);
    source = fmin(source, kClamp_max);

    return convert_op(source);
  }

  CUTLASS_HOST_DEVICE
    result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Conversion operator for Array
//
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Conversion operator for Array
template <
  typename T,
  typename S,
  int N,
  FloatRoundStyle Round = FloatRoundStyle::round_to_nearest
>
struct NumericArrayConverter {

  using result_type = Array<T, N>;
  using source_type = Array<S, N>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & s) {

    result_type result;
    NumericConverter<T, S, Round> convert_;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      result[i] = convert_(s[i]);
    }

    return result;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

template <
  typename T,
  int N,
  FloatRoundStyle Round
>
struct NumericArrayConverter<T, T, N, Round> {

  using result_type = Array<T, N>;
  using source_type = Array<T, N>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return s;
  }
};


/////////////////////////////////////////////////////////////////////////////////////////////////

/// Partial specialization for Array<half, 2> <= Array<float, 2>, round to nearest
template <>
struct NumericArrayConverter<half_t, float, 2, FloatRoundStyle::round_to_nearest> {

  using result_type = Array<half_t, 2>;
  using source_type = Array<float, 2>;
  static FloatRoundStyle const round_style = FloatRoundStyle::round_to_nearest;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & source) {

    Array<half_t, 2> result;

    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)
      reinterpret_cast<__half2 &>(result) = __float22half2_rn(reinterpret_cast<float2 const &>(source));
    #else
      NumericConverter<half_t, float, round_style> convert_;
      result[0] = convert_(source[0]);
      result[1] = convert_(source[1]);
    #endif
    
    return result;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/// Partial specialization for Array<float, 2> <= Array<half_t, 2>, round to nearest
template <FloatRoundStyle Round>
struct NumericArrayConverter<float, half_t, 2, Round> {

  using result_type = Array<float, 2>;
  using source_type = Array<half_t, 2>;
  static FloatRoundStyle const round_style = FloatRoundStyle::round_to_nearest;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & source) {

    Array<float, 2> result;

    #if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 530)
      reinterpret_cast<float2 &>(result) = __half22float2(reinterpret_cast<__half2 const &>(source));
    #else
      NumericConverter<float, half_t, round_style> convert_;
      result[0] = convert_(source[0]);
      result[1] = convert_(source[1]);
    #endif
    
    return result;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Partial specialization for Array<half> <= Array<float>
template <
  int N,
  FloatRoundStyle Round
>
struct NumericArrayConverter<half_t, float, N, Round> {

  using result_type = Array<half_t, N>;
  using source_type = Array<float, N>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & source) {

    NumericArrayConverter<half_t, float, 2, Round> convert_vector_;
    NumericConverter<half_t, float, Round> convert_element_;

    result_type result;

    Array<half_t, 2> *result_ptr = reinterpret_cast<Array<half_t, 2> *>(&result);
    Array<float, 2> const *source_ptr = reinterpret_cast<Array<float, 2> const *>(&source);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = convert_vector_(source_ptr[i]);
    }

    if (N % 2) {
      result[N - 1] = convert_element_(source[N - 1]);
    }

    return result;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};


/// Partial specialization for Array<half> <= Array<float>
template <
  int N,
  FloatRoundStyle Round
>
struct NumericArrayConverter<float, half_t, N, Round> {

  using result_type = Array<float, N>;
  using source_type = Array<half_t, N>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & source) {

    NumericArrayConverter<float, half_t, 2, Round> convert_vector_;
    NumericConverter<float, half_t, Round> convert_element_;

    result_type result;

    Array<float, 2> *result_ptr = reinterpret_cast<Array<float, 2> *>(&result);
    Array<half_t, 2> const *source_ptr = reinterpret_cast<Array<half_t, 2> const *>(&source);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = convert_vector_(source_ptr[i]);
    }

    if (N % 2) {
      result[N - 1] = convert_element_(source[N - 1]);
    }

    return result;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};


/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////

// Conditional guards to enable partial specialization for packed integers 
#if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 720) && \
    ((__CUDACC_VER_MAJOR__ > 10) ||                     \
     ((__CUDACC_VER_MAJOR__ >= 10) && (__CUDACC_VER_MINOR__ >= 2)))

/// Partial specialization for Array<int8_t, 1> <= Array<int, 1>
template <
  FloatRoundStyle Round
>
struct NumericArrayConverter<int8_t, int, 1, Round> {

  using result_type = Array<int8_t, 1>;
  using source_type = Array<int, 1>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & source) {
    NumericConverter<int8_t, int, Round> convert_element_;

    result_type result;

    result[0] = convert_element_(source[0]);
   
    return result;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/// Partial specialization for Array<int8_t, 2> <= Array<int, 2>
template <
  FloatRoundStyle Round
>
struct NumericArrayConverter<int8_t, int, 2, Round> {

  using result_type = Array<int8_t, 2>;
  using source_type = Array<int, 2>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & source) {

    uint32_t tmp;

    asm volatile(
      "cvt.pack.sat.s8.s32.b32   %0, %2, %1, 0;\n"
      : "=r"(tmp) : "r"(source[0]), "r"(source[1]));

    uint16_t out = (tmp & 0xffff);
    return reinterpret_cast<result_type const &>(out);
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/// Partial specialization for Array<int8_t, 4> <= Array<int, 4>
template <
  FloatRoundStyle Round
>
struct NumericArrayConverter<int8_t, int, 4, Round> {

  using result_type = Array<int8_t, 4>;
  using source_type = Array<int, 4>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & source) {

    unsigned out;

    asm volatile(
      "{ .reg .u32 r4;"
      "cvt.pack.sat.s8.s32.b32   r4, %4, %3, 0;"
      "cvt.pack.sat.s8.s32.b32   %0, %2, %1, r4;"
      "}"
      : "=r"(out) : "r"(source[0]), "r"(source[1]), "r"(source[2]), "r"(source[3]));

    return reinterpret_cast<result_type const &>(out);
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/// Partial specialization for Array<int8_t> <= Array<int>
template <
  int N,
  FloatRoundStyle Round
>
struct NumericArrayConverter<int8_t, int, N, Round> {
  static_assert(!(N % 4), "N must be multiple of 4.");

  using result_type = Array<int8_t, N>;
  using source_type = Array<int, N>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & source) {

    NumericArrayConverter<int8_t, int, 4, Round> convert_vector_;

    result_type result;

    Array<int8_t, 4> *result_ptr = reinterpret_cast<Array<int8_t, 4> *>(&result);
    Array<int, 4> const *source_ptr = reinterpret_cast<Array<int, 4> const *>(&source);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 4; ++i) {
      result_ptr[i] = convert_vector_(source_ptr[i]);
    }

    return result;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};
#endif

/////////////////////////////////////////////////////////////////////////////////////////////////

#if defined(__CUDA_ARCH__) && (__CUDA_ARCH__ >= 750) && \
    ((__CUDACC_VER_MAJOR__ > 10) ||                     \
     ((__CUDACC_VER_MAJOR__ >= 10) && (__CUDACC_VER_MINOR__ >= 2)))

/// Partial specialization for Array<int4b_t, 8> <= Array<int, 8>
template <
  FloatRoundStyle Round
>
struct NumericArrayConverter<int4b_t, int, 8, Round> {

  using result_type = Array<int4b_t, 8>;
  using source_type = Array<int, 8>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & source) {

    unsigned out;

    asm volatile(
        "{ .reg .u32 r4;"
        "cvt.pack.sat.s4.s32.b32   r4, %8, %7, 0;"
        "cvt.pack.sat.s4.s32.b32   r4, %6, %5, r4;"
        "cvt.pack.sat.s4.s32.b32   r4, %4, %3, r4;"
        "cvt.pack.sat.s4.s32.b32   %0, %2, %1, r4;"
        "}"
        : "=r"(out)
        : "r"(source[0]), "r"(source[1]), "r"(source[2]), "r"(source[3]),
          "r"(source[4]), "r"(source[5]), "r"(source[6]), "r"(source[7]));

    return reinterpret_cast<result_type const &>(out);
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

/// Partial specialization for Array<int4b_t> <= Array<int>
template <
  int N,
  FloatRoundStyle Round
>
struct NumericArrayConverter<int4b_t, int, N, Round> {
  static_assert(!(N % 8), "N must be multiple of 8.");

  using result_type = Array<int4b_t, N>;
  using source_type = Array<int, N>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_HOST_DEVICE
  static result_type convert(source_type const & source) {

    NumericArrayConverter<int4b_t, int, 8, Round> convert_vector_;

    result_type result;

    Array<int4b_t, 8> *result_ptr = reinterpret_cast<Array<int4b_t, 8> *>(&result);
    Array<int, 8> const *source_ptr = reinterpret_cast<Array<int, 8> const *>(&source);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 8; ++i) {
      result_ptr[i] = convert_vector_(source_ptr[i]);
    }

    return result;
  }

  CUTLASS_HOST_DEVICE
  result_type operator()(source_type const &s) {
    return convert(s);
  }
};

#endif  // Conditional guards to enable partial specialization for packed integers

/////////////////////////////////////////////////////////////////////////////////////////////////

/// FastNumericArrayConverter only works when the source is within center range.
/// Conversion operator for Array
template <typename T, typename S, int N,
          FloatRoundStyle Round = FloatRoundStyle::round_to_nearest>
struct FastNumericArrayConverter {
  using result_type = Array<T, N>;
  using source_type = Array<S, N>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_DEVICE
  static result_type convert(source_type const &s) {
    result_type result;
    NumericArrayConverter<T, S, N, Round> convert_;

    return convert_(s);
  }

  CUTLASS_DEVICE
  result_type operator()(source_type const &s) { return convert(s); }
};

/// Partial specialization for Array<float> <= Array<int>
template <typename T, int N, FloatRoundStyle Round>
struct FastNumericArrayConverter<float, T, N, Round> {
  using result_type = Array<float, N>;
  using source_type = Array<T, N>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_DEVICE
  static result_type convert(source_type const &source) {
    result_type result;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      int tmp = source[i] + 1262485504 /*0x4B400000*/;
      result[i] = reinterpret_cast<float const &>(tmp) - 12582912.0f;
    }

    return result;
  }

  CUTLASS_DEVICE
  result_type operator()(source_type const &s) { return convert(s); }
};

/// Partial specialization for Array<int8_t, 4> <= Array<float, 4>
template <FloatRoundStyle Round>
struct FastNumericArrayConverter<int8_t, float, 4, Round> {
  using result_type = Array<int8_t, 4>;
  using source_type = Array<float, 4>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_DEVICE
  static result_type convert(source_type const &source) {
    Array<int32_t, 4> result;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < 4; ++i) {
      float tmp = source[i] + 12582912.0f;
      result[i] = reinterpret_cast<int32_t const &>(tmp);
    }

    result[0] = __byte_perm(result[0], result[1], 0x40);
    result[2] = __byte_perm(result[2], result[3], 0x40);
    result[0] = __byte_perm(result[0], result[2], 0x5410);

    return reinterpret_cast<result_type const &>(result[0]);
  }

  CUTLASS_DEVICE
  result_type operator()(source_type const &s) { return convert(s); }
};

/// Partial specialization for Array<int8_t> <= Array<float>
template <int N, FloatRoundStyle Round>
struct FastNumericArrayConverter<int8_t, float, N, Round> {
  static_assert(!(N % 4), "N must be multiple of 4.");

  using result_type = Array<int8_t, N>;
  using source_type = Array<float, N>;
  static FloatRoundStyle const round_style = Round;

  CUTLASS_DEVICE
  static result_type convert(source_type const &source) {
    FastNumericArrayConverter<int8_t, float, 4, Round> convert_vector_;

    result_type result;

    Array<int8_t, 4> *result_ptr =
        reinterpret_cast<Array<int8_t, 4> *>(&result);
    Array<float, 4> const *source_ptr =
        reinterpret_cast<Array<float, 4> const *>(&source);

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 4; ++i) {
      result_ptr[i] = convert_vector_(source_ptr[i]);
    }

    return result;
  }

  CUTLASS_DEVICE
  result_type operator()(source_type const &s) { return convert(s); }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Defines preferred rounding mode for a pair of types
template <typename T, typename S>
struct PreferredRoundingMode {
  static FloatRoundStyle const kRound = FloatRoundStyle::round_to_nearest;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
