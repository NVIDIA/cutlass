/*
 * Copyright (c) 2022-2026 T-Head (Shanghai) Semiconductor Co., Ltd.
 * All rights reserved.
 *
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
 */

#pragma once

#include <cute/config.hpp>
#include <cute/arch/mma.hpp>
#include "cutlass/float8.h"

namespace cute {

template<typename ElemA, typename ElemB>
CUTE_HOST_DEVICE
void ppu_fp8_mma_simulator(uint32_t *a, uint32_t *b, float *c, float **d) {
#ifdef __HGGC_ARCH__
  const uint8_t *frag_a = reinterpret_cast<const uint8_t *>(a);
  const uint8_t *frag_b = reinterpret_cast<const uint8_t *>(b);
  const float *frag_c = reinterpret_cast<const float *>(c);
  int lane_idx = threadIdx.x % 32;
  unsigned mask = 0xffffffff;
  // two elem in each 8x8
  CUTE_NO_UNROLL
  for (int loop = 0; loop < 8; loop++) {
    float acc = 0;
    CUTE_NO_UNROLL
    for (int k = 0; k < 32; k++) {
      // threadIdx of elem a, will use two elem each time, right 16 k's thread is identical to left 16 k
      int thread_a = lane_idx - (lane_idx % 4) + ((k % 16) / 4);
      // (loop % 4) / 2 corresponds to top or down part, ((k / 16) * 8) corresponds to left or right part
      // k % 2 corresponds to which elem in each part, inner loop will use two elem in each thread
      int reg_a = ((loop % 4) / 2) * 4 + ((k / 16) * 8) + (k % 4);
      uint8_t cur_a = __shfl_sync(mask, frag_a[reg_a], thread_a);
      ElemA cur_a_half;
      memcpy(&cur_a_half, &cur_a, sizeof(uint8_t));
      // first two part is which col in matrix b, last part is which row
      int thread_b = (lane_idx % 4) * 8 + (loop % 2) * 4 + (k % 16) / 4;
      // first is hori part, second is vert part, third is index in cur part
      int reg_b = ((loop / 4) * 8) + (k / 16) * 4 + k % 4;
      uint8_t cur_b = __shfl_sync(mask, frag_b[reg_b], thread_b);
      ElemB cur_b_half;
      memcpy(&cur_b_half, &cur_b, sizeof(uint8_t));
      acc += float(cur_a_half) * float(cur_b_half);
    }
    *d[loop] = acc + frag_c[loop];
  }
#endif
}

template<typename ElemIn, typename ElemOut>
CUTE_HOST_DEVICE
void ppu_fp16_mma_simulator(uint32_t *a, uint32_t *b, float *c, float **d) {
#ifdef __HGGC_ARCH__
  const uint16_t *frag_a = reinterpret_cast<const uint16_t *>(a);
  const uint16_t *frag_b = reinterpret_cast<const uint16_t *>(b);
  const ElemOut *frag_c = reinterpret_cast<const ElemOut *>(c);
  ElemOut *frag_d = reinterpret_cast<ElemOut *>(*d);
  int lane_idx = threadIdx.x % 32;
  unsigned mask = 0xffffffff;
  // two elem in each 8x8
  CUTE_NO_UNROLL
  for (int loop = 0; loop < 8; loop++) {
    ElemOut acc = 0;
    CUTE_NO_UNROLL
    for (int k = 0; k < 16; k++) {
      // threadIdx of elem a, will use two elem each time, right 8 k's thread is identical to left 8 k
      int thread_a = lane_idx - (lane_idx % 4) + ((k % 8) / 2);
      // (loop % 4) / 2 corresponds to top or down part, ((k / 8) * 4) corresponds to left or right part
      // k % 2 corresponds to which elem in each part, inner loop will use two elem in each thread
      int reg_a = ((loop % 4) / 2) * 2 + ((k / 8) * 4) + (k % 2);
      uint16_t cur_a = __shfl_sync(mask, frag_a[reg_a], thread_a);
      ElemIn cur_a_half;
      memcpy(&cur_a_half, &cur_a, sizeof(uint16_t));

      // first two part is which col in matrix b, last part is which row
      int thread_b = (lane_idx % 4) * 8 + (loop % 2) * 4 + (k % 8) / 2;
      // first is hori part, second is vert part, third is index in cur part
      int reg_b = ((loop / 4) * 4) + (k / 8) * 2 + k % 2;
      uint16_t cur_b = __shfl_sync(mask, frag_b[reg_b], thread_b);
      ElemIn cur_b_half;
      memcpy(&cur_b_half, &cur_b, sizeof(uint16_t));
      acc += ElemOut(cur_a_half * cur_b_half);
      // if (blockIdx.x == 0 && blockIdx.y == 0 && threadIdx.x == 0 && loop == 2) {
      //   printf("k: %d, thra: %d, rega: %d, thrb: %d, regb: %d, acc: %f, a: %f, b: %f\n", k, thread_a, reg_a, thread_b, reg_b, acc, float(cur_a_half), float(cur_b_half));
      // }
    }
    frag_d[loop] = acc + frag_c[loop];
  }

#endif
}

// MMA 16x8x8 TN
struct PPU0015_16x8x8_F32TF32TF32F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n8k8.row.col.f32.tf32.tf32.f32 "
      "{%0,  %1,  %2,  %3},"
      "{%4,  %5,  %6,  %7},"
      "{%8,  %9},"
      "{%10, %11, %12, %13};\n"
      : "=f"(d0), "=f"(d1), "=f"(d2), "=f"(d3)
      :  "r"(a0),  "r"(a1),  "r"(a2),  "r"(a3),
         "r"(b0),  "r"(b1),
         "f"(c0),  "f"(c1),  "f"(c2),  "f"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x8_F32F32F32F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k8.row.col.f32.f32.f32.f32 {%0, %1, %2, %3, %4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15}, {%16, %17, %18, %19, %20, %21, %22, %23};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3), "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3), "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    uint32_t a[4] = {a0, a1, a2, a3};
    uint32_t b[4] = {b0, b1, b2, b3};
    float c[8] = {c0, c1, c2, c3, c4, c5, c6, c7};
    float *d[8] = {&d0, &d1, &d2, &d3, &d4, &d5, &d6, &d7};

    ppu_fp16_mma_simulator<cutlass::half_t, float>(a, b, c, d);
#endif
  }
};

struct PPU0015_16x16x8_F32TF32TF32F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k8.row.col.f32.tf32.tf32.f32 {%0, %1, %2, %3, %4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15}, {%16, %17, %18, %19, %20, %21, %22, %23};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3), "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3), "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    uint32_t a[4] = {a0, a1, a2, a3};
    uint32_t b[4] = {b0, b1, b2, b3};
    float c[8] = {c0, c1, c2, c3, c4, c5, c6, c7};
    float *d[8] = {&d0, &d1, &d2, &d3, &d4, &d5, &d6, &d7};

    ppu_fp16_mma_simulator<cutlass::half_t, float>(a, b, c, d);
#endif
  }
};

struct PPU0015_16x16x16_F32F16F16F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.f32.f16.f16.f32 {%0, %1, %2, %3, %4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15}, {%16, %17, %18, %19, %20, %21, %22, %23};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3), "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3), "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    uint32_t a[4] = {a0, a1, a2, a3};
    uint32_t b[4] = {b0, b1, b2, b3};
    float c[8] = {c0, c1, c2, c3, c4, c5, c6, c7};
    float *d[8] = {&d0, &d1, &d2, &d3, &d4, &d5, &d6, &d7};

    ppu_fp16_mma_simulator<cutlass::half_t, float>(a, b, c, d);
#endif
  }
};

struct PPU0015_16x16x16_F16F16F16F16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.f16.f16.f16.f16 {%0, %1, %2, %3}, {%4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    [[maybe_unused]]  uint32_t a[4] = {a0, a1, a2, a3};
    [[maybe_unused]]  uint32_t b[4] = {b0, b1, b2, b3};
    [[maybe_unused]]  uint32_t c[4] = {c0, c1, c2, c3};
    [[maybe_unused]]  uint32_t *d[4] = {&d0, &d1, &d2, &d3};

    // ppu_fp16_mma_simulator<cutlass::half_t, cutlass::half_t>(a, b, c, d);
    assert(0);
#endif
  }
};


struct PPU0015_16x16x16_F32BF16BF16F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.f32.bf16.bf16.f32 {%0, %1, %2, %3, %4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15}, {%16, %17, %18, %19, %20, %21, %22, %23};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3), "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3), "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    uint32_t a[4] = {a0, a1, a2, a3};
    uint32_t b[4] = {b0, b1, b2, b3};
    float c[8] = {c0, c1, c2, c3, c4, c5, c6, c7};
    float *d[8] = {&d0, &d1, &d2, &d3, &d4, &d5, &d6, &d7};

    ppu_fp16_mma_simulator<cutlass::half_t, float>(a, b, c, d);
#endif
  }
};

struct PPU0015_16x16x32_F32E4M3E4M3F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150

asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.f32.e4m3.e4m3.f32 {%0, %1, %2, %3, %4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15}, {%16, %17, %18, %19, %20, %21, %22, %23};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3), "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3), "r"(c4), "r"(c5), "r"(c6), "r"(c7));

#else
    assert(0);
    uint32_t a[4] = {a0, a1, a2, a3};
    uint32_t b[4] = {b0, b1, b2, b3};
    float c[8] = {c0, c1, c2, c3, c4, c5, c6, c7};
    float *d[8] = {&d0, &d1, &d2, &d3, &d4, &d5, &d6, &d7};
    ppu_fp8_mma_simulator<cutlass::float_e4m3_t, cutlass::float_e4m3_t>(a, b, c, d);
#endif
  }
};

struct PPU0015_16x16x32_F32E4M3E5M2F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150

asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.f32.e4m3.e5m2.f32 {%0, %1, %2, %3, %4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15}, {%16, %17, %18, %19, %20, %21, %22, %23};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3), "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3), "r"(c4), "r"(c5), "r"(c6), "r"(c7));

#else
    assert(0);
    uint32_t a[4] = {a0, a1, a2, a3};
    uint32_t b[4] = {b0, b1, b2, b3};
    float c[8] = {c0, c1, c2, c3, c4, c5, c6, c7};
    float *d[8] = {&d0, &d1, &d2, &d3, &d4, &d5, &d6, &d7};
    ppu_fp8_mma_simulator<cutlass::float_e4m3_t, cutlass::float_e5m2_t>(a, b, c, d);
#endif
  }
};

struct PPU0015_16x16x32_F32E5M2E4M3F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150

asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.f32.e5m2.e4m3.f32 {%0, %1, %2, %3, %4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15}, {%16, %17, %18, %19, %20, %21, %22, %23};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3), "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3), "r"(c4), "r"(c5), "r"(c6), "r"(c7));

#else
    assert(0);
    uint32_t a[4] = {a0, a1, a2, a3};
    uint32_t b[4] = {b0, b1, b2, b3};
    float c[8] = {c0, c1, c2, c3, c4, c5, c6, c7};
    float *d[8] = {&d0, &d1, &d2, &d3, &d4, &d5, &d6, &d7};

    ppu_fp8_mma_simulator<cutlass::float_e5m2_t, cutlass::float_e4m3_t>(a, b, c, d);
#endif
  }
};

struct PPU0015_16x16x32_F32E5M2E5M2F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150

asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.f32.e5m2.e5m2.f32 {%0, %1, %2, %3, %4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15}, {%16, %17, %18, %19, %20, %21, %22, %23};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3), "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3), "r"(c4), "r"(c5), "r"(c6), "r"(c7));

#else
    assert(0);
    uint32_t a[4] = {a0, a1, a2, a3};
    uint32_t b[4] = {b0, b1, b2, b3};
    float c[8] = {c0, c1, c2, c3, c4, c5, c6, c7};
    float *d[8] = {&d0, &d1, &d2, &d3, &d4, &d5, &d6, &d7};

    ppu_fp8_mma_simulator<cutlass::float_e5m2_t, cutlass::float_e5m2_t>(a, b, c, d);
#endif
  }
};

struct PPU0015_16x16x32_F16E4M3E4M3F16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.f16.e4m3.e4m3.f16 {%0, %1, %2, %3}, {%4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x32_F16E5M2E4M3F16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.f16.e5m2.e4m3.f16 {%0, %1, %2, %3}, {%4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x32_F16E4M3E5M2F16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.f16.e4m3.e5m2.f16 {%0, %1, %2, %3}, {%4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x32_F16E5M2E5M2F16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.f16.e5m2.e5m2.f16 {%0, %1, %2, %3}, {%4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15};\n"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x32_S32S8S8S32_TN
{
  using DRegisters = uint32_t[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = uint32_t[8];

  CUTE_HOST_DEVICE static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t      & d4, uint32_t      & d5, uint32_t      & d6, uint32_t      & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3,
      uint32_t const& c4, uint32_t const& c5, uint32_t const& c6, uint32_t const& c7)
  {

#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
asm volatile(
    "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.s32.s8.s8.s32  {%0,%1,%2,%3,%4,%5,%6,%7}, {%8,%9,%10,%11}, {%12,%13,%14,%15}, "
        "{%16,%17,%18,%19,%20,%21,%22,%23};\n"
        : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3), "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
        : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
          "r"(b0), "r"(b1), "r"(b2), "r"(b3),
          "r"(c0), "r"(c1), "r"(c2), "r"(c3), "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
      CUTE_INVALID_CONTROL_PATH("Attempting to use PPU0015_16x16x32_S32S8S8S32_TN without device ARCH");
#endif
  }
};

struct PPU0015_16x16x64_F32F4F4F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = float[8];
  using SRegisters = uint32_t[4];


  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7,
      uint32_t const& s0, uint32_t const& s1, uint32_t const& s2, uint32_t const& s3
  )
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150

    // uint32_t ss0 = 0x7f7f7f7f;
    // uint32_t ss1 = 0x7f7f7f7f;
    // uint32_t ss2 = 0;
    // uint32_t ss3 = 0;

asm (
    "ppu.tc02.mma.mx.sync.aligned.m16n16k64.row.col.f32.f4.f4.f32 {%0, %1, %2, %3, %4, %5, %6, %7}, {%8, %9, %10, %11}, {%12, %13, %14, %15}, {%16, %17, %18, %19, %20, %21, %22, %23}, {%24, %25}, %26, %27, 0;"
      :"=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3), "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      :"r"(a0), "r"(a1), "r"(a2), "r"(a3), "r"(b0), "r"(b1), "r"(b2), "r"(b3),
      "r"(c0), "r"(c1), "r"(c2), "r"(c3), "r"(c4), "r"(c5), "r"(c6), "r"(c7),
      "r"(s0), "r"(s1), "r"(s2), "r"(s3));
      // "r"(ss0), "r"(ss1), "r"(ss2), "r"(ss3));
#else
    assert(0);
#endif
  }
};

// Native TC02 m16n8 operations and matching m16n16 variants.
// Floating-point negation operands are fixed to zero, as in the existing operations.

struct PPU0015_16x8x8_F32F16F16F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k8.row.col.f32.f16.f16.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x8_F16F16F16F16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k8.row.col.f16.f16.f16.f16 "
      "{%0, %1}, "
      "{%2, %3}, "
      "{%4}, "
      "{%5, %6}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x8_F32BF16BF16F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k8.row.col.f32.bf16.bf16.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x8_BF16BF16BF16BF16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k8.row.col.bf16.bf16.bf16.bf16 "
      "{%0, %1}, "
      "{%2, %3}, "
      "{%4}, "
      "{%5, %6}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_F32F16F16F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.f32.f16.f16.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_F16F16F16F16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.f16.f16.f16.f16 "
      "{%0, %1}, "
      "{%2, %3, %4, %5}, "
      "{%6, %7}, "
      "{%8, %9}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_F32BF16BF16F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.f32.bf16.bf16.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_BF16BF16BF16BF16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.bf16.bf16.bf16.bf16 "
      "{%0, %1}, "
      "{%2, %3, %4, %5}, "
      "{%6, %7}, "
      "{%8, %9}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x4_F32F32F32F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k4.row.col.f32.f32.f32.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x4_F32TF32TF32F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k4.row.col.f32.tf32.tf32.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x8_F32F32F32F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k8.row.col.f32.f32.f32.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_F16E4M3E4M3F16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.f16.e4m3.e4m3.f16 "
      "{%0, %1}, "
      "{%2, %3}, "
      "{%4}, "
      "{%5, %6}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_F16E4M3E5M2F16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.f16.e4m3.e5m2.f16 "
      "{%0, %1}, "
      "{%2, %3}, "
      "{%4}, "
      "{%5, %6}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_F16E5M2E4M3F16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.f16.e5m2.e4m3.f16 "
      "{%0, %1}, "
      "{%2, %3}, "
      "{%4}, "
      "{%5, %6}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_F16E5M2E5M2F16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.f16.e5m2.e5m2.f16 "
      "{%0, %1}, "
      "{%2, %3}, "
      "{%4}, "
      "{%5, %6}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_F32E4M3E4M3F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.f32.e4m3.e4m3.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_F32E4M3E5M2F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.f32.e4m3.e5m2.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_F32E5M2E4M3F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.f32.e5m2.e4m3.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_F32E5M2E5M2F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.f32.e5m2.e5m2.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_F16E4M3E4M3F16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.f16.e4m3.e4m3.f16 "
      "{%0, %1}, "
      "{%2, %3, %4, %5}, "
      "{%6, %7}, "
      "{%8, %9}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_F16E4M3E5M2F16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.f16.e4m3.e5m2.f16 "
      "{%0, %1}, "
      "{%2, %3, %4, %5}, "
      "{%6, %7}, "
      "{%8, %9}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_F16E5M2E4M3F16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.f16.e5m2.e4m3.f16 "
      "{%0, %1}, "
      "{%2, %3, %4, %5}, "
      "{%6, %7}, "
      "{%8, %9}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_F16E5M2E5M2F16_TN
{
  using DRegisters = uint32_t[2];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[2];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.f16.e5m2.e5m2.f16 "
      "{%0, %1}, "
      "{%2, %3, %4, %5}, "
      "{%6, %7}, "
      "{%8, %9}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_F32E4M3E4M3F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.f32.e4m3.e4m3.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_F32E4M3E5M2F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.f32.e4m3.e5m2.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_F32E5M2E4M3F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.f32.e5m2.e4m3.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_F32E5M2E5M2F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = float[4];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.f32.e5m2.e5m2.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_S32S8S8S32_TN
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.s32.s8.s8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_S32S8S8S32_TN_SATURATE
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.satfinite.s32.s8.s8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_S32S8U8S32_TN
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.s32.s8.u8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_S32S8U8S32_TN_SATURATE
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.satfinite.s32.s8.u8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_S32U8S8S32_TN
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.s32.u8.s8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_S32U8S8S32_TN_SATURATE
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.satfinite.s32.u8.s8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_S32U8U8S32_TN
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.s32.u8.u8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x16_S32U8U8S32_TN_SATURATE
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[1];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k16.row.col.satfinite.s32.u8.u8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6}, "
      "{%7, %8, %9, %10};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_S32S8S8S32_TN
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.s32.s8.s8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_S32S8S8S32_TN_SATURATE
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.satfinite.s32.s8.s8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_S32S8U8S32_TN
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.s32.s8.u8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_S32S8U8S32_TN_SATURATE
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.satfinite.s32.s8.u8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_S32U8S8S32_TN
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.s32.u8.s8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_S32U8S8S32_TN_SATURATE
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.satfinite.s32.u8.s8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_S32U8U8S32_TN
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.s32.u8.u8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x32_S32U8U8S32_TN_SATURATE
{
  using DRegisters = int32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n8k32.row.col.satfinite.s32.u8.u8.s32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x8x64_F32F4F4F32_TN
{
  using DRegisters = float[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[2];
  using CRegisters = float[4];
  using SRegisters = uint32_t[5];
  // S: E8M0 metadata A/B, A part selector, B part selector, B section selector.
  // Part selectors are 0..3; B section selector is 0..1.

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      uint32_t const& s0, uint32_t const& s1, uint32_t const& s2, uint32_t const& s3,
      uint32_t const& s4)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.mx.sync.aligned.m16n8k64.row.col.f32.f4.f4.f32 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11, %12, %13}, "
      "{%14, %15}, "
      "%16, %17, %18, 0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(s0), "r"(s1), "r"(s2), "r"(s3),
        "r"(s4));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x8_F32F16F16F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k8.row.col.f32.f16.f16.f32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x8_F16F16F16F16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k8.row.col.f16.f16.f16.f16 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6, %7}, "
      "{%8, %9, %10, %11}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x8_F32BF16BF16F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k8.row.col.f32.bf16.bf16.f32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x8_BF16BF16BF16BF16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k8.row.col.bf16.bf16.bf16.bf16 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6, %7}, "
      "{%8, %9, %10, %11}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_BF16BF16BF16BF16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.bf16.bf16.bf16.bf16 "
      "{%0, %1, %2, %3}, "
      "{%4, %5, %6, %7}, "
      "{%8, %9, %10, %11}, "
      "{%12, %13, %14, %15}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1), "r"(b2), "r"(b3),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x4_F32F32F32F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k4.row.col.f32.f32.f32.f32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x4_F32TF32TF32F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k4.row.col.f32.tf32.tf32.f32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_F16E4M3E4M3F16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.f16.e4m3.e4m3.f16 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6, %7}, "
      "{%8, %9, %10, %11}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_F16E4M3E5M2F16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.f16.e4m3.e5m2.f16 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6, %7}, "
      "{%8, %9, %10, %11}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_F16E5M2E4M3F16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.f16.e5m2.e4m3.f16 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6, %7}, "
      "{%8, %9, %10, %11}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_F16E5M2E5M2F16_TN
{
  using DRegisters = uint32_t[4];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = uint32_t[4];

  CUTE_HOST_DEVICE
  static void
  fma(uint32_t      & d0, uint32_t      & d1, uint32_t      & d2, uint32_t      & d3,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      uint32_t const& c0, uint32_t const& c1, uint32_t const& c2, uint32_t const& c3)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.f16.e5m2.e5m2.f16 "
      "{%0, %1, %2, %3}, "
      "{%4, %5}, "
      "{%6, %7}, "
      "{%8, %9, %10, %11}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_F32E4M3E4M3F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.f32.e4m3.e4m3.f32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_F32E4M3E5M2F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.f32.e4m3.e5m2.f32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_F32E5M2E4M3F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.f32.e5m2.e4m3.f32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_F32E5M2E5M2F32_TN
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = float[8];

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.f32.e5m2.e5m2.f32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19}, "
      "0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_S32S8S8S32_TN
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.s32.s8.s8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_S32S8S8S32_TN_SATURATE
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.satfinite.s32.s8.s8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_S32S8U8S32_TN
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.s32.s8.u8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_S32S8U8S32_TN_SATURATE
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.satfinite.s32.s8.u8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_S32U8S8S32_TN
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.s32.u8.s8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_S32U8S8S32_TN_SATURATE
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.satfinite.s32.u8.s8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_S32U8U8S32_TN
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.s32.u8.u8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x16_S32U8U8S32_TN_SATURATE
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[2];
  using BRegisters = uint32_t[2];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1,
      uint32_t const& b0, uint32_t const& b1,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k16.row.col.satfinite.s32.u8.u8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9}, "
      "{%10, %11}, "
      "{%12, %13, %14, %15, "
      "%16, %17, %18, %19};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1),
        "r"(b0), "r"(b1),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x32_S32S8S8S32_TN_SATURATE
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.satfinite.s32.s8.s8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9, %10, %11}, "
      "{%12, %13, %14, %15}, "
      "{%16, %17, %18, %19, "
      "%20, %21, %22, %23};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1), "r"(b2), "r"(b3),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x32_S32S8U8S32_TN
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.s32.s8.u8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9, %10, %11}, "
      "{%12, %13, %14, %15}, "
      "{%16, %17, %18, %19, "
      "%20, %21, %22, %23};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1), "r"(b2), "r"(b3),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x32_S32S8U8S32_TN_SATURATE
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.satfinite.s32.s8.u8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9, %10, %11}, "
      "{%12, %13, %14, %15}, "
      "{%16, %17, %18, %19, "
      "%20, %21, %22, %23};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1), "r"(b2), "r"(b3),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x32_S32U8S8S32_TN
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.s32.u8.s8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9, %10, %11}, "
      "{%12, %13, %14, %15}, "
      "{%16, %17, %18, %19, "
      "%20, %21, %22, %23};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1), "r"(b2), "r"(b3),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x32_S32U8S8S32_TN_SATURATE
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.satfinite.s32.u8.s8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9, %10, %11}, "
      "{%12, %13, %14, %15}, "
      "{%16, %17, %18, %19, "
      "%20, %21, %22, %23};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1), "r"(b2), "r"(b3),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x32_S32U8U8S32_TN
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.s32.u8.u8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9, %10, %11}, "
      "{%12, %13, %14, %15}, "
      "{%16, %17, %18, %19, "
      "%20, %21, %22, %23};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1), "r"(b2), "r"(b3),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x32_S32U8U8S32_TN_SATURATE
{
  using DRegisters = int32_t[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = int32_t[8];

  CUTE_HOST_DEVICE
  static void
  fma(int32_t       & d0, int32_t       & d1, int32_t       & d2, int32_t       & d3,
      int32_t       & d4, int32_t       & d5, int32_t       & d6, int32_t       & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      int32_t const & c0, int32_t const & c1, int32_t const & c2, int32_t const & c3,
      int32_t const & c4, int32_t const & c5, int32_t const & c6, int32_t const & c7)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.sync.aligned.m16n16k32.row.col.satfinite.s32.u8.u8.s32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9, %10, %11}, "
      "{%12, %13, %14, %15}, "
      "{%16, %17, %18, %19, "
      "%20, %21, %22, %23};\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1), "r"(b2), "r"(b3),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7));
#else
    assert(0);
#endif
  }
};

struct PPU0015_16x16x64_F32F4F4F32_TN_NATIVE
{
  using DRegisters = float[8];
  using ARegisters = uint32_t[4];
  using BRegisters = uint32_t[4];
  using CRegisters = float[8];
  using SRegisters = uint32_t[5];
  // S: E8M0 metadata A/B, A part selector, B part selector, B section selector.
  // Part selectors are 0..3; B section selector is 0.

  CUTE_HOST_DEVICE
  static void
  fma(float         & d0, float         & d1, float         & d2, float         & d3,
      float         & d4, float         & d5, float         & d6, float         & d7,
      uint32_t const& a0, uint32_t const& a1, uint32_t const& a2, uint32_t const& a3,
      uint32_t const& b0, uint32_t const& b1, uint32_t const& b2, uint32_t const& b3,
      float const   & c0, float const   & c1, float const   & c2, float const   & c3,
      float const   & c4, float const   & c5, float const   & c6, float const   & c7,
      uint32_t const& s0, uint32_t const& s1, uint32_t const& s2, uint32_t const& s3,
      uint32_t const& s4)
  {
#if defined(__HGGC_ARCH__) && __HGGC_ARCH__ >= 150
    asm volatile(
      "ppu.tc02.mma.mx.sync.aligned.m16n16k64.row.col.f32.f4.f4.f32 "
      "{%0, %1, %2, %3, "
      "%4, %5, %6, %7}, "
      "{%8, %9, %10, %11}, "
      "{%12, %13, %14, %15}, "
      "{%16, %17, %18, %19, "
      "%20, %21, %22, %23}, "
      "{%24, %25}, "
      "%26, %27, %28, 0, 0, 0;\n"
      : "=r"(d0), "=r"(d1), "=r"(d2), "=r"(d3),
        "=r"(d4), "=r"(d5), "=r"(d6), "=r"(d7)
      : "r"(a0), "r"(a1), "r"(a2), "r"(a3),
        "r"(b0), "r"(b1), "r"(b2), "r"(b3),
        "r"(c0), "r"(c1), "r"(c2), "r"(c3),
        "r"(c4), "r"(c5), "r"(c6), "r"(c7),
        "r"(s0), "r"(s1), "r"(s2), "r"(s3),
        "r"(s4));
#else
    assert(0);
#endif
  }
};

} // namespace cute
