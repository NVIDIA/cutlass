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
// Not-inlined LayoutAlgebra; runtime arith may survive -base-prepare across helper boundaries.
// right_inverse and left_inverse require static input and are excluded.

// CHECK: (5,4):(8,2)
// CHECK: (4,5):(1,4)
// CHECK: ((4,5)):((1,4))
// group_modes on composed input (swizzle-A + dyn B) via helper.
// CHECK: S<3,4,3> o 0 o ((4,5),6):((1,4),20)
// CHECK: (8,32):(1,8)
// recast_layout on composed input — swizzle-A + dyn B upcast via helper.
// CHECK: S<3,3,4> o 0 o (1,5,6):(1,1,5)
// CHECK: (5):(4)
// CHECK: (4):(1)
// slice on composed affine with dyn A + dyn offset + dyn B (via
// helper). crd (0,_) keeps mode 1 of B; offset stays 50.
// CHECK: (4,5):(1,4) o 50 o (3):(8)
// dice on the same composed input. crd (1,_) keeps mode 0 of B.
// CHECK: (4,5):(1,4) o 50 o (8):(1)
// flatten — nested dyn layout via helper at runtime ?=3 → (3,3,5):(8,1,4).
// CHECK: (3,3,5):(8,1,4)
// coalesce — dyn middle blocks static groups on either side from merging.
// CHECK: (20,7,6):(1,9,1)
// complement — rank-1 dyn-stride `(3):(?)` × static shape `12` via
// helper. Runtime stride=2 ⇒ result `(2,2):(1,6)`.
// CHECK: (2,2):(1,6)

//===----------------------------------------------------------------------===//
// Per-op helpers — opaque-arg boundaries.
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

// group_modes on composed-layout input — swizzle-A + dyn B.
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

// Build composed_layout with dyn A + dyn offset + dyn B from runtime
// scalars so the result preserves all three slots as dynamic. Used by
// both `h_slice_composed` and `h_dice_composed` below as their input —
// the multi-slot dyn coverage pins the canonical A o offset o B print
// order for the composed_layout `cute.print` fix.
func.func @h_make_composed_multi_dyn(%a4: i32, %a5: i32, %a1: i32,
                                      %off: i32, %b8: i32, %b3: i32)
    -> !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)"> {
  %a_sh = cute.make_shape(%a4, %a5) : (i32, i32) -> !cute.shape<"(?,?)">
  %a_st = cute.make_stride(%a1, %a4) : (i32, i32) -> !cute.stride<"(?,?)">
  %aly = cute.make_layout(%a_sh, %a_st)
       : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
      -> !cute.layout<"(?,?):(?,?)">
  %off_t = cute.make_int_tuple(%off) : (i32) -> !cute.int_tuple<"?">
  %b_sh = cute.make_shape(%b8, %b3) : (i32, i32) -> !cute.shape<"(?,?)">
  %b_st = cute.make_stride(%a1, %b8) : (i32, i32) -> !cute.stride<"(?,?)">
  %bly = cute.make_layout(%b_sh, %b_st)
       : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
      -> !cute.layout<"(?,?):(?,?)">
  %r = cute.make_composed_layout(%aly, %off_t, %bly)
       : (!cute.layout<"(?,?):(?,?)">, !cute.int_tuple<"?">,
          !cute.layout<"(?,?):(?,?)">)
      -> !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">
  return %r : !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">
}

// slice on a multi-slot dyn composed. crd (0,_): mode-0 of B fixed at
// 0 contributes `0*stride[0]=0` to offset (stays 50 at runtime); B
// sliced to keep mode 1 = (3):(8). Result has 7 dyn leaves spread
// across A/offset/B.
func.func @h_slice_composed(%in: !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">)
    -> !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)"> {
  %crd = cute.static : !cute.coord<"(0,_)">
  %r = cute.slice(%in, %crd)
       : !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">,
         !cute.coord<"(0,_)">
  return %r : !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)">
}

// dice on the same multi-slot dyn composed. crd (1,_): A and offset
// unchanged; B kept at mode 0 = (8):(1). Symmetric to h_slice_composed.
func.func @h_dice_composed(%in: !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">)
    -> !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)"> {
  %crd = cute.static : !cute.coord<"(1,_)">
  %r = cute.dice(%in, %crd)
       : !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">,
         !cute.coord<"(1,_)">
  return %r : !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)">
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
// Entry point — helper-call only.
//===----------------------------------------------------------------------===//

func.func @main() {
  %x20 = arith.constant 20 : i32
  %x2c = arith.constant 2 : i32
  %r1 = func.call @h_composition(%x20, %x2c)
       : (i32, i32) -> !cute.layout<"(5,4):(?,?)">
  cute.print(%r1) : !cute.layout<"(5,4):(?,?)">

  %x4 = arith.constant 4 : i32
  %r2 = func.call @h_coalesce(%x4) : (i32) -> !cute.layout<"(?,5):(1,?)">
  cute.print(%r2) : !cute.layout<"(?,5):(1,?)">
  %r3 = func.call @h_group_modes(%x4) : (i32) -> !cute.layout<"((?,5)):((1,?))">
  cute.print(%r3) : !cute.layout<"((?,5)):((1,?))">
  // group_modes on composed-layout input via helper.
  %r3c = func.call @h_group_modes_composed(%x4)
       : (i32) -> !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">
  cute.print(%r3c) : !cute.composed_layout<"S<3,4,3> o 0 o ((?,5),6):((1,?),?)">

  %x32 = arith.constant 32 : i32
  %r4 = func.call @h_recast_layout(%x32) : (i32) -> !cute.layout<"(8,?):(1,?)">
  cute.print(%r4) : !cute.layout<"(8,?):(1,?)">
  // recast_layout on composed input — swizzle-A + dyn B upcast via helper.
  %r4c = func.call @h_recast_layout_composed(%x4)
       : (i32) -> !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">
  cute.print(%r4c) : !cute.composed_layout<"S<3,3,4> o 0 o (?,5,6):(1,?,?)">

  %r5 = func.call @h_slice(%x4) : (i32) -> !cute.layout<"(5):(?)">
  cute.print(%r5) : !cute.layout<"(5):(?)">
  %r6 = func.call @h_dice(%x4) : (i32) -> !cute.layout<"(?):(1)">
  cute.print(%r6) : !cute.layout<"(?):(1)">

  // slice / dice on multi-slot dyn composed_layout. Helper builds the
  // input with dyn A=(4,5):(1,4), dyn offset=50, dyn B=(8,3):(1,8); the
  // 7-dyn-leaf result type pins the canonical `cute.print` A o offset o B order.
  %x5cc = arith.constant 5 : i32
  %x1cc = arith.constant 1 : i32
  %x50cc = arith.constant 50 : i32
  %x8cc = arith.constant 8 : i32
  %x3cc = arith.constant 3 : i32
  %sd_in = func.call @h_make_composed_multi_dyn(%x4, %x5cc, %x1cc,
                                                 %x50cc, %x8cc, %x3cc)
       : (i32, i32, i32, i32, i32, i32)
      -> !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">
  %r5c = func.call @h_slice_composed(%sd_in)
       : (!cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">)
      -> !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)">
  cute.print(%r5c) : !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)">
  %r6c = func.call @h_dice_composed(%sd_in)
       : (!cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">)
      -> !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)">
  cute.print(%r6c) : !cute.composed_layout<"(?,?):(?,?) o ? o (?):(?)">

  // flatten — nested dyn layout via helper; %x3=3 → (3,3,5):(8,1,4).
  %x3 = arith.constant 3 : i32
  %r_fl = func.call @h_flatten(%x3) : (i32) -> !cute.layout<"(3,?,5):(8,1,4)">
  cute.print(%r_fl) : !cute.layout<"(3,?,5):(8,1,4)">

  %xmid = arith.constant 7 : i32
  %smid = arith.constant 9 : i32
  %r9 = func.call @h_coalesce_dyn_middle(%xmid, %smid)
       : (i32, i32) -> !cute.layout<"(20,?,6):(1,?,1)">
  cute.print(%r9) : !cute.layout<"(20,?,6):(1,?,1)">

  // complement — rank-1 dyn-stride input via helper. Stride=2 ⇒
  // result `(2,2):(1,6)`.
  %r10 = func.call @h_complement(%x2c)
       : (i32) -> !cute.layout<"(?,?):(1,?)">
  cute.print(%r10) : !cute.layout<"(?,?):(1,?)">

  return
}
