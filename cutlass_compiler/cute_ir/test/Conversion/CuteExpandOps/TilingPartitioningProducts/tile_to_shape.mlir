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

// Tests `cute-expand-ops` lowering for `cute.tile_to_shape`.

// -----

// Static — folds.
// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.tile_to_shape
// CHECK:       cute.static : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
func.func @expand_static(%a: !cute.layout<"(3,2):(1,3)">,
                          %s: !cute.shape<"(6,8)">)
    -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))"> {
  %r = cute.tile_to_shape(%a, %s)
         : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">)
        -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
  return %r : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
}

// -----

// Composed-layout input — wrap preserved.
// CHECK-LABEL: func.func @expand_composed_static
// CHECK-NOT:   cute.tile_to_shape
// CHECK:       cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,6),(3,12))">
func.func @expand_composed_static(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
    %s: !cute.shape<"(6,8)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,6),(3,12))"> {
  %r = cute.tile_to_shape(%a, %s)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
            !cute.shape<"(6,8)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,6),(3,12))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,6),(3,12))">
}

// -----

// Explicit order = (0,1) — natural / col-major. Static, folds.
// CHECK-LABEL: func.func @expand_order_natural
// CHECK-NOT:   cute.tile_to_shape
// CHECK:       cute.static : !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
func.func @expand_order_natural(
    %a: !cute.layout<"(128,128):(128,1)">,
    %s: !cute.shape<"(1024,512)">,
    %o: !cute.int_tuple<"(0,1)">)
    -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))"> {
  %r = cute.tile_to_shape(%a, %s, %o)
         : (!cute.layout<"(128,128):(128,1)">,
            !cute.shape<"(1024,512)">,
            !cute.int_tuple<"(0,1)">)
        -> !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
  return %r : !cute.layout<"((128,8),(128,4)):((128,16384),(1,131072))">
}

// -----

// Explicit order = (1,0) — swap, different strides than when no order is provided.
// CHECK-LABEL: func.func @expand_order_swapped
// CHECK-NOT:   cute.tile_to_shape
// CHECK:       cute.static : !cute.layout<"((128,8),(128,4)):((128,65536),(1,16384))">
func.func @expand_order_swapped(
    %a: !cute.layout<"(128,128):(128,1)">,
    %s: !cute.shape<"(1024,512)">,
    %o: !cute.int_tuple<"(1,0)">)
    -> !cute.layout<"((128,8),(128,4)):((128,65536),(1,16384))"> {
  %r = cute.tile_to_shape(%a, %s, %o)
         : (!cute.layout<"(128,128):(128,1)">,
            !cute.shape<"(1024,512)">,
            !cute.int_tuple<"(1,0)">)
        -> !cute.layout<"((128,8),(128,4)):((128,65536),(1,16384))">
  return %r : !cute.layout<"((128,8),(128,4)):((128,65536),(1,16384))">
}

// -----

// Dynamic target shape — result has dynamic replication factors.
// CHECK-LABEL: func.func @expand_dyn_shape
// CHECK-NOT:   cute.tile_to_shape
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"((3,?),(2,?)):((1,6),(3,?))">
func.func @expand_dyn_shape(
    %a: !cute.layout<"(3,2):(1,3)">,
    %s: !cute.shape<"(?,?)">)
    -> !cute.layout<"((3,?),(2,?)):((1,6),(3,?))"> {
  %r = cute.tile_to_shape(%a, %s)
         : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,?)">)
        -> !cute.layout<"((3,?),(2,?)):((1,6),(3,?))">
  return %r : !cute.layout<"((3,?),(2,?)):((1,6),(3,?))">
}

// -----

// Dynamic target shape with explicit swap order — strides shift accordingly.
// CHECK-LABEL: func.func @expand_dyn_shape_order_swap
// CHECK-NOT:   cute.tile_to_shape
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"((3,?),(2,?)):((1,?),(3,6))">
func.func @expand_dyn_shape_order_swap(
    %a: !cute.layout<"(3,2):(1,3)">,
    %s: !cute.shape<"(?,?)">,
    %o: !cute.int_tuple<"(1,0)">)
    -> !cute.layout<"((3,?),(2,?)):((1,?),(3,6))"> {
  %r = cute.tile_to_shape(%a, %s, %o)
         : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,?)">,
            !cute.int_tuple<"(1,0)">)
        -> !cute.layout<"((3,?),(2,?)):((1,?),(3,6))">
  return %r : !cute.layout<"((3,?),(2,?)):((1,?),(3,6))">
}

// -----

// Composed input with explicit swap order, all-static — swizzle/offset preserved.
// CHECK-LABEL: func.func @expand_composed_order_swap
// CHECK-NOT:   cute.tile_to_shape
// CHECK:       cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,24),(3,6))">
func.func @expand_composed_order_swap(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
    %s: !cute.shape<"(6,8)">,
    %o: !cute.int_tuple<"(1,0)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,24),(3,6))"> {
  %r = cute.tile_to_shape(%a, %s, %o)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
            !cute.shape<"(6,8)">, !cute.int_tuple<"(1,0)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,24),(3,6))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,2),(2,4)):((1,24),(3,6))">
}

// -----

// Composed input with dynamic target shape — result is a non-static composed_layout.
// CHECK-LABEL: func.func @expand_composed_dyn_shape
// CHECK-NOT:   cute.tile_to_shape
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"S<3,4,3> o 0 o ((3,?),(2,?)):((1,6),(3,?))">
func.func @expand_composed_dyn_shape(
    %a: !cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
    %s: !cute.shape<"(?,?)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,?),(2,?)):((1,6),(3,?))"> {
  %r = cute.tile_to_shape(%a, %s)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (3,2):(1,3)">,
            !cute.shape<"(?,?)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((3,?),(2,?)):((1,6),(3,?))">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((3,?),(2,?)):((1,6),(3,?))">
}
