/***************************************************************************************************
 * Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
 * Copyright (C) 2025 Intel Corporation, All rights reserved.
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
#include <cstdlib>
#include <cmath>
#include <type_traits>
#include <cstdint>
#include <vector>

#include <oneapi/mkl/rng/device.hpp>

// Cutlass includes
#include "cutlass/cutlass.h"
#include "cutlass/complex.h"
#include "cutlass/util/reference/device/tensor_foreach.h"
#include "cutlass/util/reference/host/tensor_fill.h"
#include "cutlass/tensor_view.h"
#include "cutlass/layout/vector.h"


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
  oneapi::mkl::rng::device::uniform<FloatType> distribution;
  oneapi::mkl::rng::device::philox4x32x10<> generator;

  //
  // Methods
  //

  explicit RandomUniformFunc(Params const &params):
      params(params),
      distribution(static_cast<FloatType>(params.min), static_cast<FloatType>(params.max)),
      generator(params.seed, {0, ThreadIdxX() + BlockIdxX() * BlockDimX()}) {}

  /// Compute random value and update RNG state
  CUTLASS_HOST_DEVICE
  Element operator()() {
    FloatType rnd = oneapi::mkl::rng::device::generate(distribution, generator);
    // Random values are cast to integer after scaling by a power of two to facilitate error
    // testing
    Element result;

    if (params.int_scale >= 0) {
      rnd = FloatType(IntType(sycl::round(rnd * params.float_scale_up)));
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
  BlockForEach<Element, RandomFunc>(ptr, capacity, params);
}

/// This function generates random values on the host and then copies them to the device.
template <typename Element>
void BlockFillRandomUniformCopyFromHost(
  Element *ptr,
  size_t capacity,
  uint64_t seed,                          ///< seed for RNG
  typename RealType<Element>::Type max,   ///< upper bound of distribution
  typename RealType<Element>::Type min,   ///< lower bound for distribution
  int bits = -1                           ///< If non-negative, specifies number of fractional bits that
                                          ///  are not truncated to zero. Permits reducing precision of
                                          ///  data.
  ) {
  auto buff = std::vector<Element>(capacity);

  cutlass::reference::host::BlockFillRandomUniform(buff.data(), capacity, seed, max, min, bits);

  compat::memcpy<Element>(ptr, buff.data(), capacity);
  compat::wait();
}

///////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

/// Compute the linear offset into the tensor-view with a scale and offset
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
struct TensorFillLinearFunc {

  /// View type
  using TensorView = TensorView<Element, Layout>;

  /// Scalar type
  typedef typename TensorView::Element T;

  /// Coordinate in tensor's index space
  typedef typename TensorView::TensorCoord TensorCoord;

  struct Params {
    TensorView view;
    Array<Element, Layout::kRank> v;
    Element s;

    Params() { }

    Params(
      TensorView view_,      ///< destination tensor
      Array<Element, Layout::kRank> const & v_,
      Element s_ = Element(0)
    ):
      view(view_), v(v_), s(s_) { }
  };

  Params params;

  TensorFillLinearFunc(Params const &params): params(params) {}
  TensorFillLinearFunc(TensorFillLinearFunc const &) = default;

  void operator()(TensorCoord const &coord) {

    Element sum = params.s;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < Layout::kRank; ++i) {
      if constexpr (is_complex<Element>::value) {
        if constexpr (sizeof_bits<Element>::value <= 32) {
          sum = Element(static_cast<complex<float>>(sum) +
                  static_cast<complex<float>>(params.v[i]) * static_cast<complex<float>>(coord[i]));
        }
      }
      else if constexpr (sizeof_bits<Element>::value <= 32) {
        if constexpr (std::numeric_limits<Element>::is_integer) {
          sum = Element(static_cast<int32_t>(sum) +
                  static_cast<int32_t>(params.v[i]) * static_cast<int32_t>(coord[i]));
        }
        else {
          sum = Element(static_cast<float>(sum) +
                  static_cast<float>(params.v[i]) * static_cast<float>(coord[i]));
        }
      }
      else {
        sum += params.v[i] * coord[i];
      }
    }

    params.view.at(coord) = sum;
  }
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

/// Fills tensor with a linear combination of its coordinate and another vector
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
void TensorFillLinear(
  TensorView<Element, Layout> view,      ///< destination tensor
  Array<Element, Layout::kRank> const & v,
  Element s = Element(0)) {

  using Func = detail::TensorFillLinearFunc<Element, Layout>;
  using Params = typename Func::Params;

  TensorForEach<Func, Layout::kRank, Params>(
    view.extent(),
    Params(view, v, s),
    /*grid_size*/0, /*block_size*/0
  );
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

/// Fills a block of data with sequential elements
template <
  typename Element
>
void BlockFillSequential(
  Element *ptr,
  int64_t capacity,
  Element v = Element(1),
  Element s = Element(0)) {

  using Layout = layout::PackedVectorLayout;
  Layout::TensorCoord size(static_cast<Layout::Index>(capacity)); // -Wconversion
  Layout layout = Layout::packed(size);
  TensorView<Element, Layout> view(ptr, layout, size);

  Array<Element, Layout::kRank> c{};
  c[0] = v;

  TensorFillLinear(view, c, s);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace device
} // namespace reference
} // namespace cutlass
