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

#include <cstdint>

#include "cutlass/float8.h"
#include "cutlass/util/reference/device/tensor_fill.h"

#include "cute/tensor.hpp"
#include "cute/util/type_traits.hpp"

namespace cutlass
{
template<typename T>
class packed_scale_t {
public:
  static_assert(cute::is_same_v<T, cutlass::int8_t> ||
                cute::is_same_v<T, cutlass::uint8_t> ||
                cute::is_same_v<T, cutlass::float_e4m3_t> ||
                cute::is_same_v<T, cutlass::float_e5m2_t>,
                "only 8 bit arithmetic types are supported.");
  CUTLASS_HOST_DEVICE
  explicit packed_scale_t(T val) {
    if constexpr (!cute::is_unsigned_v<T>) {
      // Only pack negative values. The positive values are generated in flight in the mainloop.
      storage[0] = pack4(T(float(val) * -8.f), T(float(val) * -7.f), T(float(val) * -6.f), T(float(val) * -5.f));
      storage[1] = pack4(T(float(val) * -4.f), T(float(val) * -3.f), T(float(val) * -2.f), -val);
    }
    else {
      storage[0] = pack4(T(float(val) * 8.f), T(float(val) * 7.f), T(float(val) * 6.f), T(float(val) * 5.f));
      storage[1] = pack4(T(float(val) * 4.f), T(float(val) * 3.f), T(float(val) * 2.f), val);
    }
  }
  CUTLASS_HOST_DEVICE
  packed_scale_t() = default;
  CUTLASS_HOST_DEVICE
  explicit operator float() const {
    return float(get());
  }
  CUTLASS_HOST_DEVICE
  bool operator==(packed_scale_t const& rhs) const {
    return storage[0] == rhs.storage[0] && storage[1] == rhs.storage[1];
  }
  CUTLASS_HOST_DEVICE
  bool operator!=(packed_scale_t const& rhs) const {
    return !(*this == rhs);
  }
  CUTLASS_HOST_DEVICE
  friend packed_scale_t operator+(packed_scale_t const& lhs, packed_scale_t const& rhs) {
    return packed_scale_t(lhs.get() + rhs.get());
  }
  CUTLASS_HOST_DEVICE
  friend packed_scale_t operator-(packed_scale_t const& lhs, packed_scale_t const& rhs) {
    return packed_scale_t(lhs.get() - rhs.get());
  }
  CUTLASS_HOST_DEVICE
  friend packed_scale_t operator*(packed_scale_t const& lhs, packed_scale_t const& rhs) {
    return packed_scale_t(lhs.get() * rhs.get());
  }
  CUTLASS_HOST_DEVICE
  friend packed_scale_t operator/(packed_scale_t const& lhs, packed_scale_t const& rhs) {
    return packed_scale_t(lhs.get() / rhs.get());
  }

private:
  using Storage = uint32_t;
  using Stage = uint8_t;

  Storage storage[2] {};

  CUTLASS_HOST_DEVICE
  static Storage pack4(T c1, T c2, T c3, T c4) {
    Storage result = 0;
    result |= (static_cast<Storage>(reinterpret_cast<Stage const&>(c4)) << 24);
    result |= (static_cast<Storage>(reinterpret_cast<Stage const&>(c3)) << 16);
    result |= (static_cast<Storage>(reinterpret_cast<Stage const&>(c2)) << 8);
    result |= static_cast<Storage>(reinterpret_cast<Stage const&>(c1));
    return result;
  }
  CUTLASS_HOST_DEVICE
  T get() const {
    auto stage = static_cast<Stage>(storage[0] >> 8);
    #if defined(__CUDA_ARCH__)
    return reinterpret_cast<T const&>(stage);
    #else
    T tmp;
    std::memcpy(&tmp, &stage, sizeof(Stage));
    return tmp;
    #endif
  }
  CUTLASS_HOST_DEVICE
  T get(int idx) const {
    Stage stage;
    if (idx < 4) stage = static_cast<Stage>(storage[0] >> (8 * idx));
    else         stage = static_cast<Stage>(storage[1] >> (8 * idx - 32));
    #if defined(__CUDA_ARCH__)
    return reinterpret_cast<T const&>(stage);
    #else
    T tmp;
    std::memcpy(&tmp, &stage, sizeof(Stage));
    return tmp;
    #endif
  }
};
}

/// Helpers to initialize scale lookup table

// In the mainloop, PRMT selects 1 byte from only 8 bytes so the sign bit is handled in an extra PRMT.
// Here the encodings of positive values and negative values are unified (except for the sign bit). 
// For instance, 1 becomes 0b0111, which is the same encoding as -1 (0b1111).
bool unify_quant_encoding(
  cutlass::DeviceAllocation<cutlass::int4b_t> const& block_in,
  cutlass::DeviceAllocation<cutlass::int4b_t>& block_out) {

  using StorageType = cutlass::int4b_t::Storage;

  if (block_in.size() != block_out.size()) {
    std::cerr << "block_in and block_out must have same size.\n";
    return false;
  }
  constexpr int pack = cute::sizeof_bits_v<StorageType> / 4;
  std::vector<StorageType> data(block_in.size() / pack);
  cutlass::device_memory::copy_to_host(data.data(), (StorageType*)block_in.get(), block_in.size() / pack);

  for (auto&& d : data) {
    StorageType out = 0;
    StorageType mask = 0x0f;
    for (int i = 0; i < pack; ++i) {
      cutlass::int4b_t curr;
      curr.storage = (d >> (i * 4)) & 0x0f;
      switch (curr) {
        case 1: curr.storage = StorageType(0b0111); break; // 2's complement
        case 2: curr.storage = StorageType(0b0110); break; // 2's complement
        case 3: curr.storage = StorageType(0b0101); break; // 2's complement
        case 4: curr.storage = StorageType(0b0100); break; // 2's complement
        case 5: curr.storage = StorageType(0b0011); break; // 2's complement
        case 6: curr.storage = StorageType(0b0010); break; // 2's complement
        case 7: curr.storage = StorageType(0b0001); break; // 2's complement
        default: break;
      }
      out |= (curr.storage << (4 * i)) & mask;
      mask <<= 4;
    }
    d = out;
  }

  cutlass::device_memory::copy_to_device((StorageType*)block_out.get(), data.data(), block_out.size() / pack);
  return true;
}

template <class ElementScale>
bool initialize_packed_scale(
  cutlass::DeviceAllocation<ElementScale> const& block_in, 
  cutlass::DeviceAllocation<cutlass::Array<ElementScale, 8> > & block_out) {
  
  std::vector<ElementScale> data_in(block_in.size());
  std::vector<cutlass::Array<ElementScale, 8> > data_out(block_in.size());
  try {
    block_in.copy_to_host(data_in.data());
  } catch (cutlass::cuda_exception const& e)
  {
    std::cerr << "CUDA Error: " << cudaGetErrorString(e.cudaError()) << std::endl;
    return false;
  }
  for (size_t i = 0; i < block_in.size(); ++i)
  {
    cutlass::packed_scale_t<ElementScale> tmp(data_in[i]);
    data_out[i] = reinterpret_cast<cutlass::Array<ElementScale, 8> const&>(tmp);
    // std::cout << data_in[i] << ":" << std::hex << static_cast<uint16_t>(data_in[i].storage) << ",\t" << -data_in[i] << ":" << std::hex << static_cast<uint16_t>((-data_in[i]).storage) << std::endl;
  }
  try {
    block_out.copy_from_host(data_out.data());
  } catch (cutlass::cuda_exception const& e)
  {
    std::cerr << "CUDA Error: " << cudaGetErrorString(e.cudaError()) << std::endl;
    return false;
  }
  return true;
}