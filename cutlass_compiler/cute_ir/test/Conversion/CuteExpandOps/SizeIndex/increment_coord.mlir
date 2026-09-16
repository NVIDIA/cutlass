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

// RUN: cute-opt -cute-expand-ops --split-input-file %s | FileCheck %s

// Tests `cute-expand-ops` lowering for `cute.increment_coord`.

// -----

// CHECK-LABEL: func.func @expand_static
// CHECK-NOT:   cute.increment_coord
// CHECK:       cute.static : !cute.coord<"(2,2)">
func.func @expand_static(%c: !cute.coord<"(1,2)">,
                          %s: !cute.shape<"(4,8)">)
    -> !cute.coord<"(2,2)"> {
  %r = cute.increment_coord(%c, %s)
         : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">)
        -> !cute.coord<"(2,2)">
  return %r : !cute.coord<"(2,2)">
}

// -----

// Dynamic coord, static shape — increment computed via arith.
// CHECK-LABEL: func.func @expand_dynamic_coord
// CHECK-NOT:   cute.increment_coord
// CHECK:       cute.get_scalars<{only_dynamic}>
// CHECK:       arith.addi
// CHECK:       cute.make_coord
// CHECK-SAME:  -> !cute.coord<"(?,?)">
func.func @expand_dynamic_coord(%c: !cute.coord<"(?,?)">,
                                 %s: !cute.shape<"(4,8)">)
    -> !cute.coord<"(?,?)"> {
  %r = cute.increment_coord(%c, %s)
         : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">)
        -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// Static coord with dynamic shape: dynamic wrap point, scf.if carry branch.
// CHECK-LABEL: func.func @expand_static_coord_dyn_shape
// CHECK-NOT:   cute.increment_coord
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.shape<"(?,8)">
// CHECK:       arith.cmpi slt
// CHECK:       scf.if
// CHECK:       cute.make_coord
// CHECK-SAME:  -> !cute.coord<"(?,?)">
func.func @expand_static_coord_dyn_shape(%c: !cute.coord<"(1,2)">,
                                          %s: !cute.shape<"(?,8)">)
    -> !cute.coord<"(?,?)"> {
  %r = cute.increment_coord(%c, %s)
         : (!cute.coord<"(1,2)">, !cute.shape<"(?,8)">)
        -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// Hierarchical dynamic coord and shape: carry chain across nested modes.
// CHECK-LABEL: func.func @expand_hierarchical_dyn
// CHECK-NOT:   cute.increment_coord
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.coord<"(?,(?,?))">
// CHECK:       arith.addi
// CHECK:       arith.cmpi
// CHECK:       scf.if
// CHECK:       cute.make_coord(%{{.+}}, %{{.+}}, %{{.+}}) : (i32, i32, i32) -> !cute.coord<"(?,(?,?))">
func.func @expand_hierarchical_dyn(%c: !cute.coord<"(?,(?,?))">,
                                    %s: !cute.shape<"(4,(3,8))">)
    -> !cute.coord<"(?,(?,?))"> {
  %r = cute.increment_coord(%c, %s)
         : (!cute.coord<"(?,(?,?))">, !cute.shape<"(4,(3,8))">)
        -> !cute.coord<"(?,(?,?))">
  return %r : !cute.coord<"(?,(?,?))">
}

// -----

// Scalar dynamic coord and shape: single mode, no carry, one arith.addi.
// CHECK-LABEL: func.func @expand_scalar_dyn
// CHECK-NOT:   cute.increment_coord
// CHECK:       %[[CDYN:.+]] = cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.coord<"?">
// CHECK:       %[[C1:.+]] = arith.constant 1 : i32
// CHECK:       %[[SUM:.+]] = arith.addi %[[CDYN]], %[[C1]] overflow<nsw> : i32
// CHECK:       cute.make_coord(%[[SUM]]) : (i32) -> !cute.coord<"?">
// CHECK-NOT:   scf.if
func.func @expand_scalar_dyn(%c: !cute.coord<"?">, %s: !cute.shape<"8">)
    -> !cute.coord<"?"> {
  %r = cute.increment_coord(%c, %s)
         : (!cute.coord<"?">, !cute.shape<"8">) -> !cute.coord<"?">
  return %r : !cute.coord<"?">
}

// -----

// Both coord and shape dynamic (rank-2): wrap point from dyn shape, scf.if carry.
// CHECK-LABEL: func.func @expand_both_dyn
// CHECK-NOT:   cute.increment_coord
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.coord<"(?,?)">
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.shape<"(?,4)">
// CHECK:       arith.addi
// CHECK:       arith.cmpi
// CHECK:       scf.if
// CHECK:       cute.make_coord(%{{.+}}, %{{.+}}) : (i32, i32) -> !cute.coord<"(?,?)">
func.func @expand_both_dyn(%c: !cute.coord<"(?,?)">, %s: !cute.shape<"(?,4)">)
    -> !cute.coord<"(?,?)"> {
  %r = cute.increment_coord(%c, %s)
         : (!cute.coord<"(?,?)">, !cute.shape<"(?,4)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// Both hierarchical and fully-dynamic coord and shape.
// CHECK-LABEL: func.func @expand_both_dyn_hier
// CHECK-NOT:   cute.increment_coord
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.coord<"(?,(?))">
// CHECK:       cute.get_scalars<{only_dynamic}> (%{{.+}}) : !cute.shape<"(?,(?))">
// CHECK:       arith.addi
// CHECK:       arith.cmpi
// CHECK:       scf.if
// CHECK:       cute.make_coord(%{{.+}}, %{{.+}}) : (i32, i32) -> !cute.coord<"(?,(?))">
func.func @expand_both_dyn_hier(%c: !cute.coord<"(?,(?))">,
                                 %s: !cute.shape<"(?,(?))">)
    -> !cute.coord<"(?,(?))"> {
  %r = cute.increment_coord(%c, %s)
         : (!cute.coord<"(?,(?))">, !cute.shape<"(?,(?))">) -> !cute.coord<"(?,(?))">
  return %r : !cute.coord<"(?,(?))">
}
