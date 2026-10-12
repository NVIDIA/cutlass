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
// Not-inlined TilingPartitioningProducts; runtime arith may survive -base-prepare across helper boundaries.

// CHECK: ((3,2),(4,2)):((1,3),(6,24))
// CHECK: ((3,4),(2,2)):((1,6),(3,24))
// CHECK: ((3,4),2,2):((1,6),3,24)
// CHECK: (3,4,2,2):(1,6,3,24)
// CHECK: ((3,2),(2,4)):((1,6),(3,12))
// CHECK: ((3,2),(2,4)):((1,24),(3,6))
// CHECK: ((3,4),(2,4)):((4,1),(12,24))
// CHECK: ((3,4),(2,4)):((4,1),(48,12))
// CHECK: ((3,4),(2,4)):((4,1),(12,24))
// CHECK: ((3,4),2,4):((4,1),12,24)
// CHECK: (3,4,2,4):(4,1,12,24)
// CHECK: ((2,3),(4,4)):((12,4),(24,1))
// CHECK: ((3,2),(4,4)):((4,12),(1,24))
// CHECK: ((3,4),(2,4)):((4,1),(48,12))
// CHECK: ((3,4),2,4):((4,1),48,12)
// CHECK: (3,4,2,4):(4,1,48,12)
// CHECK: ((2,3),(4,4)):((48,4),(12,1))
// CHECK: ((3,2),(4,4)):((4,48),(1,12))

//===----------------------------------------------------------------------===//
// Per-op helpers — opaque-arg boundaries.
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
// Each helper builds its own dyn tiler from the i32 args (same shape
// the logical_product helper above uses) and calls the per-op product.
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
// Entry point — helper-call only.
//===----------------------------------------------------------------------===//

func.func @main() {
  %x6 = arith.constant 6 : i32

  %r1 = func.call @h_logical_divide(%x6)
       : (i32) -> !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">
  cute.print(%r1) : !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">

  %r2 = func.call @h_zipped_divide(%x6)
       : (i32) -> !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">
  cute.print(%r2) : !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">

  %r3 = func.call @h_tiled_divide(%x6)
       : (i32) -> !cute.layout<"((3,4),?,2):((1,?),3,?)">
  cute.print(%r3) : !cute.layout<"((3,4),?,2):((1,?),3,?)">

  %r4 = func.call @h_flat_divide(%x6)
       : (i32) -> !cute.layout<"(3,4,?,2):(1,?,3,?)">
  cute.print(%r4) : !cute.layout<"(3,4,?,2):(1,?,3,?)">

  %r5 = func.call @h_tile_to_shape(%x6)
       : (i32) -> !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">
  cute.print(%r5) : !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">

  %r6 = func.call @h_tile_to_shape_order_swap(%x6)
       : (i32) -> !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">
  cute.print(%r6) : !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">

  %x2 = arith.constant 2 : i32
  %x4 = arith.constant 4 : i32
  %r7 = func.call @h_logical_product(%x2, %x4)
       : (i32, i32) -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  cute.print(%r7) : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">

  // Fully-dyn tiler: shape (2,4), stride (4,1) at runtime.
  %ts0 = arith.constant 4 : i32
  %ts1 = arith.constant 1 : i32
  %r8 = func.call @h_logical_product_dyn_stride(%x2, %x4, %ts0, %ts1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  cute.print(%r8) : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">

  // 5 sibling-product helper calls — same `%x2, %x4` (dyn tiler shape).
  %r_zp = func.call @h_zipped_product(%x2, %x4)
       : (i32, i32) -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  cute.print(%r_zp) : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">

  %r_tp = func.call @h_tiled_product(%x2, %x4)
       : (i32, i32) -> !cute.layout<"((3,4),?,?):((4,1),12,24)">
  cute.print(%r_tp) : !cute.layout<"((3,4),?,?):((4,1),12,24)">

  %r_fp = func.call @h_flat_product(%x2, %x4)
       : (i32, i32) -> !cute.layout<"(3,4,?,?):(4,1,12,24)">
  cute.print(%r_fp) : !cute.layout<"(3,4,?,?):(4,1,12,24)">

  %r_rp = func.call @h_raked_product(%x2, %x4)
       : (i32, i32) -> !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">
  cute.print(%r_rp) : !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">

  %r_bp = func.call @h_blocked_product(%x2, %x4)
       : (i32, i32) -> !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">
  cute.print(%r_bp) : !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">

  // 5 sibling-product helper calls — static input × fully-dyn tiler.
  // `%ts0, %ts1` (4, 1) reused from the logical_product fully-dyn call.
  %r_zp2 = func.call @h_zipped_product_dyn_stride(%x2, %x4, %ts0, %ts1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  cute.print(%r_zp2) : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">

  %r_tp2 = func.call @h_tiled_product_dyn_stride(%x2, %x4, %ts0, %ts1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"((3,4),?,?):((4,1),?,?)">
  cute.print(%r_tp2) : !cute.layout<"((3,4),?,?):((4,1),?,?)">

  %r_fp2 = func.call @h_flat_product_dyn_stride(%x2, %x4, %ts0, %ts1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"(3,4,?,?):(4,1,?,?)">
  cute.print(%r_fp2) : !cute.layout<"(3,4,?,?):(4,1,?,?)">

  %r_rp2 = func.call @h_raked_product_dyn_stride(%x2, %x4, %ts0, %ts1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">
  cute.print(%r_rp2) : !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">

  %r_bp2 = func.call @h_blocked_product_dyn_stride(%x2, %x4, %ts0, %ts1)
       : (i32, i32, i32, i32)
      -> !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">
  cute.print(%r_bp2) : !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">

  return
}
