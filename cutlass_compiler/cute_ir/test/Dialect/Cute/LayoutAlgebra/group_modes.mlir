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

// Tests round-trip for cute.group_modes.

// -----

// Group prefix [0,2): modes 0 and 1 collapse into a nested pair.
// Rank 3 → rank 2 with nested first mode.
// CHECK-LABEL: func.func @group_prefix
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,5,6):(1,4,20)">)
func.func @group_prefix(
    %input: !cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4,5),6):((1,4),20)"> {
  // CHECK: %[[R:.+]] = cute.group_modes<0, 2> (%[[IN]])
  // CHECK-SAME: (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4,5),6):((1,4),20)">
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4,5),6):((1,4),20)">
  return %r : !cute.layout<"((4,5),6):((1,4),20)">
}

// -----

// Group suffix [1,3): modes 1 and 2 collapse into a nested pair.
// Rank 3 → rank 2 with nested last mode.
// CHECK-LABEL: func.func @group_suffix
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,5,6):(1,4,20)">)
func.func @group_suffix(
    %input: !cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"(4,(5,6)):(1,(4,20))"> {
  // CHECK: %[[R:.+]] = cute.group_modes<1, 3> (%[[IN]])
  // CHECK-SAME: (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"(4,(5,6)):(1,(4,20))">
  %r = cute.group_modes<1, 3>(%input)
         : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"(4,(5,6)):(1,(4,20))">
  return %r : !cute.layout<"(4,(5,6)):(1,(4,20))">
}

// -----

// Group middle [1,3) of a rank-4 layout: modes 1 and 2 nest; modes 0 and 3 stay.
// CHECK-LABEL: func.func @group_middle
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(3,4,5,6):(1,3,12,60)">)
func.func @group_middle(
    %input: !cute.layout<"(3,4,5,6):(1,3,12,60)">) -> !cute.layout<"(3,(4,5),6):(1,(3,12),60)"> {
  // CHECK: %[[R:.+]] = cute.group_modes<1, 3> (%[[IN]])
  // CHECK-SAME: (!cute.layout<"(3,4,5,6):(1,3,12,60)">) -> !cute.layout<"(3,(4,5),6):(1,(3,12),60)">
  %r = cute.group_modes<1, 3>(%input)
         : (!cute.layout<"(3,4,5,6):(1,3,12,60)">) -> !cute.layout<"(3,(4,5),6):(1,(3,12),60)">
  return %r : !cute.layout<"(3,(4,5),6):(1,(3,12),60)">
}

// -----

// Group all [0,3): all modes fold into a single nested mode.
// Rank 3 → rank 1.
// CHECK-LABEL: func.func @group_all
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,5,6):(1,4,20)">)
func.func @group_all(
    %input: !cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4,5,6)):((1,4,20))"> {
  // CHECK: %[[R:.+]] = cute.group_modes<0, 3> (%[[IN]])
  // CHECK-SAME: (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4,5,6)):((1,4,20))">
  %r = cute.group_modes<0, 3>(%input)
         : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4,5,6)):((1,4,20))">
  return %r : !cute.layout<"((4,5,6)):((1,4,20))">
}

// -----

// Single-mode range [0,1): mode 0 is wrapped in a nested tuple.
// CHECK-LABEL: func.func @group_single_mode
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,5,6):(1,4,20)">)
func.func @group_single_mode(
    %input: !cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4),5,6):((1),4,20)"> {
  // CHECK: %[[R:.+]] = cute.group_modes<0, 1> (%[[IN]])
  // CHECK-SAME: (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4),5,6):((1),4,20)">
  %r = cute.group_modes<0, 1>(%input)
         : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4),5,6):((1),4,20)">
  return %r : !cute.layout<"((4),5,6):((1),4,20)">
}

// -----

// Composed layout: group applies to layout_b; A and offset are preserved.
// CHECK-LABEL: func.func @composed_layout
// CHECK-SAME:  (%[[IN:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">)
func.func @composed_layout(
    %input: !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((3,4),5):((1,3),12)"> {
  // CHECK: %[[R:.+]] = cute.group_modes<0, 2> (%[[IN]])
  // CHECK-SAME: (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((3,4),5):((1,3),12)">
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((3,4),5):((1,3),12)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o ((3,4),5):((1,3),12)">
}

// -----

// Dynamic shapes and strides: grouping restructures the mode tree regardless
// of whether values are statically known.
// CHECK-LABEL: func.func @dynamic_modes
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(?,5,6):(1,?,20)">)
func.func @dynamic_modes(
    %input: !cute.layout<"(?,5,6):(1,?,20)">) -> !cute.layout<"((?,5),6):((1,?),20)"> {
  // CHECK: %[[R:.+]] = cute.group_modes<0, 2> (%[[IN]])
  // CHECK-SAME: (!cute.layout<"(?,5,6):(1,?,20)">) -> !cute.layout<"((?,5),6):((1,?),20)">
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.layout<"(?,5,6):(1,?,20)">) -> !cute.layout<"((?,5),6):((1,?),20)">
  return %r : !cute.layout<"((?,5),6):((1,?),20)">
}

// -----

// Rank-2 layout grouped fully: rank 2 → rank 1 with a single nested mode.
// CHECK-LABEL: func.func @rank2_group_all
// CHECK-SAME:  (%[[IN:.+]]: !cute.layout<"(4,5):(1,4)">)
func.func @rank2_group_all(
    %input: !cute.layout<"(4,5):(1,4)">) -> !cute.layout<"((4,5)):((1,4))"> {
  // CHECK: %[[R:.+]] = cute.group_modes<0, 2> (%[[IN]])
  // CHECK-SAME: (!cute.layout<"(4,5):(1,4)">) -> !cute.layout<"((4,5)):((1,4))">
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.layout<"(4,5):(1,4)">) -> !cute.layout<"((4,5)):((1,4))">
  return %r : !cute.layout<"((4,5)):((1,4))">
}

// -----

// Composed layout with swizzle-A: A (swizzle), offset (0), B layout are all
// preserved; group applies to B.
// CHECK-LABEL: func.func @composed_swizzle
// CHECK-SAME:  (%[[IN:.+]]: !cute.composed_layout<"S<3,4,3> o 0 o (4,5,6):(1,4,20)">)
func.func @composed_swizzle(
    %input: !cute.composed_layout<"S<3,4,3> o 0 o (4,5,6):(1,4,20)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((4,5),6):((1,4),20)"> {
  // CHECK: %[[R:.+]] = cute.group_modes<0, 2> (%[[IN]])
  // CHECK-SAME: (!cute.composed_layout<"S<3,4,3> o 0 o (4,5,6):(1,4,20)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((4,5),6):((1,4),20)">
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (4,5,6):(1,4,20)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((4,5),6):((1,4),20)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((4,5),6):((1,4),20)">
}

// -----

// Composed layout with suffix range [1, 3) on B: A and offset preserved.
// CHECK-LABEL: func.func @composed_suffix
// CHECK-SAME:  (%[[IN:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">)
func.func @composed_suffix(
    %input: !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(1,(3,12))"> {
  // CHECK: %[[R:.+]] = cute.group_modes<1, 3> (%[[IN]])
  // CHECK-SAME: (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(1,(3,12))">
  %r = cute.group_modes<1, 3>(%input)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(1,3,12)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(1,(3,12))">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(1,(3,12))">
}

// -----

// Composed layout with swizzle-A + dynamic B: A and offset preserved,
// grouping applies through the dyn B.
// CHECK-LABEL: func.func @composed_dyn_b
// CHECK-SAME:  (%[[IN:.+]]: !cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,20)">)
func.func @composed_dyn_b(
    %input: !cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,20)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),20)"> {
  // CHECK: %[[R:.+]] = cute.group_modes<0, 2> (%[[IN]])
  // CHECK-SAME: (!cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,20)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),20)">
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,20)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),20)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),20)">
}
