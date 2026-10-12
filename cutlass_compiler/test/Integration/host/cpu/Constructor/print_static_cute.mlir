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

// RUN: %cutlass-compiler-run-host %s | FileCheck %s
//
// Each cute value type runs via direct inline and helper-call paths;
// values print twice consecutively (direct, then helper) → COUNT-2.

// CHECK-COUNT-2: (2,3)
// CHECK-COUNT-2: (1,4)
// CHECK-COUNT-2: (5,_,7)
// CHECK-COUNT-2: (1,(2,3),4)
// CHECK-COUNT-2: [(2,3):(1,2);(4,5):(1,4)]
// CHECK-COUNT-2: (8,4):(1,8)
// CHECK-COUNT-2: (2,3):(1@0,1@1)
// CHECK-COUNT-2: (4,5):(1,4) o 2 o (2,3):(1,2)
// CHECK-COUNT-2: S<3,5,4> o 0 o (8,4):(1,8)
// CHECK-COUNT-2: S<3,5,4>

//===----------------------------------------------------------------------===//
// Per-type helper builders (no inline print — main does the print after
// the call).
//===----------------------------------------------------------------------===//

func.func @make_shape_static() -> !cute.shape<"(2,3)"> {
  %s = cute.static : !cute.shape<"(2,3)">
  return %s : !cute.shape<"(2,3)">
}

func.func @make_stride_static() -> !cute.stride<"(1,4)"> {
  %st = cute.static : !cute.stride<"(1,4)">
  return %st : !cute.stride<"(1,4)">
}

func.func @make_coord_static() -> !cute.coord<"(5,_,7)"> {
  %c = cute.static : !cute.coord<"(5,_,7)">
  return %c : !cute.coord<"(5,_,7)">
}

func.func @make_int_tuple_static() -> !cute.int_tuple<"(1,(2,3),4)"> {
  %it = cute.static : !cute.int_tuple<"(1,(2,3),4)">
  return %it : !cute.int_tuple<"(1,(2,3),4)">
}

func.func @make_tile_static() -> !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]"> {
  %t = cute.static : !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">
  return %t : !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">
}

func.func @make_layout_static() -> !cute.layout<"(8,4):(1,8)"> {
  %l = cute.static : !cute.layout<"(8,4):(1,8)">
  return %l : !cute.layout<"(8,4):(1,8)">
}

func.func @make_layout_basis_static() -> !cute.layout<"(2,3):(1@0,1@1)"> {
  %lb = cute.static : !cute.layout<"(2,3):(1@0,1@1)">
  return %lb : !cute.layout<"(2,3):(1@0,1@1)">
}

func.func @make_clayout_layout_static()
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)"> {
  %cl = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  return %cl : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
}

func.func @make_clayout_swizzle_static()
    -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)"> {
  %csw = cute.static : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  return %csw : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
}

func.func @make_swizzle_static() -> !cute.swizzle<"S<3,5,4>"> {
  %sw = cute.static : !cute.swizzle<"S<3,5,4>">
  return %sw : !cute.swizzle<"S<3,5,4>">
}

//===----------------------------------------------------------------------===//
// Entry point: direct print, then helper-call + print, per type.
//===----------------------------------------------------------------------===//

func.func @main() {
  // !cute.shape — extent tuple.
  %s = cute.static : !cute.shape<"(2,3)">
  cute.print(%s) : !cute.shape<"(2,3)">
  %s2 = func.call @make_shape_static() : () -> !cute.shape<"(2,3)">
  cute.print(%s2) : !cute.shape<"(2,3)">

  // !cute.stride — stride tuple.
  %st = cute.static : !cute.stride<"(1,4)">
  cute.print(%st) : !cute.stride<"(1,4)">
  %st2 = func.call @make_stride_static() : () -> !cute.stride<"(1,4)">
  cute.print(%st2) : !cute.stride<"(1,4)">

  // !cute.coord — coordinate including underscore wildcards.
  %c = cute.static : !cute.coord<"(5,_,7)">
  cute.print(%c) : !cute.coord<"(5,_,7)">
  %c2 = func.call @make_coord_static() : () -> !cute.coord<"(5,_,7)">
  cute.print(%c2) : !cute.coord<"(5,_,7)">

  // !cute.int_tuple — nested integer tuple.
  %it = cute.static : !cute.int_tuple<"(1,(2,3),4)">
  cute.print(%it) : !cute.int_tuple<"(1,(2,3),4)">
  %it2 = func.call @make_int_tuple_static() : () -> !cute.int_tuple<"(1,(2,3),4)">
  cute.print(%it2) : !cute.int_tuple<"(1,(2,3),4)">

  // !cute.tile — sequence of layouts in brackets.
  %t = cute.static : !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">
  cute.print(%t) : !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">
  %t2 = func.call @make_tile_static() : () -> !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">
  cute.print(%t2) : !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">

  // !cute.layout — the canonical shape:stride pair.
  %l = cute.static : !cute.layout<"(8,4):(1,8)">
  cute.print(%l) : !cute.layout<"(8,4):(1,8)">
  %l2 = func.call @make_layout_static() : () -> !cute.layout<"(8,4):(1,8)">
  cute.print(%l2) : !cute.layout<"(8,4):(1,8)">

  // !cute.layout with scaled-basis strides.
  %lb = cute.static : !cute.layout<"(2,3):(1@0,1@1)">
  cute.print(%lb) : !cute.layout<"(2,3):(1@0,1@1)">
  %lb2 = func.call @make_layout_basis_static() : () -> !cute.layout<"(2,3):(1@0,1@1)">
  cute.print(%lb2) : !cute.layout<"(2,3):(1@0,1@1)">

  // !cute.composed_layout with a layout outer.
  %cl = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  cute.print(%cl) : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  %cl2 = func.call @make_clayout_layout_static()
      : () -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
  cute.print(%cl2) : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">

  // !cute.composed_layout with a swizzle outer.
  %csw = cute.static : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  cute.print(%csw) : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  %csw2 = func.call @make_clayout_swizzle_static()
      : () -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  cute.print(%csw2) : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">

  // !cute.swizzle — three-int compile-time bit-mask transform.
  %sw = cute.static : !cute.swizzle<"S<3,5,4>">
  cute.print(%sw) : !cute.swizzle<"S<3,5,4>">
  %sw2 = func.call @make_swizzle_static() : () -> !cute.swizzle<"S<3,5,4>">
  cute.print(%sw2) : !cute.swizzle<"S<3,5,4>">

  return
}
