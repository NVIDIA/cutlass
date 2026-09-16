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
// Tests round-trip for cute.get_stride.

// -----

// Tests get_stride from a static layout.
// CHECK-LABEL: func.func @static_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
func.func @static_layout(%l: !cute.layout<"(4,8):(1,4)">) -> !cute.stride<"(1,4)"> {
  // CHECK: %[[R:.+]] = cute.get_stride(%[[L]]) : <"(4,8):(1,4)"> -> !cute.stride<"(1,4)">
  %r = cute.get_stride(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.stride<"(1,4)">
  // CHECK: return %[[R]]
  return %r : !cute.stride<"(1,4)">
}

// -----

// Tests get_stride from a rank-1 layout.
// CHECK-LABEL: func.func @rank1_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"4:1">)
func.func @rank1_layout(%l: !cute.layout<"4:1">) -> !cute.stride<"1"> {
  // CHECK: %[[R:.+]] = cute.get_stride(%[[L]]) : <"4:1"> -> !cute.stride<"1">
  %r = cute.get_stride(%l) : !cute.layout<"4:1"> -> !cute.stride<"1">
  // CHECK: return %[[R]]
  return %r : !cute.stride<"1">
}

// -----

// Tests get_stride from a dynamic layout.
// CHECK-LABEL: func.func @dynamic_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(?,8):(1,?)">)
func.func @dynamic_layout(%l: !cute.layout<"(?,8):(1,?)">) -> !cute.stride<"(1,?)"> {
  // CHECK: %[[R:.+]] = cute.get_stride(%[[L]]) : <"(?,8):(1,?)"> -> !cute.stride<"(1,?)">
  %r = cute.get_stride(%l) : !cute.layout<"(?,8):(1,?)"> -> !cute.stride<"(1,?)">
  // CHECK: return %[[R]]
  return %r : !cute.stride<"(1,?)">
}

// -----

// Scaled-basis strides.
// CHECK-LABEL: func.func @scaled_basis_strides
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(2,3):(1@0,1@1)">)
func.func @scaled_basis_strides(%l: !cute.layout<"(2,3):(1@0,1@1)">) -> !cute.stride<"(1@0,1@1)"> {
  // CHECK: cute.get_stride(%[[L]]) : <"(2,3):(1@0,1@1)"> -> !cute.stride<"(1@0,1@1)">
  %r = cute.get_stride(%l) : !cute.layout<"(2,3):(1@0,1@1)"> -> !cute.stride<"(1@0,1@1)">
  return %r : !cute.stride<"(1@0,1@1)">
}

// -----

// Dynamic-scale basis strides.
// CHECK-LABEL: func.func @dynamic_scaled_basis
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(?,3):(?@0,1@1)">)
func.func @dynamic_scaled_basis(%l: !cute.layout<"(?,3):(?@0,1@1)">) -> !cute.stride<"(?@0,1@1)"> {
  // CHECK: cute.get_stride(%[[L]]) : <"(?,3):(?@0,1@1)"> -> !cute.stride<"(?@0,1@1)">
  %r = cute.get_stride(%l) : !cute.layout<"(?,3):(?@0,1@1)"> -> !cute.stride<"(?@0,1@1)">
  return %r : !cute.stride<"(?@0,1@1)">
}

// -----

// Nested layout.
// CHECK-LABEL: func.func @nested_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"((2,3),(4,5)):((1,2),(6,24))">)
func.func @nested_layout(%l: !cute.layout<"((2,3),(4,5)):((1,2),(6,24))">) -> !cute.stride<"((1,2),(6,24))"> {
  // CHECK: cute.get_stride(%[[L]])
  // CHECK-SAME: -> !cute.stride<"((1,2),(6,24))">
  %r = cute.get_stride(%l) : !cute.layout<"((2,3),(4,5)):((1,2),(6,24))"> -> !cute.stride<"((1,2),(6,24))">
  return %r : !cute.stride<"((1,2),(6,24))">
}
