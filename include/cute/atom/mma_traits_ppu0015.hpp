/***************************************************************************************************
 * Copyright (c) 2022-2026, T-HEAD (SHANGHAI) SEMICONDUCTOR CO., LTD. All rights reserved. 
 * Copyright (c) 2017 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cute/arch/mma_ppu0015.hpp"

#include "cute/arch/util.hpp"

#include <cute/atom/mma_traits.hpp>

#include <cute/layout.hpp>

#include <cute/numeric/int.hpp>

#include <cutlass/numeric_types.h>


namespace cute
{

namespace {

using PPU0015_16x8_Row = Layout<Shape <Shape < _4,_8>,Shape < _2,_2>>,
                             Stride<Stride<_32,_1>,Stride<_16,_8>>>;

using PPU0015_16x16_Row = Layout<Shape <Shape < _4,_8>,Shape < _2,_2,_2>>,
                              Stride<Stride<_32,_1>,Stride<_16,_8,_128>>>;

}

template <>
struct MMA_Traits<PPU0015_16x8x8_F32TF32TF32F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::tfloat32_t;
  using ValTypeB = cutlass::tfloat32_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_8>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2, _2>>,
                         Stride<Stride<_16,_1>,Stride<_8,_64>>>;
  using BLayout = Layout<Shape <Shape <_4,_8>, _2>,
                         Stride<Stride<_8,_1>,_32>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x8_F32TF32TF32F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::tfloat32_t;
  using ValTypeB = cutlass::tfloat32_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_16,_8>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2, _2>>,
                         Stride<Stride<_16,_1>,Stride<_8,_64>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_2, _2>>,
                         Stride<Stride<_16,_1>,Stride<_64,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x8_F32F32F32F32_TN>
     : MMA_Traits<PPU0015_16x16x8_F32TF32TF32F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = float;
  using ValTypeB = float;
  using ValTypeC = float;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_F32F16F16F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = half_t;
  using ValTypeB = half_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape < _2,_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8,_128>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>, Shape <_2,_2,_2>>,
                         Stride<Stride<_32,_1>, Stride<_16,_128,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_F32BF16BF16F32_TN>
     : MMA_Traits<PPU0015_16x16x16_F32F16F16F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = bfloat16_t;
  using ValTypeB = bfloat16_t;
  using ValTypeC = float;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_F16F16F16F16_TN>
     : MMA_Traits<PPU0015_16x16x16_F32F16F16F32_TN>
{
  using ValTypeD = half_t;
  using ValTypeA = half_t;
  using ValTypeB = half_t;
  using ValTypeC = half_t;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_F16E4M3E4M3F16_TN>
{
  using ValTypeD = half_t;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = half_t;

  using Shape_MNK = Shape<_16,_16,_32>;
  // using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape < _4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>, Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>, Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_F32E4M3E4M3F32_TN>
     : MMA_Traits<PPU0015_16x16x32_F16E4M3E4M3F16_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = float;
};

template<>
struct MMA_Traits<PPU0015_16x16x32_F32E4M3E5M2F32_TN>
     : MMA_Traits<PPU0015_16x16x32_F32E4M3E4M3F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = float;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_F16E5M2E4M3F16_TN>
     : MMA_Traits<PPU0015_16x16x32_F16E4M3E4M3F16_TN>
{
  using ValTypeD = half_t;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = half_t;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_F32E5M2E4M3F32_TN>
     : MMA_Traits<PPU0015_16x16x32_F32E4M3E4M3F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = float;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_F32E5M2E5M2F32_TN>
     : MMA_Traits<PPU0015_16x16x32_F32E4M3E4M3F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = float;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_S32S8S8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape < _4,_2,  _2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape < _4,_2,  _2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x64_F32F4F4F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = uint8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = float;

  // using Shape_MNK = Shape<_16,_16,_64>;
  // using ThrID   = Layout<_32>;
  // using ALayout = Layout<Shape <Shape < _4, _8>,Shape < _8,_2,_2>>,
  //                        Stride<Stride<_128,_1>,Stride<_16,_8,_512>>>;
  // using BLayout = Layout<Shape <Shape < _4, _8>, Shape < _8,_2,_2>>,
  //                        Stride<Stride<_128,_1>, Stride<_16,_512,_8>>>;
  // using CLayout = PPU0015_16x16_Row;


  // use int8 layout to get correct subloop num
  // since we regard fp4 gemm as a int8 gemm now
  using Shape_MNK = Shape<_16,_16,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape < _4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>, Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>, Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

//
// Native TC02 MMA traits (TIX 9.5.2--9.5.9).
//

template <>
struct MMA_Traits<PPU0015_16x8x8_F32F16F16F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::half_t;
  using ValTypeB = cutlass::half_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_8>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_2>,
                         Stride<Stride<_16,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x8_F16F16F16F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::half_t;
  using ValTypeB = cutlass::half_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_8,_8>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_2>,
                         Stride<Stride<_16,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x8_F32BF16BF16F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::bfloat16_t;
  using ValTypeB = cutlass::bfloat16_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_8>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_2>,
                         Stride<Stride<_16,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x8_BF16BF16BF16BF16_TN>
{
  using ValTypeD = cutlass::bfloat16_t;
  using ValTypeA = cutlass::bfloat16_t;
  using ValTypeB = cutlass::bfloat16_t;
  using ValTypeC = cutlass::bfloat16_t;

  using Shape_MNK = Shape<_16,_8,_8>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_2>,
                         Stride<Stride<_16,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_F32F16F16F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::half_t;
  using ValTypeB = cutlass::half_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8,_128>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_16,_1>,Stride<_8,_64>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_F16F16F16F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::half_t;
  using ValTypeB = cutlass::half_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8,_128>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_16,_1>,Stride<_8,_64>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_F32BF16BF16F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::bfloat16_t;
  using ValTypeB = cutlass::bfloat16_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8,_128>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_16,_1>,Stride<_8,_64>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_BF16BF16BF16BF16_TN>
{
  using ValTypeD = cutlass::bfloat16_t;
  using ValTypeA = cutlass::bfloat16_t;
  using ValTypeB = cutlass::bfloat16_t;
  using ValTypeC = cutlass::bfloat16_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8,_128>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_16,_1>,Stride<_8,_64>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x4_F32F32F32F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = float;
  using ValTypeB = float;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_4>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,_2>,
                         Stride<Stride<_16,_1>,_8>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_1>,
                         Stride<Stride<_8,_1>,_0>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x4_F32TF32TF32F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::tfloat32_t;
  using ValTypeB = cutlass::tfloat32_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_4>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,_2>,
                         Stride<Stride<_16,_1>,_8>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_1>,
                         Stride<Stride<_8,_1>,_0>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x8_F32F32F32F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = float;
  using ValTypeB = float;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_8>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_16,_1>,Stride<_8,_64>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_2>,
                         Stride<Stride<_8,_1>,_32>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_F16E4M3E4M3F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_F16E4M3E5M2F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_F16E5M2E4M3F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_F16E5M2E5M2F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_F32E4M3E4M3F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_F32E4M3E5M2F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_F32E5M2E4M3F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_F32E5M2E5M2F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_F16E4M3E4M3F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_F16E4M3E5M2F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_F16E5M2E4M3F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_F16E5M2E5M2F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_F32E4M3E4M3F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_F32E4M3E5M2F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_F32E5M2E4M3F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_F32E5M2E5M2F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_S32S8S8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_S32S8S8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_S32S8U8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_S32S8U8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_S32U8S8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_S32U8S8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_S32U8U8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x16_S32U8U8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_4>,
                         Stride<Stride<_32,_1>,_8>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_S32S8S8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_S32S8S8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_S32S8U8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_S32S8U8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_S32U8S8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_S32U8S8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_S32U8U8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x8x32_S32U8U8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_8,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_32,_1>,Stride<_8,_128>>>;
  using CLayout = PPU0015_16x8_Row;
};

// Raw E2M1 storage uses four logical bits per element and the native K=64.
// Scale operands are supplied through MMA_Atom::call(D,A,B,C,S).

template <>
struct MMA_Traits<PPU0015_16x8x64_F32F4F4F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::uint4b_t;
  using ValTypeB = cutlass::uint4b_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_8,_64>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_8,_2,_2>>,
                         Stride<Stride<_128,_1>,Stride<_16,_8,_512>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_8,_2>>,
                         Stride<Stride<_64,_1>,Stride<_8,_256>>>;
  using CLayout = PPU0015_16x8_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x8_F32F16F16F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::half_t;
  using ValTypeB = cutlass::half_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_16,_8>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x8_F16F16F16F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::half_t;
  using ValTypeB = cutlass::half_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_16,_8>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x8_F32BF16BF16F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::bfloat16_t;
  using ValTypeB = cutlass::bfloat16_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_16,_8>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x8_BF16BF16BF16BF16_TN>
{
  using ValTypeD = cutlass::bfloat16_t;
  using ValTypeA = cutlass::bfloat16_t;
  using ValTypeB = cutlass::bfloat16_t;
  using ValTypeC = cutlass::bfloat16_t;

  using Shape_MNK = Shape<_16,_16,_8>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_BF16BF16BF16BF16_TN>
{
  using ValTypeD = cutlass::bfloat16_t;
  using ValTypeA = cutlass::bfloat16_t;
  using ValTypeB = cutlass::bfloat16_t;
  using ValTypeC = cutlass::bfloat16_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_8,_128>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_2,_2,_2>>,
                         Stride<Stride<_32,_1>,Stride<_16,_128,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x4_F32F32F32F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = float;
  using ValTypeB = float;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_16,_4>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,_2>,
                         Stride<Stride<_16,_1>,_8>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_2>,
                         Stride<Stride<_16,_1>,_8>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x4_F32TF32TF32F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::tfloat32_t;
  using ValTypeB = cutlass::tfloat32_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_16,_4>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,_2>,
                         Stride<Stride<_16,_1>,_8>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,_2>,
                         Stride<Stride<_16,_1>,_8>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_F16E4M3E4M3F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_F16E4M3E5M2F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_F16E5M2E4M3F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_F16E5M2E5M2F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_F32E4M3E4M3F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_F32E4M3E5M2F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_F32E5M2E4M3F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e4m3_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_F32E5M2E5M2F32_TN>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_F16E4M3E5M2F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e4m3_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_16,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_F16E5M2E5M2F16_TN>
{
  using ValTypeD = cutlass::half_t;
  using ValTypeA = cutlass::float_e5m2_t;
  using ValTypeB = cutlass::float_e5m2_t;
  using ValTypeC = cutlass::half_t;

  using Shape_MNK = Shape<_16,_16,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_S32S8S8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_S32S8S8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_S32S8U8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_S32S8U8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_S32U8S8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_S32U8S8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_S32U8U8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x16_S32U8U8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_16>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_S32S8S8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_S32S8U8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_S32S8U8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = int8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_S32U8S8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_S32U8S8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = int8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_S32U8U8S32_TN>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

template <>
struct MMA_Traits<PPU0015_16x16x32_S32U8U8S32_TN_SATURATE>
{
  using ValTypeD = int32_t;
  using ValTypeA = uint8_t;
  using ValTypeB = uint8_t;
  using ValTypeC = int32_t;

  using Shape_MNK = Shape<_16,_16,_32>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_8,_256>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_4,_2,_2>>,
                         Stride<Stride<_64,_1>,Stride<_16,_256,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

// Raw E2M1 storage uses four logical bits per element and the native K=64.
// Scale operands are supplied through MMA_Atom::call(D,A,B,C,S).

template <>
struct MMA_Traits<PPU0015_16x16x64_F32F4F4F32_TN_NATIVE>
{
  using ValTypeD = float;
  using ValTypeA = cutlass::uint4b_t;
  using ValTypeB = cutlass::uint4b_t;
  using ValTypeC = float;

  using Shape_MNK = Shape<_16,_16,_64>;
  using ThrID   = Layout<_32>;
  using ALayout = Layout<Shape <Shape < _4,_8>,Shape <_8,_2,_2>>,
                         Stride<Stride<_128,_1>,Stride<_16,_8,_512>>>;
  using BLayout = Layout<Shape <Shape < _4,_8>,Shape <_8,_2,_2>>,
                         Stride<Stride<_128,_1>,Stride<_16,_512,_8>>>;
  using CLayout = PPU0015_16x16_Row;
};

//
// Generic mma_unpack for any MMA_Traits with scale data
//
template <class MMA_Op, class... MMA_Args,
          class TD, class DLayout,
          class TA, class ALayout,
          class TB, class BLayout,
          class TC, class CLayout,
          class TS, class SLayout>
CUTE_HOST_DEVICE constexpr
void
mma_unpack(MMA_Traits<MMA_Op, MMA_Args...> const& traits,
           Tensor<TD, DLayout>      & D,
           Tensor<TA, ALayout> const& A,
           Tensor<TB, BLayout> const& B,
           Tensor<TC, CLayout> const& C,
           Tensor<TS, SLayout> const& S)
{

  static_assert(is_rmem<TD>::value, "Expected registers in MMA_Atom::call");
  static_assert(is_rmem<TA>::value, "Expected registers in MMA_Atom::call");
  static_assert(is_rmem<TB>::value, "Expected registers in MMA_Atom::call");
  static_assert(is_rmem<TC>::value, "Expected registers in MMA_Atom::call");
  static_assert(is_rmem<TS>::value, "Expected scale registers in MMA_Atom::call");

  // Register value types from the MMA_Operation register arrays
  using RegTypeD = typename remove_extent<typename MMA_Op::DRegisters>::type;
  using RegTypeA = typename remove_extent<typename MMA_Op::ARegisters>::type;
  using RegTypeB = typename remove_extent<typename MMA_Op::BRegisters>::type;
  using RegTypeC = typename remove_extent<typename MMA_Op::CRegisters>::type;
  using RegTypeS = typename remove_extent<typename MMA_Op::SRegisters>::type;

  using MMATraits = MMA_Traits<MMA_Op, MMA_Args...>;

  [[maybe_unused]] constexpr int RegNumD = extent<typename MMA_Op::DRegisters>::value;
  constexpr int RegNumA = extent<typename MMA_Op::ARegisters>::value;
  constexpr int RegNumB = extent<typename MMA_Op::BRegisters>::value;
  constexpr int RegNumC = extent<typename MMA_Op::CRegisters>::value;
  constexpr int RegNumS = extent<typename MMA_Op::SRegisters>::value;

  Tensor rA = recast<RegTypeA>(A);
  Tensor rB = recast<RegTypeB>(B);
  Tensor rS = recast<RegTypeS>(S);

  CUTE_STATIC_ASSERT_V(size(rA) == Int<RegNumA>{});
  CUTE_STATIC_ASSERT_V(size(rB) == Int<RegNumB>{});
  CUTE_STATIC_ASSERT_V(size(rS) == Int<RegNumS>{});

  static_assert(is_same<typename TD::value_type, typename TC::value_type>::value, "GMMA C and D value_type must match.");
  static_assert(is_same<DLayout, CLayout>::value, "GMMA C and D layouts must match.");
  // assert((void*)&C == (void*)&D);

  //CUTE_STATIC_ASSERT_V(size(rC) == Int<RegNumC>{});

  Tensor rD = recast<RegTypeD>(D);
  Tensor rC = recast<RegTypeC>(C);

  CUTE_STATIC_ASSERT_V(size(rD) == Int<RegNumD>{});
  CUTE_STATIC_ASSERT_V(size(rC) == Int<RegNumC>{});

  detail::explode(MMA_Op::fma,
              rD, make_int_sequence<RegNumD>{},
              rA, make_int_sequence<RegNumA>{},
              rB, make_int_sequence<RegNumB>{},
              rC, make_int_sequence<RegNumC>{},
              rS, make_int_sequence<RegNumS>{});
}

} // namespace cute

