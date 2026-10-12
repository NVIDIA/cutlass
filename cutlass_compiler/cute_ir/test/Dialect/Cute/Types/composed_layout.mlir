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

// Tests parse/print round-trip for !cute.composed_layout types.

// -----

// Layout A composition (affine).
// CHECK-LABEL: func.func @layout_a
func.func @layout_a(
    // CHECK-SAME: %[[A:.+]]: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">
    %a: !cute.composed_layout<"(4,5):(1,4) o 2 o (2,3):(1,2)">) {
  return
}

// -----

// Swizzle A composition.
// CHECK-LABEL: func.func @swizzle_a
func.func @swizzle_a(
    // CHECK-SAME: %[[A:.+]]: !cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">
    %a: !cute.composed_layout<"S<3,5,4> o 2 o (2,3):(1,2)">) {
  return
}

// -----

// Non-identity swizzle with zero offset.
// CHECK-LABEL: func.func @zero_offset
func.func @zero_offset(
    // CHECK-SAME: %[[A:.+]]: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
    %a: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">) {
  return
}

// -----

// Tuple offset.
// CHECK-LABEL: func.func @tuple_offset
func.func @tuple_offset(
    // CHECK-SAME: %[[A:.+]]: !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)">
    %a: !cute.composed_layout<"(4,5):(1,4) o (0,0) o (2,3):(1@0,1@1)">) {
  return
}

// -----

// Dynamic B layout.
// CHECK-LABEL: func.func @dynamic_b
func.func @dynamic_b(
    // CHECK-SAME: %[[A:.+]]: !cute.composed_layout<"S<3,5,4> o 0 o (?,3):(1,2)">
    %a: !cute.composed_layout<"S<3,5,4> o 0 o (?,3):(1,2)">) {
  return
}

// -----

// Hierarchical basis fixture with uniform-depth basis chains inside
// every tuple.
// CHECK-LABEL: func.func @hierarchical_basis_uniform
func.func @hierarchical_basis_uniform(
    // CHECK-SAME: %[[A:.+]]: !cute.composed_layout<"((2,3),4):((1@0@0,1@1@0),1@1) o ((0,0),0) o ((2,3),4):((1@0@0,1@1@0),1@1)">
    %a: !cute.composed_layout<"((2,3),4):((1@0@0,1@1@0),1@1) o ((0,0),0) o ((2,3),4):((1@0@0,1@1@0),1@1)">) {
  return
}

// -----

// CHECK-LABEL: func.func @complex_fixture
func.func @complex_fixture(
    // CHECK-SAME: %[[A:.+]]: !cute.composed_layout<"((8,8,1,1),(64,3,3,3)):((1@0@1,1@1@1,1@2@1,1@2),(1@0,1@0@3,1@1@3,1@2@3)) o (0,(0,0,0,0)) o (64,(64,3,3,3)):(1@0,(1@0@1,1@1@1,1@2@1,1@3@1))">
    %a: !cute.composed_layout<"((8,8,1,1),(64,3,3,3)):((1@0@1,1@1@1,1@2@1,1@2),(1@0,1@0@3,1@1@3,1@2@3)) o (0,(0,0,0,0)) o (64,(64,3,3,3)):(1@0,(1@0@1,1@1@1,1@2@1,1@3@1))">) {
  return
}
