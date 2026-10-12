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
// Dynamic TilingPartitioningProducts with ops inlined in `@main`.
// Static leaves constant-fold through `-base-prepare`, leaving only `arith.constant`.
//
// Product ops require a fully-static input; the tiler may be dynamic.
//
// Companion `tiling_partitioning_products_dynamic_not_inlined.mlir`
// exercises the same ops via helpers.
//
// Two character-class patterns permit only `arith.constant`:
// RUN: cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:     -base-prepare %s | FileCheck --check-prefix=POST-PREP %s
//
// POST-PREP-NOT: arith.{{[^c]}}
// POST-PREP-NOT: arith.c{{[^o]}}

// CHECK: ((3,2),(4,2)):((1,3),(6,24))
// CHECK-NEXT: ((3,4),(2,2)):((1,6),(3,24))
// CHECK-NEXT: ((3,4),2,2):((1,6),3,24)
// CHECK-NEXT: (3,4,2,2):(1,6,3,24)
// CHECK-NEXT: (((3,1),(2,2)),((1,1),(1,4))):(((1,6),(3,6)),((12,12),(12,12)))
// CHECK-NEXT: (((3),2),((4),2)):(((1),3),((6),24))
// CHECK-NEXT: (3):(1) o 0 o ((3,2),(4,2)):((8,24),(1,4))
// CHECK-NEXT: (3):(1) o 0 o ((3,(2,2)),4):((8,(24,1)),2)
// CHECK-NEXT: (3):(1) o 0 o (((3),2),((4),2)):(((8),24),((1),4))
// CHECK-NEXT: ((3,2),(4,2)):((1,3),(6,24))
// CHECK-NEXT: (((3,1),(2,2)),((1,1),(1,4))):(((1,6),(3,6)),((12,12),(12,12)))
// CHECK-NEXT: (((3),2),((4),2)):(((1),3),((6),24))
// zipped_divide:
// CHECK-NEXT: (((3,1),(2,2)),((1,1),(1,4))):(((1,6),(3,6)),((12,12),(12,12)))
// CHECK-NEXT: (((3),(4)),(2,2)):(((1),(6)),(3,24))
// CHECK-NEXT: (3):(1) o 0 o ((3,4),(2,2)):((8,1),(24,4))
// CHECK-NEXT: (3):(1) o 0 o ((3,(2,2)),4):((8,(24,1)),2)
// CHECK-NEXT: (3):(1) o 0 o (((3),(4)),(2,2)):(((8),(1)),(24,4))
// CHECK-NEXT: ((3,4),(2,2)):((1,6),(3,24))
// CHECK-NEXT: (((3,1),(2,2)),((1,1),(1,4))):(((1,6),(3,6)),((12,12),(12,12)))
// CHECK-NEXT: (((3),(4)),(2,2)):(((1),(6)),(3,24))
// tiled_divide:
// CHECK-NEXT: (((3,1),(2,2)),(1,1),(1,4)):(((1,6),(3,6)),(12,12),(12,12))
// CHECK-NEXT: (((3),(4)),2,2):(((1),(6)),3,24)
// CHECK-NEXT: (3):(1) o 0 o ((3,4),2,2):((8,1),24,4)
// CHECK-NEXT: (3):(1) o 0 o ((3,(2,2)),4):((8,(24,1)),2)
// CHECK-NEXT: (3):(1) o 0 o (((3),(4)),2,2):(((8),(1)),24,4)
// CHECK-NEXT: ((3,4),2,2):((1,6),3,24)
// CHECK-NEXT: (((3,1),(2,2)),(1,1),(1,4)):(((1,6),(3,6)),(12,12),(12,12))
// CHECK-NEXT: (((3),(4)),2,2):(((1),(6)),3,24)
// flat_divide:
// CHECK-NEXT: ((3,1),(2,2),(1,1),(1,4)):((1,6),(3,6),(12,12),(12,12))
// CHECK-NEXT: ((3),(4),2,2):((1),(6),3,24)
// CHECK-NEXT: (3):(1) o 0 o (3,4,2,2):(8,1,24,4)
// CHECK-NEXT: (3):(1) o 0 o (3,(2,2),4):(8,(24,1),2)
// CHECK-NEXT: (3):(1) o 0 o ((3),(4),2,2):((8),(1),24,4)
// CHECK-NEXT: (3,4,2,2):(1,6,3,24)
// CHECK-NEXT: ((3,1),(2,2),(1,1),(1,4)):((1,6),(3,6),(12,12),(12,12))
// CHECK-NEXT: ((3),(4),2,2):((1),(6),3,24)
// CHECK-NEXT: ((3,2),(2,4)):((1,6),(3,12))
// tile_to_shape with explicit order = (1,0) on the same dyn shape:
// same shape at runtime, but the per-axis replication strides shift.
// CHECK-NEXT: ((3,2),(2,4)):((1,24),(3,6))
// logical_product with static input × dyn tiler. Tiler dynamism
// (x=2, y=4) propagates into mode-1 of the result.
// CHECK-NEXT: ((3,4),(2,4)):((4,1),(12,24))
// logical_product with static input × fully-dyn tiler (dyn shape AND
// dyn stride). Tiler stride (4,1) at runtime — non-canonical, gives
// distinct result strides vs the previous case.
// CHECK-NEXT: ((3,4),(2,4)):((4,1),(48,12))
// 5 sibling products with static input × dyn tiler — exercises the
// per-op binding through the same dyn rebuild path. Inputs `%a7` and
// `%t7` are reused from the logical_product cells above.
// CHECK-NEXT: ((3,4),(2,4)):((4,1),(12,24))
// CHECK-NEXT: ((3,4),2,4):((4,1),12,24)
// CHECK-NEXT: (3,4,2,4):(4,1,12,24)
// CHECK-NEXT: ((2,3),(4,4)):((12,4),(24,1))
// CHECK-NEXT: ((3,2),(4,4)):((4,12),(1,24))
// 5 sibling products with static input × **fully-dyn** tiler
// `((3,4),(2,4)):((4,1),(48,12))`.
// CHECK-NEXT: ((3,4),(2,4)):((4,1),(48,12))
// CHECK-NEXT: ((3,4),2,4):((4,1),48,12)
// CHECK-NEXT: (3,4,2,4):(4,1,48,12)
// CHECK-NEXT: ((2,3),(4,4)):((48,4),(12,1))
// CHECK-NEXT: ((3,2),(4,4)):((4,48),(1,12))

func.func @main() {
  // Dyn 2D layout (?,8):(1,?) with x=6.
  %x6 = arith.constant 6 : i32
  %sh = cute.make_shape (%x6) : (i32) -> !cute.shape<"(?,8)">
  %l_stride = cute.make_stride (%x6) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
  %b = cute.static : !cute.shape<"(3,4)">

  // logical_divide
  %r1 = cute.logical_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">
  cute.print(%r1) : !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">

  // zipped_divide
  %r2 = cute.zipped_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">
  cute.print(%r2) : !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">

  // tiled_divide
  %r3 = cute.tiled_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),?,2):((1,?),3,?)">
  cute.print(%r3) : !cute.layout<"((3,4),?,2):((1,?),3,?)">

  // flat_divide
  %r4 = cute.flat_divide(%l, %b)
       : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"(3,4,?,2):(1,?,3,?)">
  cute.print(%r4) : !cute.layout<"(3,4,?,2):(1,?,3,?)">

  // dyn input × layout tiler
  %lt = cute.static : !cute.layout<"(3,4):(1,3)">
  %r_g1 = cute.logical_divide(%l, %lt)
       : (!cute.layout<"(?,8):(1,?)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"(((?,?),(?,?)),((?,?),(?,?))):(((1,?),(3,?)),((12,?),(?,?)))">
  cute.print(%r_g1) : !cute.layout<"(((?,?),(?,?)),((?,?),(?,?))):(((1,?),(3,?)),((12,?),(?,?)))">

  // dyn input × tile tiler
  %tt = cute.static : !cute.tile<"[(3):(1);(4):(1)]">
  %r_g2 = cute.logical_divide(%l, %tt)
       : (!cute.layout<"(?,8):(1,?)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),?),((4),2)):(((1),3),((?),?))">
  cute.print(%r_g2) : !cute.layout<"(((3),?),((4),2)):(((1),3),((?),?))">

  // dyn composed input × {shape, layout, tile} tilers
  %dci_sh_v = arith.constant 3 : i32
  %dci_sh = cute.make_shape (%dci_sh_v) : (i32) -> !cute.shape<"(?)">
  %dci_st_v = arith.constant 1 : i32
  %dci_st = cute.make_stride (%dci_st_v) : (i32) -> !cute.stride<"(?)">
  %dci_inner = cute.make_layout (%dci_sh, %dci_st)
       : (!cute.shape<"(?)">, !cute.stride<"(?)">) -> !cute.layout<"(?):(?)">
  %dci_off_v = arith.constant 0 : i32
  %dci_off = cute.make_int_tuple (%dci_off_v) : (i32) -> !cute.int_tuple<"?">
  %dci_outer = cute.static : !cute.layout<"(6,8):(8,1)">
  %dci = cute.make_composed_layout(%dci_inner, %dci_off, %dci_outer)
       : (!cute.layout<"(?):(?)">, !cute.int_tuple<"?">,
          !cute.layout<"(6,8):(8,1)">)
       -> !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">

  %r_g5 = cute.logical_divide(%dci, %b)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
          !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((3,2),(4,2)):((8,24),(1,4))">
  cute.print(%r_g5) : !cute.composed_layout<"(?):(?) o ? o ((3,2),(4,2)):((8,24),(1,4))">

  %r_g6 = cute.logical_divide(%dci, %lt)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
          !cute.layout<"(3,4):(1,3)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r_g6) : !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">

  %r_g7 = cute.logical_divide(%dci, %tt)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">,
          !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.composed_layout<"(?):(?) o ? o (((3),2),((4),2)):(((8),24),((1),4))">
  cute.print(%r_g7) : !cute.composed_layout<"(?):(?) o ? o (((3),2),((4),2)):(((8),24),((1),4))">

  // fully-dyn input × {shape, layout, tile} tilers
  %fd_s0 = arith.constant 6 : i32
  %fd_s1 = arith.constant 8 : i32
  %fd_sh = cute.make_shape (%fd_s0, %fd_s1)
       : (i32, i32) -> !cute.shape<"(?,?)">
  %fd_t0 = arith.constant 1 : i32
  %fd_t1 = arith.constant 6 : i32
  %fd_st = cute.make_stride (%fd_t0, %fd_t1)
       : (i32, i32) -> !cute.stride<"(?,?)">
  %fd = cute.make_layout (%fd_sh, %fd_st)
       : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">) -> !cute.layout<"(?,?):(?,?)">

  %r_g10 = cute.logical_divide(%fd, %b)
       : (!cute.layout<"(?,?):(?,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,?),(4,?)):((?,?),(?,?))">
  cute.print(%r_g10) : !cute.layout<"((3,?),(4,?)):((?,?),(?,?))">

  %r_g11 = cute.logical_divide(%fd, %lt)
       : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"(((?,?),(?,?)),((?,?),(?,?))):(((?,?),(?,?)),((?,?),(?,?)))">
  cute.print(%r_g11) : !cute.layout<"(((?,?),(?,?)),((?,?),(?,?))):(((?,?),(?,?)),((?,?),(?,?)))">

  %r_g12 = cute.logical_divide(%fd, %tt)
       : (!cute.layout<"(?,?):(?,?)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),?),((4),?)):(((?),?),((?),?))">
  cute.print(%r_g12) : !cute.layout<"(((3),?),((4),?)):(((?),?),((?),?))">

  // ===== zipped_divide =====
  %r_zg1 = cute.zipped_divide(%l, %lt)
       : (!cute.layout<"(?,8):(1,?)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"(((?,?),(?,?)),((?,?),(?,?))):(((1,?),(3,?)),((12,?),(?,?)))">
  cute.print(%r_zg1) : !cute.layout<"(((?,?),(?,?)),((?,?),(?,?))):(((1,?),(3,?)),((12,?),(?,?)))">

  %r_zg2 = cute.zipped_divide(%l, %tt)
       : (!cute.layout<"(?,8):(1,?)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),(4)),(?,2)):(((1),(?)),(3,?))">
  cute.print(%r_zg2) : !cute.layout<"(((3),(4)),(?,2)):(((1),(?)),(3,?))">

  %r_zg5 = cute.zipped_divide(%dci, %b)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((3,4),(2,2)):((8,1),(24,4))">
  cute.print(%r_zg5) : !cute.composed_layout<"(?):(?) o ? o ((3,4),(2,2)):((8,1),(24,4))">

  %r_zg6 = cute.zipped_divide(%dci, %lt)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r_zg6) : !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">

  %r_zg7 = cute.zipped_divide(%dci, %tt)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.composed_layout<"(?):(?) o ? o (((3),(4)),(2,2)):(((8),(1)),(24,4))">
  cute.print(%r_zg7) : !cute.composed_layout<"(?):(?) o ? o (((3),(4)),(2,2)):(((8),(1)),(24,4))">

  %r_zg10 = cute.zipped_divide(%fd, %b)
       : (!cute.layout<"(?,?):(?,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),(?,?)):((?,?),(?,?))">
  cute.print(%r_zg10) : !cute.layout<"((3,4),(?,?)):((?,?),(?,?))">

  %r_zg11 = cute.zipped_divide(%fd, %lt)
       : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"(((?,?),(?,?)),((?,?),(?,?))):(((?,?),(?,?)),((?,?),(?,?)))">
  cute.print(%r_zg11) : !cute.layout<"(((?,?),(?,?)),((?,?),(?,?))):(((?,?),(?,?)),((?,?),(?,?)))">

  %r_zg12 = cute.zipped_divide(%fd, %tt)
       : (!cute.layout<"(?,?):(?,?)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),(4)),(?,?)):(((?),(?)),(?,?))">
  cute.print(%r_zg12) : !cute.layout<"(((3),(4)),(?,?)):(((?),(?)),(?,?))">

  // ===== tiled_divide =====
  %r_tg1 = cute.tiled_divide(%l, %lt)
       : (!cute.layout<"(?,8):(1,?)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"(((?,?),(?,?)),(?,?),(?,?)):(((1,?),(3,?)),(12,?),(?,?))">
  cute.print(%r_tg1) : !cute.layout<"(((?,?),(?,?)),(?,?),(?,?)):(((1,?),(3,?)),(12,?),(?,?))">

  %r_tg2 = cute.tiled_divide(%l, %tt)
       : (!cute.layout<"(?,8):(1,?)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),(4)),?,2):(((1),(?)),3,?)">
  cute.print(%r_tg2) : !cute.layout<"(((3),(4)),?,2):(((1),(?)),3,?)">

  %r_tg5 = cute.tiled_divide(%dci, %b)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((3,4),2,2):((8,1),24,4)">
  cute.print(%r_tg5) : !cute.composed_layout<"(?):(?) o ? o ((3,4),2,2):((8,1),24,4)">

  %r_tg6 = cute.tiled_divide(%dci, %lt)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">
  cute.print(%r_tg6) : !cute.composed_layout<"(?):(?) o ? o ((3,(2,2)),4):((8,(24,1)),2)">

  %r_tg7 = cute.tiled_divide(%dci, %tt)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.composed_layout<"(?):(?) o ? o (((3),(4)),2,2):(((8),(1)),24,4)">
  cute.print(%r_tg7) : !cute.composed_layout<"(?):(?) o ? o (((3),(4)),2,2):(((8),(1)),24,4)">

  %r_tg10 = cute.tiled_divide(%fd, %b)
       : (!cute.layout<"(?,?):(?,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"((3,4),?,?):((?,?),?,?)">
  cute.print(%r_tg10) : !cute.layout<"((3,4),?,?):((?,?),?,?)">

  %r_tg11 = cute.tiled_divide(%fd, %lt)
       : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"(((?,?),(?,?)),(?,?),(?,?)):(((?,?),(?,?)),(?,?),(?,?))">
  cute.print(%r_tg11) : !cute.layout<"(((?,?),(?,?)),(?,?),(?,?)):(((?,?),(?,?)),(?,?),(?,?))">

  %r_tg12 = cute.tiled_divide(%fd, %tt)
       : (!cute.layout<"(?,?):(?,?)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"(((3),(4)),?,?):(((?),(?)),?,?)">
  cute.print(%r_tg12) : !cute.layout<"(((3),(4)),?,?):(((?),(?)),?,?)">

  // ===== flat_divide =====
  %r_fg1 = cute.flat_divide(%l, %lt)
       : (!cute.layout<"(?,8):(1,?)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"((?,?),(?,?),(?,?),(?,?)):((1,?),(3,?),(12,?),(?,?))">
  cute.print(%r_fg1) : !cute.layout<"((?,?),(?,?),(?,?),(?,?)):((1,?),(3,?),(12,?),(?,?))">

  %r_fg2 = cute.flat_divide(%l, %tt)
       : (!cute.layout<"(?,8):(1,?)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"((3),(4),?,2):((1),(?),3,?)">
  cute.print(%r_fg2) : !cute.layout<"((3),(4),?,2):((1),(?),3,?)">

  %r_fg5 = cute.flat_divide(%dci, %b)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.shape<"(3,4)">)
        -> !cute.composed_layout<"(?):(?) o ? o (3,4,2,2):(8,1,24,4)">
  cute.print(%r_fg5) : !cute.composed_layout<"(?):(?) o ? o (3,4,2,2):(8,1,24,4)">

  %r_fg6 = cute.flat_divide(%dci, %lt)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.composed_layout<"(?):(?) o ? o (3,(2,2),4):(8,(24,1),2)">
  cute.print(%r_fg6) : !cute.composed_layout<"(?):(?) o ? o (3,(2,2),4):(8,(24,1),2)">

  %r_fg7 = cute.flat_divide(%dci, %tt)
       : (!cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.composed_layout<"(?):(?) o ? o ((3),(4),2,2):((8),(1),24,4)">
  cute.print(%r_fg7) : !cute.composed_layout<"(?):(?) o ? o ((3),(4),2,2):((8),(1),24,4)">

  %r_fg10 = cute.flat_divide(%fd, %b)
       : (!cute.layout<"(?,?):(?,?)">, !cute.shape<"(3,4)">)
        -> !cute.layout<"(3,4,?,?):(?,?,?,?)">
  cute.print(%r_fg10) : !cute.layout<"(3,4,?,?):(?,?,?,?)">

  %r_fg11 = cute.flat_divide(%fd, %lt)
       : (!cute.layout<"(?,?):(?,?)">, !cute.layout<"(3,4):(1,3)">)
        -> !cute.layout<"((?,?),(?,?),(?,?),(?,?)):((?,?),(?,?),(?,?),(?,?))">
  cute.print(%r_fg11) : !cute.layout<"((?,?),(?,?),(?,?),(?,?)):((?,?),(?,?),(?,?),(?,?))">

  %r_fg12 = cute.flat_divide(%fd, %tt)
       : (!cute.layout<"(?,?):(?,?)">, !cute.tile<"[(3):(1);(4):(1)]">)
        -> !cute.layout<"((3),(4),?,?):((?),(?),?,?)">
  cute.print(%r_fg12) : !cute.layout<"((3),(4),?,?):((?),(?),?,?)">

  // tile_to_shape with dyn target shape (?,8) x=6.
  %a5 = cute.static : !cute.layout<"(3,2):(1,3)">
  %sh_b5 = cute.make_shape (%x6) : (i32) -> !cute.shape<"(?,8)">
  %r5 = cute.tile_to_shape(%a5, %sh_b5)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,8)">)
        -> !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">
  cute.print(%r5) : !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">

  // tile_to_shape with same dyn shape + explicit order = (1,0). The
  // swap shifts strides; cutegen now produces a fully-resolved stride
  // (no  annotation needed for either mode).
  %o5 = cute.static : !cute.int_tuple<"(1,0)">
  %r6 = cute.tile_to_shape(%a5, %sh_b5, %o5)
       : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,8)">,
          !cute.int_tuple<"(1,0)">)
        -> !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">
  cute.print(%r6) : !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">

  // logical_product with static input × dyn tiler. Input must be
  // fully static; tiler may be dynamic. Result picks up dyn modes
  // from the tiler (x=2, y=4 → tiler shape (2,4) at runtime).
  %x2 = arith.constant 2 : i32
  %x4 = arith.constant 4 : i32
  %sh_t = cute.make_shape (%x2, %x4)
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

  // logical_product with static input × **fully-dyn** tiler (dyn
  // shape AND dyn stride). Tiler shape (2,4) and tiler stride (4,1)
  // at runtime — non-canonical, distinct from the case above.
  // Result type carries `?` annotations because cutegen knows
  // the input cosize (12) but not the tiler strides.
  %ts0 = arith.constant 4 : i32
  %ts1 = arith.constant 1 : i32
  %dsh = cute.make_shape (%x2, %x4)
        : (i32, i32) -> !cute.shape<"(?,?)">
  %dst = cute.make_stride (%ts0, %ts1)
        : (i32, i32) -> !cute.stride<"(?,?)">
  %t8 = cute.make_layout (%dsh, %dst)
       : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
      -> !cute.layout<"(?,?):(?,?)">
  %r8 = cute.logical_product(%a7, %t8)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
      -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  cute.print(%r8) : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">

  // 5 sibling products with static input × dyn tiler. Reuses `%a7`
  // (static `(3,4):(4,1)`) and `%t7` (dyn `(?,?):(1,2)` with x=2, y=4).
  // Each sibling produces a distinct result layout per its semantics.
  %r_zp = cute.zipped_product(%a7, %t7)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
      -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
  cute.print(%r_zp) : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">

  %r_tp = cute.tiled_product(%a7, %t7)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
      -> !cute.layout<"((3,4),?,?):((4,1),12,24)">
  cute.print(%r_tp) : !cute.layout<"((3,4),?,?):((4,1),12,24)">

  %r_fp = cute.flat_product(%a7, %t7)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
      -> !cute.layout<"(3,4,?,?):(4,1,12,24)">
  cute.print(%r_fp) : !cute.layout<"(3,4,?,?):(4,1,12,24)">

  %r_rp = cute.raked_product(%a7, %t7)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
      -> !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">
  cute.print(%r_rp) : !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">

  %r_bp = cute.blocked_product(%a7, %t7)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
      -> !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">
  cute.print(%r_bp) : !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">

  // 5 sibling products with static input × fully-dyn tiler.
  // Reuses `%a7` and `%t8`; result carries `?` annotations because
  // cutegen knows the input cosize but not the tiler strides at compile time.
  %r_zp2 = cute.zipped_product(%a7, %t8)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
      -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
  cute.print(%r_zp2) : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">

  %r_tp2 = cute.tiled_product(%a7, %t8)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
      -> !cute.layout<"((3,4),?,?):((4,1),?,?)">
  cute.print(%r_tp2) : !cute.layout<"((3,4),?,?):((4,1),?,?)">

  %r_fp2 = cute.flat_product(%a7, %t8)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
      -> !cute.layout<"(3,4,?,?):(4,1,?,?)">
  cute.print(%r_fp2) : !cute.layout<"(3,4,?,?):(4,1,?,?)">

  %r_rp2 = cute.raked_product(%a7, %t8)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
      -> !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">
  cute.print(%r_rp2) : !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">

  %r_bp2 = cute.blocked_product(%a7, %t8)
       : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
      -> !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">
  cute.print(%r_bp2) : !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">

  return
}
