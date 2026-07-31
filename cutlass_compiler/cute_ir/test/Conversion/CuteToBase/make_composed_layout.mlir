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

// Tests `cute-to-base` lowering for `cute.make_composed_layout`.

// -----

// Static inner + static outer, dynamic offset.
// CHECK-LABEL: func.func @composed_dyn_offset
// CHECK-SAME:    (%[[OFF:.+]]: i32)
// CHECK-NOT:     cute.make_composed_layout
// CHECK-DAG:     %[[INNER:.+]] = ub.poison : !llvm.struct<(struct<()>, struct<()>)>
// CHECK-DAG:     %[[OUTER:.+]] = ub.poison : !llvm.struct<(struct<()>, struct<()>)>
// CHECK:         %[[CL:.+]] = ub.poison
// CHECK-COUNT-3: llvm.insertvalue
// CHECK:         return
func.func @composed_dyn_offset(%off: i32)
    -> !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)"> {
  %a = cute.static : !cute.layout<"(4,5):(1,4)">
  %o = cute.make_int_tuple (%off) : (i32) -> !cute.int_tuple<"?">
  %b = cute.static : !cute.layout<"(2,3):(1,2)">
  %cl = cute.make_composed_layout (%a, %o, %b)
        : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"?">, !cute.layout<"(2,3):(1,2)">)
       -> !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
  return %cl : !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
}

// -----

// Fully static composed layout with swizzle inner and zero offset.
// CHECK-LABEL: func.func @composed_swizzle_static
// CHECK-NOT:     cute.make_composed_layout
// CHECK-COUNT-3: llvm.insertvalue
// CHECK:         return
func.func @composed_swizzle_static()
    -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)"> {
  %sw = cute.static : !cute.swizzle<"S<3,5,4>">
  %o = cute.static : !cute.int_tuple<"0">
  %b = cute.static : !cute.layout<"(8,4):(1,8)">
  %cl = cute.make_composed_layout (%sw, %o, %b)
        : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"0">, !cute.layout<"(8,4):(1,8)">)
       -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  return %cl : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
}

// -----

// Layout inner + dyn offset + dyn outer. Insertion order is outer (slot 0),
// offset (slot 1), inner (slot 2).
// CHECK-LABEL: func.func @composed_dyn_outer_layout
// CHECK-SAME:    (%[[A:.+]]: !llvm.struct<(i32, i32)>, %[[OFF:.+]]: i32, %[[B:.+]]: !llvm.struct<(struct<(i32, i32)>, i32)>)
// CHECK-NOT:     cute.make_composed_layout
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(struct<(struct<(i32, i32)>, i32)>, i32, struct<(i32, i32)>)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[B]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[OFF]], %[[V0]][1]
// CHECK:         %[[V2:.+]] = llvm.insertvalue %[[A]], %[[V1]][2]
// CHECK:         return %[[V2]]
func.func @composed_dyn_outer_layout(
    %a: !cute.layout<"(?,3):(1,?)">,
    %off: !cute.int_tuple<"?">,
    %b: !cute.layout<"(?,?):(1,?)">
) -> !cute.composed_layout<"(?,3):(1,?) o ? o (?,?):(1,?)"> {
  %cl = cute.make_composed_layout (%a, %off, %b)
        : (!cute.layout<"(?,3):(1,?)">, !cute.int_tuple<"?">, !cute.layout<"(?,?):(1,?)">)
       -> !cute.composed_layout<"(?,3):(1,?) o ? o (?,?):(1,?)">
  return %cl : !cute.composed_layout<"(?,3):(1,?) o ? o (?,?):(1,?)">
}

// -----

// Swizzle inner with no dyn leaves — its sub-struct is empty, but the
// pattern still emits 3 insertvalues.
// CHECK-LABEL: func.func @composed_dyn_outer_swizzle
// CHECK-SAME:    (%[[SW:.+]]: !llvm.struct<()>, %[[OFF:.+]]: i32, %[[B:.+]]: !llvm.struct<(struct<(i32, i32)>, i32)>)
// CHECK-NOT:     cute.make_composed_layout
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(struct<(struct<(i32, i32)>, i32)>, i32, struct<()>)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[B]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[OFF]], %[[V0]][1]
// CHECK:         %[[V2:.+]] = llvm.insertvalue %[[SW]], %[[V1]][2]
// CHECK:         return %[[V2]]
func.func @composed_dyn_outer_swizzle(
    %sw: !cute.swizzle<"S<3,5,4>">,
    %off: !cute.int_tuple<"?">,
    %b: !cute.layout<"(?,?):(1,?)">
) -> !cute.composed_layout<"S<3,5,4> o ? o (?,?):(1,?)"> {
  %cl = cute.make_composed_layout (%sw, %off, %b)
        : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"?">, !cute.layout<"(?,?):(1,?)">)
       -> !cute.composed_layout<"S<3,5,4> o ? o (?,?):(1,?)">
  return %cl : !cute.composed_layout<"S<3,5,4> o ? o (?,?):(1,?)">
}
