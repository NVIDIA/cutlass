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
// RUN: cute-opt %s -split-input-file | cute-opt | FileCheck %s
// RUN: cute-opt -mlir-print-op-generic %s -split-input-file | cute-opt | FileCheck %s

// Tests round-trip for cute.increment_coord.

// -----

// Static: no carry — only first mode increments.
// CHECK-LABEL: func.func @increment_coord_static
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(1,2)">, %[[S:.+]]: !cute.shape<"(4,8)">)
func.func @increment_coord_static(%c: !cute.coord<"(1,2)">, %s: !cute.shape<"(4,8)">) -> !cute.coord<"(2,2)"> {
  // CHECK: %[[R:.+]] = cute.increment_coord(%[[C]], %[[S]]) : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(2,2)">
  %r = cute.increment_coord(%c, %s) : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(2,2)">
  return %r : !cute.coord<"(2,2)">
}

// -----

// Static: first mode wraps, carry propagates to second mode.
// CHECK-LABEL: func.func @increment_coord_static_wrap
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(3,2)">, %[[S:.+]]: !cute.shape<"(4,8)">)
func.func @increment_coord_static_wrap(%c: !cute.coord<"(3,2)">, %s: !cute.shape<"(4,8)">) -> !cute.coord<"(0,3)"> {
  // CHECK: %[[R:.+]] = cute.increment_coord(%[[C]], %[[S]]) : (!cute.coord<"(3,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(0,3)">
  %r = cute.increment_coord(%c, %s) : (!cute.coord<"(3,2)">, !cute.shape<"(4,8)">) -> !cute.coord<"(0,3)">
  return %r : !cute.coord<"(0,3)">
}

// -----

// Dynamic coord: result has same hierarchical profile with dynamic values.
// CHECK-LABEL: func.func @increment_coord_dynamic
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(?,?)">, %[[S:.+]]: !cute.shape<"(4,8)">)
func.func @increment_coord_dynamic(%c: !cute.coord<"(?,?)">, %s: !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.increment_coord(%[[C]], %[[S]]) : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  %r = cute.increment_coord(%c, %s) : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// Nested static: congruent hierarchical coord and shape.
// CHECK-LABEL: func.func @increment_coord_nested
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(1,(2,0))">, %[[S:.+]]: !cute.shape<"(4,(3,8))">)
func.func @increment_coord_nested(%c: !cute.coord<"(1,(2,0))">, %s: !cute.shape<"(4,(3,8))">) -> !cute.coord<"(2,(2,0))"> {
  // CHECK: %[[R:.+]] = cute.increment_coord(%[[C]], %[[S]]) : (!cute.coord<"(1,(2,0))">, !cute.shape<"(4,(3,8))">) -> !cute.coord<"(2,(2,0))">
  %r = cute.increment_coord(%c, %s) : (!cute.coord<"(1,(2,0))">, !cute.shape<"(4,(3,8))">) -> !cute.coord<"(2,(2,0))">
  return %r : !cute.coord<"(2,(2,0))">
}

// -----

// Static coord with dynamic shape. The
// dyn shape mode 0 means the wrap point isn't statically known, so both
// result modes become dynamic.
// CHECK-LABEL: func.func @increment_coord_static_coord
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(1,2)">, %[[S:.+]]: !cute.shape<"(?,8)">)
func.func @increment_coord_static_coord(%c: !cute.coord<"(1,2)">, %s: !cute.shape<"(?,8)">)
    -> !cute.coord<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.increment_coord(%[[C]], %[[S]]) : (!cute.coord<"(1,2)">, !cute.shape<"(?,8)">) -> !cute.coord<"(?,?)">
  %r = cute.increment_coord(%c, %s) : (!cute.coord<"(1,2)">, !cute.shape<"(?,8)">) -> !cute.coord<"(?,?)">
  return %r : !cute.coord<"(?,?)">
}

// -----

// Three chained increments on a rank-4 static coord.
// CHECK-LABEL: func.func @increment_coord_chain
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(0,0,0,0)">, %[[S:.+]]: !cute.shape<"(3,3,3,3)">)
func.func @increment_coord_chain(%c: !cute.coord<"(0,0,0,0)">,
                                  %s: !cute.shape<"(3,3,3,3)">)
    -> !cute.coord<"(0,1,0,0)"> {
  // CHECK: %[[C1:.+]] = cute.increment_coord(%[[C]], %[[S]]) : (!cute.coord<"(0,0,0,0)">, !cute.shape<"(3,3,3,3)">) -> !cute.coord<"(1,0,0,0)">
  // CHECK: %[[C2:.+]] = cute.increment_coord(%[[C1]], %[[S]]) : (!cute.coord<"(1,0,0,0)">, !cute.shape<"(3,3,3,3)">) -> !cute.coord<"(2,0,0,0)">
  // CHECK: %[[C3:.+]] = cute.increment_coord(%[[C2]], %[[S]]) : (!cute.coord<"(2,0,0,0)">, !cute.shape<"(3,3,3,3)">) -> !cute.coord<"(0,1,0,0)">
  %c1 = cute.increment_coord(%c, %s) : (!cute.coord<"(0,0,0,0)">, !cute.shape<"(3,3,3,3)">) -> !cute.coord<"(1,0,0,0)">
  %c2 = cute.increment_coord(%c1, %s) : (!cute.coord<"(1,0,0,0)">, !cute.shape<"(3,3,3,3)">) -> !cute.coord<"(2,0,0,0)">
  %c3 = cute.increment_coord(%c2, %s) : (!cute.coord<"(2,0,0,0)">, !cute.shape<"(3,3,3,3)">) -> !cute.coord<"(0,1,0,0)">
  return %c3 : !cute.coord<"(0,1,0,0)">
}

// -----

// Two-step out-of-bounds carry chain on a rank-3 coord.
// CHECK-LABEL: func.func @increment_coord_oob_chain
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(2,2,2)">, %[[S:.+]]: !cute.shape<"(3,3,3)">)
func.func @increment_coord_oob_chain(%c: !cute.coord<"(2,2,2)">,
                                      %s: !cute.shape<"(3,3,3)">)
    -> !cute.coord<"(1,0,3)"> {
  // CHECK: %[[C1:.+]] = cute.increment_coord(%[[C]], %[[S]]) : (!cute.coord<"(2,2,2)">, !cute.shape<"(3,3,3)">) -> !cute.coord<"(0,0,3)">
  // CHECK: %[[C2:.+]] = cute.increment_coord(%[[C1]], %[[S]]) : (!cute.coord<"(0,0,3)">, !cute.shape<"(3,3,3)">) -> !cute.coord<"(1,0,3)">
  %c1 = cute.increment_coord(%c, %s) : (!cute.coord<"(2,2,2)">, !cute.shape<"(3,3,3)">) -> !cute.coord<"(0,0,3)">
  %c2 = cute.increment_coord(%c1, %s) : (!cute.coord<"(0,0,3)">, !cute.shape<"(3,3,3)">) -> !cute.coord<"(1,0,3)">
  return %c2 : !cute.coord<"(1,0,3)">
}

// -----

// Depth-2 nested fully-dynamic coord + partly-dyn shape.
// CHECK-LABEL: func.func @increment_coord_hierarchical_dyn
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"((?,?),(?,?))">, %[[S:.+]]: !cute.shape<"((?,3),(3,3))">)
func.func @increment_coord_hierarchical_dyn(
    %c: !cute.coord<"((?,?),(?,?))">,
    %s: !cute.shape<"((?,3),(3,3))">)
    -> !cute.coord<"((?,?),(?,?))"> {
  // CHECK: %[[R:.+]] = cute.increment_coord(%[[C]], %[[S]]) : (!cute.coord<"((?,?),(?,?))">, !cute.shape<"((?,3),(3,3))">) -> !cute.coord<"((?,?),(?,?))">
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"((?,?),(?,?))">, !cute.shape<"((?,3),(3,3))">)
      -> !cute.coord<"((?,?),(?,?))">
  return %r : !cute.coord<"((?,?),(?,?))">
}

// -----

// Rank-3 all-dyn coord with a partly-dyn shape.
// CHECK-LABEL: func.func @increment_coord_rank3_dyn
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(?,?,?)">, %[[S:.+]]: !cute.shape<"(?,4,8)">)
func.func @increment_coord_rank3_dyn(%c: !cute.coord<"(?,?,?)">,
                                      %s: !cute.shape<"(?,4,8)">)
    -> !cute.coord<"(?,?,?)"> {
  // CHECK: %[[R:.+]] = cute.increment_coord(%[[C]], %[[S]]) : (!cute.coord<"(?,?,?)">, !cute.shape<"(?,4,8)">) -> !cute.coord<"(?,?,?)">
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"(?,?,?)">, !cute.shape<"(?,4,8)">)
      -> !cute.coord<"(?,?,?)">
  return %r : !cute.coord<"(?,?,?)">
}

// -----

// Rank-4 all-static coord with a partly-dyn shape.
// CHECK-LABEL: func.func @increment_coord_rank4_static
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(0,0,0,0)">, %[[S:.+]]: !cute.shape<"(?,3,3,1)">)
func.func @increment_coord_rank4_static(%c: !cute.coord<"(0,0,0,0)">,
                                         %s: !cute.shape<"(?,3,3,1)">)
    -> !cute.coord<"(?,?,?,?)"> {
  // CHECK: %[[R:.+]] = cute.increment_coord(%[[C]], %[[S]]) : (!cute.coord<"(0,0,0,0)">, !cute.shape<"(?,3,3,1)">) -> !cute.coord<"(?,?,?,?)">
  %r = cute.increment_coord(%c, %s)
       : (!cute.coord<"(0,0,0,0)">, !cute.shape<"(?,3,3,1)">)
      -> !cute.coord<"(?,?,?,?)">
  return %r : !cute.coord<"(?,?,?,?)">
}
