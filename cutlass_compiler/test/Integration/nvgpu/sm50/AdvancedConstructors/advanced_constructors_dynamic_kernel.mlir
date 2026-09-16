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
// Dynamic AdvancedConstructors kernel; dyn leaves are kernel-internal arith.constant.

// CHECK: (4,3):(1,4)
// CHECK: (5,2):(1@0,1@1)
// CHECK: (6,2):(1,6)
// CHECK: (8,2):(1,8)
// CHECK: (2,(3,4)):(1@0,(1@0@1,1@1@1))

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0 = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0 : index
      scf.if %is_zero {
        // make_layout_like — input is a dyn layout built from a dyn shape.
        %x4 = arith.constant 4 : i32
        %sh1 = cute.make_shape (%x4) : (i32) -> !cute.shape<"(?,3)">
        %src1_stride = cute.make_stride (%x4) : (i32) -> !cute.stride<"(1,?)">
        %src1 = cute.make_layout (%sh1, %src1_stride) : (!cute.shape<"(?,3)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,3):(1,?)">
        %r1 = cute.make_layout_like(%src1)
            : !cute.layout<"(?,3):(1,?)"> -> !cute.layout<"(?,3):(1,?)">
        cute.print(%r1) : !cute.layout<"(?,3):(1,?)">

        // make_identity_layout — input is a dyn shape.
        %x5 = arith.constant 5 : i32
        %sh2 = cute.make_shape (%x5) : (i32) -> !cute.shape<"(?,2)">
        %r2 = cute.make_identity_layout(%sh2)
            : !cute.shape<"(?,2)"> -> !cute.layout<"(?,2):(1@0,1@1)">
        cute.print(%r2) : !cute.layout<"(?,2):(1@0,1@1)">

        // make_ordered_layout — dyn shape + static order tuple.
        %x6 = arith.constant 6 : i32
        %sh3 = cute.make_shape (%x6) : (i32) -> !cute.shape<"(?,2)">
        %ord = cute.static : !cute.int_tuple<"(0,1)">
        %r3 = cute.make_ordered_layout(%sh3, %ord)
            : (!cute.shape<"(?,2)">, !cute.int_tuple<"(0,1)">)
           -> !cute.layout<"(?,2):(1,?)">
        cute.print(%r3) : !cute.layout<"(?,2):(1,?)">

        // make_layout_like composed — shape_leaf=8, stride_leaf=16.
        %x8 = arith.constant 8 : i32
        %x16 = arith.constant 16 : i32
        %sh5 = cute.make_shape (%x8) : (i32) -> !cute.shape<"(?,2)">
        %st5 = cute.make_stride (%x16) : (i32) -> !cute.stride<"(2,?)">
        %outer5 = cute.make_layout (%sh5, %st5)
            : (!cute.shape<"(?,2)">, !cute.stride<"(2,?)">) -> !cute.layout<"(?,2):(2,?)">
        %sw = cute.static : !cute.swizzle<"S<3,4,3>">
        %off = cute.static : !cute.int_tuple<"6">
        %src5 = cute.make_composed_layout (%sw, %off, %outer5)
            : (!cute.swizzle<"S<3,4,3>">, !cute.int_tuple<"6">, !cute.layout<"(?,2):(2,?)">)
           -> !cute.composed_layout<"S<3,4,3> o 6 o (?,2):(2,?)">
        %r5 = cute.make_layout_like(%src5)
            : !cute.composed_layout<"S<3,4,3> o 6 o (?,2):(2,?)"> -> !cute.layout<"(?,2):(1,?)">
        cute.print(%r5) : !cute.layout<"(?,2):(1,?)">

        // make_identity_layout nested — inner_leaf=3.
        %x3 = arith.constant 3 : i32
        %sh7 = cute.make_shape (%x3) : (i32) -> !cute.shape<"(2,(?,4))">
        %r7 = cute.make_identity_layout(%sh7)
            : !cute.shape<"(2,(?,4))"> -> !cute.layout<"(2,(?,4)):(1@0,(1@0@1,1@1@1))">
        cute.print(%r7) : !cute.layout<"(2,(?,4)):(1@0,(1@0@1,1@1@1))">
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
