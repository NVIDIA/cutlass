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
// All-static LayoutAlgebra kernel; ops inline in gpu.func.
// CHECK: (5,4):(8,2)
// CHECK: 20:1
// CHECK: 2:1
// CHECK: ((4,5),6):((1,4),20)
// CHECK: (8,4):(1,8)
// CHECK: (2,4):(1,6)
// CHECK: (2):(1)
// CHECK: (3,4,5):(8,1,4)
// CHECK: (3,4):(4,1)
// CHECK: 12:1
// coalesce — nested static + with profile + composed_layout
// CHECK: (3,20):(8,1)
// CHECK: (3,20):(8,1)
// CHECK: (4,5):(1,4) o 2 o 20:1
// composed slice (affine A) — offset accumulates 2 + 1*1 = 3.
// CHECK: (4,5):(1,4) o 3 o (3):(8)
// composed dice (affine A) — A and offset preserved.
// CHECK: (4,5):(1,4) o 2 o (3):(8)

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0 = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0 : index
      scf.if %is_zero {
        // composition — (20):(2) ∘ (5,4):(4,1) = (5,4):(8,2)
        %o1 = cute.static : !cute.layout<"(20):(2)">
        %i1 = cute.static : !cute.layout<"(5,4):(4,1)">
        %r1 = cute.composition(%o1, %i1)
            : (!cute.layout<"(20):(2)">, !cute.layout<"(5,4):(4,1)">)
           -> !cute.layout<"(5,4):(8,2)">
        cute.print(%r1) : !cute.layout<"(5,4):(8,2)">

        // coalesce.
        %s2 = cute.static : !cute.layout<"(4,5):(1,4)">
        %r2 = cute.coalesce(%s2)
            : (!cute.layout<"(4,5):(1,4)">) -> !cute.layout<"20:1">
        cute.print(%r2) : !cute.layout<"20:1">

        // complement.
        %s3 = cute.static : !cute.layout<"3:2">
        %co = cute.static : !cute.shape<"6">
        %r3 = cute.complement(%s3, %co)
            : (!cute.layout<"3:2">, !cute.shape<"6">) -> !cute.layout<"2:1">
        cute.print(%r3) : !cute.layout<"2:1">

        // group_modes.
        %s4 = cute.static : !cute.layout<"(4,5,6):(1,4,20)">
        %r4 = cute.group_modes<0, 2>(%s4)
            : (!cute.layout<"(4,5,6):(1,4,20)">)
           -> !cute.layout<"((4,5),6):((1,4),20)">
        cute.print(%r4) : !cute.layout<"((4,5),6):((1,4),20)">

        // recast_layout.
        %s5 = cute.static : !cute.layout<"(32,4):(1,32)">
        %r5 = cute.recast_layout<32, 8>(%s5)
            : !cute.layout<"(32,4):(1,32)"> -> !cute.layout<"(8,4):(1,8)">
        cute.print(%r5) : !cute.layout<"(8,4):(1,8)">

        // slice — (_,0,_) keeps modes 0 and 2 → (2,4):(1,6)
        %s6 = cute.static : !cute.layout<"(2,3,4):(1,2,6)">
        %crd_s = cute.static : !cute.coord<"(_,0,_)">
        %r6 = cute.slice(%s6, %crd_s)
            : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(_,0,_)">
        cute.print(%r6) : !cute.layout<"(2,4):(1,6)">

        // dice — (1,_,_) drops modes 1 and 2 → (2):(1)
        %s7 = cute.static : !cute.layout<"(2,3,4):(1,2,6)">
        %crd_d = cute.static : !cute.coord<"(1,_,_)">
        %r7 = cute.dice(%s7, %crd_d)
            : !cute.layout<"(2,3,4):(1,2,6)">, !cute.coord<"(1,_,_)">
        cute.print(%r7) : !cute.layout<"(2):(1)">

        // flatten — collapse a layout's mode hierarchy to depth 1.
        %sf = cute.static : !cute.layout<"(3,(4,5)):(8,(1,4))">
        %rf = cute.flatten(%sf)
            : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,4,5):(8,1,4)">
        cute.print(%rf) : !cute.layout<"(3,4,5):(8,1,4)">

        // right_inverse.
        %s10 = cute.static : !cute.layout<"(4,3):(3,1)">
        %r10 = cute.right_inverse(%s10)
            : (!cute.layout<"(4,3):(3,1)">) -> !cute.layout<"(3,4):(4,1)">
        cute.print(%r10) : !cute.layout<"(3,4):(4,1)">

        // left_inverse.
        %s11 = cute.static : !cute.layout<"(4,3):(1,4)">
        %r11 = cute.left_inverse(%s11)
            : (!cute.layout<"(4,3):(1,4)">) -> !cute.layout<"12:1">
        cute.print(%r11) : !cute.layout<"12:1">

        // coalesce — nested static. Inner (4,5):(1,4) merges to 20:1,
        // outer mode 3:8 kept.
        %s12 = cute.static : !cute.layout<"(3,(4,5)):(8,(1,4))">
        %r12 = cute.coalesce(%s12)
            : (!cute.layout<"(3,(4,5)):(8,(1,4))">) -> !cute.layout<"(3,20):(8,1)">
        cute.print(%r12) : !cute.layout<"(3,20):(8,1)">

        // coalesce — with target_profile (static). Profile (1,1) selects
        // per-top-mode coalescing; result equals the nested-static case.
        %s13 = cute.static : !cute.layout<"(3,(4,5)):(8,(1,4))">
        %p13 = cute.static : !cute.coord<"(1,1)">
        %r13 = cute.coalesce(%s13, %p13)
            : (!cute.layout<"(3,(4,5)):(8,(1,4))">, !cute.coord<"(1,1)">)
           -> !cute.layout<"(3,20):(8,1)">
        cute.print(%r13) : !cute.layout<"(3,20):(8,1)">

        // coalesce — composed_layout. Coalesce applies only to B
        // ((4,5):(1,4) → 20:1); A and offset preserved.
        %s14 = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">
        %r14 = cute.coalesce(%s14)
            : (!cute.composed_layout<"(4,5):(1,4) o 2 o (4,5):(1,4)">)
           -> !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">
        cute.print(%r14) : !cute.composed_layout<"(4,5):(1,4) o 2 o 20:1">

        // slice — composed_layout (affine A). Fix mode 0 of B at
        // index 1; offset accumulates `2 + 1 * B_stride[0] = 3`.
        %s15 = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">
        %crd_sc = cute.static : !cute.coord<"(1,_)">
        %r15 = cute.slice(%s15, %crd_sc)
            : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3):(1,8)">,
              !cute.coord<"(1,_)">
        cute.print(%r15) : !cute.composed_layout<"(4,5):(1,4) o 3 o (3):(8)">

        // dice — composed_layout (affine A). A and offset unchanged;
        // B diced to keep mode 1 = (3):(8).
        %s16 = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3,4):(1,8,24)">
        %crd_dc = cute.static : !cute.coord<"(_,1,_)">
        %r16 = cute.dice(%s16, %crd_dc)
            : !cute.composed_layout<"(4,5):(1,4) o 2 o (8,3,4):(1,8,24)">,
              !cute.coord<"(_,1,_)">
        cute.print(%r16) : !cute.composed_layout<"(4,5):(1,4) o 2 o (3):(8)">
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
