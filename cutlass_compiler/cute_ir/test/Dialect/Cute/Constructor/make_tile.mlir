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

// Tests parse/print round-trip for cute.make_tile.

// -----

// 0 operands: fully static single-layout tile.
// CHECK-LABEL: func.func @static_single
func.func @static_single() -> !cute.tile<"[(2,3):(1,2)]"> {
  // CHECK: cute.make_tile() : () -> !cute.tile<"[(2,3):(1,2)]">
  %t = cute.make_tile() : () -> !cute.tile<"[(2,3):(1,2)]">
  return %t : !cute.tile<"[(2,3):(1,2)]">
}

// -----

// 0 operands: underscore-only tile.
// CHECK-LABEL: func.func @underscore_only
func.func @underscore_only() -> !cute.tile<"[_]"> {
  // CHECK: cute.make_tile() : () -> !cute.tile<"[_]">
  %t = cute.make_tile() : () -> !cute.tile<"[_]">
  return %t : !cute.tile<"[_]">
}

// -----

// 0 operands: static layout followed by underscore.
// CHECK-LABEL: func.func @static_plus_underscore
func.func @static_plus_underscore() -> !cute.tile<"[(2,3):(1,2);_]"> {
  // CHECK: cute.make_tile() : () -> !cute.tile<"[(2,3):(1,2);_]">
  %t = cute.make_tile() : () -> !cute.tile<"[(2,3):(1,2);_]">
  return %t : !cute.tile<"[(2,3):(1,2);_]">
}

// -----

// 0 operands: two static layouts.

// CHECK-LABEL: func.func @two_static_layouts
func.func @two_static_layouts() -> !cute.tile<"[(4,2):(1,4);(3,5):(1,3)]"> {
  // CHECK: cute.make_tile() : () -> !cute.tile<"[(4,2):(1,4);(3,5):(1,3)]">
  %t = cute.make_tile() : () -> !cute.tile<"[(4,2):(1,4);(3,5):(1,3)]">
  return %t : !cute.tile<"[(4,2):(1,4);(3,5):(1,3)]">
}

// -----

// 2 operands: one dynamic layout with 2 leaves (shape ?, stride ?).
// CHECK-LABEL: func.func @dynamic_single
// CHECK-SAME: (%[[M:.+]]: i32, %[[N:.+]]: i32)
func.func @dynamic_single(%m: i32, %n: i32) -> !cute.tile<"[(?,3):(1,?)]"> {
  // CHECK: %[[T:.+]] = cute.make_tile(%[[M]], %[[N]]) : (i32, i32) -> !cute.tile<"[(?,3):(1,?)]">
  %t = cute.make_tile(%m, %n) : (i32, i32) -> !cute.tile<"[(?,3):(1,?)]">
  return %t : !cute.tile<"[(?,3):(1,?)]">
}

// -----

// 2 operands: dynamic layout followed by underscore.
// CHECK-LABEL: func.func @dynamic_plus_underscore
// CHECK-SAME: (%[[M:.+]]: i32, %[[N:.+]]: i32)
func.func @dynamic_plus_underscore(%m: i32, %n: i32) -> !cute.tile<"[(?,3):(1,?);_]"> {
  // CHECK: %[[T:.+]] = cute.make_tile(%[[M]], %[[N]]) : (i32, i32) -> !cute.tile<"[(?,3):(1,?);_]">
  %t = cute.make_tile(%m, %n) : (i32, i32) -> !cute.tile<"[(?,3):(1,?);_]">
  return %t : !cute.tile<"[(?,3):(1,?);_]">
}

// -----

// 4 operands: two dynamic layouts, 2 leaves each.
// CHECK-LABEL: func.func @two_dynamic_layouts
// CHECK-SAME: (%[[M:.+]]: i32, %[[N:.+]]: i32, %[[P:.+]]: i32, %[[Q:.+]]: i32)
func.func @two_dynamic_layouts(%m: i32, %n: i32, %p: i32, %q: i32)
    -> !cute.tile<"[(?,3):(1,?);(?,2):(1,?)]"> {
  // CHECK: %[[T:.+]] = cute.make_tile(%[[M]], %[[N]], %[[P]], %[[Q]])
  // CHECK-SAME: (i32, i32, i32, i32) -> !cute.tile<"[(?,3):(1,?);(?,2):(1,?)]">
  %t = cute.make_tile(%m, %n, %p, %q)
         : (i32, i32, i32, i32) -> !cute.tile<"[(?,3):(1,?);(?,2):(1,?)]">
  return %t : !cute.tile<"[(?,3):(1,?);(?,2):(1,?)]">
}

// -----

// 2 operands: static layout, dynamic layout, underscore.
// Static slot contributes 0 leaves; dynamic layout contributes 2.

// CHECK-LABEL: func.func @static_dynamic_underscore
// CHECK-SAME: (%[[M:.+]]: i32, %[[N:.+]]: i32)
func.func @static_dynamic_underscore(%m: i32, %n: i32)
    -> !cute.tile<"[(4,2):(1,4);(?,3):(1,?);_]"> {
  // CHECK: cute.make_tile(%[[M]], %[[N]])
  // CHECK-SAME: (i32, i32) -> !cute.tile<"[(4,2):(1,4);(?,3):(1,?);_]">
  %t = cute.make_tile(%m, %n)
         : (i32, i32) -> !cute.tile<"[(4,2):(1,4);(?,3):(1,?);_]">
  return %t : !cute.tile<"[(4,2):(1,4);(?,3):(1,?);_]">
}

// -----

// 1 operand: rank-1 scalar layout with a single dynamic leaf.
// CHECK-LABEL: func.func @scalar_dynamic_layout
// CHECK-SAME: (%[[N:.+]]: i32)
func.func @scalar_dynamic_layout(%n: i32) -> !cute.tile<"[?:1]"> {
  // CHECK: cute.make_tile(%[[N]]) : (i32) -> !cute.tile<"[?:1]">
  %t = cute.make_tile(%n) : (i32) -> !cute.tile<"[?:1]">
  return %t : !cute.tile<"[?:1]">
}

// -----

// 2 operands: scalar layout with both shape and stride dynamic.

// CHECK-LABEL: func.func @scalar_dynamic_both
// CHECK-SAME: (%[[M:.+]]: i32, %[[N:.+]]: i32)
func.func @scalar_dynamic_both(%m: i32, %n: i32) -> !cute.tile<"[?:?]"> {
  // CHECK: cute.make_tile(%[[M]], %[[N]]) : (i32, i32) -> !cute.tile<"[?:?]">
  %t = cute.make_tile(%m, %n) : (i32, i32) -> !cute.tile<"[?:?]">
  return %t : !cute.tile<"[?:?]">
}

// -----

// Tile of tiles.
// CHECK-LABEL: func.func @tile_of_tiles
func.func @tile_of_tiles()
    -> !cute.tile<"[[(128,256):(256,1);_];[(2):(1);(4):(2)]]"> {
  // CHECK: cute.make_tile()
  // CHECK-SAME: () -> !cute.tile<"{{\[\[}}(128,256):(256,1);_];[(2):(1);(4):(2)]]">
  %t = cute.make_tile()
         : () -> !cute.tile<"[[(128,256):(256,1);_];[(2):(1);(4):(2)]]">
  return %t : !cute.tile<"[[(128,256):(256,1);_];[(2):(1);(4):(2)]]">
}

// -----

// `!cute.int_tuple<"?">` operand fills a dynamic leaf.
// CHECK-LABEL: func.func @int_tuple_operand
// CHECK-SAME: (%[[T:.+]]: !cute.int_tuple<"?">)
func.func @int_tuple_operand(%t: !cute.int_tuple<"?">)
    -> !cute.tile<"[?:1;3:1]"> {
  // CHECK: cute.make_tile(%[[T]])
  // CHECK-SAME: (!cute.int_tuple<"?">) -> !cute.tile<"[?:1;3:1]">
  %r = cute.make_tile(%t)
         : (!cute.int_tuple<"?">) -> !cute.tile<"[?:1;3:1]">
  return %r : !cute.tile<"[?:1;3:1]">
}
