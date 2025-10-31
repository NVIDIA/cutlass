/***************************************************************************************************
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

#pragma once

#include "cute/tensor.hpp"
#include "cute/util/sycl_vec.hpp"

namespace cute {

// Uniformize a value, in case the compiler cannot prove it is subgroup-uniform.
template <typename T>
CUTE_HOST_DEVICE
T
assert_uniform(T x) {
  auto sg = sycl::ext::oneapi::this_work_item::get_sub_group();
  return group_broadcast(sg, x, 0);
}

// Set a value in a single work-item -- x[i] = val.
// WARNING: i _must_ be a compile-time constant.
//   No diagnostics/error will be issued by the compiler if it is not.
template <typename T>
CUTE_HOST_DEVICE void
set_wi_value(T &x, int i, T val)
{
#if defined(__SYCL_DEVICE_ONLY__) && defined(SYCL_INTEL_TARGET)
  asm (
    "mov (M1_NM, 1) %0(0,%2)<1> %1(0,0)<1;1,0>"
    : "+rw"(x)
    : "rw.u"(val), "P"(i)
  );
#else
  int lane = sycl::ext::oneapi::this_work_item::get_sub_group().get_local_id()[0];
  if (lane == i)
    x = val;
#endif
}

// Set an element of a 1D SG-shared fragment x.
// WARNING: i _must_ be a compile-time constant.
//   No diagnostics/error will be issued by the compiler if it is not.
template <typename FragX>
CUTE_HOST_DEVICE void
set_single_value(FragX& x, int i, typename FragX::element_type val) {
  set_wi_value(x(i / intel::sg_size), i % intel::sg_size, val);
}

// Broadcast the element from a 1D SG-shared fragment x
//   corresponding to the Mode'th dimension of the logical coordinates of src(val).
template <int Mode, typename FragX, typename SGTensorSrc,
          __CUTE_REQUIRES(is_sg_tensor<SGTensorSrc>::value)>
CUTE_HOST_DEVICE
constexpr auto
broadcast(FragX const& x, SGTensorSrc const& src, int val)
{
  auto coord = src.tv_layout()(0, val);
  auto coord_i = get<Mode>(coord);

  constexpr auto TMode = rank(as_arithmetic_tuple(stride<0>(SGTensorSrc{}.tv_layout()))) - 1;
  if constexpr (TMode == Mode) {
    return x(coord_i / intel::sg_size);
  } else {
    auto sg = sycl::ext::oneapi::this_work_item::get_sub_group();
    return group_broadcast(sg, x(coord_i / intel::sg_size), coord_i % intel::sg_size);
  }
}

#if defined(__SYCL_DEVICE_ONLY__) && defined(SYCL_INTEL_TARGET)
#define DEFINE_HREDUCE16_FLOAT(op) \
  CUTE_DEVICE \
  float \
  hreduce16_float_ ## op(float x[16]) \
  { \
    float y; \
    asm ( \
      "{\n" \
      ".decl INTERLEAVE_2 v_type=P num_elts=16\n" \
      ".decl INTERLEAVE_4 v_type=P num_elts=16\n" \
      ".decl INTERLEAVE_8 v_type=P num_elts=16\n" \
      ".decl IN0 v_type=G type=UD num_elts=16 alias=<%1,0>\n" \
      ".decl IN1 v_type=G type=UD num_elts=16 alias=<%2,0>\n" \
      ".decl IN2 v_type=G type=UD num_elts=16 alias=<%3,0>\n" \
      ".decl IN3 v_type=G type=UD num_elts=16 alias=<%4,0>\n" \
      ".decl IN4 v_type=G type=UD num_elts=16 alias=<%5,0>\n" \
      ".decl IN5 v_type=G type=UD num_elts=16 alias=<%6,0>\n" \
      ".decl IN6 v_type=G type=UD num_elts=16 alias=<%7,0>\n" \
      ".decl IN7 v_type=G type=UD num_elts=16 alias=<%8,0>\n" \
      ".decl IN8 v_type=G type=UD num_elts=16 alias=<%9,0>\n" \
      ".decl IN9 v_type=G type=UD num_elts=16 alias=<%10,0>\n" \
      ".decl IN10 v_type=G type=UD num_elts=16 alias=<%11,0>\n" \
      ".decl IN11 v_type=G type=UD num_elts=16 alias=<%12,0>\n" \
      ".decl IN12 v_type=G type=UD num_elts=16 alias=<%13,0>\n" \
      ".decl IN13 v_type=G type=UD num_elts=16 alias=<%14,0>\n" \
      ".decl IN14 v_type=G type=UD num_elts=16 alias=<%15,0>\n" \
      ".decl IN15 v_type=G type=UD num_elts=16 alias=<%16,0>\n" \
      ".decl RA0 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RA2 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RA4 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RA6 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RA8 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RA10 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RA12 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RA14 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RF0 v_type=G type=F num_elts=16 alias=<RA0,0>\n" \
      ".decl RF1 v_type=G type=F num_elts=16 alias=<RA0,64>\n" \
      ".decl RF2 v_type=G type=F num_elts=16 alias=<RA2,0>\n" \
      ".decl RF3 v_type=G type=F num_elts=16 alias=<RA2,64>\n" \
      ".decl RF4 v_type=G type=F num_elts=16 alias=<RA4,0>\n" \
      ".decl RF5 v_type=G type=F num_elts=16 alias=<RA4,64>\n" \
      ".decl RF6 v_type=G type=F num_elts=16 alias=<RA6,0>\n" \
      ".decl RF7 v_type=G type=F num_elts=16 alias=<RA6,64>\n" \
      ".decl RF8 v_type=G type=F num_elts=16 alias=<RA8,0>\n" \
      ".decl RF9 v_type=G type=F num_elts=16 alias=<RA8,64>\n" \
      ".decl RF10 v_type=G type=F num_elts=16 alias=<RA10,0>\n" \
      ".decl RF11 v_type=G type=F num_elts=16 alias=<RA10,64>\n" \
      ".decl RF12 v_type=G type=F num_elts=16 alias=<RA12,0>\n" \
      ".decl RF13 v_type=G type=F num_elts=16 alias=<RA12,64>\n" \
      ".decl RF14 v_type=G type=F num_elts=16 alias=<RA14,0>\n" \
      ".decl RF15 v_type=G type=F num_elts=16 alias=<RA14,64>\n" \
      "setp (M1_NM,16) INTERLEAVE_2 0x5555:uw\n" \
      "setp (M1_NM,16) INTERLEAVE_4 0x3333:uw\n" \
      "setp (M1_NM,16) INTERLEAVE_8 0x0F0F:uw\n" \
      /* Round 1: interleave 2n with 2n+1 */ \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA0(0,0)<1>  IN1(0,0)<2;2,0>  IN0(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA0(1,0)<1>  IN0(0,1)<2;2,0>  IN1(0,0)<1;1,0>\n" \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA2(0,0)<1>  IN3(0,0)<2;2,0>  IN2(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA2(1,0)<1>  IN2(0,1)<2;2,0>  IN3(0,0)<1;1,0>\n" \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA4(0,0)<1>  IN5(0,0)<2;2,0>  IN4(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA4(1,0)<1>  IN4(0,1)<2;2,0>  IN5(0,0)<1;1,0>\n" \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA6(0,0)<1>  IN7(0,0)<2;2,0>  IN6(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA6(1,0)<1>  IN6(0,1)<2;2,0>  IN7(0,0)<1;1,0>\n" \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA8(0,0)<1>  IN9(0,0)<2;2,0>  IN8(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA8(1,0)<1>  IN8(0,1)<2;2,0>  IN9(0,0)<1;1,0>\n" \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA10(0,0)<1> IN11(0,0)<2;2,0> IN10(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA10(1,0)<1> IN10(0,1)<2;2,0> IN11(0,0)<1;1,0>\n" \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA12(0,0)<1> IN13(0,0)<2;2,0> IN12(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA12(1,0)<1> IN12(0,1)<2;2,0> IN13(0,0)<1;1,0>\n" \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA14(0,0)<1> IN15(0,0)<2;2,0> IN14(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA14(1,0)<1> IN14(0,1)<2;2,0> IN15(0,0)<1;1,0>\n" \
      /* Reduce */ \
      #op " (M1_NM,16) RF0(0,0)<1> RF0(0,0)<1;1,0> RF1(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF3(0,0)<1> RF2(0,0)<1;1,0> RF3(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF4(0,0)<1> RF4(0,0)<1;1,0> RF5(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF7(0,0)<1> RF6(0,0)<1;1,0> RF7(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF8(0,0)<1> RF8(0,0)<1;1,0> RF9(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF11(0,0)<1> RF10(0,0)<1;1,0> RF11(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF12(0,0)<1> RF12(0,0)<1;1,0> RF13(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF15(0,0)<1> RF14(0,0)<1;1,0> RF15(0,0)<1;1,0>\n" \
      /* Round 2: interleave 4n+{0,1} with 4n+{2,3} */ \
      "(!INTERLEAVE_4) sel (M1_NM,16) RA0(1,0)<1>  RA2(0,14)<1;1,0>  RA0(0,0)<1;1,0>\n" \
      " (INTERLEAVE_4) sel (M1_NM,16) RA0(0,0)<1>  RA0(0,2)<1;1,0>   RA2(1,0)<1;1,0>\n" \
      "(!INTERLEAVE_4) sel (M1_NM,16) RA4(1,0)<1>  RA6(0,14)<1;1,0>  RA4(0,0)<1;1,0>\n" \
      " (INTERLEAVE_4) sel (M1_NM,16) RA4(0,0)<1>  RA4(0,2)<1;1,0>   RA6(1,0)<1;1,0>\n" \
      "(!INTERLEAVE_4) sel (M1_NM,16) RA8(1,0)<1>  RA10(0,14)<1;1,0> RA8(0,0)<1;1,0>\n" \
      " (INTERLEAVE_4) sel (M1_NM,16) RA8(0,0)<1>  RA8(0,2)<1;1,0>   RA10(1,0)<1;1,0>\n" \
      "(!INTERLEAVE_4) sel (M1_NM,16) RA12(1,0)<1> RA14(0,14)<1;1,0> RA12(0,0)<1;1,0>\n" \
      " (INTERLEAVE_4) sel (M1_NM,16) RA12(0,0)<1> RA12(0,2)<1;1,0>  RA14(1,0)<1;1,0>\n" \
      /* Reduce */ \
      #op " (M1_NM,16) RF0(0,0)<1>  RF0(0,0)<1;1,0>  RF1(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF5(0,0)<1>  RF4(0,0)<1;1,0>  RF5(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF8(0,0)<1>  RF8(0,0)<1;1,0>  RF9(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF13(0,0)<1> RF12(0,0)<1;1,0> RF13(0,0)<1;1,0>\n" \
      /* Round 3: interleave 8n+{0,1,2,3} with 8n+{4,5,6,7} */ \
      "(!INTERLEAVE_8) sel (M1_NM,16) RA0(1,0)<1> RA4(0,12)<1;1,0>  RA0(0,0)<1;1,0>\n" \
      " (INTERLEAVE_8) sel (M1_NM,16) RA0(0,0)<1> RA0(0,4)<1;1,0>   RA4(1,0)<1;1,0>\n" \
      "(!INTERLEAVE_8) sel (M1_NM,16) RA8(1,0)<1> RA12(0,12)<1;1,0> RA8(0,0)<1;1,0>\n" \
      " (INTERLEAVE_8) sel (M1_NM,16) RA8(0,0)<1> RA8(0,4)<1;1,0>   RA12(1,0)<1;1,0>\n" \
      /* Reduce */ \
      #op " (M1_NM,16) RF0(0,0)<1> RF0(0,0)<1;1,0> RF1(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF8(0,0)<1> RF8(0,0)<1;1,0> RF9(0,0)<1;1,0>\n" \
      /* Round 4: final interleave */ \
      "mov (M1_NM, 8) RA0(1,0)<1> RA0(0,8)<1;1,0>\n" \
      "mov (M1_NM, 8) RA8(1,8)<1> RA8(0,0)<1;1,0>\n" \
      /* Reduce */ \
      #op " (M1_NM,8) %0(0,0)<1> RF0(0,0)<1;1,0> RF1(0,0)<1;1,0>\n" \
      #op " (M1_NM,8) %0(0,8)<1> RF8(0,8)<1;1,0> RF9(0,8)<1;1,0>\n" \
      "}\n" \
      : "=rw"(y) \
      : "rw"(x[0]), "rw"(x[1]), "rw"(x[2]),  "rw"(x[3]),  "rw"(x[4]),  "rw"(x[5]),  "rw"(x[6]),  "rw"(x[7]), \
        "rw"(x[8]), "rw"(x[9]), "rw"(x[10]), "rw"(x[11]), "rw"(x[12]), "rw"(x[13]), "rw"(x[14]), "rw"(x[15]) \
    ); \
    return y; \
  }

#define DEFINE_HREDUCE8_FLOAT(op) \
  CUTE_DEVICE \
  float \
  hreduce8_float_ ## op(float x[8]) \
  { \
    float y; \
    asm ( \
      "{\n" \
      ".decl INTERLEAVE_2 v_type=P num_elts=16\n" \
      ".decl INTERLEAVE_4 v_type=P num_elts=16\n" \
      ".decl INTERLEAVE_8 v_type=P num_elts=16\n" \
      ".decl IN0 v_type=G type=UD num_elts=16 alias=<%1,0>\n" \
      ".decl IN1 v_type=G type=UD num_elts=16 alias=<%2,0>\n" \
      ".decl IN2 v_type=G type=UD num_elts=16 alias=<%3,0>\n" \
      ".decl IN3 v_type=G type=UD num_elts=16 alias=<%4,0>\n" \
      ".decl IN4 v_type=G type=UD num_elts=16 alias=<%5,0>\n" \
      ".decl IN5 v_type=G type=UD num_elts=16 alias=<%6,0>\n" \
      ".decl IN6 v_type=G type=UD num_elts=16 alias=<%7,0>\n" \
      ".decl IN7 v_type=G type=UD num_elts=16 alias=<%8,0>\n" \
      ".decl RA0 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RA2 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RA4 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RA6 v_type=G type=UD num_elts=32 align=64\n" \
      ".decl RF0 v_type=G type=F num_elts=16 alias=<RA0,0>\n" \
      ".decl RF1 v_type=G type=F num_elts=16 alias=<RA0,64>\n" \
      ".decl RF2 v_type=G type=F num_elts=16 alias=<RA2,0>\n" \
      ".decl RF3 v_type=G type=F num_elts=16 alias=<RA2,64>\n" \
      ".decl RF4 v_type=G type=F num_elts=16 alias=<RA4,0>\n" \
      ".decl RF5 v_type=G type=F num_elts=16 alias=<RA4,64>\n" \
      ".decl RF6 v_type=G type=F num_elts=16 alias=<RA6,0>\n" \
      ".decl RF7 v_type=G type=F num_elts=16 alias=<RA6,64>\n" \
      "setp (M1_NM,16) INTERLEAVE_2 0x5555:uw\n" \
      "setp (M1_NM,16) INTERLEAVE_4 0x3333:uw\n" \
      "setp (M1_NM,16) INTERLEAVE_8 0x0F0F:uw\n" \
      /* Round 1: interleave 2n with 2n+1 */ \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA0(0,0)<1>  IN1(0,0)<2;2,0>  IN0(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA0(1,0)<1>  IN0(0,1)<2;2,0>  IN1(0,0)<1;1,0>\n" \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA2(0,0)<1>  IN3(0,0)<2;2,0>  IN2(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA2(1,0)<1>  IN2(0,1)<2;2,0>  IN3(0,0)<1;1,0>\n" \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA4(0,0)<1>  IN5(0,0)<2;2,0>  IN4(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA4(1,0)<1>  IN4(0,1)<2;2,0>  IN5(0,0)<1;1,0>\n" \
      "(!INTERLEAVE_2) sel (M1_NM,16) RA6(0,0)<1>  IN7(0,0)<2;2,0>  IN6(0,0)<1;1,0>\n" \
      " (INTERLEAVE_2) sel (M1_NM,16) RA6(1,0)<1>  IN6(0,1)<2;2,0>  IN7(0,0)<1;1,0>\n" \
      /* Reduce */ \
      #op " (M1_NM,16) RF0(0,0)<1> RF0(0,0)<1;1,0> RF1(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF3(0,0)<1> RF2(0,0)<1;1,0> RF3(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF4(0,0)<1> RF4(0,0)<1;1,0> RF5(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF7(0,0)<1> RF6(0,0)<1;1,0> RF7(0,0)<1;1,0>\n" \
      /* Round 2: interleave 4n+{0,1} with 4n+{2,3} */ \
      "(!INTERLEAVE_4) sel (M1_NM,16) RA0(1,0)<1>  RA2(0,14)<1;1,0>  RA0(0,0)<1;1,0>\n" \
      " (INTERLEAVE_4) sel (M1_NM,16) RA0(0,0)<1>  RA0(0,2)<1;1,0>   RA2(1,0)<1;1,0>\n" \
      "(!INTERLEAVE_4) sel (M1_NM,16) RA4(1,0)<1>  RA6(0,14)<1;1,0>  RA4(0,0)<1;1,0>\n" \
      " (INTERLEAVE_4) sel (M1_NM,16) RA4(0,0)<1>  RA4(0,2)<1;1,0>   RA6(1,0)<1;1,0>\n" \
      /* Reduce */ \
      #op " (M1_NM,16) RF0(0,0)<1>  RF0(0,0)<1;1,0>  RF1(0,0)<1;1,0>\n" \
      #op " (M1_NM,16) RF5(0,0)<1>  RF4(0,0)<1;1,0>  RF5(0,0)<1;1,0>\n" \
      /* Round 3: interleave 8n+{0,1,2,3} with 8n+{4,5,6,7} */ \
      "(!INTERLEAVE_8) sel (M1_NM,16) RA0(1,0)<1> RA4(0,12)<1;1,0>  RA0(0,0)<1;1,0>\n" \
      " (INTERLEAVE_8) sel (M1_NM,16) RA0(0,0)<1> RA0(0,4)<1;1,0>   RA4(1,0)<1;1,0>\n" \
      /* Reduce */ \
      #op " (M1_NM,16) RF0(0,0)<1> RF0(0,0)<1;1,0> RF1(0,0)<1;1,0>\n" \
      /* Round 4: reduce top and bottom halves */ \
      #op " (M1_NM,8) %0(0,0)<1> RF0(0,0)<1;1,0> RF0(0,8)<1;1,0>\n" \
      "}\n" \
      : "=rw"(y) \
      : "rw"(x[0]), "rw"(x[1]), "rw"(x[2]),  "rw"(x[3]),  "rw"(x[4]),  "rw"(x[5]),  "rw"(x[6]),  "rw"(x[7]), \
        "rw"(x[8]), "rw"(x[9]), "rw"(x[10]), "rw"(x[11]), "rw"(x[12]), "rw"(x[13]), "rw"(x[14]), "rw"(x[15]) \
    ); \
    return y; \
  }
#else
#define DEFINE_HREDUCE16_FLOAT(op) \
  CUTE_DEVICE float hreduce16_float_ ## op(float x[16]) { return 0.f; }
#define DEFINE_HREDUCE8_FLOAT(op) \
  CUTE_DEVICE float hreduce8_float_ ## op(float x[8]) { return 0.f; }
#endif

DEFINE_HREDUCE8_FLOAT(add)
DEFINE_HREDUCE8_FLOAT(max)
DEFINE_HREDUCE16_FLOAT(add)
DEFINE_HREDUCE16_FLOAT(max)

// Subgroup-cooperative reduction of a SubgroupTensor.
template <int Mode, class BinaryOp,
          class Engine, class FragLayout, class SubgroupTVLayout>
CUTE_HOST_DEVICE
auto
reduce(SubgroupTensor<Engine,FragLayout,SubgroupTVLayout> const& src, BinaryOp op)
{
  auto sg = sycl::ext::oneapi::this_work_item::get_sub_group();
  using T = typename Engine::value_type;
  using TVToV = Layout<Shape<intel::_SGSize,int>, Stride<_0,_1>>;

  /* Retrieve logical coordinate -> (T,V) mapping */
  constexpr auto shape = atuple_coshape(SubgroupTVLayout{});
  constexpr auto coord_to_tv = right_inverse(project_strides(SubgroupTVLayout{})).with_shape(shape);

  /* Move reduction coordinate to mode-0 and group the rest in mode-1. Then, remove work-item modes. */
  constexpr auto rcoord_to_tv = make_layout(select<Mode>(coord_to_tv), remove<Mode>(coord_to_tv));
  constexpr auto rcoord_to_v = filter(composition(TVToV{}, rcoord_to_tv), Step<_1,_1>{});

  /* Regroup input tensor */
  Tensor src_r = make_tensor(src.data(), rcoord_to_v);

  /* Create output tensor */
  auto rshape = replace<Mode>(shape, _1{});
  Tensor out = make_subgroup_tensor(make_tensor<T>(ceil_div(size(rshape), intel::_SGSize{})),
                                    make_identity_layout(rshape));

  /* Check for reduction type */
  constexpr bool horizontal = (size<0>(rcoord_to_tv) == intel::_SGSize{} * size<0>(rcoord_to_v));
  constexpr bool vertical   = (size<1>(rcoord_to_tv) == intel::_SGSize{} * size<1>(rcoord_to_v));

  /* Check for optimized reductions */
  constexpr bool align16 = is_constant_v<0, decltype(size<1>(rcoord_to_v) % _16{})>;
  constexpr bool align8  = is_constant_v<8, decltype(size<1>(rcoord_to_v))>;

  constexpr bool hadd = (horizontal && is_same_v<T, float> && is_same_v<BinaryOp, sycl::plus<void>>);
  constexpr bool hmax = (horizontal && is_same_v<T, float> && is_same_v<BinaryOp, sycl::maximum<void>>);

  constexpr bool hadd16 = hadd && align16;
  constexpr bool hmax16 = hmax && align16;

  constexpr bool hadd8 = hadd && align8;
  constexpr bool hmax8 = hmax && align8;

  [[maybe_unused]] T temp[size<1>(rcoord_to_v)];  /* array of partial reductions */

  CUTE_UNROLL
  for (int j = 0; j < size<1>(rcoord_to_v); j++) {
    T acc = src_r(0, j);
    CUTE_UNROLL
    for (int i = 1; i < size<0>(rcoord_to_v); i++) {
      acc = op(acc, src_r(i, j));
    }

    if constexpr (hadd16 || hmax16 || hadd8 || hmax8)
      temp[j] = acc;
    else if constexpr (horizontal)
      set_single_value(out, j, reduce_over_group(sg, acc, op));
    else if constexpr (vertical)
      out(j) = acc;
    else
      static_assert("Unimplemented reduction type");
  }

  if constexpr (hadd16) {
    CUTE_UNROLL
    for (int j = 0; j < size<1>(rcoord_to_v); j += 16) {
      out(j/16) = hreduce16_float_add(&temp[j]);
    }
  } else if constexpr (hmax16) {
    CUTE_UNROLL
    for (int j = 0; j < size<1>(rcoord_to_v); j += 16) {
      out(j/16) = hreduce16_float_max(&temp[j]);
    }
  } else if constexpr (hadd8) {
    out(0) = hreduce8_float_add(&temp[0]);
  } else if constexpr (hmax8) {
    out(0) = hreduce8_float_max(&temp[0]);
  }

  return out;
}

} // namespace cute
