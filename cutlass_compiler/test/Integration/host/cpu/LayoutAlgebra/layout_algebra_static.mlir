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
// All-static LayoutAlgebra; cute-fold-static evaluates every op, no arith.* survives.
// RUN: cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:     -base-prepare %s | FileCheck --check-prefix=POST-PREP %s
//
// POST-PREP-NOT: arith.

// End-to-end host integration test covering the LayoutAlgebra category:
// composition, coalesce, complement, group_modes, recast_layout, slice,
// dice, flatten, right_inverse, left_inverse. Direct + helper-call paths.

// CHECK-COUNT-2: (5,4):(8,2)
// composition layout × tile, composed × shape, composed × tile.
// CHECK: ((5,4)):((8,2))
// CHECK: (4,5):(1,4) o 2 o (2,2):(1,4)
// CHECK: (4,5):(1,4) o 2 o ((2,2)):((1,2))
// CHECK-COUNT-2: 20:1
// CHECK-COUNT-2: 2:1
// CHECK-COUNT-2: ((4,5),6):((1,4),20)
// CHECK-COUNT-2: (8,4):(1,8)
// CHECK-COUNT-2: (2,4):(1,6)
// CHECK-COUNT-2: (2):(1)
// CHECK-COUNT-2: (3,4,5):(8,1,4)
// CHECK-COUNT-2: (3,4):(4,1)
// CHECK-COUNT-2: 12:1
// CHECK-COUNT-4: (3,20):(8,1)
// CHECK-COUNT-2: (4,5):(1,4) o 2 o 20:1
// Composed slice (affine A) — fix mode 0 of B at index 1; offset
// accumulates `2 + 1*B_stride[0]=3`. Pins canonical A o offset o B
// print order on a static composed.
// CHECK-COUNT-2: (4,5):(1,4) o 3 o (3):(8)
// Composed dice (affine A) — keep mode 1 of B; A and offset unchanged.
// CHECK-COUNT-2: (4,5):(1,4) o 2 o (3):(8)

//===----------------------------------------------------------------------===//
// Per-op helpers.
//===----------------------------------------------------------------------===//

func.func @h_composition(%outer: !cute.layout<"(20):(2)">,
                         %inner: !cute.layout<"(5,4):(4,1)">)
    -> !cute.layout<"(5,4):(8,2)"> {
  %r = cute.composition(%outer, %inner)
       : (!cute.layout<"(20):(2)">, !cute.layout<"(5,4):(4,1)">) -> !cute.layout<"(5,4):(8,2)">
  return %r : !cute.layout<"(5,4):(8,2)">
}

func.func @h_coalesce(%src: !cute.layout<"(4,5):(1,4)">) -> !cute.layout<"20:1"> {
  %r = cute.coalesce(%src) : (!cute.layout<"(4,5):(1,4)">) -> !cute.layout<"20:1">
  return %r : !cute.layout<"20:1">
}

// Nested static: inner (4,5):(1,4) coalesces to 20:1; outer mode 3:8 kept.
func.func @h_coalesce_nested(%src: !cute.layout<"(3,(4,5)):(8,(1,4))">)
    -> !cute.layout<"(3,20):(8,1)"> {
  %r = cute.coalesce(%src)
       : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,20):(8,1)">
  return %r : !cute.layout<"(3,20):(8,1)">
}

// With target_profile (static): per-top-mode coalesce with profile (1,1)
// yields the same result as the no-profile nested form.
func.func @h_coalesce_with_profile(%src: !cute.layout<"(3,(4,5)):(8,(1,4))">,
                                    %prof: !cute.coord<"(1,1)">)
    -> !cute.layout<"(3,20):(8,1)"> {
  %r = cute.coalesce(%src, %prof)
       : (!cute.layout<"(3,(4,5)):(8,(1,4))">, !cute.coord<"(1,1)">)
      -> !cute.layout<"(3,20):(8,1)">
  return %r : !cute.layout<"(3,20):(8,1)">
}

// Composed layout: coalesce applies only to B; A and offset are preserved.
func.func @h_coalesce_composed(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1"> {
  %r = cute.coalesce(%src)
       : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">)
      -> !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
}

func.func @h_complement(%input: !cute.layout<"3:2">,
                        %co: !cute.shape<"6">) -> !cute.layout<"2:1"> {
  %r = cute.complement(%input, %co) : (!cute.layout<"3:2">, !cute.shape<"6">) -> !cute.layout<"2:1">
  return %r : !cute.layout<"2:1">
}

func.func @h_group_modes(%input: !cute.layout<"(4,5,6):(1,4,20)">)
    -> !cute.layout<"((4,5),6):((1,4),20)"> {
  %r = cute.group_modes<0, 2>(%input)
       : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4,5),6):((1,4),20)">
  return %r : !cute.layout<"((4,5),6):((1,4),20)">
}

func.func @h_recast_layout(%src: !cute.layout<"(32,4):(1,32)">)
    -> !cute.layout<"(8,4):(1,8)"> {
  %r = cute.recast_layout<32, 8>(%src) : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"(8,4):(1,8)">
  return %r : !cute.layout<"(8,4):(1,8)">
}

func.func @h_slice(%src: !cute.layout<"(2,3,4):(1,2,6)">,
                   %crd: !cute.coord<"(_,0,_)">) -> !cute.layout<"(2,4):(1,6)"> {
  %r = cute.slice(%src, %crd) : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,0,_)">
  return %r : !cute.layout<"(2,4):(1,6)">
}

func.func @h_dice(%src: !cute.layout<"(2,3,4):(1,2,6)">,
                  %crd: !cute.coord<"(1,_,_)">) -> !cute.layout<"(2):(1)"> {
  %r = cute.dice(%src, %crd) : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(1,_,_)">
  return %r : !cute.layout<"(2):(1)">
}

// Composed slice — fixing mode 0 of B accumulates `1 * B_stride[0]=1`
// into the offset (`2 + 1 = 3`); B sliced to keep mode 1 = (3):(8).
func.func @h_slice_composed(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
    %crd: !cute.coord<"(1,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 3 o (3):(8)"> {
  %r = cute.slice(%src, %crd)
       : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
         !cute.coord<"(1,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 3 o (3):(8)">
}

// Composed dice — A and offset unchanged; B diced to keep mode 1.
func.func @h_dice_composed(
    %src: !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3,4):(1,8,24)">,
    %crd: !cute.coord<"(_,1,_)">)
    -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(8)"> {
  %r = cute.dice(%src, %crd)
       : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3,4):(1,8,24)">,
         !cute.coord<"(_,1,_)">
  return %r : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(8)">
}

func.func @h_flatten(%src: !cute.layout<"(3,(4,5)):(8,(1,4))">)
    -> !cute.layout<"(3,4,5):(8,1,4)"> {
  %r = cute.flatten(%src)
       : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,4,5):(8,1,4)">
  return %r : !cute.layout<"(3,4,5):(8,1,4)">
}

func.func @h_right_inverse(%src: !cute.layout<"(4,3):(3,1)">)
    -> !cute.layout<"(3,4):(4,1)"> {
  %r = cute.right_inverse(%src) : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">
  return %r : !cute.layout<"(3,4):(4,1)">
}

func.func @h_left_inverse(%src: !cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1"> {
  %r = cute.left_inverse(%src) : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1">
  return %r : !cute.layout<"12:1">
}

//===----------------------------------------------------------------------===//
// Entry point.
//===----------------------------------------------------------------------===//

func.func @main() {
  // composition — (20):(2) ∘ (5,4):(4,1) = (5,4):(8,2)
  %o1 = cute.static : !cute.layout<"(20):(2)">
  %i1 = cute.static : !cute.layout<"(5,4):(4,1)">
  %r1 = cute.composition(%o1, %i1)
       : (!cute.layout<"(20):(2)">, !cute.layout<"(5,4):(4,1)">) -> !cute.layout<"(5,4):(8,2)">
  cute.print(%r1) : !cute.layout<"(5,4):(8,2)">
  %r1b = func.call @h_composition(%o1, %i1)
       : (!cute.layout<"(20):(2)">, !cute.layout<"(5,4):(4,1)">) -> !cute.layout<"(5,4):(8,2)">
  cute.print(%r1b) : !cute.layout<"(5,4):(8,2)">

  // composition layout × tile — tile wraps inner layout; result is the
  // hierarchical form `((5,4)):((8,2))`.
  %i1t = cute.static : !cute.tile<"[(5,4):(4,1)]">
  %r1_lt = cute.composition(%o1, %i1t)
       : (!cute.layout<"(20):(2)">, !cute.tile<"[(5,4):(4,1)]">)
      -> !cute.layout<"((5,4)):((8,2))">
  cute.print(%r1_lt) : !cute.layout<"((5,4)):((8,2))">

  // composition composed × shape — composition applies to the B part of
  // the composed layout; A and offset are preserved.
  %oc = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">
  %sh22 = cute.static : !cute.shape<"(2,2)">
  %r1_cs = cute.composition(%oc, %sh22)
       : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">,
          !cute.shape<"(2,2)">)
      -> !cute.composed_layout<"(4,5):(1,4) o 2 o (2,2):(1,4)">
  cute.print(%r1_cs) : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,2):(1,4)">

  // composition composed × tile — same as composed × shape but the inner
  // is tile-wrapped; B is replaced by the hierarchical tile-wrap result.
  %tl22 = cute.static : !cute.tile<"[(2,2):(1,2)]">
  %r1_ct = cute.composition(%oc, %tl22)
       : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">,
          !cute.tile<"[(2,2):(1,2)]">)
      -> !cute.composed_layout<"(4,5):(1,4) o 2 o ((2,2)):((1,2))">
  cute.print(%r1_ct) : !cute.composed_layout<"(4,5):(1,4) o 2 o ((2,2)):((1,2))">

  // coalesce — collapse contiguous col-major modes.
  %s2 = cute.static : !cute.layout<"(4,5):(1,4)">
  %r2 = cute.coalesce(%s2) : (!cute.layout<"(4,5):(1,4)">) -> !cute.layout<"20:1">
  cute.print(%r2) : !cute.layout<"20:1">
  %r2b = func.call @h_coalesce(%s2)
       : (!cute.layout<"(4,5):(1,4)">) -> !cute.layout<"20:1">
  cute.print(%r2b) : !cute.layout<"20:1">

  // complement — produces a layout filling the gap in cosize.
  %s3 = cute.static : !cute.layout<"3:2">
  %co = cute.static : !cute.shape<"6">
  %r3 = cute.complement(%s3, %co)
       : (!cute.layout<"3:2">, !cute.shape<"6">) -> !cute.layout<"2:1">
  cute.print(%r3) : !cute.layout<"2:1">
  %r3b = func.call @h_complement(%s3, %co)
       : (!cute.layout<"3:2">, !cute.shape<"6">) -> !cute.layout<"2:1">
  cute.print(%r3b) : !cute.layout<"2:1">

  // group_modes — wrap a contiguous range of modes into a sub-tuple.
  %s4 = cute.static : !cute.layout<"(4,5,6):(1,4,20)">
  %r4 = cute.group_modes<0, 2>(%s4)
       : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4,5),6):((1,4),20)">
  cute.print(%r4) : !cute.layout<"((4,5),6):((1,4),20)">
  %r4b = func.call @h_group_modes(%s4)
       : (!cute.layout<"(4,5,6):(1,4,20)">) -> !cute.layout<"((4,5),6):((1,4),20)">
  cute.print(%r4b) : !cute.layout<"((4,5),6):((1,4),20)">

  // recast_layout — rescale by element-bit ratio.
  %s5 = cute.static : !cute.layout<"(32,4):(1,32)">
  %r5 = cute.recast_layout<32, 8>(%s5)
       : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"(8,4):(1,8)">
  cute.print(%r5) : !cute.layout<"(8,4):(1,8)">
  %r5b = func.call @h_recast_layout(%s5)
       : (!cute.layout<"(32,4):(1,32)">) -> !cute.layout<"(8,4):(1,8)">
  cute.print(%r5b) : !cute.layout<"(8,4):(1,8)">

  // slice — extract sub-layout for the underscore positions of a coord.
  %s6 = cute.static : !cute.layout<"(2,3,4):(1,2,6)">
  %crd_s = cute.static : !cute.coord<"(_,0,_)">
  %r6 = cute.slice(%s6, %crd_s) : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,0,_)">
  cute.print(%r6) : !cute.layout<"(2,4):(1,6)">
  %r6b = func.call @h_slice(%s6, %crd_s)
       : (!cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,0,_)">) -> !cute.layout<"(2,4):(1,6)">
  cute.print(%r6b) : !cute.layout<"(2,4):(1,6)">

  // dice — extract sub-layout for the non-underscore positions.
  %s7 = cute.static : !cute.layout<"(2,3,4):(1,2,6)">
  %crd_d = cute.static : !cute.coord<"(1,_,_)">
  %r7 = cute.dice(%s7, %crd_d) : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(1,_,_)">
  cute.print(%r7) : !cute.layout<"(2):(1)">
  %r7b = func.call @h_dice(%s7, %crd_d)
       : (!cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(1,_,_)">) -> !cute.layout<"(2):(1)">
  cute.print(%r7b) : !cute.layout<"(2):(1)">

  // flatten — collapse a layout's mode hierarchy to depth 1.
  %sf = cute.static : !cute.layout<"(3,(4,5)):(8,(1,4))">
  %rf = cute.flatten(%sf)
       : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,4,5):(8,1,4)">
  cute.print(%rf) : !cute.layout<"(3,4,5):(8,1,4)">
  %rfb = func.call @h_flatten(%sf)
       : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,4,5):(8,1,4)">
  cute.print(%rfb) : !cute.layout<"(3,4,5):(8,1,4)">

  // right_inverse — for non-bijective layouts, the right pseudo-inverse.
  %s10 = cute.static : !cute.layout<"(4,3):(3,1)">
  %r10 = cute.right_inverse(%s10)
       : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">
  cute.print(%r10) : !cute.layout<"(3,4):(4,1)">
  %r10b = func.call @h_right_inverse(%s10)
       : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">
  cute.print(%r10b) : !cute.layout<"(3,4):(4,1)">

  // left_inverse — for bijective layouts, the inverse.
  %s11 = cute.static : !cute.layout<"(4,3):(1,4)">
  %r11 = cute.left_inverse(%s11)
       : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1">
  cute.print(%r11) : !cute.layout<"12:1">
  %r11b = func.call @h_left_inverse(%s11)
       : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1">
  cute.print(%r11b) : !cute.layout<"12:1">

  // coalesce — nested static. Inner (4,5):(1,4) merges to 20:1, outer
  // mode 3:8 kept.
  %s12 = cute.static : !cute.layout<"(3,(4,5)):(8,(1,4))">
  %r12 = cute.coalesce(%s12)
       : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,20):(8,1)">
  cute.print(%r12) : !cute.layout<"(3,20):(8,1)">
  %r12b = func.call @h_coalesce_nested(%s12)
       : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,20):(8,1)">
  cute.print(%r12b) : !cute.layout<"(3,20):(8,1)">

  // coalesce — with target_profile (static). Profile (1,1) selects
  // per-top-mode coalescing; result equals the nested-static case.
  %p13 = cute.static : !cute.coord<"(1,1)">
  %r13 = cute.coalesce(%s12, %p13)
       : (!cute.layout<"(3,(4,5)):(8,(1,4))">, !cute.coord<"(1,1)">)
      -> !cute.layout<"(3,20):(8,1)">
  cute.print(%r13) : !cute.layout<"(3,20):(8,1)">
  %r13b = func.call @h_coalesce_with_profile(%s12, %p13)
       : (!cute.layout<"(3,(4,5)):(8,(1,4))">, !cute.coord<"(1,1)">)
      -> !cute.layout<"(3,20):(8,1)">
  cute.print(%r13b) : !cute.layout<"(3,20):(8,1)">

  // coalesce — composed_layout. Applies only to B; A and offset preserved.
  %s14 = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">
  %r14 = cute.coalesce(%s14)
       : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">)
      -> !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
  cute.print(%r14) : !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
  %r14b = func.call @h_coalesce_composed(%s14)
       : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">)
      -> !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
  cute.print(%r14b) : !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">

  // slice — composed_layout (affine A). Fixing mode 0 at index 1
  // accumulates `1 * B_stride[0] = 1` into the offset (2 → 3); B
  // sliced to keep mode 1 = (3):(8).
  %s15 = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">
  %crd_sc = cute.static : !cute.coord<"(1,_)">
  %r15 = cute.slice(%s15, %crd_sc)
       : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
         !cute.coord<"(1,_)">
  cute.print(%r15) : !cute.composed_layout<"(4,5):(1,4) o 3 o (3):(8)">
  %r15b = func.call @h_slice_composed(%s15, %crd_sc)
       : (!cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
          !cute.coord<"(1,_)">)
      -> !cute.composed_layout<"(4,5):(1,4) o 3 o (3):(8)">
  cute.print(%r15b) : !cute.composed_layout<"(4,5):(1,4) o 3 o (3):(8)">

  // dice — composed_layout (affine A). A and offset unchanged; B
  // diced to keep mode 1 = (3):(8).
  %s16 = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3,4):(1,8,24)">
  %crd_dc = cute.static : !cute.coord<"(_,1,_)">
  %r16 = cute.dice(%s16, %crd_dc)
       : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3,4):(1,8,24)">,
         !cute.coord<"(_,1,_)">
  cute.print(%r16) : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(8)">
  %r16b = func.call @h_dice_composed(%s16, %crd_dc)
       : (!cute.composed_layout<"(4,5):(1,4) o 2 o (8,3,4):(1,8,24)">,
          !cute.coord<"(_,1,_)">)
      -> !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(8)">
  cute.print(%r16b) : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(8)">

  return
}
