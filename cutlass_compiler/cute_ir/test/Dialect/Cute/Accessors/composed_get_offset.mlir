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
// Tests round-trip for cute.composed_get_offset.

// -----

// Tests extraction of a scalar (rank-1) offset.
// CHECK-LABEL: func.func @scalar_offset
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">)
func.func @scalar_offset(%cl: !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">) -> !cute.int_tuple<"0"> {
  // CHECK: %[[R:.+]] = cute.composed_get_offset(%[[CL]]) : <"(4,8):(1,4) o 0 o (2,4):(1,2)"> -> !cute.int_tuple<"0">
  %r = cute.composed_get_offset(%cl) : !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)"> -> !cute.int_tuple<"0">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"0">
}

// -----

// Tests extraction of a tuple offset.
// CHECK-LABEL: func.func @tuple_offset
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"(4,8):(1,4) o (0,0) o (2,4):(1,2)">)
func.func @tuple_offset(%cl: !cute.composed_layout<"(4,8):(1,4) o (0,0) o (2,4):(1,2)">) -> !cute.int_tuple<"(0,0)"> {
  // CHECK: %[[R:.+]] = cute.composed_get_offset(%[[CL]]) : <"(4,8):(1,4) o (0,0) o (2,4):(1,2)"> -> !cute.int_tuple<"(0,0)">
  %r = cute.composed_get_offset(%cl) : !cute.composed_layout<"(4,8):(1,4) o (0,0) o (2,4):(1,2)"> -> !cute.int_tuple<"(0,0)">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"(0,0)">
}

// -----

// Tests extraction of a swizzle-composed offset.
// CHECK-LABEL: func.func @swizzle_composed_offset
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">)
func.func @swizzle_composed_offset(%cl: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">) -> !cute.int_tuple<"0"> {
  // CHECK: %[[R:.+]] = cute.composed_get_offset(%[[CL]]) : <"S<3,5,4> o 0 o (8,4):(1,8)"> -> !cute.int_tuple<"0">
  %r = cute.composed_get_offset(%cl) : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)"> -> !cute.int_tuple<"0">
  // CHECK: return %[[R]]
  return %r : !cute.int_tuple<"0">
}
