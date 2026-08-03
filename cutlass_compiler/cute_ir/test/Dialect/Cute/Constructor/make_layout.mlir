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

// Tests parse/print round-trip for cute.make_layout.

// -----

// Fully static layout.
// CHECK-LABEL: func.func @static_rank2
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(4,2)">, %[[D:.+]]: !cute.stride<"(1,4)">)
func.func @static_rank2(%s: !cute.shape<"(4,2)">, %d: !cute.stride<"(1,4)">) -> !cute.layout<"(4,2):(1,4)"> {
  // CHECK: %[[L:.+]] = cute.make_layout(%[[S]], %[[D]]) : (!cute.shape<"(4,2)">, !cute.stride<"(1,4)">) -> !cute.layout<"(4,2):(1,4)">
  %l = cute.make_layout(%s, %d) : (!cute.shape<"(4,2)">, !cute.stride<"(1,4)">) -> !cute.layout<"(4,2):(1,4)">
  return %l : !cute.layout<"(4,2):(1,4)">
}

// -----

// Rank-1 static layout.
// CHECK-LABEL: func.func @static_rank1
func.func @static_rank1(%s: !cute.shape<"4">, %d: !cute.stride<"1">) -> !cute.layout<"4:1"> {
  // CHECK: cute.make_layout(%{{.+}}, %{{.+}}) : (!cute.shape<"4">, !cute.stride<"1">) -> !cute.layout<"4:1">
  %l = cute.make_layout(%s, %d) : (!cute.shape<"4">, !cute.stride<"1">) -> !cute.layout<"4:1">
  return %l : !cute.layout<"4:1">
}

// -----

// Dynamic shape with compact column-major stride.
// CHECK-LABEL: func.func @compact_dynamic_shape
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(?,2)">, %[[D:.+]]: !cute.stride<"(1,?)">)
func.func @compact_dynamic_shape(%s: !cute.shape<"(?,2)">, %d: !cute.stride<"(1,?)">) -> !cute.layout<"(?,2):(1,?)"> {
  // CHECK: cute.make_layout(%[[S]], %[[D]])
  %l = cute.make_layout(%s, %d) : (!cute.shape<"(?,2)">, !cute.stride<"(1,?)">) -> !cute.layout<"(?,2):(1,?)">
  return %l : !cute.layout<"(?,2):(1,?)">
}

// -----

// Explicit dynamic shape + dynamic stride.
// CHECK-LABEL: func.func @explicit_dynamic
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(?,2)">, %[[D:.+]]: !cute.stride<"(?,4)">)
func.func @explicit_dynamic(%s: !cute.shape<"(?,2)">, %d: !cute.stride<"(?,4)">) -> !cute.layout<"(?,2):(?,4)"> {
  // CHECK: cute.make_layout(%[[S]], %[[D]])
  %l = cute.make_layout(%s, %d) : (!cute.shape<"(?,2)">, !cute.stride<"(?,4)">) -> !cute.layout<"(?,2):(?,4)">
  return %l : !cute.layout<"(?,2):(?,4)">
}

// -----

// Static shape + dynamic stride.
// CHECK-LABEL: func.func @explicit_static_shape_dynamic_stride
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(4,2)">, %[[D:.+]]: !cute.stride<"(?,4)">)
func.func @explicit_static_shape_dynamic_stride(%s: !cute.shape<"(4,2)">, %d: !cute.stride<"(?,4)">) -> !cute.layout<"(4,2):(?,4)"> {
  // CHECK: cute.make_layout(%[[S]], %[[D]])
  %l = cute.make_layout(%s, %d) : (!cute.shape<"(4,2)">, !cute.stride<"(?,4)">) -> !cute.layout<"(4,2):(?,4)">
  return %l : !cute.layout<"(4,2):(?,4)">
}

// -----

// Nested rank-2 shapes and strides.
// CHECK-LABEL: func.func @nested_shape_stride
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"((?,2),(3,?))">, %[[D:.+]]: !cute.stride<"((?,4),(1,?))">)
func.func @nested_shape_stride(%s: !cute.shape<"((?,2),(3,?))">, %d: !cute.stride<"((?,4),(1,?))">) -> !cute.layout<"((?,2),(3,?)):((?,4),(1,?))"> {
  // CHECK: cute.make_layout(%[[S]], %[[D]])
  %l = cute.make_layout(%s, %d) : (!cute.shape<"((?,2),(3,?))">, !cute.stride<"((?,4),(1,?))">) -> !cute.layout<"((?,2),(3,?)):((?,4),(1,?))">
  return %l : !cute.layout<"((?,2),(3,?)):((?,4),(1,?))">
}

// -----

// Fully static nested layout.
// CHECK-LABEL: func.func @static_nested
func.func @static_nested(%s: !cute.shape<"((4,2),(3,5))">, %d: !cute.stride<"((1,4),(1,3))">) -> !cute.layout<"((4,2),(3,5)):((1,4),(1,3))"> {
  // CHECK: cute.make_layout(%{{.+}}, %{{.+}}) : (!cute.shape<"((4,2),(3,5))">, !cute.stride<"((1,4),(1,3))">) -> !cute.layout<"((4,2),(3,5)):((1,4),(1,3))">
  %l = cute.make_layout(%s, %d) : (!cute.shape<"((4,2),(3,5))">, !cute.stride<"((1,4),(1,3))">) -> !cute.layout<"((4,2),(3,5)):((1,4),(1,3))">
  return %l : !cute.layout<"((4,2),(3,5)):((1,4),(1,3))">
}

// -----

// Static flat layout with basis strides.
// CHECK-LABEL: func.func @static_basis_stride
func.func @static_basis_stride(%s: !cute.shape<"(2,3)">, %d: !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(2,3):(1@0,1@1)"> {
  // CHECK: cute.make_layout(%{{.+}}, %{{.+}}) : (!cute.shape<"(2,3)">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(2,3):(1@0,1@1)">
  %l = cute.make_layout(%s, %d) : (!cute.shape<"(2,3)">, !cute.stride<"(1@0,1@1)">) -> !cute.layout<"(2,3):(1@0,1@1)">
  return %l : !cute.layout<"(2,3):(1@0,1@1)">
}

// -----

// Static layout with well-formed depth-2 hierarchical basis stride.
// CHECK-LABEL: func.func @static_hierarchical_basis_well_formed
func.func @static_hierarchical_basis_well_formed(%s: !cute.shape<"(2,3)">, %d: !cute.stride<"(1@0@0,1@1@0)">) -> !cute.layout<"(2,3):(1@0@0,1@1@0)"> {
  // CHECK: cute.make_layout(%{{.+}}, %{{.+}}) : (!cute.shape<"(2,3)">, !cute.stride<"(1@0@0,1@1@0)">) -> !cute.layout<"(2,3):(1@0@0,1@1@0)">
  %l = cute.make_layout(%s, %d) : (!cute.shape<"(2,3)">, !cute.stride<"(1@0@0,1@1@0)">) -> !cute.layout<"(2,3):(1@0@0,1@1@0)">
  return %l : !cute.layout<"(2,3):(1@0@0,1@1@0)">
}

// -----

// Compact column-major for a nested static shape.
// CHECK-LABEL: func.func @compact_nested_static
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"((2,3),(4,5))">, %[[D:.+]]: !cute.stride<"((1,2),(6,24))">)
func.func @compact_nested_static(%s: !cute.shape<"((2,3),(4,5))">, %d: !cute.stride<"((1,2),(6,24))">) -> !cute.layout<"((2,3),(4,5)):((1,2),(6,24))"> {
  // CHECK: cute.make_layout(%[[S]], %[[D]])
  %l = cute.make_layout(%s, %d) : (!cute.shape<"((2,3),(4,5))">, !cute.stride<"((1,2),(6,24))">) -> !cute.layout<"((2,3),(4,5)):((1,2),(6,24))">
  return %l : !cute.layout<"((2,3),(4,5)):((1,2),(6,24))">
}

// -----

// Dynamic-scale basis strides.
// CHECK-LABEL: func.func @dynamic_basis_strides
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(?,3)">, %[[D:.+]]: !cute.stride<"(?@0,?@1)">)
func.func @dynamic_basis_strides(%s: !cute.shape<"(?,3)">, %d: !cute.stride<"(?@0,?@1)">) -> !cute.layout<"(?,3):(?@0,?@1)"> {
  // CHECK: cute.make_layout(%[[S]], %[[D]])
  %l = cute.make_layout(%s, %d) : (!cute.shape<"(?,3)">, !cute.stride<"(?@0,?@1)">) -> !cute.layout<"(?,3):(?@0,?@1)">
  return %l : !cute.layout<"(?,3):(?@0,?@1)">
}

// -----

// Mixed static (1@0) and dynamic-scale (?@1) basis strides.
// CHECK-LABEL: func.func @mixed_basis_strides
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(4,3)">, %[[D:.+]]: !cute.stride<"(1@0,?@1)">)
func.func @mixed_basis_strides(%s: !cute.shape<"(4,3)">, %d: !cute.stride<"(1@0,?@1)">) -> !cute.layout<"(4,3):(1@0,?@1)"> {
  // CHECK: cute.make_layout(%[[S]], %[[D]])
  %l = cute.make_layout(%s, %d) : (!cute.shape<"(4,3)">, !cute.stride<"(1@0,?@1)">) -> !cute.layout<"(4,3):(1@0,?@1)">
  return %l : !cute.layout<"(4,3):(1@0,?@1)">
}

// -----

// Well-formed depth-2 hierarchical basis stride with both scales dynamic.
// CHECK-LABEL: func.func @dynamic_hierarchical_basis_well_formed
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"(2,3)">, %[[D:.+]]: !cute.stride<"(?@0@0,?@1@0)">)
func.func @dynamic_hierarchical_basis_well_formed(%s: !cute.shape<"(2,3)">, %d: !cute.stride<"(?@0@0,?@1@0)">) -> !cute.layout<"(2,3):(?@0@0,?@1@0)"> {
  // CHECK: cute.make_layout(%[[S]], %[[D]])
  %l = cute.make_layout(%s, %d) : (!cute.shape<"(2,3)">, !cute.stride<"(?@0@0,?@1@0)">) -> !cute.layout<"(2,3):(?@0@0,?@1@0)">
  return %l : !cute.layout<"(2,3):(?@0@0,?@1@0)">
}

// -----

// Nested shape with nested static basis strides.
// CHECK-LABEL: func.func @nested_with_basis_strides
// CHECK-SAME: (%[[S:.+]]: !cute.shape<"((2,3),(4,5))">, %[[D:.+]]: !cute.stride<"((1@0,1@1),(1@2,1@3))">)
func.func @nested_with_basis_strides(%s: !cute.shape<"((2,3),(4,5))">, %d: !cute.stride<"((1@0,1@1),(1@2,1@3))">) -> !cute.layout<"((2,3),(4,5)):((1@0,1@1),(1@2,1@3))"> {
  // CHECK: cute.make_layout(%[[S]], %[[D]])
  %l = cute.make_layout(%s, %d) : (!cute.shape<"((2,3),(4,5))">, !cute.stride<"((1@0,1@1),(1@2,1@3))">) -> !cute.layout<"((2,3),(4,5)):((1@0,1@1),(1@2,1@3))">
  return %l : !cute.layout<"((2,3),(4,5)):((1@0,1@1),(1@2,1@3))">
}
