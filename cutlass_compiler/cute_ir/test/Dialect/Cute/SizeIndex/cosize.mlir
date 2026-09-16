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
// RUN: cute-opt %s -split-input-file | cute-opt | FileCheck %s
// RUN: cute-opt -mlir-print-op-generic %s -split-input-file | cute-opt | FileCheck %s

// Tests round-trip for cute.cosize.

// -----

// Static layout, no mode.
// CHECK-LABEL: func.func @cosize_static
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,3,2):(1,4,12)">)
func.func @cosize_static(%src: !cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24"> {
  // CHECK: %[[R:.+]] = cute.cosize (%[[SRC]]) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24">
  %r = cute.cosize(%src) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24">
  return %r : !cute.int_tuple<"24">
}

// -----

// Layout with mode [1].
// CHECK-LABEL: func.func @cosize_with_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,3,2):(1,4,12)">)
func.func @cosize_with_mode(%src: !cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9"> {
  // CHECK: %[[R:.+]] = cute.cosize<[1]> (%[[SRC]]) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9">
  %r = cute.cosize <[1]>(%src) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}

// -----

// Dynamic layout: cosize is dynamic.
// CHECK-LABEL: func.func @cosize_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(?,?,?):(?,?,?)">)
func.func @cosize_dynamic(%src: !cute.layout<"(?,?,?):(?,?,?)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.cosize (%[[SRC]]) : (!cute.layout<"(?,?,?):(?,?,?)">) -> !cute.int_tuple<"?">
  %r = cute.cosize(%src) : (!cute.layout<"(?,?,?):(?,?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// ComposedLayout: cosize uses the outer layout's codomain.
// CHECK-LABEL: func.func @cosize_composed
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,4,6> o 0 o (3,4):(4,1)">)
func.func @cosize_composed(
    %src: !cute.composed_layout<"S<3,4,6> o 0 o (3,4):(4,1)">) -> !cute.int_tuple<"12"> {
  // CHECK: %[[R:.+]] = cute.cosize (%[[SRC]]) : (!cute.composed_layout<"S<3,4,6> o 0 o (3,4):(4,1)">) -> !cute.int_tuple<"12">
  %r = cute.cosize(%src) : (!cute.composed_layout<"S<3,4,6> o 0 o (3,4):(4,1)">) -> !cute.int_tuple<"12">
  return %r : !cute.int_tuple<"12">
}

// -----

// Basis stride layout.
// CHECK-LABEL: func.func @cosize_basis_stride
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3):(1@0,1@1)">)
func.func @cosize_basis_stride(%src: !cute.layout<"(2,3):(1@0,1@1)">) -> !cute.int_tuple<"6"> {
  // CHECK: %[[R:.+]] = cute.cosize (%[[SRC]]) : (!cute.layout<"(2,3):(1@0,1@1)">) -> !cute.int_tuple<"6">
  %r = cute.cosize(%src) : (!cute.layout<"(2,3):(1@0,1@1)">) -> !cute.int_tuple<"6">
  return %r : !cute.int_tuple<"6">
}

// -----

// Deeply-nested static layout, no mode.
// CHECK-LABEL: func.func @cosize_static_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
func.func @cosize_static_nested(
    %src: !cute.layout<"((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
    -> !cute.int_tuple<"288"> {
  // CHECK: %[[R:.+]] = cute.cosize (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"288">
  %r = cute.cosize(%src)
      : (!cute.layout<"((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
     -> !cute.int_tuple<"288">
  return %r : !cute.int_tuple<"288">
}

// -----

// Scalar static layout, mode [0].
// CHECK-LABEL: func.func @cosize_static_scalar
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"4:1">)
func.func @cosize_static_scalar(%src: !cute.layout<"4:1">) -> !cute.int_tuple<"4"> {
  // CHECK: %[[R:.+]] = cute.cosize<[0]> (%[[SRC]]) : (!cute.layout<"4:1">) -> !cute.int_tuple<"4">
  %r = cute.cosize<[0]>(%src) : (!cute.layout<"4:1">) -> !cute.int_tuple<"4">
  return %r : !cute.int_tuple<"4">
}

// -----

// Mode [1] on sub-layout 3:4 (the scalar sub-layout).
// CHECK-LABEL: func.func @cosize_with_nested_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,3,2):(1,4,12)">)
func.func @cosize_with_nested_mode(%src: !cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9"> {
  // CHECK: %[[R:.+]] = cute.cosize<[1]> (%[[SRC]]) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9">
  %r = cute.cosize<[1]>(%src) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}

// -----

// Deep mode [1, 0, 1] on a deeply-nested static layout.
// CHECK-LABEL: func.func @cosize_static_deep_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
func.func @cosize_static_deep_mode(
    %src: !cute.layout<"((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
    -> !cute.int_tuple<"109"> {
  // CHECK: %[[R:.+]] = cute.cosize<[1, 0, 1]> (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"109">
  %r = cute.cosize<[1, 0, 1]>(%src)
      : (!cute.layout<"((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
     -> !cute.int_tuple<"109">
  return %r : !cute.int_tuple<"109">
}

// -----

// Mode [1, 1, 1] on a deeply-nested static layout descending to a leaf.
// CHECK-LABEL: func.func @cosize_static_leaf_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(1,(2,(3,(4,2,1)))):(4,(3,(2,(1,4,8))))">)
func.func @cosize_static_leaf_mode(
    %src: !cute.layout<"(1,(2,(3,(4,2,1)))):(4,(3,(2,(1,4,8))))">)
    -> !cute.int_tuple<"8"> {
  // CHECK: %[[R:.+]] = cute.cosize<[1, 1, 1]> (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"8">
  %r = cute.cosize<[1, 1, 1]>(%src)
      : (!cute.layout<"(1,(2,(3,(4,2,1)))):(4,(3,(2,(1,4,8))))">)
     -> !cute.int_tuple<"8">
  return %r : !cute.int_tuple<"8">
}

// -----

// Mode [1, 1, 0] picking a partial sub-tuple of a nested layout.
// CHECK-LABEL: func.func @cosize_static_partial_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(1,(2,(3,4))):(4,(3,(2,1)))">)
func.func @cosize_static_partial_mode(
    %src: !cute.layout<"(1,(2,(3,4))):(4,(3,(2,1)))">)
    -> !cute.int_tuple<"5"> {
  // CHECK: %[[R:.+]] = cute.cosize<[1, 1, 0]> (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"5">
  %r = cute.cosize<[1, 1, 0]>(%src)
      : (!cute.layout<"(1,(2,(3,4))):(4,(3,(2,1)))">)
     -> !cute.int_tuple<"5">
  return %r : !cute.int_tuple<"5">
}

// -----

// Mode [0] picking the trivial sub-layout 1:4.
// CHECK-LABEL: func.func @cosize_static_outer_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(1,(2,(3,4))):(4,(3,(2,1)))">)
func.func @cosize_static_outer_mode(
    %src: !cute.layout<"(1,(2,(3,4))):(4,(3,(2,1)))">)
    -> !cute.int_tuple<"1"> {
  // CHECK: %[[R:.+]] = cute.cosize<[0]> (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"1">
  %r = cute.cosize<[0]>(%src)
      : (!cute.layout<"(1,(2,(3,4))):(4,(3,(2,1)))">)
     -> !cute.int_tuple<"1">
  return %r : !cute.int_tuple<"1">
}

// -----

// Dynamic scalar layout.
// CHECK-LABEL: func.func @cosize_dynamic_scalar
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"?:?">)
func.func @cosize_dynamic_scalar(%src: !cute.layout<"?:?">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.cosize (%[[SRC]]) : (!cute.layout<"?:?">) -> !cute.int_tuple<"?">
  %r = cute.cosize(%src) : (!cute.layout<"?:?">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Hierarchical dynamic layout, no mode.
// CHECK-LABEL: func.func @cosize_dynamic_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((?,?),((?,?),?)):((?,?),((?,?),?))">)
func.func @cosize_dynamic_nested(
    %src: !cute.layout<"((?,?),((?,?),?)):((?,?),((?,?),?))">)
    -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.cosize (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"?">
  %r = cute.cosize(%src)
      : (!cute.layout<"((?,?),((?,?),?)):((?,?),((?,?),?))">)
     -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Hierarchical dynamic layout with deep mode [0, 1].
// CHECK-LABEL: func.func @cosize_dynamic_nested_with_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((?,?),((?,?),?)):((?,?),((?,?),?))">)
func.func @cosize_dynamic_nested_with_mode(
    %src: !cute.layout<"((?,?),((?,?),?)):((?,?),((?,?),?))">)
    -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.cosize<[0, 1]> (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"?">
  %r = cute.cosize<[0, 1]>(%src)
      : (!cute.layout<"((?,?),((?,?),?)):((?,?),((?,?),?))">)
     -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Mixed static / dynamic layout with mode [1].
// CHECK-LABEL: func.func @cosize_dynamic_with_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(10,?,?):(?,?,?)">)
func.func @cosize_dynamic_with_mode(
    %src: !cute.layout<"(10,?,?):(?,?,?)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.cosize<[1]> (%[[SRC]]) : (!cute.layout<"(10,?,?):(?,?,?)">) -> !cute.int_tuple<"?">
  %r = cute.cosize<[1]>(%src) : (!cute.layout<"(10,?,?):(?,?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Mixed static-shape / dynamic-stride layout with deep mode [1, 0, 1].
// CHECK-LABEL: func.func @cosize_dynamic_mixed_deep_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((2,2),((3,3),?)):((?,?),((?,?),?))">)
func.func @cosize_dynamic_mixed_deep_mode(
    %src: !cute.layout<"((2,2),((3,3),?)):((?,?),((?,?),?))">)
    -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.cosize<[1, 0, 1]> (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"?">
  %r = cute.cosize<[1, 0, 1]>(%src)
      : (!cute.layout<"((2,2),((3,3),?)):((?,?),((?,?),?))">)
     -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Swizzle-composed layout with hierarchical static outer.
// CHECK-LABEL: func.func @cosize_swizzle_composed_static_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,4,6> o 0 o ((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
func.func @cosize_swizzle_composed_static_nested(
    %src: !cute.composed_layout<"S<3,4,6> o 0 o ((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
    -> !cute.int_tuple<"288"> {
  // CHECK: %[[R:.+]] = cute.cosize (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"288">
  %r = cute.cosize(%src)
      : (!cute.composed_layout<"S<3,4,6> o 0 o ((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
     -> !cute.int_tuple<"288">
  return %r : !cute.int_tuple<"288">
}

// -----

// Swizzle-composed layout with deep mode [1, 0, 1] on the outer.
// CHECK-LABEL: func.func @cosize_swizzle_composed_static_deep_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,4,6> o 0 o ((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
func.func @cosize_swizzle_composed_static_deep_mode(
    %src: !cute.composed_layout<"S<3,4,6> o 0 o ((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
    -> !cute.int_tuple<"109"> {
  // CHECK: %[[R:.+]] = cute.cosize<[1, 0, 1]> (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"109">
  %r = cute.cosize<[1, 0, 1]>(%src)
      : (!cute.composed_layout<"S<3,4,6> o 0 o ((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
     -> !cute.int_tuple<"109">
  return %r : !cute.int_tuple<"109">
}

// -----

// Swizzle-composed dynamic: outer is mixed static / dynamic, offset is dynamic.
// CHECK-LABEL: func.func @cosize_swizzle_composed_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,4,6> o ? o ((7,?),((8,?),?)):((4,?),((28,?),?))">)
func.func @cosize_swizzle_composed_dynamic(
    %src: !cute.composed_layout<"S<3,4,6> o ? o ((7,?),((8,?),?)):((4,?),((28,?),?))">)
    -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.cosize (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"?">
  %r = cute.cosize(%src)
      : (!cute.composed_layout<"S<3,4,6> o ? o ((7,?),((8,?),?)):((4,?),((28,?),?))">)
     -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Swizzle-composed dynamic with deep mode [1, 0, 1].
// CHECK-LABEL: func.func @cosize_swizzle_composed_dynamic_deep_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,4,6> o ? o ((?,?),((?,?),?)):((?,?),((?,?),?))">)
func.func @cosize_swizzle_composed_dynamic_deep_mode(
    %src: !cute.composed_layout<"S<3,4,6> o ? o ((?,?),((?,?),?)):((?,?),((?,?),?))">)
    -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.cosize<[1, 0, 1]> (%[[SRC]]) : {{.*}} -> !cute.int_tuple<"?">
  %r = cute.cosize<[1, 0, 1]>(%src)
      : (!cute.composed_layout<"S<3,4,6> o ? o ((?,?),((?,?),?)):((?,?),((?,?),?))">)
     -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
