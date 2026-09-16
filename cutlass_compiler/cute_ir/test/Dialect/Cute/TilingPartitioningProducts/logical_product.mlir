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

// Tests round-trip for cute.logical_product.

// -----

// Layout × layout (2-D × 2-D).
// CHECK-LABEL: func.func @logical_product_layout_layout
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(3,4):(4,1)">, %[[B:.+]]: !cute.layout<"(2,5):(1,2)">)
func.func @logical_product_layout_layout(
    %a: !cute.layout<"(3,4):(4,1)">,
    %b: !cute.layout<"(2,5):(1,2)">) -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))"> {
  // CHECK: %[[R:.+]] = cute.logical_product(%[[A]], %[[B]]) : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  %r = cute.logical_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
  return %r : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
}

// -----

// Layout × scalar tiler.
// CHECK-LABEL: func.func @logical_product_scalar_tiler
func.func @logical_product_scalar_tiler(
    %a: !cute.layout<"(4,8):(1,4)">,
    %b: !cute.layout<"4:1">) -> !cute.layout<"((4,8),4):((1,4),32)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"4:1">) -> !cute.layout<"((4,8),4):((1,4),32)">
  %r = cute.logical_product(%a, %b)
         : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"4:1">)
        -> !cute.layout<"((4,8),4):((1,4),32)">
  return %r : !cute.layout<"((4,8),4):((1,4),32)">
}

// -----

// ComposedLayout input — result kind matches input kind.
// CHECK-LABEL: func.func @logical_product_composed_layout
func.func @logical_product_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
    %b: !cute.layout<"(2,5):(1,2)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),(2,5)):((4,1),(20,40))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),(2,5)):((4,1),(20,40))">
  %r = cute.logical_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
            !cute.layout<"(2,5):(1,2)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),(2,5)):((4,1),(20,40))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),(2,5)):((4,1),(20,40))">
}

// -----

// Static input × dynamic tiler.
// The static-input precondition only guards the first operand, so a dyn tiler is fine.
// Result picks up dyn shape from the tiler.
// CHECK-LABEL: func.func @logical_product_dyn_tiler
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(3,4):(4,1)">, %[[B:.+]]: !cute.layout<"(?,?):(1,2)">)
func.func @logical_product_dyn_tiler(
    %a: !cute.layout<"(3,4):(4,1)">,
    %b: !cute.layout<"(?,?):(1,2)">)
    -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))"> {
  // CHECK: %[[R:.+]] = cute.logical_product(%[[A]], %[[B]]) : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">) -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  %r = cute.logical_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
        -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  return %r : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
}

// -----

// Higher-rank inputs: rank-3 plain layout × rank-3 tiler.
// CHECK-LABEL: func.func @logical_product_rank3
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(3,4,2):(8,2,1)">, %[[B:.+]]: !cute.layout<"(2,3,5):(1,2,6)">)
func.func @logical_product_rank3(
    %a: !cute.layout<"(3,4,2):(8,2,1)">,
    %b: !cute.layout<"(2,3,5):(1,2,6)">)
    -> !cute.layout<"((3,4,2),(2,3,5)):((8,2,1),(24,48,144))"> {
  // CHECK: %[[R:.+]] = cute.logical_product(%[[A]], %[[B]]) : (!cute.layout<"(3,4,2):(8,2,1)">, !cute.layout<"(2,3,5):(1,2,6)">) -> !cute.layout<"((3,4,2),(2,3,5)):((8,2,1),(24,48,144))">
  %r = cute.logical_product(%a, %b)
         : (!cute.layout<"(3,4,2):(8,2,1)">, !cute.layout<"(2,3,5):(1,2,6)">)
        -> !cute.layout<"((3,4,2),(2,3,5)):((8,2,1),(24,48,144))">
  return %r : !cute.layout<"((3,4,2),(2,3,5)):((8,2,1),(24,48,144))">
}

// -----

// Higher-rank inputs: rank-3 composed-layout input × rank-3 tiler.
// CHECK-LABEL: func.func @logical_product_rank3_composed
// CHECK-SAME:  (%[[A:.+]]: !cute.composed_layout<"S<3,4,3> o 0 o (5,4,2):(8,2,1)">, %[[B:.+]]: !cute.layout<"(2,3,5):(1,2,6)">)
func.func @logical_product_rank3_composed(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (5,4,2):(8,2,1)">,
    %b: !cute.layout<"(2,3,5):(1,2,6)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),(2,3,5)):((8,2,1),(40,80,240))"> {
  // CHECK: %[[R:.+]] = cute.logical_product(%[[A]], %[[B]]) : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4,2):(8,2,1)">, !cute.layout<"(2,3,5):(1,2,6)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),(2,3,5)):((8,2,1),(40,80,240))">
  %r = cute.logical_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4,2):(8,2,1)">,
            !cute.layout<"(2,3,5):(1,2,6)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),(2,3,5)):((8,2,1),(40,80,240))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),(2,3,5)):((8,2,1),(40,80,240))">
}

// -----

// Composed input with dynamic outer + static B × dyn tiler.
// CHECK-LABEL: func.func @logical_product_composed_dyn_outer_dyn_tiler
// CHECK-SAME:  (%[[A:.+]]: !cute.composed_layout<"(?):(?) o ? o (5,4):(4,1)">, %[[B:.+]]: !cute.layout<"(?,?):(?,?)">)
func.func @logical_product_composed_dyn_outer_dyn_tiler(
    %a: !cute.composed_layout<"(?):(?) o ? o (5,4):(4,1)">,
    %b: !cute.layout<"(?,?):(?,?)">)
    -> !cute.composed_layout<"(?):(?) o ? o ((5,4),(?,?)):((4,1),(?,?))"> {
  // CHECK: %[[R:.+]] = cute.logical_product(%[[A]], %[[B]]) : (!cute.composed_layout<"(?):(?) o ? o (5,4):(4,1)">, !cute.layout<"(?,?):(?,?)">) -> !cute.composed_layout<"(?):(?) o ? o ((5,4),(?,?)):((4,1),(?,?))">
  %r = cute.logical_product(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (5,4):(4,1)">,
            !cute.layout<"(?,?):(?,?)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((5,4),(?,?)):((4,1),(?,?))">
  return %r : !cute.composed_layout<"(?):(?) o ? o ((5,4),(?,?)):((4,1),(?,?))">
}

// -----

// 1:0 × 1:0
// CHECK-LABEL: func.func @CG_TEST_lp_b1
func.func @CG_TEST_lp_b1(%a: !cute.layout<"1:0">, %b: !cute.layout<"1:0">) -> !cute.layout<"(1,1):(0,0)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.layout<"1:0">) -> !cute.layout<"(1,1):(0,0)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"1:0">, !cute.layout<"1:0">) -> !cute.layout<"(1,1):(0,0)">
  return %r : !cute.layout<"(1,1):(0,0)">
}
// -----
// 1:0 × 1:1
// CHECK-LABEL: func.func @CG_TEST_lp_b2
func.func @CG_TEST_lp_b2(%a: !cute.layout<"1:0">, %b: !cute.layout<"1:1">) -> !cute.layout<"(1,1):(0,1)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.layout<"1:1">) -> !cute.layout<"(1,1):(0,1)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"1:0">, !cute.layout<"1:1">) -> !cute.layout<"(1,1):(0,1)">
  return %r : !cute.layout<"(1,1):(0,1)">
}
// -----
// 1:1 × 1:0
// CHECK-LABEL: func.func @CG_TEST_lp_b3
func.func @CG_TEST_lp_b3(%a: !cute.layout<"1:1">, %b: !cute.layout<"1:0">) -> !cute.layout<"(1,1):(1,0)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.layout<"1:0">) -> !cute.layout<"(1,1):(1,0)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"1:1">, !cute.layout<"1:0">) -> !cute.layout<"(1,1):(1,0)">
  return %r : !cute.layout<"(1,1):(1,0)">
}
// -----
// 1:1 × 1:1
// CHECK-LABEL: func.func @CG_TEST_lp_b4
func.func @CG_TEST_lp_b4(%a: !cute.layout<"1:1">, %b: !cute.layout<"1:1">) -> !cute.layout<"(1,1):(1,1)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.layout<"1:1">) -> !cute.layout<"(1,1):(1,1)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"1:1">, !cute.layout<"1:1">) -> !cute.layout<"(1,1):(1,1)">
  return %r : !cute.layout<"(1,1):(1,1)">
}
// -----
// 3:1 × 4:0
// CHECK-LABEL: func.func @CG_TEST_lp_b5
func.func @CG_TEST_lp_b5(%a: !cute.layout<"3:1">, %b: !cute.layout<"4:0">) -> !cute.layout<"(3,4):(1,0)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"3:1">, !cute.layout<"4:0">) -> !cute.layout<"(3,4):(1,0)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"3:1">, !cute.layout<"4:0">) -> !cute.layout<"(3,4):(1,0)">
  return %r : !cute.layout<"(3,4):(1,0)">
}
// -----
// 3:0 × 4:1
// CHECK-LABEL: func.func @CG_TEST_lp_b6
func.func @CG_TEST_lp_b6(%a: !cute.layout<"3:0">, %b: !cute.layout<"4:1">) -> !cute.layout<"(3,4):(0,1)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"3:0">, !cute.layout<"4:1">) -> !cute.layout<"(3,4):(0,1)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"3:0">, !cute.layout<"4:1">) -> !cute.layout<"(3,4):(0,1)">
  return %r : !cute.layout<"(3,4):(0,1)">
}
// -----
// 3:0 × 4:0
// CHECK-LABEL: func.func @CG_TEST_lp_b7
func.func @CG_TEST_lp_b7(%a: !cute.layout<"3:0">, %b: !cute.layout<"4:0">) -> !cute.layout<"(3,4):(0,0)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"3:0">, !cute.layout<"4:0">) -> !cute.layout<"(3,4):(0,0)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"3:0">, !cute.layout<"4:0">) -> !cute.layout<"(3,4):(0,0)">
  return %r : !cute.layout<"(3,4):(0,0)">
}
// -----
// 3:2 × 4:1
// CHECK-LABEL: func.func @CG_TEST_lp_b8
func.func @CG_TEST_lp_b8(%a: !cute.layout<"3:2">, %b: !cute.layout<"4:1">) -> !cute.layout<"(3,(2,2)):(2,(1,6))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"3:2">, !cute.layout<"4:1">) -> !cute.layout<"(3,(2,2)):(2,(1,6))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"3:2">, !cute.layout<"4:1">) -> !cute.layout<"(3,(2,2)):(2,(1,6))">
  return %r : !cute.layout<"(3,(2,2)):(2,(1,6))">
}
// -----
// 3:1 × (2,4):(1,2)
// CHECK-LABEL: func.func @CG_TEST_lp_b9
func.func @CG_TEST_lp_b9(%a: !cute.layout<"3:1">, %b: !cute.layout<"(2,4):(1,2)">) -> !cute.layout<"(3,(2,4)):(1,(3,6))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"3:1">, !cute.layout<"(2,4):(1,2)">) -> !cute.layout<"(3,(2,4)):(1,(3,6))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"3:1">, !cute.layout<"(2,4):(1,2)">) -> !cute.layout<"(3,(2,4)):(1,(3,6))">
  return %r : !cute.layout<"(3,(2,4)):(1,(3,6))">
}
// -----
// (2,4):(1,2) × 3:1
// CHECK-LABEL: func.func @CG_TEST_lp_b10
func.func @CG_TEST_lp_b10(%a: !cute.layout<"(2,4):(1,2)">, %b: !cute.layout<"3:1">) -> !cute.layout<"((2,4),3):((1,2),8)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,4):(1,2)">, !cute.layout<"3:1">) -> !cute.layout<"((2,4),3):((1,2),8)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"(2,4):(1,2)">, !cute.layout<"3:1">) -> !cute.layout<"((2,4),3):((1,2),8)">
  return %r : !cute.layout<"((2,4),3):((1,2),8)">
}
// -----
// (8,(2,2)):(1,(8,16)) × 4:2
// CHECK-LABEL: func.func @CG_TEST_lp_b11
func.func @CG_TEST_lp_b11(%a: !cute.layout<"(8,(2,2)):(1,(8,16))">, %b: !cute.layout<"4:2">) -> !cute.layout<"((8,(2,2)),4):((1,(8,16)),64)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,(2,2)):(1,(8,16))">, !cute.layout<"4:2">) -> !cute.layout<"((8,(2,2)),4):((1,(8,16)),64)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"(8,(2,2)):(1,(8,16))">, !cute.layout<"4:2">) -> !cute.layout<"((8,(2,2)),4):((1,(8,16)),64)">
  return %r : !cute.layout<"((8,(2,2)),4):((1,(8,16)),64)">
}
// -----
// (2,2):(1,2) × (3,3):(3,1)
// CHECK-LABEL: func.func @CG_TEST_lp_b12
func.func @CG_TEST_lp_b12(%a: !cute.layout<"(2,2):(1,2)">, %b: !cute.layout<"(3,3):(3,1)">) -> !cute.layout<"((2,2),(3,3)):((1,2),(12,4))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(2,2):(1,2)">, !cute.layout<"(3,3):(3,1)">) -> !cute.layout<"((2,2),(3,3)):((1,2),(12,4))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"(2,2):(1,2)">, !cute.layout<"(3,3):(3,1)">) -> !cute.layout<"((2,2),(3,3)):((1,2),(12,4))">
  return %r : !cute.layout<"((2,2),(3,3)):((1,2),(12,4))">
}
// -----
// 3:32 × 32:1
// CHECK-LABEL: func.func @CG_TEST_lp_b13
func.func @CG_TEST_lp_b13(%a: !cute.layout<"3:32">, %b: !cute.layout<"32:1">) -> !cute.layout<"(3,32):(32,1)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"3:32">, !cute.layout<"32:1">) -> !cute.layout<"(3,32):(32,1)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"3:32">, !cute.layout<"32:1">) -> !cute.layout<"(3,32):(32,1)">
  return %r : !cute.layout<"(3,32):(32,1)">
}
// -----
// 3:2 × 4:1
// CHECK-LABEL: func.func @CG_TEST_lp_b14
func.func @CG_TEST_lp_b14(%a: !cute.layout<"3:2">, %b: !cute.layout<"4:1">) -> !cute.layout<"(3,(2,2)):(2,(1,6))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"3:2">, !cute.layout<"4:1">) -> !cute.layout<"(3,(2,2)):(2,(1,6))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"3:2">, !cute.layout<"4:1">) -> !cute.layout<"(3,(2,2)):(2,(1,6))">
  return %r : !cute.layout<"(3,(2,2)):(2,(1,6))">
}
// -----
// 3:32 × 128:1
// CHECK-LABEL: func.func @CG_TEST_lp_b15
func.func @CG_TEST_lp_b15(%a: !cute.layout<"3:32">, %b: !cute.layout<"128:1">) -> !cute.layout<"(3,(32,4)):(32,(1,96))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"3:32">, !cute.layout<"128:1">) -> !cute.layout<"(3,(32,4)):(32,(1,96))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"3:32">, !cute.layout<"128:1">) -> !cute.layout<"(3,(32,4)):(32,(1,96))">
  return %r : !cute.layout<"(3,(32,4)):(32,(1,96))">
}
// -----
// 3:32 × (8,8):(1,8)
// CHECK-LABEL: func.func @CG_TEST_lp_b16
func.func @CG_TEST_lp_b16(%a: !cute.layout<"3:32">, %b: !cute.layout<"(8,8):(1,8)">) -> !cute.layout<"(3,(8,(4,2))):(32,(1,(8,96)))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"3:32">, !cute.layout<"(8,8):(1,8)">) -> !cute.layout<"(3,(8,(4,2))):(32,(1,(8,96)))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"3:32">, !cute.layout<"(8,8):(1,8)">) -> !cute.layout<"(3,(8,(4,2))):(32,(1,(8,96)))">
  return %r : !cute.layout<"(3,(8,(4,2))):(32,(1,(8,96)))">
}
// -----
// 3:32 × (8,8):(8,1)
// CHECK-LABEL: func.func @CG_TEST_lp_b17
func.func @CG_TEST_lp_b17(%a: !cute.layout<"3:32">, %b: !cute.layout<"(8,8):(8,1)">) -> !cute.layout<"(3,((4,2),8)):(32,((8,96),1))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"3:32">, !cute.layout<"(8,8):(8,1)">) -> !cute.layout<"(3,((4,2),8)):(32,((8,96),1))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"3:32">, !cute.layout<"(8,8):(8,1)">) -> !cute.layout<"(3,((4,2),8)):(32,((8,96),1))">
  return %r : !cute.layout<"(3,((4,2),8)):(32,((8,96),1))">
}
// -----
// (4,2):(1,16) × (4,4):(1,4)
// CHECK-LABEL: func.func @CG_TEST_lp_b18
func.func @CG_TEST_lp_b18(%a: !cute.layout<"(4,2):(1,16)">, %b: !cute.layout<"(4,4):(1,4)">) -> !cute.layout<"((4,2),(4,4)):((1,16),(4,32))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,2):(1,16)">, !cute.layout<"(4,4):(1,4)">) -> !cute.layout<"((4,2),(4,4)):((1,16),(4,32))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"(4,2):(1,16)">, !cute.layout<"(4,4):(1,4)">) -> !cute.layout<"((4,2),(4,4)):((1,16),(4,32))">
  return %r : !cute.layout<"((4,2),(4,4)):((1,16),(4,32))">
}
// -----
// (4,2):(1,16) × (4,2):(2,1)
// CHECK-LABEL: func.func @CG_TEST_lp_b19
func.func @CG_TEST_lp_b19(%a: !cute.layout<"(4,2):(1,16)">, %b: !cute.layout<"(4,2):(2,1)">) -> !cute.layout<"((4,2),((2,2),2)):((1,16),((8,32),4))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,2):(1,16)">, !cute.layout<"(4,2):(2,1)">) -> !cute.layout<"((4,2),((2,2),2)):((1,16),((8,32),4))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"(4,2):(1,16)">, !cute.layout<"(4,2):(2,1)">) -> !cute.layout<"((4,2),((2,2),2)):((1,16),((8,32),4))">
  return %r : !cute.layout<"((4,2),((2,2),2)):((1,16),((8,32),4))">
}
// -----
// ((2,2),(2,2)):((1,4),(8,32)) × (2,2):(1,2)
// CHECK-LABEL: func.func @CG_TEST_lp_b20
func.func @CG_TEST_lp_b20(%a: !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, %b: !cute.layout<"(2,2):(1,2)">) -> !cute.layout<"(((2,2),(2,2)),(2,2)):(((1,4),(8,32)),(2,16))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.layout<"(2,2):(1,2)">) -> !cute.layout<"(((2,2),(2,2)),(2,2)):(((1,4),(8,32)),(2,16))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.layout<"(2,2):(1,2)">) -> !cute.layout<"(((2,2),(2,2)),(2,2)):(((1,4),(8,32)),(2,16))">
  return %r : !cute.layout<"(((2,2),(2,2)),(2,2)):(((1,4),(8,32)),(2,16))">
}
// -----
// ((2,2),(2,2)):((1,4),(8,32)) × (2,2):(2,1)
// CHECK-LABEL: func.func @CG_TEST_lp_b21
func.func @CG_TEST_lp_b21(%a: !cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, %b: !cute.layout<"(2,2):(2,1)">) -> !cute.layout<"(((2,2),(2,2)),(2,2)):(((1,4),(8,32)),(16,2))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.layout<"(2,2):(2,1)">) -> !cute.layout<"(((2,2),(2,2)),(2,2)):(((1,4),(8,32)),(16,2))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"((2,2),(2,2)):((1,4),(8,32))">, !cute.layout<"(2,2):(2,1)">) -> !cute.layout<"(((2,2),(2,2)),(2,2)):(((1,4),(8,32)),(16,2))">
  return %r : !cute.layout<"(((2,2),(2,2)),(2,2)):(((1,4),(8,32)),(16,2))">
}
// -----
// (4,6):(1,6) × 3:1
// CHECK-LABEL: func.func @CG_TEST_lp_b22
func.func @CG_TEST_lp_b22(%a: !cute.layout<"(4,6):(1,6)">, %b: !cute.layout<"3:1">) -> !cute.layout<"((4,6),3):((1,6),36)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,6):(1,6)">, !cute.layout<"3:1">) -> !cute.layout<"((4,6),3):((1,6),36)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"(4,6):(1,6)">, !cute.layout<"3:1">) -> !cute.layout<"((4,6),3):((1,6),36)">
  return %r : !cute.layout<"((4,6),3):((1,6),36)">
}
// -----

// CHECK-LABEL: func.func @CG_TEST_lp_composed
func.func @CG_TEST_lp_composed(
    %a: !cute.composed_layout<"(2,3):(3,1) o 2 o (3,4):(4,1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.composed_layout<"(2,3):(3,1) o 2 o ((3,4),(2,5)):((4,1),(12,24))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"(2,3):(3,1) o 2 o (3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.composed_layout<"(2,3):(3,1) o 2 o ((3,4),(2,5)):((4,1),(12,24))">
  %r = cute.logical_product(%a, %b) : (!cute.composed_layout<"(2,3):(3,1) o 2 o (3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.composed_layout<"(2,3):(3,1) o 2 o ((3,4),(2,5)):((4,1),(12,24))">
  return %r : !cute.composed_layout<"(2,3):(3,1) o 2 o ((3,4),(2,5)):((4,1),(12,24))">
}

// -----


// CHECK-LABEL: func.func @CG_TEST_scaled_basis_lhs
func.func @CG_TEST_scaled_basis_lhs(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  return %r : !cute.layout<"((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
}

// -----

// Scaled-basis lhs on composed input.
// CHECK-LABEL: func.func @CG_TEST_scaled_basis_lhs_composed_sb_in_b
func.func @CG_TEST_scaled_basis_lhs_composed_sb_in_b(
    %a: !cute.composed_layout<"(4,3):(1,4) o 0 o (4,3):(1@0,1@1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.composed_layout<"(4,3):(1,4) o 0 o ((4,3),(2,5)):((1@0,1@1),(3@1,6@1))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"(4,3):(1,4) o 0 o (4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.composed_layout<"(4,3):(1,4) o 0 o ((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  %r = cute.logical_product(%a, %b) : (!cute.composed_layout<"(4,3):(1,4) o 0 o (4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.composed_layout<"(4,3):(1,4) o 0 o ((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
  return %r : !cute.composed_layout<"(4,3):(1,4) o 0 o ((4,3),(2,5)):((1@0,1@1),(3@1,6@1))">
}

// -----

// Scaled-basis lhs on composed input
// CHECK-LABEL: func.func @CG_TEST_scaled_basis_lhs_composed_sb_in_a
func.func @CG_TEST_scaled_basis_lhs_composed_sb_in_a(
    %a: !cute.composed_layout<"(4,3):(1@0,1@1) o (1,1) o (4,3):(1,4)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.composed_layout<"(4,3):(1@0,1@1) o (1,1) o ((4,3),(2,5)):((1,4),(12,24))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"(4,3):(1@0,1@1) o (1,1) o (4,3):(1,4)">, !cute.layout<"(2,5):(1,2)">) -> !cute.composed_layout<"(4,3):(1@0,1@1) o (1,1) o ((4,3),(2,5)):((1,4),(12,24))">
  %r = cute.logical_product(%a, %b) : (!cute.composed_layout<"(4,3):(1@0,1@1) o (1,1) o (4,3):(1,4)">, !cute.layout<"(2,5):(1,2)">) -> !cute.composed_layout<"(4,3):(1@0,1@1) o (1,1) o ((4,3),(2,5)):((1,4),(12,24))">
  return %r : !cute.composed_layout<"(4,3):(1@0,1@1) o (1,1) o ((4,3),(2,5)):((1,4),(12,24))">
}

// -----

// Scaled-basis lhs with mixed-multiplier SB strides
// CHECK-LABEL: func.func @CG_TEST_scaled_basis_lhs_mixed
func.func @CG_TEST_scaled_basis_lhs_mixed(
    %a: !cute.layout<"(4,3):(2@0,1@1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((4,3),(2,5)):((2@0,1@1),(1@0,3@1))"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(2@0,1@1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.layout<"((4,3),(2,5)):((2@0,1@1),(1@0,3@1))">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"(4,3):(2@0,1@1)">, !cute.layout<"(2,5):(1,2)">) -> !cute.layout<"((4,3),(2,5)):((2@0,1@1),(1@0,3@1))">
  return %r : !cute.layout<"((4,3),(2,5)):((2@0,1@1),(1@0,3@1))">
}

// -----

// Rank-1 lhs with a single scaled-basis stride against a rank-1 rhs.
// CHECK-LABEL: func.func @CG_TEST_scaled_basis_lhs_rank1
func.func @CG_TEST_scaled_basis_lhs_rank1(
    %a: !cute.layout<"4:1@0">,
    %b: !cute.layout<"3:1">)
    -> !cute.layout<"(4,3):(1@0,4@0)"> {
  // CHECK: cute.logical_product(%{{.+}}, %{{.+}}) : (!cute.layout<"4:1@0">, !cute.layout<"3:1">) -> !cute.layout<"(4,3):(1@0,4@0)">
  %r = cute.logical_product(%a, %b) : (!cute.layout<"4:1@0">, !cute.layout<"3:1">) -> !cute.layout<"(4,3):(1@0,4@0)">
  return %r : !cute.layout<"(4,3):(1@0,4@0)">
}

