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

#include "cutlass/util/device_memory.h"
#include "cutlass/util/reference/device/sycl_tensor_fill.h"

/// Helper to initialize a block of device data
template <class Element>
bool initialize_block(
        cutlass::DeviceAllocation<Element>& block,
        uint64_t seed=2023) {

  Element scope_max, scope_min;
  int bits_input = cutlass::sizeof_bits<Element>::value;

  if (bits_input == 1) {
   scope_max = Element(2);
   scope_min = Element(0);
  } else if (bits_input <= 8) {
    scope_max = Element(2);
    scope_min = Element(-2);
  } else {
    scope_max = Element(8);
    scope_min = Element(-8);
  }

  cutlass::reference::device::BlockFillRandomUniform(
       block.get(), block.size(), seed, scope_max, scope_min, 0);

  syclcompat::wait();
  return true;
}

template <typename T1, typename T2>
void initialize_mixed_dtype_block(cutlass::DeviceAllocation<T1>& block_device,
                           cutlass::DeviceAllocation<T2>& block_device_dq,
                          uint64_t seed) {
  static_assert(cute::sizeof_bits_v<T2> >= 8);

  std::ranlux24_base rng(std::random_device{}());
  rng.seed(seed);

  int bits_input = cute::sizeof_bits_v<T1>;
  T1 scope_max, scope_min;
  if (bits_input == 1) {
   scope_max = T1(2);
   scope_min = T1(0);
  } else if (bits_input <= 8) {
    scope_max = T1(2);
    scope_min = T1(-2);
  } else {
    scope_max = T1(8);
    scope_min = T1(-8);
  }

  std::uniform_int_distribution<> dist(scope_min, scope_max);

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
      cutlass::device_memory::copy_to_device(block_device.get() + (i * array_size) / elements_per_byte,
                                    raw_pointer_cast(block_host.begin()),
                                    array_size);
      cutlass::device_memory::copy_to_device(block_device_dq.get() + i * array_size,
                                    block_host_dq.data(),
                                    array_size);
    }

    auto tail_size = block_device.size() % array_size;
    if (tail_size) {
      cutlass::device_memory::copy_to_device(block_device.get() + (loop_cnt * array_size) / elements_per_byte,
                                    raw_pointer_cast(block_host.begin()),
                                    tail_size);
      cutlass::device_memory::copy_to_device(block_device_dq.get() + loop_cnt * array_size,
                                    block_host_dq.data(),
                                    tail_size);
    }
  }
}
