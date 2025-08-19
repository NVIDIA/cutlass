/***************************************************************************************************
* Copyright (C) 2025 Intel Corporation, All rights reserved.
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

#include <cute/arch/mma_xe.hpp>
#include <cute/atom/mma_traits.hpp>

#include <cute/layout.hpp>

namespace cute
{

template <int M, typename TD, typename TA, typename TB, typename TC>
struct MMA_Traits<XE_DPAS_TT<M, TD, TA, TB, TC>>
{
  using Op = XE_DPAS_TT<M, TD, TA, TB, TC>;

  static constexpr int BV = 32 / sizeof_bits_v<TB>;
  static constexpr int K = Op::K;

  using ValTypeD = TD;
  using ValTypeA = TA;
  using ValTypeB = TB;
  using ValTypeC = TC;
  using _M = Int<M>;
  using _K = Int<K>;

  using Shape_MNK = Shape<_M, _16, _K>;
  using ThrID = Layout<_16>;

  // A layout: (T,V) -> (M,K)
  //   M x K row major, work-items interleaved.
  using ALayout = decltype(composition(make_layout(make_shape(_K{}, _M{}), LayoutRight{}),
                                       make_layout(make_shape(_16{}, Int<M*K/16>{}))));

  // B layout: (T,V) -> (N,K)
  //   K x 16 VNNI-transformed row major, work-items interleaved.
  using BLayout = Layout<Shape<Shape<Int<BV>, Int<16/BV>>, Shape<Int<BV>, Int<16/BV>>>,
                         Stride<Stride<_16, _1>, Stride<Int<16/BV>, Int<16*BV>>>>;

  // C layout: (T,V) -> (M,N)
  //   M x 16 row major, work-items interleaved.
  using CLayout = Layout<Shape<_16, _M>, Stride<_M, _1>>;
};

} /* namespace cute */
