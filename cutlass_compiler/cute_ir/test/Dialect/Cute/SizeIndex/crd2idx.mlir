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

// Tests round-trip for cute.crd2idx: pack a coord into a linear index
// using implicit column-major strides derived from the shape.

// -----

// Static rank-2: (1,2) on (4,8) → 1*1 + 2*4 = 9.
// CHECK-LABEL: func.func @static_rank2
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(1,2)">, %[[S:.+]]: !cute.shape<"(4,8)">)
func.func @static_rank2(
    %c: !cute.coord<"(1,2)">,
    %s: !cute.shape<"(4,8)">) -> !cute.int_tuple<"9"> {
  // CHECK: %[[R:.+]] = cute.crd2idx(%[[C]], %[[S]])
  // CHECK-SAME: (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"9">
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"(1,2)">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}

// -----

// Scalar coord on scalar shape: coord itself is the index.
// CHECK-LABEL: func.func @scalar
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"5">, %[[S:.+]]: !cute.shape<"8">)
func.func @scalar(
    %c: !cute.coord<"5">, %s: !cute.shape<"8">) -> !cute.int_tuple<"5"> {
  // CHECK: %[[R:.+]] = cute.crd2idx(%[[C]], %[[S]])
  // CHECK-SAME: (!cute.coord<"5">, !cute.shape<"8">) -> !cute.int_tuple<"5">
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"5">, !cute.shape<"8">) -> !cute.int_tuple<"5">
  return %r : !cute.int_tuple<"5">
}

// -----

// Nested rank-2: ((1,2),3) on ((4,8),6) → 1 + 2*4 + 3*32 = 105.
// CHECK-LABEL: func.func @nested
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"((1,2),3)">, %[[S:.+]]: !cute.shape<"((4,8),6)">)
func.func @nested(
    %c: !cute.coord<"((1,2),3)">,
    %s: !cute.shape<"((4,8),6)">) -> !cute.int_tuple<"105"> {
  // CHECK: %[[R:.+]] = cute.crd2idx(%[[C]], %[[S]])
  // CHECK-SAME: (!cute.coord<"((1,2),3)">, !cute.shape<"((4,8),6)">) -> !cute.int_tuple<"105">
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"((1,2),3)">, !cute.shape<"((4,8),6)">) -> !cute.int_tuple<"105">
  return %r : !cute.int_tuple<"105">
}

// -----

// Dynamic coord, static shape: result is dynamic.
// CHECK-LABEL: func.func @dyn_coord
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(?,?)">, %[[S:.+]]: !cute.shape<"(4,8)">)
func.func @dyn_coord(
    %c: !cute.coord<"(?,?)">,
    %s: !cute.shape<"(4,8)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.crd2idx(%[[C]], %[[S]])
  // CHECK-SAME: (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"?">
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"(?,?)">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Static coord, dynamic shape: an unknown extent propagates into the
// column-major weighting, so the result is dynamic.
// CHECK-LABEL: func.func @dyn_shape
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"(1,2)">, %[[S:.+]]: !cute.shape<"(?,8)">)
func.func @dyn_shape(
    %c: !cute.coord<"(1,2)">,
    %s: !cute.shape<"(?,8)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.crd2idx(%[[C]], %[[S]])
  // CHECK-SAME: (!cute.coord<"(1,2)">, !cute.shape<"(?,8)">) -> !cute.int_tuple<"?">
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"(1,2)">, !cute.shape<"(?,8)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Scalar coord on rank-2 shape: the coord weakly-matches; it's treated as
// the linear index into the column-major walk directly.
// CHECK-LABEL: func.func @scalar_coord_rank2_shape
// CHECK-SAME:  (%[[C:.+]]: !cute.coord<"9">, %[[S:.+]]: !cute.shape<"(4,8)">)
func.func @scalar_coord_rank2_shape(
    %c: !cute.coord<"9">,
    %s: !cute.shape<"(4,8)">) -> !cute.int_tuple<"9"> {
  // CHECK: %[[R:.+]] = cute.crd2idx(%[[C]], %[[S]])
  // CHECK-SAME: (!cute.coord<"9">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"9">
  %r = cute.crd2idx(%c, %s)
         : (!cute.coord<"9">, !cute.shape<"(4,8)">) -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}
