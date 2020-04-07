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
/*! \file
    \brief Defines layout functions used by TensorRef and derived classes. 

    Layout functions map logical coordinates to linear memory. They often require additional
    data to describe strides between elements.

    Layout functions must implement all members in the public interface of IdentityTensorLayout<>
    defined in cutlass/tensor_ref.h.
*/
#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/matrix_coord.h"
#include "cutlass/matrix_traits.h"

namespace cutlass {
namespace layout {

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Defines data layouts of various matrix formats usable by TensorRef and other classes.
//
/////////////////////////////////////////////////////////////////////////////////////////////////

/// Mapping function for row-major matrices.
class RowMajor {
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
  using TensorCoord = MatrixCoord;

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
  RowMajor(Index ldm = 0): stride_(ldm) { }

  /// Ctor
  CUTLASS_HOST_DEVICE
  RowMajor(Stride stride): stride_(stride) { }

  /// Helper returns a layout to a tightly packed tensor
  CUTLASS_HOST_DEVICE
  static RowMajor packed(MatrixCoord const &extent) {
    return RowMajor(extent.column());
  }

  /// Returns the offset of a coordinate in linear memory. 
  /// Assumes coordinate has convention (row, column)
  CUTLASS_HOST_DEVICE
  LongIndex operator()(MatrixCoord const &coord) const {
    return LongIndex(coord.row()) * LongIndex(stride_[0]) + coord.column();
  }

  /// Inverse of layout function, mapping linear offset to logical coordinate
  CUTLASS_HOST_DEVICE
  MatrixCoord inverse(LongIndex offset) const {
    return MatrixCoord(Index(offset / stride_[0]), Index(offset % stride_[0]));
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
  Index stride(int idx) const {
    return stride_[idx];
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Index & stride(int idx) {
    return stride_[idx];
  }

  /// Compute the number of contiguous elements needed to store a tensor with the given size
  CUTLASS_HOST_DEVICE
  LongIndex capacity(MatrixCoord const &extent) const {
    return LongIndex(extent.row()) * LongIndex(stride_[0]);
  }
};

/// Mapping function for column-major matrices.
class ColumnMajor {
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
  using TensorCoord = MatrixCoord;

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

  /// Ctor
  CUTLASS_HOST_DEVICE
  ColumnMajor(Index ldm = 0): stride_(ldm) { }
  
  /// Ctor
  CUTLASS_HOST_DEVICE
  ColumnMajor(Stride stride): stride_(stride) { }


  /// Helper returns a layout to a tightly packed tensor
  CUTLASS_HOST_DEVICE
  static ColumnMajor packed(MatrixCoord const &extent) {
    return ColumnMajor(extent.row());
  }

  /// Returns the offset of a coordinate in linear memory. 
  /// Assumes coordinate has convention (row, column)
  CUTLASS_HOST_DEVICE
  LongIndex operator()(MatrixCoord const &coord) const {
    return LongIndex(coord.column()) * LongIndex(stride_[0]) + coord.row();
  }

  /// Inverse of layout function, mapping linear offset to logical coordinate
  CUTLASS_HOST_DEVICE
  MatrixCoord inverse(LongIndex offset) const {
    return MatrixCoord(Index(offset % stride_[0]), Index(offset / stride_[0]));
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
  Index stride(int idx) const {
    return stride_[idx];
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Index & stride(int idx) {
    return stride_[idx];
  }

  /// Compute the number of contiguous elements needed to store a tensor with the given size
  CUTLASS_HOST_DEVICE
  LongIndex capacity(MatrixCoord const &extent) const {
    return LongIndex(extent.column()) * LongIndex(stride_[0]);
  }
};

/// Mapping function for interleaved matrices. Matrix is structured
/// as row-major arrangement of fixed-size columns.
template <int Interleave>
struct RowMajorInterleaved {
  
  /// Logical rank of tensor
  static int const kRank = 2;

  /// Rank of stride vector
  static int const kStrideRank = 1;

  /// Index type used for coordinates
  using Index = int32_t;

  /// Long index type used for offsets
  using LongIndex = int64_t;

  /// Logical coordinate
  using TensorCoord = MatrixCoord;

  /// Stride vector
  using Stride = Coord<kStrideRank, Index>;

  /// Size of interleaved columns
  static int const kInterleave = Interleave;

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

  /// Ctor
  CUTLASS_HOST_DEVICE
  RowMajorInterleaved(Index ldm = 0): stride_(ldm) { }
  
  /// Ctor
  CUTLASS_HOST_DEVICE
  RowMajorInterleaved(Stride stride): stride_(stride) { }

  /// Helper returns a layout to a tightly packed tensor
  CUTLASS_HOST_DEVICE
  static RowMajorInterleaved packed(MatrixCoord const &extent) {
    return RowMajorInterleaved(extent.column() * kInterleave);
  }

  /// Returns the offset of a coordinate in linear memory. 
  /// Assumes coordinate has convention (row, column)
  CUTLASS_HOST_DEVICE
  LongIndex operator()(MatrixCoord const &coord) const {
    Index row_major = coord.row() / kInterleave;
    Index row_minor = coord.row() % kInterleave;
    return LongIndex(row_major) * LongIndex(stride_[0]) + LongIndex(coord.column()) * kInterleave + row_minor;
  }

  /// Inverse of layout function, mapping linear offset to logical coordinate
  CUTLASS_HOST_DEVICE
  MatrixCoord inverse(LongIndex offset) const {

    Index row_major = Index(offset / stride_[0]);
    Index residual = Index(offset % stride_[0]);

    Index column = residual / kInterleave;
    Index row_minor =  residual % kInterleave;

    return MatrixCoord(row_major * kInterleave + row_minor, column);
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
  Index stride(int idx) const {
    return stride_[idx];
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Index & stride(int idx) {
    return stride_[idx];
  }

  /// Compute the number of contiguous elements needed to store a tensor with the given size
  CUTLASS_HOST_DEVICE
  LongIndex capacity(MatrixCoord const &extent) const {
    return (extent.row() + kInterleave - 1) / kInterleave * stride_[0];
  }
};

/// Mapping function for interleaved matrices. Matrix is structured
/// as column-major arrangement of fixed-size rows.
template <int Interleave>
struct ColumnMajorInterleaved {
  
  /// Logical rank of tensor
  static int const kRank = 2;

  /// Rank of stride vector
  static int const kStrideRank = 1;

  /// Index type used for coordinates
  using Index = int32_t;

  /// Long index type used for offsets
  using LongIndex = int64_t;

  /// Logical coordinate
  using TensorCoord = MatrixCoord;

  /// Stride vector
  using Stride = Coord<kStrideRank, Index>;

  /// Size of interleaved columns
  static int const kInterleave = Interleave;

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

  /// Ctor
  CUTLASS_HOST_DEVICE
  ColumnMajorInterleaved(Index ldm = 0): stride_(ldm) { }
  
  /// Ctor
  CUTLASS_HOST_DEVICE
  ColumnMajorInterleaved(Stride stride): stride_(stride) { }


  /// Helper returns a layout to a tightly packed tensor
  CUTLASS_HOST_DEVICE
  static ColumnMajorInterleaved packed(MatrixCoord const &extent) {
    return ColumnMajorInterleaved(extent.row() * kInterleave);
  }

  /// Returns the offset of a coordinate in linear memory. 
  /// Assumes coordinate has convention (row, column)
  CUTLASS_HOST_DEVICE
  LongIndex operator()(MatrixCoord const &coord) const {
    Index column_major = coord.column() / kInterleave;
    Index column_minor = coord.column() % kInterleave;
    return LongIndex(column_major) * LongIndex(stride_[0]) + LongIndex(coord.row()) * kInterleave + column_minor;
  }

  /// Inverse of layout function, mapping linear offset to logical coordinate
  CUTLASS_HOST_DEVICE
  MatrixCoord inverse(LongIndex offset) const {

    Index column_major = Index(offset / stride_[0]);
    Index residual = Index(offset % stride_[0]);

    Index row = residual / kInterleave;
    Index column_minor =  residual % kInterleave;

    return MatrixCoord(row, column_major * kInterleave + column_minor);
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
  Index stride(int idx) const {
    return stride_[idx];
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Index & stride(int idx) {
    return stride_[idx];
  }

  /// Compute the number of contiguous elements needed to store a tensor with the given size
  CUTLASS_HOST_DEVICE
  LongIndex capacity(MatrixCoord const &extent) const {
    return (extent.column() + kInterleave - 1) / kInterleave * stride_[0];
  }
};

/// Enumerated type for canonical pitch-linear matrix layouts
enum class Matrix {
  kColumnMajor,       ///< leading dimension refers to stride between columns; stride along rows is 1
  kRowMajor           ///< leading dimension refers to stride between rows; stride along columns is 1
};

/// Mapping function for scenario in which layout is row-major or column-major but this information
/// is only available at runtime.
struct ContiguousMatrix {

  /// Logical rank of tensor
  static int const kRank = 2;

  /// Rank of stride vector
  static int const kStrideRank = 1;

  /// Index type used for coordinates
  using Index = int32_t;

  /// Long index type used for offsets
  using LongIndex = int64_t;

  /// Logical coordinate
  using TensorCoord = MatrixCoord;

  /// Stride vector
  using Stride = Coord<kStrideRank, Index>;

private:
  //
  // Data members
  //

  /// Stride data member
  Stride stride_;

  /// Enumerated type indicating canonical matrix layout
  Matrix layout_;

public:
  //
  // Methods
  //

  /// Ctor
  CUTLASS_HOST_DEVICE
  ContiguousMatrix(
    Index ldm = 0, 
    Matrix layout = Matrix::kColumnMajor
  ):
    stride_(ldm), layout_(layout) { }

  /// Helper returns a layout to a tightly packed tensor
  CUTLASS_HOST_DEVICE
  static ContiguousMatrix packed(
    MatrixCoord const &extent, 
    Matrix layout = Matrix::kColumnMajor) {

    Index ldm = 0;
    if (layout == Matrix::kColumnMajor) {
      ldm = extent.row();
    }
    else if (layout == Matrix::kRowMajor) {
      ldm = extent.column();
    }
    return ContiguousMatrix(ldm, layout);
  }

  /// Returns the offset of a coordinate in linear memory. 
  /// Assumes coordinate has convention (row, column)
  CUTLASS_HOST_DEVICE
  LongIndex operator()(MatrixCoord const &coord) const {
    if (layout_ == Matrix::kColumnMajor) {
      return coord.row() + coord.column() * stride_[0];
    }
    else if (layout_ == Matrix::kRowMajor) {
      return coord.row() * stride_[0] + coord.column();
    }
    else {
      // degenerate case
      return 0;
    }
  }

  /// Inverse of layout function, mapping linear offset to logical coordinate
  CUTLASS_HOST_DEVICE
  MatrixCoord inverse(LongIndex offset) const {
    // TODO
    return MatrixCoord(0, 0);
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
  Index stride(int idx) const {
    return stride_[idx];
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Index & stride(int idx) {
    return stride_[idx];
  }

  /// Compute the number of contiguous elements needed to store a tensor with the given size
  CUTLASS_HOST_DEVICE
  LongIndex capacity(MatrixCoord const &extent) const {
    if (layout_ == Matrix::kColumnMajor) {
      return stride_[0] * extent.column();
    }
    else if (layout_ == Matrix::kRowMajor) {
      return stride_[0] * extent.row();
    }
    else {
      // degenerate case
      return 0;
    }
  }
};

/// Mapping function for block-linear matrices. Matrix is structured
/// as column-major arrangement of 2D tiles (that are column-major).
template <int BlockRows, int BlockColumns>
struct ColumnMajorBlockLinear {
  /// Logical rank of tensor
  static int const kRank = 2;

  /// Rank of stride vector
  static int const kStrideRank = 1;

  /// Index type used for coordinates
  using Index = int32_t;

  /// Long index type used for offsets
  using LongIndex = int64_t;

  /// Logical coordinate
  using TensorCoord = MatrixCoord;

  /// Stride vector
  using Stride = Coord<kStrideRank, Index>;

  /// Size of a block in rows
  static int const kBlockRows = BlockRows;

  /// Size of a block in columns
  static int const kBlockColumns = BlockColumns;

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

  /// Ctor
  CUTLASS_HOST_DEVICE
  ColumnMajorBlockLinear(Index ldm = 0): stride_(ldm) { }

  /// Helper returns a layout to a tightly packed tensor
  CUTLASS_HOST_DEVICE
  static ColumnMajorBlockLinear packed(MatrixCoord const &extent) {
    return ColumnMajorBlockLinear(extent.row() * kBlockRows * kBlockColumns);
  }

  /// Returns the offset of a coordinate in linear memory. 
  /// Assumes coordinate has convention (row, column)
  CUTLASS_HOST_DEVICE
  LongIndex operator()(MatrixCoord const &coord) const {
    return 
      (coord.row() % kBlockRows) + 
      (coord.column() % kBlockColumns) * kBlockRows +
      (coord.row() / kBlockRows) * kBlockRows * kBlockColumns +
      (coord.column() / kBlockColumns) * stride_[0];
  }

  /// Inverse of layout function, mapping linear offset to logical coordinate
  CUTLASS_HOST_DEVICE
  MatrixCoord inverse(LongIndex offset) const {

    // TODO
    return MatrixCoord(0, 0);
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
  Index stride(int idx) const {
    return stride_[idx];
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Index & stride(int idx) {
    return stride_[idx];
  }

  /// Compute the number of contiguous elements needed to store a tensor with the given size
  CUTLASS_HOST_DEVICE
  LongIndex capacity(MatrixCoord const &extent) const {
    return (extent.column() + kBlockColumns - 1) / kBlockColumns * stride_[0];
  }
};

/// Mapping function for block-linear matrices. Matrix is structured
/// as row-major arrangement of 2D tiles (that are row-major)
template <int BlockRows, int BlockColumns>
struct RowMajorBlockLinear {
  /// Logical rank of tensor
  static int const kRank = 2;

  /// Rank of stride vector
  static int const kStrideRank = 1;

  /// Index type used for coordinates
  using Index = int32_t;

  /// Long index type used for offsets
  using LongIndex = int64_t;

  /// Logical coordinate
  using TensorCoord = MatrixCoord;

  /// Stride vector
  using Stride = Coord<kStrideRank, Index>;

  /// Size of a block in rows
  static int const kBlockRows = BlockRows;

  /// Size of a block in columns
  static int const kBlockColumns = BlockColumns;

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

  /// Ctor
  CUTLASS_HOST_DEVICE
  RowMajorBlockLinear(Index ldm = 0): stride_(ldm) { }

  /// Helper returns a layout to a tightly packed tensor
  CUTLASS_HOST_DEVICE
  static RowMajorBlockLinear packed(MatrixCoord const &extent) {
    return RowMajorBlockLinear(extent.column() * kBlockRows * kBlockColumns);
  }

  /// Returns the offset of a coordinate in linear memory. 
  /// Assumes coordinate has convention (row, column)
  CUTLASS_HOST_DEVICE
  LongIndex operator()(MatrixCoord const &coord) const {
    return 
      (coord.column() % kBlockColumns) +
      (coord.row() % kBlockRows) * kBlockColumns +
      (coord.column() / kBlockColumns) * kBlockRows * kBlockColumns +
      (coord.row() / kBlockRows) * stride_[0];
  }

  /// Inverse of layout function, mapping linear offset to logical coordinate
  CUTLASS_HOST_DEVICE
  MatrixCoord inverse(LongIndex offset) const {
    // TODO
    return MatrixCoord(0, 0);
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
  Index stride(int idx) const {
    return stride_[idx];
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Index & stride(int idx) {
    return stride_[idx];
  }
  
  /// Compute the number of contiguous elements needed to store a tensor with the given size
  CUTLASS_HOST_DEVICE
  LongIndex capacity(MatrixCoord const &extent) const {
    return (extent.row() + kBlockRows - 1) / kBlockRows * stride_[0];
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

struct GeneralMatrix {

  /// Logical rank of tensor
  static int const kRank = 2;

  /// Rank of stride vector
  static int const kStrideRank = 2;

  /// Index type used for coordinates
  using Index = int32_t;

  /// Long index type used for offsets
  using LongIndex = int64_t;

  /// Logical coordinate
  using TensorCoord = MatrixCoord;

  /// Stride vector
  using Stride = Coord<kStrideRank, Index>;

private:
  //
  // Data members
  //

  MatrixLayout layout_id_;

  /// Stride data member
  Stride stride_;

public:
  //
  // Methods
  //

  /// Ctor
  CUTLASS_HOST_DEVICE
  GeneralMatrix(): layout_id_(MatrixLayout::kColumnMajor), stride_(make_Coord(0, 1)) { }

  /// Ctor
  CUTLASS_HOST_DEVICE
  GeneralMatrix(
    MatrixLayout layout_id, 
    Index ldm, 
    Index interleave): layout_id_(layout_id), stride_(make_Coord(ldm, interleave)) { }

  /// Helper returns a layout to a tightly packed tensor
  CUTLASS_HOST_DEVICE
  static GeneralMatrix packed(
    MatrixCoord const &extent, 
    MatrixLayout layout_id = MatrixLayout::kColumnMajor, 
    Index interleave = 1) {

    Index c;
    if (layout_id == MatrixLayout::kRowMajor) {
      c = extent.column();
    }
    else {
      c = extent.row();
    }

    Index ldm = c * interleave;

    return GeneralMatrix(layout_id, ldm, interleave);
  }

  /// Returns the offset of a coordinate in linear memory. 
  /// Assumes coordinate has convention (row, column)
  CUTLASS_HOST_DEVICE
  LongIndex operator()(MatrixCoord const &coord) const {
    Index c, s;
    if (layout_id_ == MatrixLayout::kRowMajor) {
      c = coord.column();
      s = coord.row();
    }
    else {
      s = coord.column();
      c = coord.row();
    }

    Index v = s / stride_[1];
    Index residual = (s % stride_[1]);

    return LongIndex(c) * LongIndex(stride_[1]) + LongIndex(v) * LongIndex(stride_[0]) + residual;
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Stride stride() const {
    return stride_;
  }

  CUTLASS_HOST_DEVICE
  MatrixLayout layout_id() const {
    return layout_id_;
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Stride & stride() {
    return stride_;
  }

  CUTLASS_HOST_DEVICE
  MatrixLayout & layout_id() {
    return layout_id_;
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Index stride(int idx) const {
    return stride_[idx];
  }

  /// Returns the stride of the layout
  CUTLASS_HOST_DEVICE
  Index & stride(int idx) {
    return stride_[idx];
  }
  
  /// Compute the number of contiguous elements needed to store a tensor with the given size
  CUTLASS_HOST_DEVICE
  LongIndex capacity(MatrixCoord const &extent) const {
    Index s;
    if (layout_id_ == MatrixLayout::kRowMajor) {
      s = extent.row();
    }
    else {
      s = extent.column();
    }

    Index v = Index((s + stride_[1] - 1) / stride_[1]);
    return LongIndex(v) * LongIndex(stride_[0]);
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Defines transposes of matrix layouts
template <typename Layout>
struct LayoutTranspose;

/// Transpose of row-major is column-major
template <>
struct LayoutTranspose<layout::RowMajor> {
  using type = layout::ColumnMajor;
};

/// Transpose of column-major is row-major
template <>
struct LayoutTranspose<layout::ColumnMajor> {
  using type = layout::RowMajor;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace layout
} // namespace cutlass
