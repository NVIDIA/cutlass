/***************************************************************************************************
* Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
#pragma once

// Standard Library includes
#include <random>
#include <cstdlib>
#include <cmath>
#include <type_traits>
#include <cstdint>
#include <vector>

// Cutlass includes
#include "cutlass/cutlass.h"
#include "cutlass/complex.h"


namespace cutlass {
namespace reference {
namespace device {

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

/// Computes a random Gaussian distribution
template <typename Element>                ///< Element type
struct RandomUniformFunc {

  using FloatType = typename std::conditional<
    (sizeof(Element) > 4),
    double,
    float>::type;

  using IntType = typename std::conditional<
    (sizeof(Element) > 4),
    int64_t,
    int>::type;

  /// Parameters structure
  struct Params {

    //
    // Data members
    //

    uint64_t seed;
    FloatType max;
    FloatType min;
    int int_scale;
    FloatType float_scale_up;
    FloatType float_scale_down;

    /// Default ctor
    CUTLASS_HOST
    Params() { }

    //
    // Methods
    //

    /// Construction of Gaussian RNG functor.
    Params(
      uint64_t seed_ = 0,
      Element max_ = 1,
      Element min_ = 0,
      int int_scale_ = -1
    ):
      seed(seed_),
      max(static_cast<FloatType>(max_)),
      min(static_cast<FloatType>(min_)),
      int_scale(int_scale_) {

      float_scale_up = FloatType(IntType(2) << int_scale); // scale up to clamp low order bits
      float_scale_down = FloatType(1) / FloatType(IntType(2) << int_scale);
    }
  };

  //
  // Data members
  //

  /// Parameters object
  Params params;
  std::default_random_engine generator;
  std::normal_distribution<FloatType> distribution;

  //
  // Methods
  //

  explicit RandomUniformFunc(Params const &params):
      params(params),
      generator(params.seed),
      distribution(static_cast<FloatType>(params.min), static_cast<FloatType>(params.max)) {
  }

  /// Compute random value and update RNG state
  CUTLASS_HOST
  Element operator()() {
    FloatType rnd = distribution(generator);

    // Random values are cast to integer after scaling by a power of two to facilitate error
    // testing
    Element result;

    if (params.int_scale >= 0) {
      rnd = FloatType(IntType(std::llround(rnd * params.float_scale_up)));
      result = Element(IntType(rnd * params.float_scale_down));
    }
    else {
      result = Element(rnd);
    }

    return result;
  }
};

} // namespace detail

/// Fills a tensor with random values with a uniform random distribution.
template <typename Element>
void BlockFillRandomUniform(
  Element *ptr,
  size_t capacity,
  uint64_t seed,                          ///< seed for RNG
  typename RealType<Element>::Type max,   ///< upper bound of distribution
  typename RealType<Element>::Type min,   ///< lower bound for distribution
  int bits = -1                           ///< If non-negative, specifies number of fractional bits that
                                          ///  are not truncated to zero. Permits reducing precision of
                                          ///  data.
  ) {

  using RandomFunc = detail::RandomUniformFunc<Element>;

  typename RandomFunc::Params params(seed, max, min, bits);

  auto rand = RandomFunc(params);
  auto h_vector = std::vector<Element>(capacity);
  for (int j = 0; j < capacity; ++j) {
    h_vector[j] = rand();
  }
  syclcompat::memcpy<Element>(ptr, h_vector.data(), capacity);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace device
} // namespace reference
} // namespace cutlass
