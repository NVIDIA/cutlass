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

// REQUIRES: cutlass_compiler_device
// RUN: %cutlass-compiler-run-device %s | FileCheck %s
//
// All-static Arithmetic kernel; ops inline in gpu.func.
// elem_less and equal produce i1, extended via arith.extui for gpu.printf.

// CHECK: (4,6)
// CHECK: (5,7,3)
// CHECK: ((5,7),9)
// CHECK: (3,4)
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
// CHECK: 1
// CHECK: 0
// CHECK-COUNT-4: 1

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0 = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0 : index
      scf.if %is_zero {
        // tuple_add.
        %a_add = cute.static : !cute.int_tuple<"(3,4)">
        %b_add = cute.static : !cute.int_tuple<"(1,2)">
        %r1 = cute.tuple_add(%a_add, %b_add)
            : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(1,2)">)
           -> !cute.int_tuple<"(4,6)">
        cute.print(%r1) : !cute.int_tuple<"(4,6)">

        // tuple_add rank-mismatch: (1,2,3)+(4,5) → (5,7,3).
        %a_addm = cute.static : !cute.int_tuple<"(1,2,3)">
        %b_addm = cute.static : !cute.int_tuple<"(4,5)">
        %r1m = cute.tuple_add(%a_addm, %b_addm)
            : (!cute.int_tuple<"(1,2,3)">, !cute.int_tuple<"(4,5)">)
           -> !cute.int_tuple<"(5,7,3)">
        cute.print(%r1m) : !cute.int_tuple<"(5,7,3)">

        // tuple_add nested: ((1,2),3)+((4,5),6) → ((5,7),9).
        %a_addn = cute.static : !cute.int_tuple<"((1,2),3)">
        %b_addn = cute.static : !cute.int_tuple<"((4,5),6)">
        %r1n = cute.tuple_add(%a_addn, %b_addn)
            : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((4,5),6)">)
           -> !cute.int_tuple<"((5,7),9)">
        cute.print(%r1n) : !cute.int_tuple<"((5,7),9)">

        // tuple_add zero identity: (3,4) + 0 → (3,4).
        %a_addz = cute.static : !cute.int_tuple<"(3,4)">
        %b_addz = cute.static : !cute.int_tuple<"0">
        %r1z = cute.tuple_add(%a_addz, %b_addz)
            : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"0">)
           -> !cute.int_tuple<"(3,4)">
        cute.print(%r1z) : !cute.int_tuple<"(3,4)">

        // tuple_sub.
        %a_sub = cute.static : !cute.int_tuple<"(10,15)">
        %b_sub = cute.static : !cute.int_tuple<"(3,5)">
        %r2 = cute.tuple_sub(%a_sub, %b_sub)
            : (!cute.int_tuple<"(10,15)">, !cute.int_tuple<"(3,5)">)
           -> !cute.int_tuple<"(7,10)">
        cute.print(%r2) : !cute.int_tuple<"(7,10)">

        // tuple_sub rank-mismatch: (10,8,3) - (1,2) → (9,6,3).
        %a_subm = cute.static : !cute.int_tuple<"(10,8,3)">
        %b_subm = cute.static : !cute.int_tuple<"(1,2)">
        %r2m = cute.tuple_sub(%a_subm, %b_subm)
            : (!cute.int_tuple<"(10,8,3)">, !cute.int_tuple<"(1,2)">)
           -> !cute.int_tuple<"(9,6,3)">
        cute.print(%r2m) : !cute.int_tuple<"(9,6,3)">

        // tuple_sub nested: ((10,15),5) - ((1,2),3) → ((9,13),2).
        %a_subn = cute.static : !cute.int_tuple<"((10,15),5)">
        %b_subn = cute.static : !cute.int_tuple<"((1,2),3)">
        %r2n = cute.tuple_sub(%a_subn, %b_subn)
            : (!cute.int_tuple<"((10,15),5)">, !cute.int_tuple<"((1,2),3)">)
           -> !cute.int_tuple<"((9,13),2)">
        cute.print(%r2n) : !cute.int_tuple<"((9,13),2)">

        // tuple_sub zero identity: (7,11) - 0 → (7,11).
        %a_subz = cute.static : !cute.int_tuple<"(7,11)">
        %b_subz = cute.static : !cute.int_tuple<"0">
        %r2z = cute.tuple_sub(%a_subz, %b_subz)
            : (!cute.int_tuple<"(7,11)">, !cute.int_tuple<"0">)
           -> !cute.int_tuple<"(7,11)">
        cute.print(%r2z) : !cute.int_tuple<"(7,11)">

        // shape_div.
        %a_sd = cute.static : !cute.shape<"(12,20)">
        %b_sd = cute.static : !cute.shape<"(3,4)">
        %r6 = cute.shape_div(%a_sd, %b_sd)
            : (!cute.shape<"(12,20)">, !cute.shape<"(3,4)">)
           -> !cute.shape<"(4,5)">
        cute.print(%r6) : !cute.shape<"(4,5)">

        // shape_div sequential: (4,5,6)/40 → (1,1,3).
        %a_sdq = cute.static : !cute.shape<"(4,5,6)">
        %b_sdq = cute.static : !cute.shape<"40">
        %r6q = cute.shape_div(%a_sdq, %b_sdq)
            : (!cute.shape<"(4,5,6)">, !cute.shape<"40">)
           -> !cute.shape<"(1,1,3)">
        cute.print(%r6q) : !cute.shape<"(1,1,3)">

        // shape_div nested: ((8,10),(6,4))/((2,5),(3,2)) → ((4,2),(2,2)).
        %a_sdn = cute.static : !cute.shape<"((8,10),(6,4))">
        %b_sdn = cute.static : !cute.shape<"((2,5),(3,2))">
        %r6n = cute.shape_div(%a_sdn, %b_sdn)
            : (!cute.shape<"((8,10),(6,4))">, !cute.shape<"((2,5),(3,2))">)
           -> !cute.shape<"((4,2),(2,2))">
        cute.print(%r6n) : !cute.shape<"((4,2),(2,2))">

        // ceil_div: ceildiv(10,3)=4, ceildiv(11,4)=3.
        %a_cd = cute.static : !cute.int_tuple<"(10,11)">
        %b_cd = cute.static : !cute.int_tuple<"(3,4)">
        %r7 = cute.ceil_div(%a_cd, %b_cd)
            : (!cute.int_tuple<"(10,11)">, !cute.int_tuple<"(3,4)">)
           -> !cute.int_tuple<"(4,3)">
        cute.print(%r7) : !cute.int_tuple<"(4,3)">

        // ceil_div input-longer: (8,10,6)/(3,4) → (3,3,6).
        %a_cdm = cute.static : !cute.int_tuple<"(8,10,6)">
        %b_cdm = cute.static : !cute.int_tuple<"(3,4)">
        %r7m = cute.ceil_div(%a_cdm, %b_cdm)
            : (!cute.int_tuple<"(8,10,6)">, !cute.int_tuple<"(3,4)">)
           -> !cute.int_tuple<"(3,3,6)">
        cute.print(%r7m) : !cute.int_tuple<"(3,3,6)">

        // ceil_div sequential: (4,8)/2 → (2,8).
        %a_cdq = cute.static : !cute.int_tuple<"(4,8)">
        %b_cdq = cute.static : !cute.int_tuple<"2">
        %r7q = cute.ceil_div(%a_cdq, %b_cdq)
            : (!cute.int_tuple<"(4,8)">, !cute.int_tuple<"2">)
           -> !cute.int_tuple<"(2,8)">
        cute.print(%r7q) : !cute.int_tuple<"(2,8)">

        // elem_less: 3<5 && 4<6 → true. i1 → i32 → gpu.printf.
        %a_lt = cute.static : !cute.int_tuple<"(3,4)">
        %b_lt = cute.static : !cute.int_tuple<"(5,6)">
        %r8 = cute.elem_less(%a_lt, %b_lt)
            : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(5,6)">) -> i1
        %r8_i32 = arith.extui %r8 : i1 to i32
        gpu.printf "%d\n", %r8_i32 : i32

        // equal: (3,4) vs (3,5) differs at the second leaf → false.
        %a_eq = cute.static : !cute.int_tuple<"(3,4)">
        %b_eq = cute.static : !cute.int_tuple<"(3,5)">
        %r9 = cute.equal(%a_eq, %b_eq)
            : (!cute.int_tuple<"(3,4)">, !cute.int_tuple<"(3,5)">) -> i1
        %r9_i32 = arith.extui %r9 : i1 to i32
        gpu.printf "%d\n", %r9_i32 : i32

        // elem_less nested: ((1,2),3) < ((4,5),6) at every leaf → true.
        %a_ltn = cute.static : !cute.int_tuple<"((1,2),3)">
        %b_ltn = cute.static : !cute.int_tuple<"((4,5),6)">
        %r10 = cute.elem_less(%a_ltn, %b_ltn)
            : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((4,5),6)">) -> i1
        %r10_i32 = arith.extui %r10 : i1 to i32
        gpu.printf "%d\n", %r10_i32 : i32

        // equal nested: identical nested int_tuple ⇒ true.
        %a_eqn = cute.static : !cute.int_tuple<"((1,2),3)">
        %b_eqn = cute.static : !cute.int_tuple<"((1,2),3)">
        %r11 = cute.equal(%a_eqn, %b_eqn)
            : (!cute.int_tuple<"((1,2),3)">, !cute.int_tuple<"((1,2),3)">) -> i1
        %r11_i32 = arith.extui %r11 : i1 to i32
        gpu.printf "%d\n", %r11_i32 : i32

        // equal layout: identical static layout `(4,8):(1,4)` ⇒ true.
        %a_eql = cute.static : !cute.layout<"(4,8):(1,4)">
        %b_eql = cute.static : !cute.layout<"(4,8):(1,4)">
        %r12 = cute.equal(%a_eql, %b_eql)
            : (!cute.layout<"(4,8):(1,4)">, !cute.layout<"(4,8):(1,4)">) -> i1
        %r12_i32 = arith.extui %r12 : i1 to i32
        gpu.printf "%d\n", %r12_i32 : i32

        // equal stride: identical `(1,4)` ⇒ true.
        %a_eqs = cute.static : !cute.stride<"(1,4)">
        %b_eqs = cute.static : !cute.stride<"(1,4)">
        %r13 = cute.equal(%a_eqs, %b_eqs)
            : (!cute.stride<"(1,4)">, !cute.stride<"(1,4)">) -> i1
        %r13_i32 = arith.extui %r13 : i1 to i32
        gpu.printf "%d\n", %r13_i32 : i32
      }
      gpu.return
    }
  }

  func.func @main() {
    %c1 = arith.constant 1 : index
    %c4 = arith.constant 4 : index
    gpu.launch_func @kernel::@print_all blocks in (%c1, %c1, %c1) threads in (%c4, %c1, %c1)
    return
  }
}
