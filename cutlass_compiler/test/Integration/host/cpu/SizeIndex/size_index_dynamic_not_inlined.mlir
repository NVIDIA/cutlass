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
// Not-inlined SizeIndex; runtime arith may survive -base-prepare across helper boundaries.

// CHECK: 77
// CHECK: 12
// CHECK: 7
// CHECK: 208
// crd2idx via helper: (2,3) on (?,8) x=4 → 14.
// CHECK: 14
// CHECK: (3,2)
// CHECK: (2,2)
// increment_coord wrap (via helper): runtime carry rolls (3,2) → (0,3).
// CHECK: (0,3)
// increment_coord hierarchical (via helper): (1,(2,0)) → (2,(2,0)).
// CHECK: (2,(2,0))
// CHECK: (5,8,1,1)
// CHECK: (1,1,6,8)
// CHECK: 15
// CHECK: (3,10)

//===----------------------------------------------------------------------===//
// Per-op helpers — opaque-arg boundaries.
//===----------------------------------------------------------------------===//

func.func @h_size(%a: i32) -> !cute.int_tuple<"?"> {
  %s = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,7)">
  %r = cute.size(%s) : (!cute.shape<"(?,7)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

func.func @h_cosize(%a: i32) -> !cute.int_tuple<"?"> {
  %s = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,3)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%s, %l_stride) : (!cute.shape<"(?,3)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,3):(1,?)">
  %r = cute.cosize(%l) : (!cute.layout<"(?,3):(1,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

func.func @h_layout_eval(%c0: i32, %c1: i32, %a: i32) -> !cute.int_tuple<"?"> {
  %crd = cute.make_coord (%c0, %c1) : (i32, i32) -> !cute.coord<"(?,?)">
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,8)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
  %r = cute.layout_eval(%crd, %l)
       : (!cute.coord<"(?,?)">, !cute.layout<"(?,8):(1,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

func.func @h_layout_eval_composed(%c: i32) -> !cute.int_tuple<"?"> {
  %crd = cute.make_coord (%c) : (i32) -> !cute.coord<"?">
  %cl = cute.static : !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">
  %r = cute.layout_eval(%crd, %cl)
       : (!cute.coord<"?">,
          !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
      -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

func.func @h_crd2idx(%c0: i32, %c1: i32, %a: i32) -> !cute.int_tuple<"?"> {
  %crd = cute.make_coord (%c0, %c1) : (i32, i32) -> !cute.coord<"(?,?)">
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,8)">
  %r = cute.crd2idx(%crd, %sh)
       : (!cute.coord<"(?,?)">, !cute.shape<"(?,8)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

func.func @h_idx2crd(%i: i32) -> !cute.coord<"(?,?)"> {
  %idx = cute.make_int_tuple (%i) : (i32) -> !cute.int_tuple<"?">
  %s = cute.static : !cute.shape<"(4,8)">
  %r = cute.idx2crd(%idx, %s)
       : (!cute.int_tuple<"?">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

func.func @h_increment_coord(%c0: i32, %c1: i32) -> !cute.coord<"(?,?)"> {
  %crd = cute.make_coord (%c0, %c1) : (i32, i32) -> !cute.coord<"(?,?)">
  %s = cute.static : !cute.shape<"(4,8)">
  %r = cute.increment_coord(%crd, %s)
       : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// Wrap variant — runtime carry rolls mode 0 over when its current
// value reaches the shape extent.
func.func @h_increment_coord_wrap(%c0: i32, %c1: i32) -> !cute.coord<"(?,?)"> {
  %crd = cute.make_coord (%c0, %c1) : (i32, i32) -> !cute.coord<"(?,?)">
  %s = cute.static : !cute.shape<"(4,8)">
  %r = cute.increment_coord(%crd, %s)
       : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// Hierarchical variant — rank-3 flat carry chain into nested coord
// profile.
func.func @h_increment_coord_hier(%c0: i32, %c1a: i32, %c1b: i32)
    -> !cute.coord<"(?,(?,?))"> {
  %crd = cute.make_coord (%c0, %c1a, %c1b)
       : (i32, i32, i32) -> !cute.coord<"(?,(?,?))">
  %s = cute.static : !cute.shape<"(4,(3,8))">
  %r = cute.increment_coord(%crd, %s)
       : (!cute.coord<"(?,(?,?))">, !cute.shape<"(4,(3,8))">) -> !cute.coord<"(?,(?,?))">
  return %r : !cute.coord<"(?,(?,?))">
}

func.func @h_append_to_rank(%a: i32) -> !cute.shape<"(?,8,1,1)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,8)">
  %e = cute.static : !cute.shape<"1">
  %r = cute.append_to_rank<4>(%sh, %e) : !cute.shape<"(?,8)">, !cute.shape<"1">
  return %r : !cute.shape<"(?,8,1,1)">
}

func.func @h_prepend_to_rank(%a: i32) -> !cute.shape<"(1,1,?,8)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,8)">
  %e = cute.static : !cute.shape<"1">
  %r = cute.prepend_to_rank<4>(%sh, %e) : !cute.shape<"(?,8)">, !cute.shape<"1">
  return %r : !cute.shape<"(1,1,?,8)">
}

func.func @h_tuple_product(%a0: i32, %a1: i32) -> !cute.int_tuple<"?"> {
  %t = cute.make_int_tuple (%a0, %a1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_product(%t) : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

func.func @h_tuple_product_each(%a0: i32, %a1: i32, %a2: i32)
    -> !cute.int_tuple<"(?,?)"> {
  %t = cute.make_int_tuple (%a0, %a1, %a2)
       : (i32, i32, i32) -> !cute.int_tuple<"(?,(?,?))">
  %r = cute.tuple_product_each(%t)
       : (!cute.int_tuple<"(?,(?,?))">) -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

//===----------------------------------------------------------------------===//
// Entry point — helper-call only.
//===----------------------------------------------------------------------===//

func.func @main() {
  %x11 = arith.constant 11 : i32
  %r1 = func.call @h_size(%x11) : (i32) -> !cute.int_tuple<"?">
  cute.print(%r1) : !cute.int_tuple<"?">

  %x4 = arith.constant 4 : i32
  %r2 = func.call @h_cosize(%x4) : (i32) -> !cute.int_tuple<"?">
  cute.print(%r2) : !cute.int_tuple<"?">

  %x3 = arith.constant 3 : i32
  %x1 = arith.constant 1 : i32
  %r3 = func.call @h_layout_eval(%x3, %x1, %x4) : (i32, i32, i32) -> !cute.int_tuple<"?">
  cute.print(%r3) : !cute.int_tuple<"?">

  %x6c = arith.constant 6 : i32
  %r3c = func.call @h_layout_eval_composed(%x6c) : (i32) -> !cute.int_tuple<"?">
  cute.print(%r3c) : !cute.int_tuple<"?">

  // crd2idx via helper: (2,3) on (?,8) with x=4 → 2 + 3*4 = 14.
  %x2p = arith.constant 2 : i32
  %x3p = arith.constant 3 : i32
  %r3p = func.call @h_crd2idx(%x2p, %x3p, %x4) : (i32, i32, i32) -> !cute.int_tuple<"?">
  cute.print(%r3p) : !cute.int_tuple<"?">

  %x_idx = arith.constant 11 : i32
  %r4 = func.call @h_idx2crd(%x_idx) : (i32) -> !cute.coord<"(?,?)">
  cute.print(%r4) : !cute.coord<"(?,?)">

  %x2 = arith.constant 2 : i32
  %r5 = func.call @h_increment_coord(%x1, %x2) : (i32, i32) -> !cute.coord<"(?,?)">
  cute.print(%r5) : !cute.coord<"(?,?)">

  // Wrap helper call: pass (3,2) so mode 0 hits the static extent 4
  // and rolls over at runtime → (0,3).
  %x_wrap = arith.constant 3 : i32
  %r5w = func.call @h_increment_coord_wrap(%x_wrap, %x2)
       : (i32, i32) -> !cute.coord<"(?,?)">
  cute.print(%r5w) : !cute.coord<"(?,?)">

  // Hierarchical helper call: pass (1, (2, 0)) flattened as 3 i32
  // args → runtime print (2,(2,0)).
  %x_hier = arith.constant 0 : i32
  %r5h = func.call @h_increment_coord_hier(%x1, %x2, %x_hier)
       : (i32, i32, i32) -> !cute.coord<"(?,(?,?))">
  cute.print(%r5h) : !cute.coord<"(?,(?,?))">

  %x5 = arith.constant 5 : i32
  %r6 = func.call @h_append_to_rank(%x5) : (i32) -> !cute.shape<"(?,8,1,1)">
  cute.print(%r6) : !cute.shape<"(?,8,1,1)">

  %x6 = arith.constant 6 : i32
  %r7 = func.call @h_prepend_to_rank(%x6) : (i32) -> !cute.shape<"(1,1,?,8)">
  cute.print(%r7) : !cute.shape<"(1,1,?,8)">

  %r8 = func.call @h_tuple_product(%x3, %x5) : (i32, i32) -> !cute.int_tuple<"?">
  cute.print(%r8) : !cute.int_tuple<"?">

  %r9 = func.call @h_tuple_product_each(%x3, %x2, %x5)
       : (i32, i32, i32) -> !cute.int_tuple<"(?,?)">
  cute.print(%r9) : !cute.int_tuple<"(?,?)">

  return
}
