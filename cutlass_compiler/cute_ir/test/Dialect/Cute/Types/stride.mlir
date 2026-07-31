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

// Tests parse/print round-trip for !cute.stride types.

// -----

// Depth-0 scalar static stride.
// CHECK-LABEL: func.func @scalar_static
func.func @scalar_static(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"1">
    %a: !cute.stride<"1">,
    // CHECK-SAME: %[[B:.+]]: !cute.stride<"16">
    %b: !cute.stride<"16">) {
  return
}

// -----

// Depth-0 scalar dynamic stride.
// CHECK-LABEL: func.func @scalar_dynamic
func.func @scalar_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"?">
    %a: !cute.stride<"?">) {
  return
}

// -----

// Depth-0 static scaled basis.
// CHECK-LABEL: func.func @scalar_scaled_basis_static
func.func @scalar_scaled_basis_static(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"4@0">
    %a: !cute.stride<"4@0">,
    // CHECK-SAME: %[[B:.+]]: !cute.stride<"1@1">
    %b: !cute.stride<"1@1">) {
  return
}

// -----

// Depth-0 dynamic scaled basis.
// CHECK-LABEL: func.func @scalar_scaled_basis_dynamic
func.func @scalar_scaled_basis_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"?@0">
    %a: !cute.stride<"?@0">,
    // CHECK-SAME: %[[B:.+]]: !cute.stride<"?@1">
    %b: !cute.stride<"?@1">) {
  return
}

// -----

// Depth-1 static stride tuple.
// CHECK-LABEL: func.func @depth1_static
func.func @depth1_static(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"(16,32)">
    %a: !cute.stride<"(16,32)">,
    // CHECK-SAME: %[[B:.+]]: !cute.stride<"(1,16,256)">
    %b: !cute.stride<"(1,16,256)">) {
  return
}

// -----

// Depth-1 mixed static and dynamic stride.
// CHECK-LABEL: func.func @depth1_dynamic
func.func @depth1_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"(16,?)">
    %a: !cute.stride<"(16,?)">,
    // CHECK-SAME: %[[B:.+]]: !cute.stride<"(?,?)">
    %b: !cute.stride<"(?,?)">) {
  return
}

// -----

// Depth-1 with dynamic scaled basis elements. Zero-int leaves are
// allowed alongside scaled-basis leaves.
// CHECK-LABEL: func.func @depth1_scaled_basis
func.func @depth1_scaled_basis(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"(0,?@0)">
    %a: !cute.stride<"(0,?@0)">,
    // CHECK-SAME: %[[B:.+]]: !cute.stride<"(?@0,?@1)">
    %b: !cute.stride<"(?@0,?@1)">) {
  return
}

// -----

// Depth-2 nested static stride.
// CHECK-LABEL: func.func @depth2_static
func.func @depth2_static(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"(16,(32,4))">
    %a: !cute.stride<"(16,(32,4))">) {
  return
}

// -----

// Depth-2 nested with dynamic elements.
// CHECK-LABEL: func.func @depth2_dynamic
func.func @depth2_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"(16,(?,4))">
    %a: !cute.stride<"(16,(?,4))">) {
  return
}

// -----

// Hierarchical (multi-index) scaled basis.
// CHECK-LABEL: func.func @hierarchical_basis_static
func.func @hierarchical_basis_static(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"1@1@0">
    %a: !cute.stride<"1@1@0">,
    // CHECK-SAME: %[[B:.+]]: !cute.stride<"2@1@0">
    %b: !cute.stride<"2@1@0">) {
  return
}

// -----

// Dynamic hierarchical scaled basis.
// CHECK-LABEL: func.func @hierarchical_basis_dynamic
func.func @hierarchical_basis_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"?@1@0">
    %a: !cute.stride<"?@1@0">) {
  return
}

// -----

// Tuple of hierarchical basis elements sharing a common outer prefix.
// CHECK-LABEL: func.func @depth1_hierarchical_basis
func.func @depth1_hierarchical_basis(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"(1@0@0,2@1@0)">
    %a: !cute.stride<"(1@0@0,2@1@0)">) {
  return
}

// -----

// Stride 0 — scalar leaf and embedded in a tuple.
// CHECK-LABEL: func.func @zero_stride
func.func @zero_stride(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"0">
    %a: !cute.stride<"0">,
    // CHECK-SAME: %[[B:.+]]: !cute.stride<"(?,0)">
    %b: !cute.stride<"(?,0)">) {
  return
}

// -----

// Standalone dynamic stride.
// CHECK-LABEL: func.func @scalar_dynamic
func.func @scalar_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"?">
    %a: !cute.stride<"?">) {
  return
}

// -----

// Rank-4 flat stride and a rank-2 nested stride with a rank-4 inner mode.
// CHECK-LABEL: func.func @rank4_flat_and_nested
func.func @rank4_flat_and_nested(
    // CHECK-SAME: %[[A:.+]]: !cute.stride<"(1,2,4,8)">
    %a: !cute.stride<"(1,2,4,8)">,
    // CHECK-SAME: %[[B:.+]]: !cute.stride<"(1@0,(1@0@1,1@1@1,1@2@1,1@3@1))">
    %b: !cute.stride<"(1@0,(1@0@1,1@1@1,1@2@1,1@3@1))">) {
  return
}
