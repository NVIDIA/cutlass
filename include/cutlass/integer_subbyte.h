/***************************************************************************************************
 * Copyright (c) 2019, NVIDIA CORPORATION.  All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted
 * provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this list of
 *       conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above copyright notice, this list of
 *       conditions and the following disclaimer in the documentation and/or other materials
 *       provided with the distribution.
 *     * Neither the name of the NVIDIA CORPORATION nor the names of its contributors may be used
 *       to endorse or promote products derived from this software without specific prior written
 *       permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND
 * FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL NVIDIA CORPORATION BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
 * BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TOR (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 **************************************************************************************************/
/*!
    \file
    \brief Defines a class for using integer types smaller than one byte in host or
      device code.
*/
#pragma once

#if defined(__CUDACC_RTC__)
#include <cuda/std/cstdint>
#else
#include <cstdint>
#endif

#include "cutlass/platform/platform.h"

namespace cutlass {

///////////////////////////////////////////////////////////////////////////////////////////////////

/// 4-bit signed integer type
template <int Bits, bool Signed = true>
struct integer_subbyte {

  /// Number of bits
  static int const kBits = Bits;

  /// Whether type is signed
  static bool const kSigned = Signed;

  /// External type
  using T = typename platform::conditional<kSigned, int, unsigned>::type;

  /// Storage type
  using Storage = uint8_t;

  /// Bitmask used to truncate from larger integers
  static Storage const kMask = Storage((1 << kBits) - 1);

  //
  // Data members
  //

  Storage storage;

  //
  // Methods
  //

  /// No operation
  CUTLASS_HOST_DEVICE
  integer_subbyte() { }

  /// Conversion from integer type
  CUTLASS_HOST_DEVICE
  integer_subbyte(int value)
      : storage(reinterpret_cast<Storage const &>(value) & kMask) {}

  CUTLASS_HOST_DEVICE
  integer_subbyte(unsigned value)
      : storage(reinterpret_cast<Storage const &>(value) & kMask) {}

  /// Conversion from double
  CUTLASS_HOST_DEVICE
  integer_subbyte(double value) {
    T tmp = (T)value;
    storage = reinterpret_cast<Storage const &>(tmp) & kMask;
  }

  ///
  CUTLASS_HOST_DEVICE
  operator T() const {
    if (kSigned) {
      // Sign extend
      if (storage & Storage(1 << (kBits - 1))) {
        return T(storage) | ~T(kMask);
      }
    }
    return T(storage);
  }

  /// Equality
  CUTLASS_HOST_DEVICE
  bool operator==(integer_subbyte const &rhs) const {
    return storage == rhs.storage;
  }

  /// Inequality
  CUTLASS_HOST_DEVICE
  bool operator!=(integer_subbyte const &rhs) const {
    return storage != rhs.storage;
  }

  /// Less than or equal
  CUTLASS_HOST_DEVICE
  bool operator<=(integer_subbyte const &rhs) const {
    if (kSigned) {
      if (storage & (1 << (kBits - 1))) {
        return !(rhs.storage < storage);
      }
    }
    return storage < rhs.storage;
  }

  /// Less than
  CUTLASS_HOST_DEVICE
  bool operator<(integer_subbyte const &rhs) const {
    if (kSigned) {
      if (storage & (1 << (kBits - 1))) {
        return !(rhs.storage <= storage);
      }
    }
    return storage < rhs.storage;
  }

  /// Greater than or equal
  CUTLASS_HOST_DEVICE
  bool operator>=(integer_subbyte const &rhs) const {
    return !(*this < rhs);
  }

  /// Greater than
  CUTLASS_HOST_DEVICE
  bool operator>(integer_subbyte const &rhs) const {
    return !(rhs < *this);
  }
};

///////////////////////////////////////////////////////////////////////////////////////////////////


/// 1-bit Unsigned integer type
using uint1b_t = integer_subbyte<1, false>;

/// 4-bit Integer type
using int4b_t = integer_subbyte<4, true>;

/// 4-bit Unsigned integer type
using uint4b_t = integer_subbyte<4, false>;

///////////////////////////////////////////////////////////////////////////////////////////////////

/// Defines the size of an element in bits - specialized for uint1b_t
template <>
struct sizeof_bits<uint1b_t> {
  static int const value = 1;
};

/// Defines the size of an element in bits - specialized for int4b_t
template <>
struct sizeof_bits<int4b_t> {
  static int const value = 4;
};

/// Defines the size of an element in bits - specialized for uint4b_t
template <>
struct sizeof_bits<uint4b_t> {
  static int const value = 4;
};

///////////////////////////////////////////////////////////////////////////////////////////////////

} // namespace cutlass
