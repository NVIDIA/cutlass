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
// All-static Accessors; cute-fold-static evaluates every op, no arith.* survives.
// RUN: cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:     -base-prepare %s | FileCheck --check-prefix=POST-PREP %s
//
// POST-PREP-NOT: arith.

// Each op runs via direct inline and helper-call paths, with distinct values
// per op so CHECK lines don't collide.
// Single-result ops: direct + helper print consecutively → COUNT-2.
// Multi-result ops: per-result prints interleave; each gets its own CHECK.
//
// CHECK-COUNT-2: (2,7)
// CHECK-COUNT-2: (2,9)
// CHECK-COUNT-2: 11:1
// CHECK: 17
// CHECK: 19
// CHECK: 23
// CHECK: 17
// CHECK: 19
// CHECK: 23
// CHECK: (29,31):(1,29)
// CHECK: (37,41):(1,37)
// CHECK: (29,31):(1,29)
// CHECK: (37,41):(1,37)
// CHECK-COUNT-2: (43,47):(1,43)
// CHECK-COUNT-2: 53
// CHECK-COUNT-2: (2,4):(1,2)
// CHECK-COUNT-2: (61):(59)
// CHECK-COUNT-2: (71,73)
// CHECK-COUNT-2: (89,97)
// CHECK-COUNT-2: (109@0,1@1)
// CHECK-COUNT-2: S<2,3,5>
// CHECK-COUNT-2: 113
// CHECK-COUNT-2: (127,131):(1,127)
// CHECK-COUNT-2: (151,139):(20711,1)
// CHECK-COUNT-2: [_;(167,173):(1,167)]
// CHECK-COUNT-2: (179,181):(1,179) o 0 o (193,191):(191,1)
// CHECK-COUNT-2: (199,197):(1@1,1@0)
// CHECK-COUNT-2: ()
// CHECK-COUNT-2: (229,229)
// CHECK-COUNT-2: (239,241)
// CHECK-COUNT-2: (251,257)
// CHECK-COUNT-2: (263,269)
// CHECK-COUNT-2: (271,(277,281),283)
// CHECK-COUNT-2: (293,307):(1,293)
// CHECK: 311:1
// CHECK: 313:1
// CHECK: 317:1
// CHECK: 331:1
// CHECK: 311:1
// CHECK: 313:1
// CHECK: 317:1
// CHECK: 331:1

//===----------------------------------------------------------------------===//
// Per-op helpers: take the cute-typed input as an argument, run the
// accessor op, and return the result. Multi-result ops return a tuple
// of cute values.
//===----------------------------------------------------------------------===//

func.func @h_get_shape(%l: !cute.layout<"(2,7):(1,2)">) -> !cute.shape<"(2,7)"> {
  %r = cute.get_shape(%l) : !cute.layout<"(2,7):(1,2)"> -> !cute.shape<"(2,7)">
  return %r : !cute.shape<"(2,7)">
}

func.func @h_get_stride(%l: !cute.layout<"(3,5):(2,9)">) -> !cute.stride<"(2,9)"> {
  %r = cute.get_stride(%l) : !cute.layout<"(3,5):(2,9)"> -> !cute.stride<"(2,9)">
  return %r : !cute.stride<"(2,9)">
}

func.func @h_get(%l: !cute.layout<"(11,13):(1,11)">) -> !cute.layout<"11:1"> {
  %r = cute.get<[0]> (%l) : !cute.layout<"(11,13):(1,11)"> -> !cute.layout<"11:1">
  return %r : !cute.layout<"11:1">
}

func.func @h_get_leaves(%s: !cute.shape<"(17,(19,23))">)
    -> (!cute.shape<"17">, !cute.shape<"19">, !cute.shape<"23">) {
  %a, %b, %c = cute.get_leaves(%s) : !cute.shape<"(17,(19,23))">
  return %a, %b, %c : !cute.shape<"17">, !cute.shape<"19">, !cute.shape<"23">
}

func.func @h_get_layouts_from_tile(%t: !cute.tile<"[(29,31):(1,29);(37,41):(1,37)]">)
    -> (!cute.layout<"(29,31):(1,29)">, !cute.layout<"(37,41):(1,37)">) {
  %a, %b = cute.get_layouts_from_tile(%t)
         : !cute.tile<"[(29,31):(1,29);(37,41):(1,37)]">
  return %a, %b : !cute.layout<"(29,31):(1,29)">, !cute.layout<"(37,41):(1,37)">
}

func.func @h_composed_get_inner(%cl: !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">)
    -> !cute.layout<"(43,47):(1,43)"> {
  %r = cute.composed_get_inner(%cl)
     : !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">
    -> !cute.layout<"(43,47):(1,43)">
  return %r : !cute.layout<"(43,47):(1,43)">
}

func.func @h_composed_get_offset(%cl: !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">)
    -> !cute.int_tuple<"53"> {
  %r = cute.composed_get_offset(%cl)
     : !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">
    -> !cute.int_tuple<"53">
  return %r : !cute.int_tuple<"53">
}

func.func @h_composed_get_outer(%cl: !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">)
    -> !cute.layout<"(2,4):(1,2)"> {
  %r = cute.composed_get_outer(%cl)
     : !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">
    -> !cute.layout<"(2,4):(1,2)">
  return %r : !cute.layout<"(2,4):(1,2)">
}

func.func @h_select(%l: !cute.layout<"(59,61,67):(1,59,3599)">)
    -> !cute.layout<"(61):(59)"> {
  %r = cute.select<[1]> (%l) : !cute.layout<"(59,61,67):(1,59,3599)">
                            -> !cute.layout<"(61):(59)">
  return %r : !cute.layout<"(61):(59)">
}

func.func @h_to_int_tuple(%s: !cute.shape<"(71,73)">) -> !cute.int_tuple<"(71,73)"> {
  %r = cute.to_int_tuple(%s) : !cute.shape<"(71,73)"> -> !cute.int_tuple<"(71,73)">
  return %r : !cute.int_tuple<"(71,73)">
}

// ComposedLayout source for get_shape: exercises the
// ComposedLayoutType branch (outer B's shape).
func.func @h_get_shape_composed(%cl: !cute.composed_layout<"S<3,4,3> o 0 o (89,97):(1,89)">)
    -> !cute.shape<"(89,97)"> {
  %r = cute.get_shape(%cl)
       : !cute.composed_layout<"S<3,4,3> o 0 o (89,97):(1,89)"> -> !cute.shape<"(89,97)">
  return %r : !cute.shape<"(89,97)">
}

// Scaled-basis stride for get_stride: validates basis strides flow
// through the lowering / codegen pipeline unchanged.
func.func @h_get_stride_basis(%l: !cute.layout<"(101,103):(109@0,1@1)">)
    -> !cute.stride<"(109@0,1@1)"> {
  %r = cute.get_stride(%l)
       : !cute.layout<"(101,103):(109@0,1@1)"> -> !cute.stride<"(109@0,1@1)">
  return %r : !cute.stride<"(109@0,1@1)">
}

// composed_get_inner on a swizzle-A composed layout: exercises the
// `is_a_affine()=false` branch in inferReturnTypes + the swizzle
// static-fold in the lowering.
func.func @h_composed_get_inner_swizzle(
    %cl: !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)">)
    -> !cute.swizzle<"S<2,3,5>"> {
  %r = cute.composed_get_inner(%cl)
       : !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)"> -> !cute.swizzle<"S<2,3,5>">
  return %r : !cute.swizzle<"S<2,3,5>">
}

// composed_get_offset on a composed layout with a dyn-friendly offset
// shape. Static flavor uses a literal 113; dyn flavor builds the same
// value as a dynamic leaf so all flavors print `113`.
func.func @h_composed_get_offset_dyn(
    %cl: !cute.composed_layout<"(2,3):(1,2) o 113 o (4,5):(1,4)">)
    -> !cute.int_tuple<"113"> {
  %r = cute.composed_get_offset(%cl)
       : !cute.composed_layout<"(2,3):(1,2) o 113 o (4,5):(1,4)"> -> !cute.int_tuple<"113">
  return %r : !cute.int_tuple<"113">
}

// composed_get_outer on a composed layout with a multi-mode outer B.
// Static flavor's outer is fully static; dyn flavor's outer is dynamic
// — both resolve to the same printed `(127,131):(1,127)`.
func.func @h_composed_get_outer_dyn(
    %cl: !cute.composed_layout<"(2,3):(1,2) o 0 o (127,131):(1,127)">)
    -> !cute.layout<"(127,131):(1,127)"> {
  %r = cute.composed_get_outer(%cl)
       : !cute.composed_layout<"(2,3):(1,2) o 0 o (127,131):(1,127)"> -> !cute.layout<"(127,131):(1,127)">
  return %r : !cute.layout<"(127,131):(1,127)">
}

// select<[2, 0]> — permutation on a rank-3 layout.
func.func @h_select_permute(%l: !cute.layout<"(139,149,151):(1,139,20711)">)
    -> !cute.layout<"(151,139):(20711,1)"> {
  %r = cute.select<[2, 0]> (%l)
       : !cute.layout<"(139,149,151):(1,139,20711)">
      -> !cute.layout<"(151,139):(20711,1)">
  return %r : !cute.layout<"(151,139):(20711,1)">
}

// select<[1, 2]> on a tile — picks an underscore slot + a layout slot.
func.func @h_select_tile(%t: !cute.tile<"[(157,163):(1,157);_;(167,173):(1,167)]">)
    -> !cute.tile<"[_;(167,173):(1,167)]"> {
  %r = cute.select<[1, 2]> (%t)
       : !cute.tile<"[(157,163):(1,157);_;(167,173):(1,167)]">
      -> !cute.tile<"[_;(167,173):(1,167)]">
  return %r : !cute.tile<"[_;(167,173):(1,167)]">
}

// select<[1, 0]> on a composed_layout — applies to outer B; inner +
// offset preserved.
func.func @h_select_composed(%cl: !cute.composed_layout<"(179,181):(1,179) o 0 o (191,193):(1,191)">)
    -> !cute.composed_layout<"(179,181):(1,179) o 0 o (193,191):(191,1)"> {
  %r = cute.select<[1, 0]> (%cl)
       : !cute.composed_layout<"(179,181):(1,179) o 0 o (191,193):(1,191)">
      -> !cute.composed_layout<"(179,181):(1,179) o 0 o (193,191):(191,1)">
  return %r : !cute.composed_layout<"(179,181):(1,179) o 0 o (193,191):(191,1)">
}

// select<[1, 0]> on a scaled-basis layout — basis indices follow the
// picked modes through the reorder.
func.func @h_select_scaled_basis(%l: !cute.layout<"(197,199):(1@0,1@1)">)
    -> !cute.layout<"(199,197):(1@1,1@0)"> {
  %r = cute.select<[1, 0]> (%l)
       : !cute.layout<"(197,199):(1@0,1@1)"> -> !cute.layout<"(199,197):(1@1,1@0)">
  return %r : !cute.layout<"(199,197):(1@1,1@0)">
}

// select<[]> — empty mode produces a rank-0 result.
func.func @h_select_empty(%s: !cute.shape<"(211,223)">) -> !cute.shape<"()"> {
  %r = cute.select<[]> (%s) : !cute.shape<"(211,223)"> -> !cute.shape<"()">
  return %r : !cute.shape<"()">
}

// select<[1, 1]> on an int_tuple — repeated index duplicates the
// picked mode.
func.func @h_select_repeat(%i: !cute.int_tuple<"(227,229,233)">)
    -> !cute.int_tuple<"(229,229)"> {
  %r = cute.select<[1, 1]> (%i)
       : !cute.int_tuple<"(227,229,233)"> -> !cute.int_tuple<"(229,229)">
  return %r : !cute.int_tuple<"(229,229)">
}

// to_int_tuple — identity case (int_tuple -> int_tuple).
func.func @h_to_int_tuple_identity(%i: !cute.int_tuple<"(239,241)">)
    -> !cute.int_tuple<"(239,241)"> {
  %r = cute.to_int_tuple(%i)
       : !cute.int_tuple<"(239,241)"> -> !cute.int_tuple<"(239,241)">
  return %r : !cute.int_tuple<"(239,241)">
}

// to_int_tuple — from stride.
func.func @h_to_int_tuple_stride(%st: !cute.stride<"(251,257)">)
    -> !cute.int_tuple<"(251,257)"> {
  %r = cute.to_int_tuple(%st)
       : !cute.stride<"(251,257)"> -> !cute.int_tuple<"(251,257)">
  return %r : !cute.int_tuple<"(251,257)">
}

// to_int_tuple — from coord.
func.func @h_to_int_tuple_coord(%c: !cute.coord<"(263,269)">)
    -> !cute.int_tuple<"(263,269)"> {
  %r = cute.to_int_tuple(%c)
       : !cute.coord<"(263,269)"> -> !cute.int_tuple<"(263,269)">
  return %r : !cute.int_tuple<"(263,269)">
}

// to_int_tuple — from a nested shape; hierarchical structure preserved.
func.func @h_to_int_tuple_nested(%s: !cute.shape<"(271,(277,281),283)">)
    -> !cute.int_tuple<"(271,(277,281),283)"> {
  %r = cute.to_int_tuple(%s)
       : !cute.shape<"(271,(277,281),283)">
      -> !cute.int_tuple<"(271,(277,281),283)">
  return %r : !cute.int_tuple<"(271,(277,281),283)">
}

// get_layouts_from_tile — layout + underscore slot; underscore skipped.
func.func @h_get_layouts_from_tile_underscore(%t: !cute.tile<"[(293,307):(1,293);_]">)
    -> !cute.layout<"(293,307):(1,293)"> {
  %r = cute.get_layouts_from_tile(%t)
       : !cute.tile<"[(293,307):(1,293);_]">
  return %r : !cute.layout<"(293,307):(1,293)">
}

// get_layouts_from_tile — nested tile, DFS flatten → 4 layouts.
func.func @h_get_layouts_from_tile_nested(%t: !cute.tile<"[311:1;[313:1;317:1];331:1]">)
    -> (!cute.layout<"311:1">, !cute.layout<"313:1">,
        !cute.layout<"317:1">, !cute.layout<"331:1">) {
  %a, %b, %c, %d = cute.get_layouts_from_tile(%t)
                 : !cute.tile<"[311:1;[313:1;317:1];331:1]">
  return %a, %b, %c, %d
      : !cute.layout<"311:1">, !cute.layout<"313:1">,
        !cute.layout<"317:1">, !cute.layout<"331:1">
}

//===----------------------------------------------------------------------===//
// Entry point: per-op direct construction + print, then helper-call +
// print. Each pair of prints emits the same expected line consecutively
// — captured by the count-2 check directives above.
//===----------------------------------------------------------------------===//

func.func @main() {
  // get_shape — extract the shape mode of a layout.
  %l_sh = cute.static : !cute.layout<"(2,7):(1,2)">
  %sh1 = cute.get_shape(%l_sh) : !cute.layout<"(2,7):(1,2)"> -> !cute.shape<"(2,7)">
  cute.print(%sh1) : !cute.shape<"(2,7)">
  %sh2 = func.call @h_get_shape(%l_sh)
       : (!cute.layout<"(2,7):(1,2)">) -> !cute.shape<"(2,7)">
  cute.print(%sh2) : !cute.shape<"(2,7)">

  // get_stride — extract the stride mode of a layout.
  %l_st = cute.static : !cute.layout<"(3,5):(2,9)">
  %st1 = cute.get_stride(%l_st) : !cute.layout<"(3,5):(2,9)"> -> !cute.stride<"(2,9)">
  cute.print(%st1) : !cute.stride<"(2,9)">
  %st2 = func.call @h_get_stride(%l_st)
       : (!cute.layout<"(3,5):(2,9)">) -> !cute.stride<"(2,9)">
  cute.print(%st2) : !cute.stride<"(2,9)">

  // get<[mode]> — pick a single mode from a layout (here mode 0).
  %l_g = cute.static : !cute.layout<"(11,13):(1,11)">
  %g1 = cute.get<[0]> (%l_g) : !cute.layout<"(11,13):(1,11)"> -> !cute.layout<"11:1">
  cute.print(%g1) : !cute.layout<"11:1">
  %g2 = func.call @h_get(%l_g)
      : (!cute.layout<"(11,13):(1,11)">) -> !cute.layout<"11:1">
  cute.print(%g2) : !cute.layout<"11:1">

  // get_leaves — flatten a nested shape to its three leaf shapes.
  %s_lv = cute.static : !cute.shape<"(17,(19,23))">
  %a1, %b1, %c1 = cute.get_leaves(%s_lv) : !cute.shape<"(17,(19,23))">
  cute.print(%a1) : !cute.shape<"17">
  cute.print(%b1) : !cute.shape<"19">
  cute.print(%c1) : !cute.shape<"23">
  %a2, %b2, %c2 = func.call @h_get_leaves(%s_lv)
       : (!cute.shape<"(17,(19,23))">)
      -> (!cute.shape<"17">, !cute.shape<"19">, !cute.shape<"23">)
  cute.print(%a2) : !cute.shape<"17">
  cute.print(%b2) : !cute.shape<"19">
  cute.print(%c2) : !cute.shape<"23">

  // get_layouts_from_tile — split a multi-layout tile into its layouts.
  %t = cute.static : !cute.tile<"[(29,31):(1,29);(37,41):(1,37)]">
  %la1, %lb1 = cute.get_layouts_from_tile(%t)
       : !cute.tile<"[(29,31):(1,29);(37,41):(1,37)]">
  cute.print(%la1) : !cute.layout<"(29,31):(1,29)">
  cute.print(%lb1) : !cute.layout<"(37,41):(1,37)">
  %la2, %lb2 = func.call @h_get_layouts_from_tile(%t)
       : (!cute.tile<"[(29,31):(1,29);(37,41):(1,37)]">)
      -> (!cute.layout<"(29,31):(1,29)">, !cute.layout<"(37,41):(1,37)">)
  cute.print(%la2) : !cute.layout<"(29,31):(1,29)">
  cute.print(%lb2) : !cute.layout<"(37,41):(1,37)">

  // composed_get_inner / offset / outer — extract A, offset, B from an
  // affine composed layout.
  %cl = cute.static : !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">
  %in1 = cute.composed_get_inner(%cl)
       : !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">
      -> !cute.layout<"(43,47):(1,43)">
  cute.print(%in1) : !cute.layout<"(43,47):(1,43)">
  %in2 = func.call @h_composed_get_inner(%cl)
       : (!cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">)
      -> !cute.layout<"(43,47):(1,43)">
  cute.print(%in2) : !cute.layout<"(43,47):(1,43)">

  %off1 = cute.composed_get_offset(%cl)
        : !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">
       -> !cute.int_tuple<"53">
  cute.print(%off1) : !cute.int_tuple<"53">
  %off2 = func.call @h_composed_get_offset(%cl)
        : (!cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">)
       -> !cute.int_tuple<"53">
  cute.print(%off2) : !cute.int_tuple<"53">

  %out1 = cute.composed_get_outer(%cl)
        : !cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">
       -> !cute.layout<"(2,4):(1,2)">
  cute.print(%out1) : !cute.layout<"(2,4):(1,2)">
  %out2 = func.call @h_composed_get_outer(%cl)
        : (!cute.composed_layout<"(43,47):(1,43) o 53 o (2,4):(1,2)">)
       -> !cute.layout<"(2,4):(1,2)">
  cute.print(%out2) : !cute.layout<"(2,4):(1,2)">

  // select<[mode]> — pick a single mode from a multi-mode layout.
  %l_sel = cute.static : !cute.layout<"(59,61,67):(1,59,3599)">
  %sel1 = cute.select<[1]> (%l_sel) : !cute.layout<"(59,61,67):(1,59,3599)">
                                  -> !cute.layout<"(61):(59)">
  cute.print(%sel1) : !cute.layout<"(61):(59)">
  %sel2 = func.call @h_select(%l_sel)
        : (!cute.layout<"(59,61,67):(1,59,3599)">) -> !cute.layout<"(61):(59)">
  cute.print(%sel2) : !cute.layout<"(61):(59)">

  // to_int_tuple — strip the `shape`/`stride`/`coord` wrapper.
  %s_it = cute.static : !cute.shape<"(71,73)">
  %it1 = cute.to_int_tuple(%s_it) : !cute.shape<"(71,73)"> -> !cute.int_tuple<"(71,73)">
  cute.print(%it1) : !cute.int_tuple<"(71,73)">
  %it2 = func.call @h_to_int_tuple(%s_it)
       : (!cute.shape<"(71,73)">) -> !cute.int_tuple<"(71,73)">
  cute.print(%it2) : !cute.int_tuple<"(71,73)">

  // get_shape on a composed_layout — returns the outer B's shape.
  %cl2 = cute.static : !cute.composed_layout<"S<3,4,3> o 0 o (89,97):(1,89)">
  %csh1 = cute.get_shape(%cl2)
        : !cute.composed_layout<"S<3,4,3> o 0 o (89,97):(1,89)"> -> !cute.shape<"(89,97)">
  cute.print(%csh1) : !cute.shape<"(89,97)">
  %csh2 = func.call @h_get_shape_composed(%cl2)
        : (!cute.composed_layout<"S<3,4,3> o 0 o (89,97):(1,89)">) -> !cute.shape<"(89,97)">
  cute.print(%csh2) : !cute.shape<"(89,97)">

  // get_stride on a layout with scaled-basis strides — preserved verbatim.
  %l_b = cute.static : !cute.layout<"(101,103):(109@0,1@1)">
  %bst1 = cute.get_stride(%l_b)
        : !cute.layout<"(101,103):(109@0,1@1)"> -> !cute.stride<"(109@0,1@1)">
  cute.print(%bst1) : !cute.stride<"(109@0,1@1)">
  %bst2 = func.call @h_get_stride_basis(%l_b)
        : (!cute.layout<"(101,103):(109@0,1@1)">) -> !cute.stride<"(109@0,1@1)">
  cute.print(%bst2) : !cute.stride<"(109@0,1@1)">

  // composed_get_inner on a swizzle-A composed.
  %cl_sw = cute.static : !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)">
  %sw1 = cute.composed_get_inner(%cl_sw)
        : !cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)"> -> !cute.swizzle<"S<2,3,5>">
  cute.print(%sw1) : !cute.swizzle<"S<2,3,5>">
  %sw2 = func.call @h_composed_get_inner_swizzle(%cl_sw)
        : (!cute.composed_layout<"S<2,3,5> o 0 o (2,3):(1,2)">) -> !cute.swizzle<"S<2,3,5>">
  cute.print(%sw2) : !cute.swizzle<"S<2,3,5>">

  // composed_get_offset with a dyn-target offset (literal 113 in this
  // static flavor; dynamic/runtime variants build the same value at runtime).
  %cl_off = cute.static : !cute.composed_layout<"(2,3):(1,2) o 113 o (4,5):(1,4)">
  %off_v2_1 = cute.composed_get_offset(%cl_off)
        : !cute.composed_layout<"(2,3):(1,2) o 113 o (4,5):(1,4)"> -> !cute.int_tuple<"113">
  cute.print(%off_v2_1) : !cute.int_tuple<"113">
  %off_v2_2 = func.call @h_composed_get_offset_dyn(%cl_off)
        : (!cute.composed_layout<"(2,3):(1,2) o 113 o (4,5):(1,4)">) -> !cute.int_tuple<"113">
  cute.print(%off_v2_2) : !cute.int_tuple<"113">

  // composed_get_outer with a multi-mode outer (literal here; dyn flavors
  // build (?,131):(1,?) with shape_leaf=127, stride_leaf=127).
  %cl_out = cute.static : !cute.composed_layout<"(2,3):(1,2) o 0 o (127,131):(1,127)">
  %out_b1 = cute.composed_get_outer(%cl_out)
        : !cute.composed_layout<"(2,3):(1,2) o 0 o (127,131):(1,127)"> -> !cute.layout<"(127,131):(1,127)">
  cute.print(%out_b1) : !cute.layout<"(127,131):(1,127)">
  %out_b2 = func.call @h_composed_get_outer_dyn(%cl_out)
        : (!cute.composed_layout<"(2,3):(1,2) o 0 o (127,131):(1,127)">) -> !cute.layout<"(127,131):(1,127)">
  cute.print(%out_b2) : !cute.layout<"(127,131):(1,127)">

  // select<[2, 0]> — permutation on a rank-3 layout.
  %l_perm = cute.static : !cute.layout<"(139,149,151):(1,139,20711)">
  %sp1 = cute.select<[2, 0]> (%l_perm)
       : !cute.layout<"(139,149,151):(1,139,20711)"> -> !cute.layout<"(151,139):(20711,1)">
  cute.print(%sp1) : !cute.layout<"(151,139):(20711,1)">
  %sp2 = func.call @h_select_permute(%l_perm)
       : (!cute.layout<"(139,149,151):(1,139,20711)">) -> !cute.layout<"(151,139):(20711,1)">
  cute.print(%sp2) : !cute.layout<"(151,139):(20711,1)">

  // select<[1, 2]> on a tile — underscore slot picked.
  %t_sel = cute.static : !cute.tile<"[(157,163):(1,157);_;(167,173):(1,167)]">
  %sti1 = cute.select<[1, 2]> (%t_sel)
        : !cute.tile<"[(157,163):(1,157);_;(167,173):(1,167)]">
       -> !cute.tile<"[_;(167,173):(1,167)]">
  cute.print(%sti1) : !cute.tile<"[_;(167,173):(1,167)]">
  %sti2 = func.call @h_select_tile(%t_sel)
        : (!cute.tile<"[(157,163):(1,157);_;(167,173):(1,167)]">)
       -> !cute.tile<"[_;(167,173):(1,167)]">
  cute.print(%sti2) : !cute.tile<"[_;(167,173):(1,167)]">

  // select<[1, 0]> on a composed_layout — outer B sliced, inner+offset preserved.
  %cl_sel = cute.static : !cute.composed_layout<"(179,181):(1,179) o 0 o (191,193):(1,191)">
  %sc1 = cute.select<[1, 0]> (%cl_sel)
       : !cute.composed_layout<"(179,181):(1,179) o 0 o (191,193):(1,191)">
      -> !cute.composed_layout<"(179,181):(1,179) o 0 o (193,191):(191,1)">
  cute.print(%sc1) : !cute.composed_layout<"(179,181):(1,179) o 0 o (193,191):(191,1)">
  %sc2 = func.call @h_select_composed(%cl_sel)
       : (!cute.composed_layout<"(179,181):(1,179) o 0 o (191,193):(1,191)">)
      -> !cute.composed_layout<"(179,181):(1,179) o 0 o (193,191):(191,1)">
  cute.print(%sc2) : !cute.composed_layout<"(179,181):(1,179) o 0 o (193,191):(191,1)">

  // select<[1, 0]> on a scaled-basis layout.
  %l_sb = cute.static : !cute.layout<"(197,199):(1@0,1@1)">
  %ssb1 = cute.select<[1, 0]> (%l_sb)
        : !cute.layout<"(197,199):(1@0,1@1)"> -> !cute.layout<"(199,197):(1@1,1@0)">
  cute.print(%ssb1) : !cute.layout<"(199,197):(1@1,1@0)">
  %ssb2 = func.call @h_select_scaled_basis(%l_sb)
        : (!cute.layout<"(197,199):(1@0,1@1)">) -> !cute.layout<"(199,197):(1@1,1@0)">
  cute.print(%ssb2) : !cute.layout<"(199,197):(1@1,1@0)">

  // select<[]> — empty mode → rank-0 result.
  %s_empty = cute.static : !cute.shape<"(211,223)">
  %se1 = cute.select<[]> (%s_empty) : !cute.shape<"(211,223)"> -> !cute.shape<"()">
  cute.print(%se1) : !cute.shape<"()">
  %se2 = func.call @h_select_empty(%s_empty)
       : (!cute.shape<"(211,223)">) -> !cute.shape<"()">
  cute.print(%se2) : !cute.shape<"()">

  // select<[1, 1]> on an int_tuple — repeated index.
  %i_rep = cute.static : !cute.int_tuple<"(227,229,233)">
  %sr1 = cute.select<[1, 1]> (%i_rep)
       : !cute.int_tuple<"(227,229,233)"> -> !cute.int_tuple<"(229,229)">
  cute.print(%sr1) : !cute.int_tuple<"(229,229)">
  %sr2 = func.call @h_select_repeat(%i_rep)
       : (!cute.int_tuple<"(227,229,233)">) -> !cute.int_tuple<"(229,229)">
  cute.print(%sr2) : !cute.int_tuple<"(229,229)">

  // to_int_tuple — identity (int_tuple -> int_tuple).
  %it_id_in = cute.static : !cute.int_tuple<"(239,241)">
  %itid1 = cute.to_int_tuple(%it_id_in)
         : !cute.int_tuple<"(239,241)"> -> !cute.int_tuple<"(239,241)">
  cute.print(%itid1) : !cute.int_tuple<"(239,241)">
  %itid2 = func.call @h_to_int_tuple_identity(%it_id_in)
         : (!cute.int_tuple<"(239,241)">) -> !cute.int_tuple<"(239,241)">
  cute.print(%itid2) : !cute.int_tuple<"(239,241)">

  // to_int_tuple — from stride.
  %st_src = cute.static : !cute.stride<"(251,257)">
  %itst1 = cute.to_int_tuple(%st_src)
         : !cute.stride<"(251,257)"> -> !cute.int_tuple<"(251,257)">
  cute.print(%itst1) : !cute.int_tuple<"(251,257)">
  %itst2 = func.call @h_to_int_tuple_stride(%st_src)
         : (!cute.stride<"(251,257)">) -> !cute.int_tuple<"(251,257)">
  cute.print(%itst2) : !cute.int_tuple<"(251,257)">

  // to_int_tuple — from coord.
  %c_src = cute.static : !cute.coord<"(263,269)">
  %itc1 = cute.to_int_tuple(%c_src)
        : !cute.coord<"(263,269)"> -> !cute.int_tuple<"(263,269)">
  cute.print(%itc1) : !cute.int_tuple<"(263,269)">
  %itc2 = func.call @h_to_int_tuple_coord(%c_src)
        : (!cute.coord<"(263,269)">) -> !cute.int_tuple<"(263,269)">
  cute.print(%itc2) : !cute.int_tuple<"(263,269)">

  // to_int_tuple — from a nested shape; hierarchy preserved.
  %nested_src = cute.static : !cute.shape<"(271,(277,281),283)">
  %itn1 = cute.to_int_tuple(%nested_src)
        : !cute.shape<"(271,(277,281),283)">
       -> !cute.int_tuple<"(271,(277,281),283)">
  cute.print(%itn1) : !cute.int_tuple<"(271,(277,281),283)">
  %itn2 = func.call @h_to_int_tuple_nested(%nested_src)
        : (!cute.shape<"(271,(277,281),283)">)
       -> !cute.int_tuple<"(271,(277,281),283)">
  cute.print(%itn2) : !cute.int_tuple<"(271,(277,281),283)">

  // get_layouts_from_tile — layout + underscore slot; underscore skipped.
  %t_us = cute.static : !cute.tile<"[(293,307):(1,293);_]">
  %lu1 = cute.get_layouts_from_tile(%t_us)
       : !cute.tile<"[(293,307):(1,293);_]">
  cute.print(%lu1) : !cute.layout<"(293,307):(1,293)">
  %lu2 = func.call @h_get_layouts_from_tile_underscore(%t_us)
       : (!cute.tile<"[(293,307):(1,293);_]">) -> !cute.layout<"(293,307):(1,293)">
  cute.print(%lu2) : !cute.layout<"(293,307):(1,293)">

  // get_layouts_from_tile — nested tile (tile of tiles), DFS flatten.
  %t_nested = cute.static : !cute.tile<"[311:1;[313:1;317:1];331:1]">
  %ln0a, %ln1a, %ln2a, %ln3a = cute.get_layouts_from_tile(%t_nested)
                             : !cute.tile<"[311:1;[313:1;317:1];331:1]">
  cute.print(%ln0a) : !cute.layout<"311:1">
  cute.print(%ln1a) : !cute.layout<"313:1">
  cute.print(%ln2a) : !cute.layout<"317:1">
  cute.print(%ln3a) : !cute.layout<"331:1">
  %ln0b, %ln1b, %ln2b, %ln3b = func.call @h_get_layouts_from_tile_nested(%t_nested)
        : (!cute.tile<"[311:1;[313:1;317:1];331:1]">)
       -> (!cute.layout<"311:1">, !cute.layout<"313:1">,
           !cute.layout<"317:1">, !cute.layout<"331:1">)
  cute.print(%ln0b) : !cute.layout<"311:1">
  cute.print(%ln1b) : !cute.layout<"313:1">
  cute.print(%ln2b) : !cute.layout<"317:1">
  cute.print(%ln3b) : !cute.layout<"331:1">

  return
}
