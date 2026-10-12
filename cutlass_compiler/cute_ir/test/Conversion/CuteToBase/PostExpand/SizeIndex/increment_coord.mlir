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

// Full pipeline lowering for `cute.increment_coord`.

// -----
// Fully-static coord and shape.
// CHECK-LABEL: func.func @increment_coord_static_folds_to_poison
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @increment_coord_static_folds_to_poison(
    %c: !cute.coord<"(1,2)">, %s: !cute.shape<"(4,8)">)
    -> !cute.coord<"(2,2)"> {
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(2,2)">
  return %r : !cute.coord<"(2,2)">
}

// -----
// Dynamic coord, static shape.
// CHECK-LABEL: func.func @increment_coord_dyn_coord
// CHECK-SAME:    [[C:%.+]]: !llvm.struct<(i32, i32)>
// CHECK:         [[C0:%.+]] = llvm.extractvalue [[C]][0]
// CHECK:         [[C1:%.+]] = llvm.extractvalue [[C]][1]
// CHECK:         arith.constant 1 : i32
// CHECK:         arith.addi
// CHECK:         arith.cmpi slt
// CHECK:         scf.if
// CHECK:         ub.poison : !llvm.struct<(i32, i32)>
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         return
func.func @increment_coord_dyn_coord(
    %c: !cute.coord<"(?,?)">, %s: !cute.shape<"(4,8)">)
    -> !cute.coord<"(?,?)"> {
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----
// Scalar dynamic coord.
// CHECK-LABEL: func.func @increment_coord_scalar_dyn
// CHECK-SAME:    %[[C:.+]]: i32, {{.+}}
// CHECK-NEXT:    %[[C1:.+]] = arith.constant 1 : i32
// CHECK-NEXT:    %[[R:.+]] = arith.addi %[[C]], %[[C1]] overflow<nsw> : i32
// CHECK-NEXT:    return %[[R]] : i32
// CHECK-NOT:     scf.if
// CHECK-NOT:     llvm.insertvalue
func.func @increment_coord_scalar_dyn(
    %c: !cute.coord<"?">, %s: !cute.shape<"8">) -> !cute.coord<"?"> {
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"?">, !cute.shape<"8">) -> !cute.coord<"?">
  return %r : !cute.coord<"?">
}

// -----
// Hierarchical static coord and shape.
// CHECK-LABEL: func.func @increment_coord_hier_static_folds_to_poison
// CHECK:         ub.poison : !llvm.struct<()>
// CHECK-NEXT:    return
func.func @increment_coord_hier_static_folds_to_poison(
    %c: !cute.coord<"(1,(2,0))">, %s: !cute.shape<"(4,(3,8))">)
    -> !cute.coord<"(2,(2,0))"> {
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"(1,(2,0))">, !cute.shape<"(4,(3,8))">) -> !cute.coord<"(2,(2,0))">
  return %r : !cute.coord<"(2,(2,0))">
}

// -----
// Hierarchical dynamic coord, static shape.
// CHECK-LABEL: func.func @increment_coord_hier_dyn_coord
// CHECK-SAME:    [[C:%.+]]: !llvm.struct<(i32, i32, i32)>
// CHECK:         llvm.extractvalue [[C]][0]
// CHECK:         llvm.extractvalue [[C]][1]
// CHECK:         llvm.extractvalue [[C]][2]
// CHECK:         arith.constant 1 : i32
// CHECK:         arith.addi
// CHECK:         arith.cmpi slt
// CHECK:         scf.if
// CHECK:         ub.poison : !llvm.struct<(i32, i32, i32)>
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         llvm.insertvalue
// CHECK:         return
func.func @increment_coord_hier_dyn_coord(
    %c: !cute.coord<"(?,(?,?))">, %s: !cute.shape<"(4,(3,8))">)
    -> !cute.coord<"(?,(?,?))"> {
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"(?,(?,?))">, !cute.shape<"(4,(3,8))">) -> !cute.coord<"(?,(?,?))">
  return %r : !cute.coord<"(?,(?,?))">
}

