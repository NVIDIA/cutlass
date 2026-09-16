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

// Tests round-trip for cute.size.

// -----

// Shape, no mode: product of all extents.
// CHECK-LABEL: func.func @size_of_shape
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(4,3)">)
func.func @size_of_shape(%src: !cute.shape<"(4,3)">) -> !cute.int_tuple<"12"> {
  // CHECK: %[[R:.+]] = cute.size (%[[SRC]]) : (!cute.shape<"(4,3)">) -> !cute.int_tuple<"12">
  %r = cute.size(%src) : (!cute.shape<"(4,3)">) -> !cute.int_tuple<"12">
  return %r : !cute.int_tuple<"12">
}

// -----

// Shape with mode: size of the sub-tree at mode [1].
// CHECK-LABEL: func.func @size_of_shape_with_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(1,(2,4),9)">)
func.func @size_of_shape_with_mode(%src: !cute.shape<"(1,(2,4),9)">) -> !cute.int_tuple<"8"> {
  // CHECK: %[[R:.+]] = cute.size<[1]> (%[[SRC]]) : (!cute.shape<"(1,(2,4),9)">) -> !cute.int_tuple<"8">
  %r = cute.size <[1]>(%src) : (!cute.shape<"(1,(2,4),9)">) -> !cute.int_tuple<"8">
  return %r : !cute.int_tuple<"8">
}

// -----

// IntTuple input, no mode.
// CHECK-LABEL: func.func @size_of_int_tuple
// CHECK-SAME:  (%[[SRC:.+]]: !cute.int_tuple<"(4,(16,32))">)
func.func @size_of_int_tuple(%src: !cute.int_tuple<"(4,(16,32))">) -> !cute.int_tuple<"2048"> {
  // CHECK: %[[R:.+]] = cute.size (%[[SRC]]) : (!cute.int_tuple<"(4,(16,32))">) -> !cute.int_tuple<"2048">
  %r = cute.size(%src) : (!cute.int_tuple<"(4,(16,32))">) -> !cute.int_tuple<"2048">
  return %r : !cute.int_tuple<"2048">
}

// -----

// Layout input, no mode: size of the domain shape.
// CHECK-LABEL: func.func @size_of_layout
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,(16,32)):(1,(4,64))">)
func.func @size_of_layout(%src: !cute.layout<"(4,(16,32)):(1,(4,64))">) -> !cute.int_tuple<"2048"> {
  // CHECK: %[[R:.+]] = cute.size (%[[SRC]]) : (!cute.layout<"(4,(16,32)):(1,(4,64))">) -> !cute.int_tuple<"2048">
  %r = cute.size(%src) : (!cute.layout<"(4,(16,32)):(1,(4,64))">) -> !cute.int_tuple<"2048">
  return %r : !cute.int_tuple<"2048">
}

// -----

// Layout with mode: size of the sub-layout at mode [1].
// CHECK-LABEL: func.func @size_of_layout_with_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(4,(16,32)):(1,(4,64))">)
func.func @size_of_layout_with_mode(%src: !cute.layout<"(4,(16,32)):(1,(4,64))">) -> !cute.int_tuple<"512"> {
  // CHECK: %[[R:.+]] = cute.size<[1]> (%[[SRC]]) : (!cute.layout<"(4,(16,32)):(1,(4,64))">) -> !cute.int_tuple<"512">
  %r = cute.size <[1]>(%src) : (!cute.layout<"(4,(16,32)):(1,(4,64))">) -> !cute.int_tuple<"512">
  return %r : !cute.int_tuple<"512">
}

// -----

// ComposedLayout input: size of the outer layout's domain.
// CHECK-LABEL: func.func @size_of_composed_layout
// CHECK-SAME:  (%[[SRC:.+]]: !cute.composed_layout<"S<3,4,6> o 0 o (3,4):(4,1)">)
func.func @size_of_composed_layout(
    %src: !cute.composed_layout<"S<3,4,6> o 0 o (3,4):(4,1)">) -> !cute.int_tuple<"12"> {
  // CHECK: %[[R:.+]] = cute.size (%[[SRC]]) : (!cute.composed_layout<"S<3,4,6> o 0 o (3,4):(4,1)">) -> !cute.int_tuple<"12">
  %r = cute.size(%src) : (!cute.composed_layout<"S<3,4,6> o 0 o (3,4):(4,1)">) -> !cute.int_tuple<"12">
  return %r : !cute.int_tuple<"12">
}

// -----

// Dynamic shape.
// CHECK-LABEL: func.func @size_of_dynamic
// CHECK-SAME:  (%[[SRC:.+]]: !cute.shape<"(4,(16,32),(?,64))">)
func.func @size_of_dynamic(
    %src: !cute.shape<"(4,(16,32),(?,64))">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.size (%[[SRC]]) : (!cute.shape<"(4,(16,32),(?,64))">) -> !cute.int_tuple<"?">
  %r = cute.size(%src) : (!cute.shape<"(4,(16,32),(?,64))">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}

// -----

// Basis stride layout, no mode: size of the domain = product of extents (strides ignored).
// CHECK-LABEL: func.func @size_basis_stride_layout
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3):(1@0,1@1)">)
func.func @size_basis_stride_layout(%src: !cute.layout<"(2,3):(1@0,1@1)">) -> !cute.int_tuple<"6"> {
  // CHECK: %[[R:.+]] = cute.size (%[[SRC]]) : (!cute.layout<"(2,3):(1@0,1@1)">) -> !cute.int_tuple<"6">
  %r = cute.size(%src) : (!cute.layout<"(2,3):(1@0,1@1)">) -> !cute.int_tuple<"6">
  return %r : !cute.int_tuple<"6">
}

// -----

// Basis stride layout with mode [0]: size of the sub-layout at mode 0.
// CHECK-LABEL: func.func @size_basis_stride_layout_with_mode
// CHECK-SAME:  (%[[SRC:.+]]: !cute.layout<"(2,3):(1@0,1@1)">)
func.func @size_basis_stride_layout_with_mode(%src: !cute.layout<"(2,3):(1@0,1@1)">) -> !cute.int_tuple<"2"> {
  // CHECK: %[[R:.+]] = cute.size<[0]> (%[[SRC]]) : (!cute.layout<"(2,3):(1@0,1@1)">) -> !cute.int_tuple<"2">
  %r = cute.size <[0]>(%src) : (!cute.layout<"(2,3):(1@0,1@1)">) -> !cute.int_tuple<"2">
  return %r : !cute.int_tuple<"2">
}
