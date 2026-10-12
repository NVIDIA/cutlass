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

// Tests `cute-to-base` lowering for `cute.make_coord`.

// -----

// Fully static coord — empty struct.
// CHECK-LABEL: func.func @coord_static
// CHECK-NOT:     cute.make_coord
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<()>
// CHECK:         return
func.func @coord_static() -> !cute.coord<"(1,2)"> {
  %r = cute.make_coord () : () -> !cute.coord<"(1,2)">
  return %r : !cute.coord<"(1,2)">
}

// -----

// Coord with two dynamic leaves and one underscore — only the dynamics
// materialize. Underscore is fully static.
// CHECK-LABEL: func.func @coord_two_dyn_one_us
// CHECK-SAME:    (%[[A:.+]]: i32, %[[B:.+]]: i32)
// CHECK-NOT:     cute.make_coord
// CHECK:         %[[P:.+]] = ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         %[[V0:.+]] = llvm.insertvalue %[[A]], %[[P]][0]
// CHECK:         %[[V1:.+]] = llvm.insertvalue %[[B]], %[[V0]][1]
// CHECK:         return
func.func @coord_two_dyn_one_us(%a: i32, %b: i32) -> !cute.coord<"(?,?,_)"> {
  %r = cute.make_coord (%a, %b) : (i32, i32) -> !cute.coord<"(?,?,_)">
  return %r : !cute.coord<"(?,?,_)">
}
