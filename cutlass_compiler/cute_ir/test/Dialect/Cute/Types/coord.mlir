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

// Tests parse/print round-trip for !cute.coord types.

// -----

// Depth-0 scalar static integer.
// CHECK-LABEL: func.func @scalar_static
func.func @scalar_static(
    // CHECK-SAME: %[[A:.+]]: !cute.coord<"1">
    %a: !cute.coord<"1">,
    // CHECK-SAME: %[[B:.+]]: !cute.coord<"42">
    %b: !cute.coord<"42">) {
  return
}

// -----

// Depth-0 scalar dynamic.
// CHECK-LABEL: func.func @scalar_dynamic
func.func @scalar_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.coord<"?">
    %a: !cute.coord<"?">) {
  return
}

// -----

// Depth-0 underscore wildcard.
// CHECK-LABEL: func.func @scalar_underscore
func.func @scalar_underscore(
    // CHECK-SAME: %[[A:.+]]: !cute.coord<"_">
    %a: !cute.coord<"_">) {
  return
}

// -----

// Depth-1 static tuple.
// CHECK-LABEL: func.func @depth1_static
func.func @depth1_static(
    // CHECK-SAME: %[[A:.+]]: !cute.coord<"(1,2)">
    %a: !cute.coord<"(1,2)">,
    // CHECK-SAME: %[[B:.+]]: !cute.coord<"(32,64,128)">
    %b: !cute.coord<"(32,64,128)">) {
  return
}

// -----

// Depth-1 with underscore leaves.
// CHECK-LABEL: func.func @depth1_underscore
func.func @depth1_underscore(
    // CHECK-SAME: %[[A:.+]]: !cute.coord<"(_,?)">
    %a: !cute.coord<"(_,?)">,
    // CHECK-SAME: %[[B:.+]]: !cute.coord<"(_,_,?)">
    %b: !cute.coord<"(_,_,?)">) {
  return
}

// -----

// Depth-1 mixed: static, underscore, dynamic.
// CHECK-LABEL: func.func @depth1_mixed
func.func @depth1_mixed(
    // CHECK-SAME: %[[A:.+]]: !cute.coord<"(1,_,?)">
    %a: !cute.coord<"(1,_,?)">) {
  return
}

// -----

// Depth-2 nested static.
// CHECK-LABEL: func.func @depth2_static
func.func @depth2_static(
    // CHECK-SAME: %[[A:.+]]: !cute.coord<"(1,(2,3))">
    %a: !cute.coord<"(1,(2,3))">) {
  return
}

// -----

// Depth-2 nested with underscores and dynamics.
// CHECK-LABEL: func.func @depth2_mixed
func.func @depth2_mixed(
    // CHECK-SAME: %[[A:.+]]: !cute.coord<"(_,(?,1))">
    %a: !cute.coord<"(_,(?,1))">) {
  return
}

// -----

// Underscore inside a depth-2 nested mode plus a top-level static.
// CHECK-LABEL: func.func @depth2_underscore_nested
func.func @depth2_underscore_nested(
    // CHECK-SAME: %[[A:.+]]: !cute.coord<"((_,?),3)">
    %a: !cute.coord<"((_,?),3)">) {
  return
}

// -----

// Multiple underscores + dynamic at the same depth.
// CHECK-LABEL: func.func @depth1_multi_underscore
func.func @depth1_multi_underscore(
    // CHECK-SAME: %[[A:.+]]: !cute.coord<"(_,?,1)">
    %a: !cute.coord<"(_,?,1)">,
    // CHECK-SAME: %[[B:.+]]: !cute.coord<"(_,_,?)">
    %b: !cute.coord<"(_,_,?)">) {
  return
}
