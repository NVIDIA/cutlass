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

// RUN: cute-opt %s -split-input-file | FileCheck %s
// Verify the printed output can be parsed.
// RUN: cute-opt %s -split-input-file | cute-opt | FileCheck %s
// Verify the generic form can be parsed.
// RUN: cute-opt -mlir-print-op-generic %s -split-input-file | cute-opt | FileCheck %s

// Tests parse/print round-trip for !cute.swizzle types.

// -----

// Canonical identity swizzle S<0,4,3>.
// CHECK-LABEL: func.func @identity
func.func @identity(
    // CHECK-SAME: %[[A:.+]]: !cute.swizzle<"S<0,4,3>">
    %a: !cute.swizzle<"S<0,4,3>">) {
  return
}

// -----

// Non-identity swizzles.
// CHECK-LABEL: func.func @non_identity
func.func @non_identity(
    // CHECK-SAME: %[[A:.+]]: !cute.swizzle<"S<3,5,4>">
    %a: !cute.swizzle<"S<3,5,4>">,
    // CHECK-SAME: %[[B:.+]]: !cute.swizzle<"S<1,0,2>">
    %b: !cute.swizzle<"S<1,0,2>">) {
  return
}

// -----

// Negative shift.
// CHECK-LABEL: func.func @negative_shift
func.func @negative_shift(
    // CHECK-SAME: %[[A:.+]]: !cute.swizzle<"S<2,0,-3>">
    %a: !cute.swizzle<"S<2,0,-3>">) {
  return
}
