/***************************************************************************************************
* Copyright (c) 2024 - 2024 Codeplay Software Ltd. All rights reserved.
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

#include <sycl/sycl.hpp>
#include <syclcompat.hpp>

#if defined(CUTLASS_SYCL_PROFILING_ENABLED)
#include "cutlass/util/sycl_event_manager.hpp"
#endif

struct SYCLTimer {
  SYCLTimer() {
#if defined(CUTLASS_SYCL_PROFILING_ENABLED)
    start_ = SyclEvent{};
    stop_ = SyclEvent{};
#endif
  }

  ~SYCLTimer() {
#if defined(CUTLASS_SYCL_PROFILING_ENABLED)
    syclEventDestroy(start_);
    syclEventDestroy(stop_);
#endif
  }

  void start() {
#if defined(CUTLASS_SYCL_PROFILING_ENABLED)
    syclEventRecord(start_);
#else
    syclcompat::get_default_queue().wait();
    start_ = std::chrono::high_resolution_clock::now();
#endif
  }

    void stop() {
#if defined(CUTLASS_SYCL_PROFILING_ENABLED)
    syclEventRecord(stop_);
#else
    syclcompat::get_default_queue().wait();
    stop_ = std::chrono::high_resolution_clock::now();
#endif
  }

  float milliseconds() {
#if defined(CUTLASS_SYCL_PROFILING_ENABLED)
    syclEventSynchronize(start_, stop_);
    float time;
    syclEventElapsedTime(&time, start_, stop_);
    return time;
#else
    syclcompat::get_default_queue().wait();
    auto stop = std::chrono::high_resolution_clock::now();
    std::chrono::duration<float, std::milli> time = stop - start_;
    return time.count();
#endif
  }

  float seconds() {
    return milliseconds() * float(1e-3);
  }

 private:
#if defined(CUTLASS_SYCL_PROFILING_ENABLED)
    SyclEvent start_, stop_;
#else
    typedef std::chrono::nanoseconds				                  duration;
    typedef std::chrono::high_resolution_clock		                  high_resolution_clock;
    typedef std::chrono::time_point<high_resolution_clock, duration>  time_point;

    time_point start_ = std::chrono::high_resolution_clock::now();
    time_point stop_ = std::chrono::high_resolution_clock::now();
#endif
};
