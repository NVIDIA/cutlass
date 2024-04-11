/***************************************************************************************************
 * Copyright (c) 2023 - 2024 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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

#if defined(CUTLASS_ENABLE_SYCL)
#include <syclcompat.hpp>
#include <chrono>
#else
#include <cuda_runtime.h>
#endif

struct GPU_Clock
{
#if !defined(CUTLASS_ENABLE_SYCL)
  GPU_Clock() {
    cudaEventCreate(&start_);
    cudaEventCreate(&stop_);
    cudaEventRecord(start_);
  }

  ~GPU_Clock() {
    cudaEventDestroy(start_);
    cudaEventDestroy(stop_);
  }
#endif

  void start() {
#if defined(CUTLASS_ENABLE_SYCL)
    syclcompat::get_default_queue().wait();
    start_ = std::chrono::high_resolution_clock::now();
#else
    cudaEventRecord(start_);
#endif
  }

  float milliseconds() {
#if defined(CUTLASS_ENABLE_SYCL)
    syclcompat::get_default_queue().wait();
    auto stop = std::chrono::high_resolution_clock::now();
    std::chrono::duration<float, std::milli> time = stop - start_;
    return time.count();
#else
    cudaEventRecord(stop_);
    cudaEventSynchronize(stop_);
    float time;
    cudaEventElapsedTime(&time, start_, stop_);
    return time;
#endif
  }

  float seconds() {
    return milliseconds() * float(1e-3);
  }

 private:
#if defined(CUTLASS_ENABLE_SYCL)
    typedef std::chrono::nanoseconds				                  duration;
    typedef std::chrono::high_resolution_clock		                  high_resolution_clock;
    typedef std::chrono::time_point<high_resolution_clock, duration>  time_point;

    time_point start_ = std::chrono::high_resolution_clock::now();
#else
    cudaEvent_t start_, stop_;
#endif
};
