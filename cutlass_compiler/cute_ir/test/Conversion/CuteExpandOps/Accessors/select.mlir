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

// Tests `cute-expand-ops` lowering for `cute.select`.

// -----

// CHECK-LABEL: func.func @expand_int_tuple_static
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.int_tuple<"(1,3)">
func.func @expand_int_tuple_static(%v: !cute.int_tuple<"(1,2,3)">)
    -> !cute.int_tuple<"(1,3)"> {
  %r = cute.select<[0, 2]>(%v)
         : !cute.int_tuple<"(1,2,3)"> -> !cute.int_tuple<"(1,3)">
  return %r : !cute.int_tuple<"(1,3)">
}

// -----

// CHECK-LABEL: func.func @expand_int_tuple_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"(?,3)">
func.func @expand_int_tuple_dynamic(%v: !cute.int_tuple<"(?,2,3)">)
    -> !cute.int_tuple<"(?,3)"> {
  %r = cute.select<[0, 2]>(%v)
         : !cute.int_tuple<"(?,2,3)"> -> !cute.int_tuple<"(?,3)">
  return %r : !cute.int_tuple<"(?,3)">
}

// -----

// CHECK-LABEL: func.func @expand_shape_static
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.shape<"(4,2)">
func.func @expand_shape_static(%v: !cute.shape<"(4,8,2)">)
    -> !cute.shape<"(4,2)"> {
  %r = cute.select<[0, 2]>(%v) : !cute.shape<"(4,8,2)"> -> !cute.shape<"(4,2)">
  return %r : !cute.shape<"(4,2)">
}

// -----

// CHECK-LABEL: func.func @expand_shape_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape
// CHECK-SAME:  -> !cute.shape<"(4,?)">
func.func @expand_shape_dynamic(%v: !cute.shape<"(4,?,2)">)
    -> !cute.shape<"(4,?)"> {
  %r = cute.select<[0, 1]>(%v) : !cute.shape<"(4,?,2)"> -> !cute.shape<"(4,?)">
  return %r : !cute.shape<"(4,?)">
}

// -----

// CHECK-LABEL: func.func @expand_coord_static
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.coord<"(1,3)">
func.func @expand_coord_static(%v: !cute.coord<"(1,2,3)">)
    -> !cute.coord<"(1,3)"> {
  %r = cute.select<[0, 2]>(%v) : !cute.coord<"(1,2,3)"> -> !cute.coord<"(1,3)">
  return %r : !cute.coord<"(1,3)">
}

// -----

// CHECK-LABEL: func.func @expand_coord_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_coord
// CHECK-SAME:  -> !cute.coord<"(1,?)">
func.func @expand_coord_dynamic(%v: !cute.coord<"(1,?,3)">)
    -> !cute.coord<"(1,?)"> {
  %r = cute.select<[0, 1]>(%v) : !cute.coord<"(1,?,3)"> -> !cute.coord<"(1,?)">
  return %r : !cute.coord<"(1,?)">
}

// -----

// CHECK-LABEL: func.func @expand_stride_static
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.stride<"(1,8)">
func.func @expand_stride_static(%v: !cute.stride<"(1,4,8)">)
    -> !cute.stride<"(1,8)"> {
  %r = cute.select<[0, 2]>(%v) : !cute.stride<"(1,4,8)"> -> !cute.stride<"(1,8)">
  return %r : !cute.stride<"(1,8)">
}

// -----

// CHECK-LABEL: func.func @expand_stride_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_stride
// CHECK-SAME:  -> !cute.stride<"(1,?)">
func.func @expand_stride_dynamic(%v: !cute.stride<"(1,?,8)">)
    -> !cute.stride<"(1,?)"> {
  %r = cute.select<[0, 1]>(%v) : !cute.stride<"(1,?,8)"> -> !cute.stride<"(1,?)">
  return %r : !cute.stride<"(1,?)">
}

// -----

// CHECK-LABEL: func.func @expand_tile_static
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.tile<"[(2,3):(1,2);(4,8):(1,4)]">
func.func @expand_tile_static(%v: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
    -> !cute.tile<"[(2,3):(1,2);(4,8):(1,4)]"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
        -> !cute.tile<"[(2,3):(1,2);(4,8):(1,4)]">
  return %r : !cute.tile<"[(2,3):(1,2);(4,8):(1,4)]">
}

// -----

// Dynamic tile (no underscores), reordered via select<[1, 0]> — the
// reordered tile is rebuilt via make_tile from the dynamic leaves.
// CHECK-LABEL: func.func @expand_tile_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       %[[T:.+]] = cute.make_tile
// CHECK-SAME:            -> !cute.tile<"[(2,3):(1,2);(?,4):(1,?)]">
func.func @expand_tile_dynamic(%v: !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">)
    -> !cute.tile<"[(2,3):(1,2);(?,4):(1,?)]"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">
        -> !cute.tile<"[(2,3):(1,2);(?,4):(1,?)]">
  return %r : !cute.tile<"[(2,3):(1,2);(?,4):(1,?)]">
}

// -----

// CHECK-LABEL: func.func @expand_layout_static
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.layout<"(8,4):(8,1)">
func.func @expand_layout_static(%v: !cute.layout<"(4,2,8):(1,4,8)">)
    -> !cute.layout<"(8,4):(8,1)"> {
  %r = cute.select<[2, 0]>(%v)
         : !cute.layout<"(4,2,8):(1,4,8)"> -> !cute.layout<"(8,4):(8,1)">
  return %r : !cute.layout<"(8,4):(8,1)">
}

// -----

// CHECK-LABEL: func.func @expand_layout_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,4):(?,1)">
func.func @expand_layout_dynamic(%v: !cute.layout<"(4,?,2):(1,?,8)">)
    -> !cute.layout<"(?,4):(?,1)"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.layout<"(4,?,2):(1,?,8)"> -> !cute.layout<"(?,4):(?,1)">
  return %r : !cute.layout<"(?,4):(?,1)">
}

// -----

// CHECK-LABEL: func.func @expand_composed_layout_static
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(8,1)">
func.func @expand_composed_layout_static(
    %v: !cute.composed_layout<"S<3,5,4> o 0 o (4,2,8):(1,4,8)">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(8,1)"> {
  %r = cute.select<[2, 0]>(%v)
         : !cute.composed_layout<"S<3,5,4> o 0 o (4,2,8):(1,4,8)">
        -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(8,1)">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(8,1)">
}

// -----

// CHECK-LABEL: func.func @expand_composed_layout_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"S<3,5,4> o 0 o (?,4):(?,1)">
func.func @expand_composed_layout_dynamic(
    %v: !cute.composed_layout<"S<3,5,4> o 0 o (4,?,8):(1,?,8)">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o (?,4):(?,1)"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.composed_layout<"S<3,5,4> o 0 o (4,?,8):(1,?,8)">
        -> !cute.composed_layout<"S<3,5,4> o 0 o (?,4):(?,1)">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o (?,4):(?,1)">
}

// -----

// Scaled-basis stride (static): reordered selection folds.
// CHECK-LABEL: func.func @expand_stride_scaled_basis_static
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.stride<"(1@1,1@0)">
func.func @expand_stride_scaled_basis_static(%v: !cute.stride<"(1@0,1@1)">)
    -> !cute.stride<"(1@1,1@0)"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.stride<"(1@0,1@1)"> -> !cute.stride<"(1@1,1@0)">
  return %r : !cute.stride<"(1@1,1@0)">
}

// -----

// Scaled-basis stride (dynamic): reordered selection rebuilds via make_stride.
// CHECK-LABEL: func.func @expand_stride_scaled_basis_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_stride
// CHECK-SAME:  -> !cute.stride<"(?@1,?@0)">
func.func @expand_stride_scaled_basis_dynamic(%v: !cute.stride<"(?@0,?@1)">)
    -> !cute.stride<"(?@1,?@0)"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.stride<"(?@0,?@1)"> -> !cute.stride<"(?@1,?@0)">
  return %r : !cute.stride<"(?@1,?@0)">
}

// -----

// Scaled-basis layout (static).
// CHECK-LABEL: func.func @expand_layout_scaled_basis_static
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.layout<"(8,4):(1@1,1@0)">
func.func @expand_layout_scaled_basis_static(%v: !cute.layout<"(4,8):(1@0,1@1)">)
    -> !cute.layout<"(8,4):(1@1,1@0)"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.layout<"(4,8):(1@0,1@1)"> -> !cute.layout<"(8,4):(1@1,1@0)">
  return %r : !cute.layout<"(8,4):(1@1,1@0)">
}

// -----

// Scaled-basis layout (dynamic).
// CHECK-LABEL: func.func @expand_layout_scaled_basis_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,?):(?@1,?@0)">
func.func @expand_layout_scaled_basis_dynamic(%v: !cute.layout<"(?,?):(?@0,?@1)">)
    -> !cute.layout<"(?,?):(?@1,?@0)"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.layout<"(?,?):(?@0,?@1)"> -> !cute.layout<"(?,?):(?@1,?@0)">
  return %r : !cute.layout<"(?,?):(?@1,?@0)">
}

// -----

// Static composed_layout: swizzle A, integer-stride outer B.
// CHECK-LABEL: func.func @expand_composed_layout_static
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
func.func @expand_composed_layout_static(
    %v: !cute.composed_layout<"S<3,5,4> o 0 o (4,8):(8,1)">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.composed_layout<"S<3,5,4> o 0 o (4,8):(8,1)">
        -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
}

// -----

// Dynamic composed_layout with affine A, tuple offset, and basis-stride
// outer B.
// CHECK-LABEL: func.func @expand_composed_layout_affine_a_basis_b_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"(4,5):(1,4) o (0,0) o (?,?):(?@1,?@0)">
func.func @expand_composed_layout_affine_a_basis_b_dynamic(
    %v: !cute.composed_layout<"(4,5):(1,4) o (0,0) o (?,?):(?@0,?@1)">)
    -> !cute.composed_layout<"(4,5):(1,4) o (0,0) o (?,?):(?@1,?@0)"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (?,?):(?@0,?@1)">
        -> !cute.composed_layout<"(4,5):(1,4) o (0,0) o (?,?):(?@1,?@0)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (?,?):(?@1,?@0)">
}

// -----

// Nested shape with dynamic inner: select picks an outer mode whose inner
// shape contains the dynamic leaf.
// CHECK-LABEL: func.func @expand_nested_shape_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_shape
// CHECK-SAME:  -> !cute.shape<"((?,3))">
func.func @expand_nested_shape_dynamic(%v: !cute.shape<"((?,3),4)">)
    -> !cute.shape<"((?,3))"> {
  %r = cute.select<[0]>(%v) : !cute.shape<"((?,3),4)"> -> !cute.shape<"((?,3))">
  return %r : !cute.shape<"((?,3))">
}

// -----

// Nested layout with dynamic strides at multiple depths — reordered.
// CHECK-LABEL: func.func @expand_nested_layout_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(4,(?,3)):(?,(1,?))">
func.func @expand_nested_layout_dynamic(
    %v: !cute.layout<"((?,3),4):((1,?),?)">)
    -> !cute.layout<"(4,(?,3)):(?,(1,?))"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.layout<"((?,3),4):((1,?),?)">
        -> !cute.layout<"(4,(?,3)):(?,(1,?))">
  return %r : !cute.layout<"(4,(?,3)):(?,(1,?))">
}

// -----

// Nested scaled-basis stride (dynamic) — reordered selection rebuilds.
// CHECK-LABEL: func.func @expand_nested_scaled_basis_dynamic
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_stride
// CHECK-SAME:  -> !cute.stride<"(?@1,(?@0@0,?@1@0))">
func.func @expand_nested_scaled_basis_dynamic(
    %v: !cute.stride<"((?@0@0,?@1@0),?@1)">)
    -> !cute.stride<"(?@1,(?@0@0,?@1@0))"> {
  %r = cute.select<[1, 0]>(%v)
         : !cute.stride<"((?@0@0,?@1@0),?@1)">
        -> !cute.stride<"(?@1,(?@0@0,?@1@0))">
  return %r : !cute.stride<"(?@1,(?@0@0,?@1@0))">
}

// -----

// Empty mode `<[]>` on a static input: result is rank-0, folds via the
// `isStatic()` short-circuit.
// CHECK-LABEL: func.func @expand_empty_mode_static
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.shape<"()">
func.func @expand_empty_mode_static(%v: !cute.shape<"(4,8)">) -> !cute.shape<"()"> {
  %r = cute.select<[]>(%v) : !cute.shape<"(4,8)"> -> !cute.shape<"()">
  return %r : !cute.shape<"()">
}

// -----

// Empty mode `<[]>` on a dynamic input: result is still rank-0 with no
// surviving dynamic values, so it folds via the static short-circuit
// regardless of input dynamism.
// CHECK-LABEL: func.func @expand_empty_mode_dynamic_input
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.shape<"()">
func.func @expand_empty_mode_dynamic_input(%v: !cute.shape<"(?,8)">)
    -> !cute.shape<"()"> {
  %r = cute.select<[]>(%v) : !cute.shape<"(?,8)"> -> !cute.shape<"()">
  return %r : !cute.shape<"()">
}

// -----

// Tile operand picking an underscore slot — result is `!cute.tile<"[_]">`,
// fully static, so it folds via the static short-circuit.
// CHECK-LABEL: func.func @expand_tile_underscore_picked
// CHECK-NOT:   cute.select
// CHECK:       cute.static : !cute.tile<"[_]">
func.func @expand_tile_underscore_picked(%v: !cute.tile<"[(4,8):(1,4);_]">)
    -> !cute.tile<"[_]"> {
  %r = cute.select<[1]>(%v)
         : !cute.tile<"[(4,8):(1,4);_]"> -> !cute.tile<"[_]">
  return %r : !cute.tile<"[_]">
}

// -----

// Composed_layout with a dynamic offset: select reorders outer B; the
// dynamic offset threads through `get_scalars` → `make_int_tuple` →
// `make_composed_layout` on the `Layout/ComposedLayout` branch.
// CHECK-LABEL: func.func @expand_composed_layout_dynamic_offset
// CHECK-NOT:   cute.select
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"(4,5):(1,4) o ? o (8,4):(8,1)">
func.func @expand_composed_layout_dynamic_offset(
    %v: !cute.composed_layout<"(4,5):(1,4) o ? o (4,2,8):(1,4,8)">)
    -> !cute.composed_layout<"(4,5):(1,4) o ? o (8,4):(8,1)"> {
  %r = cute.select<[2, 0]>(%v)
         : !cute.composed_layout<"(4,5):(1,4) o ? o (4,2,8):(1,4,8)">
        -> !cute.composed_layout<"(4,5):(1,4) o ? o (8,4):(8,1)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o ? o (8,4):(8,1)">
}
