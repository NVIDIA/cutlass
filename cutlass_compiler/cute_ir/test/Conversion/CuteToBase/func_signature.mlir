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

// After this pass the IR is fully cute-free in both ops and types.

// -----

// Cute-typed function arg + return get rewritten to LLVM struct types.
// CHECK-LABEL: func.func @cute_arg_and_return
// CHECK-SAME:    (%[[A:.+]]: !llvm.struct<(i32, i32)>) -> !llvm.struct<(i32, i32)>
// CHECK-NOT:     !cute.
// CHECK:         return
func.func @cute_arg_and_return(%a: !cute.layout<"(?,4):(?,1)">)
    -> !cute.layout<"(?,4):(?,1)"> {
  return %a : !cute.layout<"(?,4):(?,1)">
}

// -----

// Multiple cute-typed args mixed with primitives.
// CHECK-LABEL: func.func @mixed_signature
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: !llvm.struct<(i32, i32)>, %[[C:.+]]: i64) -> i32
// CHECK-NOT:     !cute.
// CHECK:         return
func.func @mixed_signature(%a: i32, %b: !cute.layout<"(?,4):(?,1)">, %c: i64)
    -> i32 {
  return %a : i32
}

// -----

// `func.call` operand types are rewritten to the converted callee signature.
// CHECK-LABEL: func.func private @callee
// CHECK-SAME:    (!llvm.struct<(i32, i32)>) -> i32
// CHECK-LABEL: func.func @caller
// CHECK-SAME:    (%[[A:.+]]: !llvm.struct<(i32, i32)>) -> i32
// CHECK-NOT:     !cute.
// CHECK:         %[[R:.+]] = call @callee(%[[A]]) : (!llvm.struct<(i32, i32)>) -> i32
// CHECK:         return %[[R]]
func.func private @callee(!cute.layout<"(?,4):(?,1)">) -> i32

func.func @caller(%a: !cute.layout<"(?,4):(?,1)">) -> i32 {
  %r = func.call @callee(%a) : (!cute.layout<"(?,4):(?,1)">) -> i32
  return %r : i32
}

// -----

// Fully static cute type converts to a canonical empty/nested struct.
// CHECK-LABEL: func.func @static_layout_arg
// CHECK-SAME:    (%[[A:.+]]: !llvm.struct<(struct<()>, struct<()>)>)
// CHECK-NOT:     !cute.
// CHECK:         return
func.func @static_layout_arg(%a: !cute.layout<"(2,3):(1,2)">) {
  return
}

// -----

// Signature conversion composes with body conversion via `cute.get_scalars`.
// CHECK-LABEL: func.func @arg_then_get_scalars
// CHECK-SAME:    (%[[A:.+]]: !llvm.struct<(i32, i32)>)
// CHECK-NOT:     !cute.
// CHECK:         %[[E0:.+]] = llvm.extractvalue %[[A]][0]
// CHECK:         %[[E1:.+]] = llvm.extractvalue %[[A]][1]
// CHECK:         return %[[E0]], %[[E1]]
func.func @arg_then_get_scalars(%l: !cute.layout<"(?,4):(1,?)">)
    -> (i32, i32) {
  %a, %b = cute.get_scalars<{only_dynamic}> (%l) : !cute.layout<"(?,4):(1,?)">
  return %a, %b : i32, i32
}
