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

// Tests parse/print round-trip for cute.print on every CuteIR type,
// with static, dynamic, nested, and basis-stride variants where applicable.

// -----

// CHECK-LABEL: func.func @print_layout_static
func.func @print_layout_static(%x: !cute.layout<"(2,3):(1,2)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.layout<"(2,3):(1,2)">
  cute.print(%x) : !cute.layout<"(2,3):(1,2)">
  return
}

// -----

// CHECK-LABEL: func.func @print_layout_dynamic
func.func @print_layout_dynamic(%x: !cute.layout<"(2,?):(1,?)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.layout<"(2,?):(1,?)">
  cute.print(%x) : !cute.layout<"(2,?):(1,?)">
  return
}

// -----

// Nested (depth > 2) layout.
// CHECK-LABEL: func.func @print_layout_nested
func.func @print_layout_nested(%x: !cute.layout<"(5,2,(3,7)):(1,5,(10,30))">) {
  // CHECK: cute.print(%{{.+}}) : !cute.layout<"(5,2,(3,7)):(1,5,(10,30))">
  cute.print(%x) : !cute.layout<"(5,2,(3,7)):(1,5,(10,30))">
  return
}

// -----

// Nested dynamic layout.
// CHECK-LABEL: func.func @print_layout_nested_dynamic
func.func @print_layout_nested_dynamic(%x: !cute.layout<"(?,2,(?,7)):(1,?,(10,30))">) {
  // CHECK: cute.print(%{{.+}}) : !cute.layout<"(?,2,(?,7)):(1,?,(10,30))">
  cute.print(%x) : !cute.layout<"(?,2,(?,7)):(1,?,(10,30))">
  return
}

// -----

// Layout with hierarchical (basis) strides.
// CHECK-LABEL: func.func @print_layout_basis_strides
func.func @print_layout_basis_strides(%x: !cute.layout<"(2,3):(1@0@0,1@1@0)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.layout<"(2,3):(1@0@0,1@1@0)">
  cute.print(%x) : !cute.layout<"(2,3):(1@0@0,1@1@0)">
  return
}

// -----

// CHECK-LABEL: func.func @print_stride_static
func.func @print_stride_static(%x: !cute.stride<"(1,4)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.stride<"(1,4)">
  cute.print(%x) : !cute.stride<"(1,4)">
  return
}

// -----

// CHECK-LABEL: func.func @print_stride_dynamic
func.func @print_stride_dynamic(%x: !cute.stride<"?">) {
  // CHECK: cute.print(%{{.+}}) : !cute.stride<"?">
  cute.print(%x) : !cute.stride<"?">
  return
}

// -----

// Nested stride.
// CHECK-LABEL: func.func @print_stride_nested
func.func @print_stride_nested(%x: !cute.stride<"(18,5,(3,2),7)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.stride<"(18,5,(3,2),7)">
  cute.print(%x) : !cute.stride<"(18,5,(3,2),7)">
  return
}

// -----

// Hierarchical (basis) stride: V@Mn@...@M0.
// CHECK-LABEL: func.func @print_stride_basis
func.func @print_stride_basis(%x: !cute.stride<"(1@1@0,2@1@0)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.stride<"(1@1@0,2@1@0)">
  cute.print(%x) : !cute.stride<"(1@1@0,2@1@0)">
  return
}

// -----

// CHECK-LABEL: func.func @print_shape_static
func.func @print_shape_static(%x: !cute.shape<"(32,64)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.shape<"(32,64)">
  cute.print(%x) : !cute.shape<"(32,64)">
  return
}

// -----

// CHECK-LABEL: func.func @print_shape_dynamic
func.func @print_shape_dynamic(%x: !cute.shape<"(?,64)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.shape<"(?,64)">
  cute.print(%x) : !cute.shape<"(?,64)">
  return
}

// -----

// Nested shape.
// CHECK-LABEL: func.func @print_shape_nested
func.func @print_shape_nested(%x: !cute.shape<"(5,2,(3,7))">) {
  // CHECK: cute.print(%{{.+}}) : !cute.shape<"(5,2,(3,7))">
  cute.print(%x) : !cute.shape<"(5,2,(3,7))">
  return
}

// -----

// CHECK-LABEL: func.func @print_coord_static
func.func @print_coord_static(%x: !cute.coord<"(1,2)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.coord<"(1,2)">
  cute.print(%x) : !cute.coord<"(1,2)">
  return
}

// -----

// CHECK-LABEL: func.func @print_coord_dynamic
func.func @print_coord_dynamic(%x: !cute.coord<"(?,2)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.coord<"(?,2)">
  cute.print(%x) : !cute.coord<"(?,2)">
  return
}

// -----

// CHECK-LABEL: func.func @print_int_tuple_static
func.func @print_int_tuple_static(%x: !cute.int_tuple<"16">) {
  // CHECK: cute.print(%{{.+}}) : !cute.int_tuple<"16">
  cute.print(%x) : !cute.int_tuple<"16">
  return
}

// -----

// CHECK-LABEL: func.func @print_int_tuple_dynamic
func.func @print_int_tuple_dynamic(%x: !cute.int_tuple<"?">) {
  // CHECK: cute.print(%{{.+}}) : !cute.int_tuple<"?">
  cute.print(%x) : !cute.int_tuple<"?">
  return
}

// -----

// CHECK-LABEL: func.func @print_tile_static
func.func @print_tile_static(%x: !cute.tile<"[(2,3):(1,2)]">) {
  // CHECK: cute.print(%{{.+}}) : !cute.tile<"[(2,3):(1,2)]">
  cute.print(%x) : !cute.tile<"[(2,3):(1,2)]">
  return
}

// -----

// CHECK-LABEL: func.func @print_tile_dynamic
func.func @print_tile_dynamic(%x: !cute.tile<"[(?,3):(1,?)]">) {
  // CHECK: cute.print(%{{.+}}) : !cute.tile<"[(?,3):(1,?)]">
  cute.print(%x) : !cute.tile<"[(?,3):(1,?)]">
  return
}

// -----

// Nested dynamic tile.
// CHECK-LABEL: func.func @print_tile_nested_dynamic
func.func @print_tile_nested_dynamic(%x: !cute.tile<"[(?,2,(?,7)):(1,?,(10,30))]">) {
  // CHECK: cute.print(%{{.+}}) : !cute.tile<"[(?,2,(?,7)):(1,?,(10,30))]">
  cute.print(%x) : !cute.tile<"[(?,2,(?,7)):(1,?,(10,30))]">
  return
}

// -----

// Tile with hierarchical (basis) strides.
// CHECK-LABEL: func.func @print_tile_basis_strides
func.func @print_tile_basis_strides(%x: !cute.tile<"[(2,3):(1@0@0,1@1@0)]">) {
  // CHECK: cute.print(%{{.+}}) : !cute.tile<"[(2,3):(1@0@0,1@1@0)]">
  cute.print(%x) : !cute.tile<"[(2,3):(1@0@0,1@1@0)]">
  return
}

// -----

// CHECK-LABEL: func.func @print_composed_layout_static
func.func @print_composed_layout_static(%x: !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  cute.print(%x) : !cute.composed_layout<"S<3,5,4> o 0 o (8,4):(1,8)">
  return
}

// -----

// CHECK-LABEL: func.func @print_composed_layout_dynamic
func.func @print_composed_layout_dynamic(%x: !cute.composed_layout<"S<3,5,4> o 0 o (8,?):(1,?)">) {
  // CHECK: cute.print(%{{.+}}) : !cute.composed_layout<"S<3,5,4> o 0 o (8,?):(1,?)">
  cute.print(%x) : !cute.composed_layout<"S<3,5,4> o 0 o (8,?):(1,?)">
  return
}

// -----

// Swizzle is always static — only one variant.
// CHECK-LABEL: func.func @print_swizzle
func.func @print_swizzle(%x: !cute.swizzle<"S<3,5,4>">) {
  // CHECK: cute.print(%{{.+}}) : !cute.swizzle<"S<3,5,4>">
  cute.print(%x) : !cute.swizzle<"S<3,5,4>">
  return
}

