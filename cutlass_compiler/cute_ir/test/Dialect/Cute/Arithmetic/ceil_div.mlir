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

// Tests round-trip for cute.ceil_div.

// -----

// Scalar / scalar
// CHECK-LABEL: func.func @ceil_div_scalar_scalar
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"7">, %[[B:.+]]: !cute.int_tuple<"3">)
func.func @ceil_div_scalar_scalar(%a: !cute.int_tuple<"7">, %b: !cute.int_tuple<"3">) -> !cute.int_tuple<"3"> {
  // CHECK: %[[R:.+]] = cute.ceil_div(%[[A]], %[[B]]) : (!cute.int_tuple<"7">, !cute.int_tuple<"3">) -> !cute.int_tuple<"3">
  %r = cute.ceil_div(%a, %b) : (!cute.int_tuple<"7">, !cute.int_tuple<"3">) -> !cute.int_tuple<"3">
  return %r : !cute.int_tuple<"3">
}

// -----

// Tuple / tuple (same rank): element-wise ceil_div.
// CHECK-LABEL: func.func @ceil_div_tuple_tuple
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(8,10)">, %[[B:.+]]: !cute.int_tuple<"(3,4)">)
func.func @ceil_div_tuple_tuple(%a: !cute.int_tuple<"(8,10)">, %b: !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(3,3)"> {
  // CHECK: %[[R:.+]] = cute.ceil_div(%[[A]], %[[B]]) : (!cute.int_tuple<"(8,10)">, !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(3,3)">
  %r = cute.ceil_div(%a, %b) : (!cute.int_tuple<"(8,10)">, !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(3,3)">
  return %r : !cute.int_tuple<"(3,3)">
}

// -----

// Tuple / tuple (input longer): extra elements pass through.
// CHECK-LABEL: func.func @ceil_div_tuple_tuple_lhs_longer
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(8,10,6)">, %[[B:.+]]: !cute.int_tuple<"(3,4)">)
func.func @ceil_div_tuple_tuple_lhs_longer(%a: !cute.int_tuple<"(8,10,6)">, %b: !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(3,3,6)"> {
  // CHECK: %[[R:.+]] = cute.ceil_div(%[[A]], %[[B]]) : (!cute.int_tuple<"(8,10,6)">, !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(3,3,6)">
  %r = cute.ceil_div(%a, %b) : (!cute.int_tuple<"(8,10,6)">, !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(3,3,6)">
  return %r : !cute.int_tuple<"(3,3,6)">
}

// -----

// Tuple / scalar: sequential consumption.
// CHECK-LABEL: func.func @ceil_div_tuple_scalar
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(4,8)">, %[[B:.+]]: !cute.int_tuple<"2">)
func.func @ceil_div_tuple_scalar(%a: !cute.int_tuple<"(4,8)">, %b: !cute.int_tuple<"2">) -> !cute.int_tuple<"(2,8)"> {
  // CHECK: %[[R:.+]] = cute.ceil_div(%[[A]], %[[B]]) : (!cute.int_tuple<"(4,8)">, !cute.int_tuple<"2">) -> !cute.int_tuple<"(2,8)">
  %r = cute.ceil_div(%a, %b) : (!cute.int_tuple<"(4,8)">, !cute.int_tuple<"2">) -> !cute.int_tuple<"(2,8)">
  return %r : !cute.int_tuple<"(2,8)">
}

// -----

// Shape variant: result kind matches input kind.
// CHECK-LABEL: func.func @ceil_div_shape
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"(8,9)">, %[[B:.+]]: !cute.shape<"(3,4)">)
func.func @ceil_div_shape(%a: !cute.shape<"(8,9)">, %b: !cute.shape<"(3,4)">) -> !cute.shape<"(3,3)"> {
  // CHECK: %[[R:.+]] = cute.ceil_div(%[[A]], %[[B]]) : (!cute.shape<"(8,9)">, !cute.shape<"(3,4)">) -> !cute.shape<"(3,3)">
  %r = cute.ceil_div(%a, %b) : (!cute.shape<"(8,9)">, !cute.shape<"(3,4)">) -> !cute.shape<"(3,3)">
  return %r : !cute.shape<"(3,3)">
}

// -----

// Mixed kinds: int_tuple input with shape tiler. Result kind matches input.
// CHECK-LABEL: func.func @ceil_div_mixed_kinds
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(8,9)">, %[[B:.+]]: !cute.shape<"(3,4)">)
func.func @ceil_div_mixed_kinds(%a: !cute.int_tuple<"(8,9)">, %b: !cute.shape<"(3,4)">) -> !cute.int_tuple<"(3,3)"> {
  // CHECK: %[[R:.+]] = cute.ceil_div(%[[A]], %[[B]]) : (!cute.int_tuple<"(8,9)">, !cute.shape<"(3,4)">) -> !cute.int_tuple<"(3,3)">
  %r = cute.ceil_div(%a, %b) : (!cute.int_tuple<"(8,9)">, !cute.shape<"(3,4)">) -> !cute.int_tuple<"(3,3)">
  return %r : !cute.int_tuple<"(3,3)">
}

// -----

// Dynamic operands: result is dynamic.
// CHECK-LABEL: func.func @ceil_div_dynamic
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(?,?)">, %[[B:.+]]: !cute.int_tuple<"(?,?)">)
func.func @ceil_div_dynamic(%a: !cute.int_tuple<"(?,?)">, %b: !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.ceil_div(%[[A]], %[[B]]) : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  %r = cute.ceil_div(%a, %b) : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// Dynamic / static.
// CHECK-LABEL: func.func @ceil_div_dyn_static
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(?,?)">, %[[B:.+]]: !cute.int_tuple<"(2,5)">)
func.func @ceil_div_dyn_static(
    %a: !cute.int_tuple<"(?,?)">,
    %b: !cute.int_tuple<"(2,5)">)
    -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.ceil_div(%[[A]], %[[B]])
  // CHECK-SAME: -> !cute.int_tuple<"(?,?)">
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(2,5)">)
      -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// Tiler is a `!cute.tile`. `ceil_div(shape, tile)` flattens
// the tile to a scalar size and computes scalar ceil_div, so the
// result is a scalar regardless of input rank. Result kind follows
// input kind (int_tuple in / int_tuple out, shape in / shape out).
// CHECK-LABEL: func.func @ceil_div_int_tuple_tile
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(8,16)">, %[[T:.+]]: !cute.tile<"((4,8)):((1,4))">)
func.func @ceil_div_int_tuple_tile(%a: !cute.int_tuple<"(8,16)">,
                                   %t: !cute.tile<"((4,8)):((1,4))">)
    -> !cute.int_tuple<"4"> {
  // CHECK: %[[R:.+]] = cute.ceil_div(%[[A]], %[[T]])
  // CHECK-SAME: -> !cute.int_tuple<"4">
  %r = cute.ceil_div(%a, %t)
       : (!cute.int_tuple<"(8,16)">, !cute.tile<"((4,8)):((1,4))">)
      -> !cute.int_tuple<"4">
  return %r : !cute.int_tuple<"4">
}

// -----

// Shape input, rank-2 tile tiler.
// CHECK-LABEL: func.func @ceil_div_shape_tile
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"(16,32)">, %[[T:.+]]: !cute.tile<"(4,8):(1,4)">)
func.func @ceil_div_shape_tile(%a: !cute.shape<"(16,32)">,
                               %t: !cute.tile<"(4,8):(1,4)">)
    -> !cute.shape<"16"> {
  // CHECK: %[[R:.+]] = cute.ceil_div(%[[A]], %[[T]])
  // CHECK-SAME: -> !cute.shape<"16">
  %r = cute.ceil_div(%a, %t)
       : (!cute.shape<"(16,32)">, !cute.tile<"(4,8):(1,4)">)
      -> !cute.shape<"16">
  return %r : !cute.shape<"16">
}
