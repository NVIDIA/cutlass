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

// Tests round-trip for cute.flatten.
// flatten collapses a layout's shape and stride mode hierarchy to depth 1.
// The codomain is preserved — only the nesting structure changes.

// -----

// Already flat: a depth-1 layout passes through unchanged.
// CHECK-LABEL: func.func @already_flat
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,3):(1,2)">)
func.func @already_flat(
    %src: !cute.layout<"(4,3):(1,2)">) -> !cute.layout<"(4,3):(1,2)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.layout<"(4,3):(1,2)">) -> !cute.layout<"(4,3):(1,2)">
  %r = cute.flatten(%src) : (!cute.layout<"(4,3):(1,2)">) -> !cute.layout<"(4,3):(1,2)">
  return %r : !cute.layout<"(4,3):(1,2)">
}

// -----

// Nested static layout: inner sub-tuple flattens into the top-level list.
// CHECK-LABEL: func.func @nested_inner
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(3,(4,5)):(8,(1,4))">)
func.func @nested_inner(
    %src: !cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,4,5):(8,1,4)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,4,5):(8,1,4)">
  %r = cute.flatten(%src)
         : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,4,5):(8,1,4)">
  return %r : !cute.layout<"(3,4,5):(8,1,4)">
}

// -----

// Both top-level modes are nested.
// CHECK-LABEL: func.func @both_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((4,3),(2,5)):((1,0),(2,4))">)
func.func @both_nested(
    %src: !cute.layout<"((4,3),(2,5)):((1,0),(2,4))">) -> !cute.layout<"(4,3,2,5):(1,0,2,4)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.layout<"((4,3),(2,5)):((1,0),(2,4))">) -> !cute.layout<"(4,3,2,5):(1,0,2,4)">
  %r = cute.flatten(%src)
         : (!cute.layout<"((4,3),(2,5)):((1,0),(2,4))">) -> !cute.layout<"(4,3,2,5):(1,0,2,4)">
  return %r : !cute.layout<"(4,3,2,5):(1,0,2,4)">
}

// -----

// Deeply nested layout (depth > 2): all nesting levels flattened in one pass.
// CHECK-LABEL: func.func @deeply_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,(3,(4,5))):(1,(2,(6,24)))">)
func.func @deeply_nested(
    %src: !cute.layout<"(2,(3,(4,5))):(1,(2,(6,24)))">) -> !cute.layout<"(2,3,4,5):(1,2,6,24)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.layout<"(2,(3,(4,5))):(1,(2,(6,24)))">) -> !cute.layout<"(2,3,4,5):(1,2,6,24)">
  %r = cute.flatten(%src)
         : (!cute.layout<"(2,(3,(4,5))):(1,(2,(6,24)))">) -> !cute.layout<"(2,3,4,5):(1,2,6,24)">
  return %r : !cute.layout<"(2,3,4,5):(1,2,6,24)">
}

// -----

// Composed layout: flatten applied to B only; A and offset unchanged.
// CHECK-LABEL: func.func @composed_layout
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">)
func.func @composed_layout(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(8,1,4)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">)
  // CHECK-SAME: -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(8,1,4)">
  %r = cute.flatten(%src)
         : (!cute.composed_layout<"(4,5):(1,4) o 2 o (3,(4,5)):(8,(1,4))">)
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(8,1,4)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (3,4,5):(8,1,4)">
}

// -----

// Composed layout with swizzle A.
// CHECK-LABEL: func.func @composed_swizzle_a
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,5,4> o 0 o (3,(4,5)):(8,(1,4))">)
func.func @composed_swizzle_a(
    %src: !cute.composed_layout<"S<3,5,4> o 0 o (3,(4,5)):(8,(1,4))">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o (3,4,5):(8,1,4)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.composed_layout<"S<3,5,4> o 0 o (3,(4,5)):(8,(1,4))">)
  // CHECK-SAME: -> !cute.composed_layout<"S<3,5,4> o 0 o (3,4,5):(8,1,4)">
  %r = cute.flatten(%src)
         : (!cute.composed_layout<"S<3,5,4> o 0 o (3,(4,5)):(8,(1,4))">)
        -> !cute.composed_layout<"S<3,5,4> o 0 o (3,4,5):(8,1,4)">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o (3,4,5):(8,1,4)">
}

// -----

// Dynamic flat layout: depth-1 already, passes through with dynamic leaves
// preserved.
// CHECK-LABEL: func.func @dynamic_flat
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(?,3):(1,?)">)
func.func @dynamic_flat(
    %src: !cute.layout<"(?,3):(1,?)">) -> !cute.layout<"(?,3):(1,?)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.layout<"(?,3):(1,?)">) -> !cute.layout<"(?,3):(1,?)">
  %r = cute.flatten(%src) : (!cute.layout<"(?,3):(1,?)">) -> !cute.layout<"(?,3):(1,?)">
  return %r : !cute.layout<"(?,3):(1,?)">
}

// -----

// Dynamic nested layout: nesting flattens while dynamic leaves are preserved.
// CHECK-LABEL: func.func @dynamic_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(3,(?,5)):(?,(1,?))">)
func.func @dynamic_nested(
    %src: !cute.layout<"(3,(?,5)):(?,(1,?))">) -> !cute.layout<"(3,?,5):(?,1,?)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.layout<"(3,(?,5)):(?,(1,?))">) -> !cute.layout<"(3,?,5):(?,1,?)">
  %r = cute.flatten(%src)
         : (!cute.layout<"(3,(?,5)):(?,(1,?))">) -> !cute.layout<"(3,?,5):(?,1,?)">
  return %r : !cute.layout<"(3,?,5):(?,1,?)">
}

// -----

// Tuple-kind input: !cute.shape — nested static shape flattens to depth 1.
// CHECK-LABEL: func.func @shape_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(3,(4,5))">)
func.func @shape_nested(%src: !cute.shape<"(3,(4,5))">) -> !cute.shape<"(3,4,5)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.shape<"(3,(4,5))">) -> !cute.shape<"(3,4,5)">
  %r = cute.flatten(%src) : (!cute.shape<"(3,(4,5))">) -> !cute.shape<"(3,4,5)">
  return %r : !cute.shape<"(3,4,5)">
}

// -----

// Tuple-kind input: !cute.stride — nested static stride flattens.
// CHECK-LABEL: func.func @stride_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.stride<"(8,(1,4))">)
func.func @stride_nested(%src: !cute.stride<"(8,(1,4))">) -> !cute.stride<"(8,1,4)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.stride<"(8,(1,4))">) -> !cute.stride<"(8,1,4)">
  %r = cute.flatten(%src) : (!cute.stride<"(8,(1,4))">) -> !cute.stride<"(8,1,4)">
  return %r : !cute.stride<"(8,1,4)">
}

// -----

// Tuple-kind input: !cute.coord — nested coord flattens.
// CHECK-LABEL: func.func @coord_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.coord<"(1,(2,3))">)
func.func @coord_nested(%src: !cute.coord<"(1,(2,3))">) -> !cute.coord<"(1,2,3)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.coord<"(1,(2,3))">) -> !cute.coord<"(1,2,3)">
  %r = cute.flatten(%src) : (!cute.coord<"(1,(2,3))">) -> !cute.coord<"(1,2,3)">
  return %r : !cute.coord<"(1,2,3)">
}

// -----

// Coord with an underscore (`_`) leaf inside a nested mode — the wildcard
// survives flattening as a top-level leaf.
// CHECK-LABEL: func.func @coord_nested_underscore
// CHECK-SAME:  (%[[SRC:.+]]: !cute.coord<"(1,(_,3))">)
func.func @coord_nested_underscore(
    %src: !cute.coord<"(1,(_,3))">) -> !cute.coord<"(1,_,3)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.coord<"(1,(_,3))">) -> !cute.coord<"(1,_,3)">
  %r = cute.flatten(%src) : (!cute.coord<"(1,(_,3))">) -> !cute.coord<"(1,_,3)">
  return %r : !cute.coord<"(1,_,3)">
}

// -----

// Tuple-kind input: !cute.int_tuple — nested int_tuple flattens.
// CHECK-LABEL: func.func @int_tuple_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(1,(2,3))">)
func.func @int_tuple_nested(
    %src: !cute.int_tuple<"(1,(2,3))">) -> !cute.int_tuple<"(1,2,3)"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.int_tuple<"(1,(2,3))">) -> !cute.int_tuple<"(1,2,3)">
  %r = cute.flatten(%src) : (!cute.int_tuple<"(1,(2,3))">) -> !cute.int_tuple<"(1,2,3)">
  return %r : !cute.int_tuple<"(1,2,3)">
}

// -----

// Tuple-kind input: !cute.tile — already-flat tile passes through.
// CHECK-LABEL: func.func @tile_flat
// CHECK-SAME:  (%[[SRC:.+]]: !cute.tile<"[(8):(1);(4):(1);(2):(1)]">)
func.func @tile_flat(
    %src: !cute.tile<"[(8):(1);(4):(1);(2):(1)]">)
    -> !cute.tile<"[(8):(1);(4):(1);(2):(1)]"> {
  // CHECK: %[[R:.+]] = cute.flatten(%[[SRC]])
  // CHECK-SAME: (!cute.tile<"[(8):(1);(4):(1);(2):(1)]">) -> !cute.tile<"[(8):(1);(4):(1);(2):(1)]">
  %r = cute.flatten(%src)
         : (!cute.tile<"[(8):(1);(4):(1);(2):(1)]">)
        -> !cute.tile<"[(8):(1);(4):(1);(2):(1)]">
  return %r : !cute.tile<"[(8):(1);(4):(1);(2):(1)]">
}

// -----

// Tile whose first slot is itself a sub-tile of two layouts, followed by an
// underscore (`_`) and a third layout. Flatten unwraps the sub-tile into the
// outer level; the `_` wildcard and the remaining layouts pass through.
// CHECK-LABEL: func.func @tile_nested_with_underscore
func.func @tile_nested_with_underscore(
    %src: !cute.tile<"[[(8):(1);(4):(1)];_;(2):(1)]">)
    -> !cute.tile<"[(8):(1);(4):(1);_;(2):(1)]"> {
  // CHECK: cute.flatten
  // CHECK-SAME: -> !cute.tile<"[(8):(1);(4):(1);_;(2):(1)]">
  %r = cute.flatten(%src)
         : (!cute.tile<"[[(8):(1);(4):(1)];_;(2):(1)]">)
        -> !cute.tile<"[(8):(1);(4):(1);_;(2):(1)]">
  return %r : !cute.tile<"[(8):(1);(4):(1);_;(2):(1)]">
}
