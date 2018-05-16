/***************************************************************************************************
 * Copyright (c) 2017, NVIDIA CORPORATION.  All rights reserved.
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
    \brief Defines accessors for loading and storing fragments to memory efficiently.
*/
#pragma once

#include <cutlass/load_store.h>
#include <cutlass/vector.h>

namespace cutlass {

////////////////////////////////////////////////////////////////////////////////////////////////////

template <IteratorFragment::Kind kIteratorFragment,
          int kAccessSize,
          typename Scalar_,
          MemorySpace::Kind Memory_,
          typename FragmentElement_,
          int kStride>
struct FragmentLoad {};

template <int kAccessSize,
          typename Scalar_,
          MemorySpace::Kind Memory_,
          typename FragmentElement_,
          int kStride>
struct FragmentLoad<IteratorFragment::kWmmaMatrix,
                    kAccessSize,
                    Scalar_,
                    Memory_,
                    FragmentElement_,
                    kStride> {
  /// The output type.
  typedef FragmentElement_ AccessType;

  /// The load function.
  static CUTLASS_DEVICE void load(AccessType& value, Scalar_ const* pointer, int offset) {
    value.load(&pointer[offset], kStride);
  }
};

template <int kAccessSize,
          typename Scalar_,
          MemorySpace::Kind Memory_,
          typename FragmentElement_,
          int kStride>
struct FragmentLoad<IteratorFragment::kScalar,
                    kAccessSize,
                    Scalar_,
                    Memory_,
                    FragmentElement_,
                    kStride> {
  /// The output type.
  typedef typename Vectorize<Scalar_, kAccessSize>::Type AccessType;

  /// The load function.
  static CUTLASS_DEVICE void load(AccessType& value, Scalar_ const* pointer, int offset) {
    Load<Scalar_, kAccessSize, Memory_>::load(value, pointer, offset);
  }
};

template <IteratorFragment::Kind kIteratorFragment,
          int kAccessSize,
          typename Scalar_,
          MemorySpace::Kind Memory_,
          typename FragmentElement_,
          int kStride>
struct FragmentStore {};

template <int kAccessSize,
          typename Scalar_,
          MemorySpace::Kind Memory_,
          typename FragmentElement_,
          int kStride>
struct FragmentStore<IteratorFragment::kWmmaMatrix,
                     kAccessSize,
                     Scalar_,
                     Memory_,
                     FragmentElement_,
                     kStride> {
  /// The input type.
  typedef FragmentElement_ AccessType;

  /// The store function.
  static CUTLASS_DEVICE void store(AccessType const& value, Scalar_* pointer, int offset) {
    value.store(&pointer[offset], kStride);
  }
};

template <int kAccessSize,
          typename Scalar_,
          MemorySpace::Kind Memory_,
          typename FragmentElement_,
          int kStride>
struct FragmentStore<IteratorFragment::kScalar,
                     kAccessSize,
                     Scalar_,
                     Memory_,
                     FragmentElement_,
                     kStride> {
  /// The input type.
  typedef typename Vectorize<Scalar_, kAccessSize>::Type AccessType;

  /// The store function.
  static CUTLASS_DEVICE void store(AccessType const& value, Scalar_* pointer, int offset) {
    Store<Scalar_, kAccessSize, Memory_>::store(value, pointer, offset);
  }
};

////////////////////////////////////////////////////////////////////////////////////////////////////

}  /// namespace cutlass
