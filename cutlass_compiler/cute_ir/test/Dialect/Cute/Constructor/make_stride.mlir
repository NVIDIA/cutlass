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

// Tests parse/print round-trip for cute.make_stride.

// -----

// Scalar static — no operands.
// CHECK-LABEL: func.func @scalar_static
func.func @scalar_static() -> !cute.stride<"1"> {
  // CHECK: %[[V:.+]] = cute.make_stride() : () -> !cute.stride<"1">
  %0 = cute.make_stride() : () -> !cute.stride<"1">
  return %0 : !cute.stride<"1">
}

// -----

// Scalar dynamic — one i32 leaf.
// CHECK-LABEL: func.func @scalar_dynamic
func.func @scalar_dynamic(%s: i32) -> !cute.stride<"?"> {
  // CHECK: %[[V:.+]] = cute.make_stride(%{{.+}}) : (i32) -> !cute.stride<"?">
  %0 = cute.make_stride(%s) : (i32) -> !cute.stride<"?">
  return %0 : !cute.stride<"?">
}

// -----

// Static scaled-basis — no operands needed (V@M is fully static).
// CHECK-LABEL: func.func @static_scaled_basis
func.func @static_scaled_basis() -> !cute.stride<"4@0"> {
  // CHECK: %[[V:.+]] = cute.make_stride() : () -> !cute.stride<"4@0">
  %0 = cute.make_stride() : () -> !cute.stride<"4@0">
  return %0 : !cute.stride<"4@0">
}

// -----

// Dynamic scaled-basis: ?@0 — dynamic scale, static mode index.
// CHECK-LABEL: func.func @dynamic_scaled_basis
func.func @dynamic_scaled_basis(%s: i32) -> !cute.stride<"?@0"> {
  // CHECK: %[[V:.+]] = cute.make_stride(%{{.+}}) : (i32) -> !cute.stride<"?@0">
  %0 = cute.make_stride(%s) : (i32) -> !cute.stride<"?@0">
  return %0 : !cute.stride<"?@0">
}

// -----

// Hierarchical (chained) static scaled-basis — no operands.
// CHECK-LABEL: func.func @hierarchical_basis_static
func.func @hierarchical_basis_static() -> !cute.stride<"1@1@0"> {
  // CHECK: %[[V:.+]] = cute.make_stride() : () -> !cute.stride<"1@1@0">
  %0 = cute.make_stride() : () -> !cute.stride<"1@1@0">
  return %0 : !cute.stride<"1@1@0">
}

// -----

// Flat static tuple — no operands.
// CHECK-LABEL: func.func @flat_static
func.func @flat_static() -> !cute.stride<"(16,32)"> {
  // CHECK: %[[V:.+]] = cute.make_stride() : () -> !cute.stride<"(16,32)">
  %0 = cute.make_stride() : () -> !cute.stride<"(16,32)">
  return %0 : !cute.stride<"(16,32)">
}

// -----

// Flat mixed: one dynamic leaf.
// CHECK-LABEL: func.func @flat_mixed
func.func @flat_mixed(%s: i32) -> !cute.stride<"(1,?)"> {
  // CHECK: %[[V:.+]] = cute.make_stride(%{{.+}}) : (i32) -> !cute.stride<"(1,?)">
  %0 = cute.make_stride(%s) : (i32) -> !cute.stride<"(1,?)">
  return %0 : !cute.stride<"(1,?)">
}

// -----

// Flat with dynamic scaled-basis element. Zero-int leaves are allowed
// alongside scaled-basis leaves.
// CHECK-LABEL: func.func @flat_dynamic_basis
func.func @flat_dynamic_basis(%s: i32) -> !cute.stride<"(0,?@0)"> {
  // CHECK: %[[V:.+]] = cute.make_stride(%{{.+}}) : (i32) -> !cute.stride<"(0,?@0)">
  %0 = cute.make_stride(%s) : (i32) -> !cute.stride<"(0,?@0)">
  return %0 : !cute.stride<"(0,?@0)">
}

// -----

// Nested static — no operands.
// CHECK-LABEL: func.func @nested_static
func.func @nested_static() -> !cute.stride<"(16,(32,4))"> {
  // CHECK: %[[V:.+]] = cute.make_stride() : () -> !cute.stride<"(16,(32,4))">
  %0 = cute.make_stride() : () -> !cute.stride<"(16,(32,4))">
  return %0 : !cute.stride<"(16,(32,4))">
}

// -----

// int_tuple leaf as a sub-element (depth-0 int_tuple passed to make_stride).
// CHECK-LABEL: func.func @nested_int_tuple_leaf
func.func @nested_int_tuple_leaf(%s: i32, %t: i32) -> !cute.stride<"(?,?)"> {
  // CHECK: %[[INNER:.+]] = cute.make_int_tuple(%{{.+}}) : (i32) -> !cute.int_tuple<"?">
  // CHECK: %[[V:.+]] = cute.make_stride(%{{.+}}, %[[INNER]])
  // CHECK-SAME: (i32, !cute.int_tuple<"?">) -> !cute.stride<"(?,?)">
  %inner = cute.make_int_tuple(%s) : (i32) -> !cute.int_tuple<"?">
  %0 = cute.make_stride(%t, %inner)
         : (i32, !cute.int_tuple<"?">) -> !cute.stride<"(?,?)">
  return %0 : !cute.stride<"(?,?)">
}

// -----

// Rank-3 flat stride — three i32 dynamic leaves.
// CHECK-LABEL: func.func @three_dynamic
// CHECK-SAME: (%[[A:.+]]: i32, %[[B:.+]]: i32, %[[C:.+]]: i32)
func.func @three_dynamic(%a: i32, %b: i32, %c: i32) -> !cute.stride<"(?,?,?)"> {
  // CHECK: cute.make_stride(%[[A]], %[[B]], %[[C]]) : (i32, i32, i32) -> !cute.stride<"(?,?,?)">
  %0 = cute.make_stride(%a, %b, %c) : (i32, i32, i32) -> !cute.stride<"(?,?,?)">
  return %0 : !cute.stride<"(?,?,?)">
}

// -----

// Static int_tuple operand promoted to a dynamic stride result.
// CHECK-LABEL: func.func @static_int_tuple_to_dyn_stride
func.func @static_int_tuple_to_dyn_stride(%t: !cute.int_tuple<"4">) -> !cute.stride<"?"> {
  // CHECK: %[[V:.+]] = cute.make_stride(%{{.+}}) : (!cute.int_tuple<"4">) -> !cute.stride<"?">
  %0 = cute.make_stride(%t) : (!cute.int_tuple<"4">) -> !cute.stride<"?">
  return %0 : !cute.stride<"?">
}
