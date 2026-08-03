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

// Tests round-trip for cute.shape_div.

// -----

// Tuple / tuple: element-wise shape_div.
// CHECK-LABEL: func.func @div_tuple_tuple
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"(8,10)">, %[[B:.+]]: !cute.shape<"(2,5)">)
func.func @div_tuple_tuple(%a: !cute.shape<"(8,10)">, %b: !cute.shape<"(2,5)">) -> !cute.shape<"(4,2)"> {
  // CHECK: %[[R:.+]] = cute.shape_div(%[[A]], %[[B]]) : (!cute.shape<"(8,10)">, !cute.shape<"(2,5)">) -> !cute.shape<"(4,2)">
  %r = cute.shape_div(%a, %b) : (!cute.shape<"(8,10)">, !cute.shape<"(2,5)">) -> !cute.shape<"(4,2)">
  return %r : !cute.shape<"(4,2)">
}

// -----

// Scalar / scalar.
// CHECK-LABEL: func.func @div_scalar_scalar
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"12">, %[[B:.+]]: !cute.shape<"4">)
func.func @div_scalar_scalar(%a: !cute.shape<"12">, %b: !cute.shape<"4">) -> !cute.shape<"3"> {
  // CHECK: %[[R:.+]] = cute.shape_div(%[[A]], %[[B]]) : (!cute.shape<"12">, !cute.shape<"4">) -> !cute.shape<"3">
  %r = cute.shape_div(%a, %b) : (!cute.shape<"12">, !cute.shape<"4">) -> !cute.shape<"3">
  return %r : !cute.shape<"3">
}

// -----

// Tuple / scalar: sequential consumption across tuple elements.
// CHECK-LABEL: func.func @div_tuple_scalar_sequential
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"(4,5,6)">, %[[B:.+]]: !cute.shape<"40">)
func.func @div_tuple_scalar_sequential(%a: !cute.shape<"(4,5,6)">, %b: !cute.shape<"40">) -> !cute.shape<"(1,1,3)"> {
  // CHECK: %[[R:.+]] = cute.shape_div(%[[A]], %[[B]]) : (!cute.shape<"(4,5,6)">, !cute.shape<"40">) -> !cute.shape<"(1,1,3)">
  %r = cute.shape_div(%a, %b) : (!cute.shape<"(4,5,6)">, !cute.shape<"40">) -> !cute.shape<"(1,1,3)">
  return %r : !cute.shape<"(1,1,3)">
}

// -----

// Scalar / tuple: reduces to shape_div(a, product(b)).
// CHECK-LABEL: func.func @div_scalar_tuple
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"60">, %[[B:.+]]: !cute.shape<"(3,4,5)">)
func.func @div_scalar_tuple(%a: !cute.shape<"60">, %b: !cute.shape<"(3,4,5)">) -> !cute.shape<"1"> {
  // CHECK: %[[R:.+]] = cute.shape_div(%[[A]], %[[B]]) : (!cute.shape<"60">, !cute.shape<"(3,4,5)">) -> !cute.shape<"1">
  %r = cute.shape_div(%a, %b) : (!cute.shape<"60">, !cute.shape<"(3,4,5)">) -> !cute.shape<"1">
  return %r : !cute.shape<"1">
}

// -----

// Nested tuple / nested tuple.
// CHECK-LABEL: func.func @div_nested
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"((8,10),(6,4))">, %[[B:.+]]: !cute.shape<"((2,5),(3,2))">)
func.func @div_nested(%a: !cute.shape<"((8,10),(6,4))">, %b: !cute.shape<"((2,5),(3,2))">) -> !cute.shape<"((4,2),(2,2))"> {
  // CHECK: %[[R:.+]] = cute.shape_div(%[[A]], %[[B]]) : (!cute.shape<"((8,10),(6,4))">, !cute.shape<"((2,5),(3,2))">) -> !cute.shape<"((4,2),(2,2))">
  %r = cute.shape_div(%a, %b) : (!cute.shape<"((8,10),(6,4))">, !cute.shape<"((2,5),(3,2))">) -> !cute.shape<"((4,2),(2,2))">
  return %r : !cute.shape<"((4,2),(2,2))">
}

// -----

// Dynamic shapes: result is dynamic.
// CHECK-LABEL: func.func @div_dynamic
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"(?,?)">, %[[B:.+]]: !cute.shape<"(?,?)">)
func.func @div_dynamic(%a: !cute.shape<"(?,?)">, %b: !cute.shape<"(?,?)">) -> !cute.shape<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.shape_div(%[[A]], %[[B]]) : (!cute.shape<"(?,?)">, !cute.shape<"(?,?)">) -> !cute.shape<"(?,?)">
  %r = cute.shape_div(%a, %b) : (!cute.shape<"(?,?)">, !cute.shape<"(?,?)">) -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}

// -----

// Dynamic / static.
// CHECK-LABEL: func.func @div_dyn_static
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"(?,?)">, %[[B:.+]]: !cute.shape<"(2,5)">)
func.func @div_dyn_static(
    %a: !cute.shape<"(?,?)">, %b: !cute.shape<"(2,5)">)
    -> !cute.shape<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.shape_div(%[[A]], %[[B]])
  // CHECK-SAME: -> !cute.shape<"(?,?)">
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"(?,?)">, !cute.shape<"(2,5)">)
      -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}
