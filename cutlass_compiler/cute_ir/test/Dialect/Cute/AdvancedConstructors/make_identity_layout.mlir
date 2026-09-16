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

// Tests parse/print round-trip for cute.make_identity_layout.

// -----

// Scalar shape — stride is 1 (unit basis for the single mode).
// CHECK-LABEL: func.func @scalar_shape
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"4">)
func.func @scalar_shape(%s: !cute.shape<"4">) -> !cute.layout<"4:1"> {
  // CHECK: %[[L:.+]] = cute.make_identity_layout(%[[S]]) : !cute.shape<"4"> -> !cute.layout<"4:1">
  %l = cute.make_identity_layout(%s) : !cute.shape<"4"> -> !cute.layout<"4:1">
  return %l : !cute.layout<"4:1">
}

// -----

// Flat 2D shape — each mode gets its own scaled-basis stride.
// CHECK-LABEL: func.func @flat_shape
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(4,2)">)
func.func @flat_shape(%s: !cute.shape<"(4,2)">) -> !cute.layout<"(4,2):(1@0,1@1)"> {
  // CHECK: cute.make_identity_layout(%[[S]]) : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1@0,1@1)">
  %l = cute.make_identity_layout(%s) : !cute.shape<"(4,2)"> -> !cute.layout<"(4,2):(1@0,1@1)">
  return %l : !cute.layout<"(4,2):(1@0,1@1)">
}

// -----

// Nested shape — hierarchical basis strides index into nested modes.
// CHECK-LABEL: func.func @nested_shape
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(2,(3,4),5)">)
func.func @nested_shape(%s: !cute.shape<"(2,(3,4),5)">) -> !cute.layout<"(2,(3,4),5):(1@0,(1@0@1,1@1@1),1@2)"> {
  // CHECK: cute.make_identity_layout(%[[S]])
  // CHECK-SAME: !cute.shape<"(2,(3,4),5)"> -> !cute.layout<"(2,(3,4),5):(1@0,(1@0@1,1@1@1),1@2)">
  %l = cute.make_identity_layout(%s)
         : !cute.shape<"(2,(3,4),5)"> -> !cute.layout<"(2,(3,4),5):(1@0,(1@0@1,1@1@1),1@2)">
  return %l : !cute.layout<"(2,(3,4),5):(1@0,(1@0@1,1@1@1),1@2)">
}

// -----

// Dynamic extent — strides are still fully static scaled-basis vectors.
// CHECK-LABEL: func.func @dynamic_extent
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(?,3)">)
func.func @dynamic_extent(%s: !cute.shape<"(?,3)">) -> !cute.layout<"(?,3):(1@0,1@1)"> {
  // CHECK: cute.make_identity_layout(%[[S]]) : !cute.shape<"(?,3)"> -> !cute.layout<"(?,3):(1@0,1@1)">
  %l = cute.make_identity_layout(%s) : !cute.shape<"(?,3)"> -> !cute.layout<"(?,3):(1@0,1@1)">
  return %l : !cute.layout<"(?,3):(1@0,1@1)">
}

// -----

// Deeply nested shape (3 nesting levels)
// CHECK-LABEL: func.func @deeply_nested_shape
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(2,(3,(4,5)),6)">)
func.func @deeply_nested_shape(%s: !cute.shape<"(2,(3,(4,5)),6)">) -> !cute.layout<"(2,(3,(4,5)),6):(1@0,(1@0@1,(1@0@1@1,1@1@1@1)),1@2)"> {
  // CHECK: cute.make_identity_layout(%[[S]])
  // CHECK-SAME: !cute.shape<"(2,(3,(4,5)),6)"> -> !cute.layout<"(2,(3,(4,5)),6):(1@0,(1@0@1,(1@0@1@1,1@1@1@1)),1@2)">
  %l = cute.make_identity_layout(%s)
         : !cute.shape<"(2,(3,(4,5)),6)"> -> !cute.layout<"(2,(3,(4,5)),6):(1@0,(1@0@1,(1@0@1@1,1@1@1@1)),1@2)">
  return %l : !cute.layout<"(2,(3,(4,5)),6):(1@0,(1@0@1,(1@0@1@1,1@1@1@1)),1@2)">
}

// -----

// All-dynamic shape.
// CHECK-LABEL: func.func @all_dynamic_shape
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(?,?)">)
func.func @all_dynamic_shape(%s: !cute.shape<"(?,?)">) -> !cute.layout<"(?,?):(1@0,1@1)"> {
  // CHECK: cute.make_identity_layout(%[[S]]) : !cute.shape<"(?,?)"> -> !cute.layout<"(?,?):(1@0,1@1)">
  %l = cute.make_identity_layout(%s) : !cute.shape<"(?,?)"> -> !cute.layout<"(?,?):(1@0,1@1)">
  return %l : !cute.layout<"(?,?):(1@0,1@1)">
}

// -----

// Depth-2 nest with all-static outer modes and an inner tuple of two
// dynamic leaves.
// CHECK-LABEL: func.func @nested_partial_dynamic_shape
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(2,(?,?),5)">)
func.func @nested_partial_dynamic_shape(%s: !cute.shape<"(2,(?,?),5)">)
    -> !cute.layout<"(2,(?,?),5):(1@0,(1@0@1,1@1@1),1@2)"> {
  // CHECK: cute.make_identity_layout(%[[S]])
  // CHECK-SAME: !cute.shape<"(2,(?,?),5)"> -> !cute.layout<"(2,(?,?),5):(1@0,(1@0@1,1@1@1),1@2)">
  %l = cute.make_identity_layout(%s)
       : !cute.shape<"(2,(?,?),5)">
      -> !cute.layout<"(2,(?,?),5):(1@0,(1@0@1,1@1@1),1@2)">
  return %l : !cute.layout<"(2,(?,?),5):(1@0,(1@0@1,1@1@1),1@2)">
}
