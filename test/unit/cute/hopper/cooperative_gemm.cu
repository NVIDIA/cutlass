/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include <cute/swizzle.hpp> // cute::Swizzle
#include <cute/swizzle_layout.hpp> // cute::compose(cute::Swizzle)

#include "../cooperative_gemm_common.hpp"

using namespace cute;

#define USE_FP8 1

#if USE_FP8
TEST(SM90_CuTe_Hopper, CooperativeGemmTilingF8) {

  using TA = uint8_t;
  using TB = uint8_t;
  using TC = uint32_t;

  constexpr uint32_t thread_block_size = 128;
  constexpr int MaxVecBits = 16;

  using tiled_mma_t =
      TiledMMA<
        MMA_Atom<SM80_16x8x32_S32S8S8S32_TN>,
        Layout<Shape<_2, _2, _1>, Stride<_1, _2, _0>>,
        Tile<_32, _32, _32>
      >;

  using swizzle = Swizzle<2, 4, 3>;

  // This is for A row major, B col major according to CUTLASS default configs
  using ALayout = decltype(composition(swizzle{}, Layout<Shape<_64, _64>, Stride<_64, _1>>{}));
  using BLayout = decltype(composition(swizzle{}, Layout<Shape<_64, _64>, Stride<_1, _64>>{}));

  using CLayout = decltype(make_layout(Shape<_64, _64>{}, LayoutLeft{}));

  test_cooperative_gemm<ALayout,
                        BLayout,
                        CLayout,
                        ALayout,
                        BLayout,
                        CLayout,
                        AutoVectorizingCopyWithAssumedAlignment<MaxVecBits>, // A
                        AutoVectorizingCopyWithAssumedAlignment<MaxVecBits>, // B
                        AutoVectorizingCopyWithAssumedAlignment<MaxVecBits>, // C
                        thread_block_size,
                        tiled_mma_t,
                        MaxVecBits,
                        TA,
                        TB,
                        TC>();

}

#else

TEST(SM90_CuTe_Hopper, CooperativeGemmTilingF16) {

  using TA = half_t;
  using TB = half_t;
  using TC = half_t;

  constexpr uint32_t thread_block_size = 64;
  constexpr int MaxVecBits = 16;

  using tiled_mma_t =
      TiledMMA<
        MMA_Atom<SM80_16x8x16_F16F16F16F16_TN>,
        Layout<Shape<_2, _1, _1>, Stride<_1, _0, _0>>,
        Tile<_32, _32, _32>
      >;

  using swizzle = Swizzle<3, 3, 3>;

  // This is for A row major, B col major according to CUTLASS default configs
  using ALayout = decltype(composition(swizzle{},
      Layout<Shape<_64, _64>, Stride<_64, _1>>{}));

  using BLayout = decltype(composition(swizzle{},
      Layout<Shape<_64, _64>, Stride<_1, _64>>{}));

  using CLayout = decltype(make_layout(Shape<_64, _64>{}, LayoutLeft{}));

  test_cooperative_gemm<ALayout,
                        BLayout,
                        CLayout,
                        ALayout,
                        BLayout,
                        CLayout,
                        AutoVectorizingCopyWithAssumedAlignment<MaxVecBits>, // A
                        AutoVectorizingCopyWithAssumedAlignment<MaxVecBits>, // B
                        AutoVectorizingCopyWithAssumedAlignment<MaxVecBits>, // C
                        thread_block_size,
                        tiled_mma_t,
                        MaxVecBits,
                        TA,
                        TB,
                        TC>();

}

#endif
