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

// Tests `cute-expand-ops` lowering for `cute.coalesce`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.coalesce
// CHECK:       cute.static : !cute.layout<"20:1">
func.func @expand_static(%input: !cute.layout<"(4,5):(1,4)">)
    -> !cute.layout<"20:1"> {
  %r = cute.coalesce(%input) : (!cute.layout<"(4,5):(1,4)">) -> !cute.layout<"20:1">
  return %r : !cute.layout<"20:1">
}

// -----

// CHECK-LABEL: func.func @expand_layout_dynamic
// CHECK-NOT:   cute.coalesce
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"?:?">
func.func @expand_layout_dynamic(%input: !cute.layout<"(?):(?)">)
    -> !cute.layout<"?:?"> {
  %r = cute.coalesce(%input) : (!cute.layout<"(?):(?)">) -> !cute.layout<"?:?">
  return %r : !cute.layout<"?:?">
}

// -----

// Composed layout result — uses allowDecay=false so the wrap is preserved.
// CHECK-LABEL: func.func @expand_composed_layout_dynamic
// CHECK-NOT:   cute.coalesce
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_composed_layout
// CHECK-SAME:  -> <"S<3,5,4> o 0 o ?:?">
func.func @expand_composed_layout_dynamic(
    %input: !cute.composed_layout<"S<3,5,4> o 0 o (?):(?)">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o ?:?"> {
  %r = cute.coalesce(%input)
         : (!cute.composed_layout<"S<3,5,4> o 0 o (?):(?)">)
        -> !cute.composed_layout<"S<3,5,4> o 0 o ?:?">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o ?:?">
}

// -----

// Nested static input — inner mode (4,5):(1,4) coalesces to 20:1, outer
// mode 3:8 stays. Whole result folds via the static short-circuit.
// CHECK-LABEL: func.func @expand_nested_static
// CHECK-NOT:   cute.coalesce
// CHECK:       cute.static : !cute.layout<"(3,20):(8,1)">
func.func @expand_nested_static(%input: !cute.layout<"(3,(4,5)):(8,(1,4))">)
    -> !cute.layout<"(3,20):(8,1)"> {
  %r = cute.coalesce(%input)
         : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,20):(8,1)">
  return %r : !cute.layout<"(3,20):(8,1)">
}

// -----

// With target_profile, static input — per-mode coalesce produces a fully
// static result, so the lowering folds to `cute.static`.
// CHECK-LABEL: func.func @expand_with_profile_static
// CHECK-NOT:   cute.coalesce
// CHECK:       cute.static : !cute.layout<"(3,20):(8,1)">
func.func @expand_with_profile_static(
    %input: !cute.layout<"(3,(4,5)):(8,(1,4))">,
    %prof: !cute.coord<"(1,1)">) -> !cute.layout<"(3,20):(8,1)"> {
  %r = cute.coalesce(%input, %prof)
         : (!cute.layout<"(3,(4,5)):(8,(1,4))">, !cute.coord<"(1,1)">)
        -> !cute.layout<"(3,20):(8,1)">
  return %r : !cute.layout<"(3,20):(8,1)">
}

// -----

// With target_profile and dynamic input, per-mode coalesce rebuilds via make_layout.
// CHECK-LABEL: func.func @expand_with_profile_dynamic
// CHECK-NOT:   cute.coalesce
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(4,?):(1,4)">
func.func @expand_with_profile_dynamic(
    %input: !cute.layout<"(4,?):(1,4)">,
    %prof: !cute.coord<"(1,1)">) -> !cute.layout<"(4,?):(1,4)"> {
  %r = cute.coalesce(%input, %prof)
         : (!cute.layout<"(4,?):(1,4)">, !cute.coord<"(1,1)">)
        -> !cute.layout<"(4,?):(1,4)">
  return %r : !cute.layout<"(4,?):(1,4)">
}

// -----

// Dynamic middle mode blocks neighbours; flanking static groups coalesce independently.
// CHECK-LABEL: func.func @expand_dyn_middle_blocks_merge
// CHECK-NOT:   cute.coalesce
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(20,?,6):(1,?,1)">
func.func @expand_dyn_middle_blocks_merge(
    %input: !cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">)
    -> !cute.layout<"(20,?,6):(1,?,1)"> {
  %r = cute.coalesce(%input)
         : (!cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">)
        -> !cute.layout<"(20,?,6):(1,?,1)">
  return %r : !cute.layout<"(20,?,6):(1,?,1)">
}
