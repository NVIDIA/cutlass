/*! \file
    \brief Defines layout functions used by TensorRef and derived classes for pitch-linear memory.
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/coord.h"
#include "cutlass/pitch_linear_coord.h"

namespace cutlass {
namespace layout {


template <int Contiguous, int Strided>
  using PitchLinearShape = cutlass::PitchLinearShape < Contiguous, Strided >;
  using PitchLinearCoord = PitchLinearCoord;

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
  using Stride = Coord<kStrideRank, LongIndex>;

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
  PitchLinear(LongIndex ldm = 0): stride_(ldm) { }

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
      TensorCoord::Index(index % stride_[0]),
      TensorCoord::Index(index / stride_[0])
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
  LongIndex stride(int rank) const {
    return stride_[rank];
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  LongIndex & stride(int rank) {
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

