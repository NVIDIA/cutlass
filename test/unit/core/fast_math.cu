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
    \brief Tests for cutlass::FastDivmodU64 at the largest dividend.
*/

#include "../common/cutlass_unit_test.h"

#include "cutlass/fast_math.h"
#include "cutlass/util/device_memory.h"

/////////////////////////////////////////////////////////////////////////////////////////////////

namespace {

/// The device arm adds round_up to the dividend before the multiply. The sum wraps
/// for the largest dividend, and only for a divisor that carries round_up 1. Of the
/// first 1048576 divisors, 325628 carry it. The smallest one is 7.
uint64_t const kDivisors[] = {7, 23, 100, 1000};
int const kNumDivisors = int(sizeof(kDivisors) / sizeof(kDivisors[0]));

__global__ void divide_kernel(
    cutlass::FastDivmodU64 object, uint64_t dividend, uint64_t* quotient, uint64_t* remainder) {

  *quotient = object.divmod(*remainder, dividend);
}

__global__ void decompose_kernel(
    uint64_t linear_idx, cutlass::FastDivmodU64 const* divmod, cutlass::Coord<4>* out) {

  *out = cutlass::CoordinateDecomposition<4>(linear_idx, divmod);
}

}  // namespace

/// The wrap gave the quotient 0, and it gave the whole dividend as the remainder.
TEST(fast_math, fast_divmod_u64_at_the_largest_dividend) {
  uint64_t const kMax = ~uint64_t(0);

  cutlass::device_memory::allocation<uint64_t> device_u64(2);

  for (int i = 0; i < kNumDivisors; ++i) {
    uint64_t const divisor = kDivisors[i];
    cutlass::FastDivmodU64 const object(divisor);

    divide_kernel<<<1, 1>>>(object, kMax, device_u64.get(), device_u64.get() + 1);
    ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

    uint64_t from_device[2] = {0, 0};
    cutlass::device_memory::copy_to_host(from_device, device_u64.get(), 2);

    EXPECT_EQ(from_device[0], kMax / divisor) << "divisor " << divisor;
    EXPECT_EQ(from_device[1], kMax % divisor) << "divisor " << divisor;
  }
}

/// The quotient 0 left the whole dividend for the next mode, and the decomposition
/// then gave the coordinate -1.
TEST(fast_math, coordinate_decomposition_at_the_largest_dividend) {
  uint64_t const kMax = ~uint64_t(0);
  int const kExtent[3] = {3, 5, 7};

  cutlass::FastDivmodU64 host_divmod[3] = {
      cutlass::FastDivmodU64(uint64_t(kExtent[0])),
      cutlass::FastDivmodU64(uint64_t(kExtent[1])),
      cutlass::FastDivmodU64(uint64_t(kExtent[2]))};

  cutlass::device_memory::allocation<cutlass::FastDivmodU64> device_divmod(3);
  cutlass::device_memory::allocation<cutlass::Coord<4>> device_coord(1);
  cutlass::device_memory::copy_to_device(device_divmod.get(), host_divmod, 3);

  decompose_kernel<<<1, 1>>>(kMax, device_divmod.get(), device_coord.get());
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

  cutlass::Coord<4> coord;
  cutlass::device_memory::copy_to_host(&coord, device_coord.get(), 1);

  cutlass::Coord<4> const reference =
      cutlass::CoordinateDecomposition<4>(kMax, host_divmod);

  // The wrap gives the mode 3 the value -1, and it gives the mode 2 the value 0
  // against the exact 2. A coordinate is a remainder, thus a negative value is
  // outside the domain.
  EXPECT_GE(coord[3], 0);
  EXPECT_EQ(coord[2], reference[2]);
  EXPECT_EQ(coord[3], reference[3]);
}

/////////////////////////////////////////////////////////////////////////////////////////////////
