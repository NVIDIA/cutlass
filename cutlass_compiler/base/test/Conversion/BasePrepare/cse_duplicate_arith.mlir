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

// RUN: base-opt -base-prepare --split-input-file %s | FileCheck %s

// base-prepare CSE: duplicate arith expressions and constants collapse to one.

// -----

// CHECK-LABEL: func.func @cse_duplicate_addi
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-COUNT-1: arith.addi %[[A]], %[[B]]
// CHECK-NOT:     arith.addi
// CHECK:         return
func.func @cse_duplicate_addi(%a: i32, %b: i32) -> (i32, i32) {
  %x = arith.addi %a, %b : i32
  %y = arith.addi %a, %b : i32
  return %x, %y : i32, i32
}

// -----

// CHECK-LABEL: func.func @cse_duplicate_constants
// CHECK-COUNT-1: arith.constant 0 : i64
// CHECK-NOT:     arith.constant 0 : i64
// CHECK:         return
func.func @cse_duplicate_constants() -> (i64, i64, i64) {
  %c0_a = arith.constant 0 : i64
  %c0_b = arith.constant 0 : i64
  %c0_c = arith.constant 0 : i64
  return %c0_a, %c0_b, %c0_c : i64, i64, i64
}
