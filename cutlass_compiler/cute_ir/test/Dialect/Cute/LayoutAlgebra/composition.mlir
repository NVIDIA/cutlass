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

// Tests round-trip for cute.composition.

// -----

// Layout ∘ layout.
// CHECK-LABEL: func.func @layout_layout_static
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(20):(2)">, %[[INNER:.+]]: !cute.layout<"(5,4):(4,1)">)
func.func @layout_layout_static(
    %outer: !cute.layout<"(20):(2)">,
    %inner: !cute.layout<"(5,4):(4,1)">) -> !cute.layout<"(5,4):(8,2)"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(20):(2)">, !cute.layout<"(5,4):(4,1)">) -> !cute.layout<"(5,4):(8,2)">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(20):(2)">, !cute.layout<"(5,4):(4,1)">)
        -> !cute.layout<"(5,4):(8,2)">
  return %r : !cute.layout<"(5,4):(8,2)">
}

// -----

// Layout ∘ shape.
// CHECK-LABEL: func.func @layout_shape_static
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(4,8):(1,4)">, %[[INNER:.+]]: !cute.shape<"(2,4)">)
func.func @layout_shape_static(
    %outer: !cute.layout<"(4,8):(1,4)">,
    %inner: !cute.shape<"(2,4)">) -> !cute.layout<"(2,4):(1,4)"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(4,8):(1,4)">, !cute.shape<"(2,4)">) -> !cute.layout<"(2,4):(1,4)">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,8):(1,4)">, !cute.shape<"(2,4)">)
        -> !cute.layout<"(2,4):(1,4)">
  return %r : !cute.layout<"(2,4):(1,4)">
}

// -----

// Layout ∘ layout (different strides).
// CHECK-LABEL: func.func @layout_layout_strided
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(4,8):(1,4)">, %[[INNER:.+]]: !cute.layout<"(2,4):(1,2)">)
func.func @layout_layout_strided(
    %outer: !cute.layout<"(4,8):(1,4)">,
    %inner: !cute.layout<"(2,4):(1,2)">) -> !cute.layout<"(2,4):(1,2)"> {
  // CHECK: cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,4):(1,2)">) -> !cute.layout<"(2,4):(1,2)">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,4):(1,2)">)
        -> !cute.layout<"(2,4):(1,2)">
  return %r : !cute.layout<"(2,4):(1,2)">
}

// -----

// Composed layout ∘ layout.
// CHECK-LABEL: func.func @composed_layout_layout
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
// CHECK-SAME:   %[[INNER:.+]]: !cute.layout<"(2,3):(1,2)">)
func.func @composed_layout_layout(
    %outer: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
    %inner: !cute.layout<"(2,3):(1,2)">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)"> {
  // CHECK: cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  %r = cute.composition(%outer, %inner)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">, !cute.layout<"(2,3):(1,2)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
}

// -----

// Layout ∘ tile.
// in hierarchical (wrapped) form.
// CHECK-LABEL: func.func @layout_tile_static
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(4,8):(1,4)">, %[[INNER:.+]]: !cute.tile<"[(2,4):(1,2)]">)
func.func @layout_tile_static(
    %outer: !cute.layout<"(4,8):(1,4)">,
    %inner: !cute.tile<"[(2,4):(1,2)]">) -> !cute.layout<"((2,4)):((1,2))"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(4,8):(1,4)">, !cute.tile<"[(2,4):(1,2)]">) -> !cute.layout<"((2,4)):((1,2))">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,8):(1,4)">, !cute.tile<"[(2,4):(1,2)]">)
        -> !cute.layout<"((2,4)):((1,2))">
  return %r : !cute.layout<"((2,4)):((1,2))">
}

// -----

// Composed layout ∘ shape.
// CHECK-LABEL: func.func @composed_layout_shape
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
// CHECK-SAME:   %[[INNER:.+]]: !cute.shape<"(2,3)">)
func.func @composed_layout_shape(
    %outer: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
    %inner: !cute.shape<"(2,3)">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">, !cute.shape<"(2,3)">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  %r = cute.composition(%outer, %inner)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">, !cute.shape<"(2,3)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
}

// -----

// Composed layout ∘ tile.
// CHECK-LABEL: func.func @composed_layout_tile
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
// CHECK-SAME:   %[[INNER:.+]]: !cute.tile<"[(2,3):(1,2)]">)
func.func @composed_layout_tile(
    %outer: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
    %inner: !cute.tile<"[(2,3):(1,2)]">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((2,3)):((1,2))"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">, !cute.tile<"[(2,3):(1,2)]">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((2,3)):((1,2))">
  %r = cute.composition(%outer, %inner)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">, !cute.tile<"[(2,3):(1,2)]">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((2,3)):((1,2))">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o ((2,3)):((1,2))">
}

// -----

// Dynamic inner stride.
// CHECK-LABEL: func.func @layout_layout_dyn_inner_stride
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(4,8):(1,4)">, %[[INNER:.+]]: !cute.layout<"(2,4):(1,?)">)
func.func @layout_layout_dyn_inner_stride(
    %outer: !cute.layout<"(4,8):(1,4)">,
    %inner: !cute.layout<"(2,4):(1,?)">) -> !cute.layout<"(2,4):(1,?)"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,4):(1,?)">) -> !cute.layout<"(2,4):(1,?)">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,4):(1,?)">)
        -> !cute.layout<"(2,4):(1,?)">
  return %r : !cute.layout<"(2,4):(1,?)">
}

// -----

// Dynamic inner shape.
// CHECK-LABEL: func.func @layout_layout_dyn_inner_shape
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(20):(2)">, %[[INNER:.+]]: !cute.layout<"(?,4):(4,1)">)
func.func @layout_layout_dyn_inner_shape(
    %outer: !cute.layout<"(20):(2)">,
    %inner: !cute.layout<"(?,4):(4,1)">) -> !cute.layout<"(?,4):(8,2)"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(20):(2)">, !cute.layout<"(?,4):(4,1)">) -> !cute.layout<"(?,4):(8,2)">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(20):(2)">, !cute.layout<"(?,4):(4,1)">)
        -> !cute.layout<"(?,4):(8,2)">
  return %r : !cute.layout<"(?,4):(8,2)">
}

// -----

// Fully dynamic inner.
// CHECK-LABEL: func.func @layout_layout_dyn_all
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(8):(2)">, %[[INNER:.+]]: !cute.layout<"(?):(?)">)
func.func @layout_layout_dyn_all(
    %outer: !cute.layout<"(8):(2)">,
    %inner: !cute.layout<"(?):(?)">) -> !cute.layout<"(?):(?)"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(8):(2)">, !cute.layout<"(?):(?)">) -> !cute.layout<"(?):(?)">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(8):(2)">, !cute.layout<"(?):(?)">)
        -> !cute.layout<"(?):(?)">

  return %r : !cute.layout<"(?):(?)">
}

// -----

// Dynamic inner shape in composed layout.
// CHECK-LABEL: func.func @composed_layout_layout_dyn_inner_shape
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
// CHECK-SAME:   %[[INNER:.+]]: !cute.layout<"(?,3):(1,2)">)
func.func @composed_layout_layout_dyn_inner_shape(
    %outer: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">,
    %inner: !cute.layout<"(?,3):(1,2)">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(1,2)"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">, !cute.layout<"(?,3):(1,2)">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(1,2)">
  %r = cute.composition(%outer, %inner)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">, !cute.layout<"(?,3):(1,2)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(1,2)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(1,2)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_mid_layout_truncation
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(4,6,8,10):(2,3,5,7)">, %[[INNER:.+]]: !cute.layout<"6:12">)
func.func @CG_TEST_mid_layout_truncation(
    %outer: !cute.layout<"(4,6,8,10):(2,3,5,7)">,
    %inner: !cute.layout<"6:12">) -> !cute.layout<"(2,3):(9,5)"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(4,6,8,10):(2,3,5,7)">, !cute.layout<"6:12">) -> !cute.layout<"(2,3):(9,5)">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,6,8,10):(2,3,5,7)">, !cute.layout<"6:12">)
        -> !cute.layout<"(2,3):(9,5)">
  return %r : !cute.layout<"(2,3):(9,5)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_oversized_inner_stride_size2
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(8,8):(8,1)">, %[[INNER:.+]]: !cute.layout<"2:3">)
func.func @CG_TEST_oversized_inner_stride_size2(
    %outer: !cute.layout<"(8,8):(8,1)">,
    %inner: !cute.layout<"2:3">) -> !cute.layout<"2:24"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(8,8):(8,1)">, !cute.layout<"2:3">) -> !cute.layout<"2:24">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(8,8):(8,1)">, !cute.layout<"2:3">) -> !cute.layout<"2:24">
  return %r : !cute.layout<"2:24">
}

// -----

// Same outer with larger inner size.
// CHECK-LABEL: func.func @CG_TEST_oversized_inner_stride_size3
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(8,8):(8,1)">, %[[INNER:.+]]: !cute.layout<"3:3">)
func.func @CG_TEST_oversized_inner_stride_size3(
    %outer: !cute.layout<"(8,8):(8,1)">,
    %inner: !cute.layout<"3:3">) -> !cute.layout<"3:24"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(8,8):(8,1)">, !cute.layout<"3:3">) -> !cute.layout<"3:24">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(8,8):(8,1)">, !cute.layout<"3:3">) -> !cute.layout<"3:24">
  return %r : !cute.layout<"3:24">
}

// -----

// Outer with prime-ish strides composed with trivial inner `6:1`
// CHECK-LABEL: func.func @CG_TEST_prime_strides_trivial_inner
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(4,6,8):(1,4,7)">, %[[INNER:.+]]: !cute.layout<"6:1">)
func.func @CG_TEST_prime_strides_trivial_inner(
    %outer: !cute.layout<"(4,6,8):(1,4,7)">,
    %inner: !cute.layout<"6:1">) -> !cute.layout<"6:1"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(4,6,8):(1,4,7)">, !cute.layout<"6:1">) -> !cute.layout<"6:1">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,6,8):(1,4,7)">, !cute.layout<"6:1">) -> !cute.layout<"6:1">
  return %r : !cute.layout<"6:1">
}

// -----

// stride-zero (broadcast) mode in outer.
// CHECK-LABEL: func.func @CG_TEST_outer_stride_zero_mode
// CHECK-SAME:  (%[[OUTER:.+]]: !cute.layout<"(4,3,1):(3,1,0)">, %[[INNER:.+]]: !cute.layout<"4:1">)
func.func @CG_TEST_outer_stride_zero_mode(
    %outer: !cute.layout<"(4,3,1):(3,1,0)">,
    %inner: !cute.layout<"4:1">) -> !cute.layout<"4:3"> {
  // CHECK: %[[R:.+]] = cute.composition(%[[OUTER]], %[[INNER]])
  // CHECK-SAME: (!cute.layout<"(4,3,1):(3,1,0)">, !cute.layout<"4:1">) -> !cute.layout<"4:3">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,3,1):(3,1,0)">, !cute.layout<"4:1">) -> !cute.layout<"4:3">
  return %r : !cute.layout<"4:3">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l77
func.func @CG_TEST_comp_l77(%a: !cute.layout<"1:0">, %b: !cute.layout<"1:0">) -> !cute.layout<"1:0"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.layout<"1:0">) -> !cute.layout<"1:0">
  %r = cute.composition(%a, %b) : (!cute.layout<"1:0">, !cute.layout<"1:0">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l85
func.func @CG_TEST_comp_l85(%a: !cute.layout<"1:0">, %b: !cute.layout<"1:1">) -> !cute.layout<"1:0"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.layout<"1:1">) -> !cute.layout<"1:0">
  %r = cute.composition(%a, %b) : (!cute.layout<"1:0">, !cute.layout<"1:1">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l93
func.func @CG_TEST_comp_l93(%a: !cute.layout<"1:1">, %b: !cute.layout<"1:0">) -> !cute.layout<"1:0"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.layout<"1:0">) -> !cute.layout<"1:0">
  %r = cute.composition(%a, %b) : (!cute.layout<"1:1">, !cute.layout<"1:0">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l101
func.func @CG_TEST_comp_l101(%a: !cute.layout<"1:1">, %b: !cute.layout<"1:1">) -> !cute.layout<"1:1"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.layout<"1:1">) -> !cute.layout<"1:1">
  %r = cute.composition(%a, %b) : (!cute.layout<"1:1">, !cute.layout<"1:1">) -> !cute.layout<"1:1">
  return %r : !cute.layout<"1:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l109
func.func @CG_TEST_comp_l109(%a: !cute.layout<"4:1">, %b: !cute.layout<"4:1">) -> !cute.layout<"4:1"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"4:1">, !cute.layout<"4:1">) -> !cute.layout<"4:1">
  %r = cute.composition(%a, %b) : (!cute.layout<"4:1">, !cute.layout<"4:1">) -> !cute.layout<"4:1">
  return %r : !cute.layout<"4:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l117
func.func @CG_TEST_comp_l117(%a: !cute.layout<"4:2">, %b: !cute.layout<"4:1">) -> !cute.layout<"4:2"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"4:2">, !cute.layout<"4:1">) -> !cute.layout<"4:2">
  %r = cute.composition(%a, %b) : (!cute.layout<"4:2">, !cute.layout<"4:1">) -> !cute.layout<"4:2">
  return %r : !cute.layout<"4:2">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l125
func.func @CG_TEST_comp_l125(%a: !cute.layout<"4:0">, %b: !cute.layout<"4:1">) -> !cute.layout<"4:0"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"4:0">, !cute.layout<"4:1">) -> !cute.layout<"4:0">
  %r = cute.composition(%a, %b) : (!cute.layout<"4:0">, !cute.layout<"4:1">) -> !cute.layout<"4:0">
  return %r : !cute.layout<"4:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l141
func.func @CG_TEST_comp_l141(%a: !cute.layout<"4:1">, %b: !cute.layout<"1:0">) -> !cute.layout<"1:0"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"4:1">, !cute.layout<"1:0">) -> !cute.layout<"1:0">
  %r = cute.composition(%a, %b) : (!cute.layout<"4:1">, !cute.layout<"1:0">) -> !cute.layout<"1:0">
  return %r : !cute.layout<"1:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l149
func.func @CG_TEST_comp_l149(%a: !cute.layout<"4:1">, %b: !cute.layout<"2:1">) -> !cute.layout<"2:1"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"4:1">, !cute.layout<"2:1">) -> !cute.layout<"2:1">
  %r = cute.composition(%a, %b) : (!cute.layout<"4:1">, !cute.layout<"2:1">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l157
func.func @CG_TEST_comp_l157(%a: !cute.layout<"4:2">, %b: !cute.layout<"2:1">) -> !cute.layout<"2:2"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"4:2">, !cute.layout<"2:1">) -> !cute.layout<"2:2">
  %r = cute.composition(%a, %b) : (!cute.layout<"4:2">, !cute.layout<"2:1">) -> !cute.layout<"2:2">
  return %r : !cute.layout<"2:2">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l165
func.func @CG_TEST_comp_l165(%a: !cute.layout<"4:1">, %b: !cute.layout<"2:2">) -> !cute.layout<"2:2"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"4:1">, !cute.layout<"2:2">) -> !cute.layout<"2:2">
  %r = cute.composition(%a, %b) : (!cute.layout<"4:1">, !cute.layout<"2:2">) -> !cute.layout<"2:2">
  return %r : !cute.layout<"2:2">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l173
func.func @CG_TEST_comp_l173(%a: !cute.layout<"4:2">, %b: !cute.layout<"2:2">) -> !cute.layout<"2:4"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"4:2">, !cute.layout<"2:2">) -> !cute.layout<"2:4">
  %r = cute.composition(%a, %b) : (!cute.layout<"4:2">, !cute.layout<"2:2">) -> !cute.layout<"2:4">
  return %r : !cute.layout<"2:4">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l181
func.func @CG_TEST_comp_l181(%a: !cute.layout<"(4,3):(1,4)">, %b: !cute.layout<"12:1">) -> !cute.layout<"12:1"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"12:1">) -> !cute.layout<"12:1">
  %r = cute.composition(%a, %b) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"12:1">) -> !cute.layout<"12:1">
  return %r : !cute.layout<"12:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l189
func.func @CG_TEST_comp_l189(%a: !cute.layout<"12:1">, %b: !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(1,4)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"12:1">, !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(1,4)">
  %r = cute.composition(%a, %b) : (!cute.layout<"12:1">, !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(1,4)">
  return %r : !cute.layout<"(4,3):(1,4)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l197
func.func @CG_TEST_comp_l197(%a: !cute.layout<"12:2">, %b: !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(2,8)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"12:2">, !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(2,8)">
  %r = cute.composition(%a, %b) : (!cute.layout<"12:2">, !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(2,8)">
  return %r : !cute.layout<"(4,3):(2,8)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l205
func.func @CG_TEST_comp_l205(%a: !cute.layout<"12:1">, %b: !cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(4,3):(3,1)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"12:1">, !cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(4,3):(3,1)">
  %r = cute.composition(%a, %b) : (!cute.layout<"12:1">, !cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(4,3):(3,1)">
  return %r : !cute.layout<"(4,3):(3,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l213
func.func @CG_TEST_comp_l213(%a: !cute.layout<"12:2">, %b: !cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(4,3):(6,2)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"12:2">, !cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(4,3):(6,2)">
  %r = cute.composition(%a, %b) : (!cute.layout<"12:2">, !cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(4,3):(6,2)">
  return %r : !cute.layout<"(4,3):(6,2)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l221
func.func @CG_TEST_comp_l221(%a: !cute.layout<"12:1">, %b: !cute.layout<"(2,3):(2,4)">) -> !cute.layout<"(2,3):(2,4)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"12:1">, !cute.layout<"(2,3):(2,4)">) -> !cute.layout<"(2,3):(2,4)">
  %r = cute.composition(%a, %b) : (!cute.layout<"12:1">, !cute.layout<"(2,3):(2,4)">) -> !cute.layout<"(2,3):(2,4)">
  return %r : !cute.layout<"(2,3):(2,4)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l229
func.func @CG_TEST_comp_l229(%a: !cute.layout<"(4,3):(1,4)">, %b: !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(1,4)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(1,4)">
  %r = cute.composition(%a, %b) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(1,4)">
  return %r : !cute.layout<"(4,3):(1,4)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l237
func.func @CG_TEST_comp_l237(%a: !cute.layout<"(4,3):(1,4)">, %b: !cute.layout<"6:1">) -> !cute.layout<"6:1"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"6:1">) -> !cute.layout<"6:1">
  %r = cute.composition(%a, %b) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"6:1">) -> !cute.layout<"6:1">
  return %r : !cute.layout<"6:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l245
func.func @CG_TEST_comp_l245(%a: !cute.layout<"(4,3):(1,4)">, %b: !cute.layout<"6:2">) -> !cute.layout<"6:2"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"6:2">) -> !cute.layout<"6:2">
  %r = cute.composition(%a, %b) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"6:2">) -> !cute.layout<"6:2">
  return %r : !cute.layout<"6:2">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l253
func.func @CG_TEST_comp_l253(%a: !cute.layout<"(4,3):(1,4)">, %b: !cute.layout<"(6,2):(2,1)">) -> !cute.layout<"(6,2):(2,1)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"(6,2):(2,1)">) -> !cute.layout<"(6,2):(2,1)">
  %r = cute.composition(%a, %b) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"(6,2):(2,1)">) -> !cute.layout<"(6,2):(2,1)">
  return %r : !cute.layout<"(6,2):(2,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l261
func.func @CG_TEST_comp_l261(%a: !cute.layout<"(4,3):(1,4)">, %b: !cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(4,3):(3,1)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(4,3):(3,1)">
  %r = cute.composition(%a, %b) : (!cute.layout<"(4,3):(1,4)">, !cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(4,3):(3,1)">
  return %r : !cute.layout<"(4,3):(3,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l269
func.func @CG_TEST_comp_l269(%a: !cute.layout<"(4,3):(3,1)">, %b: !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(3,1)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(3,1)">
  %r = cute.composition(%a, %b) : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"(4,3):(3,1)">
  return %r : !cute.layout<"(4,3):(3,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l293
func.func @CG_TEST_comp_l293(%a: !cute.layout<"(4,3):(3,1)">, %b: !cute.layout<"(6,2):(2,1)">) -> !cute.layout<"((2,3),2):((6,1),3)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(6,2):(2,1)">) -> !cute.layout<"((2,3),2):((6,1),3)">
  %r = cute.composition(%a, %b) : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(6,2):(2,1)">) -> !cute.layout<"((2,3),2):((6,1),3)">
  return %r : !cute.layout<"((2,3),2):((6,1),3)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l322
func.func @CG_TEST_comp_l322(%a: !cute.layout<"((4,2)):((1,16))">, %b: !cute.layout<"(4,2):(2,1)">) -> !cute.layout<"((2,2),2):((2,16),1)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"((4,2)):((1,16))">, !cute.layout<"(4,2):(2,1)">) -> !cute.layout<"((2,2),2):((2,16),1)">
  %r = cute.composition(%a, %b) : (!cute.layout<"((4,2)):((1,16))">, !cute.layout<"(4,2):(2,1)">) -> !cute.layout<"((2,2),2):((2,16),1)">
  return %r : !cute.layout<"((2,2),2):((2,16),1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l329
func.func @CG_TEST_comp_l329(%a: !cute.layout<"(2,2):(2,1)">, %b: !cute.layout<"(2,2):(2,1)">) -> !cute.layout<"(2,2):(1,2)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,2):(2,1)">, !cute.layout<"(2,2):(2,1)">) -> !cute.layout<"(2,2):(1,2)">
  %r = cute.composition(%a, %b) : (!cute.layout<"(2,2):(2,1)">, !cute.layout<"(2,2):(2,1)">) -> !cute.layout<"(2,2):(1,2)">
  return %r : !cute.layout<"(2,2):(1,2)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l336
func.func @CG_TEST_comp_l336(%a: !cute.layout<"(4,8,2):(1,4,32)">, %b: !cute.layout<"(2,2,2):(2,8,1)">) -> !cute.layout<"(2,2,2):(2,8,1)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,8,2):(1,4,32)">, !cute.layout<"(2,2,2):(2,8,1)">) -> !cute.layout<"(2,2,2):(2,8,1)">
  %r = cute.composition(%a, %b) : (!cute.layout<"(4,8,2):(1,4,32)">, !cute.layout<"(2,2,2):(2,8,1)">) -> !cute.layout<"(2,2,2):(2,8,1)">
  return %r : !cute.layout<"(2,2,2):(2,8,1)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l343
func.func @CG_TEST_comp_l343(%a: !cute.layout<"(4,8,2):(2,8,1)">, %b: !cute.layout<"(2,2,2):(1,8,2)">) -> !cute.layout<"(2,2,2):(2,16,4)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,8,2):(2,8,1)">, !cute.layout<"(2,2,2):(1,8,2)">) -> !cute.layout<"(2,2,2):(2,16,4)">
  %r = cute.composition(%a, %b) : (!cute.layout<"(4,8,2):(2,8,1)">, !cute.layout<"(2,2,2):(1,8,2)">) -> !cute.layout<"(2,2,2):(2,16,4)">
  return %r : !cute.layout<"(2,2,2):(2,16,4)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l350
func.func @CG_TEST_comp_l350(%a: !cute.layout<"(4,8,2):(2,8,1)">, %b: !cute.layout<"(4,2,2):(2,8,1)">) -> !cute.layout<"(4,2,2):(4,16,2)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,8,2):(2,8,1)">, !cute.layout<"(4,2,2):(2,8,1)">) -> !cute.layout<"(4,2,2):(4,16,2)">
  %r = cute.composition(%a, %b) : (!cute.layout<"(4,8,2):(2,8,1)">, !cute.layout<"(4,2,2):(2,8,1)">) -> !cute.layout<"(4,2,2):(4,16,2)">
  return %r : !cute.layout<"(4,2,2):(4,16,2)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l360
func.func @CG_TEST_comp_l360(%a: !cute.layout<"?:?">, %b: !cute.layout<"4:1">) -> !cute.layout<"4:?"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"?:?">, !cute.layout<"4:1">) -> !cute.layout<"4:?">
  %r = cute.composition(%a, %b) : (!cute.layout<"?:?">, !cute.layout<"4:1">) -> !cute.layout<"4:?">
  return %r : !cute.layout<"4:?">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l367
func.func @CG_TEST_comp_l367(%a: !cute.layout<"?:?">, %b: !cute.layout<"4:?">) -> !cute.layout<"4:?"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"?:?">, !cute.layout<"4:?">) -> !cute.layout<"4:?">
  %r = cute.composition(%a, %b) : (!cute.layout<"?:?">, !cute.layout<"4:?">) -> !cute.layout<"4:?">
  return %r : !cute.layout<"4:?">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l374
func.func @CG_TEST_comp_l374(%a: !cute.layout<"?:1">, %b: !cute.layout<"4:?">) -> !cute.layout<"4:?"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"?:1">, !cute.layout<"4:?">) -> !cute.layout<"4:?">
  %r = cute.composition(%a, %b) : (!cute.layout<"?:1">, !cute.layout<"4:?">) -> !cute.layout<"4:?">
  return %r : !cute.layout<"4:?">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l381
func.func @CG_TEST_comp_l381(%a: !cute.layout<"?:1">, %b: !cute.layout<"4:1">) -> !cute.layout<"4:1"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"?:1">, !cute.layout<"4:1">) -> !cute.layout<"4:1">
  %r = cute.composition(%a, %b) : (!cute.layout<"?:1">, !cute.layout<"4:1">) -> !cute.layout<"4:1">
  return %r : !cute.layout<"4:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l395
func.func @CG_TEST_comp_l395(%a: !cute.layout<"?:?">, %b: !cute.layout<"?:?">) -> !cute.layout<"?:?"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"?:?">, !cute.layout<"?:?">) -> !cute.layout<"?:?">
  %r = cute.composition(%a, %b) : (!cute.layout<"?:?">, !cute.layout<"?:?">) -> !cute.layout<"?:?">
  return %r : !cute.layout<"?:?">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l405
func.func @CG_TEST_comp_l405(%a: !cute.layout<"1:0">, %b: !cute.layout<"4:1">) -> !cute.layout<"4:0"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.layout<"4:1">) -> !cute.layout<"4:0">
  %r = cute.composition(%a, %b) : (!cute.layout<"1:0">, !cute.layout<"4:1">) -> !cute.layout<"4:0">
  return %r : !cute.layout<"4:0">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l412
func.func @CG_TEST_comp_l412(%a: !cute.layout<"1:1">, %b: !cute.layout<"4:1">) -> !cute.layout<"4:1"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.layout<"4:1">) -> !cute.layout<"4:1">
  %r = cute.composition(%a, %b) : (!cute.layout<"1:1">, !cute.layout<"4:1">) -> !cute.layout<"4:1">
  return %r : !cute.layout<"4:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l419
func.func @CG_TEST_comp_l419(%a: !cute.layout<"4:1">, %b: !cute.layout<"4:2">) -> !cute.layout<"4:2"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"4:1">, !cute.layout<"4:2">) -> !cute.layout<"4:2">
  %r = cute.composition(%a, %b) : (!cute.layout<"4:1">, !cute.layout<"4:2">) -> !cute.layout<"4:2">
  return %r : !cute.layout<"4:2">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l493
func.func @CG_TEST_comp_l493(%a: !cute.layout<"3:1">, %b: !cute.layout<"4:1">) -> !cute.layout<"4:1"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"3:1">, !cute.layout<"4:1">) -> !cute.layout<"4:1">
  %r = cute.composition(%a, %b) : (!cute.layout<"3:1">, !cute.layout<"4:1">) -> !cute.layout<"4:1">
  return %r : !cute.layout<"4:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l531
func.func @CG_TEST_comp_l531(%a: !cute.layout<"(5,4):(1,10)">, %b: !cute.layout<"3:1">) -> !cute.layout<"3:1"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(5,4):(1,10)">, !cute.layout<"3:1">) -> !cute.layout<"3:1">
  %r = cute.composition(%a, %b) : (!cute.layout<"(5,4):(1,10)">, !cute.layout<"3:1">) -> !cute.layout<"3:1">
  return %r : !cute.layout<"3:1">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_comp_l538
func.func @CG_TEST_comp_l538(%a: !cute.layout<"64:4096">, %b: !cute.layout<"1:1">) -> !cute.layout<"1:4096"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"64:4096">, !cute.layout<"1:1">) -> !cute.layout<"1:4096">
  %r = cute.composition(%a, %b) : (!cute.layout<"64:4096">, !cute.layout<"1:1">) -> !cute.layout<"1:4096">
  return %r : !cute.layout<"1:4096">
}

// -----

// Scaled-basis inner with flat basis.
// CHECK-LABEL: func.func @CG_TEST_comp_sb_inner_1
func.func @CG_TEST_comp_sb_inner_1(%a: !cute.layout<"(4,4):(4,1)">,
                                    %b: !cute.layout<"(4,4):(1@1,1@0)">)
                                    -> !cute.layout<"(4,4):(1,4)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,4):(4,1)">, !cute.layout<"(4,4):(1@1,1@0)">) -> !cute.layout<"(4,4):(1,4)">
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(4,4):(4,1)">, !cute.layout<"(4,4):(1@1,1@0)">)
        -> !cute.layout<"(4,4):(1,4)">
  return %r : !cute.layout<"(4,4):(1,4)">
}

// -----

// Scaled-basis inner with hierarchical basis.
// CHECK-LABEL: func.func @CG_TEST_comp_sb_inner_hierarchical
func.func @CG_TEST_comp_sb_inner_hierarchical(
    %a: !cute.layout<"(4,(2,3)):(6,(3,1))">,
    %b: !cute.layout<"(2,4):(1@1@1,1@0)">) -> !cute.layout<"(2,4):(1,6)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,(2,3)):(6,(3,1))">, !cute.layout<"(2,4):(1@1@1,1@0)">) -> !cute.layout<"(2,4):(1,6)">
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(4,(2,3)):(6,(3,1))">, !cute.layout<"(2,4):(1@1@1,1@0)">)
        -> !cute.layout<"(2,4):(1,6)">
  return %r : !cute.layout<"(2,4):(1,6)">
}

// -----

// Inner layout with nested-tuple strides
// CHECK-LABEL: func.func @CG_TEST_comp_nested_stride_1
func.func @CG_TEST_comp_nested_stride_1(
    %a: !cute.layout<"(8,8):(1,8)">,
    %b: !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">)
    -> !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,8):(1,8)">, !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">) -> !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(8,8):(1,8)">, !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">)
        -> !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">
  return %r : !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">
}

// -----

// Same nested-stride inner with the outer's strides swapped
// CHECK-LABEL: func.func @CG_TEST_comp_nested_stride_2
func.func @CG_TEST_comp_nested_stride_2(
    %a: !cute.layout<"(8,8):(8,1)">,
    %b: !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">)
    -> !cute.layout<"((2,2,2),(2,2,2)):((8,2,32),(1,16,4))"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,8):(8,1)">, !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">) -> !cute.layout<"((2,2,2),(2,2,2)):((8,2,32),(1,16,4))">
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(8,8):(8,1)">, !cute.layout<"((2,2,2),(2,2,2)):((1,16,4),(8,2,32))">)
        -> !cute.layout<"((2,2,2),(2,2,2)):((8,2,32),(1,16,4))">
  return %r : !cute.layout<"((2,2,2),(2,2,2)):((8,2,32),(1,16,4))">
}

// -----

// Scaled-basis inner with short stride.
// CHECK-LABEL: func.func @CG_TEST_comp_sb_inner_short
func.func @CG_TEST_comp_sb_inner_short(%outer: !cute.layout<"(4,8):(1,4)">,
                                        %inner: !cute.layout<"(2,3):(1@0,1@1)">)
                                        -> !cute.layout<"(2,3):(1,4)"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1@0,1@1)">) -> !cute.layout<"(2,3):(1,4)">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1@0,1@1)">)
        -> !cute.layout<"(2,3):(1,4)">
  return %r : !cute.layout<"(2,3):(1,4)">
}

// -----

// Inner with tuple stride.
// CHECK-LABEL: func.func @CG_TEST_comp_nested_stride_short
func.func @CG_TEST_comp_nested_stride_short(
    %outer: !cute.layout<"(4,8):(1,4)">,
    %inner: !cute.layout<"((2,3),(4)):((1,2),(8))">)
    -> !cute.layout<"((2,3),(4)):((1,2),(8))"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"((2,3),(4)):((1,2),(8))">) -> !cute.layout<"((2,3),(4)):((1,2),(8))">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"((2,3),(4)):((1,2),(8))">)
        -> !cute.layout<"((2,3),(4)):((1,2),(8))">
  return %r : !cute.layout<"((2,3),(4)):((1,2),(8))">
}

// -----

// Outer-paren wrapped form.
// CHECK-LABEL: func.func @CG_TEST_comp_outer_paren_l277
func.func @CG_TEST_comp_outer_paren_l277(%a: !cute.layout<"(4,3):(3,1)">,
                                          %b: !cute.layout<"(12):(1)">)
                                          -> !cute.layout<"((4,3)):((3,1))"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(12):(1)">) -> !cute.layout<"((4,3)):((3,1))">
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(12):(1)">)
        -> !cute.layout<"((4,3)):((3,1))">
  return %r : !cute.layout<"((4,3)):((3,1))">
}

// -----

// Outer-paren wrap, strided inner.
// CHECK-LABEL: func.func @CG_TEST_comp_outer_paren_l285
func.func @CG_TEST_comp_outer_paren_l285(%a: !cute.layout<"(4,3):(3,1)">,
                                          %b: !cute.layout<"(6):(2)">)
                                          -> !cute.layout<"((2,3)):((6,1))"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(6):(2)">) -> !cute.layout<"((2,3)):((6,1))">
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(6):(2)">)
        -> !cute.layout<"((2,3)):((6,1))">
  return %r : !cute.layout<"((2,3)):((6,1))">
}

// -----

// Outer-paren wrap, larger inner size.
// CHECK-LABEL: func.func @CG_TEST_comp_outer_paren_l427
func.func @CG_TEST_comp_outer_paren_l427(%a: !cute.layout<"(4,3):(3,1)">,
                                          %b: !cute.layout<"(24):(1)">)
                                          -> !cute.layout<"((4,6)):((3,1))"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(24):(1)">) -> !cute.layout<"((4,6)):((3,1))">
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(24):(1)">)
        -> !cute.layout<"((4,6)):((3,1))">
  return %r : !cute.layout<"((4,6)):((3,1))">
}

// -----

// Outer-paren wrap, smaller inner size.
// CHECK-LABEL: func.func @CG_TEST_comp_outer_paren_l435
func.func @CG_TEST_comp_outer_paren_l435(%a: !cute.layout<"(4,3):(3,1)">,
                                          %b: !cute.layout<"(8):(1)">)
                                          -> !cute.layout<"((4,2)):((3,1))"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(8):(1)">) -> !cute.layout<"((4,2)):((3,1))">
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(4,3):(3,1)">, !cute.layout<"(8):(1)">)
        -> !cute.layout<"((4,2)):((3,1))">
  return %r : !cute.layout<"((4,2)):((3,1))">
}

// -----

// Outer-paren wrap with broadcast (stride-0) mode.
// CHECK-LABEL: func.func @CG_TEST_comp_outer_paren_l443
func.func @CG_TEST_comp_outer_paren_l443(%a: !cute.layout<"(4,3,1):(3,1,0)">,
                                          %b: !cute.layout<"(24):(1)">)
                                          -> !cute.layout<"((4,3,2)):((3,1,0))"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3,1):(3,1,0)">, !cute.layout<"(24):(1)">) -> !cute.layout<"((4,3,2)):((3,1,0))">
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(4,3,1):(3,1,0)">, !cute.layout<"(24):(1)">)
        -> !cute.layout<"((4,3,2)):((3,1,0))">
  return %r : !cute.layout<"((4,3,2)):((3,1,0))">
}

// -----

// Outer-paren wrap on dyn input.
// CHECK-LABEL: func.func @CG_TEST_comp_outer_paren_dyn
func.func @CG_TEST_comp_outer_paren_dyn(%a: !cute.layout<"(?,?):(?,?)">,
                                         %b: !cute.layout<"(4):(1)">)
                                         -> !cute.layout<"((?,?)):((?,?))"> {
  // CHECK: cute.composition(%{{.+}}, %{{.+}}) : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(4):(1)">) -> !cute.layout<"((?,?)):((?,?))">
  %r = cute.composition(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(4):(1)">)
        -> !cute.layout<"((?,?)):((?,?))">
  return %r : !cute.layout<"((?,?)):((?,?))">
}
