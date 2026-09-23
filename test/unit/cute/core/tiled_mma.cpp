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

#include "cutlass_unit_test.h"

#include <cute/tensor.hpp>
#include <cute/atom/mma_atom.hpp>
#include <cute/atom/mma_traits_sm80.hpp>

// The TV layouts of a TiledMMA must describe the same (thread, value) -> coordinate mapping as
// the corresponding ThrMMA::partition_[A|B|C], and must only map into the tile.

namespace {

template <class TiledMma, class TVLayout, class Tile, class Partition>
void
check_tv_layout(TiledMma const& mma, TVLayout const& tv, Tile const& tile_shape, Partition&& partition)
{
  using namespace cute;

  int buffer[size(Tile{})];
  Tensor tile = make_tensor(&buffer[0], make_layout(tile_shape));

  EXPECT_EQ(int(size<0>(tv)), int(size(mma)));
  EXPECT_LE(int(cosize(tv)), int(size(tile)));

  for (int t = 0; t < int(size(mma)); ++t) {
    Tensor part = partition(mma.get_slice(t), tile);
    ASSERT_EQ(int(size<1>(tv)), int(size(part)));
    for (int v = 0; v < int(size(part)); ++v) {
      EXPECT_EQ(int(tv(t,v)), int(&part(v) - &buffer[0])) << "thr_idx " << t << " val_idx " << v;
    }
  }
}

template <class TiledMma>
void
check_tiled_mma(TiledMma const& mma)
{
  using namespace cute;

  check_tv_layout(mma, mma.get_layoutC_TV(),
                  make_shape(tile_size<0>(mma), tile_size<1>(mma)),
                  [](auto const& thr_mma, auto& tile) { return thr_mma.partition_C(tile); });
  check_tv_layout(mma, mma.get_layoutA_TV(),
                  make_shape(tile_size<0>(mma), tile_size<2>(mma)),
                  [](auto const& thr_mma, auto& tile) { return thr_mma.partition_A(tile); });
  check_tv_layout(mma, mma.get_layoutB_TV(),
                  make_shape(tile_size<1>(mma), tile_size<2>(mma)),
                  [](auto const& thr_mma, auto& tile) { return thr_mma.partition_B(tile); });
}

} // end namespace

TEST(CuTe_core, TiledMma_TV_layouts_UniversalFMA)
{
  using namespace cute;
  using FMA = UniversalFMA<float, float, float>;

  check_tiled_mma(make_tiled_mma(FMA{}, Layout<Shape<_2,_3,_1>>{}));
  check_tiled_mma(make_tiled_mma(FMA{}, Layout<Shape<_2,_3,_2>>{}));
  check_tiled_mma(make_tiled_mma(FMA{}, Layout<Shape<_2,_3,_4>>{}));
  check_tiled_mma(make_tiled_mma(FMA{}, Layout<Shape<_4,_4,_2>, Stride<_4,_1,_16>>{}));
  // K-mode fastest in thread index
  check_tiled_mma(make_tiled_mma(FMA{}, Layout<Shape<_2,_2,_2>, Stride<_2,_4,_1>>{}));
  // Permuted tile with multiple values per thread
  check_tiled_mma(make_tiled_mma(FMA{}, Layout<Shape<_4,_2,_2>>{}, Tile<_16,_8,_4>{}));
}

TEST(CuTe_core, TiledMma_TV_layouts_SM80)
{
  using namespace cute;
  using MMA = SM80_16x8x16_F32F16F16F32_TN;

  check_tiled_mma(make_tiled_mma(MMA{}, Layout<Shape<_2,_2,_1>>{}, Tile<_32,_32,_16>{}));
  check_tiled_mma(make_tiled_mma(MMA{}, Layout<Shape<_2,_2,_2>>{}));
  check_tiled_mma(make_tiled_mma(MMA{}, Layout<Shape<_1,_2,_4>>{}));
  check_tiled_mma(make_tiled_mma(MMA{}, Layout<Shape<_2,_2,_2>>{}, Tile<_32,_32,_32>{}));
}
