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

// base-prepare LICM: pure arith hoisted out of scf.for.

// CHECK-LABEL: func.func @licm_invariant_arith
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32, %[[INIT:.+]]: i32,
// CHECK:       %[[INV:.+]] = arith.muli %[[A]], %[[B]]
// CHECK:       %{{.+}} = scf.for
// CHECK-SAME:    iter_args
// CHECK-NOT:     arith.muli
// CHECK:         arith.addi %{{.+}}, %[[INV]]
// CHECK:         scf.yield
// CHECK:       return
func.func @licm_invariant_arith(%a: i32, %b: i32, %init: i32,
                                  %lo: index, %hi: index, %st: index) -> i32 {
  %final = scf.for %i = %lo to %hi step %st iter_args(%acc = %init) -> (i32) {
    %inv = arith.muli %a, %b : i32
    %next = arith.addi %acc, %inv : i32
    scf.yield %next : i32
  }
  return %final : i32
}
