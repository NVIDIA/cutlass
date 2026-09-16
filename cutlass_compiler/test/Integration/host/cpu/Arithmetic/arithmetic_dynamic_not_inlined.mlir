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
// Not-inlined Arithmetic; runtime arith may survive -base-prepare across helper boundaries.
// elem_less and equal are excluded; covered in the runtime_dynamic flavor.
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

//===----------------------------------------------------------------------===//
// Per-op helpers — opaque-arg boundaries.
//===----------------------------------------------------------------------===//

func.func @h_tuple_add(%a0: i32, %a1: i32, %b0: i32, %b1: i32)
    -> !cute.int_tuple<"(?,?)"> {
  %a = cute.make_int_tuple (%a0, %a1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %b = cute.make_int_tuple (%b0, %b1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_add(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

func.func @h_tuple_add_rankmismatch(
    %a0: i32, %a1: i32, %a2: i32, %b0: i32, %b1: i32)
    -> !cute.int_tuple<"(?,?,?)"> {
  %a = cute.make_int_tuple (%a0, %a1, %a2)
       : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
  %b = cute.make_int_tuple (%b0, %b1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_add(%a, %b)
       : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?,?)">)
      -> !cute.int_tuple<"(?,?,?)">
  return %r : !cute.int_tuple<"(?,?,?)">
}

func.func @h_tuple_add_nested(
    %a0: i32, %a1: i32, %a2: i32, %b0: i32, %b1: i32, %b2: i32)
    -> !cute.int_tuple<"((?,?),?)"> {
  %a = cute.make_int_tuple (%a0, %a1, %a2)
       : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
  %b = cute.make_int_tuple (%b0, %b1, %b2)
       : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
  %r = cute.tuple_add(%a, %b)
       : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((?,?),?)">)
      -> !cute.int_tuple<"((?,?),?)">
  return %r : !cute.int_tuple<"((?,?),?)">
}

func.func @h_tuple_add_zero_identity(%a0: i32, %a1: i32)
    -> !cute.int_tuple<"(?,?)"> {
  %a = cute.make_int_tuple (%a0, %a1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %b = cute.static : !cute.int_tuple<"0">
  %r = cute.tuple_add(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"0">)
      -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

func.func @h_tuple_sub(%a0: i32, %a1: i32, %b0: i32, %b1: i32)
    -> !cute.int_tuple<"(?,?)"> {
  %a = cute.make_int_tuple (%a0, %a1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %b = cute.make_int_tuple (%b0, %b1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

func.func @h_tuple_sub_rankmismatch(
    %a0: i32, %a1: i32, %a2: i32, %b0: i32, %b1: i32)
    -> !cute.int_tuple<"(?,?,?)"> {
  %a = cute.make_int_tuple (%a0, %a1, %a2)
       : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
  %b = cute.make_int_tuple (%b0, %b1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?,?)">)
      -> !cute.int_tuple<"(?,?,?)">
  return %r : !cute.int_tuple<"(?,?,?)">
}

func.func @h_tuple_sub_nested(
    %a0: i32, %a1: i32, %a2: i32, %b0: i32, %b1: i32, %b2: i32)
    -> !cute.int_tuple<"((?,?),?)"> {
  %a = cute.make_int_tuple (%a0, %a1, %a2)
       : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
  %b = cute.make_int_tuple (%b0, %b1, %b2)
       : (i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"((?,?),?)">, !cute.int_tuple<"((?,?),?)">)
      -> !cute.int_tuple<"((?,?),?)">
  return %r : !cute.int_tuple<"((?,?),?)">
}

func.func @h_tuple_sub_zero_identity(%a0: i32, %a1: i32)
    -> !cute.int_tuple<"(?,?)"> {
  %a = cute.make_int_tuple (%a0, %a1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %b = cute.static : !cute.int_tuple<"0">
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"0">)
      -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

func.func @h_shape_div(%a0: i32, %a1: i32, %b0: i32, %b1: i32)
    -> !cute.shape<"(?,?)"> {
  %a = cute.make_shape (%a0, %a1) : (i32, i32) -> !cute.shape<"(?,?)">
  %b = cute.make_shape (%b0, %b1) : (i32, i32) -> !cute.shape<"(?,?)">
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"(?,?)">, !cute.shape<"(?,?)">) -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}

func.func @h_shape_div_sequential(%a0: i32, %a1: i32, %a2: i32, %b0: i32)
    -> !cute.shape<"(?,?,?)"> {
  %a = cute.make_shape (%a0, %a1, %a2)
       : (i32, i32, i32) -> !cute.shape<"(?,?,?)">
  %b = cute.make_shape (%b0) : (i32) -> !cute.shape<"?">
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"(?,?,?)">, !cute.shape<"?">)
      -> !cute.shape<"(?,?,?)">
  return %r : !cute.shape<"(?,?,?)">
}

func.func @h_shape_div_nested(
    %a0: i32, %a1: i32, %a2: i32, %a3: i32,
    %b0: i32, %b1: i32, %b2: i32, %b3: i32)
    -> !cute.shape<"((?,?),(?,?))"> {
  %a = cute.make_shape (%a0, %a1, %a2, %a3)
       : (i32, i32, i32, i32) -> !cute.shape<"((?,?),(?,?))">
  %b = cute.make_shape (%b0, %b1, %b2, %b3)
       : (i32, i32, i32, i32) -> !cute.shape<"((?,?),(?,?))">
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"((?,?),(?,?))">, !cute.shape<"((?,?),(?,?))">)
      -> !cute.shape<"((?,?),(?,?))">
  return %r : !cute.shape<"((?,?),(?,?))">
}

func.func @h_ceil_div(%a0: i32, %a1: i32, %b0: i32, %b1: i32)
    -> !cute.int_tuple<"(?,?)"> {
  %a = cute.make_int_tuple (%a0, %a1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %b = cute.make_int_tuple (%b0, %b1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

func.func @h_ceil_div_rankmismatch(
    %a0: i32, %a1: i32, %a2: i32, %b0: i32, %b1: i32)
    -> !cute.int_tuple<"(?,?,?)"> {
  %a = cute.make_int_tuple (%a0, %a1, %a2)
       : (i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
  %b = cute.make_int_tuple (%b0, %b1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"(?,?,?)">, !cute.int_tuple<"(?,?)">)
      -> !cute.int_tuple<"(?,?,?)">
  return %r : !cute.int_tuple<"(?,?,?)">
}

func.func @h_ceil_div_sequential(%a0: i32, %a1: i32, %b0: i32)
    -> !cute.int_tuple<"(?,?)"> {
  %a = cute.make_int_tuple (%a0, %a1) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  %b = cute.make_int_tuple (%b0) : (i32) -> !cute.int_tuple<"?">
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"(?,?)">, !cute.int_tuple<"?">)
      -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}

//===----------------------------------------------------------------------===//
// Entry point — helper-call only.
//===----------------------------------------------------------------------===//

func.func @main() {
  // tuple_add
  %a3 = arith.constant 3 : i32
  %a4 = arith.constant 4 : i32
  %a1 = arith.constant 1 : i32
  %a2 = arith.constant 2 : i32
  %r1 = func.call @h_tuple_add(%a3, %a4, %a1, %a2)
       : (i32, i32, i32, i32) -> !cute.int_tuple<"(?,?)">
  cute.print(%r1) : !cute.int_tuple<"(?,?)">

  // tuple_add rank-mismatch: (1,2,3) + (4,5) → (5,7,3).
  %a5 = arith.constant 5 : i32
  %r1m = func.call @h_tuple_add_rankmismatch(%a1, %a2, %a3, %a4, %a5)
       : (i32, i32, i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
  cute.print(%r1m) : !cute.int_tuple<"(?,?,?)">

  // tuple_add nested: ((1,2),3) + ((4,5),6) → ((5,7),9).
  %a6 = arith.constant 6 : i32
  %r1n = func.call @h_tuple_add_nested(%a1, %a2, %a3, %a4, %a5, %a6)
       : (i32, i32, i32, i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
  cute.print(%r1n) : !cute.int_tuple<"((?,?),?)">

  // tuple_add zero identity with dyn lhs: (7,11) + 0 → (7,11).
  %a7 = arith.constant 7 : i32
  %a11 = arith.constant 11 : i32
  %r1z = func.call @h_tuple_add_zero_identity(%a7, %a11)
       : (i32, i32) -> !cute.int_tuple<"(?,?)">
  cute.print(%r1z) : !cute.int_tuple<"(?,?)">

  // tuple_sub
  %a10 = arith.constant 10 : i32
  %a15 = arith.constant 15 : i32
  %b3 = arith.constant 3 : i32
  %b5 = arith.constant 5 : i32
  %r2 = func.call @h_tuple_sub(%a10, %a15, %b3, %b5)
       : (i32, i32, i32, i32) -> !cute.int_tuple<"(?,?)">
  cute.print(%r2) : !cute.int_tuple<"(?,?)">

  // tuple_sub rank-mismatch: (10,8,3) - (1,2) → (9,6,3).
  %s8 = arith.constant 8 : i32
  %r2m = func.call @h_tuple_sub_rankmismatch(%a10, %s8, %a3, %a1, %a2)
       : (i32, i32, i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
  cute.print(%r2m) : !cute.int_tuple<"(?,?,?)">

  // tuple_sub nested: ((10,15),5) - ((1,2),3) → ((9,13),2).
  %r2n = func.call @h_tuple_sub_nested(%a10, %a15, %b5, %a1, %a2, %b3)
       : (i32, i32, i32, i32, i32, i32) -> !cute.int_tuple<"((?,?),?)">
  cute.print(%r2n) : !cute.int_tuple<"((?,?),?)">

  // tuple_sub zero identity with dyn lhs: (7,11) - 0 → (7,11).
  %s7 = arith.constant 7 : i32
  %s11 = arith.constant 11 : i32
  %r2z = func.call @h_tuple_sub_zero_identity(%s7, %s11)
       : (i32, i32) -> !cute.int_tuple<"(?,?)">
  cute.print(%r2z) : !cute.int_tuple<"(?,?)">



  // shape_div
  %s12 = arith.constant 12 : i32
  %s20 = arith.constant 20 : i32
  %s3 = arith.constant 3 : i32
  %s4 = arith.constant 4 : i32
  %r6 = func.call @h_shape_div(%s12, %s20, %s3, %s4)
       : (i32, i32, i32, i32) -> !cute.shape<"(?,?)">
  cute.print(%r6) : !cute.shape<"(?,?)">

  // shape_div sequential: (4,5,6)/40 → (1,1,3).
  %s40 = arith.constant 40 : i32
  %s5 = arith.constant 5 : i32
  %s6 = arith.constant 6 : i32
  %r6q = func.call @h_shape_div_sequential(%s4, %s5, %s6, %s40)
       : (i32, i32, i32, i32) -> !cute.shape<"(?,?,?)">
  cute.print(%r6q) : !cute.shape<"(?,?,?)">

  // shape_div nested: ((8,10),(6,4))/((2,5),(3,2)) → ((4,2),(2,2)).
  %sn8 = arith.constant 8 : i32
  %sn10 = arith.constant 10 : i32
  %sn2 = arith.constant 2 : i32
  %r6n = func.call @h_shape_div_nested(%sn8, %sn10, %s6, %s4, %sn2, %s5, %s3, %sn2)
       : (i32, i32, i32, i32, i32, i32, i32, i32) -> !cute.shape<"((?,?),(?,?))">
  cute.print(%r6n) : !cute.shape<"((?,?),(?,?))">

  // ceil_div
  %c10 = arith.constant 10 : i32
  %c11 = arith.constant 11 : i32
  %c3 = arith.constant 3 : i32
  %c4 = arith.constant 4 : i32
  %r7 = func.call @h_ceil_div(%c10, %c11, %c3, %c4)
       : (i32, i32, i32, i32) -> !cute.int_tuple<"(?,?)">
  cute.print(%r7) : !cute.int_tuple<"(?,?)">

  // ceil_div rank-mismatch: (8,10,6)/(3,4) → (3,3,6).
  %c8 = arith.constant 8 : i32
  %c6 = arith.constant 6 : i32
  %r7m = func.call @h_ceil_div_rankmismatch(%c8, %c10, %c6, %c3, %c4)
       : (i32, i32, i32, i32, i32) -> !cute.int_tuple<"(?,?,?)">
  cute.print(%r7m) : !cute.int_tuple<"(?,?,?)">

  // ceil_div sequential: (4,8)/2 → (2,8).
  %c2 = arith.constant 2 : i32
  %r7q = func.call @h_ceil_div_sequential(%c4, %c8, %c2)
       : (i32, i32, i32) -> !cute.int_tuple<"(?,?)">
  cute.print(%r7q) : !cute.int_tuple<"(?,?)">

  return
}
