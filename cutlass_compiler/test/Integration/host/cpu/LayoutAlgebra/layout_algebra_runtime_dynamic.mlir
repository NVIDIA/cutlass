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

// Runtime-dynamic LayoutAlgebra; leaves are opaque to the JIT, any arith is permitted.
// right_inverse and left_inverse require static input and are excluded.

// CHECK-COUNT-2: (5,4):(8,2)
// CHECK-COUNT-2: (4,5):(1,4)
// CHECK-COUNT-2: ((4,5)):((1,4))
// group_modes on composed input (swizzle-A + dyn B). Direct + helper.
// CHECK-COUNT-2: S<3,4,3> o 0 o ((4,5),6):((1,4),20)
// CHECK-COUNT-2: (8,32):(1,8)
// recast_layout on composed input — swizzle-A + dyn B upcast. Direct + helper.
// CHECK-COUNT-2: S<3,3,4> o 0 o (1,5,6):(1,1,5)
// CHECK-COUNT-2: (5):(4)
// CHECK-COUNT-2: (4):(1)
// flatten — nested dyn layout (3,(?,5)):(8,(1,4)) at runtime ?=3 → (3,3,5):(8,1,4). Direct + helper.
// CHECK-COUNT-2: (3,3,5):(8,1,4)
// coalesce — dyn middle blocks static groups on either side from merging.
// CHECK-COUNT-2: (20,7,6):(1,9,1)
// complement — rank-1 dyn-stride `(3):(?)` × static shape `12` with
// runtime stride (built from %base + 2) ⇒ result `(2,2):(1,6)`.
// CHECK-COUNT-2: (2,2):(1,6)

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

func.func @h_composition(%shape: i32, %stride: i32) -> !cute.layout<"(5,4):(?,?)"> {
  %sh = cute.make_shape (%shape) : (i32) -> !cute.shape<"?">
  %st = cute.make_stride (%stride) : (i32) -> !cute.stride<"?">
  %outer = cute.make_layout (%sh, %st)
        : (!cute.shape<"?">, !cute.stride<"?">) -> !cute.layout<"?:?">
  %inner = cute.static : !cute.layout<"(5,4):(4,1)">
  %r = cute.composition(%outer, %inner)
       : (!cute.layout<"?:?">, !cute.layout<"(5,4):(4,1)">) -> !cute.layout<"(5,4):(?,?)">
  return %r : !cute.layout<"(5,4):(?,?)">
}

func.func @h_coalesce(%a: i32) -> !cute.layout<"(?,5):(1,?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,5)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  %r = cute.coalesce(%l) : (!cute.layout<"(?,5):(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  return %r : !cute.layout<"(?,5):(1,?)">
}

func.func @h_group_modes(%a: i32) -> !cute.layout<"((?,5)):((1,?))"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,5)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  %r = cute.group_modes<0, 2>(%l)
       : (!cute.layout<"(?,5):(1,?)">) -> !cute.layout<"((?,5)):((1,?))">
  return %r : !cute.layout<"((?,5)):((1,?))">
}

func.func @h_group_modes_composed(%a: i32)
    -> !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)"> {
  %sw = cute.static : !cute.swizzle<"S<3,4,3>">
  %off = cute.static : !cute.int_tuple<"0">
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,5,6)">
  %c5_for_b_stride = arith.constant 5 : i32
  %b_stride_mul = arith.muli %a, %c5_for_b_stride : i32
  %b_stride = cute.make_stride (%a, %b_stride_mul) : (i32, i32) -> !cute.stride<"(1,?,?)">
  %b = cute.make_layout (%sh, %b_stride) : (!cute.shape<"(?,5,6)">, !cute.stride<"(1,?,?)">) -> !cute.layout<"(?,5,6):(1,?,?)">
  %co = cute.make_composed_layout(%sw, %off, %b)
       : (!cute.swizzle<"S<3,4,3>">, !cute.int_tuple<"0">,
          !cute.layout<"(?,5,6):(1,?,?)">)
      -> !cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,?)">
  %r = cute.group_modes<0, 2>(%co)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,?)">)
      -> !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">
  return %r : !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">
}

func.func @h_recast_layout(%a: i32) -> !cute.layout<"(8,?):(1,?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(32,?)">
  %st = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %st)
        : (!cute.shape<"(32,?)">, !cute.stride<"(1,?)">) -> !cute.layout<"(32,?):(1,?)">
  %r = cute.recast_layout<32, 8>(%l)
       : !cute.layout<"(32,?):(1,?)"> -> !cute.layout<"(8,?):(1,?)">
  return %r : !cute.layout<"(8,?):(1,?)">
}

func.func @h_recast_layout_composed(%a: i32)
    -> !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)"> {
  %sw = cute.static : !cute.swizzle<"S<3,5,4>">
  %off = cute.static : !cute.int_tuple<"0">
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,5,6)">
  %c5_for_b_stride = arith.constant 5 : i32
  %b_stride_mul = arith.muli %a, %c5_for_b_stride : i32
  %b_stride = cute.make_stride (%a, %b_stride_mul) : (i32, i32) -> !cute.stride<"(1,?,?)">
  %b = cute.make_layout (%sh, %b_stride) : (!cute.shape<"(?,5,6)">, !cute.stride<"(1,?,?)">) -> !cute.layout<"(?,5,6):(1,?,?)">
  %co = cute.make_composed_layout(%sw, %off, %b)
        : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"0">,
           !cute.layout<"(?,5,6):(1,?,?)">)
       -> !cute.composed_layout<"S<3,5,4> o 0 o (?,5,6):(1,?,?)">
  %r = cute.recast_layout<32, 8>(%co)
        : !cute.composed_layout<"S<3,5,4> o 0 o (?,5,6):(1,?,?)">
       -> !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">
  return %r : !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">
}

func.func @h_slice(%a: i32) -> !cute.layout<"(5):(?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,5)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  %crd = cute.static : !cute.coord<"(0,_)">
  %r = cute.slice(%l, %crd) : !cute.layout<"(?,5):(1,?)">, !cute.coord<"(0,_)">
  return %r : !cute.layout<"(5):(?)">
}

func.func @h_dice(%a: i32) -> !cute.layout<"(?):(1)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,5)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  %crd = cute.static : !cute.coord<"(1,_)">
  %r = cute.dice(%l, %crd) : !cute.layout<"(?,5):(1,?)">, !cute.coord<"(1,_)">
  return %r : !cute.layout<"(?):(1)">
}

func.func @h_flatten(%a: i32) -> !cute.layout<"(3,?,5):(8,1,4)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(3,(?,5))">
  %st = cute.static : !cute.stride<"(8,(1,4))">
  %l = cute.make_layout (%sh, %st)
        : (!cute.shape<"(3,(?,5))">, !cute.stride<"(8,(1,4))">)
       -> !cute.layout<"(3,(?,5)):(8,(1,4))">
  %r = cute.flatten(%l)
        : (!cute.layout<"(3,(?,5)):(8,(1,4))">) -> !cute.layout<"(3,?,5):(8,1,4)">
  return %r : !cute.layout<"(3,?,5):(8,1,4)">
}

func.func @h_coalesce_dyn_middle(%xmid: i32, %smid: i32)
    -> !cute.layout<"(20,?,6):(1,?,1)"> {
  %sh = cute.make_shape (%xmid) : (i32) -> !cute.shape<"(4,5,?,3,2)">
  %st = cute.make_stride (%smid) : (i32) -> !cute.stride<"(1,4,?,1,3)">
  %l = cute.make_layout (%sh, %st)
        : (!cute.shape<"(4,5,?,3,2)">, !cute.stride<"(1,4,?,1,3)">)
       -> !cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">
  %r = cute.coalesce(%l)
        : (!cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">) -> !cute.layout<"(20,?,6):(1,?,1)">
  return %r : !cute.layout<"(20,?,6):(1,?,1)">
}

func.func @h_complement(%stride: i32) -> !cute.layout<"(?,?):(1,?)"> {
  %st = cute.make_stride (%stride) : (i32) -> !cute.stride<"(?)">
  %sh = cute.static : !cute.shape<"(3)">
  %l = cute.make_layout (%sh, %st)
        : (!cute.shape<"(3)">, !cute.stride<"(?)">) -> !cute.layout<"(3):(?)">
  %co = cute.static : !cute.shape<"12">
  %r = cute.complement(%l, %co)
        : (!cute.layout<"(3):(?)">, !cute.shape<"12">)
       -> !cute.layout<"(?,?):(1,?)">
  return %r : !cute.layout<"(?,?):(1,?)">
}

//===----------------------------------------------------------------------===//
// Entry point.
//===----------------------------------------------------------------------===//

func.func @main() {
  %base = func.call @read_base() : () -> i32

  // composition
  %o20 = arith.constant 20 : i32
  %o2 = arith.constant 2 : i32
  %x20 = arith.addi %base, %o20 : i32
  %x2 = arith.addi %base, %o2 : i32
  %sh_o = cute.make_shape (%x20) : (i32) -> !cute.shape<"?">
  %st_o = cute.make_stride (%x2) : (i32) -> !cute.stride<"?">
  %outer = cute.make_layout (%sh_o, %st_o)
        : (!cute.shape<"?">, !cute.stride<"?">) -> !cute.layout<"?:?">
  %inner = cute.static : !cute.layout<"(5,4):(4,1)">
  %r1 = cute.composition(%outer, %inner)
       : (!cute.layout<"?:?">, !cute.layout<"(5,4):(4,1)">) -> !cute.layout<"(5,4):(?,?)">
  cute.print(%r1) : !cute.layout<"(5,4):(?,?)">
  %r1b = func.call @h_composition(%x20, %x2)
       : (i32, i32) -> !cute.layout<"(5,4):(?,?)">
  cute.print(%r1b) : !cute.layout<"(5,4):(?,?)">

  // 2D dyn layout for the structural ops
  %o4 = arith.constant 4 : i32
  %x4 = arith.addi %base, %o4 : i32
  %sh = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,5)">
  %l_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  // coalesce
  %r2 = cute.coalesce(%l) : (!cute.layout<"(?,5):(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  cute.print(%r2) : !cute.layout<"(?,5):(1,?)">
  %r2b = func.call @h_coalesce(%x4) : (i32) -> !cute.layout<"(?,5):(1,?)">
  cute.print(%r2b) : !cute.layout<"(?,5):(1,?)">

  // group_modes
  %r3 = cute.group_modes<0, 2>(%l)
       : (!cute.layout<"(?,5):(1,?)">) -> !cute.layout<"((?,5)):((1,?))">
  cute.print(%r3) : !cute.layout<"((?,5)):((1,?))">
  %r3b = func.call @h_group_modes(%x4) : (i32) -> !cute.layout<"((?,5)):((1,?))">
  cute.print(%r3b) : !cute.layout<"((?,5)):((1,?))">

  // group_modes on composed input — swizzle-A + dyn B. Direct + helper.
  %gm_co_sw = cute.static : !cute.swizzle<"S<3,4,3>">
  %gm_co_off = cute.static : !cute.int_tuple<"0">
  %gm_co_sh = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,5,6)">
  %c5_for_gm_co_b_stride = arith.constant 5 : i32
  %gm_co_b_stride_mul = arith.muli %x4, %c5_for_gm_co_b_stride : i32
  %gm_co_b_stride = cute.make_stride (%x4, %gm_co_b_stride_mul) : (i32, i32) -> !cute.stride<"(1,?,?)">
  %gm_co_b = cute.make_layout (%gm_co_sh, %gm_co_b_stride) : (!cute.shape<"(?,5,6)">, !cute.stride<"(1,?,?)">) -> !cute.layout<"(?,5,6):(1,?,?)">
  %gm_co_in = cute.make_composed_layout(%gm_co_sw, %gm_co_off, %gm_co_b)
       : (!cute.swizzle<"S<3,4,3>">, !cute.int_tuple<"0">,
          !cute.layout<"(?,5,6):(1,?,?)">)
      -> !cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,?)">
  %r3c = cute.group_modes<0, 2>(%gm_co_in)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,?)">)
      -> !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">
  cute.print(%r3c) : !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">
  %r3cb = func.call @h_group_modes_composed(%x4)
       : (i32) -> !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">
  cute.print(%r3cb) : !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">

  // recast_layout
  %o32 = arith.constant 32 : i32
  %x32 = arith.addi %base, %o32 : i32
  %sh32 = cute.make_shape (%x32) : (i32) -> !cute.shape<"(32,?)">
  %st32 = cute.make_stride (%x32) : (i32) -> !cute.stride<"(1,?)">
  %lr = cute.make_layout (%sh32, %st32)
        : (!cute.shape<"(32,?)">, !cute.stride<"(1,?)">) -> !cute.layout<"(32,?):(1,?)">
  %r4 = cute.recast_layout<32, 8>(%lr)
       : !cute.layout<"(32,?):(1,?)"> -> !cute.layout<"(8,?):(1,?)">
  cute.print(%r4) : !cute.layout<"(8,?):(1,?)">
  %r4b = func.call @h_recast_layout(%x32) : (i32) -> !cute.layout<"(8,?):(1,?)">
  cute.print(%r4b) : !cute.layout<"(8,?):(1,?)">

  // recast_layout on composed input — swizzle-A + dyn B. Direct + helper.
  %rl_co_sw = cute.static : !cute.swizzle<"S<3,5,4>">
  %rl_co_off = cute.static : !cute.int_tuple<"0">
  %rl_co_sh = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,5,6)">
  %c5_for_rl_co_b_stride = arith.constant 5 : i32
  %rl_co_b_stride_mul = arith.muli %x4, %c5_for_rl_co_b_stride : i32
  %rl_co_b_stride = cute.make_stride (%x4, %rl_co_b_stride_mul) : (i32, i32) -> !cute.stride<"(1,?,?)">
  %rl_co_b = cute.make_layout (%rl_co_sh, %rl_co_b_stride) : (!cute.shape<"(?,5,6)">, !cute.stride<"(1,?,?)">) -> !cute.layout<"(?,5,6):(1,?,?)">
  %rl_co_in = cute.make_composed_layout(%rl_co_sw, %rl_co_off, %rl_co_b)
        : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"0">,
           !cute.layout<"(?,5,6):(1,?,?)">)
       -> !cute.composed_layout<"S<3,5,4> o 0 o (?,5,6):(1,?,?)">
  %r4c = cute.recast_layout<32, 8>(%rl_co_in)
        : !cute.composed_layout<"S<3,5,4> o 0 o (?,5,6):(1,?,?)">
       -> !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">
  cute.print(%r4c) : !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">
  %r4cb = func.call @h_recast_layout_composed(%x4)
       : (i32) -> !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">
  cute.print(%r4cb) : !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">

  // slice
  %crd_s = cute.static : !cute.coord<"(0,_)">
  %r5 = cute.slice(%l, %crd_s) : !cute.layout<"(?,5):(1,?)">, !cute.coord<"(0,_)">
  cute.print(%r5) : !cute.layout<"(5):(?)">
  %r5b = func.call @h_slice(%x4) : (i32) -> !cute.layout<"(5):(?)">
  cute.print(%r5b) : !cute.layout<"(5):(?)">

  // dice
  %crd_d = cute.static : !cute.coord<"(1,_)">
  %r6 = cute.dice(%l, %crd_d) : !cute.layout<"(?,5):(1,?)">, !cute.coord<"(1,_)">
  cute.print(%r6) : !cute.layout<"(?):(1)">
  %r6b = func.call @h_dice(%x4) : (i32) -> !cute.layout<"(?):(1)">
  cute.print(%r6b) : !cute.layout<"(?):(1)">

  // flatten — nested dyn layout (3,(?,5)):(8,(1,4)) at runtime ?=3 →
  // (3,3,5):(8,1,4). Direct + helper paths.
  %o3 = arith.constant 3 : i32
  %x3 = arith.addi %base, %o3 : i32
  %fl_sh = cute.make_shape (%x3) : (i32) -> !cute.shape<"(3,(?,5))">
  %fl_st = cute.static : !cute.stride<"(8,(1,4))">
  %fl_in = cute.make_layout (%fl_sh, %fl_st)
        : (!cute.shape<"(3,(?,5))">, !cute.stride<"(8,(1,4))">)
       -> !cute.layout<"(3,(?,5)):(8,(1,4))">
  %r_fl = cute.flatten(%fl_in)
        : (!cute.layout<"(3,(?,5)):(8,(1,4))">) -> !cute.layout<"(3,?,5):(8,1,4)">
  cute.print(%r_fl) : !cute.layout<"(3,?,5):(8,1,4)">
  %r_flb = func.call @h_flatten(%x3) : (i32) -> !cute.layout<"(3,?,5):(8,1,4)">
  cute.print(%r_flb) : !cute.layout<"(3,?,5):(8,1,4)">

  // coalesce — dyn middle mode blocks merge. Direct and helper-call paths.
  %o7 = arith.constant 7 : i32
  %o9 = arith.constant 9 : i32
  %xmid = arith.addi %base, %o7 : i32
  %smid = arith.addi %base, %o9 : i32
  %sh_m = cute.make_shape (%xmid) : (i32) -> !cute.shape<"(4,5,?,3,2)">
  %st_m = cute.make_stride (%smid) : (i32) -> !cute.stride<"(1,4,?,1,3)">
  %lm = cute.make_layout (%sh_m, %st_m)
       : (!cute.shape<"(4,5,?,3,2)">, !cute.stride<"(1,4,?,1,3)">)
      -> !cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">
  %r9 = cute.coalesce(%lm)
       : (!cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">) -> !cute.layout<"(20,?,6):(1,?,1)">
  cute.print(%r9) : !cute.layout<"(20,?,6):(1,?,1)">
  %r9b = func.call @h_coalesce_dyn_middle(%xmid, %smid)
       : (i32, i32) -> !cute.layout<"(20,?,6):(1,?,1)">
  cute.print(%r9b) : !cute.layout<"(20,?,6):(1,?,1)">

  // complement — rank-1 dyn-stride input. Direct + helper paths.
  %o2c = arith.constant 2 : i32
  %cmp_st = arith.addi %base, %o2c : i32
  %cmp_st_v = cute.make_stride (%cmp_st) : (i32) -> !cute.stride<"(?)">
  %cmp_sh = cute.static : !cute.shape<"(3)">
  %cmp_in = cute.make_layout (%cmp_sh, %cmp_st_v)
        : (!cute.shape<"(3)">, !cute.stride<"(?)">) -> !cute.layout<"(3):(?)">
  %cmp_co = cute.static : !cute.shape<"12">
  %r10 = cute.complement(%cmp_in, %cmp_co)
       : (!cute.layout<"(3):(?)">, !cute.shape<"12">)
      -> !cute.layout<"(?,?):(1,?)">
  cute.print(%r10) : !cute.layout<"(?,?):(1,?)">
  %r10b = func.call @h_complement(%cmp_st)
       : (i32) -> !cute.layout<"(?,?):(1,?)">
  cute.print(%r10b) : !cute.layout<"(?,?):(1,?)">

  return
}
