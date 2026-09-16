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

// Tests `cute-expand-ops` lowering for `cute.tiled_product`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.tiled_product
// CHECK:       cute.static
func.func @expand_static(%a: !cute.layout<"(3,4):(4,1)">,
                          %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((3,4),2,5):((4,1),12,24)"> {
  %r = cute.tiled_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((3,4),2,5):((4,1),12,24)">
  return %r : !cute.layout<"((3,4),2,5):((4,1),12,24)">
}

// -----

// Composed-layout input — wrap preserved.
// CHECK-LABEL: func.func @expand_composed_static
// CHECK-NOT:   cute.tiled_product
// CHECK:       cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),2,5):((4,1),20,40)">
func.func @expand_composed_static(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),2,5):((4,1),20,40)"> {
  %r = cute.tiled_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4):(4,1)">,
            !cute.layout<"(2,5):(1,2)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),2,5):((4,1),20,40)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((5,4),2,5):((4,1),20,40)">
}

// -----

// Static input × dynamic tiler → rebuild via `cute.make_layout`.
// CHECK-LABEL: func.func @expand_dyn_tiler
// CHECK-NOT:   cute.tiled_product
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"((3,4),?,?):((4,1),12,24)">
func.func @expand_dyn_tiler(%a: !cute.layout<"(3,4):(4,1)">,
                             %b: !cute.layout<"(?,?):(1,2)">)
    -> !cute.layout<"((3,4),?,?):((4,1),12,24)"> {
  %r = cute.tiled_product(%a, %b)
         : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
        -> !cute.layout<"((3,4),?,?):((4,1),12,24)">
  return %r : !cute.layout<"((3,4),?,?):((4,1),12,24)">
}

// -----

// Higher-rank inputs: rank-3 × rank-3, all static → folds.
// CHECK-LABEL: func.func @expand_rank3
// CHECK-NOT:   cute.tiled_product
// CHECK:       cute.static : !cute.layout<"((3,4,2),2,3,5):((8,2,1),24,48,144)">
func.func @expand_rank3(%a: !cute.layout<"(3,4,2):(8,2,1)">,
                         %b: !cute.layout<"(2,3,5):(1,2,6)">)
    -> !cute.layout<"((3,4,2),2,3,5):((8,2,1),24,48,144)"> {
  %r = cute.tiled_product(%a, %b)
         : (!cute.layout<"(3,4,2):(8,2,1)">, !cute.layout<"(2,3,5):(1,2,6)">)
        -> !cute.layout<"((3,4,2),2,3,5):((8,2,1),24,48,144)">
  return %r : !cute.layout<"((3,4,2),2,3,5):((8,2,1),24,48,144)">
}

// -----

// Higher-rank composed: rank-3 composed × rank-3 tiler, swizzle and offset preserved.
// CHECK-LABEL: func.func @expand_rank3_composed
// CHECK-NOT:   cute.tiled_product
// CHECK:       cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),2,3,5):((8,2,1),40,80,240)">
func.func @expand_rank3_composed(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (5,4,2):(8,2,1)">,
    %b: !cute.layout<"(2,3,5):(1,2,6)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),2,3,5):((8,2,1),40,80,240)"> {
  %r = cute.tiled_product(%a, %b)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (5,4,2):(8,2,1)">,
            !cute.layout<"(2,3,5):(1,2,6)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),2,3,5):((8,2,1),40,80,240)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((5,4,2),2,3,5):((8,2,1),40,80,240)">
}

// -----

// Composed input with dyn outer + static B × dyn tiler.
// CHECK-LABEL: func.func @expand_composed_dyn_outer_dyn_tiler
// CHECK-NOT:   cute.tiled_product
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  o ((5,4),?,?):((4,1),?,?)
func.func @expand_composed_dyn_outer_dyn_tiler(
    %a: !cute.composed_layout<"(?):(?) o ? o (5,4):(4,1)">,
    %b: !cute.layout<"(?,?):(?,?)">)
    -> !cute.composed_layout<"(?):(?) o ? o ((5,4),?,?):((4,1),?,?)"> {
  %r = cute.tiled_product(%a, %b)
         : (!cute.composed_layout<"(?):(?) o ? o (5,4):(4,1)">,
            !cute.layout<"(?,?):(?,?)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((5,4),?,?):((4,1),?,?)">
  return %r : !cute.composed_layout<"(?):(?) o ? o ((5,4),?,?):((4,1),?,?)">
}

// -----

// Scaled-basis input × static tiler → folds to `cute.static`.
// CHECK-LABEL: func.func @expand_scaled_basis_lhs
// CHECK-NOT:   cute.tiled_product
// CHECK:       cute.static : !cute.layout<"((4,3),2,5):((1@0,1@1),3@1,6@1)">
func.func @expand_scaled_basis_lhs(
    %a: !cute.layout<"(4,3):(1@0,1@1)">,
    %b: !cute.layout<"(2,5):(1,2)">)
    -> !cute.layout<"((4,3),2,5):((1@0,1@1),3@1,6@1)"> {
  %r = cute.tiled_product(%a, %b)
         : (!cute.layout<"(4,3):(1@0,1@1)">, !cute.layout<"(2,5):(1,2)">)
        -> !cute.layout<"((4,3),2,5):((1@0,1@1),3@1,6@1)">
  return %r : !cute.layout<"((4,3),2,5):((1@0,1@1),3@1,6@1)">
}

