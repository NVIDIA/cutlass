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

// Tests parse/print round-trip for !cute.layout types.

// -----

// Static rank-2 layout (column-major and row-major).
// CHECK-LABEL: func.func @rank2_static
func.func @rank2_static(
    // CHECK-SAME: %[[A:.+]]: !cute.layout<"(2,3):(1,2)">
    %a: !cute.layout<"(2,3):(1,2)">,
    // CHECK-SAME: %[[B:.+]]: !cute.layout<"(2,3):(3,1)">
    %b: !cute.layout<"(2,3):(3,1)">) {
  return
}

// -----

// Dynamic shape or stride elements.
// CHECK-LABEL: func.func @rank2_dynamic
func.func @rank2_dynamic(
    // CHECK-SAME: %[[A:.+]]: !cute.layout<"(2,3):(?,2)">
    %a: !cute.layout<"(2,3):(?,2)">,
    // CHECK-SAME: %[[B:.+]]: !cute.layout<"(?,3):(1,2)">
    %b: !cute.layout<"(?,3):(1,2)">,
    // CHECK-SAME: %[[C:.+]]: !cute.layout<"(?,?):(?,?)">
    %c: !cute.layout<"(?,?):(?,?)">) {
  return
}

// -----

// Nested (depth-2) shape and stride.
// CHECK-LABEL: func.func @nested_static
func.func @nested_static(
    // CHECK-SAME: %[[A:.+]]: !cute.layout<"((2,3),(4,5)):((1,2),(3,4))">
    %a: !cute.layout<"((2,3),(4,5)):((1,2),(3,4))">) {
  return
}

// -----

// Scaled-basis stride elements.
// CHECK-LABEL: func.func @scaled_basis
func.func @scaled_basis(
    // CHECK-SAME: %[[A:.+]]: !cute.layout<"(2,3):(1@0,1@1)">
    %a: !cute.layout<"(2,3):(1@0,1@1)">,
    // CHECK-SAME: %[[B:.+]]: !cute.layout<"(2,3):(?@0,?@1)">
    %b: !cute.layout<"(2,3):(?@0,?@1)">) {
  return
}

// -----

// Rank-1 layout.
// CHECK-LABEL: func.func @rank1
func.func @rank1(
    // CHECK-SAME: %[[A:.+]]: !cute.layout<"8:1">
    %a: !cute.layout<"8:1">,
    // CHECK-SAME: %[[B:.+]]: !cute.layout<"?:?">
    %b: !cute.layout<"?:?">) {
  return
}

// -----

// Hierarchical (multi-index) scaled-basis strides. All chains in a
// single stride tuple share the same depth; each %arg below extends
// the previous (wider rank, nested shape, dynamic-shape variants)
// while keeping mode-0 hierarchical.
// CHECK-LABEL: func.func @hierarchical_basis_strides
func.func @hierarchical_basis_strides(
    // rank-2 flat baseline.
    // CHECK-SAME: %[[A:.+]]: !cute.layout<"(2,3):(1@0@0,1@1@0)">
    %a: !cute.layout<"(2,3):(1@0@0,1@1@0)">,
    // rank-3 flat.
    // CHECK-SAME: %[[B:.+]]: !cute.layout<"(2,3,5):(1@0@0,1@1@0,1@2@0)">
    %b: !cute.layout<"(2,3,5):(1@0@0,1@1@0,1@2@0)">,
    // rank-4 flat.
    // CHECK-SAME: %[[C:.+]]: !cute.layout<"(2,3,4,5):(1@0@0,1@1@0,1@2@0,1@3@0)">
    %c: !cute.layout<"(2,3,4,5):(1@0@0,1@1@0,1@2@0,1@3@0)">,
    // Nested shape — mode-0 is a rank-2 tuple.
    // CHECK-SAME: %[[D:.+]]: !cute.layout<"((2,3),4):((1@0@0,1@1@0),1@1)">
    %d: !cute.layout<"((2,3),4):((1@0@0,1@1@0),1@1)">,
    // Dynamic shape with hierarchical basis.
    // CHECK-SAME: %[[E:.+]]: !cute.layout<"(?,?):(1@0@0,1@1@0)">
    %e: !cute.layout<"(?,?):(1@0@0,1@1@0)">) {
  return
}

// -----

// Cosize-1 layout (single element, stride zero).
// CHECK-LABEL: func.func @cosize_one
func.func @cosize_one(
    // CHECK-SAME: %[[A:.+]]: !cute.layout<"1:0">
    %a: !cute.layout<"1:0">) {
  return
}

// -----

// Rank-3 flat layouts.
// CHECK-LABEL: func.func @rank3_flat
func.func @rank3_flat(
    // CHECK-SAME: %[[A:.+]]: !cute.layout<"(2,3,4):(1,2,6)">
    %a: !cute.layout<"(2,3,4):(1,2,6)">,
    // CHECK-SAME: %[[B:.+]]: !cute.layout<"(?,?,?):(?,?,?)">
    %b: !cute.layout<"(?,?,?):(?,?,?)">) {
  return
}

// -----

// Layouts with a zero-stride broadcast mode.
// CHECK-LABEL: func.func @zero_stride_broadcast
func.func @zero_stride_broadcast(
    // CHECK-SAME: %[[A:.+]]: !cute.layout<"(2,3):(0,1)">
    %a: !cute.layout<"(2,3):(0,1)">,
    // CHECK-SAME: %[[B:.+]]: !cute.layout<"(?,1,?):(?,0,?)">
    %b: !cute.layout<"(?,1,?):(?,0,?)">) {
  return
}

// -----

// Rank-4 flat layout.
// CHECK-LABEL: func.func @rank4_flat
func.func @rank4_flat(
    // CHECK-SAME: %[[A:.+]]: !cute.layout<"(?,?,?,?):(?,1,?,?)">
    %a: !cute.layout<"(?,?,?,?):(?,1,?,?)">) {
  return
}

// -----

// Mixed-rank shape: depth-2 nesting on the shape side with a flat
// stride structure that matches the nested mode's rank.
// CHECK-LABEL: func.func @mixed_rank_shape
func.func @mixed_rank_shape(
    // CHECK-SAME: %[[A:.+]]: !cute.layout<"(2,(3,4),5):(12,(4,1),60)">
    %a: !cute.layout<"(2,(3,4),5):(12,(4,1),60)">) {
  return
}
