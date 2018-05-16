/***************************************************************************************************
 * Copyright (c) 2017-2018, NVIDIA CORPORATION.  All rights reserved.
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
/*! \file
    \brief Type traits for common CUDA types
*/

#pragma once

#include <cublas_v2.h>
#include <cuda_fp16.h>
#include <stdint.h>

#include "half.h"

namespace cutlass {
struct half_t;

template <typename T>
struct TypeTraits;

template <>
struct TypeTraits<int8_t> {
  static cudaDataType_t const cublas_type = CUDA_R_8I;
  typedef int8_t host_type;
  typedef int8_t device_type;
  typedef int8_t integer_type;
  typedef uint8_t unsigned_type;
  static inline int8_t remove_negative_zero(int8_t x) { return x; }
  static inline int to_print(int8_t x) { return (int)x; }
};

template <>
struct TypeTraits<uint8_t> {
  static cudaDataType_t const cublas_type = CUDA_R_8I;
  typedef uint8_t host_type;
  typedef uint8_t device_type;
  typedef uint8_t integer_type;
  typedef uint8_t unsigned_type;
  static inline uint8_t remove_negative_zero(uint8_t x) { return x; }
  static inline uint32_t to_print(uint8_t x) { return (uint32_t)x; }
};

template <>
struct TypeTraits<int> {
  static cudaDataType_t const cublas_type = CUDA_R_32I;
  typedef int host_type;
  typedef int device_type;
  typedef int32_t integer_type;
  typedef uint32_t unsigned_type;
  static inline int32_t remove_negative_zero(int32_t x) { return x; }
  static inline int to_print(int x) { return x; }
};

template <>
struct TypeTraits<unsigned> {
  static cudaDataType_t const cublas_type = CUDA_R_32I;
  typedef unsigned host_type;
  typedef unsigned device_type;
  typedef uint32_t integer_type;
  typedef uint32_t unsigned_type;
  static inline uint32_t remove_negative_zero(uint32_t x) { return x; }
  static inline uint32_t to_print(uint32_t x) { return x; }
};

template <>
struct TypeTraits<half> {
  static cudaDataType_t const cublas_type = CUDA_R_16F;
  typedef half_t host_type;
  typedef half device_type;
  typedef int16_t integer_type;
  typedef uint16_t unsigned_type;
  static inline half remove_negative_zero(half x) {
    integer_type h_int = reinterpret_cast<integer_type const&>(x);
    if (h_int == 0x8000) {
      h_int = 0;
    }
    x = reinterpret_cast<half const&>(h_int);
    return x;
  }
  static inline half to_print(half x) { return x; }
};

template <>
struct TypeTraits<int64_t> {
  static cudaDataType_t const cublas_type = CUDA_R_8I;
  typedef int64_t host_type;
  typedef int64_t device_type;
  typedef int64_t integer_type;
  typedef uint64_t unsigned_type;
  static inline int64_t remove_negative_zero(int64_t x) { return x; }
  static inline int64_t to_print(int64_t x) { return x; }
};

template <>
struct TypeTraits<uint64_t> {
  static cudaDataType_t const cublas_type = CUDA_R_8I;
  typedef uint64_t host_type;
  typedef uint64_t device_type;
  typedef uint64_t integer_type;
  typedef uint64_t unsigned_type;
  static inline uint64_t remove_negative_zero(uint64_t x) { return x; }
  static inline uint64_t to_print(uint64_t x) { return x; }
};

template <>
struct TypeTraits<cutlass::half_t> {
  static cudaDataType_t const cublas_type = CUDA_R_16F;
  typedef half_t host_type;
  typedef half device_type;
  typedef int16_t integer_type;
  typedef uint16_t unsigned_type;
  static inline half_t remove_negative_zero(half_t x) {
    return (x.raw() == 0x8000 ? half_t::bitcast(0) : x);
  }
  static inline half_t to_print(half_t x) { return x; }
};

template <>
struct TypeTraits<float> {
  static cudaDataType_t const cublas_type = CUDA_R_32F;
  typedef float host_type;
  typedef float device_type;
  typedef int32_t integer_type;
  typedef uint32_t unsigned_type;
  static inline float remove_negative_zero(float x) { return x == -0.f ? 0.f : x; }
  static inline float to_print(float x) { return x; }
};

template <>
struct TypeTraits<double> {
  static cudaDataType_t const cublas_type = CUDA_R_64F;
  typedef double host_type;
  typedef double device_type;
  typedef int64_t integer_type;
  typedef uint64_t unsigned_type;
  static inline double remove_negative_zero(double x) { return x == -0.0 ? 0.0 : x; }
  static inline double to_print(double x) { return x; }
};
}  // namespace cutlass
