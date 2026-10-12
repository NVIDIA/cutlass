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

// Tests `cute-expand-ops` lowering for `cute.layout_eval`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.static : !cute.int_tuple<"9">
func.func @expand_static(%crd: !cute.coord<"(1,2)">,
                          %lay: !cute.layout<"(4,8):(1,4)">)
    -> !cute.int_tuple<"9"> {
  %r = cute.layout_eval(%crd, %lay)
         : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,4)">)
        -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}

// -----

// Dynamic coord, static layout — index becomes a dynamic int_tuple.
// CHECK-LABEL: func.func @expand_dynamic_coord
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       arith.muli
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_dynamic_coord(%crd: !cute.coord<"(?,?)">,
                                 %lay: !cute.layout<"(4,8):(1,4)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%crd, %lay)
         : (!cute.coord<"(?,?)">, !cute.layout<"(4,8):(1,4)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Static coord, dynamic stride — index resolves through arith on the stride.
// CHECK-LABEL: func.func @expand_dynamic_stride
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_dynamic_stride(%crd: !cute.coord<"(1,2)">,
                                  %lay: !cute.layout<"(4,8):(1,?)">)
    -> !cute.int_tuple<"?">
{
  %r = cute.layout_eval(%crd, %lay)
         : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,?)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Nested static coord and nested static layout.
// CHECK-LABEL: func.func @expand_nested_static
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.static : !cute.int_tuple<"93">
func.func @expand_nested_static(%crd: !cute.coord<"(1,(2,1),3)">,
                                 %lay: !cute.layout<"(4,(3,2),5):(1,(4,12),24)">)
    -> !cute.int_tuple<"93"> {
  %r = cute.layout_eval(%crd, %lay)
         : (!cute.coord<"(1,(2,1),3)">,
            !cute.layout<"(4,(3,2),5):(1,(4,12),24)">)
        -> !cute.int_tuple<"93">
  return %r : !cute.int_tuple<"93">
}

// -----

// Fully-dynamic nested coord over static layout: index expands to dot-product.
// CHECK-LABEL: func.func @expand_nested_dynamic_coord
// CHECK-NOT:   cute.layout_eval
// CHECK:       %[[S:.+]]:4 = cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.coord<"(?,(?,?),?)">
// CHECK-DAG:   %[[C4:.+]] = arith.constant 4 : i32
// CHECK-DAG:   %[[C12:.+]] = arith.constant 12 : i32
// CHECK-DAG:   %[[C24:.+]] = arith.constant 24 : i32
// CHECK-DAG:   arith.muli %[[S]]#1, %[[C4]]
// CHECK-DAG:   arith.muli %[[S]]#2, %[[C12]]
// CHECK-DAG:   arith.muli %[[S]]#3, %[[C24]]
// CHECK-DAG:   arith.addi {{.+}} : i32
// CHECK-DAG:   arith.addi {{.+}} : i32
// CHECK-DAG:   arith.addi {{.+}} : i32
// CHECK-NOT:   arith.muli
// CHECK-NOT:   arith.addi
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_nested_dynamic_coord(%crd: !cute.coord<"(?,(?,?),?)">,
                                        %lay: !cute.layout<"(4,(3,2),5):(1,(4,12),24)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%crd, %lay)
         : (!cute.coord<"(?,(?,?),?)">,
            !cute.layout<"(4,(3,2),5):(1,(4,12),24)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Mixed static/dynamic nested coord: static parts fold to constants, dynamic via get_scalars.
// CHECK-LABEL: func.func @expand_nested_mixed_coord
// CHECK-NOT:   cute.layout_eval
// CHECK:       %[[S:.+]]:2 = cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.coord<"(?,(2,?),3)">
// CHECK-DAG:   %[[C8:.+]] = arith.constant 8 : i32
// CHECK-DAG:   %[[C72:.+]] = arith.constant 72 : i32
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_nested_mixed_coord(%crd: !cute.coord<"(?,(2,?),3)">,
                                      %lay: !cute.layout<"(4,(3,2),5):(1,(4,12),24)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%crd, %lay)
         : (!cute.coord<"(?,(2,?),3)">,
            !cute.layout<"(4,(3,2),5):(1,(4,12),24)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Static nested coord, partially-dynamic strides: dynamic strides via get_scalars on layout.
// CHECK-LABEL: func.func @expand_nested_dynamic_stride
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.layout<"(4,(3,2),5):(1,(?,?),?)">
// CHECK:       arith.muli
// CHECK:       arith.addi
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_nested_dynamic_stride(%crd: !cute.coord<"(1,(2,1),3)">,
                                         %lay: !cute.layout<"(4,(3,2),5):(1,(?,?),?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%crd, %lay)
         : (!cute.coord<"(1,(2,1),3)">,
            !cute.layout<"(4,(3,2),5):(1,(?,?),?)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Fully static composed layout with affine inner A — collapses to `cute.static`.
// CHECK-LABEL: func.func @expand_composed_static_affine
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.static : !cute.int_tuple<"42">
func.func @expand_composed_static_affine(
    %crd: !cute.coord<"4">,
    %cl: !cute.composed_layout<"(20):(3) o 2 o (20):(3)">)
    -> !cute.int_tuple<"42"> {
  %r = cute.layout_eval(%crd, %cl)
         : (!cute.coord<"4">,
            !cute.composed_layout<"(20):(3) o 2 o (20):(3)">)
        -> !cute.int_tuple<"42">
  return %r : !cute.int_tuple<"42">
}

// -----

// Fully static composed layout with swizzle inner — collapses to `cute.static`.
// CHECK-LABEL: func.func @expand_composed_static_swizzle
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.static : !cute.int_tuple<"208">
func.func @expand_composed_static_swizzle(
    %crd: !cute.coord<"6">,
    %cl: !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
    -> !cute.int_tuple<"208"> {
  %r = cute.layout_eval(%crd, %cl)
         : (!cute.coord<"6">,
            !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
        -> !cute.int_tuple<"208">
  return %r : !cute.int_tuple<"208">
}

// -----

// Fully static basis-B composed layout: folds to cute.static at compile time.
// CHECK-LABEL: func.func @expand_composed_static_basis_b
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.static : !cute.int_tuple<"10">
func.func @expand_composed_static_basis_b(
    %crd: !cute.coord<"3">,
    %cl: !cute.composed_layout<"(6,2):(1,3) o (2,1) o (2,3):(1@1,2@0)">)
    -> !cute.int_tuple<"10"> {
  %r = cute.layout_eval(%crd, %cl)
         : (!cute.coord<"3">,
            !cute.composed_layout<"(6,2):(1,3) o (2,1) o (2,3):(1@1,2@0)">)
        -> !cute.int_tuple<"10">
  return %r : !cute.int_tuple<"10">
}

// -----

// Dynamic coord with static affine composed layout.
// CHECK-LABEL: func.func @expand_composed_dynamic_coord_affine
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.coord<"?">
// CHECK:       arith.muli
// CHECK:       arith.addi
// CHECK:       arith.muli
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_composed_dynamic_coord_affine(
    %crd: !cute.coord<"?">,
    %cl: !cute.composed_layout<"(20):(3) o 2 o (20):(3)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%crd, %cl)
         : (!cute.coord<"?">,
            !cute.composed_layout<"(20):(3) o 2 o (20):(3)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Dynamic coord with static swizzle composed layout: swizzle materialized as bit ops.
// CHECK-LABEL: func.func @expand_composed_dynamic_coord_swizzle
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.coord<"?">
// CHECK:       arith.muli
// CHECK:       arith.andi
// CHECK:       arith.shrui
// CHECK:       arith.xori
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_composed_dynamic_coord_swizzle(
    %crd: !cute.coord<"?">,
    %cl: !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%crd, %cl)
         : (!cute.coord<"?">,
            !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Static coord, dynamic outer B-stride in affine composed layout.
// CHECK-LABEL: func.func @expand_composed_dynamic_b_stride
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.composed_layout<"(20):(3) o 2 o (20):(?)">
// CHECK:       arith.muli
// CHECK:       arith.addi
// CHECK:       arith.muli
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_composed_dynamic_b_stride(
    %crd: !cute.coord<"4">,
    %cl: !cute.composed_layout<"(20):(3) o 2 o (20):(?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%crd, %cl)
         : (!cute.coord<"4">,
            !cute.composed_layout<"(20):(3) o 2 o (20):(?)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Dynamic coord with static scaled basis-B composed layout.
// CHECK-LABEL: func.func @expand_composed_dynamic_coord_basis_b
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.coord<"?">
// CHECK-DAG:   arith.divsi
// CHECK-DAG:   arith.remsi
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_composed_dynamic_coord_basis_b(
    %crd: !cute.coord<"?">,
    %cl: !cute.composed_layout<"(6,2):(1,3) o (2,1) o (2,3):(1@1,2@0)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%crd, %cl)
         : (!cute.coord<"?">,
            !cute.composed_layout<"(6,2):(1,3) o (2,1) o (2,3):(1@1,2@0)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Static coord with dynamic offset.
// CHECK-LABEL: func.func @expand_composed_dynamic_offset_swizzle
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.composed_layout<"S<1,4,3> o ? o (32):(32)">
// CHECK:       arith.addi
// CHECK:       arith.andi
// CHECK:       arith.shrui
// CHECK:       arith.xori
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_composed_dynamic_offset_swizzle(
    %crd: !cute.coord<"6">,
    %cl: !cute.composed_layout<"S<1,4,3> o ? o (32):(32)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%crd, %cl)
         : (!cute.coord<"6">,
            !cute.composed_layout<"S<1,4,3> o ? o (32):(32)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Scalar dynamic coord on multi-mode layout.
// CHECK-LABEL: func.func @expand_scalar_coord_dynamic
// CHECK-NOT:   cute.layout_eval
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       arith.divsi
// CHECK:       arith.remsi
// CHECK:       arith.muli {{.+}} overflow<nsw> : i32
// CHECK:       arith.addi {{.+}} overflow<nsw> : i32
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_scalar_coord_dynamic(%crd: !cute.coord<"?">,
                                       %l: !cute.layout<"(4,8):(1,4)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.layout_eval(%crd, %l)
         : (!cute.coord<"?">, !cute.layout<"(4,8):(1,4)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
