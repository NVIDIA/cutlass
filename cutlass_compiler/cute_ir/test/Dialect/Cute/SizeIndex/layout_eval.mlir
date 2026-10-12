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
// Tests round-trip for cute.layout_eval.
// -----
// Static coord.
// CHECK-LABEL: func.func @layout_eval_static
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(1,2)">, %[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
func.func @layout_eval_static(%crd: !cute.coord<"(1,2)">, %l: !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"9"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"9">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"9">
  return %r : !cute.int_tuple<"9">
}
// -----
// Scalar (leaf) coord.
// CHECK-LABEL: func.func @layout_eval_scalar_coord
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"3">, %[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
func.func @layout_eval_scalar_coord(%crd: !cute.coord<"3">, %l: !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"3"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"3">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"3">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"3">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"3">
  return %r : !cute.int_tuple<"3">
}
// -----
// Dynamic coord: result is dynamic.
// CHECK-LABEL: func.func @layout_eval_dynamic
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(?,?)">, %[[L:.+]]: !cute.layout<"(4,8):(1,4)">)
func.func @layout_eval_dynamic(%crd: !cute.coord<"(?,?)">, %l: !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(?,?)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"?">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(?,?)">, !cute.layout<"(4,8):(1,4)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
// -----
// Flat scaled-basis stride.
// CHECK-LABEL: func.func @layout_eval_scaled_basis_flat
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(1,2)">, %[[L:.+]]: !cute.layout<"(4,8):(1@0,1@1)">)
func.func @layout_eval_scaled_basis_flat(%crd: !cute.coord<"(1,2)">, %l: !cute.layout<"(4,8):(1@0,1@1)">) -> !cute.int_tuple<"(1,2)"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1@0,1@1)">) -> !cute.int_tuple<"(1,2)">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1@0,1@1)">) -> !cute.int_tuple<"(1,2)">
  return %r : !cute.int_tuple<"(1,2)">
}
// -----
// Reversed flat basis.
// CHECK-LABEL: func.func @layout_eval_scaled_basis_flat_reversed
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(1,2)">, %[[L:.+]]: !cute.layout<"(4,8):(1@1,1@0)">)
func.func @layout_eval_scaled_basis_flat_reversed(%crd: !cute.coord<"(1,2)">, %l: !cute.layout<"(4,8):(1@1,1@0)">) -> !cute.int_tuple<"(2,1)"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1@1,1@0)">) -> !cute.int_tuple<"(2,1)">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(1,2)">, !cute.layout<"(4,8):(1@1,1@0)">) -> !cute.int_tuple<"(2,1)">
  return %r : !cute.int_tuple<"(2,1)">
}
// -----
// Nested shape with flat-basis strides.
// CHECK-LABEL: func.func @layout_eval_scaled_basis_nested_shape
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(1,2)">, %[[L:.+]]: !cute.layout<"((2,3),4):((1@0,1@1),1@2)">)
func.func @layout_eval_scaled_basis_nested_shape(%crd: !cute.coord<"(1,2)">, %l: !cute.layout<"((2,3),4):((1@0,1@1),1@2)">) -> !cute.int_tuple<"(1,0,2)"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(1,2)">, !cute.layout<"((2,3),4):((1@0,1@1),1@2)">) -> !cute.int_tuple<"(1,0,2)">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(1,2)">, !cute.layout<"((2,3),4):((1@0,1@1),1@2)">) -> !cute.int_tuple<"(1,0,2)">
  return %r : !cute.int_tuple<"(1,0,2)">
}
// -----
// Hierarchical scaled-basis stride (`?@N@M` notation).
// CHECK-LABEL: func.func @layout_eval_scaled_basis_hierarchical
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"0">, %[[L:.+]]: !cute.layout<"((2,3),4):((1@1@0,1@0@0),1@1)">)
func.func @layout_eval_scaled_basis_hierarchical(%crd: !cute.coord<"0">, %l: !cute.layout<"((2,3),4):((1@1@0,1@0@0),1@1)">) -> !cute.int_tuple<"((0,0),0)"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"0">, !cute.layout<"((2,3),4):((1@1@0,1@0@0),1@1)">) -> !cute.int_tuple<"((0,0),0)">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"0">, !cute.layout<"((2,3),4):((1@1@0,1@0@0),1@1)">) -> !cute.int_tuple<"((0,0),0)">
  return %r : !cute.int_tuple<"((0,0),0)">
}
// -----
// Hierarchical scaled-basis stride with *non-unit static integer*
// stride coefficients.
// CHECK-LABEL: func.func @layout_eval_scaled_basis_hierarchical_static_scaled
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"3">, %[[L:.+]]: !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">)
func.func @layout_eval_scaled_basis_hierarchical_static_scaled(%crd: !cute.coord<"3">, %l: !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">) -> !cute.int_tuple<"((2,3),0)"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"3">, !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">) -> !cute.int_tuple<"((2,3),0)">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"3">, !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">) -> !cute.int_tuple<"((2,3),0)">
  return %r : !cute.int_tuple<"((2,3),0)">
}
// -----
// Hierarchical scaled-basis stride, *static* non-unit stride
// coefficients, *dynamic* coord values.
// CHECK-LABEL: func.func @layout_eval_scaled_basis_hierarchical_dynamic_coord
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"((?,?),0)">, %[[L:.+]]: !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">)
func.func @layout_eval_scaled_basis_hierarchical_dynamic_coord(%crd: !cute.coord<"((?,?),0)">, %l: !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">) -> !cute.int_tuple<"((?,?),0)"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"((?,?),0)">, !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">) -> !cute.int_tuple<"((?,?),0)">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"((?,?),0)">, !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">) -> !cute.int_tuple<"((?,?),0)">
  return %r : !cute.int_tuple<"((?,?),0)">
}
// -----
// Same layout as the previous test, but the coord is a single dynamic scalar.
// CHECK-LABEL: func.func @layout_eval_scaled_basis_hierarchical_dynamic_coord_single
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"?">, %[[L:.+]]: !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">)
func.func @layout_eval_scaled_basis_hierarchical_dynamic_coord_single(%crd: !cute.coord<"?">, %l: !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">) -> !cute.int_tuple<"((?,?),?)"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"?">, !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">) -> !cute.int_tuple<"((?,?),?)">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"?">, !cute.layout<"((2,3),4):((2@0@0,3@1@0),5@1)">) -> !cute.int_tuple<"((?,?),?)">
  return %r : !cute.int_tuple<"((?,?),?)">
}
// -----
// Complex outer layout.
// CHECK-LABEL: func.func @layout_eval_scaled_basis_im2col_outer
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"64">, %[[L:.+]]: !cute.layout<"(64,(64,3,3,3)):(1@0,(1@0@1,1@1@1,1@2@1,1@3@1))">)
func.func @layout_eval_scaled_basis_im2col_outer(%crd: !cute.coord<"64">, %l: !cute.layout<"(64,(64,3,3,3)):(1@0,(1@0@1,1@1@1,1@2@1,1@3@1))">) -> !cute.int_tuple<"(0,(1,0,0,0))"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"64">, !cute.layout<"(64,(64,3,3,3)):(1@0,(1@0@1,1@1@1,1@2@1,1@3@1))">) -> !cute.int_tuple<"(0,(1,0,0,0))">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"64">, !cute.layout<"(64,(64,3,3,3)):(1@0,(1@0@1,1@1@1,1@2@1,1@3@1))">) -> !cute.int_tuple<"(0,(1,0,0,0))">
  return %r : !cute.int_tuple<"(0,(1,0,0,0))">
}
// -----
// Dynamic scaled-basis stride.
// CHECK-LABEL: func.func @layout_eval_scaled_basis_dynamic
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(?,?)">, %[[L:.+]]: !cute.layout<"(4,5):(?@0,?@1)">)
func.func @layout_eval_scaled_basis_dynamic(%crd: !cute.coord<"(?,?)">, %l: !cute.layout<"(4,5):(?@0,?@1)">) -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(?,?)">, !cute.layout<"(4,5):(?@0,?@1)">) -> !cute.int_tuple<"(?,?)">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(?,?)">, !cute.layout<"(4,5):(?@0,?@1)">) -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}
// -----
// Composed layout — affine A, plain B, scalar, static offset.
// CHECK-LABEL: func.func @layout_eval_composed_layout_affine_static
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(4)">, %[[L:.+]]: !cute.composed_layout<"(20):(3) o 2 o (20):(3)">)
func.func @layout_eval_composed_layout_affine_static(
    %crd: !cute.coord<"(4)">,
    %l: !cute.composed_layout<"(20):(3) o 2 o (20):(3)">) -> !cute.int_tuple<"42"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(4)">, !cute.composed_layout<"(20):(3) o 2 o (20):(3)">) -> !cute.int_tuple<"42">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(4)">, !cute.composed_layout<"(20):(3) o 2 o (20):(3)">) -> !cute.int_tuple<"42">
  return %r : !cute.int_tuple<"42">
}
// -----
// Composed layout — affine A with a fully dynamic inner B.
// CHECK-LABEL: func.func @layout_eval_composed_layout_affine_dynamic
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(?)">, %[[L:.+]]: !cute.composed_layout<"(?):(?) o 0 o (?):(?)">)
func.func @layout_eval_composed_layout_affine_dynamic(
    %crd: !cute.coord<"(?)">,
    %l: !cute.composed_layout<"(?):(?) o 0 o (?):(?)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(?)">, !cute.composed_layout<"(?):(?) o 0 o (?):(?)">) -> !cute.int_tuple<"?">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(?)">, !cute.composed_layout<"(?):(?) o 0 o (?):(?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
// -----
// Composed layout — fully dynamic affine A + dynamic offset.
// CHECK-LABEL: func.func @layout_eval_composed_layout_affine_dynamic
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(?)">, %[[L:.+]]: !cute.composed_layout<"(?):(?) o ? o (?):(?)">)
func.func @layout_eval_composed_layout_affine_dynamic(
    %crd: !cute.coord<"(?)">,
    %l: !cute.composed_layout<"(?):(?) o ? o (?):(?)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(?)">, !cute.composed_layout<"(?):(?) o ? o (?):(?)">) -> !cute.int_tuple<"?">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(?)">, !cute.composed_layout<"(?):(?) o ? o (?):(?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
// -----
// Composed layout — swizzle A, zero offset.
// CHECK-LABEL: func.func @layout_eval_composed_layout_swizzle_zero_offset
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(6)">, %[[L:.+]]: !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">)
func.func @layout_eval_composed_layout_swizzle_zero_offset(
    %crd: !cute.coord<"(6)">,
    %l: !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">) -> !cute.int_tuple<"208"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(6)">, !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">) -> !cute.int_tuple<"208">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(6)">, !cute.composed_layout<"S<1,4,3> o 0 o (32):(32)">) -> !cute.int_tuple<"208">
  return %r : !cute.int_tuple<"208">
}
// -----
// Composed layout — swizzle A, non-zero scalar offset.
// CHECK-LABEL: func.func @layout_eval_composed_layout_swizzle_scalar_offset
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(6)">, %[[L:.+]]: !cute.composed_layout<"S<1,4,3> o 2 o (32):(32)">)
func.func @layout_eval_composed_layout_swizzle_scalar_offset(
    %crd: !cute.coord<"(6)">,
    %l: !cute.composed_layout<"S<1,4,3> o 2 o (32):(32)">) -> !cute.int_tuple<"210"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(6)">, !cute.composed_layout<"S<1,4,3> o 2 o (32):(32)">) -> !cute.int_tuple<"210">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(6)">, !cute.composed_layout<"S<1,4,3> o 2 o (32):(32)">) -> !cute.int_tuple<"210">
  return %r : !cute.int_tuple<"210">
}
// -----
// Composed layout — swizzle A, underscore coord (slice wildcard).
// CHECK-LABEL: func.func @layout_eval_composed_layout_swizzle_underscore
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(_)">, %[[L:.+]]: !cute.composed_layout<"S<1,4,3> o 0 o (128):(1)">)
func.func @layout_eval_composed_layout_swizzle_underscore(
    %crd: !cute.coord<"(_)">,
    %l: !cute.composed_layout<"S<1,4,3> o 0 o (128):(1)">) -> !cute.int_tuple<"0"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(_)">, !cute.composed_layout<"S<1,4,3> o 0 o (128):(1)">) -> !cute.int_tuple<"0">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(_)">, !cute.composed_layout<"S<1,4,3> o 0 o (128):(1)">) -> !cute.int_tuple<"0">
  return %r : !cute.int_tuple<"0">
}
// -----
// Composed layout — swizzle A, dynamic coord with B stride matching
// CHECK-LABEL: func.func @layout_eval_composed_layout_swizzle_dyn_coord
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(?)">, %[[L:.+]]: !cute.composed_layout<"S<1,4,3> o 0 o (16):(16)">)
func.func @layout_eval_composed_layout_swizzle_dyn_coord(
    %crd: !cute.coord<"(?)">,
    %l: !cute.composed_layout<"S<1,4,3> o 0 o (16):(16)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(?)">, !cute.composed_layout<"S<1,4,3> o 0 o (16):(16)">) -> !cute.int_tuple<"?">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(?)">, !cute.composed_layout<"S<1,4,3> o 0 o (16):(16)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
// -----
// Composed layout — swizzle A, static coord 129.
// CHECK-LABEL: func.func @layout_eval_composed_layout_swizzle_static_129
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(129)">, %[[L:.+]]: !cute.composed_layout<"S<1,4,3> o 0 o (1024):(1)">)
func.func @layout_eval_composed_layout_swizzle_static_129(
    %crd: !cute.coord<"(129)">,
    %l: !cute.composed_layout<"S<1,4,3> o 0 o (1024):(1)">) -> !cute.int_tuple<"145"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(129)">, !cute.composed_layout<"S<1,4,3> o 0 o (1024):(1)">) -> !cute.int_tuple<"145">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(129)">, !cute.composed_layout<"S<1,4,3> o 0 o (1024):(1)">) -> !cute.int_tuple<"145">
  return %r : !cute.int_tuple<"145">
}
// -----
// Composed layout — swizzle A, dynamic coord with  aligned
// well enough to preserve  after swizzling.
// CHECK-LABEL: func.func @layout_eval_composed_layout_swizzle_div128
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(?)">, %[[L:.+]]: !cute.composed_layout<"S<1,4,3> o 0 o (1024):(1)">)
func.func @layout_eval_composed_layout_swizzle_div128(
    %crd: !cute.coord<"(?)">,
    %l: !cute.composed_layout<"S<1,4,3> o 0 o (1024):(1)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(?)">, !cute.composed_layout<"S<1,4,3> o 0 o (1024):(1)">) -> !cute.int_tuple<"?">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(?)">, !cute.composed_layout<"S<1,4,3> o 0 o (1024):(1)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
// -----
// Composed layout — larger swizzle S<1,12,3>, dynamic coord
// aligned to  — preserves .
// CHECK-LABEL: func.func @layout_eval_composed_layout_swizzle_large_base
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(?)">, %[[L:.+]]: !cute.composed_layout<"S<1,12,3> o 0 o (1024):(1)">)
func.func @layout_eval_composed_layout_swizzle_large_base(
    %crd: !cute.coord<"(?)">,
    %l: !cute.composed_layout<"S<1,12,3> o 0 o (1024):(1)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(?)">, !cute.composed_layout<"S<1,12,3> o 0 o (1024):(1)">) -> !cute.int_tuple<"?">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(?)">, !cute.composed_layout<"S<1,12,3> o 0 o (1024):(1)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
// -----
// Composed layout with **scaled-basis B** + tuple offset + affine A.
// CHECK-LABEL: func.func @layout_eval_composed_layout_basis_b
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"3">, %[[L:.+]]: !cute.composed_layout<"(6,2):(1,3) o (2,1) o (2,3):(1@1,2@0)">)
func.func @layout_eval_composed_layout_basis_b(
    %crd: !cute.coord<"3">,
    %l: !cute.composed_layout<"(6,2):(1,3) o (2,1) o (2,3):(1@1,2@0)">) -> !cute.int_tuple<"10"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"3">, !cute.composed_layout<"(6,2):(1,3) o (2,1) o (2,3):(1@1,2@0)">) -> !cute.int_tuple<"10">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"3">, !cute.composed_layout<"(6,2):(1,3) o (2,1) o (2,3):(1@1,2@0)">) -> !cute.int_tuple<"10">
  return %r : !cute.int_tuple<"10">
}
// -----
// CHECK-LABEL: func.func @layout_eval
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(?)">, %[[L:.+]]: !cute.layout<"(?):(?)">)
func.func @layout_eval(
    %crd: !cute.coord<"(?)">,
    %l: !cute.layout<"(?):(?)">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(?)">, !cute.layout<"(?):(?)">) -> !cute.int_tuple<"?">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(?)">, !cute.layout<"(?):(?)">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
// -----
// Scalar (leaf) coord on a multi-mode dynamic layout.
// CHECK-LABEL: func.func @layout_eval_scalar_coord_nested_layout
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"?">, %[[L:.+]]: !cute.layout<"(?,(?,?)):(?,(?,?))">)
func.func @layout_eval_scalar_coord_nested_layout(
    %crd: !cute.coord<"?">,
    %l: !cute.layout<"(?,(?,?)):(?,(?,?))">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"?">, !cute.layout<"(?,(?,?)):(?,(?,?))">) -> !cute.int_tuple<"?">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"?">, !cute.layout<"(?,(?,?)):(?,(?,?))">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
// -----
// Profile-matching nested coord on the same nested layout.
// CHECK-LABEL: func.func @layout_eval_nested_coord_nested_layout
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(?,(?,?))">, %[[L:.+]]: !cute.layout<"(?,(?,?)):(?,(?,?))">)
func.func @layout_eval_nested_coord_nested_layout(
    %crd: !cute.coord<"(?,(?,?))">,
    %l: !cute.layout<"(?,(?,?)):(?,(?,?))">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(?,(?,?))">, !cute.layout<"(?,(?,?)):(?,(?,?))">) -> !cute.int_tuple<"?">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(?,(?,?))">, !cute.layout<"(?,(?,?)):(?,(?,?))">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
// -----
// Scaled-basis with exact layout
// CHECK-LABEL: func.func @layout_eval_scaled_basis
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"?">, %[[L:.+]]: !cute.layout<"(10,20,30):(1@0,1@1,20@1)">)
func.func @layout_eval_scaled_basis(
    %crd: !cute.coord<"?">,
    %l: !cute.layout<"(10,20,30):(1@0,1@1,20@1)">) -> !cute.int_tuple<"(?,?)"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"?">, !cute.layout<"(10,20,30):(1@0,1@1,20@1)">) -> !cute.int_tuple<"(?,?)">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"?">, !cute.layout<"(10,20,30):(1@0,1@1,20@1)">) -> !cute.int_tuple<"(?,?)">
  return %r : !cute.int_tuple<"(?,?)">
}
// -----
// Flat rank-2 coord into a nested-shape layout.
// CHECK-LABEL: func.func @layout_eval_flat_coord_into_nested_layout
// CHECK-SAME:  (%[[CRD:.+]]: !cute.coord<"(?,?)">, %[[L:.+]]: !cute.layout<"(?,(?,?)):(?,(?,?))">)
func.func @layout_eval_flat_coord_into_nested_layout(
    %crd: !cute.coord<"(?,?)">,
    %l: !cute.layout<"(?,(?,?)):(?,(?,?))">) -> !cute.int_tuple<"?"> {
  // CHECK: %[[R:.+]] = cute.layout_eval(%[[CRD]], %[[L]]) : (!cute.coord<"(?,?)">, !cute.layout<"(?,(?,?)):(?,(?,?))">) -> !cute.int_tuple<"?">
  %r = cute.layout_eval(%crd, %l) : (!cute.coord<"(?,?)">, !cute.layout<"(?,(?,?)):(?,(?,?))">) -> !cute.int_tuple<"?">
  return %r : !cute.int_tuple<"?">
}
