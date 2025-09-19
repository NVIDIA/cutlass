/***************************************************************************************************
 * Copyright (c) 2023 - 2025 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
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
/*! \file
    \brief Initialize a block of device data
*/

#pragma once
#ifdef CUTLASS_ENABLE_SYCL
#include <compat.hpp> 
#else
#include <cuda.h>
#endif
#include "cute/tensor.hpp"
#include "cutlass/cutlass.h"
#include "cutlass/util/device_memory.h"
#ifdef CUTLASS_ENABLE_SYCL
#include "cutlass/util/reference/device/sycl_tensor_fill.h"
#else
#include "cutlass/util/reference/device/tensor_fill.h"
#endif
#include "cute/util/type_traits.hpp"

namespace cutlass {
template <class T, class = void>
static constexpr auto is_signed_v = cute::is_signed<T>::value;

template<class T>
static constexpr auto digits = std::numeric_limits<T>::digits > 0 ? std::numeric_limits<T>::digits : cute::numeric_limits<T>::digits;

template<class T, class = void>
auto max_for_test = T(1 << cute::ceil_div(digits<T> , 4));

template<class T>
auto max_for_test<T, std::enable_if_t<cute::sizeof_bits_v<T> < 8>> = T(cutlass::platform::numeric_limits<T>::max() / 2);

/// Helper to initialize a block of device data
template <class Element, class... Args_t>
bool initialize_block(Element* block, std::size_t size, uint64_t seed, Args_t&&... args) {
  static_assert(sizeof...(Args_t) == 0 || sizeof...(Args_t) == 2);

  Element scope_max;
  Element scope_min;

  if constexpr ( sizeof...(Args_t) == 2) {
    auto tuple_args = std::forward_as_tuple(std::forward<Args_t>(args)...);
    scope_min = Element(std::get<0>(tuple_args));
    scope_max = Element(std::get<1>(tuple_args));
  } else {
    scope_max = max_for_test<Element>;
    scope_min = is_signed_v<Element> ? Element(-scope_max) : Element(1);
  }

  if constexpr (cute::sizeof_bits_v<Element> >= 8) {
    cutlass::reference::device::BlockFillRandomUniform(block, size, seed, scope_max, scope_min, 0);
  } else {
    std::uniform_int_distribution<> dist(scope_min, scope_max);

    std::ranlux24_base rng(std::random_device{}());
    rng.seed(seed);

    static constexpr auto array_size = 1024;

    cute::array_subbyte<Element, array_size> block_host{};

    for (int i = 0; i < block_host.size(); ++i) {
      block_host[i] = static_cast<Element>(dist(rng));
    }

    static constexpr auto elements_per_byte = cute::sizeof_bits_v<int8_t> / cute::sizeof_bits_v<Element>;

    int loop_cnt = size / array_size;
    for (int i = 0; i < loop_cnt; i++) {
      cutlass::device_memory::copy_to_device(((uint8_t*)(block)) + (i * array_size) / elements_per_byte,
                                    (uint8_t*)(raw_pointer_cast(block_host.begin())),
                                    array_size / elements_per_byte);
    }

    auto tail_size = size % array_size;
    if (tail_size) {
      cutlass::device_memory::copy_to_device(((uint8_t*)block) + (loop_cnt * array_size) / elements_per_byte,
                                    (uint8_t*)(raw_pointer_cast(block_host.begin())),
                                    tail_size / elements_per_byte);
    }
  }

  compat::wait();
  return true;
}

template <class Element, class... Args_t>
bool initialize_block(cutlass::DeviceAllocation<Element>& block, uint64_t seed, Args_t&&... args) {
  return initialize_block<Element>(block.get(), block.size(), seed, args...);
}

template <typename T1, typename T2, class... Args_t>
void initialize_mixed_dtype_block(cutlass::DeviceAllocation<T1>& block_device,
                                  cutlass::DeviceAllocation<T2>& block_device_dq,
                                  uint64_t seed,
                                  Args_t&&... args) {
  static_assert(cute::sizeof_bits_v<T2> >= 8);
  static_assert(sizeof...(Args_t) == 0 || sizeof...(Args_t) == 2);

  T1 scope_max;
  T1 scope_min;

  if constexpr ( sizeof...(Args_t) == 2) {
    auto tuple_args = std::forward_as_tuple(std::forward<Args_t>(args)...);
    scope_min = std::get<0>(tuple_args);
    scope_max = std::get<1>(tuple_args);
  } else {
    scope_max = max_for_test<T1>;
    scope_min = is_signed_v<T1> ? T1(-scope_max) : T1(1);
  }

  std::uniform_int_distribution<> dist(scope_min, scope_max);

  std::ranlux24_base rng(std::random_device{}());
  rng.seed(seed);

  if constexpr (cute::sizeof_bits_v<T1> >= 8) {
    auto block_host = std::vector<T1>(block_device.size());
    auto block_host_dq = std::vector<T2>(block_device.size());
    for (int i = 0; i < block_host.size(); ++i) {
      block_host[i] = static_cast<T1>(dist(rng));
      block_host_dq[i] = static_cast<T2>(block_host[i]);
    }

    block_device.copy_from_host(block_host.data());
    block_device_dq.copy_from_host(block_host_dq.data());
  } else {
    static constexpr auto array_size = 1024;

    cute::array_subbyte<T1, array_size> block_host{};
    auto block_host_dq = std::vector<T2>(array_size);

    for (int i = 0; i < block_host.size(); ++i) {
      block_host[i] = static_cast<T1>(dist(rng));
      block_host_dq[i] = static_cast<T2>(block_host[i].get());
    }

    static constexpr auto elements_per_byte = cute::sizeof_bits_v<int8_t> / cute::sizeof_bits_v<T1>;

    int loop_cnt = block_device.size() / array_size;
    for (int i = 0; i < loop_cnt; i++) {
      cutlass::device_memory::copy_to_device(((uint8_t*)(block_device.get())) + (i * array_size) / elements_per_byte,
                                    (uint8_t*)(raw_pointer_cast(block_host.begin())),
                                    array_size / elements_per_byte);
      cutlass::device_memory::copy_to_device(block_device_dq.get() + i * array_size,
                                    block_host_dq.data(),
                                    array_size);
    }

    auto tail_size = block_device.size() % array_size;
    if (tail_size) {
      cutlass::device_memory::copy_to_device(((uint8_t*)block_device.get()) + (loop_cnt * array_size) / elements_per_byte,
                                    (uint8_t*)(raw_pointer_cast(block_host.begin())),
                                    tail_size / elements_per_byte);
      cutlass::device_memory::copy_to_device(block_device_dq.get() + loop_cnt * array_size,
                                    block_host_dq.data(),
                                    tail_size);
    }
  }

  compat::wait();
}

#undef CUDA_CHECK

}  // namespace cutlass
