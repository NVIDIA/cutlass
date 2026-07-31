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

// -----

// Rank-1 strided layout — compact stride 1 is produced.

// CHECK-LABEL: func.func @rank1_strided
// CHECK-SAME: (%[[SRC:.+]]: !cute.layout<"8:2">)
func.func @rank1_strided(%src: !cute.layout<"8:2">) -> !cute.layout<"8:1"> {
  // CHECK: %[[R:.+]] = cute.make_layout_like(%[[SRC]]) : !cute.layout<"8:2"> -> !cute.layout<"8:1">
  %r = cute.make_layout_like(%src) : !cute.layout<"8:2"> -> !cute.layout<"8:1">
  return %r : !cute.layout<"8:1">
}

// -----

// Col-major layout — already compact, result is unchanged.

// CHECK-LABEL: func.func @col_major_unchanged
// CHECK-SAME: (%[[SRC:.+]]: !cute.layout<"(4,2):(1,4)">)
func.func @col_major_unchanged(%src: !cute.layout<"(4,2):(1,4)">) -> !cute.layout<"(4,2):(1,4)"> {
  // CHECK: cute.make_layout_like(%[[SRC]]) : !cute.layout<"(4,2):(1,4)"> -> !cute.layout<"(4,2):(1,4)">
  %r = cute.make_layout_like(%src) : !cute.layout<"(4,2):(1,4)"> -> !cute.layout<"(4,2):(1,4)">
  return %r : !cute.layout<"(4,2):(1,4)">
}

// -----

// Row-major layout — relative stride ordering is preserved; result is compact row-major.
// Source strides: mode 0 stride 4 (more major), mode 1 stride 1 (less major).
// compact_order preserves the order: mode 1 gets stride 1, mode 0 gets stride 2.

// CHECK-LABEL: func.func @row_major_preserved
// CHECK-SAME: (%[[SRC:.+]]: !cute.layout<"(4,2):(4,1)">)
func.func @row_major_preserved(%src: !cute.layout<"(4,2):(4,1)">) -> !cute.layout<"(4,2):(2,1)"> {
  // CHECK: cute.make_layout_like(%[[SRC]]) : !cute.layout<"(4,2):(4,1)"> -> !cute.layout<"(4,2):(2,1)">
  %r = cute.make_layout_like(%src) : !cute.layout<"(4,2):(4,1)"> -> !cute.layout<"(4,2):(2,1)">
  return %r : !cute.layout<"(4,2):(2,1)">
}

// -----

// Nested col-major layout — strides are compacted within the nested structure.
// Source strides: (1,(2,8)) — mode 0 (stride 1) least major, 1.0 (stride 2), 1.1 (stride 8).
// compact_order keeps the same ordering → strides (1,(2,6)).

// CHECK-LABEL: func.func @nested_col_major
// CHECK-SAME: (%[[SRC:.+]]: !cute.layout<"(2,(3,4)):(1,(2,8))">)
func.func @nested_col_major(%src: !cute.layout<"(2,(3,4)):(1,(2,8))">) -> !cute.layout<"(2,(3,4)):(1,(2,6))"> {
  // CHECK: cute.make_layout_like(%[[SRC]])
  // CHECK-SAME: !cute.layout<"(2,(3,4)):(1,(2,8))"> -> !cute.layout<"(2,(3,4)):(1,(2,6))">
  %r = cute.make_layout_like(%src)
         : !cute.layout<"(2,(3,4)):(1,(2,8))"> -> !cute.layout<"(2,(3,4)):(1,(2,6))">
  return %r : !cute.layout<"(2,(3,4)):(1,(2,6))">
}

// -----

// Nested layout with non-trivial mode ordering.
// Source strides: (8,(1,3)) — sub-mode 1.0 (stride 1) least major, 1.1 (stride 3), 0 (stride 8).
// compact_order: 1.0 → 1, 1.1 → 3, 0 → 12.

// CHECK-LABEL: func.func @nested_reordered
// CHECK-SAME: (%[[SRC:.+]]: !cute.layout<"(2,(3,4)):(8,(1,3))">)
func.func @nested_reordered(%src: !cute.layout<"(2,(3,4)):(8,(1,3))">) -> !cute.layout<"(2,(3,4)):(12,(1,3))"> {
  // CHECK: cute.make_layout_like(%[[SRC]])
  // CHECK-SAME: !cute.layout<"(2,(3,4)):(8,(1,3))"> -> !cute.layout<"(2,(3,4)):(12,(1,3))">
  %r = cute.make_layout_like(%src)
         : !cute.layout<"(2,(3,4)):(8,(1,3))"> -> !cute.layout<"(2,(3,4)):(12,(1,3))">
  return %r : !cute.layout<"(2,(3,4)):(12,(1,3))">
}

// -----

// Composed layout source — result is derived from the outer B layout component.
// B = (8,2):(2,16) → mode 0 (stride 2) less major, mode 1 (stride 16) more major
// → compact result (8,2):(1,8).

// CHECK-LABEL: func.func @composed_layout_src
// CHECK-SAME: (%[[SRC:.+]]: !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)">)
func.func @composed_layout_src(%src: !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)">) -> !cute.layout<"(8,2):(1,8)"> {
  // CHECK: cute.make_layout_like(%[[SRC]])
  // CHECK-SAME: !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)"> -> !cute.layout<"(8,2):(1,8)">
  %r = cute.make_layout_like(%src)
         : !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)"> -> !cute.layout<"(8,2):(1,8)">
  return %r : !cute.layout<"(8,2):(1,8)">
}

// -----

// Dynamic strides — result mirrors the source layout's mode order.

// CHECK-LABEL: func.func @dynamic_strides
// CHECK-SAME: (%[[SRC:.+]]: !cute.layout<"(8,?,4,?):(?,?,?,1)">)
func.func @dynamic_strides(%src: !cute.layout<"(8,?,4,?):(?,?,?,1)">) -> !cute.layout<"(8,?,4,?):(?,?,?,1)"> {
  // CHECK: cute.make_layout_like(%[[SRC]])
  // CHECK-SAME: !cute.layout<"(8,?,4,?):(?,?,?,1)"> -> !cute.layout<"(8,?,4,?):(?,?,?,1)">
  %r = cute.make_layout_like(%src)
         : !cute.layout<"(8,?,4,?):(?,?,?,1)"> -> !cute.layout<"(8,?,4,?):(?,?,?,1)">
  return %r : !cute.layout<"(8,?,4,?):(?,?,?,1)">
}

// -----

// All-dynamic layout: shape and stride leaves all `?`. compact_order can
// still produce a compact result because the relative magnitude ordering
// is preserved at the type level (mode 0 stride is the "first" runtime
// value, so it becomes stride 1; mode 1 stride follows).

// CHECK-LABEL: func.func @all_dynamic
// CHECK-SAME: (%[[SRC:.+]]: !cute.layout<"(?,?):(?,?)">)
func.func @all_dynamic(%src: !cute.layout<"(?,?):(?,?)">) -> !cute.layout<"(?,?):(1,?)"> {
  // CHECK: cute.make_layout_like(%[[SRC]]) : !cute.layout<"(?,?):(?,?)"> -> !cute.layout<"(?,?):(1,?)">
  %r = cute.make_layout_like(%src) : !cute.layout<"(?,?):(?,?)"> -> !cute.layout<"(?,?):(1,?)">
  return %r : !cute.layout<"(?,?):(1,?)">
}

// -----

// Composed-layout source with dynamic outer B — exercises the
// ComposedLayoutType branch when B itself carries dynamic leaves.

// CHECK-LABEL: func.func @composed_dynamic_b
// CHECK-SAME: (%[[SRC:.+]]: !cute.composed_layout<"S<3,4,3> o 6 o (?,2):(2,?)">)
func.func @composed_dynamic_b(%src: !cute.composed_layout<"S<3,4,3> o 6 o (?,2):(2,?)">) -> !cute.layout<"(?,2):(1,?)"> {
  // CHECK: cute.make_layout_like(%[[SRC]])
  // CHECK-SAME: !cute.composed_layout<"S<3,4,3> o 6 o (?,2):(2,?)"> -> !cute.layout<"(?,2):(1,?)">
  %r = cute.make_layout_like(%src)
         : !cute.composed_layout<"S<3,4,3> o 6 o (?,2):(2,?)"> -> !cute.layout<"(?,2):(1,?)">
  return %r : !cute.layout<"(?,2):(1,?)">
}
