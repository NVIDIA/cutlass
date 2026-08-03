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
// Runtime-dynamic SizeIndex kernel; dyn leaves cross host→device via gpu.launch_func args.

// CHECK: 77
// CHECK: 12
// CHECK: 7
// CHECK: 208
// crd2idx (2,3) on (?,8) x=4 → 14.
// CHECK: 14
// CHECK: (3,2)
// CHECK: (2,2)
// increment_coord wrap (runtime dyn): (3,2) on (4,8) → (0,3).
// CHECK: (0,3)
// increment_coord hierarchical (runtime dyn): (1,(2,0)) on (4,(3,8)) → (2,(2,0)).
// CHECK: (2,(2,0))
// CHECK: (5,8,1,1)
// CHECK: (1,1,6,8)
// CHECK: 15
// CHECK: (3,10)

module attributes {gpu.container_module} {
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

  gpu.module @kernel {
    gpu.func @print_all(%base: i32) kernel {
      %tx = gpu.thread_id x
      %c0_idx = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0_idx : index
      scf.if %is_zero {
        // size: (?,7) → 77 with x=11.
        %o11 = arith.constant 11 : i32
        %x11 = arith.addi %base, %o11 : i32
        %sh1 = cute.make_shape (%x11) : (i32) -> !cute.shape<"(?,7)">
        %r1 = cute.size(%sh1)
            : (!cute.shape<"(?,7)">) -> !cute.int_tuple<"?">
        cute.print(%r1) : !cute.int_tuple<"?">

        // cosize: (?,3):(1,?) with x=4 → 12.
        %o4 = arith.constant 4 : i32
        %x4 = arith.addi %base, %o4 : i32
        %sh2 = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,3)">
        %l2_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
        %l2 = cute.make_layout (%sh2, %l2_stride) : (!cute.shape<"(?,3)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,3):(1,?)">
        %r2 = cute.cosize(%l2)
            : (!cute.layout<"(?,3):(1,?)">) -> !cute.int_tuple<"?">
        cute.print(%r2) : !cute.int_tuple<"?">

        // layout_eval: (3,1) on (?,8):(1,?) x=4 → 7.
        %o3 = arith.constant 3 : i32
        %o1 = arith.constant 1 : i32
        %x3 = arith.addi %base, %o3 : i32
        %x1 = arith.addi %base, %o1 : i32
        %crd3 = cute.make_coord (%x3, %x1) : (i32, i32) -> !cute.coord<"(?,?)">
        %sh3 = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,8)">
        %ll3_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
        %ll3 = cute.make_layout (%sh3, %ll3_stride) : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
        %r3 = cute.layout_eval(%crd3, %ll3)
            : (!cute.coord<"(?,?)">, !cute.layout<"(?,8):(1,?)">)
           -> !cute.int_tuple<"?">
        cute.print(%r3) : !cute.int_tuple<"?">

        // layout_eval on composed_layout: coord=6 (runtime-dynamic via
        // host->device launch arg) on `S<1,4,3> o 0 o (32):(32)` → 208.
        %o6c = arith.constant 6 : i32
        %x6c = arith.addi %base, %o6c : i32
        %crd3c = cute.make_coord (%x6c) : (i32) -> !cute.coord<"?">
        %cl3 = cute.static : !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">
        %r3c = cute.layout_eval(%crd3c, %cl3)
            : (!cute.coord<"?">,
               !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
           -> !cute.int_tuple<"?">
        cute.print(%r3c) : !cute.int_tuple<"?">

        // crd2idx: (2,3) on (?,8) with x=4 → 2 + 3*4 = 14.
        %o2p = arith.constant 2 : i32
        %o3p = arith.constant 3 : i32
        %x2p = arith.addi %base, %o2p : i32
        %x3p = arith.addi %base, %o3p : i32
        %crd3p = cute.make_coord (%x2p, %x3p)
            : (i32, i32) -> !cute.coord<"(?,?)">
        %sh3p = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,8)">
        %r3p = cute.crd2idx(%crd3p, %sh3p)
            : (!cute.coord<"(?,?)">, !cute.shape<"(?,8)">)
           -> !cute.int_tuple<"?">
        cute.print(%r3p) : !cute.int_tuple<"?">

        // idx2crd: idx=11 on (4,8) → (3,2).
        %x_idx = arith.addi %base, %o11 : i32
        %idx4 = cute.make_int_tuple (%x_idx) : (i32) -> !cute.int_tuple<"?">
        %s4 = cute.static : !cute.shape<"(4,8)">
        %r4 = cute.idx2crd(%idx4, %s4)
            : (!cute.int_tuple<"?">, !cute.shape<"(4,8)">)
           -> !cute.coord<"(?,?)">
        cute.print(%r4) : !cute.coord<"(?,?)">

        // increment_coord: (1,2) on (4,8) → (2,2).
        %o2 = arith.constant 2 : i32
        %x2 = arith.addi %base, %o2 : i32
        %crd5 = cute.make_coord (%x1, %x2) : (i32, i32) -> !cute.coord<"(?,?)">
        %s5 = cute.static : !cute.shape<"(4,8)">
        %r5 = cute.increment_coord(%crd5, %s5)
            : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">)
           -> !cute.coord<"(?,?)">
        cute.print(%r5) : !cute.coord<"(?,?)">

        // Wrap (runtime dyn): (3,2) on (4,8) → (0,3). Reuses %x3 above.
        %crd5w = cute.make_coord (%x3, %x2) : (i32, i32) -> !cute.coord<"(?,?)">
        %r5w = cute.increment_coord(%crd5w, %s5)
            : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">)
           -> !cute.coord<"(?,?)">
        cute.print(%r5w) : !cute.coord<"(?,?)">

        // Hierarchical (runtime dyn): (1,(2,0)) on (4,(3,8)) → (2,(2,0)).
        %o0c = arith.constant 0 : i32
        %x0c = arith.addi %base, %o0c : i32
        %crd5h = cute.make_coord (%x1, %x2, %x0c)
            : (i32, i32, i32) -> !cute.coord<"(?,(?,?))">
        %s5h = cute.static : !cute.shape<"(4,(3,8))">
        %r5h = cute.increment_coord(%crd5h, %s5h)
            : (!cute.coord<"(?,(?,?))">, !cute.shape<"(4,(3,8))">)
           -> !cute.coord<"(?,(?,?))">
        cute.print(%r5h) : !cute.coord<"(?,(?,?))">

        // append_to_rank<4>: (?,8) x=5 → (5,8,1,1).
        %o5 = arith.constant 5 : i32
        %x5 = arith.addi %base, %o5 : i32
        %sh6 = cute.make_shape (%x5) : (i32) -> !cute.shape<"(?,8)">
        %e6 = cute.static : !cute.shape<"1">
        %r6 = cute.append_to_rank<4>(%sh6, %e6)
            : !cute.shape<"(?,8)">, !cute.shape<"1">
        cute.print(%r6) : !cute.shape<"(?,8,1,1)">

        // prepend_to_rank<4>: (?,8) x=6 → (1,1,6,8).
        %o6 = arith.constant 6 : i32
        %x6 = arith.addi %base, %o6 : i32
        %sh7 = cute.make_shape (%x6) : (i32) -> !cute.shape<"(?,8)">
        %r7 = cute.prepend_to_rank<4>(%sh7, %e6)
            : !cute.shape<"(?,8)">, !cute.shape<"1">
        cute.print(%r7) : !cute.shape<"(1,1,?,8)">

        // tuple_product: (3,5) → 15.
        %t8 = cute.make_int_tuple (%x3, %x5) : (i32, i32) -> !cute.int_tuple<"(?,?)">
        %r8 = cute.tuple_product(%t8)
            : (!cute.int_tuple<"(?,?)">) -> !cute.int_tuple<"?">
        cute.print(%r8) : !cute.int_tuple<"?">

        // tuple_product_each: (3,(2,5)) → (3,10).
        %t9 = cute.make_int_tuple (%x3, %x2, %x5)
            : (i32, i32, i32) -> !cute.int_tuple<"(?,(?,?))">
        %r9 = cute.tuple_product_each(%t9)
            : (!cute.int_tuple<"(?,(?,?))">) -> !cute.int_tuple<"(?,?)">
        cute.print(%r9) : !cute.int_tuple<"(?,?)">

      }
      gpu.return
    }
  }

  func.func @main() {
    %base = func.call @read_base() : () -> i32
    %c1 = arith.constant 1 : index
    %c4 = arith.constant 4 : index
    gpu.launch_func @kernel::@print_all blocks in (%c1, %c1, %c1) threads in (%c4, %c1, %c1) args(%base : i32)
    return
  }
}
