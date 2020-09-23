/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
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

/// ReLu operator - propagates NaNs
template <typename T>
struct ReLu {
  CUTLASS_HOST_DEVICE
  T operator()(T const & threshold, T const &value) const {
    if (value < threshold) {
      value = threshold;
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

// GELU operator
template <typename T>
struct GELU {
  CUTLASS_HOST_DEVICE
  T operator()(T const &scalar) const {
    return T(cutlass::constants::half<T>() * scalar *
      (cutlass::constants::one<T>() + erff( scalar / cutlass::constants::root_two<T>() )));
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

template <typename T, int N>
struct GELU<Array<T, N> > {
  CUTLASS_HOST_DEVICE
  Array<T, N> operator()(Array<T, N> const &rhs) const {
    Array<T, N> y;
    GELU<T> gelu_op;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < int(rhs.size()); ++i) {
      y[i] = gelu_op(rhs[i]);
    }

    return y;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace thread
} // namespace epilogue
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////

