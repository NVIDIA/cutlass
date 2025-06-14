/***************************************************************************************************
 * Copyright (c) 2024 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
 * SPDX-License-Identifier: BSD-3-Clause
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this
 * list of conditions and the following disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice,
 * this list of conditions and the following disclaimer in the documentation
 * and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
#pragma once


#include "cutlass/cutlass.h"
#include "cute/tensor.hpp"

namespace cutlass::fmha::collective {

using namespace cute;

struct NoMask {
  template<class BlkCoord, class TileShape, class ProblemSize>
  CUTLASS_DEVICE
  int get_trip_count(
      BlkCoord const& blk_coord,
      TileShape const& tile_shape,
      ProblemSize const& problem_size) {

    return ceil_div(get<1>(problem_size), get<1>(tile_shape));
  }

  template<class BlkCoord, class TileShape, class ProblemSize>
  CUTLASS_DEVICE
  int get_masked_trip_count(
      BlkCoord const& blk_coord,
      TileShape const& tile_shape,
      ProblemSize const& problem_size) {

    return 0;
  }

  template<class BlkCoord, class TileShape, class ProblemSize>
  CUTLASS_DEVICE
  int get_unmasked_trip_count(
      BlkCoord const& blk_coord,
      TileShape const& tile_shape,
      ProblemSize const& problem_size) {

    return get_trip_count(blk_coord, tile_shape, problem_size);
  }

  template<class AccQK, class IndexQK, class ProblemSize>
  CUTLASS_DEVICE
  void apply_mask(
      AccQK& acc_qk,
      IndexQK const& index_qk,
      ProblemSize const& problem_size) {

    return;
  }
};

struct ResidualMask : NoMask {

  using Base = NoMask;

  template <class BlkCoord, class TileShape, class ProblemSize>
  CUTLASS_DEVICE int get_masked_trip_count(
      BlkCoord const& blk_coord,
      TileShape const& tile_shape,
      ProblemSize const& problem_size) {

    if (get<1>(problem_size) % get<1>(tile_shape) != 0) {
      return 1;
    }
    return 0;
  }

  template<class BlkCoord, class TileShape, class ProblemSize>
  CUTLASS_DEVICE
  int get_unmasked_trip_count(
      BlkCoord const& blk_coord,
      TileShape const& tile_shape,
      ProblemSize const& problem_size) {

    // if the sequence length does not divide the tile size evenly
    if (get<1>(problem_size) % get<1>(tile_shape) != 0) {
      return get_trip_count(blk_coord, tile_shape, problem_size) - 1;
    }
    return get_trip_count(blk_coord, tile_shape, problem_size);
  }

  template<class AccQK, class IndexQK, class ProblemSize>
  CUTLASS_DEVICE
  void apply_mask(
      AccQK& acc_qk,
      IndexQK const& index_qk,
      ProblemSize const& problem_size) {

    // This is useful is seqlen_k % kBlockN != 0 since it masks
    // the remaining elements out from softmax.
    // d % kHeadDim != 0 or seqlen_q % kBlockM do not suffer from similar
    // issues as they are transparently taken care of by TMA and the
    // epilogue, if it is instantiated with predication support.
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < size(acc_qk); i++) {
      auto pos = index_qk(i);
      if (get<1>(pos) >= get<1>(problem_size)) {
        acc_qk(i) = -INFINITY;
      }
    }
  }
};

struct CausalMask : NoMask {

  using Base = NoMask;

  template<class BlkCoord, class TileShape, class ProblemSize>
  CUTLASS_DEVICE
  int get_trip_count(
      BlkCoord const& blk_coord,
      TileShape const& tile_shape,
      ProblemSize const& problem_size) {

    // See note below on different ways to think about causal attention
    // Again, we'd add the offset_q into the max_blocks_q calculation
    int max_blocks_k = Base::get_trip_count(blk_coord, tile_shape, problem_size);
    int max_blocks_q = ceil_div((get<0>(blk_coord) + 1) * get<0>(tile_shape), get<1>(tile_shape));
    return std::min(max_blocks_k, max_blocks_q);
  }

  template<class BlkCoord, class TileShape, class ProblemSize>
  CUTLASS_DEVICE
  int get_masked_trip_count(
      BlkCoord const& blk_coord,
      TileShape const& tile_shape,
      ProblemSize const& problem_size) {

    return ceil_div(get<0>(tile_shape), get<1>(tile_shape));
  }

  template<class BlkCoord, class TileShape, class ProblemSize>
  CUTLASS_DEVICE
  int get_unmasked_trip_count(
      BlkCoord const& blk_coord,
      TileShape const& tile_shape,
      ProblemSize const& problem_size) {

    return get_trip_count(blk_coord, tile_shape, problem_size) - get_masked_trip_count(blk_coord, tile_shape, problem_size);
  }

  template<class AccQK, class IndexQK, class ProblemSize>
  CUTLASS_DEVICE
  void apply_mask(
      AccQK& acc_qk,
      IndexQK const& index_qk,
      ProblemSize const& problem_size) {

    // There are two ways to do causal if N_Q != N_K
    // (1) is to assume that the Q is at the beginning of the matrix
    //    - this is what we demonstrate here
    // (2) is that it is at the end of the matrix
    //    - this is usually what we want for inference settings
    //      where we only compute the next row and use cache for the rest
    //    - if you'd like this, you only need to add an offset like so:
    //      get<0>(pos) + offset_q < get<1>(pos)
    CUTLASS_PRAGMA_UNROLL
    for (int i = 0; i < size(acc_qk); i++) {
      auto pos = index_qk(i);
      if ((get<0>(pos) < get<1>(pos)) || (get<1>(pos) >= get<1>(problem_size))) {
        acc_qk(i) = -INFINITY;
      }
    }
  }

};

struct VariableLength {
  int max_length;
  int* cumulative_length = nullptr;

  CUTE_HOST_DEVICE operator int() const {
    return max_length;
  }
};

template<class T> struct is_variable_length : std::false_type {};
template<> struct is_variable_length<VariableLength> : std::true_type {};
template<class T> constexpr bool is_variable_length_v = is_variable_length<T>::value;

template<class Shape, class Idx>
CUTE_HOST_DEVICE
constexpr auto
apply_variable_length(Shape const& shape, Idx const& idx) {
  return transform_leaf(shape, [&](auto const& s) {
    if constexpr (is_variable_length_v<remove_cvref_t<decltype(s)>>) {
      return s.cumulative_length[idx+1] - s.cumulative_length[idx];
    }
    else {
      return s;
    }
  });
}

template<class Shape, class Coord, class Idx>
CUTE_HOST_DEVICE
constexpr auto
apply_variable_length(Shape const& shape, Coord const& coord, Idx const& idx) {
  auto new_shape = apply_variable_length(shape, idx);
  auto new_coord = transform_leaf(shape, coord, [&](auto const& s, auto const& c) {
    if constexpr (is_variable_length_v<remove_cvref_t<decltype(s)>>) {
      return cute::make_tuple(c, s.cumulative_length[idx]);
    }
    else {
      return c;
    }
  });
  return cute::make_tuple(new_shape, new_coord);
}

}  // namespace cutlass::fmha::collective

namespace cute {

template<>
struct is_integral<cutlass::fmha::collective::VariableLength> : true_type {};

CUTE_HOST_DEVICE
void print(cutlass::fmha::collective::VariableLength a) {
  printf("Varlen<%d, %p>", a.max_length, a.cumulative_length);
}

}
