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

// Tests host-side `cute.print` lowering — emits a format-string global,
// an `llvm.func @printf` decl, and an `llvm.call`. Dynamic leaves
// become `%d` (i32) or `%lld` (i64).

// -----

// Fully static layout — format string only, no scalars.
// CHECK-LABEL: llvm.func @printf(!llvm.ptr, ...) -> i32
// CHECK:       llvm.mlir.global internal constant @printfFormat_0("(2,3):(1,2)\0A\00")
// CHECK-LABEL: func.func @print_static_layout
// CHECK:       %[[ADDR:.+]] = llvm.mlir.addressof @printfFormat_0
// CHECK:       %[[GEP:.+]] = llvm.getelementptr %[[ADDR]]
// CHECK:       llvm.call @printf(%[[GEP]]) vararg
// CHECK-NOT:   cute.print
// CHECK:       return
func.func @print_static_layout() {
  %l = cute.static : !cute.layout<"(2,3):(1,2)">
  cute.print(%l) : !cute.layout<"(2,3):(1,2)">
  return
}

// -----

// Single dynamic shape leaf.
// CHECK:       llvm.mlir.global internal constant @printfFormat_0("(%d,4)\0A\00")
// CHECK-LABEL: func.func @print_dyn_shape
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK:       %[[GEP:.+]] = llvm.getelementptr
// CHECK:       llvm.call @printf(%[[GEP]], %[[A]]) vararg
// CHECK-NOT:   cute.print
// CHECK:       return
func.func @print_dyn_shape(%a: i32) {
  %s = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,4)">
  cute.print(%s) : !cute.shape<"(?,4)">
  return
}

// -----

// Layout with two dynamic leaves.
// CHECK:       llvm.mlir.global internal constant @printfFormat_0("(%d,4):(%d,1)\0A\00")
// CHECK-LABEL: func.func @print_dyn_layout
// CHECK:       %[[E0:.+]] = llvm.extractvalue %{{.+}}[0]
// CHECK:       %[[E1:.+]] = llvm.extractvalue %{{.+}}[1]
// CHECK:       llvm.call @printf(%{{.+}}, %[[E0]], %[[E1]]) vararg
// CHECK-NOT:   cute.print
// CHECK:       return
func.func @print_dyn_layout(%a: i32, %b: i32) {
  %s = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,4)">
  %st = cute.make_stride (%b) : (i32) -> !cute.stride<"(?,1)">
  %l = cute.make_layout (%s, %st)
       : (!cute.shape<"(?,4)">, !cute.stride<"(?,1)">) -> !cute.layout<"(?,4):(?,1)">
  cute.print(%l) : !cute.layout<"(?,4):(?,1)">
  return
}

// -----

// Static composed layout with swizzle inner.
// CHECK:       llvm.mlir.global internal constant @printfFormat_0("S<3,5,4> o 0 o (8,4):(1,8)\0A\00")
// CHECK-LABEL: func.func @print_swizzle_composed
// CHECK:       llvm.call @printf(%{{.+}}) vararg
// CHECK-NOT:   cute.print
// CHECK:       return
func.func @print_swizzle_composed() {
  %cl = cute.static : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  cute.print(%cl) : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  return
}

// -----

// Dynamic composed layout — pins print-order: `A o offset o B` even though
// the struct stores `(B, offset, A)`.
// CHECK:       llvm.mlir.global internal constant @printfFormat_{{.+}}("(%d):(%d) o %d o (6,8):(8,1)\0A\00")
// CHECK-LABEL: func.func @print_dyn_composed
// CHECK-SAME:    [[CL:%.+]]: !llvm.struct<(struct<(struct<()>, struct<()>)>, i32, struct<(i32, i32)>)>
// CHECK:         [[OFF:%.+]] = llvm.extractvalue [[CL]][1]
// CHECK:         [[A:%.+]] = llvm.extractvalue [[CL]][2]
// CHECK:         [[SH:%.+]] = llvm.extractvalue [[A]][0]
// CHECK:         [[STR:%.+]] = llvm.extractvalue [[A]][1]
// CHECK:         llvm.call @printf({{.+}}, [[SH]], [[STR]], [[OFF]]) vararg
// CHECK-NOT:   cute.print
// CHECK:       return
func.func @print_dyn_composed(%cl: !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">) {
  cute.print(%cl) : !cute.composed_layout<"(?):(?) o ? o (6,8):(8,1)">
  return
}

// -----

// `?` annotation — must be stripped from the format string.
// CHECK:       llvm.mlir.global internal constant @printfFormat_0("%d\0A\00")
// CHECK-LABEL: func.func @print_annotated_dyn
// CHECK:       llvm.call @printf
// CHECK-NOT:   cute.print
// CHECK:       return
func.func @print_annotated_dyn(%a: i32) {
  %t = cute.make_int_tuple (%a)
       : (i32) -> !cute.int_tuple<"?">
  cute.print(%t) : !cute.int_tuple<"?">
  return
}
