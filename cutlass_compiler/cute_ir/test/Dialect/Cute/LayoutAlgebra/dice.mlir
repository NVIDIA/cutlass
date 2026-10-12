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

// Tests round-trip for cute.dice.
// In dice, integer elements in the coord KEEP the corresponding mode;
// underscore elements DISCARD the corresponding mode.

// -----

// Keep mode 1, discard modes 0 and 2.
// CHECK-LABEL: func.func @keep_middle
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3,4):(1,2,6)">, %[[CRD:.+]]: !cute.coord<"(_,1,_)">)
func.func @keep_middle(
    %src: !cute.layout<"(2,3,4):(1,2,6)">,
    %crd: !cute.coord<"(_,1,_)">) -> !cute.layout<"(3):(2)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,1,_)">
  // CHECK: return %[[R]] : !cute.layout<"(3):(2)">
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,1,_)">
  return %r : !cute.layout<"(3):(2)">
}

// -----

// Keep mode 0 only.
// CHECK-LABEL: func.func @keep_first
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3,4):(1,2,6)">, %[[CRD:.+]]: !cute.coord<"(1,_,_)">)
func.func @keep_first(
    %src: !cute.layout<"(2,3,4):(1,2,6)">,
    %crd: !cute.coord<"(1,_,_)">) -> !cute.layout<"(2):(1)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(1,_,_)">
  // CHECK: return %[[R]] : !cute.layout<"(2):(1)">
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(1,_,_)">
  return %r : !cute.layout<"(2):(1)">
}

// -----

// Keep modes 1 and 2, discard mode 0.
// CHECK-LABEL: func.func @keep_last_two
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3,4):(1,2,6)">, %[[CRD:.+]]: !cute.coord<"(_,1,1)">)
func.func @keep_last_two(
    %src: !cute.layout<"(2,3,4):(1,2,6)">,
    %crd: !cute.coord<"(_,1,1)">) -> !cute.layout<"(3,4):(2,6)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,1,1)">
  // CHECK: return %[[R]] : !cute.layout<"(3,4):(2,6)">
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,1,1)">
  return %r : !cute.layout<"(3,4):(2,6)">
}

// -----

// Composed layout: coord applied to outer B, A and offset unchanged.
// CHECK-LABEL: func.func @composed_keep_second
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"(_,1)">)
func.func @composed_keep_second(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">,
    %crd: !cute.coord<"(_,1)">) -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">
  // CHECK-SAME: !cute.coord<"(_,1)">
  // CHECK: return %[[R]] : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
  %r = cute.dice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,3):(1,4)">,
           !cute.coord<"(_,1)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
}

// -----

// Scalar _ coord.
// CHECK-LABEL: func.func @scalar_underscore_discards_all
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3,4):(1,2,6)">, %[[CRD:.+]]: !cute.coord<"_">)
func.func @scalar_underscore_discards_all(
    %src: !cute.layout<"(2,3,4):(1,2,6)">,
    %crd: !cute.coord<"_">) -> !cute.layout<"():()"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"_">
  // CHECK: return %[[R]] : !cute.layout<"():()">
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"_">
  return %r : !cute.layout<"():()">
}

// -----

// Scalar integer coord.
// CHECK-LABEL: func.func @scalar_int_keeps_all
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3,4):(1,2,6)">, %[[CRD:.+]]: !cute.coord<"1">)
func.func @scalar_int_keeps_all(
    %src: !cute.layout<"(2,3,4):(1,2,6)">,
    %crd: !cute.coord<"1">) -> !cute.layout<"(2,3,4):(1,2,6)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"1">
  // CHECK: return %[[R]] : !cute.layout<"(2,3,4):(1,2,6)">
  %r = cute.dice(%src, %crd)
         : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"1">
  return %r : !cute.layout<"(2,3,4):(1,2,6)">
}

// -----

// Nested layout: single integer sub-coord.
// CHECK-LABEL: func.func @nested_int_keeps_submode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((2,4),3):((1,2),8)">, %[[CRD:.+]]: !cute.coord<"(1,_)">)
func.func @nested_int_keeps_submode(
    %src: !cute.layout<"((2,4),3):((1,2),8)">,
    %crd: !cute.coord<"(1,_)">) -> !cute.layout<"((2,4)):((1,2))"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"(1,_)">
  // CHECK: return %[[R]] : !cute.layout<"((2,4)):((1,2))">
  %r = cute.dice(%src, %crd)
         : !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"(1,_)">
  return %r : !cute.layout<"((2,4)):((1,2))">
}

// -----

// Nested layout: _ sub-coord.
// CHECK-LABEL: func.func @nested_underscore_discards_submode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((2,4),3):((1,2),8)">, %[[CRD:.+]]: !cute.coord<"(_,1)">)
func.func @nested_underscore_discards_submode(
    %src: !cute.layout<"((2,4),3):((1,2),8)">,
    %crd: !cute.coord<"(_,1)">) -> !cute.layout<"(3):(8)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"(_,1)">
  // CHECK: return %[[R]] : !cute.layout<"(3):(8)">
  %r = cute.dice(%src, %crd)
         : !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"(_,1)">
  return %r : !cute.layout<"(3):(8)">
}

// -----

// Nested layout: tuple coord.
// CHECK-LABEL: func.func @nested_sub_coord
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((2,4),3):((1,2),8)">, %[[CRD:.+]]: !cute.coord<"((1,_),_)">)
func.func @nested_sub_coord(
    %src: !cute.layout<"((2,4),3):((1,2),8)">,
    %crd: !cute.coord<"((1,_),_)">) -> !cute.layout<"(2):(1)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"((1,_),_)">
  // CHECK: return %[[R]] : !cute.layout<"(2):(1)">
  %r = cute.dice(%src, %crd)
         : !cute.layout<"((2,4),3):((1,2),8)">, !cute.coord<"((1,_),_)">
  return %r : !cute.layout<"(2):(1)">
}

// -----

// Shape input: keep only mode 0.
// CHECK-LABEL: func.func @shape_keep_first
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(2,3,4)">, %[[CRD:.+]]: !cute.coord<"(1,_,_)">)
func.func @shape_keep_first(
    %src: !cute.shape<"(2,3,4)">,
    %crd: !cute.coord<"(1,_,_)">) -> !cute.shape<"(2)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.shape<"(2,3,4)">, !cute.coord<"(1,_,_)">
  // CHECK: return %[[R]] : !cute.shape<"(2)">
  %r = cute.dice(%src, %crd)
         : !cute.shape<"(2,3,4)">, !cute.coord<"(1,_,_)">
  return %r : !cute.shape<"(2)">
}

// -----

// Stride input: drop a dynamic-leaf mode, keep the remaining two static modes.
// CHECK-LABEL: func.func @stride_drop_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.stride<"(?,2,4)">, %[[CRD:.+]]: !cute.coord<"(_,1,1)">)
func.func @stride_drop_dynamic(
    %src: !cute.stride<"(?,2,4)">,
    %crd: !cute.coord<"(_,1,1)">) -> !cute.stride<"(2,4)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.stride<"(?,2,4)">, !cute.coord<"(_,1,1)">
  // CHECK: return %[[R]] : !cute.stride<"(2,4)">
  %r = cute.dice(%src, %crd)
         : !cute.stride<"(?,2,4)">, !cute.coord<"(_,1,1)">
  return %r : !cute.stride<"(2,4)">
}

// -----

// IntTuple input: keep a nested mode by selecting it with an integer.
// CHECK-LABEL: func.func @int_tuple_keep_nested
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(1,(2,3))">, %[[CRD:.+]]: !cute.coord<"(_,1)">)
func.func @int_tuple_keep_nested(
    %src: !cute.int_tuple<"(1,(2,3))">,
    %crd: !cute.coord<"(_,1)">) -> !cute.int_tuple<"((2,3))"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.int_tuple<"(1,(2,3))">, !cute.coord<"(_,1)">
  // CHECK: return %[[R]] : !cute.int_tuple<"((2,3))">
  %r = cute.dice(%src, %crd)
         : !cute.int_tuple<"(1,(2,3))">, !cute.coord<"(_,1)">
  return %r : !cute.int_tuple<"((2,3))">
}

// -----

// Coord input: dice keeps modes 1 and 2.
// CHECK-LABEL: func.func @coord_keep_integer_modes
// CHECK-SAME:  (%[[SRC:.+]]: !cute.coord<"(0,_,1)">, %[[CRD:.+]]: !cute.coord<"(_,1,1)">)
func.func @coord_keep_integer_modes(
    %src: !cute.coord<"(0,_,1)">,
    %crd: !cute.coord<"(_,1,1)">) -> !cute.coord<"(_,1)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.coord<"(0,_,1)">, !cute.coord<"(_,1,1)">
  // CHECK: return %[[R]] : !cute.coord<"(_,1)">
  %r = cute.dice(%src, %crd)
         : !cute.coord<"(0,_,1)">, !cute.coord<"(_,1,1)">
  return %r : !cute.coord<"(_,1)">
}

// -----

// Fully dynamic shape input — the kept mode round-trips with its
// dynamic leaf intact.
// CHECK-LABEL: func.func @shape_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(?,?,?)">, %[[CRD:.+]]: !cute.coord<"(_,1,_)">)
func.func @shape_dynamic(
    %src: !cute.shape<"(?,?,?)">,
    %crd: !cute.coord<"(_,1,_)">) -> !cute.shape<"(?)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.shape<"(?,?,?)">, !cute.coord<"(_,1,_)">
  // CHECK: return %[[R]] : !cute.shape<"(?)">
  %r = cute.dice(%src, %crd)
         : !cute.shape<"(?,?,?)">, !cute.coord<"(_,1,_)">
  return %r : !cute.shape<"(?)">
}

// -----

// Shape input with plain dynamic leaves.
// CHECK-LABEL: func.func @shape_dynamic_drop_static
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(?,2,?)">, %[[CRD:.+]]: !cute.coord<"(1,_,1)">)
func.func @shape_dynamic_drop_static(
    %src: !cute.shape<"(?,2,?)">,
    %crd: !cute.coord<"(1,_,1)">) -> !cute.shape<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.shape<"(?,2,?)">, !cute.coord<"(1,_,1)">
  // CHECK: return %[[R]] : !cute.shape<"(?,?)">
  %r = cute.dice(%src, %crd)
         : !cute.shape<"(?,2,?)">, !cute.coord<"(1,_,1)">
  return %r : !cute.shape<"(?,?)">
}

// -----

// Swizzle-A composed.
// CHECK-LABEL: func.func @swizzle_composed_keep_mode1
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,5,4> o 0 o (8,4,2):(1,8,32)">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"(_,1,_)">)
func.func @swizzle_composed_keep_mode1(
    %src: !cute.composed_layout<"S<3,5,4> o 0 o (8,4,2):(1,8,32)">,
    %crd: !cute.coord<"(_,1,_)">)
    -> !cute.composed_layout<"S<3,5,4> o 0 o (4):(8)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.composed_layout<"S<3,5,4> o 0 o (8,4,2):(1,8,32)">
  // CHECK-SAME: !cute.coord<"(_,1,_)">
  // CHECK: return %[[R]] : !cute.composed_layout<"S<3,5,4> o 0 o (4):(8)">
  %r = cute.dice(%src, %crd)
         : !cute.composed_layout<"S<3,5,4> o 0 o (8,4,2):(1,8,32)">,
           !cute.coord<"(_,1,_)">
  return %r : !cute.composed_layout<"S<3,5,4> o 0 o (4):(8)">
}

// -----

// All-static stride input.
// CHECK-LABEL: func.func @stride_all_static
// CHECK-SAME:  (%[[SRC:.+]]: !cute.stride<"(1,8,16)">, %[[CRD:.+]]: !cute.coord<"(_,1,_)">)
func.func @stride_all_static(
    %src: !cute.stride<"(1,8,16)">,
    %crd: !cute.coord<"(_,1,_)">) -> !cute.stride<"(8)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.stride<"(1,8,16)">, !cute.coord<"(_,1,_)">
  // CHECK: return %[[R]] : !cute.stride<"(8)">
  %r = cute.dice(%src, %crd) : !cute.stride<"(1,8,16)">, !cute.coord<"(_,1,_)">
  return %r : !cute.stride<"(8)">
}

// -----

// All-dynamic int_tuple input.
// CHECK-LABEL: func.func @int_tuple_all_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(?,?,?)">, %[[CRD:.+]]: !cute.coord<"(1,_,1)">)
func.func @int_tuple_all_dynamic(
    %src: !cute.int_tuple<"(?,?,?)">,
    %crd: !cute.coord<"(1,_,1)">) -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.int_tuple<"(?,?,?)">, !cute.coord<"(1,_,1)">
  // CHECK: return %[[R]] : !cute.int_tuple<"(?,?)">
  %r = cute.dice(%src, %crd) : !cute.int_tuple<"(?,?,?)">, !cute.coord<"(1,_,1)">
  return %r : !cute.int_tuple<"(?,?)">
}

// -----

// Coord input with dynamic leaves, the kept `_` mode stays an underscore in the result.
// CHECK-LABEL: func.func @coord_dynamic_leaves
// CHECK-SAME:  (%[[SRC:.+]]: !cute.coord<"(?,_,?)">, %[[CRD:.+]]: !cute.coord<"(_,1,1)">)
func.func @coord_dynamic_leaves(
    %src: !cute.coord<"(?,_,?)">,
    %crd: !cute.coord<"(_,1,1)">) -> !cute.coord<"(_,?)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.coord<"(?,_,?)">, !cute.coord<"(_,1,1)">
  // CHECK: return %[[R]] : !cute.coord<"(_,?)">
  %r = cute.dice(%src, %crd) : !cute.coord<"(?,_,?)">, !cute.coord<"(_,1,1)">
  return %r : !cute.coord<"(_,?)">
}

// -----

// Plain layout with dynamic shape + dynamic stride leaves.
// CHECK-LABEL: func.func @layout_dynamic_drop_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(?,4,?):(1,?,?)">, %[[CRD:.+]]: !cute.coord<"(_,1,_)">)
func.func @layout_dynamic_drop_dynamic(
    %src: !cute.layout<"(?,4,?):(1,?,?)">,
    %crd: !cute.coord<"(_,1,_)">) -> !cute.layout<"(4):(?)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"(?,4,?):(1,?,?)">, !cute.coord<"(_,1,_)">
  // CHECK: return %[[R]] : !cute.layout<"(4):(?)">
  %r = cute.dice(%src, %crd) : !cute.layout<"(?,4,?):(1,?,?)">, !cute.coord<"(_,1,_)">
  return %r : !cute.layout<"(4):(?)">
}

// -----

// Affine-A composed with dynamic outer B.
// CHECK-LABEL: func.func @composed_affine_dynamic_outer
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3,4):(?,4,?)">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"(_,1,_)">)
func.func @composed_affine_dynamic_outer(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3,4):(?,4,?)">,
    %crd: !cute.coord<"(_,1,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3,4):(?,4,?)">
  // CHECK-SAME: !cute.coord<"(_,1,_)">
  // CHECK: return %[[R]] : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
  %r = cute.dice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o 2 o (?,3,4):(?,4,?)">,
           !cute.coord<"(_,1,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(4)">
}

// -----

// Nested layout with scaled-basis stride.
// CHECK-LABEL: func.func @nested_scaled_basis_stride
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"((2,3),4):((1@0,1@1),1@2)">, %[[CRD:.+]]: !cute.coord<"(1,_)">)
func.func @nested_scaled_basis_stride(
    %src: !cute.layout<"((2,3),4):((1@0,1@1),1@2)">,
    %crd: !cute.coord<"(1,_)">) -> !cute.layout<"((2,3)):((1@0,1@1))"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.layout<"((2,3),4):((1@0,1@1),1@2)">, !cute.coord<"(1,_)">
  // CHECK: return %[[R]] : !cute.layout<"((2,3)):((1@0,1@1))">
  %r = cute.dice(%src, %crd) : !cute.layout<"((2,3),4):((1@0,1@1),1@2)">, !cute.coord<"(1,_)">
  return %r : !cute.layout<"((2,3)):((1@0,1@1))">
}

// -----

// Composed affine with scaled-basis B stride.
// CHECK-LABEL: func.func @composed_affine_scaled_basis_b
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)">
// CHECK-SAME:   %[[CRD:.+]]: !cute.coord<"(1,_)">)
func.func @composed_affine_scaled_basis_b(
    %src: !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)">,
    %crd: !cute.coord<"(1,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2):(1@0)"> {
  // CHECK: %[[R:.+]] = cute.dice(%[[SRC]], %[[CRD]])
  // CHECK-SAME: !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)">
  // CHECK-SAME: !cute.coord<"(1,_)">
  // CHECK: return %[[R]] : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2):(1@0)">
  %r = cute.dice(%src, %crd)
         : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)">,
           !cute.coord<"(1,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2):(1@0)">
}
