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

// Tests `cute-to-base` lowering for `cute.make_tile`.

// -----

// Fully static tile — empty struct.
// CHECK-LABEL: func.func @tile_static
// CHECK-NOT:     cute.make_tile
// CHECK:         %[[P:.+]] = ub.poison
// CHECK:         return
func.func @tile_static() -> !cute.tile<"[(2,3):(1,2)]"> {
  %r = cute.make_tile () : () -> !cute.tile<"[(2,3):(1,2)]">
  return %r : !cute.tile<"[(2,3):(1,2)]">
}

// -----

// Underscore-only tile — empty struct.
// CHECK-LABEL: func.func @tile_underscore
// CHECK-NOT:     cute.make_tile
// CHECK:         %[[P:.+]] = ub.poison
// CHECK:         return
func.func @tile_underscore() -> !cute.tile<"[_]"> {
  %r = cute.make_tile () : () -> !cute.tile<"[_]">
  return %r : !cute.tile<"[_]">
}

// -----

// Single layout with 2 dynamic leaves (one shape `?`, one stride `?`).
// CHECK-LABEL: func.func @tile_one_layout_dyn
// CHECK-SAME:    (%[[M:.+]]: i32, %[[N:.+]]: i32)
// CHECK-NOT:     cute.make_tile
// CHECK:         %[[P:.+]] = ub.poison
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[M]], %[[P]][0
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[N]], %[[V0]][1
// CHECK:         return
func.func @tile_one_layout_dyn(%m: i32, %n: i32)
    -> !cute.tile<"[(?,3):(1,?)]"> {
  %r = cute.make_tile (%m, %n) : (i32, i32) -> !cute.tile<"[(?,3):(1,?)]">
  return %r : !cute.tile<"[(?,3):(1,?)]">
}

// -----

// Mixed tile slots: one dynamic layout + one underscore.
// CHECK-LABEL: func.func @tile_dyn_layout_plus_underscore
// CHECK-SAME:    (%[[M:.+]]: i32, %[[N:.+]]: i32)
// CHECK-NOT:     cute.make_tile
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[M]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[N]], %[[V0]][1]
// CHECK:         return
func.func @tile_dyn_layout_plus_underscore(%m: i32, %n: i32)
    -> !cute.tile<"[(?,3):(1,?);_]"> {
  %r = cute.make_tile (%m, %n)
         : (i32, i32) -> !cute.tile<"[(?,3):(1,?);_]">
  return %r : !cute.tile<"[(?,3):(1,?);_]">
}

// -----

// Tile of tiles — all inner layouts static.
// CHECK-LABEL: func.func @tile_of_tiles_static
// CHECK-NOT:     cute.make_tile
// CHECK:         %[[P:.+]] = ub.poison
// CHECK-SAME:      !llvm.struct<(struct<(struct<()>, struct<()>)>, struct<(struct<()>, struct<()>)>, struct<(struct<()>, struct<()>)>)>
// CHECK:         return
func.func @tile_of_tiles_static()
    -> !cute.tile<"[[(128,256):(256,1);_];[(2):(1);(4):(2)]]"> {
  %r = cute.make_tile()
         : () -> !cute.tile<"[[(128,256):(256,1);_];[(2):(1);(4):(2)]]">
  return %r : !cute.tile<"[[(128,256):(256,1);_];[(2):(1);(4):(2)]]">
}

// -----

// `!cute.int_tuple<"?">` operand fills a depth-0 dynamic slot.
// CHECK-LABEL: func.func @tile_int_tuple_operand
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK-NOT:     cute.make_tile
// CHECK:         %[[P:.+]] = ub.poison
// CHECK-SAME:      !llvm.struct<(struct<(i32, struct<()>)>, struct<(struct<()>, struct<()>)>)>
// CHECK:         %[[V:.+]] = llvm.insertvalue %[[A]], %[[P]][0, 0]
// CHECK:         return
func.func @tile_int_tuple_operand(%t: !cute.int_tuple<"?">)
    -> !cute.tile<"[?:1;3:1]"> {
  %r = cute.make_tile(%t)
         : (!cute.int_tuple<"?">) -> !cute.tile<"[?:1;3:1]">
  return %r : !cute.tile<"[?:1;3:1]">
}
