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

// Tests round-trip for cute.zipped_product.

// -----

// Layout × layout (2-D × 2-D).
// CHECK-LABEL: func.func @zipped_product_layout_layout
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(3,4):(4,1)">, %[[B:.+]]: !cute.layout<"(2,5):(1,2)">)
func.func @zipped_product_layout_layout(
    %a: !cute.layout<"(3,4):(4,1)">,
    %b: !cute.layout<"(2,5):(1,2)">) -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))"> {
  // CHECK: %[[R:.+]] = cute.zipped_product(%[[A]], %[[B]]) : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  %r = cute.zipped_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  return %r : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
}

// -----

// ComposedLayout input — result kind matches.
// CHECK-LABEL: func.func @zipped_product_composed_layout
func.func @zipped_product_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
    %b: !cute.layout<"(2,5):(1,2)">) {
  // CHECK: cute.zipped_product(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),(2,5)):((4,1),(20,40))">
  %r = cute.zipped_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
            !cute.layout<"(2,5):(1,2)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),(2,5)):((4,1),(20,40))">
  return
}

// -----

// Static input × dynamic tiler — static-input precondition only guards
// the first operand; dyn tiler is fine.
// CHECK-LABEL: func.func @zipped_product_dyn_tiler
func.func @zipped_product_dyn_tiler(
    %a: !cute.layout<"(3,4):(4,1)">,
    %b: !cute.layout<"(?,?):(1,2)">)
    -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))"> {
  // CHECK: cute.zipped_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">) -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  %r = cute.zipped_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
        -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  return %r : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
}

// -----

// Higher-rank inputs: rank-3 × rank-3.
// CHECK-LABEL: func.func @zipped_product_rank3
func.func @zipped_product_rank3(
    %a: !cute.layout<"(3,4,2):(8,2,1)">,
    %b: !cute.layout<"(2,3,5):(1,2,6)">)
    -> !cute.layout<"((3,4,2),(2,3,5)):((8,2,1),(24,48,144))"> {
  // CHECK: cute.zipped_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(3,4,2):(8,2,1)">, !cute.layout<"(2,3,5):(1,2,6)">) -> !cute.layout<"((3,4,2),(2,3,5)):((8,2,1),(24,48,144))">
  %r = cute.zipped_product(%a, %b)
         : (!cute.layout<"(3,4,2):(8,2,1)">, !cute.layout<"(2,3,5):(1,2,6)">)
        -> !cute.layout<"((3,4,2),(2,3,5)):((8,2,1),(24,48,144))">
  return %r : !cute.layout<"((3,4,2),(2,3,5)):((8,2,1),(24,48,144))">
}

// -----

// Higher-rank composed input × rank-3 tiler.
// CHECK-LABEL: func.func @zipped_product_rank3_composed
func.func @zipped_product_rank3_composed(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (5,4,2):(8,2,1)">,
    %b: !cute.layout<"(2,3,5):(1,2,6)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),(2,3,5)):((8,2,1),(40,80,240))"> {
  // CHECK: cute.zipped_product(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4,2):(8,2,1)">, !cute.layout<"(2,3,5):(1,2,6)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),(2,3,5)):((8,2,1),(40,80,240))">
  %r = cute.zipped_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4,2):(8,2,1)">,
            !cute.layout<"(2,3,5):(1,2,6)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),(2,3,5)):((8,2,1),(40,80,240))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),(2,3,5)):((8,2,1),(40,80,240))">
}

// -----

// Composed input with dyn outer + static B × dyn tiler — static-input
// check applies to the B component only.
// CHECK-LABEL: func.func @zipped_product_composed_dyn_outer_dyn_tiler
func.func @zipped_product_composed_dyn_outer_dyn_tiler(
    %a: !cute.composed_layout<"(?):(?) o ? o (5,4):(4,1)">,
    %b: !cute.layout<"(?,?):(?,?)">)
    -> !cute.composed_layout<"(?):(?) o ? o ((5,4),(?,?)):((4,1),(?,?))"> {
  // CHECK: cute.zipped_product(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"(?):(?) o ? o (5,4):(4,1)">, !cute.layout<"(?,?):(?,?)">) -> !cute.composed_layout<"(?):(?) o ? o ((5,4),(?,?)):((4,1),(?,?))">
  %r = cute.zipped_product(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (5,4):(4,1)">,
            !cute.layout<"(?,?):(?,?)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((5,4),(?,?)):((4,1),(?,?))">
  return %r : !cute.composed_layout<"(?):(?) o ? o ((5,4),(?,?)):((4,1),(?,?))">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_zipped_product_basic
func.func @CG_TEST_zipped_product_basic(
    %a: !cute.layout<"(3,4):(1,3)">, %b: !cute.layout<"(4,5):(5,1)">)
    -> !cute.layout<"((3,4),(4,5)):((1,3),(60,12))"> {
  // CHECK: cute.zipped_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(3,4):(1,3)">, !cute.layout<"(4,5):(5,1)">) -> !cute.layout<"((3,4),(4,5)):((1,3),(60,12))">
  %r = cute.zipped_product(%a, %b) : (!cute.layout<"(3,4):(1,3)">, !cute.layout<"(4,5):(5,1)">) -> !cute.layout<"((3,4),(4,5)):((1,3),(60,12))">
  return %r : !cute.layout<"((3,4),(4,5)):((1,3),(60,12))">
}

// -----

// Scaled-basis lhs stride.
// CHECK-LABEL: func.func @CG_TEST_scaled_basis_lhs
func.func @CG_TEST_scaled_basis_lhs(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))"> {
  // CHECK: cute.zipped_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  %r = cute.zipped_product(%a, %b) : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  return %r : !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
}
