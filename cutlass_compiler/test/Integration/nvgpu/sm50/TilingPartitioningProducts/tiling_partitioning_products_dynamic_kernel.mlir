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
// Kernel-side dynamic TilingPartitioningProducts; dyn leaves are
// kernel-internal `arith.constant : i32`. Product ops require static
// input; dyn-tiler cases are exercised below.

// CHECK: ((3,2),(4,2)):((1,3),(6,24))
// CHECK: ((3,4),(2,2)):((1,6),(3,24))
// CHECK: ((3,4),2,2):((1,6),3,24)
// CHECK: (3,4,2,2):(1,6,3,24)
// CHECK: ((3,2),(2,4)):((1,6),(3,12))
// tile_to_shape with explicit order = (1,0) on the same dyn shape:
// same shape at runtime, but the per-axis replication strides shift.
// CHECK: ((3,2),(2,4)):((1,24),(3,6))
// logical_product with static input × dyn tiler.
// CHECK: ((3,4),(2,4)):((4,1),(12,24))
// logical_product with static input × fully-dyn tiler.
// CHECK: ((3,4),(2,4)):((4,1),(48,12))
// 5 sibling products with static input × dyn tiler.
// CHECK: ((3,4),(2,4)):((4,1),(12,24))
// CHECK: ((3,4),2,4):((4,1),12,24)
// CHECK: (3,4,2,4):(4,1,12,24)
// CHECK: ((2,3),(4,4)):((12,4),(24,1))
// CHECK: ((3,2),(4,4)):((4,12),(1,24))
// 5 sibling products with static input × **fully-dyn** tiler
// CHECK: ((3,4),(2,4)):((4,1),(48,12))
// CHECK: ((3,4),2,4):((4,1),48,12)
// CHECK: (3,4,2,4):(4,1,48,12)
// CHECK: ((2,3),(4,4)):((48,4),(12,1))
// CHECK: ((3,2),(4,4)):((4,48),(1,12))

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0 = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0 : index
      scf.if %is_zero {
        // 2D dyn layout (?,8):(1,?) with x=6.
        %x6 = arith.constant 6 : i32
        %sh = cute.make_shape (%x6) : (i32) -> !cute.shape<"(?,8)">
        %l_stride = cute.make_stride (%x6) : (i32) -> !cute.stride<"(1,?)">
        %l = cute.make_layout (%sh, %l_stride) : (!cute.shape<"(?,8)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,8):(1,?)">
        %b = cute.static : !cute.shape<"(3,4)">

        // logical_divide.
        %r1 = cute.logical_divide(%l, %b)
            : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
           -> !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">
        cute.print(%r1) : !cute.layout<"((3,?),(4,2)):((1,3),(?,?))">

        // zipped_divide.
        %r2 = cute.zipped_divide(%l, %b)
            : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
           -> !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">
        cute.print(%r2) : !cute.layout<"((3,4),(?,2)):((1,?),(3,?))">

        // tiled_divide.
        %r3 = cute.tiled_divide(%l, %b)
            : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
           -> !cute.layout<"((3,4),?,2):((1,?),3,?)">
        cute.print(%r3) : !cute.layout<"((3,4),?,2):((1,?),3,?)">

        // flat_divide.
        %r4 = cute.flat_divide(%l, %b)
            : (!cute.layout<"(?,8):(1,?)">, !cute.shape<"(3,4)">)
           -> !cute.layout<"(3,4,?,2):(1,?,3,?)">
        cute.print(%r4) : !cute.layout<"(3,4,?,2):(1,?,3,?)">

        // tile_to_shape with dyn target shape (?,8) x=6.
        %a5 = cute.static : !cute.layout<"(3,2):(1,3)">
        %sh_b5 = cute.make_shape (%x6) : (i32) -> !cute.shape<"(?,8)">
        %r5 = cute.tile_to_shape(%a5, %sh_b5)
            : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,8)">)
           -> !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">
        cute.print(%r5) : !cute.layout<"((3,?),(2,4)):((1,6),(3,?))">

        // Explicit order = (1,0) on the same dyn shape; strides shift.
        %o5 = cute.static : !cute.int_tuple<"(1,0)">
        %r6 = cute.tile_to_shape(%a5, %sh_b5, %o5)
            : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(?,8)">,
               !cute.int_tuple<"(1,0)">)
           -> !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">
        cute.print(%r6) : !cute.layout<"((3,?),(2,4)):((1,24),(3,6))">

        // logical_product with static input × dyn tiler (x=2, y=4).
        %x2 = arith.constant 2 : i32
        %x4 = arith.constant 4 : i32
        %sh_t = cute.make_shape (%x2, %x4)
              : (i32, i32) -> !cute.shape<"(?,?)">
        %st_t = cute.static : !cute.stride<"(1,2)">
        %t7 = cute.make_layout (%sh_t, %st_t)
             : (!cute.shape<"(?,?)">, !cute.stride<"(1,2)">)
            -> !cute.layout<"(?,?):(1,2)">
        %a7 = cute.static : !cute.layout<"(3,4):(4,1)">
        %r7 = cute.logical_product(%a7, %t7)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
            -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
        cute.print(%r7) : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">

        // logical_product with static input × **fully-dyn** tiler
        // (dyn shape AND dyn stride). Tiler stride (4,1) at runtime
        // — non-canonical, distinct from the case above.
        %ts0 = arith.constant 4 : i32
        %ts1 = arith.constant 1 : i32
        %dsh = cute.make_shape (%x2, %x4)
              : (i32, i32) -> !cute.shape<"(?,?)">
        %dst = cute.make_stride (%ts0, %ts1)
              : (i32, i32) -> !cute.stride<"(?,?)">
        %t8 = cute.make_layout (%dsh, %dst)
             : (!cute.shape<"(?,?)">, !cute.stride<"(?,?)">)
            -> !cute.layout<"(?,?):(?,?)">
        %r8 = cute.logical_product(%a7, %t8)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
            -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
        cute.print(%r8) : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">

        // 5 sibling products with static input × dyn tiler — reuses
        // `%a7` (static `(3,4):(4,1)`) and `%t7` (dyn `(?,?):(1,2)`).
        %r_zp = cute.zipped_product(%a7, %t7)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
            -> !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">
        cute.print(%r_zp) : !cute.layout<"((3,4),(?,?)):((4,1),(12,24))">

        %r_tp = cute.tiled_product(%a7, %t7)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
            -> !cute.layout<"((3,4),?,?):((4,1),12,24)">
        cute.print(%r_tp) : !cute.layout<"((3,4),?,?):((4,1),12,24)">

        %r_fp = cute.flat_product(%a7, %t7)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
            -> !cute.layout<"(3,4,?,?):(4,1,12,24)">
        cute.print(%r_fp) : !cute.layout<"(3,4,?,?):(4,1,12,24)">

        %r_rp = cute.raked_product(%a7, %t7)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
            -> !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">
        cute.print(%r_rp) : !cute.layout<"((?,3),(?,4)):((12,4),(24,1))">

        %r_bp = cute.blocked_product(%a7, %t7)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(1,2)">)
            -> !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">
        cute.print(%r_bp) : !cute.layout<"((3,?),(4,?)):((4,12),(1,24))">

        // 5 sibling products with static input × fully-dyn tiler.
        // Reuses `%a7` × `%t8`.
        %r_zp2 = cute.zipped_product(%a7, %t8)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
            -> !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">
        cute.print(%r_zp2) : !cute.layout<"((3,4),(?,?)):((4,1),(?,?))">

        %r_tp2 = cute.tiled_product(%a7, %t8)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
            -> !cute.layout<"((3,4),?,?):((4,1),?,?)">
        cute.print(%r_tp2) : !cute.layout<"((3,4),?,?):((4,1),?,?)">

        %r_fp2 = cute.flat_product(%a7, %t8)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
            -> !cute.layout<"(3,4,?,?):(4,1,?,?)">
        cute.print(%r_fp2) : !cute.layout<"(3,4,?,?):(4,1,?,?)">

        %r_rp2 = cute.raked_product(%a7, %t8)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
            -> !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">
        cute.print(%r_rp2) : !cute.layout<"((?,3),(?,4)):((?,4),(?,1))">

        %r_bp2 = cute.blocked_product(%a7, %t8)
             : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(?,?):(?,?)">)
            -> !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">
        cute.print(%r_bp2) : !cute.layout<"((3,?),(4,?)):((4,?),(1,?))">
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
