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
// Dynamic Constructor kernel; cute values built via cute.make_* from kernel-internal arith.constant.
// One-thread guard around the prints (`tx == 0`); 4 threads launch,
// only thread 0 prints — others fall through `gpu.return`.
//
// `!cute.swizzle` is excluded — its three integers always live in
// the type signature, never as dynamic operands.

// CHECK: (5,7)
// CHECK: (10,1)
// CHECK: (12,_,15)
// CHECK: (20,3,25)
// CHECK: [(30,3):(1,35)]
// CHECK: (40,4):(1,40)
// CHECK: (45,8):(1,45)
// CHECK: (4,5):(1,4) o 50 o (2,3):(1,2)
// CHECK: S<3,5,4> o 60 o (8,4):(1,8)
// Composed-layout print-order fix-up cases — each of the 5 cases below
// builds the same logical composed layout `(4,5):(1,4) o 50 o (2,3):(1,2)`
// via a different static/dynamic placement, exercising the per-component
// re-ordering in `PrintOpConversion` (CuteToBase.cpp). All 5 must print
// the same canonical string; if the print-order fix-up regresses, the
// leaves will land in the wrong slots and the CHECK fails.
// CHECK: (4,5):(1,4) o 50 o (2,3):(1,2)
// CHECK: (4,5):(1,4) o 50 o (2,3):(1,2)
// CHECK: (4,5):(1,4) o 50 o (2,3):(1,2)
// CHECK: (4,5):(1,4) o 50 o (2,3):(1,2)
// CHECK: (4,5):(1,4) o 50 o (2,3):(1,2)

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0_idx = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0_idx : index
      scf.if %is_zero {
        // !cute.shape — both leaves dynamic.
        %x5 = arith.constant 5 : i32
        %x7 = arith.constant 7 : i32
        %s = cute.make_shape (%x5, %x7) : (i32, i32) -> !cute.shape<"(?,?)">
        cute.print(%s) : !cute.shape<"(?,?)">

        // !cute.stride — first leaf dynamic, second static.
        %x10 = arith.constant 10 : i32
        %st = cute.make_stride (%x10) : (i32) -> !cute.stride<"(?,1)">
        cute.print(%st) : !cute.stride<"(?,1)">

        // !cute.coord — dyn + underscore + dyn.
        %x12 = arith.constant 12 : i32
        %x15 = arith.constant 15 : i32
        %c = cute.make_coord (%x12, %x15) : (i32, i32) -> !cute.coord<"(?,_,?)">
        cute.print(%c) : !cute.coord<"(?,_,?)">

        // !cute.int_tuple — dyn + static + dyn.
        %x20 = arith.constant 20 : i32
        %x25 = arith.constant 25 : i32
        %it = cute.make_int_tuple (%x20, %x25)
              : (i32, i32) -> !cute.int_tuple<"(?,3,?)">
        cute.print(%it) : !cute.int_tuple<"(?,3,?)">

        // !cute.tile — single layout, one dyn shape leaf + one dyn stride leaf.
        %x30 = arith.constant 30 : i32
        %x35 = arith.constant 35 : i32
        %t = cute.make_tile (%x30, %x35) : (i32, i32)
             -> !cute.tile<"[(?,3):(1,?)]">
        cute.print(%t) : !cute.tile<"[(?,3):(1,?)]">

        // !cute.layout (1-operand form) — col-major stride synthesized.
        %x40 = arith.constant 40 : i32
        %sh1 = cute.make_shape (%x40) : (i32) -> !cute.shape<"(?,4)">
        %l1_stride = cute.make_stride (%x40) : (i32) -> !cute.stride<"(1,?)">
        %l1 = cute.make_layout (%sh1, %l1_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
        cute.print(%l1) : !cute.layout<"(?,4):(1,?)">

        // !cute.layout (2-operand form) — explicit shape + stride.
        %x45 = arith.constant 45 : i32
        %sh2 = cute.make_shape (%x45) : (i32) -> !cute.shape<"(?,8)">
        %st2_l = cute.make_stride (%x45) : (i32) -> !cute.stride<"(1,?)">
        %l2 = cute.make_layout (%sh2, %st2_l)
             : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">)
            -> !cute.layout<"(?,8):(1,?)">
        cute.print(%l2) : !cute.layout<"(?,8):(1,?)">

        // !cute.composed_layout — static layout outer, dyn offset.
        %a_in = cute.static : !cute.layout<"(4,5):(1,4)">
        %x50 = arith.constant 50 : i32
        %off1 = cute.make_int_tuple (%x50) : (i32) -> !cute.int_tuple<"?">
        %b_in = cute.static : !cute.layout<"(2,3):(1,2)">
        %cl = cute.make_composed_layout (%a_in, %off1, %b_in)
              : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"?">,
                 !cute.layout<"(2,3):(1,2)">)
             -> !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
        cute.print(%cl) : !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">

        // !cute.composed_layout — static swizzle outer, dyn offset.
        %sw_in = cute.static : !cute.swizzle<"S<3,5,4>">
        %x60 = arith.constant 60 : i32
        %off2 = cute.make_int_tuple (%x60) : (i32) -> !cute.int_tuple<"?">
        %lin = cute.static : !cute.layout<"(8,4):(1,8)">
        %csw = cute.make_composed_layout (%sw_in, %off2, %lin)
              : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"?">,
                 !cute.layout<"(8,4):(1,8)">)
             -> !cute.composed_layout<"S<3,5,4> o ? o (8,4):(1,8)">
        cute.print(%csw) : !cute.composed_layout<"S<3,5,4> o ? o (8,4):(1,8)">

        // Print-order fix-up cases — five different static/dynamic placements
        // of the same logical composed layout `(4,5):(1,4) o 50 o (2,3):(1,2)`.
        // Each must print the canonical string; if the per-component re-ordering
        // in `PrintOpConversion` regresses, leaves will land in the wrong slots.
        %x1 = arith.constant 1 : i32
        %x2 = arith.constant 2 : i32
        %x3 = arith.constant 3 : i32
        %x4 = arith.constant 4 : i32

        // Case 1: all-dynamic A, dyn offset, all-dynamic B.
        %sh_a_1 = cute.make_shape (%x4, %x5) : (i32, i32) -> !cute.shape<"(?,?)">
        %st_a_1 = cute.make_stride (%x1, %x4) : (i32, i32) -> !cute.stride<"(?,?)">
        %la_1 = cute.make_layout (%sh_a_1, %st_a_1)
              : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
             -> !cute.layout<"(?,?):(?,?)">
        %off_1 = cute.make_int_tuple (%x50) : (i32) -> !cute.int_tuple<"?">
        %sh_b_1 = cute.make_shape (%x2, %x3) : (i32, i32) -> !cute.shape<"(?,?)">
        %st_b_1 = cute.make_stride (%x1, %x2) : (i32, i32) -> !cute.stride<"(?,?)">
        %lb_1 = cute.make_layout (%sh_b_1, %st_b_1)
              : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
             -> !cute.layout<"(?,?):(?,?)">
        %cl_1 = cute.make_composed_layout (%la_1, %off_1, %lb_1)
              : (!cute.layout<"(?,?):(?,?)">, !cute.int_tuple<"?">,
                 !cute.layout<"(?,?):(?,?)">)
             -> !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">
        cute.print(%cl_1) : !cute.composed_layout<"(?,?):(?,?) o ? o (?,?):(?,?)">

        // Case 2: dyn A, dyn offset, static B.
        %sh_a_2 = cute.make_shape (%x4, %x5) : (i32, i32) -> !cute.shape<"(?,?)">
        %st_a_2 = cute.make_stride (%x1, %x4) : (i32, i32) -> !cute.stride<"(?,?)">
        %la_2 = cute.make_layout (%sh_a_2, %st_a_2)
              : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
             -> !cute.layout<"(?,?):(?,?)">
        %off_2 = cute.make_int_tuple (%x50) : (i32) -> !cute.int_tuple<"?">
        %lb_2 = cute.static : !cute.layout<"(2,3):(1,2)">
        %cl_2 = cute.make_composed_layout (%la_2, %off_2, %lb_2)
              : (!cute.layout<"(?,?):(?,?)">, !cute.int_tuple<"?">,
                 !cute.layout<"(2,3):(1,2)">)
             -> !cute.composed_layout<"(?,?):(?,?) o ? o (2,3):(1,2)">
        cute.print(%cl_2) : !cute.composed_layout<"(?,?):(?,?) o ? o (2,3):(1,2)">

        // Case 3: static A, dyn offset, dyn B.
        %la_3 = cute.static : !cute.layout<"(4,5):(1,4)">
        %off_3 = cute.make_int_tuple (%x50) : (i32) -> !cute.int_tuple<"?">
        %sh_b_3 = cute.make_shape (%x2, %x3) : (i32, i32) -> !cute.shape<"(?,?)">
        %st_b_3 = cute.make_stride (%x1, %x2) : (i32, i32) -> !cute.stride<"(?,?)">
        %lb_3 = cute.make_layout (%sh_b_3, %st_b_3)
              : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
             -> !cute.layout<"(?,?):(?,?)">
        %cl_3 = cute.make_composed_layout (%la_3, %off_3, %lb_3)
              : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"?">,
                 !cute.layout<"(?,?):(?,?)">)
             -> !cute.composed_layout<"(4,5):(1,4) o ? o (?,?):(?,?)">
        cute.print(%cl_3) : !cute.composed_layout<"(4,5):(1,4) o ? o (?,?):(?,?)">

        // Case 4: dyn A, static offset, dyn B.
        %sh_a_4 = cute.make_shape (%x4, %x5) : (i32, i32) -> !cute.shape<"(?,?)">
        %st_a_4 = cute.make_stride (%x1, %x4) : (i32, i32) -> !cute.stride<"(?,?)">
        %la_4 = cute.make_layout (%sh_a_4, %st_a_4)
              : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
             -> !cute.layout<"(?,?):(?,?)">
        %off_4 = cute.static : !cute.int_tuple<"50">
        %sh_b_4 = cute.make_shape (%x2, %x3) : (i32, i32) -> !cute.shape<"(?,?)">
        %st_b_4 = cute.make_stride (%x1, %x2) : (i32, i32) -> !cute.stride<"(?,?)">
        %lb_4 = cute.make_layout (%sh_b_4, %st_b_4)
              : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
             -> !cute.layout<"(?,?):(?,?)">
        %cl_4 = cute.make_composed_layout (%la_4, %off_4, %lb_4)
              : (!cute.layout<"(?,?):(?,?)">, !cute.int_tuple<"50">,
                 !cute.layout<"(?,?):(?,?)">)
             -> !cute.composed_layout<"(?,?):(?,?) o 50 o (?,?):(?,?)">
        cute.print(%cl_4) : !cute.composed_layout<"(?,?):(?,?) o 50 o (?,?):(?,?)">

        // Case 5: mixed within each component — one dyn + one static leaf
        // per shape/stride pair, dyn offset.
        %sh_a_5 = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,5)">
        %st_a_5 = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
        %la_5 = cute.make_layout (%sh_a_5, %st_a_5)
              : (!cute.shape<"(?,5)">, !cute.stride<"(1,?)">)
             -> !cute.layout<"(?,5):(1,?)">
        %off_5 = cute.make_int_tuple (%x50) : (i32) -> !cute.int_tuple<"?">
        %sh_b_5 = cute.make_shape (%x3) : (i32) -> !cute.shape<"(2,?)">
        %st_b_5 = cute.make_stride (%x2) : (i32) -> !cute.stride<"(1,?)">
        %lb_5 = cute.make_layout (%sh_b_5, %st_b_5)
              : (!cute.shape<"(2,?)">, !cute.stride<"(1,?)">)
             -> !cute.layout<"(2,?):(1,?)">
        %cl_5 = cute.make_composed_layout (%la_5, %off_5, %lb_5)
              : (!cute.layout<"(?,5):(1,?)">, !cute.int_tuple<"?">,
                 !cute.layout<"(2,?):(1,?)">)
             -> !cute.composed_layout<"(?,5):(1,?) o ? o (2,?):(1,?)">
        cute.print(%cl_5) : !cute.composed_layout<"(?,5):(1,?) o ? o (2,?):(1,?)">
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
