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
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*! \file
  \brief Epilogue for threadblock scoped GEMMs using Tensor Ops.

  The epilogue rearranges the result of a matrix product through shared memory to match canonical
  tensor layouts in global memory. Epilogues support conversion and reduction operations.

*/

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/numeric_types.h"
#include "cutlass/array.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/layout/tensor.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/tensor_ref.h"
#include "cutlass/transform/pitch_linear_thread_map.h"
#include "cutlass/epilogue/threadblock/output_tile_thread_map.h"
#include "cutlass/arch/arch.h"
#include "cutlass/arch/memory.h"
#include "cutlass/epilogue/threadblock/predicated_tile_iterator_params.h"
#include "cutlass/numeric_conversion.h"

#include "cutlass/matrix_coord.h"
////////////////////////////////////////////////////////////////////////////////

namespace cutlass {

////////////////////////////////////////////////////////////////////////////////

namespace epilogue {
namespace threadblock {

////////////////////////////////////////////////////////////////////////////////

/// Tile iterator used to load and store output tile from global memory in epilogue.
///
/// Satisfies: ReadableTileIterator | MyFusedPredicatedTileIterator | ForwardTileIterator
///
template <
  typename ThreadMap_,       ///< Thread map (conept: OutputTileThreadMap)
  typename Element_,         ///< Element data type
  bool UseCUDAStore = false
>
class MyFusedPredicatedTileIterator {
public:
  using ThreadMap = ThreadMap_;
  using Shape = typename ThreadMap::Shape;

  using Element = Element_;

  using Layout = layout::RowMajor;
  using TensorRef = TensorRef<Element, Layout>;
  using ConstTensorRef = typename TensorRef::ConstTensorRef;

  using Index = typename Layout::Index;
  using LongIndex = typename Layout::LongIndex;
  using TensorCoord = MatrixCoord;

  static int const kElementsPerAccess = ThreadMap::kElementsPerAccess;
  static int const kThreads = ThreadMap::kThreads;
  static int const kIterations = ThreadMap::Count::kTile;

  static_assert( ThreadMap::Iterations::kRow > 0,"ThreadMap::Iterations::kRow must be > 0");
  static_assert( ThreadMap::Iterations::kGroup > 0,"ThreadMap::Iterations::kGroup must be > 0");
  static_assert( ThreadMap::Iterations::kCluster > 0,"ThreadMap::Iterations::kCluster must be > 0");
  static_assert( ThreadMap::Iterations::kColumn > 0,"ThreadMap::Iterations::kColumn must be > 0");

  /// Fragment object
  using Fragment = Array<
    Element, 
    ThreadMap::Iterations::kColumn * 
    ThreadMap::Iterations::kRow * 
    ThreadMap::Iterations::kGroup * 
    ThreadMap::Iterations::kCluster * ThreadMap::kElementsPerAccess>;

  /// Memory access size
  using AccessType = AlignedArray<Element, ThreadMap::kElementsPerAccess>;
  using ScalarAccessType = AlignedArray<Element, 1>;

  //
  // Parameters struct
  //

  /// Uses a non-template class
  struct Params : PredicatedTileIteratorParams {
    using Base = PredicatedTileIteratorParams;

    CUTLASS_HOST_DEVICE
    Params() { }

    CUTLASS_HOST_DEVICE
    Params(Layout const &layout): 
      PredicatedTileIteratorParams(
        layout.stride(0) * int(sizeof(AccessType)) / kElementsPerAccess,
        make_OutputTileThreadMapDesc<ThreadMap>()
      ) 
    { }

    CUTLASS_HOST_DEVICE
    Params(Base const &base) : 
      Base(base) { }
  };

  /// Mask object
  struct Mask {

    static int const kCount = ThreadMap::Iterations::kColumn;

    /// Predicate state
    bool predicates[kCount];

    //
    // Mask
    //
    CUTLASS_HOST_DEVICE
    Mask() {
      enable();
    }

    ///< Efficiently disables all accesses guarded by mask
    CUTLASS_HOST_DEVICE void clear() {
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < kCount; ++i) {
        predicates[i] = false;
      }
    }

    ///< CUTLASS_HOST_DEVICE enables all accesses guarded by mask
    CUTLASS_DEVICE void enable() {
      CUTLASS_PRAGMA_UNROLL
      for (int i = 0; i < kCount; ++i) {
        predicates[i] = true;
      }
    }
  };

private:

  //
  // Data members
  //

  /// Parameters structure containing reference and precomputed state.
  PredicatedTileIteratorParams params_;

  /// Byte-level pointer
  uint8_t *byte_pointer_;

  /// Array of boolean values to contain steady-state predicates
  Mask mask_;

  /// Extent of the matrix tile in rows
  Index extent_row_;

  /// A thread's starting row position (assuming steady-state predicates have been computed)
  Index thread_start_row_;

  Index thread_start_col_;

  Element *mean_vec_;
  Element *mean_square_vec_;
  int dim_;
  /// Internal state counter
  int state_[3];
 
  //
  // Static asserts about internal strides
  //

  static_assert(sizeof(extent_row_) == 4, "Expected 32b extents");
  static_assert(sizeof(thread_start_row_) == 4, "Expected 32b extents");
  static_assert(sizeof(PredicatedTileIteratorParams::stride) == 8, "Expected 64b strides");

private:

  //
  // Methods
  //

public:

  //
  // Methods
  //

  /// Constructor
  CUTLASS_DEVICE
  MyFusedPredicatedTileIterator(
    PredicatedTileIteratorParams const & params,
    Element *pointer,
    TensorCoord extent,
    int thread_idx,
    Element *mean_vec,
    Element *mean_square_vec,
    int dim,
    TensorCoord threadblock_offset = TensorCoord()
  ): 
    params_(params)
  {

    TensorCoord thread_offset = ThreadMap::initial_offset(thread_idx) + threadblock_offset;

    extent_row_ = extent.row();
    thread_start_row_ = thread_offset.row();
    thread_start_col_ = thread_offset.column();

    // Initialize predicates
    CUTLASS_PRAGMA_UNROLL
    for (int c = 0; c < ThreadMap::Iterations::kColumn; ++c) {

      mask_.predicates[c] = ((thread_offset.column() 
        + ThreadMap::Delta::kColumn * c) < extent.column());
    }

    // Null pointer performs no accesses
    if (!pointer) {
      mask_.clear();
    }

    // Initialize pointers
    byte_pointer_ = reinterpret_cast<uint8_t *>(pointer) + 
      LongIndex(thread_offset.row()) * LongIndex(params_.stride) + 
      LongIndex(thread_offset.column()) * sizeof(AccessType) / kElementsPerAccess;

    mean_vec_ = mean_vec;// + thread_offset.row();
    mean_square_vec_ = mean_square_vec;// + thread_offset.row();
    dim_ = dim;
    // Initialize internal state counter
    state_[0] = state_[1] = state_[2] = 0;
  }

  /// Constructor without mean_vecs
  CUTLASS_DEVICE
  MyFusedPredicatedTileIterator(
    PredicatedTileIteratorParams const & params,
    Element *pointer,
    TensorCoord extent,
    int thread_idx,
    TensorCoord threadblock_offset = TensorCoord()
  ): 
    params_(params)
  {

    TensorCoord thread_offset = ThreadMap::initial_offset(thread_idx) + threadblock_offset;

    extent_row_ = extent.row();
    thread_start_row_ = thread_offset.row();
    thread_start_col_ = thread_offset.column();

    // Initialize predicates
    CUTLASS_PRAGMA_UNROLL
    for (int c = 0; c < ThreadMap::Iterations::kColumn; ++c) {

      mask_.predicates[c] = ((thread_offset.column() 
        + ThreadMap::Delta::kColumn * c) < extent.column());
    }

    // Null pointer performs no accesses
    if (!pointer) {
      mask_.clear();
    }

    // Initialize pointers
    byte_pointer_ = reinterpret_cast<uint8_t *>(pointer) + 
      LongIndex(thread_offset.row()) * LongIndex(params_.stride) + 
      LongIndex(thread_offset.column()) * sizeof(AccessType) / kElementsPerAccess;

    mean_vec_ = NULL;
    mean_square_vec_ = NULL;
    dim_ = 1;
    // Initialize internal state counter
    state_[0] = state_[1] = state_[2] = 0;
  }

  /// Adds a pointer offset in units of Element
  CUTLASS_HOST_DEVICE
  void add_pointer_offset(LongIndex pointer_offset) {
    byte_pointer_ += pointer_offset * sizeof_bits<Element>::value / 8;
  }

  /// Loads a fragment from memory
  CUTLASS_DEVICE
  void load_with_byte_offset(Fragment &frag, int64_t byte_offset) const {

    uint8_t *byte_pointer = byte_pointer_;
    AccessType *frag_ptr = reinterpret_cast<AccessType *>(&frag);

    CUTLASS_PRAGMA_UNROLL
    for (int cluster = 0; cluster < ThreadMap::Iterations::kCluster; ++cluster) {

      CUTLASS_PRAGMA_UNROLL
      for (int group = 0; group < ThreadMap::Iterations::kGroup; ++group) {

        CUTLASS_PRAGMA_UNROLL
        for (int row = 0; row < ThreadMap::Iterations::kRow; ++row) {

          int frag_row_idx = 
            (row + ThreadMap::Iterations::kRow * (group + ThreadMap::Iterations::kGroup * cluster));

          int row_offset = row * ThreadMap::Delta::kRow 
            + group * ThreadMap::Delta::kGroup 
            + cluster * ThreadMap::Delta::kCluster;

          bool row_guard = ((row_offset + thread_start_row_) < extent_row_);

          AccessType *memory_pointer = reinterpret_cast<AccessType *>(byte_pointer + byte_offset);

          CUTLASS_PRAGMA_UNROLL
          for (int column = 0; column < ThreadMap::Iterations::kColumn; ++column) {

            bool guard = row_guard && mask_.predicates[column];

            cutlass::arch::global_load<
              AccessType, 
              sizeof(AccessType)
            >(
                frag_ptr[frag_row_idx * ThreadMap::Iterations::kColumn +
                         column],
                (void *)&memory_pointer[column * ThreadMap::Delta::kColumn /
                                        kElementsPerAccess],
                guard);
          }

          if (row + 1 < ThreadMap::Iterations::kRow) {
            byte_pointer += params_.increment_row;
          }
        }

        if (group + 1 < ThreadMap::Iterations::kGroup) {
          byte_pointer += params_.increment_group;
        }
      }

      if (cluster + 1 < ThreadMap::Iterations::kCluster) {
        byte_pointer += params_.increment_cluster;
      }
    }
  }
  /// Loads a fragment from memory
  CUTLASS_DEVICE
  void load(Fragment &frag) const {
    load_with_byte_offset(frag, 0);
  }

  CUTLASS_DEVICE
  void in_thread_reduction(AccessType const &frag, float &reduction, float &reduction_square, float scalar) const {
    NumericArrayConverter<float, Element, ThreadMap::kElementsPerAccess> myconvertor;
    auto converted_frag = myconvertor(frag);
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < ThreadMap::kElementsPerAccess; i++) {
      float casted_data = converted_frag[i];
      auto tmp = casted_data * scalar;
      reduction += tmp;
      reduction_square += casted_data * tmp;
    }
  }

  /// Stores a fragment to memory
  CUTLASS_DEVICE
  void store_with_byte_offset(Fragment const &frag, int64_t byte_offset) const {
    uint8_t *byte_pointer = byte_pointer_;
    Element *mean_vec_ptr = mean_vec_;
    Element *mean_square_vec_ptr = mean_square_vec_;
    float scalar = 1./dim_;
    AccessType const *frag_ptr = reinterpret_cast<AccessType const *>(&frag);

    CUTLASS_PRAGMA_UNROLL
    for (int cluster = 0; cluster < ThreadMap::Iterations::kCluster; ++cluster) {

      CUTLASS_PRAGMA_UNROLL
      for (int group = 0; group < ThreadMap::Iterations::kGroup; ++group) {

        CUTLASS_PRAGMA_UNROLL
        for (int row = 0; row < ThreadMap::Iterations::kRow; ++row) {

          int frag_row_idx = 
            (row + ThreadMap::Iterations::kRow * (group + ThreadMap::Iterations::kGroup * cluster));

          int row_offset = row * ThreadMap::Delta::kRow 
            + group * ThreadMap::Delta::kGroup 
            + cluster * ThreadMap::Delta::kCluster;

          bool row_guard = ((row_offset + thread_start_row_) < extent_row_);

          AccessType *memory_pointer = reinterpret_cast<AccessType *>(byte_pointer + byte_offset);

          float reduction = 0., reduction_square = 0.;
          // Element reduction = Element(0);
          // Element reduction_square = Element(0);

          CUTLASS_PRAGMA_UNROLL
          for (int column = 0; column < ThreadMap::Iterations::kColumn; ++column) {

            bool guard = row_guard && mask_.predicates[column];
            auto fragPtr = frag_ptr[frag_row_idx * ThreadMap::Iterations::kColumn + column];
            if (guard) {
              in_thread_reduction(fragPtr, reduction, reduction_square, scalar);
            }

              cutlass::arch::global_store<AccessType, sizeof(AccessType)>(
                  fragPtr,
                  (void *)&memory_pointer[column * ThreadMap::Delta::kColumn / kElementsPerAccess],
                  guard);


#if (0)
              if (guard) {
                float t0 = static_cast<float>(frag_ptr[frag_row_idx * ThreadMap::Iterations::kColumn + column][0]);
                float t1 = static_cast<float>(frag_ptr[frag_row_idx * ThreadMap::Iterations::kColumn + column][1]);
                float t2 = static_cast<float>(frag_ptr[frag_row_idx * ThreadMap::Iterations::kColumn + column][2]);
                float t3 = static_cast<float>(frag_ptr[frag_row_idx * ThreadMap::Iterations::kColumn + column][3]);
                float t4 = static_cast<float>(frag_ptr[frag_row_idx * ThreadMap::Iterations::kColumn + column][4]);
                float t5 = static_cast<float>(frag_ptr[frag_row_idx * ThreadMap::Iterations::kColumn + column][5]);
                float t6 = static_cast<float>(frag_ptr[frag_row_idx * ThreadMap::Iterations::kColumn + column][6]);
                float t7 = static_cast<float>(frag_ptr[frag_row_idx * ThreadMap::Iterations::kColumn + column][7]);
                
                printf("tid = %3d, coord = {%3d,%3d}, offset = {%3d,%3d}, kColumn/Row = {%2d,%2d}, data = {%4.2f,%4.2f,%4.2f,%4.2f,%4.2f,%4.2f,%4.2f,%4.2f}, inc = %3d.\n",\
                 threadIdx.x, (int)thread_start_col_, (int)thread_start_row_, (int)(column * ThreadMap::Delta::kColumn), row_offset,\
                  ThreadMap::Iterations::kColumn, ThreadMap::Iterations::kRow,\
                  t0,t1,t2,t3,t4,t5,t6,t7, (int)(params_.increment_row));
              }
#endif

            }


          int tid = threadIdx.x;
          __syncwarp();
          float sum = reduction;
          float square_sum = reduction_square;
          for (int i = 8; i > 0; i >>= 1) {
            sum += __shfl_down_sync(0xFFFFFFFF, sum, i);
            square_sum += __shfl_down_sync(0xFFFFFFFF, square_sum, i);
          }

          tid = threadIdx.x;
          bool is_write_thread = row_guard && (tid % 16 == 0);

          cutlass::arch::global_store<Element, sizeof(Element)>(
              static_cast<Element>(sum),
              (void *)&mean_vec_ptr[row_offset + thread_start_row_],
              is_write_thread);

          cutlass::arch::global_store<Element, sizeof(Element)>(
              static_cast<Element>(square_sum),
              (void *)&mean_square_vec_ptr[row_offset + thread_start_row_],
              is_write_thread);
#if (0)
          if (is_write_thread){
            printf("tid = %3d, ind = {%3d}, threadred = %4.3f, sum = %4.3f, square_sum = %4.3f.\n", \
            threadIdx.x, (int)(row_offset + thread_start_row_),\
            static_cast<float>(reduction), static_cast<float>(sum), static_cast<float>(square_sum));
          }

#endif
          if (row + 1 < ThreadMap::Iterations::kRow) {
            byte_pointer += params_.increment_row;
          }

        }

        if (group + 1 < ThreadMap::Iterations::kGroup) {
          byte_pointer += params_.increment_group;
        }
      }

      if (cluster + 1 < ThreadMap::Iterations::kCluster) {
        byte_pointer += params_.increment_cluster;
      }
    }
  }


  /// Stores a fragment to memory
  CUTLASS_DEVICE
  void store(Fragment const &frag) const {

    store_with_byte_offset(frag, 0);
  }

  /// Need to get the thread start row from the tile iterator
  CUTLASS_DEVICE
  int32_t thread_start_row() const {
    return thread_start_row_;
  }

  /// Extent of the matrix in rows
  CUTLASS_DEVICE
  Index extent_row() const {
    return extent_row_;
  }

  /// Advances to the next position to load or store
  CUTLASS_HOST_DEVICE
  MyFusedPredicatedTileIterator &operator++() {

    ++state_[0];
    byte_pointer_ += params_.advance_row;
    thread_start_row_ += ThreadMap::Shape::kRow;
    
    if (state_[0] == ThreadMap::Count::kRow) {

      state_[0] = 0;
      ++state_[1];
      byte_pointer_ += params_.advance_group;

      thread_start_row_ += (ThreadMap::Shape::kGroup - 1) * 
        ThreadMap::Shape::kRow * ThreadMap::Count::kRow;

      if (state_[1] == ThreadMap::Count::kGroup) {

        state_[1] = 0;
        ++state_[2];
        byte_pointer_ += params_.advance_cluster;

        thread_start_row_ += ThreadMap::Count::kGroup * 
          ThreadMap::Shape::kGroup * ThreadMap::Count::kRow * ThreadMap::Shape::kRow;

        if (state_[2] == ThreadMap::Count::kCluster) {
          state_[2] = 0;
          byte_pointer_ += params_.advance_tile;
        }
      }
    }

    return *this;
  }

  ///< Efficiently disables all accesses guarded by mask
  CUTLASS_DEVICE void clear_mask() {
    mask_.clear();
  }

  ///< Efficiently enables all accesses guarded by mask
  CUTLASS_DEVICE void enable_mask() {
    mask_.enable();
  }

  ///< Sets the mask
  CUTLASS_DEVICE void get_mask(Mask &mask) const {
    mask = mask_;
  }

  ///< Sets the mask
  CUTLASS_DEVICE void set_mask(Mask const &mask) {
    mask_ = mask;
  }
};

////////////////////////////////////////////////////////////////////////////////

/// Tile iterator used to load output tile from global memory in epilogue.
///
/// Satisfies: ReadableTileIterator | InterleavedPredicatedTileIterator | ForwardTileIterator
///

///////////////////////////////////////////////////////////////////////////////


///////////////////////////////////////////////////////////////////////////////

} // namespace threadblock
} // namespace epilogue
} // namespace cutlass

////////////////////////////////////////////////////////////////////////////////
