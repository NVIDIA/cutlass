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

// RUN: cute-opt -cute-expand-ops --split-input-file %s | FileCheck %s

// Tests `cute-expand-ops` lowering for `cute.tiled_divide`.

// -----

// Static, shape tiler.
// CHECK-LABEL: func.func @expand_static_shape_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.static
func.func @expand_static_shape_tiler(%a: !cute.layout<"(6,8):(8,1)">,
                                      %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,4),2,2):((8,1),24,4)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),2,2):((8,1),24,4)">
  return %r : !cute.layout<"((3,4),2,2):((8,1),24,4)">
}

// -----

// Static, tile tiler.
// CHECK-LABEL: func.func @expand_static_tile_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.static
func.func @expand_static_tile_tiler(%a: !cute.layout<"(6,8):(8,1)">,
                                     %b: !cute.tile<"[3:1;4:1]">)
    -> !cute.layout<"((3,4),2,2):((8,1),24,4)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.tile<"[3:1;4:1]">)
        -> !cute.layout<"((3,4),2,2):((8,1),24,4)">
  return %r : !cute.layout<"((3,4),2,2):((8,1),24,4)">
}

// -----

// Composed-layout input — wrap preserved.
// CHECK-LABEL: func.func @expand_composed_static
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
func.func @expand_composed_static(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
    %b: !cute.shape<"(3,4)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">,
            !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,4),2,2):((8,1),24,4)">
}

// -----

// CHECK-LABEL: func.func @expand_static_layout_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.static : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
func.func @expand_static_layout_tiler(%a: !cute.layout<"(6,8):(8,1)">, %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.layout<"((3,(2,2)),4):((8,(24,1)),2)">
}

// -----

// CHECK-LABEL: func.func @expand_dynamic
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
func.func @expand_dynamic(%a: !cute.layout<"(?,?):(?,?)">, %b: !cute.shape<"(3,4)">)
    -> !cute.layout<"((3,4),?,?):((?,?),?,?)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.shape<"(3,4)">) -> !cute.layout<"((3,4),?,?):((?,?),?,?)">
  return %r : !cute.layout<"((3,4),?,?):((?,?),?,?)">
}

// -----

// CHECK-LABEL: func.func @expand_composed_static_layout_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
func.func @expand_composed_static_layout_tiler(%a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,(2,2)),4):((8,(24,1)),2)">
}

// -----

// CHECK-LABEL: func.func @expand_composed_static_tile_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.static : !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)">
func.func @expand_composed_static_tile_tiler(%a: !cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o (((3),(4)),2,2):(((8),(1)),24,4)">
}

// -----

// CHECK-LABEL: func.func @expand_dynamic_layout_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
func.func @expand_dynamic_layout_tiler(%a: !cute.layout<"(?,?):(?,?)">, %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.layout<"(((?,?),(?,?)),(?,?),(?,?)):(((?,?),(?,?)),(?,?),(?,?))"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(3,4):(1,3)">) -> !cute.layout<"(((?,?),(?,?)),(?,?),(?,?)):(((?,?),(?,?)),(?,?),(?,?))">
  return %r : !cute.layout<"(((?,?),(?,?)),(?,?),(?,?)):(((?,?),(?,?)),(?,?),(?,?))">
}

// -----

// CHECK-LABEL: func.func @expand_dynamic_tile_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
func.func @expand_dynamic_tile_tiler(%a: !cute.layout<"(?,?):(?,?)">, %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.layout<"(((3),(4)),?,?):(((?),(?)),?,?)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(?,?):(?,?)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.layout<"(((3),(4)),?,?):(((?),(?)),?,?)">
  return %r : !cute.layout<"(((3),(4)),?,?):(((?),(?)),?,?)">
}

// -----

// CHECK-LABEL: func.func @expand_scaled_basis_input_shape_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.static : !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">
func.func @expand_scaled_basis_input_shape_tiler(%a: !cute.layout<"(4,3):(1@0,1@1)">, %b: !cute.shape<"(2,3)">)
    -> !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.shape<"(2,3)">) -> !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">
  return %r : !cute.layout<"((2,3),2,1):((1@0,1@1),2@0,3@1)">
}

// -----

// CHECK-LABEL: func.func @expand_scaled_basis_input_tile_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.static : !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">
func.func @expand_scaled_basis_input_tile_tiler(%a: !cute.layout<"(4,3):(1@0,1@1)">, %b: !cute.tile<"[(2):(1);(3):(1)]">)
    -> !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.tile<"[(2):(1);(3):(1)]">) -> !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">
  return %r : !cute.layout<"(((2),(3)),2,1):(((1@0),(1@1)),2@0,3@1)">
}

// -----

// CHECK-LABEL: func.func @expand_composed_dyn_outer_shape_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.make_composed_layout
func.func @expand_composed_dyn_outer_shape_tiler(%a: !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, %b: !cute.shape<"(3,4)">)
    -> !cute.composed_layout<"(?):(?) o ? o ((3,4),2,2):((8,1),24,4)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.shape<"(3,4)">) -> !cute.composed_layout<"(?):(?) o ? o ((3,4),2,2):((8,1),24,4)">
  return %r : !cute.composed_layout<"(?):(?) o ? o ((3,4),2,2):((8,1),24,4)">
}

// -----

// CHECK-LABEL: func.func @expand_composed_dyn_outer_layout_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.make_composed_layout
func.func @expand_composed_dyn_outer_layout_tiler(%a: !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, %b: !cute.layout<"(3,4):(1,3)">)
    -> !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">) -> !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">
  return %r : !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">
}

// -----

// CHECK-LABEL: func.func @expand_composed_dyn_outer_tile_tiler
// CHECK-NOT:   cute.tiled_divide
// CHECK:       cute.make_composed_layout
func.func @expand_composed_dyn_outer_tile_tiler(%a: !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, %b: !cute.tile<"[(3):(1);(4):(1)]">)
    -> !cute.composed_layout<"(?):(?) o ? o (((3),(4)),2,2):(((8),(1)),24,4)"> {
  %r = cute.tiled_divide(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">) -> !cute.composed_layout<"(?):(?) o ? o (((3),(4)),2,2):(((8),(1)),24,4)">
  return %r : !cute.composed_layout<"(?):(?) o ? o (((3),(4)),2,2):(((8),(1)),24,4)">
}
