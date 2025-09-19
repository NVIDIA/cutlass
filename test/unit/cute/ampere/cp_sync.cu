/***************************************************************************************************
 * Copyright (c) 2017 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#include "cutlass_unit_test.h"

#include <iostream>
#include <iomanip>
#include <utility>
#include <type_traits>
#include <vector>
#include <numeric>

#include <cute/tensor.hpp>

using namespace cute;

#ifdef CUTLASS_ENABLE_SYCL
namespace sc = compat;
namespace sc_exp = compat::experimental;
namespace sycl_ext = sycl::ext::oneapi::experimental;

CUTLASS_GLOBAL void
test(double const* g_in, double* g_out, sycl::local_ptr<char> base_smem)
{
  auto smem = reinterpret_cast<double*>((char*)base_smem);
  smem[ThreadIdxX()] = g_in[ThreadIdxX()];

  syncthreads();

  g_out[ThreadIdxX()] = 2 * smem[ThreadIdxX()];
}

CUTLASS_GLOBAL void
test2(double const* g_in, double* g_out, sycl::local_ptr<char> base_smem)
{
  using namespace cute;

  auto smem = reinterpret_cast<double*>((char*)base_smem);

  auto s_tensor = make_tensor(make_smem_ptr(smem + ThreadIdxX()), Int<1>{});
  auto g_tensor = make_tensor(make_gmem_ptr(g_in + ThreadIdxX()), Int<1>{});

  copy(g_tensor, s_tensor);

  syncthreads();

  g_out[ThreadIdxX()] = 2 * smem[ThreadIdxX()];
}

#else

__global__ void
test(double const* g_in, double* g_out)
{
  extern __shared__ double smem[];

  smem[threadIdx.x] = g_in[threadIdx.x];

  __syncthreads();

  g_out[threadIdx.x] = 2 * smem[threadIdx.x];
}

__global__ void
test2(double const* g_in, double* g_out)
{
  using namespace cute;

  extern __shared__ double smem[];

  auto s_tensor = make_tensor(make_smem_ptr(smem + threadIdx.x), Int<1>{});
  auto g_tensor = make_tensor(make_gmem_ptr(g_in + threadIdx.x), Int<1>{});

  copy(g_tensor, s_tensor);

  __syncthreads();

  g_out[threadIdx.x] = 2 * smem[threadIdx.x];
}

#endif

TEST(SM80_CuTe_Ampere, CpSync)
{
  constexpr int count = 32;
  host_vector<double> h_in(count);
  for (int i = 0; i < count; ++i) {
    h_in[i] = double(i);
  }

  device_vector<double> d_in(h_in);

  device_vector<double> d_out(count, -1);
  #if defined(CUTLASS_ENABLE_SYCL)
    sc_exp::launch<test>(sc_exp::launch_policy{sc::dim3(1), sc::dim3(count),
              sc_exp::local_mem_size{sizeof(double) * count}},
              d_in.data(), d_out.data());
    sc::wait_and_throw();
  #else
    test<<<1, count, sizeof(double) * count>>>(
      thrust::raw_pointer_cast(d_in.data()),
      thrust::raw_pointer_cast(d_out.data()));
  #endif
  host_vector<double> h_result = d_out;

  device_vector<double> d_out_cp_async(count, -2);
  #if defined(CUTLASS_ENABLE_SYCL)
    sc_exp::launch<test2>(sc_exp::launch_policy{sc::dim3(1), sc::dim3(count),
              sc_exp::local_mem_size{sizeof(double) * count}},
              d_in.data(), d_out_cp_async.data());
    sc::wait_and_throw();
  #else
    test2<<<1, count, sizeof(double) * count>>>(
      thrust::raw_pointer_cast(d_in.data()),
      thrust::raw_pointer_cast(d_out_cp_async.data()));
  #endif
  host_vector<double> h_result_cp_async = d_out_cp_async;

  for (int i = 0; i < count; ++i) {
    EXPECT_EQ(h_result[i], h_result_cp_async[i]);
  }
}
