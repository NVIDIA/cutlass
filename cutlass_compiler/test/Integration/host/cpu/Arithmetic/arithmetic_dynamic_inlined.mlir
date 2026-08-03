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
// Dynamic Arithmetic, ops inlined in @main; static leaves fold through -base-prepare.
//
// `cute.elem_less` / `cute.equal` are deliberately excluded — they
// produce raw `i1` and the i1 → i32 → printf path requires
// `arith.extui` which would break the strict invariant.
//
// RUN: cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:     -base-prepare %s | FileCheck --check-prefix=POST-PREP %s
//
// After -base-prepare only arith.constant may remain:
// POST-PREP-NOT: arith.{{[^c]}}
// POST-PREP-NOT: arith.c{{[^o]}}
//
//

// CHECK: (4,6)
// CHECK: (5,7,3)
// CHECK: ((5,7),9)
// CHECK: (7,11)
// CHECK: (7,10)
// CHECK: (9,6,3)
// CHECK: ((9,13),2)
// CHECK: (7,11)
// CHECK: (4,5)
// CHECK: (1,1,3)
// CHECK: ((4,2),(2,2))
// CHECK: (4,3)
// CHECK: (3,3,6)
// CHECK: (2,8)

func.func @main() {
  // tuple_add: (3,4) + (1,2) → (4,6)
  %a3 = arith.constant 3 : i32
  %a4 = arith.constant 4 : i32
  %a1 = arith.constant 1 : i32
  %a2 = arith.constant 2 : i32
  %t1a = cute.make_int_tuple (%a3, %a4) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %t1b = cute.make_int_tuple (%a1, %a2) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r1 = cute.tuple_add(%t1a, %t1b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  cute.print(%r1) : !cute.int_tuple<"(?,?)">

  // tuple_add rank-mismatch: (1,2,3) + (4,5) → (5,7,3). Extra lhs
  // element passes through; result rank == max(rank(lhs), rank(rhs)).
  %a5 = arith.constant 5 : i32
  %t1am = cute.make_int_tuple (%a1, %a2, %a3)
       : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
  %t1bm = cute.make_int_tuple (%a4, %a5) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r1m = cute.tuple_add(%t1am, %t1bm)
       : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?,?)">)
      -> !cute.int_tuple<"(?,?,?)">
  cute.print(%r1m) : !cute.int_tuple<"(?,?,?)">

  // tuple_add nested: ((1,2),3) + ((4,5),6) → ((5,7),9). Recursion
  // into sub-tuples.
  %a6 = arith.constant 6 : i32
  %t1an = cute.make_int_tuple (%a1, %a2, %a3)
       : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
  %t1bn = cute.make_int_tuple (%a4, %a5, %a6)
       : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
  %r1n = cute.tuple_add(%t1an, %t1bn)
       : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((?,?),?)">)
      -> !cute.int_tuple<"((?,?),?)">
  cute.print(%r1n) : !cute.int_tuple<"((?,?),?)">

  // tuple_add zero identity with dyn lhs: (7,11) + static 0 → (7,11).
  // The static-zero rhs bypasses the per-mode add chain entirely;
  // dyn lhs values pass through unchanged.
  %a7 = arith.constant 7 : i32
  %a11 = arith.constant 11 : i32
  %t1az = cute.make_int_tuple (%a7, %a11) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %t1bz = cute.static : !cute.int_tuple<"0">
  %r1z = cute.tuple_add(%t1az, %t1bz)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"0">)
      -> !cute.int_tuple<"(?,?)">
  cute.print(%r1z) : !cute.int_tuple<"(?,?)">

  // tuple_sub: (10,15) - (3,5) → (7,10)
  %a10 = arith.constant 10 : i32
  %a15 = arith.constant 15 : i32
  %b3 = arith.constant 3 : i32
  %b5 = arith.constant 5 : i32
  %t2a = cute.make_int_tuple (%a10, %a15) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %t2b = cute.make_int_tuple (%b3, %b5) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r2 = cute.tuple_sub(%t2a, %t2b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  cute.print(%r2) : !cute.int_tuple<"(?,?)">

  // tuple_sub rank-mismatch: (10,8,3) - (1,2) → (9,6,3).
  %s8 = arith.constant 8 : i32
  %t2am = cute.make_int_tuple (%a10, %s8, %a3)
       : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
  %t2bm = cute.make_int_tuple (%a1, %a2) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r2m = cute.tuple_sub(%t2am, %t2bm)
       : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?,?)">)
      -> !cute.int_tuple<"(?,?,?)">
  cute.print(%r2m) : !cute.int_tuple<"(?,?,?)">

  // tuple_sub nested: ((10,15),5) - ((1,2),3) → ((9,13),2).
  %t2an = cute.make_int_tuple (%a10, %a15, %b5)
       : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
  %t2bn = cute.make_int_tuple (%a1, %a2, %b3)
       : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
  %r2n = cute.tuple_sub(%t2an, %t2bn)
       : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((?,?),?)">)
      -> !cute.int_tuple<"((?,?),?)">
  cute.print(%r2n) : !cute.int_tuple<"((?,?),?)">

  // tuple_sub zero identity with dyn lhs: (7,11) - 0 → (7,11).
  %s7 = arith.constant 7 : i32
  %s11 = arith.constant 11 : i32
  %t2az = cute.make_int_tuple (%s7, %s11) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %t2bz = cute.static : !cute.int_tuple<"0">
  %r2z = cute.tuple_sub(%t2az, %t2bz)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"0">)
      -> !cute.int_tuple<"(?,?)">
  cute.print(%r2z) : !cute.int_tuple<"(?,?)">


  // shape_div: (12,20) / (3,4) → (4,5)
  %s12 = arith.constant 12 : i32
  %s20 = arith.constant 20 : i32
  %s3 = arith.constant 3 : i32
  %s4 = arith.constant 4 : i32
  %t6a = cute.make_shape (%s12, %s20) : (i32, i32) -> !cute.shape<"(?,?)">
  %t6b = cute.make_shape (%s3, %s4) : (i32, i32) -> !cute.shape<"(?,?)">
  %r6 = cute.shape_div(%t6a, %t6b)
       : (!cute.shape<"(?,?)">, !cute.shape<"(?,?)">) -> !cute.shape<"(?,?)">
  cute.print(%r6) : !cute.shape<"(?,?)">

  // shape_div tuple/scalar sequential: (4,5,6)/40 → (1,1,3).
  %s40 = arith.constant 40 : i32
  %s5 = arith.constant 5 : i32
  %s6 = arith.constant 6 : i32
  %t6aq = cute.make_shape (%s4, %s5, %s6)
       : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
  %t6bq = cute.make_shape (%s40) : (i32) -> !cute.shape<"?">
  %r6q = cute.shape_div(%t6aq, %t6bq)
       : (!cute.shape<"(?,?,?)">, !cute.shape<"?">)
      -> !cute.shape<"(?,?,?)">
  cute.print(%r6q) : !cute.shape<"(?,?,?)">

  // shape_div nested: ((8,10),(6,4))/((2,5),(3,2)) → ((4,2),(2,2)).
  %sn8 = arith.constant 8 : i32
  %sn10 = arith.constant 10 : i32
  %sn2 = arith.constant 2 : i32
  %t6an = cute.make_shape (%sn8, %sn10, %s6, %s4)
       : (i32, i32, i32, i32) -> !cute.shape<"((?,?),(?,?))">
  %t6bn = cute.make_shape (%sn2, %s5, %s3, %sn2)
       : (i32, i32, i32, i32) -> !cute.shape<"((?,?),(?,?))">
  %r6n = cute.shape_div(%t6an, %t6bn)
       : (!cute.shape<"((?,?),(?,?))">, !cute.shape<"((?,?),(?,?))">)
      -> !cute.shape<"((?,?),(?,?))">
  cute.print(%r6n) : !cute.shape<"((?,?),(?,?))">

  // ceil_div: ceildiv((10,11), (3,4)) → (4,3)
  %c10 = arith.constant 10 : i32
  %c11 = arith.constant 11 : i32
  %c3 = arith.constant 3 : i32
  %c4 = arith.constant 4 : i32
  %t7a = cute.make_int_tuple (%c10, %c11) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %t7b = cute.make_int_tuple (%c3, %c4) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r7 = cute.ceil_div(%t7a, %t7b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  cute.print(%r7) : !cute.int_tuple<"(?,?)">

  // ceil_div tuple/tuple with input-longer rank: (8,10,6)/(3,4) →
  // (3,3,6). Extra input element passes through unchanged.
  %c8 = arith.constant 8 : i32
  %c6 = arith.constant 6 : i32
  %t7am = cute.make_int_tuple (%c8, %c10, %c6)
       : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
  %t7bm = cute.make_int_tuple (%c3, %c4)
       : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r7m = cute.ceil_div(%t7am, %t7bm)
       : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?,?)">)
      -> !cute.int_tuple<"(?,?,?)">
  cute.print(%r7m) : !cute.int_tuple<"(?,?,?)">

  // ceil_div tuple/scalar sequential: (4,8)/2 → (2,8).
  %c2 = arith.constant 2 : i32
  %t7aq = cute.make_int_tuple (%c4, %c8)
       : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %t7bq = cute.make_int_tuple (%c2) : (i32) -> !cute.int_tuple<"?">
  %r7q = cute.ceil_div(%t7aq, %t7bq)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"?">)
      -> !cute.int_tuple<"(?,?)">
  cute.print(%r7q) : !cute.int_tuple<"(?,?)">

  return
}
