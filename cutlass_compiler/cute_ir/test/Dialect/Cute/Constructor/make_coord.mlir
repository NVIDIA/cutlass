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

// Tests parse/print round-trip for cute.make_coord.

// -----

// Scalar static — no operands.
// CHECK-LABEL: func.func @scalar_static
func.func @scalar_static() -> !cute.coord<"1"> {
  // CHECK: %[[V:.+]] = cute.make_coord() : () -> !cute.coord<"1">
  %0 = cute.make_coord() : () -> !cute.coord<"1">
  return %0 : !cute.coord<"1">
}

// -----

// Scalar dynamic — one i32 leaf.
// CHECK-LABEL: func.func @scalar_dynamic
func.func @scalar_dynamic(%i: i32) -> !cute.coord<"?"> {
  // CHECK: %[[V:.+]] = cute.make_coord(%{{.+}}) : (i32) -> !cute.coord<"?">
  %0 = cute.make_coord(%i) : (i32) -> !cute.coord<"?">
  return %0 : !cute.coord<"?">
}

// -----

// Scalar underscore wildcard.
// CHECK-LABEL: func.func @scalar_underscore
func.func @scalar_underscore() -> !cute.coord<"_"> {
  // CHECK: %[[V:.+]] = cute.make_coord() : () -> !cute.coord<"_">
  %0 = cute.make_coord() : () -> !cute.coord<"_">
  return %0 : !cute.coord<"_">
}

// -----

// Flat static — no operands.
// CHECK-LABEL: func.func @flat_static
func.func @flat_static() -> !cute.coord<"(1,2)"> {
  // CHECK: %[[V:.+]] = cute.make_coord() : () -> !cute.coord<"(1,2)">
  %0 = cute.make_coord() : () -> !cute.coord<"(1,2)">
  return %0 : !cute.coord<"(1,2)">
}

// -----

// Flat dynamic — two i32 leaves.
// CHECK-LABEL: func.func @flat_dynamic
func.func @flat_dynamic(%i: i32, %j: i32) -> !cute.coord<"(?,?)"> {
  // CHECK: %[[V:.+]] = cute.make_coord(%{{.+}}, %{{.+}}) : (i32, i32) -> !cute.coord<"(?,?)">
  %0 = cute.make_coord(%i, %j) : (i32, i32) -> !cute.coord<"(?,?)">
  return %0 : !cute.coord<"(?,?)">
}

// -----

// Underscore slot: one dynamic leaf, one underscore.
// CHECK-LABEL: func.func @underscore_slot
func.func @underscore_slot(%i: i32) -> !cute.coord<"(?,_)"> {
  // CHECK: %[[V:.+]] = cute.make_coord(%{{.+}}) : (i32) -> !cute.coord<"(?,_)">
  %0 = cute.make_coord(%i) : (i32) -> !cute.coord<"(?,_)">
  return %0 : !cute.coord<"(?,_)">
}

// -----

// Two underscores plus one dynamic leaf.
// CHECK-LABEL: func.func @two_underscores
func.func @two_underscores(%k: i32) -> !cute.coord<"(_,_,?)"> {
  // CHECK: %[[V:.+]] = cute.make_coord(%{{.+}}) : (i32) -> !cute.coord<"(_,_,?)">
  %0 = cute.make_coord(%k) : (i32) -> !cute.coord<"(_,_,?)">
  return %0 : !cute.coord<"(_,_,?)">
}

// -----

// Nested static — no operands.
// CHECK-LABEL: func.func @nested_static
func.func @nested_static() -> !cute.coord<"(1,(2,3))"> {
  // CHECK: %[[V:.+]] = cute.make_coord() : () -> !cute.coord<"(1,(2,3))">
  %0 = cute.make_coord() : () -> !cute.coord<"(1,(2,3))">
  return %0 : !cute.coord<"(1,(2,3))">
}

// -----

// Nested with underscore in inner tuple.
// CHECK-LABEL: func.func @nested_underscore
func.func @nested_underscore(%i: i32) -> !cute.coord<"(?,(_,2))"> {
  // CHECK: %[[V:.+]] = cute.make_coord(%{{.+}}) : (i32) -> !cute.coord<"(?,(_,2))">
  %0 = cute.make_coord(%i) : (i32) -> !cute.coord<"(?,(_,2))">
  return %0 : !cute.coord<"(?,(_,2))">
}

// -----

// int_tuple leaf as a sub-element.
// CHECK-LABEL: func.func @nested_int_tuple_leaf
func.func @nested_int_tuple_leaf(%i: i32, %j: i32) -> !cute.coord<"(?,?)"> {
  // CHECK: %[[INNER:.+]] = cute.make_int_tuple(%{{.+}}) : (i32) -> !cute.int_tuple<"?">
  // CHECK: %[[V:.+]] = cute.make_coord(%{{.+}}, %[[INNER]])
  // CHECK-SAME: (i32, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
  %inner = cute.make_int_tuple(%j) : (i32) -> !cute.int_tuple<"?">
  %0 = cute.make_coord(%i, %inner)
         : (i32, !cute.int_tuple<"?">) -> !cute.coord<"(?,?)">
  return %0 : !cute.coord<"(?,?)">
}

// -----

// Rank-3 flat coord — three i32 dynamic leaves.
// CHECK-LABEL: func.func @three_dynamic
// CHECK-SAME: (%[[A:.+]]: i32, %[[B:.+]]: i32, %[[C:.+]]: i32)
func.func @three_dynamic(%a: i32, %b: i32, %c: i32) -> !cute.coord<"(?,?,?)"> {
  // CHECK: cute.make_coord(%[[A]], %[[B]], %[[C]]) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
  %0 = cute.make_coord(%a, %b, %c) : (i32, i32, i32) -> !cute.coord<"(?,?,?)">
  return %0 : !cute.coord<"(?,?,?)">
}
