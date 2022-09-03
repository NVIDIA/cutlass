/***************************************************************************************************
 * Copyright (c) 2017 - 2022 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
/*! \file
    \brief Describes the lane policy used by warp-level matrix multiply operators targeting SIMT
      instructions
*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/array.h"
#include "cutlass/tensor_ref.h"
#include "cutlass/matrix_shape.h"

#include "cutlass/arch/memory_sm75.h"

#include "cutlass/layout/matrix.h"

#include "cutlass/gemm/gemm.h"
#include "cutlass/gemm/warp/mma_simt_policy.h"
#include "cutlass/gemm/warp/mma_simt_tile_iterator.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace conv {
namespace warp {

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Iterates over operands to warp-level matrix multiply operations targeting SIMT instructions
///
/// concept: MutableRandomAccessContiguousTileIteratorConcept
///
template <
  /// Size of the matrix to load (concept: MatrixShape)
  typename Shape_,
  /// Operand identity
  cutlass::gemm::Operand Operand,
  /// Data type of A elements
  typename Element_,
  /// Layout of operand
  typename Layout_,
  /// Shape of the warp in units of thread (concept: MmaSimtPolicy)
  typename Policy_,
  /// Number of partitions along K dimension - used in sliced-K
  int PartitionsK = 1,
  /// Group Size along kPartition - used in sliced-K
  int PartitionGroupSize = 1
>
class DepthwiseMmaSimtTileIterator;

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Specialization for B operands of row-major layouts
///
/// Concept: MutableRandomAccessContiguousTileIteratorConcept
///
template <
    /// Size of the matrix to load (concept: MatrixShape)
    typename Shape_,
    /// Data type of A elements
    typename Element_,
    /// Shape of the warp in units of thread (concept: MmaSimtPolicy)
    typename Policy_,
    /// Number of partitions along K dimension
    int PartitionsK,
    /// Group Size along kPartition - used in sliced-K
    int PartitionGroupSize>
class DepthwiseMmaSimtTileIterator<Shape_,
                                   cutlass::gemm::Operand::kB,
                                   Element_,
                                   layout::RowMajor,
                                   Policy_,
                                   PartitionsK,
                                   PartitionGroupSize>
    : public cutlass::gemm::warp::MmaSimtTileIterator<Shape_,
                                               cutlass::gemm::Operand::kB,
                                               Element_,
                                               layout::RowMajor,
                                               Policy_,
                                               PartitionsK,
                                               PartitionGroupSize> {

  using Base = cutlass::gemm::warp::MmaSimtTileIterator<Shape_,
                                               cutlass::gemm::Operand::kB,
                                               Element_,
                                               layout::RowMajor,
                                               Policy_,
                                               PartitionsK,
                                               PartitionGroupSize>;
 public:
  /// Shape of tile to load (concept: MatrixShape)
  using Shape = Shape_;

  /// Operand tag
  static cutlass::gemm::Operand const kOperand = cutlass::gemm::Operand::kB;

  /// Element type
  using Element = Element_;

  /// Layout of policy
  using Layout = layout::RowMajor;

  /// Decomposition of elements among threads
  using Policy = Policy_;

  /// TensorRef type for loading element from a tensor
  using TensorRef = typename Base::TensorRef;

  /// Index type
  using Index = typename TensorRef::Index;

  /// Long Index type
  using LongIndex = typename TensorRef::LongIndex;

  /// Coordinate for an element in the tensor
  using TensorCoord = typename TensorRef::TensorCoord;

  /// Thread-level shape of a fragment
  using ThreadShape = typename Base::ThreadShape;

  /// Number of individual loads
  using Iterations =  typename Base::Iterations;

  /// Fragment object holding a thread's part of a tile
  using Fragment = typename Base::Fragment;

  static_assert(Policy::LaneMmaShape::kN == 1, "Each thread should be 1 element per LDS along the k-dim");
  
private:

  MatrixCoord lane_offset_;
  int channel_idx_;
  int base_channel_idx_;
  int warps_n_;

 public:
  
  /// Default ctor constructs null iterator
  CUTLASS_HOST_DEVICE
  DepthwiseMmaSimtTileIterator():Base() { }

  /// Constructor from TensorRef
  CUTLASS_HOST_DEVICE
  DepthwiseMmaSimtTileIterator(
    TensorRef ref, 
    int lane_id
  ) : Base(ref, lane_id) {

    // compute offset based on thread ID and lane layout
    typename Policy::LaneLayout lane_layout = Policy::get_lane_layout();

    warps_n_ = -1;
    channel_idx_ = 0;
    base_channel_idx_ = 0;
    lane_offset_ = lane_layout.inverse(lane_id) * MatrixCoord(0, Policy::LaneMmaShape::kN);
  }
  
  /// Advances an iterator along logical dimensions of matrix in units of whole tiles
  CUTLASS_HOST_DEVICE
  DepthwiseMmaSimtTileIterator &add_tile_offset(TensorCoord const &coord) {

    if(warps_n_ == -1){
        warps_n_ = coord.column();
    }
    
    Base::add_tile_offset(coord);
    return *this;
  }

  /// Loads a fragment from memory at the location pointed to by the iterator. (vector loads)
  CUTLASS_HOST_DEVICE
  void load_with_pointer_offset(Fragment &frag, Index pointer_offset) const {
    Array<Element, Policy::LaneMmaShape::kN> *dst_ptr =
        reinterpret_cast<Array<Element, Policy::LaneMmaShape::kN> *>(&frag);

    CUTLASS_PRAGMA_UNROLL
    for (int k = 0; k < Iterations::kRow; ++k) {
      CUTLASS_PRAGMA_UNROLL
      for (int n = 0; n < Iterations::kColumn; ++n) {

        void const *ptr = this->ref_.data() +
                          this->ref_.offset({-(channel_idx_ - base_channel_idx_),
                                             n * Policy::WarpShape::kColumn}) +
                          pointer_offset / Policy::LaneMmaShape::kN;

        // Base_k of a warp +  Base_k of current threads.
        int thread_k_base_idx =
            warps_n_ * Shape::kColumn / Policy::LaneMmaShape::kN + lane_offset_.column();

        if (channel_idx_ + k == thread_k_base_idx + n * Policy::WarpShape::kColumn) {
          // Depthwise kernel would only do computation when channel == k.
          // Loads an element when the current computation channel == the k corresponding to this thread.
          arch::shared_load(dst_ptr[n + k * Iterations::kColumn], ptr);
        } else {
          // Reduce SMEM load
          dst_ptr[n + k * Iterations::kColumn].fill(Element(0));
        }
      }
    }
  }

  /// Loads a fragment from memory at the location pointed to by the iterator.
  CUTLASS_HOST_DEVICE
  void load(Fragment &frag) const {
    load_with_pointer_offset(frag, 0);
  }
  
  /// Notify the iterator which k-group it is currently pointing to.
  ///
  /// This does not advance the iterator. Rather, it overrides its internal
  /// tracking with constant-valued k-group index
  CUTLASS_DEVICE
  void set_kgroup_index(int k_group) {
    if(k_group % PartitionGroupSize == 0 && k_group != 0){
      base_channel_idx_ = k_group;
    }
    channel_idx_ = k_group;
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace warp
} // namespace gemm
} // namespace cutlass
