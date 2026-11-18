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
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <vector>

#include "cutlass/util/device_memory.h"
#include "tgv_gqa.cuh"

namespace {

void check(cudaError_t status) {
  if (status != cudaSuccess) {
    std::fprintf(stderr, "CUDA error: %s\n", cudaGetErrorString(status));
    std::exit(2);
  }
}

bool run_case(char const* name, int length) {
  constexpr int Splits = 8;
  constexpr int HeadDim = 64;
  constexpr int Stages = 3;
  constexpr int repetitions = 3;
  using Element = cutlass::bfloat16_t;
  constexpr int kv_heads = 8;
  constexpr int local_heads = 8;
  constexpr int q_heads = kv_heads * local_heads;
  std::vector<Element> q(q_heads * HeadDim, Element(0.0f));
  std::vector<Element> k(size_t(kv_heads) * length * HeadDim, Element(0.0f));
  std::vector<Element> v(k.size(), Element(1.0f));
  std::vector<Element> out(q.size());
  for (int head = 0; head < q_heads; ++head) q[head * HeadDim] = Element(1.0f);
  for (int head = 0; head < kv_heads; ++head) {
    for (int token = 0; token < length; ++token) {
      k[(size_t(head) * length + token) * HeadDim] =
          Element(float((token / 128) % 2));
      for (int feature = 0; feature < HeadDim; ++feature) {
        v[(size_t(head) * length + token) * HeadDim + feature] =
            Element(0.25f * float((token / 128 + head + feature) % 7 - 3));
      }
    }
  }
  std::vector<float> expected(q.size());
  for (int head = 0; head < q_heads; ++head) {
    for (int feature = 0; feature < HeadDim; ++feature) {
      double numerator = 0.0;
      double denominator = 0.0;
      for (int token = 0; token < length; ++token) {
        // Independent scalar softmax oracle; Q/K produce base-2 logits 0 or 1.
        double weight = std::exp2(double((token / 128) % 2));
        double value = 0.25 * double((token / 128 + head / local_heads + feature) % 7 - 3);
        numerator += weight * value;
        denominator += weight;
      }
      expected[head * HeadDim + feature] = float(Element(float(numerator / denominator)));
    }
  }
  cutlass::device_memory::allocation<Element> dq(q.size()), dk(k.size()), dv(v.size()), dout(out.size());
  cutlass::device_memory::allocation<int> dlength(1);
  dq.copy_from_host(q.data()); dk.copy_from_host(k.data()); dv.copy_from_host(v.data());
  dlength.copy_from_host(&length);
  cudaStream_t stream{};
  check(cudaStreamCreateWithFlags(&stream, cudaStreamNonBlocking));
  for (int iteration = 0; iteration < repetitions; ++iteration) {
    // Poison output each time so an unwritten element cannot pass using a prior launch.
    check(cudaMemsetAsync(dout.get(), 0xff, out.size() * sizeof(Element), stream));
    TGV::gqa::gqa_host<Element, Element, float,
        local_heads, 1, 128, HeadDim, Stages, Stages, Splits, Splits>(
        dk.get(), dq.get(), dv.get(), dout.get(), dlength.get(), nullptr,
        kv_heads, local_heads, 1, length, HeadDim, 1,
        length * HeadDim, HeadDim, 1, kv_heads * length * HeadDim,
        local_heads * HeadDim, HeadDim, q_heads * HeadDim, 1, q_heads * HeadDim,
        length * HeadDim, HeadDim, 1, kv_heads * length * HeadDim,
        local_heads * HeadDim, HeadDim, q_heads * HeadDim, 1, q_heads * HeadDim,
        1.0f / TGV::gqa::Log2_E, 0, false, -1, stream);
    check(cudaGetLastError());
    check(cudaStreamSynchronize(stream));
    dout.copy_to_host(out.data());
    int mismatches = 0;
    for (size_t i = 0; i < out.size(); ++i) {
      float actual = float(out[i]);
      // Nonconstant values expose wrong relative attention weights. The absolute
      // tolerance is one BF16 step at 0.5.
      float tolerance = 1.0f / 256.0f;
      if (!std::isfinite(actual) || std::fabs(actual - expected[i]) > tolerance) {
        if (mismatches < 8)
          std::printf("%s iteration=%d head=%zu feature=%zu actual=%g expected=%g tolerance=%g\n",
                      name, iteration, i / HeadDim, i % HeadDim, actual, expected[i], tolerance);
        ++mismatches;
      }
    }
    if (mismatches) {
      std::printf("%s splits=%d KV=%d head_dim=%d stages=%d mismatches=%d FAIL\n",
                  name, Splits, length, HeadDim, Stages, mismatches);
      check(cudaStreamDestroy(stream));
      return false;
    }
  }
  check(cudaStreamDestroy(stream));
  std::printf("%s splits=%d KV=%d head_dim=%d stages=%d checked_launches=%d PASS\n",
              name, Splits, length, HeadDim, Stages, repetitions);
  return true;
}

} // namespace

int main() {
  // One tile per active split keeps scratch reuse out of these mailbox cases.
  bool okay = run_case("all-active-splits", 1024);
  okay &= run_case("one-active-split", 128);
  okay &= run_case("six-active-partial-tail", 656);
  return okay ? 0 : 1;
}
