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
/* \file
   \brief Defines a math function
*/

#include <stdexcept>
#include <string>
#include <utility>

#include "cutlass/profiler/gpu_timer.h"

namespace cutlass {
namespace profiler {

inline void throw_cuda_error(cudaError_t result, const char* msg) {
  throw std::runtime_error(std::string(msg) + ": " + cudaGetErrorString(result));
}

GpuTimer::GpuTimer() {
  for (size_t i = 0; i < 2; ++i) {
    cudaError_t result = cudaEventCreate(&events[i]);
    if (result != cudaSuccess) {
      for (size_t j = 0; j < i; ++j) {
        cudaEventDestroy(events[j]);
      }
      throw_cuda_error(result, "Failed to create CUDA event");
    }
  }
}

GpuTimer::GpuTimer(GpuTimer&& other) noexcept {
  for (size_t i = 0; i < 2; ++i) {
    events[i] = std::exchange(other.events[i], nullptr);
  }
}

GpuTimer& GpuTimer::operator=(GpuTimer&& other) noexcept {
  if (this != &other) {
    for (auto& event : events) {
      if (event) cudaEventDestroy(event);
    }
    for (size_t i = 0; i < 2; ++i) {
      events[i] = std::exchange(other.events[i], nullptr);
    }
  }
  return *this;
}

GpuTimer::~GpuTimer() {
  for (auto& event : events) {
    if (event != nullptr) {
      cudaEventDestroy(event);
    }
  }
}

void GpuTimer::start(cudaStream_t stream, const unsigned int flag) {
  cudaError_t result = cudaEventRecordWithFlags(events[0], stream, flag);
  if (result != cudaSuccess) {
    throw_cuda_error(result, "Failed to record start event");
  }
}

void GpuTimer::stop(cudaStream_t stream, const unsigned int flag) {
  cudaError_t result = cudaEventRecordWithFlags(events[1], stream, flag);
  if (result != cudaSuccess) {
    throw_cuda_error(result, "Failed to record stop event");
  }
}

void GpuTimer::stop_and_wait(cudaStream_t stream, const unsigned int flag) {
  stop(stream, flag);

  cudaError_t result = cudaEventSynchronize(events[1]);
  if (result != cudaSuccess) {
    throw_cuda_error(result, "Failed to synchronize stop event");
  }
}

double GpuTimer::duration(int iterations) const {
  if (iterations <= 0) {
    throw std::invalid_argument("GpuTimer::duration requires iterations > 0");
  }

  cudaError_t sync_res = cudaEventSynchronize(events[1]);
  if (sync_res != cudaSuccess) {
    throw_cuda_error(sync_res, "Failed to sync event prior to duration calculation");
  }

  float avg_ms = 0.0f;
  cudaError_t result = cudaEventElapsedTime(&avg_ms, events[0], events[1]);
  if (result != cudaSuccess) {
    throw_cuda_error(result, "Failed to query elapsed time");
  }

  return static_cast<double>(avg_ms) / iterations;
}

} // namespace profiler
} // namespace cutlass
