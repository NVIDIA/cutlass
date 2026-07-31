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
// All-static SizeIndex kernel; ops inline in gpu.func.

// CHECK: 12
// CHECK: 24
// CHECK: 9
// CHECK: 208
// crd2idx (2,3) on (4,8) → 14.
// CHECK: 14
// CHECK: (1,2)
// CHECK: (2,2)
// increment_coord wrap: (3,2) + (4,8) → (0,3).
// CHECK: (0,3)
// increment_coord hierarchical: (1,(2,0)) + (4,(3,8)) → (2,(2,0)).
// CHECK: (2,(2,0))
// CHECK: (4,8,1,1)
// CHECK: (1,1,4,8)
// CHECK: 30
// CHECK: (3,10)

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0 = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0 : index
      scf.if %is_zero {
        // size: (4,3) → 12
        %s1 = cute.static : !cute.shape<"(4,3)">
        %r1 = cute.size(%s1)
            : (!cute.shape<"(4,3)">) -> !cute.int_tuple<"12">
        cute.print(%r1) : !cute.int_tuple<"12">

        // cosize: (4,3,2):(1,4,12) → 24
        %l2 = cute.static : !cute.layout<"(4,3,2):(1,4,12)">
        %r2 = cute.cosize(%l2)
            : (!cute.layout<"(4,3,2):(1,4,12)">) -> !cute.int_tuple<"24">
        cute.print(%r2) : !cute.int_tuple<"24">

        // layout_eval: (1,2) + (4,8):(1,4) → 1*1 + 2*4 = 9
        %crd3 = cute.static : !cute.coord<"(1,2)">
        %l3 = cute.static : !cute.layout<"(4,8):(1,4)">
        %r3 = cute.layout_eval(%crd3, %l3)
            : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,4)">)
           -> !cute.int_tuple<"9">
        cute.print(%r3) : !cute.int_tuple<"9">

        // layout_eval on composed_layout: coord 6 on
        // `S<1,4,3> o 0 o (32):(32)` → 208.
        %crd3c = cute.static : !cute.coord<"6">
        %cl3 = cute.static : !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">
        %r3c = cute.layout_eval(%crd3c, %cl3)
            : (!cute.coord<"6">,
               !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
           -> !cute.int_tuple<"208">
        cute.print(%r3c) : !cute.int_tuple<"208">

        // crd2idx: (2,3) + (4,8) → 2 + 3*4 = 14.
        %crd3p = cute.static : !cute.coord<"(2,3)">
        %s3p = cute.static : !cute.shape<"(4,8)">
        %r3p = cute.crd2idx(%crd3p, %s3p)
            : (!cute.coord<"(2,3)">, !cute.shape<"(4,8)">)
           -> !cute.int_tuple<"14">
        cute.print(%r3p) : !cute.int_tuple<"14">

        // idx2crd: 9 + (4,8) → (1,2)
        %idx4 = cute.static : !cute.int_tuple<"9">
        %s4 = cute.static : !cute.shape<"(4,8)">
        %r4 = cute.idx2crd(%idx4, %s4)
            : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">)
           -> !cute.coord<"(1,2)">
        cute.print(%r4) : !cute.coord<"(1,2)">

        // increment_coord: (1,2) + (4,8) → (2,2)
        %c5 = cute.static : !cute.coord<"(1,2)">
        %s5 = cute.static : !cute.shape<"(4,8)">
        %r5 = cute.increment_coord(%c5, %s5)
            : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">)
           -> !cute.coord<"(2,2)">
        cute.print(%r5) : !cute.coord<"(2,2)">

        // increment_coord wrap: (3,2) + (4,8) → (0,3).
        %c5w = cute.static : !cute.coord<"(3,2)">
        %r5w = cute.increment_coord(%c5w, %s5)
            : (!cute.coord<"(3,2)">, !cute.shape<"(4,8)">)
           -> !cute.coord<"(0,3)">
        cute.print(%r5w) : !cute.coord<"(0,3)">

        // increment_coord hierarchical: (1,(2,0)) + (4,(3,8)) → (2,(2,0)).
        %c5h = cute.static : !cute.coord<"(1,(2,0))">
        %s5h = cute.static : !cute.shape<"(4,(3,8))">
        %r5h = cute.increment_coord(%c5h, %s5h)
            : (!cute.coord<"(1,(2,0))">, !cute.shape<"(4,(3,8))">)
           -> !cute.coord<"(2,(2,0))">
        cute.print(%r5h) : !cute.coord<"(2,(2,0))">

        // append_to_rank<4>: (4,8) padded with 1s → (4,8,1,1)
        %s6 = cute.static : !cute.shape<"(4,8)">
        %e6 = cute.static : !cute.shape<"1">
        %r6 = cute.append_to_rank<4>(%s6, %e6)
            : !cute.shape<"(4,8)">, !cute.shape<"1">
        cute.print(%r6) : !cute.shape<"(4,8,1,1)">

        // prepend_to_rank<4>.
        %r7 = cute.prepend_to_rank<4>(%s6, %e6)
            : !cute.shape<"(4,8)">, !cute.shape<"1">
        cute.print(%r7) : !cute.shape<"(1,1,4,8)">

        // tuple_product: (3,(2,5)) → 30
        %s8 = cute.static : !cute.int_tuple<"(3,(2,5))">
        %r8 = cute.tuple_product(%s8)
            : (!cute.int_tuple<"(3,(2,5))">) -> !cute.int_tuple<"30">
        cute.print(%r8) : !cute.int_tuple<"30">

        // tuple_product_each: (3,(2,5)) → (3,10)
        %r9 = cute.tuple_product_each(%s8)
            : (!cute.int_tuple<"(3,(2,5))">) -> !cute.int_tuple<"(3,10)">
        cute.print(%r9) : !cute.int_tuple<"(3,10)">

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
