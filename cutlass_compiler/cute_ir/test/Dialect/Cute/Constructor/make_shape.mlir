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

// Tests parse/print round-trip for cute.make_shape.

// -----

// Scalar static — no operands.
// CHECK-LABEL: func.func @scalar_static
func.func @scalar_static() -> !cute.shape<"5"> {
  // CHECK: %[[V:.+]] = cute.make_shape() : () -> !cute.shape<"5">
  %0 = cute.make_shape() : () -> !cute.shape<"5">
  return %0 : !cute.shape<"5">
}

// -----

// Scalar dynamic — one i32 leaf.
// CHECK-LABEL: func.func @scalar_dynamic
func.func @scalar_dynamic(%n: i32) -> !cute.shape<"?"> {
  // CHECK: %[[V:.+]] = cute.make_shape(%{{.+}}) : (i32) -> !cute.shape<"?">
  %0 = cute.make_shape(%n) : (i32) -> !cute.shape<"?">
  return %0 : !cute.shape<"?">
}

// -----

// Flat static tuple — no operands.
// CHECK-LABEL: func.func @flat_static
func.func @flat_static() -> !cute.shape<"(128,64)"> {
  // CHECK: %[[V:.+]] = cute.make_shape() : () -> !cute.shape<"(128,64)">
  %0 = cute.make_shape() : () -> !cute.shape<"(128,64)">
  return %0 : !cute.shape<"(128,64)">
}

// -----

// Flat dynamic — two i32 leaves.
// CHECK-LABEL: func.func @flat_dynamic
func.func @flat_dynamic(%m: i32, %n: i32) -> !cute.shape<"(?,?)"> {
  // CHECK: %[[V:.+]] = cute.make_shape(%{{.+}}, %{{.+}}) : (i32, i32) -> !cute.shape<"(?,?)">
  %0 = cute.make_shape(%m, %n) : (i32, i32) -> !cute.shape<"(?,?)">
  return %0 : !cute.shape<"(?,?)">
}

// -----

// Mixed: one dynamic leaf, one static.
// CHECK-LABEL: func.func @flat_mixed
func.func @flat_mixed(%m: i32) -> !cute.shape<"(?,64)"> {
  // CHECK: %[[V:.+]] = cute.make_shape(%{{.+}}) : (i32) -> !cute.shape<"(?,64)">
  %0 = cute.make_shape(%m) : (i32) -> !cute.shape<"(?,64)">
  return %0 : !cute.shape<"(?,64)">
}

// -----

// Nested static — no operands.
// CHECK-LABEL: func.func @nested_static
func.func @nested_static() -> !cute.shape<"(4,(2,3))"> {
  // CHECK: %[[V:.+]] = cute.make_shape() : () -> !cute.shape<"(4,(2,3))">
  %0 = cute.make_shape() : () -> !cute.shape<"(4,(2,3))">
  return %0 : !cute.shape<"(4,(2,3))">
}

// -----

// Nested dynamic with constrained leaf.
// CHECK-LABEL: func.func @nested_dynamic
func.func @nested_dynamic(%a: i32, %b: i32) -> !cute.shape<"(?,(?,3))"> {
  // CHECK: %[[V:.+]] = cute.make_shape(%{{.+}}, %{{.+}}) : (i32, i32) -> !cute.shape<"(?,(?,3))">
  %0 = cute.make_shape(%a, %b) : (i32, i32) -> !cute.shape<"(?,(?,3))">
  return %0 : !cute.shape<"(?,(?,3))">
}

// -----

// int_tuple leaf as a sub-element (depth-0 int_tuple passed to make_shape).
// CHECK-LABEL: func.func @nested_int_tuple_leaf
func.func @nested_int_tuple_leaf(%k: i32, %m: i32) -> !cute.shape<"(?,?)"> {
  // CHECK: %[[INNER:.+]] = cute.make_int_tuple(%{{.+}}) : (i32) -> !cute.int_tuple<"?">
  // CHECK: %[[V:.+]] = cute.make_shape(%{{.+}}, %[[INNER]])
  // CHECK-SAME: (i32, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
  %inner = cute.make_int_tuple(%k) : (i32) -> !cute.int_tuple<"?">
  %0 = cute.make_shape(%m, %inner)
         : (i32, !cute.int_tuple<"?">) -> !cute.shape<"(?,?)">
  return %0 : !cute.shape<"(?,?)">
}

// -----

// Rank-3 flat shape — three i32 dynamic leaves.
// CHECK-LABEL: func.func @three_dynamic
// CHECK-SAME: (%[[A:.+]]: i32, %[[B:.+]]: i32, %[[C:.+]]: i32)
func.func @three_dynamic(%a: i32, %b: i32, %c: i32) -> !cute.shape<"(?,?,?)"> {
  // CHECK: cute.make_shape(%[[A]], %[[B]], %[[C]]) : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
  %0 = cute.make_shape(%a, %b, %c) : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
  return %0 : !cute.shape<"(?,?,?)">
}

// -----

// CHECK-LABEL: func.func @nested_with_static_leading_leaf
// CHECK-SAME: (%[[A:.+]]: i32, %[[B:.+]]: i32)
func.func @nested_with_static_leading_leaf(%a: i32, %b: i32)
    -> !cute.shape<"((32,?,?),64)"> {
  // CHECK: cute.make_shape(%[[A]], %[[B]]) : (i32, i32) -> !cute.shape<"((32,?,?),64)">
  %0 = cute.make_shape(%a, %b) : (i32, i32) -> !cute.shape<"((32,?,?),64)">
  return %0 : !cute.shape<"((32,?,?),64)">
}
