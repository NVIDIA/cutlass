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
// Tests parse/print round-trip for cute.make_int_tuple.
// -----
// Scalar static — no operands.
// CHECK-LABEL: func.func @scalar_static
func.func @scalar_static() -> !cute.int_tuple<"4"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
  %0 = cute.make_int_tuple() : () -> !cute.int_tuple<"4">
  return %0 : !cute.int_tuple<"4">
}
// -----
// Scalar dynamic — one i32 leaf.
// CHECK-LABEL: func.func @scalar_dynamic
func.func @scalar_dynamic(%n: i32) -> !cute.int_tuple<"?"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple(%{{.+}}) : (i32) -> !cute.int_tuple<"?">
  %0 = cute.make_int_tuple(%n) : (i32) -> !cute.int_tuple<"?">
  return %0 : !cute.int_tuple<"?">
}
// -----
// Scalar dynamic.
// CHECK-LABEL: func.func @scalar_constrained
func.func @scalar_constrained(%n: i32) -> !cute.int_tuple<"?"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple(%{{.+}}) : (i32) -> !cute.int_tuple<"?">
  %0 = cute.make_int_tuple(%n) : (i32) -> !cute.int_tuple<"?">
  return %0 : !cute.int_tuple<"?">
}
// -----
// Flat static tuple — no operands.
// CHECK-LABEL: func.func @flat_static
func.func @flat_static() -> !cute.int_tuple<"(4,3)"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple() : () -> !cute.int_tuple<"(4,3)">
  %0 = cute.make_int_tuple() : () -> !cute.int_tuple<"(4,3)">
  return %0 : !cute.int_tuple<"(4,3)">
}
// -----
// Flat dynamic tuple — two i32 leaves.
// CHECK-LABEL: func.func @flat_dynamic
func.func @flat_dynamic(%m: i32, %n: i32) -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple(%{{.+}}, %{{.+}}) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %0 = cute.make_int_tuple(%m, %n) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  return %0 : !cute.int_tuple<"(?,?)">
}
// -----
// Mixed: static and dynamic leaves in one flat tuple.
// CHECK-LABEL: func.func @flat_mixed
func.func @flat_mixed(%m: i32) -> !cute.int_tuple<"(?,3)"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple(%{{.+}}) : (i32) -> !cute.int_tuple<"(?,3)">
  %0 = cute.make_int_tuple(%m) : (i32) -> !cute.int_tuple<"(?,3)">
  return %0 : !cute.int_tuple<"(?,3)">
}
// -----
// Nested static tuple — no operands.
// CHECK-LABEL: func.func @nested_static
func.func @nested_static() -> !cute.int_tuple<"(4,(2,3))"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple() : () -> !cute.int_tuple<"(4,(2,3))">
  %0 = cute.make_int_tuple() : () -> !cute.int_tuple<"(4,(2,3))">
  return %0 : !cute.int_tuple<"(4,(2,3))">
}
// -----
// Nested dynamic — constrained leaf plus a static-nested element.
// CHECK-LABEL: func.func @nested_dynamic
func.func @nested_dynamic(%a: i32, %b: i32) -> !cute.int_tuple<"(?,(?,3))"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple(%{{.+}}, %{{.+}}) : (i32, i32) -> !cute.int_tuple<"(?,(?,3))">
  %0 = cute.make_int_tuple(%a, %b) : (i32, i32) -> !cute.int_tuple<"(?,(?,3))">
  return %0 : !cute.int_tuple<"(?,(?,3))">
}
// -----
// Sub-tuple passed as int_tuple operand (rank-1 depth-0 sub-tuple).
// CHECK-LABEL: func.func @nested_sub_tuple
func.func @nested_sub_tuple(%k: i32, %m: i32) -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[INNER:.+]] = cute.make_int_tuple(%{{.+}}) : (i32) -> !cute.int_tuple<"?">
  // CHECK: %[[V:.+]] = cute.make_int_tuple(%{{.+}}, %[[INNER]])
  // CHECK-SAME: (i32, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?)">
  %inner = cute.make_int_tuple(%k) : (i32) -> !cute.int_tuple<"?">
  %0 = cute.make_int_tuple(%m, %inner)
         : (i32, !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,?)">
  return %0 : !cute.int_tuple<"(?,?)">
}
// -----
// Rank-3 flat tuple — three i32 dynamic leaves.
// CHECK-LABEL: func.func @three_dynamic
// CHECK-SAME: (%[[A:.+]]: i32, %[[B:.+]]: i32, %[[C:.+]]: i32)
func.func @three_dynamic(%a: i32, %b: i32, %c: i32) -> !cute.int_tuple<"(?,?,?)"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple(%[[A]], %[[B]], %[[C]]) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
  %0 = cute.make_int_tuple(%a, %b, %c) : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
  return %0 : !cute.int_tuple<"(?,?,?)">
}
// -----
// Depth-2 nested dynamic.
// CHECK-LABEL: func.func @nested_two_groups
// CHECK-SAME: (%[[X:.+]]: i32, %[[Y:.+]]: i32)
func.func @nested_two_groups(%x: i32, %y: i32) -> !cute.int_tuple<"((?,32),(?,64))"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple(%[[X]], %[[Y]]) : (i32, i32) -> !cute.int_tuple<"((?,32),(?,64))">
  %0 = cute.make_int_tuple(%x, %y) : (i32, i32) -> !cute.int_tuple<"((?,32),(?,64))">
  return %0 : !cute.int_tuple<"((?,32),(?,64))">
}
// -----
// CHECK-LABEL: func.func @from_int_tuple_with_static_suffix
// CHECK-SAME: (%[[T:.+]]: !cute.int_tuple<"?">)
func.func @from_int_tuple_with_static_suffix(
    %t: !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,8)"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple(%[[T]])
  // CHECK-SAME: (!cute.int_tuple<"?">) -> !cute.int_tuple<"(?,8)">
  %0 = cute.make_int_tuple(%t)
       : (!cute.int_tuple<"?">) -> !cute.int_tuple<"(?,8)">
  return %0 : !cute.int_tuple<"(?,8)">
}
// -----
// CHECK-LABEL: func.func @from_int_tuple_with_static_suffix
// CHECK-SAME: (%[[T:.+]]: !cute.int_tuple<"?">)
func.func @from_int_tuple_with_static_suffix(
    %t: !cute.int_tuple<"?">) -> !cute.int_tuple<"(?,4)"> {
  // CHECK: %[[V:.+]] = cute.make_int_tuple(%[[T]])
  // CHECK-SAME: (!cute.int_tuple<"?">) -> !cute.int_tuple<"(?,4)">
  %0 = cute.make_int_tuple(%t)
       : (!cute.int_tuple<"?">) -> !cute.int_tuple<"(?,4)">
  return %0 : !cute.int_tuple<"(?,4)">
}
