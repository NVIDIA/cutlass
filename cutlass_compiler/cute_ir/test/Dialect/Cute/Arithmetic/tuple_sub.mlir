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
// Tests round-trip for cute.tuple_sub.
// -----
// Static int_tuple: element-wise subtraction.
// CHECK-LABEL: func.func @sub_int_tuple_static
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(5,8)">, %[[B:.+]]: !cute.int_tuple<"(1,2)">)
func.func @sub_int_tuple_static(%a: !cute.int_tuple<"(5,8)">, %b: !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(4,6)"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]]) : (!cute.int_tuple<"(5,8)">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(4,6)">
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"(5,8)">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(4,6)">
  return %r : !cute.int_tuple<"(4,6)">
}
// -----
// Dynamic int_tuple: result is dynamic.
// CHECK-LABEL: func.func @sub_int_tuple_dynamic
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(?,?)">, %[[B:.+]]: !cute.int_tuple<"(?,?)">)
func.func @sub_int_tuple_dynamic(%a: !cute.int_tuple<"(?,?)">, %b: !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]]) : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}
// -----
// Shape variant.
// CHECK-LABEL: func.func @sub_shape_static
// CHECK-SAME:  (%[[A:.+]]: !cute.shape<"(5,8)">, %[[B:.+]]: !cute.shape<"(1,2)">)
func.func @sub_shape_static(%a: !cute.shape<"(5,8)">, %b: !cute.shape<"(1,2)">) -> !cute.shape<"(4,6)"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]]) : (!cute.shape<"(5,8)">, !cute.shape<"(1,2)">) -> !cute.shape<"(4,6)">
  %r = cute.tuple_sub(%a, %b) : (!cute.shape<"(5,8)">, !cute.shape<"(1,2)">) -> !cute.shape<"(4,6)">
  return %r : !cute.shape<"(4,6)">
}
// -----
// Rank mismatch — lhs has more elements: extra lhs elements pass through.
// CHECK-LABEL: func.func @sub_rank_mismatch_lhs_longer
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(5,8,3)">, %[[B:.+]]: !cute.int_tuple<"(1,2)">)
func.func @sub_rank_mismatch_lhs_longer(%a: !cute.int_tuple<"(5,8,3)">, %b: !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(4,6,3)"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]]) : (!cute.int_tuple<"(5,8,3)">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(4,6,3)">
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"(5,8,3)">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(4,6,3)">
  return %r : !cute.int_tuple<"(4,6,3)">
}
// -----
// Rank mismatch — rhs has more elements: extra rhs elements pass through.
// CHECK-LABEL: func.func @sub_rank_mismatch_rhs_longer
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(10,8)">, %[[B:.+]]: !cute.int_tuple<"(3,2,5)">)
func.func @sub_rank_mismatch_rhs_longer(%a: !cute.int_tuple<"(10,8)">, %b: !cute.int_tuple<"(3,2,5)">) -> !cute.int_tuple<"(7,6,5)"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]]) : (!cute.int_tuple<"(10,8)">, !cute.int_tuple<"(3,2,5)">) -> !cute.int_tuple<"(7,6,5)">
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"(10,8)">, !cute.int_tuple<"(3,2,5)">) -> !cute.int_tuple<"(7,6,5)">
  return %r : !cute.int_tuple<"(7,6,5)">
}
// -----
// Rank mismatch with nested extra mode — lhs has an extra sub-tuple.
// CHECK-LABEL: func.func @sub_rank_mismatch_lhs_extra_nested
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"((5,8),(3,4),(1,2))">, %[[B:.+]]: !cute.int_tuple<"((1,2),(1,1))">)
func.func @sub_rank_mismatch_lhs_extra_nested(%a: !cute.int_tuple<"((5,8),(3,4),(1,2))">, %b: !cute.int_tuple<"((1,2),(1,1))">) -> !cute.int_tuple<"((4,6),(2,3),(1,2))"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]]) : (!cute.int_tuple<"((5,8),(3,4),(1,2))">, !cute.int_tuple<"((1,2),(1,1))">) -> !cute.int_tuple<"((4,6),(2,3),(1,2))">
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"((5,8),(3,4),(1,2))">, !cute.int_tuple<"((1,2),(1,1))">) -> !cute.int_tuple<"((4,6),(2,3),(1,2))">
  return %r : !cute.int_tuple<"((4,6),(2,3),(1,2))">
}
// -----
// Rank mismatch with nested extra mode — rhs has an extra sub-tuple.
// CHECK-LABEL: func.func @sub_rank_mismatch_rhs_extra_nested
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"((5,8),(3,4))">, %[[B:.+]]: !cute.int_tuple<"((1,2),(1,1),(0,1))">)
func.func @sub_rank_mismatch_rhs_extra_nested(%a: !cute.int_tuple<"((5,8),(3,4))">, %b: !cute.int_tuple<"((1,2),(1,1),(0,1))">) -> !cute.int_tuple<"((4,6),(2,3),(0,1))"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]]) : (!cute.int_tuple<"((5,8),(3,4))">, !cute.int_tuple<"((1,2),(1,1),(0,1))">) -> !cute.int_tuple<"((4,6),(2,3),(0,1))">
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"((5,8),(3,4))">, !cute.int_tuple<"((1,2),(1,1),(0,1))">) -> !cute.int_tuple<"((4,6),(2,3),(0,1))">
  return %r : !cute.int_tuple<"((4,6),(2,3),(0,1))">
}
// -----
// Inner rank mismatch — rhs sub-tuple at position 1 has an extra element.
// CHECK-LABEL: func.func @sub_inner_rank_mismatch_rhs_deeper
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"((5,8),(3,4))">, %[[B:.+]]: !cute.int_tuple<"((1,2),(1,1,1))">)
func.func @sub_inner_rank_mismatch_rhs_deeper(%a: !cute.int_tuple<"((5,8),(3,4))">, %b: !cute.int_tuple<"((1,2),(1,1,1))">) -> !cute.int_tuple<"((4,6),(2,3,1))"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]]) : (!cute.int_tuple<"((5,8),(3,4))">, !cute.int_tuple<"((1,2),(1,1,1))">) -> !cute.int_tuple<"((4,6),(2,3,1))">
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"((5,8),(3,4))">, !cute.int_tuple<"((1,2),(1,1,1))">) -> !cute.int_tuple<"((4,6),(2,3,1))">
  return %r : !cute.int_tuple<"((4,6),(2,3,1))">
}
// -----
// Zero-scalar rhs identity: (x,...) - 0 = (x,...).
// CHECK-LABEL: func.func @sub_rhs_zero_identity
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(5,8)">, %[[B:.+]]: !cute.int_tuple<"0">)
func.func @sub_rhs_zero_identity(%a: !cute.int_tuple<"(5,8)">, %b: !cute.int_tuple<"0">) -> !cute.int_tuple<"(5,8)"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]]) : (!cute.int_tuple<"(5,8)">, !cute.int_tuple<"0">) -> !cute.int_tuple<"(5,8)">
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"(5,8)">, !cute.int_tuple<"0">) -> !cute.int_tuple<"(5,8)">
  return %r : !cute.int_tuple<"(5,8)">
}
// -----
// Zero identity preserves dyn structure: (?,?) - 0 = (?,?).
// CHECK-LABEL: func.func @sub_zero_preserves_dyn
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(?,?)">, %[[B:.+]]: !cute.int_tuple<"0">)
func.func @sub_zero_preserves_dyn(%a: !cute.int_tuple<"(?,?)">, %b: !cute.int_tuple<"0">) -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]]) : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"0">) -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_sub(%a, %b) : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"0">) -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}
// -----
// Zero identity, multi-line CHECK form mirroring the operand split
// across two lines.
// CHECK-LABEL: func.func @sub_zero_preserves_dyn_multiline
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(?,?)">, %[[B:.+]]: !cute.int_tuple<"0">)
func.func @sub_zero_preserves_dyn_multiline(
    %a: !cute.int_tuple<"(?,?)">,
    %b: !cute.int_tuple<"0">)
    -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]])
  // CHECK-SAME: -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"0">)
      -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}
// -----
// Both sides fully dynamic — result mirrors the per-leaf
// dynamic-leaf shape.
// CHECK-LABEL: func.func @sub_both_dynamic
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(?,?)">, %[[B:.+]]: !cute.int_tuple<"(?,?)">)
func.func @sub_both_dynamic(
    %a: !cute.int_tuple<"(?,?)">,
    %b: !cute.int_tuple<"(?,?)">)
    -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]])
  // CHECK-SAME: -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"(?,?)">,
          !cute.int_tuple<"(?,?)">)
      -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}
// -----
// Dynamic / static.
// CHECK-LABEL: func.func @sub_dyn_static
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(?,?)">, %[[B:.+]]: !cute.int_tuple<"(?,?)">)
func.func @sub_dyn_static(
    %a: !cute.int_tuple<"(?,?)">,
    %b: !cute.int_tuple<"(?,?)">)
    -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]])
  // CHECK-SAME: -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"(?,?)">,
          !cute.int_tuple<"(?,?)">)
      -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}
// -----
// Static rhs leaf acts as `` against a dyn lhs with hint.
// CHECK-LABEL: func.func @sub_dyn_static_rhs
// CHECK-SAME:  (%[[A:.+]]: !cute.int_tuple<"(?,?)">, %[[B:.+]]: !cute.int_tuple<"(6,2)">)
func.func @sub_dyn_static_rhs(
    %a: !cute.int_tuple<"(?,?)">,
    %b: !cute.int_tuple<"(6,2)">)
    -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.tuple_sub(%[[A]], %[[B]])
  // CHECK-SAME: -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(6,2)">)
      -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}
