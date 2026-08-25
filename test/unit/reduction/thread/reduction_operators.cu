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

#include "../../common/cutlass_unit_test.h"

#include "cutlass/reduction/thread/reduction_operators.h"

namespace {

template <int N>
using BitArray = cutlass::Array<cutlass::uint1b_t, N>;

template <int N>
unsigned reduce_and(BitArray<N> const &bits) {
  return static_cast<unsigned>(cutlass::reduction::thread::detail::ReduceArray(
      cutlass::logical_and<cutlass::uint1b_t>{}, bits));
}

template <int N>
unsigned reduce_or(BitArray<N> const &bits) {
  return static_cast<unsigned>(cutlass::reduction::thread::detail::ReduceArray(
      cutlass::logical_or<cutlass::uint1b_t>{}, bits));
}

template <int N>
void expect_logical_and_reduction() {
  BitArray<N> bits;
  bits.clear();

  EXPECT_EQ(reduce_and(bits), 0u) << "N = " << N;

  for (int i = 0; i < N; ++i) {
    bits[i] = cutlass::uint1b_t{1u};
  }
  EXPECT_EQ(reduce_and(bits), 1u) << "N = " << N;

  for (int zero = 0; zero < N; ++zero) {
    bits[zero] = cutlass::uint1b_t{0u};
    EXPECT_EQ(reduce_and(bits), 0u) << "N = " << N << ", zero = " << zero;
    bits[zero] = cutlass::uint1b_t{1u};
  }
}

template <int N>
void expect_logical_or_reduction() {
  BitArray<N> bits;
  bits.clear();

  if constexpr (N % 8) {
    uint8_t valid_mask = uint8_t((1u << (N % 8)) - 1);
    uint8_t *bytes = reinterpret_cast<uint8_t *>(bits.raw_data());
    bytes[N / 8] = uint8_t(~valid_mask);
  }
  EXPECT_EQ(reduce_or(bits), 0u) << "N = " << N;

  bits.clear();
  for (int one = 0; one < N; ++one) {
    bits[one] = cutlass::uint1b_t{1u};
    EXPECT_EQ(reduce_or(bits), 1u) << "N = " << N << ", one = " << one;
    bits[one] = cutlass::uint1b_t{0u};
  }
}

} // namespace

TEST(ReduceArrayUint1b, LogicalAndChecksEveryValidBit) {
  expect_logical_and_reduction<1>();
  expect_logical_and_reduction<7>();
  expect_logical_and_reduction<8>();
  expect_logical_and_reduction<9>();
  expect_logical_and_reduction<15>();
  expect_logical_and_reduction<16>();
  expect_logical_and_reduction<32>();
}

TEST(ReduceArrayUint1b, LogicalOrChecksOnlyValidBits) {
  expect_logical_or_reduction<1>();
  expect_logical_or_reduction<7>();
  expect_logical_or_reduction<8>();
  expect_logical_or_reduction<9>();
  expect_logical_or_reduction<15>();
  expect_logical_or_reduction<16>();
  expect_logical_or_reduction<32>();
}
