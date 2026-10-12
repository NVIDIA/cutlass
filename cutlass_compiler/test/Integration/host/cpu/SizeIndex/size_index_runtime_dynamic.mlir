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

// RUN: env CUTLASS_COMPILER_TEST_BASE=0 %cutlass-compiler-run-host %s | FileCheck %s

// Runtime-dynamic SizeIndex; leaves are opaque to the JIT, any arith is permitted.


// CHECK-COUNT-2: 77
// CHECK-COUNT-2: 12
// CHECK-COUNT-2: 7
// CHECK-COUNT-2: 208
// crd2idx (2,3) on (?,8) x=4 → 14. Direct + helper.
// CHECK-COUNT-2: 14
// CHECK-COUNT-2: (3,2)
// CHECK-COUNT-2: (2,2)
// increment_coord wrap (direct + helper): runtime carry rolls
// (3,2) → (0,3).
// CHECK-COUNT-2: (0,3)
// increment_coord hierarchical (direct + helper): (1,(2,0)) → (2,(2,0)).
// CHECK-COUNT-2: (2,(2,0))
// CHECK-COUNT-2: (5,8,1,1)
// CHECK-COUNT-2: (1,1,6,8)
// CHECK-COUNT-2: 15
// CHECK-COUNT-2: (3,10)

//===----------------------------------------------------------------------===//
// libc bridge: getenv/atoi for the runtime-dynamic baseline.
//===----------------------------------------------------------------------===//

llvm.func @getenv(!llvm.ptr) -> !llvm.ptr
llvm.func @atoi(!llvm.ptr) -> i32

llvm.mlir.global internal constant @cutlass_compiler_env_name("CUTLASS_COMPILER_TEST_BASE\00") {addr_space = 0 : i32}

func.func private @read_base() -> i32 {
  %name_addr = llvm.mlir.addressof @cutlass_compiler_env_name : !llvm.ptr
  %name = llvm.getelementptr %name_addr[0, 0]
        : (!llvm.ptr) -> !llvm.ptr, !llvm.array<15 x i8>
  %env = llvm.call @getenv(%name) : (!llvm.ptr) -> !llvm.ptr
  %v = llvm.call @atoi(%env) : (!llvm.ptr) -> i32
  return %v : i32
}

//===----------------------------------------------------------------------===//
// Per-op helpers.
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
// Entry point.
//===----------------------------------------------------------------------===//

func.func @main() {
  %base = func.call @read_base() : () -> i32

  // size: (?,7) → 77 with x=11
  %o11 = arith.constant 11 : i32
  %x11 = arith.addi %base, %o11 : i32
  %sh1 = cute.make_shape (%x11) : (i32) -> !cute.shape<"(?,7)">
  %r1 = cute.size(%sh1) : (!cute.shape<"(?,7)">) -> !cute.int_tuple<"?">
  cute.print(%r1) : !cute.int_tuple<"?">
  %r1b = func.call @h_size(%x11) : (i32) -> !cute.int_tuple<"?">
  cute.print(%r1b) : !cute.int_tuple<"?">

  // cosize: (?,3):(1,?) with x=4 → 12
  %o4 = arith.constant 4 : i32
  %x4 = arith.addi %base, %o4 : i32
  %sh2 = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,3)">
  %l2_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
  %l2 = cute.make_layout (%sh2, %l2_stride) : (!cute.shape<"(?,3)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,3):(1,?)">
  %r2 = cute.cosize(%l2) : (!cute.layout<"(?,3):(1,?)">) -> !cute.int_tuple<"?">
  cute.print(%r2) : !cute.int_tuple<"?">
  %r2b = func.call @h_cosize(%x4) : (i32) -> !cute.int_tuple<"?">
  cute.print(%r2b) : !cute.int_tuple<"?">

  // layout_eval: (3,1) on (?,8):(1,?) x=4 → 7
  %o3 = arith.constant 3 : i32
  %o1 = arith.constant 1 : i32
  %x3 = arith.addi %base, %o3 : i32
  %x1 = arith.addi %base, %o1 : i32
  %crd3 = cute.make_coord (%x3, %x1) : (i32, i32) -> !cute.coord<"(?,?)">
  %sh3 = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,8)">
  %ll3_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
  %ll3 = cute.make_layout (%sh3, %ll3_stride) : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
  %r3 = cute.layout_eval(%crd3, %ll3)
       : (!cute.coord<"(?,?)">, !cute.layout<"(?,8):(1,?)">) -> !cute.int_tuple<"?">
  cute.print(%r3) : !cute.int_tuple<"?">
  %r3b = func.call @h_layout_eval(%x3, %x1, %x4) : (i32, i32, i32) -> !cute.int_tuple<"?">
  cute.print(%r3b) : !cute.int_tuple<"?">

  // layout_eval over composed_layout: coord=6 (runtime-dynamic) on
  // `S<1,4,3> o 0 o (32):(32)` → 208.
  %o6c = arith.constant 6 : i32
  %x6c = arith.addi %base, %o6c : i32
  %crd3c = cute.make_coord (%x6c) : (i32) -> !cute.coord<"?">
  %cl3 = cute.static : !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">
  %r3c = cute.layout_eval(%crd3c, %cl3)
       : (!cute.coord<"?">,
          !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
      -> !cute.int_tuple<"?">
  cute.print(%r3c) : !cute.int_tuple<"?">
  %r3cb = func.call @h_layout_eval_composed(%x6c) : (i32) -> !cute.int_tuple<"?">
  cute.print(%r3cb) : !cute.int_tuple<"?">

  // crd2idx: (2,3) on (?,8) with x=4 → 2 + 3*4 = 14. Direct + helper.
  %o2p = arith.constant 2 : i32
  %o3p = arith.constant 3 : i32
  %x2p = arith.addi %base, %o2p : i32
  %x3p = arith.addi %base, %o3p : i32
  %crd3p = cute.make_coord (%x2p, %x3p) : (i32, i32) -> !cute.coord<"(?,?)">
  %sh3p = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,8)">
  %r3p = cute.crd2idx(%crd3p, %sh3p)
       : (!cute.coord<"(?,?)">, !cute.shape<"(?,8)">) -> !cute.int_tuple<"?">
  cute.print(%r3p) : !cute.int_tuple<"?">
  %r3pb = func.call @h_crd2idx(%x2p, %x3p, %x4) : (i32, i32, i32) -> !cute.int_tuple<"?">
  cute.print(%r3pb) : !cute.int_tuple<"?">

  // idx2crd: idx=11 on (4,8) → (3,2)
  %x_idx = arith.addi %base, %o11 : i32
  %idx4 = cute.make_int_tuple (%x_idx) : (i32) -> !cute.int_tuple<"?">
  %s4 = cute.static : !cute.shape<"(4,8)">
  %r4 = cute.idx2crd(%idx4, %s4)
       : (!cute.int_tuple<"?">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  cute.print(%r4) : !cute.coord<"(?,?)">
  %r4b = func.call @h_idx2crd(%x_idx) : (i32) -> !cute.coord<"(?,?)">
  cute.print(%r4b) : !cute.coord<"(?,?)">

  // increment_coord: (1,2) on (4,8) → (2,2)
  %o2 = arith.constant 2 : i32
  %x2 = arith.addi %base, %o2 : i32
  %crd5 = cute.make_coord (%x1, %x2) : (i32, i32) -> !cute.coord<"(?,?)">
  %s5 = cute.static : !cute.shape<"(4,8)">
  %r5 = cute.increment_coord(%crd5, %s5)
       : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  cute.print(%r5) : !cute.coord<"(?,?)">
  %r5b = func.call @h_increment_coord(%x1, %x2) : (i32, i32) -> !cute.coord<"(?,?)">
  cute.print(%r5b) : !cute.coord<"(?,?)">

  // Wrap (direct + helper): runtime values (3,2) on (4,8) → (0,3).
  // Reuses %x3 from above (= base + 3).
  %crd5w = cute.make_coord (%x3, %x2) : (i32, i32) -> !cute.coord<"(?,?)">
  %r5w = cute.increment_coord(%crd5w, %s5)
       : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  cute.print(%r5w) : !cute.coord<"(?,?)">
  %r5wb = func.call @h_increment_coord_wrap(%x3, %x2)
       : (i32, i32) -> !cute.coord<"(?,?)">
  cute.print(%r5wb) : !cute.coord<"(?,?)">

  // Hierarchical (direct + helper): (1,(2,0)) on (4,(3,8)) → (2,(2,0)).
  %o0c = arith.constant 0 : i32
  %x0c = arith.addi %base, %o0c : i32
  %crd5h = cute.make_coord (%x1, %x2, %x0c)
       : (i32, i32, i32) -> !cute.coord<"(?,(?,?))">
  %s5h = cute.static : !cute.shape<"(4,(3,8))">
  %r5h = cute.increment_coord(%crd5h, %s5h)
       : (!cute.coord<"(?,(?,?))">, !cute.shape<"(4,(3,8))">) -> !cute.coord<"(?,(?,?))">
  cute.print(%r5h) : !cute.coord<"(?,(?,?))">
  %r5hb = func.call @h_increment_coord_hier(%x1, %x2, %x0c)
       : (i32, i32, i32) -> !cute.coord<"(?,(?,?))">
  cute.print(%r5hb) : !cute.coord<"(?,(?,?))">

  // append_to_rank<4>: (?,8) x=5 → (5,8,1,1)
  %o5 = arith.constant 5 : i32
  %x5 = arith.addi %base, %o5 : i32
  %sh6 = cute.make_shape (%x5) : (i32) -> !cute.shape<"(?,8)">
  %e6 = cute.static : !cute.shape<"1">
  %r6 = cute.append_to_rank<4>(%sh6, %e6) : !cute.shape<"(?,8)">, !cute.shape<"1">
  cute.print(%r6) : !cute.shape<"(?,8,1,1)">
  %r6b = func.call @h_append_to_rank(%x5) : (i32) -> !cute.shape<"(?,8,1,1)">
  cute.print(%r6b) : !cute.shape<"(?,8,1,1)">

  // prepend_to_rank<4>: (?,8) x=6 → (1,1,6,8)
  %o6 = arith.constant 6 : i32
  %x6 = arith.addi %base, %o6 : i32
  %sh7 = cute.make_shape (%x6) : (i32) -> !cute.shape<"(?,8)">
  %r7 = cute.prepend_to_rank<4>(%sh7, %e6) : !cute.shape<"(?,8)">, !cute.shape<"1">
  cute.print(%r7) : !cute.shape<"(1,1,?,8)">
  %r7b = func.call @h_prepend_to_rank(%x6) : (i32) -> !cute.shape<"(1,1,?,8)">
  cute.print(%r7b) : !cute.shape<"(1,1,?,8)">

  // tuple_product: (3,5) → 15
  %t8 = cute.make_int_tuple (%x3, %x5) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r8 = cute.tuple_product(%t8) : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?">
  cute.print(%r8) : !cute.int_tuple<"?">
  %r8b = func.call @h_tuple_product(%x3, %x5) : (i32, i32) -> !cute.int_tuple<"?">
  cute.print(%r8b) : !cute.int_tuple<"?">

  // tuple_product_each: (3,(2,5)) → (3,10)
  %t9 = cute.make_int_tuple (%x3, %x2, %x5)
       : (i32, i32, i32) -> !cute.int_tuple<"(?,(?,?))">
  %r9 = cute.tuple_product_each(%t9)
       : (!cute.int_tuple<"(?,(?,?))">) -> !cute.int_tuple<"(?,?)">
  cute.print(%r9) : !cute.int_tuple<"(?,?)">
  %r9b = func.call @h_tuple_product_each(%x3, %x2, %x5)
       : (i32, i32, i32) -> !cute.int_tuple<"(?,?)">
  cute.print(%r9b) : !cute.int_tuple<"(?,?)">

  return
}
