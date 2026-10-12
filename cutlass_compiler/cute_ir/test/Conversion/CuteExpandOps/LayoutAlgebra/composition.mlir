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

// Tests `cute-expand-ops` lowering for `cute.composition`. Outer is
// AnyLayoutType; inner is layout / shape / tile (CompositionRhsType).

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.composition
// CHECK:       cute.static : !cute.layout<"(2,4):(1,2)">
func.func @expand_static() -> !cute.layout<"(2,4):(1,2)"> {
  %outer_shape = cute.make_shape () : () -> !cute.shape<"(4,8)">
  %outer_stride = cute.make_stride () : () -> !cute.stride<"(1,4)">
  %outer = cute.make_layout (%outer_shape, %outer_stride) : (!cute.shape<"(4,8)">, !cute.stride<"(1,4)">) -> !cute.layout<"(4,8):(1,4)">
  %inner_shape = cute.make_shape () : () -> !cute.shape<"(2,4)">
  %inner_stride = cute.make_stride () : () -> !cute.stride<"(1,2)">
  %inner = cute.make_layout (%inner_shape, %inner_stride) : (!cute.shape<"(2,4)">, !cute.stride<"(1,2)">) -> !cute.layout<"(2,4):(1,2)">
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,4):(1,2)">)
        -> !cute.layout<"(2,4):(1,2)">
  return %r : !cute.layout<"(2,4):(1,2)">
}

// -----

// Layout outer × Layout inner, dynamic outer.
// CHECK-LABEL: func.func @expand_layout_layout_dynamic
// CHECK-NOT:   cute.composition
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"4:?">
func.func @expand_layout_layout_dynamic(
    %outer: !cute.layout<"?:?">, %inner: !cute.layout<"4:1">)
    -> !cute.layout<"4:?"> {
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"?:?">, !cute.layout<"4:1">) -> !cute.layout<"4:?">
  return %r : !cute.layout<"4:?">
}

// -----

// Layout outer × Shape inner, dynamic outer.
// CHECK-LABEL: func.func @expand_layout_shape_dynamic
// CHECK-NOT:   cute.composition
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"4:?">
func.func @expand_layout_shape_dynamic(
    %outer: !cute.layout<"?:?">, %inner: !cute.shape<"4">)
    -> !cute.layout<"4:?"> {
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"?:?">, !cute.shape<"4">) -> !cute.layout<"4:?">
  return %r : !cute.layout<"4:?">
}

// -----

// Composed layout outer × Layout inner — composed result preserved
// (`allowDecay=false`).
// CHECK-LABEL: func.func @expand_composed_layout_dynamic
// CHECK-NOT:   cute.composition
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"S<3,5,4> o 0 o 4:?">
func.func @expand_composed_layout_dynamic(
    %outer: !cute.composed_layout<"S<3,5,4> o 0 o ?:?">,
    %inner: !cute.layout<"4:1">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o 4:?"> {
  %r = cute.composition(%outer, %inner)
         : (!cute.composed_layout<"S<3,5,4> o 0 o ?:?">, !cute.layout<"4:1">)
        -> !cute.composed_layout<"S<3,5,4> o 0 o 4:?">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o 4:?">
}

// -----

// Layout outer × Tile inner, dynamic outer. Tile wraps the inner layout
// `[4:1]`, so the composition result is hierarchical `(4):(?)`.
// CHECK-LABEL: func.func @expand_layout_tile_dynamic
// CHECK-NOT:   cute.composition
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(4):(?)">
func.func @expand_layout_tile_dynamic(
    %outer: !cute.layout<"?:?">, %inner: !cute.tile<"[4:1]">)
    -> !cute.layout<"(4):(?)"> {
  %r = cute.composition(%outer, %inner)
         : (!cute.layout<"?:?">, !cute.tile<"[4:1]">)
        -> !cute.layout<"(4):(?)">
  return %r : !cute.layout<"(4):(?)">
}

// -----

// Composed layout outer × Shape inner. Composition applies to the B part
// of the composed layout; the swizzle A and the offset are preserved.
// CHECK-LABEL: func.func @expand_composed_layout_shape_dynamic
// CHECK-NOT:   cute.composition
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"S<3,5,4> o 0 o 4:?">
func.func @expand_composed_layout_shape_dynamic(
    %outer: !cute.composed_layout<"S<3,5,4> o 0 o ?:?">,
    %inner: !cute.shape<"4">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o 4:?"> {
  %r = cute.composition(%outer, %inner)
         : (!cute.composed_layout<"S<3,5,4> o 0 o ?:?">, !cute.shape<"4">)
        -> !cute.composed_layout<"S<3,5,4> o 0 o 4:?">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o 4:?">
}

// -----

// Composed layout outer × Tile inner.
// CHECK-LABEL: func.func @expand_composed_layout_tile_dynamic
// CHECK-NOT:   cute.composition
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"S<3,5,4> o 0 o (4):(?)">
func.func @expand_composed_layout_tile_dynamic(
    %outer: !cute.composed_layout<"S<3,5,4> o 0 o ?:?">,
    %inner: !cute.tile<"[4:1]">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o (4):(?)"> {
  %r = cute.composition(%outer, %inner)
         : (!cute.composed_layout<"S<3,5,4> o 0 o ?:?">, !cute.tile<"[4:1]">)
        -> !cute.composed_layout<"S<3,5,4> o 0 o (4):(?)">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o (4):(?)">
}
