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

// CHECK: ((3,4),(2,5)):((4,1),(12,24))
// CHECK: ((3,4),(2,5)):((4,1),(12,24))
// CHECK: ((3,4),2,5):((4,1),12,24)
// CHECK: (3,4,2,5):(4,1,12,24)
// CHECK: ((3,2),(4,5)):((4,12),(1,24))
// CHECK: ((2,3),(5,4)):((12,4),(24,1))
// CHECK: ((3,2),(4,2)):((8,24),(1,4))
// CHECK: ((3,4),(2,2)):((8,1),(24,4))
// CHECK: ((3,4),2,2):((8,1),24,4)
// CHECK: (3,4,2,2):(8,1,24,4)
// CHECK: ((3,2),(2,4)):((1,6),(3,12))
// CHECK: ((3,2),(2,4)):((1,6),(3,12))
// CHECK: ((3,2),(2,4)):((1,24),(3,6))

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0 = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0 : index
      scf.if %is_zero {
        %a = cute.static : !cute.layout<"(3,4):(4,1)">
        %b = cute.static : !cute.layout<"(2,5):(1,2)">

        // logical_product.
        %r1 = cute.logical_product(%a, %b)
            : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
           -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
        cute.print(%r1) : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">

        // zipped_product.
        %r2 = cute.zipped_product(%a, %b)
            : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
           -> !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">
        cute.print(%r2) : !cute.layout<"((3,4),(2,5)):((4,1),(12,24))">

        // tiled_product.
        %r3 = cute.tiled_product(%a, %b)
            : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
           -> !cute.layout<"((3,4),2,5):((4,1),12,24)">
        cute.print(%r3) : !cute.layout<"((3,4),2,5):((4,1),12,24)">

        // flat_product.
        %r4 = cute.flat_product(%a, %b)
            : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
           -> !cute.layout<"(3,4,2,5):(4,1,12,24)">
        cute.print(%r4) : !cute.layout<"(3,4,2,5):(4,1,12,24)">

        // blocked_product.
        %r5 = cute.blocked_product(%a, %b)
            : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
           -> !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">
        cute.print(%r5) : !cute.layout<"((3,2),(4,5)):((4,12),(1,24))">

        // raked_product.
        %r6 = cute.raked_product(%a, %b)
            : (!cute.layout<"(3,4):(4,1)">, !cute.layout<"(2,5):(1,2)">)
           -> !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">
        cute.print(%r6) : !cute.layout<"((2,3),(5,4)):((12,4),(24,1))">

        // Divides — fresh inputs.
        %da = cute.static : !cute.layout<"(6,8):(8,1)">
        %db = cute.static : !cute.shape<"(3,4)">

        // logical_divide.
        %r7 = cute.logical_divide(%da, %db)
            : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
           -> !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">
        cute.print(%r7) : !cute.layout<"((3,2),(4,2)):((8,24),(1,4))">

        // zipped_divide.
        %r8 = cute.zipped_divide(%da, %db)
            : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
           -> !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">
        cute.print(%r8) : !cute.layout<"((3,4),(2,2)):((8,1),(24,4))">

        // tiled_divide.
        %r9 = cute.tiled_divide(%da, %db)
            : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
           -> !cute.layout<"((3,4),2,2):((8,1),24,4)">
        cute.print(%r9) : !cute.layout<"((3,4),2,2):((8,1),24,4)">

        // flat_divide.
        %r10 = cute.flat_divide(%da, %db)
            : (!cute.layout<"(6,8):(8,1)">, !cute.shape<"(3,4)">)
           -> !cute.layout<"(3,4,2,2):(8,1,24,4)">
        cute.print(%r10) : !cute.layout<"(3,4,2,2):(8,1,24,4)">

        // tile_to_shape.
        %tta = cute.static : !cute.layout<"(3,2):(1,3)">
        %ttb = cute.static : !cute.shape<"(6,8)">
        %r12 = cute.tile_to_shape(%tta, %ttb)
            : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">)
           -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
        cute.print(%r12) : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">

        // tile_to_shape with order = (0,1) — natural order; matches the
        // no-order case.
        %tto_n = cute.static : !cute.int_tuple<"(0,1)">
        %r13 = cute.tile_to_shape(%tta, %ttb, %tto_n)
            : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">,
               !cute.int_tuple<"(0,1)">)
           -> !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">
        cute.print(%r13) : !cute.layout<"((3,2),(2,4)):((1,6),(3,12))">

        // tile_to_shape with order = (1,0) — swap; same shape, different
        // replication strides.
        %tto_s = cute.static : !cute.int_tuple<"(1,0)">
        %r14 = cute.tile_to_shape(%tta, %ttb, %tto_s)
            : (!cute.layout<"(3,2):(1,3)">, !cute.shape<"(6,8)">,
               !cute.int_tuple<"(1,0)">)
           -> !cute.layout<"((3,2),(2,4)):((1,24),(3,6))">
        cute.print(%r14) : !cute.layout<"((3,2),(2,4)):((1,24),(3,6))">
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
