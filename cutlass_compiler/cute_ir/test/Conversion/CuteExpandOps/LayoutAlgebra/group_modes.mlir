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

// Tests `cute-expand-ops` lowering for `cute.group_modes`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.group_modes
// CHECK:       cute.static : !cute.layout<"((4,5),6):((1,4),20)">
func.func @expand_static(%input: !cute.layout<"(4,5,6):(1,4,20)">)
    -> !cute.layout<"((4,5),6):((1,4),20)"> {
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.layout<"(4,5,6):(1,4,20)">)
        -> !cute.layout<"((4,5),6):((1,4),20)">
  return %r : !cute.layout<"((4,5),6):((1,4),20)">
}

// -----

// CHECK-LABEL: func.func @expand_layout_dynamic
// CHECK-NOT:   cute.group_modes
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"((?,5),6):((1,?),?)">
func.func @expand_layout_dynamic(%input: !cute.layout<"(?,5,6):(1,?,?)">)
    -> !cute.layout<"((?,5),6):((1,?),?)"> {
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.layout<"(?,5,6):(1,?,?)">)
        -> !cute.layout<"((?,5),6):((1,?),?)">
  return %r : !cute.layout<"((?,5),6):((1,?),?)">
}

// -----

// Composed layout — wrap preserved (allowDecay=false).
// CHECK-LABEL: func.func @expand_composed_layout_dynamic
// CHECK-NOT:   cute.group_modes
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"S<3,5,4> o 0 o ((?,5),6):((1,?),?)">
func.func @expand_composed_layout_dynamic(
    %input: !cute.composed_layout<"S<3,5,4> o 0 o (?,5,6):(1,?,?)">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o ((?,5),6):((1,?),?)"> {
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.composed_layout<"S<3,5,4> o 0 o (?,5,6):(1,?,?)">)
        -> !cute.composed_layout<"S<3,5,4> o 0 o ((?,5),6):((1,?),?)">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o ((?,5),6):((1,?),?)">
}

// -----

// Composed layout, all-static — folds to cute.static (Path 1 for composed).
// CHECK-LABEL: func.func @expand_composed_static
// CHECK-NOT:   cute.group_modes
// CHECK:       cute.static : !cute.composed_layout<"S<3,4,3> o 0 o ((4,5),6):((1,4),20)">
func.func @expand_composed_static(
    %input: !cute.composed_layout<"S<3,4,3> o 0 o (4,5,6):(1,4,20)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((4,5),6):((1,4),20)"> {
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.composed_layout<"S<3,4,3> o 0 o (4,5,6):(1,4,20)">)
        -> !cute.composed_layout<"S<3,4,3> o 0 o ((4,5),6):((1,4),20)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((4,5),6):((1,4),20)">
}

// -----

// Composed layout with layout-A and dynamic B.
// CHECK-LABEL: func.func @expand_composed_layout_a_dyn_b
// CHECK-NOT:   cute.group_modes
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"(4,5):(1,4) o 2 o ((?,5),6):((1,?),20)">
func.func @expand_composed_layout_a_dyn_b(
    %input: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,5,6):(1,?,20)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((?,5),6):((1,?),20)"> {
  %r = cute.group_modes<0, 2>(%input)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (?,5,6):(1,?,20)">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((?,5),6):((1,?),20)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o ((?,5),6):((1,?),20)">
}
