/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
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
    \brief Templates implementing loading of convolution tiles mapped to GEMM A (output gradient tile) 
    matrix from memory.

    This iterator assumes TensorNHWC layout of tensors in Global Memory.

    The iterator is specialized for each of the three convolution operators: forward propagation (Fprop),
    backward data gradient (Dgrad), and backward weight gradient (Wgrad). 
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/array.h"
#include "cutlass/coord.h"
#include "cutlass/predicate_vector.h"
#include "cutlass/tensor_ref.h"
#include "cutlass/tensor_view.h"
#include "cutlass/layout/pitch_linear.h"
#include "cutlass/layout/tensor.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/conv/convolution.h"
#include "cutlass/conv/conv2d_problem_size.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace conv {
namespace threadblock {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
  typename Shape_,
  typename Element_,
  typename ThreadMap_
>
class Conv2dWgradOutputGradientTileAccessIteratorOptimized {
public:

  //
  // Types
  //
  using Shape = Shape_;
  using Element = Element_;
  using Layout = layout::TensorNHWC;
  using ThreadMap = ThreadMap_;
  using AccessType = AlignedArray<Element, ThreadMap::kElementsPerAccess>;
  using TensorRef = cutlass::TensorRef<Element, Layout>;
  using TensorCoord = typename Layout::TensorCoord;
  using Index = typename Layout::Index;
  using LongIndex = typename Layout::LongIndex;
  static IteratorAlgorithm const kIteratorAlgorithm = conv::IteratorAlgorithm::kOptimized;
  static StrideSupport const kStrideSupport = conv::StrideSupport::kStrided;
  static int const kConvDim = 2;
  using ConvProblemSize = typename conv::Conv2dProblemSize;

  static_assert(sizeof_bits<Element>::value >= 8,
    "WGRAD requires elements of size 8b or greater.");

  //
  // Parameters structure
  //

  struct Params : Conv2dWgradOutputGradientIteratorOptimizedParams {

    //
    // Methods
    //

    CUTLASS_HOST_DEVICE
    Params() { }

    CUTLASS_HOST_DEVICE
    Params(Conv2dWgradOutputGradientIteratorOptimizedParams const &base): 
      Conv2dWgradOutputGradientIteratorOptimizedParams(base) { }
      
    CUTLASS_HOST_DEVICE
    Params(
      Conv2dProblemSize const &problem_size, 
      Layout const &layout
    ): 
      Conv2dWgradOutputGradientIteratorOptimizedParams(
        problem_size,
        layout,
        sizeof_bits<Element>::value,
        {Shape::kRow, Shape::kColumn},
        ThreadMap::kThreads,
        ThreadMap::kElementsPerAccess,
        {ThreadMap::Iterations::kContiguous, ThreadMap::Iterations::kStrided},
        {ThreadMap::Delta::kContiguous, ThreadMap::Delta::kStrided}
      ) { }
  };

private:

  Conv2dWgradOutputGradientIteratorOptimizedParams const &params_;
  Conv2dProblemSize const &problem_size_;
  LongIndex iteration_contiguous_;
  LongIndex iteration_strided_;
  char const *pointer_;

  uint32_t predicates_;
  int filter_k_;
  int offset_npq_;

public:

  CUTLASS_HOST_DEVICE
  Conv2dWgradOutputGradientTileAccessIteratorOptimized(
    Conv2dWgradOutputGradientIteratorOptimizedParams const &params,
    Conv2dProblemSize const &problem_size,
    Element const *ptr,
    int thread_idx,
    MatrixCoord const &threadblock_offset = MatrixCoord()
  ):
    params_(params), 
    problem_size_(problem_size), 
    pointer_(reinterpret_cast<char const *>(ptr)),
    predicates_(0),
    filter_k_(0),
    offset_npq_(0) {

    layout::PitchLinearCoord thread_coord = ThreadMap::initial_offset(thread_idx);

    filter_k_ = threadblock_offset.row() + thread_coord.contiguous();
    offset_npq_ = threadblock_offset.column() + thread_coord.strided();
    
    CUTLASS_PRAGMA_UNROLL
    for (int s = 0; s < ThreadMap::Iterations::kStrided; ++s) {
      CUTLASS_PRAGMA_UNROLL
      for (int c = 0; c < ThreadMap::Iterations::kContiguous; ++c) {

        int filter_k = filter_k_ + c * ThreadMap::Delta::kContiguous;
        int offset_npq = offset_npq_ + s * ThreadMap::Delta::kStrided;

        bool predicate = valid_(at_(offset_npq, filter_k));

        uint32_t pred = (predicate ? 1u : 0);

        int pred_idx = c + s * ThreadMap::Iterations::kContiguous;
        
        predicates_ |= (pred << pred_idx);
      }
    }

    // Offset pointer to (iteration_strided_, iteration_contiguous_) = (0, 0) 
    pointer_ += (
      offset_npq_ * params.layout.stride()[0] + filter_k_
    ) * sizeof_bits<Element>::value / 8;

    set_iteration_index(0);
  }

  /// Overrides the internal iteration index
  CUTLASS_HOST_DEVICE
  void set_iteration_index(Index index) {
    iteration_contiguous_ = index % ThreadMap::Iterations::kContiguous;
    iteration_strided_ = index / ThreadMap::Iterations::kContiguous;
  }

  /// Adds a pointer offset in units of Element
  CUTLASS_HOST_DEVICE
  void add_pointer_offset(LongIndex pointer_offset) {
    pointer_ += pointer_offset * sizeof_bits<Element>::value / 8;
  }

  CUTLASS_HOST_DEVICE
  void advance() {
    // moves to the next GEMM-K offset (offset_npq_) in GEMM-A by a CTA-K tile
    offset_npq_ += Shape::kColumn * problem_size_.split_k_slices;

    // Clear predicates if needed
    CUTLASS_PRAGMA_UNROLL
    for (int s = 0; s < ThreadMap::Iterations::kStrided; ++s) {
      if (offset_npq_ + s * ThreadMap::Delta::kStrided >= params_.NPQ) {
        uint32_t kClearMask = ((1u << ThreadMap::Iterations::kContiguous) - 1) << (s * ThreadMap::Iterations::kContiguous); 
        predicates_ = (predicates_ & (~kClearMask));
      }
    }

    pointer_ += params_.inc_next_npq; 
  }

private:
  /// Returns the coordinate in the output gradient tensor Dy that is pointed to
  /// by offset_npq and k.
  CUTLASS_HOST_DEVICE
  TensorCoord at_(int offset_npq, int k) const {

    // The subseqnet fast_divmod() operations are equivalent to the following logical computation:
    //
    //
    // int npq = offset_npq;
    // int n = npq / (problem_size_.P * problem_size_.Q);
    // int residual = npq % (problem_size_.P * problem_size_.Q);
    // 
    // int p = residual / problem_size_.Q;
    // int q = residual % problem_size_.Q;
    
    int residual, n, p, q;
    
    params_.pq_divmod(n, residual, offset_npq);
    params_.q_divmod(p, q, residual);

    return TensorCoord(n, p, q, k);
  }
  
  /// Returns true if the coord is within the output gradient tensor Dy
  CUTLASS_HOST_DEVICE
  bool valid_(TensorCoord coord) const {

    return coord.n() < problem_size_.N &&
      coord.c() < problem_size_.K;
  }

public:

  /// Returns true if the current coordinate is within the output gradient tensor Dy
  CUTLASS_HOST_DEVICE
  bool valid() const {

    LongIndex pred_idx = iteration_contiguous_ + iteration_strided_ * ThreadMap::Iterations::kContiguous;
    return (predicates_ & (1u << pred_idx));
  }

  /// Returns a pointer to the vector starting at the current coordinate
  CUTLASS_HOST_DEVICE
  AccessType const *get() const {

    return reinterpret_cast<AccessType const *>(
      pointer_ +
      iteration_strided_ * params_.offset_next_strided + 
      iteration_contiguous_ * params_.offset_next_contiguous
    );
  }

  /// Increments to the next memory access
  CUTLASS_HOST_DEVICE
  Conv2dWgradOutputGradientTileAccessIteratorOptimized &operator++() {
    ++iteration_contiguous_;
    if (iteration_contiguous_ < ThreadMap::Iterations::kContiguous) {
      return *this;
    }
    iteration_contiguous_ = 0;
    ++iteration_strided_;
    if (iteration_strided_ < ThreadMap::Iterations::kStrided) {
      return *this;
    }
    iteration_strided_ = 0;
 
    return *this;
  }

  /// Determines whether the Implicit GEMM can execute the given problem.
  CUTLASS_HOST_DEVICE
  static Status can_implement(Conv2dProblemSize const &problem_size) {

    // check alignment constraint on iterator's contiguous dimension
    if (problem_size.C % (128/sizeof_bits<Element>::value)) {
      return Status::kErrorInvalidProblem;
    }

    return Status::kSuccess;
  }

};
/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace threadblock
} // namespace conv
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////


