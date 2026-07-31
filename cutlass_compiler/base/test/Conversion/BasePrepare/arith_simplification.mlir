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

// base-prepare canonicalize: arith identity and constant-fold simplifications.

// -----

// CHECK-LABEL: func.func @addi_zero_identity
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK-NOT:     arith.constant 0
// CHECK-NOT:     arith.addi
// CHECK:         return %[[A]]
func.func @addi_zero_identity(%a: i32) -> i32 {
  %c0 = arith.constant 0 : i32
  %r = arith.addi %a, %c0 : i32
  return %r : i32
}

// -----

// CHECK-LABEL: func.func @muli_one_identity
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK-NOT:     arith.constant 1
// CHECK-NOT:     arith.muli
// CHECK:         return %[[A]]
func.func @muli_one_identity(%a: i32) -> i32 {
  %c1 = arith.constant 1 : i32
  %r = arith.muli %a, %c1 : i32
  return %r : i32
}

// -----

// CHECK-LABEL: func.func @constant_fold_addi
// CHECK-NOT:     arith.constant 3
// CHECK-NOT:     arith.constant 5
// CHECK-NOT:     arith.addi
// CHECK:         %[[R:.+]] = arith.constant 8 : i32
// CHECK:         return %[[R]]
func.func @constant_fold_addi() -> i32 {
  %c3 = arith.constant 3 : i32
  %c5 = arith.constant 5 : i32
  %r = arith.addi %c3, %c5 : i32
  return %r : i32
}

// -----

// CHECK-LABEL: func.func @subi_self_zero
// CHECK-NOT:     arith.subi
// CHECK:         %[[R:.+]] = arith.constant 0 : i32
// CHECK:         return %[[R]]
func.func @subi_self_zero(%a: i32) -> i32 {
  %r = arith.subi %a, %a : i32
  return %r : i32
}
