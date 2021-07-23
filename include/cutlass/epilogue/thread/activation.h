/***************************************************************************************************
 * Copyright (c) 2017-2021, NVIDIA CORPORATION.  All rights reserved.
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
/*! \file
    \brief This extends the contents of cutlass/functional.h with frequently used activation functions.

*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"
#include "cutlass/constants.h"
#include "cutlass/complex.h"
#include "cutlass/array.h"
#include "cutlass/half.h"
#include "cutlass/functional.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace epilogue {
namespace thread {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename T>
struct Identity {
  CUTLASS_HOST_DEVICE
  T operator()(T value) const {
    return value;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// ReLu operator - propagates NaNs
template <typename T>
struct ReLu {
  CUTLASS_HOST_DEVICE
  T operator()(T const & threshold, T value) const {
    if (value < threshold) {
      value = threshold;
    }
    return value;
  }
  CUTLASS_HOST_DEVICE
  T operator()(T value) const {
    if (value < T()) {
      value = T();
    }
    return value;
  }
};

template <typename T, int N>
struct ReLu<Array<T, N>> {
  CUTLASS_HOST_DEVICE
  Array<T, N> operator()(T const & threshold, Array<T, N> const &frag) const {
    Array<T, N> result;
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      T value = frag[i];
      if (value < threshold) {
        value = threshold;
      }
      result[i] = value;
    }
    return result;
  }
};

// Sigmoid operator
template <typename T>
struct Sigmoid {
  CUTLASS_HOST_DEVICE
  T operator()(T const &scalar) const {
    return T(1) / (T(1) + exp(-scalar));
  }
};

template <>
struct Sigmoid<float> {
  CUTLASS_HOST_DEVICE
  float operator()(float const &scalar) const {
    return 1.0f / (1.0f + expf(-scalar));
  }
};

template <typename T, int N>
struct Sigmoid<Array<T, N> > {
  CUTLASS_HOST_DEVICE
  Array<T, N> operator()(Array<T, N> const &rhs) const {
    Array<T, N> y;
    Sigmoid<T> sigmoid_op;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < int(rhs.size()); ++i) {
      y[i] = sigmoid_op(rhs[i]);
    }

    return y;
  }
};

//
// GELU function definitions implemented as described by
//   Hendrycks, D., and Gimpel, K. in
//   "Gaussian Error Linear Units (GELUs)." (2020)
//   https://arxiv.org/pdf/1606.08415.pdf
//
// Floating-point constants are Taylor coefficients described in the paper.
//

// GELU operator
template <typename T>
struct GELU {
  CUTLASS_HOST_DEVICE
  T operator()(T const &scalar) const {
    return T(cutlass::constants::half<T>() * scalar *
      (cutlass::constants::one<T>() + (T)erff((float)(scalar / cutlass::constants::root_two<T>()))));
  }
};

template <>
struct GELU<float> {
  CUTLASS_HOST_DEVICE
  float operator()(float const &scalar) const {
    return cutlass::constants::half<float>() * scalar *
      (cutlass::constants::one<float>() + erff( scalar / cutlass::constants::root_two<float>() ));
  }
};

template <>
struct GELU<double> {
  CUTLASS_HOST_DEVICE
  double operator()(double const &scalar) const {
    return cutlass::constants::half<double>() * scalar *
      (cutlass::constants::one<double>() + erf( scalar / cutlass::constants::root_two<double>() ));
  }
};

template <typename T, int N>
struct GELU<Array<T, N> > {
  CUTLASS_HOST_DEVICE
  Array<T, N> operator()(Array<T, N> const &rhs) const {
    Array<T, N> y;
    GELU<T> gelu_op;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      y[i] = gelu_op(rhs[i]);
    }

    return y;
  }
};

// GELU operator implemented using the Taylor series approximation
template <typename T>
struct GELU_taylor {
  static const bool kIsHeavy=true;
  CUTLASS_HOST_DEVICE
  T operator()(T const &z) const {

    T k0 = T(0.7978845608028654);
    T k1 = T(0.044715);

    return T(cutlass::constants::half<T>() * z * 
      (cutlass::constants::one<T>() + fast_tanh(k0 * z * (cutlass::constants::one<T>() + k1 * z * z))));
  }
};

template <typename T, int N>
struct GELU_taylor<Array<T, N> > {
  static const bool kIsHeavy=true;
  CUTLASS_HOST_DEVICE
  Array<T, N> operator()(Array<T, N> const &rhs) const {
    Array<T, N> y;
    GELU_taylor<T> gelu_op;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      y[i] = gelu_op(rhs[i]);
    }

    return y;
  }
};

/// Computes backwards pass for GELU operator assuming d_t is the layer gradient and
/// z is computed from the forward pass.
template <typename T>
struct dGELU {
  CUTLASS_HOST_DEVICE
  T operator()(T const &d_t, T const &z) const {

    T k0 = T(0.7978845608028654);
    T k1 = T(0.044715);
    T k2 = T(0.1070322243);

    T tanh_out = fast_tanh(k0 * z * (1 + k1 * z * z));

    T ff = constants::half<T>() * z * ((1 - tanh_out * tanh_out) * (k0 + k2 * z * z)) + 
      constants::half<T>() * (1 + tanh_out);

    return ff * d_t;
  }
};

template <typename T, int N>
struct dGELU<Array<T, N> > {
  CUTLASS_HOST_DEVICE
  Array<T, N> operator()(Array<T, N> const &d_t, Array<T, N> const &z) const {
    Array<T, N> y;
    dGELU<T> gelu_op;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N; ++i) {
      y[i] = gelu_op(d_t[i], z[i]);
    }

    return y;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace thread
} // namespace epilogue
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
