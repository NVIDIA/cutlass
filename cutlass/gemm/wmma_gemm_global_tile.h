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
    \brief Defines tile iterator traits for loading thread block-level tile from global memory.
*/
#pragma once

#include <cutlass/gemm/gemm_global_tile.h>

namespace cutlass {
namespace gemm {

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Scalar_, typename Tile_, typename Threads_, int kAccessSize_>
struct WmmaGemmGlobalIteratorCdTraits : public GemmGlobalTileTraits<GemmOperand::kC,
                                                                    MatrixLayout::kColumnMajor,
                                                                    Scalar_,
                                                                    Tile_,
                                                                    Threads_,
                                                                    kAccessSize_> {
  /// The base class.
  typedef GemmGlobalTileTraits<GemmOperand::kC,
                               MatrixLayout::kColumnMajor,
                               Scalar_,
                               Tile_,
                               Threads_,
                               kAccessSize_>
      Base;

  /// Override the strides in each dimension between different loads/stores.
  typedef Shape<0, 0, Base::Delta::kW, Base::Delta::kC> Delta;

  /// Computes the thread offset in (H, W) based on thread ID
  struct ThreadOffset {
    CUTLASS_HOST_DEVICE
    Coord<4> operator()() const {
      int thread_offset_h = threadIdx.x / Base::Threads::kW;
      int thread_offset_w = threadIdx.x % Base::Threads::kW * Base::ThreadsDelta::kW;

      return make_Coord(0, thread_offset_h, thread_offset_w, 0);
    }
  };
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename TileTraits_, typename Index_ = int>
struct WmmaGemmGlobalIteratorCd : public TileIteratorBase<TileTraits_,
                                                          typename TileTraits_::Scalar,
                                                          IteratorAdvance::kH,
                                                          MemorySpace::kGlobal,
                                                          Index_> {
  /// This class.
  typedef WmmaGemmGlobalIteratorCd<TileTraits_, Index_> This_;
  /// The traits.
  typedef TileTraits_ Traits;
  /// The base class.
  typedef TileIteratorBase<Traits,
                           typename TileTraits_::Scalar,
                           IteratorAdvance::kH,
                           MemorySpace::kGlobal,
                           Index_>
      Base;
  /// Override the strides in each dimension between different loads/stores.
  typedef Shape<0, 0, Base::Delta::kW, Base::Delta::kC> ImmediateOffsetStrides;
  /// The layout.
  static MatrixLayout::Kind const kLayout = TileTraits_::kLayout;

  /// The scalar.
  typedef typename TileTraits_::Scalar Scalar;
  /// The pointer.
  typedef typename TileTraits_::Pointer Pointer;
  /// The threads.
  typedef typename TileTraits_::Threads Threads;
  /// The index.
  typedef Index_ Index;
  /// The thread offset functor.
  typedef typename TileTraits_::ThreadOffset ThreadOffset;

  /// The params.
  struct Params {
    /// The pointer.
    Pointer pointer;
    /// The stride in the H dimension to setup the thread in the block.
    Index stride_h;
    /// The strides to increment the pointer.
    Index inc_h, inc_advance;
    /// The column offset to compute the predicate for the columns.
    Index predicate_offset;
    /// The strides to increment the predicate offset.
    Index predicate_inc_h, predicate_inc_advance;

    /// Setup the params.
    CUTLASS_HOST_DEVICE int initialize(
        Pointer pointer, Index ld, Index n, Index epilogue_stride_w, Index epilogue_delta_w) {
      // The pointer.
      this->pointer = pointer;
      // Setup the base stride. One "group of threads" per column.
      stride_h = ld;
      // Each thread output 1 column per iteration. .
      inc_h = ld * TileTraits_::Threads::kH;
      inc_advance = inc_h + epilogue_stride_w;

      predicate_offset = n;
      predicate_inc_h = TileTraits_::Threads::kH;
      predicate_inc_advance = predicate_inc_h + epilogue_delta_w;

      // It worked.
      return 0;
    }
  };

  Params params;

  Coord<4> thread_offset;

  /// Ctor.
  CUTLASS_DEVICE WmmaGemmGlobalIteratorCd() {}

  /// Ctor.
  CUTLASS_DEVICE WmmaGemmGlobalIteratorCd(Params const& params,
                                          const Coord<3>& bounds,
                                          const Coord<3>& block,
                                          int const pointer_offset = 0,
                                          int const pred_offset = 0,
                                          ThreadOffset thread_offset_func = ThreadOffset())

      : params(params) {
    thread_offset = thread_offset_func();
    // Each warp works on a different column of the tile.
    int const h = thread_offset[1] + block[1];
    // Each lane writes a different element.
    int const w = thread_offset[2] + block[2];
    // Setup the pointer.
    this->params.pointer += ((h * params.stride_h + w) + pointer_offset);

    // Prepare the vector of predicates.
    for (int i = 0; i < Base::Iterations::kW; ++i) {
      predicates.set(i, w + i * Base::Delta::kW < bounds[2]);
    }
    this->params.predicate_offset -= (h + pred_offset);
  }

  /// Increment the pointer in the C dimension.
  CUTLASS_DEVICE void inc_c() {}
  /// Increment the pointer in the W dimension.
  CUTLASS_DEVICE void inc_w() {}
  /// Increment the pointer in the H dimension.
  CUTLASS_DEVICE void inc_h() {
    params.pointer += params.inc_h;
    params.predicate_offset -= params.predicate_inc_h;
  }
  /// Increment the pointer in the D dimension.
  CUTLASS_DEVICE void inc_d() {}
  /// Increment the pointer to move to the next iteration.
  CUTLASS_DEVICE void inc_advance() {
    params.pointer += params.inc_advance;
    params.predicate_offset -= params.predicate_inc_advance;
  }

  /// Test the predicate.
  CUTLASS_DEVICE bool valid(int d, int h, int w, int c) const {
    return predicates.at(w) && params.predicate_offset > 0;
  }

  /// Returns the raw pointer
  CUTLASS_HOST_DEVICE
  Pointer data() { return params.pointer; }

  CUTLASS_HOST_DEVICE
  Pointer const data() const { return params.pointer; }

  /// The predicates for the row.
  cutlass::PredicateVector<Base::Iterations::kW> predicates;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace gemm
}  // namespace cutlass
