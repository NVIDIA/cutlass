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
// Tests round-trip for cute.get_shape.

// -----

// Tests get_shape from a static layout.
// CHECK-LABEL: func.func @static_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
func.func @static_layout(%l: !cute.layout<"(4,8):(1,4)">) -> !cute.shape<"(4,8)"> {
  // CHECK: %[[R:.+]] = cute.get_shape(%[[L]]) : !cute.layout<"(4,8):(1,4)"> -> !cute.shape<"(4,8)">
  %r = cute.get_shape(%l) : !cute.layout<"(4,8):(1,4)"> -> !cute.shape<"(4,8)">
  // CHECK: return %[[R]]
  return %r : !cute.shape<"(4,8)">
}

// -----

// Tests get_shape from a rank-1 layout.
// CHECK-LABEL: func.func @rank1_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"4:1">)
func.func @rank1_layout(%l: !cute.layout<"4:1">) -> !cute.shape<"4"> {
  // CHECK: %[[R:.+]] = cute.get_shape(%[[L]]) : !cute.layout<"4:1"> -> !cute.shape<"4">
  %r = cute.get_shape(%l) : !cute.layout<"4:1"> -> !cute.shape<"4">
  // CHECK: return %[[R]]
  return %r : !cute.shape<"4">
}

// -----

// Tests get_shape from a dynamic layout.
// CHECK-LABEL: func.func @dynamic_layout
// CHECK-SAME:  (%[[L:.+]]: !cute.layout<"(?,8):(1,?)">)
func.func @dynamic_layout(%l: !cute.layout<"(?,8):(1,?)">) -> !cute.shape<"(?,8)"> {
  // CHECK: %[[R:.+]] = cute.get_shape(%[[L]]) : !cute.layout<"(?,8):(1,?)"> -> !cute.shape<"(?,8)">
  %r = cute.get_shape(%l) : !cute.layout<"(?,8):(1,?)"> -> !cute.shape<"(?,8)">
  // CHECK: return %[[R]]
  return %r : !cute.shape<"(?,8)">
}

// -----

// Tests get_shape from a composed_layout — returns the outer (B) layout's shape.
// CHECK-LABEL: func.func @composed_layout
// CHECK-SAME:  (%[[CL:.+]]: !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">)
func.func @composed_layout(%cl: !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)">) -> !cute.shape<"(2,4)"> {
  // CHECK: %[[R:.+]] = cute.get_shape(%[[CL]]) : !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)"> -> !cute.shape<"(2,4)">
  %r = cute.get_shape(%cl) : !cute.composed_layout<"(4,8):(1,4) o 0 o (2,4):(1,2)"> -> !cute.shape<"(2,4)">
  // CHECK: return %[[R]]
  return %r : !cute.shape<"(2,4)">
}

// -----

// Tests get_shape from a tile — extracts the shape of each constituent layout.
// CHECK-LABEL: func.func @tile_two_layouts
// CHECK-SAME:  (%[[T:.+]]: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">)
func.func @tile_two_layouts(%t: !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]">) -> !cute.shape<"((4,8),(2,3))"> {
  // CHECK: %[[R:.+]] = cute.get_shape(%[[T]]) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]"> -> !cute.shape<"((4,8),(2,3))">
  %r = cute.get_shape(%t) : !cute.tile<"[(4,8):(1,4);(2,3):(1,2)]"> -> !cute.shape<"((4,8),(2,3))">
  // CHECK: return %[[R]]
  return %r : !cute.shape<"((4,8),(2,3))">
}
