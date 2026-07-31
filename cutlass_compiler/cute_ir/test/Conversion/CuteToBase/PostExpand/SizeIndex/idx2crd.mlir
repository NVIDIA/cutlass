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

// RUN: cute-opt -cute-fold-static -cute-expand-ops -cute-to-base \
// RUN:   --split-input-file %s \
// RUN:   | cute-opt -reconcile-unrealized-casts --split-input-file \
// RUN:   | FileCheck %s

// Full pipeline lowering for `cute.idx2crd`.

// -----
// Static index and shape: coord resolved at compile time.
// CHECK-LABEL: func.func @idx2crd_static
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @idx2crd_static(%i: !cute.int_tuple<"9">, %s: !cute.shape<"(4,8)">)
    -> !cute.coord<"(1,2)"> {
  %r = cute.idx2crd(%i, %s) : (!cute.int_tuple<"9">, !cute.shape<"(4,8)">) -> !cute.coord<"(1,2)">
  return %r : !cute.coord<"(1,2)">
}

// -----
// Dynamic index, static shape.
// CHECK-LABEL: func.func @idx2crd_dyn
// CHECK-SAME:    [[I:%.+]]: i32
// CHECK:         arith.constant 4 : i32
// CHECK:         arith.divsi
// CHECK:         arith.constant 4 : i32
// CHECK:         arith.remsi
// CHECK:         ub.poison : !llvm.struct<(i32, i32)>
// CHECK-COUNT-2: llvm.insertvalue
// CHECK:         return {{.+}} : !llvm.struct<(i32, i32)>
func.func @idx2crd_dyn(%i: !cute.int_tuple<"?">, %s: !cute.shape<"(4,8)">)
    -> !cute.coord<"(?,?)"> {
  %r = cute.idx2crd(%i, %s) : (!cute.int_tuple<"?">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----
// Dynamic index, nested shape.
// (3 leaves for `(4,(2,3))`), reached via two divsi/remsi pairs. The cute-
// level nested profile `(?,(?,?))` is preserved at the cute type level but
// flattens at the LLVM struct level.
// CHECK-LABEL: func.func @idx2crd_nested_dyn
// CHECK-SAME:    [[I:%.+]]: i32
// CHECK:         arith.divsi
// CHECK:         arith.remsi
// CHECK:         arith.divsi
// CHECK:         arith.remsi
// CHECK:         ub.poison : !llvm.struct<(i32, i32, i32)>
// CHECK-COUNT-3: llvm.insertvalue
// CHECK:         return {{.+}} : !llvm.struct<(i32, i32, i32)>
func.func @idx2crd_nested_dyn(%i: !cute.int_tuple<"?">, %s: !cute.shape<"(4,(2,3))">)
    -> !cute.coord<"(?,(?,?))"> {
  %r = cute.idx2crd(%i, %s) : (!cute.int_tuple<"?">, !cute.shape<"(4,(2,3))">) -> !cute.coord<"(?,(?,?))">
  return %r : !cute.coord<"(?,(?,?))">
}
