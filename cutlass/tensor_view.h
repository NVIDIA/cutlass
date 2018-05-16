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
    \brief Defines a structure containing strides and a pointer to tensor data.
*/

#pragma once

#include <cmath>

#include <cutlass/cutlass.h>
#include <cutlass/tensor_ref.h>

namespace cutlass {

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Host-side reference implementation of tensor operations
template <typename T>
class TensorView : public TensorRef<T, 4> {
 public:
  /// Reference and stride
  typedef TensorRef<T, 4> Base;

  /// Reference and stride
  typedef Base TensorRef_t;

  /// Reference to constant type
  typedef TensorRef<T const, 4> ConstTensorRef_t;

  /// Rank of tensor
  static int const Rank = TensorRef_t::Rank;

  /// Type used to compute the offset of an element to the base of a tensor
  typedef int Offset_t;

  /// Coordinate into tensor
  typedef Coord<Rank> Coord_t;

 private:
  //
  // Data members
  //

  /// Pointer to pitch-linear memory
  TensorRef_t ref_;

  /// Dimensions of coordinate (independent of stride)
  Coord_t size_;

 public:
  //
  // Device and Host Methods
  //

  /// Default constructor
  CUTLASS_HOST_DEVICE
  TensorView() {}

  /// Constructs a Tensor_view from a TensorRef and size
  CUTLASS_HOST_DEVICE
  TensorView(TensorRef_t const& _ref, Coord_t const& _size) : Base(_ref), size_(_size) {}

  /// Returns true if the Tensor_view is bound to some memory
  CUTLASS_HOST_DEVICE
  bool good() const { return ref().good(); }

  /// Returns a pointer to data
  CUTLASS_HOST_DEVICE
  T* data() const { return ref().data(); }

  /// Updates the reference and size of a Tensor_view object
  CUTLASS_HOST_DEVICE
  void reset(TensorRef_t const& _ref = TensorRef_t(0), Coord_t const& _size = Coord_t()) {
    Base::operator=(_ref);
    size_ = _size;
  }

  /// Accesses the tensor reference pointing to data
  CUTLASS_HOST_DEVICE
  TensorRef_t& ref() { return *this; }

  ///
  CUTLASS_HOST_DEVICE
  ConstTensorRef_t const_ref() { return ConstTensorRef_t(data(), stride()); }

  /// Accesses the tensor reference pointing to data
  CUTLASS_HOST_DEVICE
  TensorRef_t const& ref() const { return *this; }

  /// Accesses the size
  CUTLASS_HOST_DEVICE
  Coord_t const& size() const { return size_; }

  /// Accesses the size
  CUTLASS_HOST_DEVICE
  int size(int dim) const { return size_.at(dim); }

  /// Accesses the stride
  CUTLASS_HOST_DEVICE
  Coord_t const& stride() const { return ref().stride(); }

  /// Accesses the stride
  CUTLASS_HOST_DEVICE
  int const& stride(int dim) const { return ref().stride(dim); }

  /// Assigns the Tensor_view
  CUTLASS_HOST_DEVICE
  TensorView& operator=(TensorView const& _tensor) {
    Base::operator=(_tensor._ref);
    size_ = _tensor.size_;
    return *this;
  }

  /// Returns the index of an element
  CUTLASS_HOST_DEVICE
  Offset_t offset(Coord_t const& coord) const { return ref().offset(coord); }

  /// Determines whether a location is within a tensor
  CUTLASS_HOST_DEVICE
  bool contains(Coord_t const& coord) const {
    for (int dim = 0; dim < Rank; ++dim) {
      if (coord.at(dim) >= size_.at(dim)) {
        return false;
      }
    }
    return true;
  }

  /// Element-wise accessor
  CUTLASS_HOST_DEVICE
  T& at(Coord_t const& coord) const { return ref().at(coord); }

  /// Element-wise accessor
  T& operator[](Coord<Rank> const& coord) const { return at(coord); }

  /// Element-wise accessor
  CUTLASS_HOST_DEVICE
  T& at(Offset_t idx) const { return ref().at(idx); }

  /// Returns a Tensor_view given location and size quantities
  CUTLASS_HOST_DEVICE
  TensorView<T> subview(Coord_t const& location, Coord_t size) const {
    return TensorView<T>(ref() + location, size.clamp(size_ - location));
  }
};

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace cutlass
