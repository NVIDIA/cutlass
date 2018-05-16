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
    \brief Defines the Tile Traits concept and iterators for loading and storing to tiles
   efficiently.
*/
#pragma once

#include <cutlass/fragment.h>
#include <cutlass/load_store.h>
#include <cutlass/predicate_vector.h>
#include <cutlass/vector.h>

namespace cutlass {

///////////////////////////////////////////////////////////////////////////////////////////////////

/*!@defgroup tile_traits_concept Tile Traits Concept
@{

\ref tile_traits_concept is a type definining the shape of a tile and the distribution of accesses
by individual entities, either threads or other.

@par Tile Traits Concept
   Types satisfying \ref tile_traits_concept define the following members
  - <b>Tile</b> - a type satisfying \ref layout_concept describing the dimensions of the tile
  - <b>Delta</b> - a type satisfying \ref layout_concept describing the increments between accesses
along each dimension
  - <b>Iterations</b> - a type satisfying \ref layout_concept describing the number of accesses
along each dimension
  - <b>Offset</b> - the type of a <i>functor</i> computing the offset of each participating entity
as a Coord<4>.
@}
*/

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Specifies dimension in which post-increment accesses advance
struct IteratorAdvance {
  enum Kind { kD, kH, kW };
};

/// Specifies whether iterator storage fragment consists of Scalar values or WMMA matrix
struct IteratorFragment {
  enum Kind { kScalar, kWmmaMatrix };
};

///////////////////////////////////////////////////////////////////////////////////////////////////

/**
* @brief A template defining \ref tile_traits_concept
* @concept{tile_traits_concept}
*/
template <typename Tile_, typename Delta_, typename Iterations_, typename ThreadOffset_>
struct TileTraits {
  /// Shape of the tile
  typedef Tile_ Tile;

  /// Number of steps between accesses along each dimension
  typedef Delta_ Delta;

  /// Number of accesses performed
  typedef Iterations_ Iterations;

  /// Functor that returns the logical coordinate of each entity's initial offset in the tile
  typedef ThreadOffset_ ThreadOffset;
};

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Iterator for accessing a stripmined tile in memory
template <typename Traits_,
          typename Scalar_,
          IteratorAdvance::Kind Advance_ = IteratorAdvance::kH,
          MemorySpace::Kind MemorySpace = MemorySpace::kGeneric,
          typename Index_ = int,
          typename FragmentElement_ = Scalar_,
          IteratorFragment::Kind IteratorFragment_ = IteratorFragment::kScalar,
          typename Skew_ = Shape<0, 0, 0, 0> >
struct TileIteratorBase {
  /// concept TileTraits
  typedef Traits_ Traits;

  /// Scalar element
  typedef Scalar_ Scalar;

  /// Fragment element
  typedef FragmentElement_ FragmentElement;

  /// Specifies dimension in which post-increment accesses advance.
  static IteratorAdvance::Kind const kAdvance = Advance_;

  /// Specifies iterator storage fragment type (Scalar or WmmaMatrix)
  static IteratorFragment::Kind const kIteratorFragment = IteratorFragment_;

  /// Source or destination memory space
  static MemorySpace::Kind const kMemorySpace = MemorySpace;

  /// Index type
  typedef Index_ Index;

  /// Skew quantity
  typedef Skew_ Skew;

  /// Tile shape
  typedef typename Traits::Tile Tile;

  /// Distance along each dimension
  typedef typename Traits::Delta Delta;

  /// The strides in each dimension between different loads/stores.
  typedef typename Traits::ImmediateOffsetStrides ImmediateOffsetStrides;

  /// Iterations
  typedef typename Traits::Iterations Iterations;

  /// Thread offset
  typedef typename Traits::ThreadOffset ThreadOffset;

  /// The number of scalars accessed per load/store.
  static int const kAccessSize = Tile::kC;

  /// The elements loaded/store by one instruction.
  typedef typename Vectorize<FragmentElement, kAccessSize>::Type AccessType;

  /// The size of storage needed per fragment
  static int const kFragmentSize =
      (kIteratorFragment == IteratorFragment::kWmmaMatrix ? 16 : sizeof(AccessType));
  /// The storage.
  typedef Fragment<Scalar, ShapeCount<Tile>::kCount, kFragmentSize> Storage;
  /// The fragment.
  typedef Fragment<FragmentElement, ShapeCount<Iterations>::kCount * kAccessSize> Fragment;
  /// The fragment iterator.
  typedef FragmentIterator<Fragment, Iterations, AccessType> FragmentIterator;
  /// The fragment const iterator.
  typedef FragmentConstIterator<Fragment, Iterations, AccessType> FragmentConstIterator;
  /// The shape of the fragment.
  typedef typename FragmentIterator::FragmentShape FragmentShape;

  /// Default predicate mask type
  typedef PredicateVector<ShapeCount<Iterations>::kCount> PredicateVector;

  //
  // Params struct
  //

  /// Parameters to the iterator
  struct Params {
    Index stride_d;
    Index stride_h;
    Index stride_w;

    Index inc_d;
    Index inc_h;
    Index inc_w;

    Index inc_advance;

    /// Initializes params
    CUTLASS_HOST_DEVICE
    int initialize(Index _stride_d,
                   Index _stride_h,
                   Index _stride_w,
                   Index _inc_d,
                   Index _inc_h,
                   Index _inc_w,
                   Index _inc_advance) {
      stride_d = _stride_d;
      stride_h = _stride_h;
      stride_w = _stride_w;

      inc_d = _inc_d;
      inc_h = _inc_h;
      inc_w = _inc_w;
      inc_advance = _inc_advance;

      return 0;
    }

    CUTLASS_HOST_DEVICE
    int initialize(Index _stride_d, Index _stride_h, Index _stride_w) {
      stride_d = _stride_d;
      stride_h = _stride_h;
      stride_w = _stride_w;

      inc_w = stride_w * Delta::kW;
      inc_h = stride_h * Delta::kH - stride_w * Delta::kW * (Iterations::kW - 1);

      if (kAdvance == IteratorAdvance::kH) {
        // Advance in the H dimension.
        inc_d = 0;
      } else if (kAdvance == IteratorAdvance::kW) {
        // Advance in the W dimension.
        inc_d = stride_w * Tile::kW - stride_h * Tile::kH;
      } else {
        // Advance in the D dimension.
        inc_d = stride_d;
      }

      inc_advance = 0;

      return 0;
    }

    CUTLASS_HOST_DEVICE int initialize() {
      stride_d = 0;
      stride_h = 0;
      stride_w = 1;

      inc_d = inc_h = inc_w = inc_advance = 0;

      return 0;
    }
  };

  /// Is the iterator valid?
  CUTLASS_DEVICE bool valid(int d, int h, int w, int c) const { return true; }

  //
  // Static function members
  //

  /// Initializes a predicate vector
  template <typename PredicateIterator>
  CUTLASS_DEVICE static void initialize_predicates(PredicateIterator predicate_it,
                                                   Coord<3> const &bounds,
                                                   Coord<3> const &offset = make_Coord(0, 0, 0)) {
    for (int d = 0; d < Iterations::kD; ++d) {
      bool enable_d = (d * Delta::kD + offset[0] < bounds[0]);
      for (int h = 0; h < Iterations::kH; ++h) {
        bool enable_h = (h * Delta::kH + offset[1] < bounds[1]);
        for (int w = 0; w < Iterations::kW; ++w) {
          bool enable_w = (w * Tile::kC * Delta::kW + offset[2] < bounds[2]);
          predicate_it.set(d, h, w, 0, enable_d && enable_h && enable_w);
        }
      }
    }
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

/*!@defgroup tile_load_iterator_concept Tile Load Iterator Concept
@{

\ref tile_load_iterator_concept enables loading a tile from addressable memory into a fragment

@par Tile Load Iterator Concept
  Types satisfying \ref tile_load_iterator_concept define the following members
  - <b>PredicateVector</b> - a \ref predicate_vector_concept with sufficient predicate storage for
each access implied by the tile traits
  - <b>Fragment</b> - the destination fragment type satisfying \ref fragment_concept
  - <b>initialize_predicates(pred_it, bounds, block_offset)</b> - function initializing a predicate
vector according to externally specified bounds
  - <b>load_post_increment(fragment, pred_it)</b> - a method that loads a fragment and increments
the iterator to the next tile, guarded by a \ref predicate_iterator_concept
  - <b>load_post_increment(fragment)</b> - a method that loads a fragment and increments the
iterator to the next tile
  - <b>load(fragment, pred_it)</b> - a const method that loads a fragment, guarded by a \ref
predicate_iterator_concept
  - <b>load(fragment)</b> - a method that loads a fragment

@}
*/

///////////////////////////////////////////////////////////////////////////////////////////////////

/**
* @brief An iterator implementing \ref tile_load_iterator_concept for loading a tile from memory
* @concept{tile_load_iterator_concept}
*/
template <typename Traits_,
          typename Scalar_,
          IteratorAdvance::Kind Advance_ = IteratorAdvance::kH,
          MemorySpace::Kind MemorySpace = MemorySpace::kGeneric,
          typename Index_ = int,
          typename FragmentElement_ = Scalar_,
          IteratorFragment::Kind IteratorFragment_ = IteratorFragment::kScalar,
          typename Skew_ = Shape<0, 0, 0, 0> >
struct TileLoadIterator : public TileIteratorBase<Traits_,
                                                  Scalar_,
                                                  Advance_,
                                                  MemorySpace,
                                                  Index_,
                                                  FragmentElement_,
                                                  IteratorFragment_,
                                                  Skew_> {
  /// Base class
  typedef TileIteratorBase<Traits_,
                           Scalar_,
                           Advance_,
                           MemorySpace,
                           Index_,
                           FragmentElement_,
                           IteratorFragment_,
                           Skew_>
      Base;

  /// concept TileTraits
  typedef typename Base::Traits Traits;

  /// Scalar element
  typedef typename Base::Scalar Scalar;

  /// Fragment element
  typedef typename Base::FragmentElement FragmentElement;

  /// Specifies in which dimension post-increment accesses advance.
  static IteratorAdvance::Kind const kAdvance = Base::kAdvance;

  /// Specifies type of iterator fragment storage (Salar or WmmaMatrix)
  static IteratorFragment::Kind const kIteratorFragment = Base::kIteratorFragment;

  /// Source or destination memory space
  static MemorySpace::Kind const kMemorySpace = Base::kMemorySpace;

  /// Index type
  typedef typename Base::Index Index;

  /// Skew quantity
  typedef typename Base::Skew Skew;

  /// Tile shape
  typedef typename Base::Tile Tile;

  /// Delta
  typedef typename Base::Delta Delta;

  /// Iterations
  typedef typename Base::Iterations Iterations;

  /// ThreadOffset functor
  typedef typename Base::ThreadOffset ThreadOffset;

  /// Fragment type
  typedef typename Base::FragmentShape FragmentShape;

  /// Memory access type
  typedef typename Base::AccessType AccessType;

  /// Fragment definition
  typedef typename Base::Fragment Fragment;

  /// Fragment iterator definition
  typedef typename Base::FragmentIterator FragmentIterator;

  /// Fragment const iterator definition
  typedef typename Base::FragmentConstIterator FragmentConstIterator;

  /// Default predicate mask type
  typedef typename Base::PredicateVector PredicateVector;

  /// Storage object that may be loaded from
  typedef typename Base::Storage SharedStorage;

  /// IteratorBase parameters
  typedef typename Base::Params BaseParams;

  /// Do we require a fence?
  enum { kRequiresLoadFence = Tile::kD == 1 };

  /// The pointer type
  typedef Scalar const *Pointer;

  /// Parameters
  struct Params : public BaseParams {
    /// Pointer to memory
    Scalar const *pointer;

    /// Initialize params to access storage object
    CUTLASS_HOST_DEVICE
    int initialize(SharedStorage const &storage) {
      pointer = &storage[0];
      return 0;
    }

    /// Initializes params to access a raw pointer
    CUTLASS_HOST_DEVICE
    int initialize(Scalar const *ptr, Index stride_d, Index stride_h, Index stride_w) {
      Base::Params::initialize(stride_d, stride_h, stride_w);
      pointer = ptr;
      return 0;
    }

    /// Initializes params
    CUTLASS_HOST_DEVICE
    int initialize(Scalar const *ptr,
                   Index _stride_d,
                   Index _stride_h,
                   Index _stride_w,
                   Index _inc_d,
                   Index _inc_h,
                   Index _inc_w,
                   Index _inc_advance) {
      pointer = ptr;
      Base::Params::initialize(
          _stride_d, _stride_h, _stride_w, _inc_d, _inc_h, _inc_w, _inc_advance);
      return 0;
    }

    // Initializes params to default values
    CUTLASS_HOST_DEVICE
    int initialize() { return Base::Params::initialize(); }
  };

  //
  // Data members
  //

  /// Parameters structure
  Params params;

  /// Offset of an individual lane from the start of the tile
  Coord<4> thread_offset;

  /// Stage argument enables wrapping after some number of tiles have been loaded.
  int stage;

  //
  // Static member functions
  //

  /// Initializes a predicate vector
  template <typename PredicateIterator>
  CUTLASS_HOST_DEVICE void initialize_predicates(PredicateIterator predicate_it,
                                                 Coord<3> const &bounds,
                                                 Coord<3> const &block_offset = make_Coord(0,
                                                                                           0,
                                                                                           0)) {
    Base::initialize_predicates(
        predicate_it,
        bounds,
        block_offset + make_Coord(0, thread_offset[1], thread_offset[2] * Tile::kC));
  }

  //
  // Methods
  //

  /// Default constructor
  CUTLASS_HOST_DEVICE
  TileLoadIterator() {}

  /// Constructs a tile load iterator
  CUTLASS_HOST_DEVICE
  TileLoadIterator(Params const &_params,
                   Coord<3> const &block_offset = make_Coord(0, 0, 0),
                   ThreadOffset thread_offset_func = ThreadOffset())
      : params(_params), stage(0) {
    thread_offset = thread_offset_func();

    Index block_offset_h = 0;
    Index block_offset_w = 0;
    if (kAdvance == IteratorAdvance::kH) {
      block_offset_h = block_offset[1];
      block_offset_w = block_offset[2];
    } else {
      block_offset_h = block_offset[2];
      block_offset_w = block_offset[1];
    }

    params.pointer += block_offset[0] * params.stride_d +
                      (block_offset_h + thread_offset[1]) * params.stride_h +
                      (block_offset_w + thread_offset[2] * Tile::kC) / Tile::kC * params.stride_w;
  }

  /// Constructs a tile load iterator
  CUTLASS_HOST_DEVICE
  TileLoadIterator(Params const &,
                   SharedStorage &shared_storage,
                   Coord<3> const &block_offset = make_Coord(0, 0, 0),
                   ThreadOffset thread_offset_func = ThreadOffset())
      : stage(0) {
    int const offset = thread_offset_func()[2];
    params.pointer = &shared_storage[offset];
  }

  /// Returns the current pointer
  CUTLASS_HOST_DEVICE
  Scalar const *data() const { return params.pointer; }

  /// Increment in the D dimension
  CUTLASS_HOST_DEVICE void inc_d() { params.pointer += params.inc_d; }

  /// Increment in the H dimension
  CUTLASS_HOST_DEVICE void inc_h() { params.pointer += params.inc_h; }

  /// Increment in the W dimension
  CUTLASS_HOST_DEVICE void inc_w() { params.pointer += params.inc_w; }

  /// Increment in the next dimension
  CUTLASS_HOST_DEVICE void inc_advance() { params.pointer += params.inc_advance; }

  /// Increment the stage.
  CUTLASS_DEVICE void inc_stage() {
    if (Tile::kD > 1) {
      int const kStageSize = Tile::kH * Tile::kW * Tile::kC;
      if (stage == Tile::kD - 1) {
        params.pointer -= (Tile::kD - 1) * kStageSize;
        stage = 0;
      } else {
        params.pointer += kStageSize;
        stage = stage + 1;
      }
    }
  }

 public:
  /// Loads a fragment and advances the iterator to the next tile.
  template <typename Fragment, typename PredicateIterator>
  CUTLASS_HOST_DEVICE void load_post_increment(Fragment &fragment, PredicateIterator pred_it) {
    FragmentIterator frag_iterator(fragment);

    for (int d = 0; d < Iterations::kD; ++d) {
      for (int h = 0; h < Iterations::kH; ++h) {
        for (int w = 0; w < Iterations::kW; ++w, ++pred_it) {
          if (*pred_it) {
            Load<typename Fragment::Element, Tile::kC, kMemorySpace>::load(
                reinterpret_cast<AccessType &>(frag_iterator.at(d, h, w, 0)), data(), 0);
          }

          if (w < Iterations::kW - 1) {
            inc_w();
          }
        }
        if (h < Iterations::kH - 1) {
          inc_h();
        }
      }
      if (d < Iterations::kD - 1) {
        inc_d();
      }
    }
    inc_advance();
  }

  /// Loads a fragment and advances the iterator to the next tile.
  template <typename Fragment>
  CUTLASS_HOST_DEVICE void load_post_increment(Fragment &fragment) {
    typename PredicateVector::TrivialIterator pred_it;
    load_post_increment(fragment, pred_it);
  }

  /// Loads a fragment without advancing the iterator..
  template <typename Fragment, typename PredicateIterator>
  CUTLASS_HOST_DEVICE void load(Fragment &fragment, PredicateIterator pred_it) const {
    TileLoadIterator _load_it(*this);
    _load_it.load_post_increment(fragment, pred_it);
  }

  /// Loads a fragment without advancing the iterator..
  template <typename Fragment>
  CUTLASS_HOST_DEVICE void load(Fragment &fragment) const {
    typename PredicateVector::TrivialIterator pred_it;
    load(fragment, pred_it);
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////

/*!@defgroup tile_store_iterator_concept Tile Store Iterator Concept
@{

\ref tile_store_iterator_concept enables storing a tile to addressable memory

@par Tile Store Iterator Concept
  Types satisfying \ref tile_load_iterator_concept define the following members
  - <b>PredicateVector</b> - a \ref predicate_vector_concept with sufficient predicate storage for
each access implied by the tile traits
  - <b>Fragment</b> - the destination fragment type satisfying \ref fragment_concept
  - <b>initialize_predicates(pred_it, bounds, block_offset)</b> - function initializing a predicate
vector according to externally specified bounds
  - <b>store_post_increment(fragment, pred_it)</b> - a method that stores a fragment and increments
the iterator to the next tile, guarded by a \ref predicate_iterator_concept
  - <b>store_post_increment(fragment)</b> - a method that stores a fragment and increments the
iterator to the next tile
  - <b>store(fragment, pred_it)</b> - a const method that stores a fragment, guarded by a \ref
predicate_iterator_concept
  - <b>store(fragment)</b> - a method that loads a fragment

@}
*/

///////////////////////////////////////////////////////////////////////////////////////////////////

/**
* @brief An iterator implementing \ref tile_store_iterator_concept for storing a tile to memory
* @concept{tile_store_iterator_concept}
*/
template <typename Traits_,
          typename Scalar_,
          IteratorAdvance::Kind Advance_ = IteratorAdvance::kH,
          MemorySpace::Kind MemorySpace = MemorySpace::kGeneric,
          typename Index_ = int,
          typename FragmentElement_ = Scalar_,
          IteratorFragment::Kind IteratorFragment_ = IteratorFragment::kScalar,
          typename Skew_ = Shape<0, 0, 0, 0> >
struct TileStoreIterator : public TileIteratorBase<Traits_,
                                                   Scalar_,
                                                   Advance_,
                                                   MemorySpace,
                                                   Index_,
                                                   FragmentElement_,
                                                   IteratorFragment_,
                                                   Skew_> {
  /// Base class
  typedef TileIteratorBase<Traits_,
                           Scalar_,
                           Advance_,
                           MemorySpace,
                           Index_,
                           FragmentElement_,
                           IteratorFragment_,
                           Skew_>
      Base;

  /// concept TileTraits
  typedef typename Base::Traits Traits;

  /// Scalar element
  typedef typename Base::Scalar Scalar;

  /// Fragment element
  typedef typename Base::FragmentElement FragmentElement;

  /// Specifies in which dimension post-increment accesses advance.
  static IteratorAdvance::Kind const kAdvance = Base::kAdvance;

  /// Specifies type of iterator fragment storage (Salar or WmmaMatrix)
  static IteratorFragment::Kind const kIteratorFragment = Base::kIteratorFragment;

  /// Source or destination memory space
  static MemorySpace::Kind const kMemorySpace = Base::kMemorySpace;

  /// Index type
  typedef typename Base::Index Index;

  /// Skew quantity
  typedef typename Base::Skew Skew;

  /// Tile shape
  typedef typename Base::Tile Tile;

  /// Delta
  typedef typename Base::Delta Delta;

  /// Iterations
  typedef typename Base::Iterations Iterations;

  /// ThreadOffset functor
  typedef typename Base::ThreadOffset ThreadOffset;

  /// Fragment type
  typedef typename Base::FragmentShape FragmentShape;

  /// Memory access type
  typedef typename Base::AccessType AccessType;

  /// Fragment definition
  typedef typename Base::Fragment Fragment;

  /// Fragment iterator definition
  typedef typename Base::FragmentIterator FragmentIterator;

  /// Fragment const iterator definition
  typedef typename Base::FragmentConstIterator FragmentConstIterator;

  /// Default predicate mask type
  typedef typename Base::PredicateVector PredicateVector;

  /// Storage object which may be stored to
  typedef typename Base::Storage SharedStorage;

  /// IteratorBase parameters
  typedef typename Base::Params BaseParams;

  /// Parameters
  struct Params : public BaseParams {
    /// Pointer to memory
    Scalar *pointer;

    /// Initialize params to access storage object
    CUTLASS_HOST_DEVICE
    int initialize(SharedStorage &storage) {
      pointer = &storage[0];
      return 0;
    }

    /// Initializes params to access a raw pointer
    CUTLASS_HOST_DEVICE
    int initialize(Scalar *ptr, Index stride_d, Index stride_h, Index stride_w) {
      Base::Params::initialize(stride_d, stride_h, stride_w);
      pointer = ptr;
      return 0;
    }

    /// Initializes params
    CUTLASS_HOST_DEVICE
    int initialize(Scalar *ptr,
                   Index _stride_d,
                   Index _stride_h,
                   Index _stride_w,
                   Index _inc_d,
                   Index _inc_h,
                   Index _inc_w,
                   Index _inc_advance) {
      pointer = ptr;
      Base::Params::initialize(
          _stride_d, _stride_h, _stride_w, _inc_d, _inc_h, _inc_w, _inc_advance);
      return 0;
    }

    /// Initializes params to default values
    CUTLASS_HOST_DEVICE
    int initialize() { return Base::Params::initialize(); }
  };

  //
  // Data members
  //

  /// Parameters structure
  Params params;

  /// Offset of an individual lane from the start of the tile
  Coord<4> thread_offset;

  /// The stage.
  int stage;

  //
  // Static member functions
  //

  /// Initializes a predicate vector
  template <typename PredicateIterator>
  CUTLASS_HOST_DEVICE void initialize_predicates(PredicateIterator predicate_it,
                                                 Coord<3> const &bounds,
                                                 Coord<3> const &block_offset = make_Coord(0,
                                                                                           0,
                                                                                           0)) {
    Base::initialize_predicates(
        predicate_it,
        bounds,
        block_offset + make_Coord(0, thread_offset[1], thread_offset[2] * Tile::kC));
  }

  //
  // Methods
  //

  /// Default constructor
  CUTLASS_HOST_DEVICE
  TileStoreIterator() {}

  /// Constructs a tile store iterator
  CUTLASS_HOST_DEVICE
  TileStoreIterator(Params const &_params,
                    Coord<3> const &block_offset = make_Coord(0, 0, 0),
                    ThreadOffset thread_offset_func = ThreadOffset())
      : params(_params), stage(0) {
    thread_offset = thread_offset_func();

    params.pointer += block_offset[0] * params.stride_d +
                      (block_offset[1] + thread_offset[1]) * params.stride_h +
                      (block_offset[2] + thread_offset[2] * Tile::kC) / Tile::kC * params.stride_w;
  }

  /// Constructs a tile store iterator
  CUTLASS_HOST_DEVICE
  TileStoreIterator(Params const &,
                    SharedStorage &shared_storage,
                    Coord<3> const &block_offset = make_Coord(0, 0, 0),
                    ThreadOffset thread_offset_func = ThreadOffset())
      : stage(0) {
    int const offset = thread_offset_func()[2];
    params.pointer = &shared_storage[offset];
  }

  /// Returns the current pointer
  CUTLASS_HOST_DEVICE
  Scalar *data() const { return params.pointer; }

  /// Increment in the D dimension
  CUTLASS_HOST_DEVICE void inc_d() { params.pointer += params.inc_d; }

  /// Increment in the H dimension
  CUTLASS_HOST_DEVICE void inc_h() { params.pointer += params.inc_h; }

  /// Increment in the W dimension
  CUTLASS_HOST_DEVICE void inc_w() { params.pointer += params.inc_w; }

  /// Increment in the next dimension
  CUTLASS_HOST_DEVICE void inc_advance() {}

  /// Increment the stage.
  CUTLASS_DEVICE void inc_stage() {
    if (Tile::kD > 1) {
      int const kStageSize = Tile::kH * Tile::kW * Tile::kC;
      if (stage == Tile::kD - 1) {
        params.pointer -= (Tile::kD - 1) * kStageSize;
        stage = 0;
      } else {
        params.pointer += kStageSize;
        stage = stage + 1;
      }
    }
  }

 public:
  /// Stores a fragment and advances to the next tile.
  template <typename Fragment, typename PredicateIterator>
  CUTLASS_HOST_DEVICE void store_post_increment(Fragment &fragment, PredicateIterator pred_it) {
    FragmentIterator frag_iterator(fragment);

    for (int d = 0; d < Iterations::kD; ++d) {
      for (int h = 0; h < Iterations::kH; ++h) {
        for (int w = 0; w < Iterations::kW; ++w, ++pred_it) {
          if (*pred_it) {
            Store<typename Fragment::Element, Tile::kC, kMemorySpace>::store(
                reinterpret_cast<AccessType &>(frag_iterator.at(d, h, w, 0)), data(), 0);
          }
          if (w < Iterations::kW - 1) {
            inc_w();
          }
        }
        if (h < Iterations::kH - 1) {
          inc_h();
        }
      }
      if (d < Iterations::kD - 1) {
        inc_d();
      }
    }
    inc_advance();
  }

  /// Stores a fragment and advances to the next tile.
  template <typename Fragment>
  CUTLASS_HOST_DEVICE void store_post_increment(Fragment &fragment) {
    typename PredicateVector::TrivialIterator pred_it;
    store_post_increment(fragment, pred_it);
  }

  /// Stores a fragment without advancing the iterator.
  template <typename Fragment, typename PredicateIterator>
  CUTLASS_HOST_DEVICE void store(Fragment &fragment, PredicateIterator pred_it) const {
    TileStoreIterator _store_it(*this);
    _store_it.store_post_increment(fragment, pred_it);
  }

  /// Stores a fragment without advancing the iterator.
  template <typename Fragment>
  CUTLASS_HOST_DEVICE void store(Fragment &fragment) const {
    typename PredicateVector::TrivialIterator pred_it;
    store(fragment, pred_it);
  }
};
}
