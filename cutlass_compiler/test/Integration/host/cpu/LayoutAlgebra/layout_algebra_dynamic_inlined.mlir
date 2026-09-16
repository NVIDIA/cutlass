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
// Dynamic LayoutAlgebra, ops inlined in @main; static leaves fold through -base-prepare.
//
// RUN: cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:     -base-prepare %s | FileCheck --check-prefix=POST-PREP %s
//
// After -base-prepare only arith.constant may remain:
// POST-PREP-NOT: arith.{{[^c]}}
// POST-PREP-NOT: arith.c{{[^o]}}

// CHECK: (5,4):(8,2)
// composition variants: layout × tile, composed × shape, composed × tile.
// CHECK: ((5,4)):((8,2))
// CHECK: S<3,5,4> o 0 o 4:2
// CHECK: S<3,5,4> o 0 o (4):(2)
// CHECK: (4,5):(1,4)
// CHECK: ((4,5)):((1,4))
// group_modes on composed input — swizzle-A + dyn B (compact stride
// for shape (?,5,6) with x=4 gives B = (4,5,6):(1,4,20)).
// CHECK: S<3,4,3> o 0 o ((4,5),6):((1,4),20)
// CHECK: (8,32):(1,8)
// recast_layout on composed input — swizzle-A + dyn B upcast.
// CHECK: S<3,3,4> o 0 o (1,5,6):(1,1,5)
// CHECK: (5):(4)
// CHECK: (4):(1)
// slice on composed affine with dyn A + dyn offset + dyn B (7 dyn
// leaves in the result, spread across A/offset/B). Pins the
// composed_layout `cute.print` dyn-leaf ordering fix — must print in
// canonical A o offset o B order. crd (0,_): mode-0 fix contributes
// `0*A_stride[0]=0` to offset, so offset stays 50.
// CHECK: (4,5):(1,4) o 50 o (3):(8)
// dice on the same input. crd (1,_): A and offset unchanged; B is
// diced to keep mode 0 = (8):(1). Symmetric to the slice case above
// for verifying canonical A o offset o B print order.
// CHECK: (4,5):(1,4) o 50 o (8):(1)
// flatten — nested dyn layout (3,(?,5)):(8,(1,4)) at runtime ?=3 → (3,3,5):(8,1,4).
// CHECK: (3,3,5):(8,1,4)
// coalesce — dyn middle blocks static groups on either side from merging.
// CHECK: (20,7,6):(1,9,1)
// complement — rank-1 dyn-stride `(3):(?)` × static shape `12`. With
// runtime stride=2, the result `(?,?):(1,?)` becomes (2,2):(1,6).
// CHECK: (2,2):(1,6)

func.func @main() {
  // composition — dyn outer (?:?) ∘ static inner (5,4):(4,1).
  // With outer = 20:2, inner = (5,4):(4,1) ⇒ result (5,4):(8,2).
  %x20 = arith.constant 20 : i32
  %x2c = arith.constant 2 : i32
  %sh_o = cute.make_shape (%x20) : (i32) -> !cute.shape<"?">
  %st_o = cute.make_stride (%x2c) : (i32) -> !cute.stride<"?">
  %outer = cute.make_layout (%sh_o, %st_o)
        : (!cute.shape<"?">, !cute.stride<"?">) -> !cute.layout<"?:?">
  %inner = cute.static : !cute.layout<"(5,4):(4,1)">
  %r1 = cute.composition(%outer, %inner)
       : (!cute.layout<"?:?">, !cute.layout<"(5,4):(4,1)">) -> !cute.layout<"(5,4):(?,?)">
  cute.print(%r1) : !cute.layout<"(5,4):(?,?)">

  // composition layout × tile dyn — tile wraps the inner layout, so the
  // result is hierarchical `((5,4)):((8,2))` at runtime.
  %t_lt = cute.static : !cute.tile<"[(5,4):(4,1)]">
  %r_lt = cute.composition(%outer, %t_lt)
       : (!cute.layout<"?:?">, !cute.tile<"[(5,4):(4,1)]">)
      -> !cute.layout<"((5,4)):((?,?))">
  cute.print(%r_lt) : !cute.layout<"((5,4)):((?,?))">

  // Build a dyn composed_layout: swizzle A + zero offset + dyn B (`?:?`).
  // Reuses %outer above as the dyn B component.
  %sw_a = cute.static : !cute.swizzle<"S<3,5,4>">
  %off0 = cute.static : !cute.int_tuple<"0">
  %comp_outer = cute.make_composed_layout(%sw_a, %off0, %outer)
        : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"0">, !cute.layout<"?:?">)
        -> !cute.composed_layout<"S<3,5,4> o 0 o ?:?">

  // composition composed × shape dyn — composition applies to B only.
  // B = 20:2; B ∘ shape 4 = 4:2 (cutegen truncates B's domain). Runtime
  // print: `S<3,5,4> o 0 o 4:2`.
  %sh4 = cute.static : !cute.shape<"4">
  %r_cs = cute.composition(%comp_outer, %sh4)
       : (!cute.composed_layout<"S<3,5,4> o 0 o ?:?">, !cute.shape<"4">)
      -> !cute.composed_layout<"S<3,5,4> o 0 o 4:?">
  cute.print(%r_cs) : !cute.composed_layout<"S<3,5,4> o 0 o 4:?">

  // composition composed × tile dyn — same as composed × shape but the
  // inner is a tile wrap; result B is tile-wrapped to `(4):(2)` at runtime.
  %t_ct = cute.static : !cute.tile<"[4:1]">
  %r_ct = cute.composition(%comp_outer, %t_ct)
       : (!cute.composed_layout<"S<3,5,4> o 0 o ?:?">, !cute.tile<"[4:1]">)
      -> !cute.composed_layout<"S<3,5,4> o 0 o (4):(?)">
  cute.print(%r_ct) : !cute.composed_layout<"S<3,5,4> o 0 o (4):(?)">

  // Build the dyn 2D layout used by the next several ops.
  %x4 = arith.constant 4 : i32
  %sh = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,5)">
  %l_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
  %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  // coalesce — for `(?,5):(1,?)`, the cute type system cannot prove the
  // contiguity condition statically, so coalesce returns the input
  // unchanged. The lowering still preserves the dyn leaves.
  %r2 = cute.coalesce(%l) : (!cute.layout<"(?,5):(1,?)">) -> !cute.layout<"(?,5):(1,?)">
  cute.print(%r2) : !cute.layout<"(?,5):(1,?)">

  // group_modes — wrap modes [0, 2) into a sub-tuple.
  %r3 = cute.group_modes<0, 2>(%l)
       : (!cute.layout<"(?,5):(1,?)">) -> !cute.layout<"((?,5)):((1,?))">
  cute.print(%r3) : !cute.layout<"((?,5)):((1,?))">

  // group_modes on composed-layout input — swizzle-A + dyn B.
  // Build composed via `make_composed_layout` with static swizzle,
  // static offset 0, and dyn B from %x4 (compact stride; the third
  // stride leaf carries a  annotation reflecting
  // shape[0]*shape[1]). With x=4 the runtime B is (4,5,6):(1,4,20).
  %gm_co_sw = cute.static : !cute.swizzle<"S<3,4,3>">
  %gm_co_off = cute.static : !cute.int_tuple<"0">
  %gm_co_sh = cute.make_shape (%x4)
       : (i32) -> !cute.shape<"(?,5,6)">
  %c5_for_gm_co_b_stride = arith.constant 5 : i32
  %gm_co_b_stride_mul = arith.muli %x4, %c5_for_gm_co_b_stride : i32
  %gm_co_b_stride = cute.make_stride (%x4, %gm_co_b_stride_mul) : (i32, i32) -> !cute.stride<"(1,?,?)">
  %gm_co_b = cute.make_layout (%gm_co_sh, %gm_co_b_stride) : (!cute.shape<"(?,5,6)">, !cute.stride<"(1,?,?)">) -> !cute.layout<"(?,5,6):(1,?,?)">
  %gm_co_in = cute.make_composed_layout(%gm_co_sw, %gm_co_off, %gm_co_b)
       : (!cute.swizzle<"S<3,4,3>">, !cute.int_tuple<"0">,
          !cute.layout<"(?,5,6):(1,?,?)">)
      -> !cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,?)">
  %r_co_gm = cute.group_modes<0, 2>(%gm_co_in)
       : (!cute.composed_layout<"S<3,4,3> o 0 o (?,5,6):(1,?,?)">)
      -> !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">
  cute.print(%r_co_gm) : !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">

  // recast_layout — rescale by element-bit ratio. Dyn (32,?):(1,?) → (8,?):(1,?).
  %x32 = arith.constant 32 : i32
  %sh32 = cute.make_shape (%x32) : (i32) -> !cute.shape<"(32,?)">
  %st32 = cute.make_stride (%x32) : (i32) -> !cute.stride<"(1,?)">
  %lr = cute.make_layout (%sh32, %st32)
        : (!cute.shape<"(32,?)">, !cute.stride<"(1,?)">) -> !cute.layout<"(32,?):(1,?)">
  %r4 = cute.recast_layout<32, 8>(%lr)
       : !cute.layout<"(32,?):(1,?)"> -> !cute.layout<"(8,?):(1,?)">
  cute.print(%r4) : !cute.layout<"(8,?):(1,?)">

  // recast_layout on composed input — swizzle-A + dyn B. Upcast
  // 32→8 (R=4) shifts the swizzle's num_base by log2(4)=2 and
  // scales the B layout. With %x4=4 the input B is (4,5,6):(1,4,20);
  // after upcast B = (1,5,6):(1,1,5) and swizzle S<3,5,4> → S<3,3,4>.
  %rl_co_sw = cute.static : !cute.swizzle<"S<3,5,4>">
  %rl_co_off = cute.static : !cute.int_tuple<"0">
  %rl_co_sh = cute.make_shape (%x4)
        : (i32) -> !cute.shape<"(?,5,6)">
  %c5_for_rl_co_b_stride = arith.constant 5 : i32
  %rl_co_b_stride_mul = arith.muli %x4, %c5_for_rl_co_b_stride : i32
  %rl_co_b_stride = cute.make_stride (%x4, %rl_co_b_stride_mul) : (i32, i32) -> !cute.stride<"(1,?,?)">
  %rl_co_b = cute.make_layout (%rl_co_sh, %rl_co_b_stride) : (!cute.shape<"(?,5,6)">, !cute.stride<"(1,?,?)">) -> !cute.layout<"(?,5,6):(1,?,?)">
  %rl_co_in = cute.make_composed_layout(%rl_co_sw, %rl_co_off, %rl_co_b)
        : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"0">,
           !cute.layout<"(?,5,6):(1,?,?)">)
       -> !cute.composed_layout<"S<3,5,4> o 0 o (?,5,6):(1,?,?)">
  %r_rl_co = cute.recast_layout<32, 8>(%rl_co_in)
        : !cute.composed_layout<"S<3,5,4> o 0 o (?,5,6):(1,?,?)">
       -> !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">
  cute.print(%r_rl_co) : !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">

  // slice — keep the underscore positions; crd (0,_) keeps mode 1.
  %crd_s = cute.static : !cute.coord<"(0,_)">
  %r5 = cute.slice(%l, %crd_s) : !cute.layout<"(?,5):(1,?)">, !cute.coord<"(0,_)">
  cute.print(%r5) : !cute.layout<"(5):(?)">

  // dice — keep the non-underscore positions; crd (1,_) keeps mode 0.
  %crd_d = cute.static : !cute.coord<"(1,_)">
  %r6 = cute.dice(%l, %crd_d) : !cute.layout<"(?,5):(1,?)">, !cute.coord<"(1,_)">
  cute.print(%r6) : !cute.layout<"(?):(1)">

  // slice / dice on a composed_layout with **dyn A + dyn offset + dyn B**.
  // The result has 7 dyn leaves spread across all three slots, so the
  // composed_layout `cute.print` dyn-leaf ordering matters — must print
  // in canonical A o offset o B order.
  // Build composed input with concrete runtime values:
  //   A = (4,5):(1,4), offset = 50, B = (8,3):(1,8).
  %x5c = arith.constant 5 : i32
  %x1c = arith.constant 1 : i32
  %x50c = arith.constant 50 : i32
  %x8c = arith.constant 8 : i32
  %x3c = arith.constant 3 : i32
  %sd_a_sh = cute.make_shape(%x4, %x5c)
       : (i32, i32) -> !cute.shape<"(?,?)">
  %sd_a_st = cute.make_stride(%x1c, %x4)
       : (i32, i32) -> !cute.stride<"(?,?)">
  %sd_a = cute.make_layout(%sd_a_sh, %sd_a_st)
       : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
      -> !cute.layout<"(?,?):(?,?)">
  %sd_off = cute.make_int_tuple(%x50c) : (i32) -> !cute.int_tuple<"?">
  %sd_b_sh = cute.make_shape(%x8c, %x3c)
       : (i32, i32) -> !cute.shape<"(?,?)">
  %sd_b_st = cute.make_stride(%x1c, %x8c)
       : (i32, i32) -> !cute.stride<"(?,?)">
  %sd_b = cute.make_layout(%sd_b_sh, %sd_b_st)
       : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
      -> !cute.layout<"(?,?):(?,?)">
  %sd_in = cute.make_composed_layout(%sd_a, %sd_off, %sd_b)
       : (!cute.layout<"(?,?):(?,?)">, !cute.int_tuple<"?">,
          !cute.layout<"(?,?):(?,?)">)
      -> !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">

  // slice with crd (0,_): mode-0 of B fixed at 0 contributes
  // `0 * stride[0] = 0` to offset (so offset stays 50). B sliced to
  // keep mode 1 = (3):(8). Result type carries 7 dyn leaves across
  // A/offset/B; the printed form must use the canonical order.
  %crd_sc = cute.static : !cute.coord<"(0,_)">
  %r_sc = cute.slice(%sd_in, %crd_sc)
       : !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">,
         !cute.coord<"(0,_)">
  cute.print(%r_sc) : !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)">

  // dice with crd (1,_): A and offset unchanged; B kept at mode 0 =
  // (8):(1). Same 7-dyn-leaves result type pinning the canonical
  // print order from a different op.
  %crd_dc = cute.static : !cute.coord<"(1,_)">
  %r_dc = cute.dice(%sd_in, %crd_dc)
       : !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">,
         !cute.coord<"(1,_)">
  cute.print(%r_dc) : !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)">

  // flatten — collapse a nested dyn layout to depth 1. With %x3=3 the
  // result prints as `(3,3,5):(8,1,4)`.
  %x3 = arith.constant 3 : i32
  %fl_sh = cute.make_shape (%x3) : (i32) -> !cute.shape<"(3,(?,5))">
  %fl_st = cute.static : !cute.stride<"(8,(1,4))">
  %fl_in = cute.make_layout (%fl_sh, %fl_st)
        : (!cute.shape<"(3,(?,5))">, !cute.stride<"(8,(1,4))">)
       -> !cute.layout<"(3,(?,5)):(8,(1,4))">
  %r_fl = cute.flatten(%fl_in)
        : (!cute.layout<"(3,(?,5)):(8,(1,4))">) -> !cute.layout<"(3,?,5):(8,1,4)">
  cute.print(%r_fl) : !cute.layout<"(3,?,5):(8,1,4)">

  // coalesce — dyn middle mode blocks merge. Static groups on either side
  // coalesce independently — (4,5):(1,4) → 20:1 and (3,2):(1,3) → 6:1 —
  // while the dyn middle stays as-is.
  %xmid = arith.constant 7 : i32
  %smid = arith.constant 9 : i32
  %sh_m = cute.make_shape (%xmid) : (i32) -> !cute.shape<"(4,5,?,3,2)">
  %st_m = cute.make_stride (%smid) : (i32) -> !cute.stride<"(1,4,?,1,3)">
  %lm = cute.make_layout (%sh_m, %st_m)
       : (!cute.shape<"(4,5,?,3,2)">, !cute.stride<"(1,4,?,1,3)">)
      -> !cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">
  %r9 = cute.coalesce(%lm)
       : (!cute.layout<"(4,5,?,3,2):(1,4,?,1,3)">) -> !cute.layout<"(20,?,6):(1,?,1)">
  cute.print(%r9) : !cute.layout<"(20,?,6):(1,?,1)">

  // complement — rank-1 dyn-stride input `(3):(?)` with stride=2 at
  // runtime × static shape `12`. The dyn-stride carve-out permits
  // rank-1 layouts to carry a single dyn leaf.
  %cmp_st = arith.constant 2 : i32
  %cmp_st_v = cute.make_stride (%cmp_st) : (i32) -> !cute.stride<"(?)">
  %cmp_sh = cute.static : !cute.shape<"(3)">
  %cmp_in = cute.make_layout (%cmp_sh, %cmp_st_v)
        : (!cute.shape<"(3)">, !cute.stride<"(?)">) -> !cute.layout<"(3):(?)">
  %cmp_co = cute.static : !cute.shape<"12">
  %r10 = cute.complement(%cmp_in, %cmp_co)
       : (!cute.layout<"(3):(?)">, !cute.shape<"12">)
      -> !cute.layout<"(?,?):(1,?)">
  cute.print(%r10) : !cute.layout<"(?,?):(1,?)">

  return
}
