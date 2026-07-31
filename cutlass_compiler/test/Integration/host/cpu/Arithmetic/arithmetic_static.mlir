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
// All-static Arithmetic; cute-fold-static evaluates every op; only arith.constant and arith.extui may remain.
// RUN: cutlass-compiler -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:     -base-prepare %s | FileCheck --check-prefix=POST-PREP %s
//
// POST-PREP-NOT: arith.{{[^ce]}}
// POST-PREP-NOT: arith.c{{[^o]}}
// POST-PREP-NOT: arith.extf
// POST-PREP-NOT: arith.exts

// Each op runs via direct inline and helper-call paths.
// elem_less and equal produce i1, extended to i32 via arith.extui for printf.

// CHECK-COUNT-2: (4,6)
// CHECK-COUNT-2: (5,7,3)
// CHECK-COUNT-2: ((5,7),9)
// CHECK-COUNT-2: (3,4)
// CHECK-COUNT-2: (7,10)
// CHECK-COUNT-2: (9,6,3)
// CHECK-COUNT-2: ((9,13),2)
// CHECK-COUNT-2: (7,11)
// CHECK-COUNT-2: (4,5)
// CHECK-COUNT-2: (1,1,3)
// CHECK-COUNT-2: ((4,2),(2,2))
// CHECK-COUNT-2: (4,3)
// CHECK-COUNT-2: (3,3,6)
// CHECK-COUNT-2: (2,8)
// CHECK-COUNT-2: 1
// CHECK-COUNT-2: 0
// CHECK-COUNT-8: 1

//===----------------------------------------------------------------------===//
// libc bridge: printf wrapper for raw i32 results (used by the
// elem_less / equal i1 → i32 path).
//===----------------------------------------------------------------------===//

llvm.func @printf(!llvm.ptr, ...) -> i32
llvm.mlir.global internal constant @fmt_i32("%d\0A\00") {addr_space = 0 : i32}

func.func @print_i32(%v: i32) {
  %p = llvm.mlir.addressof @fmt_i32 : !llvm.ptr
  %f = llvm.getelementptr %p[0, 0]
       : (!llvm.ptr) -> !llvm.ptr, !llvm.array<4 x i8>
  %r = llvm.call @printf(%f, %v) vararg(!llvm.func<i32 (ptr, ...)>)
       : (!llvm.ptr, i32) -> i32
  return
}

//===----------------------------------------------------------------------===//
// Per-op helpers: take the cute-typed inputs, run the op, return.
//===----------------------------------------------------------------------===//

func.func @h_tuple_add(%a: !cute.int_tuple<"(3,4)">, %b: !cute.int_tuple<"(1,2)">)
    -> !cute.int_tuple<"(4,6)"> {
  %r = cute.tuple_add(%a, %b)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(4,6)">
  return %r : !cute.int_tuple<"(4,6)">
}

func.func @h_tuple_add_rankmismatch(
    %a: !cute.int_tuple<"(1,2,3)">, %b: !cute.int_tuple<"(4,5)">)
    -> !cute.int_tuple<"(5,7,3)"> {
  %r = cute.tuple_add(%a, %b)
       : (!cute.int_tuple<"(1,2,3)">, !cute.int_tuple<"(4,5)">)
      -> !cute.int_tuple<"(5,7,3)">
  return %r : !cute.int_tuple<"(5,7,3)">
}

func.func @h_tuple_add_nested(
    %a: !cute.int_tuple<"((1,2),3)">, %b: !cute.int_tuple<"((4,5),6)">)
    -> !cute.int_tuple<"((5,7),9)"> {
  %r = cute.tuple_add(%a, %b)
       : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((4,5),6)">)
      -> !cute.int_tuple<"((5,7),9)">
  return %r : !cute.int_tuple<"((5,7),9)">
}

func.func @h_tuple_add_zero_identity(
    %a: !cute.int_tuple<"(3,4)">, %b: !cute.int_tuple<"0">)
    -> !cute.int_tuple<"(3,4)"> {
  %r = cute.tuple_add(%a, %b)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"0">)
      -> !cute.int_tuple<"(3,4)">
  return %r : !cute.int_tuple<"(3,4)">
}

func.func @h_tuple_sub(%a: !cute.int_tuple<"(10,15)">, %b: !cute.int_tuple<"(3,5)">)
    -> !cute.int_tuple<"(7,10)"> {
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"(10,15)">, !cute.int_tuple<"(3,5)">) -> !cute.int_tuple<"(7,10)">
  return %r : !cute.int_tuple<"(7,10)">
}

func.func @h_tuple_sub_rankmismatch(
    %a: !cute.int_tuple<"(10,8,3)">, %b: !cute.int_tuple<"(1,2)">)
    -> !cute.int_tuple<"(9,6,3)"> {
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"(10,8,3)">, !cute.int_tuple<"(1,2)">)
      -> !cute.int_tuple<"(9,6,3)">
  return %r : !cute.int_tuple<"(9,6,3)">
}

func.func @h_tuple_sub_nested(
    %a: !cute.int_tuple<"((10,15),5)">, %b: !cute.int_tuple<"((1,2),3)">)
    -> !cute.int_tuple<"((9,13),2)"> {
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"((10,15),5)">, !cute.int_tuple<"((1,2),3)">)
      -> !cute.int_tuple<"((9,13),2)">
  return %r : !cute.int_tuple<"((9,13),2)">
}

func.func @h_tuple_sub_zero_identity(
    %a: !cute.int_tuple<"(7,11)">, %b: !cute.int_tuple<"0">)
    -> !cute.int_tuple<"(7,11)"> {
  %r = cute.tuple_sub(%a, %b)
       : (!cute.int_tuple<"(7,11)">, !cute.int_tuple<"0">)
      -> !cute.int_tuple<"(7,11)">
  return %r : !cute.int_tuple<"(7,11)">
}

func.func @h_shape_div(%a: !cute.shape<"(12,20)">, %b: !cute.shape<"(3,4)">)
    -> !cute.shape<"(4,5)"> {
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"(12,20)">, !cute.shape<"(3,4)">) -> !cute.shape<"(4,5)">
  return %r : !cute.shape<"(4,5)">
}

func.func @h_shape_div_sequential(
    %a: !cute.shape<"(4,5,6)">, %b: !cute.shape<"40">)
    -> !cute.shape<"(1,1,3)"> {
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"(4,5,6)">, !cute.shape<"40">)
      -> !cute.shape<"(1,1,3)">
  return %r : !cute.shape<"(1,1,3)">
}

func.func @h_shape_div_nested(
    %a: !cute.shape<"((8,10),(6,4))">, %b: !cute.shape<"((2,5),(3,2))">)
    -> !cute.shape<"((4,2),(2,2))"> {
  %r = cute.shape_div(%a, %b)
       : (!cute.shape<"((8,10),(6,4))">, !cute.shape<"((2,5),(3,2))">)
      -> !cute.shape<"((4,2),(2,2))">
  return %r : !cute.shape<"((4,2),(2,2))">
}

func.func @h_ceil_div(%a: !cute.int_tuple<"(10,11)">, %b: !cute.int_tuple<"(3,4)">)
    -> !cute.int_tuple<"(4,3)"> {
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"(10,11)">, !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(4,3)">
  return %r : !cute.int_tuple<"(4,3)">
}

func.func @h_ceil_div_rankmismatch(
    %a: !cute.int_tuple<"(8,10,6)">, %b: !cute.int_tuple<"(3,4)">)
    -> !cute.int_tuple<"(3,3,6)"> {
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"(8,10,6)">, !cute.int_tuple<"(3,4)">)
      -> !cute.int_tuple<"(3,3,6)">
  return %r : !cute.int_tuple<"(3,3,6)">
}

func.func @h_ceil_div_sequential(
    %a: !cute.int_tuple<"(4,8)">, %b: !cute.int_tuple<"2">)
    -> !cute.int_tuple<"(2,8)"> {
  %r = cute.ceil_div(%a, %b)
       : (!cute.int_tuple<"(4,8)">, !cute.int_tuple<"2">)
      -> !cute.int_tuple<"(2,8)">
  return %r : !cute.int_tuple<"(2,8)">
}

func.func @h_elem_less(%a: !cute.int_tuple<"(3,4)">, %b: !cute.int_tuple<"(5,6)">)
    -> i1 {
  %r = cute.elem_less(%a, %b)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(5,6)">) -> i1
  return %r : i1
}

func.func @h_equal(%a: !cute.int_tuple<"(3,4)">, %b: !cute.int_tuple<"(3,5)">)
    -> i1 {
  %r = cute.equal(%a, %b)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,5)">) -> i1
  return %r : i1
}

func.func @h_elem_less_nested(
    %a: !cute.int_tuple<"((1,2),3)">, %b: !cute.int_tuple<"((4,5),6)">) -> i1 {
  %r = cute.elem_less(%a, %b)
       : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((4,5),6)">) -> i1
  return %r : i1
}

func.func @h_equal_nested(
    %a: !cute.int_tuple<"((1,2),3)">, %b: !cute.int_tuple<"((1,2),3)">) -> i1 {
  %r = cute.equal(%a, %b)
       : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((1,2),3)">) -> i1
  return %r : i1
}

func.func @h_equal_layout(
    %a: !cute.layout<"(4,8):(1,4)">, %b: !cute.layout<"(4,8):(1,4)">) -> i1 {
  %r = cute.equal(%a, %b)
       : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(4,8):(1,4)">) -> i1
  return %r : i1
}

func.func @h_equal_stride(
    %a: !cute.stride<"(1,4)">, %b: !cute.stride<"(1,4)">) -> i1 {
  %r = cute.equal(%a, %b)
       : (!cute.stride<"(1,4)">, !cute.stride<"(1,4)">) -> i1
  return %r : i1
}

//===----------------------------------------------------------------------===//
// Entry point: per-op direct + helper-call print pairs.
//===----------------------------------------------------------------------===//

func.func @main() {
  // tuple_add — elementwise integer add over int_tuple.
  %a_add = cute.static : !cute.int_tuple<"(3,4)">
  %b_add = cute.static : !cute.int_tuple<"(1,2)">
  %r1 = cute.tuple_add(%a_add, %b_add)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(4,6)">
  cute.print(%r1) : !cute.int_tuple<"(4,6)">
  %r1b = func.call @h_tuple_add(%a_add, %b_add)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(1,2)">) -> !cute.int_tuple<"(4,6)">
  cute.print(%r1b) : !cute.int_tuple<"(4,6)">

  // tuple_add — rank-mismatch: extra lhs element passes through.
  // (1,2,3) + (4,5) → (5,7,3).
  %a_addm = cute.static : !cute.int_tuple<"(1,2,3)">
  %b_addm = cute.static : !cute.int_tuple<"(4,5)">
  %r1m = cute.tuple_add(%a_addm, %b_addm)
       : (!cute.int_tuple<"(1,2,3)">, !cute.int_tuple<"(4,5)">)
      -> !cute.int_tuple<"(5,7,3)">
  cute.print(%r1m) : !cute.int_tuple<"(5,7,3)">
  %r1mb = func.call @h_tuple_add_rankmismatch(%a_addm, %b_addm)
       : (!cute.int_tuple<"(1,2,3)">, !cute.int_tuple<"(4,5)">)
      -> !cute.int_tuple<"(5,7,3)">
  cute.print(%r1mb) : !cute.int_tuple<"(5,7,3)">

  // tuple_add — nested: recursion into sub-tuples.
  // ((1,2),3) + ((4,5),6) → ((5,7),9).
  %a_addn = cute.static : !cute.int_tuple<"((1,2),3)">
  %b_addn = cute.static : !cute.int_tuple<"((4,5),6)">
  %r1n = cute.tuple_add(%a_addn, %b_addn)
       : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((4,5),6)">)
      -> !cute.int_tuple<"((5,7),9)">
  cute.print(%r1n) : !cute.int_tuple<"((5,7),9)">
  %r1nb = func.call @h_tuple_add_nested(%a_addn, %b_addn)
       : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((4,5),6)">)
      -> !cute.int_tuple<"((5,7),9)">
  cute.print(%r1nb) : !cute.int_tuple<"((5,7),9)">

  // tuple_add — zero-scalar identity: (3,4) + 0 → (3,4).
  %a_addz = cute.static : !cute.int_tuple<"(3,4)">
  %b_addz = cute.static : !cute.int_tuple<"0">
  %r1z = cute.tuple_add(%a_addz, %b_addz)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"0">)
      -> !cute.int_tuple<"(3,4)">
  cute.print(%r1z) : !cute.int_tuple<"(3,4)">
  %r1zb = func.call @h_tuple_add_zero_identity(%a_addz, %b_addz)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"0">)
      -> !cute.int_tuple<"(3,4)">
  cute.print(%r1zb) : !cute.int_tuple<"(3,4)">

  // tuple_sub — elementwise integer subtract.
  %a_sub = cute.static : !cute.int_tuple<"(10,15)">
  %b_sub = cute.static : !cute.int_tuple<"(3,5)">
  %r2 = cute.tuple_sub(%a_sub, %b_sub)
       : (!cute.int_tuple<"(10,15)">, !cute.int_tuple<"(3,5)">) -> !cute.int_tuple<"(7,10)">
  cute.print(%r2) : !cute.int_tuple<"(7,10)">
  %r2b = func.call @h_tuple_sub(%a_sub, %b_sub)
       : (!cute.int_tuple<"(10,15)">, !cute.int_tuple<"(3,5)">) -> !cute.int_tuple<"(7,10)">
  cute.print(%r2b) : !cute.int_tuple<"(7,10)">

  // tuple_sub — rank-mismatch: extra lhs element passes through.
  // (10,8,3) - (1,2) → (9,6,3).
  %a_subm = cute.static : !cute.int_tuple<"(10,8,3)">
  %b_subm = cute.static : !cute.int_tuple<"(1,2)">
  %r2m = cute.tuple_sub(%a_subm, %b_subm)
       : (!cute.int_tuple<"(10,8,3)">, !cute.int_tuple<"(1,2)">)
      -> !cute.int_tuple<"(9,6,3)">
  cute.print(%r2m) : !cute.int_tuple<"(9,6,3)">
  %r2mb = func.call @h_tuple_sub_rankmismatch(%a_subm, %b_subm)
       : (!cute.int_tuple<"(10,8,3)">, !cute.int_tuple<"(1,2)">)
      -> !cute.int_tuple<"(9,6,3)">
  cute.print(%r2mb) : !cute.int_tuple<"(9,6,3)">

  // tuple_sub — nested: recursion into sub-tuples.
  // ((10,15),5) - ((1,2),3) → ((9,13),2).
  %a_subn = cute.static : !cute.int_tuple<"((10,15),5)">
  %b_subn = cute.static : !cute.int_tuple<"((1,2),3)">
  %r2n = cute.tuple_sub(%a_subn, %b_subn)
       : (!cute.int_tuple<"((10,15),5)">, !cute.int_tuple<"((1,2),3)">)
      -> !cute.int_tuple<"((9,13),2)">
  cute.print(%r2n) : !cute.int_tuple<"((9,13),2)">
  %r2nb = func.call @h_tuple_sub_nested(%a_subn, %b_subn)
       : (!cute.int_tuple<"((10,15),5)">, !cute.int_tuple<"((1,2),3)">)
      -> !cute.int_tuple<"((9,13),2)">
  cute.print(%r2nb) : !cute.int_tuple<"((9,13),2)">

  // tuple_sub — zero-scalar rhs identity: (7,11) - 0 → (7,11).
  %a_subz = cute.static : !cute.int_tuple<"(7,11)">
  %b_subz = cute.static : !cute.int_tuple<"0">
  %r2z = cute.tuple_sub(%a_subz, %b_subz)
       : (!cute.int_tuple<"(7,11)">, !cute.int_tuple<"0">)
      -> !cute.int_tuple<"(7,11)">
  cute.print(%r2z) : !cute.int_tuple<"(7,11)">
  %r2zb = func.call @h_tuple_sub_zero_identity(%a_subz, %b_subz)
       : (!cute.int_tuple<"(7,11)">, !cute.int_tuple<"0">)
      -> !cute.int_tuple<"(7,11)">
  cute.print(%r2zb) : !cute.int_tuple<"(7,11)">

  // shape_div — elementwise shape divisibility-check + divide.
  %a_sd = cute.static : !cute.shape<"(12,20)">
  %b_sd = cute.static : !cute.shape<"(3,4)">
  %r6 = cute.shape_div(%a_sd, %b_sd)
       : (!cute.shape<"(12,20)">, !cute.shape<"(3,4)">) -> !cute.shape<"(4,5)">
  cute.print(%r6) : !cute.shape<"(4,5)">
  %r6b = func.call @h_shape_div(%a_sd, %b_sd)
       : (!cute.shape<"(12,20)">, !cute.shape<"(3,4)">) -> !cute.shape<"(4,5)">
  cute.print(%r6b) : !cute.shape<"(4,5)">

  // shape_div tuple/scalar sequential consumption: (4,5,6)/40 → (1,1,3).
  // Divides the first element by the running scalar, reduces the scalar,
  // and continues across the tuple.
  %a_sdq = cute.static : !cute.shape<"(4,5,6)">
  %b_sdq = cute.static : !cute.shape<"40">
  %r6q = cute.shape_div(%a_sdq, %b_sdq)
       : (!cute.shape<"(4,5,6)">, !cute.shape<"40">)
      -> !cute.shape<"(1,1,3)">
  cute.print(%r6q) : !cute.shape<"(1,1,3)">
  %r6qb = func.call @h_shape_div_sequential(%a_sdq, %b_sdq)
       : (!cute.shape<"(4,5,6)">, !cute.shape<"40">)
      -> !cute.shape<"(1,1,3)">
  cute.print(%r6qb) : !cute.shape<"(1,1,3)">

  // shape_div nested: ((8,10),(6,4))/((2,5),(3,2)) → ((4,2),(2,2)).
  %a_sdn = cute.static : !cute.shape<"((8,10),(6,4))">
  %b_sdn = cute.static : !cute.shape<"((2,5),(3,2))">
  %r6n = cute.shape_div(%a_sdn, %b_sdn)
       : (!cute.shape<"((8,10),(6,4))">, !cute.shape<"((2,5),(3,2))">)
      -> !cute.shape<"((4,2),(2,2))">
  cute.print(%r6n) : !cute.shape<"((4,2),(2,2))">
  %r6nb = func.call @h_shape_div_nested(%a_sdn, %b_sdn)
       : (!cute.shape<"((8,10),(6,4))">, !cute.shape<"((2,5),(3,2))">)
      -> !cute.shape<"((4,2),(2,2))">
  cute.print(%r6nb) : !cute.shape<"((4,2),(2,2))">

  // ceil_div — elementwise ceiling-divide: ceildiv(10,3)=4, ceildiv(11,4)=3.
  %a_cd = cute.static : !cute.int_tuple<"(10,11)">
  %b_cd = cute.static : !cute.int_tuple<"(3,4)">
  %r7 = cute.ceil_div(%a_cd, %b_cd)
       : (!cute.int_tuple<"(10,11)">, !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(4,3)">
  cute.print(%r7) : !cute.int_tuple<"(4,3)">
  %r7b = func.call @h_ceil_div(%a_cd, %b_cd)
       : (!cute.int_tuple<"(10,11)">, !cute.int_tuple<"(3,4)">) -> !cute.int_tuple<"(4,3)">
  cute.print(%r7b) : !cute.int_tuple<"(4,3)">

  // ceil_div tuple/tuple with input-longer rank: (8,10,6)/(3,4) →
  // (3,3,6). Extra input element passes through unchanged.
  %a_cdm = cute.static : !cute.int_tuple<"(8,10,6)">
  %b_cdm = cute.static : !cute.int_tuple<"(3,4)">
  %r7m = cute.ceil_div(%a_cdm, %b_cdm)
       : (!cute.int_tuple<"(8,10,6)">, !cute.int_tuple<"(3,4)">)
      -> !cute.int_tuple<"(3,3,6)">
  cute.print(%r7m) : !cute.int_tuple<"(3,3,6)">
  %r7mb = func.call @h_ceil_div_rankmismatch(%a_cdm, %b_cdm)
       : (!cute.int_tuple<"(8,10,6)">, !cute.int_tuple<"(3,4)">)
      -> !cute.int_tuple<"(3,3,6)">
  cute.print(%r7mb) : !cute.int_tuple<"(3,3,6)">

  // ceil_div tuple/scalar sequential consumption: (4,8)/2 → (2,8).
  // ceil_div(4, 2) = 2, tiler shrinks to ceil(2/4) = 1; ceil_div(8, 1) = 8.
  %a_cdq = cute.static : !cute.int_tuple<"(4,8)">
  %b_cdq = cute.static : !cute.int_tuple<"2">
  %r7q = cute.ceil_div(%a_cdq, %b_cdq)
       : (!cute.int_tuple<"(4,8)">, !cute.int_tuple<"2">)
      -> !cute.int_tuple<"(2,8)">
  cute.print(%r7q) : !cute.int_tuple<"(2,8)">
  %r7qb = func.call @h_ceil_div_sequential(%a_cdq, %b_cdq)
       : (!cute.int_tuple<"(4,8)">, !cute.int_tuple<"2">)
      -> !cute.int_tuple<"(2,8)">
  cute.print(%r7qb) : !cute.int_tuple<"(2,8)">

  // elem_less — elementwise less-than reduced to a single i1: 3<5 && 4<6 → true.
  %a_lt = cute.static : !cute.int_tuple<"(3,4)">
  %b_lt = cute.static : !cute.int_tuple<"(5,6)">
  %r8 = cute.elem_less(%a_lt, %b_lt)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(5,6)">) -> i1
  %r8_i32 = arith.extui %r8 : i1 to i32
  func.call @print_i32(%r8_i32) : (i32) -> ()
  %r8b = func.call @h_elem_less(%a_lt, %b_lt)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(5,6)">) -> i1
  %r8b_i32 = arith.extui %r8b : i1 to i32
  func.call @print_i32(%r8b_i32) : (i32) -> ()

  // equal — i1 result; (3,4) vs (3,5) differs at the second leaf → false.
  %a_eq = cute.static : !cute.int_tuple<"(3,4)">
  %b_eq = cute.static : !cute.int_tuple<"(3,5)">
  %r9 = cute.equal(%a_eq, %b_eq)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,5)">) -> i1
  %r9_i32 = arith.extui %r9 : i1 to i32
  func.call @print_i32(%r9_i32) : (i32) -> ()
  %r9b = func.call @h_equal(%a_eq, %b_eq)
       : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,5)">) -> i1
  %r9b_i32 = arith.extui %r9b : i1 to i32
  func.call @print_i32(%r9b_i32) : (i32) -> ()

  // elem_less nested — `((1,2),3) < ((4,5),6)` true at every leaf → true.
  %a_ltn = cute.static : !cute.int_tuple<"((1,2),3)">
  %b_ltn = cute.static : !cute.int_tuple<"((4,5),6)">
  %r10 = cute.elem_less(%a_ltn, %b_ltn)
       : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((4,5),6)">) -> i1
  %r10_i32 = arith.extui %r10 : i1 to i32
  func.call @print_i32(%r10_i32) : (i32) -> ()
  %r10b = func.call @h_elem_less_nested(%a_ltn, %b_ltn)
       : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((4,5),6)">) -> i1
  %r10b_i32 = arith.extui %r10b : i1 to i32
  func.call @print_i32(%r10b_i32) : (i32) -> ()

  // equal nested — identical nested int_tuple ⇒ Type-identity fold ⇒ true.
  %a_eqn = cute.static : !cute.int_tuple<"((1,2),3)">
  %b_eqn = cute.static : !cute.int_tuple<"((1,2),3)">
  %r11 = cute.equal(%a_eqn, %b_eqn)
       : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((1,2),3)">) -> i1
  %r11_i32 = arith.extui %r11 : i1 to i32
  func.call @print_i32(%r11_i32) : (i32) -> ()
  %r11b = func.call @h_equal_nested(%a_eqn, %b_eqn)
       : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((1,2),3)">) -> i1
  %r11b_i32 = arith.extui %r11b : i1 to i32
  func.call @print_i32(%r11b_i32) : (i32) -> ()

  // equal layout — identical `(4,8):(1,4)` ⇒ true. Exercises the Layout
  // operand kind end-to-end (shape-then-stride leaves under the hood).
  %a_eql = cute.static : !cute.layout<"(4,8):(1,4)">
  %b_eql = cute.static : !cute.layout<"(4,8):(1,4)">
  %r12 = cute.equal(%a_eql, %b_eql)
       : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(4,8):(1,4)">) -> i1
  %r12_i32 = arith.extui %r12 : i1 to i32
  func.call @print_i32(%r12_i32) : (i32) -> ()
  %r12b = func.call @h_equal_layout(%a_eql, %b_eql)
       : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(4,8):(1,4)">) -> i1
  %r12b_i32 = arith.extui %r12b : i1 to i32
  func.call @print_i32(%r12b_i32) : (i32) -> ()

  // equal stride — identical `(1,4)` ⇒ true. Stride is supported.
  %a_eqs = cute.static : !cute.stride<"(1,4)">
  %b_eqs = cute.static : !cute.stride<"(1,4)">
  %r13 = cute.equal(%a_eqs, %b_eqs)
       : (!cute.stride<"(1,4)">, !cute.stride<"(1,4)">) -> i1
  %r13_i32 = arith.extui %r13 : i1 to i32
  func.call @print_i32(%r13_i32) : (i32) -> ()
  %r13b = func.call @h_equal_stride(%a_eqs, %b_eqs)
       : (!cute.stride<"(1,4)">, !cute.stride<"(1,4)">) -> i1
  %r13b_i32 = arith.extui %r13b : i1 to i32
  func.call @print_i32(%r13b_i32) : (i32) -> ()

  return
}
