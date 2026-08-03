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

// RUN: base-opt -one-shot-convert-to-llvm --split-input-file %s | FileCheck %s

// Tests `one-shot-convert-to-llvm` lowering of `func.func` /
// `func.return` / `func.call`.
// -----

// Plain func definition + return.
// CHECK-LABEL: llvm.func @plain_def
// CHECK-SAME:    (%[[A:.+]]: i32) -> i32
// CHECK-NOT:     func.
// CHECK:         llvm.return %[[A]]
func.func @plain_def(%a: i32) -> i32 {
  return %a : i32
}

// -----

// Forward declaration + call.
// CHECK-LABEL: llvm.func @callee
// CHECK-SAME:    (i32) -> i32 attributes {sym_visibility = "private"}
// CHECK-LABEL: llvm.func @caller
// CHECK-SAME:    (%[[A:.+]]: i32) -> i32
// CHECK-NOT:     func.call
// CHECK:         %[[R:.+]] = llvm.call @callee(%[[A]])
// CHECK:         llvm.return %[[R]]
func.func private @callee(i32) -> i32

func.func @caller(%a: i32) -> i32 {
  %r = func.call @callee(%a) : (i32) -> i32
  return %r : i32
}

// -----

// Multiple return values.
// CHECK-LABEL: llvm.func @two_returns
// CHECK:       llvm.return %{{.+}} : !llvm.struct<(i32, i32)>
func.func @two_returns(%a: i32, %b: i32) -> (i32, i32) {
  return %a, %b : i32, i32
}
