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
    \brief Defines a structure containing strides, bounds, and a pointer to tensor data.
*/
#pragma once

#include <typeinfo>

#include <cutlass/coord.h>
#include <cutlass/cutlass.h>
#include <cutlass/vector.h>

namespace cutlass {

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Structure modeling a pointer and stride into a tensor
template <typename Storage_, int Rank_>
class TensorRef {
 public:
  /// Data type of individual access
  typedef Storage_ Storage;

  /// Rank of tensor
  static int const Rank = Rank_;

 private:
  //
  // Data members
  //

  /// Pointer to storage element
  Storage* ptr_;

  /// Stride information
  Coord<Rank> stride_;

 public:
  //
  // Methods
  //

  /// Default ctor
  CUTLASS_HOST_DEVICE
  TensorRef() : ptr_(nullptr) {}

  /// Constructs from a pointer, size, and stride
  CUTLASS_HOST_DEVICE
  TensorRef(Storage* ptr, Coord<Rank> stride) : ptr_(ptr), stride_(stride) {}

  /// Updates the pointer, stride, and location within a TensorRef
  CUTLASS_HOST_DEVICE
  void reset(Storage* ptr = nullptr, Coord<Rank> stride = Coord<Rank>(0)) {
    ptr_ = ptr;
    stride_ = stride;
  }

  /// Conversion function
  template <typename T>
  TensorRef<T, Rank> convert() {
    Coord<Rank> converted_stride;
    for (int i = 0; i < Rank - 1; ++i) {
      converted_stride[i] = stride_[i] * Extent<Storage>::kValue / Extent<T>::kValue;
    }
    converted_stride[Rank - 1] = stride_[Rank - 1];

    return TensorRef<T, Rank>(reinterpret_cast<T*>(ptr_), converted_stride);
  }

  /// Returns true if the TensorRef may be safely accessed
  CUTLASS_HOST_DEVICE
  bool good() const { return ptr_ != nullptr; }

  /// Returns the pointer to referenced data
  CUTLASS_HOST_DEVICE
  Storage* data() const { return ptr_; }

  /// Returns the stride of the tensor
  CUTLASS_HOST_DEVICE
  Coord<Rank> const& stride() const { return stride_; }

  /// Returns the stride of the tensor in the given dimension
  CUTLASS_HOST_DEVICE
  int const& stride(int dim) const { return stride_.at(dim); }

  /// Returns the maximum stride element as the 'leading dimension'
  CUTLASS_HOST_DEVICE
  int leading_dim() const { return __NV_STD_MAX(stride_[1], stride_[2]); }

  /// Computes the offset of an index from the origin of the tensor
  CUTLASS_HOST_DEVICE
  long long offset(Coord<Rank> const& coord) const {
    return stride_.template dot<long long>(coord);
  }

  /// Returns a reference to the element at a given Coord
  CUTLASS_HOST_DEVICE
  Storage& at(Coord<Rank> const& coord) const { return ptr_[offset(coord)]; }

  /// Element-wise accessor
  Storage& operator[](Coord<Rank> const& coord) const { return at(coord); }

  /// Returns a reference to the element at a given Coord
  CUTLASS_HOST_DEVICE
  Storage& at(int idx) const { return ptr_[idx]; }

  /// Element-wise accessor
  Storage& operator[](int idx) const { return at(idx); }

  /// Adds an offset to the pointer
  CUTLASS_HOST_DEVICE
  TensorRef& advance(Coord<Rank> const& b) {
    ptr_ += offset(b);
    return *this;
  }

  /// Returns a TensorRef offset by a given amount
  CUTLASS_HOST_DEVICE
  TensorRef operator+(Coord<Rank> const& b) const { return TensorRef(ptr_ + offset(b), stride_); }

  /// Returns a TensorRef offset by a given amount
  CUTLASS_HOST_DEVICE
  TensorRef operator-(Coord<Rank> const& b) const { return TensorRef(ptr_ - offset(b), stride_); }
};

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace cutlass
