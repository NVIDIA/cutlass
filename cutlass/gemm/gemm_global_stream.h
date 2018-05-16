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
    \brief Implements efficient loading of the thread block-level tile from global memory and
   storing
      to shared memory.
*/
#pragma once

#include <cutlass/convert.h>
#include <cutlass/gemm/gemm_global_tile.h>
#include <cutlass/iterator_access.h>

namespace cutlass {
namespace gemm {

////////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// The load iterator.
    typename LoadIterator_,
    /// The store iterator to copy to shared memory.
    typename StoreIterator_,
    /// The transformer to be applied after the data has been copied from global memory.
    typename Transformer_>

struct GlobalLoadStreamBase {
  /// The load iterator.
  typedef LoadIterator_ LoadIterator;
  /// The transformer.
  typedef Transformer_ Transformer;
  /// The store iterator to write to shared memory.
  typedef StoreIterator_ StoreIterator;

  /// The fragment that is copied from shared memory.
  typedef typename LoadIterator::Fragment FetchedFragment;
  /// The fragment that is obtained after the transformation by the transformer.
  typedef typename Transformer::OutputFragment TransformedFragment;
  /// Make sure the fragments match.
  static_assert((platform::is_same<FetchedFragment, typename Transformer::InputFragment>::value),
                "");
  /// The output fragment.
  typedef TransformedFragment Fragment;
  /// Make sure the transformed fragment is the same as the store fragment.
  static_assert((platform::is_same<TransformedFragment, typename StoreIterator::Fragment>::value),
                "");

  /// The layout.
  static MatrixLayout::Kind const kLayout = LoadIterator::kLayout;
  /// The scalar type of the iterator.
  typedef typename LoadIterator::Scalar Scalar;
  /// The pointer.
  typedef typename LoadIterator::Pointer Pointer;
  /// The index.
  typedef typename LoadIterator::Index Index;

  /// The params.
  struct Params {
    // The load iterator.
    typename LoadIterator::Params load_iterator;
    // The store iterator.
    typename StoreIterator::Params store_iterator;

    /// Setup the params.
    CUTLASS_HOST_DEVICE int initialize(Pointer pointer, Index ld) {
      int error_code = load_iterator.initialize(pointer, ld);
      if (error_code) {
        return error_code;
      }

      return store_iterator.initialize();
    }
  };

  /// The amount of storage in shared memory needed to store the tile.
  typedef typename StoreIterator::SharedStorage SharedStoreStorage;

  /// The storage in shared memory needed by that stream.
  union SharedStorage {
    // The load iterator.
    typename LoadIterator::SharedStorage load_iterator;
    // The store iterator.
    SharedStoreStorage store_iterator;
  };

  /// Ctor.
  CUTLASS_DEVICE GlobalLoadStreamBase(Params const& params,
                                      SharedStorage& shared_storage,
                                      Coord<3> const bounds,
                                      Coord<3> const& block)
      : load_iterator(params.load_iterator, bounds, block),
        transformer(),
        store_iterator(params.store_iterator, shared_storage.store_iterator)

  {
    fetched_fragment.clear();
  }

  /// Load the data from shared memory to the fetch fragment.
  CUTLASS_DEVICE void copy() { iterator_load(load_iterator, fetched_fragment); }

  /// Commit the data.
  CUTLASS_DEVICE void commit() {
    transformer.transform(fetched_fragment, transformed_fragment);
    iterator_store(store_iterator, transformed_fragment);
    store_iterator.inc_stage();
  }

  /// Execute the residue code.
  CUTLASS_DEVICE void residue(Index k, bool skip_clear = false) {
    load_iterator.residue(k);
    if (!skip_clear) {
      fetched_fragment.clear();
    }
  }

  /// The iterator.
  LoadIterator load_iterator;
  /// The fragment to fetch from shared memory.
  FetchedFragment fetched_fragment;
  /// The transformer.
  Transformer transformer;
  /// The fragment to convert the data after it has been fetched from shared memory.
  TransformedFragment transformed_fragment;
  /// The store iterator.
  StoreIterator store_iterator;
};

////////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// The load iterator.
    typename LoadIterator_,
    /// The store iterator to copy to shared memory.
    typename StoreIterator_,
    /// The transformer to be applied after the data has been copied from global memory.
    typename Transformer_ = Copy<typename LoadIterator_::Fragment> >

struct GlobalLoadStream : public GlobalLoadStreamBase<LoadIterator_, StoreIterator_, Transformer_> {
  /// The base class.
  typedef GlobalLoadStreamBase<LoadIterator_, StoreIterator_, Transformer_> Base;

  /// Ctor.
  CUTLASS_DEVICE GlobalLoadStream(typename Base::Params const& params,
                                  typename Base::SharedStorage& shared_storage,
                                  Coord<3> const& bounds,
                                  Coord<3> const& block)
      : Base(params, shared_storage, bounds, block) {}
};

////////////////////////////////////////////////////////////////////////////////////////////////////
}  // namespace gemm
}  // namespace cutlass
