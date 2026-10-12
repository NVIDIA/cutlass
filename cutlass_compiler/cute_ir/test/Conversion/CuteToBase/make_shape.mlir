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

// Tests `cute-to-base` lowering for `cute.make_shape`.

// -----

// Fully static shape — empty struct.
// CHECK-LABEL: func.func @shape_static
// CHECK-NOT:     cute.make_shape
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return
func.func @shape_static() -> !cute.shape<"(2,3)"> {
  %r = cute.make_shape () : () -> !cute.shape<"(2,3)">
  return %r : !cute.shape<"(2,3)">
}

// -----

// Two dynamic shape extents — converts to `struct<(i32, i32)>`.
// CHECK-LABEL: func.func @shape_two_dyn
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cute.make_shape
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[A]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[B]], %[[V0]][1]
// CHECK:         return
func.func @shape_two_dyn(%a: i32, %b: i32) -> !cute.shape<"(?,?)"> {
  %r = cute.make_shape (%a, %b) : (i32, i32) -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}

// -----

// One dynamic + one static — single-dyn-leaf shape lowers to bare i32.
// CHECK-LABEL: func.func @shape_mixed
// CHECK-NOT:     cute.make_shape
// CHECK-NOT:     llvm.insertvalue
// CHECK:         return
func.func @shape_mixed(%a: i32) -> !cute.shape<"(?,4)"> {
  %r = cute.make_shape (%a) : (i32) -> !cute.shape<"(?,4)">
  return %r : !cute.shape<"(?,4)">
}

// -----

// Nested rank-3 shape — 3 dynamic leaves flatten into one struct.
// CHECK-LABEL: func.func @shape_nested_three_dyn
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32, %[[C:.+]]: i32)
// CHECK-NOT:     cute.make_shape
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, i32, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[A]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[B]], %[[V0]][1]
// CHECK:         %[[V2:.+]] = llvm.insertvalue %[[C]], %[[V1]][2]
// CHECK:         return
func.func @shape_nested_three_dyn(%a: i32, %b: i32, %c: i32)
    -> !cute.shape<"(?,(?,?))"> {
  %r = cute.make_shape (%a, %b, %c)
         : (i32, i32, i32) -> !cute.shape<"(?,(?,?))">
  return %r : !cute.shape<"(?,(?,?))">
}

// -----

// Two i32 operands fill `?` slots — both flow straight into the
// LLVM struct insert chain.
// CHECK-LABEL: func.func @shape_two_i32_operands
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cute.make_shape
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[A]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[B]], %[[V0]][1]
// CHECK:         return
func.func @shape_two_i32_operands(
    %a: i32, %b: i32)
    -> !cute.shape<"(?,?)"> {
  %r = cute.make_shape (%a, %b)
         : (i32, i32) -> !cute.shape<"(?,?)">
  return %r : !cute.shape<"(?,?)">
}
