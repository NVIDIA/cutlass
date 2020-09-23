/***************************************************************************************************
 * Copyright (c) 2017-2020, NVIDIA CORPORATION.  All rights reserved.
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
    \brief Architecture-specific operators on memory
*/

#pragma once

#include "cutlass/cutlass.h"

namespace cutlass {
namespace arch {

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// Fragment type to store loaded data
    typename AccessType,
    /// The bytes of loading
    int LoadBytes
    >
struct global_load;

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Specializations
//
/////////////////////////////////////////////////////////////////////////////////////////////////

/////////////////////////////////////////////////////////////////////////////////////////////////

// The redundant mov PTX instruction is used to enforce the compiler to
// initialize data to zero before ld.global
template <typename AccessType
         >
struct global_load<AccessType,
                   32 
                  > {
  CUTLASS_DEVICE
  global_load(AccessType &D, void const *ptr, bool pred_guard) {
  uint4 *data = reinterpret_cast<uint4 *>(&D);

  asm volatile(
      "{\n"
      "  .reg .pred p;\n"
      "  setp.ne.b32 p, %9, 0;\n"
      "  mov.b32 %0, %10;\n"
      "  mov.b32 %1, %11;\n"
      "  mov.b32 %2, %12;\n"
      "  mov.b32 %3, %13;\n"
      "  mov.b32 %4, %14;\n"
      "  mov.b32 %5, %15;\n"
      "  mov.b32 %6, %16;\n"
      "  mov.b32 %7, %17;\n"
      "  @p ld.global.v4.u32 {%0, %1, %2, %3}, [%8];\n"
      "  @p ld.global.v4.u32 {%4, %5, %6, %7}, [%18];\n"
      "}\n"
      : "=r"(data[0].x), "=r"(data[0].y), "=r"(data[0].z), "=r"(data[0].w),
        "=r"(data[1].x), "=r"(data[1].y), "=r"(data[1].z), "=r"(data[1].w)
      : "l"(ptr), "r"((int)pred_guard), "r"(data[0].x), "r"(data[0].y),
        "r"(data[0].z), "r"(data[0].w), "r"(data[1].x), "r"(data[1].y),
        "r"(data[1].z), "r"(data[1].w), "l"(((uint8_t *)ptr) + 16));
  }
};

template <typename AccessType
         >
struct global_load<AccessType,
                   16
                  > {
  CUTLASS_DEVICE
  global_load(AccessType &D, void const *ptr, bool pred_guard) {
  uint4 &data = reinterpret_cast<uint4 &>(D);

  asm volatile(
      "{\n"
      "  .reg .pred p;\n"
      "  setp.ne.b32 p, %5, 0;\n"
      "  mov.b32 %0, %6;\n"
      "  mov.b32 %1, %7;\n"
      "  mov.b32 %2, %8;\n"
      "  mov.b32 %3, %9;\n"
      "  @p ld.global.v4.u32 {%0, %1, %2, %3}, [%4];\n"
      "}\n"
      : "=r"(data.x), "=r"(data.y), "=r"(data.z), "=r"(data.w)
      : "l"(ptr), "r"((int)pred_guard), "r"(data.x), "r"(data.y), "r"(data.z), "r"(data.w));
  }
};

template <typename AccessType
         >
struct global_load<AccessType,
                   8
                  > {
  CUTLASS_DEVICE
  global_load(AccessType &D, void const *ptr, bool pred_guard) {
  uint2 &data = reinterpret_cast<uint2 &>(D);

  asm volatile(
      "{\n"
      "  .reg .pred p;\n"
      "  setp.ne.b32 p, %3, 0;\n"
      "  mov.b32 %0, %4;\n"
      "  mov.b32 %1, %5;\n"
      "  @p ld.global.v2.u32 {%0, %1}, [%2];\n"
      "}\n"
      : "=r"(data.x), "=r"(data.y)
      : "l"(ptr), "r"((int)pred_guard), "r"(data.x), "r"(data.y));
  }
};

template <typename AccessType
         >
struct global_load<AccessType,
                   4
                  > {
  CUTLASS_DEVICE
  global_load(AccessType &D, void const *ptr, bool pred_guard) {
  unsigned &data = reinterpret_cast<unsigned &>(D);

  asm volatile(
      "{\n"
      "  .reg .pred p;\n"
      "  setp.ne.b32 p, %2, 0;\n"
      "  mov.b32 %0, %3;\n"
      "  @p ld.global.u32 %0, [%1];\n"
      "}\n"
      : "=r"(data)
      : "l"(ptr), "r"((int)pred_guard), "r"(data));
  }
};

template <typename AccessType
         >
struct global_load<AccessType,
                   2
                  > {
  CUTLASS_DEVICE
  global_load(AccessType &D, void const *ptr, bool pred_guard) {
  uint16_t &data = reinterpret_cast<uint16_t &>(D);

  asm volatile(
      "{\n"
      "  .reg .pred p;\n"
      "  setp.ne.b32 p, %2, 0;\n"
      "  mov.b16 %0, %3;\n"
      "  @p ld.global.u16 %0, [%1];\n"
      "}\n"
      : "=h"(data)
      : "l"(ptr), "r"((int)pred_guard), "h"(data));
  }
};

template <typename AccessType
          >
struct global_load<AccessType,
                   1
                  > {
  CUTLASS_DEVICE
  global_load(AccessType &D, void const *ptr, bool pred_guard) {
    if (pred_guard) D = *(reinterpret_cast<AccessType const *>(ptr));
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////

template <
    /// Fragment type to store loaded data
    typename AccessType,
    /// The bytes of loading
    int LoadBytes
    >
struct global_store;

/////////////////////////////////////////////////////////////////////////////////////////////////
//
// Specializations
//
/////////////////////////////////////////////////////////////////////////////////////////////////

template <typename AccessType>
struct global_store<AccessType, 32> {
  CUTLASS_DEVICE
  global_store(AccessType const &D, void *ptr, bool pred_guard) {
  uint4 const *data = reinterpret_cast<uint4 const *>(&D);

  asm volatile(
      "{\n"
      "  .reg .pred p;\n"
      "  setp.ne.b32 p, %5, 0;\n"
      "  @p st.global.v4.u32 [%0], {%1, %2, %3, %4};\n"
      "  @p st.global.v4.u32 [%6], {%7, %8, %9, %10};\n"
      "}\n"
      :
      : "l"(ptr), "r"(data[0].x), "r"(data[0].y), "r"(data[0].z),
        "r"(data[0].w), "r"((int)pred_guard), "l"(((uint8_t *)ptr) + 16),
        "r"(data[1].x), "r"(data[1].y), "r"(data[1].z), "r"(data[1].w));
  }
};

template <typename AccessType>
struct global_store<AccessType, 16> {
  CUTLASS_DEVICE
  global_store(AccessType const &D, void *ptr, bool pred_guard) {
  uint4 const &data = reinterpret_cast<uint4 const &>(D);
  asm volatile(
      "{\n"
      "  .reg .pred p;\n"
      "  setp.ne.b32 p, %5, 0;\n"
      "  @p st.global.v4.u32 [%0], {%1, %2, %3, %4};\n"
      "}\n"
      :
      : "l"(ptr), "r"(data.x), "r"(data.y), "r"(data.z), "r"(data.w), "r"((int)pred_guard));
  }
};

template <typename AccessType>
struct global_store<AccessType, 8> {
  CUTLASS_DEVICE
  global_store(AccessType const &D, void *ptr, bool pred_guard) {
  uint2 const &data = reinterpret_cast<uint2 const &>(D);
  asm volatile(
      "{\n"
      "  .reg .pred p;\n"
      "  setp.ne.b32 p, %3, 0;\n"
      "  @p st.global.v2.u32 [%0], {%1, %2};\n"
      "}\n"
      :
      : "l"(ptr), "r"(data.x), "r"(data.y), "r"((int)pred_guard));
  }
};

template <typename AccessType>
struct global_store<AccessType, 4> {
  CUTLASS_DEVICE
  global_store(AccessType const &D, void *ptr, bool pred_guard) {
  uint32_t const &data = reinterpret_cast<uint32_t const &>(D);
  asm volatile(
      "{\n"
      "  .reg .pred p;\n"
      "  setp.ne.b32 p, %2, 0;\n"
      "  @p st.global.u32 [%0], %1;\n"
      "}\n"
      :
      : "l"(ptr), "r"(data), "r"((int)pred_guard));
  }
};

template <typename AccessType>
struct global_store<AccessType, 2> {
  CUTLASS_DEVICE
  global_store(AccessType const &D, void *ptr, bool pred_guard) {
  uint16_t const &data = reinterpret_cast<uint16_t const &>(D);
  asm volatile(
      "{\n"
      "  .reg .pred p;\n"
      "  setp.ne.b32 p, %2, 0;\n"
      "  @p st.global.u16 [%0], %1;\n"
      "}\n"
      :
      : "l"(ptr), "h"(data), "r"((int)pred_guard));
  }
};

template <typename AccessType>
struct global_store<AccessType, 1> {
  CUTLASS_DEVICE
  global_store(AccessType const &D, void *ptr, bool pred_guard) {
    if (pred_guard) *(reinterpret_cast<AccessType *>(ptr)) = D;
  }
};

/////////////////////////////////////////////////////////////////////////////////////////////////


} // namespace arch
} // namespace cutlass

/////////////////////////////////////////////////////////////////////////////////////////////////

#include "memory_sm75.h"  
#include "memory_sm80.h"

/////////////////////////////////////////////////////////////////////////////////////////////////
