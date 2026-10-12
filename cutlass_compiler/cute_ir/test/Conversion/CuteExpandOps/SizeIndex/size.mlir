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

// Tests `cute-expand-ops` lowering for `cute.size`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.size
// CHECK:       cute.static : !cute.int_tuple<"24">
func.func @expand_static(%src: !cute.layout<"(2,3,4):(1,2,6)">)
    -> !cute.int_tuple<"24"> {
  %r = cute.size(%src)
         : (!cute.layout<"(2,3,4):(1,2,6)">) -> !cute.int_tuple<"24">
  return %r : !cute.int_tuple<"24">
}

// -----

// Static size with mode — folds at compile time.
// CHECK-LABEL: func.func @expand_with_mode
// CHECK-NOT:   cute.size
// CHECK:       cute.static : !cute.int_tuple<"3">
func.func @expand_with_mode(%src: !cute.layout<"(2,3,4):(1,2,6)">)
    -> !cute.int_tuple<"3"> {
  %r = cute.size<[1]>(%src)
         : (!cute.layout<"(2,3,4):(1,2,6)">) -> !cute.int_tuple<"3">
  return %r : !cute.int_tuple<"3">
}

// -----

// CHECK-LABEL: func.func @expand_layout_dynamic
// CHECK-NOT:   cute.size
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       arith.muli
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_layout_dynamic(%src: !cute.layout<"(2,?,4):(1,?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.size(%src)
         : (!cute.layout<"(2,?,4):(1,?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// CHECK-LABEL: func.func @expand_shape_dynamic
// CHECK-NOT:   cute.size
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_shape_dynamic(%src: !cute.shape<"(?,2)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.size(%src)
         : (!cute.shape<"(?,2)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// CHECK-LABEL: func.func @expand_int_tuple_dynamic
// CHECK-NOT:   cute.size
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_int_tuple_dynamic(%src: !cute.int_tuple<"(?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.size(%src)
         : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// CHECK-LABEL: func.func @expand_composed_dynamic
// CHECK-NOT:   cute.size
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_composed_dynamic(
    %src: !cute.composed_layout<"S<3,5,4> o 0 o (4,?):(?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.size(%src)
         : (!cute.composed_layout<"S<3,5,4> o 0 o (4,?):(?,?)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Nested static layout.
// CHECK-LABEL: func.func @expand_nested_top_mode
// CHECK-NOT:   cute.size
// CHECK:       cute.static : !cute.int_tuple<"12">
func.func @expand_nested_top_mode(
    %src: !cute.layout<"(2,(3,4),5):(1,(2,6),24)">)
    -> !cute.int_tuple<"12"> {
  %r = cute.size<[1]>(%src)
         : (!cute.layout<"(2,(3,4),5):(1,(2,6),24)">) -> !cute.int_tuple<"12">
  return %r : !cute.int_tuple<"12">
}

// -----

// Nested static layout, inner mode [1, 0] picks the leaf: folds to cute.static.
// CHECK-LABEL: func.func @expand_nested_inner_mode
// CHECK-NOT:   cute.size
// CHECK:       cute.static : !cute.int_tuple<"3">
func.func @expand_nested_inner_mode(
    %src: !cute.layout<"(2,(3,4),5):(1,(2,6),24)">)
    -> !cute.int_tuple<"3"> {
  %r = cute.size<[1, 0]>(%src)
         : (!cute.layout<"(2,(3,4),5):(1,(2,6),24)">) -> !cute.int_tuple<"3">
  return %r : !cute.int_tuple<"3">
}

// -----

// Nested dynamic layout, inner mode [1, 0] selects the dynamic leaf directly.
// CHECK-LABEL: func.func @expand_nested_inner_mode_dynamic
// CHECK-NOT:   cute.size
// CHECK:       %[[S:.+]]:{{.+}} = cute.get_scalars<{only_dynamic}>
// CHECK-NOT:   arith.muli
// CHECK:       cute.make_int_tuple(%[[S]]#0)
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_nested_inner_mode_dynamic(
    %src: !cute.layout<"(2,(?,4),5):(1,(?,?),?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.size<[1, 0]>(%src)
         : (!cute.layout<"(2,(?,4),5):(1,(?,?),?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Nested dynamic layout, top mode collapses the sub-tuple to a single dynamic product.
// CHECK-LABEL: func.func @expand_nested_top_mode_dynamic
// CHECK-NOT:   cute.size
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       arith.muli
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_nested_top_mode_dynamic(
    %src: !cute.layout<"(2,(?,4),5):(1,(?,?),?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.size<[1]>(%src)
         : (!cute.layout<"(2,(?,4),5):(1,(?,?),?)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// 3-leaf nested dynamic sub-shape: size expansion with 2 chained arith.muli.
// CHECK-LABEL: func.func @expand_nested_3mode_dynamic
// CHECK-NOT:   cute.size
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-COUNT-2: arith.muli {{.+}} : i32
// CHECK-NOT:   arith.muli
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_nested_3mode_dynamic(
    %src: !cute.layout<"(2,(?,?,?),5):(1,(?,?,?),?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.size<[1]>(%src)
         : (!cute.layout<"(2,(?,?,?),5):(1,(?,?,?),?)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// 4-leaf nested dynamic sub-shape: size expansion with 3 chained arith.muli.
// CHECK-LABEL: func.func @expand_nested_4mode_dynamic
// CHECK-NOT:   cute.size
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-COUNT-3: arith.muli {{.+}} : i32
// CHECK-NOT:   arith.muli
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_nested_4mode_dynamic(
    %src: !cute.layout<"((?,?,?,?)):((?,?,?,?))">)
    -> !cute.int_tuple<"?"> {
  %r = cute.size<[0]>(%src)
         : (!cute.layout<"((?,?,?,?)):((?,?,?,?))">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

