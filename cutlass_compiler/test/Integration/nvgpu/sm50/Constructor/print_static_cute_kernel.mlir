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
// All-static Constructor kernel; cute values from cute.static, printed via gpu.printf.
//
// One-thread guard around the prints (`tx == 0`) so each value
// prints exactly once. The kernel launches with 4 threads on a
// single block — the unguarded threads return without printing.

// CHECK: (2,3)
// CHECK: (1,4)
// CHECK: (5,_,7)
// CHECK: (1,(2,3),4)
// CHECK: [(2,3):(1,2);(4,5):(1,4)]
// CHECK: (8,4):(1,8)
// CHECK: (2,3):(1@0,1@1)
// CHECK: (4,5):(1,4) o 2 o (2,3):(1,2)
// CHECK: S<3,5,4> o 0 o (8,4):(1,8)
// CHECK: S<3,5,4>

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0 = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0 : index
      scf.if %is_zero {
        // !cute.shape — extent tuple.
        %s = cute.static : !cute.shape<"(2,3)">
        cute.print(%s) : !cute.shape<"(2,3)">

        // !cute.stride — stride tuple.
        %st = cute.static : !cute.stride<"(1,4)">
        cute.print(%st) : !cute.stride<"(1,4)">

        // !cute.coord — coord including underscore wildcards.
        %c = cute.static : !cute.coord<"(5,_,7)">
        cute.print(%c) : !cute.coord<"(5,_,7)">

        // !cute.int_tuple — nested integer tuple.
        %it = cute.static : !cute.int_tuple<"(1,(2,3),4)">
        cute.print(%it) : !cute.int_tuple<"(1,(2,3),4)">

        // !cute.tile — sequence of layouts in brackets.
        %t = cute.static : !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">
        cute.print(%t) : !cute.tile<"[(2,3):(1,2);(4,5):(1,4)]">

        // !cute.layout — canonical shape:stride pair.
        %l = cute.static : !cute.layout<"(8,4):(1,8)">
        cute.print(%l) : !cute.layout<"(8,4):(1,8)">

        // !cute.layout with scaled-basis strides.
        %lb = cute.static : !cute.layout<"(2,3):(1@0,1@1)">
        cute.print(%lb) : !cute.layout<"(2,3):(1@0,1@1)">

        // !cute.composed_layout with a layout outer.
        %cl = cute.static : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
        cute.print(%cl) : !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">

        // !cute.composed_layout with a swizzle outer.
        %csw = cute.static : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
        cute.print(%csw) : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">

        // !cute.swizzle — three-int compile-time bit-mask transform.
        %sw = cute.static : !cute.swizzle<"S<3,5,4>">
        cute.print(%sw) : !cute.swizzle<"S<3,5,4>">
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
