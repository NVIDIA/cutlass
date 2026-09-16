/***************************************************************************************************
 * Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

/*! \file
    \brief Blocked Scale configs specific for SM107 BlockScaled MMA
*/

#pragma once

#include "cutlass/layout/matrix.h"

#include "cute/int_tuple.hpp"
#include "cute/atom/mma_traits_sm107.hpp"

#include "cutlass/detail/sm100_blockscaled_layout.hpp"

namespace cutlass::detail {

/////////////////////////////////////////////////////////////////////////////////////////////////
using namespace cute;

template<int SFVecSize_>
struct Sm107BlockScaledConfig {
  // We are creating the SFA and SFB tensors' layouts in the collective since they always have the same layout.
  // k-major order
  static constexpr int SFVecSize = SFVecSize_;
  using Sm1xxBlkScaledChunk = Sm1xxBlockScaledBasicChunk<SFVecSize>;
  using Blk_MN = typename Sm1xxBlkScaledChunk::Blk_MN;
  using Blk_SF = typename Sm1xxBlkScaledChunk::Blk_SF; 
  using SfAtom = typename Sm1xxBlkScaledChunk::SfAtom;

  using LayoutSF = decltype(tile_to_shape(SfAtom{}, make_shape(int(0),int(0),int(0)), Step<_2,_1,_3>{}));

  CUTE_HOST_DEVICE
  static constexpr auto
  deduce_layoutSFA() {
    return LayoutSF{};
  }

  CUTE_HOST_DEVICE
  static constexpr auto
  deduce_layoutSFB() {
    return LayoutSF{};
  }

    // The following function is provided for user fill dynamic problem size to the layout_SFA.
  template < class ProblemShape, class LayoutSFA = LayoutSF>
  CUTE_HOST_DEVICE
  static constexpr auto
  tile_atom_to_shape_SFA(ProblemShape problem_shape, LayoutSFA layout_sfa = LayoutSFA{}) {
    if constexpr (rank(ProblemShape{}) == 3) {
      auto [M, N, K] = problem_shape;
      return tile_to_shape(SfAtom{}, make_shape(M,K), Step<_2,_1>{});
    }
    else {
      auto [M, N, K, L] = problem_shape;
      return tile_to_shape(SfAtom{}, make_shape(M,K,L), Step<_2,_1,_3>{});
    }
  }

  // The following function is provided for user fill dynamic problem size to the layout_SFB.
  template <class ProblemShape, class LayoutSFB = LayoutSF>
  CUTE_HOST_DEVICE
  static constexpr auto
  tile_atom_to_shape_SFB(ProblemShape problem_shape, LayoutSFB layout_sfb = LayoutSFB{}) {
    if constexpr (rank(ProblemShape{}) == 3) {
      auto [M, N, K] = problem_shape;
      return tile_to_shape(SfAtom{}, make_shape(N,K), Step<_2,_1>{});
    }
    else {
      auto [M, N, K, L] = problem_shape;
      return tile_to_shape(SfAtom{}, make_shape(N,K,L), Step<_2,_1,_3>{});
    }
  }

  template<class TiledMma, class TileShape_MNK>
  CUTE_HOST_DEVICE
  static constexpr auto
  deduce_smem_layoutSFA(TiledMma tiled_mma, TileShape_MNK tileshape_mnk) {
    // CTA-level MMA tile shape
    constexpr auto tile_shape_mk =
      make_shape(size<0>(TileShape_MNK{}) / size<0>(typename TiledMma::ThrLayoutVMNK{}),
                 size<2>(TileShape_MNK{}));

    // CTA-level MMA instruction shape (MMA_INST_M, MMA_INST_K)
    constexpr auto mma_shape_mk =
      make_shape(size<0>(typename TiledMma::AtomShape_MNK{}) / size<0>(typename TiledMma::ThrLayoutVMNK{}),
                 size<2>(typename TiledMma::AtomShape_MNK{}));

    // Tiling the CTA-level tile shape with SF atoms, first accross the K-mode, and then M-mode
    auto smem_layout_tiled = tile_to_shape(SfAtom{}, tile_shape_mk, Step<_2, _1>{});

    // Reorganizing the shared memory layout for easier indexing and slicing
    // (((ATOM_SF_M, 1), (VS, NSF_0, NSF_1)), MMA_M, MMA_K), where
    // NSF0, (and NSF1) = 2, (no NSF1)    (if Rubin FP8 and VS=32),
    //                  = 4, 1            (if Rubin FP4 and VS=32),
    //                  = 4, 2            (if Rubin FP4 and VS=16)
    auto smem_layout_divided = tiled_divide(smem_layout_tiled, mma_shape_mk);

    // (((ATOM_SF_M, 1), (VS, (NSF0, NSF1))), MMA_M, MMA_K), where
    auto smem_layout =
        logical_divide(smem_layout_divided,
                       make_tile(make_shape(Blk_MN{}, Int<SFVecSize>{}), _, _));
    return smem_layout;
  }

  template<class TiledMma, class TileShape_MNK>
  CUTE_HOST_DEVICE
  static constexpr auto
  deduce_smem_layoutSFB(TiledMma tiled_mma, TileShape_MNK tileshape_mnk) {
    // CTA-level MMA tile shape (TILE_N, TILE_K)
    constexpr auto tile_shape_nk =
      make_shape(size<1>(TileShape_MNK{}), size<2>(TileShape_MNK{}));

    // CTA-level MMA instruction shape (MMA_INST_N, MMA_INST_K)
    constexpr auto mma_shape_nk =
      make_shape(size<1>(typename TiledMma::AtomShape_MNK{}),
                 size<2>(typename TiledMma::AtomShape_MNK{}));

    // Tiling the CTA-level tile shape with SF atoms, first accross the K-mode, and then N-mode
    auto smem_layout_tiled = tile_to_shape(SfAtom{}, tile_shape_nk, Step<_2, _1>{});

    // Reorganizing the shared memory layout for easier indexing and slicing
    // (((ATOM_SF_N, 1), (VS, NSF_0, NSF_1)), MMA_N, MMA_K), where
    // NSF0, (and NSF1) = 2, (no NSF1)    (if Rubin FP8 and VS=32),
    //                  = 4, 1            (if Rubin FP4 and VS=32),
    //                  = 4, 2            (if Rubin FP4 and VS=16)
    auto smem_layout_divided = tiled_divide(smem_layout_tiled, mma_shape_nk);

    // (((ATOM_SF_N, 1), (VS, (NSF0, NSF1))), MMA_N, MMA_K), where
    auto smem_layout =
        logical_divide(smem_layout_divided,
                       make_tile(make_shape(Blk_MN{}, Int<SFVecSize>{}), _, _));
    return smem_layout;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass::detail
