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

// Tests round-trip for cute.left_inverse.
// left_inverse(L) produces I such that I ∘ L = identity on the domain of L.

// -----

// Row-major (4,3):(3,1) → transposed left inverse (3,4):(4,1).
// CHECK-LABEL: func.func @row_major
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,3):(3,1)">)
func.func @row_major(
    %src: !cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">
  return %r : !cute.layout<"(3,4):(4,1)">
}

// -----

// Column-major (4,3):(1,4) → flat left inverse 12:1.
// CHECK-LABEL: func.func @col_major
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,3):(1,4)">)
func.func @col_major(
    %src: !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1">
  return %r : !cute.layout<"12:1">
}

// -----

// Identity layout is self-inverse: 8:1 → 8:1.
// CHECK-LABEL: func.func @scalar_identity
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"8:1">)
func.func @scalar_identity(
    %src: !cute.layout<"8:1">) -> !cute.layout<"8:1"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"8:1">) -> !cute.layout<"8:1">
  %r = cute.left_inverse(%src) : (!cute.layout<"8:1">) -> !cute.layout<"8:1">
  return %r : !cute.layout<"8:1">
}

// -----

// Broadcast layout: 4:0 → degenerate left inverse 1:0.
// CHECK-LABEL: func.func @broadcast
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"4:0">)
func.func @broadcast(
    %src: !cute.layout<"4:0">) -> !cute.layout<"1:0"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"4:0">) -> !cute.layout<"1:0">
  %r = cute.left_inverse(%src) : (!cute.layout<"4:0">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// Nested transposed: (2,4):(4,1) → (4,2):(2,1).
// CHECK-LABEL: func.func @nested_transposed
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,4):(4,1)">)
func.func @nested_transposed(
    %src: !cute.layout<"(2,4):(4,1)">) -> !cute.layout<"(4,2):(2,1)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(2,4):(4,1)">) -> !cute.layout<"(4,2):(2,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(2,4):(4,1)">) -> !cute.layout<"(4,2):(2,1)">
  return %r : !cute.layout<"(4,2):(2,1)">
}

// -----

// Hierarchical layout.
// CHECK-LABEL: func.func @nested_hierarchical
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((2,4),(3,5)):((4,1),(2,8))">)
func.func @nested_hierarchical(
    %src: !cute.layout<"((2,4),(3,5)):((4,1),(2,8))">) -> !cute.layout<"(2,2,2,5):(2,8,1,24)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"((2,4),(3,5)):((4,1),(2,8))">) -> !cute.layout<"(2,2,2,5):(2,8,1,24)">
  %r = cute.left_inverse(%src) : (!cute.layout<"((2,4),(3,5)):((4,1),(2,8))">) -> !cute.layout<"(2,2,2,5):(2,8,1,24)">
  return %r : !cute.layout<"(2,2,2,5):(2,8,1,24)">
}

// -----

// Hierarchical contiguous layout.
// CHECK-LABEL: func.func @nested_contiguous
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((2,4),3):((1,2),8)">)
func.func @nested_contiguous(
    %src: !cute.layout<"((2,4),3):((1,2),8)">) -> !cute.layout<"24:1"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"((2,4),3):((1,2),8)">) -> !cute.layout<"24:1">
  %r = cute.left_inverse(%src) : (!cute.layout<"((2,4),3):((1,2),8)">) -> !cute.layout<"24:1">
  return %r : !cute.layout<"24:1">
}

// -----

// All-scaled-basis strides.
// CHECK-LABEL: func.func @scaled_basis_strides
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3):(1@0,1@1)">)
func.func @scaled_basis_strides(
    %src: !cute.layout<"(2,3):(1@0,1@1)">) -> !cute.layout<"(2,3):(1,2)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(2,3):(1@0,1@1)">) -> !cute.layout<"(2,3):(1,2)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(2,3):(1@0,1@1)">) -> !cute.layout<"(2,3):(1,2)">
  return %r : !cute.layout<"(2,3):(1,2)">
}

// -----

// Zero integer mixed with scaled-basis.
// CHECK-LABEL: func.func @scaled_basis_zero_mixed
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3):(0,1@0)">)
func.func @scaled_basis_zero_mixed(
    %src: !cute.layout<"(2,3):(0,1@0)">) -> !cute.layout<"(3):(2)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(2,3):(0,1@0)">) -> !cute.layout<"(3):(2)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(2,3):(0,1@0)">) -> !cute.layout<"(3):(2)">
  return %r : !cute.layout<"(3):(2)">
}

// -----

// Contiguous flat layout.
// CHECK-LABEL: func.func @flat_contiguous
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,2):(1,4)">)
func.func @flat_contiguous(
    %src: !cute.layout<"(4,2):(1,4)">) -> !cute.layout<"8:1"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(4,2):(1,4)">) -> !cute.layout<"8:1">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,2):(1,4)">) -> !cute.layout<"8:1">
  return %r : !cute.layout<"8:1">
}

// -----

// Non-injective stride > 1.
// CHECK-LABEL: func.func @CG_TEST_non_injective_stride_gt_one
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"4:2">)
func.func @CG_TEST_non_injective_stride_gt_one(
    %src: !cute.layout<"4:2">) -> !cute.layout<"(2,4):(0,1)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"4:2">) -> !cute.layout<"(2,4):(0,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"4:2">) -> !cute.layout<"(2,4):(0,1)">
  return %r : !cute.layout<"(2,4):(0,1)">
}

// -----

// Sparse stride equal to size.
// CHECK-LABEL: func.func @CG_TEST_non_injective_stride_eq_size
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"4:4">)
func.func @CG_TEST_non_injective_stride_eq_size(
    %src: !cute.layout<"4:4">) -> !cute.layout<"(4,4):(0,1)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"4:4">) -> !cute.layout<"(4,4):(0,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"4:4">) -> !cute.layout<"(4,4):(0,1)">
  return %r : !cute.layout<"(4,4):(0,1)">
}

// -----

// Flat coalescing rank-2.
// CHECK-LABEL: func.func @CG_TEST_flat_coalescing_rank2
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(8,4):(1,8)">)
func.func @CG_TEST_flat_coalescing_rank2(
    %src: !cute.layout<"(8,4):(1,8)">) -> !cute.layout<"32:1"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(8,4):(1,8)">) -> !cute.layout<"32:1">
  %r = cute.left_inverse(%src) : (!cute.layout<"(8,4):(1,8)">) -> !cute.layout<"32:1">
  return %r : !cute.layout<"32:1">
}

// -----

// Weak congruence (stride > shape product).
// CHECK-LABEL: func.func @CG_TEST_weak_congruence_stride_gt_size
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,2):(1,16)">)
func.func @CG_TEST_weak_congruence_stride_gt_size(
    %src: !cute.layout<"(4,2):(1,16)">) -> !cute.layout<"(16,2):(1,4)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(4,2):(1,16)">) -> !cute.layout<"(16,2):(1,4)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,2):(1,16)">) -> !cute.layout<"(16,2):(1,4)">
  return %r : !cute.layout<"(16,2):(1,4)">
}

// -----

// Weak congruence with odd stride.
// CHECK-LABEL: func.func @CG_TEST_weak_congruence_odd_stride
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,2):(1,5)">)
func.func @CG_TEST_weak_congruence_odd_stride(
    %src: !cute.layout<"(4,2):(1,5)">) -> !cute.layout<"(5,2):(1,4)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(4,2):(1,5)">) -> !cute.layout<"(5,2):(1,4)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,2):(1,5)">) -> !cute.layout<"(5,2):(1,4)">
  return %r : !cute.layout<"(5,2):(1,4)">
}

// -----

// Mixed zero stride rank-3.
// CHECK-LABEL: func.func @CG_TEST_mixed_zero_stride_rank3
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,4,8):(32,0,2)">)
func.func @CG_TEST_mixed_zero_stride_rank3(
    %src: !cute.layout<"(2,4,8):(32,0,2)">) -> !cute.layout<"(2,16,2):(0,8,1)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(2,4,8):(32,0,2)">) -> !cute.layout<"(2,16,2):(0,8,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(2,4,8):(32,0,2)">) -> !cute.layout<"(2,16,2):(0,8,1)">
  return %r : !cute.layout<"(2,16,2):(0,8,1)">
}

// -----

// Non-monotonic stride permutation.
// CHECK-LABEL: func.func @CG_TEST_non_monotonic_permutation
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,4,6):(4,1,8)">)
func.func @CG_TEST_non_monotonic_permutation(
    %src: !cute.layout<"(2,4,6):(4,1,8)">) -> !cute.layout<"(4,2,6):(2,1,8)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(2,4,6):(4,1,8)">) -> !cute.layout<"(4,2,6):(2,1,8)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(2,4,6):(4,1,8)">) -> !cute.layout<"(4,2,6):(2,1,8)">
  return %r : !cute.layout<"(4,2,6):(2,1,8)">
}

// -----

// Basic coordinate stride.
// CHECK-LABEL: func.func @CG_TEST_coord_basic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,5):(1@0,1@1)">)
func.func @CG_TEST_coord_basic(
    %src: !cute.layout<"(4,5):(1@0,1@1)">) -> !cute.layout<"(4,5):(1,4)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(4,5):(1@0,1@1)">) -> !cute.layout<"(4,5):(1,4)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,5):(1@0,1@1)">) -> !cute.layout<"(4,5):(1,4)">
  return %r : !cute.layout<"(4,5):(1,4)">
}

// -----

// Coordinate transpose.
// CHECK-LABEL: func.func @CG_TEST_coord_transpose
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,5):(1@1,1@0)">)
func.func @CG_TEST_coord_transpose(
    %src: !cute.layout<"(4,5):(1@1,1@0)">) -> !cute.layout<"(5,4):(4,1)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(4,5):(1@1,1@0)">) -> !cute.layout<"(5,4):(4,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,5):(1@1,1@0)">) -> !cute.layout<"(5,4):(4,1)">
  return %r : !cute.layout<"(5,4):(4,1)">
}

// -----

// Scaled-basis coefficient > 1.
// CHECK-LABEL: func.func @CG_TEST_coord_sb_coefficient
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,5):(2@0,2@1)">)
func.func @CG_TEST_coord_sb_coefficient(
    %src: !cute.layout<"(4,5):(2@0,2@1)">) -> !cute.layout<"((2,4),(2,5)):((0,1),(0,4))"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(4,5):(2@0,2@1)">) -> !cute.layout<"((2,4),(2,5)):((0,1),(0,4))">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,5):(2@0,2@1)">) -> !cute.layout<"((2,4),(2,5)):((0,1),(0,4))">
  return %r : !cute.layout<"((2,4),(2,5)):((0,1),(0,4))">
}

// -----

// Mixed scaled-basis + zero stride.
// CHECK-LABEL: func.func @CG_TEST_coord_mixed_sb_zero
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,1,5):(1@0,0,1@1)">)
func.func @CG_TEST_coord_mixed_sb_zero(
    %src: !cute.layout<"(4,1,5):(1@0,0,1@1)">) -> !cute.layout<"(4,5):(1,4)"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(4,1,5):(1@0,0,1@1)">) -> !cute.layout<"(4,5):(1,4)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,1,5):(1@0,0,1@1)">) -> !cute.layout<"(4,5):(1,4)">
  return %r : !cute.layout<"(4,5):(1,4)">
}

// -----

// Deeply nested scaled-basis + zero strides.
// CHECK-LABEL: func.func @CG_TEST_coord_regression
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(((16,4),64),1,1):(((1@1,32@1),2@0),0,0)">)
func.func @CG_TEST_coord_regression(
    %src: !cute.layout<"(((16,4),64),1,1):(((1@1,32@1),2@0),0,0)">) -> !cute.layout<"((2,64),(32,4)):((0,64),(1,16))"> {
  // CHECK: %[[R:.+]] = cute.left_inverse(%[[SRC]]) : (!cute.layout<"(((16,4),64),1,1):(((1@1,32@1),2@0),0,0)">) -> !cute.layout<"((2,64),(32,4)):((0,64),(1,16))">
  %r = cute.left_inverse(%src) : (!cute.layout<"(((16,4),64),1,1):(((1@1,32@1),2@0),0,0)">) -> !cute.layout<"((2,64),(32,4)):((0,64),(1,16))">
  return %r : !cute.layout<"((2,64),(32,4)):((0,64),(1,16))">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_1_0
func.func @CG_TEST_li_1_0(%src: !cute.layout<"1:0">) -> !cute.layout<"1:0"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"1:0">) -> !cute.layout<"1:0">
  %r = cute.left_inverse(%src) : (!cute.layout<"1:0">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_1_1
func.func @CG_TEST_li_1_1(%src: !cute.layout<"1:1">) -> !cute.layout<"1:0"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"1:1">) -> !cute.layout<"1:0">
  %r = cute.left_inverse(%src) : (!cute.layout<"1:1">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_1_2
func.func @CG_TEST_li_1_2(%src: !cute.layout<"1:2">) -> !cute.layout<"1:0"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"1:2">) -> !cute.layout<"1:0">
  %r = cute.left_inverse(%src) : (!cute.layout<"1:2">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_1_4
func.func @CG_TEST_li_1_4(%src: !cute.layout<"1:4">) -> !cute.layout<"1:0"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"1:4">) -> !cute.layout<"1:0">
  %r = cute.left_inverse(%src) : (!cute.layout<"1:4">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_1_1_0_0
func.func @CG_TEST_li_1_1_0_0(%src: !cute.layout<"(1,1):(0,0)">) -> !cute.layout<"1:0"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(1,1):(0,0)">) -> !cute.layout<"1:0">
  %r = cute.left_inverse(%src) : (!cute.layout<"(1,1):(0,0)">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_3_7_0_0
func.func @CG_TEST_li_3_7_0_0(%src: !cute.layout<"(3,7):(0,0)">) -> !cute.layout<"1:0"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(3,7):(0,0)">) -> !cute.layout<"1:0">
  %r = cute.left_inverse(%src) : (!cute.layout<"(3,7):(0,0)">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_4_1
func.func @CG_TEST_li_4_1(%src: !cute.layout<"4:1">) -> !cute.layout<"4:1"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"4:1">) -> !cute.layout<"4:1">
  %r = cute.left_inverse(%src) : (!cute.layout<"4:1">) -> !cute.layout<"4:1">
  return %r : !cute.layout<"4:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_2_4_6_flat
func.func @CG_TEST_li_2_4_6_flat(%src: !cute.layout<"(2,4,6):(1,2,8)">) -> !cute.layout<"48:1"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(2,4,6):(1,2,8)">) -> !cute.layout<"48:1">
  %r = cute.left_inverse(%src) : (!cute.layout<"(2,4,6):(1,2,8)">) -> !cute.layout<"48:1">
  return %r : !cute.layout<"48:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_2_4_8_2_0_32
func.func @CG_TEST_li_2_4_8_2_0_32(%src: !cute.layout<"(2,4,8):(2,0,32)">) -> !cute.layout<"(2,16,8):(0,1,8)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(2,4,8):(2,0,32)">) -> !cute.layout<"(2,16,8):(0,1,8)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(2,4,8):(2,0,32)">) -> !cute.layout<"(2,16,8):(0,1,8)">
  return %r : !cute.layout<"(2,16,8):(0,1,8)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_rank5_mixed_zero
func.func @CG_TEST_li_rank5_mixed_zero(%src: !cute.layout<"(2,4,4,4,2):(32,0,2,0,512)">) -> !cute.layout<"(2,16,16,2):(0,8,1,128)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(2,4,4,4,2):(32,0,2,0,512)">) -> !cute.layout<"(2,16,16,2):(0,8,1,128)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(2,4,4,4,2):(32,0,2,0,512)">) -> !cute.layout<"(2,16,16,2):(0,8,1,128)">
  return %r : !cute.layout<"(2,16,16,2):(0,8,1,128)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_4_2_1_10
func.func @CG_TEST_li_4_2_1_10(%src: !cute.layout<"(4,2):(1,10)">) -> !cute.layout<"(10,2):(1,4)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(4,2):(1,10)">) -> !cute.layout<"(10,2):(1,4)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,2):(1,10)">) -> !cute.layout<"(10,2):(1,4)">
  return %r : !cute.layout<"(10,2):(1,4)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_4_2_1_11
func.func @CG_TEST_li_4_2_1_11(%src: !cute.layout<"(4,2):(1,11)">) -> !cute.layout<"(11,2):(1,4)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(4,2):(1,11)">) -> !cute.layout<"(11,2):(1,4)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,2):(1,11)">) -> !cute.layout<"(11,2):(1,4)">
  return %r : !cute.layout<"(11,2):(1,4)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_32_8_65536_1
func.func @CG_TEST_li_32_8_65536_1(%src: !cute.layout<"(32,8):(65536,1)">) -> !cute.layout<"(65536,32):(32,1)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(32,8):(65536,1)">) -> !cute.layout<"(65536,32):(32,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(32,8):(65536,1)">) -> !cute.layout<"(65536,32):(32,1)">
  return %r : !cute.layout<"(65536,32):(32,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_32_12_65536_1
func.func @CG_TEST_li_32_12_65536_1(%src: !cute.layout<"(32,12):(65536,1)">) -> !cute.layout<"(65536,32):(32,1)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(32,12):(65536,1)">) -> !cute.layout<"(65536,32):(32,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(32,12):(65536,1)">) -> !cute.layout<"(65536,32):(32,1)">
  return %r : !cute.layout<"(65536,32):(32,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_32_3_8_65536_512_1
func.func @CG_TEST_li_32_3_8_65536_512_1(%src: !cute.layout<"(32,3,8):(65536,512,1)">) -> !cute.layout<"(512,128,32):(96,32,1)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(32,3,8):(65536,512,1)">) -> !cute.layout<"(512,128,32):(96,32,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(32,3,8):(65536,512,1)">) -> !cute.layout<"(512,128,32):(96,32,1)">
  return %r : !cute.layout<"(512,128,32):(96,32,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_32_8_131072_2
func.func @CG_TEST_li_32_8_131072_2(%src: !cute.layout<"(32,8):(131072,2)">) -> !cute.layout<"(2,65536,32):(0,32,1)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(32,8):(131072,2)">) -> !cute.layout<"(2,65536,32):(0,32,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(32,8):(131072,2)">) -> !cute.layout<"(2,65536,32):(0,32,1)">
  return %r : !cute.layout<"(2,65536,32):(0,32,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_deeply_nested
func.func @CG_TEST_li_deeply_nested(%src: !cute.layout<"(((((2,4),1),(2,2)),4),1,(2,2),2):(((((262144,4),0),(0,1)),8388608),0,(2,16),32)">) -> !cute.layout<"(2,2,4,16384,128):(16,128,2,256,1)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(((((2,4),1),(2,2)),4),1,(2,2),2):(((((262144,4),0),(0,1)),8388608),0,(2,16),32)">) -> !cute.layout<"(2,2,4,16384,128):(16,128,2,256,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(((((2,4),1),(2,2)),4),1,(2,2),2):(((((262144,4),0),(0,1)),8388608),0,(2,16),32)">) -> !cute.layout<"(2,2,4,16384,128):(16,128,2,256,1)">
  return %r : !cute.layout<"(2,2,4,16384,128):(16,128,2,256,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_128_160_65536_1
func.func @CG_TEST_li_128_160_65536_1(%src: !cute.layout<"(128,160):(65536,1)">) -> !cute.layout<"(65536,128):(128,1)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(128,160):(65536,1)">) -> !cute.layout<"(65536,128):(128,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(128,160):(65536,1)">) -> !cute.layout<"(65536,128):(128,1)">
  return %r : !cute.layout<"(65536,128):(128,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_128_3_160_65536_512_1
func.func @CG_TEST_li_128_3_160_65536_512_1(%src: !cute.layout<"(128,3,160):(65536,512,1)">) -> !cute.layout<"(512,128,128):(384,128,1)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(128,3,160):(65536,512,1)">) -> !cute.layout<"(512,128,128):(384,128,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(128,3,160):(65536,512,1)">) -> !cute.layout<"(512,128,128):(384,128,1)">
  return %r : !cute.layout<"(512,128,128):(384,128,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_li_128_64_131072_2
func.func @CG_TEST_li_128_64_131072_2(%src: !cute.layout<"(128,64):(131072,2)">) -> !cute.layout<"(2,65536,128):(0,128,1)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(128,64):(131072,2)">) -> !cute.layout<"(2,65536,128):(0,128,1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"(128,64):(131072,2)">) -> !cute.layout<"(2,65536,128):(0,128,1)">
  return %r : !cute.layout<"(2,65536,128):(0,128,1)">
}

// -----

// Nested scaled-basis with mixed depth.
// CHECK-LABEL: func.func @CG_TEST_li_coord_nested_basis
func.func @CG_TEST_li_coord_nested_basis(%src: !cute.layout<"(4,5):(1@1,1@1@4)">) -> !cute.layout<"(1,4,1,1,(1,5)):(0,1,0,0,(0,4))"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"(4,5):(1@1,1@1@4)">) -> !cute.layout<"(1,4,1,1,(1,5)):(0,1,0,0,(0,4))">
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,5):(1@1,1@1@4)">) -> !cute.layout<"(1,4,1,1,(1,5)):(0,1,0,0,(0,4))">
  return %r : !cute.layout<"(1,4,1,1,(1,5)):(0,1,0,0,(0,4))">
}

// -----

// Rank-2 outer with two rank-3 inner modes.
// Scaled-basis strides cross-mixed between basis 0 and 1, coefficients 1/2/4.
// CHECK-LABEL: func.func @CG_TEST_li_nested_3_3_sb_coef124
func.func @CG_TEST_li_nested_3_3_sb_coef124(
    %src: !cute.layout<"((2,2,2),(2,2,2)):((1@0,2@1,4@0),(1@1,2@0,4@1))">)
    -> !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"((2,2,2),(2,2,2)):((1@0,2@1,4@0),(1@1,2@0,4@1))">) -> !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">
  %r = cute.left_inverse(%src) : (!cute.layout<"((2,2,2),(2,2,2)):((1@0,2@1,4@0),(1@1,2@0,4@1))">) -> !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">
  return %r : !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">
}

// -----

// Same outer/inner shapes, coefficient 6 (not power-of-2
// aligned).
// CHECK-LABEL: func.func @CG_TEST_li_nested_3_3_sb_coef126_symmetric
func.func @CG_TEST_li_nested_3_3_sb_coef126_symmetric(
    %src: !cute.layout<"((2,2,2),(2,2,2)):((1@0,2@1,6@0),(1@1,2@0,6@1))">)
    -> !cute.layout<"((2,3,2),(2,3,2)):((1,16,4),(8,2,32))"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"((2,2,2),(2,2,2)):((1@0,2@1,6@0),(1@1,2@0,6@1))">) -> !cute.layout<"((2,3,2),(2,3,2)):((1,16,4),(8,2,32))">
  %r = cute.left_inverse(%src) : (!cute.layout<"((2,2,2),(2,2,2)):((1@0,2@1,6@0),(1@1,2@0,6@1))">) -> !cute.layout<"((2,3,2),(2,3,2)):((1,16,4),(8,2,32))">
  return %r : !cute.layout<"((2,3,2),(2,3,2)):((1,16,4),(8,2,32))">
}

// -----

// Same shape, mixed coefficients 6/4 across modes.
// CHECK-LABEL: func.func @CG_TEST_li_nested_3_3_sb_coef126_asymmetric
func.func @CG_TEST_li_nested_3_3_sb_coef126_asymmetric(
    %src: !cute.layout<"((2,2,2),(2,2,2)):((1@0,2@1,6@0),(1@1,2@0,4@1))">)
    -> !cute.layout<"((2,3,2),(2,2,2)):((1,16,4),(8,2,32))"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"((2,2,2),(2,2,2)):((1@0,2@1,6@0),(1@1,2@0,4@1))">) -> !cute.layout<"((2,3,2),(2,2,2)):((1,16,4),(8,2,32))">
  %r = cute.left_inverse(%src) : (!cute.layout<"((2,2,2),(2,2,2)):((1@0,2@1,6@0),(1@1,2@0,4@1))">) -> !cute.layout<"((2,3,2),(2,2,2)):((1,16,4),(8,2,32))">
  return %r : !cute.layout<"((2,3,2),(2,2,2)):((1,16,4),(8,2,32))">
}

// -----

// Rank-2 outer with nested rank-2 first mode and
// flat second mode; scaled-basis strides cross-mixed (basis 0/1).
// CHECK-LABEL: func.func @CG_TEST_li_nested_rank2_flat_sb_mixed
func.func @CG_TEST_li_nested_rank2_flat_sb_mixed(
    %src: !cute.layout<"((4,2),4):((1@1,4@0),1@0)">)
    -> !cute.layout<"((4,2),4):((8,4),1)"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"((4,2),4):((1@1,4@0),1@0)">) -> !cute.layout<"((4,2),4):((8,4),1)">
  %r = cute.left_inverse(%src) : (!cute.layout<"((4,2),4):((1@1,4@0),1@0)">) -> !cute.layout<"((4,2),4):((8,4),1)">
  return %r : !cute.layout<"((4,2),4):((8,4),1)">
}

// -----

// Rank-2 outer with two nested rank-2 inner modes.
// Scaled-basis strides cross-mixed with coefficient 2 / 8.
// CHECK-LABEL: func.func @CG_TEST_li_nested_rank2_rank2_sb_mixed
func.func @CG_TEST_li_nested_rank2_rank2_sb_mixed(
    %src: !cute.layout<"((4,8),(2,2)):((2@1,1@0),(1@1,8@0))">)
    -> !cute.layout<"((8,2),(2,4)):((4,64),(32,1))"> {
  // CHECK: cute.left_inverse(%{{.+}}) : (!cute.layout<"((4,8),(2,2)):((2@1,1@0),(1@1,8@0))">) -> !cute.layout<"((8,2),(2,4)):((4,64),(32,1))">
  %r = cute.left_inverse(%src) : (!cute.layout<"((4,8),(2,2)):((2@1,1@0),(1@1,8@0))">) -> !cute.layout<"((8,2),(2,4)):((4,64),(32,1))">
  return %r : !cute.layout<"((8,2),(2,4)):((4,64),(32,1))">
}
