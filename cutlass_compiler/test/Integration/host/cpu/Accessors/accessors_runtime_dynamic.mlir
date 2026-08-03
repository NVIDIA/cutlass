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

// Runtime-dynamic Accessors; leaves are opaque, any arith op is permitted.
// Each op runs via direct inline and helper-call paths.
// Single-result ops: direct + helper print consecutively → COUNT-2.
// Multi-result ops: per-result prints interleave; each gets its own CHECK.
//
// CHECK-COUNT-2: (4,7)
// CHECK-COUNT-2: (1,8)
// CHECK-COUNT-2: 11:1
// CHECK: 17
// CHECK: 19
// CHECK: 23
// CHECK: 17
// CHECK: 19
// CHECK: 23
// CHECK: 29
// CHECK: 145
// CHECK: 29
// CHECK: 145
// CHECK-COUNT-2: (37,3):(1,37)
// CHECK-COUNT-2: (43,4):(1,43)
// CHECK-COUNT-2: 53
// CHECK-COUNT-2: (2,3):(1,2)
// CHECK-COUNT-2: (59):(1)
// CHECK-COUNT-2: (71,73)
// CHECK-COUNT-2: (89,97)
// CHECK-COUNT-2: (109@0,1@1)
// CHECK-COUNT-2: S<2,3,5>
// CHECK-COUNT-2: 113
// CHECK-COUNT-2: (127,131):(1,127)
// CHECK-COUNT-2: (149,137):(19043,1)
// CHECK-COUNT-2: ()
// CHECK-COUNT-2: (1,239)
// CHECK: (251,3):(1,257)
// CHECK: (5,269):(1,5)
// CHECK: (251,3):(1,257)
// CHECK: (5,269):(1,5)

//===----------------------------------------------------------------------===//
// libc bridge: getenv/atoi for the runtime-dynamic baseline + a tiny
// printf wrapper for raw i32 results from get_scalars.
//===----------------------------------------------------------------------===//

llvm.func @getenv(!llvm.ptr) -> !llvm.ptr
llvm.func @atoi(!llvm.ptr) -> i32
llvm.func @printf(!llvm.ptr, ...) -> i32

llvm.mlir.global internal constant @cutlass_compiler_env_name("CUTLASS_COMPILER_TEST_BASE\00") {addr_space = 0 : i32}
llvm.mlir.global internal constant @fmt_i32("%d\0A\00") {addr_space = 0 : i32}

func.func private @read_base() -> i32 {
  %name_addr = llvm.mlir.addressof @cutlass_compiler_env_name : !llvm.ptr
  %name = llvm.getelementptr %name_addr[0, 0]
        : (!llvm.ptr) -> !llvm.ptr, !llvm.array<15 x i8>
  %env = llvm.call @getenv(%name) : (!llvm.ptr) -> !llvm.ptr
  %v = llvm.call @atoi(%env) : (!llvm.ptr) -> i32
  return %v : i32
}

func.func @print_i32(%v: i32) {
  %p = llvm.mlir.addressof @fmt_i32 : !llvm.ptr
  %f = llvm.getelementptr %p[0, 0]
       : (!llvm.ptr) -> !llvm.ptr, !llvm.array<4 x i8>
  %r = llvm.call @printf(%f, %v) vararg(!llvm.func<i32 (ptr, ...)>)
       : (!llvm.ptr, i32) -> i32
  return
}

//===----------------------------------------------------------------------===//
// Per-op helpers: take the runtime-dynamic i32 leaves as arguments,
// build the dynamic cute input, run the accessor op, and return.
//===----------------------------------------------------------------------===//

func.func @h_get_shape(%a: i32) -> !cute.shape<"(?,7)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,7)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,7)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,7):(1,?)">
  %r = cute.get_shape(%l) : !cute.layout<"(?,7):(1,?)"> -> !cute.shape<"(?,7)">
  return %r : !cute.shape<"(?,7)">
}

func.func @h_get_stride(%a: i32) -> !cute.stride<"(1,?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,3)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,3)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,3):(1,?)">
  %r = cute.get_stride(%l) : !cute.layout<"(?,3):(1,?)"> -> !cute.stride<"(1,?)">
  return %r : !cute.stride<"(1,?)">
}

func.func @h_get(%a: i32) -> !cute.layout<"?:1"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,5)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  %r = cute.get<[0]> (%l) : !cute.layout<"(?,5):(1,?)"> -> !cute.layout<"?:1">
  return %r : !cute.layout<"?:1">
}

func.func @h_get_leaves(%a: i32, %b: i32)
    -> (!cute.shape<"?">, !cute.shape<"19">, !cute.shape<"?">) {
  %s = cute.make_shape (%a, %b) : (i32, i32) -> !cute.shape<"(?,(19,?))">
  %x, %y, %z = cute.get_leaves(%s) : !cute.shape<"(?,(19,?))">
  return %x, %y, %z : !cute.shape<"?">, !cute.shape<"19">, !cute.shape<"?">
}

func.func @h_get_scalars(%a: i32, %b: i32) -> (i32, i32) {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,5)">
  %st = cute.make_stride (%b) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %st)
       : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">)
      -> !cute.layout<"(?,5):(1,?)">
  %x, %y = cute.get_scalars<{only_dynamic}>(%l)
       : !cute.layout<"(?,5):(1,?)">
  return %x, %y : i32, i32
}

func.func @h_get_layouts_from_tile(%a: i32, %b: i32)
    -> !cute.layout<"(?,3):(1,?)"> {
  %t = cute.make_tile (%a, %b) : (i32, i32) -> !cute.tile<"[(?,3):(1,?)]">
  %l = cute.get_layouts_from_tile(%t) : !cute.tile<"[(?,3):(1,?)]">
  return %l : !cute.layout<"(?,3):(1,?)">
}

func.func @h_composed_get_inner(%a: i32)
    -> !cute.layout<"(?,4):(1,?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,4)">
  %inner_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %inner = cute.make_layout (%sh, %inner_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %off = cute.static : !cute.int_tuple<"53">
  %outer = cute.static : !cute.layout<"(2,3):(1,2)">
  %cl = cute.make_composed_layout (%inner, %off, %outer)
        : (!cute.layout<"(?,4):(1,?)">, !cute.int_tuple<"53">,
           !cute.layout<"(2,3):(1,2)">)
       -> !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
  %r = cute.composed_get_inner(%cl)
       : !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
      -> !cute.layout<"(?,4):(1,?)">
  return %r : !cute.layout<"(?,4):(1,?)">
}

func.func @h_composed_get_offset(%a: i32) -> !cute.int_tuple<"53"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,4)">
  %inner_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %inner = cute.make_layout (%sh, %inner_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %off = cute.static : !cute.int_tuple<"53">
  %outer = cute.static : !cute.layout<"(2,3):(1,2)">
  %cl = cute.make_composed_layout (%inner, %off, %outer)
        : (!cute.layout<"(?,4):(1,?)">, !cute.int_tuple<"53">,
           !cute.layout<"(2,3):(1,2)">)
       -> !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
  %r = cute.composed_get_offset(%cl)
       : !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
      -> !cute.int_tuple<"53">
  return %r : !cute.int_tuple<"53">
}

func.func @h_composed_get_outer(%a: i32) -> !cute.layout<"(2,3):(1,2)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,4)">
  %inner_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %inner = cute.make_layout (%sh, %inner_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %off = cute.static : !cute.int_tuple<"53">
  %outer = cute.static : !cute.layout<"(2,3):(1,2)">
  %cl = cute.make_composed_layout (%inner, %off, %outer)
        : (!cute.layout<"(?,4):(1,?)">, !cute.int_tuple<"53">,
           !cute.layout<"(2,3):(1,2)">)
       -> !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
  %r = cute.composed_get_outer(%cl)
       : !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
      -> !cute.layout<"(2,3):(1,2)">
  return %r : !cute.layout<"(2,3):(1,2)">
}

func.func @h_select(%a: i32) -> !cute.layout<"(?):(1)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,5)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  %r = cute.select<[0]> (%l) : !cute.layout<"(?,5):(1,?)">
                            -> !cute.layout<"(?):(1)">
  return %r : !cute.layout<"(?):(1)">
}

// select<[2, 0]> — permutation on a fully-dyn rank-3 layout.
func.func @h_select_permute(%a: i32, %b: i32, %c: i32)
    -> !cute.layout<"(?,?):(?,1)"> {
  %sh = cute.make_shape(%a, %b, %c)
      : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
  %l_stride_mul = arith.muli %a, %b : i32
  %l_stride = cute.make_stride (%a, %l_stride_mul) : (i32, i32) -> !cute.stride<"(1,?,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,?,?)">, !cute.stride<"(1,?,?)">) -> !cute.layout<"(?,?,?):(1,?,?)">
  %r = cute.select<[2, 0]> (%l)
     : !cute.layout<"(?,?,?):(1,?,?)"> -> !cute.layout<"(?,?):(?,1)">
  return %r : !cute.layout<"(?,?):(?,1)">
}

// select<[]> on a dyn shape — empty mode → rank-0 result.
func.func @h_select_empty(%a: i32, %b: i32) -> !cute.shape<"()"> {
  %sh = cute.make_shape(%a, %b) : (i32, i32) -> !cute.shape<"(?,?)">
  %r = cute.select<[]> (%sh) : !cute.shape<"(?,?)"> -> !cute.shape<"()">
  return %r : !cute.shape<"()">
}

// to_int_tuple from a stride with a dyn leaf.
func.func @h_to_int_tuple_stride_dyn(%a: i32) -> !cute.int_tuple<"(1,?)"> {
  %st = cute.make_stride(%a) : (i32) -> !cute.stride<"(1,?)">
  %r = cute.to_int_tuple(%st)
       : !cute.stride<"(1,?)"> -> !cute.int_tuple<"(1,?)">
  return %r : !cute.int_tuple<"(1,?)">
}

// get_layouts_from_tile on a multi-layout runtime-dyn tile.
func.func @h_get_layouts_from_tile_multi_dyn(%a: i32, %b: i32, %c: i32)
    -> (!cute.layout<"(?,3):(1,?)">, !cute.layout<"(5,?):(1,5)">) {
  %t = cute.make_tile(%a, %b, %c)
       : (i32, i32, i32) -> !cute.tile<"[(?,3):(1,?);(5,?):(1,5)]">
  %l0, %l1 = cute.get_layouts_from_tile(%t)
           : !cute.tile<"[(?,3):(1,?);(5,?):(1,5)]">
  return %l0, %l1
      : !cute.layout<"(?,3):(1,?)">, !cute.layout<"(5,?):(1,5)">
}

func.func @h_to_int_tuple(%a: i32) -> !cute.int_tuple<"(?,73)"> {
  %s = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,73)">
  %r = cute.to_int_tuple(%s) : !cute.shape<"(?,73)"> -> !cute.int_tuple<"(?,73)">
  return %r : !cute.int_tuple<"(?,73)">
}

// get_shape on a composed_layout with a dyn outer B shape leaf.
func.func @h_get_shape_composed(%a: i32, %b: i32) -> !cute.shape<"(?,97)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,97)">
  %st = cute.make_stride (%b) : (i32) -> !cute.stride<"(1,?)">
  %outer = cute.make_layout (%sh, %st)
        : (!cute.shape<"(?,97)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,97):(1,?)">
  %sw = cute.static : !cute.swizzle<"S<3,4,3>">
  %off = cute.static : !cute.int_tuple<"0">
  %cl = cute.make_composed_layout (%sw, %off, %outer)
        : (!cute.swizzle<"S<3,4,3>">, !cute.int_tuple<"0">, !cute.layout<"(?,97):(1,?)">)
       -> !cute.composed_layout<"S<3,4,3> o 0 o (?,97):(1,?)">
  %r = cute.get_shape(%cl)
       : !cute.composed_layout<"S<3,4,3> o 0 o (?,97):(1,?)"> -> !cute.shape<"(?,97)">
  return %r : !cute.shape<"(?,97)">
}

// get_stride on a layout with a dyn-scale basis stride.
func.func @h_get_stride_basis(%a: i32, %s: i32) -> !cute.stride<"(?@0,1@1)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,103)">
  %st = cute.make_stride (%s) : (i32) -> !cute.stride<"(?@0,1@1)">
  %l = cute.make_layout (%sh, %st)
       : (!cute.shape<"(?,103)">, !cute.stride<"(?@0,1@1)">)
      -> !cute.layout<"(?,103):(?@0,1@1)">
  %r = cute.get_stride(%l)
       : !cute.layout<"(?,103):(?@0,1@1)"> -> !cute.stride<"(?@0,1@1)">
  return %r : !cute.stride<"(?@0,1@1)">
}

// composed_get_inner on a swizzle-A composed — fully static; no
// dyn leaves to pass.
func.func @h_composed_get_inner_swizzle() -> !cute.swizzle<"S<2,3,5>"> {
  %cl = cute.static : !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)">
  %r = cute.composed_get_inner(%cl)
       : !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)"> -> !cute.swizzle<"S<2,3,5>">
  return %r : !cute.swizzle<"S<2,3,5>">
}

// composed_get_offset on a composed with a dyn scalar offset.
func.func @h_composed_get_offset_dyn(%off_leaf: i32) -> !cute.int_tuple<"?"> {
  %inner = cute.static : !cute.layout<"(2,3):(1,2)">
  %off = cute.make_int_tuple(%off_leaf) : (i32) -> !cute.int_tuple<"?">
  %outer = cute.static : !cute.layout<"(4,5):(1,4)">
  %cl = cute.make_composed_layout(%inner, %off, %outer)
       : (!cute.layout<"(2,3):(1,2)">, !cute.int_tuple<"?">, !cute.layout<"(4,5):(1,4)">)
       -> !cute.composed_layout<"(2,3):(1,2) o ? o (4,5):(1,4)">
  %r = cute.composed_get_offset(%cl)
       : !cute.composed_layout<"(2,3):(1,2) o ? o (4,5):(1,4)"> -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// composed_get_outer on a composed with a dyn outer B.
func.func @h_composed_get_outer_dyn(%a: i32, %b: i32) -> !cute.layout<"(?,131):(1,?)"> {
  %inner = cute.static : !cute.layout<"(2,3):(1,2)">
  %off = cute.static : !cute.int_tuple<"0">
  %sh = cute.make_shape(%a) : (i32) -> !cute.shape<"(?,131)">
  %st = cute.make_stride(%b) : (i32) -> !cute.stride<"(1,?)">
  %outer = cute.make_layout(%sh, %st)
        : (!cute.shape<"(?,131)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,131):(1,?)">
  %cl = cute.make_composed_layout(%inner, %off, %outer)
       : (!cute.layout<"(2,3):(1,2)">, !cute.int_tuple<"0">, !cute.layout<"(?,131):(1,?)">)
       -> !cute.composed_layout<"(2,3):(1,2) o 0 o (?,131):(1,?)">
  %r = cute.composed_get_outer(%cl)
       : !cute.composed_layout<"(2,3):(1,2) o 0 o (?,131):(1,?)"> -> !cute.layout<"(?,131):(1,?)">
  return %r : !cute.layout<"(?,131):(1,?)">
}

//===----------------------------------------------------------------------===//
// Entry point: pull the runtime base once, derive each leaf as
// `base + offset`, then run direct + helper-call paths per op.
//===----------------------------------------------------------------------===//

func.func @main() {
  %base = func.call @read_base() : () -> i32

  // get_shape — extract shape from a layout with a runtime-dyn shape leaf.
  %o4 = arith.constant 4 : i32
  %x4 = arith.addi %base, %o4 : i32
  %sh_in1 = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,7)">
  %l1_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
  %l1 = cute.make_layout (%sh_in1, %l1_stride) : (!cute.shape<"(?,7)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,7):(1,?)">
  %sh1 = cute.get_shape(%l1) : !cute.layout<"(?,7):(1,?)"> -> !cute.shape<"(?,7)">
  cute.print(%sh1) : !cute.shape<"(?,7)">
  %sh1b = func.call @h_get_shape(%x4) : (i32) -> !cute.shape<"(?,7)">
  cute.print(%sh1b) : !cute.shape<"(?,7)">

  // get_stride — extract stride from a runtime-dyn layout.
  %o8 = arith.constant 8 : i32
  %x8 = arith.addi %base, %o8 : i32
  %sh_in2 = cute.make_shape (%x8) : (i32) -> !cute.shape<"(?,3)">
  %l2_stride = cute.make_stride (%x8) : (i32) -> !cute.stride<"(1,?)">
  %l2 = cute.make_layout (%sh_in2, %l2_stride) : (!cute.shape<"(?,3)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,3):(1,?)">
  %st1 = cute.get_stride(%l2) : !cute.layout<"(?,3):(1,?)"> -> !cute.stride<"(1,?)">
  cute.print(%st1) : !cute.stride<"(1,?)">
  %st1b = func.call @h_get_stride(%x8) : (i32) -> !cute.stride<"(1,?)">
  cute.print(%st1b) : !cute.stride<"(1,?)">

  // get<[0]> — pick mode 0 from a runtime-dyn layout.
  %o11 = arith.constant 11 : i32
  %x11 = arith.addi %base, %o11 : i32
  %sh_in3 = cute.make_shape (%x11) : (i32) -> !cute.shape<"(?,5)">
  %l3_stride = cute.make_stride (%x11) : (i32) -> !cute.stride<"(1,?)">
  %l3 = cute.make_layout (%sh_in3, %l3_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  %g1 = cute.get<[0]> (%l3) : !cute.layout<"(?,5):(1,?)"> -> !cute.layout<"?:1">
  cute.print(%g1) : !cute.layout<"?:1">
  %g1b = func.call @h_get(%x11) : (i32) -> !cute.layout<"?:1">
  cute.print(%g1b) : !cute.layout<"?:1">

  // get_leaves — flatten a nested shape with two runtime-dyn leaves.
  %o17 = arith.constant 17 : i32
  %o23 = arith.constant 23 : i32
  %x17 = arith.addi %base, %o17 : i32
  %x23 = arith.addi %base, %o23 : i32
  %s_lv = cute.make_shape (%x17, %x23)
        : (i32, i32) -> !cute.shape<"(?,(19,?))">
  %a1, %b1, %c1 = cute.get_leaves(%s_lv) : !cute.shape<"(?,(19,?))">
  cute.print(%a1) : !cute.shape<"?">
  cute.print(%b1) : !cute.shape<"19">
  cute.print(%c1) : !cute.shape<"?">
  %a2, %b2, %c2 = func.call @h_get_leaves(%x17, %x23)
        : (i32, i32)
       -> (!cute.shape<"?">, !cute.shape<"19">, !cute.shape<"?">)
  cute.print(%a2) : !cute.shape<"?">
  cute.print(%b2) : !cute.shape<"19">
  cute.print(%c2) : !cute.shape<"?">

  // get_scalars<{only_dynamic}> — extract runtime-dyn i32 leaves.
  %o29 = arith.constant 29 : i32
  %o145 = arith.constant 145 : i32
  %x29 = arith.addi %base, %o29 : i32
  %x145 = arith.addi %base, %o145 : i32
  %sh_in5 = cute.make_shape (%x29) : (i32) -> !cute.shape<"(?,5)">
  %st_in5 = cute.make_stride (%x145) : (i32) -> !cute.stride<"(1,?)">
  %l5 = cute.make_layout (%sh_in5, %st_in5)
        : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">)
       -> !cute.layout<"(?,5):(1,?)">
  %s1, %s2 = cute.get_scalars<{only_dynamic}>(%l5)
        : !cute.layout<"(?,5):(1,?)">
  func.call @print_i32(%s1) : (i32) -> ()
  func.call @print_i32(%s2) : (i32) -> ()
  %s1b, %s2b = func.call @h_get_scalars(%x29, %x145) : (i32, i32) -> (i32, i32)
  func.call @print_i32(%s1b) : (i32) -> ()
  func.call @print_i32(%s2b) : (i32) -> ()

  // get_layouts_from_tile — single-layout runtime-dyn tile (both ?s
  // set to the same value so the printed layout is `(37,3):(1,37)`).
  %o37 = arith.constant 37 : i32
  %x37 = arith.addi %base, %o37 : i32
  %t = cute.make_tile (%x37, %x37) : (i32, i32) -> !cute.tile<"[(?,3):(1,?)]">
  %lt = cute.get_layouts_from_tile(%t) : !cute.tile<"[(?,3):(1,?)]">
  cute.print(%lt) : !cute.layout<"(?,3):(1,?)">
  %ltb = func.call @h_get_layouts_from_tile(%x37, %x37)
       : (i32, i32) -> !cute.layout<"(?,3):(1,?)">
  cute.print(%ltb) : !cute.layout<"(?,3):(1,?)">

  // composed_get_inner — extract the inner layout (runtime-dyn shape).
  %o43 = arith.constant 43 : i32
  %x43 = arith.addi %base, %o43 : i32
  %sh_in7 = cute.make_shape (%x43) : (i32) -> !cute.shape<"(?,4)">
  %inner_stride = cute.make_stride (%x43) : (i32) -> !cute.stride<"(1,?)">
  %inner = cute.make_layout (%sh_in7, %inner_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
  %off_st = cute.static : !cute.int_tuple<"53">
  %outer_st = cute.static : !cute.layout<"(2,3):(1,2)">
  %cl = cute.make_composed_layout (%inner, %off_st, %outer_st)
        : (!cute.layout<"(?,4):(1,?)">, !cute.int_tuple<"53">,
           !cute.layout<"(2,3):(1,2)">)
       -> !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">

  %in1 = cute.composed_get_inner(%cl)
        : !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
       -> !cute.layout<"(?,4):(1,?)">
  cute.print(%in1) : !cute.layout<"(?,4):(1,?)">
  %in1b = func.call @h_composed_get_inner(%x43)
        : (i32) -> !cute.layout<"(?,4):(1,?)">
  cute.print(%in1b) : !cute.layout<"(?,4):(1,?)">

  // composed_get_offset — extract the (static) offset.
  %off1 = cute.composed_get_offset(%cl)
        : !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
       -> !cute.int_tuple<"53">
  cute.print(%off1) : !cute.int_tuple<"53">
  %off1b = func.call @h_composed_get_offset(%x43) : (i32) -> !cute.int_tuple<"53">
  cute.print(%off1b) : !cute.int_tuple<"53">

  // composed_get_outer — extract the (static) outer layout.
  %out1 = cute.composed_get_outer(%cl)
        : !cute.composed_layout<"(?,4):(1,?) o 53 o (2,3):(1,2)">
       -> !cute.layout<"(2,3):(1,2)">
  cute.print(%out1) : !cute.layout<"(2,3):(1,2)">
  %out1b = func.call @h_composed_get_outer(%x43) : (i32) -> !cute.layout<"(2,3):(1,2)">
  cute.print(%out1b) : !cute.layout<"(2,3):(1,2)">

  // select<[0]> — pick mode 0 from a runtime-dyn layout.
  %o59 = arith.constant 59 : i32
  %x59 = arith.addi %base, %o59 : i32
  %sh_in10 = cute.make_shape (%x59) : (i32) -> !cute.shape<"(?,5)">
  %l10_stride = cute.make_stride (%x59) : (i32) -> !cute.stride<"(1,?)">
  %l10 = cute.make_layout (%sh_in10, %l10_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  %sel1 = cute.select<[0]> (%l10) : !cute.layout<"(?,5):(1,?)">
                                  -> !cute.layout<"(?):(1)">
  cute.print(%sel1) : !cute.layout<"(?):(1)">
  %sel1b = func.call @h_select(%x59) : (i32) -> !cute.layout<"(?):(1)">
  cute.print(%sel1b) : !cute.layout<"(?):(1)">

  // to_int_tuple — strip the shape wrapper.
  %o71 = arith.constant 71 : i32
  %x71 = arith.addi %base, %o71 : i32
  %s_it = cute.make_shape (%x71) : (i32) -> !cute.shape<"(?,73)">
  %it1 = cute.to_int_tuple(%s_it) : !cute.shape<"(?,73)"> -> !cute.int_tuple<"(?,73)">
  cute.print(%it1) : !cute.int_tuple<"(?,73)">
  %it1b = func.call @h_to_int_tuple(%x71) : (i32) -> !cute.int_tuple<"(?,73)">
  cute.print(%it1b) : !cute.int_tuple<"(?,73)">

  // get_shape on composed_layout — shape_leaf=89, stride_leaf=89.
  %o89 = arith.constant 89 : i32
  %x89 = arith.addi %base, %o89 : i32
  %sh_cb = cute.make_shape (%x89) : (i32) -> !cute.shape<"(?,97)">
  %st_cb = cute.make_stride (%x89) : (i32) -> !cute.stride<"(1,?)">
  %outer_cb = cute.make_layout (%sh_cb, %st_cb)
        : (!cute.shape<"(?,97)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,97):(1,?)">
  %sw_cb = cute.static : !cute.swizzle<"S<3,4,3>">
  %off_cb = cute.static : !cute.int_tuple<"0">
  %cl_cb = cute.make_composed_layout (%sw_cb, %off_cb, %outer_cb)
        : (!cute.swizzle<"S<3,4,3>">, !cute.int_tuple<"0">, !cute.layout<"(?,97):(1,?)">)
       -> !cute.composed_layout<"S<3,4,3> o 0 o (?,97):(1,?)">
  %csh1 = cute.get_shape(%cl_cb)
        : !cute.composed_layout<"S<3,4,3> o 0 o (?,97):(1,?)"> -> !cute.shape<"(?,97)">
  cute.print(%csh1) : !cute.shape<"(?,97)">
  %csh1b = func.call @h_get_shape_composed(%x89, %x89)
        : (i32, i32) -> !cute.shape<"(?,97)">
  cute.print(%csh1b) : !cute.shape<"(?,97)">

  // get_stride on layout with dyn-scale basis stride — shape_leaf=101,
  // scale_leaf=109.
  %o101 = arith.constant 101 : i32
  %x101 = arith.addi %base, %o101 : i32
  %o109 = arith.constant 109 : i32
  %x109 = arith.addi %base, %o109 : i32
  %sh_b = cute.make_shape (%x101) : (i32) -> !cute.shape<"(?,103)">
  %st_b = cute.make_stride (%x109) : (i32) -> !cute.stride<"(?@0,1@1)">
  %l_b = cute.make_layout (%sh_b, %st_b)
        : (!cute.shape<"(?,103)">, !cute.stride<"(?@0,1@1)">)
       -> !cute.layout<"(?,103):(?@0,1@1)">
  %bst1 = cute.get_stride(%l_b)
        : !cute.layout<"(?,103):(?@0,1@1)"> -> !cute.stride<"(?@0,1@1)">
  cute.print(%bst1) : !cute.stride<"(?@0,1@1)">
  %bst1b = func.call @h_get_stride_basis(%x101, %x109)
        : (i32, i32) -> !cute.stride<"(?@0,1@1)">
  cute.print(%bst1b) : !cute.stride<"(?@0,1@1)">

  // composed_get_inner on swizzle-A — fully static, %base unused.
  %cl_sw = cute.static : !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)">
  %sw1 = cute.composed_get_inner(%cl_sw)
        : !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)"> -> !cute.swizzle<"S<2,3,5>">
  cute.print(%sw1) : !cute.swizzle<"S<2,3,5>">
  %sw1b = func.call @h_composed_get_inner_swizzle() : () -> !cute.swizzle<"S<2,3,5>">
  cute.print(%sw1b) : !cute.swizzle<"S<2,3,5>">

  // composed_get_offset with dyn scalar offset — offset_leaf=113.
  %o113 = arith.constant 113 : i32
  %x113 = arith.addi %base, %o113 : i32
  %inner_v2 = cute.static : !cute.layout<"(2,3):(1,2)">
  %off_v2 = cute.make_int_tuple(%x113) : (i32) -> !cute.int_tuple<"?">
  %outer_v2 = cute.static : !cute.layout<"(4,5):(1,4)">
  %cl_v2 = cute.make_composed_layout(%inner_v2, %off_v2, %outer_v2)
        : (!cute.layout<"(2,3):(1,2)">, !cute.int_tuple<"?">, !cute.layout<"(4,5):(1,4)">)
        -> !cute.composed_layout<"(2,3):(1,2) o ? o (4,5):(1,4)">
  %off_v2_1 = cute.composed_get_offset(%cl_v2)
        : !cute.composed_layout<"(2,3):(1,2) o ? o (4,5):(1,4)"> -> !cute.int_tuple<"?">
  cute.print(%off_v2_1) : !cute.int_tuple<"?">
  %off_v2_2 = func.call @h_composed_get_offset_dyn(%x113) : (i32) -> !cute.int_tuple<"?">
  cute.print(%off_v2_2) : !cute.int_tuple<"?">

  // composed_get_outer with dyn outer B — shape_leaf=127, stride_leaf=127.
  %o127 = arith.constant 127 : i32
  %x127 = arith.addi %base, %o127 : i32
  %inner_v3 = cute.static : !cute.layout<"(2,3):(1,2)">
  %off_v3 = cute.static : !cute.int_tuple<"0">
  %sh_v3 = cute.make_shape(%x127) : (i32) -> !cute.shape<"(?,131)">
  %st_v3 = cute.make_stride(%x127) : (i32) -> !cute.stride<"(1,?)">
  %outer_v3 = cute.make_layout(%sh_v3, %st_v3)
        : (!cute.shape<"(?,131)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,131):(1,?)">
  %cl_v3 = cute.make_composed_layout(%inner_v3, %off_v3, %outer_v3)
        : (!cute.layout<"(2,3):(1,2)">, !cute.int_tuple<"0">, !cute.layout<"(?,131):(1,?)">)
        -> !cute.composed_layout<"(2,3):(1,2) o 0 o (?,131):(1,?)">
  %out_v3_1 = cute.composed_get_outer(%cl_v3)
        : !cute.composed_layout<"(2,3):(1,2) o 0 o (?,131):(1,?)"> -> !cute.layout<"(?,131):(1,?)">
  cute.print(%out_v3_1) : !cute.layout<"(?,131):(1,?)">
  %out_v3_2 = func.call @h_composed_get_outer_dyn(%x127, %x127)
        : (i32, i32) -> !cute.layout<"(?,131):(1,?)">
  cute.print(%out_v3_2) : !cute.layout<"(?,131):(1,?)">

  // select<[2, 0]> — permutation on a fully-dyn rank-3 layout.
  %o137 = arith.constant 137 : i32
  %x137 = arith.addi %base, %o137 : i32
  %o139 = arith.constant 139 : i32
  %x139 = arith.addi %base, %o139 : i32
  %o149 = arith.constant 149 : i32
  %x149 = arith.addi %base, %o149 : i32
  %sh_perm = cute.make_shape(%x137, %x139, %x149)
           : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
  %l_perm_stride_mul = arith.muli %x137, %x139 : i32
  %l_perm_stride = cute.make_stride (%x137, %l_perm_stride_mul) : (i32, i32) -> !cute.stride<"(1,?,?)">
  %l_perm = cute.make_layout (%sh_perm, %l_perm_stride) : (!cute.shape<"(?,?,?)">, !cute.stride<"(1,?,?)">) -> !cute.layout<"(?,?,?):(1,?,?)">
  %sp1 = cute.select<[2, 0]> (%l_perm)
       : !cute.layout<"(?,?,?):(1,?,?)"> -> !cute.layout<"(?,?):(?,1)">
  cute.print(%sp1) : !cute.layout<"(?,?):(?,1)">
  %sp2 = func.call @h_select_permute(%x137, %x139, %x149)
       : (i32, i32, i32) -> !cute.layout<"(?,?):(?,1)">
  cute.print(%sp2) : !cute.layout<"(?,?):(?,1)">

  // select<[]> on a dyn shape — empty mode → rank-0 result.
  %o151 = arith.constant 151 : i32
  %x151 = arith.addi %base, %o151 : i32
  %o157 = arith.constant 157 : i32
  %x157 = arith.addi %base, %o157 : i32
  %sh_empty = cute.make_shape(%x151, %x157)
            : (i32, i32) -> !cute.shape<"(?,?)">
  %se1 = cute.select<[]> (%sh_empty) : !cute.shape<"(?,?)"> -> !cute.shape<"()">
  cute.print(%se1) : !cute.shape<"()">
  %se2 = func.call @h_select_empty(%x151, %x157)
       : (i32, i32) -> !cute.shape<"()">
  cute.print(%se2) : !cute.shape<"()">

  // to_int_tuple from a stride with a dyn leaf.
  %o239 = arith.constant 239 : i32
  %x239 = arith.addi %base, %o239 : i32
  %st_dyn = cute.make_stride(%x239) : (i32) -> !cute.stride<"(1,?)">
  %itsd1 = cute.to_int_tuple(%st_dyn)
         : !cute.stride<"(1,?)"> -> !cute.int_tuple<"(1,?)">
  cute.print(%itsd1) : !cute.int_tuple<"(1,?)">
  %itsd2 = func.call @h_to_int_tuple_stride_dyn(%x239)
         : (i32) -> !cute.int_tuple<"(1,?)">
  cute.print(%itsd2) : !cute.int_tuple<"(1,?)">

  // get_layouts_from_tile on a multi-layout runtime-dyn tile.
  %o251 = arith.constant 251 : i32
  %x251 = arith.addi %base, %o251 : i32
  %o257 = arith.constant 257 : i32
  %x257 = arith.addi %base, %o257 : i32
  %o269 = arith.constant 269 : i32
  %x269 = arith.addi %base, %o269 : i32
  %t_multi = cute.make_tile(%x251, %x257, %x269)
           : (i32, i32, i32) -> !cute.tile<"[(?,3):(1,?);(5,?):(1,5)]">
  %lm0a, %lm1a = cute.get_layouts_from_tile(%t_multi)
              : !cute.tile<"[(?,3):(1,?);(5,?):(1,5)]">
  cute.print(%lm0a) : !cute.layout<"(?,3):(1,?)">
  cute.print(%lm1a) : !cute.layout<"(5,?):(1,5)">
  %lm0b, %lm1b = func.call @h_get_layouts_from_tile_multi_dyn(%x251, %x257, %x269)
              : (i32, i32, i32)
             -> (!cute.layout<"(?,3):(1,?)">, !cute.layout<"(5,?):(1,5)">)
  cute.print(%lm0b) : !cute.layout<"(?,3):(1,?)">
  cute.print(%lm1b) : !cute.layout<"(5,?):(1,5)">

  return
}
