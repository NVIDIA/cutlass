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

// RUN: base-opt -one-shot-convert-to-llvm %s | FileCheck %s

// Tests `one-shot-convert-to-llvm` lowering of `cf` (control-flow)
// dialect ops.

// CHECK-LABEL: llvm.func @cf_ops
// CHECK-SAME:    (%[[COND:.+]]: i1, %[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cf.
// CHECK:         llvm.cond_br %[[COND]], ^[[BB1:.+]], ^[[BB2:.+]]
// CHECK:       ^[[BB1]]
// CHECK:         llvm.br ^[[JOIN:.+]](%[[A]] : i32)
// CHECK:       ^[[BB2]]
// CHECK:         llvm.br ^[[JOIN]](%[[B]] : i32)
// CHECK:       ^[[JOIN]](%[[ARG:.+]]: i32):
// CHECK:         llvm.return %[[ARG]]
func.func @cf_ops(%cond: i1, %a: i32, %b: i32) -> i32 {
  cf.cond_br %cond, ^bb1, ^bb2
^bb1:
  cf.br ^join(%a : i32)
^bb2:
  cf.br ^join(%b : i32)
^join(%arg: i32):
  return %arg : i32
}
