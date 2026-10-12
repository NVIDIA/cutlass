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

// Tests `cute-expand-ops` lowering for `cute.cosize`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.cosize
// CHECK:       cute.static : !cute.int_tuple<"24">
func.func @expand_static(%src: !cute.layout<"(4,3,2):(1,4,12)">)
    -> !cute.int_tuple<"24"> {
  %r = cute.cosize(%src)
         : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24">
  return %r : !cute.int_tuple<"24">
}

// -----

// Static cosize with mode — cosize of sub-layout at mode 1 = (3-1)*4+1 = 9.
// CHECK-LABEL: func.func @expand_with_mode
// CHECK-NOT:   cute.cosize
// CHECK:       cute.static : !cute.int_tuple<"9">
func.func @expand_with_mode(%src: !cute.layout<"(4,3,2):(1,4,12)">)
    -> !cute.int_tuple<"9"> {
  %r = cute.cosize<[1]>(%src)
         : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}

// -----

// CHECK-LABEL: func.func @expand_layout_dynamic
// CHECK-NOT:   cute.cosize
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_layout_dynamic(%src: !cute.layout<"(?,?,?):(?,?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.cosize(%src)
         : (!cute.layout<"(?,?,?):(?,?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// CHECK-LABEL: func.func @expand_composed_dynamic
// CHECK-NOT:   cute.cosize
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_composed_dynamic(
    %src: !cute.composed_layout<"S<3,5,4> o 0 o (?,?):(?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.cosize(%src)
         : (!cute.composed_layout<"S<3,5,4> o 0 o (?,?):(?,?)">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Nested static layout.
// CHECK-LABEL: func.func @expand_nested_static
// CHECK-NOT:   cute.cosize
// CHECK:       cute.static : !cute.int_tuple<"120">
func.func @expand_nested_static(
    %src: !cute.layout<"(4,(3,2),5):(1,(4,12),24)">)
    -> !cute.int_tuple<"120"> {
  %r = cute.cosize(%src)
         : (!cute.layout<"(4,(3,2),5):(1,(4,12),24)">)
        -> !cute.int_tuple<"120">
  return %r : !cute.int_tuple<"120">
}

// -----

// Nested static layout, top-mode `[1]` cosize of sub-layout.
// CHECK-LABEL: func.func @expand_nested_top_mode
// CHECK-NOT:   cute.cosize
// CHECK:       cute.static : !cute.int_tuple<"21">
func.func @expand_nested_top_mode(
    %src: !cute.layout<"(4,(3,2),5):(1,(4,12),24)">)
    -> !cute.int_tuple<"21"> {
  %r = cute.cosize<[1]>(%src)
         : (!cute.layout<"(4,(3,2),5):(1,(4,12),24)">) -> !cute.int_tuple<"21">
  return %r : !cute.int_tuple<"21">
}

// -----

// Nested static layout, nested mode `[1, 0]` cosize of leaf.
// CHECK-LABEL: func.func @expand_nested_inner_mode
// CHECK-NOT:   cute.cosize
// CHECK:       cute.static : !cute.int_tuple<"9">
func.func @expand_nested_inner_mode(
    %src: !cute.layout<"(4,(3,2),5):(1,(4,12),24)">)
    -> !cute.int_tuple<"9"> {
  %r = cute.cosize<[1, 0]>(%src)
         : (!cute.layout<"(4,(3,2),5):(1,(4,12),24)">) -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}

// -----

// Nested dynamic layout, nested mode [1, 1] selects the dynamic leaf.
// CHECK-LABEL: func.func @expand_nested_inner_mode_dynamic
// CHECK-NOT:   cute.cosize
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       math.absi
// CHECK:       arith.addi
// CHECK:       arith.muli
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_nested_inner_mode_dynamic(
    %src: !cute.layout<"(4,(3,?),5):(1,(4,?),?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.cosize<[1, 1]>(%src)
         : (!cute.layout<"(4,(3,?),5):(1,(4,?),?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// 3-leaf nested dynamic sub-layout.
// CHECK-LABEL: func.func @expand_nested_3mode_dynamic
// CHECK-NOT:   cute.cosize
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-COUNT-3: math.absi {{.+}} : i32
// CHECK-NOT:   math.absi
// CHECK-COUNT-3: arith.addi {{.+}} : i32
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_nested_3mode_dynamic(
    %src: !cute.layout<"(2,(?,?,?),5):(1,(?,?,?),?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.cosize<[1]>(%src)
         : (!cute.layout<"(2,(?,?,?),5):(1,(?,?,?),?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Static swizzle-composed layout with deep mode [1,0,1].
// CHECK-LABEL: func.func @expand_static_composed_with_mode
// CHECK-NOT:   cute.cosize
// CHECK:       cute.static : !cute.int_tuple<"109">
func.func @expand_static_composed_with_mode(
    %src: !cute.composed_layout<"S<3,4,6> o 0 o ((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
    -> !cute.int_tuple<"109"> {
  %r = cute.cosize<[1, 0, 1]>(%src)
         : (!cute.composed_layout<"S<3,4,6> o 0 o ((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
        -> !cute.int_tuple<"109">
  return %r : !cute.int_tuple<"109">
}

// -----

// Flat dynamic layout.
// CHECK-LABEL: func.func @expand_flat_dynamic_with_mode
// CHECK-NOT:   cute.cosize
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-COUNT-1: math.absi {{.+}} : i32
// CHECK-NOT:   math.absi
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_flat_dynamic_with_mode(%src: !cute.layout<"(?,?,?):(?,?,?)">)
    -> !cute.int_tuple<"?"> {
  %r = cute.cosize<[1]>(%src)
         : (!cute.layout<"(?,?,?):(?,?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Deeply-nested static layout with deep mode [1,0,1].
// CHECK-LABEL: func.func @expand_nested_static_deep_mode
// CHECK-NOT:   cute.cosize
// CHECK:       cute.static : !cute.int_tuple<"109">
func.func @expand_nested_static_deep_mode(
    %src: !cute.layout<"((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
    -> !cute.int_tuple<"109"> {
  %r = cute.cosize<[1, 0, 1]>(%src)
         : (!cute.layout<"((4,3),((3,(2,2)),2)):((1,4),((12,(36,72)),144))">)
        -> !cute.int_tuple<"109">
  return %r : !cute.int_tuple<"109">
}

// -----

// Dynamic swizzle-composed layout with deep mode [1,0,1].
// CHECK-LABEL: func.func @expand_swizzle_composed_dynamic_with_mode
// CHECK-NOT:   cute.cosize
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       math.absi
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_swizzle_composed_dynamic_with_mode(
    %src: !cute.composed_layout<"S<3,4,6> o ? o ((?,?),((?,?),?)):((?,?),((?,?),?))">)
    -> !cute.int_tuple<"?"> {
  %r = cute.cosize<[1, 0, 1]>(%src)
         : (!cute.composed_layout<"S<3,4,6> o ? o ((?,?),((?,?),?)):((?,?),((?,?),?))">)
        -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Deeply-nested dynamic layout with deep mode [1,0,1].
// CHECK-LABEL: func.func @expand_nested_dynamic_deep_mode
// CHECK-NOT:   cute.cosize
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK-COUNT-1: math.absi {{.+}} : i32
// CHECK-NOT:   math.absi
// CHECK:       cute.make_int_tuple
// CHECK-SAME:  -> !cute.int_tuple<"?">
func.func @expand_nested_dynamic_deep_mode(
    %src: !cute.layout<"((?,?),((?,?),?)):((?,?),((?,?),?))">)
    -> !cute.int_tuple<"?"> {
  %r = cute.cosize<[1, 0, 1]>(%src)
         : (!cute.layout<"((?,?),((?,?),?)):((?,?),((?,?),?))">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
