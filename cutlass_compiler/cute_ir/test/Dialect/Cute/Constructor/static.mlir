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

// Tests parse/print round-trip for cute.static on every CuteIR type.

// -----

// CHECK-LABEL: func.func @layout
func.func @layout() -> !cute.layout<"(2,3):(1,2)"> {
  // CHECK: %[[V:.+]] = cute.static : !cute.layout<"(2,3):(1,2)">
  %0 = cute.static : !cute.layout<"(2,3):(1,2)">
  return %0 : !cute.layout<"(2,3):(1,2)">
}

// -----

// CHECK-LABEL: func.func @stride
func.func @stride() -> !cute.stride<"(1,4)"> {
  // CHECK: %[[V:.+]] = cute.static : !cute.stride<"(1,4)">
  %0 = cute.static : !cute.stride<"(1,4)">
  return %0 : !cute.stride<"(1,4)">
}

// -----

// CHECK-LABEL: func.func @shape
func.func @shape() -> !cute.shape<"5"> {
  // CHECK: %[[V:.+]] = cute.static : !cute.shape<"5">
  %0 = cute.static : !cute.shape<"5">
  return %0 : !cute.shape<"5">
}

// -----

// CHECK-LABEL: func.func @coord
func.func @coord() -> !cute.coord<"(1,2)"> {
  // CHECK: %[[V:.+]] = cute.static : !cute.coord<"(1,2)">
  %0 = cute.static : !cute.coord<"(1,2)">
  return %0 : !cute.coord<"(1,2)">
}

// -----

// CHECK-LABEL: func.func @int_tuple
func.func @int_tuple() -> !cute.int_tuple<"(1,2,3)"> {
  // CHECK: %[[V:.+]] = cute.static : !cute.int_tuple<"(1,2,3)">
  %0 = cute.static : !cute.int_tuple<"(1,2,3)">
  return %0 : !cute.int_tuple<"(1,2,3)">
}

// -----

// CHECK-LABEL: func.func @tile
func.func @tile() -> !cute.tile<"[(2,3):(1,2)]"> {
  // CHECK: %[[V:.+]] = cute.static : !cute.tile<"[(2,3):(1,2)]">
  %0 = cute.static : !cute.tile<"[(2,3):(1,2)]">
  return %0 : !cute.tile<"[(2,3):(1,2)]">
}

// -----

// CHECK-LABEL: func.func @composed_layout
func.func @composed_layout() -> !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)"> {
  // CHECK: %[[V:.+]] = cute.static : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  %0 = cute.static : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  return %0 : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
}

// -----

// CHECK-LABEL: func.func @swizzle
func.func @swizzle() -> !cute.swizzle<"S<3,5,4>"> {
  // CHECK: %[[V:.+]] = cute.static : !cute.swizzle<"S<3,5,4>">
  %0 = cute.static : !cute.swizzle<"S<3,5,4>">
  return %0 : !cute.swizzle<"S<3,5,4>">
}

// -----

// Underscore wildcard slots in `coord` and `tile` are compile-time
// markers and count as static — `cute.static` must accept them.

// CHECK-LABEL: func.func @coord_underscore
func.func @coord_underscore() -> !cute.coord<"(_,2)"> {
  // CHECK: %[[V:.+]] = cute.static : !cute.coord<"(_,2)">
  %0 = cute.static : !cute.coord<"(_,2)">
  return %0 : !cute.coord<"(_,2)">
}

// -----

// CHECK-LABEL: func.func @tile_underscore
func.func @tile_underscore() -> !cute.tile<"[(2,3):(1,2);_]"> {
  // CHECK: %[[V:.+]] = cute.static : !cute.tile<"[(2,3):(1,2);_]">
  %0 = cute.static : !cute.tile<"[(2,3):(1,2);_]">
  return %0 : !cute.tile<"[(2,3):(1,2);_]">
}
