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
// Tests round-trip for cute.logical_divide.
// Tiler may be !cute.layout, !cute.tile, or !cute.shape.
// -----
// Layout × shape tiler.
// CHECK-LABEL: func.func @logical_divide_layout_shape
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(6,8):(8,1)">, %[[B:.+]]: !cute.shape<"(3,4)">)
func.func @logical_divide_layout_shape(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.shape<"(3,4)">) -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))"> {
  // CHECK: %[[R:.+]] = cute.logical_divide(%[[A]], %[[B]]) : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
  return %r : !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
}
// -----
// Layout × layout tiler.
// CHECK-LABEL: func.func @logical_divide_layout_layout
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(6,8):(8,1)">, %[[B:.+]]: !cute.layout<"(3,4):(1,3)">)
func.func @logical_divide_layout_layout(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)"> {
  // CHECK: %[[R:.+]] = cute.logical_divide(%[[A]], %[[B]]) : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
}
// -----
// Layout × tile tiler.
// CHECK-LABEL: func.func @logical_divide_layout_tile
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(6,8):(8,1)">, %[[B:.+]]: !cute.tile<"[(3):(1);(4):(1)]">)
func.func @logical_divide_layout_tile(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))"> {
  // CHECK: %[[R:.+]] = cute.logical_divide(%[[A]], %[[B]]) : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))">
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))">
  return %r : !cute.layout<"(((3),2),((4),2)):(((8),24),((1),4))">
}
// -----
// ComposedLayout × shape tiler — result kind matches input kind.
// CHECK-LABEL: func.func @logical_divide_composed_shape
func.func @logical_divide_composed_shape(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.shape<"(3,4)">) {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">
  %r = cute.logical_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
            !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(4,2)):((8,24),(1,4))">
  return
}
// -----
// ComposedLayout × layout tiler.
// CHECK-LABEL: func.func @logical_divide_composed_layout
func.func @logical_divide_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">) {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  %r = cute.logical_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
            !cute.layout<"(3,4):(1,3)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  return
}
// -----
// ComposedLayout × tile tiler.
// CHECK-LABEL: func.func @logical_divide_composed_tile
func.func @logical_divide_composed_tile(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">) {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),2),((4),2)):(((8),24),((1),4))">
  %r = cute.logical_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
            !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),2),((4),2)):(((8),24),((1),4))">
  return
}
// -----
// Fully-dyn input × shape tiler.
// CHECK-LABEL: func.func @logical_divide_dyn_input_shape
func.func @logical_divide_dyn_input_shape(
    %a: !cute.layout<"(?,?):(?,?)">,
    %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,?),(4,?)):((?,?),(?,?))"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(?,?):(?,?)">, !cute.shape<"(3,4)">) -> !cute.layout<"((3,?),(4,?)):((?,?),(?,?))">
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,?),(4,?)):((?,?),(?,?))">
  return %r : !cute.layout<"((3,?),(4,?)):((?,?),(?,?))">
}
// -----
// Fully-dyn input × layout tiler.
// CHECK-LABEL: func.func @logical_divide_dyn_input_layout
func.func @logical_divide_dyn_input_layout(
    %a: !cute.layout<"(?,?):(?,?)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.layout<"(((?,?),(?,?)),((?,?),(?,?))):(((?,?),(?,?)),((?,?),(?,?)))"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<{{.+}}>
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"(((?,?),(?,?)),((?,?),(?,?))):(((?,?),(?,?)),((?,?),(?,?)))">
  return %r : !cute.layout<"(((?,?),(?,?)),((?,?),(?,?))):(((?,?),(?,?)),((?,?),(?,?)))">
}
// -----
// Fully-dyn input × tile tiler — per-mode dispatch on the dyn input.
// CHECK-LABEL: func.func @logical_divide_dyn_input_tile
func.func @logical_divide_dyn_input_tile(
    %a: !cute.layout<"(?,?):(?,?)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.layout<"(((3),?),((4),?)):(((?),?),((?),?))"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(?,?):(?,?)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<{{.+}}>
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),?),((4),?)):(((?),?),((?),?))">
  return %r : !cute.layout<"(((3),?),((4),?)):(((?),?),((?),?))">
}
// -----
// Scaled-basis input × shape tiler.
// CHECK-LABEL: func.func @logical_divide_scaled_basis_input_shape
func.func @logical_divide_scaled_basis_input_shape(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.shape<"(2,3)">)
    -> !cute.layout<"((2,2),(3,1)):((1@0,2@0),(1@1,3@1))"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"((2,2),(3,1)):((1@0,2@0),(1@1,3@1))">
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">)
        -> !cute.layout<"((2,2),(3,1)):((1@0,2@0),(1@1,3@1))">
  return %r : !cute.layout<"((2,2),(3,1)):((1@0,2@0),(1@1,3@1))">
}
// -----
// Scaled-basis input × tile tiler.
// CHECK-LABEL: func.func @logical_divide_scaled_basis_input_tile
func.func @logical_divide_scaled_basis_input_tile(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.tile<"[(2):(1);(3):(1)]">)
    -> !cute.layout<"(((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"(((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))">
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">)
        -> !cute.layout<"(((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))">
  return %r : !cute.layout<"(((2),2),((3),1)):(((1@0),2@0),((1@1),3@1))">
}
// -----
// Scaled-basis input × scaled-basis layout tiler.
// CHECK-LABEL: func.func @logical_divide_scaled_basis_layout_tiler
func.func @logical_divide_scaled_basis_layout_tiler(
    %a: !cute.layout<"(128,64):(1@1,1@0)">,
    %b: !cute.layout<"2:64@0">)
    -> !cute.layout<"(2,(64,64)):(64@1,(1@1,1@0))"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(128,64):(1@1,1@0)">, !cute.layout<"2:64@0">) -> !cute.layout<"(2,(64,64)):(64@1,(1@1,1@0))">
  %r = cute.logical_divide(%a, %b)
         : (!cute.layout<"(128,64):(1@1,1@0)">, !cute.layout<"2:64@0">)
        -> !cute.layout<"(2,(64,64)):(64@1,(1@1,1@0))">
  return %r : !cute.layout<"(2,(64,64)):(64@1,(1@1,1@0))">
}
// -----
// Composed input with dyn outer + static B × shape tiler.
// CHECK-LABEL: func.func @logical_divide_composed_dyn_outer_shape
func.func @logical_divide_composed_dyn_outer_shape(
    %a: !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
    %b: !cute.shape<"(3,4)">)
    -> !cute.composed_layout<"(?):(?) o ? o ((3,2),(4,2)):((8,24),(1,4))"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"(?):(?) o ? o ((3,2),(4,2)):((8,24),(1,4))">
  %r = cute.logical_divide(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
            !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((3,2),(4,2)):((8,24),(1,4))">
  return %r : !cute.composed_layout<"(?):(?) o ? o ((3,2),(4,2)):((8,24),(1,4))">
}
// -----
// Composed input with dyn outer + static B × layout tiler.
// CHECK-LABEL: func.func @logical_divide_composed_dyn_outer_layout
func.func @logical_divide_composed_dyn_outer_layout(
    %a: !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">
  %r = cute.logical_divide(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
            !cute.layout<"(3,4):(1,3)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">
}
// -----
// Composed input with dyn outer + static B × tile tiler.
// CHECK-LABEL: func.func @logical_divide_composed_dyn_outer_tile
func.func @logical_divide_composed_dyn_outer_tile(
    %a: !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.composed_layout<"(?):(?) o ? o (((3),2),((4),2)):(((8),24),((1),4))"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"(?):(?) o ? o (((3),2),((4),2)):(((8),24),((1),4))">
  %r = cute.logical_divide(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
            !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.composed_layout<"(?):(?) o ? o (((3),2),((4),2)):(((8),24),((1),4))">
  return %r : !cute.composed_layout<"(?):(?) o ? o (((3),2),((4),2)):(((8),24),((1),4))">
}
// -----
// 1:0 / 1:0
// CHECK-LABEL: func.func @CG_TEST_logical_divide_1_0_div_1_0
func.func @CG_TEST_logical_divide_1_0_div_1_0(
    %a: !cute.layout<"1:0">, %b: !cute.layout<"1:0">) -> !cute.layout<"(1,1):(0,0)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.layout<"1:0">) -> !cute.layout<"(1,1):(0,0)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"1:0">, !cute.layout<"1:0">) -> !cute.layout<"(1,1):(0,0)">
  return %r : !cute.layout<"(1,1):(0,0)">
}
// -----
// 1:0 / 1:1
// CHECK-LABEL: func.func @CG_TEST_logical_divide_1_0_div_1_1
func.func @CG_TEST_logical_divide_1_0_div_1_1(
    %a: !cute.layout<"1:0">, %b: !cute.layout<"1:1">) -> !cute.layout<"(1,1):(0,0)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"1:0">, !cute.layout<"1:1">) -> !cute.layout<"(1,1):(0,0)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"1:0">, !cute.layout<"1:1">) -> !cute.layout<"(1,1):(0,0)">
  return %r : !cute.layout<"(1,1):(0,0)">
}
// -----
// 1:1 / 1:0
// CHECK-LABEL: func.func @CG_TEST_logical_divide_1_1_div_1_0
func.func @CG_TEST_logical_divide_1_1_div_1_0(
    %a: !cute.layout<"1:1">, %b: !cute.layout<"1:0">) -> !cute.layout<"(1,1):(0,1)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.layout<"1:0">) -> !cute.layout<"(1,1):(0,1)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"1:1">, !cute.layout<"1:0">) -> !cute.layout<"(1,1):(0,1)">
  return %r : !cute.layout<"(1,1):(0,1)">
}
// -----
// 1:1 / 1:1
// CHECK-LABEL: func.func @CG_TEST_logical_divide_1_1_div_1_1
func.func @CG_TEST_logical_divide_1_1_div_1_1(
    %a: !cute.layout<"1:1">, %b: !cute.layout<"1:1">) -> !cute.layout<"(1,1):(1,1)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"1:1">, !cute.layout<"1:1">) -> !cute.layout<"(1,1):(1,1)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"1:1">, !cute.layout<"1:1">) -> !cute.layout<"(1,1):(1,1)">
  return %r : !cute.layout<"(1,1):(1,1)">
}
// -----
// 6:1 / 2:1
// CHECK-LABEL: func.func @CG_TEST_logical_divide_6_1_div_2_1
func.func @CG_TEST_logical_divide_6_1_div_2_1(
    %a: !cute.layout<"6:1">, %b: !cute.layout<"2:1">) -> !cute.layout<"(2,3):(1,2)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"6:1">, !cute.layout<"2:1">) -> !cute.layout<"(2,3):(1,2)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"6:1">, !cute.layout<"2:1">) -> !cute.layout<"(2,3):(1,2)">
  return %r : !cute.layout<"(2,3):(1,2)">
}
// -----
// 6:2 / 2:3
// CHECK-LABEL: func.func @CG_TEST_logical_divide_6_2_div_2_3
func.func @CG_TEST_logical_divide_6_2_div_2_3(
    %a: !cute.layout<"6:2">, %b: !cute.layout<"2:3">) -> !cute.layout<"(2,3):(6,2)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"6:2">, !cute.layout<"2:3">) -> !cute.layout<"(2,3):(6,2)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"6:2">, !cute.layout<"2:3">) -> !cute.layout<"(2,3):(6,2)">
  return %r : !cute.layout<"(2,3):(6,2)">
}
// -----
// 6:2 / (2,3):(3,1) — rank-2 tile against rank-1 layout.
// CHECK-LABEL: func.func @CG_TEST_logical_divide_6_2_div_2_3_rank2_tile
func.func @CG_TEST_logical_divide_6_2_div_2_3_rank2_tile(
    %a: !cute.layout<"6:2">, %b: !cute.layout<"(2,3):(3,1)">) -> !cute.layout<"((2,3),1):((6,2),12)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"6:2">, !cute.layout<"(2,3):(3,1)">) -> !cute.layout<"((2,3),1):((6,2),12)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"6:2">, !cute.layout<"(2,3):(3,1)">) -> !cute.layout<"((2,3),1):((6,2),12)">
  return %r : !cute.layout<"((2,3),1):((6,2),12)">
}
// -----
// (6,6):(12,1) / (6,3):(3,1)
// CHECK-LABEL: func.func @CG_TEST_logical_divide_6_6_12_1_div_6_3_3_1
func.func @CG_TEST_logical_divide_6_6_12_1_div_6_3_3_1(
    %a: !cute.layout<"(6,6):(12,1)">, %b: !cute.layout<"(6,3):(3,1)">) -> !cute.layout<"(((2,3),3),2):(((36,1),12),3)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(6,6):(12,1)">, !cute.layout<"(6,3):(3,1)">) -> !cute.layout<"(((2,3),3),2):(((36,1),12),3)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"(6,6):(12,1)">, !cute.layout<"(6,3):(3,1)">) -> !cute.layout<"(((2,3),3),2):(((36,1),12),3)">
  return %r : !cute.layout<"(((2,3),3),2):(((36,1),12),3)">
}
// -----
// (6,6):(1,12) / (6,3):(3,1)
// CHECK-LABEL: func.func @CG_TEST_logical_divide_6_6_1_12_div_6_3_3_1
func.func @CG_TEST_logical_divide_6_6_1_12_div_6_3_3_1(
    %a: !cute.layout<"(6,6):(1,12)">, %b: !cute.layout<"(6,3):(3,1)">) -> !cute.layout<"(((2,3),3),2):(((3,12),1),36)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(6,6):(1,12)">, !cute.layout<"(6,3):(3,1)">) -> !cute.layout<"(((2,3),3),2):(((3,12),1),36)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"(6,6):(1,12)">, !cute.layout<"(6,3):(3,1)">) -> !cute.layout<"(((2,3),3),2):(((3,12),1),36)">
  return %r : !cute.layout<"(((2,3),3),2):(((3,12),1),36)">
}
// -----
// 32:1 / 2:8 (default stride 1).
// CHECK-LABEL: func.func @CG_TEST_logical_divide_32_1_div_2_8
func.func @CG_TEST_logical_divide_32_1_div_2_8(
    %a: !cute.layout<"32:1">, %b: !cute.layout<"2:8">) -> !cute.layout<"(2,(8,2)):(8,(1,16))"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"32:1">, !cute.layout<"2:8">) -> !cute.layout<"(2,(8,2)):(8,(1,16))">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"32:1">, !cute.layout<"2:8">) -> !cute.layout<"(2,(8,2)):(8,(1,16))">
  return %r : !cute.layout<"(2,(8,2)):(8,(1,16))">
}
// -----
// (4,1):(1,1) / 2:1
// CHECK-LABEL: func.func @CG_TEST_logical_divide_4_1_1_1_div_2_1
func.func @CG_TEST_logical_divide_4_1_1_1_div_2_1(
    %a: !cute.layout<"(4,1):(1,1)">, %b: !cute.layout<"2:1">) -> !cute.layout<"(2,2):(1,2)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,1):(1,1)">, !cute.layout<"2:1">) -> !cute.layout<"(2,2):(1,2)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"(4,1):(1,1)">, !cute.layout<"2:1">) -> !cute.layout<"(2,2):(1,2)">
  return %r : !cute.layout<"(2,2):(1,2)">
}
// -----
// (4,1):(1,1) / 2:2
// CHECK-LABEL: func.func @CG_TEST_logical_divide_4_1_1_1_div_2_2
func.func @CG_TEST_logical_divide_4_1_1_1_div_2_2(
    %a: !cute.layout<"(4,1):(1,1)">, %b: !cute.layout<"2:2">) -> !cute.layout<"(2,2):(2,1)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,1):(1,1)">, !cute.layout<"2:2">) -> !cute.layout<"(2,2):(2,1)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"(4,1):(1,1)">, !cute.layout<"2:2">) -> !cute.layout<"(2,2):(2,1)">
  return %r : !cute.layout<"(2,2):(2,1)">
}
// -----
// (8,8):(1,8) / 32:2
// CHECK-LABEL: func.func @CG_TEST_logical_divide_8_8_1_8_div_32_2
func.func @CG_TEST_logical_divide_8_8_1_8_div_32_2(
    %a: !cute.layout<"(8,8):(1,8)">, %b: !cute.layout<"32:2">) -> !cute.layout<"(32,2):(2,1)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,8):(1,8)">, !cute.layout<"32:2">) -> !cute.layout<"(32,2):(2,1)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"(8,8):(1,8)">, !cute.layout<"32:2">) -> !cute.layout<"(32,2):(2,1)">
  return %r : !cute.layout<"(32,2):(2,1)">
}
// -----
// (8,8):(8,1) / 32:2
// CHECK-LABEL: func.func @CG_TEST_logical_divide_8_8_8_1_div_32_2
func.func @CG_TEST_logical_divide_8_8_8_1_div_32_2(
    %a: !cute.layout<"(8,8):(8,1)">, %b: !cute.layout<"32:2">) -> !cute.layout<"((4,8),2):((16,1),8)"> {
  // CHECK: cute.logical_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,8):(8,1)">, !cute.layout<"32:2">) -> !cute.layout<"((4,8),2):((16,1),8)">
  %r = cute.logical_divide(%a, %b) : (!cute.layout<"(8,8):(8,1)">, !cute.layout<"32:2">) -> !cute.layout<"((4,8),2):((16,1),8)">
  return %r : !cute.layout<"((4,8),2):((16,1),8)">
}
