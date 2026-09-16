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

// RUN: cute-opt -cute-to-base --split-input-file %s | FileCheck %s

// Tests `cute-to-base` lowering for `cute.get_scalars`.

// -----

// Dynamic int_tuple — `only_dynamic` emits one extractvalue per leaf.
// CHECK-LABEL: func.func @int_tuple_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-COUNT-2: llvm.extractvalue
// CHECK:         return
func.func @int_tuple_only_dynamic(%t: !cute.int_tuple<"(?,?)">) -> (i32, i32) {
  %a, %b = cute.get_scalars<{only_dynamic}> (%t) : !cute.int_tuple<"(?,?)">
  return %a, %b : i32, i32
}

// -----

// All-static int_tuple — static leaves materialize as i32 constants.
// CHECK-LABEL: func.func @int_tuple_all_static
// CHECK-NOT:     cute.get_scalars
// CHECK-NOT:     llvm.extractvalue
// CHECK-NOT:     builtin.unrealized_conversion_cast
// CHECK-NOT:     arith.extsi
// CHECK-DAG:     arith.constant 2 : i32
// CHECK-DAG:     arith.constant 3 : i32
// CHECK:         return
func.func @int_tuple_all_static(%t: !cute.int_tuple<"(2,3)">) -> (i32, i32) {
  %a, %b = cute.get_scalars (%t) : !cute.int_tuple<"(2,3)">
  return %a, %b : i32, i32
}

// -----

// Single-dyn-leaf shape — LLVM representation is bare i32, no extractvalue.
// CHECK-LABEL: func.func @shape_mixed_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-NOT:     llvm.extractvalue
// CHECK:         return
func.func @shape_mixed_only_dynamic(%s: !cute.shape<"(?,4)">) -> i32 {
  %a = cute.get_scalars<{only_dynamic}> (%s) : !cute.shape<"(?,4)">
  return %a : i32
}

// -----

// Layout — shape leaves followed by stride leaves.
// CHECK-LABEL: func.func @layout_full
// CHECK-NOT:     cute.get_scalars
// CHECK-NOT:     builtin.unrealized_conversion_cast
// CHECK-NOT:     arith.extsi
// CHECK-COUNT-2: llvm.extractvalue
// CHECK-NOT:     llvm.extractvalue
// CHECK:         return
func.func @layout_full(%l: !cute.layout<"(?,4):(1,?)">)
    -> (i32, i32, i32, i32) {
  %a, %b, %c, %d = cute.get_scalars (%l) : !cute.layout<"(?,4):(1,?)">
  return %a, %b, %c, %d : i32, i32, i32, i32
}

// -----

// Fully dynamic coord — one extract per leaf.
// CHECK-LABEL: func.func @coord_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-COUNT-3: llvm.extractvalue
// CHECK:         return
func.func @coord_only_dynamic(%c: !cute.coord<"(?,?,?)">) -> (i32, i32, i32) {
  %a, %b, %c1 = cute.get_scalars<{only_dynamic}> (%c) : !cute.coord<"(?,?,?)">
  return %a, %b, %c1 : i32, i32, i32
}

// -----

// Swizzle — yields `(num_bits, num_base, num_shift)` as three constants.
// CHECK-LABEL: func.func @swizzle_all_scalars
// CHECK-NOT:     cute.get_scalars
// CHECK-DAG:     %[[NB:.+]] = arith.constant 3 : i32
// CHECK-DAG:     %[[NBASE:.+]] = arith.constant 5 : i32
// CHECK-DAG:     %[[NSHIFT:.+]] = arith.constant 4 : i32
// CHECK:         return
func.func @swizzle_all_scalars(%sw: !cute.swizzle<"S<3,5,4>">)
    -> (i32, i32, i32) {
  %nb, %nbase, %ns = cute.get_scalars (%sw) : !cute.swizzle<"S<3,5,4>">
  return %nb, %nbase, %ns : i32, i32, i32
}

// -----

// Swizzle has no dynamic leaves — `only_dynamic` lowers to nothing.
// CHECK-LABEL: func.func @swizzle_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-NOT:     arith.constant
// CHECK:         return
func.func @swizzle_only_dynamic(%sw: !cute.swizzle<"S<3,5,4>">) {
  cute.get_scalars<{only_dynamic}> (%sw) : !cute.swizzle<"S<3,5,4>">
  return
}

// -----

// Mixed dyn + static stride, only_dynamic — static leaves filtered out.
// CHECK-LABEL: func.func @stride_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-COUNT-2: llvm.extractvalue
// CHECK-NOT:     arith.constant
// CHECK:         return
func.func @stride_only_dynamic(%st: !cute.stride<"(?,4,?)">) -> (i32, i32) {
  %a, %b = cute.get_scalars<{only_dynamic}> (%st) : !cute.stride<"(?,4,?)">
  return %a, %b : i32, i32
}

// -----

// Mixed dyn + static stride, all leaves.
// CHECK-LABEL: func.func @stride_all
// CHECK-NOT:     cute.get_scalars
// CHECK-NOT:     builtin.unrealized_conversion_cast
// CHECK-NOT:     arith.extsi
// CHECK-DAG:     llvm.extractvalue
// CHECK-DAG:     arith.constant 4 : i32
// CHECK:         return
func.func @stride_all(%st: !cute.stride<"(?,4,?)">) -> (i32, i32, i32) {
  %a, %b, %c = cute.get_scalars (%st) : !cute.stride<"(?,4,?)">
  return %a, %b, %c : i32, i32, i32
}

// -----

// Static scaled-basis stride — each leaf contributes (scale, basis_index)
// as a pair of i32 constants.
// CHECK-LABEL: func.func @stride_basis_static_all
// CHECK-NOT:     cute.get_scalars
// CHECK-NOT:     llvm.extractvalue
// CHECK-NOT:     builtin.unrealized_conversion_cast
// CHECK-NOT:     arith.extsi
// CHECK-COUNT-4: arith.constant {{.+}} : i32
// CHECK:         return
func.func @stride_basis_static_all(%st: !cute.stride<"(1@0,1@1)">)
    -> (i32, i32, i32, i32) {
  %a, %b, %c, %d = cute.get_scalars (%st) : !cute.stride<"(1@0,1@1)">
  return %a, %b, %c, %d : i32, i32, i32, i32
}

// -----

// Dynamic scaled-basis stride, only_dynamic — basis indices are static
// and filtered out.
// CHECK-LABEL: func.func @stride_basis_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-COUNT-2: llvm.extractvalue
// CHECK-NOT:     arith.constant
// CHECK:         return
func.func @stride_basis_only_dynamic(%st: !cute.stride<"(?@0,?@1)">)
    -> (i32, i32) {
  %a, %b = cute.get_scalars<{only_dynamic}> (%st) : !cute.stride<"(?@0,?@1)">
  return %a, %b : i32, i32
}

// -----

// Composed layout, only_dynamic — offset + outer dyn leaves; inner is static.
// CHECK-LABEL: func.func @composed_layout_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-COUNT-3: llvm.extractvalue
// CHECK:         return
func.func @composed_layout_only_dynamic(
    %cl: !cute.composed_layout<"(?,4):(1,?) o ? o (2,3):(1,2)">)
    -> (i32, i32, i32) {
  %a, %b, %c = cute.get_scalars<{only_dynamic}> (%cl)
       : !cute.composed_layout<"(?,4):(1,?) o ? o (2,3):(1,2)">
  return %a, %b, %c : i32, i32, i32
}

// -----

// Tile of two layouts, only_dynamic — first slot has dyn leaves, second is static.
// CHECK-LABEL: func.func @tile_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-COUNT-2: llvm.extractvalue
// CHECK:         return
func.func @tile_only_dynamic(%t: !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">)
    -> (i32, i32) {
  %a, %b = cute.get_scalars<{only_dynamic}> (%t)
       : !cute.tile<"[(?,4):(1,?);(2,3):(1,2)]">
  return %a, %b : i32, i32
}

// -----

// Tile with an underscore slot, only_dynamic — underscore contributes nothing.
// CHECK-LABEL: func.func @tile_underscore_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-COUNT-2: llvm.extractvalue
// CHECK:         return
func.func @tile_underscore_only_dynamic(%t: !cute.tile<"[(?,4):(1,?);_]">)
    -> (i32, i32) {
  %a, %b = cute.get_scalars<{only_dynamic}> (%t)
       : !cute.tile<"[(?,4):(1,?);_]">
  return %a, %b : i32, i32
}

// -----

// Layout with only_dynamic — dyn shape + stride leaves only.
// CHECK-LABEL: func.func @layout_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-COUNT-2: llvm.extractvalue
// CHECK-NOT:     arith.constant
// CHECK:         return
func.func @layout_only_dynamic(%l: !cute.layout<"(?,4):(1,?)">) -> (i32, i32) {
  %a, %b = cute.get_scalars<{only_dynamic}> (%l) : !cute.layout<"(?,4):(1,?)">
  return %a, %b : i32, i32
}

// -----

// Nested int_tuple, only_dynamic — dyn leaves collected regardless of nesting.
// CHECK-LABEL: func.func @int_tuple_nested_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-COUNT-2: llvm.extractvalue
// CHECK:         return
func.func @int_tuple_nested_only_dynamic(%t: !cute.int_tuple<"(?,(?,3))">)
    -> (i32, i32) {
  %a, %b = cute.get_scalars<{only_dynamic}> (%t) : !cute.int_tuple<"(?,(?,3))">
  return %a, %b : i32, i32
}

// -----

// i64 dyn leaves materialize at i64 width with no width-normalization.
// CHECK-LABEL: func.func @shape_i64_dyn_only_dynamic
// CHECK-NOT:     cute.get_scalars
// CHECK-NOT:     builtin.unrealized_conversion_cast
// CHECK-NOT:     arith.extsi
// CHECK-NOT:     arith.trunci
// CHECK-COUNT-2: llvm.extractvalue %{{.+}} : !llvm.struct<(i64, i64)>
// CHECK:         return %{{.+}}, %{{.+}} : i64, i64
func.func @shape_i64_dyn_only_dynamic(%s: !cute.shape<"(?{i64},?{i64})">)
    -> (i64, i64) {
  %a, %b = cute.get_scalars<{only_dynamic}> (%s) : !cute.shape<"(?{i64},?{i64})">
  return %a, %b : i64, i64
}

// -----

// Mixed widths on a layout — per-leaf width selection, depth-first ordering.
// CHECK-LABEL: func.func @layout_mixed_widths_all
// CHECK-NOT:     cute.get_scalars
// CHECK-NOT:     builtin.unrealized_conversion_cast
// CHECK-NOT:     arith.extsi
// CHECK-NOT:     arith.trunci
// CHECK-DAG:     %[[D0:.+]] = llvm.extractvalue %{{.+}}[0] : !llvm.struct<(i64, i64)>
// CHECK-DAG:     %[[D1:.+]] = llvm.extractvalue %{{.+}}[1] : !llvm.struct<(i64, i64)>
// CHECK-DAG:     %[[S8:.+]] = arith.constant 8 : i32
// CHECK-DAG:     %[[S1:.+]] = arith.constant 1 : i32
// CHECK:         return %[[D0]], %[[S8]], %[[S1]], %[[D1]] : i64, i32, i32, i64
func.func @layout_mixed_widths_all(%l: !cute.layout<"(?{i64},8):(1,?{i64})">)
    -> (i64, i32, i32, i64) {
  %a, %b, %c, %d = cute.get_scalars (%l) : !cute.layout<"(?{i64},8):(1,?{i64})">
  return %a, %b, %c, %d : i64, i32, i32, i64
}
