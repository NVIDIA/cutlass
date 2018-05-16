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
    \brief Defines iterators for efficiently loading and storing to global memory.
*/
#pragma once

#include <cutlass/coord.h>
#include <cutlass/util/platform.h>

#include <cutlass/gemm/gemm_operand.h>
#include <cutlass/matrix_traits.h>
#include <cutlass/predicate_vector.h>
#include <cutlass/reshape_tile.h>
#include <cutlass/tile_iterator.h>

namespace cutlass {
namespace gemm {

////////////////////////////////////////////////////////////////////////////////////////////////////

// The following functor reshapes a tile of threads to match a tile of data. The idea is that when
// the user wants to build the iterator traits, he/she may want to specify the tile independently
// from the number of scalars loaded/stored per instruction. For example, in the row-major version
// with a tile of size 128x8 - the user may want to that the iterator works with 32x8 threads if
// each thread loads 1 scalar per LDG. If the user changes to 4 scalars per LDG, then the tile of
// threads has to change. The code below detects that and correct the code automatically - it is
// a helper when the user does not specify the right configuration.

template <typename Tile_, typename Threads_, bool = (Tile_::kW < Threads_::kW)>
struct ReshapeThreads {
  typedef Threads_ Threads;
};

template <typename Tile_, typename Threads_>
struct ReshapeThreads<Tile_, Threads_, true> {
  typedef Shape<Threads_::kD, Threads_::kH * Threads_::kW / Tile_::kW, Tile_::kW, 1> Threads;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <GemmOperand::Kind kOperand_,
          MatrixLayout::Kind kLayout_,
          typename Scalar_,
          typename Tile_,
          typename Threads_,
          int kAccessSize_>
struct GemmGlobalTileTraits {
  /// Identity of the operand
  static GemmOperand::Kind const kOperand = kOperand_;
  /// The layout.
  static MatrixLayout::Kind const kLayout = kLayout_;
  /// The scalar.
  typedef typename platform::remove_const<Scalar_>::type Scalar;
  /// The pointer.
  typedef Scalar_* Pointer;
  /// The number of scalars per LDG/STG.
  static int const kAccessSize = kAccessSize_;
  /// The memory space.
  static MemorySpace::Kind const kMemorySpace = MemorySpace::kGlobal;

  /// The tile shape
  typedef typename ReshapeTile<Tile_, kAccessSize_>::Tile Tile;
  /// The threads shape
  typedef typename ReshapeThreads<Tile, Threads_>::Threads Threads;
  /// The relative offset between two elements in the H/W dimension in adjacent threads.
  typedef Shape<1, 1, Tile::kC> ThreadsDelta;

  /// The strides in each dimension between different loads/stores.
  typedef Shape<0, Threads::kH, Threads::kW * kAccessSize> Delta;
  /// Strides for immediate offset computation
  typedef Shape<0, 0, Threads::kW * ThreadsDelta::kW, kAccessSize> ImmediateOffsetStrides;
  /// The number of iterations needed to load/store the tile.
  typedef Shape<1, Tile::kH / Threads::kH, Tile::kW / Threads::kW, Tile::kC / kAccessSize>
      Iterations;

  typedef GemmMultiplicandTraits<Tile, kOperand, kLayout> MultiplicandTraits;

  /// Computes the thread offset in (H, W) based on thread ID
  struct ThreadOffset {
    CUTLASS_HOST_DEVICE
    Coord<4> operator()() const {
      int thread_offset_h = threadIdx.x / Threads::kW * ThreadsDelta::kH;
      int thread_offset_w = threadIdx.x % Threads::kW * ThreadsDelta::kW;

      return make_Coord(0, thread_offset_h, thread_offset_w, 0);
    }
  };
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename Scalar_, typename Tile_, typename Threads_, int kStrideH_, int kAccessSize_>
struct GemmGlobalTileCdTraits : public GemmGlobalTileTraits<GemmOperand::kC,
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

  /// The stride in the H dimension.
  static int const kStrideH = kStrideH_;
  /// Override the strides in each dimension between different loads/stores.
  typedef Shape<0, 0, Base::Delta::kW, Base::Delta::kC> Delta;

  typedef typename Base::Iterations Iterations;

  typedef typename Base::Threads Threads;

  typedef typename Base::ThreadsDelta ThreadsDelta;

  typedef typename Base::ImmediateOffsetStrides ImmediateOffsetStrides;

  /// Computes the thread offset in (H, W) based on thread ID
  struct ThreadOffset {
    CUTLASS_HOST_DEVICE
    Coord<4> operator()() const {
      int thread_offset_h = threadIdx.x / Threads::kW * kStrideH * Iterations::kH;
      int thread_offset_w = threadIdx.x % Threads::kW * ThreadsDelta::kW;

      return make_Coord(0, thread_offset_h, thread_offset_w, 0);
    }
  };
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename TileTraits_, typename Index_ = int>
struct GemmGlobalIteratorAb
    : public TileLoadIterator<TileTraits_,
                              typename TileTraits_::Scalar,
                              TileTraits_::MultiplicandTraits::kKstrided ? IteratorAdvance::kH
                                                                         : IteratorAdvance::kW,
                              MemorySpace::kGlobal,
                              Index_> {
  /// This class.
  typedef GemmGlobalIteratorAb<TileTraits_, Index_> This_;  /// The base class.

  typedef TileLoadIterator<TileTraits_,
                           typename TileTraits_::Scalar,
                           TileTraits_::MultiplicandTraits::kKstrided ? IteratorAdvance::kH
                                                                      : IteratorAdvance::kW,
                           MemorySpace::kGlobal,
                           Index_>
      Base;
  /// The layout.
  static MatrixLayout::Kind const kLayout = TileTraits_::kLayout;
  /// Fragment type loaded by the iterator
  typedef typename Base::Fragment Fragment;
  /// The scalar.
  typedef typename TileTraits_::Scalar Scalar;
  /// The threads.
  typedef typename TileTraits_::Threads Threads;
  /// The index.
  typedef Index_ Index;
  /// The thread offset
  typedef typename TileTraits_::ThreadOffset ThreadOffset;
  /// Specifies in which dimension post-increment accesses advance.
  static IteratorAdvance::Kind const kAdvance = Base::kAdvance;

  typedef cutlass::PredicateVector<ShapeCount<typename Base::Iterations>::kCount> PredicateVector;

  /// Iterator parameters type
  typedef typename Base::Params BaseParams;

  struct Params : public BaseParams {
    /// Initializes params to load a strip-mined tile, given pointer and stride_h.
    CUTLASS_HOST_DEVICE int initialize(Scalar const* ptr, Index stride_h) {
      Index inc_d = 0;
      Index inc_advance = 0;
      // Move by some columns for each iteration in the H dimension.
      Index inc_h = Base::Delta::kH * stride_h;

      // Move by some more columns in the number of iterations if the D dimension is > 1.
      if (Base::Delta::kD > 0) {
        inc_d = Base::Delta::kD * stride_h - (Base::Iterations::kH - 1) * inc_h;
      }

      // Move to the beginning of the next iteration.
      if (kAdvance == IteratorAdvance::kH && Base::Delta::kD > 0) {
        inc_advance = inc_d;
      } else if (kAdvance == IteratorAdvance::kH) {
        inc_advance = inc_h;
      } else if (Base::Delta::kD > 0) {
        inc_advance = (Base::Iterations::kW + 0) * ShapeCount<typename Base::Delta>::kWc -
                      (Base::Iterations::kH - 1) * inc_h -
                      (Base::Iterations::kD - 1) * Base::Delta::kD * stride_h;
      } else {
        inc_advance = (Base::Iterations::kW + 0) * ShapeCount<typename Base::Delta>::kWc -
                      (Base::Iterations::kH - 1) * inc_h;
      }

      Base::Params::initialize(ptr, 0, stride_h, 0, inc_d, inc_h, 0, inc_advance);
      return 0;
    }
  };

  /// Offset of an individual lane from the start of the tile
  Coord<4> thread_offset;
  /// The parameters
  Params params;

  CUTLASS_DEVICE void initialize_predicates(const Coord<3>& bounds, const Coord<3>& block) {
    // Setup the masks to control loads.
    predicates.fill(0);

    int bounds_h, bounds_w;
    if (kAdvance == IteratorAdvance::kH) {
      bounds_w = bounds[2] - block[2];
      bounds_h = bounds[1];

    } else {
      bounds_w = bounds[1];
      bounds_h = bounds[2] - block[1];
    }

    // Fill in the bits of the predicate vector.
    for (int d = 0; d < Base::Iterations::kD; ++d) {
      for (int h = 0; h < Base::Iterations::kH; ++h) {
        for (int w = 0; w < Base::Iterations::kW; ++w) {
          for (int c = 0; c < Base::Iterations::kC; ++c) {
            bool flag = w * Base::Delta::kW < bounds_w;
            if (kAdvance == IteratorAdvance::kH) {
              flag = flag && (h * Base::Delta::kH + d * Base::Delta::kD) < bounds_h;
            } else {
              flag = flag && (h * Base::Delta::kH) < bounds_h;
            }
            int const bit = ComputeOffsetFromShape<typename Base::Iterations>::get(d, h, w, c);
            predicates.set(bit, flag);
          }
        }
      }
    }
  }

  /// Ctor.
  CUTLASS_DEVICE GemmGlobalIteratorAb(Params const& _params,
                                      const Coord<3>& bounds,
                                      const Coord<3>& block,
                                      ThreadOffset thread_offset_func = ThreadOffset())
      : params(_params) {
    thread_offset = thread_offset_func();
    // The column.
    Index block_h = thread_offset[1];
    // The contiguous dimension.
    Index block_w = thread_offset[2];

    // Add the blocks indices.
    if (kAdvance == IteratorAdvance::kH) {
      block_h += block[1];
      block_w += block[2];

    } else {
      block_h += block[2];
      block_w += block[1];
    }

    // Setup the pointer.
    params.pointer += (block_h * params.stride_h + block_w);

    // Initialize predicates
    initialize_predicates(bounds, make_Coord(0, block_h, block_w));
  }

  /// Increment the pointer in the H dimension.
  CUTLASS_DEVICE void inc_h() { params.pointer += params.inc_h; }
  /// Increment the pointer in the D dimension.
  CUTLASS_DEVICE void inc_d() { params.pointer += params.inc_d; }
  /// Increment the pointer to move to the next iteration.
  CUTLASS_DEVICE void inc_advance() { params.pointer += params.inc_advance; }

  /// Returns the current pointer
  CUTLASS_HOST_DEVICE
  Scalar const* data() const { return params.pointer; }

  /// That's the residue! Update the predicates.
  CUTLASS_DEVICE void residue(Index k) {
    // The coordinates of the thread.
    Index block_h = thread_offset[1];
    // The contiguous dimension.
    Index block_w = thread_offset[2];

    // Update the predicate vector.
    for (int d = 0; d < Base::Iterations::kD; ++d) {
      for (int h = 0; h < Base::Iterations::kH; ++h) {
        for (int w = 0; w < Base::Iterations::kW; ++w) {
          for (int c = 0; c < Base::Iterations::kC; ++c) {
            Index offset = 0;
            if (kAdvance == IteratorAdvance::kH) {
              offset += block_h + h * Base::Delta::kH + d * Base::Delta::kD;
            } else {
              offset += block_w + w * Base::Delta::kW;
            }

            int const bit = ComputeOffsetFromShape<typename Base::Iterations>::get(d, h, w, c);
            if (offset >= k) {
              predicates.set(bit, false);
            }
          }
        }
      }
    }
  }

  /// Is the iterator valid?
  CUTLASS_DEVICE bool valid(int d, int h, int w, int c) const {
    int const bit = ComputeOffsetFromShape<typename Base::Iterations>::get(d, h, w, c);
    return predicates[bit];
  }

  /// The predicates.
  PredicateVector predicates;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <typename TileTraits_, typename Index_ = int>
struct GemmGlobalIteratorCd : public TileIteratorBase<TileTraits_,
                                                      typename TileTraits_::Scalar,
                                                      IteratorAdvance::kH,
                                                      MemorySpace::kGlobal,
                                                      Index_> {
  /// This class.
  typedef GemmGlobalIteratorCd<TileTraits_, Index_> This_;
  /// The base class.
  typedef TileIteratorBase<TileTraits_,
                           typename TileTraits_::Scalar,
                           IteratorAdvance::kH,
                           MemorySpace::kGlobal,
                           Index_>
      Base;

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
  /// The thread offset
  typedef typename TileTraits_::ThreadOffset ThreadOffset;

  /// The params.
  struct Params {
    /// The pointer.
    Pointer pointer;
    /// The stride in the H dimension to setup the thread in the block.
    Index stride_h;
    /// The strides to increment the pointer.
    Index inc_advance, inc_h;
    /// The strides to increment the predicate offset
    Index predicate_inc_advance, predicate_inc_h;
    /// The column offset to compute the predicate for the columns.
    Index predicate_offset;

    /// Setup the params.
    CUTLASS_HOST_DEVICE int initialize(
        Pointer pointer, Index ld, Index bound, Index epilogue_stride_w, Index epilogue_delta_w) {
      // The pointer.
      this->pointer = pointer;
      // Each column of the matrix.
      stride_h = TileTraits_::ThreadsDelta::kH * ld;
      // Each thread output 1 column per iteration. The stride between columns is given by the
      // number of scalars that are loaded per LDS for B.
      inc_h = ld * TileTraits_::kStrideH;
      inc_advance =
          (ld - ld * TileTraits_::kStrideH * (Base::Iterations::kH - 1)) + epilogue_stride_w;

      predicate_offset = bound;
      predicate_inc_h = TileTraits_::kStrideH;
      predicate_inc_advance =
          -((TileTraits_::kStrideH * (Base::Iterations::kH - 1) - 1) + epilogue_delta_w);

      return 0;
    }
  };

  Params params;
  /// Offset of an individual lane from the start of the tile
  Coord<4> thread_offset;

  /// Ctor.
  CUTLASS_DEVICE GemmGlobalIteratorCd() {}

  /// Ctor.
  CUTLASS_DEVICE GemmGlobalIteratorCd(Params const& params,
                                      const Coord<3>& bounds,
                                      const Coord<3>& block,
                                      int offset = 0,
                                      int pred_offset = 0,
                                      ThreadOffset thread_offset_func = ThreadOffset())
      : params(params) {
    thread_offset = thread_offset_func();
    // Each warp works on a different column of the tile.
    int const h = thread_offset[1] + block[1];
    // Each lane writes a different element.
    int const w = thread_offset[2] + block[2];
    // Setup the pointer.
    this->params.pointer += ((h * params.stride_h + w) + offset);

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
    this->params.predicate_offset -= params.predicate_inc_advance;
  }

  /// Test the validity of the iterator.
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
