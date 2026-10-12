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

// Tests `cute-expand-ops` lowering for `cute.get_shape`. Three input
// variants: layout, composed_layout, tile.

// -----

// CHECK-LABEL: func.func @expand_layout_static
// CHECK-NOT:   cute.get_shape
// CHECK:       cute.static : !cute.shape<"(4,8)">
func.func @expand_layout_static(%l: !cute.layout<"(4,8):(1,4)">)
    -> !cute.shape<"(4,8)"> {
  %r = cute.get_shape(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.shape<"(4,8)">
  return %r : !cute.shape<"(4,8)">
}

// -----

// CHECK-LABEL: func.func @expand_layout_dynamic
// CHECK-NOT:   cute.get_shape
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[S:.+]] = cute.make_shape
// CHECK-SAME:            -> !cute.shape<"(?,4)">
func.func @expand_layout_dynamic(%l: !cute.layout<"(?,4):(1,?)">)
    -> !cute.shape<"(?,4)"> {
  %r = cute.get_shape(%l) : !cute.layout<"(?,4):(1,?)"> -> !cute.shape<"(?,4)">
  return %r : !cute.shape<"(?,4)">
}

// -----

// Nested-shape layout with dynamic leaves at multiple depths — mirrors
// the `get_stride` `expand_nested_dynamic` case for symmetry. The dyn
// branch is the same code path as flat layouts (`cg::shape()` doesn't
// distinguish), but locking the nested case keeps the matrix complete.
// CHECK-LABEL: func.func @expand_layout_nested_dynamic
// CHECK-NOT:   cute.get_shape
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[S:.+]] = cute.make_shape
// CHECK-SAME:            -> !cute.shape<"((?,3),4)">
func.func @expand_layout_nested_dynamic(%l: !cute.layout<"((?,3),4):((1,?),?)">)
    -> !cute.shape<"((?,3),4)"> {
  %r = cute.get_shape(%l)
         : !cute.layout<"((?,3),4):((1,?),?)"> -> !cute.shape<"((?,3),4)">
  return %r : !cute.shape<"((?,3),4)">
}

// -----

// CHECK-LABEL: func.func @expand_composed_layout_static
// CHECK-NOT:   cute.get_shape
// CHECK:       cute.static : !cute.shape<"(8,4)">
func.func @expand_composed_layout_static(
    %cl: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">)
    -> !cute.shape<"(8,4)"> {
  %r = cute.get_shape(%cl)
         : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
        -> !cute.shape<"(8,4)">
  return %r : !cute.shape<"(8,4)">
}

// -----

// CHECK-LABEL: func.func @expand_composed_layout_dynamic
// CHECK-NOT:   cute.get_shape
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[S:.+]] = cute.make_shape
// CHECK-SAME:            -> !cute.shape<"(?,4)">
func.func @expand_composed_layout_dynamic(
    %cl: !cute.composed_layout<"S<3,5,4> o 0 o (?,4):(1,?)">)
    -> !cute.shape<"(?,4)"> {
  %r = cute.get_shape(%cl)
         : !cute.composed_layout<"S<3,5,4> o 0 o (?,4):(1,?)">
        -> !cute.shape<"(?,4)">
  return %r : !cute.shape<"(?,4)">
}

// -----

// CHECK-LABEL: func.func @expand_tile_static
// CHECK-NOT:   cute.get_shape
// CHECK:       cute.static : !cute.shape<"((4,8),(2,3))">
func.func @expand_tile_static(%t: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
    -> !cute.shape<"((4,8),(2,3))"> {
  %r = cute.get_shape(%t)
         : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
        -> !cute.shape<"((4,8),(2,3))">
  return %r : !cute.shape<"((4,8),(2,3))">
}

// -----

// Dynamic tile: shape is rebuilt from get_scalars + make_shape.
// CHECK-LABEL: func.func @expand_tile_dynamic
// CHECK-NOT:   cute.get_shape
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[S:.+]] = cute.make_shape
// CHECK-SAME:            -> !cute.shape<"((?,3),(?,2))">
func.func @expand_tile_dynamic(%t: !cute.tile<"[(?,3):(1,?);(?,2):(1,?)]">)
    -> !cute.shape<"((?,3),(?,2))"> {
  %r = cute.get_shape(%t)
         : !cute.tile<"[(?,3):(1,?);(?,2):(1,?)]">
        -> !cute.shape<"((?,3),(?,2))">
  return %r : !cute.shape<"((?,3),(?,2))">
}

