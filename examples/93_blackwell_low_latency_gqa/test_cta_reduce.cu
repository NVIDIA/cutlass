/***************************************************************************************************
 * Copyright (c) 2025 - 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
#include <cstdio>
#include <cstdlib>
#include <vector>

#include "cutlass/util/device_memory.h"
#include "tgv_gqa.cuh"

namespace {

constexpr int Iterations = 64;
constexpr int Threads = 128;
constexpr int Values = 8;

__global__ void repeated_max(float* results) {
  using namespace cute;
  __shared__ float scratch[4 * Values];
  auto smem = make_tensor(make_smem_ptr(scratch),
                         make_layout(make_shape(Int<4>{}, Int<Values>{})));
  auto values = make_tensor<float>(make_shape(Int<Values>{}));
  auto reduced = make_tensor<float>(make_shape(Int<Values>{}));
  cutlass::arch::NamedBarrier barrier(
      Threads, cutlass::arch::ReservedNamedBarriers::EpilogueBarrier);
  for (int iteration = 0; iteration < Iterations; ++iteration) {
    for (int i = 0; i < Values; ++i) {
      values(i) = float(iteration * Threads + threadIdx.x + i);
    }
    TGV::gqa::cta_reduce<TGV::gqa::ReduceOp::Max, 4>(
        values, reduced, threadIdx.x / 32, smem, barrier);
    for (int i = 0; i < Values; ++i) {
      results[(iteration * Threads + threadIdx.x) * Values + i] = reduced(i);
    }
  }
}

void check(cudaError_t status) {
  if (status != cudaSuccess) {
    std::fprintf(stderr, "CUDA error: %s\n", cudaGetErrorString(status));
    std::exit(2);
  }
}

} // namespace

int main() {
  std::vector<float> results(Iterations * Threads * Values);
  cutlass::device_memory::allocation<float> device_results(results.size());
  check(cudaMemset(device_results.get(), 0xff, results.size() * sizeof(float)));
  repeated_max<<<1, Threads>>>(device_results.get());
  check(cudaGetLastError());
  check(cudaDeviceSynchronize());
  device_results.copy_to_host(results.data());
  for (int iteration = 0; iteration < Iterations; ++iteration) {
    for (int thread = 0; thread < Threads; ++thread) {
      for (int i = 0; i < Values; ++i) {
        float expected = float(iteration * Threads + Threads - 1 + i);
        float actual = results[(iteration * Threads + thread) * Values + i];
        if (actual != expected) {
          std::fprintf(stderr, "iteration=%d thread=%d value=%d actual=%g expected=%g\n",
                       iteration, thread, i, actual, expected);
          return 1;
        }
      }
    }
  }
  std::puts("Repeated CTA maximum reduction passed");
  return 0;
}
