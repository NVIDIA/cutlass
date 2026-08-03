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
// RUN: env CUTLASS_COMPILER_TEST_BASE=0 %cutlass-compiler-run-device %s | FileCheck %s
//
// Runtime-dynamic Constructor kernel; dyn leaves cross host→device via gpu.launch_func args.
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

module attributes {gpu.container_module} {
  //===---------------------------------------------------------------===//
  // libc bridge: host-side getenv/atoi to produce a JIT-opaque i32.
  //===---------------------------------------------------------------===//

  llvm.func @getenv(!llvm.ptr) -> !llvm.ptr
  llvm.func @atoi(!llvm.ptr) -> i32

  llvm.mlir.global internal constant @cutlass_compiler_env_name("CUTLASS_COMPILER_TEST_BASE\00") {addr_space = 0 : i32}

  func.func private @read_base() -> i32 {
    %name_addr = llvm.mlir.addressof @cutlass_compiler_env_name : !llvm.ptr
    %name = llvm.getelementptr %name_addr[0, 0]
          : (!llvm.ptr) -> !llvm.ptr, !llvm.array<15 x i8>
    %env = llvm.call @getenv(%name) : (!llvm.ptr) -> !llvm.ptr
    %v = llvm.call @atoi(%env) : (!llvm.ptr) -> i32
    return %v : i32
  }

  //===---------------------------------------------------------------===//
  // Kernel: takes the host-side base, derives every dynamic leaf as
  // `base + offset`, builds cute values, prints from thread 0.
  //===---------------------------------------------------------------===//

  gpu.module @kernel {
    gpu.func @print_all(%base: i32) kernel {
      %tx = gpu.thread_id x
      %c0_idx = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0_idx : index
      scf.if %is_zero {
        // !cute.shape — both leaves dynamic.
        %o5 = arith.constant 5 : i32
        %o7 = arith.constant 7 : i32
        %x5 = arith.addi %base, %o5 : i32
        %x7 = arith.addi %base, %o7 : i32
        %s = cute.make_shape (%x5, %x7) : (i32, i32) -> !cute.shape<"(?,?)">
        cute.print(%s) : !cute.shape<"(?,?)">

        // !cute.stride — first leaf dynamic, second static.
        %o10 = arith.constant 10 : i32
        %x10 = arith.addi %base, %o10 : i32
        %st = cute.make_stride (%x10) : (i32) -> !cute.stride<"(?,1)">
        cute.print(%st) : !cute.stride<"(?,1)">

        // !cute.coord — dyn + underscore + dyn.
        %o12 = arith.constant 12 : i32
        %o15 = arith.constant 15 : i32
        %x12 = arith.addi %base, %o12 : i32
        %x15 = arith.addi %base, %o15 : i32
        %c = cute.make_coord (%x12, %x15) : (i32, i32) -> !cute.coord<"(?,_,?)">
        cute.print(%c) : !cute.coord<"(?,_,?)">

        // !cute.int_tuple — dyn + static + dyn.
        %o20 = arith.constant 20 : i32
        %o25 = arith.constant 25 : i32
        %x20 = arith.addi %base, %o20 : i32
        %x25 = arith.addi %base, %o25 : i32
        %it = cute.make_int_tuple (%x20, %x25)
              : (i32, i32) -> !cute.int_tuple<"(?,3,?)">
        cute.print(%it) : !cute.int_tuple<"(?,3,?)">

        // !cute.tile — single layout, two dyn leaves.
        %o30 = arith.constant 30 : i32
        %o35 = arith.constant 35 : i32
        %x30 = arith.addi %base, %o30 : i32
        %x35 = arith.addi %base, %o35 : i32
        %t = cute.make_tile (%x30, %x35) : (i32, i32)
             -> !cute.tile<"[(?,3):(1,?)]">
        cute.print(%t) : !cute.tile<"[(?,3):(1,?)]">

        // !cute.layout (1-operand form) — col-major stride synthesized.
        %o40 = arith.constant 40 : i32
        %x40 = arith.addi %base, %o40 : i32
        %sh1 = cute.make_shape (%x40) : (i32) -> !cute.shape<"(?,4)">
        %l1_stride = cute.make_stride (%x40) : (i32) -> !cute.stride<"(1,?)">
        %l1 = cute.make_layout (%sh1, %l1_stride) : (!cute.shape<"(?,4)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,4):(1,?)">
        cute.print(%l1) : !cute.layout<"(?,4):(1,?)">

        // !cute.layout (2-operand form) — explicit shape + stride.
        %o45 = arith.constant 45 : i32
        %x45 = arith.addi %base, %o45 : i32
        %sh2 = cute.make_shape (%x45) : (i32) -> !cute.shape<"(?,8)">
        %st2_l = cute.make_stride (%x45) : (i32) -> !cute.stride<"(1,?)">
        %l2 = cute.make_layout (%sh2, %st2_l)
             : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">)
            -> !cute.layout<"(?,8):(1,?)">
        cute.print(%l2) : !cute.layout<"(?,8):(1,?)">

        // !cute.composed_layout — static layout outer, dyn offset.
        %a_in = cute.static : !cute.layout<"(4,5):(1,4)">
        %o50 = arith.constant 50 : i32
        %x50 = arith.addi %base, %o50 : i32
        %off1 = cute.make_int_tuple (%x50) : (i32) -> !cute.int_tuple<"?">
        %b_in = cute.static : !cute.layout<"(2,3):(1,2)">
        %cl = cute.make_composed_layout (%a_in, %off1, %b_in)
              : (!cute.layout<"(4,5):(1,4)">, !cute.int_tuple<"?">,
                 !cute.layout<"(2,3):(1,2)">)
             -> !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">
        cute.print(%cl) : !cute.composed_layout<"(4,5):(1,4) o ? o (2,3):(1,2)">

        // !cute.composed_layout — static swizzle outer, dyn offset.
        %sw_in = cute.static : !cute.swizzle<"S<3,5,4>">
        %o60 = arith.constant 60 : i32
        %x60 = arith.addi %base, %o60 : i32
        %off2 = cute.make_int_tuple (%x60) : (i32) -> !cute.int_tuple<"?">
        %lin = cute.static : !cute.layout<"(8,4):(1,8)">
        %csw = cute.make_composed_layout (%sw_in, %off2, %lin)
              : (!cute.swizzle<"S<3,5,4>">, !cute.int_tuple<"?">,
                 !cute.layout<"(8,4):(1,8)">)
             -> !cute.composed_layout<"S<3,5,4> o ? o (8,4):(1,8)">
        cute.print(%csw) : !cute.composed_layout<"S<3,5,4> o ? o (8,4):(1,8)">

      }
      gpu.return
    }
  }

  //===---------------------------------------------------------------===//
  // Host entry: read base from env, launch kernel passing it as arg.
  //===---------------------------------------------------------------===//

  func.func @main() {
    %base = func.call @read_base() : () -> i32
    %c1 = arith.constant 1 : index
    %c4 = arith.constant 4 : index
    gpu.launch_func @kernel::@print_all blocks in (%c1, %c1, %c1) threads in (%c4, %c1, %c1) args(%base : i32)
    return
  }
}
