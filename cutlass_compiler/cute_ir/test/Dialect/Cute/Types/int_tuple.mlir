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

// Tests parse/print round-trip for !cute.int_tuple types.

// -----

// Depth-0 scalar static integer.
// CHECK-LABEL: func.func @scalar_static
func.func @scalar_static(
    // CHECK-SAME: %[[A:.+]]: !cute.int_tuple<"1">
    %a: !cute.int_tuple<"1">,
    // CHECK-SAME: %[[B:.+]]: !cute.int_tuple<"128">
    %b: !cute.int_tuple<"128">) {
  return
}

// -----

// Depth-0 scalar dynamic.
// CHECK-LABEL: func.func @scalar_dynamic
func.func @scalar_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.int_tuple<"?">
    %a: !cute.int_tuple<"?">) {
  return
}

// -----

// Depth-1 static tuples.
// CHECK-LABEL: func.func @depth1_static
func.func @depth1_static(
    // CHECK-SAME: %[[A:.+]]: !cute.int_tuple<"(1,2)">
    %a: !cute.int_tuple<"(1,2)">,
    // CHECK-SAME: %[[B:.+]]: !cute.int_tuple<"(32,64,128)">
    %b: !cute.int_tuple<"(32,64,128)">) {
  return
}

// -----

// Depth-1 dynamic tuples.
// CHECK-LABEL: func.func @depth1_dynamic
func.func @depth1_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.int_tuple<"(?,?)">
    %a: !cute.int_tuple<"(?,?)">,
    // CHECK-SAME: %[[B:.+]]: !cute.int_tuple<"(?,32)">
    %b: !cute.int_tuple<"(?,32)">) {
  return
}

// -----

// Depth-1 tuples with constrained dynamics.
// CHECK-LABEL: func.func @depth1_constrained
func.func @depth1_constrained(
    // CHECK-SAME: %[[A:.+]]: !cute.int_tuple<"(?,32)">
    %a: !cute.int_tuple<"(?,32)">,
    // CHECK-SAME: %[[B:.+]]: !cute.int_tuple<"(?,?)">
    %b: !cute.int_tuple<"(?,?)">) {
  return
}

// -----

// Depth-2 nested static tuple.
// CHECK-LABEL: func.func @depth2_static
func.func @depth2_static(
    // CHECK-SAME: %[[A:.+]]: !cute.int_tuple<"(1,(2,3))">
    %a: !cute.int_tuple<"(1,(2,3))">) {
  return
}

// -----

// Depth-2 nested dynamic tuple.
// CHECK-LABEL: func.func @depth2_dynamic
func.func @depth2_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.int_tuple<"(?,(?,64))">
    %a: !cute.int_tuple<"(?,(?,64))">) {
  return
}

// -----

// Depth-3+ nesting.
// CHECK-LABEL: func.func @depth3_static
func.func @depth3_static(
    // CHECK-SAME: %[[A:.+]]: !cute.int_tuple<"(1,((2,3),(4,5)))">
    %a: !cute.int_tuple<"(1,((2,3),(4,5)))">,
    // CHECK-SAME: %[[B:.+]]: !cute.int_tuple<"(((2,2),(2,3)))">
    %b: !cute.int_tuple<"(((2,2),(2,3)))">) {
  return
}
