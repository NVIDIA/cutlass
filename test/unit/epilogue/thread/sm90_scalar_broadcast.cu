/***************************************************************************************************
 * Copyright (c) 2023 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
    \brief Unit tests for Sm90ScalarBroadcast is_zero() resolution with null pointer fallback (#3783).
*/

#include "../../common/cutlass_unit_test.h"

#include "cute/tensor.hpp"
#include "cutlass/cutlass.h"
#include "cutlass/epilogue/fusion/sm90_visitor_load_tma_warpspecialized.hpp"

using namespace cute;

template <class StrideMNL, int BroadcastCount = 1>
__global__ void test_scalar_broadcast_is_zero_kernel(
    cutlass::Array<float, BroadcastCount> scalars,
    cutlass::Array<float const*, BroadcastCount> scalar_ptrs,
    StrideMNL stride,
    int* out_is_zero)
{
  using ScalarBroadcast = cutlass::epilogue::fusion::Sm90ScalarBroadcast<
      float,
      StrideMNL,
      BroadcastCount,
      cutlass::multiplies
  >;

  typename ScalarBroadcast::Params params;
  for (int i = 0; i < BroadcastCount; ++i) {
    params.scalars[i] = scalars[i];
    params.scalar_ptrs[i] = scalar_ptrs[i];
    params.dScalar[i] = stride;
  }

  typename ScalarBroadcast::SharedStorage storage;
  ScalarBroadcast op(params, storage);

  *out_is_zero = op.is_zero() ? 1 : 0;
}

TEST(Sm90_Visitor_Load, ScalarBroadcast_NullPtrFallback_NonzeroScalar) {
  int* d_out = nullptr;
  ASSERT_EQ(cudaMalloc(&d_out, sizeof(int)), cudaSuccess);

  // Strided batch: dBeta != 0, beta_ptr == nullptr, scalar beta == 1.0f
  auto stride_batched = make_stride(_0{}, _0{}, 1);
  cutlass::Array<float, 1> scalars = {1.0f};
  cutlass::Array<float const*, 1> scalar_ptrs = {nullptr};

  test_scalar_broadcast_is_zero_kernel<decltype(stride_batched), 1><<<1, 1>>>(
      scalars, scalar_ptrs, stride_batched, d_out);
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

  int h_out = -1;
  ASSERT_EQ(cudaMemcpy(&h_out, d_out, sizeof(int), cudaMemcpyDeviceToHost), cudaSuccess);
  // Scalar beta is 1.0f (non-zero), so is_zero() must be false (0) to enable epilogue load warps
  EXPECT_EQ(h_out, 0);

  cudaFree(d_out);
}

TEST(Sm90_Visitor_Load, ScalarBroadcast_NullPtrFallback_ZeroScalar) {
  int* d_out = nullptr;
  ASSERT_EQ(cudaMalloc(&d_out, sizeof(int)), cudaSuccess);

  // Strided batch: dBeta != 0, beta_ptr == nullptr, scalar beta == 0.0f
  auto stride_batched = make_stride(_0{}, _0{}, 1);
  cutlass::Array<float, 1> scalars = {0.0f};
  cutlass::Array<float const*, 1> scalar_ptrs = {nullptr};

  test_scalar_broadcast_is_zero_kernel<decltype(stride_batched), 1><<<1, 1>>>(
      scalars, scalar_ptrs, stride_batched, d_out);
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

  int h_out = -1;
  ASSERT_EQ(cudaMemcpy(&h_out, d_out, sizeof(int), cudaMemcpyDeviceToHost), cudaSuccess);
  // Scalar beta is 0.0f, so is_zero() must be true (1)
  EXPECT_EQ(h_out, 1);

  cudaFree(d_out);
}

TEST(Sm90_Visitor_Load, ScalarBroadcast_ValidPtr) {
  int* d_out = nullptr;
  ASSERT_EQ(cudaMalloc(&d_out, sizeof(int)), cudaSuccess);

  float dummy = 1.0f;
  float* d_dummy = nullptr;
  ASSERT_EQ(cudaMalloc(&d_dummy, sizeof(float)), cudaSuccess);
  ASSERT_EQ(cudaMemcpy(d_dummy, &dummy, sizeof(float), cudaMemcpyHostToDevice), cudaSuccess);

  auto stride_batched = make_stride(_0{}, _0{}, 1);
  cutlass::Array<float, 1> scalars = {0.0f};
  cutlass::Array<float const*, 1> scalar_ptrs = {d_dummy};

  test_scalar_broadcast_is_zero_kernel<decltype(stride_batched), 1><<<1, 1>>>(
      scalars, scalar_ptrs, stride_batched, d_out);
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

  int h_out = -1;
  ASSERT_EQ(cudaMemcpy(&h_out, d_out, sizeof(int), cudaMemcpyDeviceToHost), cudaSuccess);
  // Valid pointer provided, so is_zero() must be false (0) to enable loads
  EXPECT_EQ(h_out, 0);

  cudaFree(d_dummy);
  cudaFree(d_out);
}

TEST(Sm90_Visitor_Load, ScalarBroadcast_MultiBroadcast_NullPtrFallback) {
  int* d_out = nullptr;
  ASSERT_EQ(cudaMalloc(&d_out, sizeof(int)), cudaSuccess);
  auto stride_batched = make_stride(_0{}, _0{}, 1);

  // Subcase A: 2.0 * 0.0 = 0.0 -> is_zero should be true (1)
  cutlass::Array<float, 2> scalars_zero = {2.0f, 0.0f};
  cutlass::Array<float const*, 2> null_ptrs = {nullptr, nullptr};

  test_scalar_broadcast_is_zero_kernel<decltype(stride_batched), 2><<<1, 1>>>(
      scalars_zero, null_ptrs, stride_batched, d_out);
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

  int h_out = -1;
  ASSERT_EQ(cudaMemcpy(&h_out, d_out, sizeof(int), cudaMemcpyDeviceToHost), cudaSuccess);
  EXPECT_EQ(h_out, 1);

  // Subcase B: 2.0 * 0.5 = 1.0 -> is_zero should be false (0)
  cutlass::Array<float, 2> scalars_nonzero = {2.0f, 0.5f};
  test_scalar_broadcast_is_zero_kernel<decltype(stride_batched), 2><<<1, 1>>>(
      scalars_nonzero, null_ptrs, stride_batched, d_out);
  ASSERT_EQ(cudaDeviceSynchronize(), cudaSuccess);

  ASSERT_EQ(cudaMemcpy(&h_out, d_out, sizeof(int), cudaMemcpyDeviceToHost), cudaSuccess);
  EXPECT_EQ(h_out, 0);

  cudaFree(d_out);
}
