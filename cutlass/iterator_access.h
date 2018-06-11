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
    \brief Free functions for loading and storing to implementations of tile iteartor concepts.
*/
#pragma once

#include <cutlass/fragment_load_store.h>
#include <cutlass/load_store.h>
#include <cutlass/predicate_vector.h>
#include <cutlass/shape.h>

namespace cutlass {

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Loads a fragment from an input iterator
template <typename InputIterator, typename Fragment>
CUTLASS_HOST_DEVICE void iterator_load(InputIterator &iterator, Fragment &fragment) {
  typename InputIterator::FragmentIterator frag_iterator(fragment);
  for (int d = 0; d < InputIterator::Iterations::kD; ++d) {
    for (int h = 0; h < InputIterator::Iterations::kH; ++h) {
      for (int w = 0; w < InputIterator::Iterations::kW; ++w) {
        for (int c = 0; c < InputIterator::Iterations::kC; ++c) {
          if (iterator.valid(d, h, w, c)) {
            iterator.get(reinterpret_cast<typename InputIterator::AccessType &>(
                             frag_iterator.at(d, h, w, c)),
                         d,
                         h,
                         w,
                         c);
          }
        }
        if (w < InputIterator::Iterations::kW - 1) {
          iterator.inc_w();
        }
      }
      if (h < InputIterator::Iterations::kH - 1) {
        iterator.inc_h();
      }
    }
    if (d < InputIterator::Iterations::kD - 1) {
      iterator.inc_d();
    }
  }
  iterator.inc_advance();
}

/// Loads a fragment from a shared memory input iterator
template <typename InputIterator, typename Fragment>
CUTLASS_DEVICE void shared_iterator_load(InputIterator &iterator, Fragment &fragment) {
  typename InputIterator::FragmentIterator frag_iterator(fragment);
  for (int d = 0; d < InputIterator::Iterations::kD; ++d) {
    for (int h = 0; h < InputIterator::Iterations::kH; ++h) {
      for (int w = 0; w < InputIterator::Iterations::kW; ++w) {
        for (int c = 0; c < InputIterator::Iterations::kC; ++c) {
          int const offset =
              ComputeOffsetFromStrides<typename InputIterator::ImmediateOffsetStrides>::get(
                  d, h, w, c);

          FragmentLoad<InputIterator::kIteratorFragment,
                       InputIterator::Tile::kC,
                       typename InputIterator::Scalar,
                       InputIterator::kMemorySpace,
                       typename InputIterator::FragmentElement,
                       InputIterator::Tile::kW>::load(frag_iterator.at(d, h, w, c),
                                                      iterator.data(),
                                                      offset);
        }
      }
    }
  }
}

/// Loads a fragment from a shared memory input iterator
template <typename InputIterator, typename Fragment>
CUTLASS_DEVICE void shared_iterator_load(InputIterator &iterator, Fragment &fragment, int d) {
  typename InputIterator::FragmentIterator frag_iterator(fragment);
  for (int h = 0; h < InputIterator::Iterations::kH; ++h) {
    for (int w = 0; w < InputIterator::Iterations::kW; ++w) {
      for (int c = 0; c < InputIterator::Iterations::kC; ++c) {
        int const offset =
            ComputeOffsetFromStrides<typename InputIterator::ImmediateOffsetStrides>::get(
                d, h, w, c);

        FragmentLoad<InputIterator::kIteratorFragment,
                     InputIterator::Tile::kC,
                     typename InputIterator::Scalar,
                     InputIterator::kMemorySpace,
                     typename InputIterator::FragmentElement,
                     InputIterator::Tile::kW>::load(frag_iterator.at(0, h, w, c),
                                                    iterator.data(),
                                                    offset);
      }
    }
  }
}

/// Loads a fragment from an input iterator, masked by a predicate iterator
template <typename InputIterator, typename Fragment, typename ConstPredicateAdapter>
CUTLASS_HOST_DEVICE void iterator_load_post_increment(InputIterator &iterator,
                                                      Fragment &fragment,
                                                      typename InputIterator::Index offset,
                                                      ConstPredicateAdapter predicate_adapter) {
  for (int d = 0; d < InputIterator::Iterations::kD; ++d, iterator.inc_d()) {
    for (int h = 0; h < InputIterator::Iterations::kH; ++h, iterator.inc_h()) {
      for (int w = 0; w < InputIterator::Iterations::kW; ++w, iterator.inc_w()) {
        if (predicate_adapter.at(d, h, w, 0)) {
          int idx = InputIterator::Tile::kC *
                    (w + InputIterator::Iterations::kW * (h + InputIterator::Iterations::kH * d));

          Load<typename Fragment::Element, InputIterator::Tile::kC, InputIterator::kMemorySpace>::
              load(reinterpret_cast<typename InputIterator::AccessType &>(fragment[idx]),
                   iterator.data(),
                   offset);
        }
      }
    }
  }
}

/// Loads a fragment from an input iterator
template <typename InputIterator, typename Fragment>
CUTLASS_HOST_DEVICE void iterator_load_post_increment(InputIterator &iterator,
                                                      Fragment &fragment,
                                                      typename InputIterator::Index offset = 0) {
  TrivialPredicateTileAdapter pred;
  iterator_load_post_increment(iterator, fragment, offset, pred);
}

/// Loads a fragment from an input iterator
template <typename InputIterator, typename Fragment, typename ConstPredicateAdapter>
CUTLASS_HOST_DEVICE void iterator_load_post_increment(InputIterator &iterator,
                                                      Fragment &fragment,
                                                      ConstPredicateAdapter pred_it) {
  iterator_load_post_increment(iterator, fragment, 0, pred_it);
}

template <typename InputIterator, typename Fragment, typename ConstPredicateAdapter>
CUTLASS_HOST_DEVICE void iterator_load(InputIterator const &_iterator,
                                       Fragment &fragment,
                                       typename InputIterator::Index offset,
                                       ConstPredicateAdapter predicate_adapter) {
  InputIterator iterator(_iterator);
  iterator_load_post_increment(iterator, fragment, offset, predicate_adapter);
}

/// Loads a fragment from an input iterator
template <typename InputIterator, typename Fragment>
CUTLASS_HOST_DEVICE void iterator_load(InputIterator const &iterator,
                                       Fragment &fragment,
                                       typename InputIterator::Index offset = 0) {
  TrivialPredicateTileAdapter pred;
  iterator_load(iterator, fragment, offset, pred);
}

/// Loads a fragment from an input iterator
template <typename InputIterator, typename Fragment, typename ConstPredicateAdapter>
CUTLASS_HOST_DEVICE void iterator_load(InputIterator const &iterator,
                                       Fragment &fragment,
                                       ConstPredicateAdapter pred_it) {
  iterator_load(iterator, fragment, 0, pred_it);
}

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Stores a fragment to an output iterator
template <typename OutputIterator, typename Fragment>
CUTLASS_HOST_DEVICE void iterator_store(OutputIterator &iterator, Fragment &fragment) {
  typename OutputIterator::FragmentIterator frag_iterator(fragment);
  for (int d = 0; d < OutputIterator::Iterations::kD; ++d) {
    for (int h = 0; h < OutputIterator::Iterations::kH; ++h) {
      for (int w = 0; w < OutputIterator::Iterations::kW; ++w) {
        if (iterator.valid(d, h, w, 0)) {
          iterator.set(reinterpret_cast<typename OutputIterator::AccessType const &>(
                           frag_iterator.at(d, h, w, 0)),
                       d,
                       h,
                       w,
                       0);
        }
        if (w < OutputIterator::Iterations::kW - 1) {
          iterator.inc_w();
        }
      }
      if (h < OutputIterator::Iterations::kH - 1) {
        iterator.inc_h();
      }
    }
    if (d < OutputIterator::Iterations::kD - 1) {
      iterator.inc_d();
    }
  }
  iterator.inc_advance();
}

/// Stores a fragment to a shared memory output iterator
template <typename OutputIterator, typename Fragment>
CUTLASS_DEVICE void shared_iterator_store(OutputIterator &iterator, Fragment const &fragment) {
  typename OutputIterator::FragmentConstIterator frag_iterator(fragment);
  for (int d = 0; d < OutputIterator::Iterations::kD; ++d) {
    for (int h = 0; h < OutputIterator::Iterations::kH; ++h) {
      for (int w = 0; w < OutputIterator::Iterations::kW; ++w) {
        for (int c = 0; c < OutputIterator::Iterations::kC; ++c) {
          int const offset =
              ComputeOffsetFromStrides<typename OutputIterator::ImmediateOffsetStrides>::get(
                  d, h, w, c);

          FragmentStore<OutputIterator::kIteratorFragment,
                        OutputIterator::Tile::kC,
                        typename OutputIterator::Scalar,
                        OutputIterator::kMemorySpace,
                        typename OutputIterator::FragmentElement,
                        OutputIterator::Tile::kW>::store(frag_iterator.at(d, h, w, c),
                                                         iterator.data(),
                                                         offset);
        }
      }
    }
  }
}

////////////////////////////////////////////////////////////////////////////////////////////////////

/// Stores a fragment to an output iterator, masked by a predicate iterator
template <typename OutputIterator, typename Fragment, typename ConstPredicateAdapter>
CUTLASS_HOST_DEVICE void iterator_store_post_increment(OutputIterator &iterator,
                                                       Fragment const &fragment,
                                                       typename OutputIterator::Index offset,
                                                       ConstPredicateAdapter predicate_adapter) {
  for (int d = 0; d < OutputIterator::Iterations::kD; ++d, iterator.inc_d()) {
    for (int h = 0; h < OutputIterator::Iterations::kH; ++h, iterator.inc_h()) {
      for (int w = 0; w < OutputIterator::Iterations::kW; ++w, iterator.inc_w()) {
        if (predicate_adapter.at(d, h, w, 0)) {
          int idx = OutputIterator::Tile::kC *
                    (w + OutputIterator::Iterations::kW * (h + OutputIterator::Iterations::kH * d));

          Store<typename Fragment::Element,
                OutputIterator::Tile::kC,
                OutputIterator::kMemorySpace>::
              store(reinterpret_cast<typename OutputIterator::AccessType const &>(fragment[idx]),
                    iterator.data(),
                    offset);
        }
      }
    }
  }
}

/// Stores a fragment to an output iterator
template <typename OutputIterator, typename Fragment>
CUTLASS_HOST_DEVICE void iterator_store_post_increment(OutputIterator &iterator,
                                                       Fragment const &fragment,
                                                       typename OutputIterator::Index offset = 0) {
  TrivialPredicateTileAdapter pred;
  iterator_store_post_increment(iterator, fragment, offset, pred);
}

/// Stores a fragment to an output iterator
template <typename OutputIterator, typename Fragment, typename ConstPredicateAdapter>
CUTLASS_HOST_DEVICE void iterator_store_post_increment(OutputIterator &iterator,
                                                       Fragment const &fragment,
                                                       ConstPredicateAdapter pred_it) {
  iterator_store_post_increment(iterator, fragment, 0, pred_it);
}

/// Stores a fragment to an output iterator, masked by a predicate iterator
template <typename OutputIterator, typename Fragment, typename ConstPredicateAdapter>
CUTLASS_HOST_DEVICE void iterator_store(OutputIterator const &_iterator,
                                        Fragment const &fragment,
                                        typename OutputIterator::Index offset,
                                        ConstPredicateAdapter predicate_adapter) {
  OutputIterator iterator(_iterator);
  iterator_store_post_increment(iterator, fragment, offset, predicate_adapter);
}

/// Stores a fragment to an output iterator
template <typename OutputIterator, typename Fragment>
CUTLASS_HOST_DEVICE void iterator_store(OutputIterator const &iterator,
                                        Fragment const &fragment,
                                        typename OutputIterator::Index offset = 0) {
  TrivialPredicateTileAdapter pred;
  iterator_store(iterator, fragment, offset, pred);
}

/// Stores a fragment to an output iterator
template <typename OutputIterator, typename Fragment, typename ConstPredicateAdapter>
CUTLASS_HOST_DEVICE void iterator_store(OutputIterator const &iterator,
                                        Fragment const &fragment,
                                        ConstPredicateAdapter pred_it) {
  iterator_store(iterator, fragment, 0, pred_it);
}

///////////////////////////////////////////////////////////////////////////////////////////////////

}  // namespace cutlass
