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

// RUN: base-opt -base-prepare %s | FileCheck %s

// base-prepare canonicalize: extractvalue(insertvalue(...)) folds to the inserted operand.

// CHECK-LABEL: func.func @poison_insertvalue_fold
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     ub.poison
// CHECK-NOT:     llvm.insertvalue
// CHECK-NOT:     llvm.extractvalue
// CHECK:         %[[R:.+]] = arith.addi %[[A]], %[[B]]
// CHECK:         return %[[R]]
func.func @poison_insertvalue_fold(%a: i32, %b: i32) -> i32 {
  %p = ub.poison : !llvm.struct<(i32, i32)>
  %v0 = llvm.insertvalue %a, %p[0] : !llvm.struct<(i32, i32)>
  %v1 = llvm.insertvalue %b, %v0[1] : !llvm.struct<(i32, i32)>
  %e0 = llvm.extractvalue %v1[0] : !llvm.struct<(i32, i32)>
  %e1 = llvm.extractvalue %v1[1] : !llvm.struct<(i32, i32)>
  %r = arith.addi %e0, %e1 : i32
  return %r : i32
}
