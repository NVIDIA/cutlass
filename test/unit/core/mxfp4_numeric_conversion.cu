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
    \brief Unit tests for MXFP4 numeric conversion operators.
*/

#include "../common/cutlass_unit_test.h"

#include "cutlass/numeric_conversion.h"

#include "cutlass/layout/matrix.h"
#include "cutlass/util/host_tensor.h"

namespace {

template <int N>
__global__ void convert_e2m1_to_e4m3_kernel(uint8_t* dst, uint8_t const* src) {
  cutlass::Array<cutlass::float_e2m1_t, N> input;

  CUTLASS_PRAGMA_UNROLL
  for (int i = 0; i < N; ++i) {
    input[i] = cutlass::float_e2m1_t::bitcast(src[i] & 0xf);
  }

  cutlass::NumericArrayConverter<cutlass::float_e4m3_t, cutlass::float_e2m1_t, N> converter;
  cutlass::Array<cutlass::float_e4m3_t, N> output = converter(input);

  CUTLASS_PRAGMA_UNROLL
  for (int i = 0; i < N; ++i) {
    cutlass::float_e4m3_t value = output[i];
    dst[i] = value.raw();
  }
}

template <int N>
void run_e2m1_to_e4m3_test() {
  uint8_t const input_values[16] = {
      0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7,
      0x8, 0x9, 0xa, 0xb, 0xc, 0xd, 0xe, 0xf};
  uint8_t const expected_values[16] = {
      0x00, 0x30, 0x38, 0x3c, 0x40, 0x44, 0x48, 0x4c,
      0x80, 0xb0, 0xb8, 0xbc, 0xc0, 0xc4, 0xc8, 0xcc};

  cutlass::HostTensor<uint8_t, cutlass::layout::RowMajor> src({N, 1});
  cutlass::HostTensor<uint8_t, cutlass::layout::RowMajor> dst({N, 1});

  for (int i = 0; i < N; ++i) {
    src.at({i, 0}) = input_values[i];
  }

  src.sync_device();

  convert_e2m1_to_e4m3_kernel<N><<<dim3(1,1), dim3(1,1)>>>(dst.device_data(), src.device_data());

  ASSERT_EQ(cudaGetLastError(), cudaSuccess) << "Kernel launch error.";

  dst.sync_host();

  for (int i = 0; i < N; ++i) {
    EXPECT_EQ(dst.at({i, 0}), expected_values[i]) << "index = " << i;
  }
}

}  // namespace

TEST(Mxfp4NumericConversion, E2m1ToE4m3Packed4) {
  run_e2m1_to_e4m3_test<4>();
}

TEST(Mxfp4NumericConversion, E2m1ToE4m3Packed8) {
  run_e2m1_to_e4m3_test<8>();
}
