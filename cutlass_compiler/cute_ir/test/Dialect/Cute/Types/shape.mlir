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

// Tests parse/print round-trip for !cute.shape types.

// -----

// Depth-0 scalar static integer.
// CHECK-LABEL: func.func @scalar_static
func.func @scalar_static(
    // CHECK-SAME: %[[A:.+]]: !cute.shape<"1">
    %a: !cute.shape<"1">,
    // CHECK-SAME: %[[B:.+]]: !cute.shape<"128">
    %b: !cute.shape<"128">) {
  return
}

// -----

// Depth-0 scalar dynamic.
// CHECK-LABEL: func.func @scalar_dynamic
func.func @scalar_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.shape<"?">
    %a: !cute.shape<"?">) {
  return
}

// -----

// Depth-1 static tuples.
// CHECK-LABEL: func.func @depth1_static
func.func @depth1_static(
    // CHECK-SAME: %[[A:.+]]: !cute.shape<"(1,2)">
    %a: !cute.shape<"(1,2)">,
    // CHECK-SAME: %[[B:.+]]: !cute.shape<"(32,64,128)">
    %b: !cute.shape<"(32,64,128)">) {
  return
}

// -----

// Depth-1 dynamic tuples.
// CHECK-LABEL: func.func @depth1_dynamic
func.func @depth1_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.shape<"(?,?)">
    %a: !cute.shape<"(?,?)">,
    // CHECK-SAME: %[[B:.+]]: !cute.shape<"(?,32)">
    %b: !cute.shape<"(?,32)">) {
  return
}

// -----

// Depth-1 tuples with constrained dynamics.
// CHECK-LABEL: func.func @depth1_constrained
func.func @depth1_constrained(
    // CHECK-SAME: %[[A:.+]]: !cute.shape<"(?,32)">
    %a: !cute.shape<"(?,32)">,
    // CHECK-SAME: %[[B:.+]]: !cute.shape<"(?,?)">
    %b: !cute.shape<"(?,?)">) {
  return
}

// -----

// Depth-2 nested static shape.
// CHECK-LABEL: func.func @depth2_static
func.func @depth2_static(
    // CHECK-SAME: %[[A:.+]]: !cute.shape<"(1,(2,3))">
    %a: !cute.shape<"(1,(2,3))">) {
  return
}

// -----

// Depth-2 nested dynamic shape.
// CHECK-LABEL: func.func @depth2_dynamic
func.func @depth2_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.shape<"(?,(?,64))">
    %a: !cute.shape<"(?,(?,64))">) {
  return
}

// -----

// Singleton shapes.
// CHECK-LABEL: func.func @singleton
func.func @singleton(
    // CHECK-SAME: %[[A:.+]]: !cute.shape<"(1)">
    %a: !cute.shape<"(1)">,
    // CHECK-SAME: %[[B:.+]]: !cute.shape<"((1,1),1)">
    %b: !cute.shape<"((1,1),1)">) {
  return
}

// -----

// Depth-3 nesting.
// CHECK-LABEL: func.func @depth3_static
func.func @depth3_static(
    // CHECK-SAME: %[[A:.+]]: !cute.shape<"(1,((2,3),(4,5)))">
    %a: !cute.shape<"(1,((2,3),(4,5)))">) {
  return
}

// -----

// Zero and negative shape leaves. Standalone shape literals can
// legitimately carry `0` (no-op padding) and negative values
// (cropping / negative padding); positivity is only required when
// a shape is wrapped into a layout.
// CHECK-LABEL: func.func @zero_and_negative_leaves
func.func @zero_and_negative_leaves(
    // CHECK-SAME: %[[A:.+]]: !cute.shape<"0">
    %a: !cute.shape<"0">,
    // CHECK-SAME: %[[B:.+]]: !cute.shape<"(0,2,3,4,0)">
    %b: !cute.shape<"(0,2,3,4,0)">,
    // CHECK-SAME: %[[C:.+]]: !cute.shape<"-1">
    %c: !cute.shape<"-1">,
    // CHECK-SAME: %[[D:.+]]: !cute.shape<"(0,-1,0,0,0)">
    %d: !cute.shape<"(0,-1,0,0,0)">) {
  return
}
