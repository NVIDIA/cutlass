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

// Runtime-dynamic TilingPartitioningProducts; leaves are opaque to the JIT, any arith is permitted.

// CHECK-COUNT-2: ((3,2),(4,2)):((1,3),(6,24))
// CHECK-COUNT-2: ((3,4),(2,2)):((1,6),(3,24))
// CHECK-COUNT-2: ((3,4),2,2):((1,6),3,24)
// CHECK-COUNT-2: (3,4,2,2):(1,6,3,24)
// CHECK-COUNT-2: ((3,2),(2,4)):((1,6),(3,12))
// CHECK-COUNT-2: ((3,2),(2,4)):((1,24),(3,6))
// CHECK-COUNT-2: ((3,4),(2,4)):((4,1),(12,24))
// CHECK-COUNT-2: ((3,4),(2,4)):((4,1),(48,12))
// CHECK-COUNT-2: ((3,4),(2,4)):((4,1),(12,24))
// CHECK-COUNT-2: ((3,4),2,4):((4,1),12,24)
// CHECK-COUNT-2: (3,4,2,4):(4,1,12,24)
// CHECK-COUNT-2: ((2,3),(4,4)):((12,4),(24,1))
// CHECK-COUNT-2: ((3,2),(4,4)):((4,12),(1,24))
// CHECK-COUNT-2: ((3,4),(2,4)):((4,1),(48,12))
// CHECK-COUNT-2: ((3,4),2,4):((4,1),48,12)
// CHECK-COUNT-2: (3,4,2,4):(4,1,48,12)
// CHECK-COUNT-2: ((2,3),(4,4)):((48,4),(12,1))
// CHECK-COUNT-2: ((3,2),(4,4)):((4,48),(1,12))

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

func.func @h_logical_divide(%a: i32) -> !cute.layout<"((3,?),(4,2)):((1,3),(?,?))"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,8)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
  %b = cute.static : !cute.shape<"(3,4)">
  %r = cute.logical_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">
  return %r : !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">
}

func.func @h_zipped_divide(%a: i32) -> !cute.layout<"((3,4),(?,2)):((1,?),(3,?))"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,8)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
  %b = cute.static : !cute.shape<"(3,4)">
  %r = cute.zipped_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">
  return %r : !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">
}

func.func @h_tiled_divide(%a: i32) -> !cute.layout<"((3,4),?,2):((1,?),3,?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,8)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
  %b = cute.static : !cute.shape<"(3,4)">
  %r = cute.tiled_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),?,2):((1,?),3,?)">
  return %r : !cute.layout<"((3,4),?,2):((1,?),3,?)">
}

func.func @h_flat_divide(%a: i32) -> !cute.layout<"(3,4,?,2):(1,?,3,?)"> {
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,8)">
  %l_stride = cute.make_stride (%a) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
  %b = cute.static : !cute.shape<"(3,4)">
  %r = cute.flat_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"(3,4,?,2):(1,?,3,?)">
  return %r : !cute.layout<"(3,4,?,2):(1,?,3,?)">
}

func.func @h_tile_to_shape(%a: i32) -> !cute.layout<"((3,?),(2,4)):((1,6),(3,?))"> {
  %la = cute.static : !cute.layout<"(3,2):(1,3)">
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,8)">
  %r = cute.tile_to_shape(%la, %sh)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,8)">)
        -> !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">
  return %r : !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">
}

func.func @h_tile_to_shape_order_swap(%a: i32)
    -> !cute.layout<"((3,?),(2,4)):((1,24),(3,6))"> {
  %la = cute.static : !cute.layout<"(3,2):(1,3)">
  %sh = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,8)">
  %o = cute.static : !cute.int_tuple<"(1,0)">
  %r = cute.tile_to_shape(%la, %sh, %o)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,8)">,
          !cute.int_tuple<"(1,0)">)
        -> !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">
  return %r : !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">
}

func.func @h_logical_product(%x: i32, %y: i32)
    -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.static : !cute.stride<"(1,2)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(1,2)">)
       -> !cute.layout<"(?,?):(1,2)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.logical_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  return %r : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
}

func.func @h_logical_product_dyn_stride(
    %x: i32, %y: i32, %s0: i32, %s1: i32)
    -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.make_stride (%s0, %s1)
        : (i32, i32) -> !cute.stride<"(?,?)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
       -> !cute.layout<"(?,?):(?,?)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.logical_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  return %r : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
}

// 5 sibling-product helpers — static input × dyn tiler.
func.func @h_zipped_product(%x: i32, %y: i32)
    -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.static : !cute.stride<"(1,2)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(1,2)">)
       -> !cute.layout<"(?,?):(1,2)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.zipped_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  return %r : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
}

func.func @h_tiled_product(%x: i32, %y: i32)
    -> !cute.layout<"((3,4),?,?):((4,1),12,24)"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.static : !cute.stride<"(1,2)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(1,2)">)
       -> !cute.layout<"(?,?):(1,2)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.tiled_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"((3,4),?,?):((4,1),12,24)">
  return %r : !cute.layout<"((3,4),?,?):((4,1),12,24)">
}

func.func @h_flat_product(%x: i32, %y: i32)
    -> !cute.layout<"(3,4,?,?):(4,1,12,24)"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.static : !cute.stride<"(1,2)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(1,2)">)
       -> !cute.layout<"(?,?):(1,2)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.flat_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"(3,4,?,?):(4,1,12,24)">
  return %r : !cute.layout<"(3,4,?,?):(4,1,12,24)">
}

func.func @h_raked_product(%x: i32, %y: i32)
    -> !cute.layout<"((?,3),(?,4)):((12,4),(24,1))"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.static : !cute.stride<"(1,2)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(1,2)">)
       -> !cute.layout<"(?,?):(1,2)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.raked_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">
  return %r : !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">
}

func.func @h_blocked_product(%x: i32, %y: i32)
    -> !cute.layout<"((3,?),(4,?)):((4,12),(1,24))"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.static : !cute.stride<"(1,2)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(1,2)">)
       -> !cute.layout<"(?,?):(1,2)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.blocked_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">
  return %r : !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">
}

// 5 sibling-product helpers — static input × **fully-dyn** tiler
func.func @h_zipped_product_dyn_stride(
    %x: i32, %y: i32, %s0: i32, %s1: i32)
    -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.make_stride (%s0, %s1)
        : (i32, i32) -> !cute.stride<"(?,?)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
       -> !cute.layout<"(?,?):(?,?)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.zipped_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  return %r : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
}

func.func @h_tiled_product_dyn_stride(
    %x: i32, %y: i32, %s0: i32, %s1: i32)
    -> !cute.layout<"((3,4),?,?):((4,1),?,?)"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.make_stride (%s0, %s1)
        : (i32, i32) -> !cute.stride<"(?,?)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
       -> !cute.layout<"(?,?):(?,?)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.tiled_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"((3,4),?,?):((4,1),?,?)">
  return %r : !cute.layout<"((3,4),?,?):((4,1),?,?)">
}

func.func @h_flat_product_dyn_stride(
    %x: i32, %y: i32, %s0: i32, %s1: i32)
    -> !cute.layout<"(3,4,?,?):(4,1,?,?)"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.make_stride (%s0, %s1)
        : (i32, i32) -> !cute.stride<"(?,?)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
       -> !cute.layout<"(?,?):(?,?)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.flat_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"(3,4,?,?):(4,1,?,?)">
  return %r : !cute.layout<"(3,4,?,?):(4,1,?,?)">
}

func.func @h_raked_product_dyn_stride(
    %x: i32, %y: i32, %s0: i32, %s1: i32)
    -> !cute.layout<"((?,3),(?,4)):((?,4),(?,1))"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.make_stride (%s0, %s1)
        : (i32, i32) -> !cute.stride<"(?,?)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
       -> !cute.layout<"(?,?):(?,?)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.raked_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">
  return %r : !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">
}

func.func @h_blocked_product_dyn_stride(
    %x: i32, %y: i32, %s0: i32, %s1: i32)
    -> !cute.layout<"((3,?),(4,?)):((4,?),(1,?))"> {
  %sh_t = cute.make_shape (%x, %y) : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.make_stride (%s0, %s1)
        : (i32, i32) -> !cute.stride<"(?,?)">
  %t = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
       -> !cute.layout<"(?,?):(?,?)">
  %a = cute.static : !cute.layout<"(3,4):(4,1)">
  %r = cute.blocked_product(%a, %t)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">
  return %r : !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">
}

//===----------------------------------------------------------------------===//
// Entry point.
//===----------------------------------------------------------------------===//

func.func @main() {
  %base = func.call @read_base() : () -> i32
  %o6 = arith.constant 6 : i32
  %x6 = arith.addi %base, %o6 : i32

  // Dyn 2D layout (?,8):(1,?) with x=6.
  %sh = cute.make_shape (%x6) : (i32) -> !cute.shape<"(?,8)">
  %l_stride = cute.make_stride (%x6) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
  %b = cute.static : !cute.shape<"(3,4)">

  // logical_divide
  %r1 = cute.logical_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">
  cute.print(%r1) : !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">
  %r1b = func.call @h_logical_divide(%x6)
       : (i32) -> !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">
  cute.print(%r1b) : !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">

  // zipped_divide
  %r2 = cute.zipped_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">
  cute.print(%r2) : !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">
  %r2b = func.call @h_zipped_divide(%x6)
       : (i32) -> !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">
  cute.print(%r2b) : !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">

  // tiled_divide
  %r3 = cute.tiled_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),?,2):((1,?),3,?)">
  cute.print(%r3) : !cute.layout<"((3,4),?,2):((1,?),3,?)">
  %r3b = func.call @h_tiled_divide(%x6)
       : (i32) -> !cute.layout<"((3,4),?,2):((1,?),3,?)">
  cute.print(%r3b) : !cute.layout<"((3,4),?,2):((1,?),3,?)">

  // flat_divide
  %r4 = cute.flat_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"(3,4,?,2):(1,?,3,?)">
  cute.print(%r4) : !cute.layout<"(3,4,?,2):(1,?,3,?)">
  %r4b = func.call @h_flat_divide(%x6)
       : (i32) -> !cute.layout<"(3,4,?,2):(1,?,3,?)">
  cute.print(%r4b) : !cute.layout<"(3,4,?,2):(1,?,3,?)">

  // tile_to_shape with dyn target shape (?,8) x=6.
  %a5 = cute.static : !cute.layout<"(3,2):(1,3)">
  %sh_b5 = cute.make_shape (%x6) : (i32) -> !cute.shape<"(?,8)">
  %r5 = cute.tile_to_shape(%a5, %sh_b5)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,8)">)
        -> !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">
  cute.print(%r5) : !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">
  %r5b = func.call @h_tile_to_shape(%x6)
       : (i32) -> !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">
  cute.print(%r5b) : !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">

  // tile_to_shape with explicit order = (1,0) on the same dyn shape:
  // same shape at runtime, but the per-axis replication strides shift.
  %o5 = cute.static : !cute.int_tuple<"(1,0)">
  %r6 = cute.tile_to_shape(%a5, %sh_b5, %o5)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,8)">,
          !cute.int_tuple<"(1,0)">)
        -> !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">
  cute.print(%r6) : !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">
  %r6b = func.call @h_tile_to_shape_order_swap(%x6)
       : (i32) -> !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">
  cute.print(%r6b) : !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">

  // logical_product with static input × dyn tiler. Tiler shape comes
  // from %base + offsets (2 and 4), so it stays opaque to the JIT.
  %lp_o2 = arith.constant 2 : i32
  %lp_o4 = arith.constant 4 : i32
  %lp_x2 = arith.addi %base, %lp_o2 : i32
  %lp_x4 = arith.addi %base, %lp_o4 : i32
  %sh_t = cute.make_shape (%lp_x2, %lp_x4)
        : (i32, i32) -> !cute.shape<"(?,?)">
  %st_t = cute.static : !cute.stride<"(1,2)">
  %t7 = cute.make_layout (%sh_t, %st_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(1,2)">)
       -> !cute.layout<"(?,?):(1,2)">
  %a7 = cute.static : !cute.layout<"(3,4):(4,1)">
  %r7 = cute.logical_product(%a7, %t7)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  cute.print(%r7) : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  %r7b = func.call @h_logical_product(%lp_x2, %lp_x4)
       : (i32, i32) -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  cute.print(%r7b) : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">

  // Fully-dyn tiler: shape (2,4), stride (4,1) at runtime (from
  // %base + offset). Result type carries `?` annotations.
  %lp_o4_s = arith.constant 4 : i32
  %lp_o1_s = arith.constant 1 : i32
  %lp_s0 = arith.addi %base, %lp_o4_s : i32
  %lp_s1 = arith.addi %base, %lp_o1_s : i32
  %dsh_t = cute.make_shape (%lp_x2, %lp_x4)
        : (i32, i32) -> !cute.shape<"(?,?)">
  %dst_t = cute.make_stride (%lp_s0, %lp_s1)
        : (i32, i32) -> !cute.stride<"(?,?)">
  %t8 = cute.make_layout (%dsh_t, %dst_t)
        : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
       -> !cute.layout<"(?,?):(?,?)">
  %r8 = cute.logical_product(%a7, %t8)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  cute.print(%r8) : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  %r8b = func.call @h_logical_product_dyn_stride(%lp_x2, %lp_x4, %lp_s0, %lp_s1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  cute.print(%r8b) : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">

  // 5 sibling products with static input × dyn tiler. Inline form
  // reuses `%a7` and `%t7` from above; helper form calls each
  // sibling helper directly.
  %r_zp = cute.zipped_product(%a7, %t7)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  cute.print(%r_zp) : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  %r_zpb = func.call @h_zipped_product(%lp_x2, %lp_x4)
       : (i32, i32) -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  cute.print(%r_zpb) : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">

  %r_tp = cute.tiled_product(%a7, %t7)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"((3,4),?,?):((4,1),12,24)">
  cute.print(%r_tp) : !cute.layout<"((3,4),?,?):((4,1),12,24)">
  %r_tpb = func.call @h_tiled_product(%lp_x2, %lp_x4)
       : (i32, i32) -> !cute.layout<"((3,4),?,?):((4,1),12,24)">
  cute.print(%r_tpb) : !cute.layout<"((3,4),?,?):((4,1),12,24)">

  %r_fp = cute.flat_product(%a7, %t7)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"(3,4,?,?):(4,1,12,24)">
  cute.print(%r_fp) : !cute.layout<"(3,4,?,?):(4,1,12,24)">
  %r_fpb = func.call @h_flat_product(%lp_x2, %lp_x4)
       : (i32, i32) -> !cute.layout<"(3,4,?,?):(4,1,12,24)">
  cute.print(%r_fpb) : !cute.layout<"(3,4,?,?):(4,1,12,24)">

  %r_rp = cute.raked_product(%a7, %t7)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">
  cute.print(%r_rp) : !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">
  %r_rpb = func.call @h_raked_product(%lp_x2, %lp_x4)
       : (i32, i32) -> !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">
  cute.print(%r_rpb) : !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">

  %r_bp = cute.blocked_product(%a7, %t7)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
       -> !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">
  cute.print(%r_bp) : !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">
  %r_bpb = func.call @h_blocked_product(%lp_x2, %lp_x4)
       : (i32, i32) -> !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">
  cute.print(%r_bpb) : !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">

  // 5 sibling products with static input × fully-dyn tiler.
  %r_zp2 = cute.zipped_product(%a7, %t8)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  cute.print(%r_zp2) : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  %r_zp2b = func.call @h_zipped_product_dyn_stride(%lp_x2, %lp_x4, %lp_s0, %lp_s1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  cute.print(%r_zp2b) : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">

  %r_tp2 = cute.tiled_product(%a7, %t8)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"((3,4),?,?):((4,1),?,?)">
  cute.print(%r_tp2) : !cute.layout<"((3,4),?,?):((4,1),?,?)">
  %r_tp2b = func.call @h_tiled_product_dyn_stride(%lp_x2, %lp_x4, %lp_s0, %lp_s1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"((3,4),?,?):((4,1),?,?)">
  cute.print(%r_tp2b) : !cute.layout<"((3,4),?,?):((4,1),?,?)">

  %r_fp2 = cute.flat_product(%a7, %t8)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"(3,4,?,?):(4,1,?,?)">
  cute.print(%r_fp2) : !cute.layout<"(3,4,?,?):(4,1,?,?)">
  %r_fp2b = func.call @h_flat_product_dyn_stride(%lp_x2, %lp_x4, %lp_s0, %lp_s1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"(3,4,?,?):(4,1,?,?)">
  cute.print(%r_fp2b) : !cute.layout<"(3,4,?,?):(4,1,?,?)">

  %r_rp2 = cute.raked_product(%a7, %t8)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">
  cute.print(%r_rp2) : !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">
  %r_rp2b = func.call @h_raked_product_dyn_stride(%lp_x2, %lp_x4, %lp_s0, %lp_s1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">
  cute.print(%r_rp2b) : !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">

  %r_bp2 = cute.blocked_product(%a7, %t8)
        : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
       -> !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">
  cute.print(%r_bp2) : !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">
  %r_bp2b = func.call @h_blocked_product_dyn_stride(%lp_x2, %lp_x4, %lp_s0, %lp_s1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">
  cute.print(%r_bp2b) : !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">

  return
}
