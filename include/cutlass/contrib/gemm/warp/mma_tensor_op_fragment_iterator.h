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
    \brief This defines a "fragment" iterator for visiting the fragments of a warp tile
      that participate in one warp-level mma operation.

      Typically, this is used to access the accumulator tile/fragement of a warp-level mma
   operation. The accumulator tile is then partitioned into smaller tiles/fragments that can be fed
   into next warp-level mma operation.

      This iterator is necessary to accomplish warp-level mma fusion where the accumulator tile is
      reused as multiplicand tile for the next mma.

*/

#pragma once

#include "cutlass/cutlass.h"

#include "cutlass/array.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/layout/tensor.h"
#include "cutlass/numeric_conversion.h"

namespace cutlass {
namespace contrib {
namespace gemm {
namespace warp {

////////////////////////////////////////////////////////////////////////////////

template <
    /// Size of the matrix to load (concept: MatrixShape)
    typename Shape_,
    /// Size of the accumulation tile shape (concept: MatrixShape)
    typename AccumulatorShape_,
    /// KBlocks columns to compute residual
    int KBlocksColumn_,
    /// Accumulator Element type
    typename ElementAccumulator_,
    /// Element type
    typename Element_,
    /// Layout of operand in memory
    typename Layout_,
    /// Shape of one matrix product operation (concept: MatrixShape)
    typename InstructionShape_,
    /// Output operation on the fragment
    typename OutputOp_,
    /// Whether beta is zero
    bool IsBetaZero_>
class MmaTensorOpFragmentIterator;

// Partial specialization for row-major accumulator tile

template <
    /// Shape of warp tile to load (concept: MatrixShape)
    typename Shape_,
    /// Shape of the warp accumulation tile (concept: MatrixShape)
    typename AccumulatorShape_,
    /// KBlocks columns to compute residual
    int KBlocksColumn_,
    /// Accumulator Element type
    typename ElementAccumulator_,
    /// Element type
    typename Element_,
    /// Shape of one matrix product operation (concept: MatrixShape)
    typename InstructionShape_,
    /// Output operation on fragment
    typename OutputOp_>
class MmaTensorOpFragmentIterator<Shape_,
                                  AccumulatorShape_,
                                  KBlocksColumn_,
                                  ElementAccumulator_,
                                  Element_,
                                  cutlass::layout::RowMajor,
                                  InstructionShape_,
                                  OutputOp_,
                                  true> {
 public:
  /// Shape of warp tile to load (concept: MatrixShape)
  using Shape = Shape_;

  /// Layout of source tile
  using Layout = cutlass::layout::RowMajor;

  /// KBlocks columns to compute residual
  static int const kKBlockColumn = KBlocksColumn_;

  /// Shape of the actual matrix to load
  using TensorCoord = typename Layout::TensorCoord;

  /// Shape of the warp accumulation tile (concept: MatrixShape)
  using AccumulatorShape = AccumulatorShape_;

  /// Accumulator Element type
  using ElementAccumulator = ElementAccumulator_;

  /// Element type
  using Element = Element_;

  /// Shape of one matrix product operation (concept: MatrixShape)
  using InstructionShape = InstructionShape_;

  /// Output operation on fragment
  using OutputOp = OutputOp_;

  /// Number of participating threads
  static int const kThreads = 32;

  /// Internal structure of iterator - made public to enable introspection
  struct Policy {
    static_assert(!(InstructionShape::kK % InstructionShape::kN),
                  "instruction dim K size must be divisible by dim N size");
    static_assert(!(Shape::kRow % InstructionShape::kM) &&
                      !(Shape::kColumn % InstructionShape::kK),
                  "Shape of warp-level Mma must be divisible by operator shape.");
    static_assert(!(AccumulatorShape::kRow % Shape::kRow) &&
                      !(AccumulatorShape::kColumn % Shape::kColumn),
                  "Shape of Warp Accumulator must be divisible by warp shape.");
    static_assert(!(kKBlockColumn % Shape::kColumn),
                  "KBlock size must be divisible by warp shape.");
    /// Number of times this iterator can be incremented
    static int const kIterations = AccumulatorShape::kCount / Shape::kCount;
  };

 private:
  static int const kIterationsPerBlock = kKBlockColumn / Shape::kColumn;
  static int const kElementsPerAccess = InstructionShape::kM * InstructionShape::kN / kThreads;
  /// Number of accumulator mma need to access for an operand mma load
  static int const kNumAccumulatorMma = InstructionShape::kK / InstructionShape::kN;

  /// Number of mma operations performed by a warp
  using MmaIterations =
      MatrixShape<Shape::kRow / InstructionShape::kM, Shape::kColumn / InstructionShape::kK>;
  /// Number of mma operations performed by the entire accumulator
  using AccumulatorIterations = MatrixShape<AccumulatorShape::kRow / InstructionShape::kM,
                                            AccumulatorShape::kColumn / InstructionShape::kN>;

 public:
  //
  // Derived quantities
  //

  /// Fragment object holding a thread's part of a tile
  /// This is the fragment size produced by one access of the iterator.
  using Fragment = Array<Element, Shape::kCount / kThreads>;

  /// Accumulator Fragment object
  using AccumulatorFragment = Array<ElementAccumulator, AccumulatorShape::kCount / kThreads>;

 private:
  /// Internal access type
  using AccessType = Array<ElementAccumulator, kElementsPerAccess>;
  using FragmentAccessType = Array<Element, kElementsPerAccess>;

 private:
  //
  // Data members
  //

  /// Accumulator tile
  AccessType const* accumulators_;

  bool is_residual_tile_;
  int index_;          // warp tile index
  int residual_index_;

 public:
  /// Constructs an iterator
  CUTLASS_HOST_DEVICE
  MmaTensorOpFragmentIterator(AccumulatorFragment const& accum, int column_extent)
      : accumulators_(reinterpret_cast<AccessType const*>(&accum)),
        is_residual_tile_(true),
        index_(0) {
    int residual_columns_ = column_extent % kKBlockColumn;
    residual_columns_ = residual_columns_ ? residual_columns_ : kKBlockColumn;
    residual_index_ = residual_columns_ / Shape::kColumn;
  }

  /// Increments
  CUTLASS_HOST_DEVICE
  MmaTensorOpFragmentIterator& operator++() {
    ++index_;
    if (is_residual_tile_ && index_ >= kIterationsPerBlock) {
      is_residual_tile_ = false;
      index_ = residual_index_;
    }
    return *this;
  }

  /// Loads a fragment from the referenced part of the accumulator tile
  CUTLASS_HOST_DEVICE
  void load(Fragment& frag) const {
    FragmentAccessType* frag_ptr = reinterpret_cast<FragmentAccessType*>(&frag);

    if (is_residual_tile_ && index_ >= residual_index_) {
      frag.clear();
      return;
    }

    int base_access_offset =
        MmaIterations::kRow * MmaIterations::kColumn * kNumAccumulatorMma * index_;

    CUTLASS_PRAGMA_UNROLL
    for (int m = 0; m < MmaIterations::kRow; m++) {
      CUTLASS_PRAGMA_UNROLL
      for (int n = 0; n < MmaIterations::kColumn; n++) {
        CUTLASS_PRAGMA_UNROLL
        for (int k = 0; k < kNumAccumulatorMma; ++k) {
          // operand mma is row major, while accumulator mma is column major
          int operand_access_offset = (m * MmaIterations::kColumn + n) * kNumAccumulatorMma + k;
          int accumulator_access_offset =
              base_access_offset + (n * kNumAccumulatorMma + k) * MmaIterations::kRow + m;
          frag_ptr[operand_access_offset] = accumulators_[accumulator_access_offset];
        }
      }
    }
  }
};

////////////////////////////////////////////////////////////////////////////////

}  // namespace warp
}  // namespace gemm
}  // namespace contrib
}  // namespace cutlass
