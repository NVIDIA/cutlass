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

// RUN: cute-opt -cute-to-base --split-input-file %s | FileCheck %s

// Tests GPU-side `cute.print` lowering — inside a `gpu.module` or
// `gpu.launch`, the op lowers to `gpu.printf` (no `@printf` global).

// -----

// Inside `gpu.func` — GPU path selected.
// CHECK-LABEL: gpu.module @gpu_kernels
// CHECK-LABEL: gpu.func @print_in_gpu
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK:       gpu.printf "%d\0A", %[[A]] : i32
// CHECK-NOT:   cute.print
// CHECK-NOT:   llvm.call @printf
// CHECK:       gpu.return
gpu.module @gpu_kernels {
  gpu.func @print_in_gpu(%a: i32) kernel {
    %s = cute.make_shape (%a) : (i32) -> !cute.shape<"?">
    cute.print(%s) : !cute.shape<"?">
    gpu.return
  }
}

// -----

// Static layout inside a GPU kernel — no scalars, format string only.
// CHECK-LABEL: gpu.module @gpu_kernels_static
// CHECK-LABEL: gpu.func @print_static_in_gpu
// CHECK:       gpu.printf "(2,3):(1,2)\0A"
// CHECK-NOT:   cute.print
// CHECK-NOT:   llvm.call @printf
// CHECK:       gpu.return
gpu.module @gpu_kernels_static {
  gpu.func @print_static_in_gpu() kernel {
    %l = cute.static : !cute.layout<"(2,3):(1,2)">
    cute.print(%l) : !cute.layout<"(2,3):(1,2)">
    gpu.return
  }
}

// -----

// Inside `gpu.launch` (nested in a host func) — GPU path selected; no
// `@printf` global appears in the host module.
// CHECK-LABEL: func.func @print_in_launch
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK:       gpu.launch
// CHECK:         gpu.printf "%d\0A", %[[A]] : i32
// CHECK-NOT:     cute.print
// CHECK-NOT:     llvm.call @printf
// CHECK:         gpu.terminator
// CHECK:       return
func.func @print_in_launch(%a: i32) {
  %c1 = arith.constant 1 : index
  gpu.launch blocks(%bx, %by, %bz) in (%gx = %c1, %gy = %c1, %gz = %c1)
             threads(%tx, %ty, %tz) in (%bxs = %c1, %bys = %c1, %bzs = %c1) {
    %s = cute.make_shape (%a) : (i32) -> !cute.shape<"?">
    cute.print(%s) : !cute.shape<"?">
    gpu.terminator
  }
  return
}
