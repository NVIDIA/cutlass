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

// Tests `cute-to-base` lowering for `cute.make_int_tuple`.

// -----

// Fully static int_tuple — empty struct.
// CHECK-LABEL: func.func @int_tuple_static
// CHECK-NOT:     cute.make_int_tuple
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return
func.func @int_tuple_static() -> !cute.int_tuple<"(2,3)"> {
  %r = cute.make_int_tuple () : () -> !cute.int_tuple<"(2,3)">
  return %r : !cute.int_tuple<"(2,3)">
}

// -----

// Single dynamic leaf — bare i32, no struct wrapping.
// CHECK-LABEL: func.func @int_tuple_one_dyn
// CHECK-NOT:     cute.make_int_tuple
// CHECK-NOT:     llvm.insertvalue
// CHECK:         return
func.func @int_tuple_one_dyn(%a: i32) -> !cute.int_tuple<"?"> {
  %r = cute.make_int_tuple (%a) : (i32) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Mixed dynamic + static — single dyn leaf still lowers to bare i32.
// CHECK-LABEL: func.func @int_tuple_mixed
// CHECK-NOT:     cute.make_int_tuple
// CHECK-NOT:     llvm.insertvalue
// CHECK:         return
func.func @int_tuple_mixed(%a: i32) -> !cute.int_tuple<"(?,3)"> {
  %r = cute.make_int_tuple (%a) : (i32) -> !cute.int_tuple<"(?,3)">
  return %r : !cute.int_tuple<"(?,3)">
}

// -----

// Two dynamic leaves — one insertvalue per leaf.
// CHECK-LABEL: func.func @int_tuple_two_dyn
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cute.make_int_tuple
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[A]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[B]], %[[V0]][1]
// CHECK:         return
func.func @int_tuple_two_dyn(%a: i32, %b: i32) -> !cute.int_tuple<"(?,?)"> {
  %r = cute.make_int_tuple (%a, %b) : (i32, i32) -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}
