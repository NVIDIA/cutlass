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
    \brief Generic epilogue for implementing certain kinds of fused epilogue behavior with broadcast.
*/

#pragma once

/////////////////////////////////////////////////////////////////////////////////////////////////

#include "cutlass/cutlass.h"
#include "cutlass/fast_math.h"
#include "cutlass/matrix_coord.h"
#include "cutlass/semaphore.h"
#include "cutlass/epilogue/threadblock/epilogue_base.h"

////////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace epilogue {
namespace threadblock {


/// Epilogue operator
template <
  typename Visitor_,                        ///< Functor containing fused operations (satisfies EpilogueFusedVisitorConcept)
  typename Shape_,                          ///< Shape of threadblock tile (concept: GemmShape)
  typename WarpMmaOperator_,                ///< Warp-level MMA operator (concept: gemm::warp::MmaTensorOp)
  int PartitionsK,                          ///< Number of partitions of the K dimension
  typename AccumulatorFragmentIterator_,    ///< Fragment iterator selecting accumulators
  typename WarpTileIterator_,               ///< Warp-scoped tile iterator writing accumulators to SMEM
  typename SharedLoadIterator_,             ///< Threadblock-scoped tile iterator loading from SMEM
  typename Padding_,                        ///< Padding added to SMEM allocation to avoid bank conflicts (concept: MatrixShape)
  int FragmentsPerPartition = 1,            ///< Used to coarsten the epilogue granularity
  int IterationsUnroll =                    ///< Used to reduce binary size when epilogue op is large
    (true || !IsEpilogueFunctorHeavy<Visitor_>::value)
>
class EpilogueWithBroadcastAndVisitor :
  public EpilogueBase<
    Shape_,
    typename WarpMmaOperator_::Shape,
    PartitionsK,
    AccumulatorFragmentIterator_,
    WarpTileIterator_,
    Padding_,
    FragmentsPerPartition> {

public:

  using Visitor = Visitor_;

  using Base = EpilogueBase<
    Shape_,
    typename WarpMmaOperator_::Shape,
    PartitionsK,
    AccumulatorFragmentIterator_,
    WarpTileIterator_,
    Padding_,
    FragmentsPerPartition>;

  using Shape = Shape_;
  using WarpMmaOperator = WarpMmaOperator_;
  static int const kPartitionsK = PartitionsK;

  using AccumulatorFragmentIterator = AccumulatorFragmentIterator_;
  using WarpTileIterator = WarpTileIterator_;
  using SharedLoadIterator = SharedLoadIterator_;
  using Padding = Padding_;

  using Layout = layout::RowMajor;
  using LongIndex = typename Layout::LongIndex;

  /// The complete warp-level accumulator tile
  using AccumulatorTile = typename Base::AccumulatorTile;

  /// Accumulator element
  using ElementAccumulator = typename WarpTileIterator::Element;

  /// Output access size
  static int const kElementsPerAccess = Visitor::kElementsPerAccess;

  /// Tensor reference to sync tensor
  using SyncTensorRef = typename cutlass::TensorRef<int, cutlass::layout::PackedVectorLayout>;

  /// Array type used by output functor
  using AccumulatorAccessType = Array<
    typename WarpTileIterator::Element, kElementsPerAccess>;

  /// Number of warps
  using WarpCount = typename Base::WarpCount;

  static int constexpr kSmemTiles = Base::kFragmentsPerIteration > 1 ? Base::kFragmentsPerIteration : kPartitionsK;
  static int constexpr kSmemPointerOffset = Base::SharedStorage::StorageShape::kCount / kSmemTiles;

  using SharedStorage = typename Base::SharedStorage;

private:

  /// Loads fragment from shared memory aligned with output tensor
  SharedLoadIterator shared_load_iterator_;

public:

  /// Constructor
  CUTLASS_DEVICE
  EpilogueWithBroadcastAndVisitor(
    SharedStorage &shared_storage,    ///< Shared storage object
    int thread_idx,                   ///< ID of a thread within the threadblock
    int warp_idx,                     ///< ID of warp within threadblock
    int lane_idx                      ///< Id of thread within warp
  ):
    Base(shared_storage, thread_idx, warp_idx, lane_idx),
    shared_load_iterator_(shared_storage.reference(), thread_idx)
  {

  }

  /// Streams the result to global memory
  CUTLASS_DEVICE
  void operator()(
    Visitor & visitor,
    AccumulatorTile const &accumulators) {         ///< Threadblock tile coordinate in GEMM (in units of threadblock tiles)

    visitor.begin_epilogue();

    //
    // Iterator over warp-level accumulator fragment
    //

    AccumulatorFragmentIterator accum_fragment_iterator(accumulators);

    //
    // Iterate over accumulator tile
    //

    #pragma unroll(IterationsUnroll ? Visitor::kIterations : 1)
    for (int iter_idx = 0; iter_idx < Visitor::kIterations; ++iter_idx) {

      //
      // Load the source
      //

      visitor.begin_step(iter_idx);

      //
      // Convert and store fragment
      //

      __syncthreads();

      acc2smem_source_needed<cutlass::make_index_sequence<Visitor::kIterations>>::push(
          iter_idx, accum_fragment_iterator, this->warp_tile_iterator_);

      __syncthreads();

      //
      // Load fragments from shared memory
      //

      typename SharedLoadIterator::Fragment aligned_accum_fragment[kPartitionsK];

      shared_load_iterator_.load(aligned_accum_fragment[0]);

      // If the number of k-slices is > 1 - perform a reduction amongst the k-slices
      if (kPartitionsK > 1) {

        plus <typename SharedLoadIterator::Fragment> add_fragments;

        CUTLASS_PRAGMA_UNROLL
        for ( int i = 1; i < kPartitionsK; ++i) {
          shared_load_iterator_.add_pointer_offset(kSmemPointerOffset);
          shared_load_iterator_.load(aligned_accum_fragment[i]);
          aligned_accum_fragment[0] = add_fragments(aligned_accum_fragment[0], aligned_accum_fragment[i]);
        }

        shared_load_iterator_.add_pointer_offset((1 - kPartitionsK) * kSmemPointerOffset);
      }

      //
      // Iterate over output fragments
      //

      AccumulatorAccessType const *accum_frag_ptr =
        reinterpret_cast<AccumulatorAccessType const *>(&aligned_accum_fragment[0]);

      int const kAccumulatorFragmentCount = AccumulatorTile::kElements / (Visitor::kIterations * AccumulatorAccessType::kElements);

      CUTLASS_PRAGMA_UNROLL
      for (int idx = 0; idx < kAccumulatorFragmentCount; ++idx) {

        int row_idx = idx / SharedLoadIterator::ThreadMap::Iterations::kColumn;
        int col_idx = idx % SharedLoadIterator::ThreadMap::Iterations::kColumn;

        // Start a new row of the output fragment
        if (!col_idx) {
          visitor.begin_row(row_idx);
        }

        visitor.visit(
          iter_idx,
          row_idx,
          col_idx,
          idx,
          accum_frag_ptr[idx]
        );

        // End the row of the output fragment
        if (col_idx + 1 == SharedLoadIterator::ThreadMap::Iterations::kColumn) {
          visitor.end_row(row_idx);
        }
      }

      //
      // Conclude the step
      //

      visitor.end_step(iter_idx);
    }

    visitor.end_epilogue();
  }

private:


  template<class Seq>
  struct acc2smem_source_needed;

  template <size_t... Seq>
  struct acc2smem_source_needed<cutlass::index_sequence<Seq...>> {
    template<int Advance>
    CUTLASS_DEVICE
    static void helper(AccumulatorFragmentIterator accum_fragment_iterator,
                       WarpTileIterator &warp_tile_iterator) {
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < Advance; i++) {
        ++accum_fragment_iterator;
      }

      typename AccumulatorFragmentIterator::Fragment accum_fragment;
      accum_fragment_iterator.load(accum_fragment);
      warp_tile_iterator.store(accum_fragment);
    }

    CUTLASS_DEVICE
    static void push(size_t pos,
                     AccumulatorFragmentIterator const &iterator_begin,
                     WarpTileIterator &warp_tile_iterator) {
      int dummy[] = {(pos == Seq) && (helper<Seq>(iterator_begin, warp_tile_iterator), 0)...};
    }
  };
};

/////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to create an EpilogueWithBroadcastAndVisitor from an existing epilogue
template <typename Visitor_, typename Existing_, bool IterationsUnroll = true>
struct EpilogueWithBroadcastAndVisitorFromExistingEpilogue  {

  using Epilogue = EpilogueWithBroadcastAndVisitor<
    Visitor_,
    typename Existing_::Shape,
    typename Existing_::WarpMmaOperator,
    Existing_::kPartitionsK,
    typename Existing_::AccumulatorFragmentIterator,
    typename Existing_::WarpTileIterator,
    typename Existing_::SharedLoadIterator,
    typename Existing_::Padding,
    Existing_::kFragmentsPerIteration,
    IterationsUnroll
  >;
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace threadblock
} // namespace epilogue
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
