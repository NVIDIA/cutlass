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

// Tests `cute-to-base` lowering for `cute.make_stride`.

// -----

// Fully static stride — empty struct.
// CHECK-LABEL: func.func @stride_static
// CHECK-NOT:     cute.make_stride
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return
func.func @stride_static() -> !cute.stride<"(1,4)"> {
  %r = cute.make_stride () : () -> !cute.stride<"(1,4)">
  return %r : !cute.stride<"(1,4)">
}

// -----

// One dynamic stride leaf — bare i32.
// CHECK-LABEL: func.func @stride_one_dyn
// CHECK-NOT:     cute.make_stride
// CHECK-NOT:     llvm.insertvalue
// CHECK:         return
func.func @stride_one_dyn(%a: i32) -> !cute.stride<"(?,4)"> {
  %r = cute.make_stride (%a) : (i32) -> !cute.stride<"(?,4)">
  return %r : !cute.stride<"(?,4)">
}

// -----

// Two dynamic stride leaves — `struct<(i32, i32)>`.
// CHECK-LABEL: func.func @stride_two_dyn
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cute.make_stride
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[A]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[B]], %[[V0]][1]
// CHECK:         return
func.func @stride_two_dyn(%a: i32, %b: i32) -> !cute.stride<"(?,?)"> {
  %r = cute.make_stride (%a, %b) : (i32, i32) -> !cute.stride<"(?,?)">
  return %r : !cute.stride<"(?,?)">
}

// -----

// Dynamic scaled-basis stride `?@0` — single-leaf, bare i32.
// CHECK-LABEL: func.func @stride_scaled_basis_dyn
// CHECK-NOT:     cute.make_stride
// CHECK-NOT:     llvm.insertvalue
// CHECK:         return
func.func @stride_scaled_basis_dyn(%a: i32) -> !cute.stride<"?@0"> {
  %r = cute.make_stride (%a) : (i32) -> !cute.stride<"?@0">
  return %r : !cute.stride<"?@0">
}

// -----

// Hierarchical scaled-basis stride `?@1@0` — depth-2 chain, dyn scale is
// the only leaf, basis indices are compile-time.
// CHECK-LABEL: func.func @stride_hierarchical_basis_dyn
// CHECK-NOT:     cute.make_stride
// CHECK-NOT:     llvm.insertvalue
// CHECK:         return
func.func @stride_hierarchical_basis_dyn(%a: i32) -> !cute.stride<"?@1@0"> {
  %r = cute.make_stride (%a) : (i32) -> !cute.stride<"?@1@0">
  return %r : !cute.stride<"?@1@0">
}
