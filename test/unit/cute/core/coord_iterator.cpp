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

#include <cute/layout.hpp>
#include <cute/stride.hpp>

using namespace cute;

namespace {

template <class Iterator>
void check_ordered_iterator(Iterator iter)
{
  // For shape (16,3,3) and Step<2,0,1>, s varies fastest, then r, then c.
  unsigned hash = 2166136261u;
  for (int i = 0; i < 144; ++i, ++iter) {
    auto coord = *iter;
    hash = (hash ^ unsigned(get<0>(coord) + 17 * get<1>(coord) +
                           257 * get<2>(coord))) * 16777619u;
  }
  EXPECT_EQ(3233293829u, hash);
  EXPECT_TRUE(iter == ForwardCoordIteratorSentinel{});
}

} // namespace

TEST(CuTe_core, CoordIterator_OwnsShape)
{
  auto shape = make_shape(2, 3);
  auto iter = make_coord_iterator(shape);
  auto coord_iter = make_coord_iterator(make_coord(0, 0), shape);

  // Keep the source alive but change it, so borrowing its bounds fails
  // deterministically even without a sanitizer.
  shape = make_shape(7, 11);
  for (int j = 0; j < 3; ++j) {
    for (int i = 0; i < 2; ++i) {
      EXPECT_TRUE(*iter == make_coord(i, j));
      EXPECT_TRUE(*coord_iter == make_coord(i, j));
      ++iter;
      ++coord_iter;
    }
  }
  EXPECT_TRUE(iter == ForwardCoordIteratorSentinel{});
  EXPECT_TRUE(coord_iter == ForwardCoordIteratorSentinel{});
}

TEST(CuTe_core, CoordIterator_OrderedOwnsShape)
{
  auto shape = make_shape(16, 3, 3);
  auto iter = make_coord_iterator<Step<_2, _0, _1>>(shape);
  auto coord_iter = make_coord_iterator<Step<_2, _0, _1>>(make_coord(0, 0, 0), shape);
  shape = make_shape(7, 11, 13);

  check_ordered_iterator(iter);
  check_ordered_iterator(coord_iter);
}

TEST(CuTe_core, CoordIterator_LocalShape)
{
  auto iter = [] {
    auto shape = make_shape(16, 3, 3);
    return make_coord_iterator<Step<_2, _0, _1>>(shape);
  }();

  check_ordered_iterator(iter);
}

TEST(CuTe_core, CoordIterator_TemporaryShape)
{
  auto iter = make_coord_iterator<Step<_2, _0, _1>>(make_shape(16, 3, 3));

  // The temporary shape has expired before either increment or comparison.
  check_ordered_iterator(iter);
}
