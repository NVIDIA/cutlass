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
// Tests round-trip for cute.get.

// -----

// Tests identity get (no mode) — result equals input.
// CHECK-LABEL: func.func @no_mode_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
func.func @no_mode_layout(%l: !cute.layout<"(4,8):(1,4)">) -> !cute.layout<"(4,8):(1,4)"> {
  // CHECK: %[[R:.+]] = cute.get (%[[L]]) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4,8):(1,4)">
  %r = cute.get (%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4,8):(1,4)">
  // CHECK: return %[[R]]
  return %r : !cute.layout<"(4,8):(1,4)">
}

// -----

// Tests get<[0]> extracting the first mode of a layout.
// CHECK-LABEL: func.func @mode0_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
func.func @mode0_layout(%l: !cute.layout<"(4,8):(1,4)">) -> !cute.layout<"4:1"> {
  // CHECK: %[[R:.+]] = cute.get<[0]> (%[[L]]) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"4:1">
  %r = cute.get<[0]> (%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"4:1">
  // CHECK: return %[[R]]
  return %r : !cute.layout<"4:1">
}

// -----

// Tests get<[1]> on an int_tuple.
// CHECK-LABEL: func.func @mode1_int_tuple
// CHECK-SAME:  (%[[I:.+]]: !cute.int_tuple<"(3,(4,5))">)
func.func @mode1_int_tuple(%i: !cute.int_tuple<"(3,(4,5))">) -> !cute.int_tuple<"(4,5)"> {
  // CHECK: %[[R:.+]] = cute.get<[1]> (%[[I]]) : !cute.int_tuple<"(3,(4,5))"> -> !cute.int_tuple<"(4,5)">
  %r = cute.get<[1]> (%i) : !cute.int_tuple<"(3,(4,5))"> -> !cute.int_tuple<"(4,5)">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"(4,5)">
}

// -----

// Tests get<[1]> on a coord.
// CHECK-LABEL: func.func @mode1_coord
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(2,3)">)
func.func @mode1_coord(%c: !cute.coord<"(2,3)">) -> !cute.coord<"3"> {
  // CHECK: %[[R:.+]] = cute.get<[1]> (%[[C]]) : !cute.coord<"(2,3)"> -> !cute.coord<"3">
  %r = cute.get<[1]> (%c) : !cute.coord<"(2,3)"> -> !cute.coord<"3">
  // CHECK: return %[[R]]
  return %r : !cute.coord<"3">
}

// -----

// Tests hierarchical get<[1, 0]> descending into a nested shape.
// (4,(2,3)) → mode 1 is (2,3) → mode 0 of that is 2.
// CHECK-LABEL: func.func @hierarchical_shape
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,(2,3))">)
func.func @hierarchical_shape(%s: !cute.shape<"(4,(2,3))">) -> !cute.shape<"2"> {
  // CHECK: %[[R:.+]] = cute.get<[1, 0]> (%[[S]]) : !cute.shape<"(4,(2,3))"> -> !cute.shape<"2">
  %r = cute.get<[1, 0]> (%s) : !cute.shape<"(4,(2,3))"> -> !cute.shape<"2">
  // CHECK: return %[[R]]
  return %r : !cute.shape<"2">
}

// -----

// Tests hierarchical get<[1, 0]> and <[1, 1]> on a nested int_tuple.
// CHECK-LABEL: func.func @hierarchical_int_tuple
// CHECK-SAME:  (%[[I:.+]]: !cute.int_tuple<"(3,(4,5))">)
func.func @hierarchical_int_tuple(%i: !cute.int_tuple<"(3,(4,5))">) {
  // CHECK: %[[R0:.+]] = cute.get<[1, 0]> (%[[I]]) : !cute.int_tuple<"(3,(4,5))"> -> !cute.int_tuple<"4">
  %r0 = cute.get<[1, 0]> (%i) : !cute.int_tuple<"(3,(4,5))"> -> !cute.int_tuple<"4">
  // CHECK: %[[R1:.+]] = cute.get<[1, 1]> (%[[I]]) : !cute.int_tuple<"(3,(4,5))"> -> !cute.int_tuple<"5">
  %r1 = cute.get<[1, 1]> (%i) : !cute.int_tuple<"(3,(4,5))"> -> !cute.int_tuple<"5">
  return
}

// -----

// Tests hierarchical get<[0, 1]> on a nested layout.
// CHECK-LABEL: func.func @hierarchical_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"((4,2),(3,8)):((1,4),(8,24))">)
func.func @hierarchical_layout(%l: !cute.layout<"((4,2),(3,8)):((1,4),(8,24))">) -> !cute.layout<"2:4"> {
  // CHECK: %[[R:.+]] = cute.get<[0, 1]> (%[[L]]) : !cute.layout<"((4,2),(3,8)):((1,4),(8,24))"> -> !cute.layout<"2:4">
  %r = cute.get<[0, 1]> (%l) : !cute.layout<"((4,2),(3,8)):((1,4),(8,24))"> -> !cute.layout<"2:4">
  // CHECK: return %[[R]]
  return %r : !cute.layout<"2:4">
}

// -----

// Tests 3-level hierarchical get<[1, 1, 0]> on a deeply nested shape.
// CHECK-LABEL: func.func @three_level_shape
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,(2,(3,5)))">)
func.func @three_level_shape(%s: !cute.shape<"(4,(2,(3,5)))">) -> !cute.shape<"3"> {
  // CHECK: %[[R:.+]] = cute.get<[1, 1, 0]> (%[[S]]) : !cute.shape<"(4,(2,(3,5)))"> -> !cute.shape<"3">
  %r = cute.get<[1, 1, 0]> (%s) : !cute.shape<"(4,(2,(3,5)))"> -> !cute.shape<"3">
  // CHECK: return %[[R]]
  return %r : !cute.shape<"3">
}

// -----

// Tests 3-level hierarchical get<[0, 0, 1]> on a deeply nested layout.
// CHECK-LABEL: func.func @three_level_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(((4,2),3),(8,16)):(((1,4),8),(24,384))">)
func.func @three_level_layout(%l: !cute.layout<"(((4,2),3),(8,16)):(((1,4),8),(24,384))">) -> !cute.layout<"2:4"> {
  // CHECK: %[[R:.+]] = cute.get<[0, 0, 1]> (%[[L]]) : !cute.layout<"(((4,2),3),(8,16)):(((1,4),8),(24,384))"> -> !cute.layout<"2:4">
  %r = cute.get<[0, 0, 1]> (%l) : !cute.layout<"(((4,2),3),(8,16)):(((1,4),8),(24,384))"> -> !cute.layout<"2:4">
  // CHECK: return %[[R]]
  return %r : !cute.layout<"2:4">
}

// -----

// Tests identity get (no mode) on an int_tuple.
// CHECK-LABEL: func.func @no_mode_int_tuple
// CHECK-SAME:  (%[[I:.+]]: !cute.int_tuple<"(3,4)">)
func.func @no_mode_int_tuple(%i: !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(3,4)"> {
  // CHECK: %[[R:.+]] = cute.get (%[[I]]) : !cute.int_tuple<"(3,4)"> -> !cute.int_tuple<"(3,4)">
  %r = cute.get (%i) : !cute.int_tuple<"(3,4)"> -> !cute.int_tuple<"(3,4)">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"(3,4)">
}

// -----

// Dynamic leaf.
// CHECK-LABEL: func.func @flat_leaf
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(?,5)">)
func.func @flat_leaf(%s: !cute.shape<"(?,5)">) -> !cute.shape<"?"> {
  // CHECK: cute.get<[0]> (%[[S]]) : !cute.shape<"(?,5)"> -> !cute.shape<"?">
  %r = cute.get<[0]> (%s) : !cute.shape<"(?,5)"> -> !cute.shape<"?">
  return %r : !cute.shape<"?">
}

// -----

// Hierarchical descent
// CHECK-LABEL: func.func @hierarchical_leaf
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,(?,3))">)
func.func @hierarchical_leaf(%s: !cute.shape<"(4,(?,3))">) -> !cute.shape<"?"> {
  // CHECK: cute.get<[1, 0]> (%[[S]]) : !cute.shape<"(4,(?,3))"> -> !cute.shape<"?">
  %r = cute.get<[1, 0]> (%s) : !cute.shape<"(4,(?,3))"> -> !cute.shape<"?">
  return %r : !cute.shape<"?">
}

// -----

// Same flow on an int_tuple.
// CHECK-LABEL: func.func @int_tuple_leaf
// CHECK-SAME:  (%[[I:.+]]: !cute.int_tuple<"(?,(2,3))">)
func.func @int_tuple_leaf(%i: !cute.int_tuple<"(?,(2,3))">) -> !cute.int_tuple<"?"> {
  // CHECK: cute.get<[0]> (%[[I]]) : !cute.int_tuple<"(?,(2,3))"> -> !cute.int_tuple<"?">
  %r = cute.get<[0]> (%i) : !cute.int_tuple<"(?,(2,3))"> -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Tile operand picking a layout slot — result is a single-slot tile
// NOT a bare layout.
// CHECK-LABEL: func.func @tile_mode0
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
func.func @tile_mode0(%t: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">) -> !cute.tile<"(4,8):(1,4)"> {
  // CHECK: cute.get<[0]> (%[[T]]) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]"> -> !cute.tile<"(4,8):(1,4)">
  %r = cute.get<[0]> (%t) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]"> -> !cute.tile<"(4,8):(1,4)">
  return %r : !cute.tile<"(4,8):(1,4)">
}

// -----

// Tile operand picking an underscore slot — result is `!cute.tile<"_">`.
// CHECK-LABEL: func.func @tile_underscore_slot
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(4,8):(1,4);_]">)
func.func @tile_underscore_slot(%t: !cute.tile<"[(4,8):(1,4);_]">) -> !cute.tile<"_"> {
  // CHECK: cute.get<[1]> (%[[T]]) : !cute.tile<"[(4,8):(1,4);_]"> -> !cute.tile<"_">
  %r = cute.get<[1]> (%t) : !cute.tile<"[(4,8):(1,4);_]"> -> !cute.tile<"_">
  return %r : !cute.tile<"_">
}

// -----

// ComposedLayout operand — mode is applied to the outer B layout; the
// inner A and offset are preserved. Result is still a composed_layout
// (NOT a layout) with the sub-outer.
// CHECK-LABEL: func.func @composed_layout_mode0
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">)
func.func @composed_layout_mode0(%cl: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o 2:1"> {
  // CHECK: cute.get<[0]> (%[[CL]])
  // CHECK-SAME: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)"> -> !cute.composed_layout<"(4,5):(1,4) o 2 o 2:1">
  %r = cute.get<[0]> (%cl)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o 2:1">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o 2:1">
}

// -----

// Empty mode `<[]>` is equivalent to absent mode (identity).
// CHECK-LABEL: func.func @empty_mode_identity
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
func.func @empty_mode_identity(%l: !cute.layout<"(4,8):(1,4)">) -> !cute.layout<"(4,8):(1,4)"> {
  // CHECK: cute.get<[]> (%[[L]]) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4,8):(1,4)">
  %r = cute.get<[]> (%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4,8):(1,4)">
  return %r : !cute.layout<"(4,8):(1,4)">
}
