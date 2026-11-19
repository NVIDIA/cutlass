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

#pragma once


#include <algorithm>
#include <cstddef>
#include <cstdint>
#include <vector>

#include "cute/tensor.hpp"
#include "cutlass/fast_math.h"
#include "cutlass/numeric_types.h"
#include "cutlass/util/device_memory.h"
#include "cutlass/util/reference/device/tensor_fill.h"

#include "helper.h"
#include "options.hpp"

template <class Element>
__global__ void sentinel_fill_kernel(Element *ptr, size_t n) {
  size_t stride = size_t(gridDim.x) * blockDim.x;
  for (size_t i = blockIdx.x * size_t(blockDim.x) + threadIdx.x; i < n; i += stride) {
    ptr[i] = cutlass::constants::negative_zero<Element>();
  }
}

template <class Gemm>
class MemoryPool {
public:
  using ElementA = typename Gemm::ElementA;
  using ElementB = typename Gemm::ElementB;
  using ElementD = typename Gemm::ElementD;

  static constexpr size_t kAlignmentBytes = 16;

  int num_gemms() const { return static_cast<int>(steps.size()); }

  void allocate_tensors(Options const &options, int num_chunks = 1) {
    num_chunks_ = num_chunks;
    steps.assign(options.num_gemms(), {});

    size_t offset = 0;
    for (int i = 0; i < num_gemms(); ++i) {
      plan_step(i, options, offset);
    }
    chunk_stride_ = cutlass::round_nearest(offset, kAlignmentBytes);
    pool.reset(chunk_stride_ * static_cast<size_t>(num_chunks_));
  }

  void allocate_workspaces(std::vector<size_t> const &workspace_sizes) {
    workspace_offsets.resize(workspace_sizes.size());
    size_t offset = 0;
    for (size_t i = 0; i < workspace_sizes.size(); ++i) {
      workspace_offsets[i] = offset;
      offset = cutlass::round_nearest(offset + workspace_sizes[i], kAlignmentBytes);
    }
    workspace_mem.reset(offset);
  }

  uint8_t * workspace_ptr(int i) const { return workspace_mem.get() + workspace_offsets[i]; }

  ElementA* ptr_A(int i, int chunk = 0) const {
    return reinterpret_cast<ElementA*>(chunk_base(chunk) + steps[i].off_A);
  }
  ElementB* ptr_B(int i, int chunk = 0) const {
    return reinterpret_cast<ElementB*>(chunk_base(chunk) + steps[i].off_B);
  }
  ElementD* ptr_D(int i, int chunk = 0) const {
    return reinterpret_cast<ElementD*>(chunk_base(chunk) + steps[i].off_D);
  }

  /// Random-fill the input operands of every chunk
  void init_inputs(uint64_t seed, cudaStream_t stream = nullptr, int bits = -1) {
    using RA = typename cutlass::RealType<ElementA>::Type;
    using RB = typename cutlass::RealType<ElementB>::Type;
    for (int c = 0; c < num_chunks_; ++c) {
      uint64_t chunk_seed = seed + static_cast<uint64_t>(c) * 1000;
      for (int i = 0; i < num_gemms(); ++i) {
        if (not steps[i].alias_A) {
          cutlass::reference::device::BlockFillRandomUniform<ElementA>(
            ptr_A(i, c), steps[i].cap_A, chunk_seed + 1 + static_cast<uint64_t>(i),
            static_cast<RA>(2), static_cast<RA>(-2), bits, /*pnan=*/0, stream);
        }
        if (not steps[i].alias_B) {
          cutlass::reference::device::BlockFillRandomUniform<ElementB>(
            ptr_B(i, c), steps[i].cap_B, chunk_seed + 100 + static_cast<uint64_t>(i),
            static_cast<RB>(2), static_cast<RB>(-2), bits, /*pnan=*/0, stream);
        }
      }
    }
  }

  /// Sentinel-fill (-0.0) every chunk's D outputs for data-driven sync consumers.
  void init_sentinel(cudaStream_t stream = nullptr) {
    constexpr int threads = 256;
    for (int c = 0; c < num_chunks_; ++c) {
      for (int i = 0; i < num_gemms(); ++i) {
        size_t cap_D = steps[i].cap_D;
        if (cap_D == 0) continue;
        int blocks = static_cast<int>(std::min<size_t>((cap_D + threads - 1) / threads, 4096));
        sentinel_fill_kernel<ElementD><<<blocks, threads, 0, stream>>>(ptr_D(i, c), cap_D);
        CUDA_CHECK(cudaGetLastError());
      }
    }
  }

private:
  struct Step {
    size_t off_A = 0, off_B = 0, off_D = 0;
    size_t cap_A = 0, cap_B = 0, cap_D = 0;
    bool alias_A = false, alias_B = false;
  };

  cutlass::DeviceAllocation<uint8_t> pool;
  cutlass::DeviceAllocation<uint8_t> workspace_mem;
  std::vector<size_t> workspace_offsets;
  int num_chunks_ = 1;
  size_t chunk_stride_ = 0;  // rounded byte size of one tensor-region copy
  std::vector<Step> steps;

  uint8_t * chunk_base(int chunk) const {
    return pool.get() + static_cast<size_t>(chunk) * chunk_stride_;
  }

  void plan_step(int i, Options const &options, size_t& offset) {
    auto problem = options.get_gemm_shape(i);
    Step &s = steps[i];
    s.cap_A = static_cast<size_t>(cute::size(cute::select<0, 2, 3>(problem)));
    s.cap_B = static_cast<size_t>(cute::size(cute::select<1, 2, 3>(problem)));
    s.cap_D = static_cast<size_t>(cute::size(cute::select<0, 1, 3>(problem)));
    s.alias_A = i > 0 && options.deps[i - 1] == Dependency::A;
    s.alias_B = i > 0 && options.deps[i - 1] == Dependency::B;

    if (s.alias_A) {
      s.off_A = steps[i - 1].off_D;
    } else {
      s.off_A = offset;
      offset = cutlass::round_nearest(offset + s.cap_A * sizeof(ElementA), kAlignmentBytes);
    }

    if (s.alias_B) {
      s.off_B = steps[i - 1].off_D;
    } else {
      s.off_B = offset;
      offset = cutlass::round_nearest(offset + s.cap_B * sizeof(ElementB), kAlignmentBytes);
    }

    s.off_D = offset;
    offset = cutlass::round_nearest(offset + s.cap_D * sizeof(ElementD), kAlignmentBytes);
  }
};
