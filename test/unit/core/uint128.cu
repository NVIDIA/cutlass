/***************************************************************************************************
 * Copyright (c) 2017 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Tests for basic uint128 functionality
*/

#include "../common/cutlass_unit_test.h"

#include <vector>

#include "cutlass/array.h"
#include "cutlass/layout/matrix.h"
#include "cutlass/numeric_types.h"
#include "cutlass/numeric_conversion.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/host_tensor.h"


/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Host
//
/////////////////////////////////////////////////////////////////////////////////////////////////

TEST(uint128_t, host_arithmetic) {
  using T = cutlass::uint128_t;

  // only low 64bit
  for (uint64_t i = 0; i < 1024; ++i) {
    for (uint64_t j = 0; j < 1024; ++j) {
      T x = i;
      T y = j;

      EXPECT_TRUE(static_cast<uint64_t>(x + y) == (i + j));
      EXPECT_TRUE(static_cast<uint64_t>(x * static_cast<uint64_t>(y)) == (i * j));

      if (j != 0) {
        EXPECT_TRUE(static_cast<uint64_t>(x / static_cast<uint64_t>(y)) == (i / j));
      }
    }
  }

  // carry overflow for low uint64_t
  {
    for (uint64_t i = 0; i < 1024; ++i) {
      T x = static_cast<uint64_t>(0xFFFFFFFFFFFFFFFF);
      T y = i + 1;

      T z = x + y;

      EXPECT_EQ(z.hilo_.hi, static_cast<uint64_t>(0x1));
      EXPECT_EQ(z.hilo_.lo, i);
    }
  }
}

namespace {

// 16b-limb schoolbook reference, independent of uint128.h's decomposition
void reference_umul128(uint64_t a, uint64_t b, uint64_t &hi, uint64_t &lo) {
  uint16_t const a_limb[4] = {uint16_t(a), uint16_t(a >> 16), uint16_t(a >> 32), uint16_t(a >> 48)};
  uint16_t const b_limb[4] = {uint16_t(b), uint16_t(b >> 16), uint16_t(b >> 32), uint16_t(b >> 48)};

  uint64_t column[8] = {0};
  for (int i = 0; i < 4; ++i) {
    for (int j = 0; j < 4; ++j) {
      column[i + j] += uint64_t(a_limb[i]) * b_limb[j];
    }
  }

  hi = lo = 0;
  uint64_t carry = 0;
  for (int c = 0; c < 8; ++c) {
    uint64_t v = column[c] + carry;
    if (c < 4) {
      lo |= (v & 0xFFFFull) << (16 * c);
    } else {
      hi |= (v & 0xFFFFull) << (16 * (c - 4));
    }
    carry = v >> 16;
  }
}

uint32_t xorshift(uint32_t &state) {
  state ^= state << 13;
  state ^= state >> 17;
  state ^= state << 5;
  return state;
}

} // namespace

TEST(uint128_t, host_umul128_high_product) {
  static uint64_t const edges[] = {
    0x0ull, 0x1ull, 0x2ull, 0xFFFFFFFFull, 0x100000000ull,
    0xFFFFFFFFFFFFFFFFull, 0x8000000000000000ull, 0x123456789ABCDEF0ull
  };
  int const kEdges = int(sizeof(edges) / sizeof(edges[0]));

  for (int i = 0; i < kEdges; ++i) {
    for (int j = 0; j < kEdges; ++j) {
      uint64_t got_hi = 0, got_lo = 0, want_hi = 0, want_lo = 0;
      got_lo = umul128(edges[i], edges[j], &got_hi);
      reference_umul128(edges[i], edges[j], want_hi, want_lo);

      EXPECT_EQ(got_lo, want_lo) << "a=" << edges[i] << " b=" << edges[j];
      EXPECT_EQ(got_hi, want_hi) << "a=" << edges[i] << " b=" << edges[j];
    }
  }

  uint32_t state = 0x9E3779B9u;
  for (int i = 0; i < 4096; ++i) {
    uint64_t a = (uint64_t(xorshift(state)) << 32) | xorshift(state);
    uint64_t b = (uint64_t(xorshift(state)) << 32) | xorshift(state);
    if (i % 4 == 0) {
      a &= 0xFFFFFFFF00000000ull;
      b &= 0x1FFFFFFFFull;
    }

    uint64_t got_hi = 0, got_lo = 0, want_hi = 0, want_lo = 0;
    got_lo = umul128(a, b, &got_hi);
    reference_umul128(a, b, want_hi, want_lo);

    EXPECT_EQ(got_lo, want_lo) << "iter=" << i;
    EXPECT_EQ(got_hi, want_hi) << "iter=" << i;
  }
}

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Device
//
/////////////////////////////////////////////////////////////////////////////////////////////////

__global__ void uint128_add_operator(cutlass::uint128_t *output, cutlass::uint128_t const *input, cutlass::uint128_t base, int N) {
  int tid = threadIdx.x + blockIdx.x * blockDim.x;
  if (tid < N) {
    output[tid] = input[tid] + base;
  }
}

TEST(uint128_t, device_arithmetic) {
  using T = cutlass::uint128_t;

  int const N = 1024;

  cutlass::HostTensor<T, cutlass::layout::RowMajor> input({N, 1});
  cutlass::HostTensor<T, cutlass::layout::RowMajor> sum({N, 1});

  for (int i = 0; i < N; ++i) {
    input.at({i, 0}) = static_cast<uint64_t>(i + 1);
  }

  T b = static_cast<uint64_t>(0xFFFFFFFFFFFFFFFF);

  input.sync_device();

  uint128_add_operator<<< dim3(1,1), dim3(N, 1) >>>(sum.device_data(), input.device_data(), b, N);

  ASSERT_EQ(cudaGetLastError(), cudaSuccess) << "Kernel launch error.";

  sum.sync_host();

  for (int i = 0; i < N; ++i) {
    T got = sum.at({i, 0});
    uint64_t expected_hi = static_cast<uint64_t>(0x1);
    uint64_t expected_lo = static_cast<uint64_t>(i);

    EXPECT_EQ(got.hilo_.hi, expected_hi);
    EXPECT_EQ(got.hilo_.lo, expected_lo);
  }
}

__global__ void uint128_umul_operator(int count, uint64_t const *a_values, uint64_t const *b_values,
                                      uint64_t *hi_out, uint64_t *lo_out) {
  int tid = threadIdx.x + blockIdx.x * blockDim.x;
  if (tid < count) {
    lo_out[tid] = umul128(a_values[tid], b_values[tid], &hi_out[tid]);
  }
}

TEST(uint128_t, device_umul128_high_product) {

  static uint64_t const edges[] = {
    0x0ull, 0x1ull, 0x2ull, 0xFFFFFFFFull, 0x100000000ull,
    0xFFFFFFFFFFFFFFFFull, 0x8000000000000000ull, 0x123456789ABCDEF0ull
  };
  int const kEdges = int(sizeof(edges) / sizeof(edges[0]));
  int const kRandom = 1008;
  int const kCount = kEdges * kEdges + kRandom;

  std::vector<uint64_t> a_values(kCount), b_values(kCount), hi_want(kCount), lo_want(kCount);

  int idx = 0;
  for (int i = 0; i < kEdges; ++i) {
    for (int j = 0; j < kEdges; ++j) {
      a_values[idx] = edges[i];
      b_values[idx] = edges[j];
      reference_umul128(edges[i], edges[j], hi_want[idx], lo_want[idx]);
      ++idx;
    }
  }

  uint32_t state = 0xDEADBEEFu;
  for (; idx < kCount; ++idx) {
    uint64_t a = (uint64_t(xorshift(state)) << 32) | xorshift(state);
    uint64_t b = (uint64_t(xorshift(state)) << 32) | xorshift(state);
    a_values[idx] = a;
    b_values[idx] = b;
    reference_umul128(a, b, hi_want[idx], lo_want[idx]);
  }

  cutlass::device_memory::allocation<uint64_t> a_dev(kCount);
  cutlass::device_memory::allocation<uint64_t> b_dev(kCount);
  cutlass::device_memory::allocation<uint64_t> hi_dev(kCount);
  cutlass::device_memory::allocation<uint64_t> lo_dev(kCount);

  a_dev.copy_from_host(a_values.data());
  b_dev.copy_from_host(b_values.data());

  uint128_umul_operator<<< dim3((kCount + 127) / 128), dim3(128) >>>(
    kCount, a_dev.get(), b_dev.get(), hi_dev.get(), lo_dev.get());

  ASSERT_EQ(cudaGetLastError(), cudaSuccess) << "Kernel launch error.";

  std::vector<uint64_t> hi_got(kCount), lo_got(kCount);
  hi_dev.copy_to_host(hi_got.data());
  lo_dev.copy_to_host(lo_got.data());

  for (int i = 0; i < kCount; ++i) {
    EXPECT_EQ(lo_got[i], lo_want[i]) << "iter=" << i;
    EXPECT_EQ(hi_got[i], hi_want[i]) << "iter=" << i;
  }
}
