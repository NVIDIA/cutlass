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

// RUN: cute-opt -cute-to-base --split-input-file %s | FileCheck %s

// Regression: ops from unknown dialects (e.g. math, builtin) must pass
// through cute-to-base unchanged while cute ops are lowered alongside.

// -----

// `math.sqrt` sits next to a cute op and must remain after lowering.
// CHECK-LABEL: func.func @math_alongside_cute
// CHECK-SAME:    (%[[X:.+]]: f32)
// CHECK-NOT:     cute.make_coord
// CHECK:         %[[S:.+]] = math.sqrt %[[X]] : f32
// CHECK:         arith.fptosi %[[S]] : f32 to i32
// CHECK:         return
func.func @math_alongside_cute(%x: f32) -> !cute.coord<"(?)"> {
  %s = math.sqrt %x : f32
  %i = arith.fptosi %s : f32 to i32
  %r = cute.make_coord(%i) : (i32) -> !cute.coord<"(?)">
  return %r : !cute.coord<"(?)">
}

// -----

// A standalone `math.sqrt` (no cute payload in this function) must pass
// through untouched.
// CHECK-LABEL: func.func @standalone_math
// CHECK-SAME:    (%[[X:.+]]: f32)
// CHECK:         %[[S:.+]] = math.sqrt %[[X]] : f32
// CHECK:         return %[[S]]
func.func @standalone_math(%x: f32) -> f32 {
  %s = math.sqrt %x : f32
  return %s : f32
}

// -----

// `builtin.unrealized_conversion_cast` is what the type-converter's own
// materializers emit at boundaries; the pass must tolerate it both
// when it predates the pass and when it survives lowering.
// CHECK-LABEL: func.func @unrealized_cast_passthrough
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK:         %[[C:.+]] = builtin.unrealized_conversion_cast %[[A]] : i32 to i64
// CHECK:         return %[[C]] : i64
func.func @unrealized_cast_passthrough(%a: i32) -> i64 {
  %c = builtin.unrealized_conversion_cast %a : i32 to i64
  return %c : i64
}

// -----

// A function with no cute op at all should be a no-op for the pass.
// CHECK-LABEL: func.func @no_cute_at_all
// CHECK-SAME:    (%[[A:.+]]: i32)
// CHECK:         %[[R:.+]] = arith.addi %[[A]], %[[A]]
// CHECK:         return %[[R]]
func.func @no_cute_at_all(%a: i32) -> i32 {
  %r = arith.addi %a, %a : i32
  return %r : i32
}
