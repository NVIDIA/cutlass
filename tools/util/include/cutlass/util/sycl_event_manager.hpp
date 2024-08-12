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

#include <vector>
#include <sycl/sycl.hpp>

class SyclEvent {
private:
  int index;
public:
  SyclEvent() : index(-1) {
  };

  int getIndex() const {
    return index;
  }

  SyclEvent& operator=(int const& value) {
    index = value;
    return *this;
  };
};

class EventManager {
public:
  static EventManager& getInstance()
  {
    static EventManager instance;
    return instance;
  }
private:
  EventManager() {}
  std::vector<sycl::event> events{};
  int recorders = 0;

public:
  EventManager(EventManager const&) = delete;
  void operator=(EventManager const&) = delete;

  void startRecording(SyclEvent &event) {
    if (event.getIndex() != -1) {
      throw std::runtime_error("Event is already being recorded.");
    }
    recorders++;
    event = static_cast<int>(events.size());
  }

  void addEvent(const sycl::event &event) {
    events.push_back(event);
  }

  void eventDestroy() {
    recorders--;
    if (!recorders) {
      events.clear();
    }
  }

  float getEventElapsedTimeMs(SyclEvent const& begin, SyclEvent const& end) const {
    if (begin.getIndex() < 0 || begin.getIndex() > end.getIndex() || end.getIndex() > events.size()) {
      throw std::runtime_error("Index out of bounds");
    }

    auto time_event = 0.0f;
#if defined(CUTLASS_SYCL_PROFILING_ENABLED)
    for (int i = begin.getIndex(); i < end.getIndex(); ++i) {
      const auto start_time = events[i].template get_profiling_info<
              sycl::info::event_profiling::command_start>();

      const auto end_time = events[i].template get_profiling_info<
              sycl::info::event_profiling::command_end>();

      time_event += static_cast<float>(end_time - start_time);
    }
#else
    CUTLASS_ASSERT(false && "Profiling information can not be collected. "
                            "Use CUTLASS_SYCL_PROFILING_ENABLED.");
#endif
    return time_event * 1e-6f;
  }

  void wait(SyclEvent const& begin, SyclEvent const& end) {
    if (begin.getIndex() < 0 || begin.getIndex() > end.getIndex() || end.getIndex() > events.size()) {
      throw std::runtime_error("Index out of bounds");
    }

    for (int i = begin.getIndex(); i < end.getIndex(); ++i) {
      events[i].wait();
    }
  }
};

inline void syclEventDestroy(SyclEvent const&) {
  EventManager::getInstance().eventDestroy();
}

inline void syclEventRecord(SyclEvent &event) {
  EventManager::getInstance().startRecording(event);
}

inline void syclEventSynchronize(SyclEvent const& begin, SyclEvent const& end) {
  EventManager::getInstance().wait(begin, end);
}

inline void syclEventElapsedTime(float* time, SyclEvent const& begin, SyclEvent const& end) {
  *time = EventManager::getInstance().getEventElapsedTimeMs(begin, end);
}
