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

// RUN: cute-opt %s -split-input-file | FileCheck %s
// Verify the printed output can be parsed.
// RUN: cute-opt %s -split-input-file | cute-opt | FileCheck %s
// Verify the generic form can be parsed.
// RUN: cute-opt -mlir-print-op-generic %s -split-input-file | cute-opt | FileCheck %s
// Tests round-trip for cute.get_layouts_from_tile.

// -----

// Tests extracting one layout from a single-layout tile.
// CHECK-LABEL: func.func @single_layout_tile
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(4,8):(1,4)]">)
func.func @single_layout_tile(%t: !cute.tile<"[(4,8):(1,4)]">) -> !cute.layout<"(4,8):(1,4)"> {
  // CHECK: %[[R:.+]] = cute.get_layouts_from_tile(%[[T]]) : <"[(4,8):(1,4)]">
  %l = cute.get_layouts_from_tile(%t) : !cute.tile<"[(4,8):(1,4)]">
  return %l : !cute.layout<"(4,8):(1,4)">
}

// -----

// Tests extracting two layouts from a two-layout tile.
// CHECK-LABEL: func.func @two_layout_tile
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
func.func @two_layout_tile(%t: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">) -> (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">) {
  // CHECK: %[[R:.+]]:2 = cute.get_layouts_from_tile(%[[T]]) : <"[(4,8):(1,4);(2,3):(1,2)]">
  %a, %b = cute.get_layouts_from_tile(%t) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">
}

// -----

// Tests a tile with a single underscore slot at the end — the
// underscore is silently skipped.
// CHECK-LABEL: func.func @layout_then_underscore
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[4:1;_]">)
func.func @layout_then_underscore(%t: !cute.tile<"[4:1;_]">) -> !cute.layout<"4:1"> {
  // CHECK: %[[R:.+]] = cute.get_layouts_from_tile(%[[T]]) : <"[4:1;_]">
  %a = cute.get_layouts_from_tile(%t) : !cute.tile<"[4:1;_]">
  return %a : !cute.layout<"4:1">
}

// -----

// Tests an underscore interleaved between two layout slots — DFS
// order is preserved, the underscore is skipped at its position.
// CHECK-LABEL: func.func @layout_underscore_layout
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">)
func.func @layout_underscore_layout(%t: !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">) -> (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">) {
  // CHECK: %[[R:.+]]:2 = cute.get_layouts_from_tile(%[[T]]) : <"[(4,8):(1,4);_;(2,3):(1,2)]">
  %a, %b = cute.get_layouts_from_tile(%t)
         : !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">
}


// -----

// Tests a nested tile (tile of tiles) — DFS flatten yields all
// layout leaves in left-to-right order.
// CHECK-LABEL: func.func @nested_tile
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[4:1;[2:1;3:1];5:1]">)
func.func @nested_tile(%t: !cute.tile<"[4:1;[2:1;3:1];5:1]">) -> (!cute.layout<"4:1">, !cute.layout<"2:1">, !cute.layout<"3:1">, !cute.layout<"5:1">) {
  // CHECK: %[[R:.+]]:4 = cute.get_layouts_from_tile(%[[T]]) : <"[4:1;[2:1;3:1];5:1]">
  %a, %b, %c, %d = cute.get_layouts_from_tile(%t)
                 : !cute.tile<"[4:1;[2:1;3:1];5:1]">
  return %a, %b, %c, %d : !cute.layout<"4:1">, !cute.layout<"2:1">, !cute.layout<"3:1">, !cute.layout<"5:1">
}

// -----

// Tests a tile with a dynamic layout slot — dynamic positions
// flow through to the result.
// CHECK-LABEL: func.func @dynamic_layout_slot
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">)
func.func @dynamic_layout_slot(%t: !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">) -> (!cute.layout<"(?,4):(1,?)">, !cute.layout<"(2,3):(1,2)">) {
  // CHECK: %[[R:.+]]:2 = cute.get_layouts_from_tile(%[[T]]) : <"[(?,4):(1,?);(2,3):(1,2)]">
  %a, %b = cute.get_layouts_from_tile(%t)
         : !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(?,4):(1,?)">, !cute.layout<"(2,3):(1,2)">
}

// -----

// Tests a tile with a scaled-basis layout slot — basis indices are
// preserved verbatim through the cast.
// CHECK-LABEL: func.func @scaled_basis_layout_slot
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(4,8):(1@0,1@1);(2,3):(1,2)]">)
func.func @scaled_basis_layout_slot(%t: !cute.tile<"[(4,8):(1@0,1@1);(2,3):(1,2)]">) -> (!cute.layout<"(4,8):(1@0,1@1)">, !cute.layout<"(2,3):(1,2)">) {
  // CHECK: %[[R:.+]]:2 = cute.get_layouts_from_tile(%[[T]]) : <"[(4,8):(1@0,1@1);(2,3):(1,2)]">
  %a, %b = cute.get_layouts_from_tile(%t)
         : !cute.tile<"[(4,8):(1@0,1@1);(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(4,8):(1@0,1@1)">, !cute.layout<"(2,3):(1,2)">
}
