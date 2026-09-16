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
// All-static AdvancedConstructors kernel; ops inline in gpu.func.

// CHECK: (4,2):(2,1)
// CHECK: (4,2):(1@0,1@1)
// CHECK: (4,2):(1,4)
// CHECK: (8,2):(1,8)
// CHECK: (2,(3,4)):(1@0,(1@0@1,1@1@1))

module attributes {gpu.container_module} {
  gpu.module @kernel {
    gpu.func @print_all() kernel {
      %tx = gpu.thread_id x
      %c0 = arith.constant 0 : index
      %is_zero = arith.cmpi eq, %tx, %c0 : index
      scf.if %is_zero {
        // make_layout_like — canonicalize stride to packed col-major.
        %src1 = cute.static : !cute.layout<"(4,2):(4,1)">
        %r1 = cute.make_layout_like(%src1)
            : !cute.layout<"(4,2):(4,1)"> -> !cute.layout<"(4,2):(2,1)">
        cute.print(%r1) : !cute.layout<"(4,2):(2,1)">

        // make_identity_layout — identity layout for a shape.
        %s2 = cute.static : !cute.shape<"(4,2)">
        %r2 = cute.make_identity_layout(%s2)
            : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1@0,1@1)">
        cute.print(%r2) : !cute.layout<"(4,2):(1@0,1@1)">

        // make_ordered_layout — strides ordered by an int_tuple.
        %s3 = cute.static : !cute.shape<"(4,2)">
        %ord = cute.static : !cute.int_tuple<"(0,1)">
        %r3 = cute.make_ordered_layout(%s3, %ord)
            : (!cute.shape<"(4,2)">, !cute.int_tuple<"(0,1)">)
           -> !cute.layout<"(4,2):(1,4)">
        cute.print(%r3) : !cute.layout<"(4,2):(1,4)">

        // Composed-source make_layout_like — exercises the
        // ComposedLayoutType branch on B = (8,2):(2,16).
        %src5 = cute.static : !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)">
        %r5 = cute.make_layout_like(%src5)
            : !cute.composed_layout<"S<3,4,3> o 6 o (8,2):(2,16)"> -> !cute.layout<"(8,2):(1,8)">
        cute.print(%r5) : !cute.layout<"(8,2):(1,8)">

        // Nested-shape make_identity_layout — depth-2 basis chains.
        %s7 = cute.static : !cute.shape<"(2,(3,4))">
        %r7 = cute.make_identity_layout(%s7)
            : !cute.shape<"(2,(3,4))"> -> !cute.layout<"(2,(3,4)):(1@0,(1@0@1,1@1@1))">
        cute.print(%r7) : !cute.layout<"(2,(3,4)):(1@0,(1@0@1,1@1@1))">
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
