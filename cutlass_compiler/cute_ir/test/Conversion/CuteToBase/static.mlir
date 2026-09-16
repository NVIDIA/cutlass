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

// Tests `cute-to-base` lowering for `cute.static`. Every leaf is encoded
// in the type, so the op lowers to `ub.poison` of the converted struct.

// -----

// Fully static int_tuple — empty struct.
// CHECK-LABEL: func.func @static_int_tuple
// CHECK-NOT:     cute.static
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return
func.func @static_int_tuple() -> !cute.int_tuple<"24"> {
  %r = cute.static : !cute.int_tuple<"24">
  return %r : !cute.int_tuple<"24">
}

// -----

// Static layout with all-static shape and stride.
// CHECK-LABEL: func.func @static_layout
// CHECK-NOT:     cute.static
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(struct<()>, struct<()>)>
// CHECK:         return
func.func @static_layout() -> !cute.layout<"(2,3,4):(1,2,6)"> {
  %r = cute.static : !cute.layout<"(2,3,4):(1,2,6)">
  return %r : !cute.layout<"(2,3,4):(1,2,6)">
}

// -----

// Static composed_layout — nested empty (shape, stride) sub-structs.
// CHECK-LABEL: func.func @static_composed_layout
// CHECK-NOT:     cute.static
// CHECK:         %[[P:.+]] = ub.poison
// CHECK-SAME:      !llvm.struct<(struct<(struct<()>, struct<()>)>, struct<()>, struct<(struct<()>, struct<()>)>)>
// CHECK:         return
func.func @static_composed_layout()
    -> !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)"> {
  %r = cute.static : !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 0 o (2,3):(1,2)">
}

// -----

// Static shape — empty struct.
// CHECK-LABEL: func.func @static_shape
// CHECK-NOT:     cute.static
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return
func.func @static_shape() -> !cute.shape<"(4,3)"> {
  %r = cute.static : !cute.shape<"(4,3)">
  return %r : !cute.shape<"(4,3)">
}

// -----

// Static stride.
// CHECK-LABEL: func.func @static_stride
// CHECK-NOT:     cute.static
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return
func.func @static_stride() -> !cute.stride<"(1,4)"> {
  %r = cute.static : !cute.stride<"(1,4)">
  return %r : !cute.stride<"(1,4)">
}

// -----

// Static coord with `_` wildcard slot — wildcard is compile-time.
// CHECK-LABEL: func.func @static_coord_underscore
// CHECK-NOT:     cute.static
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return
func.func @static_coord_underscore() -> !cute.coord<"(_,2)"> {
  %r = cute.static : !cute.coord<"(_,2)">
  return %r : !cute.coord<"(_,2)">
}

// -----

// All-underscore coord — zero runtime leaves.
// CHECK-LABEL: func.func @static_coord_only_underscore
// CHECK-NOT:     cute.static
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return
func.func @static_coord_only_underscore() -> !cute.coord<"_"> {
  %r = cute.static : !cute.coord<"_">
  return %r : !cute.coord<"_">
}

// -----

// CHECK-LABEL: func.func @static_coord_many_underscore_slots
// CHECK-NOT:     cute.static
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return
func.func @static_coord_many_underscore_slots()
    -> !cute.coord<"(_,_,0,_,_,_,_)"> {
  %r = cute.static : !cute.coord<"(_,_,0,_,_,_,_)">
  return %r : !cute.coord<"(_,_,0,_,_,_,_)">
}

// -----

// Static tile with a layout slot + an underscore slot.
// CHECK-LABEL: func.func @static_tile
// CHECK-NOT:     cute.static
// CHECK:         %[[P:.+]] = ub.poison
// CHECK-SAME:      !llvm.struct<(struct<()>, struct<()>)>
// CHECK:         return
func.func @static_tile() -> !cute.tile<"[(2,3):(1,2);_]"> {
  %r = cute.static : !cute.tile<"[(2,3):(1,2);_]">
  return %r : !cute.tile<"[(2,3):(1,2);_]">
}

// -----

// Static swizzle — empty struct.
// CHECK-LABEL: func.func @static_swizzle
// CHECK-NOT:     cute.static
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return
func.func @static_swizzle() -> !cute.swizzle<"S<3,5,4>"> {
  %r = cute.static : !cute.swizzle<"S<3,5,4>">
  return %r : !cute.swizzle<"S<3,5,4>">
}
