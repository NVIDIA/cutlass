/***************************************************************************************************
 * Copyright (c) 2017 - 2023 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Templates implementing how threads are mapped to a given tile.
*/

#pragma once

#include "cute/arch/mma_sm90_gmma.hpp"
/////////////////////////////////////////////////////////////////////////////////////////////////

namespace cutlass {
namespace transform {
namespace collective {

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace detail {
using namespace cute;

template <bool Transpose, class SmemLayoutAtom, class ElementType>
constexpr auto
gmma_smem_transpose_or_passthrough() {
  if constexpr (Transpose) {
    if constexpr (cute::is_same_v<GMMA::Layout_MN_SW128_Atom<ElementType>, SmemLayoutAtom>) {
      return GMMA::Layout_K_SW128_Atom<ElementType>{};
    }
    else if constexpr (cute::is_same_v<GMMA::Layout_MN_SW64_Atom<ElementType>, SmemLayoutAtom>) {
      return GMMA::Layout_K_SW64_Atom<ElementType>{};
    }
    else if constexpr (cute::is_same_v<GMMA::Layout_MN_SW32_Atom<ElementType>, SmemLayoutAtom>) {
      return GMMA::Layout_K_SW32_Atom<ElementType>{};
    }
    else if constexpr (cute::is_same_v<GMMA::Layout_MN_INTER_Atom<ElementType>, SmemLayoutAtom>) {
      return GMMA::Layout_K_INTER_Atom<ElementType>{};
    }
    else {
      static_assert(cutlass::detail::dependent_false<SmemLayoutAtom>, "Unsupported Layout_SW_Atom for B SMEM transposition");
    }
  }
  else {
    return SmemLayoutAtom{};
  }
}

template <class SmemCopyAtom, class ElementType>
constexpr auto
use_universal_transposition() {
  if constexpr (sizeof(ElementType) == 1) {
    return !cute::is_same_v<GMMA::Layout_MN_SW128_Atom<ElementType>, SmemCopyAtom>;
  }
  else if constexpr (sizeof(ElementType) == 4){
    // Only universal transposition can handle SW64 and Non swizzle SMEM layout
    if constexpr (cute::is_same_v<GMMA::Layout_MN_SW64_Atom<ElementType>, SmemCopyAtom> ||
                  cute::is_same_v<GMMA::Layout_MN_INTER_Atom<ElementType>, SmemCopyAtom>) {
      return true;
    }
    else {
      return false;
    }
  }
  else {
    static_assert(cutlass::detail::dependent_false<ElementType>, "Unsupported ElementType for B SMEM transposition");
  }
}

/// Transpose B operand in SMEM
template <
  class TensorSmemB,
  class TensorTransposedSmemB,
  class PipelineState,
  class TiledMma,
  class SmemLayoutB,
  class SmemLayoutAtomB,
  class ElementB>
CUTLASS_DEVICE void
transpose_b_operand (
  TensorSmemB const& sB,
  TensorTransposedSmemB const& gmma_sB,
  PipelineState const& smem_pipe_read,
  int warp_idx, int warp_group_thread_idx,
  TiledMma, SmemLayoutB, SmemLayoutAtomB, ElementB)
{
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Important terms:
  /// WarpgroupTileSize         : The warp_group_tile size (WarpgroupTileSize x WarpgroupTileSize) a warp group would transpose
  /// WarpTileSize              : The warp_tile size (WarpTile x WarpTile) a warp would transpose
  /// Step                      : The number of steps a warp group takes to complete the entire warp_group_tile transposition.
  /// WarpTileNCoordLUT         : The look up table to store the n-dim coords used by the warps
  /// WarpTileKCoordLUT         : The look up table to store the k-dim coords used by the warps
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  static_assert(size(TiledMma{}) == NumThreadsPerWarpGroup, "Wrong thread number for TransposeB");
  constexpr int WarpgroupTileSize = size<1>(SmemLayoutB{});  // A warp group tile would process entire Smem K.
  constexpr int NumWarpsPerWarpGroup = NumThreadsPerWarpGroup / NumThreadsPerWarp;

  constexpr int BytesPerSmemSwizzleUnit = 16;
  constexpr int WarpThreadShapeN = BytesPerSmemSwizzleUnit / sizeof(ElementB);
  constexpr int WarpThreadShapeK = NumThreadsPerWarp / WarpThreadShapeN;

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Optimized transposition, less regs per thread than universal approach, need warp sync between load and store
  /// TF32/FP32 would use the 2-steps approach. Fp8/Int8 would use 8-steps approach.
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  if constexpr (!detail::use_universal_transposition<SmemLayoutAtomB, ElementB>()) {
    constexpr int Steps                       = sizeof(ElementB) == 1 ? 8 : 2;
    constexpr int NumWarpTilePerWarpgroupTile = NumWarpsPerWarpGroup * (Steps == 8 ? 2 : 1);

    constexpr int WarpTileSize                = WarpgroupTileSize / NumWarpTilePerWarpgroupTile;
    static_assert(WarpTileSize >= WarpThreadShapeN && WarpTileSize >= WarpThreadShapeK, "Invaild warp thread shape." );
    constexpr auto WarpThreadLayout           = make_layout(make_shape(Int<WarpThreadShapeN>{}, Int<WarpThreadShapeK>{}));
    constexpr int TilesPerWarp                = 2;                     // Each Warp would process 2 warp_tiles in one step.
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    /// A warp group uses 2 or 8 steps to transpose the whole WarpgroupTileSize x WarpgroupTileSize.
    /// In each step, one warp would hold two warp_tiles.
    ///  Step 0:                Step 1:
    ///  W0 W1 W2 W3            -- -- -- --
    ///  W1 W0 -- --            -- -- W3 W2
    ///  W2 -- -- --            -- W3 W0 W1
    ///  W3 -- -- --            -- W2 W1 W1
    /// OR:
    ///  Divide a warp_group_tile into 8x8 warp_tiles to futher reduce the reg usage.
    ///  Step 0:                   Step 1:                   Step 2:                   Step 3:
    ///  W0 W1 W2 W3 -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --
    ///  W1 W0 -- -- -- -- -- --   -- -- W3 W2 -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --
    ///  W2 -- -- -- -- -- -- --   -- W3 W0 W1 -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --
    ///  W3 -- -- -- -- -- -- --   -- W2 W1 W0 -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --
    ///  -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- W0 W1 W2 W3   -- -- -- -- -- -- -- --
    ///  -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- W1 W0 -- --   -- -- -- -- -- -- W3 W2
    ///  -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- W2 -- -- --   -- -- -- -- -- W3 W0 W1
    ///  -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- W3 -- -- --   -- -- -- -- -- W2 W1 W0
    ///
    ///  Step 4:                   Step 5:                   Step 6:                   Step 7:
    ///  -- -- -- -- W0 W1 W2 W3   -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --
    ///  -- -- -- -- -- -- -- --   -- -- -- -- W0 W1 W2 W3   -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --
    ///  -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- W0 W1 W2 W3   -- -- -- -- -- -- -- --
    ///  -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- -- -- -- --   -- -- -- -- W0 W1 W2 W3
    ///  W0 -- -- -- -- -- -- --   -- W0 -- -- -- -- -- --   -- -- W0 -- -- -- -- --   -- -- -- W0 -- -- -- --
    ///  W1 -- -- -- -- -- -- --   -- W1 -- -- -- -- -- --   -- -- W1 -- -- -- -- --   -- -- -- W1 -- -- -- --
    ///  W2 -- -- -- -- -- -- --   -- W2 -- -- -- -- -- --   -- -- W2 -- -- -- -- --   -- -- -- W2 -- -- -- --
    ///  W3 -- -- -- -- -- -- --   -- W3 -- -- -- -- -- --   -- -- W3 -- -- -- -- --   -- -- -- W3 -- -- -- --
    ///
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    ///
    /// Fully static coord LUT to avoid extra register use.
    /// [warp_id][step][warp_tile][n / k]
    /// Step 0            Step 1         Step 2          Step 3          Step 4          Step 5         Step 6           Step 7
    /// {{{0,0}, {1,1}}, {{2,2}, {3,3}}, {{4,4}, {5,5}}, {{6,6}, {7,7}}, {{4,0}, {0,4}}, {{4,1}, {1,4}}, {{4,2}, {2,4}}, {{4,3}, {3,4}}}, // W0
    /// {{{1,0}, {0,1}}, {{3,2}, {2,3}}, {{5,4}, {4,5}}, {{7,6}, {6,7}}, {{5,0}, {0,5}}, {{5,1}, {1,5}}, {{5,2}, {2,5}}, {{5,3}, {3,5}}}, // W1
    /// {{{2,0}, {0,2}}, {{3,1}, {1,3}}, {{6,4}, {4,6}}, {{7,5}, {5,7}}, {{6,0}, {0,6}}, {{6,1}, {1,6}}, {{6,2}, {2,6}}, {{6,3}, {3,6}}}, // W2
    /// {{{3,0}, {0,3}}, {{2,1}, {1,2}}, {{7,4}, {4,7}}, {{6,5}, {5,6}}, {{7,0}, {0,7}}, {{7,1}, {1,7}}, {{7,2}, {2,7}}, {{7,3}, {3,7}}}, // W3
    ///
    /// Encoding the coord of warp tile0 into two int64_t values.
    /// Only encoding Step 0 ~ Step 4, since Step 5 ~ Step 7 have a straightforward pattern.
    /// Only encoding warp tile0, since the coords of warp tile1 could be easily deduced from warp tile0.
    /// The 2-step transposition and the 8-step transposition share the same encoding.
    ///
    //////////////////////////////////////////////////////////////////////////////////////////////////////////////
    constexpr int64_t WarpTileNCoordLUT = 06723763275316420;
    constexpr int64_t WarpTileKCoordLUT = 05410541064206420;
    constexpr int NumStepsEncoded       = 4;                             // Only encoding first 4 steps into LUT.
    constexpr int MaskPerStep           = 07;                            // Each step is encoded into 3bits,
    constexpr int NumBitsPerStep        = 3;
    constexpr int MaskPerWarp           = 07777;                         // Each warp has 4 steps(12 bits)
    constexpr int NumBitsPerWarp        = 12;

    const int current_warp_tile_n_coord_LUT  = (WarpTileNCoordLUT >> (warp_idx * NumBitsPerWarp)) & MaskPerWarp;
    const int current_warp_tile_k_coord_LUT  = (WarpTileKCoordLUT >> (warp_idx * NumBitsPerWarp)) & MaskPerWarp;

    // Number of warp_group_tiles
    static_assert(size<0>(SmemLayoutB{}) % WarpgroupTileSize == 0,
      "Copy size must evenly divide SMEM tile.");
    constexpr int WarpgroupTileNum = size<0>(SmemLayoutB{}) / WarpgroupTileSize;

    // Divide entire SMEM to multiple warp_tiles
    constexpr auto WarpTileShape = make_shape(Int<WarpTileSize>(), Int<WarpTileSize>());
    Tensor s_tile                = zipped_divide(     sB(_,_,smem_pipe_read.index()), WarpTileShape);
    Tensor s_tile_transposed     = zipped_divide(gmma_sB(_,_,smem_pipe_read.index()), WarpTileShape);

    // Get copy tile
    auto sB_tiled_copy = make_tiled_copy(
      Copy_Atom<DefaultCopy, ElementB>{},
      WarpThreadLayout,     // thr_layout
      Layout<_1>{}          // val_layout
    );
    static_assert(size(sB_tiled_copy) * NumWarpsPerWarpGroup == size(TiledMma{}), "Wrong thread number in TiledCopy.");
    auto sB_thr_copy = sB_tiled_copy.get_thread_slice(warp_group_thread_idx % NumThreadsPerWarp);  // slice based on lane_idx

    // Construct fragments for transposition
    Tensor tmp_tCsB = sB_thr_copy.partition_S(flatten(s_tile(_, make_coord(_0{}, _0{}))));
    decltype(make_fragment_like(tmp_tCsB)) transpose_fragments[TilesPerWarp] = {
      make_fragment_like(tmp_tCsB),
      make_fragment_like(tmp_tCsB)
    };

    CUTLASS_PRAGMA_NO_UNROLL
    for (int warp_group_tile = 0; warp_group_tile < WarpgroupTileNum; ++warp_group_tile) {
      int tmp_warp_tile_n_coord_LUT = current_warp_tile_n_coord_LUT;
      int tmp_warp_tile_k_coord_LUT = current_warp_tile_k_coord_LUT;

      CUTLASS_PRAGMA_NO_UNROLL
      for (int step = 0; step < Steps; ++step) {
        // decoding the warp tile coord.
        int warp_tile0_n = step < NumStepsEncoded ? (tmp_warp_tile_n_coord_LUT & MaskPerStep) : 4 + warp_idx;
        int warp_tile0_k = step < NumStepsEncoded ? (tmp_warp_tile_k_coord_LUT & MaskPerStep) : step - 4;
        int warp_tile1_n = warp_tile0_n == warp_tile0_k ? warp_tile0_n + 1 : warp_tile0_k;
        int warp_tile1_k = warp_tile0_n == warp_tile0_k ? warp_tile0_k + 1 : warp_tile0_n;

        tmp_warp_tile_n_coord_LUT >>= NumBitsPerStep;
        tmp_warp_tile_k_coord_LUT >>= NumBitsPerStep;

        // [warp_tile][n/k]
        const int warp_tile_coord[TilesPerWarp][2] = {
          // n                                                           k
          {warp_group_tile * NumWarpTilePerWarpgroupTile + warp_tile0_n, warp_tile0_k}, // warp_tile 0
          {warp_group_tile * NumWarpTilePerWarpgroupTile + warp_tile1_n, warp_tile1_k}  // warp_tile 1
        };

        CUTLASS_PRAGMA_UNROLL
        for (int warp_tile = 0; warp_tile < TilesPerWarp; ++warp_tile) {
          Tensor tCsB = sB_thr_copy.partition_S(
            flatten(s_tile(_, make_coord(warp_tile_coord[warp_tile][0], warp_tile_coord[warp_tile][1])))
          ); // (CPY, CPY_N, CPY_K)
          copy(sB_tiled_copy, tCsB, transpose_fragments[warp_tile]);
        }

        // Make sure elements in two 8x8 warp tiles are all consumed
        __syncwarp();

        CUTLASS_PRAGMA_UNROLL
        for (int warp_tile = 0; warp_tile < TilesPerWarp; ++warp_tile) {
          Tensor tCsB_transposed = sB_thr_copy.partition_D(
            flatten(s_tile_transposed(_, make_coord(warp_tile_coord[warp_tile][0], warp_tile_coord[warp_tile][1])))
          ); // (CPY, CPY_N, CPY_K)
          copy(sB_tiled_copy, transpose_fragments[warp_tile], tCsB_transposed);
        }

      } // lock step
    } // loop warp_group_tile
  } // if not use universal transposition

  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  /// Universal transposition, need warp_group sync between load and store.
  /// The number of reg used depends on the input elementB.
  //////////////////////////////////////////////////////////////////////////////////////////////////////////////
  else {
    /*
        In one copy step, a warp group would load WarpgroupTileSize * WarpgroupTileSize tile then store to transposed location.
        In warp_group_tile, each warp holds Four WarpTileSize x WarpTileSize elements:
                  K
            ------------
          | W0 W1 W2 W3  ---
          | W0 W1 W2 W3    |
          | W0 W1 W2 W3    | --> Copy Step 0
          | W0 W1 W2 W3  ---
                ....
          | W0 W1 W2 W3  ---
          | W0 W1 W2 W3    |
          | W0 W1 W2 W3    | --> Copy Step n
          | W0 W1 W2 W3  ---
    */
    static_assert((NumThreadsPerWarpGroup % WarpThreadShapeN == 0), "Unsupported warp thread layout.");
    constexpr auto WarpgroupThreadLayout = make_layout(make_shape(Int<WarpThreadShapeN>{}, Int<NumThreadsPerWarpGroup / WarpThreadShapeN>{}));

    // Get copy tile and partition to each thread
    auto sB_tiled_copy = make_tiled_copy(
      Copy_Atom<DefaultCopy, ElementB>{},
      WarpgroupThreadLayout,                           // thr_layout
      Layout<_1>{}                                     // val_layout
    );
    static_assert(size(sB_tiled_copy) == size(TiledMma{}), "Wrong thread number in TiledCopy.");

    auto sB_thr_copy        = sB_tiled_copy.get_thread_slice(warp_group_thread_idx);
    Tensor tCsB             = sB_thr_copy.partition_S(     sB(_,_,smem_pipe_read.index())); // (CPY, CPY_N, CPY_K)
    Tensor tCsB_transposed  = sB_thr_copy.partition_D(gmma_sB(_,_,smem_pipe_read.index())); // (CPY, CPY_N, CPY_K)

    // Divide partitioned tile to limit register usage
    constexpr int  CopySteps      = size<0>(SmemLayoutB{}) / WarpgroupTileSize;
    constexpr auto CopyTileShape  = make_shape(size<0>(tCsB), Int< size<1>(tCsB) / CopySteps >{}, size<2>(tCsB));
    static_assert(size<1>(tCsB) % CopySteps == 0, "CopySteps must evenly divide rank 1 size of partitioned SMEM.");

    Tensor tCsB_copy_tile            = zipped_divide(tCsB, CopyTileShape);
    Tensor tCsB_copy_tile_transposed = zipped_divide(tCsB_transposed, CopyTileShape);
    auto   transpose_fragment        = make_fragment_like(tCsB_copy_tile(_,_0{}));

    CUTLASS_PRAGMA_NO_UNROLL
    for (int step = 0; step < CopySteps; ++step) {
      copy(sB_tiled_copy, tCsB_copy_tile(_,step), transpose_fragment);

      // Make sure all elements are read before being overwritten
      __syncthreads();

      copy(sB_tiled_copy, transpose_fragment, tCsB_copy_tile_transposed(_,step));
    }
  } // if use universal transposition

  // SMEM fence to make sure B is transposed before math
  cutlass::arch::fence_view_async_shared();
}

}; // namespace detail

/////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace collective
} // namespace transform
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////
