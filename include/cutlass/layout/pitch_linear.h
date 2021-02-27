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
    \brief Defines layout functions used by TensorRef and derived classes for pitch-linear memory.
*/
#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/coord.h"

namespace cutlass {
namespace layout {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Template defining a shape used by pitch-linear operators
template <
  int Contiguous,
  int Strided
>
struct PitchLinearShape {
  static int const kContiguous = Contiguous;
  static int const kStrided = Strided;
  static int const kCount = Contiguous * Strided;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Coordinate in pitch-linear space
struct PitchLinearCoord : public Coord<2, int> {
public:

  /// Integer-valued index
  using Index = int;

  /// Base type is a Coord of rank=2
  using Base = Coord<2, Index>;

private:

  /// Rows dimension
  static int const kContiguous = 0;

  /// Columns dimension
  static int const kStrided = 1;

public:

  //
  // Methods
  //

  /// Default ctor
  CUTLASS_HOST_DEVICE
  PitchLinearCoord() { }

  /// Constructs from Coord<2>
  CUTLASS_HOST_DEVICE
  PitchLinearCoord(Coord<2, Index> const &coord): Base(coord) { }

  /// Helper to construct from a row and column
  CUTLASS_HOST_DEVICE
  PitchLinearCoord(Index contiguous_, Index strided_): Base(make_Coord(contiguous_, strided_)) { }

  /// Returns the contiguous dimension
  CUTLASS_HOST_DEVICE
  Index const & contiguous() const { return this->at(kContiguous); }

  /// Returns the contiguous dimension
  CUTLASS_HOST_DEVICE
  Index & contiguous() { return this->at(kContiguous); }

  /// Returns the column of the coordinate
  CUTLASS_HOST_DEVICE
  Index const & strided() const { return this->at(kStrided); }

  /// Returns the column of the coordinate
  CUTLASS_HOST_DEVICE
  Index & strided() { return this->at(kStrided); }

  //
  // Coord operators
  //

  /// Element-wise addition
  CUTLASS_HOST_DEVICE
  PitchLinearCoord operator+(Base const& b) const {
    return PitchLinearCoord(Base::operator+(b));
  }

  /// Element-wise subtraction
  CUTLASS_HOST_DEVICE
  PitchLinearCoord operator-(Base const& b) const {
    return PitchLinearCoord(Base::operator-(b));
  }

  CUTLASS_HOST_DEVICE
  PitchLinearCoord operator-() const {
    return PitchLinearCoord(-at(0), -at(1));
  }

  /// Element-wise multiplication
  CUTLASS_HOST_DEVICE
  PitchLinearCoord operator*(Base const& b) const {
    return PitchLinearCoord(Base::operator*(b));
  }

  /// Element-wise division
  CUTLASS_HOST_DEVICE
  PitchLinearCoord operator/(Base const& b) const {
    return PitchLinearCoord(Base::operator/(b));
  }

  /// In-place addition
  CUTLASS_HOST_DEVICE
  PitchLinearCoord& operator+=(Base const& b) {
    Base::operator+=(b);
    return *this;
  }

  /// In-place subtraction
  CUTLASS_HOST_DEVICE
  PitchLinearCoord& operator-=(Base const& b) {
    Base::operator-=(b);
    return *this;
  }

  /// In-place multiplication
  CUTLASS_HOST_DEVICE
  PitchLinearCoord& operator*=(Base const& b) {
    Base::operator*=(b);
    return *this;
  }

  /// In-place division
  CUTLASS_HOST_DEVICE
  PitchLinearCoord& operator/=(Base const& b) {
    Base::operator/=(b);
    return *this;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Mapping function for pitch-linear memory
class PitchLinear {
public:
  /// Logical rank of tensor
  static int const kRank = 2;

  /// Rank of stride vector
  static int const kStrideRank = 1;

  /// Index type used for coordinates
  using Index = int32_t;

  /// Long index type used for offsets
  using LongIndex = int64_t;

  /// Logical coordinate
  using TensorCoord = PitchLinearCoord;

  /// Stride vector
  using Stride = Coord<kStrideRank, Index>;

private:
  //
  // Data members
  //

  /// Stride data member
  Stride stride_;

public:
  //
  // Methods
  //
  
  /// Constructor
  CUTLASS_HOST_DEVICE
  PitchLinear(Index ldm = 0): stride_(ldm) { }

  /// Constructor
  CUTLASS_HOST_DEVICE
  PitchLinear(Stride _stride): stride_(_stride) { }

  /// Helper returns a layout to a tightly packed tensor
  CUTLASS_HOST_DEVICE
  static PitchLinear packed(TensorCoord const &extent) {
    return PitchLinear(extent.contiguous());
  }

  /// Returns the offset of a coordinate in linear memory. 
  /// Assumes coordinate has convention (contiguous, strided)
  CUTLASS_HOST_DEVICE
  LongIndex operator()(TensorCoord const &coord) const {
    return LongIndex(coord.contiguous()) + LongIndex(coord.strided()) * LongIndex(stride_[0]);
  }

  /// Returns the logical coordinate given an offset.
  CUTLASS_HOST_DEVICE
  TensorCoord inverse(LongIndex index) const {
    return make_Coord(
      Index(index % stride_[0]),
      Index(index / stride_[0])
    );
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Stride stride() const {
    return stride_;
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Stride & stride() {
    return stride_;
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Index stride(int rank) const {
    return stride_[rank];
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Index & stride(int rank) {
    return stride_[rank];
  }

  /// Compute the number of contiguous elements needed to store a tensor with the given size
  CUTLASS_HOST_DEVICE
  LongIndex capacity(TensorCoord const &extent) const {
    return extent.strided() * stride_[0];
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace layout
} // namespace cutlass

