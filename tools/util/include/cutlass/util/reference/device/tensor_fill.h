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
/* \file
  \brief Defines device-side elementwise operations on TensorView. Note, the operations defined
    in this header are not specialized for any particular data layout and are therefore not
    intended to offer the best possible performance. Rather, they are intended to be generic
    reference implementations to support the CUTLASS unit tests.
*/

#pragma once

#if !defined(__CUDACC_RTC__)

// Standard Library includes
#include <utility>
#include <cstdlib>
#include <cmath>
#include <type_traits>
#include <cstdint>

#endif

// CUDA includes
#include <cublas_v2.h>
#include <curand_kernel.h>

// Cutlass includes
#include "cutlass/cutlass.h"
#include "cutlass/array.h"
#include "cutlass/tensor_view.h"

#include "cutlass/util/reference/device/tensor_foreach.h"
#include "cutlass/util/distribution.h"

///////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace reference {
namespace device {

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

template <typename FloatType>
CUTLASS_DEVICE
FloatType random_normal_float(curandState_t *state) {
  return curand_normal(state);
}

template <>
CUTLASS_DEVICE
double random_normal_float<double>(curandState_t *state) {
  return curand_normal_double(state);
}

template <typename FloatType>
CUTLASS_DEVICE
FloatType random_uniform_float(curandState_t *state) {
  return curand_uniform(state);
}

template <>
CUTLASS_DEVICE
double random_uniform_float<double>(curandState_t *state) {
  return curand_uniform_double(state);
}

template <typename Element>
struct RandomGaussianFunc {

  using FloatType = typename std::conditional<(sizeof(Element) > 4), double, float>::type;
  using IntType = typename std::conditional<(sizeof(Element) > 4), int64_t, int>::type;

  /// Parameters structure
  struct Params {

    //
    // Data members
    //

    uint64_t seed;
    FloatType mean;
    FloatType stddev;
    int int_scale;

    //
    // Methods
    //

    /// Construction of Gaussian RNG functor.
    Params(
      uint64_t seed_ = 0,
      Element mean_ = 0, 
      Element stddev_ = 1,
      int int_scale_ = -1
    ):
      seed(seed_), 
      mean(static_cast<FloatType>(mean_)), 
      stddev(static_cast<FloatType>(stddev_)), 
      int_scale(int_scale_) {

    }
  };

  //
  // Data members
  //

  /// Parameters object
  Params params;

  /// RNG state object
  curandState_t rng_state;

  //
  // Methods
  //

  /// Device-side initialization of RNG
  CUTLASS_DEVICE
  RandomGaussianFunc(Params const &params): params(params) {

    uint64_t gtid = threadIdx.x + blockIdx.x * blockDim.x;

    curand_init(params.seed, gtid, 0, &rng_state);
  }

  /// Compute random value and update RNG state
  CUTLASS_DEVICE
  Element operator()() {

    FloatType rnd = random_normal_float<FloatType>(&rng_state);
    rnd = params.mean + params.stddev * rnd;

    Element result;
    if (params.int_scale >= 0) {
      rnd = FloatType(IntType(rnd * FloatType(IntType(1) << params.int_scale)));
      result = Element(rnd / FloatType(IntType(1) << params.int_scale));
    }
    else {
      result = Element(rnd);
    }

    return result;
  }
};

/// Computes a random Gaussian distribution
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
struct TensorFillRandomGaussianFunc {

  /// View type
  using TensorView = TensorView<Element, Layout>;

  /// Scalar type
  typedef typename TensorView::Element T;

  /// Coordinate in tensor's index space
  typedef typename TensorView::TensorCoord TensorCoord;

  using RandomFunc = RandomGaussianFunc<Element>;

  /// Parameters structure
  struct Params {

    //
    // Data members
    //

    TensorView view;
    typename RandomFunc::Params random;

    //
    // Methods
    //

    /// Construction of Gaussian RNG functor.
    Params(
      TensorView view_ = TensorView(),
      typename RandomFunc::Params random_ = typename RandomFunc::Params()
    ):
      view(view_), random(random_) {

    }
  };

  //
  // Data members
  //

  Params params;
  RandomFunc random;

  //
  // Methods
  //

  /// Device-side initialization of RNG
  CUTLASS_DEVICE
  TensorFillRandomGaussianFunc(Params const &params): params(params), random(params.random) {

  }

  /// Compute random value and update RNG state
  CUTLASS_DEVICE
  void operator()(TensorCoord const &coord) {

    params.view.at(coord) = random();
  }
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Fills a tensor with random values with a Gaussian distribution.
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
void TensorFillRandomGaussian(
  TensorView<Element, Layout> view,       ///< destination tensor
  uint64_t seed,                          ///< seed for RNG
  Element mean = Element(0),              ///< Gaussian distribution's mean
  Element stddev = Element(1),            ///< Gaussian distribution's standard deviation
  int bits = -1) {                        ///< If non-negative, specifies number of fractional bits that 
                                          ///  are not truncated to zero. Permits reducing precision of
                                          ///  data.
  
  using RandomFunc = detail::RandomGaussianFunc<Element>;
  using Func = detail::TensorFillRandomGaussianFunc<Element, Layout>;
  using Params = typename Func::Params;

  TensorForEach<Func, Layout::kRank, Params>(
    view.extent(),
    Params(view, typename RandomFunc::Params(seed, mean, stddev, bits))
  );
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Fills a tensor with random values with a Gaussian distribution.
template <typename Element>               ///< Element type
void BlockFillRandomGaussian(
  Element *ptr,
  size_t capacity,
  uint64_t seed,                          ///< seed for RNG
  Element mean = Element(0),              ///< Gaussian distribution's mean
  Element stddev = Element(1),            ///< Gaussian distribution's standard deviation
  int bits = -1) {                        ///< If non-negative, specifies number of fractional bits that 
                                          ///  are not truncated to zero. Permits reducing precision of
                                          ///  data.
  
  using RandomFunc = detail::RandomGaussianFunc<Element>;

  typename RandomFunc::Params params(seed, mean, stddev, bits);

  BlockForEach<Element, RandomFunc>(ptr, capacity, params);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

/// Computes a random Gaussian distribution
template <typename Element>                ///< Layout function
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
    FloatType range;
    FloatType min;
    int int_scale;

    /// Default ctor
    CUTLASS_HOST_DEVICE
    Params() { }

    //
    // Methods
    //

    /// Construction of Gaussian RNG functor.
    Params(
      uint64_t seed_ = 0, 
      Element max = 1,
      Element min_ = 0,
      int int_scale_ = -1
    ):
      seed(seed_), 
      range(static_cast<FloatType>(max - min_)), 
      min(static_cast<FloatType>(min_)), 
      int_scale(int_scale_) {

    }
  };

  //
  // Data members
  //

  /// Parameters object
  Params params;

  /// RNG state object
  curandState_t rng_state;

  //
  // Methods
  //

  /// Device-side initialization of RNG
  CUTLASS_DEVICE
  RandomUniformFunc(Params const &params): params(params) {

    uint64_t gtid = threadIdx.x + blockIdx.x * blockDim.x;

    curand_init(params.seed, gtid, 0, &rng_state);
  }

  /// Compute random value and update RNG state
  CUTLASS_DEVICE
  Element operator()() {

    FloatType rnd = random_uniform_float<FloatType>(&rng_state);
    rnd = params.min + params.range * rnd;

    // Random values are cast to integer after scaling by a power of two to facilitate error
    // testing
    Element result;

    if (params.int_scale >= 0) {
      rnd = FloatType(IntType(rnd * FloatType(IntType(1) << params.int_scale)));
      result = Element(rnd / FloatType(IntType(1) << params.int_scale));
    }
    else {
      result = Element(rnd);
    }

    return result;
  }
};

/// Computes a random Gaussian distribution
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
struct TensorFillRandomUniformFunc {

  /// View type
  using TensorView = TensorView<Element, Layout>;

  /// Scalar type
  typedef typename TensorView::Element T;

  /// Coordinate in tensor's index space
  typedef typename TensorView::TensorCoord TensorCoord;

  using RandomFunc = RandomUniformFunc<Element>;

  /// Parameters structure
  struct Params {

    //
    // Data members
    //

    TensorView view;
    typename RandomFunc::Params random;

    /// Default ctor
    CUTLASS_HOST_DEVICE
    Params() { }

    //
    // Methods
    //

    /// Construction of Gaussian RNG functor.
    Params(
      TensorView view_ = TensorView(),
      typename RandomFunc::Params random_ = RandomFunc::Params()
    ):
      view(view_), random(random_) {

    }
  };

  //
  // Data members
  //

  Params params;
  RandomFunc random;

  //
  // Methods
  //

  /// Device-side initialization of RNG
  CUTLASS_DEVICE
  TensorFillRandomUniformFunc(Params const &params): params(params), random(params.random) {
  }

  /// Compute random value and update RNG state
  CUTLASS_DEVICE
  void operator()(TensorCoord const &coord) {

    params.view.at(coord) = random();
  }
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Fills a tensor with random values with a uniform random distribution.
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
void TensorFillRandomUniform(
  TensorView<Element, Layout> view,       ///< destination tensor
  uint64_t seed,                          ///< seed for RNG
  Element max = Element(1),               ///< upper bound of distribution
  Element min = Element(0),               ///< lower bound for distribution
  int bits = -1) {                        ///< If non-negative, specifies number of fractional bits that 
                                          ///  are not truncated to zero. Permits reducing precision of
                                          ///  data.                 
  
  using RandomFunc = detail::RandomUniformFunc<Element>;
  using Func = detail::TensorFillRandomUniformFunc<Element, Layout>;
  using Params = typename Func::Params;

  typename RandomFunc::Params random(seed, max, min, bits);

  TensorForEach<Func, Layout::kRank, Params>(
    view.size(),
    Params(view, random)
  );
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Fills a tensor with random values with a uniform random distribution.
template <typename Element>
void BlockFillRandomUniform(
  Element *ptr,
  size_t capacity,
  uint64_t seed,                          ///< seed for RNG
  Element max = Element(1),               ///< upper bound of distribution
  Element min = Element(0),               ///< lower bound for distribution
  int bits = -1) {                        ///< If non-negative, specifies number of fractional bits that 
                                          ///  are not truncated to zero. Permits reducing precision of
                                          ///  data.                 
  
  using RandomFunc = detail::RandomUniformFunc<Element>;
  typename RandomFunc::Params params(seed, max, min, bits);

  BlockForEach<Element, RandomFunc>(ptr, capacity, params);
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

/// Computes a random Gaussian distribution
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
struct TensorFillDiagonalFunc {

  /// View type
  using TensorView = TensorView<Element, Layout>;

  /// Scalar type
  typedef typename TensorView::Element T;

  /// Coordinate in tensor's index space
  typedef typename TensorView::TensorCoord TensorCoord;

  /// Parameters structure
  struct Params {

    //
    // Data members
    //

    TensorView view;
    Element diag;
    Element other;

    /// Default ctor
    CUTLASS_HOST_DEVICE
    Params() { }

    //
    // Methods
    //

    /// Construction of Gaussian RNG functor.
    Params(
      TensorView view_ = TensorView(),
      Element diag_ = Element(1),
      Element other_ = Element(0)
    ):
      view(view_), diag(diag_), other(other_) {

    }
  };

  //
  // Data members
  //

  /// Parameters object
  Params params;

  //
  // Methods
  //

  /// Device-side initialization of RNG
  CUTLASS_DEVICE
  TensorFillDiagonalFunc(Params const &params): params(params) {

  }

  /// Compute random value and update RNG state
  CUTLASS_DEVICE
  void operator()(TensorCoord const &coord) {

    bool is_diag = true;
    
    CUTLASS_PRAGMA_UNROLL
    for (int i = 1; i < Layout::kRank; ++i) {
      if (coord[i] != coord[i - 1]) {
        is_diag = false;
        break;
      }
    }

    params.view.at(coord) = (is_diag ? params.diag : params.other);
  }
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Fills a tensor everywhere with a unique value for its diagonal.
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
void TensorFillDiagonal(
  TensorView<Element, Layout> view,       ///< destination tensor
  Element diag = Element(1),              ///< value to write in the diagonal
  Element other = Element(0)) {           ///< value to write off the diagonal
  
  typedef detail::TensorFillDiagonalFunc<Element, Layout> Func;
  typedef typename Func::Params Params;

  TensorForEach<Func, Layout::kRank, Params>(
    view.size(),
    Params(view, diag, other)
  );
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Fills a tensor with a uniform value
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
void TensorFill(
  TensorView<Element, Layout> view,         ///< destination tensor 
  Element val = Element(0)) {               ///< value to uniformly fill it with

  TensorFillDiagonal(view, val, val);
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Fills a tensor's digonal with 1 and 0 everywhere else.
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
void TensorFillIdentity(
  TensorView<Element, Layout> view) {               ///< destination tensor

  TensorFillDiagonal(view, Element(1), Element(0));
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

/// Computes a random Gaussian distribution
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
struct TensorUpdateDiagonalFunc {

  /// View type
  using TensorView = TensorView<Element, Layout>;

  /// Scalar type
  typedef typename TensorView::Element T;

  /// Coordinate in tensor's index space
  typedef typename TensorView::TensorCoord TensorCoord;

  /// Parameters structure
  struct Params {

    //
    // Data members
    //

    TensorView view;
    Element diag;

    /// Default ctor
    CUTLASS_HOST_DEVICE
    Params() { }

    //
    // Methods
    //

    /// Construction of Gaussian RNG functor.
    Params(
      TensorView view_ = TensorView(),
      Element diag_ = Element(1)
    ):
      view(view_), diag(diag_) {

    }
  };

  //
  // Data members
  //

  /// Parameters object
  Params params;

  //
  // Methods
  //

  /// Device-side initialization of RNG
  CUTLASS_DEVICE
  TensorUpdateDiagonalFunc(Params const &params): params(params) {

  }

  /// Compute random value and update RNG state
  CUTLASS_DEVICE
  void operator()(TensorCoord const &coord) {

    bool is_diag = true;
    
    CUTLASS_PRAGMA_UNROLL
    for (int i = 1; i < Layout::kRank; ++i) {
      if (coord[i] != coord[i - 1]) {
        is_diag = false;
        break;
      }
    }

    if (is_diag) {
      params.view.at(coord) = params.diag;  
    }
  }
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Writes a uniform value to the diagonal of a tensor without modifying off-diagonal elements.
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
void TensorUpdateDiagonal(
  TensorView<Element, Layout> view,                 ///< destination tensor
  Element diag = Element(1)) {

  typedef detail::TensorUpdateDiagonalFunc<Element, Layout> Func;
  typedef typename Func::Params Params;

  TensorForEach<Func, Layout::kRank, Params>(
    view.size(),
    Params(view, diag)
  );
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

/// Computes a random Gaussian distribution
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
struct TensorUpdateOffDiagonalFunc {

  /// View type
  using TensorView = TensorView<Element, Layout>;

  /// Scalar type
  typedef typename TensorView::Element T;

  /// Coordinate in tensor's index space
  typedef typename TensorView::TensorCoord TensorCoord;

  /// Parameters structure
  struct Params {

    //
    // Data members
    //

    TensorView view;
    Element other;

    /// Default ctor
    CUTLASS_HOST_DEVICE
    Params() { }

    //
    // Methods
    //

    /// Construction of Gaussian RNG functor.
    Params(
      TensorView view_ = TensorView(),
      Element other_ = Element(0)
    ):
      view(view_), other(other_) {

    }
  };

  //
  // Data members
  //

  /// Parameters object
  Params params;

  //
  // Methods
  //

  /// Device-side initialization of RNG
  CUTLASS_DEVICE
  TensorUpdateOffDiagonalFunc(Params const &params): params(params) {

  }

  /// Compute random value and update RNG state
  CUTLASS_DEVICE
  void operator()(TensorCoord const &coord) {

    bool is_diag = true;
    
    CUTLASS_PRAGMA_UNROLL
    for (int i = 1; i < Layout::kRank; ++i) {
      if (coord[i] != coord[i - 1]) {
        is_diag = false;
        break;
      }
    }

    if (!is_diag) {
      params.view.at(coord) = params.other;  
    }
  }
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Writes a uniform value to all elements in the tensor without modifying diagonal elements.
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
void TensorUpdateOffDiagonal(
  TensorView<Element, Layout> view,      ///< destination tensor
  Element other = Element(1)) {

  typedef detail::TensorUpdateOffDiagonalFunc<Element, Layout> Func;
  typedef typename Func::Params Params;

  TensorForEach<Func, Layout::kRank, Params>(
    view.size(),
    Params(view, other)
  );
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

/// Computes a random Gaussian distribution
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

  /// Parameters structure
  struct Params {

    //
    // Data members
    //

    TensorView view;
    Array<Element, Layout::kRank> v;
    Element s;

    /// Default ctor
    CUTLASS_HOST_DEVICE
    Params() { }

    //
    // Methods
    //

    /// Construction of Gaussian RNG functor.
    Params(
      TensorView view_,      ///< destination tensor
      Array<Element, Layout::kRank> const & v_,
      Element s_ = Element(0)
    ):
      view(view_), v(v_), s(s_) { 

    }
  };

  //
  // Data members
  //

  /// Parameters object
  Params params;

  //
  // Methods
  //

  /// Device-side initialization of RNG
  CUTLASS_DEVICE
  TensorFillLinearFunc(Params const &params): params(params) {

  }

  /// Compute random value and update RNG state
  CUTLASS_DEVICE
  void operator()(TensorCoord const &coord) {
    Element sum = params.s;
    
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < Layout::kRank; ++i) {
      sum += params.v[i] * Element(coord[i]);
    }

    params.view.at(coord) = sum;
  }
};

} // namespace detail

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
    view.size(),
    Params(view, v, s)
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

}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

/// Fills a block of data with sequential elements
template <
  typename Element
>
void BlockFillRandom(
  Element *ptr,
  size_t capacity,
  uint64_t seed,
  Distribution dist) {

  if (dist.kind == Distribution::Gaussian) {
    BlockFillRandomGaussian<Element>(
      ptr, 
      capacity, 
      seed, 
      static_cast<Element>(dist.gaussian.mean), 
      static_cast<Element>(dist.gaussian.stddev), 
      dist.int_scale);
  }
  else if (dist.kind == Distribution::Uniform) {
    BlockFillRandomUniform<Element>(
      ptr, 
      capacity, 
      seed, 
      static_cast<Element>(dist.uniform.max),
      static_cast<Element>(dist.uniform.min), 
      dist.int_scale);
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {

/// Computes a random Gaussian distribution
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
struct TensorCopyDiagonalInFunc {

  /// View type
  using TensorView = TensorView<Element, Layout>;

  /// Scalar type
  typedef typename TensorView::Element T;

  /// Coordinate in tensor's index space
  typedef typename TensorView::TensorCoord TensorCoord;

  /// Parameters structure
  struct Params {

    //
    // Data members
    //

    TensorView view;
    Element const *ptr;

    /// Default ctor
    CUTLASS_HOST_DEVICE
    Params() { }

    //
    // Methods
    //

    /// Construction of Gaussian RNG functor.
    Params(
      TensorView view_,      ///< destination tensor
      Element const *ptr_
    ):
      view(view_), ptr(ptr_) { 

    }
  };

  //
  // Data members
  //

  /// Parameters object
  Params params;

  //
  // Methods
  //

  /// Device-side initialization of RNG
  CUTLASS_DEVICE
  TensorCopyDiagonalInFunc(Params const &params): params(params) {

  }

  /// Only update the diagonal element
  CUTLASS_DEVICE
  void operator()(TensorCoord const &coord) {
    bool is_diagonal = true;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 1; i < Layout::kRank; ++i) {
      if (coord[i] != coord[0]) {
        is_diagonal = false;
      }
    }
    if (is_diagonal) {
      params.view.at(coord) = params.ptr[coord[0]];
    }
  }
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Copies a diagonal in from host memory without modifying off-diagonal elements.
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
void TensorCopyDiagonalIn(
  TensorView<Element, Layout> view,   ///< destination tensor
  Element const *ptr) {                     ///< dense buffer of elements

  using Func = detail::TensorCopyDiagonalInFunc<Element, Layout>;
  using Params = typename Func::Params;

  TensorForEach<Func, Layout::kRank, Params>(
    view.size(),
    Params(view, ptr)
  );
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////


namespace detail {

/// Computes a random Gaussian distribution
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
struct TensorCopyDiagonalOutFunc {

  /// View type
  using TensorView = TensorView<Element, Layout>;

  /// Scalar type
  typedef typename TensorView::Element T;

  /// Coordinate in tensor's index space
  typedef typename TensorView::TensorCoord TensorCoord;

  /// Parameters structure
  struct Params {

    //
    // Data members
    //

    TensorView view;
    Element *ptr;

    /// Default ctor
    CUTLASS_HOST_DEVICE
    Params() { }

    //
    // Methods
    //

    /// Construction of Gaussian RNG functor.
    Params(
      TensorView view_,      ///< destination tensor
      Element *ptr_
    ):
      view(view_), ptr(ptr_) { 

    }
  };

  //
  // Data members
  //

  /// Parameters object
  Params params;

  //
  // Methods
  //

  /// Device-side initialization of RNG
  CUTLASS_DEVICE
  TensorCopyDiagonalOutFunc(Params const &params): params(params) {

  }

  /// Compute random value and update RNG state
  CUTLASS_DEVICE
  void operator()(TensorCoord const &coord) {
    bool is_diagonal = true;

    CUTLASS_PRAGMA_UNROLL
    for (int i = 1; i < Layout::kRank; ++i) {
      if (coord[i] != coord[0]) {
        is_diagonal = false;
      }
    }
    if (is_diagonal) {
      params.ptr[coord[0]] = params.view.at(coord);  
    }
  }
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Copies the diagonal of a tensor into a dense buffer in host memory.
template <
  typename Element,               ///< Element type
  typename Layout>                ///< Layout function
void TensorCopyDiagonalOut(
  Element *ptr,                               ///< dense buffer of elements
  TensorView<Element, Layout> view) {    ///< source tensor

  using Func = detail::TensorCopyDiagonalOutFunc<Element, Layout>;
  using Params = typename Func::Params;

  TensorForEach<Func, Layout::kRank, Params>(
    view.size(),
    Params(view, ptr)
  );
}

///////////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace device
} // namespace reference
} // namespace cutlass
