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

// Tests round-trip for cute.tiled_divide.
// Tiler may be !cute.layout, !cute.tile, or !cute.shape.

// -----

// Layout × shape tiler.
// CHECK-LABEL: func.func @tiled_divide_layout_shape
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(6,8):(8,1)">, %[[B:.+]]: !cute.shape<"(3,4)">)
func.func @tiled_divide_layout_shape(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.shape<"(3,4)">) -> !cute.layout<"((3,4),2,2):((8,1),24,4)"> {
  // CHECK: %[[R:.+]] = cute.tiled_divide(%[[A]], %[[B]]) : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.layout<"((3,4),2,2):((8,1),24,4)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),2,2):((8,1),24,4)">
  return %r : !cute.layout<"((3,4),2,2):((8,1),24,4)">
}

// -----

// Layout × layout tiler.
// CHECK-LABEL: func.func @tiled_divide_layout_layout
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(6,8):(8,1)">, %[[B:.+]]: !cute.layout<"(3,4):(1,3)">)
func.func @tiled_divide_layout_layout(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)"> {
  // CHECK: %[[R:.+]] = cute.tiled_divide(%[[A]], %[[B]]) : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
}

// -----

// Layout × tile tiler.
// CHECK-LABEL: func.func @tiled_divide_layout_tile
// CHECK-SAME:  (%[[A:.+]]: !cute.layout<"(6,8):(8,1)">, %[[B:.+]]: !cute.tile<"[(3):(1);(4):(1)]">)
func.func @tiled_divide_layout_tile(
    %a: !cute.layout<"(6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)"> {
  // CHECK: %[[R:.+]] = cute.tiled_divide(%[[A]], %[[B]]) : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)">
  return %r : !cute.layout<"(((3),(4)),2,2):(((8),(1)),24,4)">
}

// -----

// ComposedLayout × shape tiler — result kind matches input kind.
// CHECK-LABEL: func.func @tiled_divide_composed_shape
func.func @tiled_divide_composed_shape(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.shape<"(3,4)">) {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
            !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
  return
}

// -----

// ComposedLayout × layout tiler.
// CHECK-LABEL: func.func @tiled_divide_composed_layout
func.func @tiled_divide_composed_layout(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">) {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
            !cute.layout<"(3,4):(1,3)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  return
}

// -----

// ComposedLayout × tile tiler.
// CHECK-LABEL: func.func @tiled_divide_composed_tile
func.func @tiled_divide_composed_tile(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">) {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
            !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)">
  return
}

// -----

// dyn input shape.
// CHECK-LABEL: func.func @tiled_divide_dyn_input_shape
func.func @tiled_divide_dyn_input_shape(
    %a: !cute.layout<"(?,?):(?,?)">,
    %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,4),?,?):((?,?),?,?)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(?,?):(?,?)">, !cute.shape<"(3,4)">) -> !cute.layout<"((3,4),?,?):((?,?),?,?)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),?,?):((?,?),?,?)">
  return %r : !cute.layout<"((3,4),?,?):((?,?),?,?)">
}

// -----

// dyn input layout.
// CHECK-LABEL: func.func @tiled_divide_dyn_input_layout
func.func @tiled_divide_dyn_input_layout(
    %a: !cute.layout<"(?,?):(?,?)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.layout<"(((?,?),(?,?)),(?,?),(?,?)):(((?,?),(?,?)),(?,?),(?,?))"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"(((?,?),(?,?)),(?,?),(?,?)):(((?,?),(?,?)),(?,?),(?,?))">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"(((?,?),(?,?)),(?,?),(?,?)):(((?,?),(?,?)),(?,?),(?,?))">
  return %r : !cute.layout<"(((?,?),(?,?)),(?,?),(?,?)):(((?,?),(?,?)),(?,?),(?,?))">
}

// -----

// dyn input tile.
// CHECK-LABEL: func.func @tiled_divide_dyn_input_tile
func.func @tiled_divide_dyn_input_tile(
    %a: !cute.layout<"(?,?):(?,?)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.layout<"(((3),(4)),?,?):(((?),(?)),?,?)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(?,?):(?,?)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),(4)),?,?):(((?),(?)),?,?)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),(4)),?,?):(((?),(?)),?,?)">
  return %r : !cute.layout<"(((3),(4)),?,?):(((?),(?)),?,?)">
}

// -----

// scaled basis input shape.
// CHECK-LABEL: func.func @tiled_divide_scaled_basis_input_shape
func.func @tiled_divide_scaled_basis_input_shape(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.shape<"(2,3)">)
    -> !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">)
        -> !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">
  return %r : !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">
}

// -----

// scaled basis input tile.
// CHECK-LABEL: func.func @tiled_divide_scaled_basis_input_tile
func.func @tiled_divide_scaled_basis_input_tile(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.tile<"[(2):(1);(3):(1)]">)
    -> !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">)
        -> !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">
  return %r : !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">
}

// -----

// Scaled-basis input × scaled-basis layout tiler.
// CHECK-LABEL: func.func @tiled_divide_scaled_basis_layout_tiler
func.func @tiled_divide_scaled_basis_layout_tiler(
    %a: !cute.layout<"(128,64):(1@1,1@0)">,
    %b: !cute.layout<"2:64@0">)
    -> !cute.layout<"(2,64,64):(64@1,1@1,1@0)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(128,64):(1@1,1@0)">, !cute.layout<"2:64@0">) -> !cute.layout<"(2,64,64):(64@1,1@1,1@0)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(128,64):(1@1,1@0)">, !cute.layout<"2:64@0">)
        -> !cute.layout<"(2,64,64):(64@1,1@1,1@0)">
  return %r : !cute.layout<"(2,64,64):(64@1,1@1,1@0)">
}

// -----

// composed dyn outer shape.
// CHECK-LABEL: func.func @tiled_divide_composed_dyn_outer_shape
func.func @tiled_divide_composed_dyn_outer_shape(
    %a: !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
    %b: !cute.shape<"(3,4)">)
    -> !cute.composed_layout<"(?):(?) o ? o ((3,4),2,2):((8,1),24,4)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"(?):(?) o ? o ((3,4),2,2):((8,1),24,4)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((3,4),2,2):((8,1),24,4)">
  return %r : !cute.composed_layout<"(?):(?) o ? o ((3,4),2,2):((8,1),24,4)">
}

// -----

// composed dyn outer layout.
// CHECK-LABEL: func.func @tiled_divide_composed_dyn_outer_layout
func.func @tiled_divide_composed_dyn_outer_layout(
    %a: !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
    %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">
}

// -----

// composed dyn outer tile.
// CHECK-LABEL: func.func @tiled_divide_composed_dyn_outer_tile
func.func @tiled_divide_composed_dyn_outer_tile(
    %a: !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
    %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.composed_layout<"(?):(?) o ? o (((3),(4)),2,2):(((8),(1)),24,4)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"(?):(?) o ? o (((3),(4)),2,2):(((8),(1)),24,4)">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.composed_layout<"(?):(?) o ? o (((3),(4)),2,2):(((8),(1)),24,4)">
  return %r : !cute.composed_layout<"(?):(?) o ? o (((3),(4)),2,2):(((8),(1)),24,4)">
}

// -----

// Depth-0 tile (layout wrap).
// CHECK-LABEL: func.func @CG_TEST_tiled_divide_depth0_tile
func.func @CG_TEST_tiled_divide_depth0_tile(
    %a: !cute.layout<"(8,32):(1,8)">, %b: !cute.tile<"[4:1]">) -> !cute.layout<"((4),2,32):((1),4,8)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,32):(1,8)">, !cute.tile<"[4:1]">) -> !cute.layout<"((4),2,32):((1),4,8)">
  %r = cute.tiled_divide(%a, %b) : (!cute.layout<"(8,32):(1,8)">, !cute.tile<"[4:1]">) -> !cute.layout<"((4),2,32):((1),4,8)">
  return %r : !cute.layout<"((4),2,32):((1),4,8)">
}

// -----

// Layout × shape tiler.
// CHECK-LABEL: func.func @CG_TEST_tiled_divide_layout_shape
func.func @CG_TEST_tiled_divide_layout_shape(
    %a: !cute.layout<"(8,32):(1,8)">, %b: !cute.shape<"(4,2)">) -> !cute.layout<"((4,2),2,16):((1,8),4,16)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,32):(1,8)">, !cute.shape<"(4,2)">) -> !cute.layout<"((4,2),2,16):((1,8),4,16)">
  %r = cute.tiled_divide(%a, %b) : (!cute.layout<"(8,32):(1,8)">, !cute.shape<"(4,2)">) -> !cute.layout<"((4,2),2,16):((1,8),4,16)">
  return %r : !cute.layout<"((4,2),2,16):((1,8),4,16)">
}

// -----

// Composed × shape.
// CHECK-LABEL: func.func @CG_TEST_tiled_divide_composed_shape
func.func @CG_TEST_tiled_divide_composed_shape(
    %a: !cute.composed_layout<"S<2,1,2> o 0 o (8,32):(1,8)">, %b: !cute.shape<"(4,2)">)
    -> !cute.composed_layout<"S<2,1,2> o 0 o ((4,2),2,16):((1,8),4,16)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.composed_layout<"S<2,1,2> o 0 o (8,32):(1,8)">, !cute.shape<"(4,2)">) -> !cute.composed_layout<"S<2,1,2> o 0 o ((4,2),2,16):((1,8),4,16)">
  %r = cute.tiled_divide(%a, %b) : (!cute.composed_layout<"S<2,1,2> o 0 o (8,32):(1,8)">, !cute.shape<"(4,2)">) -> !cute.composed_layout<"S<2,1,2> o 0 o ((4,2),2,16):((1,8),4,16)">
  return %r : !cute.composed_layout<"S<2,1,2> o 0 o ((4,2),2,16):((1,8),4,16)">
}

// -----

// Dyn row-major × dyn tile.
// CHECK-LABEL: func.func @CG_TEST_tiled_divide_dyn_row_major_dyn_tile
func.func @CG_TEST_tiled_divide_dyn_row_major_dyn_tile(
    %a: !cute.layout<"(?,?):(?,1)">, %b: !cute.tile<"[?:1;?:1]">) -> !cute.layout<"((?,?),?,?):((?,1),?,?)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(?,?):(?,1)">, !cute.tile<"[?:1;?:1]">) -> !cute.layout<"((?,?),?,?):((?,1),?,?)">
  %r = cute.tiled_divide(%a, %b) : (!cute.layout<"(?,?):(?,1)">, !cute.tile<"[?:1;?:1]">) -> !cute.layout<"((?,?),?,?):((?,1),?,?)">
  return %r : !cute.layout<"((?,?),?,?):((?,1),?,?)">
}

// -----

// Dyn col-major × dyn tile.
// CHECK-LABEL: func.func @CG_TEST_tiled_divide_dyn_col_major_dyn_tile
func.func @CG_TEST_tiled_divide_dyn_col_major_dyn_tile(
    %a: !cute.layout<"(?,?):(1,?)">, %b: !cute.tile<"[?:1;?:1]">) -> !cute.layout<"((?,?),?,?):((1,?),?,?)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(?,?):(1,?)">, !cute.tile<"[?:1;?:1]">) -> !cute.layout<"((?,?),?,?):((1,?),?,?)">
  %r = cute.tiled_divide(%a, %b) : (!cute.layout<"(?,?):(1,?)">, !cute.tile<"[?:1;?:1]">) -> !cute.layout<"((?,?),?,?):((1,?),?,?)">
  return %r : !cute.layout<"((?,?),?,?):((1,?),?,?)">
}

// -----

// Complex partial-dyn × static tile.
// CHECK-LABEL: func.func @CG_TEST_tiled_divide_complex_partial_dyn
func.func @CG_TEST_tiled_divide_complex_partial_dyn(
    %a: !cute.layout<"((32,4,?),(32,4,?)):((16,4,?),(0,1,512))">, %b: !cute.tile<"[128:1;32:1]">)
    -> !cute.layout<"(((32,4),32),?,(4,?)):(((16,4),0),?,(1,512))"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"((32,4,?),(32,4,?)):((16,4,?),(0,1,512))">, !cute.tile<"[128:1;32:1]">) -> !cute.layout<"(((32,4),32),?,(4,?)):(((16,4),0),?,(1,512))">
  %r = cute.tiled_divide(%a, %b) : (!cute.layout<"((32,4,?),(32,4,?)):((16,4,?),(0,1,512))">, !cute.tile<"[128:1;32:1]">) -> !cute.layout<"(((32,4),32),?,(4,?)):(((16,4),0),?,(1,512))">
  return %r : !cute.layout<"(((32,4),32),?,(4,?)):(((16,4),0),?,(1,512))">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_tiled_divide_gemm_underscore
func.func @CG_TEST_tiled_divide_gemm_underscore(
    %a: !cute.layout<"((2,(128,16)),(2,4,2)):((1,(2,256)),(4096,8192,32768))">,
    %b: !cute.tile<"[_;[2:1;1:1]]">)
    -> !cute.layout<"((2,(2,1)),(128,16),(1,4,2)):((1,(4096,8192)),(2,256),(8192,8192,32768))"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"((2,(128,16)),(2,4,2)):((1,(2,256)),(4096,8192,32768))">, !cute.tile<"[_;[2:1;1:1]]">) -> !cute.layout<"((2,(2,1)),(128,16),(1,4,2)):((1,(4096,8192)),(2,256),(8192,8192,32768))">
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"((2,(128,16)),(2,4,2)):((1,(2,256)),(4096,8192,32768))">, !cute.tile<"[_;[2:1;1:1]]">)
        -> !cute.layout<"((2,(2,1)),(128,16),(1,4,2)):((1,(4096,8192)),(2,256),(8192,8192,32768))">
  return %r : !cute.layout<"((2,(2,1)),(128,16),(1,4,2)):((1,(4096,8192)),(2,256),(8192,8192,32768))">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_tiled_divide_advanced
func.func @CG_TEST_tiled_divide_advanced(
    %a: !cute.layout<"(8,32):(1,8)">, %b: !cute.tile<"[4:1;16:2]">)
    -> !cute.layout<"((4,16),2,2):((1,16),4,8)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"(8,32):(1,8)">, !cute.tile<"[4:1;16:2]">) -> !cute.layout<"((4,16),2,2):((1,16),4,8)">
  %r = cute.tiled_divide(%a, %b) : (!cute.layout<"(8,32):(1,8)">, !cute.tile<"[4:1;16:2]">) -> !cute.layout<"((4,16),2,2):((1,16),4,8)">
  return %r : !cute.layout<"((4,16),2,2):((1,16),4,8)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_tiled_divide_rank3_broadcast_tile_layouts
func.func @CG_TEST_tiled_divide_rank3_broadcast_tile_layouts(
    %a: !cute.layout<"((8,8),(8,8),1):((512,64),(1,8),4096)">,
    %b: !cute.tile<"[128:1;128:1]">)
    -> !cute.layout<"(((8,16),128),1,1,1):(((512,64),1),1024,128,4096)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"((8,8),(8,8),1):((512,64),(1,8),4096)">, !cute.tile<"[128:1;128:1]">) -> !cute.layout<"(((8,16),128),1,1,1):(((512,64),1),1024,128,4096)">
  %r = cute.tiled_divide(%a, %b) : (!cute.layout<"((8,8),(8,8),1):((512,64),(1,8),4096)">, !cute.tile<"[128:1;128:1]">) -> !cute.layout<"(((8,16),128),1,1,1):(((512,64),1),1024,128,4096)">
  return %r : !cute.layout<"(((8,16),128),1,1,1):(((512,64),1),1024,128,4096)">
}

// -----

// CHECK-LABEL: func.func @CG_TEST_tiled_divide_rank3_broadcast_wrapped_shape
func.func @CG_TEST_tiled_divide_rank3_broadcast_wrapped_shape(
    %a: !cute.layout<"((8,8),(8,8),1):((512,64),(1,8),4096)">,
    %b: !cute.shape<"((128),(128))">)
    -> !cute.layout<"(((128),(128)),(1,8),(1,8),1):(((512),(1)),(65536,64),(128,8),4096)"> {
  // CHECK: cute.tiled_divide(%{{.+}}, %{{.+}}) : (!cute.layout<"((8,8),(8,8),1):((512,64),(1,8),4096)">, !cute.shape<"((128),(128))">) -> !cute.layout<"(((128),(128)),(1,8),(1,8),1):(((512),(1)),(65536,64),(128,8),4096)">
  %r = cute.tiled_divide(%a, %b) : (!cute.layout<"((8,8),(8,8),1):((512,64),(1,8),4096)">, !cute.shape<"((128),(128))">) -> !cute.layout<"(((128),(128)),(1,8),(1,8),1):(((512),(1)),(65536,64),(128,8),4096)">
  return %r : !cute.layout<"(((128),(128)),(1,8),(1,8),1):(((512),(1)),(65536,64),(128,8),4096)">
}
