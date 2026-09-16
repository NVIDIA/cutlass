// Copyright (c) 2026 NVIDIA CORPORATION & AFFILIATES. All rights reserved.
// SPDX-License-Identifier: BSD-3-Clause
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its
// contributors may be used to endorse or promote products derived from
// this software without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

// RUN: cute-opt %s -split-input-file | FileCheck %s
// Verify the printed output can be parsed.
// RUN: cute-opt %s -split-input-file | cute-opt | FileCheck %s
// Verify the generic form can be parsed.
// RUN: cute-opt -mlir-print-op-generic %s -split-input-file | cute-opt | FileCheck %s

// Tests round-trip for cute.complement.

// -----

// Trivial complement.
// CHECK-LABEL: func.func @trivial
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"3:1">, %[[CO:.+]]: !cute.shape<"3">)
func.func @trivial(
    %input: !cute.layout<"3:1">,
    %cotarget: !cute.shape<"3">) -> !cute.layout<"1:3"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]]) : (!cute.layout<"3:1">, !cute.shape<"3">) -> !cute.layout<"1:3">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"3:1">, !cute.shape<"3">) -> !cute.layout<"1:3">
  return %r : !cute.layout<"1:3">
}

// -----

// Strided input.
// CHECK-LABEL: func.func @strided
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"3:2">, %[[CO:.+]]: !cute.shape<"6">)
func.func @strided(
    %input: !cute.layout<"3:2">,
    %cotarget: !cute.shape<"6">) -> !cute.layout<"2:1"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]]) : (!cute.layout<"3:2">, !cute.shape<"6">) -> !cute.layout<"2:1">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"3:2">, !cute.shape<"6">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// Multi-mode input with tuple cotarget shape.
// CHECK-LABEL: func.func @multi_mode
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(3,(5,2)):(1,(3,15))">, %[[CO:.+]]: !cute.shape<"(6,20)">)
func.func @multi_mode(
    %input: !cute.layout<"(3,(5,2)):(1,(3,15))">,
    %cotarget: !cute.shape<"(6,20)">) -> !cute.layout<"4:30"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]])
  // CHECK-SAME: (!cute.layout<"(3,(5,2)):(1,(3,15))">, !cute.shape<"(6,20)">) -> !cute.layout<"4:30">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"(3,(5,2)):(1,(3,15))">, !cute.shape<"(6,20)">)
        -> !cute.layout<"4:30">
  return %r : !cute.layout<"4:30">
}

// -----

// Multi-mode layout cotarget.
// CHECK-LABEL: func.func @multi_mode_layout_cotarget
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(3,(5,2)):(1,(3,15))">, %[[CO:.+]]: !cute.layout<"(6,20):(1,6)">)
func.func @multi_mode_layout_cotarget(
    %input: !cute.layout<"(3,(5,2)):(1,(3,15))">,
    %cotarget: !cute.layout<"(6,20):(1,6)">) -> !cute.layout<"4:30"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]])
  // CHECK-SAME: (!cute.layout<"(3,(5,2)):(1,(3,15))">, !cute.layout<"(6,20):(1,6)">) -> !cute.layout<"4:30">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"(3,(5,2)):(1,(3,15))">, !cute.layout<"(6,20):(1,6)">)
        -> !cute.layout<"4:30">
  return %r : !cute.layout<"4:30">
}

// -----

// Layout cotarget.
// CHECK-LABEL: func.func @layout_cotarget
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"3:2">, %[[CO:.+]]: !cute.layout<"6:1">)
func.func @layout_cotarget(
    %input: !cute.layout<"3:2">,
    %cotarget: !cute.layout<"6:1">) -> !cute.layout<"2:1"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]]) : (!cute.layout<"3:2">, !cute.layout<"6:1">) -> !cute.layout<"2:1">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"3:2">, !cute.layout<"6:1">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// Input fully covers cotarget.
// CHECK-LABEL: func.func @full_cover
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(2,3):(1,2)">, %[[CO:.+]]: !cute.shape<"6">)
func.func @full_cover(
    %input: !cute.layout<"(2,3):(1,2)">,
    %cotarget: !cute.shape<"6">) -> !cute.layout<"1:6"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]]) : (!cute.layout<"(2,3):(1,2)">, !cute.shape<"6">) -> !cute.layout<"1:6">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"(2,3):(1,2)">, !cute.shape<"6">) -> !cute.layout<"1:6">
  return %r : !cute.layout<"1:6">
}

// -----

// Zero-stride input.
// CHECK-LABEL: func.func @zero_stride
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"3:0">, %[[CO:.+]]: !cute.shape<"6">)
func.func @zero_stride(
    %input: !cute.layout<"3:0">,
    %cotarget: !cute.shape<"6">) -> !cute.layout<"6:1"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]]) : (!cute.layout<"3:0">, !cute.shape<"6">) -> !cute.layout<"6:1">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"3:0">, !cute.shape<"6">) -> !cute.layout<"6:1">
  return %r : !cute.layout<"6:1">
}

// -----

// Tuple cotarget shape.
// CHECK-LABEL: func.func @nested_cotarget
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"3:2">, %[[CO:.+]]: !cute.shape<"(2,3)">)
func.func @nested_cotarget(
    %input: !cute.layout<"3:2">,
    %cotarget: !cute.shape<"(2,3)">) -> !cute.layout<"2:1"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]]) : (!cute.layout<"3:2">, !cute.shape<"(2,3)">) -> !cute.layout<"2:1">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"3:2">, !cute.shape<"(2,3)">)
        -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// Rank-1 dynamic-stride input.
// CHECK-LABEL: func.func @rank1_dyn_stride
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(3):(?)">
// CHECK-SAME:   %[[CO:.+]]: !cute.shape<"12">)
func.func @rank1_dyn_stride(
    %input: !cute.layout<"(3):(?)">,
    %cotarget: !cute.shape<"12">) -> !cute.layout<"(?,?):(1,?)"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]])
  // CHECK-SAME: -> !cute.layout<"(?,?):(1,?)">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"(3):(?)">    , !cute.shape<"12">)
        -> !cute.layout<"(?,?):(1,?)">
  return %r : !cute.layout<"(?,?):(1,?)">
}

// -----

// Fully-dyn rank-1 input.
// CHECK-LABEL: func.func @fully_dyn_input
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"?:?">, %[[CO:.+]]: !cute.shape<"12">)
func.func @fully_dyn_input(
    %input: !cute.layout<"?:?">,
    %cotarget: !cute.shape<"12">) -> !cute.layout<"(?,?):(1,?)"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]])
  // CHECK-SAME: -> !cute.layout<"(?,?):(1,?)">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"?:?">, !cute.shape<"12">)
        -> !cute.layout<"(?,?):(1,?)">
  return %r : !cute.layout<"(?,?):(1,?)">
}

// -----

// Dynamic scalar cotarget shape.
// CHECK-LABEL: func.func @dyn_cotarget_shape
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"3:2">, %[[CO:.+]]: !cute.shape<"?">)
func.func @dyn_cotarget_shape(
    %input: !cute.layout<"3:2">,
    %cotarget: !cute.shape<"?">) -> !cute.layout<"(2,?):(1,6)"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]])
  // CHECK-SAME: -> !cute.layout<"(2,?):(1,6)">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"3:2">, !cute.shape<"?">)
        -> !cute.layout<"(2,?):(1,6)">
  return %r : !cute.layout<"(2,?):(1,6)">
}

// -----

// Dynamic layout cotarget.
// CHECK-LABEL: func.func @dyn_cotarget_layout
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"3:2">, %[[CO:.+]]: !cute.layout<"?:?">)
func.func @dyn_cotarget_layout(
    %input: !cute.layout<"3:2">,
    %cotarget: !cute.layout<"?:?">) -> !cute.layout<"(2,?):(1,6)"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]])
  // CHECK-SAME: -> !cute.layout<"(2,?):(1,6)">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"3:2">, !cute.layout<"?:?">)
        -> !cute.layout<"(2,?):(1,6)">
  return %r : !cute.layout<"(2,?):(1,6)">
}

// -----

// Cotarget larger than input cosize.
// CHECK-LABEL: func.func @cotarget_extends_domain
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"3:2">, %[[CO:.+]]: !cute.shape<"24">)
func.func @cotarget_extends_domain(
    %input: !cute.layout<"3:2">,
    %cotarget: !cute.shape<"24">) -> !cute.layout<"(2,4):(1,6)"> {
  // CHECK: %[[R:.+]] = cute.complement(%[[IN]], %[[CO]])
  // CHECK-SAME: -> !cute.layout<"(2,4):(1,6)">
  %r = cute.complement(%input, %cotarget)
         : (!cute.layout<"3:2">, !cute.shape<"24">)
        -> !cute.layout<"(2,4):(1,6)">
  return %r : !cute.layout<"(2,4):(1,6)">
}

// -----

// Rank-0 empty layout with explicit cotarget shape.
// CHECK-LABEL: func.func @CG_TEST_complement_empty_layout
func.func @CG_TEST_complement_empty_layout(
    %input: !cute.layout<"():()">, %cotarget: !cute.shape<"128">) -> !cute.layout<"128:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"():()">, !cute.shape<"128">) -> !cute.layout<"128:1">
  %r = cute.complement(%input, %cotarget) : (!cute.layout<"():()">, !cute.shape<"128">) -> !cute.layout<"128:1">
  return %r : !cute.layout<"128:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_0__1
func.func @CG_TEST_complement_bwc_1_0__1(
    %a: !cute.layout<"1:0">, %c: !cute.shape<"1">) -> !cute.layout<"1:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.shape<"1">) -> !cute.layout<"1:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:0">, !cute.shape<"1">) -> !cute.layout<"1:1">
  return %r : !cute.layout<"1:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_0__2
func.func @CG_TEST_complement_bwc_1_0__2(
    %a: !cute.layout<"1:0">, %c: !cute.shape<"2">) -> !cute.layout<"2:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.shape<"2">) -> !cute.layout<"2:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:0">, !cute.shape<"2">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_0__5
func.func @CG_TEST_complement_bwc_1_0__5(
    %a: !cute.layout<"1:0">, %c: !cute.shape<"5">) -> !cute.layout<"5:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.shape<"5">) -> !cute.layout<"5:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:0">, !cute.shape<"5">) -> !cute.layout<"5:1">
  return %r : !cute.layout<"5:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_0__2dyn
func.func @CG_TEST_complement_bwc_1_0__2dyn(
    %a: !cute.layout<"1:0">, %c: !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,2)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,2)">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:0">, !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,2)">
  return %r : !cute.layout<"(2,?):(1,2)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_1__1
func.func @CG_TEST_complement_bwc_1_1__1(
    %a: !cute.layout<"1:1">, %c: !cute.shape<"1">) -> !cute.layout<"1:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.shape<"1">) -> !cute.layout<"1:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:1">, !cute.shape<"1">) -> !cute.layout<"1:1">
  return %r : !cute.layout<"1:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_1__2
func.func @CG_TEST_complement_bwc_1_1__2(
    %a: !cute.layout<"1:1">, %c: !cute.shape<"2">) -> !cute.layout<"2:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.shape<"2">) -> !cute.layout<"2:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:1">, !cute.shape<"2">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_1__5
func.func @CG_TEST_complement_bwc_1_1__5(
    %a: !cute.layout<"1:1">, %c: !cute.shape<"5">) -> !cute.layout<"5:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.shape<"5">) -> !cute.layout<"5:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:1">, !cute.shape<"5">) -> !cute.layout<"5:1">
  return %r : !cute.layout<"5:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_1__2dyn
func.func @CG_TEST_complement_bwc_1_1__2dyn(
    %a: !cute.layout<"1:1">, %c: !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,2)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,2)">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:1">, !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,2)">
  return %r : !cute.layout<"(2,?):(1,2)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_2__1
func.func @CG_TEST_complement_bwc_1_2__1(
    %a: !cute.layout<"1:2">, %c: !cute.shape<"1">) -> !cute.layout<"1:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:2">, !cute.shape<"1">) -> !cute.layout<"1:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:2">, !cute.shape<"1">) -> !cute.layout<"1:1">
  return %r : !cute.layout<"1:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_2__2
func.func @CG_TEST_complement_bwc_1_2__2(
    %a: !cute.layout<"1:2">, %c: !cute.shape<"2">) -> !cute.layout<"2:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:2">, !cute.shape<"2">) -> !cute.layout<"2:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:2">, !cute.shape<"2">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_2__8
func.func @CG_TEST_complement_bwc_1_2__8(
    %a: !cute.layout<"1:2">, %c: !cute.shape<"8">) -> !cute.layout<"8:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:2">, !cute.shape<"8">) -> !cute.layout<"8:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:2">, !cute.shape<"8">) -> !cute.layout<"8:1">
  return %r : !cute.layout<"8:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_2__5
func.func @CG_TEST_complement_bwc_1_2__5(
    %a: !cute.layout<"1:2">, %c: !cute.shape<"5">) -> !cute.layout<"5:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:2">, !cute.shape<"5">) -> !cute.layout<"5:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:2">, !cute.shape<"5">) -> !cute.layout<"5:1">
  return %r : !cute.layout<"5:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_1_2__2dyn
func.func @CG_TEST_complement_bwc_1_2__2dyn(
    %a: !cute.layout<"1:2">, %c: !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,2)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"1:2">, !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,2)">
  %r = cute.complement(%a, %c) : (!cute.layout<"1:2">, !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,2)">
  return %r : !cute.layout<"(2,?):(1,2)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_0__1
func.func @CG_TEST_complement_bwc_4_0__1(
    %a: !cute.layout<"4:0">, %c: !cute.shape<"1">) -> !cute.layout<"1:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:0">, !cute.shape<"1">) -> !cute.layout<"1:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:0">, !cute.shape<"1">) -> !cute.layout<"1:1">
  return %r : !cute.layout<"1:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_0__2
func.func @CG_TEST_complement_bwc_4_0__2(
    %a: !cute.layout<"4:0">, %c: !cute.shape<"2">) -> !cute.layout<"2:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:0">, !cute.shape<"2">) -> !cute.layout<"2:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:0">, !cute.shape<"2">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_0__8
func.func @CG_TEST_complement_bwc_4_0__8(
    %a: !cute.layout<"4:0">, %c: !cute.shape<"8">) -> !cute.layout<"8:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:0">, !cute.shape<"8">) -> !cute.layout<"8:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:0">, !cute.shape<"8">) -> !cute.layout<"8:1">
  return %r : !cute.layout<"8:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_1__1
func.func @CG_TEST_complement_bwc_4_1__1(
    %a: !cute.layout<"4:1">, %c: !cute.shape<"1">) -> !cute.layout<"1:4"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:1">, !cute.shape<"1">) -> !cute.layout<"1:4">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:1">, !cute.shape<"1">) -> !cute.layout<"1:4">
  return %r : !cute.layout<"1:4">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_1__2
func.func @CG_TEST_complement_bwc_4_1__2(
    %a: !cute.layout<"4:1">, %c: !cute.shape<"2">) -> !cute.layout<"1:4"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:1">, !cute.shape<"2">) -> !cute.layout<"1:4">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:1">, !cute.shape<"2">) -> !cute.layout<"1:4">
  return %r : !cute.layout<"1:4">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_1__8
func.func @CG_TEST_complement_bwc_4_1__8(
    %a: !cute.layout<"4:1">, %c: !cute.shape<"8">) -> !cute.layout<"2:4"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:1">, !cute.shape<"8">) -> !cute.layout<"2:4">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:1">, !cute.shape<"8">) -> !cute.layout<"2:4">
  return %r : !cute.layout<"2:4">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_2__1
func.func @CG_TEST_complement_bwc_4_2__1(
    %a: !cute.layout<"4:2">, %c: !cute.shape<"1">) -> !cute.layout<"2:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:2">, !cute.shape<"1">) -> !cute.layout<"2:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:2">, !cute.shape<"1">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_2__7
func.func @CG_TEST_complement_bwc_4_2__7(
    %a: !cute.layout<"4:2">, %c: !cute.shape<"7">) -> !cute.layout<"2:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:2">, !cute.shape<"7">) -> !cute.layout<"2:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:2">, !cute.shape<"7">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_2__16
func.func @CG_TEST_complement_bwc_4_2__16(
    %a: !cute.layout<"4:2">, %c: !cute.shape<"16">) -> !cute.layout<"(2,2):(1,8)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:2">, !cute.shape<"16">) -> !cute.layout<"(2,2):(1,8)">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:2">, !cute.shape<"16">) -> !cute.layout<"(2,2):(1,8)">
  return %r : !cute.layout<"(2,2):(1,8)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_2__19
func.func @CG_TEST_complement_bwc_4_2__19(
    %a: !cute.layout<"4:2">, %c: !cute.shape<"19">) -> !cute.layout<"(2,3):(1,8)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:2">, !cute.shape<"19">) -> !cute.layout<"(2,3):(1,8)">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:2">, !cute.shape<"19">) -> !cute.layout<"(2,3):(1,8)">
  return %r : !cute.layout<"(2,3):(1,8)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_2__2dyn
func.func @CG_TEST_complement_bwc_4_2__2dyn(
    %a: !cute.layout<"4:2">, %c: !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,8)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:2">, !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,8)">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:2">, !cute.shape<"(2,?)">) -> !cute.layout<"(2,?):(1,8)">
  return %r : !cute.layout<"(2,?):(1,8)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_4__1
func.func @CG_TEST_complement_bwc_4_4__1(
    %a: !cute.layout<"4:4">, %c: !cute.shape<"1">) -> !cute.layout<"4:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:4">, !cute.shape<"1">) -> !cute.layout<"4:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:4">, !cute.shape<"1">) -> !cute.layout<"4:1">
  return %r : !cute.layout<"4:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_4__13
func.func @CG_TEST_complement_bwc_4_4__13(
    %a: !cute.layout<"4:4">, %c: !cute.shape<"13">) -> !cute.layout<"4:1"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:4">, !cute.shape<"13">) -> !cute.layout<"4:1">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:4">, !cute.shape<"13">) -> !cute.layout<"4:1">
  return %r : !cute.layout<"4:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_4__17
func.func @CG_TEST_complement_bwc_4_4__17(
    %a: !cute.layout<"4:4">, %c: !cute.shape<"17">) -> !cute.layout<"(4,2):(1,16)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:4">, !cute.shape<"17">) -> !cute.layout<"(4,2):(1,16)">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:4">, !cute.shape<"17">) -> !cute.layout<"(4,2):(1,16)">
  return %r : !cute.layout<"(4,2):(1,16)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_4_4__2dyn
func.func @CG_TEST_complement_bwc_4_4__2dyn(
    %a: !cute.layout<"4:4">, %c: !cute.shape<"(2,?)">) -> !cute.layout<"(4,?):(1,16)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"4:4">, !cute.shape<"(2,?)">) -> !cute.layout<"(4,?):(1,16)">
  %r = cute.complement(%a, %c) : (!cute.layout<"4:4">, !cute.shape<"(2,?)">) -> !cute.layout<"(4,?):(1,16)">
  return %r : !cute.layout<"(4,?):(1,16)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_24__8
func.func @CG_TEST_complement_bwc_24__8(
    %a: !cute.layout<"(2,4):(1,2)">, %c: !cute.shape<"8">) -> !cute.layout<"1:8"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,4):(1,2)">, !cute.shape<"8">) -> !cute.layout<"1:8">
  %r = cute.complement(%a, %c) : (!cute.layout<"(2,4):(1,2)">, !cute.shape<"8">) -> !cute.layout<"1:8">
  return %r : !cute.layout<"1:8">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_23__6
func.func @CG_TEST_complement_bwc_23__6(
    %a: !cute.layout<"(2,3):(1,2)">, %c: !cute.shape<"6">) -> !cute.layout<"1:6"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,3):(1,2)">, !cute.shape<"6">) -> !cute.layout<"1:6">
  %r = cute.complement(%a, %c) : (!cute.layout<"(2,3):(1,2)">, !cute.shape<"6">) -> !cute.layout<"1:6">
  return %r : !cute.layout<"1:6">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_24_14__14
func.func @CG_TEST_complement_bwc_24_14__14(
    %a: !cute.layout<"(2,4):(1,4)">, %c: !cute.shape<"14">) -> !cute.layout<"2:2"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,4):(1,4)">, !cute.shape<"14">) -> !cute.layout<"2:2">
  %r = cute.complement(%a, %c) : (!cute.layout<"(2,4):(1,4)">, !cute.shape<"14">) -> !cute.layout<"2:2">
  return %r : !cute.layout<"2:2">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_24_16__20
func.func @CG_TEST_complement_bwc_24_16__20(
    %a: !cute.layout<"(2,4):(1,6)">, %c: !cute.shape<"20">) -> !cute.layout<"3:2"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,4):(1,6)">, !cute.shape<"20">) -> !cute.layout<"3:2">
  %r = cute.complement(%a, %c) : (!cute.layout<"(2,4):(1,6)">, !cute.shape<"20">) -> !cute.layout<"3:2">
  return %r : !cute.layout<"3:2">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_248_8_1_64__460
func.func @CG_TEST_complement_bwc_248_8_1_64__460(
    %a: !cute.layout<"(2,4,8):(8,1,64)">, %c: !cute.shape<"460">) -> !cute.layout<"(2,4):(4,16)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,4,8):(8,1,64)">, !cute.shape<"460">) -> !cute.layout<"(2,4):(4,16)">
  %r = cute.complement(%a, %c) : (!cute.layout<"(2,4,8):(8,1,64)">, !cute.shape<"460">) -> !cute.layout<"(2,4):(4,16)">
  return %r : !cute.layout<"(2,4):(4,16)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_248_8_1_0__12
func.func @CG_TEST_complement_bwc_248_8_1_0__12(
    %a: !cute.layout<"(2,4,8):(8,1,0)">, %c: !cute.shape<"12">) -> !cute.layout<"2:4"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,4,8):(8,1,0)">, !cute.shape<"12">) -> !cute.layout<"2:4">
  %r = cute.complement(%a, %c) : (!cute.layout<"(2,4,8):(8,1,0)">, !cute.shape<"12">) -> !cute.layout<"2:4">
  return %r : !cute.layout<"2:4">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_248_8_1_0__460
func.func @CG_TEST_complement_bwc_248_8_1_0__460(
    %a: !cute.layout<"(2,4,8):(8,1,0)">, %c: !cute.shape<"460">) -> !cute.layout<"(2,29):(4,16)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,4,8):(8,1,0)">, !cute.shape<"460">) -> !cute.layout<"(2,29):(4,16)">
  %r = cute.complement(%a, %c) : (!cute.layout<"(2,4,8):(8,1,0)">, !cute.shape<"460">) -> !cute.layout<"(2,29):(4,16)">
  return %r : !cute.layout<"(2,29):(4,16)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_2222_1_4_8_32__46
func.func @CG_TEST_complement_bwc_2222_1_4_8_32__46(
    %a: !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, %c: !cute.shape<"46">) -> !cute.layout<"(2,2):(2,16)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.shape<"46">) -> !cute.layout<"(2,2):(2,16)">
  %r = cute.complement(%a, %c) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.shape<"46">) -> !cute.layout<"(2,2):(2,16)">
  return %r : !cute.layout<"(2,2):(2,16)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_2222_1_32_8_4__46
func.func @CG_TEST_complement_bwc_2222_1_32_8_4__46(
    %a: !cute.layout<"((2,2),(2,2)):((1,32),(8,4))">, %c: !cute.shape<"46">) -> !cute.layout<"(2,2):(2,16)"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"((2,2),(2,2)):((1,32),(8,4))">, !cute.shape<"46">) -> !cute.layout<"(2,2):(2,16)">
  %r = cute.complement(%a, %c) : (!cute.layout<"((2,2),(2,2)):((1,32),(8,4))">, !cute.shape<"46">) -> !cute.layout<"(2,2):(2,16)">
  return %r : !cute.layout<"(2,2):(2,16)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_46_1_6__34
func.func @CG_TEST_complement_bwc_46_1_6__34(
    %a: !cute.layout<"(4,6):(1,6)">, %c: !cute.shape<"34">) -> !cute.layout<"1:36"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,6):(1,6)">, !cute.shape<"34">) -> !cute.layout<"1:36">
  %r = cute.complement(%a, %c) : (!cute.layout<"(4,6):(1,6)">, !cute.shape<"34">) -> !cute.layout<"1:36">
  return %r : !cute.layout<"1:36">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_42_1_10__14
func.func @CG_TEST_complement_bwc_42_1_10__14(
    %a: !cute.layout<"(4,2):(1,10)">, %c: !cute.shape<"14">) -> !cute.layout<"2:4"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,2):(1,10)">, !cute.shape<"14">) -> !cute.layout<"2:4">
  %r = cute.complement(%a, %c) : (!cute.layout<"(4,2):(1,10)">, !cute.shape<"14">) -> !cute.layout<"2:4">
  return %r : !cute.layout<"2:4">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_bwc_42_1_16__20
func.func @CG_TEST_complement_bwc_42_1_16__20(
    %a: !cute.layout<"(4,2):(1,16)">, %c: !cute.shape<"20">) -> !cute.layout<"4:4"> {
  // CHECK: cute.complement(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,2):(1,16)">, !cute.shape<"20">) -> !cute.layout<"4:4">
  %r = cute.complement(%a, %c) : (!cute.layout<"(4,2):(1,16)">, !cute.shape<"20">) -> !cute.layout<"4:4">
  return %r : !cute.layout<"4:4">
}

// -----

// Flat scaled-basis input.
// CHECK-LABEL: func.func @CG_TEST_complement_sb1
func.func @CG_TEST_complement_sb1(%input: !cute.layout<"3:1@0">)
                                   -> !cute.layout<"(1):(3@0)"> {
  // CHECK: cute.complement(%{{.+}}) : (!cute.layout<"3:1@0">) -> !cute.layout<"(1):(3@0)">
  %r = cute.complement(%input) : (!cute.layout<"3:1@0">) -> !cute.layout<"(1):(3@0)">
  return %r : !cute.layout<"(1):(3@0)">
}

// -----

// Scaled-basis with non-1 coefficient.
// CHECK-LABEL: func.func @CG_TEST_complement_sb2
func.func @CG_TEST_complement_sb2(%input: !cute.layout<"3:4@2">)
                                   -> !cute.layout<"(1,1,(4,1)):(1@0,1@1,(1@2,12@2))"> {
  // CHECK: cute.complement(%{{.+}}) : (!cute.layout<"3:4@2">) -> !cute.layout<"(1,1,(4,1)):(1@0,1@1,(1@2,12@2))">
  %r = cute.complement(%input) : (!cute.layout<"3:4@2">) -> !cute.layout<"(1,1,(4,1)):(1@0,1@1,(1@2,12@2))">
  return %r : !cute.layout<"(1,1,(4,1)):(1@0,1@1,(1@2,12@2))">
}

// -----

// Multi-mode scaled-basis input.
// CHECK-LABEL: func.func @CG_TEST_complement_sb3
func.func @CG_TEST_complement_sb3(%input: !cute.layout<"(2,5,3):(4@1,5@0,16@1)">)
                                   -> !cute.layout<"((5,1),(4,2,1)):((1@0,25@0),(1@1,8@1,48@1))"> {
  // CHECK: cute.complement(%{{.+}}) : (!cute.layout<"(2,5,3):(4@1,5@0,16@1)">) -> !cute.layout<"((5,1),(4,2,1)):((1@0,25@0),(1@1,8@1,48@1))">
  %r = cute.complement(%input) : (!cute.layout<"(2,5,3):(4@1,5@0,16@1)">) -> !cute.layout<"((5,1),(4,2,1)):((1@0,25@0),(1@1,8@1,48@1))">
  return %r : !cute.layout<"((5,1),(4,2,1)):((1@0,25@0),(1@1,8@1,48@1))">
}

// -----

// Mixed plain-integer + scaled-basis.
// CHECK-LABEL: func.func @CG_TEST_complement_sb4
func.func @CG_TEST_complement_sb4(%input: !cute.layout<"(2,1,5,3):(4@1,0,5@0,16@1)">)
                                   -> !cute.layout<"((5,1),(4,2,1)):((1@0,25@0),(1@1,8@1,48@1))"> {
  // CHECK: cute.complement(%{{.+}}) : (!cute.layout<"(2,1,5,3):(4@1,0,5@0,16@1)">) -> !cute.layout<"((5,1),(4,2,1)):((1@0,25@0),(1@1,8@1,48@1))">
  %r = cute.complement(%input) : (!cute.layout<"(2,1,5,3):(4@1,0,5@0,16@1)">) -> !cute.layout<"((5,1),(4,2,1)):((1@0,25@0),(1@1,8@1,48@1))">
  return %r : !cute.layout<"((5,1),(4,2,1)):((1@0,25@0),(1@1,8@1,48@1))">
}

// -----

// Hierarchical scaled-basis.
// CHECK-LABEL: func.func @CG_TEST_complement_sb5
func.func @CG_TEST_complement_sb5(%input: !cute.layout<"(2,3,5):(4@1,5@0,7@1@2)">)
                                   -> !cute.layout<"((5,1),(4,1),(1,(7,1))):((1@0,15@0),(1@1,8@1),(1@0@2,(1@1@2,35@1@2)))"> {
  // CHECK: cute.complement(%{{.+}}) : (!cute.layout<"(2,3,5):(4@1,5@0,7@1@2)">) -> !cute.layout<"((5,1),(4,1),(1,(7,1))):((1@0,15@0),(1@1,8@1),(1@0@2,(1@1@2,35@1@2)))">
  %r = cute.complement(%input) : (!cute.layout<"(2,3,5):(4@1,5@0,7@1@2)">) -> !cute.layout<"((5,1),(4,1),(1,(7,1))):((1@0,15@0),(1@1,8@1),(1@0@2,(1@1@2,35@1@2)))">
  return %r : !cute.layout<"((5,1),(4,1),(1,(7,1))):((1@0,15@0),(1@1,8@1),(1@0@2,(1@1@2,35@1@2)))">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_wc_l621
func.func @CG_TEST_complement_wc_l621(%input: !cute.layout<"(4,2):(1,6)">)
                                       -> !cute.layout<"1:12"> {
  // CHECK: cute.complement(%{{.+}}) : (!cute.layout<"(4,2):(1,6)">) -> !cute.layout<"1:12">
  %r = cute.complement(%input) : (!cute.layout<"(4,2):(1,6)">) -> !cute.layout<"1:12">
  return %r : !cute.layout<"1:12">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_complement_wc_l627
func.func @CG_TEST_complement_wc_l627(%input: !cute.layout<"(4,2):(1,5)">)
                                       -> !cute.layout<"1:10"> {
  // CHECK: cute.complement(%{{.+}}) : (!cute.layout<"(4,2):(1,5)">) -> !cute.layout<"1:10">
  %r = cute.complement(%input) : (!cute.layout<"(4,2):(1,5)">) -> !cute.layout<"1:10">
  return %r : !cute.layout<"1:10">
}

// -----

// Wider stride on mode 1; result keeps
// CHECK-LABEL: func.func @CG_TEST_complement_wc_l633
func.func @CG_TEST_complement_wc_l633(%input: !cute.layout<"(4,2):(1,10)">)
                                       -> !cute.layout<"(2,1):(4,20)"> {
  // CHECK: cute.complement(%{{.+}}) : (!cute.layout<"(4,2):(1,10)">) -> !cute.layout<"(2,1):(4,20)">
  %r = cute.complement(%input) : (!cute.layout<"(4,2):(1,10)">) -> !cute.layout<"(2,1):(4,20)">
  return %r : !cute.layout<"(2,1):(4,20)">
}

// -----

// Sibling of l633 with stride 11.
// CHECK-LABEL: func.func @CG_TEST_complement_wc_l639
func.func @CG_TEST_complement_wc_l639(%input: !cute.layout<"(4,2):(1,11)">)
                                       -> !cute.layout<"(2,1):(4,22)"> {
  // CHECK: cute.complement(%{{.+}}) : (!cute.layout<"(4,2):(1,11)">) -> !cute.layout<"(2,1):(4,22)">
  %r = cute.complement(%input) : (!cute.layout<"(4,2):(1,11)">) -> !cute.layout<"(2,1):(4,22)">
  return %r : !cute.layout<"(2,1):(4,22)">
}
