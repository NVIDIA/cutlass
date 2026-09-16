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

// Tests round-trip for cute.idx2crd.

// -----

// Static index: coord is fully resolved at compile time.
// CHECK-LABEL: func.func @idx2crd_static
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"9">, %[[S:.+]]: !cute.shape<"(4,8)">)
func.func @idx2crd_static(%idx: !cute.int_tuple<"9">, %s: !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)">
  return %r : !cute.coord<"(1,2)">
}

// -----

// Dynamic index: result coord has the same profile as the shape but dynamic values.
// CHECK-LABEL: func.func @idx2crd_dynamic
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"?">, %[[S:.+]]: !cute.shape<"(4,8)">)
func.func @idx2crd_dynamic(%idx: !cute.int_tuple<"?">, %s: !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"?">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"?">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// Scalar (rank-1) shape: scalar coord equals the index value.
// CHECK-LABEL: func.func @idx2crd_scalar_shape
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"3">, %[[S:.+]]: !cute.shape<"5">)
func.func @idx2crd_scalar_shape(%idx: !cute.int_tuple<"3">, %s: !cute.shape<"5">) -> !cute.coord<"3"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"3">, !cute.shape<"5">) -> !cute.coord<"3">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"3">, !cute.shape<"5">) -> !cute.coord<"3">
  return %r : !cute.coord<"3">
}

// -----

// Nested shape, static index.
// CHECK-LABEL: func.func @idx2crd_nested_shape_static
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"5">, %[[S:.+]]: !cute.shape<"(4,(2,3))">)
func.func @idx2crd_nested_shape_static(%idx: !cute.int_tuple<"5">, %s: !cute.shape<"(4,(2,3))">) -> !cute.coord<"(1,(1,0))"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"5">, !cute.shape<"(4,(2,3))">) -> !cute.coord<"(1,(1,0))">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"5">, !cute.shape<"(4,(2,3))">) -> !cute.coord<"(1,(1,0))">
  return %r : !cute.coord<"(1,(1,0))">
}

// -----

// Nested shape, dynamic index.
// CHECK-LABEL: func.func @idx2crd_nested_shape_dynamic
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"?">, %[[S:.+]]: !cute.shape<"(4,(2,3))">)
func.func @idx2crd_nested_shape_dynamic(%idx: !cute.int_tuple<"?">, %s: !cute.shape<"(4,(2,3))">) -> !cute.coord<"(?,(?,?))"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"?">, !cute.shape<"(4,(2,3))">) -> !cute.coord<"(?,(?,?))">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"?">, !cute.shape<"(4,(2,3))">) -> !cute.coord<"(?,(?,?))">
  return %r : !cute.coord<"(?,(?,?))">
}

// -----

// Multi-element index whose rank matches shape rank.
// CHECK-LABEL: func.func @idx2crd_tuple_index
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"(1,2)">, %[[S:.+]]: !cute.shape<"(4,8)">)
func.func @idx2crd_tuple_index(%idx: !cute.int_tuple<"(1,2)">, %s: !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)">
  return %r : !cute.coord<"(1,2)">
}

// -----

// Nested int_tuple index whose profile matches a nested shape: passthrough.
// CHECK-LABEL: func.func @idx2crd_nested_tuple_index
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"(1,(0,1))">, %[[S:.+]]: !cute.shape<"(4,(2,3))">)
func.func @idx2crd_nested_tuple_index(%idx: !cute.int_tuple<"(1,(0,1))">, %s: !cute.shape<"(4,(2,3))">) -> !cute.coord<"(1,(0,1))"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"(1,(0,1))">, !cute.shape<"(4,(2,3))">) -> !cute.coord<"(1,(0,1))">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"(1,(0,1))">, !cute.shape<"(4,(2,3))">) -> !cute.coord<"(1,(0,1))">
  return %r : !cute.coord<"(1,(0,1))">
}

// -----

// Empty shape `()`.
// CHECK-LABEL: func.func @idx2crd_empty_shape
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"0">, %[[S:.+]]: !cute.shape<"()">)
func.func @idx2crd_empty_shape(%idx: !cute.int_tuple<"0">, %s: !cute.shape<"()">) -> !cute.coord<"()"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"0">, !cute.shape<"()">) -> !cute.coord<"()">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"0">, !cute.shape<"()">) -> !cute.coord<"()">
  return %r : !cute.coord<"()">
}

// -----

// Mixed static / dynamic shape extents.
// CHECK-LABEL: func.func @idx2crd_mixed_extents
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"9">, %[[S:.+]]: !cute.shape<"(4,?)">)
func.func @idx2crd_mixed_extents(%idx: !cute.int_tuple<"9">, %s: !cute.shape<"(4,?)">) -> !cute.coord<"(1,2)"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"9">, !cute.shape<"(4,?)">) -> !cute.coord<"(1,2)">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"9">, !cute.shape<"(4,?)">) -> !cute.coord<"(1,2)">
  return %r : !cute.coord<"(1,2)">
}

// -----

// dynamic tuple index matching shape rank.
// CHECK-LABEL: func.func @idx2crd_tuple_dyn
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"(?,?)">, %[[S:.+]]: !cute.shape<"(4,2)">)
func.func @idx2crd_tuple_dyn(%idx: !cute.int_tuple<"(?,?)">, %s: !cute.shape<"(4,2)">) -> !cute.coord<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"(?,?)">, !cute.shape<"(4,2)">) -> !cute.coord<"(?,?)">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"(?,?)">, !cute.shape<"(4,2)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// dynamic index + fully-dynamic nested shape.
// CHECK-LABEL: func.func @idx2crd_nested_dyn
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"?">, %[[S:.+]]: !cute.shape<"(?,(?,?))">)
func.func @idx2crd_nested_dyn(%idx: !cute.int_tuple<"?">, %s: !cute.shape<"(?,(?,?))">) -> !cute.coord<"(?,(?,?))"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"?">, !cute.shape<"(?,(?,?))">) -> !cute.coord<"(?,(?,?))">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"?">, !cute.shape<"(?,(?,?))">) -> !cute.coord<"(?,(?,?))">
  return %r : !cute.coord<"(?,(?,?))">
}

// -----

// rank-1-wrapped single-dimension shape `(10)`.
// CHECK-LABEL: func.func @idx2crd_single_dim
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"?">, %[[S:.+]]: !cute.shape<"(10)">)
func.func @idx2crd_single_dim(%idx: !cute.int_tuple<"?">, %s: !cute.shape<"(10)">) -> !cute.coord<"(?)"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"?">, !cute.shape<"(10)">) -> !cute.coord<"(?)">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"?">, !cute.shape<"(10)">) -> !cute.coord<"(?)">
  return %r : !cute.coord<"(?)">
}

// -----

// dynamic nested tuple index matching dynamic nested shape.
// CHECK-LABEL: func.func @idx2crd_nested_tuple_dyn
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"(?,(?,?))">, %[[S:.+]]: !cute.shape<"(?,(?,?))">)
func.func @idx2crd_nested_tuple_dyn(%idx: !cute.int_tuple<"(?,(?,?))">, %s: !cute.shape<"(?,(?,?))">) -> !cute.coord<"(?,(?,?))"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"(?,(?,?))">, !cute.shape<"(?,(?,?))">) -> !cute.coord<"(?,(?,?))">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"(?,(?,?))">, !cute.shape<"(?,(?,?))">) -> !cute.coord<"(?,(?,?))">
  return %r : !cute.coord<"(?,(?,?))">
}

// -----

// dynamic index + mixed static/dyn shape.
// CHECK-LABEL: func.func @idx2crd_mixed_dyn
// CHECK-SAME:  (%[[IDX:.+]]: !cute.int_tuple<"?">, %[[S:.+]]: !cute.shape<"(4,?)">)
func.func @idx2crd_mixed_dyn(%idx: !cute.int_tuple<"?">, %s: !cute.shape<"(4,?)">) -> !cute.coord<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.idx2crd(%[[IDX]], %[[S]]) : (!cute.int_tuple<"?">, !cute.shape<"(4,?)">) -> !cute.coord<"(?,?)">
  %r = cute.idx2crd(%idx, %s) : (!cute.int_tuple<"?">, !cute.shape<"(4,?)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}
