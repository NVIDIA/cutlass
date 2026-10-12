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
// Tests round-trip for cute.to_int_tuple.

// -----

// Tests conversion of shape to int_tuple.
// CHECK-LABEL: func.func @from_shape
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,8)">)
func.func @from_shape(%s: !cute.shape<"(4,8)">) -> !cute.int_tuple<"(4,8)"> {
  // CHECK: %[[R:.+]] = cute.to_int_tuple(%[[S]]) : !cute.shape<"(4,8)"> -> !cute.int_tuple<"(4,8)">
  %r = cute.to_int_tuple(%s) : !cute.shape<"(4,8)"> -> !cute.int_tuple<"(4,8)">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"(4,8)">
}

// -----

// Tests conversion of stride to int_tuple.
// CHECK-LABEL: func.func @from_stride
// CHECK-SAME:  (%[[ST:.+]]: !cute.stride<"(1,4)">)
func.func @from_stride(%st: !cute.stride<"(1,4)">) -> !cute.int_tuple<"(1,4)"> {
  // CHECK: %[[R:.+]] = cute.to_int_tuple(%[[ST]]) : !cute.stride<"(1,4)"> -> !cute.int_tuple<"(1,4)">
  %r = cute.to_int_tuple(%st) : !cute.stride<"(1,4)"> -> !cute.int_tuple<"(1,4)">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"(1,4)">
}

// -----

// Tests conversion of coord to int_tuple.
// CHECK-LABEL: func.func @from_coord
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(2,3)">)
func.func @from_coord(%c: !cute.coord<"(2,3)">) -> !cute.int_tuple<"(2,3)"> {
  // CHECK: %[[R:.+]] = cute.to_int_tuple(%[[C]]) : !cute.coord<"(2,3)"> -> !cute.int_tuple<"(2,3)">
  %r = cute.to_int_tuple(%c) : !cute.coord<"(2,3)"> -> !cute.int_tuple<"(2,3)">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"(2,3)">
}

// -----

// Tests conversion of int_tuple to itself (identity).
// CHECK-LABEL: func.func @from_int_tuple
// CHECK-SAME:  (%[[I:.+]]: !cute.int_tuple<"(1,2)">)
func.func @from_int_tuple(%i: !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(1,2)"> {
  // CHECK: %[[R:.+]] = cute.to_int_tuple(%[[I]]) : !cute.int_tuple<"(1,2)"> -> !cute.int_tuple<"(1,2)">
  %r = cute.to_int_tuple(%i) : !cute.int_tuple<"(1,2)"> -> !cute.int_tuple<"(1,2)">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"(1,2)">
}

// -----

// Stride with a mixed static/dynamic mode — converts to an
// int_tuple of the same shape.
// CHECK-LABEL: func.func @from_stride_mixed
// CHECK-SAME:  (%[[ST:.+]]: !cute.stride<"(8,?)">)
func.func @from_stride_mixed(%st: !cute.stride<"(8,?)">)
    -> !cute.int_tuple<"(8,?)"> {
  // CHECK: %[[R:.+]] = cute.to_int_tuple(%[[ST]]) : !cute.stride<"(8,?)"> -> !cute.int_tuple<"(8,?)">
  %r = cute.to_int_tuple(%st)
       : !cute.stride<"(8,?)"> -> !cute.int_tuple<"(8,?)">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"(8,?)">
}

// -----

// Tests conversion of a fully-dynamic shape — `?` leaves flow
// through to the int_tuple result.
// CHECK-LABEL: func.func @from_shape_dynamic
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(?,8)">)
func.func @from_shape_dynamic(%s: !cute.shape<"(?,8)">) -> !cute.int_tuple<"(?,8)"> {
  // CHECK: %[[R:.+]] = cute.to_int_tuple(%[[S]]) : !cute.shape<"(?,8)"> -> !cute.int_tuple<"(?,8)">
  %r = cute.to_int_tuple(%s) : !cute.shape<"(?,8)"> -> !cute.int_tuple<"(?,8)">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"(?,8)">
}

// -----

// Tests conversion of a nested shape — hierarchical structure
// preserved.
// CHECK-LABEL: func.func @from_shape_nested
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,(2,3),8)">)
func.func @from_shape_nested(%s: !cute.shape<"(4,(2,3),8)">)
    -> !cute.int_tuple<"(4,(2,3),8)"> {
  // CHECK: %[[R:.+]] = cute.to_int_tuple(%[[S]]) : !cute.shape<"(4,(2,3),8)"> -> !cute.int_tuple<"(4,(2,3),8)">
  %r = cute.to_int_tuple(%s)
       : !cute.shape<"(4,(2,3),8)"> -> !cute.int_tuple<"(4,(2,3),8)">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"(4,(2,3),8)">
}
