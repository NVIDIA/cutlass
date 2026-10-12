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
// Tests round-trip for cute.select.

// -----

// Tests select<[0]> keeping the first mode of a layout.
// cute.select wraps the single-mode result in a tuple.
// CHECK-LABEL: func.func @mode0_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
func.func @mode0_layout(%l: !cute.layout<"(4,8):(1,4)">) {
  // CHECK: %[[R:.+]] = cute.select<[0]> (%[[L]]) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4):(1)">
  %r = cute.select<[0]> (%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.layout<"(4):(1)">
  return
}

// -----

// Tests select<[0, 2]> keeping two non-contiguous modes of an int_tuple.
// CHECK-LABEL: func.func @modes02_int_tuple
// CHECK-SAME:  (%[[I:.+]]: !cute.int_tuple<"(1,2,3)">)
func.func @modes02_int_tuple(%i: !cute.int_tuple<"(1,2,3)">) {
  // CHECK: %[[R:.+]] = cute.select<[0, 2]> (%[[I]]) : !cute.int_tuple<"(1,2,3)"> -> !cute.int_tuple<"(1,3)">
  %r = cute.select<[0, 2]> (%i) : !cute.int_tuple<"(1,2,3)"> -> !cute.int_tuple<"(1,3)">
  return
}

// -----

// Tests select<[1]> keeping the second mode of a shape.
// CHECK-LABEL: func.func @mode1_shape
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,8,2)">)
func.func @mode1_shape(%s: !cute.shape<"(4,8,2)">) {
  // CHECK: %[[R:.+]] = cute.select<[1]> (%[[S]]) : !cute.shape<"(4,8,2)"> -> !cute.shape<"(8)">
  %r = cute.select<[1]> (%s) : !cute.shape<"(4,8,2)"> -> !cute.shape<"(8)">
  return
}

// -----

// Tests select<[0, 1, 2]> with all three modes — identity select on a rank-3 shape.
// CHECK-LABEL: func.func @all_three_modes_shape
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,8,2)">)
func.func @all_three_modes_shape(%s: !cute.shape<"(4,8,2)">) {
  // CHECK: %[[R:.+]] = cute.select<[0, 1, 2]> (%[[S]]) : !cute.shape<"(4,8,2)"> -> !cute.shape<"(4,8,2)">
  %r = cute.select<[0, 1, 2]> (%s) : !cute.shape<"(4,8,2)"> -> !cute.shape<"(4,8,2)">
  return
}

// -----

// Tests select<[2, 0]> permuting two modes of a layout.
// CHECK-LABEL: func.func @permute_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(4,2,8):(1,4,8)">)
func.func @permute_layout(%l: !cute.layout<"(4,2,8):(1,4,8)">) {
  // CHECK: %[[R:.+]] = cute.select<[2, 0]> (%[[L]]) : !cute.layout<"(4,2,8):(1,4,8)"> -> !cute.layout<"(8,4):(8,1)">
  %r = cute.select<[2, 0]> (%l) : !cute.layout<"(4,2,8):(1,4,8)"> -> !cute.layout<"(8,4):(8,1)">
  return
}

// -----

// Tests select<[1, 1]> repeating a mode — duplicates mode 1.
// CHECK-LABEL: func.func @repeated_mode_int_tuple
// CHECK-SAME:  (%[[I:.+]]: !cute.int_tuple<"(1,2,3)">)
func.func @repeated_mode_int_tuple(%i: !cute.int_tuple<"(1,2,3)">) {
  // CHECK: %[[R:.+]] = cute.select<[1, 1]> (%[[I]]) : !cute.int_tuple<"(1,2,3)"> -> !cute.int_tuple<"(2,2)">
  %r = cute.select<[1, 1]> (%i) : !cute.int_tuple<"(1,2,3)"> -> !cute.int_tuple<"(2,2)">
  return
}

// -----

// Tests select<[3, 1, 0]> — three modes from a rank-4 coord with permutation.
// CHECK-LABEL: func.func @three_modes_from_rank4_coord
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(1,2,3,4)">)
func.func @three_modes_from_rank4_coord(%c: !cute.coord<"(1,2,3,4)">) {
  // CHECK: %[[R:.+]] = cute.select<[3, 1, 0]> (%[[C]]) : !cute.coord<"(1,2,3,4)"> -> !cute.coord<"(4,2,1)">
  %r = cute.select<[3, 1, 0]> (%c) : !cute.coord<"(1,2,3,4)"> -> !cute.coord<"(4,2,1)">
  return
}

// -----

// Tests select on a stride.
// CHECK-LABEL: func.func @permute_stride
// CHECK-SAME:  (%[[S:.+]]: !cute.stride<"(1,4,8)">)
func.func @permute_stride(%s: !cute.stride<"(1,4,8)">) {
  // CHECK: %[[R:.+]] = cute.select<[2, 0]> (%[[S]]) : !cute.stride<"(1,4,8)"> -> !cute.stride<"(8,1)">
  %r = cute.select<[2, 0]> (%s) : !cute.stride<"(1,4,8)"> -> !cute.stride<"(8,1)">
  return
}

// -----

// Tests select on a tile with two layout slots.
// CHECK-LABEL: func.func @tile_two_layout_slots
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
func.func @tile_two_layout_slots(%t: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">) {
  // CHECK: %[[R:.+]] = cute.select<[1, 0]> (%[[T]]) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]"> -> !cute.tile<"[(2,3):(1,2);(4,8):(1,4)]">
  %r = cute.select<[1, 0]> (%t)
         : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">
        -> !cute.tile<"[(2,3):(1,2);(4,8):(1,4)]">
  return
}

// -----

// Tests select on a tile where an underscore slot is picked.
// CHECK-LABEL: func.func @tile_underscore_picked
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">)
func.func @tile_underscore_picked(%t: !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">) {
  // CHECK: %[[R:.+]] = cute.select<[1, 2]> (%[[T]]) : !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]"> -> !cute.tile<"[_;(2,3):(1,2)]">
  %r = cute.select<[1, 2]> (%t)
         : !cute.tile<"[(4,8):(1,4);_;(2,3):(1,2)]">
        -> !cute.tile<"[_;(2,3):(1,2)]">
  return
}

// -----

// Tests select on a composed_layout — applies to outer B, inner +
// offset preserved.
// CHECK-LABEL: func.func @composed_layout_outer_b_slice
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3,8):(1,2,6)">)
func.func @composed_layout_outer_b_slice(
    %cl: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3,8):(1,2,6)">) {
  // CHECK: %[[R:.+]] = cute.select<[2, 0]> (%[[CL]]) : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3,8):(1,2,6)"> -> !cute.composed_layout<"(4,5):(1,4) o 2 o (8,2):(6,1)">
  %r = cute.select<[2, 0]> (%cl)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3,8):(1,2,6)">
        -> !cute.composed_layout<"(4,5):(1,4) o 2 o (8,2):(6,1)">
  return
}

// -----

// Tests empty mode <[]> — produces a rank-0 result of the same kind.
// Contrast with cute.get<[]>, which is identity.
// CHECK-LABEL: func.func @empty_mode_rank0
// CHECK-SAME:  (%[[S:.+]]: !cute.shape<"(4,8)">)
func.func @empty_mode_rank0(%s: !cute.shape<"(4,8)">) {
  // CHECK: %[[R:.+]] = cute.select<[]> (%[[S]]) : !cute.shape<"(4,8)"> -> !cute.shape<"()">
  %r = cute.select<[]> (%s) : !cute.shape<"(4,8)"> -> !cute.shape<"()">
  return
}

// -----

// Tests select on a layout with scaled-basis strides.
// CHECK-LABEL: func.func @permute_layout_scaled_basis
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(4,2,8):(1@0,1@1,1@2)">)
func.func @permute_layout_scaled_basis(%l: !cute.layout<"(4,2,8):(1@0,1@1,1@2)">) {
  // CHECK: %[[R:.+]] = cute.select<[2, 0]> (%[[L]]) : !cute.layout<"(4,2,8):(1@0,1@1,1@2)"> -> !cute.layout<"(8,4):(1@2,1@0)">
  %r = cute.select<[2, 0]> (%l)
         : !cute.layout<"(4,2,8):(1@0,1@1,1@2)">
        -> !cute.layout<"(8,4):(1@2,1@0)">
  return
}

// -----

// Tests select on a layout with dynamic shape/stride leaves.
// CHECK-LABEL: func.func @permute_layout_dynamic
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(?,4,?):(1,?,?)">)
func.func @permute_layout_dynamic(%l: !cute.layout<"(?,4,?):(1,?,?)">) {
  // CHECK: %[[R:.+]] = cute.select<[2, 0]> (%[[L]]) : !cute.layout<"(?,4,?):(1,?,?)"> -> !cute.layout<"(?,?):(?,1)">
  %r = cute.select<[2, 0]> (%l)
         : !cute.layout<"(?,4,?):(1,?,?)">
        -> !cute.layout<"(?,?):(?,1)">
  return
}

// -----

// Tests select on a bare stride with scaled-basis entries.
// CHECK-LABEL: func.func @permute_stride_scaled_basis
// CHECK-SAME:  (%[[S:.+]]: !cute.stride<"(1@0,1@1)">)
func.func @permute_stride_scaled_basis(%s: !cute.stride<"(1@0,1@1)">) {
  // CHECK: %[[R:.+]] = cute.select<[1, 0]> (%[[S]]) : !cute.stride<"(1@0,1@1)"> -> !cute.stride<"(1@1,1@0)">
  %r = cute.select<[1, 0]> (%s) : !cute.stride<"(1@0,1@1)"> -> !cute.stride<"(1@1,1@0)">
  return
}

// -----

// Tests select on a composed_layout whose outer B has scaled-basis
// strides.
// CHECK-LABEL: func.func @composed_layout_scaled_basis_outer
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"(4,5):(1,4) o (0,0) o (4,8):(1@0,1@1)">)
func.func @composed_layout_scaled_basis_outer(
    %cl: !cute.composed_layout<"(4,5):(1,4) o (0,0) o (4,8):(1@0,1@1)">) {
  // CHECK: %[[R:.+]] = cute.select<[1, 0]> (%[[CL]]) : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (4,8):(1@0,1@1)"> -> !cute.composed_layout<"(4,5):(1,4) o (0,0) o (8,4):(1@1,1@0)">
  %r = cute.select<[1, 0]> (%cl)
         : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (4,8):(1@0,1@1)">
        -> !cute.composed_layout<"(4,5):(1,4) o (0,0) o (8,4):(1@1,1@0)">
  return
}

// -----

// Tests select on a nested scaled-basis stride.
// CHECK-LABEL: func.func @nested_scaled_basis_stride
// CHECK-SAME:  (%[[S:.+]]: !cute.stride<"((1@0@0,1@1@0),1@1)">)
func.func @nested_scaled_basis_stride(%s: !cute.stride<"((1@0@0,1@1@0),1@1)">) {
  // CHECK: %[[R:.+]] = cute.select<[1, 0]> (%[[S]]) : !cute.stride<"((1@0@0,1@1@0),1@1)"> -> !cute.stride<"(1@1,(1@0@0,1@1@0))">
  %r = cute.select<[1, 0]> (%s)
         : !cute.stride<"((1@0@0,1@1@0),1@1)">
        -> !cute.stride<"(1@1,(1@0@0,1@1@0))">
  return
}
