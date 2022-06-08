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
 * FOR ANY DIRECT,INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,      
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;    
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,      
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE     
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE. 
 *
 **************************************************************************************************/
/*! \file
    \brief Templates calculating the address and predicates to the load of tiles
    from pitch-linear rank=2 tensors.

    This iterator uses masks to guard out-of-bounds accesses. The first tile this
    iterator visits maybe partial, then the remaining tiles are complete. So, we 
    only need to compute the predicates twice, once before the first tile and 
    once for the remaining full tiles which can share the same predicates.

    A precomputed "Params" object minimizes the amount of state that must be
    stored in registers, and integer addition is used to advance the pointer
    through memory.
*/

#pragma once

#include "cutlass/array.h"
#include "cutlass/coord.h"
#include "cutlass/cutlass.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/layout/pitch_linear.h"
#include "cutlass/matrix_shape.h"
#include "cutlass/predicate_vector.h"
#include "cutlass/tensor_ref.h"
#include "cutlass/tensor_view.h"
#include "customized_tile_access_iterator_params.h"

////////////////////////////////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace transform {
namespace threadblock {

////////////////////////////////////////////////////////////////////////////////

/// MyPredicatedTileAccessIteratorPredicates
///
template <typename Shape_, typename Element_, typename Layout_, int AdvanceRank,
          typename ThreadMap_, typename AccessType_>
class MyPredicatedTileAccessIteratorPredicates {
 public:
  using Shape = Shape_;
  using Element = Element_;
  using Layout = Layout_;
  static int const kAdvanceRank = AdvanceRank;
  using ThreadMap = ThreadMap_;
  using AccessType = AccessType_;

  using Index = typename Layout::Index;
  using LongIndex = typename Layout::LongIndex;

  using TensorCoord = typename Layout::TensorCoord;

  static int const kAccessesPerVector = ThreadMap::kElementsPerAccess / AccessType::kElements;

  static_assert(!(ThreadMap::kElementsPerAccess % AccessType::kElements),
    "Vectors implied by the thread map must be divisible by the access type.");

  static int const kPredicatesPerByte = 4;
  static int const kPredicatesPerWord = 4 * kPredicatesPerByte;

  static int const kPredicateCount = ThreadMap::Iterations::kCount * kAccessesPerVector;

  /// Number of 32b words containing predicates
  static int const kPredicateByteCount =
    (kPredicateCount + kPredicatesPerByte - 1) / kPredicatesPerByte;
  static int const kPredicateWordCount = (kPredicateByteCount + 3) / 4;

  static unsigned const kPredicateMask = (1u << kPredicatesPerByte) - 1u;

  static_assert(kPredicateWordCount <= 4, "Too many predicates.");

  /// Predicate vector stores mask to guard accesses
  using Mask = Array<uint32_t, kPredicateWordCount>;

// private:
  /// Guard predicates
  uint32_t predicates_[kPredicateWordCount];

  /// Size of tensor
  TensorCoord extent_;

  /// Initial offset for each thread
  TensorCoord thread_offset_;

  /// Offset to the first steady-state tile
  TensorCoord residue_offset_;

  /// Iteration along vectors implied by the thread map
  int iteration_vector_;

  /// Iteration in the contiguous dimension
  int iteration_contiguous_;

  /// Iteration in the strided dimension
  int iteration_strided_;

  /// extra vars
  int iteration_vector_2_;
  int iteration_contiguous_2_;
  int iteration_strided_2_;

 public:
  /// Computes predicates based on internally tracked per-thread offset.
  CUTLASS_DEVICE
  void compute_predicates_(
      /// Extent of the matrix window
      TensorCoord extent,
      /// optionally, simplify predicate calculation during 'steady state' phase
      bool is_steady_state = false) {

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < kPredicateWordCount; ++i) {
      predicates_[i] = 0u;
    }

    CUTLASS_PRAGMA_UNROLL
    for (int access_idx = 0; access_idx < ThreadMap::Iterations::kCount * kAccessesPerVector; ++access_idx) {

      int s = access_idx / (ThreadMap::Iterations::kContiguous * kAccessesPerVector);
      
      int access_residual = access_idx % (ThreadMap::Iterations::kContiguous * kAccessesPerVector);

      int c = access_residual / kAccessesPerVector;
      int v = access_residual % kAccessesPerVector;

      TensorCoord iteration_coord(c * ThreadMap::Delta::kContiguous + v * AccessType::kElements,
                                s * ThreadMap::Delta::kStrided);

      TensorCoord coord = thread_offset_ + iteration_coord;

      bool guard;

      if (is_steady_state) {
        if (kAdvanceRank == 0) {
          guard = (coord.strided() < extent.strided());
        } else {
          guard = (coord.contiguous() < extent.contiguous());
        }
      } else {
        guard = (coord.strided() < extent.strided() &&
                 coord.contiguous() < extent.contiguous());
      }

      int pred_idx = v + kAccessesPerVector * (c + ThreadMap::Iterations::kContiguous * s);

      int word_idx = pred_idx / kPredicatesPerWord;
      int residual = pred_idx % kPredicatesPerWord;
      int byte_idx = residual / kPredicatesPerByte;
      int bit_idx = residual % kPredicatesPerByte;
      
      predicates_[word_idx] |= (unsigned(guard) << (byte_idx * 8 + bit_idx));

    }

  }

  CUTLASS_HOST_DEVICE
  void set_predicates(int thread_id, TensorCoord const &threadblock_offset) {

    TensorCoord residue_extent;
    if (kAdvanceRank) {

      typename TensorCoord::Index residue_size = (extent_[kAdvanceRank] - threadblock_offset.strided()) % Shape::kStrided;
      if (!residue_size) {
        residue_size = Shape::kStrided;
      }

      residue_offset_ = make_Coord(0, residue_size);
      residue_extent = make_Coord(
        extent_.contiguous(), 
        min(threadblock_offset.strided() + residue_size, extent_.strided())
      );
    } else {

      typename TensorCoord::Index residue_size = (extent_[kAdvanceRank] - threadblock_offset.contiguous()) % Shape::kContiguous;
      if (!residue_size) {
        residue_size = Shape::kContiguous;
      }

      residue_offset_ = make_Coord(residue_size, 0);
      
      residue_extent = make_Coord(
        min(extent_.contiguous(), threadblock_offset.contiguous() + residue_size),
        extent_.strided()
      );
    }

    // Per-thread offset in logical coordinates of tensor
    thread_offset_ = threadblock_offset + ThreadMap::initial_offset(thread_id);

    compute_predicates_(residue_extent, false);

    set_iteration_index(0);
    set_iteration_index_2(0);
  }

    /// Constructs a TileIterator from its precomputed state, threadblock offset,
  /// and thread ID
  CUTLASS_HOST_DEVICE
  MyPredicatedTileAccessIteratorPredicates(
      /// Extent of tensor
      TensorCoord extent)
      : extent_(extent) {
	}

  /// Overrides the internal iteration index
  CUTLASS_HOST_DEVICE
  void set_iteration_index(int index) {

    iteration_vector_ = index % kAccessesPerVector;
    int residual_access = index / kAccessesPerVector;

    iteration_contiguous_ = residual_access % ThreadMap::Iterations::kContiguous;
    iteration_strided_ = residual_access / ThreadMap::Iterations::kContiguous;

  }

  CUTLASS_HOST_DEVICE
  void set_iteration_index_2(int index) {

    iteration_vector_2_ = index % kAccessesPerVector;
    int residual_access = index / kAccessesPerVector;

    iteration_contiguous_2_ = residual_access % ThreadMap::Iterations::kContiguous;
    iteration_strided_2_ = residual_access / ThreadMap::Iterations::kContiguous;

  }

  /// Increment and return an instance to self.
  CUTLASS_HOST_DEVICE
  MyPredicatedTileAccessIteratorPredicates &operator++() {

    return *this;
  }

  /// Increment and return an instance to self.
  CUTLASS_HOST_DEVICE
  MyPredicatedTileAccessIteratorPredicates second_plus() {

    return *this;
  }

  /// Clears the predicate set efficiently
  CUTLASS_HOST_DEVICE
  void clear_mask(bool enable = true) {
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < kPredicateWordCount; ++i) {
      predicates_[i] = enable ? 0u : predicates_[i];
    }

  }

  /// Clears the predicate set efficiently
  CUTLASS_HOST_DEVICE
  void enable_mask() {
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < kPredicateWordCount; ++i) {
      predicates_[i] = 0xffffffff;
    }
  }

  /// Sets the predicate mask, overriding value stored in predicate iterator
  CUTLASS_HOST_DEVICE
  void set_mask(Mask const &mask) { 
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < kPredicateWordCount; ++i) {
      predicates_[i] = mask[i];
    }

  }

  /// Gets the mask
  CUTLASS_HOST_DEVICE
  void get_mask(Mask &mask) {
     CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < kPredicateWordCount; ++i) {
      mask[i] = predicates_[i];
    }
  }

  /// Returns whether access is valid or not
  CUTLASS_HOST_DEVICE
  bool valid() {
    int pred_idx = 
      iteration_vector_ + kAccessesPerVector * (iteration_contiguous_ + iteration_strided_ * ThreadMap::Iterations::kContiguous);
    int word_idx = pred_idx / kPredicatesPerWord;
    int residual = pred_idx % kPredicatesPerWord;
    int byte_idx = residual / kPredicatesPerByte;
    int bit_idx = residual % kPredicatesPerByte;
    
    bool pred = (predicates_[word_idx] & (1u << (byte_idx * 8 + bit_idx))) != 0;
    return pred;
    
  }

  CUTLASS_HOST_DEVICE
  bool valid2() {
    int pred_idx = 
      iteration_vector_2_ + kAccessesPerVector * (iteration_contiguous_2_ + iteration_strided_2_ * ThreadMap::Iterations::kContiguous);
    int word_idx = pred_idx / kPredicatesPerWord;
    int residual = pred_idx % kPredicatesPerWord;
    int byte_idx = residual / kPredicatesPerByte;
    int bit_idx = residual % kPredicatesPerByte;
    
    bool pred = (predicates_[word_idx] & (1u << (byte_idx * 8 + bit_idx))) != 0;
    return pred;
    
  }
};

////////////////////////////////////////////////////////////////////////////////

/// MyPredicatedTileAccessIterator
///
template <typename Shape, typename Element, typename Layout, int AdvanceRank,
          typename ThreadMap, typename AccessType>
class MyPredicatedTileAccessIterator;

////////////////////////////////////////////////////////////////////////////////

/// Specialization of MyPredicatedTileAccessIterator for pitch-linear data.
///
template <typename Shape_, typename Element_, int AdvanceRank,
          typename ThreadMap_, typename AccessType_>
class MyPredicatedTileAccessIterator<Shape_, Element_, layout::PitchLinear,
                                   AdvanceRank, ThreadMap_, AccessType_> {
 public:
  static_assert(
      AdvanceRank == 0 || AdvanceRank == 1,
      "Specialization for pitch-linear iterator may along advance along the "
      "contiguous(rank=0) or strided(rank=1) dimension.");

  using Shape = Shape_;
  using Element = Element_;
  using Layout = layout::PitchLinear;
  static int const kAdvanceRank = AdvanceRank;
  using ThreadMap = ThreadMap_;
  using AccessType = AccessType_;

  using Index = typename Layout::Index;
  using LongIndex = typename Layout::LongIndex;

  using TensorRef = TensorRef<Element, Layout>;
  using TensorView = TensorView<Element, Layout>;
  using TensorCoord = typename Layout::TensorCoord;

  using Pointer = Element *;
  using NonConstPointer = typename platform::remove_const<Element>::type *;

  using UnderlyingPredicates = MyPredicatedTileAccessIteratorPredicates<
      Shape, Element, Layout, AdvanceRank, ThreadMap, AccessType>;

  static int const kAccessesPerVector = ThreadMap::kElementsPerAccess / AccessType::kElements;
  
  static_assert(!(ThreadMap::kElementsPerAccess % AccessType::kElements), 
    "Vectors implied by the thread map must be divisible by the access type.");

  using Mask = typename UnderlyingPredicates::Mask;

  /// Uses a non-template class
  struct Params : MyPredicatedTileAccessIteratorParams {
    
    using Base = MyPredicatedTileAccessIteratorParams;

    // Default ctor
    CUTLASS_HOST_DEVICE
    Params() { }

    /// Construct the Params object given a pitch-linear tensor's layout
    CUTLASS_HOST_DEVICE
    Params(Layout const &layout) : 
      Base(layout.stride(0),
            MyMakePredicatedTileAccessIteratorDesc<Shape, Element, Layout, kAdvanceRank, ThreadMap>()()
        ) { }

    CUTLASS_HOST_DEVICE
    Params(Base const &base) : 
      Base(base) { }
  };

 private:
  /// Internal pointer type permits fast address arithmetic
  using BytePointer = char *;

 private:
  //
  // Data members
  //

  UnderlyingPredicates the_predicates;

  /// Parameters object with precomputed internal state
  Params const &params_;

  /// Internal pointer to first access of tile
  BytePointer pointer_;
  Element *extra_pointer_ = NULL;
  Element *extra_square_pointer_ = NULL;
  Element *extra_beta_pointer_ = NULL;
  Element *extra_gamma_pointer_ = NULL;
  /// Used for out-of-order visitation
  bool is_residue_tile_;

 private:
  /// Computes predicates based on internally tracked per-thread offset.
  CUTLASS_DEVICE
  void compute_predicates_(
      /// Extent of the matrix window
      TensorCoord extent,
      /// optionally, simplify predicate calculation during 'steady state' phase
      bool is_steady_state = false) {
	  the_predicates.compute_predicates_(extent, is_steady_state);
  }

 public:

  CUTLASS_HOST_DEVICE
  MyPredicatedTileAccessIterator(
      /// Precomputed parameters object
      Params const &params,
      /// Pointer to start of tensor
      Pointer pointer,
      /// Extent of tensor
      TensorCoord extent,
      /// ID of each participating thread
      int thread_id,
      /// Initial offset of threadblock
      Element* extra_pointer,
      Element* extra_square_pointer,
      Element* extra_gamma_pointer,
      Element* extra_beta_pointer,
      TensorCoord const &threadblock_offset)
      : params_(params),
	pointer_(reinterpret_cast<BytePointer>(
            const_cast<NonConstPointer>(pointer))),
  extra_pointer_(extra_pointer),
  extra_square_pointer_(extra_square_pointer),
  extra_gamma_pointer_(extra_gamma_pointer),
  extra_beta_pointer_(extra_beta_pointer),
	the_predicates(extent),
        is_residue_tile_(true) {

    the_predicates.set_predicates(thread_id, threadblock_offset);
          
    // update internal pointers
    Layout layout(params_.stride_);
    add_pointer_offset(layout(the_predicates.thread_offset_));
    extra_pointer_ += the_predicates.thread_offset_.strided();
    extra_square_pointer_ += the_predicates.thread_offset_.strided();
    extra_beta_pointer_ += the_predicates.thread_offset_.contiguous();
    extra_gamma_pointer_ += the_predicates.thread_offset_.contiguous();
  }


  /// Constructs a TileIterator from its precomputed state, threadblock offset,
  /// and thread ID
  CUTLASS_HOST_DEVICE
  MyPredicatedTileAccessIterator(
      /// Precomputed parameters object
      Params const &params,
      /// Pointer to start of tensor
      Pointer pointer,
      /// Extent of tensor
      TensorCoord extent,
      /// ID of each participating thread
      int thread_id,
      /// Initial offset of threadblock
      TensorCoord const &threadblock_offset)
      : params_(params),
	pointer_(reinterpret_cast<BytePointer>(
            const_cast<NonConstPointer>(pointer))),
	the_predicates(extent),
        is_residue_tile_(true) {

    the_predicates.set_predicates(thread_id, threadblock_offset);
          
    // update internal pointers
    Layout layout(params_.stride_);
    add_pointer_offset(layout(the_predicates.thread_offset_));

  }

  /// Construct a MyPredicatedTileAccessIterator with zero threadblock offset
  CUTLASS_HOST_DEVICE
  MyPredicatedTileAccessIterator(
      /// Precomputed parameters object
      Params const &params,
      /// Pointer to start of tensor
      Pointer pointer,
      /// Extent of tensor
      TensorCoord extent,
      ///< ID of each participating thread
      int thread_id)
      : MyPredicatedTileAccessIterator(params, pointer, extent, thread_id,
                                     make_Coord(0, 0)) {}

  /// Overrides the internal iteration index
  CUTLASS_HOST_DEVICE
  void set_iteration_index(int index) {
    the_predicates.set_iteration_index(index);
  }

  CUTLASS_HOST_DEVICE
  void set_iteration_index_2(int index) {
    the_predicates.set_iteration_index_2(index);
  }

  /// Adds a pointer offset in units of Element
  CUTLASS_HOST_DEVICE
  void add_pointer_offset(LongIndex pointer_offset) {
    pointer_ += sizeof_bits<Element>::value * pointer_offset / 8;
  }

  /// Advances an iterator along logical dimensions of matrix in units of whole tiles
  CUTLASS_DEVICE
  void add_tile_offset(
      TensorCoord const &tile_offset) {
    Layout layout(params_.stride_);
    if (is_residue_tile_) {

      the_predicates.thread_offset_ += the_predicates.residue_offset_;
      auto leading_dim = (layout(the_predicates.thread_offset_) - the_predicates.thread_offset_.contiguous()) / the_predicates.thread_offset_.strided();
      auto local_add = sizeof_bits<Element>::value * layout(the_predicates.residue_offset_) / 8;
      // add_pointer_offset(local_add);

      pointer_ += local_add;
      extra_pointer_ += (local_add /2 / leading_dim);
      extra_square_pointer_ += (local_add /2 / leading_dim);
      extra_beta_pointer_ += the_predicates.residue_offset_.contiguous();
      extra_gamma_pointer_ += the_predicates.residue_offset_.contiguous();

      the_predicates.compute_predicates_(the_predicates.extent_, true);
      leading_dim = (layout(the_predicates.thread_offset_) - the_predicates.thread_offset_.contiguous()) / the_predicates.thread_offset_.strided();

      if (kAdvanceRank) {
        pointer_ += params_.inc_advance_ * LongIndex(tile_offset.strided() - 1);
        pointer_ += Shape::kContiguous * tile_offset.contiguous();
      } else {
        auto tmp1 = params_.inc_advance_ * LongIndex(tile_offset.contiguous() - 1);
        auto tmp2 = Shape::kStrided * tile_offset.strided();
        pointer_ += tmp1 + tmp2;
        extra_beta_pointer_ += tmp1 / 2;
        extra_pointer_ += ( (tmp1 + tmp2) / 2 / leading_dim);
        extra_square_pointer_ += ( (tmp1 + tmp2) / 2 / leading_dim);
        // extra_beta_pointer_ += ( (tmp1 + tmp2) / 2 / leading_dim);

      }
    } else {
      auto leading_dim = (layout(the_predicates.thread_offset_) - the_predicates.thread_offset_.contiguous()) / the_predicates.thread_offset_.strided();
      if (kAdvanceRank) {
        pointer_ += params_.inc_advance_ * LongIndex(tile_offset.strided());
        pointer_ += Shape::kContiguous * tile_offset.contiguous();
      } else {
        auto tmp1 = params_.inc_advance_ * LongIndex(tile_offset.contiguous());
        auto tmp2 = Shape::kStrided * tile_offset.strided();
        pointer_ += tmp1 + tmp2;
        extra_beta_pointer_ += tmp1 / 2;
        extra_gamma_pointer_ += tmp1 / 2;
        extra_pointer_ += ( (tmp1 + tmp2) / 2 / leading_dim);
        extra_square_pointer_ += ( (tmp1 + tmp2) / 2 / leading_dim);
        // extra_beta_pointer_ += ( (tmp1 + tmp2) / 2 / leading_dim);

      }
    }
    is_residue_tile_ = false;
  }

  /// Returns a pointer
  CUTLASS_HOST_DEVICE
  AccessType *get() const {
    return reinterpret_cast<AccessType *>(
        pointer_ + 
        the_predicates.iteration_contiguous_ * (ThreadMap::Delta::kContiguous * sizeof_bits<Element>::value) / 8) + the_predicates.iteration_vector_;
  }

  CUTLASS_HOST_DEVICE
  Element *get_mean_ptr() const {
    return extra_pointer_;
  }

  CUTLASS_HOST_DEVICE
  Element *get_mean_square_ptr() const {
    return extra_square_pointer_;
  }

  CUTLASS_HOST_DEVICE
  Element *get_beta_ptr() const {
    return extra_beta_pointer_;
  }

  CUTLASS_HOST_DEVICE
  Element *get_gamma_ptr() const {
    return extra_gamma_pointer_;
  }

  CUTLASS_HOST_DEVICE
  void print() {
    Layout layout(params_.stride_);
    auto leading_dim = (layout(the_predicates.thread_offset_) - the_predicates.thread_offset_.contiguous()) / the_predicates.thread_offset_.strided();
    printf("tid = %d, thread_offset = %ld, local_var_stride = %ld, thread_offset_.contiguous = %ld, thread_offset_.stride = %ld, layout = %ld,params_.inc_strided_ = %ld, leading_dim = %ld, params_.inc_next_ = %ld, params_.inc_advance_ = %ld, iteration_strided = %ld\n", threadIdx.x, \
    LongIndex(layout(the_predicates.thread_offset_)), params_.stride_, LongIndex(the_predicates.thread_offset_.contiguous()), LongIndex(the_predicates.thread_offset_.strided()), layout(the_predicates.thread_offset_),\
     params_.inc_strided_, LongIndex(leading_dim), LongIndex(params_.inc_next_), LongIndex(params_.inc_advance_), LongIndex(the_predicates.iteration_strided_));
  }


  /// Increment and return an instance to self.
  CUTLASS_HOST_DEVICE
  MyPredicatedTileAccessIterator &operator++() {

    the_predicates.operator++();

    ++the_predicates.iteration_vector_;
    if (the_predicates.iteration_vector_ < kAccessesPerVector) {
      return *this;
    }

    the_predicates.iteration_vector_ = 0;
    ++the_predicates.iteration_contiguous_;

    if (the_predicates.iteration_contiguous_ < ThreadMap::Iterations::kContiguous) {
      return *this;
    }

    // Enter here only if (iteration_contiguous_ ==
    // ThreadMap::Iteration::kContiguous)
    the_predicates.iteration_contiguous_ = 0;
    ++the_predicates.iteration_strided_;
    Layout layout(params_.stride_);
    // auto leading_dim = (layout(the_predicates.thread_offset_) - the_predicates.thread_offset_.contiguous()) / the_predicates.thread_offset_.strided();
    if (the_predicates.iteration_strided_ < ThreadMap::Iterations::kStrided) {
      pointer_ += params_.inc_strided_;
      // extra_pointer_ += (params_.inc_strided_/2 / leading_dim);
      // extra_square_pointer_ += (params_.inc_strided_/2 / leading_dim);
      return *this;
    }

    // Enter here only if (iteration_stride_ == ThreadMap::Iteration::kStrided)
    // which means we enter the next tile.
    the_predicates.iteration_strided_ = 0;

    // advance to next tile
    pointer_ += params_.inc_next_;

    // auto tmp = params_.inc_next_/2 / leading_dim;

    // extra_pointer_ += tmp;
    // extra_square_pointer_ += tmp;

    // if ( tmp * leading_dim * 2 !=  params_.inc_next_) {
    //   extra_pointer_ -= 1;
    //   extra_square_pointer_ -= 1;
    // }

    // now return to start tile - if the iterator is subsequently advanced, this
    // subtraction as well as the subsequent integer addition are both elided by
    // the compiler.
    pointer_ -= params_.inc_advance_;

    // extra_pointer_ -= (params_.inc_advance_/2 / leading_dim);
    // extra_square_pointer_ -= (params_.inc_advance_/2 / leading_dim);

    return *this;
  }

  CUTLASS_HOST_DEVICE
  MyPredicatedTileAccessIterator second_plus() {
    the_predicates.second_plus();

    ++the_predicates.iteration_vector_2_;
    if (the_predicates.iteration_vector_2_ < kAccessesPerVector) {
      return *this;
    }

    the_predicates.iteration_vector_2_ = 0;
    ++the_predicates.iteration_contiguous_2_;

    if (the_predicates.iteration_contiguous_2_ < ThreadMap::Iterations::kContiguous) {
      return *this;
    }

    the_predicates.iteration_contiguous_2_ = 0;
    ++the_predicates.iteration_strided_2_;
    Layout layout(params_.stride_);
    auto leading_dim = (layout(the_predicates.thread_offset_) - the_predicates.thread_offset_.contiguous()) / the_predicates.thread_offset_.strided();
    if (the_predicates.iteration_strided_2_ < ThreadMap::Iterations::kStrided) {
      extra_pointer_ += (params_.inc_strided_/2 / leading_dim);
      extra_square_pointer_ += (params_.inc_strided_/2 / leading_dim);
      return *this;
    }


    the_predicates.iteration_strided_2_ = 0;

    auto tmp = params_.inc_next_/2 / leading_dim;
    extra_pointer_ += tmp;
    extra_square_pointer_ += tmp;

    if ( tmp * leading_dim * 2 !=  params_.inc_next_) {
      extra_pointer_ -= 1;
      extra_square_pointer_ -= 1;
    }

    extra_pointer_ -= (params_.inc_advance_/2 / leading_dim);
    extra_square_pointer_ -= (params_.inc_advance_/2 / leading_dim);

    return *this;
  }

  /// Increment and return an instance to self.
  CUTLASS_HOST_DEVICE
  MyPredicatedTileAccessIterator operator++(int) {
    MyPredicatedTileAccessIterator self(*this);
    operator++();
    return self;
  }

  CUTLASS_HOST_DEVICE
  MyPredicatedTileAccessIterator second_plus(int) {
    MyPredicatedTileAccessIterator self(*this);
    second_plus();
    return self;
  }

  /// Clears the predicate set efficiently
  CUTLASS_HOST_DEVICE
  void clear_mask(bool enable = true) {
    the_predicates.clear_mask(enable);
  }

  /// Clears the predicate set efficiently
  CUTLASS_HOST_DEVICE
  void enable_mask() {
    the_predicates.enable_mask();
  }

  /// Sets the predicate mask, overriding value stored in predicate iterator
  CUTLASS_HOST_DEVICE
  void set_mask(Mask const &mask) { 
    the_predicates.set_mask(mask);
  }

  /// Gets the mask
  CUTLASS_HOST_DEVICE
  void get_mask(Mask &mask) {
    the_predicates.get_mask(mask);
  }

  /// Returns whether access is valid or not
  CUTLASS_HOST_DEVICE
  bool valid() {
    return the_predicates.valid();
  }

  /// Returns whether access is valid or not
  CUTLASS_HOST_DEVICE
  bool valid2() {
    return the_predicates.valid2();
  }

};



////////////////////////////////////////////////////////////////////////////////

}  // namespace threadblock
}  // namespace transform
}  // namespace cutlass

////////////////////////////////////////////////////////////////////////////////
