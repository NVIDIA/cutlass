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
// All-static SizeIndex; cute-fold-static evaluates every op, no arith.* survives.
// RUN: cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:     -base-prepare %s | FileCheck --check-prefix=POST-PREP %s
//
// POST-PREP-NOT: arith.

// End-to-end host integration test covering the SizeIndex category:
// size, cosize, layout_eval, crd2idx, idx2crd, increment_coord,
// append_to_rank, prepend_to_rank, tuple_product, tuple_product_each.
// Direct + helper-call paths.

// CHECK-COUNT-2: 12
// CHECK-COUNT-2: 24
// CHECK-COUNT-2: 9
// CHECK-COUNT-2: 208
// crd2idx (coord (2,3) on shape (4,8)) → 2 + 3*4 = 14.
// CHECK-COUNT-2: 14
// CHECK-COUNT-2: (1,2)
// CHECK-COUNT-2: (2,2)
// increment_coord wrap: (3,2) + (4,8) → (0,3) (mode 0 wraps, carries
// to mode 1).
// CHECK-COUNT-2: (0,3)
// increment_coord hierarchical: (1,(2,0)) + (4,(3,8)) → (2,(2,0))
// (only mode 0 increments; nested modes unchanged).
// CHECK-COUNT-2: (2,(2,0))
// CHECK-COUNT-2: (4,8,1,1)
// CHECK-COUNT-2: (1,1,4,8)
// CHECK-COUNT-2: 30
// CHECK-COUNT-2: (3,10)

//===----------------------------------------------------------------------===//
// Per-op helpers.
//===----------------------------------------------------------------------===//

func.func @h_size(%s: !cute.shape<"(4,3)">) -> !cute.int_tuple<"12"> {
  %r = cute.size(%s) : (!cute.shape<"(4,3)">) -> !cute.int_tuple<"12">
  return %r : !cute.int_tuple<"12">
}

func.func @h_cosize(%l: !cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24"> {
  %r = cute.cosize(%l) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24">
  return %r : !cute.int_tuple<"24">
}

func.func @h_layout_eval(%c: !cute.coord<"(1,2)">, %l: !cute.layout<"(4,8):(1,4)">)
    -> !cute.int_tuple<"9"> {
  %r = cute.layout_eval(%c, %l) : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}

func.func @h_layout_eval_composed(
    %c: !cute.coord<"6">,
    %cl: !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
    -> !cute.int_tuple<"208"> {
  %r = cute.layout_eval(%c, %cl)
         : (!cute.coord<"6">,
            !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
        -> !cute.int_tuple<"208">
  return %r : !cute.int_tuple<"208">
}

func.func @h_crd2idx(%c: !cute.coord<"(2,3)">, %s: !cute.shape<"(4,8)">)
    -> !cute.int_tuple<"14"> {
  %r = cute.crd2idx(%c, %s) : (!cute.coord<"(2,3)">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"14">
  return %r : !cute.int_tuple<"14">
}

func.func @h_idx2crd(%i: !cute.int_tuple<"9">, %s: !cute.shape<"(4,8)">)
    -> !cute.coord<"(1,2)"> {
  %r = cute.idx2crd(%i, %s) : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)">
  return %r : !cute.coord<"(1,2)">
}

func.func @h_increment_coord(%c: !cute.coord<"(1,2)">, %s: !cute.shape<"(4,8)">)
    -> !cute.coord<"(2,2)"> {
  %r = cute.increment_coord(%c, %s) : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(2,2)">
  return %r : !cute.coord<"(2,2)">
}

// Wrap variant: mode 0 hits its extent and rolls over, carrying into
// mode 1.
func.func @h_increment_coord_wrap(%c: !cute.coord<"(3,2)">, %s: !cute.shape<"(4,8)">)
    -> !cute.coord<"(0,3)"> {
  %r = cute.increment_coord(%c, %s) : (!cute.coord<"(3,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(0,3)">
  return %r : !cute.coord<"(0,3)">
}

// Hierarchical variant: nested coord/shape; only mode 0 increments,
// nested modes pass through unchanged.
func.func @h_increment_coord_hier(%c: !cute.coord<"(1,(2,0))">, %s: !cute.shape<"(4,(3,8))">)
    -> !cute.coord<"(2,(2,0))"> {
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"(1,(2,0))">, !cute.shape<"(4,(3,8))">) -> !cute.coord<"(2,(2,0))">
  return %r : !cute.coord<"(2,(2,0))">
}

func.func @h_append_to_rank(%in: !cute.shape<"(4,8)">, %e: !cute.shape<"1">)
    -> !cute.shape<"(4,8,1,1)"> {
  %r = cute.append_to_rank<4>(%in, %e) : !cute.shape<"(4,8)">, !cute.shape<"1">
  return %r : !cute.shape<"(4,8,1,1)">
}

func.func @h_prepend_to_rank(%in: !cute.shape<"(4,8)">, %e: !cute.shape<"1">)
    -> !cute.shape<"(1,1,4,8)"> {
  %r = cute.prepend_to_rank<4>(%in, %e) : !cute.shape<"(4,8)">, !cute.shape<"1">
  return %r : !cute.shape<"(1,1,4,8)">
}

func.func @h_tuple_product(%in: !cute.int_tuple<"(3,(2,5))">) -> !cute.int_tuple<"30"> {
  %r = cute.tuple_product(%in) : (!cute.int_tuple<"(3,(2,5))">) -> !cute.int_tuple<"30">
  return %r : !cute.int_tuple<"30">
}

func.func @h_tuple_product_each(%in: !cute.int_tuple<"(3,(2,5))">)
    -> !cute.int_tuple<"(3,10)"> {
  %r = cute.tuple_product_each(%in) : (!cute.int_tuple<"(3,(2,5))">) -> !cute.int_tuple<"(3,10)">
  return %r : !cute.int_tuple<"(3,10)">
}

//===----------------------------------------------------------------------===//
// Entry point.
//===----------------------------------------------------------------------===//

func.func @main() {
  // size: (4,3) → 12
  %s1 = cute.static : !cute.shape<"(4,3)">
  %r1 = cute.size(%s1) : (!cute.shape<"(4,3)">) -> !cute.int_tuple<"12">
  cute.print(%r1) : !cute.int_tuple<"12">
  %r1b = func.call @h_size(%s1) : (!cute.shape<"(4,3)">) -> !cute.int_tuple<"12">
  cute.print(%r1b) : !cute.int_tuple<"12">

  // cosize: (4,3,2):(1,4,12) → 24
  %l2 = cute.static : !cute.layout<"(4,3,2):(1,4,12)">
  %r2 = cute.cosize(%l2) : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24">
  cute.print(%r2) : !cute.int_tuple<"24">
  %r2b = func.call @h_cosize(%l2)
       : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24">
  cute.print(%r2b) : !cute.int_tuple<"24">

  // layout_eval: (1,2) + (4,8):(1,4) → 1*1 + 2*4 = 9
  %crd3 = cute.static : !cute.coord<"(1,2)">
  %l3 = cute.static : !cute.layout<"(4,8):(1,4)">
  %r3 = cute.layout_eval(%crd3, %l3)
       : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"9">
  cute.print(%r3) : !cute.int_tuple<"9">
  %r3b = func.call @h_layout_eval(%crd3, %l3)
       : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"9">
  cute.print(%r3b) : !cute.int_tuple<"9">

  // layout_eval over composed_layout: coord 6 on `S<1,4,3> o 0 o (32):(32)` →
  // outer = 6*32 = 192; swizzle(192) = 192 ^ ((192 & 128) >> 3) = 208.
  %crd3c = cute.static : !cute.coord<"6">
  %cl3 = cute.static : !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">
  %r3c = cute.layout_eval(%crd3c, %cl3)
       : (!cute.coord<"6">,
          !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
      -> !cute.int_tuple<"208">
  cute.print(%r3c) : !cute.int_tuple<"208">
  %r3cb = func.call @h_layout_eval_composed(%crd3c, %cl3)
       : (!cute.coord<"6">,
          !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
      -> !cute.int_tuple<"208">
  cute.print(%r3cb) : !cute.int_tuple<"208">

  // crd2idx: (2,3) + (4,8) → 2 + 3*4 = 14.
  %crd3p = cute.static : !cute.coord<"(2,3)">
  %s3p = cute.static : !cute.shape<"(4,8)">
  %r3p = cute.crd2idx(%crd3p, %s3p)
       : (!cute.coord<"(2,3)">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"14">
  cute.print(%r3p) : !cute.int_tuple<"14">
  %r3pb = func.call @h_crd2idx(%crd3p, %s3p)
       : (!cute.coord<"(2,3)">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"14">
  cute.print(%r3pb) : !cute.int_tuple<"14">

  // idx2crd: 9 + (4,8) → (1,2)
  %idx4 = cute.static : !cute.int_tuple<"9">
  %s4 = cute.static : !cute.shape<"(4,8)">
  %r4 = cute.idx2crd(%idx4, %s4)
       : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)">
  cute.print(%r4) : !cute.coord<"(1,2)">
  %r4b = func.call @h_idx2crd(%idx4, %s4)
       : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)">
  cute.print(%r4b) : !cute.coord<"(1,2)">

  // increment_coord: (1,2) + (4,8) → (2,2)
  %c5 = cute.static : !cute.coord<"(1,2)">
  %s5 = cute.static : !cute.shape<"(4,8)">
  %r5 = cute.increment_coord(%c5, %s5)
       : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(2,2)">
  cute.print(%r5) : !cute.coord<"(2,2)">
  %r5b = func.call @h_increment_coord(%c5, %s5)
       : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(2,2)">
  cute.print(%r5b) : !cute.coord<"(2,2)">

  // increment_coord wrap: (3,2) + (4,8) → (0,3) (mode 0 hits extent
  // and rolls over; mode 1 picks up the carry).
  %c5w = cute.static : !cute.coord<"(3,2)">
  %r5w = cute.increment_coord(%c5w, %s5)
       : (!cute.coord<"(3,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(0,3)">
  cute.print(%r5w) : !cute.coord<"(0,3)">
  %r5wb = func.call @h_increment_coord_wrap(%c5w, %s5)
       : (!cute.coord<"(3,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(0,3)">
  cute.print(%r5wb) : !cute.coord<"(0,3)">

  // increment_coord hierarchical: (1,(2,0)) + (4,(3,8)) → (2,(2,0))
  // (only mode 0 increments; nested coord passes through verbatim).
  %c5h = cute.static : !cute.coord<"(1,(2,0))">
  %s5h = cute.static : !cute.shape<"(4,(3,8))">
  %r5h = cute.increment_coord(%c5h, %s5h)
       : (!cute.coord<"(1,(2,0))">, !cute.shape<"(4,(3,8))">) -> !cute.coord<"(2,(2,0))">
  cute.print(%r5h) : !cute.coord<"(2,(2,0))">
  %r5hb = func.call @h_increment_coord_hier(%c5h, %s5h)
       : (!cute.coord<"(1,(2,0))">, !cute.shape<"(4,(3,8))">) -> !cute.coord<"(2,(2,0))">
  cute.print(%r5hb) : !cute.coord<"(2,(2,0))">

  // append_to_rank<4>: (4,8) padded to rank 4 with 1 → (4,8,1,1)
  %s6 = cute.static : !cute.shape<"(4,8)">
  %e6 = cute.static : !cute.shape<"1">
  %r6 = cute.append_to_rank<4>(%s6, %e6) : !cute.shape<"(4,8)">, !cute.shape<"1">
  cute.print(%r6) : !cute.shape<"(4,8,1,1)">
  %r6b = func.call @h_append_to_rank(%s6, %e6)
       : (!cute.shape<"(4,8)">, !cute.shape<"1">) -> !cute.shape<"(4,8,1,1)">
  cute.print(%r6b) : !cute.shape<"(4,8,1,1)">

  // prepend_to_rank<4>
  %r7 = cute.prepend_to_rank<4>(%s6, %e6) : !cute.shape<"(4,8)">, !cute.shape<"1">
  cute.print(%r7) : !cute.shape<"(1,1,4,8)">
  %r7b = func.call @h_prepend_to_rank(%s6, %e6)
       : (!cute.shape<"(4,8)">, !cute.shape<"1">) -> !cute.shape<"(1,1,4,8)">
  cute.print(%r7b) : !cute.shape<"(1,1,4,8)">

  // tuple_product: (3,(2,5)) → 3*2*5 = 30
  %s8 = cute.static : !cute.int_tuple<"(3,(2,5))">
  %r8 = cute.tuple_product(%s8) : (!cute.int_tuple<"(3,(2,5))">) -> !cute.int_tuple<"30">
  cute.print(%r8) : !cute.int_tuple<"30">
  %r8b = func.call @h_tuple_product(%s8)
       : (!cute.int_tuple<"(3,(2,5))">) -> !cute.int_tuple<"30">
  cute.print(%r8b) : !cute.int_tuple<"30">

  // tuple_product_each: (3,(2,5)) → (3,10) (collapse each top-level mode)
  %r9 = cute.tuple_product_each(%s8)
       : (!cute.int_tuple<"(3,(2,5))">) -> !cute.int_tuple<"(3,10)">
  cute.print(%r9) : !cute.int_tuple<"(3,10)">
  %r9b = func.call @h_tuple_product_each(%s8)
       : (!cute.int_tuple<"(3,(2,5))">) -> !cute.int_tuple<"(3,10)">
  cute.print(%r9b) : !cute.int_tuple<"(3,10)">

  return
}
