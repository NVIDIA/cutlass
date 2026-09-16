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

// Tests round-trip for cute.equal.

// -----

// int_tuple / int_tuple.
// CHECK-LABEL: func.func @equal_int_tuple
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(3,4)">, %[[B:.+]]: !cute.int_tuple<"(3,4)">)
func.func @equal_int_tuple(%a: !cute.int_tuple<"(3,4)">, %b: !cute.int_tuple<"(3,4)">) -> i1 {
  // CHECK: %[[R:.+]] = cute.equal(%[[A]], %[[B]]) : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,4)">) -> i1
  %r = cute.equal(%a, %b) : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,4)">) -> i1
  return %r : i1
}

// -----

// shape / shape.
// CHECK-LABEL: func.func @equal_shape
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"(3,4)">, %[[B:.+]]: !cute.shape<"(3,5)">)
func.func @equal_shape(%a: !cute.shape<"(3,4)">, %b: !cute.shape<"(3,5)">) -> i1 {
  // CHECK: %[[R:.+]] = cute.equal(%[[A]], %[[B]]) : (!cute.shape<"(3,4)">, !cute.shape<"(3,5)">) -> i1
  %r = cute.equal(%a, %b) : (!cute.shape<"(3,4)">, !cute.shape<"(3,5)">) -> i1
  return %r : i1
}

// -----

// layout / layout.
// CHECK-LABEL: func.func @equal_layout
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(4,8):(1,4)">, %[[B:.+]]: !cute.layout<"(4,8):(1,4)">)
func.func @equal_layout(%a: !cute.layout<"(4,8):(1,4)">, %b: !cute.layout<"(4,8):(1,4)">) -> i1 {
  // CHECK: %[[R:.+]] = cute.equal(%[[A]], %[[B]]) : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(4,8):(1,4)">) -> i1
  %r = cute.equal(%a, %b) : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(4,8):(1,4)">) -> i1
  return %r : i1
}

// -----

// coord / coord.
// CHECK-LABEL: func.func @equal_coord
// CHECK-SAME:  (%[[A:.+]]: !cute.coord<"(3,4)">, %[[B:.+]]: !cute.coord<"(3,4)">)
func.func @equal_coord(%a: !cute.coord<"(3,4)">, %b: !cute.coord<"(3,4)">) -> i1 {
  // CHECK: %[[R:.+]] = cute.equal(%[[A]], %[[B]]) : (!cute.coord<"(3,4)">, !cute.coord<"(3,4)">) -> i1
  %r = cute.equal(%a, %b) : (!cute.coord<"(3,4)">, !cute.coord<"(3,4)">) -> i1
  return %r : i1
}

// -----

// Dynamic operands.
// CHECK-LABEL: func.func @equal_dynamic
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"(?,?)">, %[[B:.+]]: !cute.shape<"(?,?)">)
func.func @equal_dynamic(%a: !cute.shape<"(?,?)">, %b: !cute.shape<"(?,?)">) -> i1 {
  // CHECK: %[[R:.+]] = cute.equal(%[[A]], %[[B]]) : (!cute.shape<"(?,?)">, !cute.shape<"(?,?)">) -> i1
  %r = cute.equal(%a, %b) : (!cute.shape<"(?,?)">, !cute.shape<"(?,?)">) -> i1
  return %r : i1
}

// -----

// Stride / stride.
// CHECK-LABEL: func.func @equal_stride
// CHECK-SAME:  (%[[A:.+]]: !cute.stride<"(1,4)">, %[[B:.+]]: !cute.stride<"(1,4)">)
func.func @equal_stride(%a: !cute.stride<"(1,4)">, %b: !cute.stride<"(1,4)">) -> i1 {
  // CHECK: %[[R:.+]] = cute.equal(%[[A]], %[[B]]) : (!cute.stride<"(1,4)">, !cute.stride<"(1,4)">) -> i1
  %r = cute.equal(%a, %b) : (!cute.stride<"(1,4)">, !cute.stride<"(1,4)">) -> i1
  return %r : i1
}

// -----

// Nested int_tuple — recursive same-kind / same-profile equality.
// CHECK-LABEL: func.func @equal_nested
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"((?,?),?)">, %[[B:.+]]: !cute.int_tuple<"((?,?),?)">)
func.func @equal_nested(
    %a: !cute.int_tuple<"((?,?),?)">, %b: !cute.int_tuple<"((?,?),?)">) -> i1 {
  // CHECK: %[[R:.+]] = cute.equal(%[[A]], %[[B]]) : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((?,?),?)">) -> i1
  %r = cute.equal(%a, %b)
       : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((?,?),?)">) -> i1
  return %r : i1
}
