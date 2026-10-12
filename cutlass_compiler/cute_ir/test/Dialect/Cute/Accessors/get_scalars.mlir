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
// Tests round-trip for cute.get_scalars.

// -----

// Tests extracting all scalars from a static layout.
// CHECK-LABEL: func.func @static_layout_all
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
func.func @static_layout_all(%l: !cute.layout<"(4,8):(1,4)">) -> (i32, i32, i32, i32) {
  // CHECK: %[[R:.+]]:4 = cute.get_scalars (%[[L]]) : !cute.layout<"(4,8):(1,4)">
  %a, %b, %c, %d = cute.get_scalars (%l) : !cute.layout<"(4,8):(1,4)">
  // CHECK: return %[[R]]#0, %[[R]]#1, %[[R]]#2, %[[R]]#3 : i32, i32, i32, i32
  return %a, %b, %c, %d : i32, i32, i32, i32
}

// -----

// Tests extracting only dynamic scalars from a mixed-static/dynamic layout.
// CHECK-LABEL: func.func @dynamic_layout_only_dynamic
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(?,8):(1,?)">)
func.func @dynamic_layout_only_dynamic(%l: !cute.layout<"(?,8):(1,?)">) -> (i32, i32) {
  // CHECK: %[[R:.+]]:2 = cute.get_scalars<{only_dynamic}> (%[[L]]) : !cute.layout<"(?,8):(1,?)">
  %x, %y = cute.get_scalars<{only_dynamic}> (%l) : !cute.layout<"(?,8):(1,?)">
  // CHECK: return %[[R]]#0, %[[R]]#1 : i32, i32
  return %x, %y : i32, i32
}

// -----

// Tests extracting all scalars from a dynamic layout — includes both static
// and dynamic values.
// CHECK-LABEL: func.func @dynamic_layout_all
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(?,8):(1,?)">)
func.func @dynamic_layout_all(%l: !cute.layout<"(?,8):(1,?)">) -> (i32, i32, i32, i32) {
  // CHECK: %[[R:.+]]:4 = cute.get_scalars (%[[L]]) : !cute.layout<"(?,8):(1,?)">
  %a, %b, %c, %d = cute.get_scalars (%l) : !cute.layout<"(?,8):(1,?)">
  // CHECK: return %[[R]]#0, %[[R]]#1, %[[R]]#2, %[[R]]#3 : i32, i32, i32, i32
  return %a, %b, %c, %d : i32, i32, i32, i32
}

// -----

// Tests extracting scalars from a shape.
// CHECK-LABEL: func.func @shape_scalars
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,8)">)
func.func @shape_scalars(%s: !cute.shape<"(4,8)">) -> (i32, i32) {
  // CHECK: %[[R:.+]]:2 = cute.get_scalars (%[[S]]) : !cute.shape<"(4,8)">
  %a, %b = cute.get_scalars (%s) : !cute.shape<"(4,8)">
  // CHECK: return %[[R]]#0, %[[R]]#1 : i32, i32
  return %a, %b : i32, i32
}

// -----

// Tests extracting scalars from a swizzle — always 3 i32 values.
// CHECK-LABEL: func.func @swizzle_scalars
// CHECK-SAME:  (%[[SW:.+]]: !cute.swizzle<"S<3,5,4>">)
func.func @swizzle_scalars(%sw: !cute.swizzle<"S<3,5,4>">) -> (i32, i32, i32) {
  // CHECK: %[[R:.+]]:3 = cute.get_scalars (%[[SW]]) : !cute.swizzle<"S<3,5,4>">
  %a, %b, %c = cute.get_scalars (%sw) : !cute.swizzle<"S<3,5,4>">
  // CHECK: return %[[R]]#0, %[[R]]#1, %[[R]]#2 : i32, i32, i32
  return %a, %b, %c : i32, i32, i32
}

// -----

// Swizzle with `only_dynamic` — all three components (num_bits, num_base,
// num_shift) are compile-time in the type signature, so the op has
// zero results.
// CHECK-LABEL: func.func @swizzle_only_dynamic
// CHECK-SAME:  (%[[SW:.+]]: !cute.swizzle<"S<3,5,4>">)
func.func @swizzle_only_dynamic(%sw: !cute.swizzle<"S<3,5,4>">) {
  // CHECK: cute.get_scalars<{only_dynamic}> (%[[SW]]) : !cute.swizzle<"S<3,5,4>">
  cute.get_scalars<{only_dynamic}> (%sw) : !cute.swizzle<"S<3,5,4>">
  return
}

// -----

// int_tuple round-trip — flat dyn with only_dynamic.
// CHECK-LABEL: func.func @int_tuple_only_dynamic
// CHECK-SAME:  (%[[T:.+]]: !cute.int_tuple<"(?,?)">)
func.func @int_tuple_only_dynamic(%t: !cute.int_tuple<"(?,?)">) -> (i32, i32) {
  // CHECK: %[[R:.+]]:2 = cute.get_scalars<{only_dynamic}> (%[[T]]) : !cute.int_tuple<"(?,?)">
  %a, %b = cute.get_scalars<{only_dynamic}> (%t) : !cute.int_tuple<"(?,?)">
  // CHECK: return %[[R]]#0, %[[R]]#1 : i32, i32
  return %a, %b : i32, i32
}

// -----

// int_tuple round-trip — nested with mix of dyn + static; only_dynamic
// returns just the dyn leaves.
// CHECK-LABEL: func.func @int_tuple_nested_only_dynamic
// CHECK-SAME:  (%[[T:.+]]: !cute.int_tuple<"(?,(?,3))">)
func.func @int_tuple_nested_only_dynamic(%t: !cute.int_tuple<"(?,(?,3))">) -> (i32, i32) {
  // CHECK: %[[R:.+]]:2 = cute.get_scalars<{only_dynamic}> (%[[T]]) : !cute.int_tuple<"(?,(?,3))">
  %a, %b = cute.get_scalars<{only_dynamic}> (%t) : !cute.int_tuple<"(?,(?,3))">
  // CHECK: return %[[R]]#0, %[[R]]#1 : i32, i32
  return %a, %b : i32, i32
}

// -----

// stride round-trip — plain integer dyn, only_dynamic returns 2 leaves.
// CHECK-LABEL: func.func @stride_only_dynamic
// CHECK-SAME:  (%[[ST:.+]]: !cute.stride<"(?,4,?)">)
func.func @stride_only_dynamic(%st: !cute.stride<"(?,4,?)">) -> (i32, i32) {
  // CHECK: %[[R:.+]]:2 = cute.get_scalars<{only_dynamic}> (%[[ST]]) : !cute.stride<"(?,4,?)">
  %a, %b = cute.get_scalars<{only_dynamic}> (%st) : !cute.stride<"(?,4,?)">
  // CHECK: return %[[R]]#0, %[[R]]#1 : i32, i32
  return %a, %b : i32, i32
}

// -----

// stride round-trip — scaled-basis static; each `1@N` leaf yields 2 i32
// values (scale + basis index), so two leaves → 4 results.
// CHECK-LABEL: func.func @stride_basis_static_all
// CHECK-SAME:  (%[[ST:.+]]: !cute.stride<"(1@0,1@1)">)
func.func @stride_basis_static_all(%st: !cute.stride<"(1@0,1@1)">) -> (i32, i32, i32, i32) {
  // CHECK: %[[R:.+]]:4 = cute.get_scalars (%[[ST]]) : !cute.stride<"(1@0,1@1)">
  %a, %b, %c, %d = cute.get_scalars (%st) : !cute.stride<"(1@0,1@1)">
  // CHECK: return %[[R]]#0, %[[R]]#1, %[[R]]#2, %[[R]]#3 : i32, i32, i32, i32
  return %a, %b, %c, %d : i32, i32, i32, i32
}

// -----

// stride round-trip — scaled-basis with dyn scales, only_dynamic returns
// the 2 dyn scales (one per `?@N` leaf).
// CHECK-LABEL: func.func @stride_basis_only_dynamic
// CHECK-SAME:  (%[[ST:.+]]: !cute.stride<"(?@0,?@1)">)
func.func @stride_basis_only_dynamic(%st: !cute.stride<"(?@0,?@1)">) -> (i32, i32) {
  // CHECK: %[[R:.+]]:2 = cute.get_scalars<{only_dynamic}> (%[[ST]]) : !cute.stride<"(?@0,?@1)">
  %a, %b = cute.get_scalars<{only_dynamic}> (%st) : !cute.stride<"(?@0,?@1)">
  // CHECK: return %[[R]]#0, %[[R]]#1 : i32, i32
  return %a, %b : i32, i32
}

// -----

// coord round-trip — fully dyn with only_dynamic.
// CHECK-LABEL: func.func @coord_only_dynamic
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(?,?,?)">)
func.func @coord_only_dynamic(%c: !cute.coord<"(?,?,?)">) -> (i32, i32, i32) {
  // CHECK: %[[R:.+]]:3 = cute.get_scalars<{only_dynamic}> (%[[C]]) : !cute.coord<"(?,?,?)">
  %a, %b, %d = cute.get_scalars<{only_dynamic}> (%c) : !cute.coord<"(?,?,?)">
  // CHECK: return %[[R]]#0, %[[R]]#1, %[[R]]#2 : i32, i32, i32
  return %a, %b, %d : i32, i32, i32
}

// -----

// composed_layout round-trip — only_dynamic on a composed with dyn inner
// shape + dyn offset, returns 3 leaves (1 from inner shape, 1 offset,
// 1 from inner stride).
// CHECK-LABEL: func.func @composed_only_dynamic
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"(?,4):(1,?) o ? o (2,3):(1,2)">)
func.func @composed_only_dynamic(%cl: !cute.composed_layout<"(?,4):(1,?) o ? o (2,3):(1,2)">) -> (i32, i32, i32) {
  // CHECK: %[[R:.+]]:3 = cute.get_scalars<{only_dynamic}> (%[[CL]]) : !cute.composed_layout<"(?,4):(1,?) o ? o (2,3):(1,2)">
  %a, %b, %c = cute.get_scalars<{only_dynamic}> (%cl)
       : !cute.composed_layout<"(?,4):(1,?) o ? o (2,3):(1,2)">
  // CHECK: return %[[R]]#0, %[[R]]#1, %[[R]]#2 : i32, i32, i32
  return %a, %b, %c : i32, i32, i32
}

// -----

// tile round-trip — only_dynamic across a multi-layout tile; returns the
// dyn leaves of all layout slots in order.
// CHECK-LABEL: func.func @tile_only_dynamic
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">)
func.func @tile_only_dynamic(%t: !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">) -> (i32, i32) {
  // CHECK: %[[R:.+]]:2 = cute.get_scalars<{only_dynamic}> (%[[T]]) : !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">
  %a, %b = cute.get_scalars<{only_dynamic}> (%t)
       : !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">
  // CHECK: return %[[R]]#0, %[[R]]#1 : i32, i32
  return %a, %b : i32, i32
}

// -----

// tile round-trip — only_dynamic with an underscore slot. Underscore
// contributes no leaves; only the dyn layout slot's leaves appear.
// CHECK-LABEL: func.func @tile_underscore_only_dynamic
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(?,4):(1,?);_]">)
func.func @tile_underscore_only_dynamic(%t: !cute.tile<"[(?,4):(1,?);_]">) -> (i32, i32) {
  // CHECK: %[[R:.+]]:2 = cute.get_scalars<{only_dynamic}> (%[[T]]) : !cute.tile<"[(?,4):(1,?);_]">
  %a, %b = cute.get_scalars<{only_dynamic}> (%t)
       : !cute.tile<"[(?,4):(1,?);_]">
  // CHECK: return %[[R]]#0, %[[R]]#1 : i32, i32
  return %a, %b : i32, i32
}

// -----

// Dynamic + static sibling — only the dyn leaf surfaces as an
// `i32` scalar.
// CHECK-LABEL: func.func @shape_dyn_static_leaf
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(?,5)">)
func.func @shape_dyn_static_leaf(%s: !cute.shape<"(?,5)">) -> i32 {
  // CHECK: %[[R:.+]] = cute.get_scalars<{only_dynamic}> (%[[S]]) : !cute.shape<"(?,5)">
  %r = cute.get_scalars<{only_dynamic}> (%s) : !cute.shape<"(?,5)">
  // CHECK: return %[[R]] : i32
  return %r : i32
}

// -----

// i64-width dynamic leaves
// CHECK-LABEL: func.func @shape_i64_dyn_only_dynamic
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(?{i64},?{i64})">)
func.func @shape_i64_dyn_only_dynamic(%s: !cute.shape<"(?{i64},?{i64})">)
    -> (i64, i64) {
  // CHECK: %[[R:.+]]:2 = cute.get_scalars<{only_dynamic}> (%[[S]]) : !cute.shape<"(?{i64},?{i64})">
  %a, %b = cute.get_scalars<{only_dynamic}> (%s) : !cute.shape<"(?{i64},?{i64})">
  // CHECK: return %[[R]]#0, %[[R]]#1 : i64, i64
  return %a, %b : i64, i64
}

// -----

// Mixed widths within one type — `?{i64}` dyn + small static. All-mode
// returns the dyn leaf at i64 and the static leaf at i32 (small enough
// to fit the value).
// CHECK-LABEL: func.func @shape_mixed_widths_all
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(?{i64},5)">)
func.func @shape_mixed_widths_all(%s: !cute.shape<"(?{i64},5)">)
    -> (i64, i32) {
  // CHECK: %[[R:.+]]:2 = cute.get_scalars (%[[S]]) : !cute.shape<"(?{i64},5)">
  %a, %b = cute.get_scalars (%s) : !cute.shape<"(?{i64},5)">
  // CHECK: return %[[R]]#0, %[[R]]#1 : i64, i32
  return %a, %b : i64, i32
}

// -----

// Layout with mixed widths — the depth-first leaf-traversal order
// (shape leaves before stride leaves) AND the per-leaf width selection.
// CHECK-LABEL: func.func @layout_mixed_widths_all
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(?{i64},8):(1,?{i64})">)
func.func @layout_mixed_widths_all(%l: !cute.layout<"(?{i64},8):(1,?{i64})">)
    -> (i64, i32, i32, i64) {
  // CHECK: %[[R:.+]]:4 = cute.get_scalars (%[[L]]) : !cute.layout<"(?{i64},8):(1,?{i64})">
  %a, %b, %c, %d = cute.get_scalars (%l) : !cute.layout<"(?{i64},8):(1,?{i64})">
  // CHECK: return %[[R]]#0, %[[R]]#1, %[[R]]#2, %[[R]]#3 : i64, i32, i32, i64
  return %a, %b, %c, %d : i64, i32, i32, i64
}

// -----

// Stride with mixed-width dyn + dyn
// CHECK-LABEL: func.func @stride_mixed_dyn_widths
// CHECK-SAME:  (%[[ST:.+]]: !cute.stride<"(?,?{i64})">)
func.func @stride_mixed_dyn_widths(%st: !cute.stride<"(?,?{i64})">)
    -> (i32, i64) {
  // CHECK: %[[R:.+]]:2 = cute.get_scalars<{only_dynamic}> (%[[ST]]) : !cute.stride<"(?,?{i64})">
  %a, %b = cute.get_scalars<{only_dynamic}> (%st) : !cute.stride<"(?,?{i64})">
  // CHECK: return %[[R]]#0, %[[R]]#1 : i32, i64
  return %a, %b : i32, i64
}
