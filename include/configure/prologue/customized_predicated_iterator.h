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
    \brief Templates implementing loading of tiles from pitch-linear rank=2 tensors. 

    This iterator uses masks to guard out-of-bounds accesses. The first tile this
    iterator visits maybe partial, then the remaining tiles are complete. So, we 
    only need to compute the predicates twice, once before the first tile and 
    once for the remaining full tiles which can share the same predicates.

    A precomputed "Params" object minimizes the amount of state that must be stored in registers,
    and integer addition is used to advance the pointer through memory.
*/

/*
this helper function is added into functional.h

template <int N>
struct fused_minus_multiply {
  CUTLASS_DEVICE
  AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> operator()(AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> const & lhs, half_t const &rhs, half_t const &scalar) const {
    AlignedArray<half_t, N, (N * sizeof_bits<half_t>::value / 8)> result;

    __half2 *result_ptr = reinterpret_cast<__half2 *>(&result);
    __half2 const *lhs_ptr = reinterpret_cast<__half2 const *>(&lhs);
    __half2 rhs_pair = __half2half2(reinterpret_cast<__half const &>(rhs));
    __half2 scalar_pair = __half2half2(reinterpret_cast<__half const &>(scalar));

    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < N / 2; ++i) {
      result_ptr[i] = __hmul2(__hsub2(lhs_ptr[i], rhs_pair), scalar_pair);
    }

    if (N % 2) {
      __half const *a_residual_ptr = reinterpret_cast<__half const *>(&lhs);
      __half d_residual = __hmul(__hsub(a_residual_ptr[N - 1], reinterpret_cast<__half const &>(rhs) ),\
                                     reinterpret_cast<__half const &>(scalar));

      result[N - 1] = reinterpret_cast<half_t const &>(d_residual);
    }

    return result;
  }
};

*/

#pragma once
#include "cuda_fp16.h"
#include "cutlass/arch/memory.h"
#include "cutlass/transform/threadblock/predicated_tile_access_iterator.h"
#include "myfunctional.h"
#include "cutlass/numeric_conversion.h"
#include "cutlass/numeric_types.h"
#include "cutlass/array.h"
#include "customized_predicated_tile_access_iterator.h"

#define LOCAL_DEBUG 1

////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace transform {
namespace threadblock {

////////////////////////////////////////////////////////////////////////////////

/// MyPredicatedTileIterator
///
/// Satisfies: ForwardTileIteratorConcept | 
///            ReadableContiguousTileIteratorConcept | 
///            WriteableContiguousTileIteratorConcept |
///            MaskedTileIteratorConcept
///
/// Regular tile iterator using a precomputed control structure to minimize register liveness
/// and integer arithmetic.
///
/// Layout is assumed to be invariant at the time the precomputed "Params" object is constructed.
///
/// Base pointer and tensor extents may be specified at the time the iterator is constructed.
/// Subsequently, they are assumed to be immutable.
///
/// Adding a logical coordinate offset may be performed at the time the iterator is constructed.
/// Subsequent additions to logical coordinate offset may be performed but are relatively expensive.
///
/// Visitation order is intended to first visit a "residual" tile that may be partially full in
/// both the advance dimension and the steady-state dimension. This is assumed to be the last
/// tile in the iteration sequence. Advancing an iterator that has just been constructed moves to
/// the first tile that is full in the advance dimension and recomputes predicates. Subsequent
/// accesses may be performed without updating internal predicates and are efficient in terms of
/// live register state and pointer arithmetic instructions.
///
/// To be efficient, this assumes the iterator will be dereferenced and advanced at least once
/// outside any looping structure to minimize integer arithmetic. 
///
/// Acceses out of bounds are safe so long as `clear_mask()` is called prior to dereferencing
/// the iterator.
///
///
/// Example:
///
/// An efficient pipeline structure may be constructed as follows:
///
// template <typename Iterator>
// __global__ void kernel(
//   typename Iterator::Params params, 
//   typename Iterator::Element *ptr,
//   TensorCoord extent) {
//
//   typename Iterator::Fragment fragment;
//
//   TensorCoord threadblock_offset(0, 0);
//
//   Iterator iter(params, ptr, extent, threadIdx.x, threadblock_offsets);
//
//
//   fragment = *iter;        // load "residue" tile first
//   ++iter;                  // advance to first "steady state" tile and update internal masks
//
//
//   #pragma unroll
//   for (int i = Remaining - 1; i >= 0; --i) {
//
//     f(fragment);
//
//     if (!i) {
//       iter.clear_mask();   // light-weight operation to clear masks - subsequent loads become NO-OPs.
//     }
//  
//     fragment = *iter;      // load tile during "steady state" phase
//     ++iter;                // advance to next tile - lightweight due to steady-state masks
//   }
// }
//
// void host(TensorView<Element, 2, layout::PitchLinear> view) {
//
//   using Iterator = transform::threadblock::MyPredicatedTileIterator;
//
//   typename Iterator::Params params(view.layout());
//
//   kernel<Iterator>(params, view.data());
// }
///
///
template <
  typename Shape,
  typename Element,
  typename Layout,
  int AdvanceRank,
  typename ThreadMap,
  int AccessSize = ThreadMap::kElementsPerAccess
>
class MyPredicatedTileIterator;

////////////////////////////////////////////////////////////////////////////////

/// Specialization of MyPredicatedTileIterator for pitch-linear data.
///
/// Satisfies: ForwardTileIteratorConcept | 
///            ReadableContiguousTileIteratorConcept | 
///            WriteableContiguousTileIteratorConcept |
///            MaskedTileIteratorConcept
///
template <typename Shape_, typename Element_, int AdvanceRank,
          typename ThreadMap_, int AccessSize>
class MyPredicatedTileIterator<Shape_, Element_, layout::PitchLinear, AdvanceRank,
                             ThreadMap_, AccessSize> {
 public:
  static_assert(
      AdvanceRank == 0 || AdvanceRank == 1,
      "Specialization for pitch-linear iterator may advance along the "
      "contiguous(rank=0) or strided(rank=1) dimension.");

  using Shape = Shape_;
  using Element = Element_;
  using Layout = layout::PitchLinear;
  static int const kAdvanceRank = AdvanceRank;
  using ThreadMap = ThreadMap_;

  using Index = typename Layout::Index;
  using LongIndex = typename Layout::LongIndex;

  using TensorRef = TensorRef<Element, Layout>;
  using TensorView = TensorView<Element, Layout>;
  using TensorCoord = typename Layout::TensorCoord;

  using Pointer = Element *;
  using NonConstPointer = typename platform::remove_const<Element>::type *;

  /// Type used for internal memory accesses
  using AccessType = AlignedArray<Element, AccessSize, (AccessSize * sizeof_bits<Element>::value / 8)>;
  using FloatAccessType = AlignedArray<Element, 1, (1 * sizeof_bits<Element>::value / 8)>;

  using FragmentAccessType = cutlass::Array<Element, AccessSize>;
  using FragmentFloatAccessType = cutlass::Array<Element, 4>;

  using FragmentAccessTypeMean = cutlass::Array<Element, ThreadMap::Iterations::kCount>;
  using FragmentAccessBeta = cutlass::Array<Element, ThreadMap::kElementsPerAccess>;

  /// Underlying iterator to compute the addresses
  using TileAccessIterator =
      MyPredicatedTileAccessIterator<Shape, Element, Layout, kAdvanceRank,
                                   ThreadMap, AccessType>;

  static int const kAccessesPerVector = TileAccessIterator::kAccessesPerVector;

  /// Fragment object to be loaded or stored
  using Fragment = cutlass::Array<Element, ThreadMap::Iterations::kCount *
                                               ThreadMap::kElementsPerAccess>;

  using FragmentMean = cutlass::Array<Element, ThreadMap::Iterations::kCount>;
  using FragmentBeta = cutlass::Array<Element, ThreadMap::kElementsPerAccess>;

  /// Predicate vector stores mask to guard accesses
  using Mask = typename TileAccessIterator::Mask;

  /// Parameters object is precomputed state and is host-constructible
  class Params {
   public:
    using Base = typename TileAccessIterator::Params::Base;

    friend MyPredicatedTileIterator;

   private:
    /// Parameters object
    typename TileAccessIterator::Params params_;
    Element* ptr_;
   public:
    /// Construct the Params object given a pitch-linear tensor's layout
    CUTLASS_HOST_DEVICE
    Params(Layout const &layout) : params_(layout) { }
    
    CUTLASS_HOST_DEVICE
    Params() { }

    CUTLASS_HOST_DEVICE
    Params(Base const &base) 
        : params_(base) {}

    CUTLASS_HOST_DEVICE
    Params(Base const &base, Element *ptr) 
        : params_(base), ptr_(ptr) {}
  };

 private:
  /// Internal pointer type permits fast address arithmetic
  using BytePointer = char *;
 private:
  //
  // Data members
  //

  /// Data member to the tile access iterator
  TileAccessIterator address_iterator_;
  Element* internal_ptr;
  Element* internal_square_ptr;
  Element* internal_beta_ptr;
  Element* internal_gamma_ptr;

 public:
  /// Constructs a TileIterator from its precomputed state, threadblock offset,
  /// and thread ID
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator(
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
      : address_iterator_(params.params_, pointer, extent, thread_id,
                          threadblock_offset) {}

  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator(
      /// Precomputed parameters object
      Params const &params,
      /// Pointer to start of tensor
      Pointer pointer,
      /// Extent of tensor
      TensorCoord extent,
      /// ID of each participating thread
      int thread_id,
      Element *extra_pointer,
      Element *extra_square_pointer,
      Element *extra_gamma_pointer,
      Element *extra_beta_pointer,
      /// Initial offset of threadblock
      TensorCoord const &threadblock_offset)
      : address_iterator_(params.params_, pointer, extent, thread_id, extra_pointer, extra_square_pointer, extra_gamma_pointer, extra_beta_pointer,
                          threadblock_offset), internal_ptr(extra_pointer), internal_square_ptr(extra_square_pointer), internal_gamma_ptr(extra_gamma_pointer), internal_beta_ptr(extra_beta_pointer) {}

  /// Construct a MyPredicatedTileIterator with zero threadblock offset
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator(
      Params const &params,  ///< Precomputed parameters object
      Pointer pointer,       ///< Pointer to start of tensor
      TensorCoord extent,    ///< Extent of tensor
      int thread_id          ///< ID of each participating thread
      )
      : MyPredicatedTileIterator(params, pointer, extent, thread_id,
                               make_Coord(0, 0)) {}

  /// Adds a pointer offset in units of Element
  CUTLASS_HOST_DEVICE
  void add_pointer_offset(LongIndex pointer_offset) {
    address_iterator_.add_pointer_offset(pointer_offset);
  }

  /// Advances to the next tile in memory.
  ///
  /// The first time this method is called, predicates are updated, and the
  /// iterator's internal pointer is reverted to the first "steady state" tile.
  /// Subsequent calls are lightweight and must only update the internal
  /// pointer.
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator &operator++() {
    if (kAdvanceRank)
      address_iterator_.add_tile_offset({0, 1});
    else
      address_iterator_.add_tile_offset({1, 0});

    return *this;
  }

  /// Advances to the next tile in memory.
  ///
  /// The first time this method is called, predicates are updated, and the
  /// iterator's internal pointer is reverted to the first "steady state" tile.
  /// Subsequent calls are lightweight and must only update the internal
  /// pointer.
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator operator++(int) {
    MyPredicatedTileIterator self(*this);
    operator++();
    return self;
  }

  /// Clears the predicate set efficiently
  CUTLASS_HOST_DEVICE
  void clear_mask(bool enable = true) { address_iterator_.clear_mask(enable); }

  /// Clears the predicate set efficiently
  CUTLASS_HOST_DEVICE
  void enable_mask() { address_iterator_.enable_mask(); }

  /// Sets the predicate mask, overriding value stored in predicate iterator
  CUTLASS_HOST_DEVICE
  void set_mask(Mask const &mask) { address_iterator_.set_mask(mask); }

  /// Gets the mask
  CUTLASS_HOST_DEVICE
  void get_mask(Mask &mask) { address_iterator_.get_mask(mask); }


/*
  CUTLASS_DEVICE
  void load_with_pointer_offset(Fragment &frag, Index pointer_offset) {
    load_with_byte_offset(frag,\
     pointer_offset * sizeof_bits<Element>::value / 8);
  }

  CUTLASS_DEVICE
  void load_with_byte_offset(Fragment &frag, LongIndex byte_offset) {

    AccessType *frag_ptr = reinterpret_cast<AccessType *>(&frag);
    AccessType *beta_frag_ptr = reinterpret_cast<AccessType *>(&frag_beta);
    AccessType *gamma_frag_ptr = reinterpret_cast<AccessType *>(&frag_gamma);
    FloatAccessType *mean_frag_ptr = reinterpret_cast<FloatAccessType *>(&frag_mean);
    // FloatAccessType *square_frag_ptr = reinterpret_cast<FloatAccessType *>(&frag_mean_square);

    // minus<AccessType> minus_op;
    // multiplies<AccessType> mul_op;
    // plus<AccessType> plus_op;
    // fused_minus_multiply_add<AccessSize> fused_op;
    // fused_minus_multiply<AccessSize> fused_op;

    CUTLASS_PRAGMA_UNROLL
    for (int s = 0; s < ThreadMap::Iterations::kStrided; ++s) {
      CUTLASS_PRAGMA_UNROLL
      for (int c = 0; c < ThreadMap::Iterations::kContiguous; ++c) {

        CUTLASS_PRAGMA_UNROLL
        for (int v = 0; v < kAccessesPerVector; ++v) {

          int idx = v + kAccessesPerVector * (c + s * ThreadMap::Iterations::kContiguous);
          
          address_iterator_.set_iteration_index(idx);
          char const *byte_ptr = reinterpret_cast<char const *>(address_iterator_.get()) + byte_offset;
          char const *mean_byte_ptr = reinterpret_cast<char const *>(address_iterator_.get_mean_ptr());
          // char const *mean_square_byte_ptr = reinterpret_cast<char const *>(address_iterator_.get_mean_square_ptr());
          char const *beta_byte_ptr = reinterpret_cast<char const *>(address_iterator_.get_beta_ptr());
          char const *gamma_byte_ptr = reinterpret_cast<char const *>(address_iterator_.get_gamma_ptr());

          AccessType const *access_ptr = reinterpret_cast<AccessType const *>(byte_ptr);
          FloatAccessType const *mean_access_ptr = reinterpret_cast<FloatAccessType const *>(mean_byte_ptr);
          // FloatAccessType const *mean_square_access_ptr = reinterpret_cast<FloatAccessType const *>(mean_square_byte_ptr);
          AccessType const *beta_access_ptr = reinterpret_cast<AccessType const *>(beta_byte_ptr);
          AccessType const *gamma_access_ptr = reinterpret_cast<AccessType const *>(gamma_byte_ptr);
          cutlass::arch::global_load<AccessType,
                                     sizeof(AccessType)
                                    >(
              frag_ptr[idx], access_ptr, address_iterator_.valid());

          cutlass::arch::global_load<FloatAccessType,
                                     sizeof(FloatAccessType)
                                    >(
              mean_frag_ptr[idx], mean_access_ptr, address_iterator_.valid());

          // cutlass::arch::global_load<FloatAccessType,
          //                            sizeof(FloatAccessType)
          //                           >(
          //     square_frag_ptr[idx], mean_square_access_ptr, address_iterator_.valid());
          
          if (s == 0)
          {
            cutlass::arch::global_load<AccessType,
                                      sizeof(AccessType)
                                      >(
                beta_frag_ptr[0], beta_access_ptr, address_iterator_.valid());

            cutlass::arch::global_load<AccessType,
                                      sizeof(AccessType)
                                      >(
                gamma_frag_ptr[0], gamma_access_ptr, address_iterator_.valid());
          }

          // frag_ptr[idx] = plus_op(frag_ptr[idx], frag_mean[idx]);

#if (0)
          float tmp1 = static_cast<float>(frag_ptr[idx][0]);
          float tmp2 = static_cast<float>(frag_ptr[idx][1]);
          float tmp3 = static_cast<float>(frag_ptr[idx][2]);
          float tmp4 = static_cast<float>(frag_ptr[idx][3]);
          float tmp5 = static_cast<float>(frag_ptr[idx][4]);
          float tmp6 = static_cast<float>(frag_ptr[idx][5]);
          float tmp7 = static_cast<float>(frag_ptr[idx][6]);
          float tmp8 = static_cast<float>(frag_ptr[idx][7]);

          float scalar_beta1 = static_cast<float>(beta_frag_ptr[0][0]);
          float scalar_beta2 = static_cast<float>(beta_frag_ptr[0][1]);
          float scalar_beta3 = static_cast<float>(beta_frag_ptr[0][2]);
          float scalar_beta4 = static_cast<float>(beta_frag_ptr[0][3]);
          float scalar_beta5 = static_cast<float>(beta_frag_ptr[0][4]);
          float scalar_beta6 = static_cast<float>(beta_frag_ptr[0][5]);
          float scalar_beta7 = static_cast<float>(beta_frag_ptr[0][6]);
          float scalar_beta8 = static_cast<float>(beta_frag_ptr[0][7]);
#endif
          // frag_ptr[idx] = minus_op(frag_ptr[idx], float_frag_mean[0]);
          // frag_ptr[idx] = mul_op(frag_ptr[idx], float_frag_square_mean[0]);

#if (0)
          if (address_iterator_.valid()) printf("tid = %d, bid = %d, idx = %d, c = %d, s = %d, v = %d, byte_offset = %ld, kStride = %d, kCont = %d, AccessSize = %d, shape = {%d, %d}, beta = {%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f}, offset = {%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f,%5.2f} .\n",threadIdx.x, blockIdx.x, idx, c, s, v, byte_offset, ThreadMap::Iterations::kStrided, ThreadMap::Iterations::kContiguous,\
           AccessSize, ThreadMap::Iterations::kCount, ThreadMap::kElementsPerAccess, scalar_beta1, scalar_beta2, scalar_beta3, scalar_beta4, scalar_beta5, scalar_beta6, scalar_beta7, scalar_beta8,\
            tmp1, tmp2, tmp3, tmp4, tmp5, tmp6, tmp7, tmp8);
          // if (address_iterator_.valid()) address_iterator_.print();
#endif

          ++address_iterator_;
        }
      }
    }
  }
*/

  CUTLASS_DEVICE
  void compute(Fragment &frag) {

   FragmentMean frag_mean;
   FragmentMean frag_mean_square;
   FragmentBeta frag_beta; 
   FragmentBeta frag_gamma;

    AccessType *frag_ptr = reinterpret_cast<AccessType *>(&frag);
    AccessType *beta_frag_ptr = reinterpret_cast<AccessType *>(&frag_beta);
    AccessType *gamma_frag_ptr = reinterpret_cast<AccessType *>(&frag_gamma);
    FloatAccessType *square_frag_ptr = reinterpret_cast<FloatAccessType *>(&frag_mean_square);
    FloatAccessType *mean_frag_ptr = reinterpret_cast<FloatAccessType *>(&frag_mean);

    fused_minus_multiply_add<AccessSize> fused_op;
    CUTLASS_PRAGMA_UNROLL
    for (int s = 0; s < ThreadMap::Iterations::kStrided; ++s) {
          int idx = s;
          address_iterator_.set_iteration_index_2(idx);
          char const *mean_byte_ptr = reinterpret_cast<char const *>(address_iterator_.get_mean_ptr());
          char const *mean_square_byte_ptr = reinterpret_cast<char const *>(address_iterator_.get_mean_square_ptr());
          char const *beta_byte_ptr = reinterpret_cast<char const *>(address_iterator_.get_beta_ptr());
          char const *gamma_byte_ptr = reinterpret_cast<char const *>(address_iterator_.get_gamma_ptr());

          FloatAccessType const *mean_access_ptr = reinterpret_cast<FloatAccessType const *>(mean_byte_ptr);
          FloatAccessType const *mean_square_access_ptr = reinterpret_cast<FloatAccessType const *>(mean_square_byte_ptr);
          AccessType const *beta_access_ptr = reinterpret_cast<AccessType const *>(beta_byte_ptr);
          AccessType const *gamma_access_ptr = reinterpret_cast<AccessType const *>(gamma_byte_ptr);

          cutlass::arch::global_load<FloatAccessType,
                                     sizeof(FloatAccessType)
                                    >(
              mean_frag_ptr[idx], mean_access_ptr, address_iterator_.valid2());// 1 x m vector

          cutlass::arch::global_load<FloatAccessType,
                                     sizeof(FloatAccessType)
                                    >(
              square_frag_ptr[idx], mean_square_access_ptr, address_iterator_.valid2()); // 1 x m vector
          

          if (s == 0)
          {
            cutlass::arch::global_load<AccessType,
                                      sizeof(AccessType)
                                      >(
                beta_frag_ptr[0], beta_access_ptr, address_iterator_.valid2()); // k x 1 vector

            cutlass::arch::global_load<AccessType,
                                      sizeof(AccessType)
                                      >(
                gamma_frag_ptr[0], gamma_access_ptr, address_iterator_.valid2()); // k x 1 vector
          }

          // B(k x m) = (B(k x m) - v1(1 x m)) * v2(1 x m) * gamma(k x 1) + beta(k x 1)
          if (address_iterator_.valid2())
          {
            frag_ptr[idx] = fused_op(frag_ptr[idx], frag_mean[idx], frag_mean_square[idx], gamma_frag_ptr[0], beta_frag_ptr[0]);
          }
          address_iterator_.second_plus();
    }
  }

  CUTLASS_DEVICE
  void load_with_pointer_offset(Fragment &frag, Index pointer_offset) {
    load_with_byte_offset(frag, pointer_offset * sizeof_bits<Element>::value / 8);
  }

  CUTLASS_DEVICE
  void load_with_byte_offset(Fragment &frag, LongIndex byte_offset) {

    AccessType *frag_ptr = reinterpret_cast<AccessType *>(&frag);

    CUTLASS_PRAGMA_UNROLL
    for (int s = 0; s < ThreadMap::Iterations::kStrided; ++s) {
      CUTLASS_PRAGMA_UNROLL
      for (int c = 0; c < ThreadMap::Iterations::kContiguous; ++c) {

        CUTLASS_PRAGMA_UNROLL
        for (int v = 0; v < kAccessesPerVector; ++v) {

          int idx = v + kAccessesPerVector * (c + s * ThreadMap::Iterations::kContiguous);
          
          address_iterator_.set_iteration_index(idx);
          char const *byte_ptr = reinterpret_cast<char const *>(address_iterator_.get()) + byte_offset;

          AccessType const *access_ptr = reinterpret_cast<AccessType const *>(byte_ptr);

          cutlass::arch::global_load<AccessType,
                                     sizeof(AccessType)
                                    >(
              frag_ptr[idx], access_ptr, address_iterator_.valid());

          ++address_iterator_;
        }
      }
    }
  }

  /// Loads a fragment from memory
  CUTLASS_DEVICE
  void load(Fragment &frag) { load_with_byte_offset(frag, 0); }

  /// Store a fragment to memory
  CUTLASS_DEVICE
  void store_with_pointer_offset(Fragment const &frag, Index pointer_offset) {
    store_with_byte_offset(frag, pointer_offset * sizeof_bits<Element>::value / 8);
  }

  /// Store a fragment to memory
  CUTLASS_DEVICE
  void store_with_byte_offset(Fragment const &frag, LongIndex byte_offset) {
    address_iterator_.set_iteration_index(0);
    AccessType const *frag_ptr = reinterpret_cast<AccessType const *>(&frag);

    CUTLASS_PRAGMA_UNROLL
    for (int s = 0; s < ThreadMap::Iterations::kStrided; ++s) {
      CUTLASS_PRAGMA_UNROLL
      for (int c = 0; c < ThreadMap::Iterations::kContiguous; ++c) {
        CUTLASS_PRAGMA_UNROLL
        for (int v = 0; v < kAccessesPerVector; ++v) {

          int idx = v + kAccessesPerVector * (c + s * ThreadMap::Iterations::kContiguous);

          char *byte_ptr = reinterpret_cast<char *>(address_iterator_.get()) + byte_offset;
          AccessType *access_ptr = reinterpret_cast<AccessType *>(byte_ptr);

          if (address_iterator_.valid()) {
            *access_ptr = frag_ptr[idx];
          }
          ++address_iterator_;
        }
      }
    }
  }

  /// Store a fragment to memory
  CUTLASS_DEVICE
  void store(Fragment const &frag) { store_with_byte_offset(frag, 0); }
};

////////////////////////////////////////////////////////////////////////////////

/// Specialization of MyPredicatedTileIterator for pitch-linear data.
///
/// Satisfies: ForwardTileIteratorConcept | 
///            ReadableContiguousTileIteratorConcept | 
///            WriteableContiguousTileIteratorConcept |
///            MaskedTileIteratorConcept
///
template <
  typename Shape_,
  typename Element_,
  int AdvanceRank,
  typename ThreadMap_,
  int AccessSize
>
class MyPredicatedTileIterator<Shape_, Element_, layout::RowMajor, AdvanceRank, ThreadMap_, AccessSize> {
public:

  static_assert(AdvanceRank == 0 || AdvanceRank == 1, 
    "Specialization for pitch-linear iterator may along advance along the "
    "contiguous(rank=0) or strided(rank=1) dimension.");

  using Shape = Shape_;
  using Element = Element_;
  using Layout = layout::RowMajor;
  static int const kAdvanceRank = AdvanceRank;
  using ThreadMap = ThreadMap_;

  using Index = typename Layout::Index;
  using LongIndex = typename Layout::LongIndex;

  using TensorRef = TensorRef<Element, Layout>;
  using TensorView = TensorView<Element, Layout>;
  using TensorCoord = typename Layout::TensorCoord;

  using Pointer = Element *;
  using NonConstPointer = typename platform::remove_const<Element>::type *;

  using UnderlyingIterator = MyPredicatedTileIterator<
    layout::PitchLinearShape<Shape::kColumn, Shape::kRow>,
    Element,
    layout::PitchLinear,
    (kAdvanceRank == 0 ? 1 : 0),
    ThreadMap,
    AccessSize
  >;

  using AccessType = typename UnderlyingIterator::AccessType;

  /// Fragment object to be loaded or stored
  using Fragment = cutlass::Array<Element, ThreadMap::Iterations::kCount * ThreadMap::kElementsPerAccess>;
  using FragmentMean = cutlass::Array<Element, ThreadMap::Iterations::kCount>;
  using FragmentBeta = cutlass::Array<Element, ThreadMap::kElementsPerAccess>;

  /// Predicate vector stores mask to guard accesses
  using Mask = typename UnderlyingIterator::Mask;

  /// Parameters object is precomputed state and is host-constructible
  class Params {
  private:

    friend MyPredicatedTileIterator;

    /// Parameters object
    typename UnderlyingIterator::Params params_;

  public:
    
    CUTLASS_HOST_DEVICE
    Params() { } 

    /// Construct the Params object given a pitch-linear tensor's layout
    CUTLASS_HOST_DEVICE
    Params(Layout const &layout): params_(layout::PitchLinear(layout.stride(0))) {}

    CUTLASS_HOST_DEVICE
    Params(typename UnderlyingIterator::Params::Base const &base) 
        : params_(base) {}

  };


private:

  //
  // Data members
  //

  /// Underlying pitch-linear tile iterator
  UnderlyingIterator iterator_;

public:

  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator(
    Params const &params,                         ///< Precomputed parameters object 
    Pointer pointer,                              ///< Pointer to start of tensor
    TensorCoord extent,                           ///< Extent of tensor
    int thread_id,                                ///< ID of each participating thread
    Element *extra_pointer,
    Element *extra_square_pointer,
    Element *extra_gamma_pointer,
    Element *extra_beta_pointer,
    TensorCoord const &threadblock_offset         ///< Initial offset of threadblock
  ):
    iterator_(
      params.params_,
      pointer,
      layout::PitchLinearCoord(extent.column(), extent.row()),
      thread_id,
      extra_pointer,
      extra_square_pointer,
      extra_gamma_pointer,
      extra_beta_pointer,
      layout::PitchLinearCoord(threadblock_offset.column(), threadblock_offset.row())
    ) { }

  /// Constructs a TileIterator from its precomputed state, threadblock offset, and thread ID
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator(
    Params const &params,                         ///< Precomputed parameters object 
    Pointer pointer,                              ///< Pointer to start of tensor
    TensorCoord extent,                           ///< Extent of tensor
    int thread_id,                                ///< ID of each participating thread
    TensorCoord const &threadblock_offset         ///< Initial offset of threadblock
  ):
    iterator_(
      params.params_,
      pointer,
      layout::PitchLinearCoord(extent.column(), extent.row()),
      thread_id,
      layout::PitchLinearCoord(threadblock_offset.column(), threadblock_offset.row())
    ) { }

  /// Construct a MyPredicatedTileIterator with zero threadblock offset
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator(
    Params const &params,                         ///< Precomputed parameters object
    Pointer pointer,                              ///< Pointer to start of tensor
    TensorCoord extent,                           ///< Extent of tensor
    int thread_id                                 ///< ID of each participating thread
  ): MyPredicatedTileIterator(params, pointer, extent, thread_id, make_Coord(0, 0)) { }

  /// Adds a pointer offset in units of Element
  CUTLASS_HOST_DEVICE
  void add_pointer_offset(LongIndex pointer_offset) {
    iterator_.add_pointer_offset(pointer_offset);
  }

  /// Advances to the next tile in memory.
  ///
  /// The first time this method is called, predicates are updated, and the iterator's
  /// internal pointer is reverted to the first "steady state" tile. Subsequent calls
  /// are lightweight and must only update the internal pointer.
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator &operator++() {
    ++iterator_;
    return *this;
  }

  /// Advances to the next tile in memory.
  ///
  /// The first time this method is called, predicates are updated, and the iterator's
  /// internal pointer is reverted to the first "steady state" tile. Subsequent calls
  /// are lightweight and must only update the internal pointer.
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator operator++(int) {
    MyPredicatedTileIterator self(*this);
    operator++();
    return self;
  }

  /// Clears the predicate set efficiently
  CUTLASS_HOST_DEVICE
  void clear_mask(bool enable = true) {
    iterator_.clear_mask(enable);
  }

  /// Clears the predicate set efficiently
  CUTLASS_HOST_DEVICE
  void enable_mask() {
    iterator_.enable_mask();
  }

  /// Sets the predicate mask, overriding value stored in predicate iterator
  CUTLASS_HOST_DEVICE
  void set_mask(Mask const &mask) {
    iterator_.set_mask(mask);
  }

  /// Gets the mask
  CUTLASS_HOST_DEVICE
  void get_mask(Mask &mask) {
    iterator_.get_mask(mask);
  }

  CUTLASS_DEVICE
  void load_with_pointer_offset(Fragment &frag, Index pointer_offset) {
    iterator_.load_with_pointer_offset(frag, pointer_offset);
  }

  /// Loads a fragment from memory
  CUTLASS_DEVICE
  void load_with_byte_offset(Fragment &frag, LongIndex byte_offset) {
    iterator_.load_with_byte_offset(frag, byte_offset);
  }

  /// Loads a fragment from memory
  CUTLASS_DEVICE
  void load(Fragment &frag) {
    load_with_pointer_offset(frag, 0);
  }

  /// Loads a fragment from memory
  CUTLASS_DEVICE
  void compute(Fragment &frag) {
    iterator_.compute(frag);
  }

  /// Store a fragment to memory
  CUTLASS_DEVICE
  void store_with_pointer_offset(Fragment const &frag, Index pointer_offset) {
    iterator_.store_with_pointer_offset(frag, pointer_offset);
  }
  
  /// Store a fragment to memory
  CUTLASS_DEVICE
  void store_with_byte_offset(Fragment const &frag, LongIndex byte_offset) {
    iterator_.store_with_byte_offset(frag, byte_offset);
  }

  /// Store a fragment to memory
  CUTLASS_DEVICE
  void store(Fragment const &frag) {
    store_with_pointer_offset(frag, 0);
  }
};


/// Specialization of MyPredicatedTileIterator for pitch-linear data.
///
/// Satisfies: ForwardTileIteratorConcept | 
///            ReadableContiguousTileIteratorConcept | 
///            WriteableContiguousTileIteratorConcept |
///            MaskedTileIteratorConcept
///
template <
  typename Shape_,
  typename Element_,
  int AdvanceRank,
  typename ThreadMap_,
  int AccessSize
>
class MyPredicatedTileIterator<Shape_, Element_, layout::ColumnMajor, AdvanceRank, ThreadMap_, AccessSize> {
public:

  static_assert(AdvanceRank == 0 || AdvanceRank == 1, 
    "Specialization for pitch-linear iterator may along advance along the "
    "contiguous(rank=0) or strided(rank=1) dimension.");

  using Shape = Shape_;
  using Element = Element_;
  using Layout = layout::ColumnMajor;
  static int const kAdvanceRank = AdvanceRank;
  using ThreadMap = ThreadMap_;

  using Index = typename Layout::Index;
  using LongIndex = typename Layout::LongIndex;

  using TensorRef = TensorRef<Element, Layout>;
  using TensorView = TensorView<Element, Layout>;
  using TensorCoord = typename Layout::TensorCoord;

  using Pointer = Element *;
  using NonConstPointer = typename platform::remove_const<Element>::type *;

  using UnderlyingIterator = MyPredicatedTileIterator<
    layout::PitchLinearShape<Shape::kRow, Shape::kColumn>,
    Element,
    layout::PitchLinear,
    (kAdvanceRank == 0 ? 0 : 1),
    ThreadMap,
    AccessSize
  >;

  using AccessType = typename UnderlyingIterator::AccessType;
  
  /// Fragment object to be loaded or stored
  using Fragment = cutlass::Array<Element, ThreadMap::Iterations::kCount * ThreadMap::kElementsPerAccess>;
  using FragmentMean = cutlass::Array<Element, ThreadMap::Iterations::kCount>;
  using FragmentBeta = cutlass::Array<Element, ThreadMap::kElementsPerAccess>;

  /// Predicate vector stores mask to guard accesses
  using Mask = typename UnderlyingIterator::Mask;

  /// Parameters object is precomputed state and is host-constructible
  class Params {
  private:

    friend MyPredicatedTileIterator;

    /// Parameters object
    typename UnderlyingIterator::Params params_;

  public:
    
    CUTLASS_HOST_DEVICE
    Params() { }

    /// Construct the Params object given a pitch-linear tensor's layout
    CUTLASS_HOST_DEVICE
    Params(Layout const &layout): params_(layout::PitchLinear(layout.stride(0))) {

    }

    CUTLASS_HOST_DEVICE
    Params(typename UnderlyingIterator::Params::Base const &base) 
        : params_(base) {}
  };


private:

  //
  // Data members
  //

  /// Underlying pitch-linear tile iterator
  UnderlyingIterator iterator_;

public:

  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator(
    Params const &params,                         ///< Precomputed parameters object 
    Pointer pointer,                              ///< Pointer to start of tensor
    TensorCoord extent,                           ///< Extent of tensor
    int thread_id,                                ///< ID of each participating thread
    Element *extra_pointer,
    Element *extra_square_pointer,
    Element *extra_gamma_pointer,
    Element *extra_beta_pointer,
    TensorCoord const &threadblock_offset         ///< Initial offset of threadblock
  ):
    iterator_(
      params.params_,
      pointer,
      layout::PitchLinearCoord(extent.row(), extent.column()),
      thread_id,
      extra_pointer,
      extra_square_pointer,
      extra_gamma_pointer,
      extra_beta_pointer,
      layout::PitchLinearCoord(threadblock_offset.row(), threadblock_offset.column())
    ) { }

  /// Constructs a TileIterator from its precomputed state, threadblock offset, and thread ID
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator(
    Params const &params,                         ///< Precomputed parameters object 
    Pointer pointer,                              ///< Pointer to start of tensor
    TensorCoord extent,                           ///< Extent of tensor
    int thread_id,                                ///< ID of each participating thread
    TensorCoord const &threadblock_offset         ///< Initial offset of threadblock
  ):
    iterator_(
      params.params_,
      pointer,
      layout::PitchLinearCoord(extent.row(), extent.column()),
      thread_id,
      layout::PitchLinearCoord(threadblock_offset.row(), threadblock_offset.column())
    ) { }

  /// Construct a MyPredicatedTileIterator with zero threadblock offset
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator(
    Params const &params,                         ///< Precomputed parameters object
    Pointer pointer,                              ///< Pointer to start of tensor
    TensorCoord extent,                           ///< Extent of tensor
    int thread_id                                 ///< ID of each participating thread
  ): MyPredicatedTileIterator(params, pointer, extent, thread_id, make_Coord(0, 0)) { }

  /// Adds a pointer offset in units of Element
  CUTLASS_HOST_DEVICE
  void add_pointer_offset(LongIndex pointer_offset) {
    iterator_.add_pointer_offset(pointer_offset);
  }

  /// Advances to the next tile in memory.
  ///
  /// The first time this method is called, predicates are updated, and the iterator's
  /// internal pointer is reverted to the first "steady state" tile. Subsequent calls
  /// are lightweight and must only update the internal pointer.
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator &operator++() {
    ++iterator_;
    return *this;
  }

  /// Advances to the next tile in memory.
  ///
  /// The first time this method is called, predicates are updated, and the iterator's
  /// internal pointer is reverted to the first "steady state" tile. Subsequent calls
  /// are lightweight and must only update the internal pointer.
  CUTLASS_HOST_DEVICE
  MyPredicatedTileIterator operator++(int) {
    MyPredicatedTileIterator self(*this);
    operator++();
    return self;
  }

  /// Clears the predicate set efficiently
  CUTLASS_HOST_DEVICE
  void clear_mask(bool enable = true) {
    iterator_.clear_mask(enable);
  }

  /// Clears the predicate set efficiently
  CUTLASS_HOST_DEVICE
  void enable_mask() {
    iterator_.enable_mask();
  }

  /// Sets the predicate mask, overriding value stored in predicate iterator
  CUTLASS_HOST_DEVICE
  void set_mask(Mask const &mask) {
    iterator_.set_mask(mask);
  }

  /// Gets the mask
  CUTLASS_HOST_DEVICE
  void get_mask(Mask &mask) {
    iterator_.get_mask(mask);
  }

  CUTLASS_DEVICE
  void load_with_pointer_offset(Fragment &frag, Index pointer_offset) {
    iterator_.load_with_pointer_offset(frag, pointer_offset);
  }

  /// Loads a fragment from memory
  CUTLASS_DEVICE
  void load_with_byte_offset(Fragment &frag, LongIndex byte_offset) {
    iterator_.load_with_byte_offset(frag, byte_offset);
  }

  /// Loads a fragment from memory
  CUTLASS_DEVICE
  void load(Fragment &frag) {
    load_with_pointer_offset(frag, 0);
  }

  /// Loads a fragment from memory
  CUTLASS_DEVICE
  void compute(Fragment &frag) {
    iterator_.compute(frag);
  }

  /// Store a fragment to memory
  CUTLASS_DEVICE
  void store_with_pointer_offset(Fragment const &frag, Index pointer_offset) {
    iterator_.store_with_pointer_offset(frag, pointer_offset);
  }

  /// Store a fragment to memory
  CUTLASS_DEVICE
  void store_with_byte_offset(Fragment const &frag, LongIndex byte_offset) {
    iterator_.store_with_byte_offset(frag, byte_offset);
  }

  /// Store a fragment to memory
  CUTLASS_DEVICE
  void store(Fragment const &frag) {
    store_with_pointer_offset(frag, 0);
  }
};




} // namespace threadblock
} // namespace transform
} // namespace cutlass

////////////////////////////////////////////////////////////////////////////////
