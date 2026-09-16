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

// Tests `cute-expand-ops` lowering for `cute.get_layouts_from_tile`.

// -----

// All static: every layout result folds to `cute.static`.
// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.get_layouts_from_tile
// CHECK-DAG:   cute.static : !cute.layout<"(4,8):(1,4)">
// CHECK-DAG:   cute.static : !cute.layout<"(2,3):(1,2)">
func.func @expand_static(%t: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
    -> (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">) {
  %a, %b = cute.get_layouts_from_tile(%t)
             : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">
}

// -----

// Mixed: dynamic layout slot rebuilds via make_*; static slot folds.
// CHECK-LABEL: func.func @expand_mixed
// CHECK-NOT:   cute.get_layouts_from_tile
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,4):(1,?)">
// CHECK:       cute.static : !cute.layout<"(2,3):(1,2)">
func.func @expand_mixed(%t: !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">)
    -> (!cute.layout<"(?,4):(1,?)">, !cute.layout<"(2,3):(1,2)">) {
  %a, %b = cute.get_layouts_from_tile(%t)
             : !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(?,4):(1,?)">, !cute.layout<"(2,3):(1,2)">
}

// -----

// Tile with one layout and one underscore — `get_layouts_from_tile`
// returns only the layout slot; the underscore is skipped.
// CHECK-LABEL: func.func @expand_layout_and_underscore
// CHECK-NOT:   cute.get_layouts_from_tile
// CHECK:       cute.static : !cute.layout<"4:1">
// CHECK-NOT:   cute.tile
func.func @expand_layout_and_underscore(%t: !cute.tile<"[4:1;_]">)
    -> !cute.layout<"4:1"> {
  %a = cute.get_layouts_from_tile(%t) : !cute.tile<"[4:1;_]">
  return %a : !cute.layout<"4:1">
}

// -----

// Underscore between two layout slots — both layouts come out, underscore
// is dropped.
// CHECK-LABEL: func.func @expand_layout_underscore_layout
// CHECK-NOT:   cute.get_layouts_from_tile
// CHECK-DAG:   cute.static : !cute.layout<"(4,8):(1,4)">
// CHECK-DAG:   cute.static : !cute.layout<"(2,3):(1,2)">
func.func @expand_layout_underscore_layout(
    %t: !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">)
    -> (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">) {
  %a, %b = cute.get_layouts_from_tile(%t)
             : !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">
}

// -----

// Dynamic layout + underscore: layout rebuilds via make_*; the underscore
// slot is dropped from the result list, so only one result is produced.
// CHECK-LABEL: func.func @expand_dynamic_layout_and_underscore
// CHECK-NOT:   cute.get_layouts_from_tile
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,4):(1,?)">
func.func @expand_dynamic_layout_and_underscore(
    %t: !cute.tile<"[(?,4):(1,?);_]">) -> !cute.layout<"(?,4):(1,?)"> {
  %a = cute.get_layouts_from_tile(%t) : !cute.tile<"[(?,4):(1,?);_]">
  return %a : !cute.layout<"(?,4):(1,?)">
}

// -----

// Tile with a scaled-basis layout slot (static): folds.
// CHECK-LABEL: func.func @expand_scaled_basis_static
// CHECK-NOT:   cute.get_layouts_from_tile
// CHECK-DAG:   cute.static : !cute.layout<"(4,8):(1@0,1@1)">
// CHECK-DAG:   cute.static : !cute.layout<"(2,3):(1,2)">
func.func @expand_scaled_basis_static(
    %t: !cute.tile<"[(4,8):(1@0,1@1);(2,3):(1,2)]">)
    -> (!cute.layout<"(4,8):(1@0,1@1)">, !cute.layout<"(2,3):(1,2)">) {
  %a, %b = cute.get_layouts_from_tile(%t)
             : !cute.tile<"[(4,8):(1@0,1@1);(2,3):(1,2)]">
  return %a, %b
      : !cute.layout<"(4,8):(1@0,1@1)">, !cute.layout<"(2,3):(1,2)">
}

// -----

// Tile with a dynamic scaled-basis layout slot: dynamic stride leaves
// rebuild via make_layout.
// CHECK-LABEL: func.func @expand_scaled_basis_dynamic
// CHECK-NOT:   cute.get_layouts_from_tile
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       cute.make_layout
// CHECK-SAME:  -> !cute.layout<"(?,?):(?@0,?@1)">
func.func @expand_scaled_basis_dynamic(
    %t: !cute.tile<"[(?,?):(?@0,?@1);(2,3):(1,2)]">)
    -> (!cute.layout<"(?,?):(?@0,?@1)">, !cute.layout<"(2,3):(1,2)">) {
  %a, %b = cute.get_layouts_from_tile(%t)
             : !cute.tile<"[(?,?):(?@0,?@1);(2,3):(1,2)]">
  return %a, %b
      : !cute.layout<"(?,?):(?@0,?@1)">, !cute.layout<"(2,3):(1,2)">
}

// -----

// Nested tile (tile of tiles): DFS flatten yields all layout leaves
// in left-to-right order. Each result folds via the static
// short-circuit since every leaf is static.
// CHECK-LABEL: func.func @expand_nested_tile
// CHECK-NOT:   cute.get_layouts_from_tile
// CHECK-DAG:   cute.static : !cute.layout<"4:1">
// CHECK-DAG:   cute.static : !cute.layout<"2:1">
// CHECK-DAG:   cute.static : !cute.layout<"3:1">
// CHECK-DAG:   cute.static : !cute.layout<"5:1">
func.func @expand_nested_tile(%t: !cute.tile<"[4:1;[2:1;3:1];5:1]">)
    -> (!cute.layout<"4:1">, !cute.layout<"2:1">, !cute.layout<"3:1">,
        !cute.layout<"5:1">) {
  %a, %b, %c, %d = cute.get_layouts_from_tile(%t)
                 : !cute.tile<"[4:1;[2:1;3:1];5:1]">
  return %a, %b, %c, %d
      : !cute.layout<"4:1">, !cute.layout<"2:1">,
        !cute.layout<"3:1">, !cute.layout<"5:1">
}
