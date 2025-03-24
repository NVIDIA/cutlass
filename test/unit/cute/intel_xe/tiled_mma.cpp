/***************************************************************************************************
 * Copyright (c) 2025 - 2025 Codeplay Software Ltd. All rights reserved.
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


#include "cute/atom/mma_atom.hpp"

#include "cutlass_unit_test.h"

using namespace cute;

template <typename MMA_Atom, typename CTATileShape, typename SubgroupLayout, typename ExpectedTiledMMA>
void check_tiled_mma(){
  using TiledMMA = typename TiledMMAHelper<MMA_Atom, Layout<CTATileShape>, SubgroupLayout>::TiledMMA;
  static_assert(std::is_same_v<TiledMMA, ExpectedTiledMMA>, "Error in construction of contiguous tiled MMA");
};

TEST(PVC_CuTe_Xe, tiled_mma_1) {

  using TileShape = Shape<_256, _256, _32>;
  using SubgroupLayout = Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>;
  using ExpectedTiledMMA = TiledMMA<
      MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
      Layout<Shape<_8, _4, _1>, Stride<_4, _1, _0>>,
      const Tile<Layout<Shape<_8, _8, _4>, Stride<_1, _32, _8>>,
                 Layout<Shape<_16, _4, _4>, Stride<_1, _64, _16>>,
                 decltype(coalesce(Layout<Shape<_32>, Stride<_1>>{}))>>;
  check_tiled_mma<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, TileShape,
                  SubgroupLayout, ExpectedTiledMMA>();
}

TEST(PVC_CuTe_Xe, tiled_mma_2) {

  using TileShape = Shape<_128, _64, _32>;
  using SubgroupLayout = Layout<Shape<_4, _2, _1>, Stride<_2, _1, _0>>;
  using ExpectedTiledMMA = TiledMMA<
      MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>,
      Layout<Shape<_4, _2, _1>, Stride<_2, _1, _0>>,
      const Tile<Layout<Shape<_8, _4, _4>, Stride<_1, _32, _8>>,
                 Layout<Shape<_16, _2, _2>, Stride<_1, _32, _16>>,
                 decltype(coalesce(Layout<Shape<_32>, Stride<_1>>{}))>>;
  check_tiled_mma<MMA_Atom<XE_8x16x16_F32BF16BF16F32_TT>, TileShape,
                  SubgroupLayout, ExpectedTiledMMA>();
}
