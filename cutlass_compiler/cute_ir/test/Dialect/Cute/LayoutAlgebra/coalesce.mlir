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

// Tests round-trip for cute.coalesce.

// -----

// All compatible modes merged.
// CHECK-LABEL: func.func @layout_flat_coalesce
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,5):(1,4)">)
func.func @layout_flat_coalesce(
    %input: !cute.layout<"(4,5):(1,4)">) -> !cute.layout<"20:1"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]]) : (!cute.layout<"(4,5):(1,4)">) -> !cute.layout<"20:1">
  %r = cute.coalesce(%input) : (!cute.layout<"(4,5):(1,4)">) -> !cute.layout<"20:1">
  return %r : !cute.layout<"20:1">
}

// -----

// Adjacent modes cannot be merged, result equals input.
// CHECK-LABEL: func.func @layout_already_coalesced
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(3,4):(8,1)">)
func.func @layout_already_coalesced(
    %input: !cute.layout<"(3,4):(8,1)">) -> !cute.layout<"(3,4):(8,1)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]]) : (!cute.layout<"(3,4):(8,1)">) -> !cute.layout<"(3,4):(8,1)">
  %r = cute.coalesce(%input) : (!cute.layout<"(3,4):(8,1)">) -> !cute.layout<"(3,4):(8,1)">
  return %r : !cute.layout<"(3,4):(8,1)">
}

// -----

// Nested inner mode coalesces.
// CHECK-LABEL: func.func @layout_nested_coalesce
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(3,(4,5)):(8,(1,4))">)
func.func @layout_nested_coalesce(
    %input: !cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,20):(8,1)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]]) : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,20):(8,1)">
  %r = cute.coalesce(%input) : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,20):(8,1)">
  return %r : !cute.layout<"(3,20):(8,1)">
}

// -----

// With target_profile (1,1): each top-level mode is coalesced independently.
// CHECK-LABEL: func.func @layout_with_profile
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(3,(4,5)):(8,(1,4))">, %[[PROF:.+]]: !cute.coord<"(1,1)">)
func.func @layout_with_profile(
    %input: !cute.layout<"(3,(4,5)):(8,(1,4))">,
    %prof: !cute.coord<"(1,1)">) -> !cute.layout<"(3,20):(8,1)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]], %[[PROF]])
  // CHECK-SAME: (!cute.layout<"(3,(4,5)):(8,(1,4))">, !cute.coord<"(1,1)">) -> !cute.layout<"(3,20):(8,1)">
  %r = cute.coalesce(%input, %prof)
         : (!cute.layout<"(3,(4,5)):(8,(1,4))">, !cute.coord<"(1,1)">)
        -> !cute.layout<"(3,20):(8,1)">
  return %r : !cute.layout<"(3,20):(8,1)">
}

// -----

// Scalar target_profile: a rank-1 coord coalesces the whole layout the same
// as the no-profile form.
// CHECK-LABEL: func.func @layout_scalar_profile
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,5):(1,4)">, %[[PROF:.+]]: !cute.coord<"1">)
func.func @layout_scalar_profile(
    %input: !cute.layout<"(4,5):(1,4)">,
    %prof: !cute.coord<"1">) -> !cute.layout<"20:1"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]], %[[PROF]])
  // CHECK-SAME: (!cute.layout<"(4,5):(1,4)">, !cute.coord<"1">) -> !cute.layout<"20:1">
  %r = cute.coalesce(%input, %prof)
         : (!cute.layout<"(4,5):(1,4)">, !cute.coord<"1">)
        -> !cute.layout<"20:1">
  return %r : !cute.layout<"20:1">
}

// -----

// Composed layout: only the B component is coalesced; A and offset are
// preserved unchanged.
// CHECK-LABEL: func.func @composed_layout_no_profile
// CHECK-SAME:  (%[[IN:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">)
func.func @composed_layout_no_profile(
    %input: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]])
  // CHECK-SAME: (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
  %r = cute.coalesce(%input)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
}

// -----

// Dynamic shape in first mode.
// CHECK-LABEL: func.func @layout_dyn_shape_no_merge
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(?,4):(1,4)">)
func.func @layout_dyn_shape_no_merge(
    %input: !cute.layout<"(?,4):(1,4)">) -> !cute.layout<"(?,4):(1,4)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]]) : (!cute.layout<"(?,4):(1,4)">) -> !cute.layout<"(?,4):(1,4)">
  %r = cute.coalesce(%input) : (!cute.layout<"(?,4):(1,4)">) -> !cute.layout<"(?,4):(1,4)">
  return %r : !cute.layout<"(?,4):(1,4)">
}

// -----

// Dynamic stride in first mode.
// CHECK-LABEL: func.func @layout_dyn_stride_no_merge
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,5):(?,4)">)
func.func @layout_dyn_stride_no_merge(
    %input: !cute.layout<"(4,5):(?,4)">) -> !cute.layout<"(4,5):(?,4)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]]) : (!cute.layout<"(4,5):(?,4)">) -> !cute.layout<"(4,5):(?,4)">
  %r = cute.coalesce(%input) : (!cute.layout<"(4,5):(?,4)">) -> !cute.layout<"(4,5):(?,4)">
  return %r : !cute.layout<"(4,5):(?,4)">
}

// -----

// Fully dynamic rank-1 layout.
// CHECK-LABEL: func.func @layout_dyn_scalar_unwrap
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(?):(?)">)
func.func @layout_dyn_scalar_unwrap(
    %input: !cute.layout<"(?):(?)">) -> !cute.layout<"?:?"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]]) : (!cute.layout<"(?):(?)">) -> !cute.layout<"?:?">
  %r = cute.coalesce(%input) : (!cute.layout<"(?):(?)">) -> !cute.layout<"?:?">
  return %r : !cute.layout<"?:?">
}

// -----

// Dynamic layout with target_profile.
// CHECK-LABEL: func.func @layout_dyn_with_profile
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,?):(1,4)">, %[[PROF:.+]]: !cute.coord<"(1,1)">)
func.func @layout_dyn_with_profile(
    %input: !cute.layout<"(4,?):(1,4)">,
    %prof: !cute.coord<"(1,1)">) -> !cute.layout<"(4,?):(1,4)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]], %[[PROF]])
  // CHECK-SAME: (!cute.layout<"(4,?):(1,4)">, !cute.coord<"(1,1)">) -> !cute.layout<"(4,?):(1,4)">
  %r = cute.coalesce(%input, %prof)
         : (!cute.layout<"(4,?):(1,4)">, !cute.coord<"(1,1)">)
        -> !cute.layout<"(4,?):(1,4)">
  return %r : !cute.layout<"(4,?):(1,4)">
}

// -----

// Static prefix coalesces, dynamic tail stays.
// CHECK-LABEL: func.func @layout_static_prefix_dyn_tail
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,5,?):(1,4,?)">)
func.func @layout_static_prefix_dyn_tail(
    %input: !cute.layout<"(4,5,?):(1,4,?)">) -> !cute.layout<"(20,?):(1,?)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]]) : (!cute.layout<"(4,5,?):(1,4,?)">) -> !cute.layout<"(20,?):(1,?)">
  %r = cute.coalesce(%input) : (!cute.layout<"(4,5,?):(1,4,?)">) -> !cute.layout<"(20,?):(1,?)">
  return %r : !cute.layout<"(20,?):(1,?)">
}

// -----

// Static modes coalesce despite dynamic shape on last mode.
// CHECK-LABEL: func.func @layout_static_merge_dyn_shape
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,5,3):(1,4,?)">)
func.func @layout_static_merge_dyn_shape(
    %input: !cute.layout<"(4,5,3):(1,4,?)">) -> !cute.layout<"(20,3):(1,?)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]]) : (!cute.layout<"(4,5,3):(1,4,?)">) -> !cute.layout<"(20,3):(1,?)">
  %r = cute.coalesce(%input) : (!cute.layout<"(4,5,3):(1,4,?)">) -> !cute.layout<"(20,3):(1,?)">
  return %r : !cute.layout<"(20,3):(1,?)">
}

// -----

// Dynamic mode in the middle.
// CHECK-LABEL: func.func @layout_dyn_middle_blocks_merge
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,?,5):(1,?,4)">)
func.func @layout_dyn_middle_blocks_merge(
    %input: !cute.layout<"(4,?,5):(1,?,4)">) -> !cute.layout<"(4,?,5):(1,?,4)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]]) : (!cute.layout<"(4,?,5):(1,?,4)">) -> !cute.layout<"(4,?,5):(1,?,4)">
  %r = cute.coalesce(%input) : (!cute.layout<"(4,?,5):(1,?,4)">) -> !cute.layout<"(4,?,5):(1,?,4)">
  return %r : !cute.layout<"(4,?,5):(1,?,4)">
}

// -----

// Two independent static coalescing groups separated by a dynamic mode.
// CHECK-LABEL: func.func @layout_two_static_groups
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">)
func.func @layout_two_static_groups(
    %input: !cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">) -> !cute.layout<"(20,?,6):(1,?,1)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]]) : (!cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">) -> !cute.layout<"(20,?,6):(1,?,1)">
  %r = cute.coalesce(%input) : (!cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">) -> !cute.layout<"(20,?,6):(1,?,1)">
  return %r : !cute.layout<"(20,?,6):(1,?,1)">
}

// -----

// Dynamic B in composed layout: A and offset are preserved; B modes are kept
// because the merge condition involves a dynamic value.
// CHECK-LABEL: func.func @composed_layout_dyn_b
// CHECK-SAME:  (%[[IN:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,?):(1,4)">)
func.func @composed_layout_dyn_b(
    %input: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,?):(1,4)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (4,?):(1,4)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]])
  // CHECK-SAME: (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,?):(1,4)">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o (4,?):(1,4)">
  %r = cute.coalesce(%input)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,?):(1,4)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (4,?):(1,4)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,?):(1,4)">
}

// -----

// Scaled-basis merge.
// CHECK-LABEL: func.func @CG_TEST_scaled_basis_merge
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"((16,4),128):((1@0,16@0),1@1)">)
func.func @CG_TEST_scaled_basis_merge(
    %input: !cute.layout<"((16,4),128):((1@0,16@0),1@1)">) -> !cute.layout<"(64,128):(1@0,1@1)"> {
  // CHECK: %[[R:.+]] = cute.coalesce(%[[IN]]) : (!cute.layout<"((16,4),128):((1@0,16@0),1@1)">) -> !cute.layout<"(64,128):(1@0,1@1)">
  %r = cute.coalesce(%input)
         : (!cute.layout<"((16,4),128):((1@0,16@0),1@1)">) -> !cute.layout<"(64,128):(1@0,1@1)">
  return %r : !cute.layout<"(64,128):(1@0,1@1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_ba
func.func @CG_TEST_co_ba(%a: !cute.layout<"1:0">) -> !cute.layout<"1:0"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"1:0">) -> !cute.layout<"1:0">
  %r = cute.coalesce(%a) : (!cute.layout<"1:0">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_bb
func.func @CG_TEST_co_bb(%a: !cute.layout<"1:1">) -> !cute.layout<"1:1"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"1:1">) -> !cute.layout<"1:1">
  %r = cute.coalesce(%a) : (!cute.layout<"1:1">) -> !cute.layout<"1:1">
  return %r : !cute.layout<"1:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_bc
func.func @CG_TEST_co_bc(%a: !cute.layout<"(2,4):(1,2)">) -> !cute.layout<"8:1"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,4):(1,2)">) -> !cute.layout<"8:1">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,4):(1,2)">) -> !cute.layout<"8:1">
  return %r : !cute.layout<"8:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_bd
func.func @CG_TEST_co_bd(%a: !cute.layout<"(2,4,6):(1,2,8)">) -> !cute.layout<"48:1"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,4,6):(1,2,8)">) -> !cute.layout<"48:1">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,4,6):(1,2,8)">) -> !cute.layout<"48:1">
  return %r : !cute.layout<"48:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_be
func.func @CG_TEST_co_be(%a: !cute.layout<"(2,1,6):(1,6,2)">) -> !cute.layout<"12:1"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,1,6):(1,6,2)">) -> !cute.layout<"12:1">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,1,6):(1,6,2)">) -> !cute.layout<"12:1">
  return %r : !cute.layout<"12:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_bf
func.func @CG_TEST_co_bf(%a: !cute.layout<"(2,1,6):(1,7,2)">) -> !cute.layout<"12:1"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,1,6):(1,7,2)">) -> !cute.layout<"12:1">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,1,6):(1,7,2)">) -> !cute.layout<"12:1">
  return %r : !cute.layout<"12:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_bg
func.func @CG_TEST_co_bg(%a: !cute.layout<"(2,1,6):(4,7,8)">) -> !cute.layout<"12:4"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,1,6):(4,7,8)">) -> !cute.layout<"12:4">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,1,6):(4,7,8)">) -> !cute.layout<"12:4">
  return %r : !cute.layout<"12:4">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_bh
func.func @CG_TEST_co_bh(%a: !cute.layout<"(2,4):(4,1)">) -> !cute.layout<"(2,4):(4,1)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,4):(4,1)">) -> !cute.layout<"(2,4):(4,1)">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,4):(4,1)">) -> !cute.layout<"(2,4):(4,1)">
  return %r : !cute.layout<"(2,4):(4,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_bi
func.func @CG_TEST_co_bi(%a: !cute.layout<"(2,4,6):(24,6,1)">) -> !cute.layout<"(2,4,6):(24,6,1)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,4,6):(24,6,1)">) -> !cute.layout<"(2,4,6):(24,6,1)">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,4,6):(24,6,1)">) -> !cute.layout<"(2,4,6):(24,6,1)">
  return %r : !cute.layout<"(2,4,6):(24,6,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_bj
func.func @CG_TEST_co_bj(%a: !cute.layout<"(2,1,3):(3,0,1)">) -> !cute.layout<"(2,3):(3,1)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,1,3):(3,0,1)">) -> !cute.layout<"(2,3):(3,1)">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,1,3):(3,0,1)">) -> !cute.layout<"(2,3):(3,1)">
  return %r : !cute.layout<"(2,3):(3,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_bk
func.func @CG_TEST_co_bk(%a: !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">) -> !cute.layout<"(2,4,2):(1,4,32)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">) -> !cute.layout<"(2,4,2):(1,4,32)">
  %r = cute.coalesce(%a) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">) -> !cute.layout<"(2,4,2):(1,4,32)">
  return %r : !cute.layout<"(2,4,2):(1,4,32)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_bl
func.func @CG_TEST_co_bl(%a: !cute.layout<"():()">) -> !cute.layout<"():()"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"():()">) -> !cute.layout<"():()">
  %r = cute.coalesce(%a) : (!cute.layout<"():()">) -> !cute.layout<"():()">
  return %r : !cute.layout<"():()">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_d1
func.func @CG_TEST_co_d1(%a: !cute.layout<"(2,1,6):(4,?,8)">) -> !cute.layout<"12:4"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,1,6):(4,?,8)">) -> !cute.layout<"12:4">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,1,6):(4,?,8)">) -> !cute.layout<"12:4">
  return %r : !cute.layout<"12:4">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_d2
func.func @CG_TEST_co_d2(%a: !cute.layout<"(?,4,6):(1,?,?)">) -> !cute.layout<"(?,4,6):(1,?,?)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(?,4,6):(1,?,?)">) -> !cute.layout<"(?,4,6):(1,?,?)">
  %r = cute.coalesce(%a) : (!cute.layout<"(?,4,6):(1,?,?)">) -> !cute.layout<"(?,4,6):(1,?,?)">
  return %r : !cute.layout<"(?,4,6):(1,?,?)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_d3
func.func @CG_TEST_co_d3(%a: !cute.layout<"(2,?,6):(1,2,?)">) -> !cute.layout<"(2,?,6):(1,2,?)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,?,6):(1,2,?)">) -> !cute.layout<"(2,?,6):(1,2,?)">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,?,6):(1,2,?)">) -> !cute.layout<"(2,?,6):(1,2,?)">
  return %r : !cute.layout<"(2,?,6):(1,2,?)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_d4
func.func @CG_TEST_co_d4(%a: !cute.layout<"(2,4,?):(1,2,8)">) -> !cute.layout<"(8,?):(1,8)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,4,?):(1,2,8)">) -> !cute.layout<"(8,?):(1,8)">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,4,?):(1,2,8)">) -> !cute.layout<"(8,?):(1,8)">
  return %r : !cute.layout<"(8,?):(1,8)">
}

// -----

// dyn first mode, otherwise non-coalescing
// CHECK-LABEL: func.func @CG_TEST_co_d7
func.func @CG_TEST_co_d7(%a: !cute.layout<"(?,4,6):(24,6,1)">) -> !cute.layout<"(?,4,6):(24,6,1)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(?,4,6):(24,6,1)">) -> !cute.layout<"(?,4,6):(24,6,1)">
  %r = cute.coalesce(%a) : (!cute.layout<"(?,4,6):(24,6,1)">) -> !cute.layout<"(?,4,6):(24,6,1)">
  return %r : !cute.layout<"(?,4,6):(24,6,1)">
}

// -----

// dyn middle mode + dyn stride
// CHECK-LABEL: func.func @CG_TEST_co_d8
func.func @CG_TEST_co_d8(%a: !cute.layout<"(2,?,6):(?,6,1)">) -> !cute.layout<"(2,?,6):(?,6,1)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,?,6):(?,6,1)">) -> !cute.layout<"(2,?,6):(?,6,1)">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,?,6):(?,6,1)">) -> !cute.layout<"(2,?,6):(?,6,1)">
  return %r : !cute.layout<"(2,?,6):(?,6,1)">
}

// -----

// dyn middle stride
// CHECK-LABEL: func.func @CG_TEST_co_d9
func.func @CG_TEST_co_d9(%a: !cute.layout<"(2,4,?):(?,?,1)">) -> !cute.layout<"(2,4,?):(?,?,1)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,4,?):(?,?,1)">) -> !cute.layout<"(2,4,?):(?,?,1)">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,4,?):(?,?,1)">) -> !cute.layout<"(2,4,?):(?,?,1)">
  return %r : !cute.layout<"(2,4,?):(?,?,1)">
}

// -----

// dyn middle mode with size-1-like stride
// CHECK-LABEL: func.func @CG_TEST_co_d11
func.func @CG_TEST_co_d11(%a: !cute.layout<"(2,?,3):(?,3,1)">) -> !cute.layout<"(2,?,3):(?,3,1)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,?,3):(?,3,1)">) -> !cute.layout<"(2,?,3):(?,3,1)">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,?,3):(?,3,1)">) -> !cute.layout<"(2,?,3):(?,3,1)">
  return %r : !cute.layout<"(2,?,3):(?,3,1)">
}

// -----

// dyn middle mode with dyn middle stride
// CHECK-LABEL: func.func @CG_TEST_co_d12
func.func @CG_TEST_co_d12(%a: !cute.layout<"(2,?,3):(2,?,4)">) -> !cute.layout<"(2,?,3):(2,?,4)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(2,?,3):(2,?,4)">) -> !cute.layout<"(2,?,3):(2,?,4)">
  %r = cute.coalesce(%a) : (!cute.layout<"(2,?,3):(2,?,4)">) -> !cute.layout<"(2,?,3):(2,?,4)">
  return %r : !cute.layout<"(2,?,3):(2,?,4)">
}

// -----

// fully-dyn rank-2 — no merge
// CHECK-LABEL: func.func @CG_TEST_co_d14
func.func @CG_TEST_co_d14(%a: !cute.layout<"(?,?):(?,?)">) -> !cute.layout<"(?,?):(?,?)"> {
  // CHECK: cute.coalesce(%{{.+}}) : (!cute.layout<"(?,?):(?,?)">) -> !cute.layout<"(?,?):(?,?)">
  %r = cute.coalesce(%a) : (!cute.layout<"(?,?):(?,?)">) -> !cute.layout<"(?,?):(?,?)">
  return %r : !cute.layout<"(?,?):(?,?)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p148
func.func @CG_TEST_co_p148(%a: !cute.layout<"1:0">, %p: !cute.coord<"1">) -> !cute.layout<"1:0"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.coord<"1">) -> !cute.layout<"1:0">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"1:0">, !cute.coord<"1">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p159
func.func @CG_TEST_co_p159(%a: !cute.layout<"1:0">, %p: !cute.coord<"(1)">) -> !cute.layout<"(1):(0)"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.coord<"(1)">) -> !cute.layout<"(1):(0)">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"1:0">, !cute.coord<"(1)">) -> !cute.layout<"(1):(0)">
  return %r : !cute.layout<"(1):(0)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p166
func.func @CG_TEST_co_p166(%a: !cute.layout<"1:1">, %p: !cute.coord<"1">) -> !cute.layout<"1:1"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.coord<"1">) -> !cute.layout<"1:1">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"1:1">, !cute.coord<"1">) -> !cute.layout<"1:1">
  return %r : !cute.layout<"1:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p177
func.func @CG_TEST_co_p177(%a: !cute.layout<"1:1">, %p: !cute.coord<"()">) -> !cute.layout<"(1):(1)"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.coord<"()">) -> !cute.layout<"(1):(1)">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"1:1">, !cute.coord<"()">) -> !cute.layout<"(1):(1)">
  return %r : !cute.layout<"(1):(1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p184
func.func @CG_TEST_co_p184(%a: !cute.layout<"1:1">, %p: !cute.coord<"(1)">) -> !cute.layout<"(1):(1)"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.coord<"(1)">) -> !cute.layout<"(1):(1)">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"1:1">, !cute.coord<"(1)">) -> !cute.layout<"(1):(1)">
  return %r : !cute.layout<"(1):(1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p191
func.func @CG_TEST_co_p191(%a: !cute.layout<"(2,4):(1,2)">, %p: !cute.coord<"1">) -> !cute.layout<"8:1"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,4):(1,2)">, !cute.coord<"1">) -> !cute.layout<"8:1">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"(2,4):(1,2)">, !cute.coord<"1">) -> !cute.layout<"8:1">
  return %r : !cute.layout<"8:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p202
func.func @CG_TEST_co_p202(%a: !cute.layout<"(2,4):(1,2)">, %p: !cute.coord<"(1)">) -> !cute.layout<"(2,4):(1,2)"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,4):(1,2)">, !cute.coord<"(1)">) -> !cute.layout<"(2,4):(1,2)">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"(2,4):(1,2)">, !cute.coord<"(1)">) -> !cute.layout<"(2,4):(1,2)">
  return %r : !cute.layout<"(2,4):(1,2)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p208
func.func @CG_TEST_co_p208(%a: !cute.layout<"(2,1,6):(1,6,2)">, %p: !cute.coord<"(1,2)">) -> !cute.layout<"(2,1,6):(1,6,2)"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,1,6):(1,6,2)">, !cute.coord<"(1,2)">) -> !cute.layout<"(2,1,6):(1,6,2)">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"(2,1,6):(1,6,2)">, !cute.coord<"(1,2)">) -> !cute.layout<"(2,1,6):(1,6,2)">
  return %r : !cute.layout<"(2,1,6):(1,6,2)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p218
func.func @CG_TEST_co_p218(%a: !cute.layout<"(2,4):(4,1)">, %p: !cute.coord<"(1)">) -> !cute.layout<"(2,4):(4,1)"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,4):(4,1)">, !cute.coord<"(1)">) -> !cute.layout<"(2,4):(4,1)">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"(2,4):(4,1)">, !cute.coord<"(1)">) -> !cute.layout<"(2,4):(4,1)">
  return %r : !cute.layout<"(2,4):(4,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p228
func.func @CG_TEST_co_p228(%a: !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, %p: !cute.coord<"1">) -> !cute.layout<"(2,4,2):(1,4,32)"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.coord<"1">) -> !cute.layout<"(2,4,2):(1,4,32)">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.coord<"1">) -> !cute.layout<"(2,4,2):(1,4,32)">
  return %r : !cute.layout<"(2,4,2):(1,4,32)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p241
func.func @CG_TEST_co_p241(%a: !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, %p: !cute.coord<"(1)">) -> !cute.layout<"((2,2),(2,2)):((1,4),(8,32))"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.coord<"(1)">) -> !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.coord<"(1)">) -> !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">
  return %r : !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p249
func.func @CG_TEST_co_p249(%a: !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, %p: !cute.coord<"(1,2)">) -> !cute.layout<"((2,2),(2,2)):((1,4),(8,32))"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.coord<"(1,2)">) -> !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.coord<"(1,2)">) -> !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">
  return %r : !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p256
func.func @CG_TEST_co_p256(%a: !cute.layout<"((2,2),(2,2)):((1,2),(16,32))">, %p: !cute.coord<"1">) -> !cute.layout<"(4,4):(1,16)"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"((2,2),(2,2)):((1,2),(16,32))">, !cute.coord<"1">) -> !cute.layout<"(4,4):(1,16)">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"((2,2),(2,2)):((1,2),(16,32))">, !cute.coord<"1">) -> !cute.layout<"(4,4):(1,16)">
  return %r : !cute.layout<"(4,4):(1,16)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p269
func.func @CG_TEST_co_p269(%a: !cute.layout<"((2,2),(2,2)):((1,2),(16,32))">, %p: !cute.coord<"(1)">) -> !cute.layout<"(4,(2,2)):(1,(16,32))"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"((2,2),(2,2)):((1,2),(16,32))">, !cute.coord<"(1)">) -> !cute.layout<"(4,(2,2)):(1,(16,32))">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"((2,2),(2,2)):((1,2),(16,32))">, !cute.coord<"(1)">) -> !cute.layout<"(4,(2,2)):(1,(16,32))">
  return %r : !cute.layout<"(4,(2,2)):(1,(16,32))">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_co_p277
func.func @CG_TEST_co_p277(%a: !cute.layout<"((2,2),(2,2)):((1,2),(16,32))">, %p: !cute.coord<"(1,2)">) -> !cute.layout<"(4,4):(1,16)"> {
  // CHECK: cute.coalesce(%{{.+}}, %{{.+}}) : (!cute.layout<"((2,2),(2,2)):((1,2),(16,32))">, !cute.coord<"(1,2)">) -> !cute.layout<"(4,4):(1,16)">
  %r = cute.coalesce(%a, %p) : (!cute.layout<"((2,2),(2,2)):((1,2),(16,32))">, !cute.coord<"(1,2)">) -> !cute.layout<"(4,4):(1,16)">
  return %r : !cute.layout<"(4,4):(1,16)">
}
