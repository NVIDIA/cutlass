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
// Tests round-trip for cute.get_leaves.

// -----

// Tests flattening a nested shape — returns one shape per leaf.
// CHECK-LABEL: func.func @nested_shape
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,(2,3))">)
func.func @nested_shape(%s: !cute.shape<"(4,(2,3))">) -> (!cute.shape<"4">, !cute.shape<"2">, !cute.shape<"3">) {
  // CHECK: %[[R:.+]]:3 = cute.get_leaves(%[[S]]) : !cute.shape<"(4,(2,3))">
  %a, %b, %c = cute.get_leaves(%s) : !cute.shape<"(4,(2,3))">
  return %a, %b, %c : !cute.shape<"4">, !cute.shape<"2">, !cute.shape<"3">
}

// -----

// Tests flattening an int_tuple — returns one int_tuple per leaf.
// CHECK-LABEL: func.func @nested_int_tuple
// CHECK-SAME:  (%[[I:.+]]: !cute.int_tuple<"(1,(2,3))">)
func.func @nested_int_tuple(%i: !cute.int_tuple<"(1,(2,3))">) -> (!cute.int_tuple<"1">, !cute.int_tuple<"2">, !cute.int_tuple<"3">) {
  // CHECK: %[[R:.+]]:3 = cute.get_leaves(%[[I]]) : !cute.int_tuple<"(1,(2,3))">
  %a, %b, %c = cute.get_leaves(%i) : !cute.int_tuple<"(1,(2,3))">
  return %a, %b, %c : !cute.int_tuple<"1">, !cute.int_tuple<"2">, !cute.int_tuple<"3">
}

// -----

// Tests flattening a stride — returns one stride per leaf.
// CHECK-LABEL: func.func @nested_stride
// CHECK-SAME:  (%[[ST:.+]]: !cute.stride<"(1,(4,8))">)
func.func @nested_stride(%st: !cute.stride<"(1,(4,8))">) -> (!cute.stride<"1">, !cute.stride<"4">, !cute.stride<"8">) {
  // CHECK: %[[R:.+]]:3 = cute.get_leaves(%[[ST]]) : !cute.stride<"(1,(4,8))">
  %a, %b, %c = cute.get_leaves(%st) : !cute.stride<"(1,(4,8))">
  return %a, %b, %c : !cute.stride<"1">, !cute.stride<"4">, !cute.stride<"8">
}

// -----

// Tests flattening a tile — returns one layout per layout leaf.
// CHECK-LABEL: func.func @tile_two_layouts
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
func.func @tile_two_layouts(%t: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">) -> (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">) {
  // CHECK: %[[R:.+]]:2 = cute.get_leaves(%[[T]]) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
  %a, %b = cute.get_leaves(%t) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
  return %a, %b : !cute.layout<"(4,8):(1,4)">, !cute.layout<"(2,3):(1,2)">
}

// -----

// Tests flattening a tile with an underscore — layout leaf becomes !cute.layout,
// underscore leaf becomes !cute.tile<"_">.
// CHECK-LABEL: func.func @tile_layout_and_underscore
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[4:1;_]">)
func.func @tile_layout_and_underscore(%t: !cute.tile<"[4:1;_]">) -> (!cute.layout<"4:1">, !cute.tile<"_">) {
  // CHECK: %[[R:.+]]:2 = cute.get_leaves(%[[T]]) : !cute.tile<"[4:1;_]">
  %a, %b = cute.get_leaves(%t) : !cute.tile<"[4:1;_]">
  // CHECK: return %[[R]]#0, %[[R]]#1
  return %a, %b : !cute.layout<"4:1">, !cute.tile<"_">
}

// -----

// Tests a tile with mixed layout, underscore, layout slots — underscore appears
// in the middle of the result list as !cute.tile<"_">.
// CHECK-LABEL: func.func @tile_layout_underscore_layout
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">)
func.func @tile_layout_underscore_layout(%t: !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">)
    -> (!cute.layout<"(4,8):(1,4)">, !cute.tile<"_">, !cute.layout<"(2,3):(1,2)">) {
  // CHECK: %[[R:.+]]:3 = cute.get_leaves(%[[T]]) : !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">
  %a, %b, %c = cute.get_leaves(%t) : !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">
  // CHECK: return %[[R]]#0, %[[R]]#1, %[[R]]#2
  return %a, %b, %c : !cute.layout<"(4,8):(1,4)">, !cute.tile<"_">, !cute.layout<"(2,3):(1,2)">
}

// -----

// Tests a tile with nesting on both sides — the bracket structure is
// flattened away and leaves come out in depth-first source order
// (layout, layout, layout, underscore).
// CHECK-LABEL: func.func @nested_tile_both_sides
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"{{\[}}[4:1;8:1];[3:1;_]]">)
func.func @nested_tile_both_sides(%t: !cute.tile<"[[4:1;8:1];[3:1;_]]">)
    -> (!cute.layout<"4:1">, !cute.layout<"8:1">,
        !cute.layout<"3:1">, !cute.tile<"_">) {
  // CHECK: %[[R:.+]]:4 = cute.get_leaves(%[[T]]) : !cute.tile<"{{\[}}[4:1;8:1];[3:1;_]]">
  %a, %b, %c, %d = cute.get_leaves(%t) : !cute.tile<"[[4:1;8:1];[3:1;_]]">
  // CHECK: return %[[R]]#0, %[[R]]#1, %[[R]]#2, %[[R]]#3
  return %a, %b, %c, %d :
      !cute.layout<"4:1">, !cute.layout<"8:1">,
      !cute.layout<"3:1">, !cute.tile<"_">
}

// -----

// Tests flattening a nested coord — coord is listed in the ODS as a
// supported operand kind but the round-trip suite previously only
// covered shape / int_tuple / stride / tile.
// CHECK-LABEL: func.func @nested_coord
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(2,(3,4))">)
func.func @nested_coord(%c: !cute.coord<"(2,(3,4))">)
    -> (!cute.coord<"2">, !cute.coord<"3">, !cute.coord<"4">) {
  // CHECK: %[[R:.+]]:3 = cute.get_leaves(%[[C]]) : !cute.coord<"(2,(3,4))">
  %a, %b, %d = cute.get_leaves(%c) : !cute.coord<"(2,(3,4))">
  return %a, %b, %d : !cute.coord<"2">, !cute.coord<"3">, !cute.coord<"4">
}

// -----

// Dynamic leaves preserve their dyn-ness on the per-leaf result.
// CHECK-LABEL: func.func @dynamic_shape_leaves
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(?,(?,3))">)
func.func @dynamic_shape_leaves(%s: !cute.shape<"(?,(?,3))">)
    -> (!cute.shape<"?">, !cute.shape<"?">, !cute.shape<"3">) {
  // CHECK: %[[R:.+]]:3 = cute.get_leaves(%[[S]]) : !cute.shape<"(?,(?,3))">
  %a, %b, %c = cute.get_leaves(%s) : !cute.shape<"(?,(?,3))">
  return %a, %b, %c : !cute.shape<"?">, !cute.shape<"?">, !cute.shape<"3">
}

// -----

// Dynamic + static sibling round-trip — each leaf is delivered to
// its own per-result slot.
// CHECK-LABEL: func.func @shape_dyn_static_leaves
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(?,5)">)
func.func @shape_dyn_static_leaves(%s: !cute.shape<"(?,5)">)
    -> (!cute.shape<"?">, !cute.shape<"5">) {
  // CHECK: %[[R:.+]]:2 = cute.get_leaves(%[[S]]) : !cute.shape<"(?,5)">
  %a, %b = cute.get_leaves(%s) : !cute.shape<"(?,5)">
  return %a, %b : !cute.shape<"?">, !cute.shape<"5">
}

// -----

// Same for int_tuple — nested static sub-tuple flattens to one
// per-leaf int_tuple result alongside the dyn leaf.
// CHECK-LABEL: func.func @int_tuple_dyn_static_leaves
// CHECK-SAME:  (%[[I:.+]]: !cute.int_tuple<"(?,(2,3))">)
func.func @int_tuple_dyn_static_leaves(%i: !cute.int_tuple<"(?,(2,3))">)
    -> (!cute.int_tuple<"?">, !cute.int_tuple<"2">, !cute.int_tuple<"3">) {
  // CHECK: %[[R:.+]]:3 = cute.get_leaves(%[[I]]) : !cute.int_tuple<"(?,(2,3))">
  %a, %b, %c = cute.get_leaves(%i) : !cute.int_tuple<"(?,(2,3))">
  return %a, %b, %c : !cute.int_tuple<"?">, !cute.int_tuple<"2">, !cute.int_tuple<"3">
}

// -----

// Scaled-basis stride leaves — each basis vector becomes its own
// single-leaf stride result.
// CHECK-LABEL: func.func @scaled_basis_stride_leaves
// CHECK-SAME:  (%[[ST:.+]]: !cute.stride<"(1@0,(?@1,1@2))">)
func.func @scaled_basis_stride_leaves(%st: !cute.stride<"(1@0,(?@1,1@2))">)
    -> (!cute.stride<"1@0">, !cute.stride<"?@1">, !cute.stride<"1@2">) {
  // CHECK: %[[R:.+]]:3 = cute.get_leaves(%[[ST]]) : !cute.stride<"(1@0,(?@1,1@2))">
  %a, %b, %c = cute.get_leaves(%st) : !cute.stride<"(1@0,(?@1,1@2))">
  return %a, %b, %c : !cute.stride<"1@0">, !cute.stride<"?@1">, !cute.stride<"1@2">
}

// -----

// Rank-1 scalar input — degenerate case, single result equal to the input.
// CHECK-LABEL: func.func @scalar_shape
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"4">)
func.func @scalar_shape(%s: !cute.shape<"4">) -> !cute.shape<"4"> {
  // CHECK: %[[R:.+]] = cute.get_leaves(%[[S]]) : !cute.shape<"4">
  %a = cute.get_leaves(%s) : !cute.shape<"4">
  return %a : !cute.shape<"4">
}

// -----

// Deep nesting (3+ levels) — leaves are emitted in depth-first
// left-to-right order regardless of nesting depth.
// CHECK-LABEL: func.func @deep_nested
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(2,(3,(4,5)),6)">)
func.func @deep_nested(%s: !cute.shape<"(2,(3,(4,5)),6)">)
    -> (!cute.shape<"2">, !cute.shape<"3">, !cute.shape<"4">, !cute.shape<"5">, !cute.shape<"6">) {
  // CHECK: %[[R:.+]]:5 = cute.get_leaves(%[[S]]) : !cute.shape<"(2,(3,(4,5)),6)">
  %a, %b, %c, %d, %e = cute.get_leaves(%s) : !cute.shape<"(2,(3,(4,5)),6)">
  return %a, %b, %c, %d, %e : !cute.shape<"2">, !cute.shape<"3">, !cute.shape<"4">, !cute.shape<"5">, !cute.shape<"6">
}
