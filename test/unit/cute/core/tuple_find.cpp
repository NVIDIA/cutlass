/***************************************************************************************************
 * Copyright (c) 2024 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include <cutlass/trace.h>
#include <cute/container/packed_tuple.hpp>
#include <cute/container/tuple.hpp>

namespace test {

template<size_t ExpectedIndex, class X, class Tuple>
void test_tuple_find(Tuple const& t) {
  auto index = cute::find<X>(t);
  static_assert(decltype(index)::value == ExpectedIndex);
}

template<template<class...> class Tuple>
void test_tuple_find_all() {
  using test::test_tuple_find;
  using cute::_1;
  using cute::_2;
  using cute::_4;

  test_tuple_find<0, _1>(Tuple<_1>{});
  test_tuple_find<0, int>(Tuple<int>{7});

  test_tuple_find<0, _1>(Tuple<_1, _2>{});
  test_tuple_find<0, _1>(Tuple<_1, int>{_1{}, 7});
  test_tuple_find<0, float>(Tuple<float, int>{15.5f, 7});
  test_tuple_find<1, _2>(Tuple<_1, _2>{});
  test_tuple_find<1, int>(Tuple<_1, int>{_1{}, 7});
  test_tuple_find<1, int>(Tuple<float, int>{15.5f, 7});

  test_tuple_find<0, _1>(Tuple<_1, _2, _4>{_1{}, _2{}, _4{}});
  test_tuple_find<0, _1>(Tuple<_1, _2, int>{_1{}, _2{}, 7});
  test_tuple_find<0, _1>(Tuple<_1, float, _4>{_1{}, 15.5f, _4{}});
  test_tuple_find<0, _1>(Tuple<_1, float, int>{_1{}, 15.5f, 7});
  test_tuple_find<0, double>(Tuple<double, _2, _4>{105.5, _2{}, _4{}});
  test_tuple_find<0, double>(Tuple<double, float, _4>{105.5, 15.5f, _4{}});
  test_tuple_find<0, double>(Tuple<double, float, int>{105.5, 15.5f, 7});

  test_tuple_find<1, _2>(Tuple<_1, _2, _4>{_1{}, _2{}, _4{}});
  test_tuple_find<1, _2>(Tuple<_1, _2, int>{_1{}, _2{}, 7});
  test_tuple_find<1, float>(Tuple<_1, float, _4>{_1{}, 15.5f, _4{}});
  test_tuple_find<1, float>(Tuple<_1, float, int>{_1{}, 15.5f, 7});
  test_tuple_find<1, _2>(Tuple<double, _2, _4>{105.5, _2{}, _4{}});
  test_tuple_find<1, float>(Tuple<double, float, _4>{105.5, 15.5f, _4{}});
  test_tuple_find<1, float>(Tuple<double, float, int>{105.5, 15.5f, 7});

  test_tuple_find<2, _4>(Tuple<_1, _2, _4>{_1{}, _2{}, _4{}});
  test_tuple_find<2, int>(Tuple<_1, _2, int>{_1{}, _2{}, 7});
  test_tuple_find<2, _4>(Tuple<_1, float, _4>{_1{}, 15.5f, _4{}});
  test_tuple_find<2, int>(Tuple<_1, float, int>{_1{}, 15.5f, 7});
  test_tuple_find<2, _4>(Tuple<double, _2, _4>{105.5, _2{}, _4{}});
  test_tuple_find<2, _4>(Tuple<double, float, _4>{105.5, 15.5f, _4{}});
  test_tuple_find<2, int>(Tuple<double, float, int>{105.5, 15.5f, 7});
}

} // end namespace test


TEST(CuTe_core, TupleFind)
{
  test::test_tuple_find_all<cute::tuple>();
}

// If cute::tuple is not simply an alias for cute::packed_tuple,
// then test cute::packed_tuple separately.
#if ! defined(CUTLASS_USE_PACKED_TUPLE)
TEST(CuTe_core, PackedTupleFind)
{
  test::test_tuple_find_all<cute::packed_tuple>();
}
#endif // CUTLASS_USE_PACKED_TUPLE
