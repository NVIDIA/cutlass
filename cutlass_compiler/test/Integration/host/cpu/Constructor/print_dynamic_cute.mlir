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
// Dynamic Constructor, ops inlined in @main; static leaves fold through -base-prepare.

// Each cute value type runs via direct inline and helper-call paths;
// values print twice consecutively (direct, then helper) → COUNT-2.
// cute.swizzle is excluded — its parameters are always in the type signature.

// CHECK-COUNT-2: (5,7)
// CHECK-COUNT-2: (10,1)
// CHECK-COUNT-2: (12,_,15)
// CHECK-COUNT-2: (20,3,25)
// CHECK-COUNT-2: [(30,3):(1,35)]
// CHECK-COUNT-2: (40,4):(1,40)
// CHECK-COUNT-2: (45,8):(1,45)
// CHECK-COUNT-2: (4,5):(1,4) o 50 o (2,3):(1,2)
// CHECK-COUNT-2: S<3,5,4> o 60 o (8,4):(1,8)

//===----------------------------------------------------------------------===//
// Per-type helper builders. Each takes the dynamic leaves as raw
// integers, builds the cute value, and returns it. main() prints both
// the direct construction and the helper's return value.
//===----------------------------------------------------------------------===//

func.func @make_shape(%a: i32, %b: i32) -> !cute.shape<"(?,?)"> {
  %s = cute.make_shape (%a, %b) : (i32, i32) -> !cute.shape<"(?,?)">
  return %s : !cute.shape<"(?,?)">
}

func.func @make_stride(%a: i32) -> !cute.stride<"(?,1)"> {
  %st = cute.make_stride (%a) : (i32) -> !cute.stride<"(?,1)">
  return %st : !cute.stride<"(?,1)">
}

func.func @make_coord(%a: i32, %b: i32) -> !cute.coord<"(?,_,?)"> {
  %c = cute.make_coord (%a, %b) : (i32, i32) -> !cute.coord<"(?,_,?)">
  return %c : !cute.coord<"(?,_,?)">
}

func.func @make_int_tuple(%a: i32, %b: i32) -> !cute.int_tuple<"(?,3,?)"> {
  %it = cute.make_int_tuple (%a, %b)
        : (i32, i32) -> !cute.int_tuple<"(?,3,?)">
  return %it : !cute.int_tuple<"(?,3,?)">
}

func.func @make_tile(%a: i32, %b: i32) -> !cute.tile<"[(?,3):(1,?)]"> {
  %t = cute.make_tile (%a, %b) : (i32, i32) -> !cute.tile<"[(?,3):(1,?)]">
  return %t : !cute.tile<"[(?,3):(1,?)]">
}

func.func @make_layout(%a: i32) -> !cute.layout<"(?,4):(1,?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,4)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  return %l : !cute.layout<"(?,4):(1,?)">
}

func.func @make_layout_explicit(%a: i32) -> !cute.layout<"(?,8):(1,?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,8)">
  %st = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %st)
       : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">)
      -> !cute.layout<"(?,8):(1,?)">
  return %l : !cute.layout<"(?,8):(1,?)">
}

func.func @make_clayout_layout(%off: i32)
    -> !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)"> {
  %a = cute.static : !cute.layout<"(4,5):(1,4)">
  %off_t = cute.make_int_tuple (%off) : (i32) -> !cute.int_tuple<"?">
  %b = cute.static : !cute.layout<"(2,3):(1,2)">
  %cl = cute.make_composed_layout (%a, %off_t, %b)
        : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"?">,
           !cute.layout<"(2,3):(1,2)">)
       -> !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
  return %cl : !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
}

func.func @make_clayout_swizzle(%off: i32)
    -> !cute.composed_layout<"S<3,5,4> o ? o (8,4):(1,8)"> {
  %sw = cute.static : !cute.swizzle<"S<3,5,4>">
  %off_t = cute.make_int_tuple (%off) : (i32) -> !cute.int_tuple<"?">
  %lin = cute.static : !cute.layout<"(8,4):(1,8)">
  %csw = cute.make_composed_layout (%sw, %off_t, %lin)
        : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"?">,
           !cute.layout<"(8,4):(1,8)">)
       -> !cute.composed_layout<"S<3,5,4> o ? o (8,4):(1,8)">
  return %csw : !cute.composed_layout<"S<3,5,4> o ? o (8,4):(1,8)">
}

func.func @make_constrained_int(%a: i32)
    -> i32 {
  return %a : i32
}

//===----------------------------------------------------------------------===//
// Entry point: direct construction + print, then helper-call + print,
// per type.
//===----------------------------------------------------------------------===//

func.func @main() {
  // !cute.shape — both dimensions dynamic.
  %x5 = arith.constant 5 : i32
  %x7 = arith.constant 7 : i32
  %s = cute.make_shape (%x5, %x7) : (i32, i32) -> !cute.shape<"(?,?)">
  cute.print(%s) : !cute.shape<"(?,?)">
  %s2 = func.call @make_shape(%x5, %x7) : (i32, i32) -> !cute.shape<"(?,?)">
  cute.print(%s2) : !cute.shape<"(?,?)">

  // !cute.stride — first leaf dynamic, second leaf static.
  %x10 = arith.constant 10 : i32
  %st = cute.make_stride (%x10) : (i32) -> !cute.stride<"(?,1)">
  cute.print(%st) : !cute.stride<"(?,1)">
  %st2 = func.call @make_stride(%x10) : (i32) -> !cute.stride<"(?,1)">
  cute.print(%st2) : !cute.stride<"(?,1)">

  // !cute.coord — dynamic + underscore + dynamic.
  %x12 = arith.constant 12 : i32
  %x15 = arith.constant 15 : i32
  %c = cute.make_coord (%x12, %x15) : (i32, i32) -> !cute.coord<"(?,_,?)">
  cute.print(%c) : !cute.coord<"(?,_,?)">
  %c2 = func.call @make_coord(%x12, %x15) : (i32, i32) -> !cute.coord<"(?,_,?)">
  cute.print(%c2) : !cute.coord<"(?,_,?)">

  // !cute.int_tuple — dynamic + static + dynamic.
  %x20 = arith.constant 20 : i32
  %x25 = arith.constant 25 : i32
  %it = cute.make_int_tuple (%x20, %x25)
        : (i32, i32) -> !cute.int_tuple<"(?,3,?)">
  cute.print(%it) : !cute.int_tuple<"(?,3,?)">
  %it2 = func.call @make_int_tuple(%x20, %x25)
       : (i32, i32) -> !cute.int_tuple<"(?,3,?)">
  cute.print(%it2) : !cute.int_tuple<"(?,3,?)">

  // !cute.tile — single layout, one dyn shape leaf + one dyn stride leaf.
  %x30 = arith.constant 30 : i32
  %x35 = arith.constant 35 : i32
  %t = cute.make_tile (%x30, %x35) : (i32, i32)
       -> !cute.tile<"[(?,3):(1,?)]">
  cute.print(%t) : !cute.tile<"[(?,3):(1,?)]">
  %t2 = func.call @make_tile(%x30, %x35)
      : (i32, i32) -> !cute.tile<"[(?,3):(1,?)]">
  cute.print(%t2) : !cute.tile<"[(?,3):(1,?)]">

  // !cute.layout (1-operand form) — compact-col-major stride synthesized.
  %x40 = arith.constant 40 : i32
  %sh1 = cute.make_shape (%x40) : (i32) -> !cute.shape<"(?,4)">
  %l1_stride = cute.make_stride (%x40) : (i32) -> !cute.stride<"(1,?)">
  %l1 = cute.make_layout (%sh1, %l1_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  cute.print(%l1) : !cute.layout<"(?,4):(1,?)">
  %l1b = func.call @make_layout(%x40)
       : (i32) -> !cute.layout<"(?,4):(1,?)">
  cute.print(%l1b) : !cute.layout<"(?,4):(1,?)">

  // !cute.layout (2-operand form) — explicit shape + stride.
  %x45 = arith.constant 45 : i32
  %sh2 = cute.make_shape (%x45) : (i32) -> !cute.shape<"(?,8)">
  %st2_l = cute.make_stride (%x45) : (i32) -> !cute.stride<"(1,?)">
  %l2 = cute.make_layout (%sh2, %st2_l)
       : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">)
      -> !cute.layout<"(?,8):(1,?)">
  cute.print(%l2) : !cute.layout<"(?,8):(1,?)">
  %l2b = func.call @make_layout_explicit(%x45)
       : (i32) -> !cute.layout<"(?,8):(1,?)">
  cute.print(%l2b) : !cute.layout<"(?,8):(1,?)">

  // !cute.composed_layout — static layout outer, dyn offset.
  %a = cute.static : !cute.layout<"(4,5):(1,4)">
  %x50 = arith.constant 50 : i32
  %off1 = cute.make_int_tuple (%x50) : (i32) -> !cute.int_tuple<"?">
  %b = cute.static : !cute.layout<"(2,3):(1,2)">
  %cl = cute.make_composed_layout (%a, %off1, %b)
        : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"?">,
           !cute.layout<"(2,3):(1,2)">)
       -> !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
  cute.print(%cl) : !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
  %cl2 = func.call @make_clayout_layout(%x50)
       : (i32) -> !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
  cute.print(%cl2) : !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">

  // !cute.composed_layout — static swizzle outer, dyn offset.
  %sw = cute.static : !cute.swizzle<"S<3,5,4>">
  %x60 = arith.constant 60 : i32
  %off2 = cute.make_int_tuple (%x60) : (i32) -> !cute.int_tuple<"?">
  %lin = cute.static : !cute.layout<"(8,4):(1,8)">
  %csw = cute.make_composed_layout (%sw, %off2, %lin)
        : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"?">,
           !cute.layout<"(8,4):(1,8)">)
       -> !cute.composed_layout<"S<3,5,4> o ? o (8,4):(1,8)">
  cute.print(%csw) : !cute.composed_layout<"S<3,5,4> o ? o (8,4):(1,8)">
  %csw2 = func.call @make_clayout_swizzle(%x60)
       : (i32) -> !cute.composed_layout<"S<3,5,4> o ? o (8,4):(1,8)">
  cute.print(%csw2) : !cute.composed_layout<"S<3,5,4> o ? o (8,4):(1,8)">

  return
}
