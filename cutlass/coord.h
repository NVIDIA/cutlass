/***************************************************************************************************
 * Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.
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
    \brief A Coord is a coordinate of arbitrary rank into a tensor or matrix
*/

#pragma once

#include <cutlass/cutlass.h>

namespace cutlass {

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Describes identity elements
struct Identity {
  /// Enumeration describing identity elements. Value assignments are significant.
  /// Feel free to add or multiply by these, respectively.
  enum Kind { Additive = 0, Multiplicative = 1 };
};

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Statically-sized array specifying Coords within a tensor
template <int N_>
struct Coord {
  //
  // Type and constant definitions
  //

  static int const N = N_;

  //
  // Data members
  //

  /// Indices
  int idx[N];

  //
  // Methods
  //

  /// Default ctor initializes uniformly
  CUTLASS_HOST_DEVICE
  Coord(int value = 0) {
    for (int i = 0; i < N; ++i) {
      idx[i] = value;
    }
  }

  /// Constructs from an array of integers
  CUTLASS_HOST_DEVICE
  Coord(int _idx[]) {
    for (int i = 0; i < N; ++i) {
      idx[i] = _idx[i];
    }
  }

  /// Element-wise addition
  CUTLASS_HOST_DEVICE
  Coord operator+(Coord const& b) const {
    Coord c;
    for (int i = 0; i < N; ++i) {
      c.idx[i] = idx[i] + b.idx[i];
    }
    return c;
  }

  /// Element-wise subtraction
  CUTLASS_HOST_DEVICE
  Coord operator-(Coord const& b) const {
    Coord c;
    for (int i = 0; i < N; ++i) {
      c.idx[i] = idx[i] - b.idx[i];
    }
    return c;
  }

  /// Element-wise multiplication
  CUTLASS_HOST_DEVICE
  Coord operator*(Coord const& b) const {
    Coord c;
    for (int i = 0; i < N; ++i) {
      c.idx[i] = idx[i] * b.idx[i];
    }
    return c;
  }

  /// Element-wise division
  CUTLASS_HOST_DEVICE
  Coord operator/(Coord const& b) const {
    Coord c;
    for (int i = 0; i < N; ++i) {
      c.idx[i] = idx[i] / b.idx[i];
    }
    return c;
  }

  /// In-place addition
  CUTLASS_HOST_DEVICE
  Coord& operator+=(Coord const& b) {
    for (int i = 0; i < N; ++i) {
      idx[i] += b.idx[i];
    }
    return *this;
  }

  /// In-place subtraction
  CUTLASS_HOST_DEVICE
  Coord& operator-=(Coord const& b) {
    for (int i = 0; i < N; ++i) {
      idx[i] -= b.idx[i];
    }
    return *this;
  }

  /// In-place multiplication
  CUTLASS_HOST_DEVICE
  Coord& operator*=(Coord const& b) {
    for (int i = 0; i < N; ++i) {
      idx[i] *= b.idx[i];
    }
    return *this;
  }

  /// In-place division
  CUTLASS_HOST_DEVICE
  Coord& operator/=(Coord const& b) {
    for (int i = 0; i < N; ++i) {
      idx[i] /= b.idx[i];
    }
    return *this;
  }

  /// Member access operator
  CUTLASS_HOST_DEVICE int& operator[](int dim) { return idx[dim]; }

  /// Member access operator
  CUTLASS_HOST_DEVICE int const& operator[](int dim) const { return idx[dim]; }

  /// Computes the dot product of two Coord instances
  template <typename T>
  CUTLASS_HOST_DEVICE T dot(Coord const& b, T sum) const {
    for (int i = 0; i < N; ++i) {
      sum += idx[i] * b.idx[i];
    }
    return sum;
  }

  /// Computes the dot product of two Coord instances
  template <typename T>
  CUTLASS_HOST_DEVICE T dot(Coord const& b) const {
    T sum = T(0);
    for (int i = 0; i < N; ++i) {
      sum += idx[i] * b.idx[i];
    }
    return sum;
  }

  /// Gets the index of a given Coord element
  template <int Dim>
  CUTLASS_HOST_DEVICE int& at() {
    return idx[Dim];
  }

  /// Access via index; may limit unrolling potential
  CUTLASS_HOST_DEVICE
  int& at(int dim) { return idx[dim]; }

  /// Gets the index of a given Coord element
  template <int Dim>
  CUTLASS_HOST_DEVICE int const& at() const {
    return idx[Dim];
  }

  /// Access via index; may limit unrolling potential
  CUTLASS_HOST_DEVICE
  int const& at(int dim) const { return idx[dim]; }

  /// Determines if two Coord<> objects are equal
  CUTLASS_HOST_DEVICE
  bool operator==(Coord<N> const& b) const {
    bool equal = true;
    for (int i = 0; equal && i < N; ++i) {
      equal = (idx[i] == b.idx[i]);
    }
    return equal;
  }

  /// Not equal
  CUTLASS_HOST_DEVICE
  bool operator!=(Coord<N> const& b) const { return !(*this == b); }

  /// Clamps a coordinate to a range specified by maximum and minimum values
  CUTLASS_HOST_DEVICE
  Coord& clamp(Coord<N> const& max, Coord<N> const& min = Coord<N>()) {
    for (int i = 0; i < N; ++i) {
      idx[i] = __NV_STD_MAX(__NV_STD_MIN(idx[i], max.idx[i]), min.idx[i]);
    }
    return *this;
  }

  /// Returns the product of all elements
  CUTLASS_HOST_DEVICE
  int count() const {
    int product = idx[0];
    for (int i = 1; i < N; ++i) {
      product *= idx[i];
    }
    return product;
  }
};

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to make a 2-element coordinate
CUTLASS_HOST_DEVICE
Coord<1> make_Coord(int _0) {
  int values[1] = {_0};
  return Coord<1>(values);
}

/// Helper to make a 2-element coordinate
CUTLASS_HOST_DEVICE
Coord<2> make_Coord(int _0, int _1) {
  int values[2] = {_0, _1};
  return Coord<2>(values);
}

/// Helper to make a 3-element coordinate
CUTLASS_HOST_DEVICE
Coord<3> make_Coord(int _0, int _1, int _2) {
  int values[3] = {_0, _1, _2};
  return Coord<3>(values);
}

/// Helper to make a 4-element coordinate
CUTLASS_HOST_DEVICE
Coord<4> make_Coord(int _0, int _1, int _2, int _3) {
  int values[4] = {_0, _1, _2, _3};
  return Coord<4>(values);
}

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Getter
CUTLASS_HOST_DEVICE
Coord<2> get_Coord_hw(Coord<3> const& coord) { return make_Coord(coord[1], coord[2]); }

/// Getter
CUTLASS_HOST_DEVICE
Coord<2> get_Coord_hw(Coord<4> const& coord) { return make_Coord(coord[1], coord[2]); }

/// Getter
CUTLASS_HOST_DEVICE
Coord<3> get_Coord_hwc(Coord<4> const& coord) { return make_Coord(coord[1], coord[2], coord[3]); }

/// Getter
CUTLASS_HOST_DEVICE
Coord<3> get_Coord_dhw(Coord<4> const& coord) { return make_Coord(coord[0], coord[1], coord[2]); }

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace cutlass
