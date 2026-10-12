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

// Tests `cute-expand-ops` lowering for `cute.get_leaves`.

// -----

// Static int_tuple: every leaf result folds to `cute.static`.
// CHECK-LABEL: func.func @expand_int_tuple_static
// CHECK-NOT:   cute.get_leaves
// CHECK-DAG:   cute.static : !cute.int_tuple<"1">
// CHECK-DAG:   cute.static : !cute.int_tuple<"2">
// CHECK-DAG:   cute.static : !cute.int_tuple<"3">
func.func @expand_int_tuple_static(%t: !cute.int_tuple<"(1,(2,3))">)
    -> (!cute.int_tuple<"1">, !cute.int_tuple<"2">, !cute.int_tuple<"3">) {
  %a, %b, %c = cute.get_leaves(%t) : !cute.int_tuple<"(1,(2,3))">
  return %a, %b, %c
      : !cute.int_tuple<"1">, !cute.int_tuple<"2">, !cute.int_tuple<"3">
}

// -----

// Dynamic int_tuple: dynamic leaves rebuild via make_int_tuple, static
// leaves fold.
// CHECK-LABEL: func.func @expand_int_tuple_dynamic
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_int_tuple
// CHECK-DAG:   cute.static : !cute.int_tuple<"3">
func.func @expand_int_tuple_dynamic(%t: !cute.int_tuple<"(?,3)">)
    -> (!cute.int_tuple<"?">, !cute.int_tuple<"3">) {
  %a, %b = cute.get_leaves(%t) : !cute.int_tuple<"(?,3)">
  return %a, %b : !cute.int_tuple<"?">, !cute.int_tuple<"3">
}

// -----

// Static shape: every leaf result folds.
// CHECK-LABEL: func.func @expand_shape_static
// CHECK-NOT:   cute.get_leaves
// CHECK-DAG:   cute.static : !cute.shape<"4">
// CHECK-DAG:   cute.static : !cute.shape<"2">
// CHECK-DAG:   cute.static : !cute.shape<"3">
func.func @expand_shape_static(%s: !cute.shape<"(4,(2,3))">)
    -> (!cute.shape<"4">, !cute.shape<"2">, !cute.shape<"3">) {
  %a, %b, %c = cute.get_leaves(%s) : !cute.shape<"(4,(2,3))">
  return %a, %b, %c : !cute.shape<"4">, !cute.shape<"2">, !cute.shape<"3">
}

// -----

// Mixed shape: static leaves fold; dynamic leaves rebuild.
// CHECK-LABEL: func.func @expand_shape_dynamic
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_shape
// CHECK-DAG:   cute.static : !cute.shape<"4">
func.func @expand_shape_dynamic(%s: !cute.shape<"(?,4)">)
    -> (!cute.shape<"?">, !cute.shape<"4">) {
  %a, %b = cute.get_leaves(%s) : !cute.shape<"(?,4)">
  return %a, %b : !cute.shape<"?">, !cute.shape<"4">
}

// -----

// Static stride.
// CHECK-LABEL: func.func @expand_stride_static
// CHECK-NOT:   cute.get_leaves
// CHECK-DAG:   cute.static : !cute.stride<"1">
// CHECK-DAG:   cute.static : !cute.stride<"4">
// CHECK-DAG:   cute.static : !cute.stride<"8">
func.func @expand_stride_static(%d: !cute.stride<"(1,(4,8))">)
    -> (!cute.stride<"1">, !cute.stride<"4">, !cute.stride<"8">) {
  %a, %b, %c = cute.get_leaves(%d) : !cute.stride<"(1,(4,8))">
  return %a, %b, %c : !cute.stride<"1">, !cute.stride<"4">, !cute.stride<"8">
}

// -----

// Dynamic stride: dynamic leaf rebuilds, static fold.
// CHECK-LABEL: func.func @expand_stride_dynamic
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_stride
// CHECK-DAG:   cute.static : !cute.stride<"4">
func.func @expand_stride_dynamic(%d: !cute.stride<"(?,4)">)
    -> (!cute.stride<"?">, !cute.stride<"4">) {
  %a, %b = cute.get_leaves(%d) : !cute.stride<"(?,4)">
  return %a, %b : !cute.stride<"?">, !cute.stride<"4">
}

// -----

// Scaled-basis stride (static): every leaf folds.
// CHECK-LABEL: func.func @expand_stride_scaled_basis_static
// CHECK-NOT:   cute.get_leaves
// CHECK-DAG:   cute.static : !cute.stride<"1@0">
// CHECK-DAG:   cute.static : !cute.stride<"1@1">
func.func @expand_stride_scaled_basis_static(%d: !cute.stride<"(1@0,1@1)">)
    -> (!cute.stride<"1@0">, !cute.stride<"1@1">) {
  %a, %b = cute.get_leaves(%d) : !cute.stride<"(1@0,1@1)">
  return %a, %b : !cute.stride<"1@0">, !cute.stride<"1@1">
}

// -----

// Scaled-basis stride (dynamic): each `?@N` leaf rebuilds via make_stride.
// CHECK-LABEL: func.func @expand_stride_scaled_basis_dynamic
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_stride
func.func @expand_stride_scaled_basis_dynamic(%d: !cute.stride<"(?@0,?@1)">)
    -> (!cute.stride<"?@0">, !cute.stride<"?@1">) {
  %a, %b = cute.get_leaves(%d) : !cute.stride<"(?@0,?@1)">
  return %a, %b : !cute.stride<"?@0">, !cute.stride<"?@1">
}

// -----

// Nested int_tuple with dynamic at the outer level: dynamic leaf rebuilds,
// inner static leaves fold.
// CHECK-LABEL: func.func @expand_int_tuple_nested_dynamic
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_int_tuple
// CHECK-DAG:   cute.static : !cute.int_tuple<"2">
// CHECK-DAG:   cute.static : !cute.int_tuple<"3">
func.func @expand_int_tuple_nested_dynamic(%i: !cute.int_tuple<"(?,(2,3))">)
    -> (!cute.int_tuple<"?">, !cute.int_tuple<"2">, !cute.int_tuple<"3">) {
  %a, %b, %c = cute.get_leaves(%i) : !cute.int_tuple<"(?,(2,3))">
  return %a, %b, %c
      : !cute.int_tuple<"?">, !cute.int_tuple<"2">, !cute.int_tuple<"3">
}

// -----

// Nested shape with dynamic mixed at multiple depths: 4 leaves
// (?, 3, 2, ?) — dynamic ones rebuild via make_shape, static ones fold.
// CHECK-LABEL: func.func @expand_shape_nested_dynamic
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_shape
// CHECK-DAG:   cute.static : !cute.shape<"3">
// CHECK-DAG:   cute.static : !cute.shape<"2">
func.func @expand_shape_nested_dynamic(%s: !cute.shape<"((?,3),(2,?))">)
    -> (!cute.shape<"?">, !cute.shape<"3">, !cute.shape<"2">,
        !cute.shape<"?">) {
  %a, %b, %c, %d = cute.get_leaves(%s) : !cute.shape<"((?,3),(2,?))">
  return %a, %b, %c, %d
      : !cute.shape<"?">, !cute.shape<"3">, !cute.shape<"2">, !cute.shape<"?">
}

// -----

// Nested scaled-basis stride (dynamic): each nested `?@N@M` leaf rebuilds.
// CHECK-LABEL: func.func @expand_stride_nested_scaled_basis_dynamic
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_stride
func.func @expand_stride_nested_scaled_basis_dynamic(
    %d: !cute.stride<"((?@0@0,?@1@0),?@1)">)
    -> (!cute.stride<"?@0@0">, !cute.stride<"?@1@0">, !cute.stride<"?@1">) {
  %a, %b, %c = cute.get_leaves(%d) : !cute.stride<"((?@0@0,?@1@0),?@1)">
  return %a, %b, %c
      : !cute.stride<"?@0@0">, !cute.stride<"?@1@0">, !cute.stride<"?@1">
}

// -----

// Static coord.
// CHECK-LABEL: func.func @expand_coord_static
// CHECK-NOT:   cute.get_leaves
// CHECK-DAG:   cute.static : !cute.coord<"1">
// CHECK-DAG:   cute.static : !cute.coord<"2">
func.func @expand_coord_static(%c: !cute.coord<"(1,2)">)
    -> (!cute.coord<"1">, !cute.coord<"2">) {
  %a, %b = cute.get_leaves(%c) : !cute.coord<"(1,2)">
  return %a, %b : !cute.coord<"1">, !cute.coord<"2">
}

// -----

// Dynamic coord: dynamic leaf rebuilds, static fold.
// CHECK-LABEL: func.func @expand_coord_dynamic
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_coord
// CHECK-DAG:   cute.static : !cute.coord<"2">
func.func @expand_coord_dynamic(%c: !cute.coord<"(?,2)">)
    -> (!cute.coord<"?">, !cute.coord<"2">) {
  %a, %b = cute.get_leaves(%c) : !cute.coord<"(?,2)">
  return %a, %b : !cute.coord<"?">, !cute.coord<"2">
}

// -----

// Static tile: each layout leaf folds to `cute.static`.
// CHECK-LABEL: func.func @expand_tile_static
// CHECK-NOT:   cute.get_leaves
// CHECK-DAG:   cute.static : !cute.layout<"(4,8):(1,4)">
// CHECK-DAG:   cute.static : !cute.layout<"(2,3):(1,2)">
func.func @expand_tile_static(%t: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
    -> (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">) {
  %a, %b = cute.get_leaves(%t) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">
}

// -----

// Dynamic tile (no underscores): the dynamic layout slot rebuilds via
// make_*; the static slot folds to `cute.static`.
// CHECK-LABEL: func.func @expand_tile_dynamic
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,4):(1,?)">
// CHECK-DAG:   cute.static : !cute.layout<"(2,3):(1,2)">
func.func @expand_tile_dynamic(%t: !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">)
    -> (!cute.layout<"(?,4):(1,?)">, !cute.layout<"(2,3):(1,2)">) {
  %a, %b = cute.get_leaves(%t) : !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(?,4):(1,?)">, !cute.layout<"(2,3):(1,2)">
}

// -----

// Tile with a single underscore slot: result is `!cute.tile<"_">`,
// always-static — folds to `cute.static`.
// CHECK-LABEL: func.func @expand_tile_layout_and_underscore
// CHECK-NOT:   cute.get_leaves
// CHECK-DAG:   cute.static : !cute.layout<"4:1">
// CHECK-DAG:   cute.static : !cute.tile<"_">
func.func @expand_tile_layout_and_underscore(%t: !cute.tile<"[4:1;_]">)
    -> (!cute.layout<"4:1">, !cute.tile<"_">) {
  %a, %b = cute.get_leaves(%t) : !cute.tile<"[4:1;_]">
  return %a, %b : !cute.layout<"4:1">, !cute.tile<"_">
}

// -----

// Underscore between two layouts: each slot folds independently.
// CHECK-LABEL: func.func @expand_tile_layout_underscore_layout
// CHECK-NOT:   cute.get_leaves
// CHECK-DAG:   cute.static : !cute.layout<"(4,8):(1,4)">
// CHECK-DAG:   cute.static : !cute.tile<"_">
// CHECK-DAG:   cute.static : !cute.layout<"(2,3):(1,2)">
func.func @expand_tile_layout_underscore_layout(
    %t: !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">)
    -> (!cute.layout<"(4,8):(1,4)">, !cute.tile<"_">,
        !cute.layout<"(2,3):(1,2)">) {
  %a, %b, %c = cute.get_leaves(%t)
                 : !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">
  return %a, %b, %c : !cute.layout<"(4,8):(1,4)">, !cute.tile<"_">,
                      !cute.layout<"(2,3):(1,2)">
}

// -----

// Mixed: dynamic layout + underscore. The dynamic layout rebuilds via
// make_*; the underscore slot is always static and folds to `cute.static`.
// CHECK-LABEL: func.func @expand_tile_dynamic_layout_and_underscore
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,4):(1,?)">
// CHECK-DAG:   cute.static : !cute.tile<"_">
func.func @expand_tile_dynamic_layout_and_underscore(
    %t: !cute.tile<"[(?,4):(1,?);_]">)
    -> (!cute.layout<"(?,4):(1,?)">, !cute.tile<"_">) {
  %a, %b = cute.get_leaves(%t) : !cute.tile<"[(?,4):(1,?);_]">
  return %a, %b : !cute.layout<"(?,4):(1,?)">, !cute.tile<"_">
}

// -----

// Dynamic shape leaf: lowering rebuilds the leaf via `get_scalars`
// + `make_shape` (i32 operand); the static sibling folds to a
// `cute.static`.
// CHECK-LABEL: func.func @expand_shape_dyn_leaf
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape(%{{.+}})
// CHECK-SAME:  -> !cute.shape<"?">
// CHECK-DAG:   cute.static : !cute.shape<"5">
func.func @expand_shape_dyn_leaf(%s: !cute.shape<"(?,5)">)
    -> (!cute.shape<"?">, !cute.shape<"5">) {
  %a, %b = cute.get_leaves(%s) : !cute.shape<"(?,5)">
  return %a, %b : !cute.shape<"?">, !cute.shape<"5">
}

// -----

// Same dynamic-leaf rebuild for an int_tuple with a nested static
// sub-tuple sibling.
// CHECK-LABEL: func.func @expand_int_tuple_dyn_leaf
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple(%{{.+}})
// CHECK-SAME:  -> !cute.int_tuple<"?">
// CHECK-DAG:   cute.static : !cute.int_tuple<"2">
// CHECK-DAG:   cute.static : !cute.int_tuple<"3">
func.func @expand_int_tuple_dyn_leaf(%i: !cute.int_tuple<"(?,(2,3))">)
    -> (!cute.int_tuple<"?">, !cute.int_tuple<"2">, !cute.int_tuple<"3">) {
  %a, %b, %c = cute.get_leaves(%i) : !cute.int_tuple<"(?,(2,3))">
  return %a, %b, %c
      : !cute.int_tuple<"?">, !cute.int_tuple<"2">, !cute.int_tuple<"3">
}

// -----

// Nested coord with dynamic leaves at multiple depths — coord had only
// flat-dynamic coverage before. Each dyn leaf rebuilds via make_coord;
// nesting structure is reflected only in the result kinds (one
// !cute.coord per leaf, flattened to depth 1).
// CHECK-LABEL: func.func @expand_coord_nested_dynamic
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_coord
// CHECK-DAG:   cute.static : !cute.coord<"3">
// CHECK-DAG:   cute.static : !cute.coord<"2">
func.func @expand_coord_nested_dynamic(%c: !cute.coord<"((?,3),(2,?))">)
    -> (!cute.coord<"?">, !cute.coord<"3">, !cute.coord<"2">, !cute.coord<"?">) {
  %a, %b, %x, %d = cute.get_leaves(%c) : !cute.coord<"((?,3),(2,?))">
  return %a, %b, %x, %d
      : !cute.coord<"?">, !cute.coord<"3">, !cute.coord<"2">, !cute.coord<"?">
}

// -----

// Nested stride (plain integer, no scaled basis) with dynamic leaves
// at multiple depths — closes the gap between flat-dyn (`@expand_stride_dynamic`)
// and the scaled-basis nested case (`@expand_stride_nested_scaled_basis_dynamic`).
// CHECK-LABEL: func.func @expand_stride_nested_dynamic
// CHECK-NOT:   cute.get_leaves
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-DAG:   cute.make_stride
// CHECK-DAG:   cute.static : !cute.stride<"3">
// CHECK-DAG:   cute.static : !cute.stride<"2">
func.func @expand_stride_nested_dynamic(%st: !cute.stride<"((?,3),(2,?))">)
    -> (!cute.stride<"?">, !cute.stride<"3">, !cute.stride<"2">, !cute.stride<"?">) {
  %a, %b, %x, %d = cute.get_leaves(%st) : !cute.stride<"((?,3),(2,?))">
  return %a, %b, %x, %d
      : !cute.stride<"?">, !cute.stride<"3">, !cute.stride<"2">, !cute.stride<"?">
}
