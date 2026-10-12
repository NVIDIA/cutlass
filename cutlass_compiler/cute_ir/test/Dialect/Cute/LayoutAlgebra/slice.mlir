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

// Tests round-trip for cute.slice.

// -----

// Keep mode 1, fix modes 0 and 2.
// CHECK-LABEL: func.func @keep_middle
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3,4):(1,2,6)">, %[[CRD:.+]]: !cute.coord<"(0,_,1)">)
func.func @keep_middle(
    %src: !cute.layout<"(2,3,4):(1,2,6)">,
    %crd: !cute.coord<"(0,_,1)">) -> !cute.layout<"(3):(2)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(0,_,1)">
  // CHECK: return %[[R]] : !cute.layout<"(3):(2)">
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(0,_,1)">
  return %r : !cute.layout<"(3):(2)">
}

// -----

// Keep modes 0 and 2, fix mode 1.
// CHECK-LABEL: func.func @keep_outer_two
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3,4):(1,2,6)">, %[[CRD:.+]]: !cute.coord<"(_,0,_)">)
func.func @keep_outer_two(
    %src: !cute.layout<"(2,3,4):(1,2,6)">,
    %crd: !cute.coord<"(_,0,_)">) -> !cute.layout<"(2,4):(1,6)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,0,_)">
  // CHECK: return %[[R]] : !cute.layout<"(2,4):(1,6)">
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,0,_)">
  return %r : !cute.layout<"(2,4):(1,6)">
}

// -----

// All underscores — identity slice.
// CHECK-LABEL: func.func @identity
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3,4):(1,2,6)">, %[[CRD:.+]]: !cute.coord<"(_,_,_)">)
func.func @identity(
    %src: !cute.layout<"(2,3,4):(1,2,6)">,
    %crd: !cute.coord<"(_,_,_)">) -> !cute.layout<"(2,3,4):(1,2,6)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,_,_)">
  // CHECK: return %[[R]] : !cute.layout<"(2,3,4):(1,2,6)">
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,_,_)">
  return %r : !cute.layout<"(2,3,4):(1,2,6)">
}

// -----

// Rank-2 layout, fix first mode.
// CHECK-LABEL: func.func @rank2_fix_first
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(8,4):(1,8)">, %[[CRD:.+]]: !cute.coord<"(0,_)">)
func.func @rank2_fix_first(
    %src: !cute.layout<"(8,4):(1,8)">,
    %crd: !cute.coord<"(0,_)">) -> !cute.layout<"(4):(8)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(8,4):(1,8)">, !cute.coord<"(0,_)">
  // CHECK: return %[[R]] : !cute.layout<"(4):(8)">
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(8,4):(1,8)">, !cute.coord<"(0,_)">
  return %r : !cute.layout<"(4):(8)">
}

// -----

// Dynamic layout, fix second mode.
// CHECK-LABEL: func.func @dynamic_fix_second
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(?,4):(1,?)">, %[[CRD:.+]]: !cute.coord<"(_,0)">)
func.func @dynamic_fix_second(
    %src: !cute.layout<"(?,4):(1,?)">,
    %crd: !cute.coord<"(_,0)">) -> !cute.layout<"(?):(1)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(?,4):(1,?)">, !cute.coord<"(_,0)">
  // CHECK: return %[[R]] : !cute.layout<"(?):(1)">
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(?,4):(1,?)">, !cute.coord<"(_,0)">
  return %r : !cute.layout<"(?):(1)">
}

// -----

// Composed layout: coord applied to outer B, A and offset unchanged.
// CHECK-LABEL: func.func @composed_fix_first
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"(0,_)">)
func.func @composed_fix_first(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">,
    %crd: !cute.coord<"(0,_)">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">
  // CHECK-SAME: !cute.coord<"(0,_)">
  // CHECK: return %[[R]] : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">,
           !cute.coord<"(0,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
}

// -----

// Scalar _ coord — weakly congruent with any layout.
// CHECK-LABEL: func.func @scalar_underscore_keeps_all
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3,4):(1,2,6)">, %[[CRD:.+]]: !cute.coord<"_">)
func.func @scalar_underscore_keeps_all(
    %src: !cute.layout<"(2,3,4):(1,2,6)">,
    %crd: !cute.coord<"_">) -> !cute.layout<"(2,3,4):(1,2,6)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"_">
  // CHECK: return %[[R]] : !cute.layout<"(2,3,4):(1,2,6)">
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"_">
  return %r : !cute.layout<"(2,3,4):(1,2,6)">
}

// -----

// Scalar integer coord — weakly congruent with any layout.
// CHECK-LABEL: func.func @scalar_int_discards_all
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3,4):(1,2,6)">, %[[CRD:.+]]: !cute.coord<"1">)
func.func @scalar_int_discards_all(
    %src: !cute.layout<"(2,3,4):(1,2,6)">,
    %crd: !cute.coord<"1">) -> !cute.layout<"():()"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"1">
  // CHECK: return %[[R]] : !cute.layout<"():()">
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"1">
  return %r : !cute.layout<"():()">
}

// -----

// Nested layout: single integer sub-coord.
// CHECK-LABEL: func.func @nested_int_discards_submode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((2,4),3):((1,2),8)">, %[[CRD:.+]]: !cute.coord<"(0,_)">)
func.func @nested_int_discards_submode(
    %src: !cute.layout<"((2,4),3):((1,2),8)">,
    %crd: !cute.coord<"(0,_)">) -> !cute.layout<"(3):(8)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"(0,_)">
  // CHECK: return %[[R]] : !cute.layout<"(3):(8)">
  %r = cute.slice(%src, %crd)
         : !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"(0,_)">
  return %r : !cute.layout<"(3):(8)">
}

// -----

// Nested layout.
// CHECK-LABEL: func.func @nested_underscore_keeps_submode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((2,4),3):((1,2),8)">, %[[CRD:.+]]: !cute.coord<"(_,0)">)
func.func @nested_underscore_keeps_submode(
    %src: !cute.layout<"((2,4),3):((1,2),8)">,
    %crd: !cute.coord<"(_,0)">) -> !cute.layout<"((2,4)):((1,2))"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"(_,0)">
  // CHECK: return %[[R]] : !cute.layout<"((2,4)):((1,2))">
  %r = cute.slice(%src, %crd)
         : !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"(_,0)">
  return %r : !cute.layout<"((2,4)):((1,2))">
}

// -----

// Nested layout: sub-tuple coord selects within the nested sub-mode.
// CHECK-LABEL: func.func @nested_sub_coord
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((2,4),3):((1,2),8)">, %[[CRD:.+]]: !cute.coord<"((_,0),_)">)
func.func @nested_sub_coord(
    %src: !cute.layout<"((2,4),3):((1,2),8)">,
    %crd: !cute.coord<"((_,0),_)">) -> !cute.layout<"(2,3):(1,8)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"((_,0),_)">
  // CHECK: return %[[R]] : !cute.layout<"(2,3):(1,8)">
  %r = cute.slice(%src, %crd)
         : !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"((_,0),_)">
  return %r : !cute.layout<"(2,3):(1,8)">
}

// -----

// Shape input: integer-marked modes are dropped, underscore-marked are kept.
// CHECK-LABEL: func.func @shape_keep_outer_two
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(2,3,4)">, %[[CRD:.+]]: !cute.coord<"(_,1,_)">)
func.func @shape_keep_outer_two(
    %src: !cute.shape<"(2,3,4)">,
    %crd: !cute.coord<"(_,1,_)">) -> !cute.shape<"(2,4)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.shape<"(2,3,4)">, !cute.coord<"(_,1,_)">
  // CHECK: return %[[R]] : !cute.shape<"(2,4)">
  %r = cute.slice(%src, %crd)
         : !cute.shape<"(2,3,4)">, !cute.coord<"(_,1,_)">
  return %r : !cute.shape<"(2,4)">
}

// -----

// Stride input with a dynamic leaf preserved in the kept mode.
// CHECK-LABEL: func.func @stride_dynamic_kept
// CHECK-SAME:  (%[[SRC:.+]]: !cute.stride<"(?,2,4)">, %[[CRD:.+]]: !cute.coord<"(_,0,_)">)
func.func @stride_dynamic_kept(
    %src: !cute.stride<"(?,2,4)">,
    %crd: !cute.coord<"(_,0,_)">) -> !cute.stride<"(?,4)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.stride<"(?,2,4)">, !cute.coord<"(_,0,_)">
  // CHECK: return %[[R]] : !cute.stride<"(?,4)">
  %r = cute.slice(%src, %crd)
         : !cute.stride<"(?,2,4)">, !cute.coord<"(_,0,_)">
  return %r : !cute.stride<"(?,4)">
}

// -----

// IntTuple input with nested sub-tuple kept whole.
// CHECK-LABEL: func.func @int_tuple_keep_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(1,(2,3))">, %[[CRD:.+]]: !cute.coord<"(0,_)">)
func.func @int_tuple_keep_nested(
    %src: !cute.int_tuple<"(1,(2,3))">,
    %crd: !cute.coord<"(0,_)">) -> !cute.int_tuple<"((2,3))"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.int_tuple<"(1,(2,3))">, !cute.coord<"(0,_)">
  // CHECK: return %[[R]] : !cute.int_tuple<"((2,3))">
  %r = cute.slice(%src, %crd)
         : !cute.int_tuple<"(1,(2,3))">, !cute.coord<"(0,_)">
  return %r : !cute.int_tuple<"((2,3))">
}

// -----

// Coord input: slice on a coord.
// CHECK-LABEL: func.func @coord_keep_underscore_modes
// CHECK-SAME:  (%[[SRC:.+]]: !cute.coord<"(0,_,1)">, %[[CRD:.+]]: !cute.coord<"(_,_,1)">)
func.func @coord_keep_underscore_modes(
    %src: !cute.coord<"(0,_,1)">,
    %crd: !cute.coord<"(_,_,1)">) -> !cute.coord<"(0,_)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.coord<"(0,_,1)">, !cute.coord<"(_,_,1)">
  // CHECK: return %[[R]] : !cute.coord<"(0,_)">
  %r = cute.slice(%src, %crd)
         : !cute.coord<"(0,_,1)">, !cute.coord<"(_,_,1)">
  return %r : !cute.coord<"(0,_)">
}

// -----

// Shape input with all dynamic leaves.
// CHECK-LABEL: func.func @shape_dynamic_drop_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(?,?,?)">, %[[CRD:.+]]: !cute.coord<"(_,0,_)">)
func.func @shape_dynamic_drop_dynamic(
    %src: !cute.shape<"(?,?,?)">,
    %crd: !cute.coord<"(_,0,_)">) -> !cute.shape<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.shape<"(?,?,?)">, !cute.coord<"(_,0,_)">
  // CHECK: return %[[R]] : !cute.shape<"(?,?)">
  %r = cute.slice(%src, %crd)
         : !cute.shape<"(?,?,?)">, !cute.coord<"(_,0,_)">
  return %r : !cute.shape<"(?,?)">
}

// -----

// Swizzle-A composed.
// CHECK-LABEL: func.func @swizzle_composed_keep_mode1
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,4,3> o 0 o (64,128):(1,64)">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"(1,_)">)
func.func @swizzle_composed_keep_mode1(
    %src: !cute.composed_layout<"S<3,4,3> o 0 o (64,128):(1,64)">,
    %crd: !cute.coord<"(1,_)">)
    -> !cute.composed_layout<"S<3,4,3> o 0 o (128):(64)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.composed_layout<"S<3,4,3> o 0 o (64,128):(1,64)">
  // CHECK-SAME: !cute.coord<"(1,_)">
  // CHECK: return %[[R]] : !cute.composed_layout<"S<3,4,3> o 0 o (128):(64)">
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"S<3,4,3> o 0 o (64,128):(1,64)">,
           !cute.coord<"(1,_)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o (128):(64)">
}

// -----

// Swizzle-A composed.
// CHECK-LABEL: func.func @swizzle_composed_normalizes_to_plain
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,4,3> o 0 o (16,8):(1,16)">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"(_,1)">)
func.func @swizzle_composed_normalizes_to_plain(
    %src: !cute.composed_layout<"S<3,4,3> o 0 o (16,8):(1,16)">,
    %crd: !cute.coord<"(_,1)">)
    -> !cute.layout<"(16):(1)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.composed_layout<"S<3,4,3> o 0 o (16,8):(1,16)">
  // CHECK-SAME: !cute.coord<"(_,1)">
  // CHECK: return %[[R]] : !cute.layout<"(16):(1)">
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"S<3,4,3> o 0 o (16,8):(1,16)">,
           !cute.coord<"(_,1)">
  return %r : !cute.layout<"(16):(1)">
}

// -----

// Swizzle-A composed with nested static B and a dynamic coord.
// CHECK-LABEL: func.func @swizzle_composed_dynamic_strides
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,2,4> o 0 o ((1,(16,1)),(1,(4,8))):((0,(4,0)),(0,(1,64)))">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"(?,_)">)
func.func @swizzle_composed_dynamic_strides(
    %src: !cute.composed_layout<"S<3,2,4> o 0 o ((1,(16,1)),(1,(4,8))):((0,(4,0)),(0,(1,64)))">,
    %crd: !cute.coord<"(?,_)">)
    -> !cute.layout<"((1,(4,(2,2,2)))):((0,(1,(?,?,?))))"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.composed_layout<"S<3,2,4> o 0 o ((1,(16,1)),(1,(4,8))):((0,(4,0)),(0,(1,64)))">
  // CHECK-SAME: !cute.coord<"(?,_)">
  // CHECK: return %[[R]] : !cute.layout<"((1,(4,(2,2,2)))):((0,(1,(?,?,?))))">
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"S<3,2,4> o 0 o ((1,(16,1)),(1,(4,8))):((0,(4,0)),(0,(1,64)))">,
           !cute.coord<"(?,_)">
  return %r : !cute.layout<"((1,(4,(2,2,2)))):((0,(1,(?,?,?))))">
}

// -----

// All-static stride input.
// CHECK-LABEL: func.func @stride_all_static
// CHECK-SAME:  (%[[SRC:.+]]: !cute.stride<"(1,8,16)">, %[[CRD:.+]]: !cute.coord<"(_,1,_)">)
func.func @stride_all_static(
    %src: !cute.stride<"(1,8,16)">,
    %crd: !cute.coord<"(_,1,_)">) -> !cute.stride<"(1,16)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.stride<"(1,8,16)">, !cute.coord<"(_,1,_)">
  // CHECK: return %[[R]] : !cute.stride<"(1,16)">
  %r = cute.slice(%src, %crd) : !cute.stride<"(1,8,16)">, !cute.coord<"(_,1,_)">
  return %r : !cute.stride<"(1,16)">
}

// -----

// All-dynamic int_tuple input.
// CHECK-LABEL: func.func @int_tuple_all_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(?,?,?)">, %[[CRD:.+]]: !cute.coord<"(0,_,_)">)
func.func @int_tuple_all_dynamic(
    %src: !cute.int_tuple<"(?,?,?)">,
    %crd: !cute.coord<"(0,_,_)">) -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.int_tuple<"(?,?,?)">, !cute.coord<"(0,_,_)">
  // CHECK: return %[[R]] : !cute.int_tuple<"(?,?)">
  %r = cute.slice(%src, %crd) : !cute.int_tuple<"(?,?,?)">, !cute.coord<"(0,_,_)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// Coord input with dynamic leaves preserved.
// CHECK-LABEL: func.func @coord_dynamic_leaves
// CHECK-SAME:  (%[[SRC:.+]]: !cute.coord<"(?,_,?)">, %[[CRD:.+]]: !cute.coord<"(_,_,1)">)
func.func @coord_dynamic_leaves(
    %src: !cute.coord<"(?,_,?)">,
    %crd: !cute.coord<"(_,_,1)">) -> !cute.coord<"(?,_)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.coord<"(?,_,?)">, !cute.coord<"(_,_,1)">
  // CHECK: return %[[R]] : !cute.coord<"(?,_)">
  %r = cute.slice(%src, %crd) : !cute.coord<"(?,_,?)">, !cute.coord<"(_,_,1)">
  return %r : !cute.coord<"(?,_)">
}

// -----

// Static plain layout with dynamic coord.
// CHECK-LABEL: func.func @layout_dynamic_coord
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(8,4):(1,8)">, %[[CRD:.+]]: !cute.coord<"(?,_)">)
func.func @layout_dynamic_coord(
    %src: !cute.layout<"(8,4):(1,8)">,
    %crd: !cute.coord<"(?,_)">) -> !cute.layout<"(4):(8)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(8,4):(1,8)">, !cute.coord<"(?,_)">
  // CHECK: return %[[R]] : !cute.layout<"(4):(8)">
  %r = cute.slice(%src, %crd) : !cute.layout<"(8,4):(1,8)">, !cute.coord<"(?,_)">
  return %r : !cute.layout<"(4):(8)">
}

// -----

// Affine-A composed with dynamic outer B.
// CHECK-LABEL: func.func @composed_affine_dynamic_outer
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(?,4)">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"(1,_)">)
func.func @composed_affine_dynamic_outer(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(?,4)">,
    %crd: !cute.coord<"(1,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o ? o (3):(4)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(?,4)">
  // CHECK-SAME: !cute.coord<"(1,_)">
  // CHECK: return %[[R]] : !cute.composed_layout<"(4,5):(1,4) o ? o (3):(4)">
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3):(?,4)">,
           !cute.coord<"(1,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o ? o (3):(4)">
}

// -----

// Affine-A composed with static input + dynamic coord.
// CHECK-LABEL: func.func @composed_affine_dyn_coord_offset_change
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"(?,_)">)
func.func @composed_affine_dyn_coord_offset_change(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
    %crd: !cute.coord<"(?,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o ? o (3):(8)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">
  // CHECK-SAME: !cute.coord<"(?,_)">
  // CHECK: return %[[R]] : !cute.composed_layout<"(4,5):(1,4) o ? o (3):(8)">
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
           !cute.coord<"(?,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o ? o (3):(8)">
}

// -----

// Swizzle-composed slice + dynamic-coord branch.
// CHECK-LABEL: func.func @composed_swizzle_dyn_coord_normalizes
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"(?,_)">)
func.func @composed_swizzle_dyn_coord_normalizes(
    %src: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">,
    %crd: !cute.coord<"(?,_)">)
    -> !cute.layout<"(4):(8)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  // CHECK-SAME: !cute.coord<"(?,_)">
  // CHECK: return %[[R]] : !cute.layout<"(4):(8)">
  %r = cute.slice(%src, %crd)
         : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">,
           !cute.coord<"(?,_)">
  return %r : !cute.layout<"(4):(8)">
}

// -----

// Deeply-nested layout.
// CHECK-LABEL: func.func @deeply_nested_layout
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(((2,3),4),(5,(6,7))):(((1,2),6),(24,(120,720)))">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"((_,0),_)">)
func.func @deeply_nested_layout(
    %src: !cute.layout<"(((2,3),4),(5,(6,7))):(((1,2),6),(24,(120,720)))">,
    %crd: !cute.coord<"((_,0),_)">)
    -> !cute.layout<"((2,3),(5,(6,7))):((1,2),(24,(120,720)))"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(((2,3),4),(5,(6,7))):(((1,2),6),(24,(120,720)))">
  // CHECK-SAME: !cute.coord<"((_,0),_)">
  // CHECK: return %[[R]] : !cute.layout<"((2,3),(5,(6,7))):((1,2),(24,(120,720)))">
  %r = cute.slice(%src, %crd)
         : !cute.layout<"(((2,3),4),(5,(6,7))):(((1,2),6),(24,(120,720)))">,
           !cute.coord<"((_,0),_)">
  return %r : !cute.layout<"((2,3),(5,(6,7))):((1,2),(24,(120,720)))">
}

// -----

// Layout with scaled-basis stride.
// CHECK-LABEL: func.func @layout_scaled_basis_stride
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3,4):(1@0,1@1,1@2)">, %[[CRD:.+]]: !cute.coord<"(_,1,_)">)
func.func @layout_scaled_basis_stride(
    %src: !cute.layout<"(2,3,4):(1@0,1@1,1@2)">,
    %crd: !cute.coord<"(_,1,_)">) -> !cute.layout<"(2,4):(1@0,1@2)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(2,3,4):(1@0,1@1,1@2)">, !cute.coord<"(_,1,_)">
  // CHECK: return %[[R]] : !cute.layout<"(2,4):(1@0,1@2)">
  %r = cute.slice(%src, %crd) : !cute.layout<"(2,3,4):(1@0,1@1,1@2)">, !cute.coord<"(_,1,_)">
  return %r : !cute.layout<"(2,4):(1@0,1@2)">
}

// -----

// Nested layout with scaled-basis stride.
// CHECK-LABEL: func.func @nested_scaled_basis_stride
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((2,3),4):((1@0,1@1),1@2)">, %[[CRD:.+]]: !cute.coord<"((_,0),_)">)
func.func @nested_scaled_basis_stride(
    %src: !cute.layout<"((2,3),4):((1@0,1@1),1@2)">,
    %crd: !cute.coord<"((_,0),_)">) -> !cute.layout<"(2,4):(1@0,1@2)"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"((2,3),4):((1@0,1@1),1@2)">, !cute.coord<"((_,0),_)">
  // CHECK: return %[[R]] : !cute.layout<"(2,4):(1@0,1@2)">
  %r = cute.slice(%src, %crd) : !cute.layout<"((2,3),4):((1@0,1@1),1@2)">, !cute.coord<"((_,0),_)">
  return %r : !cute.layout<"(2,4):(1@0,1@2)">
}

// -----

// Deeply-nested shape.
// CHECK-LABEL: func.func @deeply_nested_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(((2,3),4),(5,(6,7)))">, %[[CRD:.+]]: !cute.coord<"((_,1),_)">)
func.func @deeply_nested_shape(
    %src: !cute.shape<"(((2,3),4),(5,(6,7)))">,
    %crd: !cute.coord<"((_,1),_)">) -> !cute.shape<"((2,3),(5,(6,7)))"> {
  // CHECK: %[[R:.+]] = cute.slice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.shape<"(((2,3),4),(5,(6,7)))">, !cute.coord<"((_,1),_)">
  // CHECK: return %[[R]] : !cute.shape<"((2,3),(5,(6,7)))">
  %r = cute.slice(%src, %crd)
         : !cute.shape<"(((2,3),4),(5,(6,7)))">, !cute.coord<"((_,1),_)">
  return %r : !cute.shape<"((2,3),(5,(6,7)))">
}
