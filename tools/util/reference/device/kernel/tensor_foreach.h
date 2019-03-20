/***************************************************************************************************
 * Copyright (c) 2017-2019, NVIDIA CORPORATION.  All rights reserved.
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

#pragma once

#include "cutlass/cutlass.h"
#include "cutlass/coord.h"

namespace cutlass {
namespace reference {
namespace device {
namespace kernel {

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Defines several helpers
namespace detail {

/// Helper to perform for-each operation
template <typename Func, int Rank, int RankRemaining>
struct TensorForEachHelper {

  /// Constructor for general rank
  __inline__ __device__
  TensorForEachHelper(Func &func, Coord<Rank> const &size, Coord<Rank> &coord, int64_t index) {

    int64_t product = 1;

    CUTLASS_PRAGMA_UNROLL
    for (int i = Rank - RankRemaining; i < Rank; ++i) {
      product *= size[i];
    }

    coord[Rank - 1 - RankRemaining] = index / product;
    int64_t remaining = index % product;
    
    TensorForEachHelper<Func, Rank, RankRemaining-1>(func, size, coord, remaining);
  }
};

/// Helper to perform for-each operation
template <typename Func, int Rank>
struct TensorForEachHelper<Func, Rank, 0> {

  /// Constructor for fastest chaning rank
  __inline__ __device__
  TensorForEachHelper(Func &func, Coord<Rank> const &size, Coord<Rank> &coord, int64_t index) {

    coord[Rank - 1] = index;

    if (coord < size) {
      func(coord);
    }
  }
};

} // namespace detail

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Helper to perform for-each operation
template <typename Func, int Rank, typename Params>
__global__ void TensorForEach(Coord<Rank> size, Params params = Params()) {

  Func func(params);

  int64_t index = threadIdx.x + blockIdx.x * blockDim.x;
  int64_t max_index = 1;

  CUTLASS_PRAGMA_UNROLL
  for (int i = 0; i < Rank; ++i) {
    max_index *= size[i];
  }

  CUTLASS_PRAGMA_NO_UNROLL
  while  (index < max_index) {
    Coord<Rank> coord;

    detail::TensorForEachHelper<Func, Rank, Rank - 1>(func, size, coord, index); 
    index += blockDim.x * gridDim.x;
  }
}

///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace kernel
} // namespace device
} // namespace reference
} // namespace cutlass

